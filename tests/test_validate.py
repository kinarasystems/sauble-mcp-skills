# ABOUTME: Tests for scripts/validate.py — asserts the validator passes a good repo tree
# ABOUTME: and flags each failure mode the marketplace spec names (fields, tools, secrets).
import json
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
import validate  # noqa: E402

GOOD_SKILL = """---
name: connect-and-verify
description: Verify the Sauble connection and report tenant + permissions.
---
Call `validate_connection` first. Then you may `run_rca` or `run_analyze`.
"""


def _make_repo(tmp_path: Path, *, skill_body: str = GOOD_SKILL,
               mcp: dict | None = None, marketplace: dict | None = None) -> Path:
    root = tmp_path / "repo"
    plugin = root / "plugins" / "sauble"
    (plugin / ".claude-plugin").mkdir(parents=True)
    (root / ".claude-plugin").mkdir(parents=True)
    (plugin / "skills" / "connect-and-verify").mkdir(parents=True)

    (root / ".claude-plugin" / "marketplace.json").write_text(json.dumps(marketplace or {
        "name": "sauble-mcp-skills",
        "owner": {"name": "Kinara Systems"},
        "plugins": [{"name": "sauble", "source": "./plugins/sauble"}],
    }))
    (plugin / ".claude-plugin" / "plugin.json").write_text(json.dumps({
        "name": "sauble", "mcpServers": "./.mcp.json",
    }))
    (plugin / ".mcp.json").write_text(json.dumps(mcp or {
        "mcpServers": {"sauble": {"type": "http", "url": "${SAUBLE_MCP_URL}",
                                  "headers": {"X-API-Key": "${SAUBLE_TOKEN}",
                                              "X-Environment-ID": "${SAUBLE_ENVIRONMENT_ID}"}}}
    }))
    (plugin / "skills" / "connect-and-verify" / "SKILL.md").write_text(skill_body)
    return root


def test_good_repo_passes(tmp_path):
    assert validate.validate(_make_repo(tmp_path)) == []


def test_missing_marketplace_name_fails(tmp_path):
    root = _make_repo(tmp_path, marketplace={
        "owner": {"name": "Kinara Systems"},
        "plugins": [{"name": "sauble", "source": "./plugins/sauble"}],
    })
    assert any("name" in e for e in validate.validate(root))


def test_unknown_tool_name_fails(tmp_path):
    bad = """---
name: x
description: y
---
Use `get_rca_sessions` to fetch the session.
"""  # plural typo — not a real tool
    root = _make_repo(tmp_path, skill_body=bad)
    errors = validate.validate(root)
    assert any("get_rca_sessions" in e for e in errors)


def test_missing_description_fails(tmp_path):
    bad = """---
name: connect-and-verify
---
Call validate_connection.
"""
    root = _make_repo(tmp_path, skill_body=bad)
    assert any("description" in e for e in validate.validate(root))


def test_literal_secret_in_mcp_fails(tmp_path):
    root = _make_repo(tmp_path, mcp={
        "mcpServers": {"sauble": {"type": "http", "url": "${SAUBLE_MCP_URL}",
                                  "headers": {"X-API-Key": "sk_user_ABC123"}}}
    })
    assert any("secret" in e.lower() or "sk_" in e for e in validate.validate(root))


def test_nonenv_header_value_fails(tmp_path):
    root = _make_repo(tmp_path, mcp={
        "mcpServers": {"sauble": {"type": "http", "url": "${SAUBLE_MCP_URL}",
                                  "headers": {"X-API-Key": "literal-token"}}}
    })
    assert validate.validate(root) != []
