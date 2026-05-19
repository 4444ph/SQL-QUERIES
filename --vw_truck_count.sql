--CREATE VIEW [dbo].[vw_StatusCount] AS

WITH Counts AS (

    SELECT 
        UrStatus,
        Fjoact,
        'Truck'                         AS Source,
        COUNT(DISTINCT Unit)            AS Count
    FROM vw_Truck_Data_Cement_Cargo
    WHERE UrStatus IS NOT NULL
    AND Assignment = 'VASQUEZ'
    GROUP BY UrStatus, Fjoact

    UNION ALL

    SELECT 
        UrStatus,
        Fjoact,
        'Trailer'                       AS Source,
        COUNT(DISTINCT Unit)            AS Count
    FROM vw_Trailer_Data
    WHERE UrStatus IS NOT NULL
    AND Assignment = 'VASQUEZ'
    GROUP BY UrStatus, Fjoact

    UNION ALL

    SELECT 
        TripStatus                      AS UrStatus,
        NULL                            AS Fjoact,
        'Driver'                        AS Source,
        COUNT(*)                        AS Count
    FROM vw_Driver_Data
    WHERE TripStatus IS NOT NULL
    GROUP BY TripStatus
)

SELECT
    s.UrStatus,
    ISNULL(SUM(CASE WHEN c.Source = 'Truck'    THEN c.Count END), 0)   AS TruckCount,
    ISNULL(SUM(CASE WHEN c.Source = 'Trailer'  THEN c.Count END), 0)   AS TrailerCount,
    ISNULL(SUM(CASE WHEN c.Source = 'Driver'   THEN c.Count END), 0)   AS DriverCount,
    -- FJOAct breakdown — condition simplified, UrStatus check removed (Fjoact only exists on ON GOING rows)
    ISNULL(SUM(CASE WHEN c.Source = 'Truck'    AND c.Fjoact = 'Start'  THEN c.Count END), 0) AS Truck_ONGOING_Start,
    ISNULL(SUM(CASE WHEN c.Source = 'Truck'    AND c.Fjoact = 'Pause'  THEN c.Count END), 0) AS Truck_ONGOING_Pause,
    ISNULL(SUM(CASE WHEN c.Source = 'Truck'    AND c.Fjoact = 'Resume' THEN c.Count END), 0) AS Truck_ONGOING_Resume,
    ISNULL(SUM(CASE WHEN c.Source = 'Trailer'  AND c.Fjoact = 'Start'  THEN c.Count END), 0) AS Trailer_ONGOING_Start,
    ISNULL(SUM(CASE WHEN c.Source = 'Trailer'  AND c.Fjoact = 'Pause'  THEN c.Count END), 0) AS Trailer_ONGOING_Pause,
    ISNULL(SUM(CASE WHEN c.Source = 'Trailer'  AND c.Fjoact = 'Resume' THEN c.Count END), 0) AS Trailer_ONGOING_Resume

FROM (VALUES
    ('IDLE'), ('AVAILABLE'), ('PRELOADED'), ('ON TRIP'),
    ('AT YARD'), ('OUTSIDE'), ('APPROVED'), ('FOR RESC'),
    ('ON GOING'), ('WFP'), ('NOT RELEASED'), ('ON RESC'),
    ('RUNNING'), ('DRIVER PREPAIRING'), ('DRIVER AVAILABLE'),
    ('FOR RESCUE'), ('UR AVAILABLE DRIVER'), ('UR REST'),
    ('REST'), ('UR ABSENT'), ('ABSENT'), ('SICK LEAVE'),
    ('SUSPENDED'), ('VACATION LEAVE'), ('HOLD'), ('AWOL ALERT')
) AS s(UrStatus)

LEFT JOIN Counts c ON s.UrStatus = c.UrStatus

GROUP BY s.UrStatus

GO