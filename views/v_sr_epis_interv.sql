CREATE OR REPLACE VIEW V_SR_EPIS_INTERV AS
SELECT sei.id_sr_epis_interv,
       sei.id_episode,
       sei.id_sr_intervention,
       sei.id_prof_req,
       sei.flg_type,
       sei.flg_status,
       sei.notes_cancel,
       sei.id_prof_cancel,
       sei.id_sr_cancel_reason,
       sei.dt_req_tstz,
       sei.dt_interv_start_tstz,
       sei.dt_interv_end_tstz,
       sei.dt_cancel_tstz,
       sei.id_episode_context,
       sei.name_interv,
       sei.id_prof_req_unc,
       sei.dt_req_unc_tstz,
       sei.flg_code_type,
       sei.laterality,
       sei.flg_surg_request,
       ed.id_diagnosis,
       sei.notes,
       sei.id_epis_diagnosis
  FROM sr_epis_interv sei
  LEFT OUTER JOIN epis_diagnosis ed
    ON ed.id_epis_diagnosis = sei.id_epis_diagnosis;
