param(
 [Parameter(Mandatory)][ValidatePattern('^v[0-9][0-9A-Za-z._-]*$')][string]$Tag,
 [string]$ArchiveName = 'launcher-update.zip',
 [string]$Destination = "$env:LOCALAPPDATA\Reactivate\UpdateStaging"
)
$ErrorActionPreference='Stop'
if ($ArchiveName -notmatch '^[A-Za-z0-9._-]+\.zip$') {throw 'Unsafe archive name'}
$base="https://github.com/Ehynia/Reactivate_TFOL/releases/download/$Tag/$ArchiveName"
New-Item -ItemType Directory -Force -Path $Destination | Out-Null
$target=Join-Path $Destination $ArchiveName
$sum=Join-Path $Destination "$ArchiveName.sha256"
Invoke-WebRequest -UseBasicParsing -Uri $base -OutFile $target -TimeoutSec 180
Invoke-WebRequest -UseBasicParsing -Uri "$base.sha256" -OutFile $sum -TimeoutSec 30
$expected=(Get-Content -Raw $sum).Trim().Split(' ')[0].ToLowerInvariant()
if ($expected -notmatch '^[0-9a-f]{64}$') {throw 'Invalid SHA-256 file'}
$actual=(Get-FileHash -Algorithm SHA256 $target).Hash.ToLowerInvariant()
if ($actual -ne $expected) {Remove-Item $target -Force;throw 'SHA-256 mismatch'}
# Hold verified archive in staging. Do not auto-extract or execute untrusted ZIP content.
Write-Host "Verified staged update: $target"
Write-Host 'Close Reactivate and review update contents before replacing launcher files. Game files are never replaced.'
