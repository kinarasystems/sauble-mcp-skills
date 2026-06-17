# ABOUTME: Validates the sauble-mcp-skills marketplace: manifest fields, real tool names,
# ABOUTME: and env-var-only MCP auth (no literal secrets). Stdlib only; exits non-zero on any problem.
import json
import re
import sys
from pathlib import Path

ALLOWED_TOOLS = {
    "validate_connection", "run_analyze", "run_rca",
    "get_analysis_session", "get_rca_session", "list_rca_sessions",
}
TOOL_RE = re.compile(r"\b(?:run|get|list|validate)_[a-z_]+\b")
ENV_REF_RE = re.compile(r"^\$\{[A-Z_]+\}$")
SECRET_RE = re.compile(r"sk_(?:user_)?[A-Za-z0-9]+")


def _load_json(path: Path, errors: list[str]):
    try:
        return json.loads(path.read_text())
    except FileNotFoundError:
        errors.append(f"missing file: {path}")
    except json.JSONDecodeError as exc:
        errors.append(f"invalid JSON in {path}: {exc}")
    return None


def _parse_frontmatter(text: str) -> dict:
    if not text.startswith("---"):
        return {}
    end = text.find("\n---", 3)
    if end == -1:
        return {}
    block = text[3:end]
    fields = {}
    for line in block.splitlines():
        if ":" in line:
            key, _, value = line.partition(":")
            fields[key.strip()] = value.strip()
    return fields


def _check_skill(skill_md: Path, errors: list[str]) -> None:
    text = skill_md.read_text()
    fm = _parse_frontmatter(text)
    if not fm.get("name"):
        errors.append(f"{skill_md}: frontmatter missing non-empty 'name'")
    if not fm.get("description"):
        errors.append(f"{skill_md}: frontmatter missing non-empty 'description'")
    for tool in set(TOOL_RE.findall(text)):
        if tool not in ALLOWED_TOOLS:
            errors.append(f"{skill_md}: unknown tool name '{tool}' "
                          f"(allowed: {sorted(ALLOWED_TOOLS)})")


def _check_mcp(mcp_path: Path, errors: list[str]) -> None:
    raw = mcp_path.read_text()
    for hit in SECRET_RE.findall(raw):
        errors.append(f"{mcp_path}: literal secret-like token '{hit}' (use ${{ENV_VAR}})")
    data = _load_json(mcp_path, errors)
    if not data:
        return
    for server in data.get("mcpServers", {}).values():
        for hname, hvalue in server.get("headers", {}).items():
            if not ENV_REF_RE.match(str(hvalue)):
                errors.append(f"{mcp_path}: header '{hname}' must be a ${{ENV_VAR}} ref, got {hvalue!r}")


def validate(repo_root: Path | str) -> list[str]:
    repo_root = Path(repo_root)
    errors: list[str] = []

    market = _load_json(repo_root / ".claude-plugin" / "marketplace.json", errors)
    if market:
        if not market.get("name"):
            errors.append("marketplace.json: missing 'name'")
        if not market.get("owner", {}).get("name"):
            errors.append("marketplace.json: missing 'owner.name'")
        plugins = market.get("plugins") or []
        if not plugins:
            errors.append("marketplace.json: empty 'plugins'")
        for entry in plugins:
            if not entry.get("name") or not entry.get("source"):
                errors.append(f"marketplace.json: plugin entry needs 'name' + 'source': {entry}")
                continue
            plugin_dir = (repo_root / entry["source"]).resolve()
            plugin_json = _load_json(plugin_dir / ".claude-plugin" / "plugin.json", errors)
            if plugin_json:
                if not plugin_json.get("name"):
                    errors.append(f"{plugin_dir}/.claude-plugin/plugin.json: missing 'name'")
                mcp_ref = plugin_json.get("mcpServers")
                if isinstance(mcp_ref, str):
                    _check_mcp(plugin_dir / mcp_ref, errors)
            for skill_md in sorted((plugin_dir / "skills").glob("*/SKILL.md")):
                _check_skill(skill_md, errors)
    return errors


def main() -> int:
    root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parents[1]
    errors = validate(root)
    if errors:
        print(f"FAIL ({len(errors)} problem(s)):")
        for err in errors:
            print(f"  - {err}")
        return 1
    print("OK: marketplace, plugin, skills, and MCP config are valid.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
