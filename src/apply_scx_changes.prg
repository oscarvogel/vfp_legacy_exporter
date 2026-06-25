* apply_scx_changes.prg
* Generador seguro de cambios manuales para copias de formularios SCX/SCT.
*
* Uso recomendado sobre sandbox:
* DO src\apply_scx_changes.prg WITH ;
*    "X:\vfp_legacy_exporter\work\fasa_sandbox\forms\INGRESO COMPROBANTES.SCX", ;
*    "PREPARE_INGRESO_COMPROBANTES"
*
* Modo default: sidecar-only. No escribe en el campo `methods`, no reemplaza
* Aceptar1.Click, no agrega metodos al Formset y no modifica `properties` ni
* `reserved3`. Abre el SCX como tabla Visual FoxPro en NOUPDATE, localiza
* registros relevantes y genera archivos auxiliares limpios para pegar desde
* el diseñador de VFP.
*
* Sidecars generados:
* - INGRESO COMPROBANTES_codex_01_propiedades_formset.txt
* - INGRESO COMPROBANTES_codex_02_reserved3.txt
* - INGRESO COMPROBANTES_codex_03_metodos_formset.prg
* - INGRESO COMPROBANTES_codex_04_aceptar1_click.prg
* - INGRESO COMPROBANTES_codex_05_btnBuscaPrecarga_click.prg
* - INGRESO COMPROBANTES_codex_06_validatablas.txt
* - INGRESO COMPROBANTES_codex_PLAN_MANUAL.md

LPARAMETERS tcScxFile, tcMode, tcBackupOption

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

LOCAL lcAlias, lcBackupDir, llResult, llCreateBackup
lcAlias = "scx_" + SYS(2015)
lcBackupDir = "No solicitado"
llResult = .F.
llCreateBackup = (UPPER(ALLTRIM(tcBackupOption)) == "BACKUP")

IF llCreateBackup
    DO BackupScxPair WITH tcScxFile, lcSctFile, lcBackupDir
    IF EMPTY(lcBackupDir)
        ? "No se pudo crear backup. Se detiene sin modificar."
        RETURN .F.
    ENDIF
ENDIF

TRY
    USE (tcScxFile) ALIAS (lcAlias) IN 0 SHARED AGAIN NOUPDATE
CATCH TO loOpenError
    ? "No se pudo abrir el SCX como tabla VFP en modo NOUPDATE: " + loOpenError.Message
    RETURN .F.
ENDTRY

DO CASE
CASE tcMode == "PREPARE_INGRESO_COMPROBANTES"
    llResult = GenerateIngresoComprobantesSidecars(lcAlias, tcScxFile, lcBackupDir)
OTHERWISE
    ? "Modo no soportado: " + tcMode
    llResult = .F.
ENDCASE

IF USED(lcAlias)
    USE IN (lcAlias)
ENDIF

IF llResult
    ? "Generador sidecar-only finalizado correctamente."
    ? "Backup: " + lcBackupDir
ELSE
    ? "Generador finalizado con errores. Revise mensajes anteriores."
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


FUNCTION GenerateIngresoComprobantesSidecars
    LPARAMETERS tcAlias, tcScxFile, tcBackupDir

    LOCAL lnFormsetRecord, lnAceptarRecord
    LOCAL lcFormsetStatus, lcAceptarStatus

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

    IF lnFormsetRecord > 0
        lcFormsetStatus = "Formset localizado en registro " + TRANSFORM(lnFormsetRecord) + "."
    ELSE
        lcFormsetStatus = "Formset no localizado automaticamente; revisar manualmente en VFP."
    ENDIF

    lnAceptarRecord = FindScxRecord(tcAlias, ;
        "Aceptar1", ;
        "Formset.frmIngreso.Ajustador1", ;
        "", ;
        "commandbutton")

    IF lnAceptarRecord > 0
        lcAceptarStatus = "Aceptar1 localizado en registro " + TRANSFORM(lnAceptarRecord) + "."
    ELSE
        lcAceptarStatus = "Aceptar1 no localizado con seguridad; reemplazar Click manualmente si corresponde."
    ENDIF

    DO WriteIngresoComprobantesSidecars WITH ;
        tcScxFile, ;
        tcBackupDir, ;
        lcFormsetStatus, ;
        lcAceptarStatus

    ? "Modo: sidecar-only; no se modifica SCX/SCT."
    ? "SCX abierto como tabla VFP con NOUPDATE."
    ? lcFormsetStatus
    ? lcAceptarStatus
    ? "propiedades manuales: nIdPrecarga, lDesdePrecarga"
    ? "reserved3 manual: nidprecarga, ldesdeprecarga, *safec, *safesqlc, *safen, *grabaprecarga, *buscaprecargaproveedor, *cargaprecarga, *marcaprecargacargada"
    ? "metodos manuales: SafeC, SafeSQLC, SafeN, GrabaPrecarga, BuscaPrecargaProveedor, CargaPrecarga, MarcaPrecargaCargada"
    ? "Aceptar1.Click manual: usar INGRESO COMPROBANTES_codex_04_aceptar1_click.prg"
    ? "Boton visual manual: crear btnBuscaPrecarga y pegar el sidecar de Click."
    ? "Backup: " + tcBackupDir

    RETURN .T.
ENDFUNC


PROCEDURE WriteIngresoComprobantesSidecars
    LPARAMETERS tcScxFile, tcBackupDir, tcFormsetStatus, tcAceptarStatus

    LOCAL lcBase, lcMethodsFile, lcAceptarFile, lcBtnFile
    LOCAL lcPropertiesFile, lcReserved3File, lcValidatablasFile, lcPlanFile
    LOCAL lcProperties, lcReserved3, lcMethods, lcAceptarClick, lcBtnClick
    LOCAL lcValidatablas, lcPlan, lcBtnProps

    lcBase = ADDBS(JUSTPATH(tcScxFile)) + JUSTSTEM(tcScxFile)
    lcPropertiesFile = lcBase + "_codex_01_propiedades_formset.txt"
    lcReserved3File = lcBase + "_codex_02_reserved3.txt"
    lcMethodsFile = lcBase + "_codex_03_metodos_formset.prg"
    lcAceptarFile = lcBase + "_codex_04_aceptar1_click.prg"
    lcBtnFile = lcBase + "_codex_05_btnBuscaPrecarga_click.prg"
    lcValidatablasFile = lcBase + "_codex_06_validatablas.txt"
    lcPlanFile = lcBase + "_codex_PLAN_MANUAL.md"

    lcProperties = BuildPropertiesText()
    lcReserved3 = BuildReserved3Text()
    lcMethods = BuildIngresoMethodsBlock()
    lcAceptarClick = BuildAceptar1ClickBlock()
    lcBtnClick = BuildBtnBuscaPrecargaClickBlock()
    lcValidatablas = BuildValidatablasBlock()
    lcBtnProps = BuildBtnBuscaPrecargaPropertiesText()

    lcPlan = "# Plan manual INGRESO COMPROBANTES" + CRLF() + CRLF() + ;
        "- Modo: `sidecar-only`." + CRLF() + ;
        "- SCX: `" + tcScxFile + "`" + CRLF() + ;
        "- Backup: `" + tcBackupDir + "`" + CRLF() + ;
        "- " + tcFormsetStatus + CRLF() + ;
        "- " + tcAceptarStatus + CRLF() + ;
        "- El script no escribe en el campo `methods`, no reemplaza `Aceptar1.Click`, no modifica `properties` ni `reserved3`." + CRLF() + CRLF() + ;
        "## Pasos manuales" + CRLF() + CRLF() + ;
        "1. Abrir con `MODIFY FORM`." + CRLF() + ;
        "2. Agregar propiedades al Formset pegando/recreando lo indicado en `" + JUSTFNAME(lcPropertiesFile) + "`." + CRLF() + ;
        "3. Agregar metodos del Formset pegando desde `" + JUSTFNAME(lcMethodsFile) + "`." + CRLF() + ;
        "4. Revisar `reserved3` y agregar manualmente lo indicado en `" + JUSTFNAME(lcReserved3File) + "` si el disenador lo requiere." + CRLF() + ;
        "5. Seleccionar `Aceptar1.Click` y reemplazar manualmente el cuerpo pegando desde `" + JUSTFNAME(lcAceptarFile) + "`." + CRLF() + ;
        "6. Agregar boton visual en `Ajustador1`." + CRLF() + ;
        "7. Clase del boton: `btnaccdirecto`; classloc: `..\libs\botones.vcx`; name: `btnBuscaPrecarga`; caption: `Buscar pre-carga`." + CRLF() + ;
        "8. Ubicacion sugerida: junto a los botones de accion existentes dentro de `Formset.frmIngreso.Ajustador1`." + CRLF() + ;
        "9. Configurar el boton con estas propiedades sugeridas:" + CRLF() + CRLF() + ;
        "```text" + CRLF() + lcBtnProps + CRLF() + "```" + CRLF() + CRLF() + ;
        "10. Pegar `_click` desde `" + JUSTFNAME(lcBtnFile) + "`." + CRLF() + ;
        "11. Ubicar el metodo `validatablas` real y pegar al final el bloque `" + JUSTFNAME(lcValidatablasFile) + "`." + CRLF() + ;
        "12. Guardar." + CRLF() + ;
        "13. Cerrar y reabrir el formulario para validar." + CRLF() + CRLF() + ;
        "## Checklist de prueba" + CRLF() + CRLF() + ;
        "- [ ] `MODIFY FORM` abre sin errores." + CRLF() + ;
        "- [ ] Propiedades del Formset visibles y guardadas." + CRLF() + ;
        "- [ ] Metodos del Formset compilan." + CRLF() + ;
        "- [ ] `Aceptar1.Click` muestra las opciones Salir, Grabar ingreso a stock, Pre-cargar factura, Cancelar." + CRLF() + ;
        "- [ ] Pre-cargar factura no abre `Forms\bajapedidos`." + CRLF() + ;
        "- [ ] `btnBuscaPrecarga` carga una pre-carga y vuelve foco a `grdDet`." + CRLF() + ;
        "- [ ] `validatablas` crea/migra `codex_ingcomp_pre` y `codex_ingcomp_pre_det`." + CRLF()

    STRTOFILE(lcMethods, lcMethodsFile)
    STRTOFILE(lcAceptarClick, lcAceptarFile)
    STRTOFILE(lcBtnClick, lcBtnFile)
    STRTOFILE(lcProperties, lcPropertiesFile)
    STRTOFILE(lcReserved3, lcReserved3File)
    STRTOFILE(lcValidatablas, lcValidatablasFile)
    STRTOFILE(lcPlan, lcPlanFile)
ENDPROC


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


FUNCTION BuildPropertiesText
    RETURN "* Agregar estas propiedades al Formset desde Visual FoxPro Designer." + CRLF() + ;
        "nIdPrecarga = 0" + CRLF() + ;
        "lDesdePrecarga = .F." + CRLF()
ENDFUNC


FUNCTION BuildReserved3Text
    RETURN "nidprecarga" + CRLF() + ;
        "ldesdeprecarga" + CRLF() + ;
        "*safec" + CRLF() + ;
        "*safesqlc" + CRLF() + ;
        "*safen" + CRLF() + ;
        "*grabaprecarga" + CRLF() + ;
        "*buscaprecargaproveedor" + CRLF() + ;
        "*cargaprecarga" + CRLF() + ;
        "*marcaprecargacargada" + CRLF()
ENDFUNC


FUNCTION BuildBtnBuscaPrecargaPropertiesText
    RETURN "Class = btnaccdirecto" + CRLF() + ;
        "ClassLoc = ..\libs\botones.vcx" + CRLF() + ;
        "Name = btnBuscaPrecarga" + CRLF() + ;
        "Caption = Buscar pre-carga" + CRLF() + ;
        "Enabled = .T." + CRLF() + ;
        "Visible = .T." + CRLF() + ;
        "TabStop = .T."
ENDFUNC


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
    LOCAL lnOpcion, lcProveedorBaja, loForm
    lnOpcion = 0
    lcProveedorBaja = ""
    loForm = THISFORM

    DEFINE POPUP codex_ingcomp_menu SHORTCUT RELATIVE FROM MROW(), MCOL()
    DEFINE BAR 1 OF codex_ingcomp_menu PROMPT "Salir"
    DEFINE BAR 2 OF codex_ingcomp_menu PROMPT "Grabar ingreso a stock"
    DEFINE BAR 3 OF codex_ingcomp_menu PROMPT "Pre-cargar factura"
    DEFINE BAR 4 OF codex_ingcomp_menu PROMPT "Cancelar"
    ON SELECTION BAR 1 OF codex_ingcomp_menu lnOpcion = 1
    ON SELECTION BAR 2 OF codex_ingcomp_menu lnOpcion = 2
    ON SELECTION BAR 3 OF codex_ingcomp_menu lnOpcion = 3
    ON SELECTION BAR 4 OF codex_ingcomp_menu lnOpcion = 4
    ACTIVATE POPUP codex_ingcomp_menu
    RELEASE POPUP codex_ingcomp_menu

    DO CASE
    CASE lnOpcion = 1
        IF TYPE("THISFORMSET.frmIngreso.txtProveedor.Value") <> "U"
            lcProveedorBaja = THISFORMSET.SafeC(THISFORMSET.frmIngreso.txtProveedor.Value)
        ENDIF
        IF VARTYPE(loForm) = "O" AND NOT ISNULL(loForm)
            loForm.Release()
        ENDIF
        THISFORMSET.Release()

    CASE lnOpcion = 2
        DODEFAULT()

    CASE lnOpcion = 3
        * Pre-cargar factura: no abrir Forms\bajapedidos.
        IF PEMSTATUS(THISFORMSET, "GrabaPrecarga", 5)
            THISFORMSET.GrabaPrecarga()
        ENDIF

    CASE lnOpcion = 4 OR lnOpcion = 0
        RETURN .F.
    ENDCASE
ENDPROC
ENDTEXT

    RETURN lcCode
ENDFUNC


FUNCTION BuildBtnBuscaPrecargaClickBlock
    LOCAL lcCode

TEXT TO lcCode NOSHOW
PROCEDURE Click
    Local lnId

    lnId = Thisformset.BuscaPrecargaProveedor()
    If lnId > 0
        Thisformset.CargaPrecarga(lnId)
    Endif

    Thisform.grdDet.SetFocus()
ENDPROC
ENDTEXT

    RETURN lcCode
ENDFUNC


FUNCTION BuildValidatablasBlock
    LOCAL lcCode

TEXT TO lcCode NOSHOW
* Codex issue 10 - pegar al final de validatablas.
* No agregar una declaracion local nueva para lsCad si el metodo ya la declara.

lsCad = "CREATE TABLE IF NOT EXISTS codex_ingcomp_pre (" + ;
    "idprecarga INT NOT NULL AUTO_INCREMENT PRIMARY KEY, " + ;
    "proveedor VARCHAR(120) NOT NULL DEFAULT '', " + ;
    "fecha DATE NULL, " + ;
    "nrocomprobante VARCHAR(60) NOT NULL DEFAULT '', " + ;
    "cargada TINYINT(1) NOT NULL DEFAULT 0, " + ;
    "created_at DATETIME NULL)"
goMy.Sql(m.lsCad)

lsCad = "CREATE TABLE IF NOT EXISTS codex_ingcomp_pre_det (" + ;
    "idprecargadet INT NOT NULL AUTO_INCREMENT PRIMARY KEY, " + ;
    "idprecarga INT NOT NULL, " + ;
    "codigo VARCHAR(60) NOT NULL DEFAULT '', " + ;
    "descripcion VARCHAR(180) NOT NULL DEFAULT '', " + ;
    "cantidad DECIMAL(14,4) NOT NULL DEFAULT 0, " + ;
    "precio DECIMAL(14,4) NOT NULL DEFAULT 0)"
goMy.Sql(m.lsCad)

lsCad = "ALTER TABLE codex_ingcomp_pre ADD COLUMN IF NOT EXISTS observaciones TEXT NULL"
goMy.Sql(m.lsCad)

lsCad = "ALTER TABLE codex_ingcomp_pre ADD COLUMN IF NOT EXISTS cargada TINYINT(1) NOT NULL DEFAULT 0"
goMy.Sql(m.lsCad)

lsCad = "ALTER TABLE codex_ingcomp_pre_det ADD COLUMN IF NOT EXISTS bonificacion DECIMAL(14,4) NOT NULL DEFAULT 0"
goMy.Sql(m.lsCad)

lsCad = "ALTER TABLE codex_ingcomp_pre_det ADD INDEX IF NOT EXISTS idx_codex_ingcomp_pre_det_pre (idprecarga)"
goMy.Sql(m.lsCad)
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
