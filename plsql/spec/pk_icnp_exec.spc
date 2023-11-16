/*-- Last Change Revision: $Rev: 2028728 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:34 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_icnp_exec IS

    --------------------------------------------------------------------------------
    -- METHODS [CREATE]
    --------------------------------------------------------------------------------

    /**
     * Creates a new execution record (icnp_interv_plan row).
     *
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_epis_interv_id The identifier of the intervention that will be 
     *                         associated to the created execution.
     * @param i_dt_plan_tstz Planned date of the execution.
     * @param i_exec_number The order of the execution within the plan as specified by 
     *                      the recurrence mechanism.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * 
     * @author Luis Oliveira
     * @version 1.1
     * @since 27/Jul/2011 (v2.6.1)
    */
    PROCEDURE create_execution
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_interv_id    IN icnp_interv_plan.id_icnp_epis_interv%TYPE,
        i_dt_plan_tstz      IN icnp_interv_plan.dt_plan_tstz%TYPE,
        i_exec_number       IN icnp_interv_plan.exec_number%TYPE,
        i_order_recurr_plan IN icnp_interv_plan.id_order_recurr_plan%TYPE,
        i_sysdate_tstz      IN TIMESTAMP WITH LOCAL TIME ZONE
    );

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

    --------------------------------------------------------------------------------
    -- METHODS [UPDATE EXEC STATUS]
    --------------------------------------------------------------------------------

    /**
     * Makes the necessary updates to a set of execution records 
     * (icnp_interv_plan rows) when the user cancels executions.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_exec_ids The set of execution identifiers that we want to cancel.
     * @param i_cancel_reason Cancellation reason identifier.
     * @param i_cancel_notes Notes describing the reason of the cancellation.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * @param o_exec_row_coll Collection with the changed execution records (icnp_interv_plan rows).
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    PROCEDURE set_execs_status_cancel
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_exec_ids      IN table_number,
        i_cancel_reason IN icnp_interv_plan.id_cancel_reason%TYPE,
        i_cancel_notes  IN icnp_interv_plan.notes_cancel%TYPE,
        i_sysdate_tstz  IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_exec_row_coll OUT ts_icnp_interv_plan.icnp_interv_plan_tc
    );

    /**
     * @see set_execs_status_cancel 
    */
    PROCEDURE set_execs_status_cancel
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_exec_ids      IN table_number,
        i_cancel_reason IN icnp_interv_plan.id_cancel_reason%TYPE,
        i_cancel_notes  IN icnp_interv_plan.notes_cancel%TYPE,
        i_sysdate_tstz  IN TIMESTAMP WITH LOCAL TIME ZONE
    );

    /**
     * Makes the necessary updates to an execution record (icnp_interv_plan row) when
     * the user cancels an execution.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_interv_plan_id The execution identifier.
     * @param i_cancel_reason Cancellation reason identifier.
     * @param i_cancel_notes Notes describing the reason of the cancellation.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * @param o_exec_row The changed execution record (icnp_interv_plan row).
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    PROCEDURE set_exec_status_cancel
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_interv_plan_id IN icnp_interv_plan.id_icnp_interv_plan%TYPE,
        i_cancel_reason  IN icnp_interv_plan.id_cancel_reason%TYPE,
        i_cancel_notes   IN icnp_interv_plan.notes_cancel%TYPE,
        i_sysdate_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_exec_row       OUT icnp_interv_plan%ROWTYPE
    );

    /**
     * @see set_exec_status_cancel 
    */
    PROCEDURE set_exec_status_cancel
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_interv_plan_id IN icnp_interv_plan.id_icnp_interv_plan%TYPE,
        i_cancel_reason  IN icnp_interv_plan.id_cancel_reason%TYPE,
        i_cancel_notes   IN icnp_interv_plan.notes_cancel%TYPE,
        i_sysdate_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE
    );

    /**
     * Makes the necessary updates to a set of execution records (icnp_interv_plan rows) 
     * when the user executes a non-template execution.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_exec_interv_coll The collection with all the data needed to correctly 
     *                           execute an intervention.
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
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_exec_interv_coll IN pk_icnp_type.t_exec_interv_coll,
        i_notes            IN icnp_interv_plan.notes%TYPE,
        i_dt_take_tstz     IN icnp_interv_plan.dt_take_tstz%TYPE,
        i_sysdate_tstz     IN TIMESTAMP WITH LOCAL TIME ZONE
    );

    /**
     * Makes the necessary updates to a set of execution records (icnp_interv_plan rows) 
     * when the user executes a execution using a template.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_exec_interv_rec The record with all the data needed to correctly execute 
     *                          an intervention.
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
        i_exec_interv_rec       IN pk_icnp_type.t_exec_interv_rec,
        i_epis_documentation_id IN icnp_interv_plan.id_epis_documentation%TYPE,
        i_sysdate_tstz          IN TIMESTAMP WITH LOCAL TIME ZONE
    );

    /**
     * Makes the necessary updates to a set of execution records (icnp_interv_plan rows) 
     * when the user executes a non-template execution with vital signs.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_episode The episode identifier.
     * @param i_patient The patient identifier.
     * @param i_prof_cat The category of the logged professional.
     * @param i_exec_interv_rec The record with all the data needed to correctly execute 
     *                          an intervention.
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
     * @param i_vs_dt Collection of read vital signs clinical date.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    PROCEDURE set_exec_status_execute_vs
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_patient         IN patient.id_patient%TYPE,
        i_prof_cat        IN category.flg_type%TYPE,
        i_exec_interv_rec IN pk_icnp_type.t_exec_interv_rec,
        i_notes           IN icnp_interv_plan.notes%TYPE,
        i_dt_take_tstz    IN icnp_interv_plan.dt_take_tstz%TYPE,
        i_vs_id           IN table_number,
        i_vs_val          IN table_number,
        i_vs_unit_mea     IN table_number,
        i_vs_scl_elem     IN table_number,
        i_vs_notes        IN vital_sign_notes.notes%TYPE,
        i_sysdate_tstz    IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_vs_dt           IN table_varchar
    );

    --------------------------------------------------------------------------------
    -- METHODS [UPDATE EXEC STATUS FOR INTERV]
    --------------------------------------------------------------------------------

    /**
     * Marks as not executed all the execution records that are not yet executed and
     * that are related with a set of interventions. Usually this method is invoked 
     * when some action is performed on the interventions.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_interv_ids The set of intervention identifiers.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * 
     * @see update_execs_status (g_interv_plan_status_not_exec)
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    PROCEDURE set_exec_st_notexe_for_intervs
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_interv_ids   IN table_number,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE
    );

    /**
     * Marks as suspended all the execution records that are not yet executed and
     * that are related with a set of interventions. Usually this method is invoked 
     * when some action is performed on the interventions.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_interv_ids The set of intervention identifiers.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * 
     * @see update_execs_status (g_interv_plan_status_suspended)
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    PROCEDURE set_exec_st_susp_for_intervs
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_interv_ids   IN table_number,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE
    );

    /**
     * Marks as requested (active) all the execution records that are suspended and
     * that are related with a set of interventions. Usually this method is invoked 
     * when some action is performed on the interventions.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_interv_ids The set of intervention identifiers.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * 
     * @see update_execs_status (g_interv_plan_status_requested)
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    PROCEDURE set_exec_st_req_for_intervs
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_interv_ids   IN table_number,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE
    );

    /**
     * Marks as cancelled all the execution records that are not yet executed and
     * that are related with a set of interventions. Usually this method is invoked 
     * when some action is performed on the interventions.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_interv_ids The set of intervention identifiers.
     * @param i_cancel_reason Cancellation reason identifier.
     * @param i_cancel_notes Notes describing the reason of the cancellation.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * 
     * @see set_execs_status_cancel
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    PROCEDURE set_exec_st_cancel_for_intervs
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_interv_ids    IN table_number,
        i_cancel_reason IN icnp_interv_plan.id_cancel_reason%TYPE,
        i_cancel_notes  IN icnp_interv_plan.notes_cancel%TYPE,
        i_sysdate_tstz  IN TIMESTAMP WITH LOCAL TIME ZONE
    );

END pk_icnp_exec;
/
