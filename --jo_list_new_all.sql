--jo_list_new_all
ALTER VIEW jo_list_all_new as 

-- Active JOs
WITH ActiveJO AS (
    SELECT
        -- Standardized to match DoneJO column names and native types
        CAST(TRIM([Jrn]) AS NVARCHAR(MAX))          AS jr_number,
        CAST(TRIM([Jonumber]) AS NVARCHAR(80))      AS jo_number,
        TRY_CAST(TRIM([Urid]) AS INT)               AS ur_id,
        [Selectedurs],                               -- Already NVARCHAR(MAX)
        CAST([Activity] AS NVARCHAR(80))            AS jo_activity,
        CAST([Classification] AS NVARCHAR(80))      AS Classification,
        CAST([Location] AS NVARCHAR(80))            AS jo_location,
        [Remarks],                                   -- Already NVARCHAR(MAX)
        [Repairs],                                   -- Fixed: Added missing comma here 🌟
        [Notes],                                     -- Already NVARCHAR(MAX)
        CAST(TRIM([Wrfnumber]) AS NVARCHAR(80))     AS wrf_number,
        TRY_CAST([Etr] AS DATETIME2)                AS Etr,
        CAST([Headjo] AS NVARCHAR(80))              AS head_jo,
        CAST([Trailerjo] AS NVARCHAR(80))           AS trailer_jo,
        CAST([Jostatus] AS NVARCHAR(80))            AS jo_status,
        TRY_CAST([Modified] AS DATETIME2)           AS Modified,
        [Mechanic],                                  -- Already NVARCHAR(MAX)

        ROW_NUMBER() OVER (
            PARTITION BY [Jonumber], [Urid]
            ORDER BY TRY_CAST([Modified] AS DATETIME2) DESC
        ) AS rn
    FROM SHAREPOINT_DATA.dbo.jo_list
    WHERE TRIM([Jonumber]) <> ''
      -- Ensures we don't pass alphanumeric garbage strings into our new INT column
      AND TRY_CAST(TRIM([Urid]) AS INT) IS NOT NULL 
),

DoneJO AS (
    SELECT
        -- Native pulls without performance-draining NVARCHAR(MAX) conversions
        TRIM([JRN])                                 AS jr_number,
        TRIM([Jonumber])                            AS jo_number,
        [URID]                                      AS ur_id,
        [SelectedURs]                               AS Selectedurs,
        [Activity]                                  AS jo_activity,
        [Classification]                            AS Classification,
        [Location]                                  AS jo_location,
        [Remarks]                                   AS Remarks,
        [Repairs]                                   AS Repairs,
        [Notes]                                     AS Notes,
        TRIM([WRFNumber])                           AS wrf_number,
        [ETR]                                       AS Etr,
        [HeadJO]                                    AS head_jo,
        [TrailerJO]                                 AS trailer_jo,
        [JOStatus]                                  AS jo_status,
        [Modified]                                  AS Modified,
        [Mechanic]                                  AS Mechanic,

        ROW_NUMBER() OVER (
            PARTITION BY [Jonumber], [URID]
            ORDER BY [Modified] DESC
        ) AS rn
    FROM SHAREPOINT_DATA.dbo.jo_list_done
    WHERE TRIM([JONumber]) <> ''
      AND [Urid] IS NOT NULL
      AND TRIM([JRN]) <> ''
),

-- Merge both sources
MergedJO AS (
    SELECT
        jr_number,
        jo_number,
        ur_id,
        Selectedurs,
        jo_activity,
        Classification,
        jo_location,
        Remarks,
        Repairs,
        Notes,
        head_jo,
        trailer_jo,
        wrf_number,
        Etr,
        jo_status,
        Modified,
        Mechanic   
    FROM ActiveJO
    WHERE rn = 1

    UNION ALL

    SELECT
        d.jr_number,
        d.jo_number,
        d.ur_id,
        d.Selectedurs,
        d.jo_activity,
        d.Classification,
        d.jo_location,
        d.Remarks,
        d.Repairs,
        d.Notes,
        d.head_jo,
        d.trailer_jo,
        d.wrf_number,
        d.Etr,
        d.jo_status,
        d.Modified,
        d.Mechanic   -- ✅ ADDED
    FROM DoneJO d
    WHERE d.rn = 1
    AND NOT EXISTS (
        SELECT 1
        FROM ActiveJO a
        WHERE a.rn = 1
          AND a.jr_number = d.jr_number
          AND a.jo_number = d.jo_number
          AND a.ur_id = d.ur_id
    )
),

-- WRF enrichment
WrfStatus AS (
    SELECT
        m.*,
        CASE
            WHEN ISNULL(TRIM(m.wrf_number), '') = '' THEN 'NO WRF'
            WHEN p.JONoWrfNo IS NULL THEN 'NO PR'
            ELSE 'HAS PR'
        END AS WrfState,

        p.UnitStatus,
        p.PrDate,
        p.ItemCode,
        p.ItemDescription,
        p.PurchasingEtaOfParts
    FROM MergedJO m
    LEFT JOIN SHAREPOINT_DATA.dbo.jr_jo_pending_parts p
        ON TRIM(m.wrf_number) = TRIM(CAST(p.JONoWrfNo AS NVARCHAR(MAX)))
)

-- FINAL OUTPUT
SELECT
    w.jr_number,
    w.jo_number AS [jo_number],
    'UR-' + CAST(w.ur_id AS NVARCHAR(MAX)) AS ur_id,
    w.Selectedurs AS selected_ur,
    w.jo_activity,
    w.Classification AS [class],
    w.jo_location,
    w.jo_status,
    w.mechanic,

    w.Remarks AS jo_remarks,
    w.repairs,
    w.Notes AS jo_notes,
    w.head_jo,
    w.trailer_jo,
    w.wrf_number,

    CASE w.WrfState
        WHEN 'NO WRF' THEN 'NO WRF YET'
        WHEN 'NO PR' THEN 'NO PR YET'
        ELSE
            ISNULL(CAST(w.UnitStatus AS NVARCHAR(MAX)), '')
            + ' - ' +
            ISNULL(CONVERT(NVARCHAR(50), TRY_CAST(w.PrDate AS DATETIME), 101), '')
    END AS pr_remarks,

    CASE w.WrfState
        WHEN 'NO WRF' THEN 'NO WRF YET'
        WHEN 'NO PR' THEN 'NO PR YET'
        ELSE
            ISNULL(CAST(w.ItemCode AS NVARCHAR(MAX)), '')
            + ' - ' +
            ISNULL(CAST(w.ItemDescription AS NVARCHAR(MAX)), '')
    END AS [item_desc],

    CASE
        WHEN w.WrfState = 'NO WRF'
          OR w.PurchasingEtaOfParts IS NULL THEN ''
        ELSE
            ISNULL(CONVERT(NVARCHAR(50), TRY_CAST(w.PurchasingEtaOfParts AS DATETIME), 101), '')
    END AS [ETA],

    w.Etr AS [ETR],
    w.Modified
FROM WrfStatus w;
GO

--jr

USE [MAINTENANCE_APP_MASTERDATA]; -- Directs the target table creation to your primary processing DB
GO

-- 1. Clean up old instances if refreshing snapshots
IF OBJECT_ID('dbo.jr_list_all_new', 'U') IS NOT NULL
    DROP TABLE dbo.jr_list_all_new;
GO

-- 2. Build and populate the new table dynamically
SELECT *
INTO dbo.jr_list_all_new
FROM (
    -- 1. DONE JRs: Pulls purely from native types (No expensive MAX conversions)
    SELECT 
        [JRNumber],
        [JRStatus],
        [DateCreated],
        [BUEffective],
        [Note], 
        [Driver],
        [Head],
        [Trailer],
        [Odometer],
        [RequestStatus],
        [PriorityLevel],
        [Location],
        [UR],
        [TeamID],
        [BusinessUnit],
        [ApprovalTimestamp],
        [RejectedTimestamp],
        [RejectedRemarks],
        [Creator],
        [CancelledBy],
        [ReleaseStamp],
        [Valet],
        [ReleaseRemarks],
        [Done],
        [ReleasedBy],
        [RescueLocation],
        [ContactNumber],
        [Modified],
        [HeadTms],
        [HeadTmsTitle],
        [HeadTmsBu],
        [TrailerTms],
        [TrailerTmsBu],
        [MaintenanceRemarks],
        [Created],
        [FleetGroup],
        [ID],
        [ModifiedBy]
    FROM [SHAREPOINT_DATA].[dbo].[jr_list_done]

    UNION ALL 

    -- 2. ACTIVE JRs: Handles the explicit conversion overhead to match Done native types
    SELECT
        CAST([Jrnumber] AS VARCHAR(40))                AS [JRNumber],
        CAST([Jrstatus] AS VARCHAR(20))                AS [JRStatus],
        TRY_CAST([Datecreated] AS DATETIME2(0))        AS [DateCreated],
        CAST([Bueffective] AS VARCHAR(80))             AS [BUEffective],
        [Note], 
        CAST([Driver] AS VARCHAR(80))                  AS [Driver],
        CAST([Head] AS VARCHAR(40))                    AS [Head],
        CAST([Trailer] AS VARCHAR(80))                 AS [Trailer],
        TRY_CAST([Odometer] AS INT)                    AS [Odometer],
        CAST([Requeststatus] AS VARCHAR(100))          AS [RequestStatus],
        CAST([Prioritylevel] AS VARCHAR(100))          AS [PriorityLevel],
        CAST([Location] AS VARCHAR(255))               AS [Location],
        CAST([Ur] AS VARCHAR(255))                     AS [UR],
        CAST([Teamid] AS VARCHAR(100))                 AS [TeamID],
        CAST([Businessunit] AS VARCHAR(80))            AS [BusinessUnit],
        TRY_CAST([ApprovalTimestamp] AS DATETIME2(0))  AS [ApprovalTimestamp],
        TRY_CAST([RejectedTimestamp] AS DATETIME2(0))  AS [RejectedTimestamp],
        [RejectedRemarks], 
        CAST([Creator] AS VARCHAR(80))                 AS [Creator],
        CAST([Cancelledby] AS VARCHAR(80))             AS [CancelledBy],
        TRY_CAST([Releasestamp] AS DATETIME2(0))       AS [ReleaseStamp],
        CAST([Valet] AS VARCHAR(80))                   AS [Valet],
        [ReleaseRemarks], 
        TRY_CAST([Done] AS DATETIME2(0))               AS [Done],
        CAST([Releasedby] AS VARCHAR(80))              AS [ReleasedBy],
        CAST([Rescuelocation] AS VARCHAR(255))         AS [RescueLocation],
        CAST([Contact] AS NVARCHAR(50))                AS [ContactNumber], 
        TRY_CAST([Modified] AS DATETIME2(0))           AS [Modified],
        CAST([HeadTms] AS VARCHAR(40))                 AS [HeadTms],
        CAST([HeadTmsTitle] AS VARCHAR(60))            AS [HeadTmsTitle],
        CAST([HeadTmsBu] AS VARCHAR(60))               AS [HeadTmsBu],
        CAST([TrailerTms] AS VARCHAR(40))              AS [TrailerTms],
        CAST([TrailerTmsBu] AS VARCHAR(60))            AS [TrailerTmsBu],
        [Maintenanceremarks]                           AS [MaintenanceRemarks], 
        TRY_CAST([Created] AS DATETIME2(0))            AS [Created],
        CAST([Fleetgroup] AS VARCHAR(80))              AS [FleetGroup],
        TRY_CAST([Id] AS INT)                          AS [ID],
        CAST([ModifiedBy] AS VARCHAR(80))              AS [ModifiedBy]
    FROM [SHAREPOINT_DATA].[dbo].[jr_list]
) AS CombinedJRs;
GO