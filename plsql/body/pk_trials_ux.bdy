/*-- Last Change Revision: $Rev: 1877368 $*/
/*-- Last Change by: $Author: adriano.ferreira $*/
/*-- Date of last change: $Date: 2018-11-12 15:39:19 +0000 (seg, 12 nov 2018) $*/

CREATE OR REPLACE PACKAGE BODY pk_trials_ux IS

    -- Private variable declarations

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    /**********************************************************************************************
    * Retrieves the list of internal trials. This list excludes all the trials that 
    * have been canceled by the professionals.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_trials_list            array with the list of Trials
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/01/25
    **********************************************************************************************/
    FUNCTION get_trials_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_trials_list OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        alertlog.pk_alertlog.log_debug('PARAMS[ ]', g_package, 'GET_TRIALS_LIST');
    
        g_error := 'CALL PK_TRIALS.GET_TRIALS_LIST';
        IF NOT pk_trials.get_trials_list(i_lang        => i_lang,
                                         i_prof        => i_prof,
                                         o_trials_list => o_trials_list,
                                         o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_trials_list);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_trials_list);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_TRIALS_LIST',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_trials_list;
    --
    /**********************************************************************************************
    * Change the state of a given trial.
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_trial_id               ID trial
    * @param i_trial_status           New trial status
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/01/26
    **********************************************************************************************/
    FUNCTION set_internal_trial_state
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_trial_id     IN trial_hist.id_trial%TYPE,
        i_trial_status IN trial.flg_status%TYPE,
        o_status       OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF NOT pk_trials.set_internal_trial_state(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  i_trial_id     => i_trial_id,
                                                  i_trial_status => i_trial_status,
                                                  o_status       => o_status,
                                                  o_error        => o_error)
        THEN
            RAISE g_exception;
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
                                              i_function => 'SET_INTERNAL_TRIAL_STATE',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_internal_trial_state;

    /**********************************************************************************************
    * Retrieves the list of internal trials that are under responsability of a given professional
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_trials_list            array with the list of Trials
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/01/25
    **********************************************************************************************/
    FUNCTION get_my_internal_trials
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        o_trials_list   OUT pk_types.cursor_type,
        o_screen_labels OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        alertlog.pk_alertlog.log_debug('PARAMS[ i_prof.ID: ' || i_prof.id || ']', g_package, 'get_my_internal_trials');
    
        g_error := 'CALL pk_trials.get_my_internal_trials';
        IF NOT pk_trials.get_my_internal_trials(i_lang          => i_lang,
                                                i_prof          => i_prof,
                                                i_id_patient    => NULL,
                                                o_trials_list   => o_trials_list,
                                                o_screen_labels => o_screen_labels,
                                                o_error         => o_error)
        THEN
            RAISE g_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_trials_list);
            pk_types.open_my_cursor(o_screen_labels);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_trials_list);
            pk_types.open_my_cursor(o_screen_labels);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_MY_INTERNAL_TRIALS',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_my_internal_trials;
    --

    /**********************************************************************************************
    * Retrieves the list of internal trials that are under responsability of a given professional
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_trials_list            array with the list of Trials
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/01/25
    **********************************************************************************************/
    FUNCTION get_my_internal_trials
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_patient    IN patient.id_patient%TYPE,
        o_trials_list   OUT pk_types.cursor_type,
        o_screen_labels OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        alertlog.pk_alertlog.log_debug('PARAMS[ i_prof.ID: ' || i_prof.id || ']', g_package, 'get_my_internal_trials');
    
        g_error := 'CALL pk_trials.get_my_internal_trials';
        IF NOT pk_trials.get_my_internal_trials(i_lang          => i_lang,
                                                i_prof          => i_prof,
                                                i_id_patient    => i_id_patient,
                                                o_trials_list   => o_trials_list,
                                                o_screen_labels => o_screen_labels,
                                                o_error         => o_error)
        THEN
            RAISE g_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_trials_list);
            pk_types.open_my_cursor(o_screen_labels);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_trials_list);
            pk_types.open_my_cursor(o_screen_labels);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_MY_INTERNAL_TRIALS',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_my_internal_trials;
    /**********************************************************************************************
    * Retrieves the list Trials (internal and external) in which a patient is participating 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_patient             ID Patient
    * @param o_trials_int_list        array with the list of internal Trials
    * @param o_trials_ext_list        array with the list of external Trials
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/01/25
    **********************************************************************************************/
    FUNCTION get_pat_trials_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
        o_trials_int_list OUT pk_types.cursor_type,
        o_trials_ext_list OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        alertlog.pk_alertlog.log_debug('PARAMS[ i_id_patient :' || i_id_patient || ']', g_package, 'GET_TRIALS_LIST');
    
        g_error := 'CALL pk_trials.get_pat_trials_list';
        IF NOT pk_trials.get_pat_trials_list(i_lang            => i_lang,
                                             i_prof            => i_prof,
                                             i_id_patient      => i_id_patient,
                                             o_trials_int_list => o_trials_int_list,
                                             o_trials_ext_list => o_trials_ext_list,
                                             o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_trials_int_list);
            pk_types.open_my_cursor(o_trials_ext_list);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_trials_int_list);
            pk_types.open_my_cursor(o_trials_ext_list);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_PAT_TRIALS_LIST',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_pat_trials_list;
    --

    /**********************************************************************************************
    * Retrieves the information for a given external trial to edit.
    * If the i_id_trial parameter is NULL, the function returns only the labels to be used 
    * in the edit screen.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_trial               ID trial to edit, or NULL for trial creation
    * @param o_trial                  Information for the trial to edit
    * @param o_screen_labels          Labels for the edit screen
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/01/28
    **********************************************************************************************/
    FUNCTION get_external_trial_edit
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_trial      IN pat_trial.id_pat_trial%TYPE,
        o_trial         OUT pk_types.cursor_type,
        o_screen_labels OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_trial trial.id_trial%TYPE;
    BEGIN
    
        alertlog.pk_alertlog.log_debug('PARAMS[:i_id_trial:' || i_id_trial || ' ]',
                                       g_package,
                                       'GET_EXTERNAL_TRIAL_EDIT');
        --
        g_error := 'GET ID_TRIAL';
        IF i_id_trial IS NOT NULL
        THEN
            SELECT id_trial
              INTO l_id_trial
              FROM pat_trial pt
             WHERE pt.id_pat_trial = i_id_trial;
        END IF;
        g_error := 'CALL pk_trials.get_trial_edit';
        IF NOT pk_trials.get_trial_edit(i_lang          => i_lang,
                                        i_prof          => i_prof,
                                        i_id_trial      => l_id_trial,
                                        i_trial_type    => g_trial_f_trial_type_e,
                                        o_trial         => o_trial,
                                        o_screen_labels => o_screen_labels,
                                        o_error         => o_error)
        THEN
            RAISE g_exception;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_trial);
            pk_types.open_my_cursor(o_screen_labels);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_EXTERNAL_TRIAL_EDIT',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_external_trial_edit;
    --
    /**********************************************************************************************
    * Retrieves the information for a given internal trial to edit.
    * If the i_id_trial parameter is NULL, the function returns only the labels to be used 
    * in the edit screen.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_trial               ID trial to edit, or NULL for trial creation
    * @param o_trials_list            Information for the trial to edit
    * @param o_screen_labels          Labels for the edit screen
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/01/28
    **********************************************************************************************/
    FUNCTION get_internal_trial_edit
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_trial      IN trial.id_trial%TYPE,
        o_trial         OUT pk_types.cursor_type,
        o_screen_labels OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        alertlog.pk_alertlog.log_debug('PARAMS[:i_id_trial:' || i_id_trial || ' ]',
                                       g_package,
                                       'GET_INTERNAL_TRIAL_EDIT');
        --
        g_error := 'CALL pk_trials.get_trial_edit';
        IF NOT pk_trials.get_trial_edit(i_lang          => i_lang,
                                        i_prof          => i_prof,
                                        i_id_trial      => i_id_trial,
                                        i_trial_type    => g_trial_f_trial_type_i,
                                        o_trial         => o_trial,
                                        o_screen_labels => o_screen_labels,
                                        o_error         => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_trial);
            pk_types.open_my_cursor(o_screen_labels);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_INTERNAL_TRIAL_EDIT',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_internal_trial_edit;

    /**********************************************************************************************
    * Creates a new internal trial or edit an existing one. 
    * If the parameter i_trial_id is NULL we are creating new trials.
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_trial_id               ID trial
    * @param i_trial_name             trial name
    * @param i_trial_code             Trial code
    * @param i_trial_notes            Trial notes    
    * @param i_trial_status           Trial status
    * @param i_trial_responsibles     List of IDs of professionals responsible for this trial
    * @param i_dt_start               Trial start date    
    * @param i_dt_end                 Trial end date   
    * @param o_id_trial               ID of the created trial 
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/01/31
    **********************************************************************************************/
    FUNCTION set_internal_trial
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_trial_id           IN trial.id_trial%TYPE,
        i_trial_name         IN trial.name%TYPE,
        i_trial_code         IN trial.code%TYPE,
        i_trial_notes        IN trial.notes%TYPE,
        i_trial_status       IN trial.flg_status%TYPE DEFAULT 'A',
        i_trial_responsibles IN table_number,
        i_dt_start           IN VARCHAR2,
        i_dt_end             IN VARCHAR2,
        o_id_trial           OUT trial.id_trial%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        --Local Variables
        l_dt_start      trial.dt_start%TYPE := NULL;
        l_dt_end        trial.dt_end%TYPE := NULL;
        l_rows_out      table_varchar := table_varchar();
        l_id_trial_hist trial_hist.id_trial_hist%TYPE;
        l_id_trial      trial.id_trial%TYPE;
    
        --manage the professionals 
        l_cur_profs_list table_number := table_number();
        l_new_profs_list table_number := table_number();
    BEGIN
    
        alertlog.pk_alertlog.log_debug('PARAMS[ i_trial_name: ' || i_trial_name || ', i_trial_code: ' || i_trial_code ||
                                       ', i_trial_status: ' || i_trial_status || ' ]',
                                       g_package,
                                       'SET_INTERNAL_TRIAL');
        --
        g_error := 'CALL pk_trials.set_trial';
        IF NOT pk_trials.set_trial(i_lang               => i_lang,
                                   i_prof               => i_prof,
                                   i_trial_id           => i_trial_id,
                                   i_trial_name         => i_trial_name,
                                   i_trial_code         => i_trial_code,
                                   i_trial_notes        => i_trial_notes,
                                   i_trial_status       => i_trial_status,
                                   i_trial_responsibles => i_trial_responsibles,
                                   i_dt_start           => i_dt_start,
                                   i_dt_end             => i_dt_end,
                                   i_trial_type         => g_trial_f_trial_type_i,
                                   o_id_trial           => o_id_trial,
                                   o_id_trial_hist      => l_id_trial_hist,
                                   o_error              => o_error)
        THEN
            RAISE g_exception;
        END IF;
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_INTERNAL_TRIAL',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_internal_trial;

    /**********************************************************************************************
    * Creates a new internal trial or edit an existing one. 
    * If the parameter i_trial_id is NULL we are creating new trials.
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_trial_id               ID trial
    * @param i_trial_name             trial name
    * @param i_trial_code             Trial code
    * @param i_trial_notes            Trial notes    
    * @param i_trial_status           Trial status
    * @param i_trial_responsibles     List of IDs of professionals responsible for this trial
    * @param i_dt_start               Trial start date    
    * @param i_dt_end                 Trial end date   
    * @param o_id_trial               ID of the created trial 
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/01/31
    **********************************************************************************************/
    FUNCTION set_internal_trial
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_trial_id           IN trial.id_trial%TYPE,
        i_trial_name         IN trial.name%TYPE,
        i_trial_code         IN trial.code%TYPE,
        i_trial_notes        IN trial.notes%TYPE,
        i_trial_status       IN trial.flg_status%TYPE DEFAULT 'A',
        i_trial_responsibles IN table_number,
        i_dt_start           IN VARCHAR2,
        i_dt_end             IN VARCHAR2,
        i_pharma_code        IN trial.pharma_code%TYPE,
        i_pharma_name        IN trial.pharma_name%TYPE,
        o_id_trial           OUT trial.id_trial%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        --Local Variables
        l_dt_start      trial.dt_start%TYPE := NULL;
        l_dt_end        trial.dt_end%TYPE := NULL;
        l_rows_out      table_varchar := table_varchar();
        l_id_trial_hist trial_hist.id_trial_hist%TYPE;
        l_id_trial      trial.id_trial%TYPE;
    
        --manage the professionals 
        l_cur_profs_list table_number := table_number();
        l_new_profs_list table_number := table_number();
    BEGIN
    
        alertlog.pk_alertlog.log_debug('PARAMS[ i_trial_name: ' || i_trial_name || ', i_trial_code: ' || i_trial_code ||
                                       ', i_trial_status: ' || i_trial_status || ' ]',
                                       g_package,
                                       'SET_INTERNAL_TRIAL');
        --
        g_error := 'CALL pk_trials.set_trial';
        IF NOT pk_trials.set_trial(i_lang               => i_lang,
                                   i_prof               => i_prof,
                                   i_trial_id           => i_trial_id,
                                   i_trial_name         => i_trial_name,
                                   i_trial_code         => i_trial_code,
                                   i_trial_notes        => i_trial_notes,
                                   i_trial_status       => i_trial_status,
                                   i_trial_responsibles => i_trial_responsibles,
                                   i_dt_start           => i_dt_start,
                                   i_dt_end             => i_dt_end,
                                   i_trial_type         => g_trial_f_trial_type_i,
                                   i_pharma_code        => i_pharma_code,
                                   i_pharma_name        => i_pharma_name,
                                   o_id_trial           => o_id_trial,
                                   o_id_trial_hist      => l_id_trial_hist,
                                   o_error              => o_error)
        THEN
            RAISE g_exception;
        END IF;
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_INTERNAL_TRIAL',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_internal_trial;
    --

    /**********************************************************************************************
    * Creates a new external trial or edit an existing one. 
    * If the parameter i_trial_id is NULL we are creating new trials.
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_trial_id               ID trial
    * @param i_trial_name             trial name
    * @param i_trial_code             Trial code
    * @param i_trial_notes            Trial notes    
    * @param i_trial_status           Trial status
    * @param i_trial_responsibles     Text with the name of the responsible(s) for the trial
    * @param i_trial_resp_contact     Contact details for the responsible(s) for the trial    
    * @param i_dt_start               Trial start date    
    * @param i_dt_end                 Trial end date   
    * @param o_id_trial               ID of the created trial 
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/01/31
    **********************************************************************************************/
    FUNCTION set_external_trial
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_trial_id           IN trial.id_trial%TYPE,
        i_trial_name         IN trial.name%TYPE,
        i_trial_code         IN trial.code%TYPE,
        i_trial_notes        IN trial.notes%TYPE,
        i_trial_status       IN trial.flg_status%TYPE DEFAULT 'A',
        i_trial_responsibles IN VARCHAR2,
        i_trial_resp_contact IN VARCHAR2,
        i_dt_start           IN VARCHAR2,
        i_dt_end             IN VARCHAR2,
        i_commit             IN VARCHAR2 DEFAULT 'Y',
        o_id_trial           OUT trial.id_trial%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        --Local Variables
        l_id_trial_hist trial_hist.id_trial_hist%TYPE;
    BEGIN
    
        alertlog.pk_alertlog.log_debug('PARAMS[ i_trial_name: ' || i_trial_name || ', i_trial_code: ' || i_trial_code ||
                                       ', i_trial_status: ' || i_trial_status || ' ]',
                                       g_package,
                                       'SET_EXTERNAL_TRIAL');
        --
        g_error := 'CALL pk_trials.set_trial';
        IF NOT pk_trials.set_trial(i_lang               => i_lang,
                                   i_prof               => i_prof,
                                   i_trial_id           => i_trial_id,
                                   i_trial_name         => i_trial_name,
                                   i_trial_code         => i_trial_code,
                                   i_trial_notes        => i_trial_notes,
                                   i_trial_status       => i_trial_status,
                                   i_trial_responsibles => table_number(),
                                   i_trial_resp_ext     => i_trial_responsibles,
                                   i_trial_resp_cont    => i_trial_resp_contact,
                                   i_dt_start           => i_dt_start,
                                   i_dt_end             => i_dt_end,
                                   i_trial_type         => g_trial_f_trial_type_e,
                                   i_commit             => pk_alert_constant.g_no,
                                   o_id_trial           => o_id_trial,
                                   o_id_trial_hist      => l_id_trial_hist,
                                   o_error              => o_error)
        THEN
            RAISE g_exception;
        END IF;
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_EXTERNAL_TRIAL',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_external_trial;
    --

    /**********************************************************************************************
    * Set the internal trials in which the patient is paticipating
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_patient                ID patient
    * @param i_id_episode             ID episode    
    * @param i_trials_id              array with internal trial IDs
    * @param i_dt_start               Trial start date    
    * @param i_dt_end                 Trial end date  
    * @param o_pat_trial_ids          array with the created pat trials 
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/01/25
    **********************************************************************************************/
    FUNCTION set_pat_internal_trials
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_patient    IN patient.id_patient%TYPE,
        i_id_episode    IN episode.id_episode%TYPE,
        i_trials_ids    IN table_number,
        i_dt_start      IN VARCHAR2,
        i_dt_end        IN VARCHAR2,
        o_pat_trial_ids OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rows_out     table_varchar := table_varchar();
        l_pat_trial_id pat_trial.id_pat_trial%TYPE;
    
        l_dt_start      trial.dt_start%TYPE := NULL;
        l_dt_end        trial.dt_end%TYPE := NULL;
        l_pat_trial_ids table_number := table_number();
    BEGIN
    
        alertlog.pk_alertlog.log_debug('PARAMS[ i_id_patient: ' || i_id_patient || ' ]',
                                       g_package,
                                       'SET_PAT_INTERNAL_TRIALS');
        --
    
        IF NOT pk_trials.set_pat_internal_trials(i_lang          => i_lang,
                                                 i_prof          => i_prof,
                                                 i_id_patient    => i_id_patient,
                                                 i_id_episode    => i_id_episode,
                                                 i_trials_ids    => i_trials_ids,
                                                 i_dt_start      => i_dt_start,
                                                 i_dt_end        => i_dt_end,
                                                 o_pat_trial_ids => o_pat_trial_ids,
                                                 o_error         => o_error)
        THEN
            RAISE g_exception;
        END IF;
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_PAT_INTERNAL_TRIALS',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_pat_internal_trials;
    --

    /**********************************************************************************************
    * Create an external trials in which the patient is paticipating
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_patient                ID patient
    * @param i_id_episode             ID episode
    * @param i_id_pat_trial           ID pat_trial
    * @param i_trial_name             trial name
    * @param i_trial_code             Trial code
    * @param i_trial_notes            Trial notes    
    * @param i_trial_responsibles     Text with the name of the responsible(s) for the trial
    * @param i_trial_resp_contact     Contact details for the responsible(s) for the trial    
    * @param i_dt_start               Trial start date    
    * @param i_dt_end                 Trial end date   
    * @param i_trials_id              array with internal trial IDs
    * @param o_pat_trial_ids          array with the created pat trials 
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/01/31
    **********************************************************************************************/
    FUNCTION set_pat_external_trials
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_pat_trial       IN pat_trial.id_pat_trial%TYPE,
        i_trial_name         IN trial.name%TYPE,
        i_trial_code         IN trial.code%TYPE,
        i_trial_notes        IN trial.notes%TYPE,
        i_trial_responsibles IN trial.responsible%TYPE DEFAULT NULL,
        i_trial_resp_cont    IN trial.resp_contact_det%TYPE DEFAULT NULL,
        i_dt_start           IN VARCHAR2,
        i_dt_end             IN VARCHAR2,
        o_pat_trial_id       OUT pat_trial.id_pat_trial%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rows_out table_varchar := table_varchar();
        l_trial_id pat_trial.id_pat_trial%TYPE;
    
        l_dt_start trial.dt_start%TYPE := NULL;
        l_dt_end   trial.dt_end%TYPE := NULL;
    BEGIN
    
        alertlog.pk_alertlog.log_debug('PARAMS[ i_id_patient: ' || i_id_patient || 'i_trial_name: ' || i_trial_name || ' ]',
                                       g_package,
                                       'SET_PAT_EXTERNAL_TRIALS');
    
        g_error := 'CALL pk_trials.set_pat_external_trials';
        IF NOT pk_trials.set_pat_external_trials(i_lang               => i_lang,
                                                 i_prof               => i_prof,
                                                 i_id_patient         => i_id_patient,
                                                 i_id_episode         => i_id_episode,
                                                 i_id_pat_trial       => i_id_pat_trial,
                                                 i_trial_name         => i_trial_name,
                                                 i_trial_code         => i_trial_code,
                                                 i_trial_notes        => i_trial_notes,
                                                 i_trial_responsibles => i_trial_responsibles,
                                                 i_trial_resp_cont    => i_trial_resp_cont,
                                                 i_dt_start           => i_dt_start,
                                                 i_dt_end             => i_dt_end,
                                                 o_pat_trial_id       => o_pat_trial_id,
                                                 o_error              => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_PAT_EXTERNAL_TRIALS',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_pat_external_trials;
    --

    /**********************************************************************************************
    * Cancel internal trials .
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_trial_id               ID trial
    * @param i_notes                  Cancel notes
    * @param i_cancel_reason          ID Cancel reason    
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/01/27
    **********************************************************************************************/
    FUNCTION cancel_internal_trial
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_trial_id      IN trial_hist.id_trial%TYPE,
        i_notes         IN cancel_info_det.notes_cancel_short%TYPE,
        i_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        --Local Variables
        l_rows_out           table_varchar := table_varchar();
        l_id_trial_hist      trial_hist.id_trial_hist%TYPE;
        l_cancel_info_det_id cancel_info_det.id_cancel_info_det%TYPE;
        l_num                NUMBER;
        l_exception EXCEPTION;
    BEGIN
    
        alertlog.pk_alertlog.log_debug('PARAMS[:i_trial_id:' || i_trial_id || ' ]', g_package, 'CANCEL_INTERNAL_TRIAL');
    
        g_error := 'CALL pk_trials.cancel_internal_trial';
        IF NOT pk_trials.inactivate_internal_trial(i_lang          => i_lang,
                                                   i_prof          => i_prof,
                                                   i_trial_id      => i_trial_id,
                                                   i_notes         => i_notes,
                                                   i_flg_status    => g_trial_f_status_c,
                                                   i_cancel_reason => i_cancel_reason,
                                                   o_error         => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'CANCEL_INTERNAL_TRIAL',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_internal_trial;
    --

    /**********************************************************************************************
    * Gets the list of professionals that can be responsible for internal trials.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_prof_list              list of professionals 
    * @param o_cat_list               list of possible categories    
    * @param o_screen_labels          Labels    
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/01/27
    **********************************************************************************************/
    FUNCTION get_responsibles_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        o_prof_list     OUT pk_types.cursor_type,
        o_cat_list      OUT pk_types.cursor_type,
        o_screen_labels OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        alertlog.pk_alertlog.log_debug('PARAMS[:i_prof.INSTITUTION:' || i_prof.institution || ' ]',
                                       g_package,
                                       'GET_RESPONSIBLES_LIST');
        --
        IF NOT pk_trials.get_responsibles_list(i_lang          => i_lang,
                                               i_prof          => i_prof,
                                               o_prof_list     => o_prof_list,
                                               o_cat_list      => o_cat_list,
                                               o_screen_labels => o_screen_labels,
                                               o_error         => o_error)
        THEN
            RAISE g_exception;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_prof_list);
            pk_types.open_my_cursor(o_cat_list);
            pk_types.open_my_cursor(o_screen_labels);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_RESPONSIBLES_LIST',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_responsibles_list;
    --

    /**********************************************************************************************
    * Retrieves the list of follow ups for a given patient's trial.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_trials_list            array with the list of Trials
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/01/25
    **********************************************************************************************/
    FUNCTION get_trial_follow_up_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_pat_trial   IN pat_trial.id_pat_trial%TYPE,
        o_follow_up_list OUT pk_types.cursor_type,
        o_screen_labels  OUT pk_types.cursor_type,
        o_trial_desc     OUT trial.name%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        alertlog.pk_alertlog.log_debug('PARAMS[ i_id_pat_trial:' || i_id_pat_trial || ']',
                                       g_package,
                                       'GET_TRIAL_FOLLOW_UP_LIST');
        g_error := 'CALL pk_trials.get_trial_follow_up_list';
        IF NOT pk_trials.get_trial_follow_up_list(i_lang           => i_lang,
                                                  i_prof           => i_prof,
                                                  i_id_pat_trial   => i_id_pat_trial,
                                                  o_follow_up_list => o_follow_up_list,
                                                  o_screen_labels  => o_screen_labels,
                                                  o_trial_desc     => o_trial_desc,
                                                  o_error          => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_follow_up_list);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_TRIAL_FOLLOW_UP_LIST',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_trial_follow_up_list;

    /**********************************************************************************************
    * Create or edit a follow up associated with a given patient internal Trial
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_patient                ID patient
    * @param id_pat_trial_follow_up   ID trial follow up
    * @param i_id_pat_trial           ID pat_trial
    * @param i_follow_up_notes        Follow_up_notes 
    * @param o_id_pat_trial_follow_up Follow up ID for the created follow up 
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/02/01
    **********************************************************************************************/
    FUNCTION set_pat_trial_follow_up
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_patient             IN patient.id_patient%TYPE,
        i_id_episode             IN episode.id_episode%TYPE,
        i_id_pat_trial_follow_up IN pat_trial_follow_up.id_pat_trial_follow_up%TYPE,
        i_id_pat_trial           IN pat_trial.id_pat_trial%TYPE,
        i_follow_up_notes        IN pat_trial_follow_up.notes%TYPE,
        o_id_pat_trial_follow_up OUT pat_trial_follow_up.id_pat_trial_follow_up%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        alertlog.pk_alertlog.log_debug('PARAMS[ i_id_patient: ' || i_id_patient || 'i_id_pat_trial_follow_up: ' ||
                                       i_id_pat_trial_follow_up || ' i_id_episode:' || i_id_episode || ']',
                                       g_package,
                                       'SET_PAT_TRIAL_FOLLOW_UP');
        --
        IF NOT pk_trials.set_pat_trial_follow_up(i_lang                   => i_lang,
                                                 i_prof                   => i_prof,
                                                 i_id_patient             => i_id_patient,
                                                 i_id_episode             => i_id_episode,
                                                 i_id_pat_trial_follow_up => i_id_pat_trial_follow_up,
                                                 i_id_pat_trial           => i_id_pat_trial,
                                                 i_follow_up_notes        => i_follow_up_notes,
                                                 o_id_pat_trial_follow_up => o_id_pat_trial_follow_up,
                                                 o_error                  => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_PAT_TRIAL_FOLLOW_UP',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_pat_trial_follow_up;
    --

    /**********************************************************************
    * Returns all professionals associated with a given list of categories
    * for an institution
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_categories             array with categories
    * @param i_institution            ID institution 
    * @param o_profs                  list of professionals 
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/02/01
    **********************************************************************************************/
    FUNCTION get_cat_prof_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_categories  IN table_number,
        i_institution IN institution.id_institution%TYPE,
        o_profs       OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL pk_trials.get_cat_prof_list';
        IF NOT pk_trials.get_cat_prof_list(i_lang        => i_lang,
                                           i_prof        => i_prof,
                                           i_categories  => i_categories,
                                           i_institution => i_institution,
                                           o_profs       => o_profs,
                                           o_error       => o_error)
        THEN
            RAISE g_exception;
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
                                              i_function => 'GET_CAT_PROF_LIST',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_profs);
            RETURN FALSE;
    END get_cat_prof_list;

    /**********************************************************************************************
    * Cancel patient trials .
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_id_pat_trial           ID patient trial
    * @param i_notes                  Cancel notes
    * @param i_cancel_reason          ID Cancel reason    
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/02/04
    **********************************************************************************************/
    FUNCTION cancel_patient_trial
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_pat_trial  IN pat_trial.id_pat_trial%TYPE,
        i_notes         IN cancel_info_det.notes_cancel_short%TYPE,
        i_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        --Local Variables
        l_rows_out           table_varchar := table_varchar();
        l_id_pat_trial_hist  pat_trial_hist.id_pat_trial_hist%TYPE;
        l_cancel_info_det_id cancel_info_det.id_cancel_info_det%TYPE;
    
    BEGIN
    
        alertlog.pk_alertlog.log_debug('PARAMS[:i_id_pat_trial:' || i_id_pat_trial || ' ]',
                                       g_package,
                                       'CANCEL_PATIENT_TRIAL');
    
        g_error := 'CALL pk_trials.cancel_patient_trial ';
        IF NOT pk_trials.cancel_patient_trial(i_lang          => i_lang,
                                              i_prof          => i_prof,
                                              i_id_pat_trial  => i_id_pat_trial,
                                              i_notes         => i_notes,
                                              i_cancel_reason => i_cancel_reason,
                                              o_error         => o_error)
        THEN
            RAISE g_exception;
        END IF;
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'CANCEL_INTERNAL_TRIAL',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_patient_trial;

    /**********************************************************************
    * Get patient trial create button available actions.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient                ID patient
    * @param o_actions      actions cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Elisabete Bugalho
    * @version              2.6.1
    * @since                2011/02/04
    **********************************************************************************************/
    FUNCTION get_create_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_actions OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'OPEN o_actions';
        IF NOT pk_trials.get_create_list(i_lang,
                                         i_prof    => i_prof,
                                         i_patient => i_patient,
                                         o_actions => o_actions,
                                         o_error   => o_error)
        THEN
            RAISE g_exception;
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
                                              i_function => 'GET_CREATE_LIST',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_actions);
            RETURN FALSE;
    END get_create_list;

    FUNCTION get_create_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_actions OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'OPEN o_actions';
        IF NOT pk_trials.get_create_list(i_lang,
                                         i_prof    => i_prof,
                                         i_patient => NULL,
                                         o_actions => o_actions,
                                         o_error   => o_error)
        THEN
            RAISE g_exception;
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
                                              i_function => 'GET_CREATE_LIST',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_actions);
            RETURN FALSE;
    END get_create_list;
    /**********************************************************************************************
    * Conclude the patient trial
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_pat_trial    id patient trial
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Elisabete Bugalho
    * @version              2.6.1
    * @since                2011/02/04
    **********************************************************************************************/
    FUNCTION conclude_pat_trial
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_pat_trial IN table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_trials.set_pat_trial_status';
        IF NOT pk_trials.set_pat_trial_status(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_id_pat_trial => i_id_pat_trial,
                                              i_flg_status   => g_pat_trial_f_status_f,
                                              o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'CONCLUDE_PAT_TRIAL',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END conclude_pat_trial;

    /**********************************************************************************************
    * Descontinue the patient trial
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_pat_trial    id patient trial
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Elisabete Bugalho
    * @version              2.6.1
    * @since                2011/02/08
    **********************************************************************************************/
    FUNCTION descontinue_pat_trial
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_pat_trial  IN table_number,
        i_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes  IN cancel_info_det.notes_cancel_short%TYPE,
        
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_trials.set_pat_trial_status';
        IF NOT pk_trials.set_pat_trial_status_cancel(i_lang          => i_lang,
                                                     i_prof          => i_prof,
                                                     i_id_pat_trial  => i_id_pat_trial,
                                                     i_flg_status    => g_pat_trial_f_status_d,
                                                     i_cancel_reason => i_cancel_reason,
                                                     i_cancel_notes  => i_cancel_notes,
                                                     o_error         => o_error)
        THEN
            RAISE g_exception;
        END IF;
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'DESCONTINUE_PAT_TRIAL',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END descontinue_pat_trial;

    /**********************************************************************************************
    * Descontinue the patient trial
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_pat_trial    id patient trial
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Elisabete Bugalho
    * @version              2.6.1
    * @since                2011/02/08
    **********************************************************************************************/
    FUNCTION discontinue_pat_trial
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_pat_trial  IN table_number,
        i_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes  IN cancel_info_det.notes_cancel_short%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_trials.set_pat_trial_status';
        IF NOT pk_trials.set_pat_trial_status_cancel(i_lang          => i_lang,
                                                     i_prof          => i_prof,
                                                     i_id_pat_trial  => i_id_pat_trial,
                                                     i_flg_status    => g_pat_trial_f_status_d,
                                                     i_cancel_reason => i_cancel_reason,
                                                     i_cancel_notes  => i_cancel_notes,
                                                     o_error         => o_error)
        THEN
            RAISE g_exception;
        END IF;
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'DISCONTINUE_PAT_TRIAL',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END discontinue_pat_trial;

    /**********************************************************************************************
    * Suspend the patient trial
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_pat_trial    id patient trial
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Elisabete Bugalho
    * @version              2.6.1
    * @since                2011/02/08
    **********************************************************************************************/
    FUNCTION hold_pat_trial
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_pat_trial  IN table_number,
        i_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes  IN cancel_info_det.notes_cancel_short%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_trials.set_pat_trial_status';
        IF NOT pk_trials.set_pat_trial_status_cancel(i_lang          => i_lang,
                                                     i_prof          => i_prof,
                                                     i_id_pat_trial  => i_id_pat_trial,
                                                     i_flg_status    => g_pat_trial_f_status_h,
                                                     i_cancel_reason => i_cancel_reason,
                                                     i_cancel_notes  => i_cancel_notes,
                                                     o_error         => o_error)
        THEN
            RAISE g_exception;
        END IF;
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'HOLD_PAT_TRIAL',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END hold_pat_trial;

    /**********************************************************************************************
    * Resume the patient trial
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_pat_trial    id patient trial
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Elisabete Bugalho
    * @version              2.6.1
    * @since                2011/02/08
    **********************************************************************************************/
    FUNCTION resume_pat_trial
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_pat_trial IN table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_trials.set_pat_trial_status';
        IF NOT pk_trials.set_pat_trial_status(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_id_pat_trial => i_id_pat_trial,
                                              i_flg_status   => g_pat_trial_f_status_r,
                                              o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'RESUME_PAT_TRIAL',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END resume_pat_trial;
    /**********************************************************************************************
    * Gets the detail of a trial
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_trial     id  trial
    * @param o_trial        trial cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Elisabete Bugalho
    * @version              2.6.1
    * @since                2011/02/07
    **********************************************************************************************/
    FUNCTION get_trial_detail
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_trial IN trial.id_trial%TYPE,
        o_trial    OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'CALL pk_trials.get_trial_detail';
        IF NOT pk_trials.get_trial_detail(i_lang     => i_lang,
                                          i_prof     => i_prof,
                                          i_id_trial => i_id_trial,
                                          o_trial    => o_trial,
                                          o_error    => o_error)
        THEN
            RAISE g_exception;
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
                                              i_function => 'GET_TRIAL_DETAIL',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_trial);
            RETURN FALSE;
        
    END get_trial_detail;

    /**********************************************************************************************
    * Gets the detail history of a trial
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_trial     id  trial
    * @param o_trial        trial cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Elisabete Bugalho
    * @version              2.6.1
    * @since                2011/02/07
    **********************************************************************************************/
    FUNCTION get_trial_detail_hist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_trial   IN trial.id_trial%TYPE,
        o_trial      OUT pk_types.cursor_type,
        o_trial_hist OUT table_table_varchar,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_trials.get_trial_detail_hist';
        IF NOT pk_trials.get_trial_detail_hist(i_lang       => i_lang,
                                               i_prof       => i_prof,
                                               i_id_trial   => i_id_trial,
                                               o_trial      => o_trial,
                                               o_trial_hist => o_trial_hist,
                                               o_error      => o_error)
        THEN
            RAISE g_exception;
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
                                              i_function => 'GET_TRIAL_DETAIL_HIST',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_trial);
            RETURN FALSE;
        
    END get_trial_detail_hist;

    /**********************************************************************************************
    * Gets the detail of a patient trial
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_trial     id  trial
    * @param o_trial        trial cursor
    * @param o_followup      cursor with followup
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Elisabete Bugalho
    * @version              2.6.1
    * @since                2011/02/09
    **********************************************************************************************/
    FUNCTION get_pat_trial_detail
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_pat_trial   IN pat_trial.id_pat_trial%TYPE,
        o_trial          OUT pk_types.cursor_type,
        o_followup_title OUT pk_types.cursor_type,
        o_followup       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL pk_trials.get_pat_trial_detail';
        IF NOT pk_trials.get_pat_trial_detail(i_lang           => i_lang,
                                              i_prof           => i_prof,
                                              i_id_pat_trial   => i_id_pat_trial,
                                              o_trial          => o_trial,
                                              o_followup_title => o_followup_title,
                                              o_followup       => o_followup,
                                              o_error          => o_error)
        THEN
            RAISE g_exception;
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
                                              i_function => 'GET_PAT_TRIAL_DETAIL',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_trial);
            pk_types.open_my_cursor(o_followup);
            RETURN FALSE;
        
    END get_pat_trial_detail;

    /**********************************************************************************************
    * Gets the detail history of a trial
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_pat_trial id  PAT trial
    * @param o_trial        trial cursor
    * @param o_followup     follow up notes
    * @param o_trial_hist   trial hist cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Elisabete Bugalho
    * @version              2.6.1
    * @since                2011/02/07
    **********************************************************************************************/
    FUNCTION get_pat_trial_detail_hist
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_pat_trial IN trial.id_trial%TYPE,
        o_trial        OUT pk_types.cursor_type,
        o_followup     OUT pk_types.cursor_type,
        o_trial_hist   OUT table_table_varchar,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'CALL pk_trials.get_pat_trial_detail_hist';
        IF NOT pk_trials.get_pat_trial_detail_hist(i_lang         => i_lang,
                                                   i_prof         => i_prof,
                                                   i_id_pat_trial => i_id_pat_trial,
                                                   o_trial        => o_trial,
                                                   o_followup     => o_followup,
                                                   o_trial_hist   => o_trial_hist,
                                                   o_error        => o_error)
        THEN
            RAISE g_exception;
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
                                              i_function => 'GET_TRIAL_DETAIL_HIST',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_trial);
            pk_types.open_my_cursor(o_followup);
            RETURN FALSE;
        
    END get_pat_trial_detail_hist;

    /**********************************************************************************************
     * Gets the detail of a patient trial for viewer
     *
     * @param i_lang         language identifier
     * @param i_prof         logged professional structure
     * @param i_id_trial     id  trial
     * @param o_trial        trial cursor
    * @param o_responsible  cursor with responsibles
     * @param o_error        error
     *
     * @return               false if errors occur, true otherwise
     *
     * @author               Elisabete Bugalho
     * @version              2.6.1
     * @since                2011/02/09
     **********************************************************************************************/
    FUNCTION get_trials_details_viewer
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_pat_trial IN table_number,
        o_trial        OUT pk_types.cursor_type,
        o_responsible  OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL pk_trials.get_pat_trial_detail_viewer';
        IF NOT pk_trials.get_trials_details(i_lang         => i_lang,
                                            i_prof         => i_prof,
                                            i_id_pat_trial => i_id_pat_trial,
                                            o_trial        => o_trial,
                                            o_responsible  => o_responsible,
                                            o_error        => o_error)
        THEN
            RAISE g_exception;
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
                                              i_function => 'GET_TRIAL_DETAIL_HIST',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_trial);
            pk_types.open_my_cursor(o_responsible);
        
            RETURN FALSE;
        
    END get_trials_details_viewer;

    /**********************************************************************************************
    * Retrieves the information for a given follow up.
    * If the i_id_pat_trial_follow_up parameter is NULL, the function returns only the labels to be used 
    * in the edit screen.
    *
    * @param i_lang                    the id language
    * @param i_prof                    professional, software and institution ids
    * @param i_id_pat_trial_follow_up  ID follow up to edit, or NULL for follow  creation
    * @param o_follow_up               Information for the follow up to edit
    * @param o_screen_labels           Labels for the edit screen
    * @param o_error                   Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/02/10
    **********************************************************************************************/
    FUNCTION get_pat_trial_follow_up_edit
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_pat_trial_follow_up IN pat_trial_follow_up.id_pat_trial_follow_up%TYPE,
        o_follow_up              OUT pk_types.cursor_type,
        o_screen_labels          OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        alertlog.pk_alertlog.log_debug('PARAMS[:i_id_pat_trial_follow_up:' || i_id_pat_trial_follow_up || ' ]',
                                       g_package,
                                       'GET_PAT_TRIAL_FOLLOW_UP_EDIT');
    
        g_error := 'CALL pk_trials.get_pat_trial_follow_up_edit';
        IF NOT pk_trials.get_pat_trial_follow_up_edit(i_lang                   => i_lang,
                                                      i_prof                   => i_prof,
                                                      i_id_pat_trial_follow_up => i_id_pat_trial_follow_up,
                                                      o_follow_up              => o_follow_up,
                                                      o_screen_labels          => o_screen_labels,
                                                      o_error                  => o_error)
        THEN
            RAISE g_exception;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_follow_up);
            pk_types.open_my_cursor(o_screen_labels);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_PAT_TRIAL_FOLLOW_UP_EDIT',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_pat_trial_follow_up_edit;

    /**********************************************************************************************
    * Gets the detail of a patient trial
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_pat_trial_follow_up id  pat trial follow up
    * @param o_followup               cursor with followup
    * @param o_error                  error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Elisabete Bugalho
    * @version              2.6.1
    * @since                2011/02/10
    **********************************************************************************************/
    FUNCTION get_follow_up_detail
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_pat_trial_follow_up IN pat_trial_follow_up.id_pat_trial_follow_up%TYPE,
        o_followup               OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'CALL pk_trials.get_follow_up_detail';
        IF NOT pk_trials.get_follow_up_detail(i_lang                   => i_lang,
                                              i_prof                   => i_prof,
                                              i_id_pat_trial_follow_up => i_id_pat_trial_follow_up,
                                              o_followup               => o_followup,
                                              o_error                  => o_error)
        THEN
            RAISE g_exception;
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
                                              i_function => 'GET_FOLLOW_UP_DETAIL',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_followup);
            RETURN FALSE;
        
    END get_follow_up_detail;

    /**********************************************************************************************
    * Gets the detail history of a trial
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_trial     id  trial
    * @param o_trial        trial cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Elisabete Bugalho
    * @version              2.6.1
    * @since                2011/02/07
    **********************************************************************************************/
    FUNCTION get_followup_det_hist
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_follow_up  IN pat_trial_follow_up.id_pat_trial_follow_up%TYPE,
        o_followup      OUT pk_types.cursor_type,
        o_followup_hist OUT table_table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_trials.get_followup_det_hist';
        IF NOT pk_trials.get_followup_det_hist(i_lang          => i_lang,
                                               i_prof          => i_prof,
                                               i_id_follow_up  => i_id_follow_up,
                                               o_followup      => o_followup,
                                               o_followup_hist => o_followup_hist,
                                               o_error         => o_error)
        THEN
            RAISE g_exception;
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
                                              i_function => 'GET_FOLLOWUP_DET_HIST',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_followup);
            RETURN FALSE;
        
    END get_followup_det_hist;

    /**********************************************************************************************
    * Cancel patient follow up trials .
    *
    * @param i_lang                      Id language
    * @param i_prof                      Professional, software and institution ids
    * @param i_id_pat_trial_follow_up    ID Follow up
    * @param i_notes                     Cancel notes
    * @param i_cancel_reason             ID Cancel reason    
    * @param o_error                     Error message
    *
    * @return                            TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/02/10
    **********************************************************************************************/
    FUNCTION cancel_follow_up_trial
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_pat_trial_follow_up IN pat_trial_follow_up.id_pat_trial_follow_up%TYPE,
        i_notes                  IN cancel_info_det.notes_cancel_short%TYPE,
        i_cancel_reason          IN cancel_reason.id_cancel_reason%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_trials.cancel_follow_up_trial';
        IF NOT pk_trials.cancel_follow_up_trial(i_lang                   => i_lang,
                                                i_prof                   => i_prof,
                                                i_id_pat_trial_follow_up => i_id_pat_trial_follow_up,
                                                i_notes                  => i_notes,
                                                i_cancel_reason          => i_cancel_reason,
                                                o_error                  => o_error)
        THEN
            RAISE g_exception;
        END IF;
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'CANCEL_FOLLOW_UP_TRIAL',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_follow_up_trial;
    /**********************************************************************************************
    * Get actions for patient trials
    *
    * @param i_lang              Id language
    * @param i_prof              Professional, software and institution ids
    * @param i_subject           Subject of action
    * @param i_from_state        Array of status of trials
    * @param i_pat_trial         Array of patient trials
    * @param o_actions           Cursor with available actions    
    * @param o_error             Error message
    *
    * @return                    TRUE if sucess, FALSE otherwise
    *                        
    * @author                    Elisabete Bugalho
    * @version                   1.0
    * @since                     2011/02/16
    **********************************************************************************************/
    FUNCTION get_actions_permissions
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_subject    IN action.subject%TYPE,
        i_from_state IN table_varchar,
        i_pat_trial  IN table_number,
        o_actions    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_trials.get_actions_permissions';
        IF NOT pk_trials.get_actions_permissions(i_lang       => i_lang,
                                                 i_prof       => i_prof,
                                                 i_subject    => i_subject,
                                                 i_from_state => i_from_state,
                                                 i_pat_trial  => i_pat_trial,
                                                 o_actions    => o_actions,
                                                 o_error      => o_error)
        THEN
        
            RAISE g_exception;
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
                                              i_function => 'GET_ACTIONS_PERMISSIONS',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_actions_permissions;

    /**********************************************************************************************
    * Check if theres is any schedule for a trial 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_patient             ID Patient
    * @param i_pat_trial              list of patien trials
    * @param i_flg_status             status os trials (H / D / F / R)
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/03/24
    **********************************************************************************************/

    FUNCTION check_scheduled_trial
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_pat_trial  IN table_number,
        i_flg_status IN pat_trial.flg_status%TYPE,
        o_flg_show   OUT VARCHAR2,
        o_msg_title  OUT VARCHAR2,
        o_msg        OUT VARCHAR2,
        o_buttons    OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'CALL check_scheduled_trial';
        IF NOT pk_trials.check_scheduled_trial(i_lang       => i_lang,
                                               i_prof       => i_prof,
                                               i_id_patient => i_id_patient,
                                               i_pat_trial  => i_pat_trial,
                                               i_flg_status => i_flg_status,
                                               o_flg_show   => o_flg_show,
                                               o_msg_title  => o_msg_title,
                                               o_msg        => o_msg,
                                               o_buttons    => o_buttons,
                                               o_error      => o_error)
        THEN
            RAISE g_exception;
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
                                              i_function => 'CHECK_SCHEDULED_TRIAL',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END check_scheduled_trial;

    /**********************************************************************************************
    * Discontinue internal trials .
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_trial_id               ID trial
    * @param i_notes                  Cancel notes
    * @param i_cancel_reason          ID Cancel reason    
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/04/06
    **********************************************************************************************/
    FUNCTION discontinue_internal_trial
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_trial_id      IN trial_hist.id_trial%TYPE,
        i_notes         IN cancel_info_det.notes_cancel_short%TYPE,
        i_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        --Local Variables
        l_rows_out           table_varchar := table_varchar();
        l_id_trial_hist      trial_hist.id_trial_hist%TYPE;
        l_cancel_info_det_id cancel_info_det.id_cancel_info_det%TYPE;
        l_num                NUMBER;
        l_exception EXCEPTION;
    BEGIN
    
        alertlog.pk_alertlog.log_debug('PARAMS[:i_trial_id:' || i_trial_id || ' ]',
                                       g_package,
                                       'DISCONTINUE_INTERNAL_TRIAL');
    
        g_error := 'CALL pk_trials.cancel_internal_trial';
        IF NOT pk_trials.inactivate_internal_trial(i_lang          => i_lang,
                                                   i_prof          => i_prof,
                                                   i_trial_id      => i_trial_id,
                                                   i_notes         => i_notes,
                                                   i_flg_status    => g_trial_f_status_d,
                                                   i_cancel_reason => i_cancel_reason,
                                                   o_error         => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'DISCONTINUE_INTERNAL_TRIAL',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END discontinue_internal_trial;
BEGIN
    -- Initialization

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_trials_ux;
/
