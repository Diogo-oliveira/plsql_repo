CREATE OR REPLACE   VIEW V_SYS_ALERT_106 AS
SELECT /*+ opt_param('_OPTIMIZER_USE_FEEDBACK', 'FALSE') */
 v.id_sys_alert_event id_sys_alert_det,
 v.id_sys_alert id_reg,
 v.id_episode,
 v.id_institution,
 v.id_professional id_prof,
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
 REPLACE(pk_message.get_message(sys_context('ALERT_CONTEXT', 'i_lang'), 'SIS_PRE_NATAL_M001'),
         '$',
         pk_sysconfig.get_config('SIS_PRE_NATAL_AVAILABLE_%',
                                 profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                              sys_context('ALERT_CONTEXT', 'i_institution'),
                                              sys_context('ALERT_CONTEXT', 'i_software')))) message,
 NULL id_room,
 NULL id_patient,
 pk_prof_utils.get_name(sys_context('ALERT_CONTEXT', 'i_lang'), sys_context('ALERT_CONTEXT', 'i_prof')) name_pat,
 NULL pat_ndo,
 NULL pat_nd_icon,
 NULL photo,
 NULL gender,
 NULL pat_age,
 pk_prof_utils.get_desc_category(sys_context('ALERT_CONTEXT', 'i_lang'),
                                 profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                              sys_context('ALERT_CONTEXT', 'i_institution'),
                                              sys_context('ALERT_CONTEXT', 'i_software')),
                                 sys_context('ALERT_CONTEXT', 'i_prof'),
                                 sys_context('ALERT_CONTEXT', 'i_institution')) desc_room,
 NULL date_send,
 NULL desc_epis_anamnesis,
 pk_utils.get_institution_name(sys_context('ALERT_CONTEXT', 'i_lang'), sys_context('ALERT_CONTEXT', 'i_institution')) acuity,
 NULL rank_acuity,
 NULL id_schedule,
 pk_alerts.get_alerts_shortcut(profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                            sys_context('ALERT_CONTEXT', 'i_institution'),
                                            sys_context('ALERT_CONTEXT', 'i_software')),
                               v.id_sys_alert) id_sys_shortcut,
 v.id_record id_reg_det,
 v.id_sys_alert,
 NULL dt_first_obs_tstz,
 NULL fast_track_icon,
 NULL fast_track_color,
 NULL fast_track_status,
 NULL esi_level,
 pk_prof_utils.get_name(sys_context('ALERT_CONTEXT', 'i_lang'), sys_context('ALERT_CONTEXT', 'i_prof')) name_pat_sort,
 table_varchar(NULL) resp_icons,
 id_prof_order
  FROM sys_alert_event v
 WHERE v.id_sys_alert = 106
   AND v.id_institution = sys_context('ALERT_CONTEXT', 'i_institution')
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
   AND EXISTS
 (SELECT 1
          FROM series s
         WHERE s.id_institution = sys_context('ALERT_CONTEXT', 'i_institution')
           AND s.flg_status = 'A'
           AND (100 - ((s.current_number / s.ending_number) * 100)) <=
               to_number(pk_sysconfig.get_config('SIS_PRE_NATAL_AVAILABLE_%',
                                                 profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                              sys_context('ALERT_CONTEXT', 'i_institution'),
                                                              sys_context('ALERT_CONTEXT', 'i_software')))))
  and pk_alerts.check_if_alert_expired( i_prof => profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                          sys_context('ALERT_CONTEXT', 'i_institution'),
                                                          sys_context('ALERT_CONTEXT', 'i_software'))
									  , i_dt_creation  => v.dt_creation
									  , i_id_sys_alert => v.id_sys_alert ) > 0
															  ;
