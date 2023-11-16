CREATE OR REPLACE VIEW v_cmt_other_exam_room AS
WITH temp AS
 (SELECT /*+ materialized */
  DISTINCT id_other_exam AS id_exam
    FROM v_cmt_other_exam_available),
temp1 AS
 (SELECT /*+ materialized */
  DISTINCT edcs.id_exam, edcs.id_exam_dep_clin_serv
    FROM exam_dep_clin_serv edcs
    JOIN exam e
      ON e.id_exam = edcs.id_exam
     AND e.flg_available = 'Y'
     AND e.flg_type = 'E'
   WHERE edcs.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
     AND edcs.flg_type = 'P'
     AND edcs.id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE'))
SELECT desc_other_exam,
       id_cnt_other_exam,
       desc_room || ' (' || desc_dept || '-' || desc_department || ')' desc_room,
       id_room,
       rank,
       flg_default,
       id_exam_room AS id_record
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), c.code_exam)
                  FROM dual) desc_other_exam,
               c.id_content id_cnt_other_exam,
               (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), b.code_room)
                  FROM dual) AS desc_room,
               (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), e.code_dept)
                  FROM dual) AS desc_dept,
               (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), d.code_department)
                  FROM dual) AS desc_department,
               b.id_room,
               a.rank,
               a.flg_default,
               a.id_exam_room
          FROM exam_room a
          JOIN temp tmp
            ON a.id_exam = tmp.id_exam
          JOIN exam c
            ON c.id_exam = tmp.id_exam
          JOIN room b
            ON b.id_room = a.id_room
           AND b.flg_available = 'Y'
          JOIN department d
            ON d.id_department = b.id_department
           AND d.flg_available = 'Y'
           AND d.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
          JOIN dept e
            ON e.id_dept = d.id_dept
           AND e.flg_available = 'Y'
         WHERE a.flg_available = 'Y'
           AND (a.id_exam_dep_clin_serv IS NULL OR
               a.id_exam_dep_clin_serv IN (SELECT id_exam_dep_clin_serv
                                              FROM temp1 edcs
                                             WHERE edcs.id_exam = c.id_exam)))
 WHERE desc_other_exam IS NOT NULL
   AND desc_room IS NOT NULL;
