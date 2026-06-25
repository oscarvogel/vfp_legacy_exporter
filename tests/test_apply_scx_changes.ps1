$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$scriptPath = Join-Path $repoRoot "src\apply_scx_changes.prg"
$docPath = Join-Path $repoRoot "docs\APLICAR_CAMBIOS_SCX.md"
$sandboxScriptPath = Join-Path $repoRoot "scripts\prepare_fasa_sandbox.ps1"
$gitignorePath = Join-Path $repoRoot ".gitignore"
$versionedPaths = @(
    $scriptPath,
    $docPath,
    $sandboxScriptPath
)

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
Assert-FileExists $sandboxScriptPath
Assert-FileExists $gitignorePath

$script = Get-Content -LiteralPath $scriptPath -Raw
$doc = Get-Content -LiteralPath $docPath -Raw
$sandboxScript = Get-Content -LiteralPath $sandboxScriptPath -Raw
$gitignore = Get-Content -LiteralPath $gitignorePath -Raw

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
Assert-Contains $script "work\\fasa_sandbox\\forms\\INGRESO COMPROBANTES\.SCX" "structured sandbox VFP example"

Assert-Contains $doc "DO src\\apply_scx_changes\.prg WITH" "VFP execution example"
Assert-Contains $doc "work\\fasa_sandbox\\forms\\INGRESO COMPROBANTES\.SCX" "structured sandbox execution path"
Assert-Contains $doc "work\\fasa_sandbox\\libs" "structured libs directory"
Assert-Contains $doc "generales\.vcx" "required VCX dependency documented"
Assert-Contains $doc "validaciones\.vct" "required VCT dependency documented"
Assert-Contains $doc "X:\\FASA\\FORMS\\INGRESO COMPROBANTES\.SCX" "production path warning"
Assert-Contains $doc "MODIFY FORM" "manual sandbox validation"
Assert-Contains $doc "backup" "backup behavior"
Assert-Contains $doc "manual" "manual visual step"

Assert-Contains $sandboxScript "forms\\INGRESO COMPROBANTES\.SCX" "sandbox copies SCX into forms"
Assert-Contains $sandboxScript "libs\\generales\.vcx" "sandbox copies required class library"
Assert-Contains $sandboxScript "include\\def\.h" "sandbox copies required include"
Assert-Contains $sandboxScript "work\\fasa_sandbox" "default sandbox root"
Assert-Contains $sandboxScript "Copy-RequiredFile" "sandbox helper copies explicit dependency list"
Assert-Contains $gitignore "(?m)^work/$" "local sandbox directory ignored"

foreach ($path in $versionedPaths) {
    $content = Get-Content -LiteralPath $path -Raw
    if ($content -match "work\\fasa_ingreso_comprobantes_precarga\\INGRESO COMPROBANTES\.SCX") {
        throw "Old flat sandbox path remains in $path"
    }
}

Write-Host "apply_scx_changes static contract OK"
