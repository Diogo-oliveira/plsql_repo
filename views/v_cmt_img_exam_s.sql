CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_IMG_EXAM_S AS
SELECT "DESC_IMG_EXAM",
       "ID_CNT_IMG_EXAM",
       "DESC_EXAM_CAT",
       "ID_CNT_EXAM_CAT",
       "GENDER",
       "AGE_MIN",
       "AGE_MAX",
       "FLG_PAT_RESP",
       "FLG_PAT_PREP",
       "RANK",
       "FLG_EXECUTE",
       "FLG_FIRST_RESULT",
       "FLG_MOV_PAT",
       "FLG_TIMEOUT",
       "FLG_RESULT_NOTES",
       "FLG_FIRST_EXECUTE",
       "FLG_CHARGEABLE",
       "FLG_TECHNICAL",
       "FLG_PRIORITY",
       "DESC_ALIAS"
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), e.code_exam)
                  FROM dual) desc_img_exam,
               e.id_content id_cnt_img_exam,
               (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), ec.code_exam_cat)
                  FROM dual) desc_exam_cat,
               ec.id_content id_cnt_exam_cat,
               e.gender,
               e.age_min,
               e.age_max,
               NULL AS flg_pat_resp,
               NULL AS flg_pat_prep,
               NULL AS rank,
               NULL AS flg_execute,
               NULL AS flg_first_result,
               NULL AS flg_mov_pat,
               NULL AS flg_timeout,
               NULL AS flg_result_notes,
               NULL AS flg_first_execute,
               NULL AS flg_chargeable,
               e.flg_technical,
               (SELECT val
                  FROM TABLE(pk_sysdomain.get_values_domain_pipelined(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                                      profissional(0,
                                                                                   sys_context('ALERT_CONTEXT',
                                                                                               'ID_INSTITUTION'),
                                                                                   sys_context('ALERT_CONTEXT',
                                                                                               'ID_SOFTWARE')),
                                                                      'EXAM_REQ.PRIORITY',
                                                                      NULL))
                 WHERE rownum = 1) flg_priority,
               NULL AS desc_alias
          FROM alert.exam e
         INNER JOIN alert.exam_cat ec
            ON ec.id_exam_cat = e.id_exam_cat
           AND ec.flg_available = 'Y'
           AND ec.flg_lab = 'N'
         INNER JOIN TABLE(pk_translation.get_search_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), sys_context('ALERT_CONTEXT', 'SEARCH_TEXT'), 'EXAM.CODE_EXAM')) t
            ON t.code_translation = e.code_exam
         WHERE e.flg_type = 'I'
           AND e.flg_available = 'Y'
           AND e.id_exam NOT IN (SELECT edcs.id_exam
                                   FROM alert.exam_dep_clin_serv edcs
                                  WHERE edcs.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
                                    AND edcs.flg_type = 'P'
                                    AND edcs.id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')))
 WHERE desc_img_exam IS NOT NULL
   AND desc_exam_cat IS NOT NULL;

