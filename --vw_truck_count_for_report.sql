--vw_truck_count_for_report
WITH Counts AS (

    -- Truck counts
    SELECT 
        Team,
        LTRIM(RTRIM(UrStatus)) AS UrStatus,
        'Truck' AS Source,
        COUNT(DISTINCT Unit) AS Count
    FROM dbo.vw_Truck_Data_Cement_Cargo 
    WHERE UrStatus IS NOT NULL
    GROUP BY Team, LTRIM(RTRIM(UrStatus))

    UNION ALL

    -- Trailer counts
    SELECT 
        Team,
        LTRIM(RTRIM(UrStatus)) AS UrStatus,
        'Trailer' AS Source,
        COUNT(DISTINCT Unit) AS Count
    FROM dbo.vw_Trailer_Data
    WHERE UrStatus IS NOT NULL
    GROUP BY Team, LTRIM(RTRIM(UrStatus))

    UNION ALL

    -- Driver counts
    SELECT 
        Team,
        LTRIM(RTRIM(TripStatus)) AS UrStatus,
        'Driver' AS Source,
        COUNT(*) AS Count
    FROM dbo.vw_Driver_Data
    WHERE TripStatus IS NOT NULL
    GROUP BY Team, LTRIM(RTRIM(TripStatus))
),

Teams AS (
    SELECT DISTINCT Team FROM dbo.vw_Truck_Data_Cement_Cargo
    UNION
    SELECT DISTINCT Team FROM dbo.vw_Trailer_Data
    UNION
    SELECT DISTINCT Team FROM dbo.vw_Driver_Data
),

FilteredTeams AS (
    SELECT Team
    FROM Teams
    WHERE Team IN (
        'SBUO-1A',
        'SBUO-1B',
        'SBUO-1C',
        'SBUO-1D',
        'SBUO-2A',
        'SBUO-3A',
        'TM'
    )
),

StatusList AS (
    SELECT 'IDLE' AS UrStatus UNION ALL
    SELECT 'AVAILABLE' UNION ALL
    SELECT 'PRELOADED' UNION ALL
    SELECT 'ON TRIP' UNION ALL
    SELECT 'AT YARD' UNION ALL
    SELECT 'OUTSIDE' UNION ALL
    SELECT 'APPROVED' UNION ALL
    SELECT 'FOR RESC' UNION ALL
    SELECT 'ON GOING' UNION ALL
    SELECT 'WFP' UNION ALL
    SELECT 'NOT RELEASED' UNION ALL
    SELECT 'ON RESC' UNION ALL
    SELECT 'RUNNING' UNION ALL
    SELECT 'DRIVER PREPAIRING' UNION ALL
    SELECT 'DRIVER AVAILABLE' UNION ALL
    SELECT 'FOR RESCUE' UNION ALL
    SELECT 'UR AVAILABLE DRIVER' UNION ALL
    SELECT 'UR REST' UNION ALL
    SELECT 'REST' UNION ALL
    SELECT 'UR ABSENT' UNION ALL
    SELECT 'ABSENT' UNION ALL
    SELECT 'SICK LEAVE' UNION ALL
    SELECT 'SUSPENDED' UNION ALL
    SELECT 'VACATION LEAVE' UNION ALL
    SELECT 'HOLD' UNION ALL
    SELECT 'AWOL ALERT'
)

SELECT 
    CASE 
        WHEN GROUPING(t.Team) = 1 THEN 'GRAND TOTAL'
        ELSE t.Team
    END AS Team,

    CASE 
        WHEN GROUPING(t.Team) = 0 AND GROUPING(s.UrStatus) = 1 THEN 'TOTAL'
        WHEN GROUPING(t.Team) = 1 AND GROUPING(s.UrStatus) = 1 THEN 'GRAND TOTAL'
        ELSE s.UrStatus
    END AS UrStatus,

    ISNULL(SUM(CASE WHEN c.Source = 'Truck' THEN c.Count END), 0) AS TruckCount,
    ISNULL(SUM(CASE WHEN c.Source = 'Trailer' THEN c.Count END), 0) AS TrailerCount,
    ISNULL(SUM(CASE WHEN c.Source = 'Driver' THEN c.Count END), 0) AS DriverCount

FROM FilteredTeams t
CROSS JOIN StatusList s
LEFT JOIN Counts c 
       ON c.Team = t.Team
      AND c.UrStatus = s.UrStatus

GROUP BY GROUPING SETS (
    (t.Team, s.UrStatus),
    (t.Team),
    ()
);
GO


