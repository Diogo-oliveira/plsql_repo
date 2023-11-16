CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_BED AS
SELECT desc_bed || ' (' || desc_room || ' - ' || desc_dept || ' - ' || desc_department || ')' AS desc_bed,
       id_bed,
       bed_type,
       id_room
  FROM (SELECT desc_bed, desc_room, desc_dept, desc_department, id_room, id_bed, bed_type
          FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), b.code_bed)
                          FROM dual) AS desc_bed,
                       (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), r.code_room)
                          FROM dual) AS desc_room,
                       r.id_room,
                       (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                              d.code_department)
                          FROM dual) AS desc_department,
                       (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), e.code_dept)
                          FROM dual) AS desc_dept,
                       b.id_bed,
                       (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                                      code_bed_type)
                                  FROM alert.bed_type
                                 WHERE id_bed_type = b.id_bed_type)
                          FROM dual) AS bed_type
                  FROM bed b
                 INNER JOIN room r
                    ON r.id_room = b.id_room
                 INNER JOIN department d
                    ON d.id_department = r.id_department
                 INNER JOIN alert.dept e
                    ON e.id_dept = d.id_dept
                 WHERE d.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
                   AND r.flg_available = 'Y'
                   AND e.flg_available = 'Y'
                   AND d.flg_available = 'Y'
                   AND b.flg_available = 'Y'
                   AND b.flg_type = 'P')
         WHERE desc_room IS NOT NULL
           AND desc_bed IS NOT NULL
           AND desc_department IS NOT NULL)
 ORDER BY 1;

