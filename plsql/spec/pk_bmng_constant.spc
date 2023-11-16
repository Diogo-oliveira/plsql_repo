/*-- Last Change Revision: $Rev: 2028541 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:24 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_bmng_constant IS

    -- Author  : LUIS.MAIA
    -- Created : 24-07-2009 19:47:43
    -- Purpose : This package should have all constants used in Bed Management functionality

    ---------------------------------------- GLOBAL VALUES ----------------------------------------------

    -- ### BED MANAGEMENT FUNCTIONALITY
    -- bed.flg_type
    g_bmng_bed_flg_type_p CONSTANT bed.flg_type%TYPE := 'P';
    g_bmng_bed_flg_type_t CONSTANT bed.flg_type%TYPE := 'T';
    -- bed.flg_status
    g_bmng_bed_flg_status_v CONSTANT bed.flg_status%TYPE := 'V';
    g_bmng_bed_flg_status_o CONSTANT bed.flg_status%TYPE := 'O';
    g_bmng_bed_flg_status_d CONSTANT bed.flg_status%TYPE := 'D';
    -- bmng_allocation_bed.flg_allocation_nch
    g_bmng_allocat_flg_nch_d CONSTANT epis_nch.flg_type%TYPE := 'D';
    g_bmng_allocat_flg_nch_u CONSTANT epis_nch.flg_type%TYPE := 'U';
    -- bmng_action.flg_target_action
    g_bmng_act_flg_target_s CONSTANT bmng_action.flg_target_action%TYPE := 'S';
    g_bmng_act_flg_target_r CONSTANT bmng_action.flg_target_action%TYPE := 'R';
    g_bmng_act_flg_target_b CONSTANT bmng_action.flg_target_action%TYPE := 'B';
    -- bmng_action.flg_status
    g_bmng_act_flg_status_a CONSTANT bmng_action.flg_status%TYPE := 'A';
    g_bmng_act_flg_status_c CONSTANT bmng_action.flg_status%TYPE := 'C';
    g_bmng_act_flg_status_o CONSTANT bmng_action.flg_status%TYPE := 'O';
    -- bmng_action.flg_origin_action
    g_bmng_act_flg_origin_nb CONSTANT bmng_action.flg_origin_action%TYPE := 'NB'; -- NCH Backoffice (institution backoffice)
    g_bmng_act_flg_origin_nt CONSTANT bmng_action.flg_origin_action%TYPE := 'NT'; -- NCH inserted by chiefe nurse (in tools)
    g_bmng_act_flg_origin_nd CONSTANT bmng_action.flg_origin_action%TYPE := 'ND'; -- NCH information inserted in dashboard
    g_bmng_act_flg_origin_bt CONSTANT bmng_action.flg_origin_action%TYPE := 'BT'; -- Blocking interval inserted by chiefe nurse (in tools)
    g_bmng_act_flg_origin_bd CONSTANT bmng_action.flg_origin_action%TYPE := 'BD'; -- Blocking interval information inserted in dashboard
    g_bmng_act_flg_origin_od CONSTANT bmng_action.flg_origin_action%TYPE := 'OD'; -- Other origins
    -- bmng_action.flg_bed_ocupacity_status
    g_bmng_act_flg_ocupaci_o CONSTANT bmng_action.flg_bed_ocupacity_status%TYPE := 'O';
    g_bmng_act_flg_ocupaci_v CONSTANT bmng_action.flg_bed_ocupacity_status%TYPE := 'V';
    -- bmng_action.flg_bed_status
    g_bmng_act_flg_bed_sta_r CONSTANT bmng_action.flg_bed_status%TYPE := 'R';
    g_bmng_act_flg_bed_sta_b CONSTANT bmng_action.flg_bed_status%TYPE := 'B';
    g_bmng_act_flg_bed_sta_s CONSTANT bmng_action.flg_bed_status%TYPE := 'S';
    g_bmng_act_flg_bed_sta_n CONSTANT bmng_action.flg_bed_status%TYPE := 'N';
    -- bmng_action.flg_bed_cleaning_status
    g_bmng_act_flg_cleani_d CONSTANT bmng_action.flg_bed_cleaning_status%TYPE := 'D';
    g_bmng_act_flg_cleani_c CONSTANT bmng_action.flg_bed_cleaning_status%TYPE := 'C';
    g_bmng_act_flg_cleani_i CONSTANT bmng_action.flg_bed_cleaning_status%TYPE := 'I';
    g_bmng_act_flg_cleani_l CONSTANT bmng_action.flg_bed_cleaning_status%TYPE := 'L';
    g_bmng_act_flg_cleani_n CONSTANT bmng_action.flg_bed_cleaning_status%TYPE := 'N';
    --
    -- bmng_bed_ea.flg_allocation_nch
    g_bmng_bed_ea_flg_nch_d CONSTANT bmng_bed_ea.flg_allocation_nch%TYPE := 'D';
    g_bmng_bed_ea_flg_nch_u CONSTANT bmng_bed_ea.flg_allocation_nch%TYPE := 'U';
    -- bmng_bed_ea.flg_bed_ocupacity_status
    g_bmng_bed_ea_flg_ocup_o CONSTANT bmng_bed_ea.flg_bed_ocupacity_status%TYPE := 'O';
    g_bmng_bed_ea_flg_ocup_v CONSTANT bmng_bed_ea.flg_bed_ocupacity_status%TYPE := 'V';
    -- bmng_bed_ea.flg_bed_status
    g_bmng_bed_ea_flg_stat_r CONSTANT bmng_bed_ea.flg_bed_status%TYPE := 'R';
    g_bmng_bed_ea_flg_stat_b CONSTANT bmng_bed_ea.flg_bed_status%TYPE := 'B';
    g_bmng_bed_ea_flg_stat_s CONSTANT bmng_bed_ea.flg_bed_status%TYPE := 'S';
    g_bmng_bed_ea_flg_stat_n CONSTANT bmng_bed_ea.flg_bed_status%TYPE := 'N';
    -- bmng_bed_ea.flg_type
    g_bmng_bed_ea_flg_type_p CONSTANT bmng_bed_ea.flg_bed_type%TYPE := 'P';
    g_bmng_bed_ea_flg_type_t CONSTANT bmng_bed_ea.flg_bed_type%TYPE := 'T';
    -- bmng_bed_ea.flg_bed_cleaning_status
    g_bmng_bed_ea_flg_cle_d CONSTANT bmng_bed_ea.flg_bed_cleaning_status%TYPE := 'D';
    g_bmng_bed_ea_flg_cle_c CONSTANT bmng_bed_ea.flg_bed_cleaning_status%TYPE := 'C';
    g_bmng_bed_ea_flg_cle_i CONSTANT bmng_bed_ea.flg_bed_cleaning_status%TYPE := 'I';
    g_bmng_bed_ea_flg_cle_l CONSTANT bmng_bed_ea.flg_bed_cleaning_status%TYPE := 'L';
    g_bmng_bed_ea_flg_cle_n CONSTANT bmng_bed_ea.flg_bed_cleaning_status%TYPE := 'N';

    --
    g_bmng_flg_action_p CONSTANT bmng_action.flg_action%TYPE := 'P';
    g_bmng_flg_action_t CONSTANT bmng_action.flg_action%TYPE := 'T';
    g_bmng_flg_action_v CONSTANT bmng_action.flg_action%TYPE := 'V';

    --
    -- SYS_CONFIG
    g_bmng_config_tools_hist   CONSTANT sys_config.id_sys_config%TYPE := 'BMNG_TOOLS_HIST_NUM_MONTHS_LIMIT';
    g_bmng_conf_def_nch_dep    CONSTANT sys_config.id_sys_config%TYPE := 'BMNG_TOOLS_NCH_DAY';
    g_bmng_conf_def_nch_median CONSTANT sys_config.id_sys_config%TYPE := 'BMNG_TOOLS_NCH_MEDIAN';
    g_bmng_conf_def_nch_pat    CONSTANT sys_config.id_sys_config%TYPE := 'BMNG_DEFAULT_NCH';
    g_bmng_conf_def_anc_limit  CONSTANT sys_config.id_sys_config%TYPE := 'BMNG_ANC_ACT_HOUR_LIM';

    --
    --
    -- SYS_MESSAGE
    g_bmng_message_def_hours_sign CONSTANT sys_config.id_sys_config%TYPE := 'HOURS_SIGN';

    g_bmng_label_service      CONSTANT sys_message.code_message%TYPE := 'BMNG_T020';
    g_bmng_label_room_name    CONSTANT sys_message.code_message%TYPE := 'BMNG_T021';
    g_bmng_label_room_type    CONSTANT sys_message.code_message%TYPE := 'BMNG_T022';
    g_bmng_label_bed_name     CONSTANT sys_message.code_message%TYPE := 'BMNG_T023';
    g_bmng_label_bed_type     CONSTANT sys_message.code_message%TYPE := 'BMNG_T024';
    g_bmng_label_bed_specs    CONSTANT sys_message.code_message%TYPE := 'BMNG_T025';
    g_bmng_label_dt_discharge CONSTANT sys_message.code_message%TYPE := 'BMNG_T026';
    g_bmng_label_nch          CONSTANT sys_message.code_message%TYPE := 'BMNG_T027';
    g_bmng_label_action_notes CONSTANT sys_message.code_message%TYPE := 'BMNG_T032';
    -- new
    g_bmng_label_pat_name      CONSTANT sys_message.code_message%TYPE := 'BMNG_T140';
    g_bmng_label_bed_status    CONSTANT sys_message.code_message%TYPE := 'BMNG_T141';
    g_bmng_label_bed_cl_status CONSTANT sys_message.code_message%TYPE := 'BMNG_T142';
    g_bmng_label_block_reason  CONSTANT sys_message.code_message%TYPE := 'BMNG_T143';
    g_bmng_label_blocked_until CONSTANT sys_message.code_message%TYPE := 'BMNG_T144';

    --
    --
    -- Constants to be used for FLASH in variable FLG_ORIGIN_ACTION_UX
    g_bmng_flg_origin_ux_b  CONSTANT VARCHAR2(2) := 'B';
    g_bmng_flg_origin_ux_u  CONSTANT VARCHAR2(2) := 'U';
    g_bmng_flg_origin_ux_v  CONSTANT VARCHAR2(2) := 'V';
    g_bmng_flg_origin_ux_o  CONSTANT VARCHAR2(2) := 'O';
    g_bmng_flg_origin_ux_t  CONSTANT VARCHAR2(2) := 'T';
    g_bmng_flg_origin_ux_p  CONSTANT VARCHAR2(2) := 'P';
    g_bmng_flg_origin_ux_s  CONSTANT VARCHAR2(2) := 'S';
    g_bmng_flg_origin_ux_r  CONSTANT VARCHAR2(2) := 'R';
    g_bmng_flg_origin_ux_d  CONSTANT VARCHAR2(2) := 'D';
    g_bmng_flg_origin_ux_c  CONSTANT VARCHAR2(2) := 'C';
    g_bmng_flg_origin_ux_i  CONSTANT VARCHAR2(2) := 'I';
    g_bmng_flg_origin_ux_l  CONSTANT VARCHAR2(2) := 'L';
    g_bmng_flg_origin_ux_e  CONSTANT VARCHAR2(2) := 'E';
    g_bmng_flg_origin_ux_nb CONSTANT VARCHAR2(2) := 'NB';
    g_bmng_flg_origin_ux_nd CONSTANT VARCHAR2(2) := 'ND';
    g_bmng_flg_origin_ux_nt CONSTANT VARCHAR2(2) := 'NT';
    g_bmng_flg_origin_ux_bt CONSTANT VARCHAR2(2) := 'BT';
    g_bmng_flg_origin_ux_ut CONSTANT VARCHAR2(2) := 'UT';
    g_bmng_flg_origin_ux_ps CONSTANT VARCHAR2(2) := 'PS';
    /* Package name */
    g_package_name  VARCHAR2(32);
    g_package_owner VARCHAR2(32);

    /* Error tracking */
    g_error VARCHAR2(4000);

    /* Invalid event type */
    g_excp_invalid_event_type EXCEPTION;

    /* get_bmng_intervals request type */
    g_bmng_intervals_req_type_a CONSTANT VARCHAR2(1) := 'A'; -- All
    g_bmng_intervals_req_type_p CONSTANT VARCHAR2(1) := 'P'; -- Past
    g_bmng_intervals_req_type_f CONSTANT VARCHAR2(1) := 'F'; -- Future
    g_bmng_intervals_req_type_d CONSTANT VARCHAR2(1) := 'D'; -- Specific date, otherwise current date
    g_bmng_intervals_req_type_c CONSTANT VARCHAR2(1) := 'C'; -- Cancelled

    /* get_bmng_intervals origin action */
    g_bmng_intervals_orig_act_n CONSTANT VARCHAR2(1) := 'N'; -- NCH : 'NB', 'NT', 'ND'
    g_bmng_intervals_orig_act_b CONSTANT VARCHAR2(1) := 'B'; -- Blocking interval : 'BT', 'BD'

END pk_bmng_constant;
/
