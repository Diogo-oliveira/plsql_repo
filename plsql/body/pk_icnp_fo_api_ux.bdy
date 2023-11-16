/*-- Last Change Revision: $Rev: 2027227 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:34 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_icnp_fo_api_ux IS

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
    -- PRIVATE METHODS [DEBUG AND ERROR HANDLING]
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
    -- PRIVATE METHODS [INIT]
    --------------------------------------------------------------------------------

    /**
     * Executes all the instructions needed to correctly initialize the package.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 03/Jun/2011
    */
    PROCEDURE initialize IS
    BEGIN
        -- Initializes the log mechanism
        g_current_operation := 'INIT LOG MECHANISM';
        g_package_owner     := 'ALERT';
        g_package_name      := pk_alertlog.who_am_i;
        pk_alertlog.log_init(g_package_name);
    
        -- Log message
        log_debug('initialize()', 'initialize');
    END;

    --------------------------------------------------------------------------------
    -- METHODS [WRAPPERS - ONLY USED INTERNALLY]
    --------------------------------------------------------------------------------

    /**
     * This procedure performs error handling creating the log for the error and 
     * resets the error state (the procedure that must be called when an exception 
     * is finally handled at the lowest call).
     * 
     * @param i_lang The professional preferred language.
     * @param i_func_name The name of the function where the error occurred.
     * @param o_error The details of the error, like for example: ora_sqlcode and 
     *                ora_sqlerrm.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 22/Jul/2011
    */
    PROCEDURE process_error
    (
        i_lang      IN language.id_language%TYPE,
        i_func_name IN pk_icnp_type.t_function_name,
        o_error     OUT t_error_out
    ) IS
    BEGIN
        pk_alert_exceptions.process_error(i_lang     => i_lang,
                                          i_sqlcode  => SQLCODE,
                                          i_sqlerrm  => SQLERRM,
                                          i_message  => g_current_operation,
                                          i_owner    => g_package_owner,
                                          i_package  => g_package_name,
                                          i_function => i_func_name,
                                          o_error    => o_error);
        pk_alert_exceptions.reset_error_state;
    END;

    /**
     * This procedure performs error handling creating the log for the error and 
     * resets the error state (the procedure that must be called when an exception 
     * is finally handled at the lowest call). It also undo any pending transaction.
     * 
     * @param i_lang The professional preferred language.
     * @param i_func_name The name of the function where the error occurred.
     * @param o_error The details of the error, like for example: ora_sqlcode and 
     *                ora_sqlerrm.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 22/Jul/2011
    */
    PROCEDURE process_error_and_undo
    (
        i_lang      IN language.id_language%TYPE,
        i_func_name IN pk_icnp_type.t_function_name,
        o_error     OUT t_error_out
    ) IS
    BEGIN
        process_error(i_lang, i_func_name, o_error);
        pk_utils.undo_changes;
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
     * @param o_interv_id    created icnp_epis_intervention ids
     * @param o_error        the details of the error, like for example: ora_sqlcode 
     *                       and ora_sqlerrm.
     *
     * @return TRUE if sucess, FALSE otherwise.
     *
     * @author               Pedro Carneiro
     * @version               2.5.1
     * @since                2010/07/20
    */
    FUNCTION create_icnp_interv
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        i_patient   IN patient.id_patient%TYPE,
        i_diag      IN table_number,
        i_exp_res   IN table_number,
        i_notes     IN table_varchar,
        i_interv    IN table_table_varchar,
        o_interv_id OUT table_number,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'CREATE_ICNP_INTERV';
        l_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
        -- The same timestamp should be used across all the functions invoked from this one
        l_sysdate_tstz := current_timestamp;
    
        g_current_operation := 'calling pk_icnp_fo_api_db.create_icnp_interv function';
        pk_icnp_fo_api_db.create_icnp_interv(i_lang         => i_lang,
                                             i_prof         => i_prof,
                                             i_episode      => i_episode,
                                             i_patient      => i_patient,
                                             i_diag         => i_diag,
                                             i_exp_res      => i_exp_res,
                                             i_notes        => i_notes,
                                             i_interv       => i_interv,
                                             i_sysdate_tstz => l_sysdate_tstz,
                                             o_interv_id    => o_interv_id);
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error_and_undo(i_lang, c_func_name, o_error);
            RETURN FALSE;
        
    END create_icnp_interv;

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
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/08/09
    */
    FUNCTION set_assoc_diag
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_diag    IN table_number,
        i_interv  IN table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'SET_ASSOC_DIAG';
        l_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
        l_error        t_error_out;
    BEGIN
        -- The same timestamp should be used across all the functions invoked from this one
        l_sysdate_tstz := current_timestamp;
    
        g_current_operation := 'calling pk_icnp_fo.set_assoc_diag function';
        pk_icnp_fo.set_assoc_diag(i_lang => i_lang, i_prof => i_prof, i_diag => i_diag, i_interv => i_interv);
    
        g_current_operation := 'calling pk_visit.set_first_obs function';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => i_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => l_sysdate_tstz,
                                      i_dt_first_obs        => l_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            pk_icnp_util.raise_unexpected_error('pk_visit.set_first_obs', l_error);
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error_and_undo(i_lang, c_func_name, o_error);
            RETURN FALSE;
        
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
    FUNCTION set_assoc_interv
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        i_patient   IN patient.id_patient%TYPE,
        i_diag      IN icnp_epis_diagnosis.id_icnp_epis_diag%TYPE,
        i_interv    IN table_table_varchar,
        o_interv_id OUT table_number,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'SET_ASSOC_INTERV';
        l_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
        l_error        t_error_out;
    BEGIN
        -- The same timestamp should be used across all the functions invoked from this one
        l_sysdate_tstz := current_timestamp;
    
        g_current_operation := 'calling pk_icnp_fo.set_assoc_interv function';
        pk_icnp_fo.set_assoc_interv(i_lang         => i_lang,
                                    i_prof         => i_prof,
                                    i_episode      => i_episode,
                                    i_patient      => i_patient,
                                    i_diag         => i_diag,
                                    i_interv       => i_interv,
                                    i_sysdate_tstz => l_sysdate_tstz,
                                    o_interv_id    => o_interv_id);
    
        g_current_operation := 'calling pk_visit.set_first_obs function';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => i_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => l_sysdate_tstz,
                                      i_dt_first_obs        => l_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            pk_icnp_util.raise_unexpected_error('pk_visit.set_first_obs', l_error);
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error_and_undo(i_lang, c_func_name, o_error);
            RETURN FALSE;
        
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
     * @param o_error The details of the error, like for example: ora_sqlcode and 
     *                ora_sqlerrm.
     *
     * @return TRUE if sucess, FALSE otherwise.
     *
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    FUNCTION set_intervs_status_resolve
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN icnp_epis_intervention.id_episode%TYPE,
        i_patient    IN icnp_epis_intervention.id_patient%TYPE,
        i_interv_ids IN table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'SET_INTERVS_STATUS_RESOLVE';
        l_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
        -- The same timestamp should be used across all the functions invoked from this one
        l_sysdate_tstz := current_timestamp;
    
        g_current_operation := 'calling pk_icnp_fo_api_db.set_intervs_status_resolve function';
        pk_icnp_fo_api_db.set_intervs_status_resolve(i_lang         => i_lang,
                                                     i_prof         => i_prof,
                                                     i_episode      => i_episode,
                                                     i_patient      => i_patient,
                                                     i_interv_ids   => i_interv_ids,
                                                     i_sysdate_tstz => l_sysdate_tstz);
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error_and_undo(i_lang, c_func_name, o_error);
            RETURN FALSE;
        
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
     * @param o_error The details of the error, like for example: ora_sqlcode and 
     *                ora_sqlerrm.
     *
     * @return TRUE if sucess, FALSE otherwise.
     *
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    FUNCTION set_intervs_status_pause
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN icnp_epis_intervention.id_episode%TYPE,
        i_patient        IN icnp_epis_intervention.id_patient%TYPE,
        i_interv_ids     IN table_number,
        i_suspend_reason IN icnp_epis_intervention.id_suspend_reason%TYPE,
        i_suspend_notes  IN icnp_epis_intervention.suspend_notes%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'SET_INTERVS_STATUS_PAUSE';
        l_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
        -- The same timestamp should be used across all the functions invoked from this one
        l_sysdate_tstz := current_timestamp;
    
        g_current_operation := 'calling pk_icnp_fo_api_db.set_intervs_status_pause function';
        pk_icnp_fo_api_db.set_intervs_status_pause(i_lang           => i_lang,
                                                   i_prof           => i_prof,
                                                   i_episode        => i_episode,
                                                   i_patient        => i_patient,
                                                   i_interv_ids     => i_interv_ids,
                                                   i_suspend_reason => i_suspend_reason,
                                                   i_suspend_notes  => i_suspend_notes,
                                                   i_sysdate_tstz   => l_sysdate_tstz);
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error_and_undo(i_lang, c_func_name, o_error);
            RETURN FALSE;
        
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
     * @param o_error The details of the error, like for example: ora_sqlcode and 
     *                ora_sqlerrm.
     *
     * @return TRUE if sucess, FALSE otherwise.
     *
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    FUNCTION set_intervs_status_resume
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN icnp_epis_intervention.id_episode%TYPE,
        i_patient    IN icnp_epis_intervention.id_patient%TYPE,
        i_interv_ids IN table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'SET_INTERVS_STATUS_RESUME';
        l_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
        -- The same timestamp should be used across all the functions invoked from this one
        l_sysdate_tstz := current_timestamp;
    
        g_current_operation := 'calling pk_icnp_fo_api_db.set_intervs_status_resume function';
        pk_icnp_fo_api_db.set_intervs_status_resume(i_lang         => i_lang,
                                                    i_prof         => i_prof,
                                                    i_episode      => i_episode,
                                                    i_patient      => i_patient,
                                                    i_interv_ids   => i_interv_ids,
                                                    i_sysdate_tstz => l_sysdate_tstz);
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error_and_undo(i_lang, c_func_name, o_error);
            RETURN FALSE;
        
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
     * @param o_error The details of the error, like for example: ora_sqlcode and 
     *                ora_sqlerrm.
     *
     * @return TRUE if sucess, FALSE otherwise.
     *
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    FUNCTION set_intervs_status_cancel
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN icnp_epis_intervention.id_episode%TYPE,
        i_patient       IN icnp_epis_intervention.id_patient%TYPE,
        i_interv_ids    IN table_number,
        i_cancel_reason IN icnp_epis_intervention.id_cancel_reason%TYPE,
        i_cancel_notes  IN icnp_epis_intervention.cancel_notes%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'SET_INTERVS_STATUS_CANCEL';
        l_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
        -- The same timestamp should be used across all the functions invoked from this one
        l_sysdate_tstz := current_timestamp;
    
        g_current_operation := 'calling pk_icnp_fo_api_db.set_intervs_status_cancel function';
        pk_icnp_fo_api_db.set_intervs_status_cancel(i_lang          => i_lang,
                                                    i_prof          => i_prof,
                                                    i_episode       => i_episode,
                                                    i_patient       => i_patient,
                                                    i_interv_ids    => i_interv_ids,
                                                    i_cancel_reason => i_cancel_reason,
                                                    i_cancel_notes  => i_cancel_notes,
                                                    i_sysdate_tstz  => l_sysdate_tstz);
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error_and_undo(i_lang, c_func_name, o_error);
            RETURN FALSE;
        
    END set_intervs_status_cancel;

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
     * @param o_error The details of the error, like for example: ora_sqlcode and 
     *                ora_sqlerrm.
     *
     * @return TRUE if sucess, FALSE otherwise.
     *
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    FUNCTION set_diags_status_reeval
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN icnp_epis_diagnosis.id_episode%TYPE,
        i_patient        IN icnp_epis_diagnosis.id_patient%TYPE,
        i_diag_ids       IN table_number,
        i_composition_id IN icnp_epis_diagnosis.id_composition%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'SET_DIAGS_STATUS_REEVAL';
        l_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
        -- The same timestamp should be used across all the functions invoked from this one
        l_sysdate_tstz := current_timestamp;
    
        g_current_operation := 'calling pk_icnp_fo_api_db.set_diags_status_reeval function';
        pk_icnp_fo_api_db.set_diags_status_reeval(i_lang           => i_lang,
                                                  i_prof           => i_prof,
                                                  i_episode        => i_episode,
                                                  i_patient        => i_patient,
                                                  i_diag_ids       => i_diag_ids,
                                                  i_composition_id => i_composition_id,
                                                  i_sysdate_tstz   => l_sysdate_tstz,
                                                  i_notes          => NULL);
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error_and_undo(i_lang, c_func_name, o_error);
            RETURN FALSE;
        
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
     * @param o_error The details of the error, like for example: ora_sqlcode and 
     *                ora_sqlerrm.
     *
     * @return TRUE if sucess, FALSE otherwise.
     *
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    FUNCTION set_diags_status_resolve
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN icnp_epis_diagnosis.id_episode%TYPE,
        i_patient  IN icnp_epis_diagnosis.id_patient%TYPE,
        i_diag_ids IN table_number,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'SET_DIAGS_STATUS_RESOLVE';
        l_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
        -- The same timestamp should be used across all the functions invoked from this one
        l_sysdate_tstz := current_timestamp;
    
        g_current_operation := 'calling pk_icnp_fo_api_db.set_diags_status_resolve function';
        pk_icnp_fo_api_db.set_diags_status_resolve(i_lang         => i_lang,
                                                   i_prof         => i_prof,
                                                   i_episode      => i_episode,
                                                   i_patient      => i_patient,
                                                   i_diag_ids     => i_diag_ids,
                                                   i_sysdate_tstz => l_sysdate_tstz);
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error_and_undo(i_lang, c_func_name, o_error);
            RETURN FALSE;
        
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
     * @param o_error The details of the error, like for example: ora_sqlcode and 
     *                ora_sqlerrm.
     *
     * @return TRUE if sucess, FALSE otherwise.
     *
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    FUNCTION set_diags_status_pause
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN icnp_epis_diagnosis.id_episode%TYPE,
        i_patient        IN icnp_epis_diagnosis.id_patient%TYPE,
        i_diag_ids       IN table_number,
        i_suspend_reason IN icnp_epis_diagnosis.id_suspend_reason%TYPE,
        i_suspend_notes  IN icnp_epis_diagnosis.suspend_notes%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'SET_DIAGS_STATUS_PAUSE';
        l_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
        -- The same timestamp should be used across all the functions invoked from this one
        l_sysdate_tstz := current_timestamp;
    
        g_current_operation := 'calling pk_icnp_fo_api_db.set_diags_status_pause function';
        pk_icnp_fo_api_db.set_diags_status_pause(i_lang           => i_lang,
                                                 i_prof           => i_prof,
                                                 i_episode        => i_episode,
                                                 i_patient        => i_patient,
                                                 i_diag_ids       => i_diag_ids,
                                                 i_suspend_reason => i_suspend_reason,
                                                 i_suspend_notes  => i_suspend_notes,
                                                 i_sysdate_tstz   => l_sysdate_tstz);
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error_and_undo(i_lang, c_func_name, o_error);
            RETURN FALSE;
        
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
     * @param o_error The details of the error, like for example: ora_sqlcode and 
     *                ora_sqlerrm.
     *
     * @return TRUE if sucess, FALSE otherwise.
     *
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    FUNCTION set_diags_status_resume
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN icnp_epis_diagnosis.id_episode%TYPE,
        i_patient  IN icnp_epis_diagnosis.id_patient%TYPE,
        i_diag_ids IN table_number,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'SET_DIAGS_STATUS_RESUME';
        l_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
        -- The same timestamp should be used across all the functions invoked from this one
        l_sysdate_tstz := current_timestamp;
    
        g_current_operation := 'calling pk_icnp_fo_api_db.set_diags_status_resume function';
        pk_icnp_fo_api_db.set_diags_status_resume(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  i_episode      => i_episode,
                                                  i_patient      => i_patient,
                                                  i_diag_ids     => i_diag_ids,
                                                  i_sysdate_tstz => l_sysdate_tstz);
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error_and_undo(i_lang, c_func_name, o_error);
            RETURN FALSE;
        
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
     * @param o_error The details of the error, like for example: ora_sqlcode and 
     *                ora_sqlerrm.
     *
     * @return TRUE if sucess, FALSE otherwise.
     *
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    FUNCTION set_diags_status_cancel
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN icnp_epis_diagnosis.id_episode%TYPE,
        i_patient       IN icnp_epis_diagnosis.id_patient%TYPE,
        i_diag_ids      IN table_number,
        i_cancel_reason IN icnp_epis_diagnosis.id_cancel_reason%TYPE,
        i_cancel_notes  IN icnp_epis_diagnosis.cancel_notes%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'SET_DIAGS_STATUS_CANCEL';
        l_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
        -- The same timestamp should be used across all the functions invoked from this one
        l_sysdate_tstz := current_timestamp;
    
        g_current_operation := 'calling pk_icnp_fo_api_db.set_diags_status_cancel function';
        pk_icnp_fo_api_db.set_diags_status_cancel(i_lang          => i_lang,
                                                  i_prof          => i_prof,
                                                  i_episode       => i_episode,
                                                  i_patient       => i_patient,
                                                  i_diag_ids      => i_diag_ids,
                                                  i_cancel_reason => i_cancel_reason,
                                                  i_cancel_notes  => i_cancel_notes,
                                                  i_sysdate_tstz  => l_sysdate_tstz);
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error_and_undo(i_lang, c_func_name, o_error);
            RETURN FALSE;
        
    END set_diags_status_cancel;

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
     * @param o_error The details of the error, like for example: ora_sqlcode and 
     *                ora_sqlerrm.
     *
     * @return TRUE if sucess, FALSE otherwise.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    FUNCTION set_execs_status_execute
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN icnp_epis_intervention.id_episode%TYPE,
        i_patient         IN icnp_epis_intervention.id_patient%TYPE,
        i_interv_ids      IN table_number,
        i_notes           IN icnp_interv_plan.notes%TYPE,
        i_dt_take         IN pk_icnp_type.t_serialized_timestamp,
        i_dt_next_take    IN pk_icnp_type.t_serialized_timestamp,
        i_flg_change_next IN VARCHAR2 DEFAULT 'N',
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'SET_EXECS_STATUS_EXECUTE';
        l_dt_take_tstz      icnp_interv_plan.dt_take_tstz%TYPE;
        l_dt_next_take_tstz icnp_interv_plan.dt_take_tstz%TYPE;
        l_sysdate_tstz      TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
        -- The same timestamp should be used across all the functions invoked from this one
        l_sysdate_tstz := current_timestamp;
        --raise_Application_error(-20001,'Teste');
        -- Converte a serialized timestamp to a timestamp with local timezone
        l_dt_take_tstz := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                        i_prof      => i_prof,
                                                        i_timestamp => i_dt_take,
                                                        i_timezone  => NULL);
    
        /*        l_dt_next_take_tstz := pk_date_utils.get_string_tstz(i_lang      => i_lang,
        i_prof      => i_prof,
        i_timestamp => i_dt_next_take,
        i_timezone  => NULL);*/
    
        g_current_operation := 'calling pk_icnp_fo_api_db.set_execs_status_execute function';
        pk_icnp_fo_api_db.set_execs_status_execute(i_lang              => i_lang,
                                                   i_prof              => i_prof,
                                                   i_episode           => i_episode,
                                                   i_patient           => i_patient,
                                                   i_interv_ids        => i_interv_ids,
                                                   i_notes             => i_notes,
                                                   i_dt_take_tstz      => l_dt_take_tstz,
                                                   i_dt_next_take_tstz => i_dt_next_take, --l_dt_next_take_tstz,
                                                   i_flg_change_next   => i_flg_change_next,
                                                   i_sysdate_tstz      => l_sysdate_tstz);
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error_and_undo(i_lang, c_func_name, o_error);
            RETURN FALSE;
        
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
     * @param o_error The details of the error, like for example: ora_sqlcode and 
     *                ora_sqlerrm.
     *
     * @return TRUE if sucess, FALSE otherwise.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    FUNCTION set_exec_status_execute_doc
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN icnp_epis_intervention.id_episode%TYPE,
        i_patient               IN icnp_epis_intervention.id_patient%TYPE,
        i_epis_interv_id        IN icnp_epis_intervention.id_icnp_epis_interv%TYPE,
        i_epis_documentation_id IN icnp_interv_plan.id_epis_documentation%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'SET_EXEC_STATUS_EXECUTE_DOC';
        l_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
        -- The same timestamp should be used across all the functions invoked from this one
        l_sysdate_tstz := current_timestamp;
    
        g_current_operation := 'calling pk_icnp_fo_api_db.set_exec_status_execute_doc function';
        pk_icnp_fo_api_db.set_exec_status_execute_doc(i_lang                  => i_lang,
                                                      i_prof                  => i_prof,
                                                      i_episode               => i_episode,
                                                      i_patient               => i_patient,
                                                      i_epis_interv_id        => i_epis_interv_id,
                                                      i_epis_documentation_id => i_epis_documentation_id,
                                                      i_sysdate_tstz          => l_sysdate_tstz);
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error_and_undo(i_lang, c_func_name, o_error);
            RETURN FALSE;
        
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
     * @param i_vs_dt        Collection with the clinical date of the unit measure used
     *                       for each vital sign read.
     * @param o_error The details of the error, like for example: ora_sqlcode and 
     *                ora_sqlerrm.
     *
     * @return TRUE if sucess, FALSE otherwise.
     *
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    FUNCTION set_exec_status_execute_vs
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN icnp_epis_intervention.id_episode%TYPE,
        i_patient         IN icnp_epis_intervention.id_patient%TYPE,
        i_prof_cat        IN category.flg_type%TYPE,
        i_epis_interv_id  IN icnp_epis_intervention.id_icnp_epis_interv%TYPE,
        i_notes           IN icnp_interv_plan.notes%TYPE,
        i_dt_take         IN pk_icnp_type.t_serialized_timestamp,
        i_vs_id           IN table_number,
        i_vs_val          IN table_number,
        i_vs_unit_mea     IN table_number,
        i_vs_scl_elem     IN table_number,
        i_vs_notes        IN vital_sign_notes.notes%TYPE,
        i_vs_dt           IN table_varchar,
        i_dt_next_take    IN pk_icnp_type.t_serialized_timestamp,
        i_flg_change_next IN VARCHAR2 DEFAULT 'N',
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'SET_EXEC_STATUS_EXECUTE_VS';
        l_dt_take_tstz      icnp_interv_plan.dt_take_tstz%TYPE;
        l_sysdate_tstz      TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_next_take_tstz icnp_interv_plan.dt_take_tstz%TYPE;
    BEGIN
        -- The same timestamp should be used across all the functions invoked from this one
        l_sysdate_tstz := current_timestamp;
    
        -- Converte a serialized timestamp to a timestamp with local timezone
        l_dt_take_tstz := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                        i_prof      => i_prof,
                                                        i_timestamp => i_dt_take,
                                                        i_timezone  => NULL);
    
        /*        l_dt_next_take_tstz := pk_date_utils.get_string_tstz(i_lang      => i_lang,
        i_prof      => i_prof,
        i_timestamp => i_dt_next_take,
        i_timezone  => NULL);  */
    
        g_current_operation := 'calling pk_icnp_fo_api_db.set_exec_status_execute_vs function';
        pk_icnp_fo_api_db.set_exec_status_execute_vs(i_lang              => i_lang,
                                                     i_prof              => i_prof,
                                                     i_episode           => i_episode,
                                                     i_patient           => i_patient,
                                                     i_prof_cat          => i_prof_cat,
                                                     i_epis_interv_id    => i_epis_interv_id,
                                                     i_notes             => i_notes,
                                                     i_dt_take_tstz      => l_dt_take_tstz,
                                                     i_vs_id             => i_vs_id,
                                                     i_vs_val            => i_vs_val,
                                                     i_vs_unit_mea       => i_vs_unit_mea,
                                                     i_vs_scl_elem       => i_vs_scl_elem,
                                                     i_vs_notes          => i_vs_notes,
                                                     i_sysdate_tstz      => l_sysdate_tstz,
                                                     i_vs_dt             => i_vs_dt,
                                                     i_dt_next_take_tstz => i_dt_next_take,
                                                     i_flg_change_next   => i_flg_change_next);
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error_and_undo(i_lang, c_func_name, o_error);
            RETURN FALSE;
        
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
     * @param o_error The details of the error, like for example: ora_sqlcode and 
     *                ora_sqlerrm.
     *
     * @return TRUE if sucess, FALSE otherwise.
     *
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    FUNCTION set_exec_status_cancel
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN icnp_epis_diagnosis.id_episode%TYPE,
        i_patient        IN icnp_epis_diagnosis.id_patient%TYPE,
        i_interv_plan_id IN icnp_interv_plan.id_icnp_interv_plan%TYPE,
        i_cancel_reason  IN icnp_interv_plan.id_cancel_reason%TYPE,
        i_cancel_notes   IN icnp_interv_plan.notes_cancel%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'SET_EXEC_STATUS_CANCEL';
        l_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
        -- The same timestamp should be used across all the functions invoked from this one
        l_sysdate_tstz := current_timestamp;
    
        g_current_operation := 'calling pk_icnp_fo_api_db.set_exec_status_cancel function';
        pk_icnp_fo_api_db.set_exec_status_cancel(i_lang           => i_lang,
                                                 i_prof           => i_prof,
                                                 i_episode        => i_episode,
                                                 i_patient        => i_patient,
                                                 i_interv_plan_id => i_interv_plan_id,
                                                 i_cancel_reason  => i_cancel_reason,
                                                 i_cancel_notes   => i_cancel_notes,
                                                 i_sysdate_tstz   => l_sysdate_tstz);
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error_and_undo(i_lang, c_func_name, o_error);
            RETURN FALSE;
        
    END set_exec_status_cancel;

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
     * @param o_error The details of the error, like for example: ora_sqlcode and 
     *                ora_sqlerrm.
     *
     * @return TRUE if sucess, FALSE otherwise.
     *
     * @author Luis Oliveira
     * @version 1.1
     * @since 27/Jul/2011 (v2.6.1)
    */
    FUNCTION set_suggs_status_reject
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN icnp_suggest_interv.id_episode%TYPE,
        i_patient  IN icnp_suggest_interv.id_patient%TYPE,
        i_sugg_ids IN table_number,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'SET_SUGGS_STATUS_REJECT';
        l_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
        -- The same timestamp should be used across all the functions invoked from this one
        l_sysdate_tstz := current_timestamp;
    
        g_current_operation := 'calling pk_icnp_fo_api_db.set_suggs_status_reject function';
        pk_icnp_fo_api_db.set_suggs_status_reject(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  i_episode      => i_episode,
                                                  i_patient      => i_patient,
                                                  i_sugg_ids     => i_sugg_ids,
                                                  i_sysdate_tstz => l_sysdate_tstz);
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error_and_undo(i_lang, c_func_name, o_error);
            RETURN FALSE;
        
    END set_suggs_status_reject;

    --------------------------------------------------------------------------------
    -- METHODS [STANDARD_CPLAN]
    --------------------------------------------------------------------------------

    /********************************************************************************************
    * Creates or updates ICNP care plans (Configurations Area)
    *
    * @param i_lang            Preferred language ID for this professional
    * @param i_prof            Object (professional ID, institution ID, software ID)
    * @param i_cplan           Care plan ID (null value creates a cplan)
    * @param i_name            Care plan name
    * @param i_notes           Care plan notes
    * @param i_diags           Diagnosis
    * @param i_results         Diagnosis expected results
    * @param i_intervs         Interventions (intervention and instructions) Interventions (intervention and instructions) [[(1)ID_COMPOSITION, (2)ID_COMPOSITION_PARENT, (3)TAKE_TYPE, (4)NUM_TAKE, (5)INTERVAL, (6)INTERVAL_UNIT, (7)DURATION, (8)DURATION_UNIT],...]
    * @param i_dep_clin_serv   associated specialties list
    * @param i_soft            associated softwares list
    * @param o_error           Error
    *
    * @return                  boolean type, "False" on error or "True" if success 
    *
    * @author                  Sérgio Santos
    * @version                 2.5.1 
    * @since                   2010/05/12
    *                         
    *********************************************************************************************/
    FUNCTION create_or_update_icnp_cplan
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_cplan         IN icnp_cplan_stand.id_cplan_stand%TYPE,
        i_name          IN VARCHAR2,
        i_notes         IN VARCHAR2,
        i_diags         IN table_number,
        i_results       IN table_number,
        i_intervs       IN table_table_varchar,
        i_dep_clin_serv IN table_number,
        i_soft          IN table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'CREATE_OR_UPDATE_ICNP_CPLAN';
        l_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
        -- The same timestamp should be used across all the functions invoked from this one
        l_sysdate_tstz := current_timestamp;
    
        g_current_operation := 'calling pk_icnp_fo.create_or_update_icnp_cplan function';
        pk_icnp_fo.create_or_update_icnp_cplan(i_lang          => i_lang,
                                               i_prof          => i_prof,
                                               i_cplan         => i_cplan,
                                               i_name          => i_name,
                                               i_notes         => i_notes,
                                               i_diags         => i_diags,
                                               i_results       => i_results,
                                               i_intervs       => i_intervs,
                                               i_dep_clin_serv => i_dep_clin_serv,
                                               i_soft          => i_soft,
                                               i_sysdate_tstz  => l_sysdate_tstz);
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error_and_undo(i_lang, c_func_name, o_error);
            RETURN FALSE;
        
    END create_or_update_icnp_cplan;

    /********************************************************************************************
    * Changes the status of a ICNP care plan
    *
    * @param      i_lang      Preferred language ID for this professional
    * @param      i_prof      Object (professional ID, institution ID, software ID)
    * @param      o_error     Error
    *
    * @return                 boolean type, "False" on error or "True" if success 
    * 
    * @author                  Sérgio Santos
    * @version                 2.5.1 
    * @since                   2010/05/06
    *                         
    *********************************************************************************************/
    FUNCTION set_icnp_cplan_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_cplan   IN icnp_cplan_stand.id_cplan_stand%TYPE,
        i_flg_status IN icnp_cplan_stand.flg_status%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'SET_ICNP_CPLAN_STATUS';
    BEGIN
        g_current_operation := 'calling pk_icnp_fo.set_icnp_cplan_status function';
        pk_icnp_fo.set_icnp_cplan_status(i_lang       => i_lang,
                                         i_prof       => i_prof,
                                         i_id_cplan   => i_id_cplan,
                                         i_flg_status => i_flg_status);
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error_and_undo(i_lang, c_func_name, o_error);
            RETURN FALSE;
        
    END set_icnp_cplan_status;

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
     * @param o_error The details of the error, like for example: ora_sqlcode and 
     *                ora_sqlerrm.
     *
     * @return TRUE if sucess, FALSE otherwise.
     * 
     * @author Luis Oliveira
     * @version 2.6.1
     * @since 14/Jun/2011
    */
    FUNCTION load_standard_cplan_info
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_sel_compo IN table_number,
        o_diags     OUT pk_types.cursor_type,
        o_interv    OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'LOAD_STANDARD_CPLAN_INFO';
    
    BEGIN
        g_current_operation := 'calling pk_icnp_fo_api_db.load_standard_cplan_info function';
        pk_icnp_fo_api_db.load_standard_cplan_info(i_lang      => i_lang,
                                                   i_prof      => i_prof,
                                                   i_sel_compo => i_sel_compo,
                                                   o_diags     => o_diags,
                                                   o_interv    => o_interv);
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error_and_undo(i_lang, c_func_name, o_error);
            pk_types.open_my_cursor(o_diags);
            pk_types.open_my_cursor(o_interv);
            RETURN FALSE;
        
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
     * @param o_error The details of the error, like for example: ora_sqlcode and 
     *                ora_sqlerrm.
     *
     * @return TRUE if sucess, FALSE otherwise.
     * 
     * @author Luis Oliveira
     * @version 2.6.1
     * @since 14/Jun/2011
    */
    FUNCTION load_standard_cplan_info_bo
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_cplan_stand IN icnp_cplan_stand_compo.id_cplan_stand%TYPE,
        o_diags       OUT pk_types.cursor_type,
        o_interv      OUT pk_types.cursor_type,
        o_name        OUT VARCHAR2,
        o_notes       OUT VARCHAR2,
        o_dcs         OUT pk_types.cursor_type,
        o_soft        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'LOAD_STANDARD_CPLAN_INFO_BO';
    BEGIN
        g_current_operation := 'calling pk_icnp_fo_api_db.load_standard_cplan_info_bo function';
        pk_icnp_fo_api_db.load_standard_cplan_info_bo(i_lang        => i_lang,
                                                      i_prof        => i_prof,
                                                      i_cplan_stand => i_cplan_stand,
                                                      o_diags       => o_diags,
                                                      o_interv      => o_interv,
                                                      o_name        => o_name,
                                                      o_notes       => o_notes,
                                                      o_dcs         => o_dcs,
                                                      o_soft        => o_soft);
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error_and_undo(i_lang, c_func_name, o_error);
            pk_types.open_my_cursor(o_diags);
            pk_types.open_my_cursor(o_interv);
            pk_types.open_my_cursor(o_dcs);
            pk_types.open_my_cursor(o_soft);
            RETURN FALSE;
        
    END load_standard_cplan_info_bo;

    --------------------------------------------------------------------------------
    -- METHODS [CHECKS]
    --------------------------------------------------------------------------------

    /**
    * Checks if diagnoses for association are available.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_interv       interventions identifiers list
    * @param o_flg_show     shows warning message: Y - yes, N - No
    * @param o_msg          message text
    * @param o_msg_title    message title
    * @param o_button       buttons to show: N-No, R-Read, C-Confirmed
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/08/18
    */
    FUNCTION check_assoc_diag
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_interv    IN table_number,
        o_flg_show  OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'CHECK_ASSOC_DIAG';
    BEGIN
        g_current_operation := 'calling pk_icnp_fo.check_assoc_diag function';
        pk_icnp_fo.check_assoc_diag(i_lang      => i_lang,
                                    i_prof      => i_prof,
                                    i_patient   => i_patient,
                                    i_interv    => i_interv,
                                    o_flg_show  => o_flg_show,
                                    o_msg       => o_msg,
                                    o_msg_title => o_msg_title,
                                    o_button    => o_button);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang, c_func_name, o_error);
            RETURN FALSE;
        
    END check_assoc_diag;

    /**
    * Checks selected ICNP diagnoses and interventions for conflicts. We can't
    * have request diagnosis that are still active or suspended and interventions
    * that are still ongoing, requested or suspended for the patient.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_diag         selected diagnosis list
    * @param i_interv       selected interventions list
    * @param o_warn         conflict warning
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/08/02
    */
    FUNCTION check_epis_conflict
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_diag       IN table_number,
        i_interv     IN table_number,
        i_flg_sug    IN VARCHAR2,
        o_warn       OUT table_varchar,
        o_desc_instr OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'CHECK_EPIS_CONFLICT';
    BEGIN
        g_current_operation := 'calling pk_icnp_fo.check_epis_conflict function';
        pk_icnp_fo.check_epis_conflict(i_lang       => i_lang,
                                       i_prof       => i_prof,
                                       i_patient    => i_patient,
                                       i_episode    => i_episode,
                                       i_diag       => i_diag,
                                       i_interv     => i_interv,
                                       i_flg_sug    => i_flg_sug,
                                       o_warn       => o_warn,
                                       o_desc_instr => o_desc_instr);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang, c_func_name, o_error);
            pk_types.open_my_cursor(o_desc_instr);
            RETURN FALSE;
        
    END check_epis_conflict;

    /**
    * Checks selected ICNP care plans for conflicts.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_cplan        icnp care plans identifiers list
    * @param o_exp_res      conflicted expected results cursor
    * @param o_interv       conflicted interventions cursor
    * @param o_sel_compo    unconflicted compositions list
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/07/13
    */
    FUNCTION check_conflict
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_cplan     IN table_number,
        o_exp_res   OUT pk_types.cursor_type,
        o_interv    OUT pk_types.cursor_type,
        o_sel_compo OUT table_number,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'CHECK_CONFLICT';
    BEGIN
        g_current_operation := 'calling pk_icnp_fo.check_conflict function';
        pk_icnp_fo.check_conflict(i_lang      => i_lang,
                                  i_prof      => i_prof,
                                  i_cplan     => i_cplan,
                                  o_exp_res   => o_exp_res,
                                  o_interv    => o_interv,
                                  o_sel_compo => o_sel_compo);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang, c_func_name, o_error);
            pk_types.open_my_cursor(o_exp_res);
            pk_types.open_my_cursor(o_interv);
            RETURN FALSE;
        
    END check_conflict;

    /**
    * Checks the state of the therapeutic attitude 
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_icnp_sug_interv      nurse intervention 
    
    * @param o_flg_show    Indica se deve ou não mostrar mensagem de aviso ao criar nova avaliação
    * @param o_msg_result  Mensagem de aviso a ser mostrada
    * @param o_title       Título da mensagem de aviso
    * @param o_button      Botões a mostrar no aviso
    */
    FUNCTION check_therapeutic_status
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_icnp_epis_interv IN table_number, --icnp_epis_intervention.id_icnp_epis_interv%TYPE,
        o_flg_show            OUT VARCHAR2,
        o_msg_result          OUT VARCHAR2,
        o_title               OUT VARCHAR2,
        o_button              OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'CHECK_THERAPEUTIC_STATUS';
    BEGIN
        g_current_operation := 'calling pk_icnp_fo.check_therapeutic_status function';
        pk_icnp_fo.check_therapeutic_status(i_lang                => i_lang,
                                            i_prof                => i_prof,
                                            i_id_icnp_epis_interv => i_id_icnp_epis_interv,
                                            o_flg_show            => o_flg_show,
                                            o_msg_result          => o_msg_result,
                                            o_title               => o_title,
                                            o_button              => o_button);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang, c_func_name, o_error);
            RETURN FALSE;
        
    END check_therapeutic_status;

    --------------------------------------------------------------------------------
    -- METHODS [GETS]
    --------------------------------------------------------------------------------

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
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'GET_DEFAULT_INSTRUCTIONS';
        l_exception EXCEPTION;
    BEGIN
    
        g_current_operation := 'calling PK_ICNP_FO_API_DB.GET_DEFAULT_INSTRUCTIONS function';
        log_debug(g_current_operation, c_func_name);
        IF NOT pk_icnp_fo_api_db.get_default_instructions(i_lang             => i_lang,
                                                          i_prof             => i_prof,
                                                          i_soft             => i_soft,
                                                          i_compositions     => i_compositions,
                                                          o_default_instruct => o_default_instruct,
                                                          o_error            => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            process_error_and_undo(i_lang, c_func_name, o_error);
            pk_types.open_my_cursor(o_default_instruct);
            RETURN FALSE;
    END get_default_instructions;

    /**
    * Get list of available actions, from a given state. When specifying more than one state,
    * it groups the actions, according to their availability. This enables support
    * for "bulk" state changes.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_subject      action subject
    * @param i_from_state   list of selected states
    * @param o_actions      actions cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/07/20
    */
    FUNCTION get_actions_permissions
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_subject                IN action.subject%TYPE,
        i_from_state             IN table_varchar,
        id_icnp_epis_interv_diag IN table_number,
        o_actions                OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'GET_ACTIONS_PERMISSIONS';
    BEGIN
        g_current_operation := 'calling pk_icnp_fo.get_actions_permissions function';
        pk_icnp_fo.get_actions_permissions(i_lang                   => i_lang,
                                           i_prof                   => i_prof,
                                           i_subject                => i_subject,
                                           i_from_state             => i_from_state,
                                           id_icnp_epis_interv_diag => id_icnp_epis_interv_diag,
                                           o_actions                => o_actions);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang, c_func_name, o_error);
            pk_types.open_my_cursor(o_actions);
            RETURN FALSE;
        
    END get_actions_permissions;

    /********************************************************************************************
    *  Obter lista de opções para requisição
    *
    * @param      i_lang       Preferred language ID for this professional
    * @param      i_prof       Object (professional ID, institution ID, software ID)
    * @param      o_list       Clinical services
    * @param      o_error      Error
    *
    * @return                  boolean type, "False" on error or "True" if success 
    *
    * @author                  Sérgio Santos
    * @version                 2.5.1 
    * @since                   2010/05/17
    *********************************************************************************************/
    FUNCTION get_create_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'GET_CREATE_LIST';
    BEGIN
        g_current_operation := 'calling pk_icnp_fo.get_create_list function';
        pk_icnp_fo.get_create_list(i_lang => i_lang, i_prof => i_prof, o_list => o_list);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang, c_func_name, o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
        
    END get_create_list;

    /**
    * Get ICNP create button available actions.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param o_actions      actions cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/08/05
    */
    FUNCTION get_create_list_fo
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_actions OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'GET_CREATE_LIST_FO';
    BEGIN
        g_current_operation := 'calling pk_icnp_fo.get_create_list_fo function';
        pk_icnp_fo.get_create_list_fo(i_lang => i_lang, i_prof => i_prof, o_actions => o_actions);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang, c_func_name, o_error);
            pk_types.open_my_cursor(o_actions);
            RETURN FALSE;
        
    END get_create_list_fo;

    /********************************************************************************************
    * Returns diagnosis summary view
    *
    * @param i_lang               Language identifier
    * @param i_prof               Logged professional structure
    * @param i_patient            Patient identifier
    * @param i_episode            Episode identifier
    * @param o_diag               Diagnoses cursor
    * @param o_error              Error object
    *
    * @return                boolean type, "False" on error or "True" if success
    *
    * @author                Sérgio Santos
    * @version               2.5.1
    * @since                 2010/08/02
    *********************************************************************************************/
    FUNCTION get_diag_summary
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_diag    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'GET_DIAG_SUMMARY';
    BEGIN
        g_current_operation := 'calling pk_icnp_fo.get_diag_summary function';
        pk_icnp_fo.get_diag_summary(i_lang => i_lang, i_prof => i_prof, i_patient => i_patient, o_diag => o_diag);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang, c_func_name, o_error);
            pk_types.open_my_cursor(o_diag);
            RETURN FALSE;
        
    END get_diag_summary;

    /**
    * Get diagnosis conclusion warning.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_action       chosen action
    * @param i_diag         selected diagnosis list
    * @param o_warn         warning
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/09/16
    */
    FUNCTION get_diag_warn
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_action IN action.internal_name%TYPE,
        i_diag   IN table_number,
        o_warn   OUT table_varchar,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'GET_DIAG_WARN';
    BEGIN
        g_current_operation := 'calling pk_icnp_fo.get_diag_warn function';
        pk_icnp_fo.get_diag_warn(i_lang   => i_lang,
                                 i_prof   => i_prof,
                                 i_action => i_action,
                                 i_diag   => i_diag,
                                 o_warn   => o_warn);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang, c_func_name, o_error);
            RETURN FALSE;
        
    END get_diag_warn;

    /********************************************************************************************
    * Returns ICNP's diagnosis hist
    *
    * @param      i_lang    Preferred language ID for this professional
    * @param      i_prof    Object (professional ID, institution ID, software ID)
    * @param      i_diag    Diagnosis ID
    * @param      i_episode            Episode identifier
    * @param      o_diag    Diagnosis cursor
    * @param      o_r_diag  Most recent diagnosis
    * @param      o_error   Error
    *
    * @return                boolean type, "False" on error or "True" if success
    *
    * @author                Sérgio Santos (based on pk_icnp.get_diag_hist)
    * @version               2.5.1
    * @since                 2010/08/03
    *********************************************************************************************/
    FUNCTION get_diagnosis_hist
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_diag    IN icnp_epis_diagnosis.id_icnp_epis_diag%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_diag    OUT pk_types.cursor_type,
        o_r_diag  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'GET_DIAGNOSIS_HIST';
    BEGIN
    
        g_current_operation := 'calling pk_icnp_fo.get_diagnosis_hist function';
        pk_icnp_fo.get_diagnosis_hist(i_lang    => i_lang,
                                      i_prof    => i_prof,
                                      i_diag    => i_diag,
                                      i_episode => i_episode,
                                      o_diag    => o_diag,
                                      o_r_diag  => o_r_diag);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang, c_func_name, o_error);
            pk_types.open_my_cursor(o_diag);
            pk_types.open_my_cursor(o_r_diag);
            RETURN FALSE;
        
    END get_diagnosis_hist;

    /********************************************************************************************
    * Get ICNP care plan intervention instructions (Configurations Area)
    *
    * @param      i_lang      Preferred language ID for this professional
    * @param      i_prof      Object (professional ID, institution ID, software ID)
    * @param      o_instr     Interventions instructions
    * @param      o_error     Error
    *
    * @return                 boolean type, "False" on error or "True" if success 
    * 
    * @author                  Sérgio Santos
    * @version                 2.5.1 
    * @since                   2010/05/12
    *                         
    *********************************************************************************************/
    FUNCTION get_icnp_cplan_instr
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        o_fields     OUT pk_types.cursor_type,
        o_fields_det OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'GET_ICNP_CPLAN_INSTR';
    BEGIN
        g_current_operation := 'calling pk_icnp_fo.get_icnp_cplan_instr function';
        pk_icnp_fo.get_icnp_cplan_instr(i_lang       => i_lang,
                                        i_prof       => i_prof,
                                        o_fields     => o_fields,
                                        o_fields_det => o_fields_det);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang, c_func_name, o_error);
            pk_types.open_my_cursor(o_fields);
            pk_types.open_my_cursor(o_fields_det);
            RETURN FALSE;
        
    END get_icnp_cplan_instr;

    /********************************************************************************************
    * Get ICNP care plan (Configurations Area)
    *
    * @param      i_lang      Preferred language ID for this professional
    * @param      i_prof      Object (professional ID, institution ID, software ID)
    * @param      i_plan      Care plan ID
    * @param      o_name      Care plan name
    * @param      o_notes     Care plan notes
    * @param      o_diags     Diagnosis
    * @param      o_results   Diagnosis expected results
    * @param      o_intervs   Interventions (intervention and instructions) 
    * @param      o_dcs       associated specialties list
    * @param      o_soft      associated softwares list
    * @param      o_error     Error
    *
    * @return                 boolean type, "False" on error or "True" if success 
    * 
    * @author                  Sérgio Santos
    * @version                 2.5.1 
    * @since                   2010/05/06
    *                         
    *********************************************************************************************/
    FUNCTION get_icnp_cplan_view
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_plan   IN icnp_cplan_stand.id_cplan_stand%TYPE,
        o_name   OUT VARCHAR2,
        o_status OUT VARCHAR2,
        o_notes  OUT VARCHAR2,
        o_diags  OUT pk_types.cursor_type,
        o_interv OUT pk_types.cursor_type,
        o_dcs    OUT pk_types.cursor_type,
        o_soft   OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'GET_ICNP_CPLAN_VIEW';
    BEGIN
        g_current_operation := 'calling pk_icnp_fo.get_icnp_cplan_view function';
        pk_icnp_fo.get_icnp_cplan_view(i_lang   => i_lang,
                                       i_prof   => i_prof,
                                       i_plan   => i_plan,
                                       o_name   => o_name,
                                       o_status => o_status,
                                       o_notes  => o_notes,
                                       o_diags  => o_diags,
                                       o_interv => o_interv,
                                       o_dcs    => o_dcs,
                                       o_soft   => o_soft);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang, c_func_name, o_error);
            pk_types.open_my_cursor(o_diags);
            pk_types.open_my_cursor(o_interv);
            pk_types.open_my_cursor(o_dcs);
            pk_types.open_my_cursor(o_soft);
            RETURN FALSE;
        
    END get_icnp_cplan_view;

    /********************************************************************************************
    * Get ICNP care plan list (Configurations Area)
    *
    * @param      i_lang      Preferred language ID for this professional
    * @param      i_prof      Object (professional ID, institution ID, software ID)
    * @param      o_cplan     Cursor List of available Nursing Care Plans
    * @param      o_error     Error
    *
    * @return                 boolean type, "False" on error or "True" if success 
    * 
    * @author                  Sérgio Santos
    * @version                 2.5.1 
    * @since                   2010/05/05
    *                         
    *********************************************************************************************/
    FUNCTION get_icnp_cplan_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_cplan OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'GET_ICNP_CPLAN_LIST';
    BEGIN
        g_current_operation := 'calling pk_icnp_fo.get_icnp_cplan_list function';
        pk_icnp_fo.get_icnp_cplan_list(i_lang => i_lang, i_prof => i_prof, o_cplan => o_cplan);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang, c_func_name, o_error);
            pk_types.open_my_cursor(o_cplan);
            RETURN FALSE;
        
    END get_icnp_cplan_list;

    /********************************************************************************************
    * Get ICNP care plan expected results (Configurations Area)
    * The results are diagnosis with the same focus than the i_diag provided
    *
    * @param      i_lang      Preferred language ID for this professional
    * @param      i_prof      Object (professional ID, institution ID, software ID)
    * @param      i_diag      ICNP Diagnosis
    * @param      o_results   Diagnosis expected results
    * @param      o_error     Error
    *
    * @return                 boolean type, "False" on error or "True" if success 
    * 
    * @author                  Sérgio Santos
    * @version                 2.5.1 
    * @since                   2010/05/06
    *                         
    *********************************************************************************************/
    FUNCTION get_icnp_cplan_results
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_diag    IN icnp_composition.id_composition%TYPE,
        o_results OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'GET_ICNP_CPLAN_RESULTS';
    BEGIN
        g_current_operation := 'calling pk_icnp_fo.get_icnp_cplan_results function';
        pk_icnp_fo.get_icnp_cplan_results(i_lang => i_lang, i_diag => i_diag, i_prof => i_prof, o_results => o_results);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang, c_func_name, o_error);
            pk_types.open_my_cursor(o_results);
            RETURN FALSE;
        
    END get_icnp_cplan_results;

    /**
    * Get time icnp terms that belongs to the axis "action" that already have some composition associated
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      Patient identifier
    * @param o_terms        The icnp terms that belongs to the axis "action"
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Sérgio Santos
    * @version              2.5.1
    * @since                2010/07/22
    */
    FUNCTION get_action_terms
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient patient.id_patient%TYPE,
        o_actions OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'GET_ACTION_TERMS';
    BEGIN
        g_current_operation := 'calling pk_icnp_fo.get_action_terms function';
        pk_icnp_fo.get_action_terms(i_lang => i_lang, i_prof => i_prof, i_patient => i_patient, o_actions => o_actions);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang, c_func_name, o_error);
            pk_types.open_my_cursor(o_actions);
            RETURN FALSE;
        
    END get_action_terms;

    /**
    * Gets a list of interventions that belongs to a specific icnp term in the axis "action"
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_term         icnp term identifier
    * @param i_patient      Patient identifier (optional)
    * @param o_intervs      list of interventions
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Sérgio Santos
    * @version               2.5.1
    * @since                2010/07/22
    */
    FUNCTION get_interv_by_action_term
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_term IN icnp_term.id_term%TYPE,
        i_patient IN patient.id_patient%TYPE,
        o_intervs OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'GET_INTERV_BY_ACTION_TERM';
    BEGIN
        g_current_operation := 'calling pk_icnp_fo.get_interv_by_action_term function';
        pk_icnp_fo.get_interv_by_action_term(i_lang    => i_lang,
                                             i_prof    => i_prof,
                                             i_id_term => i_id_term,
                                             i_patient => i_patient,
                                             o_intervs => o_intervs);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang, c_func_name, o_error);
            pk_types.open_my_cursor(o_intervs);
            RETURN FALSE;
        
    END get_interv_by_action_term;

    /**
    * Get data on diagnoses and interventions, for the grid view.
    * Based on PK_ICNP's GET_DIAG_SUMMARY and GET_INTERV_SUMMARY.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param o_diag         diagnoses cursor
    * @param o_interv       interventions cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/06/29
    */
    FUNCTION get_icnp_grid
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        o_diag         OUT pk_types.cursor_type,
        o_interv       OUT pk_types.cursor_type,
        o_interv_presc OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'GET_ICNP_GRID';
    BEGIN
        g_current_operation := 'calling pk_icnp_fo.get_icnp_grid function';
        pk_icnp_fo.get_icnp_grid(i_lang         => i_lang,
                                 i_prof         => i_prof,
                                 i_patient      => i_patient,
                                 i_episode      => i_episode,
                                 o_diag         => o_diag,
                                 o_interv       => o_interv,
                                 o_interv_presc => o_interv_presc);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang, c_func_name, o_error);
            pk_types.open_my_cursor(o_diag);
            pk_types.open_my_cursor(o_interv);
            pk_types.open_my_cursor(o_interv_presc);
            RETURN FALSE;
        
    END get_icnp_grid;

    /**
    * Get available ICNP care plans list.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param o_cplan        icnp care plans cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/07/07
    */
    FUNCTION get_cplan_fo
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_cplan OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'GET_CPLAN_FO';
    BEGIN
        g_current_operation := 'calling pk_icnp_fo.get_cplan_fo function';
        pk_icnp_fo.get_cplan_fo(i_prof => i_prof, o_cplan => o_cplan);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang, c_func_name, o_error);
            pk_types.open_my_cursor(o_cplan);
            RETURN FALSE;
        
    END get_cplan_fo;

    /*
    * Returns the tasks and views for the timeline view
    *
    * @param     i_lang     Language id
    * @param     i_prof     Professional
    * @param     i_patient  Patient id
    * @param     i_episode  Episode id
    * @param     i_status   status    
    * @param     o_tasks    Tasks list
    * @param     o_view     Views list
    * @param     o_error    Error message
    
    * @return    true or false on success or error
    *
    * @author    Paulo Teixeira
    * @version   2.5.1
    * @since     2010/08/03
    */
    FUNCTION get_icnp_timeline
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN interv_icnp_ea.id_patient%TYPE,
        i_episode IN icnp_epis_diagnosis.id_episode%TYPE,
        i_status  IN icnp_epis_diagnosis.flg_status%TYPE,
        o_tasks   OUT pk_types.cursor_type,
        o_view    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'GET_ICNP_TIMELINE';
    BEGIN
        g_current_operation := 'calling pk_icnp_fo.get_icnp_timeline function';
        pk_icnp_fo.get_icnp_timeline(i_lang    => i_lang,
                                     i_prof    => i_prof,
                                     i_patient => i_patient,
                                     i_episode => i_episode,
                                     i_status  => i_status,
                                     o_tasks   => o_tasks,
                                     o_view    => o_view);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang, c_func_name, o_error);
            pk_types.open_my_cursor(o_tasks);
            pk_types.open_my_cursor(o_view);
            RETURN FALSE;
        
    END get_icnp_timeline;

    /**
    * Get data for the nurse interventon suggested with prescription.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param o_task         task cursor
    * @param o_interv       interventions cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Elisabete Bugalho
    * @version              2.5.1
    * @since                21-01-2011
    */
    FUNCTION get_icnp_sug_interv
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_task    OUT pk_types.cursor_type,
        o_interv  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'GET_ICNP_SUG_INTERV';
    BEGIN
        g_current_operation := 'calling pk_icnp_fo.get_icnp_sug_interv function';
        pk_icnp_fo.get_icnp_sug_interv(i_lang    => i_lang,
                                       i_prof    => i_prof,
                                       i_patient => i_patient,
                                       i_episode => i_episode,
                                       o_task    => o_task,
                                       o_interv  => o_interv);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang, c_func_name, o_error);
            pk_types.open_my_cursor(o_task);
            pk_types.open_my_cursor(o_interv);
            RETURN FALSE;
        
    END get_icnp_sug_interv;

    /********************************************************************************************
    * Gets the associated diagnosis of a list of interventions
    *
    * @param      i_lang               Preferred language ID for this professional
    * @param      i_prof               Object (professional ID, institution ID, software ID)
    * @param      i_epis_interv        List of interventions
    * @param      o_diag               Diagnosis list description
    * @param      o_error              Error object
    *
    * @return                boolean type, "False" on error or "True" if success
    *
    * @author                Sérgio Santos
    * @version               2.5.1
    * @since                 2010/08/06
    *********************************************************************************************/
    FUNCTION get_interv_assoc_diag_desc
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_epis_interv IN table_number,
        o_diag        OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'GET_INTERV_ASSOC_DIAG_DESC';
    BEGIN
        g_current_operation := 'calling pk_icnp_fo.get_interv_assoc_diag_desc function';
        pk_icnp_fo.get_interv_assoc_diag_desc(i_lang => i_lang, i_epis_interv => i_epis_interv, o_diag => o_diag);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang, c_func_name, o_error);
            RETURN FALSE;
        
    END get_interv_assoc_diag_desc;

    /**
    * Get the intervention data used in the edition screen.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_interv       intervention identifier
    * @param o_detail       intervention cursor
    * @param o_error        error
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/08/03
    */
    FUNCTION get_interv_edit
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_interv IN icnp_epis_intervention.id_icnp_epis_interv%TYPE,
        o_detail OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'get_interv_edit';
    BEGIN
        g_current_operation := 'calling pk_icnp_fo.get_interv_edit function';
        pk_icnp_fo.get_interv_edit(i_lang => i_lang, i_prof => i_prof, i_interv => i_interv, o_detail => o_detail);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang, c_func_name, o_error);
            pk_types.open_my_cursor(o_detail);
            RETURN FALSE;
        
    END get_interv_edit;

    /********************************************************************************************
    * Returns ICNP's intervention history
    *
    * @param      i_lang                      Preferred language ID for this professional
    * @param      i_prof                      Object (professional ID, institution ID, software ID)
    * @param      i_patient                   Patient ID
    * @param      i_episode                   Episode ID
    * @param      i_interv                    Intervetion ID
    * @param      o_interv_curr               Intervention current state
    * @param      o_interv                    Intervention detail
    * @param      o_epis_doc_register         array with the detail info register
    * @param      o_epis_document_val         array with detail of documentation
    * @param      o_error                     Error
    *
    * @return                boolean type, "False" on error or "True" if success
    *
    * @author                Nuno Neves
    * @version               2.6.1
    * @since                 2011/03/23
    *********************************************************************************************/
    FUNCTION get_interv_hist
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_patient           IN icnp_epis_intervention.id_patient%TYPE,
        i_episode           IN icnp_epis_intervention.id_episode%TYPE,
        i_interv            IN icnp_epis_intervention.id_icnp_epis_interv%TYPE,
        o_interv_curr       OUT pk_types.cursor_type,
        o_interv            OUT pk_types.cursor_type,
        o_epis_doc_register OUT pk_types.cursor_type,
        o_epis_document_val OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'GET_INTERV_HIST';
    BEGIN
        g_current_operation := 'calling pk_icnp_fo.get_interv_hist function';
        pk_icnp_fo.get_interv_hist(i_lang              => i_lang,
                                   i_prof              => i_prof,
                                   i_patient           => i_patient,
                                   i_interv            => i_interv,
                                   o_interv_curr       => o_interv_curr,
                                   o_interv            => o_interv,
                                   o_epis_doc_register => o_epis_doc_register,
                                   o_epis_document_val => o_epis_document_val);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang, c_func_name, o_error);
            pk_types.open_my_cursor(o_interv_curr);
            pk_types.open_my_cursor(o_interv);
            pk_types.open_my_cursor(o_epis_doc_register);
            pk_types.open_my_cursor(o_epis_document_val);
            RETURN FALSE;
        
    END get_interv_hist;

    /**
     * Gets the available PRN options.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param o_list The list of the available PRN options.
     * @param o_error An error message, set when return=false.
     * 
     * @return TRUE if sucess, FALSE otherwise.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 30/May/2011
    */
    FUNCTION get_prn_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'GET_PRN_LIST';
    BEGIN
        g_current_operation := 'calling pk_icnp_fo.get_prn_list function';
        pk_icnp_fo.get_prn_list(i_lang => i_lang, o_list => o_list);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang, c_func_name, o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
        
    END get_prn_list;

    FUNCTION get_time
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_soft  IN table_number,
        o_time  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'GET_TIME';
    BEGIN
        g_current_operation := 'calling pk_icnp_fo.get_time function';
        pk_icnp_fo.get_time(i_lang => i_lang, i_prof => i_prof, i_soft => i_soft, o_time => o_time);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang, c_func_name, o_error);
            pk_types.open_my_cursor(o_time);
            RETURN FALSE;
        
    END get_time;

    /**
    * Get list of diagnoses for reevaluation.
    *
    * @param i_lang         language identifier
    * @param i_prof         Professional identifier
    * @param i_patient      Patient identifier
    * @param i_diag         current diagnosis identifier
    * @param o_diags        diagnoses cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/08/06
    */
    FUNCTION get_reeval_diagnoses
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_diag      IN icnp_epis_diagnosis.id_composition%TYPE,
        i_epis_diag IN icnp_epis_diagnosis.id_icnp_epis_diag%TYPE,
        o_diags     OUT pk_types.cursor_type,
        o_interv    OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'GET_REEVAL_DIAGNOSES';
    BEGIN
        g_current_operation := 'calling pk_icnp_fo.get_reeval_diagnoses function';
        pk_icnp_fo.get_reeval_diagnoses(i_lang      => i_lang,
                                        i_prof      => i_prof,
                                        i_patient   => i_patient,
                                        i_diag      => i_diag,
                                        i_epis_diag => i_epis_diag,
                                        o_diags     => o_diags,
                                        o_interv    => o_interv,
                                        o_error     => o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang, c_func_name, o_error);
            pk_types.open_my_cursor(o_diags);
            RETURN FALSE;
        
    END get_reeval_diagnoses;

    /*
    * Returns the tasks and views for the timeline documentation view
    *
    * @param     i_lang     Language id
    * @param     i_prof     Professional
    * @param     i_patient  Patient id
    * @param     i_episode  Episode id
    * @param     i_status   status    
    * @param     o_tasks    Tasks list
    * @param     o_view     Views list
    * @param     o_error    Error message
    
    * @return    true or false on success or error
    *
    * @author    Paulo Teixeira
    * @version   2.5.1
    * @since     2010/08/03
    */
    FUNCTION get_icnp_doc_timeline
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN interv_icnp_ea.id_patient%TYPE,
        i_episode IN icnp_epis_diagnosis.id_episode%TYPE,
        i_status  IN icnp_epis_diagnosis.flg_status%TYPE,
        o_tasks   OUT pk_types.cursor_type,
        o_view    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'GET_ICNP_DOC_TIMELINE';
    BEGIN
        g_current_operation := 'calling pk_icnp_fo.get_icnp_doc_timeline function';
        pk_icnp_fo.get_icnp_doc_timeline(i_lang    => i_lang,
                                         i_prof    => i_prof,
                                         i_patient => i_patient,
                                         i_episode => i_episode,
                                         i_status  => i_status,
                                         o_tasks   => o_tasks,
                                         o_view    => o_view);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang, c_func_name, o_error);
            pk_types.open_my_cursor(o_tasks);
            pk_types.open_my_cursor(o_view);
            RETURN FALSE;
        
    END get_icnp_doc_timeline;

    /********************************************************************************************
    * Returns all composition terms from focus axis that are already available throught diagnosis.
    *
    * @param      i_lang      Preferred language ID for this professional
    * @param      i_prof      Object (professional ID, institution ID, software ID)
    * @param      i_term      Focus term ID
    * @param      i_flg_child flag (Y/N to calculate has child nodes)
    * @param      i_patient   Patient ID
    * @param      o_folder    Icnp's focuses list
    * @param      o_error     Error
    *
    * @return                boolean type, "False" on error or "True" if success
    *
    * @author                Pedro Lopes
    * @author                Sérgio Santos (added old terms support)
    * @version               1
    * @since                 2009/02/16
    *********************************************************************************************/
    FUNCTION get_icnp_composition_by_term
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_term      IN table_number,
        i_flg_child IN VARCHAR2,
        i_patient   IN patient.id_patient%TYPE,
        o_folder    OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'GET_ICNP_COMPOSITION_BY_TERM';
    BEGIN
        g_current_operation := 'calling pk_icnp_fo.get_icnp_composition_by_term function';
        pk_icnp_fo.get_icnp_composition_by_term(i_lang      => i_lang,
                                                i_prof      => i_prof,
                                                i_term      => i_term,
                                                i_flg_child => i_flg_child,
                                                i_patient   => i_patient,
                                                o_folder    => o_folder);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang, c_func_name, o_error);
            pk_types.open_my_cursor(o_folder);
            RETURN FALSE;
        
    END get_icnp_composition_by_term;

    /********************************************************************************************
    * Returns all terms from focus axis that are already available throught diagnosis.
    *
    * @param      i_lang    Preferred language ID for this professional
    * @param      i_prof    Object (professional ID, institution ID, software ID)
    * @param      i_patient Patient identifier (optional)
    * @param      o_folder  Icnp's focuses list
    * @param      o_error   Error
    *
    * @return                boolean type, "False" on error or "True" if success
    *
    * @author                Pedro Lopes
    * @author                Sérgio Santos (added old terms support)
    * @version               1
    * @since                 2009/02/16
    *********************************************************************************************/
    FUNCTION get_icnp_existing_term
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_folder  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'GET_ICNP_EXISTING_TERM';
    BEGIN
        g_current_operation := 'calling pk_icnp_fo.get_icnp_existing_term function';
        pk_icnp_fo.get_icnp_existing_term(i_lang    => i_lang,
                                          i_prof    => i_prof,
                                          i_patient => i_patient,
                                          o_folder  => o_folder);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang, c_func_name, o_error);
            pk_types.open_my_cursor(o_folder);
            RETURN FALSE;
        
    END get_icnp_existing_term;

    /**
    * Get list of diagnoses for association.
    *
    * @param i_lang         language identifier
    * @param i_patient      patient identifier
    * @param i_interv       interventions identifiers list
    * @param o_diag         diagnoses cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/08/09
    */
    FUNCTION get_assoc_diag
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_interv  IN table_number,
        o_diag    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'GET_ASSOC_DIAG';
    BEGIN
        g_current_operation := 'calling pk_icnp_fo.get_assoc_diag function';
        pk_icnp_fo.get_assoc_diag(i_lang => i_lang, i_patient => i_patient, i_interv => i_interv, o_diag => o_diag);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang, c_func_name, o_error);
            pk_types.open_my_cursor(o_diag);
            RETURN FALSE;
        
    END get_assoc_diag;

    /**
    * Get list of available softwares.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param o_soft         softwares cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/07/06
    */
    FUNCTION get_software
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_soft  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'GET_SOFTWARE';
    BEGIN
        g_current_operation := 'calling pk_icnp_fo.get_software function';
        pk_icnp_fo.get_software(i_prof => i_prof, o_soft => o_soft);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang, c_func_name, o_error);
            pk_types.open_my_cursor(o_soft);
            RETURN FALSE;
        
    END get_software;

    /**
    * Get list of available departments,
    * associated with the specified softwares.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_soft         softwares list
    * @param i_search       user input for name search
    * @param o_dept         departments cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/07/06
    */
    FUNCTION get_dept
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_soft   IN table_number,
        i_search IN pk_translation.t_desc_translation,
        o_dept   OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'GET_DEPT';
    BEGIN
        g_current_operation := 'calling pk_icnp_fo.get_dept function';
        pk_icnp_fo.get_dept(i_lang   => i_lang,
                            i_prof   => i_prof,
                            i_soft   => i_soft,
                            i_search => i_search,
                            o_dept   => o_dept);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang, c_func_name, o_error);
            pk_types.open_my_cursor(o_dept);
            RETURN FALSE;
        
    END get_dept;

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
     * @param o_error        error
     *
     * @return               false if errors occur, true otherwise
     * 
     * @author Nuno Neves
     * @version 2.5.1.8.2
     * @since 10/10/2011
    */
    FUNCTION load_icnp_info
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_icnp_epis_interv IN icnp_epis_intervention.id_icnp_epis_interv%TYPE,
        o_interv              OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'load_icnp_info';
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
        pk_icnp_fo.load_icnp_info(i_lang                => i_lang,
                                  i_prof                => i_prof,
                                  i_id_icnp_epis_interv => i_id_icnp_epis_interv,
                                  o_interv              => o_interv);
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error_and_undo(i_lang, c_func_name, o_error);
            pk_types.open_my_cursor(o_interv);
            RETURN FALSE;
    END load_icnp_info;

    /**
    * Update an ICNP intervention: given a set of interventions and it's instructions
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_interv       intervention identifiers and instructions list
    * @param i_notes        diagnosis notes list
    * @param i_sysdate_tstz Current timestamp that should be used across all the 
    *                       functions invoked from this one.
    * @param o_interv_id    created icnp_epis_intervention ids
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Nuno Neves
    * @version              2.5.1.8.2
    * @since                2011/10/10
    */
    FUNCTION update_icnp_interv
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_interv    IN table_varchar,
        o_interv_id OUT table_number,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'update_icnp_interv';
        l_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
        -- The same timestamp should be used across all the functions invoked from this one
        l_sysdate_tstz := current_timestamp;
    
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
        pk_icnp_fo.update_icnp_interv(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_interv       => i_interv,
                                      i_sysdate_tstz => l_sysdate_tstz,
                                      i_origin       => pk_icnp_constant.g_interv_plan_editing,
                                      o_interv_id    => o_interv_id);
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error_and_undo(i_lang, c_func_name, o_error);
            RETURN FALSE;
    END update_icnp_interv;

    /**
    * Get all information related to nursing interventions (relationships)
    * 
    * @param i_lang                              language identifier
    * @param i_prof                              logged professional structure
    * @param i_id_icnp_epis_inter_array          array with interventions ids
    * @param o_interv                            Interventions cursor                                               
    * @param o_diag                              Diagnoses cursor
    * @param o_task                              MCDT's cursor
    * @param o_error                             error                 
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Nuno Neves
    * @version               2.6.1
    * @since                2012/03/05
    */
    FUNCTION get_icnp_rel_info
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_icnp_epis_inter_array IN table_number,
        o_interv                   OUT pk_types.cursor_type,
        o_diag                     OUT pk_types.cursor_type,
        o_task                     OUT pk_types.cursor_type,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'get_icnp_rel_info';
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
        pk_icnp_fo.get_icnp_rel_info(i_lang                     => i_lang,
                                     i_prof                     => i_prof,
                                     i_id_icnp_epis_inter_array => i_id_icnp_epis_inter_array,
                                     o_interv                   => o_interv,
                                     o_diag                     => o_diag,
                                     o_task                     => o_task);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error_and_undo(i_lang, c_func_name, o_error);
            RETURN FALSE;
        
    END get_icnp_rel_info;

    /**
    * Define the status of the relationship with nursing intervention
    * 
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_rel_array    array with information with actions for nursing interventions
    * @param o_error                             error 
    * 
    * @return               false if errors occur, true otherwise             
    *
    * @author               Nuno Neves
    * @version               2.6.1
    * @since                2012/03/05
    */
    FUNCTION set_status_rel_icnp
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_rel_array IN table_table_varchar,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'SET_STATUS_REL_ICNP';
    BEGIN
    
        pk_icnp_fo.set_status_rel_icnp(i_lang => i_lang, i_prof => i_prof, i_rel_array => i_rel_array);
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error_and_undo(i_lang, c_func_name, o_error);
            RETURN FALSE;
    END set_status_rel_icnp;

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
        l_exception EXCEPTION;
    BEGIN
        -- Debug message      
    
        log_debug(g_current_operation, c_func_name);
        IF NOT pk_icnp_fo_api_db.get_soft(i_lang => i_lang, i_prof => i_prof, o_list => o_list, o_error => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            process_error_and_undo(i_lang, c_func_name, o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
        
    END get_soft;

    FUNCTION reeval_diagnosis
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_diag_ids       IN table_number, -- old icnp_epis_diagnosis
        i_composition_id IN icnp_epis_diagnosis.id_composition%TYPE, -- new diagnosis
        i_interv_check   IN table_number, ---- icnp_epis_intervention
        i_new_diag       IN table_number, ---- new id_diag???????
        i_new_interv     IN table_number,
        i_new_interv_ovr IN table_number,
        i_flg_sug        IN VARCHAR2,
        i_exp_res        IN table_number,
        i_notes          IN table_varchar,
        i_interv         IN table_table_varchar,
        o_interv_id      OUT table_number,
        o_warn           OUT table_varchar,
        o_desc_instr     OUT pk_types.cursor_type,
        o_error          OUT t_error_out
        
    ) RETURN BOOLEAN IS
        l_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
        l_exception EXCEPTION;
        c_func_name VARCHAR2(30 CHAR) := 'REEVAL_DIAGNOSIS';
    
    BEGIN
    
        l_sysdate_tstz := current_timestamp;
        --raise_application_error(-20001,'Teste');
        IF NOT pk_icnp_fo.reeval_diagnosis(i_lang           => i_lang,
                                           i_prof           => i_prof,
                                           i_patient        => i_patient,
                                           i_episode        => i_episode,
                                           i_diag_ids       => i_diag_ids,
                                           i_composition_id => i_composition_id,
                                           i_interv_check   => i_interv_check,
                                           i_new_diag       => i_new_diag,
                                           i_new_interv     => i_new_interv,
                                           i_new_interv_ovr => i_new_interv_ovr,
                                           i_flg_sug        => i_flg_sug,
                                           i_exp_res        => i_exp_res,
                                           i_notes          => i_notes,
                                           i_interv         => i_interv,
                                           o_interv_id      => o_interv_id,
                                           o_warn           => o_warn,
                                           o_desc_instr     => o_desc_instr,
                                           o_error          => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error_and_undo(i_lang, c_func_name, o_error);
            RETURN FALSE;
        
    END reeval_diagnosis;

    FUNCTION get_interv_by_diag
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_comp             IN icnp_composition_hist.id_composition_hist%TYPE,
        i_interv_old       IN table_number,
        o_folder           OUT pk_types.cursor_type,
        o_default_instruct OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        c_func_name VARCHAR2(30 CHAR) := 'GET_INTERV_BY_DIAG';
        l_exception EXCEPTION;
        l_id_composition      NUMBER;
        l_id_composition_hist NUMBER;
        l_composition_desc    VARCHAR2(200 CHAR);
        l_tbl_intervs         table_number := table_number();
        i                     NUMBER := 1;
    
        l_flg_cancel        VARCHAR2(2 CHAR);
        l_short_desc        VARCHAR2(200 CHAR);
        l_id_cancel_connect VARCHAR2(10 CHAR);
        l_flg_most_freq     VARCHAR2(2 CHAR);
    
        l_id icnp_composition_hist.id_composition_hist%TYPE;
    
        l_folder pk_types.cursor_type;
    
    BEGIN
    
        SELECT DISTINCT ich.id_composition_hist
          INTO l_id
          FROM icnp_composition ic, icnp_composition_hist ich, icnp_composition_term ict --, translation t
         WHERE ic.id_composition = ich.id_composition
           AND ic.flg_type = pk_icnp_constant.g_cp_st_compo_type_diag
           AND ic.flg_available = pk_alert_constant.g_yes
           AND ich.flg_most_recent = pk_alert_constant.g_yes
           AND ic.id_composition = i_comp
           AND ich.flg_cancel = pk_alert_constant.g_no
           AND ict.flg_main_focus = pk_alert_constant.g_yes
           AND ic.id_institution = i_prof.institution;
    
        IF NOT pk_icnp.get_icnp_interv_or_diag(i_lang       => i_lang,
                                               i_prof       => i_prof,
                                               i_comp       => l_id,
                                               i_flag       => pk_icnp_constant.g_composition_type_diagnosis,
                                               i_interv_old => i_interv_old,
                                               o_folder     => l_folder,
                                               o_error      => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        LOOP
            FETCH l_folder
                INTO l_id_composition,
                     l_flg_cancel,
                     l_short_desc,
                     l_id_cancel_connect,
                     l_id_composition_hist,
                     l_composition_desc,
                     l_flg_most_freq;
            EXIT WHEN l_folder%NOTFOUND;
            l_tbl_intervs.extend;
            l_tbl_intervs(i) := l_id_composition;
            i := i + 1;
        
        END LOOP;
        CLOSE l_folder;
    
        IF NOT pk_icnp.get_icnp_interv_or_diag(i_lang       => i_lang,
                                               i_prof       => i_prof,
                                               i_comp       => l_id,
                                               i_flag       => pk_icnp_constant.g_composition_type_diagnosis,
                                               i_interv_old => i_interv_old,
                                               o_folder     => o_folder,
                                               o_error      => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        IF NOT pk_icnp_fo_api_db.get_default_instructions(i_lang             => i_lang,
                                                          i_prof             => i_prof,
                                                          i_soft             => table_number(i_prof.software),
                                                          i_compositions     => l_tbl_intervs,
                                                          o_default_instruct => o_default_instruct,
                                                          o_error            => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error_and_undo(i_lang, c_func_name, o_error);
            RETURN FALSE;
        
    END get_interv_by_diag;

    FUNCTION get_icnp_interv_info
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_icnp_epis_interv IN icnp_epis_intervention.id_icnp_epis_interv%TYPE,
        o_interv              OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_icnp_fo.get_icnp_interv_info(i_lang                => i_lang,
                                               i_prof                => i_prof,
                                               i_id_icnp_epis_interv => i_id_icnp_epis_interv,
                                               o_interv              => o_interv,
                                               o_error               => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error_and_undo(i_lang, 'get_icnp_interv_info', o_error);
            RETURN FALSE;
    END get_icnp_interv_info;
    
BEGIN
    -- Executes all the instructions needed to correctly initialize the package
    initialize();

END pk_icnp_fo_api_ux;
/
