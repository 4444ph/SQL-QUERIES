
SELECT 
    CAST(t.[Body Number] as nvarchar(30)) as head,
    CAST(t.brand as nvarchar(30)) as brand,
    CAST(NULLIF(t.[Plate Number], '') as NVARCHAR(20)) as plate_no,    
    CAST(gu.groupName as nvarchar(30)) as bu,
    CAST(lu.locationName as nvarchar(30))as assignment,
    NULLIF(CAST(t.ordate AS DATE), '1900-01-01') AS or_expiry_date,
    CAST(t.status as INT) as status, --WILL BECOME status_Id
    CAST(CAST(NULLIF(t.endingnumber, '') AS DECIMAL(2,1)) AS INT) AS plate_ending_number,
    CAST(NULLIF(t.chassisnumber, '') as nvarchar(30)) as chassis_no,
    CAST(NULLIF(t.mvfileno, '' ) as nvarchar(30)) as mv_file_no,
    CAST(CAST(NULLIF(t.classification, '') AS DECIMAL(2,1)) AS INT) AS classification,

    --TRUCK MODEL
    CAST(
        CASE 
            WHEN TRIM(t.model) = '' THEN NULL
            WHEN TRIM(t.model) = 'N/A' THEN NULL
            ELSE t.model 
        END 
    AS NVARCHAR(30)) AS model,
   
    CAST(CAST(NULLIF(t.yearmodel, '') AS FLOAT) AS INT) AS year_model,

    --CAST(NULLIF(t.orcrname, ' ' )as nvarchar(30))as or_cr_name,
    CAST(
        CASE WHEN TRIM(t.orcrname) = '' THEN NULL
        WHEN TRIM(t.orcrname) = 'N/A' THEN NULL
        ELSE t.orcrname
    END AS nvarchar(30)) as orcr_name,

    --CAST(t.crdate as date) as cr_date,
    NULLIF(CAST(t.crdate AS DATE), '1900-01-01') AS cr_date,

    CAST(NULLIF(t.conductionnumber, 'N/A') as nvarchar(30)) as conduction_number,

    --t.enginenumber as engine_number,
    CAST(
         CASE WHEN t.enginenumber in ('5.05E+13', '5.05E+12') THEN NULL
         ELSE t.enginenumber
    END AS NVARCHAR(50)) as engine_number,
        
    CAST(NULLIF(LTRIM(RTRIM(t.stencil)), '') AS VARCHAR(10)) AS stencil,
    CASE 
        WHEN TRIM(t.remarks) IN ('', '#NAME?') THEN NULL
        ELSE TRIM(t.remarks)
    END AS remarks,

    --INSURANCE SECTION
    CAST(
        CASE 
            WHEN TRIM(t.tplname) IN ('', 'N/A') THEN NULL
            ELSE TRIM(t.tplname)
        END 
    AS NVARCHAR(30)) AS tpl_name,

    --t.tplnumber as tpl_number,
    CAST(
        CASE 
            WHEN TRIM(t.tplnumber) IN ('N/A', '1.10E+15', '') THEN NULL
            ELSE t.tplnumber
        END 
    AS NVARCHAR(50)) AS tpl_number,

    --CAST(t.tplexpdate as date)as tpl_exp_date,
    NULLIF(CAST(t.tplexpdate AS DATE), '1900-01-01') AS tpl_exp_date,
   
    --COMPRE SECTION
    CAST(
        CASE 
            WHEN TRIM(t.comprename) IN ('', 'N/A') THEN NULL
            ELSE TRIM(t.comprename)
        END 
    AS NVARCHAR(30)) AS compre_name,

    CASE 
        WHEN TRIM(t.comprenumber) IN ('', 'N/A', '1.15E+15', '1.10E+15') THEN NULL
        ELSE t.comprenumber
    END AS compre_num,

    NULLIF(CAST(t.compreexpdate AS DATE), '1900-01-01') AS compre_exp_date,
    
    --NULLIF(t.bank, '') as bank,
    CAST(
        CASE WHEN t.bank IN ('', 'N/A') THEN NULL
        ELSE t.bank
    END as nvarchar(20)) as bank,

    NULLIF(CAST(t.bankdue AS DATE), '1900-01-01') AS bank_due_date,

    CAST(
    CASE 
        WHEN TRIM(t.ltfrbnumber) IN ('', 'N/A') THEN NULL
        ELSE TRIM(t.ltfrbnumber)
        END AS NVARCHAR(30)) 
    as ltfrb_no,

    CAST(
        CASE 
        WHEN TRIM(t.ltfrbstatus) IN ('', 'N/A') THEN NULL
        ELSE TRIM(t.ltfrbstatus)
        END 
    AS NVARCHAR(50)) AS ltfrb_status,

    NULLIF(CAST(t.ltfrbexpdate AS DATE), '1900-01-01') AS ltfrb_exp_date
    
    --lgu.area, needs new table for this
    --lgu.expiration_date needs new table for this
    --rf.rfid_type, needs new table for this
    --rf.rfid_number
  


FROM TRACTOR_2K_RECORD t

LEFT JOIN tbl_LocationUnit lu 
    ON t._crcc8_locationname_value = lu.crcc8_tbl_locationunitid

LEFT JOIN tbl_GroupUnit gu
    ON t._crcc8_groupname_value = gu.crcc8_tbl_groupunitid

--LEFT JOIN TRACTOR_RFID rf --NEEDS OWN TABLE
--    on rf.crcc8_tractor2krecordid = t.crcc8_tractor2krecordid

--LEFT JOIN [TRACTOR_LGU] lgu -- NEEDS OWN TABLE
--    on lgu.crcc8_tractor2krecordid = t.crcc8_tractor2krecordid
    
--LEFT JOIN sr_truckpairs tp
--    ON t.[Body Number] = tp.TractorBodyNumber

--where rf.rfid_number IS NOT NULL
--where lgu.area is not null


--AI VERSION OF THE QUERY   
--t.stencil to has_stencil bit

--CREATE VIEW tms_truck_cleaned as 
--DO NOT RUN SAVE QUERY FOR NOW

SELECT 
    -- Core Identity / Asset Info
    CAST(t.[Body Number] AS NVARCHAR(30))                    AS head,
    CAST(t.brand AS NVARCHAR(30))                            AS brand,
    CAST(NULLIF(TRIM(t.[Plate Number]), '') AS NVARCHAR(20)) AS plate_no,    
    CAST(gu.groupName AS NVARCHAR(30))                       AS bu,
    CAST(lu.locationName AS NVARCHAR(30))                    AS assignment,
    CAST(t.status AS INT)                                    AS status_id, -- Standardized naming

    -- Numeric / Identification Formatting
    CAST(CAST(NULLIF(TRIM(t.endingnumber), '') AS DECIMAL(18,4)) AS INT)    AS plate_ending_number,
    CAST(NULLIF(TRIM(t.chassisnumber), '') AS NVARCHAR(30))                 AS chassis_no,
    CAST(NULLIF(TRIM(t.mvfileno), '') AS NVARCHAR(30))                      AS mv_file_no,
    CAST(CAST(NULLIF(TRIM(t.classification), '') AS DECIMAL(18,4)) AS INT)  AS classification,
    CAST(CAST(NULLIF(TRIM(t.yearmodel), '') AS FLOAT) AS INT)               AS year_model,

    -- Vehicle Model Block
    CAST(
        CASE 
            WHEN TRIM(t.model) IN ('', 'N/A') THEN NULL
            ELSE TRIM(t.model) 
        END 
    AS NVARCHAR(30)) AS model,

    -- Documentation Block
    CAST(
        CASE 
            WHEN TRIM(t.orcrname) IN ('', 'N/A') THEN NULL
            ELSE TRIM(t.orcrname)
        END 
    AS NVARCHAR(30)) AS orcr_name,

    NULLIF(CAST(t.ordate AS DATE), '1900-01-01') AS or_expiry_date,
    NULLIF(CAST(t.crdate AS DATE), '1900-01-01') AS cr_date,

    CAST(
        CASE 
            WHEN TRIM(t.conductionnumber) IN ('', 'N/A') THEN NULL
            ELSE TRIM(t.conductionnumber)
        END 
    AS NVARCHAR(30)) AS conduction_number,

    CAST(
         CASE 
            WHEN TRIM(t.enginenumber) IN ('', 'N/A', '5.05E+13', '5.05E+12') THEN NULL
            ELSE TRIM(t.enginenumber)
         END 
    AS NVARCHAR(50)) AS engine_number,
        
    --CAST(NULLIF(TRIM(t.stencil), '') AS VARCHAR(10)) AS stencil,
    CASE 
        WHEN TRIM(t.stencil) IN ('Yes', 'YES', 'Y', '1') THEN CAST(1 AS BIT)
        ELSE CAST(0 AS BIT)
    END AS has_stencil,

    CASE 
        WHEN TRIM(t.remarks) IN ('', '#NAME?') THEN NULL
        ELSE TRIM(t.remarks)
    END AS remarks,

    -- Insurance Section (TPL)
    CAST(
        CASE 
            WHEN TRIM(t.tplname) IN ('', 'N/A') THEN NULL
            ELSE TRIM(t.tplname)
        END 
    AS NVARCHAR(30)) AS tpl_name,

    CAST(
        CASE 
            WHEN TRIM(t.tplnumber) IN ('', 'N/A', '1.10E+15') THEN NULL
            ELSE TRIM(t.tplnumber)
        END 
    AS NVARCHAR(50)) AS tpl_number,

    NULLIF(CAST(t.tplexpdate AS DATE), '1900-01-01') AS tpl_exp_date,
   
    -- Insurance Section (Comprehensive)
    CAST(
        CASE 
            WHEN TRIM(t.comprename) IN ('', 'N/A') THEN NULL
            ELSE TRIM(t.comprename)
        END 
    AS NVARCHAR(30)) AS compre_name,

    CAST(
        CASE 
            WHEN TRIM(t.comprenumber) IN ('', 'N/A', '1.15E+15', '1.10E+15') THEN NULL
            ELSE TRIM(t.comprenumber)
        END 
    AS NVARCHAR(50)) AS compre_num,

    NULLIF(CAST(t.compreexpdate AS DATE), '1900-01-01') AS compre_exp_date,
    
    -- Financing & Bank Details
    CAST(
        CASE 
            WHEN TRIM(t.bank) IN ('', 'N/A') THEN NULL
            ELSE TRIM(t.bank)
        END 
    AS NVARCHAR(20)) AS bank,

    NULLIF(CAST(t.bankdue AS DATE), '1900-01-01') AS bank_due_date,

    -- LTFRB / Regulatory Block
    CAST(
        CASE 
            WHEN TRIM(t.ltfrbnumber) IN ('', 'N/A') THEN NULL
            ELSE TRIM(t.ltfrbnumber)
        END 
    AS NVARCHAR(30)) AS ltfrb_no,

    CAST(
        CASE 
            WHEN TRIM(t.ltfrbstatus) IN ('', 'N/A') THEN NULL
            ELSE TRIM(t.ltfrbstatus)
        END 
    AS NVARCHAR(50)) AS ltfrb_status,

    NULLIF(CAST(t.ltfrbexpdate AS DATE), '1900-01-01') AS ltfrb_exp_date

FROM TMS_APP.dbo.TRACTOR_2K_RECORD t

LEFT JOIN TMS_APP.dbo.tbl_LocationUnit lu 
    ON t._crcc8_locationname_value = lu.crcc8_tbl_locationunitid

LEFT JOIN TMS_APP.dbo.tbl_GroupUnit gu
    ON t._crcc8_groupname_value = gu.crcc8_tbl_groupunitid


--FOR TRAILER FIRST VIEW 

--CREATE VIEW TMS_TRAILER as 
SELECT 
    -- NUMERICS
    CAST(TRY_CAST(NULLIF([endingnumber], '') AS FLOAT) AS INT) AS [plate_ending_number],
    CAST(TRY_CAST(NULLIF([Deductible (Base)], '') AS FLOAT) AS INT) AS [deductible_base],
    
    -- STRINGS: Your updated CASE mapping + invisible character safeguard
    CAST(CASE WHEN TRIM(REPLACE([Plate Number], CHAR(160), '')) IN ('', 'N/A') THEN NULL 
              ELSE TRIM(REPLACE([Plate Number], CHAR(160), '')) END AS NVARCHAR(30)) AS [plante_number],
    
    -- DATETIME
    NULLIF(TRY_CAST([modifiedon] AS DATETIME2(0)), '1900-01-01 00:00:00') AS [modified_on],
    
    -- STRINGS
    CAST(CASE WHEN TRIM(REPLACE([Assigned], CHAR(160), '')) IN ('', 'N/A') THEN NULL 
              ELSE TRIM(REPLACE([Assigned], CHAR(160), '')) END AS NVARCHAR(20)) AS [assigned],
    
    -- BIT
    CAST(CAST(TRY_CAST(NULLIF([stencil], '') AS FLOAT) AS INT) AS BIT) AS [stencil],
    
    -- DATES
    NULLIF(TRY_CAST([compreexpdate] AS DATE), '1900-01-01') AS [compre_exp_date],
    
    -- STRINGS
    CAST(CASE WHEN TRIM(REPLACE([ltfrbstatus], CHAR(160), '')) IN ('', 'N/A') THEN NULL 
              ELSE TRIM(REPLACE([ltfrbstatus], CHAR(160), '')) END AS NVARCHAR(20)) AS [ltfrb_status],
    CAST(CASE WHEN TRIM(REPLACE([_crcc8_locationname_value], CHAR(160), '')) IN ('', 'N/A') THEN NULL 
              ELSE TRIM(REPLACE([_crcc8_locationname_value], CHAR(160), '')) END AS NVARCHAR(50)) AS [_crcc8_locationname_value],
    CAST(CASE WHEN TRIM(REPLACE([tplnumber], CHAR(160), '')) IN ('', 'N/A') THEN NULL 
              ELSE TRIM(REPLACE([tplnumber], CHAR(160), '')) END AS NVARCHAR(30)) AS [tpl_number],
    CAST(CASE WHEN TRIM(REPLACE([mvfilenumber], CHAR(160), '')) IN ('', 'N/A') THEN NULL 
              ELSE TRIM(REPLACE([mvfilenumber], CHAR(160), '')) END AS NVARCHAR(30)) AS [mv_file_number],
    CAST(CASE WHEN TRIM(REPLACE([tplname], CHAR(160), '')) IN ('', 'N/A') THEN NULL 
              ELSE TRIM(REPLACE([tplname], CHAR(160), '')) END AS NVARCHAR(30)) AS [tpl_name],
    CAST(CASE WHEN TRIM(REPLACE([Body Number], CHAR(160), '')) IN ('', 'N/A') THEN NULL 
              ELSE TRIM(REPLACE([Body Number], CHAR(160), '')) END AS NVARCHAR(30)) AS [body_number],
    
    -- NUMERICS
    CAST(TRY_CAST(NULLIF([suminsured], '') AS FLOAT) AS INT) AS [suminsured],
    CAST(TRY_CAST(NULLIF([Idle], '') AS FLOAT) AS INT) AS [idle],
    
    -- STRINGS
    CAST(CASE WHEN TRIM(REPLACE([orcrname], CHAR(160), '')) IN ('', 'N/A') THEN NULL 
              ELSE TRIM(REPLACE([orcrname], CHAR(160), '')) END AS NVARCHAR(40)) AS [or_cr_name],
    CAST(CASE WHEN TRIM(REPLACE([remarks], CHAR(160), '')) IN ('', 'N/A') THEN NULL 
              ELSE TRIM(REPLACE([remarks], CHAR(160), '')) END AS NVARCHAR(30)) AS [remarks],
    CAST(CASE WHEN TRIM(REPLACE([Deployed], CHAR(160), '')) IN ('', 'N/A') THEN NULL 
              ELSE TRIM(REPLACE([Deployed], CHAR(160), '')) END AS NVARCHAR(30)) AS [deploy],
    CAST(CASE WHEN TRIM(REPLACE([chassisnumber], CHAR(160), '')) IN ('', 'N/A') THEN NULL 
              ELSE TRIM(REPLACE([chassisnumber], CHAR(160), '')) END AS NVARCHAR(30)) AS [chassis_number],
    
    -- DATES
    NULLIF(TRY_CAST([ordate] AS DATE), '1900-01-01') AS [or_date],
    NULLIF(TRY_CAST([crdate] AS DATE), '1900-01-01') AS [cr_date],
    NULLIF(TRY_CAST([bankdue] AS DATE), '1900-01-01') AS [bank_due],
    
    -- BIT
    ISNULL(CAST(CAST(TRY_CAST(NULLIF([statecode], '') AS FLOAT) AS INT) AS BIT), 0) AS [state_code],
    
    -- STRINGS
    CAST(CASE WHEN TRIM(REPLACE([ltfrbnumber], CHAR(160), '')) IN ('', 'N/A') THEN NULL 
              ELSE TRIM(REPLACE([ltfrbnumber], CHAR(160), '')) END AS NVARCHAR(30)) AS [ltfrb_number],
    
    -- DATES
    NULLIF(TRY_CAST([tplexpdate] AS DATE), '1900-01-01') AS [tpl_exp_date],
    
    -- STRINGS
    CAST(CASE WHEN TRIM(REPLACE([_crcc8_groupname_value], CHAR(160), '')) IN ('', 'N/A') THEN NULL 
              ELSE TRIM(REPLACE([_crcc8_groupname_value], CHAR(160), '')) END AS NVARCHAR(40)) AS [_crcc8_groupname_value],
    CAST(CASE WHEN TRIM(REPLACE([flatbedfleet], CHAR(160), '')) IN ('', 'N/A') THEN NULL 
              ELSE TRIM(REPLACE([flatbedfleet], CHAR(160), '')) END AS NVARCHAR(30)) AS [fleet_group],
    
    -- DATES
    NULLIF(TRY_CAST([createdon] AS DATE), '1900-01-01') AS [created_on],
    
    -- STRINGS
    CAST(CASE WHEN TRIM(REPLACE([bank], CHAR(160), '')) IN ('', 'N/A') THEN NULL 
              ELSE TRIM(REPLACE([bank], CHAR(160), '')) END AS NVARCHAR(20)) AS [bank],
    CAST(CASE WHEN TRIM(REPLACE([comprenumber], CHAR(160), '')) IN ('', 'N/A') THEN NULL 
              ELSE TRIM(REPLACE([comprenumber], CHAR(160), '')) END AS NVARCHAR(20)) AS [compre_number],
    
    -- YEAR MODEL
    CAST(TRY_CAST(NULLIF([yearmodel], '') AS FLOAT) AS INT) AS [year_model],
    
    -- STRINGS: Explicitly matching your sample block
    CAST(CASE WHEN TRIM(REPLACE([comprename], CHAR(160), '')) IN ('', 'N/A') THEN NULL 
              ELSE TRIM(REPLACE([comprename], CHAR(160), '')) END AS NVARCHAR(30)) AS [compre_name],
    
    -- DATES & NUMERICS
    NULLIF(TRY_CAST([ltfrbexpdate] AS DATE), '1900-01-01') AS [ltfrb_exp_date],
    CAST(TRY_CAST(NULLIF([statuscode], '') AS FLOAT) AS INT) AS [status_code],
    CAST(TRY_CAST(NULLIF([status], '') AS FLOAT) AS INT) AS [STATUS],
    
    -- STRINGS
    CAST(CASE WHEN TRIM(REPLACE([crcc8_flatbedrecordid], CHAR(160), '')) IN ('', 'N/A') THEN NULL 
              ELSE TRIM(REPLACE([crcc8_flatbedrecordid], CHAR(160), '')) END AS NVARCHAR(40)) AS [crcc8_recordid]
    
FROM [TMS_APP].[dbo].[FLATBED_RECORD]

UNION ALL

SELECT 
    -- BULK RECORD (Maintains absolute column sequence matching)
    CAST(TRY_CAST(NULLIF([endingnumber], '') AS FLOAT) AS INT),
    CAST(TRY_CAST(NULLIF([Deductible (Base)], '') AS FLOAT) AS INT),
    
    CAST(CASE WHEN TRIM(REPLACE([Plate Number], CHAR(160), '')) IN ('', 'N/A') THEN NULL ELSE TRIM(REPLACE([Plate Number], CHAR(160), '')) END AS NVARCHAR(30)),
    
    NULLIF(TRY_CAST([modifiedon] AS DATETIME2(0)), '1900-01-01 00:00:00'),
    
    CAST(CASE WHEN TRIM(REPLACE([Assigned], CHAR(160), '')) IN ('', 'N/A') THEN NULL ELSE TRIM(REPLACE([Assigned], CHAR(160), '')) END AS NVARCHAR(20)),
    
    CAST(CAST(TRY_CAST(NULLIF([stencil], '') AS FLOAT) AS INT) AS BIT),
    
    NULLIF(TRY_CAST([compreexpdate] AS DATE), '1900-01-01'),
    
    CAST(CASE WHEN TRIM(REPLACE([ltfrbstatus], CHAR(160), '')) IN ('', 'N/A') THEN NULL ELSE TRIM(REPLACE([ltfrbstatus], CHAR(160), '')) END AS NVARCHAR(20)),
    CAST(CASE WHEN TRIM(REPLACE([_crcc8_locationname_value], CHAR(160), '')) IN ('', 'N/A') THEN NULL ELSE TRIM(REPLACE([_crcc8_locationname_value], CHAR(160), '')) END AS NVARCHAR(50)),
    CAST(CASE WHEN TRIM(REPLACE([tplnumber], CHAR(160), '')) IN ('', 'N/A') THEN NULL ELSE TRIM(REPLACE([tplnumber], CHAR(160), '')) END AS NVARCHAR(30)),
    CAST(CASE WHEN TRIM(REPLACE([mvfilenumber], CHAR(160), '')) IN ('', 'N/A') THEN NULL ELSE TRIM(REPLACE([mvfilenumber], CHAR(160), '')) END AS NVARCHAR(30)),
    CAST(CASE WHEN TRIM(REPLACE([tplname], CHAR(160), '')) IN ('', 'N/A') THEN NULL ELSE TRIM(REPLACE([tplname], CHAR(160), '')) END AS NVARCHAR(30)),
    CAST(CASE WHEN TRIM(REPLACE([Body Number], CHAR(160), '')) IN ('', 'N/A') THEN NULL ELSE TRIM(REPLACE([Body Number], CHAR(160), '')) END AS NVARCHAR(30)),
    
    CAST(TRY_CAST(NULLIF([suminsured], '') AS FLOAT) AS INT),
    CAST(TRY_CAST(NULLIF([Idle], '') AS FLOAT) AS INT),
    
    CAST(CASE WHEN TRIM(REPLACE([orcrname], CHAR(160), '')) IN ('', 'N/A') THEN NULL ELSE TRIM(REPLACE([orcrname], CHAR(160), '')) END AS NVARCHAR(40)),
    CAST(CASE WHEN TRIM(REPLACE([remarks], CHAR(160), '')) IN ('', 'N/A') THEN NULL ELSE TRIM(REPLACE([remarks], CHAR(160), '')) END AS NVARCHAR(30)),
    CAST(CASE WHEN TRIM(REPLACE([Deployed], CHAR(160), '')) IN ('', 'N/A') THEN NULL ELSE TRIM(REPLACE([Deployed], CHAR(160), '')) END AS NVARCHAR(30)),
    CAST(CASE WHEN TRIM(REPLACE([chassisnumber], CHAR(160), '')) IN ('', 'N/A') THEN NULL ELSE TRIM(REPLACE([chassisnumber], CHAR(160), '')) END AS NVARCHAR(30)),
    
    NULLIF(TRY_CAST([ordate] AS DATE), '1900-01-01'),
    NULLIF(TRY_CAST([crdate] AS DATE), '1900-01-01'),
    NULLIF(TRY_CAST([bankdue] AS DATE), '1900-01-01'),
    
    ISNULL(CAST(CAST(TRY_CAST(NULLIF([statecode], '') AS FLOAT) AS INT) AS BIT), 0),
    
    CAST(CASE WHEN TRIM(REPLACE([ltfrbnumber], CHAR(160), '')) IN ('', 'N/A') THEN NULL ELSE TRIM(REPLACE([ltfrbnumber], CHAR(160), '')) END AS NVARCHAR(30)),
    
    NULLIF(TRY_CAST([tplexpdate] AS DATE), '1900-01-01'),
    
    CAST(CASE WHEN TRIM(REPLACE([_crcc8_groupname_value], CHAR(160), '')) IN ('', 'N/A') THEN NULL ELSE TRIM(REPLACE([_crcc8_groupname_value], CHAR(160), '')) END AS NVARCHAR(40)),
    CAST(CASE WHEN TRIM(REPLACE([fleet], CHAR(160), '')) IN ('', 'N/A') THEN NULL ELSE TRIM(REPLACE([fleet], CHAR(160), '')) END AS NVARCHAR(30)), 
    
    NULLIF(TRY_CAST([createdon] AS DATE), '1900-01-01'),
    
    CAST(CASE WHEN TRIM(REPLACE([bank], CHAR(160), '')) IN ('', 'N/A') THEN NULL ELSE TRIM(REPLACE([bank], CHAR(160), '')) END AS NVARCHAR(20)),
    CAST(CASE WHEN TRIM(REPLACE([comprenumber], CHAR(160), '')) IN ('', 'N/A') THEN NULL ELSE TRIM(REPLACE([comprenumber], CHAR(160), '')) END AS NVARCHAR(20)),
    
    CAST(TRY_CAST(NULLIF([yearmodel], '') AS FLOAT) AS INT),
    
    CAST(CASE WHEN TRIM(REPLACE([comprename], CHAR(160), '')) IN ('', 'N/A') THEN NULL ELSE TRIM(REPLACE([comprename], CHAR(160), '')) END AS NVARCHAR(30)),
    
    NULLIF(TRY_CAST([ltfrbexpdate] AS DATE), '1900-01-01'),
    CAST(TRY_CAST(NULLIF([statuscode], '') AS FLOAT) AS INT),
    CAST(TRY_CAST(NULLIF([status], '') AS FLOAT) AS INT),
    
    CAST(CASE WHEN TRIM(REPLACE([crcc8_bulkrecordid], CHAR(160), '')) IN ('', 'N/A') THEN NULL ELSE TRIM(REPLACE([crcc8_bulkrecordid], CHAR(160), '')) END AS NVARCHAR(40))
    
FROM [TMS_APP].[dbo].[BULK_RECORD];

--TMS_TRAILER V2

SELECT 
lu.locationName as assignment,
gu.groupName as bu,
tt.*

FROM TMS_TRAILER TT

LEFT JOIN TMS_app.dbo.tbl_LocationUnit lu 
    ON tt._crcc8_locationname_value = lu.crcc8_tbl_locationunitid

LEFT JOIN TMS_app.dbo.tbl_GroupUnit gu
    ON tt._crcc8_groupname_value = gu.crcc8_tbl_groupunitid

--TMS_TRAILER V2.5

SELECT 
       tt.[body_number]
      ,tt.[plante_number]
      ,tt.[chassis_number]
      ,lu.locationName as assignment
      ,gu.groupName as bu
      ,tt.[fleet_group]
      ,tt.[or_date]
      ,tt.[cr_date]
      ,tt.[remarks]
      ,tt.[or_cr_name]
      ,tt.[mv_file_number]
      ,tp.TrailerType as trailer_type
      ,tt.[status]
      ,tt.[plate_ending_number]
      ,tt.[year_model]
      ,tt.[assigned]


      --INSURANCE
      ,tt.[tpl_name]
      ,tt.[tpl_number]
      ,tt.[tpl_exp_date]

      ,tt.[compre_name]
      ,tt.[compre_number]
      ,tt.[compre_exp_date]
      ,tt.[deductible_base]
      ,tt.[suminsured]
      --BANK
      ,tt.[bank]
      ,tt.[bank_due]    

      --LTFRB
      ,tt.[ltfrb_number]
      ,tt.[ltfrb_status]
      ,tt.[ltfrb_exp_date]
      --MISC
      ,tt.[idle]

      ,tt.[created_on]
      ,tt.[modified_on]
      ,tt.[stencil]
      ,tt.[deploy]
      ,tt.[status_code]
      ,tt.[state_code]

  FROM [WILLOWTestDB].[dbo].[TMS_TRAILER] tt

  LEFT JOIN TMS_app.dbo.tbl_LocationUnit lu 
    ON tt._crcc8_locationname_value = lu.crcc8_tbl_locationunitid

  LEFT JOIN TMS_app.dbo.tbl_GroupUnit gu
    ON tt._crcc8_groupname_value = gu.crcc8_tbl_groupunitid

  LEFT JOIN TMS_APP.dbo.sr_truckpairs tp
	ON tp.TrailerBodyNumber = tt.body_number