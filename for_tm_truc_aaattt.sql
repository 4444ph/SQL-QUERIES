SELECT 
     tad.[doc_id]
    ,tad.[asset_reference]
    ,tad.[asset_type]
    ,tad.[doc_category]
    ,tad.[provider_id]
    -- Dynamically merges all lookups into one single column
    ,COALESCE(tci.compre_name, tti.tpl_name, tb.bank_name, tls.status_name) AS provider_name
    ,tad.[document_number]
    ,tad.[expiry_or_due_date]
    ,tad.[created_on]
FROM [WILLOWTestDB].[dbo].[tms_asset_document] tad

-- 1. Compre Join
LEFT JOIN tms_compre_insurance tci
    ON tci.compre_Id = tad.provider_id AND tad.doc_category = 'COMPRE'

-- 2. TPL Join
LEFT JOIN tms_tpl_insurance tti
    ON tti.tpl_id = tad.provider_id AND tad.doc_category = 'TPL'

-- 3. Bank Join
LEFT JOIN tms_bank tb
    ON tb.bank_id = tad.provider_id AND tad.doc_category = 'BANK'

-- 4. LTFRB Status Join
LEFT JOIN tms_ltfrb_status tls
    ON tls.status_id = tad.provider_id AND tad.doc_category = 'LTFRB';