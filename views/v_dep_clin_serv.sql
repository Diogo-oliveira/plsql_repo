-- CHANGED BY: Telmo Castro
-- CHANGE DATE: 05-03-2010
-- CHANGE REASON: SCH_386
CREATE OR REPLACE VIEW V_DEP_CLIN_SERV AS
SELECT dcs.id_dep_clin_serv,
       dcs.id_clinical_service,
			 cs.code_clinical_service,
       dcs.id_department,
       dcs.flg_nurse_pre,
       dcs.flg_default,
       dcs.flg_available,
       dcs.flg_type,
       dcs.adm_age_min,
       dcs.adm_age_max,
       dcs.flg_coding,
       dcs.flg_just_post_presc,
       dcs.post_presc_num_hours
  FROM dep_clin_serv dcs
	join clinical_service cs on dcs.id_clinical_service = cs.id_clinical_service;
	
-- CHANGE END: Telmo Castro