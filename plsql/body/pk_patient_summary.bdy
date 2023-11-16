/*-- Last Change Revision: $Rev: 2027466 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:19 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_patient_summary IS

    -- use this to force UI layer *not* to follow shortcuts
    g_null_shortcut CONSTANT sys_shortcut.id_sys_shortcut%TYPE := NULL;

    g_dashboard_view CONSTANT view_option.subject%TYPE := 'DASHBOARD';

    g_open_bold            CONSTANT VARCHAR2(3 CHAR) := '<b>';
    g_close_bold           CONSTANT VARCHAR2(4 CHAR) := '</b>';
    g_space                CONSTANT VARCHAR2(3 CHAR) := ' ';
    g_finalized_status_num CONSTANT VARCHAR2(25 CHAR) := 'FINALIZED_STATUS_TO_SHOW';

    FUNCTION get_advanced_directives
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_doc_area   IN doc_area.id_doc_area%TYPE,
        i_num_reg    IN NUMBER,
        o_advanced   OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_desc_pat_adv_dir VARCHAR2(200);
    
    BEGIN
    
        IF NOT pk_advanced_directives.get_adv_dir_desc(i_lang               => i_lang,
                                                       i_prof               => i_prof,
                                                       i_patient            => i_id_patient,
                                                       i_epis_documentation => NULL,
                                                       o_desc_pat_adv_dir   => l_desc_pat_adv_dir,
                                                       o_pat_adv_dir        => o_advanced,
                                                       o_error              => o_error)
        THEN
            RETURN FALSE;
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
                                              'GET_ADVANCED_DIRECTIVES',
                                              o_error);
            pk_types.open_my_cursor(o_advanced);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_advanced_directives;

    FUNCTION get_summary_grid_exam_pat
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_num_reg IN NUMBER,
        o_exam    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_showall NUMBER;
    
    BEGIN
    
        IF i_num_reg IS NULL
        THEN
        
            l_showall := 1;
        ELSE
            l_showall := 0;
        END IF;
    
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
    
        g_error := 'OPEN CURSOR O_EXAM';
        OPEN o_exam FOR
            SELECT *
              FROM (SELECT pk_date_utils.date_send_tsz(i_lang, nvl(eea.dt_begin, eea.dt_req), i_prof) dt,
                           decode(eea.flg_referral,
                                  'R',
                                  pk_sysdomain.get_rank(i_lang, 'EXAM_REQ_DET.FLG_REFERRAL', eea.flg_referral),
                                  'S',
                                  pk_sysdomain.get_rank(i_lang, 'EXAM_REQ_DET.FLG_REFERRAL', eea.flg_referral),
                                  'I',
                                  pk_sysdomain.get_rank(i_lang, 'EXAM_REQ_DET.FLG_REFERRAL', eea.flg_referral),
                                  pk_sysdomain.get_rank(i_lang, 'EXAM_REQ_DET.FLG_STATUS', eea.flg_status_det)) rank,
                           pk_exams_api_db.get_alias_translation(i_lang, i_prof, 'EXAM.CODE_EXAM.' || eea.id_exam, NULL) description,
                           eea.flg_status_det,
                           g_sysdate_char dt_server,
                           pk_access.get_shortcut(decode(eea.flg_type,
                                                         g_exam_type_img,
                                                         'EHR_IMAGING_EXAMS',
                                                         'GRID_OTH_EXAM')) ||
                           pk_utils.get_status_string(i_lang,
                                                      i_prof,
                                                      eea.status_str,
                                                      eea.status_msg,
                                                      eea.status_icon,
                                                      eea.status_flg) icon_name1,
                           NULL icon_name2,
                           NULL icon_name3
                      FROM exam_req er, exams_ea eea
                     WHERE eea.id_patient = i_patient
                       AND eea.flg_status_det != pk_alert_constant.g_cancelled
                       AND eea.flg_status_req != pk_alert_constant.g_cancelled
                       AND er.id_exam_req = eea.id_exam_req
                          -- exclude exams requested to the next episode and already assigned to the next episode
                       AND (er.id_episode_destination IS NULL OR
                           (er.id_episode_destination IS NOT NULL AND eea.flg_time = pk_alert_constant.g_flg_time_n))
                     ORDER BY rank, dt)
            
             WHERE (l_showall = 1 OR (rownum <= i_num_reg));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SUMMARY_GRID_EXAM_PAT',
                                              o_error);
            pk_types.open_my_cursor(o_exam);
            RETURN FALSE;
    END get_summary_grid_exam_pat;

    FUNCTION get_summary_grid_drug_pat
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_num_reg    IN NUMBER,
        o_drug       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_header_messages pk_types.cursor_type; -- dummy cursor to be passed in the "get_history_medication" function
    
    BEGIN
        IF i_patient IS NULL
        THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              pk_message.get_message(1, 'COMMON_M001') || chr(10) ||
                                              'Undefined patient.',
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SUMMARY_GRID_DRUG_PAT',
                                              o_error);
            RETURN FALSE;
        END IF;
    
        g_error := 'GET CURSOR O_DRUG';
        RETURN pk_api_pfh_clindoc_in.get_history_medication_dash(i_lang     => i_lang,
                                                                 i_prof     => i_prof,
                                                                 i_patient  => i_patient,
                                                                 i_episode  => i_id_episode,
                                                                 o_hist_med => o_drug,
                                                                 o_error    => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SUMMARY_GRID_DRUG_PAT',
                                              o_error);
            pk_types.open_my_cursor(o_drug);
            RETURN FALSE;
    END get_summary_grid_drug_pat;

    FUNCTION get_summary_grid_proc_pat
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_num_reg IN NUMBER,
        o_proc    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_showall          NUMBER;
        l_sr_time_margin   NUMBER;
        l_profile_template profile_template.id_profile_template%TYPE;
        l_na CONSTANT VARCHAR2(2 CHAR) := '--';
    
    BEGIN
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
    
        g_error            := 'GET prof_profile_template';
        l_profile_template := pk_prof_utils.get_prof_profile_template(i_prof);
    
        -- Obter prazo limite antes da cirurgia para terminar posicionamentos e reservas.
        g_error          := 'GET PROC TME LIMIT';
        l_sr_time_margin := to_number(nvl(pk_sysconfig.get_config('SR_TIME_MARGIN_POS', i_prof), 0));
        l_sr_time_margin := -l_sr_time_margin;
    
        IF i_num_reg IS NULL
        THEN
        
            l_showall := 1;
        ELSE
            l_showall := 0;
        END IF;
    
        g_error := 'OPEN CURSOR O_PROC';
        OPEN o_proc FOR
            SELECT *
              FROM (SELECT pk_sysdomain.get_rank(i_lang, 'INTERV_PRESC_DET.FLG_STATUS', pea.flg_status_det) rank,
                           pk_date_utils.date_send_tsz(i_lang, nvl(pea.dt_plan, pea.dt_begin_det), i_prof) dt_interv_prescription,
                           pk_procedures_api_db.get_alias_translation(i_lang, i_prof, i.code_intervention, NULL) || ' ' ||
                           --INTERVALO
                            '(' ||
                            nvl(pk_order_recurrence_api_db.get_order_recurr_plan_desc(i_lang,
                                                                                      i_prof,
                                                                                      ipd.id_order_recurrence),
                                pk_translation.get_translation(i_lang, 'ORDER_RECURR_OPTION.CODE_ORDER_RECURR_OPTION.0')) || ')' description,
                           pea.flg_status_det,
                           g_sysdate_char dt_server,
                           (SELECT pk_access.get_shortcut('EHR_PROCEDURES')
                              FROM dual) || pk_utils.get_status_string(i_lang,
                                                                       i_prof,
                                                                       pea.status_str,
                                                                       pea.status_msg,
                                                                       pea.status_icon,
                                                                       pea.status_flg) icon_name1,
                           NULL icon_name2,
                           NULL icon_name3
                      FROM procedures_ea pea, intervention i, interv_prescription ip, interv_presc_det ipd
                     WHERE pea.id_patient = i_patient
                       AND pea.id_interv_prescription = ip.id_interv_prescription
                       AND pea.id_intervention = i.id_intervention
                       AND (pea.flg_status_plan IS NULL OR
                           pea.flg_status_plan IN (pk_alert_constant.g_interv_plan_req,
                                                    pk_alert_constant.g_interv_plan_pend,
                                                    pk_alert_constant.g_interv_plan_admt,
                                                    pk_alert_constant.g_cancelled))
                       AND pea.flg_status_det NOT IN
                           (pk_alert_constant.g_cancelled,
                            pk_procedures_constant.g_interv_draft,
                            pk_procedures_constant.g_interv_expired,
                            pk_procedures_constant.g_interv_not_ordered)
                          -- exclude requests in previous episodes to future episodes
                       AND ((ip.id_episode_destination IS NULL OR
                           (ip.id_episode_destination IS NOT NULL AND pea.flg_time = pk_alert_constant.g_flg_time_n)) OR
                           (pea.flg_time IN (pk_procedures_constant.g_flg_time_a, pk_procedures_constant.g_flg_time_h) AND
                           (pea.flg_status_det IN (pk_procedures_constant.g_interv_req,
                                                     pk_procedures_constant.g_interv_pending,
                                                     pk_procedures_constant.g_interv_exec,
                                                     pk_procedures_constant.g_interv_sos))))
                          -- exclude procedures associated to a medication
                       AND pea.id_interv_presc_det = ipd.id_interv_presc_det
                       AND ipd.id_drug_presc_det IS NULL
                    UNION ALL
                    -- Ensinos de enfermagem
                    SELECT pk_sysdomain.get_rank(i_lang, 'NURSE_TEA_REQ.FLG_STATUS', ntr.flg_status) rank,
                           pk_date_utils.date_send_tsz(i_lang, nvl(ntr.dt_begin_tstz, ntr.dt_nurse_tea_req_tstz), i_prof) dt_interv_prescription,
                           pk_message.get_message(i_lang, 'SUMMARY_M009') || chr(13) ||
                           decode(ntr.id_nurse_tea_topic,
                                  1, --other
                                  nvl(ntr.desc_topic_aux,
                                      pk_translation.get_translation(i_lang,
                                                                     (SELECT ntt.code_nurse_tea_topic
                                                                        FROM nurse_tea_topic ntt
                                                                       WHERE ntt.id_nurse_tea_topic = ntr.id_nurse_tea_topic))),
                                  pk_translation.get_translation(i_lang,
                                                                 (SELECT ntt.code_nurse_tea_topic
                                                                    FROM nurse_tea_topic ntt
                                                                   WHERE ntt.id_nurse_tea_topic = ntr.id_nurse_tea_topic))) description,
                           ntr.flg_status flg_status,
                           g_sysdate_char dt_server,
                           --In the nutritionist profile the physician can't access the procedures deepnav
                            decode(i_prof.software,
                                   pk_alert_constant.g_soft_nutritionist,
                                   g_null_shortcut,
                                   g_shortcut_pat_education) ||
                            pk_utils.get_status_string(i_lang,
                                                       i_prof,
                                                       ntr.status_str,
                                                       ntr.status_msg,
                                                       ntr.status_icon,
                                                       ntr.status_flg) icon_name1,
                            NULL icon_name2,
                            NULL icon_name3
                       FROM nurse_tea_req ntr
                      WHERE ntr.flg_status NOT IN
                            (pk_patient_education_constant.g_nurse_tea_req_canc,
                             pk_patient_education_constant.g_nurse_tea_req_draft,
                             pk_patient_education_constant.g_nurse_tea_req_expired,
                             pk_patient_education_constant.g_nurse_tea_req_not_ord_reas)
                        AND ntr.id_patient = i_patient
                     UNION ALL
                     --Posicionamentos
                     SELECT decode(r.flg_status,
                                   g_flg_status_l,
                                   0,
                                   g_flg_status_f,
                                   1,
                                   g_flg_status_i,
                                   2,
                                   g_flg_status_t,
                                   3,
                                   g_flg_status_e,
                                   4,
                                   g_flg_status_r,
                                   10,
                                   -1) rank,
                            pk_date_utils.date_send_tsz(i_lang,
                                                        greatest(r.dt_posit_req_tstz, sr.dt_interv_preview_tstz),
                                                        i_prof) dt_interv_prescription,
                            pk_translation.get_translation(i_lang, p.code_sr_posit) description,
                            r.flg_status,
                            g_sysdate_char dt_server,
                            -- Estado da requisição: R - Requisitado, P - Executado, F- Executado e Verificado, C- Cancelado
                            --In the nutritionist profile the physician can't access the procedures deepnav
                           decode(i_prof.software,
                                  pk_alert_constant.g_soft_nutritionist,
                                  g_null_shortcut,
                                  sh.id_sys_shortcut) ||
                           decode(e.id_epis_type,
                                  4, --ORIS
                                  
                                  decode(r.flg_status,
                                         g_flg_status_r,
                                         
                                         decode(pk_date_utils.compare_dates_tsz(i_prof,
                                                                                current_timestamp,
                                                                                sr.dt_interv_preview_tstz),
                                                g_flg_time_g,
                                                pk_sr_clinical_info.get_string_task(i_lang,
                                                                                    i_prof,
                                                                                    pk_sr_clinical_info.g_flg_type_p,
                                                                                    sr.flg_status,
                                                                                    pk_alert_constant.g_flg_time_e,
                                                                                    sr.flg_status,
                                                                                    r.dt_posit_req_tstz,
                                                                                    r.dt_posit_req_tstz,
                                                                                    ''),
                                                pk_sr_clinical_info.get_string_task(i_lang,
                                                                                    i_prof,
                                                                                    pk_sr_clinical_info.g_flg_type_p,
                                                                                    sr.flg_status,
                                                                                    pk_alert_constant.g_flg_time_e,
                                                                                    sr.flg_status,
                                                                                    pk_date_utils.add_to_ltstz(sr.dt_interv_preview_tstz,
                                                                                                               l_sr_time_margin,
                                                                                                               'MINUTE'),
                                                                                    pk_date_utils.add_to_ltstz(sr.dt_interv_preview_tstz,
                                                                                                               l_sr_time_margin,
                                                                                                               'MINUTE'),
                                                                                    '')),
                                         pk_utils.get_status_string(i_lang,
                                                                    i_prof,
                                                                    '|I|||#|||||&',
                                                                    '',
                                                                    'SR_POSIT_DET.FLG_STATUS',
                                                                    r.flg_status)),
                                  -- Everything else
                                  decode(r.flg_status,
                                         g_flg_status_r,
                                         pk_utils.get_status_string(i_lang,
                                                                    i_prof,
                                                                    '|D|' ||
                                                                    pk_date_utils.to_char_insttimezone(i_prof,
                                                                                                       greatest(r.dt_posit_req_tstz,
                                                                                                                sr.dt_interv_preview_tstz),
                                                                                                       pk_alert_constant.g_dt_yyyymmddhh24miss_tzr) ||
                                                                    '|||' || pk_alert_constant.g_color_null || '||||&',
                                                                    '',
                                                                    '',
                                                                    ''),
                                         pk_utils.get_status_string(i_lang,
                                                                    i_prof,
                                                                    '|I|||#|||||&',
                                                                    '',
                                                                    'SR_POSIT_DET.FLG_STATUS',
                                                                    r.flg_status))) icon_name1,
                           NULL icon_name2,
                           NULL icon_name3
                      FROM sr_posit_req r, sr_posit p, sys_shortcut sh, sys_domain s, episode e, schedule_sr sr
                     WHERE e.id_patient = i_patient
                       AND r.id_episode = e.id_episode
                       AND r.id_sr_posit = p.id_sr_posit
                       AND r.flg_status != g_flg_status_c
                       AND sr.id_episode = e.id_episode
                       AND sh.intern_name(+) = 'SR_CLINICAL_INFO_SUMMARY_POSIT'
                       AND s.code_domain = 'SR_POSIT_DET.FLG_STATUS'
                       AND s.domain_owner = pk_sysdomain.k_default_schema
                       AND s.val = r.flg_status
                       AND s.id_language = i_lang
                       AND EXISTS (SELECT 1
                              FROM profile_templ_access pta, prof_profile_template ppt
                             WHERE pta.id_sys_shortcut = sh.id_sys_shortcut
                               AND pta.id_profile_template =
                                   (SELECT pt.id_parent
                                      FROM profile_template pt
                                     WHERE pt.id_profile_template = ppt.id_profile_template)
                               AND NOT EXISTS (SELECT 0
                                      FROM profile_templ_access p
                                     WHERE p.id_profile_template = ppt.id_profile_template
                                       AND p.id_sys_button_prop = sh.id_sys_button_prop
                                       AND p.flg_add_remove = pk_access.g_flg_type_remove)
                               AND pta.flg_add_remove = pk_access.g_flg_type_add
                               AND ppt.id_professional = i_prof.id
                               AND ppt.id_software = i_prof.software
                               AND ppt.id_institution = i_prof.institution
                            UNION ALL
                            SELECT 1
                              FROM profile_templ_access pta, prof_profile_template ppt
                             WHERE pta.id_sys_shortcut = sh.id_sys_shortcut
                               AND pta.id_profile_template = ppt.id_profile_template
                               AND pta.flg_add_remove = pk_access.g_flg_type_add
                               AND ppt.id_professional = i_prof.id
                               AND ppt.id_software = i_prof.software
                               AND ppt.id_institution = i_prof.institution)
                     ORDER BY rank, dt_interv_prescription)
             WHERE (l_showall = 1 OR (rownum <= i_num_reg));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SUMMARY_GRID_PROC_PAT',
                                              o_error);
            pk_types.open_my_cursor(o_proc);
            RETURN FALSE;
    END get_summary_grid_proc_pat;

    FUNCTION get_summary_grid_analy_pat
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_num_reg IN NUMBER,
        o_analy   OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_showall NUMBER;
    
    BEGIN
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
    
        IF i_num_reg IS NULL
        THEN
        
            l_showall := 1;
        ELSE
            l_showall := 0;
        END IF;
    
        OPEN o_analy FOR
        --com resultados, episodio actual
        
            SELECT *
              FROM (
                    -- Analysis with request 
                    SELECT DISTINCT lte.id_analysis_req_det,
                                     (SELECT pk_date_utils.date_send_tsz(i_lang, ar.dt_req_tstz, i_prof)
                                        FROM dual) dt_req,
                                     decode(lte.flg_referral,
                                            'R',
                                            (SELECT pk_sysdomain.get_rank(i_lang,
                                                                          'ANALYSIS_REQ_DET.FLG_REFERRAL',
                                                                          lte.flg_referral)
                                               FROM dual),
                                            'S',
                                            (SELECT pk_sysdomain.get_rank(i_lang,
                                                                          'ANALYSIS_REQ_DET.FLG_REFERRAL',
                                                                          lte.flg_referral)
                                               FROM dual),
                                            'I',
                                            (SELECT pk_sysdomain.get_rank(i_lang,
                                                                          'ANALYSIS_REQ_DET.FLG_REFERRAL',
                                                                          lte.flg_referral)
                                               FROM dual),
                                            decode(lte.flg_status_det,
                                                   g_flg_status_e,
                                                   (SELECT pk_sysdomain.get_rank(i_lang,
                                                                                 'HARVEST.FLG_STATUS',
                                                                                 lte.flg_status_harvest)
                                                      FROM dual),
                                                   (SELECT pk_sysdomain.get_rank(i_lang,
                                                                                 'ANALYSIS_REQ_DET.FLG_STATUS',
                                                                                 lte.flg_status_det)
                                                      FROM dual))) rank_status,
                                     (SELECT pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                                       i_prof,
                                                                                       'A',
                                                                                       'ANALYSIS.CODE_ANALYSIS.' ||
                                                                                       lte.id_analysis,
                                                                                       'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' ||
                                                                                       lte.id_sample_type,
                                                                                       NULL)
                                        FROM dual) description,
                                     lte.flg_status_det,
                                     g_sysdate_char dt_server,
                                     (SELECT pk_access.get_shortcut(decode(lte.flg_status_det,
                                                                           'X',
                                                                           'GRID_ANALYSIS',
                                                                           decode(ah.id_harvest,
                                                                                  NULL,
                                                                                  'GRID_HARVEST',
                                                                                  'GRID_ANALYSIS')))
                                        FROM dual) || (SELECT pk_utils.get_status_string(i_lang,
                                                                                         i_prof,
                                                                                         lte.status_str,
                                                                                         lte.status_msg,
                                                                                         lte.status_icon,
                                                                                         lte.status_flg)
                                                         FROM dual) icon_name1,
                                     NULL icon_name2,
                                     NULL icon_name3
                      FROM lab_tests_ea lte, analysis_req ar, analysis_req_par arp, analysis_harvest ah
                     WHERE lte.id_patient = i_patient
                       AND lte.id_analysis_req = ar.id_analysis_req
                       AND arp.id_analysis_req_det(+) = lte.id_analysis_req_det --RS added outer join 
                       AND ah.id_analysis_req_det(+) = lte.id_analysis_req_det
                       AND ah.flg_status(+) = pk_lab_tests_constant.g_active
                       AND lte.flg_status_det(+) != pk_alert_constant.g_cancelled
                       AND (SELECT pk_lab_tests_api_db.get_lab_test_access_permission(i_lang, i_prof, lte.id_analysis)
                              FROM dual) = pk_alert_constant.g_yes
                          -- 20080923 - GS - Desnormalização DROP à tabela ANALYSIS_REQ_TEMP 
                          -- exclude analysis requested to the next episode and already created in the next episode 
                       AND (ar.id_episode_destination IS NULL OR
                           (ar.id_episode_destination IS NOT NULL AND
                           (lte.flg_status_det = g_flg_status_r OR
                           (ar.id_episode_origin IS NULL AND lte.flg_status_det = g_flg_status_d AND
                           lte.flg_time_harvest != pk_alert_constant.g_flg_time_n))) OR
                           (ar.id_episode_destination IS NOT NULL AND
                           lte.flg_time_harvest = pk_alert_constant.g_flg_time_n))
                    UNION ALL
                    -- Results without request (observações periódicas e histórico de análises) 
                    SELECT DISTINCT ares.id_analysis_result,
                                     (SELECT pk_date_utils.date_send_tsz(i_lang, aresp.dt_analysis_result_par_tstz, i_prof)
                                        FROM dual) dt_req,
                                     (SELECT pk_sysdomain.get_rank(i_lang,
                                                                   'ANALYSIS_REQ_DET.FLG_STATUS',
                                                                   pk_edis_summary.g_flg_status_l)
                                        FROM dual) rank_status,
                                     (SELECT pk_translation.get_translation(i_lang,
                                                                            'ANALYSIS_PARAMETER.CODE_ANALYSIS_PARAMETER.' ||
                                                                            aresp.id_analysis_parameter)
                                        FROM dual) description,
                                     pk_edis_summary.g_flg_status_l,
                                     g_sysdate_char dt_server,
                                     (SELECT pk_utils.get_status_string_immediate(i_lang,
                                                                                  i_prof,
                                                                                  pk_alert_constant.g_display_type_icon,
                                                                                  g_flg_status_l,
                                                                                  NULL,
                                                                                  NULL,
                                                                                  'ANALYSIS_REQ_DET.FLG_STATUS',
                                                                                  pk_access.get_shortcut('GRID_ANALYSIS'),
                                                                                  NULL,
                                                                                  pk_alert_constant.g_color_icon_dark_grey)
                                        FROM dual) status_icon_name,
                                     NULL icon_name2,
                                     NULL icon_name3
                      FROM analysis_result ares, analysis_result_par aresp, episode e
                     WHERE ares.id_patient = i_patient
                          -- results without request 
                       AND ares.id_analysis_req_det IS NULL
                       AND aresp.id_analysis_result = ares.id_analysis_result
                       AND ares.id_episode_orig = e.id_episode
                       AND (SELECT pk_lab_tests_api_db.get_lab_test_access_permission(i_lang, i_prof, ares.id_analysis)
                              FROM dual) = pk_alert_constant.g_yes
                     ORDER BY rank_status, dt_req, description)
             WHERE (l_showall = 1 OR (rownum <= i_num_reg))
             ORDER BY rank_status, dt_req, description;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SUMMARY_GRID_ANALY_PAT',
                                              o_error);
            pk_types.open_my_cursor(o_analy);
            RETURN FALSE;
    END get_summary_grid_analy_pat;

    FUNCTION get_summary_grid_pat
    (
        i_lang       IN language.id_language%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_num_reg    IN NUMBER,
        o_drug       OUT pk_types.cursor_type,
        o_analy      OUT pk_types.cursor_type,
        o_proc       OUT pk_types.cursor_type,
        o_exam       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_screens   table_varchar;
        l_scr_alias table_varchar := table_varchar('LIST_IVFLUIDS',
                                                   'EHR_MEDICATION',
                                                   'GRID_OTH_EXAM',
                                                   'EHR_IMAGING_EXAMS',
                                                   'GRID_ANALYSIS',
                                                   'GRID_HARVEST',
                                                   'EHR_PROCEDURES',
                                                   'LIST_NURSE_TEACH');
    
    BEGIN
    
        IF i_prof.software = pk_alert_constant.g_soft_oris
        THEN
            l_screens := table_varchar('SR_CLINICAL_INFO_SUMMARY_DRUG_PRESC', --LIST_IVFLUIDS
                                       'SR_CLINICAL_INFO_SUMMARY_DRUG_PRESC', --LIST_DRUG
                                       'GRID_OTH_EXAM', --GRID_OTH_EXAM
                                       'EHR_IMAGING_EXAMS', --GRID_IMAGE
                                       'GRID_ANALYSIS', --GRID_ANALYSIS
                                       'GRID_HARVEST', --GRID_HARVEST
                                       'SR_CLINICAL_INFO_SUMMARY_INTERV_PRESC', --LIST_PROC
                                       'GRID_PAT_EDUCATION' --LIST_NURSE_TEACH
                                       );
        ELSIF i_prof.software IN (pk_alert_constant.g_soft_outpatient, pk_alert_constant.g_soft_private_practice)
        THEN
            l_screens := table_varchar('IVFLUIDS_LIST', --LIST_IVFLUIDS
                                       'EHR_MEDICATION', --LIST_DRUG
                                       'GRID_OTH_EXAM', --GRID_OTH_EXAM
                                       'EHR_IMAGING_EXAMS', --GRID_IMAGE
                                       'GRID_ANALYSIS', --GRID_ANALYSIS
                                       'GRID_HARVEST', --GRID_HARVEST
                                       'EHR_PROCEDURES', --LIST_PROC
                                       'GRID_PAT_EDUCATION' --LIST_NURSE_TEACH
                                       );
        ELSE
            l_screens := table_varchar('IVFLUIDS_LIST', --LIST_IVFLUIDS
                                       'EHR_MEDICATION', --LIST_DRUG
                                       'GRID_OTH_EXAM', --GRID_OTH_EXAM
                                       'EHR_IMAGING_EXAMS', --GRID_IMAGE
                                       'GRID_ANALYSIS', --GRID_ANALYSIS
                                       'GRID_HARVEST', --GRID_HARVEST
                                       'EHR_PROCEDURES', --LIST_PROC
                                       'GRID_PAT_EDUCATION' --LIST_NURSE_TEACH
                                       );
        END IF;
    
        g_error := 'CALL PK_ACCESS.GET_SHORTCUTS_ARRAY';
        IF NOT pk_access.preload_shortcuts(i_lang      => i_lang,
                                           i_prof      => i_prof,
                                           i_screens   => l_screens,
                                           i_scr_alias => l_scr_alias,
                                           o_error     => o_error)
        THEN
            g_error := o_error.ora_sqlerrm;
        END IF;
    
        g_error := 'CALL PK_PATIENT_SUMMARY.GET_SUMMARY_GRID_DRUG_PAT';
        IF NOT pk_patient_summary.get_summary_grid_drug_pat(i_lang       => i_lang,
                                                            i_prof       => i_prof,
                                                            i_patient    => i_id_patient,
                                                            i_id_episode => i_id_episode,
                                                            i_num_reg    => i_num_reg,
                                                            o_drug       => o_drug,
                                                            o_error      => o_error)
        THEN
            g_error := o_error.ora_sqlerrm;
        END IF;
    
        g_error := 'CALL PK_PATIENT_SUMMARY.GET_SUMMARY_GRID_EXAM_PAT';
        IF NOT pk_patient_summary.get_summary_grid_exam_pat(i_lang    => i_lang,
                                                            i_prof    => i_prof,
                                                            i_patient => i_id_patient,
                                                            i_num_reg => i_num_reg,
                                                            o_exam    => o_exam,
                                                            o_error   => o_error)
        THEN
            g_error := o_error.ora_sqlerrm;
        END IF;
    
        g_error := 'CALLPK PK_PATIENT_SUMMARY.GET_SUMMARY_GRID_ANALY_PAT';
        IF NOT pk_patient_summary.get_summary_grid_analy_pat(i_lang    => i_lang,
                                                             i_prof    => i_prof,
                                                             i_patient => i_id_patient,
                                                             i_num_reg => i_num_reg,
                                                             o_analy   => o_analy,
                                                             o_error   => o_error)
        THEN
            g_error := o_error.ora_sqlerrm;
        END IF;
    
        g_error := 'CALL PK_PATIENT_SUMMARY.GET_SUMMARY_GRID_PROC_PAT';
        IF NOT pk_patient_summary.get_summary_grid_proc_pat(i_lang    => i_lang,
                                                            i_prof    => i_prof,
                                                            i_patient => i_id_patient,
                                                            i_num_reg => i_num_reg,
                                                            o_proc    => o_proc,
                                                            o_error   => o_error)
        THEN
            g_error := o_error.ora_sqlerrm;
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
                                              'GET_SUMMARY_GRID_PAT',
                                              o_error);
            IF NOT o_drug%ISOPEN
            THEN
                pk_types.open_my_cursor(o_drug);
            END IF;
            IF NOT o_analy%ISOPEN
            THEN
                pk_types.open_my_cursor(o_analy);
            END IF;
            IF NOT o_proc%ISOPEN
            THEN
                pk_types.open_my_cursor(o_proc);
            END IF;
            IF NOT o_exam%ISOPEN
            THEN
                pk_types.open_my_cursor(o_exam);
            END IF;
        
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_summary_grid_pat;

    FUNCTION get_previous_visits
    (
        i_lang       IN language.id_language%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        i_prof       IN profissional,
        i_num_reg    IN NUMBER,
        o_with_me    OUT pk_types.cursor_type,
        o_all        OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_showall       NUMBER;
        l_prof_cat      category.flg_type%TYPE;
        l_hand_off_type sys_config.value%TYPE;
    
    BEGIN
    
        g_error := 'GET CONFIGURATIONS';
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
        l_prof_cat := pk_prof_utils.get_category(i_lang, i_prof);
    
        IF i_num_reg IS NULL
        THEN
            l_showall := 1;
        ELSE
            l_showall := 0;
        END IF;
    
        g_error := 'GET CURSOR O_WITH_ME';
        OPEN o_with_me FOR
            SELECT description, pk_date_utils.date_send_tsz(i_lang, dt_begin_tstz, i_prof) dt_begin
              FROM (SELECT pk_translation.get_translation(i_lang,
                                                          decode(nvl(ei.id_dcs_requested, -1),
                                                                 -1,
                                                                 decode(nvl(ei.id_dep_clin_serv, -1),
                                                                        -1,
                                                                        'EPIS_TYPE.CODE_EPIS_TYPE.' || e.id_epis_type,
                                                                        'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' ||
                                                                        e.id_clinical_service),
                                                                 'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' ||
                                                                 e.id_cs_requested)) description,
                           e.dt_begin_tstz
                      FROM episode e, epis_info ei
                     WHERE e.id_patient = i_id_patient
                       AND i_prof.id IN
                           (SELECT column_value
                              FROM TABLE(pk_hand_off_core.get_responsibles_id(i_lang,
                                                                              i_prof,
                                                                              e.id_episode,
                                                                              l_prof_cat,
                                                                              l_hand_off_type)))
                       AND e.flg_status = pk_alert_constant.g_epis_status_inactive
                       AND e.flg_ehr = pk_ehr_access.g_flg_ehr_normal
                       AND e.id_episode = ei.id_episode
                     ORDER BY dt_begin_tstz DESC)
             WHERE (l_showall = 1 OR (rownum <= i_num_reg));
    
        OPEN o_all FOR
            SELECT description, pk_date_utils.date_send_tsz(i_lang, dt_begin_tstz, i_prof) dt_begin
              FROM (SELECT pk_translation.get_translation(i_lang,
                                                          decode(nvl(ei.id_dcs_requested, -1),
                                                                 -1,
                                                                 decode(nvl(ei.id_dep_clin_serv, -1),
                                                                        -1,
                                                                        'EPIS_TYPE.CODE_EPIS_TYPE.' || e.id_epis_type,
                                                                        'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' ||
                                                                        e.id_clinical_service),
                                                                 'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' ||
                                                                 e.id_cs_requested)) description,
                           e.dt_begin_tstz
                      FROM episode e, epis_info ei
                     WHERE e.id_patient = i_id_patient
                       AND e.flg_status = pk_alert_constant.g_epis_status_inactive
                       AND e.flg_ehr = pk_ehr_access.g_flg_ehr_normal
                       AND e.id_epis_type NOT IN
                           (pk_alert_constant.g_epis_type_operating, pk_alert_constant.g_hhc_epis_type)
                       AND ei.id_episode = e.id_episode
                    UNION ALL
                    SELECT pk_procedures_utils.get_alias_translation(i_lang,
                                                                     i_prof,
                                                                     'INTERVENTION.CODE_INTERVENTION.' ||
                                                                     sei.id_sr_intervention,
                                                                     NULL) description,
                           e.dt_begin_tstz
                      FROM episode e, sr_epis_interv sei
                     WHERE e.id_patient = i_id_patient
                       AND e.flg_status = pk_alert_constant.g_epis_status_inactive
                       AND e.flg_ehr = pk_ehr_access.g_flg_ehr_normal
                       AND e.id_epis_type = pk_alert_constant.g_epis_type_operating
                       AND e.id_episode = sei.id_episode_context
                     ORDER BY dt_begin_tstz DESC)
             WHERE (l_showall = 1 OR (rownum <= i_num_reg));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PREVIOUS_VISITS',
                                              o_error);
            pk_types.open_my_cursor(o_with_me);
            pk_types.open_my_cursor(o_all);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_previous_visits;

    FUNCTION get_previous_visits
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_num_reg    IN NUMBER,
        o_visit_list OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cursor pk_types.cursor_type;
    
    BEGIN
    
        g_error := 'CALL PK_PATIENT_SUMMARY.GET_PREVIOUS_VISITS';
        IF NOT pk_patient_summary.get_previous_visits(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_id_patient => i_id_patient,
                                                      i_num_reg    => i_num_reg,
                                                      o_with_me    => l_cursor,
                                                      o_all        => o_visit_list,
                                                      o_error      => o_error)
        THEN
            RAISE g_exception;
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
                                              'GET_PREVIOUS_VISITS',
                                              o_error);
            pk_types.open_my_cursor(o_visit_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_previous_visits;

    FUNCTION get_care_plans
    (
        i_lang       IN language.id_language%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        i_prof       IN profissional,
        i_num_reg    IN NUMBER,
        o_care_plans OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        b_result BOOLEAN;
        e_update_guide_prots EXCEPTION;
    
    BEGIN
        g_error := 'UPDATE GUIDELINES';
    
        -- verify if any guideline should be automatically recommended to the patient
        b_result := pk_guidelines.run_batch(i_lang, i_prof, i_id_patient, NULL, NULL, o_error);
    
        IF (NOT b_result)
        THEN
            RAISE e_update_guide_prots;
        END IF;
    
        COMMIT;
    
        g_error := 'UPDATE PROTOCOLS';
    
        -- verify if any guideline should be automatically recommended to the patient
        b_result := pk_protocol.run_batch(i_lang, i_prof, i_id_patient, NULL, NULL, o_error);
    
        IF (NOT b_result)
        THEN
            RAISE e_update_guide_prots;
        END IF;
    
        COMMIT;
    
        g_error := 'GET CURSOR O_CARE_PLANS';
        OPEN o_care_plans FOR
            SELECT description, status, shortcut
              FROM (
                    -- guidelines
                    SELECT guid.guideline_desc AS description,
                            '0' || '|' || pk_date_utils.date_send_tsz(i_lang, dt_status, i_prof) --'xxxxxxxxxxxxxx'
                            || '|' || decode(gp.flg_status,
                                             pk_guidelines.g_process_finished,
                                             pk_guidelines.g_text_icon,
                                             pk_guidelines.g_icon) || '|' ||
                            decode(pk_sysdomain.get_img(i_lang, pk_guidelines.g_domain_flg_guideline, gp.flg_status),
                                   pk_guidelines.g_alert_icon,
                                   decode(gp.flg_status,
                                          pk_guidelines.g_process_scheduled,
                                          pk_guidelines.g_green_color,
                                          pk_guidelines.g_red_color),
                                   pk_guidelines.g_waiting_icon,
                                   pk_guidelines.g_red_color,
                                   NULL) || '|' ||
                            pk_sysdomain.get_img(i_lang, pk_guidelines.g_domain_flg_guideline, gp.flg_status) || '|' ||
                            pk_date_utils.dt_chr_year_short_tsz(i_lang, dt_status, i_prof) AS status,
                            decode(i_prof.software,
                                   pk_alert_constant.g_soft_social,
                                   g_null_shortcut,
                                   pk_alert_constant.g_soft_nutritionist,
                                   g_null_shortcut,
                                   656) shortcut,
                            dt_status dt
                      FROM guideline guid, guideline_process gp
                     WHERE guid.id_institution = i_prof.institution
                       AND guid.id_guideline = gp.id_guideline
                       AND gp.id_patient = i_id_patient
                       AND gp.flg_status != pk_guidelines.g_process_canceled
                       AND gp.flg_status != pk_guidelines.g_process_closed
                    UNION ALL
                    -- protocols
                    SELECT g.protocol_desc AS protocol_title,
                            '0' || '|' || pk_date_utils.date_send_tsz(i_lang, dt_status, i_prof) --'xxxxxxxxxxxxxx'
                            || '|' || decode(gp.flg_status,
                                             pk_protocol.g_process_finished,
                                             pk_protocol.g_text_icon,
                                             pk_protocol.g_icon) || '|' ||
                            decode(pk_sysdomain.get_img(i_lang, pk_protocol.g_domain_flg_protocol, gp.flg_status),
                                   pk_protocol.g_alert_icon,
                                   decode(gp.flg_status,
                                          pk_protocol.g_process_scheduled,
                                          pk_protocol.g_green_color,
                                          pk_protocol.g_red_color),
                                   pk_protocol.g_waiting_icon,
                                   pk_protocol.g_red_color,
                                   NULL) || '|' ||
                            pk_sysdomain.get_img(i_lang, pk_protocol.g_domain_flg_protocol, gp.flg_status) || '|' ||
                            pk_date_utils.dt_chr_year_short_tsz(i_lang, dt_status, i_prof) AS status,
                            decode(i_prof.software,
                                   pk_alert_constant.g_soft_social,
                                   g_null_shortcut,
                                   pk_alert_constant.g_soft_nutritionist,
                                   g_null_shortcut,
                                   1600) shortcut,
                            dt_status dt
                      FROM protocol g, protocol_process gp
                     WHERE g.id_institution = i_prof.institution
                       AND g.id_protocol = gp.id_protocol
                       AND gp.id_patient = i_id_patient
                       AND gp.flg_nested_protocol = pk_protocol.g_not_nested_protocol
                       AND gp.flg_status != pk_protocol.g_process_canceled
                       AND gp.flg_status != pk_protocol.g_process_closed
                    UNION ALL
                    -- care plans
                    SELECT cp.name, cp.str_status status_icon, 1616 shortcut, cp.dt_begin dt
                      FROM care_plan cp
                     WHERE cp.id_patient = i_id_patient
                       AND cp.flg_status IN ('P', 'E', 'S')
                     ORDER BY dt DESC)
             WHERE rownum <= nvl(i_num_reg, rownum);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CARE_PLANS',
                                              o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_care_plans);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_care_plans;

    FUNCTION get_patient_problems
    (
        i_lang         IN language.id_language%TYPE,
        i_id_patient   IN patient.id_patient%TYPE,
        i_prof         IN profissional,
        i_num_reg      IN NUMBER,
        i_flg_show_ph  IN VARCHAR2 DEFAULT NULL,
        o_pat_problems OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        --Number of records to show
        l_showall NUMBER;
    
        --Messages
        l_message_problems_m001 sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'PROBLEMS_M001');
        l_message_problems_m004 sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'PROBLEMS_M004');
        l_message_problems_m006 sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'PROBLEMS_M006');
        l_message_problems_m007 sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'PROBLEMS_M007');
        l_message_problems_m008 sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'PROBLEMS_M008');
    
        --Problems screen shortcut
        l_problems_shortcut NUMBER := 609;
    
        l_show_allergy         sys_config.value%TYPE := pk_sysconfig.get_config('SHOW_ALLERGY_IN_PROBLEM', i_prof);
        l_show_habit           sys_config.value%TYPE := pk_sysconfig.get_config('SHOW_HABIT_IN_PROBLEM', i_prof);
        l_sys_config_show_diag sys_config.id_sys_config%TYPE := pk_sysconfig.get_config(pk_alert_constant.g_diag_area_sys_config,
                                                                                        i_prof);
    
        l_sc_show_surgical sys_config.id_sys_config%TYPE := pk_sysconfig.get_config(pk_alert_constant.g_problems_show_surgical_hist,
                                                                                    i_prof);
    BEGIN
    
        IF i_num_reg IS NULL
        THEN
            l_showall := 1;
        ELSE
            l_showall := 0;
        END IF;
    
        g_error := 'GET CURSOR O_PAT_ALLERGIES';
        OPEN o_pat_problems FOR
        
            SELECT description, desc_status, shortcut, rank_type, dt_order, flg_source
              FROM (SELECT description, desc_status, shortcut, rank_type, dt_order, flg_source
                      FROM (
                            -------------------
                            -- Problems and relevant deceases
                            -------------------
                            SELECT decode(phd.id_alert_diagnosis,
                                           NULL,
                                           phd.desc_pat_history_diagnosis,
                                           decode(phd.desc_pat_history_diagnosis,
                                                  NULL,
                                                  '',
                                                  phd.desc_pat_history_diagnosis || ' - ') ||
                                           pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                      i_prof               => i_prof,
                                                                      i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                                      i_id_diagnosis       => d.id_diagnosis,
                                                                      i_id_task_type       => pk_problems.get_flg_area_task_type(i_flg_area => phd.flg_area,
                                                                                                                                 i_flg_type => phd.flg_type),
                                                                      i_code               => d.code_icd,
                                                                      i_flg_other          => d.flg_other,
                                                                      i_flg_std_diag       => ad.flg_icd9)) description,
                                    pk_problems.get_problem_type_desc(i_lang               => i_lang,
                                                                      i_prof               => i_prof,
                                                                      i_flg_area           => phd.flg_area,
                                                                      i_id_alert_diagnosis => phd.id_alert_diagnosis,
                                                                      i_flg_type           => phd.flg_type) || ' - ' ||
                                    pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS', phd.flg_status, i_lang) desc_status,
                                    l_problems_shortcut shortcut,
                                    pk_sysdomain.get_rank(i_lang, 'PAT_PROBLEM.FLG_STATUS', phd.flg_status) rank_type,
                                    pk_date_utils.date_send_tsz(i_lang, phd.dt_pat_history_diagnosis_tstz, i_prof) dt_order,
                                    decode(nvl(phd.flg_area, 'P'),
                                           'H',
                                           decode(phd.flg_type, 'S', 'PS', 'PM'),
                                           'S',
                                           'PS',
                                           phd.flg_area) flg_source,
                                    row_number() over(ORDER BY phd.dt_pat_history_diagnosis_tstz DESC) rn
                              FROM pat_history_diagnosis phd, alert_diagnosis ad, diagnosis d
                             WHERE phd.id_pat_history_diagnosis =
                                   pk_problems.get_most_recent_phd_id(phd.id_pat_history_diagnosis)
                               AND phd.id_patient = i_id_patient
                               AND (phd.id_alert_diagnosis IS NOT NULL OR phd.desc_pat_history_diagnosis IS NOT NULL OR
                                   (d.flg_other = 'Y'))
                               AND (phd.flg_status <> pk_problems.g_pat_probl_cancel OR phd.flg_status IS NULL)
                               AND phd.id_alert_diagnosis = ad.id_alert_diagnosis(+)
                               AND phd.id_diagnosis = d.id_diagnosis(+)
                               AND ((l_sys_config_show_diag LIKE pk_alert_constant.g_diag_area_config_show_all) OR
                                   (l_sys_config_show_diag LIKE pk_alert_constant.g_diag_area_config_show_own AND
                                   phd.flg_area IN
                                   (pk_alert_constant.g_diag_area_problems, pk_alert_constant.g_diag_area_not_defined)) OR
                                   i_flg_show_ph = pk_alert_constant.g_yes)
                               AND phd.id_pat_history_diagnosis_new IS NULL
                               AND (l_sc_show_surgical = pk_alert_constant.g_yes OR
                                   phd.flg_area <> pk_alert_constant.g_diag_area_surgical_hist OR
                                   i_flg_show_ph = pk_alert_constant.g_yes)
                            UNION ALL
                            -------------------
                            -- Diagnosis and habits
                            -------------------
                            SELECT decode(pp.desc_pat_problem,
                                           '',
                                           decode(pp.id_habit,
                                                  '',
                                                  decode(nvl(ed.id_epis_diagnosis, 0),
                                                         0,
                                                         pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                                    i_prof               => i_prof,
                                                                                    i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                                                    i_id_diagnosis       => d.id_diagnosis,
                                                                                    i_code               => d.code_icd,
                                                                                    i_flg_other          => d.flg_other,
                                                                                    i_flg_std_diag       => ad.flg_icd9),
                                                         pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                                                    i_prof                => i_prof,
                                                                                    i_id_alert_diagnosis  => ad1.id_alert_diagnosis,
                                                                                    i_id_diagnosis        => d1.id_diagnosis,
                                                                                    i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                                                                    i_code                => d1.code_icd,
                                                                                    i_flg_other           => d1.flg_other,
                                                                                    i_flg_std_diag        => ad1.flg_icd9,
                                                                                    i_epis_diag           => ed.id_epis_diagnosis)),
                                                  pk_translation.get_translation(i_lang, h.code_habit)),
                                           pp.desc_pat_problem) description,
                                    decode(pp.desc_pat_problem,
                                           '',
                                           decode(pp.id_habit,
                                                  '',
                                                  decode(nvl(ed.id_epis_diagnosis, 0),
                                                         0,
                                                         l_message_problems_m004,
                                                         decode(ed.flg_type,
                                                                pk_problems.g_epis_diag_passive,
                                                                l_message_problems_m008,
                                                                l_message_problems_m007)),
                                                  l_message_problems_m006),
                                           decode(pp.id_diagnosis, NULL, l_message_problems_m001, l_message_problems_m004)) ||
                                    ' - ' ||
                                    decode(nvl(ed.id_epis_diagnosis, 0),
                                           0,
                                           pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS', pp.flg_status, i_lang),
                                           decode(ed.flg_status,
                                                  'C',
                                                  pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS', ed.flg_status, i_lang),
                                                  pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS', pp.flg_status, i_lang))) desc_status,
                                    l_problems_shortcut shortcut,
                                    pk_sysdomain.get_rank(i_lang,
                                                          'PAT_PROBLEM.FLG_STATUS',
                                                          decode(nvl(ed.id_epis_diagnosis, 0),
                                                                 0,
                                                                 pp.flg_status,
                                                                 decode(ed.flg_status, 'C', ed.flg_status, pp.flg_status))) rank_type,
                                    pk_date_utils.date_send_tsz(i_lang, pp.dt_pat_problem_tstz, i_prof) dt_order,
                                    decode(pp.desc_pat_problem,
                                           '',
                                           decode(pp.id_habit, '', decode(nvl(ed.id_epis_diagnosis, 0), 0, 'RD', 'D'), 'H'),
                                           decode(pp.id_diagnosis, NULL, 'PP', 'RD')) flg_source,
                                    row_number() over(ORDER BY pp.dt_pat_problem_tstz DESC) rn
                              FROM pat_problem     pp,
                                    diagnosis       d,
                                    professional    p,
                                    epis_diagnosis  ed,
                                    diagnosis       d1,
                                    habit           h,
                                    alert_diagnosis ad,
                                    alert_diagnosis ad1
                             WHERE pp.id_patient = i_id_patient
                               AND pp.id_diagnosis = d.id_diagnosis(+)
                               AND pp.id_alert_diagnosis = ad.id_alert_diagnosis(+)
                               AND pp.id_professional_ins = p.id_professional(+)
                               AND ed.id_epis_diagnosis(+) = pp.id_epis_diagnosis
                               AND d1.id_diagnosis(+) = ed.id_diagnosis
                               AND ad1.id_alert_diagnosis(+) = ed.id_alert_diagnosis
                               AND pp.id_habit = h.id_habit(+)
                               AND pp.flg_status NOT IN (pk_problems.g_pat_probl_cancel, pk_problems.g_pat_probl_invest)
                               AND (pp.id_habit = h.id_habit OR ed.id_epis_diagnosis = pp.id_epis_diagnosis)
                               AND ( --final diagnosis 
                                    (ed.flg_type = pk_diagnosis.g_diag_type_d) --                             
                                    OR -- differencial diagnosis only 
                                    (ed.flg_type = pk_diagnosis.g_diag_type_p AND
                                    ed.id_diagnosis NOT IN
                                    (SELECT ed3.id_diagnosis
                                        FROM epis_diagnosis ed3
                                       WHERE ed3.id_diagnosis = ed.id_diagnosis
                                         AND ed3.id_patient = pp.id_patient
                                         AND ed3.flg_type = pk_diagnosis.g_diag_type_d)) --
                                    OR -- não é um diagnóstico
                                    (pp.id_habit IS NOT NULL))
                               AND pp.flg_status <> pk_problems.g_pat_probl_invest
                            UNION ALL
                            -------------------
                            -- Alergies
                            -------------------
                            SELECT nvl2(pa.id_allergy,
                                         pk_translation.get_translation(i_lang, a.code_allergy),
                                         pa.desc_allergy) description, -- TB
                                    pk_sysdomain.get_domain('PAT_ALLERGY.FLG_TYPE', pa.flg_type, i_lang) || ' - ' ||
                                    pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS', pa.flg_status, i_lang) desc_status,
                                    l_problems_shortcut shortcut,
                                    pk_sysdomain.get_rank(i_lang, 'PAT_PROBLEM.FLG_STATUS', pa.flg_status) rank_type,
                                    pk_date_utils.date_send_tsz(i_lang, pa.dt_pat_allergy_tstz, i_prof) dt_order,
                                    'A' flg_source,
                                    row_number() over(ORDER BY pa.dt_pat_allergy_tstz DESC) rn
                              FROM pat_allergy pa, allergy a
                             WHERE pa.id_patient = i_id_patient
                               AND a.id_allergy(+) = pa.id_allergy -- TB
                               AND pa.flg_status <> pk_problems.g_pat_probl_cancel
                             ORDER BY rank_type, dt_order DESC)
                     WHERE (l_showall = 1 OR (rn <= i_num_reg))) t
             WHERE t.flg_source IN ('RD', 'PP', 'PM', 'PS', 'P')
                OR (t.flg_source = 'A' AND l_show_allergy = pk_alert_constant.g_yes)
                OR (t.flg_source = 'H' AND l_show_habit = pk_alert_constant.g_yes)
                OR (t.flg_source IN (pk_problems.g_problem_type_diag));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PATIENT_PROBLEMS',
                                              o_error);
            pk_types.open_my_cursor(o_pat_problems);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_patient_problems;

    FUNCTION get_care_dash_problems
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        o_problems OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_allergy VARCHAR2(100);
        l_habit   VARCHAR2(100);
    
        l_desc_status_01 VARCHAR2(200) := pk_message.get_message(i_lang, 'CARE_DASHBOARD_M001');
        l_desc_status_03 VARCHAR2(200) := pk_message.get_message(i_lang, 'PREV_EPISODE_T534');
    
        l_show_allergy         sys_config.value%TYPE := pk_sysconfig.get_config('SHOW_ALLERGY_IN_PROBLEM', i_prof);
        l_show_habit           sys_config.value%TYPE := pk_sysconfig.get_config('SHOW_HABIT_IN_PROBLEM', i_prof);
        l_sys_config_show_diag sys_config.id_sys_config%TYPE := pk_sysconfig.get_config(pk_alert_constant.g_diag_area_sys_config,
                                                                                        i_prof);
        l_sc_show_surgical     sys_config.id_sys_config%TYPE := pk_sysconfig.get_config(pk_alert_constant.g_problems_show_surgical_hist,
                                                                                        i_prof);
        l_problems_m007        sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'PROBLEMS_M007');
    
    BEGIN
    
        l_allergy := pk_message.get_message(i_lang, i_prof, 'ALLERGY_LIST_T008');
        l_habit   := pk_message.get_message(i_lang, i_prof, 'PATIENT_HABITS_T001');
    
        g_error := 'GET CURSOR O_PAT_ALLERGIES';
        OPEN o_problems FOR
            SELECT DISTINCT description, desc_status, flg_problem, shortcut
              FROM (
                    --allergies
                    SELECT DISTINCT decode(a.id_allergy,
                                            NULL,
                                            pa.desc_allergy,
                                            pk_translation.get_translation(i_lang, a.code_allergy)) description,
                                     pk_string_utils.concat_if_exists(l_allergy,
                                                                      decode(pa.year_begin,
                                                                             NULL,
                                                                             NULL,
                                                                             pk_message.get_message(i_lang, 'DASHBOARD_M001') || ' ' ||
                                                                             pa.year_begin),
                                                                      ' - ') status,
                                     l_desc_status_01 desc_status,
                                     pa.dt_pat_allergy_tstz dt,
                                     'Y' flg_problem,
                                     1 shortcut,
                                     'A' flg_source
                      FROM pat_allergy pa, allergy a
                     WHERE pa.id_allergy = a.id_allergy(+)
                       AND pa.flg_status <> 'C'
                       AND pa.id_patient = i_patient
                    UNION ALL
                    -- habits
                    SELECT DISTINCT pk_translation.get_translation(i_lang, h.code_habit) description,
                                     pk_string_utils.concat_if_exists(l_habit,
                                                                      decode(pp.year_begin,
                                                                             NULL,
                                                                             NULL,
                                                                             pk_message.get_message(i_lang, 'DASHBOARD_M001') || ' ' ||
                                                                             pp.year_begin),
                                                                      ' - ') status,
                                     l_desc_status_01 desc_status,
                                     pp.dt_pat_problem_tstz dt,
                                     'Y' flg_problem,
                                     166 shortcut,
                                     'H' flg_source
                      FROM pat_problem pp, habit h
                     WHERE pp.id_habit = h.id_habit
                       AND pp.flg_status <> 'C'
                       AND pp.id_patient = i_patient
                    UNION ALL
                    -- problems
                    SELECT DISTINCT decode(phd.id_alert_diagnosis,
                                            NULL,
                                            phd.desc_pat_history_diagnosis,
                                            decode(phd.desc_pat_history_diagnosis,
                                                   NULL,
                                                   '',
                                                   phd.desc_pat_history_diagnosis || ' - ') ||
                                            pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                       i_prof               => i_prof,
                                                                       i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                                       i_id_diagnosis       => d.id_diagnosis,
                                                                       i_id_task_type       => pk_problems.get_flg_area_task_type(i_flg_area => phd.flg_area,
                                                                                                                                  i_flg_type => phd.flg_type),
                                                                       i_code               => d.code_icd,
                                                                       i_flg_other          => d.flg_other,
                                                                       i_flg_std_diag       => ad.flg_icd9)) description,
                                     pk_string_utils.concat_if_exists(pk_problems.get_problem_type_desc(i_lang               => i_lang,
                                                                                                        i_prof               => i_prof,
                                                                                                        i_flg_area           => phd.flg_area,
                                                                                                        i_id_alert_diagnosis => phd.id_alert_diagnosis,
                                                                                                        i_flg_type           => phd.flg_type),
                                                                      pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS',
                                                                                              phd.flg_status,
                                                                                              i_lang),
                                                                      ' - ') status,
                                     pk_problems.get_problem_type_desc(i_lang               => i_lang,
                                                                       i_prof               => i_prof,
                                                                       i_flg_area           => phd.flg_area,
                                                                       i_id_alert_diagnosis => phd.id_alert_diagnosis,
                                                                       i_flg_type           => phd.flg_type) desc_status,
                                     phd.dt_pat_history_diagnosis_tstz dt,
                                     'Y' flg_problem,
                                     609 shortcut,
                                     decode(phd.id_alert_diagnosis, NULL, 'PP', 'RD') flg_source
                      FROM pat_history_diagnosis phd, diagnosis d, alert_diagnosis ad
                     WHERE phd.id_diagnosis = d.id_diagnosis
                          -- ALERT 736: diagnosis synonyms
                       AND phd.id_alert_diagnosis = ad.id_alert_diagnosis(+)
                       AND phd.id_patient = i_patient
                       AND phd.flg_status <> 'C'
                       AND phd.flg_status NOT IN (pk_problems.g_flg_status_none, pk_problems.g_flg_status_unk)
                       AND phd.id_alert_diagnosis NOT IN (pk_problems.g_diag_unknown, pk_problems.g_diag_none)
                       AND phd.id_pat_history_diagnosis =
                           pk_problems.get_most_recent_phd_id(phd.id_pat_history_diagnosis)
                       AND ((l_sys_config_show_diag LIKE pk_alert_constant.g_diag_area_config_show_all) OR
                           (l_sys_config_show_diag LIKE pk_alert_constant.g_diag_area_config_show_own AND
                           phd.flg_area IN
                           (pk_alert_constant.g_diag_area_problems, pk_alert_constant.g_diag_area_not_defined)))
                       AND phd.id_pat_history_diagnosis_new IS NULL
                       AND (l_sc_show_surgical = pk_alert_constant.g_yes OR
                           phd.flg_area <> pk_alert_constant.g_diag_area_surgical_hist)
                    UNION ALL
                    -- diagnosis
                    SELECT DISTINCT pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                                i_prof                => i_prof,
                                                                i_id_alert_diagnosis  => ad1.id_alert_diagnosis,
                                                                i_id_diagnosis        => d1.id_diagnosis,
                                                                i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                                                i_id_task_type        => pk_alert_constant.g_task_problems,
                                                                i_code                => d1.code_icd,
                                                                i_flg_other           => d1.flg_other,
                                                                i_flg_std_diag        => ad1.flg_icd9,
                                                                i_epis_diag           => ed.id_epis_diagnosis) description,
                                     pp.flg_status status,
                                     decode(ed.flg_type, 'P', l_desc_status_03, l_problems_m007) desc_status,
                                     ed.dt_epis_diagnosis_tstz dt,
                                     'Y' flg_problem,
                                     900825 shortcut,
                                     decode(pp.desc_pat_problem,
                                            '',
                                            decode(pp.id_habit, '', decode(nvl(ed.id_epis_diagnosis, 0), 0, 'RD', 'D'), 'H'),
                                            decode(pp.id_diagnosis, NULL, 'PP', 'RD')) flg_source
                      FROM pat_problem     pp,
                            diagnosis       d,
                            professional    p,
                            epis_diagnosis  ed,
                            diagnosis       d1,
                            alert_diagnosis ad1
                     WHERE pp.id_patient = i_patient
                       AND pp.id_diagnosis = d.id_diagnosis(+)
                       AND pp.id_professional_ins = p.id_professional(+)
                       AND pp.flg_status NOT IN (pk_problems.g_cancelled, pk_problems.g_pat_probl_invest)
                       AND ed.id_epis_diagnosis(+) = pp.id_epis_diagnosis
                       AND ed.id_epis_diagnosis = pp.id_epis_diagnosis
                       AND d1.id_diagnosis(+) = ed.id_diagnosis
                          -- ALERT 736: diagnosis synonyms
                       AND ad1.id_alert_diagnosis(+) = ed.id_alert_diagnosis
                       AND ( --final diagnosis 
                            (ed.flg_type = pk_diagnosis.g_diag_type_d) --                             
                            OR -- differencial diagnosis only 
                            (ed.flg_type = pk_diagnosis.g_diag_type_p AND
                            ed.id_diagnosis NOT IN
                            (SELECT ed3.id_diagnosis
                                FROM epis_diagnosis ed3
                               WHERE ed3.id_diagnosis = ed.id_diagnosis
                                 AND ed3.id_patient = pp.id_patient
                                 AND ed3.flg_type = pk_diagnosis.g_diag_type_d)))
                       AND NOT EXISTS (SELECT 1
                              FROM pat_history_diagnosis phd
                              LEFT JOIN diagnosis d2
                                ON d2.id_diagnosis = phd.id_diagnosis --, alert_diagnosis ad2
                             WHERE phd.id_patient = i_patient
                               AND phd.flg_type = pk_problems.g_flg_type_med
                               AND phd.id_diagnosis = pp.id_diagnosis
                               AND phd.id_pat_history_diagnosis =
                                   pk_problems.get_most_recent_phd_id(phd.id_pat_history_diagnosis)
                               AND nvl(d2.flg_other, pk_alert_constant.g_no) <> pk_alert_constant.g_yes
                               AND pp.dt_pat_problem_tstz < phd.dt_pat_history_diagnosis_tstz
                               AND rownum = 1)) t
             WHERE t.flg_source IN ('RD', 'PP', 'P')
                OR (t.flg_source = 'A' AND l_show_allergy = pk_alert_constant.g_yes)
                OR (t.flg_source = 'H' AND l_show_habit = pk_alert_constant.g_yes)
                OR (t.flg_source IN (pk_problems.g_problem_type_diag, 'DD'));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CARE_DASH_PROBLEMS',
                                              o_error);
            pk_types.open_my_cursor(o_problems);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_care_dash_problems;

    FUNCTION get_care_dash_alerts
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_alerts  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_desc_status_04 VARCHAR2(200) := pk_message.get_message(i_lang, 'CARE_DASHBOARD_M004');
        l_desc_status_05 VARCHAR2(200) := pk_message.get_message(i_lang, 'CARE_DASHBOARD_M005');
        l_desc_start_dt  sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'CARE_DASHBOARD_M006');
        l_desc_end_dt    sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'CARE_DASHBOARD_M007');
    
        b_result BOOLEAN;
        e_update_guide_prots EXCEPTION;
    
    BEGIN
    
        g_error := 'UPDATE GUIDELINES';
    
        -- verify if any guideline should be automatically recommended to the patient
        b_result := pk_guidelines.run_batch(i_lang, i_prof, i_patient, NULL, NULL, o_error);
    
        IF (NOT b_result)
        THEN
            RAISE e_update_guide_prots;
        END IF;
    
        COMMIT;
    
        g_error := 'UPDATE PROTOCOLS';
    
        -- verify if any guideline should be automatically recommended to the patient
        b_result := pk_protocol.run_batch(i_lang, i_prof, i_patient, NULL, NULL, o_error);
    
        IF (NOT b_result)
        THEN
            RAISE e_update_guide_prots;
        END IF;
    
        COMMIT;
    
        -- update CITs
        pk_cit.update_status_cit_int(i_lang    => i_lang,
                                     i_prof    => i_prof,
                                     i_patient => i_patient,
                                     i_episode => i_episode);
    
        g_error := 'GET CURSOR O_ALERTS';
    
        OPEN o_alerts FOR
            SELECT description, status, desc_status
              FROM (
                    -- guidelines
                    SELECT guid.guideline_desc AS description,
                            pk_utils.get_status_string_immediate(i_lang,
                                                                 i_prof,
                                                                 decode(gp.flg_status,
                                                                        pk_guidelines.g_process_finished,
                                                                        pk_alert_constant.g_display_type_text_icon,
                                                                        pk_alert_constant.g_display_type_icon),
                                                                 gp.flg_status,
                                                                 NULL,
                                                                 NULL,
                                                                 pk_guidelines.g_domain_flg_guideline, -- 'GUIDELINE_PROCESS.FLG_STATUS'
                                                                 656,
                                                                 decode(pk_sysdomain.get_img(i_lang,
                                                                                             pk_guidelines.g_domain_flg_guideline,
                                                                                             gp.flg_status),
                                                                        pk_guidelines.g_alert_icon, -- 'AlertIcon'
                                                                        decode(gp.flg_status,
                                                                               pk_guidelines.g_process_scheduled,
                                                                               pk_alert_constant.g_color_green,
                                                                               pk_alert_constant.g_color_red),
                                                                        pk_guidelines.g_waiting_icon, -- 'WaitingIcon'
                                                                        pk_alert_constant.g_color_red,
                                                                        pk_alert_constant.g_color_null)) status,
                            l_desc_status_04 desc_status,
                            gp.dt_status dt
                      FROM guideline guid, guideline_process gp
                     WHERE guid.id_institution = i_prof.institution
                       AND guid.id_guideline = gp.id_guideline
                       AND gp.id_patient = i_patient
                          -- necessário validar estados a integrar
                       AND gp.flg_status != pk_guidelines.g_process_canceled
                       AND gp.flg_status != pk_guidelines.g_process_closed
                    UNION ALL
                    -- protocols
                    SELECT g.protocol_desc AS description,
                            pk_utils.get_status_string_immediate(i_lang,
                                                                 i_prof,
                                                                 decode(gp.flg_status,
                                                                        pk_protocol.g_process_finished,
                                                                        pk_alert_constant.g_display_type_text_icon,
                                                                        pk_alert_constant.g_display_type_icon),
                                                                 gp.flg_status,
                                                                 NULL,
                                                                 NULL,
                                                                 pk_protocol.g_domain_flg_protocol, -- 'PROTOCOL_PROCESS.FLG_STATUS'
                                                                 1600,
                                                                 decode(pk_sysdomain.get_img(i_lang,
                                                                                             pk_protocol.g_domain_flg_protocol,
                                                                                             gp.flg_status),
                                                                        pk_protocol.g_alert_icon, -- 'AlertIcon'
                                                                        decode(gp.flg_status,
                                                                               pk_protocol.g_process_scheduled,
                                                                               pk_alert_constant.g_color_green,
                                                                               pk_alert_constant.g_color_red),
                                                                        pk_protocol.g_waiting_icon, -- 'WaitingIcon'
                                                                        pk_alert_constant.g_color_red,
                                                                        pk_alert_constant.g_color_null)) status,
                            l_desc_status_05 desc_status,
                            gp.dt_status dt
                      FROM protocol g, protocol_process gp
                     WHERE g.id_institution = i_prof.institution
                       AND g.id_protocol = gp.id_protocol
                       AND gp.id_patient = i_patient
                       AND gp.flg_nested_protocol = pk_protocol.g_not_nested_protocol
                          -- necessário validar estados a integrar
                       AND gp.flg_status != pk_protocol.g_process_canceled
                       AND gp.flg_status != pk_protocol.g_process_closed
                    UNION ALL
                    SELECT pk_sysdomain.get_domain(pk_cit.g_cit_flg_type, pc.flg_type, i_lang) AS description,
                            pk_utils.get_status_string_immediate(i_lang,
                                                                 i_prof,
                                                                 pk_alert_constant.g_display_type_icon,
                                                                 pc.flg_status,
                                                                 NULL,
                                                                 NULL,
                                                                 pk_cit.g_cit_flg_status,
                                                                 905014,
                                                                 NULL) status,
                            l_desc_start_dt || ' ' ||
                            nvl(pk_date_utils.date_chr_extend_tsz(i_lang, pc.dt_start_period_tstz, i_prof),
                                pk_date_utils.date_chr_extend_tsz(i_lang, pc.dt_other_capac_start, i_prof)) || '; ' ||
                            l_desc_end_dt || ' ' ||
                            nvl(pk_date_utils.date_chr_extend_tsz(i_lang, pc.dt_end_period_tstz, i_prof),
                                pk_sysdomain.get_domain(pk_cit.g_cit_flg_without_period,
                                                        pk_cit.g_capacity_indefinite,
                                                        i_lang)) AS desc_status,
                            pc.dt_start_period_tstz dt
                      FROM pat_cit pc
                     WHERE pc.id_patient = i_patient
                       AND pc.flg_status != pk_cit.g_flg_status_canceled
                       AND pc.flg_status != pk_cit.g_flg_status_concluded)
             ORDER BY dt; -- as mais atrasadas primeiro
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CARE_DASH_ALERTS',
                                              o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_alerts);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_care_dash_alerts;

    FUNCTION get_care_dash_mcdt
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_mcdt    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_num_final_days   sys_config.value%TYPE;
        l_patienteducation VARCHAR2(1) := 'T';
        l_prodecures       VARCHAR2(1) := 'P';
    
        l_closed_task_filter_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
    
        g_error          := 'GET CURSOR O_ALERTS';
        l_num_final_days := pk_sysconfig.get_config(g_finalized_status_num, i_prof);
    
        l_closed_task_filter_tstz := current_timestamp - numtodsinterval(to_number(l_num_final_days), 'DAY');
    
        OPEN o_mcdt FOR
        -- procedimentos
            SELECT description, status
              FROM (SELECT pk_procedures_api_db.get_alias_translation(i_lang, i_prof, i.code_intervention, NULL) description,
                           pk_utils.get_status_string(i_lang,
                                                      i_prof,
                                                      pea.status_str,
                                                      pea.status_msg,
                                                      pea.status_icon,
                                                      pea.status_flg,
                                                      g_shortcut_procedures) status,
                           pea.dt_begin_req dt_begin
                      FROM procedures_ea pea, intervention i
                     WHERE pea.id_patient = i_patient
                       AND (((pea.flg_status_plan IS NULL OR pea.flg_status_plan IN ('R', 'D', 'S')) -- R : requerido, D : pendente
                           AND pea.flg_status_det IN ('R', 'D', 'E', 'S')) -- R : atraso, D : pendente
                           OR (pea.flg_status_det IN ('F', 'I') AND pk_procedures_external_api_db.get_procedure_last_execution(i_lang,
                                                                                                                                i_prof,
                                                                                                                                pea.id_interv_presc_det,
                                                                                                                                pea.flg_status_det) >
                           l_closed_task_filter_tstz))
                       AND pea.id_intervention = i.id_intervention
                    UNION ALL
                    -- Ensinos de enfermagem
                    SELECT decode(ntr.notes_req,
                                  NULL,
                                  REPLACE(pk_message.get_message(i_lang, 'SUMMARY_M009'), ':', ''),
                                  pk_message.get_message(i_lang, 'SUMMARY_M009')) || chr(13) || ntr.notes_req description,
                           pk_utils.get_status_string(i_lang,
                                                      i_prof,
                                                      ntr.status_str,
                                                      ntr.status_msg,
                                                      ntr.status_icon,
                                                      ntr.status_flg,
                                                      15) status,
                           ntr.dt_begin_tstz dt_begin
                      FROM nurse_tea_req ntr
                     WHERE ntr.id_patient = i_patient
                       AND (ntr.flg_status IN ('A', 'D') -- A : activo, D : pendente
                           OR (ntr.flg_status IN ('F') AND pk_patient_education_api_db.get_last_execution(i_lang,
                                                                                                           i_prof,
                                                                                                           ntr.id_nurse_tea_req,
                                                                                                           ntr.flg_status) >
                           l_closed_task_filter_tstz))
                    UNION ALL
                    -- exames
                    SELECT pk_exams_api_db.get_alias_translation(i_lang, i_prof, e.code_exam, NULL) description,
                           pk_utils.get_status_string(i_lang,
                                                      i_prof,
                                                      eea.status_str,
                                                      eea.status_msg,
                                                      eea.status_icon,
                                                      eea.status_flg,
                                                      decode(eea.flg_type, g_exam_type_img, 2210, 11)) status,
                           eea.dt_begin dt_begin
                      FROM exams_ea eea, exam e, exam_req er
                     WHERE eea.id_patient = i_patient
                       AND eea.id_exam = e.id_exam
                       AND (eea.flg_status_req IN ('W', 'R', 'D', 'A', 'P') -- R : requisitado, D : pendente,  A : agendado
                           OR (eea.flg_status_req IN ('F', 'L') AND eea.dt_result > l_closed_task_filter_tstz))
                       AND (eea.flg_status_det IN ('W', 'R', 'D', 'A') -- R : requisitado, D : pendente,  A : agendado, P : c/ resultado parcial
                           OR (eea.flg_status_det IN ('F', 'L') AND eea.dt_result > l_closed_task_filter_tstz))
                       AND eea.id_exam_req = er.id_exam_req
                          -- exclude exams requested to the next episode and already assigned to the next episode
                       AND er.id_episode_destination IS NULL
                    UNION ALL
                    -- analises
                    SELECT DISTINCT pk_lab_tests_api_db.get_alias_translation(i_lang, i_prof, 'A', a.code_analysis, NULL) description,
                                    pk_utils.get_status_string(i_lang,
                                                               i_prof,
                                                               lte.status_str,
                                                               lte.status_msg,
                                                               lte.status_icon,
                                                               lte.status_flg,
                                                               8) status,
                                    lte.dt_req dt_begin
                      FROM lab_tests_ea lte, analysis_req ar, analysis_harvest ah, analysis a
                     WHERE lte.id_patient = i_patient
                       AND lte.id_analysis = a.id_analysis
                       AND lte.id_analysis_req = ar.id_analysis_req
                       AND ah.id_analysis_req_det(+) = lte.id_analysis_req_det
                       AND (lte.flg_status_det IN ('W', 'D', 'E', 'R') -- D : pendente, E : em execução, R : requisitado
                           OR (lte.flg_status_det IN ('F', 'L') AND lte.dt_analysis_result > l_closed_task_filter_tstz))
                          -- exclude analysis requested to the next episode and already created in the next episode
                       AND (ar.id_episode_destination IS NULL OR
                           (ar.id_episode_destination IS NOT NULL AND
                           (lte.flg_status_det = g_flg_status_r OR
                           (ar.id_episode_origin IS NULL AND lte.flg_status_det = g_flg_status_d AND
                           lte.flg_time_harvest != pk_alert_constant.g_flg_time_n)))))
             ORDER BY dt_begin;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CARE_DASH_MCDT',
                                              o_error);
            pk_types.open_my_cursor(o_mcdt);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_care_dash_mcdt;

    FUNCTION get_patient_care_plans
    (
        i_lang       IN language.id_language%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        i_prof       IN profissional,
        i_num_reg    IN NUMBER,
        o_care_plans OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET CURSOR O_CARE_PLANS';
        OPEN o_care_plans FOR
            SELECT description, status, desc_status
              FROM (
                    -- guidelines
                    -- care plans
                    SELECT cp.name description,
                            pk_utils.get_status_string(i_lang,
                                                       i_prof,
                                                       '|I|||#|||||',
                                                       NULL,
                                                       'CARE_PLAN.FLG_STATUS',
                                                       cp.flg_status,
                                                       1616) status,
                            'CARE' desc_status,
                            cp.dt_begin dt
                      FROM care_plan cp
                     WHERE cp.id_patient = i_id_patient
                       AND cp.flg_status IN ('P', 'E', 'S')
                     ORDER BY dt DESC)
             WHERE rownum <= nvl(i_num_reg, rownum);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PATIENT_CARE_PLANS',
                                              o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_care_plans);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_patient_care_plans;

    FUNCTION get_reported_medication
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        o_prev_medication OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_review      NUMBER;
        l_code_review    NUMBER;
        l_selection_list VARCHAR2(4000);
        l_id_prof_create professional.id_professional%TYPE;
        l_dt_create      TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_update      TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_info_source  CLOB;
        l_pat_not_take CLOB;
        l_pat_take     CLOB;
        l_notes        CLOB;
    
        l_prev_medication pk_types.cursor_type;
        t_id_values       table_number := table_number();
        t_description     table_varchar := table_varchar();
        t_desc_status     table_varchar := table_varchar();
    
    BEGIN
    
        g_error := 'CALL PK_API_PFH_IN.GET_LAST_REVIEW';
        IF NOT pk_api_pfh_in.get_last_review(i_lang           => i_lang,
                                             i_prof           => i_prof,
                                             i_id_episode     => i_episode,
                                             i_id_patient     => i_patient,
                                             o_id_review      => l_id_review,
                                             o_code_review    => l_code_review,
                                             o_review_desc    => l_selection_list,
                                             o_dt_create      => l_dt_create,
                                             o_dt_update      => l_dt_update,
                                             o_id_prof_create => l_id_prof_create,
                                             o_info_source    => l_info_source,
                                             o_pat_not_take   => l_pat_not_take,
                                             o_pat_take       => l_pat_take,
                                             o_notes          => l_notes)
        THEN
            l_selection_list := '';
        ELSE
        
            g_error := 'CALL pk_api_pfh_in.get_list_report_active_presc';
            IF NOT pk_api_pfh_in.get_list_report_active_presc(i_lang       => i_lang,
                                                              i_prof       => i_prof,
                                                              i_id_patient => i_patient,
                                                              i_id_visit   => pk_episode.get_id_visit(i_episode => i_episode),
                                                              o_info       => l_prev_medication,
                                                              o_error      => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            IF l_code_review <> pk_api_pfh_in.g_hm_review_none
            THEN
                FETCH l_prev_medication BULK COLLECT
                    INTO t_id_values, t_description, t_desc_status;
            
                OPEN o_prev_medication FOR
                    SELECT -1 id_values, l_selection_list description, NULL desc_status
                      FROM dual
                    UNION
                    SELECT t_values.column_value id_values,
                           t_descr.column_value  description,
                           t_status.column_value desc_status
                      FROM (SELECT /*+OPT_ESTIMATE(TABLE t ROWS=1)*/
                             rownum rn, column_value
                              FROM TABLE(t_id_values) t) t_values
                      JOIN (SELECT /*+OPT_ESTIMATE(TABLE x ROWS=1)*/
                             rownum rn, column_value
                              FROM TABLE(t_description) x) t_descr
                        ON t_descr.rn = t_values.rn
                      JOIN (SELECT /*+OPT_ESTIMATE(TABLE y ROWS=1)*/
                             rownum rn, column_value
                              FROM TABLE(t_desc_status) y) t_status
                        ON t_status.rn = t_values.rn;
            ELSE
                o_prev_medication := l_prev_medication;
            END IF;
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
                                              'GET_REPORTED_MEDICATION',
                                              o_error);
            pk_types.open_my_cursor(o_prev_medication);
            RETURN FALSE;
    END get_reported_medication;

    FUNCTION get_assessment_tools
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        o_assessment_tools OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_doc_scales         pk_scales_core.t_coll_doc_scales;
        l_doc_area           table_number;
        l_doc_area_d         table_number;
        l_epis_documentation table_number;
        l_market             market.id_market%TYPE;
    
    BEGIN
    
        pk_alertlog.log_debug(text            => g_error,
                              object_name     => g_package_name,
                              sub_object_name => 'GET_ASSESSMENT_TOOLS');
    
        g_error  := 'get_institution_market';
        l_market := pk_utils.get_institution_market(i_lang => i_lang, i_id_institution => i_prof.institution);
    
        g_error := 'GET DOC_AREA LIST';
        SELECT id_doc_area
          BULK COLLECT
          INTO l_doc_area
          FROM (SELECT id_doc_area
                  FROM dash_doc_area_mkt dam
                 WHERE dam.id_market = l_market
                   AND dam.flg_available = pk_alert_constant.g_available
                   AND (SELECT COUNT(1)
                          FROM dash_doc_area_inst dai
                         WHERE dai.id_institution = i_prof.institution
                           AND dai.flg_available = pk_alert_constant.g_available) = 0
                UNION
                SELECT id_doc_area
                  FROM dash_doc_area_inst dai
                 WHERE dai.id_institution = i_prof.institution
                   AND dai.flg_available = pk_alert_constant.g_available);
    
        g_error := 'GET EPIS_DOCUMENTATION';
        SELECT id_epis_documentation, id_doc_area
          BULK COLLECT
          INTO l_epis_documentation, l_doc_area_d
          FROM (SELECT ed.id_epis_documentation,
                       ed.dt_creation_tstz,
                       ed.id_doc_area,
                       row_number() over(PARTITION BY ed.id_doc_area ORDER BY ed.dt_creation_tstz DESC) rn
                  FROM epis_documentation ed
                  JOIN episode e
                    ON ed.id_episode = e.id_episode
                 WHERE e.id_patient = i_patient
                   AND ed.id_doc_area IN (SELECT /*+ dynamic_sampling(t 2) */
                                           t.column_value
                                            FROM TABLE(l_doc_area) t)
                   AND ed.flg_status = pk_touch_option.g_epis_doc_active
                   AND ed.dt_creation_tstz IS NOT NULL)
         WHERE rn = 1;
    
        g_error := 'OPEN     o_assessment_tools';
        OPEN o_assessment_tools FOR
            SELECT DISTINCT id_epis_documentation, template_desc, desc_class desc_score, soma, dt_last_update_tstz
              FROM (SELECT /*+opt_estimate(table,t,scale_rows=0.0000001)*/
                     ed.id_epis_documentation,
                     s.id_scales,
                     ed.id_doc_template,
                     pk_translation.get_translation(i_lang, dt.code_doc_template) template_desc,
                     s.desc_class,
                     s.soma,
                     s.id_professional,
                     s.nick_name,
                     s.date_target,
                     s.hour_target,
                     s.dt_last_update,
                     ed.dt_last_update_tstz,
                     s.flg_status
                      FROM epis_documentation ed
                      JOIN doc_template dt
                        ON ed.id_doc_template = dt.id_doc_template
                      LEFT JOIN (SELECT t.id_epis_documentation,
                                       t.id_scales,
                                       t.desc_class,
                                       t.soma,
                                       t.id_professional,
                                       t.nick_name,
                                       t.date_target,
                                       t.hour_target,
                                       t.dt_last_update,
                                       t.flg_status
                                  FROM TABLE(pk_scales_core.tf_scales_list(i_lang,
                                                                           i_prof,
                                                                           i_patient,
                                                                           l_epis_documentation)) t
                                UNION
                                SELECT t.id_epis_documentation,
                                       t.id_score,
                                       t.desc_class,
                                       t.soma,
                                       t.id_professional,
                                       t.nick_name,
                                       t.date_target,
                                       t.hour_target,
                                       t.dt_last_update,
                                       t.flg_status
                                  FROM TABLE(pk_risk_factor.tf_risk_total_score(i_lang, i_prof, l_epis_documentation)) t) s
                        ON s.id_epis_documentation = ed.id_epis_documentation
                     WHERE ed.id_epis_documentation IN
                           (SELECT /*+ dynamic_sampling(d 2) */
                             d.column_value
                              FROM TABLE(l_epis_documentation) d))
             ORDER BY dt_last_update_tstz DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ASSESSMENT_TOOLS',
                                              o_error);
            pk_types.open_my_cursor(o_assessment_tools);
            RETURN FALSE;
    END get_assessment_tools;

    FUNCTION get_analysis_result
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        o_analysis OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_analysis table_number;
    
    BEGIN
    
        g_error := 'OPEN O_ANALYSIS';
        OPEN o_analysis FOR
            SELECT id,
                   VALUE,
                   name,
                   color_text,
                   unit,
                   hour,
                   harvest_date AS "DATE",
                   get_analysis_tooltip(i_lang,
                                        i_prof,
                                        name,
                                        VALUE,
                                        ref_val,
                                        result_status,
                                        dt_harvest,
                                        result_notes,
                                        parameter_notes,
                                        unit) tooltip
              FROM (SELECT a.id_analysis id,
                           decode(ares.id_analysis_desc,
                                  NULL,
                                  decode(dbms_lob.getlength(ares.desc_analysis_result),
                                         NULL,
                                         to_clob((ares.comparator || ares.analysis_result_value_1 || ares.separator ||
                                                 ares.analysis_result_value_2)),
                                         ares.desc_analysis_result),
                                  (SELECT decode(ad.icon,
                                                 NULL,
                                                 pk_translation.get_translation(i_lang, ad.code_analysis_desc),
                                                 ad.icon || '|' ||
                                                 pk_translation.get_translation(i_lang, ad.code_analysis_desc))
                                     FROM analysis_desc ad
                                    WHERE ad.id_analysis_desc = ares.id_analysis_desc)) ||
                           decode(ab.value, NULL, NULL, ' ' || ab.value) VALUE,
                           
                           nvl(pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                         i_prof,
                                                                         'P',
                                                                         pa.code_analysis_parameter,
                                                                         NULL),
                               pk_lab_tests_api_db.get_alias_translation(i_lang, i_prof, 'A', a.code_analysis, NULL)) name,
                           
                           CASE
                                WHEN pk_utils.is_number(dbms_lob.substr(ares.desc_analysis_result, 3800)) =
                                     pk_lab_tests_constant.g_yes
                                     AND ares.analysis_result_value_2 IS NULL THEN
                                 CASE
                                     WHEN nvl(to_number(TRIM(REPLACE(ares.desc_analysis_result, '.', ',')),
                                                        pk_lab_tests_constant.g_format_mask,
                                                        'NLS_NUMERIC_CHARACTERS='', '''),
                                              ares.analysis_result_value_1) < ares.ref_val_min THEN
                                      '0xC3000A'
                                     WHEN nvl(to_number(TRIM(REPLACE(ares.desc_analysis_result, '.', ',')),
                                                        pk_lab_tests_constant.g_format_mask,
                                                        'NLS_NUMERIC_CHARACTERS='', '''),
                                              ares.analysis_result_value_1) > ares.ref_val_max THEN
                                      '0xC3000A'
                                     ELSE
                                      CASE
                                          WHEN ares.id_abnormality IS NOT NULL THEN
                                           ab.color_code
                                          ELSE
                                           NULL
                                      END
                                 END
                                ELSE
                                 NULL
                            END color_text,
                           nvl(ares.desc_unit_measure,
                               pk_translation.get_translation(i_lang,
                                                              'UNIT_MEASURE.CODE_UNIT_MEASURE.' ||
                                                              nvl(ares.id_unit_measure,
                                                                  pk_lab_tests_api_db.get_lab_test_unit_measure(i_lang,
                                                                                                                i_prof,
                                                                                                                apar.id_analysis,
                                                                                                                ares.id_sample_type,
                                                                                                                apar.id_analysis_parameter)))) unit,
                           
                           pk_date_utils.dt_chr_hour_tsz(i_lang, ares.dt_harvest_tstz, i_prof) hour,
                           pk_date_utils.dt_chr_tsz(i_lang, ares.dt_harvest_tstz, i_prof) harvest_date,
                           pk_lab_tests_api_db.get_lab_test_unit_measure(i_lang,
                                                                         i_prof,
                                                                         apar.id_analysis,
                                                                         ares.id_sample_type,
                                                                         apar.id_analysis_parameter) id_unit,
                           ares.notes result_notes,
                           decode(dbms_lob.getlength(ares.parameter_notes),
                                  NULL,
                                  decode(dbms_lob.getlength(ares.interface_notes), NULL, NULL, ares.interface_notes),
                                  ares.parameter_notes) parameter_notes,
                           nvl(ares.ref_val,
                               decode((nvl(TRIM(ares.ref_val_min_str), ares.ref_val_min) || ' - ' ||
                                      nvl(TRIM(ares.ref_val_max_str), ares.ref_val_max)),
                                      ' - ',
                                      NULL,
                                      nvl(TRIM(ares.ref_val_min_str), ares.ref_val_min) || ' - ' ||
                                      nvl(TRIM(ares.ref_val_max_str), ares.ref_val_max))) ref_val,
                           pk_date_utils.date_char_tsz(i_lang, ares.dt_harvest_tstz, i_prof.institution, i_prof.software) dt_harvest,
                           pk_translation.get_translation(i_lang,
                                                          'RESULT_STATUS.SHORT_CODE_RESULT_STATUS.' ||
                                                          ares.id_result_status) result_status
                      FROM (SELECT *
                              FROM (SELECT arp.*,
                                           ar.id_analysis_req_det,
                                           ar.id_harvest,
                                           ar.notes,
                                           ar.id_sample_type,
                                           ar.dt_analysis_result_tstz,
                                           apf.id_analysis_param_funcionality,
                                           h.dt_harvest_tstz,
                                           row_number() over(PARTITION BY ar.id_analysis, arp.id_analysis_parameter ORDER BY nvl(h.dt_harvest_tstz, ar.dt_sample) DESC) rn
                                      FROM analysis_result_par         arp,
                                           analysis_result             ar,
                                           analysis_param              ap,
                                           analysis_param_funcionality apf,
                                           harvest                     h
                                     WHERE arp.id_analysis_result = ar.id_analysis_result
                                       AND ar.id_patient = i_patient
                                       AND ar.id_analysis = ap.id_analysis
                                       AND arp.id_analysis_parameter = ap.id_analysis_parameter
                                       AND ap.id_analysis_param = apf.id_analysis_param
                                       AND apf.flg_type = 'D'
                                       AND ap.flg_available = 'Y'
                                       AND ap.id_software = i_prof.software
                                       AND ap.id_institution = i_prof.institution
                                       AND ar.id_harvest = h.id_harvest(+)
                                       AND coalesce(to_char(dbms_lob.substr(arp.desc_analysis_result, 3800)),
                                                    to_char(arp.analysis_result_value_1),
                                                    '0') != 'DNR') ar
                             WHERE ar.rn = 1) ares,
                           (SELECT *
                              FROM abnormality
                             WHERE flg_visible = pk_lab_tests_constant.g_yes) ab,
                           analysis a,
                           analysis_param apar,
                           analysis_parameter pa,
                           analysis_param_funcionality af
                     WHERE a.flg_available = pk_alert_constant.g_available
                       AND apar.id_analysis = a.id_analysis
                       AND af.id_analysis_param = apar.id_analysis_param
                       AND apar.flg_available = pk_alert_constant.g_available
                       AND apar.id_software = i_prof.software
                       AND af.flg_type = 'D'
                       AND apar.id_institution = i_prof.institution
                       AND apar.id_analysis = a.id_analysis
                       AND apar.id_analysis_parameter = pa.id_analysis_parameter
                       AND ares.id_analysis_param_funcionality(+) = af.id_analysis_param_funcionality
                       AND ares.id_abnormality = ab.id_abnormality(+)
                     ORDER BY af.rank);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ANALYSIS_RESULT',
                                              o_error);
            pk_types.open_my_cursor(o_analysis);
            RETURN FALSE;
    END get_analysis_result;

    FUNCTION get_cancer_plan
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        o_doc_area_register  OUT pk_types.cursor_type,
        o_doc_area_component OUT pk_types.cursor_type,
        o_doc_area_val       OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_epis_documentation table_number;
        l_template_layouts   pk_types.cursor_type;
    
    BEGIN
    
        g_error := 'SELECT ID_EPIS_DOCUMENTATION';
        SELECT id_epis_documentation
          BULK COLLECT
          INTO l_epis_documentation
          FROM (SELECT ed.id_epis_documentation, ed.dt_creation_tstz, ed.id_doc_area
                  FROM epis_documentation ed
                  JOIN episode e
                    ON ed.id_episode = e.id_episode
                 WHERE e.id_patient = i_patient
                   AND ed.id_doc_area = g_doc_area_cancer_plan
                   AND ed.flg_status = pk_touch_option.g_epis_doc_active
                   AND ed.dt_creation_tstz IS NOT NULL);
    
        g_error := 'CALL PK_TOUCH_OPTION.GET_DOC_AREA_VALUE_INTERNAL';
        IF NOT pk_touch_option.get_doc_area_value_internal(i_lang               => i_lang,
                                                           i_prof               => i_prof,
                                                           i_id_episode         => i_episode,
                                                           i_id_patient         => i_patient,
                                                           i_doc_area           => g_doc_area_cancer_plan,
                                                           i_epis_doc           => l_epis_documentation,
                                                           i_epis_anamn         => table_number(),
                                                           i_epis_rev_sys       => table_number(),
                                                           i_epis_obs           => table_number(),
                                                           i_epis_past_fsh      => table_number(),
                                                           i_epis_recomend      => table_number(),
                                                           o_doc_area_register  => o_doc_area_register,
                                                           o_doc_area_val       => o_doc_area_val,
                                                           o_template_layouts   => l_template_layouts,
                                                           o_doc_area_component => o_doc_area_component,
                                                           o_error              => o_error)
        THEN
            RAISE g_exception;
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
                                              'GET_CANCER_PLAN',
                                              o_error);
            pk_types.open_my_cursor(o_doc_area_register);
            pk_types.open_my_cursor(o_doc_area_val);
            pk_types.open_my_cursor(o_doc_area_component);
            RETURN FALSE;
    END get_cancer_plan;

    FUNCTION get_default_dashboard
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        o_default      OUT VARCHAR2,
        o_view_options OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_view_option view_option.id_view_option%TYPE;
        l_screen      view_option.screen_identifier%TYPE;
    
    BEGIN
    
        g_error := 'CALL pk_view_option.get_prof_default_view';
        IF NOT pk_view_option.get_prof_default_view(i_lang           => i_lang,
                                                    i_prof           => i_prof,
                                                    i_subject        => g_dashboard_view,
                                                    o_id_view_option => l_view_option,
                                                    o_screen         => o_default,
                                                    o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL PK_VIEW_OPTION.GET_PROF_VIEW_OPTIONS';
        IF NOT pk_view_option.get_prof_view_options(i_lang         => i_lang,
                                                    i_prof         => i_prof,
                                                    i_subject      => g_dashboard_view,
                                                    o_view_options => o_view_options,
                                                    o_error        => o_error)
        THEN
            RETURN FALSE;
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
                                              'GET_DEFAULT_DASHBOARD',
                                              o_error);
            pk_types.open_my_cursor(o_view_options);
            RETURN FALSE;
    END get_default_dashboard;

    FUNCTION get_analysis_tooltip
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_name            IN VARCHAR2,
        i_value           IN CLOB,
        i_ref             IN VARCHAR2,
        i_status          IN VARCHAR2,
        i_harvest         IN VARCHAR2,
        i_result_notes    IN CLOB,
        i_parameter_notes IN CLOB,
        i_unit            IN VARCHAR2
    ) RETURN CLOB IS
    
        l_analysis    sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'LAB_TESTS_T131');
        l_result      sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'LAB_TESTS_T066');
        l_status      sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'LAB_TESTS_T047');
        l_ref_value   sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'LAB_TESTS_T070');
        l_param_notes sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'LAB_TESTS_T149');
        l_notes       sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'LAB_TESTS_T132');
        l_harvest     sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'LAB_TESTS_T135');
    
        l_description CLOB;
    
    BEGIN
    
        IF i_name IS NOT NULL
        THEN
            l_description := g_open_bold || l_analysis || g_close_bold || chr(10) || htf.escape_sc(i_name);
        END IF;
    
        IF i_value IS NOT NULL
        THEN
            l_description := CASE
                                 WHEN l_description IS NOT NULL THEN
                                  l_description || chr(10) || chr(10)
                             END || g_open_bold || l_result || g_close_bold || chr(10) || htf.escape_sc(i_value) || g_space ||
                             i_unit;
        END IF;
    
        IF i_status IS NOT NULL
        THEN
            l_description := CASE
                                 WHEN l_description IS NOT NULL THEN
                                  l_description || chr(10) || chr(10)
                             END || g_open_bold || l_status || g_close_bold || chr(10) || i_status;
        END IF;
    
        IF i_ref IS NOT NULL
        THEN
            l_description := CASE
                                 WHEN l_description IS NOT NULL THEN
                                  l_description || chr(10) || chr(10)
                             END || g_open_bold || l_ref_value || g_close_bold || chr(10) || i_ref || g_space || i_unit;
        END IF;
    
        IF i_harvest IS NOT NULL
        THEN
            l_description := CASE
                                 WHEN l_description IS NOT NULL THEN
                                  l_description || chr(10) || chr(10)
                             END || g_open_bold || l_harvest || g_close_bold || chr(10) || i_harvest;
        END IF;
    
        IF dbms_lob.getlength(i_result_notes) > 0
        THEN
            l_description := CASE
                                 WHEN l_description IS NOT NULL THEN
                                  l_description || chr(10) || chr(10)
                             END || g_open_bold || l_notes || g_close_bold || chr(10) || htf.escape_sc(i_result_notes);
        END IF;
    
        IF i_parameter_notes IS NOT NULL
        THEN
            l_description := CASE
                                 WHEN l_description IS NOT NULL THEN
                                  l_description || chr(10) || chr(10)
                             END || g_open_bold || l_param_notes || g_close_bold || chr(10) || htf.escape_sc(i_parameter_notes);
        END IF;
    
        RETURN l_description;
    
    END get_analysis_tooltip;

    FUNCTION get_patient_emr_summary
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_patient        IN patient.id_patient%TYPE,
        i_id_episode        IN episode.id_episode%TYPE,
        i_num_reg           IN NUMBER,
        o_vs                OUT pk_types.cursor_type,
        o_visit_list        OUT pk_types.cursor_type,
        o_problem_list      OUT pk_types.cursor_type,
        o_medication_list   OUT pk_types.cursor_type,
        o_immunization_list OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF i_id_patient IS NULL
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL PK_VITAL_SIGN.GET_PAT_VITAL_SIGN';
        IF NOT pk_vital_sign.get_pat_vital_sign(i_lang     => i_lang,
                                                i_patient  => i_id_patient,
                                                i_prof     => i_prof,
                                                i_flg_view => pk_vital_sign.g_flg_scope_summary_s,
                                                o_sign_v   => o_vs,
                                                o_error    => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL PK_PATIENT_SUMMARY.GET_PREVIOUS_VISITS';
        IF NOT pk_patient_summary.get_previous_visits(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_id_patient => i_id_patient,
                                                      i_num_reg    => i_num_reg,
                                                      o_visit_list => o_visit_list,
                                                      o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL PK_PATIENT_SUMMARY.GET_PATIENT_ALLERGIES';
        IF NOT pk_patient_summary.get_patient_problems(i_lang         => i_lang,
                                                       i_prof         => i_prof,
                                                       i_id_patient   => i_id_patient,
                                                       i_num_reg      => i_num_reg,
                                                       i_flg_show_ph  => pk_alert_constant.g_yes,
                                                       o_pat_problems => o_problem_list,
                                                       o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL PK_API_PFH_IN.GET_PRESC_HOME_DISCHARGE';
        IF NOT pk_api_pfh_in.get_presc_home_discharge(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_id_episode => i_id_episode,
                                                      o_info       => o_medication_list,
                                                      o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL PK_IMMUNIZATION_CORE.GET_DASHBOARD_VACC';
        IF NOT pk_immunization_core.get_dashboard_vacc(i_lang    => i_lang,
                                                       i_prof    => i_prof,
                                                       i_patient => i_id_patient,
                                                       o_vacc    => o_immunization_list,
                                                       o_error   => o_error)
        THEN
            RAISE g_exception;
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
                                              'GET_PATIENT_DASHBOARD',
                                              o_error);
            pk_types.open_my_cursor(o_vs);
            pk_types.open_my_cursor(o_visit_list);
            pk_types.open_my_cursor(o_problem_list);
            pk_types.open_my_cursor(o_medication_list);
            pk_types.open_my_cursor(o_immunization_list);
        
            RETURN FALSE;
    END get_patient_emr_summary;

    FUNCTION get_patient_dashboard
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_patient   IN patient.id_patient%TYPE,
        i_id_episode   IN episode.id_episode%TYPE,
        i_doc_area     IN doc_area.id_doc_area%TYPE,
        i_flg_view     IN vs_soft_inst.flg_view%TYPE,
        i_num_reg      IN NUMBER,
        o_vs           OUT pk_types.cursor_type,
        o_advanced     OUT pk_types.cursor_type,
        o_with_me      OUT pk_types.cursor_type,
        o_all          OUT pk_types.cursor_type,
        o_pat_problems OUT pk_types.cursor_type,
        o_drug         OUT pk_types.cursor_type,
        o_analy        OUT pk_types.cursor_type,
        o_proc         OUT pk_types.cursor_type,
        o_exam         OUT pk_types.cursor_type,
        o_care_plans   OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        -- Show the number of finalized record to show
    
        IF i_id_patient IS NULL
        --OR i_id_episode IS NULL
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL PK_PATIENT_SUMMARY.GET_SUMMARY_GRID_PAT';
        IF NOT pk_patient_summary.get_summary_grid_pat(i_lang       => i_lang,
                                                       i_id_patient => i_id_patient,
                                                       i_prof       => i_prof,
                                                       i_id_episode => i_id_episode,
                                                       i_num_reg    => i_num_reg,
                                                       o_drug       => o_drug,
                                                       o_analy      => o_analy,
                                                       o_proc       => o_proc,
                                                       o_exam       => o_exam,
                                                       o_error      => o_error)
        
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL PK_VITAL_SIGN.GET_PAT_VITAL_SIGN';
        IF NOT pk_vital_sign.get_pat_vital_sign(i_lang     => i_lang,
                                                i_patient  => i_id_patient,
                                                i_prof     => i_prof,
                                                i_flg_view => i_flg_view,
                                                o_sign_v   => o_vs,
                                                o_error    => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL PK_PATIENT_SUMMARY.GET_ADVANCED_DIRECTIVES';
        IF NOT pk_patient_summary.get_advanced_directives(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                          i_id_patient => i_id_patient,
                                                          i_doc_area   => i_doc_area,
                                                          i_num_reg    => i_num_reg,
                                                          o_advanced   => o_advanced,
                                                          o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL PK_PATIENT_SUMMARY.GET_PATIENT_ALLERGIES';
        IF NOT pk_patient_summary.get_patient_problems(i_lang         => i_lang,
                                                       i_prof         => i_prof,
                                                       i_id_patient   => i_id_patient,
                                                       i_num_reg      => i_num_reg,
                                                       o_pat_problems => o_pat_problems,
                                                       o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL PK_PATIENT_SUMMARY.GET_PREVIOUS_VISITS';
        IF NOT pk_patient_summary.get_previous_visits(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_id_patient => i_id_patient,
                                                      o_with_me    => o_with_me,
                                                      i_num_reg    => i_num_reg,
                                                      o_all        => o_all,
                                                      o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL PK_PATIENT_SUMMARY.GET_CARE_PLANS';
        IF NOT pk_patient_summary.get_care_plans(i_lang       => i_lang,
                                                 i_prof       => i_prof,
                                                 i_id_patient => i_id_patient,
                                                 i_num_reg    => i_num_reg,
                                                 o_care_plans => o_care_plans,
                                                 o_error      => o_error)
        THEN
            RAISE g_exception;
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
                                              'GET_PATIENT_DASHBOARD',
                                              o_error);
            pk_types.open_my_cursor(o_vs);
            pk_types.open_my_cursor(o_advanced);
            pk_types.open_my_cursor(o_with_me);
            pk_types.open_my_cursor(o_all);
            pk_types.open_my_cursor(o_pat_problems);
            pk_types.open_my_cursor(o_drug);
            pk_types.open_my_cursor(o_analy);
            pk_types.open_my_cursor(o_proc);
            pk_types.open_my_cursor(o_exam);
            pk_types.open_my_cursor(o_care_plans);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_patient_dashboard;

    FUNCTION get_amb_dashboard
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        o_cnt_info        OUT pk_types.cursor_type,
        o_problems        OUT pk_types.cursor_type,
        o_prev_contact    OUT pk_types.cursor_type,
        o_alerts          OUT pk_types.cursor_type,
        o_vacc            OUT pk_types.cursor_type,
        o_mcdt            OUT pk_types.cursor_type,
        o_health_program  OUT pk_types.cursor_type,
        o_care_plans      OUT pk_types.cursor_type,
        o_prev_medication OUT pk_types.cursor_type,
        o_dashboard_tabs  OUT pk_types.cursor_type,
        o_vs              OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dashboard_mode   sys_config.value%TYPE;
        l_dasboard_subject VARCHAR2(200);
    
    BEGIN
    
        l_dasboard_subject := 'DASHBOARD_LAST_APPOINTMENT';
        g_error            := 'CALL PK_PREV_ENCOUNTER.GET_LAST_ENCOUNTER';
        IF NOT pk_prev_encounter.get_last_encounter(i_lang     => i_lang,
                                                    i_prof     => i_prof,
                                                    i_patient  => i_patient,
                                                    i_episode  => i_episode,
                                                    o_enc_data => o_cnt_info,
                                                    o_error    => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL PK_PATIENT_SUMMARY.GET_PATIENT_PROBLEMS';
        IF NOT pk_patient_summary.get_care_dash_problems(i_lang     => i_lang,
                                                         i_prof     => i_prof,
                                                         i_patient  => i_patient,
                                                         i_episode  => i_episode,
                                                         o_problems => o_problems,
                                                         o_error    => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'GET PK_TAB_BUTTON.GET_PROF_TAB_BUTTON_DEFAULT ';
        IF NOT pk_tab_button.get_prof_tab_button_default(i_lang               => i_lang,
                                                         i_prof               => i_prof,
                                                         i_subject            => l_dasboard_subject,
                                                         o_tab_button_default => l_dashboard_mode,
                                                         o_error              => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL PK_PREV_ENCOUNTER.GET_PREV_ENC_INFO';
        IF NOT pk_prev_encounter.get_prev_enc_info(i_lang     => i_lang,
                                                   i_prof     => i_prof,
                                                   i_patient  => i_patient,
                                                   i_episode  => i_episode,
                                                   i_flg_type => l_dashboard_mode,
                                                   o_enc_info => o_prev_contact,
                                                   o_error    => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL PK_EPISODE.GET_CARE_DASH_ALERTS';
        IF NOT pk_patient_summary.get_care_dash_alerts(i_lang    => i_lang,
                                                       i_prof    => i_prof,
                                                       i_patient => i_patient,
                                                       i_episode => i_episode,
                                                       o_alerts  => o_alerts,
                                                       o_error   => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL PK_EPISODE.GET_CARE_DASH_MCDT';
        IF NOT pk_patient_summary.get_care_dash_mcdt(i_lang    => i_lang,
                                                     i_prof    => i_prof,
                                                     i_patient => i_patient,
                                                     o_mcdt    => o_mcdt,
                                                     o_error   => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL PK_HEALTH_PROGRAM.GET_PAT_INSC_HPGS';
        IF NOT pk_health_program.get_pat_insc_hpgs(i_lang    => i_lang,
                                                   i_prof    => i_prof,
                                                   i_patient => i_patient,
                                                   o_hpgs    => o_health_program,
                                                   o_error   => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL PK_PATIENT_SUMMARY.GET_CARE_PLANS';
        IF NOT pk_patient_summary.get_patient_care_plans(i_lang => i_lang,
                                                         
                                                         i_prof       => i_prof,
                                                         i_id_patient => i_patient,
                                                         i_num_reg    => NULL,
                                                         o_care_plans => o_care_plans,
                                                         o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL PK_IMMUNIZATION_UX.GET_CARE_DASH_VACC';
        IF NOT pk_immunization_ux.get_care_dash_vacc(i_lang    => i_lang,
                                                     i_prof    => i_prof,
                                                     i_patient => i_patient,
                                                     o_vacc    => o_vacc,
                                                     o_error   => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF i_prof.software = pk_alert_constant.g_soft_primary_care
        THEN
            g_error := 'CALL PK_API_PFH_IN.GET_ACTIVE_CHRONIC_MEDICATION';
            IF NOT pk_api_pfh_in.get_active_chronic_presc(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                          i_id_patient => i_patient,
                                                          i_id_visit   => pk_visit.get_visit(i_episode => i_episode,
                                                                                             o_error   => o_error),
                                                          o_info       => o_prev_medication,
                                                          o_error      => o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSE
            g_error := 'CALL PK_PATIENT_SUMMARY.GET_REPORTED_MEDICATION';
            IF NOT pk_patient_summary.get_reported_medication(i_lang            => i_lang,
                                                              i_prof            => i_prof,
                                                              i_patient         => i_patient,
                                                              i_episode         => i_episode,
                                                              o_prev_medication => o_prev_medication,
                                                              o_error           => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
        END IF;
    
        g_error := 'CALL PK_TAB_BUTTON.GET_PROF_TAB_BUTTON';
        IF NOT pk_tab_button.get_prof_tab_button(i_lang       => i_lang,
                                                 i_prof       => i_prof,
                                                 i_subject    => l_dasboard_subject,
                                                 o_tab_button => o_dashboard_tabs,
                                                 o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL PK_VITAL_SIGN.GET_PAT_VITAL_SIGN';
        IF NOT pk_vital_sign.get_pat_vital_sign(i_lang     => i_lang,
                                                i_patient  => i_patient,
                                                i_prof     => i_prof,
                                                i_flg_view => 'S',
                                                o_sign_v   => o_vs,
                                                o_error    => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_cnt_info);
            pk_types.open_my_cursor(o_problems);
            pk_types.open_my_cursor(o_prev_contact);
            pk_types.open_my_cursor(o_alerts);
            pk_types.open_my_cursor(o_vacc);
            pk_types.open_my_cursor(o_mcdt);
            pk_types.open_my_cursor(o_health_program);
            pk_types.open_my_cursor(o_care_plans);
            pk_types.open_my_cursor(o_prev_medication);
            pk_types.open_my_cursor(o_dashboard_tabs);
            pk_types.open_my_cursor(o_vs);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_AMB_DASHBOARD',
                                              o_error);
            pk_types.open_my_cursor(o_cnt_info);
            pk_types.open_my_cursor(o_problems);
            pk_types.open_my_cursor(o_prev_contact);
            pk_types.open_my_cursor(o_alerts);
            pk_types.open_my_cursor(o_vacc);
            pk_types.open_my_cursor(o_mcdt);
            pk_types.open_my_cursor(o_health_program);
            pk_types.open_my_cursor(o_care_plans);
            pk_types.open_my_cursor(o_prev_medication);
            pk_types.open_my_cursor(o_dashboard_tabs);
            pk_types.open_my_cursor(o_vs);
            RETURN FALSE;
    END get_amb_dashboard;

    FUNCTION get_oncology_dashboard
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        o_problems           OUT pk_types.cursor_type,
        o_prev_contact       OUT pk_types.cursor_type,
        o_alerts             OUT pk_types.cursor_type,
        o_vacc               OUT pk_types.cursor_type,
        o_mcdt               OUT pk_types.cursor_type,
        o_health_program     OUT pk_types.cursor_type,
        o_care_plans         OUT pk_types.cursor_type,
        o_prev_medication    OUT pk_types.cursor_type,
        o_dashboard_tabs     OUT pk_types.cursor_type,
        o_vs                 OUT pk_types.cursor_type,
        o_analysis           OUT pk_types.cursor_type,
        o_diagnosis          OUT pk_types.cursor_type,
        o_assessment_tools   OUT pk_types.cursor_type,
        o_doc_area_register  OUT pk_types.cursor_type,
        o_doc_area_component OUT pk_types.cursor_type,
        o_doc_area_val       OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dashboard_mode   sys_config.value%TYPE;
        l_dasboard_subject VARCHAR2(200);
    
    BEGIN
    
        l_dasboard_subject := 'DASHBOARD_LAST_APPOINTMENT';
    
        g_error := 'CALL PK_PATIENT_SUMMARY.GET_PATIENT_PROBLEMS';
        IF NOT pk_patient_summary.get_care_dash_problems(i_lang     => i_lang,
                                                         i_prof     => i_prof,
                                                         i_patient  => i_patient,
                                                         i_episode  => i_episode,
                                                         o_problems => o_problems,
                                                         o_error    => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'GET PK_TAB_BUTTON.GET_PROF_TAB_BUTTON_DEFAULT ';
        IF NOT pk_tab_button.get_prof_tab_button_default(i_lang               => i_lang,
                                                         i_prof               => i_prof,
                                                         i_subject            => l_dasboard_subject,
                                                         o_tab_button_default => l_dashboard_mode,
                                                         o_error              => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL PK_PREV_ENCOUNTER.GET_PREV_ENC_INFO';
        IF NOT pk_prev_encounter.get_prev_visits(i_lang     => i_lang,
                                                 i_prof     => i_prof,
                                                 i_patient  => i_patient,
                                                 i_episode  => i_episode,
                                                 i_flg_type => l_dashboard_mode,
                                                 o_enc_info => o_prev_contact,
                                                 o_error    => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL PK_EPISODE.GET_CARE_DASH_ALERTS';
        IF NOT pk_patient_summary.get_care_dash_alerts(i_lang    => i_lang,
                                                       i_prof    => i_prof,
                                                       i_patient => i_patient,
                                                       i_episode => i_episode,
                                                       o_alerts  => o_alerts,
                                                       o_error   => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL PK_EPISODE.GET_CARE_DASH_MCDT';
        IF NOT pk_patient_summary.get_care_dash_mcdt(i_lang    => i_lang,
                                                     i_prof    => i_prof,
                                                     i_patient => i_patient,
                                                     o_mcdt    => o_mcdt,
                                                     o_error   => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL PK_HEALTH_PROGRAM.GET_PAT_INSC_HPGS';
        IF NOT pk_health_program.get_pat_insc_hpgs(i_lang    => i_lang,
                                                   i_prof    => i_prof,
                                                   i_patient => i_patient,
                                                   o_hpgs    => o_health_program,
                                                   o_error   => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL PK_PATIENT_SUMMARY.GET_CARE_PLANS';
        IF NOT pk_patient_summary.get_patient_care_plans(i_lang       => i_lang,
                                                         i_prof       => i_prof,
                                                         i_id_patient => i_patient,
                                                         i_num_reg    => NULL,
                                                         o_care_plans => o_care_plans,
                                                         o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL PK_IMMUNIZATION_UX.GET_CARE_DASH_VACC';
        IF NOT pk_immunization_ux.get_care_dash_vacc(i_lang    => i_lang,
                                                     i_prof    => i_prof,
                                                     i_patient => i_patient,
                                                     o_vacc    => o_vacc,
                                                     o_error   => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL PK_PATIENT_SUMMARY.GET_REPORTED_MEDICATION';
        IF NOT pk_patient_summary.get_reported_medication(i_lang            => i_lang,
                                                          i_prof            => i_prof,
                                                          i_patient         => i_patient,
                                                          i_episode         => i_episode,
                                                          o_prev_medication => o_prev_medication,
                                                          o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL PK_TAB_BUTTON.GET_PROF_TAB_BUTTON';
        IF NOT pk_tab_button.get_prof_tab_button(i_lang       => i_lang,
                                                 i_prof       => i_prof,
                                                 i_subject    => l_dasboard_subject,
                                                 o_tab_button => o_dashboard_tabs,
                                                 o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL PK_VITAL_SIGN.GET_PAT_VITAL_SIGN';
        IF NOT pk_vital_sign.get_pat_vital_sign(i_lang     => i_lang,
                                                i_patient  => i_patient,
                                                i_prof     => i_prof,
                                                i_flg_view => 'OD',
                                                o_sign_v   => o_vs,
                                                o_error    => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL PK_DIAGNOSIS.GET_CANCER_DIAGNOSIS_LIST';
        IF NOT pk_diagnosis.get_cancer_diagnosis_list(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_id_patient => i_patient,
                                                      o_cursor     => o_diagnosis,
                                                      o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL PK_PATIENT_SUMMARY.GET_PAT_VITAL_SIGN';
        IF NOT pk_patient_summary.get_assessment_tools(i_lang             => i_lang,
                                                       i_prof             => i_prof,
                                                       i_patient          => i_patient,
                                                       i_episode          => i_episode,
                                                       o_assessment_tools => o_assessment_tools,
                                                       o_error            => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL PK_PATIENT_SUMMARY.GET_CANCER_PLAN';
        IF NOT pk_patient_summary.get_cancer_plan(i_lang               => i_lang,
                                                  i_prof               => i_prof,
                                                  i_patient            => i_patient,
                                                  i_episode            => i_episode,
                                                  o_doc_area_register  => o_doc_area_register,
                                                  o_doc_area_component => o_doc_area_component,
                                                  o_doc_area_val       => o_doc_area_val,
                                                  o_error              => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL PK_PATIENT_SUMMARY.GET_ANALYSIS_RESULT';
        IF NOT pk_patient_summary.get_analysis_result(i_lang     => i_lang,
                                                      i_prof     => i_prof,
                                                      i_patient  => i_patient,
                                                      o_analysis => o_analysis,
                                                      o_error    => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_problems);
            pk_types.open_my_cursor(o_prev_contact);
            pk_types.open_my_cursor(o_alerts);
            pk_types.open_my_cursor(o_vacc);
            pk_types.open_my_cursor(o_mcdt);
            pk_types.open_my_cursor(o_health_program);
            pk_types.open_my_cursor(o_care_plans);
            pk_types.open_my_cursor(o_prev_medication);
            pk_types.open_my_cursor(o_dashboard_tabs);
            pk_types.open_my_cursor(o_vs);
            pk_types.open_my_cursor(o_analysis);
            pk_types.open_my_cursor(o_diagnosis);
            pk_types.open_my_cursor(o_assessment_tools);
            pk_types.open_my_cursor(o_doc_area_register);
            pk_types.open_my_cursor(o_doc_area_component);
            pk_types.open_my_cursor(o_doc_area_val);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ONCOLOGY_DASHBOARD',
                                              o_error);
            pk_types.open_my_cursor(o_problems);
            pk_types.open_my_cursor(o_prev_contact);
            pk_types.open_my_cursor(o_alerts);
            pk_types.open_my_cursor(o_vacc);
            pk_types.open_my_cursor(o_mcdt);
            pk_types.open_my_cursor(o_health_program);
            pk_types.open_my_cursor(o_care_plans);
            pk_types.open_my_cursor(o_prev_medication);
            pk_types.open_my_cursor(o_dashboard_tabs);
            pk_types.open_my_cursor(o_vs);
            pk_types.open_my_cursor(o_analysis);
            pk_types.open_my_cursor(o_diagnosis);
            pk_types.open_my_cursor(o_assessment_tools);
            pk_types.open_my_cursor(o_doc_area_register);
            pk_types.open_my_cursor(o_doc_area_component);
            pk_types.open_my_cursor(o_doc_area_val);
        
            RETURN FALSE;
    END get_oncology_dashboard;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END pk_patient_summary;
/
