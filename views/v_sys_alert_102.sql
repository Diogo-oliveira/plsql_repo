CREATE OR REPLACE VIEW V_SYS_ALERT_102 AS
SELECT /*+ opt_param('_OPTIMIZER_USE_FEEDBACK', 'FALSE') */
 v.id_sys_alert_event id_sys_alert_det,
 v.id_record id_reg,
 v.id_episode,
 v.id_institution,
 pf.id_professional id_prof,
 pk_date_utils.to_char_insttimezone(profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                 sys_context('ALERT_CONTEXT', 'i_institution'),
                                                 sys_context('ALERT_CONTEXT', 'i_software')),
                                    v.dt_record,
                                    'YYYYMMDDHH24MISS') dt_req,
 decode(instr(pk_date_utils.get_elapsed_sysdate_tsz(sys_context('ALERT_CONTEXT', 'i_lang'), v.dt_record), ':'),
        0,
        pk_date_utils.get_elapsed_sysdate_tsz(sys_context('ALERT_CONTEXT', 'i_lang'), v.dt_record),
        pk_date_utils.get_elapsed_sysdate_tsz(sys_context('ALERT_CONTEXT', 'i_lang'), v.dt_record) || ' ' ||
        (SELECT pk_message.get_message(sys_context('ALERT_CONTEXT', 'i_lang'), 'ALERT_LIST_T003')
           FROM dual)) TIME,
 REPLACE(pk_message.get_message(sys_context('ALERT_CONTEXT', 'i_lang'), 'SCH_T821'),
         '@1',
         pk_date_utils.dt_year_day_hour_chr_short_tsz(sys_context('ALERT_CONTEXT', 'i_lang'),
                                                      s.dt_begin_tstz,
                                                      sys_context('ALERT_CONTEXT', 'i_institution'),
                                                      sys_context('ALERT_CONTEXT', 'i_software'))) message,
 s.id_room,
 v.id_patient,
 pk_patient.get_pat_name(sys_context('ALERT_CONTEXT', 'i_lang'),
                         profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                      sys_context('ALERT_CONTEXT', 'i_institution'),
                                      sys_context('ALERT_CONTEXT', 'i_software')),
                         v.id_patient,
                         NULL) name_pat,
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
 pk_patphoto.get_pat_photo(sys_context('ALERT_CONTEXT', 'i_lang'),
                           profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                        sys_context('ALERT_CONTEXT', 'i_institution'),
                                        sys_context('ALERT_CONTEXT', 'i_software')),
                           v.id_patient,
                           v.id_episode,
                           s.id_schedule) photo,
 p.gender,
 pk_patient.get_pat_age(sys_context('ALERT_CONTEXT', 'i_lang'),
                        p.dt_birth,
                        p.age,
                        sys_context('ALERT_CONTEXT', 'i_institution'),
                        sys_context('ALERT_CONTEXT', 'i_software')) pat_age,
 (SELECT coalesce(r.desc_room_abbreviation,
                  pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'i_lang'), r.code_abbreviation),
                  r.desc_room,
                  pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'i_lang'), r.code_room))
    FROM dual) desc_room,
 pk_date_utils.get_elapsed_tsz(sys_context('ALERT_CONTEXT', 'i_lang'), s.dt_cancel_tstz, current_timestamp) date_send,
 NULL desc_epis_anamnesis,
 NULL acuity,
 NULL rank_acuity,
 s.id_schedule,
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
                                 p.id_patient,
                                 NULL) name_pat_sort,
 table_varchar() resp_icons,
 id_prof_order
  FROM sys_alert_event v, sys_alert sa, professional pf, patient p, schedule s, room r
 WHERE v.id_sys_alert = 102
   AND v.id_institution = sys_context('ALERT_CONTEXT', 'i_institution')
   AND v.id_software = sys_context('ALERT_CONTEXT', 'i_software')
   AND v.flg_visible = 'Y'
   AND sa.id_sys_alert = v.id_sys_alert
   AND p.id_patient = v.id_patient
   AND s.id_room = r.id_room(+)
   AND pf.id_professional = sys_context('ALERT_CONTEXT', 'i_prof')
   AND v.id_record = s.id_schedule
   AND s.dt_begin_tstz > current_timestamp
   AND NOT EXISTS (SELECT 1
          FROM sys_alert_read sar
         WHERE sar.id_sys_alert_event = v.id_sys_alert_event
           AND sar.id_professional = sys_context('ALERT_CONTEXT', 'i_prof')
           AND pk_alerts.get_config_flg_read(sys_context('ALERT_CONTEXT', 'i_lang'),
                                             profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                          sys_context('ALERT_CONTEXT', 'i_institution'),
                                                          sys_context('ALERT_CONTEXT', 'i_software')),
                                             v.id_sys_alert,
                                             NULL) = 'N')
  and pk_alerts.check_if_alert_expired( i_prof => profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                            sys_context('ALERT_CONTEXT', 'i_institution'),
                                            sys_context('ALERT_CONTEXT', 'i_software'))
                    , i_dt_creation  => v.dt_creation
                    , i_id_sys_alert => v.id_sys_alert ) > 0 											 
;
