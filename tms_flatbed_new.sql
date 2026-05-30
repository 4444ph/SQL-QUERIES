SELECT 
       fbn.[trailer_id]
      ,fbn.[plate_number]
      ,fbn.[plate_ending_number]
      ,fbn.[chassis_number]
      --,fbn.[trailer_type]
      ,tt.trailer_type
      --,fbn.[axle_type]
      ,tta.axle_type
      ,fbn.[year_model]
      --,fbn.[bu_ID]
      ,bu.business_unit
      ,fbn.[fleet_group]
      --,fbn.[a_ID]
      ,ta.assignment
      ,fbn.[assigned]
      ,fbn.[idle]
      ,fbn.[status_code]
      --,fbn.[og_status]
      --,fbn.[status]
      ,us.status_name
      ,fbn.[remarks]
      ,fbn.[deploy]
      ,fbn.[has_stencil]
      ,fbn.[mv_file_number]
      ,fbn.[or_cr_name]
      ,fbn.[or_date]
      ,fbn.[cr_date]
      ,fbn.[state_code]
      ,fbn.[ltfrb_number]
      --,fbn.[ltfrb_status]
      --,fbn.[status_id]
      ,tls.status_name as ltfrb_status
      ,fbn.[ltfrb_exp_date]
      ,fbn.[tpl_number]
      --,fbn.[tpl_id]
      ,tti.tpl_name
      ,fbn.[tpl_exp_date]
      ,fbn.[compre_number]
      --,fbn.[compre_id]
      ,tci.compre_name
      ,fbn.[compre_exp_date]
      ,fbn.[bank_due]
      --,fbn.[bank_id]
      ,tb.bank_name
      ,fbn.[suminsured]
      ,fbn.[deductible_base]
      ,fbn.[created_on]
      ,fbn.[modified_on]
      ,fbn.[from_tbl]
  FROM [WILLOWTestDB].[dbo].[tms_flatbed_new] fbn

  left join tms_bu bu
    on bu.bu_ID = fbn.bu_ID

  left join tms_assignment ta
    on ta.a_ID = fbn.a_ID

  left join tms_trailer_type tt
    on tt.type_id = fbn.trailer_type

  left join tms_trailer_axle tta
    on tta.axle_id = fbn.axle_type

  left join tms_unit_status us
    on us.StatusID = fbn.status
  
  left join [tms_tpl_insurance] tti
    on tti.tpl_id = fbn.tpl_id

  left join tms_compre_insurance tci
	on tci.compre_id = fbn.compre_id

  left join tms_ltfrb_status tls
    on tls.status_id = fbn.ltfrb_status_id

  left join tms_bank tb
    on tb.bank_id = fbn.bank_id
  