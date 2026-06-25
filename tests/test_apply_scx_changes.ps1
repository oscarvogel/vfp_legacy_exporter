$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$scriptPath = Join-Path $repoRoot "src\apply_scx_changes.prg"
$docPath = Join-Path $repoRoot "docs\APLICAR_CAMBIOS_SCX.md"

function Assert-FileExists {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Expected file to exist: $Path"
    }
}

function Assert-Contains {
    param(
        [string]$Text,
        [string]$Pattern,
        [string]$Label
    )

    if ($Text -notmatch $Pattern) {
        throw "Missing expected content: $Label"
    }
}

Assert-FileExists $scriptPath
Assert-FileExists $docPath

$script = Get-Content -LiteralPath $scriptPath -Raw
$doc = Get-Content -LiteralPath $docPath -Raw

Assert-Contains $script "LPARAMETERS\s+tcScxFile" "VFP entry point receives SCX path"
Assert-Contains $script "JUSTEXT\(tcScxFile\)" "SCX extension validation"
Assert-Contains $script "JUSTSTEM\(tcScxFile\)\s*\+\s*['""]\.SCT['""]" "SCT pair validation"
Assert-Contains $script "BackupScxPair" "backup helper"
Assert-Contains $script "COPY FILE" "file backup copy"
Assert-Contains $script "USE\s+\(tcScxFile\).*SHARED" "SCX opened as table, not raw text"
Assert-Contains $script "AppendMemoBlockIfMissing" "duplicate-safe memo helper"
Assert-Contains $script "FindScxRecord" "record lookup helper"
Assert-Contains $script "INGRESO COMPROBANTES" "case-specific preparation"
Assert-Contains $script "X:\\FASA\\FORMS\\INGRESO COMPROBANTES\.SCX" "explicit production-path refusal"
Assert-Contains $script "manual" "manual visual step is explicit"

Assert-Contains $doc "DO src\\apply_scx_changes\.prg WITH" "VFP execution example"
Assert-Contains $doc "X:\\FASA\\FORMS\\INGRESO COMPROBANTES\.SCX" "production path warning"
Assert-Contains $doc "MODIFY FORM" "manual sandbox validation"
Assert-Contains $doc "backup" "backup behavior"
Assert-Contains $doc "manual" "manual visual step"

Write-Host "apply_scx_changes static contract OK"
