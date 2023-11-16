CREATE OR REPLACE PACKAGE BODY pk_rt_tech IS

    PROCEDURE error_handling
    (
        i_lang           IN language.id_language%TYPE,
        i_func_proc_name IN VARCHAR2,
        i_error          IN VARCHAR2,
        i_sqlcode        IN VARCHAR2,
        i_sqlerror       IN VARCHAR2,
        o_error          OUT t_error_out
    ) IS
    BEGIN
    
        pk_alert_exceptions.process_error(i_lang,
                                          i_sqlcode,
                                          i_sqlerror,
                                          i_error,
                                          g_package_owner,
                                          g_package_name,
                                          i_func_proc_name,
                                          o_error);
    
    END error_handling;

    FUNCTION error_handling
    (
        i_lang           IN language.id_language%TYPE,
        i_func_proc_name IN VARCHAR2,
        i_error          IN VARCHAR2,
        i_sqlcode        IN VARCHAR2,
        i_sqlerror       IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        error_handling(i_lang, i_func_proc_name, i_error, i_sqlcode, i_sqlerror, o_error);
        RETURN FALSE;
    END error_handling;

    FUNCTION noresult_handler
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_unitname IN VARCHAR2
    ) RETURN t_error_out IS
        l_error_out t_error_out;
        l_error_in  t_error_in := t_error_in();
    
        l_ret           BOOLEAN;
        l_error_message sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'COMMON_M015');
        l_error_title   sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'SEARCH_CRITERIA_T011');
    BEGIN
    
        l_error_in.set_all(i_lang,
                           'COMMON_M015',
                           l_error_message,
                           g_error,
                           'ALERT',
                           'PK_RT_TECH',
                           i_unitname,
                           l_error_title,
                           'U');
    
        l_ret := pk_alert_exceptions.process_error(l_error_in, l_error_out);
        pk_alert_exceptions.reset_error_state();
        RETURN l_error_out;
    END noresult_handler;

    --
    FUNCTION preload_rt_shortcuts
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_screens   table_varchar;
        l_scr_alias table_varchar := table_varchar('LIST_IVFLUIDS',
                                                   'LIST_DRUG',
                                                   'LIST_OTHER_EXAM',
                                                   'LIST_IMAGE',
                                                   'LIST_ANALYSIS',
                                                   'LIST_TUBE',
                                                   'LIST_PROC',
                                                   'LIST_NURSE_TEACH',
                                                   'LIST_MONITORIZ');
    BEGIN
    
        IF i_prof.software = g_software_oris
        THEN
            l_screens := table_varchar('SR_CLINICAL_INFO_SUMMARY_DRUG_PRESC', --LIST_IVFLUIDS
                                       'SR_CLINICAL_INFO_SUMMARY_DRUG_PRESC', --LIST_DRUG
                                       'SR_HEADER_OTHER_EXAMS', --LIST_OTHER_EXAM
                                       'SR_CLINICAL_INFO_SUMMARY_EXAM_REQ', --LIST_IMAGE
                                       'SR_CLINICAL_INFO_SUMMARY_ANALYSIS_REQ', --LIST_ANALYSIS
                                       'SR_CLINICAL_INFO_SUMMARY_ANALYSIS_REQ', --LIST_TUBE
                                       'SR_CLINICAL_INFO_SUMMARY_INTERV_PRESC', --LIST_PROC
                                       'GRID_PAT_EDUCATION', --LIST_NURSE_TEACH
                                       NULL -- LIST_MONITORIZ
                                       );
        ELSIF i_prof.software = g_software_outp
              OR i_prof.software = g_software_pp
        THEN
            l_screens := table_varchar('IVFLUIDS_LIST', --LIST_IVFLUIDS
                                       'GRID_DRUG_ADMIN', --LIST_DRUG
                                       'LIST_OTHER_EXAM', --LIST_OTHER_EXAM
                                       'LIST_IMAGE', --LIST_IMAGE
                                       'LIST_ANALYSIS', --LIST_ANALYSIS
                                       'GRID_HARVEST', --LIST_TUBE
                                       'GRID_PROC', --LIST_PROC
                                       'GRID_PAT_EDUCATION', --LIST_NURSE_TEACH
                                       'GRID_MONITOR' -- LIST_MONITORIZ
                                       );
        ELSIF i_prof.software = g_software_care
        THEN
            l_screens := table_varchar('IVFLUIDS_LIST', --LIST_IVFLUIDS
                                       'GRID_DRUG_ADMIN', --LIST_DRUG
                                       'LIST_OTHER_EXAM', --LIST_OTHER_EXAM
                                       'LIST_IMAGE', --LIST_IMAGE
                                       'LIST_ANALYSIS', --LIST_ANALYSIS
                                       'LIST_ANALYSIS', --LIST_TUBE (Não existem colheitas)
                                       'GRID_PROC', --LIST_PROC
                                       'GRID_PAT_EDUCATION', --LIST_NURSE_TEACH
                                       'GRID_MONITOR' -- LIST_MONITORIZ
                                       );
        ELSE
            l_screens := table_varchar('IVFLUIDS_LIST', --LIST_IVFLUIDS
                                       'EDIS_SUMMARY_DRUG_PRESC', --LIST_DRUG
                                       'LIST_OTHER_EXAM', --LIST_OTHER_EXAM
                                       'LIST_IMAGE', --LIST_IMAGE
                                       'LIST_ANALYSIS', --LIST_ANALYSIS
                                       'GRID_TUBE', --LIST_TUBE
                                       'GRID_PROC', --LIST_PROC
                                       'GRID_PAT_EDUCATION', --LIST_NURSE_TEACH
                                       'GRID_MONITOR' -- LIST_MONITORIZ
                                       );
        END IF;
        --
        g_error := 'CALL PK_ACCESS.GET_SHORTCUTS_ARRAY';
        RETURN pk_access.preload_shortcuts(i_lang      => i_lang,
                                           i_prof      => i_prof,
                                           i_screens   => l_screens,
                                           i_scr_alias => l_scr_alias,
                                           o_error     => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling(i_lang, 'PRELOAD_SHORTCUTS', g_error, SQLCODE, SQLERRM, o_error);
    END;

    /**********************************************************************************************
    * Grelha do técnico respiratório, para visualizar todos os pacientes com requisições de MCTS a que ele tem acesso
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_prof_cat_type          category professional
    * @param o_grid                   cursor with all episodes 
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2007/10/18
    *
    * @author  Elisabete Bugalho
    * @date    15-01-22014
    * @version 2.6.3
    **********************************************************************************************/
    FUNCTION get_grid_my_pat_rt
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_grid  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sysdate_char  VARCHAR2(24);
        l_hand_off_type sys_config.value%TYPE;
    
        l_prof_cat category.flg_type%TYPE;
    
    BEGIN
        g_error        := 'GET DATES';
        g_sysdate_tstz := current_timestamp;
        l_sysdate_char := pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
        g_error        := 'GET CONFIGURATIONS';
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
        --
        g_error    := 'GET PROF CAT';
        l_prof_cat := pk_edis_list.get_prof_cat(i_prof);
        --
        g_error := 'OPEN o_grid';
        OPEN o_grid FOR
            SELECT epis.triage_acuity acuity,
                   epis.triage_color_text color_text,
                   (SELECT decode(epis.triage_rank_acuity,
                                  g_no_color_rank,
                                  decode(epis.id_software, g_software_edis, g_rank_inf, g_rank_sup),
                                  NULL,
                                  decode(epis.id_software, g_software_edis, g_rank_inf, g_rank_sup),
                                  epis.triage_rank_acuity)
                      FROM dual) rank_acuity,
                   (SELECT pk_message.get_message(i_lang,
                                                  profissional(i_prof.id, i_prof.institution, epis.id_software),
                                                  'IMAGE_T009')
                      FROM dual) epis_type,
                   epis.id_epis_type,
                   (SELECT decode(epis.triage_flg_letter, g_yes, pk_message.get_message(i_lang, 'EDIS_GRID_M003'))
                      FROM dual) acuity_desc,
                   epis.id_episode,
                   epis.id_patient,
                   pk_patient.get_pat_name(i_lang, i_prof, epis.id_patient, epis.id_episode) name_pat,
                   -- ALERT-102882 Patient name used for sorting
                   pk_patient.get_pat_name_to_sort(i_lang, i_prof, epis.id_patient, epis.id_episode, epis.id_schedule) name_pat_sort,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, epis.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, epis.id_patient) pat_nd_icon,
                   (SELECT pk_patient.get_gender(i_lang, gender)
                      FROM patient
                     WHERE id_patient = epis.id_patient) gender,
                   pk_patient.get_pat_age(i_lang, epis.id_patient, i_prof) pat_age,
                   pk_edis_proc.get_formatted_string_for_sort(i_lang    => i_lang,
                                                              i_prof    => i_prof,
                                                              i_type    => pk_edis_proc.g_sort_type_age,
                                                              i_episode => epis.id_episode) pat_age_for_order_by,
                   pk_edis_proc.get_formatted_string_for_sort(i_lang    => i_lang,
                                                              i_prof    => i_prof,
                                                              i_type    => pk_edis_proc.g_sort_type_los,
                                                              i_episode => epis.id_episode) date_send_sort,
                   pk_patphoto.get_pat_photo(i_lang, i_prof, epis.id_patient, epis.id_episode, NULL) photo,
                   pk_patient_tracking.get_care_stage_grid_status(i_lang, i_prof, epis.id_episode, l_sysdate_char) care_stage,
                   pk_patient_tracking.get_current_state_rank(i_lang, i_prof, epis.id_episode) care_stage_rank,
                   (SELECT pk_translation.get_translation(i_lang,
                                                          'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' ||
                                                          epis.id_clinical_service)
                      FROM dual) cons_type,
                   pk_date_utils.to_char_insttimezone(i_prof, epis.dt_begin_tstz_e, g_date_mask) dt_begin,
                   pk_date_utils.date_char_hour_tsz(i_lang, epis.dt_begin_tstz_e, i_prof.institution, i_prof.software) dt_efectiv,
                   pk_date_utils.to_char_insttimezone(i_prof, epis.dt_first_obs_tstz, g_date_mask) dt_first_obs,
                   pk_date_utils.diff_timestamp(g_sysdate_tstz, epis.dt_begin_tstz_e) order_time,
                   pk_date_utils.get_elapsed_tsz(i_lang, epis.dt_begin_tstz_e, g_sysdate_tstz) date_send,
                   'N' flg_temp,
                   (SELECT nvl(nvl(r.desc_room_abbreviation,
                                   pk_translation.get_translation_dtchk(i_lang, 'ROOM.CODE_ABBREVIATION' || epis.id_room)),
                               nvl(r.desc_room,
                                   pk_translation.get_translation_dtchk(i_lang, 'ROOM.CODE_ROOM.' || epis.id_room)))
                      FROM dual) desc_room,
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
                   (SELECT pk_prof_utils.get_nickname(i_lang, epis.id_first_nurse_resp)
                      FROM dual) name_nurse,
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
                   lpad(to_char(sd.rank), 6, '0') || sd.img_name img_transp,
                   l_sysdate_char dt_server,
                   (SELECT --pk_grid.convert_grid_task_str(i_lang, i_prof, g.exam_d)
                     pk_grid.visit_grid_task_str(i_lang, i_prof, epis.id_visit, g_task_exam, l_prof_cat)
                      FROM grid_task g
                     WHERE g.id_episode = epis.id_episode) desc_exam_req,
                   (SELECT --pk_grid.convert_grid_task_str(i_lang, i_prof, g.analysis_d)
                     pk_grid.visit_grid_task_str(i_lang, i_prof, epis.id_visit, g_task_analysis, l_prof_cat)
                      FROM grid_task g
                     WHERE g.id_episode = epis.id_episode) desc_analysis_req,
                   (SELECT pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, g.intervention)
                      FROM grid_task g
                     WHERE g.id_episode = epis.id_episode) desc_interv_presc,
                   (SELECT pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, g.drug_presc)
                      FROM grid_task g
                     WHERE g.id_episode = epis.id_episode) desc_drug_presc,
                   (SELECT pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, g.monitorization)
                      FROM grid_task g
                     WHERE g.id_episode = epis.id_episode) desc_monitorization,
                   pk_edis_grid.get_complaint_grid(i_lang, i_prof, epis.id_episode) desc_epis_anamnesis,
                   -- José Brito 23/02/2010 ALERT-721 ESI protocol data
                   (SELECT decode(epis.has_transfer,
                                  0,
                                  pk_fast_track.get_fast_track_icon(i_lang, i_prof, epis.id_fast_track, g_icon_ft),
                                  pk_fast_track.get_fast_track_icon(i_lang,
                                                                    i_prof,
                                                                    epis.id_episode,
                                                                    epis.id_fast_track,
                                                                    epis.id_triage_color,
                                                                    g_icon_ft_transfer,
                                                                    epis.has_transfer))
                      FROM dual) fast_track_icon,
                   decode(epis.triage_acuity, g_ft_color, g_ft_triage_white, g_ft_color) fast_track_color,
                   g_ft_status fast_track_status,
                   (SELECT pk_fast_track.get_fast_track_desc(i_lang, i_prof, epis.id_fast_track, g_desc_grid)
                      FROM dual) fast_track_desc,
                   (SELECT pk_edis_triage.get_epis_esi_level(i_lang, i_prof, epis.id_episode, epis.id_triage_color)
                      FROM dual) esi_level,
                   pk_alert_constant.g_no prof_follow_add,
                   pk_prof_follow.get_follow_episode_by_me(i_prof, epis.id_episode, epis.id_schedule) prof_follow_remove,
                   epis.id_schedule id_schedule
              FROM v_episode_act epis, sys_domain sd, room r
             WHERE epis.id_institution = i_prof.institution
               AND sd.val = epis.flg_status_ei
               AND sd.code_domain = 'EPIS_INFO.FLG_STATUS'
               AND sd.domain_owner = pk_sysdomain.k_default_schema
               AND sd.id_language = i_lang
               AND epis.id_room = r.id_room(+)
               AND pk_prof_follow.get_follow_episode_by_me(i_prof, epis.id_episode, epis.id_schedule) =
                   pk_alert_constant.g_yes
             ORDER BY rank_acuity,
                      decode(pk_edis_grid.orderby_flg_letter(i_prof),
                             pk_alert_constant.g_yes,
                             decode(epis.triage_flg_letter, g_yes, 0, 1)),
                      epis.dt_begin_tstz_e;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            error_handling(i_lang, 'GET_GRID_MY_PAT_RT', g_error, SQLCODE, SQLERRM, o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_grid);
            RETURN FALSE;
    END;
    --
    /**********************************************************************************************
    * Grelha do técnico respiratório, para visualizar todos os pacientes alocados ás suas salas
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_prof_cat_type          category professional
    * @param o_grid                   cursor with all episodes 
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2007/10/22
    *
    * UPDATED: ALERT-19390
    * @author  Telmo Castro
    * @date    09-03-2009
    * @version 2.5
    **********************************************************************************************/
    FUNCTION get_grid_all_pat_rt
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_grid          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sysdate_char  VARCHAR2(24);
        l_prof_cat      category.flg_type%TYPE;
        l_hand_off_type sys_config.value%TYPE;
    
    BEGIN
        g_error        := 'GET DATES';
        g_sysdate_tstz := current_timestamp;
        l_sysdate_char := pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
        g_error        := 'GET CONFIGURATIONS';
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
        --
        g_error    := 'GET PROF CAT';
        l_prof_cat := pk_edis_list.get_prof_cat(i_prof);
        --
        g_error := 'OPEN o_grid';
        OPEN o_grid FOR
            SELECT epis.triage_acuity acuity,
                   epis.triage_color_text color_text,
                   (SELECT decode(epis.triage_rank_acuity,
                                  g_no_color_rank,
                                  decode(epis.id_software, g_software_edis, g_rank_inf, g_rank_sup),
                                  NULL,
                                  decode(epis.id_software, g_software_edis, g_rank_inf, g_rank_sup),
                                  epis.triage_rank_acuity)
                      FROM dual) rank_acuity,
                   (SELECT pk_message.get_message(i_lang,
                                                  profissional(i_prof.id, i_prof.institution, epis.id_software),
                                                  'IMAGE_T009')
                      FROM dual) epis_type,
                   epis.id_epis_type,
                   (SELECT decode(epis.triage_flg_letter, g_yes, pk_message.get_message(i_lang, 'EDIS_GRID_M003'))
                      FROM dual) acuity_desc,
                   epis.id_episode,
                   epis.id_patient,
                   pk_patient.get_pat_name(i_lang, i_prof, epis.id_patient, epis.id_episode) name_pat,
                   -- ALERT-102882 Patient name used for sorting
                   pk_patient.get_pat_name_to_sort(i_lang, i_prof, epis.id_patient, epis.id_episode, epis.id_schedule) name_pat_sort,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, epis.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, epis.id_patient) pat_nd_icon,
                   (SELECT pk_patient.get_gender(i_lang, gender)
                      FROM patient
                     WHERE id_patient = epis.id_patient) gender,
                   pk_patient.get_pat_age(i_lang, epis.id_patient, i_prof) pat_age,
                   pk_edis_proc.get_formatted_string_for_sort(i_lang    => i_lang,
                                                              i_prof    => i_prof,
                                                              i_type    => pk_edis_proc.g_sort_type_age,
                                                              i_episode => epis.id_episode) pat_age_for_order_by,
                   pk_edis_proc.get_formatted_string_for_sort(i_lang    => i_lang,
                                                              i_prof    => i_prof,
                                                              i_type    => pk_edis_proc.g_sort_type_los,
                                                              i_episode => epis.id_episode) date_send_sort,
                   pk_patphoto.get_pat_photo(i_lang, i_prof, epis.id_patient, epis.id_episode, NULL) photo,
                   pk_patient_tracking.get_care_stage_grid_status(i_lang, i_prof, epis.id_episode, l_sysdate_char) care_stage,
                   pk_patient_tracking.get_current_state_rank(i_lang, i_prof, epis.id_episode) care_stage_rank,
                   (SELECT pk_translation.get_translation(i_lang,
                                                          'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' ||
                                                          epis.id_clinical_service)
                      FROM dual) cons_type,
                   pk_date_utils.to_char_insttimezone(i_prof, epis.dt_begin_tstz_e, g_date_mask) dt_begin,
                   pk_date_utils.date_char_hour_tsz(i_lang, epis.dt_begin_tstz_e, i_prof.institution, i_prof.software) dt_efectiv,
                   pk_date_utils.to_char_insttimezone(i_prof, epis.dt_first_obs_tstz, g_date_mask) dt_first_obs,
                   pk_date_utils.diff_timestamp(g_sysdate_tstz, epis.dt_begin_tstz_e) order_time,
                   pk_date_utils.get_elapsed_tsz(i_lang, epis.dt_begin_tstz_e, g_sysdate_tstz) date_send,
                   'N' flg_temp,
                   (SELECT nvl(nvl(r.desc_room_abbreviation,
                                   pk_translation.get_translation_dtchk(i_lang, 'ROOM.CODE_ABBREVIATION' || epis.id_room)),
                               nvl(r.desc_room,
                                   pk_translation.get_translation_dtchk(i_lang, 'ROOM.CODE_ROOM.' || epis.id_room)))
                      FROM dual) desc_room,
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
                   (SELECT pk_prof_utils.get_nickname(i_lang, epis.id_first_nurse_resp)
                      FROM dual) name_nurse,
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
                   lpad(to_char(sd.rank), 6, '0') || sd.img_name img_transp,
                   l_sysdate_char dt_server,
                   (SELECT --pk_grid.convert_grid_task_str(i_lang, i_prof, g.exam_d)
                     pk_grid.visit_grid_task_str(i_lang, i_prof, epis.id_visit, g_task_exam, l_prof_cat)
                      FROM grid_task g
                     WHERE g.id_episode = epis.id_episode) desc_exam_req,
                   (SELECT --pk_grid.convert_grid_task_str(i_lang, i_prof, g.analysis_d)
                     pk_grid.visit_grid_task_str(i_lang, i_prof, epis.id_visit, g_task_analysis, l_prof_cat)
                      FROM grid_task g
                     WHERE g.id_episode = epis.id_episode) desc_analysis_req,
                   (SELECT pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, g.intervention)
                      FROM grid_task g
                     WHERE g.id_episode = epis.id_episode) desc_interv_presc,
                   (SELECT pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, g.drug_presc)
                      FROM grid_task g
                     WHERE g.id_episode = epis.id_episode) desc_drug_presc,
                   (SELECT pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, g.monitorization)
                      FROM grid_task g
                     WHERE g.id_episode = epis.id_episode) desc_monitorization,
                   pk_edis_grid.get_complaint_grid(i_lang, i_prof, epis.id_episode) desc_epis_anamnesis,
                   -- José Brito 23/02/2010 ALERT-721 ESI protocol data
                   (SELECT decode(epis.has_transfer,
                                  0,
                                  pk_fast_track.get_fast_track_icon(i_lang, i_prof, epis.id_fast_track, g_icon_ft),
                                  pk_fast_track.get_fast_track_icon(i_lang,
                                                                    i_prof,
                                                                    epis.id_episode,
                                                                    epis.id_fast_track,
                                                                    epis.id_triage_color,
                                                                    g_icon_ft_transfer,
                                                                    epis.has_transfer))
                      FROM dual) fast_track_icon,
                   decode(epis.triage_acuity, g_ft_color, g_ft_triage_white, g_ft_color) fast_track_color,
                   g_ft_status fast_track_status,
                   (SELECT pk_fast_track.get_fast_track_desc(i_lang, i_prof, epis.id_fast_track, g_desc_grid)
                      FROM dual) fast_track_desc,
                   (SELECT pk_edis_triage.get_epis_esi_level(i_lang, i_prof, epis.id_episode, epis.id_triage_color)
                      FROM dual) esi_level,
                   decode(pk_prof_follow.get_follow_episode_by_me(i_prof, epis.id_episode, epis.id_schedule),
                          pk_alert_constant.g_no,
                          pk_alert_constant.g_yes,
                          pk_alert_constant.g_no) prof_follow_add,
                   pk_prof_follow.get_follow_episode_by_me(i_prof, epis.id_episode, epis.id_schedule) prof_follow_remove,
                   epis.id_schedule id_schedule
              FROM v_episode_act epis, sys_domain sd, room r
             WHERE epis.id_institution = i_prof.institution
               AND sd.val = epis.flg_status_ei
               AND sd.code_domain = 'EPIS_INFO.FLG_STATUS'
               AND sd.domain_owner = pk_sysdomain.k_default_schema
               AND sd.id_language = i_lang
               AND EXISTS (SELECT 0
                      FROM prof_room pr
                     WHERE pr.id_professional = i_prof.id
                       AND epis.id_room = pr.id_room)
               AND epis.id_room = r.id_room(+)
             ORDER BY rank_acuity,
                      decode(pk_edis_grid.orderby_flg_letter(i_prof),
                             pk_alert_constant.g_yes,
                             decode(epis.triage_flg_letter, g_yes, 0, 1)),
                      epis.dt_begin_tstz_e;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            error_handling(i_lang, 'GET_GRID_ALL_PAT_RT', g_error, SQLCODE, SQLERRM, o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_grid);
            RETURN FALSE;
    END;
    --
    /**********************************************************************************************
    * Retorna apenas as tarefas, em atraso, que um dado perfil pode efectuar
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_episode                episode id
    * @param i_prof_cat_type          category professional
    * @param i_type_context           tipo de contexto:I -Intervention; E - Exam; D - Drug; A - Analysis; M - Monitorization 
    *
    * @return                         Retorna a informação neste formato: SHORTCUT|DATA|TIPO|COR|TEXTO/NOME_ICON[;...]
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2007/10/19
    *
    * UPDATED: ALERT-19390
    * @author  Telmo Castro
    * @date    09-03-2009
    * @version 2.5
    **********************************************************************************************/
    FUNCTION get_context_value
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_type_context  IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_error         t_error_out; --VARCHAR2(2000);
        l_value_context VARCHAR2(2000);
    BEGIN
        --
        IF i_type_context = g_exam
        THEN
            g_error := 'CALL pk_rt_tech.get_epis_exam_desc';
            IF NOT pk_rt_tech.get_epis_exam_desc(i_lang    => i_lang,
                                                 i_prof    => i_prof,
                                                 i_episode => i_episode,
                                                 o_exam    => l_value_context,
                                                 o_error   => l_error)
            THEN
                g_error := l_error.err_desc;
                RAISE g_exception;
            END IF;
        
        ELSIF i_type_context = g_analysis
        THEN
            g_error := 'CALL pk_rt_tech.get_epis_analysis_desc';
            IF NOT pk_rt_tech.get_epis_analysis_desc(i_lang     => i_lang,
                                                     i_prof     => i_prof,
                                                     i_visit    => i_episode,
                                                     o_analysis => l_value_context,
                                                     o_error    => l_error)
            THEN
                g_error := l_error.err_desc;
                RAISE g_exception;
            END IF;
        ELSIF i_type_context = g_drug
        THEN
            g_error := 'CALL pk_rt_tech.get_epis_drug_desc';
            IF NOT pk_rt_tech.get_epis_drug_desc(i_lang    => i_lang,
                                                 i_prof    => i_prof,
                                                 i_episode => i_episode,
                                                 o_drug    => l_value_context,
                                                 o_error   => l_error)
            THEN
                g_error := l_error.err_desc;
                RAISE g_exception;
            END IF;
        ELSIF i_type_context = g_intervention
        THEN
            g_error := 'CALL pk_rt_tech.get_epis_interv_desc';
            IF NOT pk_rt_tech.get_epis_interv_desc(i_lang    => i_lang,
                                                   i_prof    => i_prof,
                                                   i_episode => i_episode,
                                                   o_interv  => l_value_context,
                                                   o_error   => l_error)
            THEN
                g_error := l_error.err_desc;
                RAISE g_exception;
            END IF;
        ELSIF i_type_context = g_monitorization
        THEN
            g_error := 'CALL pk_rt_tech.get_epis_monit_desc';
            IF NOT pk_rt_tech.get_epis_monit_desc(i_lang    => i_lang,
                                                  i_prof    => i_prof,
                                                  i_episode => i_episode,
                                                  o_monit   => l_value_context,
                                                  o_error   => l_error)
            THEN
                g_error := l_error.err_desc;
                RAISE g_exception;
            END IF;
        END IF;
        --        
        /*pk_utils.put_line(l_value_context);*/
        RETURN l_value_context;
    
    EXCEPTION
        WHEN OTHERS THEN
            error_handling(i_lang, 'GET_GRID_ALL_PAT_RT', g_error, SQLCODE, SQLERRM, l_error);
            RETURN NULL;
    END;

    -- 
    /**********************************************************************************************
    * Retorna apenas o exame, em atraso, que um dado perfil pode efectuar
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_episode                episode id
    * @param o_exam                   Retorna o exame neste formato: SHORTCUT|DATA|TIPO|COR|TEXTO/NOME_ICON[;...]
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2007/10/19
    *
    * UPDATED: ALERT-19390
    * @author  Telmo Castro
    * @date    09-03-2009
    * @version 2.5
    **********************************************************************************************/
    FUNCTION get_epis_exam_desc
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    profissional,
        i_episode IN episode.id_episode%TYPE,
        o_exam    OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_date TIMESTAMP WITH LOCAL TIME ZONE;
        --
        CURSOR c_exam IS
        /*<DENORM 2008-10-13 Sérgio Monteiro>*/
            SELECT pk_utils.get_status_string(i_lang,
                                              i_prof,
                                              eea.status_str,
                                              eea.status_msg,
                                              eea.status_icon,
                                              eea.status_flg,
                                              pk_access.get_shortcut(decode(eea.flg_type,
                                                                            g_exam_type_img,
                                                                            'LIST_IMAGE',
                                                                            'LIST_OTHER_EXAM'))) status_string,
                   decode(eea.flg_time,
                          g_flg_time_epis,
                          decode(eea.flg_status_det,
                                 g_exam_req,
                                 decode(eea.dt_pend_req, NULL, eea.dt_begin, eea.dt_pend_req),
                                 decode(eea.flg_time,
                                        g_flg_time_next,
                                        NULL,
                                        decode(eea.dt_begin, NULL, NULL, eea.dt_begin))),
                          decode(eea.flg_status_det,
                                 g_exam_req,
                                 NULL,
                                 g_exam_pending,
                                 decode(eea.dt_begin, NULL, NULL, nvl(eea.dt_begin, eea.dt_req)),
                                 decode(eea.flg_time, g_flg_time_next, NULL, nvl(eea.dt_begin, eea.dt_req)))) last_date
              FROM profile_context pc, exams_ea eea
             WHERE (eea.id_episode = i_episode OR eea.id_prev_episode = i_episode)
               AND eea.flg_status_req NOT IN (pk_exam_constant.g_exam_predefined,
                                              pk_exam_constant.g_exam_draft,
                                              pk_exam_constant.g_exam_cancel,
                                              pk_exam_constant.g_exam_result,
                                              pk_exam_constant.g_exam_read_partial,
                                              pk_exam_constant.g_exam_read)
               AND pc.id_profile_template = g_current_profile
               AND pc.id_context = eea.id_exam
               AND pc.flg_type = g_exam
               AND pc.flg_available = g_yes
               AND pc.id_institution IN (i_prof.institution, 0)
             ORDER BY last_date ASC NULLS LAST;
        /*<DENORM 2008-10-13 Sérgio Monteiro>*/
    BEGIN
        g_error := 'OPEN c_exam';
        OPEN c_exam;
        FETCH c_exam
            INTO o_exam, l_date;
        CLOSE c_exam;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling(i_lang, 'GET_EPIS_EXAM_DESC', g_error, SQLCODE, SQLERRM, o_error);
    END get_epis_exam_desc;
    --
    /**********************************************************************************************
    * Retorna apenas a analise, em atraso, que um dado perfil pode efectuar
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_episode                episode id
    * @param o_analysis               Retorna a análise neste formato: SHORTCUT|DATA|TIPO|COR|TEXTO/NOME_ICON[;...]
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2007/10/19
    *
    * UPDATED: ALERT-19390
    * @author  Telmo Castro
    * @date    09-03-2009
    * @version 2.5
    **********************************************************************************************/
    FUNCTION get_epis_analysis_desc
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     profissional,
        i_visit    IN visit.id_visit%TYPE,
        o_analysis OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_date TIMESTAMP WITH LOCAL TIME ZONE;
        --    
        CURSOR c_analysis IS
        -- < DESNORM LMAIA 18-10-2008 >
            SELECT pk_utils.get_status_string(i_lang,
                                              i_prof,
                                              lte.status_str,
                                              lte.status_msg,
                                              lte.status_icon,
                                              lte.status_flg,
                                              pk_access.get_shortcut(decode(ah.id_harvest,
                                                                            NULL,
                                                                            'LIST_ANALYSIS',
                                                                            'LIST_TUBE'))) status_string,
                   decode(ar.flg_time,
                          g_flg_time_epis,
                          decode(lte.flg_status_det,
                                 g_analysis_req,
                                 decode(ar.dt_pend_req_tstz, NULL, ar.dt_begin_tstz, ar.dt_pend_req_tstz),
                                 decode(ar.flg_time,
                                        g_flg_time_next,
                                        NULL,
                                        decode(ar.dt_begin_tstz, NULL, NULL, ar.dt_begin_tstz))),
                          decode(lte.flg_status_det,
                                 g_analysis_req,
                                 NULL,
                                 g_analysis_pending,
                                 decode(ar.dt_begin_tstz, NULL, NULL, nvl(ar.dt_begin_tstz, ar.dt_req_tstz)),
                                 decode(ar.flg_time, g_flg_time_next, NULL, nvl(ar.dt_begin_tstz, ar.dt_req_tstz)))) last_date
              FROM lab_tests_ea lte, analysis_req ar, analysis_harvest ah, profile_context pc
             WHERE lte.id_analysis_req = ar.id_analysis_req
               AND lte.id_visit = ar.id_visit
               AND lte.flg_status_req = ar.flg_status
               AND ar.id_visit = i_visit
               AND ar.flg_status NOT IN (pk_lab_tests_constant.g_analysis_predefined,
                                         pk_lab_tests_constant.g_analysis_draft,
                                         pk_lab_tests_constant.g_analysis_exterior,
                                         pk_lab_tests_constant.g_analysis_read,
                                         pk_lab_tests_constant.g_analysis_cancel,
                                         pk_lab_tests_constant.g_analysis_read_partial,
                                         pk_lab_tests_constant.g_analysis_result,
                                         pk_lab_tests_constant.g_analysis_sched)
               AND ah.id_analysis_req_det(+) = lte.id_analysis_req_det
               AND pc.id_profile_template = g_current_profile
               AND pc.id_context = lte.id_analysis
               AND pc.flg_type = g_analysis
               AND pc.flg_available = g_yes
               AND pc.id_institution IN (i_prof.institution, 0)
             ORDER BY last_date ASC NULLS LAST;
        -- < END DESNORM >
    BEGIN
        g_error := 'OPEN c_analysis';
        OPEN c_analysis;
        FETCH c_analysis
            INTO o_analysis, l_date;
        CLOSE c_analysis;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling(i_lang, 'GET_EPIS_ANALYSIS_DESC', g_error, SQLCODE, SQLERRM, o_error);
    END get_epis_analysis_desc;
    --
    /**********************************************************************************************
    * Retorna apenas o procedimento, em atraso, que um dado perfil pode efectuar
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_episode                episode id
    * @param o_interv                 Retorna o procedimento neste formato: SHORTCUT|DATA|TIPO|COR|TEXTO/NOME_ICON[;...]
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2007/10/19
    *
    * UPDATED: ALERT-19390
    * @author  Telmo Castro
    * @date    09-03-2009
    * @version 2.5
    **********************************************************************************************/
    FUNCTION get_epis_interv_desc
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    profissional,
        i_episode IN episode.id_episode%TYPE,
        o_interv  OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_date TIMESTAMP WITH LOCAL TIME ZONE;
        --
        CURSOR c_interv IS
            SELECT pk_utils.get_status_string(i_lang,
                                              i_prof,
                                              pea.status_str,
                                              pea.status_msg,
                                              pea.status_icon,
                                              pea.status_flg,
                                              pk_access.get_shortcut('LIST_PROC')) desc_status,
                   decode(ip.id_episode_origin,
                          NULL,
                          decode(pea.flg_interv_type,
                                 g_interv_type_sos,
                                 NULL,
                                 g_interv_type_con,
                                 decode(pea.flg_status_req,
                                        g_interv_req,
                                        decode(pea.flg_time,
                                               g_flg_time_next,
                                               NULL,
                                               nvl(pea.dt_plan, ip.dt_interv_prescription_tstz)),
                                        g_interv_pending,
                                        decode(pea.flg_time,
                                               g_flg_time_next,
                                               NULL,
                                               nvl(pea.dt_plan, ip.dt_interv_prescription_tstz)),
                                        NULL),
                                 decode(pea.flg_time,
                                        g_flg_time_next,
                                        NULL,
                                        nvl(pea.dt_plan, ip.dt_interv_prescription_tstz))),
                          decode(pea.flg_status_det,
                                 g_interv_req,
                                 NULL,
                                 g_interv_pending,
                                 decode(pea.dt_begin_req, NULL, NULL, nvl(pea.dt_plan, ip.dt_interv_prescription_tstz)),
                                 decode(pea.flg_interv_type,
                                        g_interv_type_sos,
                                        NULL,
                                        g_interv_type_con,
                                        decode(pea.flg_status_req,
                                               g_interv_req,
                                               decode(pea.flg_time, NULL, nvl(pea.dt_plan, ip.dt_interv_prescription_tstz)),
                                               g_interv_pending,
                                               decode(pea.flg_time,
                                                      g_flg_time_next,
                                                      NULL,
                                                      nvl(pea.dt_plan, ip.dt_interv_prescription_tstz)),
                                               NULL),
                                        decode(pea.flg_time,
                                               g_flg_time_next,
                                               NULL,
                                               nvl(pea.dt_plan, ip.dt_interv_prescription_tstz))))) last_date
              FROM procedures_ea pea, interv_prescription ip, profile_context pc
             WHERE (ip.id_episode = i_episode OR ip.id_prev_episode = i_episode)
               AND pea.flg_status_plan IN (g_interv_req, g_interv_pending)
               AND pea.id_interv_prescription = ip.id_interv_prescription
               AND pea.flg_status_req IN (g_interv_req,
                                          g_interv_pending,
                                          pk_procedures_constant.g_interv_exec,
                                          pk_procedures_constant.g_interv_partial)
               AND pc.id_profile_template = g_current_profile
               AND pc.id_context = pea.id_intervention
               AND pc.flg_type = g_intervention
               AND pc.flg_available = g_yes
               AND pc.id_institution IN (i_prof.institution, 0)
             ORDER BY last_date ASC NULLS LAST;
    
    BEGIN
        g_error := 'OPEN C_INTERV';
        OPEN c_interv;
        FETCH c_interv
            INTO o_interv, l_date;
        CLOSE c_interv;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling(i_lang, 'GET_EPIS_INTERV_DESC', g_error, SQLCODE, SQLERRM, o_error);
    END get_epis_interv_desc;
    --
    /**********************************************************************************************
    * Retorna apenas o medicamento, em atraso, que um dado perfil pode efectuar
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_episode                episode id
    * @param o_drug                   Retorna o medicamento neste formato: SHORTCUT|DATA|TIPO|COR|TEXTO/NOME_ICON[;...]
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2007/10/19
    *
    * UPDATED: ALERT-19390
    * @author  Telmo Castro
    * @date    09-03-2009
    * @version 2.5
    **********************************************************************************************/

    FUNCTION get_epis_drug_desc
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    profissional,
        i_episode IN episode.id_episode%TYPE,
        o_drug    OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_drug IS
            SELECT pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, g.drug_presc)
              FROM grid_task g
             WHERE g.id_episode = i_episode;
    
    BEGIN
        g_error := 'OPEN c_drug';
        OPEN c_drug;
        FETCH c_drug
            INTO o_drug;
        CLOSE c_drug;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling(i_lang, 'GET_EPIS_DRUG_DESC', g_error, SQLCODE, SQLERRM, o_error);
    END get_epis_drug_desc;

    --
    /**********************************************************************************************
    * Retorna apenas a monitorização, em atraso, que um dado perfil pode efectuar
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_episode                episode id
    * @param o_monit                  Retorna o monitorização neste formato: SHORTCUT|DATA|TIPO|COR|TEXTO/NOME_ICON[;...]
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2007/10/19
    *
    * UPDATED: ALERT-19390
    * @author  Telmo Castro
    * @date    09-03-2009
    * @version 2.5
    **********************************************************************************************/
    FUNCTION get_epis_monit_desc
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    profissional,
        i_episode IN episode.id_episode%TYPE,
        o_monit   OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_date TIMESTAMP WITH LOCAL TIME ZONE;
    
        CURSOR c_monit IS
            SELECT pk_utils.get_status_string(i_lang,
                                              i_prof,
                                              mea.status_str,
                                              mea.status_msg,
                                              mea.status_icon,
                                              mea.status_flg,
                                              pk_access.get_shortcut('LIST_MONITORIZ')) desc_status,
                   decode(mea.id_episode_origin,
                          NULL,
                          decode(mea.flg_time, g_flg_time_next, NULL, nvl(mea.dt_plan, mea.dt_begin)),
                          decode(mea.flg_time, g_flg_time_next, NULL)) last_date
              FROM monitorizations_ea mea, profile_context pc
             WHERE (mea.id_episode = i_episode OR mea.id_prev_episode = i_episode)
               AND mea.flg_status IN (g_monit_active, g_monit_pending)
               AND pc.id_profile_template = g_current_profile
               AND pc.id_context = mea.id_vital_sign
               AND pc.flg_type = g_monitorization
               AND pc.flg_available = g_yes
               AND pc.id_institution IN (i_prof.institution, 0)
             ORDER BY last_date ASC NULLS LAST;
    
    BEGIN
        g_error := 'OPEN c_monit';
        OPEN c_monit;
        FETCH c_monit
            INTO o_monit, l_date;
        CLOSE c_monit;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling(i_lang, 'GET_EPIS_MONIT_DESC', g_error, SQLCODE, SQLERRM, o_error);
    END get_epis_monit_desc;
    --
    /**********************************************************************************************
    * Verificar se existem análises que um dado perfil pode efectuar
    *
    * @param i_prof                   professional id
    * @param i_institution            institution id
    * @param i_software               software id
    * @param i_episode                episode id
    *
    * @return                         number
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2007/10/24
    **********************************************************************************************/
    FUNCTION get_epis_analysis_count
    (
        i_prof        IN professional.id_professional%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE,
        i_visit       IN visit.id_visit%TYPE
    ) RETURN NUMBER IS
        l_num_analysis_states NUMBER;
    BEGIN
        -- < DESNORM LMAIA 18-10-2008 >
        g_error := 'COUNT ANALYSIS';
        SELECT nvl((SELECT 1
                     FROM dual
                    WHERE EXISTS (SELECT 0
                             FROM lab_tests_ea lte
                            WHERE lte.id_visit = i_visit
                              AND lte.flg_status_req NOT IN
                                  (pk_lab_tests_constant.g_analysis_predefined,
                                   pk_lab_tests_constant.g_analysis_draft,
                                   pk_lab_tests_constant.g_analysis_exterior,
                                   pk_lab_tests_constant.g_analysis_read,
                                   pk_lab_tests_constant.g_analysis_cancel,
                                   pk_lab_tests_constant.g_analysis_read_partial,
                                   pk_lab_tests_constant.g_analysis_result,
                                   pk_lab_tests_constant.g_analysis_sched)
                              AND EXISTS (SELECT 0
                                     FROM profile_context pc
                                    WHERE pc.id_profile_template = g_current_profile
                                      AND pc.id_context = lte.id_analysis
                                      AND pc.flg_type = g_analysis
                                      AND pc.flg_available = g_yes
                                      AND pc.id_institution IN (i_institution, 0)))),
                   0)
          INTO l_num_analysis_states
          FROM dual;
        -- < END DESNORM >
    
        RETURN l_num_analysis_states;
    
    END get_epis_analysis_count;
    --
    /**********************************************************************************************
    * Verificar se existem exames que um dado perfil pode efectuar
    *
    * @param i_prof                   professional id
    * @param i_institution            institution id
    * @param i_software               software id
    * @param i_episode                episode id
    *
    * @return                         number
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2007/10/24
    **********************************************************************************************/
    FUNCTION get_epis_exam_count
    (
        i_prof        IN professional.id_professional%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE,
        i_episode     IN episode.id_episode%TYPE
    ) RETURN NUMBER IS
        l_num_exam_states NUMBER;
    BEGIN
        g_error := 'COUNT EXAM';
        /*DENORM Sérgio Monteiro 2008-10-13*/
        SELECT nvl((SELECT 1
                     FROM dual
                    WHERE EXISTS
                    (SELECT 0
                             FROM exams_ea eea, profile_context pc
                            WHERE (eea.id_episode = i_episode OR eea.id_prev_episode = i_episode)
                              AND eea.flg_status_req NOT IN (pk_exam_constant.g_exam_predefined,
                                                             pk_exam_constant.g_exam_draft,
                                                             pk_exam_constant.g_exam_cancel,
                                                             pk_exam_constant.g_exam_result,
                                                             pk_exam_constant.g_exam_read_partial,
                                                             pk_exam_constant.g_exam_read)
                              AND pc.id_profile_template = g_current_profile
                              AND pc.id_context = eea.id_exam
                              AND pc.flg_type = g_exam
                              AND pc.flg_available = g_yes
                              AND pc.id_institution IN (i_institution, 0))),
                   0)
          INTO l_num_exam_states
          FROM dual;
        /*DENORM Sérgio Monteiro 2008-10-13*/
        RETURN l_num_exam_states;
    
    END get_epis_exam_count;
    --
    /**********************************************************************************************
    * Verificar se existem procedimentos que um dado perfil pode efectuar
    *
    * @param i_prof                   professional id
    * @param i_institution            institution id
    * @param i_software               software id
    * @param i_episode                episode id
    *
    * @return                         number
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2007/10/24
    **********************************************************************************************/
    FUNCTION get_epis_interv_count
    (
        i_prof        IN professional.id_professional%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE,
        i_episode     IN episode.id_episode%TYPE
    ) RETURN NUMBER IS
        l_num_interv_states NUMBER;
    BEGIN
        g_error := 'COUNT INTERV';
        SELECT COUNT(*)
          INTO l_num_interv_states
          FROM (SELECT pea.flg_status_req
                  FROM procedures_ea pea, interv_prescription ip, profile_context pc
                 WHERE (ip.id_episode = i_episode OR ip.id_prev_episode = i_episode)
                   AND pea.id_interv_prescription = ip.id_interv_prescription
                   AND ip.flg_status IN (g_interv_req,
                                         g_interv_pending,
                                         pk_procedures_constant.g_interv_exec,
                                         pk_procedures_constant.g_interv_partial)
                   AND pea.flg_status_plan IN (g_interv_req, g_interv_pending)
                   AND pc.id_profile_template = g_current_profile
                   AND pc.id_context = pea.id_intervention
                   AND pc.flg_type = g_intervention
                   AND pc.flg_available = g_yes
                   AND pc.id_institution IN (i_institution, 0));
    
        RETURN l_num_interv_states;
    
    END get_epis_interv_count;
    --
    /**********************************************************************************************
    * Verificar se existem medicamentos que um dado perfil pode efectuar
    *
    * @param i_prof                   professional id
    * @param i_institution            institution id
    * @param i_software               software id
    * @param i_episode                episode id
    *
    * @return                         number
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2007/10/24
    **********************************************************************************************/
    FUNCTION get_epis_drug_count
    (
        i_prof        IN professional.id_professional%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE,
        i_episode     IN episode.id_episode%TYPE
    ) RETURN NUMBER IS
        l_num_drug_states NUMBER;
    BEGIN
        g_error := 'COUNT DRUG';
        SELECT COUNT(*)
          INTO l_num_drug_states
          FROM (SELECT /*+ordered use_nl(med_tasks pc)*/
                 desc_status
                  FROM TABLE(pk_api_pfh_clindoc_in.get_rt_epis_drug_desc(1,
                                                                         profissional(i_prof, i_institution, i_software),
                                                                         i_episode)) med_tasks
                  JOIN profile_context pc
                    ON to_char(pc.id_context) = med_tasks.id_drug
                 WHERE pc.id_profile_template = g_current_profile
                   AND pc.flg_type = g_drug
                   AND pc.flg_available = g_yes
                   AND pc.id_institution IN (i_institution, 0));
    
        RETURN l_num_drug_states;
    
    END get_epis_drug_count;
    --
    /**********************************************************************************************
    * Verificar se existem monitorizações que um dado perfil pode efectuar
    *
    * @param i_prof                   professional id
    * @param i_institution            institution id
    * @param i_software               software id
    * @param i_episode                episode id
    *
    * @return                         number
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2007/10/24
    **********************************************************************************************/
    FUNCTION get_epis_monit_count
    (
        i_prof        IN professional.id_professional%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE,
        i_episode     IN episode.id_episode%TYPE
    ) RETURN NUMBER IS
        l_num_monit_states NUMBER;
    BEGIN
        g_error := 'COUNT MONITORIZATIONS';
        SELECT COUNT(*)
          INTO l_num_monit_states
          FROM (SELECT mea.flg_status
                  FROM monitorizations_ea mea, profile_context pc
                 WHERE (mea.id_episode = i_episode OR mea.id_prev_episode = i_episode)
                   AND mea.flg_status IN (g_monit_active, g_monit_pending)
                   AND pc.id_profile_template = g_current_profile
                   AND pc.id_context = mea.id_vital_sign
                   AND pc.flg_type = g_monitorization
                   AND pc.flg_available = g_yes
                   AND pc.id_institution IN (i_institution, 0));
    
        RETURN l_num_monit_states;
    
    END get_epis_monit_count;

    /**********************************************************************************************
    * Check wether the current episode has any active treatment that this RT can perform
    * Not being used for performance issues
    *
    * @param i_prof                   professional id
    * @param i_institution            institution id
    * @param i_software               software id
    * @param i_episode                episode id
    * @param i_visit                  visit id
    *
    * @return                         number: the number of treatments in course. 0 if none, greater than 0 if any.
    *                        
    * @author                         João Eiras
    * @version                        1.0 
    * @since                          2008/02/08
    **********************************************************************************************/
    FUNCTION get_epis_treatment_count
    (
        i_prof        IN professional.id_professional%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE,
        i_visit       IN visit.id_visit%TYPE,
        i_episode     IN episode.id_episode%TYPE
    ) RETURN NUMBER IS
    BEGIN
        RETURN pk_rt_tech.get_epis_analysis_count(i_prof, i_institution, i_software, i_visit) + --
        pk_rt_tech. get_epis_exam_count(i_prof, i_institution, i_software, i_episode) + --
        pk_rt_tech. get_epis_interv_count(i_prof, i_institution, i_software, i_episode) + --
        pk_rt_tech. get_epis_drug_count(i_prof, i_institution, i_software, i_episode) + --
        pk_rt_tech. get_epis_monit_count(i_prof, i_institution, i_software, i_episode);
    END;

    --
    /**********************************************************************************************
    * Efectuar pesquisa de doentes ACTIVOS, de acordo com os critérios seleccionados, para o técnico respiratório
    *
    * @param i_lang                   the id language
    * @param i_id_sys_btn_crit        Lista de ID'S de critérios de pesquisa.             
    * @param i_crit_val               Lista de valores dos critérios de pesquisa
    * @param i_instit                 institution id
    * @param i_epis_type              episode type
    * @param i_dt                     Data a pesquisar. Se for null assume a data de sistema
    * @param i_prof                   professional, software and institution ids
    * @param i_prof_cat_type          professional category   
    * @param o_flg_show                
    * @param o_msg    
    * @param o_msg_title
    * @param o_button   
    * @param o_pat                    array with patient active
    * @param o_mess_no_result         Mensagem quando a pesquisa não devolver resultados  
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2007/10/24
    *
    * UPDATED: ALERT-19390
    * @author  Telmo Castro
    * @date    09-03-2009
    * @version 2.5
    **********************************************************************************************/
    FUNCTION get_epis_active_rttech
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_instit          IN institution.id_institution%TYPE,
        i_epis_type       IN schedule_outp.id_epis_type%TYPE,
        i_dt              IN VARCHAR2,
        i_prof            IN profissional,
        i_prof_cat_type   IN category.flg_type%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_pat             OUT pk_types.cursor_type,
        o_mess_no_result  OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_where         VARCHAR2(4000);
        v_where_cond    VARCHAR2(32767);
        l_count         PLS_INTEGER;
        l_limit         NUMBER;
        l_sysdate_char  VARCHAR2(24);
        l_hand_off_type sys_config.value%TYPE;
    
        l_ret BOOLEAN;
    
        CURSOR c_profile IS
            SELECT t.id_profile_template
              FROM prof_profile_template t, profile_template x
             WHERE t.id_profile_template = x.id_profile_template
               AND x.id_software = i_prof.software
               AND t.id_professional = i_prof.id
               AND t.id_software = i_prof.software
               AND t.id_institution = i_prof.institution;
    
        e_call_err EXCEPTION;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
        l_sysdate_char := pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
        o_flg_show     := 'N';
        --
        l_limit := pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof);
        g_error := 'GET CONFIGURATIONS';
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
        --
        --Obtem mensagem a mostrar quando a pesquisa não devolver dados
        --o_mess_no_result := pk_message.get_message(i_lang, 'COMMON_M015');
        --
        l_where := NULL;
        --
        g_error := 'COUNT i_id_sys_btn_crit';
        FOR i IN 1 .. i_id_sys_btn_crit.count
        LOOP
            --Lê critérios de pesquisa e preenche cláusula WHERE
            g_error      := 'SET WHERE';
            v_where_cond := NULL;
            --
            IF i_id_sys_btn_crit(i) IS NOT NULL
            THEN
                IF NOT pk_search.get_criteria_condition(i_lang,
                                                        i_prof,
                                                        i_id_sys_btn_crit(i),
                                                        REPLACE(i_crit_val(i), '''', ''''''),
                                                        v_where_cond,
                                                        o_error)
                THEN
                    RAISE e_call_err;
                END IF;
                --
                l_where := l_where || v_where_cond;
            END IF;
        END LOOP;
        --    
        g_error := 'OPEN c_profile';
        OPEN c_profile;
        FETCH c_profile
            INTO g_current_profile;
        CLOSE c_profile;
    
        DELETE FROM tbl_temp;
        g_error := 'GET EPISODES';
        EXECUTE IMMEDIATE 'INSERT INTO tbl_temp(num_1, num_2, num_3, num_4, num_5, num_6, vc_2, vc_3, dt_1, num_7, vc_4, vc_5, vc_6, tstz_1, tstz_2, vc_7) ' || --
                          'SELECT epis.id_episode, ' || --
                          '       epis.id_visit, ' || --
                          '       epis.id_patient, ' || --
                          '       ei.id_professional, ' || --
                          '       ei.id_first_nurse_resp, ' || --
                          '       ei.id_room, ' || --
                          '       pk_patient.get_pat_name(:i_lang, :i_prof, epis.id_patient, epis.id_episode) name, ' || --
                          '       pat.gender, ' || --
                          '       pat.dt_birth, ' || --
                          '       pat.age, ' || --
                          '       ei.flg_status, ' || --
                          '       epis.id_clinical_service, ' || --
                          '       ei.id_software, ' || --
                          '       epis.dt_begin_tstz, ' || --
                          '       ei.dt_first_obs_tstz, ' || --
                          '       ei.triage_acuity ' || --
                          '  FROM (SELECT e.* ' || --
                          '          FROM episode e ' || --
                          '         WHERE e.flg_status = :g_active ' || --
                          '           AND EXISTS (SELECT 0 FROM exam_req t WHERE e.id_episode = t.id_episode UNION ALL ' || --
                          '                       SELECT 0 FROM exam_req t WHERE e.id_episode = t.id_prev_episode UNION ALL ' || --
                          '                       SELECT 0 FROM analysis_req t WHERE e.id_visit = t.id_visit UNION ALL ' || --
                          '                       SELECT 0 FROM interv_prescription t WHERE e.id_episode = t.id_episode UNION ALL ' || --
                          '                       SELECT 0 FROM interv_prescription t WHERE e.id_episode = t.id_prev_episode UNION ALL ' || --
                          '                       SELECT 0 FROM v_drug_prescription t WHERE e.id_episode = t.id_episode UNION ALL ' || --
                          '                       SELECT 0 FROM v_drug_prescription t WHERE e.id_episode = t.id_prev_episode UNION ALL ' || --
                          '                       SELECT 0 FROM monitorization t WHERE e.id_episode = t.id_episode UNION ALL ' || --
                          '                       SELECT 0 FROM monitorization t WHERE e.id_episode = t.id_prev_episode)) epis, ' || --
                          '       epis_info ei, ' || --
                          '       patient pat, ' || --
                          '       clin_record cr, ' || --
                          '       professional p ' || --
                          ' WHERE epis.id_episode = ei.id_episode ' || --
                          '   AND epis.id_institution = :i_prof_institution ' ||
                          '   AND pk_episode.get_soft_by_epis_type(epis.id_epis_type , epis.id_institution ) = nvl(ei.id_software, 0) ' || --
                          '   AND epis.id_institution = :i_prof_institution ' || --
                          '   AND epis.id_patient = pat.id_patient ' || --
                          '   AND cr.id_institution(+) = epis.id_institution ' || --
                          '   AND cr.id_patient(+) = epis.id_patient ' || -- 
                          '   AND p.id_professional(+) = ei.id_professional ' || --                     
                         -- José Brito 28/02/2008 WO9395: linhas comentadas para que a pesquisa devolva TODOS os pacientes activos.
                          l_where
            USING --
        i_lang, --
        i_prof, --
        g_active, --
        i_prof.institution, --
        i_prof.institution; --
        --i_prof.id, --
        --i_prof.software;
        --
        g_error := 'GET COUNT';
        SELECT COUNT(0)
          INTO l_count
          FROM tbl_temp;
        --
        g_error := 'TEST LIMIT';
        IF l_count > l_limit
        THEN
            RAISE pk_search.e_overlimit;
        ELSIF l_count = 0
        THEN
            RAISE pk_search.e_noresults;
        END IF;
    
        g_error := 'PRELOAD SHORTCUTS';
        IF NOT preload_rt_shortcuts(i_lang, i_prof, o_error)
        THEN
            RAISE e_call_err;
        END IF;
    
        g_error := 'DELETE EXTRA';
        DELETE FROM tbl_temp
         WHERE ROWID IN (SELECT MIN(t.rid)
                           FROM (SELECT t.*, ROWID rid
                                   FROM tbl_temp t
                                  ORDER BY vc_2) t
                          GROUP BY rownum
                         HAVING rownum > l_limit);
    
        g_error := 'OPEN O_PAT';
        OPEN o_pat FOR
            SELECT tco.color acuity,
                   tco.color_text,
                   decode(tco.rank,
                          g_no_color_rank,
                          decode(epis.id_software, g_software_edis, g_rank_inf, g_rank_sup),
                          tco.rank) rank_acuity,
                   (SELECT pk_message.get_message(i_lang,
                                                  profissional(i_prof.id, i_prof.institution, epis.id_software),
                                                  'IMAGE_T009')
                      FROM dual) epis_type,
                   --decode(etr.flg_letter, g_yes, pk_message.get_message(i_lang, 'EDIS_GRID_M003')) acuity_desc,
                   epis.id_episode,
                   epis.id_patient,
                   epis.name       name_pat,
                   -- ALERT-102882 Patient name used for sorting
                   pk_patient.get_pat_name_to_sort(i_lang, i_prof, epis.id_patient, epis.id_episode, NULL) name_pat_sort,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, epis.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, epis.id_patient) pat_nd_icon,
                   pk_patient.get_gender(i_lang, epis.gender) gender,
                   (SELECT pk_patient.get_pat_age(i_lang, dt_birth, age, i_prof.institution, i_prof.software)
                      FROM dual) pat_age,
                   (SELECT pk_edis_proc.get_formatted_string_for_sort(i_lang    => i_lang,
                                                                      i_prof    => i_prof,
                                                                      i_type    => pk_edis_proc.g_sort_type_age,
                                                                      i_episode => epis.id_episode)
                      FROM dual) pat_age_for_order_by,
                   (SELECT pk_edis_proc.get_formatted_string_for_sort(i_lang    => i_lang,
                                                                      i_prof    => i_prof,
                                                                      i_type    => pk_edis_proc.g_sort_type_los,
                                                                      i_episode => epis.id_episode)
                      FROM dual) date_send_sort,
                   (SELECT pk_patphoto.get_pat_photo(i_lang, i_prof, epis.id_patient, epis.id_episode, NULL)
                      FROM dual) photo,
                   (SELECT pk_translation.get_translation(i_lang,
                                                          'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' ||
                                                          epis.id_clinical_service)
                      FROM dual) cons_type,
                   pk_patient_tracking.get_care_stage_grid_status(i_lang, i_prof, epis.id_episode, l_sysdate_char) care_stage,
                   pk_patient_tracking.get_current_state_rank(i_lang, i_prof, epis.id_episode) care_stage_rank,
                   pk_date_utils.to_char_insttimezone(i_prof, epis.dt_begin_tstz, g_date_mask) dt_begin,
                   pk_date_utils.date_char_hour_tsz(i_lang, epis.dt_begin_tstz, i_prof.institution, i_prof.software) dt_efectiv,
                   pk_date_utils.date_send_tsz(i_lang, dt_first_obs_tstz, i_prof) dt_first_obs,
                   pk_date_utils.diff_timestamp(g_sysdate_tstz, epis.dt_begin_tstz) order_time,
                   pk_date_utils.get_elapsed_tsz(i_lang, epis.dt_begin_tstz, g_sysdate_tstz) date_send,
                   'N' flg_temp,
                   (SELECT nvl(nvl(r.desc_room_abbreviation,
                                   pk_translation.get_translation_dtchk(i_lang, 'ROOM.CODE_ABBREVIATION.' || epis.id_room)),
                               nvl(r.desc_room,
                                   pk_translation.get_translation_dtchk(i_lang, 'ROOM.CODE_ROOM.' || epis.id_room)))
                      FROM dual) desc_room,
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
                   (SELECT pk_prof_utils.get_nickname(i_lang, epis.id_first_nurse_resp)
                      FROM dual) name_nurse,
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
                   (SELECT lpad(to_char(rank), 6, '0') || img_name
                      FROM sys_domain sd
                     WHERE sd.code_domain = 'EPIS_INFO.FLG_STATUS'
                       AND sd.domain_owner = pk_sysdomain.k_default_schema
                       AND sd.id_language = i_lang
                       AND sd.val = epis.flg_status_ei) img_transp,
                   l_sysdate_char dt_server,
                   
                   get_context_value(i_lang, i_prof, epis.id_episode, i_prof_cat_type, g_exam) desc_exam_req,
                   (SELECT get_context_value(i_lang, i_prof, epis.id_visit, i_prof_cat_type, g_analysis)
                      FROM dual) desc_analysis_req,
                   get_context_value(i_lang, i_prof, epis.id_episode, i_prof_cat_type, g_intervention) desc_interv_presc,
                   get_context_value(i_lang, i_prof, epis.id_episode, i_prof_cat_type, g_drug) desc_drug_presc,
                   get_context_value(i_lang, i_prof, epis.id_episode, i_prof_cat_type, g_monitorization) desc_monitorization,
                   pk_edis_grid.get_complaint_grid(i_lang, i_prof.institution, i_prof.software, epis.id_episode) desc_epis_anamnesis,
                   -- José Brito 26/07/2010 ALERT-109562 ESI protocol data
                   (SELECT decode(epis.has_transfer,
                                  0,
                                  pk_fast_track.get_fast_track_icon(i_lang, i_prof, epis.id_fast_track, g_icon_ft),
                                  pk_fast_track.get_fast_track_icon(i_lang,
                                                                    i_prof,
                                                                    epis.id_episode,
                                                                    epis.id_fast_track,
                                                                    epis.id_triage_color,
                                                                    g_icon_ft_transfer,
                                                                    epis.has_transfer))
                      FROM dual) fast_track_icon,
                   decode(epis.triage_acuity, g_ft_color, g_ft_triage_white, g_ft_color) fast_track_color,
                   g_ft_status fast_track_status,
                   (SELECT pk_fast_track.get_fast_track_desc(i_lang, i_prof, epis.id_fast_track, g_desc_grid)
                      FROM dual) fast_track_desc,
                   (SELECT pk_edis_triage.get_epis_esi_level(i_lang, i_prof, epis.id_episode, epis.id_triage_color)
                      FROM dual) esi_level
              FROM (SELECT num_1 id_episode,
                           num_2 id_visit,
                           num_3 id_patient,
                           num_4 id_professional,
                           num_5 id_first_nurse_resp,
                           num_6 id_room,
                           vc_2 name,
                           vc_3 gender,
                           dt_1 dt_birth,
                           num_7 age,
                           vc_4 flg_status_ei,
                           to_number(vc_5) id_clinical_service,
                           to_number(vc_6) id_software,
                           tstz_1 dt_begin_tstz,
                           tstz_2 dt_first_obs_tstz,
                           nvl((SELECT id_triage_color
                                 FROM (SELECT etr.id_triage_color, etr.id_episode
                                         FROM epis_triage etr
                                        ORDER BY etr.dt_end_tstz DESC) et
                                WHERE et.id_episode = num_1
                                  AND rownum < 2),
                               g_no_triage_color_id) id_triage_color,
                           -- José Brito 26/07/2010 ALERT-109562 ESI protocol data
                           vc_7 triage_acuity,
                           (SELECT pk_fast_track.get_epis_fast_track_int(i_lang, i_prof, num_1, NULL)
                              FROM dual) id_fast_track,
                           (SELECT pk_transfer_institution.check_epis_transfer(num_1)
                              FROM dual) has_transfer
                      FROM tbl_temp) epis,
                   triage_color tco,
                   room r
             WHERE epis.id_triage_color = tco.id_triage_color
               AND epis.id_room = r.id_room(+)
             ORDER BY rank_acuity, epis.dt_begin_tstz;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN pk_search.e_noresults THEN
            pk_alert_exceptions.reset_error_state();
            pk_types.open_my_cursor(o_pat);
        
            l_ret := pk_search.noresult_handler(i_lang, i_prof, 'PK_RT_TECH', 'GET_PAT_CRITERIA_ACTIVE_CLIN', o_error);
            RETURN FALSE;
        WHEN pk_search.e_overlimit THEN
            pk_alert_exceptions.reset_error_state();
            pk_types.open_my_cursor(o_pat);
        
            l_ret := pk_search.overlimit_handler(i_lang, i_prof, 'PK_RT_TECH', 'GET_PAT_CRITERIA_ACTIVE_CLIN', o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_RT_TECH',
                                              'GET_EPIS_ACTIVE_RTTECH',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_pat);
            RETURN FALSE;
    END;

    /**********************************************************************************************
    * Grelha do técnico respiratório, para visualizar todos os pacientes com requisições de MCTS a que ele tem acesso
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_prof_cat_type          category professional
    * @param o_grid                   cursor with all episodes 
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author  Elisabete Bugalho
    * @date    15-01-2014
    * @version 2.6.3
    **********************************************************************************************/
    FUNCTION get_grid_tasks_rt
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_grid          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sysdate_char  VARCHAR2(24);
        l_hand_off_type sys_config.value%TYPE;
    
    BEGIN
        g_error        := 'GET DATES';
        g_sysdate_tstz := current_timestamp;
        l_sysdate_char := pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
        g_error        := 'GET CONFIGURATIONS';
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
        --
        IF NOT preload_rt_shortcuts(i_lang, i_prof, o_error)
        THEN
            pk_types.open_my_cursor(o_grid);
            RETURN FALSE;
        END IF;
    
        g_error           := 'CALL get_prof_profile_template';
        g_current_profile := pk_prof_utils.get_prof_profile_template(i_prof);
        --
        g_error := 'GET CURSOR O_GRID';
        OPEN o_grid FOR
            SELECT epis.triage_acuity acuity,
                   epis.triage_color_text color_text,
                   (SELECT decode(epis.triage_rank_acuity,
                                  g_no_color_rank,
                                  decode(epis.id_software, g_software_edis, g_rank_inf, g_rank_sup),
                                  NULL,
                                  decode(epis.id_software, g_software_edis, g_rank_inf, g_rank_sup),
                                  epis.triage_rank_acuity)
                      FROM dual) rank_acuity,
                   (SELECT pk_message.get_message(i_lang,
                                                  profissional(i_prof.id, i_prof.institution, epis.id_software),
                                                  'IMAGE_T009')
                      FROM dual) epis_type,
                   epis.id_epis_type,
                   (SELECT decode(epis.triage_flg_letter, g_yes, pk_message.get_message(i_lang, 'EDIS_GRID_M003'))
                      FROM dual) acuity_desc,
                   epis.id_episode,
                   epis.id_patient,
                   pk_patient.get_pat_name(i_lang, i_prof, epis.id_patient, epis.id_episode) name_pat,
                   -- ALERT-102882 Patient name used for sorting
                   pk_patient.get_pat_name_to_sort(i_lang, i_prof, epis.id_patient, epis.id_episode, epis.id_schedule) name_pat_sort,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, epis.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, epis.id_patient) pat_nd_icon,
                   (SELECT pk_patient.get_gender(i_lang, gender)
                      FROM patient
                     WHERE id_patient = epis.id_patient) gender,
                   pk_patient.get_pat_age(i_lang, epis.id_patient, i_prof) pat_age,
                   pk_edis_proc.get_formatted_string_for_sort(i_lang    => i_lang,
                                                              i_prof    => i_prof,
                                                              i_type    => pk_edis_proc.g_sort_type_age,
                                                              i_episode => epis.id_episode) pat_age_for_order_by,
                   pk_edis_proc.get_formatted_string_for_sort(i_lang    => i_lang,
                                                              i_prof    => i_prof,
                                                              i_type    => pk_edis_proc.g_sort_type_los,
                                                              i_episode => epis.id_episode) date_send_sort,
                   pk_patphoto.get_pat_photo(i_lang, i_prof, epis.id_patient, epis.id_episode, NULL) photo,
                   pk_patient_tracking.get_care_stage_grid_status(i_lang, i_prof, epis.id_episode, l_sysdate_char) care_stage,
                   pk_patient_tracking.get_current_state_rank(i_lang, i_prof, epis.id_episode) care_stage_rank,
                   (SELECT pk_translation.get_translation(i_lang,
                                                          'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' ||
                                                          epis.id_clinical_service)
                      FROM dual) cons_type,
                   pk_date_utils.to_char_insttimezone(i_prof, epis.dt_begin_tstz_e, g_date_mask) dt_begin,
                   pk_date_utils.date_char_hour_tsz(i_lang, epis.dt_begin_tstz_e, i_prof.institution, i_prof.software) dt_efectiv,
                   pk_date_utils.to_char_insttimezone(i_prof, epis.dt_first_obs_tstz, g_date_mask) dt_first_obs,
                   pk_date_utils.diff_timestamp(g_sysdate_tstz, epis.dt_begin_tstz_e) order_time,
                   pk_date_utils.get_elapsed_tsz(i_lang, epis.dt_begin_tstz_e, g_sysdate_tstz) date_send,
                   'N' flg_temp,
                   (SELECT nvl(nvl(r.desc_room_abbreviation,
                                   pk_translation.get_translation_dtchk(i_lang, 'ROOM.CODE_ABBREVIATION' || epis.id_room)),
                               nvl(r.desc_room,
                                   pk_translation.get_translation_dtchk(i_lang, 'ROOM.CODE_ROOM.' || epis.id_room)))
                      FROM dual) desc_room,
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
                   (SELECT pk_prof_utils.get_nickname(i_lang, epis.id_first_nurse_resp)
                      FROM dual) name_nurse,
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
                   lpad(to_char(sd.rank), 6, '0') || sd.img_name img_transp,
                   l_sysdate_char dt_server,
                   get_context_value(i_lang, i_prof, epis.id_episode, i_prof_cat_type, g_exam) desc_exam_req,
                   get_context_value(i_lang, i_prof, epis.id_visit, i_prof_cat_type, g_analysis) desc_analysis_req,
                   get_context_value(i_lang, i_prof, epis.id_episode, i_prof_cat_type, g_intervention) desc_interv_presc,
                   get_context_value(i_lang, i_prof, epis.id_episode, i_prof_cat_type, g_drug) desc_drug_presc,
                   get_context_value(i_lang, i_prof, epis.id_episode, i_prof_cat_type, g_monitorization) desc_monitorization,
                   pk_edis_grid.get_complaint_grid(i_lang, i_prof, epis.id_episode) desc_epis_anamnesis,
                   -- José Brito 23/02/2010 ALERT-721 ESI protocol data
                   (SELECT decode(epis.has_transfer,
                                  0,
                                  pk_fast_track.get_fast_track_icon(i_lang, i_prof, epis.id_fast_track, g_icon_ft),
                                  pk_fast_track.get_fast_track_icon(i_lang,
                                                                    i_prof,
                                                                    epis.id_episode,
                                                                    epis.id_fast_track,
                                                                    epis.id_triage_color,
                                                                    g_icon_ft_transfer,
                                                                    epis.has_transfer))
                      FROM dual) fast_track_icon,
                   decode(epis.triage_acuity, g_ft_color, g_ft_triage_white, g_ft_color) fast_track_color,
                   g_ft_status fast_track_status,
                   (SELECT pk_fast_track.get_fast_track_desc(i_lang, i_prof, epis.id_fast_track, g_desc_grid)
                      FROM dual) fast_track_desc,
                   (SELECT pk_edis_triage.get_epis_esi_level(i_lang, i_prof, epis.id_episode, epis.id_triage_color)
                      FROM dual) esi_level,
                   
                   decode(pk_prof_follow.get_follow_episode_by_me(i_prof, epis.id_episode, epis.id_schedule),
                          pk_alert_constant.g_no,
                          pk_alert_constant.g_yes,
                          pk_alert_constant.g_no) prof_follow_add,
                   pk_prof_follow.get_follow_episode_by_me(i_prof, epis.id_episode, epis.id_schedule) prof_follow_remove,
                   epis.id_schedule id_schedule
              FROM v_episode_act epis, sys_domain sd, room r
             WHERE sd.id_language = i_lang
               AND sd.val = epis.flg_status_ei
               AND sd.code_domain = 'EPIS_INFO.FLG_STATUS'
               AND sd.domain_owner = pk_sysdomain.k_default_schema
               AND EXISTS
             (SELECT 0
                      FROM profile_context pc
                     WHERE ( /* Checks any lab tests requested in that visit */
                            EXISTS (SELECT 0
                                      FROM lab_tests_ea t
                                     WHERE t.flg_status_req NOT IN
                                           (pk_lab_tests_constant.g_analysis_predefined,
                                            pk_lab_tests_constant.g_analysis_draft,
                                            pk_lab_tests_constant.g_analysis_exterior,
                                            pk_lab_tests_constant.g_analysis_read,
                                            pk_lab_tests_constant.g_analysis_cancel,
                                            pk_lab_tests_constant.g_analysis_read_partial,
                                            pk_lab_tests_constant.g_analysis_result,
                                            pk_lab_tests_constant.g_analysis_sched)
                                       AND pc.id_context = t.id_analysis
                                       AND t.id_visit = epis.id_visit
                                       AND pc.flg_type = g_analysis) --
                           /* Checks any exams requested in that episode */
                            OR EXISTS
                            (SELECT 0
                               FROM exams_ea t
                              WHERE t.flg_status_req NOT IN (pk_exam_constant.g_exam_predefined,
                                                             pk_exam_constant.g_exam_draft,
                                                             pk_exam_constant.g_exam_cancel,
                                                             pk_exam_constant.g_exam_result,
                                                             pk_exam_constant.g_exam_read_partial,
                                                             pk_exam_constant.g_exam_read)
                                AND pc.id_context = t.id_exam
                                AND epis.id_episode IN (t.id_episode, t.id_prev_episode)
                                AND pc.flg_type = g_exam) --
                           /* Checks any procedures requested in that episode */
                            OR EXISTS (SELECT 0
                                         FROM procedures_ea pea, interv_prescription ip
                                        WHERE pea.id_interv_prescription = ip.id_interv_prescription
                                          AND ip.flg_status IN (g_interv_req,
                                                                g_interv_pending,
                                                                pk_procedures_constant.g_interv_exec,
                                                                pk_procedures_constant.g_interv_partial)
                                          AND pea.flg_status_plan IN
                                              (g_interv_req, g_interv_pending, pk_procedures_constant.g_interv_exec)
                                          AND pc.id_context = pea.id_intervention
                                          AND epis.id_episode IN (ip.id_episode, ip.id_prev_episode)
                                          AND pc.flg_type = g_intervention) --
                           /* Checks any drugs prescripted in that episode */
                            OR EXISTS
                           /*(SELECT 0
                            FROM TABLE(pk_api_pfh_clindoc_in.get_rt_epis_drug_count(i_lang, i_prof, epis.id_episode)) med_tasks
                           WHERE med_tasks.id_drug = to_char(pc.id_context)
                                       AND pc.flg_type = g_drug)*/
                           
                            (SELECT 0
                               FROM TABLE(pk_api_pfh_clindoc_in.get_rt_epis_presc_id_drug(i_lang, i_prof, epis.id_episode)) med_tasks)
                           --
                           /* Checks any monitorizations requested in that episode */
                            OR EXISTS (SELECT 0
                                         FROM monitorizations_ea mea
                                        WHERE mea.flg_status IN (g_monit_active, g_monit_pending)
                                          AND pc.id_context = mea.id_vital_sign
                                          AND epis.id_episode IN (mea.id_episode, mea.id_prev_episode)
                                          AND pc.flg_type = g_monitorization))
                       AND epis.id_institution = i_prof.institution
                       AND pc.id_institution IN (epis.id_institution, 0)
                       AND pc.id_profile_template = g_current_profile
                       AND pc.flg_available = g_yes)
               AND epis.id_room = r.id_room(+)
             ORDER BY epis.triage_rank_acuity,
                      decode(pk_edis_grid.orderby_flg_letter(i_prof), pk_alert_constant.g_yes, epis.triage_flg_letter) DESC NULLS LAST,
                      epis.dt_begin_tstz_e;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            error_handling(i_lang, 'GET_GRID_MY_PAT_RT', g_error, SQLCODE, SQLERRM, o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_grid);
            RETURN FALSE;
    END get_grid_tasks_rt;

    PROCEDURE init_params_grid_tasks
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
        l_prof_cat category.flg_type%TYPE;
    
        l_hand_off_type sys_config.value%TYPE;
    
        l_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
        l_sysdate_char VARCHAR(50 CHAR);
    
        l_dt     VARCHAR2(100);
        l_dt_min schedule_outp.dt_target_tstz%TYPE;
        l_dt_max schedule_outp.dt_target_tstz%TYPE;
    
        l_dt_min_str VARCHAR2(100 CHAR);
        l_dt_max_str VARCHAR2(100 CHAR);
    
        --l_show_med_disch            sys_config.value%TYPE;
        l_waiting_room_available    sys_config.value%TYPE;
        l_waiting_room_sys_external sys_config.value%TYPE;
        l_reasongrid                sys_config.value%TYPE;
        l_category                  category.id_category%TYPE;
        l_type_opinion              opinion_type.id_opinion_type%TYPE;
        l_today                     TIMESTAMP WITH LOCAL TIME ZONE;
        l_prof_templ                profile_template.id_profile_template%TYPE;
        l_epis_type                 epis_type.id_epis_type%TYPE := 0;
    
        o_error t_error_out;
    BEGIN
    
        IF NOT preload_rt_shortcuts(l_lang, l_prof, o_error)
        THEN
            NULL;
        END IF;
    
        l_sysdate_tstz := current_timestamp;
        l_sysdate_char := pk_date_utils.date_send_tsz(l_lang, l_sysdate_tstz, l_prof);
    
        l_prof_cat := pk_prof_utils.get_category(l_lang, l_prof);
    
        pk_hand_off_core.get_hand_off_type(l_lang, l_prof, l_hand_off_type);
    
        g_current_profile := pk_prof_utils.get_prof_profile_template(l_prof);
    
        IF i_context_vals IS NOT NULL
           AND i_context_vals.count > 0
        THEN
            l_dt := i_context_vals(1);
            pk_context_api.set_parameter('l_dt', l_dt);
        
            IF i_context_vals.count > 1
            THEN
                IF i_context_vals(2) = pk_alert_constant.g_epis_type_outpatient
                THEN
                    CASE l_prof.software
                        WHEN pk_alert_constant.g_soft_social THEN
                            pk_context_api.set_parameter('l_epis_type', pk_alert_constant.g_epis_type_social);
                            l_epis_type := pk_alert_constant.g_epis_type_social;
                        WHEN pk_alert_constant.g_soft_nutritionist THEN
                            pk_context_api.set_parameter('l_epis_type', pk_alert_constant.g_epis_type_dietitian);
                            l_epis_type := pk_alert_constant.g_epis_type_dietitian;
                        WHEN pk_alert_constant.g_soft_psychologist THEN
                            pk_context_api.set_parameter('l_epis_type', pk_alert_constant.g_epis_type_psychologist);
                            l_epis_type := pk_alert_constant.g_epis_type_psychologist;
                        WHEN pk_alert_constant.g_soft_resptherap THEN
                            pk_context_api.set_parameter('l_epis_type', pk_alert_constant.g_epis_type_resp_therapist);
                            l_epis_type := pk_alert_constant.g_epis_type_resp_therapist;
                        ELSE
                            pk_context_api.set_parameter('l_epis_type', i_context_vals(2));
                            l_epis_type := i_context_vals(2);
                    END CASE;
                ELSE
                    pk_context_api.set_parameter('l_epis_type', i_context_vals(2));
                    l_epis_type := i_context_vals(2);
                END IF;
            
            END IF;
        ELSE
            pk_context_api.set_parameter('l_dt', NULL);
        END IF;
    
        l_dt_min := pk_date_utils.trunc_insttimezone(i_prof      => profissional(l_prof.id,
                                                                                 l_prof.institution,
                                                                                 l_prof.software),
                                                     i_timestamp => nvl(pk_date_utils.get_string_tstz(i_lang      => l_lang,
                                                                                                      i_prof      => profissional(l_prof.id,
                                                                                                                                  l_prof.institution,
                                                                                                                                  l_prof.software),
                                                                                                      i_timestamp => l_dt,
                                                                                                      i_timezone  => NULL),
                                                                        l_sysdate_tstz));
        -- the date max as to be 23:59:59 (that in seconds is 86399 seconds)                                                                        
        l_dt_max := pk_date_utils.add_to_ltstz(i_timestamp => l_dt_min,
                                               i_amount    => pk_grid_amb.g_day_in_seconds,
                                               i_unit      => 'SECOND');
    
        l_dt_min_str := pk_date_utils.get_timestamp_str(i_lang      => l_lang,
                                                        i_prof      => profissional(l_prof.id,
                                                                                    l_prof.institution,
                                                                                    l_prof.software),
                                                        i_timestamp => l_dt_min,
                                                        i_timezone  => NULL);
    
        l_dt_max_str := pk_date_utils.get_timestamp_str(i_lang      => l_lang,
                                                        i_prof      => profissional(l_prof.id,
                                                                                    l_prof.institution,
                                                                                    l_prof.software),
                                                        i_timestamp => l_dt_max,
                                                        i_timezone  => NULL);
    
        /*l_show_med_disch            := nvl(pk_sysconfig.get_config('SHOW_MEDICAL_DISCHARGED_GRID',
                                profissional(l_prof.id,
                                             l_prof.institution,
                                             l_prof.software)),
        pk_alert_constant.g_yes);*/
        l_waiting_room_available    := pk_sysconfig.get_config(pk_grid_amb.g_sys_config_wr,
                                                               profissional(l_prof.id,
                                                                            l_prof.institution,
                                                                            l_prof.software));
        l_waiting_room_sys_external := pk_sysconfig.get_config('WAITING_ROOM_EXTERNAL_SYSTEM',
                                                               profissional(l_prof.id,
                                                                            l_prof.institution,
                                                                            l_prof.software));
        l_reasongrid                := pk_sysconfig.get_config('REASON_FOR_VISIT_GRID',
                                                               profissional(l_prof.id,
                                                                            l_prof.institution,
                                                                            l_prof.software));
    
        l_category := pk_prof_utils.get_id_category(i_lang => l_lang,
                                                    i_prof => profissional(l_prof.id, l_prof.institution, l_prof.software));
    
        BEGIN
            SELECT ot.id_opinion_type
              INTO l_type_opinion
              FROM opinion_type_category ot
             WHERE ot.id_category = l_category;
        EXCEPTION
            WHEN OTHERS THEN
                l_type_opinion := NULL;
        END;
    
        l_today := pk_date_utils.trunc_insttimezone(profissional(l_prof.id, l_prof.institution, l_prof.software),
                                                    current_timestamp);
    
        l_prof_templ := pk_tools.get_prof_profile_template(i_prof => profissional(l_prof.id,
                                                                                  l_prof.institution,
                                                                                  l_prof.software));
    
        pk_context_api.set_parameter('l_lang', l_lang);
        pk_context_api.set_parameter('l_prof_id', l_prof.id);
        pk_context_api.set_parameter('l_prof_institution', l_prof.institution);
        pk_context_api.set_parameter('l_prof_software', l_prof.software);
        pk_context_api.set_parameter('l_current_profile', g_current_profile);
        pk_context_api.set_parameter('l_dt_min', l_dt_min_str);
        pk_context_api.set_parameter('l_dt_max', l_dt_max_str);
        --pk_context_api.set_parameter('l_show_med_disch', l_show_med_disch);
        pk_context_api.set_parameter('l_waiting_room_available', l_waiting_room_available);
        pk_context_api.set_parameter('l_waiting_room_sys_external', l_waiting_room_sys_external);
        pk_context_api.set_parameter('l_reasongrid', l_reasongrid);
        pk_context_api.set_parameter('l_prof_cat_type', l_prof_cat);
        pk_context_api.set_parameter('l_handoff_type', l_hand_off_type);
        pk_context_api.set_parameter('l_type_opinion', l_type_opinion);
        pk_context_api.set_parameter('l_today', l_today);
        pk_context_api.set_parameter('l_prof_templ', l_prof_templ);
        pk_context_api.set_parameter('l_category', l_category);
        pk_context_api.set_parameter('l_inactive_cfg', pk_alert_constant.g_yes);
    
        pk_context_api.set_parameter('l_time_config', pk_sysconfig.get_config('RT_TECH_INACT_EPIS_LOAD', l_prof));
    
        CASE i_name
            WHEN 'l_lang' THEN
                o_vc2 := to_char(l_lang);
            WHEN 'l_sysdate_char' THEN
                o_vc2 := l_sysdate_char;
            WHEN 'l_sysdate_tstz' THEN
                o_tstz := l_sysdate_tstz;
            WHEN 'l_prof_cat_type' THEN
                o_vc2 := l_prof_cat;
            WHEN 'l_hand_off_type' THEN
                o_vc2 := l_hand_off_type;
            WHEN 'l_id_i_prof' THEN
                o_vc2 := to_char(l_prof.id);
            WHEN 'l_id_institution' THEN
                o_vc2 := to_char(l_prof.institution);
            WHEN 'l_id_software' THEN
                o_vc2 := to_char(l_prof.software);
            WHEN 'l_dt_min' THEN
                o_vc2 := to_char(l_dt_min);
            WHEN 'l_dt_max' THEN
                o_vc2 := to_char(l_dt_max);
            WHEN 'l_waiting_room_available' THEN
                o_vc2 := l_waiting_room_available;
            WHEN 'l_waiting_room_sys_external' THEN
                o_vc2 := l_waiting_room_sys_external;
            WHEN 'l_reasongrid' THEN
                o_vc2 := l_reasongrid;
            WHEN 'l_dt' THEN
                o_vc2 := l_dt;
            WHEN 'l_handoff_type' THEN
                o_vc2 := l_hand_off_type;
            WHEN 'l_type_opinion' THEN
                o_vc2 := to_char(l_type_opinion);
            WHEN 'l_today' THEN
                o_vc2 := to_char(l_today);
            WHEN 'l_prof_templ' THEN
                o_vc2 := to_char(l_prof_templ);
            WHEN 'l_epis_type' THEN
                o_vc2 := to_char(l_epis_type);
            ELSE
                NULL;
        END CASE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => l_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_RT_TECH',
                                              i_function => 'INIT_PARAMS_GRID_TASKS',
                                              o_error    => o_error);
    END init_params_grid_tasks;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_rt_tech;
/
