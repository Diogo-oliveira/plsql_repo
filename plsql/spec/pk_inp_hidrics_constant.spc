/*-- Last Change Revision: $Rev: 2028749 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:41 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_inp_hidrics_constant IS

    -- Author  : SOFIA.MENDES
    -- Created : 19-11-2009 08:59:17
    -- Purpose : This package should have all constants used in Hidrics functionality.

    g_create_hidrics_action_u CONSTANT VARCHAR2(1) := 'U';

    --epis_hidrics.flg_status
    g_epis_hidric_c CONSTANT epis_hidrics.flg_status%TYPE := 'C';
    g_epis_hidric_e CONSTANT epis_hidrics.flg_status%TYPE := 'E';
    g_epis_hidric_f CONSTANT epis_hidrics.flg_status%TYPE := 'F';
    g_epis_hidric_i CONSTANT epis_hidrics.flg_status%TYPE := 'I';
    g_epis_hidric_r CONSTANT epis_hidrics.flg_status%TYPE := 'R';
    g_epis_hidric_d CONSTANT epis_hidrics.flg_status%TYPE := 'D';
    g_epis_hidric_l CONSTANT epis_hidrics.flg_status%TYPE := 'L';
    g_epis_hidric_a CONSTANT epis_hidrics.flg_status%TYPE := 'A';
    g_epis_hidric_o CONSTANT epis_hidrics.flg_status%TYPE := 'O';
	g_epis_hidric_pd CONSTANT epis_hidrics.flg_status%TYPE := 'PD';

    --epis_hidrics/det/line.flg_action_state
    g_flg_action_a CONSTANT epis_hidrics.flg_action%TYPE := 'A'; -- insertion line, execution
    g_flg_action_u CONSTANT epis_hidrics.flg_action%TYPE := 'U'; -- edition
    g_flg_action_c CONSTANT epis_hidrics.flg_action%TYPE := 'C'; -- cancellation
    g_flg_action_i CONSTANT epis_hidrics.flg_action%TYPE := 'I'; -- interruption
    g_flg_action_f CONSTANT epis_hidrics.flg_action%TYPE := 'F'; -- finalize
    g_flg_action_r CONSTANT epis_hidrics.flg_action%TYPE := 'R'; -- request
    g_flg_action_e CONSTANT epis_hidrics.flg_action%TYPE := 'E'; -- set undergoing
    g_flg_action_d CONSTANT epis_hidrics.flg_action%TYPE := 'D'; -- set draft
    g_flg_action_l CONSTANT epis_hidrics.flg_action%TYPE := 'L';
    g_flg_action_o CONSTANT epis_hidrics.flg_action%TYPE := 'O';

    --hidrics.flg_type
    g_hidrics_flg_type_a CONSTANT hidrics.flg_type%TYPE := 'A';
    g_hidrics_flg_type_e CONSTANT hidrics.flg_type%TYPE := 'E';
    --
    g_hidrics_irrigations_g CONSTANT hidrics.flg_type%TYPE := 'G';

    --hidrics_type.acronym
    g_hid_type_d CONSTANT hidrics_type.acronym%TYPE := 'D';
    g_hid_type_h CONSTANT hidrics_type.acronym%TYPE := 'H';
    g_hid_type_r CONSTANT hidrics_type.acronym%TYPE := 'R';
    g_hid_type_g CONSTANT hidrics_type.acronym%TYPE := 'G';
    --new
    g_hid_type_i   CONSTANT hidrics_type.acronym%TYPE := 'I';
    g_hid_type_o   CONSTANT hidrics_type.acronym%TYPE := 'O';
    g_hid_type_all CONSTANT hidrics_type.acronym%TYPE := 'A';

    --hidrics_type.flg_ti_type
    g_hid_type_ti_type_bh CONSTANT hidrics_type.flg_ti_type%TYPE := 'BH';
    g_hid_type_ti_type_rd CONSTANT hidrics_type.flg_ti_type%TYPE := 'RD';

    --hidrics_relation.flg_state
    g_hid_relation_a CONSTANT hidrics_relation.flg_state%TYPE := 'A';
    g_hid_relation_i CONSTANT hidrics_relation.flg_state%TYPE := 'I';

    --epis_hidrics_balance.flg_status
    g_epis_hid_balance_r CONSTANT epis_hidrics_balance.flg_status%TYPE := 'R'; --Ordered
    g_epis_hid_balance_e CONSTANT epis_hidrics_balance.flg_status%TYPE := 'E'; --in progress
    g_epis_hid_balance_c CONSTANT epis_hidrics_balance.flg_status%TYPE := 'C'; --Cancelled
    g_epis_hid_balance_i CONSTANT epis_hidrics_balance.flg_status%TYPE := 'I'; --Discontinued
    g_epis_hid_balance_f CONSTANT epis_hidrics_balance.flg_status%TYPE := 'F'; --Complete

    --epis_hidrics_balance.flg_close_type
    g_epis_hid_bal_closed_aut   CONSTANT epis_hidrics_balance.flg_close_type%TYPE := 'A'; --automatically
    g_epis_hid_bal_closed_man_b CONSTANT epis_hidrics_balance.flg_close_type%TYPE := 'B'; --manually updating auto balance time
    g_epis_hid_bal_closed_man_c CONSTANT epis_hidrics_balance.flg_close_type%TYPE := 'C'; --manually without updating the auto balance time

    g_flg_task_status_d CONSTANT VARCHAR2(1) := 'D';
    g_flg_task_status_f CONSTANT VARCHAR2(1) := 'F';
    g_flg_task_status_o CONSTANT VARCHAR2(1) := 'O';

    --pk_inp_hidrics.get_cfg_vars - i_cfg_type
    g_cfg_var_w CONSTANT VARCHAR2(1) := 'W'; --Way
    g_cfg_var_l CONSTANT VARCHAR2(1) := 'L'; --Location
    g_cfg_var_h CONSTANT VARCHAR2(1) := 'H'; --Fluid (Hidric)
    g_cfg_var_c CONSTANT VARCHAR2(1) := 'C'; --Characterization of Fluid (Hidric)   
    g_cfg_var_i CONSTANT VARCHAR2(1) := 'I'; --Interval   
    g_cfg_var_r CONSTANT VARCHAR2(1) := 'R'; --Fluid restriction alerts
    g_cfg_var_d CONSTANT VARCHAR2(1) := 'D'; --Device
    g_cfg_var_o CONSTANT VARCHAR2(1) := 'O'; --Occurrence type

    --hidrics_way_flg_type
    g_hid_way_type_p CONSTANT way.flg_way_type%TYPE := 'P'; --IV solution (Parentérica)
    g_hid_way_type_e CONSTANT way.flg_way_type%TYPE := 'E'; --E - Enteral solution (Entérica)
    g_hid_way_type_o CONSTANT way.flg_way_type%TYPE := 'O'; --Other

    --epis_hidrics_det.flg_type
    g_epis_hid_det_type_a CONSTANT epis_hidrics_det.flg_type%TYPE := 'A'; --Administered
    g_epis_hid_det_type_p CONSTANT epis_hidrics_det.flg_type%TYPE := 'P'; --Proposed

    --epis_hidrics_det.flg_status
    g_epis_hid_det_status_a CONSTANT epis_hidrics_det.flg_status%TYPE := 'A'; --Active
    g_epis_hid_det_status_c CONSTANT epis_hidrics_det.flg_status%TYPE := 'C'; --Cancelled    

    --epis_hidrics_line.flg_status
    g_epis_hid_lin_status_a CONSTANT epis_hidrics_line.flg_status%TYPE := 'A'; --Active
    g_epis_hid_lin_status_c CONSTANT epis_hidrics_line.flg_status%TYPE := 'C'; --Cancelled    

    --hidrics_interval.flg_type
    g_hid_interval_type_o CONSTANT hidrics_interval.flg_type%TYPE := 'O'; --Other
    g_hid_interval_type_n CONSTANT hidrics_interval.flg_type%TYPE := 'N'; --Not applicable

    -- flowsheet constants
    g_element_normal  CONSTANT VARCHAR2(10) := 'N';
    g_element_presc   CONSTANT VARCHAR2(10) := 'P'; -- drug prescriptions
    g_element_total   CONSTANT VARCHAR2(10) := 'T';
    g_element_tot_abs CONSTANT VARCHAR2(10) := 'TA';
    g_element_tot_manual CONSTANT VARCHAR2(10) := 'TM';

    -- graph/flowsheet constants
    g_grid_type_f    CONSTANT VARCHAR2(10) := 'F';
    g_grid_type_g    CONSTANT VARCHAR2(10) := 'G';
    g_graph_hour     CONSTANT sys_domain.val%TYPE := 'H';
    g_graph_interval CONSTANT sys_domain.val%TYPE := 'I';

    -- context variables (used to send fluid restriction alerts)
    g_context_end_balance     CONSTANT VARCHAR2(10) := 'AB';
    g_context_msg_end_balance CONSTANT VARCHAR2(10) := 'B';
    g_context_new_record      CONSTANT VARCHAR2(10) := 'AN';
    g_context_msg_new_record  CONSTANT VARCHAR2(10) := 'R';

    -- different alert IDs
    g_alert_total_balance CONSTANT sys_alert.id_sys_alert%TYPE := 96;
    g_alert_min_output    CONSTANT sys_alert.id_sys_alert%TYPE := 97;
    g_alert_max_intake    CONSTANT sys_alert.id_sys_alert%TYPE := 98;

    -- number of miliseconds in one day/hour
    g_day_ms  CONSTANT NUMBER := 86400000;
    g_hour_ms CONSTANT NUMBER := 3600000;

    g_msg_replace_1 CONSTANT VARCHAR2(2 CHAR) := '@1';

    /* Package name */
    g_package_name  VARCHAR2(32);
    g_package_owner VARCHAR2(32);

    --Search, filter, paging, ordering in hidrics grid
    g_num_records            CONSTANT VARCHAR2(30 CHAR) := 'HIDRICS_NUM_REC_PAGE';
    g_num_records_max        CONSTANT PLS_INTEGER := 999999999;
    g_filter_type_1          CONSTANT PLS_INTEGER := 1;
    g_filter_type_2          CONSTANT PLS_INTEGER := 2;
    g_filter_type_3          CONSTANT PLS_INTEGER := 3;
    g_filter_type_all        CONSTANT PLS_INTEGER := 0;
    g_columns_order_1        CONSTANT PLS_INTEGER := 1;
    g_columns_order_2        CONSTANT PLS_INTEGER := 2;
    g_columns_order_3        CONSTANT PLS_INTEGER := 3;
    g_columns_order_4        CONSTANT PLS_INTEGER := 4;
    g_columns_order_5        CONSTANT PLS_INTEGER := 5;
    g_columns_order_6        CONSTANT PLS_INTEGER := 6;
    g_order_by_1             CONSTANT PLS_INTEGER := 1;
    g_order_by_2             CONSTANT PLS_INTEGER := 2;
    g_order_by_asc           CONSTANT VARCHAR2(30 CHAR) := 'ASC';
    g_order_by_desc          CONSTANT VARCHAR2(30 CHAR) := 'DESC';
    g_init_record            CONSTANT PLS_INTEGER := 0;
    g_domain_eh_flg_status   CONSTANT VARCHAR2(30 CHAR) := 'EPIS_HIDRICS.FLG_STATUS';
    g_image_decode           CONSTANT VARCHAR2(30 CHAR) := 'IMAGE_T009';
    g_order_by_asc_num       CONSTANT PLS_INTEGER := 1;
    g_order_by_desc_num      CONSTANT PLS_INTEGER := -1;
    g_last_hidrics_balance   CONSTANT PLS_INTEGER := 1;
    g_domain_eh_flg_restrict CONSTANT VARCHAR2(30 CHAR) := 'EPIS_HIDRICS.FLG_RESTRICTED';
    g_one_hour_unit          CONSTANT PLS_INTEGER := 1;
    g_domain_ehb_flg_status  CONSTANT VARCHAR2(200 CHAR) := 'EPIS_HIDRICS_BALANCE.FLG_STATUS';
    g_hour_minute_format     CONSTANT VARCHAR2(30 CHAR) := 'HH24:MI';
    g_hour_format            CONSTANT VARCHAR2(30 CHAR) := 'HH24';
    g_enter                  CONSTANT VARCHAR2(30 CHAR) := '\n';
    g_open_bracket           CONSTANT VARCHAR2(30 CHAR) := '(';
    g_close_bracket          CONSTANT VARCHAR2(30 CHAR) := ')';

    -- check types
    g_check_type_w CONSTANT VARCHAR2(1 CHAR) := 'W';
    g_check_type_h CONSTANT VARCHAR2(1 CHAR) := 'H';
    g_check_type_c CONSTANT VARCHAR2(1 CHAR) := 'C';
    g_check_type_l CONSTANT VARCHAR2(1 CHAR) := 'L';
    g_check_type_d CONSTANT VARCHAR2(1 CHAR) := 'D';

    g_open_bold  CONSTANT VARCHAR2(3 CHAR) := '<b>';
    g_close_bold CONSTANT VARCHAR2(4 CHAR) := '</b>';
    g_colon      CONSTANT VARCHAR2(1 CHAR) := ':';

    g_semicolon   CONSTANT VARCHAR2(1 CHAR) := ';';
    g_comma       CONSTANT VARCHAR2(1 CHAR) := ',';
    g_space       CONSTANT VARCHAR2(1 CHAR) := ' ';
    g_hifen       CONSTANT VARCHAR2(1 CHAR) := '-';
    g_right_slash CONSTANT VARCHAR2(1 CHAR) := '/';
    --separator to be used in flowsheet and graph views to separate the info set to flash
    g_separator CONSTANT VARCHAR2(1 CHAR) := '\';

    --FLGS to identify the detail/history screens
    g_detail_screen_d      CONSTANT VARCHAR2(1 CHAR) := 'D';
    g_hist_screen_h        CONSTANT VARCHAR2(1 CHAR) := 'H';
    g_detail_line_screen_l CONSTANT VARCHAR2(1 CHAR) := 'L';

    -- report types
    g_report_complete_c CONSTANT VARCHAR2(1) := 'C';
    g_report_complete_d CONSTANT VARCHAR2(1) := 'D';
    -- PDMS API that don't returns cancel records and returns the executions of all balances
    g_report_complete_p CONSTANT VARCHAR2(1) := 'P';

    -- type of content to be returned in the detail/history screens
    g_title_t       CONSTANT VARCHAR2(1) := 'T';
    g_content_c     CONSTANT VARCHAR2(1) := 'C';
    g_signature_s   CONSTANT VARCHAR2(1) := 'S';
    g_new_content_n CONSTANT VARCHAR2(1) := 'N';
    --a content under other content
    g_content_sc      CONSTANT VARCHAR2(2) := 'SC';
    g_new_content_nsc CONSTANT VARCHAR2(3) := 'NSC';

    --detail null value
    g_detail_empty CONSTANT VARCHAR2(3) := '---';

    g_sm_detail_empty CONSTANT sys_message.code_message%TYPE := 'COMMON_M106';
    g_sm_no_changes   CONSTANT sys_message.code_message%TYPE := 'HIDRICS_M072';

    --PDMS API
    g_hidrics_flg_type  CONSTANT VARCHAR2(30 CHAR) := 'HIDRICS.FLG_TYPE';
    g_flg_hidrics_med_h CONSTANT VARCHAR2(1) := 'H';
    g_flg_hidrics_med_m CONSTANT VARCHAR2(1) := 'M';

    --timeline for reports (ALERT-172572)
    g_hidric_crit_type_exec_e CONSTANT VARCHAR2(1 CHAR) := 'E'; --executions
    g_hidric_crit_type_req_r  CONSTANT VARCHAR2(1 CHAR) := 'R'; --requisitions
    g_hidric_crit_type_bal_b  CONSTANT VARCHAR2(1 CHAR) := 'B'; --balance
    g_hidric_crit_type_all_a  CONSTANT VARCHAR2(1 CHAR) := 'A'; --All

    g_import_iv_fluids CONSTANT sys_config.id_sys_config%TYPE := 'INTAKE_OUTPUT_IMPORT_IV_FLUIDS';

    g_task_type_hidric             CONSTANT task_type.id_task_type%TYPE := 105; -- hidrics (group)
    g_task_type_hidric_in_out      CONSTANT task_type.id_task_type%TYPE := 106; -- hidrics (intake and output)
    g_task_type_hidric_in          CONSTANT task_type.id_task_type%TYPE := 107; -- hidrics (intake)
    g_task_type_hidric_out         CONSTANT task_type.id_task_type%TYPE := 108; -- hidrics (output)
    g_task_type_hidric_urinary     CONSTANT task_type.id_task_type%TYPE := 109; -- hidrics (urinary output)
    g_task_type_hidric_drain       CONSTANT task_type.id_task_type%TYPE := 110; -- hidrics (drainage record)
    g_task_type_hidric_all_output  CONSTANT task_type.id_task_type%TYPE := 111; -- hidrics (all output)
    g_task_type_hidric_irrigations CONSTANT task_type.id_task_type%TYPE := 112; -- hidrics (irrigations)
    
    g_hidric_type_in_out CONSTANT hidrics_type.id_hidrics_type%TYPE := 503; --hidrics type (intake and output)

END pk_inp_hidrics_constant;
/
