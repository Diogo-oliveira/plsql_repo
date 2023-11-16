-- CHANGED BY: Telmo
-- CHANGE DATE: 27-06-2013
-- CHANGE REASON: ALERT-260738
CREATE OR REPLACE VIEW V_SCH_UPG_EXAMS AS
SELECT v.*, se.id_exam, e.id_content id_content_exam, erd.id_exam_req_det external_id, 'R' req_flg_type
FROM V_SCH_UPG_BASE_VIEW v
  JOIN schedule_exam se ON v.ID_SCHEDULE = se.id_schedule -- one-to-many
  JOIN exam e ON se.id_exam = e.id_exam
  LEFT JOIN exam_req_det erd ON se.id_exam_req = erd.id_exam_req AND se.id_exam = erd.id_exam
WHERE v.FLG_SCH_TYPE IN ('E', 'X')
ORDER BY v.id_schedule;
--CHANGE END: Telmo
