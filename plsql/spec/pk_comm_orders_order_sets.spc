/*-- Last Change Revision: $Rev: 1693828 $*/
/*-- Last Change by: $Author: ana.monteiro $*/
/*-- Date of last change: $Date: 2015-04-22 08:23:06 +0100 (qua, 22 abr 2015) $*/

CREATE OR REPLACE PACKAGE pk_comm_orders_order_sets IS

    -- Author  : TIAGO.SILVA
    -- Created : 26-02-2014
    -- Purpose : Publish communication orders API's to be used by the Order Sets tool

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
    * @param   i_id_prof_order              Order professional identifiers
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
    * Gets communication order title (title and notes)
    *
    * @param   i_lang                 Professional preferred language
    * @param   i_prof                 Professional identification and its context (institution and software)
    * @param   i_task_request         Communication order request id
    * @param   i_flg_with_notes       Flag that indicates if notes should appear under the title or not
    *
    * @return  boolean                True on sucess, otherwise false
    *
    * @author  tiago.silva
    * @version 1.0
    * @since   26-02-2014
    */
    FUNCTION get_task_title
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_task_request   IN comm_order_req.id_comm_order_req%TYPE,
        i_flg_with_notes IN VARCHAR2 DEFAULT 'N'
    ) RETURN VARCHAR2;

    /**
    * Gets communication order instructions
    *
    * @param   i_lang                 Professional preferred language
    * @param   i_prof                 Professional identification and its context (institution and software)
    * @param   i_task_request         Communication order request id
    * @param   i_flg_show_start_date  Flag that indicates if start date must be shown on instructions description or not
    * @param   o_task_instr           Task instructions
    * @param   o_error                error structure for exception handling
    *
    * @return  boolean                True on sucess, otherwise false
    *
    * @author  tiago.silva
    * @version 1.0
    * @since   26-02-2014
    */
    FUNCTION get_task_instructions
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_task_request        IN comm_order_req.id_comm_order_req%TYPE,
        i_flg_show_start_date IN VARCHAR2,
        o_task_instr          OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Creates a predefined communication order request
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
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
    * @param   o_id_comm_order_req         Array of communication orders request identifiers that were created or updated
    * @param   o_error                      Error information
    *
    * @value   i_flg_free_text              {*} Y- free text {*} N- otherwise
    * @value   i_flg_priority               {*} R- Routine {*} A- ASAP {*} S- STAT
    * @value   i_flg_prn                    {*} Y- is PRN {*} N- otherwise
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  tiago.silva
    * @version 1.0
    * @since   26-02-2014
    */
    FUNCTION create_predefined_task
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_comm_order         IN table_number,
        i_id_comm_order_type    IN table_number,
        i_flg_free_text         IN table_varchar,
        i_desc_comm_order       IN table_clob,
        i_notes                 IN table_clob,
        i_clinical_indication   IN table_clob,
        i_flg_clinical_purpose  IN table_varchar,
        i_clinical_purpose_desc IN table_varchar,
        i_flg_priority          IN table_varchar,
        i_flg_prn               IN table_varchar,
        i_prn_condition         IN table_clob,
        o_id_comm_order_req     OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancels predefined tasks
    *
    * @param   i_lang           Professional preferred language
    * @param   i_prof           Professional identification and its context (institution and software)
    * @param   i_task_request   Array of task request identifiers
    * @param   o_error          Error information
    *
    * @return  boolean          True on sucess, otherwise false
    *
    * @author  tiago.silva
    * @version 1.0
    * @since   26-02-2014
    */
    FUNCTION cancel_predefined_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancels a communication order request, updating state to canceled
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_comm_order_req         Array of communication orders request identifiers
    * @param   i_id_episode                 Episode identifier
    * @param   i_id_cancel_reason           Cancel reason identifier
    * @param   i_notes_cancel               Cancelling notes
    * @param   i_dt_order                   Co-sign order date
    * @param   i_id_prof_order              Co-sign order professional identifier
    * @param   i_id_order_type              Co-sign request order type (telephone, verbal, ...)
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   20-02-2014
    */
    FUNCTION set_action_cancel
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_comm_order_req IN table_number,
        i_id_episode        IN comm_order_req.id_episode%TYPE,
        i_id_cancel_reason  IN comm_order_req.id_cancel_reason%TYPE,
        i_notes_cancel      IN pk_translation.t_lob_char,
        i_dt_order          IN co_sign.dt_ordered_by%TYPE,
        i_id_prof_order     IN co_sign.id_prof_ordered_by%TYPE,
        i_id_order_type     IN co_sign.id_order_type%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Checks if a communication order can be executed or not
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_episode                    Episode Id
    * @param   i_id_comm_order_req         Communication order request Id
    * @param   o_flg_conflict               Conflict status 
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  tiago.silva
    * @version 1.0
    * @since   27-02-2014
    */
    FUNCTION check_comm_order_conflict
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_id_comm_order_req IN comm_order_req.id_comm_order_req%TYPE,
        o_flg_conflict      OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Checks if a communication order can be canceled or not
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_episode                    Episode Id
    * @param   i_id_comm_order_req         Communication order request Id
    * @param   o_flg_cancel                 Flag that indicates if cancel option is available or not for this communication order
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  tiago.silva
    * @version 1.0
    * @since   27-02-2014
    */
    FUNCTION check_comm_order_cancel
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_id_comm_order_req IN comm_order_req.id_comm_order_req%TYPE,
        o_flg_cancel        OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets communication orders status
    *
    * @param   i_lang                 Professional preferred language
    * @param   i_prof                 Professional identification and its context (institution and software)
    * @param   i_episode              episode id
    * @param   i_task_request         array of communication order request ids
    * @param   o_date_limits          cursor with communication 
    * @param   o_error                error structure for exception handling
    *
    * @return  boolean                True on sucess, otherwise false
    *
    * @author  tiago.silva
    * @version 1.0
    * @since   25-02-2014
    */
    FUNCTION get_date_limits
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN table_number,
        o_date_limits  OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Creates a new communication order request based on an existing one (copy)
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_comm_order_req         Communication order request identifier
    * @param   i_id_patient                 New patient identifier. If null, copy value from the original
    * @param   i_id_episode                 New episode identifier. If null, copy value from the original
    * @param   i_dt_begin                   New begin date. If null, copy value from the original
    * @param   o_id_comm_order_req         New communication order req identifier created
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  tiago.silva
    * @version 1.0
    * @since   27-02-2014
    */
    FUNCTION copy_comm_order_req
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_comm_order_req IN comm_order_req.id_comm_order_req%TYPE,
        i_id_patient        IN comm_order_req.id_patient%TYPE DEFAULT NULL,
        i_id_episode        IN comm_order_req.id_episode%TYPE DEFAULT NULL,
        i_dt_begin          IN comm_order_req.dt_begin%TYPE DEFAULT NULL,
        o_id_comm_order_req OUT comm_order_req.id_comm_order_req%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets communication order status string
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_comm_order_req         Communication order request Id
    * @param   o_task_status                Communication order status string
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  tiago.silva
    * @version 1.0
    * @since   28-02-2014
    */
    FUNCTION get_comm_order_status
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_comm_order_req IN comm_order_req.id_comm_order_req%TYPE,
        o_task_status       OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets communication order icon
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_comm_order_req         Communication order request Id
    *
    * @return  varchar2                     Communication order icon
    *
    * @author  tiago.silva
    * @version 1.0
    * @since   28-02-2014
    */
    FUNCTION get_comm_order_icon
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_comm_order_req IN comm_order_req.id_comm_order_req%TYPE
    ) RETURN VARCHAR2;

    /**
    * Order a communication order request, updating state to ongoing
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_episode                 New episode identifier. If null mantains the value
    * @param   i_id_comm_order_req         Array of communication orders request identifiers
    * @param   i_dt_order                   Order date. Format YYYYMMDDhh24miss
    * @param   i_id_prof_order              Order professional identifiers
    * @param   i_id_order_type              Request order type (telephone, verbal, ...)
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  tiago.silva
    * @version 1.0
    * @since   28-02-2014
    */
    FUNCTION set_action_order
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN comm_order_req.id_episode%TYPE DEFAULT NULL,
        i_id_comm_order_req IN table_number,
        i_dt_order          IN co_sign.dt_ordered_by%TYPE,
        i_id_prof_order     IN co_sign.id_prof_ordered_by%TYPE,
        i_id_order_type     IN co_sign.id_order_type%TYPE,        
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Updates a communication order request clinical indication
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_comm_order_req         Array of communication orders request identifiers
    * @param   i_clinical_indication        Clinical indication information
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  tiago.silva
    * @version 1.0
    * @since   03-03-2014
    */
    FUNCTION update_comm_order_clin_ind
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_comm_order_req   IN table_number,
        i_clinical_indication IN pk_translation.t_lob_char,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Checks if a given communication order needs co-sign to be ordered
    *
    * @param   i_lang                     Professional preferred language
    * @param   i_prof                     Professional identification and its context (institution and software)
    * @param   i_episode                  Episode id
    * @param   o_flg_prof_needs_cosign    Professional needs co-sign to order? (Y - Yes; N - No)    
    * @param   o_error                    Error information
    *
    * @return  boolean                    True on sucess, otherwise false
    *
    * @author  tiago.silva
    * @since   27-MAR-2015
    */
    FUNCTION check_prof_needs_cosign2order
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        o_flg_prof_needs_cosign OUT VARCHAR2,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Checks if a given communication order needs co-sign to be canceled
    *
    * @param   i_lang                     Professional preferred language
    * @param   i_prof                     Professional identification and its context (institution and software)
    * @param   i_episode                  Episode id
    * @param   o_flg_prof_needs_cosign    Professional needs co-sign to cancel? (Y - Yes; N - No)
    * @param   o_error                    Error information
    *
    * @return  boolean                    True on sucess, otherwise false
    *
    * @author  tiago.silva
    * @since   27-MAR-2015
    */
    FUNCTION check_prof_needs_cosign2cancel
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        o_flg_prof_needs_cosign OUT VARCHAR2,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

END pk_comm_orders_order_sets;
/
