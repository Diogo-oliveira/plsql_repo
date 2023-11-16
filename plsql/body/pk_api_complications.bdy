/*-- Last Change Revision: $Rev: 2026670 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:31 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_complications IS

    -- Private variable declarations
    g_general_error EXCEPTION;

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Function and procedure implementations

    /********************************************************************************************
    * Gets the list of analysis for a given episode or patient (only the ones with results)
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_patient                   Patient id
    * @param   i_visit                     Visit id
    * @param   i_type                      'AT' - Associated task; 'TP' - Treatment performed
    * @param   o_analysis                  Analysis list
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  José Silva
    * @version v2.6
    * @since   30-12-2009
    ********************************************************************************************/
    FUNCTION get_analysis
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_visit       IN visit.id_visit%TYPE,
        i_context     IN epis_comp_detail.id_context_new%TYPE DEFAULT NULL,
        i_flg_context IN epis_comp_detail.id_sys_list%TYPE DEFAULT NULL,
        i_type        IN VARCHAR2,
        o_analysis    OUT api_comp_cur,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_ANALYSIS';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'OPEN o_analysis';
        IF i_flg_context IS NULL
        THEN
        
            OPEN o_analysis FOR
                SELECT lte.id_analysis_req_det id_task,
                       pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                 i_prof,
                                                                 'A',
                                                                 'ANALYSIS.CODE_ANALYSIS.' || lte.id_analysis,
                                                                 NULL) desc_task,
                       epi.id_episode,
                       pk_complication_core.get_axe_typ_at_lab_test(i_lang, i_prof) flg_type,
                       pk_complication_core.get_axe_typ_at_lab_test(i_lang, i_prof) flg_context,
                       pk_date_utils.date_char_tsz(i_lang, cso.dt_ordered_by, i_prof.institution, i_prof.software) dt_task,
                       pk_date_utils.date_send_tsz(i_lang, cso.dt_ordered_by, i_prof) dt_task_send,
                       nvl(cso.id_prof_ordered_by, lte.id_prof_writes) id_prof_task,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, nvl(cso.id_prof_ordered_by, lte.id_prof_writes)) name_prof_task,
                       lte.id_prof_writes id_prof_req,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, lte.id_prof_writes) name_prof_req
                  FROM lab_tests_ea lte
                  JOIN analysis_req_det ard
                    ON (ard.id_analysis_req_det = lte.id_analysis_req_det)
                  LEFT JOIN TABLE(pk_co_sign_api.tf_co_sign_task_hist_info(i_lang, i_prof, lte.id_episode, NULL)) cso
                    ON (ard.id_co_sign_order = cso.id_co_sign_hist)
                  JOIN episode epi
                    ON (lte.id_episode = epi.id_episode OR ard.id_episode_origin = epi.id_episode)
                 WHERE epi.id_visit = nvl(i_visit, epi.id_visit)
                   AND lte.id_patient = i_patient
                   AND ((lte.flg_status_det IN (pk_lab_tests_constant.g_analysis_exec,
                                                pk_lab_tests_constant.g_analysis_review,
                                                pk_lab_tests_constant.g_analysis_result,
                                                pk_lab_tests_constant.g_analysis_read)) OR
                       (lte.flg_status_det = pk_lab_tests_constant.g_analysis_exterior AND ard.flg_col_inst = 'Y' AND
                       flg_status_harvest IS NOT NULL))
                   AND (lte.flg_status_harvest IS NULL OR
                       lte.flg_status_harvest != pk_lab_tests_constant.g_harvest_cancel)
                 ORDER BY desc_task;
        
        ELSIF i_flg_context = pk_complication_core.get_axe_typ_at_lab_test(i_lang, i_prof)
              AND i_type = pk_complication_core.g_flg_cfg_typ_assoc_task
        THEN
        
            OPEN o_analysis FOR
                SELECT lte.id_analysis_req_det id_task,
                       pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                 i_prof,
                                                                 'A',
                                                                 'ANALYSIS.CODE_ANALYSIS.' || lte.id_analysis,
                                                                 NULL) desc_task,
                       epi.id_episode,
                       i_flg_context flg_type,
                       pk_complication_core.get_axe_typ_at_lab_test(i_lang, i_prof) flg_context,
                       pk_date_utils.date_char_tsz(i_lang, cso.dt_ordered_by, i_prof.institution, i_prof.software) dt_task,
                       pk_date_utils.date_send_tsz(i_lang, cso.dt_ordered_by, i_prof) dt_task_send,
                       nvl(cso.id_prof_ordered_by, lte.id_prof_writes) id_prof_task,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, nvl(cso.id_prof_ordered_by, lte.id_prof_writes)) name_prof_task,
                       lte.id_prof_writes id_prof_req,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, lte.id_prof_writes) name_prof_req
                  FROM lab_tests_ea lte
                  JOIN analysis_req_det ard
                    ON (ard.id_analysis_req_det = lte.id_analysis_req_det)
                  LEFT JOIN TABLE(pk_co_sign_api.tf_co_sign_task_hist_info(i_lang, i_prof, lte.id_episode, NULL)) cso
                    ON (ard.id_co_sign_order = cso.id_co_sign_hist)
                  JOIN episode epi
                    ON (lte.id_episode = epi.id_episode OR ard.id_episode_origin = epi.id_episode)
                 WHERE lte.id_analysis_req_det = i_context;
        
        ELSIF i_flg_context = pk_complication_core.get_axe_typ_tp_lab_test(i_lang, i_prof)
              AND i_type = pk_complication_core.g_flg_cfg_typ_treat_perf
        THEN
        
            OPEN o_analysis FOR
                SELECT i_context id_task,
                       pk_lab_tests_api_db.get_alias_translation(i_lang, i_prof, 'A', a.code_analysis, NULL) desc_task,
                       --unused parameters
                       NULL id_episode,
                       NULL flg_type,
                       NULL flg_context,
                       NULL dt_task,
                       NULL dt_task_send,
                       NULL id_prof_task,
                       NULL name_prof_task,
                       NULL id_prof_req,
                       NULL name_prof_req
                  FROM analysis a
                 WHERE a.id_analysis = i_context;
        
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_analysis);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_analysis;

    /********************************************************************************************
    * Gets the list of imaging exams for a given episode or patient (only the ones with results)
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_patient                   Patient id
    * @param   i_visit                     Visit id
    * @param   i_type                      'AT' - Associated task; 'TP' - Treatment performed
    * @param   o_exams                     Exams list
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  José Silva
    * @version v2.6
    * @since   30-12-2009
    ********************************************************************************************/
    FUNCTION get_img_exams
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_visit       IN visit.id_visit%TYPE,
        i_context     IN epis_comp_detail.id_context_new%TYPE DEFAULT NULL,
        i_flg_context IN epis_comp_detail.id_sys_list%TYPE DEFAULT NULL,
        i_type        IN VARCHAR2,
        o_exams       OUT api_comp_cur,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_IMG_EXAMS';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'CALL TO GET_EXAMS';
        IF NOT get_exams(i_lang        => i_lang,
                         i_prof        => i_prof,
                         i_patient     => i_patient,
                         i_visit       => i_visit,
                         i_flg_type    => pk_exam_constant.g_type_img,
                         i_context     => i_context,
                         i_flg_context => i_flg_context,
                         i_type        => i_type,
                         o_exams       => o_exams,
                         o_error       => o_error)
        THEN
            RAISE g_general_error;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_exams);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_img_exams;

    /********************************************************************************************
    * Gets the list of exams for a given episode or patient (only the ones with results)
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_patient                   Patient id
    * @param   i_visit                     Visit id
    * @param   i_flg_type                  exam type
    * @param   i_type                      'AT' - Associated task; 'TP' - Treatment performed
    * @param   o_exams                     Exams list
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  José Silva
    * @version v2.6
    * @since   30-12-2009
    ********************************************************************************************/
    FUNCTION get_exams
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_visit       IN visit.id_visit%TYPE,
        i_flg_type    IN exam.flg_type%TYPE DEFAULT NULL,
        i_context     IN epis_comp_detail.id_context_new%TYPE DEFAULT NULL,
        i_flg_context IN epis_comp_detail.id_sys_list%TYPE DEFAULT NULL,
        i_type        IN VARCHAR2,
        o_exams       OUT api_comp_cur,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_EXAMS';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'OPEN o_exams';
        IF i_context IS NULL
        THEN
        
            OPEN o_exams FOR
                SELECT eea.id_exam_req_det id_task,
                       pk_exams_api_db.get_alias_translation(i_lang, i_prof, 'EXAM.CODE_EXAM.' || eea.id_exam, NULL) desc_task,
                       eea.id_episode,
                       decode(eea.flg_type,
                              pk_exam_constant.g_type_img,
                              pk_complication_core.get_axe_typ_at_imaging(i_lang, i_prof),
                              pk_complication_core.get_axe_typ_at_exam(i_lang, i_prof)) flg_type,
                       decode(eea.flg_type,
                              pk_exam_constant.g_type_img,
                              pk_complication_core.get_axe_typ_at_imaging(i_lang, i_prof),
                              pk_complication_core.get_axe_typ_at_exam(i_lang, i_prof)) flg_context,
                       pk_date_utils.date_char_tsz(i_lang,
                                                   nvl(cso.dt_ordered_by, eea.dt_req),
                                                   i_prof.institution,
                                                   i_prof.software) dt_task,
                       pk_date_utils.date_send_tsz(i_lang, nvl(cso.dt_ordered_by, eea.dt_req), i_prof) dt_task_send,
                       nvl(cso.id_prof_ordered_by, eea.id_prof_req) id_prof_task,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, nvl(cso.id_prof_ordered_by, eea.id_prof_req)) name_prof_task,
                       eea.id_prof_req,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, eea.id_prof_req) name_prof_req
                  FROM exams_ea eea
                  JOIN exam_req_det erd
                    ON (erd.id_exam_req_det = eea.id_exam_req_det)
                  LEFT JOIN TABLE(pk_co_sign_api.tf_co_sign_task_hist_info(i_lang, i_prof, eea.id_episode, NULL)) cso
                    ON (erd.id_co_sign_order = cso.id_co_sign_hist)
                  JOIN episode e
                    ON (eea.id_episode = e.id_episode)
                 WHERE e.id_visit = nvl(i_visit, e.id_visit)
                   AND eea.id_patient = i_patient
                   AND ((eea.flg_type != pk_exam_constant.g_type_img AND i_flg_type IS NULL) OR
                       eea.flg_type = i_flg_type)
                   AND eea.flg_status_det IN (pk_exam_constant.g_exam_toexec,
                                              pk_exam_constant.g_exam_exec,
                                              pk_exam_constant.g_exam_partial,
                                              pk_exam_constant.g_exam_result,
                                              pk_exam_constant.g_exam_read)
                 ORDER BY desc_task;
        
        ELSIF i_flg_context IN (pk_complication_core.get_axe_typ_at_imaging(i_lang, i_prof),
                                pk_complication_core.get_axe_typ_at_exam(i_lang, i_prof))
              AND i_type = pk_complication_core.g_flg_cfg_typ_assoc_task
        THEN
        
            OPEN o_exams FOR
                SELECT eea.id_exam_req_det id_task,
                       pk_exams_api_db.get_alias_translation(i_lang, i_prof, 'EXAM.CODE_EXAM.' || eea.id_exam, NULL) desc_task,
                       eea.id_episode,
                       decode(eea.flg_type,
                              pk_exam_constant.g_type_img,
                              pk_complication_core.get_axe_typ_at_imaging(i_lang, i_prof),
                              pk_complication_core.get_axe_typ_at_exam(i_lang, i_prof)) flg_type,
                       decode(eea.flg_type,
                              pk_exam_constant.g_type_img,
                              pk_complication_core.get_axe_typ_at_imaging(i_lang, i_prof),
                              pk_complication_core.get_axe_typ_at_exam(i_lang, i_prof)) flg_context,
                       pk_date_utils.date_char_tsz(i_lang,
                                                   nvl(cso.dt_ordered_by, eea.dt_req),
                                                   i_prof.institution,
                                                   i_prof.software) dt_task,
                       pk_date_utils.date_send_tsz(i_lang, nvl(cso.dt_ordered_by, eea.dt_req), i_prof) dt_task_send,
                       nvl(cso.id_prof_ordered_by, eea.id_prof_req) id_prof_task,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, nvl(cso.id_prof_ordered_by, eea.id_prof_req)) name_prof_task,
                       eea.id_prof_req,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, eea.id_prof_req) name_prof_req
                  FROM exams_ea eea
                  JOIN exam_req_det erd
                    ON (erd.id_exam_req_det = eea.id_exam_req_det)
                  LEFT JOIN TABLE(pk_co_sign_api.tf_co_sign_task_hist_info(i_lang, i_prof, eea.id_episode, NULL)) cso
                    ON (erd.id_co_sign_order = cso.id_co_sign_hist)
                 WHERE eea.id_exam_req_det = i_context;
        
        ELSIF i_flg_context IN (pk_complication_core.get_axe_typ_tp_imaging(i_lang, i_prof),
                                pk_complication_core.get_axe_typ_tp_exam(i_lang, i_prof))
              AND i_type = pk_complication_core.g_flg_cfg_typ_treat_perf
        THEN
        
            OPEN o_exams FOR
                SELECT e.id_exam id_task,
                       pk_exams_api_db.get_alias_translation(i_lang, i_prof, e.code_exam, NULL) desc_task,
                       -- unused parameters
                       NULL id_episode,
                       NULL flg_type,
                       NULL flg_context,
                       NULL dt_task,
                       NULL dt_task_send,
                       NULL id_prof_task,
                       NULL name_prof_task,
                       NULL id_prof_req,
                       NULL name_prof_req
                  FROM exam e
                 WHERE id_exam = i_context;
        
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_exams);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_exams;

    /********************************************************************************************
    * Gets the list of diets for a given episode or patient
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_patient                   Patient id
    * @param   i_episode                   Episode id
    * @param   i_type                      'AT' - Associated task; 'TP' - Treatment performed
    * @param   o_diet                      Diet list
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  José Silva
    * @version v2.6
    * @since   30-12-2009
    ********************************************************************************************/
    FUNCTION get_diets
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_context     IN epis_comp_detail.id_context_new%TYPE DEFAULT NULL,
        i_flg_context IN epis_comp_detail.id_sys_list%TYPE DEFAULT NULL,
        i_type        IN VARCHAR2,
        o_diet        OUT api_comp_cur,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_DIETS';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'OPEN o_diet';
        IF i_flg_context IS NULL
        THEN
        
            OPEN o_diet FOR
                SELECT edr.id_epis_diet_req id_task,
                       nvl(desc_diet, pk_translation.get_translation(i_lang, dt.code_diet_type)) desc_task,
                       edr.id_episode,
                       pk_complication_core.get_axe_typ_at_diet(i_lang, i_prof) flg_type,
                       pk_complication_core.get_axe_typ_at_diet(i_lang, i_prof) flg_context,
                       pk_date_utils.date_char_tsz(i_lang, edr.dt_creation, i_prof.institution, i_prof.software) dt_task,
                       pk_date_utils.date_send_tsz(i_lang, edr.dt_creation, i_prof) dt_task_send,
                       edr.id_professional id_prof_task,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, edr.id_professional) name_prof_task,
                       edr.id_professional id_prof_req,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, edr.id_professional) name_prof_req
                  FROM epis_diet_req edr
                  JOIN diet_type dt
                    ON (edr.id_diet_type = dt.id_diet_type)
                 WHERE edr.id_patient = i_patient
                   AND NOT EXISTS (SELECT 1
                          FROM epis_diet_req e
                         WHERE edr.id_epis_diet_req = e.id_epis_diet_req_parent)
                   AND edr.id_episode = nvl(i_episode, edr.id_episode)
                   AND edr.flg_status <> 'C'
                   AND edr.dt_inicial < current_timestamp
                 ORDER BY desc_task;
        
        ELSIF i_flg_context = pk_complication_core.get_axe_typ_at_diet(i_lang, i_prof)
              AND i_type = pk_complication_core.g_flg_cfg_typ_assoc_task
        THEN
        
            OPEN o_diet FOR
                SELECT edr.id_epis_diet_req id_task,
                       nvl(desc_diet, pk_translation.get_translation(i_lang, dt.code_diet_type)) desc_task,
                       edr.id_episode,
                       pk_complication_core.get_axe_typ_at_diet(i_lang, i_prof) flg_type,
                       pk_complication_core.get_axe_typ_at_diet(i_lang, i_prof) flg_context,
                       pk_date_utils.date_char_tsz(i_lang, edr.dt_creation, i_prof.institution, i_prof.software) dt_task,
                       pk_date_utils.date_send_tsz(i_lang, edr.dt_creation, i_prof) dt_task_send,
                       edr.id_professional id_prof_task,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, edr.id_professional) name_prof_task,
                       edr.id_professional id_prof_req,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, edr.id_professional) name_prof_req
                  FROM epis_diet_req edr
                  JOIN diet_type dt
                    ON (edr.id_diet_type = dt.id_diet_type)
                 WHERE edr.id_epis_diet_req = i_context;
        
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_diet);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_diets;

    /********************************************************************************************
    * Gets the list of medication for a given episode or patient (only the ones administered)
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_patient                   Patient id
    * @param   i_visit                     Visit id
    * @param   i_episode                   Episode id
    * @param   i_type                      'AT' - Associated task; 'TP' - Treatment performed
    * @param   o_med                       Medication list
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  José Silva
    * @version v2.6
    * @since   30-12-2009
    ********************************************************************************************/
    FUNCTION get_medication
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_visit       IN visit.id_visit%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_context     IN epis_comp_detail.id_context_new%TYPE DEFAULT NULL,
        i_flg_context IN epis_comp_detail.id_sys_list%TYPE DEFAULT NULL,
        i_type        IN VARCHAR2,
        o_med         OUT api_comp_cur,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_MEDICATION';
    
        l_exception EXCEPTION;
    
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        IF i_flg_context IS NULL
        THEN
        
            g_error := 'CALL TO get_compl_epis_medication';
            IF NOT pk_api_pfh_clindoc_in.get_compl_epis_medication(i_lang    => i_lang,
                                                                   i_prof    => i_prof,
                                                                   i_patient => i_patient,
                                                                   i_visit   => i_visit,
                                                                   i_episode => i_episode,
                                                                   o_med     => o_med,
                                                                   o_error   => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
        ELSIF i_flg_context = pk_complication_core.get_ecd_typ_med_ext(i_lang, i_prof)
              AND i_type = pk_complication_core.g_flg_cfg_typ_assoc_task
        THEN
        
            g_error := 'CALL TO get_compl_out_medication';
            IF NOT pk_api_pfh_clindoc_in.get_compl_out_medication(i_lang               => i_lang,
                                                                  i_prof               => i_prof,
                                                                  i_episode            => i_episode,
                                                                  i_prescription_pharm => i_context,
                                                                  o_med                => o_med,
                                                                  o_error              => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
        ELSIF i_flg_context = pk_complication_core.get_ecd_typ_med_lcl(i_lang, i_prof)
              AND i_type = pk_complication_core.g_flg_cfg_typ_assoc_task
        THEN
        
            g_error := 'CALL TO get_compl_drug_presc';
            IF NOT pk_api_pfh_clindoc_in.get_compl_drug_presc(i_lang           => i_lang,
                                                              i_prof           => i_prof,
                                                              i_episode        => i_episode,
                                                              i_drug_presc_det => i_context,
                                                              o_med            => o_med,
                                                              o_error          => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
        ELSIF i_flg_context = pk_complication_core.get_axe_typ_tp_med_grp(i_lang, i_prof)
              AND i_type = pk_complication_core.g_flg_cfg_typ_treat_perf
        THEN
        
            g_error := 'CALL TO get_compl_pharm_group';
            IF NOT pk_api_pfh_clindoc_in.get_compl_pharm_group(i_lang        => i_lang,
                                                               i_prof        => i_prof,
                                                               i_pharm_group => i_context,
                                                               i_episode     => i_episode,
                                                               o_med         => o_med,
                                                               o_error       => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
        ELSIF i_flg_context = pk_complication_core.get_axe_typ_tp_med(i_lang, i_prof)
              AND i_type = pk_complication_core.g_flg_cfg_typ_treat_perf
        THEN
        
            g_error := 'CALL TO get_compl_drug';
            IF NOT pk_api_pfh_clindoc_in.get_compl_drug(i_lang    => i_lang,
                                                        i_prof    => i_prof,
                                                        i_drug    => i_context,
                                                        i_episode => i_episode,
                                                        o_med     => o_med,
                                                        o_error   => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
        ELSIF i_flg_context = pk_complication_core.get_axe_typ_tp_out_med_grp(i_lang, i_prof)
              AND i_type = pk_complication_core.g_flg_cfg_typ_treat_perf
        THEN
        
            g_error := 'CALL TO get_compl_out_med_group';
            IF NOT pk_api_pfh_clindoc_in.get_compl_out_med_group(i_lang        => i_lang,
                                                                 i_prof        => i_prof,
                                                                 i_pharm_group => i_context,
                                                                 i_episode     => i_episode,
                                                                 o_med         => o_med,
                                                                 o_error       => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
        ELSIF i_flg_context = pk_complication_core.get_axe_typ_tp_out_med(i_lang, i_prof)
              AND i_type = pk_complication_core.g_flg_cfg_typ_treat_perf
        THEN
        
            g_error := 'CALL TO get_compl_out_drug';
            IF NOT pk_api_pfh_clindoc_in.get_compl_out_drug(i_lang    => i_lang,
                                                            i_prof    => i_prof,
                                                            i_emb_id  => i_context,
                                                            i_episode => i_episode,
                                                            o_med     => o_med,
                                                            o_error   => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_med);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_medication;

    /********************************************************************************************
    * Gets the list of positiongs for a given episode or patient
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_patient                   Patient id
    * @param   i_episode                   Episode id
    * @param   i_type                      'AT' - Associated task; 'TP' - Treatment performed
    * @param   o_positioning               Positioning list
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  José Silva
    * @version v2.6
    * @since   30-12-2009
    ********************************************************************************************/
    FUNCTION get_positioning
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_context     IN epis_comp_detail.id_context_new%TYPE DEFAULT NULL,
        i_flg_context IN epis_comp_detail.id_sys_list%TYPE DEFAULT NULL,
        i_type        IN VARCHAR2,
        o_positioning OUT api_comp_cur,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_POSITIONING';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'OPEN o_positioning';
        IF i_flg_context IS NULL
        THEN
        
            OPEN o_positioning FOR
            -- INP Positioning
                SELECT ep.id_epis_positioning id_task,
                       pk_inp_positioning.get_all_posit_desc(i_lang, i_prof, ep.id_epis_positioning) desc_task,
                       e.id_episode,
                       pk_complication_core.get_axe_typ_at_pos(i_lang, i_prof) flg_type,
                       pk_complication_core.get_axe_typ_at_pos(i_lang, i_prof) flg_context,
                       pk_date_utils.date_char_tsz(i_lang, ep.dt_creation_tstz, i_prof.institution, i_prof.software) dt_task,
                       pk_date_utils.date_send_tsz(i_lang, ep.dt_creation_tstz, i_prof) dt_task_send,
                       ep.id_professional id_prof_task,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, ep.id_professional) name_prof_task,
                       ep.id_professional id_prof_req,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, ep.id_professional) name_prof_req
                  FROM epis_positioning ep
                  JOIN episode e
                    ON (ep.id_episode = e.id_episode)
                 WHERE ep.id_episode = nvl(i_episode, ep.id_episode)
                   AND e.id_patient = i_patient
                   AND ep.flg_status NOT IN ('C', 'D', 'L', 'R')
                
                UNION ALL
                -- ORIS positioning
                SELECT r.id_sr_posit_req id_task,
                       pk_translation.get_translation(i_lang, sp.code_sr_posit) desc_task,
                       e.id_episode,
                       pk_complication_core.get_axe_typ_at_pos(i_lang, i_prof) flg_type,
                       pk_complication_core.get_ecd_typ_pos(i_lang, i_prof) flg_context,
                       pk_date_utils.date_char_tsz(i_lang, r.dt_posit_req_tstz, i_prof.institution, i_prof.software) dt_task,
                       pk_date_utils.date_send_tsz(i_lang, r.dt_posit_req_tstz, i_prof) dt_task_send,
                       r.id_prof_req id_prof_task,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, r.id_prof_req) name_prof_task,
                       r.id_prof_req,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, r.id_prof_req) name_prof_req
                  FROM sr_posit_req r
                  JOIN sr_posit sp
                    ON (r.id_sr_posit = sp.id_sr_posit)
                  JOIN episode e
                    ON (r.id_episode_context = e.id_episode)
                 WHERE r.id_episode_context = nvl(i_episode, r.id_episode_context)
                   AND e.id_patient = i_patient
                   AND r.flg_status IN ('P', 'F')
                 ORDER BY desc_task;
        
        ELSIF i_flg_context = pk_complication_core.get_axe_typ_at_pos(i_lang, i_prof)
              AND i_type = pk_complication_core.g_flg_cfg_typ_assoc_task
        THEN
        
            OPEN o_positioning FOR
            -- INP Positioning
                SELECT ep.id_epis_positioning id_task,
                       pk_inp_positioning.get_all_posit_desc(i_lang, i_prof, ep.id_epis_positioning) desc_task,
                       ep.id_episode,
                       pk_complication_core.get_axe_typ_at_pos(i_lang, i_prof) flg_type,
                       pk_complication_core.get_axe_typ_at_pos(i_lang, i_prof) flg_context,
                       pk_date_utils.date_char_tsz(i_lang, ep.dt_creation_tstz, i_prof.institution, i_prof.software) dt_task,
                       pk_date_utils.date_send_tsz(i_lang, ep.dt_creation_tstz, i_prof) dt_task_send,
                       ep.id_professional id_prof_task,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, ep.id_professional) name_prof_task,
                       ep.id_professional id_prof_req,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, ep.id_professional) name_prof_req
                  FROM epis_positioning ep
                 WHERE ep.id_epis_positioning = i_context;
        
        ELSIF i_flg_context = pk_complication_core.get_ecd_typ_pos(i_lang, i_prof)
              AND i_type = pk_complication_core.g_flg_cfg_typ_assoc_task
        THEN
        
            OPEN o_positioning FOR
            -- ORIS positioning
                SELECT r.id_sr_posit_req id_task,
                       pk_translation.get_translation(i_lang, sp.code_sr_posit) desc_task,
                       r.id_episode_context id_episode,
                       pk_complication_core.get_axe_typ_at_pos(i_lang, i_prof) flg_type,
                       pk_complication_core.get_ecd_typ_pos(i_lang, i_prof) flg_context,
                       pk_date_utils.date_char_tsz(i_lang, r.dt_posit_req_tstz, i_prof.institution, i_prof.software) dt_task,
                       pk_date_utils.date_send_tsz(i_lang, r.dt_posit_req_tstz, i_prof) dt_task_send,
                       r.id_prof_req id_prof_task,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, r.id_prof_req) name_prof_task,
                       r.id_prof_req,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, r.id_prof_req) name_prof_req
                  FROM sr_posit_req r
                  JOIN sr_posit sp
                    ON (r.id_sr_posit = sp.id_sr_posit)
                 WHERE r.id_sr_posit_req = i_context;
        
        ELSIF i_flg_context = pk_complication_core.get_axe_typ_tp_pos(i_lang, i_prof)
              AND i_type = pk_complication_core.g_flg_cfg_typ_treat_perf
        THEN
        
            OPEN o_positioning FOR
                SELECT p.id_positioning id_task,
                       pk_translation.get_translation(i_lang, code_positioning) desc_task,
                       -- unused parameters
                       NULL id_episode,
                       NULL flg_type,
                       NULL flg_context,
                       NULL dt_task,
                       NULL dt_task_send,
                       NULL id_prof_task,
                       NULL name_prof_task,
                       NULL id_prof_req,
                       NULL name_prof_req
                  FROM positioning p
                 WHERE p.id_positioning = i_context;
        
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_positioning);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_positioning;

    /********************************************************************************************
    * Gets the list of procedures for a given episode or patient (only the ones finalized)
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_patient                   Patient id
    * @param   i_visit                     Visit id
    * @param   i_type                      'AT' - Associated task; 'TP' - Treatment performed
    * @param   o_procedures                Procedures list
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  José Silva
    * @version v2.6
    * @since   30-12-2009
    ********************************************************************************************/
    FUNCTION get_procedures
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_visit       IN visit.id_visit%TYPE,
        i_context     IN epis_comp_detail.id_context_new%TYPE DEFAULT NULL,
        i_flg_context IN epis_comp_detail.id_sys_list%TYPE DEFAULT NULL,
        i_type        IN VARCHAR2,
        o_procedures  OUT api_comp_cur,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_PROCEDURES';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'OPEN o_procedures';
        IF i_flg_context IS NULL
        THEN
        
            OPEN o_procedures FOR
                SELECT pea.id_interv_presc_det id_task,
                       pk_procedures_api_db.get_alias_translation(i_lang, i_prof, i.code_intervention, NULL) desc_task,
                       pea.id_episode,
                       pk_complication_core.get_axe_typ_at_proc(i_lang, i_prof) flg_type,
                       pk_complication_core.get_axe_typ_at_proc(i_lang, i_prof) flg_context,
                       pk_date_utils.date_char_tsz(i_lang, pea.dt_order, i_prof.institution, i_prof.software) dt_task,
                       pk_date_utils.date_send_tsz(i_lang, pea.dt_order, i_prof) dt_task_send,
                       nvl(pea.id_prof_order, pea.id_professional) id_prof_task,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, nvl(pea.id_prof_order, pea.id_professional)) name_prof_task,
                       pea.id_professional id_prof_req,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, pea.id_professional) name_prof_req
                  FROM procedures_ea pea
                  JOIN intervention i
                    ON (i.id_intervention = pea.id_intervention)
                 WHERE pea.id_visit = nvl(i_visit, pea.id_visit)
                   AND pea.id_patient = i_patient
                   AND pea.flg_status_det IN ('E', 'S', 'F', 'I')
                 ORDER BY desc_task;
        
        ELSIF i_flg_context = pk_complication_core.get_axe_typ_at_proc(i_lang, i_prof)
              AND i_type = pk_complication_core.g_flg_cfg_typ_assoc_task
        THEN
        
            OPEN o_procedures FOR
                SELECT pea.id_interv_presc_det id_task,
                       pk_procedures_api_db.get_alias_translation(i_lang, i_prof, i.code_intervention, NULL) desc_task,
                       pea.id_episode,
                       pk_complication_core.get_axe_typ_at_proc(i_lang, i_prof) flg_type,
                       pk_complication_core.get_axe_typ_at_proc(i_lang, i_prof) flg_context,
                       pk_date_utils.date_char_tsz(i_lang, pea.dt_order, i_prof.institution, i_prof.software) dt_task,
                       pk_date_utils.date_send_tsz(i_lang, pea.dt_order, i_prof) dt_task_send,
                       nvl(pea.id_prof_order, pea.id_professional) id_prof_task,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, nvl(pea.id_prof_order, pea.id_professional)) name_prof_task,
                       pea.id_professional id_prof_req,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, pea.id_professional) name_prof_req
                  FROM procedures_ea pea
                  JOIN intervention i
                    ON (i.id_intervention = pea.id_intervention)
                 WHERE pea.id_interv_presc_det = i_context;
        
        ELSIF i_flg_context = pk_complication_core.get_axe_typ_tp_proc(i_lang, i_prof)
              AND i_type = pk_complication_core.g_flg_cfg_typ_treat_perf
        THEN
        
            OPEN o_procedures FOR
                SELECT i.id_intervention id_task,
                       pk_procedures_api_db.get_alias_translation(i_lang, i_prof, i.code_intervention, NULL) desc_task,
                       -- unused parameters
                       NULL id_episode,
                       NULL flg_type,
                       NULL flg_context,
                       NULL dt_task,
                       NULL dt_task_send,
                       NULL id_prof_task,
                       NULL name_prof_task,
                       NULL id_prof_req,
                       NULL name_prof_req
                  FROM intervention i
                 WHERE i.id_intervention = i_context;
        
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_procedures);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_procedures;

    /********************************************************************************************
    * Gets the list of surgical procedures for a given episode or patient (only the ones finalized)
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_patient                   Patient id
    * @param   i_episode                   Episode id
    * @param   i_type                      'AT' - Associated task; 'TP' - Treatment performed
    * @param   o_procedures                Procedures list
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  José Silva
    * @version v2.6
    * @since   30-12-2009
    ********************************************************************************************/
    FUNCTION get_surgical_procedures
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_context     IN epis_comp_detail.id_context_new%TYPE DEFAULT NULL,
        i_flg_context IN epis_comp_detail.id_sys_list%TYPE DEFAULT NULL,
        i_type        IN VARCHAR2,
        o_procedures  OUT api_comp_cur,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_SURGICAL_PROCEDURES';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'OPEN o_procedures';
        IF i_flg_context IS NULL
        THEN
        
            OPEN o_procedures FOR
                SELECT sei.id_sr_epis_interv id_task,
                       nvl(sei.name_interv,
                           pk_translation.get_translation(i_lang, si.code_intervention) || ' / ' ||
                           to_char(ic.standard_code)) desc_task,
                       sei.id_episode,
                       pk_complication_core.get_axe_typ_at_surg_proc(i_lang, i_prof) flg_type,
                       pk_complication_core.get_axe_typ_at_surg_proc(i_lang, i_prof) flg_context,
                       pk_date_utils.date_char_tsz(i_lang, sei.dt_req_tstz, i_prof.institution, i_prof.software) dt_task,
                       pk_date_utils.date_send_tsz(i_lang, sei.dt_req_tstz, i_prof) dt_task_send,
                       sei.id_prof_req id_prof_task,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, sei.id_prof_req) name_prof_task,
                       sei.id_prof_req,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, sei.id_prof_req) name_prof_req
                  FROM sr_epis_interv sei
                  JOIN intervention si
                    ON (sei.id_sr_intervention = si.id_intervention)
                  JOIN interv_codification ic
                    ON ic.id_intervention = si.id_intervention
                  JOIN episode e
                    ON (sei.id_episode_context = e.id_episode)
                 WHERE sei.id_episode_context = nvl(i_episode, sei.id_episode_context)
                   AND e.id_patient = i_patient
                   AND sei.flg_status IN ('E', 'F')
                 ORDER BY desc_task;
        
        ELSIF i_flg_context = pk_complication_core.get_axe_typ_at_surg_proc(i_lang, i_prof)
              AND i_type = pk_complication_core.g_flg_cfg_typ_assoc_task
        THEN
        
            OPEN o_procedures FOR
                SELECT sei.id_sr_epis_interv id_task,
                       nvl(sei.name_interv,
                           pk_translation.get_translation(i_lang, si.code_intervention) || ' / ' ||
                           to_char(ic.standard_code)) desc_task,
                       sei.id_episode,
                       pk_complication_core.get_axe_typ_at_surg_proc(i_lang, i_prof) flg_type,
                       pk_complication_core.get_axe_typ_at_surg_proc(i_lang, i_prof) flg_context,
                       pk_date_utils.date_char_tsz(i_lang, sei.dt_req_tstz, i_prof.institution, i_prof.software) dt_task,
                       pk_date_utils.date_send_tsz(i_lang, sei.dt_req_tstz, i_prof) dt_task_send,
                       sei.id_prof_req id_prof_task,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, sei.id_prof_req) name_prof_task,
                       sei.id_prof_req,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, sei.id_prof_req) name_prof_req
                  FROM sr_epis_interv sei
                  JOIN intervention si
                    ON (sei.id_sr_intervention = si.id_intervention)
                  JOIN interv_codification ic
                    ON ic.id_intervention = si.id_intervention
                 WHERE sei.id_sr_epis_interv = i_context;
        
        ELSIF i_flg_context = pk_complication_core.get_axe_typ_tp_surg_proc(i_lang, i_prof)
              AND i_type = pk_complication_core.g_flg_cfg_typ_treat_perf
        THEN
        
            OPEN o_procedures FOR
                SELECT si.id_intervention id_task,
                       pk_translation.get_translation(i_lang, si.code_intervention) || ' / ' ||
                       to_char(ic.standard_code) desc_task,
                       -- unused parameters
                       NULL id_episode,
                       NULL flg_type,
                       NULL flg_context,
                       NULL dt_task,
                       NULL dt_task_send,
                       NULL id_prof_task,
                       NULL name_prof_task,
                       NULL id_prof_req,
                       NULL name_prof_req
                  FROM intervention si
                 INNER JOIN interv_codification ic
                    ON si.id_intervention = ic.id_intervention
                 WHERE si.id_intervention = i_context;
        
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_procedures);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_surgical_procedures;

    /********************************************************************************************
    * Includes a new type of task to the tasks list
    *
    * @param   i_lang       Professional preferred language
    * @param   i_prof       Professional identification and its context (institution and software)
    * @param   i_tasks      New tasks to include
    * @param   i_task       Type of task to include
    * @param   i_type_tasks Type of tasks that were already fetched
    * @param   i_id_task    Tasks that were already fetched (IDs)
    * @param   i_desc_task  Tasks that were already fetched (descriptions)
    * @param   i_id_epis    Tasks that were already fetched (episode ID in which the task occured)
    * @param   i_flg_type   Tasks that were already fetched (type of task)
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  José Silva
    * @version v2.6
    * @since   04-01-2010
    ********************************************************************************************/
    FUNCTION merge_tasks
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_tasks          IN api_comp_cur,
        i_task           IN comp_axe.id_sys_list%TYPE,
        i_type_tasks     IN OUT table_varchar,
        i_id_task        IN OUT table_number,
        i_desc_task      IN OUT table_varchar,
        i_id_epis        IN OUT table_number,
        i_flg_type       IN OUT table_number,
        i_flg_context    IN OUT table_number,
        i_dt_task        IN OUT table_varchar,
        i_dt_task_send   IN OUT table_varchar,
        i_id_prof_task   IN OUT table_number,
        i_name_prof_task IN OUT table_varchar,
        i_id_prof_req    IN OUT table_number,
        i_name_prof_req  IN OUT table_varchar,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'MERGE_TASKS';
    
        l_aux_id_task      table_number;
        l_aux_desc_task    table_varchar;
        l_aux_id_episode   table_number;
        l_aux_flg_type     table_number;
        l_aux_flg_context  table_number;
        l_aux_dt_task      table_varchar;
        l_aux_dt_task_send table_varchar;
        l_aux_id_prof      table_number;
        l_aux_name_prof    table_varchar;
        l_aux_id_prof_req  table_number;
        l_aux_name_req     table_varchar;
        l_count            NUMBER;
    
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'FETCH TASKS';
        FETCH i_tasks BULK COLLECT
            INTO l_aux_id_task,
                 l_aux_desc_task,
                 l_aux_id_episode,
                 l_aux_flg_type,
                 l_aux_flg_context,
                 l_aux_dt_task,
                 l_aux_dt_task_send,
                 l_aux_id_prof,
                 l_aux_name_prof,
                 l_aux_id_prof_req,
                 l_aux_name_req;
        CLOSE i_tasks;
    
        IF l_aux_id_task.count > 0
        THEN
            g_error := 'SET TYPE TASK';
            l_count := i_type_tasks.count + 1;
            i_type_tasks.extend;
            i_type_tasks(l_count) := i_task;
        
            g_error := 'MERGE ID_TASK';
            FOR i IN 1 .. l_aux_id_task.count
            LOOP
                l_count := i_id_task.count + 1;
                i_id_task.extend;
                i_id_task(l_count) := l_aux_id_task(i);
            END LOOP;
        
            g_error := 'MERGE DESC_TASK';
            FOR i IN 1 .. l_aux_desc_task.count
            LOOP
                l_count := i_desc_task.count + 1;
                i_desc_task.extend;
                i_desc_task(l_count) := l_aux_desc_task(i);
            END LOOP;
        
            g_error := 'MERGE ID_EPISODE';
            FOR i IN 1 .. l_aux_id_episode.count
            LOOP
                l_count := i_id_epis.count + 1;
                i_id_epis.extend;
                i_id_epis(l_count) := l_aux_id_episode(i);
            END LOOP;
        
            g_error := 'MERGE FLG_TYPE';
            FOR i IN 1 .. l_aux_flg_type.count
            LOOP
                l_count := i_flg_type.count + 1;
                i_flg_type.extend;
                i_flg_type(l_count) := l_aux_flg_type(i);
            END LOOP;
        
            g_error := 'MERGE FLG_CONTEXT';
            FOR i IN 1 .. l_aux_flg_context.count
            LOOP
                l_count := i_flg_context.count + 1;
                i_flg_context.extend;
                i_flg_context(l_count) := l_aux_flg_context(i);
            END LOOP;
        
            g_error := 'MERGE DT_TASK';
            FOR i IN 1 .. l_aux_dt_task.count
            LOOP
                l_count := i_dt_task.count + 1;
                i_dt_task.extend;
                i_dt_task(l_count) := l_aux_dt_task(i);
            END LOOP;
        
            g_error := 'MERGE DT_TASK_SEND';
            FOR i IN 1 .. l_aux_dt_task_send.count
            LOOP
                l_count := i_dt_task_send.count + 1;
                i_dt_task_send.extend;
                i_dt_task_send(l_count) := l_aux_dt_task_send(i);
            END LOOP;
        
            g_error := 'MERGE ID_PROF_TASK';
            FOR i IN 1 .. l_aux_id_prof.count
            LOOP
                l_count := i_id_prof_task.count + 1;
                i_id_prof_task.extend;
                i_id_prof_task(l_count) := l_aux_id_prof(i);
            END LOOP;
        
            g_error := 'MERGE NAME_PROF_TASK';
            FOR i IN 1 .. l_aux_name_prof.count
            LOOP
                l_count := i_name_prof_task.count + 1;
                i_name_prof_task.extend;
                i_name_prof_task(l_count) := l_aux_name_prof(i);
            END LOOP;
        
            g_error := 'MERGE ID_PROF_REQ';
            FOR i IN 1 .. l_aux_id_prof_req.count
            LOOP
                l_count := i_id_prof_req.count + 1;
                i_id_prof_req.extend;
                i_id_prof_req(l_count) := l_aux_id_prof_req(i);
            END LOOP;
        
            g_error := 'MERGE NAME_PROF_REQ';
            FOR i IN 1 .. l_aux_name_req.count
            LOOP
                l_count := i_name_prof_req.count + 1;
                i_name_prof_req.extend;
                i_name_prof_req(l_count) := l_aux_name_req(i);
            END LOOP;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END merge_tasks;

    /********************************************************************************************
    * Gets the detail of a task
    *
    * @param   i_lang        Professional preferred language
    * @param   i_prof        Professional identification and its context (institution and software)
    * @param   i_id_task     Task ID
    * @param   i_flg_context Type of task
    * @param   i_flg_det     Type of detail description: N: task description, D: task date
    * @param   i_type        'AT' - Associated task; 'TP' - Treatment performed
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  José Silva
    * @version v2.6
    * @since   07-01-2010
    ********************************************************************************************/
    FUNCTION get_task_det
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_task     IN epis_comp_detail.id_context_new%TYPE,
        i_flg_context IN epis_comp_detail.id_sys_list%TYPE,
        i_flg_det     IN VARCHAR2,
        i_type        IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(30) := 'MERGE_TASKS';
        l_error     t_error_out;
    
        l_type_n CONSTANT VARCHAR2(1) := 'N';
        l_type_d CONSTANT VARCHAR2(1) := 'D';
    
        l_comp_rec api_comp_rec;
        l_tasks    api_comp_cur;
    
        l_inst      comp_config.id_institution%TYPE;
        l_soft      comp_config.id_software%TYPE;
        l_clin_serv comp_config.id_clinical_service%TYPE;
    
        l_exception EXCEPTION;
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        IF i_flg_context IN (pk_complication_core.get_axe_typ_at_lab_test(i_lang, i_prof),
                             pk_complication_core.get_axe_typ_tp_lab_test(i_lang, i_prof))
        THEN
        
            g_error := 'GET ANALYSIS';
            IF NOT get_analysis(i_lang        => i_lang,
                                i_prof        => i_prof,
                                i_patient     => NULL,
                                i_visit       => NULL,
                                i_context     => i_id_task,
                                i_flg_context => i_flg_context,
                                i_type        => i_type,
                                o_analysis    => l_tasks,
                                o_error       => l_error)
            THEN
                RAISE g_general_error;
            END IF;
        
        ELSIF i_flg_context IN (pk_complication_core.get_axe_typ_at_imaging(i_lang, i_prof),
                                pk_complication_core.get_axe_typ_tp_imaging(i_lang, i_prof))
        THEN
        
            g_error := 'GET IMAGE EXAMS';
            IF NOT get_img_exams(i_lang        => i_lang,
                                 i_prof        => i_prof,
                                 i_patient     => NULL,
                                 i_visit       => NULL,
                                 i_context     => i_id_task,
                                 i_flg_context => i_flg_context,
                                 i_type        => i_type,
                                 o_exams       => l_tasks,
                                 o_error       => l_error)
            THEN
                RAISE g_general_error;
            END IF;
        
        ELSIF i_flg_context IN (pk_complication_core.get_axe_typ_at_exam(i_lang, i_prof),
                                pk_complication_core.get_axe_typ_tp_exam(i_lang, i_prof))
        THEN
        
            g_error := 'GET EXAMS';
            IF NOT get_exams(i_lang        => i_lang,
                             i_prof        => i_prof,
                             i_patient     => NULL,
                             i_visit       => NULL,
                             i_context     => i_id_task,
                             i_flg_context => i_flg_context,
                             i_type        => i_type,
                             o_exams       => l_tasks,
                             o_error       => l_error)
            THEN
                RAISE g_general_error;
            END IF;
        
        ELSIF i_flg_context = pk_complication_core.get_axe_typ_at_diet(i_lang, i_prof)
        THEN
        
            g_error := 'GET DIETS';
            IF NOT get_diets(i_lang        => i_lang,
                             i_prof        => i_prof,
                             i_patient     => NULL,
                             i_episode     => NULL,
                             i_context     => i_id_task,
                             i_flg_context => i_flg_context,
                             i_type        => i_type,
                             o_diet        => l_tasks,
                             o_error       => l_error)
            THEN
                RAISE g_general_error;
            END IF;
        
        ELSIF i_flg_context IN (pk_complication_core.get_axe_typ_at_med(i_lang, i_prof),
                                pk_complication_core.get_ecd_typ_med_lcl(i_lang, i_prof),
                                pk_complication_core.get_ecd_typ_med_ext(i_lang, i_prof),
                                pk_complication_core.get_axe_typ_tp_med_grp(i_lang, i_prof),
                                pk_complication_core.get_axe_typ_tp_med(i_lang, i_prof),
                                pk_complication_core.get_axe_typ_tp_out_med_grp(i_lang, i_prof),
                                pk_complication_core.get_axe_typ_tp_out_med(i_lang, i_prof))
        THEN
        
            g_error := 'GET MEDICATION';
            IF NOT get_medication(i_lang        => i_lang,
                                  i_prof        => i_prof,
                                  i_patient     => NULL,
                                  i_visit       => NULL,
                                  i_episode     => NULL,
                                  i_context     => i_id_task,
                                  i_flg_context => i_flg_context,
                                  i_type        => i_type,
                                  o_med         => l_tasks,
                                  o_error       => l_error)
            THEN
                RAISE g_general_error;
            END IF;
        
        ELSIF i_flg_context IN (pk_complication_core.get_axe_typ_at_pos(i_lang, i_prof),
                                pk_complication_core.get_ecd_typ_pos(i_lang, i_prof),
                                pk_complication_core.get_axe_typ_tp_pos(i_lang, i_prof))
        THEN
        
            g_error := 'GET POSITIONING';
            IF NOT get_positioning(i_lang        => i_lang,
                                   i_prof        => i_prof,
                                   i_patient     => NULL,
                                   i_episode     => NULL,
                                   i_context     => i_id_task,
                                   i_flg_context => i_flg_context,
                                   i_type        => i_type,
                                   o_positioning => l_tasks,
                                   o_error       => l_error)
            THEN
                RAISE g_general_error;
            END IF;
        
        ELSIF i_flg_context IN (pk_complication_core.get_axe_typ_at_proc(i_lang, i_prof),
                                pk_complication_core.get_axe_typ_tp_proc(i_lang, i_prof))
        THEN
        
            g_error := 'GET PROCEDURES';
            IF NOT get_procedures(i_lang        => i_lang,
                                  i_prof        => i_prof,
                                  i_patient     => NULL,
                                  i_visit       => NULL,
                                  i_context     => i_id_task,
                                  i_flg_context => i_flg_context,
                                  i_type        => i_type,
                                  o_procedures  => l_tasks,
                                  o_error       => l_error)
            THEN
                RAISE g_general_error;
            END IF;
        
        ELSIF i_flg_context IN (pk_complication_core.get_axe_typ_at_surg_proc(i_lang, i_prof),
                                pk_complication_core.get_axe_typ_tp_surg_proc(i_lang, i_prof))
        THEN
        
            g_error := 'GET SR PROCEDURES';
            IF NOT get_surgical_procedures(i_lang        => i_lang,
                                           i_prof        => i_prof,
                                           i_patient     => NULL,
                                           i_episode     => NULL,
                                           i_context     => i_id_task,
                                           i_flg_context => i_flg_context,
                                           i_type        => i_type,
                                           o_procedures  => l_tasks,
                                           o_error       => l_error)
            THEN
                RAISE g_general_error;
            END IF;
        
        ELSIF i_flg_context = pk_complication_core.get_axe_typ_at_und(i_lang, i_prof)
              AND i_type = pk_complication_core.g_flg_cfg_typ_assoc_task
        THEN
        
            g_error := 'GET CONF VARS';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            IF NOT (pk_complication_core.get_cfg_vars(i_lang      => i_lang,
                                                      i_prof      => i_prof,
                                                      i_cfg_type  => pk_complication_core.get_cfg_typ_assoc_task(i_lang,
                                                                                                                 i_prof),
                                                      o_inst      => l_inst,
                                                      o_soft      => l_soft,
                                                      o_clin_serv => l_clin_serv,
                                                      o_error     => l_error))
            THEN
                pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
                RAISE l_exception;
            END IF;
        
            g_error := 'GET AT UNDF';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            OPEN l_tasks FOR
                SELECT i_id_task id_task,
                       pk_translation.get_translation(i_lang, ca.code_comp_axe) desc_task,
                       --unused parameters
                       NULL id_episode,
                       NULL flg_type,
                       NULL flg_context,
                       NULL dt_task,
                       NULL dt_task_send,
                       NULL id_prof_task,
                       NULL name_prof_task,
                       NULL id_prof_req,
                       NULL name_prof_req
                  FROM comp_axe ca
                  JOIN comp_config cc
                    ON cc.id_comp_axe = ca.id_comp_axe
                 WHERE ca.id_sys_list = i_flg_context
                   AND ca.flg_available = pk_alert_constant.g_yes
                   AND cc.id_sys_list = pk_complication_core.get_cfg_typ_assoc_task(i_lang, i_prof)
                   AND cc.id_institution = l_inst
                   AND cc.id_software = l_soft
                   AND cc.id_clinical_service = l_clin_serv;
        END IF;
    
        g_error := 'FETCH TASK';
        FETCH l_tasks
            INTO l_comp_rec;
        CLOSE l_tasks;
    
        g_error := 'RETURN TASK';
        IF i_flg_det = l_type_n
        THEN
            RETURN l_comp_rec.desc_task;
        ELSIF i_flg_det = l_type_d
        THEN
            RETURN l_comp_rec.dt_task;
        END IF;
    
        RETURN NULL;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => l_error);
            RETURN NULL;
    END get_task_det;

BEGIN
    -- Initialization

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_api_complications;
/
