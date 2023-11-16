/*-- Last Change Revision: $Rev: 2028733 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:36 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_icnp_interv IS

    --------------------------------------------------------------------------------
    -- METHODS [UTILS]
    --------------------------------------------------------------------------------

    /**
     * Gets the index of the first element in the collection that has the given
     * composition identifier.
     * 
     * @param i_composition_id Identifier of the composition (an intervention).
     * @param i_interv_row_coll Collection of icnp_epis_intervention rows that will be
     *                          fetched.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 25/Jul/2011 (v2.6.1)
    */
    FUNCTION get_elem_index_by_compo
    (
        i_composition_id  IN icnp_epis_intervention.id_composition%TYPE,
        i_interv_row_coll IN ts_icnp_epis_intervention.icnp_epis_intervention_tc
    ) RETURN PLS_INTEGER;

    --------------------------------------------------------------------------------
    -- METHODS [GET INTERV ROW]
    --------------------------------------------------------------------------------

    /**
     * Gets the intervention data (icnp_epis_intervention row) of a given intervention
     * identifier given as input parameter.
     *
     * @param i_epis_interv_id The intervention identifier.
     * 
     * @return The intervention data (icnp_epis_intervention row).
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 5/Jun/2011 (v2.6.1)
    */
    FUNCTION get_interv_row(i_epis_interv_id IN icnp_epis_intervention.id_icnp_epis_interv%TYPE)
        RETURN icnp_epis_intervention%ROWTYPE;

    --------------------------------------------------------------------------------
    -- METHODS [GETS]
    --------------------------------------------------------------------------------

    /**
     * Counts the number of planned executions associated with a given intervention.
     * Are considered planned executions all of them that were not executed or 
     * cancelled.
     *
     * @param i_epis_interv_id The intervention identifier.
     *
     * @return The number of planned executions.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 17/Ago/2011 (v2.6.1)
    */
    FUNCTION get_interv_planned_execs_count(i_epis_interv_id IN icnp_epis_intervention.id_icnp_epis_interv%TYPE)
        RETURN PLS_INTEGER;

    /**
     * Checks if a given intervention is associated and active for a certain patient.
     *
     * @param i_patient The patient identifier.
     * @param i_interv_compo The intervention identifier. 
     * 
     * @return Identifier of the icnp_epis_intervention that is already active for the given patient.
     *
     * @author Luis Oliveira
     * @version 1.0
     * @since 06/Jun/2011
    */
    FUNCTION get_interv_existent_id
    (
        i_patient      IN patient.id_patient%TYPE,
        i_interv_compo IN icnp_epis_intervention.id_composition%TYPE,
        i_episode      IN episode.id_episode%TYPE
        
    ) RETURN icnp_epis_intervention.id_icnp_epis_interv%TYPE;

    --------------------------------------------------------------------------------
    -- METHODS [CREATE INTERV]
    --------------------------------------------------------------------------------

    /**
     * Creates an icnp_epis_intervention record based in the input parameters and in some
     * default values that should be set when a new record is created.
     *
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_episode The episode identifier.
     * @param i_patient The patient identifier.
     * @param i_interv The identifier of the intervention that we want to insert.
     * @param i_flg_time Flag that indicates in which episode the task should be performed.
     * @param i_dt_begin_tstz Date that indicates when the task should be performed.
     * @param i_notes Notes of the intervention request.
     * @param i_order_recurr_plan Identifier of the recurrence plan.
     * @param i_flg_prn Flag that indicates if the intervention should only be executed as 
     *                  the situation demands.
     * @param i_prn_notes Notes to indicate the conditions under which the intervention 
     *                    should be executed.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * 
     * @return A icnp_epis_intervention record prepared to be inserted.
     *
     * @author Luis Oliveira
     * @version 1.0
     * @since 06/Jun/2011
    */
    FUNCTION create_interv_row
    (
        i_prof              IN profissional,
        i_episode           IN icnp_epis_intervention.id_episode%TYPE,
        i_patient           IN icnp_epis_intervention.id_patient%TYPE,
        i_interv            IN icnp_epis_intervention.id_composition%TYPE,
        i_flg_type          IN icnp_epis_intervention.flg_type%TYPE,
        i_flg_time          IN icnp_epis_intervention.flg_time%TYPE,
        i_dt_begin_tstz     IN icnp_epis_intervention.dt_begin_tstz%TYPE,
        i_notes             IN icnp_epis_intervention.notes%TYPE,
        i_order_recurr_plan IN icnp_epis_intervention.id_order_recurr_plan%TYPE,
        i_flg_prn           IN icnp_epis_intervention.flg_prn%TYPE,
        i_prn_notes         IN icnp_epis_intervention.prn_notes%TYPE,
        i_sysdate_tstz      IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN icnp_epis_intervention%ROWTYPE;

    /**
     * Creates a set of intervention records (icnp_epis_intervention rows). Each 
     * record of the collection is a icnp_epis_intervention row already with the data
     * that should be persisted in the database.
     *
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_episode_id The episode identifier.
     * @param i_interv_row_coll Collection of icnp_epis_intervention rows already with 
     *                          the data that should be persisted in the database.
     *
     * @author Luis Oliveira
     * @version 1.1
     * @since 27/Jul/2011 (v2.6.1)
    */
    PROCEDURE create_intervs
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_interv_row_coll IN ts_icnp_epis_intervention.icnp_epis_intervention_tc,
        i_sysdate_tstz    IN TIMESTAMP WITH LOCAL TIME ZONE
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
        i_interv_ids    IN table_number,
        i_cancel_reason IN icnp_epis_intervention.id_cancel_reason%TYPE,
        i_cancel_notes  IN icnp_epis_intervention.cancel_notes%TYPE,
        i_sysdate_tstz  IN TIMESTAMP WITH LOCAL TIME ZONE
    );

    PROCEDURE set_intervs_status_finish
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
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
        i_epis_interv_id IN icnp_epis_intervention.id_icnp_epis_interv%TYPE,
        i_cancel_reason  IN icnp_epis_intervention.id_cancel_reason%TYPE,
        i_cancel_notes   IN icnp_epis_intervention.cancel_notes%TYPE,
        i_sysdate_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE
    );

    --------------------------------------------------------------------------------
    -- METHODS [UPDATE INTERV STATUS FOR DIAG]
    --------------------------------------------------------------------------------

    /**
     * Resolves all the intervention records that are related with a set of
     * diagnosis. Usually this method is invoked when some action is performed
     * on the diagnosis.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_diag_ids The set of diagnosis identifiers.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * 
     * @see set_intervs_status_resolve
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    PROCEDURE set_interv_st_resol_for_diags
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_diag_ids     IN table_number,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE
    );

    /**
     * Pauses all the intervention records that are related with a set of
     * diagnosis. Usually this method is invoked when some action is performed
     * on the diagnosis.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_diag_ids The set of diagnosis identifiers.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * 
     * @see set_intervs_status_pause
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    PROCEDURE set_interv_st_pause_for_diags
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_diag_ids       IN table_number,
        i_suspend_reason IN icnp_epis_intervention.id_suspend_reason%TYPE,
        i_suspend_notes  IN icnp_epis_intervention.suspend_notes%TYPE,
        i_sysdate_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE
    );

    /**
     * Resumes all the intervention records that are related with a set of
     * diagnosis. Usually this method is invoked when some action is performed
     * on the diagnosis.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_diag_ids The set of diagnosis identifiers.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * 
     * @see set_intervs_status_resume
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    PROCEDURE set_interv_st_resume_for_diags
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_diag_ids     IN table_number,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE
    );

    /**
     * Cancels all the intervention records that are related with a set of
     * diagnosis. Usually this method is invoked when some action is performed
     * on the diagnosis.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_diag_ids The set of diagnosis identifiers.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * 
     * @see set_intervs_status_cancel
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    PROCEDURE set_interv_st_cancel_for_diags
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_diag_ids      IN table_number,
        i_cancel_reason IN icnp_epis_intervention.id_cancel_reason%TYPE,
        i_cancel_notes  IN icnp_epis_intervention.cancel_notes%TYPE,
        i_sysdate_tstz  IN TIMESTAMP WITH LOCAL TIME ZONE
    );

    --------------------------------------------------------------------------------
    -- METHODS [UPDATE INTERV STATUS AND DT NEXT]
    --------------------------------------------------------------------------------

    /**
     * Updates the status and the next execution date of an intervention record 
     * (icnp_epis_intervention row).
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_epis_interv_id The identifier of the intervention that we want to 
     *                         update.
     * @param i_action An action performed by the user that caused the status change.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    PROCEDURE update_interv_stat_and_dtnext
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_interv_id IN icnp_epis_intervention.id_icnp_epis_interv%TYPE,
        i_action         IN action.code_action%TYPE,
        i_sysdate_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE
    );

    /**
     * Updates the status and the next execution date of set of intervention records
     * (icnp_epis_intervention rows).
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_interv_ids The set of identifiers of the interventions that we want 
     *                     to update.
     * @param i_action An action performed by the user that caused the status change.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    PROCEDURE update_intervs_stat_and_dtnext
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_interv_ids   IN table_number,
        i_action       IN action.code_action%TYPE,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE
    );

    --------------------------------------------------------------------------------
    -- METHODS [CREATE AND GET INTERV EXEC]
    --------------------------------------------------------------------------------

    /**
     * This method receives a collection of intervention identifiers. For each
     * intervention identifier, gets the next execution id and adds it to a collection
     * for return. In the end we have a collection with the next execution to be 
     * performed for each intervention.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_interv_ids Collection with the intervention identifiers.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * 
     * @return A collection of records with the information needed to correctly execute 
     *         several interventions.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 27/Jul/2011 (v2.6.1)
    */
    FUNCTION create_get_intvs_nextexec_data
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_interv_ids   IN table_number,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN pk_icnp_type.t_exec_interv_coll;

    /**
     * Gets the next execution identifier for the intervention id given as input parameter.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_epis_interv_id The intervention identifier.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * 
     * @return A record with the information needed to correctly execute an intervention.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 27/Jul/2011 (v2.6.1)
    */
    FUNCTION create_get_intv_nextexec_data
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_interv_id IN icnp_epis_intervention.id_icnp_epis_interv%TYPE,
        i_sysdate_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN pk_icnp_type.t_exec_interv_rec;

    /**
     * Creates history records for all the interventions given as input parameter.
     * It is important to guarantee that before each update on an intervention 
     * record, a copy of the record is persisted. This is the mechanism we have
     * to present to the user all the changes made in the record through time.
     *
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_interv_coll Interventions records whose history will be created.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * @param o_interv_hist  Identifiers list of the created history records.
     *
     * @author Pedro Carneiro
     * @version 2.5.1
     * @since 2010/07/22
    */
    PROCEDURE create_interv_hist
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_interv_coll  IN ts_icnp_epis_intervention.icnp_epis_intervention_tc,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_interv_hist  OUT table_number
    );

    /**
     * Gets the intervention data (icnp_epis_diag_interv row) of all the intervention
     * identifiers given as input parameter.
     *
     * @param i_interv_ids Collection with the intervention identifiers.
     * 
     * @return Collection with the intervention data (icnp_epis_diag_interv row).
     * 
     * @author Nuno Neves
     * @version 1.0
     * @since 27-02-2012
    */
    FUNCTION get_iedi_rows(i_interv_ids IN table_number) RETURN ts_icnp_epis_diag_interv.icnp_epis_diag_interv_tc;

    /**
     * Gets the intervention data (icnp_epis_intervention row) of all the intervention
     * identifiers given as input parameter.
     *
     * @param i_interv_ids Collection with the intervention identifiers.
     * 
     * @return Collection with the intervention data (icnp_epis_intervention row).
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 5/Jun/2011 (v2.6.1)
    */
    FUNCTION get_interv_rows(i_interv_ids IN table_number) RETURN ts_icnp_epis_intervention.icnp_epis_intervention_tc;

    FUNCTION get_icnp_interv_desc
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN episode.id_episode%TYPE,
        i_id_icnp_epis_interv   IN icnp_epis_intervention.id_icnp_epis_interv%TYPE,
        i_flg_description       IN pn_dblock_ttp_mkt.flg_description%TYPE,
        i_description_condition IN pn_dblock_ttp_mkt.description_condition%TYPE
    ) RETURN CLOB;
END pk_icnp_interv;
/
