CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_LAB_TEST_GROUP AS
SELECT "DESC_LAB_TEST_GROUP", "GENDER", "AGE_MIN", "AGE_MAX", "ID_CNT_LAB_TEST_GROUP", "ID_LAB_TEST_GROUP"
  FROM (SELECT t.desc_translation  desc_lab_test_group,
               a.gender,
               a.age_min,
               a.age_max,
               a.id_content        id_cnt_lab_test_group,
               a.id_analysis_group AS id_lab_test_group
          FROM analysis_group a
          JOIN alert.analysis_instit_soft e
            ON e.id_analysis_group = a.id_analysis_group
          JOIN alert.v_cmt_translation_agp t
            ON t.code_translation = a.code_analysis_group
         WHERE a.flg_available = 'Y'
           AND a.id_content IS NOT NULL)
 WHERE desc_lab_test_group IS NOT NULL;

