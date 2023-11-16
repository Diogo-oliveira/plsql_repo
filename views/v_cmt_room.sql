CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_ROOM AS
SELECT desc_room || ' (' || desc_dept || '-' || desc_department || ')' desc_room,
       id_room,
       capacity,
       flg_lab,
       flg_wait,
       flg_transp
  FROM (SELECT desc_room, desc_dept, desc_department, id_room, capacity, flg_lab, flg_wait, flg_transp
          FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), b.code_room)
                          FROM dual) AS desc_room,
                       (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), e.code_dept)
                          FROM dual) AS desc_dept,
                       (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                              d.code_department)
                          FROM dual) AS desc_department,
                       b.id_room,
                       b.capacity,
                       b.flg_lab,
                       b.flg_wait,
                       b.flg_transp
                  FROM room b
                  JOIN department d
                    ON d.id_department = b.id_department
                   AND d.flg_available = 'Y'
                   AND d.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
                  JOIN alert.dept e
                    ON e.id_dept = d.id_dept
                   AND e.flg_available = 'Y'
                 WHERE b.flg_available = 'Y')
         WHERE desc_room IS NOT NULL
           AND desc_department IS NOT NULL);

