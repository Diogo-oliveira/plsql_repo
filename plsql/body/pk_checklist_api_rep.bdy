/*-- Last Change Revision: $Rev: 2026861 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:13 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_checklist_api_rep IS

    -- Private type declarations

    -- Private constant declarations

    -- Private variable declarations

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Function and procedure implementations

    /**
    * Gets a list of all checklists for patient
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_patient      Patient ID 
    * @param   i_episode      Episode ID (if null returns all patient's checklist unfiltered by episode)
    * @param   o_list         Checklist list
    * @param   o_error        Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   08-Jun-10
    */
    FUNCTION get_pat_checklist_list
    (
        i_lang    IN LANGUAGE.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        e_function_call_error EXCEPTION;
        l_ret BOOLEAN;
    BEGIN
    
        g_error := 'Get checklist list for reports';
        alertlog.pk_alertlog.log_debug(text            => g_error,
                                       object_name     => g_package,
                                       sub_object_name => 'get_pat_checklist_list');
    
        l_ret := pk_checklist_core.get_pat_checklist_list(i_lang           => i_lang,
                                                          i_prof           => i_prof,
                                                          i_patient        => i_patient,
                                                          i_episode        => i_episode,
                                                          i_ignore_profile => pk_alert_constant.g_yes,
                                                          o_list           => o_list,
                                                          o_error          => o_error);
        IF l_ret = FALSE
        THEN
            RAISE e_function_call_error;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_function_call_error THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => o_error.ora_sqlcode,
                                              i_sqlerrm  => o_error.ora_sqlerrm,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'get_pat_checklist_list',
                                              o_error    => o_error);
        
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'get_pat_checklist_list',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_pat_checklist_list;

    /**
    * Gets info about an associated checklist to patient
    *
    * @param   i_lang                   Professional preferred language
    * @param   i_prof                   Professional identification and its context (institution and software)
    * @param   i_pat_checklist          Association ID 
    * @param   o_checklist_info         Checklist information (name,type,author,etc..)
    * @param   o_profile_list           Authorized profiles for checklist
    * @param   o_clin_service_list      Specialties where checklist is applicable
    * @param   o_item_list              Checklist items
    * @param   o_item_profile_list      Authorized profiles for checklist items
    * @param   o_item_dependence_list   Dependences between checklist items
    * @param   o_pat_checklist_info     Information related to the association between checklist and patient(requested by,status,cancel info,etc.)
    * @param   o_answer_data            Answers given
    * @param   o_error                  Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   10-Jun-10
    */
    FUNCTION get_pat_checklist
    (
        i_lang                 IN LANGUAGE.id_language%TYPE,
        i_prof                 IN profissional,
        i_pat_checklist        IN pat_checklist.id_pat_checklist%TYPE,
        o_checklist_info       OUT pk_types.cursor_type,
        o_profile_list         OUT pk_types.cursor_type,
        o_clin_service_list    OUT pk_types.cursor_type,
        o_item_list            OUT pk_types.cursor_type,
        o_item_profile_list    OUT pk_types.cursor_type,
        o_item_dependence_list OUT pk_types.cursor_type,
        o_pat_checklist_info   OUT pk_types.cursor_type,
        o_answer_data          OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        e_function_call_error EXCEPTION;
        l_ret BOOLEAN;
    BEGIN
        g_error := 'Get checklist info for reports';
        alertlog.pk_alertlog.log_debug(text            => g_error,
                                       object_name     => g_package,
                                       sub_object_name => 'get_pat_checklist');
    
        l_ret := pk_checklist_core.get_pat_checklist(i_lang                 => i_lang,
                                                     i_prof                 => i_prof,
                                                     i_pat_checklist        => i_pat_checklist,
                                                     o_checklist_info       => o_checklist_info,
                                                     o_profile_list         => o_profile_list,
                                                     o_clin_service_list    => o_clin_service_list,
                                                     o_item_list            => o_item_list,
                                                     o_item_profile_list    => o_item_profile_list,
                                                     o_item_dependence_list => o_item_dependence_list,
                                                     o_pat_checklist_info   => o_pat_checklist_info,
                                                     o_answer_data          => o_answer_data,
                                                     o_error                => o_error);
        IF l_ret = FALSE
        THEN
            RAISE e_function_call_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_function_call_error THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => o_error.ora_sqlcode,
                                              i_sqlerrm  => o_error.ora_sqlerrm,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'get_pat_checklist',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_checklist_info);
            pk_types.open_my_cursor(o_profile_list);
            pk_types.open_my_cursor(o_clin_service_list);
            pk_types.open_my_cursor(o_item_list);
            pk_types.open_my_cursor(o_item_profile_list);
            pk_types.open_my_cursor(o_item_dependence_list);
            pk_types.open_my_cursor(o_pat_checklist_info);
            pk_types.open_my_cursor(o_answer_data);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'get_pat_checklist',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_checklist_info);
            pk_types.open_my_cursor(o_profile_list);
            pk_types.open_my_cursor(o_clin_service_list);
            pk_types.open_my_cursor(o_item_list);
            pk_types.open_my_cursor(o_item_profile_list);
            pk_types.open_my_cursor(o_item_dependence_list);
            pk_types.open_my_cursor(o_pat_checklist_info);
            pk_types.open_my_cursor(o_answer_data);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_pat_checklist;

BEGIN
    -- Initialization

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_checklist_api_rep;
/
