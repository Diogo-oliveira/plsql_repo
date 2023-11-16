CREATE OR REPLACE VIEW v_intervention_detail AS
SELECT ipd.id_interv_prescription,
       ipd.id_interv_presc_det,
       ipp.id_interv_presc_plan,
       ipd.id_intervention,
       flg_interv_type,
       code_intervention,
       cpt_code,
       code_codification,
       c.id_codification id_codification,
       ipp.dt_take_tstz perf_date, -- Data da execu??o
       ipp.id_prof_take prof_perf_id, -- ID Profissional que registou a execu??o
       pk_prof_utils.get_name(NULL, ipp.id_prof_take) prof_perf_name,
       pk_prof_utils.get_reg_prof_id_dcs(ipp.id_prof_take, ipp.dt_take_tstz, ip.id_episode) performing_prof_spec,
       ipp.id_prof_performed, -- ID Profissional que documentou a execu??o
       csh.id_prof_ordered_by id_prof_order, -- ID Profissional que requisitou
       csh.id_prof_co_signed id_prof_co_sign, -- ID Profissional com co-sign
       mrd.id_diagnosis,
       mrd.id_epis_diagnosis diag_clinical_indication,
       --Place of Service
       pk_hand_off.get_epis_dcs(NULL, NULL, ipp.id_episode_write, NULL, ipp.dt_take_tstz) place_of_serv,
       nvl(ip.id_episode, ip.id_episode_origin) id_episode,
       e.id_visit,
       ipd.flg_laterality flg_laterality,
       ipp.id_prof_cancel,
       ipp.id_cancel_reason,
       ipp.notes_cancel
  FROM interv_presc_det ipd
  JOIN intervention i
    ON ipd.id_intervention = i.id_intervention
  JOIN interv_prescription ip
    ON ip.id_interv_prescription = ipd.id_interv_prescription
  LEFT JOIN co_sign_hist csh
    ON (ipd.id_co_sign_order = csh.id_co_sign_hist)
  JOIN episode e
    ON nvl(ip.id_episode, ip.id_episode_origin) = e.id_episode
  JOIN interv_presc_plan ipp
    ON ipp.id_interv_presc_det = ipd.id_interv_presc_det
  LEFT JOIN mcdt_req_diagnosis mrd
    ON mrd.id_interv_prescription = ip.id_interv_prescription
   AND mrd.id_interv_presc_det = ipd.id_interv_presc_det
  LEFT JOIN interv_codification ic
    ON ipd.id_intervention = ic.id_intervention
  LEFT JOIN codification c
    ON c.id_codification = ic.id_codification;
