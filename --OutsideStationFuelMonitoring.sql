--OutsideStationFuelMonitoring

CREATE View OutsideStationFuelMonitoring AS 

SELECT
	f.created as Date,
	f.Driversname as [Driver Name],
	f.Stationdepot as [Station Depot],
	f.Head as [Head Number],
	f.Tankponumber as [Tank PO Number],
	f.Compressorponumber as [Compressor PO Number],
	f.Addblueponumber as [AdBlue PO Number],
	f.Fctchangedepotstation as [FCT Changed Depot Station],
	f.TotalloadedlitersTank as [Total Loaded Liters],
	f.TotalpriceforloadedlitersTank as [Total Price For Loaded Liters Tank],
	f.TotalloadedlitersCompressor as [Total Loaded liters Compressor],
	f.TotalpriceforloadedlitersCompressor as [Total Price for Loaded Liters Compressor],
	f.TotalloadedlitersAddblue AS [Total Loaded Liters AdBlue],
	f.TotalpriceforloadedlitersAddblue as [Total Price for Loaded Liters AdBlue],
	f.Plate,
	f.Frstatus as [Fr Status],
	f.Tsissuance as [Issuance Date],
	f.Tsliquidation as [Liquidation Date]

	FROM fctFinal f

	INNER JOIN tbl_ref_stations s 
		ON f.Stationdepot = s.StationName 
	WHERE s.IsSelected = 1




ALTER VIEW [dbo].[OutsideStationFuelMonitoring]
AS
SELECT        
f.Created AS Date, 
f.Stationdepot AS [Station Depot], 
f.Head AS [Head Number], 
f.Plate, 
f.Driversname AS [Driver Name], 
f.Frstatus AS [Fr Status], 
f.Tankponumber AS [Tank PO Number],

f.TotalloadedlitersTank AS [Total Loaded Liters Tank],
f.TotalpriceforloadedlitersTank AS [Total Price For Loaded Liters Tank], 

f.Compressorponumber AS [Compressor PO Number], 
--f.Addblueponumber AS [AdBlue PO Number], 
--f.Fctchangedepotstation AS [FCT Changed Depot Station], 
 
f.TotalloadedlitersCompressor AS [Total Loaded liters Compressor], 
f.TotalpriceforloadedlitersCompressor AS [Total Price for Loaded Liters Compressor],

--f.TotalloadedlitersAddblue AS [Total Loaded Liters AdBlue], 
--f.TotalpriceforloadedlitersAddblue AS [Total Price for Loaded Liters AdBlue], 
f.Tsissuance AS [Issuance Date], 
f.Tsliquidation AS [Liquidation Date],
f.Modified,
f.SQLID

FROM dbo.fctFinal AS f 
INNER JOIN dbo.tbl_ref_stations AS s ON f.Stationdepot = s.StationName
WHERE (s.IsSelected = 1)
AND Created >= '2026-01-01 00:00:00'
GO




--CHECK STATIONS:
WITH fctStation AS (
SELECT 
	Fctchangedepotstation,
	COUNT(*) as total
  FROM [FCT_Reporting].[dbo].[fctFinal]
  GROUP BY Fctchangedepotstation
  --ORDER BY Fctchangedepotstation desc
  )

select 
sf.Fctchangedepotstation,
sf.total,
r.StationName
from fctStation sf

FULL OUTER JOIN tbl_ref_stations r
	ON sf.Fctchangedepotstation = r.StationName 
		WHERE r.IsSelected = 1

--ORDER BY r.StationName asc

ORDER BY 
    CASE WHEN sf.Fctchangedepotstation IS NULL THEN 1 ELSE 0 END, -- NULLs get 1, others get 0
    sf.Fctchangedepotstation ASC;


