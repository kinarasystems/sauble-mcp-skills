# ABOUTME: Removes the Sauble skill pack from Codex/Cursor/Windsurf on Windows,
# ABOUTME: deleting only sauble-mcp-* skills and the `sauble` MCP entry (other packs/config untouched).
[CmdletBinding()]
param(
  [Parameter(Mandatory=$true, Position=0)]
  [ValidateSet('codex','cursor','windsurf','windsurf-jetbrains')]
  [string]$Agent,
  [string]$ProjectDir = (Get-Location).Path
)
$ErrorActionPreference = 'Stop'
$Home_ = $env:USERPROFILE

# Write UTF-8 without a BOM (PowerShell 5.1's -Encoding utf8 adds one, which
# strict JSON/TOML parsers reject and would corrupt the user's config).
function Write-Text($path, $text) {
  [System.IO.File]::WriteAllText($path, $text, (New-Object System.Text.UTF8Encoding($false)))
}

function Backup-File($path) {
  if (Test-Path $path) {
    $stamp = (Get-Date -Format 'yyyyMMddHHmmssfff') + "-$PID-$(Get-Random)"
    Copy-Item $path "$path.bak.$stamp"
  }
}

function Remove-Skills($target) {
  if (-not (Test-Path $target)) { return }
  # Only sauble-mcp-* - never the internal sauble-* developer skill pack.
  $dirs = Get-ChildItem -Directory $target -Filter 'sauble-mcp-*' -ErrorAction SilentlyContinue
  foreach ($d in $dirs) { Remove-Item -Recurse -Force $d.FullName }
  Write-Host "  removed $($dirs.Count) sauble-mcp-* skills from $target"
}

# Delete .mcpServers.sauble from a JSON config, leaving other servers/settings intact.
function Remove-Json($target) {
  if (-not (Test-Path $target)) { return }
  Backup-File $target
  $data = Get-Content $target -Raw | ConvertFrom-Json
  if ($data.PSObject.Properties['mcpServers'] -and $data.mcpServers.PSObject.Properties['sauble']) {
    $data.mcpServers.PSObject.Properties.Remove('sauble')
    Write-Text $target (($data | ConvertTo-Json -Depth 100) + "`n")
    Write-Host "  removed sauble server from $target"
  } else { Write-Host "  no sauble server in $target" }
}

# Remove the [mcp_servers.sauble] table (header through the line before the next
# table header, or EOF) from TOML. Blank/comment lines inside the table belong to it.
function Remove-Toml($target) {
  if (-not (Test-Path $target)) { return }
  if (-not (Select-String -Path $target -Pattern '^\[mcp_servers\.sauble\]' -Quiet)) {
    Write-Host "  no sauble server in $target"; return
  }
  Backup-File $target
  $out = New-Object System.Collections.Generic.List[string]
  $skip = $false
  foreach ($line in Get-Content $target) {
    if ($line.Trim() -eq '[mcp_servers.sauble]') { $skip = $true; continue }
    if ($skip) {
      # The table ends only at the next table header (or EOF).
      if ($line.TrimStart().StartsWith('[')) { $skip = $false; $out.Add($line) }
      continue
    }
    $out.Add($line)
  }
  Write-Text $target (($out -join "`n").TrimEnd() + "`n")
  Write-Host "  removed [mcp_servers.sauble] from $target"
}

switch ($Agent) {
  'codex' {
    Remove-Skills (Join-Path $Home_ '.codex\skills')
    Remove-Skills (Join-Path $ProjectDir '.agents\skills')
    Remove-Toml (Join-Path $Home_ '.codex\config.toml')
  }
  'cursor' {
    Remove-Skills (Join-Path $ProjectDir '.agents\skills')
    Remove-Json (Join-Path $Home_ '.cursor\mcp.json')
    Remove-Json (Join-Path $ProjectDir '.cursor\mcp.json')
  }
  'windsurf' {
    Remove-Skills (Join-Path $Home_ '.windsurf\skills')
    Remove-Skills (Join-Path $ProjectDir '.windsurf\skills')
    Remove-Json (Join-Path $Home_ '.codeium\windsurf\mcp_config.json')
  }
  'windsurf-jetbrains' {
    Remove-Skills (Join-Path $Home_ '.codeium\skills')
    Remove-Json (Join-Path $Home_ '.codeium\mcp_config.json')
  }
}

Remove-Item -Force -ErrorAction SilentlyContinue (Join-Path $Home_ '.agents\sauble-mcp-install.json')
Write-Host "Done. Sauble skill pack removed for $Agent."
