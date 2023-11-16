-- CHANGED BY: mario.mineiro
-- CHANGE DATE: 02/12/2014 12:22
-- CHANGE REASON: [ALERT-256948] 
update EPIS_RECOMEND er
set er.desc_epis_recomend = er.desc_epis_recomend_clob
WHERE er.desc_epis_recomend is NULL
 AND er.desc_epis_recomend_clob IS NOT NULL
 and length(er.desc_epis_recomend_clob) <= 4000; 
-- CHANGE END: mario.mineiro

-- CHANGED BY: mario.mineiro
-- CHANGE DATE: 12/12/2014 15:49
-- CHANGE REASON: [ALERT-303925] migration for the drop column epis_recomend.desc_epis_recomend
UPDATE epis_recomend er
set er.desc_epis_recomend_clob = er.desc_epis_recomend
where er.desc_epis_recomend_clob is null
and er.desc_epis_recomend is not null;
-- CHANGE END: mario.mineiro