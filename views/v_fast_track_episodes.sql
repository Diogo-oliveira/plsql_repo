CREATE OR REPLACE VIEW V_FAST_TRACK_EPISODES AS 
SELECT VALUE epis_ext_sys,
       dt_begin_tstz epis_dt_begin_tstz,
       pk_patient.get_pat_age(language_id, id_patient, profissional(NULL, id_institution, software_id)) patient_age,
       (SELECT pk_date_utils.dt_chr_date_hour_tsz(language_id,
                                                  dt_begin_tstz,
                                                  profissional(NULL, id_institution, software_id))
          FROM dual) admission_date,
       id_fast_track,
       pk_translation.get_translation(language_id, code_fast_track) fast_track,
       flg_status fast_track_status,
       (SELECT pk_date_utils.dt_chr_date_hour_tsz(language_id,
                                                  dt_triage,
                                                  profissional(NULL, id_institution, software_id))
          FROM dual) dt_begin_triage,
       (SELECT pk_translation.get_translation(language_id, 'TRIAGE_COLOR.CODE_TRIAGE_COLOR.' || id_triage_color)
          FROM dual) AS triage_color,
       (SELECT pk_translation.get_translation(language_id, 'TRIAGE_BOARD.CODE_TRIAGE_BOARD.' || id_triage_board)
          FROM dual) AS triage_fluxogram,
       (SELECT pk_date_utils.dt_chr_date_hour_tsz(language_id,
                                                  dt_enable,
                                                  profissional(NULL, id_institution, software_id))
          FROM dual) fast_track_enable,
       (SELECT pk_date_utils.dt_chr_date_hour_tsz(language_id,
                                                  dt_disable,
                                                  profissional(NULL, id_institution, software_id))
          FROM dual) fast_trak_disable,
       (SELECT pk_date_utils.dt_chr_date_hour_tsz(language_id,
                                                  dt_activation,
                                                  profissional(NULL, id_institution, software_id))
          FROM dual) fast_trak_activation,
       flg_type flg_type_fast_track,
       (SELECT pk_sysdomain.get_domain('EPIS_FAST_TRACK.FLG_TYPE', flg_type, language_id)
          FROM dual) fast_tack_type,
       (SELECT pk_translation.get_translation(language_id, 'ROOM.CODE_ROOM.' || id_room_to)
          FROM dual) AS first_room,
       (SELECT pk_translation.get_translation(language_id, 'ROOM.CODE_ROOM.' || id_actual_room)
          FROM dual) AS actual_room,
       (SELECT pk_date_utils.dt_chr_date_hour_tsz(language_id,
                                                  dt_med_tstz,
                                                  profissional(NULL, id_institution, software_id))
          FROM dual) discharge_date,
       pk_translation.get_translation(language_id, code_discharge_reason) discharge_reason,
       pk_translation.get_translation(language_id, code_discharge_dest) discharge_destination
  FROM (SELECT e.id_patient,
               e.id_institution,
               ees.value,
               e.dt_begin_tstz,
               eft.flg_status,
               eft.id_fast_track,
               ft.code_fast_track,
               eft.flg_type,
               eft.dt_enable,
               eft.dt_disable,
               eft.dt_activation,
               d.dt_med_tstz,
               dd.code_discharge_dest,
               dr.code_discharge_reason,
               et.id_triage_color,
               et.dt_begin_tstz dt_triage,
               t.id_triage_board,
               (SELECT pk_sysconfig.get_config('LANGUAGE', e.id_institution, 0)
                  FROM dual) language_id,
               id_room_to,
               ei.id_room id_actual_room,
               8 software_id
          FROM alert.fast_track ft
         INNER JOIN alert.epis_fast_track eft
            ON ft.id_fast_track = eft.id_fast_track
         INNER JOIN alert.epis_triage et
            ON et.id_epis_triage = eft.id_epis_triage
          JOIN triage t
            ON et.id_triage = t.id_triage
          JOIN episode e
            ON et.id_episode = e.id_episode
         INNER JOIN alert.epis_ext_sys ees
            ON e.id_episode = ees.id_episode
          JOIN epis_info ei
            ON e.id_episode = ei.id_episode
          LEFT JOIN alert.discharge d
            ON d.id_episode = e.id_episode
           AND d.flg_status IN ('A', 'P')
          LEFT JOIN alert.disch_reas_dest drd
            ON d.id_disch_reas_dest = drd.id_disch_reas_dest
          LEFT JOIN alert.discharge_reason dr
            ON drd.id_discharge_reason = dr.id_discharge_reason
          LEFT JOIN alert.discharge_dest dd
            ON drd.id_discharge_dest = dd.id_discharge_dest       
          LEFT JOIN (SELECT mov.id_room_to,
                           mov.id_episode,
                           rank() over(PARTITION BY mov.id_episode ORDER BY mov.dt_begin_tstz ASC NULLS LAST, mov.dt_req_tstz ASC) AS mov_rank
                      FROM alert.movement mov) mov
            ON (mov.id_episode = e.id_episode)
           AND mov_rank = 1
         WHERE e.dt_begin_tstz > CAST(current_timestamp - 30 AS TIMESTAMP WITH LOCAL TIME ZONE)
         ORDER BY eft.create_time ASC);
/         
