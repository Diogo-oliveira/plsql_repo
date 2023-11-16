CREATE OR REPLACE VIEW v_interv_questionnaire AS
SELECT 
		iq.id_interv_questionnaire,
		iq.id_intervention,
		iq.id_questionnaire,
		iq.flg_time,
		iq.flg_type,
		iq.flg_mandatory,
		iq.rank,
		iq.flg_available,
		iq.id_response,
		nvl(iq.id_response,-1) as id_response_nvl,
		iq.flg_copy,
		iq.flg_validation,
		iq.flg_exterior,
		iq.id_unit_measure,
		iq.id_institution
  FROM interv_questionnaire iq;
  