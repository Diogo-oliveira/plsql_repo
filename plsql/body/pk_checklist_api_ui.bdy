/*-- Last Change Revision: $Rev: 2026863 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:13 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_checklist_api_ui IS

    -- Private type declarations

    -- Private constant declarations
    g_detail_level_general CONSTANT VARCHAR2(1 CHAR) := 'G';
    g_detail_level_history CONSTANT VARCHAR2(1 CHAR) := 'H';

    -- Private variable declarations

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Function and procedure implementations

    /**
    * Gets a list of checklists for patient and where professional has authorization to visualize and/or fill them
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_patient      Patient ID 
    * @param   i_episode      Episode ID
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
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ret BOOLEAN;
        e_function_call_error EXCEPTION;
    BEGIN
        l_ret := pk_checklist_core.get_pat_checklist_list(i_lang    => i_lang,
                                                          i_prof    => i_prof,
                                                          i_patient => i_patient,
                                                          i_episode => i_episode,
                                                          o_list    => o_list,
                                                          o_error   => o_error);
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
    * Gets a list of available checklists for professional
    *
    * @param   i_lang              Professional preferred language
    * @param   i_prof              Professional identification and its context (institution and software)
    * @param   i_filter_speciality Filter the list to only those checklist for specialties in which the professional is allocated
    * @param   o_list              Checklist list
    * @param   o_error             Error information
    *
    * @value   i_filter_speciality    {*} 'Y' filter by specialities  {*} 'N' Unfiltered
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   08-Jun-10
    */
    FUNCTION get_prof_checklist_list
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_filter_speciality IN VARCHAR2,
        o_list              OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ret BOOLEAN;
        e_function_call_error EXCEPTION;
    BEGIN
        l_ret := pk_checklist_core.get_prof_checklist_list(i_lang              => i_lang,
                                                           i_prof              => i_prof,
                                                           i_filter_speciality => i_filter_speciality,
                                                           o_list              => o_list,
                                                           o_error             => o_error);
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
                                              i_function => 'get_prof_checklist_list',
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
                                              i_function => 'get_prof_checklist_list',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_prof_checklist_list;

    /**
    * Associates a list of specific versions of checklists to patient
    *
    * @param   i_lang                   Professional preferred language
    * @param   i_prof                   Professional identification and its context (institution and software)
    * @param   i_tab_cnt_creator        List of Checklist content creator 
    * @param   i_tab_checklist_version  List of Checklist version ID to associate
    * @param   i_patient                Patient ID 
    * @param   i_episode                Episode ID
    * @param   i_test                   Tests attempt to associate a checklist already associated (Y/N)
    * @param   o_tab_pat_checklist      List of created record IDs 
    * @param   o_flg_show               Set if a message is displayed or not
    * @param   o_msg_title              Message title
    * @param   o_msg                    Message body
    * @param   o_error                  Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.5
    * @since   2/11/2011
    */
    FUNCTION set_pat_checklist
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_tab_cnt_creator       IN table_varchar,
        i_tab_checklist_version IN table_number,
        i_patient               IN patient.id_patient%TYPE,
        i_episode               IN episode.id_episode%TYPE,
        i_test                  IN VARCHAR2,
        o_tab_pat_checklist     OUT table_number,
        o_flg_show              OUT VARCHAR2,
        o_msg_title             OUT VARCHAR2,
        o_msg                   OUT VARCHAR2,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_checklist_core.set_pat_checklist(i_lang                  => i_lang,
                                                   i_prof                  => i_prof,
                                                   i_tab_cnt_creator       => i_tab_cnt_creator,
                                                   i_tab_checklist_version => i_tab_checklist_version,
                                                   i_patient               => i_patient,
                                                   i_episode               => i_episode,
                                                   i_test                  => i_test,
                                                   o_tab_pat_checklist     => o_tab_pat_checklist,
                                                   o_flg_show              => o_flg_show,
                                                   o_msg_title             => o_msg_title,
                                                   o_msg                   => o_msg,
                                                   o_error                 => o_error);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'set_pat_checklist',
                                              o_error    => o_error);
            ROLLBACK;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_pat_checklist;

    /**
    * Cancels a previous association of checklist to patient
    *
    * @param   i_lang           Professional preferred language
    * @param   i_prof           Professional identification and its context (institution and software)
    * @param   i_pat_checklist  Association ID to cancel
    * @param   i_cancel_reason  Cancel reason ID
    * @param   i_cancel_notes   Cancelation notes
    * @param   o_error          Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   08-Jun-10
    */
    FUNCTION cancel_pat_checklist
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_checklist IN pat_checklist.id_pat_checklist%TYPE,
        i_cancel_reason IN pat_checklist.id_cancel_reason%TYPE,
        i_cancel_notes  IN pat_checklist.cancel_notes%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ret BOOLEAN;
        e_function_call_error EXCEPTION;
    BEGIN
    
        l_ret := pk_checklist_core.cancel_pat_checklist(i_lang          => i_lang,
                                                        i_prof          => i_prof,
                                                        i_pat_checklist => i_pat_checklist,
                                                        i_cancel_reason => i_cancel_reason,
                                                        i_cancel_notes  => i_cancel_notes,
                                                        o_error         => o_error);
        IF l_ret = FALSE
        THEN
            RAISE e_function_call_error;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN e_function_call_error THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => o_error.ora_sqlcode,
                                              i_sqlerrm  => o_error.ora_sqlerrm,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'cancel_pat_checklist',
                                              o_error    => o_error);
            ROLLBACK;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'cancel_pat_checklist',
                                              o_error    => o_error);
            ROLLBACK;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END cancel_pat_checklist;

    /**
    * Gets info about an associated checklist to patient
    *
    * @param   i_lang                   Professional preferred language
    * @param   i_prof                   Professional identification and its context (institution and software)
    * @param   i_pat_checklist          Association ID 
    * @param   o_checklist_info         Checklist information (name,type,author,etc..)
    * @param   o_profile_list           Authorized profiles for checklist
    * @param   o_item_list              Checklist items
    * @param   o_item_profile_list      Authorized profiles for checklist items
    * @param   o_item_dependence_list   Dependences between checklist items
    * @param   o_pat_checklist_info     Information related to the association between checklist and patient (requested by,status,cancel info,etc.)
    * @param   o_answer_data            Answers given
    * @param   o_error                  Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   08-Jun-10
    */
    FUNCTION get_pat_checklist
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_pat_checklist        IN pat_checklist.id_pat_checklist%TYPE,
        o_checklist_info       OUT pk_types.cursor_type,
        o_profile_list         OUT pk_types.cursor_type,
        o_item_list            OUT pk_types.cursor_type,
        o_item_profile_list    OUT pk_types.cursor_type,
        o_item_dependence_list OUT pk_types.cursor_type,
        o_pat_checklist_info   OUT pk_types.cursor_type,
        o_answer_data          OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        e_function_call_error EXCEPTION;
        l_clin_service_list pk_types.cursor_type;
        l_ret               BOOLEAN;
    BEGIN
        g_error := 'Get checklist info';
        alertlog.pk_alertlog.log_debug(text            => g_error,
                                       object_name     => g_package,
                                       sub_object_name => 'get_pat_checklist');
    
        l_ret := pk_checklist_core.get_pat_checklist(i_lang                 => i_lang,
                                                     i_prof                 => i_prof,
                                                     i_pat_checklist        => i_pat_checklist,
                                                     o_checklist_info       => o_checklist_info,
                                                     o_profile_list         => o_profile_list,
                                                     o_clin_service_list    => l_clin_service_list,
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
    
        g_error := 'Closing unused cursor';
        CLOSE l_clin_service_list;
    
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
            pk_types.open_my_cursor(o_item_list);
            pk_types.open_my_cursor(o_item_profile_list);
            pk_types.open_my_cursor(o_item_dependence_list);
            pk_types.open_my_cursor(o_pat_checklist_info);
            pk_types.open_my_cursor(o_answer_data);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_pat_checklist;

    /**
    * Saves answers given in an associated checklist to patient
    *
    * @param   i_lang           Professional preferred language
    * @param   i_prof           Professional identification and its context (institution and software)
    * @param   i_pat_checklist  Association ID 
    * @param   i_episode        Episode ID
    * @param   i_tab_item       List of cheklist item ID
    * @param   i_tab_answer     List of answers given
    * @param   i_tab_notes      List of observations in answers given
    * @param   o_error          Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   08-Jun-10
    */
    FUNCTION set_pat_checklist_answer
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_checklist IN pat_checklist.id_pat_checklist%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_tab_item      IN table_number,
        i_tab_answer    IN table_varchar,
        i_tab_notes     IN table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ret BOOLEAN;
        e_function_call_error EXCEPTION;
    BEGIN
        l_ret := pk_checklist_core.set_pat_checklist_answer(i_lang          => i_lang,
                                                            i_prof          => i_prof,
                                                            i_pat_checklist => i_pat_checklist,
                                                            i_episode       => i_episode,
                                                            i_tab_item      => i_tab_item,
                                                            i_tab_answer    => i_tab_answer,
                                                            i_tab_notes     => i_tab_notes,
                                                            o_error         => o_error);
        IF l_ret = FALSE
        THEN
            RAISE e_function_call_error;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_function_call_error THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => o_error.ora_sqlcode,
                                              i_sqlerrm  => o_error.ora_sqlerrm,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'set_pat_checklist_answer',
                                              o_error    => o_error);
            ROLLBACK;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'set_pat_checklist_answer',
                                              o_error    => o_error);
            ROLLBACK;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_pat_checklist_answer;

    /**
    * Gets detailed information about an associated checklist to patient
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_pat_checklist      Association ID
    * @param   i_detail_level       Detail level 
    * @param   o_checklist_info     Checklist information (name,type,author,etc..)
    * @param   o_profile_list       Authorized profiles for checklist
    * @param   o_clin_service_list  Specialties where checklist is applicable
    * @param   o_item_list          Checklist items
    * @param   o_pat_checklist_info Information related to the association between checklist and patient(requested by,status,cancel info,etc.)
    * @param   o_answer_data        Answers given
    * @param   o_error              Error information
    *
    * @value   i_detail_level {*} 'G' General {*} 'H' History
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   11-Jun-10
    */
    FUNCTION get_pat_checklist_detail
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_pat_checklist      IN pat_checklist.id_pat_checklist%TYPE,
        i_detail_level       IN VARCHAR2,
        o_checklist_info     OUT pk_types.cursor_type,
        o_profile_list       OUT pk_types.cursor_type,
        o_clin_service_list  OUT pk_types.cursor_type,
        o_item_list          OUT pk_types.cursor_type,
        o_pat_checklist_info OUT pk_types.cursor_type,
        o_answer_data        OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        e_function_call_error EXCEPTION;
        e_not_implemented EXCEPTION;
        l_item_profile_list    pk_types.cursor_type;
        l_item_dependence_list pk_types.cursor_type;
        l_ret                  BOOLEAN;
    BEGIN
        IF i_detail_level = g_detail_level_general
        THEN
            g_error := 'Get last checklist info';
            alertlog.pk_alertlog.log_debug(text            => g_error,
                                           object_name     => g_package,
                                           sub_object_name => 'get_pat_checklist_detail');
        
            l_ret := pk_checklist_core.get_pat_checklist(i_lang                 => i_lang,
                                                         i_prof                 => i_prof,
                                                         i_pat_checklist        => i_pat_checklist,
                                                         o_checklist_info       => o_checklist_info,
                                                         o_profile_list         => o_profile_list,
                                                         o_clin_service_list    => o_clin_service_list,
                                                         o_item_list            => o_item_list,
                                                         o_item_profile_list    => l_item_profile_list,
                                                         o_item_dependence_list => l_item_dependence_list,
                                                         o_pat_checklist_info   => o_pat_checklist_info,
                                                         o_answer_data          => o_answer_data,
                                                         o_error                => o_error);
            IF l_ret = FALSE
            THEN
                RAISE e_function_call_error;
            END IF;
            g_error := 'Closing unused cursors';
            CLOSE l_item_profile_list;
            CLOSE l_item_dependence_list;
        
        ELSIF i_detail_level = g_detail_level_history
        THEN
            --Currently, the functionality to show history is not implemented
            g_error := 'Get checklist info from historical: Not implemented yet';
            RAISE e_not_implemented;
        ELSE
            g_error := 'Unexpected value for input parameter i_detail_level: ' || i_detail_level;
            RAISE e_not_implemented;
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
                                              i_function => 'get_pat_checklist_detail',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_checklist_info);
            pk_types.open_my_cursor(o_profile_list);
            pk_types.open_my_cursor(o_clin_service_list);
            pk_types.open_my_cursor(o_item_list);
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
                                              i_function => 'get_pat_checklist_detail',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_checklist_info);
            pk_types.open_my_cursor(o_profile_list);
            pk_types.open_my_cursor(o_clin_service_list);
            pk_types.open_my_cursor(o_item_list);
            pk_types.open_my_cursor(o_pat_checklist_info);
            pk_types.open_my_cursor(o_answer_data);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_pat_checklist_detail;
		
		
    /**************************************************************************
    * Saves answers given in an associated checklist to patient               *
    *                                                                         *
    * @param   i_lang               Professional preferred language           *
    * @param   i_prof               Professional identification and its       *
    *                               context (institution and software)        *
    * @param   i_pat_checklist      Association ID                            *
    * @param   i_episode            Episode ID                                *
    * @param   i_tab_item           List of cheklist item ID                  *
    * @param   i_tab_answer         List of answers given                     *
    * @param   i_tab_notes          List of observations in answers given     *
    * @param   i_cnt_creator        List of Checklist content creator         *
    * @param   i_checklist_version  List of Checklist version ID to associate *
    * @param   i_patient            Patient ID                                *
    * @param   o_tab_pat_checklist  List of created record IDs                *
    * @param   o_error              Error information                         *
    *                                                                         *
    * @return  True or False on success or error                              *
    *                                                                         *
    * @author  Gustavo Serrano                                                *
    * @version 2.6.0.5                                                        *
    * @since   15-Fev-11                                                      *
    **************************************************************************/
    FUNCTION set_pat_checklist_answer
    (
        i_lang              IN language.id_language%TYPE
       ,i_prof              IN profissional
       ,i_pat_checklist     IN pat_checklist.id_pat_checklist%TYPE
       ,i_episode           IN episode.id_episode%TYPE
       ,i_tab_item          IN table_number
       ,i_tab_answer        IN table_varchar
       ,i_tab_notes         IN table_varchar
       ,i_cnt_creator       IN pat_checklist.flg_content_creator%TYPE
       ,i_checklist_version IN pat_checklist.id_checklist_version%TYPE
       ,i_patient           IN patient.id_patient%TYPE
       ,o_tab_pat_checklist OUT table_number
       ,o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ret BOOLEAN;
        e_function_call_error EXCEPTION;
    BEGIN
        l_ret := pk_checklist_core.set_pat_checklist_answer(i_lang              => i_lang
                                                           ,i_prof              => i_prof
                                                           ,i_pat_checklist     => i_pat_checklist
                                                           ,i_episode           => i_episode
                                                           ,i_tab_item          => i_tab_item
                                                           ,i_tab_answer        => i_tab_answer
                                                           ,i_tab_notes         => i_tab_notes
                                                           ,i_cnt_creator       => i_cnt_creator
                                                           ,i_checklist_version => i_checklist_version
                                                           ,i_patient           => i_patient
                                                           ,o_tab_pat_checklist => o_tab_pat_checklist
                                                           ,o_error             => o_error);
        IF l_ret = FALSE
        THEN
            RAISE e_function_call_error;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_function_call_error THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang
                                             ,i_sqlcode  => o_error.ora_sqlcode
                                             ,i_sqlerrm  => o_error.ora_sqlerrm
                                             ,i_message  => g_error
                                             ,i_owner    => g_owner
                                             ,i_package  => g_package
                                             ,i_function => 'set_pat_checklist_answer'
                                             ,o_error    => o_error);
            ROLLBACK;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang
                                             ,i_sqlcode  => SQLCODE
                                             ,i_sqlerrm  => SQLERRM
                                             ,i_message  => g_error
                                             ,i_owner    => g_owner
                                             ,i_package  => g_package
                                             ,i_function => 'set_pat_checklist_answer'
                                             ,o_error    => o_error);
            ROLLBACK;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_pat_checklist_answer;
		
	/**
    * Gets a specific checklist version
    *
    * @param   i_lang                   Professional preferred language
    * @param   i_prof                   Professional identification and its context (institution and software)
    * @param   i_content_creator        Checklist content creator
    * @param   i_checklist_version      Checklist version ID
    * @param   o_checklist_info         Checklist information (name,type,author,etc..)
    * @param   o_profile_list           Authorized profiles for checklist
    * @param   o_item_list              Checklist items
    * @param   o_item_profile_list      Authorized profiles for checklist items
    * @param   o_item_dependence_list   Dependences between checklist items
    * @param   o_error                  Error information
    *
    * @value   i_content_creator    {*} 'A' ALERT {*} 'I' Institution
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   17-Fev-11
    */
    FUNCTION get_checklist
    (
        i_lang                 IN language.id_language%TYPE
       ,i_prof                 IN profissional
       ,i_content_creator      IN checklist_version.flg_content_creator%TYPE
       ,i_checklist_version    IN checklist_version.id_checklist_version%TYPE
       ,o_checklist_info       OUT pk_types.cursor_type
       ,o_profile_list         OUT pk_types.cursor_type
       ,o_item_list            OUT pk_types.cursor_type
       ,o_item_profile_list    OUT pk_types.cursor_type
       ,o_item_dependence_list OUT pk_types.cursor_type
       ,o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        e_function_call_error EXCEPTION;
        l_clin_service_list pk_types.cursor_type;
        l_ret               BOOLEAN;
    BEGIN
        g_error := 'Get checklist info';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => 'get_checklist');
    
        l_ret := pk_checklist_core.get_checklist(i_lang                 => i_lang
                                                ,i_prof                 => i_prof
                                                ,i_content_creator      => i_content_creator
                                                ,i_checklist_version    => i_checklist_version
                                                ,o_checklist_info       => o_checklist_info
                                                ,o_profile_list         => o_profile_list
                                                ,o_clin_service_list    => l_clin_service_list
                                                ,o_item_list            => o_item_list
                                                ,o_item_profile_list    => o_item_profile_list
                                                ,o_item_dependence_list => o_item_dependence_list
                                                ,o_error                => o_error);
        IF l_ret = FALSE
        THEN
            RAISE e_function_call_error;
        END IF;
    
        g_error := 'Closing unused cursor';
        CLOSE l_clin_service_list;
    
        RETURN TRUE;
    EXCEPTION
        WHEN e_function_call_error THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang
                                             ,i_sqlcode  => o_error.ora_sqlcode
                                             ,i_sqlerrm  => o_error.ora_sqlerrm
                                             ,i_message  => g_error
                                             ,i_owner    => g_owner
                                             ,i_package  => g_package
                                             ,i_function => 'get_checklist'
                                             ,o_error    => o_error);
            pk_types.open_my_cursor(o_checklist_info);
            pk_types.open_my_cursor(o_profile_list);
            pk_types.open_my_cursor(o_item_list);
            pk_types.open_my_cursor(o_item_profile_list);
            pk_types.open_my_cursor(o_item_dependence_list);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang
                                             ,i_sqlcode  => SQLCODE
                                             ,i_sqlerrm  => SQLERRM
                                             ,i_message  => g_error
                                             ,i_owner    => g_owner
                                             ,i_package  => g_package
                                             ,i_function => 'get_checklist'
                                             ,o_error    => o_error);
            pk_types.open_my_cursor(o_checklist_info);
            pk_types.open_my_cursor(o_profile_list);
            pk_types.open_my_cursor(o_item_list);
            pk_types.open_my_cursor(o_item_profile_list);
            pk_types.open_my_cursor(o_item_dependence_list);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_checklist;
		
BEGIN
    -- Initialization

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_checklist_api_ui;
/
