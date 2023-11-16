/*-- Last Change Revision: $Rev: 2048233 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2022-10-24 11:04:51 +0100 (seg, 24 out 2022) $*/

CREATE OR REPLACE PACKAGE pk_lab_tests_constant IS

    -- Global Variables
    g_yes CONSTANT VARCHAR2(1 CHAR) := 'Y';
    g_no  CONSTANT VARCHAR2(1 CHAR) := 'N';

    g_active   CONSTANT VARCHAR2(1 CHAR) := 'A';
    g_inactive CONSTANT VARCHAR2(1 CHAR) := 'I';

    g_selected CONSTANT VARCHAR2(1 CHAR) := 'S';

    g_available CONSTANT VARCHAR2(1 CHAR) := 'Y';

    g_episode_type_lab CONSTANT NUMBER := 12;

    g_analysis CONSTANT VARCHAR2(1 CHAR) := 'A';

    g_flg_time_e CONSTANT VARCHAR2(1 CHAR) := 'E'; -- In this episode
    g_flg_time_b CONSTANT VARCHAR2(1 CHAR) := 'B'; -- Before next episode
    g_flg_time_n CONSTANT VARCHAR2(1 CHAR) := 'N'; -- Next episode
    g_flg_time_r CONSTANT VARCHAR2(1 CHAR) := 'R'; -- Brought by patient
    g_flg_time_d CONSTANT VARCHAR2(1 CHAR) := 'D'; -- On a defined or to be defined date

    g_analysis_sample_type_alias CONSTANT VARCHAR2(2 CHAR) := 'AS';
    g_analysis_alias             CONSTANT VARCHAR2(1 CHAR) := 'A';
    g_analysis_group_alias       CONSTANT VARCHAR2(1 CHAR) := 'G';
    g_analysis_parameter_alias   CONSTANT VARCHAR2(1 CHAR) := 'P';
    g_analysis_sample_alias      CONSTANT VARCHAR2(1 CHAR) := 'S';

    g_analysis_stat   CONSTANT analysis_req_det.flg_urgency%TYPE := 'E';
    g_analysis_urgent CONSTANT analysis_req_det.flg_urgency%TYPE := 'U';
    g_analysis_normal CONSTANT analysis_req_det.flg_urgency%TYPE := 'N';

    g_analysis_predefined         CONSTANT analysis_req_det.flg_status%TYPE := 'PD';
    g_analysis_draft              CONSTANT analysis_req_det.flg_status%TYPE := 'DF';
    g_analysis_sos                CONSTANT analysis_req_det.flg_status%TYPE := 'S';
    g_analysis_wtg_tde            CONSTANT analysis_req_det.flg_status%TYPE := 'W';
    g_analysis_exterior           CONSTANT analysis_req_det.flg_status%TYPE := 'X';
    g_analysis_tosched            CONSTANT analysis_req_det.flg_status%TYPE := 'PA';
    g_analysis_sched              CONSTANT analysis_req_det.flg_status%TYPE := 'A';
    g_analysis_efectiv            CONSTANT analysis_req_det.flg_status%TYPE := 'EF';
    g_analysis_nr                 CONSTANT analysis_req_det.flg_status%TYPE := 'NR';
    g_analysis_pending            CONSTANT analysis_req_det.flg_status%TYPE := 'D';
    g_analysis_review             CONSTANT analysis_req_det.flg_status%TYPE := 'V';
    g_analysis_req                CONSTANT analysis_req_det.flg_status%TYPE := 'R';
    g_analysis_ongoing            CONSTANT analysis_req.flg_status%TYPE := 'E';
    g_analysis_oncollection       CONSTANT analysis_req_det.flg_status%TYPE := 'CC';
    g_analysis_toexec             CONSTANT analysis_req_det.flg_status%TYPE := 'E';
    g_analysis_transport          CONSTANT analysis_req_det.flg_status%TYPE := 'T';
    g_analysis_collected          CONSTANT analysis_req_det.flg_status%TYPE := 'H';
    g_analysis_partial            CONSTANT analysis_req.flg_status%TYPE := 'P';
    g_analysis_result_partial     CONSTANT result_status.value%TYPE := 'S';
    g_analysis_result_preliminary CONSTANT result_status.value%TYPE := 'P';
    g_analysis_result             CONSTANT analysis_req_det.flg_status%TYPE := 'F';
    g_analysis_read_partial       CONSTANT analysis_req.flg_status%TYPE := 'LP';
    g_analysis_read               CONSTANT analysis_req_det.flg_status%TYPE := 'L';
    g_analysis_cancel             CONSTANT analysis_req_det.flg_status%TYPE := 'C';

    g_flg_referral_a CONSTANT analysis_req_det.flg_referral%TYPE := 'A'; -- Available
    g_flg_referral_r CONSTANT analysis_req_det.flg_referral%TYPE := 'R'; -- Reserved
    g_flg_referral_s CONSTANT analysis_req_det.flg_referral%TYPE := 'S'; -- Printed
    g_flg_referral_i CONSTANT analysis_req_det.flg_referral%TYPE := 'I'; -- Electronically Sent 

    g_cosign_type_labtest CONSTANT co_sign_task.flg_type%TYPE := 'A';

    g_anr_session      CONSTANT notes_config.notes_code%TYPE := 'ANR';
    g_analysis_session CONSTANT notes_config.notes_code%TYPE := 'ANL';

    g_analysis_cq_on_order   CONSTANT analysis_questionnaire.flg_time%TYPE := 'O';
    g_analysis_cq_on_harvest CONSTANT analysis_questionnaire.flg_time%TYPE := 'C';

    g_aharvest_combined CONSTANT analysis_harv_comb_div.flg_comb_div%TYPE := 'C';
    g_aharvest_divided  CONSTANT analysis_harv_comb_div.flg_comb_div%TYPE := 'D';

    g_harvest_inactive  CONSTANT harvest.flg_status%TYPE := 'I'; --Inactive, was divided or combined
    g_harvest_pending   CONSTANT harvest.flg_status%TYPE := 'P';
    g_harvest_waiting   CONSTANT harvest.flg_status%TYPE := 'W';
    g_harvest_collected CONSTANT harvest.flg_status%TYPE := 'H';
    g_harvest_transp    CONSTANT harvest.flg_status%TYPE := 'T';
    g_harvest_finished  CONSTANT harvest.flg_status%TYPE := 'F';
    g_harvest_cancel    CONSTANT harvest.flg_status%TYPE := 'C';
    g_harvest_rejected  CONSTANT harvest.flg_status%TYPE := 'J';
    g_harvest_suspended CONSTANT harvest.flg_status%TYPE := 'S'; --Suspended 
    g_harvest_repeated  CONSTANT harvest.flg_status%TYPE := 'R'; --Repeated, this harvest was repeated

    g_harvest_orig_harvest_a CONSTANT harvest.flg_orig_harvest%TYPE := 'A'; -- harvest origin from ALERT App
    g_harvest_orig_harvest_i CONSTANT harvest.flg_orig_harvest%TYPE := 'I'; -- harvest origin from Interfaces

    g_arm_flg_type_room_pat  CONSTANT analysis_room.flg_type%TYPE := 'M'; -- Room where the lab tests is collected
    g_arm_flg_type_room_tube CONSTANT analysis_room.flg_type%TYPE := 'T'; -- Room where the lab tests tube is taken to be executed

    g_analysis_result_origin_a CONSTANT VARCHAR2(1 CHAR) := 'A'; -- Result origin from ALERT App
    g_analysis_result_origin_i CONSTANT VARCHAR2(1 CHAR) := 'I'; -- Result origin from Interfaces

    g_analysis_result_above CONSTANT VARCHAR2(1 CHAR) := 'U';
    g_analysis_result_below CONSTANT VARCHAR2(1 CHAR) := 'D';

    g_analysis_result_number CONSTANT VARCHAR2(1 CHAR) := 'N';
    g_analysis_result_text   CONSTANT VARCHAR2(1 CHAR) := 'T';
    g_analysis_result_icon   CONSTANT VARCHAR2(1 CHAR) := 'I';

    g_analysis_result_url CONSTANT VARCHAR2(1 CHAR) := 'I';
    g_analysis_result_pdf CONSTANT VARCHAR2(1 CHAR) := 'R';

    -- analysis_param_funcionality
    g_apf_type_history         CONSTANT analysis_param_funcionality.flg_type%TYPE := 'S';
    g_apf_type_maternal_health CONSTANT analysis_param_funcionality.flg_type%TYPE := 'M';

    -- analysis_instit_soft
    g_analysis_can_req CONSTANT analysis_instit_soft.flg_type%TYPE := 'P';
    g_analysis_freq    CONSTANT analysis_instit_soft.flg_type%TYPE := 'M';
    g_analysis_exec    CONSTANT analysis_instit_soft.flg_type%TYPE := 'W';

    g_analysis_institution      CONSTANT VARCHAR2(1 CHAR) := 'I';
    g_analysis_clinical_service CONSTANT VARCHAR2(1 CHAR) := 'M';
    g_analysis_complaint        CONSTANT VARCHAR2(1 CHAR) := 'C';
    g_analysis_codification     CONSTANT VARCHAR2(2 CHAR) := 'CD';

    -- ti_log
    g_analysis_type_req  CONSTANT ti_log.flg_type%TYPE := 'AR';
    g_analysis_type_det  CONSTANT ti_log.flg_type%TYPE := 'AD';
    g_analysis_type_harv CONSTANT ti_log.flg_type%TYPE := 'AH';

    g_media_archive_analysis_doc CONSTANT VARCHAR2(1 CHAR) := 'D';
    g_media_archive_analysis_res CONSTANT VARCHAR2(1 CHAR) := 'R';

    g_analysis_area_lab_tests CONSTANT VARCHAR2(9 CHAR) := 'LAB_TESTS';
    g_analysis_area_orders    CONSTANT VARCHAR2(6 CHAR) := 'ORDERS';
    g_analysis_area_results   CONSTANT VARCHAR2(7 CHAR) := 'RESULTS';

    g_analysis_button_create       CONSTANT VARCHAR2(6 CHAR) := 'CREATE';
    g_analysis_button_ok           CONSTANT VARCHAR2(2 CHAR) := 'OK';
    g_analysis_button_cancel       CONSTANT VARCHAR2(6 CHAR) := 'CANCEL';
    g_analysis_button_action       CONSTANT VARCHAR2(6 CHAR) := 'ACTION';
    g_analysis_button_edit         CONSTANT VARCHAR2(6 CHAR) := 'EDIT';
    g_analysis_button_confirmation CONSTANT VARCHAR2(12 CHAR) := 'CONFIRMATION';
    g_analysis_button_read         CONSTANT VARCHAR2(4 CHAR) := 'READ';
    g_analysis_button_detail       CONSTANT VARCHAR2(6 CHAR) := 'DETAIL';

    g_analysis_unit_measure CONSTANT unit_measure.id_unit_measure_type%TYPE := 1016;

    g_format_mask CONSTANT VARCHAR2(17 CHAR) := '9999999999990D999';

    g_analysis_formula_gfr CONSTANT analysis_res_calculator.id_analysis_res_calc%TYPE := 1;
    g_analysis_formula_ccc CONSTANT analysis_res_calculator.id_analysis_res_calc%TYPE := 2;
    g_analysis_formula_osm CONSTANT analysis_res_calculator.id_analysis_res_calc%TYPE := 3;
    g_analysis_formula_ccr CONSTANT analysis_res_calculator.id_analysis_res_calc%TYPE := 4;

    --flg_type for laboratory tests of infectious diseases in group_access
    g_infectious_diseases_orders  CONSTANT group_access.flg_type%TYPE := 'IO';
    g_infectious_diseases_results CONSTANT group_access.flg_type%TYPE := 'IR';

    --Constants for lab tests aggregation criteria on the reports
    g_group_by_requisition            CONSTANT VARCHAR2(1 CHAR) := 'R';
    g_group_by_clin_indication        CONSTANT VARCHAR2(1 CHAR) := 'C';
    g_group_by_instructions           CONSTANT VARCHAR2(1 CHAR) := 'I';
    g_group_by_patient_instructions   CONSTANT VARCHAR2(1 CHAR) := 'P';
    g_group_by_execution_instructions CONSTANT VARCHAR2(1 CHAR) := 'E';
    g_group_by_health_plan            CONSTANT VARCHAR2(1 CHAR) := 'H';

    --Array of messages to be used on the details
    ga_code_messages_lab_test_detail CONSTANT table_varchar := table_varchar('LAB_TESTS_T045',
                                                                             'LAB_TESTS_T210',
                                                                             'LAB_TESTS_T046',
                                                                             'LAB_TESTS_T014',
                                                                             'LAB_TESTS_T012',
                                                                             'LAB_TESTS_T013',
                                                                             'LAB_TESTS_T003',
                                                                             'LAB_TESTS_T048',
                                                                             'LAB_TESTS_T047',
                                                                             'LAB_TESTS_T049',
                                                                             'LAB_TESTS_T050',
                                                                             'LAB_TESTS_T043',
                                                                             'LAB_TESTS_T017',
                                                                             'LAB_TESTS_T168',
                                                                             'LAB_TESTS_T022',
                                                                             'LAB_TESTS_T023',
                                                                             'LAB_TESTS_T024',
                                                                             'LAB_TESTS_T025',
                                                                             'LAB_TESTS_T026',
                                                                             'LAB_TESTS_T027',
                                                                             'LAB_TESTS_T028',
                                                                             'LAB_TESTS_T030',
                                                                             'LAB_TESTS_T229',
                                                                             'LAB_TESTS_T031',
                                                                             'LAB_TESTS_T033',
                                                                             'LAB_TESTS_T032',
                                                                             'LAB_TESTS_T199',
                                                                             'LAB_TESTS_T200',
                                                                             'LAB_TESTS_T201',
                                                                             'LAB_TESTS_T038',
                                                                             'LAB_TESTS_T035',
                                                                             'LAB_TESTS_T036',
                                                                             'LAB_TESTS_T037',
                                                                             'LAB_TESTS_T185',
                                                                             'LAB_TESTS_T227',
                                                                             'LAB_TESTS_T053',
                                                                             'LAB_TESTS_T054',
                                                                             'LAB_TESTS_T055',
                                                                             'LAB_TESTS_T228',
                                                                             'LAB_TESTS_T034',
                                                                             'LAB_TESTS_T061',
                                                                             'LAB_TESTS_T062',
                                                                             'LAB_TESTS_T063',
                                                                             'LAB_TESTS_T174',
                                                                             'LAB_TESTS_T192',
                                                                             'LAB_TESTS_T194',
                                                                             'LAB_TESTS_T056',
                                                                             'LAB_TESTS_T057',
                                                                             'LAB_TESTS_T058',
                                                                             'LAB_TESTS_T059',
                                                                             'LAB_TESTS_T205',
                                                                             'LAB_TESTS_T187',
                                                                             'LAB_TESTS_T060',
                                                                             'LAB_TESTS_T195',
                                                                             'LAB_TESTS_T198',
                                                                             'LAB_TESTS_T064',
                                                                             'LAB_TESTS_T132',
                                                                             'LAB_TESTS_T234',
                                                                             'LAB_TESTS_T066',
                                                                             'LAB_TESTS_T070',
                                                                             'LAB_TESTS_T149',
                                                                             'LAB_TESTS_T073',
                                                                             'LAB_TESTS_T071',
                                                                             'LAB_TESTS_T214',
                                                                             'LAB_TESTS_T215',
                                                                             'LAB_TESTS_T216',
                                                                             'LAB_TESTS_T217',
                                                                             'LAB_TESTS_T224',
                                                                             'LAB_TESTS_T218',
                                                                             'LAB_TESTS_T219',
                                                                             'LAB_TESTS_T220',
                                                                             'LAB_TESTS_T065',
                                                                             'LAB_TESTS_T237',
                                                                             'LAB_TESTS_T238',
                                                                             'COMMON_M035',
                                                                             'LAB_TESTS_T241',
                                                                             'COMMON_T062');

END pk_lab_tests_constant;
/
