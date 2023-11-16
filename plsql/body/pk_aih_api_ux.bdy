/*-- Last Change Revision: $Rev: 2026628 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:23 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_aih_api_ux IS

    FUNCTION get_section_events_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_component_name IN ds_component.internal_name%TYPE,
        o_section        OUT pk_types.cursor_type,
        o_def_events     OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT VARCHAR2(30 CHAR) := 'GET_SECTION_EVENTS_LIST';
        l_dbg_msg VARCHAR2(100 CHAR);
    
    BEGIN
    
        IF NOT pk_aih.get_section_events_list(i_lang           => i_lang,
                                              i_prof           => i_prof,
                                              i_component_name => i_component_name,
                                              o_section        => o_section,
                                              o_def_events     => o_def_events,
                                              o_error          => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
        
            pk_types.open_my_cursor(i_cursor => o_section);
            pk_types.open_my_cursor(i_cursor => o_def_events);
            RETURN FALSE;
        
    END get_section_events_list;

    FUNCTION get_section_data
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_ds_component IN ds_component.internal_name%TYPE,
        i_aih_simple   IN aih_simple.id_aih_simple%TYPE,
        i_params       IN CLOB,
        o_section      OUT pk_types.cursor_type,
        o_def_events   OUT pk_types.cursor_type,
        o_events       OUT pk_types.cursor_type,
        o_items_values OUT pk_types.cursor_type,
        o_data_val     OUT CLOB,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_SECTION_DATA';
        --
        l_tbl_section      t_table_ds_sections; --o_section
        l_tbl_def_events   t_table_ds_def_events; --o_def_events cursor
        l_tbl_events       t_table_ds_events; --o_events cursor
        l_tbl_items_values t_table_ds_items_values; --o_items_values
    
        l_aux_data_val xmltype; --o_data_val
        --   
        l_exception EXCEPTION;
    BEGIN
        g_error := 'CALL GET_SECTION_DATA_DB';
    
        IF NOT pk_aih.get_section_data(i_lang         => i_lang,
                                       i_prof         => i_prof,
                                       i_patient      => i_patient,
                                       i_episode      => i_episode,
                                       i_ds_component => i_ds_component,
                                       i_aih_simple   => i_aih_simple,
                                       --i_params       => '<COMPONENTS><COMPONENT_LEAF ALT_VALUE="1" VALUE="1" DESC_VALUE="Mudança Solic" INTERNAL_NAME="AIHS_SOLIC" ID_DS_CMPT_MKT_REL="890" /></COMPONENTS>',
                                       i_params       => i_params,
                                       o_section      => o_section,
                                       o_def_events   => o_def_events,
                                       o_events       => o_events,
                                       o_items_values => o_items_values,
                                       o_data_val     => o_data_val,
                                       o_error        => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            pk_types.open_my_cursor(i_cursor => o_section);
            pk_types.open_my_cursor(i_cursor => o_def_events);
            pk_types.open_my_cursor(i_cursor => o_events);
            pk_types.open_my_cursor(i_cursor => o_items_values);
            o_data_val := NULL;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
        
            pk_types.open_my_cursor(i_cursor => o_section);
            pk_types.open_my_cursor(i_cursor => o_def_events);
            pk_types.open_my_cursor(i_cursor => o_events);
            pk_types.open_my_cursor(i_cursor => o_items_values);
            o_data_val := NULL;
            RETURN FALSE;
    END get_section_data;

    FUNCTION set_aih_simple
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_id_epis_pn IN epis_pn.id_epis_pn%TYPE,
        i_xml        IN CLOB,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN AS
        l_func_name CONSTANT VARCHAR2(30) := 'SET_AIH_SIMPLE';
    BEGIN
    
        IF NOT pk_aih.set_aih_simple(i_lang       => i_lang,
                                     i_prof       => i_prof,
                                     i_patient    => i_patient,
                                     i_episode    => i_episode,
                                     i_xml        => i_xml,
                                     i_id_epis_pn => i_id_epis_pn,
                                     o_error      => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
        
            RETURN FALSE;
        
    END set_aih_simple;

    FUNCTION set_aih_special
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_id_epis_pn IN epis_pn.id_epis_pn%TYPE,
        i_xml        IN CLOB,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN AS
        l_func_name CONSTANT VARCHAR2(30) := 'SET_AIH_SIMPLE';
    BEGIN
    
        IF NOT pk_aih.set_aih_special(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_patient    => i_patient,
                                      i_episode    => i_episode,
                                      i_xml        => i_xml,
                                      i_id_epis_pn => i_id_epis_pn,
                                      o_error      => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
        
            RETURN FALSE;
        
    END set_aih_special;

END pk_aih_api_ux;
/
