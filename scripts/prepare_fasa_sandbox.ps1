[CmdletBinding()]
param(
    [string]$SourceRoot = "X:\FASA",
    [string]$SandboxRoot = (Join-Path (Split-Path -Parent $PSScriptRoot) "work\fasa_sandbox"),
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$requiredFiles = @(
    "forms\INGRESO COMPROBANTES.SCX",
    "forms\INGRESO COMPROBANTES.SCT",
    "libs\generales.vcx",
    "libs\generales.vct",
    "libs\coleccion.vcx",
    "libs\coleccion.vct",
    "libs\botones.vcx",
    "libs\botones.vct",
    "libs\fasa.vcx",
    "libs\fasa.vct",
    "libs\lookup.vcx",
    "libs\lookup.vct",
    "libs\validaciones.vcx",
    "libs\validaciones.vct",
    "include\def.h",
    "include\tastrade.h"
)

function New-DirectoryIfMissing {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        New-Item -ItemType Directory -Path $Path | Out-Null
    }
}

function Copy-RequiredFile {
    param(
        [string]$RelativePath,
        [string]$SourceRoot,
        [string]$SandboxRoot,
        [switch]$Force
    )

    $source = Join-Path $SourceRoot $RelativePath
    $destination = Join-Path $SandboxRoot $RelativePath
    $destinationDir = Split-Path -Parent $destination

    if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
        return [pscustomobject]@{
            RelativePath = $RelativePath
            Status = "missing"
            Source = $source
            Destination = $destination
        }
    }

    New-DirectoryIfMissing $destinationDir

    if ((Test-Path -LiteralPath $destination -PathType Leaf) -and -not $Force) {
        return [pscustomobject]@{
            RelativePath = $RelativePath
            Status = "exists"
            Source = $source
            Destination = $destination
        }
    }

    Copy-Item -LiteralPath $source -Destination $destination -Force:$Force

    return [pscustomobject]@{
        RelativePath = $RelativePath
        Status = "copied"
        Source = $source
        Destination = $destination
    }
}

$SourceRoot = [System.IO.Path]::GetFullPath($SourceRoot)
$SandboxRoot = [System.IO.Path]::GetFullPath($SandboxRoot)

New-DirectoryIfMissing $SandboxRoot
New-DirectoryIfMissing (Join-Path $SandboxRoot "forms")
New-DirectoryIfMissing (Join-Path $SandboxRoot "libs")
New-DirectoryIfMissing (Join-Path $SandboxRoot "include")
New-DirectoryIfMissing (Join-Path $SandboxRoot "graphics")

$results = foreach ($relativePath in $requiredFiles) {
    Copy-RequiredFile -RelativePath $relativePath -SourceRoot $SourceRoot -SandboxRoot $SandboxRoot -Force:$Force
}

$missing = @($results | Where-Object { $_.Status -eq "missing" })
$copied = @($results | Where-Object { $_.Status -eq "copied" })
$existing = @($results | Where-Object { $_.Status -eq "exists" })
$sandboxScx = Join-Path $SandboxRoot "forms\INGRESO COMPROBANTES.SCX"
$repoRoot = Split-Path -Parent $PSScriptRoot

$summary = [pscustomobject]@{
    SandboxRoot = $SandboxRoot
    Copied = @($copied | ForEach-Object { $_.RelativePath })
    Existing = @($existing | ForEach-Object { $_.RelativePath })
    Missing = @($missing | ForEach-Object { $_.RelativePath })
    ModifyFormCommand = 'MODIFY FORM "' + $sandboxScx + '"'
    ApplyCommand = 'DO src\apply_scx_changes.prg WITH "' + $sandboxScx + '", "PREPARE_INGRESO_COMPROBANTES"'
    GraphicsNote = "No graphics are copied by default. Add only files required by this form if MODIFY FORM reports missing icons or images."
    RepoRoot = $repoRoot
}

$summary

if ($missing.Count -gt 0) {
    throw "Sandbox incompleto: faltan archivos requeridos. Revise la propiedad Missing."
}
