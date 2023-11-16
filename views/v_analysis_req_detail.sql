CREATE OR REPLACE VIEW v_analysis_req_detail AS
SELECT ard.id_analysis_req,
       ard.id_analysis_req_det,
       ard.id_analysis,
       a.code_analysis,
       ar.id_episode,
       ar.id_episode_origin,
       e.id_visit,
       c.id_codification,
       c.code_codification,
       ac.standard_code,
       ard.id_analysis_codification,
       h.prof_dep_clin_serv,
       h.id_prof_harvest id_prof_performed,
       h.dt_harvest_tstz dt_start_performing_tstz,
       mrd.id_diagnosis clinical_indication,
       mrd.id_epis_diagnosis,
       pk_hand_off.get_epis_dcs(NULL, NULL, ar.id_episode, NULL, h.dt_harvest_tstz) place_of_service,
       csh.id_prof_ordered_by id_prof_order,
       ar.id_prof_writes id_prof_performed_reg,
       h.id_prof_cancels,
       h.id_cancel_reason,
       h.notes_cancel
  FROM analysis_req_det ard
 INNER JOIN analysis_req ar
    ON ar.id_analysis_req = ard.id_analysis_req
  LEFT JOIN co_sign_hist csh
    ON (ard.id_co_sign_order = csh.id_co_sign_hist)
 INNER JOIN episode e
    ON nvl(ar.id_episode, ar.id_episode_origin) = e.id_episode
 INNER JOIN analysis a
    ON a.id_analysis = ard.id_analysis
 INNER JOIN analysis_harvest ah
    ON ah.id_analysis_req_det = ard.id_analysis_req_det
 INNER JOIN harvest h
    ON h.id_harvest = ah.id_harvest
  LEFT OUTER JOIN mcdt_req_diagnosis mrd
    ON mrd.id_analysis_req_det = ard.id_analysis_req_det
  LEFT OUTER JOIN analysis_codification ac
    ON ac.id_analysis_codification = ard.id_analysis_codification
  LEFT OUTER JOIN codification c
    ON c.id_codification = ac.id_codification;
