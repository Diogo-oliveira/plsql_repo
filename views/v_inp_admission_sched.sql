CREATE OR REPLACE VIEW V_INP_ADMISSION_SCHED AS
SELECT epi.id_patient id_patient,
       epi.id_episode id_episode,
       epi.id_visit id_visit,
       ei.id_dep_clin_serv,
       'N' flg_cancel,
       pat.dt_birth pat_dt_birth,
       pat.age pat_age,
       pat.dt_deceased pat_dt_deceased,
       pat.gender pat_gender,
       ei.flg_unknown epis_flg_unknown,
       epi.flg_ehr epis_flg_ehr,
       epi.id_prev_episode id_prev_episode,
       NVL(s.dt_begin_tstz, epi.dt_begin_tstz) epis_dt_begin_tstz,
       ei.dt_last_interaction_tstz epis_dt_last_interaction_tstz,
       ei.dt_first_obs_tstz epis_dt_first_obs_tstz,
       s.id_schedule id_schedule,
       s.flg_status schedule_flg_status,
       s.dt_begin_tstz schedule_dt_begin_tstz,
       rs.id_room id_room,
       rs.desc_room room_desc,
       rs.code_room room_code,
       rs.rank room_rank,
       bd1.id_bed id_bed,
       bd1.desc_bed bed_desc,
       bd1.code_bed bed_code,
       CASE
            WHEN bd.id_bed IS NOT NULL THEN
             bd.rank
            ELSE
             bd1.rank
        END bed_rank,
       dpb.rank dep_rank,
       cli.code_clinical_service code_clinical_service,
       dpt.code_department code_department,
       nvl2(nvl(bd.code_bed, bd1.code_bed),
            nvl(pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'i_lang'), ds.abbreviation),
                pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'i_lang'), ds.code_department)),
            NULL) desc_service,
       pk_inp_grid.get_wl_sch_status(sys_context('ALERT_CONTEXT', 'i_lang'),
                                     profissional(sys_context('ALERT_CONTEXT', 'i_id_prof'),
                                                  sys_context('ALERT_CONTEXT', 'i_id_institution'),
                                                  sys_context('ALERT_CONTEXT', 'i_id_software')),
                                     epi.id_episode,
                                     s.id_schedule) wtl_epis_flg_status,
       pk_inp_grid.get_discharge_flg(sys_context('ALERT_CONTEXT', 'i_lang'),
                                     profissional(sys_context('ALERT_CONTEXT', 'i_id_prof'),
                                                  sys_context('ALERT_CONTEXT', 'i_id_institution'),
                                                  sys_context('ALERT_CONTEXT', 'i_id_software')),
                                     epi.id_episode) flg_discharge,
       'Y' scheduler_exists
  FROM episode epi
  JOIN patient pat
    ON epi.id_patient = pat.id_patient
  JOIN epis_info ei
    ON epi.id_episode = ei.id_episode
  LEFT JOIN bed bd
    ON bd.id_bed = ei.id_bed
  LEFT JOIN room rb 
	  ON bd.id_room = rb.id_room
	LEFT JOIN department drb
	  ON rb.id_department = drb.id_department
  LEFT JOIN schedule_bed sbd
    ON sbd.id_schedule = ei.id_schedule
  LEFT JOIN bed bd1
    ON bd1.id_bed = sbd.id_bed
  LEFT JOIN room rs
    ON rs.id_room = bd1.id_room
  LEFT JOIN department ds
    ON rs.id_department = ds.id_department
  LEFT JOIN room ro
    ON ro.id_room = ei.id_room
  LEFT JOIN department dpb
    ON dpb.id_department = ro.id_department
  LEFT JOIN dep_clin_serv dcs
    ON dcs.id_dep_clin_serv = ei.id_dep_clin_serv
  LEFT JOIN department dpt
    ON dpt.id_department = epi.id_department
   AND instr(dpt.flg_type, 'I') > 0
  LEFT JOIN department dpt_dcs
    ON dcs.id_department = dpt_dcs.id_department
  LEFT JOIN clinical_service cli
    ON cli.id_clinical_service = epi.id_clinical_service
  JOIN v_schedule_beds s
    ON s.id_episode = epi.id_episode
 WHERE sys_context('ALERT_CONTEXT', 'i_scheduler_exists') = 'Y'
   AND dpt_dcs.id_institution = sys_context('ALERT_CONTEXT', 'i_id_institution')
   AND epi.id_epis_type = 5
   AND epi.flg_ehr IN ('N', 'S')
   AND epi.flg_status = 'A'
   AND s.flg_status != 'C'
UNION ALL
SELECT epi.id_patient id_patient,
       epi.id_episode id_episode,
       epi.id_visit id_visit,
       ei.id_dep_clin_serv,
       'N' flg_cancel,
       pat.dt_birth pat_dt_birth,
       pat.age pat_age,
       pat.dt_deceased pat_dt_deceased,
       pat.gender pat_gender,
       ei.flg_unknown epis_flg_unknown,
       epi.flg_ehr epis_flg_ehr,
       epi.id_prev_episode id_prev_episode,
       epi.dt_begin_tstz epis_dt_begin_tstz,
       ei.dt_last_interaction_tstz epis_dt_last_interaction_tstz,
       ei.dt_first_obs_tstz epis_dt_first_obs_tstz,
       NULL id_schedule,
       NULL schedule_flg_status,
       NULL schedule_dt_begin_tstz,
       rs.id_room id_room,
       rs.desc_room room_desc,
       rs.code_room room_code,
       rs.rank room_rank,
        bd1.id_bed id_bed,
       bd1.desc_bed bed_desc,
       bd1.code_bed bed_code,
       CASE
           WHEN bd.id_bed IS NOT NULL THEN
            bd.rank
           ELSE
            bd1.rank
       END bed_rank,
       dpb.rank dep_rank,
       cli.code_clinical_service code_clinical_service,
       dpt.code_department code_department,
       nvl2(nvl(bd.code_bed, bd1.code_bed),
            nvl(pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'i_lang'), ds.abbreviation),
                pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'i_lang'), ds.code_department)),
            NULL) desc_service,
       NULL wtl_epis_flg_status,
       pk_inp_grid.get_discharge_flg(sys_context('ALERT_CONTEXT', 'i_lang'),
                                     profissional(sys_context('ALERT_CONTEXT', 'i_id_prof'),
                                                  sys_context('ALERT_CONTEXT', 'i_id_institution'),
                                                  sys_context('ALERT_CONTEXT', 'i_id_software')),
                                     epi.id_episode) flg_discharge,
       'N' scheduler_exists
  FROM episode epi
  JOIN patient pat
    ON epi.id_patient = pat.id_patient
  JOIN epis_info ei
    ON epi.id_episode = ei.id_episode
  LEFT JOIN bed bd
    ON bd.id_bed = ei.id_bed
  LEFT JOIN room rb 
	  ON bd.id_room = rb.id_room
	LEFT JOIN department drb
	  ON rb.id_department = drb.id_department
  LEFT JOIN schedule_bed sbd
    ON sbd.id_schedule = ei.id_schedule
  LEFT JOIN bed bd1
    ON bd1.id_bed = sbd.id_bed
  LEFT JOIN room rs
    ON rs.id_room = bd1.id_room
  LEFT JOIN department ds
    ON rs.id_department = ds.id_department
  LEFT JOIN room ro
    ON ro.id_room = ei.id_room
  LEFT JOIN department dpb
    ON dpb.id_department = ro.id_department
  LEFT JOIN dep_clin_serv dcs
    ON dcs.id_dep_clin_serv = ei.id_dep_clin_serv
  LEFT JOIN department dpt
    ON dpt.id_department = epi.id_department
   AND instr(dpt.flg_type, 'I') > 0
  LEFT JOIN department dpt_dcs
    ON dcs.id_department = dpt_dcs.id_department
  LEFT JOIN clinical_service cli
    ON cli.id_clinical_service = epi.id_clinical_service
  JOIN schedule_inp_bed sib
    ON sib.id_episode = epi.id_episode
 WHERE sys_context('ALERT_CONTEXT', 'i_scheduler_exists') = 'N'
   AND dpt_dcs.id_institution = sys_context('ALERT_CONTEXT', 'i_id_institution')
   AND epi.id_epis_type = 5
   AND epi.flg_ehr IN ('N', 'S')
   AND epi.flg_status = 'A';
