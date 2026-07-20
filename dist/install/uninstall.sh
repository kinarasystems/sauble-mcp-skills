#!/usr/bin/env bash
# ABOUTME: Removes the Sauble skill pack from Codex/Cursor/Windsurf on macOS/Linux,
# ABOUTME: deleting only sauble-mcp-* skills and the `sauble` MCP entry (other packs/config untouched).
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST="$(cd "$HERE/.." && pwd)"

AGENT="${1:-}"; shift || true
[ -z "$AGENT" ] && { echo "Usage: uninstall.sh <codex|cursor|windsurf> [--project DIR]" >&2; exit 1; }
PROJECT_DIR="$PWD"
[ "${1:-}" = "--project" ] && PROJECT_DIR="${2:-$PWD}"

backup() { [ -f "$1" ] && cp "$1" "$1.bak.$(date +%Y%m%d%H%M%S)-$$-$RANDOM"; }

remove_skills() {
  local target="$1"
  [ -d "$target" ] || return 0
  local n=0
  # Only sauble-mcp-* — never the internal sauble-* developer skill pack.
  for d in "$target"/sauble-mcp-*/; do
    [ -d "$d" ] || continue
    rm -rf "$d"; n=$((n+1))
  done
  echo "  removed $n sauble-mcp-* skills from $target"
}

# Delete .mcpServers.sauble from a JSON config, leaving all other servers/settings intact.
remove_json() {
  local target="$1"
  [ -f "$target" ] || return 0
  backup "$target"
  SAUBLE_TARGET="$target" python3 - <<'PY'
import json, os
target = os.environ["SAUBLE_TARGET"]
with open(target) as fh:
    data = json.load(fh)
servers = data.get("mcpServers", {})
if servers.pop("sauble", None) is not None:
    tmp = target + ".tmp"
    with open(tmp, "w") as fh:
        json.dump(data, fh, indent=2); fh.write("\n")
    os.replace(tmp, target)
    print(f"  removed sauble server from {target}")
else:
    print(f"  no sauble server in {target}")
PY
}

# Remove the [mcp_servers.sauble] table (header through the line before the next
# table header, or EOF) from TOML. Blank/comment lines inside the table belong to it.
remove_toml() {
  local target="$1"
  [ -f "$target" ] || return 0
  grep -q '^\[mcp_servers\.sauble\]' "$target" || { echo "  no sauble server in $target"; return 0; }
  backup "$target"
  SAUBLE_TARGET="$target" python3 - <<'PY'
import os
target = os.environ["SAUBLE_TARGET"]
lines = open(target).read().splitlines()
out, skip = [], False
for line in lines:
    if line.strip() == "[mcp_servers.sauble]":
        skip = True
        continue
    if skip:
        # The table ends only at the next table header (or EOF).
        if line.lstrip().startswith("["):
            skip = False
            out.append(line)
        continue
    out.append(line)
with open(target, "w") as fh:
    fh.write("\n".join(out).rstrip("\n") + "\n")
print(f"  removed [mcp_servers.sauble] from {target}")
PY
}

case "$AGENT" in
  codex)
    remove_skills "$HOME/.codex/skills"; remove_skills "$PROJECT_DIR/.agents/skills"
    remove_toml "$HOME/.codex/config.toml" ;;
  cursor)
    remove_skills "$PROJECT_DIR/.agents/skills"
    remove_json "$HOME/.cursor/mcp.json"; remove_json "$PROJECT_DIR/.cursor/mcp.json" ;;
  windsurf)
    remove_skills "$HOME/.windsurf/skills"; remove_skills "$PROJECT_DIR/.windsurf/skills"
    remove_json "$HOME/.codeium/windsurf/mcp_config.json" ;;
  *) echo "Unknown agent: $AGENT" >&2; exit 1 ;;
esac

rm -f "$HOME/.agents/sauble-mcp-install.json"
echo "Done. Sauble skill pack removed for $AGENT."
