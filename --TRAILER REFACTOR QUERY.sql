--TRAILER REFACTOR QUERY

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
ORDER BY PairedWith asc





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