USE [WILLOWTestDB]
GO

/****** Object:  View [dbo].[truck_ur_status]    Script Date: 15 May 2026 2:25:08 pm ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER VIEW [dbo].[truck_ur_status] AS

WITH ranked_jo AS (
    SELECT
        Jrn, Jonumber, Remarks, Location,
        ROW_NUMBER() OVER (
            PARTITION BY Jrn
            ORDER BY Modified DESC
        ) AS rn
    FROM SHAREPOINT_DATA.dbo.jo_list
),

ranked_jr AS (
    SELECT
        Head, Jrnumber, Jrstatus, Requeststatus, Location, Ur,
        ROW_NUMBER() OVER (
            PARTITION BY Head
            ORDER BY Created DESC
        ) AS rn
    FROM SHAREPOINT_DATA.dbo.jr_list
    WHERE Ur = 'Tractor'
)

SELECT
    tr.Head,
    tr.Bu,
    tr.Assignment,
    jr.Jrnumber                                             AS jr_number,
    jr.Jrstatus                                             AS jr_status,
    jr.Requeststatus                                        AS request_status,
    jr.Location                                             AS jr_location,
    jo.Remarks                                              AS jo_remarks,
    jo.Location                                             AS jo_location,

    CASE
        WHEN UPPER(ISNULL(jr.Location, '')) LIKE '%RESCUE%' THEN 1
        ELSE 0
    END                                                     AS IsRescue,

    CASE
        WHEN UPPER(ISNULL(jo.Remarks, '')) LIKE '%WAITING FOR PARTS%' THEN 1
        ELSE 0
    END                                                     AS IsWFP,

    CASE
        WHEN ISNULL(jr.Jrnumber, '') IN ('', '-')          THEN 'NO_JR'
        WHEN jr.Requeststatus LIKE '%Pending Acceptance%'  THEN 'PENDING_ACCEPTANCE'
        WHEN jr.Jrstatus NOT LIKE '%Pending%'
         AND jr.Jrstatus NOT LIKE '%Done%'                 THEN 'IN_PROGRESS'
        WHEN jr.Jrstatus LIKE '%Done%'                     THEN 'DONE'
        ELSE                                                    'PENDING'
    END                                                     AS JRState

FROM SHAREPOINT_DATA.dbo.masterlist_tractor tr

LEFT JOIN ranked_jr jr      ON tr.Head = jr.Head
                            AND jr.rn = 1

LEFT JOIN ranked_jo jo      ON jo.Jrn = jr.Jrnumber
                            AND jo.rn = 1

GO


--trailer

USE [WILLOWTestDB]
GO

/****** Object:  View [dbo].[trailer_ur_status]    Script Date: 15 May 2026 2:25:43 pm ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER VIEW [dbo].[trailer_ur_status] as 

WITH ranked_jo AS (
    SELECT
        Jrn, Jonumber, Remarks, Location,
        ROW_NUMBER() OVER (
            PARTITION BY Jrn
            ORDER BY Modified DESC
        ) AS rn
    FROM SHAREPOINT_DATA.dbo.jo_list
),

ranked_jr AS (
    SELECT
        Trailer, Jrnumber, Jrstatus, Requeststatus, Location, Ur,
        ROW_NUMBER() OVER (
            PARTITION BY Head
            ORDER BY Created DESC
        ) AS rn
    FROM SHAREPOINT_DATA.dbo.jr_list
    WHERE Ur = 'Trailer'
)

SELECT
    REPLACE(tl.title, ' ', '-') as title,
    tl.Bu,
    tl.assignment,
    jr.Trailer,
    jr.Jrnumber                                             AS jr_number,
    jr.Jrstatus                                             AS jr_status,
    jr.Requeststatus                                        AS request_status,
    jr.Location                                             AS jr_location,
    jo.Remarks                                              AS jo_remarks,
    jo.Location                                             AS jo_location,

    CASE
        WHEN UPPER(ISNULL(jr.Location, '')) LIKE '%RESCUE%' THEN 1
        ELSE 0
    END                                                     AS IsRescue,

    CASE
        WHEN UPPER(ISNULL(jo.Remarks, '')) LIKE '%WAITING FOR PARTS%' THEN 1
        ELSE 0
    END                                                     AS IsWFP,

    CASE
        WHEN ISNULL(jr.Jrnumber, '') IN ('', '-')          THEN 'NO_JR'
        WHEN jr.Requeststatus LIKE '%Pending Acceptance%'  THEN 'PENDING_ACCEPTANCE'
        WHEN jr.Jrstatus NOT LIKE '%Pending%'
         AND jr.Jrstatus NOT LIKE '%Done%'                 THEN 'IN_PROGRESS'
        WHEN jr.Jrstatus LIKE '%Done%'                     THEN 'DONE'
        ELSE                                                    'PENDING'
    END                                                     AS JRState

FROM SHAREPOINT_DATA.dbo.masterlist_trailer tl

LEFT JOIN ranked_jr jr      ON tl.Title = jr.Trailer
                            AND jr.rn = 1

LEFT JOIN ranked_jo jo      ON jo.Jrn = jr.Jrnumber
                            AND jo.rn = 1

GO


