USING com.totvs.framework.api.*.
USING Progress.Lang.AppError FROM PROPATH.

{utp/ut-api.i}

{utp/ut-api-action.i piGet    GET /~* }
{utp/ut-api-action.i piPost   POST / }
{utp/ut-api-action.i piDelete DELETE /~* }
{utp/ut-api-action.i piPut    PUT /~* }
{utp/ut-api-action.i piPatch  PATCH /~* }

{utp/ut-api-notfound.i}


DEFINE TEMP-TABLE ttCustomer NO-UNDO LIKE customer.

/* ****************************  Functions  *************************** */
FUNCTION getFormatedAtribValue RETURNS CHARACTER (ipName AS CHARACTER, ipValue AS CHARACTER):
    CASE ipName:
        WHEN 'Credit-Limit' OR WHEN 'Balance' OR WHEN 'Discount' THEN
            RETURN ipValue.
        OTHERWISE
            RETURN '"' + ipValue + '"'.
    END CASE.
END FUNCTION.


PROCEDURE piGet:
    DEFINE INPUT  PARAMETER jsonInput  AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAMETER jsonOutput AS JsonObject NO-UNDO.

    DEFINE VARIABLE qCustomer      AS HANDLE               NO-UNDO.
    DEFINE VARIABLE bCustomer      AS HANDLE               NO-UNDO.
    DEFINE VARIABLE bttCustomer    AS HANDLE               NO-UNDO.
    DEFINE VARIABLE cQuery         AS CHARACTER            NO-UNDO.
    DEFINE VARIABLE i              AS INTEGER              NO-UNDO.
    DEFINE VARIABLE iPage          AS INTEGER              NO-UNDO INITIAL 1.
    DEFINE VARIABLE iPageSize      AS INTEGER              NO-UNDO INITIAL 20.
    DEFINE VARIABLE iInitialRow    AS INTEGER              NO-UNDO.
    DEFINE VARIABLE cOrder         AS CHARACTER            NO-UNDO.
    DEFINE VARIABLE cExpand        AS CHARACTER            NO-UNDO.
    DEFINE VARIABLE cFields        AS CHARACTER            NO-UNDO.
    DEFINE VARIABLE oQueryParams   AS jsonObject           NO-UNDO.
    DEFINE VARIABLE cNames         AS CHARACTER            NO-UNDO EXTENT.
    DEFINE VARIABLE aItems         AS jsonArray            NO-UNDO.
    DEFINE VARIABLE oRequestParser AS JsonAPIRequestParser NO-UNDO.
    DEFINE VARIABLE iCustNum       AS INTEGER              NO-UNDO INITIAL 0.

    ASSIGN oRequestParser = NEW JsonAPIRequestParser(jsonInput)
           iPage          = oRequestParser:getPage()
           iPageSize      = oRequestParser:getPageSize()
           cOrder         = STRING(oRequestParser:getOrder())
           cExpand        = STRING(oRequestParser:getExpandChar())
           cFields        = STRING(oRequestParser:getFieldsChar())
           iInitialRow    = oRequestParser:getStartRow()
           oQueryParams   = oRequestParser:getQueryParams().

    IF oRequestParser:getPathParams():LENGTH > 0 THEN
        ASSIGN iCustNum = INT(oRequestParser:getPathParams():getCharacter(1)).

    ASSIGN bCustomer      = BUFFER Customer:HANDLE
           bttCustomer    = BUFFER ttCustomer:HANDLE
           cQuery         = 'PRESELECT EACH customer'
           jsonOutput     = NEW JSONObject().

    ASSIGN cNames = oQueryParams:getNames().

    IF iCustNum > 0 THEN
        ASSIGN cQuery = cQuery + ' WHERE customer.cust-num = ' + STRING(iCustNum).

    DO i = 1 TO EXTENT(cNames):
        ASSIGN cQuery = cQuery + (IF INDEX(cQuery, ' WHERE ') = 0 THEN ' WHERE ' ELSE ' AND ') + 'customer.' + cNames[i] + ' = ' + getFormatedAtribValue(cNames[i],oQueryParams:getJsonArray(cNames[i]):getCharacter(1)).
    END.

    CREATE QUERY qCustomer.

    qCustomer:SET-BUFFERS(bCustomer).
    qCustomer:QUERY-PREPARE(cQuery).
    IF NOT qCustomer:QUERY-OPEN() THEN
        ASSIGN jsonOutput = JsonAPIResponseBuilder:asError(NEW Progress.Lang.AppError('Erro na pesquisa de Customer. Verifique os parametros da requisiá∆o',4), 400).

    IF iInitialRow > 1 AND iCustNum = 0 THEN
        qCustomer:REPOSITION-TO-ROW(iInitialRow).

    DO i = 1 TO iPageSize:
        qCustomer:GET-NEXT(NO-LOCK).
        IF qCustomer:QUERY-OFF-END THEN LEAVE.
        bttCustomer:BUFFER-CREATE().
        bttCustomer:BUFFER-COPY(bCustomer).
    END.

    ASSIGN aItems = NEW JsonArray().
    aItems:READ(TEMP-TABLE ttCustomer:HANDLE).

    IF iCustNum > 0 THEN
        ASSIGN jsonOutput = JsonAPIResponseBuilder:ok(aItems:getJsonObject(1), 200).

    ELSE
        ASSIGN jsonOutput = JsonAPIResponseBuilder:ok(aItems, qCustomer:GET-NEXT(NO-LOCK)).

END PROCEDURE.

PROCEDURE piPost:
    DEFINE INPUT  PARAMETER jsonInput  AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAMETER jsonOutput AS JsonObject NO-UNDO.

    DEFINE VARIABLE oCustomer      AS JsonObject           NO-UNDO.
    DEFINE VARIABLE oRequestParser AS JsonAPIRequestParser NO-UNDO.

    ASSIGN oRequestParser = NEW JsonAPIRequestParser(jsonInput)
           jsonOutput     = NEW JsonObject()
           oCustomer      = oRequestParser:getPayload().

    DO ON ERROR UNDO, LEAVE:
        CREATE customer.
        ASSIGN customer.terms        = oCustomer:getCharacter('Terms')
               customer.state        = oCustomer:getCharacter('State')
               customer.sales-rep    = oCustomer:getCharacter('Sales-Rep')
               customer.postal-Code  = oCustomer:getCharacter('Postal-Code')
               customer.phone        = oCustomer:getCharacter('Phone')
               customer.NAME         = oCustomer:getCharacter('Name')
               customer.discount     = oCustomer:getInteger('Discount')
               customer.credit-Limit = oCustomer:getDecimal('Credit-Limit')
               customer.country      = oCustomer:getCharacter('Country')
               customer.contact      = oCustomer:getCharacter('Contact')
               customer.comments     = oCustomer:getCharacter('Comments')
               customer.city         = oCustomer:getCharacter('City')
               customer.balance      = oCustomer:getDecimal('Balance')
               customer.address2     = oCustomer:getCharacter('Address2')
               customer.address      = oCustomer:getCharacter('Address') NO-ERROR.
    END.

    IF NOT ERROR-STATUS:ERROR THEN DO:
        oCustomer:ADD('Cust-Num',customer.cust-num).
        ASSIGN jsonOutput = JsonAPIResponseBuilder:ok(oCustomer, 201).
    END.
    ELSE
        ASSIGN jsonOutput = JsonAPIResponseBuilder:asError(NEW Progress.Lang.AppError('Erro na inclus∆o de Customer',1), 400).

END PROCEDURE.

PROCEDURE piDelete:
    DEFINE INPUT  PARAMETER jsonInput  AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAMETER jsonOutput AS JsonObject NO-UNDO.

    DEFINE VARIABLE iCustNum       AS INTEGER              NO-UNDO.
    DEFINE VARIABLE canDelete      AS LOGICAL              NO-UNDO.
    DEFINE VARIABLE errorMsg       AS CHARACTER            NO-UNDO.
    DEFINE VARIABLE oRequestParser AS JsonAPIRequestParser NO-UNDO.

    ASSIGN oRequestParser = NEW JsonAPIRequestParser(jsonInput)
           jsonOutput     = NEW JsonObject()
           iCustNum       = INT(oRequestParser:getPathParams():getcharacter(1))
           errorMsg       = 'N∆o foi poss°vel excluir o Customer. '.

    FIND FIRST customer EXCLUSIVE-LOCK
         WHERE customer.cust-num = iCustNum NO-ERROR NO-WAIT.
    IF AVAIL customer THEN DO:
        canDelete = NOT CAN-FIND (FIRST order OF customer).
        IF canDelete THEN
            DELETE customer.
        ELSE 
            ASSIGN errorMsg = errorMsg + 'Existe um Order relacionado a este Customer.'.
    END.
    ELSE
        ASSIGN errorMsg = errorMsg + IF LOCKED customer THEN 'O registro est† em uso.' ELSE 'O registro n∆o foi encontrado.'.
    
    IF NOT canDelete THEN
        ASSIGN jsonOutput = JsonAPIResponseBuilder:asError(NEW Progress.Lang.AppError(errorMsg,3), 400).
END. 

PROCEDURE piPut:
    DEFINE INPUT  PARAMETER jsonInput  AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAMETER jsonOutput AS JsonObject NO-UNDO.

    DEFINE VARIABLE iCustNum           AS INTEGER              NO-UNDO.
    DEFINE VARIABLE oCustomer          AS JsonObject           NO-UNDO.
    DEFINE VARIABLE lcResponsePayload  AS LONGCHAR             NO-UNDO.
    DEFINE VARIABLE oParser            AS ObjectModelParser    NO-UNDO.
    DEFINE VARIABLE oRequestParser     AS JsonAPIRequestParser NO-UNDO.

    ASSIGN oRequestParser = NEW JsonAPIRequestParser(jsonInput)
           jsonOutput     = NEW JsonObject()
           iCustNum       = INT(oRequestParser:getPathParams():getcharacter(1))
           oCustomer      = oRequestParser:getPayload().

    FIND FIRST customer EXCLUSIVE-LOCK
         WHERE customer.cust-num = iCustNum NO-ERROR.
    IF AVAIL customer THEN DO:
        DO ON ERROR UNDO, LEAVE:
            ASSIGN customer.terms = IF oCustomer:has('Terms') THEN oCustomer:getCharacter('Terms') ELSE customer.terms
                   customer.state = IF oCustomer:has('State') THEN oCustomer:getCharacter('State') ELSE customer.state
                   customer.sales-rep = IF oCustomer:has('Sales-Rep') THEN oCustomer:getCharacter('Sales-Rep') ELSE customer.sales-rep
                   customer.postal-Code = IF oCustomer:has('Postal-Code') THEN oCustomer:getCharacter('Postal-Code') ELSE customer.postal-Code
                   customer.phone = IF oCustomer:has('Phone') THEN oCustomer:getCharacter('Phone') ELSE customer.phone
                   customer.NAME = IF oCustomer:has('Name') THEN oCustomer:getCharacter('Name') ELSE customer.NAME
                   customer.discount = IF oCustomer:has('Discount') THEN oCustomer:getInteger('Discount') ELSE customer.discount
                   customer.credit-limit = IF oCustomer:has('Credit-Limit') THEN oCustomer:getDecimal('Credit-Limit') ELSE customer.credit-limit
                   customer.country = IF oCustomer:has('Country') THEN oCustomer:getCharacter('Country') ELSE customer.country
                   customer.contact = IF oCustomer:has('Contact') THEN oCustomer:getCharacter('Contact') ELSE customer.contact
                   customer.comments = IF oCustomer:has('Comments') THEN oCustomer:getCharacter('Comments') ELSE customer.comments
                   customer.city = IF oCustomer:has('City') THEN oCustomer:getCharacter('City') ELSE customer.city
                   customer.balance = IF oCustomer:has('Balance') THEN oCustomer:getDecimal('Balance') ELSE customer.balance
                   customer.address2 = IF oCustomer:has('Address2') THEN  oCustomer:getCharacter('Address2') ELSE customer.address2
                   customer.address = IF oCustomer:has('Address') THEN oCustomer:getCharacter('Address') ELSE customer.address NO-ERROR.
            CREATE ttCustomer.
            BUFFER-COPY customer TO ttCustomer.
        END.
    END.

    IF NOT ERROR-STATUS:ERROR AND AVAIL customer THEN DO:
        BUFFER ttCustomer:HANDLE:SERIALIZE-ROW('json','longchar',lcResponsePayload,?,?,?,TRUE).
        ASSIGN oParser    = NEW ObjectModelParser()
               jsonOutput = JsonAPIResponseBuilder:ok(CAST(oParser:Parse(lcResponsePayload),'jsonobject'), 200).
    END.
    ELSE
        ASSIGN jsonOutput = JsonAPIResponseBuilder:asError(NEW Progress.Lang.AppError('Erro na alteraá∆o de Customer',2), 400).

END.

PROCEDURE piPatch:
    DEFINE INPUT  PARAMETER jsonInput  AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAMETER jsonOutput AS JsonObject NO-UNDO.

    DEFINE VARIABLE iCustNum           AS INTEGER              NO-UNDO.
    DEFINE VARIABLE oCustomer          AS JsonArray            NO-UNDO.
    DEFINE VARIABLE cOperation         AS CHARACTER            NO-UNDO.
    DEFINE VARIABLE cPath              AS CHARACTER            NO-UNDO.
    DEFINE VARIABLE cValue             AS CHARACTER            NO-UNDO.
    DEFINE VARIABLE qCustomer          AS HANDLE               NO-UNDO.
    DEFINE VARIABLE bCustomer          AS HANDLE               NO-UNDO.
    DEFINE VARIABLE bttCustomer        AS HANDLE               NO-UNDO.
    DEFINE VARIABLE lcResponsePayload  AS LONGCHAR             NO-UNDO.
    DEFINE VARIABLE oParser            AS ObjectModelParser    NO-UNDO.

    DEFINE BUFFER bttCustomer FOR ttCustomer.

    /* n∆o usuei o JsonAPIRequestParser porque ele n∆o preve um payload do tipo array */
    ASSIGN oCustomer  = jsonInput:getJsonArray('payload')
           iCustNum   = INT(jsonInput:getJsonArray('pathParams'):getcharacter(1))
           jsonOutput = NEW JsonObject().
                                             
    ASSIGN cOperation = oCustomer:getJsonObject(1):getCharacter('op')
           cPath      = oCustomer:getJsonObject(1):getCharacter('path')
           cValue     = oCustomer:getJsonObject(1):getCharacter('value').

    EMPTY TEMP-TABLE ttCustomer.
    
    ASSIGN bCustomer      = BUFFER Customer:HANDLE
           bttCustomer    = BUFFER ttCustomer:HANDLE.

    CREATE QUERY qCustomer.

    qCustomer:SET-BUFFERS(bCustomer).
    qCustomer:QUERY-PREPARE('FOR EACH customer WHERE customer.cust-num = ' + STRING(iCustNum)).
    IF NOT qCustomer:QUERY-OPEN() THEN
        ASSIGN jsonOutput = JsonAPIResponseBuilder:asError(NEW Progress.Lang.AppError('Erro na pesquisa de Customer. Verifique os parametros da requisiá∆o',4), 400).

    DO TRANSACTION:
        qCustomer:GET-FIRST(EXCLUSIVE-LOCK).
        IF bCustomer:BUFFER-FIELD(cPath):DATA-TYPE = 'INTEGER' THEN
            ASSIGN bCustomer:BUFFER-FIELD(cPath):BUFFER-VALUE = INT(cValue) NO-ERROR.
        ELSE
            IF bCustomer:BUFFER-FIELD(cPath):DATA-TYPE = 'LOGICAL' THEN
                ASSIGN bCustomer:BUFFER-FIELD(cPath):BUFFER-VALUE = LOGICAL(cValue) NO-ERROR.
        ELSE 
            ASSIGN bCustomer:BUFFER-FIELD(cPath):BUFFER-VALUE = cValue NO-ERROR.
        bttCustomer:BUFFER-CREATE().
        bttCustomer:BUFFER-COPY(bCustomer).
    END.
    
    IF NOT ERROR-STATUS:ERROR AND AVAIL customer THEN DO:
        bttCustomer:HANDLE:SERIALIZE-ROW('json','longchar',lcResponsePayload,?,?,?,TRUE).
        ASSIGN oParser    = NEW ObjectModelParser()
               jsonOutput = JsonAPIResponseBuilder:ok(CAST(oParser:Parse(lcResponsePayload),'jsonobject'), 200).
    END.
    ELSE
        ASSIGN jsonOutput = JsonAPIResponseBuilder:asError(NEW Progress.Lang.AppError('Erro na alteraá∆o de Customer',2), 400).

END PROCEDURE.
