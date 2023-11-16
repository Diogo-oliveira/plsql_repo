-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 23/11/2011 11:32
-- CHANGE REASON: [ALERT-206286] 02_ALERT_DDLS
grant references on CLINICAL_SERVICE to alert_product_mt;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 23/11/2011 11:42
-- CHANGE REASON: [ALERT-206286 ] 
grant references on CLINICAL_SERVICE to alert_product_mt;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 24/11/2011 19:30
-- CHANGE REASON: [ALERT-206929] 
grant  select on clinical_service to alert_product_mt;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY:  luis.r.silva
-- CHANGE DATE: 28/05/2014 18:27
-- CHANGE REASON: [ALERT-286331] Lacking grants for template configuration tool
grant select on clinical_service to alert_apex_tools;
-- CHANGE END:  luis.r.silva


-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-03
-- CHANGED REASON: ALERT-327486
grant INSERT on ALERT.CLINICAL_SERVICE to ALERT_APEX_TOOLS;
grant UPDATE on ALERT.CLINICAL_SERVICE to ALERT_APEX_TOOLS;
-- CHANGE END: Humberto Cardoso


-- CHANGED BY: cristina.oliveira
-- CHANGE DATE: 19/01/2018 16:02
-- CHANGE REASON: [ALERT-335179 ] 
BEGIN
    pk_versioning.run('GRANT REFERENCES, SELECT ON clinical_service TO alert_pharmacy_func WITH GRANT OPTION');
END;
/
-- CHANGE END: cristina.oliveira

-- CHANGED BY: Webber Chiou
-- CHANGED DATE: 2018/05/29
-- CHANGE REASON: [CEMR-1621] [Subtask] [CNT] DB alert_core_cnt_api.pk_cnt_api_clinical_service and alert_core_cnt.pk_cnt_clinical_service 
GRANT SELECT, INSERT ON alert.clinical_service TO alert_core_cnt WITH GRANT OPTION;
-- CHANGE END: Webber Chiou