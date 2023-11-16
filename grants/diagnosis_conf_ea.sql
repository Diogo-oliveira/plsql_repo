-- CHANGED BY: Alexandre Santos
-- CHANGE DATE: 18/11/2013 14:02
-- CHANGE REASON: [ALERT-269873] A&E diagnoses_Some diagnosis are not giving the option to document "anatomical side". (ALERT_268880)
--                BSUH - Diagnosis/Problems/Past history - possibility to define the classification to be used in each functional area (ALERT_265471)
GRANT SELECT ON ALERT.DIAGNOSIS_CONF_EA TO ALERT_VIEWER;
-- CHANGE END: Alexandre Santos


-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2018-07-12
-- CHANGED REASON: EMR-4688
GRANT SELECT, INSERT, UPDATE, DELETE ON diagnosis_conf_ea TO alert_core_func WITH GRANT OPTION;
-- CHANGE END: Humberto Cardoso
