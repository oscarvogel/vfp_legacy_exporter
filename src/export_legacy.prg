* export_legacy.prg
* Exportador seguro de proyectos Visual FoxPro legacy.
*
* Objetivo:
* - Leer archivos VFP DBF-based como SCX, VCX, FRX y MNX.
* - Exportar su contenido a TXT, Markdown y JSON.
* - Copiar archivos de texto como PRG, H, INI y TXT.
* - No modificar nunca los archivos originales.
*
* Uso carpeta completa:
* DO src\export_legacy.prg WITH "C:\COPIA_SISTEMA_VFP", "D:\VFP_EXPORTS\COPIA_SISTEMA_VFP"
*
* Uso archivo puntual:
* DO src\export_legacy.prg WITH "C:\COPIA_SISTEMA_VFP\forms\pedido.scx", "D:\VFP_EXPORTS\pedido"

LPARAMETERS tcSourcePath, tcOutputRoot

SET SAFETY OFF
SET TALK OFF
SET EXCLUSIVE OFF
SET DELETED OFF

PRIVATE pcLogFile

LOCAL llSourceIsFolder, llSourceIsFile
LOCAL lcSourceFile, lcSourceRoot

IF EMPTY(tcSourcePath)
    ? "Debe indicar carpeta o archivo origen."
    RETURN .F.
ENDIF

tcSourcePath = FULLPATH(tcSourcePath)
llSourceIsFolder = DIRECTORY(tcSourcePath)
llSourceIsFile = FILE(tcSourcePath)

IF NOT llSourceIsFolder AND NOT llSourceIsFile
    ? "No existe el origen indicado: " + tcSourcePath
    RETURN .F.
ENDIF

IF llSourceIsFolder
    lcSourceRoot = FULLPATH(ADDBS(tcSourcePath))
    lcSourceFile = ""

    IF EMPTY(tcOutputRoot)
        tcOutputRoot = lcSourceRoot + "_exported"
    ENDIF
ELSE
    lcSourceFile = FULLPATH(tcSourcePath)
    lcSourceRoot = FULLPATH(ADDBS(JUSTPATH(lcSourceFile)))

    IF EMPTY(tcOutputRoot)
        tcOutputRoot = lcSourceRoot + JUSTSTEM(lcSourceFile) + "_exported"
    ENDIF
ENDIF

tcOutputRoot = FULLPATH(ADDBS(tcOutputRoot))
pcLogFile = tcOutputRoot + "export_errors.log"

DO EnsureDir WITH tcOutputRoot
DO EnsureDir WITH tcOutputRoot + "json"
DO EnsureDir WITH tcOutputRoot + "md"
DO EnsureDir WITH tcOutputRoot + "txt"

STRTOFILE("VFP legacy export log" + CRLF(), pcLogFile)
STRTOFILE("Source: " + tcSourcePath + CRLF(), pcLogFile, 1)
STRTOFILE("Source root: " + lcSourceRoot + CRLF(), pcLogFile, 1)
STRTOFILE("Output: " + tcOutputRoot + CRLF() + CRLF(), pcLogFile, 1)

? "Exportando proyecto VFP legacy..."
? "Origen : " + tcSourcePath
? "Destino: " + tcOutputRoot

IF llSourceIsFolder
    DO ExportFolder WITH lcSourceRoot, lcSourceRoot, tcOutputRoot
ELSE
    DO ExportSingleFile WITH lcSourceFile, lcSourceRoot, tcOutputRoot
ENDIF

? "Exportacion finalizada."
? "Log: " + pcLogFile

RETURN .T.


PROCEDURE ExportFolder
    LPARAMETERS tcFolder, tcSourceRoot, tcOutputRoot

    LOCAL laFiles[1], laDirs[1]
    LOCAL lnFiles, lnDirs, i
    LOCAL lcName, lcFullPath

    IF IsSameOrChildPath(tcFolder, tcOutputRoot)
        RETURN
    ENDIF

    lnFiles = ADIR(laFiles, ADDBS(tcFolder) + "*.*")

    FOR i = 1 TO lnFiles
        lcName = laFiles[i, 1]
        lcFullPath = ADDBS(tcFolder) + lcName

        IF DIRECTORY(lcFullPath)
            LOOP
        ENDIF

        DO ExportSingleFile WITH lcFullPath, tcSourceRoot, tcOutputRoot
    ENDFOR

    lnDirs = ADIR(laDirs, ADDBS(tcFolder) + "*.*", "D")

    FOR i = 1 TO lnDirs
        lcName = laDirs[i, 1]

        IF lcName == "." OR lcName == ".."
            LOOP
        ENDIF

        lcFullPath = ADDBS(tcFolder) + lcName

        IF DIRECTORY(lcFullPath)
            DO ExportFolder WITH lcFullPath, tcSourceRoot, tcOutputRoot
        ENDIF
    ENDFOR
ENDPROC


PROCEDURE ExportSingleFile
    LPARAMETERS tcFile, tcSourceRoot, tcOutputRoot

    LOCAL lcExt
    lcExt = LOWER(JUSTEXT(tcFile))

    DO CASE
    CASE INLIST(lcExt, "scx", "vcx", "frx", "mnx")
        DO ExportDbfBasedFile WITH tcFile, tcSourceRoot, tcOutputRoot

    CASE INLIST(lcExt, "prg", "h", "ini", "txt")
        DO ExportTextFile WITH tcFile, tcSourceRoot, tcOutputRoot

    OTHERWISE
        DO LogError WITH "Archivo omitido por extension no soportada: " + tcFile
    ENDCASE
ENDPROC


PROCEDURE ExportDbfBasedFile
    LPARAMETERS tcFile, tcSourceRoot, tcOutputRoot

    LOCAL lcRelPath, lcSafeName, lcKind
    LOCAL lcJsonFile, lcMdFile, lcTxtFile
    LOCAL lcAlias, lnFields, laFields[1], lnRecord
    LOCAL lcJson, lcMd, lcTxt

    lcRelPath = RelativePath(tcFile, tcSourceRoot)
    lcSafeName = SafeOutputName(lcRelPath)
    lcKind = DetectKind(tcFile)

    lcJsonFile = tcOutputRoot + "json\" + lcSafeName + ".json"
    lcMdFile   = tcOutputRoot + "md\"   + lcSafeName + ".md"
    lcTxtFile  = tcOutputRoot + "txt\"  + lcSafeName + ".txt"

    ? "Exportando: " + lcRelPath

    lcAlias = "src_" + SYS(2015)

    TRY
        USE (tcFile) ALIAS (lcAlias) IN 0 SHARED AGAIN
    CATCH TO loEx
        DO LogError WITH "No se pudo abrir " + tcFile + ": " + loEx.Message
        STRTOFILE("ERROR abriendo archivo: " + tcFile + CRLF() + loEx.Message + CRLF(), lcTxtFile)
        RETURN
    ENDTRY

    SELECT (lcAlias)
    lnFields = AFIELDS(laFields)

    lcJson = "{" + CRLF()
    lcJson = lcJson + '  "file": ' + JsonValue(lcRelPath) + "," + CRLF()
    lcJson = lcJson + '  "kind": ' + JsonValue(lcKind) + "," + CRLF()
    lcJson = lcJson + '  "records": [' + CRLF()

    lcMd = "# " + lcRelPath + CRLF() + CRLF()
    lcMd = lcMd + "- Tipo: `" + lcKind + "`" + CRLF()
    lcMd = lcMd + "- Archivo original: `" + tcFile + "`" + CRLF()
    lcMd = lcMd + "- Registros: `" + TRANSFORM(RECCOUNT()) + "`" + CRLF() + CRLF()

    lcTxt = "FILE: " + lcRelPath + CRLF()
    lcTxt = lcTxt + "KIND: " + lcKind + CRLF()
    lcTxt = lcTxt + "RECORDS: " + TRANSFORM(RECCOUNT()) + CRLF()
    lcTxt = lcTxt + REPLICATE("=", 100) + CRLF()

    lnRecord = 0

    SCAN
        lnRecord = lnRecord + 1

        IF lnRecord > 1
            lcJson = lcJson + "," + CRLF()
        ENDIF

        lcJson = lcJson + "    {" + CRLF()
        lcJson = lcJson + '      "_recno": ' + TRANSFORM(RECNO())

        lcMd = lcMd + "## Registro " + TRANSFORM(RECNO()) + CRLF() + CRLF()
        lcTxt = lcTxt + "REGISTRO: " + TRANSFORM(RECNO()) + CRLF()

        DO ExportCurrentRecordFields WITH lcAlias, laFields, lnFields, lcJson, lcMd, lcTxt

        lcJson = lcJson + CRLF() + "    }"
        lcMd = lcMd + CRLF() + "---" + CRLF() + CRLF()
        lcTxt = lcTxt + REPLICATE("-", 100) + CRLF()
    ENDSCAN

    lcJson = lcJson + CRLF() + "  ]" + CRLF() + "}" + CRLF()

    USE IN (lcAlias)

    STRTOFILE(lcJson, lcJsonFile)
    STRTOFILE(lcMd, lcMdFile)
    STRTOFILE(lcTxt, lcTxtFile)
ENDPROC


PROCEDURE ExportCurrentRecordFields
    LPARAMETERS tcAlias, taFields, tnFields, tcJson, tcMd, tcTxt

    LOCAL i, lcField, luValue, lcType, lcTextValue

    SELECT (tcAlias)

    FOR i = 1 TO tnFields
        lcField = LOWER(taFields[i, 1])

        TRY
            luValue = EVALUATE(lcField)
            lcType = VARTYPE(luValue)
            lcTextValue = ValueToText(luValue, lcType)
        CATCH TO loEx
            lcType = "U"
            lcTextValue = "[UNREADABLE FIELD: " + loEx.Message + "]"
        ENDTRY

        tcJson = tcJson + "," + CRLF()
        tcJson = tcJson + "      " + JsonValue(lcField) + ": " + JsonValue(lcTextValue)

        IF NOT EMPTY(ALLTRIM(lcTextValue))
            tcMd = tcMd + "### " + lcField + CRLF() + CRLF()
            tcMd = tcMd + "```text" + CRLF()
            tcMd = tcMd + lcTextValue + CRLF()
            tcMd = tcMd + "```" + CRLF() + CRLF()
        ENDIF

        tcTxt = tcTxt + UPPER(lcField) + ":" + CRLF()
        tcTxt = tcTxt + lcTextValue + CRLF() + CRLF()
    ENDFOR
ENDPROC


PROCEDURE ExportTextFile
    LPARAMETERS tcFile, tcSourceRoot, tcOutputRoot

    LOCAL lcRelPath, lcSafeName, lcOutFile, lcMdFile, lcJsonFile
    LOCAL lcContent, lcKind

    lcRelPath = RelativePath(tcFile, tcSourceRoot)
    lcSafeName = SafeOutputName(lcRelPath)
    lcKind = DetectKind(tcFile)

    lcOutFile = tcOutputRoot + "txt\" + lcSafeName + ".txt"
    lcMdFile = tcOutputRoot + "md\" + lcSafeName + ".md"
    lcJsonFile = tcOutputRoot + "json\" + lcSafeName + ".json"

    ? "Copiando texto: " + lcRelPath

    TRY
        lcContent = FILETOSTR(tcFile)
    CATCH TO loEx
        DO LogError WITH "No se pudo leer texto " + tcFile + ": " + loEx.Message
        STRTOFILE("ERROR leyendo archivo: " + tcFile + CRLF() + loEx.Message + CRLF(), lcOutFile)
        RETURN
    ENDTRY

    STRTOFILE(lcContent, lcOutFile)

    STRTOFILE("# " + lcRelPath + CRLF() + CRLF() + ;
        "- Tipo: `" + lcKind + "`" + CRLF() + ;
        "- Archivo original: `" + tcFile + "`" + CRLF() + CRLF() + ;
        "```foxpro" + CRLF() + lcContent + CRLF() + "```" + CRLF(), lcMdFile)

    STRTOFILE("{" + CRLF() + ;
        '  "file": ' + JsonValue(lcRelPath) + "," + CRLF() + ;
        '  "kind": ' + JsonValue(lcKind) + "," + CRLF() + ;
        '  "content": ' + JsonValue(lcContent) + CRLF() + ;
        "}" + CRLF(), lcJsonFile)
ENDPROC


FUNCTION DetectKind
    LPARAMETERS tcFile

    LOCAL lcExt
    lcExt = LOWER(JUSTEXT(tcFile))

    DO CASE
    CASE lcExt == "scx"
        RETURN "form"
    CASE lcExt == "vcx"
        RETURN "classlib"
    CASE lcExt == "frx"
        RETURN "report"
    CASE lcExt == "mnx"
        RETURN "menu"
    CASE lcExt == "prg"
        RETURN "program"
    CASE lcExt == "h"
        RETURN "header"
    CASE lcExt == "ini"
        RETURN "config"
    CASE lcExt == "txt"
        RETURN "text"
    OTHERWISE
        RETURN "unknown"
    ENDCASE
ENDFUNC


FUNCTION RelativePath
    LPARAMETERS tcFile, tcSourceRoot

    LOCAL lcFile, lcRoot
    lcFile = FULLPATH(tcFile)
    lcRoot = FULLPATH(ADDBS(tcSourceRoot))

    IF UPPER(LEFT(lcFile, LEN(lcRoot))) == UPPER(lcRoot)
        RETURN SUBSTR(lcFile, LEN(lcRoot) + 1)
    ENDIF

    RETURN lcFile
ENDFUNC


FUNCTION SafeOutputName
    LPARAMETERS tcRelPath

    LOCAL lcName
    lcName = tcRelPath
    lcName = STRTRAN(lcName, "\", "__")
    lcName = STRTRAN(lcName, "/", "__")
    lcName = STRTRAN(lcName, ":", "_")
    lcName = STRTRAN(lcName, " ", "_")
    RETURN lcName
ENDFUNC


FUNCTION IsSameOrChildPath
    LPARAMETERS tcCandidate, tcParent

    LOCAL lcCandidate, lcParent
    lcCandidate = UPPER(FULLPATH(ADDBS(tcCandidate)))
    lcParent = UPPER(FULLPATH(ADDBS(tcParent)))

    RETURN LEFT(lcCandidate, LEN(lcParent)) == lcParent
ENDFUNC


FUNCTION ValueToText
    LPARAMETERS tuValue, tcType

    DO CASE
    CASE ISNULL(tuValue)
        RETURN ""

    CASE tcType == "C" OR tcType == "M"
        RETURN tuValue

    CASE INLIST(tcType, "N", "I", "B", "F", "Y")
        RETURN TRANSFORM(tuValue)

    CASE tcType == "D"
        IF EMPTY(tuValue)
            RETURN ""
        ENDIF
        RETURN DTOC(tuValue)

    CASE tcType == "T"
        IF EMPTY(tuValue)
            RETURN ""
        ENDIF
        RETURN TTOC(tuValue, 1)

    CASE tcType == "L"
        RETURN IIF(tuValue, ".T.", ".F.")

    CASE tcType == "G"
        RETURN "[GENERAL/BINARY FIELD OMITIDO]"

    CASE tcType == "U"
        RETURN "[UNREADABLE FIELD]"

    OTHERWISE
        RETURN TRANSFORM(tuValue)
    ENDCASE
ENDFUNC


FUNCTION JsonValue
    LPARAMETERS tcValue

    LOCAL lcValue

    IF ISNULL(tcValue)
        RETURN "null"
    ENDIF

    lcValue = TRANSFORM(tcValue)
    lcValue = STRTRAN(lcValue, "\", "\\")
    lcValue = STRTRAN(lcValue, '"', '\"')
    lcValue = STRTRAN(lcValue, CHR(13) + CHR(10), "\n")
    lcValue = STRTRAN(lcValue, CHR(13), "\n")
    lcValue = STRTRAN(lcValue, CHR(10), "\n")
    lcValue = STRTRAN(lcValue, CHR(9), "\t")

    RETURN '"' + lcValue + '"'
ENDFUNC


PROCEDURE EnsureDir
    LPARAMETERS tcDir

    IF NOT DIRECTORY(tcDir)
        MD (tcDir)
    ENDIF
ENDPROC


PROCEDURE LogError
    LPARAMETERS tcMessage

    IF TYPE("pcLogFile") == "C" AND NOT EMPTY(pcLogFile)
        STRTOFILE(TTOC(DATETIME(), 1) + " - " + tcMessage + CRLF(), pcLogFile, 1)
    ENDIF
ENDPROC


FUNCTION CRLF
    RETURN CHR(13) + CHR(10)
ENDFUNC
