CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_PROCEDURE_CATALOGUE AS
SELECT 'Search in ACTIONS for a specific term or ALL to retrieve all procedures' AS desc_procedure,
       NULL AS desc_alias,
       NULL AS id_cnt_procedure,
       NULL AS gender,
       NULL AS age_min,
       NULL AS age_max,
       NULL AS cpt_code,
       NULL AS flg_mov_pat,
       NULL AS duration,
       NULL AS prev_recovery_time,
       NULL AS ref_form_code,
       NULL AS barcode,
       NULL AS mdm_coding,
       NULL AS flg_technical,
       NULL AS id_procedure,
       NULL AS create_time
  FROM dual;

