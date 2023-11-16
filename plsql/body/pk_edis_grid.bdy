/*-- Last Change Revision: $Rev: 2027079 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:58 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_edis_grid AS

    g_package_name VARCHAR2(32);

    FUNCTION error_handling
    (
        i_lang           IN language.id_language%TYPE,
        i_func_proc_name IN VARCHAR2,
        i_error          IN VARCHAR2,
        i_sqlerror       IN VARCHAR2,
        i_rollback       IN BOOLEAN,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_error_in t_error_in := t_error_in();
        l_ret      BOOLEAN;
    
    BEGIN
    
        l_error_in.set_all(i_lang, SQLCODE, i_sqlerror, i_error, 'ALERT', g_package_name, i_func_proc_name);
        l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
    
        IF i_rollback = TRUE
        THEN
            pk_utils.undo_changes;
        END IF;
    
        RETURN FALSE;
    END error_handling;

    /**********************************************************************************************
    * Grelha do médico, para visualizar os seus pacientes
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_grid                   cursor with all episodes - c/ ou s/ alta médica, sem alta administrativa ou com alta administrativa
                                                                 se ainda tiverem workflow pendente.
    * @param o_flg_disch_pend         flag que determina se a alta pendente aparece ou nao na grelha
                                               N- aparece tranportes Y- pararece a alta pendente
    
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/05/30
    **********************************************************************************************/
    FUNCTION get_grid_my_pat_doc
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_grid           OUT pk_types.cursor_type,
        o_flg_disch_pend OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_hand_off_type sys_config.value%TYPE;
        l_num           NUMBER;
    
        l_msg_edis_grid_m003 sys_message.desc_message%TYPE;
        l_prof_cat           VARCHAR2(0050);
        l_config_show_resident CONSTANT sys_config.id_sys_config%TYPE := 'GRIDS_SHOW_RESIDENT';
        l_show_resident_physician sys_config.value%TYPE;
        l_show_only_epis_resp     sys_config.value%TYPE;
    
        l_exception EXCEPTION;
        l_error t_error_out;
        l_config_origin CONSTANT sys_config.id_sys_config%TYPE := 'GRID_ORIGINS';
    
    BEGIN
        g_error        := 'GET DATES';
        g_sysdate_tstz := current_timestamp;
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
    
        g_error := 'GET CONFIGURATIONS';
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
        l_msg_edis_grid_m003      := pk_message.get_message(i_lang, 'EDIS_GRID_M003');
        l_prof_cat                := pk_edis_list.get_prof_cat(i_prof);
        l_show_resident_physician := pk_sysconfig.get_config(i_code_cf => l_config_show_resident, i_prof => i_prof);
        l_show_only_epis_resp     := pk_sysconfig.get_config(i_code_cf => pk_hand_off_core.g_config_show_only_epis_resp,
                                                             i_prof    => i_prof);
    
        g_grid_origins     := pk_sysconfig.get_config(l_config_origin, i_prof);
        g_tab_grid_origins := pk_utils.str_split_l(g_grid_origins, '|');
    
        g_error := 'GET CURSOR O_GRID';
        OPEN o_grid FOR
            SELECT acuity,
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
                   origin_anamn_full_desc
              FROM (SELECT epis.triage_acuity acuity,
                           epis.triage_color_text color_text,
                           epis.triage_rank_acuity rank_acuity,
                           decode(epis.triage_flg_letter, g_yes, l_msg_edis_grid_m003) acuity_desc,
                           epis.id_episode,
                           pk_date_utils.date_send_tsz(i_lang, epis.dt_begin_tstz_e, i_prof) dt_begin,
                           pk_date_utils.date_char_hour_tsz(i_lang,
                                                            epis.dt_begin_tstz_e,
                                                            i_prof.institution,
                                                            i_prof.software) dt_efectiv,
                           pk_date_utils.diff_timestamp(g_sysdate_tstz, epis.dt_begin_tstz_e) order_time, --ET 2007/03/01
                           pk_edis_proc.get_los_duration(i_lang       => i_lang,
                                                         i_prof       => i_prof,
                                                         i_id_episode => epis.id_episode) date_send, -- Length of stay
                           pk_edis_proc.get_formatted_string_for_sort(i_lang    => i_lang,
                                                                      i_prof    => i_prof,
                                                                      i_type    => pk_edis_proc.g_sort_type_los,
                                                                      i_episode => epis.id_episode) date_send_sort,
                           (SELECT nvl(nvl(r.desc_room_abbreviation,
                                           pk_translation.get_translation_dtchk(i_lang,
                                                                                'ROOM.CODE_ABBREVIATION' || epis.id_room)),
                                       nvl(r.desc_room,
                                           pk_translation.get_translation_dtchk(i_lang, 'ROOM.CODE_ROOM.' || epis.id_room)))
                              FROM dual) desc_room,
                           epis.id_patient,
                           pk_patient.get_pat_name(i_lang, i_prof, epis.id_patient, epis.id_episode) name_pat,
                           -- ALERT-102882 Patient name used for sorting
                           pk_patient.get_pat_name_to_sort(i_lang, i_prof, epis.id_patient, epis.id_episode, NULL) name_pat_sort,
                           pk_adt.get_pat_non_disc_options(i_lang, i_prof, epis.id_patient) pat_ndo,
                           pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, epis.id_patient) pat_nd_icon,
                           (SELECT pk_patient.get_gender(i_lang, gender) gender
                              FROM patient
                             WHERE id_patient = epis.id_patient) gender,
                           -- Display number of responsible PHYSICIANS for the episode,
                           -- if institution is using the multiple hand-off mechanism,
                           -- along with the name of the main responsible for the patient.
                           (SELECT pk_hand_off_core.get_responsibles_str(i_lang,
                                                                         i_prof,
                                                                         pk_alert_constant.g_cat_type_doc,
                                                                         epis.id_episode,
                                                                         epis.id_professional,
                                                                         l_hand_off_type,
                                                                         'G',
                                                                         l_show_only_epis_resp)
                              FROM dual) name_prof,
                           -- Only display the name of the responsible nurse, for all hand-off mechanisms
                           pk_prof_utils.get_nickname(i_lang, epis.id_first_nurse_resp) name_nurse,
                           -- Team name or Resident physician(s)
                           decode(l_show_resident_physician,
                                  pk_alert_constant.g_yes,
                                  (SELECT pk_hand_off_core.get_resp_by_type_grid_str(i_lang,
                                                                                     i_prof,
                                                                                     epis.id_episode,
                                                                                     l_hand_off_type,
                                                                                     pk_hand_off_core.g_resident,
                                                                                     'G')
                                     FROM dual),
                                  (SELECT pk_prof_teams.get_prof_current_team(i_lang,
                                                                              i_prof,
                                                                              epis.id_department,
                                                                              epis.id_software,
                                                                              epis.id_professional,
                                                                              epis.id_first_nurse_resp)
                                     FROM dual)) prof_team,
                           -- Display text in tooltips
                           -- 1) Responsible physician(s)
                           (SELECT pk_hand_off_core.get_responsibles_str(i_lang,
                                                                         i_prof,
                                                                         pk_alert_constant.g_cat_type_doc,
                                                                         epis.id_episode,
                                                                         epis.id_professional,
                                                                         l_hand_off_type,
                                                                         'T')
                              FROM dual) name_prof_tooltip,
                           -- 2) Responsible nurse
                           (SELECT pk_hand_off_core.get_responsibles_str(i_lang,
                                                                         i_prof,
                                                                         pk_alert_constant.g_cat_type_nurse,
                                                                         epis.id_episode,
                                                                         epis.id_first_nurse_resp,
                                                                         l_hand_off_type,
                                                                         'T')
                              FROM dual) name_nurse_tooltip,
                           -- 3) Responsible team
                           (SELECT pk_hand_off_core.get_team_str(i_lang,
                                                                 i_prof,
                                                                 epis.id_department,
                                                                 epis.id_software,
                                                                 epis.id_professional,
                                                                 epis.id_first_nurse_resp,
                                                                 l_hand_off_type,
                                                                 NULL)
                              FROM dual) prof_team_tooltip,
                           pk_patient.get_pat_age(i_lang, epis.id_patient, i_prof) pat_age,
                           pk_edis_proc.get_formatted_string_for_sort(i_lang    => i_lang,
                                                                      i_prof    => i_prof,
                                                                      i_type    => pk_edis_proc.g_sort_type_age,
                                                                      i_episode => epis.id_episode) pat_age_for_order_by,
                           pk_date_utils.date_send_tsz(i_lang, epis.dt_first_obs_tstz, i_prof) dt_first_obs,
                           lpad(to_char(sd.rank), 6, '0') || sd.img_name img_transp,
                           pk_patphoto.get_pat_photo(i_lang, i_prof, epis.id_patient, epis.id_episode, epis.id_schedule) photo,
                           pk_patient_tracking.get_care_stage_grid_status(i_lang,
                                                                          i_prof,
                                                                          epis.id_episode,
                                                                          g_sysdate_char) care_stage,
                           pk_patient_tracking.get_current_state_rank(i_lang, i_prof, epis.id_episode) care_stage_rank,
                           'N' flg_temp,
                           g_sysdate_char dt_server,
                           NULL desc_temp,
                           --grid_task
                           (SELECT pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, g.drug_presc)
                              FROM dual) desc_drug_presc,
                           pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                  i_prof,
                                                                  pk_grid.get_prioritary_task(i_lang,
                                                                                              i_prof,
                                                                                              pk_grid.get_prioritary_task(i_lang,
                                                                                                                          i_prof,
                                                                                                                          g.intervention,
                                                                                                                          g.nurse_activity,
                                                                                                                          g_domain_nurse_act,
                                                                                                                          l_prof_cat),
                                                                                              
                                                                                              g.monitorization,
                                                                                              NULL,
                                                                                              l_prof_cat)) desc_monit_interv_presc,
                           (SELECT pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, g.movement)
                              FROM dual) desc_movement,
                           (SELECT pk_grid.visit_grid_task_str(i_lang, i_prof, epis.id_visit, g_task_analysis, l_prof_cat)
                              FROM dual) desc_analysis_req,
                           (SELECT pk_grid.visit_grid_task_str(i_lang, i_prof, epis.id_visit, g_task_exam, l_prof_cat)
                              FROM dual) desc_exam_req,
                           (SELECT pk_string_utils.concat_if_exists((SELECT get_grid_origin_abbrev(i_lang,
                                                                                                  i_prof,
                                                                                                  v.id_origin)
                                                                      FROM visit v
                                                                     WHERE v.id_visit = epis.id_visit),
                                                                    pk_edis_grid.get_complaint_grid(i_lang,
                                                                                                    i_prof,
                                                                                                    epis.id_episode),
                                                                    ' / ')
                              FROM dual) desc_epis_anamnesis,
                           -- odete monteiro 8/11/2007 nova coluna de alta clinica pendente
                           (SELECT pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, g.discharge_pend)
                              FROM dual) desc_disch_pend_time,
                           (SELECT pk_date_utils.date_send_tsz(i_lang, nvl(d.dt_med_tstz, d.dt_pend_tstz), i_prof)
                              FROM discharge d
                             WHERE d.flg_status = g_discharge_flg_status_pend
                               AND d.id_episode = epis.id_episode
                               AND rownum < 2) disch_pend_time,
                           -- José Brito 22/04/2008 Devolver FLG_CANCEL que indica se o episódio é temporário e se pode ser cancelado
                           pk_visit.check_flg_cancel(i_lang, i_prof, epis.id_episode) flg_cancel,
                           (SELECT pk_fast_track.get_fast_track_icon(i_lang,
                                                                     i_prof,
                                                                     epis.id_episode,
                                                                     epis.id_fast_track,
                                                                     epis.id_triage_color,
                                                                     decode(epis.has_transfer,
                                                                            0,
                                                                            g_icon_ft,
                                                                            g_icon_ft_transfer),
                                                                     epis.has_transfer)
                              FROM dual) fast_track_icon,
                           decode(epis.triage_acuity, g_ft_color, g_ft_triage_white, g_ft_color) fast_track_color,
                           g_ft_status fast_track_status,
                           (SELECT pk_fast_track.get_fast_track_desc(i_lang, i_prof, epis.id_fast_track, g_desc_grid)
                              FROM dual) fast_track_desc,
                           -- José Brito 12/01/2010 ALERT-16615 Returns the ESI level, if patient was triaged with ESI protocol.
                           (SELECT pk_edis_triage.get_epis_esi_level(i_lang,
                                                                     i_prof,
                                                                     epis.id_episode,
                                                                     epis.id_triage_color)
                              FROM dual) esi_level,
                           --Alexandre Santos 13-10-2010 ALERT-726 Changing and cancelling appointmentsChanging to another physician with the same specialty as the responsible physician. However, the responsible physician remains the same.
                           (SELECT pk_hand_off_api.get_resp_icons(i_lang, i_prof, epis.id_episode, l_hand_off_type)
                              FROM dual) resp_icons,
                           pk_alert_constant.g_no prof_follow_add,
                           pk_prof_follow.get_follow_episode_by_me(i_prof, epis.id_episode, epis.id_schedule) prof_follow_remove,
                           --Gisela Couto 04-09-2014  ALERT-284142 Major incident icon
                           pk_adt_core.check_bulk_admission_episode(i_lang       => i_lang,
                                                                    i_prof       => i_prof,
                                                                    i_id_episode => epis.id_episode) pat_major_inc_icon,
                           decode(l_prof_cat,
                                  pk_alert_constant.g_flg_nurse,
                                  (SELECT pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, g.oth_exam_n)
                                     FROM dual),
                                  (SELECT pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, g.oth_exam_d)
                                     FROM dual)) desc_oth_exam_req,
                           decode(l_prof_cat,
                                  pk_alert_constant.g_flg_nurse,
                                  (SELECT pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, g.img_exam_n)
                                     FROM dual),
                                  (SELECT pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, g.img_exam_d)
                                     FROM dual)) desc_img_exam_req,
                           get_length_of_stay_color(i_prof,
                                                    pk_edis_proc.get_los_duration_number(i_lang       => i_lang,
                                                                                         i_prof       => i_prof,
                                                                                         i_id_episode => epis.id_episode)) length_of_stay_bg_color,
                           
                           (SELECT pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, g.opinion_state)
                              FROM dual) desc_opinion,
                           pk_opinion.get_epis_last_opinion_popup(i_lang, i_prof, epis.id_episode) desc_opinion_popup,
                           get_orig_anamn_desc(i_lang, i_prof, epis.id_visit, epis.id_episode) origin_anamn_full_desc
                    
                      FROM v_episode_act epis, sys_domain sd, room r, grid_task g
                     WHERE epis.id_software = i_prof.software
                       AND epis.id_institution = i_prof.institution
                       AND epis.id_episode = g.id_episode(+)
                          -- José Brito 19/10/2009 ALERT-39320 Responsible physicians not registered in EPIS_INFO must
                          --                                   have the patient available in the main grid.
                       AND (pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                             i_prof,
                                                                                             epis.id_episode,
                                                                                             l_prof_cat,
                                                                                             l_hand_off_type,
                                                                                             pk_alert_constant.g_yes),
                                                         i_prof.id) != -1 OR
                           (pk_prof_follow.get_follow_episode_by_me(i_prof, epis.id_episode, epis.id_schedule) =
                           pk_alert_constant.g_yes))
                       AND epis.flg_ehr = g_flg_ehr_normal
                       AND sd.val = epis.flg_status_ei
                       AND sd.code_domain = 'EPIS_INFO.FLG_STATUS'
                       AND sd.domain_owner = pk_sysdomain.k_default_schema
                       AND sd.id_language = i_lang
                       AND epis.id_room = r.id_room(+)
                    -- Pacientes referenciados por outro médico (com carta) tem prioridade sobre outros pacientes triados com a mesma cor
                     ORDER BY rank_acuity,
                              
                              decode(pk_sysconfig.get_config('EDIS_GRID_ORIGIN_ORDER_WITHOUT_TRIAGE', i_prof),
                                     pk_alert_constant.g_yes,
                                     decode(pk_edis_triage.get_flag_no_color(i_lang, i_prof, epis.id_triage_color),
                                            'S',
                                            0,
                                            decode(pk_utils.search_table_varchar(g_tab_grid_origins,
                                                                                 (SELECT id_origin
                                                                                    FROM visit
                                                                                   WHERE id_visit = epis.id_visit)),
                                                   -1,
                                                   1,
                                                   0)),
                                     decode(pk_utils.search_table_varchar(g_tab_grid_origins,
                                                                          (SELECT id_origin
                                                                             FROM visit
                                                                            WHERE id_visit = epis.id_visit)),
                                            -1,
                                            1,
                                            0)),
                              decode(orderby_flg_letter(i_prof),
                                     pk_alert_constant.g_yes,
                                     decode(epis.triage_flg_letter, g_yes, 0, 1)),
                              epis.dt_begin_tstz_e);
    
        o_flg_disch_pend := 'N';
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_types.open_my_cursor(o_grid);
            RETURN error_handling(i_lang,
                                  'GET_GRID_MY_PAT_DOC',
                                  g_error || ' / ' || l_error.err_desc,
                                  SQLERRM,
                                  FALSE,
                                  o_error);
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_grid);
            RETURN error_handling(i_lang, 'GET_GRID_MY_PAT_DOC', g_error, SQLERRM, FALSE, o_error);
    END;
    --
    /**********************************************************************************************
    * Grelha do médico, para visualizar todos os pacientes alocados ás suas salas
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_grid                   cursor with all episodes - cursor with all episodes - c/ ou s/ alta médica, sem alta administrativa ou com alta administrativa
                                                                 se ainda tiverem workflow pendente.
    * @param o_flg_disch_pend         flag que determina se a alta pendente aparece ou nao na grelha
                                               N- aparece tranportes Y- pararece a alta pendente
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/05/30
    **********************************************************************************************/
    FUNCTION get_grid_all_pat_doc
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_grid           OUT pk_types.cursor_type,
        o_flg_disch_pend OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_hand_off_type sys_config.value%TYPE;
        l_num           NUMBER;
    
        l_prof_cat           category.flg_type%TYPE;
        l_msg_edis_grid_m003 sys_message.desc_message%TYPE;
        l_config_show_resident CONSTANT sys_config.id_sys_config%TYPE := 'GRIDS_SHOW_RESIDENT';
        l_show_resident_physician sys_config.value%TYPE;
        l_show_only_epis_resp     sys_config.value%TYPE;
    
        l_error t_error_out;
        l_exception EXCEPTION;
        l_config_origin CONSTANT sys_config.id_sys_config%TYPE := 'GRID_ORIGINS';
    
    BEGIN
        g_error        := 'GET DATES';
        g_sysdate_tstz := current_timestamp;
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
    
        g_error := 'GET CONFIGURATIONS';
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
        l_msg_edis_grid_m003      := pk_message.get_message(i_lang, 'EDIS_GRID_M003');
        l_show_resident_physician := pk_sysconfig.get_config(i_code_cf => l_config_show_resident, i_prof => i_prof);
        l_show_only_epis_resp     := pk_sysconfig.get_config(i_code_cf => pk_hand_off_core.g_config_show_only_epis_resp,
                                                             i_prof    => i_prof);
    
        g_error            := 'GET PROF_CAT';
        l_prof_cat         := pk_edis_list.get_prof_cat(i_prof);
        g_grid_origins     := pk_sysconfig.get_config(l_config_origin, i_prof);
        g_tab_grid_origins := pk_utils.str_split_l(g_grid_origins, '|');
    
        g_error := 'OPEN O_GRID';
        OPEN o_grid FOR
            SELECT acuity,
                   color_text,
                   rank_acuity,
                   acuity_desc,
                   id_episode,
                   dt_begin,
                   dt_efectiv,
                   order_time,
                   date_send,
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
                   origin_anamn_full_desc
              FROM (SELECT epis.triage_acuity acuity,
                           epis.triage_color_text color_text,
                           epis.triage_rank_acuity rank_acuity,
                           decode(epis.triage_flg_letter, g_yes, l_msg_edis_grid_m003) acuity_desc,
                           epis.id_episode,
                           pk_date_utils.date_send_tsz(i_lang, epis.dt_begin_tstz_e, i_prof) dt_begin,
                           pk_date_utils.date_char_hour_tsz(i_lang,
                                                            epis.dt_begin_tstz_e,
                                                            i_prof.institution,
                                                            i_prof.software) dt_efectiv,
                           pk_date_utils.diff_timestamp(g_sysdate_tstz, epis.dt_begin_tstz_e) order_time, --ET 2007/03/01
                           pk_edis_proc.get_los_duration(i_lang       => i_lang,
                                                         i_prof       => i_prof,
                                                         i_id_episode => epis.id_episode) date_send, -- Length of stay string
                           pk_edis_proc.get_formatted_string_for_sort(i_lang    => i_lang,
                                                                      i_prof    => i_prof,
                                                                      i_type    => pk_edis_proc.g_sort_type_los,
                                                                      i_episode => epis.id_episode) date_send_sort,
                           nvl(nvl(r.desc_room_abbreviation,
                                   pk_translation.get_translation_dtchk(i_lang, 'ROOM.CODE_ABBREVIATION' || epis.id_room)),
                               nvl(r.desc_room,
                                   pk_translation.get_translation_dtchk(i_lang, 'ROOM.CODE_ROOM.' || epis.id_room))) desc_room,
                           epis.id_patient,
                           pk_patient.get_pat_name(i_lang, i_prof, epis.id_patient, epis.id_episode) name_pat,
                           -- ALERT-102882 Patient name used for sorting
                           pk_patient.get_pat_name_to_sort(i_lang, i_prof, epis.id_patient, epis.id_episode, NULL) name_pat_sort,
                           pk_adt.get_pat_non_disc_options(i_lang, i_prof, epis.id_patient) pat_ndo,
                           pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, epis.id_patient) pat_nd_icon,
                           (SELECT pk_patient.get_gender(i_lang, gender) gender
                              FROM patient
                             WHERE id_patient = epis.id_patient) gender,
                           (SELECT pk_hand_off_core.get_responsibles_str(i_lang,
                                                                         i_prof,
                                                                         pk_alert_constant.g_cat_type_doc,
                                                                         epis.id_episode,
                                                                         epis.id_professional,
                                                                         l_hand_off_type,
                                                                         'G',
                                                                         l_show_only_epis_resp)
                              FROM dual) name_prof,
                           pk_prof_utils.get_nickname(i_lang, epis.id_first_nurse_resp) name_nurse,
                           -- Team name or Resident physician(s)
                           decode(l_show_resident_physician,
                                  pk_alert_constant.g_yes,
                                  (SELECT pk_hand_off_core.get_resp_by_type_grid_str(i_lang,
                                                                                     i_prof,
                                                                                     epis.id_episode,
                                                                                     l_hand_off_type,
                                                                                     pk_hand_off_core.g_resident,
                                                                                     'G')
                                     FROM dual),
                                  (SELECT pk_prof_teams.get_prof_current_team(i_lang,
                                                                              i_prof,
                                                                              epis.id_department,
                                                                              epis.id_software,
                                                                              epis.id_professional,
                                                                              epis.id_first_nurse_resp)
                                     FROM dual)) prof_team,
                           -- Display text in tooltips
                           -- 1) Responsible physician(s)
                           (SELECT pk_hand_off_core.get_responsibles_str(i_lang,
                                                                         i_prof,
                                                                         pk_alert_constant.g_cat_type_doc,
                                                                         epis.id_episode,
                                                                         epis.id_professional,
                                                                         l_hand_off_type,
                                                                         'T')
                              FROM dual) name_prof_tooltip,
                           -- 2) Responsible nurse
                           (SELECT pk_hand_off_core.get_responsibles_str(i_lang,
                                                                         i_prof,
                                                                         pk_alert_constant.g_cat_type_nurse,
                                                                         epis.id_episode,
                                                                         epis.id_first_nurse_resp,
                                                                         l_hand_off_type,
                                                                         'T')
                              FROM dual) name_nurse_tooltip,
                           -- 3) Responsible team
                           (SELECT pk_hand_off_core.get_team_str(i_lang,
                                                                 i_prof,
                                                                 epis.id_department,
                                                                 epis.id_software,
                                                                 epis.id_professional,
                                                                 epis.id_first_nurse_resp,
                                                                 l_hand_off_type,
                                                                 NULL)
                              FROM dual) prof_team_tooltip,
                           pk_patient.get_pat_age(i_lang, epis.id_patient, i_prof) pat_age,
                           pk_edis_proc.get_formatted_string_for_sort(i_lang    => i_lang,
                                                                      i_prof    => i_prof,
                                                                      i_type    => pk_edis_proc.g_sort_type_age,
                                                                      i_episode => epis.id_episode) pat_age_for_order_by,
                           pk_date_utils.date_send_tsz(i_lang, epis.dt_first_obs_tstz, i_prof) dt_first_obs,
                           lpad(to_char(sd.rank), 6, '0') || sd.img_name img_transp,
                           pk_patphoto.get_pat_photo(i_lang, i_prof, epis.id_patient, epis.id_episode, epis.id_schedule) photo,
                           pk_patient_tracking.get_care_stage_grid_status(i_lang,
                                                                          i_prof,
                                                                          epis.id_episode,
                                                                          g_sysdate_char) care_stage,
                           pk_patient_tracking.get_current_state_rank(i_lang, i_prof, epis.id_episode) care_stage_rank,
                           'N' flg_temp,
                           g_sysdate_char dt_server,
                           NULL desc_temp,
                           --grid_task
                           (SELECT pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, g.drug_presc)
                              FROM dual) desc_drug_presc,
                           pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                  i_prof,
                                                                  pk_grid.get_prioritary_task(i_lang,
                                                                                              i_prof,
                                                                                              pk_grid.get_prioritary_task(i_lang,
                                                                                                                          i_prof,
                                                                                                                          g.intervention,
                                                                                                                          g.nurse_activity,
                                                                                                                          g_domain_nurse_act,
                                                                                                                          l_prof_cat),
                                                                                              
                                                                                              g.monitorization,
                                                                                              NULL,
                                                                                              l_prof_cat)) desc_monit_interv_presc,
                           (SELECT pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, g.movement)
                              FROM dual) desc_movement,
                           (SELECT pk_grid.visit_grid_task_str(i_lang, i_prof, epis.id_visit, g_task_analysis, l_prof_cat)
                              FROM dual) desc_analysis_req,
                           (SELECT pk_grid.visit_grid_task_str(i_lang, i_prof, epis.id_visit, g_task_exam, l_prof_cat)
                              FROM dual) desc_exam_req,
                           (SELECT pk_string_utils.concat_if_exists((SELECT get_grid_origin_abbrev(i_lang,
                                                                                                  i_prof,
                                                                                                  v.id_origin)
                                                                      FROM visit v
                                                                     WHERE v.id_visit = epis.id_visit),
                                                                    pk_edis_grid.get_complaint_grid(i_lang,
                                                                                                    i_prof,
                                                                                                    epis.id_episode),
                                                                    ' / ')
                              FROM dual) desc_epis_anamnesis,
                           -- odete monteiro 8/11/2007 nova coluna de alta clinica pendente
                           (SELECT pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, g.discharge_pend)
                              FROM dual) desc_disch_pend_time,
                           (SELECT pk_date_utils.date_send_tsz(i_lang, nvl(d.dt_med_tstz, d.dt_pend_tstz), i_prof)
                              FROM discharge d
                             WHERE d.flg_status = g_discharge_flg_status_pend
                               AND d.id_episode = epis.id_episode
                               AND rownum < 2) disch_pend_time,
                           (SELECT pk_fast_track.get_fast_track_icon(i_lang,
                                                                     i_prof,
                                                                     epis.id_episode,
                                                                     epis.id_fast_track,
                                                                     epis.id_triage_color,
                                                                     decode(epis.has_transfer,
                                                                            0,
                                                                            g_icon_ft,
                                                                            g_icon_ft_transfer),
                                                                     epis.has_transfer)
                              FROM dual) fast_track_icon,
                           decode(epis.triage_acuity, g_ft_color, g_ft_triage_white, g_ft_color) fast_track_color,
                           g_ft_status fast_track_status,
                           (SELECT pk_fast_track.get_fast_track_desc(i_lang, i_prof, epis.id_fast_track, g_desc_grid)
                              FROM dual) fast_track_desc,
                           (SELECT pk_edis_triage.get_epis_esi_level(i_lang,
                                                                     i_prof,
                                                                     epis.id_episode,
                                                                     epis.id_triage_color)
                              FROM dual) esi_level,
                           --Alexandre Santos 13-10-2010 ALERT-726 Changing and cancelling appointmentsChanging to another physician with the same specialty as the responsible physician. However, the responsible physician remains the same.
                           (SELECT pk_hand_off_api.get_resp_icons(i_lang, i_prof, epis.id_episode, l_hand_off_type)
                              FROM dual) resp_icons,
                           decode(pk_prof_follow.get_follow_episode_by_me(i_prof, epis.id_episode, epis.id_schedule),
                                  pk_alert_constant.g_no,
                                  decode(pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                                          i_prof,
                                                                                                          epis.id_episode,
                                                                                                          l_prof_cat,
                                                                                                          l_hand_off_type,
                                                                                                          pk_alert_constant.g_yes),
                                                                      i_prof.id),
                                         -1,
                                         pk_alert_constant.g_yes,
                                         pk_alert_constant.g_no),
                                  pk_alert_constant.g_no) prof_follow_add,
                           pk_prof_follow.get_follow_episode_by_me(i_prof, epis.id_episode, epis.id_schedule) prof_follow_remove,
                           --Gisela Couto 04-09-2014  ALERT-284142 Major incident icon
                           pk_adt_core.check_bulk_admission_episode(i_lang       => i_lang,
                                                                    i_prof       => i_prof,
                                                                    i_id_episode => epis.id_episode) pat_major_inc_icon,
                           decode(l_prof_cat,
                                  pk_alert_constant.g_flg_nurse,
                                  (SELECT pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, g.oth_exam_n)
                                     FROM dual),
                                  (SELECT pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, g.oth_exam_d)
                                     FROM dual)) desc_oth_exam_req,
                           decode(l_prof_cat,
                                  pk_alert_constant.g_flg_nurse,
                                  (SELECT pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, g.img_exam_n)
                                     FROM dual),
                                  (SELECT pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, g.img_exam_d)
                                     FROM dual)) desc_img_exam_req,
                           
                           get_length_of_stay_color(i_prof,
                                                    pk_edis_proc.get_los_duration_number(i_lang       => i_lang,
                                                                                         i_prof       => i_prof,
                                                                                         i_id_episode => epis.id_episode)) length_of_stay_bg_color,
                           (SELECT pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, g.opinion_state)
                              FROM dual) desc_opinion,
                           pk_opinion.get_epis_last_opinion_popup(i_lang       => i_lang,
                                                                  i_prof       => i_prof,
                                                                  i_id_episode => epis.id_episode) desc_opinion_popup,
                           get_orig_anamn_desc(i_lang, i_prof, epis.id_visit, epis.id_episode) origin_anamn_full_desc
                      FROM v_episode_act epis, sys_domain sd, room r, grid_task g
                     WHERE epis.id_software = i_prof.software
                       AND epis.id_institution = i_prof.institution
                       AND epis.id_episode = g.id_episode(+)
                          -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer do tipo EHR
                       AND epis.flg_ehr = g_flg_ehr_normal
                       AND sd.val = epis.flg_status_ei
                       AND sd.domain_owner = pk_sysdomain.k_default_schema
                       AND sd.code_domain = 'EPIS_INFO.FLG_STATUS'
                       AND sd.id_language = i_lang
                       AND EXISTS (SELECT 0
                              FROM prof_room pr
                             WHERE pr.id_professional = i_prof.id
                               AND epis.id_room = pr.id_room)
                       AND epis.id_room = r.id_room(+)
                    -- Pacientes referenciados por outro médico (com carta) tem prioridade sobre outros pacientes triados com a mesma cor
                     ORDER BY rank_acuity,
                              
                              decode(pk_sysconfig.get_config('EDIS_GRID_ORIGIN_ORDER_WITHOUT_TRIAGE', i_prof),
                                     pk_alert_constant.g_yes,
                                     decode(pk_edis_triage.get_flag_no_color(i_lang, i_prof, epis.id_triage_color),
                                            'S',
                                            0,
                                            decode(pk_utils.search_table_varchar(g_tab_grid_origins,
                                                                                 (SELECT id_origin
                                                                                    FROM visit
                                                                                   WHERE id_visit = epis.id_visit)),
                                                   -1,
                                                   1,
                                                   0)),
                                     decode(pk_utils.search_table_varchar(g_tab_grid_origins,
                                                                          (SELECT id_origin
                                                                             FROM visit
                                                                            WHERE id_visit = epis.id_visit)),
                                            -1,
                                            1,
                                            0)),
                              decode(orderby_flg_letter(i_prof),
                                     pk_alert_constant.g_yes,
                                     decode(epis.triage_flg_letter, g_yes, 0, 1)),
                              epis.dt_begin_tstz_e);
    
        o_flg_disch_pend := 'N';
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_types.open_my_cursor(o_grid);
            RETURN error_handling(i_lang,
                                  'GET_GRID_ALL_PAT_DOC',
                                  g_error || ' / ' || l_error.err_desc,
                                  SQLERRM,
                                  FALSE,
                                  o_error);
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_grid);
            RETURN error_handling(i_lang, 'GET_GRID_ALL_PAT_DOC', g_error, SQLERRM, FALSE, o_error);
    END;
    --
    /**********************************************************************************************
    * Grelha do médico, para visualizar todos os pacientes alocados á sala seleccionada
    *
    * @param i_lang                   the id language
    * @param i_room                   room id
    * @param i_prof                   professional, software and institution ids
    * @param o_grid                   cursor with all patients
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/05/31
    **********************************************************************************************/
    FUNCTION get_grid_room_pat_doc
    (
        i_lang  IN language.id_language%TYPE,
        i_room  IN room.id_room%TYPE,
        i_prof  IN profissional,
        o_grid  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_msg_edis_grid_m003 sys_message.desc_message%TYPE;
        l_profile            VARCHAR2(0050);
        l_hand_off_type      sys_config.value%TYPE;
        l_config_origin CONSTANT sys_config.id_sys_config%TYPE := 'GRID_ORIGINS';
    
    BEGIN
        g_error        := 'GET DATES';
        g_sysdate_tstz := current_timestamp;
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
    
        g_error := 'GET CONFIGURATIONS';
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
        l_msg_edis_grid_m003 := pk_message.get_message(i_lang, 'EDIS_GRID_M003');
        l_profile            := pk_edis_list.get_prof_cat(i_prof);
        g_grid_origins       := pk_sysconfig.get_config(l_config_origin, i_prof);
        g_tab_grid_origins   := pk_utils.str_split_l(g_grid_origins, '|');
    
        --
        g_error := 'GET CURSOR O_GRID';
        OPEN o_grid FOR
            SELECT acuity,
                   color_text,
                   rank_acuity,
                   acuity_desc,
                   id_episode,
                   dt_begin,
                   dt_efectiv,
                   order_time,
                   date_send,
                   desc_room,
                   id_patient,
                   name_pat,
                   name_pat_sort,
                   pat_ndo,
                   pat_nd_icon,
                   gender,
                   name_prof,
                   name_nurse,
                   name_prof_tooltip,
                   name_nurse_tooltip,
                   pat_age,
                   pat_age_for_order_by,
                   dt_first_obs,
                   img_transp,
                   photo,
                   flg_temp,
                   dt_server,
                   desc_temp,
                   desc_drug_presc,
                   desc_monit_interv_presc,
                   desc_interv_presc,
                   desc_monitorization,
                   desc_movement,
                   desc_analysis_req,
                   desc_exam_req,
                   desc_epis_anamnesis,
                   fast_track_icon,
                   fast_track_color,
                   fast_track_status,
                   fast_track_desc,
                   esi_level,
                   resp_icons,
                   prof_follow_add,
                   prof_follow_remove,
                   desc_oth_exam_req,
                   desc_img_exam_req,
                   length_of_stay_bg_color,
                   desc_opinion,
                   desc_opinion_popup,
                   rownum rank_triage,
                   origin_anamn_full_desc
              FROM (SELECT epis.triage_acuity acuity,
                           epis.triage_color_text color_text,
                           epis.triage_rank_acuity rank_acuity,
                           decode(epis.triage_flg_letter, g_yes, l_msg_edis_grid_m003) acuity_desc,
                           epis.id_episode,
                           pk_date_utils.date_send_tsz(i_lang, epis.dt_begin_tstz_e, i_prof) dt_begin,
                           pk_date_utils.date_char_hour_tsz(i_lang,
                                                            epis.dt_begin_tstz_e,
                                                            i_prof.institution,
                                                            i_prof.software) dt_efectiv,
                           pk_date_utils.diff_timestamp(g_sysdate_tstz, epis.dt_begin_tstz_e) order_time, --ET 2007/03/01
                           pk_date_utils.get_elapsed_tsz(i_lang, epis.dt_begin_tstz_e, g_sysdate_tstz) date_send, -- Hora em atraso
                           nvl(nvl(r.desc_room_abbreviation,
                                   pk_translation.get_translation_dtchk(i_lang, 'ROOM.CODE_ABBREVIATION' || epis.id_room)),
                               nvl(r.desc_room,
                                   pk_translation.get_translation_dtchk(i_lang, 'ROOM.CODE_ROOM.' || epis.id_room))) desc_room,
                           epis.id_patient,
                           pk_patient.get_pat_name(i_lang, i_prof, epis.id_patient, epis.id_episode) name_pat,
                           -- ALERT-102882 Patient name used for sorting
                           pk_patient.get_pat_name_to_sort(i_lang, i_prof, epis.id_patient, epis.id_episode, NULL) name_pat_sort,
                           pk_adt.get_pat_non_disc_options(i_lang, i_prof, epis.id_patient) pat_ndo,
                           pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, epis.id_patient) pat_nd_icon,
                           (SELECT pk_patient.get_gender(i_lang, gender) gender
                              FROM patient
                             WHERE id_patient = epis.id_patient) gender,
                           -- Display number of responsible PHYSICIANS for the episode,
                           -- if institution is using the multiple hand-off mechanism,
                           -- along with the name of the main responsible for the patient.
                           (SELECT pk_hand_off_core.get_responsibles_str(i_lang,
                                                                         i_prof,
                                                                         pk_alert_constant.g_cat_type_doc,
                                                                         epis.id_episode,
                                                                         epis.id_professional,
                                                                         l_hand_off_type,
                                                                         'G')
                              FROM dual) name_prof,
                           pk_prof_utils.get_nickname(i_lang, epis.id_first_nurse_resp) name_nurse,
                           -- Display text in tooltips
                           -- 1) Responsible physician(s)
                           (SELECT pk_hand_off_core.get_responsibles_str(i_lang,
                                                                         i_prof,
                                                                         pk_alert_constant.g_cat_type_doc,
                                                                         epis.id_episode,
                                                                         epis.id_professional,
                                                                         l_hand_off_type,
                                                                         'T')
                              FROM dual) name_prof_tooltip,
                           -- 2) Responsible nurse
                           (SELECT pk_hand_off_core.get_responsibles_str(i_lang,
                                                                         i_prof,
                                                                         pk_alert_constant.g_cat_type_nurse,
                                                                         epis.id_episode,
                                                                         epis.id_first_nurse_resp,
                                                                         l_hand_off_type,
                                                                         'T')
                              FROM dual) name_nurse_tooltip,
                           pk_patient.get_pat_age(i_lang, epis.id_patient, i_prof) pat_age,
                           pk_patient.get_julian_age(i_lang, epis.id_patient) pat_age_for_order_by,
                           pk_date_utils.date_send_tsz(i_lang, epis.dt_first_obs_tstz, i_prof) dt_first_obs,
                           lpad(to_char(sd.rank), 6, '0') || sd.img_name img_transp,
                           pk_patphoto.get_pat_photo(i_lang, i_prof, epis.id_patient, epis.id_episode, epis.id_schedule) photo,
                           'N' flg_temp,
                           g_sysdate_char dt_server,
                           NULL desc_temp,
                           --grid_task
                           (SELECT pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, g.drug_presc)
                              FROM dual) desc_drug_presc,
                           pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                  i_prof,
                                                                  pk_grid.get_prioritary_task(i_lang,
                                                                                              i_prof,
                                                                                              pk_grid.get_prioritary_task(i_lang,
                                                                                                                          i_prof,
                                                                                                                          g.intervention,
                                                                                                                          g.nurse_activity,
                                                                                                                          g_domain_nurse_act,
                                                                                                                          l_profile),
                                                                                              
                                                                                              g.monitorization,
                                                                                              NULL,
                                                                                              l_profile)) desc_monit_interv_presc,
                           (SELECT pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                          i_prof,
                                                                          pk_grid.get_prioritary_task(i_lang,
                                                                                                      i_prof,
                                                                                                      g.intervention,
                                                                                                      g.nurse_activity,
                                                                                                      g_domain_nurse_act,
                                                                                                      l_profile))
                              FROM grid_task g
                             WHERE g.id_episode = epis.id_episode) desc_interv_presc,
                           (SELECT pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, g.monitorization)
                              FROM grid_task g
                             WHERE g.id_episode = epis.id_episode) desc_monitorization,
                           (SELECT pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, g.movement)
                              FROM dual) desc_movement,
                           (SELECT --pk_grid.convert_grid_task_str(i_lang, i_prof, g.analysis_d)
                             pk_grid.visit_grid_task_str(i_lang, i_prof, epis.id_visit, g_task_analysis, l_profile)
                              FROM dual) desc_analysis_req,
                           (SELECT --pk_grid.convert_grid_task_str(i_lang, i_prof, g.exam_d)
                             pk_grid.visit_grid_task_str(i_lang, i_prof, epis.id_visit, g_task_exam, l_profile)
                              FROM dual) desc_exam_req,
                           (SELECT pk_string_utils.concat_if_exists((SELECT get_grid_origin_abbrev(i_lang,
                                                                                                  i_prof,
                                                                                                  v.id_origin)
                                                                      FROM visit v
                                                                     WHERE v.id_visit = epis.id_visit),
                                                                    pk_edis_grid.get_complaint_grid(i_lang,
                                                                                                    i_prof,
                                                                                                    epis.id_episode),
                                                                    ' / ')
                              FROM dual) desc_epis_anamnesis,
                           (SELECT pk_fast_track.get_fast_track_icon(i_lang,
                                                                     i_prof,
                                                                     epis.id_episode,
                                                                     epis.id_fast_track,
                                                                     epis.id_triage_color,
                                                                     decode(epis.has_transfer,
                                                                            0,
                                                                            g_icon_ft,
                                                                            g_icon_ft_transfer),
                                                                     epis.has_transfer)
                              FROM dual) fast_track_icon,
                           decode(epis.triage_acuity, g_ft_color, g_ft_triage_white, g_ft_color) fast_track_color,
                           g_ft_status fast_track_status,
                           (SELECT pk_fast_track.get_fast_track_desc(i_lang, i_prof, epis.id_fast_track, g_desc_grid)
                              FROM dual) fast_track_desc,
                           (SELECT pk_edis_triage.get_epis_esi_level(i_lang,
                                                                     i_prof,
                                                                     epis.id_episode,
                                                                     epis.id_triage_color)
                              FROM dual) esi_level,
                           --Alexandre Santos 13-10-2010 ALERT-726 Changing and cancelling appointmentsChanging to another physician with the same specialty as the responsible physician. However, the responsible physician remains the same.
                           (SELECT pk_hand_off_api.get_resp_icons(i_lang, i_prof, epis.id_episode, l_hand_off_type)
                              FROM dual) resp_icons,
                           decode(pk_prof_follow.get_follow_episode_by_me(i_prof, epis.id_episode, epis.id_schedule),
                                  pk_alert_constant.g_no,
                                  decode(pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                                          i_prof,
                                                                                                          epis.id_episode,
                                                                                                          l_profile,
                                                                                                          l_hand_off_type,
                                                                                                          pk_alert_constant.g_yes),
                                                                      i_prof.id),
                                         -1,
                                         pk_alert_constant.g_yes,
                                         pk_alert_constant.g_no),
                                  pk_alert_constant.g_no) prof_follow_add,
                           pk_prof_follow.get_follow_episode_by_me(i_prof, epis.id_episode, epis.id_schedule) prof_follow_remove,
                           decode(l_profile,
                                  pk_alert_constant.g_flg_nurse,
                                  (SELECT pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, g.oth_exam_n)
                                     FROM dual),
                                  (SELECT pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, g.oth_exam_d)
                                     FROM dual)) desc_oth_exam_req,
                           decode(l_profile,
                                  pk_alert_constant.g_flg_nurse,
                                  (SELECT pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, g.img_exam_n)
                                     FROM dual),
                                  (SELECT pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, g.img_exam_d)
                                     FROM dual)) desc_img_exam_req,
                           get_length_of_stay_color(i_prof,
                                                    pk_edis_proc.get_los_duration_number(i_lang       => i_lang,
                                                                                         i_prof       => i_prof,
                                                                                         i_id_episode => epis.id_episode)) length_of_stay_bg_color,
                           (SELECT pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, g.opinion_state)
                              FROM dual) desc_opinion,
                           pk_opinion.get_epis_last_opinion_popup(i_lang       => i_lang,
                                                                  i_prof       => i_prof,
                                                                  i_id_episode => epis.id_episode) desc_opinion_popup,
                           get_orig_anamn_desc(i_lang, i_prof, epis.id_visit, epis.id_episode) origin_anamn_full_desc
                      FROM v_episode_act epis, sys_domain sd, room r, grid_task g
                     WHERE epis.id_software = i_prof.software
                       AND epis.id_institution = i_prof.institution
                       AND g.id_episode = epis.id_episode(+)
                          -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer do tipo EHR
                       AND epis.flg_ehr = g_flg_ehr_normal
                       AND sd.val = epis.flg_status_ei
                       AND sd.code_domain = 'EPIS_INFO.FLG_STATUS'
                       AND sd.domain_owner = pk_sysdomain.k_default_schema
                       AND sd.id_language = i_lang
                       AND epis.id_room = i_room
                       AND epis.id_room = r.id_room(+)
                    -- Pacientes referenciados por outro médico (com carta) tem prioridade sobre outros pacientes triados com a mesma cor
                     ORDER BY rank_acuity,
                              decode(pk_sysconfig.get_config('EDIS_GRID_ORIGIN_ORDER_WITHOUT_TRIAGE', i_prof),
                                     pk_alert_constant.g_yes,
                                     decode(pk_edis_triage.get_flag_no_color(i_lang, i_prof, epis.id_triage_color),
                                            'S',
                                            0,
                                            decode(pk_utils.search_table_varchar(g_tab_grid_origins,
                                                                                 (SELECT id_origin
                                                                                    FROM visit
                                                                                   WHERE id_visit = epis.id_visit)),
                                                   -1,
                                                   1,
                                                   0)),
                                     decode(pk_utils.search_table_varchar(g_tab_grid_origins,
                                                                          (SELECT id_origin
                                                                             FROM visit
                                                                            WHERE id_visit = epis.id_visit)),
                                            -1,
                                            1,
                                            0)),
                              decode(orderby_flg_letter(i_prof),
                                     pk_alert_constant.g_yes,
                                     decode(epis.triage_flg_letter, g_yes, 0, 1)),
                              epis.dt_begin_tstz_e);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_grid);
            RETURN error_handling(i_lang, 'GET_GRID_ROOM_PAT_DOC', g_error, SQLERRM, FALSE, o_error);
    END;
    --
    /**********************************************************************************************
    * Grelha para visualizar todas as salas e para cada sala todos os:
                         - pacientes (masculino)
                         - pacientes (Feminino)
                         - profissionais
                         - enfermeiros
                         - auxiliares
                         e respectivo total de pacientes (H e M) por sala, caso exista.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_grid                   cursor with all rooms
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/05/31
    **********************************************************************************************/
    FUNCTION get_grid_all_rooms
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_grid  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_adult_child sys_config.value%TYPE;
    BEGIN
        g_error       := 'GET configurations';
        l_adult_child := pk_sysconfig.get_config('ADULT_CHILD', i_prof);
        --
        g_error := 'GET CURSOR O_GRID';
        OPEN o_grid FOR
            SELECT id_room,
                   label_room,
                   desc_room,
                   label_men,
                   tot_men,
                   label_fem,
                   tot_fem,
                   tot_men + tot_fem total,
                   label_doctor,
                   tot_doctor,
                   label_nurse,
                   tot_nurse,
                   label_aux,
                   tot_aux,
                   label_tot,
                   label_prof,
                   label_all_pat
              FROM (SELECT ro.id_room,
                           pk_message.get_message(i_lang, 'EDIS_GRID_T005') label_room,
                           nvl(ro.desc_room, pk_translation.get_translation(i_lang, ro.code_room)) desc_room,
                           decode(l_adult_child,
                                  g_yes,
                                  pk_message.get_message(i_lang, 'EDIS_GRID_T052'),
                                  pk_message.get_message(i_lang, 'EDIS_GRID_T012')) label_men,
                           decode(l_adult_child,
                                  g_yes,
                                  pk_edis_proc.get_adult_child_count(i_prof, 'A', ro.id_room),
                                  pk_edis_proc.get_patient_count(i_prof, 'M', ro.id_room)) tot_men,
                           decode(l_adult_child,
                                  g_yes,
                                  pk_message.get_message(i_lang, 'EDIS_GRID_T053'),
                                  pk_message.get_message(i_lang, 'EDIS_GRID_T013')) label_fem,
                           decode(l_adult_child,
                                  g_yes,
                                  pk_edis_proc.get_adult_child_count(i_prof, 'C', ro.id_room),
                                  pk_edis_proc.get_patient_count(i_prof, 'F', ro.id_room)) tot_fem,
                           pk_message.get_message(i_lang, 'EDIS_GRID_T006') label_doctor,
                           pk_edis_proc.get_professional_count(i_prof, ro.id_room, 'D') tot_doctor,
                           pk_message.get_message(i_lang, 'EDIS_GRID_T007') label_nurse,
                           pk_edis_proc.get_professional_count(i_prof, ro.id_room, 'N') tot_nurse,
                           pk_message.get_message(i_lang, 'EDIS_GRID_T008') label_aux,
                           pk_edis_proc.get_professional_count(i_prof, ro.id_room, 'O') tot_aux,
                           pk_message.get_message(i_lang, 'EDIS_GRID_T011') label_tot,
                           pk_message.get_message(i_lang, 'EDIS_GRID_T021') label_prof,
                           pk_message.get_message(i_lang, 'EDIS_GRID_T022') label_all_pat
                      FROM room ro, dept dt, software_dept sd, department dp
                     WHERE ro.id_department = dp.id_department
                       AND ro.flg_available = g_yes
                       AND dp.id_institution = i_prof.institution
                       AND sd.id_dept = dp.id_dept
                       AND dp.id_dept = dt.id_dept
                       AND sd.id_software = i_prof.software)
             ORDER BY id_room ASC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_grid);
            RETURN error_handling(i_lang, 'GET_GRID_ALL_ROOMS', g_error, SQLERRM, FALSE, o_error);
    END;
    --
    /**********************************************************************************************
    *  Listagem gráfica de todas as salas onde para cada uma se visualiza:
                         - Total de pacientes
                         - Capacidade máxima da sala
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_grid                   cursor with all rooms
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/06/01
    **********************************************************************************************/
    FUNCTION get_chart_all_rooms
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_grid  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET CURSOR O_GRID';
        OPEN o_grid FOR
            SELECT id_room, desc_room, room_capacity, total
              FROM (SELECT ro.id_room,
                           nvl(ro.desc_room, pk_translation.get_translation(i_lang, ro.code_room)) desc_room,
                           ro.capacity room_capacity,
                           (SELECT COUNT(0)
                              FROM v_episode_act epis
                             WHERE epis.id_room = ro.id_room
                               AND epis.id_software = i_prof.software) total
                      FROM room ro, department dp, software_dept sd
                     WHERE ro.id_department = dp.id_department
                       AND ro.flg_available = g_yes
                       AND dp.id_institution = i_prof.institution
                       AND sd.id_dept = dp.id_dept
                       AND sd.id_software = i_prof.software)
             ORDER BY desc_room ASC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_grid);
            RETURN error_handling(i_lang, 'GET_CHART_ALL_ROOMS', g_error, SQLERRM, FALSE, o_error);
    END;
    --
    /**********************************************************************************************
    *  Listagem gráfica para um dado profissional de todos os seus pacientes
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_grid                   cursor with all patients
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/06/22
    **********************************************************************************************/
    FUNCTION get_chart_my_pat_doc
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_grid  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_cat_type         category.flg_type%TYPE;
        l_tab_triage_types table_number;
        l_hand_off_type    sys_config.value%TYPE;
        --
        l_value_los sys_config.value%TYPE;
        --
        CURSOR c_flg_type IS
            SELECT cat.flg_type
              FROM prof_cat prc, category cat
             WHERE prc.id_professional = i_prof.id
               AND prc.id_institution = i_prof.institution
               AND cat.id_category = prc.id_category
               AND flg_available = g_yes
               AND flg_prof = g_cat_is_prof;
    
        l_config_origin CONSTANT sys_config.id_sys_config%TYPE := 'GRID_ORIGINS';
    
    BEGIN
        -- Qual a categoria do profissional
        g_error := ' OPEN C_FLG_TYPE';
        OPEN c_flg_type;
        FETCH c_flg_type
            INTO l_cat_type;
        CLOSE c_flg_type;
        --
        g_error := 'GET CONFIGURATIONS';
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
        --
        g_error     := 'GET ' || pk_edis_grid.g_syscfg_los;
        l_value_los := pk_sysconfig.get_config(i_code_cf => pk_edis_grid.g_syscfg_los, i_prof => i_prof);
        --
        g_error            := 'GET TRIAGE TYPES';
        l_tab_triage_types := pk_edis_triage.tf_get_inst_triag_types(i_prof.institution);
    
        g_grid_origins     := pk_sysconfig.get_config(l_config_origin, i_prof);
        g_tab_grid_origins := pk_utils.str_split_l(g_grid_origins, '|');
    
        --
        g_error := 'GET CURSOR O_GRID';
        OPEN o_grid FOR
            SELECT acuity,
                   color_text,
                   rank_acuity,
                   id_episode,
                   dt_begin,
                   date_send,
                   id_patient,
                   dt_first_obs,
                   prof_follow_add,
                   prof_follow_remove,
                   rownum rank_triage
              FROM (SELECT epis.triage_acuity acuity,
                           epis.triage_color_text color_text,
                           epis.triage_rank_acuity rank_acuity,
                           epis.id_episode,
                           pk_date_utils.date_send_tsz(i_lang, epis.dt_begin_tstz_e, i_prof) dt_begin,
                           pk_date_utils.get_conversion_date_tsz(i_lang,
                                                                 epis.dt_begin_tstz_e,
                                                                 i_prof,
                                                                 tt.id_triage_units) date_send,
                           epis.id_patient,
                           pk_date_utils.date_send_tsz(i_lang, epis.dt_first_obs_tstz, i_prof) dt_first_obs, -- se a cor fica atracejado ou não
                           pk_alert_constant.g_no prof_follow_add,
                           pk_prof_follow.get_follow_episode_by_me(i_prof, epis.id_episode, epis.id_schedule) prof_follow_remove
                      FROM v_episode_act epis, triage_type tt, triage_color tco
                     WHERE epis.id_software = i_prof.software
                       AND epis.id_institution = i_prof.institution
                          -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer do tipo EHR
                       AND epis.flg_ehr = g_flg_ehr_normal
                          --AND i_prof.id = decode(l_cat_type, g_cat_doctor, epis.id_professional, epis.id_first_nurse_resp)
                          -- José Brito 19/10/2009 ALERT-39320 Responsible physicians not registered in EPIS_INFO must
                          --                                   have the patient available in the main grid.
                       AND (pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                             i_prof,
                                                                                             epis.id_episode,
                                                                                             l_cat_type,
                                                                                             l_hand_off_type,
                                                                                             pk_alert_constant.g_yes),
                                                         i_prof.id) != -1 OR
                           (pk_prof_follow.get_follow_episode_by_me(i_prof, epis.id_episode, epis.id_schedule) =
                           pk_alert_constant.g_yes))
                       AND epis.id_triage_color = tco.id_triage_color
                       AND tco.flg_show = pk_alert_constant.g_yes
                       AND tt.id_triage_type = tco.id_triage_type
                       AND tt.id_triage_type IN (SELECT *
                                                   FROM TABLE(l_tab_triage_types))
                    -- Pacientes referenciados por outro médico (com carta) tem prioridade sobre outros pacientes triados com a mesma cor
                     ORDER BY decode(l_value_los,
                                     pk_alert_constant.g_yes,
                                     pk_edis_grid.get_los(i_lang, epis.dt_begin_tstz_e),
                                     0) DESC,
                              decode(l_value_los, pk_alert_constant.g_no, rank_acuity, 0),
                              decode(pk_utils.search_table_varchar(g_tab_grid_origins,
                                                                   (SELECT id_origin
                                                                      FROM visit
                                                                     WHERE id_visit = epis.id_visit)),
                                     -1,
                                     1,
                                     0),
                              decode(orderby_flg_letter(i_prof),
                                     pk_alert_constant.g_yes,
                                     decode(epis.triage_flg_letter, g_yes, 0, 1)),
                              epis.dt_begin_tstz_e);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_grid);
            RETURN error_handling(i_lang, 'GET_CHART_MY_PAT_DOC', g_error, SQLERRM, FALSE, o_error);
    END;
    --
    /**********************************************************************************************
    *  Listagem gráfica de todos os pacientes alocados ás salas de um médico
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_grid                   cursor with all patients
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/06/19
    **********************************************************************************************/
    FUNCTION get_chart_all_pat_doc
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_grid  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_prof_template IS
            SELECT ppt.id_profile_template
              FROM prof_profile_template ppt, profile_template pt
             WHERE ppt.id_profile_template = pt.id_profile_template
               AND pt.id_software = i_prof.software
               AND ppt.id_professional = i_prof.id
               AND ppt.id_software = i_prof.software
               AND ppt.id_institution = i_prof.institution;
        --
        l_value_los sys_config.value%TYPE;
        --
        l_prof_profile profile_template.id_profile_template%TYPE;
        l_aux_grid     VARCHAR2(1 CHAR);
        l_config_grid_aux CONSTANT sys_config.id_sys_config%TYPE := 'SHOW_ALL_PATIENTS_AUX_GRID';
        l_show_all         sys_config.value%TYPE;
        l_tab_triage_types table_number;
    
        l_hand_off_type sys_config.value%TYPE;
        l_prof_cat      VARCHAR2(0050);
        l_config_origin CONSTANT sys_config.id_sys_config%TYPE := 'GRID_ORIGINS';
    
    BEGIN
        g_error := 'OPEN c_prof_template';
        OPEN c_prof_template;
        FETCH c_prof_template
            INTO l_prof_profile;
        CLOSE c_prof_template;
        --
        g_error    := 'CHECK ANCILLARY CONFIGURATION';
        l_show_all := pk_sysconfig.get_config(l_config_grid_aux, i_prof);
    
        IF l_prof_profile = g_profile_edis_aux
           AND l_show_all = pk_alert_constant.g_no
        THEN
            l_aux_grid := pk_alert_constant.g_yes;
        ELSE
            l_aux_grid := pk_alert_constant.g_no;
        END IF;
    
        l_prof_cat := pk_edis_list.get_prof_cat(i_prof);
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
    
        g_error     := 'GET ' || pk_edis_grid.g_syscfg_los;
        l_value_los := pk_sysconfig.get_config(i_code_cf => pk_edis_grid.g_syscfg_los, i_prof => i_prof);
        --
        g_error            := 'GET TRIAGE TYPES';
        l_tab_triage_types := pk_edis_triage.tf_get_inst_triag_types(i_prof.institution);
    
        g_grid_origins     := pk_sysconfig.get_config(l_config_origin, i_prof);
        g_tab_grid_origins := pk_utils.str_split_l(g_grid_origins, '|');
    
        g_error := 'GET CURSOR O_GRID';
        OPEN o_grid FOR
            SELECT acuity,
                   color_text,
                   rank_acuity,
                   id_episode,
                   dt_begin,
                   date_send,
                   id_patient,
                   dt_first_obs,
                   prof_follow_add,
                   prof_follow_remove,
                   rownum rank_triage
              FROM (SELECT epis.triage_acuity acuity,
                           epis.triage_color_text color_text,
                           epis.triage_rank_acuity rank_acuity,
                           epis.id_episode,
                           pk_date_utils.date_send_tsz(i_lang, epis.dt_begin_tstz_e, i_prof) dt_begin,
                           pk_date_utils.get_conversion_date_tsz(i_lang,
                                                                 epis.dt_begin_tstz_e,
                                                                 i_prof,
                                                                 tt.id_triage_units) date_send,
                           epis.id_patient,
                           pk_date_utils.date_send_tsz(i_lang, epis.dt_first_obs_tstz, i_prof) dt_first_obs, -- se a cor fica atracejado ou não
                           decode(pk_prof_follow.get_follow_episode_by_me(i_prof, epis.id_episode, epis.id_schedule),
                                  pk_alert_constant.g_no,
                                  decode(pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                                          i_prof,
                                                                                                          epis.id_episode,
                                                                                                          l_prof_cat,
                                                                                                          l_hand_off_type,
                                                                                                          pk_alert_constant.g_yes),
                                                                      i_prof.id),
                                         -1,
                                         pk_alert_constant.g_yes,
                                         pk_alert_constant.g_no),
                                  pk_alert_constant.g_no) prof_follow_add,
                           pk_prof_follow.get_follow_episode_by_me(i_prof, epis.id_episode, epis.id_schedule) prof_follow_remove
                      FROM v_episode_act epis, institution i, triage_type tt, triage_color tco
                     WHERE epis.id_institution = i_prof.institution
                          --José Brito 10/07/2008 Mostrar episódios do EDIS/UBU no ALERT® Triage
                       AND epis.id_software = decode(i_prof.software,
                                                     g_soft_triage,
                                                     decode(i.flg_type, g_inst_type_h, g_soft_edis, g_soft_ubu),
                                                     i_prof.software)
                       AND epis.id_institution = i.id_institution
                          -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer do tipo EHR
                       AND epis.flg_ehr = g_flg_ehr_normal
                       AND tco.id_triage_color = epis.id_triage_color
                       AND tt.id_triage_type = tco.id_triage_type
                       AND tco.flg_show = pk_alert_constant.g_yes
                       AND tt.id_triage_type IN (SELECT *
                                                   FROM TABLE(l_tab_triage_types))
                       AND decode(l_aux_grid,
                                  pk_alert_constant.g_yes,
                                  (SELECT COUNT(0)
                                     FROM grid_task gt
                                    WHERE gt.id_episode = epis.id_episode
                                      AND nvl(gt.movement, gt.harvest) IS NOT NULL),
                                  1) = 1
                    -- Pacientes referenciados por outro médico (com carta) tem prioridade sobre outros pacientes triados com a mesma cor
                     ORDER BY decode(l_value_los,
                                     pk_alert_constant.g_yes,
                                     pk_edis_grid.get_los(i_lang, epis.dt_begin_tstz_e),
                                     0) DESC,
                              decode(l_value_los, pk_alert_constant.g_no, rank_acuity, 0),
                              decode(pk_utils.search_table_varchar(g_tab_grid_origins,
                                                                   (SELECT id_origin
                                                                      FROM visit
                                                                     WHERE id_visit = epis.id_visit)),
                                     -1,
                                     1,
                                     0),
                              decode(orderby_flg_letter(i_prof),
                                     pk_alert_constant.g_yes,
                                     decode(epis.triage_flg_letter, g_yes, 0, 1)),
                              epis.dt_begin_tstz_e);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_grid);
            RETURN error_handling(i_lang, 'GET_CHART_ALL_PAT_DOC', g_error, SQLERRM, FALSE, o_error);
    END;
    --
    /**********************************************************************************************
    * Listagem gráfica de todos os pacientes alocados numa sala
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_room                   room id
    * @param o_grid                   cursor with all patients
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/06/19
    **********************************************************************************************/
    FUNCTION get_chart_room_pat_doc
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_room  IN room.id_room%TYPE,
        o_grid  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_hand_off_type sys_config.value%TYPE;
        l_prof_cat      VARCHAR2(0050);
        l_config_origin CONSTANT sys_config.id_sys_config%TYPE := 'GRID_ORIGINS';
    
    BEGIN
        l_prof_cat := pk_edis_list.get_prof_cat(i_prof);
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
        g_grid_origins     := pk_sysconfig.get_config(l_config_origin, i_prof);
        g_tab_grid_origins := pk_utils.str_split_l(g_grid_origins, '|');
    
        g_error := 'GET CURSOR O_GRID';
        OPEN o_grid FOR
            SELECT acuity,
                   color_text,
                   rank_acuity,
                   id_episode,
                   dt_begin,
                   date_send,
                   id_patient,
                   dt_first_obs,
                   prof_follow_add,
                   prof_follow_remove,
                   rownum rank_triage
              FROM (SELECT epis.triage_acuity acuity,
                           epis.triage_color_text color_text,
                           epis.triage_rank_acuity rank_acuity,
                           epis.id_episode,
                           pk_date_utils.date_send_tsz(i_lang, epis.dt_begin_tstz_e, i_prof) dt_begin,
                           pk_date_utils.get_conversion_date_tsz(i_lang,
                                                                 epis.dt_begin_tstz_e,
                                                                 i_prof,
                                                                 tt.id_triage_units) date_send,
                           epis.id_patient,
                           pk_date_utils.date_send_tsz(i_lang, epis.dt_first_obs_tstz, i_prof) dt_first_obs, -- se a cor fica atracejado ou não
                           decode(pk_prof_follow.get_follow_episode_by_me(i_prof, epis.id_episode, epis.id_schedule),
                                  pk_alert_constant.g_no,
                                  decode(pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                                          i_prof,
                                                                                                          epis.id_episode,
                                                                                                          l_prof_cat,
                                                                                                          l_hand_off_type,
                                                                                                          pk_alert_constant.g_yes),
                                                                      i_prof.id),
                                         -1,
                                         pk_alert_constant.g_yes,
                                         pk_alert_constant.g_no),
                                  pk_alert_constant.g_no) prof_follow_add,
                           pk_prof_follow.get_follow_episode_by_me(i_prof, epis.id_episode, epis.id_schedule) prof_follow_remove
                      FROM v_episode_act epis, triage_type tt, triage_color tco
                     WHERE epis.id_software = i_prof.software
                       AND epis.id_institution = i_prof.institution
                          -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer do tipo EHR
                       AND epis.flg_ehr = g_flg_ehr_normal
                       AND epis.id_room = i_room
                       AND tco.id_triage_color = epis.id_triage_color
                       AND tt.id_triage_type = tco.id_triage_type
                       AND tt.id_triage_type = pk_edis_triage.get_triage_type(i_lang, i_prof, epis.id_episode)
                    -- Pacientes referenciados por outro médico (com carta) tem prioridade sobre outros pacientes triados com a mesma cor
                     ORDER BY rank_acuity,
                              decode(pk_utils.search_table_varchar(g_tab_grid_origins,
                                                                   (SELECT id_origin
                                                                      FROM visit
                                                                     WHERE id_visit = epis.id_visit)),
                                     -1,
                                     1,
                                     0),
                              decode(orderby_flg_letter(i_prof),
                                     pk_alert_constant.g_yes,
                                     decode(epis.triage_flg_letter, g_yes, 0, 1)),
                              epis.dt_begin_tstz_e);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_grid);
            RETURN error_handling(i_lang, 'GET_CHART_ROOM_PAT_DOC', g_error, SQLERRM, FALSE, o_error);
    END;
    --
    /**********************************************************************************************
    * Grelha do enfermeiro para visualizar os seus pacientes
      Nesta grelha visualizam-se todos os episódios : - c/ ou s/ alta médica, sem alta administrativa ou com alta administrativa se ainda tiverem workflow pendente.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_grid                   cursor with all patients
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/09/12
    **********************************************************************************************/
    FUNCTION get_grid_my_pat_nurse
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_grid           OUT pk_types.cursor_type,
        o_flg_disch_pend OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_hand_off_type sys_config.value%TYPE;
        l_num           NUMBER;
    
        l_msg_edis_grid_m003 sys_message.desc_message%TYPE;
        l_profile            VARCHAR2(0050);
        l_config_show_resident CONSTANT sys_config.id_sys_config%TYPE := 'GRIDS_SHOW_RESIDENT';
        l_show_resident_physician sys_config.value%TYPE;
        l_show_only_epis_resp     sys_config.value%TYPE;
    
        l_exception EXCEPTION;
        l_error t_error_out;
        l_config_origin CONSTANT sys_config.id_sys_config%TYPE := 'GRID_ORIGINS';
    
    BEGIN
        g_error        := 'GET DATES';
        g_sysdate_tstz := current_timestamp;
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
    
        g_error := 'GET CONFIGURATIONS';
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
        l_msg_edis_grid_m003      := pk_message.get_message(i_lang, 'EDIS_GRID_M003');
        l_profile                 := pk_edis_list.get_prof_cat(i_prof);
        l_show_resident_physician := pk_sysconfig.get_config(i_code_cf => l_config_show_resident, i_prof => i_prof);
        l_show_only_epis_resp     := pk_sysconfig.get_config(i_code_cf => pk_hand_off_core.g_config_show_only_epis_resp,
                                                             i_prof    => i_prof);
        g_grid_origins            := pk_sysconfig.get_config(l_config_origin, i_prof);
        g_tab_grid_origins        := pk_utils.str_split_l(g_grid_origins, '|');
    
        g_error := 'GET CURSOR O_GRID';
        OPEN o_grid FOR
            SELECT acuity,
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
                   pat_age,
                   pat_age_for_order_by,
                   dt_first_obs,
                   img_transp,
                   care_stage,
                   care_stage_rank,
                   photo,
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
                   origin_anamn_full_desc
              FROM (SELECT epis.triage_acuity acuity,
                           epis.triage_color_text color_text,
                           epis.triage_rank_acuity rank_acuity,
                           decode(epis.triage_flg_letter, g_yes, l_msg_edis_grid_m003) acuity_desc,
                           epis.id_episode,
                           pk_date_utils.date_send_tsz(i_lang, epis.dt_begin_tstz_e, i_prof) dt_begin,
                           pk_date_utils.date_char_hour_tsz(i_lang,
                                                            epis.dt_begin_tstz_e,
                                                            i_prof.institution,
                                                            i_prof.software) dt_efectiv,
                           pk_date_utils.diff_timestamp(g_sysdate_tstz, epis.dt_begin_tstz_e) order_time, --ET 2007/03/01
                           pk_edis_proc.get_los_duration(i_lang       => i_lang,
                                                         i_prof       => i_prof,
                                                         i_id_episode => epis.id_episode) date_send, -- Length of stay
                           pk_edis_proc.get_formatted_string_for_sort(i_lang    => i_lang,
                                                                      i_prof    => i_prof,
                                                                      i_type    => pk_edis_proc.g_sort_type_los,
                                                                      i_episode => epis.id_episode) date_send_sort,
                           nvl(nvl(r.desc_room_abbreviation,
                                   pk_translation.get_translation_dtchk(i_lang, 'ROOM.CODE_ABBREVIATION' || epis.id_room)),
                               nvl(r.desc_room,
                                   pk_translation.get_translation_dtchk(i_lang, 'ROOM.CODE_ROOM.' || epis.id_room))) desc_room,
                           epis.id_patient,
                           pk_patient.get_pat_name(i_lang, i_prof, epis.id_patient, epis.id_episode) name_pat,
                           -- ALERT-102882 Patient name used for sorting
                           pk_patient.get_pat_name_to_sort(i_lang, i_prof, epis.id_patient, epis.id_episode, NULL) name_pat_sort,
                           pk_adt.get_pat_non_disc_options(i_lang, i_prof, epis.id_patient) pat_ndo,
                           pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, epis.id_patient) pat_nd_icon,
                           (SELECT pk_patient.get_gender(i_lang, gender) gender
                              FROM patient
                             WHERE id_patient = epis.id_patient) gender,
                           -- Display number of responsible PHYSICIANS for the episode,
                           -- if institution is using the multiple hand-off mechanism,
                           -- along with the name of the main responsible for the patient.
                           (SELECT pk_hand_off_core.get_responsibles_str(i_lang,
                                                                         i_prof,
                                                                         pk_alert_constant.g_cat_type_doc,
                                                                         epis.id_episode,
                                                                         epis.id_professional,
                                                                         l_hand_off_type,
                                                                         'G',
                                                                         l_show_only_epis_resp)
                              FROM dual) name_prof,
                           pk_prof_utils.get_nickname(i_lang, epis.id_first_nurse_resp) name_nurse,
                           -- Team name or Resident physician(s)
                           decode(l_show_resident_physician,
                                  pk_alert_constant.g_yes,
                                  (SELECT pk_hand_off_core.get_resp_by_type_grid_str(i_lang,
                                                                                     i_prof,
                                                                                     epis.id_episode,
                                                                                     l_hand_off_type,
                                                                                     pk_hand_off_core.g_resident,
                                                                                     'G')
                                     FROM dual),
                                  (SELECT pk_prof_teams.get_prof_current_team(i_lang,
                                                                              i_prof,
                                                                              epis.id_department,
                                                                              epis.id_software,
                                                                              epis.id_professional,
                                                                              epis.id_first_nurse_resp)
                                     FROM dual)) prof_team,
                           -- Display text in tooltips
                           -- 1) Responsible physician(s)
                           (SELECT pk_hand_off_core.get_responsibles_str(i_lang,
                                                                         i_prof,
                                                                         pk_alert_constant.g_cat_type_doc,
                                                                         epis.id_episode,
                                                                         epis.id_professional,
                                                                         l_hand_off_type,
                                                                         'T')
                              FROM dual) name_prof_tooltip,
                           -- 2) Responsible nurse
                           (SELECT pk_hand_off_core.get_responsibles_str(i_lang,
                                                                         i_prof,
                                                                         pk_alert_constant.g_cat_type_nurse,
                                                                         epis.id_episode,
                                                                         epis.id_first_nurse_resp,
                                                                         l_hand_off_type,
                                                                         'T')
                              FROM dual) name_nurse_tooltip,
                           -- 3) Responsible team
                           (SELECT pk_hand_off_core.get_team_str(i_lang,
                                                                 i_prof,
                                                                 epis.id_department,
                                                                 epis.id_software,
                                                                 epis.id_professional,
                                                                 epis.id_first_nurse_resp,
                                                                 l_hand_off_type,
                                                                 NULL)
                              FROM dual) prof_team_tooltip,
                           pk_patient.get_pat_age(i_lang, epis.id_patient, i_prof) pat_age,
                           pk_edis_proc.get_formatted_string_for_sort(i_lang    => i_lang,
                                                                      i_prof    => i_prof,
                                                                      i_type    => pk_edis_proc.g_sort_type_age,
                                                                      i_episode => epis.id_episode) pat_age_for_order_by,
                           pk_date_utils.date_send_tsz(i_lang, epis.dt_first_obs_tstz, i_prof) dt_first_obs,
                           lpad(to_char(sd.rank), 6, '0') || sd.img_name img_transp,
                           pk_patient_tracking.get_care_stage_grid_status(i_lang,
                                                                          i_prof,
                                                                          epis.id_episode,
                                                                          g_sysdate_char) care_stage,
                           pk_patient_tracking.get_current_state_rank(i_lang, i_prof, epis.id_episode) care_stage_rank,
                           pk_patphoto.get_pat_photo(i_lang, i_prof, epis.id_patient, epis.id_episode, epis.id_schedule) photo,
                           'N' flg_temp,
                           g_sysdate_char dt_server,
                           NULL desc_temp,
                           --grid_task
                           (SELECT pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, g.drug_presc)
                              FROM dual) desc_drug_presc,
                           pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                  i_prof,
                                                                  pk_grid.get_prioritary_task(i_lang,
                                                                                              i_prof,
                                                                                              pk_grid.get_prioritary_task(i_lang,
                                                                                                                          i_prof,
                                                                                                                          g.intervention,
                                                                                                                          g.nurse_activity,
                                                                                                                          g_domain_nurse_act,
                                                                                                                          l_profile),
                                                                                              
                                                                                              g.monitorization,
                                                                                              NULL,
                                                                                              l_profile)) desc_monit_interv_presc,
                           (SELECT pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, g.movement)
                              FROM dual) desc_movement,
                           (SELECT --pk_grid.convert_grid_task_str(i_lang, i_prof, g.analysis_n)
                             pk_grid.visit_grid_task_str(i_lang, i_prof, epis.id_visit, g_task_analysis, l_profile)
                              FROM dual) desc_analysis_req,
                           (SELECT --pk_grid.convert_grid_task_str(i_lang, i_prof, g.exam_n)
                             pk_grid.visit_grid_task_str(i_lang, i_prof, epis.id_visit, g_task_exam, l_profile)
                              FROM dual) desc_exam_req,
                           (SELECT pk_string_utils.concat_if_exists((SELECT get_grid_origin_abbrev(i_lang,
                                                                                                  i_prof,
                                                                                                  v.id_origin)
                                                                      FROM visit v
                                                                     WHERE v.id_visit = epis.id_visit),
                                                                    pk_edis_grid.get_complaint_grid(i_lang,
                                                                                                    i_prof,
                                                                                                    epis.id_episode),
                                                                    ' / ')
                              FROM dual) desc_epis_anamnesis,
                           -- odete monteiro 8/11/2007 nova coluna de alta clinica pendente
                           (SELECT pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, g.discharge_pend)
                              FROM dual) desc_disch_pend_time,
                           (SELECT pk_date_utils.date_send_tsz(i_lang, nvl(d.dt_med_tstz, d.dt_pend_tstz), i_prof)
                              FROM discharge d
                             WHERE d.flg_status = g_discharge_flg_status_pend
                               AND d.id_episode = epis.id_episode
                               AND rownum < 2) disch_pend_time,
                           -- José Brito 22/04/2008 Devolver FLG_CANCEL que indica se o episódio é temporário e se pode ser cancelado
                           pk_visit.check_flg_cancel(i_lang, i_prof, epis.id_episode) flg_cancel,
                           (SELECT pk_fast_track.get_fast_track_icon(i_lang,
                                                                     i_prof,
                                                                     epis.id_episode,
                                                                     epis.id_fast_track,
                                                                     epis.id_triage_color,
                                                                     decode(epis.has_transfer,
                                                                            0,
                                                                            g_icon_ft,
                                                                            g_icon_ft_transfer),
                                                                     epis.has_transfer)
                              FROM dual) fast_track_icon,
                           decode(epis.triage_acuity, g_ft_color, g_ft_triage_white, g_ft_color) fast_track_color,
                           g_ft_status fast_track_status,
                           (SELECT pk_fast_track.get_fast_track_desc(i_lang, i_prof, epis.id_fast_track, g_desc_grid)
                              FROM dual) fast_track_desc,
                           (SELECT pk_edis_triage.get_epis_esi_level(i_lang,
                                                                     i_prof,
                                                                     epis.id_episode,
                                                                     epis.id_triage_color)
                              FROM dual) esi_level,
                           --Alexandre Santos 13-10-2010 ALERT-726 Changing and cancelling appointmentsChanging to another physician with the same specialty as the responsible physician. However, the responsible physician remains the same.
                           (SELECT pk_hand_off_api.get_resp_icons(i_lang, i_prof, epis.id_episode, l_hand_off_type)
                              FROM dual) resp_icons,
                           pk_alert_constant.g_no prof_follow_add,
                           pk_prof_follow.get_follow_episode_by_me(i_prof, epis.id_episode, epis.id_schedule) prof_follow_remove,
                           --Gisela Couto 04-09-2014  ALERT-284142 Major incident icon
                           pk_adt_core.check_bulk_admission_episode(i_lang       => i_lang,
                                                                    i_prof       => i_prof,
                                                                    i_id_episode => epis.id_episode) pat_major_inc_icon,
                           
                           decode(l_profile,
                                  pk_alert_constant.g_flg_nurse,
                                  (SELECT pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, g.oth_exam_n)
                                     FROM dual),
                                  (SELECT pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, g.oth_exam_d)
                                     FROM dual)) desc_oth_exam_req,
                           decode(l_profile,
                                  pk_alert_constant.g_flg_nurse,
                                  (SELECT pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, g.img_exam_n)
                                     FROM dual),
                                  (SELECT pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, g.img_exam_d)
                                     FROM dual)) desc_img_exam_req,
                           get_length_of_stay_color(i_prof,
                                                    pk_edis_proc.get_los_duration_number(i_lang       => i_lang,
                                                                                         i_prof       => i_prof,
                                                                                         i_id_episode => epis.id_episode)) length_of_stay_bg_color,
                           (SELECT pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, g.opinion_state)
                              FROM dual) desc_opinion,
                           pk_opinion.get_epis_last_opinion_popup(i_lang       => i_lang,
                                                                  i_prof       => i_prof,
                                                                  i_id_episode => epis.id_episode) desc_opinion_popup,
                           get_orig_anamn_desc(i_lang, i_prof, epis.id_visit, epis.id_episode) origin_anamn_full_desc
                      FROM v_episode_act epis, sys_domain sd, room r, grid_task g
                     WHERE epis.id_software = i_prof.software
                       AND epis.id_institution = i_prof.institution
                       AND g.id_episode(+) = epis.id_episode
                          -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer do tipo EHR
                       AND epis.flg_ehr = g_flg_ehr_normal
                       AND (i_prof.id = epis.id_first_nurse_resp OR
                           (pk_prof_follow.get_follow_episode_by_me(i_prof, epis.id_episode, epis.id_schedule) =
                           pk_alert_constant.g_yes))
                       AND sd.val = epis.flg_status_ei
                       AND sd.domain_owner = pk_sysdomain.k_default_schema
                       AND sd.code_domain = 'EPIS_INFO.FLG_STATUS'
                       AND sd.id_language = i_lang
                       AND epis.id_room = r.id_room(+)
                    -- Pacientes referenciados por outro médico (com carta) tem prioridade sobre outros pacientes triados com a mesma cor
                     ORDER BY rank_acuity,
                              decode(pk_sysconfig.get_config('EDIS_GRID_ORIGIN_ORDER_WITHOUT_TRIAGE', i_prof),
                                     pk_alert_constant.g_yes,
                                     decode(pk_edis_triage.get_flag_no_color(i_lang, i_prof, epis.id_triage_color),
                                            'S',
                                            0,
                                            decode(pk_utils.search_table_varchar(g_tab_grid_origins,
                                                                                 (SELECT id_origin
                                                                                    FROM visit
                                                                                   WHERE id_visit = epis.id_visit)),
                                                   -1,
                                                   1,
                                                   0)),
                                     decode(pk_utils.search_table_varchar(g_tab_grid_origins,
                                                                          (SELECT id_origin
                                                                             FROM visit
                                                                            WHERE id_visit = epis.id_visit)),
                                            -1,
                                            1,
                                            0)),
                              decode(orderby_flg_letter(i_prof),
                                     pk_alert_constant.g_yes,
                                     decode(epis.triage_flg_letter, g_yes, 0, 1)),
                              epis.dt_begin_tstz_e);
    
        o_flg_disch_pend := 'N';
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_types.open_my_cursor(o_grid);
            RETURN error_handling(i_lang,
                                  'GET_GRID_MY_PAT_NURSE',
                                  g_error || ' / ' || l_error.err_desc,
                                  SQLERRM,
                                  FALSE,
                                  o_error);
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_grid);
            RETURN error_handling(i_lang, 'GET_GRID_MY_PAT_NURSE', g_error, SQLERRM, FALSE, o_error);
    END;
    --
    /**********************************************************************************************
    * Grelha do auxiliar para visualizar os seus pacientes
      Nesta grelha visualizam-se todos os episódios : - c/ ou s/ alta médica, sem alta administrativa ou com alta administrativa se ainda tiverem workflow pendente.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_grid                   cursor with all patients
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/10/02
    **********************************************************************************************/
    FUNCTION get_grid_all_pat_aux
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_grid  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_msg_edis_grid_m003 sys_message.desc_message%TYPE;
        l_profile            VARCHAR2(0050);
    
        l_show_all        sys_config.value%TYPE;
        l_id_software_inp software.id_software%TYPE;
        l_show_inp_epis   sys_config.value%TYPE;
    
        l_order_by VARCHAR2(1);
    
    BEGIN
        g_error := 'GET DATES';
        pk_alertlog.log_debug(g_error);
        g_sysdate_tstz := current_timestamp;
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
    
        g_error := 'GET CONFIGURATIONS';
        pk_alertlog.log_debug(g_error);
        l_show_all           := pk_sysconfig.get_config(g_config_grid_aux, i_prof);
        l_id_software_inp    := pk_sysconfig.get_config(g_config_soft_inp, i_prof);
        l_show_inp_epis      := pk_sysconfig.get_config(g_config_show_inp_epis, i_prof);
        l_msg_edis_grid_m003 := pk_message.get_message(i_lang, 'EDIS_GRID_M003');
        l_profile            := pk_edis_list.get_prof_cat(i_prof);
        l_order_by           := orderby_flg_letter(i_prof);
        --
        g_error := 'GET CURSOR O_GRID';
        pk_alertlog.log_debug(g_error);
        OPEN o_grid FOR
            SELECT epis.triage_acuity acuity,
                   epis.triage_color_text color_text,
                   epis.triage_rank_acuity rank_acuity,
                   decode(epis.triage_flg_letter, g_yes, l_msg_edis_grid_m003) acuity_desc,
                   epis.id_episode,
                   pk_date_utils.date_send_tsz(i_lang, epis.dt_begin_tstz_e, i_prof) dt_begin,
                   pk_date_utils.date_char_hour_tsz(i_lang, epis.dt_begin_tstz_e, i_prof.institution, i_prof.software) dt_efectiv,
                   pk_date_utils.diff_timestamp(g_sysdate_tstz, epis.dt_begin_tstz_e) order_time,
                   pk_edis_proc.get_los_duration(i_lang => i_lang, i_prof => i_prof, i_id_episode => epis.id_episode) date_send, -- Length of stay
                   pk_edis_proc.get_formatted_string_for_sort(i_lang    => i_lang,
                                                              i_prof    => i_prof,
                                                              i_type    => pk_edis_proc.g_sort_type_los,
                                                              i_episode => epis.id_episode) date_send_sort,
                   nvl(nvl(r.desc_room_abbreviation,
                           pk_translation.get_translation(i_lang, 'ROOM.CODE_ABBREVIATION.' || epis.id_room)),
                       nvl(r.desc_room, pk_translation.get_translation(i_lang, 'ROOM.CODE_ROOM.' || epis.id_room))) desc_room,
                   epis.id_patient,
                   pk_patient.get_pat_name(i_lang, i_prof, epis.id_patient, epis.id_episode) name_pat,
                   -- ALERT-102882 Patient name used for sorting
                   pk_patient.get_pat_name_to_sort(i_lang, i_prof, epis.id_patient, epis.id_episode, NULL) name_pat_sort,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, epis.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, epis.id_patient) pat_nd_icon,
                   (SELECT pk_patient.get_gender(i_lang, gender) gender
                      FROM patient
                     WHERE id_patient = epis.id_patient) gender,
                   pk_prof_utils.get_nickname(i_lang, epis.id_professional) name_prof,
                   pk_prof_utils.get_nickname(i_lang, epis.id_first_nurse_resp) name_nurse,
                   pk_patient.get_pat_age(i_lang, epis.id_patient, i_prof) pat_age,
                   pk_edis_proc.get_formatted_string_for_sort(i_lang    => i_lang,
                                                              i_prof    => i_prof,
                                                              i_type    => pk_edis_proc.g_sort_type_age,
                                                              i_episode => epis.id_episode) pat_age_for_order_by,
                   pk_date_utils.date_send_tsz(i_lang, epis.dt_first_obs_tstz, i_prof) dt_first_obs,
                   lpad(to_char(sd.rank), 6, '0') || sd.img_name img_transp,
                   pk_patphoto.get_pat_photo(i_lang, i_prof, epis.id_patient, epis.id_episode, epis.id_schedule) photo,
                   'N' flg_temp,
                   g_sysdate_char dt_server,
                   g.hemo_req,
                   NULL desc_temp,
                   --grid_task
                   (SELECT pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, g.movement)
                      FROM dual) desc_movement,
                   (SELECT --pk_grid.convert_grid_task_str(i_lang, i_prof, g.harvest)
                     pk_grid.visit_grid_task_str(i_lang, i_prof, epis.id_visit, g_task_harvest, l_profile)
                      FROM dual) desc_harvest,
                   (SELECT pk_grid.convert_grid_task_str(i_lang, i_prof, g.drug_transp)
                      FROM dual) desc_drug_transp,
                   pk_supplies_api_db.get_epis_max_supply_delay(i_lang, i_prof, epis.id_patient) desc_supplies,
                   (SELECT pk_fast_track.get_fast_track_icon(i_lang,
                                                             i_prof,
                                                             epis.id_episode,
                                                             epis.id_fast_track,
                                                             epis.id_triage_color,
                                                             decode(epis.has_transfer, 0, g_icon_ft, g_icon_ft_transfer),
                                                             epis.has_transfer)
                      FROM dual) fast_track_icon,
                   decode(epis.triage_acuity, g_ft_color, g_ft_triage_white, g_ft_color) fast_track_color,
                   g_ft_status fast_track_status,
                   (SELECT pk_fast_track.get_fast_track_desc(i_lang, i_prof, epis.id_fast_track, g_desc_grid)
                      FROM dual) fast_track_desc,
                   (SELECT pk_edis_triage.get_epis_esi_level(i_lang, i_prof, epis.id_episode, epis.id_triage_color)
                      FROM dual) esi_level,
                   decode(l_order_by, pk_alert_constant.g_yes, decode(epis.triage_flg_letter, g_yes, 0, 1)) letter_rank
              FROM v_episode_act epis, sys_domain sd, room r, grid_task g
             WHERE (l_show_all = g_yes OR EXISTS
                    (SELECT 0
                       FROM grid_task gt
                      WHERE gt.id_episode = epis.id_episode
                        AND coalesce(gt.movement, gt.harvest, gt.drug_transp) IS NOT NULL))
               AND epis.id_software = i_prof.software
               AND epis.id_institution = i_prof.institution
               AND g.id_episode = epis.id_episode(+)
                  -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer do tipo EHR
               AND epis.flg_ehr = g_flg_ehr_normal
               AND EXISTS (SELECT 0
                      FROM prof_room pr
                     WHERE pr.id_professional = i_prof.id
                       AND epis.id_room = pr.id_room)
               AND sd.val = epis.flg_status_ei
               AND sd.code_domain = 'EPIS_INFO.FLG_STATUS'
               AND sd.domain_owner = pk_sysdomain.k_default_schema
               AND sd.id_language = i_lang
               AND epis.id_room = r.id_room(+)
            -- José Brito 22/09/2009 ALERT-45402 Show INPATIENT episodes with a previous EDIS episode
            UNION ALL
            SELECT epis.triage_acuity acuity,
                   epis.triage_color_text color_text,
                   epis.triage_rank_acuity rank_acuity,
                   decode(epis.triage_flg_letter, g_yes, l_msg_edis_grid_m003) acuity_desc,
                   epis.id_episode,
                   pk_date_utils.date_send_tsz(i_lang, epis.dt_begin_tstz_e, i_prof) dt_begin,
                   pk_date_utils.date_char_hour_tsz(i_lang, epis.dt_begin_tstz_e, i_prof.institution, i_prof.software) dt_efectiv,
                   pk_date_utils.diff_timestamp(g_sysdate_tstz, epis.dt_begin_tstz_e) order_time,
                   pk_edis_proc.get_los_duration(i_lang => i_lang, i_prof => i_prof, i_id_episode => epis.id_episode) date_send, -- Length of stay
                   pk_edis_proc.get_formatted_string_for_sort(i_lang    => i_lang,
                                                              i_prof    => i_prof,
                                                              i_type    => pk_edis_proc.g_sort_type_los,
                                                              i_episode => epis.id_episode) date_send_sort,
                   nvl(nvl(r.desc_room_abbreviation,
                           pk_translation.get_translation(i_lang, 'ROOM.CODE_ABBREVIATION.' || epis.id_room)),
                       nvl(r.desc_room, pk_translation.get_translation(i_lang, 'ROOM.CODE_ROOM.' || epis.id_room))) desc_room,
                   epis.id_patient,
                   pk_patient.get_pat_name(i_lang, i_prof, epis.id_patient, epis.id_episode) name_pat,
                   -- ALERT-102882 Patient name used for sorting
                   pk_patient.get_pat_name_to_sort(i_lang, i_prof, epis.id_patient, epis.id_episode, NULL) name_pat_sort,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, epis.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, epis.id_patient) pat_nd_icon,
                   (SELECT pk_patient.get_gender(i_lang, gender) gender
                      FROM patient
                     WHERE id_patient = epis.id_patient) gender,
                   pk_prof_utils.get_nickname(i_lang, epis.id_professional) name_prof,
                   pk_prof_utils.get_nickname(i_lang, epis.id_first_nurse_resp) name_nurse,
                   pk_patient.get_pat_age(i_lang, epis.id_patient, i_prof) pat_age,
                   pk_edis_proc.get_formatted_string_for_sort(i_lang    => i_lang,
                                                              i_prof    => i_prof,
                                                              i_type    => pk_edis_proc.g_sort_type_age,
                                                              i_episode => epis.id_episode) pat_age_for_order_by,
                   pk_date_utils.date_send_tsz(i_lang, epis.dt_first_obs_tstz, i_prof) dt_first_obs,
                   lpad(to_char(sd.rank), 6, '0') || sd.img_name img_transp,
                   pk_patphoto.get_pat_photo(i_lang, i_prof, epis.id_patient, epis.id_episode, epis.id_schedule) photo,
                   'N' flg_temp,
                   g_sysdate_char dt_server,
                   g.hemo_req,
                   NULL desc_temp,
                   (SELECT pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, g.movement)
                      FROM dual) desc_movement,
                   (SELECT pk_grid.visit_grid_task_str(i_lang, i_prof, epis.id_visit, g_task_harvest, l_profile)
                      FROM dual) desc_harvest,
                   (SELECT pk_grid.convert_grid_task_str(i_lang, i_prof, g.drug_transp)
                      FROM dual) desc_drug_transp,
                   pk_supplies_api_db.get_epis_max_supply_delay(i_lang, i_prof, epis.id_patient) desc_supplies,
                   (SELECT pk_fast_track.get_fast_track_icon(i_lang,
                                                             i_prof,
                                                             epis.id_episode,
                                                             epis.id_fast_track,
                                                             epis.id_triage_color,
                                                             -- Send NULL if has no transfer to avoid showing the Fast Track icon
                                                             decode(epis.has_transfer, 0, NULL, g_icon_ft_transfer),
                                                             epis.has_transfer)
                      FROM dual) fast_track_icon,
                   decode(epis.triage_acuity, g_ft_color, g_ft_triage_white, g_ft_color) fast_track_color,
                   g_ft_status fast_track_status,
                   NULL fast_track_desc,
                   (SELECT pk_edis_triage.get_epis_esi_level(i_lang, i_prof, epis.id_episode, epis.id_triage_color)
                      FROM dual) esi_level,
                   decode(l_order_by, pk_alert_constant.g_yes, decode(epis.triage_flg_letter, g_yes, 0, 1)) letter_rank
              FROM v_episode_act epis, sys_domain sd, room r, grid_task g
             WHERE (l_show_all = g_yes OR EXISTS
                    (SELECT 0
                       FROM grid_task gt
                      WHERE gt.id_episode = epis.id_episode
                        AND coalesce(gt.movement, gt.harvest, gt.drug_transp) IS NOT NULL))
               AND pk_episode.get_soft_by_epis_type(epis.id_epis_type, i_prof.institution) = l_id_software_inp
               AND g.id_episode = epis.id_episode(+)
               AND EXISTS
             (SELECT 1
                      FROM episode e, discharge d
                     WHERE e.id_episode = d.id_episode
                       AND e.id_episode = epis.id_prev_episode
                       AND d.flg_status IN (g_discharge_flg_status_active, g_discharge_flg_status_pend)
                       AND pk_episode.get_soft_by_epis_type(e.id_epis_type, i_prof.institution) = i_prof.software
                       AND e.id_institution = i_prof.institution
                       AND e.flg_ehr = g_flg_ehr_normal)
               AND nvl(l_show_inp_epis, g_yes) = g_yes
               AND epis.id_institution = i_prof.institution
               AND epis.flg_ehr = g_flg_ehr_normal
               AND EXISTS (SELECT 0
                      FROM prof_room pr
                     WHERE pr.id_professional = i_prof.id
                       AND epis.id_room = pr.id_room)
               AND sd.val = epis.flg_status_ei
               AND sd.code_domain = 'EPIS_INFO.FLG_STATUS'
               AND sd.id_language = i_lang
               AND sd.domain_owner = pk_sysdomain.k_default_schema
               AND epis.id_room = r.id_room(+)
             ORDER BY rank_acuity, letter_rank, dt_begin;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_grid);
            RETURN error_handling(i_lang, 'GET_GRID_MY_PAT_AUX', g_error, SQLERRM, FALSE, o_error);
    END;
    --
    /**********************************************************************************************
    * Grelha do auxiliar para visualizar todos os pacientes alocados á sala seleccionada
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_room                   room id
    * @param o_grid                   cursor with all patients
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/05/31
    **********************************************************************************************/
    FUNCTION get_grid_room_aux_doc
    (
        i_lang  IN language.id_language%TYPE,
        i_room  IN room.id_room%TYPE,
        i_prof  IN profissional,
        o_grid  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_msg_edis_grid_m003 sys_message.desc_message%TYPE;
        l_profile            VARCHAR2(0050);
    
    BEGIN
        g_error        := 'GET DATES';
        g_sysdate_tstz := current_timestamp;
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
    
        l_msg_edis_grid_m003 := pk_message.get_message(i_lang, 'EDIS_GRID_M003');
        l_profile            := pk_edis_list.get_prof_cat(i_prof);
        --
    
        g_error := 'GET CURSOR O_GRID';
        OPEN o_grid FOR
            SELECT epis.triage_acuity acuity,
                   epis.triage_color_text color_text,
                   epis.triage_rank_acuity rank_acuity,
                   decode(epis.triage_flg_letter, g_yes, l_msg_edis_grid_m003) acuity_desc,
                   epis.id_episode,
                   pk_date_utils.date_send_tsz(i_lang, epis.dt_begin_tstz_e, i_prof) dt_begin,
                   pk_date_utils.date_char_hour_tsz(i_lang, epis.dt_begin_tstz_e, i_prof.institution, i_prof.software) dt_efectiv,
                   pk_date_utils.diff_timestamp(g_sysdate_tstz, epis.dt_begin_tstz_e) order_time, --ET 2007/03/01
                   pk_date_utils.get_elapsed_tsz(i_lang, epis.dt_begin_tstz_e, g_sysdate_tstz) date_send, -- Hora em atraso
                   nvl(nvl(r.desc_room_abbreviation,
                           pk_translation.get_translation(i_lang, 'ROOM.CODE_ABBREVIATION.' || epis.id_room)),
                       nvl(r.desc_room, pk_translation.get_translation(i_lang, 'ROOM.CODE_ROOM.' || epis.id_room))) desc_room,
                   epis.id_patient,
                   pk_patient.get_pat_name(i_lang, i_prof, epis.id_patient, epis.id_episode) name_pat,
                   -- ALERT-102882 Patient name used for sorting
                   pk_patient.get_pat_name_to_sort(i_lang, i_prof, epis.id_patient, epis.id_episode, NULL) name_pat_sort,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, epis.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, epis.id_patient) pat_nd_icon,
                   (SELECT pk_patient.get_gender(i_lang, gender) gender
                      FROM patient
                     WHERE id_patient = epis.id_patient) gender,
                   pk_prof_utils.get_nickname(i_lang, epis.id_professional) name_prof,
                   pk_prof_utils.get_nickname(i_lang, epis.id_first_nurse_resp) name_nurse,
                   pk_patient.get_pat_age(i_lang, epis.id_patient, i_prof) pat_age,
                   pk_patient.get_julian_age(i_lang, epis.id_patient) pat_age_for_order_by,
                   pk_date_utils.date_send_tsz(i_lang, epis.dt_first_obs_tstz, i_prof) dt_first_obs,
                   lpad(to_char(sd.rank), 6, '0') || sd.img_name img_transp,
                   pk_patphoto.get_pat_photo(i_lang, i_prof, epis.id_patient, epis.id_episode, epis.id_schedule) photo,
                   'N' flg_temp,
                   g_sysdate_char dt_server,
                   NULL desc_temp,
                   --grid_task
                   (SELECT pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, g.movement)
                      FROM dual) desc_movement,
                   (SELECT --pk_grid.convert_grid_task_str(i_lang, i_prof, g.harvest)
                     pk_grid.visit_grid_task_str(i_lang, i_prof, epis.id_visit, g_task_harvest, l_profile)
                      FROM dual) desc_harvest,
                   (SELECT pk_grid.convert_grid_task_str(i_lang, i_prof, g.drug_transp)
                      FROM dual) desc_drug_transp,
                   (SELECT pk_fast_track.get_fast_track_icon(i_lang,
                                                             i_prof,
                                                             epis.id_episode,
                                                             epis.id_fast_track,
                                                             epis.id_triage_color,
                                                             -- Send NULL if has no transfer to avoid showing the Fast Track icon
                                                             decode(epis.has_transfer, 0, NULL, g_icon_ft_transfer),
                                                             epis.has_transfer)
                      FROM dual) fast_track_icon,
                   decode(epis.triage_acuity, g_ft_color, g_ft_triage_white, g_ft_color) fast_track_color,
                   g_ft_status fast_track_status,
                   NULL fast_track_desc,
                   (SELECT pk_edis_triage.get_epis_esi_level(i_lang, i_prof, epis.id_episode, epis.id_triage_color)
                      FROM dual) esi_level
              FROM v_episode_act epis, sys_domain sd, room r, grid_task g
             WHERE epis.id_software = i_prof.software
               AND epis.id_institution = i_prof.institution
                  -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer do tipo EHR
               AND epis.flg_ehr = g_flg_ehr_normal
               AND g.id_episode = epis.id_episode(+)
               AND sd.val = epis.flg_status_ei
               AND sd.code_domain = 'EPIS_INFO.FLG_STATUS'
               AND sd.id_language = i_lang
               AND sd.domain_owner = pk_sysdomain.k_default_schema
               AND epis.id_room = i_room
               AND epis.id_room = r.id_room(+)
            -- Pacientes referenciados por outro médico (com carta) tem prioridade sobre outros pacientes triados com a mesma cor
             ORDER BY rank_acuity,
                      decode(orderby_flg_letter(i_prof),
                             pk_alert_constant.g_yes,
                             decode(epis.triage_flg_letter, g_yes, 0, 1)),
                      epis.dt_begin_tstz_e;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_grid);
            RETURN error_handling(i_lang, 'GET_GRID_ROOM_AUX_DOC', g_error, SQLERRM, FALSE, o_error);
    END;
    --
    /**********************************************************************************************
    * Obter a última queixa do episódio tendo em conta se estamos perante a documentation ou não.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_epis                   episode id
    *
    * @return                         description
    *
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/10/10
    **********************************************************************************************/
    FUNCTION get_complaint_grid
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_epis IN episode.id_episode%TYPE,
        i_sep  IN VARCHAR2 DEFAULT ', '
    ) RETURN VARCHAR2 IS
        l_cur_epis_complaint pk_complaint.epis_complaint_cur;
        l_row_epis_complaint pk_complaint.epis_complaint_rec;
        l_error              t_error_out;
    
        l_complaint_desc VARCHAR2(4000 CHAR);
        l_final_desc     VARCHAR2(4000 CHAR);
        l_triage_desc    VARCHAR2(4000 CHAR);
        l_column_flg_triage_res_grids CONSTANT VARCHAR2(200 CHAR) := 'FLG_TRIAGE_RES_GRIDS';
        l_flg_yes                     CONSTANT VARCHAR2(1 CHAR) := 'Y';
    
        l_triage_date              epis_triage.dt_end_tstz%TYPE;
        l_complaint_date           epis_complaint.adw_last_update_tstz%TYPE;
        l_config_record_date_order sys_config.value%TYPE;
        l_id_professional          epis_complaint.id_professional%TYPE;
        l_complaints               VARCHAR2(4000);
    BEGIN
    
        IF g_conf_flg_triage_res_grids IS NULL
        THEN
            g_error                     := 'GET TRIAGE CONFIGURATION: FLG_TRIAGE_RES_GRIDS';
            g_conf_flg_triage_res_grids := pk_edis_triage.get_triage_config_by_name(i_lang        => i_lang,
                                                                                    i_prof        => i_prof,
                                                                                    i_episode     => i_epis,
                                                                                    i_triage_type => NULL,
                                                                                    i_config      => l_column_flg_triage_res_grids);
        END IF;
    
        IF g_conf_flg_triage_res_grids = l_flg_yes
        THEN
            -- Show triage result (e.g. in EST triage shows 'motif de consultation')
            g_error := 'GET ''MOTIF DE CONSULTATION''';
            BEGIN
                SELECT nvl2(e.id_triage_white_reason, -- if white reason exists show it
                            pk_translation.get_translation(i_lang,
                                                           'TRIAGE_WHITE_REASON.CODE_TRIAGE_WHITE_REASON.' ||
                                                           e.id_triage_white_reason) || ': ' || e.notes,
                            nvl2(e.id_triage, -- if a single id_triage exists use it
                                 pk_edis_triage.get_board_label(i_lang,
                                                                i_prof,
                                                                t.id_triage_board,
                                                                td.id_triage_decision_point,
                                                                t.id_triage_type),
                                 -- if no single id_triage exists use id_triage_board in edis_triage
                                 pk_edis_triage.get_board_label(i_lang, i_prof, e.id_triage_board, NULL, NULL))) motif_consultation,
                       e.dt_end_tstz triage_date
                  INTO l_triage_desc, l_triage_date
                  FROM (SELECT etr.id_triage,
                               etr.id_triage_white_reason,
                               etr.id_professional,
                               etr.dt_end_tstz,
                               etr.notes,
                               etr.flg_selected_option,
                               etr.id_epis_triage,
                               etr.id_triage_board
                          FROM epis_triage etr
                         WHERE etr.id_episode = i_epis
                         ORDER BY etr.dt_begin_tstz DESC) e
                  LEFT JOIN triage t
                    ON e.id_triage = t.id_triage
                  LEFT JOIN triage_discriminator td
                    ON td.id_triage_discriminator = t.id_triage_discriminator
                 WHERE rownum < 2;
            EXCEPTION
                WHEN no_data_found THEN
                    l_triage_desc := NULL;
            END;
        END IF;
    
        -- Show complaint
        g_error := 'GET EMERGENCY COMPLAINT';
        /*        IF NOT pk_complaint.get_epis_complaint(i_lang           => i_lang,
                                                   i_prof           => i_prof,
                                                   i_episode        => i_epis,
                                                   i_epis_docum     => NULL,
                                                   i_flg_only_scope => pk_alert_constant.g_no,
                                                   o_epis_complaint => l_cur_epis_complaint,
                                                   o_error          => l_error)
            THEN
                RETURN NULL;
            END IF;
        */
        IF NOT pk_complaint.get_complaint_header(i_lang           => i_lang,
                                                 i_prof           => i_prof,
                                                 i_episode        => i_epis,
                                                 i_sep            => i_sep,
                                                 o_last_complaint => l_complaint_desc,
                                                 o_complaints     => l_complaints,
                                                 o_professional   => l_id_professional,
                                                 o_dt_register    => l_complaint_date,
                                                 o_error          => l_error)
        THEN
            RETURN NULL;
        END IF;
        /*        g_error := 'FETCH L_CUR_EPIS_COMPLAINT';
           FETCH l_cur_epis_complaint
               INTO l_row_epis_complaint;
        
           IF l_cur_epis_complaint%NOTFOUND
           THEN
               l_complaint_desc := NULL;
           ELSE
               l_complaint_desc := pk_complaint.get_epis_complaint_desc(i_lang,
                                                                        i_prof,
                                                                        l_row_epis_complaint.desc_complaint,
                                                                        l_row_epis_complaint.patient_complaint);
           END IF;
        
           l_complaint_date := l_row_epis_complaint.dt_register;
        
           CLOSE l_cur_epis_complaint;
        */
        l_config_record_date_order := pk_sysconfig.get_config('TRIAGE_COMPLAINT_RECORD_DATE_ORDER',
                                                              i_prof.institution,
                                                              i_prof.software);
    
        IF l_config_record_date_order = pk_alert_constant.g_yes
        THEN
            -- if configured to show most recent record, give priority to it whether it is a triage or complaint info
            IF l_triage_desc IS NULL
               OR l_triage_date < l_complaint_date
            THEN
                l_final_desc := l_complaint_desc;
            ELSE
                l_final_desc := l_triage_desc;
            END IF;
        ELSE
            -- if configured to show record according to priority triage>complaint, give priority to triage and only show complaint if there is no triage
            IF l_triage_desc IS NOT NULL
            THEN
                l_final_desc := l_triage_desc;
            ELSIF l_complaint_desc IS NOT NULL
            THEN
                l_final_desc := l_complaint_desc;
            END IF;
        END IF;
        RETURN l_final_desc;
        --without exception block so the calling function can be aware of problems
    END;
    --
    /**********************************************************************************************
    * Obter a última queixa do episódio tendo em conta se estamos perante a documentation ou não.
    *
    * @param i_lang                   the id language
    * @param i_inst                   institution id
    * @param i_soft                   software id
    * @param i_epis                   episode id
    *
    * @return                         description
    *
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/10/23
    **********************************************************************************************/
    FUNCTION get_complaint_grid
    (
        i_lang IN language.id_language%TYPE,
        i_inst IN institution.id_institution%TYPE,
        i_soft IN software.id_software%TYPE,
        i_epis IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        RETURN pk_edis_grid.get_complaint_grid(i_lang => i_lang,
                                               i_prof => profissional(0, i_inst, i_soft),
                                               i_epis => i_epis);
        --without exception block so the calling function can be aware of problems
    END;
    --
    /**********************************************************************************************
    * Grelha do triador, para visualizar todos os pacientes alocados ás suas salas
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_grid                   cursor with all patients
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2007/01/27
    **********************************************************************************************/
    FUNCTION get_grid_all_pat_triage
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_grid  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_show_all sys_config.value%TYPE;
        l_config_origin CONSTANT sys_config.id_sys_config%TYPE := 'GRID_ORIGINS';
    
    BEGIN
        g_error        := 'GET DATES';
        g_sysdate_tstz := current_timestamp;
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
    
        l_show_all         := pk_sysconfig.get_config(i_code_cf => 'TRIAGE_GRID_SHOW_ALL', i_prof => i_prof);
        g_grid_origins     := pk_sysconfig.get_config(l_config_origin, i_prof);
        g_tab_grid_origins := pk_utils.str_split_l(g_grid_origins, '|');
    
        --
        IF nvl(l_show_all, g_yes) = g_yes
        THEN
            g_error := 'GET CURSOR O_GRID (1)';
            OPEN o_grid FOR
                SELECT acuity,
                       color_text,
                       rank_acuity,
                       acuity_desc,
                       id_episode,
                       dt_begin,
                       order_time,
                       date_send,
                       desc_room,
                       id_patient,
                       name_pat,
                       name_pat_sort,
                       pat_ndo,
                       pat_nd_icon,
                       gender,
                       name_prof,
                       name_nurse,
                       pat_age,
                       pat_age_for_order_by,
                       dt_first_obs,
                       img_transp,
                       care_stage,
                       care_stage_rank,
                       photo,
                       flg_temp,
                       dt_server,
                       desc_temp,
                       desc_epis_anamnesis,
                       fast_track_icon,
                       fast_track_color,
                       fast_track_status,
                       fast_track_status,
                       esi_level,
                       resp_icons,
                       pat_major_inc_icon,
                       rownum rank_triage,
                       origin_anamn_full_desc
                  FROM (SELECT epis.triage_acuity acuity,
                               epis.triage_color_text color_text,
                               epis.triage_rank_acuity rank_acuity,
                               (SELECT decode(epis.triage_flg_letter,
                                              g_yes,
                                              pk_message.get_message(i_lang, 'EDIS_GRID_M003'))
                                  FROM dual) acuity_desc,
                               epis.id_episode,
                               pk_date_utils.date_send_tsz(i_lang, epis.dt_begin_tstz_e, i_prof) dt_begin,
                               pk_date_utils.date_char_hour_tsz(i_lang,
                                                                epis.dt_begin_tstz_e,
                                                                i_prof.institution,
                                                                i_prof.software) dt_efectiv,
                               pk_date_utils.diff_timestamp(g_sysdate_tstz, epis.dt_begin_tstz_e) order_time,
                               pk_date_utils.get_elapsed_tsz(i_lang, epis.dt_begin_tstz_e, g_sysdate_tstz) date_send,
                               (SELECT coalesce(r.desc_room_abbreviation,
                                                pk_translation.get_translation_dtchk(i_lang,
                                                                                     'ROOM.CODE_ABBREVIATION' ||
                                                                                     epis.id_room),
                                                r.desc_room,
                                                pk_translation.get_translation_dtchk(i_lang,
                                                                                     'ROOM.CODE_ROOM.' || epis.id_room))
                                  FROM dual) desc_room,
                               epis.id_patient,
                               pk_patient.get_pat_name(i_lang, i_prof, epis.id_patient, epis.id_episode) name_pat,
                               -- ALERT-102882 Patient name used for sorting
                               pk_patient.get_pat_name_to_sort(i_lang, i_prof, epis.id_patient, epis.id_episode, NULL) name_pat_sort,
                               pk_adt.get_pat_non_disc_options(i_lang, i_prof, epis.id_patient) pat_ndo,
                               pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, epis.id_patient) pat_nd_icon,
                               (SELECT pk_patient.get_gender(i_lang, gender) gender
                                  FROM patient
                                 WHERE id_patient = epis.id_patient) gender,
                               (SELECT pk_prof_utils.get_nickname(i_lang, epis.id_professional)
                                  FROM dual) name_prof,
                               (SELECT pk_prof_utils.get_nickname(i_lang, epis.id_first_nurse_resp)
                                  FROM dual) name_nurse,
                               pk_patient.get_pat_age(i_lang, epis.id_patient, i_prof) pat_age,
                               pk_edis_proc.get_formatted_string_for_sort(i_lang    => i_lang,
                                                                          i_prof    => i_prof,
                                                                          i_type    => pk_edis_proc.g_sort_type_age,
                                                                          i_episode => epis.id_episode) pat_age_for_order_by,
                               pk_date_utils.date_send_tsz(i_lang, epis.dt_first_obs_tstz, i_prof) dt_first_obs,
                               lpad(to_char(sd.rank), 6, '0') || sd.img_name img_transp,
                               pk_patient_tracking.get_care_stage_grid_status(i_lang,
                                                                              i_prof,
                                                                              epis.id_episode,
                                                                              g_sysdate_char) care_stage,
                               pk_patient_tracking.get_current_state_rank(i_lang, i_prof, epis.id_episode) care_stage_rank,
                               pk_patphoto.get_pat_photo(i_lang,
                                                         i_prof,
                                                         epis.id_patient,
                                                         epis.id_episode,
                                                         epis.id_schedule) photo,
                               'N' flg_temp,
                               g_sysdate_char dt_server,
                               NULL desc_temp,
                               (SELECT pk_string_utils.concat_if_exists((SELECT get_grid_origin_abbrev(i_lang,
                                                                                                      i_prof,
                                                                                                      v.id_origin)
                                                                          FROM visit v
                                                                         WHERE v.id_visit = epis.id_visit),
                                                                        pk_edis_grid.get_complaint_grid(i_lang,
                                                                                                        i_prof,
                                                                                                        epis.id_episode),
                                                                        ' / ')
                                  FROM dual) desc_epis_anamnesis,
                               --
                               (SELECT pk_fast_track.get_fast_track_icon(i_lang,
                                                                         i_prof,
                                                                         epis.id_episode,
                                                                         epis.id_fast_track,
                                                                         epis.id_triage_color,
                                                                         decode(epis.has_transfer,
                                                                                0,
                                                                                g_icon_ft,
                                                                                g_icon_ft_transfer),
                                                                         epis.has_transfer)
                                  FROM dual) fast_track_icon,
                               decode(epis.triage_acuity, g_ft_color, g_ft_triage_white, g_ft_color) fast_track_color,
                               g_ft_status fast_track_status,
                               (SELECT pk_fast_track.get_fast_track_desc(i_lang, i_prof, epis.id_fast_track, g_desc_grid)
                                  FROM dual) fast_track_desc,
                               (SELECT pk_edis_triage.get_epis_esi_level(i_lang,
                                                                         i_prof,
                                                                         epis.id_episode,
                                                                         epis.id_triage_color)
                                  FROM dual) esi_level,
                               --Alexandre Santos 13-10-2010 ALERT-726 Changing and cancelling appointmentsChanging to another physician with the same specialty as the responsible physician. However, the responsible physician remains the same.
                               (SELECT pk_hand_off_api.get_resp_icons(i_lang, i_prof, epis.id_episode, NULL)
                                  FROM dual) resp_icons,
                               --Gisela Couto 04-09-2014  ALERT-284142 Major incident icon
                               pk_adt_core.check_bulk_admission_episode(i_lang       => i_lang,
                                                                        i_prof       => i_prof,
                                                                        i_id_episode => epis.id_episode) pat_major_inc_icon,
                               pk_edis_proc.get_formatted_string_for_sort(i_lang    => i_lang,
                                                                          i_prof    => i_prof,
                                                                          i_type    => pk_edis_proc.g_sort_type_los,
                                                                          i_episode => epis.id_episode) date_send_sort,
                               get_orig_anamn_desc(i_lang, i_prof, epis.id_visit, epis.id_episode) origin_anamn_full_desc
                          FROM v_episode_act epis, sys_domain sd, institution i, room r
                        -- José Brito 09/05/2008 Carregar episódios do EDIS/UBU no ALERT® Triage
                         WHERE epis.id_software = decode(i_prof.software,
                                                         g_soft_triage,
                                                         decode(i.flg_type, g_inst_type_h, g_soft_edis, g_soft_ubu),
                                                         i_prof.software)
                           AND epis.id_institution = i_prof.institution
                              -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer do tipo EHR
                           AND epis.flg_ehr = g_flg_ehr_normal
                              -- José Brito 13/05/2008 Necessário para verificar se estamos em ambiente hospitalar ou centro de saúde
                           AND epis.id_institution = i.id_institution
                              --
                           AND sd.val = epis.flg_status_ei
                           AND sd.code_domain = 'EPIS_INFO.FLG_STATUS'
                           AND sd.domain_owner = pk_sysdomain.k_default_schema
                           AND sd.id_language = i_lang
                           AND EXISTS (SELECT 0
                                  FROM prof_room pr
                                 WHERE pr.id_professional = i_prof.id
                                   AND epis.id_room = pr.id_room)
                           AND epis.id_room = r.id_room(+)
                        -- José Brito 18/06/2008 Mostrar episódios triados e não-triados na grelha principal
                         ORDER BY rank_acuity,
                                  decode(pk_sysconfig.get_config('EDIS_GRID_ORIGIN_ORDER_WITHOUT_TRIAGE', i_prof),
                                         pk_alert_constant.g_yes,
                                         decode(pk_edis_triage.get_flag_no_color(i_lang, i_prof, epis.id_triage_color),
                                                'S',
                                                0,
                                                decode(pk_utils.search_table_varchar(g_tab_grid_origins,
                                                                                     (SELECT id_origin
                                                                                        FROM visit
                                                                                       WHERE id_visit = epis.id_visit)),
                                                       -1,
                                                       1,
                                                       0)),
                                         decode(pk_utils.search_table_varchar(g_tab_grid_origins,
                                                                              (SELECT id_origin
                                                                                 FROM visit
                                                                                WHERE id_visit = epis.id_visit)),
                                                -1,
                                                1,
                                                0)),
                                  decode(orderby_flg_letter(i_prof),
                                         pk_alert_constant.g_yes,
                                         decode(epis.triage_flg_letter, g_yes, 0, 1)),
                                  epis.dt_begin_tstz_e);
        ELSE
            g_error := 'GET CURSOR O_GRID (2)';
            OPEN o_grid FOR
                SELECT acuity,
                       color_text,
                       rank_acuity,
                       acuity_desc,
                       id_episode,
                       dt_begin,
                       dt_efectiv,
                       order_time,
                       date_send,
                       desc_room,
                       id_patient,
                       name_pat,
                       name_pat_sort,
                       pat_ndo,
                       pat_nd_icon,
                       gender,
                       name_prof,
                       name_nurse,
                       pat_age,
                       pat_age_for_order_by,
                       dt_first_obs,
                       img_transp,
                       photo,
                       flg_temp,
                       dt_server,
                       desc_temp,
                       desc_epis_anamnesis,
                       fast_track_icon,
                       fast_track_color,
                       fast_track_status,
                       fast_track_desc,
                       esi_level,
                       pat_major_inc_icon,
                       date_send_sort,
                       rownum rank_triage,
                       origin_anamn_full_desc
                  FROM (SELECT g_no_triage_color acuity,
                               g_no_triage_color_text color_text,
                               g_color_rank rank_acuity,
                               NULL acuity_desc,
                               epis.id_episode,
                               pk_date_utils.date_send_tsz(i_lang, epis.dt_begin_tstz_e, i_prof) dt_begin,
                               pk_date_utils.date_char_hour_tsz(i_lang,
                                                                epis.dt_begin_tstz_e,
                                                                i_prof.institution,
                                                                i_prof.software) dt_efectiv,
                               pk_date_utils.diff_timestamp(g_sysdate_tstz, epis.dt_begin_tstz_e) order_time,
                               pk_date_utils.get_elapsed_tsz(i_lang, epis.dt_begin_tstz_e, g_sysdate_tstz) date_send,
                               (SELECT nvl(nvl(r.desc_room_abbreviation,
                                               pk_translation.get_translation_dtchk(i_lang,
                                                                                    'ROOM.CODE_ABBREVIATION' ||
                                                                                    epis.id_room)),
                                           nvl(r.desc_room,
                                               pk_translation.get_translation_dtchk(i_lang,
                                                                                    'ROOM.CODE_ROOM.' || epis.id_room)))
                                  FROM dual) desc_room,
                               epis.id_patient,
                               pk_patient.get_pat_name(i_lang, i_prof, epis.id_patient, epis.id_episode) name_pat,
                               -- ALERT-102882 Patient name used for sorting
                               pk_patient.get_pat_name_to_sort(i_lang, i_prof, epis.id_patient, epis.id_episode, NULL) name_pat_sort,
                               pk_adt.get_pat_non_disc_options(i_lang, i_prof, epis.id_patient) pat_ndo,
                               pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, epis.id_patient) pat_nd_icon,
                               (SELECT pk_patient.get_gender(i_lang, gender) gender
                                  FROM patient
                                 WHERE id_patient = epis.id_patient) gender,
                               (SELECT pk_prof_utils.get_nickname(i_lang, epis.id_professional)
                                  FROM dual) name_prof,
                               (SELECT pk_prof_utils.get_nickname(i_lang, epis.id_first_nurse_resp)
                                  FROM dual) name_nurse,
                               pk_patient.get_pat_age(i_lang, epis.id_patient, i_prof) pat_age,
                               pk_edis_proc.get_formatted_string_for_sort(i_lang    => i_lang,
                                                                          i_prof    => i_prof,
                                                                          i_type    => pk_edis_proc.g_sort_type_age,
                                                                          i_episode => epis.id_episode) pat_age_for_order_by,
                               pk_date_utils.date_send_tsz(i_lang, epis.dt_first_obs_tstz, i_prof) dt_first_obs,
                               lpad(to_char(sd.rank), 6, '0') || sd.img_name img_transp,
                               pk_patphoto.get_pat_photo(i_lang,
                                                         i_prof,
                                                         epis.id_patient,
                                                         epis.id_episode,
                                                         epis.id_schedule) photo,
                               'N' flg_temp,
                               g_sysdate_char dt_server,
                               NULL desc_temp,
                               (SELECT pk_string_utils.concat_if_exists((SELECT get_grid_origin_abbrev(i_lang,
                                                                                                      i_prof,
                                                                                                      v.id_origin)
                                                                          FROM visit v
                                                                         WHERE v.id_visit = epis.id_visit),
                                                                        pk_edis_grid.get_complaint_grid(i_lang,
                                                                                                        i_prof,
                                                                                                        epis.id_episode),
                                                                        ' / ')
                                  FROM dual) desc_epis_anamnesis,
                               (SELECT pk_fast_track.get_fast_track_icon(i_lang,
                                                                         i_prof,
                                                                         epis.id_episode,
                                                                         epis.id_fast_track,
                                                                         epis.id_triage_color,
                                                                         decode(epis.has_transfer,
                                                                                0,
                                                                                g_icon_ft,
                                                                                g_icon_ft_transfer),
                                                                         epis.has_transfer)
                                  FROM dual) fast_track_icon,
                               g_ft_color fast_track_color,
                               g_ft_status fast_track_status,
                               (SELECT pk_fast_track.get_fast_track_desc(i_lang, i_prof, epis.id_fast_track, g_desc_grid)
                                  FROM dual) fast_track_desc,
                               NULL esi_level,
                               --Gisela Couto 04-09-2014  ALERT-284142 Major incident icon
                               pk_adt_core.check_bulk_admission_episode(i_lang       => i_lang,
                                                                        i_prof       => i_prof,
                                                                        i_id_episode => epis.id_episode) pat_major_inc_icon,
                               pk_edis_proc.get_formatted_string_for_sort(i_lang    => i_lang,
                                                                          i_prof    => i_prof,
                                                                          i_type    => pk_edis_proc.g_sort_type_los,
                                                                          i_episode => epis.id_episode) date_send_sort,
                               get_orig_anamn_desc(i_lang, i_prof, epis.id_visit, epis.id_episode) origin_anamn_full_desc
                          FROM v_episode_act epis, sys_domain sd, institution i, room r
                        -- José Brito 09/05/2008 Carregar episódios do EDIS/UBU no ALERT® Triage
                         WHERE epis.id_software = decode(i.flg_type, g_inst_type_h, g_soft_edis, g_soft_ubu)
                           AND epis.id_institution = i_prof.institution
                              -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer do tipo EHR
                           AND epis.flg_ehr = g_flg_ehr_normal
                              -- José Brito 13/05/2008 Necessário para verificar se estamos em ambiente hospitalar ou centro de saúde
                           AND epis.id_institution = i.id_institution
                              --
                           AND sd.val = epis.flg_status_ei
                           AND sd.code_domain = 'EPIS_INFO.FLG_STATUS'
                           AND sd.domain_owner = pk_sysdomain.k_default_schema
                           AND sd.id_language = i_lang
                           AND epis.id_room IN (SELECT pr.id_room
                                                  FROM prof_room pr
                                                 WHERE pr.id_professional = i_prof.id)
                           AND NOT EXISTS (SELECT 0
                                  FROM epis_triage etr
                                 WHERE etr.id_episode = epis.id_episode
                                      -- José Brito 10/09/2008 Os episódios triados sem côr, também devem ser devolvidos
                                   AND etr.id_triage_color NOT IN
                                       (SELECT tco.id_triage_color
                                          FROM triage_color tco
                                         WHERE tco.color = g_no_triage_color))
                           AND epis.id_room = r.id_room(+)
                         ORDER BY decode(pk_utils.search_table_varchar(g_tab_grid_origins,
                                                                       (SELECT id_origin
                                                                          FROM visit
                                                                         WHERE id_visit = epis.id_visit)),
                                         -1,
                                         1,
                                         0),
                                  epis.dt_begin_tstz_e);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_grid);
            RETURN error_handling(i_lang, 'GET_GRID_ALL_PAT_TRIAGE', g_error, SQLERRM, FALSE, o_error);
    END;
    --
    /**********************************************************************************************
    * This function picks up an id_disch_reas_dest from a patient's discharge and
    * returns the destination description if the discharge was a service transfer of an
    * inpatient admission. Theis description is shown in the administrative's grid.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_disch_reas_dest        id of the record of discharge destination for a given patient
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         João Eiras
    * @version                        1.0
    * @since                          2008/01/16
    **********************************************************************************************/
    FUNCTION get_label_follow_up_date
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_disch_reas_dest IN discharge.id_disch_reas_dest%TYPE,
        i_prof_cat        IN category.flg_type%TYPE
    ) RETURN VARCHAR2 IS
        l_label VARCHAR2(2000);
    BEGIN
        IF g_disch_reason_inp_clin_serv IS NULL
        THEN
            g_disch_reason_inp_clin_serv := pk_sysconfig.get_config('ID_DISCHARGE_INTERNMENT', i_prof);
        END IF;
    
        SELECT decode((SELECT drd.id_discharge_reason
                        FROM disch_reas_dest drd
                       WHERE drd.id_disch_reas_dest = i_disch_reas_dest),
                      g_disch_reason_inp_clin_serv,
                      (SELECT pk_translation.get_translation(i_lang, dr.code_discharge_reason) || chr(10) ||
                              decode(nvl(drd.id_discharge_dest, 0),
                                     0,
                                     decode(nvl(drd.id_dep_clin_serv, 0),
                                            0,
                                            decode(nvl(drd.id_institution, 0),
                                                   0,
                                                   pk_translation.get_translation(i_lang,
                                                                                  'DEPARTMENT.CODE_DEPARTMENT.' ||
                                                                                  drd.id_department),
                                                   pk_translation.get_translation(i_lang,
                                                                                  'AB_INSTITUTION.CODE_INSTITUTION.' ||
                                                                                  drd.id_institution)),
                                            pk_translation.get_translation(i_lang,
                                                                           'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' ||
                                                                           dcs.id_clinical_service)),
                                     pk_translation.get_translation(i_lang, dd.code_discharge_dest))
                         FROM disch_reas_dest drd, discharge_reason dr, dep_clin_serv dcs, discharge_dest dd
                        WHERE i_disch_reas_dest = drd.id_disch_reas_dest
                          AND drd.id_discharge_reason = dr.id_discharge_reason
                          AND dcs.id_dep_clin_serv(+) = drd.id_dep_clin_serv
                          AND dd.id_discharge_dest(+) = drd.id_discharge_dest
                          AND ((instr(dd.flg_type, i_prof_cat) != 0 AND dd.id_discharge_dest = drd.id_discharge_dest) OR
                              dd.id_discharge_dest IS NULL)),
                      NULL)
          INTO l_label
          FROM dual;
    
        RETURN l_label;
    
    END;
    --
    /**********************************************************************************************
    * Returns the destination description if the discharge was a service transfer of an
    * inpatient admission. This description is shown in the administrative's grid.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_episode                episode ID
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         José Silva
    * @version                        2.5.1.2
    * @since                          17/02/2011
    **********************************************************************************************/
    FUNCTION get_label_follow_up
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN discharge.id_disch_reas_dest%TYPE,
        i_prof_cat IN category.flg_type%TYPE
    ) RETURN VARCHAR2 IS
        l_label           VARCHAR2(2000);
        l_disch_reas_dest disch_reas_dest.id_disch_reas_dest%TYPE;
    BEGIN
    
        BEGIN
            SELECT d.id_disch_reas_dest
              INTO l_disch_reas_dest
              FROM discharge d
             WHERE d.id_episode = i_episode
               AND d.flg_status = g_discharge_flg_status_active;
        EXCEPTION
            WHEN no_data_found THEN
                RETURN NULL;
        END;
    
        l_label := get_label_follow_up_date(i_lang            => i_lang,
                                            i_prof            => i_prof,
                                            i_disch_reas_dest => l_disch_reas_dest,
                                            i_prof_cat        => i_prof_cat);
    
        RETURN l_label;
    
    END get_label_follow_up;
    --

    /**********************************************************************************************
    * Grelha do administrativo, para visualizar todos os pacientes alocados ás suas salas
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_grid                   cursor with all patients
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Luis Gaspar
    * @version                        1.0
    * @since                          2007/02/14
    * @notes                          Nesta grelha visualizam-se os episódios activos/pendentes do software em I_PROF_software:
                                        - Episódios sem registos clinicos.
                                        - Episódios com alta clinica definitiva para fora da instituição
                                        - Episódios com alta clinica pendente para fora da instituição(A IMPLEMENTAR)
                                        - Episódios com alta clínica pendente ou definitiva para outro local na instituição, por exemplo OBS/internamento
                                        - Episódios com pedido de transferência de instituição (A IMPLEMENTAR)
                                        - Episódios reabertos e que estejam numa das situações anteriores (A IMPLEMENTAR)
                                        Visualizam-se também os episódios activos/pendentes que tenham tido origem num episódio associado a I_PROF.Software:
                                        - Episódios sem registos clinicos.
                                        - Episódios com alta clinica definitiva para fora da instituição
                                        - Episódios com alta clinica pendente para fora da instituição(A IMPLEMENTAR)
                                        - Episódios com pedido de transferência de instituição (A IMPLEMENTAR)
                                        - Episódios reabertos e que estejam numa das situações anteriores (A IMPLEMENTAR)
    **********************************************************************************************/
    FUNCTION get_grid_all_pat_admin
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_grid  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_screens  table_varchar := table_varchar('ADMIN_DISCHARGE', 'PATIENT_ARRIVAL');
        l_cat_type category.flg_type%TYPE;
    
        l_msg_edis_common_t002 sys_message.desc_message%TYPE;
        l_msg_edis_common_t003 sys_message.desc_message%TYPE;
        l_msg_edis_common_t004 sys_message.desc_message%TYPE;
        l_msg_edis_grid_t054   sys_message.desc_message%TYPE;
        l_epis_c_display       NUMBER(24);
        l_edis_admission       VARCHAR2(1);
        l_count                NUMBER(24);
        l_limit                TIMESTAMP WITH LOCAL TIME ZONE;
        --
        l_shortcut_disch       sys_shortcut.id_sys_shortcut%TYPE;
        l_shortcut_pat_arrival sys_shortcut.id_sys_shortcut%TYPE;
        --
        l_disch_reas_dest_admission table_number;
        --
        l_exception EXCEPTION;
        l_error t_error_out;
    
    BEGIN
        g_error        := 'GET DATES';
        g_sysdate_tstz := current_timestamp;
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
        l_limit        := pk_date_utils.add_days_to_tstz(current_timestamp,
                                                         -to_number(pk_sysconfig.get_config('TIME_MAX_ADM_URG_UBU',
                                                                                            i_prof) / 24));
        --
        g_error                      := 'GET configurations';
        g_disch_reason_inp_clin_serv := pk_sysconfig.get_config('ID_DISCHARGE_INTERNMENT', i_prof);
        l_epis_c_display             := pk_sysconfig.get_config('CANCELLED_EPISODES_DISPLAY_TIME', i_prof);
        l_edis_admission             := pk_sysconfig.get_config('ADMIN_ADMISSION', i_prof);
        --
        g_error := 'CALL PK_ACCESS.PRELOAD_SHORTCUTS';
        IF NOT
            pk_access.preload_shortcuts(i_lang => i_lang, i_prof => i_prof, i_screens => l_screens, o_error => o_error)
        THEN
            RAISE l_exception;
        END IF;
        --
        g_error                := 'GET SHORTCUTS';
        l_shortcut_disch       := pk_access.get_shortcut('ADMIN_DISCHARGE');
        l_shortcut_pat_arrival := pk_access.get_shortcut('PATIENT_ARRIVAL');
        --
        g_error                := 'GET MESSAGES';
        l_msg_edis_common_t002 := pk_message.get_message(i_lang, 'EDIS_COMMON_T002');
        l_msg_edis_common_t003 := pk_message.get_message(i_lang, 'EDIS_COMMON_T003');
        l_msg_edis_common_t004 := pk_message.get_message(i_lang, 'EDIS_COMMON_T004');
        l_msg_edis_grid_t054   := pk_message.get_message(i_lang, 'EDIS_GRID_T054');
    
        g_error    := 'OPEN C_CAT';
        l_cat_type := pk_edis_list.get_prof_cat(i_prof);
        --
        -- José Brito 14/07/2008 Mostrar os episódios dos serviços aos quais o administrativo está alocado, ...
        -- ... caso contrário mostra todos os episódios.
        BEGIN
            IF i_prof.software = g_soft_ubu
            THEN
                l_count := 0;
            ELSE
                -- Verificar se o administrativo está alocado a serviços clínicos
                g_error := 'GET CLINICAL SERVICE COUNT';
                SELECT COUNT(*)
                  INTO l_count
                  FROM prof_dep_clin_serv pdcs, dep_clin_serv dcs, department dpt
                 WHERE pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
                   AND dcs.id_department = dpt.id_department
                   AND (dpt.id_software = i_prof.software OR
                       (instr(dpt.flg_type, 'I') > 0 AND instr(dpt.flg_type, 'O') > 0))
                   AND dpt.id_institution = i_prof.institution
                   AND pdcs.id_professional = i_prof.id
                   AND pdcs.flg_status = g_selected
                   AND dcs.flg_available = g_yes
                   AND dpt.flg_available = g_yes;
            END IF;
        EXCEPTION
            WHEN no_data_found THEN
                l_count := 0;
            WHEN OTHERS THEN
                RAISE l_exception;
        END;
    
        IF l_edis_admission = pk_alert_constant.g_yes
        THEN
            -- Leitura de todos os id_disch_reas_dest que possam apontar para uma alta de internamento
            SELECT drd.id_disch_reas_dest
              BULK COLLECT
              INTO l_disch_reas_dest_admission
              FROM disch_reas_dest drd
             WHERE EXISTS (SELECT 0
                      FROM profile_disch_reason pdr
                      JOIN discharge_flash_files dff
                        ON (dff.id_discharge_flash_files = pdr.id_discharge_flash_files)
                     WHERE pdr.id_discharge_reason = drd.id_discharge_reason
                       AND dff.flg_type = 'A');
        END IF;
    
        --
        g_error := 'GET CURSOR O_GRID';
        OPEN o_grid FOR
        -- episódios activos/pendentes do software em I_PROF_software
        -- TODO considerar as salas a que o profissional está alocado ou melhor seria especialidades, mas em urgência não há especialidades...
        
            WITH prof_dcs1 AS
             (SELECT /*+ materialize*/
               pdcs.id_dep_clin_serv, dpt.id_software
                FROM prof_dep_clin_serv pdcs, dep_clin_serv dcs, department dpt
               WHERE pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
                 AND dcs.id_department = dpt.id_department
                 AND dpt.id_software = i_prof.software
                 AND dpt.id_institution = i_prof.institution
                 AND i_prof.software != g_soft_ubu
                 AND pdcs.id_professional = i_prof.id
                 AND pdcs.flg_status = g_selected
                 AND dcs.flg_available = g_yes
                 AND dpt.flg_available = g_yes
              UNION ALL
              SELECT 0 id_dep_clin_serv, i_prof.software id_software
                FROM dual),
            
            prof_dcs2 AS
             (SELECT /*+ materialize*/
               pdcs.id_dep_clin_serv, dcs.id_dep_clin_serv id_dcs_obs, dpt.id_software
                FROM dep_clin_serv dcs
                JOIN department dpt
                  ON dpt.id_department = dcs.id_department
                 AND dpt.id_institution = i_prof.institution
                LEFT JOIN prof_dep_clin_serv pdcs
                  ON pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
                 AND pdcs.id_professional = i_prof.id
                 AND pdcs.flg_status = g_selected
               WHERE dcs.flg_available = g_yes
                 AND dpt.flg_available = g_yes
                 AND instr(dpt.flg_type, 'I') > 0
                 AND instr(dpt.flg_type, 'O') > 0),
            
            prof_dcs3 AS
             (SELECT /*+ materialize*/
               pdcs.id_dep_clin_serv, dcs.id_dep_clin_serv id_dcs_obs, dpt.id_software
                FROM prof_dep_clin_serv pdcs, dep_clin_serv dcs, department dpt
               WHERE pdcs.id_dep_clin_serv(+) = dcs.id_dep_clin_serv
                 AND dcs.id_department = dpt.id_department
                 AND (dpt.id_software = i_prof.software OR
                      (instr(dpt.flg_type, 'I') > 0 AND instr(dpt.flg_type, 'O') > 0))
                 AND dpt.id_institution = i_prof.institution
                 AND pdcs.id_professional(+) = i_prof.id
                 AND pdcs.flg_status(+) = 'S'
                 AND dcs.flg_available = 'Y'
                 AND dpt.flg_available = 'Y'
              UNION ALL
              SELECT 0 id_dep_clin_serv, NULL id_dcs_obs, i_prof.software id_software
                FROM dual)
            
            SELECT (SELECT decode(epis_transport.column_value,
                                  'NULL',
                                  decode(i_prof.software, g_soft_edis, l_msg_edis_common_t002, l_msg_edis_common_t004),
                                  'T',
                                  l_msg_edis_common_t002,
                                  l_msg_edis_common_t004)
                      FROM dual) origem,
                   epis.triage_acuity acuity,
                   epis.triage_color_text color_text,
                   epis.triage_rank_acuity rank_acuity,
                   (SELECT pk_patient.get_pat_age(i_lang, epis.id_patient, i_prof)
                      FROM dual) pat_age,
                   (SELECT pk_patient.get_julian_age(i_lang, epis.id_patient)
                      FROM dual) pat_age_for_order_by,
                   (SELECT pk_patient.get_gender(i_lang, gender) gender
                      FROM patient pat
                     WHERE pat.id_patient = epis.id_patient) gender,
                   (SELECT pk_patphoto.get_pat_photo(i_lang, i_prof, epis.id_patient, epis.id_episode, NULL)
                      FROM dual) photo,
                   (SELECT pk_patient.get_pat_name(i_lang, i_prof, epis.id_patient, epis.id_episode)
                      FROM dual) name_pat,
                   -- ALERT-102882 Patient name used for sorting
                   (SELECT pk_patient.get_pat_name_to_sort(i_lang, i_prof, epis.id_patient, epis.id_episode, NULL)
                      FROM dual) name_pat_sort,
                   (SELECT pk_adt.get_pat_non_disc_options(i_lang, i_prof, epis.id_patient)
                      FROM dual) pat_ndo,
                   (SELECT pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, epis.id_patient)
                      FROM dual) pat_nd_icon,
                   (SELECT num_clin_record
                      FROM clin_record cr
                     WHERE cr.id_patient = epis.id_patient
                       AND cr.id_institution = i_prof.institution
                       AND rownum < 2) num_clin_record,
                   (SELECT pk_patient_tracking.get_care_stage_grid_status(i_lang,
                                                                          i_prof,
                                                                          epis.id_episode,
                                                                          g_sysdate_char)
                      FROM dual) care_stage,
                   (SELECT pk_patient_tracking.get_current_state_rank(i_lang, i_prof, epis.id_episode)
                      FROM dual) care_stage_rank,
                   (SELECT pk_doc.get_num_episode_images(epis.id_episode, epis.id_patient)
                      FROM dual) attaches,
                   (SELECT pk_service_transfer.get_transfer_status_icon(i_lang,
                                                                        i_prof,
                                                                        epis.id_episode,
                                                                        pk_service_transfer.g_transfer_flg_hospital_h)
                      FROM dual) transfer_req_time,
                   -- data de efectivação.
                   -- um epis reaberto com alta adm sem registos clinicos tem que aparecer
                   pk_date_utils.date_send_tsz(i_lang,
                                               decode(d.flg_status,
                                                      NULL,
                                                      decode(epis_transport.column_value,
                                                             'T',
                                                             pk_transfer_institution.get_grid_task_arrival(i_lang,
                                                                                                           i_prof,
                                                                                                           epis.id_episode),
                                                             'Y',
                                                             pk_ubu.get_date_transportation(epis.id_episode),
                                                             'N',
                                                             to_timestamp(NULL),
                                                             decode(epis.dt_first_inst_obs_tstz,
                                                                    NULL,
                                                                    epis.dt_begin_tstz_e,
                                                                    to_timestamp(NULL))),
                                                      g_discharge_flg_status_reopen,
                                                      decode(epis.dt_first_inst_obs_tstz,
                                                             NULL,
                                                             decode(epis_transport.column_value,
                                                                    'T',
                                                                    pk_transfer_institution.get_grid_task_arrival(i_lang,
                                                                                                                  i_prof,
                                                                                                                  epis.id_episode),
                                                                    'Y',
                                                                    pk_ubu.get_date_transportation(epis.id_episode),
                                                                    'N',
                                                                    to_timestamp(NULL),
                                                                    epis.dt_begin_tstz_e),
                                                             to_timestamp(NULL)),
                                                      to_timestamp(NULL)),
                                               i_prof) dt_begin,
                   decode(epis_transport.column_value, 'Y', g_ubu_color, 'T', 'X', 'N') color_dt_begin,
                   -- tempo de permanência no episódio de urgência após inicio do episódio de obs
                   -- calcula-se qd episódio de obs existe e é do tipo temporário
                   -- o tempo começa a contar desde a data de admissão
                   decode(epis_obs.flg_type,
                           -- se o tipo de epiódio for temporário então é um episódio de OBS
                           g_episode_flg_type_temp,
                           pk_date_utils.date_send_tsz(i_lang,
                                                       pk_date_utils.add_to_ltstz(epis_obs.dt_begin_tstz_e, 1),
                                                       i_prof),
                           
                           -- se não for episódio OBS PT validar se não é uma alta de internamento USA à espera de alta administrativa
                           decode(l_edis_admission,
                                  pk_alert_constant.g_yes,
                                  CASE
                                      WHEN (epis.flg_status_e IN (g_epis_active, g_epis_pending) AND d.id_discharge IS NOT NULL AND
                                           d.flg_status IN (g_discharge_flg_status_pend, g_discharge_flg_status_active)) THEN
                                       decode((SELECT COUNT(1)
                                                FROM TABLE(l_disch_reas_dest_admission) r
                                               WHERE d.id_disch_reas_dest = r.column_value),
                                              0,
                                              NULL,
                                              NULL,
                                              NULL,
                                              pk_date_utils.date_send_tsz(i_lang, nvl(d.dt_med_tstz, d.dt_pend_tstz), i_prof))
                                      ELSE
                                       NULL
                                  END,
                                  NULL)) inp_admission_time,
                   -- momento da alta pendente
                   decode(d.flg_status,
                          g_discharge_flg_status_pend,
                          pk_date_utils.date_send_tsz(i_lang, nvl(d.dt_med_tstz, d.dt_pend_tstz), i_prof),
                          NULL) disch_pend_time,
                   -- momento da alta.
                   -- Na alta médica o episódio de urgência fica com estado pending.
                   -- qd o episódio de inp/obs fica com tipo D-definitivo significa que o episódio de urgência já teve alta administrativa, logo d.ID_PROF_ADMIN não pode ser nulo
                   decode(epis.flg_status_e,
                          g_epis_pending,
                          decode(epis_obs.flg_type,
                                 g_episode_flg_type_temp,
                                 NULL,
                                 pk_date_utils.date_send_tsz(i_lang, nvl(d.dt_pend_active_tstz, d.dt_med_tstz), i_prof)),
                          NULL) disch_time,
                   decode(epis.flg_status_e,
                          g_epis_pending,
                          pk_date_utils.date_send_tsz(i_lang, dd.follow_up_date_tstz, i_prof),
                          NULL) dt_follow_up_date,
                   decode(epis.flg_status_e,
                          g_epis_pending,
                          decode(dd.follow_up_date_tstz,
                                 NULL,
                                 get_label_follow_up_date(i_lang, i_prof, d.id_disch_reas_dest, l_cat_type),
                                 l_msg_edis_grid_t054),
                          NULL) label_follow_up_date,
                   decode(epis.flg_status_e,
                          g_epis_pending,
                          pk_date_utils.date_char_hour_tsz(i_lang,
                                                           dd.follow_up_date_tstz,
                                                           i_prof.institution,
                                                           i_prof.software),
                          NULL) hour_mask_follow_up_date,
                   decode(epis.flg_status_e,
                          g_epis_pending,
                          pk_date_utils.date_chr_short_read_tsz(i_lang, dd.follow_up_date_tstz, i_prof),
                          NULL) date_mask_follow_up_date,
                   pk_edis_grid.get_admin_id_episode(i_lang, i_prof, epis.id_episode, epis_obs.id_episode) id_episode,
                   epis.id_patient,
                   g_sysdate_char dt_server,
                   pk_date_utils.date_send_tsz(i_lang,
                                               decode(epis_obs.flg_type,
                                                      g_episode_flg_type_temp,
                                                      least(nvl(epis.dt_first_obs_tstz, g_sysdate_tstz),
                                                            nvl(epis.dt_first_nurse_obs_tstz, g_sysdate_tstz),
                                                            nvl(epis.dt_first_inst_obs_tstz, g_sysdate_tstz)),
                                                      decode(epis.flg_status_e,
                                                             g_epis_pending,
                                                             d.dt_med_tstz,
                                                             epis.dt_begin_tstz_e)),
                                               i_prof) rank,
                   decode(epis_transport.column_value, 'NULL', l_shortcut_disch, l_shortcut_pat_arrival) shortcut,
                   -- José Brito 22/04/2008 Devolver FLG_CANCEL que indica se o episódio é temporário e se pode ser cancelado
                   --pk_visit.check_flg_cancel(i_lang, i_prof, epis.id_episode) flg_cancel,
                   'Y' flg_cancel,
                   -- José Brito 22/04/2008 Devolver FLG_STATUS para indicar estado do episódio
                   epis.flg_status_e flg_status,
                   -- status_rank necessário para forçar os cancelados a surgir em último
                   0                     status_rank,
                   epis.id_dep_clin_serv,
                   -- José Brito 18/11/2008 ALERT-9805 Campo usado apenas para ordenação na grelha do admin
                   pk_date_utils.date_send_tsz(i_lang, epis.dt_begin_tstz_e, i_prof) dt_admin,
                   -- José Brito 24/02/2010 ALERT-721 ESI Triage
                   decode(pk_transfer_institution.check_epis_transfer(epis.id_episode),
                          0,
                          NULL,
                          (SELECT pk_fast_track.get_fast_track_icon(i_lang,
                                                                    i_prof,
                                                                    epis.id_episode,
                                                                    epis.id_fast_track,
                                                                    epis.id_triage_color,
                                                                    -- Only show icon if patient was/is to be transfered
                                                                    g_icon_ft_transfer,
                                                                    NULL)
                             FROM dual)) fast_track_icon,
                   decode(epis.triage_acuity, g_ft_color, g_ft_triage_white, g_ft_color) fast_track_color,
                   g_ft_status fast_track_status,
                   NULL fast_track_desc,
                   (SELECT pk_edis_triage.get_epis_esi_level(i_lang, i_prof, epis.id_episode, epis.id_triage_color)
                      FROM dual) esi_level,
                   --Gisela Couto 04-09-2014  ALERT-284142 Major incident icon
                   (SELECT pk_adt_core.check_bulk_admission_episode(i_lang       => i_lang,
                                                                    i_prof       => i_prof,
                                                                    i_id_episode => epis.id_episode)
                      FROM dual) pat_major_inc_icon
              FROM alert.v_episode_act_pend epis
              LEFT JOIN (SELECT *
                           FROM discharge
                          WHERE flg_status IN (g_discharge_flg_status_active, g_discharge_flg_status_pend)) d
                ON d.id_episode = epis.id_episode
              LEFT JOIN (SELECT *
                           FROM care_stage cs
                          WHERE cs.flg_active = g_yes
                            AND cs.flg_stage = g_care_stage_wrg) cs
                ON cs.id_episode = epis.id_episode
              LEFT JOIN discharge_detail dd
                ON dd.id_discharge = d.id_discharge
              JOIN prof_dcs1
                ON prof_dcs1.id_software = epis.id_software
              LEFT JOIN (SELECT /*+ opt_estimate(table t rows=1 ) */
                          *
                           FROM TABLE(pk_transfer_institution.tf_most_recent_transfer(i_lang, i_prof)) t
                          WHERE ((t.id_institution_origin = i_prof.institution AND t.flg_status IN ('T', 'R')) OR
                                (t.id_institution_dest = i_prof.institution AND t.flg_status = 'T'))) ti
                ON ti.id_episode = epis.id_episode
            -- lg 2007-03-09 considera-se apenas os temporários de obs pq são os correspondentes de urg que ficam na coluna dos deitados.
              LEFT JOIN v_episode_act_pend epis_obs
                ON epis_obs.id_prev_episode = epis.id_episode
               AND epis_obs.flg_type = g_episode_flg_type_temp
               AND epis_obs.id_epis_type = pk_alert_constant.g_epis_type_inpatient
            --verificar origem do paciente
              JOIN (SELECT /* + cardinality( t 1 ) */
                     *
                      FROM TABLE(table_varchar('N', 'Y', 'T', 'NULL'))) epis_transport
                ON epis_transport.column_value =
                   decode((SELECT /* + cardinality( t 1 ) */
                           t.id_institution_dest
                            FROM TABLE(pk_transfer_institution.tf_most_recent_transfer(i_lang, i_prof, epis.id_episode)) t
                           WHERE t.flg_status = 'F'),
                          i_prof.institution,
                          'T',
                          NULL,
                          decode(epis.id_prev_episode,
                                 NULL,
                                 'NULL',
                                 decode(pk_ubu.get_episode_transportation(epis.id_episode, i_prof, l_limit),
                                        NULL,
                                        'NULL',
                                        'N',
                                        'N',
                                        'Y',
                                        'Y')))
            --
             WHERE epis.id_software = i_prof.software
                  -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer do tipo EHR
               AND epis.flg_ehr = g_flg_ehr_normal
                  -- José Brito 14/07/2008 Mostrar os episódios dos serviços aos quais o administrativo está alocado, ...
                  -- ... caso contrário mostra todos os episódios.
               AND ((l_count = 0 AND 0 = prof_dcs1.id_dep_clin_serv) OR
                   (l_count > 0 AND
                   coalesce(decode(ti.flg_status,
                                     'T',
                                     decode(ti.id_institution_dest, i_prof.institution, ti.id_dep_clin_serv, NULL),
                                     NULL),
                              epis.id_dep_clin_serv,
                              0) = prof_dcs1.id_dep_clin_serv))
                  -- lg 2007-03-08 qd o episódio de obs tem alta clínica não mostra o episódio de URG pq só faz sentido o adm dar alta ao episódio de obs
                  -- pode existir uma alta clínica no obs cancelada. a reaberta não interessa pq o episódio de urg fica inactivo qd o o de obs for reaberto
               AND NOT EXISTS
             (SELECT 0
                      FROM discharge d_obs
                     WHERE d_obs.id_episode = epis_obs.id_episode
                       AND d_obs.flg_status = 'A')
               AND (epis_obs.dt_first_inst_obs_tstz IS NOT NULL
                   -- ALERT-8124 José Brito 22/10/2008
                   OR NOT EXISTS
                    (SELECT /* + cardinality( t 1 ) */
                      1
                       FROM TABLE(pk_transfer_institution.tf_most_recent_transfer(i_lang, i_prof, epis_obs.id_episode)) t
                      WHERE flg_status = 'F'
                        AND t.id_institution_dest = i_prof.institution)
                   --
                    OR epis_obs.id_episode IS NULL)
               AND NOT EXISTS
             (SELECT /* + cardinality( ti 1 ) */
                     0
                      FROM TABLE(pk_transfer_institution.tf_most_recent_transfer(i_lang, i_prof, epis_obs.id_episode)) ti
                     WHERE ti.id_institution_origin = i_prof.institution
                       AND ti.flg_status IN (g_transfer_inst_transp, g_transfer_inst_req)
                    UNION ALL
                    SELECT /* + cardinality( ti 1 ) */
                     1
                      FROM TABLE(pk_transfer_institution.tf_most_recent_transfer(i_lang, i_prof, epis_obs.id_episode)) ti
                     WHERE ti.id_institution_dest = i_prof.institution
                       AND ti.flg_status = g_transfer_inst_transp)
                  -- episódios sem atendimento clínico.
                  -- Os episódios temporários criados por clínicos não aparecem ao administrativo porque na criação do episódio dt_first_obs fica preenchido
               AND ((((epis.dt_first_inst_obs_tstz IS NULL OR cs.id_care_stage IS NOT NULL) AND d.id_discharge IS NULL
                   -- episódios com alta médica e sem alta administrativa, não é necessário restringir por d.id_prof_admin porque pela alta administrativa o episódio fica inactivo
                   OR d.flg_status IN (g_discharge_flg_status_active, g_discharge_flg_status_pend)) AND
                   epis.id_institution = i_prof.institution) OR ti.id_episode IS NOT NULL AND d.id_discharge IS NULL)
            
            UNION ALL
            SELECT l_msg_edis_common_t003 origem,
                   g_no_triage_color acuity,
                   g_no_triage_color_text color_text,
                   g_color_rank rank_acuity,
                   (SELECT pk_patient.get_pat_age(i_lang, epis.id_patient, i_prof)
                      FROM dual) pat_age,
                   (SELECT pk_patient.get_julian_age(i_lang, epis.id_patient)
                      FROM dual) pat_age_for_order_by,
                   (SELECT pk_patient.get_gender(i_lang, gender) gender
                      FROM patient pat
                     WHERE pat.id_patient = epis.id_patient) gender,
                   (SELECT pk_patphoto.get_pat_photo(i_lang, i_prof, epis.id_patient, epis.id_episode, NULL)
                      FROM dual) photo,
                   (SELECT pk_patient.get_pat_name(i_lang, i_prof, epis.id_patient, epis.id_episode)
                      FROM dual) name_pat,
                   (SELECT pk_patient.get_pat_name_to_sort(i_lang, i_prof, epis.id_patient, epis.id_episode, NULL)
                      FROM dual) name_pat_sort,
                   (SELECT pk_adt.get_pat_non_disc_options(i_lang, i_prof, epis.id_patient)
                      FROM dual) pat_ndo,
                   (SELECT pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, epis.id_patient)
                      FROM dual) pat_nd_icon,
                   (SELECT num_clin_record
                      FROM clin_record cr
                     WHERE cr.id_patient = epis.id_patient
                       AND cr.id_institution = i_prof.institution
                       AND rownum < 2) num_clin_record,
                   NULL care_stage,
                   NULL care_stage_rank,
                   (SELECT pk_doc.get_num_episode_images(epis.id_episode, epis.id_patient)
                      FROM dual) attaches,
                   (SELECT pk_service_transfer.get_transfer_status_icon(i_lang,
                                                                        i_prof,
                                                                        epis.id_episode,
                                                                        pk_service_transfer.g_transfer_flg_hospital_h)
                      FROM dual) transfer_req_time,
                   -- data de efectivação
                   pk_date_utils.date_send_tsz(i_lang,
                                               decode(d.id_discharge,
                                                      NULL,
                                                      decode(epis_transport.column_value,
                                                             'T',
                                                             pk_transfer_institution.get_grid_task_arrival(i_lang,
                                                                                                           i_prof,
                                                                                                           epis.id_episode),
                                                             'Y',
                                                             pk_ubu.get_date_transportation(epis.id_episode),
                                                             'N',
                                                             to_timestamp(NULL),
                                                             decode(epis_urg.flg_status,
                                                                    g_epis_inactive,
                                                                    to_timestamp(NULL),
                                                                    decode(epis.dt_first_inst_obs_tstz,
                                                                           NULL,
                                                                           epis.dt_begin_tstz_e,
                                                                           to_timestamp(NULL)))),
                                                      to_timestamp(NULL)),
                                               i_prof) dt_begin,
                   decode(epis_transport.column_value, 'Y', g_ubu_color, 'T', 'X', 'N') color_dt_begin,
                   -- tempo de permanência no episódio de urgência após inicio do episódio de obs
                   -- calcula-se qd episódio de obs existe e é do tipo temporário
                   decode(epis_urg.flg_status,
                          g_epis_inactive,
                          decode(d.flg_status,
                                 NULL,
                                 pk_date_utils.date_send_tsz(i_lang,
                                                             pk_date_utils.add_to_ltstz(epis.dt_begin_tstz_e, 1),
                                                             i_prof))) inp_admission_time,
                   -- momento da alta pendente
                   decode(d.flg_status,
                          g_discharge_flg_status_pend,
                          pk_date_utils.date_send_tsz(i_lang, nvl(d.dt_med_tstz, d.dt_pend_tstz), i_prof),
                          NULL) disch_pend_time,
                   -- momento da alta. Na alta médica o episódio de obs mantêm-se activo
                   decode(d.flg_status,
                          g_discharge_flg_status_active,
                          pk_date_utils.date_send_tsz(i_lang, d.dt_med_tstz, i_prof),
                          NULL) disch_time,
                   decode(epis.flg_status_e,
                          g_epis_pending,
                          pk_date_utils.date_send_tsz(i_lang, dd.follow_up_date_tstz, i_prof),
                          NULL) dt_follow_up_date,
                   decode(epis_urg.flg_status,
                          g_epis_inactive,
                          decode(d.flg_status,
                                 NULL,
                                 get_label_follow_up(i_lang, i_prof, epis_urg.id_episode, l_cat_type))) label_follow_up_date,
                   decode(epis.flg_status_e,
                          g_epis_pending,
                          pk_date_utils.date_char_hour_tsz(i_lang,
                                                           dd.follow_up_date_tstz,
                                                           i_prof.institution,
                                                           i_prof.software),
                          NULL) hour_mask_follow_up_date,
                   decode(epis.flg_status_e,
                          g_epis_pending,
                          pk_date_utils.date_chr_short_read_tsz(i_lang, dd.follow_up_date_tstz, i_prof),
                          NULL) date_mask_follow_up_date,
                   epis.id_episode,
                   epis.id_patient id_patient,
                   g_sysdate_char dt_server,
                   pk_date_utils.date_send_tsz(i_lang,
                                               decode(epis.flg_status_e,
                                                      g_epis_pending,
                                                      d.dt_med_tstz,
                                                      epis.dt_begin_tstz_e),
                                               i_prof) rank,
                   l_shortcut_disch shortcut,
                   -- José Brito 22/04/2008 Devolver FLG_CANCEL que indica se o episódio é temporário e se pode ser cancelado
                   (SELECT pk_visit.check_flg_cancel(i_lang, i_prof, epis.id_episode)
                      FROM dual) flg_cancel,
                   -- José Brito 22/04/2008 Devolver FLG_STATUS para indicar estado do episódio
                   epis.flg_status_e flg_status,
                   -- status_rank necessário para forçar os cancelados a surgir em último
                   0                     status_rank,
                   epis.id_dep_clin_serv,
                   -- José Brito 18/11/2008 ALERT-9805 Campo usado apenas para ordenação na grelha do admin
                   (SELECT pk_date_utils.date_send_tsz(i_lang, epis.dt_begin_tstz_e, i_prof)
                      FROM dual) dt_admin,
                   -- José Brito 24/02/2010 ALERT-721 ESI Triage
                   NULL fast_track_icon,
                   NULL fast_track_color,
                   NULL fast_track_status,
                   NULL fast_track_desc,
                   NULL esi_level,
                   --Gisela Couto 04-09-2014  ALERT-284142 Major incident icon
                   (SELECT pk_adt_core.check_bulk_admission_episode(i_lang       => i_lang,
                                                                    i_prof       => i_prof,
                                                                    i_id_episode => epis.id_episode)
                      FROM dual) pat_major_inc_icon
              FROM v_episode_act_pend epis
              LEFT JOIN (SELECT *
                           FROM discharge
                          WHERE flg_status IN (g_discharge_flg_status_active, g_discharge_flg_status_pend)) d
                ON d.id_episode = epis.id_episode
              LEFT JOIN discharge_detail dd
                ON dd.id_discharge = d.id_discharge
              LEFT JOIN episode epis_urg
                ON epis_urg.id_episode = epis.id_prev_episode
             AND (SELECT pk_episode.get_soft_by_epis_type(epis_urg.id_epis_type, i_prof.institution)
                    FROM dual) = i_prof.software
              LEFT JOIN (SELECT *
                           FROM TABLE(pk_transfer_institution.tf_most_recent_transfer(i_lang, i_prof)) t
                          WHERE ((t.id_institution_origin = i_prof.institution AND t.flg_status IN ('T', 'R')) OR
                                (t.id_institution_dest = i_prof.institution AND t.flg_status = 'T'))) ti
                ON ti.id_episode = epis.id_episode
              JOIN prof_dcs2
                ON prof_dcs2.id_software = epis.id_software
             AND ((l_count = 0 --
             AND nvl(decode(ti.flg_status,
                                  'T',
                                  decode(ti.id_institution_dest, i_prof.institution, ti.id_dep_clin_serv, NULL),
                                  NULL),
                           epis.id_dep_clin_serv) = prof_dcs2.id_dcs_obs) --
             OR (l_count > 0 --
             AND nvl(decode(ti.flg_status,
                                     'T',
                                     decode(ti.id_institution_dest, i_prof.institution, ti.id_dep_clin_serv, NULL),
                                     NULL),
                              epis.id_dep_clin_serv) = prof_dcs2.id_dep_clin_serv))
              JOIN TABLE (table_varchar('N', 'Y', 'T', 'NULL')) epis_transport
                ON epis_transport.column_value =
             decode((SELECT t.id_institution_dest
                      FROM TABLE(pk_transfer_institution.tf_most_recent_transfer(i_lang, i_prof, epis.id_episode)) t
                     WHERE t.flg_status = 'F'),
                    i_prof.institution,
                    'T',
                    NULL,
                    decode(epis.id_prev_episode,
                           NULL,
                           'NULL',
                           decode(pk_ubu.get_episode_transportation(epis.id_episode, i_prof, l_limit),
                                  NULL,
                                  'NULL',
                                  'N',
                                  'N',
                                  'Y',
                                  'Y')))
            -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer do tipo EHR
             WHERE epis.flg_ehr = g_flg_ehr_normal
             AND
             ((epis.dt_first_inst_obs_tstz IS NULL AND d.id_discharge IS NULL
             -- ALERT-8124 José Brito 22/10/2008
             AND (epis_urg.id_episode IS NULL OR epis_transport.column_value = 'T') OR
             --
             d.flg_status IN (g_discharge_flg_status_active, g_discharge_flg_status_pend) AND
             epis.id_institution = i_prof.institution) OR (ti.id_episode IS NOT NULL AND d.id_discharge IS NULL) OR
             (epis_urg.flg_status = g_epis_inactive AND d.id_discharge IS NULL))
            
            UNION ALL
            -- José Brito 21/04/2008: Mostrar episódios cancelados (dentro do período definido pela instituição)
            SELECT (SELECT decode(epis_transport.column_value,
                                  'NULL',
                                  -- José Brito 02/06/2008 Para os episódios cancelados, o descritivo de origem tem de ser obtido
                                  -- desta forma, uma vez que esta query devolve os episódios de URG/CS/OBS.
                                  decode(epis.id_epis_type,
                                         g_epis_type_urg,
                                         l_msg_edis_common_t002,
                                         g_epis_type_obs,
                                         l_msg_edis_common_t003,
                                         l_msg_edis_common_t004),
                                  l_msg_edis_common_t004)
                      FROM dual) origem,
                   ei.triage_acuity acuity,
                   ei.triage_color_text color_text,
                   ei.triage_rank_acuity rank_acuity,
                   (SELECT pk_patient.get_pat_age(i_lang, epis.id_patient, i_prof)
                      FROM dual) pat_age,
                   (SELECT pk_patient.get_julian_age(i_lang, epis.id_patient)
                      FROM dual) pat_age_for_order_by,
                   (SELECT pk_patient.get_gender(i_lang, gender) gender
                      FROM patient pat
                     WHERE pat.id_patient = epis.id_patient) gender,
                   (SELECT pk_patphoto.get_pat_photo(i_lang, i_prof, epis.id_patient, epis.id_episode, NULL)
                      FROM dual) photo,
                   (SELECT pk_patient.get_pat_name(i_lang, i_prof, epis.id_patient, epis.id_episode)
                      FROM dual) name_pat,
                   -- ALERT-102882 Patient name used for sorting
                   (SELECT pk_patient.get_pat_name_to_sort(i_lang, i_prof, epis.id_patient, epis.id_episode, NULL)
                      FROM dual) name_pat_sort,
                   (SELECT pk_adt.get_pat_non_disc_options(i_lang, i_prof, epis.id_patient)
                      FROM dual) pat_ndo,
                   (SELECT pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, epis.id_patient)
                      FROM dual) pat_nd_icon,
                   (SELECT num_clin_record
                      FROM clin_record cr
                    
                     WHERE cr.id_patient = epis.id_patient
                       AND cr.id_institution = i_prof.institution
                       AND rownum < 2) num_clin_record,
                   NULL care_stage,
                   NULL care_stage_rank,
                   (SELECT pk_doc.get_num_episode_images(epis.id_episode, epis.id_patient)
                      FROM dual) attaches,
                   NULL transfer_req_time,
                   NULL dt_begin,
                   NULL color_dt_begin,
                   pk_date_utils.date_send_tsz(i_lang, to_timestamp(NULL), i_prof) inp_admission_time,
                   NULL disch_pend_time,
                   NULL disch_time,
                   NULL dt_follow_up_date,
                   NULL label_follow_up_date,
                   NULL hour_mask_follow_up_date,
                   NULL date_mask_follow_up_date,
                   epis.id_episode,
                   epis.id_patient id_patient,
                   g_sysdate_char dt_server,
                   (SELECT pk_date_utils.date_send_tsz(i_lang, epis.dt_begin_tstz, i_prof)
                      FROM dual) rank,
                   decode(epis_transport.column_value, 'NULL', l_shortcut_disch, l_shortcut_pat_arrival) shortcut,
                   -- José Brito 22/04/2008 Devolver FLG_CANCEL (neste caso, como são episódios já cancelados, devolve-se 'N')
                   'N' flg_cancel,
                   -- José Brito 22/04/2008 Devolver FLG_STATUS para indicar estado do episódio
                   epis.flg_status flg_status,
                   -- Forçar os cancelados a surgir em último
                   1                   status_rank,
                   ei.id_dep_clin_serv,
                   -- José Brito 18/11/2008 ALERT-9805 Campo usado apenas para ordenação na grelha do admin
                   (SELECT pk_date_utils.date_send_tsz(i_lang, epis.dt_begin_tstz, i_prof)
                      FROM dual) dt_admin,
                   -- José Brito 24/02/2010 ALERT-721 ESI Triage
                   decode((SELECT pk_transfer_institution.check_epis_transfer(epis.id_episode)
                            FROM dual),
                          0,
                          NULL,
                          (SELECT pk_fast_track.get_fast_track_icon(i_lang,
                                                                    i_prof,
                                                                    epis.id_episode,
                                                                    NULL,
                                                                    ei.id_triage_color,
                                                                    -- Only show icon if patient was/is to be transfered
                                                                    g_icon_ft_transfer,
                                                                    NULL)
                             FROM dual)) fast_track_icon,
                   decode(ei.triage_acuity, g_ft_color, g_ft_triage_white, g_ft_color) fast_track_color,
                   g_ft_status fast_track_status,
                   NULL fast_track_desc,
                   (SELECT pk_edis_triage.get_epis_esi_level(i_lang, i_prof, epis.id_episode, ei.id_triage_color)
                      FROM dual) esi_level,
                   --Gisela Couto 04-09-2014  ALERT-284142 Major incident icon
                   (SELECT pk_adt_core.check_bulk_admission_episode(i_lang       => i_lang,
                                                                    i_prof       => i_prof,
                                                                    i_id_episode => epis.id_episode)
                      FROM dual) pat_major_inc_icon
              FROM (SELECT e.*,
                           (SELECT pk_episode.get_soft_by_epis_type(e.id_epis_type, i_prof.institution)
                              FROM dual) soft_by_epis_type
                      FROM episode e
                     WHERE e.flg_status = 'C'
                       AND e.flg_ehr = g_flg_ehr_normal
                       AND e.dt_cancel_tstz > CAST(current_timestamp - numtodsinterval(l_epis_c_display / 24, 'DAY') AS
                                                   TIMESTAMP WITH LOCAL TIME ZONE)
                       AND e.id_institution = i_prof.institution) epis
              JOIN epis_info ei
                ON ei.id_episode = epis.id_episode
            -- José Brito 30/05/2008 Evitar que episódios retriados, que foram cancelados,
            -- apareçam repetidos na grelha do administrativo
              JOIN triage_color tco
                ON tco.id_triage_color = ei.id_triage_color
              JOIN prof_dcs3
                ON prof_dcs3.id_software = epis.soft_by_epis_type
              JOIN (SELECT *
                      FROM TABLE(table_varchar('N', 'Y', 'T', 'NULL'))) epis_transport
                ON epis_transport.column_value =
             decode((SELECT t.id_institution_dest
                      FROM TABLE(pk_transfer_institution.tf_most_recent_transfer(i_lang, i_prof, epis.id_episode)) t
                     WHERE t.flg_status = 'F'),
                    i_prof.institution,
                    'T',
                    NULL,
                    decode(epis.id_prev_episode,
                           NULL,
                           'NULL',
                           decode(pk_ubu.get_episode_transportation(epis.id_episode, i_prof, l_limit),
                                  NULL,
                                  'NULL',
                                  'N',
                                  'N',
                                  'Y',
                                  'Y')))
            --
              LEFT JOIN (SELECT * /*+ opt_estimate(table t rows=1) */
                           FROM TABLE(pk_transfer_institution.tf_most_recent_transfer(i_lang, i_prof)) t
                          WHERE ((t.id_institution_origin = i_prof.institution AND t.flg_status IN ('T', 'R')) OR
                                (t.id_institution_dest = i_prof.institution AND t.flg_status = 'T'))) ti
                ON ti.id_episode = epis.id_episode
            --
             WHERE ((l_count = 0 AND
             ((epis.id_epis_type IN (g_epis_type_urg, g_epis_type_ubu) AND prof_dcs3.id_dep_clin_serv = 0) OR
             (epis.id_epis_type = g_epis_type_obs AND prof_dcs3.id_dcs_obs = ei.id_dep_clin_serv))) OR
             (l_count > 0 AND nvl(ei.id_dep_clin_serv, 0) = prof_dcs3.id_dep_clin_serv))
             ORDER BY status_rank, rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_types.open_my_cursor(o_grid);
            RETURN error_handling(i_lang,
                                  'GET_GRID_ALL_PAT_ADMIN',
                                  g_error || ' / ' || l_error.err_desc,
                                  SQLERRM,
                                  FALSE,
                                  o_error);
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_grid);
            RETURN error_handling(i_lang, 'GET_GRID_ALL_PAT_ADMIN', g_error, SQLERRM, FALSE, o_error);
    END get_grid_all_pat_admin;

    PROCEDURE initialize_params
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        k_lang             CONSTANT NUMBER(24) := 1;
        k_prof_id          CONSTANT NUMBER(24) := 2;
        k_prof_institution CONSTANT NUMBER(24) := 3;
        k_prof_software    CONSTANT NUMBER(24) := 4;
        k_episode          CONSTANT NUMBER(24) := 5;
        k_patient          CONSTANT NUMBER(24) := 6;
    
        g_yes                    CONSTANT VARCHAR2(1 CHAR) := 'Y';
        g_epis_flg_status_active CONSTANT VARCHAR2(1 CHAR) := 'A';
    
        l_msg_edis_grid_m003 CONSTANT sys_message.code_message%TYPE := 'EDIS_GRID_M003';
        l_prof               CONSTANT profissional := profissional(i_context_ids(k_prof_id),
                                                                   i_context_ids(k_prof_institution),
                                                                   i_context_ids(k_prof_software));
        l_lang               CONSTANT language.id_language%TYPE := i_context_ids(k_lang);
        l_patient            CONSTANT patient.id_patient%TYPE := i_context_ids(k_patient);
        l_episode            CONSTANT episode.id_episode%TYPE := i_context_ids(k_episode);
    
    BEGIN
    
        CASE i_name
            WHEN 'i_lang' THEN
                o_id := l_lang;
            WHEN 'i_prof_id' THEN
                o_id := l_prof.id;
            WHEN 'i_prof_institution' THEN
                o_id := l_prof.institution;
            WHEN 'i_prof_software' THEN
                o_id := l_prof.software;
            WHEN 'i_patient' THEN
                o_id := l_patient;
            WHEN 'i_episode' THEN
                o_id := l_episode;
            WHEN 'l_prof_cat' THEN
                o_vc2 := pk_edis_list.get_prof_cat(l_prof);
            WHEN 'l_hand_off_type' THEN
                pk_hand_off_core.get_hand_off_type(l_lang, l_prof, o_vc2);
            WHEN 'g_yes' THEN
                o_vc2 := g_yes;
            WHEN 'l_msg_edis_grid_m003' THEN
                o_vc2 := l_msg_edis_grid_m003;
            WHEN 'g_epis_flg_status_active' THEN
                o_vc2 := g_epis_flg_status_active;
        END CASE;
    END initialize_params;

    --
    /**********************************************************************************************
    * Verify if flg_letter is to be used in the ORDER BY clause.
    *
    * @param i_prof                   professional, software and institution ids
    *
    * @return                         'Y' is to be used, 'N' otherwise
    *
    * @author                         Alexandre Santos
    * @version                        1.0
    * @since                          2009/05/14
    **********************************************************************************************/
    FUNCTION orderby_flg_letter(i_prof IN profissional) RETURN VARCHAR2 IS
        l_return VARCHAR2(1);
    BEGIN
        g_error := 'GET EDIS_GRID_ORDER_BY_FLG_LETTER';
        IF nvl(pk_sysconfig.get_config('EDIS_GRID_ORDER_BY_FLG_LETTER', i_prof), pk_alert_constant.g_yes) =
           pk_alert_constant.g_yes
        THEN
            l_return := pk_alert_constant.g_yes;
        ELSE
            l_return := pk_alert_constant.g_no;
        END IF;
    
        RETURN l_return;
    END orderby_flg_letter;
    --
    /**********************************************************************************************
    * Gets all configs that affect the patients grid
    *
    * @param i_lang                   language ID
    * @param i_code_cf                configurations code array
    * @param i_prof                   professional, software and institution ids
    * @param o_msg_cf                 grid configurations
    * @param o_label_tb_name_col      Tracking view: label for the patient's name column showing origin or chief complaint
    * @param o_label_responsibles     Label for the patient's responsibles, showing medical teams or the resident physician
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         José Silva
    * @version                        1.0
    * @since                          2009/11/12
    *
    * @alter                          José Brito
    * @version                        2.6.0.5
    * @since                          2011/01/26
    **********************************************************************************************/
    FUNCTION get_grid_config
    (
        i_lang               IN language.id_language%TYPE,
        i_code_cf            IN table_varchar,
        i_prof               IN profissional,
        o_msg_cf             OUT pk_types.cursor_type,
        o_label_tb_name_col  OUT VARCHAR2,
        o_label_responsibles OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_profile_template profile_template.id_profile_template%TYPE;
        l_internal_error EXCEPTION;
    
    BEGIN
        g_error               := 'GET_PROFILE_TEMPLATE';
        l_id_profile_template := pk_prof_utils.get_prof_profile_template(i_prof);
    
        g_error := 'GET HEADER LABELS';
        pk_alertlog.log_debug(g_error);
        IF NOT get_grid_labels(i_lang               => i_lang,
                               i_prof               => i_prof,
                               o_label_tb_name_col  => o_label_tb_name_col,
                               o_label_responsibles => o_label_responsibles,
                               o_error              => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        g_error := 'OPEN O_MSG_CF';
        OPEN o_msg_cf FOR
            SELECT column_value id_sys_config,
                   pk_sysconfig.get_config(column_value, i_prof.institution, i_prof.software) VALUE
              FROM TABLE(CAST(i_code_cf AS table_varchar))
            UNION ALL
            SELECT 'PROFILES_DISCH_PEND_GRID' id_sys_config,
                   decode(instr(pk_sysconfig.get_config('PROFILES_DISCH_PEND_GRID', i_prof.institution, i_prof.software),
                                '|' || l_id_profile_template || '|'),
                          0,
                          pk_alert_constant.g_no,
                          pk_alert_constant.g_yes) VALUE
              FROM dual;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_types.open_my_cursor(o_msg_cf);
            RETURN error_handling(i_lang, 'GET_GRID_CONFIG', g_error, SQLERRM, FALSE, o_error);
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_msg_cf);
            RETURN error_handling(i_lang, 'GET_GRID_CONFIG', g_error, SQLERRM, FALSE, o_error);
    END get_grid_config;

    /**********************************************************************************************
    * Gets the header labels for the patient grids for the patients and responsibles columns.
    *
    * @param i_lang                   language ID
    * @param i_prof                   professional, software and institution ids
    * @param o_label_tb_name_col      Tracking view: label for the patient's name column showing origin or chief complaint
    * @param o_label_responsibles     Label for the patient's responsibles, showing medical teams or the resident physician
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         José Brito
    * @version                        2.6.0.5
    * @since                          2011/01/26
    **********************************************************************************************/
    FUNCTION get_grid_labels
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        o_label_tb_name_col  OUT VARCHAR2,
        o_label_responsibles OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'GET_GRID_LABELS';
    
        l_config_show_complaint CONSTANT sys_config.id_sys_config%TYPE := 'TRACKING_VIEW_SHOW_COMPLAINT';
        l_config_show_resident  CONSTANT sys_config.id_sys_config%TYPE := 'GRIDS_SHOW_RESIDENT';
    
        l_show_complaint_tb       sys_config.value%TYPE;
        l_show_resident_physician sys_config.value%TYPE;
    
    BEGIN
        g_error                   := 'GET CONFIGURATIONS';
        l_show_complaint_tb       := pk_sysconfig.get_config(i_code_cf => l_config_show_complaint, i_prof => i_prof);
        l_show_resident_physician := pk_sysconfig.get_config(i_code_cf => l_config_show_resident, i_prof => i_prof);
    
        g_error := 'SET LABELS';
        -- Show complaint or origin in Tracking View
        CASE l_show_complaint_tb
            WHEN pk_alert_constant.g_yes THEN
                o_label_tb_name_col := 'EDIS_GRID_T003'; --pk_message.get_message(i_lang => i_lang, i_code_mess => 'EDIS_GRID_T003');
            ELSE
                o_label_tb_name_col := 'TRACK_VIEW_T012'; --pk_message.get_message(i_lang => i_lang, i_code_mess => 'TRACK_VIEW_T012');
        END CASE;
    
        -- Show medical teams or resident physician in patient grids
        CASE l_show_resident_physician
            WHEN pk_alert_constant.g_yes THEN
                o_label_responsibles := 'EDIS_GRID_T061'; --pk_message.get_message(i_lang => i_lang, i_code_mess => );
            ELSE
                o_label_responsibles := 'EDIS_GRID_T060'; --pk_message.get_message(i_lang => i_lang, i_code_mess => );
        END CASE;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_grid_labels;

    --
    /**********************************************************************************************
    * Difference between current date and beging of episode
    *
    * @param i_lang                   Language ID
    * @param i_dt_begin_epis          Episode begin date
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Alexandre Santos
    * @version                        1.0
    * @since                          2010/09/03
    **********************************************************************************************/
    FUNCTION get_los
    (
        i_lang          IN language.id_language%TYPE,
        i_dt_begin_epis IN episode.dt_begin_tstz%TYPE
    ) RETURN NUMBER IS
        l_func_name VARCHAR2(30) := 'GET_COMPLICATION';
        --
        l_days_diff NUMBER;
        l_error     t_error_out;
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF NOT pk_date_utils.get_timestamp_diff(i_lang        => i_lang,
                                                i_timestamp_1 => current_timestamp,
                                                i_timestamp_2 => i_dt_begin_epis,
                                                o_days_diff   => l_days_diff,
                                                o_error       => l_error)
        THEN
            RETURN NULL;
        END IF;
    
        RETURN l_days_diff;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_los;
    --
    /**********************************************************************************************
    * Gets either the EDIS or OBS id_episode depending on configurations
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_episode             EDIS id_episode
    * @param i_id_episode_obs         OBS id_episode
    *
    * @return                         the episode ID that must be shown in the admin grid
    *
    * @author                         José Silva
    * @version                        2.5.1.2.1
    * @since                          2011/02/04
    **********************************************************************************************/
    FUNCTION get_admin_id_episode
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_id_episode_obs IN episode.id_episode%TYPE
    ) RETURN episode.id_episode%TYPE IS
    
    BEGIN
        g_error := 'GET ID_EPISODE';
        IF pk_sysconfig.get_config('ADMIN_SHOW_OBS_EPISODE', i_prof) = pk_alert_constant.g_yes
           AND i_id_episode_obs IS NOT NULL
        THEN
            RETURN i_id_episode_obs;
        ELSE
            RETURN i_id_episode;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_admin_id_episode;
    --
    /**********************************************************************************************
    * Gets the actions for the EDIS grids
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional, software and institution Ids
    * @param i_subject                Actions Subject
    * @param i_from_state             OBS State
    *
    * @param o_actions                Actions cursor
    *
    * @return                         true/false
    *
    * @author                         Sergio Dias
    * @version                        2.6.3.5.1
    * @since                          6/6/2013
    **********************************************************************************************/
    FUNCTION get_actions_edis_grids
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_subject    IN action.subject%TYPE,
        i_from_state IN action.from_state%TYPE,
        o_actions    OUT p_action_cur,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_original_actions   t_coll_action;
        l_show_waiting_room  sys_config.value%TYPE;
        l_wr_external_system sys_config.value%TYPE;
        l_sys_cfg_show_waiting_room  CONSTANT sys_config.id_sys_config%TYPE := 'WL_WAITING_ROOM_AVAILABLE';
        l_sys_cfg_wr_external_system CONSTANT sys_config.id_sys_config%TYPE := 'WAITING_ROOM_EXTERNAL_SYSTEM';
    BEGIN
        g_error              := 'GET WL_WAITING_ROOM_AVAILABLE SYS_CONFIG';
        l_show_waiting_room  := pk_sysconfig.get_config(l_sys_cfg_show_waiting_room, i_prof);
        l_wr_external_system := pk_sysconfig.get_config(l_sys_cfg_wr_external_system, i_prof);
    
        g_error            := 'GET CURSOR l_original_actions';
        l_original_actions := pk_action.tf_get_actions(i_lang, i_prof, i_subject, i_from_state);
    
        g_error := 'GET CURSOR o_actions';
        OPEN o_actions FOR
            SELECT act.*
              FROM TABLE(l_original_actions) act
             WHERE l_show_waiting_room = pk_alert_constant.g_yes
                OR l_wr_external_system = pk_alert_constant.g_yes
                OR (l_show_waiting_room = pk_alert_constant.g_no AND act.action NOT IN ('CALL'));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_EDIS_GRID',
                                              'GET_ACTIONS_EDIS_GRIDS',
                                              o_error);
            pk_types.open_my_cursor(o_actions);
        
            RETURN FALSE;
    END get_actions_edis_grids;

    --

    FUNCTION get_length_of_stay_color
    (
        i_prof  IN profissional,
        i_hours IN NUMBER
        
    ) RETURN VARCHAR2 IS
        l_color   VARCHAR2(100);
        l_minutes NUMBER;
    
        k_config_table CONSTANT VARCHAR2(0050 CHAR) := 'LENGTH_OF_STAY';
        l_id_market NUMBER;
        l_tbl_cfg   t_tbl_config_table;
    BEGIN
    
        g_error := 'GET PK_EDIS_GRID.GET_LENGTH_OF_STAY_COLOR';
    
        l_id_market := pk_utils.get_institution_market(i_lang => NULL, i_id_institution => i_prof.institution);
    
        -- convert hours to minutes
        l_tbl_cfg := pk_core_config.tf_config(i_lang         => NULL,
                                              i_prof         => i_prof,
                                              i_config_table => k_config_table,
                                              i_inst_mkt     => l_id_market);
        BEGIN
            l_minutes := round(abs(to_number(TRIM(i_hours)) * 1440));
        
            SELECT c.code_color
              INTO l_color
              FROM length_of_stay los
              JOIN color c
                ON c.id_color = los.id_color
              JOIN (SELECT /*+ opt_estimate(table cfg rows=1) */
                     cfg.id_config,
                     cfg.id_inst_owner,
                     cfg.id_record     id_length_of_stay,
                     cfg.field_01      min_val,
                     cfg.field_02      max_val
                      FROM TABLE(l_tbl_cfg) cfg) los_ism
                ON los.id_length_of_stay = los_ism.id_length_of_stay
             WHERE nvl(los_ism.min_val, -9999999999) <= l_minutes
               AND nvl(los_ism.max_val, +9999999999) >= l_minutes
            /*AND los_ism.id_market IN
                (0, pk_utils.get_institution_market(i_lang => NULL, i_id_institution => i_prof.institution))
            AND los_ism.flg_available = pk_alert_constant.g_yes*/
            ;
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;
    
        RETURN l_color;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_length_of_stay_color;

    FUNCTION get_grid_origin
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_origin IN origin.id_origin%TYPE
    ) RETURN VARCHAR2 IS
    
        l_origin VARCHAR2(1000 CHAR);
        l_config_origin CONSTANT sys_config.id_sys_config%TYPE := 'GRID_ORIGINS';
    
        CURSOR c_origin IS
            SELECT pk_translation.get_translation_dtchk(i_lang, 'ORIGIN.CODE_ORIGIN.' || i_origin)
              FROM dual
             WHERE i_origin IN (SELECT *
                                  FROM TABLE(g_tab_grid_origins));
    
    BEGIN
        g_grid_origins := pk_sysconfig.get_config(l_config_origin, i_prof);
    
        g_tab_grid_origins := pk_utils.str_split_l(g_grid_origins, '|');
    
        OPEN c_origin;
        FETCH c_origin
            INTO l_origin;
        CLOSE c_origin;
    
        RETURN l_origin;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
            RETURN NULL;
    END get_grid_origin;

    /********************************************************************************************
    * Gets the abbrevieted description of origin
    *
    * @param i_lang            language id
    * @param i_prof            professional, software and institution ids
    * @param i_origin          origin id
    *
    * @return                  origin abbreviation
    *
    * @author                  Anna Kurowska
    * @version                 1.0
    * @since                   06-09-2016
     **********************************************************************************************/
    FUNCTION get_grid_origin_abbrev
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_origin IN origin.id_origin%TYPE
    ) RETURN VARCHAR2 IS
    
        l_origin VARCHAR2(1000 CHAR);
        l_config_origin CONSTANT sys_config.id_sys_config%TYPE := 'GRID_ORIGINS';
    
        CURSOR c_origin IS
            SELECT nvl(pk_translation.get_translation_dtchk(i_lang, 'ORIGIN.CODE_ORIGIN_ABBREV.' || i_origin),
                       pk_translation.get_translation_dtchk(i_lang, 'ORIGIN.CODE_ORIGIN.' || i_origin))
              FROM dual
             WHERE i_origin IN (SELECT *
                                  FROM TABLE(g_tab_grid_origins));
    
    BEGIN
        g_grid_origins := pk_sysconfig.get_config(l_config_origin, i_prof);
    
        g_tab_grid_origins := pk_utils.str_split_l(g_grid_origins, '|');
    
        OPEN c_origin;
        FETCH c_origin
            INTO l_origin;
        CLOSE c_origin;
        RETURN l_origin;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
            RETURN NULL;
    END get_grid_origin_abbrev;

    /********************************************************************************************
    * Gets the full description about patient origin and cheif complaint to be used in tooltip
    * Consists of origin, chief complain
    *
    * @param i_lang            language id
    * @param i_prof            professional, software and institution ids
    * @param i_visit           visit ID
    * @param i_episode         episode ID
    *
    * @return                  information to be displayed in tooltip over column with patient name representing second line
    *
    * @author                  Anna Kurowska
    * @version                 1.0
    * @since                   24-08-2016
     **********************************************************************************************/

    FUNCTION get_orig_anamn_desc
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_visit   IN visit.id_visit%TYPE,
        i_episode IN episode.id_episode%TYPE DEFAULT NULL,
        i_sep     IN VARCHAR2 DEFAULT ', '
    ) RETURN VARCHAR2 IS
    
        l_origin_desc       VARCHAR2(1000 CHAR);
        l_complaint_desc    VARCHAR2(4000 CHAR);
        l_origin_anamn_full VARCHAR2(4000 CHAR) := '';
    BEGIN
    
        -- origin description
        SELECT get_grid_origin(i_lang, i_prof, v.id_origin)
          INTO l_origin_desc
          FROM visit v
         WHERE v.id_visit = i_visit;
    
        --chief complaitn description
        IF i_episode IS NOT NULL
        THEN
            SELECT pk_edis_grid.get_complaint_grid(i_lang => i_lang,
                                                   i_prof => i_prof,
                                                   i_epis => i_episode,
                                                   i_sep  => i_sep)
              INTO l_complaint_desc
              FROM dual;
        
        ELSE
            l_complaint_desc := NULL;
        END IF;
    
        l_origin_anamn_full := pk_string_utils.concat_if_exists(l_origin_desc, l_complaint_desc, chr(13));
    
        RETURN l_origin_anamn_full;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END get_orig_anamn_desc;

    /**********************************************************************************************
    * Gets the time in minutes for breach
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional, software and institution Ids
    *
    * @return                         Time in minutes
    *
    * @author                         Elisabete Bugalho
    * @version                        2.7.2.4
    * @since                          30/01/2018
    **********************************************************************************************/
    FUNCTION get_los_breach
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN NUMBER IS
    
        k_config_table CONSTANT VARCHAR2(0050 CHAR) := 'LENGTH_OF_STAY';
        l_id_market NUMBER;
        l_tbl_cfg   t_tbl_config_table;
        l_minutes   NUMBER;
    BEGIN
    
        g_error := 'GET PK_EDIS_GRID.GET_LENGTH_OF_STAY_COLOR';
    
        l_id_market := pk_utils.get_institution_market(i_lang => NULL, i_id_institution => i_prof.institution);
    
        l_tbl_cfg := pk_core_config.tf_config(i_lang         => NULL,
                                              i_prof         => i_prof,
                                              i_config_table => k_config_table,
                                              i_inst_mkt     => l_id_market);
        SELECT min_val
          INTO l_minutes
          FROM (SELECT /*+ opt_estimate(table cfg rows=1) */
                 cfg.id_config,
                 cfg.id_inst_owner,
                 cfg.id_record     id_length_of_stay,
                 cfg.field_01      min_val,
                 cfg.field_02      max_val,
                 cfg.field_04      breach
                  FROM TABLE(l_tbl_cfg) cfg)
         WHERE breach = pk_alert_constant.g_yes;
    
        RETURN l_minutes;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_los_breach;

    /*EMR-437*/
    FUNCTION get_prof_cat(i_prof IN profissional) RETURN VARCHAR2 IS
        l_cat_type category.flg_type%TYPE;
    BEGIN
        SELECT cat.flg_type
          INTO l_cat_type
          FROM category cat, professional prf, prof_cat prc
         WHERE prf.id_professional = i_prof.id
           AND prc.id_professional = prf.id_professional
           AND prc.id_institution = i_prof.institution
           AND cat.id_category = prc.id_category;
        RETURN l_cat_type;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END;

    /*EMR-437*/
    PROCEDURE setsql(i_sql IN VARCHAR2) IS
    BEGIN
        g_sql := i_sql;
    END;

    /**
    * Initialize parameters to be used in the grid query of ORIS
    *
    * @param i_context_ids  identifier used in array of context
    * @param i_context_keys Content of the array context
    * @param i_context_vals Values  of the array context
    * @param i_name         variable for bind in the query
    * @param o_vc2          returned value if varchar
    * @param o_num          returned value if number
    * @param o_id           returned value if ID
    * @param o_tstz         returned value if date
    *
    * @author               Alexander Camilo
    * @version              1.0
    * @since                2018/04/19
    */
    PROCEDURE init_params_patient_grids
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_keys  IN table_varchar DEFAULT NULL,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        g_lang             CONSTANT NUMBER(24) := 1;
        g_prof_id          CONSTANT NUMBER(24) := 2;
        g_prof_institution CONSTANT NUMBER(24) := 3;
        g_prof_software    CONSTANT NUMBER(24) := 4;
        l_lang             CONSTANT language.id_language%TYPE := i_context_ids(g_lang);
        l_prof             CONSTANT profissional := profissional(i_context_ids(g_prof_id),
                                                                 i_context_ids(g_prof_institution),
                                                                 i_context_ids(g_prof_software));
    
        --FILTER_BIND
        l_hand_off_type                sys_config.value%TYPE;
        g_task_analysis                VARCHAR2(1) := 'A';
        g_task_exam                    VARCHAR2(1) := 'E';
        g_analysis_exam_icon_grid_rank sys_domain.code_domain%TYPE := 'ANALYSIS_EXAM_ICON_GRID_RANK';
        g_pat_status_pend              VARCHAR2(1) := 'A';
        g_active                       VARCHAR2(1) := 'A';
        g_flg_pat_status               VARCHAR2(50) := 'SR_SURGERY_ROOM.FLG_PAT_STATUS';
        l_str_date                     VARCHAR2(20);
        l_sel_date                     TIMESTAMP;
    
        l_show_inp_epis   sys_config.value%TYPE;
        l_id_software_inp software.id_software%TYPE;
        l_show_all        sys_config.value%TYPE;
    BEGIN
    
        l_show_inp_epis   := pk_sysconfig.get_config(g_config_show_inp_epis, l_prof);
        l_id_software_inp := nvl(pk_sysconfig.get_config(g_config_soft_inp, l_prof), 11);
        l_show_all        := nvl(pk_sysconfig.get_config(g_config_grid_aux, l_prof), pk_alert_constant.g_yes);
    
        pk_context_api.set_parameter('i_lang', l_lang);
        pk_context_api.set_parameter('i_prof_id', l_prof.id);
        pk_context_api.set_parameter('i_institution', l_prof.institution);
        pk_context_api.set_parameter('i_software', l_prof.software);
        pk_context_api.set_parameter('g_show_inp_epis', l_show_inp_epis);
        pk_context_api.set_parameter('g_id_software_inp', l_id_software_inp);
        pk_context_api.set_parameter('g_show_all', l_show_all);
    
        IF i_context_keys IS NOT NULL
           AND i_context_keys.count > 0
        THEN
            -- There is a data to use as filter
            l_str_date := i_context_keys(1);
            l_sel_date := to_timestamp(l_str_date, 'YYYYMMDDHH24MISS');
        ELSE
            l_sel_date := current_timestamp;
        END IF;
    
        CASE i_name
            WHEN 'g_flg_ehr_normal' THEN
                o_vc2 := pk_alert_constant.g_flg_ehr_n;
            
            WHEN 'g_cf_pat_gender_abbr' THEN
                o_vc2 := g_cf_pat_gender_abbr;
            
            WHEN 'g_active_research' THEN
                o_vc2 := 'A';
            
            WHEN 'g_disch_status_active' THEN
                o_vc2 := 'A';
            
            WHEN 'g_disch_status_pend' THEN
                o_vc2 := pk_alert_constant.g_epis_status_pendent;
            
            WHEN 'g_epis_status_inactive' THEN
                o_vc2 := pk_alert_constant.g_epis_status_inactive;
            
            WHEN 'l_edis_timelimit' THEN
                o_id := nvl(pk_sysconfig.get_config('EDIS_GRID_HOURS_LIMIT_SHOW_DISCH', l_prof), 12);
            
            WHEN 'flg_nurse_categ' THEN
                o_vc2 := pk_alert_constant.g_cat_type_nurse;
            
            WHEN 'followed_by_me' THEN
                o_vc2 := pk_alert_constant.g_yes;
            
            WHEN 'flg_epis_status' THEN
                o_vc2 := pk_alert_constant.g_epis_status_active;
            
            WHEN 'flg_epis_disch' THEN
                o_vc2 := 'I'; -- Episode flag status 'I', identify administrative discharge
        
            WHEN 'l_lang' THEN
                o_vc2 := to_char(l_lang);
            
            WHEN 'l_institution' THEN
                o_vc2 := to_char(l_prof.institution);
            
            WHEN 'l_software' THEN
                o_vc2 := to_char(l_prof.software);
            
            WHEN 'l_prof_id' THEN
                o_vc2 := to_char(l_prof.id);
            
            WHEN 'g_prof_dep_status' THEN
                o_vc2 := 'S';
            
            WHEN 'dish_status' THEN
                o_vc2 := 'A';
            
            WHEN 'g_active' THEN
                o_vc2 := g_active;
            
            WHEN 'g_analysis_exam_icon_grid_rank' THEN
                o_vc2 := g_analysis_exam_icon_grid_rank;
            
            WHEN 'g_cat_type_doc' THEN
                o_vc2 := pk_alert_constant.g_cat_type_doc;
            
            WHEN 'g_pat_status_pend' THEN
                o_vc2 := g_pat_status_pend;
            
            WHEN 'g_task_analysis' THEN
                o_vc2 := g_task_analysis;
            
            WHEN 'g_task_exam' THEN
                o_vc2 := g_task_exam;
            
            WHEN 'g_task_harvest' THEN
                o_vc2 := g_task_harvest;
            
            WHEN 'l_hand_off_type' THEN
                pk_hand_off_core.get_hand_off_type(l_lang, l_prof, l_hand_off_type);
                o_vc2 := l_hand_off_type;
            
            WHEN 'l_prof_cat' THEN
                o_vc2 := pk_prof_utils.get_category(i_lang => l_lang, i_prof => l_prof);
            
            WHEN 'l_dt_min' THEN
                o_tstz := pk_date_utils.trunc_insttimezone(i_prof      => l_prof,
                                                           i_timestamp => nvl(pk_date_utils.get_string_tstz(i_lang      => l_lang,
                                                                                                            i_prof      => l_prof,
                                                                                                            i_timestamp => '',
                                                                                                            i_timezone  => NULL),
                                                                              l_sel_date));
            WHEN 'l_dt_max' THEN
                o_tstz := pk_date_utils.add_to_ltstz(i_timestamp => pk_date_utils.trunc_insttimezone(i_prof      => l_prof,
                                                                                                     i_timestamp => nvl(pk_date_utils.get_string_tstz(i_lang      => l_lang,
                                                                                                                                                      i_prof      => l_prof,
                                                                                                                                                      i_timestamp => '',
                                                                                                                                                      i_timezone  => NULL),
                                                                                                                        l_sel_date)),
                                                     i_amount    => 86399,
                                                     i_unit      => 'SECOND');
            
            WHEN 'l_order_by_flg_letter' THEN
                o_vc2 := orderby_flg_letter(l_prof);
            
            WHEN 'g_icon_ft' THEN
                o_vc2 := g_icon_ft;
            WHEN 'g_icon_ft_transfer' THEN
                o_vc2 := g_icon_ft_transfer;
            WHEN 'g_ft_color' THEN
                o_vc2 := g_ft_color;
            WHEN 'g_ft_triage_white' THEN
                o_vc2 := g_icon_ft_transfer;
            WHEN 'g_desc_grid' THEN
                o_vc2 := g_desc_grid;
            WHEN 'g_ft_status' THEN
                o_vc2 := g_ft_status;
        END CASE;
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line('pk_urg_grid,ERROR:' || SQLERRM);
            RAISE;
    END;

BEGIN

    --globals are in the spec
    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);

END pk_edis_grid;
/
