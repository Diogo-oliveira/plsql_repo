/*-- Last Change Revision: $Rev: 2027831 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:26 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_ux_death_registry AS

    --
    -- PRIVATE SUBTYPES
    --

    SUBTYPE obj_name IS VARCHAR2(32 CHAR);
    SUBTYPE debug_msg IS VARCHAR2(200 CHAR);

    --
    -- PRIVATE CONSTANTS
    --

    -- Package info
    c_package_owner CONSTANT obj_name := 'ALERT';
    c_package_name  CONSTANT obj_name := pk_alertlog.who_am_i();

    --
    -- PUBLIC FUNCTIONS
    --

    /**********************************************************************************************
    * Returns the patient death registry id
    *
    * @param        i_lang                   Language id
    * @param        i_patient                Patient id
    * @param        o_death_registry         Death registry id (null if patient has none)
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *
    * @author       Paulo Fonseca
    * @version      2.6.0.3
    * @since        08-Jun-2010
    **********************************************************************************************/
    FUNCTION get_pat_death_registry
    (
        i_lang           IN language.id_language%TYPE,
        i_patient        IN patient.id_patient%TYPE,
        o_death_registry OUT death_registry.id_death_registry%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_PAT_DEATH_REGISTRY';
        l_dbg_msg debug_msg;
    
    BEGIN
        l_dbg_msg := 'get death registry summary';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        IF NOT pk_death_registry.get_pat_death_registry(i_lang           => i_lang,
                                                        i_patient        => i_patient,
                                                        o_death_registry => o_death_registry,
                                                        o_error          => o_error)
        THEN
            o_death_registry := NULL;
            RETURN FALSE;
        END IF;
    
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
        
            o_death_registry := NULL;
            RETURN FALSE;
        
    END get_pat_death_registry;

    /**********************************************************************************************
    * Returns death registry summary
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_patient                Patient id
    * @param        i_component_name         Component internal name
    * @param        o_component_name         Component internal name
    * @param        o_section                Section components structure
    * @param        o_data_val               Components values
    * @param        o_prof_data              Professional who has made the changes (name,
    *                                        speciality and date of changes)
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *
    * @author       Paulo Fonseca
    * @version      2.6.0.3
    * @since        08-Jun-2010
    **********************************************************************************************/
    FUNCTION get_dr_summary
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        o_component_name OUT ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        o_section        OUT pk_types.cursor_type,
        o_data_val       OUT table_table_varchar,
        o_prof_data      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_DR_SUMMARY';
        l_dbg_msg debug_msg;
    
    BEGIN
        o_component_name := i_component_name;
    
        l_dbg_msg := 'get death registry summary';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        IF NOT pk_death_registry.get_dr_summary(i_lang           => i_lang,
                                                i_prof           => i_prof,
                                                i_patient        => i_patient,
                                                i_component_name => i_component_name,
                                                o_section        => o_section,
                                                o_data_val       => o_data_val,
                                                o_prof_data      => o_prof_data,
                                                o_error          => o_error)
        THEN
            o_data_val := NULL;
            pk_types.open_my_cursor(i_cursor => o_section);
            pk_types.open_my_cursor(i_cursor => o_prof_data);
            RETURN FALSE;
        END IF;
    
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
        
            o_data_val := NULL;
            pk_types.open_my_cursor(i_cursor => o_section);
            pk_types.open_my_cursor(i_cursor => o_prof_data);
            RETURN FALSE;
        
    END get_dr_summary;

    --

    FUNCTION get_dr_section_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_section OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_DR_SECTION_LIST';
        l_dbg_msg debug_msg;
    
    BEGIN
        l_dbg_msg := 'get death registry section list';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        IF NOT pk_death_registry.get_dr_section_list(i_lang    => i_lang,
                                                     i_prof    => i_prof,
                                                     i_patient => i_patient,
                                                     o_section => o_section,
                                                     o_error   => o_error)
        THEN
            pk_types.open_my_cursor(i_cursor => o_section);
            RETURN FALSE;
        END IF;
    
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
        
            pk_types.open_my_cursor(i_cursor => o_section);
            RETURN FALSE;
        
    END get_dr_section_list;

    --

    FUNCTION get_dr_section_events_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        o_section    OUT pk_types.cursor_type,
        o_def_events OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_DR_SECTION_EVENTS_LIST';
        l_dbg_msg debug_msg;
    
    BEGIN
        l_dbg_msg := 'get death registry section list';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        IF NOT pk_death_registry.get_dr_section_events_list(i_lang       => i_lang,
                                                            i_prof       => i_prof,
                                                            o_section    => o_section,
                                                            o_def_events => o_def_events,
                                                            o_error      => o_error)
        THEN
            pk_types.open_my_cursor(i_cursor => o_section);
            pk_types.open_my_cursor(i_cursor => o_def_events);
            RETURN FALSE;
        END IF;
    
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
        
            pk_types.open_my_cursor(i_cursor => o_section);
            pk_types.open_my_cursor(i_cursor => o_def_events);
            RETURN FALSE;
        
    END get_dr_section_events_list;

    --

    FUNCTION get_dr_section_data
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_episode        IN NUMBER,
        i_death_registry IN NUMBER,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        o_component_name OUT ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        o_section        OUT pk_types.cursor_type,
        o_def_events     OUT pk_types.cursor_type,
        o_events         OUT pk_types.cursor_type,
        o_items_values   OUT pk_types.cursor_type,
        o_data_val       OUT table_table_varchar,
        o_flg_show       OUT VARCHAR2,
        o_msg            OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_DR_SECTION_DATA';
        l_dbg_msg debug_msg;
    
    BEGIN
        o_component_name := i_component_name;
    
        l_dbg_msg := 'get death registry section and data';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        IF NOT pk_death_registry.get_dr_section_data(i_lang           => i_lang,
                                                     i_prof           => i_prof,
                                                     i_patient        => i_patient,
                                                     i_episode        => i_episode,
                                                     i_death_registry => i_death_registry,
                                                     i_component_name => i_component_name,
                                                     o_section        => o_section,
                                                     o_def_events     => o_def_events,
                                                     o_events         => o_events,
                                                     o_items_values   => o_items_values,
                                                     o_data_val       => o_data_val,
                                                     o_flg_show       => o_flg_show,
                                                     o_msg            => o_msg,
                                                     o_error          => o_error)
        THEN
            o_data_val := NULL;
            pk_types.open_my_cursor(i_cursor => o_section);
            pk_types.open_my_cursor(i_cursor => o_def_events);
            pk_types.open_my_cursor(i_cursor => o_events);
            pk_types.open_my_cursor(i_cursor => o_items_values);
            RETURN FALSE;
        END IF;
    
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
        
            o_data_val := NULL;
            pk_types.open_my_cursor(i_cursor => o_section);
            pk_types.open_my_cursor(i_cursor => o_def_events);
            pk_types.open_my_cursor(i_cursor => o_events);
            pk_types.open_my_cursor(i_cursor => o_items_values);
            RETURN FALSE;
        
    END get_dr_section_data;

    --

    FUNCTION set_dr_data
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_death_registry IN NUMBER,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_data_val       IN table_table_varchar,
        o_id_section     OUT NUMBER,
        o_component_name OUT ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'SET_DR_DATA';
        l_dbg_msg debug_msg;
    
    BEGIN
        o_component_name := i_component_name;
    
        l_dbg_msg := 'set death registry';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        IF NOT pk_death_registry.set_dr_data(i_lang           => i_lang,
                                             i_prof           => i_prof,
                                             i_patient        => i_patient,
                                             i_episode        => i_episode,
                                             i_death_registry => i_death_registry,
                                             i_component_name => i_component_name,
                                             i_data_val       => i_data_val,
                                             o_id_section     => o_id_section,
                                             o_error          => o_error)
        THEN
            pk_utils.undo_changes;
            o_id_section := NULL;
            RETURN FALSE;
        END IF;
    
        l_dbg_msg := 'commit death registry data';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        COMMIT;
    
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
        
            pk_utils.undo_changes;
            o_id_section := NULL;
            RETURN FALSE;
        
    END set_dr_data;

    /**********************************************************************************************
    * Set suspension action id for a patient death registry
    *
    * @param        i_lang                   Language id
    * @param        i_death_registry         Death registry id
    * @param        i_id_susp_action         Suspension action id
    * @param        o_death_registry         Updated death registry id
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *
    * @author       Filipe Machado
    * @version      2.6.0.3
    * @since        22-Jun-2010
    **********************************************************************************************/
    FUNCTION set_death_registry_susp_action
    (
        i_lang           IN language.id_language%TYPE,
        i_death_registry IN death_registry.id_death_registry%TYPE,
        i_id_susp_action IN death_registry.id_susp_action%TYPE,
        o_death_registry OUT death_registry.id_death_registry%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'SET_DEATH_REGISTRY_SUSP_ACTION';
        l_dbg_msg debug_msg;
    
    BEGIN
        l_dbg_msg := 'set death registry suspention action';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        IF NOT pk_death_registry.set_death_registry_susp_action(i_lang           => i_lang,
                                                                i_death_registry => i_death_registry,
                                                                i_id_susp_action => i_id_susp_action,
                                                                o_death_registry => o_death_registry,
                                                                o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        l_dbg_msg := 'commit death registry data';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        COMMIT;
    
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
        
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_death_registry_susp_action;

    /**********************************************************************************************
    * Returns patient final diagnosis for this episode
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_episode                Episode id
    * @param        o_diagnosis              Cursor with patient final diagnosis
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *
    * @author       Filipe Machado
    * @version      2.6.0.3
    * @since        10-Jun-2010
    **********************************************************************************************/
    FUNCTION get_pat_disch_diagnosis
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        o_diagnosis OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_PAT_DISCH_DIAGNOSIS';
        l_dbg_msg debug_msg;
    
    BEGIN
        l_dbg_msg := 'get patient final diagnosis';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        IF NOT pk_death_registry.get_pat_disch_diagnosis(i_lang      => i_lang,
                                                         i_prof      => i_prof,
                                                         i_episode   => i_episode,
                                                         o_diagnosis => o_diagnosis,
                                                         o_error     => o_error)
        THEN
            pk_types.open_my_cursor(i_cursor => o_diagnosis);
            RETURN FALSE;
        END IF;
    
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
        
            pk_types.open_my_cursor(i_cursor => o_diagnosis);
            RETURN FALSE;
        
    END get_pat_disch_diagnosis;

    /**********************************************************************************************
    * Cancel death registry
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_patient                Patient id
    * @param        i_episode                Episode id
    * @param        i_cancel_reason          Cancel reason id
    * @param        i_notes_cancel           Cancel notes
    * @param        i_component_name         Component internal name
    * @param        o_component_name         Component internal name
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *
    * @author       Filipe Machado
    * @version      2.6.0.3
    * @since        17-Jun-2010
    **********************************************************************************************/
    FUNCTION cancel_death_registry
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_death_registry IN NUMBER,
        i_cancel_reason  IN cancel_reason.id_cancel_reason%TYPE,
        i_notes_cancel   IN death_registry.notes_cancel%TYPE,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        o_component_name OUT ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        o_susp_action    OUT death_registry.id_susp_action%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'CANCEL_DEATH_REGISTRY';
        l_dbg_msg debug_msg;
    
    BEGIN
        o_component_name := i_component_name;
    
        l_dbg_msg := 'cancel death registry';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        IF NOT pk_death_registry.cancel_death_registry(i_lang           => i_lang,
                                                       i_prof           => i_prof,
                                                       i_patient        => i_patient,
                                                       i_episode        => i_episode,
                                                       i_death_registry => i_death_registry,
                                                       i_cancel_reason  => i_cancel_reason,
                                                       i_notes_cancel   => i_notes_cancel,
                                                       i_component_name => i_component_name,
                                                       o_susp_action    => o_susp_action,
                                                       o_error          => o_error)
        THEN
            pk_utils.undo_changes;
            o_susp_action := NULL;
            RETURN FALSE;
        END IF;
    
        l_dbg_msg := 'commit death registry data';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        COMMIT;
    
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
        
            pk_utils.undo_changes;
            o_susp_action := NULL;
            RETURN FALSE;
        
    END cancel_death_registry;

    --

    FUNCTION get_dr_detail
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_record         IN death_registry.id_death_registry%TYPE,
        o_component_name OUT ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        o_section        OUT pk_types.cursor_type,
        o_data_val       OUT table_table_varchar,
        o_prof_data      OUT pk_types.cursor_type,
        o_dr_wf          OUT table_table_varchar,
        o_sys_list       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_DR_DETAIL';
        l_dbg_msg debug_msg;
    
    BEGIN
        o_component_name := i_component_name;
    
        l_dbg_msg := 'get death registry details';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        IF NOT pk_death_registry.get_dr_detail(i_lang           => i_lang,
                                               i_prof           => i_prof,
                                               i_patient        => i_patient,
                                               i_component_name => i_component_name,
                                               i_record         => i_record,
                                               o_section        => o_section,
                                               o_data_val       => o_data_val,
                                               o_prof_data      => o_prof_data,
                                               o_dr_wf          => o_dr_wf,
                                               o_sys_list       => o_sys_list,
                                               o_error          => o_error)
        THEN
            o_data_val := NULL;
            o_dr_wf    := NULL;
            pk_types.open_my_cursor(i_cursor => o_section);
            pk_types.open_my_cursor(i_cursor => o_prof_data);
            pk_types.open_my_cursor(i_cursor => o_sys_list);
            RETURN FALSE;
        END IF;
    
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
        
            o_data_val := NULL;
            o_dr_wf    := NULL;
            pk_types.open_my_cursor(i_cursor => o_section);
            pk_types.open_my_cursor(i_cursor => o_prof_data);
            pk_types.open_my_cursor(i_cursor => o_sys_list);
            RETURN FALSE;
        
    END get_dr_detail;

    /**********************************************************************************************
    * Returns the contagious diseases list
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        o_diagnosis              Cursor with diagnosis list for contagious diseases
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *
    * @author       Filipe Machado
    * @version      2.6.0.3
    * @since        08-Jun-2010
    **********************************************************************************************/
    FUNCTION get_contagious_diseases
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_diagnosis OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_CONTAGIOUS_DISEASES';
        l_dbg_msg debug_msg;
    
    BEGIN
        l_dbg_msg := 'get contagious diseases list';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        IF NOT pk_organ_donor.get_contagious_diseases(i_lang      => i_lang,
                                                      i_prof      => i_prof,
                                                      o_diagnosis => o_diagnosis,
                                                      o_error     => o_error)
        THEN
            pk_types.open_my_cursor(i_cursor => o_diagnosis);
            RETURN FALSE;
        END IF;
    
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
        
            pk_types.open_my_cursor(i_cursor => o_diagnosis);
            RETURN FALSE;
        
    END get_contagious_diseases;

    /**********************************************************************************************
    * Returns the patient contagious diseases list
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_patient                Patient id
    * @param        o_diagnosis              Cursor with the patient diagnosis list for
    *                                        contagious diseases
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *
    * @author       Filipe Machado
    * @version      2.6.0.3
    * @since        09-Jun-2010
    **********************************************************************************************/
    FUNCTION get_pat_contagious_diseases
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        o_diagnosis OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_PAT_CONTAGIOUS_DISEASES';
        l_dbg_msg debug_msg;
    
    BEGIN
        l_dbg_msg := 'get contagious diseases list for a patient';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        IF NOT pk_organ_donor.get_pat_contagious_diseases(i_lang      => i_lang,
                                                          i_prof      => i_prof,
                                                          i_patient   => i_patient,
                                                          o_diagnosis => o_diagnosis,
                                                          o_error     => o_error)
        THEN
            pk_types.open_my_cursor(i_cursor => o_diagnosis);
            RETURN FALSE;
        END IF;
    
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
        
            pk_types.open_my_cursor(i_cursor => o_diagnosis);
            RETURN FALSE;
        
    END get_pat_contagious_diseases;

    --
    -- INITIALIZATION SECTION
    --

    FUNCTION get_dr_section_add
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN NUMBER,
        o_section OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_DR_SECTION_ADD';
        l_dbg_msg debug_msg;
        l_bool    BOOLEAN;
    BEGIN
        l_dbg_msg := 'get death registry section add button';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
    
        l_bool := pk_death_registry.get_dr_section_add(i_lang    => i_lang,
                                                       i_prof    => i_prof,
                                                       i_patient => i_patient,
                                                       o_section => o_section,
                                                       o_error   => o_error);
    
        IF NOT l_bool
        THEN
            pk_types.open_my_cursor(i_cursor => o_section);
        END IF;
    
        RETURN l_bool;
    
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
        
            pk_types.open_my_cursor(i_cursor => o_section);
            RETURN FALSE;
        
    END get_dr_section_add;

    FUNCTION get_death_data_inst_clues
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_institution IN institution.id_institution%TYPE,
        o_clues_data  OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_DEATH_DATA_INST_CLUES';
        l_dbg_msg debug_msg;
    
    BEGIN
        l_dbg_msg := 'CALL PK_DEATH_REGISTRY.GET_DEATH_DATA_INST_CLUES';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        IF NOT pk_death_registry.get_death_data_inst_clues(i_lang        => i_lang,
                                                           i_prof        => i_prof,
                                                           i_institution => i_institution,
                                                           o_clues_data  => o_clues_data,
                                                           o_error       => o_error)
        THEN
            pk_types.open_my_cursor(i_cursor => o_clues_data);
            RETURN FALSE;
        END IF;
    
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
        
            pk_types.open_my_cursor(i_cursor => o_clues_data);
            RETURN FALSE;
        
    END get_death_data_inst_clues;

    /**********************************************************************************************
    * This function validates if the selected death_cause is valid according to patient age
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   profissional
    * @param        i_patient                Patient ID
    * @param        o_flg_show               The warning screen should appear? Y - yes, N - No
    * @param        o_msg                    Warning message
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Elisabete Bugalho
    * @version      2.7.0.1 - NOM024
    * @since        28/07/2017
    **********************************************************************************************/

    FUNCTION check_valid_death_diagnosis
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN epis_diagnosis.id_patient%TYPE,
        i_id_diagnosis       IN diagnosis.id_diagnosis%TYPE,
        i_id_alert_diagnosis IN epis_diagnosis.id_alert_diagnosis%TYPE,
        i_component          IN ds_component.internal_name%TYPE,
        o_flg_show           OUT VARCHAR2,
        o_msg                OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'CHECK_VALID_DEATH_DIAGNOSIS';
        l_dbg_msg debug_msg;
    
    BEGIN
        l_dbg_msg := 'CALL PK_DEATH_REGISTRY.CHECK_VALID_DEATH_DIAGNOSIS';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        IF NOT pk_death_registry.check_valid_death_diagnosis(i_lang               => i_lang,
                                                             i_prof               => i_prof,
                                                             i_patient            => i_patient,
                                                             i_id_diagnosis       => i_id_diagnosis,
                                                             i_id_alert_diagnosis => i_id_alert_diagnosis,
                                                             i_component          => i_component,
                                                             o_flg_show           => o_flg_show,
                                                             o_msg                => o_msg,
                                                             o_error              => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
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
        
    END check_valid_death_diagnosis;

    /**********************************************************************************************
    * This function validates patient age betweenfixed intervals for norm24
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   profissional
    * @param        i_patient                Patient ID
    * @param        o_flg_show               The warning screen should appear? Y - yes, N - No
    * @param        o_msg                    Warning message
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Carlos Ferreira
    * @version      2.7.X.X - NOM024
    * @since        23/08//2017
    **********************************************************************************************/
    FUNCTION check_age_range
    (
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_patient   IN NUMBER,
        i_flg_death IN VARCHAR2,
        o_flg_show  OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_age NUMBER;
        k_year     CONSTANT VARCHAR2(0010 CHAR) := 'Y';
        k_code_msg CONSTANT VARCHAR2(0200 CHAR) := 'DR_NORM024_013';
        l_bool_inf BOOLEAN;
        l_bool_sup BOOLEAN;
        l_msg      VARCHAR2(4000);
    
    BEGIN
    
        RETURN pk_death_registry.check_age_range(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_patient   => i_patient,
                                                 i_flg_death => i_flg_death,
                                                 o_flg_show  => o_flg_show,
                                                 o_msg       => o_msg,
                                                 o_error     => o_error);
    
    END check_age_range;

BEGIN
    -- Initializes log context
    pk_alertlog.log_init(object_name => c_package_name);
END pk_ux_death_registry;
/
