/*-- Last Change Revision: $Rev: 2028971 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:02 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_sev_scores_api_ui IS

    -- Author  : JOSE.SILVA
    -- Created : 07-09-2010 16:55:00
    -- Purpose : Severity scores functionality (UI API)

    /**
    * Returns all scores to be listed in the summary page
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_patient      Patient ID
    * @param   i_id_episode   Episode ID
    *
    * @param   o_scores       Scores list
    *
    * @param   o_error        Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  JOSE.SILVA
    * @version 2.6.0.4
    * @since   07-09-2010
    */
    FUNCTION get_sev_scores_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        o_flg_show   OUT VARCHAR2,
        o_msg_title  OUT VARCHAR2,
        o_msg        OUT VARCHAR2,
        o_button     OUT VARCHAR2,
        o_scores     OUT pk_sev_scores_core.p_sev_scores_param_cur,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns all scores registered in a given episode
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_id_patient   Patient ID
    * @param   i_id_episode   Episode ID
    *
    * @param   o_reg          Records general information
    * @param   o_groups       List of groups inside the score records
    * @param   o_values       Score values
    *
    * @param   o_error        Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  JOSE.SILVA
    * @version 2.6.0.4
    * @since   09-09-2010
    */
    FUNCTION get_sev_scores_values
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        o_reg        OUT pk_types.cursor_type,
        o_groups     OUT pk_types.cursor_type,
        o_values     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Shows all parameters for a specific score.
    * Returns the parameters properties and current value.
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                Episode ID 
    * @param i_mtos_score             Severity score ID 
    * @param i_epis_mtos_score        Severity score evaluation ID
    * @param o_list                   Parameter list
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                         Tércio Soares
    * @version                        2.6.0.4
    * @since                          2010/09/16
    **********************************************************************************************/
    FUNCTION get_sev_score_param_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_mtos_score      IN mtos_score.id_mtos_score%TYPE,
        i_epis_mtos_score IN epis_mtos_score.id_epis_mtos_score%TYPE,
        o_list            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the history of score evaluation for the current episode. Results shown in the detail screen.
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_id_episode         Episode ID
    * @param i_epis_mtos_score    Severity score evaluation ID
    * @param o_reg                Cursor with the score
    * @param o_value              Cursor with the parameters and registered values
    * @param o_cancel             Cursor with the cencelled registered data
    * @param o_error              Error message
    *                        
    * @return                     true or false on success or error
    *
    * @author                     Tércio Soares
    * @version                    2.6.0.4
    * @since                      2010/09/22
    **********************************************************************************************/
    FUNCTION get_sev_score_detail
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_epis_mtos_score IN epis_mtos_score.id_epis_mtos_score%TYPE,
        o_reg             OUT pk_types.cursor_type,
        o_value           OUT pk_types.cursor_type,
        o_cancel          OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Cancelation of a score evaluation for the current episode.
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_id_episode         Episode ID
    * @param i_epis_mtos_score    Severity score evaluation ID
    * @param id_cancel_reason     Cancel reason ID
    * @param notes_cancel         Cancel notes
    * @param o_error              Error message
    *                        
    * @return                     true or false on success or error
    *
    * @author                     Tércio Soares
    * @version                    2.6.0.4
    * @since                      2010/09/22
    **********************************************************************************************/
    FUNCTION cancel_sev_score
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_epis_mtos_score IN epis_mtos_score.id_epis_mtos_score%TYPE,
        id_cancel_reason  IN epis_mtos_score.id_cancel_reason%TYPE,
        notes_cancel      IN epis_mtos_score.notes_cancel%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the score groups to fill. Used by Flash to know how many blocks must be shown, 
    * one block for each group.
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_id_episode         Episode ID for each parameter
    * @param i_mtos_score         Score ID
    * @param o_score              Cursor with the available score groups
    * @param o_error              Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            Tércio Soares
    * @version           2.6.0.4
    * @since             2010/09/23
    **********************************************************************************************/
    FUNCTION get_sev_score
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_mtos_score IN mtos_score.id_mtos_score%TYPE,
        o_score      OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the score groups to fill. Used by Flash to know how many blocks must be shown, 
    * one block for each group.
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_id_episode         Episode ID for each parameter
    * @param i_mtos_score         Score ID
    * @param i_epis_mtos_score    Severity score evaluation ID
    * @param o_score              Cursor with the available score groups
    * @param o_error              Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            Tércio Soares
    * @version           2.6.0.4
    * @since             2010/09/23
    **********************************************************************************************/
    FUNCTION get_sev_score
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_mtos_score      IN mtos_score.id_mtos_score%TYPE,
        i_epis_mtos_score IN epis_mtos_score.id_epis_mtos_score%TYPE,
        o_score           OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Saves a score evaluation and all the registered values.
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_prof_cat           Professional category
    * @param i_id_episode         Episode ID
    * @param i_id_patient         Patient ID
    * @param i_sev_score          Severity score ID 
    * @param i_epis_mtos_score    Severity score evaluation ID
    * @param i_id_mtos_param      Array of parameter ID's
    * @param i_value              Array with the registered values
    * @param i_unit_measure       Array with unit measures
    * @param o_flg_detail         Activate the DETAIL button: (Y)es (N)o
    * @param o_error              Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            Tércio Soares
    * @version           2.6.0.4 
    * @since             2010/09/28
    **********************************************************************************************/
    FUNCTION set_sev_score
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_prof_cat           IN category.flg_type%TYPE,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_patient         IN patient.id_patient%TYPE,
        i_sev_score          IN mtos_score.id_mtos_score%TYPE,
        i_epis_mtos_score    IN epis_mtos_score.id_epis_mtos_score%TYPE,
        i_id_mtos_param      IN table_number,
        i_value              IN table_number,
        i_notes              IN table_clob,
        i_unit_measure       IN table_number,
        i_vs_scales_elements IN table_number,
        o_flg_detail         OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Saves a score evaluation for scales with multiples values for each parameter
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_prof_cat           Professional category
    * @param i_id_episode         Episode ID
    * @param i_id_patient         Patient ID
    * @param i_sev_score          Severity score ID 
    * @param i_epis_mtos_score    Severity score evaluation ID
    * @param i_id_mtos_param      Array of parameter ID's
    * @param i_value              Array with arrays of registered values
    * @param i_unit_measure       Array with unit measures
    * @param i_vs_scales_elements Array with vital signs   
    * @param o_flg_detail         Activate the DETAIL button: (Y)es (N)o
    * @param o_error              Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    **********************************************************************************************/
    FUNCTION set_sev_score_ms
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_prof_cat           IN category.flg_type%TYPE,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_patient         IN patient.id_patient%TYPE,
        i_sev_score          IN mtos_score.id_mtos_score%TYPE,
        i_epis_mtos_score    IN epis_mtos_score.id_epis_mtos_score%TYPE,
        i_id_mtos_param      IN table_number,
        i_value              IN table_table_number,
        i_notes              IN table_clob,
        i_unit_measure       IN table_number,
        i_vs_scales_elements IN table_number,
        o_flg_detail         OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the severity score content help. Used by Flash to shown the content help (including the group help if applicable).
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_id_episode         Episode ID for each parameter
    * @param i_mtos_score         Score ID
    * @param i_mtos_score_group   Severity score group ID
    * @param i_flg_context        Context to show score help (L - scores list screen, E - score edition screen)
    * @param o_score_help         Severity score help
    * @param o_score_group_help   Severity score group help
    * @param o_error              Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            Tércio Soares
    * @version           2.6.0.4
    * @since             2010/09/29
    **********************************************************************************************/
    FUNCTION get_sev_score_help
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        i_mtos_score       IN mtos_score.id_mtos_score%TYPE,
        i_mtos_score_group IN mtos_score_group.id_mtos_score_group%TYPE,
        i_flg_context      IN VARCHAR2,
        o_score_help       OUT CLOB,
        o_score_group_help OUT CLOB,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the total value for a given score.
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_id_patient         Patient ID
    * @param i_id_mtos_param      ID's of the score parameters
    * @param i_value              Registered values for each parameter
    * @param i_flg_score_type     Type of score
    * @param o_total              Cursor with the results
    * @param o_error              Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            José Brito
    * @version           1.0  
    * @since             2009/07/08
    **********************************************************************************************/
    FUNCTION get_total_score
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_id_mtos_param      IN table_number,
        i_value              IN table_number,
        i_flg_score_type     IN mtos_score.flg_score_type%TYPE,
        i_id_mtos_score      IN mtos_score.id_mtos_score%TYPE DEFAULT NULL,
        i_vs_scales_elements IN table_number,
        o_total              OUT pk_types.cursor_type,
        o_viewer             OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the total value for a given score which allows 
    * multiple selection of values for a given parameter
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_id_patient         Patient ID
    * @param i_id_mtos_param      Array of ID's of the score parameters
    * @param i_value              Array of Arrays of the registered values for each parameter
    * @param i_flg_score_type     Type of score
    * @param o_total              Cursor with the results
    * @param o_error              Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    **********************************************************************************************/
    FUNCTION get_total_score_ms
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_id_mtos_param      IN table_number,
        i_value              IN table_table_number,
        i_flg_score_type     IN mtos_score.flg_score_type%TYPE,
        i_id_mtos_score      IN mtos_score.id_mtos_score%TYPE DEFAULT NULL,
        i_vs_scales_elements IN table_number,
        o_total              OUT pk_types.cursor_type,
        o_viewer             OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    /**********************************************************************************************
    * Returns the options for the parameters filled by multichoice.
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_id_mtos_param      Parameter ID
    * @param i_flg_score_type     Type of score
    * @param i_id_patient         Patient ID
    * @param o_list               Cursor with the results
    * @param o_error              Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            José Brito
    * @version           1.0  
    * @since             2009/07/08
    **********************************************************************************************/
    FUNCTION get_param_options
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_mtos_param  IN mtos_param.id_mtos_param%TYPE,
        i_flg_score_type IN mtos_score.flg_score_type%TYPE,
        i_id_patient     IN patient.id_patient%TYPE,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns to PDMS all scores registered in a given visit
    *
    * @param   i_lang              Professional preferred language
    * @param   i_prof              Professional identification and its context (institution and software)
    * @param   i_id_visit          Visit ID
    * @param   i_dt_begin          Begin date
    * @param   i_dt_end            End date
    * @param   o_sev_scoress       Severity scores
    * @param   o_error             Error information
    *
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            Tércio Soares
    * @version           2.6.0.5
    * @since             2010/12/17
    **********************************************************************************************/
    FUNCTION get_sev_scores_pdms
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_visit    IN visit.id_visit%TYPE,
        i_dt_begin    IN VARCHAR2,
        i_dt_end      IN VARCHAR2,
        o_sev_scoress OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get severity score add edit screen
    *
    * @param       i_lang                   preferred language id for this professional
    * @param       i_prof                   professional type
    * @param       i_id_mtos_score          Severity score Id
    * @param       o_screen                 Add/edit screen name 
    * @param       o_error                  error message
    *
    * @return      boolean                  true on success, otherwise false
    *
    * @author                               Sofia Mendes
    * @version                              2.6.2
    * @since                                31-May-2013
    **********************************************************************************************/
    FUNCTION get_sev_score_screen
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_mtos_score IN mtos_score.id_mtos_score%TYPE,
        o_screen        OUT mtos_score.screen_name%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    ============================================================================================================================
    =============================== ALERT-255254 - NEWS AND PEWS ==============================================================
    ============================================================================================================================
        **********************************************************************************************/
    /********************************************************************************************
    * 
    * Get Severity Scores to show on a viewer
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_mtos_score             Severity score ID 
    * @param i_epis_mtos_score        Severity score evaluation ID
    * @param o_list                   Parameter list
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                         Mário Mineiro
    * @version                        2.6.3.7
    * @since                          19/07/2013
    **********************************************************************************************/
    FUNCTION get_sev_score_viewer
    
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_mtos_score      IN mtos_score.id_mtos_score%TYPE,
        i_epis_mtos_score IN epis_mtos_param.id_epis_mtos_score%TYPE DEFAULT NULL,
        o_viewer          OUT pk_types.cursor_type,
        o_title           OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_sev_score_plus
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_sev_scores_ais
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_mtos_score IN mtos_score.id_mtos_score%TYPE,
        o_list          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_sev_scores_minor
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_mtos_param IN mtos_param.id_mtos_param%TYPE,
        o_list          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_modified_total_score
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_mtos_score IN table_number,
        i_id_mtos_param IN table_number,
        i_extra_score   IN table_varchar,
        o_total         OUT NUMBER,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_modified_score
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_patient         IN patient.id_patient%TYPE,
        i_epis_mtos_score    IN epis_mtos_score.id_epis_mtos_score%TYPE,
        i_id_mtos_score      IN table_number,
        i_id_mtos_param      IN table_number,
        i_extra_score        IN table_varchar,
        i_flg_api            IN VARCHAR2 DEFAULT 'N',
        o_id_epis_mtos_score OUT epis_mtos_score.id_epis_mtos_score%TYPE,
        o_msg_error          OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_modified_score
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_patient      IN patient.id_patient%TYPE,
        i_epis_mtos_score IN epis_mtos_score.id_epis_mtos_score%TYPE,
        o_mtos_score      OUT pk_types.cursor_type,
        o_total_score     OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

END pk_sev_scores_api_ui;
/
