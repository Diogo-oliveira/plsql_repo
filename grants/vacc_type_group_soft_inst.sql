GRANT SELECT ON ALERT.vacc_type_group_soft_inst TO ALERT_VIEWER;


-- CHANGED BY: Ricardo Meira
-- CHANGED DATE: 2018-7-20
-- CHANGED REASON: CEMR-1881

-- CHANGED BY: Webber Chiou
-- CHANGED DATE: 2018/06/13
-- CHANGE REASON: [CEMR-1683] DB alert_core_cnt_api.pk_cnt_api.vaccine and alert_core_cnt.pk_cnt_vaccine
GRANT SELECT, INSERT, DELETE ON vacc_type_group_soft_inst TO alert_core_cnt WITH GRANT OPTION;
-- CHANGE END: Webber Chiou
-- CHANGE END: Ricardo Meira
