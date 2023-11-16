CREATE OR REPLACE VIEW v_cmt_other_exam AS
SELECT desc_other_exam,
       id_cnt_other_exam,
       desc_exam_cat,
       id_cnt_exam_cat,
       gender,
       age_min,
       age_max,
       rank,
       flg_execute,
       flg_first_result,
       flg_mov_pat,
       flg_timeout,
       flg_result_notes,
       flg_first_execute,
       flg_chargeable,
       flg_technical,
       flg_priority,
       desc_alias,
       id_other_exam
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), e.code_exam)
                  FROM dual) desc_other_exam,
               e.id_content id_cnt_other_exam,
               (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), ec.code_exam_cat)
                  FROM dual) desc_exam_cat,
               ec.id_content id_cnt_exam_cat,
               e.gender,
               e.age_min,
               e.age_max,
               edcs.rank,
               edcs.flg_execute,
               edcs.flg_first_result,
               edcs.flg_mov_pat,
               edcs.flg_timeout,
               edcs.flg_result_notes,
               edcs.flg_first_execute,
               edcs.flg_chargeable,
               e.flg_technical,
               (SELECT pk_exam_utils.get_alias_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                           profissional(0,
                                                                        sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                                                        sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')),
                                                           'EXAM.CODE_EXAM.' || e.id_exam,
                                                           NULL)
                  FROM dual) desc_alias,
               e.id_exam AS id_other_exam,
               (SELECT nvl(edcs.flg_priority,
                           (SELECT val
                              FROM TABLE(pk_sysdomain.get_values_domain_pipelined(sys_context('ALERT_CONTEXT',
                                                                                              'ID_LANGUAGE'),
                                                                                  profissional(0,
                                                                                               sys_context('ALERT_CONTEXT',
                                                                                                           'ID_INSTITUTION'),
                                                                                               sys_context('ALERT_CONTEXT',
                                                                                                           'ID_SOFTWARE')),
                                                                                  'EXAM_REQ.PRIORITY',
                                                                                  NULL))
                             WHERE rownum = 1))
                  FROM dual) flg_priority
          FROM exam e
         INNER JOIN alert.exam_cat ec
            ON ec.id_exam_cat = e.id_exam_cat
           AND ec.flg_available = 'Y'
           AND ec.flg_lab = 'N'
         INNER JOIN exam_dep_clin_serv edcs
            ON edcs.id_exam = e.id_exam
           AND edcs.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
           AND edcs.flg_type = 'P'
         WHERE e.flg_type = 'E'
           AND edcs.id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')
           AND e.flg_available = 'Y')
 WHERE desc_other_exam IS NOT NULL
   AND desc_exam_cat IS NOT NULL;
