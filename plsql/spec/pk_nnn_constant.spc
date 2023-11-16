/*-- Last Change Revision: $Rev: 1658137 $*/
/*-- Last Change by: $Author: ariel.machado $*/
/*-- Date of last change: $Date: 2014-11-10 11:21:37 +0000 (seg, 10 nov 2014) $*/

CREATE OR REPLACE PACKAGE pk_nnn_constant IS

    -- Author  : ARIEL.MACHADO
    -- Created : 4/21/2014 11:51:57 AM
    -- Purpose : Nursing Care Plan (NANDA/NIC/NOC) Constants

    -- Public constant declarations

    -- NANDA-I Nursing Diagnosis Terminology 
    g_terminology_nanda        CONSTANT terminology.internal_name%TYPE := 'NANDA-I';
    g_terminology_nic          CONSTANT terminology.internal_name%TYPE := 'NIC'; -- Nursing Interventions Classification (NIC) Terminology
    g_terminology_noc          CONSTANT terminology.internal_name%TYPE := 'NOC'; -- Nursing Outcomes Classification (NOC) Terminology
    g_terminology_nnn_linkages CONSTANT terminology.internal_name%TYPE := 'NNN-Linkages'; -- Linkages of NANDA-I, NIC and NOC (NNN) Terminology

    g_task_type_nursing_careplan CONSTANT task_type.id_task_type%TYPE := 66; -- Nursing Care Plan
    g_task_type_nanda            CONSTANT task_type.id_task_type%TYPE := 67; -- Nursing Diagnosis (NANDA)
    g_task_type_noc              CONSTANT task_type.id_task_type%TYPE := 68; -- Nursing Outcomes (NOC)
    g_task_type_nic              CONSTANT task_type.id_task_type%TYPE := 69; -- Nursing Interventions (NIC)
    g_task_type_nnn_linkages     CONSTANT task_type.id_task_type%TYPE := 70; -- NANDA-I, NIC and NOC Linkages (NNN)

    g_ordrecurr_area_noc_outcome   CONSTANT order_recurr_area.internal_name%TYPE := 'NNN_NOC_OUTCOME'; -- Order Recurrence Area for NOC Outcomes
    g_ordrecurr_area_noc_indicator CONSTANT order_recurr_area.internal_name%TYPE := 'NNN_NOC_INDICATOR'; -- Order Recurrence Area for NOC Indicators
    g_ordrecurr_area_nic_activity  CONSTANT order_recurr_area.internal_name%TYPE := 'NNN_NIC_ACTIVITY'; -- Order Recurrence Area for NIC Activities

    g_interv_lnk_level_major     CONSTANT nan_nic_linkage.flg_link_type%TYPE := 'M'; --    Major Intervention
    g_interv_lnk_level_optional  CONSTANT nan_nic_linkage.flg_link_type%TYPE := 'O'; --    Optional Intervention
    g_interv_lnk_level_suggested CONSTANT nan_nic_linkage.flg_link_type%TYPE := 'S'; --    Suggested Intervention

    g_outcome_lnk_level_additional CONSTANT nan_noc_linkage.flg_link_type%TYPE := 'A'; --    Additional Outcome
    g_outcome_lnk_level_suggested  CONSTANT nan_noc_linkage.flg_link_type%TYPE := 'S'; --    Suggested Outcome

    g_time_performed_between   CONSTANT nnn_epis_activity.flg_time%TYPE := 'B'; --    To be performed in date to be determined
    g_time_performed_episode   CONSTANT nnn_epis_activity.flg_time%TYPE := 'E'; --    To be performed in current episode
    g_time_performed_next_epis CONSTANT nnn_epis_activity.flg_time%TYPE := 'N'; --    To be performed in the next episode

    g_priority_emergent CONSTANT nnn_epis_activity.flg_priority%TYPE := 'E'; --    Priority Emergent
    g_priority_normal   CONSTANT nnn_epis_activity.flg_priority%TYPE := 'N'; --    Priority Normal
    g_priority_urgent   CONSTANT nnn_epis_activity.flg_priority%TYPE := 'U'; --    Priority Urgent

    g_doc_type_template      CONSTANT nnn_epis_activity.flg_doc_type%TYPE := 'T'; -- Type of documentation used when a NIC Activity is executed: (T)ouch-option templates
    g_doc_type_vital_sign    CONSTANT nnn_epis_activity.flg_doc_type%TYPE := 'V'; -- Type of documentation used when a NIC Activity is executed: (V)ital signs
    g_doc_type_free_textnote CONSTANT nnn_epis_activity.flg_doc_type%TYPE := 'N'; -- Type of documentation used when a NIC Activity is executed: Free-text (N)otes

    g_req_status_cancelled    CONSTANT nnn_epis_activity.flg_req_status%TYPE := 'C'; --    Request Cancelled
    g_req_status_draft        CONSTANT nnn_epis_activity.flg_req_status%TYPE := 'D'; --    Request Draft
    g_req_status_expired      CONSTANT nnn_epis_activity.flg_req_status%TYPE := 'E'; --    Request Expired
    g_req_status_finished     CONSTANT nnn_epis_activity.flg_req_status%TYPE := 'F'; --    Request Finished
    g_req_status_ignored      CONSTANT nnn_epis_activity.flg_req_status%TYPE := 'I'; --    Request Ignored
    g_req_status_ongoing      CONSTANT nnn_epis_activity.flg_req_status%TYPE := 'O'; --    Request Ongoing
    g_req_status_ordered      CONSTANT nnn_epis_activity.flg_req_status%TYPE := 'R'; --    Request Ordered
    g_req_status_suggested    CONSTANT nnn_epis_activity.flg_req_status%TYPE := 'S'; --    Request Suggested
    g_req_status_suspended    CONSTANT nnn_epis_activity.flg_req_status%TYPE := 'P'; --    Request Suspended
    g_req_status_discontinued CONSTANT nnn_epis_activity.flg_req_status%TYPE := 'T'; --    Request Discontinued
    g_req_status_filter_any   CONSTANT VARCHAR(10 CHAR) := g_req_status_cancelled || g_req_status_draft ||
                                                           g_req_status_expired || g_req_status_finished ||
                                                           g_req_status_ignored || g_req_status_ongoing ||
                                                           g_req_status_ordered || g_req_status_suggested ||
                                                           g_req_status_suspended || g_req_status_discontinued; -- Request status filter: Any status

    g_task_status_cancelled  CONSTANT nnn_epis_activity_det.flg_status%TYPE := 'C'; --    Activity/Evaluation Cancelled
    g_task_status_expired    CONSTANT nnn_epis_activity_det.flg_status%TYPE := 'E'; --    Activity/Evaluation Expired
    g_task_status_finished   CONSTANT nnn_epis_activity_det.flg_status%TYPE := 'F'; --    Activity/Evaluation Finished
    g_task_status_ongoing    CONSTANT nnn_epis_activity_det.flg_status%TYPE := 'O'; --    Activity/Evaluation Ongoing
    g_task_status_ordered    CONSTANT nnn_epis_activity_det.flg_status%TYPE := 'R'; --    Activity/Evaluation Ordered
    g_task_status_suspended  CONSTANT nnn_epis_activity_det.flg_status%TYPE := 'P'; --    Activity/Evaluation Suspended
    g_task_status_filter_any CONSTANT VARCHAR(10 CHAR) := g_task_status_cancelled || g_task_status_expired ||
                                                          g_task_status_finished || g_task_status_ongoing ||
                                                          g_task_status_ordered || g_task_status_suspended; -- Task status filter: Any status

    g_diagnosis_status_active    CONSTANT nnn_epis_diag_eval.flg_status%TYPE := 'A'; --    Diagnosis Active
    g_diagnosis_status_cancelled CONSTANT nnn_epis_diag_eval.flg_status%TYPE := 'C'; --    Diagnosis Cancelled
    g_diagnosis_status_inactive  CONSTANT nnn_epis_diag_eval.flg_status%TYPE := 'I'; --    Diagnosis Inactive
    g_diagnosis_status_resolved  CONSTANT nnn_epis_diag_eval.flg_status%TYPE := 'R'; --    Diagnosis Resolved

    -- Domain - NNN

    g_dom_epis_act_flg_priority   CONSTANT sys_domain.code_domain%TYPE := 'NNN_EPIS_ACTIVITY.FLG_PRIORITY';
    g_dom_epis_act_flg_prn        CONSTANT sys_domain.code_domain%TYPE := 'NNN_EPIS_ACTIVITY.FLG_PRN';
    g_dom_epis_act_flg_req_status CONSTANT sys_domain.code_domain%TYPE := 'NNN_EPIS_ACTIVITY.FLG_REQ_STATUS';
    g_dom_epis_act_flg_time       CONSTANT sys_domain.code_domain%TYPE := 'NNN_EPIS_ACTIVITY.FLG_TIME';
    g_dom_epis_act_det_flg_status CONSTANT sys_domain.code_domain%TYPE := 'NNN_EPIS_ACTIVITY_DET.FLG_STATUS';
    g_dom_epis_act_d_tsk_flg_exec CONSTANT sys_domain.code_domain%TYPE := 'NNN_EPIS_ACTV_DET_TASK.FLG_EXECUTED';

    g_dom_epis_diag_flg_req_status CONSTANT sys_domain.code_domain%TYPE := 'NNN_EPIS_DIAGNOSIS.FLG_REQ_STATUS';
    g_dom_epis_diag_evl_flg_status CONSTANT sys_domain.code_domain%TYPE := 'NNN_EPIS_DIAG_EVAL.FLG_STATUS';

    g_dom_epis_ind_flg_priority   CONSTANT sys_domain.code_domain%TYPE := 'NNN_EPIS_INDICATOR.FLG_PRIORITY';
    g_dom_epis_ind_flg_prn        CONSTANT sys_domain.code_domain%TYPE := 'NNN_EPIS_INDICATOR.FLG_PRN';
    g_dom_epis_ind_flg_req_status CONSTANT sys_domain.code_domain%TYPE := 'NNN_EPIS_INDICATOR.FLG_REQ_STATUS';
    g_dom_epis_ind_flg_time       CONSTANT sys_domain.code_domain%TYPE := 'NNN_EPIS_INDICATOR.FLG_TIME';
    g_dom_epis_ind_evl_flg_status CONSTANT sys_domain.code_domain%TYPE := 'NNN_EPIS_IND_EVAL.FLG_STATUS';

    g_dom_epis_int_flg_req_status CONSTANT sys_domain.code_domain%TYPE := 'NNN_EPIS_INTERVENTION.FLG_REQ_STATUS';

    g_dom_epis_out_flg_priority   CONSTANT sys_domain.code_domain%TYPE := 'NNN_EPIS_OUTCOME.FLG_PRIORITY';
    g_dom_epis_out_flg_prn        CONSTANT sys_domain.code_domain%TYPE := 'NNN_EPIS_OUTCOME.FLG_PRN';
    g_dom_epis_out_flg_req_status CONSTANT sys_domain.code_domain%TYPE := 'NNN_EPIS_OUTCOME.FLG_REQ_STATUS';
    g_dom_epis_out_flg_time       CONSTANT sys_domain.code_domain%TYPE := 'NNN_EPIS_OUTCOME.FLG_TIME';
    g_dom_epis_out_evl_flg_status CONSTANT sys_domain.code_domain%TYPE := 'NNN_EPIS_OUTCOME_EVAL.FLG_STATUS';

    -- order recurrence options
    g_order_recurr_option_once    CONSTANT order_recurr_option.id_order_recurr_option%TYPE := 0;
    g_order_recurr_option_no_sch  CONSTANT order_recurr_option.id_order_recurr_option%TYPE := -2;
    g_dom_order_rec_option_once   CONSTANT sys_domain.code_domain%TYPE := 'ORDER_RECURR_OPTION.CODE_ORDER_RECURR_OPTION.0';
    g_dom_order_rec_option_no_sch CONSTANT sys_domain.code_domain%TYPE := 'ORDER_RECURR_OPTION.CODE_ORDER_RECURR_OPTION.-2';

    -- Set of possible values for the type of frequency of a request (translates the id_order_recurr_option)
    g_req_freq_once        CONSTANT pk_types.t_flg_char := 'O'; -- Request with frequency once (id_order_recurr_option = 0)
    g_req_freq_no_schedule CONSTANT pk_types.t_flg_char := 'N'; -- Request with no scheduled (id_order_recurr_option = -2)
    g_req_freq_recurrence  CONSTANT pk_types.t_flg_char := 'R'; -- Request with recurrency plan (id_order_recurr_option NOT IN(0, -2)  )

    g_mcode_priority      CONSTANT sys_message.code_message%TYPE := 'NNN_INSTRUCT_T002'; -- Priority:
    g_mcode_to_be_perform CONSTANT sys_message.code_message%TYPE := 'NNN_INSTRUCT_T003'; -- To be performed:
    g_mcode_prn           CONSTANT sys_message.code_message%TYPE := 'NNN_INSTRUCT_T004'; -- PRN:
    g_mcode_prn_cond      CONSTANT sys_message.code_message%TYPE := 'NNN_INSTRUCT_T005'; -- PRN condition:
    g_mcode_frequency     CONSTANT sys_message.code_message%TYPE := 'NNN_INSTRUCT_T006'; -- Frequency:
    g_mcode_start_date    CONSTANT sys_message.code_message%TYPE := 'NNN_INSTRUCT_T007'; -- Start date:

    -- status string
    g_type_diagnosis_eval CONSTANT pk_types.t_low_char := 'DE';
    g_type_outcome        CONSTANT pk_types.t_low_char := 'O';
    g_type_outcome_eval   CONSTANT pk_types.t_low_char := 'OE';
    g_type_indicator      CONSTANT pk_types.t_low_char := 'I';
    g_type_indicator_eval CONSTANT pk_types.t_low_char := 'IE';
    g_type_intervention   CONSTANT pk_types.t_low_char := 'IV';
    g_type_activity       CONSTANT pk_types.t_low_char := 'A';
    g_type_activity_det   CONSTANT pk_types.t_low_char := 'AD';
    g_type_filter_req_any CONSTANT pk_types.t_low_char := g_type_outcome || g_type_indicator || g_type_activity;

    g_mcode_icon_sos       CONSTANT sys_message.code_message%TYPE := 'COMMON_M112';
    g_mcode_style_msg_sos  CONSTANT sys_message.code_message%TYPE := 'IconRendererMessage';
    g_mcode_icon_scheduled CONSTANT sys_message.code_message%TYPE := 'ICON_T056';

    -- Labels used in Content help

    g_mcode_nanda                 CONSTANT sys_message.code_message%TYPE := 'NNN_CONTENT_M001'; -- NANDA-I Diagnosis:                
    g_mcode_nanda_code            CONSTANT sys_message.code_message%TYPE := 'NNN_CONTENT_M002'; -- Diagnosis Code:                
    g_mcode_approved              CONSTANT sys_message.code_message%TYPE := 'NNN_CONTENT_M003'; -- Approved:                       
    g_mcode_revised               CONSTANT sys_message.code_message%TYPE := 'NNN_CONTENT_M004'; -- Revised:                       
    g_mcode_loe                   CONSTANT sys_message.code_message%TYPE := 'NNN_CONTENT_M005'; -- Level of Evidence:               
    g_mcode_definition            CONSTANT sys_message.code_message%TYPE := 'NNN_CONTENT_M006'; -- Definition:                   
    g_mcode_domain                CONSTANT sys_message.code_message%TYPE := 'NNN_CONTENT_M007'; -- Domain:                        
    g_mcode_class                 CONSTANT sys_message.code_message%TYPE := 'NNN_CONTENT_M008'; -- Class:                            
    g_mcode_references            CONSTANT sys_message.code_message%TYPE := 'NNN_CONTENT_M009'; -- References:                   
    g_mcode_noc                   CONSTANT sys_message.code_message%TYPE := 'NNN_CONTENT_M010'; -- Nursing Outcomes Classification:    
    g_mcode_noc_code              CONSTANT sys_message.code_message%TYPE := 'NNN_CONTENT_M011'; -- Outcome Code:                    
    g_mcode_nic                   CONSTANT sys_message.code_message%TYPE := 'NNN_CONTENT_M012'; -- Nursing Interventions Classification:  
    g_mcode_nic_code              CONSTANT sys_message.code_message%TYPE := 'NNN_CONTENT_M013'; -- Intervention Code:               
    g_mcode_noc_scale             CONSTANT sys_message.code_message%TYPE := 'NNN_CONTENT_M014'; -- Scale:
    g_mcode_terminology_info      CONSTANT sys_message.code_message%TYPE := 'COMMON_T038'; -- Terminology information
    g_mcode_terminology_name      CONSTANT sys_message.code_message%TYPE := 'COMMON_T039'; -- Name
    g_mcode_terminology_version   CONSTANT sys_message.code_message%TYPE := 'COMMON_T041'; -- Version
    g_mcode_terminology_copyright CONSTANT sys_message.code_message%TYPE := 'COMMON_T042'; -- Copyright

    -- Touch-Option documentation area: Nursing Care Plan - Documentation of NIC Activities
    g_doc_area_nic_activity CONSTANT doc_area.id_doc_area%TYPE := 2014;
    --------------------------------------------------------------------------------
    -- EXCEPTIONS
    --------------------------------------------------------------------------------

    -- The exception that is thrown when one of the arguments provided to a method is not valid.
    e_invalid_argument EXCEPTION;

    --A call to a procedure or function API returns an error
    e_call_error EXCEPTION;

    g_excep_inv_input_params      CONSTANT pk_types.t_low_char := 'INVALID-INPUT-PARAMETERS';
    g_excep_null_identifier       CONSTANT pk_types.t_low_char := 'NULL-IDENTIFIER';
    g_excep_inv_status_transition CONSTANT pk_types.t_low_char := 'INVALID-STATUS-TRANSITION';
    g_excep_unexpected_error      CONSTANT pk_types.t_low_char := 'UNEXPECTED-ERROR';
    g_excep_not_implemented       CONSTANT pk_types.t_low_char := 'NOT-IMPLEMENTED';

    --------------------------------------------------------------------------------
    -- INSTRUCTION MASK
    --------------------------------------------------------------------------------

    -- Available options (type of information) that can be shown in the text that 
    -- describes the instructions of an NNN Outcome/Indicator/Activity request
    g_inst_format_opt_priority     CONSTANT pk_translation.t_flg_char := 'P';
    g_inst_format_opt_time_perform CONSTANT pk_translation.t_flg_char := 'T';
    g_inst_format_opt_prn          CONSTANT pk_translation.t_flg_char := 'R';
    g_inst_format_opt_frequency    CONSTANT pk_translation.t_flg_char := 'F';
    g_inst_format_opt_start_date   CONSTANT pk_translation.t_flg_char := 'S';
    -- Mask used to define which information appear and in which order when creating
    -- a text that describes the instructions of an NNN Outcome/Indicator/Activity request
    g_inst_format_mask_default CONSTANT pk_translation.t_low_char := g_inst_format_opt_priority ||
                                                                     g_inst_format_opt_time_perform ||
                                                                     g_inst_format_opt_prn ||
                                                                     g_inst_format_opt_frequency ||
                                                                     g_inst_format_opt_start_date;

    -- Cancel Reasons

    -- Cancel reasons for NANDA Diagnosis
    g_cancel_rea_area_diag cancel_rea_area.intern_name%TYPE := 'NNN_DIAG_CANCEL';
    -- Cancel reasons for NOC Outcome
    g_cancel_rea_area_outcome cancel_rea_area.intern_name%TYPE := 'NNN_OUTCOME_CANCEL';
    -- Cancel reasons for NOC Indicator
    g_cancel_rea_area_indicator cancel_rea_area.intern_name%TYPE := 'NNN_INDICATOR_CANCEL';
    -- Cancel reasons for NIC Intervention    
    g_cancel_rea_area_intervention cancel_rea_area.intern_name%TYPE := 'NNN_INTERVENTION_CANCEL';
    -- Cancel reasons for NIC Activity
    g_cancel_rea_area_activity cancel_rea_area.intern_name%TYPE := 'NNN_ACTIVITY_CANCEL';

    --Type of information to obtain from methods of detail

    -- Current information details   
    g_detail_type_current_info CONSTANT pk_types.t_flg_char := 'D';
    -- History of changes
    g_detail_type_history_changes CONSTANT pk_types.t_flg_char := 'H';

    /* List of actions in the Action Menus for the Patient's Care Plan */

    -- Menu item to Cancel a NANDA Diagnosis within a care plan
    g_action_diagnosis_cancel CONSTANT action.internal_name%TYPE := 'DIAG_CANCEL';
    -- Menu item to Edit a NANDA Diagnosis within a care plan    
    g_action_diagnosis_edit CONSTANT action.internal_name%TYPE := 'DIAG_EDIT';
    -- Menu item to Evaluate a NANDA Diagnosis within a care plan        
    g_action_diagnosis_evaluate CONSTANT action.internal_name%TYPE := 'DIAG_EVALUATE';
    -- Menu item to Link a NANDA Diagnosis within a care plan            
    g_action_diagnosis_link CONSTANT action.internal_name%TYPE := 'DIAG_LINK';
    -- Menu item to Evaluate as Active a NANDA Diagnosis within a care plan                
    g_action_diagnosis_set_activ CONSTANT action.internal_name%TYPE := 'DIAG_SET_ACTIVE';
    -- Menu item to Evaluate as Inactive a NANDA Diagnosis within a care plan                    
    g_action_diagnosis_set_inactiv CONSTANT action.internal_name%TYPE := 'DIAG_SET_INACTIVE';
    -- Menu item to Evaluate as Resolved a NANDA Diagnosis within a care plan
    g_action_diagnosis_set_resolv CONSTANT action.internal_name%TYPE := 'DIAG_SET_RESOLVED';
    -- Menu item to Cancel a NOC Outcome within a care plan    
    g_action_outcome_cancel CONSTANT action.internal_name%TYPE := 'OUTCOME_CANCEL';
    -- Menu item to Edit a NOC Outcome within a care plan        
    g_action_outcome_edit CONSTANT action.internal_name%TYPE := 'OUTCOME_EDIT';
    -- Menu item to Evaluate a NOC Outcome within a care plan            
    g_action_outcome_evaluate CONSTANT action.internal_name%TYPE := 'OUTCOME_EVALUATE';
    -- Menu item to Hold a NOC Outcome within a care plan            
    g_action_outcome_hold CONSTANT action.internal_name%TYPE := 'OUTCOME_HOLD';
    -- Menu item to Link a NOC Outcome within a care plan            
    g_action_outcome_link CONSTANT action.internal_name%TYPE := 'OUTCOME_LINK';
    -- Menu item to Resume a NOC Outcome within a care plan            
    g_action_outcome_resume CONSTANT action.internal_name%TYPE := 'OUTCOME_RESUME';
    -- Menu item to Cancel a NOC Indicator within a care plan
    g_action_indicator_cancel CONSTANT action.internal_name%TYPE := 'INDICATOR_CANCEL';
    -- Menu item to Edit a NOC Indicator within a care plan    
    g_action_indicator_edit CONSTANT action.internal_name%TYPE := 'INDICATOR_EDIT';
    -- Menu item to Evaluate a NOC Indicator within a care plan    
    g_action_indicator_evaluate CONSTANT action.internal_name%TYPE := 'INDICATOR_EVALUATE';
    -- Menu item to Hold a NOC Indicator within a care plan    
    g_action_indicator_hold CONSTANT action.internal_name%TYPE := 'INDICATOR_HOLD';
    -- Menu item to Link a NOC Indicator within a care plan    
    g_action_indicator_link CONSTANT action.internal_name%TYPE := 'INDICATOR_LINK';
    -- Menu item to Resume a NOC Indicator within a care plan    
    g_action_indicator_resume CONSTANT action.internal_name%TYPE := 'INDICATOR_RESUME';
    -- Menu item to Cancel a NIC Intervention within a care plan        
    g_action_intervention_cancel CONSTANT action.internal_name%TYPE := 'INTERVENTION_CANCEL';
    -- Menu item to Hold a NIC Intervention within a care plan
    g_action_intervention_hold CONSTANT action.internal_name%TYPE := 'INTERVENTION_HOLD';
    -- Menu item to Link a NIC Intervention within a care plan
    g_action_intervention_link CONSTANT action.internal_name%TYPE := 'INTERVENTION_LINK';
    -- Menu item to Resume a NIC Intervention within a care plan    
    g_action_intervention_resume CONSTANT action.internal_name%TYPE := 'INTERVENTION_RESUME';
    -- Menu item to Cancel a NIC Activity within a care plan
    g_action_activity_cancel CONSTANT action.internal_name%TYPE := 'ACTIVITY_CANCEL';
    -- Menu item to Edit a NIC Activity within a care plan    
    g_action_activity_edit CONSTANT action.internal_name%TYPE := 'ACTIVITY_EDIT';
    -- Menu item to Execute a NIC Activity within a care plan        
    g_action_activity_execute CONSTANT action.internal_name%TYPE := 'ACTIVITY_EXECUTE';
    -- Menu item to Hold a NIC Activity within a care plan            
    g_action_activity_hold CONSTANT action.internal_name%TYPE := 'ACTIVITY_HOLD';
    -- Menu item to Link a NIC Activity within a care plan                
    g_action_activity_link CONSTANT action.internal_name%TYPE := 'ACTIVITY_LINK';
    -- Menu item to Resume a NIC Activity within a care plan                    
    g_action_activity_resume CONSTANT action.internal_name%TYPE := 'ACTIVITY_RESUME';

    /* List of actions in the Action Menus for timeline items in the Patient's Care Plan */

    -- Menu item to Cancel a NANDA Diagnosis evaluation within a care plan
    g_action_diagnosis_eval_cancel CONSTANT action.internal_name%TYPE := 'DIAG_EVAL_CANCEL';
    -- Menu item to Edit a NANDA Diagnosis within a care plan    
    g_action_diagnosis_eval_edit CONSTANT action.internal_name%TYPE := 'DIAG_EVAL_EDIT';

    -- Menu item to Cancel a NOC Outcome evaluation within a care plan    
    g_action_outcome_eval_cancel CONSTANT action.internal_name%TYPE := 'OUTCOME_EVAL_CANCEL';
    -- Menu item to Edit a NOC Outcome evaluation within a care plan        
    g_action_outcome_eval_edit CONSTANT action.internal_name%TYPE := 'OUTCOME_EVAL_EDIT';
    -- Menu item to Evaluate a NOC Outcome evaluation within a care plan            
    g_action_outcome_eval_evaluate CONSTANT action.internal_name%TYPE := 'OUTCOME_EVAL_EVALUATE';

    -- Menu item to Cancel a NOC Indicator evaluation within a care plan    
    g_action_indicator_eval_cancel CONSTANT action.internal_name%TYPE := 'INDICATOR_EVAL_CANCEL';
    -- Menu item to Edit a NOC Indicator evaluation within a care plan    
    g_action_indicator_eval_edit CONSTANT action.internal_name%TYPE := 'INDICATOR_EVAL_EDIT';
    -- Menu item to Evaluate a NOC Indicator evaluation within a care plan        
    g_action_indicator_eval_eval CONSTANT action.internal_name%TYPE := 'INDICATOR_EVAL_EVALUATE';

    -- Menu item to Cancel a NIC Activity execution within a care plan
    g_action_activity_exec_cancel CONSTANT action.internal_name%TYPE := 'ACTIVITY_EXEC_CANCEL';
    -- Menu item to Edit a NIC Activity execution within a care plan        
    g_action_activity_exec_edit CONSTANT action.internal_name%TYPE := 'ACTIVITY_EXEC_EDIT';
    -- Menu item to Execute a NIC Activity execution within a care plan        
    g_action_activity_exec_execute CONSTANT action.internal_name%TYPE := 'ACTIVITY_EXEC_EXECUTE';

    -- Shortcut name for Nursing Care Plan area. 
    -- This shortcut is not actually about a "CIPE summary",
    -- but points to a CareplanLoaderView intended to load the right screen.
    g_shortcut_careplan_loaderview CONSTANT sys_shortcut.intern_name%TYPE := 'CIPE_SUMMARY';

    --------------------------------------------------------------------------------
    -- SYS_CONFIG
    --------------------------------------------------------------------------------

    -- Indicates the Nursing Classifications system used in the Nursing Care Plan for nursing diagnoses, expected outcomes/goals, and nursing interventions
    g_config_classification CONSTANT sys_config.id_sys_config%TYPE := 'NURSING_CARE_PLAN_CLASSIFICATION_SYSTEM';
    -- Classifications NNN - NANDA-I, NIC and NOC
    g_classification_nanda_nic_noc CONSTANT sys_config.value%TYPE := 'NNN';
    -- Classifications ICNP - International Classification for Nursing Practice
    g_classification_icnp CONSTANT sys_config.value%TYPE := 'ICNP';

    -- Indicates how the plan should be calculated
    g_config_plan_calc_mode CONSTANT sys_config.id_sys_config%TYPE := 'NURSING_CARE_PLAN_NEXT_START_DATE';
    -- When an evaluation/execution is made, the plan remains as planned (no changes are made)
    g_plan_calc_mode_planned_date CONSTANT sys_config.value%TYPE := 'PLANNED_DATE';
    -- When an evaluation/execution is made, the plan is reajusted; the next executions are recalculated based on the evaluation/execution date
    g_plan_calc_mode_system_date CONSTANT sys_config.value%TYPE := 'SYSTEM_DATE';

    -- Indicates which date is displayed by default when an evaluation/execution is made
    g_config_suggest_exec_date CONSTANT sys_config.id_sys_config%TYPE := 'NURSING_SUGGEST_EXEC_DATE';
    -- When an evaluation/execution is made, displays as default evaluation/execution date the planned date
    g_suggest_exec_planned_date CONSTANT sys_config.value%TYPE := 'Y';
    -- When an evaluation/execution is made, displays as default displays as default evaluation/execution date the current date
    g_suggest_exec_system_date CONSTANT sys_config.value%TYPE := 'N';

    -- System Alert: NOC Outcome is overdue
    g_sys_alert_outcome CONSTANT sys_alert.id_sys_alert%TYPE := 313;
    -- System Alert: NOC Indicator is overdue
    g_sys_alert_indicator CONSTANT sys_alert.id_sys_alert%TYPE := 314;
    -- System Alert: NIC Activity is overdue    
    g_sys_alert_activity CONSTANT sys_alert.id_sys_alert%TYPE := 315;

    -- Past due the configured value expressed in minutes displays an alert notification of overdue tasks in the nursing plan of care
    g_config_alert_task_timeout CONSTANT sys_config.id_sys_config%TYPE := 'ALERT_ICNP_INTERV_TIMEOUT';

    -- Timeline view header date format mask
    g_config_timeline_date_format CONSTANT sys_config.id_sys_config%TYPE := 'NURSING_CARE_PLAN_TIMELINE_HEADER_FORMAT';
END pk_nnn_constant;
/
