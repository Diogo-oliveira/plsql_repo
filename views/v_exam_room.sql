-- CHANGED BY: Telmo Castro
-- CHANGE DATE: 26-05-2010
-- CHANGE REASON: ALERT-100583
CREATE OR REPLACE VIEW V_EXAM_ROOM AS
SELECT er.id_exam_room, er.id_exam, er.id_room, er.flg_available
  FROM exam_room er;
-- CHANGE END: Telmo Castro	
	