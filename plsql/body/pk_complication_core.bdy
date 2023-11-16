/*-- Last Change Revision: $Rev: 2026896 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:20 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_complication_core IS

    -- Private type declarations
    --TYPE < typename > IS < datatype >;

    -- Private constant declarations

    --PROFESSIONAL CLINICAL SERVICES
    g_prof_clin_serv_id t_table_prof_clin_serv := NULL;

    --CONFIGURATION TYPEs
    g_lst_cfg_typ_complication  sys_list.id_sys_list%TYPE := NULL;
    g_lst_cfg_typ_axe           sys_list.id_sys_list%TYPE := NULL;
    g_lst_cfg_typ_def_comp_path sys_list.id_sys_list%TYPE := NULL;
    g_lst_cfg_typ_def_comp_loc  sys_list.id_sys_list%TYPE := NULL;
    g_lst_cfg_typ_def_comp_ef   sys_list.id_sys_list%TYPE := NULL;
    g_lst_cfg_typ_assoc_task    sys_list.id_sys_list%TYPE := NULL;
    g_lst_cfg_typ_treat_perf    sys_list.id_sys_list%TYPE := NULL;

    --COMP_AXE TYPEs
    g_lst_axe_type_comp_cat      sys_list.id_sys_list%TYPE := NULL;
    g_lst_axe_type_path          sys_list.id_sys_list%TYPE := NULL;
    g_lst_axe_type_loc           sys_list.id_sys_list%TYPE := NULL;
    g_lst_axe_type_ext_fact      sys_list.id_sys_list%TYPE := NULL;
    g_lst_axe_type_ext_fact_med  sys_list.id_sys_list%TYPE := NULL;
    g_lst_axe_type_ext_fact_tool sys_list.id_sys_list%TYPE := NULL;
    g_lst_axe_type_eff           sys_list.id_sys_list%TYPE := NULL;
    -- associated_task
    g_lst_axe_type_at_und       sys_list.id_sys_list%TYPE := NULL;
    g_lst_axe_type_at_lab_test  sys_list.id_sys_list%TYPE := NULL;
    g_lst_axe_type_at_diet      sys_list.id_sys_list%TYPE := NULL;
    g_lst_axe_type_at_imaging   sys_list.id_sys_list%TYPE := NULL;
    g_lst_axe_type_at_exam      sys_list.id_sys_list%TYPE := NULL;
    g_lst_axe_type_at_med       sys_list.id_sys_list%TYPE := NULL;
    g_lst_axe_type_at_pos       sys_list.id_sys_list%TYPE := NULL;
    g_lst_axe_type_at_dressing  sys_list.id_sys_list%TYPE := NULL;
    g_lst_axe_type_at_proc      sys_list.id_sys_list%TYPE := NULL;
    g_lst_axe_type_at_surg_proc sys_list.id_sys_list%TYPE := NULL;
    -- other context values
    g_lst_ecd_context_type_med_lcl sys_list.id_sys_list%TYPE := NULL;
    g_lst_ecd_context_type_med_ext sys_list.id_sys_list%TYPE := NULL;
    g_lst_ecd_context_type_pos     sys_list.id_sys_list%TYPE := NULL;

    -- treatment_performed
    g_lst_axe_type_tp_lab_test    sys_list.id_sys_list%TYPE := NULL;
    g_lst_axe_type_tp_imaging     sys_list.id_sys_list%TYPE := NULL;
    g_lst_axe_type_tp_exam        sys_list.id_sys_list%TYPE := NULL;
    g_lst_axe_type_tp_med_grp     sys_list.id_sys_list%TYPE := NULL;
    g_lst_axe_type_tp_med         sys_list.id_sys_list%TYPE := NULL;
    g_lst_axe_type_tp_out_med_grp sys_list.id_sys_list%TYPE := NULL;
    g_lst_axe_type_tp_out_med     sys_list.id_sys_list%TYPE := NULL;
    g_lst_axe_type_tp_pos         sys_list.id_sys_list%TYPE := NULL;
    g_lst_axe_type_tp_proc        sys_list.id_sys_list%TYPE := NULL;
    g_lst_axe_type_tp_surg_proc   sys_list.id_sys_list%TYPE := NULL;

    g_complication_diag CONSTANT VARCHAR2(4 CHAR) := 'DIAG'; --Diagnosis
    g_complication_prof CONSTANT VARCHAR2(4 CHAR) := 'PROF'; --Professionals

    g_comp_flg_status_u CONSTANT epis_complication.flg_status_comp%TYPE := 'U'; --Under investigation
    g_comp_flg_status_c CONSTANT epis_complication.flg_status_comp%TYPE := 'C'; --Confirmed
    g_comp_flg_status_e CONSTANT epis_complication.flg_status_comp%TYPE := 'E'; --Excluded
    g_comp_flg_status_i CONSTANT epis_complication.flg_status_comp%TYPE := 'I'; --Cancelled

    g_req_flg_status_r CONSTANT epis_complication.flg_status_req%TYPE := 'R'; --Requested
    g_req_flg_status_a CONSTANT epis_complication.flg_status_req%TYPE := 'A'; --Accepted
    g_req_flg_status_i CONSTANT epis_complication.flg_status_req%TYPE := 'I'; --Rejected
    g_req_flg_status_c CONSTANT epis_complication.flg_status_req%TYPE := 'C'; --Cancelled

    g_comp_flg_status_domain CONSTANT sys_domain.code_domain%TYPE := 'EPIS_COMPLICATION.FLG_STATUS_COMP';
    g_req_flg_status_domain  CONSTANT sys_domain.code_domain%TYPE := 'EPIS_COMPLICATION.FLG_STATUS_REQ';

    g_comp_action_edt_cnc CONSTANT action.subject%TYPE := 'COMPLICATION_ACTION_EDT_CNC';
    g_comp_action_req     CONSTANT action.subject%TYPE := 'COMPLICATION_ACTION_BTN_REQ';

    --sys_message
    g_msg_none                CONSTANT sys_message.code_message%TYPE := 'COMMON_M043';
    g_msg_complication        CONSTANT sys_message.code_message%TYPE := 'COMPLICATION_MSG003'; --Complication
    g_msg_pathology           CONSTANT sys_message.code_message%TYPE := 'COMPLICATION_MSG014'; --Pathology
    g_msg_location            CONSTANT sys_message.code_message%TYPE := 'COMPLICATION_MSG015'; --Location
    g_msg_external_factors    CONSTANT sys_message.code_message%TYPE := 'COMPLICATION_MSG016'; --External factors
    g_msg_verification_date   CONSTANT sys_message.code_message%TYPE := 'COMPLICATION_MSG038'; --Verification date
    g_msg_registry_date       CONSTANT sys_message.code_message%TYPE := 'COMPLICATION_MSG011'; --Registry date
    g_msg_associated_episode  CONSTANT sys_message.code_message%TYPE := 'COMPLICATION_MSG018'; --Associated episode
    g_msg_associated_task     CONSTANT sys_message.code_message%TYPE := 'COMPLICATION_MSG004'; --Associated task
    g_msg_professionals       CONSTANT sys_message.code_message%TYPE := 'COMPLICATION_MSG040'; --Professional(s)
    g_msg_task_date           CONSTANT sys_message.code_message%TYPE := 'COMPLICATION_MSG019'; --Task date
    g_msg_task_resp_phys      CONSTANT sys_message.code_message%TYPE := 'COMPLICATION_MSG078'; --Task responsible physician
    g_msg_task_spec_phys      CONSTANT sys_message.code_message%TYPE := 'COMPLICATION_MSG079'; --Task specialist physician
    g_msg_diagnosis           CONSTANT sys_message.code_message%TYPE := 'COMPLICATION_MSG020'; --Diagnosis
    g_msg_status              CONSTANT sys_message.code_message%TYPE := 'COMPLICATION_MSG007'; --Status
    g_msg_effect              CONSTANT sys_message.code_message%TYPE := 'COMPLICATION_MSG006'; --Effect
    g_msg_treatment_performed CONSTANT sys_message.code_message%TYPE := 'COMPLICATION_MSG021'; --Treatment performed
    g_msg_notes               CONSTANT sys_message.code_message%TYPE := 'COMPLICATION_MSG048'; --Notes
    g_msg_cancel_reason       CONSTANT sys_message.code_message%TYPE := 'COMPLICATION_MSG074'; --Cancellation reason
    g_msg_cancel_notes        CONSTANT sys_message.code_message%TYPE := 'COMPLICATION_MSG075'; --Cancellation notes
    g_msg_reject_reason       CONSTANT sys_message.code_message%TYPE := 'COMPLICATION_MSG076'; --Rejection reason
    g_msg_reject_notes        CONSTANT sys_message.code_message%TYPE := 'COMPLICATION_MSG077'; --Rejection notes
    g_msg_description         CONSTANT sys_message.code_message%TYPE := 'COMPLICATION_MSG037'; --Description
    g_msg_clinical_service    CONSTANT sys_message.code_message%TYPE := 'COMPLICATION_MSG039'; --Clinical service

    g_msg_with_notes CONSTANT sys_message.code_message%TYPE := 'COMPLICATION_MSG073';
    g_msg_any        CONSTANT sys_message.code_message%TYPE := 'COMMON_M059'; --Any

    g_epis_comp_curr_row CONSTANT epis_complication.id_epis_complication%TYPE := -1;

    g_encrypted_text CONSTANT VARCHAR2(15) := 'xxxxxxxxxxx xxx';

    --EPIS_COMPLICATION COLUMNS
    g_col_name_id_epis_comp      CONSTANT VARCHAR2(30 CHAR) := 'ID_EPIS_COMPLICATION'; --ID_EPIS_COMPLICATION
    g_col_name_id_episode        CONSTANT VARCHAR2(30 CHAR) := 'ID_EPISODE'; --ID_EPISODE
    g_col_name_id_episode_origin CONSTANT VARCHAR2(30 CHAR) := 'ID_EPISODE_ORIGIN'; --ID_EPISODE_ORIGIN
    g_col_name_id_complication   CONSTANT VARCHAR2(30 CHAR) := 'ID_COMPLICATION'; --ID_COMPLICATION
    g_col_name_description       CONSTANT VARCHAR2(30 CHAR) := 'DESCRIPTION'; --DESCRIPTION
    g_col_name_dt_verif_comp     CONSTANT VARCHAR2(30 CHAR) := 'DT_VERIF_COMP'; --DT_VERIF_COMP
    g_col_name_dt_verif_req      CONSTANT VARCHAR2(30 CHAR) := 'DT_VERIF_REQ'; --DT_VERIF_REQ
    g_col_name_flg_status_comp   CONSTANT VARCHAR2(30 CHAR) := 'FLG_STATUS_COMP'; --FLG_STATUS_COMP
    g_col_name_flg_status_req    CONSTANT VARCHAR2(30 CHAR) := 'FLG_STATUS_REQ'; --FLG_STATUS_REQ
    g_col_name_notes_comp        CONSTANT VARCHAR2(30 CHAR) := 'NOTES_COMP'; --NOTES_COMP
    g_col_name_notes_req         CONSTANT VARCHAR2(30 CHAR) := 'NOTES_REQ'; --NOTES_REQ
    g_col_name_pathologies       CONSTANT VARCHAR2(30 CHAR) := 'PATHOLOGIES'; --PATHOLOGIES
    g_col_name_locations         CONSTANT VARCHAR2(30 CHAR) := 'LOCATIONS'; --LOCATIONS
    g_col_name_external_factors  CONSTANT VARCHAR2(30 CHAR) := 'EXTERNAL_FACTORS'; --EXTERNAL_FACTORS
    g_col_name_associated_tasks  CONSTANT VARCHAR2(30 CHAR) := 'ASSOCIATED_TASKS'; --ASSOCIATED_TASKS
    g_col_name_assoc_task_profs  CONSTANT VARCHAR2(30 CHAR) := 'ASSOC_TASK_PROFS'; --ASSOC_TASK_PROFS
    g_col_name_req_profs         CONSTANT VARCHAR2(30 CHAR) := 'REQ_PROFS'; --REQ_PROFS
    g_col_name_req_clin_serv     CONSTANT VARCHAR2(30 CHAR) := 'REQ_CLIN_SERV'; --REQ_CLIN_SERV
    g_col_name_diagnosis         CONSTANT VARCHAR2(30 CHAR) := 'DIAGNOSIS'; --DIAGNOSIS
    g_col_name_diagnosis_desc    CONSTANT VARCHAR2(30 CHAR) := 'DIAGNOSIS_DESC'; --DIAGNOSIS_DESC
    g_col_name_effects           CONSTANT VARCHAR2(30 CHAR) := 'EFFECTS'; --EFFECTS
    g_col_name_treats_performed  CONSTANT VARCHAR2(30 CHAR) := 'TREATMENTS_PERFORMED'; --TREATMENTS_PERFORMED
    g_col_name_prof_clin_serv    CONSTANT VARCHAR2(30 CHAR) := 'ID_PROF_CLIN_SERV'; --ID_PROF_CLIN_SERV

    --COL_INFO TYPE
    g_col_info_typ_num     CONSTANT VARCHAR2(30 CHAR) := 'NUM'; --NUM
    g_col_info_typ_str     CONSTANT VARCHAR2(30 CHAR) := 'STR'; --STR
    g_col_info_typ_date    CONSTANT VARCHAR2(30 CHAR) := 'DATE'; --DATE
    g_col_info_typ_flg     CONSTANT VARCHAR2(30 CHAR) := 'FLG'; --FLG
    g_col_info_typ_tbl_num CONSTANT VARCHAR2(30 CHAR) := 'TBL_NUM'; --TBL_NUM
    g_col_info_typ_tbl_str CONSTANT VARCHAR2(30 CHAR) := 'TBL_STR'; --TBL_STR

    --PK_API_COMPLICATIONS.GET_TASK_DET - FLG_TYPE
    g_flg_task_det_n CONSTANT VARCHAR2(1 CHAR) := 'N'; --Task description

    --String delim
    g_delim_1           CONSTANT VARCHAR2(1 CHAR) := '|';
    g_delim_2           CONSTANT VARCHAR2(1 CHAR) := ';';
    g_delim_req_prof    CONSTANT VARCHAR2(1 CHAR) := ';';
    g_delim_screen_show CONSTANT VARCHAR2(2 CHAR) := '; ';

    -- Private variable declarations
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;

    g_sys_cfg_show_code CONSTANT sys_config.id_sys_config%TYPE := 'EPIS_COMP_SHOW_CODE';
    g_is_to_show_code VARCHAR2(1 CHAR) := NULL;

    g_sys_alert CONSTANT sys_alert.id_sys_alert%TYPE := 90;

    --Already processed epis_comp_detail records
    g_proc_epis_comp_detail table_number;

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Function and procedure implementations

    PROCEDURE set_pck_sysdate(i_date TIMESTAMP WITH LOCAL TIME ZONE) IS
        l_proc_name VARCHAR2(30) := 'SET_PCK_SYSDATE';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
    
        g_sysdate_tstz := i_date;
    END set_pck_sysdate;

    FUNCTION get_pck_sysdate RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
        l_func_name VARCHAR2(30) := 'GET_PCK_SYSDATE';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        RETURN g_sysdate_tstz;
    END get_pck_sysdate;

    FUNCTION get_type
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_grp_internal_name IN sys_list_group.internal_name%TYPE,
        i_flg_context       IN sys_list_group_rel.flg_context%TYPE
    ) RETURN sys_list.id_sys_list%TYPE IS
        l_func_name VARCHAR2(30) := 'GET_TYPE';
        --
        l_sys_list sys_list.id_sys_list%TYPE;
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'GET ID_SYS_LIST FOR GRP: ' || i_grp_internal_name || '; FLG_CONT: ' || i_flg_context;
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_sys_list := pk_sys_list.get_id_sys_list(i_lang              => i_lang,
                                                  i_prof              => i_prof,
                                                  i_grp_internal_name => i_grp_internal_name,
                                                  i_flg_context       => i_flg_context);
    
        RETURN l_sys_list;
    END get_type;

    --CONFIGURATION TYPEs
    FUNCTION get_cfg_typ_complication
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE IS
        l_func_name VARCHAR2(30) := 'GET_CFG_TYP_COMPLICATION';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        IF g_lst_cfg_typ_complication IS NULL
        THEN
            g_error := 'GET TYPE';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            g_lst_cfg_typ_complication := get_type(i_lang              => i_lang,
                                                   i_prof              => i_prof,
                                                   i_grp_internal_name => pk_complication_core.g_lst_grp_cfg_type,
                                                   i_flg_context       => pk_complication_core.g_flg_cfg_typ_complication);
        END IF;
    
        RETURN g_lst_cfg_typ_complication;
    END get_cfg_typ_complication;

    FUNCTION get_cfg_typ_axe
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE IS
        l_func_name VARCHAR2(30) := 'GET_CFG_TYP_AXE';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        IF g_lst_cfg_typ_axe IS NULL
        THEN
            g_error := 'GET TYPE';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            g_lst_cfg_typ_axe := get_type(i_lang              => i_lang,
                                          i_prof              => i_prof,
                                          i_grp_internal_name => pk_complication_core.g_lst_grp_cfg_type,
                                          i_flg_context       => pk_complication_core.g_flg_cfg_typ_axe);
        END IF;
    
        RETURN g_lst_cfg_typ_axe;
    END get_cfg_typ_axe;

    FUNCTION get_cfg_typ_def_comp_path
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE IS
        l_func_name VARCHAR2(30) := 'GET_CFG_TYP_DEF_COMP_PATH';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        IF g_lst_cfg_typ_def_comp_path IS NULL
        THEN
            g_error := 'GET TYPE';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            g_lst_cfg_typ_def_comp_path := get_type(i_lang              => i_lang,
                                                    i_prof              => i_prof,
                                                    i_grp_internal_name => pk_complication_core.g_lst_grp_cfg_dft_type,
                                                    i_flg_context       => pk_complication_core.g_flg_cfg_typ_def_comp_path);
        END IF;
    
        RETURN g_lst_cfg_typ_def_comp_path;
    END get_cfg_typ_def_comp_path;

    FUNCTION get_cfg_typ_def_comp_loc
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE IS
        l_func_name VARCHAR2(30) := 'GET_CFG_TYP_DEF_COMP_LOC';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        IF g_lst_cfg_typ_def_comp_loc IS NULL
        THEN
            g_error := 'GET TYPE';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            g_lst_cfg_typ_def_comp_loc := get_type(i_lang              => i_lang,
                                                   i_prof              => i_prof,
                                                   i_grp_internal_name => pk_complication_core.g_lst_grp_cfg_dft_type,
                                                   i_flg_context       => pk_complication_core.g_flg_cfg_typ_def_comp_loc);
        END IF;
    
        RETURN g_lst_cfg_typ_def_comp_loc;
    END get_cfg_typ_def_comp_loc;

    FUNCTION get_cfg_typ_def_comp_ext_fact
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE IS
        l_func_name VARCHAR2(30) := 'GET_CFG_TYP_DEF_COMP_EXT_FACT';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        IF g_lst_cfg_typ_def_comp_ef IS NULL
        THEN
            g_error := 'GET TYPE';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            g_lst_cfg_typ_def_comp_ef := get_type(i_lang              => i_lang,
                                                  i_prof              => i_prof,
                                                  i_grp_internal_name => pk_complication_core.g_lst_grp_cfg_dft_type,
                                                  i_flg_context       => pk_complication_core.g_flg_cfg_typ_def_comp_et);
        END IF;
    
        RETURN g_lst_cfg_typ_def_comp_ef;
    END get_cfg_typ_def_comp_ext_fact;

    FUNCTION get_cfg_typ_assoc_task
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE IS
        l_func_name VARCHAR2(30) := 'GET_CFG_TYP_ASSOC_TASK';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        IF g_lst_cfg_typ_assoc_task IS NULL
        THEN
            g_error := 'GET TYPE';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            g_lst_cfg_typ_assoc_task := get_type(i_lang              => i_lang,
                                                 i_prof              => i_prof,
                                                 i_grp_internal_name => pk_complication_core.g_lst_grp_cfg_type,
                                                 i_flg_context       => pk_complication_core.g_flg_cfg_typ_assoc_task);
        END IF;
    
        RETURN g_lst_cfg_typ_assoc_task;
    END get_cfg_typ_assoc_task;

    FUNCTION get_cfg_typ_treat_perf
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE IS
        l_func_name VARCHAR2(30) := 'GET_CFG_TYPE_COMPLICATION';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        IF g_lst_cfg_typ_treat_perf IS NULL
        THEN
            g_error := 'GET TYPE';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            g_lst_cfg_typ_treat_perf := get_type(i_lang              => i_lang,
                                                 i_prof              => i_prof,
                                                 i_grp_internal_name => pk_complication_core.g_lst_grp_cfg_type,
                                                 i_flg_context       => pk_complication_core.g_flg_cfg_typ_treat_perf);
        END IF;
    
        RETURN g_lst_cfg_typ_treat_perf;
    END get_cfg_typ_treat_perf;

    --COMP_AXE TYPEs
    FUNCTION get_axe_typ_comp_cat
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE IS
        l_func_name VARCHAR2(30) := 'GET_AXE_TYP_COMP_CAT';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        IF g_lst_axe_type_comp_cat IS NULL
        THEN
            g_error := 'GET TYPE';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            g_lst_axe_type_comp_cat := get_type(i_lang              => i_lang,
                                                i_prof              => i_prof,
                                                i_grp_internal_name => pk_complication_core.g_lst_grp_axe_types,
                                                i_flg_context       => pk_complication_core.g_flg_axe_type_comp_cat);
        END IF;
    
        RETURN g_lst_axe_type_comp_cat;
    END get_axe_typ_comp_cat;

    FUNCTION get_axe_typ_path
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE IS
        l_func_name VARCHAR2(30) := 'GET_AXE_TYP_COMP_CAT';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        IF g_lst_axe_type_path IS NULL
        THEN
            g_error := 'GET TYPE';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            g_lst_axe_type_path := get_type(i_lang              => i_lang,
                                            i_prof              => i_prof,
                                            i_grp_internal_name => pk_complication_core.g_lst_grp_axe_types,
                                            i_flg_context       => pk_complication_core.g_flg_axe_type_path);
        END IF;
    
        RETURN g_lst_axe_type_path;
    END get_axe_typ_path;

    FUNCTION get_axe_typ_loc
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE IS
        l_func_name VARCHAR2(30) := 'GET_AXE_TYP_COMP_CAT';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        IF g_lst_axe_type_loc IS NULL
        THEN
            g_error := 'GET TYPE';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            g_lst_axe_type_loc := get_type(i_lang              => i_lang,
                                           i_prof              => i_prof,
                                           i_grp_internal_name => pk_complication_core.g_lst_grp_axe_types,
                                           i_flg_context       => pk_complication_core.g_flg_axe_type_loc);
        END IF;
    
        RETURN g_lst_axe_type_loc;
    END get_axe_typ_loc;

    FUNCTION get_axe_typ_ext_fact
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE IS
        l_func_name VARCHAR2(30) := 'GET_AXE_TYP_COMP_CAT';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        IF g_lst_axe_type_ext_fact IS NULL
        THEN
            g_error := 'GET TYPE';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            g_lst_axe_type_ext_fact := get_type(i_lang              => i_lang,
                                                i_prof              => i_prof,
                                                i_grp_internal_name => pk_complication_core.g_lst_grp_axe_types,
                                                i_flg_context       => pk_complication_core.g_flg_axe_type_ext_fact);
        END IF;
    
        RETURN g_lst_axe_type_ext_fact;
    END get_axe_typ_ext_fact;

    FUNCTION get_axe_typ_ext_fact_med
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE IS
        l_func_name VARCHAR2(30) := 'GET_AXE_TYP_COMP_CAT';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        IF g_lst_axe_type_ext_fact_med IS NULL
        THEN
            g_error := 'GET TYPE';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            g_lst_axe_type_ext_fact_med := get_type(i_lang              => i_lang,
                                                    i_prof              => i_prof,
                                                    i_grp_internal_name => pk_complication_core.g_lst_grp_axe_types,
                                                    i_flg_context       => pk_complication_core.g_flg_axe_type_ext_fact_med);
        END IF;
    
        RETURN g_lst_axe_type_ext_fact_med;
    END get_axe_typ_ext_fact_med;

    FUNCTION get_axe_typ_ext_fact_tool
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE IS
        l_func_name VARCHAR2(30) := 'GET_AXE_TYP_COMP_CAT';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        IF g_lst_axe_type_ext_fact_tool IS NULL
        THEN
            g_error := 'GET TYPE';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            g_lst_axe_type_ext_fact_tool := get_type(i_lang              => i_lang,
                                                     i_prof              => i_prof,
                                                     i_grp_internal_name => pk_complication_core.g_lst_grp_axe_types,
                                                     i_flg_context       => pk_complication_core.g_flg_axe_type_ext_fact_tool);
        END IF;
    
        RETURN g_lst_axe_type_ext_fact_tool;
    END get_axe_typ_ext_fact_tool;

    FUNCTION get_axe_typ_eff
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE IS
        l_func_name VARCHAR2(30) := 'GET_AXE_TYP_COMP_CAT';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        IF g_lst_axe_type_eff IS NULL
        THEN
            g_error := 'GET TYPE';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            g_lst_axe_type_eff := get_type(i_lang              => i_lang,
                                           i_prof              => i_prof,
                                           i_grp_internal_name => pk_complication_core.g_lst_grp_axe_types,
                                           i_flg_context       => pk_complication_core.g_flg_axe_type_eff);
        END IF;
    
        RETURN g_lst_axe_type_eff;
    END get_axe_typ_eff;

    -- associated_task
    FUNCTION get_axe_typ_at_und
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE IS
        l_func_name VARCHAR2(30) := 'GET_AXE_TYP_COMP_CAT';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        IF g_lst_axe_type_at_und IS NULL
        THEN
            g_error := 'GET TYPE';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            g_lst_axe_type_at_und := get_type(i_lang              => i_lang,
                                              i_prof              => i_prof,
                                              i_grp_internal_name => pk_complication_core.g_lst_grp_axe_at_types,
                                              i_flg_context       => pk_complication_core.g_flg_axe_type_at_undefined);
        END IF;
    
        RETURN g_lst_axe_type_at_und;
    END get_axe_typ_at_und;

    FUNCTION get_axe_typ_at_lab_test
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE IS
        l_func_name VARCHAR2(30) := 'GET_AXE_TYP_COMP_CAT';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        IF g_lst_axe_type_at_lab_test IS NULL
        THEN
            g_error := 'GET TYPE';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            g_lst_axe_type_at_lab_test := get_type(i_lang              => i_lang,
                                                   i_prof              => i_prof,
                                                   i_grp_internal_name => pk_complication_core.g_lst_grp_axe_at_types,
                                                   i_flg_context       => pk_complication_core.g_flg_axe_type_at_lab_test);
        END IF;
    
        RETURN g_lst_axe_type_at_lab_test;
    END get_axe_typ_at_lab_test;

    FUNCTION get_axe_typ_at_diet
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE IS
        l_func_name VARCHAR2(30) := 'GET_AXE_TYP_COMP_CAT';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        IF g_lst_axe_type_at_diet IS NULL
        THEN
            g_error := 'GET TYPE';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            g_lst_axe_type_at_diet := get_type(i_lang              => i_lang,
                                               i_prof              => i_prof,
                                               i_grp_internal_name => pk_complication_core.g_lst_grp_axe_at_types,
                                               i_flg_context       => pk_complication_core.g_flg_axe_type_at_diet);
        END IF;
    
        RETURN g_lst_axe_type_at_diet;
    END get_axe_typ_at_diet;

    FUNCTION get_axe_typ_at_imaging
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE IS
        l_func_name VARCHAR2(30) := 'GET_AXE_TYP_COMP_CAT';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        IF g_lst_axe_type_at_imaging IS NULL
        THEN
            g_error := 'GET TYPE';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            g_lst_axe_type_at_imaging := get_type(i_lang              => i_lang,
                                                  i_prof              => i_prof,
                                                  i_grp_internal_name => pk_complication_core.g_lst_grp_axe_at_types,
                                                  i_flg_context       => pk_complication_core.g_flg_axe_type_at_imaging);
        END IF;
    
        RETURN g_lst_axe_type_at_imaging;
    END get_axe_typ_at_imaging;

    FUNCTION get_axe_typ_at_exam
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE IS
        l_func_name VARCHAR2(30) := 'GET_AXE_TYP_COMP_CAT';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        IF g_lst_axe_type_at_exam IS NULL
        THEN
            g_error := 'GET TYPE';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            g_lst_axe_type_at_exam := get_type(i_lang              => i_lang,
                                               i_prof              => i_prof,
                                               i_grp_internal_name => pk_complication_core.g_lst_grp_axe_at_types,
                                               i_flg_context       => pk_complication_core.g_flg_axe_type_at_exam);
        END IF;
    
        RETURN g_lst_axe_type_at_exam;
    END get_axe_typ_at_exam;

    FUNCTION get_axe_typ_at_med
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE IS
        l_func_name VARCHAR2(30) := 'GET_AXE_TYP_COMP_CAT';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        IF g_lst_axe_type_at_med IS NULL
        THEN
            g_error := 'GET TYPE';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            g_lst_axe_type_at_med := get_type(i_lang              => i_lang,
                                              i_prof              => i_prof,
                                              i_grp_internal_name => pk_complication_core.g_lst_grp_axe_at_types,
                                              i_flg_context       => pk_complication_core.g_flg_axe_type_at_med);
        END IF;
    
        RETURN g_lst_axe_type_at_med;
    END get_axe_typ_at_med;

    FUNCTION get_axe_typ_at_pos
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE IS
        l_func_name VARCHAR2(30) := 'GET_AXE_TYP_COMP_CAT';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        IF g_lst_axe_type_at_pos IS NULL
        THEN
            g_error := 'GET TYPE';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            g_lst_axe_type_at_pos := get_type(i_lang              => i_lang,
                                              i_prof              => i_prof,
                                              i_grp_internal_name => pk_complication_core.g_lst_grp_axe_at_types,
                                              i_flg_context       => pk_complication_core.g_flg_axe_type_at_pos);
        END IF;
    
        RETURN g_lst_axe_type_at_pos;
    END get_axe_typ_at_pos;

    FUNCTION get_axe_typ_at_dressing
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE IS
        l_func_name VARCHAR2(30) := 'GET_AXE_TYP_COMP_CAT';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        IF g_lst_axe_type_at_dressing IS NULL
        THEN
            g_error := 'GET TYPE';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            g_lst_axe_type_at_dressing := get_type(i_lang              => i_lang,
                                                   i_prof              => i_prof,
                                                   i_grp_internal_name => pk_complication_core.g_lst_grp_axe_at_types,
                                                   i_flg_context       => pk_complication_core.g_flg_axe_type_at_dressing);
        END IF;
    
        RETURN g_lst_axe_type_at_dressing;
    END get_axe_typ_at_dressing;

    FUNCTION get_axe_typ_at_proc
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE IS
        l_func_name VARCHAR2(30) := 'GET_AXE_TYP_COMP_CAT';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        IF g_lst_axe_type_at_proc IS NULL
        THEN
            g_error := 'GET TYPE';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            g_lst_axe_type_at_proc := get_type(i_lang              => i_lang,
                                               i_prof              => i_prof,
                                               i_grp_internal_name => pk_complication_core.g_lst_grp_axe_at_types,
                                               i_flg_context       => pk_complication_core.g_flg_axe_type_at_proc);
        END IF;
    
        RETURN g_lst_axe_type_at_proc;
    END get_axe_typ_at_proc;

    FUNCTION get_axe_typ_at_surg_proc
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE IS
        l_func_name VARCHAR2(30) := 'GET_AXE_TYP_COMP_CAT';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        IF g_lst_axe_type_at_surg_proc IS NULL
        THEN
            g_error := 'GET TYPE';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            g_lst_axe_type_at_surg_proc := get_type(i_lang              => i_lang,
                                                    i_prof              => i_prof,
                                                    i_grp_internal_name => pk_complication_core.g_lst_grp_axe_at_types,
                                                    i_flg_context       => pk_complication_core.g_flg_axe_type_at_surg_proc);
        END IF;
    
        RETURN g_lst_axe_type_at_surg_proc;
    END get_axe_typ_at_surg_proc;

    -- other context values
    FUNCTION get_ecd_typ_med_lcl
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE IS
        l_func_name VARCHAR2(30) := 'GET_AXE_TYP_COMP_CAT';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        IF g_lst_ecd_context_type_med_lcl IS NULL
        THEN
            g_error := 'GET TYPE';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            g_lst_ecd_context_type_med_lcl := get_type(i_lang              => i_lang,
                                                       i_prof              => i_prof,
                                                       i_grp_internal_name => pk_complication_core.g_lst_grp_ecd_at_types,
                                                       i_flg_context       => pk_complication_core.g_flg_ecd_context_type_med_lcl);
        END IF;
    
        RETURN g_lst_ecd_context_type_med_lcl;
    END get_ecd_typ_med_lcl;

    FUNCTION get_ecd_typ_med_ext
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE IS
        l_func_name VARCHAR2(30) := 'GET_AXE_TYP_COMP_CAT';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        IF g_lst_ecd_context_type_med_ext IS NULL
        THEN
            g_error := 'GET TYPE';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            g_lst_ecd_context_type_med_ext := get_type(i_lang              => i_lang,
                                                       i_prof              => i_prof,
                                                       i_grp_internal_name => pk_complication_core.g_lst_grp_ecd_at_types,
                                                       i_flg_context       => pk_complication_core.g_flg_ecd_context_type_med_ext);
        END IF;
    
        RETURN g_lst_ecd_context_type_med_ext;
    END get_ecd_typ_med_ext;

    FUNCTION get_ecd_typ_pos
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE IS
        l_func_name VARCHAR2(30) := 'GET_AXE_TYP_COMP_CAT';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        IF g_lst_ecd_context_type_pos IS NULL
        THEN
            g_error := 'GET TYPE';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            g_lst_ecd_context_type_pos := get_type(i_lang              => i_lang,
                                                   i_prof              => i_prof,
                                                   i_grp_internal_name => pk_complication_core.g_lst_grp_ecd_at_types,
                                                   i_flg_context       => pk_complication_core.g_flg_ecd_context_type_pos);
        END IF;
    
        RETURN g_lst_ecd_context_type_pos;
    END get_ecd_typ_pos;

    -- treatment_performed
    FUNCTION get_axe_typ_tp_lab_test
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE IS
        l_func_name VARCHAR2(30) := 'GET_AXE_TYP_COMP_CAT';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        IF g_lst_axe_type_tp_lab_test IS NULL
        THEN
            g_error := 'GET TYPE';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            g_lst_axe_type_tp_lab_test := get_type(i_lang              => i_lang,
                                                   i_prof              => i_prof,
                                                   i_grp_internal_name => pk_complication_core.g_lst_grp_axe_tp_types,
                                                   i_flg_context       => pk_complication_core.g_flg_axe_type_tp_lab_test);
        END IF;
    
        RETURN g_lst_axe_type_tp_lab_test;
    END get_axe_typ_tp_lab_test;

    FUNCTION get_axe_typ_tp_imaging
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE IS
        l_func_name VARCHAR2(30) := 'GET_AXE_TYP_COMP_CAT';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        IF g_lst_axe_type_tp_imaging IS NULL
        THEN
            g_error := 'GET TYPE';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            g_lst_axe_type_tp_imaging := get_type(i_lang              => i_lang,
                                                  i_prof              => i_prof,
                                                  i_grp_internal_name => pk_complication_core.g_lst_grp_axe_tp_types,
                                                  i_flg_context       => pk_complication_core.g_flg_axe_type_tp_imaging);
        END IF;
    
        RETURN g_lst_axe_type_tp_imaging;
    END get_axe_typ_tp_imaging;

    FUNCTION get_axe_typ_tp_exam
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE IS
        l_func_name VARCHAR2(30) := 'GET_AXE_TYP_COMP_CAT';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        IF g_lst_axe_type_tp_exam IS NULL
        THEN
            g_error := 'GET TYPE';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            g_lst_axe_type_tp_exam := get_type(i_lang              => i_lang,
                                               i_prof              => i_prof,
                                               i_grp_internal_name => pk_complication_core.g_lst_grp_axe_tp_types,
                                               i_flg_context       => pk_complication_core.g_flg_axe_type_tp_exam);
        END IF;
    
        RETURN g_lst_axe_type_tp_exam;
    END get_axe_typ_tp_exam;

    FUNCTION get_axe_typ_tp_med_grp
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE IS
        l_func_name VARCHAR2(30) := 'GET_AXE_TYP_COMP_CAT';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        IF g_lst_axe_type_tp_med_grp IS NULL
        THEN
            g_error := 'GET TYPE';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            g_lst_axe_type_tp_med_grp := get_type(i_lang              => i_lang,
                                                  i_prof              => i_prof,
                                                  i_grp_internal_name => pk_complication_core.g_lst_grp_axe_tp_types,
                                                  i_flg_context       => pk_complication_core.g_flg_axe_type_tp_med_grp);
        END IF;
    
        RETURN g_lst_axe_type_tp_med_grp;
    END get_axe_typ_tp_med_grp;

    FUNCTION get_axe_typ_tp_med
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE IS
        l_func_name VARCHAR2(30) := 'GET_AXE_TYP_COMP_CAT';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        IF g_lst_axe_type_tp_med IS NULL
        THEN
            g_error := 'GET TYPE';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            g_lst_axe_type_tp_med := get_type(i_lang              => i_lang,
                                              i_prof              => i_prof,
                                              i_grp_internal_name => pk_complication_core.g_lst_grp_axe_tp_types,
                                              i_flg_context       => pk_complication_core.g_flg_axe_type_tp_med);
        END IF;
    
        RETURN g_lst_axe_type_tp_med;
    END get_axe_typ_tp_med;

    FUNCTION get_axe_typ_tp_out_med_grp
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE IS
        l_func_name VARCHAR2(30) := 'GET_AXE_TYP_COMP_CAT';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        IF g_lst_axe_type_tp_out_med_grp IS NULL
        THEN
            g_error := 'GET TYPE';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            g_lst_axe_type_tp_out_med_grp := get_type(i_lang              => i_lang,
                                                      i_prof              => i_prof,
                                                      i_grp_internal_name => pk_complication_core.g_lst_grp_axe_tp_types,
                                                      i_flg_context       => pk_complication_core.g_flg_axe_type_tp_out_med_grp);
        END IF;
    
        RETURN g_lst_axe_type_tp_out_med_grp;
    END get_axe_typ_tp_out_med_grp;

    FUNCTION get_axe_typ_tp_out_med
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE IS
        l_func_name VARCHAR2(30) := 'GET_AXE_TYP_COMP_CAT';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        IF g_lst_axe_type_tp_out_med IS NULL
        THEN
            g_error := 'GET TYPE';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            g_lst_axe_type_tp_out_med := get_type(i_lang              => i_lang,
                                                  i_prof              => i_prof,
                                                  i_grp_internal_name => pk_complication_core.g_lst_grp_axe_tp_types,
                                                  i_flg_context       => pk_complication_core.g_flg_axe_type_tp_out_med);
        END IF;
    
        RETURN g_lst_axe_type_tp_out_med;
    END get_axe_typ_tp_out_med;

    FUNCTION get_axe_typ_tp_pos
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE IS
        l_func_name VARCHAR2(30) := 'GET_AXE_TYP_COMP_CAT';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        IF g_lst_axe_type_tp_pos IS NULL
        THEN
            g_error := 'GET TYPE';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            g_lst_axe_type_tp_pos := get_type(i_lang              => i_lang,
                                              i_prof              => i_prof,
                                              i_grp_internal_name => pk_complication_core.g_lst_grp_axe_tp_types,
                                              i_flg_context       => pk_complication_core.g_flg_axe_type_tp_pos);
        END IF;
    
        RETURN g_lst_axe_type_tp_pos;
    END get_axe_typ_tp_pos;

    FUNCTION get_axe_typ_tp_proc
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE IS
        l_func_name VARCHAR2(30) := 'GET_AXE_TYP_COMP_CAT';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        IF g_lst_axe_type_tp_proc IS NULL
        THEN
            g_error := 'GET TYPE';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            g_lst_axe_type_tp_proc := get_type(i_lang              => i_lang,
                                               i_prof              => i_prof,
                                               i_grp_internal_name => pk_complication_core.g_lst_grp_axe_tp_types,
                                               i_flg_context       => pk_complication_core.g_flg_axe_type_tp_proc);
        END IF;
    
        RETURN g_lst_axe_type_tp_proc;
    END get_axe_typ_tp_proc;

    FUNCTION get_axe_typ_tp_surg_proc
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE IS
        l_func_name VARCHAR2(30) := 'GET_AXE_TYP_COMP_CAT';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        IF g_lst_axe_type_tp_surg_proc IS NULL
        THEN
            g_error := 'GET TYPE';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            g_lst_axe_type_tp_surg_proc := get_type(i_lang              => i_lang,
                                                    i_prof              => i_prof,
                                                    i_grp_internal_name => pk_complication_core.g_lst_grp_axe_tp_types,
                                                    i_flg_context       => pk_complication_core.g_flg_axe_type_tp_surg_proc);
        END IF;
    
        RETURN g_lst_axe_type_tp_surg_proc;
    END get_axe_typ_tp_surg_proc;

    FUNCTION get_prof_clin_serv_id
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN t_table_prof_clin_serv IS
        l_func_name VARCHAR2(30) := 'GET_PROF_CLIN_SERV_ID';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        IF g_prof_clin_serv_id IS NULL
        THEN
            g_error := 'GET PROF_CLIN_SERV TABLE';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            g_prof_clin_serv_id := pk_prof_utils.tf_prof_clin_serv_list(i_lang => i_lang, i_prof => i_prof);
        END IF;
    
        RETURN g_prof_clin_serv_id;
    END get_prof_clin_serv_id;

    /**
    * Verifies if the specified column is visible to the current user
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_ec_clin_serv_dest         Episode complication clinical service dest
    * @param   i_ec_prof_clin_serv         Episode complication register prof clinical service
    * @param   i_column_name               Column name
    * @param   i_is_request                'Y' - request; 'N' - complication
    *
    * @return  'Y' if column is visible, 'N' otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   18-12-2009
    */
    FUNCTION is_column_visible
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_ec_clin_serv_dest IN epis_complication.id_clin_serv_dest%TYPE,
        i_ec_prof_clin_serv IN epis_complication.id_prof_clin_serv%TYPE,
        i_column_name       IN VARCHAR2,
        i_is_request        IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(30) := 'IS_COLUMN_VISIBLE';
        --
        l_is_visible        comp_cols_visibility.flg_visible%TYPE := pk_alert_constant.g_no;
        l_prof_clin_serv_id t_table_prof_clin_serv;
        l_is_request        VARCHAR2(1);
        l_column_name       VARCHAR2(30 CHAR);
        l_conf_type         sys_list_group_rel.flg_context%TYPE;
        l_sys_list          sys_list.id_sys_list%TYPE;
        --
        l_total_ec_cs_dest PLS_INTEGER;
        l_total_ec_pcs     PLS_INTEGER;
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'GET PROFESSIONAL CLINICAL SERVICE ID';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_prof_clin_serv_id := get_prof_clin_serv_id(i_lang => i_lang, i_prof => i_prof);
    
        g_error := 'GET TOTAL EC_CS_DEST';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        SELECT COUNT(t.id_clinical_service)
          INTO l_total_ec_cs_dest
          FROM TABLE(l_prof_clin_serv_id) t
         WHERE t.id_clinical_service = i_ec_clin_serv_dest;
    
        g_error := 'GET TOTAL EC_PDS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        SELECT COUNT(t.id_clinical_service)
          INTO l_total_ec_pcs
          FROM TABLE(l_prof_clin_serv_id) t
         WHERE t.id_clinical_service = i_ec_prof_clin_serv;
    
        g_error := 'CHANGE COLUMN CAPS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_column_name := upper(i_column_name);
    
        g_error := 'VERIFY IF THE COLUMN IS REQUEST COL';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF i_is_request IS NULL
        THEN
            IF (l_column_name LIKE '%REQ%' OR l_column_name = 'DESCRIPTION')
            THEN
                l_is_request := pk_alert_constant.g_yes;
            ELSE
                l_is_request := pk_alert_constant.g_no;
            END IF;
        ELSE
            l_is_request := i_is_request;
        END IF;
    
        IF l_total_ec_pcs > 0
           OR (l_is_request = pk_alert_constant.g_yes AND l_total_ec_cs_dest > 0)
        THEN
            l_is_visible := pk_alert_constant.g_yes;
        ELSE
            g_error := 'MAP COLUMN NAME WITH FLG_COL_NAME';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            CASE
            --COMPLICATION COLUMNS
                WHEN l_column_name IN ('ID_COMPLICATION', 'DESC_COMPLICATION') THEN
                    l_conf_type := 'C'; --Complication
                WHEN l_column_name IN ('PATHOLOGY') THEN
                    l_conf_type := 'P'; --Pathology
                WHEN l_column_name IN ('LOCATION') THEN
                    l_conf_type := 'L'; --Location
                WHEN l_column_name IN ('EXTERNAL_FACTOR') THEN
                    l_conf_type := 'EF'; --External factors
                WHEN l_column_name IN ('DT_VERIF_COMP', 'DT_VERIF_COMP_CHR') THEN
                    l_conf_type := 'VD'; --Verification date
                WHEN l_column_name IN ('REGISTRY_DATE_CHR', 'REGISTRY_DATE') THEN
                    l_conf_type := 'RD'; --Registry date
                WHEN l_column_name IN ('ID_EPISODE_ORIGIN', 'DESC_EPISODE_ORIGIN') THEN
                    l_conf_type := 'AE'; --Associated episode
                WHEN l_column_name IN ('DESC_ASSOC_TASK', 'ASSOCIATED_TASK') THEN
                    l_conf_type := 'AT'; --Associated task
                WHEN l_column_name IN ('ASSOCIATED_TASK_DT') THEN
                    l_conf_type := 'TD'; --Task date
                WHEN l_column_name IN ('DIAGNOSE') THEN
                    l_conf_type := 'D'; --Diagnosis
                WHEN l_column_name IN ('FLG_STATUS', 'DESC_STATUS') THEN
                    l_conf_type := 'CS'; --Status
                WHEN l_column_name IN ('EFFECT') THEN
                    l_conf_type := 'E'; --Effect
                WHEN l_column_name IN ('TREATMENT_PERFORMED') THEN
                    l_conf_type := 'TP'; --Treatment performed
                WHEN l_column_name IN ('FLG_HAS_NOTES', 'NOTES_COMP', 'NOTES_CANCEL') THEN
                    l_conf_type := 'CN'; --Notes
                WHEN l_column_name IN ('REGISTERED_BY', 'PROFESSIONAL') THEN
                    l_conf_type := 'PR'; --Professional
                WHEN l_column_name IN ('CLINICAL_SERVICE') THEN
                    l_conf_type := 'CL'; --Clinical service
            --REQUEST COLUMNS
                WHEN l_column_name IN ('DESCRIPTION') THEN
                    l_conf_type := 'RD'; --Description
                WHEN l_column_name IN ('DT_VERIF_REQ', 'DT_VERIF_REQ_CHR') THEN
                    l_conf_type := 'VD'; --Verification date
                WHEN l_column_name IN ('REQ_REGISTRY_DATE_CHR', 'REQ_REGISTRY_DATE') THEN
                    l_conf_type := 'RD'; --Registry date
                WHEN l_column_name IN ('REQ_ASSOC_EPI') THEN
                    l_conf_type := 'AE'; --Associated episode
                WHEN l_column_name IN ('REQ_ASSOC_TASK') THEN
                    l_conf_type := 'AT'; --Associated task
                WHEN l_column_name IN ('REQ_ASSOC_TASK_DT') THEN
                    l_conf_type := 'TD'; --Task date
                WHEN l_column_name IN ('REQ_DESC_CLIN_SERV_ORI', 'REQ_DESC_CLIN_SERV_DEST', 'REQ_CLIN_SERV') THEN
                    l_conf_type := 'CS'; --Clinical service
                WHEN l_column_name IN ('REQ_REQUESTED_BY', 'REQ_REQUESTED_TO', 'REQ_PROFESSIONAL') THEN
                    l_conf_type := 'PR'; --Professional
                WHEN l_column_name IN ('REQ_FLG_STATUS', 'REQ_DESC_STATUS') THEN
                    l_conf_type := 'RS'; --Status
                WHEN l_column_name IN ('REQ_FLG_HAS_NOTES', 'NOTES_REQ', 'REQ_NOTES_CANCEL', 'REQ_NOTES_REJECT') THEN
                    l_conf_type := 'RN'; --Notes
                ELSE
                    l_conf_type := NULL;
            END CASE;
        
            IF l_conf_type IS NOT NULL
            THEN
                g_error := 'GET SYS_LIST';
                alertlog.pk_alertlog.log_info(text            => g_error,
                                              object_name     => g_package,
                                              sub_object_name => l_func_name);
                IF l_is_request = pk_alert_constant.g_yes
                THEN
                    l_sys_list := get_type(i_lang              => i_lang,
                                           i_prof              => i_prof,
                                           i_grp_internal_name => pk_complication_core.g_lst_grp_cols_vis_req,
                                           i_flg_context       => l_conf_type);
                ELSE
                    l_sys_list := get_type(i_lang              => i_lang,
                                           i_prof              => i_prof,
                                           i_grp_internal_name => pk_complication_core.g_lst_grp_cols_vis_comp,
                                           i_flg_context       => l_conf_type);
                END IF;
            
                g_error := 'GET VISIBILITY';
                alertlog.pk_alertlog.log_info(text            => g_error,
                                              object_name     => g_package,
                                              sub_object_name => l_func_name);
                SELECT flg_visible
                  INTO l_is_visible
                  FROM (SELECT ccv.flg_visible,
                               row_number() over(ORDER BY decode(ccv.id_institution, i_prof.institution, 1, 2), decode(ccv.id_software, i_prof.software, 1, 2)) line_number
                          FROM comp_cols_visibility ccv
                         WHERE ccv.flg_available = pk_alert_constant.g_yes
                           AND ccv.id_sys_list = l_sys_list
                           AND ccv.id_institution IN (0, i_prof.institution)
                           AND ccv.id_software IN (0, i_prof.software))
                 WHERE line_number = 1;
            ELSE
                l_is_visible := pk_alert_constant.g_no;
            END IF;
        END IF;
    
        RETURN l_is_visible;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_constant.g_no;
    END is_column_visible;

    /**
    * Verifies if the input value is a valid number
    *
    * @param   i_val                       input value
    *
    * @return  'Y' if is a number, 'N' otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   22-12-2009
    */
    FUNCTION is_valid_number(i_val IN VARCHAR2) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'IS_VALID_NUMBER';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        IF i_val IS NULL
        THEN
            RETURN TRUE;
        ELSE
            RETURN regexp_like(i_val, '^[[:digit:]]+$|^-?[[:digit:]]+$');
        END IF;
    END is_valid_number;

    /**
    * Verifies if the input value is a valid date
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_val                       input value
    *
    * @return  'Y' if is a date, 'N' otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   22-12-2009
    */
    FUNCTION is_valid_date
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_val  IN VARCHAR2
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'IS_VALID_DATE';
        --
        l_date TIMESTAMP WITH TIME ZONE := NULL;
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        IF i_val IS NULL
        THEN
            RETURN TRUE;
        ELSE
            IF regexp_like(i_val, '^[[:digit:]]{14}$')
            THEN
                l_date := pk_date_utils.get_string_tstz(i_lang, i_prof, i_val, NULL);
            
                IF l_date IS NULL
                THEN
                    RETURN FALSE;
                ELSE
                    RETURN TRUE;
                END IF;
            ELSE
                RETURN FALSE;
            END IF;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END is_valid_date;

    /**
    * Verifies if the input value is a valid flag
    *
    * @param   i_val                       input value
    * @param   i_size                      len of the flag
    *
    * @return  'Y' if is a number, 'N' otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   22-12-2009
    */
    FUNCTION is_valid_flag
    (
        i_val  IN VARCHAR2,
        i_size IN NUMBER
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'IS_VALID_FLAG';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        IF i_val IS NULL
        THEN
            RETURN TRUE;
        ELSE
            RETURN regexp_like(i_val, '^[[:upper:]]{' || i_size || '}$');
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END is_valid_flag;

    /**
    * Gets the current user action options for the given epis_complication
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_complication         Episode complication id
    * @param   i_type                      C - Complication; R - Request
    *
    * @return  Action subject if the user has actions otherwise returns null
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   05-01-2010
    */
    FUNCTION get_action_subject
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_complication IN epis_complication.id_epis_complication%TYPE,
        i_type              IN VARCHAR2
    ) RETURN table_varchar IS
        l_func_name VARCHAR2(30) := 'GET_ACTION_SUBJECT';
        --
        l_subject           table_varchar := table_varchar();
        l_prof_clin_serv_id t_table_prof_clin_serv;
        l_prof_can_edit     PLS_INTEGER;
        l_prof_can_accept   PLS_INTEGER;
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'GET PROFESSIONAL CLIN_SERV ID';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_prof_clin_serv_id := get_prof_clin_serv_id(i_lang => i_lang, i_prof => i_prof);
    
        g_error := 'VERIFY IF I_PROF CAN EDIT/CANCEL';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        SELECT COUNT(*)
          INTO l_prof_can_edit
          FROM TABLE(pk_complication_core.tf_epis_comp_prof_create(i_lang, i_prof, i_epis_complication, i_type)) pc
          JOIN TABLE(l_prof_clin_serv_id) t
            ON t.id_clinical_service = pc.id_prof_clin_serv
          JOIN epis_complication ec
            ON ec.id_epis_complication = pc.id_epis_complication
         WHERE ec.id_epis_complication = i_epis_complication
           AND ((i_type = g_epis_comp_typ_r AND ec.flg_status_req = g_req_flg_status_r) OR
               (i_type = g_epis_comp_typ_c AND ec.flg_status_comp != g_comp_flg_status_i));
    
        g_error := 'VERIFY ID I_PROF CAN ACCEPT/REJECT';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        SELECT COUNT(*)
          INTO l_prof_can_accept
          FROM epis_complication ec
          JOIN TABLE(l_prof_clin_serv_id) t
            ON t.id_clinical_service = ec.id_clin_serv_dest
         WHERE ec.id_epis_complication = i_epis_complication
           AND i_type = g_epis_comp_typ_r
           AND ec.flg_status_req = g_req_flg_status_r;
    
        IF l_prof_can_edit > 0
        THEN
            l_subject.extend();
            l_subject(l_subject.count) := g_comp_action_edt_cnc;
        END IF;
    
        IF l_prof_can_accept > 0
        THEN
            l_subject.extend();
            l_subject(l_subject.count) := g_comp_action_req;
        END IF;
    
        RETURN l_subject;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_action_subject;

    /**
    * Verifies if the user has actions available
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_complication         Episode complication id
    * @param   i_type                      C - Complication; R - Request
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   05-01-2010
    */
    FUNCTION is_action_btn_available
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_complication IN epis_complication.id_epis_complication%TYPE,
        i_type              IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(30) := 'IS_ACTION_BTN_AVAILABLE';
        --
        l_subject table_varchar;
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'GET SUBJECT';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_subject := get_action_subject(i_lang              => i_lang,
                                        i_prof              => i_prof,
                                        i_epis_complication => i_epis_complication,
                                        i_type              => i_type);
    
        IF l_subject IS NOT NULL
           AND l_subject.count > 0
        THEN
            RETURN pk_alert_constant.g_yes;
        ELSE
            RETURN pk_alert_constant.g_no;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_constant.g_no;
    END is_action_btn_available;

    /**
    * Verifies if the user can edit or cancel the complication
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_complication         Episode complication id
    * @param   i_type                      C - Complication; R - Request
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   05-01-2010
    */
    FUNCTION is_possible_to_edt_cnc
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_complication IN epis_complication.id_epis_complication%TYPE,
        i_type              IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(30) := 'IS_POSSIBLE_TO_EDT_CNC';
        --
        l_subject table_varchar;
        l_count   PLS_INTEGER;
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'GET SUBJECT';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_subject := get_action_subject(i_lang              => i_lang,
                                        i_prof              => i_prof,
                                        i_epis_complication => i_epis_complication,
                                        i_type              => i_type);
    
        g_error := 'VERIFY IF ID_PROF CAN EDIT';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        SELECT COUNT(*)
          INTO l_count
          FROM TABLE(l_subject)
         WHERE column_value = g_comp_action_edt_cnc;
    
        IF l_count > 0
        THEN
            RETURN pk_alert_constant.g_yes;
        ELSE
            RETURN pk_alert_constant.g_no;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_constant.g_no;
    END is_possible_to_edt_cnc;

    /**
    * Get the professional name
    *
    * @param   i_lang             language
    * @param   i_prof             professional, institution and software ids
    * @param   i_prof_id          professional id
    *
    * @return  professional name
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   25-02-2010
    */
    FUNCTION get_prof_name
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_prof_id IN professional.id_professional%TYPE
    ) RETURN professional.name%TYPE IS
        l_func_name VARCHAR2(30) := 'GET_PROF_NAME';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        IF i_prof_id != -1
        THEN
            RETURN pk_prof_utils.get_name_signature(i_lang => i_lang, i_prof => i_prof, i_prof_id => i_prof_id);
        ELSIF i_prof_id = -1
        THEN
            RETURN pk_message.get_message(i_lang => i_lang, i_code_mess => g_msg_any);
        ELSE
            RETURN NULL;
        END IF;
    END get_prof_name;

    /**
    * Verifies if is to show the code in complications lists
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    *
    * @return  'Y' if is to show, 'N' otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   18-03-2010
    */
    FUNCTION is_to_show_code
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(30) := 'IS_TO_SHOW_CODE';
        --
        l_is_to_show_code sys_config.value%TYPE;
    BEGIN
        IF g_is_to_show_code IS NULL
        THEN
            l_is_to_show_code := pk_sysconfig.get_config(i_prof => i_prof, i_code_cf => g_sys_cfg_show_code);
        
            IF l_is_to_show_code = pk_alert_constant.g_yes
            THEN
                g_is_to_show_code := pk_alert_constant.g_yes;
            ELSE
                g_is_to_show_code := pk_alert_constant.g_no;
            END IF;
        END IF;
    
        RETURN g_is_to_show_code;
    END is_to_show_code;

    /**
    * Gets the list of complications for the given episode
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_episode                   Episode id
    * @param   o_complications             List of complications for the given episode
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   04-12-2009
    */
    FUNCTION get_epis_complications
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        o_complications OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_EPIS_COMPLICATIONS';
        --
        l_msg_with_notes sys_message.desc_message%TYPE;
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'GET MSG WITH NOTES';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_msg_with_notes := pk_message.get_message(i_lang, g_msg_with_notes);
    
        g_error := 'GET EPIS_COMPLICATIONS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        OPEN o_complications FOR
            SELECT ec.id_epis_complication,
                   decode(pk_complication_core.is_column_visible(i_lang,
                                                                 i_prof,
                                                                 ec.id_clin_serv_dest,
                                                                 pc.id_prof_clin_serv,
                                                                 'desc_complication',
                                                                 pk_alert_constant.g_no),
                          pk_alert_constant.g_no,
                          g_encrypted_text,
                          pk_translation.get_translation(i_lang, c.code_complication) ||
                          decode(pk_complication_core.is_to_show_code(i_lang, i_prof),
                                 pk_alert_constant.g_yes,
                                 decode(c.code, NULL, NULL, ' (' || c.code || ')'),
                                 NULL)) desc_complication,
                   decode(pk_complication_core.is_column_visible(i_lang,
                                                                 i_prof,
                                                                 ec.id_clin_serv_dest,
                                                                 pc.id_prof_clin_serv,
                                                                 'desc_assoc_task',
                                                                 pk_alert_constant.g_no),
                          pk_alert_constant.g_no,
                          g_encrypted_text,
                          pk_utils.concat_table(CAST(MULTISET
                                                     (SELECT pk_translation.get_translation(i_lang, ca.code_comp_axe) ||
                                                             decode(pk_complication_core.is_to_show_code(i_lang, i_prof),
                                                                    pk_alert_constant.g_yes,
                                                                    decode(ca.code, NULL, NULL, ' (' || ca.code || ')'),
                                                                    NULL) || ': ' ||
                                                             pk_api_complications.get_task_det(i_lang,
                                                                                               i_prof,
                                                                                               ecd.id_context_new,
                                                                                               ecd.id_sys_list,
                                                                                               g_flg_task_det_n,
                                                                                               g_flg_cfg_typ_assoc_task)
                                                        FROM epis_comp_detail ecd
                                                        JOIN TABLE(pk_sys_list.tf_sys_list_values(i_lang, i_prof, g_lst_grp_ecd_at_types)) lst
                                                          ON lst.id_sys_list = ecd.id_sys_list
                                                        JOIN comp_axe ca
                                                          ON ca.id_comp_axe = ecd.id_comp_axe
                                                       WHERE ecd.id_epis_complication = ec.id_epis_complication
                                                         AND ecd.dt_context IS NOT NULL
                                                         AND ecd.id_epis_comp_hist IS NULL) AS table_varchar))) desc_assoc_task,
                   decode(pk_complication_core.is_column_visible(i_lang,
                                                                 i_prof,
                                                                 ec.id_clin_serv_dest,
                                                                 pc.id_prof_clin_serv,
                                                                 'registered_by',
                                                                 pk_alert_constant.g_no),
                          pk_alert_constant.g_no,
                          g_encrypted_text,
                          pc.prof_name) registered_by,
                   decode(pk_complication_core.is_column_visible(i_lang,
                                                                 i_prof,
                                                                 ec.id_clin_serv_dest,
                                                                 pc.id_prof_clin_serv,
                                                                 'registry_date_chr',
                                                                 pk_alert_constant.g_no),
                          pk_alert_constant.g_no,
                          g_encrypted_text,
                          pk_date_utils.date_char_tsz(i_lang, pc.dt_create, i_prof.institution, i_prof.institution)) registry_date_chr,
                   decode(pk_complication_core.is_column_visible(i_lang,
                                                                 i_prof,
                                                                 ec.id_clin_serv_dest,
                                                                 pc.id_prof_clin_serv,
                                                                 'registry_date',
                                                                 pk_alert_constant.g_no),
                          pk_alert_constant.g_no,
                          g_encrypted_text,
                          pk_date_utils.date_send_tsz(i_lang, pc.dt_create, i_prof)) registry_date,
                   decode(pk_complication_core.is_column_visible(i_lang,
                                                                 i_prof,
                                                                 ec.id_clin_serv_dest,
                                                                 pc.id_prof_clin_serv,
                                                                 'effect'),
                          pk_alert_constant.g_no,
                          g_encrypted_text,
                          pk_utils.concat_table(CAST(MULTISET
                                                     (SELECT pk_translation.get_translation(i_lang, ca.code_comp_axe) ||
                                                             decode(pk_complication_core.is_to_show_code(i_lang, i_prof),
                                                                    pk_alert_constant.g_yes,
                                                                    decode(ca.code, NULL, NULL, ' (' || ca.code || ')'),
                                                                    NULL)
                                                        FROM epis_comp_detail ecd
                                                        JOIN comp_axe ca
                                                          ON ca.id_comp_axe = ecd.id_comp_axe
                                                         AND ca.id_sys_list = get_axe_typ_eff(i_lang, i_prof)
                                                       WHERE ecd.id_epis_complication = ec.id_epis_complication
                                                         AND ecd.id_epis_comp_hist IS NULL) AS table_varchar))) effect,
                   decode(pk_complication_core.is_column_visible(i_lang,
                                                                 i_prof,
                                                                 ec.id_clin_serv_dest,
                                                                 pc.id_prof_clin_serv,
                                                                 'flg_status',
                                                                 pk_alert_constant.g_no),
                          pk_alert_constant.g_no,
                          g_encrypted_text,
                          ec.flg_status_comp) flg_status,
                   decode(pk_complication_core.is_column_visible(i_lang,
                                                                 i_prof,
                                                                 ec.id_clin_serv_dest,
                                                                 pc.id_prof_clin_serv,
                                                                 'desc_status'),
                          pk_alert_constant.g_no,
                          g_encrypted_text,
                          pk_sysdomain.get_domain(g_comp_flg_status_domain, ec.flg_status_comp, i_lang) ||
                          decode(ec.notes_cancel || ec.notes_comp, NULL, NULL, g_delim_1 || l_msg_with_notes)) desc_status,
                   decode(pk_complication_core.is_column_visible(i_lang,
                                                                 i_prof,
                                                                 ec.id_clin_serv_dest,
                                                                 pc.id_prof_clin_serv,
                                                                 'flg_has_notes',
                                                                 pk_alert_constant.g_no),
                          pk_alert_constant.g_no,
                          g_encrypted_text,
                          decode(ec.notes_cancel || ec.notes_comp, NULL, pk_alert_constant.g_no, pk_alert_constant.g_yes)) flg_has_notes,
                   pk_complication_core.is_action_btn_available(i_lang,
                                                                i_prof,
                                                                ec.id_epis_complication,
                                                                g_epis_comp_typ_c) flg_action_btn,
                   pk_complication_core.is_possible_to_edt_cnc(i_lang,
                                                               i_prof,
                                                               ec.id_epis_complication,
                                                               g_epis_comp_typ_c) flg_can_edit_or_cancel
              FROM epis_complication ec
              JOIN complication c
                ON c.id_complication = ec.id_complication
              JOIN TABLE(pk_complication_core.tf_epis_comp_prof_create(i_lang, i_prof, ec.id_epis_complication, g_epis_comp_typ_c)) pc
                ON pc.id_epis_complication = ec.id_epis_complication
             WHERE (ec.id_episode = i_episode OR ec.id_episode_origin = i_episode)
               AND ec.id_complication IS NOT NULL
             ORDER BY (CASE ec.flg_status_comp
                          WHEN g_comp_flg_status_u THEN
                           1
                          WHEN g_comp_flg_status_c THEN
                           2
                          WHEN g_comp_flg_status_e THEN
                           3
                          WHEN g_comp_flg_status_i THEN
                           4
                          ELSE
                           5
                      END),
                      ec.dt_epis_complication DESC;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_complications);
            RETURN FALSE;
    END get_epis_complications;

    /**
    * Gets the names of professionals associated with a request
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_comp                 Episode complication id
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   23-12-2009
    */
    FUNCTION get_req_prof_names
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_epis_comp IN epis_comp_prof.id_epis_complication%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(30) := 'GET_REQ_PROF_NAMES';
        --
        l_profs table_varchar;
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        SELECT prof_name
          BULK COLLECT
          INTO l_profs
          FROM (
                 --Only the request was created - Gets the current req profs
                 SELECT pk_complication_core.get_prof_name(i_lang, i_prof, ecp.id_professional) prof_name
                   FROM epis_comp_prof ecp
                   JOIN epis_complication ec
                     ON ec.id_epis_complication = ecp.id_epis_complication
                    AND ec.id_complication IS NULL
                    AND ec.description IS NOT NULL --It's only a request if this is valid
                 WHERE ecp.id_epis_complication = i_epis_comp
                   AND ecp.id_epis_comp_hist IS NULL
                UNION ALL
                --The complication was created based on the request - Gets the last request profs
                SELECT pk_complication_core.get_prof_name(i_lang, i_prof, ecp.id_professional) prof_name
                  FROM epis_comp_prof ecp
                  JOIN epis_comp_hist ech
                    ON ech.id_epis_comp_hist = ecp.id_epis_comp_hist
                   AND ech.id_complication IS NULL
                   AND ech.description IS NOT NULL --It's only a request if this is valid
                    AND ech.dt_epis_complication =
                        (SELECT MIN(ech2.dt_epis_complication)
                           FROM epis_comp_hist ech2
                          WHERE ech2.id_epis_complication = ech.id_epis_complication
                            AND ech2.id_complication IS NULL
                            AND ech2.description IS NOT NULL --It's only a request if this is valid
                           AND ech2.flg_status_req = g_req_flg_status_a)
                   AND ech.flg_status_req = g_req_flg_status_a
                 WHERE ecp.id_epis_complication = i_epis_comp)
         ORDER BY prof_name;
    
        --The names should have a semicolon and a space between them
        RETURN REPLACE(pk_utils.concat_table(i_tab => l_profs, i_delim => g_delim_req_prof),
                       g_delim_req_prof,
                       g_delim_req_prof || ' ');
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_req_prof_names;

    /**
    * Get the last request registry date
    *
    * @param   i_epis_comp                 Episode complication id
    *
    * @return  request registry date
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   06-01-2010
    */
    FUNCTION get_req_registry_dt(i_epis_comp IN epis_complication.id_epis_complication%TYPE)
        RETURN epis_complication.dt_epis_complication%TYPE IS
        l_func_name VARCHAR2(30) := 'GET_REQ_REGISTRY_DT';
        --
        l_date epis_complication.dt_epis_complication%TYPE := NULL;
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        SELECT t.dt_epis_complication
          INTO l_date
          FROM (SELECT ec.dt_epis_complication
                  FROM epis_complication ec
                 WHERE ec.id_epis_complication = i_epis_comp
                   AND ec.description IS NOT NULL
                   AND ec.flg_status_req != g_req_flg_status_a --Means Requested, Rejected or Cancelled requests
                UNION ALL
                SELECT ech.dt_epis_complication
                  FROM epis_comp_hist ech
                 WHERE ech.id_epis_complication = i_epis_comp
                   AND ech.description IS NOT NULL
                   AND ech.flg_status_req = g_req_flg_status_a) t; --In this case the request date is = to the hist record with status accepted;
    
        RETURN l_date;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_req_registry_dt;

    /**
    * Gets the list of requests for the given episode
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_episode                   Episode id
    * @param   o_requests                  List of requests for the given episode
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   07-12-2009
    */
    FUNCTION get_epis_requests
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        o_requests OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_EPIS_REQUESTS';
        --
        l_msg_with_notes sys_message.desc_message%TYPE;
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'GET MSG WITH NOTES';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_msg_with_notes := pk_message.get_message(i_lang, g_msg_with_notes);
    
        g_error := 'GET EPIS_REQUESTS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        OPEN o_requests FOR
            SELECT ec.id_epis_complication,
                   decode(pk_complication_core.is_column_visible(i_lang,
                                                                 i_prof,
                                                                 ec.id_clin_serv_dest,
                                                                 pc.id_prof_clin_serv,
                                                                 'description',
                                                                 pk_alert_constant.g_yes),
                          pk_alert_constant.g_no,
                          g_encrypted_text,
                          ec.description) description,
                   decode(pk_complication_core.is_column_visible(i_lang,
                                                                 i_prof,
                                                                 ec.id_clin_serv_dest,
                                                                 pc.id_prof_clin_serv,
                                                                 'req_requested_by',
                                                                 pk_alert_constant.g_yes),
                          pk_alert_constant.g_no,
                          g_encrypted_text,
                          pc.prof_name) requested_by,
                   decode(pk_complication_core.is_column_visible(i_lang,
                                                                 i_prof,
                                                                 ec.id_clin_serv_dest,
                                                                 pc.id_prof_clin_serv,
                                                                 'req_desc_clin_serv_ori',
                                                                 pk_alert_constant.g_yes),
                          pk_alert_constant.g_no,
                          g_encrypted_text,
                          pc.desc_clin_serv) desc_clin_serv_ori,
                   decode(pk_complication_core.is_column_visible(i_lang,
                                                                 i_prof,
                                                                 ec.id_clin_serv_dest,
                                                                 pc.id_prof_clin_serv,
                                                                 'req_requested_to',
                                                                 pk_alert_constant.g_yes),
                          pk_alert_constant.g_no,
                          g_encrypted_text,
                          get_req_prof_names(i_lang, i_prof, ec.id_epis_complication)) requested_to,
                   decode(pk_complication_core.is_column_visible(i_lang,
                                                                 i_prof,
                                                                 ec.id_clin_serv_dest,
                                                                 pc.id_prof_clin_serv,
                                                                 'req_desc_clin_serv_dest',
                                                                 pk_alert_constant.g_yes),
                          pk_alert_constant.g_no,
                          g_encrypted_text,
                          pk_translation.get_translation(i_lang, cs_dest.code_clinical_service)) desc_clin_serv_dest,
                   decode(pk_complication_core.is_column_visible(i_lang,
                                                                 i_prof,
                                                                 ec.id_clin_serv_dest,
                                                                 pc.id_prof_clin_serv,
                                                                 'req_registry_date_chr',
                                                                 pk_alert_constant.g_yes),
                          pk_alert_constant.g_no,
                          g_encrypted_text,
                          pk_date_utils.date_char_tsz(i_lang, pc.dt_create, i_prof.institution, i_prof.software)) registry_date_chr,
                   decode(pk_complication_core.is_column_visible(i_lang,
                                                                 i_prof,
                                                                 ec.id_clin_serv_dest,
                                                                 pc.id_prof_clin_serv,
                                                                 'req_registry_date',
                                                                 pk_alert_constant.g_yes),
                          pk_alert_constant.g_no,
                          g_encrypted_text,
                          pk_date_utils.date_send_tsz(i_lang, pc.dt_create, i_prof)) registry_date,
                   decode(pk_complication_core.is_column_visible(i_lang,
                                                                 i_prof,
                                                                 ec.id_clin_serv_dest,
                                                                 pc.id_prof_clin_serv,
                                                                 'req_flg_status',
                                                                 pk_alert_constant.g_yes),
                          pk_alert_constant.g_no,
                          g_encrypted_text,
                          ec.flg_status_req) flg_status,
                   decode(pk_complication_core.is_column_visible(i_lang,
                                                                 i_prof,
                                                                 ec.id_clin_serv_dest,
                                                                 pc.id_prof_clin_serv,
                                                                 'req_desc_status',
                                                                 pk_alert_constant.g_yes),
                          pk_alert_constant.g_no,
                          g_encrypted_text,
                          pk_sysdomain.get_domain(g_req_flg_status_domain, ec.flg_status_req, i_lang) ||
                          decode(ec.notes_cancel || ec.notes_rejected, NULL, NULL, g_delim_1 || l_msg_with_notes)) desc_status,
                   decode(pk_complication_core.is_column_visible(i_lang,
                                                                 i_prof,
                                                                 ec.id_clin_serv_dest,
                                                                 pc.id_prof_clin_serv,
                                                                 'req_flg_has_notes',
                                                                 pk_alert_constant.g_yes),
                          pk_alert_constant.g_no,
                          g_encrypted_text,
                          decode(ec.notes_cancel || ec.notes_rejected,
                                 NULL,
                                 pk_alert_constant.g_no,
                                 pk_alert_constant.g_yes)) flg_has_notes,
                   pk_complication_core.is_action_btn_available(i_lang,
                                                                i_prof,
                                                                ec.id_epis_complication,
                                                                g_epis_comp_typ_r) flg_action_btn,
                   pk_complication_core.is_possible_to_edt_cnc(i_lang,
                                                               i_prof,
                                                               ec.id_epis_complication,
                                                               g_epis_comp_typ_r) flg_can_edit_or_cancel
              FROM epis_complication ec
              JOIN TABLE(pk_complication_core.tf_epis_comp_prof_create(i_lang, i_prof, ec.id_epis_complication, g_epis_comp_typ_r)) pc
                ON pc.id_epis_complication = ec.id_epis_complication
              JOIN clinical_service cs_dest
                ON cs_dest.id_clinical_service = ec.id_clin_serv_dest
             WHERE (ec.id_episode = i_episode OR ec.id_episode_origin = i_episode)
               AND ec.description IS NOT NULL
             ORDER BY (CASE ec.flg_status_req
                          WHEN g_req_flg_status_r THEN
                           1
                          WHEN g_req_flg_status_a THEN
                           2
                          WHEN g_req_flg_status_i THEN
                           3
                          WHEN g_req_flg_status_c THEN
                           4
                          ELSE
                           5
                      END),
                      pc.dt_create DESC;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_requests);
            RETURN FALSE;
    END get_epis_requests;

    /**
    * Gets the list of complication specific button actions
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_complication         Episode complication id
    * @param   i_type                      C - Complication; R - Request
    * @param   i_subject                   Subject: CREATE - Button create options; ACTION - Button action options
    * @param   o_actions                   List of actions
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   07-12-2009
    */
    FUNCTION get_actions
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_complication IN epis_complication.id_epis_complication%TYPE,
        i_type              IN VARCHAR2,
        i_subject           IN action.subject%TYPE,
        o_actions           OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_ACTIONS';
        --
        l_error t_error_out;
        --
        e_controlled_error EXCEPTION;
        l_action_message sys_message.desc_message%TYPE;
        l_error_code     sys_message.code_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'GET SUBJECT - ' || i_subject || '; TYPE: ' || i_type;
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF (i_subject = 'CREATE')
        THEN
            g_error := 'GET ACTIONS';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            IF NOT (pk_action.get_actions(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_subject    => 'COMPLICATION_CREATE_BTN',
                                          i_from_state => NULL,
                                          o_actions    => o_actions,
                                          o_error      => l_error))
            THEN
                g_error := l_func_name || ' - ' || g_error;
                pk_alertlog.log_debug(g_error);
                RAISE e_controlled_error;
            END IF;
        ELSIF (i_subject = 'ACTION')
        THEN
            g_error := 'GET ACTIONS';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            IF NOT (pk_action.get_actions(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_subject    => get_action_subject(i_lang              => i_lang,
                                                                             i_prof              => i_prof,
                                                                             i_epis_complication => i_epis_complication,
                                                                             i_type              => i_type),
                                          i_from_state => table_varchar('A'),
                                          o_actions    => o_actions,
                                          o_error      => l_error))
            THEN
                g_error := l_func_name || ' - ' || g_error;
                pk_alertlog.log_debug(g_error);
                RAISE e_controlled_error;
            END IF;
        ELSE
            g_error := l_func_name || ' INVALID SUBJECT - ' || i_subject || '; TYPE: ' || i_type;
            pk_alertlog.log_debug(g_error);
            RAISE e_action_subj_not_available;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN e_action_subj_not_available THEN
            l_action_message := pk_message.get_message(i_lang => i_lang, i_code_mess => 'COMPLICATION_ERR002');
            l_error_code     := 'COMPLICATION_ERR001';
            l_error_message  := pk_message.get_message(i_lang => i_lang, i_code_mess => l_error_code);
        
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => l_error_code,
                                              i_sqlerrm     => l_error_message,
                                              i_message     => g_error,
                                              i_owner       => g_owner,
                                              i_package     => g_package,
                                              i_function    => l_func_name,
                                              i_action_type => 'U',
                                              i_action_msg  => l_action_message,
                                              o_error       => o_error);
            pk_types.open_my_cursor(o_actions);
            RETURN FALSE;
        WHEN e_controlled_error THEN
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => l_error.ora_sqlcode,
                                              i_sqlerrm     => l_error.ora_sqlerrm,
                                              i_message     => g_error,
                                              i_owner       => g_owner,
                                              i_package     => g_package,
                                              i_function    => l_func_name,
                                              i_action_type => 'U',
                                              i_action_msg  => l_error.err_action,
                                              o_error       => o_error);
            pk_types.open_my_cursor(o_actions);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_actions);
            RETURN FALSE;
    END get_actions;

    /**
    * Gets the configuration variables: inst, soft and clin serv
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_cfg_type                  Configuration type
    * @param   i_axe_type                  Axe type
    * @param   o_inst                      institution id
    * @param   o_soft                      software id
    * @param   o_clin_serv                 clinical service id
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @value   i_cfg_type                  Complication
    *                                      Axe
    *                                      Associated task or Treatment Performed
    *                                      Default complication pathology
    *                                      Default complication location
    *                                      Default complication External factor
    *
    * @value   i_axe_type                  Pathology
    *                                      Location
    *                                      External Factors
    *                                      Effect
    *                           ASSOCIATED TASKS
    *                                      Lab test
    *                                      Diet
    *                                      Imaging
    *                                      Exam
    *                                      Medication
    *                                      Positioning
    *                                      Dressing
    *                                      Procedure
    *                                      Surgical procedure
    *                           TREATMENTS PERFORMED
    *                                      Lab test
    *                                      Imaging
    *                                      Exam
    *                                      Medication (group)
    *                                      Medication
    *                                      Outside medication (group)
    *                                      Outside medication
    *                                      Positioning
    *                                      Procedure
    *                                      Surgical procedure
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   10-12-2009
    */
    FUNCTION get_cfg_vars
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_cfg_type  IN comp_config.id_sys_list%TYPE,
        i_axe_type  IN comp_axe.id_sys_list%TYPE DEFAULT NULL,
        o_inst      OUT comp_config.id_institution%TYPE,
        o_soft      OUT comp_config.id_software%TYPE,
        o_clin_serv OUT comp_config.id_clinical_service%TYPE,
        o_error     OUT NOCOPY t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_CFG_VARS';
        --
        l_prof_clin_serv_id t_table_prof_clin_serv;
        --
        e_controlled_error EXCEPTION;
        l_action_message sys_message.desc_message%TYPE;
        l_error_code     sys_message.code_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        --Configuration priority levels
        --        1     2     3     4     5     6     7     8
        --id_inst !=0   !=0   !=0   !=0   0     0     0     0
        --id_soft !=0   !=0   0     0     !=0   !=0   0     0
        --id_clin !=-1  -1    !=-1  -1    !=-1  -1    !=-1  -1    
    
        g_error := 'GET PROFESSIONAL CLIN_SERV ID';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_prof_clin_serv_id := get_prof_clin_serv_id(i_lang => i_lang, i_prof => i_prof);
    
        BEGIN
            IF i_cfg_type = get_cfg_typ_complication(i_lang, i_prof)
            THEN
                g_error := 'GET CFG_VARS COMPLICATION';
                alertlog.pk_alertlog.log_info(text            => g_error,
                                              object_name     => g_package,
                                              sub_object_name => l_func_name);
                --complication
                SELECT id_institution, id_software, id_clinical_service
                  INTO o_inst, o_soft, o_clin_serv
                  FROM (SELECT cc.id_institution,
                               cc.id_software,
                               cc.id_clinical_service,
                               row_number() over(ORDER BY decode(cc.id_institution, i_prof.institution, 1, 2), decode(cc.id_software, i_prof.software, 1, 2), decode(cc.id_clinical_service, pcsl.id_clinical_service, decode(pcsl.flg_default, pk_alert_constant.g_yes, 1, 2), 3)) line_number
                          FROM comp_config cc
                          LEFT JOIN TABLE(l_prof_clin_serv_id) pcsl
                            ON cc.id_clinical_service IN (-1, pcsl.id_clinical_service)
                          JOIN complication c
                            ON c.id_complication = cc.id_complication
                         WHERE c.flg_available = pk_alert_constant.g_yes
                           AND cc.id_sys_list = i_cfg_type
                           AND cc.id_institution IN (0, i_prof.institution)
                           AND cc.id_software IN (0, i_prof.software))
                 WHERE line_number = 1;
            ELSIF i_cfg_type IN (get_cfg_typ_axe(i_lang, i_prof),
                                 get_cfg_typ_def_comp_path(i_lang, i_prof),
                                 get_cfg_typ_def_comp_loc(i_lang, i_prof),
                                 get_cfg_typ_def_comp_ext_fact(i_lang, i_prof))
            THEN
                g_error := 'GET CFG_VARS DEFAULT COMPLICATION PATH/LOC/EXT_FACT';
                alertlog.pk_alertlog.log_info(text            => g_error,
                                              object_name     => g_package,
                                              sub_object_name => l_func_name);
                --axe; default complication pathology; default complication location; default complication external factor
                SELECT id_institution, id_software, id_clinical_service
                  INTO o_inst, o_soft, o_clin_serv
                  FROM (SELECT cc.id_institution,
                               cc.id_software,
                               cc.id_clinical_service,
                               row_number() over(ORDER BY decode(cc.id_institution, i_prof.institution, 1, 2), decode(cc.id_software, i_prof.software, 1, 2), decode(cc.id_clinical_service, pcsl.id_clinical_service, decode(pcsl.flg_default, pk_alert_constant.g_yes, 1, 2), 3)) line_number
                          FROM comp_config cc
                          LEFT JOIN TABLE(l_prof_clin_serv_id) pcsl
                            ON cc.id_clinical_service IN (-1, pcsl.id_clinical_service)
                          JOIN comp_axe ca
                            ON ca.id_comp_axe = cc.id_comp_axe
                         WHERE ca.flg_available = pk_alert_constant.g_yes
                           AND ca.id_sys_list = i_axe_type
                           AND cc.id_sys_list = i_cfg_type
                           AND cc.id_institution IN (0, i_prof.institution)
                           AND cc.id_software IN (0, i_prof.software))
                 WHERE line_number = 1;
            ELSIF i_cfg_type = get_cfg_typ_assoc_task(i_lang, i_prof)
            THEN
                g_error := 'GET CFG_VARS ASSOCIATED TASKS';
                alertlog.pk_alertlog.log_info(text            => g_error,
                                              object_name     => g_package,
                                              sub_object_name => l_func_name);
                -- associated tasks
                SELECT id_institution, id_software, id_clinical_service
                  INTO o_inst, o_soft, o_clin_serv
                  FROM (SELECT cc.id_institution,
                               cc.id_software,
                               cc.id_clinical_service,
                               row_number() over(ORDER BY decode(cc.id_institution, i_prof.institution, 1, 2), decode(cc.id_software, i_prof.software, 1, 2), decode(cc.id_clinical_service, pcsl.id_clinical_service, decode(pcsl.flg_default, pk_alert_constant.g_yes, 1, 2), 3)) line_number
                          FROM comp_config cc
                          LEFT JOIN TABLE(l_prof_clin_serv_id) pcsl
                            ON cc.id_clinical_service IN (-1, pcsl.id_clinical_service)
                          JOIN comp_axe ca
                            ON ca.id_comp_axe = cc.id_comp_axe
                          JOIN TABLE(pk_sys_list.tf_sys_list_values(i_lang, i_prof, g_lst_grp_axe_at_types)) lst
                            ON lst.id_sys_list = ca.id_sys_list
                         WHERE ca.flg_available = pk_alert_constant.g_yes
                           AND cc.id_sys_list = i_cfg_type
                           AND cc.id_institution IN (0, i_prof.institution)
                           AND cc.id_software IN (0, i_prof.software))
                 WHERE line_number = 1;
            ELSIF i_cfg_type = get_cfg_typ_treat_perf(i_lang, i_prof)
            THEN
                g_error := 'GET CFG_VARS TREAT_PERFORMED';
                alertlog.pk_alertlog.log_info(text            => g_error,
                                              object_name     => g_package,
                                              sub_object_name => l_func_name);
                -- type of treatment performed
                SELECT id_institution, id_software, id_clinical_service
                  INTO o_inst, o_soft, o_clin_serv
                  FROM (SELECT cc.id_institution,
                               cc.id_software,
                               cc.id_clinical_service,
                               row_number() over(ORDER BY decode(cc.id_institution, i_prof.institution, 1, 2), decode(cc.id_software, i_prof.software, 1, 2), decode(cc.id_clinical_service, pcsl.id_clinical_service, decode(pcsl.flg_default, pk_alert_constant.g_yes, 1, 2), 3)) line_number
                          FROM comp_config cc
                          LEFT JOIN TABLE(l_prof_clin_serv_id) pcsl
                            ON cc.id_clinical_service IN (-1, pcsl.id_clinical_service)
                          JOIN comp_axe ca
                            ON ca.id_comp_axe = cc.id_comp_axe
                          JOIN TABLE(pk_sys_list.tf_sys_list_values(i_lang, i_prof, g_lst_grp_axe_tp_types)) lst
                            ON lst.id_sys_list = ca.id_sys_list
                         WHERE ca.flg_available = pk_alert_constant.g_yes
                           AND cc.id_sys_list = i_cfg_type
                           AND cc.id_institution IN (0, i_prof.institution)
                           AND cc.id_software IN (0, i_prof.software))
                 WHERE line_number = 1;
            END IF;
        EXCEPTION
            WHEN no_data_found THEN
                IF i_cfg_type NOT IN (get_cfg_typ_def_comp_path(i_lang, i_prof),
                                      get_cfg_typ_def_comp_loc(i_lang, i_prof),
                                      get_cfg_typ_def_comp_ext_fact(i_lang, i_prof))
                THEN
                    g_error := l_func_name || ' - CFG_VAR NOT DEFINED - CFG_TYPE: ' ||
                               pk_sys_list.get_sys_list_value_desc(i_lang        => i_lang,
                                                                   i_prof        => i_prof,
                                                                   i_id_sys_list => i_cfg_type) || '; AXE_TYPE: ' ||
                               pk_sys_list.get_sys_list_value_desc(i_lang        => i_lang,
                                                                   i_prof        => i_prof,
                                                                   i_id_sys_list => i_axe_type);
                    pk_alertlog.log_debug(g_error);
                    RAISE e_cfg_vars_not_defined;
                END IF;
        END;
    
        RETURN TRUE;
    EXCEPTION
        WHEN e_cfg_vars_not_defined THEN
            l_action_message := pk_message.get_message(i_lang => i_lang, i_code_mess => 'COMPLICATION_ERR004');
            l_error_code     := 'COMPLICATION_ERR003';
            l_error_message  := pk_message.get_message(i_lang => i_lang, i_code_mess => l_error_code);
        
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => l_error_code,
                                              i_sqlerrm     => l_error_message,
                                              i_message     => g_error,
                                              i_owner       => g_owner,
                                              i_package     => g_package,
                                              i_function    => l_func_name,
                                              i_action_type => 'U',
                                              i_action_msg  => l_action_message,
                                              o_error       => o_error);
            RAISE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_cfg_vars;

    /**
    * Gets the specified selection list type
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_type                      Type of list to be returned
    * @param   i_parent_axe                Parent axe id or NULL to get root values
    * @param   o_axes                      List of pathologies/locations/external factors/effects
    * @param   o_max_level                 Maximum level that has this type of lis
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @value   i_type                      P  - Pathology
    *                                      L  - Location
    *                                      EF - External factor
    *                                      E  - Effect
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   09-12-2009
    */
    FUNCTION get_axes_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_type       IN sys_list_group_rel.flg_context%TYPE,
        i_parent_axe IN comp_axe.id_comp_axe%TYPE,
        o_axes       OUT pk_types.cursor_type,
        o_max_level  OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_AXES_LIST';
        --
        l_axe_lst_typ sys_list.id_sys_list%TYPE;
        l_inst        comp_config.id_institution%TYPE;
        l_soft        comp_config.id_software%TYPE;
        l_clin_serv   comp_config.id_clinical_service%TYPE;
        --
        e_error EXCEPTION;
        l_error t_error_out;
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'GET AXE ID_SYS_LIST';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_axe_lst_typ := get_type(i_lang, i_prof, pk_complication_core.g_lst_grp_axe_types, i_type);
    
        g_error := 'GET CONF VARS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT (get_cfg_vars(i_lang      => i_lang,
                             i_prof      => i_prof,
                             i_cfg_type  => get_cfg_typ_axe(i_lang, i_prof),
                             i_axe_type  => l_axe_lst_typ,
                             o_inst      => l_inst,
                             o_soft      => l_soft,
                             o_clin_serv => l_clin_serv,
                             o_error     => l_error))
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_error;
        END IF;
    
        g_error := 'GET AXE LIST';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        OPEN o_axes FOR
            SELECT tbl_axe.id_comp_axe,
                   i_type                     flg_context,
                   tbl_axe.lst_ids,
                   tbl_axe.lst_descs          desc_comp_axe,
                   cad.id_parent_axe,
                   tbl_axe.total_childs,
                   cag.id_comp_axe_group,
                   cag.flg_exclusive,
                   cag.flg_required,
                   tbl_chd_grp.id_child_group,
                   tbl_chd_grp.flg_type,
                   cc.flg_default
              FROM TABLE(pk_complication_core.tf_comp_axe_lvl(i_lang, i_prof, l_axe_lst_typ)) tbl_axe
              JOIN comp_config cc
                ON cc.id_comp_axe = tbl_axe.id_comp_axe
              LEFT JOIN comp_axe_detail cad
                ON cad.id_comp_axe = tbl_axe.id_comp_axe
              LEFT JOIN comp_axe_group cag
                ON cag.id_comp_axe_group = cad.id_comp_axe_group
               AND cag.flg_available = pk_alert_constant.g_yes
              LEFT JOIN (SELECT cad2.id_comp_axe,
                                cad2.id_comp_axe_group,
                                cag2.id_comp_axe_group      id_child_group,
                                cag2.flg_parent_grp_context flg_type
                           FROM comp_axe_detail cad2
                           JOIN comp_axe_group cag2
                             ON cag2.id_parent_group = cad2.id_comp_axe_group) tbl_chd_grp
                ON tbl_chd_grp.id_comp_axe = tbl_axe.id_comp_axe
               AND tbl_chd_grp.id_comp_axe_group = cag.id_comp_axe_group
             WHERE cc.id_sys_list = pk_complication_core.get_cfg_typ_axe(i_lang, i_prof)
               AND cc.id_institution = l_inst
               AND cc.id_software = l_soft
               AND cc.id_clinical_service = l_clin_serv
               AND nvl(cad.id_parent_axe, -1) = nvl(i_parent_axe, -1)
             ORDER BY cc.rank, desc_comp_axe, cad.id_parent_axe, tbl_axe.id_comp_axe;
    
        g_error := 'GET MAX LIST LEVEL';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        SELECT nvl(MAX(tbl_axe.lvl), 0)
          INTO o_max_level
          FROM TABLE(pk_complication_core.tf_comp_axe_lvl(i_lang, i_prof, l_axe_lst_typ)) tbl_axe;
    
        RETURN TRUE;
    EXCEPTION
        WHEN e_cfg_vars_not_defined THEN
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => l_error.ora_sqlcode,
                                              i_sqlerrm     => l_error.ora_sqlerrm,
                                              i_message     => l_error.err_desc,
                                              i_owner       => g_owner,
                                              i_package     => g_package,
                                              i_function    => l_func_name,
                                              i_action_type => 'U',
                                              i_action_msg  => l_error.err_action,
                                              o_error       => o_error);
            pk_types.open_my_cursor(o_axes);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_axes);
            RETURN FALSE;
    END get_axes_list;

    /**
    * Gets selection list type groups
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_type                      Type of list to be returned
    * @param   o_groups                    List of pathologies/locations/external factors/effects
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @value   i_type                      P  - Pathology
    *                                      L  - Location
    *                                      EF - External factor
    *                                      E  - Effect
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   25-03-2009
    */
    FUNCTION get_axes_grp_list
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_type   IN sys_list_group_rel.flg_context%TYPE,
        o_groups OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_AXES_GRP_LIST';
        --
        l_axe_lst_typ sys_list.id_sys_list%TYPE;
        l_inst        comp_config.id_institution%TYPE;
        l_soft        comp_config.id_software%TYPE;
        l_clin_serv   comp_config.id_clinical_service%TYPE;
        --
        e_error EXCEPTION;
        l_error t_error_out;
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'GET AXE ID_SYS_LIST';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_axe_lst_typ := get_type(i_lang, i_prof, pk_complication_core.g_lst_grp_axe_types, i_type);
    
        g_error := 'GET CONF VARS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT (get_cfg_vars(i_lang      => i_lang,
                             i_prof      => i_prof,
                             i_cfg_type  => get_cfg_typ_axe(i_lang, i_prof),
                             i_axe_type  => l_axe_lst_typ,
                             o_inst      => l_inst,
                             o_soft      => l_soft,
                             o_clin_serv => l_clin_serv,
                             o_error     => l_error))
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_error;
        END IF;
    
        g_error := 'GET AXE GRP LIST';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        OPEN o_groups FOR
            SELECT DISTINCT cag.id_comp_axe_group,
                            pk_translation.get_translation(i_lang, cag.code_comp_axe_group) desc_comp_axe_group,
                            cag.code,
                            cag.flg_exclusive,
                            cag.flg_required,
                            cag.flg_parent_grp_context
              FROM comp_axe_group cag
              JOIN comp_axe_detail cad
                ON cad.id_comp_axe_group = cag.id_comp_axe_group
              JOIN TABLE(pk_complication_core.tf_comp_axe_lvl(i_lang, i_prof, l_axe_lst_typ)) tbl_axe
                ON tbl_axe.id_comp_axe = cad.id_comp_axe
              JOIN comp_config cc
                ON cc.id_comp_axe = cad.id_comp_axe
             WHERE cc.id_sys_list = pk_complication_core.get_cfg_typ_axe(i_lang, i_prof)
               AND cc.id_institution = l_inst
               AND cc.id_software = l_soft
               AND cc.id_clinical_service = l_clin_serv
               AND cag.flg_available = pk_alert_constant.g_yes
             ORDER BY desc_comp_axe_group;
    
        RETURN TRUE;
    EXCEPTION
        WHEN e_cfg_vars_not_defined THEN
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => l_error.ora_sqlcode,
                                              i_sqlerrm     => l_error.ora_sqlerrm,
                                              i_message     => l_error.err_desc,
                                              i_owner       => g_owner,
                                              i_package     => g_package,
                                              i_function    => l_func_name,
                                              i_action_type => 'U',
                                              i_action_msg  => l_error.err_action,
                                              o_error       => o_error);
            pk_types.open_my_cursor(o_groups);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_groups);
            RETURN FALSE;
    END get_axes_grp_list;

    /*
    * Get list of axe levels
    *
    * @param   i_lang                     language associated to the professional executing the request
    * @param   i_prof                     Professional ID
    * @param   i_sys_list                 Type of axe 
    *
    * @RETURN  Axe levels table
    * @author  Alexandre Santos
    * @version 1.0
    * @since   16-03-2010
    *
    */
    FUNCTION tf_comp_axe_lvl
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_sys_list IN comp_axe.id_sys_list%TYPE
    ) RETURN t_table_comp_axe_lvl
        PIPELINED IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'TF_COMP_AXE_LVL';
        --
        l_count PLS_INTEGER := 0;
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        --Get list of values of the list group
        g_error := 'FILL SYS_LIST TABLE';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        FOR rec IN (SELECT ca.id_comp_axe,
                           LEVEL lvl,
                           substr(sys_connect_by_path(ca.id_comp_axe, '|'), 2) lst_ids,
                           substr(sys_connect_by_path(pk_translation.get_translation(i_lang, ca.code_comp_axe) ||
                                                      decode(pk_complication_core.is_to_show_code(i_lang, i_prof),
                                                             pk_alert_constant.g_yes,
                                                             decode(ca.code, NULL, NULL, ' (' || ca.code || ')'),
                                                             NULL),
                                                      '|'),
                                  2) lst_descs,
                           (SELECT COUNT(*)
                              FROM comp_axe_detail cad2
                             WHERE cad2.id_parent_axe = ca.id_comp_axe) total_childs
                      FROM comp_axe ca
                      LEFT JOIN comp_axe_detail cad
                        ON cad.id_comp_axe = ca.id_comp_axe
                     WHERE ca.id_sys_list = i_sys_list
                       AND ca.flg_available = pk_alert_constant.g_yes
                     START WITH cad.id_parent_axe IS NULL
                    CONNECT BY PRIOR ca.id_comp_axe = cad.id_parent_axe)
        LOOP
            l_count := l_count + 1;
            PIPE ROW(t_rec_comp_axe_lvl(id_comp_axe  => rec.id_comp_axe,
                                        lvl          => rec.lvl,
                                        lst_ids      => rec.lst_ids,
                                        lst_descs    => rec.lst_descs,
                                        total_childs => rec.total_childs));
        END LOOP;
    
        IF (l_count = 0)
        THEN
            PIPE ROW(t_rec_comp_axe_lvl(id_comp_axe  => NULL,
                                        lvl          => NULL,
                                        lst_ids      => NULL,
                                        lst_descs    => NULL,
                                        total_childs => NULL));
        END IF;
    
        RETURN;
    END tf_comp_axe_lvl;

    /**
    * Gets the specified selection list type
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_inst                      Institution id
    * @param   i_soft                      Software id
    * @param   i_clin_serv                 Clinical service id
    * @param   ca_sys_list                 Type of axe
    * @param   cc_sys_list                 Type of config
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   15-03-2010
    */
    FUNCTION get_comp_def_lst
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_inst         IN institution.id_institution%TYPE,
        i_soft         IN software.id_software%TYPE,
        i_clin_serv    IN clinical_service.id_clinical_service%TYPE,
        i_ca_sys_list  IN comp_axe.id_sys_list%TYPE,
        i_cc_sys_list  IN comp_config.id_sys_list%TYPE,
        i_complication IN complication.id_complication%TYPE DEFAULT NULL,
        o_def_list     OUT pk_complication_core.epis_comp_def_cursor,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_COMP_DEF_LST';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'GET DEFAULT LIST';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        OPEN o_def_list FOR
            SELECT cc.id_complication,
                   tbl_aux.id_comp_axe,
                   tbl_aux.lst_ids,
                   tbl_aux.lst_descs,
                   tbl_aux.lvl,
                   decode(tbl_aux.total_childs, 0, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_is_last_lvl
              FROM comp_config cc
              JOIN TABLE(pk_complication_core.tf_comp_axe_lvl(i_lang, i_prof, i_ca_sys_list)) tbl_aux
                ON tbl_aux.id_comp_axe = cc.id_comp_axe
               AND cc.id_sys_list = i_cc_sys_list
               AND cc.id_institution = i_inst
               AND cc.id_software = i_soft
               AND cc.id_clinical_service = i_clin_serv
               AND (cc.id_complication = i_complication OR i_complication IS NULL)
             ORDER BY cc.id_complication, cc.rank, tbl_aux.lst_descs;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_comp_def_lst;

    /**
    * Gets the complication selection list
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   o_complications             List of complications
    * @param   o_def_path                  List of default complications pathologies
    * @param   o_def_loc                   List of default complications locations
    * @param   o_def_ext_fact              List of default external factors
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   09-12-2009
    */
    FUNCTION get_complication_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        o_complications OUT pk_types.cursor_type,
        o_def_path      OUT pk_complication_core.epis_comp_def_cursor,
        o_def_loc       OUT pk_complication_core.epis_comp_def_cursor,
        o_def_ext_fact  OUT pk_complication_core.epis_comp_def_cursor,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_COMPLICATION_LIST';
        --
        l_inst      comp_config.id_institution%TYPE;
        l_soft      comp_config.id_software%TYPE;
        l_clin_serv comp_config.id_clinical_service%TYPE;
        --
        e_error EXCEPTION;
        l_error t_error_out;
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'GET CONF VARS - COMPLICATIONS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT (get_cfg_vars(i_lang      => i_lang,
                             i_prof      => i_prof,
                             i_cfg_type  => get_cfg_typ_complication(i_lang, i_prof),
                             o_inst      => l_inst,
                             o_soft      => l_soft,
                             o_clin_serv => l_clin_serv,
                             o_error     => l_error))
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_error;
        END IF;
    
        g_error := 'GET COMPLICATIONS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        OPEN o_complications FOR
            SELECT c.id_complication,
                   pk_translation.get_translation(i_lang, c.code_complication) ||
                   decode(pk_complication_core.is_to_show_code(i_lang, i_prof),
                          pk_alert_constant.g_yes,
                          decode(c.code, NULL, NULL, ' (' || c.code || ')'),
                          NULL) desc_complication,
                   cc.flg_default
              FROM complication c
              JOIN comp_config cc
                ON cc.id_complication = c.id_complication
             WHERE c.flg_available = pk_alert_constant.g_yes
               AND cc.id_sys_list = get_cfg_typ_complication(i_lang, i_prof)
               AND cc.id_institution = l_inst
               AND cc.id_software = l_soft
               AND cc.id_clinical_service = l_clin_serv
             ORDER BY cc.rank, desc_complication;
    
        g_error := 'GET CONF VARS - PATHOLOGIES';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT (get_cfg_vars(i_lang      => i_lang,
                             i_prof      => i_prof,
                             i_cfg_type  => get_cfg_typ_def_comp_path(i_lang, i_prof),
                             i_axe_type  => get_axe_typ_path(i_lang, i_prof),
                             o_inst      => l_inst,
                             o_soft      => l_soft,
                             o_clin_serv => l_clin_serv,
                             o_error     => l_error))
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_error;
        END IF;
    
        g_error := 'GET DEFAULT PATHOLOGIES';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT (get_comp_def_lst(i_lang        => i_lang,
                                 i_prof        => i_prof,
                                 i_inst        => l_inst,
                                 i_soft        => l_soft,
                                 i_clin_serv   => l_clin_serv,
                                 i_ca_sys_list => pk_complication_core.get_axe_typ_path(i_lang, i_prof),
                                 i_cc_sys_list => pk_complication_core.get_cfg_typ_def_comp_path(i_lang, i_prof),
                                 o_def_list    => o_def_path,
                                 o_error       => l_error))
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_error;
        END IF;
    
        g_error := 'GET CONF VARS - LOCATIONS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT (get_cfg_vars(i_lang      => i_lang,
                             i_prof      => i_prof,
                             i_cfg_type  => get_cfg_typ_def_comp_loc(i_lang, i_prof),
                             i_axe_type  => get_axe_typ_loc(i_lang, i_prof),
                             o_inst      => l_inst,
                             o_soft      => l_soft,
                             o_clin_serv => l_clin_serv,
                             o_error     => l_error))
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_error;
        END IF;
    
        g_error := 'GET DEFAULT LOCATIONS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT (get_comp_def_lst(i_lang        => i_lang,
                                 i_prof        => i_prof,
                                 i_inst        => l_inst,
                                 i_soft        => l_soft,
                                 i_clin_serv   => l_clin_serv,
                                 i_ca_sys_list => pk_complication_core.get_axe_typ_loc(i_lang, i_prof),
                                 i_cc_sys_list => pk_complication_core.get_cfg_typ_def_comp_loc(i_lang, i_prof),
                                 o_def_list    => o_def_loc,
                                 o_error       => l_error))
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_error;
        END IF;
    
        g_error := 'GET CONF VARS - EXTERNAL FACTORS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT (get_cfg_vars(i_lang      => i_lang,
                             i_prof      => i_prof,
                             i_cfg_type  => get_cfg_typ_def_comp_ext_fact(i_lang, i_prof),
                             i_axe_type  => get_axe_typ_ext_fact(i_lang, i_prof),
                             o_inst      => l_inst,
                             o_soft      => l_soft,
                             o_clin_serv => l_clin_serv,
                             o_error     => l_error))
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_error;
        END IF;
    
        g_error := 'GET DEFAULT EXTERNAL FACTORS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT (get_comp_def_lst(i_lang        => i_lang,
                                 i_prof        => i_prof,
                                 i_inst        => l_inst,
                                 i_soft        => l_soft,
                                 i_clin_serv   => l_clin_serv,
                                 i_ca_sys_list => pk_complication_core.get_axe_typ_ext_fact(i_lang, i_prof),
                                 i_cc_sys_list => pk_complication_core.get_cfg_typ_def_comp_ext_fact(i_lang, i_prof),
                                 o_def_list    => o_def_ext_fact,
                                 o_error       => l_error))
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_error;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN e_cfg_vars_not_defined THEN
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => l_error.ora_sqlcode,
                                              i_sqlerrm     => l_error.ora_sqlerrm,
                                              i_message     => l_error.err_desc,
                                              i_owner       => g_owner,
                                              i_package     => g_package,
                                              i_function    => l_func_name,
                                              i_action_type => 'U',
                                              i_action_msg  => l_error.err_action,
                                              o_error       => o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_complication_list;

    /**
    * Gets the complication selection list (Without default values)
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   o_complications             List of complications
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   23-03-2010
    */
    FUNCTION get_complication_lst
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        o_complications OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_COMPLICATION_LST';
        --
        l_inst      comp_config.id_institution%TYPE;
        l_soft      comp_config.id_software%TYPE;
        l_clin_serv comp_config.id_clinical_service%TYPE;
        --
        e_error EXCEPTION;
        l_error t_error_out;
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'GET CONF VARS - COMPLICATIONS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT (get_cfg_vars(i_lang      => i_lang,
                             i_prof      => i_prof,
                             i_cfg_type  => get_cfg_typ_complication(i_lang, i_prof),
                             o_inst      => l_inst,
                             o_soft      => l_soft,
                             o_clin_serv => l_clin_serv,
                             o_error     => l_error))
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_error;
        END IF;
    
        g_error := 'GET COMPLICATIONS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        OPEN o_complications FOR
            SELECT c.id_complication,
                   pk_translation.get_translation(i_lang, c.code_complication) ||
                   decode(pk_complication_core.is_to_show_code(i_lang, i_prof),
                          pk_alert_constant.g_yes,
                          decode(c.code, NULL, NULL, ' (' || c.code || ')'),
                          NULL) desc_complication,
                   cc.flg_default
              FROM complication c
              JOIN comp_config cc
                ON cc.id_complication = c.id_complication
             WHERE c.flg_available = pk_alert_constant.g_yes
               AND cc.id_sys_list = get_cfg_typ_complication(i_lang, i_prof)
               AND cc.id_institution = l_inst
               AND cc.id_software = l_soft
               AND cc.id_clinical_service = l_clin_serv
             ORDER BY cc.rank, desc_complication;
    
        RETURN TRUE;
    EXCEPTION
        WHEN e_cfg_vars_not_defined THEN
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => l_error.ora_sqlcode,
                                              i_sqlerrm     => l_error.ora_sqlerrm,
                                              i_message     => l_error.err_desc,
                                              i_owner       => g_owner,
                                              i_package     => g_package,
                                              i_function    => l_func_name,
                                              i_action_type => 'U',
                                              i_action_msg  => l_error.err_action,
                                              o_error       => o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_complication_lst;

    /**
    * Gets the complication default values lists
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_complication              Complication id
    * @param   o_def_path                  List of default pathologies
    * @param   o_def_loc                   List of default locations
    * @param   o_def_ext_fact              List of default external factors
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   23-03-2010
    */
    FUNCTION get_complication_dft_lst
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_complication IN complication.id_complication%TYPE,
        o_def_path     OUT pk_complication_core.epis_comp_def_cursor,
        o_def_loc      OUT pk_complication_core.epis_comp_def_cursor,
        o_def_ext_fact OUT pk_complication_core.epis_comp_def_cursor,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_COMPLICATION_DFT_LST';
        --
        l_inst      comp_config.id_institution%TYPE := 0;
        l_soft      comp_config.id_software%TYPE := 0;
        l_clin_serv comp_config.id_clinical_service%TYPE := -1;
        --
        e_error EXCEPTION;
        l_error t_error_out;
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'GET CONF VARS - PATHOLOGIES';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT (get_cfg_vars(i_lang      => i_lang,
                             i_prof      => i_prof,
                             i_cfg_type  => get_cfg_typ_def_comp_path(i_lang, i_prof),
                             i_axe_type  => get_axe_typ_path(i_lang, i_prof),
                             o_inst      => l_inst,
                             o_soft      => l_soft,
                             o_clin_serv => l_clin_serv,
                             o_error     => l_error))
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_error;
        END IF;
    
        g_error := 'GET DEFAULT PATHOLOGIES';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT (get_comp_def_lst(i_lang         => i_lang,
                                 i_prof         => i_prof,
                                 i_inst         => l_inst,
                                 i_soft         => l_soft,
                                 i_clin_serv    => l_clin_serv,
                                 i_ca_sys_list  => pk_complication_core.get_axe_typ_path(i_lang, i_prof),
                                 i_cc_sys_list  => pk_complication_core.get_cfg_typ_def_comp_path(i_lang, i_prof),
                                 i_complication => i_complication,
                                 o_def_list     => o_def_path,
                                 o_error        => l_error))
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_error;
        END IF;
    
        g_error := 'GET CONF VARS - LOCATIONS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT (get_cfg_vars(i_lang      => i_lang,
                             i_prof      => i_prof,
                             i_cfg_type  => get_cfg_typ_def_comp_loc(i_lang, i_prof),
                             i_axe_type  => get_axe_typ_loc(i_lang, i_prof),
                             o_inst      => l_inst,
                             o_soft      => l_soft,
                             o_clin_serv => l_clin_serv,
                             o_error     => l_error))
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_error;
        END IF;
    
        g_error := 'GET DEFAULT LOCATIONS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT (get_comp_def_lst(i_lang         => i_lang,
                                 i_prof         => i_prof,
                                 i_inst         => l_inst,
                                 i_soft         => l_soft,
                                 i_clin_serv    => l_clin_serv,
                                 i_ca_sys_list  => pk_complication_core.get_axe_typ_loc(i_lang, i_prof),
                                 i_cc_sys_list  => pk_complication_core.get_cfg_typ_def_comp_loc(i_lang, i_prof),
                                 i_complication => i_complication,
                                 o_def_list     => o_def_loc,
                                 o_error        => l_error))
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_error;
        END IF;
    
        g_error := 'GET CONF VARS - EXTERNAL FACTORS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT (get_cfg_vars(i_lang      => i_lang,
                             i_prof      => i_prof,
                             i_cfg_type  => get_cfg_typ_def_comp_ext_fact(i_lang, i_prof),
                             i_axe_type  => get_axe_typ_ext_fact(i_lang, i_prof),
                             o_inst      => l_inst,
                             o_soft      => l_soft,
                             o_clin_serv => l_clin_serv,
                             o_error     => l_error))
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_error;
        END IF;
    
        g_error := 'GET DEFAULT EXTERNAL FACTORS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT (get_comp_def_lst(i_lang         => i_lang,
                                 i_prof         => i_prof,
                                 i_inst         => l_inst,
                                 i_soft         => l_soft,
                                 i_clin_serv    => l_clin_serv,
                                 i_ca_sys_list  => pk_complication_core.get_axe_typ_ext_fact(i_lang, i_prof),
                                 i_cc_sys_list  => pk_complication_core.get_cfg_typ_def_comp_ext_fact(i_lang, i_prof),
                                 i_complication => i_complication,
                                 o_def_list     => o_def_ext_fact,
                                 o_error        => l_error))
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_error;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN e_cfg_vars_not_defined THEN
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => l_error.ora_sqlcode,
                                              i_sqlerrm     => l_error.ora_sqlerrm,
                                              i_message     => l_error.err_desc,
                                              i_owner       => g_owner,
                                              i_package     => g_package,
                                              i_function    => l_func_name,
                                              i_action_type => 'U',
                                              i_action_msg  => l_error.err_action,
                                              o_error       => o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_complication_dft_lst;

    /**
    * Gets episode description label
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_episode                   Episode id
    *
    * @return  Episode description label
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   05-01-2010
    */
    FUNCTION get_episode_description
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN epis_complication.id_episode_origin%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(30) := 'GET_EPISODE_DESCRIPTION';
        --
        l_patient       patient.id_patient%TYPE;
        l_data          pk_timeline.t_cur_timeline_detail;
        l_timeline_aux  pk_timeline.t_rec_timeline_detail;
        l_desc_timeline VARCHAR2(4000);
        l_error         t_error_out;
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'GET ID_PATIENT';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        SELECT e.id_patient
          INTO l_patient
          FROM episode e
         WHERE e.id_episode = i_episode;
    
        g_error := 'GET EPISODE DESCRIPTION';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT pk_timeline.get_timeline_details(i_lang        => i_lang,
                                                i_prof        => i_prof,
                                                i_tl_timeline => 1,
                                                i_patient     => l_patient,
                                                o_x_data      => l_data,
                                                o_error       => l_error)
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_general_error;
        ELSE
            LOOP
                FETCH l_data
                    INTO l_timeline_aux;
                EXIT WHEN l_data%NOTFOUND;
            
                IF l_timeline_aux.id_episode = i_episode
                THEN
                    l_desc_timeline := l_timeline_aux.desc_timeline;
                    EXIT;
                END IF;
            END LOOP;
        
            CLOSE l_data;
        END IF;
    
        RETURN l_desc_timeline;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_episode_description;

    /**
    * Get complication data
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_complication         Episode complication id
    * @param   o_complication              All complication data
    * @param   o_comp_detail               All complication detail data
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   04-01-2010
    */
    FUNCTION get_complication
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_complication IN epis_complication.id_epis_complication%TYPE,
        o_complication      OUT pk_types.cursor_type,
        o_comp_detail       OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_COMPLICATION';
        --
        l_msg_with_notes sys_message.desc_message%TYPE;
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'GET MSG WITH NOTES';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_msg_with_notes := pk_message.get_message(i_lang, g_msg_with_notes);
    
        g_error := 'GET COMPLICATION DATA';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        OPEN o_complication FOR
            SELECT ec.id_complication id_complication,
                   pk_translation.get_translation(i_lang, c.code_complication) ||
                   decode(pk_complication_core.is_to_show_code(i_lang, i_prof),
                          pk_alert_constant.g_yes,
                          decode(c.code, NULL, NULL, ' (' || c.code || ')'),
                          NULL) desc_complication,
                   pk_date_utils.date_char_tsz(i_lang, ec.dt_verif_comp, i_prof.institution, i_prof.institution) dt_verif_comp_chr,
                   pk_date_utils.date_send_tsz(i_lang, ec.dt_verif_comp, i_prof) dt_verif_comp,
                   pk_date_utils.date_char_tsz(i_lang, ec.dt_epis_complication, i_prof.institution, i_prof.institution) registry_date_chr,
                   pk_date_utils.date_send_tsz(i_lang, ec.dt_epis_complication, i_prof) registry_date,
                   ec.id_episode_origin,
                   pk_complication_core.get_episode_description(i_lang, i_prof, ec.id_episode_origin) desc_episode_origin,
                   ec.notes_comp,
                   ec.flg_status_comp flg_status,
                   pk_sysdomain.get_domain(g_comp_flg_status_domain, ec.flg_status_comp, i_lang) ||
                   decode(ec.notes_cancel, NULL, NULL, g_delim_1 || l_msg_with_notes) desc_status,
                   ec.id_prof_clin_serv,
                   pk_translation.get_translation(i_lang, cs.code_clinical_service) desc_prof_clin_serv
              FROM epis_complication ec
              JOIN complication c
                ON c.id_complication = ec.id_complication
              JOIN clinical_service cs
                ON cs.id_clinical_service = ec.id_prof_clin_serv
             WHERE ec.id_epis_complication = i_epis_complication
               AND ec.id_complication IS NOT NULL;
    
        g_error := 'GET COMPLICATION DETAIL DATA';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        OPEN o_comp_detail FOR
        --Pathologies
            SELECT ecd.id_comp_axe || decode(ecda.id_comp_axe, NULL, NULL, g_delim_2 || ecda.id_comp_axe) id_comp_axe,
                   lvl.lst_ids || decode(ecda.id_comp_axe, NULL, NULL, g_delim_1 || lvl2.lst_ids) lst_ids,
                   lvl.lst_descs || decode(ecda.id_comp_axe, NULL, NULL, g_delim_1 || lvl2.lst_descs) lst_descs,
                   NULL id_context,
                   NULL desc_context,
                   NULL flg_context,
                   NULL dt_context_chr,
                   NULL dt_context,
                   NULL id_prof_req,
                   NULL prof_req_name,
                   NULL id_prof_task,
                   NULL prof_task_name,
                   NULL id_diagnosis,
                   NULL desc_diagnosis,
                   NULL id_professional,
                   NULL prof_name,
                   pk_complication_core.g_flg_axe_type_path typ
              FROM epis_complication ec
              JOIN epis_comp_detail ecd
                ON ecd.id_epis_complication = ec.id_epis_complication
              JOIN TABLE(pk_complication_core.tf_comp_axe_lvl(i_lang, i_prof, get_axe_typ_path(i_lang, i_prof))) lvl
                ON lvl.id_comp_axe = ecd.id_comp_axe
              LEFT JOIN epis_comp_detail_axe ecda
                ON ecda.id_epis_comp_detail = ecd.id_epis_comp_detail
               AND ecda.id_parent_comp_axe = ecd.id_comp_axe
              LEFT JOIN comp_axe ca
                ON ca.id_comp_axe = ecda.id_comp_axe
              LEFT JOIN TABLE(pk_complication_core.tf_comp_axe_lvl(i_lang, i_prof, ca.id_sys_list)) lvl2
                ON nvl(lvl2.id_comp_axe, -99) = nvl(ecda.id_comp_axe, -99)
             WHERE ecd.id_epis_comp_hist IS NULL --current records
               AND ec.id_epis_complication = i_epis_complication
               AND ec.id_complication IS NOT NULL --id_complication=NULL means that's a request
            --Locations
            UNION ALL
            SELECT ecd.id_comp_axe || decode(ecda.id_comp_axe, NULL, NULL, g_delim_2 || ecda.id_comp_axe) id_comp_axe,
                   lvl.lst_ids || decode(ecda.id_comp_axe, NULL, NULL, g_delim_1 || lvl2.lst_ids) lst_ids,
                   lvl.lst_descs || decode(ecda.id_comp_axe, NULL, NULL, g_delim_1 || lvl2.lst_descs) lst_descs,
                   NULL id_context,
                   NULL desc_context,
                   NULL flg_context,
                   NULL dt_context_chr,
                   NULL dt_context,
                   NULL id_prof_req,
                   NULL prof_req_name,
                   NULL id_prof_task,
                   NULL prof_task_name,
                   NULL id_diagnosis,
                   NULL desc_diagnosis,
                   NULL id_professional,
                   NULL prof_name,
                   pk_complication_core.g_flg_axe_type_loc typ
              FROM epis_complication ec
              JOIN epis_comp_detail ecd
                ON ecd.id_epis_complication = ec.id_epis_complication
              JOIN TABLE(pk_complication_core.tf_comp_axe_lvl(i_lang, i_prof, get_axe_typ_loc(i_lang, i_prof))) lvl
                ON lvl.id_comp_axe = ecd.id_comp_axe
              LEFT JOIN epis_comp_detail_axe ecda
                ON ecda.id_epis_comp_detail = ecd.id_epis_comp_detail
               AND ecda.id_parent_comp_axe = ecd.id_comp_axe
              LEFT JOIN comp_axe ca
                ON ca.id_comp_axe = ecda.id_comp_axe
              LEFT JOIN TABLE(pk_complication_core.tf_comp_axe_lvl(i_lang, i_prof, ca.id_sys_list)) lvl2
                ON nvl(lvl2.id_comp_axe, -99) = nvl(ecda.id_comp_axe, -99)
             WHERE ecd.id_epis_comp_hist IS NULL --current records
               AND ec.id_epis_complication = i_epis_complication
               AND ec.id_complication IS NOT NULL --id_complication=NULL means that's a request
            --External factors
            UNION ALL
            SELECT ecd.id_comp_axe || decode(ecda.id_comp_axe, NULL, NULL, g_delim_2 || ecda.id_comp_axe) id_comp_axe,
                   lvl.lst_ids || decode(ecda.id_comp_axe, NULL, NULL, g_delim_1 || lvl2.lst_ids) lst_ids,
                   lvl.lst_descs || decode(ecda.id_comp_axe, NULL, NULL, g_delim_1 || lvl2.lst_descs) lst_descs,
                   NULL id_context,
                   NULL desc_context,
                   NULL flg_context,
                   NULL dt_context_chr,
                   NULL dt_context,
                   NULL id_prof_req,
                   NULL prof_req_name,
                   NULL id_prof_task,
                   NULL prof_task_name,
                   NULL id_diagnosis,
                   NULL desc_diagnosis,
                   NULL id_professional,
                   NULL prof_name,
                   pk_complication_core.g_flg_axe_type_ext_fact typ
              FROM epis_complication ec
              JOIN epis_comp_detail ecd
                ON ecd.id_epis_complication = ec.id_epis_complication
              JOIN TABLE(pk_complication_core.tf_comp_axe_lvl(i_lang, i_prof, get_axe_typ_ext_fact(i_lang, i_prof))) lvl
                ON lvl.id_comp_axe = ecd.id_comp_axe
              LEFT JOIN epis_comp_detail_axe ecda
                ON ecda.id_epis_comp_detail = ecd.id_epis_comp_detail
               AND ecda.id_parent_comp_axe = ecd.id_comp_axe
              LEFT JOIN comp_axe ca
                ON ca.id_comp_axe = ecda.id_comp_axe
              LEFT JOIN TABLE(pk_complication_core.tf_comp_axe_lvl(i_lang, i_prof, ca.id_sys_list)) lvl2
                ON nvl(lvl2.id_comp_axe, -99) = nvl(ecda.id_comp_axe, -99)
             WHERE ecd.id_epis_comp_hist IS NULL --current records
               AND ec.id_epis_complication = i_epis_complication
               AND ec.id_complication IS NOT NULL --id_complication=NULL means that's a request
            --Effects
            UNION ALL
            SELECT to_char(ecd.id_comp_axe) id_comp_axe,
                   to_char(ecd.id_comp_axe) lst_ids,
                   pk_translation.get_translation(i_lang, ca.code_comp_axe) ||
                   decode(pk_complication_core.is_to_show_code(i_lang, i_prof),
                          pk_alert_constant.g_yes,
                          decode(ca.code, NULL, NULL, ' (' || ca.code || ')'),
                          NULL) lst_descs,
                   NULL id_context,
                   NULL desc_context,
                   NULL flg_context,
                   NULL dt_context_chr,
                   NULL dt_context,
                   NULL id_prof_req,
                   NULL prof_req_name,
                   NULL id_prof_task,
                   NULL prof_task_name,
                   NULL id_diagnosis,
                   NULL desc_diagnosis,
                   NULL id_professional,
                   NULL prof_name,
                   pk_complication_core.g_flg_axe_type_eff typ
              FROM epis_complication ec
              JOIN epis_comp_detail ecd
                ON ecd.id_epis_complication = ec.id_epis_complication
              JOIN comp_axe ca
                ON ca.id_comp_axe = ecd.id_comp_axe
               AND ca.id_sys_list = get_axe_typ_eff(i_lang, i_prof)
             WHERE ecd.id_epis_comp_hist IS NULL --current records
               AND ec.id_epis_complication = i_epis_complication
               AND ec.id_complication IS NOT NULL --id_complication=NULL means that's a request
            --Associated tasks
            UNION ALL
            SELECT to_char(ecd.id_comp_axe) id_comp_axe,
                   to_char(ecd.id_comp_axe) lst_ids,
                   pk_translation.get_translation(i_lang, ca.code_comp_axe) ||
                   decode(pk_complication_core.is_to_show_code(i_lang, i_prof),
                          pk_alert_constant.g_yes,
                          decode(ca.code, NULL, NULL, ' (' || ca.code || ')'),
                          NULL) lst_descs,
                   ecd.id_context_new id_context,
                   pk_translation.get_translation(i_lang, ca.code_comp_axe) ||
                   decode(pk_complication_core.is_to_show_code(i_lang, i_prof),
                          pk_alert_constant.g_yes,
                          decode(ca.code, NULL, NULL, ' (' || ca.code || ')'),
                          NULL) || ': ' ||
                   pk_api_complications.get_task_det(i_lang,
                                                     i_prof,
                                                     ecd.id_context_new,
                                                     ecd.id_sys_list,
                                                     g_flg_task_det_n,
                                                     g_flg_cfg_typ_assoc_task) desc_context,
                   ecd.id_sys_list,
                   pk_date_utils.date_char_tsz(i_lang, ecd.dt_context, i_prof.institution, i_prof.institution) dt_context_chr,
                   pk_date_utils.date_send_tsz(i_lang, ecd.dt_context, i_prof.institution, i_prof.institution) dt_context,
                   ecd.id_context_prof id_prof_req,
                   pk_complication_core.get_prof_name(i_lang, i_prof, ecd.id_context_prof) prof_req_name,
                   ecd.id_context_prof_spec id_prof_task,
                   pk_complication_core.get_prof_name(i_lang, i_prof, ecd.id_context_prof_spec) prof_task_name,
                   NULL id_diagnosis,
                   NULL desc_diagnosis,
                   NULL id_professional,
                   NULL prof_name,
                   pk_complication_core.g_flg_cfg_typ_assoc_task typ
              FROM epis_complication ec
              JOIN epis_comp_detail ecd
                ON ecd.id_epis_complication = ec.id_epis_complication
              JOIN TABLE(pk_sys_list.tf_sys_list_values(i_lang, i_prof, g_lst_grp_ecd_at_types)) lst
                ON lst.id_sys_list = ecd.id_sys_list
              JOIN comp_axe ca
                ON ca.id_comp_axe = ecd.id_comp_axe
             WHERE ecd.id_epis_comp_hist IS NULL --current records
               AND ecd.dt_context IS NOT NULL
               AND ec.id_epis_complication = i_epis_complication
               AND ec.id_complication IS NOT NULL --id_complication=NULL means that's a request
            --Professionals
            UNION ALL
            SELECT NULL id_comp_axe,
                   NULL lst_ids,
                   NULL lst_descs,
                   NULL id_context,
                   NULL desc_context,
                   NULL flg_context,
                   NULL dt_context_chr,
                   NULL dt_context,
                   NULL id_prof_req,
                   NULL prof_req_name,
                   NULL id_prof_task,
                   NULL prof_task_name,
                   NULL id_diagnosis,
                   NULL desc_diagnosis,
                   ecp.id_professional,
                   pk_complication_core.get_prof_name(i_lang, i_prof, ecp.id_professional) prof_name,
                   g_complication_prof typ
              FROM epis_complication ec
              JOIN epis_comp_prof ecp
                ON ecp.id_epis_complication = ec.id_epis_complication
             WHERE ecp.id_epis_comp_hist IS NULL --current records
               AND ec.id_epis_complication = i_epis_complication
               AND ec.id_complication IS NOT NULL --id_complication=NULL means that's a request            
            --Treatment performed
            UNION ALL
            SELECT to_char(ecd.id_comp_axe) id_comp_axe,
                   to_char(ecd.id_comp_axe) lst_ids,
                   pk_translation.get_translation(i_lang, ca.code_comp_axe) ||
                   decode(pk_complication_core.is_to_show_code(i_lang, i_prof),
                          pk_alert_constant.g_yes,
                          decode(ca.code, NULL, NULL, ' (' || ca.code || ')'),
                          NULL) lst_descs,
                   ecd.id_context_new id_context,
                   pk_api_complications.get_task_det(i_lang,
                                                     i_prof,
                                                     ecd.id_context_new,
                                                     ecd.id_sys_list,
                                                     g_flg_task_det_n,
                                                     g_flg_cfg_typ_treat_perf) desc_context,
                   ecd.id_sys_list,
                   NULL dt_context_chr,
                   NULL dt_context,
                   NULL id_prof_req,
                   NULL prof_req_name,
                   NULL id_prof_task,
                   NULL prof_task_name,
                   NULL id_diagnosis,
                   NULL desc_diagnosis,
                   NULL id_professional,
                   NULL prof_name,
                   pk_complication_core.g_flg_cfg_typ_treat_perf typ
              FROM epis_complication ec
              JOIN epis_comp_detail ecd
                ON ecd.id_epis_complication = ec.id_epis_complication
              JOIN TABLE(pk_sys_list.tf_sys_list_values(i_lang, i_prof, g_lst_grp_ecd_tp_types)) lst
                ON lst.id_sys_list = ecd.id_sys_list
              JOIN comp_axe ca
                ON ca.id_comp_axe = ecd.id_comp_axe
             WHERE ecd.id_epis_comp_hist IS NULL --current records
               AND ecd.dt_context IS NULL
               AND ec.id_epis_complication = i_epis_complication
               AND ec.id_complication IS NOT NULL --id_complication=NULL means that's a request
            --Diagnosis
            UNION ALL
            SELECT NULL id_comp_axe,
                   NULL lst_ids,
                   NULL lst_descs,
                   NULL id_context,
                   NULL desc_context,
                   NULL flg_context,
                   NULL dt_context_chr,
                   NULL dt_context,
                   NULL id_prof_req,
                   NULL prof_req_name,
                   NULL id_prof_task,
                   NULL prof_task_name,
                   mrd.id_diagnosis,
                   pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                              i_prof                => i_prof,
                                              i_id_alert_diagnosis  => ed.id_alert_diagnosis,
                                              i_id_diagnosis        => d.id_diagnosis,
                                              i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                              i_code                => d.code_icd,
                                              i_flg_other           => d.flg_other,
                                              i_flg_std_diag        => pk_alert_constant.g_yes) desc_diagnosis,
                   NULL id_professional,
                   NULL prof_name,
                   g_complication_diag typ
              FROM mcdt_req_diagnosis mrd
              JOIN epis_complication ec
                ON ec.id_epis_complication = mrd.id_epis_complication
              JOIN diagnosis d
                ON d.id_diagnosis = mrd.id_diagnosis
              JOIN epis_diagnosis ed
                ON ed.id_epis_diagnosis = mrd.id_epis_diagnosis
             WHERE mrd.id_epis_comp_hist IS NULL --current records
               AND mrd.id_epis_complication = i_epis_complication
               AND ec.id_complication IS NOT NULL --id_complication=NULL means that's a request
            ;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_complication;

    FUNCTION get_epis_comp_rec
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_complication IN epis_complication.id_epis_complication%TYPE,
        i_epis_comp_hist    IN epis_comp_hist.id_epis_comp_hist%TYPE
    ) RETURN pk_complication_core.epis_comp_rec IS
        l_func_name VARCHAR2(30) := 'GET_EPIS_COMP_REC';
        --
        l_epis_comp_row pk_complication_core.epis_comp_rec := NULL;
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        IF i_epis_comp_hist IS NOT NULL
        THEN
            g_error := 'GET EPIS_COMP RECORD';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            SELECT t.id_epis_complication,
                   t.id_epis_comp_hist,
                   t.id_episode,
                   t.id_episode_origin,
                   t.desc_episode_origin,
                   t.id_complication,
                   t.desc_complication,
                   t.description,
                   t.dt_verif_comp,
                   t.dt_verif_comp_desc,
                   t.dt_verif_req,
                   t.dt_verif_req_desc,
                   t.id_clin_serv_dest,
                   t.desc_clin_serv_dest,
                   t.flg_status_comp,
                   t.desc_flg_stat_comp,
                   t.flg_status_req,
                   t.desc_flg_stat_req,
                   t.notes_comp,
                   t.notes_req,
                   t.id_cancel_reason,
                   t.desc_cancel_reason,
                   t.notes_cancel,
                   t.id_reject_reason,
                   t.desc_reject_reason,
                   t.notes_rejected,
                   t.id_prof_create,
                   t.prof_create_name,
                   t.id_prof_clin_serv,
                   t.desc_prof_clin_serv,
                   t.dt_epis_complication,
                   t.dt_epis_comp_desc
              INTO l_epis_comp_row
              FROM (SELECT ec.id_epis_complication,
                           g_epis_comp_curr_row id_epis_comp_hist,
                           ec.id_episode,
                           ec.id_episode_origin,
                           pk_complication_core.get_episode_description(i_lang, i_prof, ec.id_episode_origin) desc_episode_origin,
                           ec.id_complication,
                           pk_translation.get_translation(i_lang, c.code_complication) ||
                           decode(pk_complication_core.is_to_show_code(i_lang, i_prof),
                                  pk_alert_constant.g_yes,
                                  decode(c.code, NULL, NULL, ' (' || c.code || ')'),
                                  NULL) desc_complication,
                           ec.description,
                           ec.dt_verif_comp,
                           pk_date_utils.date_char_tsz(i_lang, ec.dt_verif_comp, i_prof.institution, i_prof.software) dt_verif_comp_desc,
                           ec.dt_verif_req,
                           pk_date_utils.date_char_tsz(i_lang, ec.dt_verif_req, i_prof.institution, i_prof.software) dt_verif_req_desc,
                           ec.id_clin_serv_dest,
                           pk_translation.get_translation(i_lang, cs_d.code_clinical_service) desc_clin_serv_dest,
                           ec.flg_status_comp,
                           pk_sysdomain.get_domain(g_comp_flg_status_domain, ec.flg_status_comp, i_lang) desc_flg_stat_comp,
                           ec.flg_status_req,
                           pk_sysdomain.get_domain(g_req_flg_status_domain, ec.flg_status_req, i_lang) desc_flg_stat_req,
                           ec.notes_comp,
                           ec.notes_req,
                           ec.id_cancel_reason,
                           pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, ec.id_cancel_reason) desc_cancel_reason,
                           ec.notes_cancel,
                           ec.id_reject_reason,
                           pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, ec.id_reject_reason) desc_reject_reason,
                           ec.notes_rejected,
                           ec.id_prof_create,
                           pk_complication_core.get_prof_name(i_lang, i_prof, ec.id_prof_create) prof_create_name,
                           ec.id_prof_clin_serv,
                           pk_translation.get_translation(i_lang, cs_p.code_clinical_service) desc_prof_clin_serv,
                           ec.dt_epis_complication,
                           pk_date_utils.date_char_tsz(i_lang,
                                                       ec.dt_epis_complication,
                                                       i_prof.institution,
                                                       i_prof.software) dt_epis_comp_desc
                      FROM epis_complication ec
                      LEFT JOIN complication c
                        ON c.id_complication = ec.id_complication
                      LEFT JOIN clinical_service cs_d
                        ON cs_d.id_clinical_service = ec.id_clin_serv_dest
                      LEFT JOIN clinical_service cs_p
                        ON cs_p.id_clinical_service = ec.id_prof_clin_serv
                     WHERE ec.id_epis_complication = i_epis_complication
                       AND i_epis_comp_hist = g_epis_comp_curr_row
                    UNION ALL
                    SELECT ech.id_epis_complication,
                           ech.id_epis_comp_hist,
                           ech.id_episode,
                           ech.id_episode_origin,
                           pk_complication_core.get_episode_description(i_lang, i_prof, ech.id_episode_origin) desc_episode_origin,
                           ech.id_complication,
                           pk_translation.get_translation(i_lang, c.code_complication) ||
                           decode(pk_complication_core.is_to_show_code(i_lang, i_prof),
                                  pk_alert_constant.g_yes,
                                  decode(c.code, NULL, NULL, ' (' || c.code || ')'),
                                  NULL) desc_complication,
                           ech.description,
                           ech.dt_verif_comp,
                           pk_date_utils.date_char_tsz(i_lang, ech.dt_verif_comp, i_prof.institution, i_prof.software) dt_verif_comp_desc,
                           ech.dt_verif_req,
                           pk_date_utils.date_char_tsz(i_lang, ech.dt_verif_req, i_prof.institution, i_prof.software) dt_verif_req_desc,
                           ech.id_clin_serv_dest,
                           pk_translation.get_translation(i_lang, cs_d.code_clinical_service) desc_clin_serv_dest,
                           ech.flg_status_comp,
                           pk_sysdomain.get_domain(g_comp_flg_status_domain, ech.flg_status_comp, i_lang) desc_flg_stat_comp,
                           ech.flg_status_req,
                           pk_sysdomain.get_domain(g_req_flg_status_domain, ech.flg_status_req, i_lang) desc_flg_stat_req,
                           ech.notes_comp,
                           ech.notes_req,
                           NULL id_cancel_reason,
                           NULL desc_cancel_reason,
                           NULL notes_cancel,
                           NULL id_reject_reason,
                           NULL desc_reject_reason,
                           NULL notes_rejected,
                           ech.id_prof_create,
                           pk_complication_core.get_prof_name(i_lang, i_prof, ech.id_prof_create) prof_create_name,
                           ech.id_prof_clin_serv,
                           pk_translation.get_translation(i_lang, cs_p.code_clinical_service) desc_prof_clin_serv,
                           ech.dt_epis_complication,
                           pk_date_utils.date_char_tsz(i_lang,
                                                       ech.dt_epis_complication,
                                                       i_prof.institution,
                                                       i_prof.software) dt_epis_comp_desc
                      FROM epis_comp_hist ech
                      LEFT JOIN complication c
                        ON c.id_complication = ech.id_complication
                      LEFT JOIN clinical_service cs_d
                        ON cs_d.id_clinical_service = ech.id_clin_serv_dest
                      LEFT JOIN clinical_service cs_p
                        ON cs_p.id_clinical_service = ech.id_prof_clin_serv
                     WHERE ech.id_epis_comp_hist = i_epis_comp_hist) t;
        END IF;
    
        RETURN l_epis_comp_row;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN l_epis_comp_row;
    END get_epis_comp_rec;

    /**
    * Gets previous record date for the same axe type
    *
    * @param   i_epis_comp                 Epis complication id
    * @param   i_flg_type                  Comp axe type
    * @param   i_cur_date                  Date of the current record
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   25-03-2010
    */
    FUNCTION get_prev_ecd_dt
    (
        i_epis_comp IN epis_comp_detail.id_epis_complication%TYPE,
        i_flg_type  IN comp_axe.id_sys_list%TYPE,
        i_cur_date  IN epis_comp_detail.dt_epis_comp_detail%TYPE
    ) RETURN epis_comp_detail.dt_epis_comp_detail%TYPE IS
        l_func_name VARCHAR2(30) := 'GET_PREV_ECD_DT';
        --
        l_date           epis_comp_detail.dt_epis_comp_detail%TYPE;
        l_epis_comp_hist epis_comp_hist.id_epis_comp_hist%TYPE;
        l_hist_date      epis_comp_hist.dt_epis_complication%TYPE;
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        BEGIN
            g_error := 'GET LAST DATE (i_epis_comp: ' || to_char(i_epis_comp) || '; i_flg_type: ' ||
                       to_char(i_flg_type) || '; i_cur_date: ' || to_char(i_cur_date) || ')';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            SELECT ecd2.id_epis_comp_hist, ecd2.dt_epis_comp_detail
              INTO l_epis_comp_hist, l_date
              FROM epis_comp_detail ecd2
              JOIN comp_axe ca2
                ON ca2.id_comp_axe = ecd2.id_comp_axe
               AND ca2.id_sys_list = i_flg_type
             WHERE ecd2.id_epis_complication = i_epis_comp
               AND ecd2.dt_epis_comp_detail = (SELECT MAX(ecd.dt_epis_comp_detail)
                                                 FROM epis_comp_detail ecd
                                                 JOIN comp_axe ca
                                                   ON ca.id_comp_axe = ecd.id_comp_axe
                                                  AND ca.id_sys_list = i_flg_type
                                                WHERE ecd.id_epis_complication = i_epis_comp
                                                  AND ecd.dt_epis_comp_detail <= i_cur_date)
            --The group by is necessary because in the case of locations, for example, multiple rows are returned
             GROUP BY ecd2.id_epis_comp_hist, ecd2.dt_epis_comp_detail;
        
            IF l_epis_comp_hist IS NOT NULL
            THEN
                g_error := 'GET HIST DATE';
                alertlog.pk_alertlog.log_info(text            => g_error,
                                              object_name     => g_package,
                                              sub_object_name => l_func_name);
                SELECT ech.dt_epis_complication
                  INTO l_hist_date
                  FROM epis_comp_hist ech
                 WHERE ech.id_epis_comp_hist = l_epis_comp_hist;
            
                g_error := 'VERIFY IF HIST DATE IS THE CORRECT DATE';
                alertlog.pk_alertlog.log_info(text            => g_error,
                                              object_name     => g_package,
                                              sub_object_name => l_func_name);
                IF l_hist_date > l_date
                   AND l_hist_date < i_cur_date
                THEN
                    l_date := l_hist_date;
                END IF;
            END IF;
        EXCEPTION
            WHEN no_data_found THEN
                l_date := NULL;
        END;
    
        RETURN l_date;
    END get_prev_ecd_dt;

    /**
    * Gets previous professional record date
    *
    * @param   i_epis_comp                 Epis complication id
    * @param   i_cur_date                  Date of the current record
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   25-03-2010
    */
    FUNCTION get_prev_ecp_dt
    (
        i_epis_comp IN epis_comp_prof.id_epis_complication%TYPE,
        i_cur_date  IN epis_comp_prof.dt_epis_comp_prof%TYPE
    ) RETURN epis_comp_prof.dt_epis_comp_prof%TYPE IS
        l_func_name VARCHAR2(30) := 'GET_PREV_ECP_DT';
        --
        l_date           epis_comp_prof.dt_epis_comp_prof%TYPE;
        l_epis_comp_hist epis_comp_hist.id_epis_comp_hist%TYPE;
        l_hist_date      epis_comp_hist.dt_epis_complication%TYPE;
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        BEGIN
            g_error := 'GET LAST DATE (i_epis_comp: ' || to_char(i_epis_comp) || '; i_cur_date: ' ||
                       to_char(i_cur_date) || ')';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            SELECT ecp2.id_epis_comp_hist, ecp2.dt_epis_comp_prof
              INTO l_epis_comp_hist, l_date
              FROM epis_comp_prof ecp2
             WHERE ecp2.id_epis_complication = i_epis_comp
               AND ecp2.dt_epis_comp_prof = (SELECT MAX(ecp.dt_epis_comp_prof)
                                               FROM epis_comp_prof ecp
                                             --JOIN epis_comp_hist ech ON ech.id_epis_comp_hist = ecp.id_epis_comp_hist
                                              WHERE ecp.id_epis_complication = i_epis_comp
                                                   --AND ech.dt_epis_complication <= i_cur_date
                                                AND ecp.dt_epis_comp_prof <= i_cur_date)
            --The group by is necessary because the epis_comp can have more them one prof
             GROUP BY ecp2.id_epis_comp_hist, ecp2.dt_epis_comp_prof;
        
            IF l_epis_comp_hist IS NOT NULL
            THEN
                g_error := 'GET HIST DATE';
                alertlog.pk_alertlog.log_info(text            => g_error,
                                              object_name     => g_package,
                                              sub_object_name => l_func_name);
                SELECT ech.dt_epis_complication
                  INTO l_hist_date
                  FROM epis_comp_hist ech
                 WHERE ech.id_epis_comp_hist = l_epis_comp_hist;
            
                g_error := 'VERIFY IF HIST DATE IS THE CORRECT DATE';
                alertlog.pk_alertlog.log_info(text            => g_error,
                                              object_name     => g_package,
                                              sub_object_name => l_func_name);
                IF l_hist_date > l_date
                   AND l_hist_date < i_cur_date
                THEN
                    l_date := l_hist_date;
                END IF;
            END IF;
        EXCEPTION
            WHEN no_data_found THEN
                l_date := NULL;
        END;
    
        RETURN l_date;
    END get_prev_ecp_dt;

    /**
    * Compares epis_complication records and returns column changes
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_prev_row                  Previous row
    * @param   i_curr_row                  Current row
    * @param   o_left_columns               Left column label (Flag with new status)
    * @param   o_left_values               Left column values (Professional who made the change and when)
    * @param   o_right_labels              Right column labels changed
    * @param   o_right_values              Right column values changed
    * @param   o_info_labels               Info column labels (Information to flash such as RECORD_STATE)
    * @param   o_info_values               Info column values (Corresponding value of info_label)
    *
    * @return  TRUE if curr row has changes, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   04-01-2010
    */
    FUNCTION compare_epis_comp_rec
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_prev_row     IN pk_complication_core.epis_comp_rec,
        i_curr_row     IN pk_complication_core.epis_comp_rec,
        o_left_columns OUT table_varchar,
        o_left_values  OUT table_varchar,
        o_right_labels OUT table_varchar,
        o_right_values OUT table_varchar,
        o_info_labels  OUT table_varchar,
        o_info_values  OUT table_varchar
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'COMPARE_EPIS_COMP_REC';
        --
        l_left_columns    table_varchar := table_varchar();
        l_left_values     table_varchar := table_varchar();
        l_right_labels    table_varchar := table_varchar();
        l_right_values    table_varchar := table_varchar();
        l_info_labels     table_varchar := table_varchar();
        l_info_values     table_varchar := table_varchar();
        l_is_complication BOOLEAN;
        l_is_request      VARCHAR2(1);
        l_curr_str        VARCHAR2(32767);
        --
        l_rec_ecp_create t_rec_epis_comp_prof_create;
        --
        l_error t_error_out;
        --
        FUNCTION get_comp_axe
        (
            i_row           IN pk_complication_core.epis_comp_rec,
            i_flg_type      IN comp_axe.id_sys_list%TYPE,
            i_is_to_compare IN VARCHAR2 DEFAULT pk_alert_constant.g_yes
        ) RETURN VARCHAR2 IS
            l_sub_func_name VARCHAR2(30) := 'GET_COMP_AXE';
            --
            l_axe_desc VARCHAR2(32767);
            l_prev_dt  epis_comp_detail.dt_epis_comp_detail%TYPE := pk_complication_core.get_prev_ecd_dt(i_epis_comp => i_row.id_epis_complication,
                                                                                                         i_flg_type  => i_flg_type,
                                                                                                         i_cur_date  => i_row.dt_epis_complication);
        BEGIN
            g_error := 'Init';
            alertlog.pk_alertlog.log_info(text            => g_error,
                                          object_name     => g_package,
                                          sub_object_name => l_sub_func_name);
        
            g_error := 'GET VALUE';
            alertlog.pk_alertlog.log_info(text            => g_error,
                                          object_name     => g_package,
                                          sub_object_name => l_sub_func_name);
            SELECT pk_utils.concat_table(CAST(MULTISET (SELECT lvl.lst_descs desc_axe
                                                 FROM epis_comp_detail ecd
                                                 JOIN TABLE(pk_complication_core.tf_comp_axe_lvl(i_lang, i_prof, i_flg_type)) lvl
                                                   ON lvl.id_comp_axe = ecd.id_comp_axe
                                                WHERE ecd.id_epis_complication = i_row.id_epis_complication
                                                  AND ((i_is_to_compare = pk_alert_constant.g_yes AND
                                                      ecd.dt_epis_comp_detail BETWEEN
                                                      nvl(l_prev_dt, i_row.dt_epis_complication) AND
                                                      nvl(i_row.dt_epis_complication, g_sysdate_tstz)) OR
                                                      (i_is_to_compare = pk_alert_constant.g_no AND
                                                      ecd.dt_epis_comp_detail = i_row.dt_epis_complication))
                                                ORDER BY desc_axe) AS table_varchar),
                                         g_delim_screen_show)
              INTO l_axe_desc
              FROM dual;
        
            RETURN l_axe_desc;
        END get_comp_axe;
    
        FUNCTION get_assoc_task
        (
            i_row           IN pk_complication_core.epis_comp_rec,
            i_is_to_compare IN VARCHAR2 DEFAULT pk_alert_constant.g_yes
        ) RETURN VARCHAR2 IS
            l_sub_func_name VARCHAR2(30) := 'GET_ASSOC_TASK';
            --
            l_assoc_task VARCHAR2(32767);
        BEGIN
            g_error := 'Init';
            alertlog.pk_alertlog.log_info(text            => g_error,
                                          object_name     => g_package,
                                          sub_object_name => l_sub_func_name);
        
            g_error := 'GET VALUE';
            alertlog.pk_alertlog.log_info(text            => g_error,
                                          object_name     => g_package,
                                          sub_object_name => l_sub_func_name);
            SELECT pk_utils.concat_table(CAST(MULTISET
                                              (SELECT pk_translation.get_translation(i_lang, ca.code_comp_axe) ||
                                                      decode(pk_complication_core.is_to_show_code(i_lang, i_prof),
                                                             pk_alert_constant.g_yes,
                                                             decode(ca.code, NULL, NULL, ' (' || ca.code || ')'),
                                                             NULL) || ': ' ||
                                                      pk_api_complications.get_task_det(i_lang,
                                                                                        i_prof,
                                                                                        ecd.id_context_new,
                                                                                        ecd.id_sys_list,
                                                                                        g_flg_task_det_n,
                                                                                        g_flg_cfg_typ_assoc_task) desc_task
                                                 FROM epis_comp_detail ecd
                                                 JOIN TABLE(pk_sys_list.tf_sys_list_values(i_lang, i_prof, g_lst_grp_ecd_at_types)) lst
                                                   ON lst.id_sys_list = ecd.id_sys_list
                                                 JOIN comp_axe ca
                                                   ON ca.id_comp_axe = ecd.id_comp_axe
                                                WHERE ecd.id_epis_complication = i_row.id_epis_complication
                                                  AND ecd.dt_context IS NOT NULL
                                                  AND ((i_is_to_compare = pk_alert_constant.g_yes AND
                                                      ecd.dt_epis_comp_detail BETWEEN
                                                      nvl(pk_complication_core.get_prev_ecd_dt(i_row.id_epis_complication,
                                                                                                 ca.id_sys_list,
                                                                                                 i_row.dt_epis_complication),
                                                            i_row.dt_epis_complication) AND
                                                      nvl(i_row.dt_epis_complication, g_sysdate_tstz)) OR
                                                      (i_is_to_compare = pk_alert_constant.g_no AND
                                                      ecd.dt_epis_comp_detail = i_row.dt_epis_complication))
                                               --The order must be the same as get_assoc_task_dt, get_assoc_task_context_prof
                                               --and get_assoc_task_context_prof_sp functions
                                                ORDER BY ecd.id_epis_comp_detail) AS table_varchar),
                                         g_delim_screen_show)
              INTO l_assoc_task
              FROM dual;
        
            RETURN l_assoc_task;
        END get_assoc_task;
    
        FUNCTION get_professionals
        (
            i_row           IN pk_complication_core.epis_comp_rec,
            i_is_to_compare IN VARCHAR2 DEFAULT pk_alert_constant.g_yes
        ) RETURN VARCHAR2 IS
            l_sub_func_name VARCHAR2(30) := 'GET_PROFESSIONALS';
            --
            l_profs   VARCHAR2(32767);
            l_prev_dt epis_comp_prof.dt_epis_comp_prof%TYPE := pk_complication_core.get_prev_ecp_dt(i_row.id_epis_complication,
                                                                                                    i_row.dt_epis_complication);
        BEGIN
            g_error := 'Init';
            alertlog.pk_alertlog.log_info(text            => g_error,
                                          object_name     => g_package,
                                          sub_object_name => l_sub_func_name);
        
            g_error := 'GET VALUE';
            alertlog.pk_alertlog.log_info(text            => g_error,
                                          object_name     => g_package,
                                          sub_object_name => l_sub_func_name);
            SELECT pk_utils.concat_table(CAST(MULTISET (SELECT pk_complication_core.get_prof_name(i_lang,
                                                                                         i_prof,
                                                                                         ecp.id_professional) prof_name
                                                 FROM epis_complication ec
                                                 JOIN epis_comp_prof ecp
                                                   ON ecp.id_epis_complication = ec.id_epis_complication
                                                WHERE ecp.id_epis_complication = i_row.id_epis_complication
                                                  AND ((i_is_to_compare = pk_alert_constant.g_yes AND
                                                      ecp.dt_epis_comp_prof BETWEEN
                                                      nvl(l_prev_dt, i_row.dt_epis_complication) AND
                                                      nvl(i_row.dt_epis_complication, g_sysdate_tstz)) OR
                                                      (i_is_to_compare = pk_alert_constant.g_no AND
                                                      ecp.dt_epis_comp_prof = i_row.dt_epis_complication))
                                                ORDER BY prof_name) AS table_varchar),
                                         g_delim_screen_show)
              INTO l_profs
              FROM dual;
        
            RETURN l_profs;
        END get_professionals;
    
        FUNCTION get_assoc_task_dt
        (
            i_row           IN pk_complication_core.epis_comp_rec,
            i_is_to_compare IN VARCHAR2 DEFAULT pk_alert_constant.g_yes
        ) RETURN VARCHAR2 IS
            l_sub_func_name VARCHAR2(30) := 'GET_ASSOC_TASK_DT';
            --
            l_assoc_task_dt VARCHAR2(32767);
        BEGIN
            g_error := 'Init';
            alertlog.pk_alertlog.log_info(text            => g_error,
                                          object_name     => g_package,
                                          sub_object_name => l_sub_func_name);
        
            g_error := 'GET VALUE';
            alertlog.pk_alertlog.log_info(text            => g_error,
                                          object_name     => g_package,
                                          sub_object_name => l_sub_func_name);
            SELECT pk_utils.concat_table(CAST(MULTISET (SELECT pk_date_utils.date_char_tsz(i_lang,
                                                                                  ecd.dt_context,
                                                                                  i_prof.institution,
                                                                                  i_prof.software) task_date_desc
                                                 FROM epis_comp_detail ecd
                                                 JOIN TABLE(pk_sys_list.tf_sys_list_values(i_lang, i_prof, g_lst_grp_ecd_at_types)) lst
                                                   ON lst.id_sys_list = ecd.id_sys_list
                                                 JOIN comp_axe ca
                                                   ON ca.id_comp_axe = ecd.id_comp_axe
                                                WHERE ecd.id_epis_complication = i_row.id_epis_complication
                                                  AND ecd.dt_context IS NOT NULL
                                                  AND ((i_is_to_compare = pk_alert_constant.g_yes AND
                                                      ecd.dt_epis_comp_detail BETWEEN
                                                      nvl(pk_complication_core.get_prev_ecd_dt(i_row.id_epis_complication,
                                                                                                 ca.id_sys_list,
                                                                                                 i_row.dt_epis_complication),
                                                            i_row.dt_epis_complication) AND
                                                      nvl(i_row.dt_epis_complication, g_sysdate_tstz)) OR
                                                      (i_is_to_compare = pk_alert_constant.g_no AND
                                                      ecd.dt_epis_comp_detail = i_row.dt_epis_complication))
                                               --The order must be the same as get_assoc_task function
                                                ORDER BY ecd.id_epis_comp_detail) AS table_varchar),
                                         g_delim_screen_show)
              INTO l_assoc_task_dt
              FROM dual;
        
            RETURN l_assoc_task_dt;
        END get_assoc_task_dt;
    
        FUNCTION get_assoc_task_context_prof
        (
            i_row           IN pk_complication_core.epis_comp_rec,
            i_is_to_compare IN VARCHAR2 DEFAULT pk_alert_constant.g_yes
        ) RETURN VARCHAR2 IS
            l_sub_func_name VARCHAR2(30) := 'GET_ASSOC_TASK_CONTEXT_PROF';
            --
            l_profs VARCHAR2(32767);
        BEGIN
            g_error := 'Init';
            alertlog.pk_alertlog.log_info(text            => g_error,
                                          object_name     => g_package,
                                          sub_object_name => l_sub_func_name);
        
            g_error := 'GET VALUE';
            alertlog.pk_alertlog.log_info(text            => g_error,
                                          object_name     => g_package,
                                          sub_object_name => l_sub_func_name);
            SELECT pk_utils.concat_table(CAST(MULTISET (SELECT pk_complication_core.get_prof_name(i_lang,
                                                                                         i_prof,
                                                                                         ecd.id_context_prof) prof_name
                                                 FROM epis_comp_detail ecd
                                                 JOIN TABLE(pk_sys_list.tf_sys_list_values(i_lang, i_prof, g_lst_grp_ecd_at_types)) lst
                                                   ON lst.id_sys_list = ecd.id_sys_list
                                                 JOIN comp_axe ca
                                                   ON ca.id_comp_axe = ecd.id_comp_axe
                                                WHERE ecd.id_epis_complication = i_row.id_epis_complication
                                                  AND ecd.dt_context IS NOT NULL
                                                  AND ((i_is_to_compare = pk_alert_constant.g_yes AND
                                                      ecd.dt_epis_comp_detail BETWEEN
                                                      nvl(pk_complication_core.get_prev_ecd_dt(i_row.id_epis_complication,
                                                                                                 ca.id_sys_list,
                                                                                                 i_row.dt_epis_complication),
                                                            i_row.dt_epis_complication) AND
                                                      nvl(i_row.dt_epis_complication, g_sysdate_tstz)) OR
                                                      (i_is_to_compare = pk_alert_constant.g_no AND
                                                      ecd.dt_epis_comp_detail = i_row.dt_epis_complication))
                                               --The order must be the same as get_assoc_task function
                                                ORDER BY ecd.id_epis_comp_detail, prof_name) AS table_varchar),
                                         g_delim_screen_show)
              INTO l_profs
              FROM dual;
        
            RETURN l_profs;
        END get_assoc_task_context_prof;
    
        FUNCTION get_assoc_task_context_prof_sp
        (
            i_row           IN pk_complication_core.epis_comp_rec,
            i_is_to_compare IN VARCHAR2 DEFAULT pk_alert_constant.g_yes
        ) RETURN VARCHAR2 IS
            l_sub_func_name VARCHAR2(30) := 'GET_ASSOC_TASK_CONTEXT_PROF_SP';
            --
            l_profs VARCHAR2(32767);
        BEGIN
            g_error := 'Init';
            alertlog.pk_alertlog.log_info(text            => g_error,
                                          object_name     => g_package,
                                          sub_object_name => l_sub_func_name);
        
            g_error := 'GET VALUE';
            alertlog.pk_alertlog.log_info(text            => g_error,
                                          object_name     => g_package,
                                          sub_object_name => l_sub_func_name);
            SELECT pk_utils.concat_table(CAST(MULTISET (SELECT pk_complication_core.get_prof_name(i_lang,
                                                                                         i_prof,
                                                                                         ecd.id_context_prof_spec) prof_name
                                                 FROM epis_comp_detail ecd
                                                 JOIN TABLE(pk_sys_list.tf_sys_list_values(i_lang, i_prof, g_lst_grp_ecd_at_types)) lst
                                                   ON lst.id_sys_list = ecd.id_sys_list
                                                 JOIN comp_axe ca
                                                   ON ca.id_comp_axe = ecd.id_comp_axe
                                                WHERE ecd.id_epis_complication = i_row.id_epis_complication
                                                  AND ecd.dt_context IS NOT NULL
                                                  AND ((i_is_to_compare = pk_alert_constant.g_yes AND
                                                      ecd.dt_epis_comp_detail BETWEEN
                                                      nvl(pk_complication_core.get_prev_ecd_dt(i_row.id_epis_complication,
                                                                                                 ca.id_sys_list,
                                                                                                 i_row.dt_epis_complication),
                                                            i_row.dt_epis_complication) AND
                                                      nvl(i_row.dt_epis_complication, g_sysdate_tstz)) OR
                                                      (i_is_to_compare = pk_alert_constant.g_no AND
                                                      ecd.dt_epis_comp_detail = i_row.dt_epis_complication))
                                               --The order must be the same as get_assoc_task function
                                                ORDER BY ecd.id_epis_comp_detail, prof_name) AS table_varchar),
                                         g_delim_screen_show)
              INTO l_profs
              FROM dual;
        
            RETURN l_profs;
        END get_assoc_task_context_prof_sp;
    
        FUNCTION get_diagnosis(i_row IN pk_complication_core.epis_comp_rec) RETURN VARCHAR2 IS
            l_sub_func_name VARCHAR2(30) := 'GET_DIAGNOSIS';
            --
            l_diag VARCHAR2(32767);
        BEGIN
            g_error := 'Init';
            alertlog.pk_alertlog.log_info(text            => g_error,
                                          object_name     => g_package,
                                          sub_object_name => l_sub_func_name);
        
            g_error := 'GET VALUE';
            alertlog.pk_alertlog.log_info(text            => g_error,
                                          object_name     => g_package,
                                          sub_object_name => l_sub_func_name);
            SELECT pk_utils.concat_table(CAST(MULTISET (SELECT pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                                                 i_prof                => i_prof,
                                                                                 i_id_alert_diagnosis  => ed.id_alert_diagnosis,
                                                                                 i_id_diagnosis        => d.id_diagnosis,
                                                                                 i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                                                                 i_code                => d.code_icd,
                                                                                 i_flg_other           => d.flg_other,
                                                                                 i_flg_std_diag        => pk_alert_constant.g_yes) desc_diagnosis
                                                 FROM mcdt_req_diagnosis mrd
                                                 JOIN epis_complication ec
                                                   ON ec.id_epis_complication = mrd.id_epis_complication
                                                 JOIN diagnosis d
                                                   ON d.id_diagnosis = mrd.id_diagnosis
                                                 JOIN epis_diagnosis ed
                                                   ON ed.id_epis_diagnosis = mrd.id_epis_diagnosis
                                                WHERE mrd.id_epis_complication = i_row.id_epis_complication
                                                  AND nvl(mrd.id_epis_comp_hist, g_epis_comp_curr_row) =
                                                      i_row.id_epis_comp_hist
                                                ORDER BY desc_diagnosis) AS table_varchar),
                                         g_delim_screen_show)
              INTO l_diag
              FROM dual;
        
            RETURN l_diag;
        END get_diagnosis;
    
        FUNCTION get_treat_performed
        (
            i_row           IN pk_complication_core.epis_comp_rec,
            i_is_to_compare IN VARCHAR2 DEFAULT pk_alert_constant.g_yes
        ) RETURN VARCHAR2 IS
            l_sub_func_name VARCHAR2(30) := 'GET_TREAT_PERFORMED';
            --
            l_treat_perf VARCHAR2(32767);
        BEGIN
            g_error := 'Init';
            alertlog.pk_alertlog.log_info(text            => g_error,
                                          object_name     => g_package,
                                          sub_object_name => l_sub_func_name);
        
            g_error := 'GET VALUE';
            alertlog.pk_alertlog.log_info(text            => g_error,
                                          object_name     => g_package,
                                          sub_object_name => l_sub_func_name);
            SELECT pk_utils.concat_table(CAST(MULTISET
                                              (SELECT pk_translation.get_translation(i_lang, ca.code_comp_axe) ||
                                                      decode(pk_complication_core.is_to_show_code(i_lang, i_prof),
                                                             pk_alert_constant.g_yes,
                                                             decode(ca.code, NULL, NULL, ' (' || ca.code || ')'),
                                                             NULL) || ': ' ||
                                                      pk_api_complications.get_task_det(i_lang,
                                                                                        i_prof,
                                                                                        ecd.id_context_new,
                                                                                        ecd.id_sys_list,
                                                                                        g_flg_task_det_n,
                                                                                        g_flg_cfg_typ_treat_perf) desc_treat_perf
                                                 FROM epis_comp_detail ecd
                                                 JOIN TABLE(pk_sys_list.tf_sys_list_values(i_lang, i_prof, g_lst_grp_ecd_tp_types)) lst
                                                   ON lst.id_sys_list = ecd.id_sys_list
                                                  AND ecd.id_epis_complication = i_row.id_epis_complication
                                                 JOIN comp_axe ca
                                                   ON ca.id_comp_axe = ecd.id_comp_axe
                                                WHERE ecd.dt_context IS NULL
                                                  AND ((i_is_to_compare = pk_alert_constant.g_yes AND
                                                      ecd.dt_epis_comp_detail BETWEEN
                                                      nvl(pk_complication_core.get_prev_ecd_dt(i_row.id_epis_complication,
                                                                                                 ca.id_sys_list,
                                                                                                 i_row.dt_epis_complication),
                                                            i_row.dt_epis_complication) AND
                                                      nvl(i_row.dt_epis_complication, g_sysdate_tstz)) OR
                                                      (i_is_to_compare = pk_alert_constant.g_no AND
                                                      ecd.dt_epis_comp_detail = i_row.dt_epis_complication))
                                                ORDER BY desc_treat_perf) AS table_varchar),
                                         g_delim_screen_show)
              INTO l_treat_perf
              FROM dual;
        
            RETURN l_treat_perf;
        END get_treat_performed;
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'Set status info label';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_info_labels.extend();
        l_info_labels(l_info_labels.count) := 'RECORD_STATE';
    
        l_left_columns.extend();
        l_left_columns(l_left_columns.count) := 'DESC_FLG_STATUS';
    
        g_error := 'Verify if current row is a complication or a request';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF i_curr_row.id_epis_comp_hist IS NOT NULL
           AND i_curr_row.flg_status_req IS NOT NULL
           AND (i_curr_row.flg_status_req != g_req_flg_status_a OR
           (i_curr_row.flg_status_req = g_req_flg_status_a AND i_curr_row.flg_status_comp IS NULL))
        THEN
            l_is_complication := FALSE; --is a request
            l_is_request      := pk_alert_constant.g_yes;
        
            g_error := 'GET PROF CREATE INFO';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            SELECT t_rec_epis_comp_prof_create(t.id_epis_complication,
                                               t.id_professional,
                                               t.prof_name,
                                               t.id_prof_clin_serv,
                                               t.desc_clin_serv,
                                               t.dt_create)
              INTO l_rec_ecp_create
              FROM TABLE(pk_complication_core.tf_epis_comp_prof_create(i_lang,
                                                                       i_prof,
                                                                       i_curr_row.id_epis_complication,
                                                                       g_epis_comp_typ_r)) t;
        
            g_error := 'Get request status label';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            l_left_values.extend();
            IF is_column_visible(i_lang              => i_lang,
                                 i_prof              => i_prof,
                                 i_ec_clin_serv_dest => i_curr_row.id_clin_serv_dest,
                                 i_ec_prof_clin_serv => l_rec_ecp_create.id_prof_clin_serv,
                                 i_column_name       => 'REQ_DESC_STATUS',
                                 i_is_request        => l_is_request) = pk_alert_constant.g_yes
            THEN
                l_left_values(l_left_values.count) := pk_utils.to_bold(i_curr_row.desc_flg_stat_req);
            ELSE
                l_left_values(l_left_values.count) := g_encrypted_text;
            END IF;
        
            g_error := 'Status info value';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            l_info_values.extend();
            l_info_values(l_info_values.count) := i_curr_row.flg_status_req;
        ELSE
            l_is_complication := TRUE; --is a complication
            l_is_request      := pk_alert_constant.g_no;
        
            g_error := 'GET PROF CREATE INFO';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            SELECT t_rec_epis_comp_prof_create(t.id_epis_complication,
                                               t.id_professional,
                                               t.prof_name,
                                               t.id_prof_clin_serv,
                                               t.desc_clin_serv,
                                               t.dt_create)
              INTO l_rec_ecp_create
              FROM TABLE(pk_complication_core.tf_epis_comp_prof_create(i_lang,
                                                                       i_prof,
                                                                       i_curr_row.id_epis_complication,
                                                                       g_epis_comp_typ_c)) t;
        
            g_error := 'Get complicaton status label';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            l_left_values.extend();
            IF is_column_visible(i_lang              => i_lang,
                                 i_prof              => i_prof,
                                 i_ec_clin_serv_dest => i_curr_row.id_clin_serv_dest,
                                 i_ec_prof_clin_serv => l_rec_ecp_create.id_prof_clin_serv,
                                 i_column_name       => 'DESC_STATUS',
                                 i_is_request        => l_is_request) = pk_alert_constant.g_yes
            THEN
                l_left_values(l_left_values.count) := pk_utils.to_bold(i_curr_row.desc_flg_stat_comp);
            ELSE
                l_left_values(l_left_values.count) := g_encrypted_text;
            END IF;
        
            g_error := 'Status info value';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            l_info_values.extend();
            l_info_values(l_info_values.count) := i_curr_row.flg_status_comp;
        END IF;
    
        g_error := 'SET INFO FOR FLASH';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        --flash is waiting the following information: PROF_REG, DT_REG and PROF_SPEC_REG
        l_left_columns.extend();
        l_left_columns(l_left_columns.count) := 'PROF_REG';
        l_left_values.extend();
        IF is_column_visible(i_lang              => i_lang,
                             i_prof              => i_prof,
                             i_ec_clin_serv_dest => i_curr_row.id_clin_serv_dest,
                             i_ec_prof_clin_serv => l_rec_ecp_create.id_prof_clin_serv,
                             i_column_name       => CASE l_is_request
                                                        WHEN pk_alert_constant.g_yes THEN
                                                         'REQ_PROFESSIONAL'
                                                        ELSE
                                                         'PROFESSIONAL'
                                                    END,
                             i_is_request        => l_is_request) = pk_alert_constant.g_yes
        THEN
            l_left_values(l_left_values.count) := i_curr_row.prof_create_name;
        ELSE
            l_left_values(l_left_values.count) := g_encrypted_text;
        END IF;
        l_left_columns.extend();
        l_left_columns(l_left_columns.count) := 'DT_REG';
        l_left_values.extend();
        IF is_column_visible(i_lang              => i_lang,
                             i_prof              => i_prof,
                             i_ec_clin_serv_dest => i_curr_row.id_clin_serv_dest,
                             i_ec_prof_clin_serv => l_rec_ecp_create.id_prof_clin_serv,
                             i_column_name       => CASE l_is_request
                                                        WHEN pk_alert_constant.g_yes THEN
                                                         'REQ_REGISTRY_DATE'
                                                        ELSE
                                                         'REGISTRY_DATE'
                                                    END,
                             i_is_request        => l_is_request) = pk_alert_constant.g_yes
        THEN
            l_left_values(l_left_values.count) := i_curr_row.dt_epis_comp_desc;
        ELSE
            l_left_values(l_left_values.count) := g_encrypted_text;
        END IF;
        l_left_columns.extend();
        l_left_columns(l_left_columns.count) := 'PROF_SPEC_REG';
        l_left_values.extend();
        IF is_column_visible(i_lang              => i_lang,
                             i_prof              => i_prof,
                             i_ec_clin_serv_dest => i_curr_row.id_clin_serv_dest,
                             i_ec_prof_clin_serv => l_rec_ecp_create.id_prof_clin_serv,
                             i_column_name       => CASE l_is_request
                                                        WHEN pk_alert_constant.g_yes THEN
                                                         'REQ_PROFESSIONAL'
                                                        ELSE
                                                         'PROFESSIONAL'
                                                    END,
                             i_is_request        => l_is_request) = pk_alert_constant.g_yes
        THEN
            l_left_values(l_left_values.count) := pk_prof_utils.get_spec_signature(i_lang    => i_lang,
                                                                                   i_prof    => i_prof,
                                                                                   i_prof_id => i_curr_row.id_prof_create,
                                                                                   i_dt_reg  => i_curr_row.dt_epis_complication,
                                                                                   i_episode => i_curr_row.id_episode);
        ELSE
            l_left_values(l_left_values.count) := g_encrypted_text;
        END IF;
    
        IF l_is_complication
        THEN
            g_error := 'Complication';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            IF nvl(i_prev_row.desc_complication, '-') != i_curr_row.desc_complication
            THEN
                l_right_labels.extend();
                l_right_labels(l_right_labels.count) := pk_utils.to_bold(i_text => pk_message.get_message(i_lang      => i_lang,
                                                                                                          i_code_mess => g_msg_complication));
                l_right_values.extend();
                IF is_column_visible(i_lang              => i_lang,
                                     i_prof              => i_prof,
                                     i_ec_clin_serv_dest => i_curr_row.id_clin_serv_dest,
                                     i_ec_prof_clin_serv => l_rec_ecp_create.id_prof_clin_serv,
                                     i_column_name       => 'DESC_COMPLICATION',
                                     i_is_request        => l_is_request) = pk_alert_constant.g_yes
                THEN
                    l_right_values(l_right_values.count) := i_curr_row.desc_complication;
                ELSE
                    l_right_values(l_right_values.count) := g_encrypted_text;
                END IF;
            END IF;
        
            g_error := 'Pathology';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            IF nvl(get_comp_axe(i_prev_row, get_axe_typ_path(i_lang, i_prof)), '-') !=
               get_comp_axe(i_curr_row, get_axe_typ_path(i_lang, i_prof))
            THEN
                l_right_labels.extend();
                l_right_labels(l_right_labels.count) := pk_utils.to_bold(i_text => pk_message.get_message(i_lang      => i_lang,
                                                                                                          i_code_mess => g_msg_pathology));
                l_right_values.extend();
                IF is_column_visible(i_lang              => i_lang,
                                     i_prof              => i_prof,
                                     i_ec_clin_serv_dest => i_curr_row.id_clin_serv_dest,
                                     i_ec_prof_clin_serv => l_rec_ecp_create.id_prof_clin_serv,
                                     i_column_name       => 'PATHOLOGY',
                                     i_is_request        => l_is_request) = pk_alert_constant.g_yes
                THEN
                    l_right_values(l_right_values.count) := get_comp_axe(i_curr_row,
                                                                         get_axe_typ_path(i_lang, i_prof),
                                                                         pk_alert_constant.g_no);
                ELSE
                    l_right_values(l_right_values.count) := g_encrypted_text;
                END IF;
            END IF;
        
            g_error := 'Location';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            IF nvl(get_comp_axe(i_prev_row, get_axe_typ_loc(i_lang, i_prof)), '-') !=
               get_comp_axe(i_curr_row, get_axe_typ_loc(i_lang, i_prof))
            THEN
                l_right_labels.extend();
                l_right_labels(l_right_labels.count) := pk_utils.to_bold(i_text => pk_message.get_message(i_lang      => i_lang,
                                                                                                          i_code_mess => g_msg_location));
                l_right_values.extend();
                IF is_column_visible(i_lang              => i_lang,
                                     i_prof              => i_prof,
                                     i_ec_clin_serv_dest => i_curr_row.id_clin_serv_dest,
                                     i_ec_prof_clin_serv => l_rec_ecp_create.id_prof_clin_serv,
                                     i_column_name       => 'LOCATION',
                                     i_is_request        => l_is_request) = pk_alert_constant.g_yes
                THEN
                    l_right_values(l_right_values.count) := get_comp_axe(i_curr_row,
                                                                         get_axe_typ_loc(i_lang, i_prof),
                                                                         pk_alert_constant.g_no);
                ELSE
                    l_right_values(l_right_values.count) := g_encrypted_text;
                END IF;
            END IF;
        
            g_error := 'External factores';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            IF nvl(get_comp_axe(i_prev_row, get_axe_typ_ext_fact(i_lang, i_prof)), '-') !=
               nvl(get_comp_axe(i_curr_row, get_axe_typ_ext_fact(i_lang, i_prof)), '-')
            THEN
                l_right_labels.extend();
                l_right_labels(l_right_labels.count) := pk_utils.to_bold(i_text => pk_message.get_message(i_lang      => i_lang,
                                                                                                          i_code_mess => g_msg_external_factors));
                l_right_values.extend();
                IF is_column_visible(i_lang              => i_lang,
                                     i_prof              => i_prof,
                                     i_ec_clin_serv_dest => i_curr_row.id_clin_serv_dest,
                                     i_ec_prof_clin_serv => l_rec_ecp_create.id_prof_clin_serv,
                                     i_column_name       => 'EXTERNAL_FACTOR',
                                     i_is_request        => l_is_request) = pk_alert_constant.g_yes
                THEN
                    l_right_values(l_right_values.count) := get_comp_axe(i_curr_row,
                                                                         get_axe_typ_ext_fact(i_lang, i_prof),
                                                                         pk_alert_constant.g_no);
                ELSE
                    l_right_values(l_right_values.count) := g_encrypted_text;
                END IF;
            END IF;
        
            g_error := 'Verification date';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            IF nvl(i_prev_row.dt_verif_comp_desc, '-') != nvl(i_curr_row.dt_verif_comp_desc, '-')
            THEN
                l_right_labels.extend();
                l_right_labels(l_right_labels.count) := pk_utils.to_bold(i_text => pk_message.get_message(i_lang      => i_lang,
                                                                                                          i_code_mess => g_msg_verification_date));
                l_right_values.extend();
                IF is_column_visible(i_lang              => i_lang,
                                     i_prof              => i_prof,
                                     i_ec_clin_serv_dest => i_curr_row.id_clin_serv_dest,
                                     i_ec_prof_clin_serv => l_rec_ecp_create.id_prof_clin_serv,
                                     i_column_name       => 'DT_VERIF_COMP',
                                     i_is_request        => l_is_request) = pk_alert_constant.g_yes
                THEN
                    l_right_values(l_right_values.count) := i_curr_row.dt_verif_comp_desc;
                ELSE
                    l_right_values(l_right_values.count) := g_encrypted_text;
                END IF;
            END IF;
        
            g_error := 'Associated episode';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            IF nvl(i_prev_row.desc_episode_origin, '-') != nvl(i_curr_row.desc_episode_origin, '-')
            THEN
                l_right_labels.extend();
                l_right_labels(l_right_labels.count) := pk_utils.to_bold(i_text => pk_message.get_message(i_lang      => i_lang,
                                                                                                          i_code_mess => g_msg_associated_episode));
                l_right_values.extend();
                IF is_column_visible(i_lang              => i_lang,
                                     i_prof              => i_prof,
                                     i_ec_clin_serv_dest => i_curr_row.id_clin_serv_dest,
                                     i_ec_prof_clin_serv => l_rec_ecp_create.id_prof_clin_serv,
                                     i_column_name       => 'DESC_EPISODE_ORIGIN',
                                     i_is_request        => l_is_request) = pk_alert_constant.g_yes
                THEN
                    l_right_values(l_right_values.count) := i_curr_row.desc_episode_origin;
                ELSE
                    l_right_values(l_right_values.count) := g_encrypted_text;
                END IF;
            END IF;
        
            g_error := 'Associated task';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            IF nvl(get_assoc_task(i_prev_row), '-') != nvl(get_assoc_task(i_curr_row), '-')
            THEN
                l_right_labels.extend();
                l_right_labels(l_right_labels.count) := pk_utils.to_bold(i_text => pk_message.get_message(i_lang      => i_lang,
                                                                                                          i_code_mess => g_msg_associated_task));
                l_right_values.extend();
                IF is_column_visible(i_lang              => i_lang,
                                     i_prof              => i_prof,
                                     i_ec_clin_serv_dest => i_curr_row.id_clin_serv_dest,
                                     i_ec_prof_clin_serv => l_rec_ecp_create.id_prof_clin_serv,
                                     i_column_name       => 'DESC_ASSOC_TASK',
                                     i_is_request        => l_is_request) = pk_alert_constant.g_yes
                THEN
                    l_right_values(l_right_values.count) := get_assoc_task(i_curr_row, pk_alert_constant.g_no);
                ELSE
                    l_right_values(l_right_values.count) := g_encrypted_text;
                END IF;
            
                g_error := 'Task date';
                alertlog.pk_alertlog.log_info(text            => g_error,
                                              object_name     => g_package,
                                              sub_object_name => l_func_name);
                IF nvl(get_assoc_task_dt(i_prev_row), '-') != nvl(get_assoc_task_dt(i_curr_row), '-')
                THEN
                    l_right_labels.extend();
                    l_right_labels(l_right_labels.count) := pk_utils.to_bold(i_text => pk_message.get_message(i_lang      => i_lang,
                                                                                                              i_code_mess => g_msg_task_date));
                    l_right_values.extend();
                    IF is_column_visible(i_lang              => i_lang,
                                         i_prof              => i_prof,
                                         i_ec_clin_serv_dest => i_curr_row.id_clin_serv_dest,
                                         i_ec_prof_clin_serv => l_rec_ecp_create.id_prof_clin_serv,
                                         i_column_name       => 'ASSOCIATED_TASK_DT',
                                         i_is_request        => l_is_request) = pk_alert_constant.g_yes
                    THEN
                        l_right_values(l_right_values.count) := get_assoc_task_dt(i_curr_row, pk_alert_constant.g_no);
                    ELSE
                        l_right_values(l_right_values.count) := g_encrypted_text;
                    END IF;
                END IF;
            
                g_error := 'Task responsible physician';
                alertlog.pk_alertlog.log_info(text            => g_error,
                                              object_name     => g_package,
                                              sub_object_name => l_func_name);
                IF nvl(get_assoc_task_context_prof(i_prev_row), '-') !=
                   nvl(get_assoc_task_context_prof(i_curr_row), '-')
                THEN
                    l_right_labels.extend();
                    l_right_labels(l_right_labels.count) := pk_utils.to_bold(i_text => pk_message.get_message(i_lang      => i_lang,
                                                                                                              i_code_mess => g_msg_task_resp_phys));
                    l_right_values.extend();
                    IF is_column_visible(i_lang              => i_lang,
                                         i_prof              => i_prof,
                                         i_ec_clin_serv_dest => i_curr_row.id_clin_serv_dest,
                                         i_ec_prof_clin_serv => l_rec_ecp_create.id_prof_clin_serv,
                                         i_column_name       => 'DESC_ASSOC_TASK',
                                         i_is_request        => l_is_request) = pk_alert_constant.g_yes
                    THEN
                        l_right_values(l_right_values.count) := get_assoc_task_context_prof(i_curr_row,
                                                                                            pk_alert_constant.g_no);
                    ELSE
                        l_right_values(l_right_values.count) := g_encrypted_text;
                    END IF;
                END IF;
            
                g_error := 'Task specialist physician';
                alertlog.pk_alertlog.log_info(text            => g_error,
                                              object_name     => g_package,
                                              sub_object_name => l_func_name);
                IF nvl(get_assoc_task_context_prof_sp(i_prev_row), '-') !=
                   nvl(get_assoc_task_context_prof_sp(i_curr_row), '-')
                THEN
                    l_right_labels.extend();
                    l_right_labels(l_right_labels.count) := pk_utils.to_bold(i_text => pk_message.get_message(i_lang      => i_lang,
                                                                                                              i_code_mess => g_msg_task_spec_phys));
                    l_right_values.extend();
                    IF is_column_visible(i_lang              => i_lang,
                                         i_prof              => i_prof,
                                         i_ec_clin_serv_dest => i_curr_row.id_clin_serv_dest,
                                         i_ec_prof_clin_serv => l_rec_ecp_create.id_prof_clin_serv,
                                         i_column_name       => 'DESC_ASSOC_TASK',
                                         i_is_request        => l_is_request) = pk_alert_constant.g_yes
                    THEN
                        l_right_values(l_right_values.count) := get_assoc_task_context_prof_sp(i_curr_row,
                                                                                               pk_alert_constant.g_no);
                    ELSE
                        l_right_values(l_right_values.count) := g_encrypted_text;
                    END IF;
                END IF;
            END IF;
        
            g_error := 'Clinical service';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            IF (i_prev_row.flg_status_comp IS NOT NULL AND
               nvl(i_prev_row.desc_prof_clin_serv, '-') != nvl(i_curr_row.desc_prof_clin_serv, '-'))
               OR (i_prev_row.flg_status_comp IS NULL AND i_prev_row.flg_status_req = g_req_flg_status_a AND
               nvl(i_prev_row.desc_clin_serv_dest, '-') != nvl(i_curr_row.desc_prof_clin_serv, '-'))
            THEN
                l_right_labels.extend();
                l_right_labels(l_right_labels.count) := pk_utils.to_bold(i_text => pk_message.get_message(i_lang      => i_lang,
                                                                                                          i_code_mess => g_msg_clinical_service));
                l_right_values.extend();
                IF is_column_visible(i_lang              => i_lang,
                                     i_prof              => i_prof,
                                     i_ec_clin_serv_dest => i_curr_row.id_clin_serv_dest,
                                     i_ec_prof_clin_serv => l_rec_ecp_create.id_prof_clin_serv,
                                     i_column_name       => 'CLINICAL_SERVICE',
                                     i_is_request        => l_is_request) = pk_alert_constant.g_yes
                THEN
                    l_right_values(l_right_values.count) := i_curr_row.desc_prof_clin_serv;
                ELSE
                    l_right_values(l_right_values.count) := g_encrypted_text;
                END IF;
            END IF;
        
            g_error := 'Professionals';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            IF nvl(get_professionals(i_prev_row), '-') != nvl(get_professionals(i_curr_row), '-')
            THEN
                l_right_labels.extend();
                l_right_labels(l_right_labels.count) := pk_utils.to_bold(i_text => pk_message.get_message(i_lang      => i_lang,
                                                                                                          i_code_mess => g_msg_professionals));
                l_right_values.extend();
                IF is_column_visible(i_lang              => i_lang,
                                     i_prof              => i_prof,
                                     i_ec_clin_serv_dest => i_curr_row.id_clin_serv_dest,
                                     i_ec_prof_clin_serv => l_rec_ecp_create.id_prof_clin_serv,
                                     i_column_name       => 'CLINICAL_SERVICE', --Clinical service professional list
                                     i_is_request        => l_is_request) = pk_alert_constant.g_yes
                THEN
                    l_right_values(l_right_values.count) := get_professionals(i_curr_row, pk_alert_constant.g_no);
                ELSE
                    l_right_values(l_right_values.count) := g_encrypted_text;
                END IF;
            END IF;
        
            g_error := 'Diagnosis';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            l_curr_str := get_diagnosis(i_curr_row);
            IF nvl(get_diagnosis(i_prev_row), '-') != nvl(l_curr_str, '-')
            THEN
                l_right_labels.extend();
                l_right_labels(l_right_labels.count) := pk_utils.to_bold(i_text => pk_message.get_message(i_lang      => i_lang,
                                                                                                          i_code_mess => g_msg_diagnosis));
                l_right_values.extend();
                IF is_column_visible(i_lang              => i_lang,
                                     i_prof              => i_prof,
                                     i_ec_clin_serv_dest => i_curr_row.id_clin_serv_dest,
                                     i_ec_prof_clin_serv => l_rec_ecp_create.id_prof_clin_serv,
                                     i_column_name       => 'DIAGNOSE',
                                     i_is_request        => l_is_request) = pk_alert_constant.g_yes
                THEN
                    l_right_values(l_right_values.count) := l_curr_str;
                ELSE
                    l_right_values(l_right_values.count) := g_encrypted_text;
                END IF;
            END IF;
        
            g_error := 'Effect';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            IF nvl(get_comp_axe(i_prev_row, get_axe_typ_eff(i_lang, i_prof)), '-') !=
               nvl(get_comp_axe(i_curr_row, get_axe_typ_eff(i_lang, i_prof)), '-')
            THEN
                l_right_labels.extend();
                l_right_labels(l_right_labels.count) := pk_utils.to_bold(i_text => pk_message.get_message(i_lang      => i_lang,
                                                                                                          i_code_mess => g_msg_effect));
                l_right_values.extend();
                IF is_column_visible(i_lang              => i_lang,
                                     i_prof              => i_prof,
                                     i_ec_clin_serv_dest => i_curr_row.id_clin_serv_dest,
                                     i_ec_prof_clin_serv => l_rec_ecp_create.id_prof_clin_serv,
                                     i_column_name       => 'EFFECT',
                                     i_is_request        => l_is_request) = pk_alert_constant.g_yes
                THEN
                    l_right_values(l_right_values.count) := get_comp_axe(i_curr_row,
                                                                         get_axe_typ_eff(i_lang, i_prof),
                                                                         pk_alert_constant.g_no);
                ELSE
                    l_right_values(l_right_values.count) := g_encrypted_text;
                END IF;
            END IF;
        
            g_error := 'Treatment performed';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            IF nvl(get_treat_performed(i_prev_row), '-') != nvl(get_treat_performed(i_curr_row), '-')
            THEN
                l_right_labels.extend();
                l_right_labels(l_right_labels.count) := pk_utils.to_bold(i_text => pk_message.get_message(i_lang      => i_lang,
                                                                                                          i_code_mess => g_msg_treatment_performed));
                l_right_values.extend();
                IF is_column_visible(i_lang              => i_lang,
                                     i_prof              => i_prof,
                                     i_ec_clin_serv_dest => i_curr_row.id_clin_serv_dest,
                                     i_ec_prof_clin_serv => l_rec_ecp_create.id_prof_clin_serv,
                                     i_column_name       => 'TREATMENT_PERFORMED',
                                     i_is_request        => l_is_request) = pk_alert_constant.g_yes
                THEN
                    l_right_values(l_right_values.count) := get_treat_performed(i_curr_row, pk_alert_constant.g_no);
                ELSE
                    l_right_values(l_right_values.count) := g_encrypted_text;
                END IF;
            END IF;
        
            g_error := 'Notes';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            IF nvl(i_prev_row.notes_comp, '-') != nvl(i_curr_row.notes_comp, '-')
            THEN
                l_right_labels.extend();
                l_right_labels(l_right_labels.count) := pk_utils.to_bold(i_text => pk_message.get_message(i_lang      => i_lang,
                                                                                                          i_code_mess => g_msg_notes));
                l_right_values.extend();
                IF is_column_visible(i_lang              => i_lang,
                                     i_prof              => i_prof,
                                     i_ec_clin_serv_dest => i_curr_row.id_clin_serv_dest,
                                     i_ec_prof_clin_serv => l_rec_ecp_create.id_prof_clin_serv,
                                     i_column_name       => 'NOTES_COMP',
                                     i_is_request        => l_is_request) = pk_alert_constant.g_yes
                THEN
                    l_right_values(l_right_values.count) := i_curr_row.notes_comp;
                ELSE
                    l_right_values(l_right_values.count) := g_encrypted_text;
                END IF;
            END IF;
        ELSE
            g_error := 'Description';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            IF nvl(i_prev_row.description, '-') != i_curr_row.description
            THEN
                l_right_labels.extend();
                l_right_labels(l_right_labels.count) := pk_utils.to_bold(i_text => pk_message.get_message(i_lang      => i_lang,
                                                                                                          i_code_mess => g_msg_description));
                l_right_values.extend();
                IF is_column_visible(i_lang              => i_lang,
                                     i_prof              => i_prof,
                                     i_ec_clin_serv_dest => i_curr_row.id_clin_serv_dest,
                                     i_ec_prof_clin_serv => l_rec_ecp_create.id_prof_clin_serv,
                                     i_column_name       => 'DESCRIPTION',
                                     i_is_request        => l_is_request) = pk_alert_constant.g_yes
                THEN
                    l_right_values(l_right_values.count) := i_curr_row.description;
                ELSE
                    l_right_values(l_right_values.count) := g_encrypted_text;
                END IF;
            END IF;
        
            g_error := 'Verification date';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            IF nvl(i_prev_row.dt_verif_req_desc, '-') != nvl(i_curr_row.dt_verif_req_desc, '-')
            THEN
                l_right_labels.extend();
                l_right_labels(l_right_labels.count) := pk_utils.to_bold(i_text => pk_message.get_message(i_lang      => i_lang,
                                                                                                          i_code_mess => g_msg_verification_date));
                l_right_values.extend();
                IF is_column_visible(i_lang              => i_lang,
                                     i_prof              => i_prof,
                                     i_ec_clin_serv_dest => i_curr_row.id_clin_serv_dest,
                                     i_ec_prof_clin_serv => l_rec_ecp_create.id_prof_clin_serv,
                                     i_column_name       => 'DT_VERIF_REQ',
                                     i_is_request        => l_is_request) = pk_alert_constant.g_yes
                THEN
                    l_right_values(l_right_values.count) := i_curr_row.dt_verif_req_desc;
                ELSE
                    l_right_values(l_right_values.count) := g_encrypted_text;
                END IF;
            END IF;
        
            g_error := 'Associated episode';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            IF nvl(i_prev_row.desc_episode_origin, '-') != nvl(i_curr_row.desc_episode_origin, '-')
            THEN
                l_right_labels.extend();
                l_right_labels(l_right_labels.count) := pk_utils.to_bold(i_text => pk_message.get_message(i_lang      => i_lang,
                                                                                                          i_code_mess => g_msg_associated_episode));
                l_right_values.extend();
                IF is_column_visible(i_lang              => i_lang,
                                     i_prof              => i_prof,
                                     i_ec_clin_serv_dest => i_curr_row.id_clin_serv_dest,
                                     i_ec_prof_clin_serv => l_rec_ecp_create.id_prof_clin_serv,
                                     i_column_name       => 'REQ_ASSOC_EPI',
                                     i_is_request        => l_is_request) = pk_alert_constant.g_yes
                THEN
                    l_right_values(l_right_values.count) := i_curr_row.desc_episode_origin;
                ELSE
                    l_right_values(l_right_values.count) := g_encrypted_text;
                END IF;
            END IF;
        
            g_error := 'Associated task';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            IF nvl(get_assoc_task(i_prev_row), '-') != nvl(get_assoc_task(i_curr_row), '-')
            THEN
                l_right_labels.extend();
                l_right_labels(l_right_labels.count) := pk_utils.to_bold(i_text => pk_message.get_message(i_lang      => i_lang,
                                                                                                          i_code_mess => g_msg_associated_task));
                l_right_values.extend();
                IF is_column_visible(i_lang              => i_lang,
                                     i_prof              => i_prof,
                                     i_ec_clin_serv_dest => i_curr_row.id_clin_serv_dest,
                                     i_ec_prof_clin_serv => l_rec_ecp_create.id_prof_clin_serv,
                                     i_column_name       => 'REQ_ASSOC_TASK',
                                     i_is_request        => l_is_request) = pk_alert_constant.g_yes
                THEN
                    l_right_values(l_right_values.count) := get_assoc_task(i_curr_row, pk_alert_constant.g_no);
                ELSE
                    l_right_values(l_right_values.count) := g_encrypted_text;
                END IF;
            
                g_error := 'Task date';
                alertlog.pk_alertlog.log_info(text            => g_error,
                                              object_name     => g_package,
                                              sub_object_name => l_func_name);
                IF nvl(get_assoc_task_dt(i_prev_row), '-') != nvl(get_assoc_task_dt(i_curr_row), '-')
                THEN
                    l_right_labels.extend();
                    l_right_labels(l_right_labels.count) := pk_utils.to_bold(i_text => pk_message.get_message(i_lang      => i_lang,
                                                                                                              i_code_mess => g_msg_task_date));
                    l_right_values.extend();
                    IF is_column_visible(i_lang              => i_lang,
                                         i_prof              => i_prof,
                                         i_ec_clin_serv_dest => i_curr_row.id_clin_serv_dest,
                                         i_ec_prof_clin_serv => l_rec_ecp_create.id_prof_clin_serv,
                                         i_column_name       => 'REQ_ASSOC_TASK_DT',
                                         i_is_request        => l_is_request) = pk_alert_constant.g_yes
                    THEN
                        l_right_values(l_right_values.count) := get_assoc_task_dt(i_curr_row, pk_alert_constant.g_no);
                    ELSE
                        l_right_values(l_right_values.count) := g_encrypted_text;
                    END IF;
                END IF;
            END IF;
        
            g_error := 'Clinical service';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            IF nvl(i_prev_row.desc_clin_serv_dest, '-') != i_curr_row.desc_clin_serv_dest
            THEN
                l_right_labels.extend();
                l_right_labels(l_right_labels.count) := pk_utils.to_bold(i_text => pk_message.get_message(i_lang      => i_lang,
                                                                                                          i_code_mess => g_msg_clinical_service));
                l_right_values.extend();
                IF is_column_visible(i_lang              => i_lang,
                                     i_prof              => i_prof,
                                     i_ec_clin_serv_dest => i_curr_row.id_clin_serv_dest,
                                     i_ec_prof_clin_serv => l_rec_ecp_create.id_prof_clin_serv,
                                     i_column_name       => 'REQ_DESC_CLIN_SERV_DEST',
                                     i_is_request        => l_is_request) = pk_alert_constant.g_yes
                THEN
                    l_right_values(l_right_values.count) := i_curr_row.desc_clin_serv_dest;
                ELSE
                    l_right_values(l_right_values.count) := g_encrypted_text;
                END IF;
            END IF;
        
            g_error := 'Professionals';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            IF nvl(get_professionals(i_prev_row), '-') != nvl(get_professionals(i_curr_row), '-')
            THEN
                l_right_labels.extend();
                l_right_labels(l_right_labels.count) := pk_utils.to_bold(i_text => pk_message.get_message(i_lang      => i_lang,
                                                                                                          i_code_mess => g_msg_professionals));
                l_right_values.extend();
                IF is_column_visible(i_lang              => i_lang,
                                     i_prof              => i_prof,
                                     i_ec_clin_serv_dest => i_curr_row.id_clin_serv_dest,
                                     i_ec_prof_clin_serv => l_rec_ecp_create.id_prof_clin_serv,
                                     i_column_name       => 'REQ_PROFESSIONAL',
                                     i_is_request        => l_is_request) = pk_alert_constant.g_yes
                THEN
                    l_right_values(l_right_values.count) := get_professionals(i_curr_row, pk_alert_constant.g_no);
                ELSE
                    l_right_values(l_right_values.count) := g_encrypted_text;
                END IF;
            END IF;
        
            g_error := 'Notes';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            IF nvl(i_prev_row.notes_req, '-') != nvl(i_curr_row.notes_req, '-')
            THEN
                l_right_labels.extend();
                l_right_labels(l_right_labels.count) := pk_utils.to_bold(i_text => pk_message.get_message(i_lang      => i_lang,
                                                                                                          i_code_mess => g_msg_notes));
                l_right_values.extend();
                IF is_column_visible(i_lang              => i_lang,
                                     i_prof              => i_prof,
                                     i_ec_clin_serv_dest => i_curr_row.id_clin_serv_dest,
                                     i_ec_prof_clin_serv => l_rec_ecp_create.id_prof_clin_serv,
                                     i_column_name       => 'NOTES_REQ',
                                     i_is_request        => l_is_request) = pk_alert_constant.g_yes
                THEN
                    l_right_values(l_right_values.count) := i_curr_row.notes_req;
                ELSE
                    l_right_values(l_right_values.count) := g_encrypted_text;
                END IF;
            END IF;
        END IF;
    
        g_error := 'Cancel notes';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF i_curr_row.id_cancel_reason IS NOT NULL
        THEN
            l_right_labels.extend();
            l_right_labels(l_right_labels.count) := pk_utils.to_bold(i_text => pk_message.get_message(i_lang      => i_lang,
                                                                                                      i_code_mess => g_msg_cancel_reason));
            l_right_values.extend();
            IF is_column_visible(i_lang              => i_lang,
                                 i_prof              => i_prof,
                                 i_ec_clin_serv_dest => i_curr_row.id_clin_serv_dest,
                                 i_ec_prof_clin_serv => l_rec_ecp_create.id_prof_clin_serv,
                                 i_column_name       => CASE l_is_request
                                                            WHEN pk_alert_constant.g_yes THEN
                                                             'REQ_NOTES_CANCEL'
                                                            ELSE
                                                             'NOTES_CANCEL'
                                                        END,
                                 i_is_request        => l_is_request) = pk_alert_constant.g_yes
            THEN
                l_right_values(l_right_values.count) := i_curr_row.desc_cancel_reason;
            ELSE
                l_right_values(l_right_values.count) := g_encrypted_text;
            END IF;
        
            l_right_labels.extend();
            l_right_labels(l_right_labels.count) := pk_utils.to_bold(i_text => pk_message.get_message(i_lang      => i_lang,
                                                                                                      i_code_mess => g_msg_cancel_notes));
            l_right_values.extend();
            IF is_column_visible(i_lang              => i_lang,
                                 i_prof              => i_prof,
                                 i_ec_clin_serv_dest => i_curr_row.id_clin_serv_dest,
                                 i_ec_prof_clin_serv => l_rec_ecp_create.id_prof_clin_serv,
                                 i_column_name       => CASE l_is_request
                                                            WHEN pk_alert_constant.g_yes THEN
                                                             'REQ_NOTES_CANCEL'
                                                            ELSE
                                                             'NOTES_CANCEL'
                                                        END,
                                 i_is_request        => l_is_request) = pk_alert_constant.g_yes
            THEN
                l_right_values(l_right_values.count) := i_curr_row.notes_cancel;
            ELSE
                l_right_values(l_right_values.count) := g_encrypted_text;
            END IF;
        END IF;
    
        g_error := 'Reject notes';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF i_curr_row.id_reject_reason IS NOT NULL
        THEN
            l_right_labels.extend();
            l_right_labels(l_right_labels.count) := pk_utils.to_bold(i_text => pk_message.get_message(i_lang      => i_lang,
                                                                                                      i_code_mess => g_msg_reject_reason));
            l_right_values.extend();
            IF is_column_visible(i_lang              => i_lang,
                                 i_prof              => i_prof,
                                 i_ec_clin_serv_dest => i_curr_row.id_clin_serv_dest,
                                 i_ec_prof_clin_serv => l_rec_ecp_create.id_prof_clin_serv,
                                 i_column_name       => 'REQ_NOTES_REJECT', --It's only possible to reject a request
                                 i_is_request        => l_is_request) = pk_alert_constant.g_yes
            THEN
                l_right_values(l_right_values.count) := i_curr_row.desc_reject_reason;
            ELSE
                l_right_values(l_right_values.count) := g_encrypted_text;
            END IF;
        
            l_right_labels.extend();
            l_right_labels(l_right_labels.count) := pk_utils.to_bold(i_text => pk_message.get_message(i_lang      => i_lang,
                                                                                                      i_code_mess => g_msg_reject_notes));
            l_right_values.extend();
            IF is_column_visible(i_lang              => i_lang,
                                 i_prof              => i_prof,
                                 i_ec_clin_serv_dest => i_curr_row.id_clin_serv_dest,
                                 i_ec_prof_clin_serv => l_rec_ecp_create.id_prof_clin_serv,
                                 i_column_name       => 'REQ_NOTES_REJECT', --It's only possible to reject a request
                                 i_is_request        => l_is_request) = pk_alert_constant.g_yes
            THEN
                l_right_values(l_right_values.count) := i_curr_row.notes_rejected;
            ELSE
                l_right_values(l_right_values.count) := g_encrypted_text;
            END IF;
        END IF;
    
        o_left_columns := l_left_columns;
        o_left_values  := l_left_values;
        o_right_labels := l_right_labels;
        o_right_values := l_right_values;
        o_info_labels  := l_info_labels;
        o_info_values  := l_info_values;
    
        RETURN TRUE;
        /*EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => l_error);
            RETURN FALSE;*/
    END compare_epis_comp_rec;

    /**
    * Gets complication detail data
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_complication         Episode complication id
    * @param   o_complication              All complication data
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   04-01-2010
    */
    FUNCTION get_complication_detail
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_complication IN epis_complication.id_epis_complication%TYPE,
        o_complication      OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_COMPLICATION_DETAIL';
        --
        l_epis_comp_prev_row pk_complication_core.epis_comp_rec;
        l_epis_comp_curr_row pk_complication_core.epis_comp_rec;
        l_left_columns       table_varchar;
        l_left_values        table_varchar;
        l_right_labels       table_varchar;
        l_right_values       table_varchar;
        l_info_labels        table_varchar;
        l_info_values        table_varchar;
        l_table              t_table_comp_col_diff := t_table_comp_col_diff();
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'GET ALL COMPLICATION HISTORY';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        --This loop runs throughout the history of the given complication
        FOR l_epis_comp IN (SELECT aux.prev_epis_comp_hist, aux.curr_epis_comp_hist
                              FROM (SELECT lag(id_epis_comp_hist) over(ORDER BY dt_epis_complication, decode(id_epis_comp_hist, -1, 1, 0), id_epis_comp_hist) prev_epis_comp_hist,
                                           id_epis_comp_hist curr_epis_comp_hist
                                      FROM (SELECT g_epis_comp_curr_row id_epis_comp_hist, ec.dt_epis_complication
                                              FROM epis_complication ec
                                             WHERE ec.id_epis_complication = i_epis_complication
                                            UNION ALL
                                            SELECT ech.id_epis_comp_hist, ech.dt_epis_complication
                                              FROM epis_comp_hist ech
                                             WHERE ech.id_epis_complication = i_epis_complication)) aux)
        LOOP
            l_epis_comp_prev_row := get_epis_comp_rec(i_lang              => i_lang,
                                                      i_prof              => i_prof,
                                                      i_epis_complication => i_epis_complication,
                                                      i_epis_comp_hist    => l_epis_comp.prev_epis_comp_hist);
        
            l_epis_comp_curr_row := get_epis_comp_rec(i_lang              => i_lang,
                                                      i_prof              => i_prof,
                                                      i_epis_complication => i_epis_complication,
                                                      i_epis_comp_hist    => l_epis_comp.curr_epis_comp_hist);
        
            IF compare_epis_comp_rec(i_lang         => i_lang,
                                     i_prof         => i_prof,
                                     i_prev_row     => l_epis_comp_prev_row,
                                     i_curr_row     => l_epis_comp_curr_row,
                                     o_left_columns => l_left_columns,
                                     o_left_values  => l_left_values,
                                     o_right_labels => l_right_labels,
                                     o_right_values => l_right_values,
                                     o_info_labels  => l_info_labels,
                                     o_info_values  => l_info_values)
            THEN
                l_table.extend();
                l_table(l_table.count) := t_rec_comp_col_diff(id_epis_comp_hist => l_epis_comp_curr_row.id_epis_comp_hist,
                                                              tbl_left_columns  => l_left_columns,
                                                              tbl_left_values   => l_left_values,
                                                              tbl_right_labels  => l_right_labels,
                                                              tbl_right_values  => l_right_values,
                                                              tbl_info_labels   => l_info_labels,
                                                              tbl_info_values   => l_info_values);
            END IF;
        END LOOP;
    
        g_error := 'OPEN O_COMPLICATION CURSOR';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        OPEN o_complication FOR
            SELECT t.id_epis_comp_hist,
                   t.tbl_left_columns  left_columns,
                   t.tbl_left_values   left_values,
                   t.tbl_right_labels  right_labels,
                   t.tbl_right_values  right_values,
                   t.tbl_info_labels   info_labels,
                   t.tbl_info_values   info_values
              FROM TABLE(l_table) t;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_complication_detail;

    /**
    * Gets request data
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_complication         Episode complication id
    * @param   o_request                   All request data
    * @param   o_request_detail            All request detail data
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   04-01-2010
    */
    FUNCTION get_request
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_complication IN epis_complication.id_epis_complication%TYPE,
        o_request           OUT pk_types.cursor_type,
        o_request_detail    OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_REQUEST';
        --
        l_msg_with_notes sys_message.desc_message%TYPE;
        l_dt_request     epis_complication.dt_epis_complication%TYPE;
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'GET MSG WITH NOTES';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_msg_with_notes := pk_message.get_message(i_lang, g_msg_with_notes);
    
        g_error := 'GET REQ LAST REGISTRY DT';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_dt_request := pk_complication_core.get_req_registry_dt(i_epis_complication);
    
        g_error := 'GET REQUEST DATA';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        OPEN o_request FOR
            SELECT t.description,
                   t.dt_verif_req_chr,
                   t.dt_verif_req,
                   t.registry_date_chr,
                   t.registry_date,
                   t.id_episode_origin,
                   t.desc_episode_origin,
                   t.id_clin_serv_dest,
                   t.desc_clin_serv_dest,
                   t.notes_req,
                   t.flg_status,
                   t.desc_status,
                   t.id_prof_create,
                   t.prof_create_name,
                   t.desc_status || ': ' || t.registry_date_chr || '; ' || t.prof_create_name registry_info
              FROM (SELECT ec.description,
                           pk_date_utils.date_char_tsz(i_lang, ec.dt_verif_req, i_prof.institution, i_prof.institution) dt_verif_req_chr,
                           pk_date_utils.date_send_tsz(i_lang, ec.dt_verif_req, i_prof) dt_verif_req,
                           pk_date_utils.date_char_tsz(i_lang, l_dt_request, i_prof.institution, i_prof.institution) registry_date_chr,
                           pk_date_utils.date_send_tsz(i_lang, l_dt_request, i_prof) registry_date,
                           ec.id_episode_origin,
                           pk_complication_core.get_episode_description(i_lang, i_prof, ec.id_episode_origin) desc_episode_origin,
                           ec.id_clin_serv_dest,
                           pk_translation.get_translation(i_lang, cs.code_clinical_service) desc_clin_serv_dest,
                           ec.notes_req,
                           ec.flg_status_req flg_status,
                           pk_sysdomain.get_domain(g_req_flg_status_domain, ec.flg_status_req, i_lang) ||
                           decode(ec.notes_cancel, NULL, NULL, g_delim_1 || l_msg_with_notes) desc_status,
                           ec.id_prof_create,
                           pk_complication_core.get_prof_name(i_lang, i_prof, ec.id_prof_create) prof_create_name
                      FROM epis_complication ec
                      JOIN clinical_service cs
                        ON cs.id_clinical_service = ec.id_clin_serv_dest
                     WHERE ec.id_epis_complication = i_epis_complication
                       AND ec.description IS NOT NULL) t;
    
        g_error := 'GET REQUEST DETAIL DATA';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        OPEN o_request_detail FOR
        --Current Associated tasks
            SELECT ecd.id_comp_axe id_comp_axe,
                   pk_translation.get_translation(i_lang, ca.code_comp_axe) ||
                   decode(pk_complication_core.is_to_show_code(i_lang, i_prof),
                          pk_alert_constant.g_yes,
                          decode(ca.code, NULL, NULL, ' (' || ca.code || ')'),
                          NULL) desc_comp_axe,
                   ecd.id_context_new id_context,
                   pk_translation.get_translation(i_lang, ca.code_comp_axe) ||
                   decode(pk_complication_core.is_to_show_code(i_lang, i_prof),
                          pk_alert_constant.g_yes,
                          decode(ca.code, NULL, NULL, ' (' || ca.code || ')'),
                          NULL) || ': ' ||
                   pk_api_complications.get_task_det(i_lang,
                                                     i_prof,
                                                     ecd.id_context_new,
                                                     ecd.id_sys_list,
                                                     g_flg_task_det_n,
                                                     g_flg_cfg_typ_assoc_task) desc_context,
                   ecd.id_sys_list,
                   pk_date_utils.date_char_tsz(i_lang, ecd.dt_context, i_prof.institution, i_prof.institution) dt_context_chr,
                   pk_date_utils.date_send_tsz(i_lang, ecd.dt_context, i_prof.institution, i_prof.institution) dt_context,
                   ecd.id_context_prof id_prof_req,
                   pk_complication_core.get_prof_name(i_lang, i_prof, ecd.id_context_prof) prof_req_name,
                   ecd.id_context_prof_spec id_prof_task,
                   pk_complication_core.get_prof_name(i_lang, i_prof, ecd.id_context_prof_spec) prof_task_name,
                   NULL id_professional,
                   NULL prof_name,
                   pk_complication_core.g_flg_cfg_typ_assoc_task typ
              FROM epis_complication ec
              JOIN epis_comp_detail ecd
                ON ecd.id_epis_complication = ec.id_epis_complication
               AND ecd.dt_context IS NOT NULL
              JOIN TABLE(pk_sys_list.tf_sys_list_values(i_lang, i_prof, g_lst_grp_ecd_at_types)) lst
                ON lst.id_sys_list = ecd.id_sys_list
              JOIN comp_axe ca
                ON ca.id_comp_axe = ecd.id_comp_axe
             WHERE ec.id_epis_complication = i_epis_complication
               AND ec.description IS NOT NULL
               AND ec.flg_status_req != g_req_flg_status_a --Means Requested, Rejected or Cancelled requests
               AND ecd.id_epis_comp_hist IS NULL
            --Last Associated tasks
            UNION ALL
            SELECT ecd.id_comp_axe id_comp_axe,
                   pk_translation.get_translation(i_lang, ca.code_comp_axe) ||
                   decode(pk_complication_core.is_to_show_code(i_lang, i_prof),
                          pk_alert_constant.g_yes,
                          decode(ca.code, NULL, NULL, ' (' || ca.code || ')'),
                          NULL) desc_comp_axe,
                   ecd.id_context_new id_context,
                   pk_translation.get_translation(i_lang, ca.code_comp_axe) ||
                   decode(pk_complication_core.is_to_show_code(i_lang, i_prof),
                          pk_alert_constant.g_yes,
                          decode(ca.code, NULL, NULL, ' (' || ca.code || ')'),
                          NULL) || ': ' ||
                   pk_api_complications.get_task_det(i_lang,
                                                     i_prof,
                                                     ecd.id_context_new,
                                                     ecd.id_sys_list,
                                                     g_flg_task_det_n,
                                                     g_flg_cfg_typ_assoc_task) desc_context,
                   ecd.id_sys_list,
                   pk_date_utils.date_char_tsz(i_lang, ecd.dt_context, i_prof.institution, i_prof.institution) dt_context_chr,
                   pk_date_utils.date_send_tsz(i_lang, ecd.dt_context, i_prof.institution, i_prof.institution) dt_context,
                   ecd.id_context_prof id_prof_req,
                   pk_complication_core.get_prof_name(i_lang, i_prof, ecd.id_context_prof) prof_req_name,
                   ecd.id_context_prof_spec id_prof_task,
                   pk_complication_core.get_prof_name(i_lang, i_prof, ecd.id_context_prof_spec) prof_task_name,
                   NULL id_professional,
                   NULL prof_name,
                   pk_complication_core.g_flg_cfg_typ_assoc_task typ
              FROM epis_complication ec
              JOIN epis_comp_detail ecd
                ON ecd.id_epis_complication = ec.id_epis_complication
               AND ecd.dt_context IS NOT NULL
              JOIN TABLE(pk_sys_list.tf_sys_list_values(i_lang, i_prof, g_lst_grp_ecd_at_types)) lst
                ON lst.id_sys_list = ecd.id_sys_list
              JOIN comp_axe ca
                ON ca.id_comp_axe = ecd.id_comp_axe
              JOIN epis_comp_hist ech
                ON ech.id_epis_comp_hist = ecd.id_epis_comp_hist
             WHERE ec.id_epis_complication = i_epis_complication
               AND ech.flg_status_req = g_req_flg_status_a
            --Current Req Professionals
            UNION ALL
            SELECT NULL id_comp_axe,
                   NULL desc_comp_axe,
                   NULL id_context,
                   NULL desc_context,
                   NULL flg_context,
                   NULL dt_context_chr,
                   NULL dt_context,
                   NULL id_prof_req,
                   NULL id_prof_task,
                   NULL id_context_prof_spec,
                   NULL prof_task_name,
                   ecp.id_professional id_professional,
                   pk_complication_core.get_prof_name(i_lang, i_prof, ecp.id_professional) prof_name,
                   g_complication_prof typ
              FROM epis_complication ec
              JOIN epis_comp_prof ecp
                ON ecp.id_epis_complication = ec.id_epis_complication
             WHERE ec.id_epis_complication = i_epis_complication
               AND ec.description IS NOT NULL
               AND ec.flg_status_req != g_req_flg_status_a --Means Requested, Rejected or Cancelled requests
               AND ecp.id_epis_comp_hist IS NULL
            --Last Req Professionals
            UNION ALL
            SELECT NULL id_comp_axe,
                   NULL desc_comp_axe,
                   NULL id_context,
                   NULL desc_context,
                   NULL flg_context,
                   NULL dt_context_chr,
                   NULL dt_context,
                   NULL id_prof_req,
                   NULL id_prof_task,
                   NULL id_context_prof_spec,
                   NULL prof_task_name,
                   ecp.id_professional id_professional,
                   pk_complication_core.get_prof_name(i_lang, i_prof, ecp.id_professional) prof_name,
                   g_complication_prof typ
              FROM epis_complication ec
              JOIN epis_comp_prof ecp
                ON ecp.id_epis_complication = ec.id_epis_complication
              JOIN epis_comp_hist ech
                ON ech.id_epis_comp_hist = ecp.id_epis_comp_hist
             WHERE ec.id_epis_complication = i_epis_complication
               AND ech.flg_status_req = g_req_flg_status_a;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_request;

    /**
    * Returns the epis_comp_detail id's that must go to history
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_complication         Epis_comp_detail ID
    * @param   i_comp_axe                  Comp_axe ID
    * @param   o_epis_comp_detail          Id's that must go to hist
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   26-02-2010
    */
    FUNCTION get_epis_comp_detail_to_hist
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_complication IN epis_comp_detail.id_epis_complication%TYPE,
        i_comp_axe          IN epis_comp_detail.id_comp_axe%TYPE,
        i_type              IN sys_list.id_sys_list%TYPE,
        o_epis_comp_detail  OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_EPIS_COMP_DETAIL_TO_HIST';
        --
        l_ica_context sys_list_group_rel.flg_context%TYPE;
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        IF i_comp_axe IS NOT NULL
        THEN
            g_error := 'GET I_COMP_AXE TYPE';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            SELECT tbl.flg_context
              INTO l_ica_context
              FROM (SELECT t.flg_context, pk_complication_core.get_cfg_typ_axe(i_lang, i_prof) flg_type
                      FROM comp_axe ca
                      JOIN TABLE(pk_sys_list.tf_sys_list_values(i_lang, i_prof, pk_complication_core.g_lst_grp_axe_types)) t
                        ON t.id_sys_list = ca.id_sys_list
                     WHERE ca.id_comp_axe = i_comp_axe
                    UNION ALL
                    SELECT t.flg_context, pk_complication_core.get_cfg_typ_assoc_task(i_lang, i_prof) flg_type
                      FROM comp_axe ca
                      JOIN TABLE(pk_sys_list.tf_sys_list_values(i_lang, i_prof, pk_complication_core.g_lst_grp_axe_at_types)) t
                        ON t.id_sys_list = ca.id_sys_list
                     WHERE ca.id_comp_axe = i_comp_axe
                    UNION ALL
                    SELECT t.flg_context, pk_complication_core.get_cfg_typ_treat_perf(i_lang, i_prof) flg_type
                      FROM comp_axe ca
                      JOIN TABLE(pk_sys_list.tf_sys_list_values(i_lang, i_prof, pk_complication_core.g_lst_grp_axe_tp_types)) t
                        ON t.id_sys_list = ca.id_sys_list
                     WHERE ca.id_comp_axe = i_comp_axe) tbl
             WHERE tbl.flg_type = i_type;
        
            g_error := 'GET NUMBER OF ROWS IN I_EPIS_COMPLICATION THAT HAVE THE SAME I_COMP_AXE TYPE';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            IF i_type = pk_complication_core.get_cfg_typ_axe(i_lang, i_prof)
            THEN
                SELECT ecd.id_epis_comp_detail
                  BULK COLLECT
                  INTO o_epis_comp_detail
                  FROM epis_comp_detail ecd
                  JOIN comp_axe ca
                    ON ca.id_comp_axe = ecd.id_comp_axe
                  JOIN TABLE(pk_sys_list.tf_sys_list_values(i_lang, i_prof, pk_complication_core.g_lst_grp_axe_types)) t
                    ON t.id_sys_list = ca.id_sys_list
                   AND t.flg_context = l_ica_context
                 WHERE ecd.id_epis_complication = i_epis_complication
                   AND ecd.dt_epis_comp_detail != g_sysdate_tstz
                   AND ecd.id_epis_comp_hist IS NULL
                   AND ecd.id_epis_comp_detail NOT IN
                       (SELECT column_value id_epis_comp_detail
                          FROM TABLE(g_proc_epis_comp_detail));
            ELSIF i_type = pk_complication_core.get_cfg_typ_assoc_task(i_lang, i_prof)
            THEN
                SELECT ecd.id_epis_comp_detail
                  BULK COLLECT
                  INTO o_epis_comp_detail
                  FROM epis_comp_detail ecd
                  JOIN comp_axe ca
                    ON ca.id_comp_axe = ecd.id_comp_axe
                  JOIN TABLE(pk_sys_list.tf_sys_list_values(i_lang, i_prof, pk_complication_core.g_lst_grp_axe_at_types)) t
                    ON t.id_sys_list = ca.id_sys_list
                 WHERE ecd.id_epis_complication = i_epis_complication
                   AND ecd.dt_context IS NOT NULL
                   AND ecd.dt_epis_comp_detail != g_sysdate_tstz
                   AND ecd.id_epis_comp_hist IS NULL
                   AND ecd.id_epis_comp_detail NOT IN
                       (SELECT column_value id_epis_comp_detail
                          FROM TABLE(g_proc_epis_comp_detail));
            ELSIF i_type = pk_complication_core.get_cfg_typ_treat_perf(i_lang, i_prof)
            THEN
                SELECT ecd.id_epis_comp_detail
                  BULK COLLECT
                  INTO o_epis_comp_detail
                  FROM epis_comp_detail ecd
                  JOIN comp_axe ca
                    ON ca.id_comp_axe = ecd.id_comp_axe
                  JOIN TABLE(pk_sys_list.tf_sys_list_values(i_lang, i_prof, pk_complication_core.g_lst_grp_axe_tp_types)) t
                    ON t.id_sys_list = ca.id_sys_list
                 WHERE ecd.id_epis_complication = i_epis_complication
                   AND ecd.dt_context IS NULL
                   AND ecd.dt_epis_comp_detail != g_sysdate_tstz
                   AND ecd.id_epis_comp_hist IS NULL
                   AND ecd.id_epis_comp_detail NOT IN
                       (SELECT column_value id_epis_comp_detail
                          FROM TABLE(g_proc_epis_comp_detail));
            ELSE
                o_epis_comp_detail := table_number();
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_epis_comp_detail_to_hist;

    /**********************************************************************************************
    * Saves complication history
    *
    * @param i_lang                   the id language
    * @param i_epis_complication      epis_complication id
    * @param o_epis_comp_hist         id_epis_comp_hist of the new record
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   21-12-2009
    **********************************************************************************************/
    FUNCTION set_epis_complication_hist
    (
        i_lang              IN language.id_language%TYPE,
        i_epis_complication IN epis_complication.id_epis_complication%TYPE,
        o_epis_comp_hist    OUT epis_comp_hist.id_epis_comp_hist%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'SET_EPIS_COMPLICATION_HIST';
        --
        l_rows           table_varchar;
        l_epis_comp_hist ts_epis_comp_hist.epis_comp_hist_tc;
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'GET ANN_ARRIV';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        SELECT ts_epis_comp_hist.next_key,
               ec.id_epis_complication,
               ec.id_episode,
               ec.id_episode_origin,
               ec.id_complication,
               ec.description,
               ec.dt_verif_comp,
               ec.dt_verif_req,
               ec.id_clin_serv_dest,
               ec.flg_status_comp,
               ec.flg_status_req,
               ec.notes_comp,
               ec.notes_req,
               ec.dt_epis_complication,
               ec.id_prof_create,
               ec.id_prof_clin_serv
          INTO l_epis_comp_hist(1).id_epis_comp_hist,
               l_epis_comp_hist(1).id_epis_complication,
               l_epis_comp_hist(1).id_episode,
               l_epis_comp_hist(1).id_episode_origin,
               l_epis_comp_hist(1).id_complication,
               l_epis_comp_hist(1).description,
               l_epis_comp_hist(1).dt_verif_comp,
               l_epis_comp_hist(1).dt_verif_req,
               l_epis_comp_hist(1).id_clin_serv_dest,
               l_epis_comp_hist(1).flg_status_comp,
               l_epis_comp_hist(1).flg_status_req,
               l_epis_comp_hist(1).notes_comp,
               l_epis_comp_hist(1).notes_req,
               l_epis_comp_hist(1).dt_epis_complication,
               l_epis_comp_hist(1).id_prof_create,
               l_epis_comp_hist(1).id_prof_clin_serv
          FROM epis_complication ec
         WHERE ec.id_epis_complication = i_epis_complication;
    
        g_error := 'SET ANN_ARRIV_HIST';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        ts_epis_comp_hist.ins(rows_in => l_epis_comp_hist, rows_out => l_rows);
    
        g_error := 'VALIDATE INS ROW';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF (l_rows.count != 1)
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_general_error;
        ELSE
            SELECT ech.id_epis_comp_hist
              INTO o_epis_comp_hist
              FROM epis_comp_hist ech
             WHERE ROWID = l_rows(1);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_epis_complication_hist;

    /**********************************************************************************************
    * Saves complication detail history
    *
    * @param i_lang                   the id language
    * @param i_epis_comp_detail       epis_comp_detail id's
    * @param i_epis_comp_hist         id_epis_comp_hist id
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   21-12-2009
    **********************************************************************************************/
    FUNCTION set_epis_comp_detail_hist
    (
        i_lang             IN language.id_language%TYPE,
        i_epis_comp_detail IN table_number,
        i_epis_comp_hist   IN epis_comp_hist.id_epis_comp_hist%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'SET_EPIS_COMP_DETAIL_HIST';
        --
        l_rows table_varchar;
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'SET COMP DETAIL HIST';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        FOR l_epis_comp_detail IN (SELECT column_value id_epis_comp_detail
                                     FROM TABLE(i_epis_comp_detail))
        LOOP
            ts_epis_comp_detail.upd(id_epis_comp_detail_in => l_epis_comp_detail.id_epis_comp_detail,
                                    id_epis_comp_hist_in   => i_epis_comp_hist,
                                    id_epis_comp_hist_nin  => FALSE,
                                    rows_out               => l_rows);
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
        
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_epis_comp_detail_hist;

    /**********************************************************************************************
    * Saves complication professionals history
    *
    * @param i_lang                   the id language
    * @param i_epis_complication      epis_complication id
    * @param i_epis_comp_hist         id_epis_comp_hist id
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   21-12-2009
    **********************************************************************************************/
    FUNCTION set_epis_comp_prof_hist
    (
        i_lang           IN language.id_language%TYPE,
        i_epis_comp_prof IN epis_comp_prof.id_epis_comp_prof%TYPE,
        i_epis_comp_hist IN epis_comp_hist.id_epis_comp_hist%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'SET_EPIS_COMP_PROF_HIST';
        --
        l_rows table_varchar;
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'SET COMP DETAIL HIST';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        ts_epis_comp_prof.upd(id_epis_comp_prof_in  => i_epis_comp_prof,
                              id_epis_comp_hist_in  => i_epis_comp_hist,
                              id_epis_comp_hist_nin => FALSE,
                              rows_out              => l_rows);
    
        g_error := 'VALIDATE UPD ROW';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF (l_rows.count != 1)
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_general_error;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
        
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_epis_comp_prof_hist;

    FUNCTION set_epis_complication
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_complication IN epis_complication.id_epis_complication%TYPE DEFAULT NULL, --if is null then create new complication
        i_episode           IN epis_complication.id_episode%TYPE,
        i_episode_origin    IN epis_complication.id_episode_origin%TYPE,
        i_complication      IN epis_complication.id_complication%TYPE,
        i_dt_verif          IN epis_complication.dt_verif_comp%TYPE,
        i_flg_status        IN epis_complication.flg_status_comp%TYPE,
        i_notes             IN epis_complication.notes_comp%TYPE,
        i_prof_clin_serv    IN epis_complication.id_prof_clin_serv%TYPE,
        o_epis_complication OUT epis_complication.id_epis_complication%TYPE,
        o_epis_comp_hist    OUT epis_comp_hist.id_epis_comp_hist%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'SET_EPIS_COMPLICATION';
        --
        l_rows_comp  table_varchar;
        l_rows_other table_varchar;
        l_aux_num    NUMBER;
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'VERIFY IF IS A UPDT OR INSERT';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF (i_epis_complication IS NULL)
        THEN
            g_error := 'INSERT NEW EPIS COMPLICATION';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            ts_epis_complication.ins(id_episode_in           => i_episode,
                                     id_episode_origin_in    => i_episode_origin,
                                     id_complication_in      => i_complication,
                                     dt_verif_comp_in        => i_dt_verif,
                                     flg_status_comp_in      => i_flg_status,
                                     notes_comp_in           => i_notes,
                                     dt_epis_complication_in => g_sysdate_tstz,
                                     id_prof_create_in       => i_prof.id,
                                     id_prof_clin_serv_in    => i_prof_clin_serv,
                                     rows_out                => l_rows_comp);
        ELSE
            g_error := 'UPD COMPLICATION HISTORY';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            IF NOT set_epis_complication_hist(i_lang              => i_lang,
                                              i_epis_complication => i_epis_complication,
                                              o_epis_comp_hist    => o_epis_comp_hist,
                                              o_error             => o_error)
            THEN
                pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
                RAISE e_general_error;
            END IF;
        
            g_error := 'VERIFY IF THIS IS A NEW COMPLICATION - ACCEPTED REQUEST';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            SELECT COUNT(*)
              INTO l_aux_num
              FROM epis_complication ec
             WHERE ec.id_epis_complication = i_epis_complication
               AND ec.flg_status_req = g_req_flg_status_a
               AND ec.id_complication IS NULL;
        
            --IF IT'S A NEW COMPLICATION WITH ORIGIN ON A ACCEPTED REQUEST THEN PUT ALL DETAIL AND PROF DATA IN HISTORY
            IF l_aux_num = 1
            THEN
                g_error := 'SET COMP_DETAIL HIST';
                alertlog.pk_alertlog.log_info(text            => g_error,
                                              object_name     => g_package,
                                              sub_object_name => l_func_name);
                l_rows_other := table_varchar();
                ts_epis_comp_detail.upd(id_epis_comp_hist_in  => o_epis_comp_hist,
                                        id_epis_comp_hist_nin => FALSE,
                                        where_in              => 'id_epis_complication = ' || i_epis_complication ||
                                                                 ' AND id_epis_comp_hist IS NULL',
                                        rows_out              => l_rows_other);
            
                g_error := 'SET COMP_PROF HIST';
                alertlog.pk_alertlog.log_info(text            => g_error,
                                              object_name     => g_package,
                                              sub_object_name => l_func_name);
                l_rows_other := table_varchar();
                ts_epis_comp_prof.upd(id_epis_comp_hist_in  => o_epis_comp_hist,
                                      id_epis_comp_hist_nin => FALSE,
                                      where_in              => 'id_epis_complication = ' || i_epis_complication ||
                                                               ' AND id_epis_comp_hist IS NULL',
                                      rows_out              => l_rows_other);
            END IF;
        
            g_error := 'UPDATE EPIS COMPLICATION';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            --i_episode is not updated because always stays associated with the id_episode where it was created
            ts_epis_complication.upd(id_epis_complication_in  => i_epis_complication,
                                     id_episode_origin_in     => i_episode_origin,
                                     id_episode_origin_nin    => FALSE,
                                     id_complication_in       => i_complication,
                                     id_complication_nin      => FALSE,
                                     dt_verif_comp_in         => i_dt_verif,
                                     dt_verif_comp_nin        => FALSE,
                                     flg_status_comp_in       => i_flg_status,
                                     flg_status_comp_nin      => FALSE,
                                     notes_comp_in            => i_notes,
                                     notes_comp_nin           => FALSE,
                                     dt_epis_complication_in  => g_sysdate_tstz,
                                     dt_epis_complication_nin => FALSE,
                                     id_prof_create_in        => i_prof.id,
                                     id_prof_create_nin       => FALSE,
                                     id_prof_clin_serv_in     => i_prof_clin_serv,
                                     id_prof_clin_serv_nin    => FALSE,
                                     rows_out                 => l_rows_comp);
        END IF;
    
        g_error := 'VALIDATE INS/UPD ROW';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF (l_rows_comp.count != 1)
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_general_error;
        ELSE
            SELECT ec.id_epis_complication
              INTO o_epis_complication
              FROM epis_complication ec
             WHERE ROWID = l_rows_comp(1);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_epis_complication;

    FUNCTION set_epis_comp_request
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_complication IN epis_complication.id_epis_complication%TYPE DEFAULT NULL, --if is null then create new complication request
        i_episode           IN epis_complication.id_episode%TYPE,
        i_episode_origin    IN epis_complication.id_episode_origin%TYPE,
        i_description       IN epis_complication.description%TYPE,
        i_dt_verif          IN epis_complication.dt_verif_req%TYPE,
        i_flg_status        IN epis_complication.flg_status_req%TYPE,
        i_notes             IN epis_complication.notes_req%TYPE,
        i_clin_serv_dest    IN epis_complication.id_clin_serv_dest%TYPE,
        o_epis_complication OUT epis_complication.id_epis_complication%TYPE,
        o_epis_comp_hist    OUT epis_comp_hist.id_epis_comp_hist%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'SET_EPIS_COMP_REQUEST';
        --
        l_rows           table_varchar;
        l_prof_clin_serv clinical_service.id_clinical_service%TYPE;
    
        l_clin_serv_error EXCEPTION;
    
        l_err_msg     sys_message.desc_message%TYPE;
        l_error_title sys_message.desc_message%TYPE;
    
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'GET CURR PROF CLIN_SERV';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_prof_clin_serv := pk_prof_utils.get_prof_clin_serv_id(i_lang => i_lang, i_prof => i_prof);
    
        IF l_prof_clin_serv IS NULL
        THEN
            l_err_msg     := pk_message.get_message(i_lang, 'COMPLICATION_MSG080');
            l_error_title := pk_message.get_message(i_lang, 'COMMON_T013');
            RAISE l_clin_serv_error;
        END IF;
    
        g_error := 'VERIFY IF IS A UPDT OR INSERT';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF (i_epis_complication IS NULL)
        THEN
            g_error := 'INSERT NEW EPIS COMPLICATION';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            ts_epis_complication.ins(id_episode_in           => i_episode,
                                     id_episode_origin_in    => i_episode_origin,
                                     description_in          => i_description,
                                     dt_verif_req_in         => i_dt_verif,
                                     flg_status_req_in       => i_flg_status,
                                     notes_req_in            => i_notes,
                                     id_clin_serv_dest_in    => i_clin_serv_dest,
                                     dt_epis_complication_in => g_sysdate_tstz,
                                     id_prof_create_in       => i_prof.id,
                                     id_prof_clin_serv_in    => l_prof_clin_serv,
                                     rows_out                => l_rows);
        ELSE
            g_error := 'UPD COMPLICATION HISTORY';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            IF NOT set_epis_complication_hist(i_lang              => i_lang,
                                              i_epis_complication => i_epis_complication,
                                              o_epis_comp_hist    => o_epis_comp_hist,
                                              o_error             => o_error)
            THEN
                pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
                RAISE e_general_error;
            END IF;
        
            g_error := 'UPDATE EPIS COMPLICATION';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            --i_episode is not updated because always stays associated with the id_episode where it was created
            ts_epis_complication.upd(id_epis_complication_in  => i_epis_complication,
                                     id_episode_origin_in     => i_episode_origin,
                                     id_episode_origin_nin    => FALSE,
                                     description_in           => i_description,
                                     description_nin          => FALSE,
                                     dt_verif_req_in          => i_dt_verif,
                                     dt_verif_req_nin         => FALSE,
                                     flg_status_req_in        => i_flg_status,
                                     flg_status_req_nin       => FALSE,
                                     notes_req_in             => i_notes,
                                     notes_req_nin            => FALSE,
                                     id_clin_serv_dest_in     => i_clin_serv_dest,
                                     id_clin_serv_dest_nin    => FALSE,
                                     dt_epis_complication_in  => g_sysdate_tstz,
                                     dt_epis_complication_nin => FALSE,
                                     id_prof_create_in        => i_prof.id,
                                     id_prof_create_nin       => FALSE,
                                     id_prof_clin_serv_in     => l_prof_clin_serv,
                                     id_prof_clin_serv_nin    => FALSE,
                                     rows_out                 => l_rows);
        END IF;
    
        g_error := 'VALIDATE INS/UPD ROW';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF (l_rows.count != 1)
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_general_error;
        ELSE
            SELECT ec.id_epis_complication
              INTO o_epis_complication
              FROM epis_complication ec
             WHERE ROWID = l_rows(1);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_clin_serv_error THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang,
                                   'COMPLICATION_MSG080',
                                   l_err_msg,
                                   g_error,
                                   g_owner,
                                   g_package,
                                   l_func_name,
                                   NULL,
                                   'U',
                                   l_error_title);
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_utils.undo_changes;
                RETURN FALSE;
            END;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_epis_comp_request;

    FUNCTION set_epis_comp_detail
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_complication IN epis_comp_detail.id_epis_complication%TYPE,
        i_comp_axe          IN epis_comp_detail.id_comp_axe%TYPE,
        i_child_axe         IN epis_comp_detail_axe.id_comp_axe%TYPE,
        i_context           IN epis_comp_detail.id_context_new%TYPE,
        i_flg_context       IN epis_comp_detail.id_sys_list%TYPE,
        i_dt_context        IN epis_comp_detail.dt_context%TYPE,
        i_context_prof      IN epis_comp_detail.id_context_prof%TYPE,
        i_context_prof_spec IN epis_comp_detail.id_context_prof_spec%TYPE,
        i_epis_comp_hist    IN epis_comp_detail.id_epis_comp_hist%TYPE,
        i_type              IN sys_list.id_sys_list%TYPE,
        o_epis_comp_detail  OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'SET_EPIS_COMP_DETAIL';
        --
        l_rows             table_varchar;
        l_epis_comp_detail table_number;
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'VERIFY IF DATA CHANGED';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        BEGIN
            --When this query returns a value means that the data hasn't changed so there is nothing to do.
            SELECT ecd.id_epis_comp_detail
              BULK COLLECT
              INTO l_epis_comp_detail
              FROM epis_comp_detail ecd
              LEFT JOIN epis_comp_detail_axe ecda
                ON ecda.id_epis_comp_detail = ecd.id_epis_comp_detail
               AND ecda.id_parent_comp_axe = ecd.id_comp_axe
             WHERE ecd.id_epis_complication = i_epis_complication
               AND nvl(ecd.id_comp_axe, -99) = nvl(i_comp_axe, -99)
               AND nvl(ecd.id_context_new, -99) = nvl(i_context, -99)
               AND nvl(ecd.id_sys_list, -99) = nvl(i_flg_context, -99)
               AND nvl(ecda.id_comp_axe, -99) = nvl(i_child_axe, -99)
               AND ecd.id_epis_comp_hist IS NULL;
        
            --Add epis_comp_detail to processed table
            FOR l_aux IN (SELECT column_value id_epis_comp_detail
                            FROM TABLE(l_epis_comp_detail))
            LOOP
                g_proc_epis_comp_detail.extend();
                g_proc_epis_comp_detail(g_proc_epis_comp_detail.count) := l_aux.id_epis_comp_detail;
            END LOOP;
        EXCEPTION
            WHEN no_data_found THEN
                l_epis_comp_detail := table_number();
        END;
    
        IF l_epis_comp_detail.count = 0
        THEN
            g_error := 'VERIFY IF EPIS_COMP_DETAIL DATA TYPE EXISTS';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            --The next code verifies if the type of data being inserted already exists, if so means that must be updated
            --For instance verifies if the input value i_comp_axe is of type pathology and if we already have a pathology
            --on current i_epis_complication
            IF NOT get_epis_comp_detail_to_hist(i_lang              => i_lang,
                                                i_prof              => i_prof,
                                                i_epis_complication => i_epis_complication,
                                                i_comp_axe          => i_comp_axe,
                                                i_type              => i_type,
                                                o_epis_comp_detail  => l_epis_comp_detail,
                                                o_error             => o_error)
            THEN
                pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
                RAISE e_general_error;
            END IF;
        
            --If data exists means that has changed, so it must be moved to history and then added the new data
            --If data doesn't exists it must be added
            IF l_epis_comp_detail.count != 0
            THEN
                g_error := 'UPD COMP DETAIL HIST';
                alertlog.pk_alertlog.log_info(text            => g_error,
                                              object_name     => g_package,
                                              sub_object_name => l_func_name);
                IF NOT set_epis_comp_detail_hist(i_lang             => i_lang,
                                                 i_epis_comp_detail => l_epis_comp_detail,
                                                 i_epis_comp_hist   => i_epis_comp_hist,
                                                 o_error            => o_error)
                THEN
                    pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
                    RAISE e_general_error;
                END IF;
            END IF;
        
            g_error            := 'VERIFY IF I_COMP_AXE WAS ALREADY INSERTED';
            l_epis_comp_detail := table_number();
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            SELECT ecd.id_epis_comp_detail
              BULK COLLECT
              INTO l_epis_comp_detail
              FROM epis_comp_detail ecd
             WHERE ecd.id_comp_axe = i_comp_axe
               AND ecd.dt_epis_comp_detail = g_sysdate_tstz
               AND ecd.id_epis_comp_hist IS NULL;
        
            IF l_epis_comp_detail.count = 0
            THEN
                g_error := 'INSERT EPIS COMP DETAIL';
                alertlog.pk_alertlog.log_info(text            => g_error,
                                              object_name     => g_package,
                                              sub_object_name => l_func_name);
                l_rows := table_varchar();
                ts_epis_comp_detail.ins(id_epis_complication_in => i_epis_complication,
                                        id_comp_axe_in          => i_comp_axe,
                                        id_context_new_in       => i_context,
                                        id_sys_list_in          => i_flg_context,
                                        dt_context_in           => i_dt_context,
                                        id_context_prof_in      => i_context_prof,
                                        id_context_prof_spec_in => i_context_prof_spec,
                                        dt_epis_comp_detail_in  => g_sysdate_tstz,
                                        rows_out                => l_rows);
            
                g_error := 'VALIDATE INS ROW';
                alertlog.pk_alertlog.log_info(text            => g_error,
                                              object_name     => g_package,
                                              sub_object_name => l_func_name);
                IF (l_rows.count != 1)
                THEN
                    pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
                    RAISE e_general_error;
                ELSE
                    SELECT ecd.id_epis_comp_detail
                      BULK COLLECT
                      INTO o_epis_comp_detail
                      FROM epis_comp_detail ecd
                     WHERE ROWID = l_rows(1);
                END IF;
            ELSE
                o_epis_comp_detail := l_epis_comp_detail;
            END IF;
        
            --Add epis_comp_detail to processed table
            FOR l_aux IN (SELECT column_value id_epis_comp_detail
                            FROM TABLE(o_epis_comp_detail))
            LOOP
                g_proc_epis_comp_detail.extend();
                g_proc_epis_comp_detail(g_proc_epis_comp_detail.count) := l_aux.id_epis_comp_detail;
            
                g_error := 'INSERT EPIS COMP DETAIL AXE';
                alertlog.pk_alertlog.log_info(text            => g_error,
                                              object_name     => g_package,
                                              sub_object_name => l_func_name);
                IF nvl(i_child_axe, -1) != -1
                THEN
                    l_rows := table_varchar();
                    ts_epis_comp_detail_axe.ins(id_epis_comp_detail_in => l_aux.id_epis_comp_detail,
                                                id_parent_comp_axe_in  => i_comp_axe,
                                                id_comp_axe_in         => i_child_axe,
                                                rows_out               => l_rows);
                
                    IF (l_rows.count != 1)
                    THEN
                        pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
                        RAISE e_general_error;
                    END IF;
                END IF;
            END LOOP;
        ELSE
            o_epis_comp_detail := l_epis_comp_detail;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_epis_comp_detail;

    FUNCTION set_epis_comp_prof
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_complication IN epis_comp_prof.id_epis_complication%TYPE,
        i_professional      IN table_number,
        i_epis_comp_hist    IN epis_comp_prof.id_epis_comp_hist%TYPE,
        o_epis_comp_prof    OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'SET_EPIS_COMP_PROF';
        --
        l_rows            table_varchar;
        l_unchanged_profs table_number;
        l_new_profs       table_number;
        l_old_profs       table_number;
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'INIT OUT VAR';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        o_epis_comp_prof := table_number();
    
        g_error := 'GET OLD PROFESSIONALS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        --These professionals must go to history
        SELECT ecp.id_epis_comp_prof
          BULK COLLECT
          INTO l_old_profs
          FROM epis_comp_prof ecp
         WHERE ecp.id_epis_complication = i_epis_complication
           AND ecp.id_professional NOT IN (SELECT column_value
                                             FROM TABLE(i_professional))
           AND ecp.id_epis_comp_hist IS NULL;
    
        g_error := 'GET UNCHANGED PROFESSIONALS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        --Doesn't do anything with these ones, just add them to the o_epis_comp_prof
        SELECT ecp.id_professional
          BULK COLLECT
          INTO l_unchanged_profs
          FROM epis_comp_prof ecp
         WHERE ecp.id_epis_complication = i_epis_complication
           AND ecp.id_professional IN (SELECT column_value
                                         FROM TABLE(i_professional))
           AND ecp.id_epis_comp_hist IS NULL;
    
        g_error := 'GET NEW PROFESSIONALS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        --Insert new profs
        SELECT id_professional
          BULK COLLECT
          INTO l_new_profs
          FROM (SELECT column_value id_professional
                  FROM TABLE(i_professional)
                MINUS
                SELECT column_value id_professional
                  FROM TABLE(l_unchanged_profs));
    
        g_error := 'SEND OLD PROFS TO HIST';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_rows := table_varchar();
        FOR curr_prof IN (SELECT column_value id_epis_comp_prof
                            FROM TABLE(l_old_profs))
        LOOP
            IF NOT set_epis_comp_prof_hist(i_lang           => i_lang,
                                           i_epis_comp_prof => curr_prof.id_epis_comp_prof,
                                           i_epis_comp_hist => i_epis_comp_hist,
                                           o_error          => o_error)
            THEN
                pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
                RAISE e_general_error;
            END IF;
        END LOOP;
    
        g_error := 'INSERT NEW PROFS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_rows := table_varchar();
        FOR curr_prof IN (SELECT column_value id_professional
                            FROM TABLE(l_new_profs))
        LOOP
            ts_epis_comp_prof.ins(id_epis_complication_in => i_epis_complication,
                                  id_professional_in      => curr_prof.id_professional,
                                  dt_epis_comp_prof_in    => g_sysdate_tstz,
                                  rows_out                => l_rows);
        END LOOP;
    
        g_error := 'ADD IDs TO OUT VAR - NEW PROFS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        SELECT ecp.id_epis_comp_prof
          BULK COLLECT
          INTO o_epis_comp_prof
          FROM epis_comp_prof ecp
         WHERE ROWID IN (SELECT column_value
                           FROM TABLE(l_rows));
    
        g_error := 'ADD IDs TO OUT VAR - UNCHANGED PROFS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        FOR curr_prof IN (SELECT column_value id_professional
                            FROM TABLE(l_unchanged_profs))
        LOOP
            o_epis_comp_prof.extend();
            o_epis_comp_prof(o_epis_comp_prof.count) := curr_prof.id_professional;
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_epis_comp_prof;

    FUNCTION validate_params
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_cols       IN table_varchar,
        i_vals       IN table_varchar,
        i_valid_cols IN t_table_comp_col_info,
        o_error      OUT NOCOPY t_error_out
    ) RETURN BOOLEAN IS
        l_proc_name VARCHAR2(30) := 'VALIDATE_PARAMS';
        --
        l_col_exist BOOLEAN;
        l_tab_aux1  table_varchar;
        l_tab_aux2  table_varchar;
        --
        l_action_message sys_message.desc_message%TYPE;
        l_error_code     sys_message.code_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
    
        g_error := 'VERIFY IF ARRAYS SIZE MATCH';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        IF (i_cols.count != i_vals.count)
        THEN
            g_error := l_proc_name || ' - ' || g_error || '; icols: ' || to_char(i_cols.count) || '; i_vals: ' ||
                       to_char(i_vals.count);
            pk_alertlog.log_debug(g_error);
            RAISE e_arrays_size_dont_match;
        END IF;
    
        g_error := 'VALIDATE REQUIRED VALUES';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        FOR l_col_info IN (SELECT valid_cols.col_name, valid_cols.col_type, valid_cols.col_size, valid_cols.col_nullable
                             FROM TABLE(i_valid_cols) valid_cols)
        LOOP
            l_col_exist := FALSE;
            FOR i IN 1 .. i_cols.count
            LOOP
                IF l_col_info.col_name = i_cols(i)
                THEN
                    l_col_exist := TRUE;
                
                    IF l_col_info.col_nullable = pk_alert_constant.g_no
                       AND i_vals(i) IS NULL
                    THEN
                        g_error := l_proc_name || ' - ' || g_error || '; "' || l_col_info.col_name ||
                                   '" is a required field.';
                        pk_alertlog.log_debug(g_error);
                        RAISE e_required_field;
                    END IF;
                END IF;
            END LOOP;
        
            IF l_col_info.col_nullable = pk_alert_constant.g_no
               AND l_col_exist = FALSE
            THEN
                g_error := l_proc_name || ' - ' || g_error || '; "' || l_col_info.col_name || '" is a required field.';
                pk_alertlog.log_debug(g_error);
                RAISE e_required_field;
            END IF;
        END LOOP;
    
        g_error := 'VERIFY IF COL VALUE IS VALID';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        FOR i IN 1 .. i_cols.count
        LOOP
            l_col_exist := FALSE;
            FOR l_col_info IN (SELECT valid_cols.col_name, valid_cols.col_type, valid_cols.col_size
                                 FROM TABLE(i_valid_cols) valid_cols
                                WHERE valid_cols.col_name = i_cols(i))
            LOOP
                l_col_exist := TRUE;
            
                CASE l_col_info.col_type
                    WHEN g_col_info_typ_num THEN
                        IF NOT is_valid_number(i_vals(i))
                        THEN
                            g_error := l_proc_name || ' - Column "' || l_col_info.col_name || '". Type "' ||
                                       l_col_info.col_type || '" Value "' || i_vals(i) || '" isn''t a valid number.';
                            pk_alertlog.log_debug(g_error);
                            RAISE e_not_a_number;
                        END IF;
                    WHEN g_col_info_typ_date THEN
                        IF NOT is_valid_date(i_lang, i_prof, i_vals(i))
                        THEN
                            g_error := l_proc_name || ' -  Column "' || l_col_info.col_name || '". Type "' ||
                                       l_col_info.col_type || '" Value "' || i_vals(i) || '" isn''t a valid date.';
                            pk_alertlog.log_debug(g_error);
                            RAISE e_not_a_date;
                        END IF;
                    WHEN g_col_info_typ_flg THEN
                        IF NOT is_valid_flag(i_vals(i), l_col_info.col_size)
                        THEN
                            g_error := l_proc_name || ' -  Column "' || l_col_info.col_name || '". Type "' ||
                                       l_col_info.col_type || '" Value "' || i_vals(i) || '" with size "' ||
                                       to_char(l_col_info.col_size) || '" isn''t a valid flag.';
                            pk_alertlog.log_debug(g_error);
                            RAISE e_not_a_flag;
                        END IF;
                    WHEN g_col_info_typ_str THEN
                        NULL; --There is nothing to validate
                    WHEN g_col_info_typ_tbl_num THEN
                        l_tab_aux1 := pk_utils.str_split_l(i_vals(i), g_delim_1);
                    
                        FOR j IN 1 .. l_tab_aux1.count
                        LOOP
                            IF nvl(l_col_info.col_size, 1) = 1
                               AND NOT is_valid_number(l_tab_aux1(j))
                            THEN
                                g_error := l_proc_name || ' -  Column "' || l_col_info.col_name || '". Type "' ||
                                           l_col_info.col_type || '" Value "' || l_tab_aux1(j) ||
                                           '" isn''t a valid number.';
                                pk_alertlog.log_debug(g_error);
                                RAISE e_not_a_number;
                            ELSIF l_col_info.col_size = 2
                            THEN
                                --Size = 2 means that can have 1 or 2 values
                                --This is used by axes lists that may have additional data
                                --example: certain external factors may have a associated medication or tool
                                --In case we have 2 values they mean parent_axe;child_axe
                                l_tab_aux2 := pk_utils.str_split_l(l_tab_aux1(j), g_delim_2);
                            
                                IF NOT (l_tab_aux2.count BETWEEN 1 AND l_col_info.col_size)
                                THEN
                                    g_error := l_proc_name || ' -  Column "' || l_col_info.col_name || '". Type "' ||
                                               l_col_info.col_type || '" Value "' || l_tab_aux1(j) ||
                                               '" hasn''t the right number of values.';
                                    pk_alertlog.log_debug(g_error);
                                    RAISE e_array_size_dont_match;
                                END IF;
                            
                                FOR p IN 1 .. l_tab_aux2.count
                                LOOP
                                    IF NOT is_valid_number(l_tab_aux2(p))
                                    THEN
                                        g_error := l_proc_name || ' -  Column "' || l_col_info.col_name || '". Type "' ||
                                                   l_col_info.col_type || '" Value "' || l_tab_aux2(p) ||
                                                   '" isn''t a valid number.';
                                        pk_alertlog.log_debug(g_error);
                                        RAISE e_not_a_number;
                                    END IF;
                                END LOOP;
                            ELSIF l_col_info.col_size >= 3
                            THEN
                                g_error := l_proc_name || ' -  Column "' || l_col_info.col_name || '". Type "' ||
                                           l_col_info.col_type || '" Value "' || l_tab_aux1(j) ||
                                           '" hasn''t the right number of values.';
                                pk_alertlog.log_debug(g_error);
                                RAISE e_array_size_dont_match;
                            END IF;
                        END LOOP;
                    WHEN g_col_info_typ_tbl_str THEN
                        IF l_col_info.col_size = 1
                        THEN
                            NULL; --There is nothing to validate
                        ELSE
                            l_tab_aux1 := pk_utils.str_split_l(i_vals(i), g_delim_1);
                        
                            FOR j IN 1 .. l_tab_aux1.count
                            LOOP
                                l_tab_aux2 := pk_utils.str_split_l(l_tab_aux1(j), g_delim_2);
                            
                                --used only by associated_tasks (6 values: id_comp_axe;id_context;flg_context;dt_context;requested_by;ordered_by)
                                --and treatments_performed (3 values: id_comp_axe;id_context;flg_context)
                                IF l_col_info.col_size IS NOT NULL
                                   AND l_col_info.col_size != l_tab_aux2.count
                                THEN
                                    g_error := l_proc_name || ' -  Column "' || l_col_info.col_name || '". Type "' ||
                                               l_col_info.col_type || '" Value "' || l_tab_aux1(j) ||
                                               '" hasn''t the right number of values.';
                                    pk_alertlog.log_debug(g_error);
                                    RAISE e_array_size_dont_match;
                                END IF;
                            
                                IF l_col_info.col_name IN (g_col_name_associated_tasks, g_col_name_treats_performed)
                                THEN
                                    IF NOT is_valid_number(l_tab_aux2(1))
                                    THEN
                                        g_error := l_proc_name || ' -  Column "' || l_col_info.col_name || '". Type "' ||
                                                   l_col_info.col_type || '" Value "' || l_tab_aux1(j) ||
                                                   '" specific value: "' || l_tab_aux2(1) || '" isn''t a valid number.';
                                        pk_alertlog.log_debug(g_error);
                                        RAISE e_not_a_number;
                                    END IF;
                                
                                    --l_tab_aux2(2): ID_CONTEXT is a VARCHAR2 so it's not necessary to validate index 2 of l_tab_aux2 array
                                
                                    IF NOT is_valid_number(l_tab_aux2(3))
                                    THEN
                                        g_error := l_proc_name || ' -  Column "' || l_col_info.col_name || '". Type "' ||
                                                   l_col_info.col_type || '" Value "' || l_tab_aux1(j) ||
                                                   '" specific value: "' || l_tab_aux2(3) || '" isn''t a valid number.';
                                        pk_alertlog.log_debug(g_error);
                                        RAISE e_not_a_number;
                                    END IF;
                                END IF;
                            
                                IF l_col_info.col_name = g_col_name_associated_tasks
                                THEN
                                    IF l_tab_aux2.count = 6
                                    THEN
                                        IF NOT is_valid_date(i_lang, i_prof, l_tab_aux2(4))
                                        THEN
                                            g_error := l_proc_name || ' -  Column "' || l_col_info.col_name ||
                                                       '". Type "' || l_col_info.col_type || '" Value "' ||
                                                       l_tab_aux1(j) || '" specific value: "' || l_tab_aux2(4) ||
                                                       '" isn''t a valid date.';
                                            pk_alertlog.log_debug(g_error);
                                            RAISE e_not_a_number;
                                        END IF;
                                    
                                        IF NOT is_valid_number(l_tab_aux2(5))
                                        THEN
                                            g_error := l_proc_name || ' -  Column "' || l_col_info.col_name ||
                                                       '". Type "' || l_col_info.col_type || '" Value "' ||
                                                       l_tab_aux1(j) || '" specific value: "' || l_tab_aux2(5) ||
                                                       '" isn''t a valid number.';
                                            pk_alertlog.log_debug(g_error);
                                            RAISE e_not_a_number;
                                        END IF;
                                    
                                        IF NOT is_valid_number(l_tab_aux2(6))
                                        THEN
                                            g_error := l_proc_name || ' -  Column "' || l_col_info.col_name ||
                                                       '". Type "' || l_col_info.col_type || '" Value "' ||
                                                       l_tab_aux1(j) || '" specific value: "' || l_tab_aux2(6) ||
                                                       '" isn''t a valid number.';
                                            pk_alertlog.log_debug(g_error);
                                            RAISE e_not_a_number;
                                        END IF;
                                    END IF;
                                END IF;
                            END LOOP;
                        END IF;
                END CASE; --
            END LOOP;
        
            g_error := 'VERIFY IF COL EXIST';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
            IF (NOT l_col_exist)
            THEN
                g_error := l_proc_name || ' -  Column "' || i_cols(i) || '" doesn''t exist.';
                pk_alertlog.log_debug(g_error);
                RAISE e_wrong_column_name;
            END IF;
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        WHEN e_arrays_size_dont_match THEN
            l_action_message := pk_message.get_message(i_lang => i_lang, i_code_mess => 'COMPLICATION_ERR006');
            l_error_code     := 'COMPLICATION_ERR005';
            l_error_message  := pk_message.get_message(i_lang => i_lang, i_code_mess => l_error_code);
        
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => l_error_code,
                                              i_sqlerrm     => l_error_message,
                                              i_message     => g_error,
                                              i_owner       => g_owner,
                                              i_package     => g_package,
                                              i_function    => l_proc_name,
                                              i_action_type => 'U',
                                              i_action_msg  => l_action_message,
                                              o_error       => o_error);
            pk_utils.undo_changes;
            RAISE;
        WHEN e_not_a_number THEN
            l_action_message := pk_message.get_message(i_lang => i_lang, i_code_mess => 'COMPLICATION_ERR008');
            l_error_code     := 'COMPLICATION_ERR005';
            l_error_message  := pk_message.get_message(i_lang => i_lang, i_code_mess => l_error_code);
        
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => l_error_code,
                                              i_sqlerrm     => l_error_message,
                                              i_message     => g_error,
                                              i_owner       => g_owner,
                                              i_package     => g_package,
                                              i_function    => l_proc_name,
                                              i_action_type => 'U',
                                              i_action_msg  => l_action_message,
                                              o_error       => o_error);
            pk_utils.undo_changes;
            RAISE;
        WHEN e_not_a_flag THEN
            l_action_message := pk_message.get_message(i_lang => i_lang, i_code_mess => 'COMPLICATION_ERR009');
            l_error_code     := 'COMPLICATION_ERR005';
            l_error_message  := pk_message.get_message(i_lang => i_lang, i_code_mess => l_error_code);
        
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => l_error_code,
                                              i_sqlerrm     => l_error_message,
                                              i_message     => g_error,
                                              i_owner       => g_owner,
                                              i_package     => g_package,
                                              i_function    => l_proc_name,
                                              i_action_type => 'U',
                                              i_action_msg  => l_action_message,
                                              o_error       => o_error);
            pk_utils.undo_changes;
            RAISE;
        WHEN e_not_a_date THEN
            l_action_message := pk_message.get_message(i_lang => i_lang, i_code_mess => 'COMPLICATION_ERR010');
            l_error_code     := 'COMPLICATION_ERR005';
            l_error_message  := pk_message.get_message(i_lang => i_lang, i_code_mess => l_error_code);
        
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => l_error_code,
                                              i_sqlerrm     => l_error_message,
                                              i_message     => g_error,
                                              i_owner       => g_owner,
                                              i_package     => g_package,
                                              i_function    => l_proc_name,
                                              i_action_type => 'U',
                                              i_action_msg  => l_action_message,
                                              o_error       => o_error);
            pk_utils.undo_changes;
            RAISE;
        WHEN e_wrong_column_name THEN
            l_action_message := pk_message.get_message(i_lang => i_lang, i_code_mess => 'COMPLICATION_ERR011');
            l_error_code     := 'COMPLICATION_ERR005';
            l_error_message  := pk_message.get_message(i_lang => i_lang, i_code_mess => l_error_code);
        
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => l_error_code,
                                              i_sqlerrm     => l_error_message,
                                              i_message     => g_error,
                                              i_owner       => g_owner,
                                              i_package     => g_package,
                                              i_function    => l_proc_name,
                                              i_action_type => 'U',
                                              i_action_msg  => l_action_message,
                                              o_error       => o_error);
            pk_utils.undo_changes;
            RAISE;
        WHEN e_required_field THEN
            l_action_message := pk_message.get_message(i_lang => i_lang, i_code_mess => 'COMPLICATION_ERR013');
            l_error_code     := 'COMPLICATION_ERR005';
            l_error_message  := pk_message.get_message(i_lang => i_lang, i_code_mess => l_error_code);
        
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => l_error_code,
                                              i_sqlerrm     => l_error_message,
                                              i_message     => g_error,
                                              i_owner       => g_owner,
                                              i_package     => g_package,
                                              i_function    => l_proc_name,
                                              i_action_type => 'U',
                                              i_action_msg  => l_action_message,
                                              o_error       => o_error);
            pk_utils.undo_changes;
            RAISE;
    END validate_params;

    FUNCTION get_col_index
    (
        i_cols   IN table_varchar,
        col_name IN VARCHAR2
    ) RETURN NUMBER IS
        l_func_name VARCHAR2(30) := 'GET_COL_INDEX';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        FOR i IN 1 .. i_cols.count
        LOOP
            IF i_cols(i) = col_name
            THEN
                RETURN i;
            END IF;
        END LOOP;
    
        RETURN - 1; --NOT FOUND
    END get_col_index;

    FUNCTION get_num_value
    (
        i_cols   IN table_varchar,
        i_vals   IN table_varchar,
        col_name IN VARCHAR2
    ) RETURN NUMBER IS
        l_func_name VARCHAR2(30) := 'GET_NUM_VALUE';
        --
        l_index NUMBER := get_col_index(i_cols, col_name);
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        IF l_index = -1
        THEN
            RETURN NULL;
        ELSE
            RETURN to_number(i_vals(l_index));
        END IF;
    END get_num_value;

    FUNCTION get_date_value
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_cols   IN table_varchar,
        i_vals   IN table_varchar,
        col_name IN VARCHAR2
    ) RETURN TIMESTAMP
        WITH TIME ZONE IS
        l_func_name VARCHAR2(30) := 'GET_DATE_VALUE';
        --
        l_index NUMBER := get_col_index(i_cols, col_name);
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        IF l_index = -1
        THEN
            RETURN NULL;
        ELSE
            RETURN pk_date_utils.get_string_tstz(i_lang, i_prof, i_vals(l_index), NULL);
        END IF;
    END get_date_value;

    FUNCTION get_str_value
    (
        i_cols   IN table_varchar,
        i_vals   IN table_varchar,
        col_name IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(30) := 'GET_STR_VALUE';
        --
        l_index NUMBER := get_col_index(i_cols, col_name);
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        IF l_index = -1
        THEN
            RETURN NULL;
        ELSE
            RETURN i_vals(l_index);
        END IF;
    END get_str_value;

    PROCEDURE set_assoc_task
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_assoc_task_table  IN table_varchar,
        i_epis_complication IN epis_complication.id_epis_complication%TYPE,
        i_epis_comp_hist    IN epis_comp_hist.id_epis_comp_hist%TYPE,
        o_epis_comp_detail  OUT table_number,
        o_error             OUT t_error_out
    ) IS
        l_proc_name VARCHAR2(30) := 'SET_ASSOC_TASK';
        --
        l_aux_table         table_varchar;
        l_epis_comp_detail  table_number;
        l_id_comp_axe       epis_comp_detail.id_comp_axe%TYPE;
        l_id_context        epis_comp_detail.id_context_new%TYPE;
        l_flg_context       epis_comp_detail.id_sys_list%TYPE;
        l_dt_context        epis_comp_detail.dt_context%TYPE;
        l_context_prof      epis_comp_detail.id_context_prof%TYPE; --requested_by
        l_context_prof_spec epis_comp_detail.id_context_prof_spec%TYPE; --ordered_by
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
    
        g_error := 'INITIALIZE VAR';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        o_epis_comp_detail := table_number();
    
        g_error := 'VERIFY IF IS TO DELETE INFORMATION';
        IF i_assoc_task_table IS NULL
           OR i_assoc_task_table.count = 0
           OR (i_assoc_task_table.count = 1 AND i_assoc_task_table(1) IS NULL)
        THEN
            g_error := 'GET ROWS THAT WILL GO INTO HISTORY';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
            SELECT ecd.id_epis_comp_detail
              BULK COLLECT
              INTO l_epis_comp_detail
              FROM epis_comp_detail ecd
              JOIN comp_axe ca
                ON ca.id_comp_axe = ecd.id_comp_axe
              JOIN TABLE(pk_sys_list.tf_sys_list_values(i_lang, i_prof, pk_complication_core.g_lst_grp_axe_at_types)) t
                ON t.id_sys_list = ca.id_sys_list
             WHERE ecd.id_epis_complication = i_epis_complication
               AND ecd.dt_context IS NOT NULL
               AND ecd.id_epis_comp_hist IS NULL;
        
            g_error := 'UPD COMP DETAIL HIST';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
            IF NOT set_epis_comp_detail_hist(i_lang             => i_lang,
                                             i_epis_comp_detail => l_epis_comp_detail,
                                             i_epis_comp_hist   => i_epis_comp_hist,
                                             o_error            => o_error)
            THEN
                pk_alertlog.log_debug(l_proc_name || ' - ' || g_error);
                RAISE e_general_error;
            END IF;
        
            o_epis_comp_detail := l_epis_comp_detail;
        ELSE
            g_error := 'INSERT ASSOCIATED TASKS';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
            FOR l_assoc_task IN (SELECT column_value assoc_task
                                   FROM TABLE(i_assoc_task_table))
            LOOP
                IF l_assoc_task.assoc_task IS NOT NULL
                THEN
                    l_aux_table := pk_utils.str_split_l(l_assoc_task.assoc_task, g_delim_2);
                
                    l_id_comp_axe       := to_number(l_aux_table(1));
                    l_id_context        := l_aux_table(2);
                    l_flg_context       := to_number(l_aux_table(3));
                    l_dt_context        := pk_date_utils.get_string_tstz(i_lang, i_prof, l_aux_table(4), NULL);
                    l_context_prof      := to_number(l_aux_table(5));
                    l_context_prof_spec := to_number(l_aux_table(6));
                
                    IF l_id_comp_axe IS NOT NULL
                    THEN
                        IF NOT set_epis_comp_detail(i_lang              => i_lang,
                                                    i_prof              => i_prof,
                                                    i_epis_complication => i_epis_complication,
                                                    i_comp_axe          => l_id_comp_axe,
                                                    i_child_axe         => NULL,
                                                    i_context           => l_id_context,
                                                    i_flg_context       => l_flg_context,
                                                    i_dt_context        => l_dt_context,
                                                    i_context_prof      => l_context_prof, --requested_by
                                                    i_context_prof_spec => l_context_prof_spec, --ordered_by
                                                    i_epis_comp_hist    => i_epis_comp_hist,
                                                    i_type              => pk_complication_core.get_cfg_typ_assoc_task(i_lang,
                                                                                                                       i_prof),
                                                    o_epis_comp_detail  => l_epis_comp_detail,
                                                    o_error             => o_error)
                        THEN
                            pk_alertlog.log_debug(l_proc_name || ' - ' || g_error || '; Associated tasks: "' ||
                                                  pk_utils.concat_table(i_assoc_task_table) ||
                                                  '"; Current id_context: "' || l_id_context ||
                                                  '"; o_epis_comp_detail: "' ||
                                                  pk_utils.concat_table(l_epis_comp_detail) || '".');
                            RAISE e_general_error;
                        END IF;
                    
                        FOR tbl_aux IN (SELECT column_value id_epis_comp_detail
                                          FROM TABLE(l_epis_comp_detail))
                        LOOP
                            o_epis_comp_detail.extend();
                            o_epis_comp_detail(o_epis_comp_detail.count) := tbl_aux.id_epis_comp_detail;
                        END LOOP;
                    END IF;
                END IF;
            END LOOP;
        END IF;
    END set_assoc_task;

    PROCEDURE set_axes
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_axe_type          IN comp_axe.id_sys_list%TYPE,
        i_axes_table        IN table_varchar,
        i_epis_complication IN epis_complication.id_epis_complication%TYPE,
        i_epis_comp_hist    IN epis_comp_hist.id_epis_comp_hist%TYPE,
        o_epis_comp_detail  OUT table_number,
        o_error             OUT t_error_out
    ) IS
        l_proc_name VARCHAR2(30) := 'SET_AXES';
        --
        l_aux_table        table_varchar;
        l_epis_comp_detail table_number;
        l_comp_axe         epis_comp_detail.id_comp_axe%TYPE;
        l_child_comp_axe   epis_comp_detail_axe.id_comp_axe%TYPE;
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
    
        g_error := 'INITIALIZE VAR';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        o_epis_comp_detail := table_number();
    
        g_error := 'VERIFY IF IS TO DELETE INFORMATION';
        IF i_axes_table IS NULL
           OR i_axes_table.count = 0
           OR (i_axes_table.count = 1 AND i_axes_table(1) IS NULL)
        THEN
            g_error := 'GET ROWS THAT WILL GO INTO HISTORY';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
            SELECT ecd.id_epis_comp_detail
              BULK COLLECT
              INTO l_epis_comp_detail
              FROM epis_comp_detail ecd
              JOIN comp_axe ca
                ON ca.id_comp_axe = ecd.id_comp_axe
               AND ca.id_sys_list = i_axe_type
             WHERE ecd.id_epis_complication = i_epis_complication
               AND ecd.id_epis_comp_hist IS NULL;
        
            g_error := 'UPD COMP DETAIL HIST';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
            IF NOT set_epis_comp_detail_hist(i_lang             => i_lang,
                                             i_epis_comp_detail => l_epis_comp_detail,
                                             i_epis_comp_hist   => i_epis_comp_hist,
                                             o_error            => o_error)
            THEN
                pk_alertlog.log_debug(l_proc_name || ' - ' || g_error);
                RAISE e_general_error;
            END IF;
        
            o_epis_comp_detail := l_epis_comp_detail;
        ELSE
            g_error := 'SET EPIS_COMP_DETAIL DATA';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
            FOR l_cur_value IN (SELECT column_value data
                                  FROM TABLE(i_axes_table))
            LOOP
                IF l_cur_value.data IS NOT NULL
                THEN
                    l_aux_table := pk_utils.str_split_l(l_cur_value.data, g_delim_2);
                
                    l_comp_axe := to_number(l_aux_table(1));
                
                    IF l_aux_table.count = 2
                    THEN
                        l_child_comp_axe := to_number(l_aux_table(2));
                    ELSE
                        l_child_comp_axe := NULL;
                    END IF;
                
                    IF nvl(l_comp_axe, -99) != -99
                    THEN
                        l_epis_comp_detail := table_number();
                    
                        IF NOT set_epis_comp_detail(i_lang              => i_lang,
                                                    i_prof              => i_prof,
                                                    i_epis_complication => i_epis_complication,
                                                    i_comp_axe          => l_comp_axe,
                                                    i_child_axe         => l_child_comp_axe,
                                                    i_context           => NULL,
                                                    i_flg_context       => NULL,
                                                    i_dt_context        => NULL,
                                                    i_context_prof      => NULL,
                                                    i_context_prof_spec => NULL,
                                                    i_epis_comp_hist    => i_epis_comp_hist,
                                                    i_type              => pk_complication_core.get_cfg_typ_axe(i_lang,
                                                                                                                i_prof),
                                                    o_epis_comp_detail  => l_epis_comp_detail,
                                                    o_error             => o_error)
                        THEN
                            pk_alertlog.log_debug(l_proc_name || ' - ' || g_error || '; Axes: "' ||
                                                  pk_utils.concat_table(i_axes_table) || '"; Current axe: "' ||
                                                  to_char(l_cur_value.data) || '"; o_epis_comp_detail: "' ||
                                                  pk_utils.concat_table(l_epis_comp_detail) || '".');
                            RAISE e_general_error;
                        END IF;
                    
                        FOR tbl_aux IN (SELECT column_value id_epis_comp_detail
                                          FROM TABLE(l_epis_comp_detail))
                        LOOP
                            o_epis_comp_detail.extend();
                            o_epis_comp_detail(o_epis_comp_detail.count) := tbl_aux.id_epis_comp_detail;
                        END LOOP;
                    END IF;
                END IF;
            END LOOP;
        END IF;
    END set_axes;

    /**
    * Add/Upd a complication
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_cols                      Columns names
    * @param   i_vals                      Columns values
    * @param   i_is_ins                    True - Is to insert a new complication, Otherwise is to update a existing complication
    * @param   o_epis_complication         Created epis complication id
    * @param   o_epis_comp_detail          Created epis comp detail id's
    * @param   o_epis_comp_prof            Created epis comp prof id's
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   18-12-2009
    */
    FUNCTION set_complication
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_cols              IN table_varchar,
        i_vals              IN table_varchar,
        i_is_ins            IN BOOLEAN,
        o_epis_complication OUT epis_complication.id_epis_complication%TYPE,
        o_epis_comp_detail  OUT table_number,
        o_epis_comp_prof    OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'SET_COMPLICATION';
        --
        l_i_epis_complication epis_complication.id_epis_complication%TYPE; -- If is to update, this var gets the corresponding id 
        l_epis_complication   epis_complication.id_epis_complication%TYPE;
        l_epis_comp_hist      epis_comp_hist.id_epis_comp_hist%TYPE;
        l_epis_comp_detail    table_number;
        l_epis_comp_prof      table_number;
        l_aux_table           table_varchar;
        l_aux_tbl_num         table_number;
        l_id_comp_axe         epis_comp_detail.id_comp_axe%TYPE;
        l_id_context          epis_comp_detail.id_context_new%TYPE;
        l_flg_context         epis_comp_detail.id_sys_list%TYPE;
        l_desc_diag           table_varchar;
        --
        l_error          t_error_out;
        l_action_message sys_message.desc_message%TYPE;
        l_error_code     sys_message.code_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
        --
        l_valid_cols t_table_comp_col_info := t_table_comp_col_info(t_rec_comp_col_info(col_name => g_col_name_id_epis_comp,
                                                                                        col_type => g_col_info_typ_num,
                                                                                        col_size => NULL),
                                                                    t_rec_comp_col_info(col_name     => g_col_name_id_episode,
                                                                                        col_type     => g_col_info_typ_num,
                                                                                        col_size     => NULL,
                                                                                        col_nullable => pk_alert_constant.g_no),
                                                                    t_rec_comp_col_info(col_name => g_col_name_id_episode_origin,
                                                                                        col_type => g_col_info_typ_num,
                                                                                        col_size => NULL),
                                                                    t_rec_comp_col_info(col_name     => g_col_name_id_complication,
                                                                                        col_type     => g_col_info_typ_num,
                                                                                        col_size     => NULL,
                                                                                        col_nullable => pk_alert_constant.g_no),
                                                                    t_rec_comp_col_info(col_name => g_col_name_dt_verif_comp,
                                                                                        col_type => g_col_info_typ_date,
                                                                                        col_size => NULL),
                                                                    t_rec_comp_col_info(col_name     => g_col_name_flg_status_comp,
                                                                                        col_type     => g_col_info_typ_flg,
                                                                                        col_size     => 1,
                                                                                        col_nullable => pk_alert_constant.g_no),
                                                                    t_rec_comp_col_info(col_name => g_col_name_notes_comp,
                                                                                        col_type => g_col_info_typ_str,
                                                                                        col_size => NULL),
                                                                    t_rec_comp_col_info(col_name     => g_col_name_pathologies,
                                                                                        col_type     => g_col_info_typ_tbl_num,
                                                                                        col_size     => 2,
                                                                                        col_nullable => pk_alert_constant.g_no),
                                                                    t_rec_comp_col_info(col_name     => g_col_name_locations,
                                                                                        col_type     => g_col_info_typ_tbl_num,
                                                                                        col_size     => 2,
                                                                                        col_nullable => pk_alert_constant.g_no),
                                                                    t_rec_comp_col_info(col_name => g_col_name_external_factors,
                                                                                        col_type => g_col_info_typ_tbl_num,
                                                                                        col_size => 2),
                                                                    t_rec_comp_col_info(col_name => g_col_name_associated_tasks,
                                                                                        col_type => g_col_info_typ_tbl_str,
                                                                                        col_size => 6),
                                                                    t_rec_comp_col_info(col_name => g_col_name_assoc_task_profs,
                                                                                        col_type => g_col_info_typ_tbl_num,
                                                                                        col_size => NULL),
                                                                    t_rec_comp_col_info(col_name => g_col_name_diagnosis,
                                                                                        col_type => g_col_info_typ_tbl_num,
                                                                                        col_size => NULL),
                                                                    t_rec_comp_col_info(col_name => g_col_name_diagnosis_desc,
                                                                                        col_type => g_col_info_typ_tbl_str,
                                                                                        col_size => 1),
                                                                    t_rec_comp_col_info(col_name => g_col_name_effects,
                                                                                        col_type => g_col_info_typ_tbl_num,
                                                                                        col_size => NULL),
                                                                    t_rec_comp_col_info(col_name => g_col_name_treats_performed,
                                                                                        col_type => g_col_info_typ_tbl_str,
                                                                                        col_size => 3),
                                                                    t_rec_comp_col_info(col_name     => g_col_name_prof_clin_serv,
                                                                                        col_type     => g_col_info_typ_num,
                                                                                        col_size     => NULL,
                                                                                        col_nullable => pk_alert_constant.g_no));
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'VALIDATE PARAMS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT validate_params(i_lang       => i_lang,
                               i_prof       => i_prof,
                               i_cols       => i_cols,
                               i_vals       => i_vals,
                               i_valid_cols => l_valid_cols,
                               o_error      => l_error)
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_general_error;
        END IF;
    
        g_error := 'CLEAR PROCESSED EPIS_COMP_DETAIL';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        g_proc_epis_comp_detail := table_number();
    
        g_error := 'GET ID_EPIS_COMPLICATION';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF i_is_ins
        THEN
            --If is to insert a new epis_comp then the id must be null
            l_i_epis_complication := NULL;
        ELSE
            --Otherwise it must have a value
            IF get_col_index(i_cols, g_col_name_id_epis_comp) = -1
            THEN
                g_error := l_func_name || ' - "' || g_col_name_id_epis_comp || '" is a required field.';
                pk_alertlog.log_debug(g_error);
            
                l_action_message := pk_message.get_message(i_lang => i_lang, i_code_mess => 'COMPLICATION_ERR013');
                l_error_code     := 'COMPLICATION_ERR005';
                l_error_message  := pk_message.get_message(i_lang => i_lang, i_code_mess => l_error_code);
            
                l_error := t_error_out(ora_sqlcode         => l_error_code,
                                       ora_sqlerrm         => l_error_message,
                                       err_desc            => g_error,
                                       err_action          => l_action_message,
                                       log_id              => NULL,
                                       err_instance_id_out => NULL,
                                       msg_title           => NULL,
                                       flg_msg_type        => NULL);
            
                RAISE e_required_field;
            ELSE
                l_i_epis_complication := get_num_value(i_cols, i_vals, g_col_name_id_epis_comp);
            END IF;
        END IF;
    
        g_error := 'CREATE/UPDATE EPIS COMPLICATION';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT set_epis_complication(i_lang              => i_lang,
                                     i_prof              => i_prof,
                                     i_epis_complication => l_i_epis_complication,
                                     --i_episode is not updated because always stays associated with the id_episode where it was created
                                     i_episode           => CASE i_is_ins
                                                                WHEN TRUE THEN
                                                                 get_num_value(i_cols, i_vals, g_col_name_id_episode)
                                                                ELSE
                                                                 NULL
                                                            END,
                                     i_episode_origin    => get_num_value(i_cols, i_vals, g_col_name_id_episode_origin),
                                     i_complication      => get_num_value(i_cols, i_vals, g_col_name_id_complication),
                                     i_dt_verif          => get_date_value(i_lang,
                                                                           i_prof,
                                                                           i_cols,
                                                                           i_vals,
                                                                           g_col_name_dt_verif_comp),
                                     i_flg_status        => get_str_value(i_cols, i_vals, g_col_name_flg_status_comp),
                                     i_notes             => get_str_value(i_cols, i_vals, g_col_name_notes_comp),
                                     i_prof_clin_serv    => get_num_value(i_cols, i_vals, g_col_name_prof_clin_serv),
                                     o_epis_complication => l_epis_complication,
                                     o_epis_comp_hist    => l_epis_comp_hist,
                                     o_error             => o_error)
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_general_error;
        END IF;
    
        g_error := 'INITIALIZE VARS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        o_epis_complication := l_epis_complication;
        o_epis_comp_detail  := table_number();
        o_epis_comp_prof    := table_number();
    
        g_error := 'INSERT PATHOLOGIES';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_aux_table := pk_utils.str_split_l(get_str_value(i_cols, i_vals, g_col_name_pathologies), g_delim_1);
        set_axes(i_lang              => i_lang,
                 i_prof              => i_prof,
                 i_axe_type          => pk_complication_core.get_axe_typ_path(i_lang, i_prof),
                 i_axes_table        => l_aux_table,
                 i_epis_complication => l_epis_complication,
                 i_epis_comp_hist    => l_epis_comp_hist,
                 o_epis_comp_detail  => l_epis_comp_detail,
                 o_error             => o_error);
    
        FOR tbl_aux IN (SELECT column_value id_epis_comp_detail
                          FROM TABLE(l_epis_comp_detail))
        LOOP
            o_epis_comp_detail.extend();
            o_epis_comp_detail(o_epis_comp_detail.count) := tbl_aux.id_epis_comp_detail;
        END LOOP;
    
        g_error := 'INSERT LOCATIONS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_aux_table := pk_utils.str_split_l(get_str_value(i_cols, i_vals, g_col_name_locations), g_delim_1);
        set_axes(i_lang              => i_lang,
                 i_prof              => i_prof,
                 i_axe_type          => pk_complication_core.get_axe_typ_loc(i_lang, i_prof),
                 i_axes_table        => l_aux_table,
                 i_epis_complication => l_epis_complication,
                 i_epis_comp_hist    => l_epis_comp_hist,
                 o_epis_comp_detail  => l_epis_comp_detail,
                 o_error             => o_error);
    
        FOR tbl_aux IN (SELECT column_value id_epis_comp_detail
                          FROM TABLE(l_epis_comp_detail))
        LOOP
            o_epis_comp_detail.extend();
            o_epis_comp_detail(o_epis_comp_detail.count) := tbl_aux.id_epis_comp_detail;
        END LOOP;
    
        g_error := 'INSERT EXTERNAL_FACTORS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_aux_table := pk_utils.str_split_l(get_str_value(i_cols, i_vals, g_col_name_external_factors), g_delim_1);
        set_axes(i_lang              => i_lang,
                 i_prof              => i_prof,
                 i_axe_type          => pk_complication_core.get_axe_typ_ext_fact(i_lang, i_prof),
                 i_axes_table        => l_aux_table,
                 i_epis_complication => l_epis_complication,
                 i_epis_comp_hist    => l_epis_comp_hist,
                 o_epis_comp_detail  => l_epis_comp_detail,
                 o_error             => o_error);
    
        FOR tbl_aux IN (SELECT column_value id_epis_comp_detail
                          FROM TABLE(l_epis_comp_detail))
        LOOP
            o_epis_comp_detail.extend();
            o_epis_comp_detail(o_epis_comp_detail.count) := tbl_aux.id_epis_comp_detail;
        END LOOP;
    
        g_error := 'INSERT EFFECTS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_aux_table := pk_utils.str_split_l(get_str_value(i_cols, i_vals, g_col_name_effects), g_delim_1);
        set_axes(i_lang              => i_lang,
                 i_prof              => i_prof,
                 i_axe_type          => pk_complication_core.get_axe_typ_eff(i_lang, i_prof),
                 i_axes_table        => l_aux_table,
                 i_epis_complication => l_epis_complication,
                 i_epis_comp_hist    => l_epis_comp_hist,
                 o_epis_comp_detail  => l_epis_comp_detail,
                 o_error             => o_error);
    
        FOR tbl_aux IN (SELECT column_value id_epis_comp_detail
                          FROM TABLE(l_epis_comp_detail))
        LOOP
            o_epis_comp_detail.extend();
            o_epis_comp_detail(o_epis_comp_detail.count) := tbl_aux.id_epis_comp_detail;
        END LOOP;
    
        g_error := 'GET INPUT DIAGNOSIS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_aux_table := pk_utils.str_split_l(get_str_value(i_cols, i_vals, g_col_name_diagnosis), g_delim_1);
    
        IF l_aux_table.count > 0
        THEN
            g_error := 'FILL TBL_NUM WTIH DIAGs';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            SELECT to_number(column_value) id_diagnosis
              BULK COLLECT
              INTO l_aux_tbl_num
              FROM TABLE(l_aux_table);
        
            g_error := 'GET DESC DIAGNOSIS';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            l_desc_diag := pk_utils.str_split_l(get_str_value(i_cols, i_vals, g_col_name_diagnosis_desc), g_delim_1);
        
            IF l_desc_diag.count != l_aux_table.count
            THEN
                l_desc_diag := table_varchar();
                l_desc_diag.extend(l_aux_table.count);
            END IF;
        
            g_error := 'INSERT DIAGNOSIS';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            IF NOT pk_diagnosis.set_mcdt_req_diag_no_commit(i_lang              => i_lang,
                                                            i_prof              => i_prof,
                                                            i_epis              => get_num_value(i_cols,
                                                                                                 i_vals,
                                                                                                 g_col_name_id_episode),
                                                            i_diag              => l_aux_tbl_num,
                                                            i_desc_diagnosis    => l_desc_diag,
                                                            i_exam_req          => NULL,
                                                            i_analysis_req      => NULL,
                                                            i_interv_presc      => NULL,
                                                            i_exam_req_det      => NULL,
                                                            i_analysis_req_det  => NULL,
                                                            i_interv_presc_det  => NULL,
                                                            i_epis_complication => l_epis_complication,
                                                            i_epis_comp_hist    => l_epis_comp_hist,
                                                            o_error             => o_error)
            THEN
                pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
                RAISE e_general_error;
            END IF;
        END IF;
    
        g_error := 'INSERT ASSOC TASKS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_aux_table := pk_utils.str_split_l(get_str_value(i_cols, i_vals, g_col_name_associated_tasks), g_delim_1);
        set_assoc_task(i_lang              => i_lang,
                       i_prof              => i_prof,
                       i_assoc_task_table  => l_aux_table,
                       i_epis_complication => l_epis_complication,
                       i_epis_comp_hist    => l_epis_comp_hist,
                       o_epis_comp_detail  => l_epis_comp_detail,
                       o_error             => o_error);
    
        FOR tbl_aux IN (SELECT column_value id_epis_comp_detail
                          FROM TABLE(l_epis_comp_detail))
        LOOP
            o_epis_comp_detail.extend();
            o_epis_comp_detail(o_epis_comp_detail.count) := tbl_aux.id_epis_comp_detail;
        END LOOP;
    
        g_error := 'INSERT TREATMENTS PERFORMED';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_aux_table := pk_utils.str_split_l(get_str_value(i_cols, i_vals, g_col_name_treats_performed), g_delim_1);
    
        g_error := 'VERIFY IF IS TO DELETE INFORMATION';
        IF l_aux_table IS NULL
           OR l_aux_table.count = 0
           OR (l_aux_table.count = 1 AND l_aux_table(1) IS NULL)
        THEN
            g_error := 'GET ROWS THAT WILL GO INTO HISTORY';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            SELECT ecd.id_epis_comp_detail
              BULK COLLECT
              INTO l_epis_comp_detail
              FROM epis_comp_detail ecd
              JOIN comp_axe ca
                ON ca.id_comp_axe = ecd.id_comp_axe
              JOIN TABLE(pk_sys_list.tf_sys_list_values(i_lang, i_prof, pk_complication_core.g_lst_grp_axe_tp_types)) t
                ON t.id_sys_list = ca.id_sys_list
             WHERE ecd.id_epis_complication = l_epis_complication
               AND ecd.dt_context IS NULL
               AND ecd.id_epis_comp_hist IS NULL;
        
            g_error := 'UPD COMP DETAIL HIST';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            IF NOT set_epis_comp_detail_hist(i_lang             => i_lang,
                                             i_epis_comp_detail => l_epis_comp_detail,
                                             i_epis_comp_hist   => l_epis_comp_hist,
                                             o_error            => o_error)
            THEN
                pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
                RAISE e_general_error;
            END IF;
        
            FOR tbl_aux IN (SELECT column_value id_epis_comp_detail
                              FROM TABLE(l_epis_comp_detail))
            LOOP
                o_epis_comp_detail.extend();
                o_epis_comp_detail(o_epis_comp_detail.count) := tbl_aux.id_epis_comp_detail;
            END LOOP;
        ELSE
            FOR l_treat_perf IN (SELECT column_value treat_performed
                                   FROM TABLE(l_aux_table))
            LOOP
                IF l_treat_perf.treat_performed IS NOT NULL
                THEN
                    l_aux_table := pk_utils.str_split_l(l_treat_perf.treat_performed, g_delim_2);
                
                    l_id_comp_axe := to_number(l_aux_table(1));
                    l_id_context  := l_aux_table(2);
                    l_flg_context := l_aux_table(3);
                
                    IF l_id_comp_axe IS NOT NULL
                       AND l_id_comp_axe != -1
                    THEN
                        IF NOT set_epis_comp_detail(i_lang              => i_lang,
                                                    i_prof              => i_prof,
                                                    i_epis_complication => l_epis_complication,
                                                    i_comp_axe          => l_id_comp_axe,
                                                    i_child_axe         => NULL,
                                                    i_context           => l_id_context,
                                                    i_flg_context       => l_flg_context,
                                                    i_dt_context        => NULL,
                                                    i_context_prof      => NULL,
                                                    i_context_prof_spec => NULL,
                                                    i_epis_comp_hist    => l_epis_comp_hist,
                                                    i_type              => pk_complication_core.get_cfg_typ_treat_perf(i_lang,
                                                                                                                       i_prof),
                                                    o_epis_comp_detail  => l_epis_comp_detail,
                                                    o_error             => o_error)
                        THEN
                            pk_alertlog.log_debug(l_func_name || ' - ' || g_error || '; Treatments performed: "' ||
                                                  get_str_value(i_cols, i_vals, g_col_name_treats_performed) ||
                                                  '"; Current id_context: "' || l_id_context ||
                                                  '"; o_epis_comp_detail: "' ||
                                                  pk_utils.concat_table(l_epis_comp_detail) || '".');
                            RAISE e_general_error;
                        END IF;
                    
                        FOR tbl_aux IN (SELECT column_value id_epis_comp_detail
                                          FROM TABLE(l_epis_comp_detail))
                        LOOP
                            o_epis_comp_detail.extend();
                            o_epis_comp_detail(o_epis_comp_detail.count) := tbl_aux.id_epis_comp_detail;
                        END LOOP;
                    END IF;
                END IF;
            END LOOP;
        END IF;
    
        g_error := 'GET ID_PROFS TBL_CHAR';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_aux_table := pk_utils.str_split_l(get_str_value(i_cols, i_vals, g_col_name_assoc_task_profs), g_delim_1);
    
        g_error := 'VERIFY IF IS TO DELETE INFORMATION';
        IF l_aux_table IS NULL
           OR l_aux_table.count = 0
           OR (l_aux_table.count = 1 AND l_aux_table(1) IS NULL)
        THEN
            g_error := 'GET ROWS THAT WILL GO INTO HISTORY';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            SELECT ecp.id_epis_comp_prof
              BULK COLLECT
              INTO l_epis_comp_prof
              FROM epis_comp_prof ecp
             WHERE ecp.id_epis_complication = l_epis_complication
               AND ecp.id_epis_comp_hist IS NULL;
        
            g_error := 'SEND OLD PROFS TO HIST';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            FOR curr_prof IN (SELECT column_value id_epis_comp_prof
                                FROM TABLE(l_epis_comp_prof))
            LOOP
                IF NOT set_epis_comp_prof_hist(i_lang           => i_lang,
                                               i_epis_comp_prof => curr_prof.id_epis_comp_prof,
                                               i_epis_comp_hist => l_epis_comp_hist,
                                               o_error          => o_error)
                THEN
                    pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
                    RAISE e_general_error;
                END IF;
            
                o_epis_comp_prof.extend();
                o_epis_comp_prof(o_epis_comp_prof.count) := curr_prof.id_epis_comp_prof;
            END LOOP;
        ELSE
            g_error := 'CONVERT ID_PROFS TBL_CHAR TO TBL_NUMBER';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            SELECT to_number(column_value)
              BULK COLLECT
              INTO l_aux_tbl_num
              FROM TABLE(l_aux_table) t
             WHERE t.column_value IS NOT NULL;
        
            g_error := 'INSERT ASSOC TASK PROFESSIONALS';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            IF NOT set_epis_comp_prof(i_lang              => i_lang,
                                      i_prof              => i_prof,
                                      i_epis_complication => l_epis_complication,
                                      i_professional      => l_aux_tbl_num,
                                      i_epis_comp_hist    => l_epis_comp_hist,
                                      o_epis_comp_prof    => l_epis_comp_prof,
                                      o_error             => o_error)
            THEN
                pk_alertlog.log_debug(l_func_name || ' - ' || g_error || '; Profs: "' ||
                                      get_str_value(i_cols, i_vals, g_col_name_assoc_task_profs) || '"; Profs: "' ||
                                      pk_utils.concat_table(l_aux_tbl_num) || '"; Output Prof: "' ||
                                      pk_utils.concat_table(l_epis_comp_prof) || '".');
                RAISE e_general_error;
            END IF;
        
            FOR tbl_aux IN (SELECT column_value id_epis_comp_prof
                              FROM TABLE(l_epis_comp_prof))
            LOOP
                o_epis_comp_prof.extend();
                o_epis_comp_prof(o_epis_comp_prof.count) := tbl_aux.id_epis_comp_prof;
            END LOOP;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN e_arrays_size_dont_match
             OR e_not_a_number
             OR e_not_a_flag
             OR e_not_a_date
             OR e_wrong_column_name
             OR e_required_field THEN
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => l_error.ora_sqlcode,
                                              i_sqlerrm     => l_error.ora_sqlerrm,
                                              i_message     => l_error.err_desc,
                                              i_owner       => g_owner,
                                              i_package     => g_package,
                                              i_function    => l_func_name,
                                              i_action_type => 'U',
                                              i_action_msg  => l_error.err_action,
                                              o_error       => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_complication;

    /**
    * Add/Upd a complication request
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_cols                      Columns names
    * @param   i_vals                      Columns values
    * @param   i_is_ins                    True - Is to insert a new complication request, Otherwise is to update a existing complication request
    * @param   o_epis_complication         Created epis complication id
    * @param   o_epis_comp_detail          Created epis comp detail id's
    * @param   o_epis_comp_prof            Created epis comp prof id's
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   23-12-2009
    */
    FUNCTION set_request
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_cols              IN table_varchar,
        i_vals              IN table_varchar,
        i_is_ins            IN BOOLEAN,
        o_epis_complication OUT epis_complication.id_epis_complication%TYPE,
        o_epis_comp_detail  OUT table_number,
        o_epis_comp_prof    OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'SET_REQUEST';
        --
        l_i_epis_complication epis_complication.id_epis_complication%TYPE; -- If is to update, this var gets the corresponding id 
        l_epis_complication   epis_complication.id_epis_complication%TYPE;
        l_epis_comp_hist      epis_comp_hist.id_epis_comp_hist%TYPE;
        l_epis_comp_detail    table_number;
        l_epis_comp_prof      table_number;
        l_aux_table           table_varchar;
        l_aux_tbl_num         table_number;
        --
        l_error          t_error_out;
        l_action_message sys_message.desc_message%TYPE;
        l_error_code     sys_message.code_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
        --
        l_valid_cols t_table_comp_col_info := t_table_comp_col_info(t_rec_comp_col_info(col_name => g_col_name_id_epis_comp,
                                                                                        col_type => g_col_info_typ_num,
                                                                                        col_size => NULL),
                                                                    t_rec_comp_col_info(col_name => g_col_name_id_episode,
                                                                                        col_type => g_col_info_typ_num,
                                                                                        col_size => NULL),
                                                                    t_rec_comp_col_info(col_name => g_col_name_id_episode_origin,
                                                                                        col_type => g_col_info_typ_num,
                                                                                        col_size => NULL),
                                                                    t_rec_comp_col_info(col_name     => g_col_name_description,
                                                                                        col_type     => g_col_info_typ_str,
                                                                                        col_size     => NULL,
                                                                                        col_nullable => pk_alert_constant.g_no),
                                                                    t_rec_comp_col_info(col_name => g_col_name_dt_verif_req,
                                                                                        col_type => g_col_info_typ_date,
                                                                                        col_size => NULL),
                                                                    t_rec_comp_col_info(col_name => g_col_name_notes_req,
                                                                                        col_type => g_col_info_typ_str,
                                                                                        col_size => NULL),
                                                                    t_rec_comp_col_info(col_name => g_col_name_associated_tasks,
                                                                                        col_type => g_col_info_typ_tbl_str,
                                                                                        col_size => 6),
                                                                    t_rec_comp_col_info(col_name     => g_col_name_req_clin_serv,
                                                                                        col_type     => g_col_info_typ_num,
                                                                                        col_size     => NULL,
                                                                                        col_nullable => pk_alert_constant.g_no),
                                                                    t_rec_comp_col_info(col_name     => g_col_name_req_profs,
                                                                                        col_type     => g_col_info_typ_tbl_num,
                                                                                        col_size     => NULL,
                                                                                        col_nullable => pk_alert_constant.g_no));
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'VALIDATE PARAMS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT validate_params(i_lang       => i_lang,
                               i_prof       => i_prof,
                               i_cols       => i_cols,
                               i_vals       => i_vals,
                               i_valid_cols => l_valid_cols,
                               o_error      => l_error)
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_general_error;
        END IF;
    
        g_error := 'CLEAR PROCESSED EPIS_COMP_DETAIL';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        g_proc_epis_comp_detail := table_number();
    
        g_error := 'GET ID_EPIS_COMPLICATION';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF i_is_ins
        THEN
            --If is to insert a new epis_comp then the id must be null
            l_i_epis_complication := NULL;
        ELSE
            --Otherwise it must have a value
            IF get_col_index(i_cols, g_col_name_id_epis_comp) = -1
            THEN
                g_error := l_func_name || ' - "' || g_col_name_id_epis_comp || '" is a required field.';
                pk_alertlog.log_debug(g_error);
            
                l_action_message := pk_message.get_message(i_lang => i_lang, i_code_mess => 'COMPLICATION_ERR013');
                l_error_code     := 'COMPLICATION_ERR005';
                l_error_message  := pk_message.get_message(i_lang => i_lang, i_code_mess => l_error_code);
            
                l_error := t_error_out(ora_sqlcode         => l_error_code,
                                       ora_sqlerrm         => l_error_message,
                                       err_desc            => g_error,
                                       err_action          => l_action_message,
                                       log_id              => NULL,
                                       err_instance_id_out => NULL,
                                       msg_title           => NULL,
                                       flg_msg_type        => NULL);
            
                RAISE e_required_field;
            ELSE
                l_i_epis_complication := get_num_value(i_cols, i_vals, g_col_name_id_epis_comp);
            END IF;
        END IF;
    
        g_error := 'CREATE/UPDATE EPIS COMP REQUEST';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT set_epis_comp_request(i_lang              => i_lang,
                                     i_prof              => i_prof,
                                     i_epis_complication => l_i_epis_complication,
                                     --i_episode is not updated because always stays associated with the id_episode where it was created
                                     i_episode           => (CASE i_is_ins
                                                                WHEN TRUE THEN
                                                                 get_num_value(i_cols, i_vals, g_col_name_id_episode)
                                                                ELSE
                                                                 NULL
                                                            END),
                                     i_episode_origin    => get_num_value(i_cols, i_vals, g_col_name_id_episode_origin),
                                     i_description       => get_str_value(i_cols, i_vals, g_col_name_description),
                                     i_dt_verif          => get_date_value(i_lang,
                                                                           i_prof,
                                                                           i_cols,
                                                                           i_vals,
                                                                           g_col_name_dt_verif_req),
                                     i_flg_status        => g_req_flg_status_r,
                                     i_notes             => get_str_value(i_cols, i_vals, g_col_name_notes_req),
                                     i_clin_serv_dest    => get_num_value(i_cols, i_vals, g_col_name_req_clin_serv),
                                     o_epis_complication => l_epis_complication,
                                     o_epis_comp_hist    => l_epis_comp_hist,
                                     o_error             => o_error)
        THEN
            RETURN FALSE; -- o_error can contain user error messages so function must end now
        END IF;
    
        g_error := 'INITIALIZE VARS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        o_epis_complication := l_epis_complication;
        o_epis_comp_detail  := table_number();
        o_epis_comp_prof    := table_number();
    
        g_error := 'INSERT ASSOC TASKS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_aux_table := pk_utils.str_split_l(get_str_value(i_cols, i_vals, g_col_name_associated_tasks), g_delim_1);
        set_assoc_task(i_lang              => i_lang,
                       i_prof              => i_prof,
                       i_assoc_task_table  => l_aux_table,
                       i_epis_complication => l_epis_complication,
                       i_epis_comp_hist    => l_epis_comp_hist,
                       o_epis_comp_detail  => l_epis_comp_detail,
                       o_error             => o_error);
    
        FOR tbl_aux IN (SELECT column_value id_epis_comp_detail
                          FROM TABLE(l_epis_comp_detail))
        LOOP
            o_epis_comp_detail.extend();
            o_epis_comp_detail(o_epis_comp_detail.count) := tbl_aux.id_epis_comp_detail;
        END LOOP;
    
        g_error := 'GET ID_PROFS TBL_CHAR';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_aux_table := pk_utils.str_split_l(get_str_value(i_cols, i_vals, g_col_name_req_profs), g_delim_1);
    
        g_error := 'CONVERT ID_PROFS TBL_CHAR TO TBL_NUMBER';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        SELECT to_number(column_value)
          BULK COLLECT
          INTO l_aux_tbl_num
          FROM TABLE(l_aux_table) t
         WHERE t.column_value IS NOT NULL;
    
        g_error := 'INSERT ASSOC TASK PROFESSIONALS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT set_epis_comp_prof(i_lang              => i_lang,
                                  i_prof              => i_prof,
                                  i_epis_complication => l_epis_complication,
                                  i_professional      => l_aux_tbl_num,
                                  i_epis_comp_hist    => l_epis_comp_hist,
                                  o_epis_comp_prof    => l_epis_comp_prof,
                                  o_error             => o_error)
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error || '; Profs: "' ||
                                  get_str_value(i_cols, i_vals, g_col_name_req_profs) || '"; Profs: "' ||
                                  pk_utils.concat_table(l_aux_tbl_num) || '"; Output Prof: "' ||
                                  pk_utils.concat_table(l_epis_comp_prof) || '".');
            RAISE e_general_error;
        END IF;
    
        FOR tbl_aux IN (SELECT column_value id_epis_comp_prof
                          FROM TABLE(l_epis_comp_prof))
        LOOP
            o_epis_comp_prof.extend();
            o_epis_comp_prof(o_epis_comp_prof.count) := tbl_aux.id_epis_comp_prof;
        END LOOP;
    
        IF i_is_ins
           AND l_aux_tbl_num.count > 0
        THEN
            FOR tbl_prof IN (SELECT column_value id_professional
                               FROM TABLE(l_aux_tbl_num))
            LOOP
                g_error := 'CREATE SYS_ALERT - ID_PROF: ' || tbl_prof.id_professional;
                alertlog.pk_alertlog.log_info(text            => g_error,
                                              object_name     => g_package,
                                              sub_object_name => l_func_name);
                IF NOT pk_alerts.insert_sys_alert_event(i_lang                => i_lang,
                                                        i_prof                => i_prof,
                                                        i_sys_alert           => g_sys_alert,
                                                        i_id_episode          => get_num_value(i_cols,
                                                                                               i_vals,
                                                                                               g_col_name_id_episode),
                                                        i_id_record           => l_epis_complication,
                                                        i_dt_record           => g_sysdate_tstz,
                                                        i_id_professional     => (CASE tbl_prof.id_professional
                                                                                     WHEN -1 THEN
                                                                                      NULL
                                                                                     ELSE
                                                                                      tbl_prof.id_professional
                                                                                 END),
                                                        i_id_room             => NULL,
                                                        i_id_clinical_service => (CASE tbl_prof.id_professional
                                                                                     WHEN -1 THEN
                                                                                      get_num_value(i_cols,
                                                                                                    i_vals,
                                                                                                    g_col_name_req_clin_serv)
                                                                                     ELSE
                                                                                      NULL
                                                                                 END),
                                                        i_flg_type_dest       => 'C',
                                                        i_replace1            => NULL,
                                                        i_replace2            => NULL,
                                                        o_error               => o_error)
                THEN
                    pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
                    RAISE e_general_error;
                END IF;
            END LOOP;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN e_arrays_size_dont_match
             OR e_not_a_number
             OR e_not_a_flag
             OR e_not_a_date
             OR e_wrong_column_name
             OR e_required_field THEN
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => l_error.ora_sqlcode,
                                              i_sqlerrm     => l_error.ora_sqlerrm,
                                              i_message     => l_error.err_desc,
                                              i_owner       => g_owner,
                                              i_package     => g_package,
                                              i_function    => l_func_name,
                                              i_action_type => 'U',
                                              i_action_msg  => l_error.err_action,
                                              o_error       => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_request;

    /********************************************************************************************
    * Gets the list of tasks to associate with the complication
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_patient                   Patient id
    * @param   i_episode                   Episode id
    * @param   o_type_tasks                Type of tasks
    * @param   o_tasks                     Tasks list
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  José Silva
    * @version v2.6
    * @since   04-01-2010
    ********************************************************************************************/
    FUNCTION get_assoc_task_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        o_type_tasks OUT pk_types.cursor_type,
        o_tasks      OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_ASSOC_TASK_LIST';
        e_error EXCEPTION;
    
        l_id_visit visit.id_visit%TYPE;
        l_tasks    pk_types.cursor_type;
    
        l_type_tasks table_varchar := table_varchar();
    
        l_id_task        table_number := table_number();
        l_desc_task      table_varchar := table_varchar();
        l_id_episode     table_number := table_number();
        l_flg_type       table_number := table_number();
        l_flg_context    table_number := table_number();
        l_dt_task        table_varchar := table_varchar();
        l_dt_task_send   table_varchar := table_varchar();
        l_id_prof_task   table_number := table_number();
        l_name_prof_task table_varchar := table_varchar();
        l_id_prof_req    table_number := table_number();
        l_name_prof_req  table_varchar := table_varchar();
    
        l_inst      comp_config.id_institution%TYPE;
        l_soft      comp_config.id_software%TYPE;
        l_clin_serv comp_config.id_clinical_service%TYPE;
        l_error     t_error_out;
    
        l_msg_none sys_message.desc_message%TYPE;
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'GET VISIT ID';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        BEGIN
            SELECT id_visit
              INTO l_id_visit
              FROM episode
             WHERE id_episode = i_episode;
        EXCEPTION
            WHEN no_data_found THEN
                l_id_visit := NULL;
        END;
    
        g_error := 'GET ANALYSIS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT pk_api_complications.get_analysis(i_lang     => i_lang,
                                                 i_prof     => i_prof,
                                                 i_patient  => i_patient,
                                                 i_visit    => l_id_visit,
                                                 i_type     => g_flg_cfg_typ_assoc_task,
                                                 o_analysis => l_tasks,
                                                 o_error    => o_error)
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_error;
        END IF;
    
        g_error := 'MERGE TASKS 1';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT pk_api_complications.merge_tasks(i_lang           => i_lang,
                                                i_prof           => i_prof,
                                                i_tasks          => l_tasks,
                                                i_task           => get_axe_typ_at_lab_test(i_lang, i_prof),
                                                i_type_tasks     => l_type_tasks,
                                                i_id_task        => l_id_task,
                                                i_desc_task      => l_desc_task,
                                                i_id_epis        => l_id_episode,
                                                i_flg_type       => l_flg_type,
                                                i_flg_context    => l_flg_context,
                                                i_dt_task        => l_dt_task,
                                                i_dt_task_send   => l_dt_task_send,
                                                i_id_prof_task   => l_id_prof_task,
                                                i_name_prof_task => l_name_prof_task,
                                                i_id_prof_req    => l_id_prof_req,
                                                i_name_prof_req  => l_name_prof_req,
                                                o_error          => o_error)
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_error;
        END IF;
    
        g_error := 'GET IMAGE EXAMS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT pk_api_complications.get_img_exams(i_lang    => i_lang,
                                                  i_prof    => i_prof,
                                                  i_patient => i_patient,
                                                  i_visit   => l_id_visit,
                                                  i_type    => g_flg_cfg_typ_assoc_task,
                                                  o_exams   => l_tasks,
                                                  o_error   => o_error)
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_error;
        END IF;
    
        g_error := 'MERGE TASKS 2';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT pk_api_complications.merge_tasks(i_lang           => i_lang,
                                                i_prof           => i_prof,
                                                i_tasks          => l_tasks,
                                                i_task           => get_axe_typ_at_imaging(i_lang, i_prof),
                                                i_type_tasks     => l_type_tasks,
                                                i_id_task        => l_id_task,
                                                i_desc_task      => l_desc_task,
                                                i_id_epis        => l_id_episode,
                                                i_flg_type       => l_flg_type,
                                                i_flg_context    => l_flg_context,
                                                i_dt_task        => l_dt_task,
                                                i_dt_task_send   => l_dt_task_send,
                                                i_id_prof_task   => l_id_prof_task,
                                                i_name_prof_task => l_name_prof_task,
                                                i_id_prof_req    => l_id_prof_req,
                                                i_name_prof_req  => l_name_prof_req,
                                                o_error          => o_error)
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_error;
        END IF;
    
        g_error := 'GET EXAMS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT pk_api_complications.get_exams(i_lang    => i_lang,
                                              i_prof    => i_prof,
                                              i_patient => i_patient,
                                              i_visit   => l_id_visit,
                                              i_type    => g_flg_cfg_typ_assoc_task,
                                              o_exams   => l_tasks,
                                              o_error   => o_error)
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_error;
        END IF;
    
        g_error := 'MERGE TASKS 3';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT pk_api_complications.merge_tasks(i_lang           => i_lang,
                                                i_prof           => i_prof,
                                                i_tasks          => l_tasks,
                                                i_task           => get_axe_typ_at_exam(i_lang, i_prof),
                                                i_type_tasks     => l_type_tasks,
                                                i_id_task        => l_id_task,
                                                i_desc_task      => l_desc_task,
                                                i_id_epis        => l_id_episode,
                                                i_flg_type       => l_flg_type,
                                                i_flg_context    => l_flg_context,
                                                i_dt_task        => l_dt_task,
                                                i_dt_task_send   => l_dt_task_send,
                                                i_id_prof_task   => l_id_prof_task,
                                                i_name_prof_task => l_name_prof_task,
                                                i_id_prof_req    => l_id_prof_req,
                                                i_name_prof_req  => l_name_prof_req,
                                                o_error          => o_error)
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_error;
        END IF;
    
        g_error := 'GET DIETS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT pk_api_complications.get_diets(i_lang    => i_lang,
                                              i_prof    => i_prof,
                                              i_patient => i_patient,
                                              i_episode => i_episode,
                                              i_type    => g_flg_cfg_typ_assoc_task,
                                              o_diet    => l_tasks,
                                              o_error   => o_error)
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_error;
        END IF;
    
        g_error := 'MERGE TASKS 4';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT pk_api_complications.merge_tasks(i_lang           => i_lang,
                                                i_prof           => i_prof,
                                                i_tasks          => l_tasks,
                                                i_task           => get_axe_typ_at_diet(i_lang, i_prof),
                                                i_type_tasks     => l_type_tasks,
                                                i_id_task        => l_id_task,
                                                i_desc_task      => l_desc_task,
                                                i_id_epis        => l_id_episode,
                                                i_flg_type       => l_flg_type,
                                                i_flg_context    => l_flg_context,
                                                i_dt_task        => l_dt_task,
                                                i_dt_task_send   => l_dt_task_send,
                                                i_id_prof_task   => l_id_prof_task,
                                                i_name_prof_task => l_name_prof_task,
                                                i_id_prof_req    => l_id_prof_req,
                                                i_name_prof_req  => l_name_prof_req,
                                                o_error          => o_error)
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_error;
        END IF;
    
        g_error := 'GET MEDICATION';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT pk_api_complications.get_medication(i_lang    => i_lang,
                                                   i_prof    => i_prof,
                                                   i_patient => i_patient,
                                                   i_visit   => l_id_visit,
                                                   i_episode => i_episode,
                                                   i_type    => g_flg_cfg_typ_assoc_task,
                                                   o_med     => l_tasks,
                                                   o_error   => o_error)
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_error;
        END IF;
    
        g_error := 'MERGE TASKS 5';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT pk_api_complications.merge_tasks(i_lang           => i_lang,
                                                i_prof           => i_prof,
                                                i_tasks          => l_tasks,
                                                i_task           => get_axe_typ_at_med(i_lang, i_prof),
                                                i_type_tasks     => l_type_tasks,
                                                i_id_task        => l_id_task,
                                                i_desc_task      => l_desc_task,
                                                i_id_epis        => l_id_episode,
                                                i_flg_type       => l_flg_type,
                                                i_flg_context    => l_flg_context,
                                                i_dt_task        => l_dt_task,
                                                i_dt_task_send   => l_dt_task_send,
                                                i_id_prof_task   => l_id_prof_task,
                                                i_name_prof_task => l_name_prof_task,
                                                i_id_prof_req    => l_id_prof_req,
                                                i_name_prof_req  => l_name_prof_req,
                                                o_error          => o_error)
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_error;
        END IF;
    
        g_error := 'GET POSITIONING';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT pk_api_complications.get_positioning(i_lang        => i_lang,
                                                    i_prof        => i_prof,
                                                    i_patient     => i_patient,
                                                    i_episode     => i_episode,
                                                    i_type        => g_flg_cfg_typ_assoc_task,
                                                    o_positioning => l_tasks,
                                                    o_error       => o_error)
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_error;
        END IF;
    
        g_error := 'MERGE TASKS 7';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT pk_api_complications.merge_tasks(i_lang           => i_lang,
                                                i_prof           => i_prof,
                                                i_tasks          => l_tasks,
                                                i_task           => get_axe_typ_at_pos(i_lang, i_prof),
                                                i_type_tasks     => l_type_tasks,
                                                i_id_task        => l_id_task,
                                                i_desc_task      => l_desc_task,
                                                i_id_epis        => l_id_episode,
                                                i_flg_type       => l_flg_type,
                                                i_flg_context    => l_flg_context,
                                                i_dt_task        => l_dt_task,
                                                i_dt_task_send   => l_dt_task_send,
                                                i_id_prof_task   => l_id_prof_task,
                                                i_name_prof_task => l_name_prof_task,
                                                i_id_prof_req    => l_id_prof_req,
                                                i_name_prof_req  => l_name_prof_req,
                                                o_error          => o_error)
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_error;
        END IF;
    
        g_error := 'GET PROCEDURES';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT pk_api_complications.get_procedures(i_lang       => i_lang,
                                                   i_prof       => i_prof,
                                                   i_patient    => i_patient,
                                                   i_visit      => l_id_visit,
                                                   i_type       => g_flg_cfg_typ_assoc_task,
                                                   o_procedures => l_tasks,
                                                   o_error      => o_error)
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_error;
        END IF;
    
        g_error := 'MERGE TASKS 8';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT pk_api_complications.merge_tasks(i_lang           => i_lang,
                                                i_prof           => i_prof,
                                                i_tasks          => l_tasks,
                                                i_task           => get_axe_typ_at_proc(i_lang, i_prof),
                                                i_type_tasks     => l_type_tasks,
                                                i_id_task        => l_id_task,
                                                i_desc_task      => l_desc_task,
                                                i_id_epis        => l_id_episode,
                                                i_flg_type       => l_flg_type,
                                                i_flg_context    => l_flg_context,
                                                i_dt_task        => l_dt_task,
                                                i_dt_task_send   => l_dt_task_send,
                                                i_id_prof_task   => l_id_prof_task,
                                                i_name_prof_task => l_name_prof_task,
                                                i_id_prof_req    => l_id_prof_req,
                                                i_name_prof_req  => l_name_prof_req,
                                                o_error          => o_error)
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_error;
        END IF;
    
        g_error := 'GET SR PROCEDURES';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT pk_api_complications.get_surgical_procedures(i_lang       => i_lang,
                                                            i_prof       => i_prof,
                                                            i_patient    => i_patient,
                                                            i_episode    => i_episode,
                                                            i_type       => g_flg_cfg_typ_assoc_task,
                                                            o_procedures => l_tasks,
                                                            o_error      => o_error)
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_error;
        END IF;
    
        g_error := 'MERGE TASKS 9';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT pk_api_complications.merge_tasks(i_lang           => i_lang,
                                                i_prof           => i_prof,
                                                i_tasks          => l_tasks,
                                                i_task           => get_axe_typ_at_surg_proc(i_lang, i_prof),
                                                i_type_tasks     => l_type_tasks,
                                                i_id_task        => l_id_task,
                                                i_desc_task      => l_desc_task,
                                                i_id_epis        => l_id_episode,
                                                i_flg_type       => l_flg_type,
                                                i_flg_context    => l_flg_context,
                                                i_dt_task        => l_dt_task,
                                                i_dt_task_send   => l_dt_task_send,
                                                i_id_prof_task   => l_id_prof_task,
                                                i_name_prof_task => l_name_prof_task,
                                                i_id_prof_req    => l_id_prof_req,
                                                i_name_prof_req  => l_name_prof_req,
                                                o_error          => o_error)
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_error;
        END IF;
    
        g_error := 'GET CONF VARS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT (get_cfg_vars(i_lang      => i_lang,
                             i_prof      => i_prof,
                             i_cfg_type  => get_cfg_typ_assoc_task(i_lang, i_prof),
                             o_inst      => l_inst,
                             o_soft      => l_soft,
                             o_clin_serv => l_clin_serv,
                             o_error     => l_error))
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_error;
        END IF;
    
        g_error := 'OPEN O_TYPE_TASKS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        OPEN o_type_tasks FOR
            SELECT id_comp_axe, desc_comp_axe, id_sys_list, flg_type
              FROM (SELECT ca.id_comp_axe,
                           pk_translation.get_translation(i_lang, ca.code_comp_axe) ||
                           decode(pk_complication_core.is_to_show_code(i_lang, i_prof),
                                  pk_alert_constant.g_yes,
                                  decode(ca.code, NULL, NULL, ' (' || ca.code || ')'),
                                  NULL) desc_comp_axe,
                           tbl_typ.id_sys_list,
                           tbl_typ.flg_context flg_type,
                           cc.rank
                      FROM comp_axe ca
                      JOIN TABLE(pk_sys_list.tf_sys_list_values(i_lang, i_prof, pk_complication_core.g_lst_grp_axe_at_types)) tbl_typ
                        ON tbl_typ.id_sys_list = ca.id_sys_list
                      JOIN comp_config cc
                        ON cc.id_comp_axe = ca.id_comp_axe
                     WHERE ca.id_sys_list = pk_complication_core.get_axe_typ_at_und(i_lang, i_prof)
                       AND ca.flg_available = pk_alert_constant.g_yes
                       AND cc.id_sys_list = get_cfg_typ_assoc_task(i_lang, i_prof)
                       AND cc.id_institution = l_inst
                       AND cc.id_software = l_soft
                       AND cc.id_clinical_service = l_clin_serv
                    UNION ALL
                    SELECT /*+ordered use_nl(tasks ca cc)*/
                     ca.id_comp_axe,
                     pk_translation.get_translation(i_lang, ca.code_comp_axe) ||
                     decode(pk_complication_core.is_to_show_code(i_lang, i_prof),
                            pk_alert_constant.g_yes,
                            decode(ca.code, NULL, NULL, ' (' || ca.code || ')'),
                            NULL) desc_comp_axe,
                     tbl_typ.id_sys_list,
                     tbl_typ.flg_context flg_type,
                     cc.rank
                      FROM (SELECT column_value id_sys_list
                              FROM TABLE(l_type_tasks)) tasks
                      JOIN comp_axe ca
                        ON ca.id_sys_list = tasks.id_sys_list
                      JOIN TABLE(pk_sys_list.tf_sys_list_values(i_lang, i_prof, pk_complication_core.g_lst_grp_axe_at_types)) tbl_typ
                        ON tbl_typ.id_sys_list = ca.id_sys_list
                    
                      JOIN comp_config cc
                        ON cc.id_comp_axe = ca.id_comp_axe
                     WHERE ca.flg_available = pk_alert_constant.g_yes
                       AND cc.id_sys_list = get_cfg_typ_assoc_task(i_lang, i_prof)
                       AND cc.id_institution = l_inst
                       AND cc.id_software = l_soft
                       AND cc.id_clinical_service = l_clin_serv)
             ORDER BY rank, desc_comp_axe;
    
        g_error := 'GET MSG NONE';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_msg_none := pk_message.get_message(i_lang => i_lang, i_code_mess => g_msg_none);
    
        g_error := 'OPEN O_TASKS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        OPEN o_tasks FOR
            SELECT id_task,
                   desc_task,
                   id_episode,
                   desc_episode,
                   id_sys_list,
                   flg_context,
                   dt_task,
                   dt_task_send,
                   id_prof_task,
                   name_prof_task,
                   id_prof_req,
                   name_prof_req
              FROM (SELECT -1 id_task,
                           l_msg_none desc_task,
                           i_episode id_episode,
                           pk_complication_core.get_episode_description(i_lang, i_prof, i_episode) desc_episode,
                           tbl_typ.id_sys_list,
                           tbl_typ.id_sys_list flg_context,
                           pk_date_utils.date_char_tsz(i_lang, g_sysdate_tstz, i_prof.institution, i_prof.institution) dt_task,
                           pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof) dt_task_send,
                           NULL id_prof_task,
                           NULL name_prof_task,
                           NULL id_prof_req,
                           NULL name_prof_req
                      FROM comp_axe ca
                      JOIN TABLE(pk_sys_list.tf_sys_list_values(i_lang, i_prof, pk_complication_core.g_lst_grp_axe_at_types)) tbl_typ
                        ON tbl_typ.id_sys_list = ca.id_sys_list
                      JOIN comp_config cc
                        ON cc.id_comp_axe = ca.id_comp_axe
                     WHERE ca.id_sys_list = pk_complication_core.get_axe_typ_at_und(i_lang, i_prof)
                       AND ca.flg_available = pk_alert_constant.g_yes
                       AND cc.id_sys_list = get_cfg_typ_assoc_task(i_lang, i_prof)
                       AND cc.id_institution = l_inst
                       AND cc.id_software = l_soft
                       AND cc.id_clinical_service = l_clin_serv
                    UNION ALL
                    SELECT a.column_value id_task,
                           b.column_value desc_task,
                           c.column_value id_episode,
                           pk_complication_core.get_episode_description(i_lang, i_prof, c.column_value) desc_episode,
                           d.column_value id_sys_list,
                           e.column_value flg_context,
                           f.column_value dt_task,
                           g.column_value dt_task_send,
                           h.column_value id_prof_task,
                           i.column_value name_prof_task,
                           j.column_value id_prof_req,
                           k.column_value name_prof_req
                      FROM (SELECT column_value, rownum num
                              FROM TABLE(l_id_task)) a,
                           (SELECT column_value, rownum num
                              FROM TABLE(l_desc_task)) b,
                           (SELECT column_value, rownum num
                              FROM TABLE(l_id_episode)) c,
                           (SELECT column_value, rownum num
                              FROM TABLE(l_flg_type)) d,
                           (SELECT column_value, rownum num
                              FROM TABLE(l_flg_context)) e,
                           (SELECT column_value, rownum num
                              FROM TABLE(l_dt_task)) f,
                           (SELECT column_value, rownum num
                              FROM TABLE(l_dt_task_send)) g,
                           (SELECT column_value, rownum num
                              FROM TABLE(l_id_prof_task)) h,
                           (SELECT column_value, rownum num
                              FROM TABLE(l_name_prof_task)) i,
                           (SELECT column_value, rownum num
                              FROM TABLE(l_id_prof_req)) j,
                           (SELECT column_value, rownum num
                              FROM TABLE(l_name_prof_req)) k
                     WHERE a.num = b.num
                       AND b.num = c.num
                       AND c.num = d.num
                       AND d.num = e.num
                       AND e.num = f.num
                       AND f.num = g.num
                       AND g.num = h.num
                       AND h.num = i.num
                       AND i.num = j.num
                       AND j.num = k.num) t
             ORDER BY decode(t.id_task, -1, 1, 2), t.id_sys_list, t.desc_task;
    
        RETURN TRUE;
    EXCEPTION
        WHEN e_cfg_vars_not_defined THEN
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => l_error.ora_sqlcode,
                                              i_sqlerrm     => l_error.ora_sqlerrm,
                                              i_message     => l_error.err_desc,
                                              i_owner       => g_owner,
                                              i_package     => g_package,
                                              i_function    => l_func_name,
                                              i_action_type => 'U',
                                              i_action_msg  => l_error.err_action,
                                              o_error       => o_error);
            pk_types.open_my_cursor(o_type_tasks);
            pk_types.open_my_cursor(o_tasks);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_type_tasks);
            pk_types.open_my_cursor(o_tasks);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_assoc_task_list;

    /********************************************************************************************
    * Gets the type of treatments to associate with the complication
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   o_treat                     Types of treatment
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  José Silva
    * @version v2.6
    * @since   04-01-2010
    ********************************************************************************************/
    FUNCTION get_treat_perf_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_treat OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_TREAT_PERF_LIST';
        e_error EXCEPTION;
    
        l_inst      comp_config.id_institution%TYPE;
        l_soft      comp_config.id_software%TYPE;
        l_clin_serv comp_config.id_clinical_service%TYPE;
        l_error     t_error_out;
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'GET CONF VARS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT (get_cfg_vars(i_lang      => i_lang,
                             i_prof      => i_prof,
                             i_cfg_type  => get_cfg_typ_treat_perf(i_lang, i_prof),
                             o_inst      => l_inst,
                             o_soft      => l_soft,
                             o_clin_serv => l_clin_serv,
                             o_error     => l_error))
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_error;
        END IF;
    
        g_error := 'OPEN O_TASKS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        OPEN o_treat FOR
            SELECT t.id_comp_axe, t.desc_comp_axe, t.flg_type, t.id_sys_list, t.rank
              FROM (SELECT ca.id_comp_axe,
                           pk_translation.get_translation(i_lang, ca.code_comp_axe) ||
                           decode(pk_complication_core.is_to_show_code(i_lang, i_prof),
                                  pk_alert_constant.g_yes,
                                  decode(ca.code, NULL, NULL, ' (' || ca.code || ')'),
                                  NULL) desc_comp_axe,
                           tbl_typ.flg_context flg_type,
                           tbl_typ.id_sys_list,
                           cc.rank
                      FROM comp_axe ca
                      JOIN comp_config cc
                        ON cc.id_comp_axe = ca.id_comp_axe
                      JOIN TABLE(pk_sys_list.tf_sys_list_values(i_lang, i_prof, pk_complication_core.g_lst_grp_axe_tp_types)) tbl_typ
                        ON tbl_typ.id_sys_list = ca.id_sys_list
                     WHERE ca.flg_available = pk_alert_constant.g_yes
                       AND cc.id_sys_list = get_cfg_typ_treat_perf(i_lang, i_prof)
                       AND cc.id_institution = l_inst
                       AND cc.id_software = l_soft
                       AND cc.id_clinical_service = l_clin_serv) t
             ORDER BY t.rank, t.desc_comp_axe;
    
        RETURN TRUE;
    EXCEPTION
        WHEN e_cfg_vars_not_defined THEN
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => l_error.ora_sqlcode,
                                              i_sqlerrm     => l_error.ora_sqlerrm,
                                              i_message     => l_error.err_desc,
                                              i_owner       => g_owner,
                                              i_package     => g_package,
                                              i_function    => l_func_name,
                                              i_action_type => 'U',
                                              i_action_msg  => l_error.err_action,
                                              o_error       => o_error);
            pk_types.open_my_cursor(o_treat);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_treat);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_treat_perf_list;

    /**
    * Cancel a complication
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_complication         Epis complication id
    * @param   i_cancel_reason             Cancel reason id
    * @param   i_notes_cancel              Cancelation notes
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   06-01-2010
    */
    FUNCTION cancel_complication
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_complication IN epis_complication.id_epis_complication%TYPE,
        i_cancel_reason     IN epis_complication.id_cancel_reason%TYPE,
        i_notes_cancel      IN epis_complication.notes_cancel%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'CANCEL_COMPLICATION';
        --
        l_rows           table_varchar;
        l_flg_status     epis_complication.flg_status_comp%TYPE;
        l_epis_comp_hist epis_comp_hist.id_epis_comp_hist%TYPE;
        --
        l_action_message sys_message.desc_message%TYPE;
        l_error_code     sys_message.code_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'GET CURRENT STATUS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        SELECT ec.flg_status_comp
          INTO l_flg_status
          FROM epis_complication ec
         WHERE ec.id_epis_complication = i_epis_complication;
    
        g_error := 'VALIDATE COMP STATUS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF l_flg_status = g_comp_flg_status_i --Cancelled
        THEN
            l_error_code     := 'COMPLICATION_ERR014';
            l_error_message  := pk_message.get_message(i_lang => i_lang, i_code_mess => l_error_code);
            l_action_message := pk_message.get_message(i_lang => i_lang, i_code_mess => 'COMPLICATION_ERR015');
        
            g_error := l_func_name || ' - ' || g_error || ' - ' || l_error_code || ' - ' || l_error_message || ' - ' ||
                       l_action_message;
            pk_alertlog.log_debug(g_error);
        
            RAISE pk_complication_core.e_invalid_flg_state;
        END IF;
    
        g_error := 'UPD COMPLICATION HISTORY';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT set_epis_complication_hist(i_lang              => i_lang,
                                          i_epis_complication => i_epis_complication,
                                          o_epis_comp_hist    => l_epis_comp_hist,
                                          o_error             => o_error)
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_general_error;
        END IF;
    
        g_error := 'CANCEL COMPLICATION';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        ts_epis_complication.upd(id_epis_complication_in => i_epis_complication,
                                 id_cancel_reason_in     => i_cancel_reason,
                                 id_cancel_reason_nin    => FALSE,
                                 notes_cancel_in         => i_notes_cancel,
                                 notes_cancel_nin        => FALSE,
                                 flg_status_comp_in      => g_comp_flg_status_i,
                                 dt_epis_complication_in => g_sysdate_tstz,
                                 id_prof_create_in       => i_prof.id,
                                 id_prof_create_nin      => FALSE,
                                 rows_out                => l_rows);
    
        g_error := 'VALIDATE UPD ROW';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF (l_rows.count != 1)
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_general_error;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN pk_complication_core.e_invalid_flg_state THEN
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => l_error_code,
                                              i_sqlerrm     => l_error_message,
                                              i_message     => g_error,
                                              i_owner       => g_owner,
                                              i_package     => g_package,
                                              i_function    => l_func_name,
                                              i_action_type => 'U',
                                              i_action_msg  => l_action_message,
                                              o_error       => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END cancel_complication;

    /**
    * Cancel a complication request
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_complication         Epis complication id
    * @param   i_cancel_reason             Cancel reason id
    * @param   i_notes_cancel              Cancelation notes
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   06-01-2010
    */
    FUNCTION cancel_request
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_complication IN epis_complication.id_epis_complication%TYPE,
        i_cancel_reason     IN epis_complication.id_cancel_reason%TYPE,
        i_notes_cancel      IN epis_complication.notes_cancel%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'CANCEL_REQUEST';
        --
        l_rows           table_varchar;
        l_flg_status     epis_complication.flg_status_req%TYPE;
        l_epis_comp_hist epis_comp_hist.id_epis_comp_hist%TYPE;
        --
        l_action_message sys_message.desc_message%TYPE;
        l_error_code     sys_message.code_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'GET CURRENT STATUS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        SELECT ec.flg_status_req
          INTO l_flg_status
          FROM epis_complication ec
         WHERE ec.id_epis_complication = i_epis_complication;
    
        g_error := 'VALIDATE REQ STATUS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF l_flg_status = g_req_flg_status_c --Cancelled
        THEN
            l_error_code     := 'COMPLICATION_ERR014';
            l_error_message  := pk_message.get_message(i_lang => i_lang, i_code_mess => l_error_code);
            l_action_message := pk_message.get_message(i_lang => i_lang, i_code_mess => 'COMPLICATION_ERR016');
        
            g_error := l_func_name || ' - ' || g_error || ' - ' || l_error_code || ' - ' || l_error_message || ' - ' ||
                       l_action_message;
            pk_alertlog.log_debug(g_error);
        
            RAISE pk_complication_core.e_invalid_flg_state;
        ELSIF l_flg_status = g_req_flg_status_i --Rejected
        THEN
        
            l_error_code     := 'COMPLICATION_ERR014';
            l_error_message  := pk_message.get_message(i_lang => i_lang, i_code_mess => l_error_code);
            l_action_message := pk_message.get_message(i_lang => i_lang, i_code_mess => 'COMPLICATION_ERR017');
        
            g_error := l_func_name || ' - ' || g_error || ' - ' || l_error_code || ' - ' || l_error_message || ' - ' ||
                       l_action_message;
            pk_alertlog.log_debug(g_error);
        
            RAISE pk_complication_core.e_invalid_flg_state;
        ELSIF l_flg_status = g_req_flg_status_a --Accepted
        THEN
        
            l_error_code     := 'COMPLICATION_ERR014';
            l_error_message  := pk_message.get_message(i_lang => i_lang, i_code_mess => l_error_code);
            l_action_message := pk_message.get_message(i_lang => i_lang, i_code_mess => 'COMPLICATION_ERR018');
        
            g_error := l_func_name || ' - ' || g_error || ' - ' || l_error_code || ' - ' || l_error_message || ' - ' ||
                       l_action_message;
            pk_alertlog.log_debug(g_error);
        
            RAISE pk_complication_core.e_invalid_flg_state;
        END IF;
    
        g_error := 'UPD REQUEST HISTORY';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT set_epis_complication_hist(i_lang              => i_lang,
                                          i_epis_complication => i_epis_complication,
                                          o_epis_comp_hist    => l_epis_comp_hist,
                                          o_error             => o_error)
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_general_error;
        END IF;
    
        g_error := 'CANCEL REQUEST';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        ts_epis_complication.upd(id_epis_complication_in => i_epis_complication,
                                 id_cancel_reason_in     => i_cancel_reason,
                                 id_cancel_reason_nin    => FALSE,
                                 notes_cancel_in         => i_notes_cancel,
                                 notes_cancel_nin        => FALSE,
                                 flg_status_req_in       => g_req_flg_status_c,
                                 dt_epis_complication_in => g_sysdate_tstz,
                                 id_prof_create_in       => i_prof.id,
                                 id_prof_create_nin      => FALSE,
                                 rows_out                => l_rows);
    
        g_error := 'VALIDATE UPD ROW';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF (l_rows.count != 1)
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_general_error;
        END IF;
    
        g_error := 'DELETE SYS_ALERT';
        IF NOT pk_alerts.delete_sys_alert_event(i_lang         => i_lang,
                                                i_prof         => i_prof,
                                                i_id_sys_alert => g_sys_alert,
                                                i_id_record    => i_epis_complication,
                                                o_error        => o_error)
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_general_error;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN pk_complication_core.e_invalid_flg_state THEN
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => l_error_code,
                                              i_sqlerrm     => l_error_message,
                                              i_message     => g_error,
                                              i_owner       => g_owner,
                                              i_package     => g_package,
                                              i_function    => l_func_name,
                                              i_action_type => 'U',
                                              i_action_msg  => l_action_message,
                                              o_error       => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END cancel_request;

    /**
    * Reject a complication request
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_complication         Epis complication id
    * @param   i_reject_reason             Reject reason id
    * @param   i_notes_reject              Reject notes
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   06-01-2010
    */
    FUNCTION set_reject_request
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_complication IN epis_complication.id_epis_complication%TYPE,
        i_reject_reason     IN epis_complication.id_reject_reason%TYPE,
        i_notes_reject      IN epis_complication.notes_rejected%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'SET_REJECT_REQUEST';
        --
        l_rows           table_varchar;
        l_flg_status     epis_complication.flg_status_req%TYPE;
        l_epis_comp_hist epis_comp_hist.id_epis_comp_hist%TYPE;
        --
        l_action_message sys_message.desc_message%TYPE;
        l_error_code     sys_message.code_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'GET CURRENT STATUS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        SELECT ec.flg_status_req
          INTO l_flg_status
          FROM epis_complication ec
         WHERE ec.id_epis_complication = i_epis_complication;
    
        g_error := 'VALIDATE REQ STATUS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF l_flg_status = g_req_flg_status_c --Cancelled
        THEN
            l_error_code     := 'COMPLICATION_ERR019';
            l_error_message  := pk_message.get_message(i_lang => i_lang, i_code_mess => l_error_code);
            l_action_message := pk_message.get_message(i_lang => i_lang, i_code_mess => 'COMPLICATION_ERR016');
        
            g_error := l_func_name || ' - ' || g_error || ' - ' || l_error_code || ' - ' || l_error_message || ' - ' ||
                       l_action_message;
            pk_alertlog.log_debug(g_error);
        
            RAISE pk_complication_core.e_invalid_flg_state;
        ELSIF l_flg_status = g_req_flg_status_i --Rejected
        THEN
            l_error_code     := 'COMPLICATION_ERR019';
            l_error_message  := pk_message.get_message(i_lang => i_lang, i_code_mess => l_error_code);
            l_action_message := pk_message.get_message(i_lang => i_lang, i_code_mess => 'COMPLICATION_ERR017');
        
            g_error := l_func_name || ' - ' || g_error || ' - ' || l_error_code || ' - ' || l_error_message || ' - ' ||
                       l_action_message;
            pk_alertlog.log_debug(g_error);
        
            RAISE pk_complication_core.e_invalid_flg_state;
        ELSIF l_flg_status = g_req_flg_status_a --Accepted
        THEN
            l_error_code     := 'COMPLICATION_ERR019';
            l_error_message  := pk_message.get_message(i_lang => i_lang, i_code_mess => l_error_code);
            l_action_message := pk_message.get_message(i_lang => i_lang, i_code_mess => 'COMPLICATION_ERR018');
        
            g_error := l_func_name || ' - ' || g_error || ' - ' || l_error_code || ' - ' || l_error_message || ' - ' ||
                       l_action_message;
            pk_alertlog.log_debug(g_error);
        
            RAISE pk_complication_core.e_invalid_flg_state;
        END IF;
    
        g_error := 'UPD REQUEST HISTORY';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT set_epis_complication_hist(i_lang              => i_lang,
                                          i_epis_complication => i_epis_complication,
                                          o_epis_comp_hist    => l_epis_comp_hist,
                                          o_error             => o_error)
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_general_error;
        END IF;
    
        g_error := 'REJECT REQUEST';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        ts_epis_complication.upd(id_epis_complication_in => i_epis_complication,
                                 id_reject_reason_in     => i_reject_reason,
                                 id_reject_reason_nin    => FALSE,
                                 notes_rejected_in       => i_notes_reject,
                                 notes_rejected_nin      => FALSE,
                                 flg_status_req_in       => g_req_flg_status_i,
                                 dt_epis_complication_in => g_sysdate_tstz,
                                 id_prof_create_in       => i_prof.id,
                                 id_prof_create_nin      => FALSE,
                                 rows_out                => l_rows);
    
        g_error := 'VALIDATE UPD ROW';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF (l_rows.count != 1)
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_general_error;
        END IF;
    
        g_error := 'DELETE SYS_ALERT';
        IF NOT pk_alerts.delete_sys_alert_event(i_lang         => i_lang,
                                                i_prof         => i_prof,
                                                i_id_sys_alert => g_sys_alert,
                                                i_id_record    => i_epis_complication,
                                                o_error        => o_error)
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_general_error;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN pk_complication_core.e_invalid_flg_state THEN
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => l_error_code,
                                              i_sqlerrm     => l_error_message,
                                              i_message     => g_error,
                                              i_owner       => g_owner,
                                              i_package     => g_package,
                                              i_function    => l_func_name,
                                              i_action_type => 'U',
                                              i_action_msg  => l_action_message,
                                              o_error       => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_reject_request;

    /**
    * Accept the request and insert complication data
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_cols                      Columns names
    * @param   i_vals                      Columns values
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   07-01-2010
    */
    FUNCTION set_accept_request
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_cols  IN table_varchar,
        i_vals  IN table_varchar,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'SET_ACCEPT_REQUEST';
        --
        l_epis_complication epis_complication.id_epis_complication%TYPE;
        l_epis_comp_hist    epis_comp_hist.id_epis_comp_hist%TYPE;
        l_epis_comp_detail  table_number;
        l_epis_comp_prof    table_number;
        l_rows              table_varchar;
        l_flg_status        epis_complication.flg_status_req%TYPE;
        l_index             NUMBER;
        l_cols              table_varchar;
        l_vals              table_varchar;
        --
        l_action_message sys_message.desc_message%TYPE;
        l_error_code     sys_message.code_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'GET ID_EPIS_COMPLICATION';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_epis_complication := get_num_value(i_cols, i_vals, g_col_name_id_epis_comp);
    
        g_error := 'GET CURRENT STATUS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        SELECT ec.flg_status_req
          INTO l_flg_status
          FROM epis_complication ec
         WHERE ec.id_epis_complication = l_epis_complication;
    
        g_error := 'VALIDATE REQ STATUS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF l_flg_status = g_req_flg_status_c --Cancelled
        THEN
            l_error_code     := 'COMPLICATION_ERR020';
            l_error_message  := pk_message.get_message(i_lang => i_lang, i_code_mess => l_error_code);
            l_action_message := pk_message.get_message(i_lang => i_lang, i_code_mess => 'COMPLICATION_ERR016');
        
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error || ' - ' || l_error_code || ' - ' || l_error_message ||
                                  ' - ' || l_action_message);
        
            RAISE pk_complication_core.e_invalid_flg_state;
        ELSIF l_flg_status = g_req_flg_status_i --Rejected
        THEN
        
            l_error_code     := 'COMPLICATION_ERR020';
            l_error_message  := pk_message.get_message(i_lang => i_lang, i_code_mess => l_error_code);
            l_action_message := pk_message.get_message(i_lang => i_lang, i_code_mess => 'COMPLICATION_ERR017');
        
            g_error := l_func_name || ' - ' || g_error || ' - ' || l_error_code || ' - ' || l_error_message || ' - ' ||
                       l_action_message;
            pk_alertlog.log_debug(g_error);
        
            RAISE pk_complication_core.e_invalid_flg_state;
        ELSIF l_flg_status = g_req_flg_status_a --Accepted
        THEN
        
            l_error_code     := 'COMPLICATION_ERR020';
            l_error_message  := pk_message.get_message(i_lang => i_lang, i_code_mess => l_error_code);
            l_action_message := pk_message.get_message(i_lang => i_lang, i_code_mess => 'COMPLICATION_ERR018');
        
            g_error := l_func_name || ' - ' || g_error || ' - ' || l_error_code || ' - ' || l_error_message || ' - ' ||
                       l_action_message;
            pk_alertlog.log_debug(g_error);
        
            RAISE pk_complication_core.e_invalid_flg_state;
        END IF;
    
        g_error := 'SEND REQUEST TO HISTORY';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT set_epis_complication_hist(i_lang              => i_lang,
                                          i_epis_complication => l_epis_complication,
                                          o_epis_comp_hist    => l_epis_comp_hist,
                                          o_error             => o_error)
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_general_error;
        END IF;
    
        g_error := 'ACCEPT REQUEST UPD';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_rows := table_varchar();
        ts_epis_complication.upd(id_epis_complication_in  => l_epis_complication,
                                 flg_status_req_in        => g_req_flg_status_a,
                                 notes_req_in             => get_str_value(i_cols, i_vals, g_col_name_notes_req),
                                 notes_req_nin            => FALSE,
                                 dt_epis_complication_in  => g_sysdate_tstz,
                                 dt_epis_complication_nin => FALSE,
                                 id_prof_create_in        => i_prof.id,
                                 id_prof_create_nin       => FALSE,
                                 rows_out                 => l_rows);
    
        g_error := 'REMOVE NOTES_REQ';
        l_cols  := i_cols;
        l_vals  := i_vals;
        l_index := get_col_index(l_cols, g_col_name_notes_req);
        IF l_index != -1
        THEN
            l_cols.delete(l_index);
            l_vals.delete(l_index);
        END IF;
    
        g_error := 'VALIDATE ACCEPT UPD ROW';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF (l_rows.count != 1)
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_general_error;
        END IF;
    
        g_error := 'SET COMPLICATION';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT pk_complication_core.set_complication(i_lang              => i_lang,
                                                     i_prof              => i_prof,
                                                     i_cols              => l_cols,
                                                     i_vals              => l_vals,
                                                     i_is_ins            => FALSE,
                                                     o_epis_complication => l_epis_complication,
                                                     o_epis_comp_detail  => l_epis_comp_detail,
                                                     o_epis_comp_prof    => l_epis_comp_prof,
                                                     o_error             => o_error)
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_general_error;
        END IF;
    
        g_error := 'DELETE SYS_ALERT';
        IF NOT pk_alerts.delete_sys_alert_event(i_lang         => i_lang,
                                                i_prof         => i_prof,
                                                i_id_sys_alert => g_sys_alert,
                                                i_id_record    => l_epis_complication,
                                                o_error        => o_error)
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_general_error;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN pk_complication_core.e_invalid_flg_state THEN
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => l_error_code,
                                              i_sqlerrm     => l_error_message,
                                              i_message     => g_error,
                                              i_owner       => g_owner,
                                              i_package     => g_package,
                                              i_function    => l_func_name,
                                              i_action_type => 'U',
                                              i_action_msg  => l_action_message,
                                              o_error       => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_accept_request;

    /**
    * Gets discharge confirmation message
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_episode                   Episode id
    * @param   o_show                      Y - Confirmation message is to be shown; Otherwise N
    * @param   o_title                     Confirmation title
    * @param   o_quest                     Confirmation question
    * @param   o_msg                       Confirmation message
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   25-02-2010
    */
    FUNCTION get_disch_conf_msg
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_show    OUT VARCHAR2,
        o_title   OUT VARCHAR2,
        o_quest   OUT VARCHAR2,
        o_msg     OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_DISCH_CONF_MSG';
        --
        l_cfg_show_disch_msg sys_config.id_sys_config%TYPE := 'EPIS_COMP_SHOW_DISCH_MSG';
        l_msg_title          sys_message.code_message%TYPE := 'COMPLICATION_MSG053';
        l_msg_quest          sys_message.code_message%TYPE := 'COMPLICATION_MSG054';
        l_msg_body           sys_message.code_message%TYPE := 'COMPLICATION_MSG055';
        l_show_msg           sys_config.value%TYPE;
        l_comp_num           PLS_INTEGER;
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'GET EPIS_COMP_SHOW_DISCH_MSG';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_show_msg := pk_sysconfig.get_config(i_code_cf => l_cfg_show_disch_msg, i_prof => i_prof);
    
        IF l_show_msg = pk_alert_constant.g_yes
        THEN
            g_error := 'GET NUMBER OF ACTIVE COMPLICATIONS';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            SELECT COUNT(*)
              INTO l_comp_num
              FROM epis_complication ec
             WHERE ec.id_episode = i_episode
               AND ec.id_complication IS NOT NULL
               AND ec.flg_status_comp IN (g_comp_flg_status_u, g_comp_flg_status_c);
        
            IF l_comp_num > 0
            THEN
                o_show := pk_alert_constant.g_yes;
            
                o_title := pk_message.get_message(i_lang => i_lang, i_code_mess => l_msg_title);
                o_quest := pk_message.get_message(i_lang => i_lang, i_code_mess => l_msg_quest);
                o_msg   := REPLACE(pk_message.get_message(i_lang => i_lang, i_code_mess => l_msg_body),
                                   '@1',
                                   to_char(l_comp_num));
            ELSE
                o_show := pk_alert_constant.g_no;
            END IF;
        ELSE
            o_show := pk_alert_constant.g_no;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_disch_conf_msg;

    /**
    * Gets the clinical services list to which the current professional is allocated
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   o_clin_serv                 Clinical services list
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   01-03-2010
    */
    FUNCTION get_prof_clin_serv_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_clin_serv OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_PROF_CLIN_SERV_LIST';
        --
        l_prof_clin_serv_id t_table_prof_clin_serv;
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'GET PROF_CLIN_SERV_TABLE';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_prof_clin_serv_id := get_prof_clin_serv_id(i_lang, i_prof);
    
        g_error := 'GET RETURN DATA';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        OPEN o_clin_serv FOR
            SELECT t.id_clinical_service, t.desc_clin_serv, t.flg_default, t.rank
              FROM TABLE(l_prof_clin_serv_id) t;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_clin_serv);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_prof_clin_serv_list;

    /**
    * Get domain values
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_code_dom                  Element domain
    * @param   i_dep_clin_serv             Dep_clin_serv ID                                                              
    * @param   o_data                      Domain values list
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   18-03-2010
    */
    FUNCTION get_domain_values
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_code_dom      IN sys_domain.code_domain%TYPE,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_data          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_DOMAIN_VALUES';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'CALL TO pk_sysdomain.get_values_domain_pipelined';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        OPEN o_data FOR
            SELECT t.desc_val, t.val, t.img_name, t.rank
              FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang, i_prof, i_code_dom, i_dep_clin_serv)) t;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_data);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_domain_values;

    /********************************************************************************************
    * Function that updates the id_episode
    *
    * @param i_lang          Language ID
    * @param i_prof          Professional
    * @param i_episode       Definitive episode ID
    * @param i_episode_temp  Temporary episode ID
    * @param o_error         Error ocurred
    *
    * @return                False if an error ocurred and True if not
    *
    * @author                Alexandre Santos
    * @version               2.6
    * @since                 21-04-2010
    ********************************************************************************************/
    FUNCTION match_complications
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_episode_temp IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'MATCH_COMPLICATIONS';
        --
        l_rows_aux table_varchar;
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'UPDATE ID_EPISODE OF EPIS_COMP_HIST';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        ts_epis_comp_hist.upd(id_episode_in  => i_episode,
                              id_episode_nin => FALSE,
                              where_in       => 'id_episode = ' || i_episode_temp,
                              rows_out       => l_rows_aux);
    
        g_error := 'UPDATE ID_EPISODE_ORIGIN OF EPIS_COMP_HIST';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        ts_epis_comp_hist.upd(id_episode_origin_in  => i_episode,
                              id_episode_origin_nin => FALSE,
                              where_in              => 'id_episode_origin = ' || i_episode_temp,
                              rows_out              => l_rows_aux);
    
        g_error := 'UPDATE ID_EPISODE OF EPIS_COMPLICATION';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        ts_epis_complication.upd(id_episode_in  => i_episode,
                                 id_episode_nin => FALSE,
                                 where_in       => 'id_episode = ' || i_episode_temp,
                                 rows_out       => l_rows_aux);
    
        g_error := 'UPDATE ID_EPISODE_ORIGIN OF EPIS_COMPLICATION';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        ts_epis_complication.upd(id_episode_origin_in  => i_episode,
                                 id_episode_origin_nin => FALSE,
                                 where_in              => 'id_episode_origin = ' || i_episode_temp,
                                 rows_out              => l_rows_aux);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END match_complications;

    /********************************************************************************************
    * Gets professional that created the request/complication
    *
    * @param i_lang          Language ID
    * @param i_prof          Professional
    * @param i_epis_comp     Episode complication ID
    * @param i_type          'R' - Request; 'C' - Complication
    *
    * @return                Table of epis_comp_prof_create
    *
    * @author                Alexandre Santos
    * @version               2.6
    * @since                 06-05-2010
    ********************************************************************************************/
    FUNCTION tf_epis_comp_prof_create
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_epis_comp IN epis_complication.id_epis_complication%TYPE,
        i_type      IN VARCHAR2
    ) RETURN t_table_epis_comp_prof_create
        PIPELINED IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'TF_EPIS_COMP_PROF_CREATE';
        --
        l_count PLS_INTEGER := 0;
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        --Get list of values of the list group
        g_error := 'FILL EPIS_COMP_PROF_CREATE TABLE';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        FOR rec IN (SELECT t.id_prof_create,
                           pk_complication_core.get_prof_name(i_lang, i_prof, t.id_prof_create) prof_name,
                           t.id_prof_clin_serv,
                           pk_translation.get_translation(i_lang, cs_ori.code_clinical_service) desc_clin_serv,
                           t.dt_epis_complication
                      FROM ( -- 1 - Exists only one record in epis_complication and is a request
                            SELECT ec.id_prof_create, ec.id_prof_clin_serv, ec.dt_epis_complication
                              FROM epis_complication ec
                             WHERE ec.id_epis_complication = i_epis_comp
                               AND i_type = g_epis_comp_typ_r
                               AND ec.flg_status_comp IS NULL
                               AND NOT EXISTS (SELECT 1
                                      FROM epis_comp_hist ech
                                     WHERE ech.id_epis_complication = i_epis_comp)
                            UNION
                            -- 2 - Is a request and we want the first record from hist
                            SELECT aux.id_prof_create, aux.id_prof_clin_serv, aux.dt_epis_complication
                              FROM (SELECT ech.id_prof_create,
                                            ech.id_prof_clin_serv,
                                            ech.dt_epis_complication,
                                            row_number() over(ORDER BY ech.dt_epis_complication) line_number
                                       FROM epis_comp_hist ech
                                      WHERE ech.id_epis_complication = i_epis_comp
                                        AND i_type = g_epis_comp_typ_r
                                        AND ech.flg_status_comp IS NULL) aux
                             WHERE aux.line_number = 1
                            UNION
                            -- 3 - Exists only one record in epis_complication and is a complication
                            SELECT ec.id_prof_create, ec.id_prof_clin_serv, ec.dt_epis_complication
                              FROM epis_complication ec
                             WHERE ec.id_epis_complication = i_epis_comp
                               AND i_type = g_epis_comp_typ_c
                               AND ec.flg_status_comp IS NOT NULL
                               AND NOT EXISTS (SELECT 1
                                      FROM epis_comp_hist ech
                                     WHERE ech.id_epis_complication = i_epis_comp
                                       AND ech.flg_status_comp IS NOT NULL)
                            UNION
                            -- 4 - Is a complication and we want the first record from hist
                            SELECT aux.id_prof_create, aux.id_prof_clin_serv, aux.dt_epis_complication
                              FROM (SELECT ech.id_prof_create,
                                            ech.id_prof_clin_serv,
                                            ech.dt_epis_complication,
                                            row_number() over(ORDER BY ech.dt_epis_complication) line_number
                                       FROM epis_comp_hist ech
                                      WHERE ech.id_epis_complication = i_epis_comp
                                        AND i_type = g_epis_comp_typ_c
                                        AND ech.flg_status_comp IS NOT NULL) aux
                             WHERE aux.line_number = 1) t
                      JOIN clinical_service cs_ori
                        ON cs_ori.id_clinical_service = t.id_prof_clin_serv)
        LOOP
            l_count := l_count + 1;
            PIPE ROW(t_rec_epis_comp_prof_create(id_epis_complication => i_epis_comp,
                                                 id_professional      => rec.id_prof_create,
                                                 prof_name            => rec.prof_name,
                                                 id_prof_clin_serv    => rec.id_prof_clin_serv,
                                                 desc_clin_serv       => rec.desc_clin_serv,
                                                 dt_create            => rec.dt_epis_complication));
        END LOOP;
    
        IF (l_count = 0)
        THEN
            PIPE ROW(t_rec_epis_comp_prof_create(id_epis_complication => NULL,
                                                 id_professional      => NULL,
                                                 prof_name            => NULL,
                                                 id_prof_clin_serv    => NULL,
                                                 desc_clin_serv       => NULL,
                                                 dt_create            => NULL));
        END IF;
    
        RETURN;
    END tf_epis_comp_prof_create;
BEGIN
    -- Initialization
    g_sysdate_tstz          := current_timestamp;
    g_proc_epis_comp_detail := table_number();

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_complication_core;
/
