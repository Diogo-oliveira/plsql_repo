CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_LAB_TEST_ST_CATALOGUE AS
SELECT DISTINCT 'Search in ACTIONS for a specific term or ALL to retrieve all labtests' AS desc_lab_test_sample_type,
                NULL AS desc_alias,
                NULL AS id_cnt_lab_test_sample_type,
                NULL AS desc_lab_test,
                NULL AS id_cnt_lab_test,
                NULL AS desc_sample_type,
                NULL AS id_cnt_sample_type,
                NULL AS gender,
                NULL AS age_min,
                NULL AS age_max,
                NULL AS create_time
  FROM dual;

