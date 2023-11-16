CREATE OR REPLACE VIEW v_cmt_img_exam_available AS
WITH tmp AS
 (SELECT /*+ materialized */
   pk_sysconfig.get_config(i_code_cf => 'EXAMS_PERFORM_LOCATION',
                           i_prof    => profissional(0,
                                                     sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                                     sys_context('ALERT_CONTEXT', 'ID_SOFTWARE'))) AS RESULT
    FROM dual)
SELECT desc_img_exam,
       desc_alias,
       id_cnt_img_exam,
       id_img_exam,
       rank,
       flg_execute,
       flg_first_result,
       flg_mov_pat,
       flg_timeout,
       flg_result_notes,
       flg_first_execute,
       flg_chargeable,
       flg_priority,
       desc_room,
       id_room
  FROM (SELECT desc_img_exam,
               desc_alias,
               id_cnt_img_exam,
               id_img_exam,
               rank,
               flg_execute,
               flg_first_result,
               flg_mov_pat,
               flg_timeout,
               flg_result_notes,
               flg_first_execute,
               flg_chargeable,
               flg_priority,
               desc_room,
               id_room
          FROM (SELECT t.desc_translation desc_img_exam,
                       tt.desc_translation desc_alias,
                       e.id_content id_cnt_img_exam,
                       e.id_exam id_img_exam,
                       edcs.rank,
                       edcs.flg_execute,
                       edcs.flg_first_result,
                       edcs.flg_mov_pat,
                       edcs.flg_timeout,
                       edcs.flg_result_notes,
                       edcs.flg_first_execute,
                       edcs.flg_chargeable,
                       er.id_room,
                       ttt.desc_translation desc_room,
                       edcs.flg_priority,
                       row_number() over(PARTITION BY e.id_exam ORDER BY er.id_exam_dep_clin_serv NULLS LAST, ea.id_software DESC, er.id_room DESC) rn
                  FROM exam e
                  JOIN exam_dep_clin_serv edcs
                    ON edcs.id_exam = e.id_exam
                   AND edcs.flg_execute = 'Y'
                   AND edcs.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
                   AND edcs.flg_type = 'P'
                   AND edcs.id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')
                  JOIN exam_room er
                    ON er.id_exam = e.id_exam
                   AND er.flg_available = 'Y'
                   AND er.flg_default = 'Y'
                   AND (er.id_exam_dep_clin_serv IS NULL OR er.id_exam_dep_clin_serv = edcs.id_exam_dep_clin_serv)
                  JOIN room r
                    ON er.id_room = r.id_room
                   AND r.flg_available = 'Y'
                  JOIN department d
                    ON d.id_department = r.id_department
                   AND d.flg_available = 'Y'
                   AND d.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
                  JOIN v_cmt_translation_exam t
                    ON t.code_translation = e.code_exam
                  JOIN v_cmt_translation_room ttt
                    ON ttt.code_translation = r.code_room
                  LEFT JOIN exam_alias ea
                    ON ea.id_exam = e.id_exam
                   AND ea.id_software IN (sys_context('ALERT_CONTEXT', 'ID_SOFTWARE'), 0)
                   AND ea.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
                  LEFT JOIN v_cmt_translation_exam_alias tt
                    ON tt.code_translation = ea.code_exam_alias
                 WHERE e.flg_available = 'Y'
                   AND e.flg_type = 'I')
         WHERE rn = 1
           AND desc_img_exam IS NOT NULL
        UNION
        SELECT desc_img_exam,
               desc_alias,
               id_cnt_img_exam,
               id_img_exam,
               rank,
               flg_execute,
               flg_first_result,
               flg_mov_pat,
               flg_timeout,
               flg_result_notes,
               flg_first_execute,
               flg_chargeable,
               flg_priority,
               desc_room,
               id_room
          FROM (SELECT t.desc_translation desc_img_exam,
                       tt.desc_translation desc_alias,
                       e.id_content id_cnt_img_exam,
                       e.id_exam id_img_exam,
                       edcs.rank,
                       edcs.flg_execute,
                       edcs.flg_first_result,
                       edcs.flg_mov_pat,
                       edcs.flg_timeout,
                       edcs.flg_result_notes,
                       edcs.flg_first_execute,
                       edcs.flg_chargeable,
                       r.id_room,
                       ttt.desc_translation desc_room,
                       edcs.flg_priority,
                       row_number() over(PARTITION BY e.id_exam ORDER BY er.id_exam_dep_clin_serv NULLS LAST, ea.id_software DESC, er.id_room DESC) rn
                  FROM exam e
                  JOIN v_cmt_translation_exam t
                    ON t.code_translation = e.code_exam
                  JOIN exam_dep_clin_serv edcs
                    ON edcs.id_exam = e.id_exam
                   AND edcs.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
                   AND edcs.flg_type = 'P'
                   AND edcs.id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')
                   AND (edcs.flg_execute = 'N' OR
                       (SELECT RESULT
                           FROM tmp) = 'Y' AND edcs.flg_execute = 'N')
                  LEFT JOIN exam_room er
                    ON er.id_exam = e.id_exam
                   AND er.flg_available = 'Y'
                   AND er.flg_default = 'Y'
                   AND (er.id_exam_dep_clin_serv IS NULL OR er.id_exam_dep_clin_serv = edcs.id_exam_dep_clin_serv)
                   AND EXISTS (SELECT *
                          FROM room r
                          JOIN department d
                            ON d.id_department = r.id_department
                           AND d.flg_available = 'Y'
                           AND d.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
                         WHERE r.flg_available = 'Y'
                           AND r.id_room = er.id_room)
                  LEFT JOIN room r
                    ON er.id_room = r.id_room
                   AND r.flg_available = 'Y'
                  LEFT JOIN exam_alias ea
                    ON ea.id_exam = e.id_exam
                   AND ea.id_software IN (sys_context('ALERT_CONTEXT', 'ID_SOFTWARE'), 0)
                   AND ea.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
                  LEFT JOIN v_cmt_translation_exam_alias tt
                    ON tt.code_translation = ea.code_exam_alias
                  LEFT JOIN v_cmt_translation_room ttt
                    ON ttt.code_translation = r.code_room
                 WHERE e.flg_available = 'Y'
                   AND e.flg_type = 'I')
         WHERE rn = 1
           AND desc_img_exam IS NOT NULL)
 ORDER BY 1;
