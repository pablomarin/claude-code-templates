#!/bin/bash
# scripts/migrate-continuity.sh
# Migrate legacy CONTINUITY.md into the new three-artifact structure.
# Idempotent (sentinel-marker-based); original-file-preserving; no dry-run.
#
# Invoked by setup.sh / setup.ps1 on --migrate. Runs in the user's CWD.
# Forge-internal -- not shipped to downstream installs.

set -u  # fail on unset vars; do NOT set -e (we handle errors explicitly)

# AC-4 parity: this script emits ASCII-only, color-free output so its stdout
# matches scripts/migrate-continuity.ps1 byte-for-byte under the test contract.
# If interactive callers want color, setup.sh / setup.ps1 can wrap the dispatch.

# Sentinel marker for idempotency -- embedded in migrated content.
SENTINEL_PREFIX="<!-- forge:migrated"
SENTINEL_TODAY="<!-- forge:migrated $(date +%Y-%m-%d) -->"

LEGACY_FILE="CONTINUITY.md"

if [ ! -f "$LEGACY_FILE" ]; then
    # ASCII-safe output for AC-4 byte-equivalence with PS mirror.
    echo "!  No CONTINUITY.md found in this directory. Nothing to migrate."
    exit 0
fi

# Idempotency check -- if either target already has the sentinel, this is a rerun.
# Sentinel locations: top-of-file in .claude/local/state.md AND in CLAUDE.md.
# Sentinel is written UNCONDITIONALLY at the start of migration (see below) --
# so even repos with no Goal / no decisions / no Done content still get marked.
already_migrated() {
    [ -f "CLAUDE.md" ] && grep -qF "$SENTINEL_PREFIX" CLAUDE.md 2>/dev/null && return 0
    [ -f ".claude/local/state.md" ] && grep -qF "$SENTINEL_PREFIX" .claude/local/state.md 2>/dev/null && return 0
    return 1
}

if already_migrated; then
    # Use -E (regex), NOT -F (fixed-string + regex metachars don't mix).
    existing=$(grep -hoE '<!-- forge:migrated [^>]*-->' CLAUDE.md .claude/local/state.md 2>/dev/null | head -1)
    echo "Already migrated. ${existing}"
    echo "  Sentinel marker detected in CLAUDE.md or .claude/local/state.md."
    echo "  No content was modified. To force a fresh migration, remove the marker line(s) and rerun."
    exit 0
fi

# --- Write sentinel UNCONDITIONALLY at the start (before any extraction) ---
# This guarantees idempotency even when the legacy CONTINUITY.md has no Goal,
# no Decisions table, or empty Done -- repos that migrate "nothing" still get
# marked as migrated, so rerun is a no-op (Codex iter-2 P0 fix).
mkdir -p .claude/local
if [ ! -f ".claude/local/state.md" ]; then
    # state.md will be present on -f / --upgrade installs; if standalone --migrate
    # was invoked without first running -f, bail with a clear message.
    echo "x .claude/local/state.md not found." >&2
    echo "  Run setup -f first to install the state template, then rerun --migrate." >&2
    exit 1
fi
# Prepend sentinel to state.md (line 1).
{ echo "$SENTINEL_TODAY"; cat .claude/local/state.md; } > .claude/local/state.md.tmp && mv .claude/local/state.md.tmp .claude/local/state.md

# If CLAUDE.md exists, prepend sentinel as a comment line on line 2 (after H1).
if [ -f "CLAUDE.md" ] && ! grep -qF "$SENTINEL_PREFIX" CLAUDE.md; then
    awk -v sentinel="$SENTINEL_TODAY" '
        NR==1 { print; print sentinel; next }
        { print }
    ' CLAUDE.md > CLAUDE.md.tmp && mv CLAUDE.md.tmp CLAUDE.md
fi

echo "Migrating $LEGACY_FILE..."
echo ""

moved_sections=()
skipped_sections=()
created_adrs=()
warnings=()

# --- (a) Extract Goal section to CLAUDE.md ---
# Goal extraction preserves interior blank lines (multi-paragraph goals are valid markdown).
# Only strips leading/trailing blank lines.
goal_content=$(awk '
    /^## Goal$/ { flag=1; next }
    flag && /^## / { flag=0 }
    flag { print }
' "$LEGACY_FILE" | awk '
    NF { found=1; lines[++n]=$0; last=n }
    !NF && found { lines[++n]=$0 }
    END {
        for (i=1; i<=last; i++) print lines[i]
    }
')
goal_placeholder='[PROJECT GOAL - One sentence describing what we'"'"'re building]'

# Trim before comparison to tolerate user-added whitespace variations.
goal_trimmed=$(echo "$goal_content" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')

if [ -n "$goal_trimmed" ] && [ "$goal_trimmed" != "$goal_placeholder" ]; then
    if [ -f "CLAUDE.md" ]; then
        if grep -q "^## Project Overview" CLAUDE.md; then
            # Sentinel was already prepended unconditionally above -- no need to duplicate here.
            tmp=$(mktemp)
            awk -v goal="$goal_content" '
                /^## Project Overview$/ { print; print ""; print "### Goal"; print ""; print goal; print ""; next }
                { print }
            ' CLAUDE.md > "$tmp" && mv "$tmp" CLAUDE.md
            moved_sections+=("Goal -> CLAUDE.md (under ## Project Overview)")
        else
            skipped_sections+=("Goal (CLAUDE.md has no ## Project Overview section)")
        fi
    else
        skipped_sections+=("Goal (CLAUDE.md not present)")
    fi
else
    skipped_sections+=("Goal (placeholder content; not migrated)")
fi

# --- (b) Extract Architecture/Key Decisions table rows to per-file ADRs ---
decisions_section=$(awk '
    /^## (Architecture Decisions|Key Decisions)$/ { flag=1; next }
    flag && /^## / { flag=0 }
    flag { print }
' "$LEGACY_FILE")

if [ -n "$decisions_section" ]; then
    # Find next available ADR number using glob-safe shell (NOT [ -f "...*..." ]).
    next_num=6
    while compgen -G "docs/adr/$(printf '%04d' "$next_num")-*.md" >/dev/null 2>&1; do
        next_num=$((next_num + 1))
    done

    while IFS= read -r line; do
        # Only data rows of a markdown pipe table.
        [[ "$line" =~ ^\|.*\|$ ]] || continue
        # Skip header (first cell == "Decision").
        [[ "$line" =~ ^\|[[:space:]]*Decision[[:space:]]*\| ]] && continue
        # Skip separator (cells are dashes / colons).
        [[ "$line" =~ ^\|[[:space:]]*[:-] ]] && continue
        # Skip empty/whitespace-only rows.
        stripped=$(echo "$line" | sed 's/[[:space:]|]//g')
        [ -z "$stripped" ] && continue

        decision=$(echo "$line" | awk -F'|' '{print $2}' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
        choice=$(echo "$line"   | awk -F'|' '{print $3}' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
        why=$(echo "$line"      | awk -F'|' '{print $4}' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')

        # Skip rows where decision OR choice is empty after trimming.
        [ -z "$decision" ] && continue
        [ -z "$choice" ] && continue

        slug=$(echo "$decision" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9' '-' | sed 's/--*/-/g; s/^-//; s/-$//')
        adr_num=$(printf '%04d' "$next_num")
        adr_file="docs/adr/${adr_num}-${slug}.md"

        # Idempotency at the slug level -- if any ADR already has this slug, skip.
        if compgen -G "docs/adr/*-${slug}.md" >/dev/null 2>&1; then
            skipped_sections+=("Decision '$decision' (ADR with slug '${slug}' already exists)")
            continue
        fi

        mkdir -p docs/adr
        cat > "$adr_file" <<EOF
# ${adr_num} -- ${decision}

## Status

Accepted (migrated $(date +%Y-%m-%d))

## Context

Migrated from legacy CONTINUITY.md Architecture Decisions table.

## Considered Options

- **${choice} (chosen)**

## Decision

${choice}

## Consequences

${why:-(empty in legacy CONTINUITY.md - please fill in)}
EOF
        created_adrs+=("$adr_file")
        moved_sections+=("Decision '$decision' -> $adr_file")
        next_num=$((next_num + 1))
    done <<< "$decisions_section"
fi

# --- (c) Extract volatile sections to .claude/local/state.md ---
# state.md presence already verified at the top (sentinel-write block).
# Done: keep the LAST 3 entries (most recent), not the first.
# POSIX awk: use [[:space:]] not \s (BSD awk + portability).
done_section=$(awk '
    /^### Done([[:space:]]|$|[^[:alnum:]])/ { flag=1; next }
    flag && /^### / { flag=0 }
    flag && /^- / { print }
' "$LEGACY_FILE" | tail -3)

if [ -n "$done_section" ]; then
    # Sentinel is already on line 1 of state.md (unconditional write at top).
    tmp=$(mktemp)
    awk -v done_content="$done_section" '
        /^### Done/ { in_done=1; print; print ""; print done_content; print ""; next }
        in_done && /^### / { in_done=0 }
        in_done { next }
        { print }
    ' .claude/local/state.md > "$tmp" && mv "$tmp" .claude/local/state.md
    moved_sections+=("Done (last 3 entries) -> .claude/local/state.md")
fi

# Now/Next: same idea, replace placeholder content with migrated content.
# Already using [[:space:]] (POSIX-portable across BSD and GNU awk).
for section in Now Next; do
    section_content=$(awk -v s="$section" '
        $0 ~ "^### "s"([[:space:]]|$|[^[:alnum:]])" { flag=1; next }
        flag && /^### / { flag=0 }
        flag
    ' "$LEGACY_FILE")
    if [ -n "$section_content" ]; then
        tmp=$(mktemp)
        awk -v sec="$section" -v content="$section_content" '
            $0 ~ "^### "sec"([[:space:]]|$|[^[:alnum:]])" { in_sec=1; print; print ""; print content; next }
            in_sec && /^### / { in_sec=0; print; next }
            in_sec { next }
            { print }
        ' .claude/local/state.md > "$tmp" && mv "$tmp" .claude/local/state.md
        moved_sections+=("$section -> .claude/local/state.md")
    fi
done

# --- (d) Flag dangling @CONTINUITY.md import in CLAUDE.md ---
if [ -f "CLAUDE.md" ] && grep -qE '^@CONTINUITY\.md\b' CLAUDE.md; then
    warnings+=("CLAUDE.md still contains a '@CONTINUITY.md' dangling import - Claude Code silently ignores missing imports, but you may want to remove the line manually for cleanliness.")
fi

# --- (e) Print summary (ASCII-safe characters for AC-4 byte-equivalence with PS) ---
echo "Migration complete."
echo ""
echo "Moved:"
if [ ${#moved_sections[@]} -eq 0 ]; then
    echo "  (nothing - content was either placeholder or already migrated)"
else
    for s in "${moved_sections[@]}"; do echo "  + $s"; done
fi
echo ""
if [ ${#skipped_sections[@]} -gt 0 ]; then
    echo "Skipped:"
    for s in "${skipped_sections[@]}"; do echo "  . $s"; done
    echo ""
fi
if [ ${#created_adrs[@]} -gt 0 ]; then
    echo "ADRs created:"
    for a in "${created_adrs[@]}"; do echo "  + $a"; done
    echo ""
fi
if [ ${#warnings[@]} -gt 0 ]; then
    echo "Warnings:"
    for w in "${warnings[@]}"; do echo "  ! $w"; done
    echo ""
fi
echo "Original CONTINUITY.md was preserved in place (byte-for-byte)."
echo "Review the migrated content, then delete CONTINUITY.md when satisfied."
exit 0
