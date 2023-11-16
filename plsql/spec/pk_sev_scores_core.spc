CREATE OR REPLACE PACKAGE pk_sev_scores_core IS

    -- Author  : JOSE.SILVA
    -- Created : 06-09-2010 16:55:00
    -- Purpose : Severity scores functionality

    TYPE p_sev_scores_param_rec IS RECORD(
        doc_area        mtos_score.id_mtos_score%TYPE,
        translated_code pk_translation.t_desc_translation,
        screen_name     mtos_score.screen_name%TYPE,
        flg_score_type  mtos_score.flg_score_type%TYPE,
        flg_write       mtos_score_soft_inst.flg_write%TYPE,
        height          mtos_score_soft_inst.height%TYPE,
        flg_viewer      mtos_score.flg_viewer%TYPE);

    TYPE p_sev_scores_param_cur IS REF CURSOR RETURN p_sev_scores_param_rec;

    PROCEDURE open_my_cursor(i_cursor IN OUT pk_sev_scores_core.p_sev_scores_param_cur);

    /**********************************************************************************************
    **********************************************************************************************/
    FUNCTION get_epis_mtos_score_patient
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_epis_mtos_score IN epis_mtos_score.id_epis_mtos_score%TYPE
    ) RETURN patient.id_patient%TYPE;

    /**
    * Gets the score description
    *
    * @param   i_lang                  Professional preferred language
    * @param   i_prof                  Professional identification and its context (institution and software)
    * @param   i_id_score              Score id
    * @param   i_code_trans            Code used for score translation
    * @param   i_code_abbrev           Code used for abbreviated translation
    * @param   i_id_score_group        Score group id
    *
    * @return  Score description
    *
    * @author  Jos?Silva
    * @version v2.6.0.3
    * @since   07-09-2010
    */
    FUNCTION get_desc_score
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_score       IN mtos_score.id_mtos_score%TYPE,
        i_code_trans     IN mtos_score.code_mtos_score%TYPE DEFAULT NULL,
        i_code_abbrev    IN mtos_score.code_mtos_score_abbrev%TYPE DEFAULT NULL,
        i_id_score_group IN mtos_score_group.id_mtos_score_group%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Check if episode has any saved score in EPIS_MTOS_SCORE.
    * If so, the DETAIL button is activated.
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_id_episode         Episode ID
    * @param o_flg_detail         (Y) Activate detail button  (N) Inactivate
    * @param o_error              Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            Jos?Brito
    * @version           1.0  
    * @since             2009/07/08
    **********************************************************************************************/
    FUNCTION check_flg_detail
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_flg_detail OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Formats a given total value according to the rules of the specified score in 'internal_name'.
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_value              Score value
    * @param i_internal_name      Score internal name
    * @param i_epis_mtos_score    Score evaluation id
    *                        
    * @return            Formatted string
    *
    * @author            Jos?Brito
    * @version           1.0  
    * @since             2009/07/08
    **********************************************************************************************/
    FUNCTION get_formatted_total
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_value           IN NUMBER,
        i_internal_name   IN mtos_param.internal_name%TYPE,
        i_epis_mtos_score IN epis_mtos_param.id_epis_mtos_score%TYPE DEFAULT NULL,
        i_id_mtos_param   IN mtos_param.id_mtos_param%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Auxilliary method. Get the registered age in a given previously saved score.
    *
    * @param i_id_epis_mtos_score               Score ID
    *                        
    * @return            Registered Age
    *
    * @author            Jos?Brito
    * @version           1.0  
    * @since             2009/09/21
    **********************************************************************************************/
    FUNCTION get_registered_age(i_id_epis_mtos_score IN epis_mtos_score.id_epis_mtos_score%TYPE) RETURN NUMBER;

    /**********************************************************************************************
    * Checks if the patient age and gender matches the score configuration
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_pat_age            Patient age
    * @param i_pat_gender         Patient gender
    * @param i_age_min            Score minimum age
    * @param i_age_max            Score maximum age
    * @param i_gender             Score gender
    *                        
    * @return            Score is within patient gender and age: Y - Yes, N - No
    *
    * @author            Jos?Silva
    * @version           1.0  
    * @since             2010/09/09
    **********************************************************************************************/
    FUNCTION check_age_and_gender
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_pat_age    IN NUMBER,
        i_pat_gender IN patient.gender%TYPE,
        i_age_min    IN mtos_score_soft_inst.age_min%TYPE,
        i_age_max    IN mtos_score_soft_inst.age_max%TYPE,
        i_gender     IN mtos_score_soft_inst.gender%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Returns the patient age in years. 
    * E.g.:
    *       1) if 2 days old returns 0;
    *       2) if 16 months old returns 1;
    *       3) if 3 years old returns... 3.
    *
    * @param i_lang        Language ID
    * @param i_prof        Professional info
    * @param i_age         Patient age as shown in ALERT?
    * @param o_age         Patient age (in years)
    * @param o_error       Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            Jos?Brito
    * @version           1.0  
    * @since             2009/07/08
    **********************************************************************************************/
    FUNCTION get_pat_age_years
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_age   IN VARCHAR2,
        o_age   OUT NUMBER,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Database internal function. Used to return the total value of a given score.
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_id_patient         Patient ID
    * @param i_id_mtos_param      ID's of the score parameters
    * @param i_value              Registered values for each parameter
    * @param i_flg_score_type     Type of score
    * @param i_calculate_age      (Y) Calculate patient age in years (N) Do not calculate
    * @param i_pat_age_years      Patient age (in years)
    * @param o_score_a            Total score value
    * @param o_score_b            Total score second value, if applicable (only for TRISS)
    * @param o_error              Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            Jos?Brito
    * @version           1.0  
    * @since             2009/07/08
    **********************************************************************************************/
    FUNCTION get_total_score_internal
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_patient     IN patient.id_patient%TYPE,
        i_id_mtos_param  IN table_number,
        i_value          IN table_number,
        i_flg_score_type IN mtos_score.flg_score_type%TYPE,
        i_calculate_age  IN VARCHAR2,
        i_pat_age_years  IN NUMBER,
        o_score_a        OUT NUMBER,
        o_score_b        OUT NUMBER,
        o_total          OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Database internal function. Used to return the total value of a given score.
    * This function is used during the screen loading, so the scores are correctly shown.
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_id_episode         Episode ID
    * @param i_id_patient         Patient ID
    * @param i_flg_score_type     Type of score   
    * @param i_total_glasgow      Glasgow total score (needed for RTS)
    * @param i_total_rts          RTS total score (needed for TRISS)
    * @param i_total_iss          ISS total score (needed for TRISS)
    * @param i_pat_age_years      Patient age (in years)
    * @param o_score_a            Total score value
    * @param o_score_b            Total score second value, if applicable (only for TRISS)
    * @param o_error              Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            Jos?Brito
    * @version           1.0  
    * @since             2009/07/08
    **********************************************************************************************/
    FUNCTION get_total_score_aux
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_id_patient     IN patient.id_patient%TYPE,
        i_flg_score_type IN mtos_score.flg_score_type%TYPE,
        i_total_glasgow  IN NUMBER, -- Needed for RTS
        i_total_rts      IN NUMBER, -- Needed for TRISS
        i_total_iss      IN NUMBER, -- Needed for TRISS
        i_pat_age_years  IN NUMBER,
        o_score_a        OUT NUMBER,
        o_score_b        OUT NUMBER,
        o_error          OUT t_error_out
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
    * @author            Jos?Brito
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
    * Returns the available scores. Used by Flash to know how many blocks must be shown, 
    * one block for each score.
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_id_episode         Episode ID for each parameter
    * @param i_mtos_score         Score ID
    * @param o_score              Cursor with the available scores
    * @param o_flg_detail         Activate the DETAIL button: (Y)es (N)o
    * @param o_error              Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            Jos?Brito
    * @version           1.0  
    * @since             2009/07/08
    **********************************************************************************************/
    FUNCTION get_mtos_score
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_mtos_score IN mtos_score.id_mtos_score%TYPE,
        o_score      OUT pk_types.cursor_type,
        o_flg_detail OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Shows all parameters for all scores.
    * Returns the parameters properties and current value.
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_episode            Episode ID
    * @param i_mtos_score         Score ID
    * @param i_id_epis_mtos_score Score ID (currently not needed)
    * @param o_list               Cursor with the parameters
    * @param o_error              Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            Jos?Brito
    * @version           1.0  
    * @since             2009/07/08
    **********************************************************************************************/
    FUNCTION get_mtos_param_list
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_mtos_score         IN mtos_score.id_mtos_score%TYPE,
        i_id_epis_mtos_score IN epis_mtos_score.id_epis_mtos_score%TYPE,
        o_list               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

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
    * @since   06-09-2010
    */
    FUNCTION get_sev_scores_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        o_scores     OUT p_sev_scores_param_cur,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the score in which the record was made
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_patient            Patient ID
    * @param i_episode            Episode ID
    * @param i_epis_mtos_score    Episode score record ID
    * @param i_mtos_score         Score ID (it can be a child score)
    *                        
    * @return            Score ID
    *
    * @author            Jos?Silva
    * @version           1.0  
    * @since             2010/09/09
    **********************************************************************************************/
    FUNCTION get_epis_mtos_score
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_epis_mtos_score IN epis_mtos_score.id_epis_mtos_score%TYPE,
        i_mtos_score      IN mtos_score.id_mtos_score%TYPE
    ) RETURN NUMBER;

    /**********************************************************************************************
    * Returns the total score(s) of a record
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_patient            Patient ID
    * @param i_epis_mtos_score    Episode score record ID
    *                        
    * @return            Score totals
    *
    * @author            Jos?Silva
    * @version           1.0  
    * @since             2010/09/09
    **********************************************************************************************/
    FUNCTION get_epis_mtos_total
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_epis_mtos_score IN epis_mtos_score.id_epis_mtos_score%TYPE
    ) RETURN table_varchar;

    /**********************************************************************************************
    * Returns the total score(s) of a record
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_patient            Patient ID
    * @param i_epis_mtos_score    Episode score record ID
    *                        
    * @return            Score totals
    *
    * @author            Jos?Silva
    * @version           1.0  
    * @since             2010/09/09
    **********************************************************************************************/
    FUNCTION get_epis_mtos_total_desc
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_epis_mtos_score IN epis_mtos_score.id_epis_mtos_score%TYPE
    ) RETURN table_varchar;

    /**********************************************************************************************
    * Returns all scores registered in a given episode
    *
    * @param   i_lang              Professional preferred language
    * @param   i_prof              Professional identification and its context (institution and software)
    * @param   i_id_patient        Patient ID
    * @param   i_id_episode        Episode ID
    * @param   i_mtos_score        Score ID
    * @param   i_epis_mtos_score   Score evaluation ID
    * @param   o_reg               Records general information
    * @param   o_groups            List of groups inside the score records
    * @param   o_values            Score values
    * @param   o_cancel            Score cancellation data
    * @param   o_error             Error information
    *
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            Tércio Soares
    * @version           2.6.0.4
    * @since             2010/09/27
    **********************************************************************************************/
    FUNCTION get_sev_scores_values
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        i_mtos_score      IN mtos_score.id_mtos_score%TYPE,
        i_epis_mtos_score IN epis_mtos_score.id_epis_mtos_score%TYPE,
        o_reg             OUT pk_types.cursor_type,
        o_groups          OUT pk_types.cursor_type,
        o_values          OUT pk_types.cursor_type,
        o_cancel          OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Check if severity score evaluation can be canceled.
    * If so, the CANCEL button is activated.
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_episode            Episode ID
    * @param i_epis_mtos_score    Episode score record ID
    * @param i_prof_create        Professional ID
    *                        
    * @return            Flag for cancel button - Y - active; N - inactive
    *
    * @author            Tércio Soares
    * @version           2.6.0.4  
    * @since             2010/09/20
    **********************************************************************************************/
    FUNCTION chk_flg_cancel
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_epis_mtos_score IN epis_mtos_score.id_epis_mtos_score%TYPE,
        i_prof_create     IN epis_mtos_score.id_prof_create%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Returns the score parameter to be displayed in the evaluation screen
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_epis_mtos_score    Episode score record ID
    * @param i_id_mtos_param      Score parameter ID
    *                        
    * @return            Score parameter evaluation
    *
    * @author            Tércio Soares
    * @version           2.6.0.4
    * @since             2010/09/21
    **********************************************************************************************/
    FUNCTION get_registered_value_desc
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_epis_mtos_score IN epis_mtos_score.id_epis_mtos_score%TYPE,
        i_id_mtos_param   IN epis_mtos_param.id_mtos_param%TYPE,
        i_id_extra_score  IN epis_mtos_param.extra_score%TYPE
    ) RETURN VARCHAR2;

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
    * @since                          2010/09/21
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

    /********************************************************************************************
    * Shows all parameters for TRISS score.
    * Returns the parameters properties and current value.
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_patient             Patient ID
    * @param i_episode                Episode ID 
    * @param i_pat_age_years          Patient age
    * @param i_epis_mtos_score        Severity score evaluation ID
    * @param o_list                   Parameter list
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                         Tércio Soares
    * @version                        2.6.0.4
    * @since                          2010/09/21
    **********************************************************************************************/
    FUNCTION get_triss_param_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_pat_age_years   IN NUMBER,
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

    /********************************************************************************************
    * Shows all parameters for TISS score.
    * Returns the parameters properties and current value.
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_patient             Patient ID
    * @param i_episode                Episode ID 
    * @param i_pat_age_years          Patient age
    * @param i_mtos_score             Severity score ID
    * @param i_epis_mtos_score        Severity score evaluation ID
    * @param o_list                   Parameter list
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                         Tércio Soares
    * @version                        2.6.0.4
    * @since                          2010/09/23
    **********************************************************************************************/
    FUNCTION get_tiss_param_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_pat_age_years   IN NUMBER,
        i_mtos_score      IN mtos_score.id_mtos_score%TYPE,
        i_epis_mtos_score IN epis_mtos_score.id_epis_mtos_score%TYPE,
        o_list            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_isstw_param_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_pat_age_years   IN NUMBER,
        i_mtos_score      IN mtos_score.id_mtos_score%TYPE,
        i_epis_mtos_score IN epis_mtos_score.id_epis_mtos_score%TYPE,
        o_list            OUT pk_types.cursor_type,
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
    * Returns the score outdated evaluation id's used in detail screen.
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_id_episode         Episode ID for each parameter
    * @param i_epis_mtos_score    Score evaluation ID
    * @param flg_cancelled        'Y' - cancelled records only, 'N' - Outdated records
    *                        
    * @return            List of evaluation 
    *
    * @author            Tércio Soares
    * @version           2.6.0.4
    * @since             2010/09/23
    **********************************************************************************************/
    FUNCTION get_sev_score_detail_ids
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_epis_mtos_score IN epis_mtos_score.id_epis_mtos_score%TYPE,
        flg_cancelled     IN VARCHAR2
    ) RETURN table_number;

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
    * Saves a TRISS score evaluation and all the registered values.
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
    FUNCTION set_triss_score
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_prof_cat        IN category.flg_type%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_patient      IN patient.id_patient%TYPE,
        i_sev_score       IN mtos_score.id_mtos_score%TYPE,
        i_epis_mtos_score IN epis_mtos_score.id_epis_mtos_score%TYPE,
        i_id_mtos_param   IN table_number,
        i_value           IN table_number,
        i_unit_measure    IN table_number,
        o_flg_detail      OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Saves a score evaluation and all the registered values (without vital signs values).
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
    * @param o_error              Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            Tércio Soares
    * @version           2.6.0.4 
    * @since             2010/09/28
    **********************************************************************************************/
    FUNCTION set_general_score
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
    * Returns the score parameter exclusions
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_id_mtos_param      Score parameter ID
    *                        
    * @return            Score paramters exclusions
    *
    * @author            Tércio Soares
    * @version           2.6.0.4
    * @since             2010/10/01
    **********************************************************************************************/
    FUNCTION get_param_exclusions
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_mtos_param IN mtos_param_exclusions.id_mtos_param%TYPE
    ) RETURN table_number;

    /********************************************************************************************
    * Shows all parameters for SOFA score.
    * Returns the parameters properties and current value.
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_patient             Patient ID
    * @param i_episode                Episode ID 
    * @param i_pat_age_years          Patient age
    * @param i_epis_mtos_score        Severity score evaluation ID
    * @param o_list                   Parameter list
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                         Tércio Soares
    * @version                        2.6.0.4
    * @since                          2010/10/20
    **********************************************************************************************/
    FUNCTION get_sofa_param_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_pat_age_years   IN NUMBER,
        i_epis_mtos_score IN epis_mtos_score.id_epis_mtos_score%TYPE,
        o_list            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Shows all parameters for ALDRETE score.
    * Returns the parameters properties and current value.
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_patient             Patient ID
    * @param i_episode                Episode ID 
    * @param i_epis_mtos_score        Severity score evaluation ID
    * @param o_list                   Parameter list
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                         Tércio Soares
    * @version                        2.6.0.4
    * @since                          2010/10/26
    **********************************************************************************************/
    FUNCTION get_aldrete_param_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_epis_mtos_score IN epis_mtos_score.id_epis_mtos_score%TYPE,
        o_list            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Shows all parameters for CRIB AND CRIB II scores.
    * Returns the parameters properties and current value.
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_patient             Patient ID
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
    * @since                          2010/10/26
    **********************************************************************************************/
    FUNCTION get_crib_param_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_mtos_score      IN mtos_score.id_mtos_score%TYPE,
        i_epis_mtos_score IN epis_mtos_score.id_epis_mtos_score%TYPE,
        o_list            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Shows all parameters for SNAP score.
    * Returns the parameters properties and current value.
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_patient             Patient ID
    * @param i_episode                Episode ID 
    * @param i_epis_mtos_score        Severity score evaluation ID
    * @param o_list                   Parameter list
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                         Tércio Soares
    * @version                        2.6.0.4
    * @since                          2010/10/29
    **********************************************************************************************/
    FUNCTION get_snap_param_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_epis_mtos_score IN epis_mtos_score.id_epis_mtos_score%TYPE,
        o_list            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Shows all parameters for SPAS II score.
    * Returns the parameters properties and current value.
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_patient             Patient ID
    * @param i_episode                Episode ID 
    * @param i_pat_age_years          Patient age
    * @param i_epis_mtos_score        Severity score evaluation ID
    * @param o_list                   Parameter list
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                         Tércio Soares
    * @version                        2.6.0.4
    * @since                          2010/11/02
    **********************************************************************************************/
    FUNCTION get_saps_param_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_pat_age_years   IN NUMBER,
        i_epis_mtos_score IN epis_mtos_score.id_epis_mtos_score%TYPE,
        o_list            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Shows all parameters for APACHE II score.
    * Returns the parameters properties and current value.
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_patient             Patient ID
    * @param i_episode                Episode ID 
    * @param i_pat_age_years          Patient age
    * @param i_epis_mtos_score        Severity score evaluation ID
    * @param o_list                   Parameter list
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                         Tércio Soares
    * @version                        2.6.0.4
    * @since                          2010/10/20
    **********************************************************************************************/
    FUNCTION get_apache2_param_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_pat_age_years   IN NUMBER,
        i_epis_mtos_score IN epis_mtos_score.id_epis_mtos_score%TYPE,
        o_list            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Shows all parameters for APACHE III score.
    * Returns the parameters properties and current value.
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_patient             Patient ID
    * @param i_episode                Episode ID 
    * @param i_pat_age_years          Patient age
    * @param i_epis_mtos_score        Severity score evaluation ID
    * @param o_list                   Parameter list
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                         Tércio Soares
    * @version                        2.6.0.4
    * @since                          2010/11/02
    **********************************************************************************************/
    FUNCTION get_apache3_param_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_pat_age_years   IN NUMBER,
        i_epis_mtos_score IN epis_mtos_score.id_epis_mtos_score%TYPE,
        o_list            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_si_it_is_param_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_pat_age_years   IN NUMBER,
        i_epis_mtos_score IN epis_mtos_score.id_epis_mtos_score%TYPE,
        o_list            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prism_param_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_pat_age_years   IN NUMBER,
        i_epis_mtos_score IN epis_mtos_score.id_epis_mtos_score%TYPE,
        o_list            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_apache_tw_param_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_pat_age_years   IN NUMBER,
        i_epis_mtos_score IN epis_mtos_score.id_epis_mtos_score%TYPE,
        o_list            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_sofa_tw_param_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_pat_age_years   IN NUMBER,
        i_epis_mtos_score IN epis_mtos_score.id_epis_mtos_score%TYPE,
        o_list            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vte_param_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_pat_age_years   IN NUMBER,
        i_epis_mtos_score IN epis_mtos_score.id_epis_mtos_score%TYPE,
        o_list            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Database internal function. Used to return the values of a Glasgow score.
    * This function is used during the screen loading, so the scores are correctly shown.
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_id_episode         Episode ID
    * @param i_id_patient         Patient ID
    * @param i_pat_age_years      Patient age (in years)
    * @param o_gcs_eyes           Eyes value
    * @param o_gcs_verbal         Verbal value
    * @param o_gcs_motor          Motor value
    * @param o_gcs_eyes_desc      Eyes value description
    * @param o_gcs_verbal_desc    Verbal value description
    * @param o_gcs_motor_desc     Motor value description
    * @param o_gcs_total          Total scorevalue
    * @param o_error              Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            Tércio Sooares
    * @version           1.0  
    * @since             2010/10/27
    **********************************************************************************************/
    FUNCTION get_glasgow_score_aux
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_patient      IN patient.id_patient%TYPE,
        i_pat_age_years   IN NUMBER,
        o_gcs_eyes        OUT NUMBER,
        o_gcs_verbal      OUT NUMBER,
        o_gcs_motor       OUT NUMBER,
        o_gcs_eyes_desc   OUT VARCHAR2,
        o_gcs_verbal_desc OUT VARCHAR2,
        o_gcs_motor_desc  OUT VARCHAR2,
        o_gcs_total       OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Database internal function. Used to return the values of a (A-a)O2 Gradient score.
    * This function is used during the screen loading, so the scores are correctly shown.
    *
    * @param i_lang                      Language ID
    * @param i_prof                      Professional info
    * @param i_id_episode                Episode ID
    * @param i_id_patient                Patient ID
    * @param i_pat_age_years             Patient age (in years)
    * @param i_paco2                     PaCO2 value
    * @param i_pao2                      PaO2 value
    * @param i_fio2                      FIO2 value
    * @param o_paco2                     PaCO2 value
    * @param o_pao2                      PaO2 value
    * @param o_fio2                      FIO2 value
    * @param o_o2_grd_total              (A-a) Gradient total value
    * @param o_apache3_fio2_02_grd       "If FIO2 >= 0.5: (A-a) O2" value (APACHE III)
    * @param o_apache3_fio2_pao2         "If FIO2 < 0.5: PaO2" value (APACHE III)
    * @param o_paco2_desc                PaCO2 value description
    * @param o_pao2_desc                 PaO2 value description
    * @param o_fio2_desc                 FIO2 value description
    * @param o_apache3_fio2_02_grd_desc "If FIO2 >= 0.5: (A-a) O2" value (APACHE III) description
    * @param o_apache3_fio2_pao2_desc   "If FIO2 < 0.5: PaO2" value (APACHE III) description
    * @param o_error                    Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            Tércio Sooares
    * @version           2.6.0.4
    * @since             2010/11/03
    **********************************************************************************************/
    FUNCTION get_02_grd_score_aux
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_episode               IN episode.id_episode%TYPE,
        i_id_patient               IN patient.id_patient%TYPE,
        i_pat_age_years            IN NUMBER,
        i_paco2                    IN NUMBER,
        i_pao2                     IN NUMBER,
        i_fio2                     IN NUMBER,
        o_paco2                    OUT NUMBER,
        o_pao2                     OUT NUMBER,
        o_fio2                     OUT NUMBER,
        o_o2_grd_total             OUT NUMBER,
        o_apache3_fio2_02_grd      OUT NUMBER,
        o_apache3_fio2_pao2        OUT NUMBER,
        o_paco2_desc               OUT VARCHAR2,
        o_pao2_desc                OUT VARCHAR2,
        o_fio2_desc                OUT VARCHAR2,
        o_apache3_fio2_02_grd_desc OUT VARCHAR2,
        o_apache3_fio2_pao2_desc   OUT VARCHAR2,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Auxilliary method. Get the CRIB II value for Birthweight and Gestation weeks considering the 
    * child gender
    *
    * @param i_pat_gender       Child gender
    * @param i_birthweight      Birthweight
    * @param i_gestation_weeks  Gestation weeks
    *                        
    * @return            Value for birthweight and gestation weeks relation
    *
    * @author            Tércio Soares
    * @version           2.6.0.4
    * @since             2010/10/29
    **********************************************************************************************/
    FUNCTION get_crib_weight_gest_aux
    (
        i_pat_gender      IN patient.gender%TYPE,
        i_birthweight     NUMBER,
        i_gestation_weeks NUMBER
    ) RETURN NUMBER;

    /**********************************************************************************************
    * Function used to return the total value of Oxyganation Index.
    *
    * @param i_lang            Language ID
    * @param i_prof            Professional info
    * @param i_paw             Mean Airway - Pressure (mmHg)
    * @param i_pao2            Mean Airway - PaO2 (mmHg)
    * @param i_fio2            Mean Airway - FIO2
    * @param o_oi_total_value  Total OI value for SNAP score calculation
    * @param o_oi_total_desc   Total OI value description to show in the screen
    * @param i_id_mtos_param   ID's of the score parameters
    * @param i_value           Registered values for each parameter
    * @param o_total           OI total value
    * @param o_error           Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            Tércio Soares
    * @version           2.6.0.4
    * @since             2010/10/29
    **********************************************************************************************/
    FUNCTION get_oi_total
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_mtos_param IN table_number,
        i_value         IN table_number,
        o_total         OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Function used to return the total value of Acute Physiology (APACHE III).
    *
    * @param i_lang            Language ID
    * @param i_prof            Professional info
    * @param i_pco2            pCO2 value
    * @param i_ph              pH value
    *                        
    * @return            Acute Physiology value
    *
    * @author            Tércio Soares
    * @version           2.6.0.4
    * @since             2010/11/02
    **********************************************************************************************/
    FUNCTION get_acute_physiology_total
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_pco2 IN NUMBER,
        i_ph   IN FLOAT
    ) RETURN NUMBER;

    /**********************************************************************************************
    * Function used to return the total value of Neurologic abnormalties  (APACHE III).
    *
    * @param i_lang      Language ID
    * @param i_prof      Professional info
    * @param i_eyes      Eyes Open
    * @param i_motor     Motor
    * @param i_verbal    Verbal
    *                        
    * @return            Neurologic abnormalty value
    *
    * @author            Tércio Soares
    * @version           2.6.0.4
    * @since             2010/11/02
    **********************************************************************************************/
    FUNCTION get_neuro_abnormalty_total
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_eyes   IN NUMBER,
        i_motor  IN NUMBER,
        i_verbal IN NUMBER
    ) RETURN NUMBER;

    /**********************************************************************************************
    * Database internal function. Used to return the values of a (A-a)O2 Gradient score.
    * This function is used during the screen loading, so the scores are correctly shown.
    *
    * @param i_lang                      Language ID
    * @param i_prof                      Professional info
    * @param i_id_patient                Patient ID
    * @param i_id_mtos_param             ID's of the score parameters
    * @param i_value                     Registered values for each parameter
    * @param o_total                     (A-a) Gradient total value
    * @param o_error                     Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            Tércio Sooares
    * @version           2.6.0.4
    * @since             2010/11/26
    **********************************************************************************************/
    FUNCTION get_o2_grd_total
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_patient    IN patient.id_patient%TYPE,
        i_id_mtos_param IN table_number,
        i_value         IN table_number,
        o_total         OUT pk_types.cursor_type,
        o_error         OUT t_error_out
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
    * @author            Jos?Brito
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
    * Returns the vital sign value information according to the institution/market configuration.
    *
    * @param i_lang                Language ID
    * @param i_prof                Professional info
    * @param i_id_vital_sign_vsr   Vital sign ID
    * @param i_id_unit_measure_vsr Unit measure ID
    * @param i_value_vsr           Vital sign value
    * @param i_flg_return          Flag to indicate wich value should be returned 
    *                              (V - Value, U - Unit measure, MIN - Minimum value,
    *                               MAX - Maximum value, F - Format)
    *
    * @return            Vital sign infromation
    *
    * @author            Tércio Soares
    * @version           2.6.0.4  
    * @since             2010/12/07
    **********************************************************************************************/
    FUNCTION get_vital_sign_info
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_vital_sign_vsr   IN vital_sign_read.id_vital_sign%TYPE,
        i_id_unit_measure_vsr IN vital_sign_read.id_unit_measure%TYPE,
        i_value_vsr           IN vital_sign_read.value%TYPE,
        i_flg_return          IN VARCHAR2
    ) RETURN NUMBER;

    /**********************************************************************************************
    * Returns the vital sign unit measure according to the institution/market configuration.
    *
    * @param i_vital_sign   Vital sign ID
    * @param i_institution  Institution ID
    *
    * @return            Vital sign unit measure
    *
    * @author            Tércio Soares
    * @version           2.6.0.4  
    * @since             2010/12/09
    **********************************************************************************************/
    FUNCTION get_vs_um_inst_um
    (
        i_vital_sign  IN vital_sign.id_vital_sign%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE
    ) RETURN unit_measure.id_unit_measure%TYPE;

    FUNCTION get_ap_um_inst_um
    (
        i_analysis_parameter IN analysis_parameter.id_content%TYPE,
        i_institution        IN institution.id_institution%TYPE,
        i_software           IN software.id_software%TYPE
    ) RETURN unit_measure.id_unit_measure%TYPE;

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

    /********************************************************************************************
    * Shows all parameters for CRUB65 score.
    * Returns the parameters properties and current value.
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_patient             Patient ID
    * @param i_episode                Episode ID 
    * @param i_epis_mtos_score        Severity score evaluation ID
    * @param o_list                   Parameter list
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                         Elisabete Bugalho
    * @version                        2.6.2.1.7
    * @since                          2012/09/11
    **********************************************************************************************/
    FUNCTION get_curb65_param_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_epis_mtos_score IN epis_mtos_score.id_epis_mtos_score%TYPE,
        i_mtos_score      IN mtos_score.id_mtos_score%TYPE,
        o_list            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /**
    * Get EPIS_MTOS_SCORE description.
    * Used for the task timeline easy access (HandP import mechanism).
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_ID_EPIS_MTOS_SCORE     mtos identifier
    * @param i_desc_type              desc_type S-short/L-long
    * @param i_flg_description        Task description type (S-short; L-long; D-detail; C- conditional)
    * @param i_description_condition  String that will dictate how the description should be built  
    *
    * @return               diet task description
    *
    * @author               Paulo Teixeira
    * @version               2.6.3
    * @since                2013/05/07
    */
    FUNCTION get_task_description
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_epis_mtos_score    IN epis_mtos_score.id_epis_mtos_score%TYPE,
        i_patient               IN patient.id_patient%TYPE DEFAULT NULL,
        i_desc_type             IN VARCHAR2,
        i_flg_description       IN pn_dblock_ttp_mkt.flg_description%TYPE,
        i_description_condition IN pn_dblock_ttp_mkt.description_condition%TYPE
    ) RETURN CLOB;

    /**********************************************************************************************
    * get actions of the severity scores records
    *
    * @param       i_lang                   preferred language id for this professional
    * @param       i_prof                   professional type
    * @param       i_task_request           task request id (monitorization id)
    * @param       o_actions                actions cursor info 
    * @param       o_error                  error message
    *
    * @return      boolean                  true on success, otherwise false
    *
    * @author                               Sofia Mendes
    * @version                              2.6.2
    * @since                                23-May-2013
    **********************************************************************************************/
    FUNCTION get_sev_scores_actions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN epis_mtos_score.id_epis_mtos_score%TYPE,
        i_patient      IN patient.id_patient%TYPE DEFAULT NULL,
        o_actions      OUT pk_types.cursor_type,
        o_error        OUT t_error_out
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
    * Shows all parameters for Any Score
    * Returns the parameters properties and current value.
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_patient             Patient ID
    * @param i_episode                Episode ID 
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
    FUNCTION get_general_param_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_mtos_score      IN mtos_score.id_mtos_score%TYPE,
        i_epis_mtos_score IN epis_mtos_score.id_epis_mtos_score%TYPE,
        o_list            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

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
    /********************************************************************************************
    * 
    * Get Severity Scores to show on a viewer with temporary totals
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

    FUNCTION get_sev_score_viewer_wtotals
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_mtos_score         IN mtos_score.id_mtos_score%TYPE,
        i_epis_mtos_score    IN epis_mtos_param.id_epis_mtos_score%TYPE DEFAULT NULL,
        i_id_mtos_param      IN table_number,
        i_value              IN table_number,
        i_vs_scales_elements IN table_number,
        o_list               OUT pk_types.cursor_type,
        
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * 
    * Get a Score Value for each parameter value calculated on fly
    *
    * @param i_id_mtos_param      ID's of the score parameters
    * @param i_value              Registered values for each parameter
    *
    * @return                         Value or 0
    *
    * @author                         Mário Mineiro
    * @version                        2.6.3.7
    * @since                          19/07/2013
    **********************************************************************************************/

    FUNCTION get_score_value
    (
        i_prof          IN profissional,
        i_id_mtos_param IN NUMBER,
        i_value         IN NUMBER
    ) RETURN NUMBER;

    /********************************************************************************************
    * 
    * Get a Score Color for each parameter value calculated on fly
    *
    * @param i_id_mtos_param      ID's of the score parameters
    * @param i_value              Registered values for each parameter
    *
    * @return                         Value or 0
    *
    * @author                         Mário Mineiro
    * @version                        2.6.3.7
    * @since                          19/07/2013
    **********************************************************************************************/

    FUNCTION get_score_color
    (
        i_prof          IN profissional,
        i_id_mtos_param IN NUMBER,
        i_value         IN NUMBER
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * 
    * Get a Score Description for each parameter value calculated on fly
    *
    * @param i_id_mtos_param      ID's of the score parameters
    * @param i_value              Registered values for each parameter
    *
    * @return                         Value or 0
    *
    * @author                         Mário Mineiro
    * @version                        2.6.3.7
    * @since                          19/07/2013
    **********************************************************************************************/

    FUNCTION get_score_desc
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_mtos_param IN NUMBER,
        i_value         IN NUMBER
    ) RETURN VARCHAR2;

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
        i_dt_create          IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_id_epis_mtos_score OUT epis_mtos_score.id_epis_mtos_score%TYPE,
        o_msg_error          OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_modified_score
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_epis_mtos_score IN epis_mtos_score.id_epis_mtos_score%TYPE
    ) RETURN NUMBER;

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

    FUNCTION set_sev_score_api
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_epis_mtos_score IN epis_mtos_score.id_epis_mtos_score%TYPE,
        i_id_episode         IN episode.id_episode%TYPE,
        i_dt_create          IN VARCHAR2,
        i_mtos_params        IN table_number,
        i_extra_score        IN table_varchar,
        o_id_epis_mtos_score OUT epis_mtos_score.id_epis_mtos_score%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_sev_score_api
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_epis_mtos_score IN epis_mtos_score.id_epis_mtos_score%TYPE,
        i_id_cancel_reason   IN epis_mtos_score.id_cancel_reason%TYPE,
        i_cancel_notes       IN epis_mtos_score.notes_cancel%TYPE,
        i_dt_cancel          IN VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_param_default
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE,
        i_mtos_param          IN mtos_param.id_mtos_param%TYPE,
        i_flg_param_task_type IN mtos_param_task.flg_param_task_type%TYPE,
        i_ref_value           IN NUMBER,
        i_ref_unit_measure    IN unit_measure.id_unit_measure%TYPE,
        i_flg_condition       IN VARCHAR2,
        i_flg_comparison      IN VARCHAR2,
        i_dt_min              IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_max              IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN BOOLEAN;

    FUNCTION check_param_default_2
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE,
        i_mtos_param          IN mtos_param.id_mtos_param%TYPE,
        i_flg_param_task_type IN table_varchar,
        i_ref_unit_measure    IN table_number,
        i_flg_condition       IN VARCHAR2,
        i_flg_comparison      IN VARCHAR2,
        i_dt_min              IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_max              IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN NUMBER;

    FUNCTION check_param_default_to_int
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE,
        i_mtos_param          IN mtos_param.id_mtos_param%TYPE,
        i_flg_param_task_type IN mtos_param_task.flg_param_task_type%TYPE,
        i_ref_value           IN NUMBER,
        i_ref_unit_measure    IN unit_measure.id_unit_measure%TYPE,
        i_flg_condition       IN VARCHAR2,
        i_flg_comparison      IN VARCHAR2,
        i_dt_min              IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_max              IN TIMESTAMP WITH LOCAL TIME ZONE
        
    ) RETURN INTEGER;

    FUNCTION check_param_default_2_final
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE,
        i_mtos_param          IN mtos_param.id_mtos_param%TYPE,
        i_flg_param_task_type IN table_varchar,
        i_ref_unit_measure    IN table_number,
        i_flg_condition       IN VARCHAR2,
        i_flg_comparison      IN VARCHAR2,
        i_dt_min              IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_max              IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN NUMBER;

    /**********************************************************************************************
    * Formats a given total value according to the rules of the specified score in 'internal_name'.
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_episode            Episode ID
    * @param i_mtos_score         mtos_score ID
    * @param i_internal_name      Score internal name
    *
    * @return            Formatted string
    *
    * @author            Lillian Lu
    * @version           2.7.2.3
    * @since             13/1/2018
    **********************************************************************************************/
    FUNCTION get_last_sev_score_total
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_mtos_score    IN mtos_score.id_mtos_score%TYPE,
        i_internal_name IN mtos_param.internal_name%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_sev_scores_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_mtos_score IN table_number,
        i_id_episode IN episode.id_episode%TYPE,
        o_scores     OUT p_sev_scores_param_cur,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION count_documented_tasks
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE,
        i_mtos_param          IN mtos_param.id_mtos_param%TYPE,
        i_flg_param_task_type IN mtos_param_task.flg_param_task_type%TYPE,
        i_ref_value           IN NUMBER,
        i_ref_unit_measure    IN unit_measure.id_unit_measure%TYPE,
        i_flg_condition       IN VARCHAR2,
        i_flg_comparison      IN VARCHAR2,
        i_dt_min              IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_max              IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN INTEGER;

    g_colon       CONSTANT VARCHAR2(1 CHAR) := ':';
    g_space       CONSTANT VARCHAR2(1 CHAR) := ' ';
    g_open        CONSTANT VARCHAR2(1 CHAR) := '(';
    g_close       CONSTANT VARCHAR2(1 CHAR) := ')';
    g_slash       CONSTANT VARCHAR2(1 CHAR) := '/';
    g_desc_type_s CONSTANT VARCHAR2(1 CHAR) := 'S';
    g_desc_type_l CONSTANT VARCHAR2(1 CHAR) := 'L';

    FUNCTION exists_in_diagnoses
    (
        i_lang               IN NUMBER,
        i_prof               IN profissional,
        i_episode            IN NUMBER,
        i_table_param_values IN table_number
    ) RETURN BOOLEAN;

    FUNCTION compare_exists_vs
    (
        i_lang               IN NUMBER,
        i_prof               IN profissional,
        i_episode            IN NUMBER,
        i_table_param_values IN table_number,
        i_id_mtos_param      IN NUMBER DEFAULT NULL,
        flg_comparison       IN VARCHAR2 DEFAULT NULL
    ) RETURN BOOLEAN;

    FUNCTION process_value
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional,
        i_episode       IN NUMBER,
        i_id_mtos_score IN NUMBER,
        i_id_mtos_param IN NUMBER
    ) RETURN table_number;

    FUNCTION get_nstemi
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_episode         IN NUMBER,
        i_mto_score       IN NUMBER,
        i_epis_mtos_score IN NUMBER
    ) RETURN t_tab_sev_score;

    FUNCTION get_stemi
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_episode         IN NUMBER,
        i_mto_score       IN NUMBER,
        i_epis_mtos_score IN NUMBER
    ) RETURN t_tab_sev_score;

    FUNCTION get_timi_core
    (
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_episode   IN NUMBER,
        i_mto_score IN NUMBER,
        i_group     IN NUMBER
    ) RETURN t_tab_sev_score;

    PROCEDURE get_timi_group
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_episode         IN NUMBER,
        i_mto_score       IN NUMBER,
        i_epis_mtos_score IN NUMBER,
        o_score           OUT pk_types.cursor_type
    );

    FUNCTION get_all_timi
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_episode         IN NUMBER,
        i_mto_score       IN NUMBER,
        i_epis_mtos_score IN NUMBER
    ) RETURN t_tab_sev_score;

    FUNCTION get_timi_base_sql
    (
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_mto_score IN NUMBER,
        i_group     IN NUMBER
    ) RETURN t_tab_sev_score;

    FUNCTION get_pat_info(i_id_episode IN NUMBER) RETURN patient%ROWTYPE;

    FUNCTION decode_value
    (
        i_flag       IN NUMBER,
        i_new_value  IN table_number,
        i_edit_value IN table_number
    ) RETURN table_number;

    FUNCTION get_timi_new_n_edit
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_episode         IN NUMBER,
        i_mto_score       IN NUMBER,
        i_group           IN NUMBER,
        i_epis_mtos_score IN NUMBER
    ) RETURN t_tab_sev_score;

    FUNCTION get_mto_score_parent(i_id_mtos_score IN NUMBER) RETURN NUMBER;

    FUNCTION decode_value_v
    (
        i_lang       IN NUMBER,
        i_flag       IN NUMBER,
        i_new_value  IN table_varchar,
        i_edit_value IN table_number
    ) RETURN table_varchar;

    PROCEDURE get_score_nstemi
    (
        i_id_mtos_param IN table_number,
        i_value         IN table_number,
        o_total         OUT pk_types.cursor_type
    );

    FUNCTION get_score_groups
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        o_groups     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    -- ****************************************************************
    FUNCTION get_stemi_tot_item(i_value IN NUMBER) RETURN NUMBER;
    FUNCTION get_nstemi_tot_item
    (
        i_value IN NUMBER,
        i_idx   IN NUMBER
    ) RETURN VARCHAR2;

    FUNCTION get_score_det_dest
    (
        i_lang     IN NUMBER,
        i_code     IN VARCHAR2,
        i_code_abb IN VARCHAR2
    ) RETURN VARCHAR2;

    PROCEDURE ins_mtos_param_value_task
    (
        i_id_mtos_param_value IN mtos_param_value_task.id_mtos_param_value%TYPE,
        i_flg_param_task_type IN mtos_param_value_task.flg_param_task_type%TYPE,
        i_id_param_task       IN mtos_param_value_task.id_param_task%TYPE DEFAULT NULL,
        i_min_val             IN mtos_param_value_task.min_val%TYPE DEFAULT NULL,
        i_max_val             IN mtos_param_value_task.max_val%TYPE DEFAULT NULL,
        i_flg_available       IN mtos_param_value_task.flg_available%TYPE DEFAULT pk_alert_constant.g_yes,
        i_handle_error_in     IN BOOLEAN := TRUE
    );

    PROCEDURE ins_mtos_param_task
    (
        i_id_mtos_param         IN mtos_param_task.id_mtos_param%TYPE,
        i_flg_param_task_type   IN mtos_param_task.flg_param_task_type%TYPE,
        i_id_param_task         IN mtos_param_task.id_param_task%TYPE,
        i_id_content_param_task IN mtos_param_task.id_content_param_task%TYPE,
        i_flg_available         IN mtos_param_task.flg_available%TYPE DEFAULT pk_alert_constant.g_yes,
        i_flg_show_task_desc    IN mtos_param_task.flg_show_task_desc%TYPE DEFAULT pk_alert_constant.g_no,
        i_handle_error_in       IN BOOLEAN := TRUE
    );

END pk_sev_scores_core;
/
