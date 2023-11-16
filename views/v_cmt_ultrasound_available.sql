CREATE OR REPLACE VIEW v_cmt_ultrasound_available AS
SELECT desc_ultrasound,
       desc_alias,
       id_cnt_ultrasound,
       id_ultrasound,
       rank,
       flg_execute,
       flg_first_result,
       flg_mov_pat,
       flg_timeout,
       flg_result_notes,
       flg_first_execute,
       flg_chargeable,
       flg_priority,
       flg_bypass_validation,
       desc_room,
       id_room
  FROM (SELECT desc_ultrasound,
               desc_alias,
               id_cnt_ultrasound,
               id_ultrasound,
               rank,
               flg_execute,
               flg_first_result,
               flg_mov_pat,
               flg_timeout,
               flg_result_notes,
               flg_first_execute,
               flg_chargeable,
               flg_priority,
               flg_bypass_validation,
               desc_room,
               id_room
          FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), e.code_exam)
                          FROM dual) desc_ultrasound,
                       (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                              ea.code_exam_alias)
                          FROM dual) desc_alias,
                       e.id_content id_cnt_ultrasound,
                       e.id_exam id_ultrasound,
                       edcs.rank,
                       edcs.flg_execute,
                       edcs.flg_first_result,
                       edcs.flg_mov_pat,
                       edcs.flg_timeout,
                       edcs.flg_result_notes,
                       edcs.flg_first_execute,
                       edcs.flg_chargeable,
                       (nvl(er.id_room, NULL)) id_room,
                       (nvl2(er.id_room,
                             pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), r.code_room),
                             'In this facility')) desc_room,
                       edcs.flg_priority,
                       etg.flg_bypass_validation,
                       row_number() over(PARTITION BY e.id_exam ORDER BY er.id_exam_dep_clin_serv NULLS LAST, er.flg_default DESC, er.id_room DESC) rn
                  FROM exam e
                  JOIN exam_dep_clin_serv edcs
                    ON edcs.id_exam = e.id_exam
                   AND edcs.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
                   AND edcs.flg_type = 'P'
                   AND edcs.id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')
                  JOIN exam_type_group etg
                    ON etg.id_exam = e.id_exam
                   AND etg.id_software IN (sys_context('ALERT_CONTEXT', 'ID_SOFTWARE'), 0)
                   AND etg.id_institution IN (sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'), 0)
                  JOIN exam_type et
                    ON et.id_exam_type = etg.id_exam_type
                   AND et.flg_type = 'U'
                  LEFT JOIN exam_room er
                    ON er.id_exam = e.id_exam
                   AND er.flg_available = 'Y'
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
                   AND ea.id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')
                   AND ea.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
                 WHERE e.flg_available = 'Y'
                   AND e.flg_type = 'I')
         WHERE rn = 1
           AND desc_ultrasound IS NOT NULL)
 ORDER BY 1;
