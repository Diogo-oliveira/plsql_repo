-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 23/11/2011 11:32
-- CHANGE REASON: [ALERT-206286] 02_ALERT_DDLS
grant references on DEPT to alert_product_mt;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 23/11/2011 11:42
-- CHANGE REASON: [ALERT-206286 ] 
grant references on DEPT to alert_product_mt;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 24/11/2011 15:43
-- CHANGE REASON: [ALERT-206850] 
GRANT SELECT ON DEPT TO ALERT_PRODUCT_MT;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY:  luis.r.silva
-- CHANGE DATE: 28/05/2014 10:54
-- CHANGE REASON: [ALERT-281087] 
grant select on dept to alert_apex_tools;
-- CHANGE END:  luis.r.silva


-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-03
-- CHANGED REASON: ALERT-327486
grant INSERT on ALERT.DEPT to ALERT_APEX_TOOLS;
grant UPDATE on ALERT.DEPT to ALERT_APEX_TOOLS;
-- CHANGE END: Humberto Cardoso


-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 21/02/2017 11:03
-- CHANGE REASON: [ALERT-328830 ] New ADW Report to identify prescriptions for Expensive Drugs - Medication View
BEGIN
    pk_versioning.run('GRANT REFERENCES, SELECT ON dept TO alert_product_tr WITH GRANT OPTION');
END;
/
-- CHANGE END: Sofia Mendes

-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 07/03/2017 15:03
-- CHANGE REASON: [ALERT-328830 ] New ADW Report to identify prescriptions for Expensive Drugs - Medication View
BEGIN
    pk_versioning.run('GRANT REFERENCES, SELECT ON dept TO alert_product_tr WITH GRANT OPTION');
END;
/
-- CHANGE END: Sofia Mendes