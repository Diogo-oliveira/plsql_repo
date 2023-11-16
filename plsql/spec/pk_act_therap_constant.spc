/*-- Last Change Revision: $Rev: 2028438 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:45:46 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_act_therap_constant IS

    -- Author  : SOFIA.MENDES
    -- Created : 13-05-2010 15:29:43
    -- Purpose : Define the Activity Therapist constants

    -- Public constant declarations
    g_activ_therap_epis_type CONSTANT epis_type.id_epis_type%TYPE := 23;
    g_inp_epis_type          CONSTANT epis_type.id_epis_type%TYPE := 5;

    g_at_search_icons CONSTANT VARCHAR2(30) := 'AT_SEARCH_ICONS';

    g_flg_na        CONSTANT VARCHAR2(2) := 'NA';
    g_act_therapist CONSTANT profile_template.id_profile_template%TYPE := 800;

    g_supplies_default_qt CONSTANT PLS_INTEGER := 1;

    g_id_workflow CONSTANT wf_workflow.id_workflow%TYPE := 9;

    g_id_software_at CONSTANT software.id_software%TYPE := 80;

    --activity theraapist opinion (request) type
    g_at_opinion_type CONSTANT opinion_type.id_opinion_type%TYPE := 4;

    --default discharge reason
    g_def_disch_reas_sc CONSTANT sys_config.id_sys_config%TYPE := 'DEFAULT_DISCHARGE_REASON';

    g_id_supplies_alert CONSTANT sys_alert.id_sys_alert%TYPE := 95;

    g_msg_na              CONSTANT VARCHAR2(15) := 'AT_GRIDS_M002';
    g_msg_requested_to    CONSTANT VARCHAR2(15) := 'AT_GRIDS_M001';
    g_msg_cancelled       CONSTANT VARCHAR2(15) := 'AT_NOTES_M001';
    g_msg_loaned_units    CONSTANT VARCHAR2(15) := 'AT_SUP_M003';
    g_msg_supplies_header CONSTANT VARCHAR2(15) := 'AT_SUP_T010';
    g_msg_loan            CONSTANT VARCHAR2(15) := 'AT_SUP_M005';
    g_msg_return          CONSTANT VARCHAR2(15) := 'AT_SUP_M004';
    g_msg_nr_loaned       CONSTANT VARCHAR2(15) := 'AT_SUP_M006';
    g_msg_nr_returned     CONSTANT VARCHAR2(15) := 'AT_SUP_M007';
    g_msg_return_date     CONSTANT VARCHAR2(15) := 'AT_SUP_T009';
    g_msg_avail_units     CONSTANT VARCHAR2(15) := 'AT_SUP_M008';
    g_msg_epis_reopen     CONSTANT VARCHAR2(15) := 'AT_SUP_T011';
    g_msg_epis_reopen_bd  CONSTANT VARCHAR2(15) := 'AT_SUP_M009';
    g_msg_disch_no_config CONSTANT VARCHAR2(15) := 'AT_DISCH_M002';
    g_msg_disch_has_sup   CONSTANT VARCHAR2(15) := 'AT_DISCH_M001';
    g_msg_error           CONSTANT VARCHAR2(15) := 'COMMON_T006';
    --g_msg_warning          CONSTANT VARCHAR2(15) := 'COMMON_M015';
    g_msg_wrong_loan_units CONSTANT VARCHAR2(15) := 'AT_SUP_M015';
    g_msg_wrong_del_units  CONSTANT VARCHAR2(15) := 'AT_SUP_M016';
    g_msg_start_therapy    CONSTANT VARCHAR2(15) := 'AT_SEARCH_T005';
    g_msg_start_cont       CONSTANT VARCHAR2(15) := 'AT_SEARCH_M001';

    g_msg_create_req      CONSTANT VARCHAR2(15) := 'AT_SEARCH_T006';
    g_msg_create_req_cont CONSTANT VARCHAR2(15) := 'AT_SEARCH_M002';

    g_msg_with_return CONSTANT VARCHAR2(15) := 'AT_SUP_M020';

    g_msg_admission CONSTANT VARCHAR2(15) := 'AT_HIST_M001';
    g_msg_discharge CONSTANT VARCHAR2(15) := 'AT_HIST_M002';

    g_msg_auto_close       CONSTANT VARCHAR2(15) := 'AT_DISCH_M003';
    g_msg_auto_close_title CONSTANT VARCHAR2(15) := 'AT_DISCH_T008';

    g_msg_oper_add           CONSTANT VARCHAR2(15) := 'AT_HIST_T001';
    g_msg_oper_edit          CONSTANT VARCHAR2(15) := 'AT_HIST_T002';
    g_msg_oper_canc          CONSTANT VARCHAR2(15) := 'AT_HIST_T003';
    g_msg_delivered_units    CONSTANT VARCHAR2(15) := 'AT_HIST_M003';
    g_msg_loan_units         CONSTANT VARCHAR2(15) := 'AT_HIST_M004';
    g_msg_pr_delivery_date   CONSTANT VARCHAR2(15) := 'AT_HIST_M010';
    g_msg_delivery_date      CONSTANT VARCHAR2(15) := 'AT_HIST_M009';
    g_msg_delivery_canc      CONSTANT VARCHAR2(15) := 'AT_HIST_M008';
    g_msg_loan_canc          CONSTANT VARCHAR2(15) := 'AT_HIST_M007';
    g_msg_reg                CONSTANT VARCHAR2(15) := 'AT_HIST_M011';
    g_msg_supply             CONSTANT VARCHAR2(15) := 'AT_HIST_M005';
    g_msg_supply_type        CONSTANT VARCHAR2(15) := 'AT_HIST_M006';
    g_msg_cancel_notes_match CONSTANT VARCHAR2(15) := 'AT_CANC_M001';
    g_msg_cancel_del         CONSTANT VARCHAR2(15) := 'AT_SUP_T026';
    g_msg_wrong_cancel_del   CONSTANT VARCHAR2(15) := 'AT_SUP_M022';

    g_open_parenthesis  CONSTANT VARCHAR2(2) := ' (';
    g_close_parenthesis CONSTANT VARCHAR2(2) := ')';
    g_open_bold_html    CONSTANT VARCHAR2(5) := '<b>';
    g_close_bold_html   CONSTANT VARCHAR2(5) := '</b>';

    g_button  CONSTANT VARCHAR2(4) := 'NC';
    g_warning CONSTANT VARCHAR2(1) := 'D';

    g_domain_yes_no CONSTANT VARCHAR2(15) := 'YES_NO';

    g_screen_detail CONSTANT VARCHAR2(1) := 'D';
    g_screen_ehr    CONSTANT VARCHAR2(1) := 'E';

    g_ehr_view_option_sub CONSTANT VARCHAR2(15) := 'AT_EHR_HISTORY';

    g_1st_replace CONSTANT VARCHAR2(3) := '@1';
    g_2nd_replace CONSTANT VARCHAR2(3) := '@2';
    g_3rd_replace CONSTANT VARCHAR2(3) := '@3';

    g_scale_all   CONSTANT VARCHAR2(4) := 'ALL';
    g_scale_year  CONSTANT VARCHAR2(4) := 'YEAR';
    g_scale_month CONSTANT VARCHAR2(5) := 'MONTH';
    g_scale_week  CONSTANT VARCHAR2(4) := 'WEEK';

    g_test_cancel_deliver CONSTANT VARCHAR2(1) := 'C';
    g_test_reopen_episode CONSTANT VARCHAR2(1) := 'E';

    g_year_format  CONSTANT VARCHAR2(4) := 'YYYY';
    g_month_format CONSTANT VARCHAR2(4) := 'MM';
    g_week_format  CONSTANT VARCHAR2(4) := 'DAY';

    g_dashes CONSTANT VARCHAR2(3) := '--';
    
    --flags to indicate the type of popup to be show to the user
    g_flg_show_r constant varchar2(1 char) := 'R'; --popup with the read button
    g_flg_show_q constant varchar2(1 char) := 'Q'; --popup with the Yes/NO button

END pk_act_therap_constant;
/
