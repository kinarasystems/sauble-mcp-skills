#!/usr/bin/env bash
# ABOUTME: Installs the Sauble skill pack into Codex/Cursor/Windsurf on macOS/Linux,
# ABOUTME: merging into existing MCP config non-destructively (backup + never overwrite other servers).
set -euo pipefail

# Resolve the dist root (this script lives in dist/install/).
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST="$(cd "$HERE/.." && pwd)"
SKILLS_SRC="$DIST/skills"

usage() {
  cat <<'EOF'
Usage: install.sh <codex|cursor|windsurf|windsurf-jetbrains> [options]

  windsurf            the standalone Windsurf editor (~/.windsurf/skills + ~/.codeium/windsurf)
  windsurf-jetbrains  the JetBrains "Windsurf Plugin" (Codeium): ~/.codeium/skills + ~/.codeium/mcp_config.json
  --global        install skills into the user-global skills dir (default for codex/windsurf)
  --project DIR   install skills into DIR/.agents (cursor/codex) or DIR/.windsurf (default: cwd)
  --skills-only   install skills, skip MCP server registration
  --mcp-only      register the MCP server, skip skills
  --url URL       Sauble MCP URL (Codex needs a literal URL; defaults to $SAUBLE_MCP_URL)
  -h, --help      show this help

Nothing is overwritten: existing MCP config is backed up and only the `sauble` server
entry is added/updated; existing servers and skills are left untouched.
EOF
}

AGENT="${1:-}"; shift || true
[ -z "$AGENT" ] && { usage; exit 1; }
case "$AGENT" in codex|cursor|windsurf|windsurf-jetbrains) ;; -h|--help) usage; exit 0 ;; *) echo "Unknown agent: $AGENT" >&2; usage; exit 1 ;; esac

SCOPE="global"; PROJECT_DIR="$PWD"; DO_SKILLS=1; DO_MCP=1; MCP_URL="${SAUBLE_MCP_URL:-}"
while [ $# -gt 0 ]; do
  case "$1" in
    --global) SCOPE="global" ;;
    --project) SCOPE="project"; PROJECT_DIR="${2:-$PWD}"; shift ;;
    --skills-only) DO_MCP=0 ;;
    --mcp-only) DO_SKILLS=0 ;;
    --url) MCP_URL="${2:-}"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
  shift
done

backup() { [ -f "$1" ] && cp "$1" "$1.bak.$(date +%Y%m%d%H%M%S)-$$-$RANDOM" && echo "  backed up $1"; }

install_skills() {
  local target="$1"
  mkdir -p "$target"
  local n=0
  for d in "$SKILLS_SRC"/*/; do
    # Namespace with sauble-mcp- (NOT sauble-) so we never collide with the
    # internal sauble-* developer skill pack sharing the same skills dir.
    local name; name="sauble-mcp-$(basename "$d")"
    rm -rf "${target:?}/$name"
    cp -R "$d" "$target/$name"
    n=$((n+1))
  done
  echo "  installed $n skills into $target (as sauble-mcp-*)"
}

# Safe JSON merge: set .mcpServers.sauble = <fragment> in target, preserving everything else.
merge_json() {
  local target="$1" fragment="$2"
  mkdir -p "$(dirname "$target")"
  backup "$target"
  SAUBLE_TARGET="$target" SAUBLE_FRAGMENT="$fragment" python3 - <<'PY'
import json, os
target = os.environ["SAUBLE_TARGET"]
fragment = json.load(open(os.environ["SAUBLE_FRAGMENT"]))
try:
    with open(target) as fh:
        data = json.load(fh)
except (FileNotFoundError, json.JSONDecodeError):
    data = {}
servers = data.setdefault("mcpServers", {})
servers["sauble"] = fragment["mcpServers"]["sauble"]
tmp = target + ".tmp"
with open(tmp, "w") as fh:
    json.dump(data, fh, indent=2)
    fh.write("\n")
os.replace(tmp, target)
print(f"  merged sauble server into {target} (other servers untouched)")
PY
}

# Remove the [mcp_servers.sauble] table (header through the line before the next
# table header, or EOF) from a TOML file. Blank/comment lines inside the table
# belong to it. No-op if the table isn't present.
remove_sauble_toml() {
  local target="$1"
  [ -f "$target" ] || return 0
  grep -q '^\[mcp_servers\.sauble\]' "$target" || return 0
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
        # The table ends at the next table header; everything until then is ours.
        if line.lstrip().startswith("["):
            skip = False
            out.append(line)
        continue
    out.append(line)
with open(target, "w") as fh:
    fh.write("\n".join(out).rstrip("\n") + "\n")
PY
}

case "$AGENT" in
  codex)
    [ "$SCOPE" = "global" ] && SKILLS_DIR="$HOME/.codex/skills" || SKILLS_DIR="$PROJECT_DIR/.agents/skills"
    [ "$DO_SKILLS" = 1 ] && install_skills "$SKILLS_DIR"
    if [ "$DO_MCP" = 1 ]; then
      CFG="$HOME/.codex/config.toml"; mkdir -p "$(dirname "$CFG")"; touch "$CFG"
      backup "$CFG"
      # Idempotent: drop any existing sauble block, then write the current one —
      # so a re-run with a changed --url updates in place, like the other tools.
      remove_sauble_toml "$CFG"
      block="$(cat "$DIST/mcp/codex.toml")"
      [ -n "$MCP_URL" ] && block="${block/https:\/\/YOUR-SAUBLE-INSTANCE\/mcp/$MCP_URL}"
      printf '\n%s\n' "$block" >> "$CFG"
      echo "  wrote [mcp_servers.sauble] to $CFG (other servers untouched)"
      [ -z "$MCP_URL" ] && echo "  NOTE: set the url in $CFG to your Sauble MCP URL (placeholder left in)."
    fi
    ;;
  cursor)
    # Cursor skills are project-scoped via .agents/skills.
    SKILLS_DIR="$PROJECT_DIR/.agents/skills"
    [ "$DO_SKILLS" = 1 ] && install_skills "$SKILLS_DIR"
    if [ "$DO_MCP" = 1 ]; then
      [ "$SCOPE" = "global" ] && CFG="$HOME/.cursor/mcp.json" || CFG="$PROJECT_DIR/.cursor/mcp.json"
      merge_json "$CFG" "$DIST/mcp/cursor.json"
      echo "  tip: one-click install also available — see dist/mcp/cursor-deeplink.txt"
    fi
    ;;
  windsurf)
    [ "$SCOPE" = "global" ] && SKILLS_DIR="$HOME/.windsurf/skills" || SKILLS_DIR="$PROJECT_DIR/.windsurf/skills"
    [ "$DO_SKILLS" = 1 ] && install_skills "$SKILLS_DIR"
    if [ "$DO_MCP" = 1 ]; then
      CFG="$HOME/.codeium/windsurf/mcp_config.json"
      merge_json "$CFG" "$DIST/mcp/windsurf.json"
    fi
    ;;
  windsurf-jetbrains)
    # JetBrains "Windsurf Plugin" (Codeium): skills in ~/.codeium/skills, MCP config in
    # ~/.codeium/mcp_config.json - NOT the standalone editor's ~/.windsurf + ~/.codeium/windsurf
    # paths. User-global only; the plugin reads no project-scoped dirs, so --project is ignored.
    SKILLS_DIR="$HOME/.codeium/skills"
    [ "$DO_SKILLS" = 1 ] && install_skills "$SKILLS_DIR"
    if [ "$DO_MCP" = 1 ]; then
      CFG="$HOME/.codeium/mcp_config.json"
      merge_json "$CFG" "$DIST/mcp/windsurf.json"
    fi
    ;;
esac

# Record what we installed for a clean uninstall / version check.
META="$HOME/.agents/sauble-mcp-install.json"; mkdir -p "$(dirname "$META")"
printf '{\n  "version": "%s",\n  "agent": "%s",\n  "scope": "%s"\n}\n' \
  "$(cat "$DIST/VERSION")" "$AGENT" "$SCOPE" > "$META"

echo "Done. Sauble skill pack v$(cat "$DIST/VERSION") installed for $AGENT."
echo "Set SAUBLE_MCP_URL / SAUBLE_TOKEN / SAUBLE_ENVIRONMENT_ID in your environment before launching the agent."
