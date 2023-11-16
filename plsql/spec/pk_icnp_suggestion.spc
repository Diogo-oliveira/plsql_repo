/*-- Last Change Revision: $Rev: 2028734 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:36 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_icnp_suggestion IS

    --------------------------------------------------------------------------------
    -- METHODS [GETS EXTERNAL TASK]
    --------------------------------------------------------------------------------

    /**
     * Gets the description of a task that is associated with a therapeutic attitude.
     *
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_request_id The identifier of the external request.
     * @param i_task_type_id Identifier of the external task type.
     *
     * @return The description of a task that is associated with a therapeutic 
     *         attitude.
     * 
     * @author Joao Martins
     * @version (?)
     * @since (?)
    */
    FUNCTION get_sugg_task_description
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_request_id   IN icnp_suggest_interv.id_req%TYPE,
        i_task_type_id IN icnp_suggest_interv.id_task_type%TYPE
    ) RETURN VARCHAR2;

    /**
     * Gets the instructions of a task that is associated with a therapeutic 
     * attitude.
     *
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_request_id The identifier of the external request.
     * @param i_task_type_id Identifier of the external task type.
     *
     * @return The instructions of a task that is associated with a therapeutic 
     *         attitude.
     * 
     * @author Joao Martins
     * @version (?)
     * @since (?)
    */
    FUNCTION get_sugg_task_instructions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_request_id   IN icnp_suggest_interv.id_req%TYPE,
        i_task_type_id IN icnp_suggest_interv.id_task_type%TYPE
    ) RETURN VARCHAR2;

    /**
     * Gets the status of a task that is associated with a therapeutic attitude.
     *
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_request_id The identifier of the external request.
     * @param i_task_type_id Identifier of the external task type.
     *
     * @return The status of a task that is associated with a therapeutic 
     *         attitude.
     * 
     * @author Joao Martins
     * @version (?)
     * @since (?)
    */
    FUNCTION get_sugg_task_status
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_request_id   IN icnp_suggest_interv.id_req%TYPE,
        i_task_type_id IN icnp_suggest_interv.id_task_type%TYPE
    ) RETURN VARCHAR2;

    --------------------------------------------------------------------------------
    -- METHODS [CREATE]
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
        i_episode_id         IN episode.id_episode%TYPE,
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
     * @param i_episode_id The episode identifier.
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
        i_episode_id         IN episode.id_episode%TYPE,
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
        i_sugg_ids     IN table_number,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE
    );

    /**
     * Accepts all the suggestions with identifiers that are in the collection given 
     * as input parameter (i_interv_suggested_coll). The collection is composed by
     * records with the identifier of the suggestion and the identifier of the 
     * intervention that we want to associated with the suggestion.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_episode_id The episode identifier.
     * @param i_interv_suggested_coll Collection with the suggestion and the intervention 
     *                                identifier.
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
    PROCEDURE set_suggs_status_accept
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode_id            IN icnp_suggest_interv.id_episode%TYPE,
        i_interv_suggested_coll IN pk_icnp_type.t_interv_suggested_coll,
        i_sysdate_tstz          IN TIMESTAMP WITH LOCAL TIME ZONE
    );

    /**
     * Cancels all the suggestions with identifiers that are in the collection given 
     * as input parameter.
     *
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_sugg_ids Collection with the suggestion identifiers.
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

END pk_icnp_suggestion;
/
