/*-- Last Change Revision: $Rev: 2028727 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:34 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_icnp_diag IS

    --------------------------------------------------------------------------------
    -- METHODS [CREATE]
    --------------------------------------------------------------------------------

    /**
     * Creates an icnp_epis_diagnosis record based in the input parameters and in some
     * default values that should be set when a new record is created.
     *
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_episode The episode identifier.
     * @param i_patient The patient identifier.
     * @param i_visit The visit identifier.
     * @param i_epis_type The identifier of the type of episode.
     * @param i_diag Identifier of the diagnose to insert.
     * @param i_exp_res Identifier of the expected results for the diagnose.
     * @param i_notes Notes for the diagnose.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * 
     * @return A icnp_epis_diagnosis record prepared to be inserted.
     *
     * @author Luis Oliveira
     * @version 1.0
     * @since 3/Jun/2011
    */
    FUNCTION create_diag_row
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN icnp_epis_diagnosis.id_episode%TYPE,
        i_patient      IN icnp_epis_diagnosis.id_patient%TYPE,
        i_visit        IN icnp_epis_diagnosis.id_visit%TYPE,
        i_epis_type    IN icnp_epis_diagnosis.id_epis_type%TYPE,
        i_diag         IN icnp_epis_diagnosis.id_icnp_epis_diag%TYPE,
        i_exp_res      IN icnp_epis_diagnosis.icnp_compo_reeval%TYPE,
        i_notes        IN icnp_epis_diagnosis.notes%TYPE,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN icnp_epis_diagnosis%ROWTYPE;

    /**
     * Creates a set of diagnosis records (icnp_epis_diagnosis rows). Each 
     * record of the collection is a icnp_epis_diagnosis row already with the data
     * that should be persisted in the database.
     *
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_diag_coll Collection of icnp_epis_diagnosis rows already with the
     *                    data that should be persisted in the database.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     *
     * @author Luis Oliveira
     * @version 1.1
     * @since 27/Jul/2011 (v2.6.1)
    */
    PROCEDURE create_diags
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_diag_coll    IN ts_icnp_epis_diagnosis.icnp_epis_diagnosis_tc,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE
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
        i_diag_ids       IN table_number,
        i_composition_id IN icnp_epis_diagnosis.id_composition%TYPE,
        i_sysdate_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_notes          IN table_varchar
    );

    /**
     * Makes the necessary updates to a set of diagnosis records (icnp_epis_diagnosis rows)
     * when the user resolves the diagnosis. Resolved is a final status, no more changes 
     * to the record can be made.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
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
        i_diag_ids     IN table_number,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE
    );

    /**
     * Makes the necessary updates to a set of diagnosis records (icnp_epis_diagnosis rows)
     * when the user suspends the diagnosis. When a diagnose is suspended, no actions
     * (excluding the resume) could be performed.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
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
     * like for example, reevaluate, resolve or cancel. 
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
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
        i_diag_ids     IN table_number,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE
    );

    /**
     * Makes the necessary updates to a set of diagnosis records (icnp_epis_diagnosis rows)
     * when the user cancels the diagnosis. When the diagnose is cancelled the user can't 
     * make any more changes.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
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
        i_diag_ids      IN table_number,
        i_cancel_reason IN icnp_epis_diagnosis.id_cancel_reason%TYPE,
        i_cancel_notes  IN icnp_epis_diagnosis.cancel_notes%TYPE,
        i_sysdate_tstz  IN TIMESTAMP WITH LOCAL TIME ZONE
    );

    FUNCTION get_icnp_diagnosis_desc
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN episode.id_episode%TYPE,
        i_id_icnp_epis_diag     IN icnp_epis_diagnosis.id_icnp_epis_diag%TYPE,
        i_flg_description       IN pn_dblock_ttp_mkt.flg_description%TYPE,
        i_description_condition IN pn_dblock_ttp_mkt.description_condition%TYPE
    ) RETURN CLOB;
END pk_icnp_diag;
/
