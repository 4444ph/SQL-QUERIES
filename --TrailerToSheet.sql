--TrailerToSheet

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

    CASE 
        WHEN (fb.remarks IN ('N/A', '')) 
          OR (br.remarks IN ('N/A', '')) 
        THEN tp.TrailerType
        ELSE COALESCE(fb.remarks, br.remarks)
    END AS Classification,

    NULL AS Axel,

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

ORDER BY Title asc