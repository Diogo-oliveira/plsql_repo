CREATE OR REPLACE VIEW v_exam_questionnaire AS
SELECT 
		eq.id_exam_questionnaire,
		eq.id_exam,
		nvl(eq.id_exam,-1) as id_exam_nvl,
		eq.id_questionnaire,
		eq.flg_time,
		eq.flg_type,
		eq.flg_mandatory,
		eq.rank,
		eq.flg_available,
		eq.id_exam_group,
		nvl(eq.id_exam_group,-1) as id_exam_group_nvl,
		eq.id_response,
		nvl(eq.id_response,-1) as id_response_nvl,
		eq.flg_copy,
		eq.flg_validation,
		eq.flg_exterior,
		eq.id_unit_measure,
		eq.id_institution
  FROM exam_questionnaire eq;
  