* apply_scx_changes.prg
* Aplicador seguro para preparar cambios sobre copias de formularios SCX/SCT.
*
* Uso recomendado sobre sandbox:
* DO src\apply_scx_changes.prg WITH ;
*    "X:\vfp_legacy_exporter\work\fasa_sandbox\forms\INGRESO COMPROBANTES.SCX", ;
*    "PREPARE_INGRESO_COMPROBANTES"
*
* Este script no parchea SCX/SCT como texto bruto. Abre el SCX como tabla VFP,
* crea backup antes de cualquier modificacion y rechaza la ruta productiva
* conocida del caso INGRESO COMPROBANTES.
*
* Sidecars generados:
* - INGRESO COMPROBANTES_codex_methods_added.prg
* - INGRESO COMPROBANTES_codex_aceptar1_click.prg
* - INGRESO COMPROBANTES_codex_btnBuscaPrecarga_click.prg
* - INGRESO COMPROBANTES_codex_apply_plan.md

LPARAMETERS tcScxFile, tcMode

SET SAFETY OFF
SET TALK OFF
SET EXCLUSIVE OFF
SET DELETED OFF

IF EMPTY(tcScxFile)
    ? "Debe indicar el archivo .SCX de una copia/sandbox."
    RETURN .F.
ENDIF

IF EMPTY(tcMode)
    tcMode = "PREPARE_INGRESO_COMPROBANTES"
ENDIF

tcScxFile = FULLPATH(tcScxFile)
tcMode = UPPER(ALLTRIM(tcMode))

IF LOWER(JUSTEXT(tcScxFile)) <> "scx"
    ? "El archivo indicado no es .SCX: " + tcScxFile
    RETURN .F.
ENDIF

IF IsForbiddenProductionScx(tcScxFile)
    ? "Ruta productiva bloqueada. Trabaje solo sobre una copia/sandbox."
    ? tcScxFile
    RETURN .F.
ENDIF

IF NOT FILE(tcScxFile)
    ? "No existe el .SCX indicado: " + tcScxFile
    RETURN .F.
ENDIF

LOCAL lcSctFile
lcSctFile = ADDBS(JUSTPATH(tcScxFile)) + JUSTSTEM(tcScxFile) + ".SCT"

IF NOT FILE(lcSctFile)
    ? "No existe el .SCT par esperado: " + lcSctFile
    RETURN .F.
ENDIF

LOCAL lcAlias, lcBackupDir, llResult
lcAlias = "scx_" + SYS(2015)
lcBackupDir = ""
llResult = .F.

DO BackupScxPair WITH tcScxFile, lcSctFile, lcBackupDir
IF EMPTY(lcBackupDir)
    ? "No se pudo crear backup. Se detiene sin modificar."
    RETURN .F.
ENDIF

TRY
    USE (tcScxFile) ALIAS (lcAlias) IN 0 SHARED AGAIN
CATCH TO loOpenError
    ? "No se pudo abrir el SCX como tabla VFP: " + loOpenError.Message
    RETURN .F.
ENDTRY

DO CASE
CASE tcMode == "PREPARE_INGRESO_COMPROBANTES"
    llResult = ApplyIngresoComprobantesPreparation(lcAlias, tcScxFile, lcBackupDir)
OTHERWISE
    ? "Modo no soportado: " + tcMode
    llResult = .F.
ENDCASE

IF USED(lcAlias)
    USE IN (lcAlias)
ENDIF

IF llResult
    ? "Aplicador finalizado correctamente."
    ? "Backup: " + lcBackupDir
ELSE
    ? "Aplicador finalizado con errores. Revise mensajes anteriores."
ENDIF

RETURN llResult


PROCEDURE BackupScxPair
    LPARAMETERS tcScxFile, tcSctFile, tcBackupDir

    LOCAL lcStamp, lcBackupDir, lcBackupScx, lcBackupSct
    lcStamp = SafeTimestamp()
    lcBackupDir = ADDBS(JUSTPATH(tcScxFile)) + "_scx_backups\" + ;
        JUSTSTEM(tcScxFile) + "_" + lcStamp

    DO EnsureDir WITH ADDBS(JUSTPATH(tcScxFile)) + "_scx_backups"
    DO EnsureDir WITH lcBackupDir
    lcBackupDir = ADDBS(lcBackupDir)

    lcBackupScx = lcBackupDir + JUSTFNAME(tcScxFile)
    lcBackupSct = lcBackupDir + JUSTFNAME(tcSctFile)

    TRY
        COPY FILE (tcScxFile) TO (lcBackupScx)
        COPY FILE (tcSctFile) TO (lcBackupSct)
    CATCH TO loBackupError
        ? "Error creando backup: " + loBackupError.Message
        tcBackupDir = ""
        RETURN
    ENDTRY

    tcBackupDir = lcBackupDir
ENDPROC


FUNCTION ApplyIngresoComprobantesPreparation
    LPARAMETERS tcAlias, tcScxFile, tcBackupDir

    LOCAL lnFormsetRecord, lnAceptarRecord
    LOCAL lcMethodsBlock, lcAceptarClick, lcBtnClick, lcAceptarStatus

    IF UPPER(JUSTSTEM(tcScxFile)) <> "INGRESO COMPROBANTES"
        ? "El modo PREPARE_INGRESO_COMPROBANTES solo aplica al formulario INGRESO COMPROBANTES."
        RETURN .F.
    ENDIF

    IF NOT IsAllowedIngresoSandboxScx(tcScxFile)
        ? "Ruta sandbox no permitida para este modo. Use:"
        ? "X:\vfp_legacy_exporter\work\fasa_sandbox\forms\INGRESO COMPROBANTES.SCX"
        RETURN .F.
    ENDIF

    lnFormsetRecord = FindScxRecord(tcAlias, "", "", "", "formset")
    IF lnFormsetRecord = 0
        lnFormsetRecord = FindScxRecord(tcAlias, "", "", "formset", "")
    ENDIF

    IF lnFormsetRecord = 0
        ? "No se encontro registro Formset en INGRESO COMPROBANTES."
        RETURN .F.
    ENDIF

    IF NOT AppendPropertyIfMissing(tcAlias, lnFormsetRecord, "nIdPrecarga", "nIdPrecarga = 0")
        RETURN .F.
    ENDIF
    IF NOT AppendPropertyIfMissing(tcAlias, lnFormsetRecord, "lDesdePrecarga", "lDesdePrecarga = .F.")
        RETURN .F.
    ENDIF

    IF NOT AppendIngresoReserved3(tcAlias, lnFormsetRecord)
        RETURN .F.
    ENDIF

    IF NOT AppendIngresoMethods(tcAlias, lnFormsetRecord)
        RETURN .F.
    ENDIF

    lcMethodsBlock = BuildIngresoMethodsBlock()
    lcAceptarClick = BuildAceptar1ClickBlock()
    lcBtnClick = BuildBtnBuscaPrecargaClickBlock()

    lnAceptarRecord = FindScxRecord(tcAlias, ;
        "Aceptar1", ;
        "Formset.frmIngreso.Ajustador1", ;
        "", ;
        "commandbutton")

    IF lnAceptarRecord > 0
        IF NOT ReplaceMemoBlock(tcAlias, lnAceptarRecord, "methods", lcAceptarClick)
            RETURN .F.
        ENDIF
        lcAceptarStatus = "Aceptar1.Click reemplazado automaticamente."
    ELSE
        lcAceptarStatus = "Aceptar1.Click no localizado con seguridad; queda manual."
    ENDIF

    DO WriteIngresoComprobantesSidecars WITH ;
        tcScxFile, ;
        tcBackupDir, ;
        lcMethodsBlock, ;
        lcAceptarClick, ;
        lcBtnClick, ;
        lcAceptarStatus

    ? "Preparacion aplicada para INGRESO COMPROBANTES."
    ? "propiedades agregadas: nIdPrecarga, lDesdePrecarga"
    ? "reserved3 actualizado: nidprecarga, ldesdeprecarga, *safec, *safesqlc, *safen, *grabaprecarga, *buscaprecargaproveedor, *cargaprecarga, *marcaprecargacargada"
    ? "metodos agregados: SafeC, SafeSQLC, SafeN, GrabaPrecarga, BuscaPrecargaProveedor, CargaPrecarga, MarcaPrecargaCargada"
    ? "Aceptar1.Click: " + lcAceptarStatus
    ? "Boton visual: manual; usar btnBuscaPrecarga y el sidecar de Click generado."
    ? "Backup creado: " + tcBackupDir
    RETURN .T.
ENDFUNC


FUNCTION AppendIngresoReserved3
    LPARAMETERS tcAlias, tnRecord

    IF NOT AppendReserved3TokenIfMissing(tcAlias, tnRecord, "nidprecarga")
        RETURN .F.
    ENDIF
    IF NOT AppendReserved3TokenIfMissing(tcAlias, tnRecord, "ldesdeprecarga")
        RETURN .F.
    ENDIF
    IF NOT AppendReserved3TokenIfMissing(tcAlias, tnRecord, "*safec")
        RETURN .F.
    ENDIF
    IF NOT AppendReserved3TokenIfMissing(tcAlias, tnRecord, "*safesqlc")
        RETURN .F.
    ENDIF
    IF NOT AppendReserved3TokenIfMissing(tcAlias, tnRecord, "*safen")
        RETURN .F.
    ENDIF
    IF NOT AppendReserved3TokenIfMissing(tcAlias, tnRecord, "*grabaprecarga")
        RETURN .F.
    ENDIF
    IF NOT AppendReserved3TokenIfMissing(tcAlias, tnRecord, "*buscaprecargaproveedor")
        RETURN .F.
    ENDIF
    IF NOT AppendReserved3TokenIfMissing(tcAlias, tnRecord, "*cargaprecarga")
        RETURN .F.
    ENDIF
    IF NOT AppendReserved3TokenIfMissing(tcAlias, tnRecord, "*marcaprecargacargada")
        RETURN .F.
    ENDIF

    RETURN .T.
ENDFUNC


FUNCTION AppendIngresoMethods
    LPARAMETERS tcAlias, tnRecord

    IF NOT AppendMemoBlockIfMissing(tcAlias, tnRecord, "methods", "PROCEDURE SafeC", BuildSafeCMethod())
        RETURN .F.
    ENDIF
    IF NOT AppendMemoBlockIfMissing(tcAlias, tnRecord, "methods", "PROCEDURE SafeSQLC", BuildSafeSQLCMethod())
        RETURN .F.
    ENDIF
    IF NOT AppendMemoBlockIfMissing(tcAlias, tnRecord, "methods", "PROCEDURE SafeN", BuildSafeNMethod())
        RETURN .F.
    ENDIF
    IF NOT AppendMemoBlockIfMissing(tcAlias, tnRecord, "methods", "PROCEDURE GrabaPrecarga", BuildGrabaPrecargaMethod())
        RETURN .F.
    ENDIF
    IF NOT AppendMemoBlockIfMissing(tcAlias, tnRecord, "methods", "PROCEDURE BuscaPrecargaProveedor", BuildBuscaPrecargaProveedorMethod())
        RETURN .F.
    ENDIF
    IF NOT AppendMemoBlockIfMissing(tcAlias, tnRecord, "methods", "PROCEDURE CargaPrecarga", BuildCargaPrecargaMethod())
        RETURN .F.
    ENDIF
    IF NOT AppendMemoBlockIfMissing(tcAlias, tnRecord, "methods", "PROCEDURE MarcaPrecargaCargada", BuildMarcaPrecargaCargadaMethod())
        RETURN .F.
    ENDIF

    RETURN .T.
ENDFUNC


FUNCTION AppendPropertyIfMissing
    LPARAMETERS tcAlias, tnRecord, tcPropertyName, tcPropertyLine

    RETURN AppendLineIfMissing(tcAlias, tnRecord, "properties", tcPropertyName, tcPropertyLine)
ENDFUNC


FUNCTION AppendReserved3TokenIfMissing
    LPARAMETERS tcAlias, tnRecord, tcToken

    RETURN AppendLineIfMissing(tcAlias, tnRecord, "reserved3", tcToken, tcToken)
ENDFUNC


FUNCTION AppendLineIfMissing
    LPARAMETERS tcAlias, tnRecord, tcFieldName, tcMarker, tcLine

    LOCAL lcCurrent, lcNewValue

    IF NOT HasField(tcAlias, tcFieldName)
        ? "El SCX no tiene campo requerido: " + tcFieldName
        RETURN .F.
    ENDIF

    SELECT (tcAlias)
    GO tnRecord

    lcCurrent = GetFieldText(tcAlias, tcFieldName)
    IF ATC(tcMarker, lcCurrent) > 0
        ? "Entrada ya existente, no se duplica: " + tcMarker
        RETURN .T.
    ENDIF

    lcNewValue = lcCurrent
    IF NOT EMPTY(lcNewValue)
        lcNewValue = lcNewValue + CRLF()
    ENDIF
    lcNewValue = lcNewValue + tcLine

    RETURN ReplaceMemoBlock(tcAlias, tnRecord, tcFieldName, lcNewValue)
ENDFUNC


FUNCTION AppendMemoBlockIfMissing
    LPARAMETERS tcAlias, tnRecord, tcFieldName, tcMarker, tcBlock

    LOCAL lcCurrent, lcNewValue

    IF NOT HasField(tcAlias, tcFieldName)
        ? "El SCX no tiene campo requerido: " + tcFieldName
        RETURN .F.
    ENDIF

    SELECT (tcAlias)
    GO tnRecord

    lcCurrent = GetFieldText(tcAlias, tcFieldName)
    IF ATC(tcMarker, lcCurrent) > 0
        ? "Bloque ya existente, no se duplica: " + tcMarker
        RETURN .T.
    ENDIF

    lcNewValue = lcCurrent
    IF NOT EMPTY(lcNewValue)
        lcNewValue = lcNewValue + CRLF()
    ENDIF
    lcNewValue = lcNewValue + tcBlock

    RETURN ReplaceMemoBlock(tcAlias, tnRecord, tcFieldName, lcNewValue)
ENDFUNC


FUNCTION ReplaceMemoBlock
    LPARAMETERS tcAlias, tnRecord, tcFieldName, tcNewValue

    IF NOT HasField(tcAlias, tcFieldName)
        ? "El SCX no tiene campo requerido: " + tcFieldName
        RETURN .F.
    ENDIF

    SELECT (tcAlias)
    GO tnRecord

    IF NOT RLOCK()
        ? "No se pudo bloquear el registro " + TRANSFORM(tnRecord)
        RETURN .F.
    ENDIF

    TRY
        REPLACE (tcFieldName) WITH tcNewValue IN (tcAlias)
    CATCH TO loReplaceError
        UNLOCK IN (tcAlias)
        ? "No se pudo actualizar " + tcFieldName + ": " + loReplaceError.Message
        RETURN .F.
    ENDTRY

    UNLOCK IN (tcAlias)
    RETURN .T.
ENDFUNC


FUNCTION FindScxRecord
    LPARAMETERS tcAlias, tcObjName, tcParent, tcClass, tcBaseClass

    LOCAL lnFound
    lnFound = 0

    SELECT (tcAlias)
    GO TOP

    SCAN
        IF RecordMatches(tcAlias, "objname", tcObjName) AND ;
                RecordMatches(tcAlias, "parent", tcParent) AND ;
                RecordMatches(tcAlias, "class", tcClass) AND ;
                RecordMatches(tcAlias, "baseclass", tcBaseClass)
            lnFound = RECNO()
            EXIT
        ENDIF
    ENDSCAN

    RETURN lnFound
ENDFUNC


FUNCTION RecordMatches
    LPARAMETERS tcAlias, tcFieldName, tcExpected

    LOCAL lcExpected, lcActual
    lcExpected = UPPER(ALLTRIM(tcExpected))

    IF EMPTY(lcExpected)
        RETURN .T.
    ENDIF

    IF NOT HasField(tcAlias, tcFieldName)
        RETURN .F.
    ENDIF

    lcActual = UPPER(ALLTRIM(GetFieldText(tcAlias, tcFieldName)))
    RETURN lcActual == lcExpected
ENDFUNC


FUNCTION HasField
    LPARAMETERS tcAlias, tcFieldName

    LOCAL laFields[1], lnFields, i

    SELECT (tcAlias)
    lnFields = AFIELDS(laFields)

    FOR i = 1 TO lnFields
        IF LOWER(laFields[i, 1]) == LOWER(tcFieldName)
            RETURN .T.
        ENDIF
    ENDFOR

    RETURN .F.
ENDFUNC


FUNCTION GetFieldText
    LPARAMETERS tcAlias, tcFieldName

    LOCAL luValue

    SELECT (tcAlias)

    TRY
        luValue = EVALUATE(tcAlias + "." + tcFieldName)
    CATCH
        RETURN ""
    ENDTRY

    IF ISNULL(luValue)
        RETURN ""
    ENDIF

    RETURN TRANSFORM(luValue)
ENDFUNC


PROCEDURE WriteIngresoComprobantesSidecars
    LPARAMETERS tcScxFile, tcBackupDir, tcMethodsBlock, tcAceptarClick, tcBtnClick, tcAceptarStatus

    LOCAL lcBase, lcMethodsFile, lcAceptarFile, lcBtnFile, lcPlanFile
    LOCAL lcPlan, lcBtnProps

    lcBase = ADDBS(JUSTPATH(tcScxFile)) + JUSTSTEM(tcScxFile)
    lcMethodsFile = lcBase + "_codex_methods_added.prg"
    lcAceptarFile = lcBase + "_codex_aceptar1_click.prg"
    lcBtnFile = lcBase + "_codex_btnBuscaPrecarga_click.prg"
    lcPlanFile = lcBase + "_codex_apply_plan.md"

    lcBtnProps = ;
        "Name = btnBuscaPrecarga" + CRLF() + ;
        "Caption = Pre-carga" + CRLF() + ;
        "Enabled = .T." + CRLF() + ;
        "Visible = .T." + CRLF() + ;
        "TabStop = .T."

    lcPlan = "# Plan manual INGRESO COMPROBANTES" + CRLF() + CRLF() + ;
        "- SCX: `" + tcScxFile + "`" + CRLF() + ;
        "- Backup: `" + tcBackupDir + "`" + CRLF() + ;
        "- Propiedades agregadas al Formset: `nIdPrecarga = 0`, `lDesdePrecarga = .F.`" + CRLF() + ;
        "- `reserved3` actualizado con propiedades y metodos protegidos de pre-carga." + CRLF() + ;
        "- Metodos agregados al Formset: `SafeC`, `SafeSQLC`, `SafeN`, `GrabaPrecarga`, `BuscaPrecargaProveedor`, `CargaPrecarga`, `MarcaPrecargaCargada`." + CRLF() + ;
        "- Aceptar1.Click: " + tcAceptarStatus + CRLF() + ;
        "- Boton visual automatico: no aplicado; agregar manualmente `btnBuscaPrecarga`." + CRLF() + ;
        "- Propiedades sugeridas del boton:" + CRLF() + CRLF() + ;
        "```text" + CRLF() + lcBtnProps + CRLF() + "```" + CRLF() + CRLF() + ;
        "- Codigo manual del boton: `" + JUSTFNAME(lcBtnFile) + "`" + CRLF() + ;
        "- Codigo final de Aceptar1.Click: `" + JUSTFNAME(lcAceptarFile) + "`" + CRLF() + ;
        "- Metodos agregados: `" + JUSTFNAME(lcMethodsFile) + "`" + CRLF()

    STRTOFILE(tcMethodsBlock, lcMethodsFile)
    STRTOFILE(tcAceptarClick, lcAceptarFile)
    STRTOFILE("* Propiedades sugeridas para btnBuscaPrecarga" + CRLF() + lcBtnProps + CRLF() + CRLF() + tcBtnClick, lcBtnFile)
    STRTOFILE(lcPlan, lcPlanFile)
ENDPROC


FUNCTION BuildIngresoMethodsBlock
    RETURN BuildSafeCMethod() + CRLF() + ;
        BuildSafeSQLCMethod() + CRLF() + ;
        BuildSafeNMethod() + CRLF() + ;
        BuildGrabaPrecargaMethod() + CRLF() + ;
        BuildBuscaPrecargaProveedorMethod() + CRLF() + ;
        BuildCargaPrecargaMethod() + CRLF() + ;
        BuildMarcaPrecargaCargadaMethod()
ENDFUNC


FUNCTION BuildSafeCMethod
    LOCAL lcCode

TEXT TO lcCode NOSHOW
PROCEDURE SafeC
    LPARAMETERS tuValue

    IF VARTYPE(tuValue) = "U" OR ISNULL(tuValue)
        RETURN ""
    ENDIF

    RETURN ALLTRIM(TRANSFORM(tuValue))
ENDPROC
ENDTEXT

    RETURN lcCode
ENDFUNC


FUNCTION BuildSafeSQLCMethod
    LOCAL lcCode

TEXT TO lcCode NOSHOW
PROCEDURE SafeSQLC
    LPARAMETERS tuValue

    LOCAL lcValue
    lcValue = THIS.SafeC(tuValue)
    lcValue = STRTRAN(lcValue, "'", "''")

    RETURN "'" + lcValue + "'"
ENDPROC
ENDTEXT

    RETURN lcCode
ENDFUNC


FUNCTION BuildSafeNMethod
    LOCAL lcCode

TEXT TO lcCode NOSHOW
PROCEDURE SafeN
    LPARAMETERS tuValue

    DO CASE
    CASE VARTYPE(tuValue) = "U" OR ISNULL(tuValue)
        RETURN 0
    CASE INLIST(VARTYPE(tuValue), "N", "I", "B", "F", "Y")
        RETURN tuValue
    CASE EMPTY(ALLTRIM(TRANSFORM(tuValue)))
        RETURN 0
    OTHERWISE
        RETURN VAL(ALLTRIM(TRANSFORM(tuValue)))
    ENDCASE
ENDPROC
ENDTEXT

    RETURN lcCode
ENDFUNC


FUNCTION BuildGrabaPrecargaMethod
    LOCAL lcCode

TEXT TO lcCode NOSHOW
PROCEDURE GrabaPrecarga
    LPARAMETERS tnIdPrecarga

    LOCAL lnIdPrecarga
    lnIdPrecarga = IIF(PCOUNT() > 0, THIS.SafeN(tnIdPrecarga), THIS.SafeN(THIS.nIdPrecarga))

    IF lnIdPrecarga <= 0
        RETURN .T.
    ENDIF

    THIS.nIdPrecarga = lnIdPrecarga
    THIS.lDesdePrecarga = .T.

    RETURN THIS.MarcaPrecargaCargada(lnIdPrecarga)
ENDPROC
ENDTEXT

    RETURN lcCode
ENDFUNC


FUNCTION BuildBuscaPrecargaProveedorMethod
    LOCAL lcCode

TEXT TO lcCode NOSHOW
PROCEDURE BuscaPrecargaProveedor
    LPARAMETERS tcProveedor

    LOCAL lnIdPrecarga, lcProveedor
    lnIdPrecarga = 0
    lcProveedor = UPPER(ALLTRIM(THIS.SafeC(tcProveedor)))

    IF NOT USED("precarga")
        MESSAGEBOX("No esta abierta la tabla o vista de pre-carga.", 48, "INGRESO COMPROBANTES")
        RETURN 0
    ENDIF

    SELECT precarga

    IF EMPTY(lcProveedor) OR TYPE("precarga.proveedor") = "U"
        LOCATE FOR NOT DELETED()
    ELSE
        LOCATE FOR NOT DELETED() AND UPPER(ALLTRIM(TRANSFORM(precarga.proveedor))) == lcProveedor
    ENDIF

    IF FOUND() AND TYPE("precarga.idprecarga") <> "U"
        lnIdPrecarga = THIS.SafeN(precarga.idprecarga)
    ENDIF

    RETURN lnIdPrecarga
ENDPROC
ENDTEXT

    RETURN lcCode
ENDFUNC


FUNCTION BuildCargaPrecargaMethod
    LOCAL lcCode

TEXT TO lcCode NOSHOW
PROCEDURE CargaPrecarga
    LPARAMETERS tnIdPrecarga

    LOCAL lnIdPrecarga
    lnIdPrecarga = THIS.SafeN(tnIdPrecarga)

    IF lnIdPrecarga <= 0
        RETURN .F.
    ENDIF

    THIS.nIdPrecarga = lnIdPrecarga
    THIS.lDesdePrecarga = .T.

    IF USED("precarga") AND TYPE("precarga.idprecarga") <> "U"
        SELECT precarga
        LOCATE FOR NOT DELETED() AND THIS.SafeN(precarga.idprecarga) = lnIdPrecarga
        IF NOT FOUND()
            MESSAGEBOX("No se encontro la pre-carga seleccionada.", 48, "INGRESO COMPROBANTES")
            RETURN .F.
        ENDIF
    ENDIF

    RETURN .T.
ENDPROC
ENDTEXT

    RETURN lcCode
ENDFUNC


FUNCTION BuildMarcaPrecargaCargadaMethod
    LOCAL lcCode

TEXT TO lcCode NOSHOW
PROCEDURE MarcaPrecargaCargada
    LPARAMETERS tnIdPrecarga

    LOCAL lnIdPrecarga
    lnIdPrecarga = THIS.SafeN(tnIdPrecarga)

    IF lnIdPrecarga <= 0
        RETURN .T.
    ENDIF

    IF NOT USED("precarga") OR TYPE("precarga.idprecarga") = "U"
        RETURN .T.
    ENDIF

    SELECT precarga
    LOCATE FOR NOT DELETED() AND THIS.SafeN(precarga.idprecarga) = lnIdPrecarga

    IF FOUND() AND TYPE("precarga.cargada") <> "U"
        IF RLOCK()
            REPLACE cargada WITH .T. IN precarga
            UNLOCK IN precarga
        ENDIF
    ENDIF

    RETURN .T.
ENDPROC
ENDTEXT

    RETURN lcCode
ENDFUNC


FUNCTION BuildAceptar1ClickBlock
    LOCAL lcCode

TEXT TO lcCode NOSHOW
PROCEDURE Click
    LOCAL llOk
    llOk = .T.

    IF PEMSTATUS(THISFORMSET, "GrabaPrecarga", 5)
        llOk = THISFORMSET.GrabaPrecarga()
    ENDIF

    IF llOk
        DODEFAULT()
    ENDIF
ENDPROC
ENDTEXT

    RETURN lcCode
ENDFUNC


FUNCTION BuildBtnBuscaPrecargaClickBlock
    LOCAL lcCode

TEXT TO lcCode NOSHOW
PROCEDURE Click
    LOCAL lnIdPrecarga
    lnIdPrecarga = 0

    IF PEMSTATUS(THISFORMSET, "BuscaPrecargaProveedor", 5)
        lnIdPrecarga = THISFORMSET.BuscaPrecargaProveedor()
    ENDIF

    IF lnIdPrecarga > 0 AND PEMSTATUS(THISFORMSET, "CargaPrecarga", 5)
        THISFORMSET.CargaPrecarga(lnIdPrecarga)
    ENDIF
ENDPROC
ENDTEXT

    RETURN lcCode
ENDFUNC


FUNCTION IsForbiddenProductionScx
    LPARAMETERS tcScxFile

    LOCAL lcPath
    lcPath = UPPER(FULLPATH(tcScxFile))

    RETURN lcPath == "X:\FASA\FORMS\INGRESO COMPROBANTES.SCX"
ENDFUNC


FUNCTION IsAllowedIngresoSandboxScx
    LPARAMETERS tcScxFile

    LOCAL lcPath
    lcPath = UPPER(FULLPATH(tcScxFile))

    RETURN lcPath == "X:\VFP_LEGACY_EXPORTER\WORK\FASA_SANDBOX\FORMS\INGRESO COMPROBANTES.SCX"
ENDFUNC


PROCEDURE EnsureDir
    LPARAMETERS tcDir

    IF NOT DIRECTORY(tcDir)
        MD (tcDir)
    ENDIF
ENDPROC


FUNCTION SafeTimestamp
    LOCAL lcStamp

    lcStamp = TTOC(DATETIME(), 1)
    lcStamp = STRTRAN(lcStamp, "-", "")
    lcStamp = STRTRAN(lcStamp, ":", "")
    lcStamp = STRTRAN(lcStamp, "T", "_")

    RETURN lcStamp
ENDFUNC


FUNCTION CRLF
    RETURN CHR(13) + CHR(10)
ENDFUNC
