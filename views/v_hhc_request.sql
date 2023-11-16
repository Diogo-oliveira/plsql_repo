CREATE OR REPLACE VIEW V_HHC_REQUEST AS
SELECT ehr.id_epis_hhc_req, ehr.id_episode, ehr.flg_status, ehr.id_prof_manager, ehr.id_patient, ehr.id_epis_hhc
  FROM v_epis_hhc_req ehr;
