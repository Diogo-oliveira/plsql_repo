-- ADDED BY: Pedro Maia
-- ADDED DATE: 29/06/2010
-- ADDED REASON: [ALERT-94678]

grant select on lab_tests_par_uni_mea to alert_viewer;

-- END: Pedro Maia


-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-03
-- CHANGED REASON: ALERT-327486
grant SELECT on ALERT.LAB_TESTS_PAR_UNI_MEA to ALERT_APEX_TOOLS;
-- CHANGE END: Humberto Cardoso

-- ADDED BY: Gilberto Rocha
-- ADDED DATE: 24/02/2020
-- ADDED REASON: [EMR-25254]

grant select on lab_tests_par_uni_mea to alert_inter;

-- END: Gilberto Rocha