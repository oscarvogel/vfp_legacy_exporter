$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$scriptPath = Join-Path $repoRoot "src\export_legacy.prg"

if (-not (Test-Path $scriptPath)) {
    throw "Missing export_legacy.prg at $scriptPath"
}

$content = Get-Content -LiteralPath $scriptPath -Raw
$lines = Get-Content -LiteralPath $scriptPath

function Get-CatchBlocks {
    param(
        [string[]]$Lines
    )

    $blocks = @()
    $insideCatch = $false
    $startLine = 0
    $blockLines = @()

    for ($i = 0; $i -lt $Lines.Count; $i++) {
        $lineNumber = $i + 1
        $line = $Lines[$i]

        if ($line -match '^\s*CATCH\b') {
            $insideCatch = $true
            $startLine = $lineNumber
            $blockLines = @()
            continue
        }

        if ($insideCatch -and $line -match '^\s*ENDTRY\b') {
            $blocks += [pscustomobject]@{
                StartLine = $startLine
                EndLine = $lineNumber
                Text = ($blockLines -join "`n")
            }
            $insideCatch = $false
            $startLine = 0
            $blockLines = @()
            continue
        }

        if ($insideCatch) {
            $blockLines += $line
        }
    }

    if ($insideCatch) {
        throw "Unclosed CATCH block starting at line $startLine"
    }

    return $blocks
}

$catchBlocks = Get-CatchBlocks -Lines $lines

if ($catchBlocks.Count -lt 1) {
    throw "Expected at least one CATCH block in export_legacy.prg"
}

$invalidCatchBlocks = $catchBlocks | Where-Object {
    $_.Text -match '(?im)^\s*(RETURN|RETRY)\b'
}

if ($invalidCatchBlocks) {
    $locations = ($invalidCatchBlocks | ForEach-Object { "CATCH line $($_.StartLine)-$($_.EndLine)" }) -join ", "
    throw "RETURN/RETRY found inside CATCH block(s): $locations"
}

if ($content -match 'TTOC\s*\(\s*DATETIME\s*\(\s*\)\s*,\s*1\s*\)') {
    throw "Log timestamp must not use TTOC(DATETIME(), 1)"
}

if ($content -notmatch 'DTOC\s*\(\s*DATE\s*\(\s*\)\s*\)\s*\+\s*"\s*"\s*\+\s*TIME\s*\(\s*\)') {
    throw "Expected LogError timestamp to use DTOC(DATE()) + `" `" + TIME()"
}

if ($content -notmatch 'llOpened\s*=\s*\.F\.') {
    throw "Expected ExportDbfBasedFile to use llOpened failure flag"
}

if ($content -notmatch 'llRead\s*=\s*\.F\.') {
    throw "Expected ExportTextFile to use llRead failure flag"
}

Write-Host "export_legacy compatibility checks passed."
