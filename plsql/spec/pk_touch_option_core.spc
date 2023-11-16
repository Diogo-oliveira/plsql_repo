/*-- Last Change Revision: $Rev: 1946744 $*/
/*-- Last Change by: $Author: ana.moita $*/
/*-- Date of last change: $Date: 2020-04-22 16:42:56 +0100 (qua, 22 abr 2020) $*/
CREATE OR REPLACE PACKAGE pk_touch_option_core IS
    -- Author  : ARIEL.MACHADO
    -- Created : 31-01-2012 11:27:46
    -- Purpose : Touch-option framework: Core methods 

    -- Exceptions

    -- An invalid parameter is passed to a method that resolves a bind variable value.
    e_invalid_parameter EXCEPTION;

    -- Error trying to resolve bind variable value.
    e_bind_resolution_error EXCEPTION;

    -- The call to a internal function returned an error.
    e_function_call_error EXCEPTION;

    -- Public type declarations
    TYPE t_rec_doc_area IS RECORD(
        id_doc_area doc_area.id_doc_area%TYPE);
    TYPE t_coll_doc_area IS TABLE OF t_rec_doc_area;
    TYPE t_cur_doc_area IS REF CURSOR RETURN t_rec_doc_area;

    TYPE t_rec_doc_template IS RECORD(
        id_doc_template   doc_template.id_doc_template%TYPE,
        code_doc_template doc_template.code_doc_template%TYPE);
    TYPE t_coll_doc_template IS TABLE OF t_rec_doc_template;
    TYPE t_cur_doc_template IS REF CURSOR RETURN t_rec_doc_template;

    TYPE t_rec_epis_edition_log IS RECORD(
        id_epis_documentation        epis_documentation.id_epis_documentation%TYPE,
        id_epis_documentation_parent epis_documentation.id_epis_documentation_parent%TYPE,
        flg_status                   epis_documentation.flg_status%TYPE,
        flg_edition_type             epis_documentation.flg_edition_type%TYPE,
        dt_creation_tstz             epis_documentation.dt_creation_tstz%TYPE);
    TYPE t_coll_epis_edition_log IS TABLE OF t_rec_epis_edition_log;

    TYPE t_rec_plain_text_entry IS RECORD(
        id_epis_documentation epis_documentation.id_epis_documentation%TYPE,
        dt_creation_tstz      epis_documentation.dt_creation_tstz%TYPE,
        template_title        pk_translation.t_desc_translation,
        plain_text_entry      CLOB,
        area_name             pk_translation.t_desc_translation);
    TYPE t_coll_plain_text_entry IS TABLE OF t_rec_plain_text_entry;
    TYPE t_cur_plain_text_entry IS REF CURSOR RETURN t_rec_plain_text_entry;

    -- Public constant declarations

    -- Public variable declarations

    -- Public function and procedure declarations
    /********************************************************************************************
     * Returns the templates for an area
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_professional           Profissional ID
     * @param i_institution            Institution ID
     * @param i_software               Id of the software to get areas
     * @param i_doc_area               Id of the area to get templates
     *
     * @return                         true or false on success or error
     *
     * @author                         Daniel Ferreira
     * @version                        2.6.2
     * @since                          2012/01/19
    **********************************************************************************************/
    FUNCTION tf_doc_templates
    (
        i_lang         IN language.id_language%TYPE,
        i_professional IN professional.id_professional%TYPE,
        i_institution  IN institution.id_institution%TYPE,
        i_software     IN software.id_software%TYPE,
        i_doc_area     IN doc_area.id_doc_area%TYPE,
        i_doc_template IN table_number DEFAULT NULL
    ) RETURN t_coll_doc_template
        PIPELINED;

    /********************************************************************************************
    * Returns the areas for a product
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_professional           Profissional ID
    * @param i_institution            Institution ID
    * @param i_software               Id of the software to get areas
    * @param i_prof_profile_template  Profile ID used by i_professional for the i_software. NULL: the profile will be retrieved according the input parameters.
    * @param i_inst_market            Market ID of i_institution. NULL the market will be retrieved according the input parameter.
    * @param i_check_template_exists  Ensure that the areas have templates. If an area has no templates then is not included in the output.    
    *
    * @return                         true or false on success or error
    *
    * @author                         Daniel Ferreira
    * @version                        2.6.2
    * @since                          2012/01/19
    **********************************************************************************************/
    FUNCTION tf_doc_areas
    (
        i_lang                  IN language.id_language%TYPE,
        i_professional          IN professional.id_professional%TYPE,
        i_institution           IN institution.id_institution%TYPE,
        i_software              IN software.id_software%TYPE,
        i_prof_profile_template IN profile_template.id_profile_template%TYPE DEFAULT NULL,
        i_inst_market           IN market.id_market%TYPE DEFAULT NULL,
        i_check_template_exists IN VARCHAR2 DEFAULT pk_alert_constant.g_yes
    ) RETURN t_coll_doc_area
        PIPELINED;

    /**
    * Check if the template remains available to be used by this professional
    *
    * @param   i_lang           Professional preferred language
    * @param   i_prof           Professional identification and its context (institution and software)
    * @param   i_doc_area       Documentation area ID 
    * @param   i_doc_template   Template ID. If Null this function will returns 'Y'.
    *
    * @return  Flag indicating if template is currently available to be used or not.
    *
    * @value return  {*} 'Y' Template is currently available (or  i_doc_template is null) {*} 'N' The template is not available 
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.2.1
    * @since   31-01-2012
    */
    FUNCTION check_can_use_template
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_doc_area     IN doc_area.id_doc_area%TYPE,
        i_doc_template IN doc_template.id_doc_template%TYPE
    ) RETURN VARCHAR2;

    /**
    * Procedure that resolves bind variables required for the filter TOTPreviousRecords
    *
    * @param i_context_ids  Static contexts (i_prof, i_lang, i_episode, i_patient)
    * @param i_context_vals Custom contexts, sent from the user interface
    * @param i_name         Name of the bind variable to get
    * @param  o_vc2         Varchar2 value returned by the procedure
    * @param  o_num         Numeric value returned by the procedure
    * @param  o_id          NUMBER(24) value returned by the procedure
    * @param  o_tstz        Timestamp value returned by the procedure
    *
    * @catches 
    * @throws  e_invalid_parameter If i_context_vals is not initialized or does not include required values as id_doc_area
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.2.1
    * @since   15-02-2012
    */
    PROCEDURE init_fltr_params_prev_records
    (
        i_context_ids  IN table_number,
        i_context_vals IN table_varchar,
        i_name         IN VARCHAR2,
        o_vc2          OUT VARCHAR2,
        o_num          OUT NUMBER,
        o_id           OUT NUMBER,
        o_tstz         OUT TIMESTAMP WITH LOCAL TIME ZONE
    );

    /**
    * Retrieves details about a set of previous records done in a touch-option area 
    *
    * @param   i_lang                Professional preferred language
    * @param   i_prof                Professional identification and its context (institution and software)
    * @param   i_patient             Patient ID 
    * @param   i_episode             Episode ID
    * @param   i_doc_area            Documentation area ID        
    * @param   i_epis_doc            Table number with id_epis_documentation        
    * @param   o_doc_area_register   Cursor with the doc area info register        
    * @param   o_doc_area_val        Cursor containing the completed info for episode        
    * @param   o_template_layouts    Cursor containing the layout for each template used        
    * @param   o_doc_area_component  Cursor containing the components for each template used        
    *
    * @catches 
    * @throws  e_function_call_error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.2.1
    * @since   16-02-2012
    */
    PROCEDURE get_prev_record_detail
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        i_epis_doc           IN table_number,
        o_doc_area_register  OUT NOCOPY pk_touch_option.t_cur_doc_area_register,
        o_doc_area_val       OUT NOCOPY pk_touch_option.t_cur_doc_area_val,
        o_template_layouts   OUT NOCOPY pk_types.cursor_type,
        o_doc_area_component OUT NOCOPY pk_types.cursor_type
    );

    /********************************************************************************************
    * Checks if the elements of a template has translations
    *                                                                                                                                          
    * @param i_lang                   Language ID                                                                                              
    * @param i_prof                   Professional, software and institution ids
    * @param i_doc_area               Doc area
    * @param i_doc_template           Template                                                                                       
    *                                                                                                                                         
    * @return                         {*} 'Y'  Has translations {*} 'N' Has no translations                                                        
    *
    * @author                         Ariel Geraldo Machado                                                                                    
    * @version                         1.0 (2.4.3)                                                                                                     
    * @since                          2008/07/25                                                                                               
    ********************************************************************************************/
    FUNCTION get_template_translated
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_doc_area     IN doc_area.id_doc_area%TYPE,
        i_doc_template IN doc_template.id_doc_template%TYPE
    ) RETURN VARCHAR2;

    /**
    * Returns list of editions done in a documentation entry
    *
    * @param   i_lang                 Professional preferred language
    * @param   i_prof                 Professional identification and its context (institution and software)
    * @param   i_epis_documentation   ID documentation entry 
    *
    * @return  Collection of t_rec_epis_edition_log
    *
    * @catches 
    * @throws  
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.2.1
    * @since   09-03-2012
    */
    FUNCTION get_epis_doc_edition_log
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE
    ) RETURN t_coll_epis_edition_log;

    /**
    * Returns the possible actions for a documentation entry in a touch option area
    *
    * @param   i_lang                  Professional preferred language
    * @param   i_prof                  Professional identification and its context (institution and software)
    * @param   i_epis_documentation    Entry ID
    * @param   i_flg_table_origin      Entry table origin
    * @param   i_flg_write             Write permission
    * @param   i_flg_no_changes        Permission for "No changes" action
    * @param   i_show_disabled_actions Allow invalid actions to be returned, but disabled <FLG_ACTIVE == 'N'>
    * @param   o_actions               Actions information
    *
    * @value   i_flg_table_origin      {*} 'D'  EPIS_DOCUMENTATION {*} 'A'  EPIS_ANAMNESIS {*} 'S'  EPIS_REVIEW_SYSTEMS {*} 'O'  EPIS_OBSERVATION {*} 'R' EPIS_RECOMEND {*} 'F' PAT_FAM_SOC_HIST {*} 'G' EPIS_DIAGNOSIS {*} 'U' SR_SURGERY_RECORD
    * @value   i_flg_write             {*} 'Y'  YES {*} 'N'  NO
    * @value   i_flg_no_changes        {*} 'Y'  YES {*} 'N'  NO
    * @value   i_show_disabled_actions {*} 'Y'  YES {*} 'N'  NO
    * @param   i_nr_record             Number of allowed record 
    *
    * @author  MIGUEL.LEITE
    * @version V2.6.2.1
    * @since   20-03-2012 14:59:41
    */
    PROCEDURE get_entry_actions
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_epis_documentation    IN epis_documentation.id_epis_documentation%TYPE,
        i_flg_table_origin      IN VARCHAR2,
        i_flg_write             IN VARCHAR2,
        i_flg_update            IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_flg_no_changes        IN VARCHAR2 DEFAULT 'N',
        i_show_disabled_actions IN VARCHAR2 DEFAULT 'N',
        i_nr_record             IN NUMBER DEFAULT NULL,
        o_actions               OUT pk_types.cursor_type
    );

    /**
    * Returns the content of a set of Touch-option documentation entries in plain-text format
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_documentation_list   List of id_pis_documentation to retrieve
    * @param   i_use_html_format           Use HTML tags to format output. Default: No
    * @param   o_entries                   Cursor with the content of entries in plain text format
    *
    * @value   i_use_html_format           {*} 'Y'  Use HTML tags {*} 'N'  No HTML tags
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.2.1.3
    * @since   26-06-2012
    */
    PROCEDURE get_plain_text_entries
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_epis_documentation_list IN table_number,
        i_use_html_format         IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_entries                 OUT t_cur_plain_text_entry
    );

    /**
    * Returns the content of a set of Touch-option documentation entry in plain-text format
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_documentation        id_pis_documentation to retrieve
    * @param   i_use_html_format           Use HTML tags to format output. Default: No
    *
    * @return  The content of entry in plain text format
    *
    * @value   i_use_html_format           {*} 'Y'  Use HTML tags {*} 'N'  No HTML tags
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.3.7
    * @since   02-07-2013
    */
    FUNCTION get_plain_text_entry
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_use_html_format    IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN CLOB;

    /**
    * Get the ID of last active Touch-option entry documented in an area and scope using a specific template (optional)
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_scope              Scope ID (Episode ID; Visit ID; Patient ID)
    * @param   i_scope_type         Scope type (by episode; by visit; by patient)
    * @param   i_doc_area           Documentation area ID
    * @param   i_doc_template       Touch-option template ID (Optional) Null = All templates
    * @param   o_last_epis_doc       Last documentation ID 
    * @param   o_last_date_epis_doc  Date of last epis documentation
    * @param   o_error          Error information
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
    *
    * @return  A string with the element value in raw format 
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
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE
    ) RETURN VARCHAR2;
    /**
    * Returns true if a template is bilateral false otherwise
    *
    * @param i_epis_documentation     The documentation episode id
    *
    * @return  Returns true if a template is bilateral false otherwise
    *    
    * @author  ARIEL.MACHADO
    * @version 2.6.4
    * @since   2014-11-05
    */
    FUNCTION has_layout(i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE) RETURN VARCHAR2;
    ---
    /**
    * Returns the id of the professional that created the template
    *
    * @param i_epis_documentation     The documentation episode id
    *
    * @return  Returns id_prof
    *    
    * @author  Paulo Teixeira
    * @version 2.6.5
    * @since   2015-07-15
    */
    FUNCTION get_id_prof_create_ed(i_id_epis_documentation IN epis_documentation.id_epis_documentation%TYPE)
        RETURN epis_documentation.id_professional%TYPE result_cache;
    --
    FUNCTION get_dt_create_ed(i_id_epis_documentation IN epis_documentation.id_epis_documentation%TYPE)
        RETURN epis_documentation.dt_creation_tstz%TYPE result_cache;

    PROCEDURE get_plain_text_entries_type
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_patient            IN patient.id_patient%TYPE,
        i_id_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_id_request            IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_flg_report            IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_entries               OUT pk_types.cursor_type
    );
END pk_touch_option_core;
/
