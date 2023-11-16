/*-- Last Change Revision: $Rev: 2028497 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:09 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_api_summary_page IS

    -- Author  : ARIEL.MACHADO
    -- Created : 16-Feb-09 3:24:04 PM
    -- Purpose : API for INTER_ALERT

    SUBTYPE t_rec_doc_area_register IS pk_touch_option.t_rec_doc_area_register;
    SUBTYPE t_coll_doc_area_register IS pk_touch_option.t_coll_doc_area_register;
    SUBTYPE t_cur_doc_area_register IS pk_touch_option.t_cur_doc_area_register;
    SUBTYPE t_rec_doc_area_val IS pk_touch_option.t_rec_doc_area_val;
    SUBTYPE t_coll_doc_area_val IS pk_touch_option.t_coll_doc_area_val;
    SUBTYPE t_cur_doc_area_val IS pk_touch_option.t_cur_doc_area_val;
    SUBTYPE t_rec_doc_scales IS pk_scales_core.t_rec_doc_scales;
    SUBTYPE t_coll_doc_scales IS pk_scales_core.t_coll_doc_scales;

    /********************************************************************************************
    *  Returns the values for the Barthel Index evaluation.
    *
    * @param i_lang                    language id
    * @param i_prof                    professional, software and institution ids
    * @param i_id_episode              the episode id
    * @param o_doc_area_register       Cursor with the doc area info register
    * @param o_doc_area_val            Cursor containing the completed info for episode
    * @param o_doc_scales              Cursor containing the association between documentation elements and scale values    
    * @param o_error                   Error info
    * @return                          true (sucess), false (error)
    *
    * @author                          Ariel Machado
    * @version                         2.4.3.20
    * @since                           17-02-2009
    *
    * Changes:
    *
    * @author                          Ariel Machado 
    * @version                         2.5                    
    * @since                           02-04-2009
    * reason                           o_error_out as error type
    **********************************************************************************************/
    FUNCTION intf_get_evaluation_barthel
    (
        i_lang              IN NUMBER,
        i_prof              IN profissional,
        i_id_episode        IN NUMBER,
        o_doc_area_register OUT pk_types.cursor_type,
        o_doc_area_val      OUT pk_types.cursor_type,
        o_doc_scales        OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns physical exam information about episode
    *
    * @param i_lang                      Language ID
    * @param i_prof                      Current profissional
    * @param i_episode                   Episode ID
    * @param o_doc_area_register         Cursor with the doc area info register
    * @param o_doc_area_val              Cursor containing the completed info for episode
    * @param o_doc_area_component        Cursor containing the components for each template used                        
    * @param o_error                     Error message
    * @return                            True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.5.0.7.6
    * @since   19-Jan-10
    **********************************************************************************************/
    FUNCTION intf_get_physical_exam
    (
        i_lang               IN NUMBER,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        o_doc_area_register  OUT pk_types.cursor_type,
        o_doc_area_val       OUT pk_types.cursor_type,
        o_doc_area_component OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns history of the present illness about episode
    *
    * @param i_lang                      Language ID
    * @param i_prof                      Current profissional
    * @param i_episode                   Episode ID
    * @param o_doc_area_register         Cursor with the doc area info register
    * @param o_doc_area_val              Cursor containing the completed info for episode
    * @param o_doc_area_component        Cursor containing the components for each template used                        
    * @param o_error                     Error message
    * @return                            True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.5.0.7.6
    * @since   19-Jan-10
    **********************************************************************************************/
    FUNCTION intf_get_hist_present_illness
    (
        i_lang               IN NUMBER,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        o_doc_area_register  OUT pk_types.cursor_type,
        o_doc_area_val       OUT pk_types.cursor_type,
        o_doc_area_component OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns a set of records done in a touch-option area based on filters criteria and with paging support
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_doc_area           Documentation area ID
    * @param   i_current_episode    Current episode ID
    * @param   i_scope              Scope ID (Episode ID; Visit ID; Patient ID)
    * @param   i_scope_type         Scope type (by episode; by visit; by patient). Default g_scope_type_episode
    * @param   i_fltr_status        A sequence of flags representing the status that records must comply ('A' Active, 'O' Outdated, 'C' Cancelled) Default 'AOC'
    * @param   i_order              Indicates the chronological order of records returned ('ASC' Ascending , 'DESC' Descending) Default 'DESC'
    * @param   i_fltr_start_date    Begin date (optional)        
    * @param   i_fltr_end_date      End date (optional)        
    * @param   i_paging             Use paging ('Y' Yes; 'N' No) Default 'N'
    * @param   i_start_record       First record. Just considered when paging is used. Default 1
    * @param   i_num_records        Number of records to be retrieved. Just considered when paging is used.  Default 2000
    * @param   o_doc_area_register  Cursor with the doc area info register
    * @param   o_doc_area_val       Cursor containing the completed info for episode
    * @param   o_template_layouts   Cursor containing the layout for each template used
    * @param   o_doc_area_component Cursor containing the components for each template used 
    * @param   o_record_count       Indicates the number of records that match filters criteria
    * @param   o_error              Error message 
    *
    * @value i_scope_type {*} g_scope_type_patient Patient('P') {*} g_scope_type_visit Visit('V') {*} g_scope_type_episode Episode('E')
    * @value i_fltr_status {*} g_active Active('A') {*} g_outdated Outdated('O') {*} g_cancelled Cancelled('C')
    * @value i_order {*} g_order_ascending Ascending('ASC') {*} g_order_descending Descending('DESC')
    * @value i_paging {*} g_yes Yes('Y') {*} g_no No('N')
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.1.2
    * @since   27-06-2011
    */
    FUNCTION intf_get_doc_area_value
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        i_current_episode    IN episode.id_episode%TYPE,
        i_scope              IN NUMBER,
        i_scope_type         IN VARCHAR2 DEFAULT pk_alert_constant.g_scope_type_episode,
        i_fltr_status        IN VARCHAR2 DEFAULT pk_alert_constant.g_active || pk_alert_constant.g_outdated ||
                                                 pk_alert_constant.g_cancelled,
        i_order              IN VARCHAR2 DEFAULT pk_alert_constant.g_order_descending,
        i_fltr_start_date    IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_fltr_end_date      IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_paging             IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_start_record       IN NUMBER DEFAULT 1,
        i_num_records        IN NUMBER DEFAULT 2000,
        o_doc_area_register  OUT t_cur_doc_area_register,
        o_doc_area_val       OUT t_cur_doc_area_val,
        o_template_layouts   OUT pk_types.cursor_type,
        o_doc_area_component OUT pk_types.cursor_type,
        o_record_count       OUT NUMBER,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

END pk_api_summary_page;
/
