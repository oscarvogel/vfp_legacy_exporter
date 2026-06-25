* generate_indexes.prg
* Genera indices Markdown a partir de una carpeta exportada por export_legacy.prg.
*
* Uso:
* DO src\generate_indexes.prg WITH "D:\VFP_EXPORTS\COPIA_SISTEMA_VFP"
*
* Entrada esperada:
* - Carpeta exportada con subcarpeta md\ generada por export_legacy.prg.
*
* Salida:
* - index\INDICE_FORMULARIOS.md
* - index\INDICE_CLASES.md
* - index\INDICE_REPORTES.md
* - index\INDICE_MENUS.md
* - index\INDICE_PROGRAMAS.md
* - index\INDICE_GENERAL.md

LPARAMETERS tcExportRoot

SET SAFETY OFF
SET TALK OFF

PRIVATE pcIndexRoot

IF EMPTY(tcExportRoot)
    ? "Debe indicar carpeta exportada."
    RETURN .F.
ENDIF

tcExportRoot = FULLPATH(ADDBS(tcExportRoot))

IF NOT DIRECTORY(tcExportRoot)
    ? "No existe la carpeta exportada: " + tcExportRoot
    RETURN .F.
ENDIF

IF NOT DIRECTORY(tcExportRoot + "md")
    ? "No existe la carpeta md dentro de la exportacion: " + tcExportRoot + "md"
    RETURN .F.
ENDIF

pcIndexRoot = tcExportRoot + "index\"
DO EnsureDir WITH pcIndexRoot

DO InitIndexFiles WITH pcIndexRoot
DO ScanExportedMarkdown WITH tcExportRoot + "md\", tcExportRoot
DO WriteGeneralIndex WITH pcIndexRoot

? "Indices generados en: " + pcIndexRoot
RETURN .T.


PROCEDURE InitIndexFiles
    LPARAMETERS tcIndexRoot

    STRTOFILE("# Indice de formularios" + CRLF() + CRLF() + "| Archivo | Registros | Objetos | Metodos | Clases base |" + CRLF() + "|---|---:|---|---|---|" + CRLF(), tcIndexRoot + "INDICE_FORMULARIOS.md")
    STRTOFILE("# Indice de clases" + CRLF() + CRLF() + "| Archivo | Registros | Objetos | Metodos | Clases base |" + CRLF() + "|---|---:|---|---|---|" + CRLF(), tcIndexRoot + "INDICE_CLASES.md")
    STRTOFILE("# Indice de reportes" + CRLF() + CRLF() + "| Archivo | Registros | Objetos | Metodos | Clases base |" + CRLF() + "|---|---:|---|---|---|" + CRLF(), tcIndexRoot + "INDICE_REPORTES.md")
    STRTOFILE("# Indice de menus" + CRLF() + CRLF() + "| Archivo | Registros | Objetos | Metodos | Clases base |" + CRLF() + "|---|---:|---|---|---|" + CRLF(), tcIndexRoot + "INDICE_MENUS.md")
    STRTOFILE("# Indice de programas" + CRLF() + CRLF() + "| Archivo | Lineas aprox. | Observaciones |" + CRLF() + "|---|---:|---|" + CRLF(), tcIndexRoot + "INDICE_PROGRAMAS.md")
ENDPROC


PROCEDURE ScanExportedMarkdown
    LPARAMETERS tcMdRoot, tcExportRoot

    LOCAL laFiles[1], laDirs[1]
    LOCAL lnFiles, lnDirs, i
    LOCAL lcName, lcFullPath

    lnFiles = ADIR(laFiles, ADDBS(tcMdRoot) + "*.md")

    FOR i = 1 TO lnFiles
        lcName = laFiles[i, 1]
        lcFullPath = ADDBS(tcMdRoot) + lcName

        IF NOT DIRECTORY(lcFullPath)
            DO IndexMarkdownFile WITH lcFullPath, tcExportRoot
        ENDIF
    ENDFOR

    lnDirs = ADIR(laDirs, ADDBS(tcMdRoot) + "*.*", "D")

    FOR i = 1 TO lnDirs
        lcName = laDirs[i, 1]

        IF lcName == "." OR lcName == ".."
            LOOP
        ENDIF

        lcFullPath = ADDBS(tcMdRoot) + lcName

        IF DIRECTORY(lcFullPath)
            DO ScanExportedMarkdown WITH lcFullPath, tcExportRoot
        ENDIF
    ENDFOR
ENDPROC


PROCEDURE IndexMarkdownFile
    LPARAMETERS tcMdFile, tcExportRoot

    LOCAL lcContent, lcKind, lcFileName, lcRecords, lcObjects, lcMethods, lcBaseClasses
    LOCAL lcIndexFile, lcRow, lnLines

    TRY
        lcContent = FILETOSTR(tcMdFile)
    CATCH TO loEx
        RETURN
    ENDTRY

    lcKind = ExtractKind(lcContent)
    lcFileName = ExtractTitle(lcContent)

    IF EMPTY(lcFileName)
        lcFileName = JUSTFNAME(tcMdFile)
    ENDIF

    lcRecords = ExtractMetadataValue(lcContent, "Registros")
    lcObjects = ExtractUniqueValues(lcContent, "objname", 12)
    lcMethods = ExtractMethodNames(lcContent, 12)
    lcBaseClasses = ExtractUniqueValues(lcContent, "baseclass", 10)

    DO CASE
    CASE lcKind == "form"
        lcIndexFile = pcIndexRoot + "INDICE_FORMULARIOS.md"
        lcRow = "| " + EscapeMd(lcFileName) + " | " + IIF(EMPTY(lcRecords), "0", lcRecords) + " | " + EscapeMd(lcObjects) + " | " + EscapeMd(lcMethods) + " | " + EscapeMd(lcBaseClasses) + " |" + CRLF()
        STRTOFILE(lcRow, lcIndexFile, 1)

    CASE lcKind == "classlib"
        lcIndexFile = pcIndexRoot + "INDICE_CLASES.md"
        lcRow = "| " + EscapeMd(lcFileName) + " | " + IIF(EMPTY(lcRecords), "0", lcRecords) + " | " + EscapeMd(lcObjects) + " | " + EscapeMd(lcMethods) + " | " + EscapeMd(lcBaseClasses) + " |" + CRLF()
        STRTOFILE(lcRow, lcIndexFile, 1)

    CASE lcKind == "report"
        lcIndexFile = pcIndexRoot + "INDICE_REPORTES.md"
        lcRow = "| " + EscapeMd(lcFileName) + " | " + IIF(EMPTY(lcRecords), "0", lcRecords) + " | " + EscapeMd(lcObjects) + " | " + EscapeMd(lcMethods) + " | " + EscapeMd(lcBaseClasses) + " |" + CRLF()
        STRTOFILE(lcRow, lcIndexFile, 1)

    CASE lcKind == "menu"
        lcIndexFile = pcIndexRoot + "INDICE_MENUS.md"
        lcRow = "| " + EscapeMd(lcFileName) + " | " + IIF(EMPTY(lcRecords), "0", lcRecords) + " | " + EscapeMd(lcObjects) + " | " + EscapeMd(lcMethods) + " | " + EscapeMd(lcBaseClasses) + " |" + CRLF()
        STRTOFILE(lcRow, lcIndexFile, 1)

    CASE lcKind == "program" OR ".prg." $ LOWER("." + lcFileName + ".")
        lnLines = OCCURS(CHR(10), lcContent) + 1
        lcIndexFile = pcIndexRoot + "INDICE_PROGRAMAS.md"
        lcRow = "| " + EscapeMd(lcFileName) + " | " + TRANSFORM(lnLines) + " | program |" + CRLF()
        STRTOFILE(lcRow, lcIndexFile, 1)
    ENDCASE
ENDPROC


FUNCTION ExtractTitle
    LPARAMETERS tcContent

    LOCAL lnEnd

    IF LEFT(tcContent, 2) == "# "
        lnEnd = AT(CHR(13), tcContent)
        IF lnEnd <= 0
            lnEnd = AT(CHR(10), tcContent)
        ENDIF
        IF lnEnd > 0
            RETURN ALLTRIM(SUBSTR(tcContent, 3, lnEnd - 3))
        ENDIF
    ENDIF

    RETURN ""
ENDFUNC


FUNCTION ExtractKind
    LPARAMETERS tcContent

    LOCAL lcValue
    lcValue = ExtractMetadataValue(tcContent, "Tipo")

    lcValue = STRTRAN(lcValue, "`", "")
    lcValue = LOWER(ALLTRIM(lcValue))

    RETURN lcValue
ENDFUNC


FUNCTION ExtractMetadataValue
    LPARAMETERS tcContent, tcName

    LOCAL lcNeedle, lnPos, lnEnd, lcLine, lnSep

    lcNeedle = "- " + tcName + ":"
    lnPos = ATC(lcNeedle, tcContent)

    IF lnPos <= 0
        RETURN ""
    ENDIF

    lnEnd = AT(CHR(13), SUBSTR(tcContent, lnPos))
    IF lnEnd <= 0
        lnEnd = AT(CHR(10), SUBSTR(tcContent, lnPos))
    ENDIF

    IF lnEnd <= 0
        lcLine = SUBSTR(tcContent, lnPos)
    ELSE
        lcLine = LEFT(SUBSTR(tcContent, lnPos), lnEnd - 1)
    ENDIF

    lnSep = AT(":", lcLine)
    IF lnSep <= 0
        RETURN ""
    ENDIF

    RETURN ALLTRIM(SUBSTR(lcLine, lnSep + 1))
ENDFUNC


FUNCTION ExtractUniqueValues
    LPARAMETERS tcContent, tcFieldName, tnLimit

    LOCAL lcNeedle, lnPos, lnSearchFrom, lcValue, lcResult, lcSeen, lnCount

    lcNeedle = "### " + LOWER(tcFieldName)
    lnSearchFrom = 1
    lcResult = ""
    lcSeen = "|"
    lnCount = 0

    DO WHILE .T.
        lnPos = ATC(lcNeedle, SUBSTR(tcContent, lnSearchFrom))
        IF lnPos <= 0
            EXIT
        ENDIF

        lnPos = lnSearchFrom + lnPos - 1
        lcValue = ExtractCodeBlockAfter(tcContent, lnPos)
        lcValue = FirstNonEmptyLine(lcValue)

        IF NOT EMPTY(lcValue) AND NOT ValueAlreadyListed(lcSeen, lcValue)
            lcResult = lcResult + IIF(EMPTY(lcResult), "", ", ") + lcValue
            lcSeen = lcSeen + NormalizeToken(lcValue) + "|"
            lnCount = lnCount + 1
        ENDIF

        IF lnCount >= tnLimit
            lcResult = lcResult + ", ..."
            EXIT
        ENDIF

        lnSearchFrom = lnPos + LEN(lcNeedle)
    ENDDO

    RETURN lcResult
ENDFUNC


FUNCTION ExtractMethodNames
    LPARAMETERS tcContent, tnLimit

    LOCAL lcNeedle, lnPos, lnSearchFrom, lcBlock, lcName, lcResult, lcSeen, lnCount

    lcNeedle = "### methods"
    lnSearchFrom = 1
    lcResult = ""
    lcSeen = "|"
    lnCount = 0

    DO WHILE .T.
        lnPos = ATC(lcNeedle, SUBSTR(tcContent, lnSearchFrom))
        IF lnPos <= 0
            EXIT
        ENDIF

        lnPos = lnSearchFrom + lnPos - 1
        lcBlock = ExtractCodeBlockAfter(tcContent, lnPos)
        lcName = ExtractProcedureName(lcBlock)

        IF NOT EMPTY(lcName) AND NOT ValueAlreadyListed(lcSeen, lcName)
            lcResult = lcResult + IIF(EMPTY(lcResult), "", ", ") + lcName
            lcSeen = lcSeen + NormalizeToken(lcName) + "|"
            lnCount = lnCount + 1
        ENDIF

        IF lnCount >= tnLimit
            lcResult = lcResult + ", ..."
            EXIT
        ENDIF

        lnSearchFrom = lnPos + LEN(lcNeedle)
    ENDDO

    RETURN lcResult
ENDFUNC


FUNCTION ExtractCodeBlockAfter
    LPARAMETERS tcContent, tnPos

    LOCAL lnFenceStart, lnValueStart, lnFenceEnd, lcTail

    lcTail = SUBSTR(tcContent, tnPos)
    lnFenceStart = AT("```", lcTail)

    IF lnFenceStart <= 0
        RETURN ""
    ENDIF

    lnValueStart = AT(CHR(10), SUBSTR(lcTail, lnFenceStart))
    IF lnValueStart <= 0
        RETURN ""
    ENDIF

    lnValueStart = lnFenceStart + lnValueStart
    lnFenceEnd = AT("```", SUBSTR(lcTail, lnValueStart))

    IF lnFenceEnd <= 0
        RETURN ""
    ENDIF

    RETURN ALLTRIM(LEFT(SUBSTR(lcTail, lnValueStart), lnFenceEnd - 1))
ENDFUNC


FUNCTION FirstNonEmptyLine
    LPARAMETERS tcText

    LOCAL lnI, lcLine, laLines[1], lnLines

    tcText = STRTRAN(tcText, CHR(13), "")
    lnLines = ALINES(laLines, tcText)

    FOR lnI = 1 TO lnLines
        lcLine = ALLTRIM(laLines[lnI])
        IF NOT EMPTY(lcLine)
            RETURN lcLine
        ENDIF
    ENDFOR

    RETURN ""
ENDFUNC


FUNCTION ExtractProcedureName
    LPARAMETERS tcText

    LOCAL lnI, lcLine, laLines[1], lnLines

    tcText = STRTRAN(tcText, CHR(13), "")
    lnLines = ALINES(laLines, tcText)

    FOR lnI = 1 TO lnLines
        lcLine = ALLTRIM(laLines[lnI])
        IF UPPER(LEFT(lcLine, 10)) == "PROCEDURE "
            RETURN ALLTRIM(SUBSTR(lcLine, 11))
        ENDIF
        IF UPPER(LEFT(lcLine, 9)) == "FUNCTION "
            RETURN ALLTRIM(SUBSTR(lcLine, 10))
        ENDIF
    ENDFOR

    RETURN FirstNonEmptyLine(tcText)
ENDFUNC


FUNCTION ValueAlreadyListed
    LPARAMETERS tcSeen, tcValue

    RETURN ("|" + NormalizeToken(tcValue) + "|") $ tcSeen
ENDFUNC


FUNCTION NormalizeToken
    LPARAMETERS tcValue

    LOCAL lcValue
    lcValue = UPPER(ALLTRIM(TRANSFORM(tcValue)))
    lcValue = STRTRAN(lcValue, "|", "/")
    lcValue = STRTRAN(lcValue, CHR(13), " ")
    lcValue = STRTRAN(lcValue, CHR(10), " ")
    RETURN lcValue
ENDFUNC


FUNCTION EscapeMd
    LPARAMETERS tcValue

    LOCAL lcValue
    lcValue = ALLTRIM(TRANSFORM(tcValue))
    lcValue = STRTRAN(lcValue, "|", "/")
    lcValue = STRTRAN(lcValue, CHR(13), " ")
    lcValue = STRTRAN(lcValue, CHR(10), " ")
    RETURN lcValue
ENDFUNC


PROCEDURE WriteGeneralIndex
    LPARAMETERS tcIndexRoot

    LOCAL lcContent

    lcContent = "# Indice general" + CRLF() + CRLF()
    lcContent = lcContent + "- [Formularios](INDICE_FORMULARIOS.md)" + CRLF()
    lcContent = lcContent + "- [Clases](INDICE_CLASES.md)" + CRLF()
    lcContent = lcContent + "- [Reportes](INDICE_REPORTES.md)" + CRLF()
    lcContent = lcContent + "- [Menus](INDICE_MENUS.md)" + CRLF()
    lcContent = lcContent + "- [Programas](INDICE_PROGRAMAS.md)" + CRLF()

    STRTOFILE(lcContent, tcIndexRoot + "INDICE_GENERAL.md")
ENDPROC


PROCEDURE EnsureDir
    LPARAMETERS tcDir

    IF NOT DIRECTORY(tcDir)
        MD (tcDir)
    ENDIF
ENDPROC


FUNCTION CRLF
    RETURN CHR(13) + CHR(10)
ENDFUNC
