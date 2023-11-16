/*-- Last Change Revision: $Rev: 2028941 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:52 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_scales_api IS

    -- Author  : SOFIA.MENDES
    -- Created : 7/21/2011 8:33:38 AM
    -- Purpose : This package contains the API functions of the assessment tools functionality

    /**
    * Rebuild the grid task assessment tools values.
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_doc_area                   Doc_area id         
    * @param   o_error                      Error message
    *
    * @return  True or False on success or error
    *
    * @author  Sofia Mendes
    * @version 2.6.1.2
    * @since   08-Jul-2011
    */
    FUNCTION rebuild_grid_task
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_doc_area IN doc_area.id_doc_area%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Rebuild the grid task assessment tools values.
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_doc_area                   Doc_area id     
    * @param   o_epis_documentation         The epis_documentation ID created
    * @param   o_error                      Error message
    *
    * @return  True or False on success or error
    *
    * @author  Sofia Mendes
    * @version 2.6.1.2
    * @since   08-Jul-2011
    */
    FUNCTION set_grids_assessment_tool
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        i_doc_area       IN doc_area.id_doc_area%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns the info registered in the documentation regarding a patient, an episode or an visit.
    * For a patient scope: i_flg_scope = P and i_scope regards to id_patient
    * For a visit scope: i_flg_scope = V and i_scope regards to id_visit
    * For an episode scope: i_flg_scope = E and i_scope regards to id_episode    
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_doc_area               the doc area ID
    * @param i_episode                the episode ID
    * @param i_scope                  Scope ID (Episode ID; Visit ID; Patient ID)
    * @param i_scope_type             Scope type (by episode; by visit; by patient)
    * @param o_scales_list            Cursor with the scales info register
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Sofia Mendes
    * @version                        2.6.0.5
    * @since                          06-Jan-2010
    **********************************************************************************************/
    FUNCTION get_scales_list
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_doc_area    IN NUMBER,
        i_scope       IN NUMBER,
        i_scope_type  IN VARCHAR2 DEFAULT 'E',
        o_scales_list OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Devolve toda a informação registada na Documentation para um paciente, relativamente às escalas
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_doc_area               the doc area ID
    * @param i_episode                the episode ID
    * @param o_scales_list            Cursor with the scales info register
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Luís Maia
    * @version                        1.0
    * @since                          2008/10/27
    **********************************************************************************************/
    FUNCTION get_scales_list_pat
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_doc_area    IN NUMBER,
        i_id_episode  IN NUMBER,
        o_scales_list OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *  Get the documented assessment scales description "Title: score"
    *
    * @param i_lang                     Language identifier
    * @param i_prof                     Professional
    * @param i_episode                  Episode Id
    * @param i_id_scales                Scales Id
    * @param o_ass_scales               Cursor with description in the format: "Title: score"
    * @param o_error                    Error
    *
    * @return                          true (sucess), false (error)
    *
    * @author                          Nuno Alves
    * @version                         2.6.3.8.2
    * @since                           27-04-2015
    **********************************************************************************************/
    FUNCTION get_epis_ass_scales_scores
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_tbl_episode     IN table_number,
        i_show_all_scores IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_ass_scales      OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    g_exception EXCEPTION;

END pk_scales_api;
/
