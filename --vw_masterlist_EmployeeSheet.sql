--vw_[masterlist_EmployeeSheet]

/****** Object:  View [dbo].[masterlist_EmployeeSheet]    Script Date: 14/04/2026 15:22:00 ******/

SELECT

    -- A: DP FullName
    TRIM(dp.Driverlname) + ', ' + TRIM(dp.Driverfname)                     AS DP_FullName,

    -- B: DP BU
    dp.Businessunit                                                          AS DP_BU,

    -- C: HR FullName Short (LastName, FirstName)
    TRIM(hr.LastName) + ', ' + TRIM(hr.FirstName)                           AS HR_FullName,

    -- D: HR FullName Full (LastName, FirstName MiddleName)
    CASE
        WHEN TRIM(hr.LastName) = '' OR hr.LastName IS NULL THEN ''
        ELSE TRIM(hr.LastName) + ', ' + TRIM(hr.FirstName) + ' ' + TRIM(hr.MiddleName)
    END                                                                      AS HR_FullName_Full,

    -- E: HR Employment Status
    hr.EmploymentStatus                                                      AS HR_EmploymentStatus,

    -- F: HR ID
    TRIM(hr.Id)                                                      AS HR_ID,

    -- G: HP ID
    hp.Hrid                                                                  AS HP_ID,

    -- H: HP BU
    hp.BusinessUnit                                                          AS HP_BU,

    -- I: HR Position
    hr.Position                                                              AS HR_Position,

    -- J: Employer
    hr.Employer                                                              AS Employer,

    -- K: D HR BU (XLOOKUP: HR FullName → DP FullName → DP BU)
    dp.Businessunit                                                          AS D_HR_BU,

    -- L: H HR BU (XLOOKUP: HR ID → HP ID → HP BU)
    hp.BusinessUnit                                                          AS H_HR_BU,

    -- M: DL Expiry
    hr.Driverslicenseexpdate                                                 AS DL_Expiry,

    -- N: DRIVER (HR FullName if active driver)
    CASE
        WHEN hr.Position = 'Driver'
         AND hr.EmploymentStatus IN ('Regular', 'Probitionary', 'Employed')
         AND dp.Deploystatus IN ('Deployed', 'Undeployed')
         AND TRIM(ISNULL(dp.Businessunit, '')) <> ''
        THEN TRIM(hr.LastName) + ', ' + TRIM(hr.FirstName) + ' ' + TRIM(hr.MiddleName)
        ELSE NULL
    END                                                                      AS Driver,

    -- O: Driver_BU
    CASE
        WHEN hr.Position = 'Driver'
         AND hr.EmploymentStatus IN ('Regular', 'Probitionary', 'Employed')
         AND dp.Deploystatus IN ('Deployed', 'Undeployed')
         AND TRIM(ISNULL(dp.Businessunit, '')) <> ''
        THEN dp.Businessunit
        ELSE NULL
    END                                                                      AS Driver_BU,

    -- P: HELPER (HR FullName if active helper)
    CASE
        WHEN hr.Position = 'Helper'
         AND hr.EmploymentStatus IN ('Regular', 'Probitionary', 'Employed')
        THEN TRIM(hr.LastName) + ', ' + TRIM(hr.FirstName) + ' ' + TRIM(hr.MiddleName)
        ELSE NULL
    END                                                                      AS Helper,

    -- Q: Helper_BU
    CASE
        WHEN hr.Position = 'Helper'
         AND hr.EmploymentStatus IN ('Regular', 'Probitionary', 'Employed')
        THEN hp.BusinessUnit
        ELSE NULL
    END                                                                      AS Helper_BU,

    -- S: DRIVER DL EXPIRY
    CASE
        WHEN hr.Position = 'Driver'
         AND hr.EmploymentStatus IN ('Regular', 'Probitionary', 'Employed')
         AND dp.Deploystatus IN ('Deployed', 'Undeployed')
         AND TRIM(ISNULL(dp.Businessunit, '')) <> ''
        THEN hr.Driverslicenseexpdate
        ELSE NULL
    END                                                                      AS Driver_DL_Expiry,

    -- T: DL STATUS
    CASE
        WHEN hr.Driverslicenseexpdate IS NULL
          OR TRIM(hr.Driverslicenseexpdate) = ''        THEN ''
        WHEN TRY_CAST(hr.Driverslicenseexpdate AS DATE)
           < CAST(GETDATE() AS DATE)                    THEN 'EXPIRED'
        ELSE                                                 'VALID'
    END                                                                      AS DL_Status,

    -- U: DRIVER EMPLOYER
    CASE
        WHEN hr.Position = 'Driver'
         AND hr.EmploymentStatus IN ('Regular', 'Probitionary', 'Employed')
         AND dp.Deploystatus IN ('Deployed', 'Undeployed')
         AND TRIM(ISNULL(dp.Businessunit, '')) <> ''
        THEN hr.Employer
        ELSE NULL
    END                                                                      AS Driver_Employer,

    -- V: HELPER EMPLOYER
    CASE
        WHEN hr.Position = 'Helper'
         AND hr.EmploymentStatus IN ('Regular', 'Probitionary', 'Employed')
        THEN hr.Employer
        ELSE NULL
    END                                                                      AS Helper_Employer,

    -- Y: DP Deploy Status
    dp.Deploystatus                                                          AS DP_DeployStatus,

    -- Z: D HR Deploy Status
    dp.Deploystatus                                                          AS D_HR_DeployStatus

FROM       [SHAREPOINT_DATA].[dbo].[masterlist_gsdcemployee]  hr

LEFT JOIN  [SHAREPOINT_DATA].[dbo].[driver_probitionary]      dp
        ON TRIM(hr.LastName + ', ' + hr.FirstName)
         = TRIM(dp.Driverlname + ', ' + dp.Driverfname)

LEFT JOIN  [SHAREPOINT_DATA].[dbo].[helper]                   hp
        ON TRIM(hr.Id)
         = TRIM(hp.Hrid)
GO


