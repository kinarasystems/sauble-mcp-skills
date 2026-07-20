#!/usr/bin/env python3
# ABOUTME: Generates per-agent distribution artifacts (Codex/Cursor/Windsurf) from the
# ABOUTME: canonical Claude-plugin source, so one edit to the skills fans out to every tool.
"""Build the multi-agent distribution for the Sauble skill pack.

Source of truth (never generated):
    plugins/sauble/skills/<name>/SKILL.md   the skills, one open-standard format for all tools
    plugins/sauble/.mcp.json                the MCP server definition
    plugins/sauble/.claude-plugin/plugin.json  the canonical version

Generated into dist/ (checked in, kept in sync by CI):
    dist/VERSION                    the pack version, stamped from plugin.json
    dist/skills/<name>/SKILL.md     canonical copy of the skills every non-Claude tool installs
    dist/mcp/codex.toml             [mcp_servers.sauble] block for ~/.codex/config.toml
    dist/mcp/cursor.json            .cursor/mcp.json fragment
    dist/mcp/windsurf.json          ~/.codeium/windsurf/mcp_config.json fragment
    dist/mcp/cursor-deeplink.txt    one-click "Add to Cursor" deeplink
    dist/instructions.json          per-agent x per-OS instruction matrix (installers + UI consume this)
    dist/manifest.json              version + skill list + server def, for installer bookkeeping
    dist/AGENTS.md                  pointer file for Codex / .agents-skills consumers

The Claude Code channel is NOT generated: plugins/sauble/ already IS the Claude plugin.
"""

from __future__ import annotations

import base64
import json
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PLUGIN_DIR = ROOT / "plugins" / "sauble"
SKILLS_SRC = PLUGIN_DIR / "skills"
MCP_SRC = PLUGIN_DIR / ".mcp.json"
PLUGIN_JSON = PLUGIN_DIR / ".claude-plugin" / "plugin.json"
DIST = ROOT / "dist"

MARKETPLACE_REPO = "kinarasystems/sauble-mcp-skills"
SERVER_NAME = "sauble"
# Placeholder URL used in static artifacts. The UI templates the user's real MCP URL
# (known from signup) into these same shapes at render time.
PLACEHOLDER_URL = "https://YOUR-SAUBLE-INSTANCE/mcp"


def read_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def write_text(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if not content.endswith("\n"):
        content += "\n"
    # newline="\n" keeps LF on every platform. Without it, Windows translates "\n"
    # to CRLF and churns every generated artifact relative to the Unix/CI baseline.
    path.write_text(content, encoding="utf-8", newline="\n")


def write_json(path: Path, data: object) -> None:
    write_text(path, json.dumps(data, indent=2))


def parse_frontmatter(skill_md: Path) -> dict[str, str]:
    """Pull name/description out of a SKILL.md YAML frontmatter block."""
    text = skill_md.read_text(encoding="utf-8")
    if not text.startswith("---"):
        raise RuntimeError(f"{skill_md} missing frontmatter")
    _, fm, _body = text.split("---", 2)
    out: dict[str, str] = {}
    for line in fm.splitlines():
        if ":" in line and not line.startswith(" "):
            key, val = line.split(":", 1)
            val = val.strip()
            # This is a deliberately small line-based parser, not a YAML engine.
            # A block scalar (`>` / `|`) would silently truncate to the indicator,
            # so fail loudly instead — skills must use single-line name/description.
            if val in (">", "|", ">-", "|-", ">+", "|+"):
                raise RuntimeError(
                    f"{skill_md}: multi-line YAML scalar for '{key.strip()}' is not supported; "
                    "use a single-line value."
                )
            out[key.strip()] = val
    return out


def load_skills() -> list[dict]:
    skills = []
    for skill_dir in sorted(p for p in SKILLS_SRC.iterdir() if p.is_dir()):
        fm = parse_frontmatter(skill_dir / "SKILL.md")
        skills.append({"name": fm["name"], "description": fm["description"], "dir": skill_dir.name})
    return skills


def version() -> str:
    return read_json(PLUGIN_JSON)["version"]


# --- MCP config renderers (one per tool dialect) -----------------------------

def cursor_mcp() -> dict:
    """Cursor .cursor/mcp.json: url + headers, ${env:VAR} interpolation."""
    return {
        "mcpServers": {
            SERVER_NAME: {
                "url": "${env:SAUBLE_MCP_URL}",
                "headers": {
                    "X-API-Key": "${env:SAUBLE_TOKEN}",
                    "X-Environment-ID": "${env:SAUBLE_ENVIRONMENT_ID}",
                },
            }
        }
    }


def windsurf_mcp() -> dict:
    """Windsurf mcp_config.json: note serverUrl (not url), ${env:VAR} interpolation."""
    return {
        "mcpServers": {
            SERVER_NAME: {
                "serverUrl": "${env:SAUBLE_MCP_URL}",
                "headers": {
                    "X-API-Key": "${env:SAUBLE_TOKEN}",
                    "X-Environment-ID": "${env:SAUBLE_ENVIRONMENT_ID}",
                },
            }
        }
    }


def codex_toml() -> str:
    """Codex config.toml block. url is literal (Codex does not interpolate env in url);
    header VALUES are env-var NAMES that Codex reads at launch via env_http_headers."""
    return (
        f"[mcp_servers.{SERVER_NAME}]\n"
        f'url = "{PLACEHOLDER_URL}"\n'
        'env_http_headers = { "X-API-Key" = "SAUBLE_TOKEN", "X-Environment-ID" = "SAUBLE_ENVIRONMENT_ID" }\n'
    )


def cursor_deeplink() -> str:
    """cursor://anysphere.cursor-deeplink/mcp/install?name=..&config=<base64 json>."""
    config = cursor_mcp()["mcpServers"][SERVER_NAME]
    encoded = base64.b64encode(json.dumps(config).encode("utf-8")).decode("ascii")
    return f"cursor://anysphere.cursor-deeplink/mcp/install?name={SERVER_NAME}&config={encoded}"


# --- The instruction matrix: agent x OS --------------------------------------
# Consumed by the CLI installers AND the sauble-ui #skill component so instructions
# never drift between the two. OS profiles: "posix" covers macOS + Linux (identical
# for our purposes); "windows" is PowerShell.

def env_lines(profile: str) -> list[str]:
    keys = ["SAUBLE_MCP_URL", "SAUBLE_TOKEN", "SAUBLE_ENVIRONMENT_ID"]
    if profile == "windows":
        return [f'$env:{k} = "<{k}>"' for k in keys]
    return [f"export {k}=<{k}>" for k in keys]


def config_paths(profile: str) -> dict[str, str]:
    home = "%USERPROFILE%" if profile == "windows" else "~"
    sep = "\\" if profile == "windows" else "/"
    def p(*parts: str) -> str:
        return sep.join([home, *parts])
    return {
        "codex_toml": p(".codex", "config.toml"),
        "codex_skills": p(".codex", "skills"),
        "cursor_mcp": p(".cursor", "mcp.json"),
        "windsurf_mcp": p(".codeium", "windsurf", "mcp_config.json"),
        "windsurf_skills": p(".windsurf", "skills"),
        "agents_skills": p(".agents", "skills"),
    }


def instruction_matrix(skills: list[dict]) -> dict:
    os_profiles = [
        {"id": "posix", "label": "macOS / Linux", "shell": "bash/zsh"},
        {"id": "windows", "label": "Windows", "shell": "PowerShell"},
    ]
    agents = [
        {
            "id": "claude-code",
            "label": "Claude Code",
            "connect": "plugin",
            "skills_source": "bundled with the plugin",
            "install": [
                f"/plugin marketplace add {MARKETPLACE_REPO}",
                f"/plugin install {SERVER_NAME}-mcp@sauble-mcp-skills",
            ],
            "update": "In Claude Code: /plugin marketplace update sauble-mcp-skills, then reinstall (or enable auto-update in the /plugin Marketplaces tab).",
            "note": "Export the three variables in your shell before launching Claude Code — the bundled MCP server reads them at startup.",
        },
        {
            "id": "codex",
            "label": "Codex",
            "connect": "config-block",
            "config_file": "codex_toml",
            "config_kind": "toml",
            "skills_dir": "codex_skills",
            "skills_dir_alt": "agents_skills",
            "install": None,  # rendered from dist/mcp/codex.toml + skill copy
            "update": "Re-run the installer (or copy the latest skills into your skills dir). The MCP block only changes if your Sauble URL changes.",
            "note": "codex mcp add cannot set custom headers, so add the block below to your Codex config (or use the installer, which appends it safely without touching your other servers).",
        },
        {
            "id": "cursor",
            "label": "Cursor",
            "connect": "deeplink-or-config",
            "config_file": "cursor_mcp",
            "config_kind": "json",
            "skills_dir": "agents_skills",
            "update": "Re-run the installer or re-copy the skills folder. Cursor rediscovers skills on restart.",
            "note": "Use the one-click Add-to-Cursor link (Cursor merges it into your mcp.json for you), or add the fragment below.",
        },
        {
            "id": "windsurf",
            "label": "Windsurf",
            "connect": "ui-or-config",
            "config_file": "windsurf_mcp",
            "config_kind": "json",
            "skills_dir": "windsurf_skills",  # .windsurf/skills — distinct from the MCP config file
            "update": "Replace the skills folder with the new version and reload Windsurf.",
            "note": "Add the server via Windsurf's Plugins UI, or paste the fragment below into mcp_config.json.",
        },
    ]
    return {
        "version": version(),
        "server_name": SERVER_NAME,
        "marketplace_repo": MARKETPLACE_REPO,
        "env_vars": ["SAUBLE_MCP_URL", "SAUBLE_TOKEN", "SAUBLE_ENVIRONMENT_ID"],
        "skills": [{"name": s["name"], "description": s["description"]} for s in skills],
        "os": {
            prof["id"]: {
                "label": prof["label"],
                "shell": prof["shell"],
                "env_lines": env_lines(prof["id"]),
                "paths": config_paths(prof["id"]),
            }
            for prof in os_profiles
        },
        "agents": agents,
    }


def copy_skills() -> None:
    dest = DIST / "skills"
    if dest.exists():
        shutil.rmtree(dest)
    shutil.copytree(SKILLS_SRC, dest)


def copy_installers() -> None:
    """Copy the static installer scripts into dist/install/, preserving exec bits.

    PowerShell scripts are written with a UTF-8 BOM. Windows PowerShell 5.1 decodes a
    BOM-less .ps1 as the system ANSI codepage, so any non-ASCII byte (e.g. an em-dash)
    turns into stray characters that break parsing; a BOM forces UTF-8 decoding. The
    templates themselves stay BOM-free for clean diffs, so the BOM is added here at
    copy time. Shell scripts must stay BOM-free (a BOM breaks the shebang line), so
    those are copied verbatim.
    """
    templates = ROOT / "packaging" / "templates"
    dest = DIST / "install"
    dest.mkdir(parents=True, exist_ok=True)
    bom = b"\xef\xbb\xbf"
    for script in sorted(templates.glob("install*")) + sorted(templates.glob("uninstall*")):
        target = dest / script.name
        if script.suffix == ".ps1":
            data = script.read_bytes()
            if not data.startswith(bom):
                data = bom + data
            target.write_bytes(data)
        else:
            shutil.copy2(script, target)
            if script.suffix == ".sh":
                target.chmod(0o755)


def main() -> None:
    skills = load_skills()
    ver = version()

    copy_skills()
    copy_installers()

    write_json(DIST / "mcp" / "cursor.json", cursor_mcp())
    write_json(DIST / "mcp" / "windsurf.json", windsurf_mcp())
    write_text(DIST / "mcp" / "codex.toml", codex_toml())
    write_text(DIST / "mcp" / "cursor-deeplink.txt", cursor_deeplink())

    write_json(DIST / "instructions.json", instruction_matrix(skills))
    write_json(
        DIST / "manifest.json",
        {
            "name": "sauble-mcp-skills",
            "version": ver,
            "server": read_json(MCP_SRC),
            "skills": [s["name"] for s in skills],
        },
    )
    write_text(DIST / "VERSION", ver)

    write_text(
        DIST / "AGENTS.md",
        "# Sauble skills\n\n"
        f"This directory ships the Sauble skill pack (v{ver}) for agents that read the open "
        "Agent Skills standard (Codex, Cursor via `.agents/skills`, and others).\n\n"
        "Each folder under `skills/` is a self-contained `SKILL.md`. Install with `install/install.sh` "
        "(macOS/Linux) or `install/install.ps1` (Windows). See the repo README for per-agent steps.\n",
    )

    print(f"Built dist/ for sauble-mcp-skills v{ver}: {len(skills)} skills, 3 non-Claude channels.")


if __name__ == "__main__":
    main()
