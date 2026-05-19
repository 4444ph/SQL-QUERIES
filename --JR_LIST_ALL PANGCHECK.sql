--JR_LIST_ALL PANGCHECK

SELECT 
    jl.Head,
    jl.Jrnumber,
    jl.Jrstatus,
    jl.Datecreated as jrCreated,
    jl.Modified,
    jla.JONumber,
    jla.JOStatus,
    jla.JRNumber
FROM jr_list jl
-- First join the JOs (One JR to Many JOs)
LEFT JOIN VW_JO_List_All jla
    ON jl.Jrnumber = jla.JRNumber
-- Then join the Tractor (Many JRs to One Tractor)

ORDER BY jl.Jrnumber, jla.JONumber;
