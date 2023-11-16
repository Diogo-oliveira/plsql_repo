/*-- Last Change Revision: $Rev: 2027808 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:22 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_tracking_view IS

    TYPE t_bool IS TABLE OF BOOLEAN INDEX BY BINARY_INTEGER;
    TYPE t_img IS TABLE OF sys_domain.img_name%TYPE INDEX BY BINARY_INTEGER;

    g_flg_exec_glob t_bool;

    g_exam_flg_status_req_img    t_img;
    g_exam_flg_status_mov_img    t_img;
    g_exam_flg_status_exec_img   t_img;
    g_exam_flg_status_result_img t_img;
    g_exam_flg_status_read_img   t_img;
    g_exam_flg_status_ext_img    t_img;
    g_exam_flg_status_perf_img   t_img;
    g_exam_flg_status_wtg_img    t_img;
    g_exam_flg_status_sos_img    t_img;
    g_lab_flg_status_pend_img    t_img;
    g_lab_flg_status_harv_img    t_img;
    g_lab_flg_status_trans_img   t_img;
    g_lab_flg_status_exec_img    t_img;
    g_lab_flg_status_result_img  t_img;
    g_lab_flg_status_read_img    t_img;
    g_lab_flg_status_ext_img     t_img;
    g_lab_flg_status_wtg_img     t_img;
    g_lab_flg_status_sos_img     t_img;
    g_lab_flg_status_cc_img      t_img;

    g_interv_flg_status_exec_img  t_img;
    g_interv_flg_status_fin_img   t_img;
    g_interv_flg_status_ext_img   t_img;
    g_interv_nurse_status_fin_img t_img;

    g_monit_det_exec_img t_img;
    g_monit_det_fini_img t_img;

    g_interv_msg_it056 t_img;

    g_msg_drug_sos sys_message.desc_message%TYPE;

    g_grid_origins     sys_config.value%TYPE;
    g_tab_grid_origins table_varchar;

    FUNCTION get_all_edis_epis_internal
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_room          IN room.id_room%TYPE,
        i_flg_view      IN VARCHAR2,
        i_anon          IN VARCHAR2,
        i_show_photo    IN VARCHAR2,
        i_external_tr   IN VARCHAR2,
        i_id_department IN department.id_department%TYPE DEFAULT NULL,
        o_rows          OUT pk_types.cursor_type,
        o_dt_server     OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_msg_empty_room   sys_message.desc_message%TYPE;
        l_config_refresh   sys_config.id_sys_config%TYPE;
        l_tab_triage_types table_number;
        l_hand_off_type    sys_config.value%TYPE;
    
        l_config_origin CONSTANT sys_config.id_sys_config%TYPE := 'GRID_ORIGINS';
    
        --l_config_show_complaint CONSTANT sys_config.id_sys_config%TYPE := 'TRACKING_VIEW_SHOW_COMPLAINT';
        l_config_show_resident CONSTANT sys_config.id_sys_config%TYPE := 'GRIDS_SHOW_RESIDENT';
        l_config_orderby       CONSTANT sys_config.id_sys_config%TYPE := 'TRACKING_VIEW_ORDERBY';
    
        -- config to be used exclusively during an upgrade with migrated patients
        l_config_temp_room CONSTANT sys_config.id_sys_config%TYPE := 'MIGRATE_PATIENTS_TEMP_ROOM';
    
        --l_orderby_color CONSTANT sys_config.value%TYPE := 'C';
        l_orderby_room CONSTANT sys_config.value%TYPE := 'R';
        l_orderby_los  CONSTANT sys_config.value%TYPE := 'L';
    
        l_show_only_epis_resp sys_config.value%TYPE;
    
        l_show_resident_physician sys_config.value%TYPE;
        l_orderby                 sys_config.value%TYPE;
        l_temp_room               sys_config.value%TYPE;
        l_orign_order_without_tri sys_config.value%TYPE;
    
        l_prof_cat category.flg_type%TYPE;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        g_error          := 'GET CONFIGURATIONS';
        l_config_refresh := pk_sysconfig.get_config('TRACKING_VIEW_REFRESH',
                                                    i_prof.institution,
                                                    pk_alert_constant.g_soft_edis);
    
        l_show_resident_physician := pk_sysconfig.get_config(i_code_cf => l_config_show_resident, i_prof => i_prof);
        l_orderby                 := pk_sysconfig.get_config(i_code_cf => l_config_orderby, i_prof => i_prof);
        l_temp_room               := pk_sysconfig.get_config(i_code_cf => l_config_temp_room, i_prof => i_prof);
        l_show_only_epis_resp     := pk_sysconfig.get_config(i_code_cf => pk_hand_off_core.g_config_show_only_epis_resp,
                                                             i_prof    => i_prof);
        l_orign_order_without_tri := pk_sysconfig.get_config(i_code_cf => 'EDIS_GRID_ORIGIN_ORDER_WITHOUT_TRIAGE',
                                                             i_prof    => i_prof);
        l_tab_triage_types        := pk_edis_triage.tf_get_inst_triag_types(i_prof.institution);
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
    
        l_prof_cat := pk_edis_list.get_prof_cat(i_prof);
    
        g_error     := 'DO DT SERVER';
        o_dt_server := pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
    
        g_error          := 'GET EMPTY ROOM MSG';
        l_msg_empty_room := pk_message.get_message(i_lang, 'TRACK_VIEW_M002');
        g_msg_drug_sos   := pk_message.get_message(i_lang, 'DRUG_PRESC_M004');
    
        -- 'Prefetch' of some informating to avoid repeated calls inside the main query
        -- This code block is meant to increase the query performance and it's executed only once (in order with g_flg_exec_glob var)
        -- Result depends on the language id
        -- This is valid to a scenario where the sessions are kept (which is not the current scenario)
        --
        -- ATTENTION: new status must be used here
        --
        -- TODO: encapsulate inside a function
    
        IF NOT g_flg_exec_glob.exists(i_lang)
        THEN
            g_flg_exec_glob(i_lang) := FALSE;
        END IF;
    
        IF NOT g_flg_exec_glob(i_lang)
        THEN
            g_exam_flg_status_req_img(i_lang) := pk_sysdomain.get_img(i_lang,
                                                                      'EXAM_REQ_DET.FLG_STATUS',
                                                                      pk_alert_constant.g_exam_det_req);
            g_exam_flg_status_mov_img(i_lang) := pk_sysdomain.get_img(i_lang,
                                                                      'MOVEMENT.FLG_STATUS',
                                                                      pk_alert_constant.g_mov_status_transp);
            g_exam_flg_status_exec_img(i_lang) := pk_sysdomain.get_img(i_lang,
                                                                       'EXAM_REQ_DET.FLG_STATUS',
                                                                       pk_alert_constant.g_exam_det_exec);
            g_exam_flg_status_result_img(i_lang) := pk_sysdomain.get_img(i_lang,
                                                                         'EXAM_REQ_DET.FLG_STATUS',
                                                                         pk_alert_constant.g_exam_det_result);
            g_exam_flg_status_read_img(i_lang) := pk_sysdomain.get_img(i_lang,
                                                                       'EXAM_REQ_DET.FLG_STATUS',
                                                                       pk_alert_constant.g_exam_det_read);
            g_exam_flg_status_ext_img(i_lang) := pk_sysdomain.get_img(i_lang,
                                                                      'EXAM_REQ_DET.FLG_STATUS',
                                                                      pk_alert_constant.g_exam_det_ext);
            g_exam_flg_status_perf_img(i_lang) := pk_sysdomain.get_img(i_lang,
                                                                       'EXAM_REQ_DET.FLG_STATUS',
                                                                       pk_alert_constant.g_exam_det_performed);
            g_exam_flg_status_wtg_img(i_lang) := pk_sysdomain.get_img(i_lang,
                                                                      'EXAM_REQ_DET.FLG_STATUS',
                                                                      pk_exam_constant.g_exam_wtg_tde);
            g_exam_flg_status_sos_img(i_lang) := pk_sysdomain.get_img(i_lang,
                                                                      'EXAM_REQ_DET.FLG_STATUS',
                                                                      pk_exam_constant.g_exam_sos);
            g_lab_flg_status_pend_img(i_lang) := pk_sysdomain.get_img(i_lang,
                                                                      'ANALYSIS_REQ_DET.FLG_STATUS',
                                                                      pk_alert_constant.g_analysis_det_pend);
            g_lab_flg_status_harv_img(i_lang) := pk_sysdomain.get_img(i_lang,
                                                                      'HARVEST.FLG_STATUS',
                                                                      pk_alert_constant.g_harvest_harv);
            g_lab_flg_status_trans_img(i_lang) := pk_sysdomain.get_img(i_lang,
                                                                       'HARVEST.FLG_STATUS',
                                                                       pk_alert_constant.g_harvest_trans);
            g_lab_flg_status_exec_img(i_lang) := pk_sysdomain.get_img(i_lang,
                                                                      'ANALYSIS_REQ_DET.FLG_STATUS',
                                                                      pk_alert_constant.g_analysis_det_exec);
            g_lab_flg_status_result_img(i_lang) := pk_sysdomain.get_img(i_lang,
                                                                        'ANALYSIS_REQ_DET.FLG_STATUS',
                                                                        pk_alert_constant.g_analysis_det_result);
            g_lab_flg_status_read_img(i_lang) := pk_sysdomain.get_img(i_lang,
                                                                      'ANALYSIS_REQ_DET.FLG_STATUS',
                                                                      pk_alert_constant.g_analysis_det_read);
            g_lab_flg_status_ext_img(i_lang) := pk_sysdomain.get_img(i_lang,
                                                                     'ANALYSIS_REQ_DET.FLG_STATUS',
                                                                     pk_alert_constant.g_analysis_det_ext);
            g_lab_flg_status_wtg_img(i_lang) := pk_sysdomain.get_img(i_lang,
                                                                     'ANALYSIS_REQ_DET.FLG_STATUS',
                                                                     pk_lab_tests_constant.g_analysis_wtg_tde);
            g_lab_flg_status_sos_img(i_lang) := pk_sysdomain.get_img(i_lang,
                                                                     'ANALYSIS_REQ_DET.FLG_STATUS',
                                                                     pk_lab_tests_constant.g_analysis_sos);
            g_lab_flg_status_cc_img(i_lang) := pk_sysdomain.get_img(i_lang,
                                                                    'ANALYSIS_REQ_DET.FLG_STATUS',
                                                                    pk_lab_tests_constant.g_analysis_oncollection);
            g_monit_det_exec_img(i_lang) := pk_sysdomain.get_img(i_lang,
                                                                 'MONITORIZATION_VS.FLG_STATUS',
                                                                 pk_alert_constant.g_monitor_vs_exec);
            g_monit_det_fini_img(i_lang) := pk_sysdomain.get_img(i_lang,
                                                                 'MONITORIZATION_VS.FLG_STATUS',
                                                                 pk_alert_constant.g_monitor_vs_fini);
        
            g_interv_flg_status_exec_img(i_lang) := pk_sysdomain.get_img(i_lang,
                                                                         'INTERV_PRESC_DET.FLG_STATUS',
                                                                         pk_alert_constant.g_interv_det_exec);
            g_interv_flg_status_fin_img(i_lang) := pk_sysdomain.get_img(i_lang,
                                                                        'INTERV_PRESC_DET.FLG_STATUS',
                                                                        pk_alert_constant.g_interv_det_fin);
        
            g_interv_flg_status_ext_img(i_lang) := pk_sysdomain.get_img(i_lang,
                                                                        'INTERV_PRESC_DET.FLG_STATUS',
                                                                        pk_alert_constant.g_interv_det_ext);
        
            g_interv_msg_it056(i_lang) := pk_message.get_message(i_lang, 'ICON_T056');
        
            g_flg_exec_glob(i_lang) := TRUE;
        
        END IF;
    
        g_error        := 'OPEN O_ROWS';
        g_grid_origins := pk_sysconfig.get_config(l_config_origin, i_prof);
    
        pk_edis_grid.g_tab_grid_origins := pk_utils.str_split_l(g_grid_origins, '|');
    
        OPEN o_rows FOR
        --episodes
            SELECT id_episode,
                   id_patient,
                   refresh_interval,
                   dt_first_obs,
                   acuity,
                   color_text,
                   rank_acuity,
                   epi_duration,
                   length_of_stay_bg_color,
                   date_send_sort,
                   dt_begin,
                   desc_room,
                   desc_bed,
                   pat_name,
                   name_pat_sort,
                   pat_ndo,
                   pat_nd_icon,
                   pat_gender,
                   pat_age,
                   care_stage,
                   care_stage_rank,
                   name_prof,
                   name_nurse,
                   prof_team,
                   name_prof_tooltip,
                   name_nurse_tooltip,
                   prof_team_tooltip,
                   desc_exam,
                   desc_oth_exam,
                   desc_analysis,
                   desc_monit,
                   desc_interv,
                   desc_interv_monit,
                   desc_drug,
                   desc_mov,
                   desc_opinion,
                   desc_opinion_popup,
                   fast_track_icon,
                   fast_track_color,
                   fast_track_status,
                   avail_butt_ok,
                   fast_track_desc,
                   esi_level,
                   pat_photo,
                   desc_destination,
                   desc_origin,
                   resp_icons,
                   pat_age_for_order_by,
                   prof_follow_add,
                   prof_follow_remove,
                   pat_major_inc_icon,
                   origin_rank,
                   rank_letter,
                   rownum rank_triage,
                   desc_origin_full,
                   desc_destination_tooltip
              FROM (SELECT *
                      FROM (SELECT tbea.id_episode,
                                   tbea.id_patient,
                                   l_config_refresh refresh_interval,
                                   (SELECT pk_episode.get_epis_dt_first_obs(i_lang,
                                                                            i_prof,
                                                                            tbea.id_episode,
                                                                            ei.dt_first_obs_tstz,
                                                                            tbea.flg_has_stripes)
                                      FROM dual) dt_first_obs,
                                   ei.triage_acuity acuity,
                                   ei.triage_color_text color_text,
                                   to_number(ei.triage_rank_acuity) rank_acuity,
                                   (SELECT pk_edis_proc.get_los_duration(i_lang       => i_lang,
                                                                         i_prof       => i_prof,
                                                                         i_id_episode => tbea.id_episode)
                                      FROM dual) epi_duration, -- Length of stay
                                   (SELECT pk_edis_grid.get_length_of_stay_color(i_prof,
                                                                                 pk_edis_proc.get_los_duration_number(i_lang       => i_lang,
                                                                                                                      i_prof       => i_prof,
                                                                                                                      i_id_episode => epis.id_episode))
                                      FROM dual) length_of_stay_bg_color,
                                   (SELECT pk_edis_proc.get_formatted_string_for_sort(i_lang    => i_lang,
                                                                                      i_prof    => i_prof,
                                                                                      i_type    => pk_edis_proc.g_sort_type_los,
                                                                                      i_episode => epis.id_episode)
                                      FROM dual) date_send_sort, -- Length of stay for sort purposes
                                   (SELECT pk_date_utils.date_send_tsz(i_lang, tbea.dt_begin, i_prof)
                                      FROM dual) dt_begin,
                                   (SELECT nvl(r.desc_room,
                                               pk_translation.get_translation_dtchk(i_lang,
                                                                                    'ROOM.CODE_ROOM.' || tbea.id_room))
                                      FROM room r
                                     WHERE r.id_room = tbea.id_room) desc_room,
                                   nvl(b.desc_bed, pk_translation.get_translation(i_lang, b.code_bed)) desc_bed,
                                   decode(i_anon,
                                          pk_alert_constant.g_yes,
                                          '',
                                          (SELECT pk_patient.get_pat_name(i_lang, i_prof, epis.id_patient, epis.id_episode)
                                             FROM dual)) pat_name,
                                   decode(i_anon,
                                          pk_alert_constant.g_yes,
                                          '',
                                          (SELECT pk_patient.get_pat_name_to_sort(i_lang,
                                                                                  i_prof,
                                                                                  epis.id_patient,
                                                                                  epis.id_episode,
                                                                                  NULL)
                                             FROM dual)) name_pat_sort,
                                   decode(i_anon,
                                          pk_alert_constant.g_yes,
                                          '',
                                          (SELECT pk_adt.get_pat_non_disc_options(i_lang, i_prof, epis.id_patient)
                                             FROM dual)) pat_ndo,
                                   decode(i_anon,
                                          pk_alert_constant.g_yes,
                                          '',
                                          (SELECT pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, epis.id_patient)
                                             FROM dual)) pat_nd_icon,
                                   (SELECT decode(i_anon,
                                                  pk_alert_constant.g_yes,
                                                  '',
                                                  pk_patient.get_gender(i_lang, pat.gender))
                                      FROM dual) pat_gender,
                                   decode(i_anon,
                                          pk_alert_constant.g_yes,
                                          '',
                                          (SELECT pk_patient.get_pat_age(i_lang,
                                                                         pat.dt_birth,
                                                                         pat.age,
                                                                         i_prof.institution,
                                                                         i_prof.software)
                                             FROM dual)) pat_age,
                                   (SELECT pk_patient_tracking.get_care_stage_grid_status(i_lang,
                                                                                          i_prof,
                                                                                          tbea.id_episode,
                                                                                          o_dt_server)
                                      FROM dual) care_stage,
                                   (SELECT pk_patient_tracking.get_current_state_rank(i_lang, i_prof, epis.id_episode)
                                      FROM dual) care_stage_rank,
                                   -- Display number of responsible PHYSICIANS for the episode, 
                                   -- if institution is using the multiple hand-off mechanism,
                                   -- along with the name of the main responsible for the patient.
                                   (SELECT pk_hand_off_core.get_responsibles_str(i_lang,
                                                                                 i_prof,
                                                                                 pk_alert_constant.g_cat_type_doc,
                                                                                 tbea.id_episode,
                                                                                 tbea.id_prof_resp,
                                                                                 l_hand_off_type,
                                                                                 'G',
                                                                                 l_show_only_epis_resp)
                                      FROM dual) name_prof,
                                   (SELECT nvl(nick_name, name)
                                      FROM professional p
                                     WHERE p.id_professional = tbea.id_nurse_resp) name_nurse,
                                   decode(l_show_resident_physician,
                                          pk_alert_constant.g_yes,
                                          (SELECT pk_hand_off_core.get_resp_by_type_grid_str(i_lang,
                                                                                             i_prof,
                                                                                             tbea.id_episode,
                                                                                             l_hand_off_type,
                                                                                             pk_hand_off_core.g_resident,
                                                                                             'G')
                                             FROM dual),
                                          (SELECT pk_prof_teams.get_prof_current_team(i_lang,
                                                                                      i_prof,
                                                                                      epis.id_department,
                                                                                      ei.id_software,
                                                                                      tbea.id_prof_resp,
                                                                                      tbea.id_nurse_resp)
                                             FROM dual)) prof_team,
                                   -- Display text in tooltips
                                   -- 1) Responsible physician(s)
                                   (SELECT pk_hand_off_core.get_responsibles_str(i_lang,
                                                                                 i_prof,
                                                                                 pk_alert_constant.g_cat_type_doc,
                                                                                 tbea.id_episode,
                                                                                 tbea.id_prof_resp,
                                                                                 l_hand_off_type,
                                                                                 'T')
                                      FROM dual) name_prof_tooltip,
                                   -- 2) Responsible nurse
                                   (SELECT pk_hand_off_core.get_responsibles_str(i_lang,
                                                                                 i_prof,
                                                                                 pk_alert_constant.g_cat_type_nurse,
                                                                                 tbea.id_episode,
                                                                                 tbea.id_nurse_resp,
                                                                                 l_hand_off_type,
                                                                                 'T')
                                      FROM dual) name_nurse_tooltip,
                                   -- 3) Responsible team
                                   (SELECT pk_hand_off_core.get_team_str(i_lang,
                                                                         i_prof,
                                                                         epis.id_department,
                                                                         ei.id_software,
                                                                         tbea.id_prof_resp,
                                                                         tbea.id_nurse_resp,
                                                                         l_hand_off_type,
                                                                         NULL)
                                      FROM dual) prof_team_tooltip,
                                   -- exams processing  
                                   (SELECT pk_tracking_view.get_epis_exam_desc(i_lang, i_prof, tbea.rowid)
                                      FROM dual) desc_exam,
                                   -- other exams processing
                                   pk_tracking_view.get_epis_oth_exam_desc(i_lang, i_prof, tbea.rowid) desc_oth_exam,
                                   -- analysis processing
                                   (SELECT pk_tracking_view.get_epis_lab_desc(i_lang, i_prof, tbea.rowid)
                                      FROM dual) desc_analysis,
                                   -- monitorizations processing
                                   (SELECT pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, g.monitorization)
                                      FROM grid_task g
                                     WHERE g.id_episode = epis.id_episode) desc_monit,
                                   -- interventions processing                   
                                   (SELECT pk_tracking_view.get_epis_interv_desc(i_lang, i_prof, tbea.id_episode)
                                      FROM dual) desc_interv,
                                   -- monitorizations and interventions processing 
                                   pk_string_utils.concat_if_exists((SELECT pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                                                                  i_prof,
                                                                                                                  g.monitorization)
                                                                      FROM grid_task g
                                                                     WHERE g.id_episode = epis.id_episode),
                                                                    decode(aw.flg_interv_prescription,
                                                                           pk_alert_constant.g_yes,
                                                                           pk_tracking_view.get_epis_interv_desc(i_lang,
                                                                                                                 i_prof,
                                                                                                                 tbea.id_episode),
                                                                           decode(aw.flg_nurse_activity_req,
                                                                                  pk_alert_constant.g_yes,
                                                                                  pk_tracking_view.get_epis_interv_desc(i_lang,
                                                                                                                        i_prof,
                                                                                                                        tbea.id_episode),
                                                                                  (pk_tracking_view.get_epis_interv_desc(i_lang,
                                                                                                                         i_prof,
                                                                                                                         tbea.id_episode)))),
                                                                    '; ') desc_interv_monit,
                                   -- drug prescriptions processing
                                   (SELECT pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, g.drug_presc)
                                      FROM grid_task g
                                     WHERE g.id_episode = tbea.id_episode) desc_drug,
                                   -- transportations processing
                                   substr(decode(tbea.transp_delay,
                                                 NULL,
                                                 NULL,
                                                 ';' || (SELECT get_status_string(i_lang         => i_lang,
                                                                                  i_prof         => i_prof,
                                                                                  i_display_type => pk_alert_constant.g_display_type_date,
                                                                                  i_value_date   => pk_date_utils.date_send_tsz(i_lang,
                                                                                                                                to_timestamp_tz(tbea.transp_delay,
                                                                                                                                                pk_alert_constant.g_dt_yyyymmddhh24miss_tzr),
                                                                                                                                i_prof),
                                                                                  i_value_icon   => NULL,
                                                                                  i_color        => pk_alert_constant.g_color_red)
                                                           FROM dual)) ||
                                          decode(tbea.transp_ongoing,
                                                 NULL,
                                                 NULL,
                                                 ';' || (SELECT get_status_string(i_lang         => i_lang,
                                                                                  i_prof         => i_prof,
                                                                                  i_display_type => pk_alert_constant.g_display_type_date_icon,
                                                                                  i_value_date   => pk_date_utils.date_send_tsz(i_lang,
                                                                                                                                to_timestamp_tz(tbea.transp_ongoing,
                                                                                                                                                pk_alert_constant.g_dt_yyyymmddhh24miss_tzr),
                                                                                                                                i_prof),
                                                                                  i_value_icon   => g_exam_flg_status_mov_img(i_lang),
                                                                                  i_color        => pk_alert_constant.g_color_none)
                                                           FROM dual)),
                                          2) desc_mov,
                                   -- Opinion       
                                   substr((SELECT concatenate(';' || CASE
                                                                  WHEN o.flg_state IN
                                                                       (pk_opinion.g_opinion_req, pk_opinion.g_opinion_req_read) THEN
                                                                   (SELECT get_status_string(i_lang         => i_lang,
                                                                                             i_prof         => i_prof,
                                                                                             i_display_type => pk_alert_constant.g_display_type_date,
                                                                                             i_value_date   => pk_date_utils.date_send_tsz(i_lang,
                                                                                                                                           o.dt_problem_tstz,
                                                                                                                                           i_prof),
                                                                                             i_value_icon   => NULL,
                                                                                             i_color        => pk_alert_constant.g_color_red)
                                                                      FROM dual)
                                                                  ELSE
                                                                   (SELECT get_status_string(i_lang         => i_lang,
                                                                                             i_prof         => i_prof,
                                                                                             i_display_type => pk_alert_constant.g_display_type_icon,
                                                                                             i_value_date   => NULL,
                                                                                             i_value_icon   => pk_sysdomain.get_img(i_lang,
                                                                                                                                    pk_opinion.g_opinion_consults,
                                                                                                                                    pk_opinion.g_opinion_reply),
                                                                                             i_color        => pk_alert_constant.g_color_none)
                                                                      FROM dual)
                                                              END) state
                                            FROM opinion o
                                           WHERE o.id_episode = tbea.id_episode
                                             AND o.flg_state != pk_opinion.g_opinion_cancel
                                             AND o.id_opinion_type IS NULL),
                                          2) desc_opinion,
                                   (SELECT pk_opinion.get_epis_last_opinion_popup(i_lang, i_prof, tbea.id_episode)
                                      FROM dual) desc_opinion_popup,
                                   -- José Brito 08/03/2010 ALERT-721 
                                   (SELECT pk_fast_track.get_fast_track_icon(i_lang,
                                                                             i_prof,
                                                                             tbea.id_episode,
                                                                             tbea.id_fast_track,
                                                                             tbea.id_triage_color,
                                                                             NULL,
                                                                             NULL)
                                      FROM dual) fast_track_icon,
                                   decode(ei.triage_acuity,
                                          pk_alert_constant.g_ft_color,
                                          pk_alert_constant.g_ft_triage_white,
                                          pk_alert_constant.g_ft_color) fast_track_color,
                                   pk_alert_constant.g_ft_status fast_track_status,
                                   pk_alert_constant.g_yes avail_butt_ok,
                                   (SELECT pk_fast_track.get_fast_track_desc(i_lang,
                                                                             i_prof,
                                                                             tbea.id_episode,
                                                                             tbea.id_fast_track,
                                                                             pk_alert_constant.g_desc_grid)
                                      FROM dual) fast_track_desc,
                                   (SELECT pk_edis_triage.get_epis_esi_level(i_lang,
                                                                             i_prof,
                                                                             tbea.id_episode,
                                                                             tbea.id_triage_color)
                                      FROM dual) esi_level,
                                   decode(i_show_photo,
                                          pk_alert_constant.g_yes,
                                          (SELECT pk_patphoto.get_pat_foto_url(i_lang,
                                                                               epis.id_patient,
                                                                               i_prof,
                                                                               epis.id_episode,
                                                                               ei.id_schedule,
                                                                               'Y')
                                             FROM dual),
                                          NULL) pat_photo,
                                   -- destination (opinions or discharge department)
                                   (SELECT get_epis_destination(i_lang,
                                                                i_prof,
                                                                epis.id_episode,
                                                                ei.id_disch_reas_dest,
                                                                ei.flg_dsch_status)
                                      FROM dual) desc_destination,
                                   (SELECT pk_opinion.get_consultations_tooltip(i_lang, i_prof, epis.id_episode)
                                      FROM dual) desc_destination_tooltip,
                                   -- visit origin and chief complaint
                                   (SELECT pk_string_utils.concat_if_exists((SELECT pk_edis_grid.get_grid_origin_abbrev(i_lang,
                                                                                                                       i_prof,
                                                                                                                       v.id_origin)
                                                                              FROM visit v
                                                                             WHERE v.id_visit = epis.id_visit),
                                                                            (SELECT pk_edis_grid.get_complaint_grid(i_lang,
                                                                                                                    i_prof,
                                                                                                                    epis.id_episode)
                                                                               FROM dual),
                                                                            ' / ')
                                      FROM dual) desc_origin,
                                   
                                   --Alexandre Santos 13-10-2010 ALERT-726 Changing and cancelling appointmentsChanging to another physician with the same specialty as the responsible physician. However, the responsible physician remains the same.
                                   (SELECT pk_hand_off_api.get_resp_icons(i_lang, i_prof, epis.id_episode, l_hand_off_type)
                                      FROM dual) resp_icons,
                                   (SELECT pk_edis_proc.get_formatted_string_for_sort(i_lang    => i_lang,
                                                                                      i_prof    => i_prof,
                                                                                      i_type    => pk_edis_proc.g_sort_type_age,
                                                                                      i_episode => epis.id_episode)
                                      FROM dual) pat_age_for_order_by,
                                   decode((SELECT pk_prof_follow.get_follow_episode_by_me(i_prof, epis.id_episode, -1)
                                            FROM dual),
                                          pk_alert_constant.g_no,
                                          decode(pk_utils.search_table_number((SELECT pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                                                         i_prof,
                                                                                                                         epis.id_episode,
                                                                                                                         l_prof_cat,
                                                                                                                         l_hand_off_type,
                                                                                                                         pk_alert_constant.g_yes)
                                                                                FROM dual),
                                                                              i_prof.id),
                                                 -1,
                                                 pk_alert_constant.g_yes,
                                                 pk_alert_constant.g_no),
                                          pk_alert_constant.g_no) prof_follow_add,
                                   (SELECT pk_prof_follow.get_follow_episode_by_me(i_prof, epis.id_episode, -1)
                                      FROM dual) prof_follow_remove,
                                   --Gisela Couto 04-09-2014  ALERT-284142 Major incident icon
                                   (SELECT pk_adt_core.check_bulk_admission_episode(i_lang       => i_lang,
                                                                                    i_prof       => i_prof,
                                                                                    i_id_episode => epis.id_episode)
                                      FROM dual) pat_major_inc_icon,
                                   decode(l_orign_order_without_tri,
                                          pk_alert_constant.g_yes,
                                          decode(pk_edis_triage.get_flag_no_color(i_lang, i_prof, tbea.id_triage_color),
                                                 'S',
                                                 0,
                                                 decode(pk_utils.search_table_varchar(pk_edis_grid.g_tab_grid_origins,
                                                                                      (SELECT id_origin
                                                                                         FROM visit
                                                                                        WHERE id_visit = epis.id_visit)),
                                                        -1,
                                                        1,
                                                        0)),
                                          decode(pk_utils.search_table_varchar(pk_edis_grid.g_tab_grid_origins,
                                                                               (SELECT id_origin
                                                                                  FROM visit
                                                                                 WHERE id_visit = epis.id_visit)),
                                                 -1,
                                                 1,
                                                 0)) origin_rank,
                                   decode(orderby_flg_letter(i_prof),
                                          pk_alert_constant.g_yes,
                                          decode(ei.triage_flg_letter, pk_alert_constant.g_yes, 0, 1)) rank_letter,
                                   (SELECT pk_string_utils.concat_if_exists((SELECT pk_edis_grid.get_grid_origin(i_lang,
                                                                                                                i_prof,
                                                                                                                v.id_origin)
                                                                              FROM visit v
                                                                             WHERE v.id_visit = epis.id_visit),
                                                                            (SELECT pk_edis_grid.get_complaint_grid(i_lang,
                                                                                                                    i_prof,
                                                                                                                    epis.id_episode)
                                                                               FROM dual),
                                                                            chr(13))
                                      FROM dual) desc_origin_full,
                                   v.id_origin id_origin
                              FROM tracking_board_ea tbea,
                                   episode           epis,
                                   epis_info         ei,
                                   patient           pat,
                                   awareness         aw,
                                   bed               b,
                                   visit             v, 
                                   room r
                             WHERE tbea.id_epis_type = pk_alert_constant.g_epis_type_emergency
                               AND (tbea.id_room = i_room OR i_room IS NULL)
                               AND epis.id_episode = tbea.id_episode
                               AND epis.id_institution = i_prof.institution
                               AND tbea.id_episode = ei.id_episode
                               AND tbea.id_patient = pat.id_patient
                               AND v.id_visit = epis.id_visit
                               and tbea.id_room = r.id_room
                               AND aw.id_patient = tbea.id_patient
                               AND aw.id_episode = tbea.id_episode
                               AND b.id_bed(+) = tbea.id_bed
                               AND ei.id_room <> l_temp_room
                               AND (i_id_department IS NULL OR r.id_department = i_id_department)
                               AND (i_flg_view <> 'V3' OR (i_flg_view = 'V3' AND EXISTS
                                    (SELECT 1
                                                              FROM prof_room pr
                                                             WHERE pr.id_professional = i_prof.id
                                                               AND pr.id_room IN (ei.id_room))))
                            UNION ALL
                            --empty rooms
                            SELECT NULL id_episode,
                                   NULL id_patient,
                                   l_config_refresh refresh_interval,
                                   o_dt_server dt_first_obs,
                                   tc.color acuity,
                                   tc.color color_text,
                                   tc.rank rank_acuity,
                                   NULL epi_duration,
                                   NULL length_of_stay_bg_color,
                                   NULL date_send_sort,
                                   NULL dt_begin,
                                   (SELECT nvl(room.desc_room, pk_translation.get_translation(i_lang, room.code_room))
                                      FROM dual) desc_room,
                                   NULL desc_bed,
                                   l_msg_empty_room pat_name,
                                   NULL name_pat_sort,
                                   NULL pat_ndo,
                                   NULL pat_nd_icon,
                                   NULL pat_gender,
                                   NULL pat_age,
                                   NULL care_stage,
                                   NULL care_stage_rank,
                                   NULL name_prof,
                                   NULL name_nurse,
                                   NULL prof_team,
                                   NULL name_prof_tooltip,
                                   NULL name_nurse_tooltip,
                                   NULL prof_team_tooltip,
                                   NULL desc_exam,
                                   NULL desc_oth_exam,
                                   NULL desc_analysis,
                                   NULL desc_monit,
                                   NULL desc_interv,
                                   NULL desc_interv_monit,
                                   NULL desc_drug,
                                   NULL desc_consults,
                                   NULL desc_mov,
                                   NULL desc_opinion_popup,
                                   NULL fast_track_icon,
                                   NULL fast_track_color,
                                   NULL fast_track_status,
                                   'N' avail_butt_ok,
                                   NULL fast_track_desc,
                                   NULL esi_level,
                                   NULL pat_photo,
                                   NULL desc_destination,
                                   NULL desc_destination_tooltip,
                                   NULL desc_origin,
                                   NULL resp_icons,
                                   NULL pat_age_for_order_by,
                                   pk_alert_constant.g_no prof_follow_add,
                                   pk_alert_constant.g_no prof_follow_remove,
                                   NULL pat_major_inc_icon,
                                   999 origin_rank,
                                   NULL rank_letter,
                                   NULL desc_origin_full,
                                   NULL origin
                              FROM software_dept sd, department dt, room, triage_color tc
                             WHERE room.flg_available = pk_alert_constant.g_yes
                               AND NOT EXISTS
                             (SELECT 0
                                      FROM tracking_board_ea tbea
                                     WHERE tbea.id_room = room.id_room)
                               AND room.id_department = dt.id_department
                               AND dt.id_institution = i_prof.institution
                               AND sd.id_dept = dt.id_dept
                               AND sd.id_software = pk_alert_constant.g_soft_edis
                               AND i_flg_view = 'V2'
                               AND tc.flg_type = 'S'
                               AND tc.flg_available = 'Y'
                               AND tc.id_triage_type IN (SELECT *
                                                           FROM TABLE(l_tab_triage_types))) tbl_temp
                     ORDER BY decode(l_orderby, l_orderby_los, date_send_sort, 0) DESC NULLS LAST,
                              decode(l_orderby, l_orderby_room, tbl_temp.desc_room, tbl_temp.rank_acuity),
                              origin_rank,
                              rank_letter,
                              dt_begin ASC);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ALL_EDIS_EPIS_INTERNAL',
                                              o_error);
            pk_types.open_my_cursor(o_rows);
            RETURN FALSE;
    END get_all_edis_epis_internal;

    FUNCTION get_all_edis_epis
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_room      IN room.id_room%TYPE,
        i_flg_view  IN VARCHAR2,
        o_rows      OUT pk_types.cursor_type,
        o_dt_server OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        IF NOT get_all_edis_epis_internal(i_lang,
                                          i_prof,
                                          i_room,
                                          i_flg_view,
                                          pk_alert_constant.g_no,
                                          pk_sysconfig.get_config('SHOW_PHOTO_TRACKING_VIEW_IN', i_prof),
                                          pk_alert_constant.g_no, -- Internal tracking view, 
                                          NULL,
                                          o_rows,
                                          o_dt_server,
                                          o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ALL_EDIS_EPIS',
                                              o_error);
        
            pk_types.open_my_cursor(o_rows);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_all_edis_epis;

    FUNCTION get_all_edis_epis
    (
        i_lang          IN language.id_language%TYPE,
        i_institution   IN institution.id_institution%TYPE,
        i_room          IN room.id_room%TYPE,
        i_flg_view      IN VARCHAR2,
        i_id_department IN department.id_department%TYPE,
        o_rows          OUT pk_types.cursor_type,
        o_dt_server     OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_prof profissional := profissional(0, i_institution, pk_alert_constant.g_soft_edis);
    
    BEGIN
    
        IF NOT get_all_edis_epis_internal(i_lang,
                                          l_prof,
                                          i_room,
                                          i_flg_view,
                                          pk_alert_constant.g_no,
                                          pk_sysconfig.get_config('SHOW_PHOTO_TRACKING_VIEW_OUT', l_prof),
                                          pk_alert_constant.g_yes, -- External tracking view
                                          i_id_department,
                                          o_rows,
                                          o_dt_server,
                                          o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ALL_EDIS_EPIS',
                                              o_error);
            pk_types.open_my_cursor(o_rows);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_all_edis_epis;

    FUNCTION get_all_edis_epis_out
    (
        i_lang          IN language.id_language%TYPE,
        i_institution   IN institution.id_institution%TYPE,
        i_room          IN room.id_room%TYPE,
        i_flg_view      IN VARCHAR2,
        i_id_department IN department.id_department%TYPE,
        o_rows          OUT pk_types.cursor_type,
        o_dt_server     OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_prof profissional := profissional(0, i_institution, pk_alert_constant.g_soft_edis);
    
    BEGIN
    
        IF NOT get_all_edis_epis_internal(i_lang,
                                          l_prof,
                                          i_room,
                                          i_flg_view,
                                          pk_alert_constant.g_yes,
                                          pk_sysconfig.get_config('SHOW_PHOTO_TRACKING_VIEW_OUT', l_prof),
                                          pk_alert_constant.g_yes, -- External tracking view, 
                                          i_id_department,
                                          o_rows,
                                          o_dt_server,
                                          o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ALL_EDIS_EPIS_OUT',
                                              o_error);
            pk_types.open_my_cursor(o_rows);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_all_edis_epis_out;

    FUNCTION get_all_inp_epis
    (
        i_lang          IN language.id_language%TYPE,
        i_institution   IN institution.id_institution%TYPE,
        i_room          IN room.id_room%TYPE,
        i_flg_view      IN VARCHAR,
        i_id_department IN department.id_department%TYPE,
        o_rows          OUT pk_types.cursor_type,
        o_dt_server     OUT VARCHAR2,
        o_label         OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_prof profissional := profissional(0, i_institution, pk_alert_constant.g_soft_inpatient);
    
        l_empty_bed_msg  sys_message.desc_message%TYPE;
        l_config_refresh sys_config.id_sys_config%TYPE;
        l_desc_service   translation.desc_lang_1%TYPE;
    
        g_execption_no_cs EXCEPTION;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        IF i_id_department IS NOT NULL
        THEN
            SELECT pk_translation.get_translation(i_lang, d.code_department)
              INTO l_desc_service
              FROM department d
             WHERE d.id_department = i_id_department;
        
            o_label := pk_message.get_message(i_lang => i_lang, i_prof => l_prof, i_code_mess => 'TRACK_VIEW_T015') ||
                       ' / ' || l_desc_service;
        ELSE
            o_label := pk_message.get_message(i_lang => i_lang, i_prof => l_prof, i_code_mess => 'TRACK_VIEW_T006');
        END IF;
    
        l_config_refresh := pk_sysconfig.get_config('TRACKING_VIEW_REFRESH',
                                                    i_institution,
                                                    pk_alert_constant.g_soft_inpatient);
    
        l_empty_bed_msg := pk_message.get_message(i_lang, 'TRACK_VIEW_M001');
        g_msg_drug_sos  := pk_message.get_message(i_lang, 'DRUG_PRESC_M004');
    
        -- 'Prefetch' of some informating to avoid repeated calls inside the main query
        -- This code block is meant to increase the query performance and it's executed only once (in order with g_flg_exec_glob var)
        -- Result depends on the language id
        -- This is valid to a scenario where the sessions are kept (which is not the current scenario)
        --
        -- ATTENTION: new status must be used here
        --
        -- TODO: encapsulate inside a function
        IF NOT g_flg_exec_glob.exists(i_lang)
        THEN
            g_flg_exec_glob(i_lang) := FALSE;
        END IF;
    
        IF NOT g_flg_exec_glob(i_lang)
        THEN
            g_exam_flg_status_req_img(i_lang) := pk_sysdomain.get_img(i_lang,
                                                                      'EXAM_REQ_DET.FLG_STATUS',
                                                                      pk_alert_constant.g_exam_det_req);
            g_exam_flg_status_wtg_img(i_lang) := pk_sysdomain.get_img(i_lang,
                                                                      'EXAM_REQ_DET.FLG_STATUS',
                                                                      pk_exam_constant.g_exam_wtg_tde);
            g_exam_flg_status_mov_img(i_lang) := pk_sysdomain.get_img(i_lang,
                                                                      'MOVEMENT.FLG_STATUS',
                                                                      pk_alert_constant.g_mov_status_transp);
            g_exam_flg_status_exec_img(i_lang) := pk_sysdomain.get_img(i_lang,
                                                                       'EXAM_REQ_DET.FLG_STATUS',
                                                                       pk_alert_constant.g_exam_det_exec);
            g_exam_flg_status_result_img(i_lang) := pk_sysdomain.get_img(i_lang,
                                                                         'EXAM_REQ_DET.FLG_STATUS',
                                                                         pk_alert_constant.g_exam_det_result);
            g_exam_flg_status_read_img(i_lang) := pk_sysdomain.get_img(i_lang,
                                                                       'EXAM_REQ_DET.FLG_STATUS',
                                                                       pk_alert_constant.g_exam_det_read);
        
            g_lab_flg_status_wtg_img(i_lang) := pk_sysdomain.get_img(i_lang,
                                                                     'ANALYSIS_REQ_DET.FLG_STATUS',
                                                                     pk_lab_tests_constant.g_analysis_wtg_tde);
        
            g_lab_flg_status_pend_img(i_lang) := pk_sysdomain.get_img(i_lang,
                                                                      'ANALYSIS_REQ_DET.FLG_STATUS',
                                                                      pk_alert_constant.g_analysis_det_pend);
            g_lab_flg_status_harv_img(i_lang) := pk_sysdomain.get_img(i_lang,
                                                                      'HARVEST.FLG_STATUS',
                                                                      pk_alert_constant.g_harvest_harv);
            g_lab_flg_status_trans_img(i_lang) := pk_sysdomain.get_img(i_lang,
                                                                       'HARVEST.FLG_STATUS',
                                                                       pk_alert_constant.g_harvest_trans);
            g_lab_flg_status_exec_img(i_lang) := pk_sysdomain.get_img(i_lang,
                                                                      'ANALYSIS_REQ_DET.FLG_STATUS',
                                                                      pk_alert_constant.g_analysis_det_exec);
            g_lab_flg_status_result_img(i_lang) := pk_sysdomain.get_img(i_lang,
                                                                        'ANALYSIS_REQ_DET.FLG_STATUS',
                                                                        pk_alert_constant.g_analysis_det_result);
            g_lab_flg_status_read_img(i_lang) := pk_sysdomain.get_img(i_lang,
                                                                      'ANALYSIS_REQ_DET.FLG_STATUS',
                                                                      pk_alert_constant.g_analysis_det_read);
            g_lab_flg_status_wtg_img(i_lang) := pk_sysdomain.get_img(i_lang,
                                                                     'ANALYSIS_REQ_DET.FLG_STATUS',
                                                                     pk_lab_tests_constant.g_analysis_wtg_tde);
        
            g_monit_det_exec_img(i_lang) := pk_sysdomain.get_img(i_lang,
                                                                 'MONITORIZATION_VS.FLG_STATUS',
                                                                 pk_alert_constant.g_monitor_vs_exec);
            g_monit_det_fini_img(i_lang) := pk_sysdomain.get_img(i_lang,
                                                                 'MONITORIZATION_VS.FLG_STATUS',
                                                                 pk_alert_constant.g_monitor_vs_fini);
        
            g_interv_flg_status_exec_img(i_lang) := pk_sysdomain.get_img(i_lang,
                                                                         'INTERV_PRESC_DET.FLG_STATUS',
                                                                         pk_alert_constant.g_interv_det_exec);
            g_interv_flg_status_fin_img(i_lang) := pk_sysdomain.get_img(i_lang,
                                                                        'INTERV_PRESC_DET.FLG_STATUS',
                                                                        pk_alert_constant.g_interv_det_fin);
        
            g_interv_flg_status_ext_img(i_lang) := pk_sysdomain.get_img(i_lang,
                                                                        'INTERV_PRESC_DET.FLG_STATUS',
                                                                        pk_alert_constant.g_interv_det_ext);
        
            g_interv_msg_it056(i_lang) := pk_message.get_message(i_lang, 'ICON_T056');
        
            g_flg_exec_glob(i_lang) := TRUE;
        END IF;
    
        g_error := 'OPEN O_ROWS';
        OPEN o_rows FOR
        --all the beds with patient on it
            SELECT tbea.id_episode,
                   tbea.id_patient id_patient,
                   l_config_refresh refresh_interval,
                   nvl(bed.desc_bed, pk_translation.get_translation(i_lang, bed.code_bed)) desc_bed,
                   (SELECT nvl(room.desc_room, pk_translation.get_translation(i_lang, room.code_room))
                      FROM dual) desc_room,
                   (SELECT pk_edis_grid.get_complaint_grid(i_lang, l_prof, tbea.id_episode)
                      FROM dual) epis_anamnesis,
                   (SELECT nvl(nick_name, name)
                      FROM professional
                     WHERE id_professional = tbea.id_prof_resp) name_prof,
                   (SELECT nvl(nick_name, name)
                      FROM professional
                     WHERE id_professional = tbea.id_nurse_resp) name_nurse,
                   (SELECT pk_diet.get_active_diet_description(i_lang, l_prof, tbea.id_episode)
                      FROM dual) desc_diet,
                   (SELECT pk_diet.get_active_diet_tooltip(i_lang, l_prof, tbea.id_episode)
                      FROM dual) desc_diet_tooltip,
                   -- exams processing
                   pk_tracking_view.get_epis_exam_desc(i_lang, l_prof, tbea.rowid) desc_exam,
                   -- other exams processing
                   pk_tracking_view.get_epis_oth_exam_desc(i_lang, l_prof, tbea.rowid) desc_oth_exam,
                   -- analysis processing
                   pk_tracking_view.get_epis_lab_desc(i_lang, l_prof, tbea.rowid) desc_analysis,
                   pk_opinion.get_consultations_tooltip(i_lang, l_prof, tbea.id_episode) desc_destination_tooltip,
                   -- monitorizations processing
                   decode(aw.flg_monitorization,
                          pk_alert_constant.g_yes,
                          pk_tracking_view.get_epis_monit_desc(i_lang, l_prof, tbea.id_episode),
                          '') desc_monit,
                   -- drug prescriptions processing
                   decode(aw.flg_presc_med,
                          pk_alert_constant.g_yes,
                          pk_tracking_view.get_epis_drug_desc(i_lang, l_prof, tbea.id_episode, pk_alert_constant.g_no),
                          '') desc_drug,
                   -- interventions processing
                   decode(aw.flg_interv_prescription,
                          pk_alert_constant.g_yes,
                          pk_tracking_view.get_epis_interv_desc(i_lang, l_prof, tbea.id_episode),
                          decode(aw.flg_nurse_activity_req,
                                 pk_alert_constant.g_yes,
                                 pk_tracking_view.get_epis_interv_desc(i_lang, l_prof, tbea.id_episode),
                                 '')) desc_interv,
                   -- transportations processing
                   substr(decode(tbea.transp_delay,
                                 NULL,
                                 NULL,
                                 ';' || get_status_string(i_lang         => i_lang,
                                                          i_prof         => l_prof,
                                                          i_display_type => pk_alert_constant.g_display_type_date,
                                                          i_value_date   => pk_date_utils.date_send_tsz(i_lang,
                                                                                                        to_timestamp_tz(tbea.transp_delay,
                                                                                                                        pk_alert_constant.g_dt_yyyymmddhh24miss_tzr),
                                                                                                        l_prof),
                                                          i_value_icon   => NULL,
                                                          i_color        => pk_alert_constant.g_color_red)) ||
                          decode(tbea.transp_ongoing,
                                 NULL,
                                 NULL,
                                 ';' || get_status_string(i_lang         => i_lang,
                                                          i_prof         => l_prof,
                                                          i_display_type => pk_alert_constant.g_display_type_icon,
                                                          i_value_date   => pk_date_utils.date_send_tsz(i_lang,
                                                                                                        to_timestamp_tz(tbea.transp_ongoing,
                                                                                                                        pk_alert_constant.g_dt_yyyymmddhh24miss_tzr),
                                                                                                        l_prof),
                                                          i_value_icon   => g_exam_flg_status_mov_img(i_lang),
                                                          i_color        => pk_alert_constant.g_color_none)),
                          2) desc_mov,
                   -- Opinion       
                   substr((SELECT concatenate(';' || CASE
                                                  WHEN o.flg_state IN (pk_opinion.g_opinion_req, pk_opinion.g_opinion_req_read) THEN
                                                   get_status_string(i_lang         => i_lang,
                                                                     i_prof         => l_prof,
                                                                     i_display_type => pk_alert_constant.g_display_type_date,
                                                                     i_value_date   => pk_date_utils.date_send_tsz(i_lang,
                                                                                                                   o.dt_problem_tstz,
                                                                                                                   l_prof),
                                                                     i_value_icon   => NULL,
                                                                     i_color        => pk_alert_constant.g_color_red)
                                                  ELSE
                                                   get_status_string(i_lang         => i_lang,
                                                                     i_prof         => l_prof,
                                                                     i_display_type => pk_alert_constant.g_display_type_icon,
                                                                     i_value_date   => NULL,
                                                                     i_value_icon   => pk_sysdomain.get_img(i_lang,
                                                                                                            pk_opinion.g_opinion_consults,
                                                                                                            pk_opinion.g_opinion_reply),
                                                                     i_color        => pk_alert_constant.g_color_none)
                                              END) state
                            FROM opinion o
                           WHERE o.id_episode = tbea.id_episode
                             AND o.flg_state != pk_opinion.g_opinion_cancel
                             AND o.id_opinion_type IS NULL),
                          2) desc_opinion,
                   pk_opinion.get_epis_last_opinion_popup(i_lang, l_prof, epi.id_episode) desc_opinion_popup,
                   d.id_department,
                   nvl((d.rank * 100000), 0) + nvl((room.rank * 1000), 0) + nvl(bed.rank, 99) rank,
                   pk_alert_constant.g_no flg_vacant,
                   (SELECT pk_patient.get_pat_age(i_lang, pat.dt_birth, pat.age, l_prof.institution, l_prof.software)
                      FROM dual) pat_age,
                   (SELECT pk_patient.get_gender(i_lang, pat.gender)
                      FROM dual) pat_gender,
                   (SELECT pk_adt.get_pat_non_disclosure_icon(i_lang, l_prof, epi.id_patient)
                      FROM dual) pat_nd_icon,
                   (SELECT pk_adt.get_pat_non_disc_options(i_lang, l_prof, epi.id_patient)
                      FROM dual) pat_ndo,
                   (SELECT pk_patphoto.get_pat_foto_url(i_lang,
                                                        epi.id_patient,
                                                        l_prof,
                                                        epi.id_episode,
                                                        ei.id_schedule,
                                                        'Y')
                      FROM dual) pat_photo,
                   epi.id_clinical_service,
                   pk_adt.get_identification_doc(i_lang => i_lang, i_prof => l_prof, i_id_patient => epi.id_patient) patient_id,
                   (CASE
                        WHEN (epi.flg_ehr = pk_alert_constant.g_flg_ehr_n) THEN
                         (SELECT pk_date_utils.dt_chr_hour_tsz(i_lang, epi.dt_begin_tstz, l_prof)
                            FROM dual)
                        ELSE
                         '---'
                    END) dt_admission_hour,
                   (CASE
                        WHEN (epi.flg_ehr = pk_alert_constant.g_flg_ehr_n) THEN
                         (SELECT pk_date_utils.dt_chr_tsz(i_lang, epi.dt_begin_tstz, l_prof)
                            FROM dual)
                        ELSE
                         '---'
                    END) dt_admission_date,
                   (CASE
                        WHEN (epi.flg_ehr = pk_alert_constant.g_flg_ehr_n) THEN
                         (SELECT pk_date_utils.date_send_tsz(i_lang, epi.dt_begin_tstz, l_prof)
                            FROM dual)
                        ELSE
                         '---'
                    END) dt_admission_send,
                   (SELECT pk_patient.get_pat_name(i_lang, l_prof, epi.id_patient, epi.id_episode)
                      FROM dual) pat_name,
                   (SELECT pk_adt.get_nationality(i_lang, l_prof, epi.id_patient)
                      FROM dual) nationality,
                   pk_patient.get_julian_age(i_lang, pat.dt_birth, pat.age) pat_age_for_order_by
              FROM episode epi
              JOIN epis_info ei
                ON epi.id_episode = ei.id_episode
              JOIN tracking_board_ea tbea
                ON tbea.id_episode = epi.id_episode
               AND tbea.id_epis_type = pk_alert_constant.g_epis_type_inpatient
              JOIN bed
                ON tbea.id_bed = bed.id_bed
               AND bed.flg_available = pk_alert_constant.g_yes
               AND (i_room IS NULL OR bed.id_room = i_room)
              JOIN room
                ON room.id_room = bed.id_room
               AND room.flg_available = pk_alert_constant.g_yes
              JOIN department d
                ON d.id_department = room.id_department
               AND d.id_institution = epi.id_institution
              JOIN awareness aw
                ON aw.id_patient = tbea.id_patient
               AND aw.id_episode = tbea.id_episode
              JOIN patient pat
                ON pat.id_patient = epi.id_patient
             WHERE epi.id_institution = l_prof.institution
               AND (i_id_department IS NULL OR d.id_department = i_id_department)
            UNION ALL
            --empty beds
            SELECT NULL id_episode,
                   NULL id_patient,
                   l_config_refresh refresh_interval,
                   nvl(bed.desc_bed, pk_translation.get_translation(i_lang, bed.code_bed)) desc_bed,
                   (SELECT nvl(room.desc_room, pk_translation.get_translation(i_lang, room.code_room))
                      FROM dual) desc_room,
                   l_empty_bed_msg epis_anamnesis,
                   NULL name_prof,
                   NULL name_nurse,
                   NULL desc_diet,
                   NULL desc_diet_tooltip,
                   NULL desc_exam,
                   NULL desc_oth_exam,
                   NULL desc_analysis,
                   NULL desc_destination_tooltip,
                   NULL desc_monit,
                   NULL desc_drug,
                   NULL desc_interv,
                   NULL desc_mov,
                   -- Opinion       
                   NULL desc_opinion,
                   NULL desc_opinion_popup,
                   dt.id_department,
                   nvl((dt.rank * 100000), 0) + nvl((room.rank * 1000), 0) rank,
                   pk_alert_constant.g_yes flg_vacant,
                   NULL pat_age,
                   NULL pat_gender,
                   NULL pat_nd_icon,
                   NULL pat_ndo,
                   NULL pat_photo,
                   NULL id_clinical_service,
                   NULL patient_id,
                   NULL dt_admission_hour,
                   NULL dt_admission_date,
                   NULL dt_admission_send,
                   NULL pat_name,
                   NULL nationality,
                   NULL pat_age_for_order_by
              FROM dept d
              JOIN department dt
                ON d.id_dept = dt.id_dept
              JOIN room
                ON dt.id_department = room.id_department
               AND room.flg_available = pk_alert_constant.g_yes
              JOIN bed
                ON room.id_room = bed.id_room
               AND bed.flg_available = pk_alert_constant.g_yes
              JOIN software_dept sd
                ON sd.id_dept = d.id_dept
               AND sd.id_software = pk_alert_constant.g_soft_inpatient
             WHERE d.id_institution = i_institution
               AND i_flg_view = 'V2'
               AND i_room IS NULL
               AND (i_id_department IS NULL OR dt.id_department = i_id_department)
               AND NOT EXISTS (SELECT 0
                      FROM tracking_board_ea tbea
                     WHERE tbea.id_bed = bed.id_bed)
             ORDER BY flg_vacant, rank, id_department, desc_room, desc_bed;
    
        g_error     := 'DO DT SERVER';
        o_dt_server := pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, l_prof);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_execption_no_cs THEN
            pk_alert_exceptions.process_warning(i_lang        => i_lang,
                                                i_sqlcode     => NULL,
                                                i_sqlerrm     => NULL,
                                                i_message     => '',
                                                i_owner       => g_package_owner,
                                                i_package     => g_package_name,
                                                i_function    => 'GET_ALL_INP_EPIS',
                                                i_action_type => 'U',
                                                i_action_msg  => 'Please verify the configurations in the local config.xml file.',
                                                i_msg_title   => 'System Error',
                                                o_error       => o_error);
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ALL_INP_EPIS',
                                              o_error);
            pk_types.open_my_cursor(o_rows);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_all_inp_epis;

    FUNCTION get_all_rooms
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE,
        i_department  IN department.id_department%TYPE DEFAULT NULL,
        o_list        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET CURSOR FOR ALL ROOM PATS';
        OPEN o_list FOR
            SELECT r.id_room id_room,
                   coalesce(r.desc_room,
                            r.desc_room_abbreviation,
                            pk_translation.get_translation(i_lang, nvl(r.code_room, r.code_abbreviation))) desc_room,
                   decode(r.capacity, NULL, 0, r.capacity) room_capacity,
                   (SELECT COUNT(0)
                      FROM tracking_board_ea tbea, episode epis
                     WHERE tbea.id_room = r.id_room
                       AND tbea.id_epis_type = decode(i_software,
                                                      pk_alert_constant.g_soft_inpatient,
                                                      pk_alert_constant.g_epis_type_inpatient,
                                                      pk_alert_constant.g_soft_edis,
                                                      pk_alert_constant.g_epis_type_emergency,
                                                      pk_alert_constant.g_soft_triage,
                                                      pk_alert_constant.g_epis_type_emergency)
                       AND epis.id_episode = tbea.id_episode
                       AND epis.id_institution = i_institution) total
              FROM room r
             INNER JOIN department d
                ON d.id_department = r.id_department
             INNER JOIN dept dt
                ON dt.id_dept = d.id_dept
             WHERE r.id_department = nvl(i_department, r.id_department)
               AND r.flg_available = pk_alert_constant.g_available
               AND EXISTS (SELECT 0
                      FROM software_dept sd
                     WHERE dt.id_dept = sd.id_dept
                       AND sd.id_software = i_software)
               AND d.id_institution = i_institution
               AND d.flg_available = pk_alert_constant.g_available
               AND dt.flg_available = pk_alert_constant.g_available
             ORDER BY total DESC;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ALL_ROOMS',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_all_rooms;

    FUNCTION get_all_edis_rooms_pats
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_department  IN department.id_department%TYPE,
        o_rows        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_ALL_ROOMS';
        IF NOT get_all_rooms(i_lang, i_institution, pk_alert_constant.g_soft_edis, i_department, o_rows, o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ALL_EDIS_ROOMS_PATS',
                                              o_error);
            pk_types.open_my_cursor(o_rows);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_all_edis_rooms_pats;

    FUNCTION get_all_edis_rooms_pats
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        o_rows        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_ALL_ROOMS';
        IF NOT get_all_rooms(i_lang, i_institution, pk_alert_constant.g_soft_edis, NULL, o_rows, o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ALL_EDIS_ROOMS_PATS',
                                              o_error);
            pk_types.open_my_cursor(o_rows);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_all_edis_rooms_pats;

    FUNCTION get_all_inp_rooms_pats
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_department  IN department.id_department%TYPE,
        o_rows        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_ALL_ROOMS';
        IF NOT get_all_rooms(i_lang, i_institution, pk_alert_constant.g_soft_inpatient, i_department, o_rows, o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ALL_INP_ROOMS_PATS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_rows);
            RETURN FALSE;
    END get_all_inp_rooms_pats;

    FUNCTION get_chart_header
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE,
        i_room        IN room.id_room%TYPE,
        o_head_col    OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_tab_inst_triag_types table_number;
        l_tab_triage_color     table_number;
        l_tab_color_groups     table_number;
        l_minutes_desc         VARCHAR2(200);
        l_software             software.id_software%TYPE;
    
    BEGIN
    
        g_error        := 'GET INITIAL DATA';
        l_minutes_desc := pk_translation.get_translation(i_lang, 'TRIAGE_UNITS.CODE_TRIAGE_UNITS.1'); -- "Min"
    
        l_software := pk_episode.get_soft_by_epis_type(pk_sysconfig.get_config('EPIS_TYPE', i_institution, i_software),
                                                       i_institution);
    
        g_error                := 'GET INST TRIAGE_TYPES';
        l_tab_inst_triag_types := pk_edis_triage.tf_get_inst_triag_types(i_institution);
    
        -- José Brito 16/09/2009 ALERT-42214 
        -- Get all triage colors used in the institution
        g_error := 'GET TRIAGE COLORS';
        SELECT tco1.id_triage_color
          BULK COLLECT
          INTO l_tab_triage_color
          FROM triage_color tco1,
               (SELECT tab.column_value id_triage_type
                  FROM TABLE(l_tab_inst_triag_types) tab) t
         WHERE tco1.flg_show = pk_alert_constant.g_yes
           AND tco1.id_triage_type = t.id_triage_type;
    
        -- Get color groups
        g_error := 'GET TRIAGE COLOR GROUPS';
        SELECT tco1.id_triage_color_group
          BULK COLLECT
          INTO l_tab_color_groups
          FROM triage_color tco1,
               (SELECT tab.column_value id_triage_color
                  FROM TABLE(l_tab_triage_color) tab) t
         WHERE tco1.id_triage_color = t.id_triage_color;
    
        -- Clear repeated elements
        l_tab_color_groups := l_tab_color_groups MULTISET UNION DISTINCT l_tab_color_groups;
    
        g_error := 'GET CURSOR O_HEAD_COL';
        IF i_software IN (pk_alert_constant.g_soft_edis, pk_alert_constant.g_soft_triage)
        THEN
            -- José Brito 16/09/2009 ALERT-42214
            -- Query completely rewritten to support color groups
            OPEN o_head_col FOR
                SELECT --tco.id_triage_color id_color,
                 tcg.id_triage_color_group,
                 tcg.color,
                 tcg.color_text,
                 tcg.flg_ref_line,
                 tcg.len_color_tracking length_color,
                 -- Get the maximum SCALE TIME of all triage types used in the institution
                 (SELECT MAX(tci.scale_time)
                    FROM triage_color_time_inst tci, triage_color tco
                   WHERE tci.id_triage_color = tco.id_triage_color
                     AND tco.id_triage_color_group = tcg.id_triage_color_group
                     AND tco.id_triage_type IN (SELECT column_value
                                                  FROM TABLE(l_tab_inst_triag_types))
                     AND (tci.id_institution = 0 AND NOT EXISTS
                          (SELECT 0
                             FROM triage_color_time_inst t1
                            WHERE t1.id_triage_color = tco.id_triage_color
                              AND t1.id_institution = i_institution) OR tci.id_institution = i_institution)) scale_time,
                 -- Get the maximum SCALE TIME INTERVAL of all triage types used in the institution
                 (SELECT MAX(tci.scale_time_interv)
                    FROM triage_color_time_inst tci, triage_color tco
                   WHERE tci.id_triage_color = tco.id_triage_color
                     AND tco.id_triage_color_group = tcg.id_triage_color_group
                     AND tco.id_triage_type IN (SELECT column_value
                                                  FROM TABLE(l_tab_inst_triag_types))
                     AND (tci.id_institution = 0 AND NOT EXISTS
                          (SELECT 0
                             FROM triage_color_time_inst t1
                            WHERE t1.id_triage_color = tco.id_triage_color
                              AND t1.id_institution = i_institution) OR tci.id_institution = i_institution)) scale_time_interv,
                 l_minutes_desc units,
                 -- Count number of episodes for each color group
                 (SELECT COUNT(0)
                    FROM (SELECT id_triage_color, id_episode
                            FROM epis_info
                           WHERE id_room = i_room
                             AND id_software = l_software
                          UNION
                          SELECT id_triage_color, id_episode
                            FROM epis_info
                           WHERE i_room IS NULL
                             AND id_software = l_software) ei,
                         episode epis
                   WHERE (ei.id_triage_color IN
                         (SELECT tco1.id_triage_color
                             FROM triage_color tco1
                            WHERE tco1.id_triage_color_group = tcg.id_triage_color_group
                              AND tco1.id_triage_color IN (SELECT *
                                                             FROM TABLE(l_tab_triage_color))))
                     AND epis.id_epis_type = pk_alert_constant.g_epis_type_emergency
                     AND epis.id_episode = ei.id_episode
                     AND epis.id_institution = i_institution
                     AND epis.flg_status = pk_alert_constant.g_active
                     AND epis.flg_ehr = pk_alert_constant.g_flg_ehr_n) epis_count
                  FROM triage_color_group tcg,
                       -- Groups of colours used in the institution
                       (SELECT tab.column_value id_triage_color_group
                          FROM TABLE(l_tab_color_groups) tab) t
                 WHERE tcg.id_triage_color_group = t.id_triage_color_group
                 ORDER BY tcg.rank;
        
        ELSIF i_software = pk_alert_constant.g_soft_inpatient
        THEN
            -- José Brito 16/09/2009 ALERT-42214
            -- Query completely rewritten to support color groups
            OPEN o_head_col FOR
                SELECT --tco.id_triage_color id_color,
                 tcg.id_triage_color_group,
                 tcg.color,
                 tcg.color_text,
                 tcg.len_color_tracking length_color,
                 tcg.flg_ref_line,
                 -- Get the maximum SCALE TIME of all triage types used in the institution
                 (SELECT MAX(tci.scale_time)
                    FROM triage_color_time_inst tci, triage_color tco
                   WHERE tci.id_triage_color = tco.id_triage_color
                     AND tco.id_triage_color_group = tcg.id_triage_color_group
                     AND tco.id_triage_type IN (SELECT column_value
                                                  FROM TABLE(l_tab_inst_triag_types))
                     AND (tci.id_institution = 0 AND NOT EXISTS
                          (SELECT 0
                             FROM triage_color_time_inst t1
                            WHERE t1.id_triage_color = tco.id_triage_color
                              AND t1.id_institution = i_institution) OR tci.id_institution = i_institution)) scale_time,
                 -- Get the maximum SCALE TIME INTERVAL of all triage types used in the institution
                 (SELECT MAX(tci.scale_time_interv)
                    FROM triage_color_time_inst tci, triage_color tco
                   WHERE tci.id_triage_color = tco.id_triage_color
                     AND tco.id_triage_color_group = tcg.id_triage_color_group
                     AND tco.id_triage_type IN (SELECT column_value
                                                  FROM TABLE(l_tab_inst_triag_types))
                     AND (tci.id_institution = 0 AND NOT EXISTS
                          (SELECT 0
                             FROM triage_color_time_inst t1
                            WHERE t1.id_triage_color = tco.id_triage_color
                              AND t1.id_institution = i_institution) OR tci.id_institution = i_institution)) scale_time_interv,
                 l_minutes_desc units,
                 decode(tcg.flg_type,
                        'S', --without color
                        (SELECT COUNT(0)
                           FROM (SELECT id_triage_color, id_episode
                                   FROM epis_info
                                  WHERE id_room = i_room
                                    AND id_software = l_software
                                 UNION
                                 SELECT id_triage_color, id_episode
                                   FROM epis_info
                                  WHERE i_room IS NULL
                                    AND id_software = l_software) ei,
                                episode epis
                          WHERE (ei.id_triage_color IN (SELECT tco1.id_triage_color
                                   FROM triage_color tco1
                                  WHERE tco1.id_triage_color_group = tcg.id_triage_color_group
                                                           AND tco1.id_triage_color IN
                                                               (SELECT *
                                                                  FROM TABLE(l_tab_triage_color))))
                            AND epis.id_epis_type = pk_alert_constant.g_epis_type_inpatient
                            AND epis.id_episode = ei.id_episode
                            AND epis.id_institution = i_institution
                            AND epis.flg_status = pk_alert_constant.g_active
                            AND epis.flg_ehr = pk_alert_constant.g_flg_ehr_n),
                        0) epis_count
                  FROM triage_color_group tcg,
                       -- Groups of colours used in the institution
                       (SELECT tab.column_value id_triage_color_group
                          FROM TABLE(l_tab_color_groups) tab) t
                 WHERE tcg.id_triage_color_group = t.id_triage_color_group
                 ORDER BY tcg.rank;
        
        ELSE
            g_error := 'INVALID ID SOFTWARE';
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CHART_HEADER',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_head_col);
            RETURN FALSE;
    END get_chart_header;

    FUNCTION get_chart_all_pat
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE,
        i_room        IN room.id_room%TYPE,
        i_prof        IN profissional,
        o_grid        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_software         software.id_software%TYPE;
        l_prof             profissional := profissional(0, i_institution, i_software);
        l_tab_triage_types table_number;
    
        l_value_los sys_config.value%TYPE;
    
        l_hand_off_type sys_config.value%TYPE;
        l_prof_cat      category.flg_type%TYPE;
        l_config_origin CONSTANT sys_config.id_sys_config%TYPE := 'GRID_ORIGINS';
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        g_error            := 'GET CONFIGURATIONS';
        l_software         := pk_episode.get_soft_by_epis_type(pk_sysconfig.get_config('EPIS_TYPE',
                                                                                       i_institution,
                                                                                       i_software),
                                                               i_institution);
        l_tab_triage_types := pk_edis_triage.tf_get_inst_triag_types(i_institution);
    
        g_error     := 'GET ' || pk_edis_grid.g_syscfg_los;
        l_value_los := pk_sysconfig.get_config(i_code_cf => pk_edis_grid.g_syscfg_los, i_prof => l_prof);
    
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
    
        l_prof_cat                      := pk_edis_list.get_prof_cat(i_prof);
        g_grid_origins                  := pk_sysconfig.get_config(l_config_origin, i_prof);
        pk_edis_grid.g_tab_grid_origins := pk_utils.str_split_l(g_grid_origins, '|');
    
        -- José Brito 18/09/2009 ALERT-42214 Rebuilt query to support color groups
        g_error := 'GET CURSOR O_GRID 1';
        OPEN o_grid FOR
            SELECT ei.triage_acuity acuity,
                   ei.triage_color_text color_text,
                   ei.triage_rank_acuity rank_acuity,
                   epis.id_episode,
                   pk_date_utils.date_send_tsz(i_lang, epis.dt_begin_tstz, l_prof) dt_begin,
                   pk_date_utils.get_conversion_date_tsz(i_lang, epis.dt_begin_tstz, l_prof, tt.id_triage_units) date_send,
                   epis.id_patient,
                   pk_episode.get_epis_dt_first_obs(i_lang,
                                                    l_prof,
                                                    tbea.id_episode,
                                                    ei.dt_first_obs_tstz,
                                                    tbea.flg_has_stripes) dt_first_obs,
                   decode(pk_prof_follow.get_follow_episode_by_me(i_prof, epis.id_episode, NULL),
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
                   pk_prof_follow.get_follow_episode_by_me(i_prof, epis.id_episode, NULL) prof_follow_remove,
                   (SELECT pk_adt_core.check_bulk_admission_episode(i_lang       => i_lang,
                                                                    i_prof       => i_prof,
                                                                    i_id_episode => epis.id_episode)
                      FROM dual) pat_major_inc_icon,
                   decode(pk_sysconfig.get_config('EDIS_GRID_ORIGIN_ORDER_WITHOUT_TRIAGE', i_prof),
                          pk_alert_constant.g_yes,
                          decode(pk_edis_triage.get_flag_no_color(i_lang, i_prof, tbea.id_triage_color),
                                 'S',
                                 0,
                                 decode(pk_utils.search_table_varchar(pk_edis_grid.g_tab_grid_origins,
                                                                      (SELECT id_origin
                                                                         FROM visit
                                                                        WHERE id_visit = epis.id_visit)),
                                        -1,
                                        1,
                                        0)),
                          decode(pk_utils.search_table_varchar(pk_edis_grid.g_tab_grid_origins,
                                                               (SELECT id_origin
                                                                  FROM visit
                                                                 WHERE id_visit = epis.id_visit)),
                                 -1,
                                 1,
                                 0)) origin_rank,
                   decode(orderby_flg_letter(i_prof),
                          pk_alert_constant.g_yes,
                          decode(ei.triage_flg_letter, pk_alert_constant.g_yes, 0, 1)) rank_letter
              FROM episode epis
              JOIN tracking_board_ea tbea
                ON tbea.id_episode = epis.id_episode
              JOIN epis_info ei
                ON ei.id_episode = epis.id_episode
              JOIN triage_color tco
                ON tco.id_triage_color = ei.id_triage_color
              JOIN triage_type tt
                ON tt.id_triage_type = tco.id_triage_type
             WHERE (ei.id_room = i_room OR i_room IS NULL)
               AND ei.id_software = l_software
               AND epis.id_institution = i_institution
                  -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer do tipo EHR 
               AND epis.flg_ehr = pk_alert_constant.g_flg_ehr_n
               AND epis.flg_status = pk_alert_constant.g_active
               AND tco.flg_show = 'Y'
               AND tco.id_triage_type IN (SELECT column_value id_triage_type
                                            FROM TABLE(l_tab_triage_types))
             ORDER BY decode(l_value_los, pk_alert_constant.g_yes, pk_edis_grid.get_los(i_lang, epis.dt_begin_tstz), 0) DESC,
                      decode(l_value_los, pk_alert_constant.g_no, rank_acuity, 0),
                      origin_rank,
                      rank_letter,
                      epis.dt_begin_tstz;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CHART_ALL_PAT',
                                              o_error);
            pk_types.open_my_cursor(o_grid);
            RETURN FALSE;
    END get_chart_all_pat;

    FUNCTION get_chart_all_pat_edis
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE,
        i_room        IN room.id_room%TYPE,
        i_prof        IN profissional,
        o_grid        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        pk_alertlog.log_debug(text => 'get_chart_all_pat_edis prosissional(' || i_prof.id || ',' || i_prof.institution || ',' ||
                                      i_prof.software || ')');
        g_error := 'CALL GET_CHART_ALL_PAT';
        IF NOT get_chart_all_pat(i_lang        => i_lang,
                                 i_institution => i_institution,
                                 i_software    => pk_alert_constant.g_soft_edis,
                                 i_room        => i_room,
                                 i_prof        => i_prof,
                                 o_grid        => o_grid,
                                 o_error       => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CHART_ALL_PAT_EDIS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_grid);
            RETURN FALSE;
    END get_chart_all_pat_edis;

    FUNCTION get_chart_all_pat_edis
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE,
        i_room        IN room.id_room%TYPE,
        o_grid        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_prof profissional := profissional(0, i_institution, i_software);
    
    BEGIN
        g_error := 'CALL GET_CHART_ALL_PAT';
    
        IF NOT get_chart_all_pat(i_lang        => i_lang,
                                 i_institution => i_institution,
                                 i_software    => i_software,
                                 i_room        => i_room,
                                 i_prof        => l_prof,
                                 o_grid        => o_grid,
                                 o_error       => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CHART_ALL_PAT_EDIS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_grid);
            RETURN FALSE;
    END get_chart_all_pat_edis;

    FUNCTION get_chart_all_pat_inp
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE,
        i_room        IN room.id_room%TYPE,
        i_prof        IN profissional,
        o_grid        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_CHART_ALL_PAT';
        IF NOT get_chart_all_pat(i_lang        => i_lang,
                                 i_institution => i_institution,
                                 i_software    => pk_alert_constant.g_soft_inpatient,
                                 i_room        => i_room,
                                 i_prof        => i_prof,
                                 o_grid        => o_grid,
                                 o_error       => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CHART_ALL_PAT_INP',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_grid);
            RETURN FALSE;
    END get_chart_all_pat_inp;

    FUNCTION get_chart_all_pat_inp
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE,
        i_room        IN room.id_room%TYPE,
        o_grid        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_prof profissional := profissional(0, i_institution, i_software);
    
    BEGIN
        g_error := 'CALL GET_CHART_ALL_PAT';
        IF NOT get_chart_all_pat(i_lang        => i_lang,
                                 i_institution => i_institution,
                                 i_software    => pk_alert_constant.g_soft_inpatient,
                                 i_room        => i_room,
                                 i_prof        => l_prof,
                                 o_grid        => o_grid,
                                 o_error       => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CHART_ALL_PAT_INP',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_grid);
            RETURN FALSE;
    END get_chart_all_pat_inp;

    FUNCTION get_sr_grid_tracking_view
    (
        i_lang         IN language.id_language%TYPE,
        i_institution  IN institution.id_institution%TYPE,
        i_room         IN VARCHAR2,
        i_pat_states   IN VARCHAR2,
        i_page         IN NUMBER,
        i_id_room      IN room.id_room%TYPE,
        i_waiting_room IN VARCHAR2,
        o_grid         OUT pk_types.cursor_type,
        o_room_list    OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_sr_grid.get_sr_grid_tracking_view(i_lang         => i_lang,
                                                    i_institution  => i_institution,
                                                    i_room         => i_room,
                                                    i_pat_states   => i_pat_states,
                                                    i_page         => i_page,
                                                    i_id_room      => i_id_room,
                                                    i_waiting_room => i_waiting_room,
                                                    o_grid         => o_grid,
                                                    o_room_list    => o_room_list,
                                                    o_error        => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
            pk_types.open_my_cursor(o_grid);
            RETURN FALSE;
    END get_sr_grid_tracking_view;

    FUNCTION get_room_desc
    (
        i_lang      IN language.id_language%TYPE,
        i_room      IN room.id_room%TYPE,
        o_room_desc OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET ROOM DESC';
        SELECT nvl(r.desc_room, pk_translation.get_translation(i_lang, 'ROOM.CODE_ROOM.' || i_room))
          INTO o_room_desc
          FROM room r
         WHERE r.id_room = i_room;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ROOM_DESC',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_room_desc;

    FUNCTION get_epis_destination_int
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_disch_reas_dest IN epis_info.id_disch_reas_dest%TYPE,
        i_flg_status      IN epis_info.flg_dsch_status%TYPE,
        o_dest_partial    OUT table_varchar,
        o_dest_full       OUT table_varchar,
        o_disch           OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_disch VARCHAR2(1000 CHAR);
    
        l_destin VARCHAR2(4000 CHAR);
    
        l_destin_list         table_varchar := table_varchar();
        l_destin_partial_list table_varchar := table_varchar();
    
        l_profs             VARCHAR2(1000 CHAR);
        l_room              VARCHAR2(1000 CHAR);
        l_tab_profs         table_varchar;
        l_tab_profs_pending table_varchar := table_varchar();
        l_tab_status        table_varchar;
        l_speciality        table_varchar;
    
        l_sep VARCHAR2(2 CHAR);
    
        l_pend_cons VARCHAR2(1 CHAR);
    
        CURSOR c_opinion IS
            SELECT DISTINCT pk_translation.get_translation(i_lang, 'SPECIALITY.CODE_SPECIALITY.' || id_speciality) desc_spec,
                            id_speciality
              FROM (SELECT op.id_speciality
                      FROM opinion op
                     WHERE op.id_episode = i_episode
                       AND op.flg_state IN (pk_opinion.g_opinion_req_read, pk_opinion.g_opinion_req)
                       AND op.id_speciality IS NOT NULL) a
             ORDER BY desc_spec;
    
        CURSOR c_room IS
            SELECT pk_disposition.get_room_admit(i_lang, i_prof, ddh.id_room_admit, ddh.admit_to_room) desc_room
              FROM discharge_hist dh
              JOIN discharge_detail_hist ddh
                ON dh.id_discharge_hist = ddh.id_discharge_hist
             WHERE dh.id_episode = i_episode
             ORDER BY dh.dt_created_hist DESC;
    
    BEGIN
    
        IF i_disch_reas_dest IS NOT NULL
           AND i_flg_status = pk_discharge.g_disch_flg_status_pend
        THEN
            SELECT pk_translation.get_translation_dtchk(i_lang, 'DEPARTMENT.CODE_DEPARTMENT.' || drd.id_department)
              INTO l_disch
              FROM disch_reas_dest drd
             WHERE drd.id_disch_reas_dest = i_disch_reas_dest;
        
            IF l_disch IS NOT NULL
            THEN
                OPEN c_room;
                FETCH c_room
                    INTO l_room;
                CLOSE c_room;
            
                IF l_room IS NOT NULL
                THEN
                    l_disch := l_disch || chr(10) || l_room;
                END IF;
            END IF;
        END IF;
    
        o_disch := l_disch;
    
        FOR r_opinion IN c_opinion
        LOOP
            l_destin := r_opinion.desc_spec;
        
            SELECT pk_prof_utils.get_nickname(i_lang, op.id_prof_questioned) ||
                   decode(pk_prof_utils.get_nickname(i_lang, op.id_prof_questioned),
                          NULL,
                          pk_message.get_message(i_lang, 'OPINION_T019') || ' ',
                          ' - ') || pk_sysdomain.get_domain('OPINION.FLG_STATE', op.flg_state, i_lang) desc_p,
                   
                   op.flg_state
              BULK COLLECT
              INTO l_tab_profs, l_tab_status
              FROM opinion op
             WHERE op.id_speciality = r_opinion.id_speciality
               AND op.id_episode = i_episode
               AND op.flg_state IN
                   (pk_opinion.g_opinion_req, pk_opinion.g_opinion_reply, pk_opinion.g_opinion_req_read)
             ORDER BY desc_p;
        
            --Check if we have pending consultations and filter that information
            l_pend_cons         := pk_alert_constant.g_no;
            l_tab_profs_pending := table_varchar();
            FOR i IN 1 .. l_tab_status.count
            LOOP
                l_pend_cons := pk_alert_constant.g_yes;
            
                l_tab_profs_pending.extend(1);
                l_tab_profs_pending(l_tab_profs_pending.count) := l_tab_profs(i);
            
            END LOOP;
        
            l_sep := '; ';
        
            --process all the consults
            IF l_tab_profs IS NOT NULL
               AND l_tab_profs.count > 0
            THEN
                l_tab_profs := l_tab_profs MULTISET UNION DISTINCT table_varchar();
            
                IF l_tab_profs(1) IS NOT NULL
                THEN
                    l_profs := pk_utils.concat_table(l_tab_profs, l_sep);
                
                    l_destin := l_destin || ' (' || l_profs || ')';
                    l_destin_list.extend(1);
                    l_destin_list(l_destin_list.count) := l_destin;
                END IF;
            END IF;
        
            --process only the pending consults if exists only one pending
            l_destin := r_opinion.desc_spec;
            l_profs  := NULL;
            IF l_tab_profs_pending IS NOT NULL
               AND l_tab_profs_pending.count > 0
               AND l_pend_cons = pk_alert_constant.g_yes
            THEN
                l_tab_profs_pending := l_tab_profs_pending MULTISET UNION DISTINCT table_varchar();
            
                IF l_tab_profs_pending(1) IS NOT NULL
                THEN
                    l_profs := pk_utils.concat_table(l_tab_profs_pending, l_sep);
                
                    l_destin := l_destin;
                    l_destin_partial_list.extend(1);
                    l_destin_partial_list(l_destin_partial_list.count) := l_destin;
                END IF;
            END IF;
        END LOOP;
    
        o_dest_full := l_destin_list;
    
        IF l_pend_cons = pk_alert_constant.g_yes
        THEN
            o_dest_partial := l_destin_partial_list;
        ELSE
            o_dest_partial := l_destin_list;
        END IF;
    
        IF o_dest_partial.count = 0
        THEN
            SELECT pk_prof_utils.get_prof_speciality(i_lang,
                                                     profissional(ei.id_professional,
                                                                  ei.id_instit_requested,
                                                                  ei.id_software)) speciality
              BULK COLLECT
              INTO l_speciality
              FROM epis_info ei
             WHERE ei.id_episode = i_episode;
        
            o_dest_partial := l_speciality;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EPIS_DESTINATION_INT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_epis_destination_int;

    FUNCTION get_epis_destination
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_disch_reas_dest IN epis_info.id_disch_reas_dest%TYPE,
        i_flg_status      IN epis_info.flg_dsch_status%TYPE
    ) RETURN VARCHAR2 IS
    
        l_dummy     table_varchar;
        l_dest      VARCHAR2(32767);
        l_dest_list table_varchar;
        l_disch     VARCHAR2(32767);
    
        l_error t_error_out;
    
    BEGIN
    
        g_error := 'CALL GET_EPIS_DESTINATION_INT';
        IF NOT get_epis_destination_int(i_lang            => i_lang,
                                        i_prof            => i_prof,
                                        i_episode         => i_episode,
                                        i_disch_reas_dest => i_disch_reas_dest,
                                        i_flg_status      => i_flg_status,
                                        o_dest_partial    => l_dest_list,
                                        o_dest_full       => l_dummy,
                                        o_disch           => l_disch,
                                        o_error           => l_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        g_error := 'CALL PK_UTILS.CONCAT_TABLE';
        l_dest  := pk_utils.concat_table(l_dest_list, chr(10));
    
        RETURN nvl(l_disch, l_dest);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_warn(text            => g_error || ' (' || SQLCODE || ' - ' || SQLERRM || ')',
                                 sub_object_name => 'GET_EPIS_DESTINATION');
            RETURN NULL;
    END get_epis_destination;

    FUNCTION get_epis_lab_desc
    (
        i_lang IN language.id_language%TYPE,
        i_prof profissional,
        i_row  IN ROWID
    ) RETURN VARCHAR2 IS
    
        l_rec tracking_board_ea%ROWTYPE;
    
    BEGIN
    
        g_error := 'GET TRACKING_BOARD_EA REC';
        SELECT tbea.*
          INTO l_rec
          FROM tracking_board_ea tbea
         WHERE tbea.rowid = i_row;
    
        g_error := 'RETURN LAB DESC';
        RETURN substr(CASE WHEN l_rec.lab_pend IS NULL THEN NULL ELSE
                      ';' || get_status_string(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_display_type => pk_alert_constant.g_display_type_date,
                                               i_value_date   => pk_date_utils.date_send_tsz(i_lang,
                                                                                             to_timestamp_tz(l_rec.lab_pend,
                                                                                                             pk_alert_constant.g_dt_yyyymmddhh24miss_tzr),
                                                                                             i_prof),
                                               i_value_icon   => g_lab_flg_status_pend_img(i_lang),
                                               i_color        => pk_alert_constant.g_color_green,
                                               i_shortcut     => 8) END || CASE WHEN l_rec.lab_req IS NULL THEN NULL ELSE
                      ';' || get_status_string(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_display_type => pk_alert_constant.g_display_type_date,
                                               i_value_date   => pk_date_utils.date_send_tsz(i_lang,
                                                                                             to_timestamp_tz(l_rec.lab_req,
                                                                                                             pk_alert_constant.g_dt_yyyymmddhh24miss_tzr),
                                                                                             i_prof),
                                               i_value_icon   => NULL,
                                               i_color        => pk_alert_constant.g_color_red,
                                               i_shortcut     => 8) END || CASE WHEN l_rec.lab_harv IS NULL THEN NULL ELSE
                      ';' || get_status_string(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_display_type => pk_alert_constant.g_display_type_date_icon,
                                               i_value_date   => pk_date_utils.date_send_tsz(i_lang,
                                                                                             to_timestamp_tz(l_rec.lab_harv,
                                                                                                             pk_alert_constant.g_dt_yyyymmddhh24miss_tzr),
                                                                                             i_prof),
                                               i_value_icon   => g_lab_flg_status_harv_img(i_lang),
                                               i_color        => pk_alert_constant.g_color_none,
                                               i_shortcut     => 8) END || CASE WHEN l_rec.lab_transp IS NULL THEN NULL ELSE
                      ';' || get_status_string(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_display_type => pk_alert_constant.g_display_type_date_icon,
                                               i_value_date   => pk_date_utils.date_send_tsz(i_lang,
                                                                                             to_timestamp_tz(l_rec.lab_transp,
                                                                                                             pk_alert_constant.g_dt_yyyymmddhh24miss_tzr),
                                                                                             i_prof),
                                               i_value_icon   => g_lab_flg_status_trans_img(i_lang),
                                               i_color        => pk_alert_constant.g_color_none,
                                               i_shortcut     => 8) END || CASE WHEN l_rec.lab_exec IS NULL THEN NULL ELSE
                      ';' || get_status_string(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_display_type => pk_alert_constant.g_display_type_date_icon,
                                               i_value_date   => pk_date_utils.date_send_tsz(i_lang,
                                                                                             to_timestamp_tz(l_rec.lab_exec,
                                                                                                             pk_alert_constant.g_dt_yyyymmddhh24miss_tzr),
                                                                                             i_prof),
                                               i_value_icon   => g_lab_flg_status_exec_img(i_lang),
                                               i_color        => pk_alert_constant.g_color_none,
                                               i_shortcut     => 8) END || CASE WHEN l_rec.lab_result IS NULL THEN NULL ELSE
                      ';' || get_status_string(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_display_type => pk_alert_constant.g_display_type_date_icon,
                                               i_value_date   => pk_date_utils.date_send_tsz(i_lang,
                                                                                             to_timestamp_tz(l_rec.lab_result,
                                                                                                             pk_alert_constant.g_dt_yyyymmddhh24miss_tzr),
                                                                                             i_prof),
                                               i_value_icon   => g_lab_flg_status_result_img(i_lang),
                                               i_color        => pk_alert_constant.g_color_none,
                                               i_shortcut     => 8) END || CASE WHEN l_rec.lab_result_read IS NULL THEN NULL ELSE
                      ';' || get_status_string(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_display_type => pk_alert_constant.g_display_type_date_icon,
                                               i_value_date   => pk_date_utils.date_send_tsz(i_lang,
                                                                                             to_timestamp_tz(l_rec.lab_result_read,
                                                                                                             pk_alert_constant.g_dt_yyyymmddhh24miss_tzr),
                                                                                             i_prof),
                                               i_value_icon   => g_lab_flg_status_read_img(i_lang),
                                               i_color        => pk_alert_constant.g_color_none,
                                               i_shortcut     => 8) END || CASE WHEN l_rec.lab_wtg IS NULL THEN NULL ELSE
                      ';' || get_status_string(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_display_type => pk_alert_constant.g_display_type_icon,
                                               i_value_date   => NULL,
                                               i_value_icon   => g_lab_flg_status_wtg_img(i_lang),
                                               i_color        => pk_alert_constant.g_color_icon_dark_grey) END || CASE WHEN
                      l_rec.lab_ext IS NULL THEN NULL ELSE ';' || get_status_string(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_display_type => pk_alert_constant.g_display_type_date,
                                               i_value_date   => pk_date_utils.date_send_tsz(i_lang,
                                                                                             to_timestamp_tz(l_rec.lab_ext,
                                                                                                             pk_alert_constant.g_dt_yyyymmddhh24miss_tzr),
                                                                                             i_prof),
                                               i_value_icon   => g_lab_flg_status_ext_img(i_lang),
                                               i_color        => pk_alert_constant.g_color_red,
                                               i_shortcut     => 8) END || CASE WHEN l_rec.lab_cc IS NULL THEN NULL ELSE
                      ';' || get_status_string(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_display_type => pk_alert_constant.g_display_type_date,
                                               i_value_date   => pk_date_utils.date_send_tsz(i_lang,
                                                                                             to_timestamp_tz(l_rec.lab_cc,
                                                                                                             pk_alert_constant.g_dt_yyyymmddhh24miss_tzr),
                                                                                             i_prof),
                                               i_value_icon   => g_lab_flg_status_cc_img(i_lang),
                                               i_color        => pk_alert_constant.g_color_none,
                                               i_shortcut     => 8) END || CASE WHEN l_rec.lab_sos IS NULL THEN NULL ELSE
                      ';' || get_status_string(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_display_type => pk_alert_constant.g_display_type_date_icon,
                                               i_value_date   => pk_date_utils.date_send_tsz(i_lang,
                                                                                             to_timestamp_tz(l_rec.lab_sos,
                                                                                                             pk_alert_constant.g_dt_yyyymmddhh24miss_tzr),
                                                                                             i_prof),
                                               i_value_icon   => g_lab_flg_status_sos_img(i_lang),
                                               i_color        => pk_alert_constant.g_color_none,
                                               i_shortcut     => 8) END,
                      2);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_warn(text            => g_error || ' (' || SQLCODE || ' - ' || SQLERRM || ')',
                                 sub_object_name => 'GET_EPIS_LAB_DESC');
            RETURN NULL;
    END get_epis_lab_desc;

    FUNCTION get_epis_exam_desc
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_row  IN ROWID
    ) RETURN VARCHAR2 IS
    
        l_rec tracking_board_ea%ROWTYPE;
    
    BEGIN
    
        g_error := 'GET TRACKING_BOARD_EA REC';
        SELECT tbea.*
          INTO l_rec
          FROM tracking_board_ea tbea
         WHERE tbea.rowid = i_row;
    
        g_error := 'RETURN EXAM DESC';
        RETURN substr(CASE WHEN l_rec.exam_pend IS NULL THEN NULL ELSE
                      ';' || get_status_string(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_display_type => pk_alert_constant.g_display_type_date,
                                               i_value_date   => pk_date_utils.date_send_tsz(i_lang,
                                                                                             to_timestamp_tz(l_rec.exam_pend,
                                                                                                             pk_alert_constant.g_dt_yyyymmddhh24miss_tzr),
                                                                                             i_prof),
                                               i_value_icon   => NULL,
                                               i_color        => pk_alert_constant.g_color_green,
                                               i_shortcut     => 10) END || CASE WHEN l_rec.exam_req IS NULL THEN NULL ELSE
                      ';' || get_status_string(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_display_type => (CASE i_prof.software
                                                                     WHEN pk_alert_constant.g_soft_edis THEN
                                                                      pk_alert_constant.g_display_type_date
                                                                     WHEN pk_alert_constant.g_soft_inpatient THEN
                                                                      pk_alert_constant.g_display_type_date_icon
                                                                     ELSE
                                                                      NULL
                                                                 END),
                                               i_value_date   => pk_date_utils.date_send_tsz(i_lang,
                                                                                             to_timestamp_tz(l_rec.exam_req,
                                                                                                             pk_alert_constant.g_dt_yyyymmddhh24miss_tzr),
                                                                                             i_prof),
                                               i_value_icon   => (CASE i_prof.software
                                                                     WHEN pk_alert_constant.g_soft_inpatient THEN
                                                                      g_exam_flg_status_req_img(i_lang) --
                                                                     ELSE
                                                                      NULL
                                                                 END),
                                               i_color        => (CASE i_prof.software
                                                                     WHEN pk_alert_constant.g_soft_edis THEN
                                                                      pk_alert_constant.g_color_red
                                                                     WHEN pk_alert_constant.g_soft_inpatient THEN
                                                                      pk_alert_constant.g_color_none
                                                                     ELSE
                                                                      NULL
                                                                 END),
                                               i_shortcut     => 10) END || CASE WHEN l_rec.exam_transp IS NULL THEN NULL ELSE
                      ';' || get_status_string(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_display_type => pk_alert_constant.g_display_type_date_icon,
                                               i_value_date   => pk_date_utils.date_send_tsz(i_lang,
                                                                                             to_timestamp_tz(l_rec.exam_transp,
                                                                                                             pk_alert_constant.g_dt_yyyymmddhh24miss_tzr),
                                                                                             i_prof),
                                               i_value_icon   => g_exam_flg_status_mov_img(i_lang),
                                               i_color        => pk_alert_constant.g_color_none,
                                               i_shortcut     => 10) END || CASE WHEN l_rec.exam_exec IS NULL THEN NULL ELSE
                      ';' || get_status_string(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_display_type => pk_alert_constant.g_display_type_date_icon,
                                               i_value_date   => pk_date_utils.date_send_tsz(i_lang,
                                                                                             to_timestamp_tz(l_rec.exam_exec,
                                                                                                             pk_alert_constant.g_dt_yyyymmddhh24miss_tzr),
                                                                                             i_prof),
                                               i_value_icon   => g_exam_flg_status_exec_img(i_lang),
                                               i_color        => pk_alert_constant.g_color_none,
                                               i_shortcut     => 10) END || CASE WHEN l_rec.exam_result IS NULL THEN NULL ELSE
                      ';' || get_status_string(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_display_type => pk_alert_constant.g_display_type_date_icon,
                                               i_value_date   => pk_date_utils.date_send_tsz(i_lang,
                                                                                             to_timestamp_tz(l_rec.exam_result,
                                                                                                             pk_alert_constant.g_dt_yyyymmddhh24miss_tzr),
                                                                                             i_prof),
                                               i_value_icon   => g_exam_flg_status_result_img(i_lang),
                                               i_color        => pk_alert_constant.g_color_none,
                                               i_shortcut     => 10) END || CASE WHEN l_rec.exam_result_read IS NULL THEN NULL ELSE
                      ';' || get_status_string(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_display_type => pk_alert_constant.g_display_type_date_icon,
                                               i_value_date   => pk_date_utils.date_send_tsz(i_lang,
                                                                                             to_timestamp_tz(l_rec.exam_result_read,
                                                                                                             pk_alert_constant.g_dt_yyyymmddhh24miss_tzr),
                                                                                             i_prof),
                                               i_value_icon   => g_exam_flg_status_read_img(i_lang),
                                               i_color        => pk_alert_constant.g_color_none,
                                               i_shortcut     => 10) END || CASE WHEN l_rec.exam_wtg IS NULL THEN NULL ELSE
                      ';' || get_status_string(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_display_type => pk_alert_constant.g_display_type_icon,
                                               i_value_date   => NULL,
                                               i_value_icon   => g_exam_flg_status_wtg_img(i_lang),
                                               i_color        => pk_alert_constant.g_color_icon_dark_grey) END || CASE WHEN
                      l_rec.exam_ext IS NULL THEN NULL ELSE ';' || get_status_string(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_display_type => pk_alert_constant.g_display_type_date,
                                               i_value_date   => pk_date_utils.date_send_tsz(i_lang,
                                                                                             to_timestamp_tz(l_rec.exam_ext,
                                                                                                             pk_alert_constant.g_dt_yyyymmddhh24miss_tzr),
                                                                                             i_prof),
                                               i_value_icon   => g_exam_flg_status_ext_img(i_lang),
                                               i_color        => pk_alert_constant.g_color_red,
                                               i_shortcut     => 10) END || CASE WHEN l_rec.exam_perf IS NULL THEN NULL ELSE
                      ';' || get_status_string(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_display_type => pk_alert_constant.g_display_type_date_icon,
                                               i_value_date   => pk_date_utils.date_send_tsz(i_lang,
                                                                                             to_timestamp_tz(l_rec.exam_perf,
                                                                                                             pk_alert_constant.g_dt_yyyymmddhh24miss_tzr),
                                                                                             i_prof),
                                               i_value_icon   => g_exam_flg_status_perf_img(i_lang),
                                               i_color        => pk_alert_constant.g_color_none,
                                               i_shortcut     => 10) END || CASE WHEN l_rec.exam_sos IS NULL THEN NULL ELSE
                      ';' || get_status_string(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_display_type => pk_alert_constant.g_display_type_date_icon,
                                               i_value_date   => pk_date_utils.date_send_tsz(i_lang,
                                                                                             to_timestamp_tz(l_rec.exam_sos,
                                                                                                             pk_alert_constant.g_dt_yyyymmddhh24miss_tzr),
                                                                                             i_prof),
                                               i_value_icon   => g_exam_flg_status_sos_img(i_lang),
                                               i_color        => pk_alert_constant.g_color_none,
                                               i_shortcut     => 10) END,
                      2);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_warn(text            => g_error || ' (' || SQLCODE || ' - ' || SQLERRM || ')',
                                 sub_object_name => 'GET_EPIS_EXAM_DESC');
            RETURN NULL;
    END get_epis_exam_desc;

    FUNCTION get_epis_oth_exam_desc
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_row  IN ROWID
    ) RETURN VARCHAR2 IS
    
        l_rec tracking_board_ea%ROWTYPE;
    
    BEGIN
        g_error := 'GET TRACKING_BOARD_EA REC';
        SELECT tbea.*
          INTO l_rec
          FROM tracking_board_ea tbea
         WHERE tbea.rowid = i_row;
    
        g_error := 'RETURN OTH EXAM DESC';
        RETURN substr(CASE WHEN l_rec.oth_exam_pend IS NULL THEN NULL ELSE
                      ';' || get_status_string(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_display_type => pk_alert_constant.g_display_type_date,
                                               i_value_date   => pk_date_utils.date_send_tsz(i_lang,
                                                                                             to_timestamp_tz(l_rec.oth_exam_pend,
                                                                                                             pk_alert_constant.g_dt_yyyymmddhh24miss_tzr),
                                                                                             i_prof),
                                               i_value_icon   => NULL,
                                               i_color        => pk_alert_constant.g_color_green,
                                               i_shortcut     => 11) END || CASE WHEN l_rec.oth_exam_req IS NULL THEN NULL ELSE
                      ';' || get_status_string(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_display_type => (CASE i_prof.software
                                                                     WHEN pk_alert_constant.g_soft_edis THEN
                                                                      pk_alert_constant.g_display_type_date
                                                                     WHEN pk_alert_constant.g_soft_inpatient THEN
                                                                      pk_alert_constant.g_display_type_date_icon
                                                                     ELSE
                                                                      NULL
                                                                 END),
                                               i_value_date   => pk_date_utils.date_send_tsz(i_lang,
                                                                                             to_timestamp_tz(l_rec.oth_exam_req,
                                                                                                             pk_alert_constant.g_dt_yyyymmddhh24miss_tzr),
                                                                                             i_prof),
                                               i_value_icon   => (CASE i_prof.software
                                                                     WHEN pk_alert_constant.g_soft_inpatient THEN
                                                                      g_exam_flg_status_req_img(i_lang)
                                                                     ELSE
                                                                      NULL
                                                                 END),
                                               i_color        => (CASE i_prof.software
                                                                     WHEN pk_alert_constant.g_soft_edis THEN
                                                                      pk_alert_constant.g_color_red
                                                                     WHEN pk_alert_constant.g_soft_inpatient THEN
                                                                      pk_alert_constant.g_color_none
                                                                     ELSE
                                                                      NULL
                                                                 END),
                                               i_shortcut     => 11) END || CASE WHEN l_rec.oth_exam_transp IS NULL THEN NULL ELSE
                      ';' || get_status_string(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_display_type => pk_alert_constant.g_display_type_date_icon,
                                               i_value_date   => pk_date_utils.date_send_tsz(i_lang,
                                                                                             to_timestamp_tz(l_rec.oth_exam_transp,
                                                                                                             pk_alert_constant.g_dt_yyyymmddhh24miss_tzr),
                                                                                             i_prof),
                                               i_value_icon   => g_exam_flg_status_mov_img(i_lang),
                                               i_color        => pk_alert_constant.g_color_none,
                                               i_shortcut     => 11) END || CASE WHEN l_rec.oth_exam_exec IS NULL THEN NULL ELSE
                      ';' || get_status_string(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_display_type => pk_alert_constant.g_display_type_date_icon,
                                               i_value_date   => pk_date_utils.date_send_tsz(i_lang,
                                                                                             to_timestamp_tz(l_rec.oth_exam_exec,
                                                                                                             pk_alert_constant.g_dt_yyyymmddhh24miss_tzr),
                                                                                             i_prof),
                                               i_value_icon   => g_exam_flg_status_exec_img(i_lang),
                                               i_color        => pk_alert_constant.g_color_none,
                                               i_shortcut     => 11) END || CASE WHEN l_rec.oth_exam_result IS NULL THEN NULL ELSE
                      ';' || get_status_string(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_display_type => pk_alert_constant.g_display_type_date_icon,
                                               i_value_date   => pk_date_utils.date_send_tsz(i_lang,
                                                                                             to_timestamp_tz(l_rec.oth_exam_result,
                                                                                                             pk_alert_constant.g_dt_yyyymmddhh24miss_tzr),
                                                                                             i_prof),
                                               i_value_icon   => g_exam_flg_status_result_img(i_lang),
                                               i_color        => pk_alert_constant.g_color_none,
                                               i_shortcut     => 11) END || CASE WHEN
                      l_rec.oth_exam_result_read IS NULL THEN NULL ELSE
                      ';' || get_status_string(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_display_type => pk_alert_constant.g_display_type_date_icon,
                                               i_value_date   => pk_date_utils.date_send_tsz(i_lang,
                                                                                             to_timestamp_tz(l_rec.oth_exam_result_read,
                                                                                                             pk_alert_constant.g_dt_yyyymmddhh24miss_tzr),
                                                                                             i_prof),
                                               i_value_icon   => g_exam_flg_status_read_img(i_lang),
                                               i_color        => pk_alert_constant.g_color_none,
                                               i_shortcut     => 11) END || CASE WHEN l_rec.oth_exam_wtg IS NULL THEN NULL ELSE
                      ';' || get_status_string(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_display_type => pk_alert_constant.g_display_type_icon,
                                               i_value_date   => NULL,
                                               i_value_icon   => g_exam_flg_status_wtg_img(i_lang),
                                               i_color        => pk_alert_constant.g_color_icon_dark_grey) END || CASE WHEN
                      l_rec.oth_exam_ext IS NULL THEN NULL ELSE ';' || get_status_string(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_display_type => pk_alert_constant.g_display_type_date,
                                               i_value_date   => pk_date_utils.date_send_tsz(i_lang,
                                                                                             to_timestamp_tz(l_rec.oth_exam_ext,
                                                                                                             pk_alert_constant.g_dt_yyyymmddhh24miss_tzr),
                                                                                             i_prof),
                                               i_value_icon   => g_exam_flg_status_ext_img(i_lang),
                                               i_color        => pk_alert_constant.g_color_red,
                                               i_shortcut     => 11) END || CASE WHEN l_rec.oth_exam_perf IS NULL THEN NULL ELSE
                      ';' || get_status_string(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_display_type => pk_alert_constant.g_display_type_date_icon,
                                               i_value_date   => pk_date_utils.date_send_tsz(i_lang,
                                                                                             to_timestamp_tz(l_rec.oth_exam_perf,
                                                                                                             pk_alert_constant.g_dt_yyyymmddhh24miss_tzr),
                                                                                             i_prof),
                                               i_value_icon   => g_exam_flg_status_perf_img(i_lang),
                                               i_color        => pk_alert_constant.g_color_none,
                                               i_shortcut     => 11) END || CASE WHEN l_rec.oth_exam_sos IS NULL THEN NULL ELSE
                      ';' || get_status_string(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_display_type => pk_alert_constant.g_display_type_date_icon,
                                               i_value_date   => pk_date_utils.date_send_tsz(i_lang,
                                                                                             to_timestamp_tz(l_rec.oth_exam_sos,
                                                                                                             pk_alert_constant.g_dt_yyyymmddhh24miss_tzr),
                                                                                             i_prof),
                                               i_value_icon   => g_exam_flg_status_sos_img(i_lang),
                                               i_color        => pk_alert_constant.g_color_none,
                                               i_shortcut     => 11) END,
                      2);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
            RETURN NULL;
    END get_epis_oth_exam_desc;

    FUNCTION get_epis_monit_desc
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
    
        l_result VARCHAR(4000) := '';
        l_lines  pk_edis_types.table_line;
        l_temp   VARCHAR2(200);
    
    BEGIN
    
        BEGIN
            g_error := 'GET ' || i_episode || ' MONIT DATA';
            SELECT MIN(dt_status) dt_status, flg_text, content, color, rank
              BULK COLLECT
              INTO l_lines
              FROM (SELECT decode(mea.flg_status_det,
                                  pk_alert_constant.g_monitor_vs_fini,
                                  CAST(NULL AS TIMESTAMP WITH LOCAL TIME ZONE),
                                  mea.dt_plan) dt_status,
                           decode(mea.flg_status_det,
                                  pk_alert_constant.g_monitor_vs_fini,
                                  pk_alert_constant.g_display_type_icon,
                                  pk_alert_constant.g_display_type_date) flg_text,
                           decode(mea.flg_status_det,
                                  pk_alert_constant.g_monitor_vs_exec,
                                  g_monit_det_exec_img(i_lang),
                                  pk_alert_constant.g_monitor_vs_fini,
                                  g_monit_det_fini_img(i_lang)) content,
                           decode(mea.flg_status,
                                  pk_alert_constant.g_monitor_vs_fini,
                                  pk_alert_constant.g_color_none,
                                  decode(least(mea.dt_plan, g_sysdate_tstz),
                                         g_sysdate_tstz,
                                         pk_alert_constant.g_color_green,
                                         pk_alert_constant.g_color_red)) color,
                           decode(mea.flg_status_det,
                                  pk_alert_constant.g_monitor_vs_exec,
                                  0,
                                  pk_alert_constant.g_monitor_vs_fini,
                                  100,
                                  50) rank
                      FROM monitorizations_ea mea
                     WHERE mea.flg_time = pk_alert_constant.g_flg_time_e
                       AND mea.id_episode = i_episode
                       AND mea.flg_status_det IN (pk_alert_constant.g_monitor_vs_pend,
                                                  pk_alert_constant.g_monitor_vs_exec,
                                                  pk_alert_constant.g_monitor_vs_fini))
             GROUP BY flg_text, content, color, rank
             ORDER BY rank, color DESC;
        
            g_error  := 'LOOP';
            l_result := '';
            FOR idx IN 1 .. l_lines.count
            LOOP
                IF length(l_result) < 3900
                   OR l_result IS NULL
                THEN
                
                    l_temp := get_status_string(i_lang         => i_lang,
                                                i_prof         => i_prof,
                                                i_display_type => l_lines(idx).flg_text,
                                                i_value_date   => nvl(pk_date_utils.date_send_tsz(i_lang,
                                                                                                  l_lines(idx).dt_status,
                                                                                                  i_prof),
                                                                      'xxxxxxxxxxxxxx'),
                                                i_value_icon   => l_lines(idx).content,
                                                i_color        => l_lines(idx).color);
                
                    l_result := l_result || ';' || pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, l_temp);
                
                END IF;
            END LOOP;
        
            l_result := substr(l_result, 2);
        
        EXCEPTION
            WHEN no_data_found THEN
                g_error  := 'NO_DATA_FOUND';
                l_result := NULL;
        END;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_warn(text            => g_error || ' (' || SQLCODE || ' - ' || SQLERRM || ')',
                                 sub_object_name => 'GET_EPIS_MONIT_DESC');
            RETURN NULL;
    END get_epis_monit_desc;

    FUNCTION get_epis_drug_desc
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        i_external_tr IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_result    VARCHAR2(4000) := '';
        l_dt_status TIMESTAMP WITH LOCAL TIME ZONE;
        l_lines     pk_edis_types.table_line;
    
    BEGIN
    
        g_error := 'CALL PK_API_PFH_CLINDOC_IN.GET_TRACKING_VIEW_DRUG';
        l_lines := pk_api_pfh_clindoc_in.get_tracking_view_drug(i_lang        => i_lang,
                                                                i_prof        => i_prof,
                                                                i_episode     => i_episode,
                                                                i_sysdate     => g_sysdate_tstz,
                                                                i_external_tr => i_external_tr);
    
        g_error := 'LOOP';
        FOR idx IN 1 .. l_lines.count
        LOOP
        
            l_dt_status := l_lines(idx).dt_status;
        
            l_result := l_result || ';' ||
                        get_status_string(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_display_type => l_lines(idx).flg_text,
                                          i_value_date   => pk_date_utils.date_send_tsz(i_lang, l_dt_status, i_prof),
                                          i_value_icon   => l_lines(idx).content,
                                          i_color        => l_lines(idx).color);
        
        END LOOP;
    
        l_result := substr(l_result, 2);
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_warn(text            => g_error || ' (' || SQLCODE || ' - ' || SQLERRM || ')',
                                 sub_object_name => 'GET_EPIS_DRUG_DESC');
            RETURN NULL;
    END get_epis_drug_desc;

    FUNCTION get_epis_interv_desc
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
    
        l_result VARCHAR2(4000) := '';
        l_lines  pk_edis_types.table_line;
        l_temp   VARCHAR2(200);
    
        l_id_patient patient.id_patient%TYPE;
    
    BEGIN
    
        l_id_patient := pk_episode.get_id_patient(i_episode);
    
        -- Oracle bug -> decode + min + bulk collect + called from query -> broken date
        -- loop used instead
        BEGIN
            g_error := 'QUERY DATA';
            SELECT MIN(dt_status) dt_status, flg_text, content, color, rank
              BULK COLLECT
              INTO l_lines
              FROM (SELECT -- DATE
                     decode(pea.flg_interv_type,
                            pk_alert_constant.g_interv_type_sos,
                            CAST(NULL AS TIMESTAMP WITH LOCAL TIME ZONE),
                            pk_alert_constant.g_interv_type_con,
                            decode(pea.flg_status_det,
                                   pk_alert_constant.g_interv_det_exec,
                                   CAST(NULL AS TIMESTAMP WITH LOCAL TIME ZONE),
                                   pk_alert_constant.g_interv_det_fin,
                                   CAST(NULL AS TIMESTAMP WITH LOCAL TIME ZONE),
                                   coalesce(pea.dt_plan, pea.dt_begin_det, pea.dt_order)),
                            decode(pea.flg_status_det,
                                   pk_alert_constant.g_interv_det_fin,
                                   CAST(NULL AS TIMESTAMP WITH LOCAL TIME ZONE),
                                   coalesce(pea.dt_plan, pea.dt_begin_det, pea.dt_order))) dt_status,
                     -- TEXT
                     decode(pea.flg_interv_type,
                            pk_alert_constant.g_interv_type_sos,
                            pk_alert_constant.g_display_type_label,
                            pk_alert_constant.g_interv_type_con,
                            decode(pea.flg_status_det,
                                   pk_alert_constant.g_interv_det_exec,
                                   pk_alert_constant.g_display_type_icon,
                                   pk_alert_constant.g_interv_det_fin,
                                   pk_alert_constant.g_display_type_icon,
                                   pk_alert_constant.g_display_type_date),
                            decode(pea.flg_status_det,
                                   pk_alert_constant.g_interv_det_fin,
                                   pk_alert_constant.g_display_type_icon,
                                   pk_alert_constant.g_display_type_date)) flg_text,
                     -- ICON
                     decode(pea.flg_interv_type,
                            pk_alert_constant.g_interv_type_sos,
                            g_msg_drug_sos,
                            pk_alert_constant.g_interv_type_con,
                            decode(pea.flg_status_det,
                                   pk_alert_constant.g_interv_det_exec,
                                   g_interv_flg_status_exec_img(i_lang),
                                   pk_alert_constant.g_interv_det_fin,
                                   g_interv_flg_status_fin_img(i_lang),
                                   pk_alert_constant.g_interv_det_ext,
                                   g_interv_flg_status_ext_img(i_lang)),
                            decode(pea.flg_status_det,
                                   pk_alert_constant.g_interv_det_fin,
                                   g_interv_flg_status_fin_img(i_lang))) content,
                     -- COLOR
                     decode(pea.flg_interv_type,
                            pk_alert_constant.g_interv_type_sos,
                            pk_alert_constant.g_color_none,
                            pk_alert_constant.g_interv_type_con,
                            decode(pea.flg_status_det,
                                   pk_alert_constant.g_interv_det_exec,
                                   pk_alert_constant.g_color_none,
                                   pk_alert_constant.g_interv_det_fin,
                                   pk_alert_constant.g_color_none,
                                   decode(least(g_sysdate_tstz, coalesce(pea.dt_plan, pea.dt_begin_det, pea.dt_order)),
                                          g_sysdate_tstz,
                                          pk_alert_constant.g_color_green,
                                          pk_alert_constant.g_color_red)),
                            decode(pea.flg_status_det,
                                   pk_alert_constant.g_interv_det_fin,
                                   pk_alert_constant.g_color_none,
                                   decode(least(g_sysdate_tstz, coalesce(pea.dt_plan, pea.dt_begin_det, pea.dt_order)),
                                          g_sysdate_tstz,
                                          pk_alert_constant.g_color_green,
                                          pk_alert_constant.g_color_red))) color,
                     -- RANK
                     decode(pea.flg_interv_type,
                            pk_alert_constant.g_interv_type_sos,
                            1,
                            decode(pea.flg_status_det,
                                   pk_alert_constant.g_interv_det_pend,
                                   3,
                                   pk_alert_constant.g_interv_det_req,
                                   2,
                                   pk_alert_constant.g_interv_det_exec,
                                   4,
                                   pk_alert_constant.g_interv_det_fin,
                                   5,
                                   pk_alert_constant.g_interv_det_ext,
                                   6)) rank
                      FROM (SELECT *
                              FROM procedures_ea pea
                             WHERE pea.flg_time = pk_alert_constant.g_flg_time_e
                               AND pea.id_episode = i_episode
                               AND pea.id_intervention IN
                                   (SELECT id_intervention
                                      FROM interv_dep_clin_serv idcs
                                     WHERE idcs.id_institution = i_prof.institution)
                               AND pea.flg_status_det IN (pk_alert_constant.g_interv_det_req,
                                                          pk_alert_constant.g_interv_det_pend,
                                                          pk_alert_constant.g_interv_det_fin,
                                                          pk_alert_constant.g_interv_det_exec,
                                                          pk_alert_constant.g_interv_det_ext)
                               AND nvl(pea.flg_status_plan, pk_alert_constant.g_interv_plan_req) IN
                                   (pk_alert_constant.g_interv_plan_req,
                                    pk_alert_constant.g_interv_plan_pend,
                                    decode(pea.flg_status_det,
                                           pk_alert_constant.g_interv_det_fin,
                                           pk_alert_constant.g_interv_plan_admt,
                                           decode(pea.flg_interv_type,
                                                  pk_alert_constant.g_interv_type_sos,
                                                  pk_alert_constant.g_interv_plan_admt,
                                                  NULL)))
                                  -- José Brito 20/11/2009 ALERT-57349
                               AND (pea.flg_referral <> 'S' OR pea.flg_referral IS NULL)
                            UNION ALL
                            SELECT *
                              FROM procedures_ea pea
                             WHERE pea.flg_time IN
                                   (pk_procedures_constant.g_flg_time_a, pk_procedures_constant.g_flg_time_h)
                               AND pea.id_patient = l_id_patient
                               AND pea.id_intervention IN
                                   (SELECT id_intervention
                                      FROM interv_dep_clin_serv idcs
                                     WHERE idcs.id_institution = i_prof.institution)
                               AND pea.flg_status_det IN (pk_alert_constant.g_interv_det_req,
                                                          pk_alert_constant.g_interv_det_pend,
                                                          pk_alert_constant.g_interv_det_fin,
                                                          pk_alert_constant.g_interv_det_exec,
                                                          pk_alert_constant.g_interv_det_ext)
                               AND nvl(pea.flg_status_plan, pk_alert_constant.g_interv_plan_req) IN
                                   (pk_alert_constant.g_interv_plan_req,
                                    pk_alert_constant.g_interv_plan_pend,
                                    decode(pea.flg_status_det,
                                           pk_alert_constant.g_interv_det_fin,
                                           pk_alert_constant.g_interv_plan_admt,
                                           decode(pea.flg_interv_type,
                                                  pk_alert_constant.g_interv_type_sos,
                                                  pk_alert_constant.g_interv_plan_admt,
                                                  NULL)))
                                  -- José Brito 20/11/2009 ALERT-57349
                               AND (pea.flg_referral <> 'S' OR pea.flg_referral IS NULL)) pea)
             GROUP BY flg_text, content, color, rank
             ORDER BY rank ASC, dt_status ASC;
        
            g_error := 'LOOP';
            FOR idx IN 1 .. l_lines.count
            LOOP
            
                l_temp := get_status_string(i_lang         => i_lang,
                                            i_prof         => i_prof,
                                            i_display_type => l_lines(idx).flg_text,
                                            i_value_date   => pk_date_utils.date_send_tsz(i_lang,
                                                                                          l_lines(idx).dt_status,
                                                                                          i_prof),
                                            i_value_icon   => l_lines(idx).content,
                                            i_color        => l_lines(idx).color,
                                            i_shortcut     => 10451);
            
                l_result := l_result || ';' || l_temp;
            
            END LOOP;
        
            l_result := substr(l_result, 2);
        
        EXCEPTION
            WHEN no_data_found THEN
                g_error  := 'NO_DATA_FOUND';
                l_result := NULL;
        END;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_warn(text            => g_error || ' (' || SQLCODE || ' - ' || SQLERRM || ')',
                                 sub_object_name => 'GET_EPIS_INTERV_DESC');
            RETURN NULL;
    END get_epis_interv_desc;

    FUNCTION get_message_array
    (
        i_lang         IN NUMBER,
        i_code_msg_arr IN table_varchar,
        o_desc_msg_arr OUT pk_types.cursor_type
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN pk_message.get_message_array(i_lang, i_code_msg_arr, o_desc_msg_arr);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_desc_msg_arr);
            RETURN FALSE;
    END get_message_array;

    FUNCTION get_config
    (
        i_code_cf     IN VARCHAR2,
        i_institution IN NUMBER,
        o_msg_cf      OUT VARCHAR2
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN pk_sysconfig.get_config(i_code_cf,
                                       profissional(0, i_institution, pk_alert_constant.g_soft_edis),
                                       o_msg_cf);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_config;

    FUNCTION get_grid_labels
    (
        i_lang               IN language.id_language%TYPE,
        i_institution        IN NUMBER,
        o_label_tb_name_col  OUT VARCHAR2,
        o_label_responsibles OUT VARCHAR2
    ) RETURN BOOLEAN IS
    
        l_error t_error_out;
    
    BEGIN
    
        RETURN pk_edis_grid.get_grid_labels(i_lang               => i_lang,
                                            i_prof               => profissional(0,
                                                                                 i_institution,
                                                                                 pk_alert_constant.g_soft_edis),
                                            o_label_tb_name_col  => o_label_tb_name_col,
                                            o_label_responsibles => o_label_responsibles,
                                            o_error              => l_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_grid_labels;

    FUNCTION get_vip_icons
    (
        i_lang      IN language.id_language%TYPE,
        o_vip_icons OUT NOCOPY pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_utils.get_vip_icons(i_lang => i_lang, i_prof => NULL, o_vip_icons => o_vip_icons, o_error => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
            pk_types.open_my_cursor(o_vip_icons);
            RETURN FALSE;
    END get_vip_icons;

    FUNCTION get_config
    (
        i_code_cf     IN table_varchar,
        i_institution IN NUMBER,
        i_software    IN NUMBER,
        o_msg_cf      OUT pk_types.cursor_type
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN pk_sysconfig.get_config(i_code_cf, profissional(0, i_institution, i_software), o_msg_cf);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
            pk_types.open_my_cursor(o_msg_cf);
            RETURN FALSE;
    END get_config;

    FUNCTION get_status_string
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_display_type IN VARCHAR2,
        i_value_date   IN VARCHAR2,
        i_value_icon   IN VARCHAR2,
        i_color        IN VARCHAR2,
        i_shortcut     IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2 IS
    
        l_server_date VARCHAR2(200);
        l_aux         VARCHAR2(200);
        l_temp        VARCHAR2(200);
    
    BEGIN
    
        g_error := 'CALL PK_UTILS.GET_STATUS_STRING_IMMEDIATE';
        pk_utils.build_status_string(i_display_type => i_display_type,
                                     i_value_date   => i_value_date,
                                     i_shortcut     => i_shortcut,
                                     i_value_icon   => i_value_icon,
                                     i_icon_color   => i_color,
                                     o_status_str   => l_temp,
                                     o_status_msg   => l_aux,
                                     o_status_icon  => l_aux,
                                     o_status_flg   => l_aux);
    
        l_temp := REPLACE(l_temp, pk_alert_constant.g_status_rpl_chr_icon, i_value_icon);
    
        l_server_date := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
    
        l_temp := REPLACE(l_temp, pk_alert_constant.g_status_rpl_chr_dt_server, l_server_date) || '|';
    
        RETURN l_temp;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
            RETURN NULL;
    END get_status_string;

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
        k_episode          CONSTANT NUMBER(24) := 5;
    
        l_prof    CONSTANT profissional := profissional(i_context_ids(g_prof_id),
                                                        i_context_ids(g_prof_institution),
                                                        i_context_ids(g_prof_software));
        l_lang    CONSTANT language.id_language%TYPE := i_context_ids(g_lang);
        l_episode CONSTANT episode.id_episode%TYPE := i_context_ids(k_episode);
    
        l_hand_off_type sys_config.value%TYPE;
        l_config_show_resident CONSTANT sys_config.id_sys_config%TYPE := 'GRIDS_SHOW_RESIDENT';
    
        -- config to be used exclusively during an upgrade with migrated patients
        l_config_temp_room CONSTANT sys_config.id_sys_config%TYPE := 'MIGRATE_PATIENTS_TEMP_ROOM';
    
        l_orderby_room CONSTANT sys_config.value%TYPE := 'R';
        l_orderby_los  CONSTANT sys_config.value%TYPE := 'L';
        l_orderby        sys_config.value%TYPE;
        l_temp_room      sys_config.value%TYPE;
        l_config_refresh sys_config.id_sys_config%TYPE;
        l_id_room        room.id_room%TYPE;
    
        l_error t_error_out;
    BEGIN
        l_temp_room := pk_sysconfig.get_config(i_code_cf => l_config_temp_room, i_prof => l_prof);
        pk_context_api.set_parameter('i_lang', l_lang);
        pk_context_api.set_parameter('i_id_prof', l_prof.id);
        pk_context_api.set_parameter('i_id_institution', l_prof.institution);
        pk_context_api.set_parameter('i_id_software', l_prof.software);
        pk_context_api.set_parameter('l_temp_room', l_temp_room);
    
        IF NOT g_flg_exec_glob.exists(l_lang)
        THEN
            g_flg_exec_glob(l_lang) := FALSE;
        END IF;
    
        IF NOT g_flg_exec_glob(l_lang)
        THEN
            g_exam_flg_status_req_img(l_lang) := pk_sysdomain.get_img(l_lang,
                                                                      'EXAM_REQ_DET.FLG_STATUS',
                                                                      pk_alert_constant.g_exam_det_req);
            g_exam_flg_status_mov_img(l_lang) := pk_sysdomain.get_img(l_lang,
                                                                      'MOVEMENT.FLG_STATUS',
                                                                      pk_alert_constant.g_mov_status_transp);
            g_exam_flg_status_exec_img(l_lang) := pk_sysdomain.get_img(l_lang,
                                                                       'EXAM_REQ_DET.FLG_STATUS',
                                                                       pk_alert_constant.g_exam_det_exec);
            g_exam_flg_status_result_img(l_lang) := pk_sysdomain.get_img(l_lang,
                                                                         'EXAM_REQ_DET.FLG_STATUS',
                                                                         pk_alert_constant.g_exam_det_result);
            g_exam_flg_status_read_img(l_lang) := pk_sysdomain.get_img(l_lang,
                                                                       'EXAM_REQ_DET.FLG_STATUS',
                                                                       pk_alert_constant.g_exam_det_read);
            g_exam_flg_status_ext_img(l_lang) := pk_sysdomain.get_img(l_lang,
                                                                      'EXAM_REQ_DET.FLG_STATUS',
                                                                      pk_alert_constant.g_exam_det_ext);
            g_exam_flg_status_perf_img(l_lang) := pk_sysdomain.get_img(l_lang,
                                                                       'EXAM_REQ_DET.FLG_STATUS',
                                                                       pk_alert_constant.g_exam_det_performed);
            g_exam_flg_status_wtg_img(l_lang) := pk_sysdomain.get_img(l_lang,
                                                                      'EXAM_REQ_DET.FLG_STATUS',
                                                                      pk_exam_constant.g_exam_wtg_tde);
            g_exam_flg_status_sos_img(l_lang) := pk_sysdomain.get_img(l_lang,
                                                                      'EXAM_REQ_DET.FLG_STATUS',
                                                                      pk_exam_constant.g_exam_sos);
            g_lab_flg_status_pend_img(l_lang) := pk_sysdomain.get_img(l_lang,
                                                                      'ANALYSIS_REQ_DET.FLG_STATUS',
                                                                      pk_alert_constant.g_analysis_det_pend);
            g_lab_flg_status_harv_img(l_lang) := pk_sysdomain.get_img(l_lang,
                                                                      'HARVEST.FLG_STATUS',
                                                                      pk_alert_constant.g_harvest_harv);
            g_lab_flg_status_trans_img(l_lang) := pk_sysdomain.get_img(l_lang,
                                                                       'HARVEST.FLG_STATUS',
                                                                       pk_alert_constant.g_harvest_trans);
            g_lab_flg_status_exec_img(l_lang) := pk_sysdomain.get_img(l_lang,
                                                                      'ANALYSIS_REQ_DET.FLG_STATUS',
                                                                      pk_alert_constant.g_analysis_det_exec);
            g_lab_flg_status_result_img(l_lang) := pk_sysdomain.get_img(l_lang,
                                                                        'ANALYSIS_REQ_DET.FLG_STATUS',
                                                                        pk_alert_constant.g_analysis_det_result);
            g_lab_flg_status_read_img(l_lang) := pk_sysdomain.get_img(l_lang,
                                                                      'ANALYSIS_REQ_DET.FLG_STATUS',
                                                                      pk_alert_constant.g_analysis_det_read);
            g_lab_flg_status_ext_img(l_lang) := pk_sysdomain.get_img(l_lang,
                                                                     'ANALYSIS_REQ_DET.FLG_STATUS',
                                                                     pk_alert_constant.g_analysis_det_ext);
            g_lab_flg_status_wtg_img(l_lang) := pk_sysdomain.get_img(l_lang,
                                                                     'ANALYSIS_REQ_DET.FLG_STATUS',
                                                                     pk_lab_tests_constant.g_analysis_wtg_tde);
            g_lab_flg_status_sos_img(l_lang) := pk_sysdomain.get_img(l_lang,
                                                                     'ANALYSIS_REQ_DET.FLG_STATUS',
                                                                     pk_lab_tests_constant.g_analysis_sos);
            g_lab_flg_status_cc_img(l_lang) := pk_sysdomain.get_img(l_lang,
                                                                    'ANALYSIS_REQ_DET.FLG_STATUS',
                                                                    pk_lab_tests_constant.g_analysis_oncollection);
            g_monit_det_exec_img(l_lang) := pk_sysdomain.get_img(l_lang,
                                                                 'MONITORIZATION_VS.FLG_STATUS',
                                                                 pk_alert_constant.g_monitor_vs_exec);
            g_monit_det_fini_img(l_lang) := pk_sysdomain.get_img(l_lang,
                                                                 'MONITORIZATION_VS.FLG_STATUS',
                                                                 pk_alert_constant.g_monitor_vs_fini);
        
            g_interv_flg_status_exec_img(l_lang) := pk_sysdomain.get_img(l_lang,
                                                                         'INTERV_PRESC_DET.FLG_STATUS',
                                                                         pk_alert_constant.g_interv_det_exec);
            g_interv_flg_status_fin_img(l_lang) := pk_sysdomain.get_img(l_lang,
                                                                        'INTERV_PRESC_DET.FLG_STATUS',
                                                                        pk_alert_constant.g_interv_det_fin);
        
            g_interv_flg_status_ext_img(l_lang) := pk_sysdomain.get_img(l_lang,
                                                                        'INTERV_PRESC_DET.FLG_STATUS',
                                                                        pk_alert_constant.g_interv_det_ext);
        
            g_interv_msg_it056(l_lang) := pk_message.get_message(l_lang, 'ICON_T056');
        
            g_flg_exec_glob(l_lang) := TRUE;
        
        END IF;
    
        IF i_context_vals IS NOT NULL
           AND i_context_vals.count > 0
        THEN
            l_id_room := to_number(i_context_vals(1));
            pk_context_api.set_parameter('i_id_room', l_id_room);
        END IF;
    
        CASE i_name
            WHEN 'i_episode' THEN
                o_id := l_episode;
            
            WHEN 'g_cat_type_doc' THEN
                o_vc2 := pk_alert_constant.g_cat_type_doc;
            
            WHEN 'g_cat_type_nurse' THEN
                o_vc2 := pk_alert_constant.g_cat_type_nurse;
            
            WHEN 'g_cf_pat_gender_abbr' THEN
                o_vc2 := g_cf_pat_gender_abbr;
            
            WHEN 'i_lang' THEN
                o_id := l_lang;
            
            WHEN 'i_prof_cat' THEN
                o_vc2 := pk_prof_utils.get_category(i_lang => l_lang, i_prof => l_prof);
            
            WHEN 'i_prof_id' THEN
                o_id := l_prof.id;
            
            WHEN 'i_prof_institution' THEN
                o_id := l_prof.institution;
            
            WHEN 'i_prof_software' THEN
                o_id := l_prof.software;
            
            WHEN 'l_hand_off_type' THEN
                pk_hand_off_core.get_hand_off_type(l_lang, l_prof, l_hand_off_type);
                o_vc2 := l_hand_off_type;
            
            WHEN 'current_timestamp' THEN
                o_tstz := current_timestamp;
            
            WHEN 'g_edis_epis_type' THEN
                o_id := pk_alert_constant.g_epis_type_emergency;
            
            WHEN 'g_no' THEN
                o_vc2 := pk_alert_constant.g_no;
            
            WHEN 'g_yes' THEN
                o_vc2 := pk_alert_constant.g_yes;
            
            WHEN 'l_show_resident_physician' THEN
                o_vc2 := pk_sysconfig.get_config(i_code_cf => l_config_show_resident, i_prof => l_prof);
            
            WHEN 'g_resident' THEN
                o_vc2 := pk_hand_off_core.g_resident;
            
            WHEN 'l_show_only_epis_resp' THEN
                o_vc2 := pk_sysconfig.get_config(i_code_cf => pk_hand_off_core.g_config_show_only_epis_resp,
                                                 i_prof    => l_prof);
            
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
            
            WHEN 'g_show_in_grid' THEN
                o_vc2 := g_show_in_grid;
            
            WHEN 'g_show_in_tooltip' THEN
                o_vc2 := g_show_in_tooltip;
            
            WHEN 'g_sort_type_los' THEN
                o_vc2 := pk_edis_proc.g_sort_type_los;
            
            WHEN 'l_orderby' THEN
                o_vc2 := pk_sysconfig.get_config(i_code_cf => 'TRACKING_VIEW_ORDERBY', i_prof => l_prof);
            
            WHEN 'l_orderby_room' THEN
                o_vc2 := l_orderby_room;
            
            WHEN 'l_orderby_los' THEN
                o_vc2 := l_orderby_los;
            
            WHEN 'l_config_refresh' THEN
                o_vc2 := pk_sysconfig.get_config(i_code_cf => 'TRACKING_VIEW_REFRESH', i_prof => l_prof);
            
            WHEN 'g_dt_yyyymmddhh24miss_tzr' THEN
                o_vc2 := pk_alert_constant.g_dt_yyyymmddhh24miss_tzr;
            
            WHEN 'g_color_red' THEN
                o_vc2 := pk_alert_constant.g_color_red;
            
            WHEN 'g_color_none' THEN
                o_vc2 := pk_alert_constant.g_color_none;
            
            WHEN 'g_display_type_date' THEN
                o_vc2 := pk_alert_constant.g_display_type_date;
            
            WHEN 'g_display_type_icon' THEN
                o_vc2 := pk_alert_constant.g_display_type_icon;
            
            WHEN 'g_opinion_req' THEN
                o_vc2 := pk_opinion.g_opinion_req;
            
            WHEN 'g_opinion_req_read' THEN
                o_vc2 := pk_opinion.g_opinion_req_read;
            
            WHEN 'g_opinion_consults' THEN
                o_vc2 := pk_opinion.g_opinion_consults;
            
            WHEN 'g_opinion_reply' THEN
                o_vc2 := pk_opinion.g_opinion_reply;
            
            WHEN 'g_opinion_cancel' THEN
                o_vc2 := pk_opinion.g_opinion_cancel;
            
            WHEN 'g_sysdate_tstz' THEN
                o_tstz := current_timestamp;
            
            WHEN 'l_orign_order_without_tri' THEN
                o_vc2 := pk_sysconfig.get_config(i_code_cf => 'EDIS_GRID_ORIGIN_ORDER_WITHOUT_TRIAGE', i_prof => l_prof);
            
            WHEN 'l_config_origin' THEN
                o_vc2 := pk_sysconfig.get_config('GRID_ORIGINS', l_prof);
            
            WHEN 'l_order_by_flg_letter' THEN
                o_vc2 := orderby_flg_letter(l_prof);
            
        END CASE;
    END init_params_patient_grids;
BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_tracking_view;
/
