CREATE OR REPLACE VIEW v_cmt_ultrasound_room AS
WITH temp AS
 (SELECT /*+ materialized */
  DISTINCT avlb.id_ultrasound id_exam
    FROM v_cmt_ultrasound_available avlb),
temp1 AS
 (SELECT /*+ materialized */
  DISTINCT e.id_exam, edcs.id_exam_dep_clin_serv
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
   WHERE e.flg_available = 'Y'
     AND e.flg_type = 'I')
SELECT desc_ultrasound,
       id_cnt_ultrasound,
       desc_room || ' (' || desc_dept || '-' || desc_department || ')' desc_room,
       id_room,
       rank,
       flg_default,
       id_exam_room id_record
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), c.code_exam)
                  FROM dual) desc_ultrasound,
               c.id_content id_cnt_ultrasound,
               (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), b.code_room)
                  FROM dual) desc_room,
               (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), e.code_dept)
                  FROM dual) desc_dept,
               (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), d.code_department)
                  FROM dual) desc_department,
               b.id_room,
               a.rank,
               a.flg_default,
               a.id_exam_room
          FROM exam_room a
          JOIN temp tmp
            ON a.id_exam = tmp.id_exam
          JOIN room b
            ON b.id_room = a.id_room
           AND b.flg_available = 'Y'
          JOIN exam c
            ON c.id_exam = a.id_exam
          JOIN department d
            ON d.id_department = b.id_department
           AND d.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
           AND d.flg_available = 'Y'
          JOIN dept e
            ON e.id_dept = d.id_dept
           AND e.flg_available = 'Y'
         WHERE a.flg_available = 'Y'
           AND (a.id_exam_dep_clin_serv IS NULL OR
               a.id_exam_dep_clin_serv IN (SELECT id_exam_dep_clin_serv
                                              FROM temp1 edcs
                                             WHERE edcs.id_exam = c.id_exam)))
 WHERE desc_ultrasound IS NOT NULL
   AND desc_room IS NOT NULL;
