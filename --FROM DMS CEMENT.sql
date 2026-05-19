--FROM DMS CEMENT

WITH sample_customer_list as (
    SELECT DISTINCT Customer
    FROM DMS_CEM
),

ranked_trips as (
SELECT
od.OE,
    od.Customer,
    od.Source,
    od.Destination,
    od.[OE Date],
    od.QTYWithdrawn,
    od.QTYDelivered,
    ( SELECT SUM(d.QTYWithdrawn) FROM DMS_CEM d WHERE d.Customer = od.Customer AND od.TripProgress = 'Done') AS QTYWithdrawn_total,
    od.QTYDelivered - od.QTYWithdrawn AS Discrepancy,
    ROW_NUMBER() OVER (PARTITION BY od.Customer ORDER BY [Modified] DESC) AS rn,
    ( SELECT COUNT(OE) FROM DMS_CEM d WHERE d.Customer = od.Customer AND od.TripProgress = 'Done') AS cc
    FROM DMS_CEM od
    WHERE od._tripGroup NOT IN ('Preload','Mobilization') AND od.OE IS NOT NULL
)

customer_statistics as (
    SELECT
    scl.*, rt.OE, rt.Source, rt.Destination, rt.[OE Date], rt.QTYWithdrawn, rt.QTYWithdrawn_total, rt.QTYDelivered, rt.Discrepancy, rt.cc as [trip count]
    FROM sample_customer_list scl
    LEFT JOIN ranked_trips rt
    ON scl.Customer = rt.Customer
    WHERE rn = 1
),

SELECT * FROM customer_statistics ORDER BY [trip count] DESC


--new

WITH sample_customer_list as (
    SELECT DISTINCT [Client Name] 
    FROM GSDC_PROD.dbo.VW_CementSalesMTDJhontry
),

ranked_trips as (
SELECT
od.OE,
    od.Customer,
    od.Source,
    od.Destination,
    od.[OE Date],
    od.[_tripGroup] AS DeliveryType,
    od.[cementType],
    od.QTYWithdrawn,
    od.QTYDelivered,
    ( SELECT SUM(d.QTYWithdrawn) FROM DMS_CEM d WHERE d.Customer = od.Customer AND od.TripProgress = 'Done') AS QTYWithdrawn_total,
    od.QTYDelivered - od.QTYWithdrawn AS Discrepancy,
    ROW_NUMBER() OVER (PARTITION BY od.Customer ORDER BY [Modified] DESC) AS rn,
    ( SELECT COUNT(OE) FROM DMS_CEM d WHERE d.Customer = od.Customer AND od.TripProgress = 'Done') AS cc
    FROM DMS_CEM od
    WHERE od._tripGroup NOT IN ('Preload','Mobilization') AND od.OE IS NOT NULL
),

customer_statistics as (
    SELECT
    scl.*, rt.OE, rt.Source, rt.Destination, rt.[OE Date], cs.[Cement Brand] ,rt.DeliveryType ,rt.cementType, rt.QTYWithdrawn, rt.QTYWithdrawn_total, rt.QTYDelivered, rt.Discrepancy, rt.cc as [trip count]
    FROM sample_customer_list scl
    LEFT JOIN ranked_trips rt
    ON scl.[Client Name] COLLATE DATABASE_DEFAULT = rt.Customer COLLATE DATABASE_DEFAULT

    LEFT JOIN GSDC_PROD.dbo.VW_CementSalesMTDJhontry cs ON cs.[OE Number] COLLATE DATABASE_DEFAULT = rt.OE COLLATE DATABASE_DEFAULT

    WHERE rn = 1
)

SELECT * FROM customer_statistics ORDER BY [trip count] DESC
