/*-- Last Change Revision: $Rev: 2029016 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:18 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_touch_option_api_rep IS

    -- Author  : ARIEL.MACHADO
    -- Created : 06-10-2011 11:14:05
    -- Purpose : Touch-option API used by Reports

    -- Public type declarations

    -- Public constant declarations

    -- Public variable declarations

    -- Public function and procedure declarations
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
    ) RETURN BOOLEAN;

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
    * @version 2.6.3.5
    * @since   5/16/2013
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
    ) RETURN BOOLEAN;

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
    * @version 2.6.3.5
    * @since   5/16/2013
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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN VARCHAR2;
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
    ) RETURN BOOLEAN;
END pk_touch_option_api_rep;
/
