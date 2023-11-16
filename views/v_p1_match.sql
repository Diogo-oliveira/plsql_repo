CREATE OR REPLACE VIEW v_p1_match AS 
SELECT id_match,
       id_patient,
       id_clin_record,
       id_institution,
       sequential_number_number,
       flg_status,
       id_prof_create,
       id_prof_cancel,
       id_match_prev,
       dt_create_tstz,
       dt_cancel_tstz,
       sequential_number,
       id_episode
  FROM p1_match;