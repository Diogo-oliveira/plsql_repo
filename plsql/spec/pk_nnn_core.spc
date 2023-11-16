/*-- Last Change Revision: $Rev: 2005972 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2022-01-20 16:59:36 +0000 (qui, 20 jan 2022) $*/
CREATE OR REPLACE PACKAGE pk_nnn_core IS

    -- Author  : CRISTINA.OLIVEIRA
    -- Created : 25-10-2013 14:03:52
    -- Purpose : NANDA, NIC and NOC (NNN) framework: Core methods 

    -- Exceptions
    -- Missing configuration in MSI_NNN_TERM_VERSION to indicate the terminology version of NANDA/NIC/NOC/NNNLinkages used by institution/software
    e_missing_cfg_term_version EXCEPTION;

    -- An invalid ID ORDER RECURRENCE PLAN not available in NNN_EPIS_OUTCOME
    e_invalid_epis_out_rec_plan EXCEPTION;

    -- An invalid ID ORDER RECURRENCE PLAN not available in NNN_EPIS_INDICATOR
    e_invalid_epis_ind_rec_plan EXCEPTION;

    -- An invalid ID ORDER RECURRENCE PLAN not available in NNN_EPIS_ACTIVITY
    e_invalid_epis_act_rec_plan EXCEPTION;

    -- Public type declarations

    -- Public constant declarations

    -- Public variable declarations

    -- Public function and procedure declarations

    /**
    * Renders a HTML template with the given context labels into the template var itself.     
    * This is a very primitive template engine inspired by "Mustache - Logic-less templates", see http://mustache.github.io.
    * It works by expanding tags in a template using values provided in a hash.
    * No sections, partials, lambdas,etc. support yet, just tag variables substitution.
    *
    * @param    io_template            HTML template using Mustache style
    * @param    i_hash_values          hash with tag variables
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    7/14/2014
    */
    PROCEDURE render_template
    (
        io_template   IN OUT NOCOPY CLOB,
        i_hash_values IN pk_types.vc2_hash_table
    );

    /**
    * Returns the Terminology Version ID configured to being used for NANDA, NIC and NOC(NNN) Configuration.
        
    * @param    i_terminology_name  Terminology name (NANDA-I, NIC, NOC)    
    * @param    i_inst             Institution ID 
    * @param    i_soft             Software ID 
    *
    * @throws   e_missing_cfg_term_version
    *
    * @author  CRISTINA.OLIVEIRA
    * @version  2.6.4.3
    * @since   25/10/2013
    */
    FUNCTION get_inst_nnn_term_version
    (
        i_terminology_name IN terminology.internal_name%TYPE,
        i_inst             IN institution.id_institution%TYPE,
        i_soft             IN software.id_software%TYPE
    ) RETURN terminology_version.id_terminology_version%TYPE result_cache;

    /**
    * Gets language ID of a terminology version.
    *
    * @param   i_terminology_version    Terminology Version ID
    *
    * @return  Language ID
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   10/29/2013
    */
    FUNCTION get_terminology_language(i_terminology_version IN terminology_version.id_terminology_version%TYPE)
        RETURN terminology_version.id_language%TYPE result_cache;

    /**
    * Gets language ID of the version of terminology configured.
    *
    * @param    i_terminology_name  Terminology name (NANDA-I, NIC, NOC)    
    * @param    i_inst             Institution ID 
    * @param    i_soft             Software ID 
    *
    * @return  Language ID
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   10/30/2013
    */
    FUNCTION get_terminology_language
    (
        i_terminology_name IN terminology.internal_name%TYPE,
        i_inst             IN institution.id_institution%TYPE,
        i_soft             IN software.id_software%TYPE
    ) RETURN terminology_version.id_language%TYPE result_cache;

    /**
    * Checks if a NANDA Diagnosis already exists in the patient nursing care plan.
    *
    * @param    i_patient                      Patient ID
    * @param    i_episode                      Episode ID
    * @param    i_nan_diagnosis                NANDA diagnosis ID
    *
    * @return  True if the NANDA Diagnosis is already defined in the patient nursing care plan
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   11/04/2013
    */
    FUNCTION check_epis_nan_diagnosis
    (
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_nan_diagnosis IN nnn_epis_diagnosis.id_nan_diagnosis%TYPE
    ) RETURN BOOLEAN;

    /**
    * Gets the patient's nursing care plan.
    *
    * @param    i_lang              Professional preferred language
    * @param    i_prof              Professional identification and its context (institution and software)
    * @param    i_patient           Patient ID
    * @param    i_scope             Scope ID (Episode ID; Visit ID; Patient ID)
    * @param    i_scope_type        Scope type (by episode; by visit; by patient)
    * @param    o_diagnosis         Cursor with list of Nursing Diagnoses
    * @param    o_outcome           Cursor with list of Nursing Outcomes
    * @param    o_indicator         Cursor with list of Nursing Indicators 
    * @param    o_intervention      Cursor with list of Nursing Interventions
    * @param    o_activity          Cursor with list of Nursing Activities
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   11/01/2013
    */
    PROCEDURE get_pat_nursing_careplan
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_scope        IN NUMBER,
        i_scope_type   IN VARCHAR2 DEFAULT pk_alert_constant.g_scope_type_episode,
        o_diagnosis    OUT pk_types.cursor_type,
        o_outcome      OUT pk_types.cursor_type,
        o_indicator    OUT pk_types.cursor_type,
        o_intervention OUT pk_types.cursor_type,
        o_activity     OUT pk_types.cursor_type
    );

    /**
    * Gets an evaluations view of the patient's nursing care plan. 
    * The output is intended to be visualized in a timeline view (rows and columns).
    *
    * Notice #columns <> #records. May exists several evaluations performed on the same date, and therefore, belong to the same column.
    *
    * @param    i_lang              Professional preferred language
    * @param    i_prof              Professional identification and its context (institution and software)
    * @param    i_patient           Patient ID
    * @param    i_scope             Scope ID (Episode ID; Visit ID; Patient ID)
    * @param    i_scope_type        Scope type (by episode; by visit; by patient)
    * @param    i_paging            Use paging. Default: No
    * @param    i_start_column      First column. Just considered when paging is used. Default 1
    * @param    i_num_columns       Number of columns (distinct evaluation's time) to be retrieved. Just considered when paging is used. Default 2000.
    * @param    o_rows              Cursor with list of items in the care plan
    * @param    o_cols              Cursor with list of evaluations for each item 
    *
    * @value    i_paging {*} pk_alert_constant.g_yes {*} pk_alert_constant.g_no
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   02/05/2014
    */
    PROCEDURE get_pat_evaluations_view
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_scope        IN NUMBER,
        i_scope_type   IN VARCHAR2 DEFAULT pk_alert_constant.g_scope_type_episode,
        i_paging       IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_start_column IN NUMBER DEFAULT 1,
        i_num_columns  IN NUMBER DEFAULT 2000,
        o_rows         OUT pk_types.cursor_type,
        o_cols         OUT pk_types.cursor_type
    );

    /**
    * Gets a plan view of the patient's nursing care plan. 
    * The output is intended to be visualized in a timeline view (rows and columns).
    *
    * Notice #columns <> #records. May exists several evaluations performed on the same date, and therefore, belong to the same column.
    *
    * @param    i_lang              Professional preferred language
    * @param    i_prof              Professional identification and its context (institution and software)
    * @param    i_patient           Patient ID
    * @param    i_scope             Scope ID (Episode ID; Visit ID; Patient ID)
    * @param    i_scope_type        Scope type (by episode; by visit; by patient)
    * @param    i_paging            Use paging. Default: No
    * @param    i_start_column      First column. Just considered when paging is used. Default 1
    * @param    i_num_columns       Number of columns (distinct evaluation's time) to be retrieved. Just considered when paging is used. Default 2000.
    * @param    o_rows              Cursor with list of items in the care plan
    * @param    o_cols              Cursor with list of evaluations for each item 
    *
    * @value    i_paging {*} pk_alert_constant.g_yes {*} pk_alert_constant.g_no
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   02/05/2014
    */
    PROCEDURE get_pat_plan_view
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_scope        IN NUMBER,
        i_scope_type   IN VARCHAR2 DEFAULT pk_alert_constant.g_scope_type_episode,
        i_paging       IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_start_column IN NUMBER DEFAULT 1,
        i_num_columns  IN NUMBER DEFAULT 2000,
        o_rows         OUT pk_types.cursor_type,
        o_cols         OUT pk_types.cursor_type
    );

    /**
    * Gets the patient's nursing diagnoses that are with unresolved status (active, inactive).
    *
    * @param    i_lang              Professional preferred language
    * @param    i_prof              Professional identification and its context (institution and software)
    * @param    i_patient           Patient ID
    * @param    i_scope             Scope ID (Episode ID; Visit ID; Patient ID)
    * @param    i_scope_type        Scope type (by episode; by visit; by patient)
    * @param    o_diagnosis         Cursor with list of Nursing Diagnoses
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   4/14/2014
    */
    PROCEDURE get_pat_unresolved_diagnosis
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_scope      IN NUMBER,
        i_scope_type IN VARCHAR2 DEFAULT pk_alert_constant.g_scope_type_episode,
        o_diagnosis  OUT pk_types.cursor_type
    );

    /**
    * Gets the patient's nursing outcomes linked to diagnoses that are with unresolved status (active, inactive).
    *
    * @param    i_lang              Professional preferred language
    * @param    i_prof              Professional identification and its context (institution and software)
    * @param    i_patient           Patient ID
    * @param    i_scope             Scope ID (Episode ID; Visit ID; Patient ID)
    * @param    i_scope_type        Scope type (by episode; by visit; by patient)
    * @param    o_outcome           Cursor with list of Nursing Outcomes
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   6/13/2014
    */
    PROCEDURE get_pat_unresolved_outcome
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_scope      IN NUMBER,
        i_scope_type IN VARCHAR2 DEFAULT pk_alert_constant.g_scope_type_episode,
        o_outcome    OUT pk_types.cursor_type
    );

    /**
    * Gets the latest evaluation of a NANDA nursing diagnosis in a patient's nursing care plan.
    *
    * @param    i_nnn_epis_diagnosis   Careplan's NANDA Diagnosis ID
    *
    * @return   A nnn_epis_diag_eval_ntt collection (nnn_epis_diag_eval%ROWTYPE) with one row corresponding to the latest evaluation    
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    11/5/2013
    */
    FUNCTION tf_latest_nnn_epis_diag_eval(i_nnn_epis_diagnosis IN nnn_epis_diagnosis.id_nnn_epis_diagnosis%TYPE)
        RETURN ts_nnn_epis_diag_eval.nnn_epis_diag_eval_ntt
        PIPELINED;

    /**
    * Gets the latest evaluation of a NOC Outcome in a patient's nursing care plan.
    *
    * @param    i_nnn_epis_outcome    Careplan's NOC Outcome ID
    *
    * @return   A nnn_epis_outcome_eval_ntt collection (nnn_epis_outcome_eval%ROWTYPE) with one row corresponding to the latest evaluation
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    11/07/2013
    */
    FUNCTION tf_latest_nnn_epis_outc_eval(i_nnn_epis_outcome IN nnn_epis_outcome_eval.id_nnn_epis_outcome%TYPE)
        RETURN ts_nnn_epis_outcome_eval.nnn_epis_outcome_eval_ntt
        PIPELINED;

    /**
    * Gets the latest evaluation of a NOC Indicator in a patient's nursing care plan.
    *
    * @param    i_nnn_epis_indicator    Careplan's NOC Indicator ID
    *
    * @return   A nnn_epis_ind_eval_ntt collection (nnn_epis_ind_eval%ROWTYPE) with one row corresponding to the latest evaluation
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    11/07/2013
    */
    FUNCTION tf_latest_nnn_epis_ind_eval(i_nnn_epis_indicator IN nnn_epis_ind_eval.id_nnn_epis_indicator%TYPE)
        RETURN ts_nnn_epis_ind_eval.nnn_epis_ind_eval_ntt
        PIPELINED;

    /**
    * Gets the latest execution of a NIC Activity in a patient's nursing care plan.
    *
    * @param    i_nnn_epis_activity    Careplan's NIC Activity ID
    *
    * @return   A nnn_epis_activity_det_ntt collection (nnn_epis_activity_det%ROWTYPE) with one row corresponding to the latest execution
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    10/30/2014
    */
    FUNCTION tf_latest_nnn_epis_activ_det(i_nnn_epis_activity IN nnn_epis_activity_det.id_nnn_epis_activity%TYPE)
        RETURN ts_nnn_epis_activity_det.nnn_epis_activity_det_ntt
        PIPELINED;

    /**
    * Gets a string representing NOC outcome evaluations in the format " #executed_evaluations / #total_evaluations".
    *
    * @param    i_lang                         Professional preferred language
    * @param    i_prof                         Professional identification and its context (institution and software)    
    * @param    i_nnn_epis_outcome             Careplan's NOC Outcome ID
    *
    * @return   "#executed_evaluations / #total_evaluations"
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    11/6/2013
    */
    FUNCTION get_outcome_eval_progress
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_nnn_epis_outcome  IN nnn_epis_outcome.id_nnn_epis_outcome%TYPE,
        i_order_recurr_plan IN nnn_epis_outcome.id_order_recurr_plan%TYPE
    ) RETURN VARCHAR2;

    /**
    * Gets a string representing NOC indicator evaluations in the format " #executed_evaluations / #total_evaluations".
    *
    * @param    i_nnn_epis_indicator  Careplan's NOC Indicator ID
    *
    * @return   "#executed_evaluations / #total_evaluations"
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    11/6/2013
    */
    FUNCTION get_indicator_eval_progress
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_nnn_epis_indicator IN nnn_epis_indicator.id_nnn_epis_indicator%TYPE,
        i_order_recurr_plan  IN nnn_epis_indicator.id_order_recurr_plan%TYPE
    ) RETURN VARCHAR2;

    /**
    * Gets a string representing NIC activity executions in the format " #executed / #total_executions".
    *
    * @param    i_nnn_epis_activity  Careplan's NIC Activity ID
    *
    * @return   "#executed / #total_executions"
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    11/6/2013
    */
    FUNCTION get_activity_det_progress
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_nnn_epis_activity IN nnn_epis_activity.id_nnn_epis_activity%TYPE,
        i_order_recurr_plan IN nnn_epis_activity.id_order_recurr_plan%TYPE
    ) RETURN VARCHAR2;

    /**
    * Gets info about a NANDA Nursing Diagnosis in a patient's nursing care plan.
    *    
    * @param    i_lang                 Language ID    
    * @param    i_prof                 Profissional
    * @param    i_nnn_epis_diagnosis   The nnn_epis_diagnosis identifier whose details we want to retrieve
    *
    * @param    o_diagnosis            The details of the selected diagnosis needed to populate
    *                                  the UX form.
    *    
    * @author  CRISTINA.OLIVEIRA
    * @version  2.6.4.3
    * @since   06/11/2013
    */
    PROCEDURE get_epis_nan_diagnosis
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_nnn_epis_diagnosis IN nnn_epis_diagnosis.id_nnn_epis_diagnosis%TYPE,
        o_diagnosis          OUT pk_types.cursor_type
    );

    /**
    *  Gets the data of a NANDA Diagnosis in a patient's nursing care plan (nnn_epis_diagnosis row).
    *    
    * @param    i_nnn_epis_diagnosis    Careplan's NANDA Diagnosis ID
    *
    * @return   The diagnosis data (nnn_epis_diagnosis row)
    *    
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    6/11/2014
    */
    FUNCTION get_epis_nan_diagnosis_row(i_nnn_epis_diagnosis IN nnn_epis_diagnosis.id_nnn_epis_diagnosis%TYPE)
        RETURN nnn_epis_diagnosis%ROWTYPE;

    /**
    *  Gets info about an evaluation of a NANDA Diagnosis in a patient's nursing care plan.
    *    
    * @param    i_lang                 Language ID    
    * @param    i_prof                 Profissional
    * @param    i_nnn_epis_diag_eval   Careplan's NANDA Diagnosis Evaluation ID whose evaluation we want to retrieve
    * @param    o_eval                 Information about the nursing diagnosis evaluation
    *    
    * @author  CRISTINA.OLIVEIRA
    * @version  2.6.4.3
    * @since   06/11/2013
    */
    PROCEDURE get_epis_nan_diagnosis_eval
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_nnn_epis_diag_eval IN nnn_epis_diag_eval.id_nnn_epis_diag_eval%TYPE,
        o_eval               OUT pk_types.cursor_type
    );

    /**
    *  Gets a string that describes the instructions of an NNN Outcome/Indicator/Activity request.
    *    
    * @param    i_lang                         Professional preferred language
    * @param    i_prof                         Professional identification and its context (institution and software)
    * @param    i_flg_priority                 Flag that indicates the priority of a task: (N)ormal, (U)rgent, (E)mergent
    * @param    i_flg_prn                      Flag that indicates wether the task is PRN or not
    * @param    i_notes_prn                    Notes to indicate when a PRN order should be activated
    * @param    i_flg_time                     Execution time to evaluate the task: In current (E)pisode, (B)etween episodes, (N)ext episode. 
    * @param    i_start_date                   If not null, this date will be used instead of the defined by in order recurrence plan
    * @param    i_order_recurr_plan            Order recurrence plan ID for defined frequency in the instructions             
    * @param    i_mask                         Mask used to define which information appear and in which order. Concatenate the flags for include the various fields in the final string.
    *
    * @value    i_mask        {*}g_inst_format_mask_default        All fields are included
    *                         {*}g_inst_format_opt_priority        Priority
    *                         {*}g_inst_format_opt_time_perform    Execution time
    *                         {*}g_inst_format_opt_prn             PRN and PRN Condition
    *                         {*}g_inst_format_opt_frequency       Frequency
    *                         {*}g_inst_format_opt_start_date      Start Date
    * 
    * @return   The instructions in a formatted string
    *    
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    4/23/2014
    */
    FUNCTION get_instructions
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_flg_priority      IN nnn_epis_activity.flg_priority%TYPE,
        i_flg_prn           IN nnn_epis_activity.flg_prn%TYPE,
        i_notes_prn         IN CLOB DEFAULT NULL,
        i_flg_time          IN nnn_epis_activity.flg_time%TYPE,
        i_start_date        IN nnn_epis_activity.dt_val_time_start%TYPE DEFAULT NULL,
        i_order_recurr_plan IN nnn_epis_activity.id_order_recurr_plan%TYPE,
        i_mask              IN pk_translation.t_low_char DEFAULT pk_nnn_constant.g_inst_format_mask_default
    ) RETURN pk_translation.t_hug_byte;

    /**
    * Gets the text with the frequency of the executions.
    * call API pk_order_recurrence_api_db.get_order_recurr_plan_desc     
    *    
    * @param    i_lang                 Language ID    
    * @param    i_prof                 Profissional
    * @param    i_id_order_recurr_plan The order_recurr_plan identifier whose recurrence plan we want to retrieve
    * @param    i_order_recurr_option  Option ONCE-0 
    *
    *    
    * @author  CRISTINA.OLIVEIRA
    * @version  2.6.4.3
    * @since   06/11/2013
    */
    FUNCTION get_frequency_desc
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_order_recurr_plan IN order_recurr_plan.id_order_recurr_plan%TYPE,
        i_order_recurr_option  IN order_recurr_plan.id_order_recurr_option%TYPE
    ) RETURN VARCHAR2;

    /**
    * Gets the start date defined in a recurrence plan.
    * 
    *    
    * @param    i_lang                Professional preferred language
    * @param    i_prof                Professional identification and its context (institution and software)
    * @param    i_order_recurr_plan   Order recurrence plan ID used to retrieve the start date in the instructions
    * @param    i_start_date          If not null, this date will be used instead of the defined by in order recurrence plan
    *
    * @return   Start date in a formatted string
    *    
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    5/14/2014
    */
    FUNCTION get_start_date_desc
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_order_recurr_plan IN order_recurr_plan.id_order_recurr_plan%TYPE,
        i_start_date        IN order_recurr_plan.start_date%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    /**
    * Gets the start date defined in a recurrence plan.
    * 
    *    
    * @param    i_lang                Professional preferred language
    * @param    i_prof                Professional identification and its context (institution and software)
    * @param    i_order_recurr_plan   Order recurrence plan ID used to retrieve the start date in the instructions
    *
    * @return   Start date 
    *    
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    5/14/2014
    */
    FUNCTION get_start_date
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_order_recurr_plan IN order_recurr_plan.id_order_recurr_plan%TYPE
    ) RETURN order_recurr_plan.start_date%TYPE;

    /**
    * Load needed info about outcome and it's instructions
    * This method gets all the data needed to update de recurrence and it's instructions     
    *    
    * @param    i_lang                Language ID    
    * @param    i_prof                Profissional
    * @param    i_nnn_epis_outcome    The Careplan's NOC Outcome ID whose details we want to retrieve
    *
    * @param    o_outcome             All the details of the selected outcome needed to populate
    *                                 the UX form.
    *    
    * @author  CRISTINA.OLIVEIRA
    * @version  2.6.4.3
    * @since   06/11/2013
    */
    PROCEDURE get_epis_noc_outcome
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_nnn_epis_outcome IN nnn_epis_outcome.id_nnn_epis_outcome%TYPE,
        o_outcome          OUT pk_types.cursor_type
    );

    /**
    *  Gets the data of a NOC Outcome in a patient's nursing care plan (nnn_epis_outcome row).
    *    
    * @param    i_nnn_epis_outcome    Careplan's NOC Outcome ID
    *
    * @return   The outcome data (nnn_epis_outcome row)
    *    
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    4/23/2014
    */
    FUNCTION get_epis_noc_outcome_row(i_nnn_epis_outcome IN nnn_epis_outcome.id_nnn_epis_outcome%TYPE)
        RETURN nnn_epis_outcome%ROWTYPE;

    /**
    *  Gets the evaluation data of a NOC Outcome in a patient's nursing care plan (nnn_epis_outcome_eval row).
    *    
    * @param    i_nnn_epis_outcome_eval    The Careplan's NOC Outcome ID whose evaluation we want to retrieve
    *
    * @return   The outcome evaluation (nnn_epis_outcome_eval row)
    *    
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    4/23/2014
    */
    FUNCTION get_epis_noc_outcome_eval_row(i_nnn_epis_outcome_eval IN nnn_epis_outcome_eval.id_nnn_epis_outcome_eval%TYPE)
        RETURN nnn_epis_outcome_eval%ROWTYPE;

    /**
    * Retrieves the ID of next planned NOC Outcome evaluation
    *
    * @param    i_nnn_epis_outcome              Careplan's NOC Outcome ID
    *
    * @return   The next Careplan's NOC Outcome Evaluation ID or NULL if no next evaluation was planned
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    1/8/2014
    */
    FUNCTION get_next_outcome_eval(i_nnn_epis_outcome nnn_epis_outcome.id_nnn_epis_outcome%TYPE)
        RETURN nnn_epis_outcome_eval.id_nnn_epis_outcome_eval%TYPE;

    /**
    * Retrieves the ID of next planned NOC Indicator evaluation
    *
    * @param    i_nnn_epis_outcome              Careplan's NOC Indicator ID
    *
    * @return   The next Careplan's NOC Indicator Evaluation ID or NULL if no next evaluation was planned
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    1/8/2014
    */
    FUNCTION get_next_indicator_eval(i_nnn_epis_indicator nnn_epis_indicator.id_nnn_epis_indicator%TYPE)
        RETURN nnn_epis_ind_eval.id_nnn_epis_ind_eval%TYPE;

    /**
    * Retrieves the ID of next planned NIC Activity execution
    *
    * @param    i_nnn_epis_outcome              Careplan's NIC Activity ID
    *
    * @return   The next Careplan's NOC Activity Execution ID or NULL if no next execution was planned
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    1/8/2014
    */
    FUNCTION get_next_activity_det(i_nnn_epis_activity nnn_epis_activity.id_nnn_epis_activity%TYPE)
        RETURN nnn_epis_activity_det.id_nnn_epis_activity_det%TYPE;
    /**
    *  Gets info about a NOC Indicator in a patient's nursing care plan.    
    *    
    * @param    i_lang                 Language ID    
    * @param    i_prof                 Profissional
    * @param    i_nnn_epis_indicator   The nnn_epis_indicator identifier whose details we want to retrieve
    *
    * @param    o_indicator            The details of the selected indicator needed to populate
    *                                  the UX form.
    *    
    * @author  CRISTINA.OLIVEIRA
    * @version  2.6.4.3
    * @since   06/11/2013
    */
    PROCEDURE get_epis_noc_indicator
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_nnn_epis_indicator IN nnn_epis_indicator.id_nnn_epis_indicator%TYPE,
        o_indicator          OUT pk_types.cursor_type
    );

    /**
    *  Gets the data of a NOC Indicator in a patient's nursing care plan (nnn_epis_indicator row).
    *    
    * @param    i_nnn_epis_indicator    Careplan's NOC Indicator ID
    *
    * @return   The indicator data (nnn_epis_indicator row)
    *    
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    4/28/2014
    */
    FUNCTION get_epis_noc_indicator_row(i_nnn_epis_indicator IN nnn_epis_indicator.id_nnn_epis_indicator%TYPE)
        RETURN nnn_epis_indicator%ROWTYPE;

    /**
    * Gets info about an evaluation of a NOC Indicator in a patient's nursing care plan.
    *    
    * @param    i_lang                 Language ID    
    * @param    i_prof                 Profissional
    * @param    i_nnn_epis_outcome     The Careplan's NOC Outcome ID is required to return the descriptions of scale levels
    * @param    i_nnn_epis_ind_eval    The nnn_epis_ind_eval identifier whose evaluation we want to retrieve
    *
    * @param    o_eval                 The evaluation of information of the selected indicator needed to populate
    *                                  the UX form.
    *    
    * @author  CRISTINA.OLIVEIRA
    * @version  2.6.4.3
    * @since   06/11/2013
    */
    PROCEDURE get_epis_noc_indicator_eval
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_nnn_epis_outcome  IN nnn_epis_outcome.id_nnn_epis_outcome%TYPE,
        i_nnn_epis_ind_eval IN nnn_epis_ind_eval.id_nnn_epis_ind_eval%TYPE,
        o_eval              OUT pk_types.cursor_type
    );

    /**
    *  Gets the evaluation data of a NOC Indicator in a patient's nursing care plan (nnn_epis_ind_eval row).
    *    
    * @param    i_nnn_epis_ind_eval    The Careplan's NOC Indicator ID whose evaluation we want to retrieve
    *
    * @return   The indicator evaluation (nnn_epis_ind_eval row)
    *    
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    4/28/2014
    */
    FUNCTION get_epis_noc_ind_eval_row(i_nnn_epis_ind_eval IN nnn_epis_ind_eval.id_nnn_epis_ind_eval%TYPE)
        RETURN nnn_epis_ind_eval%ROWTYPE;
    /**
    * Gets info about a NIC Activity in a patient's nursing care plan.
    *    
    * @param    i_lang                 Language ID    
    * @param    i_prof                 Profissional
    * @param    i_nnn_epis_activity    The nnn_epis_activity identifier whose details we want to retrieve
    *
    * @param    o_activity             The details of the selected activity needed to populate
    *                                  the UX form.
    *    
    * @author  CRISTINA.OLIVEIRA
    * @version  2.6.4.3
    * @since   06/11/2013
    */
    PROCEDURE get_epis_nic_activity
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_nnn_epis_activity IN nnn_epis_activity.id_nnn_epis_activity%TYPE,
        o_activity          OUT pk_types.cursor_type
    );

    /**
    *  Gets the data of a NIC Activity in a patient's nursing care plan (nnn_epis_activity row).
    *    
    * @param    i_nnn_epis_activity    Careplan's NIC Activity ID
    *
    * @return   The activity data (nnn_epis_activity row)
    *    
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    5/2/2014
    */
    FUNCTION get_epis_nic_activity_row(i_nnn_epis_activity IN nnn_epis_activity.id_nnn_epis_activity%TYPE)
        RETURN nnn_epis_activity%ROWTYPE;

    /**
    * Returns the necessary information on all executions of a Activity
    *    
    * @param    i_nnn_epis_activity  Careplan's NIC Activity ID
    * @param    i_fltr_status          A sequence of flags representing the status that records must comply. Default: Any     
    *
    * @return   Collection of the executions of the selected Activity
    *    
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   5/2/2014
    */
    FUNCTION get_epis_nic_activity_execs
    (
        i_nnn_epis_activity IN nnn_epis_activity_det.id_nnn_epis_activity%TYPE,
        i_fltr_status       IN VARCHAR DEFAULT pk_nnn_constant.g_req_status_filter_any
    ) RETURN ts_nnn_epis_activity_det.nnn_epis_activity_det_tc;

    /**
    *  Gets the data of a NIC Activity execution in a patient's nursing care plan (nnn_epis_activity_det row).
    *    
    * @param    i_nnn_epis_activity_det Careplan's NIC Activity execution ID
    *
    * @return   The activity execution data (nnn_epis_activity_det row)
    *    
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    5/19/2014
    */
    FUNCTION get_epis_nic_activity_det_row(i_nnn_epis_activity_det IN nnn_epis_activity_det.id_nnn_epis_activity_det%TYPE)
        RETURN nnn_epis_activity_det%ROWTYPE;

    /**
    *  Gets the data of a NIC Intervention in a patient's nursing care plan (nnn_epis_intervention row).
    *    
    * @param    i_nnn_epis_intervention    Careplan's NIC Intervention ID
    *
    * @return   The intervention data (nnn_epis_intervention row)
    *    
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    5/5/2014
    */
    FUNCTION get_epis_nic_intervention_row(i_nnn_epis_intervention IN nnn_epis_intervention.id_nnn_epis_intervention%TYPE)
        RETURN nnn_epis_intervention%ROWTYPE;

    /**
    * Creates or updates a NANDA Nursing Diagnosis in a patient's nursing care plan.
    *
    * @param    i_lang                  Professional preferred language
    * @param    i_prof                  Professional identification and its context (institution and software)
    * @param    i_patient               Patient ID
    * @param    i_episode               Episode ID
    * @param    i_nan_diagnosis         NANDA diagnosis ID
    * @param    i_nnn_epis_diagnosis    Careplan's NANDA Diagnosis ID. Declared to update an existing nursing diagnosis or NULL to create a new one
    * @param    i_dt_diagnosis          Diagnosis date    
    * @param    i_notes                 Notes
    * @param    i_flg_req_status        Request status
    * @param    i_timestamp             Timestamp that should be used across all the functions invoked from this one. Default or NULL to use current_timestamp
    *
    * @return   Careplan's NANDA Diagnosis ID
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    12/11/2013
    */
    FUNCTION set_epis_nan_diagnosis
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_nan_diagnosis      IN nnn_epis_diagnosis.id_nan_diagnosis%TYPE,
        i_dt_diagnosis       IN nnn_epis_diagnosis.dt_diagnosis%TYPE,
        i_nnn_epis_diagnosis IN nnn_epis_diagnosis.id_nnn_epis_diagnosis%TYPE DEFAULT NULL,
        i_notes              IN nnn_epis_diagnosis.edited_diagnosis_name%TYPE DEFAULT NULL,
        i_flg_req_status     IN nnn_epis_diagnosis.flg_req_status%TYPE DEFAULT pk_nnn_constant.g_req_status_ordered,
        i_timestamp          IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) RETURN nnn_epis_diagnosis.id_nnn_epis_diagnosis%TYPE;

    /**
    * Creates or updates an evaluation of NANDA Nursing Diagnosis in a patient's nursing care plan.
    *
    * @param    i_lang                  Professional preferred language
    * @param    i_prof                  Professional identification and its context (institution and software)
    * @param    i_patient               Patient ID
    * @param    i_episode               Episode ID
    * @param    i_nnn_epis_diagnosis    Careplan's NANDA Diagnosis ID 
    * @param    i_nnn_epis_diag_eval    Careplan's NANDA Diagnosis Evaluation ID. Declared to update an existing evaluation or NULL to create a new one
    * @param    i_flg_status            Diagnosis status
    * @param    i_dt_evaluation         Evaluation date 
    * @param    i_notes                 Notes
    * @param    i_lst_nan_relf          List of Related Factors for the NANDA nursing diagnosis
    * @param    i_lst_nan_riskf         List of Risk Factors for the NANDA nursing diagnosis
    * @param    i_lst_nan_defc          List of Defined characteristics for the NANDA nursing diagnosis
    * @param    i_timestamp             Timestamp that should be used across all the functions invoked from this one. Default or NULL to use current_timestamp
    *
    * @return   Careplan's NANDA Diagnosis Evaluation ID
    *
    * @author   CRISTINA.OLIVEIRA
    * @version  2.6.4.3  
    * @since    11/6/2013
    */
    FUNCTION set_epis_nan_diagnosis_eval
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_nnn_epis_diagnosis IN nnn_epis_diag_eval.id_nnn_epis_diagnosis%TYPE,
        i_nnn_epis_diag_eval IN nnn_epis_diag_eval.id_nnn_epis_diag_eval%TYPE DEFAULT NULL,
        i_flg_status         IN nnn_epis_diag_eval.flg_status%TYPE,
        i_dt_evaluation      IN nnn_epis_diag_eval.dt_evaluation%TYPE,
        i_notes              IN CLOB DEFAULT NULL,
        i_lst_nan_relf       IN table_number DEFAULT NULL,
        i_lst_nan_riskf      IN table_number DEFAULT NULL,
        i_lst_nan_defc       IN table_number DEFAULT NULL,
        i_timestamp          IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) RETURN nnn_epis_diag_eval.id_nnn_epis_diag_eval%TYPE;

    /**
    * Creates an evaluation of NANDA Nursing Diagnosis in a patient's nursing care plan using the information of the last evaluation (if any)and the status indicated in the input parameter.
    *
    * This method is only inteded to be used for actions like "Mark as Active", "Mark as Inactive", "Mark as Resolved"
    * to create a new evaluation, so as assumption the new diagnosis status must be different from de last one.
    * Otherwise shoud use the full method pk_nnn_core.set_epis_nan_diagnosis_eval.
    *
    * @param    i_lang                  Professional preferred language
    * @param    i_prof                  Professional identification and its context (institution and software)
    * @param    i_patient               Patient ID
    * @param    i_episode               Episode ID
    * @param    i_nnn_epis_diagnosis    Careplan's NANDA Diagnosis ID 
    * @param    i_flg_status            Diagnosis status
    *    
    * @return   Careplan's NANDA Diagnosis Evaluation ID
    *
    * @throws   e_invalid_argument      Invalid input values. Also raised when function was called with i_flg_status equal to diagnosis status recorded in the last evaluation.
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    3/13/2014
    */
    FUNCTION set_epis_nan_diagnosis_eval_st
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_nnn_epis_diagnosis IN nnn_epis_diag_eval.id_nnn_epis_diagnosis%TYPE,
        i_flg_status         IN nnn_epis_diag_eval.flg_status%TYPE
    ) RETURN nnn_epis_diag_eval.id_nnn_epis_diag_eval%TYPE;

    /**
    * Creates or updates a NOC Nursing Outcome in a patient's nursing care plan.
    *
    * @param    i_lang                         Professional preferred language
    * @param    i_prof                         Professional identification and its context (institution and software)
    * @param    i_patient                      Patient ID 
    * @param    i_episode                      Episode ID 
    * @param    i_noc_outcome                  NOC Outcome ID
    * @param    i_nnn_epis_outcome             Careplan's NOC Outcome ID. Declared to update an existing nursing outcome or NULL to create a new one     
    * @param    i_episode_origin               Episode ID where the activity was registered 
    * @param    i_episode_destination          Episode ID where the activity is going to be performed
    * @param    i_flg_prn                      Flag that indicates wether the Outcome is PRN or not
    * @param    i_notes_prn                    Notes to indicate when a PRN order should be activated
    * @param    i_flg_time                     Execution time to evaluate the outcome: In current (E)pisode, (B)etween episodes, (N)ext episode. 
    * @param    i_flg_priority                 Flag that indicates the priority of an Outcome: (N)ormal, (U)rgent, (E)mergent
    * @param    i_order_recurr_plan            Order recurrence plan ID for defined frequency in the instructions             
    * @param    i_flg_req_status               Request status
    * @param    i_timestamp                    Timestamp that should be used across all the functions invoked from this one. Default or NULL to use current_timestamp
    *
    * @return   Careplan's NOC Outcome ID
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   11/08/2013    
    */
    FUNCTION set_epis_noc_outcome
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_patient             IN nnn_epis_outcome.id_patient%TYPE,
        i_episode             IN nnn_epis_outcome.id_episode%TYPE,
        i_noc_outcome         IN nnn_epis_outcome.id_noc_outcome%TYPE,
        i_nnn_epis_outcome    IN nnn_epis_outcome.id_nnn_epis_outcome%TYPE DEFAULT NULL,
        i_episode_origin      IN nnn_epis_outcome.id_episode_origin%TYPE DEFAULT NULL,
        i_episode_destination IN nnn_epis_outcome.id_episode_destination%TYPE DEFAULT NULL,
        i_flg_prn             IN nnn_epis_outcome.flg_prn%TYPE DEFAULT pk_alert_constant.g_no,
        i_notes_prn           IN CLOB DEFAULT NULL,
        i_flg_time            IN nnn_epis_outcome.flg_time%TYPE DEFAULT pk_nnn_constant.g_time_performed_episode,
        i_flg_priority        IN nnn_epis_outcome.flg_priority%TYPE DEFAULT pk_nnn_constant.g_priority_normal,
        i_order_recurr_plan   IN nnn_epis_outcome.id_order_recurr_plan%TYPE DEFAULT NULL,
        i_flg_req_status      IN nnn_epis_outcome.flg_req_status%TYPE DEFAULT pk_nnn_constant.g_req_status_ordered,
        i_timestamp           IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) RETURN nnn_epis_outcome.id_nnn_epis_outcome%TYPE;

    /**
    * Creates or updates an evaluation of NOC Outcome in a patient's nursing care plan.
    *
    * @param    i_lang                  Professional preferred language
    * @param    i_prof                  Professional identification and its context (institution and software)
    * @param    i_patient               Patient ID
    * @param    i_episode               Episode ID
    * @param    i_nnn_epis_outcome      Careplan's NOC Outcome ID 
    * @param    i_nnn_epis_outcome_eval Careplan's NOC Outcome Evaluation ID. Declared to update an existing evaluation or NULL to create a new one
    * @param    i_dt_evaluation         Evaluation date 
    * @param    i_target_value          Outcome Target rating: Likert scale (1 to 5)
    * @param    i_outcome_value         Outcome overall rating: Likert scale (1 to 5)
    * @param    i_notes                 Notes
    * @param    i_dt_plan               Planned date for the outcome evaluation
    * @param    i_order_recurr_plan     Order recurrence plan ID for defined frequency in the instructions
    * @param    i_exec_number           The order of the execution within the plan as specified by the recurrence mechanism    
    * @param    i_flg_status            Evaluation status        
    * @param    i_timestamp             Timestamp that should be used across all the functions invoked from this one. Default or NULL to use current_timestamp    
    *
    * @return   Careplan's NOC Outcome Evaluation ID
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    11/11/2013
    */
    FUNCTION set_epis_noc_outcome_eval
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_patient               IN nnn_epis_outcome.id_patient%TYPE,
        i_episode               IN nnn_epis_outcome.id_episode%TYPE,
        i_nnn_epis_outcome      IN nnn_epis_outcome.id_nnn_epis_outcome%TYPE,
        i_nnn_epis_outcome_eval IN nnn_epis_outcome_eval.id_nnn_epis_outcome_eval%TYPE DEFAULT NULL,
        i_dt_evaluation         IN nnn_epis_outcome_eval.dt_evaluation%TYPE,
        i_target_value          IN nnn_epis_outcome_eval.target_value%TYPE,
        i_outcome_value         IN nnn_epis_outcome_eval.outcome_value%TYPE,
        i_notes                 IN CLOB DEFAULT NULL,
        i_dt_plan               IN nnn_epis_outcome_eval.dt_plan%TYPE DEFAULT NULL,
        i_order_recurr_plan     IN nnn_epis_outcome_eval.id_order_recurr_plan%TYPE DEFAULT NULL,
        i_exec_number           IN nnn_epis_outcome_eval.exec_number%TYPE DEFAULT NULL,
        i_flg_status            IN nnn_epis_outcome_eval.flg_status%TYPE DEFAULT pk_nnn_constant.g_task_status_finished,
        i_timestamp             IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) RETURN nnn_epis_outcome_eval.id_nnn_epis_outcome_eval%TYPE;

    /**
    * Checks if at least one planned evaluation of a given NOC Outcome was performed.
    *
    * @param    i_nnn_epis_outcome  Careplan's NOC Outcome ID
    *
    * @return   True if at least one planned evaluation was performed, false otherwise.
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    4/24/2014
    */
    FUNCTION get_outcome_has_evals(i_nnn_epis_outcome IN nnn_epis_outcome.id_nnn_epis_outcome%TYPE) RETURN BOOLEAN;

    /**
    * Gets the new Outcome status according with the finite state machine (FSM) that represent the allowable states 
    * and transitions for a NOC Outcome in a care plan.
    * The outcome status must be updated whenever an action is performed by the user. 
    * Each tansition has an identifier that is also used in the state diagram.
    * 
    * @param    i_lang              Professional preferred language
    * @param    i_prof              Professional identification and its context (institution and software)
    * @param    i_nnn_epis_outcome  Careplan's NOC Outcome ID whose status we want to update.
    * @param    i_flg_req_status    The status of the NOC Outcome
    * @param    i_action            An action performed by the user that caused the status change
    * 
    * @return   The new status.
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    4/24/2014
    */
    FUNCTION get_fsm_outcome_status
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_nnn_epis_outcome IN nnn_epis_outcome.id_nnn_epis_outcome%TYPE,
        i_flg_req_status   IN nnn_epis_outcome.flg_req_status%TYPE,
        i_action           IN action.internal_name%TYPE
    ) RETURN nnn_epis_outcome.flg_req_status%TYPE;

    /**
    * Updates the status of NOC Outcome and the ending valid time in case the new state is a final state.
    * The update occurs only if the Outcome is not currently in a final state and the new state is different from current one.
    * 
    * @param    i_lang              Professional preferred language
    * @param    i_prof              Professional identification and its context (institution and software)
    * @param    i_nnn_epis_outcome  Careplan's NOC Outcome ID whose status we want to update
    * @param    i_flg_req_status    The new status of the NOC Outcome
    * @param    i_timestamp         Timestamp that should be used across all the functions invoked from this one. Default or NULL to use current_timestamp
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    4/24/2014
    */
    PROCEDURE upd_noc_outcome_status
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_nnn_epis_outcome IN nnn_epis_outcome.id_nnn_epis_outcome%TYPE,
        i_flg_req_status   IN nnn_epis_outcome.flg_req_status%TYPE,
        i_timestamp        IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    );

    /**
    * Establishes a link between a NANDA Diagnosis and a NOC Outcome within a patient's nursing care plan.
    *
    * @param    i_prof                         Professional identification and its context (institution and software)
    * @param    i_episode                      Episode ID 
    * @param    i_nnn_epis_diagnosis           Careplan's NANDA Diagnosis ID
    * @param    i_nnn_epis_outcome             Careplan's NOC Outcome ID
    * @param    i_flg_lnk_status               Link status: (A)ctive, (C)ancelled
    * @param    i_timestamp                    Timestamp that should be used across all the functions invoked from this one. Default or NULL to use current_timestamp        
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   11/08/2013    
    */
    PROCEDURE set_lnk_diagnosis_outcome
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN nnn_epis_lnk_dg_outc.id_episode%TYPE,
        i_nnn_epis_diagnosis IN nnn_epis_lnk_dg_outc.id_nnn_epis_diagnosis%TYPE,
        i_nnn_epis_outcome   IN nnn_epis_lnk_dg_outc.id_nnn_epis_outcome%TYPE,
        i_flg_lnk_status     IN nnn_epis_lnk_dg_outc.flg_lnk_status%TYPE DEFAULT pk_alert_constant.g_active,
        i_timestamp          IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    );

    /**
    * Gets the available PRN options.
    *
    * @param    i_lang                  Professional preferred language
    * @param    o_list                  The list of the available PRN options
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   11/12/2013    
    */
    PROCEDURE get_prn_list
    (
        i_lang IN language.id_language%TYPE,
        o_list OUT pk_types.cursor_type
    );

    /**
    * Gets the available execution time options.
    * Based on PK_ICNP_FO.GET_TIME
    *
    * @param    i_lang                         Professional preferred language
    * @param    i_inst                         Professional's institution
    * @param    i_soft                         Professional's software
        
    * @param    o_time                         Cursor with a list of available execution time options
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   11/12/2013    
    */
    PROCEDURE get_time_list
    (
        i_lang IN language.id_language%TYPE,
        i_inst IN institution.id_institution%TYPE,
        i_soft IN software.id_software%TYPE,
        o_time OUT pk_types.cursor_type
    );

    /**
    * Gets default PRN option.
    *
    * @param    i_lang                         Professional preferred language
    * @param    i_prof                         Professional identification and its context (institution and software)
    *
    * @return   Default execution time
    *
    * @value    return        {*}'Y' PRN {*}'N' No PRN
    **
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   11/12/2013    
    */
    FUNCTION get_default_flg_prn(i_lang IN language.id_language%TYPE) RETURN VARCHAR2 result_cache;

    /**
    * Gets the default execution time option.
    *
    * @param    i_lang                         Professional preferred language
    * @param    i_inst                         Professional's institution
    * @param    i_soft                         Professional's software
    *
    * @return   Default execution time
    *
    * @value    return        {*}'E' In current Episode {*}'B' Between episodes {*}'N' Next episode
    **
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   11/12/2013    
    */
    FUNCTION get_default_flg_time
    (
        i_lang IN language.id_language%TYPE,
        i_inst IN institution.id_institution%TYPE,
        i_soft IN software.id_software%TYPE
    ) RETURN VARCHAR2 result_cache;

    /**
    * Gets the available Priority options.
    *
    * @param    i_lang                  Professional preferred language
    * @param    o_list                  The list of the available priority options
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   5/27/2014
    */
    PROCEDURE get_priority_list
    (
        i_lang IN language.id_language%TYPE,
        o_list OUT pk_types.cursor_type
    );

    /**
    * Gets the default priority option.
    *
    * @return   Default priority
    *
    * @value    return        {*}'N' g_priority_normal {*}'U' g_priority_urgent {*}'E' g_priority_emergent
    **
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   11/13/2013    
    */
    FUNCTION get_default_flg_priority RETURN VARCHAR2 result_cache;

    /**
    * Creates and returns a recurrence plan with default instructions for each NOC Outcome, NOC Indicator and NIC Activity.
    *
    * @param    i_lang                         Professional preferred language
    * @param    i_prof                         Professional identification and its context (institution and software)
    * @param    i_lst_outcome                  List of NOC Outcomes
    * @param    i_lst_indicator                List of NOC Indicators
    * @param    i_lst_activity                 List of NIC Activities
    * @param    o_default_outcome_instruct     Default instructions for NOC Outcomes 
    * @param    o_default_indicator_instruct   Default instructions for NOC Indicators
    * @param    o_default_activity_instruct    Default instructions for NIC Activities
    *
    * @throws   e_call_error
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   11/13/2013    
    */
    PROCEDURE create_default_instructions
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_lst_outcome                IN table_number,
        i_lst_indicator              IN table_number,
        i_lst_activity               IN table_number,
        o_default_outcome_instruct   OUT pk_types.cursor_type,
        o_default_indicator_instruct OUT pk_types.cursor_type,
        o_default_activity_instruct  OUT pk_types.cursor_type
    );

    /**
    * Creates or updates an NIC Nursing Intervention in a patient's nursing care plan.
    *
    * @param    i_lang                         Professional preferred language
    * @param    i_prof                         Professional identification and its context (institution and software)
    * @param    i_patient                      Patient ID 
    * @param    i_episode                      Episode ID 
    * @param    i_nic_intervention             NIC Intervention ID 
    * @param    i_nnn_epis_intervention        Careplan's NIC Intervention ID. Declared to update an existing nursing intervention or NULL to create a new one
    * @param    i_flg_req_status               Request status
    * @param    i_timestamp                    Timestamp that should be used across all the functions invoked from this one. Default or NULL to use current_timestamp    
    *
    * @return   Careplan's NIC Intervention ID
    *
    * @author   CRISTINA.OLIVEIRA
    * @version  2.6.4.3
    * @since    13/11/2013    
    */
    FUNCTION set_epis_nic_intervention
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_patient               IN nnn_epis_intervention.id_patient%TYPE,
        i_episode               IN nnn_epis_intervention.id_episode%TYPE,
        i_nic_intervention      IN nnn_epis_intervention.id_nic_intervention %TYPE,
        i_nnn_epis_intervention IN nnn_epis_intervention.id_nnn_epis_intervention%TYPE DEFAULT NULL,
        i_flg_req_status        IN nnn_epis_intervention.flg_req_status%TYPE DEFAULT pk_nnn_constant.g_req_status_ordered,
        i_timestamp             IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) RETURN nnn_epis_intervention.id_nnn_epis_intervention%TYPE;

    /**
    * Creates or updates an NIC Activity to a patient's nursing care plan.
    *
    * @param    i_lang                         Professional preferred language
    * @param    i_prof                         Professional identification and its context (institution and software)
    * @param    i_patient                      Patient ID 
    * @param    i_episode                      Episode ID 
    * @param    i_nic_activity                 NIC Activity ID 
    * @param    i_nnn_epis_activity            Careplan's NIC Activity ID. Declared to update an existing nursing activity or NULL to create a new one
    * @param    i_episode_origin               Episode ID where the activity was registered 
    * @param    i_episode_destination          Episode ID where the activity is going to be performed
    * @param    i_flg_prn                      Flag that indicates wether the Outcome is PRN or not
    * @param    i_notes_prn                    Notes to indicate when a PRN order should be activated
    * @param    i_flg_time                     Execution time to evaluate the outcome: In current (E)pisode, (B)etween episodes, (N)ext episode. 
    * @param    i_flg_priority                 Flag that indicates the priority of an Outcome: (N)ormal, (U)rgent, (E)mergent
    * @param    i_order_recurr_plan            Order recurrence plan ID for defined frequency in the instructions 
    * @param    i_flg_req_status               Request status
    * @param    i_timestamp                    Timestamp that should be used across all the functions invoked from this one. Default or NULL to use current_timestamp    
    *
    * @return   Careplan's NIC Activity ID
    *    
    * @author  CRISTINA.OLIVEIRA
    * @version  2.6.4.3
    * @since   13/11/2013    
    */
    FUNCTION set_epis_nic_activity
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_patient             IN nnn_epis_activity.id_patient%TYPE,
        i_episode             IN nnn_epis_activity.id_episode%TYPE,
        i_nic_activity        IN nnn_epis_activity.id_nic_activity%TYPE,
        i_nnn_epis_activity   IN nnn_epis_activity.id_nnn_epis_activity%TYPE DEFAULT NULL,
        i_episode_origin      IN nnn_epis_activity.id_episode_origin%TYPE DEFAULT NULL,
        i_episode_destination IN nnn_epis_activity.id_episode_destination%TYPE DEFAULT NULL,
        i_flg_prn             IN nnn_epis_activity.flg_prn%TYPE DEFAULT pk_alert_constant.g_no,
        i_notes_prn           IN CLOB DEFAULT NULL,
        i_flg_time            IN nnn_epis_activity.flg_time%TYPE DEFAULT pk_nnn_constant.g_time_performed_episode,
        i_flg_priority        IN nnn_epis_activity.flg_priority%TYPE DEFAULT pk_nnn_constant.g_priority_normal,
        i_order_recurr_plan   IN nnn_epis_activity.id_order_recurr_plan%TYPE DEFAULT NULL,
        i_flg_req_status      IN nnn_epis_activity.flg_req_status%TYPE DEFAULT pk_nnn_constant.g_req_status_ordered,
        i_timestamp           IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) RETURN nnn_epis_activity.id_nnn_epis_activity%TYPE;

    /**
    * Checks if at least one planned execution of a given NIC Activity was performed.
    *
    * @param    i_nnn_epis_outcome  Careplan's NIC Activity ID
    *
    * @return   True if at least one planned execution was performed, false otherwise.
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    5/2/2014
    */
    FUNCTION get_activity_has_execs(i_nnn_epis_activity IN nnn_epis_activity.id_nnn_epis_activity%TYPE) RETURN BOOLEAN;

    /**
    * Gets the new Activity status according with the finite state machine (FSM) that represent the allowable states 
    * and transitions for a NIC Activity in a care plan.
    * The activity status must be updated whenever an action is performed by the user. 
    * Each tansition has an identifier that is also used in the state diagram.
    * 
    * @param    i_lang              Professional preferred language
    * @param    i_prof              Professional identification and its context (institution and software)
    * @param    i_nnn_epis_activity Careplan's NIC Activity ID whose status we want to update.
    * @param    i_flg_req_status    The status of the NIC Activity
    * @param    i_action            An action performed by the user that caused the status change
    * 
    * @return   The new status.
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    5/2/2014
    */
    FUNCTION get_fsm_activity_status
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_nnn_epis_activity IN nnn_epis_activity.id_nnn_epis_activity%TYPE,
        i_flg_req_status    IN nnn_epis_activity.flg_req_status%TYPE,
        i_action            IN action.internal_name%TYPE
    ) RETURN nnn_epis_activity.flg_req_status%TYPE;

    /**
    * Creates or updates the execution of a NIC Activity in a patient's nursing care plan.
    *
    * @param    i_lang                  Professional preferred language
    * @param    i_prof                  Professional identification and its context (institution and software)
    * @param    i_patient               Patient ID
    * @param    i_episode               Episode ID
    * @param    i_nnn_epis_activity     Careplan's NIC Activity ID
    * @param    i_nnn_epis_activity_det Careplan's NIC Activity execution ID
    * @param    i_time_start            Start date of activiy execution 
    * @param    i_time_end              End date of activiy execution
    * @param    i_epis_documentation    Documentation ID
    * @param    i_vital_sign_read_list  List of vital sign measurement associated to this activity (id_vital_sign_read) separated by pipes "|"
    * @param    i_notes                 Notes
    * @param    i_lst_task_activity     List of activity task (used to document child tasks within a NIC Activity that was defined as tasklist)
    * @param    i_lst_task_executed     List of flags to indicate the activity task was executed or not
    * @param    i_lst_task_notes        List of notes for the activity task    
    * @param    i_dt_plan               Planned date for the activity execution
    * @param    i_order_recurr_plan     Order recurrence plan ID for defined frequency in the instructions
    * @param    i_exec_number           The order of the execution within the plan as specified by the recurrence mechanism    
    * @param    i_flg_status            Execution status        
    * @param    i_timestamp             Timestamp that should be used across all the functions invoked from this one. Default or NULL to use current_timestamp    
        
    *
    * @return   Careplan's NIC Activity Execution ID
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    5/16/2014
    */
    FUNCTION set_epis_nic_activity_det
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_patient               IN nnn_epis_activity_det.id_patient%TYPE,
        i_episode               IN nnn_epis_activity_det.id_episode%TYPE,
        i_nnn_epis_activity     IN nnn_epis_activity_det.id_nnn_epis_activity%TYPE,
        i_nnn_epis_activity_det IN nnn_epis_activity_det.id_nnn_epis_activity_det%TYPE DEFAULT NULL,
        i_time_start            IN nnn_epis_activity_det.dt_val_time_start%TYPE,
        i_time_end              IN nnn_epis_activity_det.dt_val_time_end%TYPE,
        i_epis_documentation    IN nnn_epis_activity_det.id_epis_documentation%TYPE,
        i_vital_sign_read_list  IN nnn_epis_activity_det.vital_sign_read_list%TYPE,
        i_notes                 IN CLOB DEFAULT NULL,
        i_lst_task_activity     IN table_number DEFAULT NULL,
        i_lst_task_executed     IN table_varchar DEFAULT NULL,
        i_lst_task_notes        IN table_varchar DEFAULT NULL,
        i_dt_plan               IN nnn_epis_activity_det.dt_plan%TYPE DEFAULT NULL,
        i_order_recurr_plan     IN nnn_epis_activity_det.id_order_recurr_plan%TYPE DEFAULT NULL,
        i_exec_number           IN nnn_epis_activity_det.exec_number%TYPE DEFAULT NULL,
        i_flg_status            IN nnn_epis_activity_det.flg_status%TYPE DEFAULT pk_nnn_constant.g_task_status_finished,
        i_timestamp             IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) RETURN nnn_epis_activity_det.id_nnn_epis_activity_det%TYPE;

    /**
    * Updates the status of NIC Intervention and the ending valid time in case the new state is a final state.
    * The update occurs only if the Intervention is not currently in a final state and the new state is different from current one.
    * 
    * @param    i_lang                   Professional preferred language
    * @param    i_prof                   Professional identification and its context (institution and software)
    * @param    i_nnn_epis_intervention  Careplan's NIC Intervention ID whose status we want to update
    * @param    i_flg_req_status         The new status of the NIC Intervention
    * @param    i_timestamp              Timestamp that should be used across all the functions invoked from this one. Default or NULL to use current_timestamp
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    5/15/2014
    */
    PROCEDURE upd_nic_interv_status
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_nnn_epis_intervention IN nnn_epis_intervention.id_nnn_epis_intervention%TYPE,
        i_flg_req_status        IN nnn_epis_intervention.flg_req_status%TYPE,
        i_timestamp             IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    );

    /**
    * Gets the new Intervention status according with the finite state machine (FSM) that represent the allowable states 
    * and transitions for a NIC Intervention in a care plan.
    * The intervention status must be updated whenever an action is performed by the user. 
    * Each tansition has an identifier that is also used in the state diagram.
    * 
    * @param    i_lang                  Professional preferred language
    * @param    i_prof                  Professional identification and its context (institution and software)
    * @param    i_nnn_epis_intervention Careplan's NIC Intervention ID whose status we want to update.
    * @param    i_flg_req_status        The status of the NIC Intervention
    * @param    i_action                An action performed by the user that caused the status change
    * 
    * @return   The new status.
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    5/5/2014
    */
    FUNCTION get_fsm_intervention_status
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_nnn_epis_intervention IN nnn_epis_intervention.id_nnn_epis_intervention%TYPE,
        i_flg_req_status        IN nnn_epis_intervention.flg_req_status%TYPE,
        i_action                IN action.internal_name%TYPE
    ) RETURN nnn_epis_intervention.flg_req_status%TYPE;

    /**
    * Updates the status of NIC Activity and the ending valid time in case the new state is a final state.
    * The update occurs only if the Activity is not currently in a final state and the new state is different from current one.
    * 
    * @param    i_lang                   Professional preferred language
    * @param    i_prof                   Professional identification and its context (institution and software)
    * @param    i_nnn_epis_intervention  Careplan's NIC Activity ID whose status we want to update
    * @param    i_flg_req_status         The new status of the NIC Activity
    * @param    i_timestamp              Timestamp that should be used across all the functions invoked from this one. Default or NULL to use current_timestamp
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    5/15/2014
    */
    PROCEDURE upd_nic_activity_status
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_nnn_epis_activity IN nnn_epis_activity.id_nnn_epis_activity%TYPE,
        i_flg_req_status    IN nnn_epis_activity.flg_req_status%TYPE,
        i_timestamp         IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    );

    /**
    * Establishes a link between a NIC Intervention and a NIC Activity within a patient's nursing care plan.
    *
    * @param    i_prof                         Professional identification and its context (institution and software)
    * @param    i_episode                      Episode ID 
    * @param    i_nnn_epis_intervention        Careplan's NIC Intervention ID
    * @param    i_nnn_epis_activity            Careplan's NIC Activity ID
    * @param    i_flg_lnk_status               Link status: (A)ctive, (C)ancelled
    * @param    i_timestamp                    Timestamp that should be used across all the functions invoked from this one. Default or NULL to use current_timestamp    
    *
    * @author  CRISTINA.OLIVEIRA
    * @version  2.6.4.3
    * @since   13/11/2013    
    */
    PROCEDURE set_lnk_intervention_activity
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN nnn_epis_lnk_int_actv.id_episode%TYPE,
        i_nnn_epis_intervention IN nnn_epis_lnk_int_actv.id_nnn_epis_intervention%TYPE,
        i_nnn_epis_activity     IN nnn_epis_lnk_int_actv.id_nnn_epis_activity%TYPE,
        i_flg_lnk_status        IN nnn_epis_lnk_int_actv.flg_lnk_status%TYPE DEFAULT pk_alert_constant.g_active,
        i_timestamp             IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    );

    /**
    * Establishes a link between a NOC Outcome and a NOC Indicator within a patient's nursing care plan.
    *
    * @param    i_prof                         Professional identification and its context (institution and software)
    * @param    i_episode                      Episode ID 
    * @param    i_nnn_epis_outcome             Careplan's NOC Outcome ID
    * @param    i_nnn_epis_indicator           Careplan's NOC indicator ID
    * @param    i_flg_lnk_status               Link status: (A)ctive, (C)ancelled
    * @param    i_timestamp                    Timestamp that should be used across all the functions invoked from this one. Default or NULL to use current_timestamp    
    *
    * @author  CRISTINA.OLIVEIRA
    * @version  2.6.4.3
    * @since   21/11/2013    
    */
    PROCEDURE set_lnk_outcome_indicator
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN nnn_epis_lnk_outc_ind.id_episode%TYPE,
        i_nnn_epis_outcome   IN nnn_epis_lnk_outc_ind.id_nnn_epis_outcome%TYPE,
        i_nnn_epis_indicator IN nnn_epis_lnk_outc_ind.id_nnn_epis_indicator%TYPE,
        i_flg_lnk_status     IN nnn_epis_lnk_outc_ind.flg_lnk_status%TYPE DEFAULT pk_alert_constant.g_active,
        i_timestamp          IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    );

    /**
    * Establishes a link between a NANDA Diagnosis and a NIC Intervention within a patient's nursing care plan.
    *
    * @param    i_prof                         Professional identification and its context (institution and software)
    * @param    i_episode                      Episode ID 
    * @param    i_nnn_epis_diagnosis           Careplan's NNADA Diagnosis ID
    * @param    i_nnn_epis_intervention        Careplan's NIC Intervention ID
    * @param    i_flg_lnk_status               Link status: (A)ctive, (C)ancelled
    *
    * @author  CRISTINA.OLIVEIRA
    * @version  2.6.4.3
    * @since   21/11/2013    
    */
    PROCEDURE set_lnk_diagnosis_intervention
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN nnn_epis_lnk_dg_intrv.id_episode%TYPE,
        i_nnn_epis_diagnosis    IN nnn_epis_lnk_dg_intrv.id_nnn_epis_diagnosis%TYPE,
        i_nnn_epis_intervention IN nnn_epis_lnk_dg_intrv.id_nnn_epis_intervention%TYPE,
        i_flg_lnk_status        IN nnn_epis_lnk_dg_intrv.flg_lnk_status%TYPE DEFAULT pk_alert_constant.g_active,
        i_timestamp             IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    );

    /**
    * Cancels an NANDA Nursing Diagnosis to a patient nursing care plan (nnn_epis_diagnosis).
    *
    * @param    i_prof                  Professional identification and its context (institution and software)
    * @param    i_nnn_epis_diagnosis    ID Episode Diagnosis       
    * @param    i_cancel_reason         Cancellation reason identifier.
    * @param    i_cancel_notes          Notes describing the reason of the cancellation.
    *
    *
    * @author   CRISTINA.OLIVEIRA
    * @version  2.6.4.3 
    * @since    14/11/2013 
    */
    /*  PROCEDURE cancel_epis_nan_diagnosis
    (
    i_lang               IN language.id_language%TYPE,
    i_prof               IN profissional,
    i_nnn_epis_diagnosis IN nnn_epis_diagnosis.id_nnn_epis_diagnosis%TYPE,
    i_cancel_reason      IN nnn_epis_diagnosis.id_cancel_reason%TYPE,
    i_cancel_notes       IN nnn_epis_diagnosis.cancel_notes%TYPE DEFAULT NULL
    );*/

    /**
    * Cancels an NOC Outcome to a patient nursing care plan (nnn_epis_outcome).
    *
    * @param    i_prof                  Professional identification and its context (institution and software)
    * @param    i_nnn_epis_outcome      Careplan's NOC Outcome ID
    * @param    i_cancel_reason         Cancellation reason identifier.
    * @param    i_cancel_notes          Notes describing the reason of the cancellation.
    * @param    i_flg_req_status        Status: Cancel / Discontinue
    * @param    i_timestamp             Timestamp that should be used across all the functions invoked from this one. Default or NULL to use current_timestamp     
    *
    * @author   CRISTINA.OLIVEIRA
    * @version  2.6.4.3 
    * @since    14/11/2013 
    */
    PROCEDURE cancel_epis_noc_outcome
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_nnn_epis_outcome IN nnn_epis_outcome.id_nnn_epis_outcome%TYPE,
        i_cancel_reason    IN nnn_epis_outcome.id_cancel_reason%TYPE,
        i_cancel_notes     IN nnn_epis_outcome.cancel_notes%TYPE DEFAULT NULL,
        i_flg_req_status   IN nnn_epis_outcome.flg_req_status%TYPE DEFAULT pk_nnn_constant.g_req_status_cancelled,
        i_timestamp        IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    );

    /**
    * Cancels an NOC Indicador to a patient nursing care plan (nnn_epis_indicator).
    *
    * @param    i_prof                  Professional identification and its context (institution and software)
    * @param    i_nnn_epis_indicator    ID Episode indicator
    * @param    i_cancel_reason         Cancellation reason identifier.
    * @param    i_cancel_notes          Notes describing the reason of the cancellation.
    * @param    i_flg_req_status        Status: Cancel / Discontinue
    * @param    i_timestamp             Timestamp that should be used across all the functions invoked from this one. Default or NULL to use current_timestamp
    *
    * @author   CRISTINA.OLIVEIRA
    * @version  2.6.4.3 
    * @since    14/11/2013 
    */
    PROCEDURE cancel_epis_noc_indicator
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_nnn_epis_indicator IN nnn_epis_indicator.id_nnn_epis_indicator%TYPE,
        i_cancel_reason      IN nnn_epis_indicator.id_cancel_reason%TYPE,
        i_cancel_notes       IN nnn_epis_indicator.cancel_notes%TYPE DEFAULT NULL,
        i_flg_req_status     IN nnn_epis_indicator.flg_req_status%TYPE DEFAULT pk_nnn_constant.g_req_status_cancelled,
        i_timestamp          IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    );

    /**
    * Cancels an NIC Intervention to a patient nursing care plan (nnn_epis_intervention).
    *
    * @param    i_prof                  Professional identification and its context (institution and software)
    * @param    i_nnn_epis_intervention ID Episode Intervention
    * @param    i_cancel_reason         Cancellation reason identifier.
    * @param    i_cancel_notes          Notes describing the reason of the cancellation.
    * @param    i_flg_req_status        Status: Cancel / Discontinue
    * @param    i_timestamp             Timestamp that should be used across all the functions invoked from this one. Default or NULL to use current_timestamp     
    *
    * @author   CRISTINA.OLIVEIRA
    * @version  2.6.4.3 
    * @since    14/11/2013 
    */
    PROCEDURE cancel_epis_nic_intervention
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_nnn_epis_intervention IN nnn_epis_intervention.id_nnn_epis_intervention%TYPE,
        i_cancel_reason         IN nnn_epis_intervention.id_cancel_reason%TYPE,
        i_cancel_notes          IN nnn_epis_intervention.cancel_notes%TYPE DEFAULT NULL,
        i_flg_req_status        IN nnn_epis_intervention.flg_req_status%TYPE DEFAULT pk_nnn_constant.g_req_status_cancelled,
        i_timestamp             IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    );

    /**
    * Cancels an NIC Activity to a patient nursing care plan (nnn_epis_activity).
    *
    * @param    i_prof                  Professional identification and its context (institution and software)
    * @param    i_nnn_epis_activity     ID Episode Activity
    * @param    i_cancel_reason         Cancellation reason identifier.
    * @param    i_cancel_notes          Notes describing the reason of the cancellation.
    * @param    i_flg_req_status        Status: Cancel / Discontinue
    * @param    i_timestamp             Timestamp that should be used across all the functions invoked from this one. Default or NULL to use current_timestamp          
    *
    * @author   CRISTINA.OLIVEIRA
    * @version  2.6.4.3 
    * @since    14/11/2013 
    */
    PROCEDURE cancel_epis_nic_activity
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_nnn_epis_activity IN nnn_epis_activity.id_nnn_epis_activity%TYPE,
        i_cancel_reason     IN nnn_epis_activity.id_cancel_reason%TYPE,
        i_cancel_notes      IN nnn_epis_activity.cancel_notes%TYPE DEFAULT NULL,
        i_flg_req_status    IN nnn_epis_activity.flg_req_status%TYPE DEFAULT pk_nnn_constant.g_req_status_cancelled,
        i_timestamp         IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    );

    /**
    * Cancels an execution of NIC Activity in a patient's nursing care plan (nnn_epis_activity_det).
    *
    * @param    i_prof                  Professional identification and its context (institution and software)
    * @param    i_nnn_epis_activity_det Careplan's NIC Activity execution ID
    * @param    i_cancel_reason         Cancellation reason identifier.
    * @param    i_cancel_notes          Notes describing the reason of the cancellation.
    * @param    i_timestamp             Timestamp that should be used across all the functions invoked from this one. Default or NULL to use current_timestamp     
    *
    * @author   CRISTINA.OLIVEIRA
    * @version  2.6.4.3 
    * @since    14/11/2013 
    */
    PROCEDURE cancel_epis_nic_activity_exec
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_nnn_epis_activity_det IN nnn_epis_activity_det.id_nnn_epis_activity_det%TYPE,
        i_cancel_reason         IN nnn_epis_activity_det.id_cancel_reason%TYPE,
        i_cancel_notes          IN nnn_epis_activity_det.cancel_notes%TYPE DEFAULT NULL,
        i_timestamp             IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    );

    /**
    * Cancels evaluations associated a one Activity (nnn_epis_activity_det).
    *
    * @param    i_lang                  Professional preferred language     
    * @param    i_prof                  Professional identification and its context (institution and software)
    * @param    i_nnn_epis_activity     Careplan's NIC Activity ID
    * @param    i_cancel_reason         Cancellation reason identifier.
    * @param    i_cancel_notes          Notes describing the reason of the cancellation.
    * @param    i_timestamp             Timestamp that should be used across all the functions invoked from this one. Default or NULL to use current_timestamp     
    *
    * @author   CRISTINA.OLIVEIRA
    * @version  2.6.4.3 
    * @since    14/11/2013 
    */
    PROCEDURE cancel_epis_nic_activity_execs
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_nnn_epis_activity IN nnn_epis_activity_det.id_nnn_epis_activity%TYPE,
        i_cancel_reason     IN nnn_epis_activity_det.id_cancel_reason%TYPE,
        i_cancel_notes      IN nnn_epis_activity_det.cancel_notes%TYPE DEFAULT NULL,
        i_timestamp         IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    );

    /**
    * Cancels an Evaluation of NANDA Nursing Diagnosis in a patient's nursing care plan (nnn_epis_diag_eval).
    *
    * @param    i_lang                  Professional preferred language
    * @param    i_prof                  Professional identification and its context (institution and software)
    * @param    i_nnn_epis_diag_eval    Diagnosis Evaluation ID
    * @param    i_cancel_reason         Cancellation reason identifier.
    * @param    i_cancel_notes          Notes describing the reason of the cancellation.
    * @param    i_timestamp             Timestamp that should be used across all the functions invoked from this one. Default or NULL to use current_timestamp
    *
    * @author   CRISTINA.OLIVEIRA
    * @version  2.6.4.3 
    * @since    14/11/2013 
    */
    PROCEDURE cancel_epis_nan_diag_eval
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_nnn_epis_diag_eval IN nnn_epis_diag_eval.id_nnn_epis_diag_eval%TYPE,
        i_cancel_reason      IN nnn_epis_diag_eval.id_cancel_reason%TYPE,
        i_cancel_notes       IN nnn_epis_diag_eval.cancel_notes%TYPE DEFAULT NULL,
        i_timestamp          IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    );

    /**
    * Cancels an Evaluation of NOC Outcome in a patient's nursing care plan (nnn_epis_outcome_eval).
    *
    * @param    i_prof                  Professional identification and its context (institution and software)
    * @param    i_nnn_epis_outcome_eval Careplan's NOC Outcome Evaluation ID
    * @param    i_cancel_reason         Cancellation reason identifier.
    * @param    i_cancel_notes          Notes describing the reason of the cancellation.
    * @param    i_timestamp             Timestamp that should be used across all the functions invoked from this one. Default or NULL to use current_timestamp     
    *
    * @author   CRISTINA.OLIVEIRA
    * @version  2.6.4.3 
    * @since    14/11/2013 
    */
    PROCEDURE cancel_epis_noc_outcome_eval
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_nnn_epis_outcome_eval IN nnn_epis_outcome_eval.id_nnn_epis_outcome_eval%TYPE,
        i_cancel_reason         IN nnn_epis_outcome_eval.id_cancel_reason%TYPE,
        i_cancel_notes          IN nnn_epis_outcome_eval.cancel_notes%TYPE DEFAULT NULL,
        i_timestamp             IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    );

    /**
    * Cancels an Evaluation of NOC Indicator in a patient's nursing care plan (nnn_epis_ind_eval).
    *
    * @param    i_prof                  Professional identification and its context (institution and software)
    * @param    i_nnn_epis_ind_eval     Indicator Evaluation ID
    * @param    i_cancel_reason         Cancellation reason identifier.
    * @param    i_cancel_notes          Notes describing the reason of the cancellation.
    * @param    i_timestamp             Timestamp that should be used across all the functions invoked from this one. Default or NULL to use current_timestamp          
    *
    * @author   CRISTINA.OLIVEIRA
    * @version  2.6.4.3 
    * @since    14/11/2013 
    */
    PROCEDURE cancel_epis_noc_ind_eval
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_nnn_epis_ind_eval IN nnn_epis_ind_eval.id_nnn_epis_ind_eval%TYPE,
        i_cancel_reason     IN nnn_epis_ind_eval.id_cancel_reason%TYPE,
        i_cancel_notes      IN nnn_epis_ind_eval.cancel_notes%TYPE DEFAULT NULL,
        i_timestamp         IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    );

    /**
    * Cancels the link between a NANDA Diagnosis and a NIC Inetrvention within a patient's nursing care plan.
    *
    * @param    i_prof                  Professional identification and its context (institution and software)
    * @param    i_nnn_epis_lnk_dg_intrv Linkage Diagnosis Intervention ID
    *
    * @author   CRISTINA.OLIVEIRA
    * @version  2.6.4.3 
    * @since    14/11/2013 
    */
    PROCEDURE cancel_lnk_dg_intrv
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_nnn_epis_lnk_dg_intrv IN nnn_epis_lnk_dg_intrv.id_nnn_epis_lnk_dg_intrv%TYPE
    );

    /**
    * Cancels the link between a NANDA Diagnosis and a NOC Outcome within a patient's nursing care plan.
    *
    * @param    i_prof                  Professional identification and its context (institution and software)
    * @param    i_nnn_epis_lnk_dg_outc  Linkage Diagnosis Outcome ID
    *
    * @author   CRISTINA.OLIVEIRA
    * @version  2.6.4.3 
    * @since    14/11/2013 
    */
    PROCEDURE cancel_lnk_dg_outc
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_nnn_epis_lnk_dg_outc IN nnn_epis_lnk_dg_outc.id_nnn_epis_lnk_dg_outc%TYPE
    );

    /**
    * Cancels the link between a NOC Outcome and a NOC indicator within a patient's nursing care plan.
    *
    * @param    i_prof                  Professional identification and its context (institution and software)
    * @param    i_nnn_epis_lnk_outc_ind  Linkage Outcome Indicator ID
    *
    * @author   CRISTINA.OLIVEIRA
    * @version  2.6.4.3 
    * @since    14/11/2013 
    */
    PROCEDURE cancel_lnk_outc_ind
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_nnn_epis_lnk_outc_ind IN nnn_epis_lnk_outc_ind.id_nnn_epis_lnk_outc_ind%TYPE
    );

    /**
    * Cancels the link between a NIC Intervention and a NIC Activity within a patient's nursing care plan.
    *
    * @param    i_prof                  Professional identification and its context (institution and software)
    * @param    i_nnn_epis_lnk_int_actv Linkage Intervention Activity ID
    *
    * @author   CRISTINA.OLIVEIRA
    * @version  2.6.4.3 
    * @since    14/11/2013 
    */
    PROCEDURE cancel_lnk_int_actv
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_nnn_epis_lnk_int_actv IN nnn_epis_lnk_int_actv.id_nnn_epis_lnk_int_actv%TYPE
    );

    /**
    * Gets all the Linkages active between the Diagnosis and Outcomes for a diagnosis.
    *  
    * @param    i_nnn_epis_diagnosis Diagnosis ID
    *
    * @return   Collection of linkages Outcomes 
    *
    * @author   CRISTINA.OLIVEIRA
    * @version  2.6.4.3 
    * @since    18/11/2013 
    */
    FUNCTION get_lnk_dg_outc_by_diag
    (
        i_nnn_epis_diagnosis IN nnn_epis_lnk_dg_outc.id_nnn_epis_diagnosis%TYPE,
        i_fltr_status        IN VARCHAR DEFAULT pk_nnn_constant.g_req_status_filter_any
    ) RETURN ts_nnn_epis_lnk_dg_outc.nnn_epis_lnk_dg_outc_tc;

    /**
    * Gets all the Linkages active between the Diagnosis and Outcome for a Outcome.
    *  
    * @param    i_nnn_epis_outcome    Careplan's NOC Outcome ID
    *
    * @return   Collection of Linkages Outcomes 
    *
    * @author   CRISTINA.OLIVEIRA
    * @version  2.6.4.3 
    * @since    18/11/2013 
    */
    FUNCTION get_lnk_dg_outc_by_outc
    (
        i_nnn_epis_outcome IN nnn_epis_lnk_dg_outc.id_nnn_epis_outcome%TYPE,
        i_fltr_status      IN VARCHAR DEFAULT pk_nnn_constant.g_req_status_filter_any
    ) RETURN ts_nnn_epis_lnk_dg_outc.nnn_epis_lnk_dg_outc_tc;

    /**
    * Gets all the Linkages active between the Diagnoses and Outcomes for a set of diagnoses.
    *  
    * @param    Collection of Diagnoses ID
    *
    * @return   Collection of Linkages Outcomes 
    *
    * @author   CRISTINA.OLIVEIRA
    * @version  2.6.4.3 
    * @since    18/11/2013 
    */
    FUNCTION get_lnk_dg_outc_by_diags
    (
        i_lst_nnn_epis_diag IN table_number,
        i_fltr_status       IN VARCHAR DEFAULT pk_nnn_constant.g_req_status_filter_any
    ) RETURN ts_nnn_epis_lnk_dg_outc.nnn_epis_lnk_dg_outc_tc;

    /**
    * Gets all the Linkages active between the Outcome and Indicators for one NOC Outcome.
    *  
    * @param    i_nnn_epis_outcome    Careplan's NOC Outcome ID
    *
    * @return   Collection of Linkages Indicators 
    *
    * @author   CRISTINA.OLIVEIRA
    * @version  2.6.4.3 
    * @since    18/11/2013 
    */
    FUNCTION get_lnk_outc_ind_by_outc
    (
        i_nnn_epis_outcome IN nnn_epis_lnk_outc_ind.id_nnn_epis_outcome%TYPE,
        i_fltr_status      IN VARCHAR DEFAULT pk_nnn_constant.g_req_status_filter_any
    ) RETURN ts_nnn_epis_lnk_outc_ind.nnn_epis_lnk_outc_ind_tc;

    /**
    * Gets all the linkages active between the outcome and the indicator for one NOC Indicator.
    *  
    * @param    i_nnn_epis_indicator Episode Indicator ID
    *
    * @return   Collection of linkages Indicators 
    *
    * @author   CRISTINA.OLIVEIRA
    * @version  2.6.4.3 
    * @since    18/11/2013 
    */
    FUNCTION get_lnk_outc_ind_by_ind
    (
        i_nnn_epis_indicator IN nnn_epis_lnk_outc_ind.id_nnn_epis_indicator%TYPE,
        i_fltr_status        IN VARCHAR DEFAULT pk_nnn_constant.g_req_status_filter_any
    ) RETURN ts_nnn_epis_lnk_outc_ind.nnn_epis_lnk_outc_ind_tc;

    /**
    * Gets all the Linkages active  between the Diagnosis and Interventions for one NANDA Diagnosis.
    *  
    * @param    i_nnn_epis_diagnosis Episode Diagnosis ID
    *
    * @return   Collection of linkages Interventions 
    *
    * @author   CRISTINA.OLIVEIRA
    * @version  2.6.4.3 
    * @since    18/11/2013 
    */
    FUNCTION get_lnk_dg_intrv_by_diag
    (
        i_nnn_epis_diagnosis IN nnn_epis_lnk_dg_intrv.id_nnn_epis_diagnosis%TYPE,
        i_fltr_status        IN VARCHAR DEFAULT pk_nnn_constant.g_req_status_filter_any
    ) RETURN ts_nnn_epis_lnk_dg_intrv.nnn_epis_lnk_dg_intrv_tc;

    /**
    * Gets all the Linkages active between the Diagnosis and Intervention for a set of  Diagnosis.
    *  
    * @param    i_lst_nnn_epis_diag Collection of Episode Diagnosis ID
    *
    * @return   Collection of linkages Interventions 
    *
    * @author   CRISTINA.OLIVEIRA
    * @version  2.6.4.3 
    * @since    18/11/2013 
    */
    FUNCTION get_lnk_dg_intrv_by_diags
    (
        i_lst_nnn_epis_diag IN table_number,
        i_fltr_status       IN VARCHAR DEFAULT pk_nnn_constant.g_req_status_filter_any
    ) RETURN ts_nnn_epis_lnk_dg_intrv.nnn_epis_lnk_dg_intrv_tc;

    /**
    * Gets all the linkages active between the Diagnosis and Intervention for one Indicator.
    *  
    * @param    id_nnn_epis_intervention Episode Intervention ID
    *
    * @return   Collection of linkages Interventions 
    *
    * @author   CRISTINA.OLIVEIRA
    * @version  2.6.4.3 
    * @since    18/11/2013 
    */
    FUNCTION get_lnk_dg_intrv_by_intrv
    (
        i_nnn_epis_intervention IN nnn_epis_lnk_dg_intrv.id_nnn_epis_intervention%TYPE,
        i_fltr_status           IN VARCHAR DEFAULT pk_nnn_constant.g_req_status_filter_any
    ) RETURN ts_nnn_epis_lnk_dg_intrv.nnn_epis_lnk_dg_intrv_tc;

    /**
    * Gets all the linkages active between the Intervention and the Activities for one Intervention.
    *  
    * @param    i_nnn_epis_intervention Episode Intervention ID
    *
    * @return   Collection of linkages Activities 
    *
    * @author   CRISTINA.OLIVEIRA
    * @version  2.6.4.3 
    * @since    18/11/2013 
    */

    FUNCTION get_lnk_int_actv_by_intrv
    (
        i_nnn_epis_intervention IN nnn_epis_lnk_int_actv.id_nnn_epis_intervention%TYPE,
        i_fltr_status           IN VARCHAR DEFAULT pk_nnn_constant.g_req_status_filter_any
    ) RETURN ts_nnn_epis_lnk_int_actv.nnn_epis_lnk_int_actv_tc;

    /**
    * Gets all the linkages active between the Intervention and the Activities for one Activity.
    *  
    * @param    id_nnn_epis_activity Episode Activity ID
    *
    * @return   Collection of linkages Activities 
    *
    * @author   CRISTINA.OLIVEIRA
    * @version  2.6.4.3 
    * @since    18/11/2013 
    */
    FUNCTION get_lnk_int_actv_by_actv
    (
        i_nnn_epis_activity IN nnn_epis_lnk_int_actv.id_nnn_epis_activity%TYPE,
        i_fltr_status       IN VARCHAR DEFAULT pk_nnn_constant.g_req_status_filter_any
    ) RETURN ts_nnn_epis_lnk_int_actv.nnn_epis_lnk_int_actv_tc;

    /**
    * Cancels a NANDA diagnosis to a patient nursing care plan (nnn_epis_diagnosis).
    *
    * @param    i_lang                  Professional preferred language     
    * @param    i_prof                  Professional identification and its context (institution and software)
    * @param    i_lst_epis_diag         Collection of diagnoses identifiers that we want to cancel
    * @param    i_cancel_reason         Cancellation reason identifier.
    * @param    i_cancel_notes          Notes describing the reason of the cancellation.
    * @param    i_timestamp             Timestamp that should be used across all the functions invoked from this one. Default or NULL to use current_timestamp          
    *
    * @author   CRISTINA.OLIVEIRA
    * @version  2.6.4.3 
    * @since    14/11/2013 
    */
    PROCEDURE cancel_epis_nan_diagnosis
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_nnn_epis_diagnosis IN nnn_epis_diagnosis.id_nnn_epis_diagnosis%TYPE,
        i_cancel_reason      IN nnn_epis_diagnosis.id_cancel_reason%TYPE,
        i_cancel_notes       IN nnn_epis_diagnosis.cancel_notes%TYPE DEFAULT NULL,
        i_timestamp          IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    );

    /**
    * Returns the necessary information on all evaluation of a NOC Outcome.
    *    
    * @param    i_nnn_epis_outcome     Careplan's NOC Outcome ID
    * @param    i_fltr_status          A sequence of flags representing the status that records must comply. Default: Any
    *
    * @return   Collection of the evaluations of the selected Outcome
    *    
    * @author  CRISTINA.OLIVEIRA
    * @version  2.6.4.3
    * @since   14/11/2013
    */
    FUNCTION get_epis_noc_outcome_evals
    (
        i_nnn_epis_outcome IN nnn_epis_outcome_eval.id_nnn_epis_outcome%TYPE,
        i_fltr_status      IN VARCHAR DEFAULT pk_nnn_constant.g_req_status_filter_any
    ) RETURN ts_nnn_epis_outcome_eval.nnn_epis_outcome_eval_tc;

    /**
    * Cancels evaluations associated a one Outcome (nnn_epis_outcome_eval).
    *
    * @param    i_lang                  Professional preferred language     
    * @param    i_prof                  Professional identification and its context (institution and software)
    * @param    i_nnn_epis_outcome      Careplan's NOC Outcome ID
    * @param    i_cancel_reason         Cancellation reason identifier.
    * @param    i_cancel_notes          Notes describing the reason of the cancellation.
    * @param    i_timestamp             Timestamp that should be used across all the functions invoked from this one. Default or NULL to use current_timestamp     
    *
    * @author   CRISTINA.OLIVEIRA
    * @version  2.6.4.3 
    * @since    14/11/2013 
    */
    PROCEDURE cancel_epis_noc_outcome_evals
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_nnn_epis_outcome IN nnn_epis_outcome_eval.id_nnn_epis_outcome%TYPE,
        i_cancel_reason    IN nnn_epis_outcome_eval.id_cancel_reason%TYPE,
        i_cancel_notes     IN nnn_epis_outcome_eval.cancel_notes%TYPE DEFAULT NULL,
        i_timestamp        IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    );

    /**
    * Returns the necessary information on all evaluation of a Indicator.
    *    
    * @param    i_nnn_epis_indicator   Episode Indicator ID 
    * @param    i_fltr_status          A sequence of flags representing the status that records must comply. Default: Any     
    *
    * @return   Collection of the evaluations of the selected Indicator
    *    
    * @author  CRISTINA.OLIVEIRA
    * @version  2.6.4.3
    * @since   14/11/2013
    */
    FUNCTION get_epis_noc_ind_evals
    (
        i_nnn_epis_indicator IN nnn_epis_ind_eval.id_nnn_epis_indicator%TYPE,
        i_fltr_status        IN VARCHAR DEFAULT pk_nnn_constant.g_req_status_filter_any
    ) RETURN ts_nnn_epis_ind_eval.nnn_epis_ind_eval_tc;

    /**
    * Cancels evaluations associated a one Indicator (nnn_epis_ind_eval).
    *
    * @param    i_lang                  Professional preferred language     
    * @param    i_prof                  Professional identification and its context (institution and software)
    * @param    i_nnn_epis_indicator    ID Episode Indicator
    * @param    i_cancel_reason         Cancellation reason identifier.
    * @param    i_cancel_notes          Notes describing the reason of the cancellation.
    * @param    i_timestamp             Timestamp that should be used across all the functions invoked from this one. Default or NULL to use current_timestamp          
    *
    * @author   CRISTINA.OLIVEIRA
    * @version  2.6.4.3 
    * @since    14/11/2013 
    */
    PROCEDURE cancel_epis_noc_ind_evals
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_nnn_epis_indicator IN nnn_epis_ind_eval.id_nnn_epis_indicator%TYPE,
        i_cancel_reason      IN nnn_epis_ind_eval.id_cancel_reason%TYPE,
        i_cancel_notes       IN nnn_epis_ind_eval.cancel_notes%TYPE DEFAULT NULL,
        i_timestamp          IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
        
    );

    /**
    * Gets the information about the diagnoses linked to interventions.
    *  
    * @param    i_lang                         Professional preferred language
    * @param    i_prof                         Professional identification and its context (institution and software)
    * @param    i_lst_nnn_epis_intervention    Collection of Interventions
    * @param    o_interventions                Collection of interventions selected
    * @param    o_diagnoses                    Collection of linked diagnoses 
    *
    * @author   CRISTINA.OLIVEIRA
    * @version  2.6.4.3 
    * @since    21/11/2013 
    */
    PROCEDURE get_epis_diag_intrv_by_intrvs
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_lst_nnn_epis_intervention IN table_number,
        o_interventions             OUT pk_types.cursor_type,
        o_diagnoses                 OUT pk_types.cursor_type
    );

    /**
    * Gets the information about the interventions linked to activities.
    *  
    * @param    i_lang                  Professional preferred language
    * @param    i_prof                  Professional identification and its context (institution and software)
    * @param    i_lst_nnn_epis_activity Collection of Activities
    * @param    o_activities            Collection of activities selected 
    * @param    o_interventions         Collection of linked interventions selected
    *
    * @author   CRISTINA.OLIVEIRA
    * @version  2.6.4.3 
    * @since    21/11/2013 
    */
    PROCEDURE get_epis_intrv_actv_by_actvs
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_lst_nnn_epis_activity IN table_number,
        o_activities            OUT pk_types.cursor_type,
        o_interventions         OUT pk_types.cursor_type
    );

    /**
    * Gets the information about the diagnoses linked to outcomes.
    *  
    * @param    i_lang                 Professional preferred language
    * @param    i_prof                 Professional identification and its context (institution and software)
    * @param    i_lst_nnn_epis_outcome Collection of outcomes
    * @param    o_outcomes             Collection of Outcomes selected
    * @param    o_diagnoses            Collection of linked diagnoses 
    *
    * @author   CRISTINA.OLIVEIRA
    * @version  2.6.4.3 
    * @since    21/11/2013 
    */
    PROCEDURE get_epis_diag_outc_by_outcs
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_lst_nnn_epis_outcome IN table_number,
        o_outcomes             OUT pk_types.cursor_type,
        o_diagnoses            OUT pk_types.cursor_type
    );

    /**
    * Gets the information about the outcomes linked to indicators.
    *  
    * @param    i_lang                   Professional preferred language
    * @param    i_prof                   Professional identification and its context (institution and software)    
    * @param    i_lst_nnn_epis_indicator Collections of Indicators
    * @param    o_indicators             Collection of Indicators selected
    * @param    o_outcomes               Collection of linked outcomes 
    *
    * @author   CRISTINA.OLIVEIRA
    * @version  2.6.4.3 
    * @since    21/11/2013 
    */
    PROCEDURE get_epis_outc_ind_by_inds
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_lst_nnn_epis_indicator IN table_number,
        o_indicators             OUT pk_types.cursor_type,
        o_outcomes               OUT pk_types.cursor_type
    );

    /**
    * Creates or updates a NOC Nursing Indicator in a patient's nursing care plan.
    *
    * @param    i_lang                         Professional preferred language
    * @param    i_prof                         Professional identification and its context (institution and software)
    * @param    i_patient                      Patient ID 
    * @param    i_episode                      Episode ID 
    * @param    i_noc_indicator                NOC Indicator ID
    * @param    i_nnn_epis_indicator           Careplan's NOC Indicator ID. Declared to update an existing nursing indicator or NULL to create a new one         
    * @param    i_episode_origin               Episode ID where the activity was registered 
    * @param    i_episode_destination          Episode ID where the activity is going to be performed
    * @param    i_flg_prn                      Flag that indicates wether the Outcome is PRN or not
    * @param    i_notes_prn                    Notes to indicate when a PRN order should be activated
    * @param    i_flg_time                     Execution time to evaluate the outcome: In current (E)pisode, (B)etween episodes, (N)ext episode. 
    * @param    i_flg_priority                 Flag that indicates the priority of an Outcome: (N)ormal, (U)rgent, (E)mergent
    * @param    i_order_recurr_plan            Order recurrence plan ID for defined frequency in the instructions
    * @param    i_flg_req_status               Request status
    * @param    i_timestamp                    Timestamp that should be used across all the functions invoked from this one. Default or NULL to use current_timestamp    
    *
    * @return   Careplan's NOC Indicator ID
    *
    * @author  CRISTINA.OLIVEIRA
    * @version  2.6.4.3
    * @since   22/08/2013    
    */
    FUNCTION set_epis_noc_indicator
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_patient             IN nnn_epis_indicator.id_patient%TYPE,
        i_episode             IN nnn_epis_indicator.id_episode%TYPE,
        i_noc_indicator       IN nnn_epis_indicator.id_noc_indicator%TYPE,
        i_nnn_epis_indicator  IN nnn_epis_indicator.id_nnn_epis_indicator%TYPE DEFAULT NULL,
        i_episode_origin      IN nnn_epis_indicator.id_episode_origin%TYPE DEFAULT NULL,
        i_episode_destination IN nnn_epis_indicator.id_episode_destination%TYPE DEFAULT NULL,
        i_flg_prn             IN nnn_epis_indicator.flg_prn%TYPE DEFAULT pk_alert_constant.g_no,
        i_notes_prn           IN CLOB DEFAULT NULL,
        i_flg_time            IN nnn_epis_indicator.flg_time%TYPE DEFAULT pk_nnn_constant.g_time_performed_episode,
        i_flg_priority        IN nnn_epis_indicator.flg_priority%TYPE DEFAULT pk_nnn_constant.g_priority_normal,
        i_order_recurr_plan   IN nnn_epis_indicator.id_order_recurr_plan%TYPE DEFAULT NULL,
        i_flg_req_status      IN nnn_epis_indicator.flg_req_status%TYPE DEFAULT pk_nnn_constant.g_req_status_ordered,
        i_timestamp           IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) RETURN nnn_epis_indicator.id_nnn_epis_indicator%TYPE;

    /**
    * Creates or updates an evaluation of NOC Indicator in a patient's nursing care plan.
    *
    * @param    i_lang                  Professional preferred language
    * @param    i_prof                  Professional identification and its context (institution and software)
    * @param    i_patient               Patient ID
    * @param    i_episode               Episode ID
    * @param    i_nnn_epis_indicator    Careplan's NOC Indicator ID 
    * @param    i_nnn_epis_ind_eval     Careplan's NOC Indicator Evaluation ID. Declared to update an existing evaluation or NULL to create a new one
    * @param    i_dt_evaluation         Evaluation date 
    * @param    i_target_value          Indicator Target rating: Likert scale (1 to 5)
    * @param    i_indicator_value       Indicator overall rating: Likert scale (1 to 5)
    * @param    i_notes                 Notes
    * @param    i_dt_plan               Planned date for the indicator evaluation
    * @param    i_order_recurr_plan     Order recurrence plan ID for defined frequency in the instructions
    * @param    i_exec_number           The order of the execution within the plan as specified by the recurrence mechanism
        
    * @param    i_flg_status            Evaluation status        
    * @param    i_timestamp             Timestamp that should be used across all the functions invoked from this one. Default or NULL to use current_timestamp    
    *
    * @return   Careplan's NOC Indicator Evaluation ID
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    12/13/2013
    */
    FUNCTION set_epis_noc_indicator_eval
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN nnn_epis_ind_eval.id_patient%TYPE,
        i_episode            IN nnn_epis_ind_eval.id_episode%TYPE,
        i_nnn_epis_indicator IN nnn_epis_ind_eval.id_nnn_epis_indicator%TYPE,
        i_nnn_epis_ind_eval  IN nnn_epis_ind_eval.id_nnn_epis_ind_eval%TYPE DEFAULT NULL,
        i_dt_evaluation      IN nnn_epis_ind_eval.dt_evaluation%TYPE,
        i_target_value       IN nnn_epis_ind_eval.target_value%TYPE,
        i_indicator_value    IN nnn_epis_ind_eval.indicator_value%TYPE,
        i_notes              IN CLOB DEFAULT NULL,
        i_dt_plan            IN nnn_epis_ind_eval.dt_plan%TYPE DEFAULT NULL,
        i_order_recurr_plan  IN nnn_epis_ind_eval.id_order_recurr_plan%TYPE DEFAULT NULL,
        i_exec_number        IN nnn_epis_ind_eval.exec_number%TYPE DEFAULT NULL,
        i_flg_status         IN nnn_epis_ind_eval.flg_status%TYPE DEFAULT pk_nnn_constant.g_task_status_finished,
        i_timestamp          IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) RETURN nnn_epis_ind_eval.id_nnn_epis_ind_eval%TYPE;

    /**
    * Checks if at least one planned evaluation of a given NOC Indicator was performed.
    *
    * @param    i_nnn_epis_indicator  Careplan's NOC Indicator ID
    *
    * @return   True if at least one planned evaluation was performed, false otherwise.
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    4/28/2014
    */
    FUNCTION get_ind_has_evals(i_nnn_epis_indicator IN nnn_epis_indicator.id_nnn_epis_indicator%TYPE) RETURN BOOLEAN;

    /**
    * Gets the new Indicator status according with the finite state machine (FSM) that represent the allowable states 
    * and transitions for a NOC Indicator in a care plan.
    * The outcome status must be updated whenever an action is performed by the user. 
    * Each tansition has an identifier that is also used in the state diagram.
    * 
    * @param    i_lang                Professional preferred language
    * @param    i_prof                Professional identification and its context (institution and software)
    * @param    i_nnn_epis_indicator  Careplan's NOC Indicator ID whose status we want to update.
    * @param    i_flg_req_status      The status of the NOC Indicator
    * @param    i_action              An action performed by the user that caused the status change
    * 
    * @return   The new status.
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    4/28/2014
    */
    FUNCTION get_fsm_indicator_status
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_nnn_epis_indicator IN nnn_epis_indicator.id_nnn_epis_indicator%TYPE,
        i_flg_req_status     IN nnn_epis_indicator.flg_req_status%TYPE,
        i_action             IN action.internal_name%TYPE
    ) RETURN nnn_epis_indicator.flg_req_status%TYPE;

    /**
    * Updates the status of NOC Indicator and the ending valid time in case the new state is a final state.
    * The update occurs only if the Indicator is not currently in a final state and the new state is different from current one.
    * 
    * @param    i_lang                Professional preferred language
    * @param    i_prof                Professional identification and its context (institution and software)
    * @param    i_nnn_epis_indicator  Careplan's NOC Indicator ID whose status we want to update
    * @param    i_flg_req_status      The new status of the NOC Indicator
    * @param    i_timestamp           Timestamp that should be used across all the functions invoked from this one. Default or NULL to use current_timestamp
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    4/24/2014
    */
    PROCEDURE upd_noc_indicator_status
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_nnn_epis_indicator IN nnn_epis_indicator.id_nnn_epis_indicator%TYPE,
        i_flg_req_status     IN nnn_epis_indicator.flg_req_status%TYPE,
        i_timestamp          IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    );
    /**
    * Establishes the links between a set of NANDA Diagnoses and a set of NIC Interventions when the i_flg_lnk_status is 'A'
    * or cancels the links between a set of NANDA Diagnoses and a set of NIC Interventions when the i_flg_lnk_status is 'C'.
    * 
    *
    * @param    i_prof                         Professional identification and its context (institution and software)
    * @param    i_episode                      Episode ID 
    * @param    i_lst_nnn_epis_diagnosis       Collection of diagnoses
    * @param    i_lst_nnn_epis_intervention    Collection of interventions
    * @param    i_flg_lnk_status               Link status: (A)ctive, (C)ancelled
    *
    * @author  CRISTINA.OLIVEIRA
    * @version  2.6.4.3
    * @since   21/11/2013    
    */
    PROCEDURE set_lnk_diagnosis_intervention
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_episode                   IN nnn_epis_lnk_dg_intrv.id_episode%TYPE,
        i_lst_nnn_epis_diagnosis    IN table_number,
        i_lst_nnn_epis_intervention IN table_number,
        i_flg_lnk_status            IN nnn_epis_lnk_dg_intrv.flg_lnk_status%TYPE DEFAULT pk_alert_constant.g_active,
        i_timestamp                 IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    );

    /**
    * Establishes the links between a set of NIC Interventions and a set of NIC Actities when the i_flg_lnk_status is 'A'
    * Or cancels the links between a set of NIC Interventions and a set of NIC Actities when the i_flg_lnk_status is 'C'
    * 
    *
    * @param    i_prof                         Professional identification and its context (institution and software)
    * @param    i_episode                      Episode ID 
    * @param    i_lst_nnn_epis_intervention    Collection of interventions
    * @param    i_lst_nnn_epis_activity        Collection of activities
    * @param    i_flg_lnk_status               Link status: (A)ctive, (C)ancelled
    * @param    i_timestamp                    Timestamp that should be used across all the functions invoked from this one. Default or NULL to use current_timestamp    
    *
    * @author  CRISTINA.OLIVEIRA
    * @version  2.6.4.3
    * @since   21/11/2013    
    */
    PROCEDURE set_lnk_intervention_activity
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_episode                   IN nnn_epis_lnk_dg_intrv.id_episode%TYPE,
        i_lst_nnn_epis_intervention IN table_number,
        i_lst_nnn_epis_activity     IN table_number,
        i_flg_lnk_status            IN nnn_epis_lnk_int_actv.flg_lnk_status%TYPE DEFAULT pk_alert_constant.g_active,
        i_timestamp                 IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    );

    /**
    * Establishes the links between a set of NANDA Diagnoses and a set of NOC Outcomes when the i_flg_lnk_status is 'A'
    * or cancels the links between a set of NANDA Diagnoses and a set of NOC Outcomes when the i_flg_lnk_status is 'C'
    * 
    *
    * @param    i_prof                         Professional identification and its context (institution and software)
    * @param    i_episode                      Episode ID 
    * @param    i_lst_nnn_epis_diagnosis       Collection of diagnoses
    * @param    i_lst_nnn_epis_outcome         Collection of outcomes
    * @param    i_flg_lnk_status               Link status: (A)ctive, (C)ancelled
    * @param    i_timestamp                    Timestamp that should be used across all the functions invoked from this one. Default or NULL to use current_timestamp    
    *
    * @author  CRISTINA.OLIVEIRA
    * @version  2.6.4.3
    * @since   21/11/2013    
    */
    PROCEDURE set_lnk_diagnosis_outcome
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN nnn_epis_lnk_dg_intrv.id_episode%TYPE,
        i_lst_nnn_epis_diagnosis IN table_number,
        i_lst_nnn_epis_outcome   IN table_number,
        i_flg_lnk_status         IN nnn_epis_lnk_dg_outc.flg_lnk_status%TYPE DEFAULT pk_alert_constant.g_active,
        i_timestamp              IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    );

    /**
    * Establishes the links between a set of NOC Outcomes and a set of NOC Indicators when the i_flg_lnk_status is 'A'
    * or cancels the links between a set of NOC Outcomes and a set of NOC Indicators when the i_flg_lnk_status is 'C'.
    * 
    *
    * @param    i_prof                         Professional identification and its context (institution and software)
    * @param    i_episode                      Episode ID 
    * @param    i_lst_nnn_epis_outcome         Collection of outcomes
    * @param    i_lst_nnn_epis_indicator       Collection of indicators
    * @param    i_flg_lnk_status               Link status: (A)ctive, (C)ancelled
    * @param    i_timestamp                    Timestamp that should be used across all the functions invoked from this one. Default or NULL to use current_timestamp
    *
    * @author  CRISTINA.OLIVEIRA
    * @version  2.6.4.3
    * @since   21/11/2013    
    */
    PROCEDURE set_lnk_outcome_indicator
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN nnn_epis_lnk_dg_intrv.id_episode%TYPE,
        i_lst_nnn_epis_outcome   IN table_number,
        i_lst_nnn_epis_indicator IN table_number,
        i_flg_lnk_status         IN nnn_epis_lnk_outc_ind.flg_lnk_status%TYPE DEFAULT pk_alert_constant.g_active,
        i_timestamp              IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    );

    /**
    * Check if a NIC Activity already exists for the same diagnosis and intervention.
    *
    * @param    i_patient                    Patient ID
    * @param    i_episode                    Episode ID
    * @param    i_nan_diagnosis              NANDA diagnosis ID
    * @param    i_nic_intervention           NIC intervention ID
    * @param    i_nic_activity               NIC activity ID
    *
    * @return  True if the NIC Activitie is already defined in the same diagnosis and intervention
    *
    * @author  CRISTINA.OLIVEIRA
    * @version  2.6.4.3
    * @since   25/11/2013
    */
    FUNCTION check_epis_nic_activity
    (
        i_patient          IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_nan_diagnosis    IN nnn_epis_diagnosis.id_nan_diagnosis%TYPE,
        i_nic_intervention IN nnn_epis_intervention.id_nic_intervention%TYPE,
        i_nic_activity     IN nnn_epis_activity.id_nic_activity%TYPE
    ) RETURN BOOLEAN;

    /**
    * Check if a NOC Indicator already exists for the same diagnosis and outcome.
    *
    * @param    i_patient                 Patient ID
    * @param    i_episode                 Episode ID
    * @param    i_nan_diagnosis           NANDA diagnosis ID
    * @param    i_noc_outcome             NOC outcome ID
    * @param    i_noc_indicator           NOC indicator ID
    *
    * @return  True if the NOC Indicator is already defined in the same diagnosis and outcome
    *
    * @author  CRISTINA.OLIVEIRA
    * @version  2.6.4.3
    * @since   25/11/2013
    */
    FUNCTION check_epis_noc_indicator
    (
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_nan_diagnosis IN nnn_epis_diagnosis.id_nan_diagnosis%TYPE,
        i_noc_outcome   IN nnn_epis_outcome.id_noc_outcome%TYPE,
        i_noc_indicator IN nnn_epis_indicator.id_noc_indicator%TYPE
    ) RETURN BOOLEAN;

    /**
    * Gets list of available actions, from a given state. When specifying more than one state,
    * it groups the actions, according to their availability. This enables support
    * for "bulk" state changes.
    *
    * @param    i_lang              Professional preferred language
    * @param    i_prof              Professional identification and its context (institution and software)
    * @param    i_subject           Action subject
    * @param    i_lst_from_state    List of selected states
    * @param    i_lst_entries       List of selected entries
    * @param    o_actions           Cursor with a list of available actions
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   12/18/2013
    */
    PROCEDURE get_actions_permissions
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_subject        IN action.subject%TYPE,
        i_lst_from_state IN table_varchar,
        i_lst_entries    IN table_number,
        o_actions        OUT pk_types.cursor_type
    );

    /**
    * Gets the list of available actions for the Staging Area acording with the selected item.
    * This procedures evaluates whether the "Link" action should be active or not in accordance with the selected item 
    * and if there are potential linkable items in the staging area.
    *
    * @param    i_lang              Professional preferred language
    * @param    i_prof              Professional identification and its context (institution and software)
    * @param    i_subject           Action subject
    * @param    i_staging_data      JSON Document(plain text) with the information of the selected item and the others what are in the staging area
    * @param    o_actions           Cursor with a list of available actions
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   2/17/2014
    */
    PROCEDURE get_actions_staging_area
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_subject      IN action.subject%TYPE,
        i_staging_data IN CLOB,
        o_actions      OUT pk_types.cursor_type
    );

    /**
    * Gets the list of available actions for the "Add button"(+) of the Patient Care Plan.
    *
    * @param    i_lang              Professional preferred language
    * @param    i_prof              Professional identification and its context (institution and software)
    * @param    o_actions           Cursor with a list of available actions
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   4/2/2014
    */
    PROCEDURE get_actions_add_button
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_actions OUT pk_types.cursor_type
    );

    /**
    * Checks if a given action is active or not for an entry and its state.
    *
    * @param    i_lang              Professional preferred language
    * @param    i_prof              Professional identification and its context (institution and software)
    * @param    i_subject           Action subject
    * @param    i_status            entry's status
    * @param    i_check             Action to perform
    *
    * @return   Action status
    *
    * @value    return        {*}'Y' Action is active {*}'N' Action is inactive or not defined    *
    * @return  'Y' or 'N'
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   3/19/2014
    */
    FUNCTION check_permissions
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_subject IN action.subject%TYPE,
        i_status  IN action.from_state%TYPE,
        i_check   IN action.internal_name%TYPE
    ) RETURN VARCHAR2;

    /**
    * Returns the filter options for list NIC Interventions when we want to add them to a nursing care plan.
    *
    * There are two ways for list NIC Interventions:
    *    - Using as input a NANDA Diagnosis, thereby listing the Interventions associated with it (NANDA/NIC Linkages)
    *    - Using as input a NOC Outcome, in turn, is linked to a NANDA Diagnosis, thereby listing the Interventions associated with this tuple (NANDA/NOC/NIC Linkages) 
    * This procedure returns these options evaluating if the nursing care plan already has NOC Outcomes in order to displays the second one as active.
    *   
    * @param    i_lang              Professional preferred language
    * @param    i_prof              Professional identification and its context (institution and software)
    * @param    i_patient           Patient ID
    * @param    i_scope             Scope ID (Episode ID; Visit ID; Patient ID)
    * @param    i_scope_type        Scope type (by episode; by visit; by patient)
    * @param    o_diagnosis         Cursor with list of Nursing Diagnoses    
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   6/13/2014
    */
    PROCEDURE get_nic_filter_dropdown
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_scope      IN NUMBER,
        i_scope_type IN VARCHAR2 DEFAULT pk_alert_constant.g_scope_type_episode,
        o_dropdown   OUT pk_types.cursor_type
    );

    /**
    * Gets a brief summary of an evaluation of a NANDA Diagnosis.
    *
    * @param    i_lang                     Professional preferred language
    * @param    i_prof                     Professional identification and its context (institution and software)
    * @param    i_nnn_epis_diag_eval       Careplan's NANDA Diagnosis Evaluation ID. 
    * @param    i_use_html_format          Use HTML tags to format output. Default: No
    * @param    o_entries                  Cursor with 
    *
    * @value    i_use_html_format          {*} 'Y'  Use HTML tags {*} 'N'  No HTML tags
    *
    * @return   Descriptive abstract of a NANDA Diagnosis evaluation in plain text format
    *    
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   01/30/2014
    */
    FUNCTION get_epis_diag_eval_abstract
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_nnn_epis_diag_eval IN nnn_epis_diag_eval.id_nnn_epis_diag_eval%TYPE,
        i_use_html_format    IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN CLOB;

    /**
    * Gets a brief summary of an evaluation of a NOC Outcome.
    *
    * @param    i_lang                     Professional preferred language
    * @param    i_prof                     Professional identification and its context (institution and software)
    * @param    i_nnn_epis_outcome_eval    Careplan's NOC Outcome Evaluation ID. 
    * @param    i_use_html_format          Use HTML tags to format output. Default: No
    * @param    o_entries                  Cursor with 
    *
    * @value    i_use_html_format           {*} 'Y'  Use HTML tags {*} 'N'  No HTML tags
    *
    * @return   Descriptive abstract of a NOC Outcome evaluation in plain text format
    *    
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   01/30/2014
    */
    FUNCTION get_epis_outcome_eval_abstract
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_nnn_epis_outcome_eval IN nnn_epis_outcome_eval.id_nnn_epis_outcome_eval%TYPE,
        i_use_html_format       IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN CLOB;

    /**
    * Gets a brief summary of an evaluation of a NOC Indicator.
    *
    * @param    i_lang                     Professional preferred language
    * @param    i_prof                     Professional identification and its context (institution and software)
    * @param    i_nnn_epis_outcome         Associated Careplan's Outcome ID
    * @param    i_nnn_epis_ind_eval        Careplan's NOC Inicator Evaluation ID
    * @param    i_use_html_format          Use HTML tags to format output. Default: No
    * @param    o_entries                  Cursor with 
    *
    * @value    i_use_html_format           {*} 'Y'  Use HTML tags {*} 'N'  No HTML tags
    *
    * @return   Descriptive abstract of a NOC Outcome evaluation in plain text format
    *    
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   01/30/2014
    */
    FUNCTION get_epis_ind_eval_abstract
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_nnn_epis_outcome  IN nnn_epis_outcome.id_nnn_epis_outcome%TYPE,
        i_nnn_epis_ind_eval IN nnn_epis_ind_eval.id_nnn_epis_ind_eval%TYPE,
        i_use_html_format   IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN CLOB;

    /**
    * Gets a brief summary of an execution of a NIC Activity.
    *
    * @param    i_lang                     Professional preferred language
    * @param    i_prof                     Professional identification and its context (institution and software)
    * @param    i_nnn_epis_activity_det    Careplan's NOC Inicator Evaluation ID
    * @param    i_use_html_format          Use HTML tags to format output. Default: No
    * @param    o_entries                  Cursor with 
    *
    * @value    i_use_html_format           {*} 'Y'  Use HTML tags {*} 'N'  No HTML tags
    *
    * @return   Descriptive abstract of a NIC Activity execution in plain text format
    *    
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   10/30/2014
    */
    FUNCTION get_epis_actv_exec_abstract
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_nnn_epis_activity_det IN nnn_epis_activity_det.id_nnn_epis_activity_det%TYPE,
        i_use_html_format       IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN CLOB;

    /**
    * Checks if goals were achieved for NOC outcomes/indicators that are associated with a NANDA Diagnosis.
    *
    * @param    i_lang                  Professional preferred language
    * @param    i_prof                  Professional identification and its context (institution and software)    
    * @param    i_nnn_epis_diagnosis    Careplan's NANDA Diagnosis ID
    * @param    o_flg_goals_archieved   Returns 'N' if at least one goal was not achieved
    * @param    o_goals_status          Cursor with information about expected outcomes and current evaluation
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    2/10/2014
    */
    PROCEDURE check_outcome_goals_achieved
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_nnn_epis_diagnosis  IN nnn_epis_diagnosis.id_nnn_epis_diagnosis%TYPE,
        o_flg_goals_archieved OUT VARCHAR2,
        o_goals_status        OUT pk_types.cursor_type
    );

    /*
    * Build status string. 
    *
    * @param i_lang           Professional preferred language
    * @param i_prof           Professional identification and its context (institution and software)
    * @param i_flg_type       Type (g_type_outcome, g_type_outcome_eval)
    * @param i_flg_prn        Flag that indicates wether the Outcome is PRN or not    
    * @param i_flg_status     Request status
    * @param i_flg_time       Execution time to evaluate the outcome: In current (E)pisode, (B)etween episodes, (N)ext episode.
    * @param i_dt_plan        Planned date for the type 
    * @param i_shortcut       Shortcut ID
    * @param i_timestamp      Timestamp that should be used across all the functions invoked from this one. Default or NULL to use current_timestamp
    * 
    * @return                 status string
    *
    * @author                 CRISTINA.OLIVEIRA
    * @version  2.6.4.3                
    * @since                  2014/04/01
    */
    FUNCTION get_status_str
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_flg_type   IN VARCHAR,
        i_flg_prn    IN VARCHAR,
        i_flg_status IN VARCHAR,
        i_flg_time   IN VARCHAR,
        i_dt_plan    IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_shortcut   IN sys_shortcut.id_sys_shortcut%TYPE DEFAULT NULL,
        i_timestamp  IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) RETURN VARCHAR2;

    /**
    * Gets the next evaluation of a NOC Outcome in a patient's nursing care plan ongoing/required.
    *
    * @param    i_nnn_epis_outcome    Careplan's NOC Outcome ID
    *
    * @return   A nnn_epis_outcome_eval_ntt collection (nnn_epis_outcome_eval%ROWTYPE) with one row corresponding to the next evaluation
    *
    * @author   CRISTINA.OLIVEIRA
    * @version  2.6.4.3
    * @since    2014/04/01
    */
    FUNCTION tf_next_nnn_epis_outc_eval(i_nnn_epis_outcome IN nnn_epis_outcome_eval.id_nnn_epis_outcome%TYPE)
        RETURN ts_nnn_epis_outcome_eval.nnn_epis_outcome_eval_ntt
        PIPELINED;

    /**
    * Gets the next evaluation of a NOC Indicator in a patient's nursing care plan ongoing/required.
    *
    * @param    i_nnn_epis_indicator    Careplan's NOC Indicator ID
    *
    * @return   A nnn_epis_ind_eval_ntt collection (nnn_epis_ind_eval%ROWTYPE) with one row corresponding to the next evaluation
    *
    * @author   CRISTINA.OLIVEIRA
    * @version  2.6.4.3
    * @since    2014/04/01
    */
    FUNCTION tf_next_nnn_epis_ind_eval(i_nnn_epis_indicator IN nnn_epis_ind_eval.id_nnn_epis_indicator%TYPE)
        RETURN ts_nnn_epis_ind_eval.nnn_epis_ind_eval_ntt
        PIPELINED;

    /**
    * Gets the next evaluation of a NIC Activity in a patient's nursing care plan ongoing/required.
    *
    * @param    i_nnn_epis_activity    Careplan's NIC Activity ID
    *
    * @return   A nnn_epis_activity_det_ntt collection (nnn_epis_activity_det%ROWTYPE) with one row corresponding to the next evaluation
    *
    * @author   CRISTINA.OLIVEIRA
    * @version  2.6.4.3
    * @since    2014/04/01
    */
    FUNCTION tf_next_nnn_epis_activ_det(i_nnn_epis_activity IN nnn_epis_activity_det.id_nnn_epis_activity%TYPE)
        RETURN ts_nnn_epis_activity_det.nnn_epis_activity_det_ntt
        PIPELINED;

    /*
    * Returns a summary about ordered/ongoing Outcomes, Indicators and Activities in the nursing care plan
    *
    * @param    i_lang          Professional preferred language
    * @param    i_prof          Professional identification and its context (institution and software)
    * @param    i_episode       Episode ID
    * @param    i_fltr_status   A sequence of flags representing the type of tasks to return
    * @param    o_epis_nnn      Cursor with summary lists of Nursing care plan ongoing/ordered
    *
    * @value    i_fltr_status {*} pk_nnn_constant.g_type_outcome {*} pk_nnn_constant.g_type_indicator {*} pk_nnn_constant.g_type_activity {*} pk_nnn_constant.g_type_filter_req_any (Default)
    *    
    * @return  True on sucess, false otherwise
    *    
    * @author                CRISTINA.OLIVEIRA
    * @version  2.6.4.3                
    * @since                 2014/04/01
    */
    FUNCTION get_epis_nnn_summary
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        i_fltr_type IN pk_types.t_low_char DEFAULT pk_nnn_constant.g_type_filter_req_any,
        o_epis_nnn  OUT pk_types.cursor_type
    ) RETURN BOOLEAN;

    /*
    * Returns a summary about active/inactive nursing diagnoses in the nursing care plan
    *
    * @param    i_lang          Professional preferred language
    * @param    i_prof          Professional identification and its context (institution and software)
    * @param    i_episode       Episode ID
    * @param    o_diagnosis     Cursor with summary lists of Nursing diagnosis
    *    
    * @return  True on sucess, false otherwise
    *    
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    12/4/2014
    */
    FUNCTION get_epis_nnn_diag_summary
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        o_diagnosis OUT pk_types.cursor_type
    ) RETURN BOOLEAN;

    /*
    * Insert/Update column of the NOC outcome in GRID_TASK table  
    *
    * @param i_lang          Professional preferred language
    * @param i_prof          Professional identification and its context (institution and software)
    * @param i_episode       Episode ID
    *
    * @author                CRISTINA.OLIVEIRA
    * @version  2.6.4.3                
    * @since                 2014/04/03
    */
    PROCEDURE set_tasks_outcome
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    );

    /*
    * Insert/Update column of the NOC indicator in GRID_TASK table  
    *
    * @param i_lang          Professional preferred language
    * @param i_prof          Professional identification and its context (institution and software)
    * @param i_episode       Episode ID
    *
    * @author                CRISTINA.OLIVEIRA
    * @version  2.6.4.3                
    * @since                 2014/04/03
    */
    PROCEDURE set_tasks_indicator
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    );

    /*
    * Insert/Update column of the NIC activity in GRID_TASK table  
    *
    * @param i_lang          Professional preferred language
    * @param i_prof          Professional identification and its context (institution and software)
    * @param i_episode       Episode ID
    *
    * @author                CRISTINA.OLIVEIRA
    * @version  2.6.4.3                
    * @since                 2014/04/03
    */
    PROCEDURE set_tasks_activity
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    );

    /**
    * Translates the option recurrence ID into a flag representing the kind of recurrence category: Once, Not-scheduled, or with Recurrence.
    *
    * @param    i_order_recurr_option   Order recurrence option ID
    *
    * @return   True or False on success or error    
    *
    * @value    return        {*}'O' g_req_freq_once {*}'N' g_req_freq_no_schedule {*}'R' g_req_freq_recurrence
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    4/21/2014
    */
    FUNCTION recurr_option_to_freq_type(i_order_recurr_option IN order_recurr_plan.id_order_recurr_option%TYPE)
        RETURN VARCHAR2;

    /**
    *  Evaluates if the given request status is a final state (also referred to as accepting or acept state).
    *  This method is applicable for Outcomes, Indicators, Interventions and Activities.
    *
    * @param    i_flg_req_status        Request status
    *
    * @return   True if the input value is a final state; False otherwise.
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    4/24/2014
    */
    FUNCTION is_req_final_state(i_flg_req_status IN nnn_epis_activity.flg_req_status%TYPE) RETURN BOOLEAN;

    /**
    *  Evaluates if the given evaluation/execution status is a final state (also referred to as accepting or acept state).
    *  This method is applicable for evaluations of Outcomes/Indicators and executions of Activities.
    *
    * @param    i_flg_status        Evaluation/Execution status
    *
    * @return   True if the input value is a final state; False otherwise.
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    4/24/2014
    */
    FUNCTION is_task_final_state(i_flg_status IN nnn_epis_activity_det.flg_status%TYPE) RETURN BOOLEAN;

    /**
    * Counts the number of planned evaluations associated with a given NOC Outcome.
    * Are considered planned evaluation all of them that were not executed or cancelled.
    *
    * @param    i_nnn_epis_outcome              Careplan's NOC Outcome ID
    *
    * @return   The number of planned evaluations.
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    4/24/2014
    */
    FUNCTION get_outcome_planned_eval_count(i_nnn_epis_outcome IN nnn_epis_outcome.id_nnn_epis_outcome%TYPE)
        RETURN PLS_INTEGER;

    /**
    * Counts the number of planned evaluations associated with a given NOC Indicator.
    * Are considered planned evaluation all of them that were not executed or cancelled.
    *
    * @param    get_ind_planned_eval_count    Careplan's NOC Indicator ID
    *
    * @return   The number of planned evaluations.
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    4/28/2014
    */
    FUNCTION get_ind_planned_eval_count(i_nnn_epis_indicator IN nnn_epis_indicator.id_nnn_epis_indicator%TYPE)
        RETURN PLS_INTEGER;

    /**
    * Counts the number of planned executions associated with a given NIC Activity.
    * Are considered planned executions all of them that were not executed or cancelled.
    *
    * @param    i_nnn_epis_activity              Careplan's NIC Activity ID
    *
    * @return   The number of planned evaluations.
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    5/2/2014
    */
    FUNCTION get_activity_planned_exe_count(i_nnn_epis_activity IN nnn_epis_activity.id_nnn_epis_activity %TYPE)
        RETURN PLS_INTEGER;

    /**
    * Gets the list of defining characteristics documented in a NANDA diagnosis evaluation at that point in time.
    *
    * @param    i_nnn_epis_diag_eval        Careplan's NANDA Diagnosis Evaluation ID
    * @param    i_dt_trs_time_start         Time of the change
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    6/19/2014
    */
    FUNCTION get_epis_nan_diag_defc_h
    (
        i_nnn_epis_diag_eval IN nnn_epis_diag_eval_h.id_nnn_epis_diag_eval%TYPE,
        i_dt_trs_time_start  IN nnn_epis_diag_eval_h.dt_trs_time_start%TYPE
    ) RETURN t_coll_obj_nan_def_chars;

    /**
    * Gets the list of risk factors documented in a NANDA diagnosis evaluation at that point in time.
    *
    * @param    i_nnn_epis_diag_eval        Careplan's NANDA Diagnosis Evaluation ID
    * @param    i_dt_trs_time_start         Time of the change
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    6/19/2014
    */
    FUNCTION get_epis_nan_diag_rskf_h
    (
        i_nnn_epis_diag_eval IN nnn_epis_diag_eval_h.id_nnn_epis_diag_eval%TYPE,
        i_dt_trs_time_start  IN nnn_epis_diag_eval_h.dt_trs_time_start%TYPE
    ) RETURN t_coll_obj_nan_risk_factor;

    /**
    * Gets the list of related factors documented in a NANDA diagnosis evaluation at that point in time.
    *
    * @param    i_nnn_epis_diag_eval        Careplan's NANDA Diagnosis Evaluation ID
    * @param    i_dt_trs_time_start         Time of the change
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    6/19/2014
    */
    FUNCTION get_epis_nan_diag_relf_h
    (
        i_nnn_epis_diag_eval IN nnn_epis_diag_eval_h.id_nnn_epis_diag_eval%TYPE,
        i_dt_trs_time_start  IN nnn_epis_diag_eval_h.dt_trs_time_start%TYPE
    ) RETURN t_coll_obj_nan_related_factor;

    /**
    * Gets the list of activity tasks documented in a NIC activity execution at that point in time.
    *
    * @param    i_nnn_epis_activity_det     Careplan's NIC Activity Execution ID
    * @param    i_dt_trs_time_start         Time of the change
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    10/9/2014
    */
    FUNCTION get_epis_nic_actv_det_task_h
    (
        i_nnn_epis_activity_det IN nnn_epis_actv_det_tskh.id_nnn_epis_activity_det%TYPE,
        i_dt_trs_time_start     IN nnn_epis_actv_det_tskh.dt_trs_time_start%TYPE
    ) RETURN t_coll_obj_nnn_epis_actv_tsk;

    /**
    * Updates the system alert for the due date of next NOC Outcome evaluation.
    *
    * @param    i_lang                  Professional preferred language
    * @param    i_prof                  Professional identification and its context (institution and software)
    * @param    i_episode               Episode ID
    * @param    i_nnn_epis_outcome      Careplan's NOC Outcome ID
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    7/2/2014
    */
    PROCEDURE refresh_outcome_alert
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_nnn_epis_outcome IN nnn_epis_outcome.id_nnn_epis_outcome%TYPE
    );

    /**
    * Updates the system alert for the due date of next NOC Indicator evaluation.
    *
    * @param    i_lang                  Professional preferred language
    * @param    i_prof                  Professional identification and its context (institution and software)
    * @param    i_episode               Episode ID
    * @param    i_nnn_epis_indicator    Careplan's NOC Indicator ID
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    7/3/2014
    */
    PROCEDURE refresh_indicator_alert
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_nnn_epis_indicator IN nnn_epis_indicator.id_nnn_epis_indicator%TYPE
    );

    /**
    * Updates the system alert for the due date of next NIC Activity execution.
    *
    * @param    i_lang                  Professional preferred language
    * @param    i_prof                  Professional identification and its context (institution and software)
    * @param    i_episode               Episode ID
    * @param    i_nnn_epis_activity     Careplan's NIC Activity ID
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    7/3/2014
    */
    PROCEDURE refresh_activity_alert
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_nnn_epis_activity IN nnn_epis_activity.id_nnn_epis_activity%TYPE
    );

    /**
    * Calculates the duration and end date of an execution 
    *
    * @param    i_lang                          Professional preferred language
    * @param    i_prof                          Professional identification and its context (institution and software)
    * @param    i_start_date                    Start date defined by the user
    * @param    i_duration                      Duration defined by the user
    * @param    i_unit_meas_duration            Duration unit measure defined by the user
    * @param    i_end_date                      End date defined by the user
    * @param    o_start_date                    Calculated start date
    * @param    o_duration                      Duration considered in this interval
    * @param    o_unit_meas_duration            Duration unit measure considered in this interval
    * @param    o_end_date                      Calculated end date
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    10/02/2014
    */
    PROCEDURE calculate_duration
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_start_date         IN nnn_epis_activity_det.dt_val_time_start%TYPE,
        i_duration           IN pk_types.t_med_num,
        i_unit_meas_duration IN nic_cfg_activity.id_unit_measure_duration%TYPE,
        i_end_date           IN nnn_epis_activity_det.dt_val_time_end%TYPE,
        o_start_date         OUT nnn_epis_activity_det.dt_val_time_start%TYPE,
        o_duration           OUT pk_types.t_med_num,
        o_duration_desc      OUT pk_types.t_big_byte,
        o_unit_meas_duration OUT nic_cfg_activity.id_unit_measure_duration%TYPE,
        o_end_date           OUT nnn_epis_activity_det.dt_val_time_end%TYPE
    );

    /**
    * Gets the ID of the history tracking table for NIC Activity execution
    *
    * @param    i_nnn_epis_activity_det     Careplan's NIC Activity execution ID
    * @param    i_dt_trs_time_end           Time of the change
    * 
    * @return   ID of entry in the tracking table
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    10/07/2014
    */
    FUNCTION get_id_hist_epis_activity_det
    (
        i_nnn_epis_activity_det IN nnn_epis_activity_det.id_nnn_epis_activity_det%TYPE,
        i_dt_trs_time_end       IN nnn_epis_activity_det_h.dt_trs_time_end%TYPE
    ) RETURN nnn_epis_activity_det_h.id_nnn_epis_activity_det_h%TYPE;

    /**
    * Matches all the information of the two episodes (temporary and definitive).
    *
    * @param    i_lang              Professional preferred language
    * @param    i_prof              Professional identification and its context (institution and software)
    * @param    i_episode_temp      Temporary episode which data will be merged out
    * @param    i_episode           Episode identifier
    * @param    o_error             Error info
    * 
    * @return  True on sucess, false otherwise
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    10/23/2014
    */
    FUNCTION set_match_episode
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode_temp IN episode.id_episode%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Matches all the information of the two patients (temporary and definitive).
    *
    * @param    i_lang              Professional preferred language
    * @param    i_prof              Professional identification and its context (institution and software)
    * @param    i_patient_temp      Temporary patient which data will be merged out
    * @param    i_patient           Patient identifier
    * @param    o_error             Error info
    * 
    * @return  True on sucess, false otherwise
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    10/23/2014
    */
    FUNCTION set_match_patient
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient_temp IN patient.id_patient%TYPE,
        i_patient      IN patient.id_patient%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Changes the id_patient of the i_old_episode and associated visit to the i_new_patient
    *
    * @param    i_lang              Professional preferred language
    * @param    i_prof              Professional identification and its context (institution and software)
    * @param    i_new_patient       New patient ID
    * @param    i_old_episode       Episode ID for which the associated patient will change
    * @param    o_error             Error info
    * 
    * @return  True on sucess, false otherwise
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    10/27/2014
    */
    FUNCTION set_episode_new_patient
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_new_patient IN patient.id_patient%TYPE,
        i_old_episode IN episode.id_episode%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION inactivate_nnn_tasks
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_inst      IN institution.id_institution%TYPE,
        o_has_error OUT BOOLEAN,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

END pk_nnn_core;
/
