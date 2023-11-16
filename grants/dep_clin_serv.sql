-- CHANGED BY: José Silva
-- CHANGE DATE: 22/05/2012 16:33
-- CHANGE REASON: [ALERT-230907] Diagnosis corrections
GRANT SELECT ON ALERT.DEP_CLIN_SERV TO ALERT_CORE_FUNC;
/
GRANT REFERENCES ON ALERT.DEP_CLIN_SERV TO ALERT_CORE_FUNC;
/
-- CHANGE END: José Silva

-- CHANGED BY:  luis.r.silva
-- CHANGE DATE: 28/05/2014 18:27
-- CHANGE REASON: [ALERT-286331] Lacking grants for template configuration tool
grant select on dep_clin_serv to alert_apex_tools;
-- CHANGE END:  luis.r.silva


-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-03
-- CHANGED REASON: ALERT-327486
grant INSERT on ALERT.DEP_CLIN_SERV to ALERT_APEX_TOOLS;
grant UPDATE on ALERT.DEP_CLIN_SERV to ALERT_APEX_TOOLS;
-- CHANGE END: Humberto Cardoso


-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 21/02/2017 11:03
-- CHANGE REASON: [ALERT-328830 ] New ADW Report to identify prescriptions for Expensive Drugs - Medication View
BEGIN
    pk_versioning.run('GRANT REFERENCES, SELECT ON dep_clin_serv TO alert_product_tr WITH GRANT OPTION');
END;
/
-- CHANGE END: Sofia Mendes

-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 07/03/2017 15:03
-- CHANGE REASON: [ALERT-328830 ] New ADW Report to identify prescriptions for Expensive Drugs - Medication View
BEGIN
    pk_versioning.run('GRANT REFERENCES, SELECT ON dep_clin_serv TO alert_product_tr WITH GRANT OPTION');
END;
/
-- CHANGE END: Sofia Mendes

-- CHANGED BY:  andre.silva
-- CHANGE DATE: 09/11/2017
-- CHANGE REASON: [CALERT-622]
grant select on dep_clin_serv to alert_inter;
-- CHANGE END:  andre.silva

-- CHANGED BY: cristina.oliveira
-- CHANGE DATE: 19/01/2018 15:55
-- CHANGE REASON: [ALERT-335179 ] 
BEGIN
    pk_versioning.run('GRANT REFERENCES, SELECT ON dep_clin_serv TO alert_pharmacy_data WITH GRANT OPTION');
END;
/
-- CHANGE END: cristina.oliveira

-- CHANGED BY: cristina.oliveira
-- CHANGE DATE: 19/01/2018 16:02
-- CHANGE REASON: [ALERT-335179 ] 
BEGIN
    pk_versioning.run('GRANT REFERENCES, SELECT ON dep_clin_serv TO alert_pharmacy_func WITH GRANT OPTION');
END;
/
-- CHANGE END: cristina.oliveira
-- CHANGED BY: Webber Chiou
-- CHANGED DATE: 2018/05/17
-- CHANGE REASON: [CEMR-1492] [Subtask] [CNT] DB alert_core_cnt_api.pk_cnt_api_exam_cat and alert_core_cnt.pk_cnt_exam_cat
GRANT SELECT ON alert.dep_clin_serv TO alert_core_cnt;
-- CHANGE END: Webber Chiou