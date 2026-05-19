--CreatedTables.sql

CREATE TABLE LawAccountManagement (
    [UserID] INT IDENTITY(1,1) PRIMARY KEY, -- Auto-incrementing unique ID
    [FirstName] NVARCHAR(100) NOT NULL,
    [LastName] NVARCHAR(100) NOT NULL,
    [EmailAddress] NVARCHAR(255) NOT NULL UNIQUE, -- UNIQUE prevents duplicate emails
    [Password] NVARCHAR(MAX) NOT NULL,       -- Storing "Hash", never plain text
    [Role] NVARCHAR(50) DEFAULT 'User',         -- Matches your dropdown default
    [IsActive] BIT DEFAULT 1,                   -- 1 for active, 0 for deactivated
    [CreatedAt] DATETIME DEFAULT GETDATE(),     -- Auto-timestamp
    [LastModified] DATETIME DEFAULT GETDATE()   -- For your Audit logic
);


CREATE TABLE [dbo].[PMSOdometerLogs] (
    [ID] INT IDENTITY(1,1) PRIMARY KEY,        -- Auto-increments starting at 1
    [TIMESTAMP] DATETIME2(7),                   -- DEFAULT GETDATE(), Automatically captures current time
    [HEAD_NO] NVARCHAR(50) NOT NULL,           -- e.g., 'H-2002'
    [PLATE_NO] NVARCHAR(15),                   -- Vehicle Plate Number
    [BRAND] NVARCHAR(20),                      -- e.g., 'Isuzu', 'Hino'
    [BU] NVARCHAR(15),                         -- Business Unit
    [AREA_ASSIGNMENT] NVARCHAR(100),           -- Assignment Location
    [OLD_VALUE] DECIMAL(10, 2),                -- Previous Odometer Reading
    [NEW_VALUE] DECIMAL(10, 2)                 -- New Odometer Reading
);



--EmployeeAttendanceStatus
SELECT
    p.Driverfname AS 'FirstName',
    p.Driverlname AS 'LastName',
    CONCAT(p.DriverLname, ' ', p.DriverFname) AS 'FullName',
    p.DriverStatus,

CASE 
    WHEN (p.DriverStatus IN ('Absent', 'Suspended')
    OR p.DriverStatus LIKE 'present%' 
    )THEN 'Inactive'

    WHEN p.DriverStatus LIKE '%Leave' THEN 'On Leave'
    ELSE 'Active'
END AS DeploymentStatus

FROM driver_probitionary p

CREATE TABLE [dbo].[sr_truckoperationslogs] (
    [sr_truckoperationslogid] UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    [Action] NVARCHAR(50),
    [VehicleType] NVARCHAR(50),
    [BodyNumber] NVARCHAR(100),
    [PlateNumber] NVARCHAR(100),
    [FromLocation] NVARCHAR(200),
    [ToLocation] NVARCHAR(200),
    [FromGroup] NVARCHAR(100),
    [ToGroup] NVARCHAR(100),
    [PairedWithBodyNumber] NVARCHAR(100),
    [PairedWithType] NVARCHAR(50),
    [Notes] NVARCHAR(500),
    [createdon] DATETIME DEFAULT GETDATE(),
    [modifiedon] DATETIME,
    [_modifiedby_value] NVARCHAR(100),
    [ModifiedByName] NVARCHAR(100)
);
GO


CREATE TABLE [dbo].[CementForecastSales] (
    [ForecastID] INT IDENTITY(1,1) PRIMARY KEY, -- Unique ID for each entry
    [ASM] NVARCHAR(100),                          -- Area Sales Manager
    [ClientName] NVARCHAR(200),
    [DeliveryType] NVARCHAR(50),                  -- e.g., Pick-up or Door-to-Door
    [CementBrand] NVARCHAR(100),                  -- e.g., Republic, Holcim
    [Forecast] DECIMAL(12, 0),                    -- Planned Quantity
    [TotalTrips] INT DEFAULT 0,
    [TotalQTYDelivered] DECIMAL(12, 0) DEFAULT 0,
    [TotalQTYWithdrawn] DECIMAL(12, 0) DEFAULT 0,
    [CementType] NVARCHAR(50),                    -- e.g., Type 1, Type 1P
    [Destination] NVARCHAR(255),
    [Remarks] NVARCHAR(500), --PAKI ADD MAMAYA
    [CreatedDate] DATETIME DEFAULT GETDATE(),
    [ModifiedDate] DATETIME(0) 
);
GO

CREATE TABLE HeadPMSLastODO (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    Head NVARCHAR(100) NOT NULL,
    Odo DECIMAL(12, 2) NOT NULL,
    CreatedAt DATETIME DEFAULT GETDATE()
);


--MTD_Grouped_ASM

CREATE TABLE CementAuditSummary (
    -- Primary Key
    AuditID INT IDENTITY(1,1) PRIMARY KEY,

    -- Categorization & Path
    [ASM] NVARCHAR(150),
    [Client Name] NVARCHAR(255) NOT NULL,
    [Source Name] NVARCHAR(255),
    [Destination Name] NVARCHAR(255),
    [Cement Brand] NVARCHAR(150),
    [Cement Type] NVARCHAR(100),
    [Delivery Group] NVARCHAR(100),

    -- Metrics (Using Decimal for high precision weight/qty)
    [Total Trips Delivered] INT DEFAULT 0,
    [Total Qty Withdrawn] DECIMAL(12, 2) DEFAULT 0,
    [Total Qty Delivered] DECIMAL(12, 2) DEFAULT 0,
    [Discrepancy] DECIMAL(12, 2) DEFAULT 0,

    -- Reference Info
    [Latest Delivery #] NVARCHAR(50),
    [Last Delivery Date] DATETIME2(0),
    [Days Since Delivery] INT,

    -- SAP Specific References
    [Latest ORDR DocNum] INT,
    [Latest OE Number] NVARCHAR(100),
    [Latest SO Create Date] DATETIME2(0),
    [Latest SO Doc Date] DATETIME2(0),

    -- Metadata
    [LastUpdated] DATETIME2(0) DEFAULT GETDATE()
);



--WAIT FOR APPROVAL

CREATE TABLE CH_Life_Gospel_Attendance (
    [Id] NVARCHAR(60),
    [Date] NVARCHAR(16),
    [No] NVARCHAR(10),
    [Column] NVARCHAR(35),
    [Column_2] NVARCHAR(60),
    [Column_3] NVARCHAR(50),
    [0] NVARCHAR(50),
    [0_2] NVARCHAR(50),
    [0_3] NVARCHAR(50),
    [0_4] NVARCHAR(50),
    [3] NVARCHAR(50),
    [0_5] NVARCHAR(50),
    [0_6] NVARCHAR(50),
    [CampusMeeting0] NVARCHAR(50),
    [JypMeeting0] NVARCHAR(50),
    [Prophesying0] NVARCHAR(50),
    [YpMeeting0] NVARCHAR(50)
);


--SALESAPP
CREATE TABLE DashboardAccountManager (
    [Id] INT IDENTITY(1,1) PRIMARY KEY,
    [Firstname] NVARCHAR(100) NOT NULL,
    [Lastname] NVARCHAR(100) NOT NULL,
    [Username] NVARCHAR(50) NOT NULL UNIQUE,
    [Password] NVARCHAR(MAX) NOT NULL, -- Stored as MAX to accommodate hashed strings
    [Email] NVARCHAR(255) NOT NULL UNIQUE,
    [Role] NVARCHAR(50) DEFAULT 'User',
    [CreatedAt] DATETIME2(0) DEFAULT GETDATE(),
    [ModifiedAt] DATETIME2(0) DEFAULT 
);


CREATE TABLE Vehicle_Inspection (
    ControlNumber VARCHAR(255) PRIMARY KEY,
    HeadNo VARCHAR(50),
    Inspector VARCHAR(100),
    InspectionType VARCHAR(50),
    ScanTime DATETIME2(0),
    SubmitTime DATETIME2(0),
    Duration INT,        -- Or INT if you are storing total minutes/seconds
    PhotoFront VARBINARY(MAX),     -- Assumes storing file paths or URLs for the photos
    PhotoBack VARBINARY(MAX),
    PhotoLeft VARBINARY(MAX),
    PhotoRight VARBINARY(MAX),
    PhotoInside VARBINARY(MAX),
    ORCR VARCHAR(50),            -- Could be BIT/BOOLEAN if it's just a Pass/Fail check
    ORCR_Rmk VARCHAR(255),
    LTFRB VARCHAR(115),
    LTFRB_Rmk VARCHAR(255),
    Odometer INT,                -- Assumes whole numbers for mileage
    Odometer_Rmk VARCHAR(255),
    HubOdo INT,
    HubOdo_Rmk VARCHAR(255),
    FuelLevel INT,       -- e.g., 'Full', 'Half', or DECIMAL if storing exact percentages
    Battery INT,
    Battery_Rmk VARCHAR(255),
    SpareTires INT,              -- Assumes a count of spare tires
    SpareTires_Rmk VARCHAR(255),
    Padlock BOOLEAN,         -- Could be BIT/BOOLEAN (1 = Yes/Present, 0 = No/Missing)
    PushCart BOOLEAN,        -- Could be BIT/BOOLEAN
    GasTankCap BOOLEAN,      -- Could be BIT/BOOLEAN
    GPSStatus VARCHAR(50)
);

CREATE TABLE jr_list_done (
    JRNumber VARCHAR(40) PRIMARY KEY,
    CreatedBy VARCHAR(40),
    DriverName VARCHAR(60),
    HeadNumber VARCHAR(40),
    TrailerNumber VARCHAR(40),
    JRStatus VARCHAR(20),
    DateCreated DATETIME2(0),

    BUEffective VARCHAR(80),
    UR2 VARCHAR(255),
    UR3 VARCHAR(255),
    UR4 VARCHAR(255),
    UR5 VARCHAR(255),
    JRCreator VARCHAR(80),
    Note NVARCHAR(MAX),
    DateTime DATETIME2(0),
    Driver VARCHAR(80),
    Head VARCHAR(40),

    Trailer VARCHAR(80),
    Odometer INT,
    RequestStatus VARCHAR(100),
    PriorityLevel VARCHAR(100),
    Location VARCHAR(255),
    UR VARCHAR(255),
    TeamID VARCHAR(100),
    BusinessUnit VARCHAR(80),

    [ApprovalTimestamp] DATETIME2(0),
    [RejectedTimestamp] DATETIME2(0),
    [RejectedRemarks] NVARCHAR(MAX),
    Creator VARCHAR(80),
    CancelledBy VARCHAR(80),

    ReleaseStamp DATETIME2(0),
    Valet VARCHAR(80),
    ReleaseRemarks NVARCHAR(MAX),
    Done DATETIME2(0),
    ReleasedBy VARCHAR(80),
    RescueLocation VARCHAR(255),
    [ContactNumber] NVARCHAR(50),

    Modified DATETIME2(0),
    Head_TMS VARCHAR(40),
    [Head_TMS_Title] VARCHAR(60),
    [Head_TMS_BU] VARCHAR(60),
    Trailer_TMS VARCHAR(40),
    [Trailer_TMS_BU] VARCHAR(60),

    MaintenanceRemarks NVARCHAR(MAX),
    Created DATETIME2(0),
    FleetGroup VARCHAR(80),
    ID INT,
    [Created By] VARCHAR(80),
    [Modified By] VARCHAR(80)
);

--PANG ATTENDANCE_APP CHLIFEYEAH
-- 1. Table for Halls and Districts
CREATE TABLE hall_x_district (
    id INT IDENTITY(1,1) PRIMARY KEY,
    code NVARCHAR(50) UNIQUE NOT NULL,
    description NVARCHAR(MAX)
);

-- 2. Table for Age Group definitions
CREATE TABLE age_group (
    id INT IDENTITY(1,1) PRIMARY KEY,
    group_name NVARCHAR(100) NOT NULL,
    min_age INT,
    max_age INT,
    color NVARCHAR(50)
);

-- 3. Table for Identity Types
CREATE TABLE identify_type (
    id INT IDENTITY(1,1) PRIMARY KEY,
    name NVARCHAR(100) UNIQUE NOT NULL
);

-- 4. Table for Year Levels
CREATE TABLE year_level (
    id INT IDENTITY(1,1) PRIMARY KEY,
    year_level NVARCHAR(100) NOT NULL,
    min_age INT,
    max_age INT
);

-- 5. Table for Meeting Types
CREATE TABLE meeting_type (
    id INT IDENTITY(1,1) PRIMARY KEY,
    abbreviation NVARCHAR(20) UNIQUE NOT NULL,
    description NVARCHAR(255),
    day NVARCHAR(20) -- e.g., 'Monday', 'Tuesday'
);

-- 6. Table for Small Group Meeting Schedules
CREATE TABLE meeting_sched_small_group (
    id INT IDENTITY(1,1) PRIMARY KEY,
    type NVARCHAR(100),
    contact_person NVARCHAR(255),
    day NVARCHAR(20),
    time TIME,
    venue NVARCHAR(255),
    face_to_face BIT DEFAULT 1 -- 1 for True/Yes, 0 for No
);

-- 7. Table for Prayer Meeting Schedules
CREATE TABLE meeting_sched_prayer_meeting (
    id INT IDENTITY(1,1) PRIMARY KEY,
    type NVARCHAR(100),
    contact_person NVARCHAR(255),
    day NVARCHAR(20),
    time TIME,
    venue NVARCHAR(255),
    face_to_face BIT DEFAULT 1
);

CREATE TABLE [dbo].[VehicleMasterdata] (
    -- Primary Key for unique identification
    [SQLId] INT IDENTITY(1,1) PRIMARY KEY, 
    -- Your specific columns
    [SourceId] INT NULL,
    [Head] NVARCHAR(50) NOT NULL, -- Usually the main identifier (e.g., Body No)
    [PlateNo] NVARCHAR(100),
    [Brand] NVARCHAR(100),
    [PairedTrailer] NVARCHAR(100),
    [BU] NVARCHAR(100),            -- Business Unit
    [Assignment] NVARCHAR(50),
    [Modified] DATETIME2(0)
);


--logs salesapp
-- 1. Create the Login Logs Table
CREATE TABLE login_logs (
    log_Id INT IDENTITY(1,1) NOT NULL,
    UserId INT NOT NULL,
    LoginTime DATETIME2(0) NOT NULL DEFAULT GETDATE(),
    LogoutTime DATETIME2(0) NULL,
    CONSTRAINT PK_login_logs PRIMARY KEY (log_Id)
);

-- 2. Create the Access Logs Table
CREATE TABLE access_logs (
    al_Id INT IDENTITY(1,1) NOT NULL,
    UserId INT NOT NULL,
    AccessTime DATETIME2(0) NOT NULL DEFAULT GETDATE(),
    PageAccessed NVARCHAR(255) NOT NULL,
    CONSTRAINT PK_access_logs PRIMARY KEY (al_Id)
);

-- 3. Optional: Add Foreign Keys 
-- (Assuming your main table is named DashboardAccountManager)
ALTER TABLE login_logs 
ADD CONSTRAINT FK_Login_User FOREIGN KEY (UserId) REFERENCES DashboardAccountManager(Id);

ALTER TABLE access_logs 
ADD CONSTRAINT FK_Access_User FOREIGN KEY (UserId) REFERENCES DashboardAccountManager(Id);


CREATE TABLE [dbo].[UnitStatuses] (
    [StatusID] INT PRIMARY KEY,
    [StatusName] NVARCHAR(50) NOT NULL
);

INSERT INTO [dbo].[UnitStatuses] ([StatusID], [StatusName])
VALUES 
    (0, 'Running'),
    (1, 'Condemn'),
    (2, 'Sold'),
    (3, 'Others'),
    (4, 'Available'),
    (5, 'Rental'),
    (6, 'Under'),
    (7, 'Old Unit In Ic'),
    (8, 'Joint Ventures'),
    (9, 'N/A'),
    (10, 'Old Unit'),
    (11, 'Sold With Terms'),
    (12, 'Unassigned');

--SERVERLOGS

-- Historical: raw snapshot every 15 minutes
CREATE TABLE dbo.ServerLogsHistorical (
    Id                  INT IDENTITY(1,1)   PRIMARY KEY,
    CapturedAt          DATETIME2           NOT NULL DEFAULT GETDATE(),
    DatabaseName        NVARCHAR(128)       NOT NULL,
    PhysicalName        NVARCHAR(260)       NOT NULL,
    NumOfReads          BIGINT              NOT NULL,
    IoStallReadMs       BIGINT              NOT NULL,
    AvgReadMs           BIGINT              NOT NULL,
    NumOfWrites         BIGINT              NOT NULL,
    IoStallWriteMs      BIGINT              NOT NULL,
    AvgWriteMs          BIGINT              NOT NULL
)
GO

-- Summary: all-time cumulative per database + file
CREATE TABLE dbo.ServerLogsSummary (
    Id                  INT IDENTITY(1,1)   PRIMARY KEY,
    DatabaseName        NVARCHAR(128)       NOT NULL,
    PhysicalName        NVARCHAR(260)       NOT NULL,
    TotalReads          BIGINT              NOT NULL DEFAULT 0,
    TotalIoStallReadMs  BIGINT              NOT NULL DEFAULT 0,
    TotalWrites         BIGINT              NOT NULL DEFAULT 0,
    TotalIoStallWriteMs BIGINT              NOT NULL DEFAULT 0,
    AvgReadMsAllTime    BIGINT              NOT NULL DEFAULT 0,
    AvgWriteMsAllTime   BIGINT              NOT NULL DEFAULT 0,
    SnapshotCount       INT                 NOT NULL DEFAULT 0,
    FirstCapturedAt     DATETIME2           NOT NULL DEFAULT GETDATE(),
    LastCapturedAt      DATETIME2           NOT NULL DEFAULT GETDATE(),
    CONSTRAINT UQ_ServerIO_Summary UNIQUE (DatabaseName, PhysicalName)
)
GO

CREATE PROCEDURE dbo.usp_CaptureServerIO
AS
BEGIN
    SET NOCOUNT ON

    -- Step 1: capture current snapshot
    DECLARE @snapshot TABLE (
        DatabaseName    NVARCHAR(128),
        PhysicalName    NVARCHAR(260),
        NumOfReads      BIGINT,
        IoStallReadMs   BIGINT,
        AvgReadMs       BIGINT,
        NumOfWrites     BIGINT,
        IoStallWriteMs  BIGINT,
        AvgWriteMs      BIGINT
    )

    INSERT INTO @snapshot
    SELECT
        DB_NAME(vfs.database_id)                        AS DatabaseName,
        mf.physical_name                                AS PhysicalName,
        vfs.num_of_reads                                AS NumOfReads,
        vfs.io_stall_read_ms                            AS IoStallReadMs,
        CASE
            WHEN vfs.num_of_reads = 0 THEN 0
            ELSE vfs.io_stall_read_ms / vfs.num_of_reads
        END                                             AS AvgReadMs,
        vfs.num_of_writes                               AS NumOfWrites,
        vfs.io_stall_write_ms                           AS IoStallWriteMs,
        CASE
            WHEN vfs.num_of_writes = 0 THEN 0
            ELSE vfs.io_stall_write_ms / vfs.num_of_writes
        END                                             AS AvgWriteMs
    FROM sys.dm_io_virtual_file_stats(NULL, NULL) vfs
    JOIN sys.master_files mf
        ON vfs.database_id = mf.database_id
        AND vfs.file_id    = mf.file_id

    -- Step 2: insert into Historical
    INSERT INTO dbo.ServerLogsHistorical (
        CapturedAt, DatabaseName, PhysicalName,
        NumOfReads, IoStallReadMs, AvgReadMs,
        NumOfWrites, IoStallWriteMs, AvgWriteMs
    )
    SELECT
        GETDATE(),
        DatabaseName, PhysicalName,
        NumOfReads, IoStallReadMs, AvgReadMs,
        NumOfWrites, IoStallWriteMs, AvgWriteMs
    FROM @snapshot

    -- Step 3: upsert into Summary (MERGE)
    MERGE dbo.ServerLogsSummary AS target
    USING @snapshot AS source
        ON target.DatabaseName = source.DatabaseName
        AND target.PhysicalName = source.PhysicalName

    WHEN MATCHED THEN UPDATE SET
        target.TotalReads           = target.TotalReads          + source.NumOfReads,
        target.TotalIoStallReadMs   = target.TotalIoStallReadMs  + source.IoStallReadMs,
        target.TotalWrites          = target.TotalWrites         + source.NumOfWrites,
        target.TotalIoStallWriteMs  = target.TotalIoStallWriteMs + source.IoStallWriteMs,
        target.AvgReadMsAllTime     = CASE
                                        WHEN (target.TotalReads + source.NumOfReads) = 0 THEN 0
                                        ELSE (target.TotalIoStallReadMs + source.IoStallReadMs)
                                             / (target.TotalReads + source.NumOfReads)
                                      END,
        target.AvgWriteMsAllTime    = CASE
                                        WHEN (target.TotalWrites + source.NumOfWrites) = 0 THEN 0
                                        ELSE (target.TotalIoStallWriteMs + source.IoStallWriteMs)
                                             / (target.TotalWrites + source.NumOfWrites)
                                      END,
        target.SnapshotCount        = target.SnapshotCount + 1,
        target.LastCapturedAt       = GETDATE()

    WHEN NOT MATCHED THEN INSERT (
        DatabaseName, PhysicalName,
        TotalReads, TotalIoStallReadMs,
        TotalWrites, TotalIoStallWriteMs,
        AvgReadMsAllTime, AvgWriteMsAllTime,
        SnapshotCount, FirstCapturedAt, LastCapturedAt
    )
    VALUES (
        source.DatabaseName, source.PhysicalName,
        source.NumOfReads, source.IoStallReadMs,
        source.NumOfWrites, source.IoStallWriteMs,
        source.AvgReadMs, source.AvgWriteMs,
        1, GETDATE(), GETDATE()
    );

END
GO

USE msdb
GO

EXEC sp_add_job
    @job_name = N'Capture Server IO Stats'

EXEC sp_add_jobstep
    @job_name   = N'Capture Server IO Stats',
    @step_name  = N'Run usp_CaptureServerIO',
    @command    = N'EXEC server_logs.dbo.usp_CaptureServerIO',
    @database_name = N'server_logs'

EXEC sp_add_schedule
    @schedule_name      = N'Every 15 Minutes',
    @freq_type          = 4,        -- Daily
    @freq_interval      = 1,
    @freq_subday_type   = 4,        -- Minutes
    @freq_subday_interval = 15

EXEC sp_attach_schedule
    @job_name       = N'Capture Server IO Stats',
    @schedule_name  = N'Every 15 Minutes'

EXEC sp_add_jobserver
    @job_name = N'Capture Server IO Stats'
GO

