/*-- Last Change Revision: $Rev: 1917580 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2019-09-19 09:26:02 +0100 (qui, 19 set 2019) $*/

CREATE OR REPLACE PACKAGE pk_comm_orders_ux IS

    -- Author  : ANA.MONTEIRO
    -- Created : 13-02-2014 17:21:47
    -- Purpose : 

    /**
    * Get the list of communication order types
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   o_list               Cursor containing information about communication order types
    * @param   o_error              Error information
    *
    * @return  boolean              True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   13-02-2014
    */
    FUNCTION get_comm_order_type_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_task_type IN NUMBER,
        o_list      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get the list of communication orders related to this communication order type
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_id_comm_order_type Communication order type identifier
    * @param   i_id_comm_order_par  Communication order parent identifier. If specified, returns all communication orders 'sons'
    * @param   o_list               Cursor containing information about communication orders
    * @param   o_error              Error information
    *
    * @return  boolean              True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   13-02-2014
    */
    FUNCTION get_comm_order_selection_list
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_comm_order_type IN NUMBER, -- COMMUNICATION_ORDERS_EA.id_concept_type%TYPE
        i_id_comm_order_par  IN NUMBER, -- COMMUNICATION_ORDERS_EA.id_concept_term%TYPE
        i_task_type          IN NUMBER,
        o_list               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Search communication orders by name 
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_comm_order_search  String to search for communication orders
    * @param   o_list               Cursor containing information about communication orders 
    * @param   o_error              Error information
    *
    * @return  boolean              True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   13-02-2014
    */
    FUNCTION get_comm_order_search
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_comm_order_search IN pk_translation.t_desc_translation,
        o_list              OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns a list of options with the clinical purpose for a communication order
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)    
    * @param   o_error              Error information
    *
    * @return  boolean              True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   14-02-2014
    */
    FUNCTION get_clinical_purpose
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns a list of options with the priority for a communication order
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)    
    * @param   o_error              Error information
    *
    * @return  boolean              True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   14-02-2014
    */
    FUNCTION get_priority
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns a list of options with the prn for a communication order
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)    
    * @param   o_error              Error information
    *
    * @return  boolean              True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   14-02-2014
    */
    FUNCTION get_prn
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns a list of options with diagnoses for a communication order
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)    
    * @param   o_error              Error information
    *
    * @return  boolean              True on sucess, otherwise false
    *
    * @author  tiago.silva
    * @version 1.0
    * @since   18-02-2014
    */
    FUNCTION get_diagnoses_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns instructions default
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)    
    * @param   i_id_comm_order              Array of communication order identifiers
    * @param   i_id_comm_order_type         Array of communication order types identifiers
    * @param   o_list                       Cursor containing information about instructions default
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   19-02-2014
    */
    FUNCTION get_instructions_default
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_comm_order      IN table_number,
        i_id_comm_order_type IN table_number,
        o_list               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_comm_order_summary
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_episode                 IN episode.id_episode%TYPE,
        i_id_comm_order_req       IN comm_order_req.id_comm_order_req%TYPE,
        o_comm_order              OUT pk_types.cursor_type,
        o_comm_clinical_questions OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Creates an ongoing communication order request
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_patient                 Patient identifier    
    * @param   i_id_episode                 Episode identifier
    * @param   i_id_comm_order              Array of communication order identifiers
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
    FUNCTION create_comm_order_req_ong
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
        i_task_duration           IN table_number, --20
        i_order_recurr            IN table_number,
        i_clinical_question       IN table_table_number,
        i_response                IN table_table_varchar,
        i_clinical_question_notes IN table_table_varchar,
        i_task_type               IN NUMBER,
        o_id_comm_order_req       OUT table_number,
        o_error                   OUT t_error_out
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
    * @author  ana.monteiro
    * @version 1.0
    * @since   20-02-2014
    */
    /*
    FUNCTION create_comm_order_req_predf
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_comm_order        IN table_number,
        i_id_comm_order_type   IN table_number,
        i_flg_free_text        IN table_varchar,
        i_desc_comm_order      IN table_clob,
        i_notes                IN table_clob,
        i_clinical_indication  IN table_clob,
        i_flg_clinical_purpose IN table_varchar,
        i_flg_priority         IN table_varchar,
        i_flg_prn              IN table_varchar,
        i_prn_condition        IN table_clob,
        o_id_comm_order_req    OUT table_number,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;
    */

    /**
    * Updates a communication order request
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
    * @author  ana.monteiro
    * @version 1.0
    * @since   20-02-2014
    */
    FUNCTION update_comm_order_req
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_episode                 IN episode.id_episode%TYPE,
        i_id_comm_order_req       IN table_number,
        i_flg_free_text           IN table_varchar,
        i_desc_comm_order         IN table_clob,
        i_notes                   IN table_clob,
        i_clinical_indication     IN table_clob,
        i_flg_clinical_purpose    IN table_varchar,
        i_clinical_purpose_desc   IN table_varchar,
        i_flg_priority            IN table_varchar,
        i_flg_prn                 IN table_varchar,
        i_prn_condition           IN table_clob,
        i_dt_order_str            IN table_varchar,
        i_id_prof_order           IN table_number,
        i_id_order_type           IN table_number,
        i_task_duration           IN table_number,
        i_dt_begin_str            IN table_varchar,
        i_order_recurr            IN table_number,
        i_clinical_question       IN table_table_number,
        i_response                IN table_table_varchar,
        i_clinical_question_notes IN table_table_varchar,
        o_error                   OUT t_error_out
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
    * @param   i_id_order_type              Co-sign request order type (telephone, verbal, ...)
    * @param   i_id_prof_order              Co-sign order professional identifier
    * @param   i_dt_order                   Co-sign order date. Format YYYYMMDDHH24MISS    
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
        i_id_order_type     IN co_sign.id_order_type%TYPE,
        i_id_prof_order     IN co_sign.id_prof_ordered_by%TYPE,
        i_dt_order          IN VARCHAR2,
        i_task_type         IN task_type.id_task_type%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets communication order requests information
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)    
    * @param   i_id_comm_order_req         Array of communication orders requests identifiers
    * @param   o_info                       Information about communication order requests
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   24-02-2014
    */
    FUNCTION get_comm_order_req_info
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_comm_order_req       IN table_number,
        o_info                    OUT pk_types.cursor_type,
        o_comm_clinical_questions OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets communication order requests to be shown in detail screen
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)    
    * @param   i_id_comm_order_req         Communication orders request identifier
    * @param   o_status                     Status description
    * @param   o_title                      Title description
    * @param   o_cur_current                Communication order current information
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   24-02-2014
    */
    FUNCTION get_comm_order_req_detail
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_comm_order_req IN comm_order_req.id_comm_order_req%TYPE,
        i_task_type         IN task_type.id_task_type%TYPE,
        o_status            OUT VARCHAR2,
        o_title             OUT VARCHAR2,
        o_cur_current       OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets communication order requests to be shown in history detail screen
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)    
    * @param   i_id_comm_order_req         Communication orders request identifier
    * @param   o_cur_hist                   Communication order history information
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   27-02-2014
    */
    FUNCTION get_comm_order_req_detail_h
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_comm_order_req IN comm_order_req.id_comm_order_req%TYPE,
        o_cur_hist          OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get the information of communication orders requests identifiers
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_id_comm_order_req Array of communication orders requests identifiers
    * @param   o_list               Cursor containing information of communication orders requests
    * @param   o_error              Error information
    *
    * @return  boolean              True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   18-03-2014
    */
    FUNCTION get_comm_order_req_type
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_comm_order_req IN table_number,
        o_list              OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns communication order detail for the viewer
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_comm_order_req             Communication order request identifier
    * @param   o_detail                     Cursor containing communication order req detail
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @since   04-12-2014
    */
    FUNCTION get_comm_order_viewer_detail
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_comm_order_req IN comm_order_req.id_comm_order_req%TYPE,
        o_detail         OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_comm_order_questionnaire
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_comm_order    IN comm_order_ea.id_comm_order%TYPE,
        i_flg_time      IN VARCHAR2,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        o_list          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_comm_order_execution_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_comm_order_req  IN comm_order_req.id_comm_order_req%TYPE,
        o_comm_order_plan OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_execution_action_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_subject        IN action.subject%TYPE,
        i_from_state     IN action.from_state%TYPE,
        i_comm_order_req IN comm_order_req.id_comm_order_req%TYPE,
        o_actions        OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_comm_order_for_execution
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_comm_order_req  IN comm_order_req.id_comm_order_req%TYPE,
        i_comm_order_plan IN comm_order_plan.id_comm_order_plan%TYPE,
        o_comm_order      OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_comm_order_execution
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN episode.id_episode%TYPE,
        i_comm_order_req         IN comm_order_req.id_comm_order_req%TYPE,
        i_comm_order_plan        IN comm_order_plan.id_comm_order_plan%TYPE,
        i_flg_status             IN comm_order_plan.flg_status%TYPE,
        i_dt_next                IN VARCHAR2,
        i_prof_performed         IN comm_order_plan.id_prof_performed%TYPE,
        i_start_time             IN VARCHAR2,
        i_end_time               IN VARCHAR2,
        i_flg_supplies           IN VARCHAR2,
        i_notes                  IN comm_order_plan.notes%TYPE,
        i_doc_template           IN doc_template.id_doc_template%TYPE,
        i_flg_type               IN doc_template_context.flg_type%TYPE,
        i_id_documentation       IN table_number,
        i_id_doc_element         IN table_number,
        i_id_doc_element_crit    IN table_number,
        i_value                  IN table_varchar,
        i_id_doc_element_qualif  IN table_table_number,
        i_vs_element_list        IN table_number,
        i_vs_save_mode_list      IN table_varchar,
        i_vs_list                IN table_number,
        i_vs_value_list          IN table_number,
        i_vs_uom_list            IN table_number,
        i_vs_scales_list         IN table_number,
        i_vs_date_list           IN table_varchar,
        i_vs_read_list           IN table_number,
        i_clinical_decision_rule IN cdr_call.id_cdr_call%TYPE,
        i_id_po_param_reg        IN po_param_reg.id_po_param_reg%TYPE,
        i_task_type              IN task_type.id_task_type%TYPE,
        o_comm_order_plan        OUT comm_order_plan.id_comm_order_plan%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_comm_order_execution
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN episode.id_episode%TYPE,
        i_comm_order_req         IN comm_order_req.id_comm_order_req%TYPE,
        i_comm_order_plan        IN comm_order_plan.id_comm_order_plan%TYPE,
        i_flg_status             IN comm_order_plan.flg_status%TYPE,
        i_dt_next                IN VARCHAR2,
        i_prof_performed         IN comm_order_plan.id_prof_performed%TYPE,
        i_start_time             IN VARCHAR2,
        i_end_time               IN VARCHAR2,
        i_flg_supplies           IN VARCHAR2,
        i_notes                  IN comm_order_plan.notes%TYPE,
        i_epis_documentation     IN epis_documentation.id_epis_documentation%TYPE,
        i_clinical_decision_rule IN cdr_call.id_cdr_call%TYPE,
        i_id_po_param_reg        IN po_param_reg.id_po_param_reg%TYPE,
        o_comm_order_plan        OUT comm_order_plan.id_comm_order_plan%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_comm_order_conclusion
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_comm_order_req  IN comm_order_req.id_comm_order_req%TYPE,
        i_comm_order_plan IN comm_order_plan.id_comm_order_plan%TYPE,
        o_comm_order_plan OUT comm_order_plan.id_comm_order_plan%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_comm_order_execution
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_comm_order_plan IN comm_order_plan.id_comm_order_plan%TYPE,
        i_dt_plan         IN VARCHAR2,
        i_cancel_reason   IN interv_presc_plan.id_cancel_reason%TYPE,
        i_cancel_notes    IN interv_presc_plan.notes_cancel%TYPE,
        i_task_type       IN task_type.id_task_type%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_comm_order_exec_values
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_comm_order_plan    IN comm_order_plan.id_comm_order_plan%TYPE,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_po_param_reg       IN po_param_reg.id_po_param_reg%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

END pk_comm_orders_ux;
/
