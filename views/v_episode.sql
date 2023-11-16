-- CHANGED BY: Bruno Martins
-- CHANGED DATE: 2015-01-06
-- CHANGE REASON: ADT-8646

CREATE OR REPLACE VIEW V_EPISODE AS
SELECT e.id_episode,
       e.id_epis_type,
       e.flg_type,
       e.flg_status              AS epis_flg_status,
       e.dt_begin_tstz           AS episode_dt_begin_tstz,
       e.dt_end_tstz             AS episode_dt_end_tstz,
       e.id_prof_cancel,
       e.dt_cancel_tstz,
       e.desc_cancel_reason,
       e.id_prev_episode,
       e.companion,
       e.id_visit,
       e.id_department,
       e.flg_ehr,
       e.flg_migration,
       v.id_institution,
       v.flg_status              AS visit_flg_status,
       e.id_patient,
       v.id_origin,
       v.id_external_cause,
       v.dt_begin_tstz           AS visit_dt_begin_tstz,
       v.dt_end_tstz             AS visit_dt_end_tstz,
       ei.id_first_dep_clin_serv,
       ei.id_dep_clin_serv,
       ei.id_room,
       ei.id_bed,
       ei.flg_status             AS epis_info_flg_status,
       ei.id_professional,
       ei.id_first_nurse_resp,
       ei.dt_first_obs_tstz,
       ei.dt_init,
       ei.id_software,
       ei.id_schedule,
       ref.id_external_request   AS referal_id_external_request,
       aeds.id_incident_location,
       ainp.flg_admission_type,
       --pre_hosp_accident
       pha.flg_prot_device,
       pha.flg_rta_pat_typ,
       pha.rta_pat_typ_ft,
       pha.flg_is_driv_own,
       pha.flg_police_involved,
       pha.police_num,
       pha.police_station,
       pha.police_accident_num,
       e.barcode,
       aadt.ticket_number,
       pk_api_visit.get_dt_intake_time(e.id_episode) dt_intake_time
  FROM episode e
  JOIN visit v
    ON e.id_visit = v.id_visit
  JOIN epis_info ei
    ON ei.id_episode = e.id_episode
  LEFT JOIN ref_map REF
    ON ref.id_episode = e.id_episode
   AND ref.flg_status = 'A'
  LEFT JOIN episode_adt eadt
    ON e.id_episode = eadt.id_episode
  LEFT JOIN admission_adt aadt
    ON eadt.id_episode_adt = aadt.id_episode_adt
  LEFT JOIN admission_edis aeds
    ON aadt.id_admission_adt = aeds.id_admission_edis
  LEFT JOIN admission_inpatient ainp
    ON aadt.id_admission_adt = ainp.id_admission_inpatient
  LEFT JOIN pre_hosp_accident pha
    ON (pha.id_episode = e.id_episode AND pha.flg_status = 'A');

-- CHANGED END: Bruno Martins


-- CHANGED BY: filipe.f.pereira
-- CHANGE DATE:
-- CHANGE REASON: ALERT-329254 
CREATE OR REPLACE VIEW ALERT.V_EPISODE AS
SELECT e.id_episode,
       e.id_epis_type,
       e.flg_type,
       e.flg_status              AS epis_flg_status,
       e.dt_begin_tstz           AS episode_dt_begin_tstz,
       e.dt_end_tstz             AS episode_dt_end_tstz,
       e.id_prof_cancel,
       e.dt_cancel_tstz,
       e.desc_cancel_reason,
       e.id_prev_episode,
       e.companion,
       e.id_visit,
       e.id_department,
       e.flg_ehr,
       e.flg_migration,
       v.id_institution,
       v.flg_status              AS visit_flg_status,
       e.id_patient,
       v.id_origin,
       v.id_external_cause,
       v.dt_begin_tstz           AS visit_dt_begin_tstz,
       v.dt_end_tstz             AS visit_dt_end_tstz,
       ei.id_first_dep_clin_serv,
       ei.id_dep_clin_serv,
       ei.id_room,
       ei.id_bed,
       ei.flg_status             AS epis_info_flg_status,
       ei.id_professional,
       ei.id_first_nurse_resp,
       ei.dt_first_obs_tstz,
       ei.dt_init,
       ei.id_software,
       ei.id_schedule,
       ref.id_external_request   AS referal_id_external_request,
       aeds.id_incident_location,
       ainp.flg_admission_type,
       ainp.flg_hospitalization_type,
       ainp.id_prescribing_physician,
       --pre_hosp_accident
       pha.flg_prot_device,
       pha.flg_rta_pat_typ,
       pha.rta_pat_typ_ft,
       pha.flg_is_driv_own,
       pha.flg_police_involved,
       pha.police_num,
       pha.police_station,
       pha.police_accident_num,
       e.barcode,
       aadt.ticket_number,
       pk_api_visit.get_dt_intake_time(e.id_episode) dt_intake_time
  FROM episode e
  JOIN visit v
    ON e.id_visit = v.id_visit
  JOIN epis_info ei
    ON ei.id_episode = e.id_episode
  LEFT JOIN ref_map REF
    ON ref.id_episode = e.id_episode
   AND ref.flg_status = 'A'
  LEFT JOIN episode_adt eadt
    ON e.id_episode = eadt.id_episode
  LEFT JOIN admission_adt aadt
    ON eadt.id_episode_adt = aadt.id_episode_adt
  LEFT JOIN admission_edis aeds
    ON aadt.id_admission_adt = aeds.id_admission_edis
  LEFT JOIN admission_inpatient ainp
    ON aadt.id_admission_adt = ainp.id_admission_inpatient
  LEFT JOIN pre_hosp_accident pha
    ON (pha.id_episode = e.id_episode AND pha.flg_status = 'A');
-- CHANGE END: filipe.f.pereira
