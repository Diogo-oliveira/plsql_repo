/*-- Last Change Revision: $Rev: 2027804 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:21 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_touch_option_api_rep IS

    -- Private type declarations

    -- Private constant declarations

    -- Private variable declarations

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Function and procedure implementations

    /**
    * Returns a set of records done in a touch-option area based on filters criteria and with paging support
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_doc_area           Documentation area ID
    * @param   i_current_episode    Current episode ID
    * @param   i_scope              Scope ID (Episode ID; Visit ID; Patient ID)
    * @param   i_scope_type         Scope type (by episode; by visit; by patient)
    * @param   i_fltr_status        A sequence of flags representing the status that records must comply ('A' Active, 'O' Outdated, 'C' Cancelled)
    * @param   i_order              Indicates the chronological order of records returned ('ASC' Ascending , 'DESC' Descending)
    * @param   i_fltr_start_date    Begin date in serialized format: YYYYMMDDhhmmss        
    * @param   i_fltr_end_date      End date in serialized format: YYYYMMDDhhmmss        
    * @param   i_paging             Use paging ('Y' Yes; 'N' No)
    * @param   i_start_record       First record. Just considered when paging is used.
    * @param   i_num_records        Number of records to be retrieved. Just considered when paging is used.
    * @param   o_doc_area_register  Cursor with the doc area info register
    * @param   o_doc_area_val       Cursor containing the completed info for episode
    * @param   o_template_layouts   Cursor containing the layout for each template used
    * @param   o_doc_area_component Cursor containing the components for each template used 
    * @param   o_record_count       Indicates the number of records that match filters criteria
    * @param   o_error              Error message 
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.5.1.8.2
    * @since   06/10/2011
    */
    FUNCTION get_doc_area_value
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_doc_area            IN doc_area.id_doc_area%TYPE,
        i_current_episode     IN episode.id_episode%TYPE,
        i_scope               IN NUMBER,
        i_scope_type          IN VARCHAR2,
        i_fltr_status         IN VARCHAR2,
        i_order               IN VARCHAR2,
        i_fltr_start_date_str IN VARCHAR2,
        i_fltr_end_date_str   IN VARCHAR2,
        i_paging              IN VARCHAR2,
        i_start_record        IN NUMBER,
        i_num_records         IN NUMBER,
        o_doc_area_register   OUT pk_types.cursor_type,
        o_doc_area_val        OUT pk_types.cursor_type,
        o_template_layouts    OUT pk_types.cursor_type,
        o_doc_area_component  OUT pk_types.cursor_type,
        o_record_count        OUT NUMBER,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        e_function_call_error EXCEPTION;
        l_function_name CONSTANT VARCHAR2(30) := 'get_doc_area_value';
        l_fltr_start_date TIMESTAMP WITH LOCAL TIME ZONE;
        l_fltr_end_date   TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
        IF i_fltr_start_date_str IS NOT NULL
        THEN
            g_error := 'CALL get_string_tstz (i_fltr_start_date_str)';
            alertlog.pk_alertlog.log_debug(text            => g_error,
                                           object_name     => g_package,
                                           sub_object_name => l_function_name);
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => i_fltr_start_date_str,
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_fltr_start_date,
                                                 o_error     => o_error)
            THEN
                RAISE e_function_call_error;
            END IF;
        END IF;
    
        IF i_fltr_end_date_str IS NOT NULL
        THEN
            g_error := 'CALL get_string_tstz (i_fltr_end_date_str)';
            alertlog.pk_alertlog.log_debug(text            => g_error,
                                           object_name     => g_package,
                                           sub_object_name => l_function_name);
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => i_fltr_end_date_str,
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_fltr_end_date,
                                                 o_error     => o_error)
            THEN
                RAISE e_function_call_error;
            END IF;
        END IF;
    
        RETURN pk_touch_option.get_doc_area_value(i_lang               => i_lang,
                                                  i_prof               => i_prof,
                                                  i_doc_area           => i_doc_area,
                                                  i_current_episode    => i_current_episode,
                                                  i_scope              => i_scope,
                                                  i_scope_type         => i_scope_type,
                                                  i_fltr_status        => i_fltr_status,
                                                  i_order              => i_order,
                                                  i_fltr_start_date    => l_fltr_start_date,
                                                  i_fltr_end_date      => l_fltr_end_date,
                                                  i_paging             => i_paging,
                                                  i_start_record       => i_start_record,
                                                  i_num_records        => i_num_records,
                                                  o_doc_area_register  => o_doc_area_register,
                                                  o_doc_area_val       => o_doc_area_val,
                                                  o_template_layouts   => o_template_layouts,
                                                  o_doc_area_component => o_doc_area_component,
                                                  o_record_count       => o_record_count,
                                                  o_error              => o_error);
    EXCEPTION
        WHEN e_function_call_error THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => o_error.ora_sqlcode,
                                              i_sqlerrm  => o_error.ora_sqlerrm,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_function_name,
                                              o_error    => o_error);
        
            /* Open out cursors */
            pk_types.open_my_cursor(o_doc_area_register);
            pk_types.open_my_cursor(o_doc_area_val);
            pk_types.open_my_cursor(o_template_layouts);
            pk_types.open_my_cursor(o_doc_area_component);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_function_name,
                                              o_error);
            /* Open out cursors */
            pk_types.open_my_cursor(o_doc_area_register);
            pk_types.open_my_cursor(o_doc_area_val);
            pk_types.open_my_cursor(o_template_layouts);
            pk_types.open_my_cursor(o_doc_area_component);
            pk_alert_exceptions.reset_error_state();
        
            RETURN FALSE;
    END get_doc_area_value;

    /**
    * Returns the content of a set of Touch-option documentation entries      
    *                                                                                 
    * @param i_lang                   Language ID                                     
    * @param i_prof                   Profissional ID                                 
    * @param i_id_episode             Episode ID        
    * @param i_id_patient             Patient ID
    * @param i_epis_doc               Table number with id_epis_documentation        
    * @param i_order                  Order of records returned ('ASC' Ascending , 'DESC' Descending)        
    * @param o_doc_area_register      Cursor with the doc area info register        
    * @param o_doc_area_val           Cursor containing the completed info for episode        
    * @param o_template_layouts       Cursor containing the layout for each template used        
    * @param o_doc_area_component     Cursor containing the components for each template used        
    * @param o_error                  Error message        
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.1.8.1
    * @since   5/15/2013
    */
    FUNCTION get_doc_area_value_internal
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_patient         IN patient.id_patient%TYPE,
        i_epis_doc           IN table_number,
        i_order              IN VARCHAR2 DEFAULT 'DESC',
        o_doc_area_register  OUT NOCOPY pk_types.cursor_type,
        o_doc_area_val       OUT NOCOPY pk_types.cursor_type,
        o_template_layouts   OUT NOCOPY pk_types.cursor_type,
        o_doc_area_component OUT NOCOPY pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_doc_area_value_internal';
    BEGIN
    
        RETURN pk_touch_option.get_doc_area_value_internal(i_lang               => i_lang,
                                                           i_prof               => i_prof,
                                                           i_id_episode         => i_id_episode,
                                                           i_id_patient         => i_id_patient,
                                                           i_doc_area           => NULL,
                                                           i_epis_doc           => i_epis_doc,
                                                           i_epis_anamn         => table_number(),
                                                           i_epis_rev_sys       => table_number(),
                                                           i_epis_obs           => table_number(),
                                                           i_epis_past_fsh      => table_number(),
                                                           i_epis_recomend      => table_number(),
                                                           i_flg_show_fm        => pk_alert_constant.g_no,
                                                           i_order              => i_order,
                                                           o_doc_area_register  => o_doc_area_register,
                                                           o_doc_area_val       => o_doc_area_val,
                                                           o_template_layouts   => o_template_layouts,
                                                           o_doc_area_component => o_doc_area_component,
                                                           o_error              => o_error);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_doc_area_register);
            pk_types.open_my_cursor(o_doc_area_val);
            pk_types.open_my_cursor(o_template_layouts);
            pk_types.open_my_cursor(o_doc_area_component);
            RETURN FALSE;
    END get_doc_area_value_internal;

    /**
    * Get the ID of last active Touch-option entry documented in an area and scope using a specific template (optional)
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_scope              Scope ID (Episode ID; Visit ID; Patient ID)
    * @param   i_scope_type         Scope type (by episode; by visit; by patient)
    * @param   i_doc_area           Documentation area ID
    * @param   i_doc_template       Touch-option template ID (Optional) Null = All templates
    * @param   o_last_epis_doc      Last documentation ID 
    * @param   o_last_date_epis_doc Date of last epis documentation
    * @param   o_error              Error information
    *
    * @return  True or False on success or error
    *
    * @catches 
    * @throws  
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.1.8.1
    * @since   5/15/2013
    */
    FUNCTION get_last_doc_area
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_scope              IN NUMBER,
        i_scope_type         IN VARCHAR2 DEFAULT 'E',
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        i_doc_template       IN doc_template.id_doc_template%TYPE DEFAULT NULL,
        o_last_epis_doc      OUT epis_documentation.id_epis_documentation%TYPE,
        o_last_date_epis_doc OUT epis_documentation.dt_creation_tstz%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_last_doc_area';
    BEGIN
    
        RETURN pk_touch_option_core.get_last_doc_area(i_lang               => i_lang,
                                                      i_prof               => i_prof,
                                                      i_scope              => i_scope,
                                                      i_scope_type         => i_scope_type,
                                                      i_doc_area           => i_doc_area,
                                                      i_doc_template       => i_doc_template,
                                                      o_last_epis_doc      => o_last_epis_doc,
                                                      o_last_date_epis_doc => o_last_date_epis_doc,
                                                      o_error              => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_last_doc_area;

    /**
    * Returns a documented element value in raw format according with the type of element:
    *         Date element: Returns a string that represents the date value at institution timezone
    *         Numeric elements: check if has an unit of measure related and then concatenate value with UOM ID
    *         Numeric elements with reference values: verifies that it has properties, then concatenate them
    *         Vital sign elements:  related id_vital_sign_read(s) saved in value_properties field are returned
    *
    * @param i_lang                   Language ID                                                                                              
    * @param i_prof                   Professional, software and institution ids                                                                                                                                          
    * @param i_doc_element_crit       Element criteria ID
    * @param i_epis_documentation     The documentation episode id
    * @param o_element_value          A string with the element value in raw format 
    * @param   o_error                Error information    
    *
    * @return  True or False on success or error
    *    
    * @author  ARIEL.MACHADO
    * @version 2.6.3.7.2
    * @since   27-08-2013
    */
    FUNCTION get_unformatted_value
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_doc_element_crit   IN doc_element_crit.id_doc_element_crit%TYPE,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        o_element_value      OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_unformatted_value';
    BEGIN
        o_element_value := pk_touch_option_core.get_unformatted_value(i_lang               => i_lang,
                                                                      i_prof               => i_prof,
                                                                      i_doc_element_crit   => i_doc_element_crit,
                                                                      i_epis_documentation => i_epis_documentation);
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_unformatted_value;

    /**
    * Get epis documentation flg printed
    *
    * @param i_lang                   Language ID                                     
    * @param i_prof                   Profissional ID                                 
    * @param i_id_epis_doc            the documentation episode id
    *  
    * @return o_flg_printed           from epis_documentation
    *                                                                                 
    * @author                         Ana Moita                                   
    * @version                        2.8.0                                        
    * @since                          2019/08/22
    */
    FUNCTION get_epis_doc_flg_printed
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_epis_doc IN epis_documentation.id_epis_documentation%TYPE,
        o_flg_printed OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN VARCHAR2 IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'GET_EPIS_DOC_FLG_PRINTED';
    BEGIN
        RETURN pk_touch_option.get_epis_doc_flg_printed(i_lang        => i_lang,
                                                        i_prof        => i_prof,
                                                        i_id_epis_doc => i_id_epis_doc,
                                                        o_flg_printed => o_flg_printed,
                                                        o_error       => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            RETURN NULL;
    END get_epis_doc_flg_printed;

    /**
    * Set epis documentation flg printed
    *
    * @param i_lang                   Language ID                                     
    * @param i_prof                   Profissional ID                                 
    * @param i_id_epis_doc            the documentation episode id
    *
    * @return                         Returns boolean    
    *                                                                               
    * @author                         Ana Moita                                   
    * @version                        2.8.0                                        
    * @since                          2019/08/22
    */
    FUNCTION set_epis_doc_flg_printed
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_epis_doc IN epis_documentation.id_epis_documentation%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'SET_EPIS_DOC_FLG_PRINTED';
    BEGIN
        IF NOT pk_touch_option.set_epis_doc_flg_printed(i_lang        => i_lang,
                                                        i_prof        => i_prof,
                                                        i_id_epis_doc => i_id_epis_doc,
                                                        o_error       => o_error)
        THEN
            RETURN FALSE;
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
                                              i_function => k_function_name,
                                              o_error    => o_error);
        
    END set_epis_doc_flg_printed;

BEGIN
    -- Initialization

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_touch_option_api_rep;
/
