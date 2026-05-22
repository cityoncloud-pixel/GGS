param(
  [Parameter(Mandatory = $false)]
  [string]$TargetPath = (Get-Location).Path,

  [Parameter(Mandatory = $false)]
  [switch]$Force
)

$ErrorActionPreference = 'Stop'

function Ensure-Dir {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) {
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
  }
}

function Copy-TemplateItem {
  param([string]$Src, [string]$Dst)
  $dstDir = Split-Path -Parent $Dst
  Ensure-Dir $dstDir
  Copy-Item -LiteralPath $Src -Destination $Dst -Force
}

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$templatesRoot = Join-Path $scriptRoot 'templates'

if (-not (Test-Path -LiteralPath $templatesRoot)) {
  throw "templates folder missing: $templatesRoot"
}

Ensure-Dir $TargetPath
Ensure-Dir (Join-Path $TargetPath 'project_control')

Write-Host "GGS bootstrap -> $TargetPath"

# .ggs workspace
$ggsSrc = Join-Path $templatesRoot 'project_control\.ggs'
$ggsFiles = Get-ChildItem -LiteralPath $ggsSrc -Recurse -File
foreach ($f in $ggsFiles) {
  $rel = $f.FullName.Substring($ggsSrc.Length).TrimStart('\','/')
  $dst = Join-Path (Join-Path $TargetPath 'project_control\.ggs') $rel
  if ((Test-Path -LiteralPath $dst) -and (-not $Force)) { continue }
  Copy-TemplateItem -Src $f.FullName -Dst $dst
}

# Cursor rules (so "运行 GGS" triggers runner without pasting prompt)
$cursorRulesSrc = Join-Path $templatesRoot '.cursor\rules'
if (Test-Path -LiteralPath $cursorRulesSrc) {
  $ruleFiles = Get-ChildItem -LiteralPath $cursorRulesSrc -File
  foreach ($f in $ruleFiles) {
    $dst = Join-Path (Join-Path $TargetPath '.cursor\rules') $f.Name
    if ((Test-Path -LiteralPath $dst) -and (-not $Force)) { continue }
    Copy-TemplateItem -Src $f.FullName -Dst $dst
  }
}

# Codex AGENTS.md (symmetric trigger for Codex)
$agentsSrc = Join-Path $templatesRoot 'AGENTS.md'
if (Test-Path -LiteralPath $agentsSrc) {
  $agentsDst = Join-Path $TargetPath 'AGENTS.md'
  if ((Test-Path -LiteralPath $agentsDst) -and (-not $Force)) {
    # skip
  } else {
    Copy-TemplateItem -Src $agentsSrc -Dst $agentsDst
  }
}

# Handoff shells (GAEH consumes goal.md; empty template until GGS export)
$handoffSrc = Join-Path $templatesRoot 'handoff'
foreach ($name in @('goal.md', 'goal.next.md')) {
  $src = Join-Path $handoffSrc $name
  if (-not (Test-Path -LiteralPath $src)) { continue }
  $dst = Join-Path (Join-Path $TargetPath 'project_control') $name
  if ((Test-Path -LiteralPath $dst) -and (-not $Force)) { continue }
  Copy-TemplateItem -Src $src -Dst $dst
}

$logPath = Join-Path $TargetPath 'ggs_install.log'
$log = @(
  "installed_at: $((Get-Date).ToString('s'))"
  "target: $TargetPath"
  "kit: ggs"
)
Set-Content -LiteralPath $logPath -Value ($log -join [Environment]::NewLine) -Encoding UTF8

Write-Host "Done."
Write-Host "Next: edit project_control\.ggs\goal_seed.md"
Write-Host "      IDE:  Cursor or Codex chat ->  运行 GGS"
Write-Host "      CLI:  ggs agent -TargetPath `"$TargetPath`" -Runtime auto"
Write-Host "      See:  commandlist.md"
