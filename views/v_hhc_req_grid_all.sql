CREATE OR REPLACE VIEW V_HHC_REQ_GRID_ALL AS
SELECT ehr.id_epis_hhc_req, ehr.id_episode, ehr.flg_status, ehr.id_prof_manager, ehr.id_patient, ehr.id_epis_hhc, ve.id_institution
  FROM v_hhc_request ehr
  join v_episode ve on ehr.id_episode=ve.id_episode;
