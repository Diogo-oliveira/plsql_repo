grant select on ALERT.prof_institution to ALERT_IDP;

-- CHANGED BY: Bruno Martins
-- CHANGED DATE: 2010-03-11
-- CHANGE REASON: ADT-2165

grant select on prof_institution to alert_adtcod;

-- CHANGED END: Bruno Martins

-- CHANGED BY: Bruno Martins
-- CHANGE DATE: 2010-07-29
-- CHANGE REASON: ADT-2923

grant insert on prof_institution to alert_adtcod;

-- CHANGE END: Bruno Martins

-- CHANGED BY: Bruno Martins
-- CHANGED DATE: 2010-12-10
-- CHANGE REASON: ADT-3775

GRANT SELECT ON prof_institution TO alert_basecomp;

-- CHANGE END: Bruno Martins

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 23/11/2011 11:42
-- CHANGE REASON: [ALERT-206286 ] 
grant references on PROF_INSTITUTION to alert_product_mt;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 24/11/2011 15:44
-- CHANGE REASON: [ALERT-206850] 
GRANT SELECT ON PROF_INSTITUTION TO ALERT_PRODUCT_MT;
-- CHANGE END: Pedro Quinteiro