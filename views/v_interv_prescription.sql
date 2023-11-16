CREATE OR REPLACE VIEW v_interv_prescription AS
SELECT id_interv_prescription,
       id_episode,
       id_professional,
       id_institution,
       flg_time,
       flg_status,
       id_prof_cancel,
       notes_cancel,
       notes,
       id_episode_origin,
       id_episode_destination,
       id_prev_episode,
       dt_interv_prescription_tstz,
       dt_begin_tstz,
       dt_cancel_tstz,
       id_patient,
       id_prof_last_update,
       dt_last_update_tstz
  FROM interv_prescription;
