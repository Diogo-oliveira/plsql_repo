CREATE OR REPLACE VIEW v_sys_alert_304 AS
SELECT /*+ opt_param('_OPTIMIZER_USE_FEEDBACK', 'FALSE') */
 v.id_sys_alert_event id_sys_alert_det,
 v.id_record id_reg,
 v.id_episode,
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
 pk_ref_core_internal.get_alerts_message(v.replace1) message,
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
 pk_date_utils.get_elapsed_tsz(sys_context('ALERT_CONTEXT', 'i_lang'), rtr.dt_update, current_timestamp) date_send,
 NULL desc_epis_anamnesis,
 NULL acuity,
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
 'A' fast_track_status,
 NULL esi_level,
 pk_patient.get_pat_name_to_sort(sys_context('ALERT_CONTEXT', 'i_lang'),
                                 profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                              sys_context('ALERT_CONTEXT', 'i_institution'),
                                              sys_context('ALERT_CONTEXT', 'i_software')),
                                 v.id_patient,
                                 v.id_episode) name_pat_sort,
 table_varchar() resp_icons,
 id_prof_order
  FROM sys_alert_event v
  JOIN p1_external_request p1
    ON (p1.id_external_request = v.id_record)
  JOIN ref_trans_responsibility rtr
    ON (rtr.id_external_request = p1.id_external_request)
 WHERE v.id_sys_alert = 304
   AND v.flg_visible = 'Y'
   AND rtr.id_status = 46 -- rejeitado
   AND rtr.id_workflow IN (10, 11)
   AND rtr.flg_active = 'Y'
   AND rtr.id_prof_transf_owner = sys_context('ALERT_CONTEXT', 'i_prof')
   AND rtr.id_inst_orig_tr = sys_context('ALERT_CONTEXT', 'i_institution');
