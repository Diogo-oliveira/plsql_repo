CREATE OR REPLACE  VIEW v_cmt_img_exam_available_s AS
WITH tmp AS
 (SELECT /*+ materialized */
   *
    FROM (SELECT DISTINCT id_cnt_img_exam,
                          (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), a.code_exam)
                             FROM dual) desc_translation,
                          (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                                 ea.code_exam_alias)
                             FROM dual) desc_alias
            FROM (SELECT id_cnt_img_exam, code_exam, id_exam
                    FROM (SELECT e.id_content id_cnt_img_exam, e.code_exam, e.id_exam
                            FROM exam e
                            JOIN TABLE(pk_translation.get_search_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), sys_context('ALERT_CONTEXT', 'SEARCH_TEXT'), 'EXAM.CODE_EXAM')) t
                              ON t.code_translation = e.code_exam
                           WHERE e.flg_available = 'Y'
                             AND e.flg_type = 'I'
                             AND lower(sys_context('ALERT_CONTEXT', 'SEARCH_TEXT')) != 'all'
                             AND instr(lower(sys_context('ALERT_CONTEXT', 'SEARCH_TEXT')), 'tmp2.') = 0
                             AND instr(lower(sys_context('ALERT_CONTEXT', 'SEARCH_TEXT')), 'cntx.') = 0)
                  UNION
                  SELECT id_cnt_img_exam, code_exam, id_exam
                    FROM (SELECT e.id_content id_cnt_img_exam, e.code_exam, e.id_exam
                            FROM exam e
                           WHERE e.flg_available = 'Y'
                             AND e.flg_type = 'I'
                             AND 'all' = lower(sys_context('ALERT_CONTEXT', 'SEARCH_TEXT')))
                  UNION
                  SELECT id_cnt_img_exam, code_exam, id_exam
                    FROM (SELECT e.id_content id_cnt_img_exam, e.code_exam, e.id_exam
                            FROM exam e
                           WHERE e.flg_available = 'Y'
                             AND e.flg_type = 'I'
                             AND e.id_content = sys_context('ALERT_CONTEXT', 'SEARCH_TEXT'))
                  MINUS
                  SELECT id_content id_cnt_img_exam, e.code_exam, e.id_exam
                    FROM exam e
                    JOIN v_cmt_img_exam_available avlb
                      ON e.id_content = avlb.id_cnt_img_exam) a
            LEFT JOIN exam_alias ea
              ON ea.id_exam = a.id_exam
             AND ea.id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')
             AND ea.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'))
   WHERE desc_translation IS NOT NULL)
SELECT desc_img_exam,
       desc_alias,
       id_cnt_img_exam,
       nvl(rank, 0) rank,
       nvl(flg_execute, 'Y') flg_execute,
       nvl(flg_first_result, 'DTN') flg_first_result,
       nvl(flg_mov_pat, 'N') flg_mov_pat,
       nvl(flg_timeout, 'N') flg_timeout,
       nvl(flg_result_notes, 'N') flg_result_notes,
       nvl(flg_first_execute, 'DTN') flg_first_execute,
       nvl(flg_chargeable, 'N') flg_chargeable,
       desc_room,
       id_room
  FROM (SELECT DISTINCT tmp.desc_translation desc_img_exam,
                        tmp.desc_alias       desc_alias,
                        tmp.id_cnt_img_exam,
                        NULL                 rank,
                        NULL                 flg_execute,
                        NULL                 flg_first_result,
                        NULL                 flg_mov_pat,
                        NULL                 flg_timeout,
                        NULL                 flg_result_notes,
                        NULL                 flg_first_execute,
                        NULL                 flg_chargeable,
                        NULL                 flg_priority,
                        NULL                 desc_room,
                        NULL                 id_room
          FROM exam e
          JOIN tmp tmp
            ON tmp.id_cnt_img_exam = e.id_content)
 ORDER BY 1;
