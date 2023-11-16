CREATE OR REPLACE VIEW v_sys_alert_51 AS
SELECT /*+ opt_param('_OPTIMIZER_USE_FEEDBACK', 'FALSE') */
 NULL id_sys_alert_det,
 NULL id_reg,
 NULL id_episode,
 pi.id_institution id_institution,
 prof_locked.id_professional id_prof,
 NULL dt_req,
 decode(instr(pk_date_utils.get_elapsed_sysdate_tsz(sys_context('ALERT_CONTEXT', 'i_lang'), v.dt_record), ': '),
        0,
        pk_date_utils.get_elapsed_sysdate_tsz(sys_context('ALERT_CONTEXT', 'i_lang'), v.dt_record),
        pk_date_utils.get_elapsed_sysdate_tsz(sys_context('ALERT_CONTEXT', 'i_lang'), v.dt_record) || '' ||
        pk_message.get_message(sys_context('ALERT_CONTEXT', 'i_lang'), 'ALERT_LIST_T003')) TIME,
 pk_message.get_message(sys_context('ALERT_CONTEXT', 'i_lang'), 'ADMINISTRATOR_T173') message,
 (SELECT i.id_parent
    FROM institution i
   WHERE i.id_institution = pi.id_institution) id_room,
 NULL id_patient,
 prof_locked.name name_pat,
 NULL pat_ndo,
 NULL pat_nd_icon,
 pk_profphoto.get_prof_photo(profissional(prof_locked.id_professional, pi.id_institution, 0)) photo,
 prof_locked.gender gender,
 to_char(pk_backoffice.get_professional_age(sys_context('ALERT_CONTEXT', 'i_lang'), prof_locked.dt_birth)) pat_age,
 pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'i_lang'), 'CATEGORY.CODE_CATEGORY.' || pc.id_category) desc_room,
 NULL date_send,
 pk_backoffice.get_user_funtionality(pc.id_category, 0, pi.id_institution, prof_locked.id_professional) desc_epis_anamnesis,
 pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'i_lang'),
                                'AB_INSTITUTION.CODE_INSTITUTION.' || pi.id_institution) acuity,
 NULL rank_acuity,
 NULL id_schedule,
 (SELECT id_sys_shortcut
    FROM TABLE(pk_alerts.get_config_as_type(sys_context('ALERT_CONTEXT', 'i_lang'),
                                            profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                         pi.id_institution,
                                                         sys_context('ALERT_CONTEXT', 'i_software')),
                                            v.id_sys_alert,
                                            NULL))) id_sys_shortcut,
 NULL id_reg_det,
 v.id_sys_alert id_sys_alert,
 v.dt_record dt_first_obs_tstz,
 NULL fast_track_icon,
 NULL fast_track_color,
 NULL fast_track_status,
 NULL esi_level,
 NULL name_pat_sort,
 pk_hand_off_api.get_resp_icons(sys_context('ALERT_CONTEXT', 'i_lang'),
                                profissional(prof_locked.id_professional, pi.id_institution, 0),
                                v.id_episode,
                                sys_context('ALERT_CONTEXT', 'l_hand_off_type')) resp_icons,
 id_prof_order
  FROM sys_alert_event v
 INNER JOIN professional prof_locked
    ON (prof_locked.id_professional = v.id_record)
 INNER JOIN prof_institution pi
    ON (pi.id_professional = prof_locked.id_professional)
 INNER JOIN prof_cat pc
    ON (pc.id_professional = prof_locked.id_professional AND pc.id_institution = pi.id_institution)
 WHERE pi.id_institution = sys_context('ALERT_CONTEXT', 'i_institution')
   AND pi.dt_end_tstz IS NULL
   AND v.flg_visible = 'Y'
   AND v.id_sys_alert = 51
   AND v.id_institution = 0;
