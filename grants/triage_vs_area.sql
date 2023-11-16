-- CHANGED BY: Alexandre Santos
-- CHANGE DATE: 28/06/2013 17:04
-- CHANGE REASON: [ALERT-260856] Ability to perform triage based on EST (�chelle Suisse de Tri) (ALERT_188926) - VERSIONING DB DDL
GRANT SELECT ON ALERT.TRIAGE_VS_AREA TO ALERT_VIEWER;
-- CHANGE END: Alexandre Santos


-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2018-12-10
-- CHANGED REASON: EMR-9798
GRANT SELECT, INSERT, UPDATE ON triage_vs_area TO alert_core_cnt WITH GRANT OPTION;
-- CHANGE END: Humberto Cardoso