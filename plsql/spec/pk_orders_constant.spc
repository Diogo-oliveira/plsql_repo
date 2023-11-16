/*-- Last Change Revision: $Rev: 2001311 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2021-11-12 14:35:07 +0000 (sex, 12 nov 2021) $*/

CREATE OR REPLACE PACKAGE pk_orders_constant IS

    -- Public constant declarations
    --Root names
    g_ds_lab_results                      CONSTANT VARCHAR2(50 CHAR) := 'DS_LAB_RESULTS';
    g_ds_lab_results_with_prof_list       CONSTANT VARCHAR2(50 CHAR) := 'DS_LAB_RESULTS_WITH_PROF_LIST';
    g_ds_procedure_request                CONSTANT VARCHAR2(50 CHAR) := 'DS_PROCEDURE_REQUEST';
    g_ds_imaging_exam_request             CONSTANT VARCHAR2(50 CHAR) := 'DS_IMAGING_EXAM_REQUEST';
    g_ds_other_exam_request               CONSTANT VARCHAR2(50 CHAR) := 'DS_OTHER_EXAM_REQUEST';
    g_ds_lab_test_request                 CONSTANT VARCHAR2(50 CHAR) := 'DS_LAB_TEST_REQUEST';
    g_ds_health_education_order           CONSTANT VARCHAR2(50 CHAR) := 'DS_HEALTH_EDUCATION_ORDER';
    g_ds_health_education_order_execution CONSTANT VARCHAR2(50 CHAR) := 'DS_HEALTH_EDUCATION_ORDER_EXECUTION';
    g_ds_health_education_execution       CONSTANT VARCHAR2(50 CHAR) := 'DS_HEALTH_EDUCATION_EXECUTION';
    g_ds_positioning                      CONSTANT VARCHAR2(50 CHAR) := 'DS_POSITIONING';
    g_ds_sr_positioning                   CONSTANT VARCHAR2(50 CHAR) := 'DS_SR_POSITIONING';
    g_ds_positioning_execution            CONSTANT VARCHAR2(50 CHAR) := 'DS_POSITIONING_EXECUTION';
    g_ds_rehab_treatment                  CONSTANT VARCHAR2(50 CHAR) := 'DS_REHAB_TREATMENT';
    g_ds_other_frequencies                CONSTANT VARCHAR2(50 CHAR) := 'DS_OTHER_FREQUENCIES';
    g_ds_to_execute                       CONSTANT VARCHAR2(50 CHAR) := 'DS_TO_EXECUTE';
    g_ds_prof_bleep_info                  CONSTANT VARCHAR2(50 CHAR) := 'DS_PROF_BLEEP_INFO';
    g_ds_exam_associate_pregnancy         CONSTANT VARCHAR2(50 CHAR) := 'DS_EXAM_ASSOCIATE_PREGNANCY';

    --Root names for order sets
    g_ds_order_set_bo                     CONSTANT VARCHAR2(50 CHAR) := 'DS_ORDER_SET_BO';
    g_ds_order_set_monitoring             CONSTANT VARCHAR2(50 CHAR) := 'DS_ORDER_SET_MONITORING';
    g_ds_order_set_consult                CONSTANT VARCHAR2(50 CHAR) := 'DS_ORDER_SET_CONSULT';
    g_ds_order_set_health_education       CONSTANT VARCHAR2(50 CHAR) := 'DS_ORDER_SET_HEALTH_EDUCATION';
    g_ds_procedure_os_creation            CONSTANT VARCHAR2(50 CHAR) := 'DS_ORDER_SET_PROCEDURE'; --eliminar
    g_ds_order_set_procedure              CONSTANT VARCHAR2(50 CHAR) := 'DS_ORDER_SET_PROCEDURE';
    g_ds_order_set_medical_appointment    CONSTANT VARCHAR2(50 CHAR) := 'DS_ORDER_SET_MEDICAL_APPOINTMENT';
    g_ds_order_set_nursing_appointment    CONSTANT VARCHAR2(50 CHAR) := 'DS_ORDER_SET_NURSING_APPOINTMENT';
    g_ds_order_set_rehab_appointment      CONSTANT VARCHAR2(50 CHAR) := 'DS_ORDER_SET_REHAB_APPOINTMENT';
    g_ds_order_set_social_appointment     CONSTANT VARCHAR2(50 CHAR) := 'DS_ORDER_SET_SOCIAL_APPOINTMENT';
    g_ds_order_set_diet_appointment       CONSTANT VARCHAR2(50 CHAR) := 'DS_ORDER_SET_DIET_APPOINTMENT';
    g_ds_order_set_discharge_instructions CONSTANT VARCHAR2(50 CHAR) := 'DS_ORDER_SET_DISCHARGE_INSTRUCTIONS';
    g_ds_order_set_personalised_diets     CONSTANT VARCHAR2(50 CHAR) := 'DS_ORDER_SET_PERSONALISED_DIETS';
    g_ds_order_set_group                  CONSTANT VARCHAR2(50 CHAR) := 'DS_ORDER_SET_GROUP';
    g_ds_order_set_front_office           CONSTANT VARCHAR2(50 CHAR) := 'DS_ORDER_SET_FRONT_OFFICE';

    --FOLLOW-UP ROOTS
    g_ds_follow_up_social             CONSTANT VARCHAR2(50 CHAR) := 'DS_FOLLOW_UP_SOCIAL';
    g_ds_follow_up_case_management    CONSTANT VARCHAR2(50 CHAR) := 'DS_FOLLOW_UP_CASE_MANAGEMENT';
    g_ds_follow_up_cdc                CONSTANT VARCHAR2(50 CHAR) := 'DS_FOLLOW_UP_CDC';
    g_ds_follow_up_mental             CONSTANT VARCHAR2(50 CHAR) := 'DS_FOLLOW_UP_MENTAL';
    g_ds_follow_up_diet               CONSTANT VARCHAR2(50 CHAR) := 'DS_FOLLOW_UP_DIET';
    g_ds_follow_up_psy                CONSTANT VARCHAR2(50 CHAR) := 'DS_FOLLOW_UP_PSY';
    g_ds_follow_up_rehab_occupational CONSTANT VARCHAR2(50 CHAR) := 'DS_FOLLOW_UP_REHAB_OCCUPATIONAL';
    g_ds_follow_up_rehab_physical     CONSTANT VARCHAR2(50 CHAR) := 'DS_FOLLOW_UP_REHAB_PHYSICAL';
    g_ds_follow_up_rehab_speech       CONSTANT VARCHAR2(50 CHAR) := 'DS_FOLLOW_UP_REHAB_SPEECH';
    g_ds_follow_up_religious          CONSTANT VARCHAR2(50 CHAR) := 'DS_FOLLOW_UP_RELIGIOUS';
    g_ds_follow_up_social_original    CONSTANT VARCHAR2(50 CHAR) := 'DS_FOLLOW_UP_SOCIAL_ORIGINAL';
    g_ds_follow_up_activity_therapist CONSTANT VARCHAR2(50 CHAR) := 'DS_FOLLOW_UP_ACTIVITY_THERAPIST';

    --Root names for referrals
    g_p1_appointment  CONSTANT VARCHAR2(50 CHAR) := 'DS_P1_APPOINTMENT';
    g_p1_lab_test     CONSTANT VARCHAR2(50 CHAR) := 'DS_P1_LAB_TEST';
    g_p1_imaging_exam CONSTANT VARCHAR2(50 CHAR) := 'DS_P1_IMAGING_EXAM';
    g_p1_other_exam   CONSTANT VARCHAR2(50 CHAR) := 'DS_P1_OTHER_EXAM';
    g_p1_intervention CONSTANT VARCHAR2(50 CHAR) := 'DS_P1_INTERVENTION';
    g_p1_rehab        CONSTANT VARCHAR2(50 CHAR) := 'DS_P1_REHAB';

    --DS_COMPONENTS internal names
    g_ds_to_execute_list                  CONSTANT VARCHAR2(50 CHAR) := 'DS_EXECUTE_MW';
    g_ds_execute                          CONSTANT VARCHAR2(50 CHAR) := 'DS_EXECUTE';
    g_ds_to_be_executed                   CONSTANT VARCHAR2(50 CHAR) := 'DS_TO_BE_EXECUTED';
    g_ds_start_date                       CONSTANT VARCHAR2(50 CHAR) := 'DS_START_DATE';
    g_ds_start_date_medium                CONSTANT VARCHAR2(50 CHAR) := 'DS_START_DATE_MEDIUM';
    g_ds_quantity_execution               CONSTANT VARCHAR2(50 CHAR) := 'DS_QUANTITY_EXECUTION';
    g_ds_special_type                     CONSTANT VARCHAR2(50 CHAR) := 'DS_SPECIAL_TYPE';
    g_ds_special_instructions             CONSTANT VARCHAR2(50 CHAR) := 'DS_SPECIAL_INSTRUCTIONS';
    g_ds_priority                         CONSTANT VARCHAR2(50 CHAR) := 'DS_PRIORITY';
    g_ds_prn                              CONSTANT VARCHAR2(50 CHAR) := 'DS_PRN';
    g_ds_prn_specify                      CONSTANT VARCHAR2(50 CHAR) := 'DS_PRN_SPECIFY';
    g_ds_hemo_type                        CONSTANT VARCHAR2(50 CHAR) := 'DS_HEMO_TYPE';
    g_ds_dummy_number                     CONSTANT VARCHAR2(50 CHAR) := 'DS_DUMMY_NUMBER';
    g_ds_frequency                        CONSTANT VARCHAR2(50 CHAR) := 'DS_FREQUENCY';
    g_ds_other_frequency                  CONSTANT VARCHAR2(50 CHAR) := 'DS_OTHER_FREQUENCY';
    g_ds_executions                       CONSTANT VARCHAR2(50 CHAR) := 'DS_EXECUTIONS';
    g_ds_duration                         CONSTANT VARCHAR2(50 CHAR) := 'DS_DURATION';
    g_ds_unit_measure                     CONSTANT VARCHAR2(50 CHAR) := 'DS_UNIT_MEASURE';
    g_ds_end_date                         CONSTANT VARCHAR2(50 CHAR) := 'DS_END_DT';
    g_ds_to_date                          CONSTANT VARCHAR2(50 CHAR) := 'DS_TO_DATE';
    g_ds_order_type                       CONSTANT VARCHAR2(50 CHAR) := 'DS_ORDER_TYPE';
    g_ds_ordered_by                       CONSTANT VARCHAR2(50 CHAR) := 'DS_ORDERED_BY';
    g_ds_ordered_at                       CONSTANT VARCHAR2(50 CHAR) := 'DS_ORDERED_AT';
    g_ds_execution_ordered_at             CONSTANT VARCHAR2(50 CHAR) := 'DS_EXECUTION_ORDERED_AT';
    g_ds_financial_entity                 CONSTANT VARCHAR2(50 CHAR) := 'DS_FINANCIAL_ENTITY';
    g_ds_health_coverage_plan             CONSTANT VARCHAR2(50 CHAR) := 'DS_HEALTH_COVERAGE_PLAN';
    g_ds_beneficiary_number               CONSTANT VARCHAR2(50 CHAR) := 'DS_BENEFICIARY_NUMBER';
    g_ds_health_plan_number               CONSTANT VARCHAR2(50 CHAR) := 'DS_HEALTH_PLAN_NUMBER';
    g_ds_exemption                        CONSTANT VARCHAR2(50 CHAR) := 'DS_EXEMPTION';
    g_ds_daily_executions                 CONSTANT VARCHAR2(50 CHAR) := 'DS_DAILY_EXECUTIONS';
    g_ds_time_schedule                    CONSTANT VARCHAR2(50 CHAR) := 'DS_TIME_SCHEDULE';
    g_ds_regular_intervals                CONSTANT VARCHAR2(50 CHAR) := 'DS_REGULAR_INTERVALS';
    g_ds_recurrence_pattern               CONSTANT VARCHAR2(50 CHAR) := 'DS_RECURRENCE_PATTERN';
    g_ds_repeat_every                     CONSTANT VARCHAR2(50 CHAR) := 'DS_REPEAT_EVERY';
    g_ds_end_based                        CONSTANT VARCHAR2(50 CHAR) := 'DS_END_BASED';
    g_ds_end_after                        CONSTANT VARCHAR2(50 CHAR) := 'DS_END_AFTER';
    g_ds_end_after_n                      CONSTANT VARCHAR2(50 CHAR) := 'DS_END_AFTER_N';
    g_ds_end_after_occurrences            CONSTANT VARCHAR2(50 CHAR) := 'DS_END_AFTER_OCCURRENCES';
    g_ds_description                      CONSTANT VARCHAR2(50 CHAR) := 'DS_DESCRIPTION';
    g_ds_notes_clob                       CONSTANT VARCHAR2(50 CHAR) := 'DS_NOTES_CLOB';
    g_ds_clinical_indication_icnp_mw      CONSTANT VARCHAR2(50 CHAR) := 'DS_CLINICAL_INDICATION_ICNP_MW';
    g_ds_clinical_purpose                 CONSTANT VARCHAR2(50 CHAR) := 'DS_CLINICAL_PURPOSE';
    g_ds_clinical_purpose_ft              CONSTANT VARCHAR2(50 CHAR) := 'DS_CLINICAL_PURPOSE_FT';
    g_ds_professional                     CONSTANT VARCHAR2(50 CHAR) := 'DS_PROFESSIONAL';
    g_ds_place_service                    CONSTANT VARCHAR2(50 CHAR) := 'DS_PLACE_SERVICE';
    g_ds_number_sessions                  CONSTANT VARCHAR2(50 CHAR) := 'DS_NUMBER_SESSIONS';
    g_ds_frequency_sessions               CONSTANT VARCHAR2(50 CHAR) := 'DS_FREQUENCY_SESSIONS';
    g_ds_executions_sessions              CONSTANT VARCHAR2(50 CHAR) := 'DS_EXECUTIONS_SESSIONS';
    g_ds_reason_not_ordering              CONSTANT VARCHAR2(50 CHAR) := 'DS_REASON_NOT_ORDERING';
    g_ds_reason_not_ordering_control      CONSTANT VARCHAR2(50 CHAR) := 'DS_REASON_NOT_ORDERING_CONTROL';
    g_ds_clinical_indication_ft           CONSTANT VARCHAR2(50 CHAR) := 'DS_CLINICAL_INDICATION_FT';
    g_ds_icf                              CONSTANT VARCHAR2(50 CHAR) := 'DS_ICF';
    g_ds_edition                          CONSTANT VARCHAR2(50 CHAR) := 'DS_EDITION';
    g_ds_lab_test_result                  CONSTANT VARCHAR2(50 CHAR) := 'DS_LAB_TEST_RESULT';
    g_ds_weight_kg                        CONSTANT VARCHAR2(50 CHAR) := 'DS_WEIGHT_KG';
    g_ds_unit_measure_regular_intervals   CONSTANT VARCHAR2(50 CHAR) := 'DS_UNIT_MEASURE_REGULAR_INTERVALS';
    g_ds_catalogue                        CONSTANT VARCHAR2(50 CHAR) := 'DS_CATALOGUE';
    g_ds_healthcare_insurance_control     CONSTANT VARCHAR2(50 CHAR) := 'DS_HEALTHCARE_INSURANCE_CONTROL';
    g_ds_healthcare_insurance_cat_control CONSTANT VARCHAR2(50 CHAR) := 'DS_HEALTHCARE_INSURANCE_CAT_CONTROL';
    g_ds_co_sign_control                  CONSTANT VARCHAR2(50 CHAR) := 'DS_CO_SIGN_CONTROL';
    g_ds_notes_execution                  CONSTANT VARCHAR2(50 CHAR) := 'DS_NOTES_EXECUTION';
    g_ds_fasting                          CONSTANT VARCHAR2(50 CHAR) := 'DS_FASTING';
    g_ds_location                         CONSTANT VARCHAR2(50 CHAR) := 'DS_LOCATION';
    g_ds_type_of_visit                    CONSTANT VARCHAR2(50 CHAR) := 'DS_TYPE_OF_VISIT';
    g_ds_reason_for_visit                 CONSTANT VARCHAR2(50 CHAR) := 'DS_REASON_FOR_VISIT';
    g_ds_reason_for_visit_ms              CONSTANT VARCHAR2(50 CHAR) := 'DS_REASON_FOR_VISIT_MS';
    g_ds_type_of_encounter                CONSTANT VARCHAR2(50 CHAR) := 'DS_TYPE_OF_ENCOUNTER';
    g_ds_approved_by                      CONSTANT VARCHAR2(50 CHAR) := 'DS_APPROVED_BY';
    g_ds_room                             CONSTANT VARCHAR2(50 CHAR) := 'DS_ROOM';
    g_ds_reason_for_order                 CONSTANT VARCHAR2(50 CHAR) := 'DS_REASON_FOR_ORDER';
    g_ds_end_by                           CONSTANT VARCHAR2(50 CHAR) := 'DS_END_BY';
    g_ds_week_day                         CONSTANT VARCHAR2(50 CHAR) := 'DS_WEEK_DAY';
    g_ds_repeat_by                        CONSTANT VARCHAR2(50 CHAR) := 'DS_REPEAT_BY';
    g_ds_days_month                       CONSTANT VARCHAR2(50 CHAR) := 'DS_DAYS_MONTH';
    g_ds_on_weeks                         CONSTANT VARCHAR2(50 CHAR) := 'DS_ON_WEEKS';
    g_ds_on_months                        CONSTANT VARCHAR2(50 CHAR) := 'DS_ON_MONTHS';
    g_ds_execution_date                   CONSTANT VARCHAR2(50 CHAR) := 'DS_EXECUTION_DATE';
    g_ds_scheduling_notes                 CONSTANT VARCHAR2(50 CHAR) := 'DS_SCHEDULING_NOTES';
    g_ds_notes_technician                 CONSTANT VARCHAR2(50 CHAR) := 'DS_NOTES_TECHNICIAN';
    g_ds_patient_instructions             CONSTANT VARCHAR2(50 CHAR) := 'DS_PATIENT_INSTRUCTIONS';
    g_ds_order_method                     CONSTANT VARCHAR2(50 CHAR) := 'DS_ORDER_METHOD';
    g_ds_translation                      CONSTANT VARCHAR2(50 CHAR) := 'DS_TRANSLATION';
    g_ds_episode                          CONSTANT VARCHAR2(50 CHAR) := 'DS_EPISODE';
    g_ds_no_later                         CONSTANT VARCHAR2(50 CHAR) := 'DS_NO_LATER';
    g_ds_specimen                         CONSTANT VARCHAR2(50 CHAR) := 'DS_SPECIMEN';
    g_ds_body_location                    CONSTANT VARCHAR2(50 CHAR) := 'DS_BODY_LOCATION';
    g_ds_collection_place                 CONSTANT VARCHAR2(50 CHAR) := 'DS_COLLECTION_PLACE';
    g_ds_specialty                        CONSTANT VARCHAR2(50 CHAR) := 'DS_SPECIALTY';
    g_ds_bleep_number                     CONSTANT VARCHAR2(50 CHAR) := 'DS_BLEEP_NUMBER';
    g_ds_work_phone                       CONSTANT VARCHAR2(50 CHAR) := 'DS_WORK_PHONE';
    g_ds_mobile_phone                     CONSTANT VARCHAR2(50 CHAR) := 'DS_MOBILE_PHONE';
    g_ds_work_phone_ft                    CONSTANT VARCHAR2(50 CHAR) := 'DS_WORK_PHONE_FT';
    g_ds_mobile_phone_ft                  CONSTANT VARCHAR2(50 CHAR) := 'DS_MOBILE_PHONE_FT';
    g_ds_patient_assistance               CONSTANT VARCHAR2(50 CHAR) := 'DS_PATIENT_ASSISTANCE';
    g_ds_diet_after_discharge             CONSTANT VARCHAR2(50 CHAR) := 'DS_DIET_AFTER_DISCHARGE';
    g_ds_exam_associate_pregnancy_record  CONSTANT VARCHAR2(50 CHAR) := 'DS_EXAM_ASSOCIATE_PREGNANCY_RECORD';
    g_ds_pregnancy_number                 CONSTANT VARCHAR2(50 CHAR) := 'DS_PREGNANCY_NUMBER';
    g_ds_last_menstrual_date              CONSTANT VARCHAR2(50 CHAR) := 'DS_LAST_MENSTRUAL_DATE';
    g_ds_delivery_date                    CONSTANT VARCHAR2(50 CHAR) := 'DS_DELIVERY_DATE';
    g_ds_live_births                      CONSTANT VARCHAR2(50 CHAR) := 'DS_LIVE_BIRTHS';
    g_ds_pregnancy_abortion_type          CONSTANT VARCHAR2(50 CHAR) := 'DS_PREGNANCY_ABORTION_TYPE';
    g_ds_delivery_type                    CONSTANT VARCHAR2(50 CHAR) := 'DS_DELIVERY_TYPE';

    g_ds_health_education_goals    CONSTANT VARCHAR2(50 CHAR) := 'DS_HEALTH_EDUCATION_GOALS';
    g_ds_health_education_goals_ft CONSTANT VARCHAR2(50 CHAR) := 'DS_HEALTH_EDUCATION_GOALS_FT';
    g_ds_health_education_method   CONSTANT VARCHAR2(50 CHAR) := 'DS_HEALTH_EDUCATION_METHOD';
    g_ds_health_educ_method_ft     CONSTANT VARCHAR2(50 CHAR) := 'DS_HEALTH_EDUCATION_METHOD_FT';
    g_ds_health_educ_given_to      CONSTANT VARCHAR2(50 CHAR) := 'DS_HEALTH_EDUCATION_GIVEN_TO';
    g_ds_health_educ_given_to_ft   CONSTANT VARCHAR2(50 CHAR) := 'DS_HEALTH_EDUCATION_GIVEN_TO_FT';
    g_ds_health_educ_addit_res     CONSTANT VARCHAR2(50 CHAR) := 'DS_HEALTH_EDUCATION_ADDITIONAL_RESOURCES';
    g_ds_health_educ_addit_res_ft  CONSTANT VARCHAR2(50 CHAR) := 'DS_HEALTH_EDUCATION_ADDITIONAL_RESOURCES_FT';
    g_ds_health_educ_level_und     CONSTANT VARCHAR2(50 CHAR) := 'DS_HEALTH_EDUCATION_LEVEL_UNDERSTANDING';
    g_ds_health_educ_level_und_ft  CONSTANT VARCHAR2(50 CHAR) := 'DS_HEALTH_EDUCATION_LEVEL_UNDERSTANDING_FT';

    g_ds_problems_addressed        CONSTANT VARCHAR2(50 CHAR) := 'DS_PROBLEM_ADDRESSED_MW';
    g_ds_diagnosis                 CONSTANT VARCHAR2(50 CHAR) := 'DS_DIAGNOSIS_MW';
    g_ds_onset                     CONSTANT VARCHAR2(50 CHAR) := 'DS_ONSET';
    g_ds_referral_reason           CONSTANT VARCHAR2(50 CHAR) := 'DS_REFERRAL_REASON';
    g_ds_notes                     CONSTANT VARCHAR2(50 CHAR) := 'DS_NOTES';
    g_ds_symptoms                  CONSTANT VARCHAR2(50 CHAR) := 'DS_SYMPTOMS';
    g_ds_course                    CONSTANT VARCHAR2(50 CHAR) := 'DS_COURSE';
    g_ds_medication                CONSTANT VARCHAR2(50 CHAR) := 'DS_MEDICATION';
    g_ds_vital_signs               CONSTANT VARCHAR2(50 CHAR) := 'DS_VITAL_SIGNS';
    g_ds_personal_history          CONSTANT VARCHAR2(50 CHAR) := 'DS_PERSONAL_HISTORY';
    g_ds_family_history            CONSTANT VARCHAR2(50 CHAR) := 'DS_FAMILY_HISTORY';
    g_ds_objective_examination_ft  CONSTANT VARCHAR2(50 CHAR) := 'DS_OBJECTIVE_EXAMINATION_FT';
    g_ds_executed_tests_ft         CONSTANT VARCHAR2(50 CHAR) := 'DS_EXECUTED_TESTS_FT';
    g_ds_referral_consent          CONSTANT VARCHAR2(50 CHAR) := 'DS_REFERRAL_CONSENT';
    g_ds_destination_facility      CONSTANT VARCHAR2(50 CHAR) := 'DS_DESTINATION_FACILITY';
    g_ds_quantity                  CONSTANT VARCHAR2(50 CHAR) := 'DS_QUANTITY';
    g_ds_laterality                CONSTANT VARCHAR2(50 CHAR) := 'DS_LATERALITY';
    g_ds_p1_home                   CONSTANT VARCHAR2(50 CHAR) := 'DS_P1_HOME';
    g_ds_clinical_service          CONSTANT VARCHAR2(50 CHAR) := 'DS_CLINICAL_SERVICE';
    g_ds_family_relationship       CONSTANT VARCHAR2(50 CHAR) := 'DS_FAMILY_RELATIONSHIP';
    g_ds_family_relationship_spec  CONSTANT VARCHAR2(50 CHAR) := 'DS_FAMILY_RELATIONSHIP_SPECIFY';
    g_ds_lastname                  CONSTANT VARCHAR2(50 CHAR) := 'DS_LASTNAME';
    g_ds_middlename                CONSTANT VARCHAR2(50 CHAR) := 'DS_MIDDLENAME';
    g_ds_nombres                   CONSTANT VARCHAR2(50 CHAR) := 'DS_NOMBRES';
    g_ds_physician_name            CONSTANT VARCHAR2(50 CHAR) := 'DS_PHYSICIAN_NAME';
    g_ds_physician_surname         CONSTANT VARCHAR2(50 CHAR) := 'DS_PHYSICIAN_SURNAME';
    g_ds_physician_phone           CONSTANT VARCHAR2(50 CHAR) := 'DS_PHYSICIAN_PHONE';
    g_ds_physician_license         CONSTANT VARCHAR2(50 CHAR) := 'DS_PHYSICIAN_LICENSE';
    g_ds_complementary_information CONSTANT VARCHAR2(50 CHAR) := 'DS_COMPLEMENTARY_INFORMATION';
    g_ds_additional_notes          CONSTANT VARCHAR2(50 CHAR) := 'DS_ADDITIONAL_NOTES';
    g_ds_supply_order_mw           CONSTANT VARCHAR2(50 CHAR) := 'DS_SUPPLY_ORDER_MW';
    g_ds_end_after_d               CONSTANT VARCHAR2(50 CHAR) := 'DS_END_AFTER_D';
    g_ds_patient_notes             CONSTANT VARCHAR2(50 CHAR) := 'DS_PATIENT_NOTES';

    g_ds_date_service             CONSTANT VARCHAR2(50 CHAR) := 'DS_DATE_SERVICE';
    g_ds_date_result              CONSTANT VARCHAR2(50 CHAR) := 'DS_DATE_RESULT';
    g_ds_result_origin            CONSTANT VARCHAR2(50 CHAR) := 'DS_RESULT_ORIGIN';
    g_ds_lab_results_node_control CONSTANT VARCHAR2(50 CHAR) := 'DS_LAB_RESULTS_NODE_CONTROL';
    g_ds_result_notes             CONSTANT VARCHAR2(50 CHAR) := 'DS_RESULT_NOTES';
    g_ds_place_service_ft         CONSTANT VARCHAR2(50 CHAR) := 'DS_PLACE_SERVICE_FT';
    g_ds_request_reason_other     CONSTANT VARCHAR2(50 CHAR) := 'DS_REQUEST_REASON_OTHER';
    g_ds_req_reason_no_permission CONSTANT VARCHAR2(50 CHAR) := 'DS_REQ_REASON_NO_PERMISSION';
    g_ds_follow_up_on             CONSTANT VARCHAR2(50 CHAR) := 'DS_FOLLOW_UP_ON';
    g_ds_follow_up_date           CONSTANT VARCHAR2(50 CHAR) := 'DS_FOLLOW_UP_DATE';
    g_ds_follow_up_n              CONSTANT VARCHAR2(50 CHAR) := 'DS_FOLLOW_UP_N';
    g_ds_release_from             CONSTANT VARCHAR2(50 CHAR) := 'DS_RELEASE_FROM';
    g_ds_care_instructions        CONSTANT VARCHAR2(50 CHAR) := 'DS_CARE_INSTRUCTIONS';
    g_ds_episode_due              CONSTANT VARCHAR2(50 CHAR) := 'DS_EPISODE_DUE';
    g_ds_patient_diagnosed        CONSTANT VARCHAR2(50 CHAR) := 'DS_PATIENT_DIAGNOSED';
    g_ds_restrict_activity        CONSTANT VARCHAR2(50 CHAR) := 'DS_RESTRICT_ACTIVITY';
    g_ds_from_date                CONSTANT VARCHAR2(50 CHAR) := 'DS_FROM_DATE';
    g_ds_follow_up_by             CONSTANT VARCHAR2(50 CHAR) := 'DS_FOLLOW_UP_BY';

    --Dynamic date fields for Ohter frequencies
    g_ds_exact_time    CONSTANT VARCHAR2(50 CHAR) := 'DS_EXACT_TIME';
    g_ds_exact_time_02 CONSTANT VARCHAR2(50 CHAR) := 'DS_EXACT_TIME_02';
    g_ds_exact_time_03 CONSTANT VARCHAR2(50 CHAR) := 'DS_EXACT_TIME_03';
    g_ds_exact_time_04 CONSTANT VARCHAR2(50 CHAR) := 'DS_EXACT_TIME_04';
    g_ds_exact_time_05 CONSTANT VARCHAR2(50 CHAR) := 'DS_EXACT_TIME_05';
    g_ds_exact_time_06 CONSTANT VARCHAR2(50 CHAR) := 'DS_EXACT_TIME_06';
    g_ds_exact_time_07 CONSTANT VARCHAR2(50 CHAR) := 'DS_EXACT_TIME_07';
    g_ds_exact_time_08 CONSTANT VARCHAR2(50 CHAR) := 'DS_EXACT_TIME_08';
    g_ds_exact_time_09 CONSTANT VARCHAR2(50 CHAR) := 'DS_EXACT_TIME_09';

    --Components for multiple selection (UX must explicit sent in a different array the values for these components)
    g_ds_clinical_indication_mw CONSTANT VARCHAR2(50 CHAR) := 'DS_CLINICAL_INDICATION_MW';
    g_ds_clinical_service_mm    CONSTANT VARCHAR2(50 CHAR) := 'DS_CLINICAL_SERVICE_MM';
    g_ds_order_set_type         CONSTANT VARCHAR2(50 CHAR) := 'DS_ORDER_SET_TYPE';
    g_ds_order_set_service      CONSTANT VARCHAR2(50 CHAR) := 'DS_ORDER_SET_SERVICE';
    g_ds_complaint_mw           CONSTANT VARCHAR2(50 CHAR) := 'DS_COMPLAINT_MW';
    g_ds_institution_mm         CONSTANT VARCHAR2(50 CHAR) := 'DS_INSTITUTION_MM';

    --Order set backoffice form
    g_ds_order_set_title               CONSTANT VARCHAR2(50 CHAR) := 'DS_ORDER_SET_TITLE';
    g_ds_order_set_author              CONSTANT VARCHAR2(50 CHAR) := 'DS_ORDER_SET_AUTHOR';
    g_ds_order_set_department          CONSTANT VARCHAR2(50 CHAR) := 'DS_ORDER_SET_DEPARTMENT';
    g_ds_order_set_user_permissions    CONSTANT VARCHAR2(50 CHAR) := 'DS_ORDER_SET_USER_PERMISSIONS';
    g_ds_order_set_editing_permissions CONSTANT VARCHAR2(50 CHAR) := 'DS_ORDER_SET_EDITING_PERMISSIONS';
    g_ds_frequency_n                   CONSTANT VARCHAR2(50 CHAR) := 'DS_FREQUENCY_N';
    g_ds_specialty_mm                  CONSTANT VARCHAR2(50 CHAR) := 'DS_SPECIALTY_MM';
    g_ds_vital_sign_list               CONSTANT VARCHAR2(50 CHAR) := 'DS_VITAL_SIGN_LIST';

    --Order set groups
    g_ds_order_set_group_name   CONSTANT VARCHAR2(50 CHAR) := 'DS_ORDER_SET_GROUP_NAME';
    g_ds_order_set_group_status CONSTANT VARCHAR2(50 CHAR) := 'DS_ORDER_SET_GROUP_STATUS';

    --MEMORY COMPONENTS (TO HOLD VALUES NOT SHOWN TO THE USER)
    g_ds_patient_id          CONSTANT VARCHAR2(50 CHAR) := 'DS_PATIENT_ID';
    g_ds_root_name           CONSTANT VARCHAR2(50 CHAR) := 'DS_ROOT_NAME';
    g_ds_tbl_records         CONSTANT VARCHAR2(50 CHAR) := 'DS_TBL_RECORDS';
    g_ds_ok_button_control   CONSTANT VARCHAR2(50 CHAR) := 'DS_OK_BUTTON_CONTROL';
    g_ds_tbl_mandatory_items CONSTANT VARCHAR2(50 CHAR) := 'DS_TBL_MANDATORY_ITEMS';
    g_ds_p1_origin_info      CONSTANT VARCHAR2(50 CHAR) := 'DS_P1_ORIGIN_INFO';
    g_ds_id_record           CONSTANT VARCHAR2(50 CHAR) := 'DS_ID_RECORD';
    g_ds_flg_edition         CONSTANT VARCHAR2(50 CHAR) := 'DS_FLG_EDITION';
    g_ds_flg_time            CONSTANT VARCHAR2(50 CHAR) := 'DS_FLG_TIME';
    g_ds_date_dummy          CONSTANT VARCHAR2(50 CHAR) := 'DS_DATE_DUMMY';
    g_ds_no_later_than       CONSTANT VARCHAR2(50 CHAR) := 'DS_NO_LATER_THAN';
    g_ds_next_episode_id     CONSTANT VARCHAR2(50 CHAR) := 'DS_NEXT_EPISODE_ID';
    g_ds_default_laterality  CONSTANT VARCHAR2(50 CHAR) := 'DS_DEFAULT_LATERALITY';
    g_ds_id_analysis         CONSTANT VARCHAR2(50 CHAR) := 'DS_ID_ANALYSIS';
    g_ds_id_sample_type      CONSTANT VARCHAR2(50 CHAR) := 'DS_ID_SAMPLE_TYPE';
    g_ds_id_supply           CONSTANT VARCHAR2(50 CHAR) := 'DS_ID_SUPPLY';
    g_ds_supply_set          CONSTANT VARCHAR2(50 CHAR) := 'DS_SUPPLY_SET';
    g_ds_supply_quantity     CONSTANT VARCHAR2(50 CHAR) := 'DS_SUPPLY_QUANTITY';
    g_ds_supply_dt_return    CONSTANT VARCHAR2(50 CHAR) := 'DS_SUPPLY_DT_RETURN';
    g_ds_supply_location     CONSTANT VARCHAR2(50 CHAR) := 'DS_SUPPLY_LOCATION';
    g_ds_has_catalogue       CONSTANT VARCHAR2(50 CHAR) := 'DS_HAS_CATALOGUE';
    g_ds_id_task_type        CONSTANT VARCHAR2(50 CHAR) := 'DS_ID_TASK_TYPE';
    g_ds_id_order_set_task   CONSTANT VARCHAR2(50 CHAR) := 'DS_ID_ORDER_SET_TASK';
    g_ds_id_advanced_input   CONSTANT VARCHAR2(50 CHAR) := 'DS_ID_ADVANCED_INPUT';
    g_ds_flg_female_exam     CONSTANT VARCHAR2(50 CHAR) := 'DS_FLG_FEMALE_EXAM';

    g_ds_p1_import_ids    CONSTANT VARCHAR2(50 CHAR) := 'DS_P1_IMPORT_IDS';
    g_ds_p1_import_values CONSTANT VARCHAR2(50 CHAR) := 'DS_P1_IMPORT_VALUES';

    /*DO NOT TOUCH - G_DS_P1_ALL_ITEMS_SELECTED used by UX layer*/
    g_ds_p1_all_items_selected CONSTANT VARCHAR2(50 CHAR) := 'DS_P1_ALL_ITEMS_SELECTED';
    --

    --Constants for the flg_validation response
    g_component_valid CONSTANT VARCHAR2(1 CHAR) := 'Y';
    g_component_error CONSTANT VARCHAR2(1 CHAR) := 'E';

    --Constants for the flg_event_type response
    g_component_mandatory CONSTANT VARCHAR2(1 CHAR) := 'M';
    g_component_inactive  CONSTANT VARCHAR2(1 CHAR) := 'I';
    g_component_active    CONSTANT VARCHAR2(1 CHAR) := 'A';
    g_component_read_only CONSTANT VARCHAR2(1 CHAR) := 'R';
    g_component_hidden    CONSTANT VARCHAR2(1 CHAR) := 'H';
    g_component_unique    CONSTANT VARCHAR2(1 CHAR) := 'U';

    --Form actions
    g_action_edition              CONSTANT NUMBER(24) := 2355256;
    g_action_edit_no_recurrence   CONSTANT NUMBER(24) := 2340163;
    g_action_edit_with_recurrence CONSTANT NUMBER(24) := 2340164;
    g_action_cq_edition           CONSTANT NUMBER(24) := 70;

END pk_orders_constant;
/
