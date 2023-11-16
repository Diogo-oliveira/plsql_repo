/*-- Last Change Revision: $Rev: 2028600 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:48 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_diagnosis_form IS

    -- Author  : ALEXANDRE.SANTOS
    -- Created : 23-02-2012 10:53:34
    -- Purpose : Specific dynamic screen logic for diagnosis form

    -- Public type declarations

    -- Public constant declarations
    --
    g_cfg_prim_tum_unit_meas      CONSTANT sys_config.id_sys_config%TYPE := 'DIAG_PRIM_TUMOR_SIZE_UNIT_MEAS';
    g_initial_date_default_config CONSTANT sys_config.id_sys_config%TYPE := 'DATE_OF_INITIAL_DIAGNOSIS_DEFAULT_VALUE';

    -- CONCEPT TYPES    
    g_cancer_type          CONSTANT diagnosis.concept_type_int_name%TYPE := 'CANCER_DIAGNOSIS';
    g_diagn_type           CONSTANT diagnosis.concept_type_int_name%TYPE := 'DIAGNOSIS';
    g_topography_type      CONSTANT diagnosis.concept_type_int_name%TYPE := 'TOPOGRAPHY';
    g_laterality_type      CONSTANT diagnosis.concept_type_int_name%TYPE := 'LATERALITY';
    g_diag_basis_type      CONSTANT diagnosis.concept_type_int_name%TYPE := 'BASIS_DIAGNOSIS';
    g_morphology_type      CONSTANT diagnosis.concept_type_int_name%TYPE := 'MORPHOLOGY';
    g_histology_type       CONSTANT diagnosis.concept_type_int_name%TYPE := 'HISTOLOGY';
    g_behavior_type        CONSTANT diagnosis.concept_type_int_name%TYPE := 'BEHAVIOR';
    g_grade_diff_type      CONSTANT diagnosis.concept_type_int_name%TYPE := 'GRADE_DIFFERENTIATION';
    g_grade_cell_lineage   CONSTANT diagnosis.concept_type_int_name%TYPE := 'CELL_LINEAGE';
    g_grade_hist_type      CONSTANT diagnosis.concept_type_int_name%TYPE := 'HISTOLOGY_GRADING_SYSTEM';
    g_stage_base_type      CONSTANT diagnosis.concept_type_int_name%TYPE := 'STAGING_BASIS';
    g_tnm_t_type           CONSTANT diagnosis.concept_type_int_name%TYPE := 'TNM_T';
    g_tnm_n_type           CONSTANT diagnosis.concept_type_int_name%TYPE := 'TNM_N';
    g_tnm_m_type           CONSTANT diagnosis.concept_type_int_name%TYPE := 'TNM_M';
    g_metastic_type        CONSTANT diagnosis.concept_type_int_name%TYPE := 'METASTIC_SITE';
    g_residual_type        CONSTANT diagnosis.concept_type_int_name%TYPE := 'RESIDUAL_TUMOR';
    g_surgical_type        CONSTANT diagnosis.concept_type_int_name%TYPE := 'SURGICAL_MARGINS';
    g_lymph_vasc_type      CONSTANT diagnosis.concept_type_int_name%TYPE := 'LYMPH_VASCULAR_INVASION';
    g_other_staging_sys    CONSTANT diagnosis.concept_type_int_name%TYPE := 'OTHER_STAGING_GROUP';
    g_pfactors_clin_signif CONSTANT diagnosis.concept_type_int_name%TYPE := 'CLINICALLY_SIGNIFICANT_STAGE_PROGNOSTIC_FACTOR';
    g_pfactors_staging     CONSTANT diagnosis.concept_type_int_name%TYPE := 'REQUIRED_STAGE_PROGNOSTIC_FACTOR';
    g_stage_group_type     CONSTANT diagnosis.concept_type_int_name%TYPE := 'STAGING_GROUP';
    g_validation_any_type  CONSTANT diagnosis.concept_type_int_name%TYPE := 'VALIDATION_ANY';
    g_validation_and_type  CONSTANT diagnosis.concept_type_int_name%TYPE := 'VALIDATION_AND';
    g_death_event          CONSTANT diagnosis.concept_type_int_name%TYPE := 'DEATH_EVENT';
    g_treatment_group      CONSTANT diagnosis.concept_type_int_name%TYPE := 'TREATMENT_GROUP';
    g_lesion_type          CONSTANT diagnosis.concept_type_int_name%TYPE := 'INTENTION';
    g_lesion_location_type CONSTANT diagnosis.concept_type_int_name%TYPE := 'PLACE_OF_OCCURRENCE';

    --ALERT-261232 - ALERT® REFERRAL - changes required for MX market
    g_causes_type CONSTANT diagnosis.concept_type_int_name%TYPE := 'CAUSES';

    --ACCIDENT AND EMERGENCY TYPES
    g_diag_condition_type  CONSTANT diagnosis.concept_type_int_name%TYPE := 'DIAGNOSIS_CONDITION';
    g_sub_analysis_type    CONSTANT diagnosis.concept_type_int_name%TYPE := 'SUB_ANALYSIS';
    g_ae_diagnosis_type    CONSTANT diagnosis.concept_type_int_name%TYPE := 'AE_DIAGNOSIS';
    g_anatomical_area_type CONSTANT diagnosis.concept_type_int_name%TYPE := 'ANATOMICAL_AREA';
    g_anatomical_side_type CONSTANT diagnosis.concept_type_int_name%TYPE := 'ANATOMICAL_SIDE';

    -- CONCEPT_CODES
    g_val_req_prog_fact_01_type CONSTANT diagnosis.code_icd%TYPE := 'VAL_REQ_PROG_FACT_01'; --Ex: VALIDATION_CONCEPT_GLEASON
    g_val_req_prog_fact_02_type CONSTANT diagnosis.code_icd%TYPE := 'VAL_REQ_PROG_FACT_02'; --Ex: VALIDATION_CONCEPT_PSA
    g_val_req_prog_fact_03_type CONSTANT diagnosis.code_icd%TYPE := 'VAL_REQ_PROG_FACT_03'; --Ex: VALIDATION_CONCEPT_RISK_FACTORS

    g_req_prog_fact_01_any_type CONSTANT diagnosis.code_icd%TYPE := 'REQ_PROG_FACT_01'; --Ex: GLEASON
    g_req_prog_fact_02_any_type CONSTANT diagnosis.code_icd%TYPE := 'REQ_PROG_FACT_02'; --Ex: PSA
    g_req_prog_fact_03_any_type CONSTANT diagnosis.code_icd%TYPE := 'REQ_PROG_FACT_03'; --Ex: RISK_FACTORS

    -- CONCEPT RELATIONS
    g_rel_is_a         CONSTANT diagnosis_relations_ea.cncpt_rel_type_int_name%TYPE := 'IS_A';
    g_rel_depends_on   CONSTANT diagnosis_relations_ea.cncpt_rel_type_int_name%TYPE := 'DEPENDS_ON';
    g_rel_finding_site CONSTANT diagnosis_relations_ea.cncpt_rel_type_int_name%TYPE := 'FINDING_SITE';
    g_rel_laterality   CONSTANT diagnosis_relations_ea.cncpt_rel_type_int_name%TYPE := 'LATERALITY';

    g_sys_list_yes_no     CONSTANT sys_list_group.internal_name%TYPE := 'DIAGNOSES_YES_NO';
    g_sys_list_yes_no_unk CONSTANT sys_list_group.internal_name%TYPE := 'DIAGNOSES_YES_NO_UNK';

    -- CONCEPT_TYPES
    g_cncpt_type_diag        CONSTANT diagnosis_ea.concept_type_int_name%TYPE := 'DIAGNOSIS';
    g_cncpt_type_cancer_diag CONSTANT diagnosis_ea.concept_type_int_name%TYPE := 'CANCER_DIAGNOSIS';
    g_cncpt_type_trauma_diag CONSTANT diagnosis_ea.concept_type_int_name%TYPE := 'CONSEQUENCE_OF_EXTERNAL_CAUSE';

    --DS components - Diagnosis ROOT components
    g_dsc_general_diagnosis   CONSTANT ds_component.internal_name%TYPE := 'GENERAL_DIAGNOSES';
    g_dsc_cancer_diagnosis    CONSTANT ds_component.internal_name%TYPE := 'CANCER_DIAGNOSES';
    g_dsc_acc_emerg_diagnosis CONSTANT ds_component.internal_name%TYPE := 'ACC_EMER_DIAGNOSES';

    --DS components - Diagnosis Nodes components
    g_dsc_general_caracterization CONSTANT ds_component.internal_name%TYPE := 'GENERAL_DIAGNOSES_CARACTERIZATION';
    g_dsc_general_additional_info CONSTANT ds_component.internal_name%TYPE := 'GENERAL_DIAGNOSES_ADDITIONAL_INFO';

    g_dsc_cancer_caracterization CONSTANT ds_component.internal_name%TYPE := 'CANCER_DIAGNOSES_CARACTERIZATION';
    g_dsc_cancer_prim_tum        CONSTANT ds_component.internal_name%TYPE := 'CANCER_DIAGNOSES_PRIMARY_TUMOR';
    g_dsc_cancer_staging         CONSTANT ds_component.internal_name%TYPE := 'CANCER_DIAGNOSES_STAGING';
    g_dsc_cancer_additional_info CONSTANT ds_component.internal_name%TYPE := 'CANCER_DIAGNOSES_ADDITIONAL_INFO';

    g_dsc_acc_emerg_caract   CONSTANT ds_component.internal_name%TYPE := 'ACC_EMER_DIAGNOSES_CARACTERIZATION';
    g_dsc_acc_emerg_add_info CONSTANT ds_component.internal_name%TYPE := 'ACC_EMER_DIAGNOSES_ADDITIONAL_INFO';

    --DS Components whose values doesn't depend on user selection
    g_dsc_general_invest_stat    CONSTANT ds_component.internal_name%TYPE := 'GENERAL_DIAGNOSES_INVESTIGATION_STATUS';
    g_dsc_general_add_problem    CONSTANT ds_component.internal_name%TYPE := 'GENERAL_DIAGNOSES_ADD_TO_PROBLEMS';
    g_dsc_cancer_invest_stat     CONSTANT ds_component.internal_name%TYPE := 'CANCER_DIAGNOSES_INVESTIGATION_STATUS';
    g_dsc_cancer_basis_diag      CONSTANT ds_component.internal_name%TYPE := 'CANCER_DIAGNOSES_BASIS_DIAG';
    g_dsc_cancer_basis_diag_ms   CONSTANT ds_component.internal_name%TYPE := 'CANCER_DIAGNOSES_BASIS_DIAG_MS';
    g_dsc_cancer_basis_diag_spec CONSTANT ds_component.internal_name%TYPE := 'CANCER_DIAGNOSES_BASIS_DIAG_SPEC';
    g_dsc_cancer_num_prim_tum    CONSTANT ds_component.internal_name%TYPE := 'CANCER_DIAGNOSES_NUM_PRIM_TUMORS';
    g_dsc_cancer_nprim_tum_ms_yn CONSTANT ds_component.internal_name%TYPE := 'CANCER_DIAGNOSES_NUM_PRIM_TUMORS_MS_YN';
    g_dsc_cancer_nprim_tum_num   CONSTANT ds_component.internal_name%TYPE := 'CANCER_DIAGNOSES_NUM_PRIM_TUMORS_NUM';
    g_dsc_cancer_topography      CONSTANT ds_component.internal_name%TYPE := 'CANCER_DIAGNOSES_TOPOGRAPHY';
    g_dsc_cancer_add_problem     CONSTANT ds_component.internal_name%TYPE := 'CANCER_DIAGNOSES_ADD_TO_PROBLEMS';

    --DS Components whose values depend on user selection
    g_dsc_cancer_laterality        CONSTANT ds_component.internal_name%TYPE := 'CANCER_DIAGNOSES_LATERALITY';
    g_dsc_cancer_histology         CONSTANT ds_component.internal_name%TYPE := 'CANCER_DIAGNOSES_HISTOLOGY'; --Histology is the name used in the diagnosis form, but we are refering to the id_morphology
    g_dsc_cancer_behavior          CONSTANT ds_component.internal_name%TYPE := 'CANCER_DIAGNOSES_BEHAVIOR';
    g_dsc_cancer_hist_grade        CONSTANT ds_component.internal_name%TYPE := 'CANCER_DIAGNOSES_HISTOLOGIC_GRADE';
    g_dsc_cancer_ograd_system      CONSTANT ds_component.internal_name%TYPE := 'CANCER_DIAGNOSES_OTHER_GRADING_SYSTEM';
    g_dsc_cancer_prim_tum_siz      CONSTANT ds_component.internal_name%TYPE := 'CANCER_DIAGNOSES_PRIMARY_TUMOR_SIZE';
    g_dsc_cancer_prim_tum_siz_unk  CONSTANT ds_component.internal_name%TYPE := 'CANCER_DIAGNOSES_PRIMARY_TUMOR_SIZE_UNKNOWN';
    g_dsc_cancer_prim_tum_siz_num  CONSTANT ds_component.internal_name%TYPE := 'CANCER_DIAGNOSES_PRIMARY_TUMOR_SIZE_NUMERIC';
    g_dsc_cancer_prim_tum_siz_desc CONSTANT ds_component.internal_name%TYPE := 'CANCER_DIAGNOSES_PRIMARY_TUMOR_SIZE_DESCRIPTIVE';
    g_dsc_cancer_staging_basis     CONSTANT ds_component.internal_name%TYPE := 'CANCER_DIAGNOSES_STAGING_BASIS';
    g_dsc_cancer_tnm               CONSTANT ds_component.internal_name%TYPE := 'CANCER_DIAGNOSES_TNM';
    g_dsc_cancer_tnm_tnm           CONSTANT ds_component.internal_name%TYPE := 'CANCER_DIAGNOSES_TNM_TNM';
    g_dsc_cancer_tnm_t             CONSTANT ds_component.internal_name%TYPE := 'CANCER_DIAGNOSES_TNM_T';
    g_dsc_cancer_tnm_n             CONSTANT ds_component.internal_name%TYPE := 'CANCER_DIAGNOSES_TNM_N';
    g_dsc_cancer_tnm_m             CONSTANT ds_component.internal_name%TYPE := 'CANCER_DIAGNOSES_TNM_M';
    g_dsc_cancer_metast_sites      CONSTANT ds_component.internal_name%TYPE := 'CANCER_DIAGNOSES_METASTATIC_SITES';
    g_dsc_cancer_progn_factors     CONSTANT ds_component.internal_name%TYPE := 'CANCER_DIAGNOSES_PROGNOSTIC_FACTORS';
    g_dsc_cancer_progn_factors_req CONSTANT ds_component.internal_name%TYPE := 'CANCER_DIAGNOSES_PROGNOSTIC_FACTORS_REQ_FACT_STAGING';
    g_dsc_cancer_progn_factors_cli CONSTANT ds_component.internal_name%TYPE := 'CANCER_DIAGNOSES_PROGNOSTIC_FACTORS_CLINICALLY_SIGNIFICANT';
    g_dsc_cancer_residual_tum      CONSTANT ds_component.internal_name%TYPE := 'CANCER_DIAGNOSES_RESIDUAL_TUMOR';
    g_dsc_cancer_surg_margins      CONSTANT ds_component.internal_name%TYPE := 'CANCER_DIAGNOSES_SURGICAL_MARGINS';
    g_dsc_cancer_lymp_vasc_inv     CONSTANT ds_component.internal_name%TYPE := 'CANCER_DIAGNOSES_LYMPH_VASCULAR_INVASION';
    g_dsc_cancer_ostaging_sys      CONSTANT ds_component.internal_name%TYPE := 'CANCER_DIAGNOSES_OTHER_STAGING_SYSTEM';

    g_dsc_acc_emer_sub_analysis CONSTANT ds_component.internal_name%TYPE := 'ACC_EMER_DIAGNOSES_SUB_ANALYSIS';
    g_dsc_acc_emer_anat_area    CONSTANT ds_component.internal_name%TYPE := 'ACC_EMER_DIAGNOSES_ANATOMICAL_AREA';
    g_dsc_acc_emer_anat_side    CONSTANT ds_component.internal_name%TYPE := 'ACC_EMER_DIAGNOSES_ANATOMICAL_SIDE';

    --Other DS Components
    g_dsc_general_dt_init_diag   CONSTANT ds_component.internal_name%TYPE := 'GENERAL_DIAGNOSES_DT_INIT_DIAG';
    g_dsc_cancer_dt_init_diag    CONSTANT ds_component.internal_name%TYPE := 'CANCER_DIAGNOSES_DT_INIT_DIAG';
    g_dsc_general_age_init_diag  CONSTANT ds_component.internal_name%TYPE := 'GENERAL_DIAGNOSES_AGE_INIT_DIAG';
    g_dsc_cancer_age_init_diag   CONSTANT ds_component.internal_name%TYPE := 'CANCER_DIAGNOSES_AGE_INIT_DIAG';
    g_dsc_general_recur          CONSTANT ds_component.internal_name%TYPE := 'GENERAL_DIAGNOSES_RECURRENCE';
    g_dsc_general_princ_diag     CONSTANT ds_component.internal_name%TYPE := 'GENERAL_DIAGNOSES_PRINCIPAL_DIAG';
    g_dsc_general_notes          CONSTANT ds_component.internal_name%TYPE := 'GENERAL_DIAGNOSES_NOTES';
    g_dsc_cancer_recur           CONSTANT ds_component.internal_name%TYPE := 'CANCER_DIAGNOSES_RECURRENCE';
    g_dsc_cancer_addit_path_info CONSTANT ds_component.internal_name%TYPE := 'CANCER_DIAGNOSES_ADDITIONAL_PATH_INFO';
    g_dsc_cancer_stage_grp       CONSTANT ds_component.internal_name%TYPE := 'CANCER_DIAGNOSES_STAGE_GROUP';
    g_dsc_cancer_stage           CONSTANT ds_component.internal_name%TYPE := 'CANCER_DIAGNOSES_STAGE';
    g_dsc_cancer_princ_diag      CONSTANT ds_component.internal_name%TYPE := 'CANCER_DIAGNOSES_PRINCIPAL_DIAG';
    g_dsc_cancer_notes           CONSTANT ds_component.internal_name%TYPE := 'CANCER_DIAGNOSES_NOTES';

    g_dsc_lesion_location CONSTANT ds_component.internal_name%TYPE := 'GENERAL_DIAGNOSES_LESION_LOCATION';
    g_dsc_lesion_type     CONSTANT ds_component.internal_name%TYPE := 'GENERAL_DIAGNOSES_LESION_TYPE';
    g_dsc_complications   CONSTANT ds_component.internal_name%TYPE := 'GENERAL_DIAGNOSES_COMPLICATIONS';
    g_dsc_general_rank    CONSTANT ds_component.internal_name%TYPE := 'GENERAL_DIAGNOSES_RANK';

    -- Others
    g_id_tnm_none   CONSTANT epis_diag_stag.id_tnm_t%TYPE := -1;
    g_code_tnm_none CONSTANT epis_diag_stag.code_tnm_t%TYPE := 'NONE';

    --DB fields names
    g_db_fld_add_to_problems       CONSTANT ds_component.internal_name%TYPE := 'ADD_TO_PROBLEMS';
    g_db_fld_additional_path_info  CONSTANT ds_component.internal_name%TYPE := 'ADDITIONAL_PATH_INFO';
    g_db_fld_age_init_diag         CONSTANT ds_component.internal_name%TYPE := 'AGE_INIT_DIAG';
    g_db_fld_anatomical_area       CONSTANT ds_component.internal_name%TYPE := 'ANATOMICAL_AREA';
    g_db_fld_anatomical_side       CONSTANT ds_component.internal_name%TYPE := 'ANATOMICAL_SIDE';
    g_db_fld_basis_diag            CONSTANT ds_component.internal_name%TYPE := 'BASIS_DIAG';
    g_db_fld_basis_diag_ms         CONSTANT ds_component.internal_name%TYPE := 'BASIS_DIAG_MS';
    g_db_fld_basis_diag_spec       CONSTANT ds_component.internal_name%TYPE := 'BASIS_DIAG_SPEC';
    g_db_fld_behavior              CONSTANT ds_component.internal_name%TYPE := 'BEHAVIOR';
    g_db_fld_dt_init_diag          CONSTANT ds_component.internal_name%TYPE := 'DT_INIT_DIAG';
    g_db_fld_histologic_grade      CONSTANT ds_component.internal_name%TYPE := 'HISTOLOGIC_GRADE';
    g_db_fld_histology             CONSTANT ds_component.internal_name%TYPE := 'HISTOLOGY';
    g_db_fld_investigation_status  CONSTANT ds_component.internal_name%TYPE := 'INVESTIGATION_STATUS';
    g_db_fld_laterality            CONSTANT ds_component.internal_name%TYPE := 'LATERALITY';
    g_db_fld_lymph_vasc_invasion   CONSTANT ds_component.internal_name%TYPE := 'LYMPH_VASCULAR_INVASION';
    g_db_fld_metastatic_sites      CONSTANT ds_component.internal_name%TYPE := 'METASTATIC_SITES';
    g_db_fld_notes                 CONSTANT ds_component.internal_name%TYPE := 'NOTES';
    g_db_fld_num_prim_tumors       CONSTANT ds_component.internal_name%TYPE := 'NUM_PRIM_TUMORS';
    g_db_fld_num_prim_tumors_ms_yn CONSTANT ds_component.internal_name%TYPE := 'NUM_PRIM_TUMORS_MS_YN';
    g_db_fld_num_prim_tumors_num   CONSTANT ds_component.internal_name%TYPE := 'NUM_PRIM_TUMORS_NUM';
    g_db_fld_other_grading_system  CONSTANT ds_component.internal_name%TYPE := 'OTHER_GRADING_SYSTEM';
    g_db_fld_other_staging_system  CONSTANT ds_component.internal_name%TYPE := 'OTHER_STAGING_SYSTEM';
    g_db_fld_ptumor_size           CONSTANT ds_component.internal_name%TYPE := 'PRIMARY_TUMOR_SIZE';
    g_db_fld_ptumor_size_desc      CONSTANT ds_component.internal_name%TYPE := 'PRIMARY_TUMOR_SIZE_DESCRIPTIVE';
    g_db_fld_ptumor_size_numeric   CONSTANT ds_component.internal_name%TYPE := 'PRIMARY_TUMOR_SIZE_NUMERIC';
    g_db_fld_ptumor_size_unknown   CONSTANT ds_component.internal_name%TYPE := 'PRIMARY_TUMOR_SIZE_UNKNOWN';
    g_db_fld_principal_diag        CONSTANT ds_component.internal_name%TYPE := 'PRINCIPAL_DIAG';
    g_db_fld_prognostic_factors    CONSTANT ds_component.internal_name%TYPE := 'PROGNOSTIC_FACTORS';
    g_db_fld_recurrence            CONSTANT ds_component.internal_name%TYPE := 'RECURRENCE';
    g_db_fld_residual_tumor        CONSTANT ds_component.internal_name%TYPE := 'RESIDUAL_TUMOR';
    g_db_fld_stage                 CONSTANT ds_component.internal_name%TYPE := 'STAGE';
    g_db_fld_stage_group           CONSTANT ds_component.internal_name%TYPE := 'STAGE_GROUP';
    g_db_fld_staging_basis         CONSTANT ds_component.internal_name%TYPE := 'STAGING_BASIS';
    g_db_fld_sub_analysis          CONSTANT ds_component.internal_name%TYPE := 'SUB_ANALYSIS';
    g_db_fld_surgical_margins      CONSTANT ds_component.internal_name%TYPE := 'SURGICAL_MARGINS';
    g_db_fld_tnm                   CONSTANT ds_component.internal_name%TYPE := 'TNM';
    g_db_fld_tnm_m                 CONSTANT ds_component.internal_name%TYPE := 'TNM_M';
    g_db_fld_tnm_n                 CONSTANT ds_component.internal_name%TYPE := 'TNM_N';
    g_db_fld_tnm_t                 CONSTANT ds_component.internal_name%TYPE := 'TNM_T';
    g_db_fld_tnm_tnm               CONSTANT ds_component.internal_name%TYPE := 'TNM_TNM';
    g_db_fld_topography            CONSTANT ds_component.internal_name%TYPE := 'TOPOGRAPHY';
    g_db_lesion_location           CONSTANT ds_component.internal_name%TYPE := 'LESION_LOCATION';
    g_db_lesion_type               CONSTANT ds_component.internal_name%TYPE := 'LESION_TYPE';
    g_db_complications             CONSTANT ds_component.internal_name%TYPE := 'COMPLICATIONS';
    g_db_fld_rank                  CONSTANT ds_component.internal_name%TYPE := 'RANK';

    -- Public variable declarations
    --DIAGNOSIS SECTION - General characterization
    CURSOR c_basis_diag
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_basis_diag IN diagnosis_ea.id_concept_term%TYPE DEFAULT NULL
    ) IS
    --This cursor is only used in cancer diagnosis in general diagnosis this field is a free text
        SELECT t.id_basis_diag,
               nvl2(t.desc_basis_parent, pk_utils.to_bold(t.desc_basis_parent) || chr(10), '') || t.desc_basis_diag desc_basis_diag,
               t.flg_default,
               t.rank,
               xmlelement("ADDITIONAL_INFO",
                          xmlattributes(t.flg_default,
                                        (nvl2(t.desc_basis_parent, t.desc_basis_parent || ' - ', '') || t.desc_basis_diag)
                                        desc_basis_diag_closed)) addit_info
          FROM (SELECT id_concept_term id_basis_diag,
                       htf.escape_sc(pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                i_prof               => i_prof,
                                                                i_id_alert_diagnosis => id_concept_term,
                                                                i_id_diagnosis       => id_concept_version,
                                                                i_code_diagnosis     => code_diagnosis,
                                                                i_diagnosis_language => id_language,
                                                                i_code               => concept_code,
                                                                i_flg_other          => flg_other,
                                                                i_flg_std_diag       => flg_icd9,
                                                                i_flg_search_mode    => pk_alert_constant.g_yes)) desc_basis_diag,
                       nvl2(id_parent,
                            htf.escape_sc(pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                     i_prof               => i_prof,
                                                                     i_id_diagnosis       => id_parent,
                                                                     i_diagnosis_language => id_language,
                                                                     i_code               => NULL,
                                                                     i_flg_other          => pk_alert_constant.g_no,
                                                                     i_flg_std_diag       => pk_alert_constant.g_yes,
                                                                     i_flg_search_mode    => pk_alert_constant.g_yes)),
                            '') desc_basis_parent,
                       rank,
                       CASE
                            WHEN i_basis_diag IS NULL THEN
                             pk_alert_constant.g_no
                            ELSE
                             decode(i_basis_diag, id_concept_term, pk_alert_constant.g_yes, pk_alert_constant.g_no)
                        END flg_default
                  FROM (SELECT d.id_concept_term,
                               d.id_concept_version,
                               pk_diagnosis.get_diagnosis_parent(i_diagnosis   => d.id_concept_version,
                                                                 i_institution => i_prof.institution,
                                                                 i_software    => i_prof.software) id_parent,
                               d.code_diagnosis,
                               d.id_language,
                               d.concept_code,
                               d.flg_other,
                               d.flg_icd9,
                               d.rank
                          FROM diagnosis_ea d
                         WHERE d.concept_type_int_name = g_diag_basis_type
                           AND d.id_institution = i_prof.institution
                           AND d.id_software = i_prof.software
                           AND NOT EXISTS (SELECT 0
                                  FROM diagnosis_relations_ea dr2
                                 WHERE dr2.cncpt_rel_type_int_name = g_rel_is_a
                                   AND dr2.concept_type_int_name1 = g_diag_basis_type
                                   AND dr2.concept_type_int_name2 = g_diag_basis_type
                                   AND dr2.id_concept_version_2 = d.id_concept_version
                                   AND dr2.id_institution = i_prof.institution
                                   AND dr2.id_software = i_prof.software))) t
         ORDER BY t.rank, t.desc_basis_diag;

    CURSOR c_treatment_group
    (
        i_prof           IN profissional,
        i_topography     IN diagnosis.id_diagnosis%TYPE,
        i_any_topography IN diagnosis.id_diagnosis%TYPE,
        i_morphology     IN diagnosis.id_diagnosis%TYPE,
        i_any_morphology IN diagnosis.id_diagnosis%TYPE
    ) IS
        SELECT t.id_treatment_group
          FROM (SELECT d.id_concept_version id_treatment_group, d.rank
                  FROM diagnosis_relations_ea dr
                  JOIN diagnosis_ea d
                    ON d.id_concept_version = dr.id_concept_version_1
                 WHERE dr.cncpt_rel_type_int_name = g_rel_depends_on
                   AND dr.concept_type_int_name1 = g_treatment_group
                   AND dr.concept_type_int_name2 = g_topography_type
                   AND dr.id_concept_version_2 IN (i_topography, i_any_topography)
                   AND dr.id_institution = i_prof.institution
                   AND dr.id_software = i_prof.software
                   AND d.id_institution = i_prof.institution
                   AND d.id_software = i_prof.software
                   AND EXISTS (SELECT 0
                          FROM diagnosis_relations_ea dr2
                         WHERE dr2.cncpt_rel_type_int_name = g_rel_depends_on
                           AND dr2.concept_type_int_name1 = g_treatment_group
                           AND dr2.concept_type_int_name2 = g_morphology_type
                           AND dr2.id_concept_version_1 = d.id_concept_version
                           AND dr2.id_concept_version_2 IN (i_morphology, i_any_morphology)
                           AND dr2.id_institution = i_prof.institution
                           AND dr2.id_software = i_prof.software)) t
         ORDER BY t.rank;

    --DIAGNOSIS SECTION - Primary Tumor
    CURSOR c_topographies
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_diagnosis     IN diagnosis.id_diagnosis%TYPE,
        i_any_diagnosis IN diagnosis.id_diagnosis%TYPE,
        i_topography    IN diagnosis_ea.id_concept_term%TYPE DEFAULT NULL
    ) IS
        SELECT t.id_topography,
               t.desc_topography,
               t.flg_default,
               t.rank,
               xmlelement("ADDITIONAL_INFO", xmlattributes(t.flg_default)) addit_info
          FROM (SELECT id_concept_term id_topography,
                       htf.escape_sc(pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                i_prof               => i_prof,
                                                                i_id_alert_diagnosis => id_concept_term,
                                                                i_id_diagnosis       => id_concept_version,
                                                                i_code_diagnosis     => code_diagnosis,
                                                                i_diagnosis_language => id_language,
                                                                i_code               => concept_code,
                                                                i_flg_other          => flg_other,
                                                                i_flg_std_diag       => flg_icd9,
                                                                i_flg_search_mode    => pk_alert_constant.g_yes)) desc_topography,
                       rank,
                       CASE
                            WHEN i_topography IS NULL THEN
                             flg_default
                            ELSE
                             decode(i_topography, id_concept_term, pk_alert_constant.g_yes, pk_alert_constant.g_no)
                        END flg_default
                  FROM (SELECT DISTINCT d.id_concept_term,
                                        d.id_concept_version,
                                        d.code_diagnosis,
                                        d.id_language,
                                        d.concept_code,
                                        d.flg_other,
                                        d.flg_icd9,
                                        d.rank,
                                        dr.flg_default
                          FROM diagnosis_relations_ea dr
                          JOIN diagnosis_ea d
                            ON d.id_concept_version = dr.id_concept_version_1
                         WHERE dr.cncpt_rel_type_int_name = g_rel_depends_on
                           AND dr.concept_type_int_name1 = g_topography_type
                           AND dr.concept_type_int_name2 = g_cancer_type
                           AND dr.id_concept_version_2 IN (i_diagnosis, i_any_diagnosis)
                           AND dr.id_institution = i_prof.institution
                           AND dr.id_software = i_prof.software
                           AND d.id_institution = i_prof.institution
                           AND d.id_software = i_prof.software)) t
         ORDER BY t.rank, t.desc_topography;

    CURSOR c_lateralities
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_topography     IN diagnosis.id_diagnosis%TYPE,
        i_any_topography IN diagnosis.id_diagnosis%TYPE,
        i_laterality     IN diagnosis_ea.id_concept_term%TYPE DEFAULT NULL
    ) IS
        SELECT t.id_laterality,
               t.desc_laterality,
               t.flg_default,
               t.rank,
               xmlelement("ADDITIONAL_INFO", xmlattributes(t.flg_default)) addit_info
          FROM (SELECT id_concept_term id_laterality,
                       htf.escape_sc(pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                i_prof               => i_prof,
                                                                i_id_alert_diagnosis => id_concept_term,
                                                                i_id_diagnosis       => id_concept_version,
                                                                i_code_diagnosis     => code_diagnosis,
                                                                i_diagnosis_language => id_language,
                                                                i_code               => NULL,
                                                                i_flg_other          => flg_other,
                                                                i_flg_std_diag       => flg_icd9,
                                                                i_flg_search_mode    => pk_alert_constant.g_yes)) desc_laterality,
                       rank,
                       CASE
                            WHEN i_laterality IS NULL THEN
                             flg_default
                            ELSE
                             decode(i_laterality, id_concept_term, pk_alert_constant.g_yes, pk_alert_constant.g_no)
                        END flg_default
                  FROM (SELECT DISTINCT d.id_concept_term,
                                        d.id_concept_version,
                                        d.code_diagnosis,
                                        d.id_language,
                                        d.concept_code,
                                        d.flg_other,
                                        d.flg_icd9,
                                        d.rank,
                                        dr.flg_default
                          FROM diagnosis_relations_ea dr
                          JOIN diagnosis_ea d
                            ON d.id_concept_version = dr.id_concept_version_1
                         WHERE dr.cncpt_rel_type_int_name = g_rel_depends_on
                           AND dr.concept_type_int_name1 = g_laterality_type
                           AND dr.concept_type_int_name2 = g_topography_type
                           AND dr.id_concept_version_2 IN (i_topography, i_any_topography)
                           AND dr.id_institution = i_prof.institution
                           AND dr.id_software = i_prof.software
                           AND d.id_institution = i_prof.institution
                           AND d.id_software = i_prof.software)) t
         ORDER BY t.rank, t.desc_laterality;

    CURSOR c_histologies
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_topography     IN diagnosis.id_diagnosis%TYPE,
        i_any_topography IN diagnosis.id_diagnosis%TYPE,
        i_basis_diag     IN diagnosis.id_diagnosis%TYPE,
        i_any_basis_diag IN diagnosis.id_diagnosis%TYPE,
        i_morphology     IN diagnosis_ea.id_concept_term%TYPE DEFAULT NULL
    ) IS
        SELECT t.id_morphology,
               t.desc_morphology,
               t.flg_default,
               t.rank,
               xmlelement("ADDITIONAL_INFO", xmlattributes(t.flg_default, t.desc_histology)) addit_info
          FROM (SELECT id_concept_term id_morphology,
                       htf.escape_sc(pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                i_prof               => i_prof,
                                                                i_id_alert_diagnosis => id_concept_term,
                                                                i_id_diagnosis       => id_concept_version,
                                                                i_code_diagnosis     => code_diagnosis,
                                                                i_diagnosis_language => id_language,
                                                                i_code               => concept_code,
                                                                i_flg_other          => flg_other,
                                                                i_flg_std_diag       => flg_icd9,
                                                                i_flg_search_mode    => pk_alert_constant.g_yes)) desc_morphology,
                       pk_diagnosis_core.get_desc_histology(i_lang, i_prof, id_concept_version) desc_histology,
                       rank,
                       CASE
                            WHEN i_morphology IS NULL THEN
                             flg_default
                            ELSE
                             decode(i_morphology, id_concept_term, pk_alert_constant.g_yes, pk_alert_constant.g_no)
                        END flg_default
                  FROM (SELECT DISTINCT d.id_concept_term,
                                        d.id_concept_version,
                                        d.code_diagnosis,
                                        d.id_language,
                                        d.concept_code,
                                        d.flg_other,
                                        d.flg_icd9,
                                        d.rank,
                                        dr.flg_default
                          FROM diagnosis_relations_ea dr
                          JOIN diagnosis_ea d
                            ON d.id_concept_version = dr.id_concept_version_1
                         WHERE dr.cncpt_rel_type_int_name = g_rel_depends_on
                           AND dr.concept_type_int_name1 = g_morphology_type
                           AND dr.concept_type_int_name2 = g_topography_type
                           AND dr.id_concept_version_2 IN (i_topography, i_any_topography)
                           AND dr.id_institution = i_prof.institution
                           AND dr.id_software = i_prof.software
                           AND d.id_institution = i_prof.institution
                           AND d.id_software = i_prof.software
                           AND EXISTS (SELECT 0
                                  FROM diagnosis_relations_ea dr2
                                 WHERE dr2.cncpt_rel_type_int_name = g_rel_depends_on
                                   AND dr2.concept_type_int_name1 = g_morphology_type
                                   AND dr2.concept_type_int_name2 = g_diag_basis_type
                                   AND dr2.id_concept_version_1 = d.id_concept_version
                                   AND dr2.id_concept_version_2 IN (i_basis_diag, i_any_basis_diag)
                                   AND dr2.id_institution = i_prof.institution
                                   AND dr2.id_software = i_prof.software))) t
         ORDER BY t.rank, t.desc_morphology;

    CURSOR c_behaviours
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_morphology IN diagnosis.id_diagnosis%TYPE,
        i_behavior   IN diagnosis_ea.id_concept_term%TYPE DEFAULT NULL
    ) IS
        SELECT t.id_behavior,
               t.desc_behavior,
               t.flg_default,
               t.rank,
               xmlelement("ADDITIONAL_INFO", xmlattributes(t.flg_default)) addit_info
          FROM (SELECT d.id_concept_term id_behavior,
                       htf.escape_sc(pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                i_prof               => i_prof,
                                                                i_id_alert_diagnosis => d.id_concept_term,
                                                                i_id_diagnosis       => d.id_concept_version,
                                                                i_code_diagnosis     => d.code_diagnosis,
                                                                i_diagnosis_language => d.id_language,
                                                                i_code               => d.concept_code,
                                                                i_flg_other          => d.flg_other,
                                                                i_flg_std_diag       => d.flg_icd9,
                                                                i_flg_search_mode    => pk_alert_constant.g_yes)) desc_behavior,
                       d.rank,
                       CASE
                            WHEN i_behavior IS NULL THEN
                             dr.flg_default
                            ELSE
                             decode(i_behavior, d.id_concept_term, pk_alert_constant.g_yes, pk_alert_constant.g_no)
                        END flg_default
                  FROM diagnosis_relations_ea dr
                  JOIN diagnosis_ea d
                    ON d.id_concept_version = dr.id_concept_version_2
                 WHERE dr.cncpt_rel_type_int_name = g_rel_is_a
                   AND dr.concept_type_int_name1 = g_morphology_type
                   AND dr.concept_type_int_name2 = g_behavior_type
                   AND dr.id_concept_version_1 = i_morphology
                   AND dr.id_institution = i_prof.institution
                   AND dr.id_software = i_prof.software
                   AND d.id_institution = i_prof.institution
                   AND d.id_software = i_prof.software
                UNION
                SELECT id_concept_term id_behavior,
                       htf.escape_sc(pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                i_prof               => i_prof,
                                                                i_id_alert_diagnosis => d.id_concept_term,
                                                                i_id_diagnosis       => d.id_concept_version,
                                                                i_code_diagnosis     => d.code_diagnosis,
                                                                i_diagnosis_language => d.id_language,
                                                                i_code               => d.concept_code,
                                                                i_flg_other          => d.flg_other,
                                                                i_flg_std_diag       => d.flg_icd9,
                                                                i_flg_search_mode    => pk_alert_constant.g_yes)) desc_behavior,
                       d.rank,
                       CASE
                           WHEN i_behavior IS NULL THEN
                            pk_alert_constant.g_no
                           ELSE
                            decode(i_behavior, d.id_concept_term, pk_alert_constant.g_yes, pk_alert_constant.g_no)
                       END flg_default
                  FROM diagnosis_ea d
                 WHERE d.concept_type_int_name = g_behavior_type
                   AND d.concept_code = '2'
                   AND d.id_institution = i_prof.institution
                   AND d.id_software = i_prof.software
                   AND NOT EXISTS (SELECT 0
                          FROM diagnosis_relations_ea dr
                         WHERE dr.cncpt_rel_type_int_name = g_rel_is_a
                           AND dr.concept_type_int_name1 = g_morphology_type
                           AND dr.concept_type_int_name2 = g_behavior_type
                           AND dr.id_concept_version_2 = d.id_concept_version
                           AND dr.id_concept_version_1 = i_morphology
                           AND dr.id_institution = i_prof.institution
                           AND dr.id_software = i_prof.software)) t
         ORDER BY t.rank, t.desc_behavior;

    CURSOR c_histological_grade
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_topography         IN diagnosis.id_diagnosis%TYPE,
        i_histological_grade IN diagnosis_ea.id_concept_term%TYPE DEFAULT NULL
    ) IS
        SELECT t.id_histological_grade,
               t.desc_histological_grade,
               t.flg_default,
               t.rank,
               xmlelement("ADDITIONAL_INFO", xmlattributes(t.flg_default)) addit_info
          FROM (SELECT d.id_concept_term id_histological_grade,
                       htf.escape_sc(pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                i_prof               => i_prof,
                                                                i_id_alert_diagnosis => d.id_concept_term,
                                                                i_id_diagnosis       => d.id_concept_version,
                                                                i_code_diagnosis     => d.code_diagnosis,
                                                                i_diagnosis_language => d.id_language,
                                                                i_code               => d.concept_code,
                                                                i_flg_other          => d.flg_other,
                                                                i_flg_std_diag       => d.flg_icd9,
                                                                i_flg_search_mode    => pk_alert_constant.g_yes)) desc_histological_grade,
                       d.rank,
                       CASE
                            WHEN i_histological_grade IS NULL THEN
                             dr.flg_default
                            ELSE
                             decode(i_histological_grade, id_concept_term, pk_alert_constant.g_yes, pk_alert_constant.g_no)
                        END flg_default
                  FROM diagnosis_relations_ea dr
                  JOIN diagnosis_ea d
                    ON d.id_concept_version = dr.id_concept_version_1
                 WHERE dr.cncpt_rel_type_int_name = g_rel_depends_on
                   AND dr.concept_type_int_name1 IN (g_grade_diff_type, g_grade_cell_lineage)
                   AND dr.concept_type_int_name2 = g_topography_type
                   AND dr.id_concept_version_2 = i_topography
                   AND dr.id_institution = i_prof.institution
                   AND dr.id_software = i_prof.software
                   AND d.id_institution = i_prof.institution
                   AND d.id_software = i_prof.software) t
         ORDER BY t.rank, t.desc_histological_grade;

    CURSOR c_other_grading_sys
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_topography          IN diagnosis.id_diagnosis%TYPE,
        i_any_topography      IN diagnosis.id_diagnosis%TYPE,
        i_morphology          IN diagnosis.id_diagnosis%TYPE,
        i_any_morphology      IN diagnosis.id_diagnosis%TYPE,
        i_treatment_group     IN diagnosis.id_diagnosis%TYPE,
        i_any_treatment_group IN diagnosis.id_diagnosis%TYPE,
        i_other_grading_sys   IN diagnosis_ea.id_concept_term%TYPE DEFAULT NULL
    ) IS
        SELECT t.id_other_grading_sys,
               t.desc_other_grading_sys,
               t.flg_default,
               t.rank,
               xmlelement("ADDITIONAL_INFO", xmlattributes(t.flg_default, t.desc_grading_title)) addit_info
          FROM (SELECT d.id_concept_term id_other_grading_sys,
                       htf.escape_sc(pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                i_prof               => i_prof,
                                                                i_id_alert_diagnosis => d.id_concept_term,
                                                                i_id_diagnosis       => d.id_concept_version,
                                                                i_code_diagnosis     => d.code_diagnosis,
                                                                i_diagnosis_language => d.id_language,
                                                                i_code               => d.concept_code,
                                                                i_flg_other          => d.flg_other,
                                                                i_flg_std_diag       => d.flg_icd9,
                                                                i_flg_search_mode    => pk_alert_constant.g_yes)) desc_other_grading_sys,
                       htf.escape_sc(pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                i_prof               => i_prof,
                                                                i_id_diagnosis       => pk_diagnosis_core.get_diagnosis_parent(d.id_concept_version,
                                                                                                                               i_prof.institution,
                                                                                                                               i_prof.software),
                                                                i_diagnosis_language => d.id_language,
                                                                i_code               => NULL,
                                                                i_flg_other          => pk_alert_constant.g_no,
                                                                i_flg_std_diag       => pk_alert_constant.g_yes,
                                                                i_flg_search_mode    => pk_alert_constant.g_yes)) desc_grading_title,
                       d.rank,
                       CASE
                            WHEN i_other_grading_sys IS NULL THEN
                             dr.flg_default
                            ELSE
                             decode(i_other_grading_sys, id_concept_term, pk_alert_constant.g_yes, pk_alert_constant.g_no)
                        END flg_default
                  FROM diagnosis_relations_ea dr
                  JOIN diagnosis_ea d
                    ON d.id_concept_version = dr.id_concept_version_1
                 WHERE dr.cncpt_rel_type_int_name = g_rel_depends_on
                   AND dr.concept_type_int_name1 = g_grade_hist_type
                   AND dr.concept_type_int_name2 = g_topography_type
                   AND dr.id_concept_version_2 IN (i_topography, i_any_topography)
                   AND dr.id_institution = i_prof.institution
                   AND dr.id_software = i_prof.software
                   AND d.id_institution = i_prof.institution
                   AND d.id_software = i_prof.software
                   AND EXISTS (SELECT 0
                          FROM diagnosis_relations_ea dr2
                         WHERE dr2.cncpt_rel_type_int_name = g_rel_depends_on
                           AND dr2.concept_type_int_name1 = g_grade_hist_type
                           AND dr2.concept_type_int_name2 = g_morphology_type
                           AND dr2.id_concept_version_1 = d.id_concept_version
                           AND dr2.id_concept_version_2 IN (i_morphology, i_any_morphology)
                           AND dr2.id_institution = i_prof.institution
                           AND dr2.id_software = i_prof.software)
                   AND EXISTS (SELECT 0
                          FROM diagnosis_relations_ea dr2
                         WHERE dr2.cncpt_rel_type_int_name = g_rel_depends_on
                           AND dr2.concept_type_int_name1 = g_grade_hist_type
                           AND dr2.concept_type_int_name2 = g_treatment_group
                           AND dr2.id_concept_version_1 = d.id_concept_version
                           AND dr2.id_concept_version_2 IN (i_treatment_group, i_any_treatment_group)
                           AND dr2.id_institution = i_prof.institution
                           AND dr2.id_software = i_prof.software)) t
         ORDER BY t.rank, t.desc_other_grading_sys;

    --DIAGNOSIS SECTION - Staging
    CURSOR c_staging_basis
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_flg_edit_mode IN VARCHAR2,
        i_staging_basis IN diagnosis.id_diagnosis%TYPE
    ) IS
        SELECT t.id_staging_basis, t.desc_staging_basis, t.flg_default, t.rank
          FROM (SELECT id_concept_term id_staging_basis,
                       pk_diagnosis.std_staging_basis_desc(i_lang               => i_lang,
                                                           i_prof               => i_prof,
                                                           i_id_alert_diagnosis => d.id_concept_term,
                                                           i_id_diagnosis       => d.id_concept_version,
                                                           i_code_diagnosis     => d.code_diagnosis,
                                                           i_diagnosis_language => d.id_language,
                                                           i_code               => d.concept_code,
                                                           i_flg_other          => d.flg_other,
                                                           i_flg_std_diag       => d.flg_icd9,
                                                           i_flg_search_mode    => pk_alert_constant.g_yes,
                                                           i_format_bold        => pk_alert_constant.g_yes) desc_staging_basis,
                       d.rank,
                       nvl2(decode(i_staging_basis, id_concept_version, 1, NULL),
                            decode(i_flg_edit_mode,
                                   pk_diagnosis_core.g_diag_edit_mode_staging,
                                   pk_alert_constant.g_yes,
                                   pk_diagnosis_core.g_diag_edit_mode_edit,
                                   pk_alert_constant.g_yes,
                                   pk_diagnosis_core.g_diag_create_mode,
                                   pk_alert_constant.g_yes,
                                   pk_alert_constant.g_no),
                            pk_alert_constant.g_no) flg_default,
                       pk_alert_constant.g_yes flg_available
                  FROM diagnosis_ea d
                 WHERE d.concept_type_int_name = g_stage_base_type
                   AND d.id_institution = i_prof.institution
                   AND d.id_software = i_prof.software
                   AND (nvl(i_flg_edit_mode, pk_diagnosis_core.g_diag_create_mode) NOT IN
                       (pk_diagnosis_core.g_diag_edit_mode_staging, pk_diagnosis_core.g_diag_edit_mode_edit) OR
                       d.id_concept_version = nvl(i_staging_basis, d.id_concept_version))) t
         ORDER BY t.rank, t.desc_staging_basis;

    CURSOR c_tnm_t
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_topography          IN diagnosis.id_diagnosis%TYPE,
        i_any_topography      IN diagnosis.id_diagnosis%TYPE,
        i_morphology          IN diagnosis.id_diagnosis%TYPE,
        i_any_morphology      IN diagnosis.id_diagnosis%TYPE,
        i_treatment_group     IN diagnosis.id_diagnosis%TYPE,
        i_any_treatment_group IN diagnosis.id_diagnosis%TYPE,
        i_staging_basis       IN diagnosis.id_diagnosis%TYPE,
        i_code_stage_basis    IN diagnosis.code_icd%TYPE,
        i_any_staging_basis   IN diagnosis.id_diagnosis%TYPE,
        i_epis_tnm_t          IN epis_diag_stag.id_tnm_t%TYPE,
        i_code_tnm_t          IN epis_diag_stag.code_tnm_t%TYPE
    ) IS
        SELECT t.id_tnm_t,
               t.desc_tnm_t,
               t.flg_default,
               t.rank,
               xmlelement("ADDITIONAL_INFO",
                          xmlattributes(t.flg_default,
                                        t.code_staging,
                                        t.concept_code,
                                        (t.code_staging || t.concept_code) code)) addit_info
          FROM (SELECT id_concept_term id_tnm_t,
                       pk_diagnosis.std_tnm_desc(i_lang               => i_lang,
                                                 i_prof               => i_prof,
                                                 i_id_alert_diagnosis => id_concept_term,
                                                 i_id_diagnosis       => id_concept_version,
                                                 i_code_diagnosis     => code_diagnosis,
                                                 i_diagnosis_language => id_language,
                                                 i_code               => concept_code,
                                                 i_flg_other          => flg_other,
                                                 i_flg_std_diag       => flg_icd9,
                                                 i_flg_search_mode    => pk_alert_constant.g_yes,
                                                 i_format_bold        => pk_alert_constant.g_yes,
                                                 i_code_staging       => code_staging) desc_tnm_t,
                       code_staging,
                       concept_code,
                       rank,
                       flg_default
                  FROM (SELECT DISTINCT d.id_concept_term,
                                        d.id_concept_version,
                                        d.code_diagnosis,
                                        d.id_language,
                                        d.concept_code,
                                        d.flg_other,
                                        d.flg_icd9,
                                        d.rank,
                                        nvl2(i_epis_tnm_t, pk_alert_constant.g_no, dr.flg_default) flg_default,
                                        i_code_stage_basis code_staging
                          FROM diagnosis_relations_ea dr
                          JOIN diagnosis_ea d
                            ON d.id_concept_version = dr.id_concept_version_1
                         WHERE dr.cncpt_rel_type_int_name = g_rel_depends_on
                           AND dr.concept_type_int_name1 = g_tnm_t_type
                           AND dr.concept_type_int_name2 = g_topography_type
                           AND dr.id_concept_version_2 IN (i_topography, i_any_topography)
                           AND dr.id_institution = i_prof.institution
                           AND dr.id_software = i_prof.software
                           AND d.id_institution = i_prof.institution
                           AND d.id_software = i_prof.software
                           AND (d.id_concept_term <> nvl(i_epis_tnm_t, g_id_tnm_none) OR
                               i_code_stage_basis <> nvl(i_code_tnm_t, g_code_tnm_none))
                           AND EXISTS (SELECT 0
                                  FROM diagnosis_relations_ea dr2
                                 WHERE dr2.cncpt_rel_type_int_name = g_rel_depends_on
                                   AND dr2.concept_type_int_name1 = g_tnm_t_type
                                   AND dr2.concept_type_int_name2 = g_morphology_type
                                   AND dr2.id_concept_version_1 = d.id_concept_version
                                   AND dr2.id_concept_version_2 IN (i_morphology, i_any_morphology)
                                   AND dr2.id_institution = i_prof.institution
                                   AND dr2.id_software = i_prof.software)
                           AND EXISTS (SELECT 0
                                  FROM diagnosis_relations_ea dr2
                                 WHERE dr2.cncpt_rel_type_int_name = g_rel_depends_on
                                   AND dr2.concept_type_int_name1 = g_tnm_t_type
                                   AND dr2.concept_type_int_name2 = g_stage_base_type
                                   AND dr2.id_concept_version_1 = d.id_concept_version
                                   AND dr2.id_concept_version_2 IN (i_staging_basis, i_any_staging_basis)
                                   AND dr2.id_institution = i_prof.institution
                                   AND dr2.id_software = i_prof.software)
                           AND EXISTS (SELECT 0
                                  FROM diagnosis_relations_ea dr2
                                 WHERE dr2.cncpt_rel_type_int_name = g_rel_depends_on
                                   AND dr2.concept_type_int_name1 = g_tnm_t_type
                                   AND dr2.concept_type_int_name2 = g_treatment_group
                                   AND dr2.id_concept_version_1 = d.id_concept_version
                                   AND dr2.id_concept_version_2 IN (i_treatment_group, i_any_treatment_group)
                                   AND dr2.id_institution = i_prof.institution
                                   AND dr2.id_software = i_prof.software)
                        
                        UNION ALL
                        
                        SELECT DISTINCT ad.id_alert_diagnosis   id_concept_term,
                                        di.id_diagnosis         id_concept_version,
                                        ad.code_alert_diagnosis code_diagnosis,
                                        ad.id_language,
                                        di.code_icd             concept_code,
                                        di.flg_other            flg_other,
                                        ad.flg_icd9,
                                        -999                    rank,
                                        pk_alert_constant.g_yes flg_default,
                                        i_code_tnm_t            code_staging
                          FROM alert_diagnosis ad
                          JOIN diagnosis di
                            ON di.id_diagnosis = ad.id_diagnosis
                         WHERE ad.id_alert_diagnosis = i_epis_tnm_t)) t
         ORDER BY t.rank, t.desc_tnm_t;

    CURSOR c_tnm_n
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_topography          IN diagnosis.id_diagnosis%TYPE,
        i_any_topography      IN diagnosis.id_diagnosis%TYPE,
        i_morphology          IN diagnosis.id_diagnosis%TYPE,
        i_any_morphology      IN diagnosis.id_diagnosis%TYPE,
        i_treatment_group     IN diagnosis.id_diagnosis%TYPE,
        i_any_treatment_group IN diagnosis.id_diagnosis%TYPE,
        i_staging_basis       IN diagnosis.id_diagnosis%TYPE,
        i_code_stage_basis    IN diagnosis.code_icd%TYPE,
        i_any_staging_basis   IN diagnosis.id_diagnosis%TYPE,
        i_epis_tnm_n          IN epis_diag_stag.id_tnm_t%TYPE,
        i_code_tnm_n          IN epis_diag_stag.code_tnm_t%TYPE
    ) IS
        SELECT t.id_tnm_n,
               t.desc_tnm_n,
               t.flg_default,
               t.rank,
               xmlelement("ADDITIONAL_INFO",
                          xmlattributes(t.flg_default,
                                        t.code_staging,
                                        t.concept_code,
                                        (t.code_staging || t.concept_code) code)) addit_info
          FROM (SELECT id_concept_term id_tnm_n,
                       pk_diagnosis.std_tnm_desc(i_lang               => i_lang,
                                                 i_prof               => i_prof,
                                                 i_id_alert_diagnosis => id_concept_term,
                                                 i_id_diagnosis       => id_concept_version,
                                                 i_code_diagnosis     => code_diagnosis,
                                                 i_diagnosis_language => id_language,
                                                 i_code               => concept_code,
                                                 i_flg_other          => flg_other,
                                                 i_flg_std_diag       => flg_icd9,
                                                 i_flg_search_mode    => pk_alert_constant.g_yes,
                                                 i_format_bold        => pk_alert_constant.g_yes,
                                                 i_code_staging       => code_staging) desc_tnm_n,
                       code_staging,
                       concept_code,
                       rank,
                       flg_default
                  FROM (SELECT DISTINCT d.id_concept_term,
                                        d.id_concept_version,
                                        d.code_diagnosis,
                                        d.id_language,
                                        d.concept_code,
                                        d.flg_other,
                                        d.flg_icd9,
                                        d.rank,
                                        nvl2(i_epis_tnm_n, pk_alert_constant.g_no, dr.flg_default) flg_default,
                                        i_code_stage_basis code_staging
                          FROM diagnosis_relations_ea dr
                          JOIN diagnosis_ea d
                            ON d.id_concept_version = dr.id_concept_version_1
                         WHERE dr.cncpt_rel_type_int_name = g_rel_depends_on
                           AND dr.concept_type_int_name1 = g_tnm_n_type
                           AND dr.concept_type_int_name2 = g_topography_type
                           AND dr.id_concept_version_2 IN (i_topography, i_any_topography)
                           AND dr.id_institution = i_prof.institution
                           AND dr.id_software = i_prof.software
                           AND d.id_institution = i_prof.institution
                           AND d.id_software = i_prof.software
                           AND (d.id_concept_term <> nvl(i_epis_tnm_n, g_id_tnm_none) OR
                               i_code_stage_basis <> nvl(i_code_tnm_n, g_code_tnm_none))
                           AND EXISTS (SELECT 0
                                  FROM diagnosis_relations_ea dr2
                                 WHERE dr2.cncpt_rel_type_int_name = g_rel_depends_on
                                   AND dr2.concept_type_int_name1 = g_tnm_n_type
                                   AND dr2.concept_type_int_name2 = g_morphology_type
                                   AND dr2.id_concept_version_1 = d.id_concept_version
                                   AND dr2.id_concept_version_2 IN (i_morphology, i_any_morphology)
                                   AND dr2.id_institution = i_prof.institution
                                   AND dr2.id_software = i_prof.software)
                           AND EXISTS (SELECT 0
                                  FROM diagnosis_relations_ea dr2
                                 WHERE dr2.cncpt_rel_type_int_name = g_rel_depends_on
                                   AND dr2.concept_type_int_name1 = g_tnm_n_type
                                   AND dr2.concept_type_int_name2 = g_stage_base_type
                                   AND dr2.id_concept_version_1 = d.id_concept_version
                                   AND dr2.id_concept_version_2 IN (i_staging_basis, i_any_staging_basis)
                                   AND dr2.id_institution = i_prof.institution
                                   AND dr2.id_software = i_prof.software)
                           AND EXISTS (SELECT 0
                                  FROM diagnosis_relations_ea dr2
                                 WHERE dr2.cncpt_rel_type_int_name = g_rel_depends_on
                                   AND dr2.concept_type_int_name1 = g_tnm_n_type
                                   AND dr2.concept_type_int_name2 = g_treatment_group
                                   AND dr2.id_concept_version_1 = d.id_concept_version
                                   AND dr2.id_concept_version_2 IN (i_treatment_group, i_any_treatment_group)
                                   AND dr2.id_institution = i_prof.institution
                                   AND dr2.id_software = i_prof.software)
                        
                        UNION ALL
                        
                        SELECT DISTINCT ad.id_alert_diagnosis   id_concept_term,
                                        di.id_diagnosis         id_concept_version,
                                        ad.code_alert_diagnosis code_diagnosis,
                                        ad.id_language,
                                        di.code_icd             concept_code,
                                        di.flg_other            flg_other,
                                        ad.flg_icd9,
                                        -999                    rank,
                                        pk_alert_constant.g_yes flg_default,
                                        i_code_tnm_n            code_staging
                          FROM alert_diagnosis ad
                          JOIN diagnosis di
                            ON di.id_diagnosis = ad.id_diagnosis
                         WHERE ad.id_alert_diagnosis = i_epis_tnm_n)) t
         ORDER BY t.rank, t.desc_tnm_n;

    CURSOR c_tnm_m
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_topography          IN diagnosis.id_diagnosis%TYPE,
        i_any_topography      IN diagnosis.id_diagnosis%TYPE,
        i_morphology          IN diagnosis.id_diagnosis%TYPE,
        i_any_morphology      IN diagnosis.id_diagnosis%TYPE,
        i_treatment_group     IN diagnosis.id_diagnosis%TYPE,
        i_any_treatment_group IN diagnosis.id_diagnosis%TYPE,
        i_staging_basis       IN diagnosis.id_diagnosis%TYPE,
        i_code_stage_basis    IN diagnosis.code_icd%TYPE,
        i_any_staging_basis   IN diagnosis.id_diagnosis%TYPE,
        i_epis_tnm_m          IN epis_diag_stag.id_tnm_t%TYPE,
        i_code_tnm_m          IN epis_diag_stag.code_tnm_t%TYPE
    ) IS
        SELECT t.id_tnm_m,
               t.desc_tnm_m,
               t.flg_default,
               t.rank,
               xmlelement("ADDITIONAL_INFO",
                          xmlattributes(t.flg_default,
                                        t.code_staging,
                                        t.concept_code,
                                        (t.code_staging || t.concept_code) code)) addit_info
          FROM (SELECT id_concept_term id_tnm_m,
                       pk_diagnosis.std_tnm_desc(i_lang               => i_lang,
                                                 i_prof               => i_prof,
                                                 i_id_alert_diagnosis => id_concept_term,
                                                 i_id_diagnosis       => id_concept_version,
                                                 i_code_diagnosis     => code_diagnosis,
                                                 i_diagnosis_language => id_language,
                                                 i_code               => concept_code,
                                                 i_flg_other          => flg_other,
                                                 i_flg_std_diag       => flg_icd9,
                                                 i_flg_search_mode    => pk_alert_constant.g_yes,
                                                 i_format_bold        => pk_alert_constant.g_yes,
                                                 i_code_staging       => code_staging) desc_tnm_m,
                       code_staging,
                       concept_code,
                       rank,
                       flg_default
                  FROM (SELECT DISTINCT d.id_concept_term,
                                        d.id_concept_version,
                                        d.code_diagnosis,
                                        d.id_language,
                                        d.concept_code,
                                        d.flg_other,
                                        d.flg_icd9,
                                        d.rank,
                                        nvl2(i_epis_tnm_m, pk_alert_constant.g_no, dr.flg_default) flg_default,
                                        i_code_stage_basis code_staging
                          FROM diagnosis_relations_ea dr
                          JOIN diagnosis_ea d
                            ON d.id_concept_version = dr.id_concept_version_1
                         WHERE dr.cncpt_rel_type_int_name = g_rel_depends_on
                           AND dr.concept_type_int_name1 = g_tnm_m_type
                           AND dr.concept_type_int_name2 = g_topography_type
                           AND dr.id_concept_version_2 IN (i_topography, i_any_topography)
                           AND dr.id_institution = i_prof.institution
                           AND dr.id_software = i_prof.software
                           AND d.id_institution = i_prof.institution
                           AND d.id_software = i_prof.software
                           AND (d.id_concept_term <> nvl(i_epis_tnm_m, g_id_tnm_none) OR
                               i_code_stage_basis <> nvl(i_code_tnm_m, g_code_tnm_none))
                           AND EXISTS (SELECT 0
                                  FROM diagnosis_relations_ea dr2
                                 WHERE dr2.cncpt_rel_type_int_name = g_rel_depends_on
                                   AND dr2.concept_type_int_name1 = g_tnm_m_type
                                   AND dr2.concept_type_int_name2 = g_morphology_type
                                   AND dr2.id_concept_version_1 = d.id_concept_version
                                   AND dr2.id_concept_version_2 IN (i_morphology, i_any_morphology)
                                   AND dr2.id_institution = i_prof.institution
                                   AND dr2.id_software = i_prof.software)
                           AND EXISTS (SELECT 0
                                  FROM diagnosis_relations_ea dr2
                                 WHERE dr2.cncpt_rel_type_int_name = g_rel_depends_on
                                   AND dr2.concept_type_int_name1 = g_tnm_m_type
                                   AND dr2.concept_type_int_name2 = g_stage_base_type
                                   AND dr2.id_concept_version_1 = d.id_concept_version
                                   AND dr2.id_concept_version_2 IN (i_staging_basis, i_any_staging_basis)
                                   AND dr2.id_institution = i_prof.institution
                                   AND dr2.id_software = i_prof.software)
                           AND EXISTS (SELECT 0
                                  FROM diagnosis_relations_ea dr2
                                 WHERE dr2.cncpt_rel_type_int_name = g_rel_depends_on
                                   AND dr2.concept_type_int_name1 = g_tnm_m_type
                                   AND dr2.concept_type_int_name2 = g_treatment_group
                                   AND dr2.id_concept_version_1 = d.id_concept_version
                                   AND dr2.id_concept_version_2 IN (i_treatment_group, i_any_treatment_group)
                                   AND dr2.id_institution = i_prof.institution
                                   AND dr2.id_software = i_prof.software)
                        
                        UNION ALL
                        
                        SELECT DISTINCT ad.id_alert_diagnosis   id_concept_term,
                                        di.id_diagnosis         id_concept_version,
                                        ad.code_alert_diagnosis code_diagnosis,
                                        ad.id_language,
                                        di.code_icd             concept_code,
                                        di.flg_other            flg_other,
                                        ad.flg_icd9,
                                        -999                    rank,
                                        pk_alert_constant.g_yes flg_default,
                                        i_code_tnm_m            code_staging
                          FROM alert_diagnosis ad
                          JOIN diagnosis di
                            ON di.id_diagnosis = ad.id_diagnosis
                         WHERE ad.id_alert_diagnosis = i_epis_tnm_m)) t
         ORDER BY t.rank, t.desc_tnm_m;

    CURSOR c_metastatic_sites
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_tnm_m            IN diagnosis.id_diagnosis%TYPE,
        i_any_tnm_m        IN diagnosis.id_diagnosis%TYPE,
        i_metastatic_sites IN diagnosis_ea.id_concept_term%TYPE DEFAULT NULL
    ) IS
        SELECT t.id_metastatic_sites,
               t.desc_metastatic_sites,
               t.flg_default,
               t.rank,
               xmlelement("ADDITIONAL_INFO", xmlattributes(t.flg_default)) addit_info
          FROM (SELECT id_concept_term id_metastatic_sites,
                       htf.escape_sc(pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                i_prof               => i_prof,
                                                                i_id_alert_diagnosis => id_concept_term,
                                                                i_id_diagnosis       => id_concept_version,
                                                                i_code_diagnosis     => code_diagnosis,
                                                                i_diagnosis_language => id_language,
                                                                i_code               => concept_code,
                                                                i_flg_other          => flg_other,
                                                                i_flg_std_diag       => flg_icd9,
                                                                i_flg_search_mode    => pk_alert_constant.g_yes)) desc_metastatic_sites,
                       rank,
                       CASE
                            WHEN i_metastatic_sites IS NULL THEN
                             flg_default
                            ELSE
                             decode(i_metastatic_sites, id_concept_term, pk_alert_constant.g_yes, pk_alert_constant.g_no)
                        END flg_default
                  FROM (SELECT DISTINCT d.id_concept_term,
                                        d.id_concept_version,
                                        d.code_diagnosis,
                                        d.id_language,
                                        d.concept_code,
                                        d.flg_other,
                                        d.flg_icd9,
                                        d.rank,
                                        dr.flg_default
                          FROM diagnosis_relations_ea dr
                          JOIN diagnosis_ea d
                            ON d.id_concept_version = dr.id_concept_version_1
                         WHERE dr.cncpt_rel_type_int_name = g_rel_depends_on
                           AND dr.concept_type_int_name1 = g_metastic_type
                           AND dr.concept_type_int_name2 = g_tnm_m_type
                           AND dr.id_concept_version_2 IN (i_tnm_m, i_any_tnm_m)
                           AND dr.id_institution = i_prof.institution
                           AND dr.id_software = i_prof.software
                           AND d.id_institution = i_prof.institution
                           AND d.id_software = i_prof.software)) t
         ORDER BY t.rank, t.desc_metastatic_sites;

    CURSOR c_residual_tumor
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_residual_tumor IN diagnosis_ea.id_concept_term%TYPE DEFAULT NULL
    ) IS
        SELECT t.id_residual_tumor,
               t.desc_residual_tumor,
               t.flg_default,
               t.rank,
               xmlelement("ADDITIONAL_INFO", xmlattributes(t.code, t.flg_default)) addit_info
          FROM (SELECT id_concept_term id_residual_tumor,
                       htf.escape_sc(pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                i_prof               => i_prof,
                                                                i_id_alert_diagnosis => d.id_concept_term,
                                                                i_id_diagnosis       => d.id_concept_version,
                                                                i_code_diagnosis     => d.code_diagnosis,
                                                                i_diagnosis_language => d.id_language,
                                                                i_code               => d.concept_code,
                                                                i_flg_other          => d.flg_other,
                                                                i_flg_std_diag       => d.flg_icd9,
                                                                i_flg_search_mode    => pk_alert_constant.g_yes)) desc_residual_tumor,
                       d.rank,
                       CASE
                            WHEN i_residual_tumor IS NULL THEN
                             pk_alert_constant.g_no
                            ELSE
                             decode(i_residual_tumor, id_concept_term, pk_alert_constant.g_yes, pk_alert_constant.g_no)
                        END flg_default,
                       d.concept_code code
                  FROM diagnosis_ea d
                 WHERE d.concept_type_int_name = g_residual_type
                   AND d.id_institution = i_prof.institution
                   AND d.id_software = i_prof.software) t
         ORDER BY t.rank, t.desc_residual_tumor;

    CURSOR c_surgical_margins
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_surgical_margins IN diagnosis_ea.id_concept_term%TYPE DEFAULT NULL
    ) IS
        SELECT t.id_surgical_margin,
               t.desc_surgical_margin,
               t.flg_default,
               t.rank,
               xmlelement("ADDITIONAL_INFO", xmlattributes(t.flg_default)) addit_info
          FROM (SELECT id_concept_term id_surgical_margin,
                       htf.escape_sc(pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                i_prof               => i_prof,
                                                                i_id_alert_diagnosis => d.id_concept_term,
                                                                i_id_diagnosis       => d.id_concept_version,
                                                                i_code_diagnosis     => d.code_diagnosis,
                                                                i_diagnosis_language => d.id_language,
                                                                i_code               => NULL,
                                                                i_flg_other          => d.flg_other,
                                                                i_flg_std_diag       => d.flg_icd9,
                                                                i_flg_search_mode    => pk_alert_constant.g_yes)) desc_surgical_margin,
                       d.rank,
                       CASE
                            WHEN i_surgical_margins IS NULL THEN
                             pk_alert_constant.g_no
                            ELSE
                             decode(i_surgical_margins, id_concept_term, pk_alert_constant.g_yes, pk_alert_constant.g_no)
                        END flg_default
                  FROM diagnosis_ea d
                 WHERE d.concept_type_int_name = g_surgical_type
                   AND d.id_institution = i_prof.institution
                   AND d.id_software = i_prof.software) t
         ORDER BY t.rank, t.desc_surgical_margin;

    CURSOR c_lymph_vascular_invasion
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_topography              IN diagnosis.id_diagnosis%TYPE,
        i_any_topography          IN diagnosis.id_diagnosis%TYPE,
        i_lymph_vascular_invasion IN diagnosis_ea.id_concept_term%TYPE DEFAULT NULL
    ) IS
        SELECT t.id_lymph_vascular_invasion,
               t.desc_lymph_vascular_invasion,
               t.flg_default,
               t.rank,
               xmlelement("ADDITIONAL_INFO", xmlattributes(t.flg_default)) addit_info
          FROM (SELECT id_concept_term id_lymph_vascular_invasion,
                       htf.escape_sc(pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                i_prof               => i_prof,
                                                                i_id_alert_diagnosis => id_concept_term,
                                                                i_id_diagnosis       => id_concept_version,
                                                                i_code_diagnosis     => code_diagnosis,
                                                                i_diagnosis_language => id_language,
                                                                i_code               => NULL,
                                                                i_flg_other          => flg_other,
                                                                i_flg_std_diag       => flg_icd9,
                                                                i_flg_search_mode    => pk_alert_constant.g_yes)) desc_lymph_vascular_invasion,
                       rank,
                       CASE
                            WHEN i_lymph_vascular_invasion IS NULL THEN
                             flg_default
                            ELSE
                             decode(i_lymph_vascular_invasion,
                                    id_concept_term,
                                    pk_alert_constant.g_yes,
                                    pk_alert_constant.g_no)
                        END flg_default
                  FROM (SELECT DISTINCT d.id_concept_term,
                                        d.id_concept_version,
                                        d.code_diagnosis,
                                        d.id_language,
                                        d.concept_code,
                                        d.flg_other,
                                        d.flg_icd9,
                                        d.rank,
                                        dr.flg_default
                          FROM diagnosis_relations_ea dr
                          JOIN diagnosis_ea d
                            ON d.id_concept_version = dr.id_concept_version_1
                         WHERE dr.cncpt_rel_type_int_name = g_rel_depends_on
                           AND dr.concept_type_int_name1 = g_lymph_vasc_type
                           AND dr.concept_type_int_name2 = g_topography_type
                           AND dr.id_concept_version_2 IN (i_topography, i_any_topography)
                           AND dr.id_institution = i_prof.institution
                           AND dr.id_software = i_prof.software
                           AND d.id_institution = i_prof.institution
                           AND d.id_software = i_prof.software)) t
         ORDER BY t.rank, t.desc_lymph_vascular_invasion;

    CURSOR c_other_staging_sys
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_topography        IN diagnosis.id_diagnosis%TYPE,
        i_any_topography    IN diagnosis.id_diagnosis%TYPE,
        i_other_staging_sys IN diagnosis_ea.id_concept_term%TYPE DEFAULT NULL
    ) IS
        SELECT t.id_other_staging_sys,
               t.desc_other_staging_sys,
               t.flg_default,
               t.rank,
               xmlelement("ADDITIONAL_INFO", xmlattributes(t.flg_default)) addit_info
          FROM (SELECT id_concept_term id_other_staging_sys,
                       htf.escape_sc(pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                i_prof               => i_prof,
                                                                i_id_alert_diagnosis => id_concept_term,
                                                                i_id_diagnosis       => id_concept_version,
                                                                i_code_diagnosis     => code_diagnosis,
                                                                i_diagnosis_language => id_language,
                                                                i_code               => concept_code,
                                                                i_flg_other          => flg_other,
                                                                i_flg_std_diag       => flg_icd9,
                                                                i_flg_search_mode    => pk_alert_constant.g_yes)) desc_other_staging_sys,
                       rank,
                       CASE
                            WHEN i_other_staging_sys IS NULL THEN
                             flg_default
                            ELSE
                             decode(i_other_staging_sys, id_concept_term, pk_alert_constant.g_yes, pk_alert_constant.g_no)
                        END flg_default
                  FROM (SELECT DISTINCT d.id_concept_term,
                                        d.id_concept_version,
                                        d.code_diagnosis,
                                        d.id_language,
                                        d.concept_code,
                                        d.flg_other,
                                        d.flg_icd9,
                                        d.rank,
                                        dr.flg_default
                          FROM diagnosis_relations_ea dr
                          JOIN diagnosis_ea d
                            ON d.id_concept_version = dr.id_concept_version_1
                         WHERE dr.cncpt_rel_type_int_name = g_rel_depends_on
                           AND dr.concept_type_int_name1 = g_other_staging_sys
                           AND dr.concept_type_int_name2 = g_topography_type
                           AND dr.id_concept_version_2 IN (i_topography, i_any_topography)
                           AND dr.id_institution = i_prof.institution
                           AND dr.id_software = i_prof.software
                           AND d.id_institution = i_prof.institution
                           AND d.id_software = i_prof.software)) t
         ORDER BY t.rank, t.desc_other_staging_sys;

    CURSOR c_pfactors_staging_fields
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_topography          IN diagnosis.id_diagnosis%TYPE,
        i_any_topography      IN diagnosis.id_diagnosis%TYPE,
        i_morphology          IN diagnosis.id_diagnosis%TYPE,
        i_any_morphology      IN diagnosis.id_diagnosis%TYPE,
        i_treatment_group     IN diagnosis.id_diagnosis%TYPE,
        i_any_treatment_group IN diagnosis.id_diagnosis%TYPE
    ) IS
        SELECT t.id_field,
               t.field_label,
               t.rank,
               to_char(t.id_field) internal_name,
               xmlelement("ADDITIONAL_INFO", xmlattributes(t.id_field, t.rank)) addit_info
          FROM (SELECT id_concept_term id_field,
                       htf.escape_sc(pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                i_prof               => i_prof,
                                                                i_id_alert_diagnosis => id_concept_term,
                                                                i_id_diagnosis       => id_concept_version,
                                                                i_code_diagnosis     => code_diagnosis,
                                                                i_diagnosis_language => id_language,
                                                                i_code               => NULL,
                                                                i_flg_other          => flg_other,
                                                                i_flg_std_diag       => flg_icd9,
                                                                i_flg_search_mode    => pk_alert_constant.g_yes)) field_label,
                       rank,
                       i_topography id_topography
                  FROM (SELECT DISTINCT d.id_concept_term,
                                        d.id_concept_version,
                                        d.code_diagnosis,
                                        d.id_language,
                                        d.concept_code,
                                        d.flg_other,
                                        d.flg_icd9,
                                        d.rank,
                                        dr.flg_default
                          FROM diagnosis_relations_ea dr
                          JOIN diagnosis_ea d
                            ON d.id_concept_version = dr.id_concept_version_1
                         WHERE dr.cncpt_rel_type_int_name = g_rel_depends_on
                           AND dr.concept_type_int_name1 = g_pfactors_staging
                           AND dr.concept_type_int_name2 = g_topography_type
                           AND dr.id_concept_version_2 IN (i_topography, i_any_topography)
                           AND dr.id_institution = i_prof.institution
                           AND dr.id_software = i_prof.software
                           AND d.id_institution = i_prof.institution
                           AND d.id_software = i_prof.software
                           AND EXISTS (SELECT 0
                                  FROM diagnosis_relations_ea dr2
                                 WHERE dr2.cncpt_rel_type_int_name = g_rel_depends_on
                                   AND dr2.concept_type_int_name1 = g_pfactors_staging
                                   AND dr2.concept_type_int_name2 = g_morphology_type
                                   AND dr2.id_concept_version_1 = d.id_concept_version
                                   AND dr2.id_concept_version_2 IN (i_morphology, i_any_morphology)
                                   AND dr2.id_institution = i_prof.institution
                                   AND dr2.id_software = i_prof.software)
                           AND EXISTS (SELECT 0
                                  FROM diagnosis_relations_ea dr2
                                 WHERE dr2.cncpt_rel_type_int_name = g_rel_depends_on
                                   AND dr2.concept_type_int_name1 = g_pfactors_staging
                                   AND dr2.concept_type_int_name2 = g_treatment_group
                                   AND dr2.id_concept_version_1 = d.id_concept_version
                                   AND dr2.id_concept_version_2 IN (i_treatment_group, i_any_treatment_group)
                                   AND dr2.id_institution = i_prof.institution
                                   AND dr2.id_software = i_prof.software))) t
         ORDER BY t.rank, t.field_label;

    CURSOR c_pfactors_staging_values
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_pfactor_staging_field IN diagnosis.id_diagnosis%TYPE,
        i_pfactor_staging_value IN diagnosis_ea.id_concept_term%TYPE DEFAULT NULL
    ) IS
        SELECT t.id_value,
               t.desc_value,
               t.flg_default,
               t.rank,
               xmlelement("ADDITIONAL_INFO", xmlattributes(t.flg_default)) addit_info
          FROM (SELECT d.id_concept_term id_value,
                       htf.escape_sc(pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                i_prof               => i_prof,
                                                                i_id_alert_diagnosis => d.id_concept_term,
                                                                i_id_diagnosis       => d.id_concept_version,
                                                                i_code_diagnosis     => d.code_diagnosis,
                                                                i_diagnosis_language => d.id_language,
                                                                i_code               => NULL,
                                                                i_flg_other          => d.flg_other,
                                                                i_flg_std_diag       => d.flg_icd9,
                                                                i_flg_search_mode    => pk_alert_constant.g_yes)) desc_value,
                       d.rank,
                       CASE
                            WHEN i_pfactor_staging_value IS NULL THEN
                             dr.flg_default
                            ELSE
                             decode(i_pfactor_staging_value,
                                    id_concept_term,
                                    pk_alert_constant.g_yes,
                                    pk_alert_constant.g_no)
                        END flg_default,
                       dr.id_concept_version_2 id_pfactor_staging_field
                  FROM diagnosis_relations_ea dr
                  JOIN diagnosis_ea d
                    ON d.id_concept_version = dr.id_concept_version_1
                 WHERE dr.cncpt_rel_type_int_name = g_rel_is_a
                   AND dr.concept_type_int_name1 = g_pfactors_staging
                   AND dr.concept_type_int_name2 = g_pfactors_staging
                   AND dr.id_concept_version_2 = i_pfactor_staging_field
                   AND dr.id_institution = i_prof.institution
                   AND dr.id_software = i_prof.software
                   AND d.id_institution = i_prof.institution
                   AND d.id_software = i_prof.software) t
         ORDER BY t.rank, t.desc_value;

    CURSOR c_pfactors_clin_signif_fields
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_topography     IN diagnosis.id_diagnosis%TYPE,
        i_any_topography IN diagnosis.id_diagnosis%TYPE
    ) IS
        SELECT t.id_field,
               t.field_label,
               t.rank,
               to_char(t.id_field) internal_name,
               xmlelement("ADDITIONAL_INFO", xmlattributes(t.id_field, t.rank)) addit_info
          FROM (SELECT id_concept_term id_field,
                       htf.escape_sc(pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                i_prof               => i_prof,
                                                                i_id_alert_diagnosis => id_concept_term,
                                                                i_id_diagnosis       => id_concept_version,
                                                                i_code_diagnosis     => code_diagnosis,
                                                                i_diagnosis_language => id_language,
                                                                i_code               => NULL,
                                                                i_flg_other          => flg_other,
                                                                i_flg_std_diag       => flg_icd9,
                                                                i_flg_search_mode    => pk_alert_constant.g_yes)) field_label,
                       rank,
                       i_topography id_topography
                  FROM (SELECT DISTINCT d.id_concept_term,
                                        d.id_concept_version,
                                        d.code_diagnosis,
                                        d.id_language,
                                        d.concept_code,
                                        d.flg_other,
                                        d.flg_icd9,
                                        d.rank,
                                        dr.flg_default
                          FROM diagnosis_relations_ea dr
                          JOIN diagnosis_ea d
                            ON d.id_concept_version = dr.id_concept_version_1
                         WHERE dr.cncpt_rel_type_int_name = g_rel_depends_on
                           AND dr.concept_type_int_name1 = g_pfactors_clin_signif
                           AND dr.concept_type_int_name2 = g_topography_type
                           AND dr.id_concept_version_2 IN (i_topography, i_any_topography)
                           AND dr.id_institution = i_prof.institution
                           AND dr.id_software = i_prof.software
                           AND d.id_institution = i_prof.institution
                           AND d.id_software = i_prof.software)) t
         ORDER BY t.rank, t.field_label;

    CURSOR c_cancer_diag_already_reg
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_diagnosis       IN diagnosis.id_diagnosis%TYPE,
        i_alert_diagnosis IN alert_diagnosis.id_alert_diagnosis%TYPE
    ) IS
        SELECT t.id_epis_diagnosis
          FROM (SELECT ed.id_epis_diagnosis,
                       row_number() over(ORDER BY pk_diagnosis_core.get_dt_diagnosis(i_lang => i_lang, --
                       i_prof => i_prof, --
                       i_flg_status => ed.flg_status, --
                       i_dt_epis_diagnosis => ed.dt_epis_diagnosis_tstz, --
                       i_dt_confirmed => ed.dt_confirmed_tstz, --
                       i_dt_cancel => ed.dt_cancel_tstz, --
                       i_dt_base => ed.dt_base_tstz, --
                       i_dt_rulled_out => ed.dt_rulled_out_tstz)) line_number
                  FROM epis_diagnosis ed
                 WHERE ed.id_patient = i_patient
                   AND ed.id_episode != i_episode
                   AND ed.id_diagnosis = i_diagnosis
                   AND ed.flg_status != pk_diagnosis.g_ed_flg_status_ca) t
         WHERE t.line_number = 1;

    --Accident and Emergency fields
    CURSOR c_sub_analysis
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_diagnosis       IN diagnosis.id_diagnosis%TYPE,
        i_alert_diagnosis IN diagnosis_ea.id_concept_term%TYPE,
        i_diag_type       IN diagnosis.concept_type_int_name%TYPE,
        i_sub_analysis    IN diagnosis_ea.id_concept_term%TYPE DEFAULT NULL,
        i_show_code       IN VARCHAR2 DEFAULT pk_alert_constant.g_yes
    ) IS
        SELECT t.id_sub_analysis,
               t.desc_sub_analysis,
               t.flg_default,
               t.rank,
               xmlelement("ADDITIONAL_INFO", xmlattributes(t.flg_default)) addit_info
          FROM (SELECT id_concept_term id_sub_analysis,
                       htf.escape_sc(pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                i_prof               => i_prof,
                                                                i_id_alert_diagnosis => id_concept_term,
                                                                i_id_diagnosis       => id_concept_version,
                                                                i_code_diagnosis     => code_diagnosis,
                                                                i_diagnosis_language => id_language,
                                                                i_code               => CASE i_show_code
                                                                                            WHEN pk_alert_constant.g_yes THEN
                                                                                             concept_code
                                                                                            ELSE
                                                                                             NULL
                                                                                        END,
                                                                i_flg_other          => flg_other,
                                                                i_flg_std_diag       => flg_icd9,
                                                                i_flg_search_mode    => pk_alert_constant.g_yes)) desc_sub_analysis,
                       rank,
                       CASE
                            WHEN i_sub_analysis IS NULL THEN
                             flg_default
                            ELSE
                             decode(i_sub_analysis, id_concept_term, pk_alert_constant.g_yes, pk_alert_constant.g_no)
                        END flg_default
                  FROM (SELECT d.id_concept_term,
                               d.id_concept_version,
                               d.code_diagnosis,
                               d.id_language,
                               d.concept_code,
                               d.flg_other,
                               d.flg_icd9,
                               d.rank,
                               pk_alert_constant.g_yes flg_default
                          FROM diagnosis_ea d
                         WHERE d.id_concept_version = i_diagnosis
                           AND d.id_concept_term = i_alert_diagnosis
                           AND i_diag_type = g_sub_analysis_type
                           AND d.id_institution = i_prof.institution
                           AND d.id_software = i_prof.software
                        UNION ALL
                        SELECT DISTINCT d.id_concept_term,
                                        d.id_concept_version,
                                        d.code_diagnosis,
                                        d.id_language,
                                        d.concept_code,
                                        d.flg_other,
                                        d.flg_icd9,
                                        d.rank,
                                        dr.flg_default
                          FROM diagnosis_relations_ea dr
                          JOIN diagnosis_ea d
                            ON d.id_concept_version = dr.id_concept_version_2
                         WHERE dr.cncpt_rel_type_int_name = g_rel_is_a
                           AND dr.concept_type_int_name1 = i_diag_type
                           AND dr.id_concept_version_1 = i_diagnosis
                           AND dr.concept_type_int_name2 = g_sub_analysis_type
                           AND dr.id_institution = i_prof.institution
                           AND dr.id_software = i_prof.software
                           AND d.id_institution = i_prof.institution
                           AND d.id_software = i_prof.software
                           AND i_diag_type = g_ae_diagnosis_type
                        UNION ALL
                        SELECT DISTINCT d.id_concept_term,
                                        d.id_concept_version,
                                        d.code_diagnosis,
                                        d.id_language,
                                        d.concept_code,
                                        d.flg_other,
                                        d.flg_icd9,
                                        d.rank,
                                        dr.flg_default
                          FROM diagnosis_relations_ea dr
                          JOIN diagnosis_ea d
                            ON d.id_concept_version = dr.id_concept_version_1
                         WHERE dr.cncpt_rel_type_int_name = g_rel_is_a
                           AND dr.concept_type_int_name2 = i_diag_type
                           AND dr.id_concept_version_2 = i_diagnosis
                           AND dr.concept_type_int_name1 = g_sub_analysis_type
                           AND dr.id_institution = i_prof.institution
                           AND dr.id_software = i_prof.software
                           AND d.id_institution = i_prof.institution
                           AND d.id_software = i_prof.software
                           AND i_diag_type = g_diag_condition_type)) t
         ORDER BY t.rank, t.desc_sub_analysis;

    CURSOR c_anatomical_area
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_diagnosis       IN diagnosis.id_diagnosis%TYPE,
        i_diag_type       IN diagnosis.concept_type_int_name%TYPE,
        i_sub_analysis    IN diagnosis.id_diagnosis%TYPE,
        i_anatomical_area IN diagnosis_ea.id_concept_term%TYPE DEFAULT NULL,
        i_show_code       IN VARCHAR2 DEFAULT pk_alert_constant.g_yes
    ) IS
        SELECT t.id_anatomical_area,
               t.desc_anatomical_area,
               t.flg_default,
               t.rank,
               xmlelement("ADDITIONAL_INFO", xmlattributes(t.flg_default)) addit_info
          FROM (SELECT id_concept_term id_anatomical_area,
                       htf.escape_sc(pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                i_prof               => i_prof,
                                                                i_id_alert_diagnosis => id_concept_term,
                                                                i_id_diagnosis       => id_concept_version,
                                                                i_code_diagnosis     => code_diagnosis,
                                                                i_diagnosis_language => id_language,
                                                                i_code               => CASE i_show_code
                                                                                            WHEN pk_alert_constant.g_yes THEN
                                                                                             concept_code
                                                                                            ELSE
                                                                                             NULL
                                                                                        END,
                                                                i_flg_other          => flg_other,
                                                                i_flg_std_diag       => flg_icd9,
                                                                i_flg_search_mode    => pk_alert_constant.g_yes)) desc_anatomical_area,
                       rank,
                       CASE
                            WHEN i_anatomical_area IS NULL THEN
                             flg_default
                            ELSE
                             decode(i_anatomical_area, id_concept_term, pk_alert_constant.g_yes, pk_alert_constant.g_no)
                        END flg_default
                  FROM (SELECT DISTINCT d.id_concept_term,
                                        d.id_concept_version,
                                        d.code_diagnosis,
                                        d.id_language,
                                        d.concept_code,
                                        d.flg_other,
                                        d.flg_icd9,
                                        d.rank,
                                        dr.flg_default
                          FROM diagnosis_relations_ea dr
                          JOIN diagnosis_ea d
                            ON d.id_concept_version = dr.id_concept_version_2
                         WHERE dr.concept_type_int_name1 = i_diag_type
                           AND dr.id_concept_version_1 = i_diagnosis
                           AND dr.cncpt_rel_type_int_name = g_rel_finding_site
                           AND dr.concept_type_int_name2 = g_anatomical_area_type
                           AND dr.id_institution = i_prof.institution
                           AND dr.id_software = i_prof.software
                           AND d.id_institution = i_prof.institution
                           AND d.id_software = i_prof.software)) t
         ORDER BY t.rank, t.desc_anatomical_area;

    CURSOR c_anatomical_side
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_diagnosis       IN diagnosis.id_diagnosis%TYPE,
        i_diag_type       IN diagnosis.concept_type_int_name%TYPE,
        i_anatomical_area IN diagnosis.id_diagnosis%TYPE,
        i_anatomical_side IN diagnosis_ea.id_concept_term%TYPE DEFAULT NULL,
        i_show_code       IN VARCHAR2 DEFAULT pk_alert_constant.g_yes
    ) IS
        SELECT t.id_anatomical_side,
               t.desc_anatomical_side,
               t.flg_default,
               t.rank,
               xmlelement("ADDITIONAL_INFO", xmlattributes(t.flg_default)) addit_info
          FROM (SELECT id_concept_term id_anatomical_side,
                       htf.escape_sc(pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                i_prof               => i_prof,
                                                                i_id_alert_diagnosis => id_concept_term,
                                                                i_id_diagnosis       => id_concept_version,
                                                                i_code_diagnosis     => code_diagnosis,
                                                                i_diagnosis_language => id_language,
                                                                i_code               => CASE i_show_code
                                                                                            WHEN pk_alert_constant.g_yes THEN
                                                                                             concept_code
                                                                                            ELSE
                                                                                             NULL
                                                                                        END,
                                                                i_flg_other          => flg_other,
                                                                i_flg_std_diag       => flg_icd9,
                                                                i_flg_search_mode    => pk_alert_constant.g_yes)) desc_anatomical_side,
                       rank,
                       CASE
                            WHEN i_anatomical_side IS NULL THEN
                             flg_default
                            ELSE
                             decode(i_anatomical_side, id_concept_term, pk_alert_constant.g_yes, pk_alert_constant.g_no)
                        END flg_default
                  FROM (SELECT DISTINCT d.id_concept_term,
                                        d.id_concept_version,
                                        d.code_diagnosis,
                                        d.id_language,
                                        d.concept_code,
                                        d.flg_other,
                                        d.flg_icd9,
                                        d.rank,
                                        dr.flg_default
                          FROM diagnosis_relations_ea dr
                          JOIN diagnosis_ea d
                            ON d.id_concept_version = dr.id_concept_version_2
                         WHERE dr.cncpt_rel_type_int_name = g_rel_laterality
                           AND dr.concept_type_int_name1 = i_diag_type
                           AND dr.concept_type_int_name2 = g_anatomical_side_type
                           AND dr.id_concept_version_1 = i_diagnosis
                           AND dr.id_institution = i_prof.institution
                           AND dr.id_software = i_prof.software
                           AND d.id_institution = i_prof.institution
                           AND d.id_software = i_prof.software
                        UNION ALL
                        SELECT DISTINCT d.id_concept_term,
                                        d.id_concept_version,
                                        d.code_diagnosis,
                                        d.id_language,
                                        d.concept_code,
                                        d.flg_other,
                                        d.flg_icd9,
                                        d.rank,
                                        dr.flg_default
                          FROM diagnosis_relations_ea dr
                          JOIN diagnosis_ea d
                            ON d.id_concept_version = dr.id_concept_version_2
                         WHERE dr.cncpt_rel_type_int_name = g_rel_laterality
                           AND dr.concept_type_int_name1 = g_anatomical_area_type
                           AND dr.concept_type_int_name2 = g_anatomical_side_type
                           AND dr.id_concept_version_1 = i_anatomical_area
                           AND dr.id_institution = i_prof.institution
                           AND dr.id_software = i_prof.software
                           AND d.id_institution = i_prof.institution
                           AND d.id_software = i_prof.software
                           AND NOT EXISTS (SELECT 1
                                  FROM diagnosis_relations_ea dr
                                  JOIN diagnosis_ea d
                                    ON d.id_concept_version = dr.id_concept_version_2
                                 WHERE dr.cncpt_rel_type_int_name = g_rel_laterality
                                   AND dr.concept_type_int_name1 = i_diag_type
                                   AND dr.concept_type_int_name2 = g_anatomical_side_type
                                   AND dr.id_concept_version_1 = i_diagnosis
                                   AND dr.id_institution = i_prof.institution
                                   AND dr.id_software = i_prof.software
                                   AND d.id_institution = i_prof.institution
                                   AND d.id_software = i_prof.software))) t
         ORDER BY t.rank, t.desc_anatomical_side;

    --ALERT-261232 - ALERT REFERRAL - changes required for MX market
    CURSOR c_causes
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_diagnosis IN diagnosis.id_diagnosis%TYPE
    ) IS
        SELECT t.id_cause, t.desc_cause, t.code_cause, t.flg_default, t.rank
          FROM (SELECT id_concept_term id_cause,
                       pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                  i_prof               => i_prof,
                                                  i_id_alert_diagnosis => id_concept_term,
                                                  i_id_diagnosis       => id_concept_version,
                                                  i_code_diagnosis     => code_diagnosis,
                                                  i_diagnosis_language => id_language,
                                                  i_code               => concept_code,
                                                  i_flg_other          => flg_other,
                                                  i_flg_std_diag       => flg_icd9,
                                                  i_flg_search_mode    => pk_alert_constant.g_yes) desc_cause,
                       concept_code code_cause,
                       rank,
                       flg_default
                  FROM (SELECT DISTINCT d.id_concept_term,
                                        d.id_concept_version,
                                        d.code_diagnosis,
                                        d.id_language,
                                        d.concept_code,
                                        d.flg_other,
                                        d.flg_icd9,
                                        d.rank,
                                        dr.flg_default
                          FROM diagnosis_relations_ea dr
                          JOIN diagnosis_ea d
                            ON d.id_concept_version = dr.id_concept_version_1
                         WHERE dr.cncpt_rel_type_int_name = g_rel_depends_on
                           AND dr.concept_type_int_name1 = g_causes_type
                           AND dr.concept_type_int_name2 = g_diagn_type
                           AND dr.id_concept_version_2 = i_diagnosis
                           AND dr.id_institution = i_prof.institution
                           AND dr.id_software = i_prof.software
                           AND d.id_institution = i_prof.institution
                           AND d.id_software = i_prof.software)) t
         ORDER BY t.rank, t.desc_cause;

    CURSOR c_lesion_type
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_diagnosis      IN diagnosis.id_diagnosis%TYPE,
        i_diag_type      IN diagnosis.concept_type_int_name%TYPE,
        i_id_lesion_type diagnosis_ea.id_concept_term%TYPE DEFAULT NULL,
        i_show_code      IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) IS
        SELECT t.id_lesion_type,
               t.desc_lesion_type,
               t.flg_default,
               t.rank,
               xmlelement("ADDITIONAL_INFO", xmlattributes(t.flg_default)) addit_info
          FROM (SELECT id_concept_term id_lesion_type,
                       htf.escape_sc(pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                i_prof               => i_prof,
                                                                i_id_alert_diagnosis => id_concept_term,
                                                                i_id_diagnosis       => id_concept_version,
                                                                i_code_diagnosis     => code_diagnosis,
                                                                i_diagnosis_language => id_language,
                                                                i_code               => NULL,
                                                                i_flg_other          => flg_other,
                                                                i_flg_std_diag       => flg_icd9,
                                                                i_flg_search_mode    => pk_alert_constant.g_yes)) desc_lesion_type,
                       rank,
                       CASE
                            WHEN i_id_lesion_type IS NULL THEN
                             flg_default
                            ELSE
                             decode(i_id_lesion_type, id_concept_term, pk_alert_constant.g_yes, pk_alert_constant.g_no)
                        END flg_default
                  FROM (SELECT DISTINCT d.id_concept_term,
                                        d.id_concept_version,
                                        d.code_diagnosis,
                                        d.id_language,
                                        d.concept_code,
                                        d.flg_other,
                                        d.flg_icd9,
                                        dr.rank,
                                        dr.flg_default
                          FROM diagnosis_relations_ea dr
                          JOIN diagnosis_ea d
                            ON d.id_concept_version = dr.id_concept_version_1
                         WHERE dr.concept_type_int_name1 = g_lesion_type
                           AND dr.id_concept_version_2 = i_diagnosis
                           AND dr.cncpt_rel_type_int_name = g_rel_depends_on
                           AND dr.concept_type_int_name2 = i_diag_type
                           AND dr.id_institution = i_prof.institution
                           AND dr.id_software = i_prof.software
                           AND d.id_institution = i_prof.institution
                           AND d.id_software = i_prof.software)) t
         ORDER BY t.rank, t.desc_lesion_type;

    CURSOR c_lesion_location
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_diagnosis          IN diagnosis.id_diagnosis%TYPE,
        i_diag_type          IN diagnosis.concept_type_int_name%TYPE,
        i_id_lesion_location diagnosis_ea.id_concept_term%TYPE DEFAULT NULL,
        i_show_code          IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) IS
        SELECT t.id_lesion_location,
               t.desc_lesion_location,
               t.flg_default,
               t.rank,
               xmlelement("ADDITIONAL_INFO", xmlattributes(t.flg_default)) addit_info
          FROM (SELECT id_concept_term id_lesion_location,
                       htf.escape_sc(pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                i_prof               => i_prof,
                                                                i_id_alert_diagnosis => id_concept_term,
                                                                i_id_diagnosis       => id_concept_version,
                                                                i_code_diagnosis     => code_diagnosis,
                                                                i_diagnosis_language => id_language,
                                                                i_code               => NULL,
                                                                i_flg_other          => flg_other,
                                                                i_flg_std_diag       => flg_icd9,
                                                                i_flg_search_mode    => pk_alert_constant.g_yes)) desc_lesion_location,
                       rank,
                       CASE
                            WHEN i_id_lesion_location IS NULL THEN
                             flg_default
                            ELSE
                             decode(i_id_lesion_location, id_concept_term, pk_alert_constant.g_yes, pk_alert_constant.g_no)
                        END flg_default
                  FROM (SELECT DISTINCT d.id_concept_term,
                                        d.id_concept_version,
                                        d.code_diagnosis,
                                        d.id_language,
                                        d.concept_code,
                                        d.flg_other,
                                        d.flg_icd9,
                                        dr.rank,
                                        dr.flg_default
                          FROM diagnosis_relations_ea dr
                          JOIN diagnosis_ea d
                            ON d.id_concept_version = dr.id_concept_version_1
                         WHERE dr.concept_type_int_name1 = g_lesion_location_type
                           AND dr.id_concept_version_2 = i_diagnosis
                           AND dr.cncpt_rel_type_int_name = g_rel_depends_on
                           AND dr.concept_type_int_name2 = i_diag_type
                           AND dr.id_institution = i_prof.institution
                           AND dr.id_software = i_prof.software
                           AND d.id_institution = i_prof.institution
                           AND d.id_software = i_prof.software)) t
         ORDER BY t.rank, t.desc_lesion_location;

    -- Public function and procedure declarations
    /**
    * Get dynamic screen sections and events list
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_diagnosis                 Diagnosis id
    * @param   o_diag_ds_int_name          Dynamic screen internal name
    * @param   o_min_tumor_num             Minimum tumor number
    * @param   o_section                   Section cursor
    * @param   o_def_events                Def events cursor
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6
    * @since   17-01-2012
    */
    FUNCTION get_section_events_list
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_diagnosis        IN concept_version.id_concept_version%TYPE,
        o_diag_ds_int_name OUT ds_component.internal_name%TYPE,
        o_min_tumor_num    OUT epis_diag_tumors.tumor_num%TYPE,
        o_section          OUT pk_types.cursor_type,
        o_def_events       OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get dynamic screen sections and events list
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_diag                 episode diagnosis ID
    * @param   i_epis_diag_hist            episode diagnosis ID (history record)
    * @param   o_diag_ds_int_name          Dynamic screen internal name
    * @param   o_min_tumor_num             Minimum tumor number
    * @param   o_section                   Section cursor
    * @param   o_def_events                Def events cursor
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6
    * @since   17-01-2012
    */
    FUNCTION get_section_events_list
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_epis_diagnosis      IN epis_diagnosis.id_epis_diagnosis%TYPE,
        i_epis_diagnosis_hist IN epis_diagnosis_hist.id_epis_diagnosis_hist%TYPE,
        o_diag_ds_int_name    OUT ds_component.internal_name%TYPE,
        o_min_tumor_num       OUT epis_diag_tumors.tumor_num%TYPE,
        o_section             OUT pk_types.cursor_type,
        o_def_events          OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_treament_group
    (
        i_prof            IN profissional,
        i_topography      IN diagnosis.id_diagnosis%TYPE,
        i_topography_term IN alert_diagnosis.id_alert_diagnosis%TYPE,
        i_any_topography  IN diagnosis.id_diagnosis%TYPE,
        i_morphology      IN diagnosis.id_diagnosis%TYPE,
        i_any_morphology  IN diagnosis.id_diagnosis%TYPE
    ) RETURN diagnosis_ea.id_concept_version%TYPE;

    -- Parse xml, validate input params and fill missing data of section data xml parameter
    FUNCTION parse_val_fill_sect_param
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_params IN CLOB,
        o_params OUT pk_edis_types.rec_diag_section_data_param,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_section_data_db
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_params       IN pk_edis_types.rec_diag_section_data_param,
        o_section      OUT t_table_ds_sections,
        o_def_events   OUT t_table_ds_def_events,
        o_events       OUT t_table_ds_events,
        o_items_values OUT t_table_ds_items_values,
        o_data_val     OUT xmltype,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get dynamic screen sections and events list
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_params                    Group of parameters
    * @param   o_section                   Section cursor
    * @param   o_def_events                Default events cursor
    * @param   o_events                    Events cursor
    * @param   o_items_values              Item values for multichoices of single choice
    * @param   o_data_val                  Default data or previous saved data
    * @param   o_error                     Error information
    *
    * @example i_params                    Example of the XML passed in this variable
    *          <PARAMETERS ID_EPISODE="" ID_PATIENT="" FLG_EDIT_MODE="">
    *              <DIAGNOSIS ID_DIAGNOSIS="" ID_ALERT_DIAG="" DESC_DIAGNOSIS="" FLG_TYPE="" FLG_REUSE_PAST_DIAG="" /> <!-- This information is available just when creating a new diagnosis -->
    *              <!-- FLG_REUSE_PAST_DIAG - if is to reuse epis_diagnosis data from a past diagnosis -->
    *              <!-- ID_EPIS_DIAGNOSIS is only needed when editing the current episode diagnosis, in the case of cancer diagnosis also means editing the current staging diagnosis
    *                   ID_EPIS_DIAGNOSIS_HIST is only needed for cancer diagnosis when editing a past staging diagnosis  -->
    *              <EPIS_DIAGNOSIS ID_EPIS_DIAGNOSIS="" ID_EPIS_DIAGNOSIS_HIST="" /> <!-- This information is available just when editing a existing diagnosis -->
    *              <DS_COMPONENT INTERNAL_NAME="" FLG_COMPONENT_TYPE="" /> <!-- Used to get information of form sections, etc...; NAME = I_COMPONENT_NAME; TYPE = I_COMPONENT_TYPE -->
    *              <TOPOGRAPHY ID="" /> <!-- Selected user option -->
    *              <MORPHOLOGY HISTOLOGY="" BEHAVIOR="" GRADE="" />  <!-- Selected user option -->
    *              <TNM T="" N="" M="" />  <!-- Selected user option -->
    *              <STAGING_BASIS ID="" />  <!-- Selected user option -->
    *              <BASIS_DIAG ID="" /> <!-- Selected user option -->
    *              <DS_COMPONENTS> 
    *                  <!-- Used to get information of MS, MM, FR fields that depend on user selection -->
    *                  <!-- Set of fields whose values we want to get -->
    *                  <DS_COMPONENT ID_DS_CMPT_MKT_REL=""  ID_DS_COMPONENT_PARENT="" ID_DS_COMPONENT="" COMPONENT_DESC="" INTERNAL_NAME="" FLG_COMPONENT_TYPE="" FLG_DATA_TYPE="" SLG_INTERNAL_NAME="" RANK="" />
    *              </DS_COMPONENTS>
    *          </PARAMETERS>
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6
    * @since   17-01-2012
    */
    FUNCTION get_section_data_db
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_params       IN CLOB,
        o_section      OUT t_table_ds_sections,
        o_def_events   OUT t_table_ds_def_events,
        o_events       OUT t_table_ds_events,
        o_items_values OUT t_table_ds_items_values,
        o_data_val     OUT xmltype,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get dynamic screen sections and events list
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_params                    Group of parameters
    * @param   o_section                   Section cursor
    * @param   o_def_events                Default events cursor
    * @param   o_events                    Events cursor
    * @param   o_items_values              Item values for multichoices of single choice
    * @param   o_data_val                  Default data or previous saved data
    * @param   o_error                     Error information
    *
    * @example i_params                    Example of the XML passed in this variable
    *          <PARAMETERS ID_EPISODE="" ID_PATIENT="">
    *              <!-- ID_EPIS_DIAGNOSIS is only needed when editing the current episode diagnosis, in the case of cancer diagnosis also means editing the current staging diagnosis
    *                   ID_EPIS_DIAGNOSIS_HIST is only needed for cancer diagnosis when editing a past staging diagnosis  -->
    *              <DIAGNOSIS ID="" FLG_TYPE="" /> <!-- This information is available just when creating a new diagnosis -->
    *              <EPIS_DIAGNOSIS ID_EPIS_DIAGNOSIS="" ID_EPIS_DIAGNOSIS_HIST="" /> <!-- This information is available just when editing a existing diagnosis -->
    *              <DS_COMPONENT INTERNAL_NAME="" FLG_COMPONENT_TYPE="" /> <!-- Used to get information of form sections, etc...; NAME = I_COMPONENT_NAME; TYPE = I_COMPONENT_TYPE -->
    *              <TOPOGRAPHY ID="" /> <!-- Selected user option -->
    *              <MORPHOLOGY HISTOLOGY="" BEHAVIOR="" GRADE="" />  <!-- Selected user option -->
    *              <TNM T="" N="" M="" />  <!-- Selected user option -->
    *              <STAGING_BASIS ID="" />  <!-- Selected user option -->
    *              <BASIS_DIAG ID="" /> <!-- Selected user option -->
    *              <DS_COMPONENTS> 
    *                  <!-- Used to get information of MS, MM, FR fields that depend on user selection -->
    *                  <!-- Set of fields whose values we want to get -->
    *                  <DS_COMPONENT ID_DS_CMPT_MKT_REL=""  ID_DS_COMPONENT_PARENT="" ID_DS_COMPONENT="" COMPONENT_DESC="" INTERNAL_NAME="" FLG_COMPONENT_TYPE="" FLG_DATA_TYPE="" SLG_INTERNAL_NAME="" RANK="" />
    *              </DS_COMPONENTS>
    *          </PARAMETERS>
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6
    * @since   17-01-2012
    */
    FUNCTION get_section_data
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_params       IN CLOB,
        o_section      OUT pk_types.cursor_type,
        o_def_events   OUT pk_types.cursor_type,
        o_events       OUT pk_types.cursor_type,
        o_items_values OUT pk_types.cursor_type,
        o_data_val     OUT CLOB,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get dynamic screen sections and events list
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_params                    Group of parameters
    * @param   o_stage_info                Stage information
    * @param   o_error                     Error information
    *
    * @example i_params                    Example of the XML passed in this variable
    *
    * <PARAMETERS>
    *   <STAGING STAGING_BASIS="" TNM_T="" CODE_STAGE_T="" TNM_N="" CODE_STAGE_N="" TNM_M="" CODE_STAGE_M="">
    *     <PROG_FACTORS>
    *       <PROG_FACTOR ID_LABEL="" ID_VALUE="" />
    *     </PROG_FACTORS>
    *   </STAGING>
    * </PARAMETERS>
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6
    * @since   17-01-2012
    */
    FUNCTION get_calculate_fields_values
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_params     IN CLOB,
        o_stage_info OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**
    * Get the resulting ICDO diagnosis description to be placed in the form
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_params                    Group of parameters
    * @param   o_diag_icdo                 Diagnosis description
    * @param   o_error                     Error information
    *
    * @example i_params                    Example of the XML passed in this variable
    *
    * <PARAMETERS BEHAVIOR="" HISTOLOGY="" TOPOGRAPHY="" />
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  José Silva
    * @version v2.6.2.1
    * @since   28-03-2012
    */
    FUNCTION get_calculate_diag_icdo
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_params    IN CLOB,
        o_diag_icdo OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**
    * Parse XML parameter to database pl/sql record types
    *
    * @param   i_lang                  Professional preferred language
    * @param   i_prof                  Professional identification and its context (institution and software)
    * @param   i_params                XML with all input parameters
    * @param   o_rec_in_epis_diagnoses Save parameters
    * @param   o_error                 Error information
    *
    * @example i_params                See the example of set_epis_diagnosis function
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    *
    * @author  Alexandre Santos
    * @version 2.6.2.1
    * @since   19/03/2012
    */
    FUNCTION get_save_parameters
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_params                IN CLOB,
        o_rec_in_epis_diagnoses OUT pk_edis_types.rec_in_epis_diagnoses,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**
    * Parse database pl/sql record type to XML
    *
    * @param   i_lang                  Professional preferred language
    * @param   i_prof                  Professional identification and its context (institution and software)
    * @param   i_out_params            Onput parameter object
    * @param   o_out_params            XML output parameters
    * @param   o_error                 Error information
    *
    * @example o_out_params            See the example of set_epis_diagnosis function
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    *
    * @author  Alexandre Santos
    * @version 2.6.2.1
    * @since   19/03/2012
    */
    FUNCTION get_out_parameters
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_out_params IN pk_edis_types.table_out_epis_diags,
        o_out_params OUT CLOB,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**
    * Encapsulates the logic of saving (create/update/cancel) a diagnosis
    * (CALLED BY: FLASH)
    *
    * @param   i_lang                  Professional preferred language
    * @param   i_prof                  Professional identification and its context (institution and software)
    * @param   i_params                XML with all input parameters
    * @param   o_params                XML with all output parameters
    * @param   o_error                 Error information
    *
    * @example i_params                Example of the possible XML passed in this variable
    *
    * <EPIS_DIAGNOSES ID_PATIENT="" ID_EPISODE="" PROF_CAT_TYPE="" FLG_TYPE="" FLG_EDIT_MODE="" ID_CDR_CALL="">
    *   <!-- 
    *   FLG_TYPE: P - Working diag; D - Final diag
    *   FLG_EDIT_MODE: Flag to diferentiate which fields are being updated
    *       S - Diagnosis Status edit
    *       T - Diagnosis Type edit
    *       N - Diagnosis screen edition (multiple values editable)
    *   --> 
    *   <EPIS_DIAGNOSIS ID_EPIS_DIAGNOSIS="" ID_EPIS_DIAGNOSIS_HIST=""  FLG_TRANSF_FINAL="" ID_CANCEL_REASON="" CANCEL_NOTES="" FLG_CANCEL_DIFF_DIAG="" >
    *     <!-- 
    *     ID_EPIS_DIAGNOSIS OR ID_EPIS_DIAGNOSIS_HIST mandatory when editing
    *     ID_EPIS_DIAGNOSIS is needed when editing the current episode diagnosis, in the case of cancer diagnosis also means editing the current staging diagnosis
    *     ID_EPIS_DIAGNOSIS_HIST is needed for cancer diagnosis when editing a past staging diagnosis
    *     --> 
    *     <!-- 
    *        In case of association only ID is needed for diagnosis
    *     --> 
    *     
    *     <DIAGNOSIS ID="" ID_ALERT_DIAG="" DESC_DIAGNOSIS="" FLG_FINAL_TYPE="" FLG_STATUS="" FLG_ADD_PROBLEM="" NOTES="" >
    *       <CHARACTERIZATION DT_INIT_DIAG="" BASIS_DIAG_MS="" BASIS_DIAG_SPEC= "" NUM_PRIM_TUMORS_MS_YN="" NUM_PRIM_TUMORS_NUM="" RECURRENCE="" />
    *       <!-- 
    *       DESC_DIAGNOSIS only available when creating a new diagnosis
    *       ID_ALERT_DIAG only necessary when creating
    *       -->
    *       <TUMORS>
    *         <TUMOR NUM="" TOPOGRAPHY="" LATERALITY="" HISTOLOGY="" BEHAVIOR="" HISTOLOGIC_GRADE="" OTHER_GRADING_SYSTEM=""
    *              PRIMARY_TUMOR_SIZE_UNKNOWN="" PRIMARY_TUMOR_SIZE_NUMERIC="" PRIMARY_TUMOR_SIZE_DESCRIPTIVE="" ADDITIONAL_PATH_INFO="" />
    *       </TUMORS>
    *       <STAGING STAGING_BASIS="" TNM_T="" TNM_N="" TNM_M="" METASTATIC_SITES="" RESIDUAL_TUMOR="" SURGICAL_MARGINS="" LYMPH_VASCULAR_INVASION="" OTHER_STAGING_SYSTEM="">
    *         <PROG_FACTORS>
    *           <PROG_FACTOR ID_LABEL="" LABEL_RANK="" ID_VALUE="" FT=""  />
    *         </PROG_FACTORS>
    *       </STAGING>
    *     </DIAGNOSIS>
    *     <!--
    *     FLG_CANCEL_DIFF_DIAG: Flag that indicates if differencial diagnoses should also be cancelled (This flag is only necessary when cancelling a final diagnosis)
    *     -->
    *   </EPIS_DIAGNOSIS>
    *   <GENERAL_NOTES ID="" VALUE="" ID_CANCEL_REASON="" />
    *   <!--
    *   ID: is equal to ID_EPIS_DIAGNOSIS_NOTES, this is only used when editing the general note
    *   ID_CANCEL_REASON: Only mandatory when cancelling the general notes
    *   -->
    * 
    * </EPIS_DIAGNOSES>
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    *
    * @author  Sergio Dias
    * @version 1.0
    * @since   14/Fev/2012
    */
    FUNCTION set_epis_diagnosis
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_params IN CLOB,
        o_params OUT CLOB,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************
    ********************************************************************************/
    FUNCTION set_confirmed_epis_diagnosis
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN alert.profissional,
        i_params            IN CLOB,
        o_id_epis_diagnosis OUT table_number,
        o_id_diagnosis      OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    --
    /**
    * Gets the patient age on the given date
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_patient                   Patient id
    * @param   i_when                      Date on which you want to know the patient's age
    * @param   o_pat_age                   Patient age on the given date
    * @param   o_error                     Error information
    *
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.2.1
    * @since   28-03-2012
    */
    FUNCTION get_pat_age
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_when    IN VARCHAR2,
        o_pat_age OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**
    * Gets the patient age on the given date
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_patient                   Patient id
    * @param   i_when                      Date on which you want to know the patient's age
    *
    * @return  Patient age on the given date
    *
    * @author  Alexandre Santos
    * @version v2.6.2.1
    * @since   28-03-2012
    */
    FUNCTION get_pat_age
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_when    IN patient.dt_deceased%TYPE
    ) RETURN VARCHAR2;
    --
    /**
    * Check if any of the selected diagnoses were registered in a past episode
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_params                    Group of parameters
    * @param   o_title                     Confirmation title
    * @param   o_msg                       Confirmation message
    * @param   o_diags                     Diagnoses info
    * @param   o_error                     Error information
    *
    * @example i_params                    Example of the XML passed in this variable
    *
    * <PARAMETERS ID_PATIENT="" ID_EPISODE="">
    *   <DIAGNOSIS ID_DIAGNOSIS="" ID_ALERT_DIAGNOSIS=""/>
    * </PARAMETERS>
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6
    * @since   26-06-2012
    */
    FUNCTION check_diag_already_reg
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_params IN CLOB,
        o_title  OUT VARCHAR2,
        o_msg    OUT VARCHAR2,
        o_diags  OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**
    * Get cancer diagnosis already registered in a past episode
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_patient                   Patient ID
    * @param   i_episode                   Episode ID
    * @param   i_diagnosis                 Diagnosis ID
    * @param   i_alert_diagnosis           Alert Diagnoses ID
    *
    * @return  id_epis_diagnosis of the past episode
    *
    * @author  Alexandre Santos
    * @version v2.6
    * @since   10-07-2012
    */
    FUNCTION get_cancer_diag_already_reg
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_diagnosis       IN diagnosis.id_diagnosis%TYPE,
        i_alert_diagnosis IN alert_diagnosis.id_alert_diagnosis%TYPE
    ) RETURN epis_diagnosis.id_epis_diagnosis%TYPE;

    /********************************************************************************************
    * Function that returns the the place of occurence of the diagnosis
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_diagnosis              Diagnosis ID
    * @param i_diag_type              Concept type DEFAULT DIAGNOSIS
    * @param i_id_location            Place of occurence ID
    * @param i_show_code              if the code Should be shown (Default Y)
     *
    * @return                         place of occurence
    *
    *
    * @author                         Elisabete Bugalho
    * @version                        2.7.0
    * @since                          16/11/2016
    **********************************************************************************************/
    FUNCTION get_place_of_occurence
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_diagnosis   IN diagnosis.id_diagnosis%TYPE,
        i_diag_type   IN diagnosis.concept_type_int_name%TYPE DEFAULT g_cncpt_type_diag,
        i_id_location IN diagnosis_ea.id_concept_term%TYPE DEFAULT NULL,
        i_show_code   IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_location    OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Function that returns the the places of occurence of the diagnoses
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_diagnosis              Collection of diagnoses IDs
    * @param i_id_location            Collection of places of occurence (IDs already registered)
    *
    * @return                         Places of occurence
    *
    * Note: This function will return the locations that are common to all the input diagnoses.
    **********************************************************************************************/
    FUNCTION get_place_of_occurence
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_diagnosis   IN table_number,
        i_diag_type   IN diagnosis.concept_type_int_name%TYPE DEFAULT g_cncpt_type_diag,
        i_id_location IN table_number DEFAULT NULL,
        o_location    OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Function that returns the list of mandatory components of the selected diagnoses
    * (used for multiple selection)
    *    
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_id_patient             Patient ID
    * @param i_id_episode             Episode ID
    * @param i_id_diagnosis           List of diagnoses IDs
    * @param i_id_alert_diagnosis     List of alert diagnoses IDs
    * @param i_desc_diagnosis         List of diagnoses descriptions
    * @param i_flg_type               List of type of each diagnosis (P-Working diagnosis/D-Discharge diagnosis)
    *
    * @return                         List of mandatory sections of the selected diagnoses
    *
    *
    * @author                         Diogo Oliveira
    * @version                        2.7.4.0
    * @since                          14/05/2018
    **********************************************************************************************/
    FUNCTION get_mandatory_sections
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_diagnosis       IN table_number,
        i_id_alert_diagnosis IN table_number,
        i_desc_diagnosis     IN table_varchar,
        i_flg_type           IN table_varchar,
        o_mandatory_sections OUT t_tbl_diag_mandatory_sections,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

END pk_diagnosis_form;
/
