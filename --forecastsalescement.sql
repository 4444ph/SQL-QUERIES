--source table from GSDC_PROD.dbo.vw_cementsalesmtdjhontry

SELECT
    cs.[Client Name],
    cs.[Source Name],
    cs.[Destination Name],
    cs.[cement Type],
    cs.[Cement Brand],
    SUM(cs.[Qty Withdrawn]) AS [total withdrawn],
    SUM(cs.[Qty Delivered]) AS [total delivered],
    COUNT(*) AS totalDeliveredTrips
FROM [VW_CementSalesMTDJhontry] cs
GROUP BY 
    cs.[Client Name],
   
   -- dms.Customer,
   
    cs.[Source Name], 
    cs.[Destination Name], 
    cs.[cement Type], 
    cs.[Cement Brand]
ORDER BY cs.[Client Name] DESC;

--SOURCE TABLE FROM DISPATCH_APP_DMS.dbo.DMS_CEM

SELECT
    cs.[Client Name],
    od.Customer,
    od.Source,
    od.Destination,
    od.[_tripGroup] AS DeliveryType,
    cs.[Cement Brand],
    od.[cementType] AS CementType,
    
    -- Added MAX to show the latest date without breaking the grouping
    MAX(od.[OE Date]) AS LastOEDate, 
    
    -- The totals for this specific combination
    SUM(od.QTYWithdrawn) AS QTYWithdrawn_total,
    SUM(od.QTYDelivered) AS QTYDelivered_total,
    SUM(od.QTYDelivered) - SUM(od.QTYWithdrawn) AS Discrepancy,
    COUNT(od.OE) AS [trip count]

FROM DISPATCH_APP_DMS.dbo.DMS_CEM od

-- Join directly to get the Client Name and Cement Brand
LEFT JOIN GSDC_PROD.dbo.VW_CementSalesMTDJhontry cs 
    ON od.OE COLLATE DATABASE_DEFAULT = cs.[OE Number] COLLATE DATABASE_DEFAULT

WHERE od._tripGroup NOT IN ('Preload','Mobilization') 
  AND od.OE IS NOT NULL
  AND od.TripProgress = 'Done' -- Added here so it filters globally, replacing your subquery logic

GROUP BY 
    cs.[Client Name],
    od.Customer,
    od.Source,
    od.Destination,
    od.[_tripGroup],
    cs.[Cement Brand],
    od.[cementType]

ORDER BY [Client Name] desc;


--TO TEST
WITH SAP_Summary AS (
    SELECT 
        O.U_SORefNo AS OE,
        SUM(T1.U_QTYCustDelivered) AS SAP_Qty
    FROM GSDC_Prod.dbo.ODLN T0
    INNER JOIN GSDC_Prod.dbo.DLN1 T1 ON CAST(T0.DocEntry AS VARCHAR(10)) COLLATE DATABASE_DEFAULT = CAST(T1.DocEntry AS VARCHAR(10)) COLLATE DATABASE_DEFAULT
    LEFT JOIN GSDC_Prod.dbo.ORDR O ON O.DocEntry COLLATE DATABASE_DEFAULT = T1.BaseEntry COLLATE DATABASE_DEFAULT
    WHERE T0.Canceled = 'N' AND T0.DocDate >= '2026-01-01'
    GROUP BY O.U_SORefNo
),
DMS_Summary AS (
    SELECT 
        OE,
        SUM(QTYDelivered) AS DMS_Qty
    FROM DMS_CEM
    WHERE TripProgress = 'Done'
    GROUP BY OE
)
SELECT 
    COALESCE(S.OE, D.OE) AS [OE Number],
    ISNULL(S.SAP_Qty, 0) AS [Qty in SAP],
    ISNULL(D.DMS_Qty, 0) AS [Qty in DMS],
    CASE 
        WHEN S.OE IS NULL THEN 'Missing in SAP'
        WHEN D.OE IS NULL THEN 'Missing in DMS'
        WHEN S.SAP_Qty <> D.DMS_Qty THEN 'Quantity Mismatch'
        ELSE 'Matched'
    END AS [Audit Status]
FROM SAP_Summary S
FULL OUTER JOIN DMS_Summary D ON S.OE COLLATE DATABASE_DEFAULT = D.OE COLLATE DATABASE_DEFAULT


--GROUPED_MTD

USE [GSDC_PROD]
GO

/****** Object:  View [dbo].[vw_MTD_Grouped]    Script Date: 28/04/2026 16:08:22 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



ALTER VIEW [dbo].[vw_MTD_Grouped] AS
--GROUPED

SELECT
    -- 1. IDENTIFY THE PATH
    T0.CardName                                AS [ClientName],
    COALESCE(SRC.Name, T1.U_Source)            AS [SourceName],
    COALESCE(DEST.Name, T1.U_Destination)      AS [DestinationName],
    i.ItemName                                 AS [CementBrand],
    MAX(CT.Name)                               AS [CementType],
    
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
    END                                        AS [DeliveryGroup],

    -- 3. THE TOTAL TRIPS
    COUNT(DISTINCT T0.DocEntry)                AS [TotalTripsDelivered],
    
    -- 4. THE QUANTITIES
    CAST(SUM(T1.U_QTYDelivered) AS DECIMAL(10,2))     AS [TotalQtyWithdrawn],
    CAST(SUM(T1.U_QTYCustDelivered) AS DECIMAL(10,2)) AS [TotalQtyDelivered],
    CAST(SUM(T1.U_QTYDelivered) - SUM(T1.U_QTYCustDelivered)        AS DECIMAL(10,2)) AS [Discrepancy],    
    -- 5. REFERENCE & AGING
    MAX(T0.DocNum)                             AS [DeliveryNo],--Latest
    CAST(MAX(T0.DocDate) AS DATE)              AS [DeliveryDate],--Last
    -- Days since the last delivery was made
    DATEDIFF(DAY, MAX(T0.DocDate), GETDATE())  AS [DaysSinceDelivery], 

    -- 6. LATEST ORDER INFO
    MAX(O.DocNum)                              AS [ORDRDocNum], --Latest
    MAX(O.U_SORefNo)                           AS [OENumber],--Latest
    CAST(MAX(O.CreateDate) AS DATE)            AS [SOCreateDate],--Latest
    CAST(MAX(O.DocDate) AS DATE)               AS [SODocDate]--Latest

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

GROUP BY 
    T0.CardName, 
    COALESCE(SRC.Name, T1.U_Source), 
    COALESCE(DEST.Name, T1.U_Destination), 
    i.ItemName

--ORDER BY [Client Name] ASC;
GO


