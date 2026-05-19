--jo_list_all_1stver
ALTER VIEW [dbo].[VW_JO_List_All] AS 

WITH ActiveJO AS (
    SELECT
        [Jonumber], [Urid], [Selectedurs], [Activity], [Classification],
        [Location], [Remarks], [Notes], [Wrfnumber], [Etr], [Jostatus],
        ROW_NUMBER() OVER (
            PARTITION BY [Jonumber], [Urid]
            ORDER BY [Modified] DESC
        ) AS rn
    FROM dbo.jo_list
    WHERE [Jonumber] IS NOT NULL AND LTRIM(RTRIM([Jonumber])) <> ''
      AND [Urid]     IS NOT NULL AND LTRIM(RTRIM(CAST([Urid] AS NVARCHAR(MAX)))) <> ''
),

DoneJO AS (
    SELECT
        [Jonumber], [Urid], [Selectedurs], [Activity], [Classification],
        [Location], [Remarks], [Notes], [Wrfnumber], [Etr], [Jostatus],
        ROW_NUMBER() OVER (
            PARTITION BY [Jonumber], [Urid]
            ORDER BY [Modified] DESC
        ) AS rn
    FROM dbo.jo_list_done
    WHERE [Jonumber] IS NOT NULL AND LTRIM(RTRIM([Jonumber])) <> ''
      AND [Urid]     IS NOT NULL AND LTRIM(RTRIM(CAST([Urid] AS NVARCHAR(MAX)))) <> ''
),

MergedJO AS (
    -- FIX #1: We CAST everything to NVARCHAR here before COALESCE.
    -- If jo_list has ETR as a DATETIME but jo_list_done has ETR as VARCHAR, 
    -- COALESCE normally crashes. Casting them first prevents this.
    SELECT 
        COALESCE(CAST(a.[Jonumber] AS NVARCHAR(MAX)), CAST(d.[Jonumber] AS NVARCHAR(MAX))) AS [Jonumber],
        COALESCE(CAST(a.[Urid] AS NVARCHAR(MAX)), CAST(d.[Urid] AS NVARCHAR(MAX)))         AS [Urid],
        COALESCE(CAST(a.[Selectedurs] AS NVARCHAR(MAX)), CAST(d.[Selectedurs] AS NVARCHAR(MAX))) AS [Selectedurs],
        COALESCE(CAST(a.[Activity] AS NVARCHAR(MAX)), CAST(d.[Activity] AS NVARCHAR(MAX))) AS [Activity],
        COALESCE(CAST(a.[Classification] AS NVARCHAR(MAX)), CAST(d.[Classification] AS NVARCHAR(MAX))) AS [Classification],
        COALESCE(CAST(a.[Location] AS NVARCHAR(MAX)), CAST(d.[Location] AS NVARCHAR(MAX))) AS [Location],
        COALESCE(CAST(a.[Remarks] AS NVARCHAR(MAX)), CAST(d.[Remarks] AS NVARCHAR(MAX)))   AS [Remarks],
        COALESCE(CAST(a.[Notes] AS NVARCHAR(MAX)), CAST(d.[Notes] AS NVARCHAR(MAX)))       AS [Notes],
        COALESCE(CAST(a.[Wrfnumber] AS NVARCHAR(MAX)), CAST(d.[Wrfnumber] AS NVARCHAR(MAX))) AS [Wrfnumber],
        COALESCE(CAST(a.[Etr] AS NVARCHAR(MAX)), CAST(d.[Etr] AS NVARCHAR(MAX)))           AS [Etr],
        COALESCE(CAST(a.[Jostatus] AS NVARCHAR(MAX)), CAST(d.[Jostatus] AS NVARCHAR(MAX))) AS [Jostatus]
    FROM (SELECT * FROM ActiveJO WHERE rn = 1) a
    FULL OUTER JOIN (SELECT * FROM DoneJO WHERE rn = 1) d
        ON a.[Jonumber] = d.[Jonumber] AND a.[Urid] = d.[Urid]
)

SELECT
    m.[Jonumber]                                                AS [JONumber],
    'UR-' + m.[Urid]                                            AS [RepairID],
    m.[Selectedurs]                                             AS [SelectedUR],
    m.[Activity]                                                AS [Activity],
    m.[Classification]                                          AS [Class],
    m.[Location]                                                AS [Location],
    m.[Jostatus]                                                AS [JOStatus],
    m.[Remarks]                                                 AS [JORemarks],
    m.[Notes]                                                   AS [JONotes],
    m.[Wrfnumber]                                               AS [WRFNo],

    -- FIX #2: Wrapped PrDate in TRY_CAST
    CASE
        WHEN m.[Wrfnumber] IS NULL OR LTRIM(RTRIM(m.[Wrfnumber])) = '' THEN 'NO WRF YET'
        WHEN p.[JONoWrfNo] IS NULL THEN 'NO PR YET'
        ELSE
            ISNULL(CAST(p.[UnitStatus] AS NVARCHAR(MAX)), '')
            + ' - '
            + ISNULL(CONVERT(NVARCHAR(50), TRY_CAST(p.[PrDate] AS DATETIME), 101), 'Invalid Date')
    END                                                         AS [PRRemarks],

    CASE
        WHEN m.[Wrfnumber] IS NULL OR LTRIM(RTRIM(m.[Wrfnumber])) = '' THEN 'NO WRF YET'
        WHEN p.[JONoWrfNo] IS NULL THEN 'NO PR YET'
        ELSE
            ISNULL(CAST(p.[ItemCode] AS NVARCHAR(MAX)), '')
            + ' - '
            + ISNULL(CAST(p.[ItemDescription] AS NVARCHAR(MAX)), '')
    END                                                         AS [ItemDesc],

    -- FIX #3: Wrapped PurchasingEtaOfParts in TRY_CAST
    CASE
        WHEN m.[Wrfnumber] IS NULL OR LTRIM(RTRIM(m.[Wrfnumber])) = '' THEN ''
        WHEN p.[PurchasingEtaOfParts] IS NULL THEN ''
        ELSE
            ISNULL(CONVERT(NVARCHAR(50), TRY_CAST(p.[PurchasingEtaOfParts] AS DATETIME), 101), '')
            + ' '
            + ISNULL(CONVERT(NVARCHAR(10), TRY_CAST(p.[PurchasingEtaOfParts] AS DATETIME), 108), '')
    END                                                         AS [ETA],

    m.[Etr]                                                     AS [ETR]
FROM MergedJO m
LEFT JOIN dbo.jr_jo_pending_parts p
    ON m.[Wrfnumber] = CAST(p.[JONoWrfNo] AS NVARCHAR(MAX))
GO


--USING RIGHT NOW

ALTER VIEW [dbo].[VW_JO_List_All] AS 

-- Active JOs — all NVARCHAR(MAX) already, no casting needed
WITH ActiveJO AS (
    SELECT
        TRIM([Jonumber])                            AS Jonumber,
        TRIM(CAST([Urid] AS NVARCHAR(MAX)))         AS Urid,
        [Selectedurs], [Activity], [Classification],
        [Location], [Remarks], [Notes],
        TRIM([Wrfnumber])                           AS Wrfnumber,
        [Etr], [Jostatus],
        ROW_NUMBER() OVER (
            PARTITION BY [Jonumber], [Urid]
            ORDER BY [Modified] DESC
        )                                           AS rn
    FROM dbo.jo_list
    WHERE TRIM([Jonumber]) <> ''
    AND   TRIM(CAST([Urid] AS NVARCHAR(MAX))) <> ''
),

-- Done JOs — cast typed columns to NVARCHAR(MAX) to match jo_list
DoneJO AS (
    SELECT
        TRIM(CAST([Jonumber]       AS NVARCHAR(MAX)))    AS Jonumber,
        TRIM(CAST([Urid]           AS NVARCHAR(MAX)))    AS Urid,
        CAST([Selectedurs]         AS NVARCHAR(MAX))     AS Selectedurs,
        CAST([Activity]            AS NVARCHAR(MAX))     AS Activity,
        CAST([Classification]      AS NVARCHAR(MAX))     AS Classification,
        CAST([Location]            AS NVARCHAR(MAX))     AS Location,
        CAST([Remarks]             AS NVARCHAR(MAX))     AS Remarks,
        CAST([Notes]               AS NVARCHAR(MAX))     AS Notes,
        TRIM(CAST([Wrfnumber]      AS NVARCHAR(MAX)))    AS Wrfnumber,
        -- Etr: convert datetime to string safely
        ISNULL(
            CONVERT(NVARCHAR(50), TRY_CAST([Etr] AS DATETIME), 101),
            CAST([Etr] AS NVARCHAR(MAX))
        )                                                AS Etr,
        CAST([Jostatus]            AS NVARCHAR(MAX))     AS Jostatus,
        ROW_NUMBER() OVER (
            PARTITION BY CAST([Jonumber] AS NVARCHAR(MAX)), 
                         CAST([Urid]     AS NVARCHAR(MAX))
            ORDER BY [Modified] DESC
        )                                                AS rn
    FROM dbo.jo_list_done
    WHERE TRIM(CAST([Jonumber] AS NVARCHAR(MAX))) <> ''
    AND   TRIM(CAST([Urid]     AS NVARCHAR(MAX))) <> ''
),

MergedJO AS (
    SELECT
        Jonumber, Urid, Selectedurs, Activity,
        Classification, Location, Remarks, Notes,
        Wrfnumber, Etr, Jostatus
    FROM ActiveJO
    WHERE rn = 1

    UNION ALL

    SELECT
        d.Jonumber, d.Urid, d.Selectedurs, d.Activity,
        d.Classification, d.Location, d.Remarks, d.Notes,
        d.Wrfnumber, d.Etr, d.Jostatus
    FROM DoneJO d
    WHERE d.rn = 1
    -- Only include Done JOs that have no Active counterpart
    AND NOT EXISTS (
        SELECT 1
        FROM ActiveJO a
        WHERE a.rn = 1
        AND   a.Jonumber = d.Jonumber
        AND   a.Urid     = d.Urid
    )
),

-- Pre-compute WRF status to avoid repeating the same CASE logic
WrfStatus AS (
    SELECT
        m.*,
        CASE
            WHEN ISNULL(TRIM(m.Wrfnumber), '') = '' THEN 'NO WRF'
            WHEN p.JONoWrfNo IS NULL                THEN 'NO PR'
            ELSE                                         'HAS PR'
        END                                         AS WrfState,
        p.UnitStatus,
        p.PrDate,
        p.ItemCode,
        p.ItemDescription,
        p.PurchasingEtaOfParts
    FROM MergedJO m
    LEFT JOIN dbo.jr_jo_pending_parts p
        ON TRIM(m.Wrfnumber) = TRIM(CAST(p.JONoWrfNo AS NVARCHAR(MAX)))
)

SELECT
    w.Jonumber                                      AS [JONumber],
    'UR-' + CAST(w.Urid AS NVARCHAR(MAX))           AS [RepairID],
    w.Selectedurs                                   AS [SelectedUR],
    w.Activity,
    w.Classification                                AS [Class],
    w.Location,
    w.Jostatus                                      AS [JOStatus],
    w.Remarks                                       AS [JORemarks],
    w.Notes                                         AS [JONotes],
    w.Wrfnumber                                     AS [WRFNo],

    -- PRRemarks: references WrfState once — no repeated CASE conditions
    CASE w.WrfState
        WHEN 'NO WRF' THEN 'NO WRF YET'
        WHEN 'NO PR'  THEN 'NO PR YET'
        ELSE
            ISNULL(CAST(w.UnitStatus AS NVARCHAR(MAX)), '')
            + ' - '
            + ISNULL(
                CONVERT(NVARCHAR(50), TRY_CAST(w.PrDate AS DATETIME), 101),
                'Invalid Date'
              )
    END                                             AS [PRRemarks],

    -- ItemDesc: same WrfState check — no duplication
    CASE w.WrfState
        WHEN 'NO WRF' THEN 'NO WRF YET'
        WHEN 'NO PR'  THEN 'NO PR YET'
        ELSE
            ISNULL(CAST(w.ItemCode AS NVARCHAR(MAX)), '')
            + ' - '
            + ISNULL(CAST(w.ItemDescription AS NVARCHAR(MAX)), '')
    END                                             AS [ItemDesc],

    -- ETA
    CASE
        WHEN w.WrfState = 'NO WRF'
          OR w.PurchasingEtaOfParts IS NULL         THEN ''
        ELSE
            ISNULL(
                CONVERT(NVARCHAR(50), TRY_CAST(w.PurchasingEtaOfParts AS DATETIME), 101),
                ''
            )
            + ' '
            + ISNULL(
                CONVERT(NVARCHAR(10), TRY_CAST(w.PurchasingEtaOfParts AS DATETIME), 108),
                ''
            )
    END                                             AS [ETA],

    w.Etr                                           AS [ETR]

FROM WrfStatus w


