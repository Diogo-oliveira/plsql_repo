/*-- Last Change Revision: $Rev: 1746924 $*/
/*-- Last Change by: $Author: vanessa.barsottelli $*/
/*-- Date of last change: $Date: 2016-07-15 11:52:45 +0100 (sex, 15 jul 2016) $*/

CREATE OR REPLACE PACKAGE pk_cdr_constant IS

    -- time measurement units
    g_tmu_minute CONSTANT unit_measure.id_unit_measure%TYPE := 10374;
    g_tmu_hour   CONSTANT unit_measure.id_unit_measure%TYPE := 1041;
    g_tmu_day    CONSTANT unit_measure.id_unit_measure%TYPE := 1039;
    g_tmu_week   CONSTANT unit_measure.id_unit_measure%TYPE := 10375;
    g_tmu_month  CONSTANT unit_measure.id_unit_measure%TYPE := 1127;
    g_tmu_year   CONSTANT unit_measure.id_unit_measure%TYPE := 10373;

    -- rule status
    g_edited CONSTANT cdr_definition.flg_status%TYPE := 'E';

    -- rule origins
    g_origin_local CONSTANT cdr_definition.flg_origin%TYPE := 'L';
    g_origin_def   CONSTANT cdr_definition.flg_origin%TYPE := 'D';

    -- rule condition operators
    g_oper_and CONSTANT cdr_def_cond.flg_condition%TYPE := 'A';
    g_oper_or  CONSTANT cdr_def_cond.flg_condition%TYPE := 'O';

    -- rule concepts
    g_cdrcp_lab_test     CONSTANT cdr_concept.id_cdr_concept%TYPE := 1;
    g_cdrcp_lab_test_par CONSTANT cdr_concept.id_cdr_concept%TYPE := 2;
    g_cdrcp_exam         CONSTANT cdr_concept.id_cdr_concept%TYPE := 3;
    g_cdrcp_diagnosis    CONSTANT cdr_concept.id_cdr_concept%TYPE := 4;
    g_cdrcp_allergy      CONSTANT cdr_concept.id_cdr_concept%TYPE := 5;
    g_cdrcp_sr_proc      CONSTANT cdr_concept.id_cdr_concept%TYPE := 6;
    g_cdrcp_pregnancy    CONSTANT cdr_concept.id_cdr_concept%TYPE := 10;
    g_cdrcp_age          CONSTANT cdr_concept.id_cdr_concept%TYPE := 11;
    g_cdrcp_gender       CONSTANT cdr_concept.id_cdr_concept%TYPE := 12;
    g_cdrcp_procedure    CONSTANT cdr_concept.id_cdr_concept%TYPE := 13;
    g_cdrcp_ingredient   CONSTANT cdr_concept.id_cdr_concept%TYPE := 17;
    g_cdrcp_ingr_group   CONSTANT cdr_concept.id_cdr_concept%TYPE := 18;
    g_cdrcp_product      CONSTANT cdr_concept.id_cdr_concept%TYPE := 19;
    g_cdrcp_ddi          CONSTANT cdr_concept.id_cdr_concept%TYPE := 20;
    g_cdrcp_drug_group   CONSTANT cdr_concept.id_cdr_concept%TYPE := 22;
    g_cdrcp_diag_syn     CONSTANT cdr_concept.id_cdr_concept%TYPE := 21;
    g_cdrcp_rcm          CONSTANT cdr_concept.id_cdr_concept%TYPE := 23;

    g_cdrcp_rcm_sev_score CONSTANT cdr_concept.id_cdr_concept%TYPE := 24;
    g_cdrcp_war_sev_score CONSTANT cdr_concept.id_cdr_concept%TYPE := 25;

    g_cdrcp_vs CONSTANT cdr_concept.id_cdr_concept%TYPE := 31;

    -- rule severities
    g_cdrs_not_applicable CONSTANT cdr_severity.id_cdr_severity%TYPE := -1;

    -- rule actions
    g_cdra_override CONSTANT cdr_action.id_cdr_action%TYPE := 1;
    g_cdra_warning  CONSTANT cdr_action.id_cdr_action%TYPE := 2;
    g_cdra_postpone CONSTANT cdr_action.id_cdr_action%TYPE := 5;
    g_cdra_external  CONSTANT cdr_action.id_cdr_action%TYPE := 6;
    g_cdra_no_action CONSTANT cdr_action.id_cdr_action%TYPE := 9;

    -- rule warning answers
    g_cdraw_no_answer CONSTANT cdr_answer.id_cdr_answer%TYPE := -1;
    g_cdraw_cancel    CONSTANT cdr_answer.id_cdr_answer%TYPE := 2;

    -- conversion types
    g_conv_simple  CONSTANT cdr_concept_task_type.flg_conversion%TYPE := 'S';
    g_conv_complex CONSTANT cdr_concept_task_type.flg_conversion%TYPE := 'C';

    -- domain codes
    g_domain_status   CONSTANT sys_domain.code_domain%TYPE := 'CDR_INSTANCE.FLG_STATUS';
    g_domain_operator CONSTANT sys_domain.code_domain%TYPE := 'CDR_DEF_COND.FLG_CONDITION';

    -- actions
    g_action_cancel CONSTANT action.to_state%TYPE := 'C';
    g_action_edit   CONSTANT action.to_state%TYPE := 'ED';

    -- setting types
    g_add      CONSTANT cdr_def_inst.flg_add_remove%TYPE := 'A';
    g_rem      CONSTANT cdr_def_inst.flg_add_remove%TYPE := 'R';
    g_multiple CONSTANT VARCHAR(10 CHAR) := 'M';

    -- 
    g_tt_medication         CONSTANT task_type.id_task_type%TYPE := 51;
    g_tt_allergy            CONSTANT task_type.id_task_type%TYPE := 59;
    g_tt_problem            CONSTANT NUMBER := 4;
    g_tt_medication_by_prod CONSTANT task_type.id_task_type%TYPE := 90;
    g_tt_medication_by_detail CONSTANT task_type.id_task_type%TYPE := 125;

    -- context external warnings type 
    g_ced_product CONSTANT cdr_external_det.ced_type%TYPE := 1;
    g_ced_ucd     CONSTANT cdr_external_det.ced_type%TYPE := 2;
    g_ced_pk      CONSTANT cdr_external_det.ced_type%TYPE := 3;
    g_ced_cng     CONSTANT cdr_external_det.ced_type%TYPE := 4;

    -- cdr warnings types
    g_warn_drug_interaction        CONSTANT cdr_type.id_cdr_type%TYPE := 1;
    g_warn_drug_allergie           CONSTANT cdr_type.id_cdr_type%TYPE := 2;
    g_warn_contraindication        CONSTANT cdr_type.id_cdr_type%TYPE := 3;
    g_warn_overdose                CONSTANT cdr_type.id_cdr_type%TYPE := 4;
    g_warn_therapeutic_duplication CONSTANT cdr_type.id_cdr_type%TYPE := 5;
    g_warn_duplication_of_requests CONSTANT cdr_type.id_cdr_type%TYPE := 6;
    g_warn_recommendation          CONSTANT cdr_type.id_cdr_type%TYPE := 7;
    g_warn_prep_pat_imcompatible   CONSTANT cdr_type.id_cdr_type%TYPE := 8;
    g_warn_incomp_between_requests CONSTANT cdr_type.id_cdr_type%TYPE := 9;
    g_warn_suggestion              CONSTANT cdr_type.id_cdr_type%TYPE := 10;
    g_warn_other                   CONSTANT cdr_type.id_cdr_type%TYPE := 11;

    g_ced_age               CONSTANT cdr_external_det.ced_type%TYPE := 10;
    g_ced_weight            CONSTANT cdr_external_det.ced_type%TYPE := 20;
    g_ced_pregnant          CONSTANT cdr_external_det.ced_type%TYPE := 30;
    g_ced_breast_feeding    CONSTANT cdr_external_det.ced_type%TYPE := 40;
    g_ced_creatin_clearance CONSTANT cdr_external_det.ced_type%TYPE := 50;
    g_ced_gender            CONSTANT cdr_external_det.ced_type%TYPE := 60;
    g_ced_diagnosis         CONSTANT cdr_external_det.ced_type%TYPE := 70;
    g_ced_allergy           CONSTANT cdr_external_det.ced_type%TYPE := 80;

    g_task_type_filter CONSTANT sys_domain.code_domain%TYPE := 'CDR_TASK_TYPE_FILTER'; -- in the future this will be a sys_domain for alert internal cds engine 
    g_task_type_severity CONSTANT sys_domain.code_domain%TYPE := 'CDR_TASK_TYPE_SEVERITY'; -- in the future this will be a sys_domain for alert internal cds engine 

END pk_cdr_constant;
/
