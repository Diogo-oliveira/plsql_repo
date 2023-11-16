CREATE OR REPLACE VIEW v_analysis_result AS
SELECT ar.id_analysis_result,
       ar.id_analysis_req_det,
       ar.id_harvest,
       ar.id_analysis,
       ar.id_sample_type,
       ar.loinc_code,
       ar.id_exam_cat,
       ar.id_patient,
       ar.id_episode_orig,
       ar.id_episode,
       ar.id_visit,
       ar.id_institution,
       ar.dt_analysis_result_tstz,
       ar.dt_sample,
       ar.id_professional,
       ar.flg_type,
       ar.flg_status,
       ar.id_result_status,
       ar.id_prof_req,
       ar.flg_result_origin,
       ar.result_origin_notes,
       ar.notes,
       ar.flg_orig_analysis
  FROM analysis_result ar;