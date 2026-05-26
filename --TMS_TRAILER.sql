--BULK NOT DONE

SELECT 
       b.[body_number]
      ,b.[plate_number]
      ,b.[plate_ending_number]
      ,b.[chassis_number]
      ,b.[trailer_type]--
      ,b.[axle_type]--
      ,b.[year_model]

      ,b.[bu_ID]
      ,b.[fleet] as fleet_group
      ,b.[a_ID]
      ,b.[assigned]
      ,b.[idle]

      ,b.[status_code]

      ,b.[status] as og_status
      
      ,CASE 
           WHEN b.status = 1 THEN 0
           WHEN b.status = 0 THEN 1
           WHEN b.status = 2 THEN 14
           WHEN b.status = 3 THEN 20
           WHEN b.status = 4 THEN 6
           WHEN b.status = 5 THEN 2
           WHEN b.status = 6 THEN 8
           WHEN b.status = 7 THEN 4
           WHEN b.status = 8 THEN 21
           WHEN b.status = 9 THEN 3
           WHEN b.status = 10 THEN 12
           WHEN b.status = 11 THEN 5
       ELSE b.status
       END AS status

      ,b.[remarks]
      ,b.[deployed]
      ,b.[has_stencil]

      ,b.[mv_file_number]
      ,b.[or_cr_name]
      ,b.[or_date]
      ,b.[cr_date]
      ,b.[state_code]

      ,b.[ltfrb_exp_date]
      ,b.[ltfrb_number]
      ,UPPER(b.[ltfrb_status]) AS ltfrb_status

      ,b.tpl_name
      ,b.[tpl_number]
      ,b.[tpl_exp_date]

      ,b.[compre_name]
      ,b.[compre_number]
      ,b.[compre_exp_date]

      ,b.[bank]
      ,b.[bank_due]
      ,b.[sum_insured]
      ,b.[deductible_base]

      ,b.[modified_on]
      ,b.[created_on]
      ,b.[from_tbl]
      --,b.[bulkrecordid]
      --,b.[assignment_og_id]
      --,b.[bu_origninal_id]
      --,b.[business_unit]
      --,b.[assignment]
  --INTO tms_bulk_new
  FROM [WILLOWTestDB].[dbo].[tms_bulk] b

-- DONE FLATBED

SELECT 
       fb.[body_number] as trailer_id
      ,fb.[plate_number]
      ,fb.[plate_ending_number]
      ,fb.[chassis_number]
      ,fb.[trailer_type]
      ,fb.[axle_type]
      ,fb.[year_model]
      ,fb.[bu_ID]
      ,fb.[fleet_group]
      ,fb.[a_ID]
      ,fb.[assigned]
      ,fb.[idle]
      ,fb.[status_code]
      
      ,fb.[status] as og_status --original
      ,CASE 
           WHEN fb.status = 1 THEN 2
           WHEN fb.status = 2 THEN 15
           WHEN fb.status = 4 THEN 8
           WHEN fb.status = 5 THEN 4
           WHEN fb.status = 6 THEN 14
           WHEN fb.status = 7 THEN 1
           WHEN fb.status = 8 THEN 9
           WHEN fb.status = 9 THEN 16
           WHEN fb.status = 10 THEN 6
           WHEN fb.status = 11 THEN 17
           WHEN fb.status = 12 THEN 18
           WHEN fb.status = 13 THEN 19
           WHEN fb.status = 14 THEN 3
       ELSE fb.status
       END AS status
      ,fb.[remarks]
      ,fb.[deploy]
      ,fb.[stencil] as has_stencil
      ,fb.[mv_file_number]
      ,fb.[or_cr_name]
      ,fb.[or_date]
      ,fb.[cr_date]
      ,fb.[state_code]
      ,fb.[ltfrb_number]
      ,UPPER(fb.[ltfrb_status]) AS ltfrb_status      
      ,fb.[ltfrb_exp_date]
      ,fb.[tpl_number]
      ,fb.tpl_name
      ,fb.[tpl_exp_date]
      ,fb.[compre_number]
      ,fb.[compre_name]
      ,fb.[compre_exp_date]
      ,fb.[bank_due]
      ,fb.[bank]
      ,fb.[suminsured]
      ,fb.[deductible_base]
      ,fb.[created_on]
      ,fb.[modified_on]
      ,fb.[from_tbl]
      --,fb.[_crcc8_groupname_value]
      --,fb.[bu]
      --,fb.[crcc8_recordid]
      --,fb.[_crcc8_locationname_value]
      --,fb.[assignment]
  FROM [WILLOWTestDB].[dbo].[tms_flatbed] fb
