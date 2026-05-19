--Trip Mapping
OpsStatusValid AS (
    SELECT v.Status, v.Category FROM (VALUES
        ('AWAITING TRIP',        'AVAILABLE'),
        ('DRIVER PREPAIRING',    'DRIVER PREPAIRING'),
        ('DRIVER AVAILABLE',     'DRIVER AVAILABLE'),
        ('REST',                 'REST'),
        ('VACATION LEAVE',       'VACATION LEAVE'),
        ('SICK LEAVE',           'SICK LEAVE'),
        ('ABSENT',               'ABSENT'),
        ('SUSPENDED',            'SUSPENDED'),
        ('HOLD',                 'HOLD'),
        ('UR AVAILABLE DRIVER',  'UR AVAILABLE DRIVER'),
        ('UR REST',              'UR REST'),
        ('UR ABSENT',            'UR ABSENT'),
        ('AWOL ALERT',           'AWOL ALERT'),
        ('FOR RESCUE',           'FOR RESCUE'),
        ('ITG',                  'RUNNING'),
        ('EMS',                  'RUNNING'),
        ('ITD',                  'RUNNING'),
        ('WTL',                  'RUNNING'),
        ('LDN',                  'RUNNING'),
        ('ULD',                  'RUNNING'),
        ('LDS',                  'RUNNING'),
        ('LDD',                  'RUNNING'),
        ('LDG',                  'RUNNING'),
        ('ITR',                  'RUNNING'),
        ('WTU',                  'RUNNING'),
        ('ITS',                  'RUNNING')
    ) AS v(Status, Category)



    (IDLE, AVAILABLE, PRELOADED, ON TRIP, AT YARD, OUTSIDE, APPROVED, 
    FOR RESCUE, ON GOING, WFP, NOT RELEASED, ON RESC)




--FOR DEV

-- Create config schema
CREATE SCHEMA config --DEFAULT dbo DO NOT CREATE THIS YET.
GO

-- Yard pattern mapping table
CREATE TABLE config.YardMapping (
    Priority    INT             NOT NULL,
    Pattern     NVARCHAR(200)   NOT NULL,
    YardCode    NVARCHAR(50)    NOT NULL,
    CONSTRAINT PK_YardMapping PRIMARY KEY (Priority)
)
GO

CREATE TABLE dbo.YardMapping (
    Priority    INT             NOT NULL,
    Pattern     NVARCHAR(200)   NOT NULL,
    YardCode    NVARCHAR(50)    NOT NULL,
    CONSTRAINT PK_YardMapping PRIMARY KEY (Priority)
)
GO

-- for URSTATUS truck and trailer = status category mapping table
CREATE TABLE config.URStatus (
    Status      NVARCHAR(100)   NOT NULL,
    Category    NVARCHAR(50)    NOT NULL,
    CONSTRAINT PK_URStatus PRIMARY KEY (Status)
)
GO

CREATE TABLE dbo.URStatus (
    Status      NVARCHAR(100)   NOT NULL,
    Category    NVARCHAR(50)    NOT NULL,
    CONSTRAINT PK_URStatus PRIMARY KEY (Status)
)
GO

INSERT INTO dbo.YardMapping (Priority, Pattern, YardCode) VALUES
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
    (51, '%--No Loc%',                      'Vas'),
    -- Option C catch-all fallbacks
    (99,  '%Philippines%',                  'Unknown'),
    (100, '%,%',                            'Unknown')
GO


INSERT INTO dbo.URStatus (Status, Category) VALUES
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
    ('UITS',                 'ON TRIP'),
    -- Option E: explicit unmapped catch-all
    ('DEFAULT',              'UNMAPPED')
GO

-- EXAMPLE INSERT QUERY 

--INSERT NEW LOCATION MAPPING
INSERT INTO dbo.YardMapping VALUES (52, '%New Location%', 'Vas')
--INSERT NEW STATUS MAPPING
INSERT INTO dbo.URStatus VALUES ('NEW STATUS', 'ON TRIP')
