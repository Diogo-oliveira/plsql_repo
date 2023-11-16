/*-- Last Change Revision: $Rev: 2055614 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2023-02-22 15:26:38 +0000 (qua, 22 fev 2023) $*/

CREATE OR REPLACE PACKAGE pk_prog_notes_constants IS

    -- Author  : SOFIA.MENDES
    -- Created : 27-01-2011 08:10:43
    -- Purpose : Define the Progress Notes constants

    -- Public constant declarations
    --note statuses
    g_epis_pn_flg_status_d    CONSTANT epis_pn.flg_status%TYPE := 'D'; --Draft
    g_epis_pn_flg_status_s    CONSTANT epis_pn.flg_status%TYPE := 'S'; --Signed-off
    g_epis_pn_flg_status_m    CONSTANT epis_pn.flg_status%TYPE := 'M'; -- Migrated
    g_epis_pn_flg_status_f    CONSTANT epis_pn.flg_status%TYPE := 'F'; --Finalized
    g_epis_pn_flg_status_c    CONSTANT epis_pn.flg_status%TYPE := 'C'; --Cancelled
    g_epis_pn_flg_status_t    CONSTANT epis_pn.flg_status%TYPE := 'T'; --Temporary save
    g_epis_pn_flg_for_review  CONSTANT epis_pn.flg_status%TYPE := 'V'; -- submit for review
    g_epis_pn_flg_submited    CONSTANT epis_pn.flg_status%TYPE := 'B'; -- submited
    g_epis_pn_flg_draftsubmit CONSTANT epis_pn.flg_status%TYPE := 'W'; -- draft4submited

    --note detail statuses
    g_epis_pn_det_flg_status_a CONSTANT epis_pn_det.flg_status%TYPE := 'A'; --Active
    g_epis_pn_det_flg_status_r CONSTANT epis_pn_det.flg_status%TYPE := 'R'; --Removed   
    g_epis_pn_det_sug_add_s    CONSTANT epis_pn_det.flg_status%TYPE := 'S'; --Active auto-suggested
    g_epis_pn_det_sug_rem_i    CONSTANT epis_pn_det.flg_status%TYPE := 'I'; --Removed auto-suggested
    g_epis_pn_det_aut_rem_z    CONSTANT epis_pn_det.flg_status%TYPE := 'Z'; --Automatically removed

    g_review_action        CONSTANT VARCHAR2(1 CHAR) := 'X';
    g_copy_template_action CONSTANT VARCHAR2(1 CHAR) := 'C';
    g_remove_action        CONSTANT VARCHAR2(1 CHAR) := 'R';

    --addendum status
    g_addendum_status_d CONSTANT epis_pn.flg_status%TYPE := 'D'; --Draft
    g_addendum_status_s CONSTANT epis_pn.flg_status%TYPE := 'S'; --Signed-off
    g_addendum_status_f CONSTANT epis_pn.flg_status%TYPE := 'F'; --Finalized
    g_addendum_status_c CONSTANT epis_pn.flg_status%TYPE := 'C'; --Cancelled

    --Screens
    g_screen_hp CONSTANT VARCHAR2(2) := 'HP';
    g_screen_pn CONSTANT VARCHAR2(2) := 'PN';

    --
    g_selected CONSTANT VARCHAR2(1 CHAR) := 'A';
    g_active   CONSTANT VARCHAR2(1 CHAR) := 'A';

    -- soap note type identifiers
    -- used for documentation templates configuration and search
    g_dtc_note_amb       CONSTANT doc_template_context.id_context_2%TYPE := 1; -- ambulatory progress note
    g_dtc_note_h_and_p   CONSTANT doc_template_context.id_context_2%TYPE := 2; -- history and physical note
    g_dtc_note_progress  CONSTANT doc_template_context.id_context_2%TYPE := 3; -- progress note
    g_dtc_note_prolonged CONSTANT doc_template_context.id_context_2%TYPE := 4; -- prolonged service note
    g_dtc_note_crit_care CONSTANT doc_template_context.id_context_2%TYPE := 5; -- critical care note
    g_dtc_note_consult   CONSTANT doc_template_context.id_context_2%TYPE := 6; -- consult note

    -- data importability types
    g_import_not       CONSTANT pn_dblock_mkt.flg_import%TYPE := 'N'; -- not importable
    g_import_text      CONSTANT pn_dblock_mkt.flg_import%TYPE := 'T'; -- text importable
    g_import_block     CONSTANT pn_dblock_mkt.flg_import%TYPE := 'B'; -- block importable  
    g_import_exclusive CONSTANT pn_note_type_mkt.flg_import_available%TYPE := 'E'; -- exclusive

    -- data block types
    g_data_block_text         CONSTANT pn_data_block.flg_type%TYPE := 'T'; -- simple text
    g_data_block_doc          CONSTANT pn_data_block.flg_type%TYPE := 'D'; -- documentation
    g_data_block_free_text    CONSTANT pn_data_block.flg_type%TYPE := 'F'; -- free text
    g_data_block_cdate        CONSTANT pn_data_block.flg_type%TYPE := 'C'; -- current date/Date time always
    g_data_block_date_time    CONSTANT pn_data_block.flg_type%TYPE := 'P'; -- Popup that allows date insertion or date/time insertion
    g_data_block_strut        CONSTANT pn_data_block.flg_type%TYPE := 'S'; -- structure (used for parenting)
    g_dblock_strut_date       CONSTANT pn_data_block.flg_type%TYPE := 'ID'; -- import structure date
    g_dblock_strut_group      CONSTANT pn_data_block.flg_type%TYPE := 'IG'; -- import structure group
    g_dblock_strut_subgroup   CONSTANT pn_data_block.flg_type%TYPE := 'IS'; -- import structure sub group
    g_dblock_free_text_w_save CONSTANT pn_data_block.flg_type%TYPE := 'M'; -- Free text with save
    g_dblock_table            CONSTANT pn_data_block.flg_type%TYPE := 'TB';
    g_data_block_action       CONSTANT pn_data_block.flg_type%TYPE := 'A'; --Used for actions without sync area

    -- data block Areas
    g_data_block_cdate_cd      CONSTANT pn_data_block.data_area%TYPE := 'CD'; -- current date
    g_data_block_eddate_edd    CONSTANT pn_data_block.data_area%TYPE := 'EDD'; -- Expected Discharge Date
    g_data_block_arrivaldt_adt CONSTANT pn_data_block.data_area%TYPE := 'ADT'; -- Arrival Date/Time
    g_data_block_cdate_ddt     CONSTANT pn_data_block.data_area%TYPE := 'DDT'; -- DISSEASE date

    --Availability
    g_available CONSTANT VARCHAR2(1 CHAR) := 'Y';

    --progress notes status
    g_pn_draft     CONSTANT VARCHAR2(1 CHAR) := 'D';
    g_pn_signoff   CONSTANT VARCHAR2(1 CHAR) := 'S';
    g_pn_cancelled CONSTANT VARCHAR2(1 CHAR) := 'C';
    g_pn_migrated  CONSTANT VARCHAR2(1 CHAR) := 'M';
    g_pn_finished  CONSTANT VARCHAR2(1 CHAR) := 'F';

    --Sort keys
    g_order_by_asc      CONSTANT VARCHAR2(30 CHAR) := 'ASC';
    g_order_by_desc     CONSTANT VARCHAR2(30 CHAR) := 'DESC';
    g_order_by_asc_num  CONSTANT PLS_INTEGER := 1;
    g_order_by_desc_num CONSTANT PLS_INTEGER := -1;

    --
    g_open_parenthesis  CONSTANT VARCHAR2(2) := ' (';
    g_close_parenthesis CONSTANT VARCHAR2(2) := ')';
    g_colon             CONSTANT VARCHAR2(2 CHAR) := ': ';
    g_comma             CONSTANT VARCHAR2(2 CHAR) := ', ';
    g_space             CONSTANT VARCHAR2(1 CHAR) := ' ';
    g_flg_sep           CONSTANT VARCHAR2(3 CHAR) := ' - ';
    g_period            CONSTANT VARCHAR2(2 CHAR) := '. ';
    g_new_line          CONSTANT VARCHAR2(2 CHAR) := chr(10);
    g_semicolon         CONSTANT VARCHAR2(2 CHAR) := '; ';
    g_triple_colon      CONSTANT VARCHAR2(3 CHAR) := '---';

    --FLGS to identify the detail/history screens
    g_detail_screen_d CONSTANT VARCHAR2(1 CHAR) := 'D';
    g_hist_screen_h   CONSTANT VARCHAR2(1 CHAR) := 'H';

    -- type of content to be returned in the detail/history screens
    g_title_t CONSTANT VARCHAR2(1) := 'T';
    --title without new line
    g_title_tnl             CONSTANT VARCHAR2(3) := 'TNL';
    g_content_c             CONSTANT VARCHAR2(1) := 'C';
    g_signature_s           CONSTANT VARCHAR2(1) := 'S';
    g_signature_ss          CONSTANT VARCHAR2(2) := 'SS';
    g_new_content_n         CONSTANT VARCHAR2(1) := 'N';
    g_sub_title_st          CONSTANT VARCHAR2(2) := 'ST';
    g_sub_title_content_stc CONSTANT VARCHAR2(3) := 'STC';
    --arabic
    g_sub_title_arabic         CONSTANT VARCHAR2(3) := 'STA';
    g_sub_title_content_arabic CONSTANT VARCHAR2(4) := 'STCA';
    g_content_ca               CONSTANT VARCHAR2(2) := 'CA';
    --The same as STC for reports in the history: The report has a diferent indentation
    g_sub_title_content_stcr CONSTANT VARCHAR2(4) := 'STCR';
    --
    g_sub_title_content_stcra CONSTANT VARCHAR2(5) := 'STCRA';
    --red status
    g_status_str CONSTANT VARCHAR2(3) := 'STR';
    --black status
    g_status_stb CONSTANT VARCHAR2(3) := 'STB';
    --red status without new line
    g_status_strwl CONSTANT VARCHAR2(5) := 'STRWL';
    --back status without new line
    g_status_stbwl         CONSTANT VARCHAR2(5) := 'STBWL';
    g_main_title           CONSTANT VARCHAR2(2) := 'MT';
    g_new_content_2_pts_nn CONSTANT VARCHAR2(2) := 'NN';
    g_content_2_pts_cc     CONSTANT VARCHAR2(2) := 'CC';
    g_line                 CONSTANT VARCHAR2(1) := 'L';

    g_content_2_pts_cca CONSTANT VARCHAR2(3) := 'CCA';
    --a content under other content
    g_content_sc      CONSTANT VARCHAR2(2) := 'SC';
    g_new_content_nsc CONSTANT VARCHAR2(3) := 'NSC';

    --Sys_domains
    g_sd_note_flg_status CONSTANT VARCHAR2(18) := 'EPIS_PN.FLG_STATUS';
    g_sd_add_flg_status  CONSTANT VARCHAR2(27) := 'EPIS_PN_ADDENDUM.FLG_STATUS';

    --sys_configs
    g_sc_hp_num_rec_pag CONSTANT VARCHAR2(15) := 'HP_NUM_REC_PAGE';
    g_sc_pn_num_rec_pag CONSTANT VARCHAR2(15) := 'PN_NUM_REC_PAGE';

    --actions
    g_act_add_note_hp  CONSTANT VARCHAR2(8) := 'ADD_NOTE';
    g_act_add_note_pn  CONSTANT VARCHAR2(11) := 'ADD_NOTE_PN';
    g_act_add_note_ppn CONSTANT VARCHAR2(12) := 'ADD_NOTE_PPN';
    g_act_add_note_icn CONSTANT VARCHAR2(12) := 'ADD_NOTE_ICN';
    g_act_add_note_ft  CONSTANT VARCHAR2(12) := 'ADD_NOTE_FT';
    g_act_edit         CONSTANT VARCHAR2(14) := 'SP_ACTION_EDIT';

    --actions subjects
    g_act_review  CONSTANT VARCHAR2(11 CHAR) := 'REVIEW_TASK';
    g_act_remove  CONSTANT VARCHAR2(16 CHAR) := 'REMOVE_FROM_NOTE';
    g_act_comment CONSTANT VARCHAR2(12 CHAR) := 'COMMENT_TASK';

    --Scope types
    g_flg_scope_p CONSTANT VARCHAR2(1 CHAR) := 'P';
    g_flg_scope_e CONSTANT VARCHAR2(1 CHAR) := 'E';
    g_flg_scope_v CONSTANT VARCHAR2(1 CHAR) := 'V';

    --Report types
    g_report_complete_c CONSTANT VARCHAR2(1 CHAR) := 'C';
    g_report_detailed_d CONSTANT VARCHAR2(1 CHAR) := 'D';

    --Reports configs
    g_show_title_t CONSTANT VARCHAR2(1 CHAR) := 'T'; --in the complete report should be show the title (date,status, nr addendums)
    g_show_block_b CONSTANT VARCHAR2(1 CHAR) := 'B'; --in the complete report should not be show the title and should be show the date soap block
    g_show_all     CONSTANT VARCHAR2(1 CHAR) := 'A'; --shows the title and the date soap block

    g_addendum CONSTANT VARCHAR2(1) := 'A';
    g_note     CONSTANT VARCHAR2(1) := 'N';

    g_flg_type_m  CONSTANT VARCHAR2(2 CHAR) := 'M';
    g_flg_type_d  CONSTANT VARCHAR2(2 CHAR) := 'D';
    g_flg_type_md CONSTANT VARCHAR2(2 CHAR) := 'MD';

    g_yes CONSTANT VARCHAR2(1 CHAR) := 'Y';
    g_no  CONSTANT VARCHAR2(1 CHAR) := 'N';

    g_work_tab_y CONSTANT VARCHAR2(1 CHAR) := 'Y';
    g_work_tab_n CONSTANT VARCHAR2(1 CHAR) := 'N';

    --
    g_at_summ_page CONSTANT NUMBER := 34; -- Assessment tools summary page      

    --sys_messages code
    g_msg_error              CONSTANT sys_message.code_message%TYPE := 'COMMON_T006';
    g_max_addendums_reached  CONSTANT sys_message.code_message%TYPE := 'PN_M019';
    g_max_notes_reached      CONSTANT sys_message.code_message%TYPE := 'PN_M018';
    g_sm_addendum            CONSTANT sys_message.code_message%TYPE := 'PN_T007';
    g_sm_pn_comments         CONSTANT sys_message.code_message%TYPE := 'PN_T194';
    g_sm_pn_comments_new     CONSTANT sys_message.code_message%TYPE := 'PN_M048';
    g_sm_pn_comments_edit    CONSTANT sys_message.code_message%TYPE := 'PN_T195';
    g_sm_add_signoff         CONSTANT sys_message.code_message%TYPE := 'PN_M013';
    g_sm_add_canc            CONSTANT sys_message.code_message%TYPE := 'PN_M014';
    g_sm_add_new             CONSTANT sys_message.code_message%TYPE := 'PN_M020';
    g_sm_add_edit            CONSTANT sys_message.code_message%TYPE := 'PN_T018';
    g_sm_new_status          CONSTANT sys_message.code_message%TYPE := 'PN_M012';
    g_sm_new_note            CONSTANT sys_message.code_message%TYPE := 'PN_M016';
    g_sm_just_save           CONSTANT sys_message.code_message%TYPE := 'PN_M028';
    g_sm_edit_without_ch     CONSTANT sys_message.code_message%TYPE := 'PN_M029';
    g_sm_del_info            CONSTANT sys_message.code_message%TYPE := 'PN_M026';
    g_sm_status              CONSTANT sys_message.code_message%TYPE := 'PN_M011';
    g_sm_canc_reason         CONSTANT sys_message.code_message%TYPE := 'COMMON_M072';
    g_sm_canc_notes          CONSTANT sys_message.code_message%TYPE := 'COMMON_M073';
    g_sm_note                CONSTANT sys_message.code_message%TYPE := 'PN_M017';
    g_sm_addendum_m          CONSTANT sys_message.code_message%TYPE := 'PN_M010';
    g_sm_addenda             CONSTANT sys_message.code_message%TYPE := 'PN_M009';
    g_sm_notes               CONSTANT sys_message.code_message%TYPE := 'PN_T050';
    g_sm_exec_dt             CONSTANT sys_message.code_message%TYPE := 'PN_T055';
    g_sm_collect_dt          CONSTANT sys_message.code_message%TYPE := 'PN_T056';
    g_sm_requested_dt        CONSTANT sys_message.code_message%TYPE := 'PN_T059';
    g_sm_comment             CONSTANT sys_message.code_message%TYPE := 'PN_T097';
    g_sm_registered          CONSTANT sys_message.code_message%TYPE := 'PN_M039';
    g_sm_reviewed            CONSTANT sys_message.code_message%TYPE := 'PN_M040';
    g_sm_doctor_reviewed     CONSTANT sys_message.code_message%TYPE := 'PN_M056';
    g_sm_nurse_grid_title    CONSTANT sys_message.code_message%TYPE := 'PN_T117';
    g_sm_nurse_grid_subtitle CONSTANT sys_message.code_message%TYPE := 'PN_T118';
    g_sm_datetime            CONSTANT sys_message.code_message%TYPE := 'PN_T008';
    g_sm_referal_consult     CONSTANT sys_message.code_message%TYPE := 'PN_T138';
    g_sm_referal_interv      CONSTANT sys_message.code_message%TYPE := 'PN_T139';
    g_sm_referal_mfr         CONSTANT sys_message.code_message%TYPE := 'PN_T140';
    g_sm_referal_nutrition   CONSTANT sys_message.code_message%TYPE := 'PN_T141';

    --sys_configs
    g_sc_hp_show_empty_block CONSTANT sys_config.id_sys_config%TYPE := 'HP_SHOW_EMPTY_BLOCKS';
    g_sc_pn_show_empty_block CONSTANT sys_config.id_sys_config%TYPE := 'PN_SHOW_EMPTY_BLOCKS';
    g_sc_hp_max_notes        CONSTANT sys_config.id_sys_config%TYPE := 'HP_MAX_NOTES';
    g_sc_dictation_editable  CONSTANT sys_config.id_sys_config%TYPE := 'PN_DICTATION_EDITABLE';

    --sys_config suffixs
    g_scs_data_sort         CONSTANT sys_config.id_sys_config%TYPE := '_DATA_SORT';
    g_scs_num_rec_page      CONSTANT sys_config.id_sys_config%TYPE := '_NUM_REC_PAGE';
    g_scs_other_prof_edit   CONSTANT sys_config.id_sys_config%TYPE := '_ADD_ADDENDUMS_OTHER_PROF_NOTE';
    g_scs_max_draft_addenda CONSTANT sys_config.id_sys_config%TYPE := '_MAX_DRAFT_ADDENDUMS';
    g_scs_max_draft_notes   CONSTANT sys_config.id_sys_config%TYPE := '_MAX_DRAFT_NOTES';

    --actions subject suffixs
    g_acs_pagging_filter CONSTANT action.subject%TYPE := 'PN_ACTION_FILTER';

    --actions subjects    
    g_acs_add_button_add    CONSTANT action.subject%TYPE := 'PN_ACTION_ADD';
    g_acs_actions_button    CONSTANT action.subject%TYPE := 'PN_ACTIONS_NOTES';
    g_acs_actions_addendums CONSTANT action.subject%TYPE := 'PN_ACTIONS_ADDENDUMS';

    g_pn_flg_scope_area_f          CONSTANT VARCHAR2(1 CHAR) := 'F'; --FREE TEXT
    g_pn_flg_scope_area_a          CONSTANT VARCHAR2(1 CHAR) := 'A'; --area
    g_pn_flg_scope_notetype_n      CONSTANT VARCHAR2(1 CHAR) := 'N'; --note type
    g_note_type_id_amb_1           CONSTANT PLS_INTEGER := 1;
    g_flg_code_note_type_desc_d    CONSTANT VARCHAR2(1 CHAR) := 'D'; --Description
    g_flg_code_note_type_signoff_s CONSTANT VARCHAR2(1 CHAR) := 'S'; --Sign Off
    g_flg_code_note_type_cancel_d  CONSTANT VARCHAR2(1 CHAR) := 'C'; --Cancel
    g_flg_code_note_type_edit_e    CONSTANT VARCHAR2(1 CHAR) := 'E'; --Edition
    g_flg_code_note_type_add_a     CONSTANT VARCHAR2(1 CHAR) := 'A'; --Add

    g_flg_config_type_software_s  CONSTANT VARCHAR2(1 CHAR) := 'S'; --Software
    g_flg_config_type_proftempl_p CONSTANT VARCHAR2(1 CHAR) := 'P'; --Profile Template
    g_flg_config_type_category_c  CONSTANT VARCHAR2(1 CHAR) := 'C'; --Category

    --API's for Viewer
    g_flg_scope_summary_s  CONSTANT VARCHAR2(1 CHAR) := 'S'; --Summary 1.st level (last Note)
    g_flg_scope_detail_d   CONSTANT VARCHAR2(1 CHAR) := 'D'; --Detailed 2.nd level (Last Note by each Area)
    g_flg_scope_complete_c CONSTANT VARCHAR2(1 CHAR) := 'C'; --Complete 3.rd level (All Notes for Note Type selected)
    g_flg_scope_type_t     CONSTANT VARCHAR2(1 CHAR) := 'T'; --note_type

    --ID's needeed for interface's API's
    --Soap Blocks
    g_sblock_cdate_6          CONSTANT pn_soap_block.id_pn_soap_block%TYPE := 6; -- Current Date
    g_sblock_eddate_18        CONSTANT pn_soap_block.id_pn_soap_block%TYPE := 18; -- Expected Discharge Date
    g_sblock_chiefcomplaint_7 CONSTANT pn_soap_block.id_pn_soap_block%TYPE := 7; -- Chief complaint
    g_sblock_free_text_pn_17  CONSTANT pn_soap_block.id_pn_soap_block%TYPE := 17; -- Free Text Progress Note
    g_sblock_handp_33         CONSTANT pn_soap_block.id_pn_soap_block%TYPE := 33; -- History and physical    
    g_sblock_hcourse_30       CONSTANT pn_soap_block.id_pn_soap_block%TYPE := 30; -- Hospital course
    g_sblock_edcourse_35      CONSTANT pn_soap_block.id_pn_soap_block%TYPE := 35; -- Emergency Department course
    g_sblock_creport_36       CONSTANT pn_soap_block.id_pn_soap_block%TYPE := 36; -- Consultation report     
    --Data Blocks
    g_dblock_cdate_47           CONSTANT pn_data_block.id_pn_data_block%TYPE := 47; -- Current Date
    g_dblock_eddate_93          CONSTANT pn_data_block.id_pn_data_block%TYPE := 93; -- Expected Discharge Date
    g_dblock_adatetime_106      CONSTANT pn_data_block.id_pn_data_block%TYPE := 106; -- Arrival Date/Time
    g_dblock_chiefcomplaint_48  CONSTANT pn_data_block.id_pn_data_block%TYPE := 48; -- Chief complaint   
    g_dblock_free_text_pn_92    CONSTANT pn_data_block.id_pn_data_block%TYPE := 92; -- Free Text Progress Note
    g_dblock_free_text_diag_109 CONSTANT pn_data_block.id_pn_data_block%TYPE := 109; -- Free Text Diagnoses Notes
    g_dblock_free_text_plan_108 CONSTANT pn_data_block.id_pn_data_block%TYPE := 108; -- Free Text Plan Notes
    g_dblock_handp_128          CONSTANT pn_data_block.id_pn_data_block%TYPE := 128; -- History and physical
    g_dblock_vital_sign_tb_143  CONSTANT pn_data_block.id_pn_data_block%TYPE := 143; -- Vital sign table
    g_dblock_vital_sign_22      CONSTANT pn_data_block.id_pn_data_block%TYPE := 22; -- Vital sign
    g_dblock_plan_90            CONSTANT pn_data_block.id_pn_data_block%TYPE := 90; -- plan
    g_dblock_hcourse_136        CONSTANT pn_data_block.id_pn_data_block%TYPE := 136; -- Hospital course
    g_dblock_edcourse_138       CONSTANT pn_data_block.id_pn_data_block%TYPE := 138; -- Emergency department course
    g_dblock_creport_120        CONSTANT pn_data_block.id_pn_data_block%TYPE := 120; -- Consultation report 
    g_dblock_handoff_194        CONSTANT pn_data_block.id_pn_data_block%TYPE := 194; -- Responsible professional
    g_dblock_arabic_free_text   CONSTANT pn_data_block.id_pn_data_block%TYPE := 915; -- arabic free text dblock
    g_dblock_arabic_chief_compl CONSTANT pn_data_block.id_pn_data_block%TYPE := 975; -- arabic chief complaint dblock

    --H&P
    g_note_type_id_handp_2    CONSTANT pn_note_type.id_pn_note_type%TYPE := 2;
    g_note_type_id_handp_ft_8 CONSTANT pn_note_type.id_pn_note_type%TYPE := 8;
    --Free Text Progress Note
    g_note_type_id_ftn_7 CONSTANT pn_note_type.id_pn_note_type%TYPE := 7;
    --Discharge Summary
    g_note_type_id_disch_sum_12 CONSTANT pn_note_type.id_pn_note_type%TYPE := 12;
    --Discharge Summary free text
    g_note_type_id_disch_sum_ft_13 CONSTANT pn_note_type.id_pn_note_type%TYPE := 13;
    --Group notes
    g_note_type_id_group_note_31 CONSTANT pn_note_type.id_pn_note_type%TYPE := 31;
    --Progress note
    g_note_type_prog_note_3 CONSTANT pn_note_type.id_pn_note_type%TYPE := 3;
    --Progress note recheck
    g_note_type_prog_note_10 CONSTANT pn_note_type.id_pn_note_type%TYPE := 10;
    --Progress note recheck free text
    g_note_type_prog_note_ft_11 CONSTANT pn_note_type.id_pn_note_type%TYPE := 11;
    --Progress note outp
    g_note_type_prog_note_32 CONSTANT pn_note_type.id_pn_note_type%TYPE := 32;
    --Current visit
    g_note_type_current_visit_9 CONSTANT pn_note_type.id_pn_note_type%TYPE := 9;
    --Nursing Initial Assessment
    g_note_type_nur_init_assm_17 CONSTANT pn_note_type.id_pn_note_type%TYPE := 17;
    --Nursing Initial Assessment free text
    g_note_type_nia_ft_19 CONSTANT pn_note_type.id_pn_note_type%TYPE := 19;
    --Nursing Assessment
    g_note_type_nur_assm_16 CONSTANT pn_note_type.id_pn_note_type%TYPE := 16;
    --Nursing Initial Assessment AHP
    g_note_type_nur_init_assm_42 CONSTANT pn_note_type.id_pn_note_type%TYPE := 42;
    --Nursing progress notes
    g_note_type_nur_prog_note_18 CONSTANT pn_note_type.id_pn_note_type%TYPE := 18;
    --Nursing progress notes free text
    g_note_type_npn_ft_20 CONSTANT pn_note_type.id_pn_note_type%TYPE := 20;
    --Visit note - consultation report
    g_note_type_visit_note_14 CONSTANT pn_note_type.id_pn_note_type%TYPE := 14;
    --Dietary initial assessment
    g_note_type_die_init_assm_29 CONSTANT pn_note_type.id_pn_note_type%TYPE := 29;
    --Dietary initial assessment free text
    g_note_type_dia_ft_24 CONSTANT pn_note_type.id_pn_note_type%TYPE := 24;
    --Nutrition progress notes
    g_note_type_nutr_prog_note_33 CONSTANT pn_note_type.id_pn_note_type%TYPE := 33;
    --Nutrition progress notes free text
    g_note_type_dpn_ft_25 CONSTANT pn_note_type.id_pn_note_type%TYPE := 25;
    --Nutrition progress notes TEC
    g_note_type_nutr_prog_note_26 CONSTANT pn_note_type.id_pn_note_type%TYPE := 26;
    --Nutrition visit note
    g_note_type_nutr_visit_note_30 CONSTANT pn_note_type.id_pn_note_type%TYPE := 30;
    --Pharmacist notes free text
    g_note_type_pharm_note_ft_34 CONSTANT pn_note_type.id_pn_note_type%TYPE := 34;
    --Initial respiratory assessment
    g_note_type_resp_init_assm_27 CONSTANT pn_note_type.id_pn_note_type%TYPE := 27;
    --Respiratory therapy progress notes
    g_note_type_resp_prog_note_28 CONSTANT pn_note_type.id_pn_note_type%TYPE := 28;
    --Shif summary 
    g_note_type_shif_summary_51 CONSTANT pn_note_type.id_pn_note_type%TYPE := 51;
    g_note_type_shif_summary_52 CONSTANT pn_note_type.id_pn_note_type%TYPE := 52;
    g_note_type_shif_summary_53 CONSTANT pn_note_type.id_pn_note_type%TYPE := 53;
    --AIH
    g_note_type_aih_62 CONSTANT pn_note_type.id_pn_note_type%TYPE := 62;
    --Arabic Free Text inp
    g_note_type_arabic_ft CONSTANT pn_note_type.id_pn_note_type%TYPE := 115;
    --Arabic Free Text social worker
    g_note_type_arabic_ft_sw CONSTANT pn_note_type.id_pn_note_type%TYPE := 123;
    --Arabic Free Text psyc
    g_note_type_arabic_ft_psy CONSTANT pn_note_type.id_pn_note_type%TYPE := 125;
    --psychologist initial assessment
    g_note_type_psycho_ia CONSTANT pn_note_type.id_pn_note_type%TYPE := 114;
    --psychologist progress note
    g_note_type_psycho_pn CONSTANT pn_note_type.id_pn_note_type%TYPE := 120;
    --psychologist visit note
    g_note_type_psycho_vn CONSTANT pn_note_type.id_pn_note_type%TYPE := 117;
    --pychiatric assessment
    g_note_psych_assess CONSTANT pn_note_type.id_pn_note_type%TYPE := 126;
    --arabic free text note CDC vn
    g_note_type_arabic_ft_cdc_vn CONSTANT pn_note_type.id_pn_note_type%TYPE := 128;
    --arabic free text note CDC ia
    g_note_type_arabic_ft_cdc_ia CONSTANT pn_note_type.id_pn_note_type%TYPE := 129;
    --arabic free text note CDC pn
    g_note_type_arabic_ft_cdc_pn CONSTANT pn_note_type.id_pn_note_type%TYPE := 130;
    --free text note cdc ia
    g_note_type_ft_cdc_ia CONSTANT pn_note_type.id_pn_note_type%TYPE := 132;
    --free text note cdc pn
    g_note_type_ft_cdc_pn CONSTANT pn_note_type.id_pn_note_type%TYPE := 133;
    --free text note vn
    g_note_type_ft_cdc_vn CONSTANT pn_note_type.id_pn_note_type%TYPE := 131;
    --Psychiatric discharge summary
    g_note_type_psy_ds CONSTANT pn_note_type.id_pn_note_type%TYPE := 135;
    -- sbar note
    g_sbar_note CONSTANT pn_note_type.id_pn_note_type%TYPE := 136;
    -- sbar labor note 
    g_sbar_labor_note CONSTANT pn_note_type.id_pn_note_type%TYPE := 167;
    --Religious counseler arabic progress note
    g_note_type_arabic_ft_rc_pn CONSTANT pn_note_type.id_pn_note_type%TYPE := 144;
    --Religious counseler arabic visit note
    g_note_type_arabic_ft_rc_vn CONSTANT pn_note_type.id_pn_note_type%TYPE := 146;

    --Flag update
    g_flg_update_u CONSTANT VARCHAR2(1 CHAR) := 'U';

    --data blocks search types
    g_importable_dblocks_i CONSTANT VARCHAR2(1 CHAR) := 'I';
    g_auto_pop_dblocks_a   CONSTANT VARCHAR2(1 CHAR) := 'A'; --auto populated 
    --g_suggested_dblocks_s  CONSTANT VARCHAR2(1 CHAR) := 'S'; --suggested
    g_synch_dblocks_c CONSTANT VARCHAR2(1 CHAR) := 'C'; --sincronize existing info in the note
    g_synch_dblocks_r CONSTANT VARCHAR2(1 CHAR) := 'R'; --sincronize a record

    --Indicates the the data blocks belong to the note, import or both
    g_struct_type_both_b   CONSTANT pn_dblock_mkt.flg_struct_type%TYPE := 'B';
    g_struct_type_note_n   CONSTANT pn_dblock_mkt.flg_struct_type%TYPE := 'N';
    g_struct_type_import_i CONSTANT pn_dblock_mkt.flg_struct_type%TYPE := 'I';

    --task types ids
    g_task_templates               CONSTANT tl_task.id_tl_task%TYPE := 36;
    g_task_vital_signs             CONSTANT tl_task.id_tl_task%TYPE := 37;
    g_task_biometrics              CONSTANT tl_task.id_tl_task%TYPE := 122;
    g_task_allergies               CONSTANT tl_task.id_tl_task%TYPE := 38;
    g_task_habits                  CONSTANT tl_task.id_tl_task%TYPE := 39;
    g_task_dicharge_sch            CONSTANT tl_task.id_tl_task%TYPE := 40;
    g_task_ph_medical_hist         CONSTANT tl_task.id_tl_task%TYPE := 41;
    g_task_ph_free_txt             CONSTANT tl_task.id_tl_task%TYPE := 42;
    g_task_ph_templ                CONSTANT tl_task.id_tl_task%TYPE := 43;
    g_task_ph_treatments           CONSTANT tl_task.id_tl_task%TYPE := 48;
    g_task_ph_medical_other        CONSTANT tl_task.id_tl_task%TYPE := 49;
    g_task_ph_medical_diag         CONSTANT tl_task.id_tl_task%TYPE := 50;
    g_task_ph_medical_surg         CONSTANT tl_task.id_tl_task%TYPE := 51;
    g_task_img_exams_req           CONSTANT tl_task.id_tl_task%TYPE := 4; --14
    g_task_exam_results            CONSTANT tl_task.id_tl_task%TYPE := 15;
    g_task_img_exam_results        CONSTANT tl_task.id_tl_task%TYPE := 130;
    g_task_oth_exam_results        CONSTANT tl_task.id_tl_task%TYPE := 131;
    g_task_img_exam_recur          CONSTANT tl_task.id_tl_task%TYPE := 55;
    g_task_lab                     CONSTANT tl_task.id_tl_task%TYPE := 5; --16;
    g_task_lab_results             CONSTANT tl_task.id_tl_task%TYPE := 17;
    g_task_lab_recur               CONSTANT tl_task.id_tl_task%TYPE := 54;
    g_task_problems                CONSTANT tl_task.id_tl_task%TYPE := 18;
    g_task_diagnosis               CONSTANT tl_task.id_tl_task%TYPE := 19;
    g_task_transports              CONSTANT tl_task.id_tl_task%TYPE := 9;
    g_task_care_plans              CONSTANT tl_task.id_tl_task%TYPE := 21;
    g_task_guidelines              CONSTANT tl_task.id_tl_task%TYPE := 22;
    g_task_protocol                CONSTANT tl_task.id_tl_task%TYPE := 23;
    g_task_monitoring              CONSTANT tl_task.id_tl_task%TYPE := 6; --24;
    g_task_pat_education           CONSTANT tl_task.id_tl_task%TYPE := 25;
    g_task_procedures              CONSTANT tl_task.id_tl_task%TYPE := 8;
    g_task_medic_here              CONSTANT tl_task.id_tl_task%TYPE := 7;
    g_task_reported_medic          CONSTANT tl_task.id_tl_task%TYPE := 29;
    g_task_ph_surgical_hist        CONSTANT tl_task.id_tl_task%TYPE := 30;
    g_task_ph_obstetric_hist       CONSTANT tl_task.id_tl_task%TYPE := 31;
    g_task_ph_cong_anomalies       CONSTANT tl_task.id_tl_task%TYPE := 32;
    g_task_ph_relevant_notes       CONSTANT tl_task.id_tl_task%TYPE := 33;
    g_task_past_hist               CONSTANT tl_task.id_tl_task%TYPE := 34;
    g_task_final_diag              CONSTANT tl_task.id_tl_task%TYPE := 35;
    g_task_medication              CONSTANT tl_task.id_tl_task%TYPE := 52;
    g_task_rep_med_sel_list        CONSTANT tl_task.id_tl_task%TYPE := 53;
    g_task_chief_complaint         CONSTANT tl_task.id_tl_task%TYPE := 56;
    g_task_chief_complaint_anm     CONSTANT tl_task.id_tl_task%TYPE := 57;
    g_task_chief_compl_prt         CONSTANT tl_task.id_tl_task%TYPE := 58;
    g_task_arrival_date_time       CONSTANT tl_task.id_tl_task%TYPE := 59;
    g_task_arrival_days            CONSTANT tl_task.id_tl_task%TYPE := 203;
    g_task_plan_notes              CONSTANT tl_task.id_tl_task%TYPE := 60;
    g_task_subjective              CONSTANT tl_task.id_tl_task%TYPE := 118;
    g_task_objective               CONSTANT tl_task.id_tl_task%TYPE := 119;
    g_task_assessment              CONSTANT tl_task.id_tl_task%TYPE := 120;
    g_task_diag_notes              CONSTANT tl_task.id_tl_task%TYPE := 61;
    g_task_past_hist_prt           CONSTANT tl_task.id_tl_task%TYPE := 62;
    g_task_diets                   CONSTANT tl_task.id_tl_task%TYPE := 63;
    g_task_intake_output           CONSTANT tl_task.id_tl_task%TYPE := 3;
    g_task_positioning             CONSTANT tl_task.id_tl_task%TYPE := 1;
    g_task_analysis_comments       CONSTANT tl_task.id_tl_task%TYPE := 66;
    g_task_exams_comments          CONSTANT tl_task.id_tl_task%TYPE := 67;
    g_task_medication_comments     CONSTANT tl_task.id_tl_task%TYPE := 68;
    g_task_procedures_comments     CONSTANT tl_task.id_tl_task%TYPE := 69;
    g_task_consult_requests        CONSTANT tl_task.id_tl_task%TYPE := 70;
    g_task_disch_instructions      CONSTANT tl_task.id_tl_task%TYPE := 71;
    g_task_surg_procedures         CONSTANT tl_task.id_tl_task%TYPE := 72;
    g_task_consults                CONSTANT tl_task.id_tl_task%TYPE := 73;
    g_task_chief_complaint_out     CONSTANT tl_task.id_tl_task%TYPE := 121;
    g_task_emergency_law           CONSTANT tl_task.id_tl_task%TYPE := 123;
    g_task_schedule_inp            CONSTANT tl_task.id_tl_task%TYPE := 11;
    g_task_medrec_cont_home_hm     CONSTANT tl_task.id_tl_task%TYPE := 74; --continue at home from home medication
    g_task_medrec_mod_cont_home_hm CONSTANT tl_task.id_tl_task%TYPE := 139; -- modify to continue at home from home medication
    g_task_medrec_cont_hospital_hm CONSTANT tl_task.id_tl_task%TYPE := 76; --continue in the hospital from home medication
    g_task_medrec_discontinue_hm   CONSTANT tl_task.id_tl_task%TYPE := 77; --discontinue from home medication
    g_task_medrec_cont_home_lm     CONSTANT tl_task.id_tl_task%TYPE := 102; --continue at home from local medication
    g_task_medrec_cont_hospital_lm CONSTANT tl_task.id_tl_task%TYPE := 103; --continue in the hospital from local medication
    g_task_medrec_discontinue_lm   CONSTANT tl_task.id_tl_task%TYPE := 104; --discontinue from local medication
    g_task_chief_complaint_amb     CONSTANT tl_task.id_tl_task%TYPE := 75;
    g_task_problems_diag           CONSTANT tl_task.id_tl_task%TYPE := 78;
    g_task_procedures_exec         CONSTANT tl_task.id_tl_task%TYPE := 79;
    g_task_medical_appointment     CONSTANT tl_task.id_tl_task%TYPE := 81;
    g_task_nursing_appointment     CONSTANT tl_task.id_tl_task%TYPE := 82;
    g_task_nutrition_appointment   CONSTANT tl_task.id_tl_task%TYPE := 83;
    g_task_rehabilitation          CONSTANT tl_task.id_tl_task%TYPE := 84;
    g_task_social_service          CONSTANT tl_task.id_tl_task%TYPE := 85;
    g_task_inp_surg                CONSTANT tl_task.id_tl_task%TYPE := 86;
    g_task_surg                    CONSTANT tl_task.id_tl_task%TYPE := 125;
    g_task_body_diagram            CONSTANT tl_task.id_tl_task%TYPE := 126;
    g_task_opinion                 CONSTANT tl_task.id_tl_task%TYPE := 89;
    g_task_opinion_die             CONSTANT tl_task.id_tl_task%TYPE := 91;
    g_task_opinion_cm              CONSTANT tl_task.id_tl_task%TYPE := 92;
    g_task_opinion_sw              CONSTANT tl_task.id_tl_task%TYPE := 93;
    g_task_opinion_at              CONSTANT tl_task.id_tl_task%TYPE := 94;
    g_task_opinion_speech          CONSTANT tl_task.id_tl_task%TYPE := 215;
    g_task_opinion_occupational    CONSTANT tl_task.id_tl_task%TYPE := 216;
    g_task_opinion_physical        CONSTANT tl_task.id_tl_task%TYPE := 217;
    g_task_opinion_cdc             CONSTANT tl_task.id_tl_task%TYPE := 220;
    g_task_opinion_mental          CONSTANT tl_task.id_tl_task%TYPE := 221;
    g_task_opinion_religious       CONSTANT tl_task.id_tl_task%TYPE := 222;
    g_task_opinion_rehabilitation  CONSTANT tl_task.id_tl_task%TYPE := 223;

    g_task_referral                CONSTANT tl_task.id_tl_task%TYPE := 88;
    g_task_future_events           CONSTANT tl_task.id_tl_task%TYPE := 90;
    g_task_no_known_allergies      CONSTANT tl_task.id_tl_task%TYPE := 95;
    g_task_amb_medication          CONSTANT tl_task.id_tl_task%TYPE := 96;
    g_task_visit_info_inp          CONSTANT tl_task.id_tl_task%TYPE := 97;
    g_task_visit_info_edis         CONSTANT tl_task.id_tl_task%TYPE := 98;
    g_task_visit_info_amb          CONSTANT tl_task.id_tl_task%TYPE := 99;
    g_task_single_page_note        CONSTANT tl_task.id_tl_task%TYPE := 100;
    g_task_handp                   CONSTANT tl_task.id_tl_task%TYPE := 100;
    g_task_other_exams_req         CONSTANT tl_task.id_tl_task%TYPE := 101;
    g_task_no_known_prob           CONSTANT tl_task.id_tl_task%TYPE := 105;
    g_task_other_exams_recur       CONSTANT tl_task.id_tl_task%TYPE := 106;
    g_task_dev_first_yr            CONSTANT tl_task.id_tl_task%TYPE := 108; --Development during 1st year
    g_task_nutr_first_yr           CONSTANT tl_task.id_tl_task%TYPE := 109; --Nutrition during 1st year
    g_task_triage                  CONSTANT tl_task.id_tl_task%TYPE := 110;
    g_task_vaccination             CONSTANT tl_task.id_tl_task%TYPE := 111;
    g_task_communications          CONSTANT tl_task.id_tl_task%TYPE := 112;
    g_task_mtos_score              CONSTANT tl_task.id_tl_task%TYPE := 114;
    g_task_cits                    CONSTANT tl_task.id_tl_task%TYPE := 115;
    g_task_surgery                 CONSTANT tl_task.id_tl_task%TYPE := 10;
    g_task_prev_dischage_dt        CONSTANT tl_task.id_tl_task%TYPE := 12;
    g_task_prognosis               CONSTANT tl_task.id_tl_task%TYPE := 127;
    g_task_prof_resp               CONSTANT tl_task.id_tl_task%TYPE := 128; -- Responsible professional
    g_task_final_diag_prima        CONSTANT tl_task.id_tl_task%TYPE := 129; --final diagnosis principal
    g_task_allergies_allergy       CONSTANT tl_task.id_tl_task%TYPE := 133;
    g_task_allergies_adverse       CONSTANT tl_task.id_tl_task%TYPE := 134;
    g_task_allergies_intolerance   CONSTANT tl_task.id_tl_task%TYPE := 135;
    g_task_allergies_propensity    CONSTANT tl_task.id_tl_task%TYPE := 136;
    g_task_cits_procedures         CONSTANT tl_task.id_tl_task%TYPE := 137; --CITS procedures
    g_task_cits_procedures_special CONSTANT tl_task.id_tl_task%TYPE := 146; --CITS procedures special
    g_task_document_status         CONSTANT tl_task.id_tl_task%TYPE := 138; --Document status
    g_task_referral_other_exams    CONSTANT tl_task.id_tl_task%TYPE := 144; -- Referral other exams
    g_task_referral_img_exams      CONSTANT tl_task.id_tl_task%TYPE := 143; --Referral imaging exams
    g_task_referral_lab            CONSTANT tl_task.id_tl_task%TYPE := 142; -- Referral lab tests
    g_task_referral_rehab          CONSTANT tl_task.id_tl_task%TYPE := 141; --  Referral rehabilitation
    g_task_referral_proc           CONSTANT tl_task.id_tl_task%TYPE := 140; -- Referral procedures
    g_task_referral_nutrition      CONSTANT tl_task.id_tl_task%TYPE := 145; -- Referral nutrition
    g_task_patient_information     CONSTANT tl_task.id_tl_task%TYPE := 147; -- patient_information
    g_task_vacc                    CONSTANT tl_task.id_tl_task%TYPE := 148; -- Vaccination_Immunization
    g_task_past_hist_biometrics    CONSTANT tl_task.id_tl_task%TYPE := 151; -- Past medical history - Biometrics
    g_task_templates_other_note    CONSTANT tl_task.id_tl_task%TYPE := 153; -- Import tasks associated to a note of other note type (registere in the same episode)
    g_task_home_med_chinese        CONSTANT tl_task.id_tl_task%TYPE := 155;
    g_task_complications           CONSTANT tl_task.id_tl_task%TYPE := 161;
    g_task_problems_groups         CONSTANT tl_task.id_tl_task%TYPE := 170; -- Episode group problems
    g_task_problems_episode        CONSTANT tl_task.id_tl_task%TYPE := 171; -- Episode problems
    g_task_problems_group_ass      CONSTANT tl_task.id_tl_task%TYPE := 172; -- Problems group assessment
    g_task_vital_signs_view_date   CONSTANT tl_task.id_tl_task%TYPE := 501; -- Import vital sigan by view and date
    g_task_supply                  CONSTANT tl_task.id_tl_task%TYPE := 177; --Supply and materials
    g_task_episode_transf          CONSTANT tl_task.id_tl_task%TYPE := 181; --Episode transfer information 
    g_task_icu_assessment          CONSTANT tl_task.id_tl_task%TYPE := 173; -- ICU assessment
    g_task_transfer_cs             CONSTANT tl_task.id_tl_task%TYPE := 174; -- transfer to clinical service
    g_task_attending_physicians    CONSTANT tl_task.id_tl_task%TYPE := 175; -- Attending physicians
    g_task_check_reicu             CONSTANT tl_task.id_tl_task%TYPE := 179; -- Check whether to re-enter ICU
    g_task_cp_icu_info             CONSTANT tl_task.id_tl_task%TYPE := 180; -- Get the re-enter ICU information      
    g_task_icu_asse_priority       CONSTANT tl_task.id_tl_task%TYPE := 185; -- Get the ICU Assessment defult Priority
    g_task_blood_type              CONSTANT tl_task.id_tl_task%TYPE := 186; -- Blood Type
    g_task_obstetric_index         CONSTANT tl_task.id_tl_task%TYPE := 187; -- Obstetric index
    g_task_home                    CONSTANT tl_task.id_tl_task%TYPE := 189; --Housing
    g_task_fam_soc_class           CONSTANT tl_task.id_tl_task%TYPE := 190; --Social-demographic data   
    g_task_family_monetary         CONSTANT tl_task.id_tl_task%TYPE := 191; --Household financial situation
    g_task_restricted_pat          CONSTANT tl_task.id_tl_task%TYPE := 193; -- restricted patients
    g_task_intervention_plan       CONSTANT tl_task.id_tl_task%TYPE := 194; --Social intervention plans
    g_task_household               CONSTANT tl_task.id_tl_task%TYPE := 195; --Members of household
    g_task_follow_up_notes         CONSTANT tl_task.id_tl_task%TYPE := 196; --Social worker follow up notes  
    g_task_pat_identification      CONSTANT tl_task.id_tl_task%TYPE := 197; -- Patient identification
	g_task_opinion_psy             CONSTANT tl_task.id_tl_task%TYPE := 199; --psychology follow up
    g_task_psychology              CONSTANT tl_task.id_tl_task%TYPE := 200; --psychology appointment
    g_task_med_admin_herelastday   CONSTANT tl_task.id_tl_task%TYPE := 201; --medication admin here in last 24h aggregated
    g_task_med_antibiotics         CONSTANT tl_task.id_tl_task%TYPE := 202; --antibiotics admin in inp aggregated
    g_task_resp_physician          CONSTANT tl_task.id_tl_task%TYPE := 204; -- Responsable physician
    g_task_speech_therapy          CONSTANT tl_task.id_tl_task%TYPE := 213; --speech therapy appointment
    g_task_occupational_therapy    CONSTANT tl_task.id_tl_task%TYPE := 214; --occupational therapy appointment
    g_task_ph_family_diag CONSTANT tl_task.id_tl_task%TYPE := 207; -- Responsable physician
    g_task_ph_gynec_diag  CONSTANT tl_task.id_tl_task%TYPE := 208; --
    g_task_readmission    CONSTANT tl_task.id_tl_task%TYPE := 209; -- readmission ( multichoice on note)

    g_task_nurse_diagnosis    CONSTANT tl_task.id_tl_task%TYPE := 210; -- nurse diagnosis
    g_task_nurse_intervention    CONSTANT tl_task.id_tl_task%TYPE := 211; -- nurse interventions

    g_task_rehab_treatments CONSTANT tl_task.id_tl_task%TYPE := 218; -- rehabilitation treatments
    g_task_icf              CONSTANT tl_task.id_tl_task%TYPE := 219; -- clinical indication for rehabiliation

    g_task_current_pregnancy CONSTANT tl_task.id_tl_task%TYPE := 212; -- current pregnancy
    g_tl_table_name_ph_diag    VARCHAR2(30) := 'PAT_HISTORY_DIAGNOSIS';
    g_tl_table_name_pp         VARCHAR2(30) := 'PAT_PROBLEM';
    g_tl_table_name_ph_ftxt    VARCHAR2(30) := 'PAT_PAST_HIST_FT_HIST';
    g_tl_table_name_pat_hab    VARCHAR2(30) := 'PAT_HABIT';
    g_tl_table_name_pa         VARCHAR2(30) := 'PAT_ALLERGY';
    g_tl_table_name_pa_unaware VARCHAR2(30) := 'PAT_ALLERGY_UNAWARENESS';
    g_tl_table_name_pp_unaware VARCHAR2(30) := 'PAT_PROB_UNAWARE';
    g_tl_table_name_patient    VARCHAR2(30) := 'PATIENT';

    g_interval_last24h_d VARCHAR2(1 CHAR) := 'D';
    g_interval_week_w    VARCHAR2(1 CHAR) := 'W';
    g_interval_month_m   VARCHAR2(1 CHAR) := 'M';
    g_interval_all_a     VARCHAR2(1 CHAR) := 'A';

    g_barthel_index doc_area.id_doc_area%TYPE := 3592;

    g_discharge_notes doc_area.id_doc_area%TYPE := 36091;

    g_replace_1 CONSTANT VARCHAR2(2 CHAR) := '@1';

    g_type_replace_dblock CONSTANT VARCHAR2(2 CHAR) := 'RI';

    --Flash constants for KeyPad Parameters
    g_format_datetime_dh CONSTANT VARCHAR2(24 CHAR) := 'DH';
    g_format_date_d      CONSTANT VARCHAR2(1 CHAR) := 'D';

    g_validation_date_d           CONSTANT VARCHAR2(1 CHAR) := 'D';
    g_validation_time_t           CONSTANT VARCHAR2(1 CHAR) := 'T';
    g_validation_datetime_dt      CONSTANT VARCHAR2(24 CHAR) := 'DT';
    g_validation_date_partial_dtp CONSTANT VARCHAR2(24 CHAR) := 'DTP';
    g_validation_time_partial_dpt CONSTANT VARCHAR2(24 CHAR) := 'DPT';

    g_enter CONSTANT VARCHAR2(1 CHAR) := chr(10);
    g_hifen CONSTANT VARCHAR2(1 CHAR) := '-';

    --FLG_DATA_REMOVAL
    g_flg_remove_populated_p CONSTANT VARCHAR2(1 CHAR) := 'P'; --auto-populated record (black)
    g_flg_remove_imported_i  CONSTANT VARCHAR2(1 CHAR) := 'I'; --Imported record
    g_flg_remove_no_remove_n CONSTANT VARCHAR2(1 CHAR) := 'N'; --Not possible to remove from note
    g_flg_remove_shortcut_s  CONSTANT VARCHAR2(1 CHAR) := 'S'; --record created by shortcut

    --PN_NOTE_TYPE.FLG_TYPE
    g_nt_flg_type_s CONSTANT VARCHAR2(1 CHAR) := 'S'; --note_type structured
    g_nt_flg_type_f CONSTANT VARCHAR2(1 CHAR) := 'F'; --note_type free text

    --Medication contexts
    g_ctx_reported_medication CONSTANT VARCHAR2(13 CHAR) := 'SINGLE_PAGE_R';
    g_ctx_local_medication    CONSTANT VARCHAR2(13 CHAR) := 'SINGLE_PAGE_L';

    --Actions IDs
    g_task_med_resume_action CONSTANT action.id_action%TYPE := 700008;
    g_task_med_set_active    CONSTANT action.id_action%TYPE := 700001;
    g_task_med_set_inactive  CONSTANT action.id_action%TYPE := 700004;
    g_task_med_set_unknown   CONSTANT action.id_action%TYPE := 700005;
    g_task_med_review        CONSTANT action.id_action%TYPE := 810000;
    g_task_cancel_amb_med    CONSTANT action.id_action%TYPE := 701007;

    --FLG_ONGOING
    g_task_ongoing_o        CONSTANT task_timeline_ea.flg_ongoing%TYPE := 'O';
    g_task_finalized_f      CONSTANT task_timeline_ea.flg_ongoing%TYPE := 'F';
    g_task_inactive_i       CONSTANT task_timeline_ea.flg_ongoing%TYPE := 'I';
    g_task_pending_d        CONSTANT task_timeline_ea.flg_ongoing%TYPE := 'D';
    g_task_not_applicable_n CONSTANT task_timeline_ea.flg_ongoing%TYPE := 'N';

    --FLG_COMMENTS
    g_task_comments_na_i CONSTANT VARCHAR2(1 CHAR) := 'I';

    --FLG_AUTOPOPULATED
    g_auto_pop_all_y               CONSTANT pn_dblock_ttp_mkt.flg_auto_populated%TYPE := 'Y'; --This area should be auto-populated with no restrictions    
    g_auto_pop_anormal_a           CONSTANT pn_dblock_ttp_mkt.flg_auto_populated%TYPE := 'A'; --Auto-populated with anormal results
    g_auto_pop_normal_m            CONSTANT pn_dblock_ttp_mkt.flg_auto_populated%TYPE := 'M'; --Auto-populated with normal results
    g_auto_pop_first_record_r      CONSTANT pn_dblock_ttp_mkt.flg_auto_populated%TYPE := 'R'; --The first record is autopopulated
    g_auto_pop_last_record_l       CONSTANT pn_dblock_ttp_mkt.flg_auto_populated%TYPE := 'L'; --The last N records are auto populated
    g_auto_pop_last_rec_subg_s     CONSTANT pn_dblock_ttp_mkt.flg_auto_populated%TYPE := 'S'; --Last N records by subgroup (only available for analysis results)
    g_auto_pop_last_rec_gr_g       CONSTANT pn_dblock_ttp_mkt.flg_auto_populated%TYPE := 'G'; -- Last N records by group (only available for vital sings, lab and img)
    g_auto_pop_not_app_n           CONSTANT pn_dblock_ttp_mkt.flg_auto_populated%TYPE := 'N'; --It is not auto-populated
    g_auto_pop_since_last_p        CONSTANT pn_dblock_ttp_mkt.flg_auto_populated%TYPE := 'P'; --auto-populate since last record (all records, if there is no previsous note)
    g_auto_pop_with_notes_w        CONSTANT pn_dblock_ttp_mkt.flg_auto_populated%TYPE := 'W'; --auto-populate records with notes/comments
    g_auto_pop_without_notes_t     CONSTANT pn_dblock_ttp_mkt.flg_auto_populated%TYPE := 'T'; --auto-populate records without notes/comments
    g_auto_pop_ong_exec_c          CONSTANT pn_dblock_ttp_mkt.flg_auto_populated%TYPE := 'C'; --Ongoing records with at least one completed execution since last recheck
    g_auto_pop_no_note_sl_b        CONSTANT pn_dblock_ttp_mkt.flg_auto_populated%TYPE := 'B'; --All records since last note + all records without notes/comments
    g_auto_pop_reviewed_v          CONSTANT pn_dblock_ttp_mkt.flg_auto_populated%TYPE := 'V'; --Info reviewed in the episode
    g_auto_pop_no_new_presc_k      CONSTANT pn_dblock_ttp_mkt.flg_auto_populated%TYPE := 'K'; --Prescriptions that not originated a new prescription, only available for amb medication
    g_auto_pop_no_new_presc_z      CONSTANT pn_dblock_ttp_mkt.flg_auto_populated%TYPE := 'Z'; --Prescriptions that not originated a new prescription, only available for medication continue at home and continue in the hospital
    g_auto_pop_fin_execs_e         CONSTANT pn_dblock_ttp_mkt.flg_auto_populated%TYPE := 'E'; --Finalized records without any child execution performed by a professional from physician category (To be used in the procedures requests: the request is the parent andeach execution is a child record)
    g_auto_pop_new_prescs_h        CONSTANT pn_dblock_ttp_mkt.flg_auto_populated%TYPE := 'H'; --Ambulatory prescriptions originated from continue at home    
    g_auto_pop_new_prescs_x        CONSTANT pn_dblock_ttp_mkt.flg_auto_populated%TYPE := 'X'; --Ambulatory prescriptions originated from modify to continue at home    
    g_auto_pop_invasive_u          CONSTANT pn_dblock_ttp_mkt.flg_auto_populated%TYPE := 'U'; --Auto-populated requesitions of invasive exams/intervs
    g_auto_pop_chest_xr            CONSTANT pn_dblock_ttp_mkt.flg_auto_populated%TYPE := 'XR'; --Auto-populated requesitions chest x ray image results
    g_auto_pop_exam_pathology_pt   CONSTANT pn_dblock_ttp_mkt.flg_auto_populated%TYPE := 'PT'; --Auto-populated requesitions of pathology other exam orders / results
    g_auto_pop_relevant_j          CONSTANT pn_dblock_ttp_mkt.flg_auto_populated%TYPE := 'J'; --Auto-populated relevant exams/analysis/intervs results
    g_auto_pop_current_institution CONSTANT pn_dblock_ttp_mkt.flg_auto_populated%TYPE := 'CI'; -- Autopopulated records from current institution
    g_auto_pop_ext_institution     CONSTANT pn_dblock_ttp_mkt.flg_auto_populated%TYPE := 'EI'; -- Autopopulg_auto_pop_bd_medical_needsated records from external institution
    g_auto_pop_bd_others           CONSTANT pn_dblock_ttp_mkt.flg_auto_populated%TYPE := 'BO'; -- Auto-populated records of body diagrams that are categorized as normal ones
    g_auto_pop_bd_neur_assessm     CONSTANT pn_dblock_ttp_mkt.flg_auto_populated%TYPE := 'BN'; -- Auto-populated records of body diagrams in neurological assessment context
    g_auto_pop_bd_drain            CONSTANT pn_dblock_ttp_mkt.flg_auto_populated%TYPE := 'BD'; -- Auto-populated records of body diagrams in drainage context
    g_auto_pop_bd_medical_needs    CONSTANT pn_dblock_ttp_mkt.flg_auto_populated%TYPE := 'MN'; -- Auto-populated records of medication (last 7 days)
    g_auto_pop_miss                CONSTANT pn_dblock_ttp_mkt.flg_auto_populated%TYPE := 'MISS'; -- Modified Injury Severity Scores
    g_auto_pop_bd_med_antibotic    CONSTANT pn_dblock_ttp_mkt.flg_auto_populated%TYPE := 'ANTIB'; -- Auto-populated records of medication (last 7 days)
    g_auto_pop_b_streptococcus     CONSTANT pn_dblock_ttp_mkt.flg_auto_populated%TYPE := 'GBS'; --Auto-populated Lab test request
    g_auto_pop_antibiotic          CONSTANT pn_dblock_ttp_mkt.flg_auto_populated%TYPE := 'ANTIB'; --Auto-populated Antibiotics orders
    g_auto_pop_non_antibiotic      CONSTANT pn_dblock_ttp_mkt.flg_auto_populated%TYPE := 'NO_ANTI'; --Auto-populated Non antibiotics orders
    g_auto_pop_restraint_order     CONSTANT pn_dblock_ttp_mkt.flg_auto_populated%TYPE := 'RO'; --Auto-populated records of communication orders which are restraint orders
    g_auto_pop_procedure_gen       CONSTANT pn_dblock_ttp_mkt.flg_auto_populated%TYPE := 'IG'; --Auto-populated records of procedures which are general orders
    g_auto_pop_procedure_reh       CONSTANT pn_dblock_ttp_mkt.flg_auto_populated%TYPE := 'IR'; --Auto-populated records of procedures which are rehabilitation orders
    g_auto_pop_procedure_oth       CONSTANT pn_dblock_ttp_mkt.flg_auto_populated%TYPE := 'IT'; --Auto-populated records of procedures which are others
    g_auto_pop_procedure_obs       CONSTANT pn_dblock_ttp_mkt.flg_auto_populated%TYPE := 'IB'; --Auto-populated records of procedures which are observation fee
    g_auto_pop_procedure_dent      CONSTANT pn_dblock_ttp_mkt.flg_auto_populated%TYPE := 'ID'; --Auto-populated records of procedures which are Dentistry reques
    g_auto_pop_chemotherapy        CONSTANT pn_dblock_ttp_mkt.flg_auto_populated%TYPE := 'CHEMO'; --Auto-populated records of chemotherapy orders
    g_auto_pop_b_chemo             CONSTANT pn_dblock_ttp_mkt.flg_auto_populated%TYPE := 'CTP'; --Auto-populated Lab test request CHEMOTHERAPY

    g_action_copy_record_from_note CONSTANT pn_dblock_ttp_mkt.flg_auto_populated%TYPE := 'CPRN';
    g_action_copy_note             CONSTANT pn_dblock_ttp_mkt.flg_auto_populated%TYPE := 'CPN';
    g_action_copy_note_no_title    CONSTANT pn_dblock_ttp_mkt.flg_auto_populated%TYPE := 'CPNNOTITLE';
    g_action_cp_rec_from_same_note CONSTANT pn_dblock_ttp_mkt.flg_auto_populated%TYPE := 'CPRSN'; -- action to copy records from same notes
    g_action_cp_note_from_note_tp  CONSTANT pn_dblock_ttp_mkt.flg_auto_populated%TYPE := 'CPNT'; -- action to copy note from specific note type
g_auto_pop_last_record_l_area       CONSTANT pn_dblock_ttp_mkt.flg_auto_populated%TYPE := 'LD'; --The last N records for each doc_area are auto populated 
g_auto_pop_last_record_area       CONSTANT pn_dblock_ttp_mkt.flg_auto_populated%TYPE := 'D'; --The last N records for each doc_area are auto populated 
    --FLG_MED_FILTERS
    g_med_filter_n CONSTANT VARCHAR2(1 CHAR) := 'N'; --'Continue at home' or 'Continue in the hospital' tasks that generated a new prescription
    g_med_filter_r CONSTANT VARCHAR2(1 CHAR) := 'R'; --ambulatory medication tasks originated in the medication reconciliation

    --FLG_AUTOPOPULATED; FLG_SELECTED; FLG_IMPORT_FILTER: status based filters
    g_ongoing_o               CONSTANT pn_dblock_ttp_mkt.flg_auto_populated%TYPE := 'O'; ---Auto-populated with ongoing records
    g_ongoing_q               CONSTANT pn_dblock_ttp_mkt.flg_auto_populated%TYPE := 'Q';
    g_finalized_f             CONSTANT pn_dblock_ttp_mkt.flg_auto_populated%TYPE := 'F';
    g_inactive_i              CONSTANT pn_dblock_ttp_mkt.flg_selected%TYPE := 'I';
    g_pending_d               CONSTANT pn_dblock_ttp_mkt.flg_selected%TYPE := 'D';
    g_priority_u              CONSTANT analysis_req.flg_priority%TYPE := 'U';
    g_replied_opinion         CONSTANT pn_dblock_ttp_mkt.flg_import_filter%TYPE := 'RO'; -- filter by replied opinions
    g_stat                    CONSTANT pn_dblock_ttp_mkt.flg_import_filter%TYPE := 'SO'; -- Filter by the orders who need to be executed immediately (STAT ORDER)
    g_stat_result             CONSTANT pn_dblock_ttp_mkt.flg_import_filter%TYPE := 'SOR'; -- Filter by the orders who need to be executed immediately with results available in days_available period (STAT ORDER with results)
    g_date_filter             CONSTANT pn_dblock_ttp_mkt.flg_import_filter%TYPE := 'DO'; -- Filter that indicates that the record needs to e filtered by the date using the valu from pn_dblock_mkt.days_available_period (DATE ORDER)
    g_note_date_filter        CONSTANT pn_dblock_ttp_mkt.flg_import_filter%TYPE := 'DN'; -- Filter that indicates that the record needs to e filtered by the date using the valu from pn_dblock_mkt.days_available_period (NOTE DATE ORDER) 
    g_event_date_o_filter     CONSTANT pn_dblock_ttp_mkt.flg_import_filter%TYPE := 'DEO'; -- Filter that indicates that the record needs to e filtered by the date on event date (EVENT DATE)
    g_event_date_b_filter     CONSTANT pn_dblock_ttp_mkt.flg_import_filter%TYPE := 'DEB'; -- Filter that indicates that the record needs to e filtered by the date using the value before event date (EVENT DATE)
    g_admission_date_filter   CONSTANT pn_dblock_ttp_mkt.flg_import_filter%TYPE := 'DA'; -- Filter that indicates that the record needs to e filtered by the date on admission date
    g_vs_view_n2              CONSTANT pn_dblock_ttp_mkt.flg_import_filter%TYPE := 'N2'; -- Filter Vital Sign records on flg_view = N2
    g_vs_view_n3              CONSTANT pn_dblock_ttp_mkt.flg_import_filter%TYPE := 'N3'; -- Filter Vital Sign records on flg_view = N3
    g_vs_view_n4              CONSTANT pn_dblock_ttp_mkt.flg_import_filter%TYPE := 'N4'; -- Filter Vital Sign records on flg_view = N4
		g_vs_view_n5              CONSTANT pn_dblock_ttp_mkt.flg_import_filter%TYPE := 'N5'; -- Filter Vital Sign records on flg_view = N5 single page PN nurse
		g_vs_view_n6              CONSTANT pn_dblock_ttp_mkt.flg_import_filter%TYPE := 'N6'; -- Filter Vital Sign records on flg_view = N6 single page PN nurse UTI
    g_vs_view_pt              CONSTANT pn_dblock_ttp_mkt.flg_import_filter%TYPE := 'PT'; -- Filter Vital Sign records on flg_view = PT Labor and progression
    g_vs_view_n7              CONSTANT pn_dblock_ttp_mkt.flg_import_filter%TYPE := 'N7'; -- Filter Vital Sign records on flg_view = N7 single page Obstetric history   
    g_admission_date_b_filter CONSTANT pn_dblock_ttp_mkt.flg_import_filter%TYPE := 'DAB'; -- Filter that indicates that the record needs to be filtered by the the date using the value before  using the value before admission date
    g_primary_diagnosis       CONSTANT pn_dblock_ttp_mkt.flg_import_filter%TYPE := 'PD';
    g_secondary_diagnosis     CONSTANT pn_dblock_ttp_mkt.flg_import_filter%TYPE := 'SD';
    g_admission_dt_filter     CONSTANT pn_dblock_ttp_mkt.flg_import_filter%TYPE := 'AD'; -- Filter that indicates that the record needs to e filtered by the date on admission date
    g_current_resp_phys       CONSTANT pn_dblock_ttp_mkt.flg_import_filter%TYPE := 'CRESP'; -- Filter that indicates that the record must be the current responsability

    --flg_action
    g_flg_action_autopop  CONSTANT epis_pn_det_task.flg_action%TYPE := 'A';
    g_flg_action_shortcut CONSTANT epis_pn_det_task.flg_action%TYPE := 'S';
    g_flg_action_import   CONSTANT epis_pn_det_task.flg_action%TYPE := 'I';

    --
    g_not_editable_by_time CONSTANT VARCHAR2(1 CHAR) := 'T';
    g_editable_all         CONSTANT VARCHAR2(1 CHAR) := 'A';

    --areas
    g_area_disch_4              CONSTANT pn_area.id_pn_area%TYPE := 4;
    g_area_pn_2                 CONSTANT pn_area.id_pn_area%TYPE := 2;
    g_area_nursing_assessment_5 CONSTANT pn_area.id_pn_area%TYPE := 5;
    g_area_current_visit_3      CONSTANT pn_area.id_pn_area%TYPE := 3;

    --areas internal names
    g_area_hp   CONSTANT pn_area.internal_name%TYPE := 'HP'; --H&P
    g_area_cv   CONSTANT pn_area.internal_name%TYPE := 'CV'; -- Current visit
    g_area_ds   CONSTANT pn_area.internal_name%TYPE := 'DS'; --Discharge summary
    g_area_nia  CONSTANT pn_area.internal_name%TYPE := 'NIA'; --Initial nursing assessment
    g_area_nsp  CONSTANT pn_area.internal_name%TYPE := 'NSP'; --Nursing assessment
    g_area_npn  CONSTANT pn_area.internal_name%TYPE := 'NPN'; --Nursing progress notes
    g_area_pn   CONSTANT pn_area.internal_name%TYPE := 'PN'; --Progress notes
    g_area_dia  CONSTANT pn_area.internal_name%TYPE := 'DIA'; --Dietary initial assessment
    g_area_dpn  CONSTANT pn_area.internal_name%TYPE := 'DPN'; --Nutrition progress note
    g_area_nvn  CONSTANT pn_area.internal_name%TYPE := 'NVN'; --Nutrition visit note
    g_area_phan CONSTANT pn_area.internal_name%TYPE := 'PHAN'; --Pharmacist notes free text
    g_area_ria  CONSTANT pn_area.internal_name%TYPE := 'RIA'; --Initial respiratory assessment
    g_area_rpn  CONSTANT pn_area.internal_name%TYPE := 'RPN'; --Respiratory therapy progress notes
    g_area_psypn CONSTANT pn_area.internal_name%TYPE := 'PSYPN'; --Psychology progress note
    g_area_psyvn CONSTANT pn_area.internal_name%TYPE := 'PSYVN'; --Psychology visit note
    g_area_psyia CONSTANT pn_area.internal_name%TYPE := 'PSYIA'; --Psychology initial assessment
    g_area_cdcia CONSTANT pn_area.internal_name%TYPE := 'CDCIA'; --CDC initial assessment
    g_area_cdcvn CONSTANT pn_area.internal_name%TYPE := 'CDCVN'; --CDC visit notes
    g_area_cdcpn CONSTANT pn_area.internal_name%TYPE := 'CDCPN'; --CDC progress notes
    g_area_nmd   CONSTANT pn_area.internal_name%TYPE := 'NMD'; -- nursing mental discharge
    g_area_mtpn    CONSTANT pn_area.internal_name%TYPE := 'MTPN'; --Mental rehabilitation therapist progress notes
    g_area_rehabpn CONSTANT pn_area.internal_name%TYPE := 'REHABPN'; --Rehabilitation progress notes
    g_area_rcpn    CONSTANT pn_area.internal_name%TYPE := 'RCPN'; --Religious counselor progress notes
    g_area_swpn    CONSTANT pn_area.internal_name%TYPE := 'SWPN'; -- Social worker progress note
    --creation modes
    g_append_a CONSTANT VARCHAR2(1 CHAR) := 'A';
    g_update_u CONSTANT VARCHAR2(1 CHAR) := 'U';

    --insertion modes
    g_insert_i CONSTANT VARCHAR2(1 CHAR) := 'I';

    --sets of tasks to the get descriptions in group
    g_medication CONSTANT PLS_INTEGER := 1000;
    g_templates  CONSTANT PLS_INTEGER := 1001;
    g_med_rec    CONSTANT PLS_INTEGER := 1002;

    --
    --Default filter to apply to the summary grid. N-Last N records, D-Date filter that contains the last note.
    g_filter_date         CONSTANT VARCHAR2(1 CHAR) := 'D';
    g_filter_last_records CONSTANT VARCHAR2(1 CHAR) := 'N';

    g_soap_and_data_blocks CONSTANT VARCHAR2(2 CHAR) := 'SD';

    g_vital_sign_desc_code      CONSTANT VARCHAR2(30 CHAR) := 'VITAL_SIGN.CODE_VS_SHORT_DESC.';
    g_vital_sign_long_desc_code CONSTANT VARCHAR2(27 CHAR) := 'VITAL_SIGN.CODE_VITAL_SIGN.';

    --concepts of suggestion
    g_suggest_review_r CONSTANT pn_note_type_mkt.flg_suggest_concept%TYPE := 'R'; --registers not reviewed in the episode 
    g_suggest_p        CONSTANT pn_note_type_mkt.flg_suggest_concept%TYPE := 'P'; --information autopopulated ( not text, not synchronized)
    g_suggest_edit_e   CONSTANT pn_note_type_mkt.flg_suggest_concept%TYPE := 'E'; --information that can be edited (DS)

    g_desc_type_s          CONSTANT VARCHAR2(1 CHAR) := 'S'; -- S - short
    g_desc_type_l          CONSTANT VARCHAR2(1 CHAR) := 'L'; -- L- Long
    g_desc_type_d          CONSTANT VARCHAR2(1 CHAR) := 'D'; -- D - Detailed
    g_desc_type_c          CONSTANT VARCHAR2(1 CHAR) := 'C'; -- C - Conditional (uses DESCRIPTION_CONDITION as a condition for desc calculation)
    g_desc_type_visit_info CONSTANT VARCHAR2(2 CHAR) := 'VP'; -- visit information structure

    -- Constants to the rules to be applied to check if the button should be active
    g_flg_activation_n CONSTANT pn_button_mkt.flg_activation%TYPE := 'N'; --No rule to be applied. The button is always active
    g_flg_activation_o CONSTANT pn_button_mkt.flg_activation%TYPE := 'O'; --the button is active if there is not some ongoing record yet.

    --flg_editable
    g_editable_y            CONSTANT pn_dblock_mkt.flg_editable%TYPE := 'Y';
    g_not_editable_n        CONSTANT pn_dblock_mkt.flg_editable%TYPE := 'N'; -- no editable and do not set the records dimmed
    g_not_editable_dimmed_x CONSTANT pn_dblock_mkt.flg_editable%TYPE := 'X'; -- not editable and set the records dimmed
    g_editable_to_review_k  CONSTANT pn_dblock_mkt.flg_editable%TYPE := 'K'; -- editable and considered to be reviewed if flg_suggest_concept = E

    --
    g_without_status CONSTANT VARCHAR2(2 CHAR) := 'WS';

    g_flg_action_create CONSTANT VARCHAR2(1 CHAR) := 'C';
    g_flg_action_update CONSTANT VARCHAR2(1 CHAR) := 'U';

    g_flg_add     CONSTANT VARCHAR2(1 CHAR) := 'A';
    g_flg_remove  CONSTANT VARCHAR2(1 CHAR) := 'R';
    g_flg_app_upd CONSTANT VARCHAR2(1 CHAR) := 'U';

    g_open_bold_html  CONSTANT VARCHAR2(5) := '<b>';
    g_close_bold_html CONSTANT VARCHAR2(5) := '</b>';
    --
    g_category_title  VARCHAR2(30 CHAR) := 'categoryTitle';
    g_category_text   VARCHAR2(30 CHAR) := 'categoryText';
    g_note_type       VARCHAR2(30 CHAR) := 'NOTE_TYPE';
    g_note_type_group VARCHAR2(30 CHAR) := 'NOTE_TYPE_GROUP';
    g_dates           VARCHAR2(30 CHAR) := 'DATES';
    g_filter_all      VARCHAR2(30 CHAR) := 'FILTER_ALL';
    g_filter_ds       VARCHAR2(30 CHAR) := 'NOTE_TYPE|12';
    g_sep             VARCHAR2(1 CHAR) := '|';
    g_all             VARCHAR2(1 CHAR) := '1';
    --
    g_shift_summary_notes         VARCHAR2(20) := 'SHIFT_SUMMARY_NOTES';
    g_id_pntg_shift_summary_notes pn_note_type.id_pn_note_type_group%TYPE := 1;

    g_flg_value_a     CONSTANT VARCHAR2(1) := 'A'; --Admission date
    g_flg_value_c     CONSTANT VARCHAR2(1) := 'C'; --Current date
    g_flg_value_e     CONSTANT VARCHAR2(1) := 'E'; --Expected Discharge date
    g_flg_value_i     CONSTANT VARCHAR2(1) := 'I'; --Intake arrival date time
    g_flg_value_s     CONSTANT VARCHAR2(1) := 'S'; --Service transfer date/time
    g_flg_value_p     CONSTANT VARCHAR2(1) := 'P'; --Proposed date/time
    g_flg_value_icu_a CONSTANT VARCHAR2(5) := 'ICU_A'; --ICU Admission date/time
    g_flg_value_icu_d CONSTANT VARCHAR2(5) := 'ICU_D'; --ICU Discharge date/time
    g_flg_value_d     CONSTANT VARCHAR2(1) := 'D'; --Discharge date/time
    g_flg_value_b     CONSTANT VARCHAR2(1) := 'B'; --Birth date

    g_flg_config_signoff CONSTANT VARCHAR2(1) := 'S'; --Config type is signoff;

    g_flg_description_c CONSTANT VARCHAR2(1 CHAR) := 'C';
    -- Types of addenda
    g_epa_flg_type_addendum CONSTANT epis_pn_addendum.flg_type%TYPE := 'A';
    g_epa_flg_type_comment  CONSTANT epis_pn_addendum.flg_type%TYPE := 'C';

    -- Types of intervention category
    g_category_type_p    CONSTANT task_timeline_ea.flg_type%TYPE := 'P';
    g_category_type_oth  CONSTANT task_timeline_ea.flg_type%TYPE := 'O';
    g_category_type_reh  CONSTANT task_timeline_ea.flg_type%TYPE := 'R';
    g_category_type_dent CONSTANT task_timeline_ea.flg_type%TYPE := 'D';
    g_category_type_obs  CONSTANT task_timeline_ea.flg_type%TYPE := 'F';
    -- Note flg_edit_condition
    g_flg_edit_util_now CONSTANT VARCHAR2(001 CHAR) := 'U';
	
	g_search_free_text CONSTANT VARCHAR2(1) := 'F';
    g_search_template  CONSTANT VARCHAR2(1) := 'D';

END pk_prog_notes_constants;
/
