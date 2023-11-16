/*-- Last Change Revision: $Rev: 1932931 $*/
/*-- Last Change by: $Author: nuno.coelho $*/
/*-- Date of last change: $Date: 2020-01-24 14:48:55 +0000 (sex, 24 jan 2020) $*/

CREATE OR REPLACE PACKAGE pk_hhc_constant IS

    -- hhc software
    k_hhc_software CONSTANT NUMBER := 312;

    k_hhc_req_status_requested     CONSTANT VARCHAR2(0001 CHAR) := 'R'; --  Requested
    k_hhc_req_status_part_approved CONSTANT VARCHAR2(0001 CHAR) := 'P'; --  Partially accepted
    k_hhc_req_stauts_part_acc_wcm  CONSTANT VARCHAR2(0001 CHAR) := 'W'; --  Partially accepted without assigned case manager
    k_hhc_req_status_in_eval       CONSTANT VARCHAR2(0001 CHAR) := 'E'; --  In evaluation
    k_hhc_req_status_approved      CONSTANT VARCHAR2(0001 CHAR) := 'A'; --  Approved
    k_hhc_req_status_in_progress   CONSTANT VARCHAR2(0001 CHAR) := 'O'; --  In progress
    k_hhc_req_status_rejected      CONSTANT VARCHAR2(0001 CHAR) := 'I'; --  Rejected
    k_hhc_req_status_closed        CONSTANT VARCHAR2(0001 CHAR) := 'F'; --  Closed
    k_hhc_req_status_canceled      CONSTANT VARCHAR2(0001 CHAR) := 'C'; --  Canceled
    k_hhc_req_status_discontinued  CONSTANT VARCHAR2(0001 CHAR) := 'D'; --  Discontinued
    k_hhc_req_status_undo          CONSTANT VARCHAR2(0001 CHAR) := 'U'; --  Undo    

    --k_hhc_req_status_create        CONSTANT VARCHAR2(0001 CHAR) := 'C'; --  Create
    --k_hhc_req_status_edit          CONSTANT VARCHAR2(0001 CHAR) := 'E'; --  Edit
    k_hhc_row_dml_create CONSTANT VARCHAR2(0001 CHAR) := 'C'; --  Create
    k_hhc_row_dml_edit   CONSTANT VARCHAR2(0001 CHAR) := 'E'; --  Edit

    k_hhc_type_text CONSTANT VARCHAR2(0001 CHAR) := 'T'; --  text type

    g_type_name_lab     VARCHAR2(0100 CHAR) := 'LAB';
    g_type_name_exam    VARCHAR2(0100 CHAR) := 'EXAM';
    g_type_name_problem VARCHAR2(0100 CHAR) := 'PROBLEM';
    --g_type_name_probl_diag  VARCHAR2(0100 CHAR) := 'PROBLEM_DIAG';
    --g_type_name_probl_aller VARCHAR2(0100 CHAR) := 'PROBLEM_ALLER';
    g_type_name_prof_in_ch VARCHAR2(0100 CHAR) := 'PROF_CHARGE';

    g_flg_type_d VARCHAR2(0010 CHAR) := 'D';
    g_flg_type_k VARCHAR2(0010 CHAR) := 'K';
    k_flg_type_r VARCHAR2(0010 CHAR) := 'R';

    k_action_add    CONSTANT NUMBER := 235534078;
    k_action_edit   CONSTANT NUMBER := 235534079;
    k_action_cancel CONSTANT NUMBER := 235534080;

    k_ds_referral_type             CONSTANT NUMBER := 1289;
    k_ds_referral_origin           CONSTANT NUMBER := 1290;
    k_ds_medical_history           CONSTANT NUMBER := 1292;
    k_ds_problems                  CONSTANT NUMBER := 1294;
    k_ds_vaccines                  CONSTANT NUMBER := 1296;
    k_ds_care_plan                 CONSTANT NUMBER := 1298;
    k_ds_supplies                  CONSTANT NUMBER := 1300;
    k_ds_iv_referral_required      CONSTANT NUMBER := 1302;
    k_ds_iv_pharm_assessed         CONSTANT NUMBER := 1303;
    k_ds_iv_inf_control_done       CONSTANT NUMBER := 1304;
    k_ds_investigation_lab         CONSTANT NUMBER := 1306;
    k_ds_investigation_exam        CONSTANT NUMBER := 1307;
    k_ds_care_giver_name           CONSTANT NUMBER := 1309;
    k_ds_care_giver_contact_num    CONSTANT NUMBER := 1310;
    k_ds_prof_in_charge_name       CONSTANT NUMBER := 1312;
    k_ds_prof_in_charge_mobile_num CONSTANT NUMBER := 1313;
    k_ds_care_plan_specify         CONSTANT NUMBER := 1315;

    k_ds_family_relationship CONSTANT NUMBER := 1056;
    k_ds_family_rel_specify  CONSTANT NUMBER := 1317;
    k_ds_firstname           CONSTANT NUMBER := 906;
    k_ds_lastname            CONSTANT NUMBER := 909;
    k_ds_othernames1         CONSTANT NUMBER := 902;
    k_ds_othernames3         CONSTANT NUMBER := 905;
    k_ds_phone_mobile        CONSTANT NUMBER := 918;
    k_ds_phone_mob_ctry_code CONSTANT NUMBER := 1052;
    k_ds_id_care_giver       CONSTANT NUMBER := 1393;

    k_hhc_epis_type CONSTANT NUMBER := 99;
    k_hhc_epis_type_child CONSTANT NUMBER := 50;

    --hhc discharge
    --popup type
    k_disch_hhc_performed CONSTANT VARCHAR2(19 CHAR) := 'DISCH_HHC_PERFORMED';
    k_disch_hhc_approval  CONSTANT VARCHAR2(18 CHAR) := 'DISCH_HHC_APPROVAL';
    k_disch_hhc_ongoing   CONSTANT VARCHAR2(19 CHAR) := 'DISCH_HHC_ONGOING';
    --discharge status
    k_disch_pending CONSTANT NUMBER := 7;
    k_disch_final   CONSTANT NUMBER := 1;

    -- Functionalities
    k_hhc_func_coordinator  CONSTANT NUMBER := 1523;
    k_hhc_func_case_manager CONSTANT NUMBER := 1524;

    --Alerts
    k_hhc_new_referral_alert   CONSTANT NUMBER := 325;
    k_hhc_approved_alert       CONSTANT NUMBER := 326;
    k_hhc_reject_alert         CONSTANT NUMBER := 327;
    k_hhc_end_follow_up_alert  CONSTANT NUMBER := 328;
    k_hhc_manager_assign_alert CONSTANT NUMBER := 329;
    k_hhc_team_discharge_alert CONSTANT NUMBER := 330;

    -- ALERTS
    k_hhc_new_referral_msg   CONSTANT VARCHAR2(200) := 'V_ALERT_M325';
    k_hhc_approved_msg       CONSTANT VARCHAR2(200) := 'V_ALERT_M326';
    k_hhc_reject_msg         CONSTANT VARCHAR2(200) := 'V_ALERT_M327';
    k_hhc_end_follow_up_msg  CONSTANT VARCHAR2(200) := 'V_ALERT_M328';
    k_hhc_manager_assign_msg CONSTANT VARCHAR2(200) := 'V_ALERT_M329';
    k_hhc_team_dicharge_msg  CONSTANT VARCHAR2(200) := 'V_ALERT_M330';

    --hhc_det_type flg_type
    k_hhc_flg_type_text CONSTANT VARCHAR2(1 CHAR) := 'T'; --text
    k_hhc_flg_type_k    CONSTANT VARCHAR2(1 CHAR) := 'K';
    k_hhc_flg_type_d    CONSTANT VARCHAR2(1 CHAR) := 'D';
    k_hhc_flg_type_r    CONSTANT VARCHAR2(1 CHAR) := 'R';

    --ds_component flg_data_type
    k_hhc_flg_data_type_ft CONSTANT VARCHAR2(2 CHAR) := 'FT'; --free text
    k_hhc_flg_data_type_lo CONSTANT VARCHAR2(2 CHAR) := 'LO';
    k_hhc_flg_data_type_mw CONSTANT VARCHAR2(2 CHAR) := 'MW';
    k_hhc_flg_data_type_ms CONSTANT VARCHAR2(2 CHAR) := 'MS';
    k_hhc_flg_data_type_cb CONSTANT VARCHAR2(2 CHAR) := 'CB';
    --
    --profile_template id's
    k_prof_templ_die   CONSTANT NUMBER := 70;
    k_prof_templ_nurse CONSTANT NUMBER := 749;
    k_prof_templ_ot    CONSTANT NUMBER := 800;
    k_prof_templ_psy   CONSTANT NUMBER := 742;
    k_prof_templ_pt    CONSTANT NUMBER := 48;
    k_prof_templ_pt_c  CONSTANT NUMBER := 49;
    k_prof_templ_phy   CONSTANT NUMBER := 747;
    k_prof_templ_rt    CONSTANT NUMBER := 411;
    k_prof_templ_sw    CONSTANT NUMBER := 28;
    k_prof_templ_sw_h  CONSTANT NUMBER := 31;
    k_prof_templ_st    CONSTANT NUMBER := 801;

    k_ds_adt_name_fam_rel     CONSTANT VARCHAR2(200 CHAR) := 'DS_FAMILY_RELATIONSHIP';
    k_ds_adt_name_fam_rel_spec CONSTANT VARCHAR2(200 CHAR) := 'DS_FAMILY_RELATIONSHIP_SPECIFY';
    k_ds_adt_name_1st_name    CONSTANT VARCHAR2(200 CHAR) := 'DS_FIRSTNAME';
    k_ds_adt_name_oname1      CONSTANT VARCHAR2(200 CHAR) := 'DS_OTHERNAMES1';
    k_ds_adt_name_last_anme   CONSTANT VARCHAR2(200 CHAR) := 'DS_LASTNAME';
    k_ds_adt_name_oname3      CONSTANT VARCHAR2(200 CHAR) := 'DS_OTHERNAMES3';
    k_ds_adt_name_phone_no    CONSTANT VARCHAR2(200 CHAR) := 'DS_PHONE_MOBILE';
    k_ds_adt_id_care_giver     CONSTANT VARCHAR2(200 CHAR) := 'DS_HHC_ID_CARE_GIVER';

    --department flg_type
    k_dept_flg_type_h CONSTANT VARCHAR(1 CHAR) := 'H'; --home health care
    k_hhc_flg_status_domain CONSTANT VARCHAR(23 CHAR) := 'EPIS_HHC_REQ.FLG_STATUS';

    -- wl
    k_wl_hhc_flg_type CONSTANT VARCHAR(2 CHAR) := 'HC';
    k_hhc_sch_event   CONSTANT NUMBER := 2207;

    -- detail
    k_detail_status_referral CONSTANT VARCHAR2(1 CHAR) := 'R';
    k_detail_status_referral_det  CONSTANT VARCHAR2(1 CHAR) := 'S';
    k_detail_status_referral_hist CONSTANT VARCHAR2(1 CHAR) := 'A';

END pk_hhc_constant;
/
