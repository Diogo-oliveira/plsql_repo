GRANT REFERENCES ON vacc_group TO alert_default;

-- CHANGED BY: Tércio Soares
-- CHANGE DATE: 28/08/2009 16:51
-- CHANGE REASON: [ALERT-40932] 
GRANT REFERENCES ON vacc_group TO alert_default;
-- CHANGE END: Tércio Soares


-- CHANGED BY: Ricardo Meira
-- CHANGED DATE: 2018-7-20
-- CHANGED REASON: CEMR-1881

-- CHANGED BY: Webber Chiou
-- CHANGED DATE: 2018/06/13
-- CHANGE REASON: [CEMR-1683] DB alert_core_cnt_api.pk_cnt_api.vaccine and alert_core_cnt.pk_cnt_vaccine
GRANT SELECT, INSERT ON vacc_group TO alert_core_cnt WITH GRANT OPTION;
-- CHANGE END: Webber Chiou
-- CHANGE END: Ricardo Meira
