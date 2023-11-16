CREATE OR REPLACE VIEW V_GRID_ORIS_BASE AS
SELECT ss.id_schedule ss_id_schedule,
       ss.id_episode ss_id_episode,
			 ss.id_sched_sr_parent ss_id_sched_sr_parent,
       ss.dt_interv_preview_tstz ss_dt_interv_preview_tstz,
			 ss.flg_status ss_flg_status,
       ss.dt_target_tstz ss_dt_target_tstz,
			 epis.id_visit e_id_visit,
			 epis.flg_status e_flg_status,
			 ei.id_dep_clin_serv ei_id_dep_clin_serv,
			 p.gender p_gender,
       p.id_patient p_id_patient,
       p.dt_birth p_dt_birth,
       p.age p_age,
			 m.flg_status m_flg_status,
			 m.dt_status_tstz m_dt_status_tstz,
			 m.id_episode m_id_episode,
       s.flg_urgency s_flg_urgency,
       st.dt_interv_start_tstz st_dt_interv_start_tstz,
       r.code_abbreviation r_code_abbreviation,
			 r.desc_room_abbreviation r_desc_room_abbreviation,
       r.id_room r_id_room,
       rec.flg_pat_status rec_flg_pat_status,
       gt.drug_presc gt_drug_presc,
       gt.hemo_req gt_hemo_req,
       gt.material_req gt_material_req,
       alert_context('i_lang') i_lang,
       alert_context('i_prof_id') i_prof_id,
       alert_context('i_institution') i_institution,
       alert_context('i_software') i_software,
       alert_context('l_limit_bp_transport') l_limit_bp_transport      
  FROM schedule_sr ss
  JOIN schedule s
    ON s.id_schedule = ss.id_schedule
  JOIN patient p
    ON p.id_patient = ss.id_patient
  JOIN episode epis
    ON epis.id_episode = ss.id_episode
  JOIN epis_info ei
    ON ei.id_episode = epis.id_episode
  JOIN institution i
    ON i.id_institution = ss.id_institution
  LEFT JOIN room_scheduled sr
    ON ss.id_schedule = sr.id_schedule
  LEFT JOIN room r
    ON sr.id_room = r.id_room
  LEFT JOIN (SELECT r.id_room, s.flg_status, s.dt_status_tstz, s.id_episode
               FROM room r
               LEFT JOIN sr_room_status s
                 ON r.id_room = s.id_room
              WHERE s.id_sr_room_state = pk_sr_grid.get_last_room_status(s.id_room, 'R')
                 OR s.id_sr_room_state IS NULL) m
    ON m.id_room = sr.id_room
  LEFT JOIN sr_surgery_record rec
    ON ss.id_schedule_sr = rec.id_schedule_sr
  LEFT JOIN grid_task gt
    ON epis.id_episode = gt.id_episode
  LEFT JOIN (SELECT std.id_episode, std.dt_surgery_time_det_tstz dt_interv_start_tstz
               FROM sr_surgery_time st, sr_surgery_time_det std
              WHERE st.id_sr_surgery_time = std.id_sr_surgery_time
                AND st.flg_type = 'IC'
                AND std.flg_status = 'A') st
    ON epis.id_episode = st.id_episode
 WHERE (sr.id_room_scheduled = pk_sr_grid.get_last_room_status(ss.id_schedule, 'S') OR sr.id_room_scheduled IS NULL)
   AND epis.flg_ehr != 'E'
   AND ss.id_institution = alert_context('i_institution');