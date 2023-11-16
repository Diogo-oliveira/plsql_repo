CREATE OR REPLACE VIEW v_pat_history_diagnosis AS
SELECT phd.id_pat_history_diagnosis,
       phd.id_professional,
       flg_status,
       phd.flg_nature,
       phd.id_diagnosis,
       phd.id_epis_complaint,
       phd.id_pat_history_diagnosis_new,
       phd.flg_compl,
       phd.id_alert_diagnosis,
       phd.flg_recent_diag,
       phd.flg_type,
       phd.id_patient,
       phd.id_episode,
       phd.id_institution,
       phd.dt_pat_history_diagnosis_tstz,
       phd.notes,
       phd.id_pat_problem_mig,
       phd.flg_aproved_mig,
       phd.desc_pat_history_diagnosis,
       phd.id_pat_problem_hist_mig,
       phd.id_cancel_reason,
       phd.flg_warning,
       -- Diagnosis translation code
       d.code_diagnosis,
       -- Standard
       d.id_codification,
       -- Terminology
       d.id_terminology_version,
       -- Code
       d.code_icd,
       d.id_content,
       -- Recorder acting specialty
       pk_prof_utils.get_reg_prof_id_dcs(phd.id_professional, phd.dt_pat_history_diagnosis_tstz, phd.id_episode) prof_id_dcs,
       phd.dt_diagnosed,
       phd.dt_diagnosed_precision,
       phd.dt_resolved,
       phd.dt_resolved_precision
  FROM pat_history_diagnosis phd
  JOIN diagnosis d
    ON d.id_diagnosis = phd.id_diagnosis;
