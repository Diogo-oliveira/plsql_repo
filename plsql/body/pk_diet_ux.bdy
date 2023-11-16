/*-- Last Change Revision: $Rev: 2026966 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:35 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE BODY pk_diet_ux IS

    -- Private type declarations
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);
    g_exception EXCEPTION;

    /********************************************************************************************
    * Retrieves the list of Categories/Intervention plans parametrized as 'searchable'.
    * This function is prepared to return categories or plans hierarchy, where either 
    * categories or plans can have an undetermined number of levels.
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_interv_plan_cat       ID intervention plan category. Can be null, if no 
    *                                 category is selected. 
    * @ param i_interv_plan           ID intervention plan. Can be null, if no 
    *                                 intervention plan is selected. 
    * @ param i_inter_type            Intervention plna type
    * @ param o_interv_plan_info      List of categories/intervention plans             
    * @ param o_header_label          Label for the screen header
    *
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/25
    **********************************************************************************************/
    FUNCTION get_interv_plan_list
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_plan_cat  IN interv_plan_category.id_interv_plan_category%TYPE,
        i_interv_plan      IN interv_plan.id_interv_plan%TYPE,
        o_interv_plan_info OUT pk_types.cursor_type,
        o_header_label     OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET_INTERV_PLAN_LIST';
        IF NOT pk_paramedical_prof_core.get_interv_plan_list(i_lang             => i_lang,
                                                             i_prof             => i_prof,
                                                             i_interv_plan_cat  => i_interv_plan_cat,
                                                             i_interv_plan      => i_interv_plan,
                                                             i_inter_type       => 1,
                                                             o_interv_plan_info => o_interv_plan_info,
                                                             o_header_label     => o_header_label,
                                                             o_error            => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_interv_plan_info);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     o_error.ora_sqlcode,
                                                     o_error.ora_sqlerrm,
                                                     o_error.err_desc,
                                                     g_owner,
                                                     g_package,
                                                     'GET_INTERV_PLAN_LIST',
                                                     o_error);
    END get_interv_plan_list;

    /********************************************************************************************
    * Retrieves the list of Categories/Intervention plans parametrized as 'more frequents'.
    * This function is prepared to return categories or plans hierarchy, where either 
    * categories or plans can have an undetermined number of levels.
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_interv_plan_cat       ID intervention plan category. Can be null, if no 
    *                                 category is selected. 
    * @ param i_interv_plan           ID intervention plan. Can be null, if no 
    *                                 intervention plan is selected. 
    * @ param i_inter_type            Intervention plna type
    * @ param o_interv_plan_info      List of categories/intervention plans             
    * @ param o_header_label          Label for the screen header
    *
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/25
    **********************************************************************************************/
    FUNCTION get_interv_plan_freq_list
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_plan_cat  IN interv_plan_category.id_interv_plan_category%TYPE,
        i_interv_plan      IN interv_plan.id_interv_plan%TYPE,
        o_interv_plan_info OUT pk_types.cursor_type,
        o_header_label     OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET_INTERV_PLAN_FREQ_LIST';
        IF NOT pk_paramedical_prof_core.get_interv_plan_freq_list(i_lang             => i_lang,
                                                                  i_prof             => i_prof,
                                                                  i_interv_plan_cat  => i_interv_plan_cat,
                                                                  i_interv_plan      => i_interv_plan,
                                                                  i_inter_type       => 2,
                                                                  o_interv_plan_info => o_interv_plan_info,
                                                                  o_header_label     => o_header_label,
                                                                  o_error            => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_interv_plan_info);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     o_error.ora_sqlcode,
                                                     o_error.ora_sqlerrm,
                                                     o_error.err_desc,
                                                     g_owner,
                                                     g_package,
                                                     'GET_INTERV_PLAN_FREQ_LIST',
                                                     o_error);
    END get_interv_plan_freq_list;

    /********************************************************************************************
    * Get the list of intervention plans for a given episode
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               Episode ID (Epis type = Social Worker)
    * @ param o_interv_plan           Intervention plan list
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/24
    **********************************************************************************************/
    FUNCTION get_interv_plan
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_epis       IN episode.id_episode%TYPE,
        o_interv_plan   OUT pk_types.cursor_type,
        o_screen_labels OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET_INTERV_PLAN';
        IF NOT pk_paramedical_prof_core.get_interv_plan(i_lang          => i_lang,
                                                        i_prof          => i_prof,
                                                        i_id_epis       => i_id_epis,
                                                        o_interv_plan   => o_interv_plan,
                                                        o_screen_labels => o_screen_labels,
                                                        o_error         => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_interv_plan);
            pk_types.open_my_cursor(o_screen_labels);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     o_error.ora_sqlcode,
                                                     o_error.ora_sqlerrm,
                                                     o_error.err_desc,
                                                     g_owner,
                                                     g_package,
                                                     'GET_INTERV_PLAN',
                                                     o_error);
    END get_interv_plan;

    /********************************************************************************************
    * Get the list of intervention plans for a patient
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_patient               Patient ID 
    * @ param o_interv_plan           Intervention plan list
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Jorge Silva
    * @version                         0.1
    * @since                           2014/01/20
    **********************************************************************************************/
    FUNCTION get_interv_ehr_plan
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_patient    IN patient.id_patient%TYPE,
        o_interv_plan   OUT pk_types.cursor_type,
        o_screen_labels OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET_INTERV_EHR_PLAN';
        IF NOT pk_paramedical_prof_core.get_interv_ehr_plan(i_lang          => i_lang,
                                                            i_prof          => i_prof,
                                                            i_id_patient    => i_id_patient,
                                                            o_interv_plan   => o_interv_plan,
                                                            o_screen_labels => o_screen_labels,
                                                            o_error         => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_interv_plan);
            pk_types.open_my_cursor(o_screen_labels);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     o_error.ora_sqlcode,
                                                     o_error.ora_sqlerrm,
                                                     o_error.err_desc,
                                                     g_owner,
                                                     g_package,
                                                     'GET_INTERV_EHR_PLAN',
                                                     o_error);
    END get_interv_ehr_plan;

    /********************************************************************************************
    * Set one or more intervention plans for a given episode. This function can be used either to 
    * create new intervention plans or to edit existing ones. When editing intervention plans
    * the parameter i_id_epis_interv_plan must be not null.
    *
    * @param i_lang                   Preferred language ID for this professional    
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               Episode ID (Epis type = Social worker)
    * @ param i_id_epis_interv_plan   List of IDs for the existing intervention plans to edit
    * @ param i_id_interv_plan        List of IDs for the intervention plans
    * @ param i_desc_other_interv_plan List of description of free text intervention plans
    * @ param i_dt_begin               List of begin dates for the intervention plans
    * @ param i_dt_end                 List of end dates for the intervention plans
    * @ param i_interv_plan_state      List of current states for the intervention plans
    * @ param i_notes                  List of notes for the intervention plans
    * @ param i_id_task_goal_det       List of task/goal detail identifier         
    * @ param i_id_task_goal           List of coded task/goal identifier   
    * @ param i_desc_task_goal         List of description of tasks/goals
    *
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/24
    **********************************************************************************************/
    FUNCTION set_interv_plan
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_epis IN episode.id_episode%TYPE,
        --
        i_id_epis_interv_plan IN table_number,
        i_id_interv_plan      IN table_number,
        --
        i_desc_other_interv_plan IN table_varchar,
        i_dt_begin               IN table_varchar,
        i_dt_end                 IN table_varchar,
        i_interv_plan_state      IN table_varchar,
        i_notes                  IN table_varchar,
        i_id_task_goal_det       IN table_number,
        i_id_task_goal           IN table_number,
        i_desc_task_goal         IN table_varchar,
        --
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'SET_INTERV_PLAN';
        IF NOT pk_paramedical_prof_core.set_interv_plan(i_lang                   => i_lang,
                                                        i_prof                   => i_prof,
                                                        i_id_epis                => i_id_epis,
                                                        i_id_epis_interv_plan    => i_id_epis_interv_plan,
                                                        i_id_interv_plan         => i_id_interv_plan,
                                                        i_desc_other_interv_plan => i_desc_other_interv_plan,
                                                        i_dt_begin               => i_dt_begin,
                                                        i_dt_end                 => i_dt_end,
                                                        i_interv_plan_state      => i_interv_plan_state,
                                                        i_notes                  => i_notes,
                                                        i_id_task_goal_det       => i_id_task_goal_det,
                                                        i_id_task_goal           => i_id_task_goal,
                                                        i_desc_task_goal         => i_desc_task_goal,
                                                        i_tb_tb_diag             => table_table_number(),
                                                        i_tb_tb_desc_diag        => table_table_varchar(),
                                                        o_error                  => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     o_error.ora_sqlcode,
                                                     o_error.ora_sqlerrm,
                                                     o_error.err_desc,
                                                     g_owner,
                                                     g_package,
                                                     'SET_INTERV_PLAN',
                                                     o_error);
    END set_interv_plan;

    /********************************************************************************************
    * Get domains values for the intervention plan states. 
    * If the parameter i_current_state is null then all available states will be returned, 
    * otherwise the function returns only the states that are different form the current one.
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_current_state          Current state
    *
    * @ param o_interv_plan_state     List with available states
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.1
    * @since                           2010/02/25
    **********************************************************************************************/
    FUNCTION get_interv_plan_state_domains
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_current_state     IN VARCHAR2,
        o_interv_plan_state OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET_INTERV_PLAN_STATE_DOMAINS';
        IF NOT pk_paramedical_prof_core.get_interv_plan_state_domains(i_lang              => i_lang,
                                                                      i_prof              => i_prof,
                                                                      i_current_state     => i_current_state,
                                                                      o_interv_plan_state => o_interv_plan_state,
                                                                      o_error             => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     o_error.ora_sqlcode,
                                                     o_error.ora_sqlerrm,
                                                     o_error.err_desc,
                                                     g_owner,
                                                     g_package,
                                                     'GET_INTERV_PLAN_STATE_DOMAINS',
                                                     o_error);
    END get_interv_plan_state_domains;

    /********************************************************************************************
    * Get data for the popup screen that allows the professionals to edit a 
    * given list of interventions plans
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               Episode ID (Epis type = Social Worker)
    * @ param i_id_epis_interv_plan   List of intervention plans to edit
    * @ param o_interv_plan           Intervention plan list
    * @ param o_screen_labels         Screen label
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.1
    * @since                           2010/02/24
    **********************************************************************************************/
    FUNCTION get_interv_plan_edit_popup
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis             IN episode.id_episode%TYPE,
        i_id_epis_interv_plan IN table_number,
        --
        o_interv_plan   OUT pk_types.cursor_type,
        o_screen_labels OUT pk_types.cursor_type,
        --
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET_INTERV_PLAN_EDIT_POPUP';
        IF NOT pk_paramedical_prof_core.get_interv_plan_edit_popup(i_lang                => i_lang,
                                                                   i_prof                => i_prof,
                                                                   i_id_epis             => i_id_epis,
                                                                   i_id_epis_interv_plan => i_id_epis_interv_plan,
                                                                   o_interv_plan         => o_interv_plan,
                                                                   o_screen_labels       => o_screen_labels,
                                                                   o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     o_error.ora_sqlcode,
                                                     o_error.ora_sqlerrm,
                                                     o_error.err_desc,
                                                     g_owner,
                                                     g_package,
                                                     'GET_INTERV_PLAN_EDIT_POPUP',
                                                     o_error);
    END get_interv_plan_edit_popup;

    /********************************************************************************************
    * Get data for the popup screen that allows the professionals to edit a 
    * given list of interventions plans that are not yet set for the patient
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               Episode ID (Epis type = Social Worker)
    * @ param i_dt_begin              List of begin dates for the select intervention plans to edit
    * @ param i_dt_end                List of end dates for the select intervention plans to edit
    * @ param i_dt_begin              List of states for the select intervention plans to edit
    * @ param o_interv_plan           Intervention plan list
    * @ param o_screen_labels         Screen label
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/24
    **********************************************************************************************/
    FUNCTION get_interv_plan_edit_popup
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_epis        IN episode.id_episode%TYPE,
        i_id_interv_plan IN table_number,
        i_dt_begin       IN table_varchar,
        i_dt_end         IN table_varchar,
        i_state          IN table_varchar,
        i_notes          IN table_varchar,
        i_task_goal_det  IN table_number,
        i_task_goal      IN table_number,
        --
        o_interv_plan   OUT pk_types.cursor_type,
        o_screen_labels OUT pk_types.cursor_type,
        --
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'CALL pk_paramedical_prof_core.get_interv_plan_edit_popup';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_paramedical_prof_core.get_interv_plan_edit_popup(i_lang           => i_lang,
                                                                   i_prof           => i_prof,
                                                                   i_id_epis        => i_id_epis,
                                                                   i_id_interv_plan => i_id_interv_plan,
                                                                   i_dt_begin       => i_dt_begin,
                                                                   i_dt_end         => i_dt_end,
                                                                   i_state          => i_state,
                                                                   i_notes          => i_notes,
                                                                   i_task_goal_det  => i_task_goal_det,
                                                                   i_task_goal      => i_task_goal,
                                                                   o_interv_plan    => o_interv_plan,
                                                                   o_screen_labels  => o_screen_labels,
                                                                   o_error          => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_interv_plan);
            pk_types.open_my_cursor(o_screen_labels);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     o_error.ora_sqlcode,
                                                     o_error.ora_sqlerrm,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_INTERV_PLAN_EDIT_POPUP',
                                                     o_error);
        
    END get_interv_plan_edit_popup;

    /********************************************************************************************
    * Get labels and domains for the edit screen
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               Episode ID (Epis type = Social Worker)
    
    * @ param o_interv_plan           State domains
    * @ param o_screen_labels         Screen label
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.1
    * @since                           2010/02/24
    **********************************************************************************************/
    FUNCTION get_interv_plan_edit
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_epis IN episode.id_episode%TYPE,
        --
        o_state_domains OUT pk_types.cursor_type,
        o_screen_labels OUT pk_types.cursor_type,
        --
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET_INTERV_PLAN_EDIT';
        IF NOT pk_paramedical_prof_core.get_interv_plan_edit(i_lang          => i_lang,
                                                             i_prof          => i_prof,
                                                             i_id_epis       => i_id_epis,
                                                             o_state_domains => o_state_domains,
                                                             o_screen_labels => o_screen_labels,
                                                             o_error         => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     o_error.ora_sqlcode,
                                                     o_error.ora_sqlerrm,
                                                     o_error.err_desc,
                                                     g_owner,
                                                     g_package,
                                                     'GET_INTERV_PLAN_EDIT',
                                                     o_error);
    END get_interv_plan_edit;

    /********************************************************************************************
    * Get the history of a given intervention plan
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               Episode ID (Epis type = Social Worker)
    * @ param i_epis_interv_plan      
    * @ param o_interv_plan           Cursor intervention plan history
    * @ param o_interv_plan_prof      Cursor with prof history information for the 
    *                                 given Intervention plan
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.1
    * @since                           2010/02/24
    **********************************************************************************************/
    FUNCTION get_interv_plan_hist
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis             IN episode.id_episode%TYPE,
        i_id_epis_interv_plan IN epis_interv_plan.id_epis_interv_plan%TYPE,
        --
        o_interv_plan      OUT pk_types.cursor_type,
        o_interv_plan_prof OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET_INTERV_PLAN_HIST';
        IF NOT pk_paramedical_prof_core.get_interv_plan_hist(i_lang                => i_lang,
                                                             i_prof                => i_prof,
                                                             i_id_epis             => i_id_epis,
                                                             i_id_epis_interv_plan => i_id_epis_interv_plan,
                                                             o_interv_plan         => o_interv_plan,
                                                             o_interv_plan_prof    => o_interv_plan_prof,
                                                             o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     o_error.ora_sqlcode,
                                                     o_error.ora_sqlerrm,
                                                     o_error.err_desc,
                                                     g_owner,
                                                     g_package,
                                                     'GET_INTERV_PLAN_HIST',
                                                     o_error);
    END get_interv_plan_hist;

    /********************************************************************************************
    * Set(change) a new intervention plan state 
    *
    * @param i_lang                   Preferred language ID for this professional    
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               Episode ID (Epis type = Social worker)
    * @ param i_id_epis_interv_plan   Intervention plan ID
    * @ param i_new_interv_plan_state New state for the existing plan
    *
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.1
    * @since                           2010/02/24
    **********************************************************************************************/
    FUNCTION set_new_interv_plan_state
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_epis               IN episode.id_episode%TYPE,
        i_id_epis_interv_plan   IN table_number,
        i_new_interv_plan_state IN epis_interv_plan.flg_status%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'SET_NEW_INTERV_PLAN_STATE';
        IF NOT pk_paramedical_prof_core.set_new_interv_plan_state(i_lang                  => i_lang,
                                                                  i_prof                  => i_prof,
                                                                  i_id_epis               => i_id_epis,
                                                                  i_id_epis_interv_plan   => i_id_epis_interv_plan,
                                                                  i_new_interv_plan_state => i_new_interv_plan_state,
                                                                  o_error                 => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     o_error.ora_sqlcode,
                                                     o_error.ora_sqlerrm,
                                                     o_error.err_desc,
                                                     g_owner,
                                                     g_package,
                                                     'SET_NEW_INTERV_PLAN_STATE',
                                                     o_error);
    END set_new_interv_plan_state;

    /********************************************************************************************
    * Cancel Intervention plans.
    *
    * @param i_lang                    Preferred language ID for this professional
    * @param i_prof                    Object (professional ID, institution ID, software ID)
    * @param i_id_epis                 Episode ID
    * @ param i_id_epis_interv_plan     Intervention plan ID
    * @ param i_notes                   Cancel notes
    * @ param i_cancel_reason           Cancel reason
    *
    * @ param o_error                   Error message
    *
    * @return                          true or false on success or error
    *
    * @author                           Orlando Antunes
    * @version                          2.6.0.1
    * @since                            2010/02/25
    **********************************************************************************************/
    FUNCTION set_cancel_interv_plan
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis             IN episode.id_episode%TYPE,
        i_id_epis_interv_plan IN table_number,
        i_notes               IN cancel_info_det.notes_cancel_short%TYPE,
        i_cancel_reason       IN cancel_reason.id_cancel_reason%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'set_cancel_interv_plan';
        IF NOT pk_paramedical_prof_core.set_cancel_interv_plan(i_lang                => i_lang,
                                                               i_prof                => i_prof,
                                                               i_id_epis             => i_id_epis,
                                                               i_id_epis_interv_plan => i_id_epis_interv_plan,
                                                               i_notes               => i_notes,
                                                               i_cancel_reason       => i_cancel_reason,
                                                               o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     o_error.ora_sqlcode,
                                                     o_error.ora_sqlerrm,
                                                     o_error.err_desc,
                                                     g_owner,
                                                     g_package,
                                                     'SET_CANCEL_INTERV_PLAN',
                                                     o_error);
    END set_cancel_interv_plan;

    /********************************************************************************************
    * Get Intervention plans available actiosn 
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_current_state          Current state     
    * @param o_interv_plan_actions    List of actions 
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.1
    * @since                           2010/02/25
    **********************************************************************************************/
    FUNCTION get_interv_plan_actions
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_current_state       IN table_varchar,
        o_interv_plan_actions OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET_INTERV_PLAN_ACTIONS';
        IF NOT pk_paramedical_prof_core.get_interv_plan_actions(i_lang                => i_lang,
                                                                i_prof                => i_prof,
                                                                i_current_state       => i_current_state,
                                                                o_interv_plan_actions => o_interv_plan_actions,
                                                                o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     o_error.ora_sqlcode,
                                                     o_error.ora_sqlerrm,
                                                     o_error.err_desc,
                                                     g_owner,
                                                     g_package,
                                                     'GET_INTERV_PLAN_ACTIONS',
                                                     o_error);
    END get_interv_plan_actions;

    /********************************************************************************************
    * Get data for the dietitian requests grids.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_show_all       'Y' to show all requests,
    *                         'N' to show a specific SW requests.
    * @param o_requests       requests cursor
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Elisabete Bugalho
    * @version                2.6.0.1
    * @since                  07-04-2010
    */
    FUNCTION get_paramedical_requests
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_show_all IN VARCHAR2,
        o_requests OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_paramedical_prof_core.get_paramedical_requests';
        IF NOT pk_paramedical_prof_core.get_paramedical_requests(i_lang     => i_lang,
                                                                 i_prof     => i_prof,
                                                                 i_show_all => i_show_all,
                                                                 o_requests => o_requests,
                                                                 o_error    => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_PARAMEDICAL_REQUESTS',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_requests);
            RETURN FALSE;
        
    END get_paramedical_requests;

    /********************************************************************************************
    * Get patient's Dietitian Summary. This includes information of:
    *    - Diagnosis
    *    - Intervention plan
    *    - Follow up notes
    *    - Diets
    *    - Evaluation tools
    *    - Dietitian report
    *    - Dietitian requests
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_pat                 Patient ID
    * @param i_episode                ID Episode
    * 
    * @ param o_diagnosis             Patient's diagnosis list
    * @ param o_diagnosis_prof        Professional that creates/edit the diagnosis
    * @ param o_interv_plan           Patient's intevention plan list
    * @ param o_interv_plan_prof      Professional that creates/edit the intervention plan
    * @ param o_follow_up             Follow up notes for the current episode
    * @ param o_follow_up_prof        Professional that creates the follow up notes
    * @ param o_diet                  Patient diets
    * @ param o_diet_prof             Professional that prescribes the diets
    * @ param o_evaluation_tools      List of evaluation tools
    * @ param o_evaluation_tools_prof Professional that creates the evaluation
    * @ param o_dietitian_report      Dietitian report
    * @ param o_dietitian_report_prof Professional that creates/edit the dietitian report
    * @ param o_dietitian_request     Dietitian request
    * @ param o_dietitian_request_prof Professional that creates/edit the dietitian request
    * @ param o_request_origin        Y/N  - Indicates if the episode started with a request 
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/01/21
    **********************************************************************************************/
    FUNCTION get_dietitian_summary
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_pat  IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        --request
        o_dietitian_request      OUT pk_types.cursor_type,
        o_dietitian_request_prof OUT pk_types.cursor_type,
        --
        o_request_origin OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        --
        IF NOT pk_diet.get_dietitian_summary(i_lang                   => i_lang,
                                             i_prof                   => i_prof,
                                             i_id_pat                 => i_id_pat,
                                             i_episode                => i_episode,
                                             o_dietitian_request      => o_dietitian_request,
                                             o_dietitian_request_prof => o_dietitian_request_prof,
                                             o_error                  => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := ('GET_NUTRITIAN_EPISODE_ORIGIN_TYPE');
        IF pk_diet.get_nutritian_epis_origin_type(i_lang, i_prof, i_episode) = 'R'
           OR pk_diet.get_nutritian_epis_origin_type(i_lang, i_prof, i_episode) = 'C'
        THEN
            o_request_origin := pk_alert_constant.g_yes;
        ELSE
            o_request_origin := pk_alert_constant.g_no;
        END IF;
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            --
            pk_types.open_my_cursor(o_dietitian_request);
            pk_types.open_my_cursor(o_dietitian_request_prof);
        
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     o_error.ora_sqlcode,
                                                     o_error.ora_sqlerrm,
                                                     o_error.err_desc,
                                                     g_owner,
                                                     g_package,
                                                     'GET_DIETITIAN_SUMMARY',
                                                     o_error);
        
    END get_dietitian_summary;

    /********************************************************************************************
    * Get patient's EHR Dietitian Summary. This includes information of:
    *    - Diagnosis
    *    - Intervention plan
    *    - Follow up notes
    *    - Diets
    *    - Evaluation tools
    *    - Dietitian report
    *    - Dietitian requests
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_pat                 Patient ID
    * @param i_episode                ID Episode
    * 
    * @ param o_screen_labels         Labels
    * @ param o_episodes_det          List of patient's episodes
    * @ param o_diagnosis             Patient's diagnosis list
    * @ param o_interv_plan           Patient's intevention plan list
    * @ param o_follow_up             Follow up notes list
    * @ param o_diet                  Patient diets
    * @ param o_evaluation_tools      List of evaluation tools
    * @ param o_dietitian_report         dietitian report list
    * @ param o_dietitian_request        dietitian requests list
    * @ param o_request_origin        Y/N  - Indicates if the episode started with a request 
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/03/15
    **********************************************************************************************/
    FUNCTION get_dietitian_summary_ehr
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_pat  IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        --labels
        o_screen_labels OUT pk_types.cursor_type,
        --list of episodes
        o_episodes_det OUT pk_types.cursor_type,
        --request
        o_dietitian_request OUT pk_types.cursor_type,
        --
        o_request_origin OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET_SOCIAL_SUMMARY_EHR';
        IF NOT pk_diet.get_dietitian_summary_ehr(i_lang              => i_lang,
                                                 i_prof              => i_prof,
                                                 i_id_pat            => i_id_pat,
                                                 i_episode           => i_episode,
                                                 o_screen_labels     => o_screen_labels,
                                                 o_episodes_det      => o_episodes_det,
                                                 o_dietitian_request => o_dietitian_request,
                                                 o_error             => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := ('GET_NUTRITIAN_EPISODE_ORIGIN_TYPE');
        IF pk_diet.get_nutritian_epis_origin_type(i_lang, i_prof, i_episode) = 'R'
           OR pk_diet.get_nutritian_epis_origin_type(i_lang, i_prof, i_episode) = 'C'
        THEN
            o_request_origin := pk_alert_constant.g_yes;
        ELSE
            o_request_origin := pk_alert_constant.g_no;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_screen_labels);
            pk_types.open_my_cursor(o_episodes_det);
            pk_types.open_my_cursor(o_dietitian_request);
        
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_DIETITIAN_SUMMARY_EHR',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_dietitian_summary_ehr;

    /********************************************************************************************
    * Get all parametrizations for the dietitian software
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_social_parametrizations List with all parametrizations (name/value)
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/19
    **********************************************************************************************/
    FUNCTION get_dietitian_parametrizations
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        o_dietitian_parametrizations OUT pk_types.cursor_type,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_social.get_social_parametrizations';
    
        IF NOT pk_paramedical_prof_core.get_paramedical_param(i_lang              => i_lang,
                                                              i_prof              => i_prof,
                                                              o_paramedical_param => o_dietitian_parametrizations,
                                                              o_error             => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_dietitian_parametrizations);
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_owner,
                                                     i_package  => g_package,
                                                     i_function => 'get_DIETITIAN_parametrizations',
                                                     o_error    => o_error);
    END get_dietitian_parametrizations;

    /********************************************************************************************
    * Get the dietitian summary screen labels
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_dietitian_summary_labels   Social summary screen labels  
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/04/
    **********************************************************************************************/
    FUNCTION get_dietitian_summary_labels
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        o_dietitian_summary_labels OUT pk_types.cursor_type,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        pk_alertlog.log_debug('CALL GET_DIETITIAN_SUMMARY_LABELS');
        IF NOT pk_diet.get_dietitian_summary_labels(i_lang                     => i_lang,
                                                    i_prof                     => i_prof,
                                                    o_dietitian_summary_labels => o_dietitian_summary_labels,
                                                    o_error                    => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        --      
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_dietitian_summary_labels);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_dietitian_summary_labels);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_DIETITIAN_SUMMARY_LABELS',
                                                     o_error);
        
    END get_dietitian_summary_labels;

    /********************************************************************************************
    * Get all parametrizations for the social worker software
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_social_parametrizations List with all parametrizations (name/value)
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/19
    **********************************************************************************************/
    FUNCTION get_parametrizations
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        o_parametrizations OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_configs CONSTANT table_varchar := table_varchar('SUMMARY_VIEW_ALL_DIETITIAN',
                                                          'GRID_NAVIGATION',
                                                          'PARAMEDICAL_REQUESTS_SHOW_PATIENT_AREA');
    BEGIN
        g_error := 'CALL pk_paramedical_prof_core.get_parametrizations';
    
        IF NOT pk_paramedical_prof_core.get_parametrizations(i_lang              => i_lang,
                                                             i_prof              => i_prof,
                                                             i_configs           => l_configs,
                                                             o_paramedical_param => o_parametrizations,
                                                             o_error             => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_parametrizations);
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_owner,
                                                     i_package  => g_package,
                                                     i_function => 'GET_PARAMETRIZATIONS',
                                                     o_error    => o_error);
    END get_parametrizations;

    /********************************************************************************************
    * Get the task/goal for the specific intervention plan
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_interv_plan         Intervention Plan array
    *
    * @param o_task_goal              list of task/goal defined for the specific intervention plan
    * @return                         TRUE/FALSE
    *
    * @author                          João Almeida
    * @version                         0.1
    * @since 
    **********************************************************************************************/
    FUNCTION get_task_goal
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_interv_plan IN table_number,
        o_task_goal      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
        
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'CALL pk_paramedical_prof_core.get_task_goal';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_paramedical_prof_core.get_task_goal(i_lang           => i_lang,
                                                      i_prof           => i_prof,
                                                      i_id_interv_plan => i_id_interv_plan,
                                                      o_task_goal      => o_task_goal,
                                                      o_error          => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_owner,
                                                     i_package  => g_package,
                                                     i_function => 'GET_TASK_GOAL',
                                                     o_error    => o_error);
    END get_task_goal;
    /********************************************************************************************
    * Get an episode's paramedical service reports list. Specify the report
    * identifier to retrieve the history of its changes.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        social episode identifier
    * @param i_report         report identifier
    * @param i_show_cancelled set 'Y' to show cancelled records
    * @param o_report_prof    reports records info 
    * @param o_report         reports
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/04
    */
    FUNCTION get_paramed_report
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN paramed_report.id_episode%TYPE,
        i_report      IN paramed_report.id_paramed_report%TYPE,
        o_report_prof OUT pk_types.cursor_type,
        o_report      OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_paramedical_prof_core.get_paramed_report';
        IF NOT pk_paramedical_prof_core.get_paramed_report(i_lang           => i_lang,
                                                           i_prof           => i_prof,
                                                           i_episode        => table_number(i_episode),
                                                           i_report         => i_report,
                                                           i_show_cancelled => pk_alert_constant.g_yes,
                                                           o_report_prof    => o_report_prof,
                                                           o_report         => o_report,
                                                           o_error          => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_report_prof);
            pk_types.open_my_cursor(o_report);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_PARAMED_REPORT',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_report_prof);
            pk_types.open_my_cursor(o_report);
            RETURN FALSE;
    END get_paramed_report;

    /********************************************************************************************
    * Set paramedical service report.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_report         report identifier
    * @param i_episode        episode identifier
    * @param i_text           report text
    * @param o_report         created report identifier
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/04
    */
    FUNCTION set_paramed_report
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_report  IN paramed_report.id_paramed_report%TYPE,
        i_episode IN paramed_report.id_episode%TYPE,
        i_text    IN paramed_report.text%TYPE,
        o_report  OUT paramed_report.id_paramed_report%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_paramedical_prof_core.set_paramed_report';
        IF NOT pk_paramedical_prof_core.set_paramed_report(i_lang    => i_lang,
                                                           i_prof    => i_prof,
                                                           i_report  => i_report,
                                                           i_episode => i_episode,
                                                           i_text    => i_text,
                                                           o_report  => o_report,
                                                           o_error   => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_PARAMED_REPORT',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_paramed_report;

    /*
    * Get an episode's follow up notes list.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        social episode identifier
    * @param i_mng_followup   follow up notes identifier
    * @param o_follow_up_prof follow up notes records info 
    * @param o_follow_up      follow up notes
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/15
    */
    FUNCTION get_followup_notes
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN management_follow_up.id_episode%TYPE,
        i_mng_followup   IN management_follow_up.id_management_follow_up%TYPE,
        o_follow_up_prof OUT pk_types.cursor_type,
        o_follow_up      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_paramedical_prof_core.get_followup_notes';
        IF NOT pk_paramedical_prof_core.get_followup_notes(i_lang           => i_lang,
                                                           i_prof           => i_prof,
                                                           i_episode        => i_episode,
                                                           i_mng_followup   => i_mng_followup,
                                                           i_show_cancelled => pk_alert_constant.g_yes,
                                                           o_follow_up_prof => o_follow_up_prof,
                                                           o_follow_up      => o_follow_up,
                                                           o_error          => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_follow_up_prof);
            pk_types.open_my_cursor(o_follow_up);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_FOLLOWUP_NOTES',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_follow_up_prof);
            pk_types.open_my_cursor(o_follow_up);
            RETURN FALSE;
    END get_followup_notes;

    /*
    * Set follow up notes.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_mng_followup   follow up notes identifier
    * @param i_episode        episode identifier
    * @param i_notes          follow up notes
    * @param i_start_dt       start date
    * @param i_time_spent     time spent
    * @param i_unit_time      time spent unit measure
    * @param i_next_dt        next date
    * @param i_flg_end_followup flagend of followup  Y/N  
    * @param o_mng_followup   created follow up notes identifier
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/15
    */
    FUNCTION set_followup_notes
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_mng_followup          IN management_follow_up.id_management_follow_up%TYPE,
        i_episode               IN management_follow_up.id_episode%TYPE,
        i_start_dt              IN VARCHAR2,
        i_time_spent            IN management_follow_up.time_spent%TYPE,
        i_unit_time             IN management_follow_up.id_unit_time%TYPE,
        i_next_dt               IN VARCHAR2,
        i_flg_end_followup      IN sys_domain.val%TYPE,
        i_dt_next_enc_precision IN management_follow_up.dt_next_enc_precision%TYPE,
        o_mng_followup          OUT management_follow_up.id_management_follow_up%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_paramedical_prof_core.set_followup_notes';
        IF NOT pk_paramedical_prof_core.set_followup_notes(i_lang                  => i_lang,
                                                           i_prof                  => i_prof,
                                                           i_mng_followup          => i_mng_followup,
                                                           i_episode               => i_episode,
                                                           i_notes                 => '',
                                                           i_start_dt              => i_start_dt,
                                                           i_time_spent            => i_time_spent,
                                                           i_unit_time             => i_unit_time,
                                                           i_next_dt               => i_next_dt,
                                                           i_flg_end_followup      => i_flg_end_followup,
                                                           i_dt_next_enc_precision => i_dt_next_enc_precision,
                                                           o_mng_followup          => o_mng_followup,
                                                           o_error                 => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_EDIT_FOLLOWUP_NOTES',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_followup_notes;

    /*
    * Cancel follow up notes.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_mng_followup   follow up notes identifier
    * @param i_episode        episode identifier
    * @param i_cancel_reason  cancellation reason
    * @param i_notes          cancellation notes
    * @param o_mng_followup   created follow up notes identifier
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/18
    */
    FUNCTION set_cancel_followup_notes
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_mng_followup  IN management_follow_up.id_management_follow_up%TYPE,
        i_episode       IN management_follow_up.id_episode%TYPE,
        i_cancel_reason IN management_follow_up.id_cancel_reason%TYPE,
        i_notes         IN management_follow_up.notes_cancel%TYPE,
        o_mng_followup  OUT management_follow_up.id_management_follow_up%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_case_management.cancel_mng_followup';
        IF NOT pk_case_management.cancel_mng_followup(i_lang              => i_lang,
                                                      i_prof              => i_prof,
                                                      i_mng_plan_followup => i_mng_followup,
                                                      i_episode           => i_episode,
                                                      i_epis_encounter    => NULL,
                                                      i_cancel_reason     => i_cancel_reason,
                                                      i_notes             => i_notes,
                                                      o_mng_plan_followup => o_mng_followup,
                                                      o_error             => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_CANCEL_FOLLOWUP_NOTES',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_cancel_followup_notes;

    /*
    * Get an episode's discharges list. Specify the discharge
    * identifier to retrieve the history of its changes.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    * @param i_discharge      discharge identifier
    * @param o_discharge      discharges
    * @param o_discharge_prof discharges records info
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/05
    */
    FUNCTION get_discharge
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_discharge      IN discharge.id_discharge%TYPE,
        o_discharge      OUT pk_types.cursor_type,
        o_discharge_prof OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_discharge_amb.get_discharge';
        IF NOT pk_discharge_amb.get_discharge(i_lang           => i_lang,
                                              i_prof           => i_prof,
                                              i_episode        => i_episode,
                                              i_discharge      => i_discharge,
                                              i_show_cancelled => pk_alert_constant.g_yes,
                                              o_discharge      => o_discharge,
                                              o_discharge_prof => o_discharge_prof,
                                              o_error          => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_discharge);
            pk_types.open_my_cursor(o_discharge_prof);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_DISCHARGE',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_discharge);
            pk_types.open_my_cursor(o_discharge_prof);
            RETURN FALSE;
    END get_discharge;

    /*
    * Check if the CREATE button must be enabled
    * in the discharge screen.
    *
    * @param i_lang           language identifier
    * @param i_episode        episode identifier
    * @param o_create         'Y' to enable create, 'N' otherwise
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/08
    */
    FUNCTION get_discharge_create
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_create  OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_epis_type episode.id_epis_type%TYPE;
    BEGIN
    
        SELECT e.id_epis_type
          INTO l_epis_type
          FROM episode e
         WHERE e.id_episode = i_episode;
    
        IF (l_epis_type NOT IN
           (pk_alert_constant.g_epis_type_dietitian, pk_alert_constant.g_epis_type_home_health_care))
        THEN
            o_create := pk_alert_constant.g_no;
        ELSE
            g_error := 'CALL pk_discharge_amb.get_discharge_create';
            IF NOT pk_discharge_amb.get_discharge_create(i_lang    => i_lang,
                                                         i_episode => i_episode,
                                                         o_create  => o_create,
                                                         o_error   => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_DISCHARGE_CREATE',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_discharge_create;

    /*
    * Get necessary domains for discharge registration.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param o_destiny        discharge destinies
    * @param o_time_unit      time units
    * @param o_type_closure   type of closure
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/08
    */
    FUNCTION get_discharge_domains
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        o_destiny      OUT pk_types.cursor_type,
        o_time_unit    OUT pk_types.cursor_type,
        o_type_closure OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_discharge_amb.get_domains';
        IF NOT pk_discharge_amb.get_domains(i_lang         => i_lang,
                                            i_prof         => i_prof,
                                            o_destiny      => o_destiny,
                                            o_time_unit    => o_time_unit,
                                            o_type_closure => o_type_closure,
                                            o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_destiny);
            pk_types.open_my_cursor(o_time_unit);
            pk_types.open_my_cursor(o_type_closure);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_DISCHARGE_DOMAINS',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_destiny);
            pk_types.open_my_cursor(o_time_unit);
            pk_types.open_my_cursor(o_type_closure);
            RETURN FALSE;
    END get_discharge_domains;

    /*
    * Set discharge.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_prof_cat       logged professional category
    * @param i_discharge      discharge identifier
    * @param i_episode        episode identifier
    * @param i_dt_end         discharge date
    * @param i_disch_dest     discharge reason destiny identifier
    * @param i_notes          discharge notes_med
    * @param i_print_report   print report?
    * @param o_reports_pat    report to print
    * @param o_flg_show       warm
    * @param o_msg_title      warn
    * @param o_msg_text       warn
    * @param o_button         warn
    * @param o_id_episode     created episode identifier
    * @param o_discharge      created discharge identifier
    * @param o_disch_detail   created discharge_detail identifier
    * @param o_disch_hist     created discharge_hist identifier
    * @param o_disch_det_hist created discharge_detail_hist identifier
    * @param o_error          error message
    *
    * @return                 false if errors occur, true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/08
    */
    FUNCTION set_discharge
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_prof_cat         IN category.flg_type%TYPE,
        i_discharge        IN discharge.id_discharge%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_dt_end           IN VARCHAR2,
        i_disch_dest       IN disch_reas_dest.id_disch_reas_dest%TYPE,
        i_notes            IN discharge.notes_med%TYPE,
        i_time_spent       IN discharge_detail.total_time_spent%TYPE,
        i_unit_measure     IN discharge_detail.id_unit_measure%TYPE,
        i_print_report     IN discharge_detail.flg_print_report%TYPE,
        i_flg_type_closure IN discharge_detail.flg_type_closure%TYPE,
        o_reports_pat      OUT reports.id_reports%TYPE,
        o_flg_show         OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_msg_text         OUT VARCHAR2,
        o_button           OUT VARCHAR2,
        o_id_episode       OUT episode.id_episode%TYPE,
        o_discharge        OUT discharge.id_discharge%TYPE,
        o_disch_detail     OUT discharge_detail.id_discharge_detail%TYPE,
        o_disch_hist       OUT discharge_hist.id_discharge_hist%TYPE,
        o_disch_det_hist   OUT discharge_detail_hist.id_discharge_detail_hist%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_social.set_discharge';
        IF NOT pk_paramedical_prof_core.set_discharge(i_lang             => i_lang,
                                                      i_prof             => i_prof,
                                                      i_prof_cat         => i_prof_cat,
                                                      i_discharge        => i_discharge,
                                                      i_episode          => i_episode,
                                                      i_dt_end           => i_dt_end,
                                                      i_disch_dest       => i_disch_dest,
                                                      i_notes            => i_notes,
                                                      i_time_spent       => i_time_spent,
                                                      i_unit_measure     => i_unit_measure,
                                                      i_print_report     => i_print_report,
                                                      i_flg_type_closure => i_flg_type_closure,
                                                      o_reports_pat      => o_reports_pat,
                                                      o_flg_show         => o_flg_show,
                                                      o_msg_title        => o_msg_title,
                                                      o_msg_text         => o_msg_text,
                                                      o_button           => o_button,
                                                      o_id_episode       => o_id_episode,
                                                      o_discharge        => o_discharge,
                                                      o_disch_detail     => o_disch_detail,
                                                      o_disch_hist       => o_disch_hist,
                                                      o_disch_det_hist   => o_disch_det_hist,
                                                      o_error            => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_DISCHARGE',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_discharge;

    /*
    * Cancels a discharge.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_discharge      discharge identifier
    * @param i_episode        episode identifier
    * @param i_cancel_reason  cancel reason identifier
    * @param i_cancel_notes   cancel notes
    * @param o_disch_hist     created discharge_hist identifier
    * @param o_disch_det_hist created discharge_detail_hist identifier
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/08
    */
    FUNCTION set_discharge_cancel
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_discharge      IN discharge.id_discharge%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_cancel_reason  IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes   IN discharge.notes_cancel%TYPE,
        o_disch_hist     OUT discharge_hist.id_discharge_hist%TYPE,
        o_disch_det_hist OUT discharge_detail_hist.id_discharge_detail_hist%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_social.set_discharge_cancel';
        IF NOT pk_paramedical_prof_core.set_discharge_cancel(i_lang           => i_lang,
                                                             i_prof           => i_prof,
                                                             i_discharge      => i_discharge,
                                                             i_episode        => i_episode,
                                                             i_cancel_reason  => i_cancel_reason,
                                                             i_cancel_notes   => i_cancel_notes,
                                                             o_disch_hist     => o_disch_hist,
                                                             o_disch_det_hist => o_disch_det_hist,
                                                             o_error          => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_DISCHARGE_CANCEL',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_discharge_cancel;

    /*
    * Get discharge data for the create/edit screen.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    * @param i_discharge      discharge identifier
    * @param o_discharge      discharge
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/08
    */
    FUNCTION get_discharge_edit
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        i_discharge IN discharge.id_discharge%TYPE,
        o_discharge OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_discharge_amb.get_discharge_edit';
        IF NOT pk_discharge_amb.get_discharge_edit(i_lang      => i_lang,
                                                   i_prof      => i_prof,
                                                   i_episode   => i_episode,
                                                   i_discharge => i_discharge,
                                                   o_discharge => o_discharge,
                                                   o_error     => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_discharge);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_DISCHARGE_EDIT',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_discharge);
            RETURN FALSE;
    END get_discharge_edit;

    /*
    * Get follow up notes data for the create/edit screen.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    * @param i_mng_followup   follow up notes identifier
    * @param o_follow_up      follow up notes
    * @param o_time_units     time units
    * @param o_domain         option of end of follow up
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/15
    */
    FUNCTION get_followup_notes_edit
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_mng_followup IN management_follow_up.id_management_follow_up%TYPE,
        o_follow_up    OUT pk_types.cursor_type,
        o_time_units   OUT pk_types.cursor_type,
        o_domain       OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_paramedical_prof_core.get_edit_followup_notes';
        IF NOT pk_paramedical_prof_core.get_followup_notes_edit(i_lang         => i_lang,
                                                                i_prof         => i_prof,
                                                                i_episode      => i_episode,
                                                                i_mng_followup => i_mng_followup,
                                                                o_follow_up    => o_follow_up,
                                                                o_time_units   => o_time_units,
                                                                o_domain       => o_domain,
                                                                o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_follow_up);
            pk_types.open_my_cursor(o_time_units);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_FOLLOWUP_NOTES_EDIT',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_follow_up);
            pk_types.open_my_cursor(o_time_units);
            RETURN FALSE;
    END get_followup_notes_edit;

    /********************************************************************************************
    * get all patients button grid data. Uses the same base function as pk_social_ux.
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_software            software id for filtering purpose
    * @param o_data                   output cursor
    * @param o_error                  Error info
    *
    * @return                         true or false on success or error
    *
    * @author                          Telmo
    * @version                         2.6.1.2
    * @since                           19-09-2011
    **********************************************************************************************/
    FUNCTION get_all_patient_grid_data
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_software IN software.id_software%TYPE,
        o_data        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF NOT pk_social.get_all_patient_grid_data(i_lang        => i_lang,
                                                   i_prof        => i_prof,
                                                   i_id_software => i_id_software,
                                                   o_data        => o_data,
                                                   o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_data);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_ALL_PATIENT_GRID_DATA',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_data);
            RETURN FALSE;
    END get_all_patient_grid_data;

    /********************************************************************************************
    * create a follow-up request and sets it as accepted. To be used in the All patient button when
    * the user presses OK in a valid episode (those without follow-up). 
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             episode that will be followed
    * @param i_id_patient             episode patient
    * @param i_id_dcs                 episode's dcs
    * @param i_id_prof                professional that is creating this follow up
    * @param o_id_opinion             resulting follow up request id
    * @param o_id_episode             resulting follow-up episode id 
    * @param o_error                  Error info
    *
    * @return                         true or false on success or error
    *
    * @author                         Telmo
    * @version                        2.6.1.2
    * @since                          21-09-2011
    **********************************************************************************************/
    FUNCTION set_accepted_follow_up
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_dcs     IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_prof    IN opinion.id_prof_questioned%TYPE,
        o_id_opinion OUT opinion.id_opinion%TYPE,
        o_id_episode OUT opinion.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_social.set_accepted_follow_up(i_lang            => i_lang,
                                                i_prof            => i_prof,
                                                i_id_episode      => i_id_episode,
                                                i_id_patient      => i_id_patient,
                                                i_id_dcs          => i_id_dcs,
                                                i_id_prof         => i_id_prof,
                                                i_id_opinion_type => pk_opinion.g_ot_dietitian,
                                                o_id_opinion      => o_id_opinion,
                                                o_id_episode      => o_id_episode,
                                                o_error           => o_error);
    END set_accepted_follow_up;

    /*************************************************
    * Check if button create is active
    *
    * @param i_lang                                  language identifier
    * @param i_prof                                  logged professional structure
    * @param i_episode                               episode idendifier
    *
    * @param 
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Jorge Silva  
    * @version                2.6.3.13
    * @since                  2014/03/18
    ***********************************************/
    FUNCTION get_create_active
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        o_flg_active OUT VARCHAR2
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_paramedical_prof_core.get_create_active(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                          i_episode    => i_episode,
                                                          o_flg_active => o_flg_active);
    
    END get_create_active;

    FUNCTION get_swf_by_epis
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_flg_type      IN category.code_category%TYPE,
        o_swf_file_name OUT swf_file.swf_file_name%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_paramedical_prof_core.get_swf_by_epis(i_lang          => i_lang,
                                                        i_prof          => i_prof,
                                                        i_id_episode    => i_id_episode,
                                                        i_flg_type      => i_flg_type,
                                                        o_swf_file_name => o_swf_file_name,
                                                        o_error         => o_error);
    
    END get_swf_by_epis;

    /*************************************************
    * Checks if the episode has followup requests
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_episode                episode idendifier
    * @param o_followup_access        returns if exists a followup request and his current status
    * @param o_error                  Error info
    *
    * @return                         true or false on success or error
    *
    * @author                 Teresa Coutinho 
    * @version                2.6.4.2.1
    * @since                  2014/10/16
    ***********************************************/
    FUNCTION get_followup_access
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        o_followup_access OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_paramedical_prof_core.get_followup_access(i_lang            => i_lang,
                                                            i_prof            => i_prof,
                                                            i_episode         => i_episode,
                                                            o_followup_access => o_followup_access,
                                                            o_error           => o_error);
    
    END get_followup_access;

    /**********************************************************************************************
    * Cancels a diet 
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    
    * @param i_id_diet               ID Diet to be canceled
    * @param i_notes                 Cancel Notes 
    * @param i_reason                Reason
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/04/08
    **********************************************************************************************/
    FUNCTION cancel_diet
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_diet IN epis_diet_req.id_epis_diet_req%TYPE,
        i_notes   IN epis_diet_req.notes_cancel%TYPE,
        i_reason  IN epis_diet_req.id_cancel_reason%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF NOT pk_diet.cancel_diet(i_lang        => i_lang,
                                   i_prof        => i_prof,
                                   i_id_diet     => i_id_diet,
                                   i_notes       => i_notes,
                                   i_reason      => i_reason,
                                   i_auto_cancel => pk_alert_constant.g_no,
                                   o_error       => o_error)
        THEN
            RAISE g_exception;
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
                                              i_function => 'CANCEL_DIET',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END cancel_diet;

BEGIN
    -- Initialization
    pk_alertlog.who_am_i(g_owner, g_package);
    pk_alertlog.log_init(g_package);

END pk_diet_ux;
/
