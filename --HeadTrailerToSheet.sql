--HeadTrailerToSheet.sql


ALTER VIEW [dbo].[HeadToSheet] AS 

WITH LocationMapping AS (
    SELECT * FROM (VALUES 
        ('PORT',        '3054d48a-c9c9-f011-8543-7ced8db4a2d9'),
        ('LUGAIT',      'ef710c4c-7aca-f011-8543-7ced8db4a2d9'),
        ('DAVAO',       '6478a19d-27c5-f011-bbd2-7ced8db4a2d9'),
        ('CARGO',       'eff409a4-27c5-f011-bbd2-7ced8db4a2d9'),
        ('CEMENT',      'fff409a4-27c5-f011-bbd2-7ced8db4a2d9'),
        ('CAR CARRIER', 'e3100dbd-a4eb-f011-8406-7ced8de56630'),
        ('OTHERS',      '86d32968-e8f4-f011-8406-7ced8de56630')
    ) AS t(locationName, LOCATIONID)
),

GroupMapping AS (
    SELECT * FROM (VALUES 
        ('SBUO-2A',         '7b6533be-26cb-f011-8543-7ced8db4a2d9'),
        ('SBUO-2B',         'a1e5ddc5-26cb-f011-8543-7ced8db4a2d9'),
        ('PORT',            '95b37646-27cb-f011-8543-7ced8db4a2d9'),
        ('CARGO-2A',        '03207360-27cb-f011-8543-7ced8db4a2d9'),
        ('CARGO-3A',        '49981778-27cb-f011-8543-7ced8db4a2d9'),
        ('SBUO-3A',         '85dbd993-27cb-f011-8543-7ced8db4a2d9'),
        ('ZION',            'aa053dcb-29cb-f011-8543-7ced8db4a2d9'),
        ('J EXPRESS',       '9db79ed1-29cb-f011-8543-7ced8db4a2d9'),
        ('DAVAO',           '4da504e1-29cb-f011-8543-7ced8db4a2d9'),
        ('LUGAIT',          'd1d03be7-29cb-f011-8543-7ced8db4a2d9'),
        ('SBUO-1A',         '259302b8-27c5-f011-bbd2-7ced8db4a2d9'),
        ('SBUO-1B',         'd5fe86bf-27c5-f011-bbd2-7ced8db4a2d9'),
        ('SBUO-1C',         '50238dd1-27c5-f011-bbd2-7ced8db4a2d9'),
        ('SBUO-1D',         '64238dd1-27c5-f011-bbd2-7ced8db4a2d9'),
        ('CAR CARRIER',     '867ba1d4-a4eb-f011-8406-7ced8de56630'),
        ('ZION BUKIDNON',   '05edf7a8-56ec-f011-8406-7ced8de56630'),
        ('OTHERS',          '4b15f23b-2503-f111-8406-7ced8de56630')
    ) AS t(GroupName, GroupID)
)

SELECT 
    t.[Body Number] as Head,
    t.brand,
    t.[Plate Number],
    gm.GroupName AS Bu,
    lm.locationName AS Assignment,
    --t.remarks
    tp.TrailerBodyNumber AS Paired_trailer,
    t.[Body Number] AS Pair



FROM TRACTOR_2K_RECORD t

LEFT JOIN LocationMapping lm 
    ON t._crcc8_locationname_value = lm.LOCATIONID

LEFT JOIN GroupMapping gm
    ON t._crcc8_groupname_value = gm.GroupID

LEFT JOIN sr_truckpairs tp
    ON t.[Body Number] = tp.TractorBodyNumber

--WHERE gm.GroupName = 'SBUO-1A'

--ORDER BY t.[Body Number] asc
GO




USE [TMS_APP]
GO

/****** Object:  View [dbo].[TrailerToSheet]    Script Date: 21/04/2026 09:15:55 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



ALTER VIEW [dbo].[TrailerToSheet] AS

WITH LocationMapping AS (
    SELECT * FROM (VALUES 
        ('PORT',        '3054d48a-c9c9-f011-8543-7ced8db4a2d9'),
        ('LUGAIT',      'ef710c4c-7aca-f011-8543-7ced8db4a2d9'),
        ('DAVAO',       '6478a19d-27c5-f011-bbd2-7ced8db4a2d9'),
        ('CARGO',       'eff409a4-27c5-f011-bbd2-7ced8db4a2d9'),
        ('CEMENT',      'fff409a4-27c5-f011-bbd2-7ced8db4a2d9'),
        ('CAR CARRIER', 'e3100dbd-a4eb-f011-8406-7ced8de56630'),
        ('OTHERS',      '86d32968-e8f4-f011-8406-7ced8de56630')
    ) AS t(locationName, LOCATIONID)
),

GroupMapping AS (
    SELECT * FROM (VALUES 
        ('SBUO-2A',         '7b6533be-26cb-f011-8543-7ced8db4a2d9'),
        ('SBUO-2B',         'a1e5ddc5-26cb-f011-8543-7ced8db4a2d9'),
        ('PORT',            '95b37646-27cb-f011-8543-7ced8db4a2d9'),
        ('CARGO-2A',        '03207360-27cb-f011-8543-7ced8db4a2d9'),
        ('CARGO-3A',        '49981778-27cb-f011-8543-7ced8db4a2d9'),
        ('SBUO-3A',         '85dbd993-27cb-f011-8543-7ced8db4a2d9'),
        ('ZION',            'aa053dcb-29cb-f011-8543-7ced8db4a2d9'),
        ('J EXPRESS',       '9db79ed1-29cb-f011-8543-7ced8db4a2d9'),
        ('DAVAO',           '4da504e1-29cb-f011-8543-7ced8db4a2d9'),
        ('LUGAIT',          'd1d03be7-29cb-f011-8543-7ced8db4a2d9'),
        ('SBUO-1A',         '259302b8-27c5-f011-bbd2-7ced8db4a2d9'),
        ('SBUO-1B',         'd5fe86bf-27c5-f011-bbd2-7ced8db4a2d9'),
        ('SBUO-1C',         '50238dd1-27c5-f011-bbd2-7ced8db4a2d9'),
        ('SBUO-1D',         '64238dd1-27c5-f011-bbd2-7ced8db4a2d9'),
        ('CAR CARRIER',     '867ba1d4-a4eb-f011-8406-7ced8de56630'),
        ('ZION BUKIDNON',   '05edf7a8-56ec-f011-8406-7ced8de56630'),
        ('OTHERS',          '4b15f23b-2503-f111-8406-7ced8de56630')
    ) AS t(GroupName, GroupID)
)

SELECT 
	COALESCE(fb.[Body Number], br.[Body Number]) as Title, 

    /**CASE 
        WHEN (fb.remarks IN ('N/A', '')) 
          OR (br.remarks IN ('N/A', '')) 
        THEN tp.TrailerType
        ELSE COALESCE(fb.remarks, br.remarks)
    END AS Classification,**/

    CASE WHEN fb.trailertype = '0' THEN 'Long Trailer'
         WHEN fb.trailertype = '1' THEN 'Short Trailer'
         WHEN fb.trailertype = '3' THEN 'Car Carrier'
         WHEN br.trailertype LIKE '0%' THEN '3 Hoppers'
         WHEN br.trailertype LIKE '1%' THEN 'Jumbo'
    ELSE Null
    END AS Classification,

    CASE
        WHEN COALESCE(fb.axle, br.axle) = '0' THEN '2'
        WHEN COALESCE(fb.axle, br.axle) = '1' THEN '3'
        WHEN COALESCE(fb.axle, br.axle) = '2' THEN '4'
        ELSE NULL
    END AS Axle,

    CASE
        WHEN br.subengine = ''
        THEN NULL
        ELSE br.subengine
    END as [Sub-Engine],
    
    COALESCE(gm.GroupName, tp.GroupName) AS BU,

    CASE
        WHEN COALESCE(fb.[Plate Number], br.[Plate Number]) IN( '', 'N/A' )
        THEN NULL
        ELSE COALESCE(fb.[Plate Number], br.[Plate Number])
    END AS [Plate No],

	COALESCE( tp.Location, lm.locationName )AS Assignment,

    tp.TractorBodyNumber AS Paired_With,
	tp.TrailerBodyNumber AS Pair

FROM FLATBED_RECORD fb

FULL OUTER JOIN BULK_RECORD br
	ON fb.[Body Number] = br.[Body Number]

LEFT JOIN sr_truckpairs tp
	ON tp.TrailerBodyNumber = COALESCE(fb.[Body Number], br.[Body Number])

LEFT JOIN LocationMapping lm 
    ON COALESCE (fb._crcc8_locationname_value, br._crcc8_locationname_value) = lm.LOCATIONID

LEFT JOIN GroupMapping gm
    ON COALESCE (fb._crcc8_locationname_value, br._crcc8_locationname_value) = gm.GroupID


--WHERE tp.GroupName is not null

--ORDER BY Title asc
GO


