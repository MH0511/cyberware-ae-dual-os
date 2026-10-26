param([string]$OutputDirectory = (Join-Path $PSScriptRoot 'dist'))
$ErrorActionPreference = 'Stop'
$archiveName = 'Cyberware-AE-Dual-OS-0.1.0.zip'
$sources = [ordered]@{
    'bin/x64/plugins/cyber_engine_tweaks/mods/ae_dual_os/init.lua' = 'package/bin/x64/plugins/cyber_engine_tweaks/mods/ae_dual_os/init.lua'
    'r6/scripts/AEDualOS/AEDualOS.reds' = 'package/r6/scripts/AEDualOS/AEDualOS.reds'
    'r6/scripts/AEDualOS/HUD.reds' = 'package/r6/scripts/AEDualOS/HUD.reds'
    'LICENSE' = 'LICENSE'
    'README.md' = 'README.md'
    'README.zh-CN.md' = 'README.zh-CN.md'
    'CHANGELOG.md' = 'CHANGELOG.md'
    'docs/images/dual-os-hud.png' = 'docs/images/dual-os-hud.png'
    'docs/images/quickhack-menu.png' = 'docs/images/quickhack-menu.png'
}
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$archivePath = Join-Path $OutputDirectory $archiveName
if (Test-Path -LiteralPath $archivePath) { throw 'Archive already exists. Choose a fresh output directory.' }
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [IO.Compression.ZipFile]::Open($archivePath, [IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($destination in $sources.Keys) {
        $source = Join-Path $PSScriptRoot $sources[$destination]
        [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $source, $destination) | Out-Null
    }
} finally { $archive.Dispose() }
$archive = [IO.Compression.ZipFile]::OpenRead($archivePath)
try {
    if ($archive.Entries.Count -ne $sources.Count) { throw 'Unexpected archive entries' }
    foreach ($entry in $archive.Entries) {
        if (!$sources.Contains($entry.FullName)) { throw "Unexpected entry: $($entry.FullName)" }
        $stream = $entry.Open()
        $sha = [Security.Cryptography.SHA256]::Create()
        try { $actual = [BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-', '') }
        finally { $stream.Dispose(); $sha.Dispose() }
        $expected = (Get-FileHash -LiteralPath (Join-Path $PSScriptRoot $sources[$entry.FullName]) -Algorithm SHA256).Hash
        if ($actual -ne $expected) { throw "Archive hash mismatch: $($entry.FullName)" }
    }
} finally { $archive.Dispose() }
$digest = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash.ToLowerInvariant()
[IO.File]::WriteAllText((Join-Path $OutputDirectory 'SHA256SUMS.txt'), "$digest  $archiveName`n", [Text.UTF8Encoding]::new($false))
Write-Output "Built and verified $archivePath ($($sources.Count) files)."
