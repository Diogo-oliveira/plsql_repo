/*-- Last Change Revision: $Rev: 2027633 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:51 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_rep_death_registry AS

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

    --

    FUNCTION get_dr_section_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN NUMBER,
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

    /**********************************************************************************************
    * Returns death registry summary
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_patient                Patient id
    * @param        i_component_name         Component internal name
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
        o_section        OUT pk_types.cursor_type,
        o_data_val       OUT table_table_varchar,
        o_prof_data      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_DR_SUMMARY';
        l_dbg_msg debug_msg;
    
        l_data_val pk_types.cursor_type;
    
    BEGIN
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
            pk_types.open_my_cursor(i_cursor => o_section);
            pk_types.open_my_cursor(i_cursor => l_data_val);
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
            pk_types.open_my_cursor(i_cursor => l_data_val);
            RETURN FALSE;
        
    END get_dr_summary;

    --

    FUNCTION get_dr_detail
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_record         IN death_registry.id_death_registry%TYPE,
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

    FUNCTION get_component_desc
    (
        i_lang              IN NUMBER,
        i_ds_component      IN NUMBER,
        o_ds_component_desc OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_DR_DETAIL';
    
    BEGIN
        o_ds_component_desc := pk_death_registry.get_component_desc(i_lang => i_lang, i_ds_component => i_ds_component);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => NULL,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_component_desc;

    FUNCTION get_dr_rep_summary
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_section_name   IN VARCHAR2,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_component_type IN ds_cmpt_mkt_rel.flg_component_type_parent%TYPE DEFAULT pk_dynamic_screen.c_node_component,
        o_section        OUT pk_types.cursor_type,
        o_data_val       OUT table_table_varchar,
        o_prof_data      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_death_registry.get_dr_rep_summary(i_lang           => i_lang,
                                                    i_prof           => i_prof,
                                                    i_patient        => i_patient,
                                                    i_section_name   => i_section_name,
                                                    i_component_name => i_component_name,
                                                    i_component_type => i_component_type,
                                                    o_section        => o_section,
                                                    o_data_val       => o_data_val,
                                                    o_prof_data      => o_prof_data,
                                                    o_error          => o_error);
    
    END get_dr_rep_summary;

    ---***************

    --***************************
    FUNCTION get_rep_component_desc
    (
        i_lang               IN NUMBER,
        i_section_name       IN VARCHAR2,
        i_id_ds_cmpt_kmt_rel IN NUMBER,
        o_ds_component_desc  OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'get_rep_component_desc';
    BEGIN
    
        o_ds_component_desc := pk_death_registry.get_rep_component_desc(i_lang               => i_lang,
                                                      i_section_name       => i_section_name,
                                                      i_id_ds_cmpt_kmt_rel => i_id_ds_cmpt_kmt_rel);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => NULL,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_rep_component_desc;

--
-- INITIALIZATION SECTION
-- 

BEGIN
    -- Initializes log context
    pk_alertlog.log_init(object_name => c_package_name);
END pk_rep_death_registry;
/
