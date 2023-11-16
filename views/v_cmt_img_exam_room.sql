CREATE OR REPLACE VIEW v_cmt_img_exam_room AS
WITH temp AS
 (SELECT /*+ materialized */
  DISTINCT avlb.id_img_exam AS id_exam
    FROM v_cmt_img_exam_available avlb),
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
SELECT desc_img_exam,
       id_cnt_img_exam,
       desc_room || ' (' || desc_dept || '-' || desc_department || ')' AS desc_room,
       id_room,
       rank,
       flg_default,
       id_exam_room AS id_record
  FROM (SELECT t.desc_translation    desc_img_exam,
               c.id_content          id_cnt_img_exam,
               tt.desc_translation   desc_room,
               ttt.desc_translation  desc_dept,
               tttt.desc_translation desc_department,
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
          JOIN v_cmt_translation_exam t
            ON t.code_translation = c.code_exam
          JOIN v_cmt_translation_room tt
            ON tt.code_translation = b.code_room
          JOIN v_cmt_translation_dept ttt
            ON ttt.code_translation = e.code_dept
          JOIN v_cmt_translation_department tttt
            ON tttt.code_translation = d.code_department
         WHERE a.flg_available = 'Y'
           AND (a.id_exam_dep_clin_serv IS NULL OR
               a.id_exam_dep_clin_serv IN (SELECT id_exam_dep_clin_serv
                                              FROM temp1 edcs
                                             WHERE edcs.id_exam = c.id_exam)))
 WHERE desc_img_exam IS NOT NULL
   AND desc_room IS NOT NULL;
