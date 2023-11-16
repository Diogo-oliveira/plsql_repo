CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_IMG_EXAM_CATALOGUE AS
SELECT 'Search in ACTIONS for a specific term or ALL to retrieve all imaging exams' AS desc_img_exam,
       NULL AS desc_alias,
       NULL AS id_cnt_img_exam,
       NULL AS desc_exam_cat,
       NULL AS id_cnt_exam_cat,
       NULL AS gender,
       NULL AS age_min,
       NULL AS age_max,
       NULL AS flg_pat_resp,
       NULL AS flg_pat_prep,
       NULL AS flg_mov_pat,
       NULL AS flg_technical,
       NULL AS id_img_exam,
       NULL AS create_time
  FROM dual;

