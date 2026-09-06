# Shadowgun / TrimUI port - English labels for the settings screens.
#
# Why this exists:
#   The bundled APK is the 4PDA Russian build. Its translation is complete, but
#   the font used by the options and gamepad-config screens has no Cyrillic
#   glyphs, so every translated label there draws as an empty box. Only ASCII
#   survives - that is why "Fire / Action" showed up as a lone "/".
#
# What it does:
#   Pulls the Texts.eng string table out of the OBB (Unity Resources asset
#   assets/bin/Data/<hash>), rewrites the settings/gamepad ids in English and
#   drops the result into assets/bin/Data/ on the card. A copy sitting there
#   takes precedence over the OBB, so the OBB itself is never modified.
#
#   The replacement text is padded back to the original byte count, so every
#   size field in the Unity serialized file stays valid and no offsets move.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File patch_texts_en.ps1 -PortDir G:\Data\ports\shadowgun
#
# To undo: delete assets/bin/Data/5fd3979c24c27cd4fae626319ef1d06e - the game
# falls back to the Russian table inside the OBB.

param(
    [Parameter(Mandatory = $true)]
    [string]$PortDir
)

$ErrorActionPreference = 'Stop'

$asset   = '5fd3979c24c27cd4fae626319ef1d06e'
$entry   = "assets/bin/Data/$asset"
$obbName = 'main.170300014.com.madfingergames.shadowgun.obb'
$obbPath = Join-Path $PortDir "Android/obb/com.madfingergames.shadowgun/$obbName"
$destDir = Join-Path $PortDir 'assets/bin/Data'
$dest    = Join-Path $destDir $asset

$map = @{
    '32000' = 'SETUP / CONTROLS'
    '33000' = 'CONTROL SCHEME'
    '34000' = 'FLOATING MOVEMENT STICK'
    '35000' = 'STATIC MOVEMENT STICK'
    '36000' = 'SENSITIVITY'
    '37000' = 'INVERT VERTICAL LOOK'
    '37001' = 'LEFT-HANDED AIM'
    '38000' = 'ON'
    '39000' = 'OFF'
    '40000' = 'NEXT'
    '41000' = 'BACK'
    '42000' = 'RESET TO DEFAULTS'
    '43000' = 'SETUP / SUBTITLES AND MUSIC'
    '44000' = 'MUSIC VOLUME'
    '45000' = 'IN-GAME SUBTITLES'
    '45100' = 'SETUP / XPERIA PLAY'
    '45101' = 'SHOW CONTROLS'
    '45102' = 'SLIDE PAD'
    '45103' = 'JOYSTICK'
    '53000' = 'CUSTOMISE SCHEME'
    '54000' = 'MOVEMENT CONTROL'
    '55000' = 'FIRE CONTROL'
    '56000' = 'RELOAD BUTTON'
    '56100' = 'GAMEPAD'
    '56101' = 'GAMEPAD CONFIGURATION'
    '56102' = 'Action'
    '56103' = 'Button'
    '56104' = 'Reset to defaults'
    '56105' = 'Save and exit'
    '56106' = 'New gamepad detected.\nOpen <SETUP / CONTROLS> and pick <GAMEPAD> to configure it.'
    '56110' = 'Fire / Action'
    '56111' = 'Reload'
    '56112' = 'Pause'
    '56113' = 'Previous weapon'
    '56114' = 'Next weapon'
    '56115' = 'Select'
    '56116' = 'Back'
    '56117' = 'Dodge roll'
    '56118' = 'Move right'
    '56119' = 'Move forward'
    '56120' = 'Look right'
    '56121' = 'Look up'
    '56200' = 'LANGUAGE'
    '56201' = 'RUSSIAN'
    '56202' = 'GERMAN'
    '56203' = 'FRENCH'
    '56204' = 'ITALIAN'
    '56205' = 'JAPANESE'
    '56206' = 'CHINESE'
    '56207' = 'KOREAN'
}

if (-not (Test-Path $obbPath)) { throw "OBB not found: $obbPath" }

Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead($obbPath)
try {
    $item = $zip.Entries | Where-Object { $_.FullName -eq $entry }
    if ($null -eq $item) { throw "OBB has no entry $entry" }
    $buffer = New-Object byte[] $item.Length
    $stream = $item.Open()
    try {
        $read = 0
        while ($read -lt $buffer.Length) {
            $got = $stream.Read($buffer, $read, $buffer.Length - $read)
            if ($got -le 0) { break }
            $read += $got
        }
        if ($read -ne $buffer.Length) { throw "short read: $read of $($buffer.Length)" }
    } finally { $stream.Dispose() }
} finally { $zip.Dispose() }

# TextAsset m_Script is a length-prefixed raw UTF-8 blob.
$probe     = [System.Text.Encoding]::ASCII.GetString($buffer)
$textStart = $probe.IndexOf('# This is comment')
if ($textStart -lt 4) { throw 'string table not found in asset' }
$textLen = [System.BitConverter]::ToInt32($buffer, $textStart - 4)
if ($textLen -le 0 -or ($textStart + $textLen) -gt $buffer.Length) {
    throw "bad length prefix: $textLen"
}

$text  = [System.Text.Encoding]::UTF8.GetString($buffer, $textStart, $textLen)
$eol   = if ($text.Contains("`r`n")) { "`r`n" } else { "`n" }
$lines = $text -split "`r`n|`n"

$done = 0
for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = [regex]::Match($lines[$i], '^(\d+)(\s+)(.*)$')
    if (-not $line.Success) { continue }
    $id = $line.Groups[1].Value
    if (-not $map.ContainsKey($id)) { continue }
    $lines[$i] = $id + $line.Groups[2].Value + $map[$id]
    $done++
}
if ($done -ne $map.Count) { throw "matched $done of $($map.Count) ids" }

$patched = [string]::Join($eol, $lines)
$deficit = $textLen - [System.Text.Encoding]::UTF8.GetByteCount($patched)
if ($deficit -lt ($eol.Length + 1)) { throw "no room to pad: $deficit" }

# Pad with a trailing comment line so the byte count is unchanged.
$patched += $eol + '#' + (' ' * ($deficit - $eol.Length - 1))
$patchedBytes = [System.Text.Encoding]::UTF8.GetBytes($patched)
if ($patchedBytes.Length -ne $textLen) {
    throw "padding failed: $($patchedBytes.Length) != $textLen"
}

[System.Array]::Copy($patchedBytes, 0, $buffer, $textStart, $textLen)

if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Force -Path $destDir | Out-Null }
[System.IO.File]::WriteAllBytes($dest, $buffer)

Write-Host "patched $done ids, wrote $dest ($($buffer.Length) bytes)"
