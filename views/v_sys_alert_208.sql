CREATE OR REPLACE VIEW v_sys_alert_208 AS
SELECT /*+ opt_param('_OPTIMIZER_USE_FEEDBACK', 'FALSE') */
 sev.id_sys_alert_event id_sys_alert_det,
 sev.id_record id_reg,
 sev.id_episode,
 sev.id_institution,
 sys_context('ALERT_CONTEXT', 'i_prof') id_prof,
 NULL dt_req,
 decode(instr(pk_date_utils.get_elapsed_sysdate_tsz(sys_context('ALERT_CONTEXT', 'i_lang'), sev.dt_record), ':'),
        0,
        pk_date_utils.get_elapsed_sysdate_tsz(sys_context('ALERT_CONTEXT', 'i_lang'), sev.dt_record),
        pk_date_utils.get_elapsed_sysdate_tsz(sys_context('ALERT_CONTEXT', 'i_lang'), sev.dt_record) || ' ' ||
        pk_message.get_message(sys_context('ALERT_CONTEXT', 'i_lang'), 'ALERT_LIST_T003')) TIME,
 REPLACE(REPLACE(pk_message.get_message(sys_context('ALERT_CONTEXT', 'i_lang'), 'ADMINISTRATOR_M001'),
                 '@@spec',
                 v_dcs_new.spec),
         '@@serv',
         v_dcs_new.serv) message,
 NULL id_room,
 NULL id_patient,
 (SELECT p.name
    FROM professional p
   WHERE p.id_professional = sys_context('ALERT_CONTEXT', 'i_prof')) name_pat,
 NULL pat_ndo,
 NULL pat_nd_icon,
 decode(pk_profphoto.check_blob(sys_context('ALERT_CONTEXT', 'i_prof')),
        'N',
        '',
        pk_profphoto.get_prof_photo(profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                 sys_context('ALERT_CONTEXT', 'i_institution'),
                                                 0))) photo,
 (SELECT p.gender
    FROM professional p
   WHERE p.id_professional = sys_context('ALERT_CONTEXT', 'i_prof')) gender,
 NULL pat_age,
 pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'i_lang'),
                                'CATEGORY.CODE_CATEGORY.' ||
                                (SELECT pc.id_category
                                   FROM prof_cat pc
                                  WHERE pc.id_professional = sys_context('ALERT_CONTEXT', 'i_prof')
                                    AND pc.id_institution = sys_context('ALERT_CONTEXT', 'i_institution'))) desc_room,
 NULL date_send,
 NULL desc_epis_anamnesis,
 pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'i_lang'),
                                'INSTITUTION.CODE_INSTITUTION.' || v_dcs_new.id_institution) acuity,
 NULL rank_acuity,
 NULL id_schedule,
 sac.id_sys_shortcut id_sys_shortcut,
 sev.id_record id_reg_det,
 sac.id_sys_alert id_sys_alert,
 NULL dt_first_obs_tstz,
 NULL fast_track_icon,
 NULL fast_track_color,
 NULL fast_track_status,
 NULL esi_level,
 NULL name_pat_sort,
 pk_hand_off_api.get_resp_icons(sys_context('ALERT_CONTEXT', 'i_lang'),
                                profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                             sys_context('ALERT_CONTEXT', 'i_institution'),
                                             sys_context('ALERT_CONTEXT', 'i_software')),
                                sev.id_episode,
                                sys_context('ALERT_CONTEXT', 'l_hand_off_type')) resp_icons,
 id_prof_order
  FROM (SELECT dcs.id_dep_clin_serv,
               dcs.id_clinical_service,
               pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'i_lang'), cs.code_clinical_service) spec,
               dcs.id_department,
               pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'i_lang'), d.code_department) serv,
               d.id_institution
          FROM dep_clin_serv dcs
         INNER JOIN clinical_service cs
            ON (cs.id_clinical_service = dcs.id_clinical_service AND cs.flg_available = 'Y')
         INNER JOIN department d
            ON (d.id_department = dcs.id_department AND d.flg_available = 'Y')
         INNER JOIN sys_alert_event sae
            ON (sae.id_sys_alert = 208 AND sae.id_institution = d.id_institution AND
               sae.id_record = dcs.id_dep_clin_serv)
         WHERE dcs.flg_available = 'Y') v_dcs_new
 INNER JOIN prof_profile_template ppt
    ON (ppt.id_institution = v_dcs_new.id_institution)
 INNER JOIN sys_alert_prof sap
    ON (sap.id_profile_template = ppt.id_profile_template AND sap.id_professional = ppt.id_professional AND
       sap.id_institution = ppt.id_institution AND sap.id_sys_alert = 208)
 INNER JOIN sys_alert_config sac
    ON (sac.id_sys_alert = sap.id_sys_alert AND sac.id_profile_template = ppt.id_profile_template)
 INNER JOIN sys_alert_event sev
    ON (sev.id_sys_alert = sap.id_sys_alert AND sev.id_institution = sap.id_institution AND
       sev.id_record = v_dcs_new.id_dep_clin_serv)
 WHERE ppt.id_software = 26
   AND ppt.id_professional = sys_context('ALERT_CONTEXT', 'i_prof')
   AND ppt.id_institution = sys_context('ALERT_CONTEXT', 'i_institution')
   AND NOT EXISTS (SELECT 0
          FROM sys_alert_read sar
         WHERE sar.id_sys_alert_event = sev.id_sys_alert_event
           AND sar.id_professional = sys_context('ALERT_CONTEXT', 'i_prof')
           AND pk_alerts.get_config_flg_read(sys_context('ALERT_CONTEXT', 'i_lang'),
                                             profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                          sys_context('ALERT_CONTEXT', 'i_institution'),
                                                          sys_context('ALERT_CONTEXT', 'i_software')),
                                             sev.id_sys_alert,
                                             NULL) = 'N');
