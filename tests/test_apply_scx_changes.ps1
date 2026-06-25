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
Assert-Contains $script "AppendPropertyIfMissing" "duplicate-safe properties helper"
Assert-Contains $script "AppendReserved3TokenIfMissing" "duplicate-safe reserved3 helper"
Assert-Contains $script "ReplaceMemoBlock" "safe click replacement helper"
Assert-Contains $script "FindScxRecord" "record lookup helper"
Assert-Contains $script "INGRESO COMPROBANTES" "case-specific preparation"
Assert-Contains $script "X:\\FASA\\FORMS\\INGRESO COMPROBANTES\.SCX" "explicit production-path refusal"
Assert-Contains $script "manual" "manual visual step is explicit"
Assert-Contains $script "work\\fasa_sandbox\\forms\\INGRESO COMPROBANTES\.SCX" "structured sandbox VFP example"
Assert-Contains $script "nIdPrecarga\s*=\s*0" "nIdPrecarga property"
Assert-Contains $script "lDesdePrecarga\s*=\s*\.F\." "lDesdePrecarga property"
Assert-Contains $script "\*grabaprecarga" "reserved3 protected method token"
Assert-Contains $script "PROCEDURE\s+SafeC" "SafeC method"
Assert-Contains $script "PROCEDURE\s+SafeSQLC" "SafeSQLC method"
Assert-Contains $script "PROCEDURE\s+SafeN" "SafeN method"
Assert-Contains $script "PROCEDURE\s+GrabaPrecarga" "GrabaPrecarga method"
Assert-Contains $script "PROCEDURE\s+BuscaPrecargaProveedor" "BuscaPrecargaProveedor method"
Assert-Contains $script "PROCEDURE\s+CargaPrecarga" "CargaPrecarga method"
Assert-Contains $script "PROCEDURE\s+MarcaPrecargaCargada" "MarcaPrecargaCargada method"
Assert-Contains $script "FindScxRecord[\s\S]*`"Aceptar1`"" "Aceptar1 lookup by objname"
Assert-Contains $script "FindScxRecord[\s\S]*Formset\.frmIngreso\.Ajustador1" "Aceptar1 lookup by parent"
Assert-Contains $script "FindScxRecord[\s\S]*commandbutton" "Aceptar1 lookup by baseclass"
Assert-Contains $script "INGRESO COMPROBANTES_codex_methods_added\.prg" "methods sidecar"
Assert-Contains $script "INGRESO COMPROBANTES_codex_aceptar1_click\.prg" "Aceptar1 click sidecar"
Assert-Contains $script "INGRESO COMPROBANTES_codex_btnBuscaPrecarga_click\.prg" "btnBuscaPrecarga click sidecar"
Assert-Contains $script "btnBuscaPrecarga" "manual button definition"
Assert-Contains $script "propiedades agregadas" "summary includes properties"
Assert-Contains $script "reserved3 actualizado" "summary includes reserved3"
Assert-Contains $script "metodos agregados" "summary includes methods"
Assert-Contains $script "Aceptar1\.Click" "summary includes Aceptar1 status"

Assert-Contains $doc "DO src\\apply_scx_changes\.prg WITH" "VFP execution example"
Assert-Contains $doc "work\\fasa_sandbox\\forms\\INGRESO COMPROBANTES\.SCX" "structured sandbox execution path"
Assert-Contains $doc "work\\fasa_sandbox\\libs" "structured libs directory"
Assert-Contains $doc "generales\.vcx" "required VCX dependency documented"
Assert-Contains $doc "validaciones\.vct" "required VCT dependency documented"
Assert-Contains $doc "X:\\FASA\\FORMS\\INGRESO COMPROBANTES\.SCX" "production path warning"
Assert-Contains $doc "MODIFY FORM" "manual sandbox validation"
Assert-Contains $doc "backup" "backup behavior"
Assert-Contains $doc "manual" "manual visual step"
Assert-Contains $doc "nIdPrecarga" "new property documented"
Assert-Contains $doc "GrabaPrecarga" "new method documented"
Assert-Contains $doc "Aceptar1\.Click" "Aceptar1 behavior documented"
Assert-Contains $doc "INGRESO COMPROBANTES_codex_methods_added\.prg" "methods sidecar documented"
Assert-Contains $doc "INGRESO COMPROBANTES_codex_btnBuscaPrecarga_click\.prg" "button click sidecar documented"

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
