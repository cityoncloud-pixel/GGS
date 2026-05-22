param(
  [Parameter(Mandatory = $false)]
  [string]$TargetPath = (Get-Location).Path,

  [Parameter(Mandatory = $false)]
  [ValidateSet('auto', 'cursor', 'codex')]
  [string]$Runtime = 'auto',

  [Parameter(Mandatory = $false)]
  [switch]$Fast,

  [Parameter(Mandatory = $false)]
  [switch]$Print,

  [Parameter(Mandatory = $false)]
  [switch]$DryRun,

  [Parameter(Mandatory = $false)]
  [string]$AgentCmd = $null,

  [Parameter(Mandatory = $false)]
  [string]$Prompt = $null
)

$ErrorActionPreference = 'Stop'

function Resolve-GgsTargetPath([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) { throw "TargetPath not found: $Path" }
  try { return (Resolve-Path -LiteralPath $Path).Path } catch { return $Path }
}

function Get-GgsConfig {
  $cfgPath = Join-Path (Join-Path $env:USERPROFILE '.ggs') 'config.json'
  if (-not (Test-Path -LiteralPath $cfgPath)) { return $null }
  try { return (Get-Content -Raw -LiteralPath $cfgPath) | ConvertFrom-Json } catch { return $null }
}

function Resolve-CommandPath([string]$Name, [string]$Override, [string]$ConfigPath) {
  if ($Override) {
    if (Test-Path -LiteralPath $Override) { return $Override }
    $cmd = Get-Command $Override -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    throw "Command not found: $Override"
  }
  if ($ConfigPath) {
    if (Test-Path -LiteralPath $ConfigPath) { return $ConfigPath }
    $cmd = Get-Command $ConfigPath -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
  }
  $cmd = Get-Command $Name -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  return $null
}

function Find-CursorAgentCommand([string]$Override) {
  $cfg = Get-GgsConfig
  $fromCfg = $null
  if ($cfg -and $cfg.cursor_agent -and $cfg.cursor_agent.command) {
    $fromCfg = $cfg.cursor_agent.command
  }
  $exe = Resolve-CommandPath -Name 'agent' -Override $Override -ConfigPath $fromCfg
  if ($exe) { return $exe }
  foreach ($alias in @('cursor-agent')) {
    $cmd = Get-Command $alias -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
  }
  $localAgent = Join-Path $env:LOCALAPPDATA 'cursor-agent\agent.exe'
  if (Test-Path -LiteralPath $localAgent) { return $localAgent }
  return $null
}

function Find-CodexCommand([string]$Override) {
  $cfg = Get-GgsConfig
  $fromCfg = $null
  if ($cfg -and $cfg.codex -and $cfg.codex.command) {
    $fromCfg = $cfg.codex.command
  }
  return Resolve-CommandPath -Name 'codex' -Override $Override -ConfigPath $fromCfg
}

function Get-PreferredRuntime([string]$Requested) {
  if ($Requested -and $Requested -ne 'auto') { return $Requested.ToLowerInvariant() }
  $cfg = Get-GgsConfig
  if ($cfg -and $cfg.runtime -and $cfg.runtime.preferred) {
    $p = [string]$cfg.runtime.preferred
    if ($p -in @('cursor', 'codex')) { return $p }
  }
  return 'auto'
}

function Resolve-Runtime([string]$Requested, [string]$AgentCmdOverride) {
  $pref = Get-PreferredRuntime $Requested
  $cursor = Find-CursorAgentCommand $(if ($AgentCmdOverride -and $pref -in @('auto','cursor')) { $AgentCmdOverride } else { $null })
  $codex = Find-CodexCommand $(if ($AgentCmdOverride -and $pref -eq 'codex') { $AgentCmdOverride } else { $null })

  if ($pref -eq 'cursor') {
    if ($cursor) { return @{ name = 'cursor'; exe = $cursor } }
    throw 'GGS agent: runtime=cursor but Cursor Agent CLI (agent) not found. Install: https://cursor.com/docs/cli/using'
  }
  if ($pref -eq 'codex') {
    if ($codex) { return @{ name = 'codex'; exe = $codex } }
    throw 'GGS agent: runtime=codex but Codex CLI not found. Install: https://developers.openai.com/codex/cli'
  }

  # auto
  if ($AgentCmdOverride) {
    if ($cursor) { return @{ name = 'cursor'; exe = $cursor } }
    if ($codex) { return @{ name = 'codex'; exe = $codex } }
    throw "GGS agent: -AgentCmd not found: $AgentCmdOverride"
  }
  if ($cursor) { return @{ name = 'cursor'; exe = $cursor } }
  if ($codex) { return @{ name = 'codex'; exe = $codex } }

  return $null
}

function Build-GgsAgentPrompt([switch]$FastMode, [string]$Custom) {
  if ($Custom) { return $Custom }
  $p = '运行 GGS'
  if ($FastMode) { $p += '，fast mode，grill depth none' }
  return $p
}

function Get-InvokePlan($RuntimeInfo, [string]$TargetPath, [string]$Prompt, [switch]$PrintMode) {
  if ($RuntimeInfo.name -eq 'cursor') {
    if ($PrintMode) {
      return @{
        label = 'Cursor Agent CLI (non-interactive)'
        exe   = $RuntimeInfo.exe
        args  = @('--workspace', $TargetPath, '--trust', '-f', '-p', '--output-format', 'text', $Prompt)
      }
    }
    return @{
      label = 'Cursor Agent CLI'
      exe   = $RuntimeInfo.exe
      args  = @('--workspace', $TargetPath, '--trust', '-f', $Prompt)
    }
  }

  if ($PrintMode) {
    return @{
      label = 'Codex CLI (exec)'
      exe   = $RuntimeInfo.exe
      args  = @('exec', '--cd', $TargetPath, '--sandbox', 'workspace-write', $Prompt)
    }
  }
  return @{
    label = 'Codex CLI'
    exe   = $RuntimeInfo.exe
    args  = @('--cd', $TargetPath, '--ask-for-approval', 'on-failure', $Prompt)
  }
}

$TargetPath = Resolve-GgsTargetPath $TargetPath
$ggsRoot = Join-Path $TargetPath 'project_control\.ggs'
if (-not (Test-Path -LiteralPath $ggsRoot)) {
  throw "Missing project_control/.ggs — run: ggs init -TargetPath `"$TargetPath`""
}

$prompt = Build-GgsAgentPrompt -FastMode:$Fast -Custom $Prompt
$runtimeInfo = Resolve-Runtime -Requested $Runtime -AgentCmdOverride $AgentCmd

if (-not $runtimeInfo) {
  Write-Host 'GGS agent: FAIL - no supported Agent CLI found (auto).' -ForegroundColor Red
  Write-Host ''
  Write-Host 'Install one of:'
  Write-Host '  Cursor Agent CLI:  https://cursor.com/docs/cli/using   (command: agent)'
  Write-Host '  Codex CLI:         https://developers.openai.com/codex/cli (command: codex)'
  Write-Host ''
  Write-Host 'Or set ~/.ggs/config.json:'
  Write-Host '  { "runtime": { "preferred": "cursor" }, "cursor_agent": { "command": "agent" }, "codex": { "command": "codex" } }'
  Write-Host ''
  Write-Host 'IDE fallback:'
  Write-Host '  Cursor: say  运行 GGS  (needs .cursor/rules/ggs-runner.mdc)'
  Write-Host '  Codex:  say  运行 GGS  (needs AGENTS.md at project root)'
  Write-Host "  ggs run -TargetPath `"$TargetPath`""
  exit 1
}

$invokePlan = Get-InvokePlan -RuntimeInfo $runtimeInfo -TargetPath $TargetPath -Prompt $prompt -PrintMode:$Print
$displayArgs = @($invokePlan.exe) + $invokePlan.args

Write-Host "GGS agent: invoking $($invokePlan.label)"
Write-Host "  runtime:   $($runtimeInfo.name)"
Write-Host "  workspace: $TargetPath"
Write-Host "  prompt:    $prompt"
if ($Print) { Write-Host '  mode:      non-interactive / script' }
Write-Host "  command:   $($displayArgs -join ' ')"
Write-Host ''

if ($DryRun) {
  Write-Host 'GGS agent: DRY RUN (not executed)' -ForegroundColor Yellow
  exit 0
}

if ($Print) {
  Write-Host 'GGS agent: NOTE - non-interactive mode may not wait for Grill Q&A.' -ForegroundColor Yellow
  Write-Host '          Use without -Print when A-level clarification is needed.'
  Write-Host ''
}

& $invokePlan.exe @($invokePlan.args)
exit $LASTEXITCODE
