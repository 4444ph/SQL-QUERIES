-- vw_trailer_data_query

WITH ranked_jo AS (
    SELECT
        Jrn, Jonumber, Activity, Etr, Location,
        Remarks, [Classification], Modified,
        ROW_NUMBER() OVER (
            PARTITION BY Jrn
            ORDER BY Modified DESC
        ) AS rn
    FROM jo_list
),
ranked_gps AS (
    SELECT
        Headno, LiveLocation, LastUpdate, GpsStat,
        ROW_NUMBER() OVER (
            PARTITION BY Headno
            ORDER BY LastUpdate DESC
        ) AS rn2
    FROM gps_live_data
),
YardMapping AS (
    SELECT Priority, Pattern, YardCode FROM (VALUES 
        (1,  '%3013 Minuyan%',                  'FEBCI'),
        (2,  '%C3013 Minuyan%',                 'FEBCI'),
        (10, '%Pisces Rice Mill%',              'IC'),
        (11, '%Bdo South Sea%',                 'IC'),
        (12, '%South Sea%',                     'IC'),
        (13, '%3016 San Juan, Balagtas%',       'IC'),
        (14, '%San Juan, Balagtas%',            'IC'),
        (15, '%RW46+RH%',                       'IC'),
        (16, '%Halili Avenue%',                 'IC'),
        (17, '%Turo, Bocaue%',                  'IC'),
        (18, '%Maria Corazon%',                 'IC'),
        (19, '%Unnamed Road, Balagtas%',        'IC'),
        (20, '%+%, Balagtas, Bulacan%',         'IC'),
        (21, '%+%Balagtas%',                    'IC'),
        (22, '%Balagtas, Bulacan%',             'IC'),
        (30, '%Great Sierra%',                  'Vas'),
        (31, '%Wakas, Bocaue%',                 'Vas'),
        (32, '%583 Villarama%',                 'Vas'),
        (33, '%Vasquez Compound%',              'Vas'),
        (34, '%Villarama Road%',                'Vas'),
        (35, '%Villarama Hwy%',                 'Vas'),
        (36, '%Kaymino Road%',                  'Vas'),
        (37, '%V39G+WJM%',                      'Vas'),
        (38, '%Payogi Leisure%',                'Vas'),
        (39, '%Matictic%',                      'Vas'),
        (40, '%+%, Villarama Road%',            'Vas'),
        (41, '%+% Vasquez Compound%',           'Vas'),
        (42, '%+%, Old Barrio Rd%',             'Vas'),
        (43, '%+%, Del Monte%',                 'Vas'),
        (44, '%+%, Norzagaray, Bulacan%',       'Vas'),
        (45, '%+% Norzagaray, Bulacan%',        'Vas'),
        (46, '%San Jose Del Monte-Norzagaray%', 'Vas'),
        (47, '%Bigte%',                         'Vas'),
        (48, '%Norzagaray%',                    'Vas'),
        (49, '%Quirino Highway%',               'Vas'),
        (50, '%Minuyan%',                       'Vas'),
        (51, '%--No Loc%',                      'Vas')
    ) AS t(Priority, Pattern, YardCode)
),
OpsStatusValid AS (
    SELECT v.Status, v.Category FROM (VALUES
        ('AWAITING TRIP',        'AVAILABLE'),
        ('REST',                 'AVAILABLE'),
        ('DRIVER PREPAIRING',    'IDLE'),
        ('DRIVER AVAILABLE',     'AVAILABLE'),
        ('HELPER AVAILABLE',     'IDLE'),
        ('VACATION LEAVE',       'IDLE'),
        ('SICK LEAVE',           'IDLE'),
        ('ABSENT',               'IDLE'),
        ('SUSPENDED',            'IDLE'),
        ('HOLD',                 'IDLE'),
        ('UR AVAILABLE DRIVER',  'IDLE'),
        ('UR REST',              'IDLE'),
        ('UR ABSENT',            'IDLE'),
        ('AWOL ALERT',           'IDLE'),
        ('FOR RESCUE',           'IDLE'),
        ('ITG',                  'ON TRIP'),
        ('EMS',                  'ON TRIP'),
        ('ITD',                  'ON TRIP'),
        ('WTL',                  'ON TRIP'),
        ('LDN',                  'ON TRIP'),
        ('ULD',                  'ON TRIP'),
        ('LDS',                  'ON TRIP'),
        ('LDD',                  'ON TRIP'),
        ('LDG',                  'ON TRIP'),
        ('ITR',                  'ON TRIP'),
        ('WTU',                  'ON TRIP'),
        ('ITS',                  'ON TRIP'),
        ('PRELOADED',            'PRELOADED'),
        ('REDEL GSDC',           'ON TRIP'),
        ('REDEL CLIENT',         'ON TRIP'),
        ('GTD',                  'ON TRIP'),
        ('BACKLOAD',             'ON TRIP'),
        ('SERVED',               'ON TRIP'),
        ('SERVED BACKLOGS',      'ON TRIP'),
        ('FOUL TRIP',            'ON TRIP'),
        ('LAS',                  'ON TRIP'),
        ('UAD',                  'IDLE'),
        ('CONFIRMED',            'IDLE'),
        ('EMPTY AT YARD - EAY',  'AVAILABLE'),
        ('AFD',                  'AVAILABLE'),
        ('CANCELLED',            'AVAILABLE'),
        ('LOADED AT YARD - LAY', 'PRELOADED'),
        ('ITGEMS',               'ON TRIP'),
        ('WTLL',                 'ON TRIP'),
        ('DNUL',                 'ON TRIP'),
        ('DLD',                  'ON TRIP'),
        ('SLD',                  'ON TRIP'),
        ('GIT',                  'ON TRIP'),
        ('RWT',                  'ON TRIP'),
        ('UITS',                 'ON TRIP')
    ) AS v(Status, Category)
),
base AS (
    SELECT
        tl.Bo,
        CONCAT(tl.Bo, ' - ', tl.PlateNo)                             AS Unit,
        tl.Bu                                                    AS Team,
        tl.Classification,
        tl.PairedWith,
        tl.Axle,
        tl.SubEngine,
        jr.Jrnumber                                              AS JRNumber,
        jr.Jrstatus                                              AS JRStatus,
        jr.Requeststatus                                         AS Status,
        jr.Location,
        jr.Created                                               AS JRAge,
        jr.ApprovalTimestamp                                     AS ApprovalAge,
        jo.Classification                                        AS Tag,
        jo.Jonumber,
        jo.Activity,
        jo.Etr,
        NULL                                                     AS PartsEta,
        gps.LiveLocation                                         AS LastLocation,
        gps.LastUpdate,
        gps.GpsStat                                              AS GpsStatus,
        NULL                                                     AS AtYardTimeStamp,
        NULL                                                     AS TOAatYard,
        ym.YardCode                                              AS AssignedYard,

        -- Trip only shows if trailer has a paired head
        CASE
            WHEN ISNULL(tl.PairedWith, '') = ''                  THEN NULL
            ELSE ops.DriverTripStatus
        END                                                      AS Trip,

        ops.LatestLsTripAssigned                                 AS OE,
        ops.Remarks                                              AS OpsRemarks,
        CONCAT(jo.Jonumber, ' - ', jo.Remarks)                  AS JORemarks,
        NULL                                                     AS PRRemarks,

        CASE
            WHEN jr.Location LIKE '%Rescue%'
            THEN CONCAT(jr.Jrnumber, ' - ', jr.Location)
            ELSE NULL
        END                                                      AS ForRescue,

        -- SbuoStatus — only if paired with a head
        CASE
            WHEN ISNULL(tl.PairedWith, '') = ''                  THEN NULL
            WHEN ops.DriverTripStatus IS NULL                    THEN NULL
            WHEN osv.Category IS NOT NULL                        THEN ops.DriverTripStatus
            ELSE                                                      'NO TRIP'
        END                                                      AS SbuoStatus,

        -- URStatus
        CASE
            WHEN osv.Category IN ('IDLE', 'AVAILABLE', 'PRELOADED')
            THEN
                CASE
                    WHEN jr.Requeststatus = 'Pending Acceptance'
                    THEN
                        CASE
                            WHEN jo.Location LIKE '%Rescue%'                       THEN 'FOR RESC'
                            WHEN ISNULL(ym.YardCode, '') = ''                      THEN 'OUTSIDE'
                            ELSE                                                        'AT YARD'
                        END
                    WHEN UPPER(CONCAT(ISNULL(jo.Jonumber,''), ' - ', ISNULL(jo.Remarks,'')))
                         LIKE '%WAITING FOR PARTS%'                                THEN 'WFP'
                    WHEN jr.Jrnumber = '-'
                      OR jr.Jrnumber IS NULL                                       THEN osv.Category
                    WHEN ISNULL(jr.Jrnumber, '') <> ''
                    THEN
                        CASE
                            WHEN jr.Jrstatus <> 'Pending'
                            THEN
                                CASE
                                    WHEN jo.Location LIKE '%Rescue%'               THEN 'ON RESC'
                                    WHEN jr.Jrstatus <> 'Done'                     THEN 'ON GOING'
                                    ELSE                                                'NOT RELEASED'
                                END
                            ELSE                                                        'APPROVED'
                        END
                    ELSE osv.Category
                END
            WHEN osv.Category = 'ON TRIP'                                         THEN 'ON TRIP'
            WHEN ops.DriverTripStatus IS NULL                                      THEN 'IDLE'
            ELSE                                                                        'IDLE'
        END                                                      AS URStatus

    FROM masterlist_trailer tl

    -- JR joined via trailer's own Bo
    LEFT JOIN jr_list jr             ON tl.Bo = jr.Trailer
                                    AND jr.Ur = 'Trailer'

    LEFT JOIN ranked_jo jo           ON jo.Jrn = jr.Jrnumber
                                    AND jo.rn = 1

    -- GPS joined via paired tractor head
    LEFT JOIN ranked_gps gps         ON tl.PairedWith = gps.Headno
                                    AND gps.rn2 = 1

    -- Ops joined via paired tractor head
    LEFT JOIN fromsheet_os_idl ops   ON tl.PairedWith = ops.Head

    LEFT JOIN OpsStatusValid osv     ON osv.Status = ops.DriverTripStatus

    OUTER APPLY (
        SELECT TOP 1 YardCode
        FROM YardMapping
        WHERE gps.LiveLocation LIKE Pattern
        ORDER BY Priority ASC
    ) ym
)

-- OUTER SELECT
SELECT
    Bo,
    Unit,
    Team,
    Classification,
    PairedWith,
    JRNumber,
    JRStatus,
    Status,
    Location,
    Tag,
    JRAge,
    ApprovalAge,
    Jonumber,
    Activity,
    Etr,
    PartsEta,
    URStatus,
    LastLocation,
    LastUpdate,
    AssignedYard,
    AtYardTimeStamp,
    TOAatYard,
    SbuoStatus,
    OE,
    OpsRemarks,
    Axle,
    SubEngine,
    GpsStatus,
    Trip,
    ForRescue,
    JORemarks,
    PRRemarks,
    CASE
        WHEN URStatus = 'ON GOING'
        THEN
            CASE
                WHEN Activity LIKE '%Resume%'                  THEN 'RESUME'
                WHEN Activity LIKE '%Pause%'                   THEN 'PAUSE'
                WHEN Activity LIKE '%Start%'                   THEN 'START'
                ELSE                                                NULL
            END
        ELSE NULL
    END                                                        AS FJOAct

FROM base

ORDER BY Unit ASC;


--OLD QUERY BEFORE ALTER VIEW
USE [SHAREPOINT_DATA]
GO

/****** Object:  View [dbo].[vw_Trailer_Data]    Script Date: 29/04/2026 15:56:37 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

--TRAILER REFACTOR QUERY

ALTER VIEW [dbo].[vw_Trailer_Data] AS 

WITH ranked_jo AS (
    SELECT
        Jrn, Jonumber, Activity, Etr, Location,
        Remarks, [Classification], Modified,
        ROW_NUMBER() OVER (
            PARTITION BY Jrn
            ORDER BY Modified DESC
        ) AS rn
    FROM jo_list
),
ranked_gps AS (
    SELECT
        Headno, LiveLocation, LastUpdate, GpsStat,
        ROW_NUMBER() OVER (
            PARTITION BY Headno
            ORDER BY LastUpdate DESC
        ) AS rn2
    FROM gps_live_data
),
YardMapping AS (
    SELECT Priority, Pattern, YardCode FROM (VALUES 
        (1,  '%3013 Minuyan%',                  'FEBCI'),
        (2,  '%C3013 Minuyan%',                 'FEBCI'),
        (10, '%Pisces Rice Mill%',              'IC'),
        (11, '%Bdo South Sea%',                 'IC'),
        (12, '%South Sea%',                     'IC'),
        (13, '%3016 San Juan, Balagtas%',       'IC'),
        (14, '%San Juan, Balagtas%',            'IC'),
        (15, '%RW46+RH%',                       'IC'),
        (16, '%Halili Avenue%',                 'IC'),
        (17, '%Turo, Bocaue%',                  'IC'),
        (18, '%Maria Corazon%',                 'IC'),
        (19, '%Unnamed Road, Balagtas%',        'IC'),
        (20, '%+%, Balagtas, Bulacan%',         'IC'),
        (21, '%+%Balagtas%',                    'IC'),
        (22, '%Balagtas, Bulacan%',             'IC'),
        (30, '%Great Sierra%',                  'Vas'),
        (31, '%Wakas, Bocaue%',                 'Vas'),
        (32, '%583 Villarama%',                 'Vas'),
        (33, '%Vasquez Compound%',              'Vas'),
        (34, '%Villarama Road%',                'Vas'),
        (35, '%Villarama Hwy%',                 'Vas'),
        (36, '%Kaymino Road%',                  'Vas'),
        (37, '%V39G+WJM%',                      'Vas'),
        (38, '%Payogi Leisure%',                'Vas'),
        (39, '%Matictic%',                      'Vas'),
        (40, '%+%, Villarama Road%',            'Vas'),
        (41, '%+% Vasquez Compound%',           'Vas'),
        (42, '%+%, Old Barrio Rd%',             'Vas'),
        (43, '%+%, Del Monte%',                 'Vas'),
        (44, '%+%, Norzagaray, Bulacan%',       'Vas'),
        (45, '%+% Norzagaray, Bulacan%',        'Vas'),
        (46, '%San Jose Del Monte-Norzagaray%', 'Vas'),
        (47, '%Bigte%',                         'Vas'),
        (48, '%Norzagaray%',                    'Vas'),
        (49, '%Quirino Highway%',               'Vas'),
        (50, '%Minuyan%',                       'Vas'),
        (51, '%--No Loc%',                      'Vas')
    ) AS t(Priority, Pattern, YardCode)
),

base AS (
    SELECT
        tl.Title AS Bo,
        CONCAT(tl.Title, ' - ', tl.PlateNo)                      AS Unit,
        tl.Bu                                                    AS Team,
        tl.Classification,
        tl.PairedWith,
        tl.Axle,
        tl.SubEngine,
        tl.Assignment,
        jr.Jrnumber                                              AS JRNumber,
        jr.Jrstatus                                              AS JRStatus,
        jr.Requeststatus                                         AS Status,
        --jr.Location,
        jr.Created                                               AS JRAge,
        jr.ApprovalTimestamp                                     AS ApprovalAge,
        jo.Classification                                        AS Tag,
        jo.Jonumber,
        jo.Activity,
        jo.Etr,
        NULL                                                     AS PartsEta,
        gps.LiveLocation                                         AS LastLocation,
        gps.LastUpdate,
        gps.GpsStat                                              AS GpsStatus,
        NULL                                                     AS AtYardTimeStamp,
        NULL                                                     AS TOAatYard,

        CASE
            WHEN ISNULL(ym.YardCode, '') = ''                    THEN 'no location'
            ELSE ym.YardCode             
        END                                                      AS Yard,

        -- Trip only shows if trailer has a paired head
        CASE
            WHEN ISNULL(tl.PairedWith, '') = ''                  THEN 'IDLE'
            --WHEN ops.DriverTripStatus IS NULL                    THEN 'IDLE'
            WHEN trd.URStatus IS NOT NULL                        THEN trd.URStatus
            ELSE                                                      'IDLE'
        END                                                      AS Trip,
        -- OE REMOVE IF NOT NEEDED
        CASE
            WHEN trd.OE IS NULL THEN 'NO CURRENT TRIP'
            ELSE trd.OE
        END                                                      AS OE,

        ops.Remarks                                              AS OpsRemarks,
        CONCAT(jo.Jonumber, ' - ', jo.Remarks)                   AS JORemarks,
        NULL                                                     AS PRRemarks,

        CASE
            WHEN trd.Location LIKE '%Rescue%'
            THEN CONCAT(jr.Jrnumber, ' - ', trd.Location)
            ELSE NULL
        END                                                      AS ForRescue,

        -- SbuoStatus — only if paired with a head
        CASE
            WHEN ISNULL(tl.PairedWith, '') = ''                  THEN NULL
            WHEN ops.DriverTripStatus IS NULL                    THEN 'IDLE'
            WHEN ref.Category IS NOT NULL                        THEN ops.DriverTripStatus
            ELSE                                                      'NO TRIP'
        END                                                      AS SbuoStatus,
        trd.Location as location,
        trd.URStatus
    FROM masterlist_trailer tl

    LEFT JOIN jr_list jr             ON tl.Title = jr.Trailer
                                    AND jr.Ur = 'Trailer'
    LEFT JOIN ranked_jo jo           ON jo.Jrn = jr.Jrnumber
                                    AND jo.rn = 1
    LEFT JOIN ranked_gps gps         ON tl.PairedWith = gps.Headno
                                    AND gps.rn2 = 1
    LEFT JOIN fromsheet_os_idl ops   ON tl.PairedWith = ops.Head

    LEFT JOIN urstat_ref ref     ON ref.Status = ops.DriverTripStatus

    LEFT JOIN vw_Truck_Data_Cement_Cargo trd on tl.Title = trd.PairedTrailer

    OUTER APPLY (
        SELECT TOP 1 YardCode
        FROM YardMapping
        WHERE gps.LiveLocation LIKE Pattern
        ORDER BY Priority ASC
    ) ym
)

-- OUTER SELECT
SELECT
    Bo,
    Unit,
    Team,
    Classification,
    PairedWith,
    JRNumber,
    JRStatus,
    Status,
    Location,--trd.location
    Tag,
    JRAge,
    ApprovalAge,
    Jonumber,
    Activity,
    Etr,
    PartsEta,
    --URStatus,
    CASE 
        WHEN trip IN ('IDLE', 'AVAILABLE', 'PRELOADED') THEN
            CASE
                WHEN status = 'Pending Acceptance' THEN 
                    CASE 
                        WHEN Location LIKE '%Rescue%' THEN 'FOR RESC'
                        WHEN ISNULL(Yard, '') = '' THEN 'OUTSIDE'
                        ELSE 'AT YARD'
                    END
                WHEN UPPER(ISNULL(OpsRemarks, '')) LIKE '%WAITING FOR PARTS%' THEN 'WFP'
                WHEN ISNULL(JRNumber, '') = '-' THEN Trip
                WHEN ISNULL(JRNumber, '') <> '' THEN 
                    CASE 
                        WHEN JRStatus NOT LIKE '%Pending%' THEN
                            CASE
                                WHEN Location LIKE '%Rescue%' THEN 'ON RESC'
                                WHEN JRStatus NOT LIKE '%Done%' THEN 'ON GOING'
                                ELSE 'NOT RELEASED'
                            END
                        ELSE 'APPROVED'
                    END
            END
        ELSE 'IDLE'
    END AS URStatus,
    LastLocation,
    LastUpdate,
    Yard,
    AtYardTimeStamp,
    TOAatYard,
    SbuoStatus,
    OE,
    OpsRemarks,
    Axle,
    SubEngine,
    GpsStatus,
    Trip,
    ForRescue,
    JORemarks,
    PRRemarks,
    CASE
        WHEN URStatus = 'ON GOING'
        THEN
            CASE
                WHEN Activity LIKE '%Resume%'                  THEN 'RESUME'
                WHEN Activity LIKE '%Pause%'                   THEN 'PAUSE'
                WHEN Activity LIKE '%Start%'                   THEN 'START'
                ELSE                                                NULL
            END
        ELSE NULL
    END                                                        AS FJOAct,
    Assignment

FROM base 

WHERE Team IN ('TM','SBUO-1A')
AND Assignment = 'VASQUEZ'
--ORDER BY PairedWith asc
GO

--new and improve trailer data query

--ALTER VIEW [dbo].[vw_Trailer_Data] AS

WITH ranked_jo AS (
    SELECT
        Jrn, Jonumber, Activity, Etr, Location,
        Remarks, [Classification], Modified,
        ROW_NUMBER() OVER (
            PARTITION BY Jrn
            ORDER BY Modified DESC
        ) AS rn
    FROM jo_list
),
ranked_gps AS (
    SELECT
        Headno, LiveLocation, LastUpdate, GpsStat,
        ROW_NUMBER() OVER (
            PARTITION BY Headno
            ORDER BY LastUpdate DESC
        ) AS rn2
    FROM gps_live_data
),
ranked_jr AS (
    SELECT
        Trailer, Jrnumber, Jrstatus, Requeststatus,
        Location, Created, ApprovalTimestamp,
        ROW_NUMBER() OVER (
            PARTITION BY Trailer
            ORDER BY Created DESC
        ) AS rn3
    FROM jr_list
    WHERE Ur = 'Trailer'
),
YardMapping AS (
    SELECT Priority, Pattern, YardCode FROM (VALUES 
        (1,  '%3013 Minuyan%',                  'FEBCI'),
        (2,  '%C3013 Minuyan%',                 'FEBCI'),
        (10, '%Pisces Rice Mill%',              'IC'),
        (11, '%Bdo South Sea%',                 'IC'),
        (12, '%South Sea%',                     'IC'),
        (13, '%3016 San Juan, Balagtas%',       'IC'),
        (14, '%San Juan, Balagtas%',            'IC'),
        (15, '%RW46+RH%',                       'IC'),
        (16, '%Halili Avenue%',                 'IC'),
        (17, '%Turo, Bocaue%',                  'IC'),
        (18, '%Maria Corazon%',                 'IC'),
        (19, '%Unnamed Road, Balagtas%',        'IC'),
        (20, '%+%, Balagtas, Bulacan%',         'IC'),
        (21, '%+%Balagtas%',                    'IC'),
        (22, '%Balagtas, Bulacan%',             'IC'),
        (30, '%Great Sierra%',                  'Vas'),
        (31, '%Wakas, Bocaue%',                 'Vas'),
        (32, '%583 Villarama%',                 'Vas'),
        (33, '%Vasquez Compound%',              'Vas'),
        (34, '%Villarama Road%',                'Vas'),
        (35, '%Villarama Hwy%',                 'Vas'),
        (36, '%Kaymino Road%',                  'Vas'),
        (37, '%V39G+WJM%',                      'Vas'),
        (38, '%Payogi Leisure%',                'Vas'),
        (39, '%Matictic%',                      'Vas'),
        (40, '%+%, Villarama Road%',            'Vas'),
        (41, '%+% Vasquez Compound%',           'Vas'),
        (42, '%+%, Old Barrio Rd%',             'Vas'),
        (43, '%+%, Del Monte%',                 'Vas'),
        (44, '%+%, Norzagaray, Bulacan%',       'Vas'),
        (45, '%+% Norzagaray, Bulacan%',        'Vas'),
        (46, '%San Jose Del Monte-Norzagaray%', 'Vas'),
        (47, '%Bigte%',                         'Vas'),
        (48, '%Norzagaray%',                    'Vas'),
        (49, '%Quirino Highway%',               'Vas'),
        (50, '%Minuyan%',                       'Vas'),
        (51, '%--No Loc%',                      'Vas')
    ) AS t(Priority, Pattern, YardCode)
),

base AS (
    SELECT
        tl.Title                                                 AS Bo,
        CONCAT(tl.Title, ' - ', tl.PlateNo)                     AS Unit,
        tl.Bu                                                    AS Team,
        tl.Classification,
        tl.PairedWith,
        tl.Axle,
        tl.SubEngine,
        tl.Assignment,

        jr.Jrnumber                                              AS JRNumber,
        jr.Jrstatus                                              AS JRStatus,
        jr.Requeststatus                                         AS RequestStatus,
        jr.Created                                               AS JRAge,
        jr.ApprovalTimestamp                                     AS ApprovalAge,

        jo.Classification                                        AS Tag,
        jo.Jonumber,
        jo.Activity,
        jo.Etr,
        NULL                                                     AS PartsEta,

        gps.LiveLocation                                         AS LastLocation,
        gps.LastUpdate,
        gps.GpsStat                                              AS GpsStatus,

        NULL                                                     AS AtYardTimeStamp,
        NULL                                                     AS TOAatYard,

        CASE
            WHEN ISNULL(ym.YardCode, '') = ''                    THEN 'No Location'
            ELSE ym.YardCode
        END                                                      AS Yard,

        ISNULL(osv.Category, 'IDLE')                             AS TripCategory,

        CASE
            WHEN trd.OE IS NULL                                  THEN 'NO CURRENT TRIP'
            ELSE trd.OE
        END                                                      AS OE,

        ops.Remarks                                              AS OpsRemarks,
        CONCAT(jo.Jonumber, ' - ', jo.Remarks)                   AS JORemarks,
        NULL                                                     AS PRRemarks,

        CASE
            WHEN jr.Location LIKE '%Rescue%'
                THEN CONCAT(jr.Jrnumber, ' - ', jr.Location)
            WHEN trd.Location LIKE '%Rescue%'
                THEN CONCAT(trd.JRNumber, ' - ', trd.Location)
            ELSE NULL
        END                                                      AS ForRescue,

        CASE
            WHEN ISNULL(tl.PairedWith, '') = ''                  THEN NULL
            WHEN ops.DriverTripStatus IS NULL                    THEN 'IDLE'
            WHEN osv.Category IS NOT NULL                        THEN ops.DriverTripStatus
            ELSE                                                      'NO TRIP'
        END                                                      AS SbuoStatus,

        -- Internal columns for ur_status CTE
        trd.URStatus                                             AS _TruckURStatus,
        ISNULL(tl.PairedWith, '')                                AS _PairedWith,
        ISNULL(osv.Category, '')                                 AS _OsvCategory,
        ISNULL(jr.Location, '')                                  AS _JrLocation,
        ISNULL(trd.Location, '')                                 AS _TrdLocation,
        ISNULL(jr.Requeststatus, '')                             AS _RequestStatus,
        ISNULL(jr.Jrstatus, '')                                  AS _JrStatus,
        ISNULL(jr.Jrnumber, '')                                  AS _JrNumber,
        ISNULL(jo.Remarks, '')                                   AS _JoRemarks,
        ISNULL(ym.YardCode, '')                                  AS _YardCode,
        jr.Location                                             AS Location

    FROM masterlist_trailer tl

    LEFT JOIN ranked_jr jr               ON tl.Title = jr.Trailer
                                        AND jr.rn3 = 1

    LEFT JOIN ranked_jo jo               ON jo.Jrn = jr.Jrnumber
                                        AND jo.rn = 1

    LEFT JOIN ranked_gps gps             ON tl.PairedWith = gps.Headno
                                        AND gps.rn2 = 1

    LEFT JOIN fromsheet_os_idl ops       ON tl.PairedWith = ops.Head

    -- Updated: dbo.urstat_ref instead of config.OpsStatusValid
    LEFT JOIN dbo.urstat_ref osv         ON osv.Status = ops.DriverTripStatus

    LEFT JOIN vw_Truck_Data_Cement_Cargo trd ON tl.Title = trd.PairedTrailer

    OUTER APPLY (
        SELECT TOP 1 YardCode
        FROM YardMapping
        WHERE gps.LiveLocation LIKE Pattern
        ORDER BY Priority ASC
    ) ym

    WHERE tl.Bu IN ('TM', 'SBUO-1A')
    AND tl.Assignment = 'VASQUEZ'
),

ur_status AS (
    SELECT
        *,
        CASE
            -- 1st: Trailer has its own active JR → compute from trailer's own data
            WHEN _JrNumber NOT IN ('', '-')
            THEN
                CASE
                    -- Rescue check
                    WHEN _JrLocation LIKE '%Rescue%'
                    THEN
                        CASE
                            WHEN _RequestStatus LIKE '%Pending Acceptance%'    THEN 'FOR RESC'
                            WHEN _JrStatus NOT LIKE '%Pending%'
                             AND _JrStatus NOT LIKE '%Done%'                   THEN 'ON RESC'
                            ELSE                                                    'FOR RESC'
                        END
                    -- WFP
                    WHEN UPPER(_JoRemarks) LIKE '%WAITING FOR PARTS%'         THEN 'WFP'
                    -- Pending Acceptance
                    WHEN _RequestStatus LIKE '%Pending Acceptance%'
                    THEN
                        CASE
                            WHEN _YardCode = ''                                THEN 'OUTSIDE'
                            ELSE                                                    'AT YARD'
                        END
                    -- Has JR in progress
                    WHEN _JrStatus NOT LIKE '%Pending%'
                    THEN
                        CASE
                            WHEN _JrStatus NOT LIKE '%Done%'                   THEN 'ON GOING'
                            ELSE                                                    'NOT RELEASED'
                        END
                    ELSE                                                            'APPROVED'
                END

            -- 2nd: Trailer has no JR (fine) + paired truck exists → inherit truck URStatus
            WHEN _PairedWith <> ''
             AND _TruckURStatus IS NOT NULL                                    THEN _TruckURStatus

            -- 3rd: Trailer has no JR + no paired truck → use ops category
            WHEN _OsvCategory IN ('IDLE', 'AVAILABLE', 'PRELOADED')           THEN _OsvCategory
            WHEN _OsvCategory = 'ON TRIP'                                     THEN 'ON TRIP'

            -- Fallback
            ELSE                                                                   'IDLE'
        END                                                                    AS URStatus

    FROM base
)

SELECT
    Bo,
    Unit,
    Team,
    Classification,
    PairedWith,
    JRNumber,
    JRStatus,
    RequestStatus,
    Location,
    Tag,
    JRAge,
    ApprovalAge,
    Jonumber,
    Activity,
    Etr,
    PartsEta,
    URStatus,
    LastLocation,
    LastUpdate,
    Yard,
    AtYardTimeStamp,
    TOAatYard,
    SbuoStatus,
    OE,
    OpsRemarks,
    Axle,
    SubEngine,
    GpsStatus,
    TripCategory,
    ForRescue,
    JORemarks,
    PRRemarks,
    CASE
        WHEN URStatus = 'ON GOING'
        THEN
            CASE
                WHEN Activity LIKE '%Resume%'                    THEN 'RESUME'
                WHEN Activity LIKE '%Pause%'                     THEN 'PAUSE'
                WHEN Activity LIKE '%Start%'                     THEN 'START'
                ELSE                                                  NULL
            END
        ELSE NULL
    END                                                          AS FJOAct,
    Assignment

FROM ur_status

GO


--NEW TRAILER DATA (accurate)

CREATE VIEW vw_trailer_data as

WITH ranked_jo AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY Jrn
            ORDER BY Modified DESC
        ) AS rn
    FROM SHAREPOINT_DATA.dbo.jo_list
),

ranked_jr AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY Head
            ORDER BY Created DESC
        ) AS rn
    FROM SHAREPOINT_DATA.dbo.jr_list
    WHERE Ur = 'Trailer'
)



SELECT

    REPLACE(tl.title, ' ', '-') AS trailer_Id,
    tl.PlateNo as plate_no,
    tl.classification,
    tl.axle,
    tl.SubEngine as sub_engine,
    tl.bu,
    tl.assignment,
    lv.head as paired_head,
    lv.OE,
    lv.[Trip Status] as trip_status,
    lv.[Trip Status] as sbuo_status,

    CASE
        -- 1st: Rescue
        WHEN urs.IsRescue = 1
        THEN
            CASE
                WHEN urs.JRState = 'PENDING_ACCEPTANCE'        THEN 'FOR RESC'
                WHEN urs.JRState = 'IN_PROGRESS'               THEN 'ON RESC'
                ELSE                                                'FOR RESC'
            END

        -- 2nd: WFP
        WHEN urs.IsWFP = 1                         THEN 'WFP'

        -- 3rd: IDLE / AVAILABLE / PRELOADED
        WHEN ur.Category IN ('IDLE', 'AVAILABLE', 'PRELOADED')
        THEN
            CASE
                WHEN urs.JRState = 'PENDING_ACCEPTANCE'        THEN 'AT YARD'
                WHEN urs.JRState = 'NO_JR'                     THEN ur.Category
                WHEN urs.JRState = 'IN_PROGRESS'               THEN 'ON GOING'
                WHEN urs.JRState = 'DONE'                      THEN 'NOT RELEASED'
                ELSE                                                 'APPROVED'
            END

        -- 4th: ON TRIP
        WHEN ur.Category = 'ON TRIP'             THEN 'ON TRIP'

        -- Fallback
        ELSE 'IDLE'
    END                                           AS ur_status,

    lv.LiveLocation as live_location,
    lv.LastUpdate as last_update,
    lv.GpsStatus as gps_status,

    jr.Jrnumber as jr_number,
    jr.Jrstatus as jr_status,
    jr.Requeststatus as jr_request_status,
    jr.Location as jr_location,
    jr.created as jr_age,
    jr.ApprovalTimeStamp as jr_approval,

    jo.Jonumber				   as jo_number,
    jo.Jostatus				   as jo_status,
    jo.Activity                as jo_activity,
    jo.classification		   as jo_classification,
    CONCAT(jo.Jonumber, ' - ', jo.Remarks) AS jo_remarks,
    jo.etr,

    CASE
        WHEN jr.Location LIKE '%Rescue%'
        THEN CONCAT(jr.Jrnumber, ' - ', jr.Location)
        ELSE NULL
    END                        AS for_rescue

FROM SHAREPOINT_DATA.dbo.masterlist_trailer tl

LEFT JOIN DISPATCH_APP_DMS.dbo.LiveVehicleAssignmentLIstView lv
	ON REPLACE(tl.title, ' ', '-') = lv.PairedTrailer

LEFT JOIN ranked_jr jr      ON tl.Title = jr.Trailer
                            AND jr.rn = 1

LEFT JOIN ranked_jo jo      ON jo.Jrn = jr.Jrnumber
                            AND jo.rn = 1

LEFT JOIN SHAREPOINT_DATA.dbo.urstat_ref ur
                            ON lv.[Trip Status] = ur.Status 
LEFT JOIN trailer_ur_status urs 
    ON REPLACE(tl.title, ' ', '-') = urs.title

where tl.bu = 'SBUO-1A'

--UR_STATUS

CREATE VIEW trailer_ur_status as 

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


