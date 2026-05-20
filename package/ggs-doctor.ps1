param(
  [Parameter(Mandatory = $false)]
  [string]$TargetPath = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'

function Fail($msg) {
  Write-Host "GGS doctor: FAIL - $msg" -ForegroundColor Red
  exit 2
}

function Ok($msg) {
  Write-Host "GGS doctor: OK   - $msg" -ForegroundColor Green
}

function Warn($msg) {
  Write-Host "GGS doctor: WARN - $msg" -ForegroundColor Yellow
}

if (-not (Test-Path -LiteralPath $TargetPath)) {
  Fail "TargetPath not found: $TargetPath"
}

$ggsRoot = Join-Path $TargetPath 'project_control\.ggs'
if (-not (Test-Path -LiteralPath $ggsRoot)) { Fail "Missing project_control/.ggs (run: ggs init)" }
Ok "GGS workspace present"

$required = @(
  'project_control\.ggs\goal_seed.md',
  'project_control\.ggs\goal.draft.md',
  'project_control\.ggs\assumptions.md',
  'project_control\.ggs\state.json',
  'project_control\.ggs\goal.review.json',
  'project_control\.ggs\templates\runner.prompt.md',
  'project_control\.ggs\templates\goal.schema.md'
)
foreach ($f in $required) {
  $p = Join-Path $TargetPath $f
  if (-not (Test-Path -LiteralPath $p)) { Fail "Missing file: $f" }
}
Ok "GGS core files present"

foreach ($jsonRel in @('project_control\.ggs\state.json', 'project_control\.ggs\goal.review.json')) {
  $p = Join-Path $TargetPath $jsonRel
  try {
    $null = (Get-Content -Raw -LiteralPath $p) | ConvertFrom-Json
    Ok "$jsonRel is valid JSON"
  } catch {
    Fail "$jsonRel invalid JSON: $($_.Exception.Message)"
  }
}

$goalPath = Join-Path $TargetPath 'project_control\goal.md'
if (Test-Path -LiteralPath $goalPath) {
  Ok "goal.md present (handoff target)"
} else {
  Warn "goal.md missing (run GGS runner to export)"
}

$statePath = Join-Path $TargetPath 'project_control\.ggs\state.json'
try {
  $state = (Get-Content -Raw -LiteralPath $statePath) | ConvertFrom-Json
  if ($state.status -eq 'EXPORTED') {
    Ok "state.json status is EXPORTED"
  } else {
    Warn "state.json status is $($state.status) (expected EXPORTED after GGS run)"
  }
} catch { }

Write-Host "GGS doctor: PASS" -ForegroundColor Green
