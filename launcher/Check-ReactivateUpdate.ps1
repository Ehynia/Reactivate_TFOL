param([string]$Repository = "Ehynia/Reactivate_TFOL")
$ErrorActionPreference = 'Stop'
if ($Repository -ne "Ehynia/Reactivate_TFOL") { throw "Unexpected repository" }
$uri = "https://api.github.com/repos/$Repository/releases/latest"
$release = Invoke-RestMethod -Uri $uri -Headers @{ 'User-Agent' = 'Reactivate-TFOL-Updater'; 'Accept'='application/vnd.github+json' } -TimeoutSec 25
if (-not $release.tag_name -or $release.draft -or $release.prerelease) { throw 'No stable release published' }
[pscustomobject]@{ Tag=$release.tag_name; Name=$release.name; Url=$release.html_url; Published=$release.published_at } | Format-List
