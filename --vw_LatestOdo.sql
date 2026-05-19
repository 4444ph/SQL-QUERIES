--vw_LatestOdo

WITH ranked_odo AS (
    SELECT 
        Head, 
        Odometer, 
        SQLID,
        ROW_NUMBER() OVER (
            PARTITION BY Head, Odometer 
            ORDER BY SQLID DESC
        ) AS ranked_num
    FROM fctFinal fct
)


SELECT * FROM ranked_odo
WHERE Head IS NOT NULL
AND SQLID IS NOT NULL -- Filters out rows that failed conversion
--AND ModifiedDate >= '2026-04-01'
and ranked_num = 1
--ORDER BY ModifiedDate ASC;



