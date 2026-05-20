param(
  [Parameter(Mandatory = $false)]
  [string]$OutDir = '',
  [Parameter(Mandatory = $false)]
  [switch]$Clean
)

$ErrorActionPreference = 'Stop'

$root = $PSScriptRoot
if (-not $OutDir) { $OutDir = Join-Path $root 'dist' }
if (-not (Test-Path -LiteralPath $OutDir)) { New-Item -ItemType Directory -Force -Path $OutDir | Out-Null }

$metaPath = Join-Path $root 'package\ggs-kit.json'
$meta = (Get-Content -Raw -LiteralPath $metaPath) | ConvertFrom-Json
$version = $meta.version
$zipPath = Join-Path $OutDir "ggs-kit-v$version.zip"

if ($Clean -and (Test-Path -LiteralPath $zipPath)) { Remove-Item -Force -LiteralPath $zipPath }
if (Test-Path -LiteralPath $zipPath) {
  Write-Host "Already built: $zipPath"
  exit 0
}

Write-Host "Building: $zipPath"
Compress-Archive -Path (Join-Path $root 'package\*') -DestinationPath $zipPath -CompressionLevel Optimal
Write-Host "Done."
