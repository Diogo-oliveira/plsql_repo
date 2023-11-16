CREATE OR REPLACE PACKAGE BODY pk_icnp_fo_api_db IS

    --------------------------------------------------------------------------------
    -- GLOBAL VARIABLES
    --------------------------------------------------------------------------------

    -- Identifes the owner in the log mechanism
    g_package_owner pk_icnp_type.t_package_owner;

    -- Identifes the package in the log mechanism
    g_package_name pk_icnp_type.t_package_name;

    -- Text that briefly describes the current operation
    g_current_operation pk_icnp_type.t_current_operation;

    --------------------------------------------------------------------------------
    -- METHODS [DEBUG]
    --------------------------------------------------------------------------------

    /*
     * Wrapper of the method from the alertlog mechanism that creates a debug log 
     * message.
     *
     * @param i_text Text to log.
     * @param i_func_name Function / procedure name.
     *
     * @author Luis Oliveira
     * @version 1.0
     * @since 25/Jul/2011
    */
    PROCEDURE log_debug
    (
        i_text      VARCHAR2,
        i_func_name VARCHAR2
    ) IS
    BEGIN
        pk_alertlog.log_debug(text => i_text, object_name => g_package_name, sub_object_name => i_func_name);
    END log_debug;

    --------------------------------------------------------------------------------
    -- METHODS [INIT]
    --------------------------------------------------------------------------------

    /**
     * Executes all the instructions needed to correctly initialize the package.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 03/Jun/2011
    */
    PROCEDURE initialize IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'initialize';
    
    BEGIN
        -- Initializes the log mechanism
        g_package_owner := 'ALERT';
        g_package_name  := pk_alertlog.who_am_i;
        pk_alertlog.log_init(g_package_name);
    
        -- Log message
        log_debug(c_func_name || '()', c_func_name);
    END;

    --------------------------------------------------------------------------------
    -- METHODS [WRAPPERS - ONLY USED INTERNALLY]
    --------------------------------------------------------------------------------

    /**
     * Updates the dates of the first and last clinical interactions within this 
     * episode.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_episode The episode identifier.
     * @param i_patient The patient identifier.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 17/Ago/2011
    */
    PROCEDURE set_first_obs
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN icnp_epis_intervention.id_episode%TYPE,
        i_patient      IN icnp_epis_intervention.id_patient%TYPE,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'set_first_obs';
        l_error t_error_out;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => i_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => i_sysdate_tstz,
                                      i_dt_first_obs        => i_sysdate_tstz,
                                      o_error               => l_error)
        THEN
            pk_icnp_util.raise_unexpected_error('pk_visit.set_first_obs', l_error);
        END IF;
    
    END;

    /**
     * Delete the alerts associated to the given set of interventions.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_interv_ids The set of interventions identifiers whose alerts should be
     *                     deleted.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 17/Ago/2011
    */
    PROCEDURE delete_intervs_alert
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_interv_ids IN table_number
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'delete_intervs_alert';
        l_error t_error_out;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Delete the alerts associated to the given set of interventions
        FOR i IN i_interv_ids.first .. i_interv_ids.last
        LOOP
            IF NOT pk_alerts.delete_sys_alert_event(i_lang         => i_lang,
                                                    i_prof         => i_prof,
                                                    i_id_sys_alert => pk_icnp_constant.g_icnp_alert,
                                                    i_id_record    => i_interv_ids(i),
                                                    o_error        => l_error)
            THEN
                pk_icnp_util.raise_unexpected_error('pk_alerts.delete_sys_alert_event', l_error);
            END IF;
        END LOOP;
    
    END;

    /**
     * Delete the alert associated with the intervention.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_epis_interv_id The identifier of the intervention whose alert should be
     *                         deleted.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 17/Ago/2011
    */
    PROCEDURE delete_interv_alert
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_interv_id IN icnp_epis_intervention.id_icnp_epis_interv%TYPE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'delete_intervs_alert';
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Delete the alert associated with the intervention
        delete_intervs_alert(i_lang => i_lang, i_prof => i_prof, i_interv_ids => table_number(i_epis_interv_id));
    
    END;

    --------------------------------------------------------------------------------
    -- METHODS [CREATE INTERV]
    --------------------------------------------------------------------------------

    /**
     * Create an ICNP intervention: given a set of diagnosis,
     * interventions and it's instructions, set them to the specified
     * patient.
     *
     * @param i_lang         language identifier
     * @param i_prof         logged professional structure
     * @param i_episode      episode identifier
     * @param i_patient      patient identifier
     * @param i_diag         diagnosis identifiers list
     * @param i_exp_res      expected results identifiers list
     * @param i_notes        diagnosis notes list
     * @param i_interv       intervention identifiers and instructions list
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * @param o_interv_id    created icnp_epis_intervention ids
     *
     * @author               Pedro Carneiro
     * @version               2.5.1
     * @since                2010/07/20
    */
    PROCEDURE create_icnp_interv
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN icnp_epis_intervention.id_episode%TYPE,
        i_patient      IN icnp_epis_intervention.id_patient%TYPE,
        i_diag         IN table_number,
        i_exp_res      IN table_number,
        i_notes        IN table_varchar,
        i_interv       IN table_table_varchar,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_interv_id    OUT table_number
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'CREATE_ICNP_INTERV';
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Creates the intervetions, diagnosis and corresponding associations
        pk_icnp_fo.create_icnp_interv(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_episode      => i_episode,
                                      i_patient      => i_patient,
                                      i_diag         => i_diag,
                                      i_exp_res      => i_exp_res,
                                      i_notes        => i_notes,
                                      i_interv       => i_interv,
                                      i_cur_diag     => NULL,
                                      i_sysdate_tstz => i_sysdate_tstz,
                                      o_interv_id    => o_interv_id);
    
        -- Updates the dates of the first and last clinical interactions within this episode
        set_first_obs(i_lang         => i_lang,
                      i_prof         => i_prof,
                      i_episode      => i_episode,
                      i_patient      => i_patient,
                      i_sysdate_tstz => i_sysdate_tstz);
    
    END create_icnp_interv;

    /**
    * Creates interventions for "this episode", given the interventions
    * for the "next episode", set on a previous visit.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_past_episode past episode identifier
    * @param i_next_episode next episode identifier (the one being registered)
    * @param i_sysdate_tstz Current timestamp that should be used across all the 
    *                       functions invoked from this one.
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/08/19
    */
    PROCEDURE create_interv_next_epis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_past_episode IN episode.id_episode%TYPE,
        i_next_episode IN episode.id_episode%TYPE,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'CREATE_INTERV_NEXT_EPIS';
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Creates the intervetions, diagnosis and corresponding associations
        pk_icnp_fo.create_interv_next_epis(i_lang         => i_lang,
                                           i_prof         => i_prof,
                                           i_past_episode => i_past_episode,
                                           i_next_episode => i_next_episode,
                                           i_sysdate_tstz => i_sysdate_tstz);
    
        -- The set_first_obs shouldn't be invoked because this method is not called as a result 
        -- of a medical interaction.
    
    END create_interv_next_epis;

    --------------------------------------------------------------------------------
    -- METHODS [INTERVS AND DIAGS ASSOCIATION]
    --------------------------------------------------------------------------------

    /**
    * Associate diagnosis.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_patient      patient identifier
    * @param i_diag         diagnoses identifiers list
    * @param i_interv       interventions identifiers list
    * @param i_sysdate_tstz Current timestamp that should be used across all the 
    *                        functions invoked from this one.
    *
    * @author               Pedro Carneiro
    * @version              2.5.1
    * @since                2010/08/09
    */
    PROCEDURE set_assoc_diag
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_patient      IN patient.id_patient%TYPE,
        i_diag         IN table_number,
        i_interv       IN table_number,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'SET_ASSOC_DIAG';
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Makes the association
        pk_icnp_fo.set_assoc_diag(i_lang => i_lang, i_prof => i_prof, i_diag => i_diag, i_interv => i_interv);
    
        -- Updates the dates of the first and last clinical interactions within this episode
        set_first_obs(i_lang         => i_lang,
                      i_prof         => i_prof,
                      i_episode      => i_episode,
                      i_patient      => i_patient,
                      i_sysdate_tstz => i_sysdate_tstz);
    
    END set_assoc_diag;

    /**
    * Associate intervention.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_patient      patient identifier
    * @param i_diag         diagnosis identifier
    * @param i_interv       intervention identifiers and instructions list
    * @param o_interv_id    created icnp_epis_intervention ids
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/07/20
    */
    PROCEDURE set_assoc_interv
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_patient      IN patient.id_patient%TYPE,
        i_diag         IN icnp_epis_diagnosis.id_icnp_epis_diag%TYPE,
        i_interv       IN table_table_varchar,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_interv_id    OUT table_number
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'SET_ASSOC_INTERV';
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Makes the association
        pk_icnp_fo.set_assoc_interv(i_lang         => i_lang,
                                    i_prof         => i_prof,
                                    i_episode      => i_episode,
                                    i_patient      => i_patient,
                                    i_diag         => i_diag,
                                    i_interv       => i_interv,
                                    i_sysdate_tstz => i_sysdate_tstz,
                                    o_interv_id    => o_interv_id);
    
        -- Updates the dates of the first and last clinical interactions within this episode
        set_first_obs(i_lang         => i_lang,
                      i_prof         => i_prof,
                      i_episode      => i_episode,
                      i_patient      => i_patient,
                      i_sysdate_tstz => i_sysdate_tstz);
    
    END set_assoc_interv;

    --------------------------------------------------------------------------------
    -- METHODS [UPDATE INTERV STATUS]
    --------------------------------------------------------------------------------

    /**
     * Makes the necessary updates to a set of intervention records
     * (icnp_epis_intervention rows) when the user resolves the interventions. A
     * resolved intervention is considered completed, the user can't make any more
     * executions.
     *
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_episode The episode identifier.
     * @param i_patient The patient identifier.
     * @param i_interv_ids The set of identifiers of the interventions that we want
     *                     to resolve.
     * @param i_sysdate_tstz Current timestamp that should be used across all the
     *                       functions invoked from this one.
     *
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    PROCEDURE set_intervs_status_resolve
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN icnp_epis_intervention.id_episode%TYPE,
        i_patient      IN icnp_epis_intervention.id_patient%TYPE,
        i_interv_ids   IN table_number,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'SET_INTERVS_STATUS_RESOLVE';
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Check the input parameters
        IF pk_icnp_util.is_table_empty(i_interv_ids)
        THEN
            pk_alert_exceptions.raise_error(error_name_in => pk_icnp_constant.g_excep_inv_input_params,
                                            text_in       => 'The table with the intervention identifiers (i_interv_ids) given as input parameter is empty');
        END IF;
    
        -- Resolves the set of interventions
        pk_icnp_interv.set_intervs_status_resolve(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  i_interv_ids   => i_interv_ids,
                                                  i_sysdate_tstz => i_sysdate_tstz);
    
        -- Updates the dates of the first and last clinical interactions within this episode
        set_first_obs(i_lang         => i_lang,
                      i_prof         => i_prof,
                      i_episode      => i_episode,
                      i_patient      => i_patient,
                      i_sysdate_tstz => i_sysdate_tstz);
    
    END set_intervs_status_resolve;

    /**
     * Makes the necessary updates to a set of intervention records
     * (icnp_epis_intervention rows) when the user pauses the interventions. When
     * the intervention is paused no executions could be made, until the intervention
     * is resumed again. Under this circumstances we don't have the concept of
     * "next execution".
     *
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_episode The episode identifier.
     * @param i_patient The patient identifier.
     * @param i_interv_ids The set of identifiers of the interventions that we want
     *                     to pause.
     * @param i_suspend_reason Suspension reason identifier.
     * @param i_suspend_notes Notes describing the reason of the suspension.
     * @param i_sysdate_tstz Current timestamp that should be used across all the
     *                       functions invoked from this one.
     *
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    PROCEDURE set_intervs_status_pause
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN icnp_epis_intervention.id_episode%TYPE,
        i_patient        IN icnp_epis_intervention.id_patient%TYPE,
        i_interv_ids     IN table_number,
        i_suspend_reason IN icnp_epis_intervention.id_suspend_reason%TYPE,
        i_suspend_notes  IN icnp_epis_intervention.suspend_notes%TYPE,
        i_sysdate_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_force_status   IN VARCHAR2 DEFAULT 'N'
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'SET_INTERVS_STATUS_PAUSE';
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Check the input parameters
        IF pk_icnp_util.is_table_empty(i_interv_ids)
        THEN
            pk_alert_exceptions.raise_error(error_name_in => pk_icnp_constant.g_excep_inv_input_params,
                                            text_in       => 'The table with the intervention identifiers (i_interv_ids) given as input parameter is empty');
        END IF;
    
        -- Pauses the set of interventions
        pk_icnp_interv.set_intervs_status_pause(i_lang           => i_lang,
                                                i_prof           => i_prof,
                                                i_interv_ids     => i_interv_ids,
                                                i_suspend_reason => i_suspend_reason,
                                                i_suspend_notes  => i_suspend_notes,
                                                i_sysdate_tstz   => i_sysdate_tstz,
                                                i_force_status   => i_force_status);
    
        -- Updates the dates of the first and last clinical interactions within this episode
        set_first_obs(i_lang         => i_lang,
                      i_prof         => i_prof,
                      i_episode      => i_episode,
                      i_patient      => i_patient,
                      i_sysdate_tstz => i_sysdate_tstz);
    
    END set_intervs_status_pause;

    /**
     * Makes the necessary updates to a set of intervention records
     * (icnp_epis_intervention rows) when the user resumes the interventions. When
     * the intervention is resumed it goes again to its previous status before being
     * paused and the user is allowed to make executions again.
     *
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_episode The episode identifier.
     * @param i_patient The patient identifier.
     * @param i_interv_ids The set of identifiers of the interventions that we want
     *                     to resume.
     * @param i_sysdate_tstz Current timestamp that should be used across all the
     *                       functions invoked from this one.
     *
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    PROCEDURE set_intervs_status_resume
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN icnp_epis_intervention.id_episode%TYPE,
        i_patient      IN icnp_epis_intervention.id_patient%TYPE,
        i_interv_ids   IN table_number,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'SET_INTERVS_STATUS_RESUME';
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Check the input parameters
        IF pk_icnp_util.is_table_empty(i_interv_ids)
        THEN
            pk_alert_exceptions.raise_error(error_name_in => pk_icnp_constant.g_excep_inv_input_params,
                                            text_in       => 'The table with the intervention identifiers (i_interv_ids) given as input parameter is empty');
        END IF;
    
        -- Resumes the set of interventions
        pk_icnp_interv.set_intervs_status_resume(i_lang         => i_lang,
                                                 i_prof         => i_prof,
                                                 i_interv_ids   => i_interv_ids,
                                                 i_sysdate_tstz => i_sysdate_tstz);
    
        -- Updates the dates of the first and last clinical interactions within this episode
        set_first_obs(i_lang         => i_lang,
                      i_prof         => i_prof,
                      i_episode      => i_episode,
                      i_patient      => i_patient,
                      i_sysdate_tstz => i_sysdate_tstz);
    
    END set_intervs_status_resume;

    /**
     * Makes the necessary updates to a set of intervention records
     * (icnp_epis_intervention rows) when the user cancels the interventions. When
     * the intervention is cancelled the user can't make any more executions.
     *
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_episode The episode identifier.
     * @param i_patient The patient identifier.
     * @param i_interv_ids The set of identifiers of the interventions that we want
     *                     to cancel.
     * @param i_cancel_reason Cancellation reason identifier.
     * @param i_cancel_notes Notes describing the reason of the cancellation.
     * @param i_sysdate_tstz Current timestamp that should be used across all the
     *                       functions invoked from this one.
     *
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    PROCEDURE set_intervs_status_cancel
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN icnp_epis_intervention.id_episode%TYPE,
        i_patient       IN icnp_epis_intervention.id_patient%TYPE,
        i_interv_ids    IN table_number,
        i_cancel_reason IN icnp_epis_intervention.id_cancel_reason%TYPE,
        i_cancel_notes  IN icnp_epis_intervention.cancel_notes%TYPE,
        i_sysdate_tstz  IN TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'SET_INTERVS_STATUS_CANCEL';
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Check the input parameters
        IF pk_icnp_util.is_table_empty(i_interv_ids)
        THEN
            pk_alert_exceptions.raise_error(error_name_in => pk_icnp_constant.g_excep_inv_input_params,
                                            text_in       => 'The table with the intervention identifiers (i_interv_ids) given as input parameter is empty');
        END IF;
    
        FOR i IN 1 .. i_interv_ids.count
        LOOP
            -- Cancels the set of interventions             
            pk_icnp_interv.set_interv_status_cancel(i_lang           => i_lang,
                                                    i_prof           => i_prof,
                                                    i_epis_interv_id => i_interv_ids(i),
                                                    i_cancel_reason  => i_cancel_reason,
                                                    i_cancel_notes   => i_cancel_notes,
                                                    i_sysdate_tstz   => i_sysdate_tstz);
        
        END LOOP;
    
        -- Updates the dates of the first and last clinical interactions within this episode
        set_first_obs(i_lang         => i_lang,
                      i_prof         => i_prof,
                      i_episode      => i_episode,
                      i_patient      => i_patient,
                      i_sysdate_tstz => i_sysdate_tstz);
    
    END set_intervs_status_cancel;

    PROCEDURE set_intervs_status_finish
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN icnp_epis_intervention.id_episode%TYPE,
        i_patient      IN icnp_epis_intervention.id_patient%TYPE,
        i_interv_ids   IN table_number,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'SET_INTERVS_STATUS_FINISH';
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Check the input parameters
        IF pk_icnp_util.is_table_empty(i_interv_ids)
        THEN
            pk_alert_exceptions.raise_error(error_name_in => pk_icnp_constant.g_excep_inv_input_params,
                                            text_in       => 'The table with the intervention identifiers (i_interv_ids) given as input parameter is empty');
        END IF;
    
        FOR i IN 1 .. i_interv_ids.count
        LOOP
            -- Cancels the set of interventions             
            pk_icnp_interv.set_intervs_status_finish(i_lang         => i_lang,
                                                     i_prof         => i_prof,
                                                     i_interv_ids   => i_interv_ids,
                                                     i_sysdate_tstz => i_sysdate_tstz);
        
        END LOOP;
    
        -- Updates the dates of the first and last clinical interactions within this episode
        set_first_obs(i_lang         => i_lang,
                      i_prof         => i_prof,
                      i_episode      => i_episode,
                      i_patient      => i_patient,
                      i_sysdate_tstz => i_sysdate_tstz);
    
    END set_intervs_status_finish;

    /**
     * Makes the necessary updates to an intervention record (icnp_epis_intervention row)
     * when the user cancels an intervention. When the intervention is cancelled the user
     * can't make any more executions.
     *
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_episode The episode identifier.
     * @param i_patient The patient identifier.
     * @param i_epis_interv_id The identifier of the intervention that we want to cancel.
     * @param i_cancel_reason Cancellation reason identifier.
     * @param i_cancel_notes Notes describing the reason of the cancellation.
     * @param i_sysdate_tstz Current timestamp that should be used across all the
     *                       functions invoked from this one.
     *
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    PROCEDURE set_interv_status_cancel
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN icnp_epis_intervention.id_episode%TYPE,
        i_patient        IN icnp_epis_intervention.id_patient%TYPE,
        i_epis_interv_id IN icnp_epis_intervention.id_icnp_epis_interv%TYPE,
        i_cancel_reason  IN icnp_epis_intervention.id_cancel_reason%TYPE,
        i_cancel_notes   IN icnp_epis_intervention.cancel_notes%TYPE,
        i_sysdate_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'set_interv_status_cancel';
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Cancels the intervention given as input parameter
        set_intervs_status_cancel(i_lang          => i_lang,
                                  i_prof          => i_prof,
                                  i_episode       => i_episode,
                                  i_patient       => i_patient,
                                  i_interv_ids    => table_number(i_epis_interv_id),
                                  i_cancel_reason => i_cancel_reason,
                                  i_cancel_notes  => i_cancel_notes,
                                  i_sysdate_tstz  => i_sysdate_tstz);
    
    END set_interv_status_cancel;

    --------------------------------------------------------------------------------
    -- METHODS [UPDATE DIAG STATUS]
    --------------------------------------------------------------------------------

    /**
     * Makes the necessary updates to a set of diagnosis records (icnp_epis_diagnosis rows)
     * when the user reevaluates the diagnosis. When a diagose is reevaluated, the
     * old diagnose is replaced by a new one. Functionally it means that the patient
     * condition changed.
     *
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_episode The episode identifier.
     * @param i_patient The patient identifier.
     * @param i_diag_ids The set of diagnosis identifiers that we want to reeval.
     * @param i_composition_id The new diagnose that was determined in the reevaluation
     *                         process.
     * @param i_sysdate_tstz Current timestamp that should be used across all the
     *                       functions invoked from this one.
     *
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    PROCEDURE set_diags_status_reeval
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN icnp_epis_diagnosis.id_episode%TYPE,
        i_patient        IN icnp_epis_diagnosis.id_patient%TYPE,
        i_diag_ids       IN table_number,
        i_composition_id IN icnp_epis_diagnosis.id_composition%TYPE,
        i_sysdate_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_notes          IN table_varchar
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'SET_DIAGS_STATUS_REEVAL';
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Check the input parameters
        IF pk_icnp_util.is_table_empty(i_diag_ids)
        THEN
            pk_alert_exceptions.raise_error(error_name_in => pk_icnp_constant.g_excep_inv_input_params,
                                            text_in       => 'The table with diagnosis identifiers (i_diag_ids) given as input parameter is empty');
        END IF;
    
        -- Reevaluates the set of diagnosis
        pk_icnp_diag.set_diags_status_reeval(i_lang           => i_lang,
                                             i_prof           => i_prof,
                                             i_diag_ids       => i_diag_ids,
                                             i_composition_id => i_composition_id,
                                             i_sysdate_tstz   => i_sysdate_tstz,
                                             i_notes          => i_notes);
    
        -- Updates the dates of the first and last clinical interactions within this episode
        set_first_obs(i_lang         => i_lang,
                      i_prof         => i_prof,
                      i_episode      => i_episode,
                      i_patient      => i_patient,
                      i_sysdate_tstz => i_sysdate_tstz);
    
    END set_diags_status_reeval;

    /**
     * Makes the necessary updates to a set of diagnosis records (icnp_epis_diagnosis rows)
     * when the user resolves the diagnosis. Resolved is a final status, no more changes
     * to the record can be made. Additionally, it resolves all the intervention records that 
     * are related with the set of diagnosis (when the diagnosis are resolved the associated
     * interventions should be resolved too).
     *
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_episode The episode identifier.
     * @param i_patient The patient identifier.
     * @param i_diag_ids The set of diagnosis identifiers that we want to resolve.
     * @param i_sysdate_tstz Current timestamp that should be used across all the
     *                       functions invoked from this one.
     *
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    PROCEDURE set_diags_status_resolve
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN icnp_epis_diagnosis.id_episode%TYPE,
        i_patient      IN icnp_epis_diagnosis.id_patient%TYPE,
        i_diag_ids     IN table_number,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'SET_DIAGS_STATUS_RESOLVE';
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Check the input parameters
        IF pk_icnp_util.is_table_empty(i_diag_ids)
        THEN
            pk_alert_exceptions.raise_error(error_name_in => pk_icnp_constant.g_excep_inv_input_params,
                                            text_in       => 'The table with the diagnosis identifiers (i_diag_ids) given as input parameter is empty');
        END IF;
    
        -- Resolves the set of diagnosis
        pk_icnp_diag.set_diags_status_resolve(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_diag_ids     => i_diag_ids,
                                              i_sysdate_tstz => i_sysdate_tstz);
    
        -- Resolves the interventions that are associated with the given set of diagnosis
        pk_icnp_interv.set_interv_st_resol_for_diags(i_lang         => i_lang,
                                                     i_prof         => i_prof,
                                                     i_diag_ids     => i_diag_ids,
                                                     i_sysdate_tstz => i_sysdate_tstz);
    
        -- Updates the dates of the first and last clinical interactions within this episode
        set_first_obs(i_lang         => i_lang,
                      i_prof         => i_prof,
                      i_episode      => i_episode,
                      i_patient      => i_patient,
                      i_sysdate_tstz => i_sysdate_tstz);
    
    END set_diags_status_resolve;

    /**
     * Makes the necessary updates to a set of diagnosis records (icnp_epis_diagnosis rows)
     * when the user suspends the diagnosis. When a diagnose is suspended, no actions
     * (excluding the resume) could be performed. Additionally, it pauses all the 
     * intervention records that are related with the set of diagnosis (when the diagnosis 
     * are paused the associated interventions should be paused too).
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_episode The episode identifier.
     * @param i_patient The patient identifier.
     * @param i_diag_ids The set of diagnosis identifiers that we want to resolve.
     * @param i_suspend_reason Suspension reason identifier.
     * @param i_suspend_notes Notes describing the reason of the suspension.
     * @param i_sysdate_tstz Current timestamp that should be used across all the
     *                       functions invoked from this one.
     *
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    PROCEDURE set_diags_status_pause
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN icnp_epis_diagnosis.id_episode%TYPE,
        i_patient        IN icnp_epis_diagnosis.id_patient%TYPE,
        i_diag_ids       IN table_number,
        i_suspend_reason IN icnp_epis_diagnosis.id_suspend_reason%TYPE,
        i_suspend_notes  IN icnp_epis_diagnosis.suspend_notes%TYPE,
        i_sysdate_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_force_status   IN VARCHAR2 DEFAULT 'N'
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'SET_DIAGS_STATUS_PAUSE';
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Check the input parameters
        IF pk_icnp_util.is_table_empty(i_diag_ids)
        THEN
            pk_alert_exceptions.raise_error(error_name_in => pk_icnp_constant.g_excep_inv_input_params,
                                            text_in       => 'The table with the diagnosis identifiers (i_diag_ids) given as input parameter is empty');
        END IF;
    
        -- Pauses the set of diagnosis
        pk_icnp_diag.set_diags_status_pause(i_lang           => i_lang,
                                            i_prof           => i_prof,
                                            i_diag_ids       => i_diag_ids,
                                            i_suspend_reason => i_suspend_reason,
                                            i_suspend_notes  => i_suspend_notes,
                                            i_sysdate_tstz   => i_sysdate_tstz,
                                            i_force_status   => i_force_status);
    
        -- Pauses the interventions that are associated with the given set of diagnosis
        pk_icnp_interv.set_interv_st_pause_for_diags(i_lang           => i_lang,
                                                     i_prof           => i_prof,
                                                     i_diag_ids       => i_diag_ids,
                                                     i_suspend_reason => i_suspend_reason,
                                                     i_suspend_notes  => i_suspend_notes,
                                                     i_sysdate_tstz   => i_sysdate_tstz);
    
        -- Updates the dates of the first and last clinical interactions within this episode
        set_first_obs(i_lang         => i_lang,
                      i_prof         => i_prof,
                      i_episode      => i_episode,
                      i_patient      => i_patient,
                      i_sysdate_tstz => i_sysdate_tstz);
    
    END set_diags_status_pause;

    /**
     * Makes the necessary updates to a set of diagnosis records (icnp_epis_diagnosis rows)
     * when the user resumes the diagnosis. When the diagnose is resumed its status is
     * updated to active again, allowing the user to execute again action on the diagnosis,
     * like for example, reevaluate, resolve or cancel. Additionally, it resumes all the 
     * intervention records that are related with the set of diagnosis (when the diagnosis 
     * are resumed the associated interventions should be resumed too).
     *
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_episode The episode identifier.
     * @param i_patient The patient identifier.
     * @param i_diag_ids The set of diagnosis identifiers that we want to resolve.
     * @param i_sysdate_tstz Current timestamp that should be used across all the
     *                       functions invoked from this one.
     *
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    PROCEDURE set_diags_status_resume
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN icnp_epis_diagnosis.id_episode%TYPE,
        i_patient      IN icnp_epis_diagnosis.id_patient%TYPE,
        i_diag_ids     IN table_number,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'SET_DIAGS_STATUS_RESUME';
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Check the input parameters
        IF pk_icnp_util.is_table_empty(i_diag_ids)
        THEN
            pk_alert_exceptions.raise_error(error_name_in => pk_icnp_constant.g_excep_inv_input_params,
                                            text_in       => 'The table with the diagnosis identifiers (i_diag_ids) given as input parameter is empty');
        END IF;
    
        -- Resumes the set of diagnosis
        pk_icnp_diag.set_diags_status_resume(i_lang         => i_lang,
                                             i_prof         => i_prof,
                                             i_diag_ids     => i_diag_ids,
                                             i_sysdate_tstz => i_sysdate_tstz);
    
        -- Resumes the interventions that are associated with the given set of diagnosis
        pk_icnp_interv.set_interv_st_resume_for_diags(i_lang         => i_lang,
                                                      i_prof         => i_prof,
                                                      i_diag_ids     => i_diag_ids,
                                                      i_sysdate_tstz => i_sysdate_tstz);
    
        -- Updates the dates of the first and last clinical interactions within this episode
        set_first_obs(i_lang         => i_lang,
                      i_prof         => i_prof,
                      i_episode      => i_episode,
                      i_patient      => i_patient,
                      i_sysdate_tstz => i_sysdate_tstz);
    
    END set_diags_status_resume;

    /**
     * Makes the necessary updates to a set of diagnosis records (icnp_epis_diagnosis rows)
     * when the user cancels the diagnosis. When the diagnose is cancelled the user can't
     * make any more changes. Additionally, it cancels all the intervention records that 
     * are related with the set of diagnosis (when the diagnosis are cancelled the associated
     * interventions should be cancelled too).
     *
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_episode The episode identifier.
     * @param i_patient The patient identifier.
     * @param i_diag_ids The set of diagnosis identifiers that we want to resolve.
     * @param i_cancel_reason Cancellation reason identifier.
     * @param i_cancel_notes Notes describing the reason of the cancellation.
     * @param i_sysdate_tstz Current timestamp that should be used across all the
     *                       functions invoked from this one.
     *
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    PROCEDURE set_diags_status_cancel
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN icnp_epis_diagnosis.id_episode%TYPE,
        i_patient       IN icnp_epis_diagnosis.id_patient%TYPE,
        i_diag_ids      IN table_number,
        i_cancel_reason IN icnp_epis_diagnosis.id_cancel_reason%TYPE,
        i_cancel_notes  IN icnp_epis_diagnosis.cancel_notes%TYPE,
        i_sysdate_tstz  IN TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'SET_DIAGS_STATUS_CANCEL';
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Check the input parameters
        IF pk_icnp_util.is_table_empty(i_diag_ids)
        THEN
            pk_alert_exceptions.raise_error(error_name_in => pk_icnp_constant.g_excep_inv_input_params,
                                            text_in       => 'The table with the diagnosis identifiers (i_diag_ids) given as input parameter is empty');
        END IF;
    
        -- Cancels the set of diagnosis
        pk_icnp_diag.set_diags_status_cancel(i_lang          => i_lang,
                                             i_prof          => i_prof,
                                             i_diag_ids      => i_diag_ids,
                                             i_cancel_reason => i_cancel_reason,
                                             i_cancel_notes  => i_cancel_notes,
                                             i_sysdate_tstz  => i_sysdate_tstz);
    
        -- Cancels the interventions that are associated with the given set of diagnosis
        pk_icnp_interv.set_interv_st_cancel_for_diags(i_lang          => i_lang,
                                                      i_prof          => i_prof,
                                                      i_diag_ids      => i_diag_ids,
                                                      i_cancel_reason => i_cancel_reason,
                                                      i_cancel_notes  => i_cancel_notes,
                                                      i_sysdate_tstz  => i_sysdate_tstz);
    
        -- Updates the dates of the first and last clinical interactions within this episode
        set_first_obs(i_lang         => i_lang,
                      i_prof         => i_prof,
                      i_episode      => i_episode,
                      i_patient      => i_patient,
                      i_sysdate_tstz => i_sysdate_tstz);
    
    END set_diags_status_cancel;

    --------------------------------------------------------------------------------
    -- METHODS [CREATE EXEC]
    --------------------------------------------------------------------------------

    /**
     * Creates a set of execution records (icnp_interv_plan rows). Each record of 
     * the collection is a icnp_interv_plan row already with the data that should
     * be persisted in the database. This method is prepared to be used by the 
     * recurrence mechanism.
     *
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_exec_tab A collection with the execution order number and the planned 
     *                   date of execution.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * @param o_exec_to_process For each plan, indicates if there are more executions 
     *                          to be processed.
     * 
     * @value o_exec_to_process {*} 'Y' there are more executions to be processed {*} 'N' there are no more executions to be processed.
     *
     * @author Luis Oliveira
     * @version 1.1
     * @since 27/Jul/2011 (v2.6.1)
    */
    PROCEDURE create_executions
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_exec_tab        IN t_tbl_order_recurr_plan,
        i_sysdate_tstz    IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_exec_to_process OUT t_tbl_order_recurr_plan_sts
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'create_executions';
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Check the input parameters
        IF i_exec_tab IS NULL
           OR i_exec_tab.count = 0
        THEN
            pk_alert_exceptions.raise_error(error_name_in => pk_icnp_constant.g_excep_inv_input_params,
                                            text_in       => 'The table with the recurrence information (i_exec_tab) given as input parameter is empty');
        END IF;
    
        -- Create the executions
        pk_icnp_exec.create_executions(i_lang            => i_lang,
                                       i_prof            => i_prof,
                                       i_exec_tab        => i_exec_tab,
                                       i_sysdate_tstz    => i_sysdate_tstz,
                                       o_exec_to_process => o_exec_to_process);
    
        -- The set_first_obs shouldn't be invoked because this method is called from a job 
        -- managed by the recurrence mechanism
    
    END create_executions;

    /**
     * Wrapper that converts the procedure create_executions into a function. The error
     * details are returned in the o_error output parameter.
     * 
     * This wrapper was created because it is invoked from the job of the recurrence 
     * mechanism.
     * 
     * @see create_executions
     * @param o_error The details of the error, like for example: ora_sqlcode and 
     *                ora_sqlerrm.
     * 
     * @return TRUE if sucess, FALSE otherwise.
     *
     * @author Luis Oliveira
     * @version 1.1
     * @since 27/Jul/2011 (v2.6.1)
    */
    FUNCTION create_executions
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_exec_tab        IN t_tbl_order_recurr_plan,
        i_sysdate_tstz    IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_exec_to_process OUT t_tbl_order_recurr_plan_sts,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'create_executions';
        l_current_operation pk_icnp_type.t_current_operation;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        l_current_operation := 'calling create_executions function';
        create_executions(i_lang            => i_lang,
                          i_prof            => i_prof,
                          i_exec_tab        => i_exec_tab,
                          i_sysdate_tstz    => i_sysdate_tstz,
                          o_exec_to_process => o_exec_to_process);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_current_operation,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => c_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END create_executions;

    --------------------------------------------------------------------------------
    -- METHODS [UPDATE EXEC STATUS]
    --------------------------------------------------------------------------------

    /**
     * Makes the necessary updates to a set of execution records (icnp_interv_plan rows) 
     * when the user executes a non-template execution. If there are any pending alerts
     * they should be removed. The intervention status and the date of the next execution
     * must be updated.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_episode The episode identifier.
     * @param i_patient The patient identifier.
     * @param i_interv_ids The set of interventions identifiers: for each intervention
     *                     we get the next planned execution and an update is performed
     *                     to mark it as executed.
     * @param i_notes Notes with the details about the execution.
     * @param i_dt_take_tstz Timestamp that identifies the moment in time when the 
     *                       planned execution was effectively executed.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    PROCEDURE set_execs_status_execute
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN icnp_epis_intervention.id_episode%TYPE,
        i_patient           IN icnp_epis_intervention.id_patient%TYPE,
        i_interv_ids        IN table_number,
        i_notes             IN icnp_interv_plan.notes%TYPE,
        i_dt_take_tstz      IN icnp_interv_plan.dt_take_tstz%TYPE,
        i_dt_next_take_tstz IN pk_icnp_type.t_serialized_timestamp, --IN icnp_interv_plan.dt_take_tstz%TYPE,
        i_flg_change_next   IN VARCHAR2 DEFAULT 'N',
        i_sysdate_tstz      IN TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'set_execs_status_execute';
        l_exec_interv_coll pk_icnp_type.t_exec_interv_coll;
    
        l_order_recurr_desc   VARCHAR2(200);
        l_order_recurr_option order_recurr_plan.id_order_recurr_option%TYPE;
        l_start_date          order_recurr_plan.start_date%TYPE;
        l_occurrences         order_recurr_plan.occurrences%TYPE;
        l_duration            order_recurr_plan.duration%TYPE;
        l_unit_meas_duration  order_recurr_plan.id_unit_meas_duration%TYPE;
        l_end_date            order_recurr_plan.end_date%TYPE;
        l_duration_desc       VARCHAR2(200);
        l_flg_end_by_editable VARCHAR2(2);
        l_order_recurr_plan   order_recurr_plan.id_order_recurr_plan%TYPE;
        l_error               t_error_out;
        l_exception EXCEPTION;
        l_interv_id table_number;
    
        l_order_recurr_opt    order_recurr_plan.id_order_recurr_option%TYPE;
        l_order_recurr_area   order_recurr_plan.id_order_recurr_area%TYPE;
        l_id_icnp_epis_interv icnp_epis_intervention.id_icnp_epis_interv%TYPE;
        l_id_icnp_epis_diag   icnp_epis_diagnosis.id_icnp_epis_diag%TYPE;
        l_flg_time            icnp_epis_intervention.flg_time%TYPE;
        l_flg_prn             icnp_epis_intervention.flg_prn%TYPE;
        l_prn_notes           icnp_epis_intervention.prn_notes%TYPE;
        l_notes               icnp_epis_intervention.notes%TYPE;
        l_num_exec            NUMBER;
        l_dt_first_plan       icnp_interv_plan.dt_plan_tstz%TYPE;
        l_dt_last_plan        icnp_interv_plan.dt_plan_tstz%TYPE;
        l_time_past           NUMBER;
        l_time_left           NUMBER;
    
        updt_tb_varchar_interv table_varchar;
    
        l_flg_end_by order_recurr_plan.flg_end_by%TYPE;
    
        l_dt_next_take_tstz icnp_interv_plan.dt_take_tstz%TYPE;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        l_dt_next_take_tstz := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                             i_prof      => i_prof,
                                                             i_timestamp => i_dt_next_take_tstz,
                                                             i_timezone  => NULL);
    
        -- Check the input parameters
        IF pk_icnp_util.is_table_empty(i_interv_ids)
        THEN
            pk_alert_exceptions.raise_error(error_name_in => pk_icnp_constant.g_excep_inv_input_params,
                                            text_in       => 'The table with the intervention identifiers (i_interv_ids) given as input parameter is empty');
        END IF;
    
        -- Gets the next planned execution identifiers (for all the given interventions)
        l_exec_interv_coll := pk_icnp_interv.create_get_intvs_nextexec_data(i_lang         => i_lang,
                                                                            i_prof         => i_prof,
                                                                            i_interv_ids   => i_interv_ids,
                                                                            i_sysdate_tstz => i_sysdate_tstz);
    
        -- Mark the planned execution as executed
        pk_icnp_exec.set_execs_status_execute(i_lang             => i_lang,
                                              i_prof             => i_prof,
                                              i_exec_interv_coll => l_exec_interv_coll,
                                              i_notes            => i_notes,
                                              i_dt_take_tstz     => i_dt_take_tstz,
                                              i_sysdate_tstz     => i_sysdate_tstz);
    
        FOR i IN 1 .. l_exec_interv_coll.count
        LOOP
        
            IF i_flg_change_next = pk_alert_constant.g_yes
            THEN
            
                IF NOT pk_order_recurrence_api_db.get_order_recurr_instructions(i_lang                => i_lang,
                                                                                i_prof                => i_prof,
                                                                                i_order_plan          => l_exec_interv_coll(i).id_order_recurr_plan,
                                                                                o_order_recurr_desc   => l_order_recurr_desc,
                                                                                o_order_recurr_option => l_order_recurr_option,
                                                                                o_start_date          => l_start_date,
                                                                                o_occurrences         => l_occurrences,
                                                                                o_duration            => l_duration,
                                                                                o_unit_meas_duration  => l_unit_meas_duration,
                                                                                o_duration_desc       => l_duration_desc,
                                                                                o_end_date            => l_end_date,
                                                                                o_flg_end_by_editable => l_flg_end_by_editable,
                                                                                o_error               => l_error)
                THEN
                    RAISE l_exception;
                END IF;
            
                SELECT COUNT(*)
                  INTO l_num_exec
                  FROM icnp_interv_plan a
                 WHERE a.id_order_recurr_plan = l_exec_interv_coll(i).id_order_recurr_plan --a.id_icnp_epis_interv = l_exec_interv_coll(i).id_icnp_epis_interv
                   AND a.flg_status IN (pk_icnp_constant.g_icnp_cplan_status_active,
                                        pk_icnp_constant.g_icnp_cplan_status_inactive,
                                        pk_icnp_constant.g_icnp_cplan_status_cancelled);
            
                BEGIN
                    SELECT b.dt_plan_tstz
                      INTO l_dt_first_plan
                      FROM icnp_interv_plan b
                     WHERE b.id_icnp_epis_interv = l_exec_interv_coll(i).id_icnp_epis_interv
                       AND b.exec_number = 1
                       AND b.dt_plan_tstz IS NOT NULL;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_dt_first_plan := NULL;
                END;
            
                BEGIN
                    SELECT *
                      INTO l_dt_last_plan
                      FROM (SELECT b.dt_plan_tstz
                              FROM icnp_interv_plan b
                             WHERE b.id_icnp_epis_interv = l_exec_interv_coll(i).id_icnp_epis_interv
                               AND b.flg_status = pk_icnp_constant.g_interv_plan_status_requested
                             ORDER BY exec_number)
                     WHERE rownum = 1;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_dt_first_plan := NULL;
                END;
            
                l_time_left := extract(DAY FROM(l_dt_next_take_tstz - l_dt_last_plan)) * 24 * 60 * 60 +
                               extract(hour FROM(l_dt_next_take_tstz - l_dt_last_plan)) * 60 * 60 +
                               extract(minute FROM(l_dt_next_take_tstz - l_dt_last_plan)) * 60 +
                               extract(SECOND FROM(l_dt_next_take_tstz - l_dt_last_plan));
            
                SELECT iei.id_icnp_epis_interv,
                       iedi.id_icnp_epis_diag,
                       iei.flg_time,
                       iei.flg_prn,
                       iei.prn_notes,
                       iei.notes,
                       orp.id_order_recurr_option,
                       orp.id_order_recurr_area
                  INTO l_id_icnp_epis_interv,
                       l_id_icnp_epis_diag,
                       l_flg_time,
                       l_flg_prn,
                       l_prn_notes,
                       l_notes,
                       l_order_recurr_opt,
                       l_order_recurr_area
                  FROM icnp_epis_intervention iei
                 INNER JOIN icnp_epis_diag_interv iedi
                    ON iei.id_icnp_epis_interv = iedi.id_icnp_epis_interv
                  LEFT JOIN order_recurr_plan orp
                    ON orp.id_order_recurr_plan = iei.id_order_recurr_plan
                 WHERE iei.id_icnp_epis_interv = l_exec_interv_coll(i).id_icnp_epis_interv;
            
                SELECT orp.flg_end_by
                  INTO l_flg_end_by
                  FROM order_recurr_plan orp
                 WHERE orp.id_order_recurr_plan = l_exec_interv_coll(i).id_order_recurr_plan;
            
                IF NOT pk_order_recurrence_core.edit_order_recurr_plan(i_lang                   => i_lang,
                                                                       i_prof                   => i_prof,
                                                                       i_order_recurr_area      => l_order_recurr_area,
                                                                       i_order_recurr_option    => l_order_recurr_opt,
                                                                       i_start_date             => l_dt_next_take_tstz,
                                                                       i_occurrences            => CASE l_occurrences
                                                                                                       WHEN NULL THEN
                                                                                                        NULL
                                                                                                       ELSE
                                                                                                        (l_occurrences -
                                                                                                        l_num_exec)
                                                                                                   END,
                                                                       i_duration               => NULL,
                                                                       i_unit_meas_duration     => NULL,
                                                                       i_end_date               => CASE l_flg_end_by
                                                                                                       WHEN 'N' THEN
                                                                                                        l_end_date +
                                                                                                        numtodsinterval(l_time_left,
                                                                                                                        'second')
                                                                                                       ELSE
                                                                                                        l_end_date
                                                                                                   END,
                                                                       i_order_recurr_plan_from => l_exec_interv_coll(i).id_order_recurr_plan,
                                                                       o_order_recurr_desc      => l_order_recurr_desc,
                                                                       o_order_recurr_option    => l_order_recurr_option,
                                                                       o_start_date             => l_start_date,
                                                                       o_occurrences            => l_occurrences,
                                                                       o_duration               => l_duration,
                                                                       o_unit_meas_duration     => l_unit_meas_duration,
                                                                       o_end_date               => l_end_date,
                                                                       o_flg_end_by_editable    => l_flg_end_by_editable,
                                                                       o_order_recurr_plan      => l_order_recurr_plan,
                                                                       o_error                  => l_error)
                THEN
                    RAISE l_exception;
                END IF;
            
                updt_tb_varchar_interv := table_varchar(l_id_icnp_epis_interv,
                                                        l_id_icnp_epis_diag,
                                                        l_flg_time,
                                                        i_dt_next_take_tstz,
                                                        l_exec_interv_coll(i).id_order_recurr_plan,
                                                        l_flg_prn,
                                                        l_prn_notes,
                                                        l_notes,
                                                        NULL,
                                                        l_order_recurr_plan);
            
                pk_icnp_fo.update_icnp_interv(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_interv       => updt_tb_varchar_interv,
                                              i_sysdate_tstz => i_sysdate_tstz,
                                              i_origin       => pk_icnp_constant.g_interv_plan_executing,
                                              o_interv_id    => l_interv_id);
            
                pk_icnp_fo.updt_icnp_plan(i_lang => i_lang, i_prof => i_prof, i_interv => updt_tb_varchar_interv);
            
            END IF;
        
        END LOOP;
    
        -- Updates the status and the next execution date (for all the given interventions)
        pk_icnp_interv.update_intervs_stat_and_dtnext(i_lang         => i_lang,
                                                      i_prof         => i_prof,
                                                      i_interv_ids   => i_interv_ids,
                                                      i_action       => pk_icnp_constant.g_action_interv_exec,
                                                      i_sysdate_tstz => i_sysdate_tstz);
    
        -- :TODO: update ICNP_EPIS_DIAGNOSIS.FLG_EXECUTIONS field (is this really needed?)
    
        -- Delete the alerts associated to the given interventions
        delete_intervs_alert(i_lang => i_lang, i_prof => i_prof, i_interv_ids => i_interv_ids);
    
        -- Updates the dates of the first and last clinical interactions within this episode
        set_first_obs(i_lang         => i_lang,
                      i_prof         => i_prof,
                      i_episode      => i_episode,
                      i_patient      => i_patient,
                      i_sysdate_tstz => i_sysdate_tstz);
    
    END set_execs_status_execute;

    /**
     * Makes the necessary updates to a set of execution records (icnp_interv_plan rows) 
     * when the user executes a execution using a template. If there are any pending alerts
     * they should be removed. The intervention status and the date of the next execution
     * must be updated.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_episode The episode identifier.
     * @param i_patient The patient identifier.
     * @param i_epis_interv_id The identifier of the intervention that we want to execute. 
     * @param i_epis_documentation_id Identifier of the template record where the execution
     *                                was documented.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    PROCEDURE set_exec_status_execute_doc
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN icnp_epis_intervention.id_episode%TYPE,
        i_patient               IN icnp_epis_intervention.id_patient%TYPE,
        i_epis_interv_id        IN icnp_epis_intervention.id_icnp_epis_interv%TYPE,
        i_epis_documentation_id IN icnp_interv_plan.id_epis_documentation%TYPE,
        i_sysdate_tstz          IN TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'set_exec_status_execute_doc';
        l_exec_interv_rec pk_icnp_type.t_exec_interv_rec;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Gets the next planned execution identifier (for the given intervention)
        l_exec_interv_rec := pk_icnp_interv.create_get_intv_nextexec_data(i_lang           => i_lang,
                                                                          i_prof           => i_prof,
                                                                          i_epis_interv_id => i_epis_interv_id,
                                                                          i_sysdate_tstz   => i_sysdate_tstz);
    
        -- Mark the planned execution as executed
        pk_icnp_exec.set_exec_status_execute_doc(i_lang                  => i_lang,
                                                 i_prof                  => i_prof,
                                                 i_exec_interv_rec       => l_exec_interv_rec,
                                                 i_epis_documentation_id => i_epis_documentation_id,
                                                 i_sysdate_tstz          => i_sysdate_tstz);
    
        -- Updates the status and the next execution date of the intervention
        pk_icnp_interv.update_interv_stat_and_dtnext(i_lang           => i_lang,
                                                     i_prof           => i_prof,
                                                     i_epis_interv_id => i_epis_interv_id,
                                                     i_action         => pk_icnp_constant.g_action_interv_exec,
                                                     i_sysdate_tstz   => i_sysdate_tstz);
    
        -- :TODO: update ICNP_EPIS_DIAGNOSIS.FLG_EXECUTIONS field (is this really needed?)
    
        -- Delete the alert associated with the intervention
        delete_interv_alert(i_lang => i_lang, i_prof => i_prof, i_epis_interv_id => i_epis_interv_id);
    
        -- Updates the dates of the first and last clinical interactions within this episode
        set_first_obs(i_lang         => i_lang,
                      i_prof         => i_prof,
                      i_episode      => i_episode,
                      i_patient      => i_patient,
                      i_sysdate_tstz => i_sysdate_tstz);
    
    END set_exec_status_execute_doc;

    /**
     * Makes the necessary updates to a set of execution records (icnp_interv_plan rows)
     * when the user executes a non-template execution with vital signs. If there are any 
     * pending alerts they should be removed. The intervention status and the date of the 
     * next execution must be updated.
     *
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_episode The episode identifier.
     * @param i_patient The patient identifier.
     * @param i_prof_cat The category of the logged professional.
     * @param i_epis_interv_id The identifier of the intervention that we want to execute.
     * @param i_notes Notes with the details about the execution.
     * @param i_dt_take_tstz Timestamp that identifies the moment in time when the
     *                       planned execution was effectively executed.
     * @param i_vs_id Collection of read vital signs identifiers.
     * @param i_vs_val Collection with the measured values of each vital sign.
     * @param i_vs_unit_mea Collection with the identifiers of the unit measure used
     *                      for each vital sign read.
     * @param i_vs_scl_elem Collection with the identifiers of the scale used to
     *                      measure the pain vital sign. When other vital signs are
     *                      read, the collection element should be null.
     * @param i_vs_notes The notes written while reading the vital signs.
     * @param i_sysdate_tstz Current timestamp that should be used across all the
     *                       functions invoked from this one.
     * @param i_vs_dt        Collection with the clinical date of the unit measure used
     *                       for each vital sign read.
     *
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    PROCEDURE set_exec_status_execute_vs
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN icnp_epis_intervention.id_episode%TYPE,
        i_patient           IN icnp_epis_intervention.id_patient%TYPE,
        i_prof_cat          IN category.flg_type%TYPE,
        i_epis_interv_id    IN icnp_epis_intervention.id_icnp_epis_interv%TYPE,
        i_notes             IN icnp_interv_plan.notes%TYPE,
        i_dt_take_tstz      IN icnp_interv_plan.dt_take_tstz%TYPE,
        i_vs_id             IN table_number,
        i_vs_val            IN table_number,
        i_vs_unit_mea       IN table_number,
        i_vs_scl_elem       IN table_number,
        i_vs_notes          IN vital_sign_notes.notes%TYPE,
        i_sysdate_tstz      IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_vs_dt             IN table_varchar,
        i_dt_next_take_tstz IN pk_icnp_type.t_serialized_timestamp, --IN icnp_interv_plan.dt_take_tstz%TYPE,
        i_flg_change_next   IN VARCHAR2 DEFAULT 'N'
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'set_exec_status_execute_vs';
        l_exec_interv_rec pk_icnp_type.t_exec_interv_rec;
    
        l_order_recurr_desc   VARCHAR2(200);
        l_order_recurr_option order_recurr_plan.id_order_recurr_option%TYPE;
        l_start_date          order_recurr_plan.start_date%TYPE;
        l_occurrences         order_recurr_plan.occurrences%TYPE;
        l_duration            order_recurr_plan.duration%TYPE;
        l_unit_meas_duration  order_recurr_plan.id_unit_meas_duration%TYPE;
        l_end_date            order_recurr_plan.end_date%TYPE;
        l_duration_desc       VARCHAR2(200);
        l_flg_end_by_editable VARCHAR2(2);
        l_error               t_error_out;
        l_exception EXCEPTION;
        l_num_exec            NUMBER;
        l_dt_first_plan       icnp_interv_plan.dt_plan_tstz%TYPE;
        l_dt_last_plan        icnp_interv_plan.dt_plan_tstz%TYPE;
        l_time_left           NUMBER;
        l_order_recurr_opt    order_recurr_plan.id_order_recurr_option%TYPE;
        l_order_recurr_area   order_recurr_plan.id_order_recurr_area%TYPE;
        l_id_icnp_epis_interv icnp_epis_intervention.id_icnp_epis_interv%TYPE;
        l_id_icnp_epis_diag   icnp_epis_diagnosis.id_icnp_epis_diag%TYPE;
        l_flg_time            icnp_epis_intervention.flg_time%TYPE;
        l_flg_prn             icnp_epis_intervention.flg_prn%TYPE;
        l_prn_notes           icnp_epis_intervention.prn_notes%TYPE;
        l_notes               icnp_epis_intervention.notes%TYPE;
        l_flg_end_by          order_recurr_plan.flg_end_by%TYPE;
        l_order_recurr_plan   order_recurr_plan.id_order_recurr_plan%TYPE;
    
        updt_tb_varchar_interv table_varchar;
        l_interv_id            table_number;
        l_dt_next_take_tstz    icnp_interv_plan.dt_take_tstz%TYPE;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        l_dt_next_take_tstz := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                             i_prof      => i_prof,
                                                             i_timestamp => i_dt_next_take_tstz,
                                                             i_timezone  => NULL);
    
        -- Gets the next planned execution identifiers (for the given intervention)
        l_exec_interv_rec := pk_icnp_interv.create_get_intv_nextexec_data(i_lang           => i_lang,
                                                                          i_prof           => i_prof,
                                                                          i_epis_interv_id => i_epis_interv_id,
                                                                          i_sysdate_tstz   => i_sysdate_tstz);
        -- Mark the planned execution as executed
        pk_icnp_exec.set_exec_status_execute_vs(i_lang            => i_lang,
                                                i_prof            => i_prof,
                                                i_episode         => i_episode,
                                                i_patient         => i_patient,
                                                i_prof_cat        => i_prof_cat,
                                                i_exec_interv_rec => l_exec_interv_rec,
                                                i_notes           => i_notes,
                                                i_dt_take_tstz    => i_dt_take_tstz,
                                                i_vs_id           => i_vs_id,
                                                i_vs_val          => i_vs_val,
                                                i_vs_unit_mea     => i_vs_unit_mea,
                                                i_vs_scl_elem     => i_vs_scl_elem,
                                                i_vs_notes        => i_vs_notes,
                                                i_sysdate_tstz    => i_sysdate_tstz,
                                                i_vs_dt           => i_vs_dt);
    
        -- Updates the status and the next execution date of the intervention
        pk_icnp_interv.update_interv_stat_and_dtnext(i_lang           => i_lang,
                                                     i_prof           => i_prof,
                                                     i_epis_interv_id => i_epis_interv_id,
                                                     i_action         => pk_icnp_constant.g_action_interv_exec,
                                                     i_sysdate_tstz   => i_sysdate_tstz);
    
        -- :TODO: update ICNP_EPIS_DIAGNOSIS.FLG_EXECUTIONS field (is this really needed?)
    
        -- Delete the alert associated with the intervention
        delete_interv_alert(i_lang => i_lang, i_prof => i_prof, i_epis_interv_id => i_epis_interv_id);
    
        IF i_flg_change_next = pk_alert_constant.g_yes
        THEN
        
            IF NOT pk_order_recurrence_api_db.get_order_recurr_instructions(i_lang                => i_lang,
                                                                            i_prof                => i_prof,
                                                                            i_order_plan          => l_exec_interv_rec.id_order_recurr_plan,
                                                                            o_order_recurr_desc   => l_order_recurr_desc,
                                                                            o_order_recurr_option => l_order_recurr_option,
                                                                            o_start_date          => l_start_date,
                                                                            o_occurrences         => l_occurrences,
                                                                            o_duration            => l_duration,
                                                                            o_unit_meas_duration  => l_unit_meas_duration,
                                                                            o_duration_desc       => l_duration_desc,
                                                                            o_end_date            => l_end_date,
                                                                            o_flg_end_by_editable => l_flg_end_by_editable,
                                                                            o_error               => l_error)
            THEN
                RAISE l_exception;
            END IF;
        
            --DETERMINE THE NUMBER OF EXECUTED TASKS
            SELECT COUNT(*)
              INTO l_num_exec
              FROM icnp_interv_plan a
             WHERE a.id_order_recurr_plan = l_exec_interv_rec.id_order_recurr_plan
               AND a.flg_status IN (pk_icnp_constant.g_icnp_cplan_status_active,
                                    pk_icnp_constant.g_icnp_cplan_status_inactive,
                                    pk_icnp_constant.g_icnp_cplan_status_cancelled);
        
            --DETERMINE THE DATE/HOUR OF THE FIRST EXECUTION
            BEGIN
                SELECT b.dt_plan_tstz
                  INTO l_dt_first_plan
                  FROM icnp_interv_plan b
                 WHERE b.id_icnp_epis_interv = l_exec_interv_rec.id_icnp_epis_interv
                   AND b.exec_number = 1
                   AND b.dt_plan_tstz IS NOT NULL;
            EXCEPTION
                WHEN no_data_found THEN
                    l_dt_first_plan := NULL;
            END;
        
            --DETERMINE THE DATE/HOUR OF NEXT EXECUTION
            BEGIN
                SELECT *
                  INTO l_dt_last_plan
                  FROM (SELECT b.dt_plan_tstz
                          FROM icnp_interv_plan b
                         WHERE b.id_icnp_epis_interv = l_exec_interv_rec.id_icnp_epis_interv
                           AND b.flg_status = pk_icnp_constant.g_interv_plan_status_requested
                         ORDER BY exec_number)
                 WHERE rownum = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    l_dt_first_plan := NULL;
            END;
        
            l_time_left := extract(DAY FROM(l_dt_next_take_tstz - l_dt_last_plan)) * 24 * 60 * 60 +
                           extract(hour FROM(l_dt_next_take_tstz - l_dt_last_plan)) * 60 * 60 +
                           extract(minute FROM(l_dt_next_take_tstz - l_dt_last_plan)) * 60 +
                           extract(SECOND FROM(l_dt_next_take_tstz - l_dt_last_plan));
        
            SELECT iei.id_icnp_epis_interv,
                   iedi.id_icnp_epis_diag,
                   iei.flg_time,
                   iei.flg_prn,
                   iei.prn_notes,
                   iei.notes,
                   orp.id_order_recurr_option,
                   orp.id_order_recurr_area
              INTO l_id_icnp_epis_interv,
                   l_id_icnp_epis_diag,
                   l_flg_time,
                   l_flg_prn,
                   l_prn_notes,
                   l_notes,
                   l_order_recurr_opt,
                   l_order_recurr_area
              FROM icnp_epis_intervention iei
             INNER JOIN icnp_epis_diag_interv iedi
                ON iei.id_icnp_epis_interv = iedi.id_icnp_epis_interv
              LEFT JOIN order_recurr_plan orp
                ON orp.id_order_recurr_plan = iei.id_order_recurr_plan
             WHERE iei.id_icnp_epis_interv = l_exec_interv_rec.id_icnp_epis_interv;
        
            SELECT orp.flg_end_by
              INTO l_flg_end_by
              FROM order_recurr_plan orp
             WHERE orp.id_order_recurr_plan = l_exec_interv_rec.id_order_recurr_plan;
        
            IF NOT pk_order_recurrence_core.edit_order_recurr_plan(i_lang                   => i_lang,
                                                                   i_prof                   => i_prof,
                                                                   i_order_recurr_area      => l_order_recurr_area,
                                                                   i_order_recurr_option    => l_order_recurr_opt,
                                                                   i_start_date             => l_dt_next_take_tstz, --i_dt_next_take_tstz,
                                                                   i_occurrences            => CASE l_occurrences
                                                                                                   WHEN NULL THEN
                                                                                                    NULL
                                                                                                   ELSE
                                                                                                    (l_occurrences -
                                                                                                    l_num_exec)
                                                                                               END,
                                                                   i_duration               => NULL,
                                                                   i_unit_meas_duration     => NULL,
                                                                   i_end_date               => CASE l_flg_end_by
                                                                                                   WHEN 'N' THEN
                                                                                                    l_end_date +
                                                                                                    numtodsinterval(l_time_left,
                                                                                                                    'second')
                                                                                                   ELSE
                                                                                                    l_end_date
                                                                                               END,
                                                                   i_order_recurr_plan_from => l_exec_interv_rec.id_order_recurr_plan,
                                                                   o_order_recurr_desc      => l_order_recurr_desc,
                                                                   o_order_recurr_option    => l_order_recurr_option,
                                                                   o_start_date             => l_start_date,
                                                                   o_occurrences            => l_occurrences,
                                                                   o_duration               => l_duration,
                                                                   o_unit_meas_duration     => l_unit_meas_duration,
                                                                   o_end_date               => l_end_date,
                                                                   o_flg_end_by_editable    => l_flg_end_by_editable,
                                                                   o_order_recurr_plan      => l_order_recurr_plan,
                                                                   o_error                  => l_error)
            THEN
                RAISE l_exception;
            END IF;
        
            updt_tb_varchar_interv := table_varchar(l_id_icnp_epis_interv,
                                                    l_id_icnp_epis_diag,
                                                    l_flg_time,
                                                    i_dt_next_take_tstz,
                                                    l_exec_interv_rec.id_order_recurr_plan,
                                                    l_flg_prn,
                                                    l_prn_notes,
                                                    l_notes,
                                                    NULL,
                                                    l_order_recurr_plan);
        
            pk_icnp_fo.update_icnp_interv(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_interv       => updt_tb_varchar_interv,
                                          i_sysdate_tstz => i_sysdate_tstz,
                                          i_origin       => pk_icnp_constant.g_interv_plan_executing,
                                          o_interv_id    => l_interv_id);
        
            pk_icnp_fo.updt_icnp_plan(i_lang => i_lang, i_prof => i_prof, i_interv => updt_tb_varchar_interv);
        
            --raise_Application_error(-20001,l_order_recurr_plan);  
        
        END IF;
    
        -- Updates the dates of the first and last clinical interactions within this episode
        set_first_obs(i_lang         => i_lang,
                      i_prof         => i_prof,
                      i_episode      => i_episode,
                      i_patient      => i_patient,
                      i_sysdate_tstz => i_sysdate_tstz);
    
    END set_exec_status_execute_vs;

    /**
     * Makes the necessary updates to an execution record (icnp_interv_plan row) when
     * the user cancels an execution. The intervention status and the date of the next 
     * execution must be updated.
     *
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_episode The episode identifier.
     * @param i_patient The patient identifier.
     * @param i_interv_plan_id The execution identifier.
     * @param i_cancel_reason Cancellation reason identifier.
     * @param i_cancel_notes Notes describing the reason of the cancellation.
     * @param i_sysdate_tstz Current timestamp that should be used across all the
     *                       functions invoked from this one.
     *
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    PROCEDURE set_exec_status_cancel
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN icnp_epis_diagnosis.id_episode%TYPE,
        i_patient        IN icnp_epis_diagnosis.id_patient%TYPE,
        i_interv_plan_id IN icnp_interv_plan.id_icnp_interv_plan%TYPE,
        i_cancel_reason  IN icnp_interv_plan.id_cancel_reason%TYPE,
        i_cancel_notes   IN icnp_interv_plan.notes_cancel%TYPE,
        i_sysdate_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'set_exec_status_cancel';
        l_exec_row icnp_interv_plan%ROWTYPE;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Mark the planned execution as cancelled
        pk_icnp_exec.set_exec_status_cancel(i_lang           => i_lang,
                                            i_prof           => i_prof,
                                            i_interv_plan_id => i_interv_plan_id,
                                            i_cancel_reason  => i_cancel_reason,
                                            i_cancel_notes   => i_cancel_notes,
                                            i_sysdate_tstz   => i_sysdate_tstz,
                                            o_exec_row       => l_exec_row);
    
        -- Updates the status and the next execution date of the intervention
        pk_icnp_interv.update_interv_stat_and_dtnext(i_lang           => i_lang,
                                                     i_prof           => i_prof,
                                                     i_epis_interv_id => l_exec_row.id_icnp_epis_interv,
                                                     i_action         => pk_icnp_constant.g_action_interv_canc_exec,
                                                     i_sysdate_tstz   => i_sysdate_tstz);
    
        -- :TODO: não devia eliminar um possivel alerta da execução? (se sim, actualizar tb comentário da função)
    
        -- Updates the dates of the first and last clinical interactions within this episode
        set_first_obs(i_lang         => i_lang,
                      i_prof         => i_prof,
                      i_episode      => i_episode,
                      i_patient      => i_patient,
                      i_sysdate_tstz => i_sysdate_tstz);
    
    END set_exec_status_cancel;

    --------------------------------------------------------------------------------
    -- METHODS [CREATE SUGGESTIONS]
    --------------------------------------------------------------------------------

    /**
     * Creates therapeutic attitudes (icnp suggestions) for a given ALERT area and
     * task identifiers. A configuration table stores the suggestions that should
     * be created for each task / ALERT module.
     *
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_episode_id The episode identifier.
     * @param i_request_ids Collection with the external request identifiers.
     * @param i_task_ids  Collection with the tasks identifiers, like for example,
     *                    the identifier of the lab test, exam, etc.
     * @param i_task_type_id Identifier of the external tasks type (ALERT modules),
     *                       like for example, lab tests, exams, etc.
     * @param i_sysdate_tstz Current timestamp that should be used across all the
     *                       functions invoked from this one.
     * @param o_id_icnp_sug_interv Collection with the identifiers of the created
     *                             suggestions.
     *
     * @author Joao Martins
     * @version 1.0
     * @since 2011/01/19 (v2.5.1.3)
     *
     * @author Luis Oliveira
     * @version 1.1
     * @since 20/Jul/2011 (v2.6.1)
    */
    PROCEDURE create_suggs
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_request_ids        IN table_number,
        i_task_ids           IN table_number,
        i_task_type_id       IN task_type.id_task_type%TYPE,
        i_sysdate_tstz       IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_id_icnp_sug_interv OUT table_number
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'create_suggs';
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Check the input parameters
        IF pk_icnp_util.is_table_empty(i_request_ids)
           OR pk_icnp_util.is_table_empty(i_task_ids)
        THEN
            pk_alert_exceptions.raise_error(error_name_in => pk_icnp_constant.g_excep_inv_input_params,
                                            text_in       => 'At least one of the tables given as input parameter is empty');
        END IF;
        IF i_request_ids.count <> i_task_ids.count
        THEN
            pk_alert_exceptions.raise_error(error_name_in => pk_icnp_constant.g_excep_inv_input_params,
                                            text_in       => 'The tables given as input parameter are not equally sized');
        END IF;
    
        -- Creates therapeutic attitudes (icnp suggestions)
        pk_icnp_suggestion.create_suggs(i_lang               => i_lang,
                                        i_prof               => i_prof,
                                        i_episode_id         => i_id_episode,
                                        i_request_ids        => i_request_ids,
                                        i_task_ids           => i_task_ids,
                                        i_task_type_id       => i_task_type_id,
                                        i_sysdate_tstz       => i_sysdate_tstz,
                                        o_id_icnp_sug_interv => o_id_icnp_sug_interv);
    
        -- There is no need to call the set_first_obs method because this method is only invoked
        -- from other packages (not from ux)
    
    END create_suggs;

    /**
     * Creates a therapeutic attitude (icnp suggestion) for a given ALERT area and
     * task identifier. A configuration table stores the suggestions that should
     * be created for each task / ALERT module.
     *
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_id_episode The episode identifier.
     * @param i_request_id Identifier of the external request.
     * @param i_task_id Identifier of the task, like for example, the identifier of
     *                  the lab test, exam, etc.
     * @param i_task_type_id Identifier of the external task type (ALERT modules),
     *                       like for example, lab tests, exams, etc.
     * @param i_sysdate_tstz Current timestamp that should be used across all the
     *                       functions invoked from this one.
     * @param o_id_icnp_sug_interv Collection with the identifiers of the created
     *                             suggestions.
     *
     * @author Luis Oliveira
     * @version 1.1
     * @since 20/Jul/2011 (v2.6.1)
    */
    PROCEDURE create_sugg
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_request_id         IN icnp_suggest_interv.id_req%TYPE,
        i_task_id            IN icnp_suggest_interv.id_task%TYPE,
        i_task_type_id       IN icnp_suggest_interv.id_task_type%TYPE,
        i_sysdate_tstz       IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_id_icnp_sug_interv OUT table_number
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'create_sugg';
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Creates a therapeutic attitude (icnp suggestion)
        pk_icnp_suggestion.create_sugg(i_lang               => i_lang,
                                       i_prof               => i_prof,
                                       i_episode_id         => i_id_episode,
                                       i_request_id         => i_request_id,
                                       i_task_id            => i_task_id,
                                       i_task_type_id       => i_task_type_id,
                                       i_sysdate_tstz       => i_sysdate_tstz,
                                       o_id_icnp_sug_interv => o_id_icnp_sug_interv);
    
    END create_sugg;

    --------------------------------------------------------------------------------
    -- METHODS [UPDATE SUGGESTION STATUS]
    --------------------------------------------------------------------------------

    /**
     * Rejects all the suggestions with identifiers that are in the collection given
     * as input parameter (i_sugg_ids). When the suggestion is rejected, the
     * corresponding alert should be deleted.
     *
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_episode The episode identifier.
     * @param i_patient The patient identifier.
     * @param i_sugg_ids Collection with the suggestion identifiers.
     * @param i_sysdate_tstz Current timestamp that should be used across all the
     *                       functions invoked from this one.
     *
     * @author Luis Oliveira
     * @version 1.1
     * @since 27/Jul/2011 (v2.6.1)
    */
    PROCEDURE set_suggs_status_reject
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN icnp_suggest_interv.id_episode%TYPE,
        i_patient      IN icnp_suggest_interv.id_patient%TYPE,
        i_sugg_ids     IN table_number,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'set_suggs_status_reject';
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Rejects the suggestions
        pk_icnp_suggestion.set_suggs_status_reject(i_lang         => i_lang,
                                                   i_prof         => i_prof,
                                                   i_sugg_ids     => i_sugg_ids,
                                                   i_sysdate_tstz => i_sysdate_tstz);
    
        -- Updates the dates of the first and last clinical interactions within this episode
        set_first_obs(i_lang         => i_lang,
                      i_prof         => i_prof,
                      i_episode      => i_episode,
                      i_patient      => i_patient,
                      i_sysdate_tstz => i_sysdate_tstz);
    
    END set_suggs_status_reject;

    /**
     * Cancels all the suggestions by request identifier / ALERT module (like for example,
     * lab tests, medication, procedures, etc).
     *
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_request_ids Collection with the external request identifiers.
     * @param i_task_type_id Identifier of the external tasks type.
     * @param i_sysdate_tstz Current timestamp that should be used across all the
     *                       functions invoked from this one.
     *
     * @author Luis Oliveira
     * @version 1.1
     * @since 20/Jul/2011 (v2.6.1)
    */
    PROCEDURE set_suggs_status_cancel
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_request_ids  IN table_number,
        i_task_type_id IN icnp_suggest_interv.id_task_type%TYPE,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'set_suggs_status_cancel';
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Cancels the suggestions
        pk_icnp_suggestion.set_suggs_status_cancel(i_lang         => i_lang,
                                                   i_prof         => i_prof,
                                                   i_request_ids  => i_request_ids,
                                                   i_task_type_id => i_task_type_id,
                                                   i_sysdate_tstz => i_sysdate_tstz);
    
        -- There is no need to call the set_first_obs method because this method is only invoked
        -- from other packages (not from ux)
    
    END set_suggs_status_cancel;

    /**
     * Cancels a single suggestion by request identifier / ALERT module (like for
     * example, lab tests, medication, procedures, etc).
     *
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_request_id The identifier of the external request.
     * @param i_task_type_id Identifier of the external task type.
     * @param i_sysdate_tstz Current timestamp that should be used across all the
     *                       functions invoked from this one.
     *
     * @author Joao Martins
     * @version 1.0
     * @since 2011/01/21 (v2.5.1.3)
     *
     * @author Luis Oliveira
     * @version 1.1
     * @since 20/Jul/2011 (v2.6.1)
    */
    PROCEDURE set_sugg_status_cancel
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_request_id   IN icnp_suggest_interv.id_req%TYPE,
        i_task_type_id IN icnp_suggest_interv.id_task_type%TYPE,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'set_sugg_status_cancel';
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Cancels the suggestion
        pk_icnp_suggestion.set_sugg_status_cancel(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  i_request_id   => i_request_id,
                                                  i_task_type_id => i_task_type_id,
                                                  i_sysdate_tstz => i_sysdate_tstz);
    
        -- There is no need to call the set_first_obs method because this method is only invoked
        -- from other packages (not from ux)
    
    END set_sugg_status_cancel;

    --------------------------------------------------------------------------------
    -- METHODS [STANDARD_CPLAN]
    --------------------------------------------------------------------------------

    /**
     * The icnp_cplan_stand_compo contains the set of icnp templates that could
     * be activated in frontoffice in order to ease the user in the request process.
     * This method gets all the data needed in order to correctly request one or
     * several of those templates. This method doesn't start by "get" because it 
     * changes some data in the database.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_sel_compo A set of diagnosis and interventions whose details must be 
     *                    returned.
     * @param o_diags All the details of the selected diagnosis needed to populate
     *                the UX form.
     * @param o_interv All the details of the selected interventions needed to populate
     *                the UX form.
     * 
     * @author Luis Oliveira
     * @version 2.6.1
     * @since 14/Jun/2011
    */
    PROCEDURE load_standard_cplan_info
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_sel_compo IN table_number,
        o_diags     OUT pk_types.cursor_type,
        o_interv    OUT pk_types.cursor_type
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'load_standard_cplan_info';
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        pk_icnp_fo.load_standard_cplan_info(i_lang      => i_lang,
                                            i_prof      => i_prof,
                                            i_sel_compo => i_sel_compo,
                                            o_diags     => o_diags,
                                            o_interv    => o_interv);
    
    END load_standard_cplan_info;

    /**
     * Gets all the data related with a given standard plan. This method is invoked 
     * to populate the UX form when the user wants to edit a plan. This method doesn't 
     * start by "get" because it changes data.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_cplan_stand The standard plan identifier whose details we want to retrieve.
     * @param o_diags All the details of the diagnosis associated with the standard plan.
     * @param o_interv All the details of the interventions associated with the standard plan.
     * @param o_name The standard plan name.
     * @param o_notes Predefined request notes.
     * @param o_dcs The specialties list where the plan is valid.
     * @param o_soft The software list where the plan is valid.
     * 
     * @author Luis Oliveira
     * @version 2.6.1
     * @since 14/Jun/2011
    */
    PROCEDURE load_standard_cplan_info_bo
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_cplan_stand IN icnp_cplan_stand_compo.id_cplan_stand%TYPE,
        o_diags       OUT pk_types.cursor_type,
        o_interv      OUT pk_types.cursor_type,
        o_name        OUT VARCHAR2,
        o_notes       OUT VARCHAR2,
        o_dcs         OUT pk_types.cursor_type,
        o_soft        OUT pk_types.cursor_type
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'load_standard_cplan_info_bo';
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        pk_icnp_fo.load_standard_cplan_info_bo(i_lang        => i_lang,
                                               i_prof        => i_prof,
                                               i_cplan_stand => i_cplan_stand,
                                               o_diags       => o_diags,
                                               o_interv      => o_interv,
                                               o_name        => o_name,
                                               o_notes       => o_notes,
                                               o_dcs         => o_dcs,
                                               o_soft        => o_soft);
    
    END load_standard_cplan_info_bo;

    /**
     * Load needed info about intervention and it's instructions
     * This method gets all the data needed to update de recurrence. interventions and it's instructions
     * 
     * @param i_lang                      The professional preferred language.
     * @param i_prof                      The professional context [id user, id institution, id software].
     * @param i_id_icnp_epis_interv       The icnp_epis_intervention identifier whose details we want to retrieve. 
     *
     * @param o_interv All the details of the selected interventions needed to populate
     *                the UX form.
     * 
     * @author Nuno Neves
     * @version 2.5.1.8.2
     * @since 10/10/2011
    */
    PROCEDURE load_icnp_info
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_icnp_epis_interv IN icnp_epis_intervention.id_icnp_epis_interv%TYPE,
        o_interv              OUT pk_types.cursor_type
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'load_icnp_info';
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
        pk_icnp_fo.load_icnp_info(i_lang                => i_lang,
                                  i_prof                => i_prof,
                                  i_id_icnp_epis_interv => i_id_icnp_epis_interv,
                                  o_interv              => o_interv);
    
    END load_icnp_info;

    /**
    * Update an ICNP intervention: given a set of interventions and it's instructions
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_interv       intervention identifiers and instructions list
    * @param i_sysdate_tstz Current timestamp that should be used across all the 
    *                       functions invoked from this one.
    * @param o_interv_id    created icnp_epis_intervention ids
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Nuno Neves
    * @version              2.5.1.8.2
    * @since                2011/10/10
    */
    PROCEDURE update_icnp_interv
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_interv       IN table_varchar,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_interv_id    OUT table_number
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'update_icnp_interv';
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
        pk_icnp_fo.update_icnp_interv(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_interv       => i_interv,
                                      i_sysdate_tstz => i_sysdate_tstz,
                                      i_origin       => pk_icnp_constant.g_interv_plan_editing,
                                      o_interv_id    => o_interv_id);
    
    END update_icnp_interv;

    /********************************************************************************************
    * get icnp default instructions for a given list of composition ids
    *
    * @param       i_lang                preferred language id for this professional
    * @param       i_prof                professional id structure
    * @param       i_soft                softwares list
    * @param       i_compositions        array of composition ids
    * @param       o_default_instruct    cursor containing the default instructions for each composition id
    * @param       o_error               error message
    *
    * @return      boolean               true or false on success or error
    *
    * @author                            Tiago Silva
    * @since                             2013/02/04
    ********************************************************************************************/
    FUNCTION get_default_instructions
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_soft             IN table_number,
        i_compositions     IN table_number,
        o_default_instruct OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        const_func_name                CONSTANT pk_icnp_type.t_function_name := 'GET_DEFAULT_INSTRUCTIONS';
        const_null_order_recurr_option CONSTANT NUMBER(24) := -9999;
    
        -- get institution market
        l_id_market market.id_market%TYPE := pk_utils.get_institution_market(i_lang, i_prof.institution);
    
        -- get configuration value that indicates if default recurrence instructions should appear when user requests an intervention
        l_icpn_def_recurr_instr_config sys_config.value%TYPE := pk_sysconfig.get_config('ICNP_DEFAULT_RECURRENCE_INSTRUCTIONS',
                                                                                        i_prof);
    
        -- variables used to create recurrence plans
        l_order_recurr_desc   VARCHAR2(1000 CHAR);
        l_order_recurr_option order_recurr_plan.id_order_recurr_option%TYPE;
        l_start_date          order_recurr_plan.start_date%TYPE;
        l_occurrences         order_recurr_plan.occurrences%TYPE;
        l_duration            order_recurr_plan.duration%TYPE;
        l_unit_meas_duration  order_recurr_plan.id_unit_meas_duration%TYPE;
        l_end_date            order_recurr_plan.end_date%TYPE;
        l_flg_end_by_editable VARCHAR2(1 CHAR);
        l_order_recurr_plan   order_recurr_plan.id_order_recurr_plan%TYPE;
    
        -- other local variables
        l_default_flg_time VARCHAR2(1);
        l_default_flg_prn  VARCHAR2(1);
    
        -- collections
        l_default_instructions t_tbl_icnp_default_instruct;
    
        TYPE t_rec_recurr_plan IS RECORD(
            id_order_recurr_plan order_recurr_plan.id_order_recurr_plan%TYPE,
            start_date           order_recurr_plan.start_date%TYPE);
    
        TYPE t_rec_compo_recurr_option_map IS TABLE OF t_rec_recurr_plan INDEX BY VARCHAR2(200 CHAR);
        ibt_compo_recurr_option_map t_rec_compo_recurr_option_map;
    
        -- local exception
        l_exception EXCEPTION;
    
        -- get default icnp time option
        FUNCTION get_default_flg_time RETURN VARCHAR2 IS
            l_time_val         sys_domain.val%TYPE;
            l_default_time_val sys_domain.val%TYPE;
            l_time_rank        sys_domain.rank%TYPE;
            l_time_desc_val    sys_domain.desc_val%TYPE;
            l_time_flg_default VARCHAR2(1 CHAR);
        
            c_data pk_types.cursor_type;
        BEGIN
        
            -- get icnp time options
            pk_icnp_fo.get_time(i_lang => i_lang, i_prof => i_prof, i_soft => i_soft, o_time => c_data);
        
            -- get default time option
            LOOP
                FETCH c_data
                    INTO l_time_val, l_time_rank, l_time_desc_val, l_time_flg_default;
            
                EXIT WHEN c_data%NOTFOUND;
            
                -- check if time option is default or not
                IF l_default_time_val IS NULL
                   OR l_time_flg_default = pk_alert_constant.g_yes
                THEN
                    l_default_time_val := l_time_val;
                END IF;
            
            END LOOP;
        
            RETURN l_default_time_val;
        
        END get_default_flg_time;
    
        -- get default icnp prn option
        FUNCTION get_default_flg_prn RETURN VARCHAR2 IS
            l_prn_val         sys_domain.val%TYPE;
            l_default_prn_val sys_domain.val%TYPE;
            l_prn_rank        sys_domain.rank%TYPE;
            l_prn_desc_val    sys_domain.desc_val%TYPE;
            l_prn_flg_default VARCHAR2(1 CHAR);
        
            c_data pk_types.cursor_type;
        BEGIN
        
            -- get icnp prn options
            pk_icnp_fo.get_prn_list(i_lang => i_lang, o_list => c_data);
        
            -- get default prn option
            LOOP
                FETCH c_data
                    INTO l_prn_val, l_prn_rank, l_prn_desc_val, l_prn_flg_default;
            
                EXIT WHEN c_data%NOTFOUND;
            
                -- check if prn option is default or not
                IF l_default_prn_val IS NULL
                   OR l_prn_flg_default = pk_alert_constant.g_yes
                THEN
                    l_default_prn_val := l_prn_val;
                END IF;
            
            END LOOP;
        
            RETURN l_default_prn_val;
        
        END get_default_flg_prn;
    
    BEGIN
    
        g_current_operation := 'get default icnp time value';
        log_debug(g_current_operation, const_func_name);
    
        l_default_flg_time := get_default_flg_time();
    
        g_current_operation := 'get default icnp prn value';
        log_debug(g_current_operation, const_func_name);
    
        l_default_flg_prn := get_default_flg_prn();
    
        g_current_operation := 'get icnp default instructions data';
        log_debug(g_current_operation, const_func_name);
    
        IF i_compositions IS NULL
           AND l_icpn_def_recurr_instr_config = pk_alert_constant.g_yes
        THEN
        
            SELECT t_rec_icnp_default_instruct(NULL,
                                               const_null_order_recurr_option,
                                               NULL,
                                               NULL,
                                               l_default_flg_prn,
                                               NULL,
                                               l_default_flg_time)
              BULK COLLECT
              INTO l_default_instructions
              FROM dual;
        
        ELSE
            SELECT t_rec_icnp_default_instruct(comps.column_value,
                                               nvl(confs.id_order_recurr_option, const_null_order_recurr_option),
                                               NULL,
                                               NULL,
                                               nvl(confs.flg_prn, l_default_flg_prn),
                                               confs.prn_notes,
                                               nvl(confs.flg_time, l_default_flg_time))
              BULK COLLECT
              INTO l_default_instructions
              FROM TABLE(i_compositions) comps
              LEFT OUTER JOIN (SELECT /*+opt_estimate(table comps rows=1)*/
                                comps.column_value AS id_composition,
                                row_number() over(PARTITION BY def_instr.id_composition ORDER BY def_instr.id_institution DESC, def_instr.id_market DESC, def_instr.id_software DESC) AS rownumber,
                                def_instr.id_order_recurr_option,
                                def_instr.flg_prn,
                                def_instr.prn_notes,
                                def_instr.flg_time,
                                def_instr.flg_available
                                 FROM icnp_default_instructions_msi def_instr
                                INNER JOIN TABLE(i_compositions) comps
                                   ON (def_instr.id_composition = comps.column_value)
                                WHERE def_instr.id_market IN (l_id_market, pk_alert_constant.g_id_market_all)
                                  AND def_instr.id_institution IN (i_prof.institution, pk_alert_constant.g_inst_all)
                                  AND def_instr.id_software IN (i_prof.software, pk_alert_constant.g_soft_all)) confs
                ON (comps.column_value = confs.id_composition AND
                   (confs.flg_available IS NULL OR
                   (confs.rownumber = 1 AND confs.flg_available = pk_alert_constant.g_yes)));
        
            g_current_operation := 'create and set the recurrence plan for each composition record';
            log_debug(g_current_operation, const_func_name);
        
        END IF;
        -- loop default instructions of each composition
        FOR i IN 1 .. l_default_instructions.count
        LOOP
        
            -- check if already was created a recurrence plan for this recurrence option
            IF ibt_compo_recurr_option_map.exists(l_default_instructions(i).id_order_recurr_option)
            THEN
                -- set composition record with the existing recurrence plan regarding its recurrence option
                l_default_instructions(i).id_order_recurr_plan := ibt_compo_recurr_option_map(l_default_instructions(i).id_order_recurr_option).id_order_recurr_plan;
                l_default_instructions(i).start_date := ibt_compo_recurr_option_map(l_default_instructions(i).id_order_recurr_option).start_date;
            ELSE
            
                -- if there's no default instructions and default recurrence option should not appear, 
                IF l_default_instructions(i).id_order_recurr_option = const_null_order_recurr_option
                    AND l_icpn_def_recurr_instr_config = pk_alert_constant.g_no
                THEN
                    l_default_instructions.delete(i);
                ELSE
                
                    -- create new recurrence plan for this recurrence option            
                    g_current_operation := 'call function PK_ORDER_RECURRENCE_API_DB.CREATE_ORDER_RECURR_PLAN';
                    log_debug(g_current_operation, const_func_name);
                
                    IF NOT pk_order_recurrence_api_db.create_order_recurr_plan(i_lang                => i_lang,
                                                                          i_prof                => i_prof,
                                                                          i_order_recurr_area   => 'ICNP',
                                                                          i_order_recurr_option => (CASE
                                                                                                       WHEN l_default_instructions(i).id_order_recurr_option =
                                                                                                             const_null_order_recurr_option THEN
                                                                                                        NULL
                                                                                                       ELSE
                                                                                                        l_default_instructions(i).id_order_recurr_option
                                                                                                   END),
                                                                          o_order_recurr_desc   => l_order_recurr_desc,
                                                                          o_order_recurr_option => l_order_recurr_option,
                                                                          o_start_date          => l_start_date,
                                                                          o_occurrences         => l_occurrences,
                                                                          o_duration            => l_duration,
                                                                          o_unit_meas_duration  => l_unit_meas_duration,
                                                                          o_end_date            => l_end_date,
                                                                          o_flg_end_by_editable => l_flg_end_by_editable,
                                                                          o_order_recurr_plan   => l_order_recurr_plan,
                                                                          o_error               => o_error)
                    THEN
                        g_current_operation := 'error found while calling PK_ORDER_RECURRENCE_API_DB.CREATE_ORDER_RECURR_PLAN';
                        RAISE l_exception;
                    END IF;
                
                    -- add map between this recurrence option and the new recurrence plan
                    ibt_compo_recurr_option_map(l_default_instructions(i).id_order_recurr_option).id_order_recurr_plan := l_order_recurr_plan;
                    ibt_compo_recurr_option_map(l_default_instructions(i).id_order_recurr_option).start_date := l_start_date;
                
                    -- set composition record with the new recurrence plan
                    l_default_instructions(i).id_order_recurr_plan := l_order_recurr_plan;
                    l_default_instructions(i).start_date := l_start_date;
                
                END IF;
            
            END IF;
        
        END LOOP;
    
        g_current_operation := 'open cursor O_DEFAULT_INSTRUCT';
        log_debug(g_current_operation, const_func_name);
    
        OPEN o_default_instruct FOR
            SELECT def_instr.id_composition,
                   def_instr.id_order_recurr_plan,
                   def_instr.flg_prn,
                   pk_sysdomain.get_domain(pk_icnp_constant.g_domain_default_instr_prn, def_instr.flg_prn, i_lang) AS desc_prn,
                   def_instr.prn_notes,
                   def_instr.flg_time,
                   pk_sysdomain.get_domain(pk_icnp_constant.g_domain_default_instr_time, def_instr.flg_time, i_lang) AS desc_execution,
                   pk_icnp_fo.get_instructions(i_lang,
                                               i_prof,
                                               pk_icnp_constant.g_epis_interv_type_recurrence,
                                               def_instr.flg_time,
                                               def_instr.start_date,
                                               def_instr.id_order_recurr_plan) AS desc_instructions,
                   pk_date_utils.date_send_tsz(i_lang, def_instr.start_date, i_prof) AS start_date
              FROM TABLE(l_default_instructions) def_instr;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_current_operation,
                                              g_package_owner,
                                              g_package_name,
                                              'c_func_name',
                                              o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_default_instruct);
            RETURN FALSE;
    END get_default_instructions;

    /********************************************************************************************
    * get departments list which the user has access
    *
    * @param       i_lang                preferred language id for this professional
    * @param       i_prof                professional id structure
    * @param       o_list                department list
    * @param       o_error               error message
    *
    * @return      boolean               true or false on success or error
    *
    * @author                            Teresa Coutinho
    * @since                             2013/05/28
    ********************************************************************************************/

    FUNCTION get_soft
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'get_soft';
    BEGIN
    
        g_current_operation := 'open cursor O_DEFAULT_INSTRUCT';
        OPEN o_list FOR
            SELECT s.name,
                   nvl((SELECT REPLACE(sl.desc_software, '<br>', ' ')
                         FROM soft_lang sl
                        WHERE sl.id_software = s.id_software
                          AND sl.id_language = i_lang),
                       s.desc_software) desc_software,
                   s.id_software
              FROM prof_soft_inst psi, prof_preferences pp, software s
             WHERE psi.id_professional = i_prof.id
               AND psi.id_institution = i_prof.institution
               AND pp.id_software = psi.id_software
               AND pp.id_professional = psi.id_professional
               AND pp.id_institution = psi.id_institution
               AND s.id_software = psi.id_software
               AND s.id_software NOT IN (0)
             ORDER BY name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_current_operation,
                                              g_package_owner,
                                              g_package_name,
                                              c_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
        
    END;

    FUNCTION inactivate_icnp_tasks
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_inst        IN institution.id_institution%TYPE,
        i_ids_exclude IN OUT table_number,
        i_ids_area    IN VARCHAR2 DEFAULT NULL,
        o_has_error   OUT BOOLEAN,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cancel_cfg sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf => 'INACTIVATE_CANCEL_REASON',
                                                                      i_prof    => i_prof);
    
        l_descontinued_cfg sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf => 'INACTIVATE_DISCONTINUED_REASON',
                                                                            i_prof    => i_prof);
    
        l_tbl_config_diag t_tbl_config_table := pk_core_config.get_values_by_mkt_inst_sw(i_lang => NULL,
                                                                                         i_prof => profissional(0,
                                                                                                                i_inst,
                                                                                                                0),
                                                                                         i_area => 'ICNP_DIAG_INACTIVATE');
    
        l_tbl_config_interv t_tbl_config_table := pk_core_config.get_values_by_mkt_inst_sw(i_lang => NULL,
                                                                                           i_prof => profissional(0,
                                                                                                                  i_inst,
                                                                                                                  0),
                                                                                           i_area => 'ICNP_INTERV_INACTIVATE');
    
        l_tbl_config_sugg t_tbl_config_table := pk_core_config.get_values_by_mkt_inst_sw(i_lang => NULL,
                                                                                         i_prof => profissional(0,
                                                                                                                i_inst,
                                                                                                                0),
                                                                                         i_area => 'ICNP_SUGG_INACTIVATE');
    
        l_cancel_id cancel_reason.id_cancel_reason%TYPE := pk_cancel_reason.get_id_by_content(i_lang,
                                                                                              i_prof,
                                                                                              l_cancel_cfg);
    
        l_descontinued_id cancel_reason.id_cancel_reason%TYPE := pk_cancel_reason.get_id_by_content(i_lang,
                                                                                                    i_prof,
                                                                                                    l_descontinued_cfg);
    
        l_max_rows sys_config.value%TYPE := pk_sysconfig.get_config(i_prof    => i_prof,
                                                                    i_code_cf => 'INACTIVATE_TASKS_MAX_NUMBER_ROWS');
    
        l_icnp_diag_req         table_number;
        l_icnp_interv_req       table_number;
        l_icnp_sugg_req         table_number;
        l_icnp_diag_status      table_varchar;
        l_icnp_interv_status    table_varchar;
        l_icnp_sugg_status      table_varchar;
        l_icnp_diag_episode     table_number;
        l_icnp_diag_patient     table_number;
        l_icnp_interv_episode   table_number;
        l_icnp_interv_patient   table_number;
        l_icnp_sugg_task_type   table_number;
        l_tbl_order_recurr_plan table_number;
    
        l_msg       VARCHAR2(1000 CHAR);
        l_flg_show  VARCHAR2(2 CHAR);
        l_msg_title VARCHAR2(200 CHAR);
    
        l_count PLS_INTEGER;
    
        l_error t_error_out;
        g_other_exception EXCEPTION;
    
        l_tbl_error_diag_ids   table_number := table_number();
        l_tbl_error_interv_ids table_number := table_number();
        l_tbl_error_sugg_ids   table_number := table_number();
    
        --The cursor will not fetch the records for the ids (id_icnp_epis_diag) sent in i_ids_exclude   
        CURSOR c_icnp_diag_req(ids_exclude IN table_number) IS
            SELECT ied.id_icnp_epis_diag, cfg.field_04, ied.id_episode, ied.id_patient
              FROM icnp_epis_diagnosis ied
             INNER JOIN episode e
                ON e.id_episode = ied.id_episode
              LEFT JOIN episode prev_e
                ON prev_e.id_prev_episode = e.id_episode
               AND e.id_visit = prev_e.id_visit
             INNER JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                          *
                           FROM TABLE(l_tbl_config_diag) t) cfg
                ON cfg.field_01 = ied.flg_status
              LEFT JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                          t.column_value
                           FROM TABLE(i_ids_exclude) t) t_ids
                ON t_ids.column_value = ied.id_icnp_epis_diag
               AND i_ids_area = 'D'
             WHERE e.id_institution = i_inst
               AND e.dt_end_tstz IS NOT NULL
               AND (prev_e.id_episode IS NULL OR prev_e.flg_status = pk_alert_constant.g_inactive)
               AND pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                    i_timestamp => (pk_date_utils.add_to_ltstz(i_timestamp => e.dt_end_tstz,
                                                                                               i_amount    => cfg.field_02,
                                                                                               i_unit      => cfg.field_03))) <=
                   pk_date_utils.trunc_insttimezone(i_prof => i_prof, i_timestamp => current_timestamp)
               AND rownum <= l_max_rows
               AND t_ids.column_value IS NULL;
    
        CURSOR c_icnp_interv_req(ids_exclude IN table_number) IS
            SELECT iei.id_icnp_epis_interv, cfg.field_04, iei.id_episode, iei.id_patient, iei.id_order_recurr_plan
              FROM icnp_epis_intervention iei
             INNER JOIN episode e
                ON e.id_episode = iei.id_episode
              LEFT JOIN episode prev_e
                ON prev_e.id_prev_episode = e.id_episode
               AND e.id_visit = prev_e.id_visit
             INNER JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                          *
                           FROM TABLE(l_tbl_config_interv) t) cfg
                ON cfg.field_01 = iei.flg_status
              LEFT JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                          t.column_value
                           FROM TABLE(i_ids_exclude) t) t_ids
                ON t_ids.column_value = iei.id_icnp_epis_interv
               AND i_ids_area = 'I'
             WHERE e.id_institution = i_inst
               AND e.dt_end_tstz IS NOT NULL
               AND (prev_e.id_episode IS NULL OR prev_e.flg_status = pk_alert_constant.g_inactive)
               AND pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                    i_timestamp => (pk_date_utils.add_to_ltstz(i_timestamp => e.dt_end_tstz,
                                                                                               i_amount    => cfg.field_02,
                                                                                               i_unit      => cfg.field_03))) <=
                   pk_date_utils.trunc_insttimezone(i_prof => i_prof, i_timestamp => current_timestamp)
               AND rownum <= l_max_rows
               AND t_ids.column_value IS NULL;
    
        CURSOR c_icnp_sugg_req(ids_exclude IN table_number) IS
            SELECT isi.id_req, cfg.field_04, isi.id_task_type
              FROM icnp_suggest_interv isi
             INNER JOIN episode e
                ON e.id_episode = isi.id_episode
              LEFT JOIN episode prev_e
                ON prev_e.id_prev_episode = e.id_episode
               AND e.id_visit = prev_e.id_visit
             INNER JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                          *
                           FROM TABLE(l_tbl_config_sugg) t) cfg
                ON cfg.field_01 = isi.flg_status
              LEFT JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                          t.column_value
                           FROM TABLE(i_ids_exclude) t) t_ids
                ON t_ids.column_value = isi.id_req
               AND i_ids_area = 'S'
             WHERE e.id_institution = i_inst
               AND e.dt_end_tstz IS NOT NULL
               AND (prev_e.id_episode IS NULL OR prev_e.flg_status = pk_alert_constant.g_inactive)
               AND pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                    i_timestamp => (pk_date_utils.add_to_ltstz(i_timestamp => e.dt_end_tstz,
                                                                                               i_amount    => cfg.field_02,
                                                                                               i_unit      => cfg.field_03))) <=
                   pk_date_utils.trunc_insttimezone(i_prof => i_prof, i_timestamp => current_timestamp)
               AND rownum <= l_max_rows
               AND t_ids.column_value IS NULL;
    
    BEGIN
    
        o_has_error := FALSE;
    
        OPEN c_icnp_diag_req(i_ids_exclude);
        FETCH c_icnp_diag_req BULK COLLECT
            INTO l_icnp_diag_req, l_icnp_diag_status, l_icnp_diag_episode, l_icnp_diag_patient;
        CLOSE c_icnp_diag_req;
    
        OPEN c_icnp_interv_req(i_ids_exclude);
        FETCH c_icnp_interv_req BULK COLLECT
            INTO l_icnp_interv_req,
                 l_icnp_interv_status,
                 l_icnp_interv_episode,
                 l_icnp_interv_patient,
                 l_tbl_order_recurr_plan;
        CLOSE c_icnp_interv_req;
    
        OPEN c_icnp_sugg_req(i_ids_exclude);
        FETCH c_icnp_sugg_req BULK COLLECT
            INTO l_icnp_sugg_req, l_icnp_sugg_status, l_icnp_sugg_task_type;
        CLOSE c_icnp_sugg_req;
    
        IF l_icnp_interv_req.count > 0
        THEN
            IF i_ids_area <> 'I'
               OR i_ids_area IS NULL
            THEN
                i_ids_exclude := table_number();
            END IF;
        
            FOR i IN 1 .. l_icnp_interv_req.count
            LOOP
                IF l_icnp_interv_status(i) = pk_icnp_constant.g_epis_interv_status_cancelled
                THEN
                    BEGIN
                        SAVEPOINT init_cancel;
                        pk_icnp_fo_api_db.set_intervs_status_cancel(i_lang          => i_lang,
                                                                    i_prof          => i_prof,
                                                                    i_episode       => l_icnp_interv_episode(i),
                                                                    i_patient       => l_icnp_interv_patient(i),
                                                                    i_interv_ids    => table_number(l_icnp_interv_req(i)),
                                                                    i_cancel_reason => l_cancel_id,
                                                                    i_cancel_notes  => NULL,
                                                                    i_sysdate_tstz  => current_timestamp);
                    
                    EXCEPTION
                        WHEN OTHERS THEN
                            ROLLBACK TO init_cancel;
                        
                            --If, for the given id_icnp_epis_interv, an error is generated, o_has_error is set as TRUE,
                            --this way, the loop cicle may continue, but the system will know that at least one error has happened
                            o_has_error := TRUE;
                        
                            --A log for the id_icnp_epis_interv that raised the error must be generated 
                            pk_alert_exceptions.reset_error_state;
                            l_error.err_desc := 'ERROR CALLING PK_ICNP_FO_API_DB.SET_INTERVS_STATUS_CANCEL FOR RECORD ' ||
                                                l_icnp_interv_req(i);
                            pk_alert_exceptions.process_error(i_lang,
                                                              SQLCODE,
                                                              SQLERRM,
                                                              l_error.err_desc,
                                                              g_package_owner,
                                                              g_package_name,
                                                              'INACTIVATE_ICNP_TASKS',
                                                              o_error);
                        
                            --The array for the ids (id_icnp_epis_interv) that raised the error is incremented
                            l_tbl_error_interv_ids.extend();
                            l_tbl_error_interv_ids(l_tbl_error_interv_ids.count) := l_icnp_interv_req(i);
                        
                            CONTINUE;
                    END;
                ELSIF l_icnp_interv_status(i) = pk_icnp_constant.g_epis_interv_status_discont
                THEN
                    BEGIN
                        SAVEPOINT init_cancel;
                        pk_icnp_fo_api_db.set_intervs_status_pause(i_lang           => i_lang,
                                                                   i_prof           => i_prof,
                                                                   i_episode        => l_icnp_interv_episode(i),
                                                                   i_patient        => l_icnp_interv_patient(i),
                                                                   i_interv_ids     => table_number(l_icnp_interv_req(i)),
                                                                   i_suspend_reason => l_descontinued_id,
                                                                   i_suspend_notes  => NULL,
                                                                   i_sysdate_tstz   => current_timestamp,
                                                                   i_force_status   => pk_alert_constant.g_yes);
                    
                    EXCEPTION
                        WHEN OTHERS THEN
                            ROLLBACK TO init_cancel;
                        
                            --If, for the given id_icnp_epis_interv, an error is generated, o_has_error is set as TRUE,
                            --this way, the loop cicle may continue, but the system will know that at least one error has happened
                            o_has_error := TRUE;
                        
                            --A log for the id_icnp_epis_interv that raised the error must be generated 
                            pk_alert_exceptions.reset_error_state;
                            l_error.err_desc := 'ERROR CALLING PK_ICNP_FO_API_DB.SET_INTERVS_STATUS_CANCEL FOR RECORD ' ||
                                                l_icnp_interv_req(i);
                            pk_alert_exceptions.process_error(i_lang,
                                                              SQLCODE,
                                                              SQLERRM,
                                                              l_error.err_desc,
                                                              g_package_owner,
                                                              g_package_name,
                                                              'INACTIVATE_ICNP_TASKS',
                                                              o_error);
                        
                            --The array for the ids (id_icnp_epis_interv) that raised the error is incremented
                            l_tbl_error_interv_ids.extend();
                            l_tbl_error_interv_ids(l_tbl_error_interv_ids.count) := l_icnp_interv_req(i);
                        
                            CONTINUE;
                    END;
                END IF;
            
                SELECT COUNT(1)
                  INTO l_count
                  FROM icnp_epis_intervention iei
                 WHERE iei.id_order_recurr_plan = l_tbl_order_recurr_plan(i)
                   AND iei.flg_status NOT IN (pk_icnp_constant.g_epis_interv_status_cancelled,
                                              pk_icnp_constant.g_epis_interv_status_executed,
                                              pk_icnp_constant.g_epis_interv_status_discont);
            
                IF l_count = 0
                THEN
                    IF NOT pk_order_recurrence_core.set_order_recurr_plan_finish(i_lang              => i_lang,
                                                                                 i_prof              => i_prof,
                                                                                 i_order_recurr_plan => l_tbl_order_recurr_plan(i),
                                                                                 o_error             => o_error)
                    THEN
                        ROLLBACK TO init_cancel;
                    
                        --If, for the given id_icnp_epis_interv, an error is generated, o_has_error is set as TRUE,
                        --this way, the loop cicle may continue, but the system will know that at least one error has happened
                        o_has_error := TRUE;
                    
                        --A log for the id_icnp_epis_interv that raised the error must be generated 
                        pk_alert_exceptions.reset_error_state;
                        l_error.err_desc := 'ERROR CALLING PK_ORDER_RECURRENCE_CORE.SET_ORDER_RECURR_PLAN_FINISH FOR RECORD ' ||
                                            l_icnp_interv_req(i);
                        pk_alert_exceptions.process_error(i_lang,
                                                          SQLCODE,
                                                          SQLERRM,
                                                          l_error.err_desc,
                                                          g_package_owner,
                                                          g_package_name,
                                                          'INACTIVATE_MONITORZTN_TASKS',
                                                          o_error);
                    
                        --The array for the ids (id_icnp_epis_interv) that raised the error is incremented
                        l_tbl_error_interv_ids.extend();
                        l_tbl_error_interv_ids(l_tbl_error_interv_ids.count) := l_icnp_interv_req(i);
                    
                        CONTINUE;
                    END IF;
                END IF;
            END LOOP;
        
            --When the number of error ids match the max number of rows that can be processed for each call,
            --it means that no id_icnp_epis_interv has been inactivated.
            --The next time the Job would be executed, the cursor would fetch the same set fetched on the previous call,
            --and therefore, from this point on, no more records would be inactivated.
            IF l_tbl_error_interv_ids.count = l_max_rows
            THEN
                FOR i IN l_tbl_error_interv_ids.first .. l_tbl_error_interv_ids.last
                LOOP
                    --i_ids_exclude is an IN OUT parameter, and is incremented with the ids (id_icnp_epis_interv) that could not
                    --be inactivated with the current call of the function
                    i_ids_exclude.extend();
                    i_ids_exclude(i_ids_exclude.count) := l_tbl_error_interv_ids(i);
                END LOOP;
            
                --Since no inactivations were performed with the current call, a new call to this function is performed,
                --however, this time, the array i_ids_exclude will include a list of ids that cannot be fetched by the cursor
                --on the next call. The recursion will be perfomed until at least one record is inactivated, or the cursor
                --has no more records to fetch.
                --Note: i_ids_exclude is incremented and is an IN OUT parameter, therefore, 
                --it will hold all the ids that were not inactivated from ALL calls.            
                IF NOT pk_icnp_fo_api_db.inactivate_icnp_tasks(i_lang        => i_lang,
                                                               i_prof        => i_prof,
                                                               i_inst        => i_inst,
                                                               i_ids_exclude => i_ids_exclude,
                                                               i_ids_area    => 'I',
                                                               o_has_error   => o_has_error,
                                                               o_error       => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            END IF;
        END IF;
    
        IF l_icnp_sugg_req.count > 0
        THEN
            IF i_ids_area <> 'S'
               OR i_ids_area IS NULL
            THEN
                i_ids_exclude := table_number();
            END IF;
        
            FOR i IN 1 .. l_icnp_sugg_req.count
            LOOP
                IF l_icnp_sugg_status(i) = pk_icnp_constant.g_epis_interv_status_cancelled
                THEN
                    SAVEPOINT init_cancel;
                    BEGIN
                        pk_icnp_fo_api_db.set_sugg_status_cancel(i_lang         => i_lang,
                                                                 i_prof         => i_prof,
                                                                 i_request_id   => l_icnp_sugg_req(i),
                                                                 i_task_type_id => l_icnp_sugg_task_type(i),
                                                                 i_sysdate_tstz => current_timestamp);
                    EXCEPTION
                        WHEN OTHERS THEN
                            ROLLBACK TO init_cancel;
                        
                            o_has_error := TRUE;
                        
                            pk_alert_exceptions.reset_error_state;
                            l_error.err_desc := 'ERROR CALLING PK_ICNP_FO_API_DB.SET_SUGG_STATUS_CANCEL FOR RECORD ' ||
                                                l_icnp_sugg_req(i);
                            pk_alert_exceptions.process_error(i_lang,
                                                              SQLCODE,
                                                              SQLERRM,
                                                              l_error.err_desc,
                                                              g_package_owner,
                                                              g_package_name,
                                                              'INACTIVATE_ICNP_TASKS',
                                                              o_error);
                        
                            --The array for the ids (id_icnp_epis_interv) that raised the error is incremented
                            l_tbl_error_sugg_ids.extend();
                            l_tbl_error_sugg_ids(l_tbl_error_sugg_ids.count) := l_icnp_sugg_req(i);
                        
                            CONTINUE;
                    END;
                END IF;
            END LOOP;
        
            IF l_tbl_error_sugg_ids.count = l_max_rows
            THEN
                FOR i IN l_tbl_error_sugg_ids.first .. l_tbl_error_sugg_ids.last
                LOOP
                    i_ids_exclude.extend();
                    i_ids_exclude(i_ids_exclude.count) := l_tbl_error_sugg_ids(i);
                END LOOP;
            
                IF NOT pk_icnp_fo_api_db.inactivate_icnp_tasks(i_lang        => i_lang,
                                                               i_prof        => i_prof,
                                                               i_inst        => i_inst,
                                                               i_ids_exclude => i_ids_exclude,
                                                               i_ids_area    => 'S',
                                                               o_has_error   => o_has_error,
                                                               o_error       => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            END IF;
        END IF;
    
        IF l_icnp_diag_req.count > 0
        THEN
            IF i_ids_area <> 'S'
               OR i_ids_area IS NULL
            THEN
                i_ids_exclude := table_number();
            END IF;
        
            FOR i IN 1 .. l_icnp_diag_req.count
            LOOP
                SAVEPOINT init_cancel;
                BEGIN
                    pk_icnp_fo_api_db.set_diags_status_pause(i_lang           => i_lang,
                                                             i_prof           => i_prof,
                                                             i_episode        => NULL,
                                                             i_patient        => NULL,
                                                             i_diag_ids       => table_number(l_icnp_diag_req(i)),
                                                             i_suspend_reason => l_descontinued_id,
                                                             i_suspend_notes  => NULL,
                                                             i_sysdate_tstz   => current_timestamp,
                                                             i_force_status   => pk_alert_constant.g_yes);
                EXCEPTION
                    WHEN OTHERS THEN
                        ROLLBACK TO init_cancel;
                    
                        o_has_error := TRUE;
                    
                        pk_alert_exceptions.reset_error_state;
                        l_error.err_desc := 'ERROR CALLING PK_ICNP_FO_API_DB.SET_SUGG_STATUS_CANCEL FOR RECORD ' ||
                                            l_icnp_diag_req(i);
                        pk_alert_exceptions.process_error(i_lang,
                                                          SQLCODE,
                                                          SQLERRM,
                                                          l_error.err_desc,
                                                          g_package_owner,
                                                          g_package_name,
                                                          'INACTIVATE_ICNP_TASKS',
                                                          o_error);
                    
                        --The array for the ids (id_icnp_epis_interv) that raised the error is incremented
                        l_tbl_error_diag_ids.extend();
                        l_tbl_error_diag_ids(l_tbl_error_diag_ids.count) := l_icnp_diag_req(i);
                    
                        CONTINUE;
                END;
            END LOOP;
        
            IF l_tbl_error_diag_ids.count = l_max_rows
            THEN
                FOR i IN l_tbl_error_diag_ids.first .. l_tbl_error_diag_ids.last
                LOOP
                    i_ids_exclude.extend();
                    i_ids_exclude(i_ids_exclude.count) := l_tbl_error_diag_ids(i);
                END LOOP;
            
                IF NOT pk_icnp_fo_api_db.inactivate_icnp_tasks(i_lang        => i_lang,
                                                               i_prof        => i_prof,
                                                               i_inst        => i_inst,
                                                               i_ids_exclude => i_ids_exclude,
                                                               i_ids_area    => 'D',
                                                               o_has_error   => o_has_error,
                                                               o_error       => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END inactivate_icnp_tasks;

BEGIN
    -- Executes all the instructions needed to correctly initialize the package
    initialize();

END pk_icnp_fo_api_db;
/
