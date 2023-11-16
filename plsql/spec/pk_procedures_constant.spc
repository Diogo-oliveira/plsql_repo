/*-- Last Change Revision: $Rev: 2048233 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2022-10-24 11:04:51 +0100 (seg, 24 out 2022) $*/

CREATE OR REPLACE PACKAGE pk_procedures_constant IS

    -- Global variables
    g_yes CONSTANT VARCHAR2(1 CHAR) := 'Y';
    g_no  CONSTANT VARCHAR2(1 CHAR) := 'N';

    g_active   CONSTANT VARCHAR2(1 CHAR) := 'A';
    g_inactive CONSTANT VARCHAR2(1 CHAR) := 'I';

    g_selected CONSTANT VARCHAR2(1 CHAR) := 'S';

    g_available CONSTANT VARCHAR2(1 CHAR) := 'Y';

    g_type_interv          CONSTANT VARCHAR2(1 CHAR) := 'P';
    g_type_interv_surgical CONSTANT VARCHAR2(1 CHAR) := 'S';
    g_type_interv_rehab    CONSTANT VARCHAR2(1 CHAR) := 'R';

    g_episode_type_interv CONSTANT NUMBER := 24;

    g_doc_area_intervention    CONSTANT NUMBER := 1082;
    g_doc_area_interv_time_out CONSTANT NUMBER := 1082;

    g_flg_time_e CONSTANT VARCHAR2(1 CHAR) := 'E'; -- In this episode
    g_flg_time_b CONSTANT VARCHAR2(1 CHAR) := 'B'; -- Between episodes
    g_flg_time_n CONSTANT VARCHAR2(1 CHAR) := 'N'; -- Next episode
    g_flg_time_r CONSTANT VARCHAR2(1 CHAR) := 'R'; -- Brought by patient
    g_flg_time_a CONSTANT VARCHAR2(1 CHAR) := 'A'; -- Across care settings
    g_flg_time_h CONSTANT VARCHAR2(1 CHAR) := 'H'; -- Home health care

    g_interv_stat   CONSTANT interv_presc_det.flg_prty%TYPE := 'E';
    g_interv_urgent CONSTANT interv_presc_det.flg_prty%TYPE := 'U';
    g_interv_normal CONSTANT interv_presc_det.flg_prty%TYPE := 'N';

    -- interv_req_det.flg_status
    g_interv_predefined  CONSTANT VARCHAR(2 CHAR) := 'PD';
    g_interv_draft       CONSTANT interv_presc_det.flg_status%TYPE := 'Z'; --'DF';
    g_interv_sos         CONSTANT interv_presc_det.flg_status%TYPE := 'S';
    g_interv_exterior    CONSTANT interv_presc_det.flg_status%TYPE := 'X';
    g_interv_tosched     CONSTANT VARCHAR(2 CHAR) := 'PA';
    g_interv_sched       CONSTANT interv_presc_det.flg_status%TYPE := 'A';
    g_interv_efectiv     CONSTANT VARCHAR(2 CHAR) := 'EF';
    g_interv_nr          CONSTANT VARCHAR(2 CHAR) := 'NR';
    g_interv_pending     CONSTANT interv_presc_det.flg_status%TYPE := 'D';
    g_interv_req         CONSTANT interv_presc_det.flg_status%TYPE := 'R';
    g_interv_cancel      CONSTANT interv_presc_det.flg_status%TYPE := 'C';
    g_interv_exec        CONSTANT interv_presc_det.flg_status%TYPE := 'E';
    g_interv_partial     CONSTANT interv_presc_det.flg_status%TYPE := 'P';
    g_interv_finished    CONSTANT interv_presc_det.flg_status%TYPE := 'F';
    g_interv_not_ordered CONSTANT interv_presc_det.flg_status%TYPE := 'N'; -- 'NO'
    g_interv_expired     CONSTANT interv_presc_det.flg_status%TYPE := 'O'; -- 'EP'
    g_interv_interrupted CONSTANT interv_presc_det.flg_status%TYPE := 'I';
    g_interv_wtg_tde     CONSTANT interv_presc_det.flg_status%TYPE := 'W';

    g_interv_plan_req          CONSTANT interv_presc_plan.flg_status%TYPE := 'R';
    g_interv_plan_pending      CONSTANT interv_presc_plan.flg_status%TYPE := 'D';
    g_interv_plan_executed     CONSTANT interv_presc_plan.flg_status%TYPE := 'A';
    g_interv_plan_not_executed CONSTANT interv_presc_plan.flg_status%TYPE := 'N';
    g_interv_plan_expired      CONSTANT interv_presc_plan.flg_status%TYPE := 'O';
    g_interv_plan_cancel       CONSTANT interv_presc_plan.flg_status%TYPE := 'C';

    g_flg_referral_a CONSTANT interv_presc_det.flg_referral%TYPE := 'A';
    g_flg_referral_r CONSTANT interv_presc_det.flg_referral%TYPE := 'R';
    g_flg_referral_s CONSTANT interv_presc_det.flg_referral%TYPE := 'S';
    g_flg_referral_i CONSTANT interv_presc_det.flg_referral%TYPE := 'I';

    g_interv_cq_on_order       CONSTANT interv_questionnaire.flg_time%TYPE := 'O';
    g_interv_cq_before_execute CONSTANT interv_questionnaire.flg_time%TYPE := 'BE';
    g_interv_cq_after_execute  CONSTANT interv_questionnaire.flg_time%TYPE := 'AE';

    -- interv_dep_clin_serv.flg_type
    g_interv_can_req CONSTANT interv_dep_clin_serv.flg_type%TYPE := 'P';
    g_interv_freq    CONSTANT interv_dep_clin_serv.flg_type%TYPE := 'M';
    g_interv_execute CONSTANT interv_dep_clin_serv.flg_type%TYPE := 'R';

    g_interv_institution      CONSTANT VARCHAR2(1 CHAR) := 'I';
    g_interv_clinical_service CONSTANT VARCHAR2(1 CHAR) := 'S';
    g_interv_medical          CONSTANT VARCHAR2(1 CHAR) := 'D';
    g_interv_nursing          CONSTANT VARCHAR2(1 CHAR) := 'N';
    g_interv_complaint        CONSTANT VARCHAR2(1 CHAR) := 'C';
    g_interv_codification     CONSTANT VARCHAR2(2 CHAR) := 'CD';

    g_id_location_hhc  CONSTANT NUMBER(24) := -100;
    g_flg_location_hhc CONSTANT VARCHAR2(3 CHAR) := 'HHC';

    g_interv_type_req CONSTANT ti_log.flg_type%TYPE := 'PR';

    g_interv_planned_date CONSTANT sys_domain.code_domain%TYPE := 'PLANNED_DATE';
    g_interv_system_date  CONSTANT sys_domain.code_domain%TYPE := 'SYSTEM_DATE';

    g_media_archive_interv_exec CONSTANT VARCHAR2(1 CHAR) := 'E';
    g_media_archive_interv_doc  CONSTANT VARCHAR2(1 CHAR) := 'D';

    g_interv_area_procedures CONSTANT VARCHAR2(10 CHAR) := 'PROCEDURES';
    g_interv_area_execution  CONSTANT VARCHAR2(9 CHAR) := 'EXECUTION';

    g_interv_button_create       CONSTANT VARCHAR2(6 CHAR) := 'CREATE';
    g_interv_button_ok           CONSTANT VARCHAR2(2 CHAR) := 'OK';
    g_interv_button_cancel       CONSTANT VARCHAR2(6 CHAR) := 'CANCEL';
    g_interv_button_action       CONSTANT VARCHAR2(6 CHAR) := 'ACTION';
    g_interv_button_edit         CONSTANT VARCHAR2(4 CHAR) := 'EDIT';
    g_interv_button_confirmation CONSTANT VARCHAR2(12 CHAR) := 'CONFIRMATION';

    g_flg_origin_module_o CONSTANT VARCHAR2(1 CHAR) := 'O';

    TYPE t_code_messages IS TABLE OF VARCHAR2(1000 CHAR) INDEX BY sys_message.code_message%TYPE;

    ga_code_messages_procedure_detail CONSTANT table_varchar := table_varchar('PROCEDURES_T096',
                                                                              'PROCEDURES_T058',
                                                                              'PROCEDURES_T081',
                                                                              'PROCEDURES_T104',
                                                                              'PROCEDURES_T122',
                                                                              'PROCEDURES_T082',
                                                                              'PROCEDURES_T091',
                                                                              'PROCEDURES_T011',
                                                                              'PROCEDURES_T143',
                                                                              'PROCEDURES_T023',
                                                                              'PROCEDURES_T025',
                                                                              'PROCEDURES_T130',
                                                                              'PROCEDURES_T131',
                                                                              'PROCEDURES_T139',
                                                                              'PROCEDURES_T144',
                                                                              'PROCEDURES_T078',
                                                                              'SUPPLIES_T076',
                                                                              'PROCEDURES_T092',
                                                                              'PROCEDURES_T090',
                                                                              'PROCEDURES_T123',
                                                                              'PROCEDURES_T100',
                                                                              'PROCEDURES_T138',
                                                                              'PROCEDURES_T077',
                                                                              'PROCEDURES_T010',
                                                                              'PROCEDURES_T038',
                                                                              'PROCEDURES_T163',
                                                                              'PROCEDURES_T133',
                                                                              'PROCEDURES_T134',
                                                                              'PROCEDURES_T135',
                                                                              'PROCEDURES_T136',
                                                                              'PROCEDURES_T137',
                                                                              'PROCEDURES_T164',
                                                                              'PROCEDURES_T185',
                                                                              'PROCEDURES_T089',
                                                                              'PROCEDURES_T029',
                                                                              'PROCEDURES_T186',
                                                                              'PROCEDURES_T024',
                                                                              'PROCEDURES_T187',
                                                                              'PROCEDURES_T036',
                                                                              'PROCEDURES_T151',
                                                                              'PROCEDURES_T148',
                                                                              'PROCEDURES_T149',
                                                                              'PROCEDURES_T150',
                                                                              'PROCEDURES_T153',
                                                                              'PROCEDURES_T152',
                                                                              'PROCEDURES_T159',
                                                                              'PROCEDURES_T162',
                                                                              'PROCEDURES_T158',
                                                                              'PROCEDURES_T155',
                                                                              'PROCEDURES_T156',
                                                                              'PROCEDURES_T161',
                                                                              'PROCEDURES_T157',
                                                                              'PROCEDURES_T160',
                                                                              'PROCEDURES_T145',
                                                                              'COMMON_T062');

    ga_code_messages_procedure_detail_upd CONSTANT table_varchar := table_varchar('PROCEDURES_T172',
                                                                                  'PROCEDURES_T120',
                                                                                  'PROCEDURES_T171',
                                                                                  'PROCEDURES_T174',
                                                                                  'PROCEDURES_T175',
                                                                                  'PROCEDURES_T176',
                                                                                  'PROCEDURES_T177',
                                                                                  'PROCEDURES_T178',
                                                                                  'SUPPLIES_T137',
                                                                                  'PROCEDURES_T179',
                                                                                  'PROCEDURES_T180',
                                                                                  'PROCEDURES_T181',
                                                                                  'PROCEDURES_T182',
                                                                                  'PROCEDURES_T183',
                                                                                  'PROCEDURES_T184',
                                                                                  'PROCEDURES_T173',
                                                                                  'PROCEDURES_T168',
                                                                                  'PROCEDURES_T169',
                                                                                  'PROCEDURES_T170',
                                                                                  'PROCEDURES_T110',
                                                                                  'PROCEDURES_T110',
                                                                                  'PROCEDURES_T111',
                                                                                  'PROCEDURES_T112',
                                                                                  'PROCEDURES_T113',
                                                                                  'PROCEDURES_T114',
                                                                                  'PROCEDURES_T115',
                                                                                  'PROCEDURES_T116',
                                                                                  'PROCEDURES_T116',
                                                                                  'COMMON_T061');

END pk_procedures_constant;
/
