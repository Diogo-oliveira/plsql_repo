GRANT SELECT ON ALERT.vacc_group_soft_inst TO ALERT_VIEWER;


-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-03
-- CHANGED REASON: ALERT-327486
grant SELECT on ALERT.VACC_GROUP_SOFT_INST to ALERT_APEX_TOOLS;
-- CHANGE END: Humberto Cardoso



-- CHANGED BY: Ricardo Meira
-- CHANGED DATE: 2018-7-20
-- CHANGED REASON: CEMR-1881

-- CHANGED BY: Webber Chiou
-- CHANGED DATE: 2018/06/13
-- CHANGE REASON: [CEMR-1683] DB alert_core_cnt_api.pk_cnt_api.vaccine and alert_core_cnt.pk_cnt_vaccine
GRANT SELECT, INSERT, DELETE ON vacc_group_soft_inst TO alert_core_cnt WITH GRANT OPTION;
-- CHANGE END: Webber Chiou
-- CHANGE END: Ricardo Meira
