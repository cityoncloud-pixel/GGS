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
Write-Host "Next: edit project_control\.ggs\goal_seed.md, then run: ggs run -TargetPath `"$TargetPath`""
