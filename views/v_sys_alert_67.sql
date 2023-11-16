CREATE OR REPLACE VIEW V_SYS_ALERT_67 AS
SELECT /*+ opt_param('_OPTIMIZER_USE_FEEDBACK', 'FALSE') */
v.id_sys_alert_event id_sys_alert_det,
       v.id_record          id_reg,
       cp.id_episode,
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
       pk_message.get_message(sys_context('ALERT_CONTEXT', 'i_lang'), 'CP_ALERT_067') message,
       NULL id_room,
       p.id_patient,
       pk_patient.get_pat_name(sys_context('ALERT_CONTEXT', 'i_lang'),
                               profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                            sys_context('ALERT_CONTEXT', 'i_institution'),
                                            sys_context('ALERT_CONTEXT', 'i_software')),
                               p.id_patient,
                               cp.id_episode,
                               NULL) name_pat,
       pk_adt.get_pat_non_disc_options(sys_context('ALERT_CONTEXT', 'i_lang'),
                                       profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                    sys_context('ALERT_CONTEXT', 'i_institution'),
                                                    sys_context('ALERT_CONTEXT', 'i_software')),
                                       p.id_patient) pat_ndo,
       pk_adt.get_pat_non_disclosure_icon(sys_context('ALERT_CONTEXT', 'i_lang'),
                                          profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                       sys_context('ALERT_CONTEXT', 'i_institution'),
                                                       sys_context('ALERT_CONTEXT', 'i_software')),
                                          p.id_patient) pat_nd_icon,
       decode(pk_patphoto.check_blob(p.id_patient),
              'N',
              '',
              pk_patphoto.get_pat_foto(p.id_patient,
                                       sys_context('ALERT_CONTEXT', 'i_institution'),
                                       sys_context('ALERT_CONTEXT', 'i_software'))) photo,
       p.gender,
       pk_patient.get_pat_age(sys_context('ALERT_CONTEXT', 'i_lang'),
                              p.id_patient,
                              sys_context('ALERT_CONTEXT', 'i_institution'),
                              sys_context('ALERT_CONTEXT', 'i_software')) pat_age,
       NULL desc_room,
       NULL date_send,
       NULL desc_epis_anamnesis,
       NULL acuity,
       NULL rank_acuity,
       NULL id_schedule,
       nvl2(cp.id_episode, 1747, 1818) id_sys_shortcut,
       v.id_record id_reg_det,
       v.id_sys_alert,
       NULL dt_first_obs_tstz,
       pk_fast_track.get_fast_track_icon(sys_context('ALERT_CONTEXT', 'i_lang'),
                                         profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                      sys_context('ALERT_CONTEXT', 'i_institution'),
                                                      sys_context('ALERT_CONTEXT', 'i_software')),
                                         cp.id_episode,
                                         NULL,
                                         ei.id_triage_color,
                                         NULL,
                                         NULL) fast_track_icon,
       decode(ei.triage_acuity, '0xFFFFFF', '0x787864', '0xFFFFFF') fast_track_color,
       'A' fast_track_status,
       (SELECT pk_edis_triage.get_epis_esi_level(sys_context('ALERT_CONTEXT', 'i_lang'),
                                                 profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                              sys_context('ALERT_CONTEXT', 'i_institution'),
                                                              sys_context('ALERT_CONTEXT', 'i_software')),
                                                 cp.id_episode,
                                                 ei.id_triage_color)
          FROM dual) esi_level,
       pk_patient.get_pat_name_to_sort(sys_context('ALERT_CONTEXT', 'i_lang'),
                                       profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                    sys_context('ALERT_CONTEXT', 'i_institution'),
                                                    sys_context('ALERT_CONTEXT', 'i_software')),
                                       v.id_patient,
                                       v.id_episode,
                                       ei.id_schedule) name_pat_sort,
       pk_hand_off_api.get_resp_icons(sys_context('ALERT_CONTEXT', 'i_lang'),
                                      profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                   sys_context('ALERT_CONTEXT', 'i_institution'),
                                                   sys_context('ALERT_CONTEXT', 'i_software')),
                                      v.id_episode,
                                      sys_context('ALERT_CONTEXT', 'l_hand_off_type'))resp_icons, id_prof_order 
  FROM sys_alert_event v
  LEFT JOIN epis_info ei
    ON v.id_episode = ei.id_episode
  LEFT JOIN (SELECT id_episode_origin id_episode, id_patient, id_coding_page
               FROM coding_page) cp
    ON v.id_record = cp.id_coding_page
 INNER JOIN patient p
    ON p.id_patient = v.id_patient
 WHERE (v.id_professional = sys_context('ALERT_CONTEXT', 'i_prof') OR
       sys_context('ALERT_CONTEXT', 'i_prof') IN
       (SELECT prof_cat.id_professional
           FROM prof_cat
          WHERE id_category IN (SELECT cat.id_category
                                  FROM category cat
                                 WHERE cat.flg_type = 'O')))
   AND v.id_institution = sys_context('ALERT_CONTEXT', 'i_institution')
   AND v.id_sys_alert = 67;