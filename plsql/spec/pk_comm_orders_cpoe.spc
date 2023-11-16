/*-- Last Change Revision: $Rev: 1991069 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2021-06-04 15:35:16 +0100 (sex, 04 jun 2021) $*/

CREATE OR REPLACE PACKAGE pk_comm_orders_cpoe IS

    -- Author  : ANA.MONTEIRO
    -- Created : 21-02-2014 15:35:37
    -- Purpose :

    /**
    * Creates a draft communication order request
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_patient                 Patient identifier
    * @param   i_id_episode                 Episode identifier
    * @param   i_id_comm_order              Array of communication orders identifier
    * @param   i_id_comm_order_type         Array of communication orders types identifiers
    * @param   i_flg_free_text              Array of flags indicating if this communication orders is free text
    * @param   i_desc_comm_order            Array of communication orders request description (in case of free text)
    * @param   i_notes                      Array of communication orders request notes
    * @param   i_clinical_indication        Array of clinical indication information
    * @param   i_flg_clinical_purpose       Array of flags that indicates the clinical purpose
    * @param   i_clinical_purpose_desc      Array of clinical purpose descriptions
    * @param   i_flg_priority               Array of flags that indicates the priority
    * @param   i_flg_prn                    Array of flags that indicates whether the communication orders is PRN or not
    * @param   i_prn_condition              Array of notes to indicate the PRN conditions
    * @param   i_dt_begin_str               Array of start dates. Format YYYYMMDDhh24miss
    * @param   i_dt_order_str               Array of order dates. Format YYYYMMDDhh24miss
    * @param   i_id_prof_order              Array of order professional identifiers
    * @param   i_id_order_type              Array of request order types (telephone, verbal, ...)
    * @param   o_id_comm_order_req         Array of communication orders request identifiers that were created or updated
    * @param   o_error                      Error information
    *
    * @value   i_flg_free_text              {*} Y- free text {*} N- otherwise
    * @value   i_flg_priority               {*} R- Routine {*} A- ASAP {*} S- STAT
    * @value   i_flg_prn                    {*} Y- is PRN {*} N- otherwise
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   20-02-2014
    */
    FUNCTION create_draft
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_patient              IN comm_order_req.id_patient%TYPE,
        i_id_episode              IN comm_order_req.id_episode%TYPE,
        i_id_comm_order           IN table_number,
        i_id_comm_order_type      IN table_number,
        i_flg_free_text           IN table_varchar,
        i_desc_comm_order         IN table_clob,
        i_notes                   IN table_clob,
        i_clinical_indication     IN table_clob,
        i_flg_clinical_purpose    IN table_varchar,
        i_clinical_purpose_desc   IN table_varchar,
        i_flg_priority            IN table_varchar,
        i_flg_prn                 IN table_varchar,
        i_prn_condition           IN table_clob,
        i_dt_begin_str            IN table_varchar,
        i_dt_order_str            IN table_varchar,
        i_id_prof_order           IN table_number,
        i_id_order_type           IN table_number,
        i_task_duration           IN table_number,
        i_order_recurr            IN table_number,
        i_clinical_question       IN table_table_number,
        i_response                IN table_table_varchar,
        i_clinical_question_notes IN table_table_varchar,
        i_task_type               IN NUMBER,
        o_id_comm_order_req       OUT table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Updates a task
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_comm_order_req         Array of communication orders request identifiers
    * @param   i_flg_free_text              Flag indicating if this communication orders is free text
    * @param   i_desc_comm_order            Communication orders request description (in case of free text)
    * @param   i_notes                      Communication orders request notes
    * @param   i_clinical_indication        Clinical indication information
    * @param   i_flg_clinical_purpose       Flag that indicates the clinical purpose
    * @param   i_clinical_purpose_desc      Clinical purpose descriptions
    * @param   i_flg_priority               Flag that indicates the priority
    * @param   i_flg_prn                    Flag that indicates whether the communication orders is PRN or not
    * @param   i_prn_condition              Notes to indicate the PRN conditions
    * @param   i_dt_begin_str               Start date. Format YYYYMMDDhh24miss
    * @param   i_dt_order_str               Order date. Format YYYYMMDDhh24miss
    * @param   i_id_prof_order              Order professional identifier
    * @param   i_id_order_type              Request order type (telephone, verbal, ...)
    * @param   o_error                      Error information
    *
    * @value   i_flg_free_text              {*} Y- free text {*} N- otherwise
    * @value   i_flg_priority               {*} R- Routine {*} A- ASAP {*} S- STAT
    * @value   i_flg_prn                    {*} Y- is PRN {*} N- otherwise
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   25-02-2014
    */
    FUNCTION set_task_parameters
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_comm_order_req     IN table_number,
        i_flg_free_text         IN table_varchar,
        i_desc_comm_order       IN table_clob,
        i_notes                 IN table_clob,
        i_clinical_indication   IN table_clob,
        i_flg_clinical_purpose  IN table_varchar,
        i_clinical_purpose_desc IN table_varchar,
        i_flg_priority          IN table_varchar,
        i_flg_prn               IN table_varchar,
        i_prn_condition         IN table_clob,
        i_dt_begin_str          IN table_varchar,
        i_dt_order_str          IN table_varchar,
        i_id_prof_order         IN table_number,
        i_id_order_type         IN table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Expire tasks action (task will change its state to expired)
    *
    * @param   i_lang           Professional preferred language
    * @param   i_prof           Professional identification and its context (institution and software)
    * @param   i_episode        Episode identifier
    * @param   i_task_requests  Array of task request ids to expire
    * @param   o_error          Error information
    *
    * @return  boolean          True on sucess, otherwise false
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   21-02-2014
    */
    FUNCTION expire_task
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_task_requests IN table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get actions available to a task
    *
    * @param   i_lang           Professional preferred language
    * @param   i_prof           Professional identification and its context (institution and software)
    * @param   i_episode        Episode identifier
    * @param   i_task_request   Array of task request identifiers to get the actions available
    * @param   o_error          Error information
    *
    * @return  boolean          True on sucess, otherwise false
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   21-02-2014
    */
    FUNCTION get_task_actions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN table_number,
        i_task_type    IN NUMBER,
        o_action       OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Changes task from state
    *
    * @param   i_lang           Professional preferred language
    * @param   i_prof           Professional identification and its context (institution and software)
    * @param   i_episode        Episode identifier
    * @param   i_action         Action identifier
    * @param   i_task_request   Array with task request identifiers
    * @param   o_error          Error information
    *
    * @return  boolean          True on sucess, otherwise false
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   21-02-2014
    */
    FUNCTION set_action
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_action       IN action.id_action%TYPE,
        i_task_request IN table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Check conflicts upon created drafts (verify if drafts can be requested or not)
    *
    * @param   i_lang           Professional preferred language
    * @param   i_prof           Professional identification and its context (institution and software)
    * @param   i_episode        Episode identifier
    * @param   i_draft          Draft identifier
    * @param   o_flg_conflict   Array of draft conflicts indicators
    * @param   o_msg_template   Array of message/pop-up templates
    * @param   o_msg_title      Array of message titles
    * @param   o_msg_body       Array of message bodies
    * @param   o_error          Error information
    *
    * @value   o_flg_conflict   {*} 'Y' the draft has conflicts
    *                           {*} 'N' no conflicts found
    *
    * @value   o_msg_template   {*} 'WARNING_READ' Warning Read
    *                           {*} 'WARNING_CONFIRMATION' Warning Confirmation
    *                           {*} 'WARNING_CANCEL' Warning Cancel
    *                           {*} 'WARNING_HELP_SAVE' Warning Help Save
    *                           {*} 'WARNING_SECURITY' Warning Security
    *                           {*} 'CONFIRMATION' Confirmation
    *                           {*} 'DETAIL' Detail
    *                           {*} 'HELP' Help
    *                           {*} 'WIZARD' Wizard
    *                           {*} 'ADVANCED_INPUT' Advanced Input
    *
    * @return  boolean          True on sucess, otherwise false
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   21-02-2014
    */
    FUNCTION check_draft_conflicts
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_draft        IN table_number,
        o_flg_conflict OUT table_varchar,
        o_msg_title    OUT table_varchar,
        o_msg_body     OUT table_varchar,
        o_msg_template OUT table_varchar,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Changes task from state
    *
    * @param   i_lang           Professional preferred language
    * @param   i_prof           Professional identification and its context (institution and software)
    * @param   i_episode        Episode identifier
    * @param   i_task_request   Task request identifier to get the actions available
    * @param   o_error          Error information
    *
    * @return  boolean          True on sucess, otherwise false
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   21-02-2014
    */
    FUNCTION copy_to_draft
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN episode.id_episode%TYPE,
        i_task_request         IN cpoe_process_task.id_task_request%TYPE,
        i_task_start_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_task_end_timestamp   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_task_type            IN task_type.id_task_type%TYPE DEFAULT NULL,
        o_draft                OUT cpoe_process_task.id_task_request%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Activates draft tasks
    *
    * @param   i_lang           Professional preferred language
    * @param   i_prof           Professional identification and its context (institution and software)
    * @param   i_episode        Episode identifier
    * @param   i_draft          Array of task requests identifiers
    * @param   i_flg_commit     Flag that indicates to commit transaction (or not)
    * @param   o_created_tasks  Array with created task request Ids
    * @param   o_error          Error information
    *
    * @return  boolean          True on sucess, otherwise false
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   21-02-2014
    */
    FUNCTION activate_drafts
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_draft         IN table_number,
        i_flg_commit    IN VARCHAR2,
        o_created_tasks OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancels all draft tasks related to the visit of this episode
    *
    * @param   i_lang           Professional preferred language
    * @param   i_prof           Professional identification and its context (institution and software)
    * @param   i_episode        Episode identifier
    * @param   o_error          Error information
    *
    * @return  boolean          True on sucess, otherwise false
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   24-02-2014
    */
    FUNCTION cancel_all_drafts
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancels draft tasks
    *
    * @param   i_lang           Professional preferred language
    * @param   i_prof           Professional identification and its context (institution and software)
    * @param   i_episode        Episode identifier
    * @param   i_draft          Array of task request identifiers
    * @param   o_error          Error information
    *
    * @return  boolean          True on sucess, otherwise false
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   24-02-2014
    */
    FUNCTION cancel_draft
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_draft   IN table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets communication orders list
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_patient                    Patient id
    * @param   i_episode                    Episode id
    * @param   i_task_request               Communication order request id
    * @param   i_filter_tstz                Date filter (used by CPOE),
    * @param   i_filter_status              Status filter (used by CPOE),
    * @param   i_flg_report                 Flag that indicates if this function was called to get data to generate report (used by CPOE)
    *
    * @value   i_flg_report                 {*} Y- called to get data to generate report {*} N- otherwise
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  tiago.silva
    * @version 1.0
    * @since   24-02-2014
    */
    FUNCTION get_comm_order_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_task_request   IN table_number,
        i_filter_tstz    IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_filter_status  IN table_varchar,
        i_flg_report     IN VARCHAR2 DEFAULT 'N',
        i_cpoe_task_type IN cpoe_task_type.id_task_type%TYPE DEFAULT NULL,
        i_dt_begin       IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_dt_end         IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_plan_list      OUT pk_types.cursor_type,
        o_task_list      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets communication orders status
    *
    * @param   i_lang                 Professional preferred language
    * @param   i_prof                 Professional identification and its context (institution and software)
    * @param   i_episode              episode id
    * @param   i_task_request         array of communication order request ids
    * @param   o_task_status          cursor with all communication order tasks status
    * @param   o_error                error structure for exception handling
    *
    * @return  boolean                True on sucess, otherwise false
    *
    * @author  tiago.silva
    * @version 1.0
    * @since   25-02-2014
    */
    FUNCTION get_task_status
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN table_number,
        o_task_status  OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

END pk_comm_orders_cpoe;
/
