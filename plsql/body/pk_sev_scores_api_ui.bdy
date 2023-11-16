/*-- Last Change Revision: $Rev: 2027713 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:05 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_sev_scores_api_ui IS

    -- Private variable declarations

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Function and procedure implementations

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
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_SEV_SCORES_LIST';
    
    BEGIN
        g_error := 'Init UX';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        IF NOT pk_sev_scores_core.get_sev_scores_list(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_patient    => i_patient,
                                                      i_id_episode => i_id_episode,
                                                      o_scores     => o_scores,
                                                      o_error      => o_error)
        THEN
        
            o_error := NULL;
            pk_sev_scores_core.open_my_cursor(o_scores);
            o_flg_show  := 'Y';
            o_msg_title := pk_message.get_message(i_lang, 'COMMON_M080');
            o_msg       := pk_message.get_message(i_lang, 'TRAUMA_T040');
            o_button    := 'R';
        
        END IF;
    
        RETURN TRUE;
    
    END get_sev_scores_list;

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
    ) RETURN BOOLEAN IS
    
        l_cancel pk_types.cursor_type;
    
    BEGIN
    
        RETURN pk_sev_scores_core.get_sev_scores_values(i_lang            => i_lang,
                                                        i_prof            => i_prof,
                                                        i_id_patient      => i_id_patient,
                                                        i_id_episode      => i_id_episode,
                                                        i_mtos_score      => NULL,
                                                        i_epis_mtos_score => NULL,
                                                        o_reg             => o_reg,
                                                        o_groups          => o_groups,
                                                        o_values          => o_values,
                                                        o_cancel          => l_cancel,
                                                        o_error           => o_error);
    
    END get_sev_scores_values;

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
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET_SEV_SCORE_PARAM_LIST: i_id_episode = ' || i_episode || ', ID_MTOS_SCORE = ' || i_mtos_score;
        pk_alertlog.log_debug(g_error);
    
        RETURN pk_sev_scores_core.get_sev_score_param_list(i_lang,
                                                           i_prof,
                                                           i_episode,
                                                           i_mtos_score,
                                                           i_epis_mtos_score,
                                                           o_list,
                                                           o_error);
    
    END get_sev_score_param_list;

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
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET_SEV_SCORE_DETAIL: i_id_episode = ' || i_id_episode || ', ID_EPIS_MTOS_SCORE = ' ||
                   i_epis_mtos_score;
        pk_alertlog.log_debug(g_error);
        RETURN pk_sev_scores_core.get_sev_score_detail(i_lang,
                                                       i_prof,
                                                       i_id_episode,
                                                       i_epis_mtos_score,
                                                       o_reg,
                                                       o_value,
                                                       o_cancel,
                                                       o_error);
    
    END get_sev_score_detail;

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
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CANCEL SEV_SCORE EVALUATION: i_id_episode = ' || i_id_episode || ', ID_EPIS_MTOS_SCORE = ' ||
                   i_epis_mtos_score;
        pk_alertlog.log_debug(g_error);
        RETURN pk_sev_scores_core.cancel_sev_score(i_lang,
                                                   i_prof,
                                                   i_id_episode,
                                                   i_epis_mtos_score,
                                                   id_cancel_reason,
                                                   notes_cancel,
                                                   o_error);
    
    END cancel_sev_score;

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
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200) := 'GET_SEV_SCORE';
    
    BEGIN
    
        g_error := 'GET_SEV_SCORE_GROUPS: i_id_episode = ' || i_id_episode || ', ID_SEV_SCORE = ' || i_mtos_score;
        pk_alertlog.log_debug(g_error);
        RETURN get_sev_score(i_lang, i_prof, i_id_episode, i_mtos_score, NULL, o_score, o_error);
    END get_sev_score;

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
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200) := 'GET_SEV_SCORE';
    
    BEGIN
    
        g_error := 'GET_SEV_SCORE_GROUPS: i_id_episode = ' || i_id_episode || ', ID_SEV_SCORE = ' || i_mtos_score;
        pk_alertlog.log_debug(g_error);
        RETURN pk_sev_scores_core.get_sev_score(i_lang,
                                                i_prof,
                                                i_id_episode,
                                                i_mtos_score,
                                                i_epis_mtos_score,
                                                o_score,
                                                o_error);
    END get_sev_score;

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
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200) := 'SET_SEV_SCORE';
    
    BEGIN
    
        g_error := 'SET_SEV_SCORE_EVALUATION: i_id_episode = ' || i_id_episode || ', ID_SEV_SCORE = ' || i_sev_score;
        pk_alertlog.log_debug(g_error);
        RETURN pk_sev_scores_core.set_sev_score(i_lang               => i_lang,
                                                i_prof               => i_prof,
                                                i_prof_cat           => i_prof_cat,
                                                i_id_episode         => i_id_episode,
                                                i_id_patient         => i_id_patient,
                                                i_sev_score          => i_sev_score,
                                                i_epis_mtos_score    => i_epis_mtos_score,
                                                i_id_mtos_param      => i_id_mtos_param,
                                                i_value              => i_value,
                                                i_notes              => i_notes,
                                                i_unit_measure       => i_unit_measure,
                                                i_vs_scales_elements => i_vs_scales_elements,
                                                o_flg_detail         => o_flg_detail,
                                                o_error              => o_error);
    END set_sev_score;

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
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200) := 'SET_SEV_SCORE';
    
    BEGIN
    
        g_error := 'SET_SEV_SCORE_EVALUATION: i_id_episode = ' || i_id_episode || ', ID_SEV_SCORE = ' || i_sev_score;
        pk_alertlog.log_debug(g_error);
    
        RETURN pk_sev_scores_core.set_sev_score_ms(i_lang               => i_lang,
                                                   i_prof               => i_prof,
                                                   i_prof_cat           => i_prof_cat,
                                                   i_id_episode         => i_id_episode,
                                                   i_id_patient         => i_id_patient,
                                                   i_sev_score          => i_sev_score,
                                                   i_epis_mtos_score    => i_epis_mtos_score,
                                                   i_id_mtos_param      => i_id_mtos_param,
                                                   i_value              => i_value,
                                                   i_notes              => i_notes,
                                                   i_unit_measure       => i_unit_measure,
                                                   i_vs_scales_elements => i_vs_scales_elements,
                                                   o_flg_detail         => o_flg_detail,
                                                   o_error              => o_error);
    END set_sev_score_ms;

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
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200) := 'SET_SEV_SCORE';
    
    BEGIN
    
        g_error := 'SET_SEV_SCORE_CONTENT_HELP: i_id_episode = ' || i_id_episode || ', ID_SEV_SCORE = ' || i_mtos_score;
        pk_alertlog.log_debug(g_error);
        RETURN pk_sev_scores_core.get_sev_score_help(i_lang             => i_lang,
                                                     i_prof             => i_prof,
                                                     i_id_episode       => i_id_episode,
                                                     i_mtos_score       => i_mtos_score,
                                                     i_mtos_score_group => i_mtos_score_group,
                                                     i_flg_context      => i_flg_context,
                                                     o_score_help       => o_score_help,
                                                     o_score_group_help => o_score_group_help,
                                                     o_error            => o_error);
    END get_sev_score_help;

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
        i_id_mtos_param      IN table_number, --
        i_value              IN table_number, --
        i_flg_score_type     IN mtos_score.flg_score_type%TYPE, --si_it_is
        i_id_mtos_score      IN mtos_score.id_mtos_score%TYPE DEFAULT NULL, --45
        i_vs_scales_elements IN table_number, --
        o_total              OUT pk_types.cursor_type,
        o_viewer             OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200) := 'SET_SEV_SCORE';
    
    BEGIN
    
        g_error := 'GET_TOTAL_SCORE: i_id_patient = ' || i_id_patient;
        pk_alertlog.log_debug(g_error);
        RETURN pk_sev_scores_core.get_total_score(i_lang               => i_lang,
                                                  i_prof               => i_prof,
                                                  i_id_patient         => i_id_patient,
                                                  i_id_mtos_param      => i_id_mtos_param,
                                                  i_value              => i_value,
                                                  i_flg_score_type     => i_flg_score_type,
                                                  i_id_mtos_score      => i_id_mtos_score,
                                                  i_vs_scales_elements => i_vs_scales_elements,
                                                  o_total              => o_total,
                                                  o_viewer             => o_viewer,
                                                  o_error              => o_error);
    END get_total_score;

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
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200) := 'SET_SEV_SCORE';
        l_param          table_number := table_number();
        l_value          table_number := table_number();
        l_assigned_value BOOLEAN := FALSE;
    BEGIN
    
        g_error := 'GET_TOTAL_SCORE: i_id_patient = ' || i_id_patient;
        pk_alertlog.log_debug(g_error);
    
        FOR i IN i_value.first .. i_value.last
        LOOP
        
            FOR j IN i_value(i).first .. i_value(i).last
            LOOP
                IF i_value(i) (j) IS NOT NULL
                THEN
                    l_value.extend;
                    l_param.extend;
                
                    l_value(l_value.count) := i_value(i) (j);
                    l_param(l_value.count) := i_id_mtos_param(i);
                    l_assigned_value := TRUE;
                END IF;
            END LOOP;
        
            IF l_assigned_value = FALSE
            THEN
                l_value.extend;
                l_param.extend;
                l_value(l_value.count) := NULL;
                l_param(l_value.count) := i_id_mtos_param(i);
            END IF;
        
            l_assigned_value := FALSE;
        END LOOP;
    
        RETURN pk_sev_scores_core.get_total_score(i_lang               => i_lang,
                                                  i_prof               => i_prof,
                                                  i_id_patient         => i_id_patient,
                                                  i_id_mtos_param      => l_param, --i_id_mtos_param,
                                                  i_value              => l_value,
                                                  i_flg_score_type     => i_flg_score_type,
                                                  i_id_mtos_score      => i_id_mtos_score,
                                                  i_vs_scales_elements => i_vs_scales_elements,
                                                  o_total              => o_total,
                                                  o_viewer             => o_viewer,
                                                  o_error              => o_error);
    END get_total_score_ms;

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
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200) := 'GET_PARAM_OPTIONS';
        l_exception EXCEPTION;
    BEGIN
    
        IF NOT pk_sev_scores_core.get_param_options(i_lang           => i_lang,
                                                    i_prof           => i_prof,
                                                    i_id_mtos_param  => i_id_mtos_param,
                                                    i_flg_score_type => i_flg_score_type,
                                                    i_id_patient     => i_id_patient,
                                                    o_list           => o_list,
                                                    o_error          => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        
    END get_param_options;

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
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200) := 'GET_SEV_SCORES_PDMS';
    
        l_dt_begin epis_mtos_score.dt_create%TYPE;
        l_dt_end   epis_mtos_score.dt_create%TYPE;
    
    BEGIN
    
        g_error := 'GET_SEV_SCORES_PDMS: i_id_visit = ' || i_id_visit;
        pk_alertlog.log_debug(g_error);
        RETURN pk_sev_scores_core.get_sev_scores_pdms(i_lang,
                                                      i_prof,
                                                      i_id_visit,
                                                      i_dt_begin,
                                                      i_dt_end,
                                                      o_sev_scoress,
                                                      o_error);
    END get_sev_scores_pdms;

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
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET_SEV_SCORE_SCREEN: i_id_mtos_score = ' || i_id_mtos_score;
        pk_alertlog.log_debug(g_error);
        RETURN pk_sev_scores_core.get_sev_score_screen(i_lang          => i_lang,
                                                       i_prof          => i_prof,
                                                       i_id_mtos_score => i_id_mtos_score,
                                                       o_screen        => o_screen,
                                                       o_error         => o_error);
    END get_sev_score_screen;

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
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN pk_sev_scores_core.get_sev_score_viewer(i_lang,
                                                       i_prof,
                                                       i_mtos_score,
                                                       i_epis_mtos_score,
                                                       o_viewer,
                                                       o_title,
                                                       o_error);
    
    END get_sev_score_viewer;

    FUNCTION get_sev_score_plus
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
    BEGIN
    
        IF NOT pk_sev_scores_core.get_sev_score_plus(i_lang  => i_lang,
                                                     i_prof  => i_prof,
                                                     o_list  => o_list,
                                                     o_error => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_SEV_SCORE_PLUS',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        
    END get_sev_score_plus;

    FUNCTION get_sev_scores_ais
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_mtos_score IN mtos_score.id_mtos_score%TYPE,
        o_list          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
    BEGIN
    
        IF NOT pk_sev_scores_core.get_sev_scores_ais(i_lang          => i_lang,
                                                     i_prof          => i_prof,
                                                     i_id_mtos_score => i_id_mtos_score,
                                                     o_list          => o_list,
                                                     o_error         => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_SEV_SCORES_AIS',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_sev_scores_ais;

    FUNCTION get_sev_scores_minor
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_mtos_param IN mtos_param.id_mtos_param%TYPE,
        o_list          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
    BEGIN
    
        IF NOT pk_sev_scores_core.get_sev_scores_minor(i_lang          => i_lang,
                                                       i_prof          => i_prof,
                                                       i_id_mtos_param => i_id_mtos_param,
                                                       o_list          => o_list,
                                                       o_error         => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_SEV_SCORES_MINOR',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_sev_scores_minor;

    FUNCTION get_modified_total_score
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_mtos_score IN table_number,
        i_id_mtos_param IN table_number,
        i_extra_score   IN table_varchar,
        o_total         OUT NUMBER,
        o_error         OUT t_error_out
        
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
    
        IF NOT pk_sev_scores_core.get_modified_total_score(i_lang          => i_lang,
                                                           i_prof          => i_prof,
                                                           i_id_mtos_score => i_id_mtos_score,
                                                           i_id_mtos_param => i_id_mtos_param,
                                                           i_extra_score   => i_extra_score,
                                                           o_total         => o_total,
                                                           o_error         => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_MODIFIED_TOTAL_SCORE',
                                              o_error);
        
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        
    END get_modified_total_score;

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
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
    
        IF NOT pk_sev_scores_core.set_modified_score(i_lang               => i_lang,
                                                     i_prof               => i_prof,
                                                     i_id_episode         => i_id_episode,
                                                     i_id_patient         => i_id_patient,
                                                     i_epis_mtos_score    => i_epis_mtos_score,
                                                     i_id_mtos_score      => i_id_mtos_score,
                                                     i_id_mtos_param      => i_id_mtos_param,
                                                     i_extra_score        => i_extra_score,
                                                     i_flg_api            => i_flg_api,
                                                     o_id_epis_mtos_score => o_id_epis_mtos_score,
                                                     o_msg_error          => o_msg_error,
                                                     o_error              => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        IF i_flg_api = pk_alert_constant.g_no
           AND o_msg_error IS NULL
        THEN
            COMMIT;
        END IF;
    
        IF o_msg_error IS NOT NULL
        THEN
            ROLLBACK;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'SET_MODIFIED_SCORE',
                                              o_error);
        
            pk_alert_exceptions.reset_error_state();
            ROLLBACK;
            RETURN FALSE;
        
    END set_modified_score;

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
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
    
        IF NOT pk_sev_scores_core.get_modified_score(i_lang            => i_lang,
                                                     i_prof            => i_prof,
                                                     i_id_episode      => i_id_episode,
                                                     i_id_patient      => i_id_patient,
                                                     i_epis_mtos_score => i_epis_mtos_score,
                                                     o_mtos_score      => o_mtos_score,
                                                     o_total_score     => o_total_score,
                                                     o_error           => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_MODIFIED_SCORE',
                                              o_error);
            pk_types.open_my_cursor(o_mtos_score);
            pk_alert_exceptions.reset_error_state();
            ROLLBACK;
            RETURN FALSE;
        
    END get_modified_score;

BEGIN

    /* CAN'T TOUCH THIS */
    /* Who am I */
    pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    pk_alertlog.log_init(object_name => g_package);
END pk_sev_scores_api_ui;
/
