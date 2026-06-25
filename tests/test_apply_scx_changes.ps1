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

function Assert-NotContains {
    param(
        [string]$Text,
        [string]$Pattern,
        [string]$Label
    )

    if ($Text -match $Pattern) {
        throw "Unexpected unsafe content: $Label"
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
Assert-Contains $script "BackupScxPair" "optional backup helper"
Assert-Contains $script "llCreateBackup" "backup is explicit, not default"
Assert-Contains $script "COPY FILE" "optional file backup copy"
Assert-Contains $script "USE\s+\(tcScxFile\).*SHARED.*NOUPDATE" "SCX opened as read-only table, not raw text"
Assert-Contains $script "sidecar-only" "default sidecar-only mode"
Assert-Contains $script "GenerateIngresoComprobantesSidecars" "sidecar generator"
Assert-NotContains $script "AppendMemoBlockIfMissing" "memo mutation helper removed"
Assert-NotContains $script "AppendPropertyIfMissing" "properties mutation helper removed"
Assert-NotContains $script "AppendReserved3TokenIfMissing" "reserved3 mutation helper removed"
Assert-NotContains $script "ReplaceMemoBlock" "SCX field replacement helper removed"
Assert-NotContains $script "REPLACE\s+\(tcFieldName\)" "generic SCX field replacement removed"
Assert-NotContains $script "REPLACE\s+methods\s+WITH" "methods memo replacement removed"
Assert-NotContains $script "REPLACE\s+properties\s+WITH" "properties replacement removed"
Assert-NotContains $script "REPLACE\s+reserved3\s+WITH" "reserved3 replacement removed"
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
Assert-Contains $script 'FindScxRecord[\s\S]*"Aceptar1"' "Aceptar1 lookup by objname"
Assert-Contains $script "FindScxRecord[\s\S]*Formset\.frmIngreso\.Ajustador1" "Aceptar1 lookup by parent"
Assert-Contains $script "FindScxRecord[\s\S]*commandbutton" "Aceptar1 lookup by baseclass"
Assert-Contains $script "INGRESO COMPROBANTES_codex_01_propiedades_formset\.txt" "properties sidecar"
Assert-Contains $script "INGRESO COMPROBANTES_codex_02_reserved3\.txt" "reserved3 sidecar"
Assert-Contains $script "INGRESO COMPROBANTES_codex_03_metodos_formset\.prg" "Formset methods sidecar"
Assert-Contains $script "INGRESO COMPROBANTES_codex_04_aceptar1_click\.prg" "Aceptar1 click sidecar"
Assert-Contains $script "INGRESO COMPROBANTES_codex_05_btnBuscaPrecarga_click\.prg" "btnBuscaPrecarga click sidecar"
Assert-Contains $script "INGRESO COMPROBANTES_codex_06_validatablas\.txt" "validatablas sidecar"
Assert-Contains $script "INGRESO COMPROBANTES_codex_PLAN_MANUAL\.md" "manual plan sidecar"
Assert-Contains $script "btnBuscaPrecarga" "manual button definition"
Assert-Contains $script "Buscar pre-carga" "manual button caption"
Assert-Contains $script "btnaccdirecto" "manual button class"
Assert-Contains $script "Salir" "Aceptar1 menu option"
Assert-Contains $script "Grabar ingreso a stock" "Aceptar1 menu option"
Assert-Contains $script "Pre-cargar factura" "Aceptar1 menu option"
Assert-Contains $script "Cancelar" "Aceptar1 menu option"
Assert-Contains $script "lcProveedorBaja" "provider saved before release"
Assert-Contains $script "loForm\.Release\(\)[\s\S]*THISFORMSET\.Release\(\)" "release order"
Assert-Contains $script "no abrir Forms\\bajapedidos" "pre-carga path must explicitly avoid bajapedidos"
Assert-Contains $script "CREATE TABLE IF NOT EXISTS codex_ingcomp_pre" "validatablas creates header table"
Assert-Contains $script "CREATE TABLE IF NOT EXISTS codex_ingcomp_pre_det" "validatablas creates detail table"
Assert-Contains $script "goMy\.Sql\(m\.lsCad\)" "validatablas uses goMy.Sql"
Assert-NotContains $script "Local\s+lsCad" "validatablas block does not redeclare lsCad"
Assert-Contains $script "propiedades manuales" "summary includes manual properties"
Assert-Contains $script "reserved3 manual" "summary includes manual reserved3"
Assert-Contains $script "metodos manuales" "summary includes manual methods"
Assert-Contains $script "Aceptar1\.Click manual" "summary includes manual Aceptar1 status"

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
Assert-Contains $doc "sidecar-only" "sidecar-only behavior documented"
Assert-Contains $doc 'no escribe en el campo `methods`' "methods no-write documented"
Assert-Contains $doc "INGRESO COMPROBANTES_codex_01_propiedades_formset\.txt" "properties sidecar documented"
Assert-Contains $doc "INGRESO COMPROBANTES_codex_02_reserved3\.txt" "reserved3 sidecar documented"
Assert-Contains $doc "INGRESO COMPROBANTES_codex_03_metodos_formset\.prg" "methods sidecar documented"
Assert-Contains $doc "INGRESO COMPROBANTES_codex_04_aceptar1_click\.prg" "Aceptar1 sidecar documented"
Assert-Contains $doc "INGRESO COMPROBANTES_codex_05_btnBuscaPrecarga_click\.prg" "button click sidecar documented"
Assert-Contains $doc "INGRESO COMPROBANTES_codex_06_validatablas\.txt" "validatablas sidecar documented"
Assert-Contains $doc "INGRESO COMPROBANTES_codex_PLAN_MANUAL\.md" "manual plan sidecar documented"

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
