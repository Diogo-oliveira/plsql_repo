CREATE OR REPLACE VIEW v_paramedical_all_appointments as
SELECT s.id_schedule,
       sg.id_patient,
       (SELECT cr.num_clin_record
          FROM clin_record cr
         WHERE cr.id_patient = sg.id_patient
           AND cr.id_institution = s.id_instit_requested
           AND rownum < 2) num_clin_record,
       ei.id_episode,
       ei.id_episode id_episode_by_pat,
       e.flg_ehr,
       e.id_epis_type,
       sp.flg_state,
       e.dt_begin_tstz,
       pat.gender,
       ei.id_dep_clin_serv,
       sp.dt_target_tstz,
       s.flg_status,
       sp.flg_sched,
       s.id_dcs_requested,
       s.reason_notes,
       s.flg_vacancy,
       ei.id_room,
       e.flg_appointment_type,
       sg.flg_contact_type,
       ei.id_professional,
       spo.id_professional id_professional_sch_outp,
       current_timestamp dt_server,
       sys_context('ALERT_CONTEXT', 'l_lang') i_lang,
       sys_context('ALERT_CONTEXT', 'l_prof_id') i_prof_id,
       sys_context('ALERT_CONTEXT', 'l_prof_institution') i_prof_institution,
       sys_context('ALERT_CONTEXT', 'l_prof_software') i_prof_software
  FROM schedule_outp sp
  JOIN schedule s
    ON s.id_schedule = sp.id_schedule
   AND s.id_instit_requested = sys_context('ALERT_CONTEXT', 'l_prof_institution')
  JOIN sch_prof_outp spo
    ON spo.id_schedule_outp = sp.id_schedule_outp
  JOIN sch_group sg
    ON sg.id_schedule = s.id_schedule
  JOIN epis_type et
    ON et.id_epis_type = sp.id_epis_type
  LEFT JOIN epis_info ei
    ON ei.id_schedule = s.id_schedule
  LEFT JOIN episode e
    ON e.id_episode = ei.id_episode
  LEFT JOIN patient pat
    ON pat.id_patient = sg.id_patient
 WHERE sp.dt_target_tstz BETWEEN CAST((SELECT pk_date_utils.get_string_tstz(i_lang      => alert_context('l_lang'),
                                                                            i_prof      => profissional(alert_context('l_prof_id'),
                                                                                                        alert_context('l_prof_institution'),
                                                                                                        alert_context('l_prof_software')),
                                                                            i_timestamp => alert_context('l_dt_min'),
                                                                            i_timezone  => '')
                                         FROM dual) AS TIMESTAMP WITH LOCAL TIME ZONE) AND
       CAST((SELECT pk_date_utils.get_string_tstz(i_lang      => alert_context('l_lang'),
                                                  i_prof      => profissional(alert_context('l_prof_id'),
                                                                              alert_context('l_prof_institution'),
                                                                              alert_context('l_prof_software')),
                                                  i_timestamp => alert_context('l_dt_max'),
                                                  i_timezone  => '')
               FROM dual) AS TIMESTAMP WITH LOCAL TIME ZONE)
   AND sp.id_software IN (sys_context('ALERT_CONTEXT', 'l_prof_software'), 312)
 	 AND (NOT(e.flg_status = 'I' AND e.flg_ehr = 'S'))
   AND s.flg_status NOT IN ('V', 'C');
