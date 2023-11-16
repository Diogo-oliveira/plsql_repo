CREATE OR REPLACE VIEW v_sys_alert_312 AS
SELECT /*+ opt_param('_OPTIMIZER_USE_FEEDBACK', 'FALSE') */
 NULL id_sys_alert_det,
 sev.id_record id_reg,
 sev.id_episode,
 sev.id_institution,
 tbl.id_professional id_prof,
 NULL dt_req,
 decode(instr(pk_date_utils.get_elapsed_sysdate_tsz(sys_context('ALERT_CONTEXT', 'i_lang'), sev.dt_record), ':'),
        0,
        pk_date_utils.get_elapsed_sysdate_tsz(sys_context('ALERT_CONTEXT', 'i_lang'), sev.dt_record),
        pk_date_utils.get_elapsed_sysdate_tsz(sys_context('ALERT_CONTEXT', 'i_lang'), sev.dt_record) || '' ||
        pk_message.get_message(sys_context('ALERT_CONTEXT', 'i_lang'), 'ALERT_LIST_T003')) TIME,
 pk_sysdomain.get_domain('CDA_REQ.FLG_STATUS', tbl.flg_status, sys_context('ALERT_CONTEXT', 'i_lang')) message,
 (SELECT i.id_parent
    FROM institution i
   WHERE i.id_institution = ppt.id_institution) id_room,
 NULL id_patient,
 pk_sysdomain.get_domain('CDA_REQ.FLG_TYPE', tbl.flg_type, sys_context('ALERT_CONTEXT', 'i_lang')) || '_' ||
 tbl.id_cda_req name_pat,
 NULL pat_ndo,
 NULL pat_nd_icon,
 decode(pk_profphoto.check_blob(tbl.id_professional),
        'N',
        '',
        pk_profphoto.get_prof_photo(profissional(tbl.id_professional, tbl.id_institution, 0))) photo,
 (SELECT p.gender
    FROM professional p
   WHERE p.id_professional = tbl.id_professional) gender,
 NULL pat_age,
 pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'i_lang'),
                                'CATEGORY.CODE_CATEGORY.' ||
                                (SELECT pc.id_category
                                   FROM prof_cat pc
                                  WHERE pc.id_professional = tbl.id_professional
                                    AND pc.id_institution = tbl.id_institution)) desc_room,
 NULL date_send,
 NULL desc_epis_anamnesis,
 pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'i_lang'),
                                'AB_INSTITUTION.CODE_INSTITUTION.' || sev.id_institution) acuity,
 NULL rank_acuity,
 NULL id_schedule,
 sac.id_sys_shortcut id_sys_shortcut,
 sev.id_record id_reg_det,
 sac.id_sys_alert id_sys_alert,
 sev.dt_record dt_first_obs_tstz,
 NULL fast_track_icon,
 NULL fast_track_color,
 NULL fast_track_status,
 NULL esi_level,
 NULL name_pat_sort,
 pk_hand_off_api.get_resp_icons(sys_context('ALERT_CONTEXT', 'i_lang'),
                                profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                             sys_context('ALERT_CONTEXT', tbl.id_institution),
                                             sys_context('ALERT_CONTEXT', ppt.id_software)),
                                sev.id_episode,
                                sys_context('ALERT_CONTEXT', 'l_hand_off_type')) resp_icons,
 id_prof_order
  FROM (SELECT cr.id_cda_req,
               cr.id_institution,
               cr.flg_type,
               cr.flg_status,
               cr.create_user,
               cr.dt_start,
               cr.id_professional
          FROM cda_req cr
         WHERE cr.flg_status = 'R') tbl
 INNER JOIN prof_profile_template ppt
    ON (ppt.id_institution = tbl.id_institution)
 INNER JOIN sys_alert_prof sap
    ON (sap.id_profile_template = ppt.id_profile_template AND sap.id_professional = ppt.id_professional AND
       sap.id_institution = ppt.id_institution AND sap.id_sys_alert = 312)
 INNER JOIN sys_alert_config sac
    ON (sac.id_sys_alert = sap.id_sys_alert AND sac.id_profile_template = ppt.id_profile_template)
 INNER JOIN sys_alert_event sev
    ON (sev.id_sys_alert = sap.id_sys_alert AND sev.id_institution = sap.id_institution AND
       sev.id_record = tbl.id_cda_req)
 WHERE ppt.id_software = 26
   AND ppt.id_professional = tbl.id_professional
   AND ppt.id_institution = sys_context('ALERT_CONTEXT', 'i_institution');
