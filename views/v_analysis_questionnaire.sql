CREATE OR REPLACE VIEW v_analysis_questionnaire AS
SELECT 
		aq.id_analysis_questionnaire,
		aq.id_analysis,
		nvl(aq.id_analysis,-1) as id_analysis_nvl,
		aq.id_questionnaire,
		aq.flg_time,
		aq.flg_type,
		aq.flg_mandatory,
		aq.rank,
		aq.flg_available,
		aq.id_sample_type,
		nvl(aq.id_sample_type,-1) as id_sample_type_nvl,
		id_analysis_group,
		nvl(aq.id_analysis_group,-1) as id_analysis_group_nvl,
		aq.id_response,
		nvl(aq.id_response,-1) as id_response_nvl,
		aq.flg_copy,
		aq.flg_validation,
		aq.flg_exterior,
		aq.id_unit_measure,
		aq.id_institution
  FROM analysis_questionnaire aq;
  