-- CHANGED BY: Telmo
-- CHANGE DATE: 08-04-2013
-- CHANGE REASON: ALERT-253594
CREATE OR REPLACE VIEW ALERT.V_EXAM_DEPARTMENTS AS
SELECT er.id_exam, 
             d.id_institution, 
             d.id_department
FROM exam_room er
  JOIN room r ON er.id_room = r.id_room
  JOIN department d ON r.id_department = d.id_department
GROUP BY er.id_exam, d.id_institution, d.id_department;
--CHANGE END: Telmo
