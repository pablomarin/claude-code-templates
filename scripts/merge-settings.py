#!/usr/bin/env python3
"""Merge template settings/MCP JSON into existing user files.

Strategy: add-only, never remove.
- Objects (hooks, enabledPlugins, mcpServers): add new keys, skip existing
- Arrays (permissions.allow/deny/ask): append items not already present
- Creates timestamped backup before modifying

Usage:
    python3 merge-settings.py <template_file> <user_file>

Exit codes:
    0 = merged successfully (or no changes needed)
    1 = error
"""

import json
import sys
import shutil
from datetime import datetime
from pathlib import Path


def merge_arrays(template_arr, user_arr):
    """Append items from template that aren't already in user's array."""
    added = []
    for item in template_arr:
        if item not in user_arr:
            user_arr.append(item)
            added.append(item)
    return added


def merge_objects(template_obj, user_obj):
    """Add keys from template that don't exist in user's object."""
    added = []
    for key, value in template_obj.items():
        if key not in user_obj:
            user_obj[key] = value
            added.append(key)
    return added


def merge_settings(template, user):
    """Merge settings.json: hooks, permissions, enabledPlugins."""
    changes = []

    # Merge enabledPlugins (add new plugins)
    if "enabledPlugins" in template:
        if "enabledPlugins" not in user:
            user["enabledPlugins"] = {}
        added = merge_objects(template["enabledPlugins"], user["enabledPlugins"])
        if added:
            changes.append(f"  Added plugins: {', '.join(added)}")

    # Merge permissions arrays
    if "permissions" in template:
        if "permissions" not in user:
            user["permissions"] = {}
        for key in ("allow", "deny", "ask"):
            if key in template["permissions"]:
                if key not in user["permissions"]:
                    user["permissions"][key] = []
                added = merge_arrays(template["permissions"][key], user["permissions"][key])
                if added:
                    changes.append(f"  Added permissions.{key}: {', '.join(added)}")

    # Merge hooks (add new hook events, skip existing)
    if "hooks" in template:
        if "hooks" not in user:
            user["hooks"] = {}
        added = merge_objects(template["hooks"], user["hooks"])
        if added:
            changes.append(f"  Added hook events: {', '.join(added)}")

    return changes


def merge_mcp(template, user):
    """Merge .mcp.json: add new MCP servers."""
    changes = []

    if "mcpServers" in template:
        if "mcpServers" not in user:
            user["mcpServers"] = {}
        added = merge_objects(template["mcpServers"], user["mcpServers"])
        if added:
            changes.append(f"  Added MCP servers: {', '.join(added)}")

    return changes


def main():
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <template_file> <user_file>", file=sys.stderr)
        sys.exit(1)

    template_path = Path(sys.argv[1])
    user_path = Path(sys.argv[2])

    if not template_path.exists():
        print(f"Template not found: {template_path}", file=sys.stderr)
        sys.exit(1)

    if not user_path.exists():
        # No existing file — just copy template
        shutil.copy2(template_path, user_path)
        print(f"  Created {user_path} (new)")
        sys.exit(0)

    # Load both files
    try:
        template = json.loads(template_path.read_text())
    except json.JSONDecodeError as e:
        print(f"Invalid JSON in template {template_path}: {e}", file=sys.stderr)
        sys.exit(1)

    try:
        user = json.loads(user_path.read_text())
    except json.JSONDecodeError as e:
        print(f"Invalid JSON in {user_path}: {e}", file=sys.stderr)
        print(f"  Backing up and replacing with template", file=sys.stderr)
        backup = user_path.with_suffix(f".bak.{datetime.now().strftime('%Y%m%d%H%M%S')}")
        shutil.copy2(user_path, backup)
        shutil.copy2(template_path, user_path)
        print(f"  Backup: {backup}")
        sys.exit(0)

    # Detect file type by content
    if "mcpServers" in template:
        changes = merge_mcp(template, user)
    else:
        changes = merge_settings(template, user)

    if not changes:
        print(f"  {user_path.name}: already up to date")
        sys.exit(0)

    # Backup before modifying
    backup = user_path.with_suffix(f".bak.{datetime.now().strftime('%Y%m%d%H%M%S')}")
    shutil.copy2(user_path, backup)

    # Write merged result
    user_path.write_text(json.dumps(user, indent=2) + "\n")

    print(f"  Upgraded {user_path.name} (backup: {backup.name}):")
    for change in changes:
        print(change)


if __name__ == "__main__":
    main()
