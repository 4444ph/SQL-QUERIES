--truck cargo data
--not finished 

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
)


select
	mt.Head,
	mt.Bu                                                    as Team,
	mt.Assignment,
	mt.Brand,
	mtr.Bu                                                   as Paired_Trailer,
    jr.Jrnumber                                              AS JR_Number,
    jr.Jrstatus                                              AS JR_Status,
    jr.Requeststatus                                         AS Request_Status,
    jr.Location                                              AS Repair_Location,
    DATEDIFF(HOUR, jr.Created, GETDATE())                    AS JR_Age,

    CAST(DATEDIFF(HOUR, TRY_CAST(jr.ApprovalTimestamp AS DATETIME), GETDATE()) AS INT) AS Approval_Age,

    jo.Classification                                        AS Tag,
    jo.Jonumber                                              AS JO_Number,
    jo.Activity                                              AS JO_Activity,
    jo.Etr,
    NULL                                                     AS Eta,
    --gps.LiveLocation                                         AS LastLocation,
    CASE WHEN gps.LiveLocation IS NULL THEN 'No Location'
         WHEN gps.LiveLocation LIKE '%N/A%' THEN 'No Location'
         ELSE gps.LiveLocation
    END AS Last_Location,
    --gps.LastUpdate,
    CASE 
        WHEN gps.LastUpdate LIKE '% %' 
          OR gps.LastUpdate LIKE '%N/A%' THEN NULL
        ELSE gps.LastUpdate
    END AS Last_Update,
    gps.GpsStat                                              AS GpsStatus,
    NULL                                                     AS AtYardTimeStamp,
    NULL                                                     AS TOAatYard,
    ym.YardCode                                              AS AssignedYard

from masterlist_tractor mt

left join masterlist_trailer mtr
	ON mt.PairedTrailer = mtr.PairedWith

LEFT JOIN jr_list jr
    ON mt.Head = jr.Head
    AND jr.Ur = 'Tractor'

LEFT JOIN ranked_jo jo           
    ON jo.Jrn = jr.Jrnumber
    AND jo.rn = 1

LEFT JOIN ranked_gps gps
    ON mt.Head = gps.HeadNo
    AND gps.rn2 = 1

    OUTER APPLY (
            SELECT TOP 1 YardCode
            FROM YardMapping
            WHERE gps.LiveLocation LIKE Pattern
            ORDER BY Priority ASC
        ) ym
where mt.bu LIKE '%CARGO%'



WITH RankedAttendance AS (
    SELECT
        [Oe],
        [Employeename],
        [Attendancedetail],
        [Modified],
        ROW_NUMBER() OVER (
            PARTITION BY [Employeename] 
            ORDER BY [Modified] DESC
        ) AS rn
    FROM [SHAREPOINT_DATA].[dbo].[gsdc_attendance]
    WHERE [Position] = 'Driver'
      --AND [OE] IS NOT NULL
)

SELECT 
    ra.[Oe],
    ra.[Employeename],
    ra.[Attendancedetail],
    ra.[Modified],
    ra.rn,
    dp.Businessunit,
    dp.HrAppLastName,
    CONCAT(dp.HrAppLastName, ', ', dp.HrAppFirstName, ' ', dp.HrAppMiddleName) as FullName

FROM RankedAttendance ra

left join driver_probitionary dp
    ON ra.Employeename = CONCAT(dp.HrAppLastName, ', ', dp.HrAppFirstName, ' ', dp.HrAppMiddleName)
    where rn = 1
    AND dp.Businessunit LIKE '%CARGO%'
    --group by Employeename
    --order by Employeename asc





WITH LatestDriverData AS (
    SELECT
        -- Driver info from driver_probitionary
        CONCAT(dp.HrAppLastName, ', ', dp.HrAppFirstName)           AS Driver,
        dp.Businessunit                                             AS BU,

        -- Attendance from driver_probitionary
        dp.Dstatus                                                  AS AttendanceDetail,
        dp.Modified                                                 AS AttendanceDate,

        -- _tripstatus
        CASE
            WHEN UPPER(ISNULL(dp.Dstatus, '')) LIKE '%PRESENT%'
                THEN am_present.TruckStatus
            WHEN ISNULL(dp.Dstatus, '') <> ''
                THEN am.TruckStatus
            ELSE 'IDLE'
        END                                                         AS _tripstatus,

        -- _DRVstatus1
        CASE
            WHEN UPPER(ISNULL(dp.Dstatus, '')) LIKE '%PRESENT%'
                THEN am_present.DriverStatus1
            WHEN ISNULL(dp.Dstatus, '') <> ''
                THEN am.DriverStatus1
            ELSE 'ABSENT'
        END                                                         AS _DRVstatus1,

        -- _DRVstatus2
        CASE
            WHEN UPPER(ISNULL(dp.Dstatus, '')) LIKE '%PRESENT%'
                THEN am_present.DriverStatus2
            WHEN ISNULL(dp.Dstatus, '') <> ''
                THEN am.DriverStatus2
            ELSE 'ABSENT'
        END                                                         AS _DRVstatus2,
        
        -- Generate the Row Number to find the latest 'Modified' date per driver
        ROW_NUMBER() OVER (
            PARTITION BY dp.HrAppLastName, dp.HrAppFirstName 
            ORDER BY dp.Modified DESC
        )                                                           AS rn

    FROM driver_probitionary dp
    -- MAKE SURE TO PUT YOUR JOINS FOR 'am' AND 'am_present' RIGHT HERE
    -- LEFT JOIN ... am ON ...
    -- LEFT JOIN ... am_present ON ...

    LEFT JOIN AttendanceMapping am_present
                                    ON am_present.OpsStatus = 'PRESENT'

-- Map attendance: exact match on Dstatus
    LEFT JOIN AttendanceMapping am      ON am.OpsStatus = UPPER(dp.Dstatus)

    WHERE ISNULL(dp.HrAppLastName, '') <> ''
    AND ISNULL(dp.HrAppFirstName, '') <> ''

)
-- Select everything from the CTE, but only grab Row 1 (the latest date)
SELECT 
    *
FROM LatestDriverData
WHERE rn = 1;




--CARGO DRIVER ATTENDANCE AND TRIP STATUS
WITH RankedAttendance AS (
    SELECT
        ga.[Oe],
        ga.[Position],
        ga.[Employeename],
        ga.[Sd],
        ga.[Attendancedetail],
        ga.[Modified], -- Keep the raw date here
        
        /* This creates a ranking for each driver's history */
        ROW_NUMBER() OVER (
            PARTITION BY [Employeename] 
            ORDER BY [Modified] DESC
        ) AS rn
    FROM [SHAREPOINT_DATA].[dbo].[gsdc_attendance] ga
    WHERE [Position] = 'Driver'
      --AND [OE] IS NOT NULL
)

SELECT
    ra.*,
    CONCAT(dp.HrAppLastName, ', ', dp.HrAppFirstName, ' ', dp.HrAppMiddleName) as FullName,
    dp.Businessunit as Team
FROM RankedAttendance ra

left join driver_probitionary dp
    ON ra.Employeename = CONCAT(dp.HrAppLastName, ', ', dp.HrAppFirstName, ' ', dp.HrAppMiddleName)

where ra.rn = 1
    and dp.Businessunit LIKE '%CARGO%'
    and dp.HrAppEmploymentStatus = 'Regular'



-- backup 
    -- =LET(
    -- header, {"Tractor","Trailer","Team based on TMS"},

    -- head, FILTER({'FOR LOOK UP - HEAD MASTERLIST'!D2:D,IF('FOR LOOK UP - HEAD MASTERLIST'!M2:M<>"",'FOR LOOK UP - HEAD MASTERLIST'!M2:M,"-"),'FOR LOOK UP - HEAD MASTERLIST'!G2:G},'FOR LOOK UP - HEAD MASTERLIST'!D2:D<>""),

    -- trailer, FILTER({IF('FOR LOOK UP - CEMENT TRAILER'!N2:N<>"",'FOR LOOK UP - CEMENT TRAILER'!N2:N,"-"),'FOR LOOK UP - CEMENT TRAILER'!A2:A,'FOR LOOK UP - CEMENT TRAILER'!G2:G},'FOR LOOK UP - CEMENT TRAILER'!A2:A<>""),

    -- comb, {head;trailer},
    -- sort_h, ARRAYFORMULA(IF(INDEX(comb,,2)<>"-",1,0)),
    -- sort_t, ARRAYFORMULA(IF(INDEX(comb,,1)<>"-",1,0)),

    -- unit_list, {ARRAY_CONSTRAIN(SORT(UNIQUE({comb,sort_h,sort_t}),5,0,4,0),ROWS(comb),3)},
    -- head_bo, {INDEX(unit_list,,1),INDEX(unit_list,,2)},

    -- header_sbuo, {"Driver","Helper","Team","Trip Status","Attendance","Assigned Trip","Remarks","Last Updated","Paired Trailer based on Ops"},
    -- range_sbuo, {'FOR LOOK UP - SBUO MONITORING'!D2:D,'FOR LOOK UP - SBUO MONITORING'!E2:E,'FOR LOOK UP - SBUO MONITORING'!P2:P,'FOR LOOK UP - SBUO MONITORING'!N2:N,'FOR LOOK UP - SBUO MONITORING'!O2:O,'FOR LOOK UP - SBUO MONITORING'!M2:M,'FOR LOOK UP - SBUO MONITORING'!K2:K,'FOR LOOK UP - SBUO MONITORING'!L2:L,'FOR LOOK UP - SBUO MONITORING'!F2:F},

    -- select,TEXTJOIN(",", TRUE, ARRAYFORMULA("Col" & SEQUENCE(1, COLUMNS(range_sbuo), 2, 1))),

    -- data, BYROW(FILTER(head_bo,INDEX(head_bo,,1)<>""), LAMBDA(x, 
    --    IFERROR( INDEX(QUERY({'FOR LOOK UP - SBUO MONITORING'!A2:A,range_sbuo},"SELECT "&select&" WHERE Col1 = '"&INDEX(x,1,1)&"'",0),1,),
    --    IFERROR( INDEX(QUERY({'FOR LOOK UP - SBUO MONITORING'!B2:B,range_sbuo},"SELECT "&select&" WHERE Col1 = '"&INDEX(x,1,2)&"'",0),1,),
    --      ))
    -- )),
    -- driver_no_truck, SORT( QUERY({'FOR LOOK UP - SBUO MONITORING'!A2:A,range_sbuo},"SELECT "&select&" WHERE Col1 = '' AND  (Col2 != '' OR Col3 != '')",0) ,1,1),


    -- comb_header, {header,header_sbuo,"_sort"},
    -- datadata, {data; driver_no_truck},

    -- for_sort, ARRAYFORMULA(IF(INDEX(datadata,,1)<>"",1,0)+IF(INDEX(datadata,,2)<>"",1,0)),

    -- F_DATA,IFERROR( HSTACK(unit_list, datadata, for_sort), "-" ),

    -- VSTACK(comb_header,F_DATA)
    -- )

--count
    -- WITH test as (

    -- select
    -- 	oe,
    -- 	employeename,
    -- 	sd,
    -- 	AttendanceDetail,
    -- 	MAX(modified) as LastModified,
    -- 	count(*) as total
    -- FROM [gsdc_attendance]
    -- where position = 'Driver'
    -- GROUP BY employeename, oe, sd, Attendancedetail
    -- --ORDER BY employeename asc
    -- )

    -- select 
    -- t.*,

    -- dp.Businessunit,
    -- CONCAT(dp.HrAppLastName, ', ', dp.HrAppFirstName, ' ', dp.HrAppMiddleName)  as HrFullName


    -- from test t
    -- Left join driver_probitionary dp
    --     ON t.Employeename =        CONCAT(dp.HrAppLastName, ', ', dp.HrAppFirstName, ' ', dp.HrAppMiddleName)  
    -- where dp.Businessunit LIKE '%CARGO%'
    -- and dp.HrAppEmploymentStatus = 'Regular'
    -- ORDER BY employeename asc
    -- --COUNT


--BACKUP
WITH RankedAttendance AS (
    SELECT
        [Oe],
        [Employeename],
        [Attendancedetail],
        [Modified],
        ROW_NUMBER() OVER (
            PARTITION BY [Employeename] 
            ORDER BY [Modified] DESC
        ) AS rn
    FROM [SHAREPOINT_DATA].[dbo].[gsdc_attendance]
    WHERE [Position] = 'Driver'
      --AND [OE] IS NOT NULL
)

select ra.* from RankedAttendance ra
where ra.rn = 1
and ra.Modified >= '2026-01-01 00:00:00'
order by ra.modified desc


--BACKUP
WITH RankedAttendance AS (
    SELECT
        [Oe],
        [Employeename],
        [Attendancedetail],
        [Modified],
        ROW_NUMBER() OVER (
            PARTITION BY [Employeename] 
            ORDER BY [Modified] DESC
        ) AS rn
    FROM [SHAREPOINT_DATA].[dbo].[gsdc_attendance]
    WHERE [Position] = 'Driver'
      --AND [OE] IS NOT NULL
)

SELECT 
    ra.[Oe],
    ra.[Employeename],
    ra.[Attendancedetail],
    ra.[Modified],
    ra.rn,
    dp.Businessunit,
    dp.HrAppLastName,
    CONCAT(dp.HrAppLastName, ', ', dp.HrAppFirstName, ' ', dp.HrAppMiddleName) as FullName

FROM RankedAttendance ra

left join driver_probitionary dp
    ON ra.Employeename = CONCAT(dp.HrAppLastName, ', ', dp.HrAppFirstName, ' ', dp.HrAppMiddleName)

where rn = 1
--AND dp.Businessunit LIKE '%CAR%'
--group by Employeename
AND dp.HrAppEmploymentStatus = 'Regular'
and dp.HrAppLastName LIKE '%Ferrer%'
order by Modified desc