/*-- Last Change Revision: $Rev: 2048233 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2022-10-24 11:04:51 +0100 (seg, 24 out 2022) $*/

CREATE OR REPLACE PACKAGE pk_exam_constant IS

    -- Global variables
    g_yes CONSTANT VARCHAR2(1 CHAR) := 'Y';
    g_no  CONSTANT VARCHAR2(1 CHAR) := 'N';

    g_active   CONSTANT VARCHAR2(1 CHAR) := 'A';
    g_inactive CONSTANT VARCHAR2(1 CHAR) := 'I';

    g_selected CONSTANT VARCHAR2(1 CHAR) := 'S';

    g_available CONSTANT VARCHAR2(1 CHAR) := 'Y';

    g_type_img CONSTANT VARCHAR2(1 CHAR) := 'I';
    g_type_exm CONSTANT VARCHAR2(1 CHAR) := 'E';

    g_episode_type_rad CONSTANT NUMBER := 13;
    g_episode_type_exm CONSTANT NUMBER := 21;
    g_episode_type_out CONSTANT NUMBER := 1;

    g_doc_area_exam          CONSTANT NUMBER := 1083;
    g_doc_area_exam_time_out CONSTANT NUMBER := 6715;
    g_doc_area_exam_result   CONSTANT NUMBER := 32380;

    g_waiting_technician CONSTANT VARCHAR2(1 CHAR) := 'G';
    g_in_technician      CONSTANT VARCHAR2(1 CHAR) := 'K';
    g_end_technician     CONSTANT VARCHAR2(1 CHAR) := 'F';

    g_flg_time_e CONSTANT VARCHAR2(1 CHAR) := 'E'; -- In this episode
    g_flg_time_b CONSTANT VARCHAR2(1 CHAR) := 'B'; -- Before next episode
    g_flg_time_n CONSTANT VARCHAR2(1 CHAR) := 'N'; -- Next episode
    g_flg_time_r CONSTANT VARCHAR2(1 CHAR) := 'R'; -- Brought by patient
    g_flg_time_d CONSTANT VARCHAR2(1 CHAR) := 'D'; -- On a defined or to be defined date

    g_exam_stat   CONSTANT exam_req.priority%TYPE := 'E';
    g_exam_urgent CONSTANT exam_req.priority%TYPE := 'U';
    g_exam_normal CONSTANT exam_req.priority%TYPE := 'N';

    -- exam_req_det.flg_status
    g_exam_predefined         CONSTANT exam_req_det.flg_status%TYPE := 'PD';
    g_exam_draft              CONSTANT exam_req_det.flg_status%TYPE := 'DF';
    g_exam_sos                CONSTANT exam_req_det.flg_status%TYPE := 'S';
    g_exam_exterior           CONSTANT exam_req_det.flg_status%TYPE := 'X';
    g_exam_tosched            CONSTANT exam_req_det.flg_status%TYPE := 'PA';
    g_exam_sched              CONSTANT exam_req_det.flg_status%TYPE := 'A';
    g_exam_efectiv            CONSTANT exam_req_det.flg_status%TYPE := 'EF';
    g_exam_nr                 CONSTANT exam_req_det.flg_status%TYPE := 'NR';
    g_exam_pending            CONSTANT exam_req_det.flg_status%TYPE := 'D';
    g_exam_req                CONSTANT exam_req_det.flg_status%TYPE := 'R';
    g_exam_ongoing            CONSTANT exam_req.flg_status%TYPE := 'E';
    g_exam_cancel             CONSTANT exam_req_det.flg_status%TYPE := 'C';
    g_exam_toexec             CONSTANT exam_req_det.flg_status%TYPE := 'E';
    g_exam_exec               CONSTANT exam_req_det.flg_status%TYPE := 'EX';
    g_exam_partial            CONSTANT exam_req.flg_status%TYPE := 'P';
    g_exam_result_partial     CONSTANT result_status.value%TYPE := 'S';
    g_exam_result_preliminary CONSTANT result_status.value%TYPE := 'P';
    g_exam_result             CONSTANT exam_req_det.flg_status%TYPE := 'F';
    g_exam_read_partial       CONSTANT exam_req.flg_status%TYPE := 'LP';
    g_exam_read               CONSTANT exam_req_det.flg_status%TYPE := 'L';
    g_exam_transp             CONSTANT exam_req_det.flg_status%TYPE := 'T';
    g_exam_end_transp         CONSTANT exam_req_det.flg_status%TYPE := 'M';
    g_exam_wtg_tde            CONSTANT exam_req_det.flg_status%TYPE := 'W';

    g_flg_referral_r CONSTANT exam_req_det.flg_referral%TYPE := 'R';
    g_flg_referral_s CONSTANT exam_req_det.flg_referral%TYPE := 'S';
    g_flg_referral_i CONSTANT exam_req_det.flg_referral%TYPE := 'I';

    g_exam_location_interior CONSTANT exam_req_det.flg_location%TYPE := 'I';
    g_exam_location_exterior CONSTANT exam_req_det.flg_location%TYPE := 'E';

    g_exam_cq_on_order       CONSTANT exam_questionnaire.flg_time%TYPE := 'O';
    g_exam_cq_before_execute CONSTANT exam_questionnaire.flg_time%TYPE := 'BE';
    g_exam_cq_after_execute  CONSTANT exam_questionnaire.flg_time%TYPE := 'AE';

    -- exam_dep_clin_serv.flg_type
    g_exam_can_req         CONSTANT exam_dep_clin_serv.flg_type%TYPE := 'P';
    g_exam_freq            CONSTANT exam_dep_clin_serv.flg_type%TYPE := 'M';
    g_exam_history         CONSTANT exam_dep_clin_serv.flg_type%TYPE := 'H';
    g_past_hist_freq_treat CONSTANT exam_dep_clin_serv.flg_type%TYPE := 'A';
    g_past_hist_treat      CONSTANT exam_dep_clin_serv.flg_type%TYPE := 'B';

    g_exam_institution      CONSTANT VARCHAR2(1 CHAR) := 'I';
    g_exam_clinical_service CONSTANT VARCHAR2(1 CHAR) := 'M';
    g_exam_complaint        CONSTANT VARCHAR2(1 CHAR) := 'C';
    g_exam_codification     CONSTANT VARCHAR2(2 CHAR) := 'CD';

    g_exam_type_req CONSTANT ti_log.flg_type%TYPE := 'ER';
    g_exam_type_det CONSTANT ti_log.flg_type%TYPE := 'ED';

    g_exam_result_origin CONSTANT VARCHAR2(1 CHAR) := 'I';

    g_exam_result_url CONSTANT VARCHAR2(1 CHAR) := 'I';
    g_exam_result_pdf CONSTANT VARCHAR2(1 CHAR) := 'R';

    g_exam_result_cancel VARCHAR2(1 CHAR) := 'C'; --Canceled
    g_exam_result_active VARCHAR2(1 CHAR) := 'A'; --Active

    g_media_archive_exam_result CONSTANT VARCHAR2(1 CHAR) := 'R';
    g_media_archive_exam_doc    CONSTANT VARCHAR2(1 CHAR) := 'D';

    g_exam_area_exams   CONSTANT VARCHAR2(5 CHAR) := 'EXAMS';
    g_exam_area_orders  CONSTANT VARCHAR2(6 CHAR) := 'ORDERS';
    g_exam_area_results CONSTANT VARCHAR2(7 CHAR) := 'RESULTS';
    g_exam_area_perform CONSTANT VARCHAR2(7 CHAR) := 'PERFORM';

    g_exam_button_ok           CONSTANT VARCHAR2(2 CHAR) := 'OK';
    g_exam_button_cancel       CONSTANT VARCHAR2(6 CHAR) := 'CANCEL';
    g_exam_button_action       CONSTANT VARCHAR2(6 CHAR) := 'ACTION';
    g_exam_button_edit         CONSTANT VARCHAR2(4 CHAR) := 'EDIT';
    g_exam_button_confirmation CONSTANT VARCHAR2(12 CHAR) := 'CONFIRMATION';
    g_exam_button_read         CONSTANT VARCHAR2(4 CHAR) := 'READ';
    g_exam_button_detail       CONSTANT VARCHAR2(6 CHAR) := 'DETAIL';

    g_cancel_permissions_img CONSTANT table_number := table_number(59, 142, 4036);
    g_cancel_permissions_exm CONSTANT table_number := table_number(58, 163, 4035);

    g_flg_origin_module_o CONSTANT VARCHAR2(1 CHAR) := 'O';

    --Constants for exams aggregation criteria on the reports
    g_group_by_requisition            CONSTANT VARCHAR2(1 CHAR) := 'R';
    g_group_by_clin_indication        CONSTANT VARCHAR2(1 CHAR) := 'C';
    g_group_by_instructions           CONSTANT VARCHAR2(1 CHAR) := 'I';
    g_group_by_patient_instructions   CONSTANT VARCHAR2(1 CHAR) := 'P';
    g_group_by_execution_instructions CONSTANT VARCHAR2(1 CHAR) := 'E';
    g_group_by_health_plan            CONSTANT VARCHAR2(1 CHAR) := 'H';

    TYPE t_tbl_code_messages IS TABLE OF VARCHAR2(1000 CHAR) INDEX BY sys_message.code_message%TYPE;

    --SYS_MESSAGE ARRAY FOR DETAILS AND HISTORY
    ga_code_messages_exam_detail CONSTANT table_varchar := table_varchar('EXAMS_T037',
                                                                         'EXAMS_T138',
                                                                         'EXAMS_T046',
                                                                         'EXAMS_T047',
                                                                         'EXAMS_T054',
                                                                         'EXAMS_T223',
                                                                         'EXAMS_T016',
                                                                         'EXAMS_T033',
                                                                         'EXAMS_T035',
                                                                         'EXAMS_T139',
                                                                         'EXAMS_T141',
                                                                         'EXAMS_T034',
                                                                         'EXAMS_T174',
                                                                         'EXAMS_T159',
                                                                         'EXAMS_T164',
                                                                         'EXAMS_T165',
                                                                         'EXAMS_T166',
                                                                         'EXAMS_T167',
                                                                         'EXAMS_T020',
                                                                         'EXAMS_T176',
                                                                         'EXAMS_T053',
                                                                         'EXAMS_T258',
                                                                         'EXAMS_T059',
                                                                         'EXAMS_T019',
                                                                         'EXAMS_T168',
                                                                         'EXAMS_T169',
                                                                         'EXAMS_T170',
                                                                         'EXAMS_T171',
                                                                         'EXAMS_T246',
                                                                         'EXAMS_T172',
                                                                         'EXAMS_T031',
                                                                         'EXAMS_T058',
                                                                         'EXAMS_T126',
                                                                         'EXAMS_T251',
                                                                         'EXAMS_T009',
                                                                         'EXAMS_T256',
                                                                         'EXAMS_T025',
                                                                         'EXAMS_T077',
                                                                         'EXAMS_T078',
                                                                         'EXAMS_T079',
                                                                         'EXAMS_T098',
                                                                         'EXAMS_T099',
                                                                         'EXAMS_T095',
                                                                         'EXAMS_T094',
                                                                         'EXAMS_T255',
                                                                         'EXAMS_T090',
                                                                         'EXAMS_T097',
                                                                         'EXAMS_T096',
                                                                         'EXAMS_T091',
                                                                         'EXAMS_T100',
                                                                         'EXAMS_T130',
                                                                         'EXAMS_T242',
                                                                         'EXAMS_T265',
                                                                         'EXAMS_T226',
                                                                         'EXAMS_T228',
                                                                         'EXAMS_T253',
                                                                         'EXAMS_T268',
                                                                         'COMMON_M035',
                                                                         'COMMON_T062',
                                                                         'EXAMS_T224');
    --SYS_MESSAGE ARRAYS FOR THE HISTORY DETAILS WITH 'UPDATED' TAG
    ga_code_messages_exam_detail_upd CONSTANT table_varchar := table_varchar('EXAMS_T266',
                                                                             'EXAMS_T259',
                                                                             'EXAMS_T177',
                                                                             'EXAMS_T178',
                                                                             'EXAMS_T179',
                                                                             'EXAMS_T185',
                                                                             'EXAMS_T187',
                                                                             'EXAMS_T188',
                                                                             'EXAMS_T189',
                                                                             'EXAMS_T190',
                                                                             'EXAMS_T191',
                                                                             'EXAMS_T192',
                                                                             'EXAMS_T194',
                                                                             'EXAMS_T195',
                                                                             'EXAMS_T196',
                                                                             'EXAMS_T203',
                                                                             'EXAMS_T204',
                                                                             'EXAMS_T205',
                                                                             'EXAMS_T206',
                                                                             'EXAMS_T207',
                                                                             'EXAMS_T208',
                                                                             'EXAMS_T209',
                                                                             'EXAMS_T186',
                                                                             'EXAMS_T193',
                                                                             'EXAMS_T210',
                                                                             'EXAMS_T210',
                                                                             'EXAMS_T211',
                                                                             'EXAMS_T212',
                                                                             'EXAMS_T213',
                                                                             'EXAMS_T214',
                                                                             'EXAMS_T215',
                                                                             'EXAMS_T216',
                                                                             'EXAMS_T217',
                                                                             'EXAMS_T222',
                                                                             'EXAMS_T229',
                                                                             'EXAMS_T230',
                                                                             'EXAMS_T235',
                                                                             'EXAMS_T247',
                                                                             'EXAMS_T243',
                                                                             'COMMON_T061',
                                                                             'COMMON_M161',
                                                                             'COMMON_M044');

END pk_exam_constant;
/
