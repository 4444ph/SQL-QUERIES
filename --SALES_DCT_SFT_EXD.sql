--SALES_DCT_SFT_EXD

SELECT 
    -- 1. IDENTIFY THE PATH
    T0.CardName                                AS [ClientName],
    COALESCE(SRC.Name, T1.U_Source)            AS [SourceName],
    COALESCE(DEST.Name, T1.U_Destination)      AS [DestinationName],
    i.ItemName                                 AS [CementBrand],
    CT.Name                                    AS [CementType],
    
    -- 2. DELIVERY CLASSIFICATION 
    CASE 
        -- Added priority catch so they do not default to 'Others'
        WHEN O.U_TranType IN ('SFT','DCT','EXD') THEN 'Priority - ' + O.U_TranType
        
        -- Existing Logic
        WHEN O.U_TranType IN ('SOC','SOCH','FTH') 
             AND COALESCE(SRC.U_DeliveryType, T1.U_DeliveryType) = 'BULK'   THEN 'Trading - Bulk'
        WHEN O.U_TranType IN ('SOC','SOCH','FTH') 
             AND COALESCE(SRC.U_DeliveryType, T1.U_DeliveryType) = 'BAGGED' THEN 'Trading - FB'
        WHEN O.U_TranType IN ('SPT','SOTC','CIF','SOHH') 
             AND COALESCE(SRC.U_DeliveryType, T1.U_DeliveryType) = 'BULK'   THEN 'Hauling - Bulk'
        WHEN O.U_TranType IN ('SPT','SOTC','CIF','SOHH')                    THEN 'Hauling - FB'
        WHEN O.U_TranType IN ('RVC','SOHH')                                 THEN 'Republic'
        WHEN O.U_TranType IN ('PLD','MOB')                                  THEN 'Preload'
        ELSE 'Others'
    END                                        AS [DeliveryGroup],

    -- 3. TRANSACTION DATA 
    T0.DocNum                                  AS [DeliveryNo],
    CAST(T0.DocDate AS DATE)                   AS [DeliveryDate],
    CAST(T1.U_QTYCustDelivered AS DECIMAL(10,2)) AS [QtyDelivered],
    CAST(T1.U_QTYDelivered AS DECIMAL(10,2))     AS [QtyWithdrawn],
    
    -- 4. AGING
    DATEDIFF(DAY, T0.DocDate, GETDATE())       AS [DaysSinceDelivery],

    -- 5. ORDER INFO 
    O.U_SORefNo                                AS [OENumber],
    O.DocNum                                   AS [ORDRDocNum],
    CAST(O.CreateDate AS DATE)                 AS [SOCreateDate],
    CAST(O.DocDate AS DATE)                    AS [SODocDate]

FROM dbo.ODLN T0
INNER JOIN dbo.DLN1 T1 ON T0.DocEntry = T1.DocEntry
INNER JOIN dbo.OITM i  ON i.ItemCode = T1.ItemCode

-- Linking back to Sales Order
LEFT JOIN dbo.RDR1 R   ON R.DocEntry = T1.BaseEntry AND R.LineNum = T1.BaseLine AND T1.BaseType = 17
LEFT JOIN dbo.ORDR O   ON O.DocEntry = R.DocEntry

-- Joins for User-Defined Tables
LEFT JOIN dbo.[@SOURCE] SRC       ON SRC.Code  = T1.U_Source
LEFT JOIN dbo.[@DESTINATION] DEST ON DEST.Code = T1.U_Destination
LEFT JOIN dbo.[@CEMENTTYPE] CT    ON CT.Code   = O.U_CementType

WHERE 
    T0.Canceled = 'N' 
    AND T0.DocDate >= '2025-01-01'
    AND T0.U_CompanyCategory = 'Business'
    -- Strict Filter applied here:
    AND O.U_TranType IN ('SFT','DCT','EXD')

-- Sorts the target types to the very top if you eventually decide to remove the WHERE filter
ORDER BY 
    CASE WHEN O.U_TranType IN ('SFT','DCT','EXD') THEN 1 ELSE 2 END ASC,
    T0.DocDate DESC;