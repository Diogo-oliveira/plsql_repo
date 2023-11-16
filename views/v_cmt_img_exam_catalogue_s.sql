CREATE OR REPLACE VIEW v_cmt_img_exam_catalogue_s AS
SELECT desc_img_exam,
       desc_alias,
       id_cnt_img_exam,
       desc_exam_cat,
       id_cnt_exam_cat,
       gender,
       age_min,
       age_max,
       flg_technical,
       id_img_exam,
       create_time
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), code_exam)
                  FROM dual) desc_img_exam,
               (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), code_exam_alias)
                  FROM dual) desc_alias,
               id_cnt_img_exam,
               (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), code_exam_cat)
                  FROM dual) desc_exam_cat,
               id_cnt_exam_cat,
               gender,
               age_min,
               age_max,
               nvl(flg_technical, 'N') flg_technical,
               id_img_exam,
               to_char(create_time, 'DD-MON-YYYY HH24:MI') create_time
          FROM (SELECT e.code_exam,
                       ea.code_exam_alias,
                       e.id_content       id_cnt_img_exam,
                       ec.code_exam_cat,
                       ec.id_content      id_cnt_exam_cat,
                       e.gender,
                       e.age_min,
                       e.age_max,
                       e.flg_technical,
                       e.id_exam          id_img_exam,
                       e.create_time
                  FROM exam e
                  JOIN TABLE(pk_translation.get_search_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), sys_context('ALERT_CONTEXT', 'SEARCH_TEXT'), 'EXAM.CODE_EXAM')) t
                    ON t.code_translation = e.code_exam
                  JOIN exam_cat ec
                    ON ec.id_exam_cat = e.id_exam_cat
                   AND ec.flg_available = 'Y'
                  LEFT JOIN alert.exam_alias ea
                    ON ea.id_exam = e.id_exam
                   AND ea.id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')
                   AND ea.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
                 WHERE e.flg_type = 'I'
                   AND e.flg_available = 'Y'
                   AND 'all' != lower(sys_context('ALERT_CONTEXT', 'SEARCH_TEXT'))
                   AND instr(lower(sys_context('ALERT_CONTEXT', 'SEARCH_TEXT')), 'tmp2.') = 0
                   AND instr(lower(sys_context('ALERT_CONTEXT', 'SEARCH_TEXT')), 'cntx.') = 0
                UNION
                SELECT e.code_exam,
                       ea.code_exam_alias,
                       e.id_content       id_cnt_img_exam,
                       ec.code_exam_cat,
                       ec.id_content      id_cnt_exam_cat,
                       e.gender,
                       e.age_min,
                       e.age_max,
                       e.flg_technical,
                       e.id_exam          id_img_exam,
                       e.create_time
                  FROM exam e
                  JOIN exam_cat ec
                    ON ec.id_exam_cat = e.id_exam_cat
                   AND ec.flg_available = 'Y'
                  LEFT JOIN alert.exam_alias ea
                    ON ea.id_exam = e.id_exam
                   AND ea.id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')
                   AND ea.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
                 WHERE e.flg_type = 'I'
                   AND e.flg_available = 'Y'
                   AND 'all' = lower(sys_context('ALERT_CONTEXT', 'SEARCH_TEXT'))
                UNION
                SELECT e.code_exam,
                       ea.code_exam_alias,
                       e.id_content       id_cnt_img_exam,
                       ec.code_exam_cat,
                       ec.id_content      id_cnt_exam_cat,
                       e.gender,
                       e.age_min,
                       e.age_max,
                       e.flg_technical,
                       e.id_exam          id_img_exam,
                       e.create_time
                  FROM exam e
                  JOIN exam_cat ec
                    ON ec.id_exam_cat = e.id_exam_cat
                   AND ec.flg_available = 'Y'
                  LEFT JOIN alert.exam_alias ea
                    ON ea.id_exam = e.id_exam
                   AND ea.id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')
                   AND ea.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
                 WHERE e.flg_type = 'I'
                   AND e.flg_available = 'Y'
                   AND e.id_content = sys_context('ALERT_CONTEXT', 'SEARCH_TEXT')))
 WHERE desc_img_exam IS NOT NULL
 ORDER BY 1;
