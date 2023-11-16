GRANT SELECT ON ALERT.MI_MED TO ALERT_PRODUCT_TR;


-- CHANGED BY: Ricardo Meira
-- CHANGED DATE: 2018-7-20
-- CHANGED REASON: CEMR-1881

-- CHANGED BY: Howard Cheng
-- CHANGED DATE: 2018/06/13
-- CHANGE REASON: [CEMR-1683] DB alert_core_cnt_api.pk_cnt_api.vaccine and alert_core_cnt.pk_cnt_vaccine
GRANT SELECT, INSERT ON mi_med TO alert_core_cnt WITH GRANT OPTION;
-- CHANGE END: Howard Cheng
-- CHANGE END: Ricardo Meira
