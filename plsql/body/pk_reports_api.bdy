CREATE OR REPLACE PACKAGE BODY pk_reports_api IS

    --
    -- SUBTYPES
    -- 

    SUBTYPE obj_name IS VARCHAR2(32 CHAR);
    SUBTYPE debug_msg IS VARCHAR2(4000 CHAR);

    --
    -- CONSTANTS
    -- 

    -- Package info
    c_package_owner CONSTANT obj_name := 'ALERT';
    c_package_name  CONSTANT obj_name := pk_alertlog.who_am_i();
    c_available     CONSTANT VARCHAR2(1) := 'Y';
    c_not_available CONSTANT VARCHAR2(1) := 'N';
    c_original      CONSTANT VARCHAR2(1) := 'Y';
    c_add           CONSTANT VARCHAR2(1) := 'A';

    my_exception EXCEPTION;
    --
    -- FUNCTIONS
    -- 

    /********************************************************************************************
    * Invokation of pk_message.get_message_array.
    
    * @author                                  Gonçalo Almeida
    * @version                                 0.1
    * @since                                   2011/Mar/02
    ********************************************************************************************/
    FUNCTION get_message_array
    (
        i_lang         IN language.id_language%TYPE,
        i_code_msg_arr IN table_varchar,
        i_prof         IN profissional,
        o_desc_msg_arr OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    BEGIN
        l_message := 'CALL TO FUNCTION INTERNAL GET_MESSAGE_ARRAY';
        pk_alertlog.log_debug(l_message);
        IF NOT pk_message.get_message_array(i_lang         => i_lang,
                                            i_code_msg_arr => i_code_msg_arr,
                                            i_prof         => i_prof,
                                            o_desc_msg_arr => o_desc_msg_arr)
        THEN
            RETURN FALSE;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              c_package_owner,
                                              c_package_name,
                                              'GET_MESSAGE_ARRAY',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_message_array;

    /********************************************************************************************
    * Invokation of pk_message.get_message_array.
    
    * @author                                  Gonçalo Almeida
    * @version                                 0.1
    * @since                                   2011/Mar/02
    ********************************************************************************************/
    FUNCTION get_message_array_simple
    (
        i_lang         IN language.id_language%TYPE,
        i_code_msg_arr IN table_varchar,
        o_desc_msg_arr OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    BEGIN
        l_message := 'CALL TO FUNCTION INTERNAL GET_MESSAGE_ARRAY_SIMPLE';
        pk_alertlog.log_debug(l_message);
        IF NOT pk_message.get_message_array(i_lang         => i_lang,
                                            i_code_msg_arr => i_code_msg_arr,
                                            o_desc_msg_arr => o_desc_msg_arr)
        THEN
            RETURN FALSE;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              c_package_owner,
                                              c_package_name,
                                              'GET_MESSAGE_ARRAY_SIMPLE',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_message_array_simple;

    /********************************************************************************************
    * Invokation of pk_patient.get_pat_habit.
    
    * @author                                  Gonçalo Almeida
    * @version                                 0.1
    * @since                                   2011/Mar/02
    ********************************************************************************************/
    FUNCTION get_pat_habit
    (
        i_lang         IN language.id_language%TYPE,
        i_id_pat_habit IN pat_habit.id_pat_habit%TYPE,
        i_prof         IN profissional,
        o_habit_detail OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    BEGIN
        l_message := 'CALL TO FUNCTION INTERNAL GET_PAT_HABIT';
        pk_alertlog.log_debug(l_message);
        IF NOT pk_patient.get_pat_habit(i_lang         => i_lang,
                                        i_id_pat_habit => i_id_pat_habit,
                                        i_prof         => i_prof,
                                        i_all          => TRUE,
                                        o_habit_detail => o_habit_detail,
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
                                              l_message,
                                              c_package_owner,
                                              c_package_name,
                                              'GET_PAT_HABIT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_pat_habit;

    /********************************************************************************************
    * Invokation of pk_inp_nurse.get_scales_summ_page.
    
    * @author                                  Gonçalo Almeida
    * @version                                 0.1
    * @since                                   2011/Mar/02
    ********************************************************************************************/
    FUNCTION get_scales_summ_page
    (
        i_lang               IN NUMBER,
        i_prof               IN profissional,
        i_doc_area           IN NUMBER,
        i_id_episode         IN episode.id_episode%TYPE,
        i_flg_scope          IN VARCHAR2,
        i_scope              IN NUMBER,
        i_start_date         IN VARCHAR2,
        i_end_date           IN VARCHAR2,
        i_num_record_show    IN NUMBER DEFAULT NULL,
        o_doc_area_register  OUT pk_types.cursor_type,
        o_doc_area_val       OUT pk_types.cursor_type,
        o_doc_not_register   OUT pk_types.cursor_type,
        o_template_layouts   OUT pk_types.cursor_type,
        o_doc_area_component OUT pk_types.cursor_type,
        o_record_count       OUT NUMBER,
        o_groups             OUT pk_types.cursor_type,
        o_scores             OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    BEGIN
        l_message := 'CALL TO FUNCTION INTERNAL GET_SCALES_SUMM_PAGE';
        pk_alertlog.log_debug(l_message);
        IF NOT pk_inp_nurse.get_scales_summ_page(i_lang               => i_lang,
                                                 i_prof               => i_prof,
                                                 i_doc_area           => i_doc_area,
                                                 i_id_episode         => i_id_episode,
                                                 i_flg_scope          => i_flg_scope,
                                                 i_scope              => i_scope,
                                                 i_start_date         => i_start_date,
                                                 i_end_date           => i_end_date,
                                                 i_num_record_show    => i_num_record_show,
                                                 o_doc_area_register  => o_doc_area_register,
                                                 o_doc_area_val       => o_doc_area_val,
                                                 o_doc_not_register   => o_doc_not_register,
                                                 o_template_layouts   => o_template_layouts,
                                                 o_doc_area_component => o_doc_area_component,
                                                 o_record_count       => o_record_count,
                                                 o_groups             => o_groups,
                                                 o_scores             => o_scores,
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
                                              l_message,
                                              c_package_owner,
                                              c_package_name,
                                              'GET_SCALES_SUMM_PAGE',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_scales_summ_page;

    /********************************************************************************************
    * Invokation of pk_summary_page.get_summary_page_sections
    
    * @author                                  Gonçalo Almeida
    * @version                                 0.1
    * @since                                   2011/Mar/02
    ********************************************************************************************/
    FUNCTION get_summary_page_sections_rep
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_summary_page IN summary_page.id_summary_page%TYPE,
        o_sections        OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    BEGIN
        l_message := 'CALL TO FUNCTION INTERNAL GET_SUMMARY_PAGE_SECTIONS';
        pk_alertlog.log_debug(l_message);
        RETURN pk_summary_page.get_summary_page_sections_rep(i_lang            => i_lang,
                                                             i_prof            => i_prof,
                                                             i_id_summary_page => i_id_summary_page,
                                                             o_sections        => o_sections,
                                                             o_error           => o_error);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              c_package_owner,
                                              c_package_name,
                                              'GET_SUMMARY_PAGE_SECTIONS',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_summary_page_sections_rep;

    /********************************************************************************************
    * Invokation of pk_sysconfig.get_config
    
    * @author                                  Gonçalo Almeida
    * @version                                 0.1
    * @since                                   2011/Mar/02
    ********************************************************************************************/
    FUNCTION get_single_config
    (
        i_lang    IN language.id_language%TYPE,
        i_code_cf IN sys_config.id_sys_config%TYPE,
        i_prof    IN profissional,
        o_msg_cf  OUT sys_config.value%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    BEGIN
        l_message := 'CALL TO FUNCTION INTERNAL GET_SINGLE_CONFIG';
        pk_alertlog.log_debug(l_message);
        IF NOT pk_sysconfig.get_config(i_code_cf => i_code_cf, i_prof => i_prof, o_msg_cf => o_msg_cf)
        
        THEN
            RETURN FALSE;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              c_package_owner,
                                              c_package_name,
                                              'GET_SINGLE_CONFIG',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_single_config;

    /********************************************************************************************
    * Invokation of pk_sysconfig.get_config
    
    * @author                                  Gonçalo Almeida
    * @version                                 0.1
    * @since                                   2011/Mar/02
    ********************************************************************************************/
    FUNCTION get_array_config
    (
        i_lang    IN language.id_language%TYPE,
        i_code_cf IN table_varchar,
        i_prof    IN profissional,
        o_msg_cf  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    BEGIN
        l_message := 'CALL TO FUNCTION INTERNAL GET_ARRAY_CONFIG';
        pk_alertlog.log_debug(l_message);
        IF NOT pk_sysconfig.get_config(i_code_cf => i_code_cf, i_prof => i_prof, o_msg_cf => o_msg_cf)
        
        THEN
            RETURN FALSE;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              c_package_owner,
                                              c_package_name,
                                              'GET_ARRAY_CONFIG',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_array_config;

    /********************************************************************************************
    * Invokation of pk_sysconfig.get_config
    
    * @author                                  Gonçalo Almeida
    * @version                                 0.1
    * @since                                   2011/Mar/02
    ********************************************************************************************/
    FUNCTION get_array_config_inst_soft
    (
        i_lang      IN language.id_language%TYPE,
        i_code_cf   IN table_varchar,
        i_prof_inst IN institution.id_institution%TYPE,
        i_prof_soft IN software.id_software%TYPE,
        o_msg_cf    OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    BEGIN
        l_message := 'CALL TO FUNCTION INTERNAL GET_ARRAY_CONFIG_INST_SOFT';
        pk_alertlog.log_debug(l_message);
        IF NOT pk_sysconfig.get_config(i_code_cf   => i_code_cf,
                                       i_prof_inst => i_prof_inst,
                                       i_prof_soft => i_prof_soft,
                                       o_msg_cf    => o_msg_cf)
        THEN
            RETURN FALSE;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              c_package_owner,
                                              c_package_name,
                                              'GET_ARRAY_CONFIG_INST_SOFT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_array_config_inst_soft;

    /********************************************************************************************
    * Invokation of pk_complaint.get_epis_complaint
    
    * @author                                  Gonçalo Almeida
    * @version                                 0.1
    * @since                                   2011/Mar/02
    ********************************************************************************************/
    FUNCTION get_epis_complaint
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_epis_docum     IN epis_documentation.id_epis_documentation%TYPE,
        o_epis_complaint OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    BEGIN
        l_message := 'CALL TO FUNCTION INTERNAL GET_EPIS_COMPLAINT';
        pk_alertlog.log_debug(l_message);
        IF NOT pk_complaint.get_epis_complaint(i_lang           => i_lang,
                                               i_prof           => i_prof,
                                               i_episode        => i_episode,
                                               i_epis_docum     => i_epis_docum,
                                               o_epis_complaint => o_epis_complaint,
                                               o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              c_package_owner,
                                              c_package_name,
                                              'GET_EPIS_COMPLAINT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_epis_complaint;

    /********************************************************************************************
    * Invokation of pk_medication_current.get_current_medication_int
    
    * @author                                  Gonçalo Almeida
    * @version                                 0.1
    * @since                                   2011/Mar/02
    ********************************************************************************************/
    FUNCTION get_current_medication_int
    (
        i_lang         IN language.id_language%TYPE,
        i_epis         IN drug_prescription.id_episode%TYPE,
        i_prof         IN profissional,
        i_id_presc     IN presc.id_presc%TYPE,
        o_this_episode OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message  debug_msg;
        l_id_visit episode.id_visit%TYPE;
    BEGIN
        l_message  := 'PK_EPISODE.GET_ID_VISIT';
        l_id_visit := pk_episode.get_id_visit(i_episode => i_epis);
    
        l_message := 'PK_RT_MED_PFH.GET_CUR_MED_LOCAL_4REPORT';
        RETURN pk_rt_med_pfh.get_cur_med_local_4report(i_lang       => i_lang,
                                                       i_prof       => i_prof,
                                                       i_id_episode => i_epis,
                                                       i_id_visit   => l_id_visit,
                                                       i_id_presc   => i_id_presc,
                                                       o_cur        => o_this_episode,
                                                       o_error      => o_error);
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              c_package_owner,
                                              c_package_name,
                                              'GET_CURRENT_MEDICATION_INT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_current_medication_int;

    /********************************************************************************************
    * Invokation of pk_rt_med_pfh.get_cur_med_ext_4report
    
    * @author                                  daniel.albuquerque
    * @version                                 0.1
    * @since                                   2011/Dec/06
    ********************************************************************************************/
    FUNCTION get_current_medication_ext
    (
        i_lang              IN language.id_language%TYPE,
        i_epis              IN drug_prescription.id_episode%TYPE,
        i_prof              IN profissional,
        i_flg_only_not_disp IN VARCHAR2 DEFAULT pk_alert_constant.g_no, -- only not dispensed medication
        o_this_episode      OUT pk_types.cursor_type,
        o_print             OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message  debug_msg;
        l_id_visit episode.id_visit%TYPE;
    BEGIN
        l_message  := 'PK_EPISODE.GET_ID_VISIT';
        l_id_visit := pk_episode.get_id_visit(i_episode => i_epis);
    
        l_message := 'PK_RT_MED_PFH.GET_CUR_MED_LOCAL_4REPORT';
        pk_rt_med_pfh.get_cur_med_ext_4report(i_lang              => i_lang,
                                              i_prof              => i_prof,
                                              i_id_episode        => i_epis,
                                              i_id_visit          => l_id_visit,
                                              i_flg_only_not_disp => i_flg_only_not_disp,
                                              o_cur               => o_this_episode,
                                              o_print             => o_print);
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              c_package_owner,
                                              c_package_name,
                                              'GET_CURRENT_MEDICATION_EXT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_current_medication_ext;

    /********************************************************************************************
    * pk_reports_api.get_prev_med_not_local  
    *
    * @param    I_LANG                          IN        NUMBER(6)
    * @param    I_PROF                          IN        PROFISSIONAL
    * @param    I_ID_PATIENT                    IN        NUMBER(24)
    * @param    I_ID_EPISODE                    IN        NUMBER(24)
    * @param    O_PREVIOUS_MEDICATION           OUT       REF CURSOR
    * @param    O_PREVIOUS_REVIEW               OUT       REF CURSOR
    * @param    O_ERROR                         OUT       T_ERROR_OUT
    *
    * @return   BOOLEAN
    *
    * @author   Rui Marante
    * @version    2.6.2
    * @since    2011-09-06
    *
    * @notes    
    *
    * @status   done
    *
    ********************************************************************************************/
    FUNCTION get_prev_med_not_local
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_patient          IN patient.id_patient%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        o_previous_medication OUT pk_types.cursor_type,
        o_previous_review     OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    BEGIN
        l_message := 'PK_RT_MED_PFH.GET_PREV_MED_NOT_LOCAL_4REPORT';
        pk_rt_med_pfh.get_prev_med_not_local_4report(i_lang       => i_lang,
                                                     i_prof       => i_prof,
                                                     i_id_patient => i_id_patient,
                                                     i_id_episode => i_id_episode,
                                                     o_cur        => o_previous_medication,
                                                     o_cur_review => o_previous_review);
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              c_package_owner,
                                              c_package_name,
                                              'GET_PREV_MED_NOT_LOCAL',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_prev_med_not_local;

    /********************************************************************************************
    * Invokation of pk_discharge.get_follow_up_with_list
    
    * @author                                  Gonçalo Almeida
    * @version                                 0.1
    * @since                                   2011/Mar/02
    ********************************************************************************************/
    FUNCTION get_follow_up_with_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_disch_notes IN discharge_notes.id_discharge_notes%TYPE,
        o_follow_up_with OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    BEGIN
        l_message := 'CALL TO FUNCTION INTERNAL GET_FOLLOW_UP_WITH_LIST';
        pk_alertlog.log_debug(l_message);
        IF NOT pk_discharge.get_follow_up_with_list(i_lang           => i_lang,
                                                    i_prof           => i_prof,
                                                    i_id_disch_notes => i_id_disch_notes,
                                                    o_follow_up_with => o_follow_up_with,
                                                    o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              c_package_owner,
                                              c_package_name,
                                              'GET_FOLLOW_UP_WITH_LIST',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_follow_up_with_list;

    /********************************************************************************************
    * Invokation of pk_rehab.get_rehab_treatment_plan_int
    
    * @author                                  Jorge Matos
    * @version                                 0.1
    * @since                                   2011/Mai/12
    ********************************************************************************************/
    FUNCTION get_rehab_treatment_plan_int
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_patient        IN rehab_plan.id_patient%TYPE,
        i_id_episode        IN rehab_plan.id_episode_origin%TYPE,
        i_reports           IN VARCHAR2,
        o_id_episode_origin OUT rehab_plan.id_episode_origin%TYPE,
        o_sch_need          OUT pk_types.cursor_type,
        o_treat             OUT pk_types.cursor_type,
        o_notes             OUT pk_types.cursor_type,
        o_labels            OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    BEGIN
        l_message := 'CALL TO FUNCTION INTERNAL GET_REHAB_TREATMENT_PLAN_INT';
        pk_alertlog.log_debug(l_message);
        IF NOT pk_rehab.get_rehab_treatment_plan_int(i_lang              => i_lang,
                                                     i_prof              => i_prof,
                                                     i_id_patient        => i_id_patient,
                                                     i_id_episode        => i_id_episode,
                                                     i_reports           => i_reports,
                                                     o_id_episode_origin => o_id_episode_origin,
                                                     o_sch_need          => o_sch_need,
                                                     o_treat             => o_treat,
                                                     o_notes             => o_notes,
                                                     o_labels            => o_labels,
                                                     o_error             => o_error)
        THEN
            RETURN FALSE;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              c_package_owner,
                                              c_package_name,
                                              'GET_REHAB_TREATMENT_PLAN_INT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_rehab_treatment_plan_int;

    FUNCTION get_rehab_treatment_plan
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN rehab_plan.id_patient%TYPE,
        i_id_episode IN rehab_plan.id_episode_origin%TYPE,
        o_treat      OUT pk_types.cursor_type,
        o_sch_need   OUT pk_types.cursor_type,
        o_notes      OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    BEGIN
        l_message := 'CALL TO FUNCTION INTERNAL GET_REHAB_TREATMENT_PLAN_INT';
        pk_alertlog.log_debug(l_message);
        IF NOT pk_rehab.get_rehab_treatment_plan(i_lang       => i_lang,
                                                 i_prof       => i_prof,
                                                 i_id_patient => i_id_patient,
                                                 i_id_episode => i_id_episode,
                                                 i_reports    => pk_alert_constant.g_yes,
                                                 o_treat      => o_treat,
                                                 o_sch_need   => o_sch_need,
                                                 o_notes      => o_notes,
                                                 o_error      => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              c_package_owner,
                                              c_package_name,
                                              'GET_REHAB_TREATMENT_PLAN',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_rehab_treatment_plan;

    /********************************************************************************************
    * Invokation of pk_allergy
    
    * @author                                  Joaquim Rocha
    * @version                                 0.1
    * @since                                   2011/May/05
    ********************************************************************************************/
    FUNCTION get_allergy_list
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_patient              IN patient.id_patient%TYPE,
        i_episode              IN episode.id_episode%TYPE,
        o_allergies            OUT pk_types.cursor_type,
        o_unawareness_active   OUT pk_types.cursor_type,
        o_unawareness_outdated OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    BEGIN
        l_message := 'CALL TO FUNCTION INTERNAL GET_ALLERGY_LIST';
        pk_alertlog.log_debug(l_message);
    
        IF NOT pk_allergy.get_allergy_list(i_lang                 => i_lang,
                                           i_prof                 => i_prof,
                                           i_patient              => i_patient,
                                           i_episode              => i_episode,
                                           o_allergies            => o_allergies,
                                           o_unawareness_active   => o_unawareness_active,
                                           o_unawareness_outdated => o_unawareness_outdated,
                                           o_error                => o_error)
        THEN
            RETURN FALSE;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              c_package_owner,
                                              c_package_name,
                                              'GET_ALLERGY_LIST',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_allergy_list;

    /********************************************************************************************
    * Invocation of pk_hand_off.get_current_resp_grid
    
    * @author                                  goncalo.almeida
    * @version                                 0.1
    * @since                                   2011/May/27
    ********************************************************************************************/
    FUNCTION get_current_resp_grid
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_flg_show        IN VARCHAR2 DEFAULT 'A',
        o_grid            OUT pk_types.cursor_type,
        o_has_responsible OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    BEGIN
        l_message := 'CALL TO FUNCTION INTERNAL GET_CURRENT_RESP_GRID';
        pk_alertlog.log_debug(l_message);
    
        IF NOT pk_hand_off_core.get_current_resp_grid(i_lang            => i_lang,
                                                      i_prof            => i_prof,
                                                      i_episode         => i_episode,
                                                      i_flg_show        => i_flg_show,
                                                      o_grid            => o_grid,
                                                      o_has_responsible => o_has_responsible,
                                                      o_error           => o_error)
        THEN
            RETURN FALSE;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              c_package_owner,
                                              c_package_name,
                                              'GET_CURRENT_RESP_GRID',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_current_resp_grid;

    /********************************************************************************************
    * Invocation of pk_sr_visit.get_pat_surg_episodes
    
    * @author                                  daniel.albuquerque
    * @version                                 0.1
    * @since                                   2011/Jun/06
    ********************************************************************************************/
    FUNCTION get_pat_surg_episodes
    (
        i_lang     IN language.id_language%TYPE,
        i_patient  IN patient.id_patient%TYPE,
        i_prof     IN profissional,
        i_status   IN VARCHAR2,
        i_planned  IN VARCHAR2,
        o_grid     OUT pk_types.cursor_type,
        o_status   OUT pk_types.cursor_type,
        o_room     OUT pk_types.cursor_type,
        o_id_disch OUT disch_reas_dest.id_disch_reas_dest%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    BEGIN
        l_message := 'CALL TO FUNCTION INTERNAL GET_PAT_SURG_EPISODES';
        pk_alertlog.log_debug(l_message);
    
        IF NOT pk_sr_visit.get_pat_surg_episodes(i_lang     => i_lang,
                                                 i_patient  => i_patient,
                                                 i_prof     => i_prof,
                                                 i_status   => i_status,
                                                 i_planned  => i_planned,
                                                 o_grid     => o_grid,
                                                 o_status   => o_status,
                                                 o_room     => o_room,
                                                 o_id_disch => o_id_disch,
                                                 o_error    => o_error)
        THEN
            RETURN FALSE;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              c_package_owner,
                                              c_package_name,
                                              'GET_PAT_SURG_EPISODES',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_pat_surg_episodes;

    /********************************************************************************************
    * Invocation of pk_touch_option.get_formatted_value
    
    * @author                                  joaquim.rocha
    * @version                                 0.1
    * @since                                   2011/Jun/29
    ********************************************************************************************/
    FUNCTION get_formatted_value
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_type  IN doc_element.flg_type%TYPE,
        i_value IN epis_documentation_det.value%TYPE
    ) RETURN VARCHAR2 IS
        l_message         debug_msg;
        l_formatted_value VARCHAR2(32767);
    BEGIN
        l_message := 'CALL TO FUNCTION INTERNAL GET_FORMATTED_VALUE';
        pk_alertlog.log_debug(l_message);
    
        l_formatted_value := pk_touch_option.get_formatted_value(i_lang                => i_lang,
                                                                 i_prof                => i_prof,
                                                                 i_type                => i_type,
                                                                 i_value               => i_value,
                                                                 i_properties          => NULL,
                                                                 i_input_mask          => NULL,
                                                                 i_optional_value      => NULL,
                                                                 i_domain_type         => NULL,
                                                                 i_code_element_domain => NULL,
                                                                 i_dt_creation         => NULL);
    
        RETURN TRIM(l_formatted_value);
    
    END get_formatted_value;

    /********************************************************************************************
    * Invocation of pk_header.get_header
    
    * @author                                  goncalo.almeida
    * @version                                 0.1
    * @since                                   2011/Jul/14
    ********************************************************************************************/
    FUNCTION get_header
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_patient  IN patient.id_patient%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE,
        i_screen_mode IN header.flg_screen_mode%TYPE,
        i_flg_area    IN sys_application_area.flg_area%TYPE,
        i_id_keys     IN table_varchar,
        i_id_values   IN table_varchar,
        o_id_header   OUT header.id_header%TYPE,
        o_data        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message         debug_msg;
        l_ptempl          profile_template.id_profile_template%TYPE;
        l_professional    profissional;
        l_id_professional professional.id_professional%TYPE;
    BEGIN
        l_message := 'CALL TO FUNCTION INTERNAL GET_HEADER';
        pk_alertlog.log_debug(l_message);
    
        -- check if the professional has an associated profile template (it may not have when we change it to the episode's institution and software)
        l_ptempl := pk_tools.get_prof_profile_template(i_prof => i_prof);
    
        IF l_ptempl IS NOT NULL
        THEN
            -- if there is a valid profile template then call pk_header.get_header as usual
            l_professional := i_prof;
        ELSE
            -- if there isn't, get a random professional from that institution and software (TODO: replace this hardcoded logic)
            SELECT ppt.id_professional
              INTO l_id_professional
              FROM prof_profile_template ppt
              JOIN profile_template pt
                ON pt.id_profile_template = ppt.id_profile_template
               AND pt.id_software = ppt.id_software
             WHERE ppt.id_institution = i_prof.institution
               AND ppt.id_software = i_prof.software
               AND pt.flg_available = 'Y'
               AND rownum = 1;
            l_professional := profissional(l_id_professional, i_prof.institution, i_prof.software);
        END IF;
    
        -- call pk_header with the correct l_professional
        IF NOT pk_header.get_header(i_lang        => i_lang,
                                    i_prof        => l_professional,
                                    i_id_episode  => i_id_episode,
                                    i_id_patient  => i_id_patient,
                                    i_id_schedule => i_id_schedule,
                                    i_screen_mode => i_screen_mode,
                                    i_flg_area    => i_flg_area,
                                    i_id_keys     => i_id_keys,
                                    i_id_values   => i_id_values,
                                    o_id_header   => o_id_header,
                                    o_data        => o_data,
                                    o_error       => o_error)
        THEN
            RETURN FALSE;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              c_package_owner,
                                              c_package_name,
                                              'GET_HEADER',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_header;

    /********************************************************************************************
    * Invocation of pk_sr_tools.get_sr_prof_team_det
    
    * @author                                  goncalo.almeida
    * @version                                 0.1
    * @since                                   2012/Jun/05
    ********************************************************************************************/
    FUNCTION get_sr_prof_team_det
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_type         IN VARCHAR2,
        o_id_prof_team OUT sr_prof_team_det.id_prof_team%TYPE,
        o_team_name    OUT VARCHAR2,
        o_team_desc    OUT VARCHAR2,
        o_list         OUT pk_types.cursor_type,
        o_status       OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    BEGIN
        l_message := 'CALL TO FUNCTION INTERNAL GET_SR_PROF_TEAM_DET';
        pk_alertlog.log_debug(l_message);
    
        IF NOT pk_sr_tools.get_sr_prof_team_det(i_lang         => i_lang,
                                                i_prof         => i_prof,
                                                i_episode      => i_episode,
                                                i_type         => i_type,
                                                o_id_prof_team => o_id_prof_team,
                                                o_team_name    => o_team_name,
                                                o_team_desc    => o_team_desc,
                                                o_list         => o_list,
                                                o_status       => o_status,
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
                                              l_message,
                                              c_package_owner,
                                              c_package_name,
                                              'GET_SR_PROF_TEAM_DET',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_sr_prof_team_det;

    /********************************************************************************************
    * Invocation of pk_adt.get_patient_name
    
    * @author                                  goncalo.almeida
    * @version                                 0.1
    * @since                                   2012/Jun/05
    ********************************************************************************************/
    FUNCTION get_patient_name
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        o_name     OUT patient.name%TYPE,
        o_vip_name OUT patient.name%TYPE,
        o_alias    OUT patient.alias%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    BEGIN
        l_message := 'CALL TO FUNCTION INTERNAL GET_PATIENT_NAME';
        pk_alertlog.log_debug(l_message);
    
        IF NOT pk_adt.get_patient_name(i_lang     => i_lang,
                                       i_prof     => i_prof,
                                       i_patient  => i_patient,
                                       o_name     => o_name,
                                       o_vip_name => o_vip_name,
                                       o_alias    => o_alias,
                                       o_error    => o_error)
        THEN
            RETURN FALSE;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              c_package_owner,
                                              c_package_name,
                                              'GET_PATIENT_NAME',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_patient_name;

    /********************************************************************************************
    * pk_reports_api.get_cur_med_reported_4report  
    *
    * @param    I_LANG                          IN        NUMBER(6)
    * @param    I_PROF                          IN        PROFISSIONAL
    * @param    I_ID_PATIENT                    IN        NUMBER(24)
    * @param    I_ID_EPISODE                    IN        NUMBER(24)
    * @param    O_cur                           OUT       REF CURSOR
    * @param    O_CUR_REVIEW                    OUT       REF CURSOR
    * @param    O_ERROR                         OUT       T_ERROR_OUT
    *
    * @return   BOOLEAN
    *
    * @author   Rui Marante
    * @version    2.6.2
    * @since    2011-09-06
    *
    * @notes    
    *
    * @status   done
    *
    ********************************************************************************************/
    FUNCTION get_cur_med_reported_4report
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        o_cur        OUT pk_types.cursor_type,
        o_cur_review OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    BEGIN
        l_message := 'PK_RT_MED_PFH.GET_CUR_MED_REPORTED_4REPORT';
        pk_rt_med_pfh.get_cur_med_reported_4report(i_lang       => i_lang,
                                                   i_prof       => i_prof,
                                                   i_id_patient => i_id_patient,
                                                   i_id_episode => i_id_episode,
                                                   o_cur        => o_cur,
                                                   o_cur_review => o_cur_review);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_cur);
            pk_types.open_my_cursor(o_cur_review);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              c_package_owner,
                                              c_package_name,
                                              'GET_PREV_MED_NOT_LOCAL',
                                              o_error);
            RETURN FALSE;
    END get_cur_med_reported_4report;

    /********************************************************************************************
    * Get professional work phone
    *
    * @param i_lang              Language id (log)
    * @param i_id_professional   Professional identifier
    * @param o_work_phone        Professional work phone
    * @param o_error             Error
    *
    * @return boolean
    *
    * @author                    JTS
    * @version                   26371
    * @since                     2013/08/06
    ********************************************************************************************/
    FUNCTION get_prof_work_phone
    (
        i_lang            IN language.id_language%TYPE,
        i_id_professional IN professional.id_professional%TYPE,
        o_work_phone      OUT professional.work_phone%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_message debug_msg;
        l_exception EXCEPTION;
    
    BEGIN
    
        l_message := 'GET PROFESSIONAL WORK PHONE';
        IF NOT pk_api_backoffice.get_prof_work_phone(i_lang, i_id_professional, o_work_phone, o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              'ALERT',
                                              'PK_REPORTS_API',
                                              'GET_PROF_WORK_PHONE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              'ALERT',
                                              'PK_REPORTS_API',
                                              'GET_PROF_WORK_PHONE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_prof_work_phone;

    /********************************************************************************************
    * Invocation of pk_cit.get_cit_report
    *
    * @author                   Jorge Silva
    * @since                    27/08/2013
    ********************************************************************************************/
    FUNCTION get_cit_report
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_cits    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    BEGIN
        l_message := 'CALL TO FUNCTION INTERNAL GET_CIT_REPORT';
        IF NOT pk_cit.get_cit_report(i_lang    => i_lang,
                                     i_prof    => i_prof,
                                     i_patient => i_patient,
                                     i_episode => i_episode,
                                     o_cits    => o_cits,
                                     o_error   => o_error)
        THEN
            RETURN FALSE;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              c_package_owner,
                                              c_package_name,
                                              'GET_CIT_REPORT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_cit_report;

    /********************************************************************************************
    * Invocation of pk_complaint.get_complaint_report
    *
    * @author                   Jorge Silva
    * @since                    25/09/2013
    ********************************************************************************************/
    FUNCTION get_complaint
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_flg_scope          IN VARCHAR2,
        o_complaint_register OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    BEGIN
        l_message := 'CALL TO FUNCTION INTERNAL GET_COMPLAINT_REPORT';
        IF NOT pk_complaint.get_complaint_report(i_lang               => i_lang,
                                                 i_prof               => i_prof,
                                                 i_patient            => i_patient,
                                                 i_episode            => i_episode,
                                                 i_flg_scope          => i_flg_scope,
                                                 o_complaint_register => o_complaint_register,
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
                                              l_message,
                                              c_package_owner,
                                              c_package_name,
                                              'GET_COMPLAINT_REPORT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_complaint;

    /********************************************************************************************
    * Invokation of pk_adt.get_health_plan.
    
    * @author                                  Ricardo Pires
    * @version                                 0.1
    * @since                                   2013/Oct/08
    ********************************************************************************************/
    FUNCTION get_health_plan
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        o_hp_id_hp        OUT pat_health_plan.id_health_plan%TYPE,
        o_num_health_plan OUT pat_health_plan.num_health_plan%TYPE,
        o_hp_entity       OUT VARCHAR2,
        o_hp_desc         OUT VARCHAR2,
        o_hp_in_use       OUT VARCHAR2,
        o_nhn_id_hp       OUT pat_health_plan.id_health_plan%TYPE,
        o_nhn_number      OUT VARCHAR2,
        o_nhn_hp_entity   OUT VARCHAR2,
        o_nhn_hp_desc     OUT VARCHAR2,
        o_nhn_status      OUT VARCHAR2,
        o_nhn_desc_status OUT VARCHAR2,
        o_nhn_in_use      OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    BEGIN
        l_message := 'CALL TO FUNCTION INTERNAL GET_HEALTH_PLAN';
        pk_alertlog.log_debug(l_message);
        IF NOT pk_adt.get_health_plan(i_lang            => i_lang,
                                      i_prof            => i_prof,
                                      i_id_patient      => i_id_patient,
                                      i_id_episode      => i_id_episode,
                                      o_hp_id_hp        => o_hp_id_hp,
                                      o_num_health_plan => o_num_health_plan,
                                      o_hp_entity       => o_hp_entity,
                                      o_hp_desc         => o_hp_desc,
                                      o_hp_in_use       => o_hp_in_use,
                                      o_nhn_id_hp       => o_nhn_id_hp,
                                      o_nhn_number      => o_nhn_number,
                                      o_nhn_hp_entity   => o_nhn_hp_entity,
                                      o_nhn_hp_desc     => o_nhn_hp_desc,
                                      o_nhn_status      => o_nhn_status,
                                      o_nhn_desc_status => o_nhn_desc_status,
                                      o_nhn_in_use      => o_nhn_in_use,
                                      o_error           => o_error)
        
        THEN
            RETURN FALSE;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              c_package_owner,
                                              c_package_name,
                                              'GET_HEALTH_PLAN',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_health_plan;

    /********************************************************************************************
    * Invokation of pk_api_backoffice.get_inst_account_val.
    
    * @author                                  Ricardo Pires
    * @version                                 0.1
    * @since                                   2013/Oct/29
    ********************************************************************************************/

    FUNCTION get_inst_account_val
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_account     IN accounts.id_account%TYPE,
        o_account_val OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    BEGIN
        l_message := 'CALL TO FUNCTION INTERNAL GET_INST_ACCOUNT_VAL';
        pk_alertlog.log_debug(l_message);
        o_account_val := pk_api_backoffice.get_inst_account_val(i_lang        => i_lang,
                                                                i_institution => i_institution,
                                                                i_account     => i_account,
                                                                o_error       => o_error);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              c_package_owner,
                                              c_package_name,
                                              'GET_INST_ACCOUNT_VAL',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_inst_account_val;
    FUNCTION get_inst_structure_acronyms
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_info    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_institution_acrn institution.abbreviation%TYPE;
        l_dept_acrn        dept.abbreviation%TYPE;
        l_service_acrn     department.abbreviation%TYPE;
        l_room_acrn        translation.desc_lang_1%TYPE;
        l_bed_acrn         bed.desc_bed%TYPE;
        g_error            VARCHAR2(1000);
    BEGIN
        g_error := 'GET INSTITUTION/DEPARTMENT/SERVICE ACRONYMS ' || i_episode;
        SELECT d.abbreviation, s.abbreviation, i.abbreviation
          INTO l_dept_acrn, l_service_acrn, l_institution_acrn
          FROM episode e
          LEFT JOIN institution i
            ON (i.id_institution = e.id_institution)
          LEFT JOIN dept d
            ON (d.id_dept = e.id_dept)
          LEFT JOIN department s
            ON (s.id_department = e.id_department)
         WHERE e.id_episode = i_episode;
    
        g_error := 'GET ROOM/BED ACRONYMS ' || i_episode;
        SELECT nvl(pk_translation.get_translation(i_lang, b.code_bed), b.desc_bed),
               pk_translation.get_translation(i_lang, r.code_abbreviation)
          INTO l_bed_acrn, l_room_acrn
          FROM epis_info ei
          LEFT JOIN bed b
            ON (b.id_bed = ei.id_bed)
          LEFT JOIN room r
            ON (r.id_room = ei.id_room)
         WHERE ei.id_episode = i_episode;
    
        g_error := 'SENT TO REPORT ACRONYMS (' || l_institution_acrn || ',' || l_dept_acrn || ',' || l_service_acrn || ',' ||
                   l_room_acrn || ',' || l_bed_acrn || ') ' || i_episode;
        -- dbms_output.put_line(g_error);
        OPEN o_info FOR
            SELECT l_institution_acrn instit_accronym,
                   l_dept_acrn        dept_accronym,
                   l_service_acrn     serv_accronym,
                   l_room_acrn        room_accronym,
                   l_bed_acrn         bed_accronym
              FROM dual;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_REPORTS_API',
                                              'GET_INST_STRUCTURE_ACRONYMS',
                                              o_error);
            RETURN FALSE;
    END get_inst_structure_acronyms;

    /********************************************************************************************
    * Return id Report and flg available (Y/N)
    *
    * @param i_lang              Language id (log)
    * @param i_prof              Professional identifier
    * @param o_id_report         Report id
    * @param o_flg_available     Flag available
    * @param o_error             Error
    *
    * @return boolean
    *
    * @author                   Jorge Silva
    * @since                    14/01/2014
    ********************************************************************************************/
    FUNCTION get_id_report
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis_doc      IN epis_documentation.id_epis_documentation%TYPE,
        i_doc_area      IN doc_area.id_doc_area%TYPE,
        o_id_report     OUT reports.id_reports%TYPE,
        o_flg_available OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message    debug_msg;
        l_flg_status epis_documentation.flg_status%TYPE;
    BEGIN
    
        l_message := 'CALL TO FUNCTION GET_ID_REPORT';
    
        IF i_epis_doc IS NOT NULL
        THEN
            SELECT ed.flg_status
              INTO l_flg_status
              FROM epis_documentation ed
             WHERE ed.id_epis_documentation = i_epis_doc;
        ELSE
            l_flg_status := NULL;
        END IF;
    
        SELECT decode(l_flg_status, pk_alert_constant.g_active, pk_alert_constant.g_yes, pk_alert_constant.g_no)
          INTO o_flg_available
          FROM dual;
    
        SELECT rtc.id_reports
          INTO o_id_report
          FROM rep_template_cfg rtc
         WHERE rtc.id_doc_area = i_doc_area
           AND rtc.id_software IN (pk_alert_constant.g_soft_all, i_prof.software)
           AND rtc.id_institution IN (pk_alert_constant.g_inst_all, i_prof.institution)
           AND rtc.id_market IN
               (0, pk_utils.get_institution_market(i_lang => i_lang, i_id_institution => i_prof.institution))
           AND rownum = 1;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            -- an area has no report
            o_id_report     := NULL;
            o_flg_available := pk_alert_constant.g_no;
            RETURN TRUE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              c_package_owner,
                                              c_package_name,
                                              'GET_ID_REPORT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_id_report;

    /******************************************************************************************** 
    * @param i_lang              Language id (log)
    * @param i_prof              Professional identifier
    * @param i_flg_type          Flag indicate the provenance
    * @param o_id_report         Report id
    * @param o_flg_available     Flag available
    * @param o_error             Error
    *
    * @return boolean
    *
    * @author                   Joel Lopes
    * @since                    28/01/2014
    ********************************************************************************************/
    FUNCTION get_epis_recomend_report
    (
        i_lang     IN language.id_language%TYPE,
        i_episode  IN epis_recomend.id_episode%TYPE,
        i_flg_type IN epis_recomend.flg_type%TYPE,
        i_prof     IN profissional,
        o_temp     OUT pk_types.cursor_type,
        o_def      OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    
    BEGIN
    
        l_message := 'CALL TO FUNCTION GET_EPIS_RECOMEND_REP';
    
        IF NOT pk_discharge.get_epis_recomend_rep(i_lang     => i_lang,
                                                  i_episode  => i_episode,
                                                  i_flg_type => i_flg_type,
                                                  i_flg_rep  => pk_alert_constant.g_yes,
                                                  i_prof     => i_prof,
                                                  o_temp     => o_temp,
                                                  o_def      => o_def,
                                                  o_error    => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              c_package_owner,
                                              c_package_name,
                                              'GET_EPIS_RECOMEND_REP',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_epis_recomend_report;
    /********************************************************************************************
    * Get Service information for reports presentation (Phone and fax number, responsible physicians)
    *
    * @param i_lang                   Preferred language ID for this professional    
    * @param i_institution            Institution ID
    * @param i_id_department          Service ID
    * @param o_fax_number             Fax Number
    * @param o_phone_number           Phone Number
    * @param o_prof_id_list           List of professionals ids
    * @param o_prof_desc_list         list of professional names concatenated
    * @param o_error                  Error Message ID
    *
    * @return                         true or false
    *
    * @author                         RMGM
    * @version                        2.6.3
    * @since                          2014/02/12
    **********************************************************************************************/
    FUNCTION get_service_detail_info
    (
        i_lang                    IN language.id_language%TYPE,
        i_id_institution          IN institution.id_institution%TYPE,
        i_id_department           IN department.id_department%TYPE,
        o_fax_number              OUT department.fax_number%TYPE,
        o_phone_number            OUT department.phone_number%TYPE,
        o_prof_id_list            OUT table_number,
        o_prof_name_list          OUT table_varchar,
        o_prof_desc_list          OUT VARCHAR2,
        o_prof_aff_list           OUT table_varchar,
        o_desc_prof_aff           OUT VARCHAR2,
        o_service_name            OUT VARCHAR2,
        o_prof_id_not_resp_list   OUT table_number,
        o_prof_name_not_resp_list OUT table_varchar,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_api_backoffice.get_service_detail_info(i_lang,
                                                         i_id_institution,
                                                         i_id_department,
                                                         o_fax_number,
                                                         o_phone_number,
                                                         o_prof_id_list,
                                                         o_prof_name_list,
                                                         o_prof_desc_list,
                                                         o_prof_aff_list,
                                                         o_desc_prof_aff,
                                                         o_service_name,
                                                         o_prof_id_not_resp_list,
                                                         o_prof_name_not_resp_list,
                                                         o_error);
    END get_service_detail_info;

    /********************************************************************************************
    * Get a header return a esi level or not (true/false)
    *
    * @param i_lang                   Preferred language ID for this professional    
    * @param i_prof                   Professional identifier
    * @param i_id_episode             Episode Id
    * @param o_flg_level              Flag is level or epis_type (Y-level N-epis_type)
    * @param o_epis_type              Description of level or epis_type
    *
    * @return                         true or false
    *
    * @author                         JS
    * @version                        2.6.3
    * @since                          2014/02/24
    **********************************************************************************************/
    FUNCTION get_epis_esi_level
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_flg_level  OUT VARCHAR2,
        o_epis_type  OUT VARCHAR2,
        o_acronym    OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message      debug_msg;
        l_epis_type    epis_type.id_epis_type%TYPE;
        l_triage_color epis_info.id_triage_color%TYPE;
    
    BEGIN
    
        SELECT e.id_epis_type
          INTO l_epis_type
          FROM episode e
         WHERE e.id_episode = i_id_episode;
    
        IF l_epis_type = pk_edis_proc.g_epis_type_edis
        THEN
            BEGIN
                SELECT ei.id_triage_color
                  INTO l_triage_color
                  FROM epis_info ei
                  JOIN triage_esi_level tlvl
                    ON tlvl.id_triage_color = ei.id_triage_color
                 WHERE ei.id_episode = i_id_episode;
            EXCEPTION
                WHEN no_data_found THEN
                    l_triage_color := NULL;
            END;
        
            IF l_triage_color IS NOT NULL
            THEN
                l_message   := 'CALL TO FUNCTION GET_EPIS_ESI_LEVEL';
                o_epis_type := pk_edis_triage.get_epis_esi_level(i_lang         => i_lang,
                                                                 i_prof         => i_prof,
                                                                 i_epis         => i_id_episode,
                                                                 i_triage_color => l_triage_color,
                                                                 i_type         => 'F');
                l_message   := 'CALL TO FUNCTION GET_EPIS_TRIAGE_ACRONYM';
                o_acronym   := pk_edis_triage.get_epis_triage_acronym(i_lang    => i_lang,
                                                                      i_prof    => i_prof,
                                                                      i_episode => i_id_episode);
                o_flg_level := pk_alert_constant.g_yes;
            ELSE
                o_epis_type := pk_message.get_message(i_lang, i_prof, 'HEADER_M007');
                o_acronym   := NULL;
                o_flg_level := pk_alert_constant.g_no;
            END IF;
        ELSE
            IF i_prof.software = 4
            THEN
                o_epis_type := pk_message.get_message(i_lang, i_prof, 'P1_HEADER_M001');
            ELSE
                IF l_epis_type IS NOT NULL
                THEN
                    o_epis_type := pk_translation.get_translation(i_lang, 'EPIS_TYPE.CODE_EPIS_TYPE.' || l_epis_type);
                ELSE
                    o_epis_type := pk_translation.get_translation(i_lang, 'SOFTWARE.CODE_SOFTWARE.' || i_prof.software);
                END IF;
            END IF;
        
            o_flg_level := pk_alert_constant.g_no;
            o_acronym   := NULL;
        
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              c_package_owner,
                                              c_package_name,
                                              'GET_EPIS_ESI_LEVEL',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_epis_esi_level;

    /********************************************************************************************
    * Insert records on the table rep_template_cfg (true/false)
    *
    * @param i_lang                   Preferred language ID for this professional    
    * @param i_doc_area               Doc area Id
    * @param i_report                 Report Id
    * @param i_concept                Concept Id
    * @param i_market                 Market Id
    * @param i_software               Software Id
    * @param i_institution            Institution Id                    
    * @param i_doc_template           Doc Template Id                        
    *
    * @return                         true or false
    *
    * @author                         Ricardo Pires
    * @version                        2.6.4
    * @since                          2014/07/04
    **********************************************************************************************/
    FUNCTION insert_into_rep_template_cfg
    (
        i_lang         IN language.id_language%TYPE,
        i_doc_area     IN doc_area.id_doc_area%TYPE,
        i_reports      IN reports.id_reports%TYPE,
        i_concept      IN concept.id_concept%TYPE,
        i_market       IN market.id_market%TYPE,
        i_software     IN software.id_software%TYPE,
        i_institution  IN institution.id_institution%TYPE,
        i_doc_template IN NUMBER,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'INSERT_INTO_REP_TEMPLATE_CFG';
        l_dbg_msg debug_msg;
    
    BEGIN
        l_dbg_msg := 'INSERT_INTO_REP_TEMPLATE_CFG';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        MERGE INTO rep_template_cfg rtc
        USING (SELECT i_doc_area     id_doc_area,
                      i_reports      id_reports,
                      i_concept      id_concept,
                      i_market       id_market,
                      i_software     id_software,
                      i_institution  id_institution,
                      i_doc_template id_doc_template
                 FROM dual) args
        ON (rtc.id_doc_area = args.id_doc_area AND rtc.id_reports = args.id_reports AND rtc.id_concept = args.id_concept AND rtc.id_market = args.id_market AND rtc.id_software = args.id_software AND rtc.id_institution = args.id_institution AND rtc.id_doc_template = args.id_doc_template)
        WHEN NOT MATCHED THEN
            INSERT
                (id_rep_template,
                 id_doc_area,
                 id_reports,
                 id_concept,
                 id_market,
                 id_software,
                 id_institution,
                 id_doc_template)
            VALUES
                (seq_rep_template_cfg.nextval,
                 i_doc_area,
                 i_reports,
                 i_concept,
                 i_market,
                 i_software,
                 i_institution,
                 i_doc_template);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END insert_into_rep_template_cfg;

    /********************************************************************************************
    * Get the id_doc_are and id_doc_template for a specific report
    *
    * @param i_lang                   Preferred language ID for this professional    
    * @param i_report                 Report Id
    * @param i_concept                Concept Id
    * @param i_market                 Market Id
    * @param i_software               Software Id
    * @param i_institution            Institution Id                                         
    *
    * @param o_rep_template_cfg       Array with id_doc_area and id_doc_template
    *    
    * @return                         true or false
    *
    * @author                         Ricardo Pires
    * @version                        2.6.4
    * @since                          2014/07/04
    **********************************************************************************************/
    FUNCTION get_rep_template_cfg
    (
        i_lang             IN language.id_language%TYPE,
        i_reports          IN reports.id_reports%TYPE,
        i_concept          IN concept.id_concept%TYPE,
        i_market           IN market.id_market%TYPE,
        i_software         IN software.id_software%TYPE,
        i_institution      IN institution.id_institution%TYPE,
        o_rep_template_cfg OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_REP_TEMPLATE_CFG';
        l_dbg_msg debug_msg;
    
        l_temp_id_reports table_number := table_number();
        l_temp_id_context table_number := table_number();
    
        l_id_reports reports.id_reports%TYPE;
    
    BEGIN
    
        l_dbg_msg := 'get_rep_template_ctg';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
    
        OPEN o_rep_template_cfg FOR
            SELECT cfg.id_doc_area, cfg.id_doc_template
              FROM rep_template_cfg cfg
             WHERE cfg.id_reports = i_reports
               AND cfg.id_concept = i_concept
               AND cfg.id_institution = decode((SELECT COUNT(*) num
                                                 FROM rep_template_cfg cfg2
                                                WHERE cfg2.id_reports = i_reports
                                                  AND cfg2.id_concept = i_concept
                                                  AND cfg2.id_institution = i_institution
                                                  AND cfg2.id_market IN (i_market, pk_alert_constant.g_id_market_all)
                                                  AND cfg2.id_software IN (i_software, pk_alert_constant.g_soft_all)),
                                               0,
                                               pk_alert_constant.g_inst_all,
                                               i_institution)
               AND cfg.id_market = decode((SELECT COUNT(*) num
                                            FROM rep_template_cfg cfg2
                                           WHERE cfg2.id_reports = i_reports
                                             AND cfg2.id_concept = i_concept
                                             AND cfg2.id_institution IN (i_institution, pk_alert_constant.g_inst_all)
                                             AND cfg2.id_market = i_market
                                             AND cfg2.id_software IN (i_software, pk_alert_constant.g_soft_all)),
                                          0,
                                          pk_alert_constant.g_id_market_all,
                                          i_market)
               AND cfg.id_software = decode((SELECT COUNT(*) num
                                              FROM rep_template_cfg cfg2
                                             WHERE cfg2.id_reports = i_reports
                                               AND cfg2.id_concept = i_concept
                                               AND cfg2.id_institution IN (i_institution, pk_alert_constant.g_inst_all)
                                               AND cfg2.id_market IN (i_market, pk_alert_constant.g_id_market_all)
                                               AND cfg2.id_software = i_software),
                                            0,
                                            pk_alert_constant.g_soft_all,
                                            i_software);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(i_cursor => o_rep_template_cfg);
            RETURN FALSE;
        
    END get_rep_template_cfg;

    /********************************************************************************************
    * Get Institution FINESS identifier
    *
    * @param i_lang             Preferred language ID
    * @param i_prof             Professional Array
    *
    * @return                   Value
    *
    * @author                   Tiago Pereira
    * @version                  2.6.4.3
    * @since                    2014/12/29
    ********************************************************************************************/
    FUNCTION get_inst_finess
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_api_backoffice.get_inst_finess(i_lang, i_prof);
    END get_inst_finess;

    /********************************************************************************************
    * Insert new logo for a report by config and rep_group_logos
    *
    *  @param i_id_reports         reports.id_reports%TYPE,
    *  @param i_internal_name      table_varchar,
    *  @param i_inst_owner         V_CONFIG.Id_Inst_Owner%TYPE,
    *  @param i_id_config          V_CONFIG.Id_Config%TYPE,
    *  @param id_rep_group_logos REP_GROUP_LOGOS.ID_REP_GROUP_LOGOS%TYPE,
    *  @param i_is_available       table_varchar,
    *  @param i_file_names         table_varchar
    *
    * @return                   true if sucess, false if ocurred and error
    *
    * @author                   Tiago Pereira
    * @version                  2.6.4.3.1
    * @since                    05/03/2015
    ********************************************************************************************/
    FUNCTION insert_logo_report_logos
    (
        i_id_reports         reports.id_reports%TYPE,
        i_internal_name      table_varchar,
        i_inst_owner         v_config.id_inst_owner%TYPE,
        i_id_config          v_config.id_config%TYPE,
        i_id_rep_group_logos rep_group_logos.id_rep_group_logos%TYPE,
        i_is_available       table_varchar,
        i_file_names         table_varchar
    ) RETURN BOOLEAN IS
        l_area                 VARCHAR2(30) := 'REP_GROUP_LOGOS';
        l_count                NUMBER(24) := 1;
        l_internal_name        rep_logos.internal_name%TYPE;
        l_is_available         rep_logos.flg_available%TYPE;
        dest_loc               BLOB;
        l_have_regists         NUMBER(24) := 0;
        src_loc                BFILE;
        l_sys_config           VARCHAR2(30) := 'REP_LOGOS_DIRECTORY';
        full_path_directory    VARCHAR2(1000);
        l_file_name            VARCHAR2(1000);
        l_directory_sys_config sys_config.value%TYPE;
    
    BEGIN
    
        IF i_id_config IS NOT NULL
        THEN
            pk_alertlog.log_debug(' configuration was entered');
            IF i_internal_name IS NOT NULL
               AND i_internal_name.count > 0
            THEN
            
                FOR l_count IN 1 .. i_internal_name.count
                LOOP
                    l_internal_name := i_internal_name(l_count);
                    l_is_available  := i_is_available(l_count);
                    l_file_name     := i_file_names(l_count);
                
                    SELECT COUNT(*)
                      INTO l_have_regists
                      FROM rep_logos rl
                     WHERE rl.internal_name = l_internal_name
                       AND rl.id_rep_group_logos = i_id_rep_group_logos;
                    IF l_have_regists = 0
                    THEN
                    
                        INSERT INTO rep_logos
                            (id_rep_logos, internal_name, flg_available, image_logo, id_rep_group_logos)
                        VALUES
                            (seq_rep_logos.nextval,
                             l_internal_name,
                             l_is_available,
                             empty_blob(),
                             i_id_rep_group_logos)
                        RETURNING image_logo INTO dest_loc;
                    
                        SELECT s.value
                          INTO l_directory_sys_config
                          FROM sys_config s
                         WHERE s.id_sys_config = l_sys_config;
                    
                        src_loc := bfilename(l_directory_sys_config, l_file_name);
                    
                        dbms_lob.open(src_loc);
                    
                        dbms_lob.open(dest_loc, dbms_lob.lob_readwrite);
                    
                        dbms_lob.loadfromfile(dest_lob => dest_loc,
                                              src_lob  => src_loc,
                                              amount   => dbms_lob.getlength(src_loc));
                    
                        dbms_lob.close(dest_loc);
                        dbms_lob.close(src_loc);
                    
                    ELSE
                        pk_alertlog.log_debug('No logos internal_name was entered');
                    END IF;
                
                END LOOP;
            
                pk_core_config.insert_into_config_table(i_config_table  => l_area,
                                                        i_id_record     => i_id_reports,
                                                        i_id_inst_owner => i_inst_owner,
                                                        i_id_config     => i_id_config,
                                                        i_field_01      => i_id_rep_group_logos);
            
                pk_core_config.recreate_ea(i_config_table => l_area);
            
            ELSE
                pk_alertlog.log_debug('No logos internal_name was entered');
                RETURN FALSE;
            END IF;
        
        ELSE
            pk_alertlog.log_debug('No configuration was entered');
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    END insert_logo_report_logos;

    /********************************************************************************************
    * Insert new rep group logos config to group multiple logos
    *
    * @param i_report_group_description             The description of group id
    *
    * @return                   true if sucess, false if ocurred and error
    *
    * @author                   Tiago Pereira
    * @version                  2.6.5.0
    * @since                    19/03/2015
    ********************************************************************************************/

    FUNCTION insert_report_group_logos(i_report_group_description rep_group_logos.rep_description%TYPE) RETURN BOOLEAN IS
    BEGIN
        INSERT INTO rep_group_logos
            (id_rep_group_logos, rep_description)
        VALUES
            (seq_rep_group_logo.nextval, i_report_group_description);
    
        pk_alertlog.log_debug('new id id_rep_group_logos: ' || seq_rep_group_logo.currval);
    
        RETURN TRUE;
    END insert_report_group_logos;

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION get_presc_pharm_validated
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_reports       IN NUMBER, -- JSON.ID_REPORTS
        i_filter_name      IN VARCHAR2, -- JSON.GENERIC_PARAMETER_1
        i_id_episode       presc.id_epis_create%TYPE, -- JSON.ID_EPISODE
        i_lov_id           IN NUMBER, -- JSON.GENERIC_PARAMETER_3,
        i_dt_begin         IN VARCHAR2, -- JSON.DT_BEGIN
        i_dt_end           IN VARCHAR2, -- JSON.DT_END
        i_id_custom_filter IN NUMBER, -- JSON.XXX
        o_pharm_val_info   OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_PRESC_PHARM_VALIDATED';
    
    BEGIN
        RETURN pk_rt_med_pfh.get_presc_pharm_validated(i_lang             => i_lang,
                                                       i_prof             => i_prof,
                                                       i_id_reports       => i_id_reports,
                                                       i_filter_name      => i_filter_name,
                                                       i_id_episode       => i_id_episode,
                                                       i_lov_id           => i_lov_id,
                                                       i_dt_begin         => i_dt_begin,
                                                       i_dt_end           => i_dt_end,
                                                       i_id_custom_filter => i_id_custom_filter,
                                                       o_pharm_val_info   => o_pharm_val_info,
                                                       o_error            => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text            => SQLERRM,
                                  object_name     => 'PK_REPORTS_API',
                                  sub_object_name => l_db_object_name);
        
            RETURN FALSE;
    END get_presc_pharm_validated;

    /********************************************************************************************
    * Gets the last prescription printed for this patient, section "Last Ambulatory Prescription". 
    *
    * @param  i_lang                        The language ID
    * @param  i_prof                        The professional array
    * @param  i_id_patient                  The Patient ID
    
    * @param  o_info                        Output cursor with medication description, dosage, frequency 
    *
    * @author CRISTINA.OLIVEIRA
    * @since  2016-06-28
    ********************************************************************************************/
    FUNCTION get_presc_printed_by_patient
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN presc.id_patient%TYPE,
        o_info       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_PRESC_PRINTED_BY_PATIENT';
    
    BEGIN
    
        RETURN pk_rt_med_pfh.get_presc_printed_by_patient(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                          i_id_patient => i_id_patient,
                                                          o_info       => o_info,
                                                          o_error      => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text => SQLERRM, object_name => c_package_name, sub_object_name => l_db_object_name);
        
            RETURN FALSE;
    END get_presc_printed_by_patient;

    /********************************************************************************************
    * Function that returns the informtaion of diagnosis by id_epis_diagnosis
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_episode                episode ID
    * @param i_epis_diag              episode diagnosis ID
     *
    * @return                         diagnosis general info
    *
    *
    * @author                         Elisabete Bugalho
    * @version                        2.7.0
    * @since                          16/11/2016
    **********************************************************************************************/
    FUNCTION get_epis_diag_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        i_flg_type  IN epis_diagnosis.flg_type%TYPE,
        i_epis_diag IN table_number,
        o_epis_diag OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_EPIS_DIAG_LIST';
    BEGIN
        RETURN pk_diagnosis_core.get_epis_diag_list(i_lang      => i_lang,
                                                    i_prof      => i_prof,
                                                    i_episode   => i_episode,
                                                    i_flg_type  => i_flg_type,
                                                    i_epis_diag => i_epis_diag,
                                                    o_epis_diag => o_epis_diag,
                                                    o_error     => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text => SQLERRM, object_name => c_package_name, sub_object_name => l_db_object_name);
        
            RETURN FALSE;
    END get_epis_diag_list;

    FUNCTION get_grid_hand_off_det
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_patient           IN patient.id_patient%TYPE,
        i_id_epis_prof_resp IN epis_prof_resp.id_epis_prof_resp%TYPE,
        o_diag              OUT pk_types.cursor_type,
        o_sign_v            OUT pk_types.cursor_type,
        o_title_analy       OUT table_clob,
        o_analysis          OUT table_clob,
        o_title_ex_imag     OUT table_clob,
        o_exam_imag         OUT table_clob,
        o_title_exams       OUT table_clob,
        o_exams             OUT table_clob,
        o_title_drug        OUT table_clob,
        o_drug              OUT table_clob,
        o_title_interv      OUT table_clob,
        o_intervention      OUT table_clob,
        o_hidrics           OUT pk_types.cursor_type,
        o_allergies         OUT pk_types.cursor_type,
        o_diets             OUT pk_types.cursor_type,
        o_precautions       OUT pk_types.cursor_type,
        o_icnp_diag         OUT pk_types.cursor_type,
        --
        o_title_handoff OUT VARCHAR2,
        o_handoff       OUT pk_types.cursor_type,
        --
        o_patient    OUT patient.id_patient%TYPE,
        o_episode    OUT episode.id_episode%TYPE,
        o_sbar_note  OUT CLOB,
        o_title_sbar OUT VARCHAR2,
        o_id_epis_pn OUT epis_pn.id_epis_pn%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_GRID_HAND_OFF_DET';
    BEGIN
        RETURN pk_hand_off.get_grid_hand_off_det(i_lang              => i_lang,
                                                 i_prof              => i_prof,
                                                 i_episode           => i_episode,
                                                 i_patient           => i_patient,
                                                 i_id_epis_prof_resp => i_id_epis_prof_resp,
                                                 o_diag              => o_diag,
                                                 o_sign_v            => o_sign_v,
                                                 o_title_analy       => o_title_analy,
                                                 o_analysis          => o_analysis,
                                                 o_title_ex_imag     => o_title_ex_imag,
                                                 o_exam_imag         => o_exam_imag,
                                                 o_title_exams       => o_title_exams,
                                                 o_exams             => o_exams,
                                                 o_title_drug        => o_title_drug,
                                                 o_drug              => o_drug,
                                                 o_title_interv      => o_title_interv,
                                                 o_intervention      => o_intervention,
                                                 o_hidrics           => o_hidrics,
                                                 o_allergies         => o_allergies,
                                                 o_diets             => o_diets,
                                                 o_precautions       => o_precautions,
                                                 o_icnp_diag         => o_icnp_diag,
                                                 o_title_handoff     => o_title_handoff,
                                                 o_handoff           => o_handoff,
                                                 o_patient           => o_patient,
                                                 o_episode           => o_episode,
                                                 o_sbar_note         => o_sbar_note,
                                                 o_title_sbar        => o_title_sbar,
                                                 o_id_epis_pn        => o_id_epis_pn,
                                                 o_error             => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text => SQLERRM, object_name => c_package_name, sub_object_name => l_db_object_name);
        
            RETURN FALSE;
    END get_grid_hand_off_det;
    --

    FUNCTION get_pats_from_pref_dept
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        o_cursor OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_inp_grid.get_pats_from_pref_dept(i_lang   => i_lang,
                                                   i_prof   => i_prof,
                                                   o_cursor => o_cursor,
                                                   o_error  => o_error);
    
    END get_pats_from_pref_dept;

    /* *
    * Returns shifts summary notes for the 24h
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_start_date             initial date
    * @param i_end_date               final date
    * @param i_tbl_episode            list of episode
    *
    * @return                         description
    *
    * @author               Carlos FErreira
    * @version              2.7.1
    * @since                28-04-2017
    */
    FUNCTION get_rep_pn_24h
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_start_date  IN VARCHAR2,
        i_end_date    IN VARCHAR2,
        i_tbl_episode IN table_number,
        o_data        OUT NOCOPY pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_prog_notes_grids.get_rep_pn_24h(i_lang        => i_lang,
                                                  i_prof        => i_prof,
                                                  i_start_date  => i_start_date,
                                                  i_end_date    => i_end_date,
                                                  i_tbl_episode => i_tbl_episode,
                                                  o_data        => o_data,
                                                  o_error       => o_error);
    
    END get_rep_pn_24h;

    /**
    * Function to get the aih simple information to the AIH report
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_id_episode   Episode identifier
    * @param   i_id_patient   Patient identifier
    *
    * @param   o_data         AIH episode/patient data
    * @param   o_error        Error information
    *
    * @return  Boolean
    *
    * @author  Sofia Mendes
    * @version 2.7.1
    * @since   04-Set-2017
    */
    FUNCTION get_aih_simple_report
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_epis_pn IN epis_pn.id_epis_pn%TYPE,
        o_data       OUT NOCOPY pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN AS
    BEGIN
    
        RETURN pk_aih.get_aih_simple_report(i_lang       => i_lang,
                                            i_prof       => i_prof,
                                            i_id_episode => i_id_episode,
                                            i_id_patient => i_id_patient,
                                            i_id_epis_pn => i_id_epis_pn,
                                            o_data       => o_data,
                                            o_error      => o_error);
    END get_aih_simple_report;

    /**
    * Function to get the aih special information to the AIH report
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_id_episode   Episode identifier
    * @param   i_id_patient   Patient identifier
    * @param   i_id_epis_pn   Single Page note id
    *
    * @param   o_data         AIH episode/patient data
    * @param   o_error        Error information
    *
    * @return  Boolean
    *
    * @author  Sofia Mendes
    * @version 2.7.1
    * @since   04-Set-2017
    */
    FUNCTION get_aih_special_report
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_id_patient    IN patient.id_patient%TYPE,
        i_id_epis_pn    IN epis_pn.id_epis_pn%TYPE,
        o_data          OUT NOCOPY pk_types.cursor_type,
        o_repeated_data OUT NOCOPY pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN AS
    BEGIN
    
        RETURN pk_aih.get_aih_special_report(i_lang          => i_lang,
                                             i_prof          => i_prof,
                                             i_id_episode    => i_id_episode,
                                             i_id_patient    => i_id_patient,
                                             i_id_epis_pn    => i_id_epis_pn,
                                             o_data          => o_data,
                                             o_repeated_data => o_repeated_data,
                                             o_error         => o_error);
    END get_aih_special_report;

    /**********************************************************************************************
    * Returns a list of all the supply requests and consumptions, grouped by status.
    * 
    * @i_lang  Language ID
    * @i_prof  Professional's info
    * @i_id_supply_area   supply area ID
    * @i_patient Patient's id
    * @i_episode Current Episode
    * @o_list  list of all the supply requests and consumptions
    * @o_error Error info
    * 
    * @return  True on success, false on error
    *
    * @author  João Almeida
    * @version 2.5.0.7
    * @since   9/11/09
    **********************************************************************************************/

    FUNCTION get_list_req_cons_no_cat
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_supply_area IN supply_area.id_supply_area%TYPE,
        i_patient        IN episode.id_patient%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_flg_type       IN table_varchar,
        i_flg_status     IN table_varchar,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF NOT pk_supplies_core.get_list_req_cons_no_cat(i_lang           => i_lang,
                                                         i_prof           => i_prof,
                                                         i_id_supply_area => i_id_supply_area,
                                                         i_patient        => i_patient,
                                                         i_episode        => i_episode,
                                                         i_flg_type       => i_flg_type,
                                                         i_flg_status     => i_flg_status,
                                                         o_list           => o_list,
                                                         o_error          => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text            => SQLERRM,
                                  object_name     => c_package_name,
                                  sub_object_name => 'GET_LIST_REQ_CONS_NO_CAT');
            RETURN FALSE;
    END get_list_req_cons_no_cat;

    FUNCTION get_supply_wf_det
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_sup_wf IN supply_workflow.id_supply_workflow%TYPE,
        o_register  OUT pk_types.cursor_type,
        o_req       OUT pk_types.cursor_type,
        o_canceled  OUT pk_types.cursor_type,
        o_rejected  OUT pk_types.cursor_type,
        o_consumed  OUT pk_types.cursor_type,
        o_others    OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF NOT pk_supplies_core.get_supply_detail(i_lang      => i_lang,
                                                  i_prof      => i_prof,
                                                  i_id_sup_wf => i_id_sup_wf,
                                                  o_register  => o_register,
                                                  o_req       => o_req,
                                                  o_canceled  => o_canceled,
                                                  o_rejected  => o_rejected,
                                                  o_consumed  => o_consumed,
                                                  o_others    => o_others,
                                                  o_error     => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text            => SQLERRM,
                                  object_name     => c_package_name,
                                  sub_object_name => 'GET_SUPPLY_WF_DET');
        
            pk_types.open_my_cursor(o_register);
            pk_types.open_my_cursor(o_canceled);
            pk_types.open_my_cursor(o_rejected);
            pk_types.open_my_cursor(o_consumed);
            pk_types.open_my_cursor(o_others);
            pk_types.open_my_cursor(o_req);
        
            RETURN FALSE;
    END get_supply_wf_det;

    FUNCTION get_list_req_cons_report
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN episode.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_flg_type   IN supply.flg_type%TYPE,
        i_flg_status IN table_varchar,
        o_list       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF NOT pk_supplies_core.get_list_req_cons_report(i_lang       => i_lang,
                                                         i_prof       => i_prof,
                                                         i_patient    => i_patient,
                                                         i_episode    => i_episode,
                                                         i_flg_type   => i_flg_type,
                                                         i_flg_status => i_flg_status,
                                                         o_list       => o_list,
                                                         o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text            => SQLERRM,
                                  object_name     => c_package_name,
                                  sub_object_name => 'GET_LIST_REQ_CONS_REPORT');
            RETURN FALSE;
    END get_list_req_cons_report;

    FUNCTION get_supplies_consumed_counted
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        o_sup_cons_count OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_function_name VARCHAR2(30 CHAR) := 'GET_SUPPLIES_CONSUMED_COUNTED';
    
    BEGIN
    
        OPEN o_sup_cons_count FOR
            SELECT t.id_supply,
                   t.desc_supply,
                   t.desc_supply_attrib,
                   t.desc_supply_type,
                   t.cod_table desc_table,
                   SUM(ssc.qty_added) qty_added,
                   --ssc.qty_added,
                   ssc.id_sr_supply_count,
                   SUM(ssc.qty_final_count) qty_final,
                   --ssc.qty_final_count qty_final,
                   SUM(t.qty_before) qty_before
            --t.qty_before
              FROM TABLE(pk_supplies_core.tf_surg_supply_count(i_lang, i_prof, i_id_episode, NULL)) t
             INNER JOIN sr_supply_count ssc
                ON ssc.id_sr_supply_count = t.id_sr_supply_count
             GROUP BY t.id_supply,
                      t.desc_supply,
                      t.desc_supply_attrib,
                      t.desc_supply_type,
                      t.cod_table,
                      ssc.id_sr_supply_count;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              '',
                                              c_package_owner,
                                              c_package_name,
                                              l_function_name,
                                              o_error);
            pk_types.open_my_cursor(o_sup_cons_count);
            RETURN FALSE;
    END get_supplies_consumed_counted;

    FUNCTION get_supply_count_detail
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_sr_supply_count  IN sr_supply_count.id_sr_supply_count%TYPE,
        o_supply_count_detail OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_function_name VARCHAR2(30 CHAR) := 'GET_SUPPLY_COUNT_DETAIL';
        l_code_messages table_varchar := table_varchar('SR_SUPPLIES_M040',
                                                       'SR_SUPPLIES_M043',
                                                       'SR_SUPPLIES_M034',
                                                       'SR_SUPPLIES_M044',
                                                       'SR_SUPPLIES_M045',
                                                       'SR_SUPPLIES_M046',
                                                       'SR_SUPPLIES_M047',
                                                       'SR_SUPPLIES_M025',
                                                       'SR_SUPPLIES_M026',
                                                       'SR_SUPPLIES_M027');
    
        TYPE t_code_messages IS TABLE OF VARCHAR2(2000 CHAR) INDEX BY sys_message.code_message%TYPE;
        aa_code_messages t_code_messages;
    
    BEGIN
    
        FOR i IN l_code_messages.first .. l_code_messages.last
        LOOP
            aa_code_messages(l_code_messages(i)) := pk_message.get_message(i_lang, l_code_messages(i));
        END LOOP;
    
        OPEN o_supply_count_detail FOR
            SELECT 10 rank,
                   ssc.id_sr_supply_count,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, ssc.dt_reg, i_prof) tstamp,
                   ssc.dt_reg timestamp_order,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ssc.id_prof_reg) professional,
                   pk_string_utils.surround(pk_prof_utils.get_spec_signature(i_lang,
                                                                             i_prof,
                                                                             ssc.id_prof_reg,
                                                                             ssc.dt_reg,
                                                                             NULL),
                                            pk_string_utils.g_pattern_parenthesis) speciality,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, ssc.id_prof_reg, ssc.dt_reg, NULL) spec_report,
                   t.id_supply,
                   aa_code_messages('SR_SUPPLIES_M047') supply_name_label,
                   t.desc_supply,
                   aa_code_messages('SR_SUPPLIES_M034') supply_attrib_label,
                   t.desc_supply_attrib,
                   aa_code_messages('SR_SUPPLIES_M043') supply_attrib_label1,
                   t.flg_type supply_type,
                   t.desc_supply_type,
                   t.id_supply_type,
                   t.desc_code_supply_type,
                   aa_code_messages('SR_SUPPLIES_M046') qty_before_label,
                   t.qty_before,
                   aa_code_messages('SR_SUPPLIES_M045') qty_added_label,
                   nvl(ssc.qty_added, 0) qty_added,
                   aa_code_messages('SR_SUPPLIES_M044') qty_final_label,
                   ssc.qty_final_count qty_final,
                   CASE
                        WHEN ssc.id_reconcile_reason IS NOT NULL THEN
                         aa_code_messages('SR_SUPPLIES_M025')
                    END title_reconcile_reason_label,
                   CASE
                        WHEN ssc.id_reconcile_reason IS NOT NULL THEN
                         aa_code_messages('SR_SUPPLIES_M026')
                    END reconcile_reason_label,
                   CASE
                        WHEN ssc.id_reconcile_reason IS NOT NULL THEN
                         pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, ssc.id_reconcile_reason)
                    END reconcile_reason,
                   CASE
                        WHEN ssc.id_reconcile_reason IS NOT NULL THEN
                         aa_code_messages('SR_SUPPLIES_M027')
                    END notes_label,
                   CASE
                        WHEN ssc.id_reconcile_reason IS NOT NULL THEN
                         nvl(ssc.notes, pk_supplies_constant.g_dashes)
                    END notes,
                   aa_code_messages('SR_SUPPLIES_M040') cod_table_label,
                   t.cod_table
              FROM TABLE(pk_supplies_core.tf_surg_supply_count(i_lang, i_prof, i_id_episode, i_id_sr_supply_count)) t
             INNER JOIN sr_supply_count ssc
                ON ssc.id_sr_supply_count = t.id_sr_supply_count
            UNION ALL
            SELECT 100 rank,
                   ssch.id_sr_supply_count,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, ssch.dt_reg, i_prof) tstamp,
                   ssch.dt_reg timestamp_order,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ssch.id_prof_reg) professional,
                   pk_string_utils.surround(pk_prof_utils.get_spec_signature(i_lang,
                                                                             i_prof,
                                                                             ssch.id_prof_reg,
                                                                             ssch.dt_reg,
                                                                             NULL),
                                            pk_string_utils.g_pattern_parenthesis) speciality,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, ssch.id_prof_reg, ssch.dt_reg, NULL) spec_report,
                   t.id_supply,
                   aa_code_messages('SR_SUPPLIES_M047') supply_name_label,
                   t.desc_supply,
                   aa_code_messages('SR_SUPPLIES_M034') supply_attrib_label,
                   t.desc_supply_attrib,
                   aa_code_messages('SR_SUPPLIES_M043') supply_attrib_label1,
                   t.flg_type supply_type,
                   t.desc_supply_type,
                   t.id_supply_type,
                   t.desc_code_supply_type desc_code_supply_type,
                   aa_code_messages('SR_SUPPLIES_M046') qty_before_label,
                   t.qty_before,
                   aa_code_messages('SR_SUPPLIES_M045') qty_added_label,
                   nvl(ssch.qty_added, 0) qty_added,
                   aa_code_messages('SR_SUPPLIES_M044') qty_final_label,
                   ssch.qty_final_count,
                   CASE
                       WHEN ssch.id_reconcile_reason IS NOT NULL THEN
                        aa_code_messages('SR_SUPPLIES_M025')
                   END title_reconcile_reason_label,
                   CASE
                       WHEN ssch.id_reconcile_reason IS NOT NULL THEN
                        aa_code_messages('SR_SUPPLIES_M026')
                   END reconcile_reason_label,
                   CASE
                       WHEN ssch.id_reconcile_reason IS NOT NULL THEN
                        pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, ssch.id_reconcile_reason)
                   END reconcile_reason,
                   CASE
                       WHEN ssch.id_reconcile_reason IS NOT NULL THEN
                        aa_code_messages('SR_SUPPLIES_M027')
                   END notes_label,
                   CASE
                       WHEN ssch.id_reconcile_reason IS NOT NULL THEN
                        nvl(ssch.notes, pk_supplies_constant.g_dashes)
                   END notes,
                   aa_code_messages('SR_SUPPLIES_M040') cod_table_label,
                   t.cod_table
              FROM TABLE(pk_supplies_core.tf_surg_supply_count(i_lang, i_prof, i_id_episode, i_id_sr_supply_count)) t
             INNER JOIN sr_supply_count_hist ssch
                ON ssch.id_sr_supply_count = t.id_sr_supply_count
             ORDER BY rank, timestamp_order DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              '',
                                              c_package_owner,
                                              c_package_name,
                                              l_function_name,
                                              o_error);
            pk_types.open_my_cursor(o_supply_count_detail);
            RETURN FALSE;
    END get_supply_count_detail;

    FUNCTION get_list_req_cons
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN episode.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF NOT pk_supplies_core.get_supply_listview(i_lang           => i_lang,
                                                    i_prof           => i_prof,
                                                    i_id_supply_area => NULL,
                                                    i_patient        => i_patient,
                                                    i_episode        => i_episode,
                                                    i_flg_type       => table_varchar(pk_supplies_constant.g_supply_set_type,
                                                                                      pk_supplies_constant.g_supply_kit_type,
                                                                                      pk_supplies_constant.g_supply_type,
                                                                                      pk_supplies_constant.g_supply_equipment_type,
                                                                                      pk_supplies_constant.g_supply_implant_type),
                                                    o_list           => o_list,
                                                    o_error          => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              '',
                                              c_package_owner,
                                              c_package_name,
                                              'GET_LIST_REQ_CONS',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_list_req_cons;

    FUNCTION get_epis_prof
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        o_id_professional OUT professional.id_professional%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        o_id_professional := pk_episode.get_epis_prof(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              '',
                                              c_package_owner,
                                              c_package_name,
                                              'GET_EPIS_PROF',
                                              o_error);
            RETURN FALSE;
    END get_epis_prof;

    FUNCTION get_adm_surg_request
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN episode.id_episode%TYPE,
        i_id_waiting_list   IN waiting_list.id_waiting_list%TYPE,
        o_adm_request       OUT pk_types.cursor_type,
        o_diag              OUT pk_types.cursor_type,
        o_surg_specs        OUT pk_types.cursor_type,
        o_pref_surg         OUT pk_types.cursor_type,
        o_procedures        OUT pk_types.cursor_type,
        o_ext_disc          OUT pk_types.cursor_type,
        o_danger_cont       OUT pk_types.cursor_type,
        o_preferred_time    OUT pk_types.cursor_type,
        o_pref_time_reason  OUT pk_types.cursor_type,
        o_pos               OUT pk_types.cursor_type,
        o_surg_request      OUT pk_types.cursor_type,
        o_waiting_list      OUT pk_types.cursor_type,
        o_unavailabilities  OUT pk_types.cursor_type,
        o_sched_period      OUT pk_types.cursor_type,
        o_referral          OUT pk_types.cursor_type,
        o_doc_area_register OUT pk_types.cursor_type,
        o_doc_area_val      OUT pk_types.cursor_type,
        o_doc_scales        OUT pk_types.cursor_type,
        o_pos_validation    OUT pk_types.cursor_type,
        -- Clinical Questions
        o_interv_clinical_questions OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_wtl_api_ui.get_adm_surg_request(i_lang                      => i_lang,
                                                  i_prof                      => i_prof,
                                                  i_id_episode                => i_id_episode,
                                                  i_id_waiting_list           => i_id_waiting_list,
                                                  o_adm_request               => o_adm_request,
                                                  o_diag                      => o_diag,
                                                  o_surg_specs                => o_surg_specs,
                                                  o_pref_surg                 => o_pref_surg,
                                                  o_procedures                => o_procedures,
                                                  o_ext_disc                  => o_ext_disc,
                                                  o_danger_cont               => o_danger_cont,
                                                  o_preferred_time            => o_preferred_time,
                                                  o_pref_time_reason          => o_pref_time_reason,
                                                  o_pos                       => o_pos,
                                                  o_surg_request              => o_surg_request,
                                                  o_waiting_list              => o_waiting_list,
                                                  o_unavailabilities          => o_unavailabilities,
                                                  o_sched_period              => o_sched_period,
                                                  o_referral                  => o_referral,
                                                  o_doc_area_register         => o_doc_area_register,
                                                  o_doc_area_val              => o_doc_area_val,
                                                  o_doc_scales                => o_doc_scales,
                                                  o_pos_validation            => o_pos_validation,
                                                  o_interv_clinical_questions => o_interv_clinical_questions,
                                                  o_error                     => o_error);
    END get_adm_surg_request;

    /********************************************************************************************
    * Get patient delivery information
    *
    * @param i_lang             The language ID
    * @param i_prof             Object (professional ID, institution ID, software ID)
    * @param i_patient          Patient ID
    * @param o_info             cursor with all information
    * @param o_error            Error message
    *
    * @return                   true or false on success or error
    *
    * @author                   Elisabete Bugalho
    * @version                  2.7.4.0
    * @since                    2018-09-10
    **********************************************************************************************/
    FUNCTION get_patient_delivery_info
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN NUMBER,
        o_info    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_delivery.get_patient_delivery_info(i_lang    => i_lang,
                                                     i_prof    => i_prof,
                                                     i_patient => i_patient,
                                                     o_info    => o_info,
                                                     o_error   => o_error);
    
    END get_patient_delivery_info;

    FUNCTION get_bp_detail
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_blood_product_det     IN blood_product_det.id_blood_product_det%TYPE,
        o_bp_detail             OUT pk_types.cursor_type,
        o_bp_clinical_questions OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_bp_external_api_db.get_bp_detail(i_lang                  => i_lang,
                                                   i_prof                  => i_prof,
                                                   i_episode               => i_episode,
                                                   i_blood_product_det     => i_blood_product_det,
                                                   o_bp_detail             => o_bp_detail,
                                                   o_bp_clinical_questions => o_bp_clinical_questions,
                                                   o_error                 => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              '',
                                              c_package_owner,
                                              c_package_name,
                                              'GET_BP_DETAIL',
                                              o_error);
            pk_types.open_my_cursor(o_bp_detail);
            pk_types.open_my_cursor(o_bp_clinical_questions);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_bp_detail;

    FUNCTION get_bp_detail_history
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_blood_product_det     IN blood_product_det.id_blood_product_det%TYPE,
        o_bp_detail             OUT pk_types.cursor_type,
        o_bp_clinical_questions OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_bp_external_api_db.get_bp_detail_history(i_lang                  => i_lang,
                                                           i_prof                  => i_prof,
                                                           i_episode               => i_episode,
                                                           i_blood_product_det     => i_blood_product_det,
                                                           o_bp_detail             => o_bp_detail,
                                                           o_bp_clinical_questions => o_bp_clinical_questions,
                                                           o_error                 => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              '',
                                              c_package_owner,
                                              c_package_name,
                                              'GET_BP_DETAIL_HISTORY',
                                              o_error);
            pk_types.open_my_cursor(o_bp_detail);
            pk_types.open_my_cursor(o_bp_clinical_questions);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_bp_detail_history;

    FUNCTION get_bp_task_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        i_flg_scope IN VARCHAR2,
        i_scope     IN NUMBER,
        o_bp_list   OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_bp_external_api_db.get_bp_task_list(i_lang      => i_lang,
                                                      i_prof      => i_prof,
                                                      i_episode   => i_episode,
                                                      i_flg_scope => i_flg_scope,
                                                      i_scope     => i_scope,
                                                      o_bp_list   => o_bp_list,
                                                      o_error     => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              '',
                                              c_package_owner,
                                              c_package_name,
                                              'GET_BP_TASK_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_bp_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_bp_task_list;

    FUNCTION get_bp_adverse_reaction_rep
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_blood_product_det   IN blood_product_det.id_blood_product_det%TYPE,
        o_data_transfusion    OUT pk_types.cursor_type,
        o_data_vital_signs    OUT pk_types.cursor_type,
        o_data_clinical_sympt OUT VARCHAR2,
        o_data_medicine       OUT VARCHAR2,
        o_data_lab_tests_list OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_bp_external_api_db.get_bp_adverse_reaction(i_lang                => i_lang,
                                                             i_prof                => i_prof,
                                                             i_blood_product_det   => i_blood_product_det,
                                                             o_data_transfusion    => o_data_transfusion,
                                                             o_data_vital_signs    => o_data_vital_signs,
                                                             o_data_clinical_sympt => o_data_clinical_sympt,
                                                             o_data_medicine       => o_data_medicine,
                                                             o_data_lab_tests_list => o_data_lab_tests_list,
                                                             o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              '',
                                              c_package_owner,
                                              c_package_name,
                                              'GET_BP_ADVERSE_REACTION_REP',
                                              o_error);
            pk_types.open_my_cursor(o_data_transfusion);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_bp_adverse_reaction_rep;

    FUNCTION get_surg_request_by_oris_epis
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_id_episode                IN episode.id_episode%TYPE,
        o_prof_resp                 OUT professional.id_professional%TYPE,
        o_procedures                OUT pk_types.cursor_type,
        o_interv_clinical_questions OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF NOT pk_surgery_request.get_surg_request_by_oris_epis(i_lang                      => i_lang,
                                                                i_prof                      => i_prof,
                                                                i_id_episode                => i_id_episode,
                                                                o_prof_resp                 => o_prof_resp,
                                                                o_procedures                => o_procedures,
                                                                o_interv_clinical_questions => o_interv_clinical_questions,
                                                                o_error                     => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              '',
                                              c_package_owner,
                                              c_package_name,
                                              'GET_SURG_REQUEST_BY_ORIS_EPIS',
                                              o_error);
            pk_types.open_my_cursor(o_procedures);
            pk_types.open_my_cursor(o_interv_clinical_questions);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_surg_request_by_oris_epis;

    FUNCTION get_report_cfg_adv_reaction
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_rep_section       IN rep_section.id_rep_section%TYPE,
        i_report            IN reports.id_reports%TYPE,
        i_task_type_context IN rep_section_cfg_inst_soft.id_task_type_context%TYPE,
        o_cursor            OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_profile_template profile_template.id_profile_template%TYPE;
    
    BEGIN
    
        l_profile_template := pk_prof_utils.get_prof_profile_template(i_prof => i_prof);
    
        IF i_task_type_context = pk_alert_constant.g_task_lab_tests
        THEN
            OPEN o_cursor FOR
                SELECT t.rep_section_area,
                       t.id_context,
                       pk_lab_tests_utils.get_alias_translation(i_lang,
                                                                i_prof,
                                                                'A',
                                                                'ANALYSIS.CODE_ANALYSIS.' || t.id_analysis,
                                                                'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || t.id_sample_type,
                                                                NULL) translation,
                       t.rank
                  FROM (SELECT rscis.rep_section_area,
                               rscis.id_context,
                               ast.id_analysis,
                               ast.id_sample_type,
                               rscis.rank,
                               dense_rank() over(PARTITION BY rscis.rep_section_area, rscis.id_context ORDER BY rscis.id_rep_section DESC, rscis.id_rep_profile_template DESC) rn
                          FROM rep_section_cfg_inst_soft rscis, analysis_sample_type ast
                         WHERE rscis.id_reports = i_report
                           AND rscis.id_task_type_context = i_task_type_context
                           AND rscis.id_rep_section IN (0, i_rep_section)
                           AND rscis.id_software = i_prof.software
                           AND rscis.id_institution = i_prof.institution
                           AND rscis.id_rep_profile_template IN (0, l_profile_template)
                           AND rscis.id_context = ast.id_content) t
                 WHERE t.rn = 1
                 ORDER BY t.rank ASC;
        ELSE
            pk_types.open_my_cursor(o_cursor);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              '',
                                              c_package_owner,
                                              c_package_name,
                                              'GET_REPORT_CFG_ADV_REACTION',
                                              o_error);
            pk_types.open_my_cursor(o_cursor);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_report_cfg_adv_reaction;

    /********************************************************************************************
    * GET_MAP_A_B - Returns the b value that matches all the other parameters passed
    *
    * @param i_a_system              IN MAPS.a_system%TYPE
    * @param i_a_definition          IN MAPS.a_def%TYPE
    * @param i_a_value               IN MAPS.a_value%TYPE
    * @param i_b_system              IN MAPS.b_system%TYPE
    * @param i_b_definition          IN MAPS.b_def%TYPE
    * @param i_b_value               IN MAPS.b_value%TYPE
    *
    * @return                The mapped value
    *
    * @author                filipe.f.pereira
    * @version               1.0
    * @since                15/07/2019
    ********************************************************************************************/
    FUNCTION get_map_a_b
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_a_system     IN pk_translation.t_desc_translation,
        i_b_system     IN pk_translation.t_desc_translation,
        i_a_value      IN pk_translation.t_desc_translation,
        i_a_definition IN pk_translation.t_desc_translation,
        i_b_definition IN pk_translation.t_desc_translation,
        o_b_value      OUT NOCOPY VARCHAR2,
        o_error        OUT NOCOPY VARCHAR2
    ) RETURN BOOLEAN IS
        l_error_out t_error_out;
        l_exception EXCEPTION;
    BEGIN
    
        IF NOT pk_map.get_map_a_b(i_a_system       => i_a_system,
                                  i_b_system       => i_b_system,
                                  i_a_value        => i_a_value,
                                  i_a_definition   => i_a_definition,
                                  i_b_definition   => i_b_definition,
                                  i_id_institution => 0,
                                  i_id_software    => 0,
                                  o_b_value        => o_b_value,
                                  o_error          => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              '',
                                              c_package_owner,
                                              c_package_name,
                                              'get_map_a_b',
                                              l_error_out);
        
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_map_a_b;

    FUNCTION get_positioning_rep
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope      IN NUMBER,
        i_flg_scope  IN VARCHAR2,
        i_start_date IN VARCHAR2,
        i_end_date   IN VARCHAR2,
        i_cancelled  IN VARCHAR2,
        i_crit_type  IN VARCHAR2,
        i_flg_report IN VARCHAR2,
        i_flg_status IN table_varchar DEFAULT NULL,
        o_pos        OUT pk_types.cursor_type,
        o_pos_exec   OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
    
        IF NOT pk_inp_positioning.get_positioning_rep(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_scope      => i_scope,
                                                      i_flg_scope  => i_flg_scope,
                                                      i_start_date => i_start_date,
                                                      i_end_date   => i_end_date,
                                                      i_cancelled  => i_cancelled,
                                                      i_crit_type  => i_crit_type,
                                                      i_flg_report => i_flg_report,
                                                      i_flg_status => i_flg_status,
                                                      o_pos        => o_pos,
                                                      o_pos_exec   => o_pos_exec,
                                                      o_error      => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              '',
                                              c_package_owner,
                                              c_package_name,
                                              'get_positioning_rep',
                                              o_error);
        
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_positioning_rep;

    FUNCTION get_hhc_req_det
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_request IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        i_flg_hist   IN VARCHAR2,
        o_request    OUT pk_types.cursor_type,
        o_status     OUT pk_types.cursor_type,
        o_int_hhc    OUT pk_types.cursor_type,
        o_team       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        k_root_name CONSTANT ds_component.internal_name%TYPE := 'DS_HHC_REQUEST';
        l_exception EXCEPTION;
        l_id_request     epis_hhc_req.id_epis_hhc_req%TYPE;
        l_tbl_id_request table_number;
        l_req_det        t_coll_hhc_req_hist := t_coll_hhc_req_hist();
        l_id_prof_team   prof_team.id_prof_team%TYPE;
        l_team_edit      pk_types.cursor_type;
    BEGIN
    
        IF i_flg_hist = pk_alert_constant.g_no
        THEN
            IF i_id_request IS NULL
            THEN
                l_id_request := pk_hhc_core.get_last_id_hhc_request(i_lang       => i_lang,
                                                                    i_prof       => i_prof,
                                                                    i_id_patient => i_id_patient,
                                                                    o_error      => o_error);
            ELSE
                l_id_request := i_id_request;
            END IF;
        
            IF l_id_request IS NOT NULL
            THEN
                IF NOT pk_hhc_core.get_hhc_req_det(i_lang       => i_lang,
                                                   i_prof       => i_prof,
                                                   i_root_name  => k_root_name,
                                                   i_id_request => l_id_request,
                                                   i_flg_report => pk_alert_constant.g_yes,
                                                   o_detail     => o_request,
                                                   o_error      => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
                --intensity home care
                IF NOT pk_prog_notes_in.get_intensity_hhc(i_lang           => i_lang,
                                                          i_prof           => i_prof,
                                                          i_id_patient     => i_id_patient,
                                                          i_tbl_id_request => table_number(l_id_request),
                                                          i_flg_report     => pk_alert_constant.g_yes,
                                                          o_data           => o_int_hhc,
                                                          o_error          => o_error)
                THEN
                    pk_types.open_my_cursor(o_int_hhc);
                END IF;
            
                --team   
                IF NOT pk_prof_teams.get_prof_team_det_hist(i_lang       => i_lang,
                                                            i_prof       => i_prof,
                                                            i_tbl_id_req => table_number(l_id_request),
                                                            i_flg_report => pk_alert_constant.g_yes,
                                                            o_team_val   => o_team,
                                                            o_error      => o_error)
                THEN
                    pk_types.open_my_cursor(o_team);
                END IF;
            
                --status
                IF NOT pk_hhc_core.get_hhc_req_reason_notes(i_lang           => i_lang,
                                                            i_prof           => i_prof,
                                                            i_tbl_id_hhc_rec => table_number(l_id_request),
                                                            i_flg_report     => pk_alert_constant.g_yes,
                                                            o_status         => o_status,
                                                            o_error          => o_error)
                THEN
                    pk_types.open_my_cursor(o_status);
                END IF;
            
            ELSE
                pk_types.open_my_cursor(o_request);
                pk_types.open_my_cursor(o_status);
                pk_types.open_my_cursor(o_int_hhc);
                pk_types.open_my_cursor(o_team);
            END IF;
        
        ELSE
            --get all hhc request id's
            l_tbl_id_request := pk_hhc_core.get_all_hhc_req_from_pat(i_lang       => i_lang,
                                                                     i_prof       => i_prof,
                                                                     i_id_patient => i_id_patient,
                                                                     o_error      => o_error);
            IF l_tbl_id_request IS NOT empty
            THEN
                IF NOT pk_hhc_core.get_hhc_req_det_hist(i_lang       => i_lang,
                                                        i_prof       => i_prof,
                                                        i_tbl_id_req => l_tbl_id_request,
                                                        i_flg_report => pk_alert_constant.g_yes,
                                                        o_detail     => o_request,
                                                        o_error      => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
                --intensity home care
                IF NOT pk_prog_notes_in.get_intensity_hhc(i_lang           => i_lang,
                                                          i_prof           => i_prof,
                                                          i_id_patient     => i_id_patient,
                                                          i_tbl_id_request => l_tbl_id_request,
                                                          i_flg_report     => pk_alert_constant.g_yes,
                                                          o_data           => o_int_hhc,
                                                          o_error          => o_error)
                THEN
                    pk_types.open_my_cursor(o_int_hhc);
                END IF;
            
                --status
                IF NOT pk_hhc_core.get_hhc_req_reason_notes(i_lang           => i_lang,
                                                            i_prof           => i_prof,
                                                            i_tbl_id_hhc_rec => l_tbl_id_request,
                                                            i_flg_report     => pk_alert_constant.g_yes,
                                                            o_status         => o_status,
                                                            o_error          => o_error)
                THEN
                    pk_types.open_my_cursor(o_status);
                END IF;
            
                IF NOT pk_prof_teams.get_prof_team_det_hist(i_lang       => i_lang,
                                                            i_prof       => i_prof,
                                                            i_tbl_id_req => l_tbl_id_request,
                                                            i_flg_report => pk_alert_constant.g_yes,
                                                            o_team_val   => o_team,
                                                            o_error      => o_error)
                THEN
                    pk_types.open_my_cursor(o_team);
                END IF;
            
            ELSE
                pk_types.open_my_cursor(o_request);
                pk_types.open_my_cursor(o_status);
                pk_types.open_my_cursor(o_int_hhc);
                pk_types.open_my_cursor(o_team);
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              '',
                                              c_package_owner,
                                              c_package_name,
                                              'get_hhc_req_det',
                                              o_error);
            pk_types.open_my_cursor(o_request);
            pk_types.open_my_cursor(o_status);
            pk_types.open_my_cursor(o_int_hhc);
            pk_types.open_my_cursor(o_team);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_hhc_req_det;

    /*******************************************************************************************
    *******************************************************************************************/
    FUNCTION get_hhc_discharge_rep
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_detail          OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        RETURN pk_hhc_discharge.get_report_data(i_lang            => i_lang,
                                                i_prof            => i_prof,
                                                i_id_epis_hhc_req => i_id_epis_hhc_req,
                                                o_detail          => o_detail,
                                                o_error           => o_error);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              '',
                                              c_package_owner,
                                              c_package_name,
                                              'GET_HHC_DISCHARGE_REP',
                                              o_error);
            pk_types.open_my_cursor(o_detail);
            RETURN FALSE;
    END get_hhc_discharge_rep;

    FUNCTION get_sev_scores_values
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        i_mtos_score      IN mtos_score.id_mtos_score%TYPE,
        i_epis_mtos_score IN epis_mtos_score.id_epis_mtos_score%TYPE,
        o_reg             OUT pk_types.cursor_type,
        o_groups          OUT pk_types.cursor_type,
        o_values          OUT pk_types.cursor_type,
        o_cancel          OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_sev_scores_core.get_sev_scores_values(i_lang            => i_lang,
                                                        i_prof            => i_prof,
                                                        i_id_patient      => i_id_patient,
                                                        i_id_episode      => i_id_episode,
                                                        i_mtos_score      => i_mtos_score,
                                                        i_epis_mtos_score => i_epis_mtos_score,
                                                        o_reg             => o_reg,
                                                        o_groups          => o_groups,
                                                        o_values          => o_values,
                                                        o_cancel          => o_cancel,
                                                        o_error           => o_error);
    
    END get_sev_scores_values;

    FUNCTION get_rep_sev_score_detail
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN NUMBER,
        i_id_episode      IN episode.id_episode%TYPE,
        i_epis_mtos_score IN epis_mtos_score.id_epis_mtos_score%TYPE,
        o_reg             OUT pk_types.cursor_type,
        o_value           OUT pk_types.cursor_type,
        o_cancel          OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ret BOOLEAN := TRUE;
    BEGIN
    
        l_ret := pk_sev_scores_core.get_sev_score_detail(i_lang            => i_lang,
                                                         i_prof            => i_prof,
                                                         i_id_episode      => i_id_episode,
                                                         i_epis_mtos_score => i_epis_mtos_score,
                                                         o_reg             => o_reg,
                                                         o_value           => o_value,
                                                         o_cancel          => o_cancel,
                                                         o_error           => o_error);
    
        RETURN l_ret;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => '',
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => 'get_rep_sev_score_detail',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_reg);
            pk_types.open_my_cursor(o_value);
            pk_types.open_my_cursor(o_cancel);
            RETURN FALSE;
    END get_rep_sev_score_detail;

    FUNCTION get_epis_bed_history
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_sql        OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_bed.get_epis_bed_history(i_lang       => i_lang,
                                           i_prof       => i_prof,
                                           i_id_episode => i_id_episode,
                                           o_sql        => o_sql,
                                           o_error      => o_error);
    
    END get_epis_bed_history;

    FUNCTION get_pdms_events
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_flg_scope     IN VARCHAR2,
        i_scope         IN NUMBER,
        i_flg_show_hist IN VARCHAR2,
        o_events        OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        RETURN pk_api_pdms.get_pdms_events(i_lang          => i_lang,
                                           i_prof          => i_prof,
                                           i_flg_scope     => i_flg_scope,
                                           i_scope         => i_scope,
                                           i_flg_report    => pk_alert_constant.g_yes,
                                           i_flg_show_hist => i_flg_show_hist,
                                           o_events        => o_events,
                                           o_error         => o_error);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              NULL,
                                              c_package_owner,
                                              c_package_name,
                                              'GET_PDMS_EVENTS',
                                              o_error);
            pk_types.open_my_cursor(o_events);
            RETURN FALSE;
    END get_pdms_events;

    FUNCTION get_pdms_cases
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_flg_scope     IN VARCHAR2,
        i_scope         IN NUMBER,
        i_flg_show_hist IN VARCHAR2,
        o_events        OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        RETURN pk_api_pdms.get_pdms_cases(i_lang          => i_lang,
                                          i_prof          => i_prof,
                                          i_flg_scope     => i_flg_scope,
                                          i_scope         => i_scope,
                                          i_flg_report    => pk_alert_constant.g_yes,
                                          i_flg_show_hist => i_flg_show_hist,
                                          o_events        => o_events,
                                          o_error         => o_error);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              NULL,
                                              c_package_owner,
                                              c_package_name,
                                              'GET_PDMS_CASES',
                                              o_error);
            pk_types.open_my_cursor(o_events);
            RETURN FALSE;
    END get_pdms_cases;

    /*********************************************************************************************
    *********************************************************************************************/
    FUNCTION get_pnv_flg
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE DEFAULT NULL,
        i_episode        IN episode.id_episode%TYPE DEFAULT NULL,
        o_flg_vaccinated OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        RETURN pk_immunization_core.get_pnv_flg(i_lang           => i_lang,
                                                i_prof           => i_prof,
                                                i_patient        => i_patient,
                                                i_episode        => i_episode,
                                                o_flg_vaccinated => o_flg_vaccinated,
                                                o_error          => o_error);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              NULL,
                                              c_package_owner,
                                              c_package_name,
                                              'GET_PNV_FLG',
                                              o_error);
            RETURN FALSE;
    END get_pnv_flg;
    /********************************************************************************************
    * Invokation of pk_adt.check_sus_health_plan.
    
    * @author                                  Anna Kurowska
    * @version                                 2.8
    * @since                                   2020/Dec/21
    ********************************************************************************************/
    FUNCTION check_sus_health_plan
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_has_sus    OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    BEGIN
        l_message := 'CALL TO FUNCTION INTERNAL CHECK_SUS_HEALTH_PLAN';
        pk_alertlog.log_debug(l_message);
        IF NOT pk_adt.check_sus_health_plan(i_lang       => i_lang,
                                            i_prof       => i_prof,
                                            i_id_patient => i_id_patient,
                                            o_has_sus    => o_has_sus,
                                            o_error      => o_error)
        
        THEN
            RETURN FALSE;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              c_package_owner,
                                              c_package_name,
                                              'CHECK_SUS_HEALTH_PLAN',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END check_sus_health_plan;

    FUNCTION get_institution_img_logo_by_inst
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        i_institution IN institution.id_institution%TYPE,
        o_inst_logo   OUT institution_logo.img_logo%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_dep_clin_serv NUMBER;
        c_function_name CONSTANT obj_name := 'GET_INSTITUTION_IMG_LOGO';
        l_message     debug_msg;
        l_institution institution.id_institution%TYPE;
    
    BEGIN
    
        l_message := 'GET ID_DEP_CLIN_SERV FOR EPISODE';
        pk_alertlog.log_debug(l_message);
    
        BEGIN
            IF i_episode IS NOT NULL
            THEN
                SELECT ei.id_dep_clin_serv
                  INTO l_id_dep_clin_serv
                  FROM epis_info ei
                 WHERE ei.id_episode = i_episode;
            
            END IF;
        
        EXCEPTION
            WHEN no_data_found THEN
                l_id_dep_clin_serv := NULL;
            
        END;
    
        IF i_institution IS NOT NULL
        THEN
            l_institution := i_institution;
        ELSE
            l_institution := i_prof.institution;
        END IF;
    
        BEGIN
            SELECT il.img_logo
              INTO o_inst_logo
              FROM institution i
              JOIN institution_logo il
                ON i.id_institution = il.id_institution
             WHERE i.id_institution = l_institution --i_prof.institution
               AND (il.id_dep_clin_serv = l_id_dep_clin_serv OR il.id_dep_clin_serv IS NULL)
               AND rownum = 1
             ORDER BY il.id_dep_clin_serv ASC;
        
        EXCEPTION
            WHEN no_data_found THEN
                o_inst_logo := NULL;
            
        END;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_message,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_institution_img_logo_by_inst;

    -- CMF
    /********************************************************************************************
    * This function returns the software of one episode
    *
    * @param i_lang                language
    * @param i_prof                profissional
    * @param i_id_episode          episode id
    * @param o_id_software         episode software
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      Luis Gaspar
    * @version                     1.0
    * @since                       2007/02/23
    **********************************************************************************************/
    FUNCTION get_episode_software
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        o_id_software OUT software.id_software%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_episode.get_episode_software(i_lang        => i_lang,
                                               i_prof        => i_prof,
                                               i_id_episode  => i_id_episode,
                                               o_id_software => o_id_software,
                                               o_error       => o_error);
    
    END get_episode_software;

    FUNCTION get_episode_software
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN software.id_software%TYPE IS
    BEGIN
    
        RETURN pk_episode.get_episode_software(i_lang => i_lang, i_prof => i_prof, i_id_episode => i_id_episode);
    
    END get_episode_software;

    /**
    * Returns the visit ID associated to an episode.
    * This function can be invoked by Flash
    *
    * @param i_lang         Language ID
    * @param i_prof         Current profissional
    * @param i_episode      Episode ID
    *
    * @param o_error        Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.1
    * @since   07-Apr-10
    */
    FUNCTION get_id_visit
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_visit   OUT visit.id_visit%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_episode.get_id_visit(i_lang    => i_lang,
                                       i_prof    => i_prof,
                                       i_episode => i_episode,
                                       o_visit   => o_visit,
                                       o_error   => o_error);
    
    END get_id_visit;

    FUNCTION get_id_visit(i_episode IN episode.id_episode%TYPE) RETURN episode.id_visit%TYPE IS
    BEGIN
    
        RETURN pk_episode.get_id_visit(i_episode => i_episode);
    
    END get_id_visit;

    /********************************************************************************************
    * Return EPIS_TYPE
    *
    * @param i_lang              language id
    * @param i_id_epis           episode id
    * @param o_epis_type         episode type
    
    * @param o_error             Error message
    
    * @return                    true or false on success or error
    *
    * @author                    Rui Spratley
    * @version                   2.4.2
    * @since                     2008/02/07
    
    * @notes                     This function should not be used by the flash layer
    ********************************************************************************************/
    FUNCTION get_epis_type
    (
        i_lang      IN language.id_language%TYPE,
        i_id_epis   IN social_episode.id_social_episode%TYPE,
        o_epis_type OUT episode.id_epis_type%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_episode.get_epis_type(i_lang      => i_lang,
                                        i_id_epis   => i_id_epis,
                                        o_epis_type => o_epis_type,
                                        o_error     => o_error);
    
    END get_epis_type;

    FUNCTION get_epis_type
    (
        i_lang    IN language.id_language%TYPE,
        i_id_epis IN social_episode.id_social_episode%TYPE
    ) RETURN NUMBER IS
    BEGIN
    
        RETURN pk_episode.get_epis_type(i_lang => i_lang, i_id_epis => i_id_epis);
    
    END get_epis_type;

    /**
    * Gets intake time info
    *
    * @param   i_lang                   Professional preferred language
    * @param   i_prof                   Professional identification and its context (institution and software)
    * @param   i_episode                Episode id
    * @param   o_intake_time_register   Intake time registered info
    *
    * @param   o_error                  Error information
    *
    * @return  Returns TRUE if success, otherwise returns FALSE
    *
    * @author  ALEXANDRE.SANTOS
    * @version 2.6.0.5
    * @since   25-01-2011
    */
    FUNCTION get_intake_time
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN epis_intake_time.id_episode%TYPE,
        o_intake_time_register OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_episode.get_intake_time(i_lang                 => i_lang,
                                          i_prof                 => i_prof,
                                          i_episode              => i_episode,
                                          o_intake_time_register => o_intake_time_register,
                                          o_error                => o_error);
    
    END get_intake_time;

    -------
    FUNCTION get_epis_institution_id
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN NUMBER IS
    BEGIN
    
        RETURN pk_episode.get_epis_institution_id(i_lang => i_lang, i_prof => i_prof, i_id_episode => i_id_episode);
    
    END get_epis_institution_id;

    FUNCTION get_soft_by_epis_type
    (
        i_epis_type   IN epis_type_soft_inst.id_epis_type%TYPE,
        i_institution IN epis_type_soft_inst.id_institution%TYPE
    ) RETURN NUMBER IS
    BEGIN
    
        RETURN pk_episode.get_soft_by_epis_type(i_epis_type => i_epis_type, i_institution => i_institution);
    
    END get_soft_by_epis_type;

    --***************************************
    FUNCTION get_epis_ext_sys
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_ext_sys     IN external_sys.id_external_sys%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_institution IN institution.id_institution%TYPE
    ) RETURN VARCHAR2 IS
    BEGIN
    
        RETURN pk_episode.get_epis_ext_sys(i_lang        => i_lang,
                                           i_prof        => i_prof,
                                           i_ext_sys     => i_ext_sys,
                                           i_episode     => i_episode,
                                           i_institution => i_institution);
    
    END get_epis_ext_sys;

    FUNCTION get_id_patient(i_episode IN episode.id_episode%TYPE) RETURN NUMBER IS
    BEGIN
    
        RETURN pk_episode.get_id_patient(i_episode => i_episode);
    
    END get_id_patient;

    FUNCTION get_epis_department
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN dep_clin_serv.id_department%TYPE IS
    BEGIN
    
        RETURN pk_episode.get_epis_department(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode);
    
    END get_epis_department;

    FUNCTION get_dt_schedule
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_dt_target_tstz schedule_outp.dt_target_tstz%TYPE;
        l_id_schedule    schedule.id_schedule%TYPE;
    BEGIN
    
        SELECT id_schedule
          INTO l_id_schedule
          FROM epis_info
         WHERE id_episode = i_id_episode;
        IF l_id_schedule IS NOT NULL
           AND l_id_schedule <> -1
        THEN
            BEGIN
                SELECT so.dt_target_tstz
                  INTO l_dt_target_tstz
                  FROM schedule_outp so
                 WHERE so.id_schedule = l_id_schedule;
            EXCEPTION
                WHEN no_data_found THEN
                    SELECT s.dt_begin_tstz
                      INTO l_dt_target_tstz
                      FROM schedule s
                     WHERE s.id_schedule = l_id_schedule;
            END;
        ELSE
            SELECT dt_begin_tstz
              INTO l_dt_target_tstz
              FROM episode
             WHERE id_episode = i_id_episode;
        END IF;
    
        RETURN pk_date_utils.date_char_tsz(i_lang, l_dt_target_tstz, i_prof.institution, i_prof.software);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_dt_schedule;

    FUNCTION get_admission_discharge
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        o_episode_info OUT pk_types.cursor_type,
        o_diag         OUT pk_types.cursor_type,
        o_surgical     OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_inp_episode.get_admission_discharge(i_lang         => i_lang,
                                                      i_prof         => i_prof,
                                                      i_episode      => i_episode,
                                                      o_episode_info => o_episode_info,
                                                      o_diag         => o_diag,
                                                      o_surgical     => o_surgical,
                                                      o_error        => o_error);
    END get_admission_discharge;

-- INITIALIZATION SECTION
-- 

BEGIN
    -- Initializes log context
    pk_alertlog.log_init(object_name => c_package_name);

END pk_reports_api;
/
