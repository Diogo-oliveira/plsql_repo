CREATE OR REPLACE VIEW V_EPISODE_ALL_DIAGNOSES AS
SELECT ad.flg_icd9,
       ed.id_alert_diagnosis,
       d.code_icd,
       nvl(ad.code_alert_diagnosis, d.code_diagnosis) code_diagnosis,
       d.concept_type_int_name,
       d.flg_other,
       d.id_diagnosis,
       ed.desc_epis_diagnosis,
       ed.dt_base_tstz,
       ed.dt_cancel_tstz,
       ed.dt_confirmed_tstz,
       ed.dt_epis_diagnosis_tstz,
       ed.dt_initial_diag,
       ed.dt_rulled_out_tstz,
       ed.flg_final_type,
       ed.flg_status,
       ed.flg_type,
       ed.id_cancel_reason,
       ed.id_episode,
       ed.id_episode_origin,
       ed.id_epis_diagnosis,
       ed.id_professional_cancel,
       ed.id_professional_diag,
       ed.id_prof_base,
       ed.id_prof_confirmed,
       ed.id_prof_rulled_out,
       ed.notes,
       ed.notes_cancel,
       d.id_concept,
       ed.rank,
       ed.flg_is_complication
  FROM epis_diagnosis ed
  JOIN diagnosis d
    ON d.id_diagnosis = ed.id_diagnosis
  LEFT JOIN alert_diagnosis ad
    ON ad.id_alert_diagnosis = ed.id_alert_diagnosis;
