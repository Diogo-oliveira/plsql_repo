-- CHANGED BY: Bruno Martins
-- CHANGED DATE: 2010-06-30
-- CHANGE REASON: ADT-2707

grant select on prof_profile_template to alert_adtcod;

-- CHANGED END: Bruno Martins

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 23/11/2011 11:43
-- CHANGE REASON: [ALERT-206286 ] 
grant references on PROF_PROFILE_TEMPLATE to alert_product_mt;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 24/11/2011 15:43
-- CHANGE REASON: [ALERT-206850] 
GRANT SELECT ON PROF_PROFILE_TEMPLATE TO ALERT_PRODUCT_MT;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Rui Spratley
-- CHANGE DATE: 13/01/2014 09:17
-- CHANGE REASON: [ALERT-270576] 
grant SELECT ON alert.prof_profile_template TO alert_basecomp;
-- CHANGE END: Rui Spratley

-- CHANGED BY:  luis.r.silva
-- CHANGE DATE: 28/05/2014 10:54
-- CHANGE REASON: [ALERT-281087] 
grant select on prof_profile_template to alert_apex_tools;
-- CHANGE END:  luis.r.silva

-- CHANGED BY: Cristina Oliveira
-- CHANGE DATE: 15/12/2020 10:26
-- CHANGE REASON: [EMR-39746]
grant select, references on PROF_PROFILE_TEMPLATE to alert_product_tr;
-- CHANGE END: Cristina Oliveira

-- CHANGED BY: Cristina Oliveira
-- CHANGE DATE: 15/12/2020 10:33
-- CHANGE REASON: [EMR-39746]
grant select, references on prof_profile_template to adw_stg  WITH GRANT OPTION;
-- CHANGE END: Cristina Oliveira

-- CHANGED BY: Cristina Oliveira
-- CHANGE DATE: 28/01/2021 08:39
-- CHANGE REASON: [EMR-41232]
GRANT SELECT ON prof_profile_template TO alert_product_tr WITH GRANT OPTION;
-- CHANGE END: Cristina Oliveira