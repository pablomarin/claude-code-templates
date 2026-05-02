#!/usr/bin/env python3
# hooks/lib/codex-pty-helper.py — PTY wrapper for codex exec.
#
# Why a separate file (not inline in codex-pty.sh)?
#   pty.spawn() in Python 3.9 hangs on macOS after the child exits because
#   the parent's _copy loop blocks in select() waiting on master_fd that
#   never reports ready. Working around it requires an explicit waitpid
#   poll loop, which is too long to inline as `python3 -c '...'` in bash.
#
# Why pty.fork() not pty.spawn()?
#   pty.spawn() does the fork + I/O loop together but its loop is buggy on
#   3.9. We use the lower-level pty.fork() (which just allocates a pty pair
#   and forks) and write our own loop that polls waitpid(WNOHANG) so we can
#   exit promptly when the child terminates.
#
# Contract:
#   sys.argv[1:] is the command + args to run inside the pty.
#   stdin → pty master, pty master → stdout, both 4KB chunks.
#   Returns child's exit code; signal-killed children return 128 + signum.

import errno
import os
import pty
import select
import signal
import sys


def main() -> int:
    if len(sys.argv) < 2:
        print("codex-pty-helper: usage: codex-pty-helper.py <cmd> [args...]",
              file=sys.stderr)
        return 2

    argv = sys.argv[1:]

    pid, master_fd = pty.fork()
    if pid == 0:
        # Child: pty.fork() already dup'd slave to fd 0/1/2 and made us the
        # session leader. Just exec.
        # On exec failure, emit a diagnostic to stderr (which goes through the
        # pty back to the user) so the user can distinguish "codex ran and
        # exited N" from "execvp failed and we couldn't run codex" — without
        # the diagnostic, exit codes 126/127 collide with legitimate codex
        # exits (silent-failure agent P0, iter-2).
        try:
            os.execvp(argv[0], argv)
        except FileNotFoundError:
            sys.stderr.write(
                f"codex-pty-helper: command not found: {argv[0]}\n"
            )
            sys.stderr.flush()
            os._exit(127)
        except OSError as e:
            sys.stderr.write(
                f"codex-pty-helper: execvp failed for {argv[0]}: "
                f"errno={e.errno} ({e.strerror})\n"
            )
            sys.stderr.flush()
            os._exit(126)

    # Parent: I/O multiplex until child exits.
    exit_status = None
    select_error_streak = 0
    try:
        while True:
            # Poll for child exit — non-blocking.
            try:
                wpid, status = os.waitpid(pid, os.WNOHANG)
            except ChildProcessError:
                exit_status = 0
                break
            if wpid == pid:
                exit_status = status
                # Drain remaining buffered output before returning.
                _drain(master_fd)
                break
            # Multiplex parent stdin → pty master, pty master → parent stdout.
            try:
                rfds, _, _ = select.select([master_fd, 0], [], [], 0.1)
                select_error_streak = 0
            except (OSError, ValueError) as e:
                # Either master_fd was closed under us, or stdin is closed.
                # Bail after a sustained streak — without this, EBADF would
                # spin at 100% CPU forever (silent-failure agent P1, iter-2).
                select_error_streak += 1
                if select_error_streak > 50:  # ~5s of consecutive errors
                    sys.stderr.write(
                        f"codex-pty-helper: select() persistently failing "
                        f"({e}); killing child and aborting\n"
                    )
                    try:
                        os.kill(pid, signal.SIGTERM)
                    except OSError:
                        pass
                    exit_status = 1 << 8  # encode as wait-status (exit 1)
                    break
                continue

            if master_fd in rfds:
                try:
                    data = os.read(master_fd, 4096)
                except OSError:
                    # macOS: master read returns EIO when slave is fully closed.
                    # Treat as EOF — child has exited and waitpid will catch it.
                    data = b""
                if data:
                    try:
                        os.write(1, data)
                    except BrokenPipeError:
                        # Downstream reader is gone (SIGPIPE semantics). Kill
                        # the child to free resources and surface 141 (per
                        # silent-failure agent P1, iter-2).
                        try:
                            os.kill(pid, signal.SIGTERM)
                        except OSError:
                            pass
                        exit_status = (128 + signal.SIGPIPE) << 8  # encode wait-status
                        break
                    except OSError as e:
                        sys.stderr.write(
                            f"codex-pty-helper: stdout write failed: {e}\n"
                        )
                        exit_status = 1 << 8
                        break
                # If empty, don't break — let waitpid confirm the exit.

            if 0 in rfds:
                try:
                    data = os.read(0, 4096)
                except OSError:
                    data = b""
                if data:
                    try:
                        os.write(master_fd, data)
                    except OSError as e:
                        if e.errno not in (errno.EIO, errno.EPIPE):
                            sys.stderr.write(
                                f"codex-pty-helper: pty write failed: {e}\n"
                            )
                        # Stop forwarding stdin — child has hung up its end.
                        try:
                            devnull = os.open(os.devnull, os.O_RDONLY)
                            os.dup2(devnull, 0)
                            os.close(devnull)
                        except OSError:
                            pass
                else:
                    # Stdin EOF — dup /dev/null over fd 0 so select() never
                    # wakes for fd 0 again. (iter-2 doc fix: was previously
                    # described as "bool flag" which never existed.)
                    try:
                        devnull = os.open(os.devnull, os.O_RDONLY)
                        os.dup2(devnull, 0)
                        os.close(devnull)
                    except OSError:
                        pass
    finally:
        try:
            os.close(master_fd)
        except OSError:
            pass

    if exit_status is None:
        return 1
    if os.WIFEXITED(exit_status):
        return os.WEXITSTATUS(exit_status)
    if os.WIFSIGNALED(exit_status):
        return 128 + os.WTERMSIG(exit_status)
    return 1


def _drain(master_fd: int, max_bytes: int = 1 << 20) -> None:
    """Read everything buffered on master_fd and write to stdout.

    Bounded by max_bytes (1 MiB) to avoid infinite loops if upstream is weird.
    """
    total = 0
    while total < max_bytes:
        try:
            rfds, _, _ = select.select([master_fd], [], [], 0)
        except (OSError, ValueError):
            return
        if master_fd not in rfds:
            return
        try:
            data = os.read(master_fd, 4096)
        except OSError:
            return
        if not data:
            return
        try:
            os.write(1, data)
        except OSError:
            return
        total += len(data)


if __name__ == "__main__":
    sys.exit(main())
