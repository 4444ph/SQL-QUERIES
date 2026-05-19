--ALTER VIEW [dbo].[vw_Truck_Data_Cement_Cargo] AS

-- CTEs
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
        -- FROM PREVIOUS GUIDE IMAGE
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

-- BASE CTE: all joins + computed columns done once
base AS (
    SELECT
        tr.Head,
        CONCAT(tr.Head, ' | ', tr.PlateNo)                      AS Unit,
        tr.Bu                                                    AS Team,
        tr.Brand,
        tr.PairedTrailer,
        tr.Assignment,
        jr.Jrnumber                                              AS JRNumber,
        jr.Jrstatus                                              AS JRStatus,
        jr.Requeststatus                                         AS Status,
        jr.Location,
        jr.Created                                               AS JRAge,
        jr.ApprovalTimestamp                                     AS ApprovalAge,
        jo.[Classification]                                      AS Tag,
        jo.Jonumber,
        jo.Activity,
        jo.Etr,
        NULL                                                     AS Eta,
        gps.LiveLocation                                         AS LastLocation,
        gps.LastUpdate,
        gps.GpsStat                                              AS GpsStatus,
        NULL                                                     AS AtYardTimeStamp,
        NULL                                                     AS TOAatYard,
        ym.YardCode                                              AS AssignedYard,

        -- Trip
        CASE
            /**WHEN ISNULL(osv.Category, 'IDLE') IN ('IDLE', 'AVAILABLE')
                THEN ISNULL(osv.Category, 'IDLE')**/
                
            WHEN ops.DriverTripStatus IS NOT NULL
                THEN osv.Category
            ELSE 'IDLE'
        END AS Trip,
        ops.DriverTripStatus,
        CASE
            WHEN osv.Category IS NULL THEN 'IDLE'
            ELSE osv.Category
        END AS TripTesting,
        
        ops.LatestLsTripAssigned                                 AS OE,
        ops.Remarks                                              AS OpsRemarks,
        CONCAT(jo.Jonumber, ' - ', jo.Remarks)                   AS JORemarks,
        CASE
            WHEN jr.Location LIKE '%Rescue%'
            THEN CONCAT(jr.Jrnumber, ' - ', jr.Location)
            ELSE NULL
        END                                                      AS ForRescue,

        -- SbuoStatus
        CASE
            WHEN ops.DriverTripStatus IS NULL                    THEN NULL
            WHEN osv.Category IS NOT NULL                        THEN ops.DriverTripStatus
            ELSE                                                      'NO TRIP'
        END                                                      AS SbuoStatus,

        -- URStatus
        CASE
            WHEN osv.Category IN ('IDLE', 'AVAILABLE', 'PRELOADED')
            THEN
                CASE
                    -- 1st: Pending Acceptance (no WFP here)
                    WHEN jr.Requeststatus = 'Pending Acceptance'
                    THEN
                        CASE
                            WHEN jo.Location LIKE '%Rescue%'                           THEN 'FOR RESC'
                            WHEN ISNULL(ym.YardCode, '') = ''                          THEN 'OUTSIDE'
                            ELSE                                                             'AT YARD'
                        END

                    -- 2nd: WFP checked independently
                    WHEN UPPER(CONCAT(ISNULL(jo.Jonumber,''), ' - ', ISNULL(jo.Remarks,'')))
                         LIKE '%WAITING FOR PARTS%'                                    THEN 'WFP'

                    -- 3rd: No JR → show SbuoStatus category as-is
                    WHEN jr.Jrnumber = '-'
                      OR jr.Jrnumber IS NULL                                           THEN osv.Category

                    -- 4th: Has JR
                    WHEN ISNULL(jr.Jrnumber, '') <> ''
                    THEN
                        CASE
                            WHEN jr.Jrstatus <> 'Pending'
                            THEN
                                CASE
                                    WHEN jo.Location LIKE '%Rescue%'                   THEN 'ON RESC'
                                    WHEN jr.Jrstatus <> 'Done'                         THEN 'ON GOING'
                                    ELSE                                                     'NOT RELEASED'
                                END
                            ELSE                                                             'APPROVED'
                        END

                    ELSE osv.Category
                END

            -- Everything outside IDLE/AVAILABLE/PRELOADED → ON TRIP
            WHEN osv.Category = 'ON TRIP'                                             THEN 'ON TRIP'
            WHEN ops.DriverTripStatus IS NULL                                         THEN 'IDLE'
            ELSE                                                                          'IDLE'
        END                                                                           AS URStatus

    FROM masterlist_tractor tr

    LEFT JOIN jr_list jr             ON tr.Head = jr.Head
                                    AND jr.Ur = 'Tractor'

    LEFT JOIN ranked_jo jo           ON jo.Jrn = jr.Jrnumber
                                    AND jo.rn = 1

    LEFT JOIN ranked_gps gps         ON tr.Head = gps.HeadNo
                                    AND gps.rn2 = 1

    LEFT JOIN fromsheet_os_idl ops   ON tr.Head = ops.Head

    -- OpsStatusValid joined once instead of correlated subqueries
    LEFT JOIN OpsStatusValid osv     ON osv.Status = ops.DriverTripStatus

    OUTER APPLY (
        SELECT TOP 1 YardCode
        FROM YardMapping
        WHERE gps.LiveLocation LIKE Pattern
        ORDER BY Priority ASC
    ) ym
)

-- OUTER SELECT: reference computed columns directly
SELECT
    Head,
    Unit,
    Team,
    Brand,
    PairedTrailer,
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
    Eta,
    URStatus,
    LastLocation,
    LastUpdate,
    AssignedYard,
    SbuoStatus,
    OE,
    OpsRemarks,
    GpsStatus,
    Trip,
    DriverTripStatus,
    TripTesting,
    ForRescue,
    JORemarks,

    -- FJOAct: references URStatus directly from base — no logic duplication
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
WHERE Head NOT IN ('TEST-7777', 'ZHT 679') --Hidden for now, to be ask kay sir carlo
AND Team = 'SBUO-1A'
--AND Assignment LIKE 'Vasquez'
--where Assignment LIKE 'Vasquez'
--AND Team IS NOT NULL
--ORDER BY Assignment ASC;
GO


--BACKUP

        -- URStatus
CASE 
    -- 1. HIGHEST PRIORITY: The Rescue Override
    -- This ensures that if it's a Rescue, we don't care about Category yet
    WHEN jr.Location LIKE '%Rescue%' THEN
        CASE 
            WHEN jr.Jrstatus = 'Pending'
            AND jr.Requeststatus = 'Pending Acceptance' THEN 'FOR RESC'
            WHEN jr.Jrstatus <> 'Pending' AND jr.Jrstatus <> 'Done' THEN 'ON RESC'
            ELSE 'RESCUE-CHECK' -- Fallback for other rescue states
        END

    -- 2. SECOND PRIORITY: Static Units
    WHEN osv.Category IN ('IDLE', 'AVAILABLE', 'PRELOADED') THEN
        CASE
            WHEN UPPER(ISNULL(jo.Remarks,'')) LIKE '%WAITING FOR PARTS%' THEN 'WFP'
            WHEN ISNULL(jr.Jrnumber, '') = '' OR jr.Jrnumber = '-' THEN osv.Category
            WHEN jr.Jrstatus <> 'Pending' THEN
                CASE
                    WHEN jr.Jrstatus <> 'Done' THEN 'ON GOING'
                    ELSE 'NOT RELEASED'
                END
            ELSE 'APPROVED'
        END

    -- 3. THIRD PRIORITY: Active Trips
    WHEN osv.Category = 'ON TRIP' THEN 'ON TRIP'

    -- 4. FALLBACK
    ELSE 'IDLE'
END AS URStatus,

CASE
    -- OUTER IF: Matches your IF(REGEXMATCH(AC2:AC, "IDLE|AVAILABLE|PRELOADED"))
    WHEN osv.Category IN ('IDLE', 'AVAILABLE', 'PRELOADED') 
    THEN
        CASE
            -- 1st IFS Condition: H2:H = "Pending Acceptance"
            WHEN jr.Requeststatus = 'Pending Acceptance' 
            THEN 
                CASE 
                    WHEN jr.Location LIKE '%Rescue%' THEN 'FOR RESC'
                    -- Matches your IF(T2:T="", "OUTSIDE", "AT YARD")
                    WHEN ISNULL(ym.YardCode, '') = '' THEN 'OUTSIDE'
                    ELSE 'AT YARD'
                END

            -- 2nd IFS Condition: REGEXMATCH(UPPER(AE2:AE), "WAITING FOR PARTS")
            WHEN UPPER(ISNULL(jo.Remarks, '')) LIKE '%WAITING FOR PARTS%' 
            THEN 'WFP'

            -- 3rd IFS Condition: F2:F = "-"
            WHEN ISNULL(jr.Jrnumber, '') = '-' 
            THEN osv.Category

            -- 4th IFS Condition: F2:F <> "" (Has a JR Number)
            WHEN ISNULL(jr.Jrnumber, '') <> '' 
            THEN
                CASE
                    -- Matches IF(G2:G <> "Pending")
                    WHEN jr.Jrstatus <> 'Pending' 
                    THEN
                        CASE
                            WHEN jr.Location LIKE '%Rescue%' THEN 'ON RESC'
                            WHEN jr.Jrstatus LIKE '%On going%'       THEN 'ON GOING'
                            ELSE                                  'NOT RELEASED'
                        END
                    ELSE 'APPROVED'
                END

            -- Fallback for the inner IFS
            ELSE osv.Category 
        END

    -- OUTER ELSE: Matches your final ,"ON TRIP"
    WHEN osv.Category = 'ON TRIP' THEN 'ON TRIP'
    
    -- Final Fallback
    ELSE 'IDLE' 
END AS URStatusTEST,



ALTER VIEW [dbo].[vw_Truck_Data_Cement_Cargo] AS

-- CTEs
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
        -- FROM PREVIOUS GUIDE IMAGE
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

-- BASE CTE: all joins + computed columns done once
base AS (
    SELECT
        tr.Head,
        CONCAT(tr.Head, ' | ', tr.PlateNo)                      AS Unit,
        tr.Bu                                                    AS Team,
        tr.Brand,
        tr.PairedTrailer,
        tr.Assignment,
        jr.Jrnumber                                              AS JRNumber,
        jr.Jrstatus                                              AS JRStatus,
        jr.Requeststatus                                         AS Status,
        jr.Location,
        jr.Created                                               AS JRAge,
        jr.ApprovalTimestamp                                     AS ApprovalAge,
        jo.[Classification]                                      AS Tag,
        jo.Jonumber,
        jo.Activity,
        jo.Etr,
        NULL                                                     AS Eta,
        gps.LiveLocation                                         AS LastLocation,
        gps.LastUpdate,
        gps.GpsStat                                              AS GpsStatus,
        NULL                                                     AS AtYardTimeStamp,
        NULL                                                     AS TOAatYard,
        ym.YardCode                                              AS AssignedYard,
        -- Trip
        CASE                
            WHEN ops.DriverTripStatus IS NOT NULL
                THEN osv.Category
            ELSE 'IDLE'
        END AS Trip,
        ops.DriverTripStatus,--FOR DEBUG
        CASE
            WHEN osv.Category IS NULL THEN 'IDLE'
            ELSE osv.Category
        END AS TripTesting,--FOR DEBUG
        
        ops.LatestLsTripAssigned                                 AS OE,
        ops.Remarks                                              AS OpsRemarks,
        CONCAT(jo.Jonumber, ' - ', jo.Remarks)                   AS JORemarks,
        CASE
            WHEN jr.Location LIKE '%Rescue%'
            THEN CONCAT(jr.Jrnumber, ' - ', jr.Location)
            ELSE NULL
        END                                                      AS ForRescue,

        -- SbuoStatus
        CASE
            WHEN ops.DriverTripStatus IS NULL                    THEN NULL
            WHEN osv.Category IS NOT NULL                        THEN ops.DriverTripStatus
            ELSE                                                      'NO TRIP'
        END                                                      AS SbuoStatus,
    --URStatus
    CASE 
        -- 1st PRIORITY: GLOBAL RESCUE CHECK
        -- This handles FOR RESC and ON RESC regardless of the osv.Category
        WHEN UPPER(ISNULL(jr.Location, '')) LIKE '%RESCUE%' THEN
            CASE 
                WHEN jr.Requeststatus LIKE '%Pending Acceptance%' THEN 'FOR RESC'
                WHEN jr.Jrstatus NOT LIKE '%Pending%' AND jr.Jrstatus NOT LIKE '%Done%' THEN 'ON RESC'
                ELSE 'FOR RESC' -- Fallback if it's a Rescue location but status is still Pending
            END

        -- 2nd PRIORITY: WAITING FOR PARTS (Global Check)
        WHEN UPPER(ISNULL(jo.Remarks, '')) LIKE '%WAITING FOR PARTS%' THEN 'WFP'

        -- 3rd PRIORITY: STATIC FLEET LOGIC
        WHEN osv.Category IN ('IDLE', 'AVAILABLE', 'PRELOADED') THEN
            CASE
                WHEN jr.Requeststatus LIKE '%Pending Acceptance%' THEN 
                    CASE 
                        WHEN ISNULL(ym.YardCode, '') = '' THEN 'OUTSIDE'
                        ELSE 'AT YARD'
                    END
                
                WHEN ISNULL(jr.Jrnumber, '') IN ('', '-') THEN osv.Category
                ELSE 
                    CASE
                        WHEN jr.Jrstatus NOT LIKE '%Pending%' THEN
                            CASE
                                WHEN jr.Jrstatus NOT LIKE '%Done%' THEN 'ON GOING'
                                ELSE 'NOT RELEASED'
                            END
                        ELSE 'APPROVED'
                    END
            END

        -- 4th PRIORITY: ACTIVE FLEET
        WHEN osv.Category = 'ON TRIP' THEN 'ON TRIP'

        -- FINAL FALLBACK
        ELSE 'IDLE' 
    END AS URStatus

    FROM masterlist_tractor tr

    LEFT JOIN jr_list jr             ON tr.Head = jr.Head
                                    AND jr.Ur = 'Tractor'

    LEFT JOIN ranked_jo jo           ON jo.Jrn = jr.Jrnumber
                                    AND jo.rn = 1

    LEFT JOIN ranked_gps gps         ON tr.Head = gps.HeadNo
                                    AND gps.rn2 = 1

    LEFT JOIN fromsheet_os_idl ops   ON tr.Head = ops.Head

    -- OpsStatusValid joined once instead of correlated subqueries
    LEFT JOIN OpsStatusValid osv     ON osv.Status = ops.DriverTripStatus

    OUTER APPLY (
        SELECT TOP 1 YardCode
        FROM YardMapping
        WHERE gps.LiveLocation LIKE Pattern
        ORDER BY Priority ASC
    ) ym
)

-- OUTER SELECT: reference computed columns directly
SELECT
    Head,
    Unit,
    Team,
    Brand,
    PairedTrailer,
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
    Eta,
    URStatus,
    LastLocation,
    LastUpdate,
    AssignedYard,
    SbuoStatus,
    OE,
    OpsRemarks,
    GpsStatus,
    Trip,
    --DriverTripStatus,
    --TripTesting,
    ForRescue,
    JORemarks,

    -- FJOAct: references URStatus directly from base — no logic duplication
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
WHERE Head NOT IN ('TEST-7777', 'ZHT 679') --Hidden for now, to be ask kay sir carlo
AND Team = 'SBUO-1A'
--AND location = 'Rescue'
GO

--TESTING NEW BACKUP


WITH ranked_jo AS (
    SELECT
        Jrn, Jonumber, Activity, Etr, Location, 
        Remarks, [Classification], Modified,
        ROW_NUMBER() OVER (
            PARTITION BY Jrn
            ORDER BY Modified DESC
        ) AS rn
    FROM jo_list
)

SELECT 
tr.Id,
tr.head,
CONCAT(tr.Head, ' | ', tr.PlateNo)    as unit,
tr.Brand                   as brand,
l.Bo                       as paired_trailer,
tr.PlateNo                 as plate_no,
tr.Assignment              as assignment,
tr.Bu                      as team,

jr.Jrnumber                as jr_number,
jr.Jrstatus                as jr_status,
jr.Requeststatus           as request_status,
l.LiveLocation             as last_location,
l.LastUpdate               as last_update,

l.OE,
CAST(l.[OE Date] as DATE)  as oe_date,
l.GpsStatus                AS gps_status,
CASE 
	WHEN ur.Category IS NULL THEN 'IDLE'
	ELSE ur.Category
END AS trip_status

from masterlist_tractor tr

LEFT JOIN DISPATCH_APP_DMS.dbo.LiveDMSView_CEM l
	ON tr.head = l.Vehicle
	AND l.[Trip Status] NOT IN ('Served', 'Cancelled') 
	--AND l.[Trip Status] IS NOT NULL

LEFT JOIN urstat_ref ur 
	ON l.[Trip Status] = ur.Status

LEFT JOIN jr_list jr             
    ON tr.Head = jr.Head
    AND jr.Ur = 'Tractor'

WHERE tr.bu = 'SBUO-1A'
Order by Id asc;

--NEW TRUCK DATA \ ACCURATE

create view cement_truck_data as 

WITH ranked_jo AS (
    SELECT
        Jrn, Jonumber, Activity, Etr, Location, jostatus,
        Remarks, [Classification], Modified,
        ROW_NUMBER() OVER (
            PARTITION BY Jrn
            ORDER BY Modified DESC
        ) AS rn
    FROM SHAREPOINT_DATA.dbo.jo_list
)

SELECT 
    tr.Id,
    tr.head,
    CONCAT(tr.Head, ' | ', tr.PlateNo)    as unit,
    tr.Brand                   as brand,
    l.Bo                       as paired_trailer,
    tr.PlateNo                 as plate_no,
    tr.Assignment              as assignment,
    tr.Bu                      as team,

    CASE
        --WHEN tr.Assignment = 'SOLD' THEN 'SOLD'
        WHEN ur.Category IS NULL THEN 'IDLE'
        ELSE ur.Category
    END                        AS trip_status,

    jr.Jrnumber                as jr_number,
    jr.Jrstatus                as jr_status,
    jr.Requeststatus           as request_status,
    jr.location				   as jr_location,
    jr.created                 as jr_age,
    jr.ApprovalTimestamp       as jr_approval,

    jo.Jonumber				   as jo_number,
    jo.Jostatus				   as jo_status,
    jo.Activity                as jo_activity,
    jo.classification		   as jo_classification,
    CONCAT(jo.Jonumber, ' - ', jo.Remarks) AS jo_remarks,
    jo.etr,

    l.LiveLocation             as last_location,
    l.LastUpdate               as last_update,

    CASE
        WHEN jr.Location LIKE '%Rescue%'
        THEN CONCAT(jr.Jrnumber, ' - ', jr.Location)
        ELSE NULL
    END                        AS for_rescue,

    l.[Trip Status]            as sbuo_status,
    l.OE,
    CAST(l.[OE Date] as DATE)  as oe_date,
    l.GpsStatus                AS gps_status

from SHAREPOINT_DATA.dbo.masterlist_tractor tr

LEFT JOIN DISPATCH_APP_DMS.dbo.LiveDMSView_CEM l
	ON tr.head = l.Vehicle
	AND l.[Trip Status] NOT IN ('Served', 'Cancelled') 
	--AND l.[Trip Status] IS NOT NULL

LEFT JOIN SHAREPOINT_DATA.dbo.urstat_ref ur 
	ON l.[Trip Status] = ur.Status

LEFT JOIN SHAREPOINT_DATA.dbo.jr_list jr             
    ON tr.Head = jr.Head
    AND jr.Ur = 'Tractor'

LEFT JOIN ranked_jo jo
	ON jo.Jrn = jr.Jrnumber
    AND jo.rn = 1

WHERE tr.bu = 'SBUO-1A'
--and tr.Assignment = 'SOLD'
--Order by Id asc