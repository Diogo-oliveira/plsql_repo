-- CHANGED BY: Ariel Machado
-- CHANGE DATE: 24/10/2011 17:18
-- CHANGE REASON: [ALERT-201238] Medical/Nursing notes. Remove 4k limitation for free text entries using CLOB.
BEGIN
    UPDATE epis_recomend er
       SET er.desc_epis_recomend_clob = er.desc_epis_recomend
     WHERE er.flg_type IN ('M', 'N')
       AND er.desc_epis_recomend IS NOT NULL
       AND er.desc_epis_recomend_clob IS NULL;
END;
/
-- CHANGE END: Ariel Machado