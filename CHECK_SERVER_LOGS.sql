-- Run once manually to verify
--EXEC dbo.usp_CaptureServerIO

-- Check Historical
SELECT TOP 10 * FROM dbo.ServerLogsHistorical ORDER BY CapturedAt DESC

-- Check Summary
SELECT * FROM dbo.ServerLogsSummary ORDER BY AvgWriteMsAllTime DESC