CREATE OR REPLACE VIEW V_SYS_ALERT_63 AS
SELECT /*+ opt_param('_OPTIMIZER_USE_FEEDBACK', 'FALSE') */
 v.id_sys_alert_event id_sys_alert_det,
 v.id_record id_reg,
 aa.id_episode id_episode,
 pha.id_institution,
 aa.id_ed_physician id_prof,
 pk_date_utils.date_send_tsz(sys_context('ALERT_CONTEXT', 'i_lang'),
                             aa.dt_announced_arrival,
                             pha.id_institution,
                             pha.id_software) dt_req,
 decode(instr(pk_date_utils.get_elapsed_sysdate_tsz(sys_context('ALERT_CONTEXT', 'i_lang'), aa.dt_announced_arrival),
              ':'),
        0,
        pk_date_utils.get_elapsed_sysdate_tsz(sys_context('ALERT_CONTEXT', 'i_lang'), aa.dt_announced_arrival),
        pk_date_utils.get_elapsed_sysdate_tsz(sys_context('ALERT_CONTEXT', 'i_lang'), aa.dt_announced_arrival) || ' ' ||
        pk_message.get_message(sys_context('ALERT_CONTEXT', 'i_lang'), 'ALERT_LIST_T003')) TIME,
 (SELECT decode(v.replace1,
                NULL,
                decode(aa.dt_expected_arrival,
                       NULL,
                       substr(aux.msg1, 0, instr(aux.msg2, '.') - 1),
                       substr(aux.msg1, 0, instr(aux.msg1, '@1') - 1) ||
                       pk_date_utils.date_chr_short_read_tsz(sys_context('ALERT_CONTEXT', 'i_lang'),
                                                             aa.dt_expected_arrival,
                                                             pha.id_institution,
                                                             pha.id_software) || ' ' ||
                       pk_date_utils.date_char_hour_tsz(sys_context('ALERT_CONTEXT', 'i_lang'),
                                                        aa.dt_expected_arrival,
                                                        pha.id_institution,
                                                        pha.id_software)),
                decode(aa.dt_expected_arrival,
                       NULL,
                       REPLACE(aux.msg2, '@2', v.replace1),
                       REPLACE(REPLACE(aux.msg1,
                                       '@1',
                                       pk_date_utils.date_chr_short_read_tsz(sys_context('ALERT_CONTEXT', 'i_lang'),
                                                                             aa.dt_expected_arrival,
                                                                             pha.id_institution,
                                                                             pha.id_software) || ' ' ||
                                       pk_date_utils.date_char_hour_tsz(sys_context('ALERT_CONTEXT', 'i_lang'),
                                                                        aa.dt_expected_arrival,
                                                                        pha.id_institution,
                                                                        pha.id_software)),
                               '@2',
                               v.replace1)))
    FROM (SELECT pk_message.get_message(sys_context('ALERT_CONTEXT', 'i_lang'), 'ANN_ARRIV_MSG057') msg1,
                 pk_message.get_message(sys_context('ALERT_CONTEXT', 'i_lang'), 'ANN_ARRIV_MSG068') msg2
            FROM dual) aux) message,
 NULL id_room,
 aa.id_patient id_patient,
 pk_patient.get_pat_name(sys_context('ALERT_CONTEXT', 'i_lang'),
                         profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                            sys_context('ALERT_CONTEXT', 'i_institution'),
                                            sys_context('ALERT_CONTEXT', 'i_software')),
                         aa.id_patient,
                         epis.id_episode) name_pat,
 pk_adt.get_pat_non_disc_options(sys_context('ALERT_CONTEXT', 'i_lang'),
                                 profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                    sys_context('ALERT_CONTEXT', 'i_institution'),
                                                    sys_context('ALERT_CONTEXT', 'i_software')),
                                 aa.id_patient) pat_ndo,
 pk_adt.get_pat_non_disclosure_icon(sys_context('ALERT_CONTEXT', 'i_lang'),
                                    profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                       sys_context('ALERT_CONTEXT', 'i_institution'),
                                                       sys_context('ALERT_CONTEXT', 'i_software')),
                                    aa.id_patient) pat_nd_icon,
 NULL photo,
 pk_patient.get_gender(sys_context('ALERT_CONTEXT', 'i_lang'), nvl(p.gender, 'I')) gender,
 pk_patient.get_pat_age(sys_context('ALERT_CONTEXT', 'i_lang'), p.dt_birth, p.age, aa.id_ed_physician, pha.id_software) pat_age,
 NULL desc_room,
 NULL date_send,
 NULL desc_epis_anamnesis,
 ei.triage_acuity acuity,
 ei.triage_rank_acuity rank_acuity,
 NULL id_schedule,
 pk_alerts.get_alerts_shortcut(profissional(aa.id_ed_physician, pha.id_institution, pha.id_software),
                               v.id_sys_alert) id_sys_shortcut,
 NULL id_reg_det,
 v.id_sys_alert,
 pk_episode.get_epis_dt_first_obs(ei.id_episode, ei.dt_first_obs_tstz, NULL, 'Y') dt_first_obs_tstz,
 pk_fast_track.get_fast_track_icon(sys_context('ALERT_CONTEXT', 'i_lang'),
                                   profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                      sys_context('ALERT_CONTEXT', 'i_institution'),
                                                      sys_context('ALERT_CONTEXT', 'i_software')),
                                   v.id_episode,
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
                                           v.id_episode,
                                           ei.id_triage_color)
    FROM dual) esi_level,
 pk_patient.get_pat_name_to_sort(sys_context('ALERT_CONTEXT', 'i_lang'),
                                 profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                    sys_context('ALERT_CONTEXT', 'i_institution'),
                                                    sys_context('ALERT_CONTEXT', 'i_software')),
                                 aa.id_patient,
                                 epis.id_episode) name_pat_sort,
 pk_hand_off_api.get_resp_icons(sys_context('ALERT_CONTEXT', 'i_lang'),
                                profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                   sys_context('ALERT_CONTEXT', 'i_institution'),
                                                   sys_context('ALERT_CONTEXT', 'i_software')),
                                v.id_episode,
                                sys_context('ALERT_CONTEXT', 'l_hand_off_type')) resp_icons,
 id_prof_order
  FROM sys_alert_event v
  JOIN announced_arrival aa
    ON aa.id_announced_arrival = v.id_record
   AND aa.id_ed_physician = v.id_professional
  JOIN patient p
    ON aa.id_patient = p.id_patient
  JOIN pre_hosp_accident pha
    ON pha.id_pre_hosp_accident = aa.id_pre_hosp_accident
   AND pha.id_institution = v.id_institution
   AND pha.id_software = v.id_software
  LEFT JOIN episode epis
    ON epis.id_episode = aa.id_episode
  LEFT JOIN epis_info ei
    ON ei.id_episode = epis.id_episode
 WHERE v.id_sys_alert = 63
   AND v.id_software = sys_context('ALERT_CONTEXT', 'i_software')
   AND v.id_institution = sys_context('ALERT_CONTEXT', 'i_institution')
   AND v.flg_visible = 'Y'
   AND aa.id_ed_physician = sys_context('ALERT_CONTEXT', 'i_prof')
   AND aa.flg_status = 'E'
   AND ((current_timestamp -
       to_number(pk_sysconfig.get_config('ANN_ARRIV_TIME_LIMIT', pha.id_institution, pha.id_software)) / 1440) <=
       aa.dt_expected_arrival OR aa.dt_expected_arrival IS NULL)
   AND NOT EXISTS
 (SELECT 1
          FROM sys_alert_read sar
         WHERE sar.id_sys_alert_event = v.id_sys_alert_event
           AND sar.id_professional = aa.id_ed_physician
           AND pk_alerts.get_config_flg_read(sys_context('ALERT_CONTEXT', 'i_lang'),
                                             profissional(aa.id_ed_physician, pha.id_institution, pha.id_software),
                                             v.id_sys_alert,
                                             NULL) = 'N')
  and pk_alerts.check_if_alert_expired( i_prof => profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                            sys_context('ALERT_CONTEXT', 'i_institution'),
                                            sys_context('ALERT_CONTEXT', 'i_software'))
                    , i_dt_creation  => v.dt_creation
                    , i_id_sys_alert => v.id_sys_alert ) > 0  	
 --ORDER BY aa.dt_expected_arrival
 ;
