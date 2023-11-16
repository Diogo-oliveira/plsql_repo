CREATE OR REPLACE PACKAGE pk_icnp_fo_api_db IS

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
    );

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
    );

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
    );

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
    );

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
    );

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
    );

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
    );

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
    );

    PROCEDURE set_intervs_status_finish
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN icnp_epis_intervention.id_episode%TYPE,
        i_patient      IN icnp_epis_intervention.id_patient%TYPE,
        i_interv_ids   IN table_number,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE
    );

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
    );

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
    );

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
    );

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
    );

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
    );

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
    );

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
    );

    /**
     * Wrapper that converts the procedure create_executions into a function. The error
     * details are returned in the o_error output parameter.
     * 
     * This wrapper was created because it is invoked from the job of the recurrence mechanism.
     * 
     * @see create_executions
     * @param o_error An error message, set when return=false.
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
    ) RETURN BOOLEAN;

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
        i_dt_next_take_tstz pk_icnp_type.t_serialized_timestamp, --IN icnp_interv_plan.dt_take_tstz%TYPE,
        i_flg_change_next   IN VARCHAR2 DEFAULT 'N',
        i_sysdate_tstz      IN TIMESTAMP WITH LOCAL TIME ZONE
    );

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
    );

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
    );

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
    );

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
    );

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
    );

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
    );

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
    );

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
    );

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
    );

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
    );

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
    ) RETURN BOOLEAN;
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
    ) RETURN BOOLEAN;

    FUNCTION inactivate_icnp_tasks
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_inst        IN institution.id_institution%TYPE,
        i_ids_exclude IN OUT table_number,
        i_ids_area    IN VARCHAR2 DEFAULT NULL,
        o_has_error   OUT BOOLEAN,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

END pk_icnp_fo_api_db;
/
