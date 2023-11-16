/*-- Last Change Revision: $Rev: 2005972 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2022-01-20 16:59:36 +0000 (qui, 20 jan 2022) $*/

CREATE OR REPLACE PACKAGE pk_comm_orders IS

    -- Author  : ANA.MONTEIRO
    -- Created : 13-02-2014 17:29:48
    -- Purpose :

    TYPE t_rec_comm_order_type IS RECORD(
        id_comm_order_type   concept_type.id_concept_type%TYPE,
        desc_comm_order_type pk_translation.t_desc_translation);

    TYPE t_coll_comm_order_type IS TABLE OF t_rec_comm_order_type;
    TYPE t_cur_comm_order_type IS REF CURSOR RETURN t_rec_comm_order_type;

    TYPE t_rec_comm_order IS RECORD(
        id_comm_order_type        concept_type.id_concept_type%TYPE,
        desc_comm_order_type      pk_translation.t_desc_translation,
        icon_comm_order_type      pk_translation.t_desc_translation,
        rank_comm_order_type      comm_order_type.rank%TYPE,
        id_comm_order             comm_order_ea.id_comm_order%TYPE,
        desc_comm_order           pk_translation.t_lob_char,
        desc_comm_order_with_path pk_translation.t_lob_char,
        flg_other                 VARCHAR2(1 CHAR),
        flg_select                VARCHAR2(1 CHAR),
        flg_child                 VARCHAR2(1 CHAR),
        flg_clinical_question     VARCHAR2(1 CHAR) DEFAULT NULL);

    TYPE t_coll_comm_order IS TABLE OF t_rec_comm_order;
    TYPE t_cur_comm_order IS REF CURSOR RETURN t_rec_comm_order;

    TYPE t_rec_comm_order_search IS RECORD(
        id_comm_order_type        concept_type.id_concept_type%TYPE,
        desc_comm_order_type      pk_translation.t_desc_translation,
        icon_comm_order_type      pk_translation.t_desc_translation,
        rank_comm_order_type      comm_order_type.rank%TYPE,
        id_comm_order             comm_order_ea.id_comm_order%TYPE,
        desc_comm_order           pk_translation.t_lob_char,
        desc_comm_order_with_path pk_translation.t_lob_char,
        flg_free_text             comm_order_req.flg_free_text%TYPE);

    TYPE t_coll_comm_order_search IS TABLE OF t_rec_comm_order_search;
    TYPE t_cur_comm_order_search IS REF CURSOR RETURN t_rec_comm_order_search;

    TYPE t_rec_comm_order_req_info IS RECORD(
        id_comm_order_req     comm_order_req.id_comm_order_req%TYPE,
        id_workflow           comm_order_req.id_workflow%TYPE,
        id_status             comm_order_req.id_status%TYPE,
        id_patient            comm_order_req.id_patient%TYPE,
        id_episode            comm_order_req.id_episode%TYPE,
        id_comm_order_type    comm_order_req.id_concept_type%TYPE,
        desc_comm_order_type  VARCHAR2(1000 CHAR),
        flg_free_text         comm_order_req.flg_free_text%TYPE,
        desc_comm_order       pk_translation.t_lob_char,
        notes                 comm_order_req.notes%TYPE,
        id_diagnosis          table_number, -- refers to clinical_indication
        id_alert_diagnosis    table_number, -- refers to clinical_indication
        desc_diagnosis        table_varchar, -- refers to clinical_indication
        flg_clinical_purpose  comm_order_req.flg_clinical_purpose%TYPE,
        desc_clinical_purpose VARCHAR2(1000 CHAR),
        flg_priority          comm_order_req.flg_priority%TYPE,
        desc_priority         VARCHAR2(1000 CHAR),
        flg_prn               comm_order_req.flg_prn%TYPE,
        desc_prn              VARCHAR2(1000 CHAR),
        prn_condition         comm_order_req.prn_condition%TYPE,
        dt_begin              comm_order_req.dt_begin%TYPE,
        start_date_str        VARCHAR2(50 CHAR),
        dt_order_str          VARCHAR2(50 CHAR),
        id_prof_order         co_sign.id_prof_ordered_by%TYPE,
        desc_prof_order       VARCHAR2(1000 CHAR),
        id_order_type         co_sign.id_order_type%TYPE,
        desc_order_type       VARCHAR2(1000 CHAR),
        dt_req_str            VARCHAR2(50 CHAR),
        id_task_type          task_type.id_task_type%TYPE,
        task_duration         comm_order_req.task_duration%TYPE,
        id_order_recurrence   comm_order_req.id_order_recurr%TYPE,
        order_recurrence      VARCHAR2(1000 CHAR),
        id_comm_order         comm_order_ea.id_comm_order%TYPE,
        dt_order              VARCHAR2(200));

    TYPE t_coll_comm_order_req_info IS TABLE OF t_rec_comm_order_req_info;
    TYPE t_cur_comm_order_req_info IS REF CURSOR RETURN t_rec_comm_order_req_info;

    -- workflow
    g_id_sts_ongoing      CONSTANT wf_status.id_status%TYPE := 500;
    g_id_sts_completed    CONSTANT wf_status.id_status%TYPE := 501;
    g_id_sts_canceled     CONSTANT wf_status.id_status%TYPE := 502;
    g_id_sts_draft        CONSTANT wf_status.id_status%TYPE := 503;
    g_id_sts_predf        CONSTANT wf_status.id_status%TYPE := 504;
    g_id_sts_expired      CONSTANT wf_status.id_status%TYPE := 505;
    g_id_sts_discontinued CONSTANT wf_status.id_status%TYPE := 1805;

    g_id_action_complete CONSTANT wf_workflow_action.id_workflow_action%TYPE := 600;
    g_id_action_cancel   CONSTANT wf_workflow_action.id_workflow_action%TYPE := 601;
    g_id_action_expire   CONSTANT wf_workflow_action.id_workflow_action%TYPE := 602;
    g_id_action_order    CONSTANT wf_workflow_action.id_workflow_action%TYPE := 603;

    -- fields style
    g_field_style_new    CONSTANT VARCHAR2(30 CHAR) := 'NEW';
    g_field_style_normal CONSTANT VARCHAR2(30 CHAR) := 'NORMAL';
    g_field_style_hist   CONSTANT VARCHAR2(30 CHAR) := 'HIST';
    g_field_style_new_h2 CONSTANT VARCHAR2(30 CHAR) := 'NEW_H2';

    -- co signs actions
    g_cs_action_add                CONSTANT task_type_actions.id_action%TYPE := 6980;
    g_cs_action_edit               CONSTANT task_type_actions.id_action%TYPE := 235528819;
    g_cs_action_cancel_discontinue CONSTANT task_type_actions.id_action%TYPE := 235529905;

    -- codes to translation_trs
    g_code_notes               CONSTANT comm_order_req.notes%TYPE := 'ALERT.COMM_ORDER_REQ.NOTES.';
    g_code_clinical_indication CONSTANT comm_order_req.notes%TYPE := 'ALERT.COMM_ORDER_REQ.CLINICAL_INDICATION.';
    g_code_prn_condition       CONSTANT comm_order_req.notes%TYPE := 'ALERT.COMM_ORDER_REQ.PRN_CONDITION.';
    g_code_notes_cancel        CONSTANT comm_order_req.notes%TYPE := 'ALERT.COMM_ORDER_REQ.NOTES_CANCEL.';
    g_code_desc_concept_term   CONSTANT comm_order_req.notes%TYPE := 'ALERT.COMM_ORDER_REQ.DESC_CONCEPT_TERM.';

    -- desc separators
    g_str_separator  CONSTANT VARCHAR2(5 CHAR) := '; ';
    g_str_sep_colon  CONSTANT VARCHAR2(5 CHAR) := ': ';
    g_str_sep_comma  CONSTANT VARCHAR2(5 CHAR) := ', ';
    g_str_sep_l_par  CONSTANT VARCHAR2(5 CHAR) := ' (';
    g_str_sep_r_par  CONSTANT VARCHAR2(5 CHAR) := ') ';
    g_str_sep_hyphen CONSTANT VARCHAR2(5 CHAR) := ' - ';

    g_comm_order_plan_sos          CONSTANT comm_order_plan.flg_status%TYPE := 'S';
    g_comm_order_plan_req          CONSTANT comm_order_plan.flg_status%TYPE := 'R';
    g_comm_order_plan_pending      CONSTANT comm_order_plan.flg_status%TYPE := 'D';
    g_comm_order_plan_ongoing      CONSTANT comm_order_plan.flg_status%TYPE := 'E';
    g_comm_order_plan_executed     CONSTANT comm_order_plan.flg_status%TYPE := 'A';
    g_comm_order_plan_monitorized  CONSTANT comm_order_plan.flg_status%TYPE := 'M';
    g_comm_order_plan_not_executed CONSTANT comm_order_plan.flg_status%TYPE := 'N';
    g_comm_order_plan_discontinued CONSTANT comm_order_plan.flg_status%TYPE := 'I';
    g_comm_order_plan_expired      CONSTANT comm_order_plan.flg_status%TYPE := 'O';
    g_comm_order_plan_cancel       CONSTANT comm_order_plan.flg_status%TYPE := 'C';

    g_execution_action_execution  CONSTANT VARCHAR2(1 CHAR) := 'E';
    g_execution_action_monitoring CONSTANT VARCHAR2(1 CHAR) := 'M';

    --doc areas
    g_doc_area_communications CONSTANT NUMBER(24) := 36086;
    g_doc_area_medical_orders CONSTANT NUMBER(24) := 36087;

    --identifier for Restraint Orders Type
    g_restraint_order_type CONSTANT comm_order_type.id_comm_order_type%TYPE := 51;

    --Configuration of the execution/monitorization workflow for the communication orders
    g_comm_order_exec_workflow CONSTANT VARCHAR2(40 CHAR) := 'COMMUNICATION_ORDERS_SCREEN_NEW';

    /**
    * Convert a clob to varchar2 and truncate it to the max size, adding ellipsis if necessarypk_comm_orders.g_comm_order_plan_executed
    *
    * @param i_clob               clob value
    * @param i_max_size           max size
    *
    * @return  varchar2           varchar2 value
    *
    * @author  tiago.silva
    * @version 1.0
    * @since   12-03-2014
    */
    FUNCTION trunc_clob_to_varchar2
    (
        i_clob     IN CLOB,
        i_max_size IN NUMBER
    ) RETURN VARCHAR2;

    /**
    * Converts columns (id_concept_type,id_concept_version,id_cncpt_vrs_inst_owner,id_concept_term,id_cncpt_trm_inst_owner) into hash key ID_COMM_ORDER
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_concept_version         Concept version identifier
    * @param   i_id_cncpt_vrs_inst_owner    Concept version inst owner
    * @param   i_id_concept_term            Concept term identifier
    * @param   i_id_cncpt_trm_inst_owner    Concept term inst owner
    * @param   o_error                      Error information
    *
    * @return  number                      Hash key used to identify a communication order
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   18-03-2014
    */
    FUNCTION get_comm_order_id
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_concept_version      IN comm_order_ea.id_concept_version%TYPE,
        i_id_cncpt_vrs_inst_owner IN comm_order_ea.id_cncpt_vrs_inst_owner%TYPE,
        i_id_concept_term         IN comm_order_ea.id_concept_term%TYPE,
        i_id_cncpt_trm_inst_owner IN comm_order_ea.id_cncpt_trm_inst_owner%TYPE
    ) RETURN comm_order_ea.id_comm_order%TYPE;

    FUNCTION get_comm_order_question_type
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_concept_term IN comm_order_questionnaire.id_concept_term%TYPE,
        i_flg_time        IN interv_questionnaire.flg_time%TYPE,
        i_questionnaire   IN questionnaire.id_questionnaire%TYPE,
        i_response        IN response.id_response%TYPE
    ) RETURN comm_order_questionnaire.flg_type%TYPE;

    FUNCTION get_comm_order_question_rank
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_concept_term IN comm_order_questionnaire.id_concept_term%TYPE,
        i_questionnaire   IN questionnaire.id_questionnaire%TYPE,
        i_flg_time        IN interv_questionnaire.flg_time%TYPE
    ) RETURN NUMBER;

    /**
    * Returns clinical purpose description for a communication order request
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_flg_clin_purpose   Flag that indicates the clinical purpose
    * @param   i_clin_purpose_desc  Clinical purpose description (in case of other)
    *
    * @return  VARCHAR2             Clinical purpose description
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   15-04-2014
    */
    FUNCTION get_clinical_purpose_desc
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_flg_clin_purpose  IN comm_order_req.flg_clinical_purpose%TYPE,
        i_clin_purpose_desc IN comm_order_req.clinical_purpose_desc%TYPE
    ) RETURN comm_order_req.clinical_purpose_desc%TYPE;
    /**
    * Gets clinical indication text to be shown in detail screens
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_clinical_indication        Clinical indication (xml format)
    * @param   o_text                       Clinical indication text to be show in detail screens
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   28-02-2014
    */
    FUNCTION get_diagnoses_text
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_clinical_indication IN comm_order_req.clinical_indication%TYPE,
        o_text                OUT CLOB,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

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
        o_list      OUT t_cur_comm_order_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get number of children for a given communication order
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_cpt_vrs_uid        Concept version unique identifier
    * @param   o_error              Error information
    *
    * @return  number               Number of children
    *
    * @author  tiago.silva
    * @version 1.0
    * @since   05-03-2014
    */
    FUNCTION get_num_comm_order_children
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_cpt_vrs_uid IN comm_order_ea.cpt_vrs_uid%TYPE
    ) RETURN NUMBER;

    /**
    * Get concept version unique identifier given a communication order id
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_id_comm_order      Communication order identifier
    * @param   o_error              Error information
    *
    * @return  boolean              True on sucess, otherwise false
    *
    * @author  tiago.silva
    * @version 1.0
    * @since   05-03-2014
    */
    FUNCTION get_cpt_vrs_uid
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_comm_order IN comm_order_ea.id_comm_order%TYPE
    ) RETURN comm_order_ea.cpt_vrs_uid%TYPE;

    /**
    * Gets clinical indication diagnosis identifiers
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_clinical_indication        Clinical indication (xml format)
    *
    * @return  table_number                 Array of diagnosis identifiers
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   13-03-2014
    */
    FUNCTION get_id_diagnoses
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_clinical_indication IN comm_order_req.clinical_indication%TYPE
    ) RETURN table_number;

    /**
    * Gets clinical indication alert diagnosis identifiers
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_clinical_indication        Clinical indication (xml format)
    *
    * @return  table_number                 Array of alert diagnosis identifiers
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   13-03-2014
    */
    FUNCTION get_id_alert_diagnoses
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_clinical_indication IN comm_order_req.clinical_indication%TYPE
    ) RETURN table_number;

    /**
    * Gets clinical indication alert diagnosis identifiers
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_clinical_indication        Clinical indication (xml format)
    *
    * @return  table_varchar                Array of diagnosis descriptions
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   13-03-2014
    */
    FUNCTION get_desc_diagnoses
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_clinical_indication IN comm_order_req.clinical_indication%TYPE
    ) RETURN table_varchar;

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
        i_id_comm_order_type IN concept_type.id_concept_type%TYPE,
        i_id_comm_order_par  IN comm_order_ea.id_comm_order%TYPE,
        i_task_type          IN NUMBER,
        o_list               OUT t_cur_comm_order,
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
        o_list              OUT t_cur_comm_order_search,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns a list of options with the clinical purpose for a communication order
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   o_list               List of clinical purpose values
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
    * @param   o_list               List of priority values
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
    * @param   o_list               List of prn values
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

    -----------------
    -- workflow functions
    -----------------
    /**
    * Initializes table_varchar as input of workflow transition function
    *
    * @param   i_lang                    Language associated to the professional
    * @param   i_prof                    Professional, institution and software ids
    * @param   i_id_comm_order_req      Communication orders identifier
    * @param   i_dt_begin                Start date
    *
    */
    FUNCTION init_param_tab
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_comm_order_req IN comm_order_req.id_comm_order_req%TYPE,
        i_dt_begin          IN comm_order_req.dt_begin%TYPE
    ) RETURN table_varchar;

    /**
    * Check if professional can complete this communication order
    *
    * @param   i_lang               Language associated to the professional
    * @param   i_prof               Professional, institution and software ids
    * @param   i_workflow           Workflow identifier
    * @param   i_status_begin       Initial transition status
    * @param   i_status_end         Final transition status
    * @param   i_workflow_action    Workflow action identifier
    * @param   i_category           Category identifier
    * @param   i_profile            Profile template identifier
    * @param   i_func               Functionality identifier
    * @param   i_param              Communication orders information
    *
    * @RETURN  VARCHAR2 'A' - transition allowed 'D' - transition denied
    * @author  Ana Monteiro
    * @version 1.0
    * @since   18-02-2014
    */
    FUNCTION can_complete
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_workflow        IN wf_transition_config.id_workflow%TYPE,
        i_status_begin    IN wf_transition_config.id_status_begin%TYPE,
        i_status_end      IN wf_transition_config.id_status_end%TYPE,
        i_workflow_action IN wf_transition_config.id_workflow_action%TYPE,
        i_category        IN wf_transition_config.id_category%TYPE,
        i_profile         IN wf_transition_config.id_profile_template%TYPE,
        i_func            IN wf_transition_config.id_functionality%TYPE,
        i_param           IN table_varchar
    ) RETURN VARCHAR2;

    /**
    * Check if professional can cancel this communication order
    *
    * @param   i_lang               Language associated to the professional
    * @param   i_prof               Professional, institution and software ids
    * @param   i_workflow           Workflow identifier
    * @param   i_status_begin       Initial transition status
    * @param   i_status_end         Final transition status
    * @param   i_workflow_action    Workflow action identifier
    * @param   i_category           Category identifier
    * @param   i_profile            Profile template identifier
    * @param   i_func               Functionality identifier
    * @param   i_param              Communication orders information
    *
    * @RETURN  VARCHAR2 'A' - transition allowed 'D' - transition denied
    *
    * @author  Ana Monteiro
    * @since   18-02-2014
    */
    FUNCTION can_cancel
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_workflow        IN wf_transition_config.id_workflow%TYPE,
        i_status_begin    IN wf_transition_config.id_status_begin%TYPE,
        i_status_end      IN wf_transition_config.id_status_end%TYPE,
        i_workflow_action IN wf_transition_config.id_workflow_action%TYPE,
        i_category        IN wf_transition_config.id_category%TYPE,
        i_profile         IN wf_transition_config.id_profile_template%TYPE,
        i_func            IN wf_transition_config.id_functionality%TYPE,
        i_param           IN table_varchar
    ) RETURN VARCHAR2;

    /**
    * Check if a transition is valid
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_workflow                Workflow identifier
    * @param   i_id_status_begin            Begin status identifier
    * @param   i_id_status_end              End status identifier
    * @param   i_id_workflow_action         Workflow action identifier
    * @param   i_id_category                Category identifier
    * @param   i_id_profile_template        Profile template identifier
    * @param   i_id_comm_order_req         communication orders request identifier
    * @param   i_dt_begin                   Communication order start date
    * @param   o_error                      Error information
    *
    * @return  varchar2                     'Y'- transition allowed 'N'- transition denied
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   25-02-2014
    */
    FUNCTION check_transition
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_workflow         IN comm_order_req.id_workflow%TYPE,
        i_id_status_begin     IN comm_order_req.id_status%TYPE,
        i_id_status_end       IN comm_order_req.id_status%TYPE,
        i_id_workflow_action  IN wf_workflow_action.id_workflow_action%TYPE,
        i_id_category         IN category.id_category%TYPE,
        i_id_profile_template IN profile_template.id_profile_template%TYPE,
        i_id_comm_order_req   IN comm_order_req.id_comm_order_req%TYPE,
        i_dt_begin            IN comm_order_req.dt_begin%TYPE
    ) RETURN VARCHAR2;

    /**
    * Checks an action is active or not
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_action                  Action identifier
    * @param   i_internal_name              Action internal name
    * @param   i_id_comm_order_req          Array of communication order request identifiers
    * @param   o_error                      Error information
    *
    * @return  varchar2                     'A'- action is active 'I'- action is inactive
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   25-02-2014
    */
    FUNCTION check_action_active
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_action         IN action.id_action%TYPE,
        i_internal_name     IN action.internal_name%TYPE,
        i_id_comm_order_req IN table_number
    ) RETURN VARCHAR2;

    FUNCTION check_parameters
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_task_type    IN task_type.id_task_type%TYPE,
        i_id_concept_term IN comm_order_req.id_concept_term%TYPE
    ) RETURN VARCHAR2;

    /**
    * Gets communication order requests identifiers related to data set in input parameters
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_visit                   Visit identifier. It set, return identifiers of the episodes related to this visit
    * @param   i_id_patient                 Patient identifier. It set, return identifiers of this patient
    * @param   i_id_episode                 Episode identifier. It set, return identifiers of this episode
    * @param   i_id_status                  Status identifier. It set, return identifiers of this status
    * @param   i_id_status_exclude          Status identifiers to be excluded.
    * @param   o_comm_order_req_tab        Array of communication order requests identifiers
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   24-02-2014
    */
    FUNCTION get_comm_order_req_ids
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_visit           IN episode.id_visit%TYPE DEFAULT NULL,
        i_id_patient         IN comm_order_req.id_patient%TYPE DEFAULT NULL,
        i_id_episode         IN comm_order_req.id_episode%TYPE DEFAULT NULL,
        i_id_status          IN comm_order_req.id_status%TYPE DEFAULT NULL,
        i_id_status_exclude  IN table_number DEFAULT table_number(),
        i_tbl_task_type      IN table_number DEFAULT table_number(),
        o_comm_order_req_tab OUT table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Check if there was any acknowledge after the occurence of id_comm_order_req_hist
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_comm_order_req          Comm_order_req identifier
    * @param   i_id_comm_order_req_hist     Comm_order_req history identifier
    *
    * @return  VARCHAR2                     Y- was acknowledged N- otherwise
    *
    * @author  ana.monteiro
    * @since   22-04-2015
    */
    FUNCTION check_if_acknowledged
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_comm_order_req      IN comm_order_req.id_comm_order_req%TYPE,
        i_id_comm_order_req_hist IN comm_order_req_hist.id_comm_order_req_hist%TYPE
    ) RETURN VARCHAR2;

    /**
    * Gets the most recent co-sign info
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_episode                 Episode identifier
    * @param   i_id_comm_order_req          Communication orders request identifier
    * @param   i_flg_not_ack                Flag that indicates if this function returns co-sign data that was not aknowledged
    * @param   i_tab_id_actions             Array of action identifiers
    *
    * @value   i_flg_not_ack                {*} Y- returns co-sign data that was not aknowledged
    *                                       {*} N- returns all co-sign data, ignoring if it was acknowledged or not
    *
    * @return  t_rec_co_sign                Co-sign data
    *
    * @author  ana.monteiro
    * @since   14-04-2014
    */
    FUNCTION get_last_cs_info
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN comm_order_req.id_episode%TYPE,
        i_id_comm_order_req IN comm_order_req.id_comm_order_req%TYPE,
        i_flg_not_ack       IN VARCHAR2,
        i_tab_id_actions    IN table_number
    ) RETURN t_rec_co_sign;

    /**
    * Gets communication order requests information
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_comm_order_req          Array of communication orders requests identifiers
    * @param   i_flg_escape_char            Flag that indicates if html characters must be escaped
    * @param   o_info                       Information about communication order requests
    * @param   o_error                      Error information
    *
    * @value   i_flg_escape_char            {*} Y- escape html characters {*} N- otherwise
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
        i_flg_escape_char         IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_info                    OUT t_cur_comm_order_req_info,
        o_comm_clinical_questions OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets communication order requests description, used for the task timeline easy access
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_comm_order_req         Array of communication orders requests identifiers
    *
    * @return  clob                         Communication order request description
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   06-03-2014
    */
    FUNCTION get_comm_order_req_desc
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_comm_order_req     IN comm_order_req.id_comm_order_req%TYPE,
        i_description_condition IN pn_dblock_ttp_mkt.description_condition%TYPE DEFAULT NULL,
        i_flg_desc_for_dblock   IN pk_types.t_flg_char DEFAULT NULL
    ) RETURN CLOB;

    /**
    * Gets communication order request detail info
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_rec_comm_order_req        Communication orders request data
    * @param   i_rank                       Rank of this block (to be sorted later)
    * @param   io_id_section                Section identifier of this block
    * @param   io_data                      Communication order current information
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   24-02-2014
    */
    FUNCTION get_comm_order_req
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_rank               IN NUMBER,
        io_id_section        IN OUT NUMBER,
        i_rec_comm_order_req IN t_rec_comm_order_req,
        i_show_status        IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        io_data              IN OUT t_coll_comm_order_req_det,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets status description of communication order request
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_status                  Status identifier
    * @param   i_dt_begin                   Start date
    *
    * @return  Status descriptions
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   05-03-2014
    */
    FUNCTION get_comm_order_req_sts_desc
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_status         IN comm_order_req.id_status%TYPE,
        i_dt_begin          IN comm_order_req.dt_begin%TYPE,
        i_id_comm_order_req IN comm_order_req.id_comm_order_req%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

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
    * @since   24-02-2014
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
    * Gets communication order requests to be shown in detail screen
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_episode                 Episode identifier
    * @param   i_flg_scope                  Scope
    * @param   i_flg_show_history           Flag to indicate if history is shown
    * @param   i_flg_show_cancel            Flag to indicate if cancelled communication order requests are shown
    * @param   o_title_info                 Communication order request status and title descriptions
    * @param   o_detail_info                Communication order request information
    * @param   o_error                      Error information
    *
    * @value   i_flg_scope                  {*} P- patient {*} E- episode {*} V- visit
    * @value   i_flg_show_history           {*} Y- show history {*} N- otherwise
    * @value   i_flg_show_cancel            {*} Y- show cancelled records {*} N- otherwise
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   13-03-2014
    */
    FUNCTION get_comm_order_req_detail_rep
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN comm_order_req.id_episode%TYPE,
        i_flg_scope        IN VARCHAR2,
        i_flg_show_history IN VARCHAR2,
        i_flg_show_cancel  IN VARCHAR2,
        i_task_type        IN task_type.id_task_type%TYPE DEFAULT pk_alert_constant.g_task_medical_orders,
        o_title_info       OUT pk_types.cursor_type,
        o_detail_info      OUT pk_types.cursor_type,
        o_error            OUT t_error_out
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
        i_task_duration           IN table_number,
        i_order_recurr            IN table_number,
        i_clinical_question       IN table_table_number, --30
        i_response                IN table_table_varchar,
        i_clinical_question_notes IN table_table_varchar,
        i_task_type               IN NUMBER,
        o_id_comm_order_req       OUT table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

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
    FUNCTION create_comm_order_req_draft
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
    * @author  ana.monteiro
    * @version 1.0
    * @since   20-02-2014
    */
    FUNCTION create_comm_order_req_predf
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
    * @param   i_clinical_purpose_desc      Array of clinical purpose descriptions
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
    * @author  ana.monteiro
    * @version 1.0
    * @since   20-02-2014
    */
    FUNCTION update_comm_order_req
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_episode                 IN episode.id_episode%TYPE DEFAULT NULL,
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
        i_dt_begin_str            IN table_varchar,
        i_dt_order_str            IN table_varchar,
        i_id_prof_order           IN table_number,
        i_id_order_type           IN table_number,
        i_task_duration           IN table_number,
        i_order_recurr            IN table_number, ----tratar        
        i_clinical_question       IN table_table_number,
        i_response                IN table_table_varchar,
        i_clinical_question_notes IN table_table_varchar,
        o_error                   OUT t_error_out
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
    * @author  ana.monteiro
    * @version 1.0
    * @since   28-02-2014
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
    * Creates a new communication order request based on an existing one (copy)
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_comm_order_req         Communication order request identifier
    * @param   i_id_status                  New status identifier. If null, copy value from the original
    * @param   i_id_patient                 New patient identifier. If null, copy value from the original
    * @param   i_id_episode                 New episode identifier. If null, copy value from the original
    * @param   i_dt_begin                   New begin date. If null, copy value from the original
    * @param   o_id_comm_order_req         New communication order req identifier created
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   21-02-2014
    */
    FUNCTION copy_comm_order_req
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_comm_order_req IN comm_order_req.id_comm_order_req%TYPE,
        i_id_status         IN comm_order_req.id_status%TYPE DEFAULT NULL,
        i_id_patient        IN comm_order_req.id_patient%TYPE DEFAULT NULL,
        i_id_episode        IN comm_order_req.id_episode%TYPE DEFAULT NULL,
        i_dt_begin          IN comm_order_req.dt_begin%TYPE DEFAULT NULL,
        i_task_type         IN comm_order_req.id_task_type%TYPE DEFAULT NULL,
        o_id_comm_order_req OUT comm_order_req.id_comm_order_req%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Deletes an existing communication order request
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_comm_order_req         Array of communication orders request identifiers
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   24-02-2014
    */
    FUNCTION delete_comm_order_req
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_comm_order_req IN table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Mark a communication order request as acknowledged
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_comm_order_req         Array of communication orders requests identifiers
    * @param   o_id_ack_tab                 Array of acknowledges identifiers related to communication orders requests
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   19-02-2014
    */
    FUNCTION set_comm_order_req_ack
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_comm_order_req IN table_number,
        o_id_ack_tab        OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Order a communication order request, updating state to ongoing
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_episode                 New episode identifier. If null mantains the value
    * @param   i_id_comm_order_req         Array of communication orders request identifiers
    * @param   i_dt_order                   Order date
    * @param   i_id_prof_order              Order professional identifier
    * @param   i_id_order_type              Request order type (telephone, verbal, ...)
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   20-02-2014
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
    * Expires a communication order request, updating state to expired
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_comm_order_req         Array of communication orders request identifiers
    * @param   i_flg_ignore_trs_error       Flag indicating if ignores the error occured in transition status
    * @param   o_error                      Error information
    *
    * @value   i_flg_ignore_trs_error       {*} Y- ignore transition error {*} N- propagates transition error
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   20-02-2014
    */
    FUNCTION set_action_expire
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_comm_order_req    IN table_number,
        i_flg_ignore_trs_error IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancels or discontinues a communication order request
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_comm_order_req         Array of communication orders request identifiers
    * @param   i_id_episode                 Episode identifier
    * @param   i_id_reason                  Reason identifier (stored in id_cancel_reason)
    * @param   i_notes                      Notes (stored in cancel_notes)
    * @param   i_dt_order                   Co-sign order date
    * @param   i_id_prof_order              Co-sign order professional identifier
    * @param   i_id_order_type              Co-sign request order type (telephone, verbal, ...)
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @since   27-03-2015
    */
    FUNCTION set_action_cancel_discontinue
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_comm_order_req IN table_number,
        i_id_episode        IN comm_order_req.id_episode%TYPE,
        i_id_reason         IN comm_order_req.id_cancel_reason%TYPE,
        i_notes             IN pk_translation.t_lob_char,
        i_dt_order          IN co_sign.dt_ordered_by%TYPE,
        i_id_prof_order     IN co_sign.id_prof_ordered_by%TYPE,
        i_id_order_type     IN co_sign.id_order_type%TYPE,
        i_auto_descontinued IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Set action of a communication order request
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_action                  Action identifier form table ACTION
    * @param   i_id_comm_order_req          Array of communication orders request identifiers
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   25-02-2014
    */
    FUNCTION set_action
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_action         IN action.id_action%TYPE,
        i_id_comm_order_req IN table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets actions available for the communication order request
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_comm_order_req          Array with communication order request identifiers
    * @param   o_list                       List of actions available
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   21-02-2014
    */
    FUNCTION get_actions
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_comm_order_req IN table_number,
        i_task_type         IN NUMBER,
        o_list              OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets communication orders status
    *
    * @param   i_lang                 Professional preferred language
    * @param   i_prof                 Professional identification and its context (institution and software)
    * @param   i_episode              episode id
    * @param   i_comm_order_req       array of communication order request ids
    * @param   o_task_status          cursor with all communication order tasks status
    * @param   o_error                error structure for exception handling
    *
    * @return  boolean                True on sucess, otherwise false
    *
    * @author  tiago.silva
    * @version 1.0
    * @since   25-02-2014
    */
    FUNCTION get_comm_order_status
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_comm_order_req IN table_number,
        o_task_status    OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets communication order status string
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_status                  Communication order status
    * @param   i_dt_begin                   Communication order start date
    * @param   i_flg_need_ack               Comm order req needs to be acknowledge?
    * @param   i_flg_ignore_ack             Flag indicating if graphic indication of acknowledge is ignored
    *
    * @value   i_flg_need_ack               {*} Y- yes {*} N- no
    * @value   i_flg_ignore_ack             {*} Y- ignore graphic indication of acknowledge {*} N- otherwise
    *
    * @return  varchar2                     communication order status string
    *
    * @author  tiago.silva
    * @since   25-02-2014
    */
    FUNCTION get_comm_order_status_string
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_comm_order_req     IN comm_order_req.id_comm_order_req%TYPE,
        i_id_status             IN comm_order_req.id_status%TYPE,
        i_dt_begin              IN comm_order_req.dt_begin%TYPE,
        i_flg_need_ack          IN comm_order_req.flg_need_ack%TYPE,
        i_flg_ignore_ack        IN comm_order_req.flg_need_ack%TYPE DEFAULT pk_alert_constant.g_no,
        i_flg_new_wf_comm_order IN sys_config.value%TYPE DEFAULT pk_alert_constant.g_yes
    ) RETURN VARCHAR2;

    /**
    * Gets communication type description
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_concept_type               Communication order concept type
    *
    * @return  varchar2                     communication type description
    *
    * @author  tiago.silva
    * @version 1.0
    * @since   24-02-2014
    */
    FUNCTION get_comm_order_type_desc
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_concept_type IN comm_order_req.id_concept_type%TYPE
    ) RETURN VARCHAR2;

    /**
    * Gets communication order path with bound descriptions
    *
    * @param   i_lang              Professional preferred language
    * @param   i_prof              Professional identification and its context (institution and software)
    * @param   i_concept_path      Communication order concept type
    *
    * @return  clob                communication order path
    *
    * @author  tiago.silva
    * @version 1.0
    * @since   16-04-2014
    */
    FUNCTION get_comm_order_path_bound_desc
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_concept_path IN comm_order_ea.concept_path%TYPE
    ) RETURN CLOB;

    /**
    * Gets communication order path
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_concept_type               Communication order concept type
    * @param   i_concept_term               Communication order concept term id
    * @param   i_cncpt_trm_inst_owner       Communication order concept term instution owner
    * @param   i_concept_version            Communication order concept version id
    * @param   i_cncpt_vrs_inst_owner       Communication order concept version instution owner
    *
    * @return  varchar2                     communication order path
    *
    * @author  tiago.silva
    * @version 1.0
    * @since   16-04-2014
    */
    FUNCTION get_comm_order_path
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_concept_type         IN comm_order_req.id_concept_type%TYPE,
        i_concept_term         IN comm_order_req.id_concept_term%TYPE,
        i_cncpt_trm_inst_owner IN comm_order_req.id_cncpt_trm_inst_owner%TYPE,
        i_concept_version      IN comm_order_req.id_concept_version%TYPE,
        i_cncpt_vrs_inst_owner IN comm_order_req.id_cncpt_vrs_inst_owner%TYPE,
        i_task_type            IN comm_order_req.id_task_type%TYPE
    ) RETURN VARCHAR2;

    /**
    * Gets communication order title
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_concept_type               Communication order concept type
    * @param   i_concept_term               Communication order concept term id
    * @param   i_cncpt_trm_inst_owner       Communication order concept term instution owner
    * @param   i_concept_version            Communication order concept version id
    * @param   i_cncpt_vrs_inst_owner       Communication order concept version instution owner
    * @param   i_flg_free_text              Flag that indicates if this communication order is free text or not
    * @param   i_desc_concept_term          Communication order request description (in case of free text)
    * @param   i_flg_bold_title             Flag that indicates if communication order title must be return in bold format or not
    * @param   i_flg_show_comm_order_type   Flag that indicates if communitiona order type must be shown or not
    * @param   i_flg_trunc_clobs            Flag that indicates if all clob fields must be truncated or not
    * @param   i_flg_escape_char            Flag that indicates if html characters must be escaped
    *
    * @value   i_flg_free_text              {*} Y- free text {*} N- otherwise
    * @value   i_flg_bold_title             {*} Y- bold {*} N- normal
    * @value   i_flg_show_comm_order_type   {*} Y- show {*} N- hide
    * @value   i_flg_trunc_clobs            {*} Y- trunc clobs {*} N- otherwise
    * @value   i_flg_escape_char            {*} Y- escape html characters {*} N- otherwise
    *
    * @return  varchar2                     communication order title
    *
    * @author  tiago.silva
    * @version 1.0
    * @since   24-02-2014
    */
    FUNCTION get_comm_order_title
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_concept_type             IN comm_order_req.id_concept_type%TYPE,
        i_concept_term             IN comm_order_req.id_concept_term%TYPE,
        i_cncpt_trm_inst_owner     IN comm_order_req.id_cncpt_trm_inst_owner%TYPE,
        i_concept_version          IN comm_order_req.id_concept_version%TYPE,
        i_cncpt_vrs_inst_owner     IN comm_order_req.id_cncpt_vrs_inst_owner%TYPE,
        i_flg_free_text            IN comm_order_req.flg_free_text%TYPE,
        i_desc_concept_term        IN pk_translation.t_lob_char,
        i_task_type                IN comm_order_req.id_task_type%TYPE,
        i_flg_bold_title           IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_show_comm_order_type IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_trunc_clobs          IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_escape_char          IN VARCHAR2 DEFAULT pk_alert_constant.g_yes
    ) RETURN VARCHAR2;

    /**
    * Gets communication order notes formatted accordingly
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_notes                      Communication order notes
    * @param   i_flg_trunc_clobs            Flag that indicates if all clob fields must be truncated or not
    * @param   i_flg_escape_char            Flag that indicates if html characters must be escaped
    *
    * @value   i_flg_trunc_clobs            {*} Y- trunc clobs {*} N- otherwise
    * @value   i_flg_escape_char            {*} Y- escape html characters {*} N- otherwise
    *
    * @return  clob                         communication order notes
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   03-06-2014
    */
    FUNCTION get_comm_order_notes
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_notes           IN pk_translation.t_lob_char,
        i_flg_trunc_clobs IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_flg_escape_char IN VARCHAR2 DEFAULT pk_alert_constant.g_yes
    ) RETURN CLOB;

    /**
    * Gets communication order instructions
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_flg_priority               Flag that indicates the priority
    * @param   i_flg_prn                    Flag that indicates whether the communication order is PRN or not
    * @param   i_prn_condition              Notes to indicate the PRN conditions
    * @param   i_dt_begin                   Start date
    * @param   i_flg_trunc_clobs            Flag that indicates if all clob fields must be truncated or not
    * @param   i_flg_escape_char            Flag that indicates if html characters must be escaped
    *
    * @value   i_flg_priority               {*} R- Routine {*} A- ASAP {*} S- STAT
    * @value   i_flg_prn                    {*} Y- is PRN {*} N- otherwise
    * @value   i_flg_trunc_clobs            {*} Y- trunc clobs {*} N- otherwise
    * @value   i_flg_escape_char            {*} Y- escape html characters {*} N- otherwise
    *
    * @return  clob                         communication order instructions
    *
    * @author  tiago.silva
    * @version 1.0
    * @since   24-02-2014
    */
    FUNCTION get_comm_order_instr
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_flg_priority    IN comm_order_req.flg_priority%TYPE,
        i_flg_prn         IN comm_order_req.flg_prn%TYPE,
        i_prn_condition   IN comm_order_req.prn_condition%TYPE,
        i_dt_begin        IN comm_order_req.dt_begin%TYPE,
        i_flg_trunc_clobs IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_escape_char IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_flg_report      IN VARCHAR2 DEFAULT 'N'
    ) RETURN CLOB;

    /**
    * Gets communication order description (title, notes and instructions)
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_concept_type               Communication order concept type
    * @param   i_concept_term               Communication order concept term
    * @param   i_cncpt_trm_inst_owner       Communication order concept version id
    * @param   i_concept_version            Communication order concept version id
    * @param   i_cncpt_vrs_inst_owner       Communication order concept version instution owner
    * @param   i_flg_free_text              Flag that indicates if this communication order is free text or not
    * @param   i_desc_concept_term          Communication order request description (in case of free text)
    * @param   i_flg_priority               Flag that indicates the priority
    * @param   i_flg_prn                    Flag that indicates whether the communication order is PRN or not
    * @param   i_prn_condition              Notes to indicate the PRN conditions
    * @param   i_dt_begin                   Start date
    * @param   i_flg_bold_title             Flag that indicates if communication order title must be return in bold format or not
    * @param   i_flg_show_comm_order_type   Flag that indicates if communitiona order type must be shown or not
    * @param   i_flg_trunc_clobs            Flag that indicates if all clob fields must be truncated or not
    *
    * @value   i_flg_free_text              {*} Y- free text {*} N- otherwise
    * @value   i_flg_priority               {*} R- Routine {*} A- ASAP {*} S- STAT
    * @value   i_flg_prn                    {*} Y- is PRN {*} N- otherwise
    * @value   i_flg_bold_title             {*} Y- bold {*} N- normal
    * @value   i_flg_show_comm_order_type   {*} Y- show {*} N- hide
    * @value   i_flg_trunc_clobs            {*} Y- trunc clobs {*} N- otherwise
    *
    * @return  clob                         communication order description
    *
    * @author  tiago.silva
    * @version 1.0
    * @since   24-02-2014
    */
    FUNCTION get_comm_order_desc
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_concept_type             IN comm_order_req.id_concept_type%TYPE,
        i_concept_term             IN comm_order_req.id_concept_term%TYPE,
        i_cncpt_trm_inst_owner     IN comm_order_req.id_cncpt_trm_inst_owner%TYPE,
        i_concept_version          IN comm_order_req.id_concept_version%TYPE,
        i_cncpt_vrs_inst_owner     IN comm_order_req.id_cncpt_vrs_inst_owner%TYPE,
        i_flg_free_text            IN comm_order_req.flg_free_text%TYPE,
        i_desc_concept_term        IN pk_translation.t_lob_char,
        i_notes                    IN pk_translation.t_lob_char,
        i_flg_priority             IN comm_order_req.flg_priority%TYPE,
        i_flg_prn                  IN comm_order_req.flg_prn%TYPE,
        i_prn_condition            IN pk_translation.t_lob_char,
        i_dt_begin                 IN comm_order_req.dt_begin%TYPE,
        i_task_type                IN comm_order_req.id_task_type%TYPE,
        i_flg_bold_title           IN VARCHAR2 DEFAULT 'N',
        i_flg_show_comm_order_type IN VARCHAR2 DEFAULT 'N',
        i_flg_trunc_clobs          IN VARCHAR2 DEFAULT 'N',
        i_flg_report               IN VARCHAR2 DEFAULT 'N'
    ) RETURN CLOB;

    /**
    * Check if all mandatory fields are filled
    *
    * @param   i_lang                    Professional preferred language
    * @param   i_prof                    Professional identification and its context (institution and software)
    * @param   i_id_comm_order_req       Communication order request identifier
    * @param   i_id_episode              Episode identifier
    *
    * @return  varchar2                  'Y'- all mandatory fields filled 'N'- otherwise
    *
    * @author  tiago.silva
    * @version 1.0
    * @since   18-06-2014
    */
    FUNCTION check_mandatory_fields
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_comm_order_req IN comm_order_req.id_comm_order_req%TYPE,
        i_id_episode        IN comm_order_req.id_episode%TYPE
    ) RETURN VARCHAR2;

    /**
    * Gets the color to indicate that a comm order req needs to be acknowledged, in grids
    *
    * @param   i_flg_need_ack               Comm order req needs to be acknowledge?
    *
    * @value   i_flg_need_ack               {*} Y- yes {*} N- no
    *
    * @return  varchar2                     Color indicating that a comm order req needs to be acknowledged
    *
    * @author  ana.monteiro
    * @since   25-11-2014
    */
    FUNCTION get_instr_bg_color
    (
        i_flg_need_ack   IN comm_order_req.flg_need_ack%TYPE,
        i_comm_order_req comm_order_req.id_comm_order_req%TYPE
    ) RETURN VARCHAR2;

    /**
    * Gets the color to indicate that a comm order req needs to be acknowledged, in grids
    *
    * @param   i_flg_need_ack               Comm order req needs to be acknowledge?
    *
    * @value   i_flg_need_ack               {*} Y- yes {*} N- no
    *
    * @return  varchar2                     Color indicating that a comm order req needs to be acknowledged
    *
    * @author  ana.monteiro
    * @since   25-11-2014
    */
    FUNCTION get_instr_fg_color(i_flg_need_ack IN comm_order_req.flg_need_ack%TYPE) RETURN VARCHAR2;

    /**
    * Gets the alpha color to indicate that a comm order req needs to be acknowledged, in grids
    *
    * @param   i_flg_need_ack               Comm order req needs to be acknowledge?
    *
    * @value   i_flg_need_ack               {*} Y- yes {*} N- no
    *
    * @return  varchar2                     Alpha color indicating that a comm order req needs to be acknowledged
    *
    * @author  ana.monteiro
    * @since   25-11-2014
    */
    FUNCTION get_instr_bg_alpha(i_flg_need_ack IN comm_order_req.flg_need_ack%TYPE) RETURN VARCHAR2;

    /**
    * Gets the icon to indicate that a comm order req was edited, in grids
    *
    * @param   i_id_comm_order_req          Communication order request identifier
    * @param   i_flg_need_ack               Comm order req needs to be acknowledge?
    * @param   i_flg_action                 Last action performed to a communication order request
    *
    * @value   i_flg_need_ack               {*} Y- yes {*} N- no
    *
    * @return  varchar2                     Icon indicating that a comm order req was edited
    *
    * @author  ana.monteiro
    * @since   25-11-2014
    */
    FUNCTION get_edit_icon
    (
        i_id_comm_order_req IN comm_order_req.id_comm_order_req%TYPE,
        i_flg_need_ack      IN comm_order_req.flg_need_ack%TYPE,
        i_flg_action        IN comm_order_req.flg_action%TYPE
    ) RETURN VARCHAR2;

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
    * Informs communication orders module that a visit changed its status
    *
    * @param   i_lang                Professional preferred language
    * @param   i_prof                Professional identification and its context (institution and software)
    * @param   i_event_type          Type of event (UPDATE, INSERT, etc)
    * @param   i_rowids              List of ROWIDs belonging to the changed records.
    * @param   i_list_columns        List of columns that were changed
    * @param   i_source_table_name   Name of the table that was changed.
    * @param   i_dg_table_name       Name of the Data Governance table.
    *
    * @author  tiago.silva
    * @version 1.0
    * @since   07-03-2014
    */
    PROCEDURE set_visit_status_trigger
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    /**
    * Informs communication orders module that an episode changed its status
    *
    * @param   i_lang                Professional preferred language
    * @param   i_prof                Professional identification and its context (institution and software)
    * @param   i_event_type          Type of event (UPDATE, INSERT, etc)
    * @param   i_rowids              List of ROWIDs belonging to the changed records.
    * @param   i_list_columns        List of columns that were changed
    * @param   i_source_table_name   Name of the table that was changed.
    * @param   i_dg_table_name       Name of the Data Governance table.
    *
    * @author  tiago.silva
    * @version 1.0
    * @since   07-03-2014
    */
    PROCEDURE set_episode_status_trigger
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    /**
    * This function deletes all data related to a communication order request episode
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_patients                Array of patient identifiers
    * @param   i_id_episodes                Array of episode identifiers
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   21-03-2014
    */
    FUNCTION reset_comm_order_req
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_patients IN table_number,
        i_id_episodes IN table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets the rank of a communication order request, to be shown in grids/single page
    * Sorts by communication order type, status and priority
    *
    * @param   i_lang                  Professional preferred language
    * @param   i_prof                  Professional identification and its context (institution and software)
    * @param   i_id_comm_order_type    Communication order type identifier
    * @param   i_id_workflow           Workflow identifier
    * @param   i_id_status             Status identifier
    * @param   i_id_category           Professional category identifier
    * @param   i_id_profile_template   Professional profile template identifier
    * @param   i_flg_priority          Communication order priority
    *
    * @return  number                  Rank of the communication order request
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   09-05-2014
    */
    FUNCTION get_comm_order_req_rank
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_comm_order_type  IN comm_order_type.id_comm_order_type%TYPE,
        i_id_workflow         IN comm_order_req.id_workflow%TYPE,
        i_id_status           IN comm_order_req.id_status%TYPE,
        i_id_category         IN wf_status_config.id_category%TYPE DEFAULT 0,
        i_id_profile_template IN wf_status_config.id_profile_template%TYPE DEFAULT 0,
        i_flg_priority        IN comm_order_req.flg_priority%TYPE,
        i_id_task_type        IN task_type.id_task_type%TYPE
    ) RETURN NUMBER;

    /**
    * Gets the rank of a communication order request, to be shown in grids/single page
    * Sorts by communication order type, status and priority
    *
    * @param   i_rank_comm_order_type  Communication order type rank
    * @param   i_rank_status           Status rank
    * @param   i_rank_priority         Priority rank
    *
    * @return  number                  Rank of the communication order request
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   09-05-2014
    */
    FUNCTION get_comm_order_req_rank
    (
        i_rank_comm_order_type IN NUMBER,
        i_rank_status          IN NUMBER,
        i_rank_priority        IN NUMBER
    ) RETURN NUMBER;

    /**
    * Returns communication orders list for the viewer
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_patient                    Patient identifier
    * @param   i_viewer_area                Viewer area
    * @param   i_episode                    Episode identifier
    * @param   o_list                       Cursor containing communication orders list
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @since   02-12-2014
    */
    FUNCTION get_comm_order_viewer_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_viewer_area IN VARCHAR2,
        i_episode     IN episode.id_episode%TYPE,
        o_list        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
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

    /**
    * Returns communication orders for a given episode
    * Used by grid summary screen
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_episode                    Episode identifier
    * @param   i_filter_tstz                Date to filter only the records with "end dates" > i_filter_tstz
    * @param   i_filter_status              Array with task status to consider along with i_filter_tstz
    * @param   o_comm_orders                Cursor containing the communication order requests of this episode
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @since   03-12-2014
    */
    FUNCTION get_comm_order_summ_grid
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_filter_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_filter_status IN table_number,
        o_comm_orders   OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets co-sign action description
    * Used by co-sign module
    *
    * @param   i_lang              Professional preferred language
    * @param   i_prof              Professional identification and its context (institution and software)
    * @param   i_flg_action        Co-sign actions performed over a communication order request
    *
    * @value   i_flg_action        {*} 'ORDER'- Order
    *                              {*} 'EDITION'- Edition
    *                              {*} 'DISCONTINUED'- Discontinuation
    *                              {*} 'CANCELED'- Cancellation
    *                              {*} 'DRAFT'- Draft
    *
    * @return  VARCHAR2            Co-sign action description
    *
    * @author  ana.monteiro
    * @since   30-03-2015
    */
    FUNCTION get_cs_action_desc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_flg_action IN comm_order_req_hist.flg_action%TYPE
    ) RETURN VARCHAR2;

    FUNCTION inactivate_comm_order_tasks
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_inst        IN institution.id_institution%TYPE,
        i_ids_exclude IN OUT table_number,
        o_has_error   OUT BOOLEAN,
        o_error       OUT t_error_out
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

    FUNCTION get_comm_order_response
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_questionnaire IN questionnaire_response.id_questionnaire%TYPE,
        i_comm_order    IN comm_order_ea.id_comm_order%TYPE,
        i_flg_time      IN VARCHAR2
    ) RETURN table_varchar;

    FUNCTION get_comm_order_response
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_notes IN comm_order_question_response.notes%TYPE
    ) RETURN comm_order_question_response.notes%TYPE;

    FUNCTION get_comm_order_episode_resp
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_questionnaire IN comm_order_question_response.id_questionnaire%TYPE
    ) RETURN VARCHAR2;

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
        i_epis_documentation     IN comm_order_plan.id_epis_documentation%TYPE DEFAULT NULL,
        i_doc_template           IN doc_template.id_doc_template%TYPE, --25
        i_flg_type               IN doc_template_context.flg_type%TYPE,
        i_id_documentation       IN table_number,
        i_id_doc_element         IN table_number,
        i_id_doc_element_crit    IN table_number,
        i_value                  IN table_varchar, --30
        i_id_doc_element_qualif  IN table_table_number,
        i_vs_element_list        IN table_number,
        i_vs_save_mode_list      IN table_varchar,
        i_vs_list                IN table_number,
        i_vs_value_list          IN table_number, --35
        i_vs_uom_list            IN table_number,
        i_vs_scales_list         IN table_number,
        i_vs_date_list           IN table_varchar,
        i_vs_read_list           IN table_number,
        i_clinical_decision_rule IN cdr_call.id_cdr_call%TYPE,
        i_id_po_param_reg        IN po_param_reg.id_po_param_reg%TYPE DEFAULT NULL,
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

    FUNCTION set_comm_order_execution_hist
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_comm_order_plan      IN comm_order_plan_hist.id_comm_order_plan%TYPE,
        o_comm_order_plan_hist OUT comm_order_plan_hist.id_comm_order_plan_hist%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_order_plan_report
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_task_request  IN table_number,
        i_cpoe_dt_begin IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_cpoe_dt_end   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_task_type     IN cpoe_task_type.id_task_type%TYPE DEFAULT NULL,
        o_plan_rep      OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_last_order_plan_executed
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE,
        i_id_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        i_cpoe_dt_end         IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2;

END pk_comm_orders;
/
