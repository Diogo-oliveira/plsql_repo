/*-- Last Change Revision: $Rev: 2028724 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:33 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_icnp_constant IS
    --------------------------------------------------------------------------------
    -- INSTRUCTION MASK
    --------------------------------------------------------------------------------

    -- Available options (type of information) that can be shown in the text that 
    -- describes the instructions of an ICNP intervention request
    g_inst_format_opt_perform    CONSTANT pk_icnp_type.t_instruction_mask := 'P';
    g_inst_format_opt_frequency  CONSTANT pk_icnp_type.t_instruction_mask := 'F';
    g_inst_format_opt_start_date CONSTANT pk_icnp_type.t_instruction_mask := 'S';
    -- Mask used to define which information appear and in which order when creating
    -- a text that describes the instructions of an ICNP intervention request
    g_inst_format_mask_default CONSTANT pk_icnp_type.t_instruction_mask := g_inst_format_opt_perform ||
                                                                           g_inst_format_opt_start_date ||
                                                                           g_inst_format_opt_frequency;

    --------------------------------------------------------------------------------
    -- ICNP_AXIS
    --------------------------------------------------------------------------------

    -- Set of possible values for the type of axis
    g_axis_focus  CONSTANT icnp_axis.flg_axis%TYPE := 'F';
    g_axis_action CONSTANT icnp_axis.flg_axis%TYPE := 'A';

    --------------------------------------------------------------------------------
    -- ICNP_COMPOSITION
    --------------------------------------------------------------------------------

    -- Set of possible values for the type of term (diagnosis/intervention)
    g_composition_type_action    CONSTANT icnp_composition.flg_type%TYPE := 'A';
    g_composition_type_diagnosis CONSTANT icnp_composition.flg_type%TYPE := 'D';

    -- Set of possible values for the gender associated to a nursing term
    -- (diagnosis/intervention)
    g_composition_gender_male   CONSTANT icnp_composition.flg_gender%TYPE := 'M';
    g_composition_gender_female CONSTANT icnp_composition.flg_gender%TYPE := 'F';
    g_composition_gender_both   CONSTANT icnp_composition.flg_gender%TYPE := 'B';

    --------------------------------------------------------------------------------
    -- ICNP_CPLAN_STAND
    --------------------------------------------------------------------------------

    -- Set of possible values for the status of a standard plan
    g_icnp_cplan_status_active    CONSTANT icnp_cplan_stand.flg_status%TYPE := 'A';
    g_icnp_cplan_status_inactive  CONSTANT icnp_cplan_stand.flg_status%TYPE := 'I';
    g_icnp_cplan_status_cancelled CONSTANT icnp_cplan_stand.flg_status%TYPE := 'C';

    --------------------------------------------------------------------------------
    -- ICNP_CPLAN_STAND_COMPO
    --------------------------------------------------------------------------------

    -- Set of possible values for the type of term (diagnosis, interventions, expected 
    -- result) associated with a standard plan
    g_cp_st_compo_type_diag   CONSTANT icnp_cplan_stand_compo.flg_compo_type%TYPE := 'D';
    g_cp_st_compo_type_interv CONSTANT icnp_cplan_stand_compo.flg_compo_type%TYPE := 'I';
    g_cp_st_compo_type_res    CONSTANT icnp_cplan_stand_compo.flg_compo_type%TYPE := 'R';

    -- Set of possible values of the status of a term associated with a standard plan
    g_cp_st_compo_status_active   CONSTANT icnp_cplan_stand_compo.flg_status%TYPE := 'A';
    g_cp_st_compo_status_inactive CONSTANT icnp_cplan_stand_compo.flg_status%TYPE := 'I';

    --------------------------------------------------------------------------------
    -- ICNP_EPIS_DIAG_INTERV
    --------------------------------------------------------------------------------

    -- Set of possible values of the status of a interv associated with a diag
    g_iedi_st_active   CONSTANT icnp_epis_diag_interv.flg_status%TYPE := 'A';
    g_iedi_st_inactive CONSTANT icnp_epis_diag_interv.flg_status%TYPE := 'I';

    --------------------------------------------------------------------------------
    -- ICNP_EPIS_INTERVENTION
    --------------------------------------------------------------------------------

    -- Set of possible values for the status of an icnp intervention request
    g_epis_interv_status_requested CONSTANT icnp_epis_intervention.flg_status%TYPE := 'A';
    g_epis_interv_status_ongoing   CONSTANT icnp_epis_intervention.flg_status%TYPE := 'E';
    g_epis_interv_status_suspended CONSTANT icnp_epis_intervention.flg_status%TYPE := 'I';
    g_epis_interv_status_executed  CONSTANT icnp_epis_intervention.flg_status%TYPE := 'F';
    g_epis_interv_status_cancelled CONSTANT icnp_epis_intervention.flg_status%TYPE := 'C';
    g_epis_interv_status_discont   CONSTANT icnp_epis_intervention.flg_status%TYPE := 'T';
    g_epis_interv_status_modified  CONSTANT icnp_epis_intervention.flg_status%TYPE := 'M';
    g_epis_interv_status_resolved  CONSTANT icnp_epis_intervention.flg_status%TYPE := 'S'; -- This status is no longer being used; it should be kept for backward compatibility

    -- Set of possible values for the type of frequency of an icnp intervention request
    g_epis_interv_type_once        CONSTANT icnp_epis_intervention.flg_type%TYPE := 'O';
    g_epis_interv_type_no_schedule CONSTANT icnp_epis_intervention.flg_type%TYPE := 'N';
    g_epis_interv_type_recurrence  CONSTANT icnp_epis_intervention.flg_type%TYPE := 'R';

    -- Set of possible values for the flag that indicates when an icnp intervention request 
    -- should be performed 
    g_epis_interv_time_before_epis CONSTANT icnp_epis_intervention.flg_time%TYPE := 'B'; -- Before next episode
    g_epis_interv_time_curr_epis   CONSTANT icnp_epis_intervention.flg_time%TYPE := 'E'; -- Current episode
    g_epis_interv_time_next_epis   CONSTANT icnp_epis_intervention.flg_time%TYPE := 'N'; -- Next episode

    --------------------------------------------------------------------------------
    -- ICNP_EPIS_DIAGNOSIS
    --------------------------------------------------------------------------------

    -- Set of possible values for the status of an icnp diagnosis request
    g_epis_diag_status_active      CONSTANT icnp_epis_diagnosis.flg_status%TYPE := 'A';
    g_epis_diag_status_resolved    CONSTANT icnp_epis_diagnosis.flg_status%TYPE := 'S';
    g_epis_diag_status_cancelled   CONSTANT icnp_epis_diagnosis.flg_status%TYPE := 'C';
    g_epis_diag_status_suspended   CONSTANT icnp_epis_diagnosis.flg_status%TYPE := 'T';
    g_epis_diag_status_revaluated  CONSTANT icnp_epis_diagnosis.flg_status%TYPE := 'R';
    g_epis_diag_status_discontinue CONSTANT icnp_epis_diagnosis.flg_status%TYPE := 'I';
    g_epis_diag_status_in_progress CONSTANT icnp_epis_diagnosis.flg_status%TYPE := 'E';

    --------------------------------------------------------------------------------
    -- ICNP_INTERV_PLAN (EXECUTIONS)
    --------------------------------------------------------------------------------

    -- Set of possible values for the status of an icnp intervention execution
    g_interv_plan_status_executed  CONSTANT icnp_interv_plan.flg_status%TYPE := 'A';
    g_interv_plan_status_cancelled CONSTANT icnp_interv_plan.flg_status%TYPE := 'C';
    g_interv_plan_status_pending   CONSTANT icnp_interv_plan.flg_status%TYPE := 'D';
    g_interv_plan_status_requested CONSTANT icnp_interv_plan.flg_status%TYPE := 'R';
    g_interv_plan_status_suspended CONSTANT icnp_interv_plan.flg_status%TYPE := 'I';
    g_interv_plan_status_freq_alt  CONSTANT icnp_interv_plan.flg_status%TYPE := 'M';
    g_interv_plan_status_not_exec  CONSTANT icnp_interv_plan.flg_status%TYPE := 'N';
    g_interv_plan_status_ongoing   CONSTANT icnp_interv_plan.flg_status%TYPE := 'E';

    g_interv_plan_executing CONSTANT icnp_interv_plan.flg_status%TYPE := 'E';
    g_interv_plan_editing   CONSTANT icnp_interv_plan.flg_status%TYPE := 'M';

    --------------------------------------------------------------------------------
    -- ICNP_SUGGEST_INTERV
    --------------------------------------------------------------------------------

    -- Set of possible values for the status of an intervention that was suggested
    -- based on a set of rules
    g_sug_interv_status_suggested CONSTANT icnp_suggest_interv.flg_status%TYPE := 'S';
    g_sug_interv_status_accepted  CONSTANT icnp_suggest_interv.flg_status%TYPE := 'A';
    g_sug_interv_status_canceled  CONSTANT icnp_suggest_interv.flg_status%TYPE := 'C';
    g_sug_interv_status_rejected  CONSTANT icnp_suggest_interv.flg_status%TYPE := 'R';

    --------------------------------------------------------------------------------
    -- TI_LOG
    --------------------------------------------------------------------------------

    -- Set of possible values of the type of record of the information exchange (TI)
    -- FIXME: This set of values could be defined in its own package
    g_ti_log_type_interv CONSTANT ti_log.flg_type%TYPE := 'NI';
    g_ti_log_type_diag   CONSTANT ti_log.flg_type%TYPE := 'ND';

    --------------------------------------------------------------------------------
    -- DOMAINS
    --------------------------------------------------------------------------------

    -- Domains used by the icnp functionality
    g_domain_epis_interv_type   CONSTANT sys_domain.code_domain%TYPE := 'ICNP_EPIS_INTERVENTION.FLG_TYPE';
    g_domain_epis_interv_prn    CONSTANT sys_domain.code_domain%TYPE := 'ICNP_EPIS_INTERVENTION.FLG_PRN';
    g_domain_epis_interv_time   CONSTANT sys_domain.code_domain%TYPE := 'ICNP_EPIS_INTERVENTION.FLG_TIME';
    g_domain_epis_interv_status CONSTANT sys_domain.code_domain%TYPE := 'ICNP_EPIS_INTERVENTION.FLG_STATUS';
    g_domain_epis_diag_status   CONSTANT sys_domain.code_domain%TYPE := 'ICNP_EPIS_DIAGNOSIS.FLG_STATUS';
    g_domain_interv_plan_status CONSTANT sys_domain.code_domain%TYPE := 'ICNP_INTERV_PLAN.FLG_STATUS';
    g_domain_compo_type         CONSTANT sys_domain.code_domain%TYPE := 'ICNP_COMPOSITION.FLG_TYPE';
    g_domain_default_instr_prn  CONSTANT sys_domain.code_domain%TYPE := 'ICNP_DEFAULT_INSTRUCTIONS_MSI.FLG_PRN';
    g_domain_default_instr_time CONSTANT sys_domain.code_domain%TYPE := 'ICNP_DEFAULT_INSTRUCTIONS_MSI.FLG_TIME';

    --------------------------------------------------------------------------------
    -- ACTIONS
    --------------------------------------------------------------------------------

    -- Action subjects
    g_action_subject_diag        CONSTANT action.subject%TYPE := 'ICNP_DIAG';
    g_action_subject_interv      CONSTANT action.subject%TYPE := 'ICNP_INTERV';
    g_action_subject_interv_exec CONSTANT action.subject%TYPE := 'ICNP_INTERV_EXEC';

    -- Actions associated with icnp diagnosis
    g_action_diag_reeval     CONSTANT action.internal_name%TYPE := 'DIAG_REEVAL';
    g_action_diag_resolve    CONSTANT action.internal_name%TYPE := 'DIAG_RESOLVE';
    g_action_diag_pause      CONSTANT action.internal_name%TYPE := 'DIAG_PAUSE';
    g_action_diag_resume     CONSTANT action.internal_name%TYPE := 'DIAG_RESUME';
    g_action_diag_cancel     CONSTANT action.internal_name%TYPE := 'DIAG_CANCEL';
    g_action_diag_add_interv CONSTANT action.internal_name%TYPE := 'DIAG_ADD_INTERV';

    -- Actions associated with icnp interventions
    g_action_interv_exec      CONSTANT action.internal_name%TYPE := 'INTERV_EXEC';
    g_action_interv_resolve   CONSTANT action.internal_name%TYPE := 'INTERV_RESOLVE';
    g_action_interv_discont   CONSTANT action.internal_name%TYPE := 'INTERV_DISCONT';
    g_action_interv_pause     CONSTANT action.internal_name%TYPE := 'INTERV_PAUSE';
    g_action_interv_resume    CONSTANT action.internal_name%TYPE := 'INTERV_RESUME';
    g_action_interv_cancel    CONSTANT action.internal_name%TYPE := 'INTERV_CANCEL';
    g_action_interv_canc_exec CONSTANT action.internal_name%TYPE := 'INTERV_CANCEL_EXEC';
    g_action_interv_add_diag  CONSTANT action.internal_name%TYPE := 'INTERV_ADD_DIAG';
    g_action_interv_edit      CONSTANT action.internal_name%TYPE := 'INTERV_EDIT'; -- :TODO: The edit must be disabled because is not yet possible to edit a recurrence 

    -- Actions associated with icnp intervention executions
    g_action_exec_execute CONSTANT action.internal_name%TYPE := 'INTERV_EXEC';
    g_action_exec_cancel  CONSTANT action.internal_name%TYPE := 'INTERV_CANCEL_EXEC';

    --------------------------------------------------------------------------------
    -- RECURRENCE
    --------------------------------------------------------------------------------

    g_order_recurr_area CONSTANT order_recurr_area.internal_name%TYPE := 'ICNP';

    --------------------------------------------------------------------------------
    -- SHORTCUTS
    --------------------------------------------------------------------------------

    -- Shortcuts used by the icnp functionality
    g_ss_in_grid_icnp_diag   CONSTANT sys_shortcut.intern_name%TYPE := 'GRID_ICNP_DIAG';
    g_ss_in_grid_icnp_interv CONSTANT sys_shortcut.intern_name%TYPE := 'GRID_ICNP_INTERV';

    --------------------------------------------------------------------------------
    -- ALERTS
    --------------------------------------------------------------------------------

    g_icnp_alert                  CONSTANT sys_alert.id_sys_alert%TYPE := 21;
    g_alert_therapeutic_attitudes CONSTANT sys_alert.id_sys_alert%TYPE := 104;

    --------------------------------------------------------------------------------
    -- SYS_CONFIG
    --------------------------------------------------------------------------------

    -- Indicates if the therapeutic attitudes (icnp suggestions) should be created
    -- when a given request is created in other ALERT areas
    g_config_nurse_trigg_ther_att CONSTANT sys_config.value%TYPE := 'NURSE_TRIGGERS_THERAPEUTIC_ATTITUDES';

    -- Indicates how the plan should be calculated
    -- PLANNED_DATE: when an execution is made, the plan remains as planned (no changes 
    --               are made)
    -- SYSTEM_DATE: when an execution is made, the plan is reajusted; the next executions
    --              are recalculated based on the execution date
    g_config_plan_calc_mode       CONSTANT sys_config.id_sys_config%TYPE := 'CIPE_START_DATE';
    g_plan_calc_mode_planned_date CONSTANT sys_config.value%TYPE := 'PLANNED_DATE';
    g_plan_calc_mode_system_date  CONSTANT sys_config.value%TYPE := 'SYSTEM_DATE';

    --------------------------------------------------------------------------------
    -- MESSAGE CODES
    --------------------------------------------------------------------------------

    -- Message codes used by the icnp functionality
    mcodet_to_be_exec            CONSTANT sys_message.code_message%TYPE := 'CIPE_T132';
    mcodet_frequency             CONSTANT sys_message.code_message%TYPE := 'CIPE_T133';
    mcodet_start_date            CONSTANT sys_message.code_message%TYPE := 'CIPE_T134';
    mcodet_assoc_interv          CONSTANT sys_message.code_message%TYPE := 'ICNP_T052';
    mcodet_diagnosis             CONSTANT sys_message.code_message%TYPE := 'ICNP_T005';
    mcodet_exp_results           CONSTANT sys_message.code_message%TYPE := 'CPLAN_T102';
    mcodet_warning               CONSTANT sys_message.code_message%TYPE := 'COMMON_T013';
    mcodet_intervs_already_assoc CONSTANT sys_message.code_message%TYPE := 'CPLAN_T114';

    --------------------------------------------------------------------------------
    -- EXCEPTIONS
    --------------------------------------------------------------------------------

    g_excep_inv_input_params      CONSTANT pk_icnp_type.t_exception_name := 'INVALID-INPUT-PARAMETERS';
    g_excep_null_identifier       CONSTANT pk_icnp_type.t_exception_name := 'NULL-IDENTIFIER';
    g_excep_count_mismatch        CONSTANT pk_icnp_type.t_exception_name := 'COUNT-MISMATCH';
    g_excep_inv_status_transition CONSTANT pk_icnp_type.t_exception_name := 'INVALID-STATUS-TRANSITION';
    g_excep_unexpected_error      CONSTANT pk_icnp_type.t_exception_name := 'UNEXPECTED-ERROR';
    g_excep_not_implemented       CONSTANT pk_icnp_type.t_exception_name := 'NOT-IMPLEMENTED';

    --------------------------------------------------------------------------------
    -- GENERAL
    --------------------------------------------------------------------------------

    -- Identifiers used to represent all the institutions and all the softwares
    -- FIXME: This set of values could be defined in its own package
    g_institution_all CONSTANT institution.id_institution%TYPE := 0;
    g_software_all    CONSTANT software.id_software%TYPE := 0;

    -- Text construction constants
    g_word_sep        CONSTANT VARCHAR2(2 CHAR) := '; ';
    g_word_end        CONSTANT VARCHAR2(1 CHAR) := '.';
    g_word_no_record  CONSTANT VARCHAR2(3 CHAR) := '---';
    g_word_space      CONSTANT VARCHAR2(1 CHAR) := ' ';
    g_word_open_brac  CONSTANT VARCHAR2(1 CHAR) := '(';
    g_word_close_brac CONSTANT VARCHAR2(1 CHAR) := ')';

    -- Set of possible values of the i_flg parameter of the get_icnp_validation_flag 
    -- method
    g_icnp_focus     CONSTANT VARCHAR2(20 CHAR) := 'FOCUS';
    g_icnp_action    CONSTANT VARCHAR2(20 CHAR) := 'ACTION';
    g_icnp_judgement CONSTANT VARCHAR2(20 CHAR) := 'JUDGEMENT';

    --------------------------------------------------------------------------------
    -- :TODO: DEPRECATED: REMOVE AFTER MIGRATION
    --------------------------------------------------------------------------------

    -- Domains
    g_domain_deprecated_interval CONSTANT sys_domain.code_domain%TYPE := 'ICNP_EPIS_INTERVENTION.FLG_INTERVAL_UNIT';
    g_domain_deprecated_duration CONSTANT sys_domain.code_domain%TYPE := 'ICNP_EPIS_INTERVENTION.FLG_DURATION_UNIT';

    -- Intervention types
    g_interv_type_deprecated_sos  CONSTANT icnp_epis_intervention.flg_type%TYPE := 'S';
    g_interv_type_deprecated_nor  CONSTANT icnp_epis_intervention.flg_type%TYPE := 'N';
    g_interv_type_deprecated_uni  CONSTANT icnp_epis_intervention.flg_type%TYPE := 'U';
    g_interv_type_deprecated_cont CONSTANT icnp_epis_intervention.flg_type%TYPE := 'C';
    g_interv_type_deprecated_eter CONSTANT icnp_epis_intervention.flg_type%TYPE := 'A';

    --------------------------------------------------------------------------------
    --ICNP_EPIS_DIAG_INTERV.FLG_STATUS_REL
    --------------------------------------------------------------------------------  
    g_interv_rel_active       CONSTANT icnp_epis_diag_interv.flg_status_rel%TYPE := 'A';
    g_interv_rel_cancel       CONSTANT icnp_epis_diag_interv.flg_status_rel%TYPE := 'C';
    g_interv_rel_hold         CONSTANT icnp_epis_diag_interv.flg_status_rel%TYPE := 'H';
    g_interv_rel_discontinued CONSTANT icnp_epis_diag_interv.flg_status_rel%TYPE := 'I';
    g_interv_rel_reactivated  CONSTANT icnp_epis_diag_interv.flg_status_rel%TYPE := 'R';

    --------------------------------------------------------------------------------
    --ICNP_EPIS_DIAG_INTERV.FLG_STATUS
    --------------------------------------------------------------------------------  
    g_interv_flg_status_a CONSTANT icnp_epis_diag_interv.flg_status%TYPE := 'A';
    g_interv_flg_status_i CONSTANT icnp_epis_diag_interv.flg_status%TYPE := 'I';

    --------------------------------------------------------------------------------
    -- ICNP_EPIS_DG_INT_HIST.FLG_IUD
    -------------------------------------------------------------------------------- 
    g_iedih_flg_uid_i CONSTANT icnp_epis_dg_int_hist.flg_iud%TYPE := 'I';
    g_iedih_flg_uid_u CONSTANT icnp_epis_dg_int_hist.flg_iud%TYPE := 'U';
    g_iedih_flg_uid_d CONSTANT icnp_epis_dg_int_hist.flg_iud%TYPE := 'D';

    --------------------------------------------------------------------------------
    --ICNP_EPIS_DIAG_INTERV.FLG_MOMENT_ASSOC
    --------------------------------------------------------------------------------  
    g_moment_assoc_c CONSTANT icnp_epis_diag_interv.flg_moment_assoc%TYPE := 'C';
    g_moment_assoc_a CONSTANT icnp_epis_diag_interv.flg_moment_assoc%TYPE := 'A';

    --------------------------------------------------------------------------------
    --ICNP_EPIS_DIAG_INTERV.FLG_TYPE_ASSOC
    --------------------------------------------------------------------------------  
    g_flg_type_assoc_d CONSTANT icnp_epis_diag_interv.flg_type_assoc%TYPE := 'D';
    g_flg_type_assoc_i CONSTANT icnp_epis_diag_interv.flg_type_assoc%TYPE := 'I';

    g_diagnosis            CONSTANT VARCHAR2(1 CHAR) := 'D';
    g_therapeutic_attitude CONSTANT VARCHAR2(1 CHAR) := 'S';

    -- Area used by Touch-option templates related to ICNP
    g_doc_area_icnp CONSTANT doc_area.id_doc_area%TYPE := 43;

END pk_icnp_constant;
/
