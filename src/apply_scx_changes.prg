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

    LOCAL lnFormRecord, lcMarker, lcMethodBlock, llUpdated

    IF UPPER(JUSTSTEM(tcScxFile)) <> "INGRESO COMPROBANTES"
        ? "El modo PREPARE_INGRESO_COMPROBANTES solo aplica al formulario INGRESO COMPROBANTES."
        RETURN .F.
    ENDIF

    lnFormRecord = FindScxRecord(tcAlias, "", "", "", "form")
    IF lnFormRecord = 0
        lnFormRecord = FindScxRecord(tcAlias, "", "", "form", "")
    ENDIF

    IF lnFormRecord = 0
        ? "No se encontro registro baseclass/class form en INGRESO COMPROBANTES."
        RETURN .F.
    ENDIF

    lcMarker = "codex_issue10_precarga_manual"
    lcMethodBlock = CRLF() + ;
        "* CODEx issue 10 - INGRESO COMPROBANTES" + CRLF() + ;
        "* Metodo de preparacion no visual. El boton se agrega manualmente desde VFP." + CRLF() + ;
        "PROCEDURE codex_issue10_precarga_manual" + CRLF() + ;
        "    * Punto seguro para conectar la logica validada en sandbox." + CRLF() + ;
        "    MESSAGEBOX(" + CHR(34) + "Pendiente: conectar pre-carga validada en sandbox." + CHR(34) + ;
        ", 64, " + CHR(34) + "INGRESO COMPROBANTES" + CHR(34) + ")" + CRLF() + ;
        "ENDPROC" + CRLF()

    llUpdated = AppendMemoBlockIfMissing(tcAlias, lnFormRecord, "methods", lcMarker, lcMethodBlock)
    IF NOT llUpdated
        RETURN .F.
    ENDIF

    DO WriteIngresoComprobantesManualFiles WITH tcScxFile, tcBackupDir

    ? "Preparacion aplicada para INGRESO COMPROBANTES."
    ? "Paso visual manual: agregar boton y llamar THISFORM.codex_issue10_precarga_manual()."
    RETURN .T.
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

    IF NOT RLOCK()
        ? "No se pudo bloquear el registro " + TRANSFORM(tnRecord)
        RETURN .F.
    ENDIF

    lcNewValue = lcCurrent
    IF NOT EMPTY(lcNewValue)
        lcNewValue = lcNewValue + CRLF()
    ENDIF
    lcNewValue = lcNewValue + tcBlock

    TRY
        REPLACE (tcFieldName) WITH lcNewValue IN (tcAlias)
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


PROCEDURE WriteIngresoComprobantesManualFiles
    LPARAMETERS tcScxFile, tcBackupDir

    LOCAL lcBase, lcClickFile, lcPlanFile, lcClickCode, lcPlan

    lcBase = ADDBS(JUSTPATH(tcScxFile)) + JUSTSTEM(tcScxFile)
    lcClickFile = lcBase + "_codex_click_manual.prg"
    lcPlanFile = lcBase + "_codex_apply_plan.md"

    lcClickCode = "* Codigo sugerido para el Click del boton manual." + CRLF() + ;
        "* Pegar en el evento Click del boton agregado desde MODIFY FORM." + CRLF() + ;
        "IF PEMSTATUS(THISFORM, " + CHR(34) + "codex_issue10_precarga_manual" + CHR(34) + ", 5)" + CRLF() + ;
        "    THISFORM.codex_issue10_precarga_manual()" + CRLF() + ;
        "ELSE" + CRLF() + ;
        "    MESSAGEBOX(" + CHR(34) + "Metodo de pre-carga no encontrado en el formulario." + CHR(34) + ", 16, " + ;
        CHR(34) + "INGRESO COMPROBANTES" + CHR(34) + ")" + CRLF() + ;
        "ENDIF" + CRLF()

    lcPlan = "# Plan manual INGRESO COMPROBANTES" + CRLF() + CRLF() + ;
        "- SCX: `" + tcScxFile + "`" + CRLF() + ;
        "- Backup: `" + tcBackupDir + "`" + CRLF() + ;
        "- Cambio automatizado: metodo `codex_issue10_precarga_manual` agregado al formulario." + CRLF() + ;
        "- Cambio manual: abrir con `MODIFY FORM`, agregar boton visual y pegar el codigo de `" + ;
        JUSTFNAME(lcClickFile) + "` en el evento Click." + CRLF()

    STRTOFILE(lcClickCode, lcClickFile)
    STRTOFILE(lcPlan, lcPlanFile)
ENDPROC


FUNCTION IsForbiddenProductionScx
    LPARAMETERS tcScxFile

    LOCAL lcPath
    lcPath = UPPER(FULLPATH(tcScxFile))

    RETURN lcPath == "X:\FASA\FORMS\INGRESO COMPROBANTES.SCX"
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
