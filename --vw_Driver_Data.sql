--vw_Driver_Data

WITH ranked_jo AS (
    SELECT
        Jrn, Jonumber, Activity, Etr, Location, 
        Remarks, [Classification], Modified, Jostatus,
        ROW_NUMBER() OVER (
            PARTITION BY Jrn
            ORDER BY Modified DESC
        ) AS rn
    FROM jo_list
),

OpsStatusValid AS (
    SELECT v.Status, v.Category FROM (VALUES
        ('AWAITING TRIP',           'AVAILABLE'),
        ('DRIVER PREPAIRING',       'DRIVER PREPAIRING'),
        ('DRIVER AVAILABLE',        'DRIVER AVAILABLE'),
        ('REST',                    'REST'),
        ('VACATION LEAVE',          'VACATION LEAVE'),
        ('SICK LEAVE',              'SICK LEAVE'),
        ('ABSENT',                  'ABSENT'),
        ('SUSPENDED',               'SUSPENDED'),
        ('HOLD',                    'HOLD'),
        ('UR AVAILABLE DRIVER',     'UR AVAILABLE DRIVER'),
        ('UR REST',                 'UR REST'),
        ('UR ABSENT',               'UR ABSENT'),
        ('AWOL ALERT',              'AWOL ALERT'),
        ('FOR RESCUE',              'FOR RESCUE'),
        ('ITG',                     'RUNNING'),
        ('EMS',                     'RUNNING'),
        ('ITD',                     'RUNNING'),
        ('WTL',                     'RUNNING'),
        ('LDN',                     'RUNNING'),
        ('ULD',                     'RUNNING'),
        ('LDS',                     'RUNNING'),
        ('LDD',                     'RUNNING'),
        ('LDG',                     'RUNNING'),
        ('ITR',                     'RUNNING'),
        ('WTU',                     'RUNNING'),
        ('ITS',                     'RUNNING')
    ) AS v(Status, Category)
)
SELECT 
	tr.Head					AS Tractor,
	tr.PairedTrailer		AS Trailer,
	tr.Bu					AS TeamBasedOnTMS,
	o.Driver,
	o.Helper,
	o.Team,
    osv.Category            AS TripStatus,
	--o.DriverTripStatus			AS TripStatus,
	o.DriverStatus2			AS Attendance,
	o.LatestLsTripAssigned	AS AssignedTrip,
	o.Remarks,
	o.LastUpdate,
	NULL					AS PairedTrailerBasedOnOps,
	td.URStatus				AS TractorURStatus,
	td.JRStatus				AS TractorJRStatus,
	trd.JRNumber			AS TrailerJRStatus,

	-- This converts the text to a date and finds the difference in HOURS
	DATEDIFF(HOUR, TRY_CONVERT(DATETIME, o.LastUpdate), GETDATE()) AS StatusAgeHours,
    
	jo.Jostatus				AS TractorUrStatus2,
	trd.Trip			    AS TrailerUrStatus2		

FROM masterlist_tractor tr

LEFT JOIN fromsheet_os_idl o ON tr.Head = o.Head

LEFT JOIN vw_Truck_Data_Cement_Cargo td ON tr.Head = td.Head

LEFT JOIN vw_Trailer_Data trd ON tr.PairedTrailer = trd.Bo

LEFT JOIN ranked_jo jo ON jo.Jrn = td.JRNumber AND jo.rn = 1

LEFT JOIN OpsStatusValid osv ON o.DriverTripStatus = osv.Status

WHERE o.Driver IS NOT NULL
AND o.Team = 'SBUO-1A'
GO


