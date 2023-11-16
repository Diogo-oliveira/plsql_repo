CREATE OR REPLACE VIEW v_sys_alert_305 AS
SELECT /*+ opt_param('_OPTIMIZER_USE_FEEDBACK', 'FALSE') */
 v.id_sys_alert_event id_sys_alert_det,
 v.id_record id_reg,
 p1.id_episode,
 v.id_institution,
 sys_context('ALERT_CONTEXT', 'i_prof') id_prof,
 pk_date_utils.to_char_insttimezone(profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                 sys_context('ALERT_CONTEXT', 'i_institution'),
                                                 sys_context('ALERT_CONTEXT', 'i_software')),
                                    v.dt_record,
                                    'YYYYMMDDHH24MISS') dt_req,
 decode(instr(pk_date_utils.get_elapsed_sysdate_tsz(sys_context('ALERT_CONTEXT', 'i_lang'), v.dt_record), ':'),
        0,
        pk_date_utils.get_elapsed_sysdate_tsz(sys_context('ALERT_CONTEXT', 'i_lang'), v.dt_record),
        pk_date_utils.get_elapsed_sysdate_tsz(sys_context('ALERT_CONTEXT', 'i_lang'), v.dt_record) || ' ' ||
        pk_message.get_message(sys_context('ALERT_CONTEXT', 'i_lang'), 'ALERT_LIST_T003')) TIME,
 pk_message.get_message(sys_context('ALERT_CONTEXT', 'i_lang'), v.replace1) message,
 NULL id_room,
 v.id_patient,
 pk_patient.get_pat_name(sys_context('ALERT_CONTEXT', 'i_lang'),
                         profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                      sys_context('ALERT_CONTEXT', 'i_institution'),
                                      sys_context('ALERT_CONTEXT', 'i_software')),
                         v.id_patient,
                         v.id_episode) name_pat,
 pk_adt.get_pat_non_disc_options(sys_context('ALERT_CONTEXT', 'i_lang'),
                                 profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                              sys_context('ALERT_CONTEXT', 'i_institution'),
                                              sys_context('ALERT_CONTEXT', 'i_software')),
                                 v.id_patient) pat_ndo,
 pk_adt.get_pat_non_disclosure_icon(sys_context('ALERT_CONTEXT', 'i_lang'),
                                    profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                 sys_context('ALERT_CONTEXT', 'i_institution'),
                                                 sys_context('ALERT_CONTEXT', 'i_software')),
                                    v.id_patient) pat_nd_icon,
 pk_patphoto.get_pat_foto(v.id_patient,
                          sys_context('ALERT_CONTEXT', 'i_institution'),
                          sys_context('ALERT_CONTEXT', 'i_software')) photo,
 pk_patient.get_pat_gender(v.id_patient) gender,
 pk_patient.get_pat_age(sys_context('ALERT_CONTEXT', 'i_lang'),
                        v.id_patient,
                        sys_context('ALERT_CONTEXT', 'i_institution'),
                        sys_context('ALERT_CONTEXT', 'i_software')) pat_age,
 NULL desc_room,
 pk_date_utils.get_elapsed_tsz(sys_context('ALERT_CONTEXT', 'i_lang'), ea.dt_status, current_timestamp) date_send,
 NULL desc_epis_anamnesis,
 NULL acuity,
 NULL rank_acuity,
 p1.id_schedule id_schedule,
 pk_alerts.get_alerts_shortcut(profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                            sys_context('ALERT_CONTEXT', 'i_institution'),
                                            sys_context('ALERT_CONTEXT', 'i_software')),
                               v.id_sys_alert) id_sys_shortcut,
 v.id_record id_reg_det,
 v.id_sys_alert,
 NULL dt_first_obs_tstz,
 NULL fast_track_icon,
 NULL fast_track_color,
 'A' fast_track_status,
 NULL esi_level,
 pk_patient.get_pat_name_to_sort(sys_context('ALERT_CONTEXT', 'i_lang'),
                                 profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                              sys_context('ALERT_CONTEXT', 'i_institution'),
                                              sys_context('ALERT_CONTEXT', 'i_software')),
                                 v.id_patient,
                                 p1.id_episode) name_pat_sort,
 table_varchar() resp_icons,
 id_prof_order
  FROM sys_alert_event v
  JOIN referral_ea ea
    ON (ea.id_external_request = v.id_record)
  JOIN p1_external_request p1
    ON (ea.id_external_request = p1.id_external_request)
 WHERE v.id_sys_alert = 305
   AND v.flg_visible = 'Y'
   AND p1.flg_status IN ('S', 'M', 'E', 'K', 'W')
   AND ea.id_prof_schedule = sys_context('ALERT_CONTEXT', 'i_prof')
   AND p1.id_inst_dest = sys_context('ALERT_CONTEXT', 'i_institution')
   AND ea.dt_schedule BETWEEN
       CAST((SELECT pk_date_utils.trunc_insttimezone(profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                                  sys_context('ALERT_CONTEXT', 'i_institution'),
                                                                  sys_context('ALERT_CONTEXT', 'i_software')),
                                                     current_timestamp)
               FROM dual) AS TIMESTAMP WITH LOCAL TIME ZONE) AND
       CAST((SELECT pk_date_utils.trunc_insttimezone(profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                                  sys_context('ALERT_CONTEXT', 'i_institution'),
                                                                  sys_context('ALERT_CONTEXT', 'i_software')),
                                                     current_timestamp + INTERVAL '1' DAY)
               FROM dual) AS TIMESTAMP WITH LOCAL TIME ZONE);
