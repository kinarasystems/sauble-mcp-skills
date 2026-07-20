# ABOUTME: Installs the Sauble skill pack into Codex/Cursor/Windsurf on Windows,
# ABOUTME: merging into existing MCP config non-destructively (backup + never overwrite other servers).
[CmdletBinding()]
param(
  [Parameter(Mandatory=$true, Position=0)]
  [ValidateSet('codex','cursor','windsurf')]
  [string]$Agent,
  [ValidateSet('global','project')]
  [string]$Scope = 'global',
  [string]$ProjectDir = (Get-Location).Path,
  [switch]$SkillsOnly,
  [switch]$McpOnly,
  [string]$Url = $env:SAUBLE_MCP_URL
)
$ErrorActionPreference = 'Stop'

$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
$Dist = Split-Path -Parent $Here
$SkillsSrc = Join-Path $Dist 'skills'
$Version = (Get-Content (Join-Path $Dist 'VERSION') -Raw).Trim()

# Write UTF-8 WITHOUT a BOM. Windows PowerShell 5.1's `-Encoding utf8` prepends a
# BOM, which strict JSON/TOML parsers reject - that would corrupt the user's
# existing config on rewrite. This helper is BOM-free on both 5.1 and 7+.
function Write-Text($path, $text) {
  [System.IO.File]::WriteAllText($path, $text, (New-Object System.Text.UTF8Encoding($false)))
}

function Backup-File($path) {
  if (Test-Path $path) {
    $stamp = (Get-Date -Format 'yyyyMMddHHmmssfff') + "-$PID-$(Get-Random)"
    Copy-Item $path "$path.bak.$stamp"
    Write-Host "  backed up $path"
  }
}

function Install-Skills($target) {
  New-Item -ItemType Directory -Force -Path $target | Out-Null
  $n = 0
  Get-ChildItem -Directory $SkillsSrc | ForEach-Object {
    # Namespace sauble-mcp- (not sauble-) to avoid clobbering the internal sauble-* dev pack.
    $name = "sauble-mcp-$($_.Name)"
    $dest = Join-Path $target $name
    if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
    Copy-Item -Recurse $_.FullName $dest
    $n++
  }
  Write-Host "  installed $n skills into $target (as sauble-mcp-*)"
}

# Safe JSON merge using native cmdlets: set .mcpServers.sauble, preserve the rest.
function Merge-Json($target, $fragmentPath) {
  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
  Backup-File $target
  $fragment = Get-Content $fragmentPath -Raw | ConvertFrom-Json
  if (Test-Path $target) {
    try { $data = Get-Content $target -Raw | ConvertFrom-Json } catch { $data = [pscustomobject]@{} }
  } else { $data = [pscustomobject]@{} }
  if (-not $data.PSObject.Properties['mcpServers']) {
    $data | Add-Member -NotePropertyName mcpServers -NotePropertyValue ([pscustomobject]@{})
  }
  $sauble = $fragment.mcpServers.sauble
  if ($data.mcpServers.PSObject.Properties['sauble']) { $data.mcpServers.sauble = $sauble }
  else { $data.mcpServers | Add-Member -NotePropertyName sauble -NotePropertyValue $sauble }
  Write-Text $target (($data | ConvertTo-Json -Depth 100) + "`n")
  Write-Host "  merged sauble server into $target (other servers untouched)"
}

# Remove the [mcp_servers.sauble] table (header through the line before the next
# table header, or EOF) from a TOML file, writing BOM-free. No-op if absent.
function Remove-SaubleToml($target) {
  if (-not (Test-Path $target)) { return }
  if (-not (Select-String -Path $target -Pattern '^\[mcp_servers\.sauble\]' -Quiet)) { return }
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
}

$Home_ = $env:USERPROFILE
switch ($Agent) {
  'codex' {
    $skillsDir = if ($Scope -eq 'global') { Join-Path $Home_ '.codex\skills' } else { Join-Path $ProjectDir '.agents\skills' }
    if (-not $McpOnly) { Install-Skills $skillsDir }
    if (-not $SkillsOnly) {
      $cfg = Join-Path $Home_ '.codex\config.toml'
      New-Item -ItemType Directory -Force -Path (Split-Path -Parent $cfg) | Out-Null
      Backup-File $cfg
      # Idempotent: drop any existing sauble block, then write the current one -
      # so a re-run with a changed -Url updates in place, like the other tools.
      Remove-SaubleToml $cfg
      $block = (Get-Content (Join-Path $Dist 'mcp\codex.toml') -Raw).TrimEnd()
      if ($Url) { $block = $block.Replace('https://YOUR-SAUBLE-INSTANCE/mcp', $Url) }
      $existing = if (Test-Path $cfg) { (Get-Content $cfg -Raw).TrimEnd() } else { '' }
      $sep = if ($existing) { "`n`n" } else { '' }
      Write-Text $cfg ($existing + $sep + $block + "`n")
      Write-Host "  wrote [mcp_servers.sauble] to $cfg (other servers untouched)"
      if (-not $Url) { Write-Host "  NOTE: set the url in $cfg to your Sauble MCP URL (placeholder left in)." }
    }
  }
  'cursor' {
    $skillsDir = Join-Path $ProjectDir '.agents\skills'
    if (-not $McpOnly) { Install-Skills $skillsDir }
    if (-not $SkillsOnly) {
      $cfg = if ($Scope -eq 'global') { Join-Path $Home_ '.cursor\mcp.json' } else { Join-Path $ProjectDir '.cursor\mcp.json' }
      Merge-Json $cfg (Join-Path $Dist 'mcp\cursor.json')
      Write-Host "  tip: one-click install also available - see dist\mcp\cursor-deeplink.txt"
    }
  }
  'windsurf' {
    $skillsDir = if ($Scope -eq 'global') { Join-Path $Home_ '.windsurf\skills' } else { Join-Path $ProjectDir '.windsurf\skills' }
    if (-not $McpOnly) { Install-Skills $skillsDir }
    if (-not $SkillsOnly) {
      $cfg = Join-Path $Home_ '.codeium\windsurf\mcp_config.json'
      Merge-Json $cfg (Join-Path $Dist 'mcp\windsurf.json')
    }
  }
}

$meta = Join-Path $Home_ '.agents\sauble-mcp-install.json'
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $meta) | Out-Null
Write-Text $meta (([pscustomobject]@{ version = $Version; agent = $Agent; scope = $Scope } | ConvertTo-Json))

Write-Host "Done. Sauble skill pack v$Version installed for $Agent."
Write-Host "Set SAUBLE_MCP_URL / SAUBLE_TOKEN / SAUBLE_ENVIRONMENT_ID in your environment before launching the agent."
