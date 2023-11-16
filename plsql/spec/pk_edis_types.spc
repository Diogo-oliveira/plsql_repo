/*-- Last Change Revision: $Rev: 2028669 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:13 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_edis_types AS

    TYPE rec_step IS RECORD(
        id_pre_hosp_form  pre_hosp_form_steps.id_pre_hosp_form%TYPE,
        id_pre_hosp_step  pre_hosp_form_steps.id_pre_hosp_step%TYPE,
        step_int_name     pre_hosp_step.internal_name%TYPE,
        desc_step         sys_message.desc_message%TYPE,
        flg_show_step_msg pre_hosp_form_steps.flg_show_step_msg%TYPE);

    TYPE rec_section IS RECORD(
        id_pre_hosp_form    pre_hosp_step_sections.id_pre_hosp_form%TYPE,
        id_pre_hosp_step    pre_hosp_step_sections.id_pre_hosp_step%TYPE,
        id_pre_hosp_section pre_hosp_step_sections.id_pre_hosp_section%TYPE,
        section_int_name    pre_hosp_section.internal_name%TYPE,
        desc_section        sys_message.desc_message%TYPE);

    TYPE rec_field IS RECORD(
        id_pre_hosp_form    pre_hosp_section_fields.id_pre_hosp_form%TYPE,
        id_pre_hosp_step    pre_hosp_section_fields.id_pre_hosp_step%TYPE,
        id_pre_hosp_section pre_hosp_section_fields.id_pre_hosp_section%TYPE,
        id_pre_hosp_field   pre_hosp_section_fields.id_pre_hosp_field%TYPE,
        field_int_name      pre_hosp_field.internal_name%TYPE,
        desc_field          sys_message.desc_message%TYPE,
        desc_new_field      sys_message.desc_message%TYPE,
        flg_mandatory       pre_hosp_section_fields.flg_mandatory%TYPE);

    TYPE cursor_step IS REF CURSOR RETURN rec_step;
    TYPE cursor_section IS REF CURSOR RETURN rec_section;
    TYPE cursor_field IS REF CURSOR RETURN rec_field;

    TYPE table_step IS TABLE OF rec_step;
    TYPE table_section IS TABLE OF rec_section;
    TYPE table_field IS TABLE OF rec_field;

    --START DIAGNOSIS TYPES
    TYPE rec_in_morphology IS RECORD(
        morphology epis_diag_tumors.id_morphology%TYPE,
        behavior   epis_diag_tumors.id_behavior%TYPE,
        grade      epis_diag_tumors.id_histological_grade%TYPE);

    TYPE rec_in_tnm IS RECORD(
        t            epis_diag_stag.id_tnm_t%TYPE,
        code_stage_t epis_diag_stag.code_tnm_t%TYPE,
        n            epis_diag_stag.id_tnm_n%TYPE,
        code_stage_n epis_diag_stag.code_tnm_n%TYPE,
        m            epis_diag_stag.id_tnm_m%TYPE,
        code_stage_m epis_diag_stag.code_tnm_t%TYPE);

    ------------------------------------------------------------------------
    -- tumor
    TYPE rec_in_tumor IS RECORD(
        tumor_num              epis_diag_tumors.tumor_num%TYPE,
        id_topography          epis_diag_tumors.id_topography%TYPE,
        id_laterality          epis_diag_tumors.id_laterality%TYPE,
        morphology             rec_in_morphology,
        id_other_grading_sys   epis_diag_tumors.id_other_grading_sys%TYPE,
        flg_unknown_dimension  epis_diag_tumors.flg_unknown_dimension%TYPE,
        num_dimension          epis_diag_tumors.num_dimension%TYPE,
        desc_dimension         epis_diag_tumors.desc_dimension%TYPE,
        additional_pathol_info epis_diag_tumors.additional_pathol_info%TYPE);

    TYPE table_in_tumors IS TABLE OF rec_in_tumor;

    ------------------------------------------------------------------------
    -- prog_factor
    TYPE rec_in_prog_factor IS RECORD(
        id_field   epis_diag_stag_pfact.id_field%TYPE,
        field_rank epis_diag_stag_pfact.field_rank%TYPE,
        id_value   epis_diag_stag_pfact.id_value%TYPE,
        desc_value epis_diag_stag_pfact.desc_value%TYPE);

    TYPE table_in_prog_factor IS TABLE OF rec_in_prog_factor;

    ------------------------------------------------------------------------
    -- diag staging
    TYPE rec_in_diag_staging IS RECORD(
        num_staging_basis    epis_diag_stag.num_staging_basis%TYPE,
        id_staging_basis     epis_diag_stag.id_staging_basis%TYPE,
        tnm                  rec_in_tnm,
        id_metastatic_sites  epis_diag_stag.id_metastatic_sites%TYPE,
        id_staging_group     epis_diag_stag.id_staging_group%TYPE,
        id_residual_tumor    epis_diag_stag.id_residual_tumor%TYPE,
        id_surgical_margins  epis_diag_stag.id_surgical_margins%TYPE,
        id_lymph_vasc_inv    epis_diag_stag.id_lymph_vasc_inv%TYPE,
        id_other_staging_sys epis_diag_stag.id_other_staging_sys%TYPE,
        id_cancel_reason     epis_diag_stag.id_cancel_reason%TYPE,
        cancel_notes         epis_diag_stag.cancel_notes%TYPE,
        tbl_prog_factors     table_in_prog_factor);

    TYPE table_in_diag_staging IS TABLE OF rec_in_diag_staging;

    ------------------------------------------------------------------------
    -- diag complications
    TYPE rec_in_complication IS RECORD(
        id_complication       diagnosis.id_diagnosis%TYPE, -- item_value
        id_alert_complication alert_diagnosis.id_alert_diagnosis%TYPE, -- alt_value
        desc_complication     epis_diag_complications.desc_complication%TYPE -- diagnosis description
        );

    TYPE table_in_complications IS TABLE OF rec_in_complication;

    ------------------------------------------------------------------------
    TYPE rec_in_diagnosis IS RECORD(
        id_diagnosis       diagnosis.id_diagnosis%TYPE, --When editing can be NULL
        id_alert_diagnosis alert_diagnosis.id_alert_diagnosis%TYPE, --When editing can be NULL
        desc_diagnosis     epis_diagnosis.desc_epis_diagnosis%TYPE, --DESC_DIAGNOSIS only available when creating a new diagnosis
        flg_diag_type      VARCHAR2(1 CHAR), -- C - Cancer; A - Accident and Emergency; D - Diagnosis
        flg_final_type     epis_diagnosis.flg_final_type%TYPE,
        flg_status         epis_diagnosis.flg_status%TYPE,
        flg_add_problem    epis_diagnosis.flg_add_problem%TYPE,
        notes              epis_diagnosis.notes%TYPE,
        --ACCIDENT_EMERGENCY
        id_diagnosis_condition epis_diagnosis.id_diagnosis_condition%TYPE,
        id_sub_analysis        epis_diagnosis.id_sub_analysis%TYPE,
        id_anatomical_area     epis_diagnosis.id_anatomical_area%TYPE,
        id_anatomical_side     epis_diagnosis.id_anatomical_side%TYPE,
        -- TARUMA MX
        id_lesion_location epis_diagnosis.id_lesion_location%TYPE,
        id_lesion_type     epis_diagnosis.id_lesion_type%TYPE,
        -- RANK
        rank epis_diagnosis.rank%TYPE,
        -- COMPLICATIONS
        tbl_complications table_in_complications,
        --CHARACTERIZATION
        dt_initial_diag    epis_diagnosis.dt_initial_diag%TYPE,
        id_diag_basis      epis_diagnosis.id_diag_basis%TYPE,
        diag_basis_spec    epis_diagnosis.diag_basis_spec%TYPE,
        flg_recurrence     epis_diagnosis.flg_recurrence%TYPE,
        flg_mult_tumors    epis_diagnosis.flg_mult_tumors%TYPE,
        num_primary_tumors epis_diagnosis.num_primary_tumors%TYPE,
        tbl_tumors         table_in_tumors,
        tbl_diag_staging   table_in_diag_staging);

    TYPE table_in_diagnosis IS TABLE OF rec_in_diagnosis;

    TYPE rec_in_epis_diagnosis IS RECORD(
        id_epis_diagnosis        epis_diagnosis.id_epis_diagnosis%TYPE, -- available when editing a existing diagnosis (creating if NULL)
        id_epis_diagnosis_hist   epis_diagnosis_hist.id_epis_diagnosis_hist%TYPE, --is needed for cancer diagnosis when editing a past staging diagnosis
        id_patient               epis_diagnosis.id_patient%TYPE,
        id_episode               epis_diagnosis.id_episode%TYPE,
        prof_cat_type            category.flg_type%TYPE,
        flg_type                 epis_diagnosis_hist.flg_type%TYPE, --P - Working diag; D - Final diag
        flg_edit_mode            VARCHAR2(1 CHAR), --Flag to diferentiate which fields are being updated. S - Diagnosis Status edit; T - Diagnosis Type edit; N - Diagnosis screen edition (multiple values editable)
        flg_transf_final         VARCHAR2(1 CHAR),
        id_cdr_call              cdr_call.id_cdr_call%TYPE,
        id_cancel_reason         epis_diagnosis.id_cancel_reason%TYPE, -- Only available when canceling a diagnosis
        cancel_notes             epis_diagnosis.notes_cancel%TYPE,
        flg_cancel_diff_diag     VARCHAR2(1 CHAR), --Flag that indicates if differencial diagnoses should also be cancelled (This flag is only necessary when cancelling a final diagnosis)
        flg_val_single_prim_diag VARCHAR2(1 CHAR), --Check if the episode has only one primary diagnosis: Y - yes, N - No
        tbl_diagnosis            table_in_diagnosis, -- If only diagnosis ID is used, record is a diagnostic association
        dt_record                TIMESTAMP WITH LOCAL TIME ZONE);

    TYPE table_in_epis_diagnosis IS TABLE OF rec_in_epis_diagnosis;

    TYPE rec_in_general_notes IS RECORD(
        id_epis_diagnosis_notes epis_diagnosis_notes.id_epis_diagnosis_notes%TYPE, -- Only available when editing
        id_episode              epis_diagnosis_notes.id_episode%TYPE,
        notes                   epis_diagnosis_notes.notes%TYPE,
        id_cancel_reason        epis_diagnosis_notes.id_cancel_reason%TYPE,
        id_prof_create          epis_diagnosis_notes.id_prof_create%TYPE);

    --This type is used has input parameter of pk_diagnosis_core.set_epis_diagnosis function
    TYPE rec_in_epis_diagnoses IS RECORD(
        epis_diagnosis rec_in_epis_diagnosis,
        general_notes  rec_in_general_notes);

    -- epis_diagnosis_notes info (Impressions)
    TYPE t_rec_diag_notes IS RECORD(
        id_epis_diagnosis_notes epis_diagnosis_notes.id_epis_diagnosis_notes%TYPE,
        dt_register             VARCHAR2(1000),
        dt_register_chr         VARCHAR2(1000),
        id_prof_create          epis_diagnosis_notes.id_prof_create%TYPE,
        name_prof_create        professional.name%TYPE,
        desc_spec_create        VARCHAR2(1000),
        flg_status              VARCHAR2(1),
        desc_status             sys_domain.desc_val%TYPE,
        notes                   epis_diagnosis_notes.notes%TYPE,
        id_prof_cancel          epis_diagnosis_notes.id_prof_cancel%TYPE,
        name_prof_cancel        professional.name%TYPE,
        desc_spec_cancel        VARCHAR2(1000),
        dt_cancel_chr           VARCHAR2(1000),
        desc_cancel_reason      pk_translation.t_desc_translation,
        notes_cancel            epis_diagnosis_notes.notes_cancel%TYPE,
        signature               VARCHAR2(4000));
    TYPE t_coll_diag_notes IS TABLE OF t_rec_diag_notes;
    TYPE t_cur_diag_notes IS REF CURSOR RETURN t_rec_diag_notes; -- returned in pk_diagnosis_core.get_epis_diag_notes

    ------------------------------------------------------------------------
    TYPE rec_out_tumor IS RECORD(
        tumor_num               epis_diag_tumors.tumor_num%TYPE,
        tumor_num_directly_hist epis_diag_tumors.tumor_num%TYPE);

    TYPE table_out_tumors IS TABLE OF rec_out_tumor;

    ------------------------------------------------------------------------
    TYPE rec_out_pfactor IS RECORD(
        prog_factor               epis_diag_stag_pfact.id_field%TYPE,
        prog_factor_directly_hist epis_diag_stag_pfact.id_field%TYPE);

    TYPE table_out_pfactors IS TABLE OF rec_out_pfactor;

    ------------------------------------------------------------------------
    TYPE rec_out_staging IS RECORD(
        diag_staging               epis_diag_stag.num_staging_basis%TYPE,
        diag_staging_directly_hist epis_diag_stag.num_staging_basis%TYPE,
        tbl_prog_factors           table_out_pfactors);

    TYPE table_out_stagings IS TABLE OF rec_out_staging;

    ------------------------------------------------------------------------
    TYPE rec_out_complication IS RECORD(
        id_complication          epis_diag_complications.id_complication%TYPE,
        id_alert_complication    epis_diag_complications.id_alert_complication%TYPE,
        complication_description VARCHAR2(4000 CHAR),
        complication_code        VARCHAR2(200 CHAR),
        rank                     epis_diag_complications.rank%TYPE);

    TYPE table_out_complications IS TABLE OF rec_out_complication;

    ------------------------------------------------------------------------
    TYPE rec_out_epis_diag IS RECORD(
        id_epis_diagnosis      epis_diagnosis.id_epis_diagnosis%TYPE,
        id_epis_diagnosis_hist epis_diagnosis_hist.id_epis_diagnosis_hist%TYPE,
        id_professional        professional.id_professional%TYPE,
        prof_name              professional.name%TYPE,
        prof_spec              pk_translation.t_desc_translation,
        dt_record              epis_diagnosis.dt_epis_diagnosis_tstz%TYPE,
        problem_msg            VARCHAR2(1000 CHAR),
        problem_msg_title      VARCHAR2(1000 CHAR),
        problem_flg_show       VARCHAR2(1000 CHAR),
        problem_button         VARCHAR2(1000 CHAR),
        tbl_tumors             table_out_tumors,
        tbl_stagings           table_out_stagings,
        tbl_complications      table_out_complications);

    --This type is used has output parameter of pk_diagnosis_core.set_epis_diagnosis function
    TYPE table_out_epis_diags IS TABLE OF rec_out_epis_diag;

    TYPE assoc_diag_rec IS RECORD(
        id_diagnosis       diagnosis.id_diagnosis%TYPE,
        desc_diagnosis     sys_message.desc_message%TYPE,
        code_icd           diagnosis.code_icd%TYPE,
        flg_other          diagnosis.flg_other%TYPE,
        id_alert_diagnosis alert_diagnosis.id_alert_diagnosis%TYPE);

    TYPE assoc_diag_table IS TABLE OF assoc_diag_rec;

    TYPE rec_status IS RECORD(
        val         VARCHAR2(30 CHAR),
        desc_val    VARCHAR2(800 CHAR),
        img_name    VARCHAR2(200 CHAR),
        flg_default VARCHAR2(1 CHAR));

    TYPE cursor_status IS REF CURSOR RETURN rec_status;
    TYPE table_status IS TABLE OF rec_status;

    TYPE rec_assoc_prob IS RECORD(
        data                    VARCHAR2(30 CHAR),
        label                   VARCHAR2(800 CHAR),
        flg_default             VARCHAR2(1 CHAR),
        flg_default_diag_cancer VARCHAR2(1 CHAR));

    TYPE cursor_assoc_prob IS REF CURSOR RETURN rec_assoc_prob;
    TYPE table_assoc_prob IS TABLE OF rec_assoc_prob;

    TYPE diagnosis_list_rec IS RECORD(
        id_epis_diagnosis      epis_diagnosis.id_epis_diagnosis%TYPE,
        prof_category          VARCHAR2(0050 CHAR),
        id_epis_diagnosis_hist epis_diagnosis_hist.id_epis_diagnosis_hist%TYPE,
        id_diagnosis           diagnosis.id_diagnosis%TYPE,
        id_alert_diagnosis     alert_diagnosis.id_alert_diagnosis%TYPE,
        desc_diagnosis         pk_translation.t_desc_translation,
        date_target_initial    VARCHAR2(200),
        flg_with_notes         VARCHAR2(1 CHAR),
        status_diagnosis       epis_diagnosis.flg_status%TYPE,
        id_professional_diag   professional.id_professional%TYPE,
        prof_name_diag         pk_translation.t_desc_translation,
        date_diag              VARCHAR2(50 CHAR),
        date_target_diag       VARCHAR2(50 CHAR),
        hour_target_diag       VARCHAR2(50 CHAR),
        id_prof_confirmed      professional.id_professional%TYPE,
        prof_name_conf         pk_translation.t_desc_translation,
        date_conf              VARCHAR2(50 CHAR),
        date_target_conf       VARCHAR2(50 CHAR),
        hour_target_conf       VARCHAR2(50 CHAR),
        id_professional_cancel professional.id_professional%TYPE,
        prof_name_cancel       pk_translation.t_desc_translation,
        date_cancel            VARCHAR2(50 CHAR),
        date_target_cancel     VARCHAR2(50 CHAR),
        hour_target_cancel     VARCHAR2(50 CHAR),
        id_prof_rulled_out     professional.id_professional%TYPE,
        prof_name_rulled_out   pk_translation.t_desc_translation,
        date_rulled_out        VARCHAR2(50 CHAR),
        date_target_rulled     VARCHAR2(50 CHAR),
        hour_target_rulled     VARCHAR2(50 CHAR),
        id_prof_base           professional.id_professional%TYPE,
        prof_name_base         pk_translation.t_desc_translation,
        date_base              VARCHAR2(50 CHAR),
        date_target_base       VARCHAR2(50 CHAR),
        hour_target_base       VARCHAR2(50 CHAR),
        icon_status            VARCHAR2(200 CHAR),
        desc_status            pk_translation.t_desc_translation,
        icon_final_type        VARCHAR2(200 CHAR),
        desc_final_type        pk_translation.t_desc_translation,
        final_type             epis_diagnosis.flg_final_type%TYPE,
        date_order             VARCHAR2(50 CHAR),
        notes                  pk_translation.t_desc_translation,
        notes_cancel           pk_translation.t_desc_translation,
        id_cancel_reason       epis_diagnosis.id_cancel_reason%TYPE,
        general_notes          pk_translation.t_desc_translation,
        avail_butt_cancel      VARCHAR2(2 CHAR),
        rank                   sys_domain.rank%TYPE,
        prof_spec_diag         pk_translation.t_desc_translation,
        prof_spec_conf         pk_translation.t_desc_translation,
        prof_spec_canc         pk_translation.t_desc_translation,
        prof_spec_rull         pk_translation.t_desc_translation,
        prof_spec_base         pk_translation.t_desc_translation,
        has_diff_diag          VARCHAR2(2 CHAR),
        flg_is_cancer          VARCHAR2(1 CHAR),
        ds_leaf_path           CLOB);

    TYPE diagnosis_cur IS REF CURSOR RETURN diagnosis_list_rec;

    PROCEDURE open_my_cursor(i_cursor IN OUT diagnosis_cur);

    TYPE t_coll_diagnosis IS TABLE OF diagnosis_list_rec;

    TYPE p_epis_diagnosis_rec IS RECORD(
        id_epis_diagnosis      NUMBER(24),
        id_epis_diagnosis_hist NUMBER(24),
        id_diagnosis           NUMBER(24),
        diag_desc              VARCHAR2(1000 CHAR),
        flg_type               VARCHAR2(10),
        type_desc              VARCHAR2(1000 CHAR),
        flg_status             VARCHAR2(10),
        status_desc            VARCHAR2(1000 CHAR),
        problem_status         VARCHAR2(10),
        notes                  VARCHAR2(1000 CHAR),
        general_notes          VARCHAR2(1000 CHAR),
        notes_cancel           VARCHAR2(1000 CHAR),
        flg_has_recent_data    VARCHAR2(10));

    TYPE p_epis_diagnosis_cur IS REF CURSOR RETURN p_epis_diagnosis_rec;

    TYPE rec_diag_factors IS RECORD(
        id_epis_diagnosis      epis_diag_stag_pfact.id_epis_diagnosis%TYPE,
        id_epis_diagnosis_hist epis_dstag_pfact_hist.id_epis_diagnosis_hist%TYPE,
        id_staging_basis       epis_diag_stag.id_staging_basis%TYPE,
        num_staging_basis      epis_diag_stag_pfact.num_staging_basis%TYPE,
        id_field               epis_diag_stag_pfact.id_field%TYPE,
        desc_field             VARCHAR2(1000 CHAR),
        id_value               epis_diag_stag_pfact.id_value%TYPE,
        desc_value_field       VARCHAR2(1000 CHAR),
        desc_value             epis_diag_stag_pfact.desc_value%TYPE,
        is_current_val         NUMBER,
        is_stage_factor        NUMBER);

    TYPE tab_diag_factors IS TABLE OF rec_diag_factors;

    TYPE rec_epis_diag_staging IS RECORD(
        num_staging_basis      epis_diag_stag.num_staging_basis%TYPE,
        id_epis_diagnosis      epis_diag_stag.id_epis_diagnosis%TYPE,
        id_epis_diagnosis_hist epis_diag_stag_hist.id_epis_diagnosis_hist%TYPE,
        id_staging_basis       epis_diag_stag.id_staging_basis%TYPE,
        desc_staging_basis     VARCHAR2(1000 CHAR),
        id_tnm_t               epis_diag_stag.id_tnm_t%TYPE,
        desc_tnm_t             VARCHAR2(1000 CHAR),
        code_tnm_t             epis_diag_stag.code_tnm_t%TYPE,
        concept_code_t         diagnosis.code_icd%TYPE,
        id_tnm_n               epis_diag_stag.id_tnm_n%TYPE,
        desc_tnm_n             VARCHAR2(1000 CHAR),
        code_tnm_n             epis_diag_stag.code_tnm_n%TYPE,
        concept_code_n         diagnosis.code_icd%TYPE,
        id_tnm_m               epis_diag_stag.id_tnm_m%TYPE,
        desc_tnm_m             VARCHAR2(1000 CHAR),
        code_tnm_m             epis_diag_stag.code_tnm_m%TYPE,
        concept_code_m         diagnosis.code_icd%TYPE,
        desc_tnm               VARCHAR2(1000 CHAR),
        id_metastatic_sites    epis_diag_stag.id_metastatic_sites%TYPE,
        desc_metastatic_sites  VARCHAR2(1000 CHAR),
        id_staging_group       epis_diag_stag.id_staging_group%TYPE,
        desc_group             VARCHAR2(1000 CHAR),
        desc_staging           VARCHAR2(1000 CHAR),
        desc_stage_title       VARCHAR2(1000 CHAR),
        desc_group_title       VARCHAR2(1000 CHAR),
        id_residual_tumor      epis_diag_stag.id_residual_tumor%TYPE,
        desc_residual_tumor    VARCHAR2(1000 CHAR),
        id_surgical_margins    epis_diag_stag.id_surgical_margins%TYPE,
        desc_surgical_margins  VARCHAR2(1000 CHAR),
        id_lymph_vasc_inv      epis_diag_stag.id_lymph_vasc_inv%TYPE,
        desc_lymph_vasc_inv    VARCHAR2(1000 CHAR),
        id_other_staging_sys   epis_diag_stag.id_other_staging_sys%TYPE,
        desc_other_staging_sys VARCHAR2(1000 CHAR),
        dt_epis_diagnosis_stag epis_diag_stag.dt_epis_diagnosis_stag%TYPE,
        dt_epis_diag_stag_chr  VARCHAR2(200 CHAR),
        flg_status             VARCHAR2(1 CHAR),
        desc_status            VARCHAR2(200 CHAR),
        id_cancel_reason       epis_diag_stag.id_cancel_reason%TYPE,
        desc_cancel_reason     pk_translation.t_desc_translation,
        cancel_notes           epis_diag_stag.cancel_notes%TYPE,
        id_prof_create         epis_diag_stag.id_prof_create%TYPE,
        name_prof_create       professional.name%TYPE,
        desc_spec_create       VARCHAR2(1000 CHAR),
        rank                   diagnosis_ea.rank%TYPE,
        prog_factors           tab_diag_factors);

    TYPE tab_epis_diag_staging IS TABLE OF rec_epis_diag_staging;

    TYPE rec_epis_diag_tumors IS RECORD(
        id_epis_diagnosis       epis_diag_tumors.id_epis_diagnosis%TYPE,
        id_epis_diagnosis_hist  epis_diag_tumors_hist.id_epis_diagnosis_hist%TYPE,
        tumor_num               epis_diag_tumors.tumor_num%TYPE,
        code_icdo               VARCHAR(1000 CHAR),
        id_topography           epis_diag_tumors.id_topography%TYPE,
        desc_topography         VARCHAR(1000 CHAR),
        id_laterality           epis_diag_tumors.id_laterality%TYPE,
        desc_laterality         VARCHAR(1000 CHAR),
        id_morphology           epis_diag_tumors.id_morphology%TYPE,
        desc_morphology         VARCHAR(1000 CHAR),
        id_behavior             epis_diag_tumors.id_behavior%TYPE,
        desc_behaviour          VARCHAR(1000 CHAR),
        id_histological_grade   epis_diag_tumors.id_histological_grade%TYPE,
        desc_histological_grade VARCHAR(1000 CHAR),
        id_other_grading_sys    epis_diag_tumors.id_other_grading_sys%TYPE,
        desc_other_grading_sys  VARCHAR(1000 CHAR),
        desc_grading_system     VARCHAR(1000 CHAR),
        flg_unknown_dimension   epis_diag_tumors.flg_unknown_dimension%TYPE,
        desc_unknown_dimension  VARCHAR(200 CHAR),
        num_dimension           epis_diag_tumors.num_dimension%TYPE,
        desc_dimension          epis_diag_tumors.desc_dimension%TYPE,
        additional_pathol_info  epis_diag_tumors.additional_pathol_info%TYPE);

    TYPE tab_epis_diag_tumors IS TABLE OF rec_epis_diag_tumors INDEX BY PLS_INTEGER;

    TYPE rec_epis_diagnosis IS RECORD(
        id_epis_diagnosis       epis_diagnosis.id_epis_diagnosis%TYPE,
        id_epis_diagnosis_hist  epis_diagnosis_hist.id_epis_diagnosis_hist%TYPE,
        id_diagnosis            epis_diagnosis.id_diagnosis%TYPE,
        id_alert_diagnosis      epis_diagnosis.id_alert_diagnosis%TYPE,
        desc_diagnosis          VARCHAR(1000 CHAR),
        desc_diagnosis_original VARCHAR(1000 CHAR),
        dt_initial_diag         epis_diagnosis.dt_initial_diag%TYPE,
        dt_initial_diag_chr     VARCHAR2(200 CHAR),
        age_diag                VARCHAR2(200 CHAR),
        id_diag_basis           epis_diagnosis.id_diag_basis%TYPE,
        desc_diag_basis         VARCHAR2(200 CHAR),
        diag_basis_spec         epis_diagnosis.diag_basis_spec%TYPE,
        flg_mult_tumors         epis_diagnosis.flg_mult_tumors%TYPE,
        desc_mult_tumors        VARCHAR2(200 CHAR),
        num_primary_tumors      epis_diagnosis.num_primary_tumors%TYPE,
        flg_recurrence          epis_diagnosis.flg_recurrence%TYPE,
        desc_recurrence         VARCHAR2(200 CHAR),
        flg_final_type          epis_diagnosis.flg_final_type%TYPE,
        desc_final_type         VARCHAR2(200 CHAR),
        flg_status              epis_diagnosis.flg_status%TYPE,
        desc_status             VARCHAR2(200 CHAR),
        diag_notes              epis_diagnosis.notes%TYPE,
        flg_add_problem         epis_diagnosis.flg_add_problem%TYPE,
        desc_add_problem        VARCHAR2(200 CHAR),
        dt_epis_diagnosis       epis_diagnosis.dt_epis_diagnosis_tstz%TYPE,
        dt_epis_diagnosis_chr   VARCHAR2(200 CHAR),
        id_prof_diagnosis       epis_diagnosis.id_professional_diag%TYPE,
        name_prof_diag          professional.name%TYPE,
        spec_prof_diag          VARCHAR(1000 CHAR),
        flg_type                epis_diagnosis.flg_type%TYPE,
        id_cancel_reason        epis_diagnosis.id_epis_diagnosis%TYPE,
        desc_cancel_reason      pk_translation.t_desc_translation,
        notes_cancel            epis_diagnosis.notes_cancel%TYPE,
        --ACCIDENT_EMERGENCY
        id_diagnosis_condition   epis_diagnosis.id_diagnosis_condition%TYPE,
        desc_diagnosis_condition pk_translation.t_desc_translation,
        id_sub_analysis          epis_diagnosis.id_sub_analysis%TYPE,
        desc_sub_analysis        pk_translation.t_desc_translation,
        id_anatomical_area       epis_diagnosis.id_anatomical_area%TYPE,
        desc_anatomical_area     pk_translation.t_desc_translation,
        id_anatomical_side       epis_diagnosis.id_anatomical_side%TYPE,
        desc_anatomical_side     pk_translation.t_desc_translation,
        id_lesion_type           epis_diagnosis.id_lesion_type%TYPE,
        desc_lesion_type         pk_translation.t_desc_translation,
        id_lesion_location       epis_diagnosis.id_lesion_location%TYPE,
        desc_lesion_location     pk_translation.t_desc_translation,
        --rank
        rank      epis_diagnosis.rank%TYPE,
        desc_rank pk_translation.t_desc_translation);

    TYPE tab_epis_diagnosis IS TABLE OF rec_epis_diagnosis;

    TYPE rec_diag_staging_group IS RECORD(
        id_staging_group   diagnosis.id_diagnosis%TYPE,
        code_staging_group diagnosis.code_icd%TYPE,
        desc_staging_group pk_translation.t_desc_translation);

    --The following types are used in pk_diagnosis_form.check_diag_already_reg
    TYPE rec_diagnosis IS RECORD(
        id_diagnosis       epis_diagnosis.id_diagnosis%TYPE,
        id_alert_diagnosis epis_diagnosis.id_alert_diagnosis%TYPE);

    TYPE table_diagnosis IS TABLE OF rec_diagnosis;

    TYPE rec_chk_diag_alredy_reg IS RECORD(
        id_patient    epis_diagnosis.id_patient%TYPE,
        id_episode    epis_diagnosis.id_episode%TYPE,
        tbl_diagnoses table_diagnosis);

    --This type is used has input parameter of get_section_data_int function
    TYPE rec_diag_section_data_param IS RECORD(
        id_patient                 patient.id_patient%TYPE,
        id_episode                 episode.id_episode%TYPE,
        flg_edit_mode              VARCHAR2(1),
        is_to_fill_with_saved_data VARCHAR2(1),
        id_diagnosis               diagnosis.id_diagnosis%TYPE, -- Only available when creating a new diagnosis
        id_alert_diagnosis         alert_diagnosis.id_alert_diagnosis%TYPE, -- Only available when creating a new diagnosis
        desc_diagnosis             epis_diagnosis.desc_epis_diagnosis%TYPE, -- Only available when creating a new diagnosis
        flg_type                   epis_diagnosis.flg_type%TYPE, -- Only available when creating a new diagnosis
        flg_reuse_past_diag        VARCHAR2(1), -- Only available when creating a new diagnosis
        id_epis_diagnosis          epis_diagnosis.id_epis_diagnosis%TYPE, -- Only available when editing a existing diagnosis
        id_epis_diagnosis_hist     epis_diagnosis_hist.id_epis_diagnosis_hist%TYPE, --is needed for cancer diagnosis when editing a past staging diagnosis
        ds_component_name          ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        tumor_num                  epis_diag_tumors.tumor_num%TYPE,
        display_number             epis_diag_tumors.tumor_num%TYPE,
        ds_component_type          ds_cmpt_mkt_rel.flg_component_type_parent%TYPE DEFAULT pk_dynamic_screen.c_node_component,
        id_topography              epis_diag_tumors.id_topography%TYPE,
        morphology                 pk_edis_types.rec_in_morphology,
        tnm                        pk_edis_types.rec_in_tnm,
        id_staging_basis           epis_diag_stag.id_staging_basis%TYPE,
        id_basis_diag              epis_diagnosis.id_diag_basis%TYPE,
        tbl_sections               t_table_ds_sections,
        id_diagnosis_condition     diagnosis.id_diagnosis%TYPE,
        id_sub_analysis            diagnosis.id_diagnosis%TYPE,
        id_anatomical_area         diagnosis.id_diagnosis%TYPE,
        id_anatomical_side         diagnosis.id_diagnosis%TYPE,
        id_lesion_location         diagnosis.id_diagnosis%TYPE,
        id_lesion_type             diagnosis.id_diagnosis%TYPE);

    --END DIAGNOSIS TYPES

    --START TRIAGE TYPES

    TYPE rec_need IS RECORD(
        id_necessity   pat_necessity.id_necessity%TYPE,
        desc_necessity pk_translation.t_desc_translation,
        flg_status     pat_necessity.flg_status%TYPE);

    TYPE table_needs IS TABLE OF rec_need;

    TYPE table_triag_disc_consent IS TABLE OF triage_disc_consent%ROWTYPE;

    TYPE rec_discrim_child IS RECORD(
        id_triage                triage.id_triage%TYPE,
        flg_reassess             triage.flg_reassess%TYPE,
        id_triage_color          triage.id_triage_color%TYPE,
        id_triage_color_other    triage.id_triage_color_other%TYPE,
        color_text               triage_color.color_text%TYPE,
        acuity                   triage_color.color%TYPE,
        id_triage_discriminator  triage.id_triage_discriminator%TYPE,
        desc_discriminator       pk_translation.t_desc_translation,
        flg_accepted_option      triage.flg_accepted_option%TYPE,
        desc_accepted_option     pk_translation.t_desc_translation,
        flg_accuity_confirmation VARCHAR2(1 CHAR),
        flg_select_option        VARCHAR2(1 CHAR),
        esi_level_header         pk_translation.t_desc_translation);

    TYPE cursor_discrim_child IS REF CURSOR RETURN rec_discrim_child;

    TYPE rec_option IS RECORD(
        id_triage_discriminator   triage_discriminator.id_triage_discriminator%TYPE, --Used when validating VS and when getting saved data
        desc_triage_discriminator pk_translation.t_desc_translation,
        id_triage                 epis_triage_option.id_triage%TYPE,
        flg_reassess              triage.flg_reassess%TYPE,
        id_triage_cons_value      epis_triage_option.id_triage_cons_value%TYPE,
        title_consent             sys_message.desc_message%TYPE,
        desc_consent              pk_translation.t_desc_translation,
        flg_triage_cons_vs_mand   triage_disc_consent.flg_vs_mandatory%TYPE,
        flg_triage_cons_vs_enab   triage_disc_consent.flg_vs_enable%TYPE,
        discr_consent_values      table_triag_disc_consent,
        flg_selected_option       epis_triage_option.flg_selected_option%TYPE, --Option selected by the user to confirm triage: (Y) Yes (N) No
        urgency_level             triage_esi_level.esi_level%TYPE, --Used on ESI and EST triage
        id_triage_color           triage_color.id_triage_color%TYPE,
        flg_critical_look         triage.flg_critical_look%TYPE,
        child_option              rec_discrim_child --In ESI some triage discriminators have multichoices where is possible to select child discriminators
        );

    TYPE table_options IS TABLE OF rec_option;

    TYPE rec_group_option IS RECORD(
        id_triage_color triage.id_triage_color%TYPE,
        options         table_options);

    TYPE table_group_options IS TABLE OF rec_group_option;

    TYPE rec_origin IS RECORD(
        id_origin      epis_triage.id_origin%TYPE,
        desc_origin    pk_translation.t_desc_translation,
        desc_origin_ft epis_triage.desc_origin%TYPE);

    TYPE rec_vital_sign IS RECORD(
        id_vital_sign        vital_sign.id_vital_sign%TYPE,
        desc_vital_sign      pk_translation.t_desc_translation,
        id_vital_sign_parent vital_sign_relation.id_vital_sign_parent%TYPE,
        id_unit_measure      unit_measure.id_unit_measure%TYPE,
        desc_unit_measure    pk_translation.t_desc_translation,
        VALUE                vital_sign_read.value%TYPE,
        id_vital_sign_desc   vital_sign_desc.id_vital_sign_desc%TYPE,
        vsd_value            vital_sign_desc.value%TYPE,
        desc_value           pk_translation.t_desc_translation, -- Translation of vital_sign_desc.code_vital_sign_desc
        flg_save             VARCHAR2(1), -- flg that indicates if a vital sign is to be saved
        urgency_level        triage_esi_level.esi_level%TYPE, --Mantained by UX with the responses from check_vital_signs and used by DB to calculate the defining criteria, function check_est_level
        --ID_SCALES_ELEMENT is used in set_triage_vs and only for the pain vs
        id_scales_element vital_sign_scales_element.id_vs_scales_element%TYPE,
        --CHECK_VS DATA - The following fields are filled in get_vital_sign_data
        internal_name      vital_sign.intern_name_vital_sign%TYPE,
        val_min            vital_sign_unit_measure.val_min%TYPE,
        val_max            vital_sign_unit_measure.val_max%TYPE,
        vs_area_min_value  triage_type_vs.val_min%TYPE,
        vs_area_max_value  triage_type_vs.val_max%TYPE,
        id_triage_type_vs  triage_type_vs.id_triage_type_vs%TYPE,
        id_triage_vs_area  triage_vs_area.id_triage_vs_area%TYPE,
        id_config_unit_mea unit_measure.id_unit_measure%TYPE,
        flg_available      triage_type_vs.flg_available%TYPE,
        flg_fill_type      vital_sign.flg_fill_type%TYPE,
        flg_mandatory      triage_vs_area.flg_mandatory%TYPE,
        has_child_record   BOOLEAN,
        has_limits         BOOLEAN,
        --Ratio between the read value and the expected one
        peak_flow_percentage vital_sign_read.value%TYPE,
        rank                 vs_soft_inst.rank%TYPE,
        --ALERT-275364 - EST New requirement: The system must provide the ability to ignore the urgency level obtained by the index the choc whenever required
        is_to_ignore_result epis_triage_vs.flg_ignore_result%TYPE);

    TYPE table_vital_signs IS TABLE OF rec_vital_sign;

    TYPE rec_pregnant IS RECORD(
        flg_pregnant    epis_triage.flg_pregnant%TYPE,
        desc_pregnant   pk_translation.t_desc_translation,
        pregnancy_weeks epis_triage.preg_weeks%TYPE,
        desc_weeks      pk_translation.t_desc_translation,
        flg_postpartum  epis_triage.flg_postpartum%TYPE,
        desc_postpartum pk_translation.t_desc_translation);

    TYPE rec_check_option IS RECORD(
        id_triage_board         triage_board.id_triage_board%TYPE, --Used when validating VS
        id_triage_discriminator triage_discriminator.id_triage_discriminator%TYPE, --Used when validating VS
        desc_option             pk_translation.t_desc_translation, --Has the translation of the board or of the discriminator. Is filled in check_vital_signs function
        flg_accepted_option     triage.flg_accepted_option%TYPE, --Used in check_vital_signs function
        discriminator_answer    rec_option --Correspondent user answer to the discriminator, filled in check_vital_signs function and only when id_triage_discriminator is not null
        );

    TYPE table_check_options IS TABLE OF rec_check_option;

    TYPE rec_check_vital_signs IS RECORD(
        flg_type             VARCHAR2(1 CHAR),
        flg_check_vital_sign triage_configuration.flg_check_vital_sign%TYPE, --Filled in check_vital_signs function
        check_options        table_check_options);

    TYPE rec_defining_criteria IS RECORD(
        id_triage               triage.id_triage%TYPE,
        flg_reassess            triage.flg_reassess%TYPE,
        id_triage_discriminator triage_discriminator.id_triage_discriminator%TYPE,
        id_triage_cons_value    epis_triage_option.id_triage_cons_value%TYPE DEFAULT NULL,
        desc_criteria           pk_translation.t_desc_translation, --Discriminator description
        discrim_answer          epis_triage.flg_selected_option%TYPE,
        desc_discrim_answer     pk_translation.t_desc_translation,
        child_criteria          rec_discrim_child, --In ESI some triage discriminators have multichoices where is possible to select child discriminators
        flg_critical_look       triage.flg_critical_look%TYPE,
        box                     triage.box%TYPE);

    TYPE table_defining_criteria IS TABLE OF rec_defining_criteria;

    TYPE rec_fast_track IS RECORD(
        id_fast_track           fast_track.id_fast_track%TYPE,
        desc_fast_track         pk_translation.t_desc_translation,
        flg_activation_type     epis_fast_track.flg_activation_type%TYPE,
        flg_type                epis_fast_track.flg_type%TYPE,
        desc_flg_type           pk_translation.t_desc_translation,
        flg_status              epis_fast_track.flg_status%TYPE,
        id_epis_fast_track_hist epis_fast_track_hist.id_epis_fast_track_hist%TYPE,
        notes                   epis_fast_track_hist.notes_enable%TYPE,
        id_professional         epis_fast_track_hist.id_prof_disable%TYPE,
        fast_track_date         epis_fast_track.dt_disable%TYPE,
        reason                  pk_translation.t_desc_translation);

    TYPE table_fast_track IS TABLE OF rec_fast_track;

    TYPE rec_cause_comments IS RECORD(
        id_external_cause   transportation.id_external_cause%TYPE, -- form field 'Cause' ID
        desc_external_cause translation.desc_lang_1%TYPE, -- form field 'Cause' description
        comments            transportation.notes%TYPE); -- form field 'Comments');

    TYPE rec_safeguarding IS RECORD(
        
        flg_under_two_years  VARCHAR2(1 CHAR),
        flg_immobile         VARCHAR2(1 CHAR),
        flg_injury           VARCHAR2(1 CHAR),
        flg_protection_plan  VARCHAR2(1 CHAR),
        flg_attend_delay     VARCHAR2(1 CHAR),
        flg_domestic_abuse   VARCHAR2(1 CHAR),
        flg_possible_injury  VARCHAR2(1 CHAR),
        flg_has_social       VARCHAR2(1 CHAR),
        social_work_name     VARCHAR2(800 CHAR),
        social_work_address  VARCHAR2(1000 CHAR),
        flg_social_services  VARCHAR2(1 CHAR),
        social_reason        VARCHAR2(1000 CHAR),
        flg_consent_social   VARCHAR2(1 CHAR),
        flg_info_sharing     VARCHAR2(1 CHAR),
        dt_social_contact    TIMESTAMP WITH LOCAL TIME ZONE,
        social_info_received VARCHAR2(1000 CHAR),
        flg_signs_abuse      VARCHAR2(1 CHAR));

    TYPE rec_triage IS RECORD(
        id_patient             patient.id_patient%TYPE,
        patient_age            NUMBER(4, 1), --Used in check_vital_signs function
        id_episode             episode.id_episode%TYPE,
        id_prof_cat            category.flg_type%TYPE,
        id_triage_board        triage_board.id_triage_board%TYPE, -- used in save function
        desc_triage_board      pk_translation.t_desc_translation,
        id_triage              triage.id_triage%TYPE, -- used only in save validations
        id_epis_triage         epis_triage.id_epis_triage%TYPE,
        id_triage_type         triage.id_triage_type%TYPE,
        desc_triage_type       pk_translation.t_desc_translation,
        triage_type_acronym    triage_type.acronym%TYPE, --Used in check_vital_signs function
        id_triage_color        triage_color.id_triage_color%TYPE, --UX sends this value as ID_FINAL_COLOR
        desc_triage_color      VARCHAR2(200 CHAR), -- used in get_triage_svd_data to send to detail screen
        id_triage_white_reason epis_triage.id_triage_white_reason%TYPE,
        desc_white_reason      pk_translation.t_desc_translation,
        id_transp_entity       transp_entity.id_transp_entity%TYPE, --Arrived by
        desc_transport         pk_translation.t_desc_translation,
        flg_changed_color      VARCHAR2(1 CHAR), --User changed triage color?
        id_triage_orig_color   epis_triage.id_triage_color_orig%TYPE,
        triage_duration        NUMBER(24),
        dt_triage_begin        TIMESTAMP WITH LOCAL TIME ZONE,
        dt_triage_end          TIMESTAMP WITH LOCAL TIME ZONE,
        flg_letter             epis_triage.flg_letter%TYPE,
        desc_letter            sys_domain.desc_val%TYPE,
        initial_notes          epis_triage.initial_notes%TYPE, --Notes of triage form
        notes                  epis_triage.notes%TYPE, --Final triage notes
        chief_complaint        epis_anamnesis.desc_epis_anamnesis%TYPE,
        emergency_contact      VARCHAR2(200 CHAR),
        treatment              epis_triage.treatment%TYPE,
        accident_desc          epis_triage.accident_desc%TYPE,
        flg_default_view       triage_configuration.flg_default_view%TYPE,
        flg_complaint          triage_configuration.flg_complaint%TYPE,
        flg_reassess           triage.flg_reassess%TYPE,
        flg_selected_option    epis_triage.flg_selected_option%TYPE, -- used only in save validations
        triage_color_color     triage_color.color%TYPE, -- used only in save (epis_info)
        triage_color_text      triage_color.color_text%TYPE, -- used only in save (epis_info)
        triage_color_rank      triage_color.rank%TYPE, -- used only in save (epis_info)
        epis_triage_count      NUMBER(6), -- used only in save to know how many triages have been done before for this episode
        episode_dt_begin       episode.dt_begin_tstz%TYPE, -- used only in save (set_triage_alerts),
        flg_critical_look   epis_triage.flg_critical_look%type, -- used only on CTAS,
        desc_critical varchar2(200 char),
critical_look_description pk_translation.t_desc_translation,
        cause_comments         rec_cause_comments,
        needs                  table_needs,
        group_options          table_group_options,
        defining_criterias     table_defining_criteria,
        other_criterias        table_defining_criteria,
        check_vs               rec_check_vital_signs, --Only used in check_vs function
        vital_signs            table_vital_signs,
        origin                 rec_origin,
        pregnant               rec_pregnant,
        fast_track             table_fast_track,
        safeguarding           rec_safeguarding);

    TYPE rec_validate_vs IS RECORD(
        vs_value               vital_sign_read.value%TYPE,
        only_optional_vs       BOOLEAN,
        missing_vs_exclusive   BOOLEAN,
        finish_esi_validation  BOOLEAN,
        values_within_range    VARCHAR2(1),
        id_triage_vs_area      triage_vs_area.id_triage_vs_area%TYPE,
        msg_text_range_yes     sys_message.desc_message%TYPE,
        msg_text_range_no      sys_message.desc_message%TYPE,
        vsd_value              VARCHAR2(1),
        checked_blood_pressure BOOLEAN,
        missing_vs_mandatory   BOOLEAN,
        msg_text_y             sys_message.desc_message%TYPE,
        msg_text_x             sys_message.desc_message%TYPE,
        mandatory_no_limits    BOOLEAN);

    TYPE rec_degree IS RECORD(
        id_triage_color    triage_color.id_triage_color%TYPE,
        desc_triage_color  pk_translation.t_desc_translation,
        color              triage_color.color%TYPE,
        color_text         triage_color.color_text%TYPE,
        desc_accuity       pk_translation.t_desc_translation,
        urgency_level      triage_esi_level.esi_level%TYPE,
        desc_time_max      sys_message.desc_message%TYPE,
        flg_show           triage_color.flg_show%TYPE,
        esi_level_header   pk_translation.t_desc_translation,
        flg_selected       VARCHAR2(1),
        flg_active         VARCHAR2(1),
        desc_reassess_time sys_message.desc_message%TYPE);

    TYPE table_degrees IS TABLE OF rec_degree;

    TYPE rec_triage_level IS RECORD(
        id_triage_color         triage_color.id_triage_color%TYPE,
        current_triage_level    triage_esi_level.esi_level%TYPE,
        higher_vs_urgency_level triage_esi_level.esi_level%TYPE,
        flg_valid_board_level   VARCHAR2(1), --Used in questions screen. Tells if the current board is valid or not, if it isn't the user must select a new board/motive
        triage_can_change_color sys_config.value%TYPE,
        degrees                 table_degrees,
        defining_criteria       table_defining_criteria,
        other_defining_criteria table_defining_criteria,
        urgency_level_desc      sys_message.desc_message%TYPE, -- used for impose/propose
        flg_critical_look       VARCHAR2(1 CHAR));

    TYPE rec_vs_result IS RECORD(
        id_vital_sign        vital_sign.id_vital_sign%TYPE,
        internal_name        vital_sign.intern_name_vital_sign%TYPE,
        id_vital_sign_parent vital_sign.id_vital_sign%TYPE,
        urgency_level        triage_esi_level.esi_level%TYPE,
        message              sys_message.desc_message%TYPE, --This message is to send additional information to the user, for instance the peak flow message
        VALUE                vital_sign_read.value%TYPE,
        desc_value           pk_translation.t_desc_translation,
        flg_active           ds_def_event.flg_event_type%TYPE,
        rank                 vs_soft_inst.rank%TYPE);

    TYPE table_vs_results IS TABLE OF rec_vs_result;

    TYPE rec_chk_result IS RECORD(
        id_triage_vs_area     triage_vs_area.id_triage_vs_area%TYPE,
        select_option         triage.flg_accepted_option%TYPE,
        flg_show              VARCHAR2(1 CHAR),
        msg_title             sys_message.desc_message%TYPE,
        msg                   sys_message.desc_message%TYPE,
        msg_rank              NUMBER(6),
        button                VARCHAR2(1 CHAR),
        id_parent_tri_discrim triage_discriminator.id_triage_discriminator%TYPE, --Parent triage discriminator, in ESI some triage discriminators have multichoices where is possible to select child discriminators
        id_triage_discrim     triage_discriminator.id_triage_discriminator%TYPE,
        desc_discrim          pk_translation.t_desc_translation,
        id_triage             triage.id_triage%TYPE,
        flg_accepted_option   triage.flg_accepted_option%TYPE,
        vital_signs           table_vs_results,
        triage_level          rec_triage_level,
        flg_critical_look     VARCHAR2(1 CHAR));

    --END TRIAGE TYPES
    TYPE rec_disch_message IS RECORD(
        gp_id                   professional.id_professional%TYPE,
        gp_name                 professional.name%TYPE,
        episode_date            VARCHAR2(200 CHAR),
        episode_time            VARCHAR2(200 CHAR),
        episode_final_diagnoses VARCHAR2(1000 CHAR),
        episode_prof_name       professional.name%TYPE,
        patient_name            patient.name%TYPE,
        patient_nhs             pat_soc_attributes.national_health_number%TYPE,
        address_1               VARCHAR2(200 CHAR),
        address_2               institution.address%TYPE,
        address_3               institution.location%TYPE,
        address_4               institution.zip_code%TYPE,
        address_5               institution.phone_number%TYPE,
        gp_email                professional.email%TYPE,
        professional_email      professional.email%TYPE,
        attach_extension        VARCHAR2(10 CHAR),
        attach_name             VARCHAR2(200 CHAR),
        attachfile              BLOB);

    TYPE t_line IS RECORD(
        dt_status TIMESTAMP WITH LOCAL TIME ZONE,
        flg_text  VARCHAR2(10),
        content   VARCHAR2(1000),
        color     VARCHAR2(100),
        rank      NUMBER);
    TYPE table_line IS TABLE OF t_line;

    PROCEDURE open_my_cursor(i_cursor IN OUT cursor_step);
    PROCEDURE open_my_cursor(i_cursor IN OUT cursor_section);
    PROCEDURE open_my_cursor(i_cursor IN OUT cursor_field);

    PROCEDURE open_my_cursor(i_cursor IN OUT cursor_status);
    PROCEDURE open_my_cursor(i_cursor IN OUT cursor_assoc_prob);

    PROCEDURE open_my_cursor(i_cursor IN OUT cursor_discrim_child);
END;
/