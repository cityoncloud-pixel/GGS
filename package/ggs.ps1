param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$Args
)

$ErrorActionPreference = 'Stop'

function Get-KitRoot { return $PSScriptRoot }

function Get-UserHome {
  if ($env:USERPROFILE) { return $env:USERPROFILE }
  if ($HOME) { return $HOME }
  throw "Cannot resolve user home folder."
}

function Get-GgsHome { Join-Path (Get-UserHome) '.ggs' }

function Ensure-Dir([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) {
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
  }
}

function Read-Json([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) { return $null }
  (Get-Content -Raw -LiteralPath $Path) | ConvertFrom-Json
}

function Write-Json([string]$Path, $Obj) {
  $dir = Split-Path -Parent $Path
  Ensure-Dir $dir
  ($Obj | ConvertTo-Json -Depth 50) | Set-Content -LiteralPath $Path -Encoding UTF8
}

function Print-Help {
  @"
GGS CLI (Goal Generation System)

Usage:
  .\ggs.ps1 install
  .\ggs.ps1 init     [-TargetPath <path>] [-Force]
  .\ggs.ps1 run      [-TargetPath <path>]
  .\ggs.ps1 agent    [-TargetPath <path>] [-Runtime auto|cursor|codex] [-Fast] [-Print] [-DryRun] [-AgentCmd <exe>]
  .\ggs.ps1 doctor   [-TargetPath <path>]
  .\ggs.ps1 export   [-TargetPath <path>]

Handoff to GAEH: project_control/goal.md (see docs/GGS_GAEH_Handoff.md)
"@ | Write-Host
}

function Cmd-Install {
  $kitRoot = Get-KitRoot
  $ggsHome = Get-GgsHome

  Ensure-Dir $ggsHome
  Ensure-Dir (Join-Path $ggsHome 'bin')
  Ensure-Dir (Join-Path $ggsHome 'kits')

  $metaPath = Join-Path $kitRoot 'ggs-kit.json'
  $meta = Read-Json $metaPath
  if (-not $meta) { throw "Missing kit metadata: $metaPath" }
  $version = $meta.version
  if (-not $version) { throw "Missing version in ggs-kit.json" }

  $dstKit = Join-Path (Join-Path $ggsHome 'kits') $version
  $srcResolved = $null
  $dstResolved = $null
  try { $srcResolved = (Resolve-Path -LiteralPath $kitRoot).Path } catch { }
  try { $dstResolved = (Resolve-Path -LiteralPath $dstKit).Path } catch { }

  $samePath = $false
  if ($srcResolved -and $dstResolved -and ($srcResolved.TrimEnd('\') -ieq $dstResolved.TrimEnd('\'))) {
    $samePath = $true
  }

  if (-not $samePath) {
    if (Test-Path -LiteralPath $dstKit) { Remove-Item -Recurse -Force -LiteralPath $dstKit }
    Ensure-Dir $dstKit
    $srcGgs = Join-Path $kitRoot 'ggs.ps1'
    if (-not (Test-Path -LiteralPath $srcGgs)) { throw "Invalid kit root: $kitRoot" }
    Copy-Item -Recurse -Force -Path (Join-Path $kitRoot '*') -Destination $dstKit
  }

  Set-Content -LiteralPath (Join-Path $ggsHome 'current.txt') -Value $dstKit -Encoding UTF8

  $cfgPath = Join-Path $ggsHome 'config.json'
  if (-not (Test-Path -LiteralPath $cfgPath)) {
    Write-Json -Path $cfgPath -Obj @{
      schema_version = '1.0'
      projects_root = (Join-Path (Get-UserHome) 'ggs-projects')
      runtime = @{ preferred = 'auto' }
      cursor_agent = @{ command = 'agent' }
      codex = @{ command = 'codex' }
    }
  }

  $shim = @'
param([Parameter(ValueFromRemainingArguments=$true)][string[]]$Args)
$ErrorActionPreference = "Stop"
$userHome = if ($env:USERPROFILE) { $env:USERPROFILE } elseif ($HOME) { $HOME } else { throw "Cannot resolve user home." }
$ggsHome = Join-Path $userHome ".ggs"
$current = Join-Path $ggsHome "current.txt"
if (-not (Test-Path -LiteralPath $current)) { throw "GGS not installed. Run: ggs.ps1 install" }
$kit = (Get-Content -Raw -LiteralPath $current).Trim()
. (Join-Path $kit "ggs.ps1") @Args
'@
  $shimPath = Join-Path (Join-Path $ggsHome 'bin') 'ggs.ps1'
  Set-Content -LiteralPath $shimPath -Value $shim -Encoding UTF8

  $cmdShim = @'
@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%USERPROFILE%\.ggs\bin\ggs.ps1" %*
'@
  Set-Content -LiteralPath (Join-Path (Join-Path $ggsHome 'bin') 'ggs.cmd') -Value $cmdShim -Encoding ASCII

  Write-Host "GGS installed to: $dstKit"
  Write-Host "Shim: $shimPath"
  Write-Host ('Add to PATH: $env:PATH = "{0};$env:PATH"' -f (Join-Path $ggsHome 'bin'))
}

function Cmd-Init {
  param([string]$TargetPath = (Get-Location).Path, [switch]$Force)
  $bootstrap = Join-Path (Get-KitRoot) 'ggs-bootstrap.ps1'
  if (-not (Test-Path -LiteralPath $bootstrap)) { throw "Missing bootstrap: $bootstrap" }
  $cmd = @('-ExecutionPolicy', 'Bypass', '-File', $bootstrap, '-TargetPath', $TargetPath)
  if ($Force) { $cmd += '-Force' }
  & powershell @cmd
}

function Cmd-Run {
  param([string]$TargetPath = (Get-Location).Path)
  $goalSeed = Join-Path $TargetPath 'project_control\.ggs\goal_seed.md'
  $runner = Join-Path $TargetPath 'project_control\.ggs\templates\runner.prompt.md'
  $cursorRule = Join-Path $TargetPath '.cursor\rules\ggs-runner.mdc'
  $agentsMd = Join-Path $TargetPath 'AGENTS.md'
  Write-Host "GGS (Goal Generation) — IDE or CLI (no paste required after ggs init):"
  Write-Host ""
  Write-Host "  1) Edit: $goalSeed"
  Write-Host "  2) IDE:  Cursor or Codex chat ->  运行 GGS"
  Write-Host "     Runner: $runner"
  if (Test-Path -LiteralPath $cursorRule) {
    Write-Host "     Cursor: $cursorRule"
  } else {
    Write-Host "     WARN: missing Cursor rule — ggs init -Force"
  }
  if (Test-Path -LiteralPath $agentsMd) {
    Write-Host "     Codex:  $agentsMd"
  } else {
    Write-Host "     WARN: missing AGENTS.md — ggs init -Force"
  }
  Write-Host "  3) CLI:  ggs agent -TargetPath `"$TargetPath`" -Runtime auto"
  Write-Host ""
  Write-Host "  See: commandlist.md (in GGS kit / repo root)"
  Write-Host ""
  Write-Host "Expected outputs:"
  Write-Host "  - project_control\.ggs\grill.md (after Grill Gate)"
  Write-Host "  - project_control\goal.md"
  Write-Host "  - project_control\.ggs\goal.review.json"
  Write-Host "  - state.json status=EXPORTED, goal.review.json verdict=PASS"
  Write-Host ""
  Write-Host "Then: ggs export -TargetPath `"$TargetPath`""
  Write-Host "Then hand off to GAEH: gaeh doctor / gaeh start on same project path."
}

function Cmd-Agent {
  param(
    [string]$TargetPath = (Get-Location).Path,
    [string]$Runtime = 'auto',
    [switch]$Fast,
    [switch]$Print,
    [switch]$DryRun,
    [string]$AgentCmd = $null,
    [string]$Prompt = $null
  )
  $agentScript = Join-Path (Get-KitRoot) 'ggs-agent.ps1'
  if (-not (Test-Path -LiteralPath $agentScript)) { throw "Missing ggs-agent.ps1: $agentScript" }
  $cmd = @('-ExecutionPolicy', 'Bypass', '-File', $agentScript, '-TargetPath', $TargetPath, '-Runtime', $Runtime)
  if ($Fast) { $cmd += '-Fast' }
  if ($Print) { $cmd += '-Print' }
  if ($DryRun) { $cmd += '-DryRun' }
  if ($AgentCmd) { $cmd += @('-AgentCmd', $AgentCmd) }
  if ($Prompt) { $cmd += @('-Prompt', $Prompt) }
  & powershell @cmd
  exit $LASTEXITCODE
}

function Cmd-Doctor {
  param([string]$TargetPath = (Get-Location).Path)
  $doctor = Join-Path (Get-KitRoot) 'ggs-doctor.ps1'
  & powershell -ExecutionPolicy Bypass -File $doctor -TargetPath $TargetPath
}

function Cmd-Export {
  param([string]$TargetPath = (Get-Location).Path)
  $statePath = Join-Path $TargetPath 'project_control\.ggs\state.json'
  $reviewPath = Join-Path $TargetPath 'project_control\.ggs\goal.review.json'
  $goalPath = Join-Path $TargetPath 'project_control\goal.md'

  if (-not (Test-Path -LiteralPath $statePath)) { throw "Missing state.json (run: ggs init)" }
  if (-not (Test-Path -LiteralPath $reviewPath)) { throw "Missing goal.review.json" }
  if (-not (Test-Path -LiteralPath $goalPath)) { throw "Missing goal.md" }

  $state = Read-Json $statePath
  $review = Read-Json $reviewPath
  $ok = $true

  if ($state.status -ne 'EXPORTED') {
    Write-Host "GGS export: FAIL - state.status is $($state.status), expected EXPORTED" -ForegroundColor Red
    $ok = $false
  } else {
    Write-Host "GGS export: OK   - state.status EXPORTED" -ForegroundColor Green
  }

  if ($review.verdict -ne 'PASS') {
    Write-Host "GGS export: FAIL - review.verdict is $($review.verdict), expected PASS" -ForegroundColor Red
    $ok = $false
  } else {
    Write-Host "GGS export: OK   - review.verdict PASS" -ForegroundColor Green
  }

  if (-not (Test-Path -LiteralPath $goalPath)) {
    Write-Host "GGS export: FAIL - goal.md missing" -ForegroundColor Red
    $ok = $false
  } else {
    Write-Host "GGS export: OK   - goal.md present" -ForegroundColor Green
  }

  if (-not $ok) {
    Write-Host "GGS export: NOT READY for GAEH handoff" -ForegroundColor Red
    exit 2
  }

  Write-Host "GGS export: READY for GAEH (see docs/GGS_GAEH_Handoff.md)" -ForegroundColor Green
}

# --- dispatch ---
if (-not $Args -or $Args.Count -eq 0) {
  Print-Help
  exit 0
}

$cmd = $Args[0].ToLowerInvariant()
$rest = @()
if ($Args.Count -gt 1) { $rest = $Args[1..($Args.Count - 1)] }

function Get-ArgValue {
  param([string]$Name, [string[]]$Tokens)
  for ($i = 0; $i -lt $Tokens.Count; $i++) {
    if ($Tokens[$i] -eq $Name -and ($i + 1) -lt $Tokens.Count) {
      return $Tokens[$i + 1]
    }
    if ($Tokens[$i] -like "$Name=*") {
      return $Tokens[$i].Substring($Name.Length + 1)
    }
  }
  return $null
}

$tp = Get-ArgValue '-TargetPath' $rest
if (-not $tp) { $tp = (Get-Location).Path }

switch ($cmd) {
  'install' { Cmd-Install }
  'init' {
    $force = ($rest -contains '-Force')
    Cmd-Init -TargetPath $tp -Force:([bool]$force)
  }
  'run' { Cmd-Run -TargetPath $tp }
  'agent' {
    $fast = ($rest -contains '-Fast')
    $print = ($rest -contains '-Print')
    $dry = ($rest -contains '-DryRun')
    $agentCmd = Get-ArgValue '-AgentCmd' $rest
    $prompt = Get-ArgValue '-Prompt' $rest
    $rt = Get-ArgValue '-Runtime' $rest
    if (-not $rt) { $rt = 'auto' }
    Cmd-Agent -TargetPath $tp -Runtime $rt -Fast:([bool]$fast) -Print:([bool]$print) -DryRun:([bool]$dry) -AgentCmd $agentCmd -Prompt $prompt
  }
  'doctor' { Cmd-Doctor -TargetPath $tp }
  'export' { Cmd-Export -TargetPath $tp }
  'help' { Print-Help }
  default {
    Write-Host "Unknown command: $cmd"
    Print-Help
    exit 1
  }
}
