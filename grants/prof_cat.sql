-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 23/11/2011 11:32
-- CHANGE REASON: [ALERT-206286] 02_ALERT_DDLS
grant references on PROF_CAT to alert_product_mt;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 23/11/2011 11:43
-- CHANGE REASON: [ALERT-206286 ] 
grant references on PROF_CAT to alert_product_mt;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Telmo
-- CHANGED DATE: 20-12-2012
-- CHANGE REASON: BC-311
GRANT SELECT ON prof_cat TO alert_basecomp;
--CHANGE END: Telmo



-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-03
-- CHANGED REASON: ALERT-327486
grant SELECT on ALERT.PROF_CAT to ALERT_APEX_TOOLS;
-- CHANGE END: Humberto Cardoso
