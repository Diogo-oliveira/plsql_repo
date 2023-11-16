/*-- Last Change Revision: $Rev: 2005972 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2022-01-20 16:59:36 +0000 (qui, 20 jan 2022) $*/

CREATE OR REPLACE PACKAGE pk_nnn_api_db IS

    -- Author  : ARIEL.MACHADO
    -- Created : 11/11/2013 5:24:32 PM
    -- Purpose : NANDA NIC NOC APIs with business logic

    -- Public type declarations

    -- Public constant declarations

    -- Public variable declarations 

    -- Public function and procedure declarations

    /**
    * Creates a set of NOC Outcome's evaluations. This method is invoked by the 
    * recurrence mechanism to create the evaluations plan.
    *
    * @param    i_lang              Professional preferred language
    * @param    i_prof              Professional identification and its context (institution and software)
    * @param    i_exec_tab          A collection with the execution order number and the planned date of evaluation.
    * @param    i_timestamp         Timestamp that should be used across all the functions invoked from this one. Default or NULL to use current_timestamp
    * @param    o_exec_to_process   For each plan, indicates if there are more evaluations to be processed. 
    * @param    o_error             Error info
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    11/13/2013
    */
    FUNCTION create_outcome_recurrence
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_exec_tab        IN t_tbl_order_recurr_plan,
        i_timestamp       IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp,
        o_exec_to_process OUT t_tbl_order_recurr_plan_sts,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Creates a set of NOC Indicator's evaluations. This method is invoked by the 
    * recurrence mechanism to create the evaluations plan.
    *
    * @param    i_lang              Professional preferred language
    * @param    i_prof              Professional identification and its context (institution and software)
    * @param    i_exec_tab          A collection with the execution order number and the planned date of evaluation.
    * @param    i_timestamp         Timestamp that should be used across all the functions invoked from this one. Default or NULL to use current_timestamp
    * @param    o_exec_to_process   For each plan, indicates if there are more evaluations to be processed. 
    * @param    o_error             Error info
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    11/13/2013
    */
    FUNCTION create_indicator_recurrence
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_exec_tab        IN t_tbl_order_recurr_plan,
        i_timestamp       IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp,
        o_exec_to_process OUT t_tbl_order_recurr_plan_sts,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Creates a set of NIC Activity's executions. This method is invoked by the 
    * recurrence mechanism to create the executions plan.
    *
    * @param    i_lang              Professional preferred language
    * @param    i_prof              Professional identification and its context (institution and software)
    * @param    i_exec_tab          A collection with the execution order number and the planned date of execution.
    * @param    i_timestamp         Timestamp that should be used across all the functions invoked from this one. Default or NULL to use current_timestamp
    * @param    o_exec_to_process   For each plan, indicates if there are more executions to be processed. 
    * @param    o_error             Error info
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    11/13/2013
    */
    FUNCTION create_activity_recurrence
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_exec_tab        IN t_tbl_order_recurr_plan,
        i_timestamp       IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp,
        o_exec_to_process OUT t_tbl_order_recurr_plan_sts,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Creates a next Outcome's evaluation in the plan table when there are more evaluations to be done, 
    * but they are no yet in the plan table.
    *
    * @param    i_lang                 Professional preferred language
    * @param    i_prof                 Professional identification and its context (institution and software)
    * @param    i_nnn_epis_outcome     Careplan's NOC Outcome ID
    * @param    i_order_recurr_plan    Order recurrence plan ID for defined frequency in the instructions                 
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    5/8/2014
    */
    PROCEDURE create_next_outcome_eval
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_nnn_epis_outcome  IN nnn_epis_outcome.id_nnn_epis_outcome%TYPE,
        i_order_recurr_plan IN nnn_epis_indicator.id_order_recurr_plan%TYPE
    );

    /**
    * Creates a next Indicator's evaluation in the plan table when there are more evaluations to be done, 
    * but they are no yet in the plan table.
    *
    * @param    i_lang                 Professional preferred language
    * @param    i_prof                 Professional identification and its context (institution and software)
    * @param    i_nnn_epis_indicator   Careplan's NOC Indicator ID
    * @param    i_order_recurr_plan    Order recurrence plan ID for defined frequency in the instructions                 
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    5/8/2014
    */
    PROCEDURE create_next_indicator_eval
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_nnn_epis_indicator IN nnn_epis_indicator.id_nnn_epis_indicator%TYPE,
        i_order_recurr_plan  IN nnn_epis_indicator.id_order_recurr_plan%TYPE
    );

    /**
    * Creates a next Activity's execution in the plan table when there are more executions to be done, 
    * but they are no yet in the plan table.
    *
    * @param    i_lang                 Professional preferred language
    * @param    i_prof                 Professional identification and its context (institution and software)
    * @param    i_nnn_epis_activity    Careplan's NIC Activity ID
    * @param    i_order_recurr_plan    Order recurrence plan ID for defined frequency in the instructions                 
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    5/8/2014
    */
    PROCEDURE create_next_activity_eval
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_nnn_epis_activity IN nnn_epis_activity.id_nnn_epis_activity%TYPE,
        i_order_recurr_plan IN nnn_epis_activity.id_order_recurr_plan%TYPE
    );

    /**
    * Creates or updates a nursing patient's plan of care with NANDA, NOC and NIC content.
    *
    * @param    i_lang              Professional preferred language
    * @param    i_prof              Professional identification and its context (institution and software)
    * @param    i_patient           Patient ID
    * @param    i_episode           Episode ID
    * @param    i_jsn_careplan      Care plan content in JSON (see example of json structure in the code)
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    12/18/2013
    */
    PROCEDURE create_care_plan
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_jsn_careplan IN CLOB
    );

    /**
    * Gets an object with the information about Careplan's NANDA Diagnosis
    *
    * @param    i_lang                         Professional preferred language
    * @param    i_prof                         Professional identification and its context (institution and software)
    * @param    i_nnn_epis_diagnosis           Careplan's NANDA Diagnosis ID
    *
    * @return   t_obj_nnn_epis_diagnosis       Object with the information about the NANDA diagnosis
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    2/7/2014
    */
    FUNCTION get_epis_nan_diagnosis
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_nnn_epis_diagnosis IN nnn_epis_diagnosis.id_nnn_epis_diagnosis%TYPE
    ) RETURN t_obj_nnn_epis_diagnosis;

    /**
    * Gets info detail about a NANDA Diagnosis included in a patient's nursing care plan.
    *
    * @param    i_lang                 Professional preferred language
    * @param    i_prof                 Professional identification and its context (institution and software)
    * @param    i_nnn_epis_diagnosis   Careplan's NANDA Diagnosis ID
    * @param    i_flg_detail_type      Type of information to obtain from methods of detail
    * @param    o_detail               The details of the selected NANDA diagnosis
    *
    * @value    i_flg_detail_type {*} pk_nnn_core.g_detail_type_current_info {*} pk_nnn_core.g_detail_type_history_changes
    *
    
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    3/26/2014
    */
    PROCEDURE get_epis_nan_diagnosis_det
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_nnn_epis_diagnosis IN nnn_epis_diagnosis.id_nnn_epis_diagnosis%TYPE,
        i_flg_detail_type    IN VARCHAR2,
        o_detail             OUT pk_types.cursor_type
    );

    /**
    * Gets an object with the information about a NANDA Diagnosis evaluation 
    *
    * @param    i_lang                         Professional preferred language
    * @param    i_prof                         Professional identification and its context (institution and software)
    * @param    i_nnn_epis_diag_eval           Careplan's NANDA Diagnosis Evaluation ID
    *
    * @return   t_obj_nnn_epis_diag_eval       Object with the information about the evaluation
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    1/31/2014
    */
    FUNCTION get_epis_nan_diagnosis_eval
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_nnn_epis_diag_eval IN nnn_epis_diag_eval.id_nnn_epis_diag_eval%TYPE
    ) RETURN t_obj_nnn_epis_diag_eval;

    /**
    * Gets info detail about a NANDA Diagnosis an evaluation.
    *
    * @param    i_lang                 Professional preferred language
    * @param    i_prof                 Professional identification and its context (institution and software)
    * @param    i_nnn_epis_diag_eval   Careplan's NANDA Diagnosis Evaluation ID
    * @param    i_flg_detail_type      Type of information to obtain from methods of detail
    * @param    o_detail               The details of the selected NANDA diagnosis evaluation
    *
    * @value    i_flg_detail_type {*} pk_nnn_core.g_detail_type_current_info {*} pk_nnn_core.g_detail_type_history_changes
    *
    
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    6/18/2014
    */
    PROCEDURE get_epis_nan_diagnosis_evl_det
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_nnn_epis_diag_eval IN nnn_epis_diag_eval.id_nnn_epis_diag_eval%TYPE,
        i_flg_detail_type    IN VARCHAR2,
        o_detail             OUT pk_types.cursor_type
    );

    /**
    * Gets an object with the information about a Careplan's NOC Outcome
    *
    * @param    i_lang                         Professional preferred language
    * @param    i_prof                         Professional identification and its context (institution and software)
    * @param    i_nnn_epis_outcome             Careplan's NOC Outcome ID
    *
    * @return   t_obj_nnn_epis_outcome         Object with the information about the NOC Outcome
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    2/26/2014
    */
    FUNCTION get_epis_noc_outcome
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_nnn_epis_outcome IN nnn_epis_outcome.id_nnn_epis_outcome%TYPE
    ) RETURN t_obj_nnn_epis_outcome;

    /**
    * Gets info detail about a NOC Outcome included in a patient's nursing care plan.
    *
    * @param    i_lang                 Professional preferred language
    * @param    i_prof                 Professional identification and its context (institution and software)
    * @param    i_nnn_epis_outcome     Careplan's NOC Outcome ID
    * @param    i_flg_detail_type      Type of information to obtain from methods of detail
    * @param    o_detail               The details of the selected NOC outcome
    *
    * @value    i_flg_detail_type {*} pk_nnn_core.g_detail_type_current_info {*} pk_nnn_core.g_detail_type_history_changes
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    3/28/2014
    */
    PROCEDURE get_epis_noc_outcome_det
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_nnn_epis_outcome IN nnn_epis_outcome.id_nnn_epis_outcome%TYPE,
        i_flg_detail_type  IN VARCHAR2,
        o_detail           OUT pk_types.cursor_type
    );

    /**
    * Gets an object with the information about a NOC Outcome evaluation 
    *
    * @param    i_lang                         Professional preferred language
    * @param    i_prof                         Professional identification and its context (institution and software)
    * @param    i_nnn_epis_outcome_eval        Careplan's Outcome Evaluation ID
    *
    * @return   t_obj_nnn_epis_outcome_eval    Object with the information about the evaluation
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    2/3/2014
    */
    FUNCTION get_epis_noc_outcome_eval
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_nnn_epis_outcome_eval IN nnn_epis_outcome_eval.id_nnn_epis_outcome_eval%TYPE
    ) RETURN t_obj_nnn_epis_outcome_eval;

    /**
    * Gets info detail about a NOC Outcome evaluation
    *
    * @param    i_lang                      Professional preferred language
    * @param    i_prof                      Professional identification and its context (institution and software)
    * @param    i_nnn_epis_outcome_eval     Careplan's Outcome Evaluation ID
    * @param    i_flg_detail_type           Type of information to obtain from methods of detail
    * @param    o_detail                    The details of the selected NOC outcome evaluation
    *
    * @value    i_flg_detail_type {*} pk_nnn_core.g_detail_type_current_info {*} pk_nnn_core.g_detail_type_history_changes
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    5/27/2014
    */
    PROCEDURE get_epis_noc_outcome_eval_det
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_nnn_epis_outcome_eval IN nnn_epis_outcome_eval.id_nnn_epis_outcome_eval%TYPE,
        i_flg_detail_type       IN VARCHAR2,
        o_detail                OUT pk_types.cursor_type
    );
    /**
    * Gets an object with the information about a Careplan's NOC Indicator
    *
    * @param    i_lang                         Professional preferred language
    * @param    i_prof                         Professional identification and its context (institution and software)
    * @param    i_nnn_epis_indicator           Careplan's NOC Indicator ID
    *
    * @return   t_obj_nnn_epis_indicator         Object with the information about the NOC Indicator
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    2/27/2014
    */
    FUNCTION get_epis_noc_indicator
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_nnn_epis_indicator IN nnn_epis_indicator.id_nnn_epis_indicator%TYPE
    ) RETURN t_obj_nnn_epis_indicator;

    /**
    * Gets info detail about a NOC Indicator included in a patient's nursing care plan.
    *
    * @param    i_lang                 Professional preferred language
    * @param    i_prof                 Professional identification and its context (institution and software)
    * @param    i_nnn_epis_indicator   Careplan's NOC Indicator ID
    * @param    i_flg_detail_type      Type of information to obtain from methods of detail
    * @param    o_detail               The details of the selected NOC indicator
    *
    * @value    i_flg_detail_type {*} pk_nnn_core.g_detail_type_current_info {*} pk_nnn_core.g_detail_type_history_changes
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    3/28/2014
    */
    PROCEDURE get_epis_noc_indicator_det
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_nnn_epis_indicator IN nnn_epis_indicator.id_nnn_epis_indicator%TYPE,
        i_flg_detail_type    IN VARCHAR2,
        o_detail             OUT pk_types.cursor_type
    );
    /**
    * Gets an object with the information about a NOC Indicator evaluation 
    *
    * @param    i_lang                         Professional preferred language
    * @param    i_prof                         Professional identification and its context (institution and software)
    * @param    i_nnn_epis_outcome             Associated Careplan's Outcome ID (the scale descriptions depends on associated Outcome)
    * @param    i_nnn_epis_ind_eval            Careplan's Indicator Evaluation ID
    *
    * @return   t_obj_nnn_epis_ind_eval    Object with the information about the evaluation
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    2/5/2014
    */
    FUNCTION get_epis_noc_indicator_eval
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_nnn_epis_outcome  IN nnn_epis_outcome.id_nnn_epis_outcome%TYPE,
        i_nnn_epis_ind_eval IN nnn_epis_ind_eval.id_nnn_epis_ind_eval%TYPE
    ) RETURN t_obj_nnn_epis_ind_eval;

    /**
    * Gets info detail about a NOC Indicator evaluation
    *
    * @param    i_lang                      Professional preferred language
    * @param    i_prof                      Professional identification and its context (institution and software)
    * @param    i_nnn_epis_outcome          Associated Careplan's Outcome ID (the scale descriptions depends on associated Outcome)
    * @param    i_nnn_epis_ind_eval         Careplan's Indicator Evaluation ID
    * @param    i_flg_detail_type           Type of information to obtain from methods of detail
    * @param    o_detail                    The details of the selected NOC indicator evaluation
    *
    * @value    i_flg_detail_type {*} pk_nnn_core.g_detail_type_current_info {*} pk_nnn_core.g_detail_type_history_changes
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    6/17/2014
    */
    PROCEDURE get_epis_noc_indicator_evl_det
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_nnn_epis_outcome  IN nnn_epis_outcome.id_nnn_epis_outcome%TYPE,
        i_nnn_epis_ind_eval IN nnn_epis_ind_eval.id_nnn_epis_ind_eval%TYPE,
        i_flg_detail_type   IN VARCHAR2,
        o_detail            OUT pk_types.cursor_type
    );
    /**
    * Gets an object with the information about a Careplan's NIC Intervention
    *
    * @param    i_lang                         Professional preferred language
    * @param    i_prof                         Professional identification and its context (institution and software)
    * @param    i_nnn_epis_intervention        Careplan's NIC Intervention ID
    *
    * @return   t_obj_nnn_epis_intervention    Object with the information about the NIC Intervention
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    2/28/2014
    */
    FUNCTION get_epis_nic_intervention
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_nnn_epis_intervention IN nnn_epis_intervention.id_nnn_epis_intervention%TYPE
    ) RETURN t_obj_nnn_epis_intervention;

    /**
    * Gets info detail about a NIC Intervention included in a patient's nursing care plan.
    *
    * @param    i_lang                     Professional preferred language
    * @param    i_prof                     Professional identification and its context (institution and software)
    * @param    i_nnn_epis_intervention    Careplan's NIC Intervention ID
    * @param    i_flg_detail_type          Type of information to obtain from methods of detail
    * @param    o_detail                   The details of the selected NIC intervention
    *
    * @value    i_flg_detail_type {*} pk_nnn_core.g_detail_type_current_info {*} pk_nnn_core.g_detail_type_history_changes
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    4/11/2014
    */
    PROCEDURE get_epis_nic_intervention_det
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_nnn_epis_intervention IN nnn_epis_intervention.id_nnn_epis_intervention%TYPE,
        i_flg_detail_type       IN VARCHAR2,
        o_detail                OUT pk_types.cursor_type
    );

    /**
    * Gets an object with the information about a Careplan's NIC Activity
    *
    * @param    i_lang                         Professional preferred language
    * @param    i_prof                         Professional identification and its context (institution and software)
    * @param    i_nnn_epis_activity            Careplan's NIC Activity ID
    *
    * @return   t_obj_nnn_epis_activity    Object with the information about the NIC Activity
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    3/3/2014
    */
    FUNCTION get_epis_nic_activity
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_nnn_epis_activity IN nnn_epis_activity.id_nnn_epis_activity%TYPE
    ) RETURN t_obj_nnn_epis_activity;

    /**
    * Gets an object with the information about a NIC Activity execution 
    *
    * @param    i_lang                         Professional preferred language
    * @param    i_prof                         Professional identification and its context (institution and software)
    * @param    i_nnn_epis_activity_det        Careplan's NIC Activity execution ID
    *
    * @return   t_obj_nnn_epis_activity_det    Object with the information about the execution
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    9/26/2014
    */
    FUNCTION get_epis_nic_activity_det
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_nnn_epis_activity_det IN nnn_epis_activity_det.id_nnn_epis_activity_det%TYPE
    ) RETURN t_obj_nnn_epis_activity_det;

    /**
    * Gets info detail about a NIC Activity included in a patient's nursing care plan.
    *
    * @param    i_lang                     Professional preferred language
    * @param    i_prof                     Professional identification and its context (institution and software)
    * @param    i_nnn_epis_activity        Careplan's NIC Activity ID
    * @param    i_flg_detail_type          Type of information to obtain from methods of detail
    * @param    o_detail                   The details of the selected NIC activity
    *
    * @value    i_flg_detail_type {*} pk_nnn_core.g_detail_type_current_info {*} pk_nnn_core.g_detail_type_history_changes
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    4/11/2014
    */
    PROCEDURE get_epis_nic_activity_det
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_nnn_epis_activity IN nnn_epis_activity.id_nnn_epis_activity%TYPE,
        i_flg_detail_type   IN VARCHAR2,
        o_detail            OUT pk_types.cursor_type
    );

    /**
    * Gets info detail about a NIC Activity execution in a patient's nursing care plan.
    *
    * @param    i_lang                     Professional preferred language
    * @param    i_prof                     Professional identification and its context (institution and software)
    * @param    i_nnn_epis_activity_det    Careplan's NIC Activity execution ID
    * @param    i_flg_detail_type          Type of information to obtain from methods of detail
    * @param    o_detail                   The details of the selected NIC activity
    *
    * @value    i_flg_detail_type {*} pk_nnn_core.g_detail_type_current_info {*} pk_nnn_core.g_detail_type_history_changes
    *
    
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    10/15/2014
    */
    PROCEDURE get_epis_nic_activity_det_det
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_nnn_epis_activity_det IN nnn_epis_activity_det.id_nnn_epis_activity_det%TYPE,
        i_flg_detail_type       IN VARCHAR2,
        o_detail                OUT pk_types.cursor_type
    );

    /**
    * Updates a NOC Nursing Outcome in a patient's nursing care plan.
    *
    * @param    i_lang                         Professional preferred language
    * @param    i_prof                         Professional identification and its context (institution and software)
    * @param    i_patient                      Patient ID 
    * @param    i_episode                      Episode ID 
    * @param    i_noc_outcome                  NOC Outcome ID
    * @param    i_nnn_epis_outcome             Careplan's NOC Outcome ID
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
    * @value    i_flg_prn {*} pk_alert_constant.g_no {*} pk_alert_constant.g_yes
    * @value    i_flg_time {*} pk_nnn_constant.g_time_performed_episode {*} pk_nnn_constant.g_time_performed_between {*} pk_nnn_constant.g_time_performed_next_epis
    * @value    i_flg_priority {*} pk_nnn_constant.g_priority_normal {*} pk_nnn_constant.g_priority_urgent {*} pk_nnn_constant.g_priority_emergent
    * @value    i_flg_req_status {*} pk_nnn_constant.g_req_status_ordered {*} pk_nnn_constant.g_req_status_draft {*} pk_nnn_constant.g_req_status_ongoing  {*} pk_nnn_constant.g_req_status_suspended
    *
    * @return   The updated Careplan's NOC Outcome ID
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   5/6/2013    
    */
    FUNCTION set_outcome_update
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_patient             IN nnn_epis_outcome.id_patient%TYPE,
        i_episode             IN nnn_epis_outcome.id_episode%TYPE,
        i_noc_outcome         IN nnn_epis_outcome.id_noc_outcome%TYPE,
        i_nnn_epis_outcome    IN nnn_epis_outcome.id_nnn_epis_outcome%TYPE,
        i_episode_origin      IN nnn_epis_outcome.id_episode_origin%TYPE,
        i_episode_destination IN nnn_epis_outcome.id_episode_destination%TYPE,
        i_flg_prn             IN nnn_epis_outcome.flg_prn%TYPE,
        i_notes_prn           IN CLOB,
        i_flg_time            IN nnn_epis_outcome.flg_time%TYPE,
        i_flg_priority        IN nnn_epis_outcome.flg_priority%TYPE,
        i_order_recurr_plan   IN nnn_epis_outcome.id_order_recurr_plan%TYPE,
        i_flg_req_status      IN nnn_epis_outcome.flg_req_status%TYPE,
        i_timestamp           IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) RETURN nnn_epis_outcome.id_nnn_epis_outcome%TYPE;

    /**
    *  Gets info to use in the next evaluation of a NOC Outcome in a patient's nursing care plan.
    *    
    * @param    i_lang                     Professional preferred language
    * @param    i_prof                     Professional identification and its context (institution and software)
    * @param    i_nnn_epis_outcome         Careplan's NOC Outcome
    * @param    o_eval                     Information about the next evaluation
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    6/9/2014
    */
    PROCEDURE get_next_outcome_eval_info
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_nnn_epis_outcome IN nnn_epis_outcome_eval.id_nnn_epis_outcome%TYPE,
        o_eval             OUT pk_types.cursor_type
    );

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
    * @param    i_timestamp             Timestamp that should be used across all the functions invoked from this one. Default or NULL to use current_timestamp    
    *
    * @return   Careplan's NOC Outcome Evaluation ID
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    11/11/2013
    */
    FUNCTION set_outcome_evaluate
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_patient               IN nnn_epis_outcome_eval.id_patient%TYPE,
        i_episode               IN nnn_epis_outcome_eval.id_episode%TYPE,
        i_nnn_epis_outcome      IN nnn_epis_outcome_eval.id_nnn_epis_outcome%TYPE,
        i_nnn_epis_outcome_eval IN nnn_epis_outcome_eval.id_nnn_epis_outcome_eval%TYPE,
        i_dt_evaluation         IN nnn_epis_outcome_eval.dt_evaluation%TYPE,
        i_target_value          IN nnn_epis_outcome_eval.target_value%TYPE,
        i_outcome_value         IN nnn_epis_outcome_eval.outcome_value%TYPE,
        i_notes                 IN CLOB,
        i_timestamp             IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) RETURN nnn_epis_outcome_eval.id_nnn_epis_outcome_eval%TYPE;

    /**
    * Cancels a set of NOC Outcomes and all its linked NOC Indicators that are not being shared with other outcomes.
    *
    * @param    i_lang                     Professional preferred language
    * @param    i_prof                     Professional identification and its context (institution and software)
    * @param    i_patient                  Patient ID
    * @param    i_episode                  Episode ID         
    * @param    i_lst_nnn_epis_outcome     Collection of outcomes identifiers that we want to cancel
    * @param    i_cancel_reason            Cancellation reason identifier.
    * @param    i_cancel_notes             Notes describing the reason of the cancellation.
    * @param    i_timestamp                 Timestamp that should be used across all the functions invoked from this one. Default or NULL to use current_timestamp     
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    4/30/2014
    */
    PROCEDURE set_outcome_cancel
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_patient              IN nnn_epis_outcome.id_patient%TYPE,
        i_episode              IN nnn_epis_outcome.id_episode%TYPE,
        i_lst_nnn_epis_outcome IN table_number,
        i_cancel_reason        IN nnn_epis_outcome.id_cancel_reason%TYPE,
        i_cancel_notes         IN nnn_epis_outcome.cancel_notes%TYPE DEFAULT NULL,
        i_timestamp            IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    );

    /**
    * Cancels a set of NOC Outcome evaluations.
    *
    * @param    i_lang                         Professional preferred language    
    * @param    i_prof                         Professional identification and its context (institution and software)
    * @param    i_lst_nnn_epis_outcome_eval    Collection of outcome evaluation IDs that we want to cancel
    * @param    i_cancel_reason                Cancellation reason identifier.
    * @param    i_cancel_notes                 Notes describing the reason of the cancellation.
    * @param    i_timestamp                    Timestamp that should be used across all the functions invoked from this one. Default or NULL to use current_timestamp
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    11/06/2014
    */
    PROCEDURE set_outcome_eval_cancel
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_patient                   IN patient.id_patient%TYPE,
        i_episode                   IN episode.id_episode%TYPE,
        i_lst_nnn_epis_outcome_eval IN table_number,
        i_cancel_reason             IN nnn_epis_outcome_eval.id_cancel_reason%TYPE,
        i_cancel_notes              IN nnn_epis_outcome_eval.cancel_notes%TYPE,
        i_timestamp                 IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    );

    /**
    * Sets as "On-Hold" a set of NOC Outcomes.
    *
    * @param    i_lang                     Professional preferred language
    * @param    i_prof                     Professional identification and its context (institution and software)
    * @param    i_patient                  Patient ID
    * @param    i_episode                  Episode ID         
    * @param    i_lst_nnn_epis_outcome     Collection of outcomes identifiers that we want to hold
    * @param    i_timestamp                Timestamp that should be used across all the functions invoked from this one. Default or NULL to use current_timestamp     
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    5/15/2014
    */
    PROCEDURE set_outcome_hold
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_patient              IN nnn_epis_outcome.id_patient%TYPE,
        i_episode              IN nnn_epis_outcome.id_episode%TYPE,
        i_lst_nnn_epis_outcome IN table_number,
        i_timestamp            IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    );

    /**
    * Resumes from "On-hold" state a set of NOC Outcomes.
    *
    * @param    i_lang                     Professional preferred language
    * @param    i_prof                     Professional identification and its context (institution and software)
    * @param    i_patient                  Patient ID
    * @param    i_episode                  Episode ID         
    * @param    i_lst_nnn_epis_outcome     Collection of outcomes identifiers that we want to resume
    * @param    i_timestamp                Timestamp that should be used across all the functions invoked from this one. Default or NULL to use current_timestamp     
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    5/15/2014
    */
    PROCEDURE set_outcome_resume
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_patient              IN nnn_epis_outcome.id_patient%TYPE,
        i_episode              IN nnn_epis_outcome.id_episode%TYPE,
        i_lst_nnn_epis_outcome IN table_number,
        i_timestamp            IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    );

    /**
    * Updates a NOC Nursing Indicator in a patient's nursing care plan.
    *
    * @param    i_lang                         Professional preferred language
    * @param    i_prof                         Professional identification and its context (institution and software)
    * @param    i_patient                      Patient ID 
    * @param    i_episode                      Episode ID 
    * @param    i_noc_indicator                NOC Indicator ID
    * @param    i_nnn_epis_indicator           Careplan's NOC Indicator ID
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
    * @return   The updated Careplan's NOC Indicator ID
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    5/7/2014
    */
    FUNCTION set_indicator_update
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_patient             IN nnn_epis_indicator.id_patient%TYPE,
        i_episode             IN nnn_epis_indicator.id_episode%TYPE,
        i_noc_indicator       IN nnn_epis_indicator.id_noc_indicator%TYPE,
        i_nnn_epis_indicator  IN nnn_epis_indicator.id_nnn_epis_indicator%TYPE,
        i_episode_origin      IN nnn_epis_indicator.id_episode_origin%TYPE,
        i_episode_destination IN nnn_epis_indicator.id_episode_destination%TYPE,
        i_flg_prn             IN nnn_epis_indicator.flg_prn%TYPE,
        i_notes_prn           IN CLOB,
        i_flg_time            IN nnn_epis_indicator.flg_time%TYPE,
        i_flg_priority        IN nnn_epis_indicator.flg_priority%TYPE,
        i_order_recurr_plan   IN nnn_epis_indicator.id_order_recurr_plan%TYPE,
        i_flg_req_status      IN nnn_epis_indicator.flg_req_status%TYPE,
        i_timestamp           IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) RETURN nnn_epis_indicator.id_nnn_epis_indicator%TYPE;

    /**
    *  Gets info to use in the next evaluation of a NOC Indicator in a patient's nursing care plan.
    *    
    * @param    i_lang                     Professional preferred language
    * @param    i_prof                     Professional identification and its context (institution and software)
    * @param    i_nnn_epis_outcome         Careplan's NOC Outcome
    * @param    i_nnn_epis_indicator       Careplan's NOC Indicator ID    
    * @param    o_eval                     Information about the next evaluation
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    6/11/2014
    */
    PROCEDURE get_next_indicator_eval_info
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_nnn_epis_outcome   IN nnn_epis_outcome.id_nnn_epis_outcome%TYPE,
        i_nnn_epis_indicator IN nnn_epis_ind_eval.id_nnn_epis_indicator%TYPE,
        o_eval               OUT pk_types.cursor_type
    );

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
    * @param    i_flg_status            Evaluation status        
    * @param    i_timestamp             Timestamp that should be used across all the functions invoked from this one. Default or NULL to use current_timestamp    
    *
    * @return   Careplan's NOC Indicator Evaluation ID
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    12/13/2013
    */
    FUNCTION set_indicator_evaluate
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN nnn_epis_ind_eval.id_patient%TYPE,
        i_episode            IN nnn_epis_ind_eval.id_episode%TYPE,
        i_nnn_epis_indicator IN nnn_epis_ind_eval.id_nnn_epis_indicator%TYPE,
        i_nnn_epis_ind_eval  IN nnn_epis_ind_eval.id_nnn_epis_ind_eval%TYPE,
        i_dt_evaluation      IN nnn_epis_ind_eval.dt_evaluation%TYPE,
        i_target_value       IN nnn_epis_ind_eval.target_value%TYPE,
        i_indicator_value    IN nnn_epis_ind_eval.indicator_value%TYPE,
        i_notes              IN CLOB,
        i_timestamp          IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) RETURN nnn_epis_ind_eval.id_nnn_epis_ind_eval%TYPE;

    /**
    * Cancels a set of NOC Indicators.
    *
    * @param    i_lang                      Professional preferred language
    * @param    i_prof                      Professional identification and its context (institution and software)
    * @param    i_patient                   Patient ID
    * @param    i_episode                   Episode ID    
    * @param    i_lst_nnn_epis_indicator    Collection of indicator IDs that we want to cancel
    * @param    i_cancel_reason             Cancellation reason identifier
    * @param    i_cancel_notes              Notes describing the reason of the cancellation
    * @param    i_timestamp                 Timestamp that should be used across all the functions invoked from this one. Default or NULL to use current_timestamp
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    4/30/2014
    */
    PROCEDURE set_indicator_cancel
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_patient                IN nnn_epis_indicator.id_patient%TYPE,
        i_episode                IN nnn_epis_indicator.id_episode%TYPE,
        i_lst_nnn_epis_indicator IN table_number,
        i_cancel_reason          IN nnn_epis_indicator.id_cancel_reason%TYPE,
        i_cancel_notes           IN nnn_epis_indicator.cancel_notes%TYPE DEFAULT NULL,
        i_timestamp              IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    );

    /**
    * Cancels a set of NIC Indicator evaluations.
    *
    * @param    i_lang                      Professional preferred language     
    * @param    i_prof                      Professional identification and its context (institution and software)
    * @param    i_lst_nnn_epis_ind_eval     Collection of indicator evaluation IDs that we want to cancel
    * @param    i_cancel_reason             Cancellation reason identifier.
    * @param    i_cancel_notes              Notes describing the reason of the cancellation.
    * @param    i_timestamp                 Timestamp that should be used across all the functions invoked from this one. Default or NULL to use current_timestamp
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    11/06/2014
    */
    PROCEDURE set_indicator_eval_cancel
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_patient               IN patient.id_patient%TYPE,
        i_episode               IN episode.id_episode%TYPE,
        i_lst_nnn_epis_ind_eval IN table_number,
        i_cancel_reason         IN nnn_epis_ind_eval.id_cancel_reason%TYPE,
        i_cancel_notes          IN nnn_epis_ind_eval.cancel_notes%TYPE,
        i_timestamp             IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    );

    /**
    * Sets as "On-Hold" a set of NOC Indicator.
    *
    * @param    i_lang                     Professional preferred language
    * @param    i_prof                     Professional identification and its context (institution and software)
    * @param    i_patient                  Patient ID
    * @param    i_episode                  Episode ID         
    * @param    i_lst_nnn_epis_indicator   Collection of indicator identifiers that we want to hold
    * @param    i_timestamp                Timestamp that should be used across all the functions invoked from this one. Default or NULL to use current_timestamp     
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    5/15/2014
    */
    PROCEDURE set_indicator_hold
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_patient                IN nnn_epis_indicator.id_patient%TYPE,
        i_episode                IN nnn_epis_indicator.id_episode%TYPE,
        i_lst_nnn_epis_indicator IN table_number,
        i_timestamp              IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    );

    /**
    * Resumes from "On-hold" state a set of NOC Indicator.
    *
    * @param    i_lang                     Professional preferred language
    * @param    i_prof                     Professional identification and its context (institution and software)
    * @param    i_patient                  Patient ID
    * @param    i_episode                  Episode ID         
    * @param    i_lst_nnn_epis_indicator   Collection of indicator identifiers that we want to resume
    * @param    i_timestamp                Timestamp that should be used across all the functions invoked from this one. Default or NULL to use current_timestamp     
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    5/15/2014
    */
    PROCEDURE set_indicator_resume
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_patient                IN nnn_epis_indicator.id_patient%TYPE,
        i_episode                IN nnn_epis_indicator.id_episode%TYPE,
        i_lst_nnn_epis_indicator IN table_number,
        i_timestamp              IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    );

    /**
    * Updates a NIC Activity to a patient's nursing care plan.
    *
    * @param    i_lang                         Professional preferred language
    * @param    i_prof                         Professional identification and its context (institution and software)
    * @param    i_patient                      Patient ID 
    * @param    i_episode                      Episode ID 
    * @param    i_nic_activity                 NIC Activity ID 
    * @param    i_nnn_epis_activity            Careplan's NIC Activity ID
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
    * @value    i_flg_prn {*} pk_alert_constant.g_no {*} pk_alert_constant.g_yes
    * @value    i_flg_time {*} pk_nnn_constant.g_time_performed_episode {*} pk_nnn_constant.g_time_performed_between {*} pk_nnn_constant.g_time_performed_next_epis
    * @value    i_flg_priority {*} pk_nnn_constant.g_priority_normal {*} pk_nnn_constant.g_priority_urgent {*} pk_nnn_constant.g_priority_emergent
    * @value    i_flg_req_status {*} pk_nnn_constant.g_req_status_ordered {*} pk_nnn_constant.g_req_status_draft {*} pk_nnn_constant.g_req_status_ongoing  {*} pk_nnn_constant.g_req_status_suspended
    *
    * @return   The updated Careplan's NIC Activity ID
    
    *    
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   6/20/2014
    */
    FUNCTION set_activity_update
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_patient             IN nnn_epis_activity.id_patient%TYPE,
        i_episode             IN nnn_epis_activity.id_episode%TYPE,
        i_nic_activity        IN nnn_epis_activity.id_nic_activity%TYPE,
        i_nnn_epis_activity   IN nnn_epis_activity.id_nnn_epis_activity%TYPE,
        i_episode_origin      IN nnn_epis_activity.id_episode_origin%TYPE,
        i_episode_destination IN nnn_epis_activity.id_episode_destination%TYPE,
        i_flg_prn             IN nnn_epis_activity.flg_prn%TYPE,
        i_notes_prn           IN CLOB,
        i_flg_time            IN nnn_epis_activity.flg_time%TYPE,
        i_flg_priority        IN nnn_epis_activity.flg_priority%TYPE,
        i_order_recurr_plan   IN nnn_epis_activity.id_order_recurr_plan%TYPE,
        i_flg_req_status      IN nnn_epis_activity.flg_req_status%TYPE,
        i_timestamp           IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) RETURN nnn_epis_activity.id_nnn_epis_activity%TYPE;

    /**
    * Cancels a set of NIC Activities.
    *
    * @param    i_lang                     Professional preferred language
    * @param    i_prof                     Professional identification and its context (institution and software)
    * @param    i_patient                  Patient ID
    * @param    i_episode                  Episode ID         
    * @param    i_lst_nnn_epis_activity    Collection of activity IDs that we want to cancel
    * @param    i_cancel_reason            Cancellation reason identifier.
    * @param    i_cancel_notes             Notes describing the reason of the cancellation.
    * @param    i_timestamp                Timestamp that should be used across all the functions invoked from this one. Default or NULL to use current_timestamp          
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    5/2/2014
    */
    PROCEDURE set_activity_cancel
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_patient               IN nnn_epis_activity.id_patient%TYPE,
        i_episode               IN nnn_epis_activity.id_episode%TYPE,
        i_lst_nnn_epis_activity IN table_number,
        i_cancel_reason         IN nnn_epis_activity.id_cancel_reason%TYPE,
        i_cancel_notes          IN nnn_epis_activity.cancel_notes%TYPE DEFAULT NULL,
        i_timestamp             IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    );

    /**
    * Cancels a set of NIC Activity executions.
    *
    * @param    i_lang                      Professional preferred language     
    * @param    i_prof                      Professional identification and its context (institution and software)
    * @param    lst_nnn_epis_activity_det   Collection of activity execution IDs that we want to cancel
    * @param    i_cancel_reason             Cancellation reason identifier.
    * @param    i_cancel_notes              Notes describing the reason of the cancellation.
    * @param    i_timestamp                Timestamp that should be used across all the functions invoked from this one. Default or NULL to use current_timestamp
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    11/06/2014
    */
    PROCEDURE set_activity_exec_cancel
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_patient                   IN patient.id_patient%TYPE,
        i_episode                   IN episode.id_episode%TYPE,
        i_lst_nnn_epis_activity_det IN table_number,
        i_cancel_reason             IN nnn_epis_activity_det.id_cancel_reason%TYPE,
        i_cancel_notes              IN nnn_epis_activity_det.cancel_notes%TYPE,
        i_timestamp                 IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    );

    /**
    * Sets as "On-Hold" a set of NIC Activities.
    *
    * @param    i_lang                     Professional preferred language
    * @param    i_prof                     Professional identification and its context (institution and software)
    * @param    i_patient                  Patient ID
    * @param    i_episode                  Episode ID         
    * @param    i_lst_nnn_epis_activity    Collection of activity identifiers that we want to hold
    * @param    i_timestamp                Timestamp that should be used across all the functions invoked from this one. Default or NULL to use current_timestamp     
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    5/15/2014
    */
    PROCEDURE set_activity_hold
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_patient               IN nnn_epis_activity.id_patient%TYPE,
        i_episode               IN nnn_epis_activity.id_episode%TYPE,
        i_lst_nnn_epis_activity IN table_number,
        i_timestamp             IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    );

    /**
    * Resumes from "On-hold" state a set of NIC Activities.
    *
    * @param    i_lang                     Professional preferred language
    * @param    i_prof                     Professional identification and its context (institution and software)
    * @param    i_patient                  Patient ID
    * @param    i_episode                  Episode ID         
    * @param    i_lst_nnn_epis_activity     Collection of activities identifiers that we want to resume
    * @param    i_timestamp                Timestamp that should be used across all the functions invoked from this one. Default or NULL to use current_timestamp     
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    5/15/2014
    */
    PROCEDURE set_activity_resume
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_patient               IN nnn_epis_activity.id_patient%TYPE,
        i_episode               IN nnn_epis_activity.id_episode%TYPE,
        i_lst_nnn_epis_activity IN table_number,
        i_timestamp             IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    );

    /**
    *  Gets info about NIC Activities in a patient's nursing care plan.
    *    
    * @param    i_lang                         Professional preferred language
    * @param    i_prof                         Professional identification and its context (institution and software)
    * @param    i_lst_nnn_epis_intervention    Collection of Careplan's NIC Intervention ID
    * @param    i_lst_nnn_epis_activity        Collection of Careplan's NIC Activity ID
    * @param    o_info                         Information about the NIC Activities
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    9/29/2014
    */
    PROCEDURE get_activity_info
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_patient                   IN nnn_epis_outcome.id_patient%TYPE,
        i_episode                   IN nnn_epis_outcome.id_episode%TYPE,
        i_lst_nnn_epis_intervention IN table_number,
        i_lst_nnn_epis_activity     IN table_number,
        o_info                      OUT pk_types.cursor_type
    );

    /**
    *  Gets info to be used in the next execution of a NIC Activity in a patient's nursing care plan.
    *    
    * @param    i_lang                     Professional preferred language
    * @param    i_prof                     Professional identification and its context (institution and software)
    * @param    i_patient                  Patient ID
    * @param    i_episode                  Episode ID             
    * @param    i_nnn_epis_intervention    Careplan's NIC Intervention ID    
    * @param    i_nnn_epis_activity        Careplan's NIC Activity ID
    * @param    o_exec_info                Information about the next execution
    * @param    o_activity_tasks           If a tasklist, returns the list of activity tasks
    * @param    o_vs_info                  Vital sign-related information
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    9/29/2014
    */
    PROCEDURE get_next_activity_exec_info
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_patient               IN patient.id_patient%TYPE,
        i_episode               IN episode.id_episode%TYPE,
        i_nnn_epis_intervention IN nnn_epis_intervention.id_nnn_epis_intervention%TYPE,
        i_nnn_epis_activity     IN nnn_epis_activity.id_nnn_epis_activity%TYPE,
        o_exec_info             OUT pk_types.cursor_type,
        o_activity_tasks        OUT pk_types.cursor_type,
        o_vs_info               OUT pk_types.cursor_type
    );

    /**
    * Creates or updates an execution of NIC Activity in a patient's nursing care plan.
    *
    * @param    i_lang                          Professional preferred language
    * @param    i_prof                          Professional identification and its context (institution and software)
    * @param    i_patient                       Patient ID
    * @param    i_episode                       Episode ID
    * @param    i_nnn_epis_activity             Careplan's NIC Activity ID
    * @param    i_nnn_epis_activity_det         Careplan's NIC Activity execution ID. Declared to update an existing execution or NULL to create a new one
    * @param    i_time_start                    Start date of activiy execution 
    * @param    i_time_end                      End date of activiy execution
    * @param    i_doc_template                  Touch-option template ID    
    * @param    i_lst_documentation             List of template's elements documentation
    * @param    i_lst_doc_element               List of template's elements
    * @param    i_lst_doc_element_crit          List of template's elements crit
    * @param    i_lst_value                     List of template's elements values    
    * @param    i_lst_lst_doc_element_qualif    List of lists with template's elements quantifications/qualifications
    * @param    i_lst_vs_element                List of template's elements ID (id_doc_element) filled with vital signs
    * @param    i_lst_vs_save_mode              List of flags to indicate the applicable mode to save each vital signs measurement
    * @param    i_lst_vs                        List of vital signs ID (id_vital_sign)
    * @param    i_lst_vs_value                  List of vital signs values
    * @param    i_lst_vs_uom                    List of units of measurement (id_unit_measure)
    * @param    i_lst_vs_scales                 List of scales (id_vs_scales_element)
    * @param    i_lst_vs_date                   List of measurement date. Values are serialized as strings (YYYYMMDDhh24miss)
    * @param    i_lst_vs_read                   List of saved vital sign measurement (id_vital_sign_read)    
    * @param    i_notes                         Notes
    * @param    i_lst_task_activity             List of activity task (used to document child tasks within a NIC Activity that was defined as tasklist)
    * @param    i_lst_task_executed             List of flags to indicate the activity task was executed or not
    * @param    i_lst_task_notes                List of notes for the activity task
    * @param    i_lst_supply_workflow           List of supply workflow ID
    * @param    i_lst_supply                    List of supply ID
    * @param    i_lst_supply_set                List of parent supply set (if applicable)
    * @param    i_lst_supply_qty                List of supply quantities
    * @param    i_lst_supply_type               List of supply or supply Kit
    * @param    i_lst_supply_barcode            List of supply barcode
    * @param    i_lst_supply_deliver_needed     List of supply deliver needed
    * @param    i_lst_supply_cons_type          List of supply consumption type
    * @param    i_lst_dt_expiration             List of supply expiration date    
    * @param    i_lst_supply_validation         List of supply barcode has been validated
    * @param    i_lst_supply_lot                List of supply lot number
    * @param    i_timestamp                     Timestamp that should be used across all the functions invoked from this one. Default or NULL to use current_timestamp           
    *
    * @return   Careplan's NIC Activity execution ID
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    5/19/2014
    */
    FUNCTION set_activity_execute
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_patient                    IN nnn_epis_activity_det.id_patient%TYPE,
        i_episode                    IN nnn_epis_activity_det.id_episode%TYPE,
        i_nnn_epis_activity          IN nnn_epis_activity_det.id_nnn_epis_activity%TYPE,
        i_nnn_epis_activity_det      IN nnn_epis_activity_det.id_nnn_epis_activity_det%TYPE,
        i_time_start                 IN nnn_epis_activity_det.dt_val_time_start%TYPE,
        i_time_end                   IN nnn_epis_activity_det.dt_trs_time_end%TYPE,
        i_doc_template               IN doc_template.id_doc_template%TYPE,
        i_lst_documentation          IN table_number,
        i_lst_doc_element            IN table_number,
        i_lst_doc_element_crit       IN table_number,
        i_lst_value                  IN table_varchar,
        i_lst_lst_doc_element_qualif IN table_table_number,
        i_lst_vs_element             IN table_number,
        i_lst_vs_save_mode           IN table_varchar,
        i_lst_vs                     IN table_number,
        i_lst_vs_value               IN table_number,
        i_lst_vs_uom                 IN table_number,
        i_lst_vs_scales              IN table_number,
        i_lst_vs_date                IN table_varchar,
        i_lst_vs_read                IN table_number,
        i_notes                      IN CLOB,
        i_lst_task_activity          IN table_number,
        i_lst_task_executed          IN table_varchar,
        i_lst_task_notes             IN table_varchar,
        i_lst_supply_workflow        IN table_number,
        i_lst_supply                 IN table_number,
        i_lst_supply_set             IN table_number,
        i_lst_supply_qty             IN table_number,
        i_lst_supply_type            IN table_varchar,
        i_lst_supply_barcode_scanned IN table_varchar,
        i_lst_supply_deliver_needed  IN table_varchar,
        i_lst_supply_cons_type       IN table_varchar,
        i_lst_supply_dt_expiration   IN table_varchar,
        i_lst_supply_validation      IN table_varchar,
        i_lst_supply_lot             IN table_varchar,
        i_timestamp                  IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) RETURN nnn_epis_activity_det.id_nnn_epis_activity_det%TYPE;

    /**
    * Creates or updates a collection of executions of NIC Activities in a patient's nursing care plan.
    * Deserializes the input parameters sent in JSON and invokes the original set_activity_execute().
    *
    * @param    i_lang                          Professional preferred language
    * @param    i_prof                          Professional identification and its context (institution and software)
    * @param    i_patient                       Patient ID
    * @param    i_episode                       Episode ID
    * @param    i_jsn_input_params              Collection of input parameters in JSON
    *
    * @return   Collection of Careplan's NIC Activity execution ID
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    9/11/2014
    */
    FUNCTION set_activity_execute
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN nnn_epis_activity_det.id_patient%TYPE,
        i_episode          IN nnn_epis_activity_det.id_episode%TYPE,
        i_jsn_input_params IN CLOB
    ) RETURN table_number;

    /**
    * Cancels a set of NIC Interventions and all its linked NIC Activities that are not being shared with other interventions.
    *
    * @param    i_lang                         Professional preferred language
    * @param    i_prof                         Professional identification and its context (institution and software)
    * @param    i_patient                      Patient ID
    * @param    i_episode                      Episode ID         
    * @param    i_lst_nnn_epis_intervention    Collection of intervention IDs that we want to cancel
    * @param    i_cancel_reason                Cancellation reason identifier.
    * @param    i_cancel_notes                 Notes describing the reason of the cancellation.
    * @param    i_timestamp                    Timestamp that should be used across all the functions invoked from this one. Default or NULL to use current_timestamp          
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    5/5/2014
    */
    PROCEDURE set_intervention_cancel
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_patient                   IN nnn_epis_intervention.id_patient%TYPE,
        i_episode                   IN nnn_epis_intervention.id_episode%TYPE,
        i_lst_nnn_epis_intervention IN table_number,
        i_cancel_reason             IN nnn_epis_intervention.id_cancel_reason%TYPE,
        i_cancel_notes              IN nnn_epis_intervention.cancel_notes%TYPE DEFAULT NULL,
        i_timestamp                 IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    );

    /**
    * Sets as "On-Hold" a set of NIC Interventions.
    *
    * @param    i_lang                       Professional preferred language
    * @param    i_prof                       Professional identification and its context (institution and software)
    * @param    i_patient                    Patient ID
    * @param    i_episode                    Episode ID         
    * @param    i_lst_nnn_epis_intervention  Collection of intervention identifiers that we want to hold
    * @param    i_timestamp                  Timestamp that should be used across all the functions invoked from this one. Default or NULL to use current_timestamp     
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    5/16/2014
    */
    PROCEDURE set_intervention_hold
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_patient                   IN nnn_epis_intervention.id_patient%TYPE,
        i_episode                   IN nnn_epis_intervention.id_episode%TYPE,
        i_lst_nnn_epis_intervention IN table_number,
        i_timestamp                 IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    );

    /**
    * Resumes from "On-hold" state a set of NIC Interventions.
    *
    * @param    i_lang                       Professional preferred language
    * @param    i_prof                       Professional identification and its context (institution and software)
    * @param    i_patient                    Patient ID
    * @param    i_episode                    Episode ID         
    * @param    i_lst_nnn_epis_intervention  Collection of intervention identifiers that we want to resume
    * @param    i_timestamp                  Timestamp that should be used across all the functions invoked from this one. Default or NULL to use current_timestamp     
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    5/16/2014
    */
    PROCEDURE set_intervention_resume
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_patient                   IN nnn_epis_intervention.id_patient%TYPE,
        i_episode                   IN nnn_epis_intervention.id_episode%TYPE,
        i_lst_nnn_epis_intervention IN table_number,
        i_timestamp                 IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    );

    /**
    * Updates a NANDA Nursing Diagnosis in a patient's nursing care plan.
    *
    * @param    i_lang                  Professional preferred language
    * @param    i_prof                  Professional identification and its context (institution and software)
    * @param    i_patient               Patient ID
    * @param    i_episode               Episode ID
    * @param    i_nan_diagnosis         NANDA diagnosis ID
    * @param    i_nnn_epis_diagnosis    Careplan's NANDA Diagnosis ID
    * @param    i_dt_diagnosis          Diagnosis date    
    * @param    i_notes                 Notes
    * @param    i_flg_req_status        Request status
    * @param    i_timestamp             Timestamp that should be used across all the functions invoked from this one. Default or NULL to use current_timestamp
    *
    * @value    i_flg_req_status {*} pk_nnn_constant.g_req_status_ordered {*} pk_nnn_constant.g_req_status_draft
    *    
    * @return   The updated Careplan's NANDA Diagnosis ID
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    12/11/2013
    */
    FUNCTION set_diagnosis_update
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_nan_diagnosis      IN nnn_epis_diagnosis.id_nan_diagnosis%TYPE,
        i_dt_diagnosis       IN nnn_epis_diagnosis.dt_diagnosis%TYPE,
        i_nnn_epis_diagnosis IN nnn_epis_diagnosis.id_nnn_epis_diagnosis%TYPE,
        i_notes              IN nnn_epis_diagnosis.edited_diagnosis_name%TYPE,
        i_flg_req_status     IN nnn_epis_diagnosis.flg_req_status%TYPE,
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
    * @return   The created or updated Careplan's NANDA Diagnosis Evaluation ID
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    3/3/2014
    */
    FUNCTION set_diagnosis_evaluate
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_nnn_epis_diagnosis IN nnn_epis_diag_eval.id_nnn_epis_diagnosis%TYPE,
        i_nnn_epis_diag_eval IN nnn_epis_diag_eval.id_nnn_epis_diag_eval%TYPE,
        i_flg_status         IN nnn_epis_diag_eval.flg_status%TYPE,
        i_dt_evaluation      IN nnn_epis_diag_eval.dt_evaluation%TYPE,
        i_notes              IN CLOB,
        i_lst_nan_relf       IN table_number,
        i_lst_nan_riskf      IN table_number,
        i_lst_nan_defc       IN table_number,
        i_timestamp          IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) RETURN nnn_epis_diag_eval.id_nnn_epis_diag_eval%TYPE;

    /**
    * Creates an evaluation of NANDA Nursing Diagnosis in a patient's nursing care plan using the information of the last evaluation (if any)and the status indicated in the input parameter.
    *
    * This method is only inteded to be used for actions like "Mark as Active", "Mark as Inactive", "Mark as Resolved"
    * to create a new evaluation, so as assumption the new diagnosis status must be different from de last one.
    * Otherwise shoud use the full method pk_nnn_api_db.set_diagnosis_evaluate.
    *
    * @param    i_lang                  Professional preferred language
    * @param    i_prof                  Professional identification and its context (institution and software)
    * @param    i_patient               Patient ID
    * @param    i_episode               Episode ID
    * @param    i_nnn_epis_diagnosis    Careplan's NANDA Diagnosis ID 
    * @param    i_flg_status            Diagnosis status
    * @param    i_timestamp             Timestamp that should be used across all the functions invoked from this one. Default or NULL to use current_timestamp        
    *
    * @return   The created or updated Careplan's NANDA Diagnosis Evaluation ID
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    3/13/2014
    */
    FUNCTION set_diagnosis_evaluate_st
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_nnn_epis_diagnosis IN nnn_epis_diag_eval.id_nnn_epis_diagnosis%TYPE,
        i_flg_status         IN nnn_epis_diag_eval.flg_status%TYPE,
        i_timestamp          IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) RETURN nnn_epis_diag_eval.id_nnn_epis_diag_eval%TYPE;

    /**
     * Cancels a set of NANDA diagnoses and all its linked NOC Outcomes / NIC Interventions that are not being shared with other diagnoses.
     *
     * @param    i_lang                  Professional preferred language     
     * @param    i_prof                  Professional identification and its context (institution and software)
     * @param    i_patient               Patient ID
     * @param    i_episode               Episode ID         
     * @param    i_lst_epis_diag         Collection of diagnosis IDs that we want to cancel
     * @param    i_cancel_reason         Cancellation reason identifier.
     * @param    i_cancel_notes          Notes describing the reason of the cancellation.
     * @param    i_timestamp             Timestamp that should be used across all the functions invoked from this one. Default or NULL to use current_timestamp          
     *
     * @author   CRISTINA.OLIVEIRA
     * @version  2.6.4.3 
     * @since    14/11/2013 
    */
    PROCEDURE set_diagnosis_cancel
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN nnn_epis_diagnosis.id_patient%TYPE,
        i_episode       IN nnn_epis_diagnosis.id_episode%TYPE,
        i_lst_epis_diag IN table_number,
        i_cancel_reason IN nnn_epis_diagnosis.id_cancel_reason%TYPE,
        i_cancel_notes  IN nnn_epis_diagnosis.cancel_notes%TYPE DEFAULT NULL,
        i_timestamp     IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    );

    /**
    * Cancels a set of NANDA Diagnosis evaluations.
    *
    * @param    i_lang                  Professional preferred language    
    * @param    i_prof                  Professional identification and its context (institution and software)
    * @param    i_lst_epis_diag_eval    Collection of diagnosis evaluation IDs that we want to cancel
    * @param    i_cancel_reason         Cancellation reason identifier.
    * @param    i_cancel_notes          Notes describing the reason of the cancellation.
    * @param    i_timestamp             Timestamp that should be used across all the functions invoked from this one. Default or NULL to use current_timestamp
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    11/06/2014
    */
    PROCEDURE set_diagnosis_eval_cancel
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_lst_epis_diag_eval IN table_number,
        i_cancel_reason      IN nnn_epis_diag_eval.id_cancel_reason%TYPE,
        i_cancel_notes       IN nnn_epis_diag_eval.cancel_notes%TYPE,
        i_timestamp          IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    );

    /**
    * Gets an hierachical detail of the Careplan for a NANDA Diagnosis.
    *
    * @param    i_lang                         Professional preferred language
    * @param    i_prof                         Professional identification and its context (institution and software)
    * @param    i_nnn_epis_diagnosis           Careplan's NANDA Diagnosis ID
    *
    * @return   json                           JSON document with current information about the diagnosis and all the items in the care plan that are linked to it.
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    3/7/2014
    */
    FUNCTION get_epis_diagnosis_hier_detail
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_nnn_epis_diagnosis IN nnn_epis_diagnosis.id_nnn_epis_diagnosis%TYPE
    ) RETURN json_object_t;

    /**
    * Gets an hierachical detail of the Careplan for a NOC Outcome.
    *
    * @param    i_lang                         Professional preferred language
    * @param    i_prof                         Professional identification and its context (institution and software)
    * @param    i_nnn_epis_outcome             Careplan's NOC Outcome ID
    *
    * @return   json                           JSON document with current information about the outcome and all the items in the care plan that are linked to it.
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    3/7/2014
    */
    FUNCTION get_epis_outcome_hier_detail
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_nnn_epis_outcome IN nnn_epis_outcome.id_nnn_epis_outcome%TYPE
    ) RETURN json_object_t;

    /**
    * Gets an hierachical detail of the Careplan for a NOC Indicator.
    *
    * @param    i_lang                         Professional preferred language
    * @param    i_prof                         Professional identification and its context (institution and software)
    * @param    i_nnn_epis_indicator           Careplan's NOC Indicator ID
    * @param    i_nnn_epis_outcome             Careplan's NOC Outcome ID    
    * @param    i_noc_outcome                  NOC Outcome ID    
    *
    * @return   json                           JSON document with current information about the indicator.
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    4/10/2014
    */
    FUNCTION get_epis_indicator_hier_detail
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_nnn_epis_indicator IN nnn_epis_indicator.id_nnn_epis_indicator%TYPE,
        i_nnn_epis_outcome   IN nnn_epis_outcome.id_nnn_epis_outcome%TYPE,
        i_noc_outcome        IN nnn_epis_outcome.id_noc_outcome%TYPE
    ) RETURN json_object_t;

    /**
    * Gets an hierachical detail of the Careplan for a NIC Intervention.
    *
    * @param    i_lang                         Professional preferred language
    * @param    i_prof                         Professional identification and its context (institution and software)
    * @param    i_nnn_epis_intervention        Careplan's NIC Intervention ID
    *
    * @return   json                           JSON document with current information about the intervention and all the items in the care plan that are linked to it.
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    3/7/2014
    */
    FUNCTION get_epis_interv_hier_detail
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_nnn_epis_intervention IN nnn_epis_intervention.id_nnn_epis_intervention%TYPE
    ) RETURN json_object_t;

    /**
    * Gets an hierachical detail of the Careplan for a NIC Activity.
    *
    * @param    i_lang                         Professional preferred language
    * @param    i_prof                         Professional identification and its context (institution and software)
    * @param    i_nnn_epis_activity            Careplan's NIC Activity ID
    * @param    i_nnn_epis_intervention        Careplan's NIC Intervention ID
    *
    * @return   json                           JSON document with current information about the activity.
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    3/7/2014
    */
    FUNCTION get_epis_activity_hier_detail
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_nnn_epis_activity IN nnn_epis_activity.id_nnn_epis_activity%TYPE,
        i_nic_intervention  IN nnn_epis_intervention.id_nic_intervention%TYPE
    ) RETURN json_object_t;

    /**
    * Gets an hierachical detail of the Careplan's NANDA Diagnoses
    *
    * @param    i_lang              Professional preferred language
    * @param    i_prof              Professional identification and its context (institution and software)
    * @param    i_patient           Patient ID
    * @param    i_scope             Scope ID (Episode ID; Visit ID; Patient ID)
    * @param    i_scope_type        Scope type (by episode; by visit; by patient)
    *
    * @return   json                JSON document with current information about the diagnoses and all the items in the care plan that are linked to it.
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   03/10/2014
    */
    FUNCTION get_pat_diagnoses_hier_detail
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_scope      IN NUMBER,
        i_scope_type IN VARCHAR2 DEFAULT pk_alert_constant.g_scope_type_episode
    ) RETURN json_object_t;

    /**
    * Retrieves the Scale ID used by an NOC Indicator according with the associated NOC Outcome.
    * The scale descriptions used by NOC indicator depends on the associated NOC outcome. 
    *
    * @param    i_nnn_epis_outcome              Careplan's NOC Outcome ID
    * @param    i_nnn_epis_indicator            Careplan's NOC Indicator ID
    *
    * @return   id_noc_scale                    NOC Scale ID
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    2/5/2014
    */
    FUNCTION get_indicator_scale
    (
        i_nnn_epis_outcome   IN nnn_epis_outcome.id_nnn_epis_outcome%TYPE,
        i_nnn_epis_indicator IN nnn_epis_indicator.id_nnn_epis_indicator%TYPE
    ) RETURN noc_scale.id_noc_scale%TYPE;

    FUNCTION inactivate_nnn_tasks
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_inst      IN institution.id_institution%TYPE,
        o_has_error OUT BOOLEAN,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

END pk_nnn_api_db;
/
