#!/usr/bin/env bash
# hooks/lib/default-branch.sh — detect the repo's default branch.
#
# Detection chain (in order):
#   1. git symbolic-ref refs/remotes/origin/HEAD --short  (e.g. "origin/main")
#   2. fallback: local "main" exists
#   3. fallback: local "master" exists
#   4. bail (exit 1)
#
# Contract:
#   - Branch name on stdout ONLY (no trailing noise)
#   - Exit 0 on success, exit 1 on bail
#   - All git stderr redirected to /dev/null (silent contract)
#
# Dual-mode:
#   Script-call:  default_branch=$(bash "$ROOT/.claude/hooks/lib/default-branch.sh") || default_branch="main"
#   Source-mode:  source "$ROOT/.claude/hooks/lib/default-branch.sh"
#                 default_branch=$(detect_default_branch) || default_branch="main"

detect_default_branch() {
    # Method 1: origin/HEAD symbolic ref (~95% of repos)
    local ref
    if ref=$(git symbolic-ref --short -q refs/remotes/origin/HEAD 2>/dev/null); then
        printf '%s' "${ref#origin/}"
        return 0
    fi
    # Method 2: local main exists
    if git show-ref --verify --quiet refs/heads/main 2>/dev/null; then
        printf 'main'
        return 0
    fi
    # Method 3: local master exists
    if git show-ref --verify --quiet refs/heads/master 2>/dev/null; then
        printf 'master'
        return 0
    fi
    # Bail
    return 1
}

# Dual-mode: when invoked as a script (not sourced), call the function and
# exit with its status. When sourced, the function is defined and the script
# returns immediately without exiting the caller.
#
# Idiom: BASH_SOURCE[0] equals $0 only when this file is the entry point
# (i.e., invoked as `bash this-file.sh`). When sourced, BASH_SOURCE[0] is
# this file's path while $0 is the parent script's name.
if [[ "${BASH_SOURCE[0]:-}" == "${0}" ]]; then
    detect_default_branch
    exit $?
fi
