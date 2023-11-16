CREATE OR REPLACE VIEW V_EDISGRIDPATIENTS AS
SELECT
  triage_flg_letter,
  acuity,
  color_text,
  rank_acuity,
  acuity_desc,
  id_episode,
  dt_begin,
  dt_efectiv,
  order_time,
  date_send,
  date_send_sort,
  desc_room,
  id_patient,
  name_pat,
  name_pat_sort,
  pat_ndo,
  pat_nd_icon,
  gender,
  name_prof,
  name_nurse,
  prof_team,
  name_prof_tooltip,
  name_nurse_tooltip,
  prof_team_tooltip,
  pat_age,
  pat_age_for_order_by,
  dt_first_obs,
  img_transp,
  photo,
  care_stage,
  care_stage_rank,
  flg_temp,
  dt_server,
  desc_temp,
  desc_drug_presc,
  desc_monit_interv_presc,
  desc_movement,
  desc_analysis_req,
  desc_exam_req,
  desc_epis_anamnesis,
  desc_disch_pend_time,
  disch_pend_time,
  flg_cancel,
  fast_track_icon,
  fast_track_color,
  fast_track_status,
  fast_track_desc,
  esi_level,
  resp_icons,
  prof_follow_add,
  prof_follow_remove,
  pat_major_inc_icon,
  desc_oth_exam_req,
  desc_img_exam_req,
  length_of_stay_bg_color,
  desc_opinion,
  desc_opinion_popup,
  rownum rank_triage,
  origin_anamn_full_desc,
  prof_id,
  i_lang,
  institution,
  software,
  id_room,
  epis_flg_status,
  id_schedule,
  id_first_nurse_resp,
  flg_disch_status,
  dt_begin_tstz,
  lprof,
  id_triage_color,
  ( select pk_sysconfig.get_config(pk_gridfilter.get_strings('l_egoo'), lprof) from dual ) g_config_egoo,
  ( select pk_edis_triage.get_flag_no_color(i_lang, lprof, id_triage_color) from dual ) g_triage_color,
  ( select pk_utils.search_table_varchar(pk_utils.str_split_l(pk_sysconfig.get_config('GRID_ORIGINS',lprof), '|'), id_origin) from dual )g_id_origin,
  ( select pk_edis_grid.orderby_flg_letter(lprof)  from dual )g_orderby_flg_letter,
  ( select pk_alert_constant.get_yes()  from dual )g_yes
FROM
  (
  SELECT
    epis.lprof,
  epis.id_origin ,
    epis.triage_acuity acuity,
    epis.triage_color_text color_text,
    epis.triage_rank_acuity rank_acuity,
  epis.id_triage_color id_triage_color,
    epis.triage_flg_letter,
    decode(epis.triage_flg_letter,
         pk_alert_constant.get_yes(),
         pk_gridfilter.get_strings('l_msg_edis_grid_m003', i_lang, epis.lprof)) acuity_desc,
    epis.id_episode,
    (SELECT pk_date_utils.date_send_tsz(i_lang, epis.dt_begin_tstz, epis.lprof)
       FROM dual) dt_begin,
    (SELECT pk_date_utils.date_char_hour_tsz(i_lang, epis.dt_begin_tstz, epis.institution, epis.software)
       FROM dual) dt_efectiv,
    (SELECT pk_date_utils.diff_timestamp(current_timestamp, epis.dt_begin_tstz)
       FROM dual) order_time, --ET 2007/03/01
    (SELECT pk_edis_proc.get_los_duration(i_lang       => i_lang,
                        i_prof       => epis.lprof,
                        i_id_episode => epis.id_episode)
       FROM dual) date_send, -- Length of stay
    (SELECT pk_edis_proc.get_formatted_string_for_sort(i_lang    => i_lang,
                               i_prof    => epis.lprof,
                               i_type    => pk_gridfilter.get_strings('g_sort_type_los'),
                               i_episode => epis.id_episode)
       FROM dual) date_send_sort,
    (SELECT nvl(nvl(r.desc_room_abbreviation,
            pk_translation.get_translation_dtchk(i_lang, 'ROOM.CODE_ABBREVIATION' || epis.id_room)),
          nvl(r.desc_room,
            pk_translation.get_translation_dtchk(i_lang, 'ROOM.CODE_ROOM.' || epis.id_room)))
       FROM dual) desc_room,
    epis.id_patient,
    (SELECT pk_patient.get_pat_name(i_lang, epis.lprof, epis.id_patient, epis.id_episode)
       FROM dual) name_pat,
    (SELECT pk_patient.get_pat_name_to_sort(i_lang, epis.lprof, epis.id_patient, epis.id_episode, NULL)
       FROM dual) name_pat_sort,
    (SELECT pk_adt.get_pat_non_disc_options(i_lang, epis.lprof, epis.id_patient)
       FROM dual) pat_ndo,
    (SELECT pk_adt.get_pat_non_disclosure_icon(i_lang, epis.lprof, epis.id_patient)
       FROM dual) pat_nd_icon,
    (SELECT pk_patient.get_gender(i_lang, gender) gender
       FROM patient
      WHERE id_patient = epis.id_patient) gender,
    (SELECT pk_hand_off_core.get_responsibles_str(i_lang,
                            epis.lprof,
                            'D',
                            epis.id_episode,
                            epis.id_professional,
                            pk_gridfilter.get_strings('l_hand_off_type',
                                        epis.i_lang,
                                        epis.lprof), --l_hand_off_type,
                            'G',
                            pk_gridfilter.get_strings('l_show_only_epis_resp',
                                        i_lang,
                                        lprof))
       FROM dual) name_prof,
    (SELECT pk_prof_utils.get_nickname(i_lang, epis.id_first_nurse_resp)
       FROM dual) name_nurse,
    decode(pk_gridfilter.get_strings('l_show_resident_physician', i_lang, lprof),
         pk_alert_constant.get_yes(),
         (SELECT pk_hand_off_core.get_resp_by_type_grid_str(i_lang,
                                  epis.lprof,
                                  epis.id_episode,
                                  pk_gridfilter.get_strings('l_hand_off_type',
                                              epis.i_lang,
                                              epis.lprof),
                                  'R',
                                  'G')
          FROM dual),
         (SELECT pk_prof_teams.get_prof_current_team(i_lang,
                               epis.lprof,
                               epis.id_department,
                               epis.id_software,
                               epis.id_professional,
                               epis.id_first_nurse_resp)
          FROM dual)) prof_team,
    -- Display text in tooltips
    -- 1) Responsible physician(s)
    (SELECT pk_hand_off_core.get_responsibles_str(i_lang,
                            epis.lprof,
                            'D',
                            epis.id_episode,
                            epis.id_professional,
                            pk_gridfilter.get_strings('l_hand_off_type',
                                        epis.i_lang,
                                        epis.lprof),
                            'T')
       FROM dual) name_prof_tooltip,
    -- 2) Responsible nurse
    (SELECT pk_hand_off_core.get_responsibles_str(i_lang,
                            epis.lprof,
                            'N',
                            epis.id_episode,
                            epis.id_first_nurse_resp,
                            pk_gridfilter.get_strings('l_hand_off_type',
                                        epis.i_lang,
                                        epis.lprof),
                            'T')
       FROM dual) name_nurse_tooltip,
    -- 3) Responsible team
    (SELECT pk_hand_off_core.get_team_str(i_lang,
                        epis.lprof,
                        epis.id_department,
                        epis.id_software,
                        epis.id_professional,
                        epis.id_first_nurse_resp,
                        pk_gridfilter.get_strings('l_hand_off_type',
                                    epis.i_lang,
                                    epis.lprof),
                        NULL)
       FROM dual) prof_team_tooltip,
    (SELECT pk_patient.get_pat_age(i_lang, epis.id_patient, epis.lprof)
       FROM dual) pat_age,
    (SELECT pk_edis_proc.get_formatted_string_for_sort(i_lang    => i_lang,
                               i_prof    => epis.lprof,
                               i_type    => pk_gridfilter.get_strings('g_sort_type_age'),
                               i_episode => epis.id_episode)
       FROM dual) pat_age_for_order_by,
    pk_date_utils.date_send_tsz(i_lang, epis.dt_first_obs_tstz, epis.lprof) dt_first_obs,
    lpad(to_char(sd_rank), 6, '0') || sd_img_name img_transp,
    (SELECT pk_patphoto.get_pat_photo(i_lang, epis.lprof, epis.id_patient, epis.id_episode, epis.id_schedule)
       FROM dual) photo,
    (SELECT pk_patient_tracking.get_care_stage_grid_status(i_lang,
                                 epis.lprof,
                                 epis.id_episode,
                                 pk_date_utils.date_send_tsz(i_lang,
                                               current_timestamp,
                                               epis.lprof))
       FROM dual) care_stage,
    (SELECT pk_patient_tracking.get_current_state_rank(i_lang, epis.lprof, epis.id_episode)
       FROM dual) care_stage_rank,
    'N' flg_temp,
    (SELECT pk_date_utils.date_send_tsz(i_lang, current_timestamp, epis.lprof)
       FROM dual) dt_server,
    NULL desc_temp,
    --grid_task
    (SELECT pk_grid.convert_grid_task_dates_to_str(i_lang, epis.lprof, g.drug_presc)
       FROM dual) desc_drug_presc,
    (SELECT pk_grid.convert_grid_task_dates_to_str(i_lang,
                             epis.lprof,
                             pk_grid.get_prioritary_task(i_lang,
                                           epis.lprof,
                                           pk_grid.get_prioritary_task(i_lang,
                                                         epis.lprof,
                                                         g.intervention,
                                                         g.nurse_activity,
                                                         pk_gridfilter.get_strings('g_domain_nurse_act'),
                                                        pk_edis_list.get_prof_cat(epis.lprof)),
                                           g.monitorization,
                                           NULL,
                                           pk_edis_list.get_prof_cat(epis.lprof)))
       FROM dual) desc_monit_interv_presc,
    (SELECT pk_grid.convert_grid_task_dates_to_str(i_lang, epis.lprof, g.movement)
       FROM dual) desc_movement,
    (SELECT pk_grid.visit_grid_task_str(i_lang,
                      epis.lprof,
                      epis.id_visit,
                      'A',
                      pk_edis_list.get_prof_cat(epis.lprof))
       FROM dual) desc_analysis_req,
    (SELECT pk_grid.visit_grid_task_str(i_lang,
                      epis.lprof,
                      epis.id_visit,
                      'E',
                      pk_edis_list.get_prof_cat(epis.lprof))
       FROM dual) desc_exam_req,
    (SELECT pk_string_utils.concat_if_exists((SELECT pk_edis_grid.get_grid_origin_abbrev(i_lang,
                                              epis.lprof,
                                              v.id_origin)
                           FROM visit v
                          WHERE v.id_visit = epis.id_visit),
                         pk_edis_grid.get_complaint_grid(i_lang,
                                         epis.lprof,
                                         epis.id_episode),
                         ' / ')
       FROM dual) desc_epis_anamnesis,
    (SELECT pk_grid.convert_grid_task_dates_to_str(i_lang, epis.lprof, g.discharge_pend)
       FROM dual) desc_disch_pend_time,
    (SELECT pk_date_utils.date_send_tsz(i_lang, nvl(d.dt_med_tstz, d.dt_pend_tstz), epis.lprof)
       FROM discharge d
      WHERE d.flg_status = 'P'
      AND d.id_episode = epis.id_episode
      AND rownum < 2) disch_pend_time,
    (SELECT pk_visit.check_flg_cancel(i_lang, epis.lprof, epis.id_episode)
       FROM dual) flg_cancel,
    (SELECT pk_fast_track.get_fast_track_icon(i_lang,
                          epis.lprof,
                          epis.id_episode,
                          epis.id_fast_track,
                          epis.id_triage_color,
                          decode((SELECT pk_transfer_institution.check_epis_transfer(epis.id_episode)
                               FROM dual),
                             0,
                             'F',
                             'T'),
                          (SELECT pk_transfer_institution.check_epis_transfer(epis.id_episode)
                           FROM dual))
       FROM dual) fast_track_icon,
    decode(epis.triage_acuity, '0xFFFFFF', '0x787864', '0xFFFFFF') fast_track_color,
    'A' fast_track_status,
    (SELECT pk_fast_track.get_fast_track_desc(i_lang, epis.lprof, epis.id_fast_track, 'G' /*g_desc_grid*/)
       FROM dual) fast_track_desc,
    (SELECT pk_edis_triage.get_epis_esi_level(i_lang, epis.lprof, epis.id_episode, epis.id_triage_color)
       FROM dual) esi_level,
    (SELECT pk_hand_off_api.get_resp_icons(i_lang,
                         epis.lprof,
                         epis.id_episode,
                         pk_gridfilter.get_strings('l_hand_off_type',
                                     epis.i_lang,
                                     epis.lprof))
       FROM dual) resp_icons,
    decode(pk_prof_follow.get_follow_episode_by_me(epis.lprof, epis.id_episode, epis.id_schedule),
         'N',
         decode(pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang,
                                             epis.lprof,
                                             epis.id_episode,
                                             (SELECT pk_edis_list.get_prof_cat(epis.lprof) FROM dual),
                                             (SELECT pk_gridfilter.get_strings('l_hand_off_type',
                                                              epis.i_lang,
                                                              epis.lprof) FROM dual),
                                             'Y'),
                           epis.id ),
            -1,
            'Y',
            'N'),
         'N') prof_follow_add,
    (SELECT pk_prof_follow.get_follow_episode_by_me(epis.lprof, epis.id_episode, epis.id_schedule)
       FROM dual) prof_follow_remove,
    (SELECT pk_adt_core.check_bulk_admission_episode(i_lang       => i_lang,
                             i_prof       => epis.lprof,
                             i_id_episode => epis.id_episode)
       FROM dual) pat_major_inc_icon,
    decode((SELECT pk_edis_list.get_prof_cat(epis.lprof)
         FROM dual),
         'N',
         (SELECT pk_grid.convert_grid_task_dates_to_str(i_lang, epis.lprof, g.oth_exam_n)
          FROM dual),
         (SELECT pk_grid.convert_grid_task_dates_to_str(i_lang, epis.lprof, g.oth_exam_d)
          FROM dual)) desc_oth_exam_req,
    decode((SELECT pk_edis_list.get_prof_cat(epis.lprof)
         FROM dual),
         'N',
         (SELECT pk_grid.convert_grid_task_dates_to_str(i_lang, epis.lprof, g.img_exam_n)
          FROM dual),
         (SELECT pk_grid.convert_grid_task_dates_to_str(i_lang, epis.lprof, g.img_exam_d)
          FROM dual)) desc_img_exam_req,
    (SELECT pk_edis_grid.get_length_of_stay_color(epis.lprof,
                            pk_edis_proc.get_los_duration_number(i_lang       => i_lang,
                                               i_prof       => epis.lprof,
                                               i_id_episode => epis.id_episode))
       FROM dual) length_of_stay_bg_color,
    (SELECT pk_grid.convert_grid_task_dates_to_str(i_lang, epis.lprof, g.opinion_state)
       FROM dual) desc_opinion,
    (SELECT pk_opinion.get_epis_last_opinion_popup(i_lang, epis.lprof, epis.id_episode)
       FROM dual) desc_opinion_popup,
    (SELECT pk_edis_grid.get_orig_anamn_desc(i_lang, epis.lprof, epis.id_visit, epis.id_episode)
       FROM dual) origin_anamn_full_desc,
    epis.id prof_id,
    epis.i_lang i_lang,
    epis.institution institution,
    epis.software software,
    r.id_room id_room,
    epis.episode_flg_status epis_flg_status,
    epis.id_schedule id_schedule,
    epis.id_first_nurse_resp,
    flg_disch_status flg_disch_status,
    epis.dt_begin_tstz
    FROM
      (
      SELECT
        gea.id_episode,
        gea.id_visit,
        gea.id_clinical_service,
        gea.episode_flg_status,
        gea.id_epis_type,
        gea.episode_companion,
        gea.barcode,
        gea.id_prof_cancel,
        gea.flg_type,
        gea.id_prev_episode,
        gea.dt_begin_tstz,
        gea.dt_end_tstz,
        gea.dt_cancel_tstz,
        gea.id_fast_track,
        gea.flg_ehr,
        gea.id_patient,
        gea.id_department,
        gea.id_institution,
        gea.id_software,
        gea.id_bed,
        gea.id_room,
        gea.id_professional,
        gea.norton,
        gea.flg_hydric,
        gea.flg_wound,
        gea.epis_info_companion,
        gea.flg_unknown,
        gea.desc_info,
        gea.id_schedule,
        gea.id_first_nurse_resp,
        gea.epis_info_flg_status,
        gea.id_dep_clin_serv,
        gea.id_first_dep_clin_serv,
        gea.dt_first_obs_tstz,
        gea.dt_first_nurse_obs_tstz,
        gea.dt_first_inst_obs_tstz,
        gea.triage_acuity,
        gea.triage_color_text,
        gea.triage_rank_acuity,
        gea.triage_flg_letter,
        gea.id_triage_color,
        gea.id_announced_arrival,
        v.id_origin id_origin,
        NULL flg_disch_status,
        v.i_lang,
        v.lprof,
        v.institution,
        v.software,
        v.id,
    ( select pk_sysdomain.get_rank(i_lang => v.i_lang, i_code_dom => v.xdomain, i_val => gea.epis_info_flg_status) from dual ) sd_rank,
    ( select pk_sysdomain.get_rank(i_lang => v.i_lang, i_code_dom => v.xdomain, i_val => gea.epis_info_flg_status) from dual ) sd_img_name
        FROM grids_ea gea
        join (
          select
            sys_context('ALERT_CONTEXT', 'i_lang') i_lang,
            profissional(
              sys_context('ALERT_CONTEXT', 'i_prof_id'),
              sys_context('ALERT_CONTEXT', 'i_institution'),
              sys_context('ALERT_CONTEXT', 'i_software')) lprof,
            sys_context('ALERT_CONTEXT', 'i_institution') institution,
            sys_context('ALERT_CONTEXT', 'i_software') software,
            sys_context('ALERT_CONTEXT', 'i_prof_id') id,
      'EPIS_INFO.FLG_STATUS' xdomain,
            vis.*
          from visit vis
          ) v on v.id_visit = gea.id_visit
        WHERE gea.id_epis_type = 2
        AND gea.flg_ehr = 'N'
    and gea.id_institution = v.institution
      ) epis
    left join grid_task g on g.id_episode = epis.id_episode
    left join room r on r.id_room = epis.id_room
  )
;
