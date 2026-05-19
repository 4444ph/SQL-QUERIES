--VW_CementSalesMTDJhontry
--OLD VER
SELECT
    -- Primary Identifiers
    ORDR.DocNum AS [ORDR DocNum],
    ORDR.DocEntry AS [ORDR DocEntry],
    ORDR.CardName AS [Client Name], 
    ORDR.U_SORefNo AS [OE Number],
    ODLN.DocNum AS [Delivery Number],
    ODLN.DocEntry AS [Delivery Entry],

    -- Dates
    ORDR.CreateDate AS [SO Create Date],
    ORDR.DocDate AS [SO Doc Date],
    ODLN.DocDate AS [Date Delivered],

    -- Quantities
    DLN1.U_QTYDelivered AS [Qty Withdrawn],
    DLN1.U_QTYCustDelivered AS [Qty Delivered],

    -- Source / Destination Info
    COALESCE(SRC.Name, SRCRDR1.Name) AS [Source Name],
    COALESCE(DEST.Name, DESTRDR1.Name) AS [Destination Name],

    -- Category / Delivery Type
    COALESCE(SRC.U_Category, SRCRDR1.U_Category) AS [Category],
    COALESCE(SRC.U_DeliveryType, SRCRDR1.U_DeliveryType) AS [Delivery Type],

    -- Business Classification
    CASE 
        WHEN ORDR.U_TranType IN ('SOC', 'SOCH', 'FTH') 
             AND COALESCE(SRC.U_DeliveryType, SRCRDR1.U_DeliveryType) = 'BULK' THEN 'Trading - Bulk'
        WHEN ORDR.U_TranType IN ('SOC', 'SOCH', 'FTH') 
             AND COALESCE(SRC.U_DeliveryType, SRCRDR1.U_DeliveryType) = 'BAGGED' THEN 'Trading - FB'
        WHEN ORDR.U_TranType IN ('SPT', 'SOTC', 'CIF', 'SOHH') 
             AND COALESCE(SRC.U_DeliveryType, SRCRDR1.U_DeliveryType) = 'BULK' THEN 'Hauling - Bulk'
        WHEN ORDR.U_TranType IN ('SPT', 'SOTC', 'CIF', 'SOHH') THEN 'Hauling - FB'
        WHEN ORDR.U_TranType IN ('RVC', 'SOHH') THEN 'Republic'
        WHEN ORDR.U_TranType IN ('PLD', 'MOB') THEN 'Preload'
        ELSE 'Others'
    END AS [Delivery Group]

FROM dbo.ORDR AS ORDR
    -- Source & Destination from Header
    LEFT JOIN dbo.[@SOURCE] AS SRC 
        ON SRC.Code = ORDR.U_Source
    LEFT JOIN dbo.[@DESTINATION] AS DEST 
        ON DEST.Code = ORDR.U_Destination

    -- Item-level Source/Destination
    LEFT JOIN dbo.RDR1 AS RDR1
        ON RDR1.DocEntry = ORDR.DocEntry
    LEFT JOIN dbo.[@SOURCE] AS SRCRDR1
        ON SRCRDR1.Code = RDR1.U_Source
    LEFT JOIN dbo.[@DESTINATION] AS DESTRDR1
        ON DESTRDR1.Code = RDR1.U_Destination

    -- Delivery Links (LEFT JOIN so we still see undelivered SO)
    LEFT JOIN dbo.DLN1 AS DLN1
        ON DLN1.BaseEntry = ORDR.DocEntry
    LEFT JOIN dbo.ODLN AS ODLN
        ON ODLN.DocEntry = DLN1.DocEntry
        AND ODLN.Canceled = 'N'

WHERE
    ORDR.U_CompanyCategory = 'Business'
    AND ORDR.CreateDate >= '2025-01-01';
GO


--SHOW ALL deliveries per SO by removing the ROW_NUMBER() filter and adjusting joins accordingly
-- Grab one source/destination per SO from RDR1 (first line item only)
 WITH RDR1_First AS (
    SELECT
        DocEntry,
        U_Source,
        U_Destination,
        ROW_NUMBER() OVER (PARTITION BY DocEntry ORDER BY LineNum ASC) AS rn
    FROM dbo.RDR1
),

-- Deliveries CTE: Removed ROW_NUMBER() because we want ALL deliveries, not just the top 1
Deliveries AS (
    SELECT
        DLN1.BaseEntry                  AS SO_DocEntry,
        ODLN.DocNum                     AS DeliveryNumber,
        ODLN.DocEntry                   AS DeliveryEntry,
        ODLN.DocDate                    AS DateDelivered,
        DLN1.U_QTYDelivered             AS QtyWithdrawn,
        DLN1.U_QTYCustDelivered         AS QtyDelivered
    FROM dbo.DLN1 AS DLN1
    INNER JOIN dbo.ODLN AS ODLN
        ON ODLN.DocEntry = DLN1.DocEntry
        AND ODLN.Canceled = 'N'
)

SELECT
    ORDR.DocNum                                                 AS [ORDR DocNum],
    ORDR.DocEntry                                               AS [ORDR DocEntry],
    ORDR.CardName                                               AS [Client Name],
    ORDR.U_SORefNo                                              AS [OE Number],
    d.DeliveryNumber                                            AS [Delivery Number],
    d.DeliveryEntry                                             AS [Delivery Entry],
    ORDR.CreateDate                                             AS [SO Create Date],
    ORDR.DocDate                                                AS [SO Doc Date],
    d.DateDelivered                                             AS [Date Delivered],
    d.QtyWithdrawn                                              AS [Qty Withdrawn],
    d.QtyDelivered                                              AS [Qty Delivered],
    COALESCE(SRC.Name,      SRCRDR1.Name)                       AS [Source Name],
    COALESCE(DEST.Name,     DESTRDR1.Name)                      AS [Destination Name],
    COALESCE(SRC.U_Category,      SRCRDR1.U_Category)           AS [Category],
    COALESCE(SRC.U_DeliveryType,  SRCRDR1.U_DeliveryType)       AS [Delivery Type],
    CASE
        WHEN ORDR.U_TranType IN ('SOC','SOCH','FTH')
             AND COALESCE(SRC.U_DeliveryType, SRCRDR1.U_DeliveryType) = 'BULK'   THEN 'Trading - Bulk'
        WHEN ORDR.U_TranType IN ('SOC','SOCH','FTH')
             AND COALESCE(SRC.U_DeliveryType, SRCRDR1.U_DeliveryType) = 'BAGGED' THEN 'Trading - FB'
        WHEN ORDR.U_TranType IN ('SPT','SOTC','CIF','SOHH')
             AND COALESCE(SRC.U_DeliveryType, SRCRDR1.U_DeliveryType) = 'BULK'   THEN 'Hauling - Bulk'
        WHEN ORDR.U_TranType IN ('SPT','SOTC','CIF','SOHH')                      THEN 'Hauling - FB'
        WHEN ORDR.U_TranType IN ('RVC','SOHH')                                   THEN 'Republic'
        WHEN ORDR.U_TranType IN ('PLD','MOB')                                    THEN 'Preload'
        ELSE 'Others'
    END                                                         AS [Delivery Group]

FROM dbo.ORDR AS ORDR

LEFT JOIN dbo.[@SOURCE]      AS SRC      ON SRC.Code  = ORDR.U_Source
LEFT JOIN dbo.[@DESTINATION] AS DEST     ON DEST.Code = ORDR.U_Destination

LEFT JOIN RDR1_First          AS R1       ON R1.DocEntry = ORDR.DocEntry AND R1.rn = 1
LEFT JOIN dbo.[@SOURCE]      AS SRCRDR1  ON SRCRDR1.Code  = R1.U_Source
LEFT JOIN dbo.[@DESTINATION] AS DESTRDR1 ON DESTRDR1.Code = R1.U_Destination

-- CHANGED: Removed the "AND d.rn = 1" to allow all deliveries to branch out
LEFT JOIN Deliveries          AS d        ON d.SO_DocEntry = ORDR.DocEntry

WHERE
    ORDR.U_CompanyCategory = 'Business'
    AND ORDR.CreateDate >= '2025-01-01';
GO




--SHOW TOP 1 delivery per SO by re-introducing ROW_NUMBER() and filtering on it in the final join
-- Grab one source/destination per SO from RDR1 (first line item only)
WITH RDR1_First AS (
    SELECT
        DocEntry,
        U_Source,
        U_Destination,
        ROW_NUMBER() OVER (PARTITION BY DocEntry ORDER BY LineNum ASC) AS rn
    FROM dbo.RDR1
),

-- Flatten DLN1 to one row per Delivery + SO link
Deliveries AS (
    SELECT
        DLN1.BaseEntry                  AS SO_DocEntry,
        ODLN.DocNum                     AS DeliveryNumber,
        ODLN.DocEntry                   AS DeliveryEntry,
        ODLN.DocDate                    AS DateDelivered,
        DLN1.U_QTYDelivered             AS QtyWithdrawn,
        DLN1.U_QTYCustDelivered         AS QtyDelivered,
        ROW_NUMBER() OVER (
            PARTITION BY DLN1.BaseEntry 
            ORDER BY ODLN.DocDate DESC
        )                               AS rn
    FROM dbo.DLN1 AS DLN1
    LEFT JOIN dbo.ODLN AS ODLN
        ON ODLN.DocEntry = DLN1.DocEntry
        AND ODLN.Canceled = 'N'
)

SELECT
    ORDR.DocNum                                                 AS [ORDR DocNum],
    ORDR.DocEntry                                               AS [ORDR DocEntry],
    ORDR.CardName                                               AS [Client Name],
    ORDR.U_SORefNo                                              AS [OE Number],
    d.DeliveryNumber                                            AS [Delivery Number],
    d.DeliveryEntry                                             AS [Delivery Entry],
    ORDR.CreateDate                                             AS [SO Create Date],
    ORDR.DocDate                                                AS [SO Doc Date],
    d.DateDelivered                                             AS [Date Delivered],
    d.QtyWithdrawn                                              AS [Qty Withdrawn],
    d.QtyDelivered                                              AS [Qty Delivered],
    COALESCE(SRC.Name,      SRCRDR1.Name)                       AS [Source Name],
    COALESCE(DEST.Name,     DESTRDR1.Name)                      AS [Destination Name],
    COALESCE(SRC.U_Category,      SRCRDR1.U_Category)           AS [Category],
    COALESCE(SRC.U_DeliveryType,  SRCRDR1.U_DeliveryType)       AS [Delivery Type],
    CASE
        WHEN ORDR.U_TranType IN ('SOC','SOCH','FTH')
             AND COALESCE(SRC.U_DeliveryType, SRCRDR1.U_DeliveryType) = 'BULK'   THEN 'Trading - Bulk'
        WHEN ORDR.U_TranType IN ('SOC','SOCH','FTH')
             AND COALESCE(SRC.U_DeliveryType, SRCRDR1.U_DeliveryType) = 'BAGGED' THEN 'Trading - FB'
        WHEN ORDR.U_TranType IN ('SPT','SOTC','CIF','SOHH')
             AND COALESCE(SRC.U_DeliveryType, SRCRDR1.U_DeliveryType) = 'BULK'   THEN 'Hauling - Bulk'
        WHEN ORDR.U_TranType IN ('SPT','SOTC','CIF','SOHH')                       THEN 'Hauling - FB'
        WHEN ORDR.U_TranType IN ('RVC','SOHH')                                    THEN 'Republic'
        WHEN ORDR.U_TranType IN ('PLD','MOB')                                     THEN 'Preload'
        ELSE 'Others'
    END                                                         AS [Delivery Group]

FROM dbo.ORDR AS ORDR

LEFT JOIN dbo.[@SOURCE]      AS SRC      ON SRC.Code  = ORDR.U_Source
LEFT JOIN dbo.[@DESTINATION] AS DEST     ON DEST.Code = ORDR.U_Destination

LEFT JOIN RDR1_First          AS R1      ON R1.DocEntry = ORDR.DocEntry AND R1.rn = 1
LEFT JOIN dbo.[@SOURCE]      AS SRCRDR1  ON SRCRDR1.Code  = R1.U_Source
LEFT JOIN dbo.[@DESTINATION] AS DESTRDR1 ON DESTRDR1.Code = R1.U_Destination

LEFT JOIN Deliveries          AS d       ON d.SO_DocEntry = ORDR.DocEntry AND d.rn = 1

WHERE
    ORDR.U_CompanyCategory = 'Business'
    AND ORDR.CreateDate >= '2025-01-01'

GO




--NEW UNGROUPED

SELECT
    -- 1. IDENTIFY THE PATH
    T0.CardName                                AS [Client Name],
    COALESCE(SRC.Name, T1.U_Source)            AS [Source Name],
    COALESCE(DEST.Name, T1.U_Destination)      AS [Destination Name],
    i.ItemName                                 AS [Cement Brand],
    CT.Name                                    AS [Cement Type],
    
    -- 2. DELIVERY CLASSIFICATION (Specific to this row)
    CASE
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
    END                                        AS [Delivery Group],

    -- 3. TRANSACTION DATA (No longer grouped)
    T0.DocNum                                  AS [Delivery No],
    CAST(T0.DocDate AS DATE)                   AS [Delivery Date],
    CAST(T1.U_QTYCustDelivered AS DECIMAL(10,2)) AS [Qty Delivered],
    CAST(T1.U_QTYDelivered AS DECIMAL(10,2))     AS [Qty Withdrawn],
    
    -- 4. AGING
    DATEDIFF(DAY, T0.DocDate, GETDATE())       AS [Days Since Delivery],

    -- 5. ORDER INFO (Using OE Number as the Key)
    O.U_SORefNo                                AS [OE Number],
    O.DocNum                                   AS [ORDR DocNum],
    CAST(O.CreateDate AS DATE)                 AS [SO Create Date],
    CAST(O.DocDate AS DATE)                    AS [SO Doc Date]

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
    AND T0.DocDate >= '2026-01-01'
    AND T0.U_CompanyCategory = 'Business'

ORDER BY O.U_SORefNo, T0.DocDate DESC;

--NEW GROUPED

SELECT
    -- 1. IDENTIFY THE PATH
    T0.CardName                                AS [Client Name],
    COALESCE(SRC.Name, T1.U_Source)            AS [Source Name],
    COALESCE(DEST.Name, T1.U_Destination)      AS [Destination Name],
    i.ItemName                                 AS [Cement Brand],
    MAX(CT.Name)                               AS [Cement Type],
    
    -- 2. DELIVERY CLASSIFICATION
    CASE
        WHEN MAX(O.U_TranType) IN ('SOC','SOCH','FTH')
             AND MAX(COALESCE(SRC.U_DeliveryType, T1.U_DeliveryType)) = 'BULK'   THEN 'Trading - Bulk'
        WHEN MAX(O.U_TranType) IN ('SOC','SOCH','FTH')
             AND MAX(COALESCE(SRC.U_DeliveryType, T1.U_DeliveryType)) = 'BAGGED' THEN 'Trading - FB'
        WHEN MAX(O.U_TranType) IN ('SPT','SOTC','CIF','SOHH')
             AND MAX(COALESCE(SRC.U_DeliveryType, T1.U_DeliveryType)) = 'BULK'   THEN 'Hauling - Bulk'
        WHEN MAX(O.U_TranType) IN ('SPT','SOTC','CIF','SOHH')                    THEN 'Hauling - FB'
        WHEN MAX(O.U_TranType) IN ('RVC','SOHH')                                 THEN 'Republic'
        WHEN MAX(O.U_TranType) IN ('PLD','MOB')                                  THEN 'Preload'
        ELSE 'Others'
    END                                        AS [Delivery Group],

    -- 3. THE TOTAL TRIPS
    COUNT(DISTINCT T0.DocEntry)                AS [Total Trips Delivered],
    
    -- 4. THE QUANTITIES
    CAST(SUM(T1.U_QTYCustDelivered) AS DECIMAL(10,2)) AS [Grand Total Qty Delivered],
    CAST(SUM(T1.U_QTYDelivered) AS DECIMAL(10,2))     AS [Total Qty Withdrawn],
    
    -- 5. REFERENCE & AGING
    MAX(T0.DocNum)                             AS [Latest Delivery No],
    CAST(MAX(T0.DocDate) AS DATE)              AS [Last Delivery Date],
    -- Days since the last delivery was made
    DATEDIFF(DAY, MAX(T0.DocDate), GETDATE())  AS [Days Since Delivery], 

    -- 6. LATEST ORDER INFO
    MAX(O.DocNum)                              AS [Latest ORDR DocNum],
    MAX(O.U_SORefNo)                           AS [Latest OE Number],
    CAST(MAX(O.CreateDate) AS DATE)            AS [Latest SO Create Date],
    CAST(MAX(O.DocDate) AS DATE)               AS [Latest SO Doc Date]

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
    AND T0.DocDate >= '2026-01-01'
    AND T0.U_CompanyCategory = 'Business'

GROUP BY 
    T0.CardName, 
    COALESCE(SRC.Name, T1.U_Source), 
    COALESCE(DEST.Name, T1.U_Destination), 
    i.ItemName

ORDER BY [LastOrdered] ASC;