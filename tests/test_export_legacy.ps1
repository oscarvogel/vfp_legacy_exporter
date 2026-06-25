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

function Get-ProcedureText {
    param(
        [string]$Content,
        [string]$Name
    )

    $pattern = "(?is)PROCEDURE\s+$Name\b(?<Body>.*?)(?=\r?\n(?:PROCEDURE|FUNCTION)\s+|\z)"
    $match = [regex]::Match($Content, $pattern)

    if (-not $match.Success) {
        throw "Missing procedure $Name"
    }

    return $match.Value
}

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

$dbfExport = Get-ProcedureText -Content $content -Name "ExportDbfBasedFile"
$fieldExport = Get-ProcedureText -Content $content -Name "ExportCurrentRecordFields"
$omitFunction = [regex]::Match($content, '(?is)FUNCTION\s+FieldShouldOmitContent\b.*?(?=\r?\n(?:PROCEDURE|FUNCTION)\s+|\z)').Value

if ($dbfExport -notmatch 'STRTOFILE\s*\(.+lcJsonFile\s*,\s*1\s*\)') {
    throw "Expected ExportDbfBasedFile to append JSON output incrementally"
}

if ($dbfExport -notmatch 'STRTOFILE\s*\(.+lcMdFile\s*,\s*1\s*\)') {
    throw "Expected ExportDbfBasedFile to append Markdown output incrementally"
}

if ($dbfExport -notmatch 'STRTOFILE\s*\(.+lcTxtFile\s*,\s*1\s*\)') {
    throw "Expected ExportDbfBasedFile to append TXT output incrementally"
}

if ($dbfExport -match '(?m)^\s*lc(Json|Md|Txt)\s*=\s*lc\1\s*\+') {
    throw "ExportDbfBasedFile must not append whole output into lcJson/lcMd/lcTxt accumulators"
}

if ($fieldExport -notmatch 'LPARAMETERS\s+tcAlias\s*,\s*taFields\s*,\s*tnFields\s*,\s*tcJsonFile\s*,\s*tcMdFile\s*,\s*tcTxtFile') {
    throw "Expected ExportCurrentRecordFields to receive output file paths"
}

if ($fieldExport -notmatch 'STRTOFILE\s*\(.+tcJsonFile\s*,\s*1\s*\)') {
    throw "Expected ExportCurrentRecordFields to append JSON fields incrementally"
}

if ($fieldExport -notmatch 'STRTOFILE\s*\(.+tcMdFile\s*,\s*1\s*\)') {
    throw "Expected ExportCurrentRecordFields to append Markdown fields incrementally"
}

if ($fieldExport -notmatch 'STRTOFILE\s*\(.+tcTxtFile\s*,\s*1\s*\)') {
    throw "Expected ExportCurrentRecordFields to append TXT fields incrementally"
}

if ($content -notmatch 'FUNCTION\s+MaxFieldExportChars\b') {
    throw "Expected MaxFieldExportChars to cap very large memo exports"
}

if ($content -notmatch 'FUNCTION\s+LimitFieldText\b') {
    throw "Expected LimitFieldText to truncate oversized field text before JSON/MD/TXT output"
}

if ($fieldExport -notmatch 'LimitFieldText\s*\(') {
    throw "Expected ExportCurrentRecordFields to apply LimitFieldText before writing fields"
}

if ($omitFunction -match '(?i)"methods"|"properties"') {
    throw "FieldShouldOmitContent must not omit methods or properties"
}

Write-Host "export_legacy compatibility checks passed."
