/*-- Last Change Revision: $Rev: 2054054 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2023-01-03 22:45:03 +0000 (ter, 03 jan 2023) $*/

CREATE OR REPLACE PACKAGE BODY pk_comm_orders IS

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- debug mode enabled/disabled
    g_debug BOOLEAN;

    g_retval BOOLEAN;
    g_exception_np EXCEPTION;
    g_exception    EXCEPTION;

    g_free_text              CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_M002';
    g_idx_id_comm_order_req  CONSTANT PLS_INTEGER := 1;
    g_idx_dt_begin           CONSTANT PLS_INTEGER := 2;
    g_idx_dt_begin_mask      CONSTANT VARCHAR2(50 CHAR) := pk_date_utils.g_dateformat;
    g_code_priority          CONSTANT sys_domain.code_domain%TYPE := 'COMM_ORDER_REQ.FLG_PRIORITY';
    g_code_prn               CONSTANT sys_domain.code_domain%TYPE := 'COMM_ORDER_REQ.FLG_PRN';
    g_code_clinical_purpose  CONSTANT sys_domain.code_domain%TYPE := 'COMM_ORDER_REQ.FLG_CLINICAL_PURPOSE';
    g_code_status            CONSTANT sys_domain.code_domain%TYPE := 'COMM_ORDER_REQ.ID_STATUS';
    g_code_status_order      CONSTANT sys_domain.code_domain%TYPE := 'COMM_ORDER_REQ.ID_STATUS_ORD';
    g_code_comm_order_action CONSTANT sys_domain.code_domain%TYPE := 'COMM_ORDER_REQ.FLG_ACTION';
    g_code_order_type        CONSTANT pk_translation.t_code := 'ORDER_TYPE.CODE_ORDER_TYPE.';
    g_code_cancel_reason     CONSTANT pk_translation.t_code := 'CANCEL_REASON.CODE_CANCEL_REASON.';

    -- actions
    g_id_act_ack           CONSTANT action.id_action%TYPE := 235528818;
    g_id_act_ack_med_order CONSTANT action.id_action%TYPE := 235534034;

    -- workflow info
    g_id_workflow CONSTANT wf_workflow.id_workflow%TYPE := 40;

    -- communication orders types
    g_comm_order_type_misc CONSTANT concept_type.id_concept_type%TYPE := 53;

    -- communication orders task type on terminology server
    --g_standard_task_type CONSTANT concept_term_task_type.id_task_type%TYPE := 63;

    -- sys_messages
    g_sm_comm_order_t004 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_T004'; -- clinical indication
    g_sm_comm_order_t005 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_T005'; -- Instructions   
    g_sm_comm_order_t008 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_T008'; -- 'Notes:'
    g_sm_comm_order_t010 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_T010'; -- 'Clinical purpose:'
    g_sm_comm_order_t011 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_T011'; -- 'Priority:'    
    g_sm_comm_order_t012 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_T012'; -- 'PRN:'
    g_sm_comm_order_t013 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_T013'; -- 'PRN condition:'   
    g_sm_comm_order_t014 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_T014'; -- 'Start date:'    
    g_sm_comm_order_t025 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_T025'; -- order
    g_sm_comm_order_t021 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_T021'; -- 'Notes'
    g_sm_comm_order_t026 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_T026'; -- 'Clinical indication:'
    g_sm_comm_order_t027 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_T027'; -- 'Acknowledgement'
    g_sm_comm_order_t028 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_T028'; -- 'Edition'
    g_sm_comm_order_t029 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_T029'; -- 'Notes (new record):'
    g_sm_comm_order_t030 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_T030'; -- 'Clinical Indication (new record):'
    g_sm_comm_order_t031 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_T031'; -- 'Clinical purpose (new record):'
    g_sm_comm_order_t032 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_T032'; -- 'Priority (new record):'
    g_sm_comm_order_t033 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_T033'; -- 'PRN (new record):'
    g_sm_comm_order_t034 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_T034'; -- 'Start date (new record):'
    --g_sm_comm_order_t035 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_T035'; -- 'Order type (new record):'
    --g_sm_comm_order_t036 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_T036'; -- 'Ordered by (new record):'
    --g_sm_comm_order_t037 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_T037'; -- 'Ordered at (new record):'
    g_sm_comm_order_t038 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_T038'; -- 'PRN condition (new record):'
    g_sm_comm_order_t040 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_T040'; -- 'Order type:'
    g_sm_comm_order_t041 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_T041'; -- 'Order at:'
    g_sm_comm_order_t042 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_T042'; -- 'Ordered by:'
    g_sm_comm_order_t043 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_T043'; -- 'Order co-sign'
    g_sm_comm_order_t044 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_T044'; -- 'Order co-sign (new record)'
    g_sm_comm_order_t047 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_T047'; -- 'Cancellation co-sign'
    g_sm_comm_order_t048 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_T048'; -- 'Cancellation co-sign (new record)'
    g_sm_comm_order_t049 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_T049'; -- 'Discontinuation co-sign'
    g_sm_comm_order_t050 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_T050'; -- 'Discontinuation co-sign (new record)'
    g_sm_comm_order_t051 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_T051'; -- 'Status:'
    g_sm_comm_order_t052 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_T052'; -- 'Status (new record):'
    g_sm_comm_order_t053 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_T053'; -- 'Co-sign notes:'
    g_sm_comm_order_t054 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_T054'; -- 'Co-sign notes (new record):'
    g_sm_comm_order_t055 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_T055'; -- 'Discontinuation reason: (new record):'
    g_sm_comm_order_t056 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_T056'; -- 'Discontinuation notes: (new record):'
    g_sm_comm_order_t057 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_T057'; -- 'Cancellation reason: (new record):'
    g_sm_comm_order_t058 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_T058'; -- 'Cancellation notes: (new record):'
    g_sm_comm_order_t061 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_T061'; -- 'Frequency:'
    g_sm_comm_order_t062 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_T062'; -- 'Frequency: (new record):'
    g_sm_comm_order_t063 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_T063'; -- 'Execution'
    g_sm_comm_order_t064 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_T064'; -- Start time:
    g_sm_comm_order_t065 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_T065'; -- Start time: (updated)
    g_sm_comm_order_t066 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_T066'; -- End time:
    g_sm_comm_order_t067 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_T067'; -- End time: (updated)
    g_sm_comm_order_t068 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_T068'; -- Performed by:
    g_sm_comm_order_t069 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_T069'; -- Performed by: (updated)
    g_sm_comm_order_t070 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_T070'; -- Execution
    g_sm_comm_order_t071 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_T071'; -- Monitored
    g_sm_comm_order_t072 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_T072'; -- Concluded
    g_sm_comm_order_t073 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_T073'; -- Cancellation 
    g_sm_comm_order_t074 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_T074'; -- Clinical questions
    g_sm_comm_order_t075 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_T075'; -- Time period of execution: 
    g_sm_comm_order_t077 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_T077'; -- Time period of execution (new record): 
    g_sm_comm_order_t079 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_T079'; -- Flowsheets

    g_sm_comm_order_m005 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_M005'; -- 'Documented:'
    g_sm_comm_order_m006 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_M006'; -- 'Updated:'
    g_sm_comm_order_m007 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_M007'; -- '<information deleted>'
    g_sm_comm_order_m008 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_M008'; -- 'Cancellation notes:'
    g_sm_comm_order_m009 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_M009'; -- 'Cancellation reason:'
    g_sm_comm_order_m010 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_M010'; -- 'Discontinuation reason:'
    g_sm_comm_order_m011 CONSTANT sys_message.code_message%TYPE := 'COMM_ORDER_M011'; -- 'Discontinuation notes:'

    -- fields to format (this codes are returned in reports)
    g_field_notes              CONSTANT VARCHAR2(30 CHAR) := 'ux_communicationorders_001'; --'NOTES';
    g_field_clin_indication    CONSTANT VARCHAR2(30 CHAR) := 'ux_communicationorders_002'; --'CLINICAL_INDICATION';
    g_field_clin_purpose       CONSTANT VARCHAR2(30 CHAR) := 'ux_communicationorders_003'; --'CLINICAL_PURPOSE';
    g_field_priority           CONSTANT VARCHAR2(30 CHAR) := 'ux_communicationorders_004'; --'PRIORITY';
    g_field_prn                CONSTANT VARCHAR2(30 CHAR) := 'ux_communicationorders_005'; --'PRN';
    g_field_prn_condition      CONSTANT VARCHAR2(30 CHAR) := 'ux_communicationorders_006'; --'PRN_CONDITION';
    g_field_dt_begin           CONSTANT VARCHAR2(30 CHAR) := 'ux_communicationorders_007'; --'DT_BEGIN';
    g_field_acknowledge        CONSTANT VARCHAR2(30 CHAR) := 'ux_communicationorders_011'; --'ACKNOWLEDGE';
    g_field_status             CONSTANT VARCHAR2(30 CHAR) := 'ux_communicationorders_012'; --'STATUS';
    g_field_cancel_reason      CONSTANT VARCHAR2(30 CHAR) := 'ux_communicationorders_013'; --'ID_CANCEL_REASON';
    g_field_cancel_notes       CONSTANT VARCHAR2(30 CHAR) := 'ux_communicationorders_014'; --'CANCEL_NOTES';    
    g_field_discontinue_reason CONSTANT VARCHAR2(30 CHAR) := 'ux_communicationorders_015'; -- related to discontinuation reason
    g_field_discontinue_notes  CONSTANT VARCHAR2(30 CHAR) := 'ux_communicationorders_016'; -- related to discontinuation notes
    g_field_frequency          CONSTANT VARCHAR2(30 CHAR) := 'ux_communicationorders_017'; --'FREQUENCY'
    g_field_task_duration      CONSTANT VARCHAR2(30 CHAR) := 'ux_communicationorders_018'; --'TASK_DURATION'
    g_field_start_time         CONSTANT VARCHAR2(30 CHAR) := 'ux_communicationorders_019'; --'start_time';
    g_field_end_time           CONSTANT VARCHAR2(30 CHAR) := 'ux_communicationorders_020'; --'end_time';
    g_field_performed_by       CONSTANT VARCHAR2(30 CHAR) := 'ux_communicationorders_021'; --'Performed by';    
    g_field_notes_execution    CONSTANT VARCHAR2(30 CHAR) := 'ux_communicationorders_022'; --'Execution notes';    
    g_field_template_execution CONSTANT VARCHAR2(30 CHAR) := 'ux_communicationorders_023'; --'Execution notes';    
    g_field_clinical_question  CONSTANT VARCHAR2(30 CHAR) := 'ux_communicationorders_024'; --'Clinical questions'
    g_field_parameter_desc     CONSTANT VARCHAR2(30 CHAR) := 'ux_communicationorders_025'; --'Parameter description (Flowsheets)'

    -- order co-sign
    g_field_o_id_order_type CONSTANT VARCHAR2(30 CHAR) := 'ux_communicationorders_008_o'; --'ID_ORDER_TYPE';
    g_field_o_prof_order    CONSTANT VARCHAR2(30 CHAR) := 'ux_communicationorders_009_o'; --'ID_PROF_ORDER';
    g_field_o_dt_order      CONSTANT VARCHAR2(30 CHAR) := 'ux_communicationorders_010_o'; --'DT_ORDER';
    g_field_o_notes         CONSTANT VARCHAR2(30 CHAR) := 'ux_communicationorders_017_o'; --'Co-Sign Notes';
    --g_field_o_status        CONSTANT VARCHAR2(30 CHAR) := 'ux_communicationorders_019_o'; --'Co-Signed status';
    g_field_o_title CONSTANT VARCHAR2(30 CHAR) := 'ux_communicationorders_020_o'; --'Order co-sign';

    -- edit co-sign
    g_field_e_id_order_type CONSTANT VARCHAR2(30 CHAR) := 'ux_communicationorders_008_e'; --'ID_ORDER_TYPE';
    g_field_e_prof_order    CONSTANT VARCHAR2(30 CHAR) := 'ux_communicationorders_009_e'; --'ID_PROF_ORDER';
    g_field_e_dt_order      CONSTANT VARCHAR2(30 CHAR) := 'ux_communicationorders_010_e'; --'DT_ORDER';
    g_field_e_notes         CONSTANT VARCHAR2(30 CHAR) := 'ux_communicationorders_017_e'; --'Co-Sign Notes';
    --g_field_e_status        CONSTANT VARCHAR2(30 CHAR) := 'ux_communicationorders_019_e'; --'Co-Signed status';
    g_field_e_title CONSTANT VARCHAR2(30 CHAR) := 'ux_communicationorders_020_e'; --'Order co-sign';

    -- cancellation co-sign
    g_field_c_id_order_type CONSTANT VARCHAR2(30 CHAR) := 'ux_communicationorders_008_c'; --'ID_ORDER_TYPE';
    g_field_c_prof_order    CONSTANT VARCHAR2(30 CHAR) := 'ux_communicationorders_009_c'; --'ID_PROF_ORDER';
    g_field_c_dt_order      CONSTANT VARCHAR2(30 CHAR) := 'ux_communicationorders_010_c'; --'DT_ORDER';
    g_field_c_notes         CONSTANT VARCHAR2(30 CHAR) := 'ux_communicationorders_017_c'; --'Co-Sign Notes';
    --g_field_c_status        CONSTANT VARCHAR2(30 CHAR) := 'ux_communicationorders_019_c'; --'Co-Signed status';
    g_field_c_title CONSTANT VARCHAR2(30 CHAR) := 'ux_communicationorders_020_c'; --'Cancellation co-sign';

    -- discontinuation co-sign
    g_field_d_id_order_type CONSTANT VARCHAR2(30 CHAR) := 'ux_communicationorders_008_d'; --'ID_ORDER_TYPE';
    g_field_d_prof_order    CONSTANT VARCHAR2(30 CHAR) := 'ux_communicationorders_009_d'; --'ID_PROF_ORDER';
    g_field_d_dt_order      CONSTANT VARCHAR2(30 CHAR) := 'ux_communicationorders_010_d'; --'DT_ORDER';
    g_field_d_notes         CONSTANT VARCHAR2(30 CHAR) := 'ux_communicationorders_017_d'; --'Co-Sign Notes';
    --g_field_d_status        CONSTANT VARCHAR2(30 CHAR) := 'ux_communicationorders_019_d'; --'Co-Signed status';
    g_field_d_title CONSTANT VARCHAR2(30 CHAR) := 'ux_communicationorders_020_~d'; --'Discontinuation co-sign';

    -- field_rank
    g_field_sr_status          CONSTANT PLS_INTEGER := 5;
    g_field_sr_notes           CONSTANT PLS_INTEGER := 10;
    g_field_sr_clin_indication CONSTANT PLS_INTEGER := 20;
    g_field_sr_clin_purpose    CONSTANT PLS_INTEGER := 30;
    g_field_sr_priority        CONSTANT PLS_INTEGER := 40;
    g_field_sr_prn             CONSTANT PLS_INTEGER := 50;
    g_field_sr_prn_condition   CONSTANT PLS_INTEGER := 60;
    g_filed_sr_performed_by    CONSTANT PLS_INTEGER := 65;
    g_field_sr_dt_begin        CONSTANT PLS_INTEGER := 70;
    g_field_sr_dt_end          CONSTANT PLS_INTEGER := 75;
    g_field_sr_frequency       CONSTANT PLS_INTEGER := 80;
    g_field_sr_task_duration   CONSTANT PLS_INTEGER := 85;
    g_field_sr_notes_execution CONSTANT PLS_INTEGER := 90;
    g_field_sr_parameter_desc  CONSTANT PLS_INTEGER := 95;
    -- order co-sign
    g_field_sr_o_id_order_type CONSTANT PLS_INTEGER := 80;
    g_field_sr_o_prof_order    CONSTANT PLS_INTEGER := 90;
    g_field_sr_o_dt_order      CONSTANT PLS_INTEGER := 100;
    g_field_sr_o_title         CONSTANT PLS_INTEGER := 200;
    --g_field_sr_o_status        CONSTANT PLS_INTEGER := 205;
    g_field_sr_o_notes CONSTANT PLS_INTEGER := 210;
    -- edit co-sign
    g_field_sr_e_id_order_type CONSTANT PLS_INTEGER := 110;
    g_field_sr_e_prof_order    CONSTANT PLS_INTEGER := 120;
    g_field_sr_e_dt_order      CONSTANT PLS_INTEGER := 130;
    g_field_sr_e_title         CONSTANT PLS_INTEGER := 220;
    --g_field_sr_e_status        CONSTANT PLS_INTEGER := 225;
    g_field_sr_e_notes CONSTANT PLS_INTEGER := 230;
    -- cancel co-sign
    g_field_sr_c_id_order_type CONSTANT PLS_INTEGER := 140;
    g_field_sr_c_prof_order    CONSTANT PLS_INTEGER := 150;
    g_field_sr_c_dt_order      CONSTANT PLS_INTEGER := 160;
    g_field_sr_c_title         CONSTANT PLS_INTEGER := 240;
    --g_field_sr_c_status        CONSTANT PLS_INTEGER := 245;
    g_field_sr_c_notes CONSTANT PLS_INTEGER := 250;
    -- discontinuation co-sign
    g_field_sr_d_id_order_type CONSTANT PLS_INTEGER := 140;
    g_field_sr_d_prof_order    CONSTANT PLS_INTEGER := 150;
    g_field_sr_d_dt_order      CONSTANT PLS_INTEGER := 160;
    g_field_sr_d_title         CONSTANT PLS_INTEGER := 260;
    --g_field_sr_d_status        CONSTANT PLS_INTEGER := 265;
    g_field_sr_d_notes CONSTANT PLS_INTEGER := 270;

    g_field_sr_cancel_reason      CONSTANT PLS_INTEGER := 133;
    g_field_sr_cancel_notes       CONSTANT PLS_INTEGER := 134;
    g_field_sr_discontinue_reason CONSTANT PLS_INTEGER := 133;
    g_field_sr_discontinue_notes  CONSTANT PLS_INTEGER := 134;

    --clinical questions
    g_field_sr_clin_quest CONSTANT PLS_INTEGER := 280;

    -- fields style rank
    g_field_style_rank_new    CONSTANT PLS_INTEGER := 10;
    g_field_style_rank_new_h2 CONSTANT PLS_INTEGER := 10;
    g_field_style_rank_normal CONSTANT PLS_INTEGER := 20;

    -- sys_configs
    g_config_show_free_text_option CONSTANT sys_config.id_sys_config%TYPE := 'COMM_ORDER_SHOW_FREE_TEXT_OPTION';

    -- max size used to truncate clob fields
    g_trunc_clob_max_size CONSTANT NUMBER := 200;

    -- clinical purpose other
    g_flg_clin_purpose_other   CONSTANT sys_domain.desc_val%TYPE := 'O';
    g_flg_clin_purpose_default CONSTANT sys_domain.desc_val%TYPE := 'N';

    -- icons
    g_icon_edited_info CONSTANT VARCHAR2(30 CHAR) := 'CpoeEditedInfoIcon';

    -- color
    g_color_fg_acknowledged CONSTANT VARCHAR2(10 CHAR) := '0x919178';
    g_color_bg_acknowledged CONSTANT VARCHAR2(10 CHAR) := '0xFAF09B';
    g_color_bg_alpha        CONSTANT VARCHAR2(10 CHAR) := '100';

    -- actions executed to the comm order req
    g_action_order       CONSTANT VARCHAR2(30 CHAR) := 'ORDER';
    g_action_edition     CONSTANT VARCHAR2(30 CHAR) := 'EDITION';
    g_action_ack         CONSTANT VARCHAR2(30 CHAR) := 'ACK';
    g_action_expired     CONSTANT VARCHAR2(30 CHAR) := 'EXPIRED';
    g_action_dicontinued CONSTANT VARCHAR2(30 CHAR) := 'DISCONTINUED';
    g_action_canceled    CONSTANT VARCHAR2(30 CHAR) := 'CANCELED';
    g_action_draft       CONSTANT VARCHAR2(30 CHAR) := 'DRAFT';
    g_action_predf       CONSTANT VARCHAR2(30 CHAR) := 'PREDEFINED';
    g_action_concluded   CONSTANT VARCHAR2(30 CHAR) := 'CONCLUDED';
    g_action_monitored   CONSTANT VARCHAR2(30 CHAR) := 'MONITORED';
    g_action_executed    CONSTANT VARCHAR2(30 CHAR) := 'EXECUTED';
    g_action_completed   CONSTANT VARCHAR2(30 CHAR) := 'COMPLETED';

    --Status flags for comm_order_plan
    g_flg_status_a CONSTANT VARCHAR2(1 CHAR) := 'A';
    g_flg_status_c CONSTANT VARCHAR2(1 CHAR) := 'C';
    g_flg_status_e CONSTANT VARCHAR2(1 CHAR) := 'E';
    g_flg_status_r CONSTANT VARCHAR2(1 CHAR) := 'R';

    FUNCTION trunc_clob_to_varchar2
    (
        i_clob     IN CLOB,
        i_max_size IN NUMBER
    ) RETURN VARCHAR2 IS
        l_varchar_string            VARCHAR2(32767); -- Maximum length for PL/SQL VARCHAR2 type
        l_max_size_without_ellipsis NUMBER;
        l_ellipis_str CONSTANT VARCHAR2(10 CHAR) := '...';
    BEGIN
    
        -- check if clob is greater than max size
        IF length(i_clob) > i_max_size
        THEN
        
            -- calculate max size without ellipsis
            l_max_size_without_ellipsis := i_max_size - length(l_ellipis_str);
        
            -- convert clob to varchar2 and truncate it to max size
            l_varchar_string := pk_string_utils.clob_to_varchar2(i_clob, l_max_size_without_ellipsis);
        
            -- append ellipsis to the string
            l_varchar_string := l_varchar_string || l_ellipis_str;
        
        ELSE
        
            -- convert clob to varchar2 and truncate it to max size
            l_varchar_string := pk_string_utils.clob_to_varchar2(i_clob, i_max_size);
        
        END IF;
    
        RETURN l_varchar_string;
    
    END trunc_clob_to_varchar2;

    FUNCTION get_comm_order_key
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_comm_order           IN comm_order_ea.id_comm_order%TYPE,
        o_id_concept_version      OUT comm_order_ea.id_concept_version%TYPE,
        o_id_cncpt_vrs_inst_owner OUT comm_order_ea.id_cncpt_vrs_inst_owner%TYPE,
        o_id_concept_term         OUT comm_order_ea.id_concept_term%TYPE,
        o_id_cncpt_trm_inst_owner OUT comm_order_ea.id_cncpt_trm_inst_owner%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_ea IS
            SELECT coea.id_concept_version,
                   coea.id_cncpt_vrs_inst_owner,
                   coea.id_concept_term,
                   coea.id_cncpt_trm_inst_owner
              FROM comm_order_ea coea
             WHERE coea.id_comm_order = i_id_comm_order;
    BEGIN
    
        OPEN c_ea;
        FETCH c_ea
            INTO o_id_concept_version, o_id_cncpt_vrs_inst_owner, o_id_concept_term, o_id_cncpt_trm_inst_owner;
        CLOSE c_ea;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_COMM_ORDER_KEY',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_comm_order_key;

    FUNCTION get_comm_order_question_type
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_concept_term IN comm_order_questionnaire.id_concept_term%TYPE,
        i_flg_time        IN interv_questionnaire.flg_time%TYPE,
        i_questionnaire   IN questionnaire.id_questionnaire%TYPE,
        i_response        IN response.id_response%TYPE
    ) RETURN comm_order_questionnaire.flg_type%TYPE IS
    
        l_type comm_order_questionnaire.flg_type%TYPE;
    
    BEGIN
    
        g_error := 'SELECT INTO L_TYPE';
        SELECT coq.flg_type
          INTO l_type
          FROM comm_order_questionnaire coq
         INNER JOIN questionnaire_response qr
            ON coq.id_questionnaire = qr.id_questionnaire
           AND coq.id_response = qr.id_response
         WHERE coq.id_concept_term = i_id_concept_term
           AND coq.flg_time = i_flg_time
           AND coq.id_questionnaire = i_questionnaire
           AND (coq.id_response = i_response OR i_response IS NULL)
           AND coq.id_institution = i_prof.institution
           AND coq.flg_available = pk_alert_constant.g_available
           AND qr.flg_available = pk_alert_constant.g_available
           AND rownum < 2;
    
        RETURN l_type;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_comm_order_question_type;

    FUNCTION get_comm_order_question_rank
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_concept_term IN comm_order_questionnaire.id_concept_term%TYPE,
        i_questionnaire   IN questionnaire.id_questionnaire%TYPE,
        i_flg_time        IN interv_questionnaire.flg_time%TYPE
    ) RETURN NUMBER IS
    
        l_rank NUMBER;
    
    BEGIN
    
        g_error := 'SELECT INTERV_QUESTIONNAIRE';
        SELECT MAX(coq.rank)
          INTO l_rank
          FROM comm_order_questionnaire coq
         WHERE coq.id_concept_term = i_id_concept_term
           AND coq.id_questionnaire = i_questionnaire
           AND coq.flg_time = i_flg_time
           AND coq.id_institution = i_prof.institution
           AND coq.flg_available = pk_alert_constant.g_available;
    
        RETURN l_rank;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_comm_order_question_rank;

    FUNCTION get_comm_order_id
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_concept_version      IN comm_order_ea.id_concept_version%TYPE,
        i_id_cncpt_vrs_inst_owner IN comm_order_ea.id_cncpt_vrs_inst_owner%TYPE,
        i_id_concept_term         IN comm_order_ea.id_concept_term%TYPE,
        i_id_cncpt_trm_inst_owner IN comm_order_ea.id_cncpt_trm_inst_owner%TYPE
    ) RETURN comm_order_ea.id_comm_order%TYPE IS
    
        l_id_comm_order comm_order_ea.id_comm_order%TYPE;
        l_prof_cat_id   category.id_category%TYPE := pk_prof_utils.get_id_category(i_lang, i_prof);
        l_market        market.id_market%TYPE := pk_utils.get_institution_market(i_lang, i_prof.institution);
    
        CURSOR c_ea IS
            SELECT coea.id_comm_order
              FROM comm_order_ea coea
             WHERE coea.id_concept_version = i_id_concept_version
               AND coea.id_cncpt_vrs_inst_owner = i_id_cncpt_vrs_inst_owner
               AND coea.id_concept_term = i_id_concept_term
               AND coea.id_cncpt_trm_inst_owner = i_id_cncpt_trm_inst_owner
               AND coea.id_market IN (pk_alert_constant.g_id_market_all, l_market)
               AND coea.id_institution_term_vers IN (pk_alert_constant.g_inst_all, i_prof.institution)
               AND coea.id_institution_conc_term IN (pk_alert_constant.g_inst_all, i_prof.institution)
               AND coea.id_software_term_vers IN (pk_alert_constant.g_soft_all, i_prof.software)
               AND coea.id_software_conc_term IN (pk_alert_constant.g_soft_all, i_prof.software)
               AND coea.id_category_cncpt_vers IN (pk_ea_logic_comm_orders.k_category_minus_one, l_prof_cat_id)
               AND coea.id_category_cncpt_term IN (pk_ea_logic_comm_orders.k_category_minus_one, l_prof_cat_id);
    BEGIN
    
        g_error := 'OPEN c_ea';
        OPEN c_ea;
        FETCH c_ea
            INTO l_id_comm_order;
        CLOSE c_ea;
    
        RETURN l_id_comm_order;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(SQLERRM || ' / ' || g_error);
            RETURN NULL;
    END get_comm_order_id;

    FUNCTION get_comm_order_req_dt_b
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_comm_order_req IN comm_order_req.id_comm_order_req%TYPE
    ) RETURN comm_order_req.dt_begin%TYPE IS
    
        l_error  t_error_out;
        l_result comm_order_req.dt_begin%TYPE;
    
        CURSOR c_req IS
            SELECT cor.dt_begin
              FROM comm_order_req cor
             WHERE cor.id_comm_order_req = i_id_comm_order_req;
    
    BEGIN
    
        g_error := 'OPEN c_req ';
        OPEN c_req;
        FETCH c_req
            INTO l_result;
        CLOSE c_req;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_COMM_ORDER_REQ_DT_B',
                                              o_error    => l_error);
            RETURN NULL;
    END get_comm_order_req_dt_b;

    FUNCTION get_comm_order_req_epis
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_comm_order_req IN comm_order_req.id_comm_order_req%TYPE
    ) RETURN comm_order_req.id_episode%TYPE IS
    
        l_error  t_error_out;
        l_result comm_order_req.id_episode%TYPE;
    
        CURSOR c_req IS
            SELECT cor.id_episode
              FROM comm_order_req cor
             WHERE cor.id_comm_order_req = i_id_comm_order_req;
    BEGIN
    
        g_error := 'OPEN c_req / ';
        OPEN c_req;
        FETCH c_req
            INTO l_result;
        CLOSE c_req;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_COMM_ORDER_REQ_EPIS',
                                              o_error    => l_error);
            RETURN NULL;
    END get_comm_order_req_epis;

    FUNCTION get_comm_order_req_rows
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_comm_order_req IN table_number,
        o_row_tab           OUT t_coll_comm_order_req,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_req IS
            SELECT /*+opt_estimate (table tt rows=1)*/
             t_rec_comm_order_req(cor.id_comm_order_req,
                                  cor.id_workflow,
                                  cor.id_status,
                                  cor.id_patient,
                                  cor.id_episode,
                                  cor.id_concept_type,
                                  cor.id_concept_version,
                                  cor.id_cncpt_vrs_inst_owner,
                                  cor.id_concept_term,
                                  cor.id_cncpt_trm_inst_owner,
                                  cor.flg_free_text,
                                  pk_translation.get_translation_trs(cor.desc_concept_term),
                                  cor.id_prof_req,
                                  cor.id_inst_req,
                                  cor.dt_req,
                                  pk_translation.get_translation_trs(cor.notes),
                                  pk_translation.get_translation_trs(cor.clinical_indication),
                                  cor.flg_clinical_purpose,
                                  cor.clinical_purpose_desc,
                                  cor.flg_priority,
                                  cor.flg_prn,
                                  pk_translation.get_translation_trs(cor.prn_condition),
                                  cor.dt_begin,
                                  cor.id_professional,
                                  cor.id_institution,
                                  cor.dt_status,
                                  pk_translation.get_translation_trs(cor.notes_cancel),
                                  cor.id_cancel_reason,
                                  cor.flg_need_ack,
                                  cor.flg_action,
                                  cor.id_previous_status,
                                  cor.task_duration,
                                  cor.id_order_recurr,
                                  cor.id_task_type,
                                  t_table_co_sign())
              FROM comm_order_req cor
              JOIN TABLE(CAST(i_id_comm_order_req AS table_number)) tt
                ON (tt.column_value = cor.id_comm_order_req);
    
    BEGIN
    
        g_error := 'OPEN c_req';
        OPEN c_req;
        FETCH c_req BULK COLLECT
            INTO o_row_tab;
        CLOSE c_req;
    
        IF o_row_tab.count = 0
        THEN
            g_error := 'Communication order request does not exist';
            RAISE g_exception;
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
                                              i_function => 'GET_COMM_ORDER_REQ_ROWS',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_comm_order_req_rows;

    FUNCTION get_comm_order_req_row
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_comm_order_req IN comm_order_req.id_comm_order_req%TYPE,
        o_row               OUT t_rec_comm_order_req,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_row_tab t_coll_comm_order_req;
    
    BEGIN
    
        g_error  := 'GET_COMM_ORDER_REQ_ROWS';
        g_retval := get_comm_order_req_rows(i_lang              => i_lang,
                                            i_prof              => i_prof,
                                            i_id_comm_order_req => table_number(i_id_comm_order_req),
                                            o_row_tab           => l_row_tab,
                                            o_error             => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        o_row := l_row_tab(1);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_COMM_ORDER_REQ_ROW',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_comm_order_req_row;

    FUNCTION get_flg_action
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_status_actual IN comm_order_req.id_status%TYPE,
        i_task_type        IN comm_order_req.id_task_type%TYPE DEFAULT NULL
    ) RETURN comm_order_req.flg_action%TYPE IS
    
        l_flg_action comm_order_req.flg_action%TYPE;
    
    BEGIN
    
        CASE
            WHEN i_id_status_actual = g_id_sts_ongoing THEN
                l_flg_action := g_action_order;
            WHEN i_id_status_actual = g_id_sts_expired THEN
                l_flg_action := g_action_expired;
            WHEN i_id_status_actual = g_id_sts_completed
                 AND i_task_type = pk_alert_constant.g_task_medical_orders THEN
                l_flg_action := g_action_completed;
            WHEN i_id_status_actual = g_id_sts_completed THEN
                l_flg_action := g_action_dicontinued;
            WHEN i_id_status_actual IN (g_id_sts_canceled, g_id_sts_discontinued) THEN
                l_flg_action := g_action_canceled;
            WHEN i_id_status_actual = g_id_sts_draft THEN
                l_flg_action := g_action_draft;
            WHEN i_id_status_actual = g_id_sts_predf THEN
                l_flg_action := g_action_predf;
            ELSE
                l_flg_action := NULL;
        END CASE;
    
        RETURN l_flg_action;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error('GET_FLG_ACTION / ' || SQLERRM);
            RETURN NULL;
    END get_flg_action;

    FUNCTION get_clinical_purpose_desc
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_flg_clin_purpose  IN comm_order_req.flg_clinical_purpose%TYPE,
        i_clin_purpose_desc IN comm_order_req.clinical_purpose_desc%TYPE
    ) RETURN comm_order_req.clinical_purpose_desc%TYPE IS
    
        l_result comm_order_req.clinical_purpose_desc%TYPE;
    
    BEGIN
    
        IF i_flg_clin_purpose = g_flg_clin_purpose_other
        THEN
            l_result := i_clin_purpose_desc;
        ELSE
            l_result := pk_sysdomain.get_domain(i_code_dom => g_code_clinical_purpose,
                                                i_val      => i_flg_clin_purpose,
                                                i_lang     => i_lang);
        END IF;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error('GET_CLINICAL_PURPOSE_DESC / ' || SQLERRM);
            RETURN NULL;
    END get_clinical_purpose_desc;

    FUNCTION get_diagnoses
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_clinical_indication IN comm_order_req.clinical_indication%TYPE,
        o_id_diagnoses        OUT table_number,
        o_id_alert_diagnoses  OUT table_number,
        o_desc_diagnoses      OUT table_varchar,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rec_clin_ind   pk_edis_types.rec_in_epis_diagnosis;
        l_coll_diagnoses t_table_diagnoses;
    
    BEGIN
    
        o_id_diagnoses       := table_number();
        o_id_alert_diagnoses := table_number();
        o_desc_diagnoses     := table_varchar();
    
        -- get diagnosis records
        IF i_clinical_indication IS NOT NULL
        THEN
            g_error        := 'Call pk_diagnosis.get_diag_rec';
            l_rec_clin_ind := pk_diagnosis.get_diag_rec(i_lang   => i_lang,
                                                        i_prof   => i_prof,
                                                        i_params => i_clinical_indication);
        
            -- get diagnosis information 
            l_coll_diagnoses := t_table_diagnoses();
            IF l_rec_clin_ind.tbl_diagnosis IS NOT NULL
               AND l_rec_clin_ind.tbl_diagnosis.count > 0
            THEN
            
                l_coll_diagnoses.extend(l_rec_clin_ind.tbl_diagnosis.count);
            
                FOR i IN 1 .. l_rec_clin_ind.tbl_diagnosis.count
                LOOP
                    l_coll_diagnoses(i) := t_rec_diagnosis(NULL, NULL, NULL);
                    l_coll_diagnoses(i).id_diagnosis := l_rec_clin_ind.tbl_diagnosis(i).id_diagnosis;
                    l_coll_diagnoses(i).id_alert_diagnosis := l_rec_clin_ind.tbl_diagnosis(i).id_alert_diagnosis;
                    l_coll_diagnoses(i).desc_epis_diagnosis := pk_diagnosis.get_diag_desc(i_lang,
                                                                                          i_prof,
                                                                                          l_rec_clin_ind.tbl_diagnosis(i));
                END LOOP;
            END IF;
        
            g_error := 'SELECT';
            SELECT /*+opt_estimate (table t rows=1)*/
             t.id_diagnosis, t.id_alert_diagnosis, t.desc_epis_diagnosis
              BULK COLLECT
              INTO o_id_diagnoses, o_id_alert_diagnoses, o_desc_diagnoses
              FROM TABLE(CAST(l_coll_diagnoses AS t_table_diagnoses)) t
             ORDER BY t.id_diagnosis; -- to be sure that information is returned always in this order
        
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
                                              i_function => 'GET_DIAGNOSES',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_diagnoses;

    FUNCTION get_id_diagnoses
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_clinical_indication IN comm_order_req.clinical_indication%TYPE
    ) RETURN table_number IS
    
        l_diagnoses_desc     table_varchar;
        l_id_diagnoses       table_number;
        l_id_alert_diagnoses table_number;
        l_error              t_error_out;
    
    BEGIN
    
        l_id_diagnoses := table_number();
    
        -- get diagnosis info
        g_error  := 'Call get_diagnoses';
        g_retval := get_diagnoses(i_lang                => i_lang,
                                  i_prof                => i_prof,
                                  i_clinical_indication => i_clinical_indication,
                                  o_id_diagnoses        => l_id_diagnoses,
                                  o_id_alert_diagnoses  => l_id_alert_diagnoses,
                                  o_desc_diagnoses      => l_diagnoses_desc,
                                  o_error               => l_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN l_id_diagnoses;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN NULL;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_ID_DIAGNOSES',
                                              o_error    => l_error);
            RETURN NULL;
    END get_id_diagnoses;

    FUNCTION get_id_alert_diagnoses
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_clinical_indication IN comm_order_req.clinical_indication%TYPE
    ) RETURN table_number IS
    
        l_diagnoses_desc     table_varchar;
        l_id_diagnoses       table_number;
        l_id_alert_diagnoses table_number;
        l_error              t_error_out;
    
    BEGIN
    
        l_id_alert_diagnoses := table_number();
    
        -- get diagnosis info
        g_error  := 'Call get_diagnoses';
        g_retval := get_diagnoses(i_lang                => i_lang,
                                  i_prof                => i_prof,
                                  i_clinical_indication => i_clinical_indication,
                                  o_id_diagnoses        => l_id_diagnoses,
                                  o_id_alert_diagnoses  => l_id_alert_diagnoses,
                                  o_desc_diagnoses      => l_diagnoses_desc,
                                  o_error               => l_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN l_id_alert_diagnoses;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN NULL;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_ID_ALERT_DIAGNOSES',
                                              o_error    => l_error);
            RETURN NULL;
    END get_id_alert_diagnoses;

    FUNCTION get_desc_diagnoses
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_clinical_indication IN comm_order_req.clinical_indication%TYPE
    ) RETURN table_varchar IS
    
        l_diagnoses_desc     table_varchar;
        l_id_diagnoses       table_number;
        l_id_alert_diagnoses table_number;
        l_error              t_error_out;
    
    BEGIN
    
        l_diagnoses_desc := table_varchar();
    
        -- get diagnosis info
        g_error  := 'Call get_diagnoses ';
        g_retval := get_diagnoses(i_lang                => i_lang,
                                  i_prof                => i_prof,
                                  i_clinical_indication => i_clinical_indication,
                                  o_id_diagnoses        => l_id_diagnoses,
                                  o_id_alert_diagnoses  => l_id_alert_diagnoses,
                                  o_desc_diagnoses      => l_diagnoses_desc,
                                  o_error               => l_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN l_diagnoses_desc;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN NULL;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_DESC_DIAGNOSES',
                                              o_error    => l_error);
            RETURN NULL;
    END get_desc_diagnoses;

    FUNCTION get_diagnoses_text
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_clinical_indication IN comm_order_req.clinical_indication%TYPE,
        o_text                OUT CLOB,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_diagnosis_desc table_varchar;
    
    BEGIN
    
        -- get diagnosis desc        
        g_error          := 'Call get_desc_diagnoses';
        l_diagnosis_desc := get_desc_diagnoses(i_lang                => i_lang,
                                               i_prof                => i_prof,
                                               i_clinical_indication => i_clinical_indication);
    
        -- concat descriptions
        o_text := pk_utils.concat_table(l_diagnosis_desc, g_str_sep_comma);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_DIAGNOSES_TEXT',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_diagnoses_text;

    FUNCTION get_comm_order_type_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_task_type IN NUMBER,
        o_list      OUT t_cur_comm_order_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_prof_cat_id               category.id_category%TYPE := pk_prof_utils.get_id_category(i_lang, i_prof);
        l_market                    market.id_market%TYPE := pk_utils.get_institution_market(i_lang, i_prof.institution);
        l_cfg_show_free_text_option sys_config.value%TYPE := pk_sysconfig.get_config(g_config_show_free_text_option,
                                                                                     i_prof);
    
    BEGIN
    
        g_error := 'OPEN o_list';
        OPEN o_list FOR
            SELECT id_comm_order_type,
                   get_comm_order_type_desc(i_lang, i_prof, id_comm_order_type) || ' (' || COUNT(*) || ')' AS desc_comm_order_type
              FROM (SELECT cotype.id_comm_order_type AS id_comm_order_type
                      FROM comm_order_type cotype
                     WHERE l_cfg_show_free_text_option = pk_alert_constant.g_yes
                       AND cotype.id_task_type = i_task_type
                    UNION ALL
                    SELECT coea.id_concept_type AS id_comm_order_type
                      FROM comm_order_ea coea
                     WHERE coea.id_market IN (pk_alert_constant.g_id_market_all, l_market)
                       AND coea.id_institution_term_vers IN (pk_alert_constant.g_inst_all, i_prof.institution)
                       AND coea.id_institution_conc_term IN (pk_alert_constant.g_inst_all, i_prof.institution)
                       AND coea.id_software_term_vers IN (pk_alert_constant.g_soft_all, i_prof.software)
                       AND coea.id_software_conc_term IN (pk_alert_constant.g_soft_all, i_prof.software)
                       AND coea.id_category_cncpt_vers IN (pk_ea_logic_comm_orders.k_category_minus_one, l_prof_cat_id)
                       AND coea.id_category_cncpt_term IN (pk_ea_logic_comm_orders.k_category_minus_one, l_prof_cat_id)
                       AND coea.id_task_type_conc_term = i_task_type
                       AND coea.cpt_vrs_uid_parent IS NULL) t
             GROUP BY t.id_comm_order_type
             ORDER BY decode(id_comm_order_type, g_comm_order_type_misc, 1, 0), upper(desc_comm_order_type);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_COMM_ORDER_TYPE_LIST',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_comm_order_type_list;

    FUNCTION get_num_comm_order_children
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_cpt_vrs_uid IN comm_order_ea.cpt_vrs_uid%TYPE
    ) RETURN NUMBER IS
    
        l_error t_error_out;
    
        l_prof_cat_id category.id_category%TYPE := pk_prof_utils.get_id_category(i_lang, i_prof);
        l_market      market.id_market%TYPE := pk_utils.get_institution_market(i_lang, i_prof.institution);
    
        l_num_childs NUMBER;
    
    BEGIN
    
        g_error := 'get number of children of the communication order ';
        SELECT COUNT(*)
          INTO l_num_childs
          FROM comm_order_ea coea
         WHERE coea.id_market IN (pk_alert_constant.g_id_market_all, l_market)
           AND coea.id_institution_term_vers IN (pk_alert_constant.g_inst_all, i_prof.institution)
           AND coea.id_institution_conc_term IN (pk_alert_constant.g_inst_all, i_prof.institution)
           AND coea.id_software_term_vers IN (pk_alert_constant.g_soft_all, i_prof.software)
           AND coea.id_software_conc_term IN (pk_alert_constant.g_soft_all, i_prof.software)
           AND coea.id_category_cncpt_vers IN (pk_ea_logic_comm_orders.k_category_minus_one, l_prof_cat_id)
           AND coea.id_category_cncpt_term IN (pk_ea_logic_comm_orders.k_category_minus_one, l_prof_cat_id)
           AND coea.cpt_vrs_uid_parent = i_cpt_vrs_uid;
    
        RETURN l_num_childs;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_NUM_COMM_ORDER_CHILDREN',
                                              o_error    => l_error);
            RETURN NULL;
    END get_num_comm_order_children;

    FUNCTION get_cpt_vrs_uid
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_comm_order IN comm_order_ea.id_comm_order%TYPE
    ) RETURN comm_order_ea.cpt_vrs_uid%TYPE IS
    
        l_error t_error_out;
    
        l_prof_cat_id category.id_category%TYPE := pk_prof_utils.get_id_category(i_lang, i_prof);
        l_market      market.id_market%TYPE := pk_utils.get_institution_market(i_lang, i_prof.institution);
    
        l_cpt_vrs_uid comm_order_ea.cpt_vrs_uid%TYPE;
    
    BEGIN
    
        g_error := 'get concept version unique identifier of the communication order';
        SELECT coea.cpt_vrs_uid
          INTO l_cpt_vrs_uid
          FROM comm_order_ea coea
         WHERE coea.id_market IN (pk_alert_constant.g_id_market_all, l_market)
           AND coea.id_institution_term_vers IN (pk_alert_constant.g_inst_all, i_prof.institution)
           AND coea.id_institution_conc_term IN (pk_alert_constant.g_inst_all, i_prof.institution)
           AND coea.id_software_term_vers IN (pk_alert_constant.g_soft_all, i_prof.software)
           AND coea.id_software_conc_term IN (pk_alert_constant.g_soft_all, i_prof.software)
           AND coea.id_category_cncpt_vers IN (pk_ea_logic_comm_orders.k_category_minus_one, l_prof_cat_id)
           AND coea.id_category_cncpt_term IN (pk_ea_logic_comm_orders.k_category_minus_one, l_prof_cat_id)
           AND coea.id_comm_order = i_id_comm_order;
    
        RETURN l_cpt_vrs_uid;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_CPT_VRS_UID',
                                              o_error    => l_error);
            RETURN NULL;
    END get_cpt_vrs_uid;

    FUNCTION get_comm_order_selection_list
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_comm_order_type IN concept_type.id_concept_type%TYPE,
        i_id_comm_order_par  IN comm_order_ea.id_comm_order%TYPE,
        i_task_type          IN NUMBER,
        o_list               OUT t_cur_comm_order,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_prof_cat_id               category.id_category%TYPE := pk_prof_utils.get_id_category(i_lang, i_prof);
        l_market                    market.id_market%TYPE := pk_utils.get_institution_market(i_lang, i_prof.institution);
        l_cfg_show_free_text_option sys_config.value%TYPE := pk_sysconfig.get_config(g_config_show_free_text_option,
                                                                                     i_prof);
    
    BEGIN
    
        g_error := 'OPEN o_list';
        OPEN o_list FOR
            SELECT t.id_comm_order_type,
                   t.desc_comm_order_type,
                   t.icon_comm_order_type,
                   t.rank_comm_order_type,
                   t.id_comm_order,
                   t.flg_clinical_question,
                   t.desc_comm_order || decode(num_comm_order_children, 0, '', ' (' || num_comm_order_children || ')') AS desc_comm_order,
                   nvl2(t.concept_path, get_comm_order_path_bound_desc(i_lang, i_prof, t.concept_path) || ' > ', '') ||
                   t.desc_comm_order AS desc_comm_order_with_path,
                   t.flg_free_text,
                   decode(num_comm_order_children, 0, pk_alert_constant.g_yes, pk_alert_constant.g_no) AS flg_select,
                   decode(num_comm_order_children, 0, pk_alert_constant.g_no, pk_alert_constant.g_yes) AS flg_child
              FROM (SELECT DISTINCT coea.id_concept_type AS id_comm_order_type,
                                    pk_translation.get_translation(i_lang, coea.code_concept_type_name) AS desc_comm_order_type,
                                    pk_translation.get_translation(i_lang, cotype.code_icon) AS icon_comm_order_type,
                                    cotype.rank AS rank_comm_order_type,
                                    coea.id_comm_order AS id_comm_order,
                                    pk_translation.get_translation(i_lang, coea.code_concept_term) AS desc_comm_order,
                                    coea.concept_path,
                                    pk_alert_constant.g_no AS flg_free_text,
                                    get_num_comm_order_children(i_lang, i_prof, coea.cpt_vrs_uid) AS num_comm_order_children,
                                    0 AS rank,
                                    decode(coq.id_comm_order_questionnaire,
                                           NULL,
                                           pk_alert_constant.g_no,
                                           pk_alert_constant.g_yes) flg_clinical_question
                      FROM comm_order_ea coea
                      JOIN comm_order_type cotype
                        ON coea.id_concept_type = cotype.id_comm_order_type
                       AND coea.id_task_type_conc_term = cotype.id_task_type
                      LEFT JOIN comm_order_questionnaire coq
                        ON coq.id_concept_term = coea.id_concept_term
                       AND coq.id_institution = i_prof.institution
                     WHERE coea.id_market IN (pk_alert_constant.g_id_market_all, l_market)
                       AND coea.id_institution_term_vers IN (pk_alert_constant.g_inst_all, i_prof.institution)
                       AND coea.id_institution_conc_term IN (pk_alert_constant.g_inst_all, i_prof.institution)
                       AND coea.id_software_term_vers IN (pk_alert_constant.g_soft_all, i_prof.software)
                       AND coea.id_software_conc_term IN (pk_alert_constant.g_soft_all, i_prof.software)
                       AND coea.id_category_cncpt_vers IN (pk_ea_logic_comm_orders.k_category_minus_one, l_prof_cat_id)
                       AND coea.id_category_cncpt_term IN (pk_ea_logic_comm_orders.k_category_minus_one, l_prof_cat_id)
                       AND coea.id_concept_type = i_id_comm_order_type
                       AND coea.id_task_type_conc_term = i_task_type
                       AND ((i_id_comm_order_par IS NULL AND coea.cpt_vrs_uid_parent IS NULL) OR
                           (i_id_comm_order_par IS NOT NULL AND
                           coea.cpt_vrs_uid_parent = get_cpt_vrs_uid(i_lang, i_prof, i_id_comm_order_par)))
                    UNION ALL
                    SELECT i_id_comm_order_type AS id_comm_order_type,
                           get_comm_order_type_desc(i_lang, i_prof, i_id_comm_order_type) AS desc_comm_order_type,
                           pk_translation.get_translation(i_lang, cotype.code_icon) AS icon_comm_order_type,
                           cotype.rank AS rank_comm_order_type,
                           NULL AS id_comm_order,
                           pk_message.get_message(i_lang, g_free_text) AS desc_comm_order,
                           NULL AS concept_path,
                           pk_alert_constant.g_yes AS flg_free_text,
                           0 AS num_comm_order_children,
                           1 AS rank,
                           pk_alert_constant.g_no flg_clinical_question
                      FROM comm_order_type cotype
                     WHERE cotype.id_comm_order_type = i_id_comm_order_type
                       AND cotype.id_task_type = i_task_type
                       AND l_cfg_show_free_text_option = pk_alert_constant.g_yes
                       AND i_id_comm_order_par IS NULL) t
             ORDER BY t.rank, upper(desc_comm_order);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_COMM_ORDER_SELECTION_LIST',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_comm_order_selection_list;

    FUNCTION get_comm_order_search
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_comm_order_search IN pk_translation.t_desc_translation,
        o_list              OUT t_cur_comm_order_search,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_prof_cat_id               category.id_category%TYPE := pk_prof_utils.get_id_category(i_lang, i_prof);
        l_market                    market.id_market%TYPE := pk_utils.get_institution_market(i_lang, i_prof.institution);
        l_cfg_show_free_text_option sys_config.value%TYPE := pk_sysconfig.get_config(g_config_show_free_text_option,
                                                                                     i_prof);
    
    BEGIN
    
        g_error := 'OPEN o_list';
        OPEN o_list FOR
            SELECT tt.id_comm_order_type,
                   tt.desc_comm_order_type,
                   tt.icon_comm_order_type,
                   tt.rank_comm_order_type,
                   tt.id_comm_order,
                   tt.desc_comm_order,
                   tt.desc_comm_order_with_path,
                   tt.flg_free_text
              FROM (SELECT t.id_comm_order_type,
                           t.desc_comm_order_type,
                           t.icon_comm_order_type,
                           t.rank_comm_order_type,
                           t.id_comm_order,
                           t.desc_comm_order_type || ' - ' || t.desc_comm_order AS desc_comm_order,
                           t.desc_comm_order_type || ' - ' ||
                           nvl2(t.concept_path,
                                get_comm_order_path_bound_desc(i_lang, i_prof, t.concept_path) || ' > ',
                                '') || t.desc_comm_order AS desc_comm_order_with_path,
                           t.flg_free_text,
                           t.rank
                      FROM (SELECT coea.id_concept_type AS id_comm_order_type,
                                   pk_translation.get_translation(i_lang, coea.code_concept_type_name) AS desc_comm_order_type,
                                   pk_translation.get_translation(i_lang, cotype.code_icon) AS icon_comm_order_type,
                                   cotype.rank AS rank_comm_order_type,
                                   coea.id_comm_order AS id_comm_order,
                                   pk_translation.get_translation(i_lang, coea.code_concept_term) AS desc_comm_order,
                                   coea.concept_path,
                                   pk_alert_constant.g_no AS flg_free_text,
                                   0 AS rank
                              FROM comm_order_ea coea
                              JOIN comm_order_type cotype
                                ON coea.id_concept_type = cotype.id_comm_order_type
                               AND cotype.id_task_type = coea.id_task_type_conc_term
                             WHERE coea.id_market IN (pk_alert_constant.g_id_market_all, l_market)
                               AND coea.id_institution_term_vers IN (pk_alert_constant.g_inst_all, i_prof.institution)
                               AND coea.id_institution_conc_term IN (pk_alert_constant.g_inst_all, i_prof.institution)
                               AND coea.id_software_term_vers IN (pk_alert_constant.g_soft_all, i_prof.software)
                               AND coea.id_software_conc_term IN (pk_alert_constant.g_soft_all, i_prof.software)
                               AND coea.id_category_cncpt_vers IN
                                   (pk_ea_logic_comm_orders.k_category_minus_one, l_prof_cat_id)
                               AND coea.id_category_cncpt_term IN
                                   (pk_ea_logic_comm_orders.k_category_minus_one, l_prof_cat_id)
                               AND get_num_comm_order_children(i_lang, i_prof, coea.cpt_vrs_uid) = 0
                            UNION ALL
                            SELECT cotype.id_comm_order_type AS id_comm_order_type,
                                   get_comm_order_type_desc(i_lang, i_prof, cotype.id_comm_order_type) AS desc_comm_order_type,
                                   pk_translation.get_translation(i_lang, cotype.code_icon) AS icon_comm_order_type,
                                   cotype.rank AS rank_comm_order_type,
                                   NULL AS id_comm_order,
                                   pk_message.get_message(i_lang, g_free_text) AS desc_comm_order,
                                   NULL AS concept_path,
                                   pk_alert_constant.g_yes AS flg_free_text,
                                   1 AS rank
                              FROM comm_order_type cotype
                             WHERE l_cfg_show_free_text_option = pk_alert_constant.g_yes) t) tt
             WHERE dbms_lob.instr(upper(tt.desc_comm_order_with_path), upper(i_comm_order_search)) != 0
             ORDER BY tt.rank, CAST(upper(tt.desc_comm_order_with_path) AS VARCHAR2(1000 CHAR));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_COMM_ORDER_SEARCH',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_comm_order_search;

    FUNCTION get_clinical_purpose
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'OPEN o_list';
        OPEN o_list FOR
            SELECT /*+opt_estimate (table t rows=1)*/
             val data, rank, desc_val label, NULL flg_default
              FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang, i_prof, g_code_clinical_purpose, NULL)) t
             WHERE val IN ('N', 'O')
            UNION ALL
            SELECT t.data, t.rank, t.label, NULL flg_default
              FROM (SELECT /*+opt_estimate (table t rows=1)*/
                     val data, desc_val label, row_number() over(ORDER BY desc_val) AS rank
                      FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang, i_prof, g_code_clinical_purpose, NULL)) t
                     WHERE val NOT IN ('N', 'O')) t
             ORDER BY rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_CLINICAL_PURPOSE',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_clinical_purpose;

    FUNCTION get_priority
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'Init';
        OPEN o_list FOR
            SELECT /*+opt_estimate (table t rows=1)*/
             val data, rank, desc_val label, NULL flg_default
              FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang, i_prof, g_code_priority, NULL)) t
             ORDER BY rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_PRIORITY',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_priority;

    FUNCTION get_prn
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'Init';
        OPEN o_list FOR
            SELECT /*+opt_estimate (table t rows=1)*/
             val data, rank, desc_val label, NULL flg_default
              FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang, i_prof, g_code_prn, NULL)) t
             ORDER BY rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_PRN',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_prn;

    FUNCTION get_diagnoses_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_search_diagnosis sys_config.value%TYPE := pk_sysconfig.get_config('PERMISSION_FOR_SEARCH_DIAGNOSIS', i_prof);
    
        l_profile_template profile_template.id_profile_template%TYPE := pk_prof_utils.get_prof_profile_template(i_prof);
    
        l_tbl_diags t_coll_diagnosis_config := t_coll_diagnosis_config();
    
    BEGIN
    
        IF i_episode IS NOT NULL
        THEN
            l_tbl_diags := pk_diagnosis.get_associated_diagnosis_tf(i_lang, i_prof, i_episode, pk_alert_constant.g_yes);
        END IF;
    
        g_error := 'OPEN o_list FOR';
        OPEN o_list FOR
            SELECT id_epis_diagnosis, id_diagnosis, id_alert_diagnosis, code_icd, desc_diagnosis, rank, flg_other
              FROM (SELECT NULL id_diagnosis,
                           pk_message.get_message(i_lang, i_prof, 'COMM_ORDER_M003') desc_diagnosis,
                           NULL code_icd,
                           NULL flg_other,
                           1 rank,
                           NULL id_alert_diagnosis,
                           NULL id_epis_diagnosis
                      FROM dual
                     WHERE instr(nvl(l_search_diagnosis, '#'), l_profile_template) != 0
                    UNION ALL
                    SELECT /*+opt_estimate (table t rows=1)*/
                     t.id_diagnosis,
                     t.desc_diagnosis,
                     t.code_icd,
                     t.flg_other,
                     0 rank,
                     t.id_alert_diagnosis,
                     t.id_epis_diagnosis
                      FROM TABLE(l_tbl_diags) t)
             ORDER BY rank ASC, desc_diagnosis ASC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_DIAGNOSES_LIST',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_diagnoses_list;

    FUNCTION get_instructions_default
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_comm_order      IN table_number,
        i_id_comm_order_type IN table_number,
        o_list               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_market           institution.id_market%TYPE;
        l_id_category         category.id_category%TYPE;
        l_id_profile_template profile_template.id_profile_template%TYPE;
        l_comm_order_tab      t_coll_comm_order_obj;
    
    BEGIN
    
        l_comm_order_tab := t_coll_comm_order_obj();
        l_comm_order_tab.extend(i_id_comm_order.count);
    
        l_id_market           := pk_utils.get_institution_market(i_lang           => i_lang,
                                                                 i_id_institution => i_prof.institution);
        l_id_category         := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
        l_id_profile_template := pk_tools.get_prof_profile_template(i_prof);
    
        g_error := 'FOR i IN 1 .. ' || i_id_comm_order.count;
        FOR i IN 1 .. i_id_comm_order.count
        LOOP
            l_comm_order_tab(i) := t_rec_comm_order_obj();
            l_comm_order_tab(i).id_comm_order := i_id_comm_order(i);
            l_comm_order_tab(i).id_comm_order_type := i_id_comm_order_type(i);
        END LOOP;
    
        g_error := 'OPEN o_list FOR';
        OPEN o_list FOR
            SELECT t.id_comm_order,
                   t.id_comm_order_type,
                   t.notes,
                   t.flg_priority,
                   pk_sysdomain.get_domain(i_code_dom => g_code_priority, i_val => t.flg_priority, i_lang => i_lang) desc_priority,
                   t.flg_prn,
                   pk_sysdomain.get_domain(i_code_dom => g_code_prn, i_val => t.flg_prn, i_lang => i_lang) desc_prn,
                   t.prn_condition,
                   pk_date_utils.date_send_tsz(i_lang, (current_timestamp + t.start_interval), i_prof) dt_begin
              FROM (SELECT tt.id_comm_order,
                           tt.id_comm_order_type,
                           coidm.notes,
                           coidm.flg_priority,
                           coidm.flg_prn,
                           coidm.prn_condition,
                           coidm.start_interval,
                           row_number() over(PARTITION BY tt.id_comm_order, tt.id_comm_order_type ORDER BY coidm.id_market DESC, coidm.id_institution DESC, coidm.id_software DESC, coidm.id_category DESC, coidm.id_profile_template DESC, coidm.id_concept_type DESC NULLS LAST, coidm.id_concept_term DESC NULLS LAST, coidm.id_concept_version DESC NULLS LAST) AS rn
                      FROM comm_order_instr_def_msi coidm
                      LEFT JOIN comm_order_ea ea
                        ON (ea.id_concept_type = coidm.id_concept_type AND
                           ea.id_concept_version = coidm.id_concept_version AND
                           ea.id_cncpt_vrs_inst_owner = coidm.id_cncpt_vrs_inst_owner AND
                           ea.id_concept_term = coidm.id_concept_term AND
                           ea.id_cncpt_trm_inst_owner = coidm.id_cncpt_trm_inst_owner)
                      JOIN (SELECT /*+opt_estimate (table t rows=1)*/
                           DISTINCT t.id_comm_order, t.id_comm_order_type
                             FROM TABLE(CAST(l_comm_order_tab AS t_coll_comm_order_obj)) t) tt
                        ON (((ea.id_comm_order IS NULL AND coidm.id_concept_version IS NULL AND
                           coidm.id_cncpt_vrs_inst_owner IS NULL AND coidm.id_concept_term IS NULL AND
                           coidm.id_cncpt_trm_inst_owner IS NULL) OR
                           (ea.id_comm_order IS NOT NULL AND tt.id_comm_order = ea.id_comm_order)) AND
                           tt.id_comm_order_type = nvl(coidm.id_concept_type, tt.id_comm_order_type))
                       AND coidm.id_market IN (l_id_market, 0)
                       AND coidm.id_institution IN (i_prof.institution, 0)
                       AND coidm.id_software IN (i_prof.software, 0)
                       AND nvl(coidm.id_category, 0) IN (l_id_category, 0)
                       AND coidm.id_profile_template IN (l_id_profile_template, 0)) t
             WHERE rn = 1;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_INSTRUCTIONS_DEFAULT',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_instructions_default;

    FUNCTION init_param_tab
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_comm_order_req IN comm_order_req.id_comm_order_req%TYPE,
        i_dt_begin          IN comm_order_req.dt_begin%TYPE
    ) RETURN table_varchar IS
    
        l_result table_varchar;
    
    BEGIN
    
        g_error  := 'Init init_param_tab / ';
        l_result := table_varchar();
        l_result.extend(2);
    
        l_result(g_idx_id_comm_order_req) := i_id_comm_order_req;
        l_result(g_idx_dt_begin) := pk_date_utils.to_char_insttimezone(i_prof, i_dt_begin, g_idx_dt_begin_mask);
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END init_param_tab;

    FUNCTION get_param_values
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_param             IN table_varchar,
        o_id_comm_order_req OUT comm_order_req.id_comm_order_req%TYPE,
        o_dt_begin          OUT comm_order_req.dt_begin%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dt_begin_v VARCHAR2(50 CHAR);
    
    BEGIN
    
        g_error := 'Init';
        IF i_param.exists(g_idx_id_comm_order_req)
        THEN
            -- id_comm_order_req
            o_id_comm_order_req := to_number(i_param(g_idx_id_comm_order_req));
        END IF;
    
        IF i_param.exists(g_idx_dt_begin)
        THEN
            -- dt_begin
            g_error      := 'l_dt_begin_v';
            l_dt_begin_v := i_param(g_idx_dt_begin);
        
            g_error    := 'l_dt_begin_v=' || l_dt_begin_v || ' / ';
            o_dt_begin := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                        i_prof      => i_prof,
                                                        i_timestamp => l_dt_begin_v,
                                                        i_timezone  => NULL,
                                                        i_mask      => g_idx_dt_begin_mask);
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
                                              i_function => 'GET_PARAM_VALUES',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_param_values;

    FUNCTION can_complete
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_workflow        IN wf_transition_config.id_workflow%TYPE,
        i_status_begin    IN wf_transition_config.id_status_begin%TYPE,
        i_status_end      IN wf_transition_config.id_status_end%TYPE,
        i_workflow_action IN wf_transition_config.id_workflow_action%TYPE,
        i_category        IN wf_transition_config.id_category%TYPE,
        i_profile         IN wf_transition_config.id_profile_template%TYPE,
        i_func            IN wf_transition_config.id_functionality%TYPE,
        i_param           IN table_varchar
    ) RETURN VARCHAR2 IS
    
        l_error             t_error_out;
        l_result            VARCHAR2(1 CHAR);
        l_check_date        VARCHAR2(1 CHAR);
        l_id_comm_order_req comm_order_req.id_comm_order_req%TYPE;
        l_dt_begin          comm_order_req.dt_begin%TYPE;
        l_count             PLS_INTEGER;
        l_id_task_type      comm_order_req.id_task_type%TYPE;
    
    BEGIN
        g_error  := 'Init';
        l_result := pk_workflow.g_transition_deny;
    
        g_retval := get_param_values(i_lang              => i_lang,
                                     i_prof              => i_prof,
                                     i_param             => i_param,
                                     o_id_comm_order_req => l_id_comm_order_req,
                                     o_dt_begin          => l_dt_begin,
                                     o_error             => l_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := 'Getting task type';
        SELECT cor.id_task_type
          INTO l_id_task_type
          FROM comm_order_req cor
         WHERE cor.id_comm_order_req = l_id_comm_order_req;
    
        g_error      := 'Call pk_date_utils.compare_dates_tsz';
        l_check_date := pk_date_utils.compare_dates_tsz(i_prof  => i_prof,
                                                        i_date1 => current_timestamp,
                                                        i_date2 => l_dt_begin);
    
        IF l_id_task_type = pk_alert_constant.g_task_medical_orders
           OR (l_id_task_type = pk_alert_constant.g_task_comm_orders AND
           pk_sysconfig.get_config(i_code_cf => g_comm_order_exec_workflow, i_prof => i_prof) =
           pk_alert_constant.g_yes)
        THEN
            l_result := pk_workflow.g_transition_allow;
        ELSIF l_check_date = pk_alert_constant.g_date_greater
        THEN
            -- comm order has started, check acknowledges first
            g_error := 'SELECT COUNT(1)';
            SELECT COUNT(1)
              INTO l_count
              FROM comm_order_req_ack cora
             WHERE cora.id_comm_order_req = l_id_comm_order_req;
        
            IF l_count > 0
            THEN
                -- there were acknowledges done to this comm_order_req, can discontinue
                l_result := pk_workflow.g_transition_allow;
            END IF;
        END IF;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN pk_workflow.g_transition_deny;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'CAN_COMPLETE',
                                              o_error    => l_error);
            RETURN pk_workflow.g_transition_deny;
    END can_complete;

    FUNCTION can_cancel
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_workflow        IN wf_transition_config.id_workflow%TYPE,
        i_status_begin    IN wf_transition_config.id_status_begin%TYPE,
        i_status_end      IN wf_transition_config.id_status_end%TYPE,
        i_workflow_action IN wf_transition_config.id_workflow_action%TYPE,
        i_category        IN wf_transition_config.id_category%TYPE,
        i_profile         IN wf_transition_config.id_profile_template%TYPE,
        i_func            IN wf_transition_config.id_functionality%TYPE,
        i_param           IN table_varchar
    ) RETURN VARCHAR2 IS
    
        l_error             t_error_out;
        l_result            VARCHAR2(1 CHAR);
        l_check_date        VARCHAR2(1 CHAR);
        l_id_comm_order_req comm_order_req.id_comm_order_req%TYPE;
        l_dt_begin          comm_order_req.dt_begin%TYPE;
    
    BEGIN
    
        g_error  := 'Init ';
        l_result := pk_workflow.g_transition_deny;
    
        g_retval := get_param_values(i_lang              => i_lang,
                                     i_prof              => i_prof,
                                     i_param             => i_param,
                                     o_id_comm_order_req => l_id_comm_order_req,
                                     o_dt_begin          => l_dt_begin,
                                     o_error             => l_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error      := 'Call pk_date_utils.compare_dates_tsz / ';
        l_check_date := pk_date_utils.compare_dates_tsz(i_prof  => i_prof,
                                                        i_date1 => current_timestamp,
                                                        i_date2 => l_dt_begin);
    
        l_result := pk_workflow.g_transition_allow;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN pk_workflow.g_transition_deny;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'CAN_CANCEL',
                                              o_error    => l_error);
            RETURN pk_workflow.g_transition_deny;
    END can_cancel;

    FUNCTION check_transition
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_workflow         IN comm_order_req.id_workflow%TYPE,
        i_id_status_begin     IN comm_order_req.id_status%TYPE,
        i_id_status_end       IN comm_order_req.id_status%TYPE,
        i_id_workflow_action  IN wf_workflow_action.id_workflow_action%TYPE,
        i_id_category         IN category.id_category%TYPE,
        i_id_profile_template IN profile_template.id_profile_template%TYPE,
        i_id_comm_order_req   IN comm_order_req.id_comm_order_req%TYPE,
        i_dt_begin            IN comm_order_req.dt_begin%TYPE
    ) RETURN VARCHAR2 IS
    
        l_error               t_error_out;
        l_wf_param            table_varchar;
        l_dt_begin            comm_order_req.dt_begin%TYPE;
        l_id_category         category.id_category%TYPE;
        l_id_profile_template profile_template.id_profile_template%TYPE;
        l_result              VARCHAR2(1 CHAR);
    
    BEGIN
    
        l_result := pk_alert_constant.g_no;
    
        -- func
        IF i_dt_begin IS NULL
        THEN
            l_dt_begin := get_comm_order_req_dt_b(i_lang              => i_lang,
                                                  i_prof              => i_prof,
                                                  i_id_comm_order_req => i_id_comm_order_req);
        ELSE
            l_dt_begin := i_dt_begin;
        END IF;
    
        l_id_category         := nvl(i_id_category, pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof));
        l_id_profile_template := nvl(i_id_profile_template, pk_tools.get_prof_profile_template(i_prof));
    
        -- check workflow permission
        g_error    := 'Call init_param_tab / ';
        l_wf_param := init_param_tab(i_lang              => i_lang,
                                     i_prof              => i_prof,
                                     i_id_comm_order_req => i_id_comm_order_req,
                                     i_dt_begin          => l_dt_begin);
    
        g_error  := 'Call pk_workflow.check_transition / i_param=' || pk_utils.to_string(l_wf_param);
        g_retval := pk_workflow.check_transition(i_lang                => i_lang,
                                                 i_prof                => i_prof,
                                                 i_id_workflow         => i_id_workflow,
                                                 i_id_status_begin     => i_id_status_begin,
                                                 i_id_status_end       => i_id_status_end,
                                                 i_id_workflow_action  => i_id_workflow_action,
                                                 i_id_category         => l_id_category,
                                                 i_id_profile_template => l_id_profile_template,
                                                 i_id_functionality    => NULL,
                                                 i_param               => l_wf_param,
                                                 o_flg_available       => l_result,
                                                 o_error               => l_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN pk_alert_constant.g_no;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'CHECK_TRANSITION',
                                              o_error    => l_error);
            RETURN pk_alert_constant.g_no;
    END check_transition;

    FUNCTION check_acknowledge
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_id_status IN comm_order_req.id_status%TYPE,
        i_dt_begin     IN comm_order_req.dt_begin%TYPE
    ) RETURN VARCHAR2 IS
    
        l_error  t_error_out;
        l_result VARCHAR2(1 CHAR);
    
    BEGIN
    
        g_error  := 'Init ';
        l_result := pk_alert_constant.g_yes;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN pk_alert_constant.g_no;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'CHECK_ACKNOWLEDGE',
                                              o_error    => l_error);
            RETURN pk_alert_constant.g_no;
    END check_acknowledge;

    FUNCTION check_edit
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_workflow         IN comm_order_req.id_workflow%TYPE,
        i_id_status           IN comm_order_req.id_status%TYPE,
        i_id_category         IN category.id_category%TYPE,
        i_id_profile_template IN profile_template.id_profile_template%TYPE,
        i_id_comm_order_req   IN comm_order_req.id_comm_order_req%TYPE,
        i_dt_begin            IN comm_order_req.dt_begin%TYPE
    ) RETURN VARCHAR2 IS
    
        l_error               t_error_out;
        l_result              VARCHAR2(1 CHAR);
        l_wf_param            table_varchar;
        l_dt_begin            comm_order_req.dt_begin%TYPE;
        l_id_category         category.id_category%TYPE;
        l_id_profile_template profile_template.id_profile_template%TYPE;
        l_rec_status_info     t_rec_wf_status_info;
        l_count               NUMBER := 0;
    
    BEGIN
    
        IF i_dt_begin IS NULL
        THEN
            l_dt_begin := get_comm_order_req_dt_b(i_lang              => i_lang,
                                                  i_prof              => i_prof,
                                                  i_id_comm_order_req => i_id_comm_order_req);
        ELSE
            l_dt_begin := i_dt_begin;
        END IF;
    
        l_id_category         := nvl(i_id_category, pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof));
        l_id_profile_template := nvl(i_id_profile_template, pk_tools.get_prof_profile_template(i_prof));
    
        g_error    := 'Call init_param_tab / ';
        l_wf_param := init_param_tab(i_lang              => i_lang,
                                     i_prof              => i_prof,
                                     i_id_comm_order_req => i_id_comm_order_req,
                                     i_dt_begin          => l_dt_begin);
    
        --Check if there's already any execution performed
        --If there is, it will no longer be possible to cancel the requisition
        SELECT COUNT(1)
          INTO l_count
          FROM comm_order_plan c
         WHERE c.id_comm_order_req IN (i_id_comm_order_req)
           AND c.flg_status NOT IN (g_comm_order_plan_req, g_comm_order_plan_cancel);
    
        IF l_count > 0
        THEN
            l_result := pk_alert_constant.g_no;
        ELSE
        
            -- get status info
            g_error           := 'Call pk_workflow.get_status_info / ';
            l_rec_status_info := pk_workflow.get_status_info(i_lang                => i_lang,
                                                             i_prof                => i_prof,
                                                             i_id_workflow         => i_id_workflow,
                                                             i_id_status           => i_id_status,
                                                             i_id_category         => l_id_category,
                                                             i_id_profile_template => l_id_profile_template,
                                                             i_id_functionality    => NULL,
                                                             i_param               => l_wf_param);
        
            l_result := l_rec_status_info.get_flg_update();
        
        END IF;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN pk_alert_constant.g_no;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'CHECK_EDIT',
                                              o_error    => l_error);
            RETURN pk_alert_constant.g_no;
    END check_edit;

    FUNCTION check_action_active
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_action         IN action.id_action%TYPE,
        i_internal_name     IN action.internal_name%TYPE,
        i_id_comm_order_req IN table_number
    ) RETURN VARCHAR2 IS
    
        l_error  t_error_out;
        l_result VARCHAR2(1 CHAR);
    
        l_comm_order_req      t_coll_comm_order_req;
        l_id_category         category.id_category%TYPE;
        l_id_profile_template profile_template.id_profile_template%TYPE;
        l_count               PLS_INTEGER;
    
        l_sys_cfg_old_wf sys_config.value%TYPE := pk_sysconfig.get_config(i_prof    => i_prof,
                                                                          i_code_cf => 'COMMUNICATION_ORDERS_SCREEN_NEW');
    
    BEGIN
    
        l_result := pk_alert_constant.g_no;
    
        -- func
        l_id_category         := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
        l_id_profile_template := pk_tools.get_prof_profile_template(i_prof);
    
        -- get comm order reqs data
        g_error  := 'Call get_comm_order_req_rows / ';
        g_retval := get_comm_order_req_rows(i_lang              => i_lang,
                                            i_prof              => i_prof,
                                            i_id_comm_order_req => i_id_comm_order_req,
                                            o_row_tab           => l_comm_order_req,
                                            o_error             => l_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- loop throught all comm order reqs
        FOR i IN 1 .. l_comm_order_req.count
        LOOP
        
            g_error := 'CASE / ';
            CASE i_internal_name
                WHEN 'ACK' THEN
                    l_result := check_acknowledge(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  i_id_id_status => l_comm_order_req(i).id_status,
                                                  i_dt_begin     => l_comm_order_req(i).dt_begin);
                
                WHEN 'EDIT' THEN
                    l_result := check_edit(i_lang                => i_lang,
                                           i_prof                => i_prof,
                                           i_id_workflow         => l_comm_order_req(i).id_workflow,
                                           i_id_status           => l_comm_order_req(i).id_status,
                                           i_id_category         => l_id_category,
                                           i_id_profile_template => l_id_profile_template,
                                           i_id_comm_order_req   => l_comm_order_req(i).id_comm_order_req,
                                           i_dt_begin            => l_comm_order_req(i).dt_begin);
                WHEN 'EXECUTE' THEN
                
                    IF l_comm_order_req(i).id_status IN (g_id_sts_canceled, g_id_sts_completed, g_id_sts_discontinued)
                    THEN
                        l_result := pk_alert_constant.g_no;
                    ELSE
                        l_result := pk_alert_constant.g_yes;
                    END IF;
                
                    IF (l_comm_order_req(i).id_task_type = pk_cpoe.g_task_type_com_order OR l_comm_order_req(i).id_task_type IS NULL)
                       AND l_sys_cfg_old_wf = pk_alert_constant.g_no
                    THEN
                        l_result := pk_alert_constant.g_no;
                    END IF;
                
                ELSE
                    -- CANCEL, COMPLETE
                    g_error := 'Call PK_WORKFLOW.get_wf_action_trans / ';
                    SELECT /*+opt_estimate (table t rows=1)*/
                     COUNT(1)
                      INTO l_count
                      FROM TABLE(CAST(pk_workflow.get_wf_action_trans(i_lang            => i_lang,
                                                                      i_prof            => i_prof,
                                                                      i_action          => i_id_action,
                                                                      i_id_workflow     => l_comm_order_req(i).id_workflow,
                                                                      i_id_status_begin => l_comm_order_req(i).id_status) AS
                                      t_coll_wf_action)) t
                     WHERE check_transition(i_lang                => i_lang,
                                            i_prof                => i_prof,
                                            i_id_workflow         => t.id_workflow,
                                            i_id_status_begin     => t.id_status_begin,
                                            i_id_status_end       => t.id_status_end,
                                            i_id_workflow_action  => t.id_workflow_action,
                                            i_id_category         => l_id_category,
                                            i_id_profile_template => l_id_profile_template,
                                            i_id_comm_order_req   => l_comm_order_req(i).id_comm_order_req,
                                            i_dt_begin            => l_comm_order_req(i).dt_begin) =
                           pk_alert_constant.g_yes;
                
                    IF l_count > 0
                    THEN
                        l_result := pk_alert_constant.g_yes;
                    ELSE
                        l_result := pk_alert_constant.g_no;
                    END IF;
                
            END CASE;
        
            -- if this action is inactive for at least one comm order, then exit loop and inactive this action for all comm orders selection
            IF l_result = pk_alert_constant.g_no
            THEN
                EXIT;
            END IF;
        
        END LOOP;
    
        -- convert yes and no to active and inactive
        g_error := 'l_result=' || l_result;
        IF l_result = pk_alert_constant.g_yes
        THEN
            l_result := pk_alert_constant.g_active;
        ELSIF l_result = pk_alert_constant.g_no
        THEN
            l_result := pk_alert_constant.g_inactive;
        END IF;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN pk_alert_constant.g_inactive;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'CHECK_ACTION_ACTIVE',
                                              o_error    => l_error);
            RETURN pk_alert_constant.g_inactive;
    END check_action_active;

    FUNCTION check_parameters
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_task_type    IN task_type.id_task_type%TYPE,
        i_id_concept_term IN comm_order_req.id_concept_term%TYPE
    ) RETURN VARCHAR2 IS
    
        l_error  t_error_out;
        l_result VARCHAR2(1 CHAR);
    
        l_count PLS_INTEGER;
    
    BEGIN
    
        l_result := pk_alert_constant.g_no;
    
        SELECT COUNT(*)
          INTO l_count
          FROM po_param_sets pps
         WHERE pps.id_task_type = i_id_task_type
           AND pps.task_type_content = (SELECT coe.concept_code
                                          FROM comm_order_ea coe
                                         WHERE coe.id_concept_term = i_id_concept_term
                                           AND coe.id_institution_conc_term = i_prof.institution
                                           AND coe.id_software_conc_term = i_prof.software
                                           AND coe.id_task_type_conc_term = i_id_task_type
                                           AND rownum = 1)
           AND pps.id_software IN (0, i_prof.software)
           AND pps.id_institution IN (0, i_prof.institution);
    
        IF l_count > 0
        THEN
            l_result := pk_alert_constant.g_yes;
        END IF;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'CHECK_PARAMETERS',
                                              o_error    => l_error);
            RETURN pk_alert_constant.g_no;
    END check_parameters;

    FUNCTION get_comm_order_req_ids
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_visit           IN episode.id_visit%TYPE DEFAULT NULL,
        i_id_patient         IN comm_order_req.id_patient%TYPE DEFAULT NULL,
        i_id_episode         IN comm_order_req.id_episode%TYPE DEFAULT NULL,
        i_id_status          IN comm_order_req.id_status%TYPE DEFAULT NULL,
        i_id_status_exclude  IN table_number DEFAULT table_number(),
        i_tbl_task_type      IN table_number DEFAULT table_number(),
        o_comm_order_req_tab OUT table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_req IS
            WITH comm_order_req_w AS
             (SELECT *
                FROM comm_order_req cor
               WHERE cor.id_episode IN (SELECT id_episode
                                          FROM episode e
                                         WHERE id_visit = i_id_visit)
                 AND i_id_visit IS NOT NULL
              UNION
              SELECT *
                FROM comm_order_req cor
               WHERE cor.id_episode = i_id_episode
                 AND i_id_episode IS NOT NULL
              UNION
              SELECT *
                FROM comm_order_req cor
               WHERE cor.id_patient = i_id_patient
                 AND i_id_patient IS NOT NULL)
            SELECT id_comm_order_req
              FROM (SELECT cor.id_comm_order_req, cor.id_status
                      FROM comm_order_req_w cor
                     WHERE cor.id_task_type IN
                           (SELECT /*+ opt_estimate (table t1 rows=1) */
                             *
                              FROM TABLE(CAST(i_tbl_task_type AS table_number)) t1)
                       AND NOT EXISTS (SELECT /*+ opt_estimate (table t2 rows=1) */
                             1
                              FROM TABLE(CAST(i_id_status_exclude AS table_number)) t2
                             WHERE t2.column_value = cor.id_status)
                       AND rownum > 0) t
             WHERE t.id_status = nvl(i_id_status, t.id_status);
    
    BEGIN
    
        o_comm_order_req_tab := table_number();
    
        g_error := 'OPEN c_req ';
        OPEN c_req;
        FETCH c_req BULK COLLECT
            INTO o_comm_order_req_tab;
        CLOSE c_req;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_COMM_ORDER_REQ_IDS',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_comm_order_req_ids;

    FUNCTION set_comm_order_req_h
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_comm_order_req_row IN t_rec_comm_order_req,
        o_id_hist            OUT comm_order_req_hist.id_comm_order_req_hist%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'Init ';
        INSERT INTO comm_order_req_hist
            (id_comm_order_req_hist,
             id_comm_order_req,
             id_workflow,
             id_status,
             id_patient,
             id_episode,
             id_concept_type,
             id_concept_version,
             id_cncpt_vrs_inst_owner,
             id_concept_term,
             id_cncpt_trm_inst_owner,
             flg_free_text,
             desc_concept_term,
             id_prof_req,
             id_inst_req,
             dt_req,
             notes,
             clinical_indication,
             flg_clinical_purpose,
             clinical_purpose_desc,
             flg_priority,
             flg_prn,
             prn_condition,
             dt_begin,
             id_professional,
             id_institution,
             dt_status,
             notes_cancel,
             id_cancel_reason,
             flg_need_ack,
             flg_action,
             id_previous_status,
             id_order_recurr,
             task_duration,
             id_task_type)
        VALUES
            (seq_comm_order_req_hist.nextval,
             i_comm_order_req_row.id_comm_order_req,
             i_comm_order_req_row.id_workflow,
             i_comm_order_req_row.id_status,
             i_comm_order_req_row.id_patient,
             i_comm_order_req_row.id_episode,
             i_comm_order_req_row.id_concept_type,
             i_comm_order_req_row.id_concept_version,
             i_comm_order_req_row.id_cncpt_vrs_inst_owner,
             i_comm_order_req_row.id_concept_term,
             i_comm_order_req_row.id_cncpt_trm_inst_owner,
             i_comm_order_req_row.flg_free_text,
             i_comm_order_req_row.desc_concept_term,
             i_comm_order_req_row.id_prof_req,
             i_comm_order_req_row.id_inst_req,
             i_comm_order_req_row.dt_req,
             i_comm_order_req_row.notes,
             i_comm_order_req_row.clinical_indication,
             i_comm_order_req_row.flg_clinical_purpose,
             i_comm_order_req_row.clinical_purpose_desc,
             i_comm_order_req_row.flg_priority,
             i_comm_order_req_row.flg_prn,
             i_comm_order_req_row.prn_condition,
             i_comm_order_req_row.dt_begin,
             i_comm_order_req_row.id_professional,
             i_comm_order_req_row.id_institution,
             i_comm_order_req_row.dt_status,
             i_comm_order_req_row.notes_cancel,
             i_comm_order_req_row.id_cancel_reason,
             i_comm_order_req_row.flg_need_ack,
             i_comm_order_req_row.flg_action,
             i_comm_order_req_row.id_previous_status,
             i_comm_order_req_row.id_order_recurr,
             i_comm_order_req_row.task_duration,
             i_comm_order_req_row.id_task_type)
        RETURNING id_comm_order_req_hist INTO o_id_hist;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_COMM_ORDER_REQ_H',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_comm_order_req_h;

    FUNCTION get_actual_cs_info
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN comm_order_req.id_episode%TYPE,
        i_id_comm_order_req IN comm_order_req.id_comm_order_req%TYPE
    ) RETURN t_table_co_sign IS
    
        l_error        t_error_out;
        l_co_sign_info t_table_co_sign := t_table_co_sign();
        l_task_type    task_type.id_task_type%TYPE;
    
    BEGIN
    
        SELECT cor.id_task_type
          INTO l_task_type
          FROM comm_order_req cor
         WHERE cor.id_comm_order_req = i_id_comm_order_req;
    
        -- func
        -- gets the most recent co-sign data of:
        -- - order or edition co-signs
        -- - cancellation co-sign (if available)
        -- - discontinuation co-sign (if available)
        g_error := 'SELECT t_rec_co_sign() / ';
        SELECT t_rec_co_sign(id_co_sign           => cs.id_co_sign,
                             id_co_sign_hist      => cs.id_co_sign_hist,
                             id_episode           => cs.id_episode,
                             id_task              => cs.id_task,
                             id_task_group        => cs.id_task_group,
                             id_task_type         => cs.id_task_type,
                             desc_task_type       => cs.desc_task_type,
                             icon_task_type       => cs.icon_task_type,
                             id_action            => cs.id_action,
                             desc_action          => cs.desc_action,
                             id_task_type_action  => cs.id_task_type_action,
                             desc_order           => cs.desc_order,
                             desc_instructions    => cs.desc_instructions,
                             desc_task_action     => cs.desc_task_action,
                             id_order_type        => cs.id_order_type,
                             desc_order_type      => cs.desc_order_type,
                             id_prof_created      => cs.id_prof_created,
                             id_prof_ordered_by   => cs.id_prof_ordered_by,
                             desc_prof_ordered_by => cs.desc_prof_ordered_by,
                             id_prof_co_signed    => cs.id_prof_co_signed,
                             dt_req               => cs.dt_req,
                             dt_created           => cs.dt_created,
                             dt_ordered_by        => cs.dt_ordered_by,
                             dt_co_signed         => cs.dt_co_signed,
                             dt_exec_date_sort    => cs.dt_exec_date_sort,
                             flg_status           => cs.flg_status,
                             icon_status          => cs.icon_status,
                             desc_status          => cs.desc_status,
                             code_co_sign_notes   => cs.code_co_sign_notes,
                             co_sign_notes        => cs.co_sign_notes,
                             flg_has_notes        => cs.flg_has_notes,
                             flg_needs_cosign     => cs.flg_needs_cosign,
                             flg_has_cosign       => cs.flg_has_cosign,
                             flg_made_auth        => cs.flg_made_auth)
          BULK COLLECT
          INTO l_co_sign_info
          FROM (SELECT /*+opt_estimate (table t rows=1)*/
                 row_number() over(PARTITION BY(CASE id_action
                     WHEN g_cs_action_edit THEN
                      g_cs_action_add -- treats edition co-sign like an order co-sign
                     ELSE
                      id_action
                 END) ORDER BY dt_req DESC) rn,
                 t.*
                  FROM TABLE(pk_co_sign_api.tf_co_sign_tasks_info(i_lang          => i_lang,
                                                                  i_prof          => i_prof,
                                                                  i_episode       => i_id_episode,
                                                                  i_task_type     => l_task_type,
                                                                  i_id_task_group => i_id_comm_order_req)) t
                 WHERE t.flg_status != pk_co_sign_api.g_cosign_flg_status_o) cs
         WHERE cs.rn = 1;
    
        RETURN l_co_sign_info;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN l_co_sign_info;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_ACTUAL_CS_INFO',
                                              o_error    => l_error);
            RETURN l_co_sign_info;
    END get_actual_cs_info;

    FUNCTION check_if_acknowledged
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_comm_order_req      IN comm_order_req.id_comm_order_req%TYPE,
        i_id_comm_order_req_hist IN comm_order_req_hist.id_comm_order_req_hist%TYPE
    ) RETURN VARCHAR2 IS
    
        l_count PLS_INTEGER;
        l_error t_error_out;
    
        CURSOR c_cor_ack IS
            SELECT COUNT(1)
              FROM comm_order_req_hist corh
              JOIN comm_order_req_ack cora
                ON cora.id_comm_order_req_hist = corh.id_comm_order_req_hist
             WHERE corh.id_comm_order_req = i_id_comm_order_req
               AND corh.dt_status > (SELECT corh2.dt_status
                                       FROM comm_order_req_hist corh2
                                      WHERE corh2.id_comm_order_req = corh.id_comm_order_req
                                        AND corh2.id_comm_order_req_hist = i_id_comm_order_req_hist);
    BEGIN
    
        OPEN c_cor_ack;
        FETCH c_cor_ack
            INTO l_count;
        CLOSE c_cor_ack;
    
        IF l_count = 0
        THEN
            RETURN pk_alert_constant.g_no;
        ELSE
            RETURN pk_alert_constant.g_yes;
        END IF;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN pk_alert_constant.g_no;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'CHECK_IF_ACKNOWLEDGED',
                                              o_error    => l_error);
            RETURN pk_alert_constant.g_no;
    END check_if_acknowledged;

    FUNCTION get_last_cs_info
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN comm_order_req.id_episode%TYPE,
        i_id_comm_order_req IN comm_order_req.id_comm_order_req%TYPE,
        i_flg_not_ack       IN VARCHAR2,
        i_tab_id_actions    IN table_number
    ) RETURN t_rec_co_sign IS
    
        l_error        t_error_out;
        l_co_sign_info t_rec_co_sign := t_rec_co_sign();
        l_id_task_type task_type.id_task_type%TYPE;
    
    BEGIN
    
        SELECT cor.id_task_type
          INTO l_id_task_type
          FROM comm_order_req cor
         WHERE cor.id_comm_order_req = i_id_comm_order_req;
    
        SELECT t_rec_co_sign(id_co_sign           => cs.id_co_sign,
                             id_co_sign_hist      => cs.id_co_sign_hist,
                             id_episode           => cs.id_episode,
                             id_task              => cs.id_task,
                             id_task_group        => cs.id_task_group,
                             id_task_type         => cs.id_task_type,
                             desc_task_type       => cs.desc_task_type,
                             icon_task_type       => cs.icon_task_type,
                             id_action            => cs.id_action,
                             desc_action          => cs.desc_action,
                             id_task_type_action  => cs.id_task_type_action,
                             desc_order           => cs.desc_order,
                             desc_instructions    => cs.desc_instructions,
                             desc_task_action     => cs.desc_task_action,
                             id_order_type        => cs.id_order_type,
                             desc_order_type      => cs.desc_order_type,
                             id_prof_created      => cs.id_prof_created,
                             id_prof_ordered_by   => cs.id_prof_ordered_by,
                             desc_prof_ordered_by => cs.desc_prof_ordered_by,
                             id_prof_co_signed    => cs.id_prof_co_signed,
                             dt_req               => cs.dt_req,
                             dt_created           => cs.dt_created,
                             dt_ordered_by        => cs.dt_ordered_by,
                             dt_co_signed         => cs.dt_co_signed,
                             dt_exec_date_sort    => cs.dt_exec_date_sort,
                             flg_status           => cs.flg_status,
                             icon_status          => cs.icon_status,
                             desc_status          => cs.desc_status,
                             code_co_sign_notes   => cs.code_co_sign_notes,
                             co_sign_notes        => cs.co_sign_notes,
                             flg_has_notes        => cs.flg_has_notes,
                             flg_needs_cosign     => cs.flg_needs_cosign,
                             flg_has_cosign       => cs.flg_has_cosign,
                             flg_made_auth        => cs.flg_made_auth)
          INTO l_co_sign_info
          FROM (SELECT /*+opt_estimate (table t rows=1)*/
                 row_number() over(ORDER BY dt_req DESC) rn, t.*
                  FROM TABLE(pk_co_sign_api.tf_co_sign_tasks_info(i_lang          => i_lang,
                                                                  i_prof          => i_prof,
                                                                  i_episode       => i_id_episode,
                                                                  i_task_type     => coalesce(l_id_task_type,
                                                                                              pk_alert_constant.g_task_comm_orders),
                                                                  i_id_task_group => i_id_comm_order_req)) t
                 WHERE (i_tab_id_actions IS NULL OR
                       t.id_action IN (SELECT column_value
                                          FROM TABLE(i_tab_id_actions)))
                   AND t.flg_status IN (pk_co_sign_api.g_cosign_flg_status_p,
                                        pk_co_sign_api.g_cosign_flg_status_na,
                                        pk_co_sign_api.g_cosign_flg_status_d)
                   AND t.flg_status != pk_co_sign_api.g_cosign_flg_status_o
                   AND (i_flg_not_ack = pk_alert_constant.g_no OR
                       -- only not acknowledged co-signs
                       (i_flg_not_ack = pk_alert_constant.g_yes AND
                       check_if_acknowledged(i_lang                   => i_lang,
                                               i_prof                   => i_prof,
                                               i_id_comm_order_req      => t.id_task_group,
                                               i_id_comm_order_req_hist => t.id_task) = pk_alert_constant.g_no))) cs
         WHERE cs.rn = 1;
    
        RETURN l_co_sign_info;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN l_co_sign_info;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_LAST_CS_INFO',
                                              o_error    => l_error);
            RETURN l_co_sign_info;
    END get_last_cs_info;

    FUNCTION get_comm_order_req_info
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_comm_order_req       IN table_number,
        i_flg_escape_char         IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_info                    OUT t_cur_comm_order_req_info,
        o_comm_clinical_questions OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'Init ';
        OPEN o_info FOR
            SELECT t.id_comm_order_req,
                   t.id_workflow,
                   t.id_status,
                   t.id_patient,
                   t.id_episode,
                   t.id_concept_type id_comm_order_type,
                   get_comm_order_type_desc(i_lang => i_lang, i_prof => i_prof, i_concept_type => t.id_concept_type) desc_comm_order_type,
                   t.flg_free_text,
                   get_comm_order_title(i_lang                 => i_lang,
                                        i_prof                 => i_prof,
                                        i_concept_type         => t.id_concept_type,
                                        i_concept_term         => t.id_concept_term,
                                        i_cncpt_trm_inst_owner => t.id_cncpt_trm_inst_owner,
                                        i_concept_version      => t.id_concept_version,
                                        i_cncpt_vrs_inst_owner => t.id_cncpt_vrs_inst_owner,
                                        i_flg_free_text        => t.flg_free_text,
                                        i_desc_concept_term    => t.desc_concept_term,
                                        i_task_type            => t.id_task_type,
                                        i_flg_trunc_clobs      => pk_alert_constant.g_yes,
                                        i_flg_escape_char      => i_flg_escape_char) desc_comm_order,
                   t.notes,
                   t.id_diagnosis,
                   t.id_alert_diagnosis,
                   t.desc_diagnosis,
                   t.flg_clinical_purpose,
                   get_clinical_purpose_desc(i_lang              => i_lang,
                                             i_prof              => i_prof,
                                             i_flg_clin_purpose  => t.flg_clinical_purpose,
                                             i_clin_purpose_desc => t.clinical_purpose_desc) desc_clinical_purpose,
                   t.flg_priority,
                   pk_sysdomain.get_domain(i_code_dom => g_code_priority, i_val => t.flg_priority, i_lang => i_lang) desc_priority,
                   t.flg_prn,
                   pk_sysdomain.get_domain(i_code_dom => g_code_prn, i_val => t.flg_prn, i_lang => i_lang) desc_prn,
                   t.prn_condition,
                   t.dt_begin,
                   pk_date_utils.date_send_tsz(i_lang, t.dt_begin, i_prof) start_date_str,
                   pk_date_utils.date_send_tsz(i_lang, t.co_sign_data.dt_ordered_by, i_prof) dt_order_str,
                   t.co_sign_data.id_prof_ordered_by id_prof_order,
                   t.co_sign_data.desc_prof_ordered_by desc_prof_order,
                   t.co_sign_data.id_order_type id_order_type,
                   t.co_sign_data.desc_order_type desc_order_type,
                   pk_date_utils.date_send_tsz(i_lang, t.dt_req, i_prof) dt_req_str,
                   pk_alert_constant.g_task_comm_orders id_task_type,
                   t.task_duration,
                   t.id_order_recurr id_order_recurrence,
                   t.order_recurrence,
                   (SELECT id_comm_order
                      FROM comm_order_ea c
                     WHERE c.id_concept_term = t.id_concept_term
                       AND c.id_software_conc_term = i_prof.software
                       AND c.id_institution_conc_term = i_prof.institution
                       AND c.id_task_type_conc_term = t.id_task_type
                       AND rownum = 1) id_comm_order,
                   pk_date_utils.date_char_tsz(i_lang,
                                               t.co_sign_data.dt_ordered_by,
                                               i_prof.institution,
                                               i_prof.software) dt_order
              FROM (SELECT /*+opt_estimate (table tt rows=1)*/
                     cor.id_comm_order_req,
                     cor.id_workflow,
                     cor.id_status,
                     cor.id_patient,
                     cor.id_episode,
                     cor.id_concept_type,
                     cor.id_concept_term,
                     cor.id_cncpt_trm_inst_owner,
                     cor.id_concept_version,
                     cor.id_cncpt_vrs_inst_owner,
                     pk_translation.get_translation_trs(cor.desc_concept_term) desc_concept_term,
                     cor.flg_free_text,
                     pk_translation.get_translation_trs(cor.notes) notes,
                     get_id_diagnoses(i_lang                => i_lang,
                                      i_prof                => i_prof,
                                      i_clinical_indication => pk_translation.get_translation_trs(cor.clinical_indication)) id_diagnosis,
                     get_id_alert_diagnoses(i_lang                => i_lang,
                                            i_prof                => i_prof,
                                            i_clinical_indication => pk_translation.get_translation_trs(cor.clinical_indication)) id_alert_diagnosis,
                     get_desc_diagnoses(i_lang                => i_lang,
                                        i_prof                => i_prof,
                                        i_clinical_indication => pk_translation.get_translation_trs(cor.clinical_indication)) desc_diagnosis,
                     cor.flg_clinical_purpose,
                     cor.clinical_purpose_desc,
                     cor.flg_priority,
                     cor.flg_prn,
                     pk_translation.get_translation_trs(cor.prn_condition) prn_condition,
                     cor.dt_begin,
                     cor.dt_req,
                     -- co-sign data
                     get_last_cs_info(i_lang              => i_lang,
                                      i_prof              => i_prof,
                                      i_id_episode        => cor.id_episode,
                                      i_id_comm_order_req => cor.id_comm_order_req,
                                      i_flg_not_ack       => pk_alert_constant.g_yes, -- only co-sign data that were not acknowledged
                                      i_tab_id_actions    => table_number(g_cs_action_add, g_cs_action_edit)) co_sign_data,
                     cor.task_duration,
                     nvl(cor.id_order_recurr, 0) id_order_recurr,
                     decode(cor.id_order_recurr,
                            NULL,
                            pk_translation.get_translation(i_lang, 'ORDER_RECURR_OPTION.CODE_ORDER_RECURR_OPTION.0'),
                            pk_order_recurrence_api_db.get_order_recurr_plan_desc(i_lang, i_prof, cor.id_order_recurr)) order_recurrence,
                     cor.id_task_type
                      FROM comm_order_req cor
                      JOIN TABLE(CAST(i_id_comm_order_req AS table_number)) tt
                        ON (tt.column_value = cor.id_comm_order_req)) t;
    
        g_error := 'GET CURSOR O_COMM_CLINICAL_QUESTIONS';
        OPEN o_comm_clinical_questions FOR
            SELECT coqr.id_common_order_req id_comm_order_req,
                   coqr.id_questionnaire,
                   pk_mcdt.get_questionnaire_alias(i_lang,
                                                   i_prof,
                                                   'QUESTIONNAIRE.CODE_QUESTIONNAIRE.' || coqr.id_questionnaire) desc_questionnaire,
                   decode(instr(get_comm_order_question_type(i_lang,
                                                             i_prof,
                                                             cor.id_concept_term,
                                                             pk_procedures_constant.g_interv_cq_on_order,
                                                             coqr.id_questionnaire,
                                                             coqr.id_response),
                                'D'),
                          0,
                          to_char(coqr1.id_response),
                          to_char(coqr.notes)) id_response,
                   decode(dbms_lob.getlength(coqr.notes),
                          NULL,
                          coqr1.desc_response,
                          pk_procedures_utils.get_procedure_response(i_lang, i_prof, coqr.notes)) desc_response
              FROM (SELECT coqr.id_common_order_req,
                           coqr.id_questionnaire,
                           substr(concatenate(coqr.id_response || '; '),
                                  1,
                                  length(concatenate(coqr.id_response || '; ')) - 2) id_response,
                           listagg(pk_mcdt.get_response_alias(i_lang,
                                                              i_prof,
                                                              'RESPONSE.CODE_RESPONSE.' || coqr.id_response),
                                   '; ') within GROUP(ORDER BY coqr.id_response) desc_response,
                           coqr.dt_last_update_tstz,
                           row_number() over(PARTITION BY coqr.id_questionnaire ORDER BY coqr.dt_last_update_tstz DESC NULLS FIRST) rn
                      FROM comm_order_question_response coqr
                     WHERE coqr.id_common_order_req IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                         *
                                                          FROM TABLE(i_id_comm_order_req) t)
                     GROUP BY coqr.id_common_order_req, coqr.id_questionnaire, coqr.dt_last_update_tstz) coqr1,
                   comm_order_question_response coqr,
                   comm_order_req cor
             WHERE coqr1.rn = 1
               AND coqr1.id_common_order_req = coqr.id_common_order_req
               AND coqr1.id_questionnaire = coqr.id_questionnaire
               AND coqr1.dt_last_update_tstz = coqr.dt_last_update_tstz
               AND coqr.id_common_order_req = cor.id_comm_order_req;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_COMM_ORDER_REQ_INFO',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_info);
            RETURN FALSE;
    END get_comm_order_req_info;

    FUNCTION get_comm_order_req_desc
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_comm_order_req     IN comm_order_req.id_comm_order_req%TYPE,
        i_description_condition IN pn_dblock_ttp_mkt.description_condition%TYPE DEFAULT NULL,
        i_flg_desc_for_dblock   IN pk_types.t_flg_char DEFAULT NULL
    ) RETURN CLOB IS
    
        l_cur_info t_cur_comm_order_req_info;
        l_rec_info t_rec_comm_order_req_info;
        l_result   CLOB;
        l_error    t_error_out;
    
        l_final_desc_cond     pk_types.t_huge_byte;
        l_tbl_desc_condition  table_varchar;
        l_tbl_final_desc_cond table_varchar;
        l_type_shown          BOOLEAN := FALSE;
    
        l_dummy pk_types.cursor_type;
    
    BEGIN
    
        g_error := 'Init ';
        IF i_description_condition IS NOT NULL
        THEN
        
            l_tbl_desc_condition := pk_string_utils.str_split(i_list => i_description_condition, i_delim => ';');
        
            IF i_flg_desc_for_dblock = pk_alert_constant.g_yes
               OR i_flg_desc_for_dblock IS NULL
            THEN
                l_final_desc_cond := l_tbl_desc_condition(1);
            ELSIF l_tbl_desc_condition.exists(2)
            THEN
                l_final_desc_cond := l_tbl_desc_condition(2);
            END IF;
        
            l_tbl_final_desc_cond := pk_string_utils.str_split(i_list => l_final_desc_cond, i_delim => '|');
        
            l_result := '';
        
            g_retval := get_comm_order_req_info(i_lang                    => i_lang,
                                                i_prof                    => i_prof,
                                                i_id_comm_order_req       => table_number(i_id_comm_order_req),
                                                i_flg_escape_char         => pk_alert_constant.g_no,
                                                o_info                    => l_cur_info,
                                                o_comm_clinical_questions => l_dummy,
                                                o_error                   => l_error);
        
            g_error := 'FETCH l_cur_info / ';
            FETCH l_cur_info
                INTO l_rec_info;
            CLOSE l_cur_info;
        
            FOR i IN l_tbl_final_desc_cond.first .. l_tbl_final_desc_cond.last
            LOOP
                IF l_tbl_final_desc_cond(i) = 'START-DATE'
                THEN
                    IF l_rec_info.start_date_str IS NOT NULL
                    THEN
                        IF l_result IS NOT NULL
                        THEN
                            l_result := l_result || pk_prog_notes_constants.g_comma ||
                                        pk_date_utils.date_char_tsz(i_lang => i_lang,
                                                                    i_date => l_rec_info.start_date_str,
                                                                    i_inst => i_prof.institution,
                                                                    i_soft => i_prof.software);
                        ELSE
                            l_result := l_result || pk_date_utils.date_char_tsz(i_lang => i_lang,
                                                                                i_date => l_rec_info.dt_begin,
                                                                                i_inst => i_prof.institution,
                                                                                i_soft => i_prof.software);
                        END IF;
                    END IF;
                END IF;
            
                IF l_tbl_final_desc_cond(i) = 'TYPE'
                THEN
                    IF l_rec_info.desc_comm_order_type IS NOT NULL
                    THEN
                        IF l_result IS NOT NULL
                        THEN
                            l_result := l_result || pk_prog_notes_constants.g_space || l_rec_info.desc_comm_order_type ||
                                        pk_prog_notes_constants.g_flg_sep;
                        ELSE
                            l_result := l_result || l_rec_info.desc_comm_order_type ||
                                        pk_prog_notes_constants.g_flg_sep;
                        END IF;
                    END IF;
                    l_type_shown := TRUE;
                END IF;
            
                IF l_tbl_final_desc_cond(i) = 'COMMORDER'
                THEN
                    IF l_rec_info.desc_comm_order IS NOT NULL
                    THEN
                        IF l_result IS NOT NULL
                        THEN
                        
                            IF l_type_shown = FALSE
                            THEN
                                l_result := l_result || pk_prog_notes_constants.g_space || l_rec_info.desc_comm_order;
                            ELSE
                                l_result := l_result || l_rec_info.desc_comm_order;
                            END IF;
                        
                        ELSE
                            l_result := l_result || l_rec_info.desc_comm_order;
                        END IF;
                    END IF;
                END IF;
            
                IF l_tbl_final_desc_cond(i) = 'NOTES'
                THEN
                    IF l_rec_info.notes IS NOT NULL
                    THEN
                        IF l_result IS NOT NULL
                        THEN
                            l_result := l_result || pk_prog_notes_constants.g_comma || l_rec_info.notes;
                        ELSE
                            l_result := l_result || l_rec_info.notes;
                        END IF;
                    END IF;
                END IF;
            
            END LOOP;
        
        ELSE
            g_retval := get_comm_order_req_info(i_lang                    => i_lang,
                                                i_prof                    => i_prof,
                                                i_id_comm_order_req       => table_number(i_id_comm_order_req),
                                                i_flg_escape_char         => pk_alert_constant.g_no,
                                                o_info                    => l_cur_info,
                                                o_comm_clinical_questions => l_dummy,
                                                o_error                   => l_error);
        
            g_error := 'FETCH l_cur_info ';
            FETCH l_cur_info
                INTO l_rec_info;
            CLOSE l_cur_info;
        
            -- <CO_TYPE>: <CO_TITLE>[, <NOTES>] ([<PRN_DESC> <PRN_CONDITION>] <DT_BEGIN> - <DESC_STATUS>)
            -- PRN information only visible if FLG_PRN=Y
            g_error  := 'Get values / ';
            l_result := l_rec_info.desc_comm_order_type || g_str_sep_colon ||
                        trunc_clob_to_varchar2(l_rec_info.desc_comm_order, g_trunc_clob_max_size);
        
            IF l_rec_info.notes IS NOT NULL
               OR length(l_rec_info.notes) > 0
            THEN
                l_result := l_result || g_str_sep_comma ||
                            get_comm_order_notes(i_lang            => i_lang,
                                                 i_prof            => i_prof,
                                                 i_notes           => l_rec_info.notes,
                                                 i_flg_trunc_clobs => pk_alert_constant.g_yes,
                                                 i_flg_escape_char => pk_alert_constant.g_no);
                --trunc_clob_to_varchar2(l_rec_info.notes, g_trunc_clob_max_size);
            END IF;
        
            l_result := l_result || g_str_sep_l_par;
        
            -- getting instructions
            g_error := 'PRN / FLG_PRN=' || l_rec_info.flg_prn;
            IF l_rec_info.flg_prn = pk_alert_constant.g_yes
            THEN
                l_result := l_result ||
                            to_char(get_comm_order_instr(i_lang            => i_lang,
                                                         i_prof            => i_prof,
                                                         i_flg_priority    => NULL, -- don't want to print this information
                                                         i_flg_prn         => l_rec_info.flg_prn,
                                                         i_prn_condition   => l_rec_info.prn_condition,
                                                         i_dt_begin        => l_rec_info.dt_begin,
                                                         i_flg_trunc_clobs => pk_alert_constant.g_yes,
                                                         i_flg_escape_char => pk_alert_constant.g_no));
            ELSE
                l_result := l_result ||
                            to_char(get_comm_order_instr(i_lang            => i_lang,
                                                         i_prof            => i_prof,
                                                         i_flg_priority    => NULL, -- don't want to print this information
                                                         i_flg_prn         => NULL, -- don't want to print this information
                                                         i_prn_condition   => NULL, -- don't want to print this information
                                                         i_dt_begin        => l_rec_info.dt_begin,
                                                         i_flg_trunc_clobs => pk_alert_constant.g_yes,
                                                         i_flg_escape_char => pk_alert_constant.g_no));
            END IF;
        
            -- getting status desc
            g_error  := 'Status / ID_STATUS=' || l_rec_info.id_status;
            l_result := l_result || g_str_sep_hyphen ||
                        get_comm_order_req_sts_desc(i_lang              => i_lang,
                                                    i_prof              => i_prof,
                                                    i_id_status         => l_rec_info.id_status,
                                                    i_dt_begin          => l_rec_info.dt_begin,
                                                    i_id_comm_order_req => l_rec_info.id_comm_order_req);
            l_result := l_result || g_str_sep_r_par;
        END IF;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_comm_order_req_desc;

    FUNCTION get_signature
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_code_message IN sys_message.code_message%TYPE,
        i_id_prof_op   IN comm_order_req.id_professional%TYPE,
        i_dt_op        IN comm_order_req.dt_status%TYPE,
        o_text         OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'Init ';
        o_text  := pk_message.get_message(i_lang => i_lang, i_code_mess => i_code_message);
    
        g_error := 'Call pk_prof_utils.get_name_signature ';
        o_text  := o_text || ' ' ||
                   pk_prof_utils.get_name_signature(i_lang => i_lang, i_prof => i_prof, i_prof_id => i_id_prof_op);
    
        g_error := 'Call pk_date_utils.dt_chr_date_hour_tsz ';
        o_text  := o_text || '; ' || pk_date_utils.dt_chr_date_hour_tsz(i_lang, i_dt_op, i_prof);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_SIGNATURE',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_signature;

    FUNCTION get_comm_order_clin_quest
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_comm_order_req IN comm_order_req.id_comm_order_req%TYPE,
        i_dt_status_new  IN comm_order_req.dt_status%TYPE,
        i_dt_status_old  IN comm_order_req.dt_status%TYPE,
        o_tbl_clin_quest OUT table_varchar,
        o_tbl_curr_resp  OUT table_varchar,
        o_tbl_prev_resp  OUT table_varchar,
        o_tbl_cq_rank    OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'Init';
        SELECT desc_clinical_question, desc_response, prev_ans, rank
          BULK COLLECT
          INTO o_tbl_clin_quest, o_tbl_curr_resp, o_tbl_prev_resp, o_tbl_cq_rank
          FROM (SELECT tt.*,
                       (SELECT pk_mcdt.get_questionnaire_alias(i_lang,
                                                               i_prof,
                                                               'QUESTIONNAIRE.CODE_QUESTIONNAIRE.' || tt.id_questionnaire)
                          FROM dual) || ': ' desc_clinical_question,
                       (SELECT pk_comm_orders.get_comm_order_question_rank(i_lang,
                                                                           i_prof,
                                                                           tt.id_concept_term,
                                                                           tt.id_questionnaire,
                                                                           tt.flg_time)
                          FROM dual) rank
                  FROM (SELECT t.*,
                               
                               lag(t.desc_response, 1) over(ORDER BY t.flg_time, t.id_questionnaire, t.rn DESC) AS prev_ans
                          FROM (SELECT DISTINCT coqr1.id_questionnaire,
                                                coqr1.flg_time,
                                                dbms_lob.substr(decode(dbms_lob.getlength(coqr.notes),
                                                                       NULL,
                                                                       to_clob(decode(coqr1.desc_response,
                                                                                      NULL,
                                                                                      '---',
                                                                                      coqr1.desc_response)),
                                                                       pk_procedures_utils.get_procedure_response(i_lang,
                                                                                                                  i_prof,
                                                                                                                  coqr.notes)),
                                                                3800) desc_response,
                                                cor.id_concept_term,
                                                rn
                                  FROM (SELECT coqr.id_common_order_req,
                                               coqr.id_questionnaire,
                                               coqr.flg_time,
                                               listagg((SELECT pk_mcdt.get_response_alias(i_lang,
                                                                                         i_prof,
                                                                                         'RESPONSE.CODE_RESPONSE.' ||
                                                                                         coqr.id_response)
                                                         FROM dual),
                                                       '; ') within GROUP(ORDER BY coqr.id_response) desc_response,
                                               coqr.dt_last_update_tstz,
                                               row_number() over(PARTITION BY coqr.id_questionnaire, coqr.flg_time ORDER BY coqr.dt_last_update_tstz DESC NULLS FIRST) rn
                                          FROM comm_order_question_response coqr
                                         WHERE coqr.id_common_order_req = i_comm_order_req
                                           AND coqr.dt_last_update_tstz IN (i_dt_status_new, i_dt_status_old)
                                         GROUP BY coqr.id_common_order_req,
                                                  coqr.id_questionnaire,
                                                  coqr.flg_time,
                                                  coqr.dt_last_update_tstz) coqr1
                                 INNER JOIN comm_order_question_response coqr
                                    ON coqr1.id_common_order_req = coqr.id_common_order_req
                                   AND coqr1.id_questionnaire = coqr.id_questionnaire
                                   AND coqr1.dt_last_update_tstz = coqr.dt_last_update_tstz
                                   AND coqr1.flg_time = coqr.flg_time
                                 INNER JOIN comm_order_req cor
                                    ON coqr.id_common_order_req = cor.id_comm_order_req) t
                         ORDER BY flg_time, id_questionnaire, rn) tt
                 WHERE tt.rn = 1)
         ORDER BY rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_COMM_ORDER_CLIN_QUEST',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_comm_order_clin_quest;

    FUNCTION is_diff_c
    (
        i_old_val IN CLOB,
        i_new_val IN CLOB,
        o_old_set OUT PLS_INTEGER,
        o_new_set OUT PLS_INTEGER
    ) RETURN VARCHAR2 IS
    
        l_result VARCHAR2(1 CHAR);
    
    BEGIN
    
        o_old_set := 0;
        o_new_set := 0;
        l_result  := pk_alert_constant.g_no;
    
        g_error := 'Old value';
        IF i_old_val IS NOT NULL
           AND length(i_old_val) > 0
        THEN
            o_old_set := 1;
        END IF;
    
        g_error := 'New value';
        IF i_new_val IS NOT NULL
           AND length(i_new_val) > 0
        THEN
            o_new_set := 1;
        END IF;
    
        g_error := 'Diff';
        IF (o_old_set = 0 AND o_new_set = 1)
           OR (o_old_set = 1 AND o_new_set = 0)
           OR (o_old_set = 1 AND o_new_set = 1 AND i_old_val != i_new_val)
        THEN
            l_result := pk_alert_constant.g_yes;
        END IF;
    
        RETURN l_result;
    
    END is_diff_c;

    FUNCTION is_diff_n
    (
        i_old_val IN NUMBER,
        i_new_val IN NUMBER,
        o_old_set OUT PLS_INTEGER,
        o_new_set OUT PLS_INTEGER
    ) RETURN VARCHAR2 IS
    
        l_result VARCHAR2(1 CHAR);
    
    BEGIN
    
        o_old_set := 0;
        o_new_set := 0;
        l_result  := pk_alert_constant.g_no;
    
        g_error := 'Old value';
        IF i_old_val IS NOT NULL
        THEN
            o_old_set := 1;
        END IF;
    
        g_error := 'New value';
        IF i_new_val IS NOT NULL
        THEN
            o_new_set := 1;
        END IF;
    
        g_error := 'Diff';
        IF (o_old_set = 0 AND o_new_set = 1)
           OR (o_old_set = 1 AND o_new_set = 0)
           OR (o_old_set = 1 AND o_new_set = 1 AND i_old_val != i_new_val)
        THEN
            l_result := pk_alert_constant.g_yes;
        END IF;
    
        RETURN l_result;
    
    END is_diff_n;

    FUNCTION is_diff_t
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_old_val IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_new_val IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_old_set OUT PLS_INTEGER,
        o_new_set OUT PLS_INTEGER
    ) RETURN VARCHAR2 IS
    
        l_result     VARCHAR2(1 CHAR);
        l_check_date VARCHAR2(1 CHAR);
    
    BEGIN
    
        o_old_set := 0;
        o_new_set := 0;
        l_result  := pk_alert_constant.g_no;
    
        g_error := 'Old value';
        IF i_old_val IS NOT NULL
        THEN
            o_old_set := 1;
        END IF;
    
        g_error := 'New value';
        IF i_new_val IS NOT NULL
        THEN
            o_new_set := 1;
        END IF;
    
        g_error := 'Diff';
        IF (o_old_set = 0 AND o_new_set = 1)
           OR (o_old_set = 1 AND o_new_set = 0)
        THEN
            l_result := pk_alert_constant.g_yes;
        ELSIF o_old_set = 1
              AND o_new_set = 1
        THEN
            l_check_date := pk_date_utils.compare_dates_tsz(i_prof  => i_prof,
                                                            i_date1 => i_old_val,
                                                            i_date2 => i_new_val);
            IF l_check_date != pk_alert_constant.g_date_equal
            THEN
                l_result := pk_alert_constant.g_yes;
            END IF;
        END IF;
    
        RETURN l_result;
    
    END is_diff_t;

    FUNCTION is_diff_cq
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_comm_order_req IN NUMBER,
        i_old_dt_status     IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_new_dt_status     IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_old_set           OUT PLS_INTEGER,
        o_new_set           OUT PLS_INTEGER
    ) RETURN VARCHAR2 IS
    
        l_result VARCHAR2(1 CHAR);
    
        l_tbl_curr_answ table_varchar := table_varchar();
        l_tbl_prev_answ table_varchar := table_varchar();
    
    BEGIN
    
        o_old_set := 0;
        o_new_set := 0;
        l_result  := pk_alert_constant.g_no;
    
        g_error := 'Old value';
        IF i_old_dt_status IS NOT NULL
        THEN
            o_old_set := 1;
        END IF;
    
        g_error := 'New value';
        IF i_new_dt_status IS NOT NULL
        THEN
            o_new_set := 1;
        END IF;
    
        g_error := 'Diff';
        IF (o_old_set <> 0 AND o_new_set <> 0)
        THEN
            SELECT tt.desc_response, tt.prev_ans
              BULK COLLECT
              INTO l_tbl_curr_answ, l_tbl_prev_answ
              FROM (SELECT t.*,
                           lag(t.desc_response, 1) over(ORDER BY t.flg_time, t.id_questionnaire, t.rn DESC) AS prev_ans
                      FROM (SELECT DISTINCT coqr1.id_questionnaire,
                                            coqr1.flg_time,
                                            dbms_lob.substr(decode(dbms_lob.getlength(coqr.notes),
                                                                   NULL,
                                                                   to_clob(decode(coqr1.desc_response,
                                                                                  NULL,
                                                                                  '---',
                                                                                  coqr1.desc_response)),
                                                                   pk_procedures_utils.get_procedure_response(i_lang,
                                                                                                              i_prof,
                                                                                                              coqr.notes)),
                                                            3800) desc_response,
                                            rn
                              FROM (SELECT coqr.id_common_order_req,
                                           coqr.id_questionnaire,
                                           coqr.flg_time,
                                           listagg((SELECT pk_mcdt.get_response_alias(i_lang,
                                                                                     i_prof,
                                                                                     'RESPONSE.CODE_RESPONSE.' ||
                                                                                     coqr.id_response)
                                                     FROM dual),
                                                   '; ') within GROUP(ORDER BY coqr.id_response) desc_response,
                                           coqr.dt_last_update_tstz,
                                           row_number() over(PARTITION BY coqr.id_questionnaire, coqr.flg_time ORDER BY coqr.dt_last_update_tstz DESC NULLS FIRST) rn
                                      FROM comm_order_question_response coqr
                                     WHERE coqr.id_common_order_req = i_id_comm_order_req
                                       AND coqr.dt_last_update_tstz IN (i_old_dt_status, i_new_dt_status)
                                     GROUP BY coqr.id_common_order_req,
                                              coqr.id_questionnaire,
                                              coqr.flg_time,
                                              coqr.dt_last_update_tstz) coqr1
                             INNER JOIN comm_order_question_response coqr
                                ON coqr1.id_common_order_req = coqr.id_common_order_req
                               AND coqr1.id_questionnaire = coqr.id_questionnaire
                               AND coqr1.dt_last_update_tstz = coqr.dt_last_update_tstz
                               AND coqr1.flg_time = coqr.flg_time) t
                     ORDER BY flg_time, id_questionnaire, rn) tt
             WHERE tt.rn = 1;
        
            IF l_tbl_curr_answ.exists(1)
            THEN
                FOR i IN l_tbl_curr_answ.first .. l_tbl_curr_answ.last
                LOOP
                    IF l_tbl_curr_answ(i) <> l_tbl_prev_answ(i)
                    THEN
                        l_result := pk_alert_constant.g_yes;
                        RETURN l_result;
                    END IF;
                END LOOP;
            END IF;
        END IF;
    
        RETURN l_result;
    
    END is_diff_cq;

    FUNCTION show_in_history_co_sign
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_rec_old IN t_rec_comm_order_req,
        i_rec_new IN t_rec_comm_order_req,
        o_old_set OUT PLS_INTEGER,
        o_new_set OUT PLS_INTEGER
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        o_old_set := 0;
        o_new_set := 0;
    
        -- all fields related with co-signs
        -- only need to check if there is any co-sign related to this change
        IF i_rec_new.co_sign_data.count > 0
        THEN
            o_new_set := 1;
            RETURN pk_alert_constant.g_yes;
        END IF;
    
        RETURN pk_alert_constant.g_no;
    
    END show_in_history_co_sign;

    FUNCTION show_in_history
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_rec_old IN t_rec_comm_order_req,
        i_rec_new IN t_rec_comm_order_req,
        i_field   IN VARCHAR,
        o_old_set OUT PLS_INTEGER,
        o_new_set OUT PLS_INTEGER
    ) RETURN VARCHAR2 IS
    
        l_error           t_error_out;
        l_field_value_old CLOB;
        l_field_value_new CLOB;
    
    BEGIN
    
        -- g_field_notes
        IF i_field IS NULL
           OR i_field = g_field_notes
        THEN
        
            g_error := 'Call is_diff_c / g_field_notes / ';
            IF is_diff_c(i_old_val => i_rec_old.notes,
                         i_new_val => i_rec_new.notes,
                         o_old_set => o_old_set,
                         o_new_set => o_new_set) = pk_alert_constant.g_yes
            THEN
                RETURN pk_alert_constant.g_yes;
            END IF;
        END IF;
    
        -- g_field_clin_indication
        IF i_field IS NULL
           OR i_field = g_field_clin_indication
        THEN
        
            g_error  := 'Call get_diagnoses_text / old clinical indication / ';
            g_retval := get_diagnoses_text(i_lang                => i_lang,
                                           i_prof                => i_prof,
                                           i_clinical_indication => i_rec_old.clinical_indication,
                                           o_text                => l_field_value_old,
                                           o_error               => l_error);
        
            g_error  := 'Call get_diagnoses_text / new clinical indication / ';
            g_retval := get_diagnoses_text(i_lang                => i_lang,
                                           i_prof                => i_prof,
                                           i_clinical_indication => i_rec_old.clinical_indication,
                                           o_text                => l_field_value_new,
                                           o_error               => l_error);
        
            g_error := 'Call is_diff_c / g_field_clin_indication / ';
            IF is_diff_c(i_old_val => l_field_value_old,
                         i_new_val => l_field_value_new,
                         o_old_set => o_old_set,
                         o_new_set => o_new_set) = pk_alert_constant.g_yes
            THEN
                RETURN pk_alert_constant.g_yes;
            END IF;
        END IF;
    
        -- g_field_clin_purpose
        IF i_field IS NULL
           OR i_field = g_field_clin_purpose
        THEN
            g_error := 'Call is_diff_c / g_field_clin_purpose / ';
            IF is_diff_c(i_old_val => i_rec_old.flg_clinical_purpose,
                         i_new_val => i_rec_new.flg_clinical_purpose,
                         o_old_set => o_old_set,
                         o_new_set => o_new_set) = pk_alert_constant.g_yes
            THEN
                RETURN pk_alert_constant.g_yes;
            ELSIF i_rec_old.flg_clinical_purpose = g_flg_clin_purpose_other
                  AND i_rec_new.flg_clinical_purpose = g_flg_clin_purpose_other
            THEN
                -- compares description           
                IF is_diff_c(i_old_val => i_rec_old.clinical_purpose_desc,
                             i_new_val => i_rec_new.clinical_purpose_desc,
                             o_old_set => o_old_set,
                             o_new_set => o_new_set) = pk_alert_constant.g_yes
                THEN
                    RETURN pk_alert_constant.g_yes;
                END IF;
            END IF;
        END IF;
    
        -- g_field_priority
        IF i_field IS NULL
           OR i_field = g_field_priority
        THEN
            g_error := 'Call is_diff_c / g_field_priority / ';
            IF is_diff_c(i_old_val => i_rec_old.flg_priority,
                         i_new_val => i_rec_new.flg_priority,
                         o_old_set => o_old_set,
                         o_new_set => o_new_set) = pk_alert_constant.g_yes
            THEN
                RETURN pk_alert_constant.g_yes;
            END IF;
        END IF;
    
        -- g_field_prn
        IF i_field IS NULL
           OR i_field = g_field_prn
        THEN
            g_error := 'Call is_diff_c / g_field_prn / ';
            IF is_diff_c(i_old_val => i_rec_old.flg_prn,
                         i_new_val => i_rec_new.flg_prn,
                         o_old_set => o_old_set,
                         o_new_set => o_new_set) = pk_alert_constant.g_yes
            THEN
                RETURN pk_alert_constant.g_yes;
            END IF;
        END IF;
    
        -- g_field_prn_condition
        IF i_field IS NULL
           OR i_field = g_field_prn_condition
        THEN
            g_error := 'Call is_diff_c / g_field_prn_condition / ';
            IF is_diff_c(i_old_val => i_rec_old.prn_condition,
                         i_new_val => i_rec_new.prn_condition,
                         o_old_set => o_old_set,
                         o_new_set => o_new_set) = pk_alert_constant.g_yes
            THEN
                RETURN pk_alert_constant.g_yes;
            END IF;
        END IF;
    
        -- g_field_dt_begin
        IF i_field IS NULL
           OR i_field = g_field_dt_begin
        THEN
            g_error := 'Call is_diff_t / g_field_dt_begin / ';
            IF is_diff_t(i_lang    => i_lang,
                         i_prof    => i_prof,
                         i_old_val => i_rec_old.dt_begin,
                         i_new_val => i_rec_new.dt_begin,
                         o_old_set => o_old_set,
                         o_new_set => o_new_set) = pk_alert_constant.g_yes
            THEN
                RETURN pk_alert_constant.g_yes;
            END IF;
        END IF;
    
        --Frequency
        IF i_field IS NULL
           OR i_field = g_field_frequency
        THEN
            g_error := 'Call is_diff_t / g_field_frequency / ';
            IF is_diff_n(i_old_val => i_rec_old.id_order_recurr,
                         i_new_val => i_rec_new.id_order_recurr,
                         o_old_set => o_old_set,
                         o_new_set => o_new_set) = pk_alert_constant.g_yes
            THEN
                RETURN pk_alert_constant.g_yes;
            END IF;
        END IF;
    
        --Task duration
        IF i_field IS NULL
           OR i_field = g_field_task_duration
        THEN
            g_error := 'Call is_diff_t / g_field_task_duration / ';
            IF is_diff_n(i_old_val => i_rec_old.task_duration,
                         i_new_val => i_rec_new.task_duration,
                         o_old_set => o_old_set,
                         o_new_set => o_new_set) = pk_alert_constant.g_yes
            THEN
                RETURN pk_alert_constant.g_yes;
            END IF;
        END IF;
    
        -- all fields related with co-signs
        g_error := 'i_field=' || i_field;
        IF i_field IS NULL
           OR i_field IN (g_field_o_id_order_type,
                          g_field_e_id_order_type,
                          g_field_c_id_order_type,
                          g_field_d_id_order_type,
                          g_field_o_prof_order,
                          g_field_e_prof_order,
                          g_field_c_prof_order,
                          g_field_d_prof_order,
                          g_field_o_dt_order,
                          g_field_e_dt_order,
                          g_field_c_dt_order,
                          g_field_d_dt_order)
        THEN
            IF show_in_history_co_sign(i_lang    => i_lang,
                                       i_prof    => i_prof,
                                       i_rec_old => i_rec_old,
                                       i_rec_new => i_rec_new,
                                       o_old_set => o_old_set,
                                       o_new_set => o_new_set) = pk_alert_constant.g_yes
            THEN
                RETURN pk_alert_constant.g_yes;
            END IF;
        END IF;
    
        IF i_field IS NULL
           OR i_field = g_field_status
        THEN
            g_error := 'Call is_diff_n / g_field_status / ';
            IF is_diff_n(i_old_val => i_rec_old.id_status,
                         i_new_val => i_rec_new.id_status,
                         o_old_set => o_old_set,
                         o_new_set => o_new_set) = pk_alert_constant.g_yes
            THEN
                RETURN pk_alert_constant.g_yes;
            END IF;
        END IF;
    
        -- g_field_cancel_reason / g_field_discontinue_reason
        IF i_field IS NULL
           OR i_field IN (g_field_cancel_reason, g_field_discontinue_reason)
        THEN
            g_error := 'Call is_diff_n / g_field_cancel_reason, g_field_discontinue_reason / ';
            IF is_diff_n(i_old_val => i_rec_old.id_cancel_reason,
                         i_new_val => i_rec_new.id_cancel_reason,
                         o_old_set => o_old_set,
                         o_new_set => o_new_set) = pk_alert_constant.g_yes
            THEN
                RETURN pk_alert_constant.g_yes;
            END IF;
        END IF;
    
        -- g_field_cancel_notes/g_field_discontinue_notes
        IF i_field IS NULL
           OR i_field IN (g_field_cancel_notes, g_field_discontinue_notes)
        THEN
            g_error := 'Call is_diff_c / g_field_cancel_notes / ';
            IF is_diff_c(i_old_val => i_rec_old.notes_cancel,
                         i_new_val => i_rec_new.notes_cancel,
                         o_old_set => o_old_set,
                         o_new_set => o_new_set) = pk_alert_constant.g_yes
            THEN
                RETURN pk_alert_constant.g_yes;
            END IF;
        END IF;
    
        -- g_field_clinical_question
        IF i_field IS NULL
           OR i_field = g_field_clinical_question
        THEN
            g_error := 'Call is_diff_c / g_field_cancel_notes / ';
            IF is_diff_cq(i_lang              => i_lang,
                          i_prof              => i_prof,
                          i_id_comm_order_req => i_rec_new.id_comm_order_req,
                          i_old_dt_status     => i_rec_old.dt_status,
                          i_new_dt_status     => i_rec_new.dt_status,
                          o_old_set           => o_old_set,
                          o_new_set           => o_new_set) = pk_alert_constant.g_yes
            THEN
                RETURN pk_alert_constant.g_yes;
            END IF;
        END IF;
    
        RETURN pk_alert_constant.g_no;
    
    END show_in_history;

    FUNCTION format_field
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_comm_order_req      IN comm_order_req.id_comm_order_req%TYPE,
        i_field                  IN VARCHAR2,
        i_id_section             IN PLS_INTEGER,
        i_header_1               IN VARCHAR2,
        i_signature              IN VARCHAR2,
        i_field_value            IN CLOB,
        i_field_style            IN VARCHAR2 DEFAULT NULL,
        i_flg_new                IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_rank                   IN PLS_INTEGER,
        i_dt_detail              IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_use_header_2           IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_clinical_question_desc IN VARCHAR2 DEFAULT NULL
    ) RETURN t_rec_comm_order_req_det IS
    
        l_error  t_error_out;
        l_result t_rec_comm_order_req_det;
        l_aux    table_varchar2 := table_varchar2();
    
    BEGIN
    
        l_result                   := t_rec_comm_order_req_det();
        l_result.id_comm_order_req := i_id_comm_order_req;
        l_result.id_section        := i_id_section;
        l_result.header_1          := i_header_1;
        l_result.signature         := i_signature;
        l_result.rank              := i_rank;
        l_result.dt_detail         := i_dt_detail;
        l_result.field_value       := htf.escape_sc(i_field_value); -- escape html characters
        l_result.field_code        := i_field;
    
        -- filed style: general behaviour, could be changed below
        g_error := 'i_field_style=' || i_field_style;
        IF i_field_style IS NOT NULL
        THEN
            l_result.field_style := i_field_style;
        ELSE
            g_error := 'i_flg_new=' || i_flg_new;
            IF i_flg_new = pk_alert_constant.g_no
            THEN
                l_result.field_style := g_field_style_normal;
                l_result.style_rank  := g_field_style_rank_normal;
            ELSE
                l_result.field_style := g_field_style_new;
                l_result.style_rank  := g_field_style_rank_new;
            END IF;
        END IF;
    
        g_error := 'CASE / ';
        CASE
            WHEN i_field = g_field_notes THEN
            
                l_result.field_rank := g_field_sr_notes;
            
                IF i_use_header_2 = pk_alert_constant.g_yes
                THEN
                    l_result.header_2 := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t021);
                ELSE
                    l_result.header_2 := NULL;
                END IF;
                IF i_flg_new = pk_alert_constant.g_no
                THEN
                    l_result.field_name := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t008);
                ELSE
                    l_result.field_name := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t029);
                END IF;
            
            WHEN i_field = g_field_notes_execution THEN
            
                l_result.field_rank := g_field_sr_notes_execution;
            
                IF i_use_header_2 = pk_alert_constant.g_yes
                THEN
                    l_result.header_2 := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t021);
                ELSE
                    l_result.header_2 := NULL;
                END IF;
                IF i_flg_new = pk_alert_constant.g_no
                THEN
                    l_result.field_name := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t008);
                ELSE
                    l_result.field_name := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t029);
                END IF;
            WHEN i_field = g_field_template_execution THEN
            
                l_result.field_rank := g_field_sr_notes_execution;
            
                IF i_use_header_2 = pk_alert_constant.g_yes
                THEN
                    l_result.header_2 := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t021);
                ELSE
                    l_result.header_2 := NULL;
                END IF;
            
                l_result.field_name := NULL;
            
            WHEN i_field = g_field_clin_indication THEN
            
                l_result.field_rank := g_field_sr_clin_indication;
            
                IF i_use_header_2 = pk_alert_constant.g_yes
                THEN
                    l_result.header_2 := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t004);
                ELSE
                    l_result.header_2 := NULL;
                END IF;
                IF i_flg_new = pk_alert_constant.g_no
                THEN
                    l_result.field_name := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t026);
                ELSE
                    l_result.field_name := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t030);
                END IF;
            
            WHEN i_field = g_field_clin_purpose THEN
            
                l_result.field_rank := g_field_sr_clin_purpose;
            
                IF i_use_header_2 = pk_alert_constant.g_yes
                THEN
                    l_result.header_2 := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t004);
                ELSE
                    l_result.header_2 := NULL;
                END IF;
                IF i_flg_new = pk_alert_constant.g_no
                THEN
                    l_result.field_name := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t010);
                ELSE
                    l_result.field_name := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t031);
                END IF;
            
            WHEN i_field = g_field_priority THEN
            
                l_result.field_rank := g_field_sr_priority;
            
                IF i_use_header_2 = pk_alert_constant.g_yes
                THEN
                    l_result.header_2 := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t005);
                ELSE
                    l_result.header_2 := NULL;
                END IF;
                IF i_flg_new = pk_alert_constant.g_no
                THEN
                    l_result.field_name := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t011);
                ELSE
                    l_result.field_name := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t032);
                END IF;
            
            WHEN i_field = g_field_prn THEN
            
                l_result.field_rank := g_field_sr_prn;
            
                IF i_use_header_2 = pk_alert_constant.g_yes
                THEN
                    l_result.header_2 := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t005);
                ELSE
                    l_result.header_2 := NULL;
                END IF;
                IF i_flg_new = pk_alert_constant.g_no
                THEN
                    l_result.field_name := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t012);
                ELSE
                    l_result.field_name := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t033);
                END IF;
            
            WHEN i_field = g_field_prn_condition THEN
            
                l_result.field_rank := g_field_sr_prn_condition;
            
                IF i_use_header_2 = pk_alert_constant.g_yes
                THEN
                    l_result.header_2 := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t005);
                ELSE
                    l_result.header_2 := NULL;
                END IF;
                IF i_flg_new = pk_alert_constant.g_no
                THEN
                    l_result.field_name := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t013);
                ELSE
                    l_result.field_name := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t038);
                END IF;
            
            WHEN i_field = g_field_dt_begin THEN
            
                l_result.field_rank := g_field_sr_dt_begin;
            
                IF i_use_header_2 = pk_alert_constant.g_yes
                THEN
                    l_result.header_2 := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t005);
                ELSE
                    l_result.header_2 := NULL;
                END IF;
                IF i_flg_new = pk_alert_constant.g_no
                THEN
                    l_result.field_name := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t014);
                ELSE
                    l_result.field_name := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t034);
                END IF;
            
            WHEN i_field = g_field_start_time THEN
            
                l_result.field_rank := g_field_sr_dt_begin;
            
                IF i_use_header_2 = pk_alert_constant.g_yes
                THEN
                    l_result.header_2 := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t005);
                ELSE
                    l_result.header_2 := NULL;
                END IF;
                IF i_flg_new = pk_alert_constant.g_no
                THEN
                    l_result.field_name := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t064);
                ELSE
                    l_result.field_name := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t065);
                END IF;
            
            WHEN i_field = g_field_end_time THEN
            
                l_result.field_rank := g_field_sr_dt_end;
            
                IF i_use_header_2 = pk_alert_constant.g_yes
                THEN
                    l_result.header_2 := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t005);
                ELSE
                    l_result.header_2 := NULL;
                END IF;
                IF i_flg_new = pk_alert_constant.g_no
                THEN
                    l_result.field_name := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t066);
                ELSE
                    l_result.field_name := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t067);
                END IF;
            
            WHEN i_field = g_field_performed_by THEN
            
                l_result.field_rank := g_filed_sr_performed_by;
            
                IF i_use_header_2 = pk_alert_constant.g_yes
                THEN
                    l_result.header_2 := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t005);
                ELSE
                    l_result.header_2 := NULL;
                END IF;
                IF i_flg_new = pk_alert_constant.g_no
                THEN
                    l_result.field_name := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t068);
                ELSE
                    l_result.field_name := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t069);
                END IF;
            
            WHEN i_field = g_field_frequency THEN
            
                l_result.field_rank := g_field_sr_frequency;
            
                IF i_use_header_2 = pk_alert_constant.g_yes
                THEN
                    l_result.header_2 := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t005);
                ELSE
                    l_result.header_2 := NULL;
                END IF;
                IF i_flg_new = pk_alert_constant.g_no
                THEN
                    l_result.field_name := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t061);
                ELSE
                    l_result.field_name := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t062);
                END IF;
            
            WHEN i_field = g_field_task_duration THEN
            
                l_result.field_rank := g_field_sr_task_duration;
            
                IF i_use_header_2 = pk_alert_constant.g_yes
                THEN
                    l_result.header_2 := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t005);
                ELSE
                    l_result.header_2 := NULL;
                END IF;
                IF i_flg_new = pk_alert_constant.g_no
                THEN
                    l_result.field_name := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t075);
                ELSE
                    l_result.field_name := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t077);
                END IF;
                --FLOWSHEETS
            WHEN i_field = g_field_parameter_desc THEN
            
                l_result.field_rank := g_field_sr_parameter_desc;
            
                IF i_use_header_2 = pk_alert_constant.g_yes
                THEN
                    l_result.header_2 := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t079);
                ELSE
                    l_result.header_2 := NULL;
                END IF;
                BEGIN
                    l_aux               := pk_utils.str_split(i_list => l_result.field_value, i_delim => '|');
                    l_result.field_name := l_aux(1) || ':';
                
                    l_result.field_value := l_aux(2);
                EXCEPTION
                    WHEN OTHERS THEN
                        l_result.field_name  := NULL;
                        l_result.field_value := NULL;
                END;
            
        -- order co-sign
            WHEN i_field = g_field_o_id_order_type THEN
            
                l_result.field_rank := g_field_sr_o_id_order_type;
            
                IF i_flg_new = pk_alert_constant.g_no
                THEN
                    IF i_use_header_2 = pk_alert_constant.g_yes
                    THEN
                        l_result.header_2 := pk_message.get_message(i_lang      => i_lang,
                                                                    i_code_mess => g_sm_comm_order_t043);
                    ELSE
                        l_result.header_2 := NULL;
                    END IF;
                ELSE
                    IF i_use_header_2 = pk_alert_constant.g_yes
                    THEN
                        l_result.header_2 := pk_message.get_message(i_lang      => i_lang,
                                                                    i_code_mess => g_sm_comm_order_t044);
                    ELSE
                        l_result.header_2 := NULL;
                    END IF;
                    l_result.field_style := g_field_style_new_h2;
                    l_result.style_rank  := g_field_style_rank_new_h2;
                END IF;
            
                l_result.field_name := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t040);
            
            WHEN i_field = g_field_o_prof_order THEN
            
                l_result.field_rank := g_field_sr_o_prof_order;
            
                IF i_flg_new = pk_alert_constant.g_no
                THEN
                    IF i_use_header_2 = pk_alert_constant.g_yes
                    THEN
                        l_result.header_2 := pk_message.get_message(i_lang      => i_lang,
                                                                    i_code_mess => g_sm_comm_order_t043);
                    ELSE
                        l_result.header_2 := NULL;
                    END IF;
                ELSE
                    IF i_use_header_2 = pk_alert_constant.g_yes
                    THEN
                        l_result.header_2 := pk_message.get_message(i_lang      => i_lang,
                                                                    i_code_mess => g_sm_comm_order_t044);
                    ELSE
                        l_result.header_2 := NULL;
                    END IF;
                
                    l_result.field_style := g_field_style_new_h2;
                    l_result.style_rank  := g_field_style_rank_new_h2;
                
                END IF;
            
                l_result.field_name := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t042);
            
            WHEN i_field = g_field_o_dt_order THEN
            
                l_result.field_rank := g_field_sr_o_dt_order;
            
                IF i_flg_new = pk_alert_constant.g_no
                THEN
                    IF i_use_header_2 = pk_alert_constant.g_yes
                    THEN
                        l_result.header_2 := pk_message.get_message(i_lang      => i_lang,
                                                                    i_code_mess => g_sm_comm_order_t043);
                    ELSE
                        l_result.header_2 := NULL;
                    END IF;
                ELSE
                    IF i_use_header_2 = pk_alert_constant.g_yes
                    THEN
                        l_result.header_2 := pk_message.get_message(i_lang      => i_lang,
                                                                    i_code_mess => g_sm_comm_order_t044);
                    ELSE
                        l_result.header_2 := NULL;
                    END IF;
                    l_result.field_style := g_field_style_new_h2;
                    l_result.style_rank  := g_field_style_rank_new_h2;
                END IF;
            
                l_result.field_name := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t041);
            
            WHEN i_field = g_field_o_title THEN
                l_result.field_rank := g_field_sr_o_title;
            
            WHEN i_field IN (g_field_o_notes, g_field_e_notes, g_field_c_notes, g_field_d_notes) THEN
            
                CASE i_field
                    WHEN g_field_o_notes THEN
                        l_result.field_rank := g_field_sr_o_notes;
                    WHEN g_field_e_notes THEN
                        l_result.field_rank := g_field_sr_e_notes;
                    WHEN g_field_c_notes THEN
                        l_result.field_rank := g_field_sr_c_notes;
                    WHEN g_field_d_notes THEN
                        l_result.field_rank := g_field_sr_d_notes;
                END CASE;
            
                l_result.header_2 := NULL;
            
                IF i_flg_new = pk_alert_constant.g_no
                THEN
                    l_result.field_name := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t053);
                ELSE
                    l_result.field_name := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t054);
                END IF;
            
        -- edition co-sign
            WHEN i_field = g_field_e_id_order_type THEN
                l_result.field_rank := g_field_sr_e_id_order_type;
            
                IF i_flg_new = pk_alert_constant.g_no
                THEN
                    IF i_use_header_2 = pk_alert_constant.g_yes
                    THEN
                        l_result.header_2 := pk_message.get_message(i_lang      => i_lang,
                                                                    i_code_mess => g_sm_comm_order_t043);
                    ELSE
                        l_result.header_2 := NULL;
                    END IF;
                ELSE
                    IF i_use_header_2 = pk_alert_constant.g_yes
                    THEN
                        l_result.header_2 := pk_message.get_message(i_lang      => i_lang,
                                                                    i_code_mess => g_sm_comm_order_t044);
                    ELSE
                        l_result.header_2 := NULL;
                    END IF;
                    l_result.field_style := g_field_style_new_h2;
                    l_result.style_rank  := g_field_style_rank_new_h2;
                END IF;
            
                l_result.field_name := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t040);
            
            WHEN i_field = g_field_e_prof_order THEN
                l_result.field_rank := g_field_sr_e_prof_order;
            
                IF i_flg_new = pk_alert_constant.g_no
                THEN
                    IF i_use_header_2 = pk_alert_constant.g_yes
                    THEN
                        l_result.header_2 := pk_message.get_message(i_lang      => i_lang,
                                                                    i_code_mess => g_sm_comm_order_t043);
                    ELSE
                        l_result.header_2 := NULL;
                    END IF;
                ELSE
                    IF i_use_header_2 = pk_alert_constant.g_yes
                    THEN
                        l_result.header_2 := pk_message.get_message(i_lang      => i_lang,
                                                                    i_code_mess => g_sm_comm_order_t044);
                    ELSE
                        l_result.header_2 := NULL;
                    END IF;
                    l_result.field_style := g_field_style_new_h2;
                    l_result.style_rank  := g_field_style_rank_new_h2;
                END IF;
            
                l_result.field_name := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t042);
            
            WHEN i_field = g_field_e_dt_order THEN
            
                l_result.field_rank := g_field_sr_e_dt_order;
            
                IF i_flg_new = pk_alert_constant.g_no
                THEN
                    IF i_use_header_2 = pk_alert_constant.g_yes
                    THEN
                        l_result.header_2 := pk_message.get_message(i_lang      => i_lang,
                                                                    i_code_mess => g_sm_comm_order_t043);
                    ELSE
                        l_result.header_2 := NULL;
                    END IF;
                ELSE
                    IF i_use_header_2 = pk_alert_constant.g_yes
                    THEN
                        l_result.header_2 := pk_message.get_message(i_lang      => i_lang,
                                                                    i_code_mess => g_sm_comm_order_t044);
                    ELSE
                        l_result.header_2 := NULL;
                    END IF;
                
                    l_result.field_style := g_field_style_new_h2;
                    l_result.style_rank  := g_field_style_rank_new_h2;
                
                END IF;
            
                l_result.field_name := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t041);
            
            WHEN i_field = g_field_e_title THEN
                l_result.field_rank := g_field_sr_e_title;
            
        -- cancellation co-sign
            WHEN i_field = g_field_c_id_order_type THEN
            
                l_result.field_rank := g_field_sr_c_id_order_type;
            
                IF i_flg_new = pk_alert_constant.g_no
                THEN
                    IF i_use_header_2 = pk_alert_constant.g_yes
                    THEN
                        l_result.header_2 := pk_message.get_message(i_lang      => i_lang,
                                                                    i_code_mess => g_sm_comm_order_t047);
                    ELSE
                        l_result.header_2 := NULL;
                    END IF;
                ELSE
                    IF i_use_header_2 = pk_alert_constant.g_yes
                    THEN
                        l_result.header_2 := pk_message.get_message(i_lang      => i_lang,
                                                                    i_code_mess => g_sm_comm_order_t048);
                    ELSE
                        l_result.header_2 := NULL;
                    END IF;
                
                    l_result.field_style := g_field_style_new_h2;
                    l_result.style_rank  := g_field_style_rank_new_h2;
                
                END IF;
            
                l_result.field_name := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t040);
            
            WHEN i_field = g_field_c_prof_order THEN
            
                l_result.field_rank := g_field_sr_c_prof_order;
            
                IF i_flg_new = pk_alert_constant.g_no
                THEN
                    IF i_use_header_2 = pk_alert_constant.g_yes
                    THEN
                        l_result.header_2 := pk_message.get_message(i_lang      => i_lang,
                                                                    i_code_mess => g_sm_comm_order_t047);
                    ELSE
                        l_result.header_2 := NULL;
                    END IF;
                ELSE
                    IF i_use_header_2 = pk_alert_constant.g_yes
                    THEN
                        l_result.header_2 := pk_message.get_message(i_lang      => i_lang,
                                                                    i_code_mess => g_sm_comm_order_t048);
                    ELSE
                        l_result.header_2 := NULL;
                    END IF;
                    l_result.field_style := g_field_style_new_h2;
                    l_result.style_rank  := g_field_style_rank_new_h2;
                END IF;
            
                l_result.field_name := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t042);
            
            WHEN i_field = g_field_c_dt_order THEN
            
                l_result.field_rank := g_field_sr_c_dt_order;
            
                IF i_flg_new = pk_alert_constant.g_no
                THEN
                    IF i_use_header_2 = pk_alert_constant.g_yes
                    THEN
                        l_result.header_2 := pk_message.get_message(i_lang      => i_lang,
                                                                    i_code_mess => g_sm_comm_order_t047);
                    ELSE
                        l_result.header_2 := NULL;
                    END IF;
                ELSE
                    IF i_use_header_2 = pk_alert_constant.g_yes
                    THEN
                        l_result.header_2 := pk_message.get_message(i_lang      => i_lang,
                                                                    i_code_mess => g_sm_comm_order_t048);
                    ELSE
                        l_result.header_2 := NULL;
                    END IF;
                
                    l_result.field_style := g_field_style_new_h2;
                    l_result.style_rank  := g_field_style_rank_new_h2;
                
                END IF;
            
                l_result.field_name := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t041);
            
            WHEN i_field = g_field_c_title THEN
            
                l_result.field_rank := g_field_sr_c_title;
            
        -- discontinuation co-sign
            WHEN i_field = g_field_d_id_order_type THEN
            
                l_result.field_rank := g_field_sr_d_id_order_type;
            
                IF i_flg_new = pk_alert_constant.g_no
                THEN
                    IF i_use_header_2 = pk_alert_constant.g_yes
                    THEN
                        l_result.header_2 := pk_message.get_message(i_lang      => i_lang,
                                                                    i_code_mess => g_sm_comm_order_t049);
                    ELSE
                        l_result.header_2 := NULL;
                    END IF;
                ELSE
                    IF i_use_header_2 = pk_alert_constant.g_yes
                    THEN
                        l_result.header_2 := pk_message.get_message(i_lang      => i_lang,
                                                                    i_code_mess => g_sm_comm_order_t050);
                    ELSE
                        l_result.header_2 := NULL;
                    END IF;
                
                    l_result.field_style := g_field_style_new_h2;
                    l_result.style_rank  := g_field_style_rank_new_h2;
                
                END IF;
            
                l_result.field_name := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t040);
            
            WHEN i_field = g_field_d_prof_order THEN
            
                l_result.field_rank := g_field_sr_d_prof_order;
            
                IF i_flg_new = pk_alert_constant.g_no
                THEN
                    IF i_use_header_2 = pk_alert_constant.g_yes
                    THEN
                        l_result.header_2 := pk_message.get_message(i_lang      => i_lang,
                                                                    i_code_mess => g_sm_comm_order_t049);
                    ELSE
                        l_result.header_2 := NULL;
                    END IF;
                ELSE
                    IF i_use_header_2 = pk_alert_constant.g_yes
                    THEN
                        l_result.header_2 := pk_message.get_message(i_lang      => i_lang,
                                                                    i_code_mess => g_sm_comm_order_t050);
                    ELSE
                        l_result.header_2 := NULL;
                    END IF;
                
                    l_result.field_style := g_field_style_new_h2;
                    l_result.style_rank  := g_field_style_rank_new_h2;
                
                END IF;
            
                l_result.field_name := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t042);
            
            WHEN i_field = g_field_d_dt_order THEN
            
                l_result.field_rank := g_field_sr_d_dt_order;
            
                IF i_flg_new = pk_alert_constant.g_no
                THEN
                    IF i_use_header_2 = pk_alert_constant.g_yes
                    THEN
                        l_result.header_2 := pk_message.get_message(i_lang      => i_lang,
                                                                    i_code_mess => g_sm_comm_order_t049);
                    ELSE
                        l_result.header_2 := NULL;
                    END IF;
                ELSE
                    IF i_use_header_2 = pk_alert_constant.g_yes
                    THEN
                        l_result.header_2 := pk_message.get_message(i_lang      => i_lang,
                                                                    i_code_mess => g_sm_comm_order_t050);
                    ELSE
                        l_result.header_2 := NULL;
                    END IF;
                
                    l_result.field_style := g_field_style_new_h2;
                    l_result.style_rank  := g_field_style_rank_new_h2;
                
                END IF;
            
                l_result.field_name := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t041);
            
            WHEN i_field = g_field_d_title THEN
            
                l_result.field_rank := g_field_sr_d_title;
            
            WHEN i_field = g_field_cancel_reason THEN
            
                l_result.field_rank := g_field_sr_cancel_reason;
                l_result.header_2   := NULL;
            
                IF i_flg_new = pk_alert_constant.g_no
                THEN
                    l_result.field_name := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_m009);
                ELSE
                    l_result.field_name := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t057);
                END IF;
            
            WHEN i_field = g_field_cancel_notes THEN
            
                l_result.field_rank := g_field_sr_cancel_notes;
                l_result.header_2   := NULL;
            
                IF i_flg_new = pk_alert_constant.g_no
                THEN
                    l_result.field_name := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_m008);
                ELSE
                    l_result.field_name := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t058);
                END IF;
            
            WHEN i_field = g_field_discontinue_reason THEN
            
                l_result.field_rank := g_field_sr_discontinue_reason;
                l_result.header_2   := NULL;
            
                IF i_flg_new = pk_alert_constant.g_no
                THEN
                    l_result.field_name := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_m010);
                ELSE
                    l_result.field_name := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t055);
                END IF;
            
            WHEN i_field = g_field_discontinue_notes THEN
            
                l_result.field_rank := g_field_sr_discontinue_notes;
                l_result.header_2   := NULL;
            
                IF i_flg_new = pk_alert_constant.g_no
                THEN
                    l_result.field_name := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_m011);
                ELSE
                    l_result.field_name := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t056);
                END IF;
            
            WHEN i_field = g_field_acknowledge THEN
            
                l_result.header_2   := NULL;
                l_result.field_name := NULL;
            
            WHEN i_field = g_field_status THEN
            
                l_result.field_rank := g_field_sr_status;
            
                l_result.header_2 := NULL;
            
                IF i_flg_new = pk_alert_constant.g_no
                THEN
                    l_result.field_name := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t051);
                ELSE
                    l_result.field_name := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t052);
                END IF;
                --Clinical questions
            WHEN i_field = g_field_clinical_question THEN
            
                l_result.field_rank := g_field_sr_clin_quest;
            
                IF i_use_header_2 = pk_alert_constant.g_yes
                THEN
                    l_result.header_2 := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t074);
                ELSE
                    l_result.header_2 := NULL;
                END IF;
                IF i_flg_new = pk_alert_constant.g_no
                THEN
                    l_result.field_name := i_clinical_question_desc;
                ELSE
                    l_result.field_name := i_clinical_question_desc || ' (updated)'; --update
                END IF;
            
            ELSE
                g_error := 'Field name ' || i_field || ' not supported / ';
                RAISE g_exception;
        END CASE;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'FORMAT_FIELD',
                                              o_error    => l_error);
            RETURN NULL;
    END format_field;

    FUNCTION get_co_sign_action(i_id_task IN co_sign.id_task%TYPE) RETURN comm_order_req.flg_action%TYPE IS
    
        l_flg_action comm_order_req.flg_action%TYPE;
    
    BEGIN
    
        SELECT h.flg_action
          INTO l_flg_action
          FROM comm_order_req_hist h
         WHERE h.id_comm_order_req_hist = i_id_task;
    
        RETURN l_flg_action;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error('GET_CO_SIGN_ACTION / ' || SQLERRM);
            RETURN NULL;
    END get_co_sign_action;

    FUNCTION format_data_co_sign
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_rec_comm_order_req IN t_rec_comm_order_req,
        i_header_1           IN VARCHAR2 DEFAULT NULL,
        i_rank               IN PLS_INTEGER,
        i_signature          IN VARCHAR2,
        io_id_section        IN OUT PLS_INTEGER,
        io_data              IN OUT NOCOPY t_coll_comm_order_req_det,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rec_comm_order_req_det t_rec_comm_order_req_det;
        l_field_value            CLOB;
        l_dt_detail              TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_field                  VARCHAR2(30 CHAR);
        l_rec_co_sign            t_rec_co_sign;
        l_flg_action             comm_order_req.flg_action%TYPE;
    
    BEGIN
    
        IF io_data IS NULL
        THEN
            io_data := t_coll_comm_order_req_det();
        END IF;
    
        -- getting common values
        l_dt_detail := i_rec_comm_order_req.dt_status;
    
        g_error := 'FOR i IN 1 .. ' || i_rec_comm_order_req.co_sign_data.count;
        FOR i IN 1 .. i_rec_comm_order_req.co_sign_data.count
        LOOP
        
            l_rec_co_sign := i_rec_comm_order_req.co_sign_data(i);
        
            -- get the action
            g_error      := 'Call get_co_sign_action / ';
            l_flg_action := get_co_sign_action(i_id_task => l_rec_co_sign.id_task);
        
            -- Co-sign
            -- Order type
            g_error := 'CASE l_flg_action / l_flg_action=' || l_flg_action || ' / ';
            CASE
                WHEN l_flg_action IN (g_action_order, g_action_draft) THEN
                    l_field := g_field_o_id_order_type;
                WHEN l_flg_action = g_action_edition THEN
                    l_field := g_field_e_id_order_type;
                WHEN l_flg_action = g_action_canceled THEN
                    l_field := g_field_c_id_order_type;
                WHEN l_flg_action = g_action_dicontinued THEN
                    l_field := g_field_d_id_order_type;
                ELSE
                    l_field := NULL;
            END CASE;
        
            -- Order type
            g_error       := 'Order type / ';
            l_field_value := pk_translation.get_translation(i_lang, g_code_order_type || l_rec_co_sign.id_order_type);
        
            g_error                  := 'Call format_field id_order_type / ';
            l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                     i_prof              => i_prof,
                                                     i_id_comm_order_req => i_rec_comm_order_req.id_comm_order_req,
                                                     i_field             => l_field,
                                                     i_id_section        => io_id_section,
                                                     i_header_1          => i_header_1,
                                                     i_signature         => i_signature,
                                                     i_field_value       => l_field_value,
                                                     i_rank              => i_rank,
                                                     i_dt_detail         => l_dt_detail);
        
            g_error := 'io_data.extend / ';
            io_data.extend;
            io_data(io_data.last) := l_rec_comm_order_req_det;
        
            -- Ordered by
            g_error       := 'Ordered by ';
            l_field_value := l_rec_co_sign.desc_prof_ordered_by;
            IF l_field_value IS NOT NULL
            THEN
            
                g_error := 'CASE l_flg_action / l_flg_action=' || l_flg_action;
                CASE
                    WHEN l_flg_action IN (g_action_order, g_action_draft) THEN
                        l_field := g_field_o_prof_order;
                    WHEN l_flg_action = g_action_edition THEN
                        l_field := g_field_e_prof_order;
                    WHEN l_flg_action = g_action_canceled THEN
                        l_field := g_field_c_prof_order;
                    WHEN l_flg_action = g_action_dicontinued THEN
                        l_field := g_field_d_prof_order;
                    ELSE
                        l_field := NULL;
                END CASE;
            
                g_error                  := 'Call format_field prof_order ';
                l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                         i_prof              => i_prof,
                                                         i_id_comm_order_req => i_rec_comm_order_req.id_comm_order_req,
                                                         i_field             => l_field,
                                                         i_id_section        => io_id_section,
                                                         i_header_1          => i_header_1,
                                                         i_signature         => i_signature,
                                                         i_field_value       => l_field_value,
                                                         i_rank              => i_rank,
                                                         i_dt_detail         => l_dt_detail);
            
                g_error := 'io_data.extend ';
                io_data.extend;
                io_data(io_data.last) := l_rec_comm_order_req_det;
            END IF;
        
            -- Ordered at
            IF l_rec_co_sign.dt_ordered_by IS NOT NULL
            THEN
                g_error       := 'Ordered at ';
                l_field_value := pk_date_utils.dt_chr_date_hour_tsz(i_lang, l_rec_co_sign.dt_ordered_by, i_prof);
            
                g_error := 'CASE l_flg_action / l_flg_action=' || l_flg_action;
                CASE
                    WHEN l_flg_action IN (g_action_order, g_action_draft) THEN
                        l_field := g_field_o_dt_order;
                    WHEN l_flg_action = g_action_edition THEN
                        l_field := g_field_e_dt_order;
                    WHEN l_flg_action = g_action_canceled THEN
                        l_field := g_field_c_dt_order;
                    WHEN l_flg_action = g_action_dicontinued THEN
                        l_field := g_field_d_dt_order;
                    ELSE
                        l_field := NULL;
                END CASE;
            
                g_error                  := 'Call format_field prof_order ';
                l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                         i_prof              => i_prof,
                                                         i_id_comm_order_req => i_rec_comm_order_req.id_comm_order_req,
                                                         i_field             => l_field,
                                                         i_id_section        => io_id_section,
                                                         i_header_1          => i_header_1,
                                                         i_signature         => i_signature,
                                                         i_field_value       => l_field_value,
                                                         i_rank              => i_rank,
                                                         i_dt_detail         => l_dt_detail);
            
                g_error := 'io_data.extend ';
                io_data.extend;
                io_data(io_data.last) := l_rec_comm_order_req_det;
            END IF;
        
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
                                              i_function => 'FORMAT_DATA_CO_SIGN',
                                              o_error    => o_error);
            RETURN FALSE;
    END format_data_co_sign;

    FUNCTION format_data_co_signed
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_rec_comm_order_req IN t_rec_comm_order_req,
        i_rank               IN PLS_INTEGER,
        io_id_section        IN OUT PLS_INTEGER,
        io_data              IN OUT NOCOPY t_coll_comm_order_req_det,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rec_comm_order_req_det t_rec_comm_order_req_det;
        l_header_1               VARCHAR2(1000 CHAR);
        l_code_header_1          sys_message.code_message%TYPE;
        l_signature              VARCHAR2(1000 CHAR);
        l_field_value            CLOB;
        l_dt_detail              TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_field                  VARCHAR2(30 CHAR);
        l_rec_co_sign            t_rec_co_sign;
        l_co_signed_data         t_table_co_sign;
        l_flg_action             comm_order_req_hist.flg_action%TYPE;
    
    BEGIN
    
        IF io_data IS NULL
        THEN
            io_data := t_coll_comm_order_req_det();
        END IF;
    
        -- get all co-signed co-signs
        g_error := 'SELECT t_rec_co_sign() co-signed ';
        SELECT /*+opt_estimate (table cs rows=1)*/
         t_rec_co_sign(id_co_sign           => cs.id_co_sign,
                       id_co_sign_hist      => cs.id_co_sign_hist,
                       id_episode           => cs.id_episode,
                       id_task              => cs.id_task,
                       id_task_group        => cs.id_task_group,
                       id_task_type         => cs.id_task_type,
                       desc_task_type       => cs.desc_task_type,
                       icon_task_type       => cs.icon_task_type,
                       id_action            => cs.id_action,
                       desc_action          => cs.desc_action,
                       id_task_type_action  => cs.id_task_type_action,
                       desc_order           => cs.desc_order,
                       desc_instructions    => cs.desc_instructions,
                       desc_task_action     => cs.desc_task_action,
                       id_order_type        => cs.id_order_type,
                       desc_order_type      => cs.desc_order_type,
                       id_prof_created      => cs.id_prof_created,
                       id_prof_ordered_by   => cs.id_prof_ordered_by,
                       desc_prof_ordered_by => cs.desc_prof_ordered_by,
                       id_prof_co_signed    => cs.id_prof_co_signed,
                       dt_req               => cs.dt_req,
                       dt_created           => cs.dt_created,
                       dt_ordered_by        => cs.dt_ordered_by,
                       dt_co_signed         => cs.dt_co_signed,
                       dt_exec_date_sort    => cs.dt_exec_date_sort,
                       flg_status           => cs.flg_status,
                       icon_status          => cs.icon_status,
                       desc_status          => cs.desc_status,
                       code_co_sign_notes   => cs.code_co_sign_notes,
                       co_sign_notes        => cs.co_sign_notes,
                       flg_has_notes        => cs.flg_has_notes,
                       flg_needs_cosign     => cs.flg_needs_cosign,
                       flg_has_cosign       => cs.flg_has_cosign,
                       flg_made_auth        => cs.flg_made_auth)
          BULK COLLECT
          INTO l_co_signed_data
          FROM TABLE(i_rec_comm_order_req.co_sign_data) cs
         WHERE cs.flg_status = pk_co_sign_api.g_cosign_flg_status_cs; -- all co-signed co-signs
    
        g_error := 'FOR i IN 1 .. ' || l_co_signed_data.count;
        FOR i IN 1 .. l_co_signed_data.count
        LOOP
        
            l_rec_co_sign := l_co_signed_data(i);
        
            -- get flg_action related to this co-sign
            g_error      := 'Call get_co_sign_action ';
            l_flg_action := get_co_sign_action(i_id_task => l_rec_co_sign.id_task);
        
            -- getting common values
            g_error := 'CASE l_flg_action / l_flg_action=' || l_flg_action;
            CASE
                WHEN l_flg_action IN (g_action_order, g_action_draft) THEN
                    l_code_header_1 := g_sm_comm_order_t043;
                WHEN l_flg_action = g_action_edition THEN
                    l_code_header_1 := g_sm_comm_order_t043;
                WHEN l_flg_action = g_action_canceled THEN
                    l_code_header_1 := g_sm_comm_order_t047;
                WHEN l_flg_action = g_action_dicontinued THEN
                    l_code_header_1 := g_sm_comm_order_t049;
                ELSE
                    l_code_header_1 := NULL;
            END CASE;
        
            l_header_1 := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_header_1);
        
            -- output this records only if the co-sign was co-signed                
            l_dt_detail   := l_rec_co_sign.dt_co_signed;
            io_id_section := io_id_section + 1;
        
            g_error  := 'Call get_signature / ID_PROF=' || i_rec_comm_order_req.id_professional;
            g_retval := get_signature(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_code_message => g_sm_comm_order_m005, -- 'Documented:'
                                      i_id_prof_op   => l_rec_co_sign.id_prof_co_signed,
                                      i_dt_op        => l_dt_detail,
                                      o_text         => l_signature,
                                      o_error        => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            -- Co-sign
            -- co-sign notes
            IF l_rec_co_sign.flg_has_notes = pk_alert_constant.g_yes
            THEN
                g_error := 'CASE l_flg_action / l_flg_action=' || l_flg_action;
                CASE
                    WHEN l_flg_action IN (g_action_order, g_action_draft) THEN
                        l_field := g_field_o_notes;
                    WHEN l_flg_action = g_action_edition THEN
                        l_field := g_field_e_notes;
                    WHEN l_flg_action = g_action_canceled THEN
                        l_field := g_field_c_notes;
                    WHEN l_flg_action = g_action_dicontinued THEN
                        l_field := g_field_d_notes;
                    ELSE
                        l_field := NULL;
                END CASE;
            
                g_error       := 'Co-sign notes ';
                l_field_value := pk_translation.get_translation_trs(l_rec_co_sign.code_co_sign_notes);
            
                g_error                  := 'Call format_field co-sign notes ';
                l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                         i_prof              => i_prof,
                                                         i_id_comm_order_req => i_rec_comm_order_req.id_comm_order_req,
                                                         i_field             => l_field,
                                                         i_id_section        => io_id_section,
                                                         i_header_1          => l_header_1,
                                                         i_signature         => l_signature,
                                                         i_field_value       => l_field_value,
                                                         i_rank              => i_rank,
                                                         i_dt_detail         => l_dt_detail);
            
                g_error := 'io_data.extend ';
                io_data.extend;
                io_data(io_data.last) := l_rec_comm_order_req_det;
            ELSE
                -- no notes specified, print only the title
                -- co-sign title
                g_error := 'CASE l_flg_action / l_flg_action=' || l_flg_action;
                CASE
                    WHEN l_flg_action IN (g_action_order, g_action_draft) THEN
                        l_field := g_field_o_title;
                    WHEN l_flg_action = g_action_edition THEN
                        l_field := g_field_e_title;
                    WHEN l_flg_action = g_action_canceled THEN
                        l_field := g_field_c_title;
                    WHEN l_flg_action = g_action_dicontinued THEN
                        l_field := g_field_d_title;
                    ELSE
                        l_field := NULL;
                END CASE;
            
                g_error                  := 'Call format_field co-sign title ';
                l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                         i_prof              => i_prof,
                                                         i_id_comm_order_req => i_rec_comm_order_req.id_comm_order_req,
                                                         i_field             => l_field,
                                                         i_id_section        => io_id_section,
                                                         i_header_1          => l_header_1,
                                                         i_signature         => l_signature,
                                                         i_field_value       => NULL,
                                                         i_rank              => i_rank,
                                                         i_dt_detail         => l_dt_detail);
            
                g_error := 'io_data.extend ';
                io_data.extend;
                io_data(io_data.last) := l_rec_comm_order_req_det;
            END IF;
        
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
                                              i_function => 'FORMAT_DATA_CO_SIGNED',
                                              o_error    => o_error);
            RETURN FALSE;
    END format_data_co_signed;

    FUNCTION format_data_order
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_rec_comm_order_req IN t_rec_comm_order_req,
        i_rank               IN PLS_INTEGER,
        i_sig_code_message   IN sys_message.code_message%TYPE DEFAULT g_sm_comm_order_m005, -- 'Documented:' is default signature message,
        i_field_style        IN VARCHAR2 DEFAULT NULL,
        i_flg_show_status    IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        io_id_section        IN OUT PLS_INTEGER,
        io_data              IN OUT NOCOPY t_coll_comm_order_req_det,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rec_comm_order_req_det t_rec_comm_order_req_det;
        l_header_1               VARCHAR2(1000 CHAR);
        l_signature              VARCHAR2(1000 CHAR);
        l_field_value            CLOB;
        l_dt_detail              TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_field                  VARCHAR2(30 CHAR);
    
        l_count_cq                   NUMBER := 0;
        l_tbl_desc_clinical_question table_varchar;
        l_tbl_desc_response          table_clob;
        l_dt_qc_current              comm_order_question_response.dt_last_update_tstz%TYPE;
        l_dt_qc_rec_comm_order       comm_order_question_response.dt_last_update_tstz%TYPE;
    
    BEGIN
    
        io_id_section := io_id_section + 1;
    
        IF io_data IS NULL
        THEN
            io_data := t_coll_comm_order_req_det();
        END IF;
    
        -- getting common values
        g_error     := 'getting common values ';
        l_header_1  := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t025);
        l_dt_detail := i_rec_comm_order_req.dt_status;
    
        g_error  := 'Call get_signature / ID_PROF=' || i_rec_comm_order_req.id_professional;
        g_retval := get_signature(i_lang         => i_lang,
                                  i_prof         => i_prof,
                                  i_code_message => i_sig_code_message,
                                  i_id_prof_op   => i_rec_comm_order_req.id_professional,
                                  i_dt_op        => l_dt_detail,
                                  o_text         => l_signature,
                                  o_error        => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- Status
        IF i_flg_show_status = pk_alert_constant.g_yes
        THEN
            g_error       := 'Status ';
            l_field_value := get_comm_order_req_sts_desc(i_lang              => i_lang,
                                                         i_prof              => i_prof,
                                                         i_id_status         => i_rec_comm_order_req.id_status,
                                                         i_dt_begin          => i_rec_comm_order_req.dt_begin,
                                                         i_id_comm_order_req => i_rec_comm_order_req.id_comm_order_req);
        
            g_error                  := 'Call format_field ';
            l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                     i_prof              => i_prof,
                                                     i_id_comm_order_req => i_rec_comm_order_req.id_comm_order_req,
                                                     i_field             => g_field_status,
                                                     i_id_section        => io_id_section,
                                                     i_header_1          => l_header_1,
                                                     i_signature         => l_signature,
                                                     i_field_value       => l_field_value,
                                                     i_field_style       => i_field_style,
                                                     i_rank              => i_rank,
                                                     i_dt_detail         => l_dt_detail);
        
            g_error := 'io_data.extend ';
            io_data.extend;
            io_data(io_data.last) := l_rec_comm_order_req_det;
        END IF;
    
        -- Notes
        IF i_rec_comm_order_req.notes IS NOT NULL
           AND length(i_rec_comm_order_req.notes) > 0
        THEN
            g_error                  := 'Notes ';
            l_field_value            := i_rec_comm_order_req.notes;
            l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                     i_prof              => i_prof,
                                                     i_id_comm_order_req => i_rec_comm_order_req.id_comm_order_req,
                                                     i_field             => g_field_notes,
                                                     i_id_section        => io_id_section,
                                                     i_header_1          => l_header_1,
                                                     i_signature         => l_signature,
                                                     i_field_value       => l_field_value,
                                                     i_field_style       => i_field_style,
                                                     i_rank              => i_rank,
                                                     i_dt_detail         => l_dt_detail);
        
            g_error := 'io_data.extend ';
            io_data.extend;
            io_data(io_data.last) := l_rec_comm_order_req_det;
        
        END IF;
    
        -- Clinical Indication
        IF i_rec_comm_order_req.clinical_indication IS NOT NULL
           AND length(i_rec_comm_order_req.clinical_indication) > 0
        THEN
            g_error  := 'Clinical Indication ';
            g_retval := get_diagnoses_text(i_lang                => i_lang,
                                           i_prof                => i_prof,
                                           i_clinical_indication => i_rec_comm_order_req.clinical_indication,
                                           o_text                => l_field_value,
                                           o_error               => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            IF l_field_value IS NOT NULL
            THEN
                l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                         i_prof              => i_prof,
                                                         i_id_comm_order_req => i_rec_comm_order_req.id_comm_order_req,
                                                         i_field             => g_field_clin_indication,
                                                         i_id_section        => io_id_section,
                                                         i_header_1          => l_header_1,
                                                         i_signature         => l_signature,
                                                         i_field_value       => l_field_value,
                                                         i_field_style       => i_field_style,
                                                         i_rank              => i_rank,
                                                         i_dt_detail         => l_dt_detail);
            
                g_error := 'io_data.extend ';
                io_data.extend;
                io_data(io_data.last) := l_rec_comm_order_req_det;
            END IF;
        END IF;
    
        -- Clinical Purpose
        IF i_rec_comm_order_req.flg_clinical_purpose IS NOT NULL
        THEN
            g_error       := 'Clinical Purpose ';
            l_field_value := get_clinical_purpose_desc(i_lang              => i_lang,
                                                       i_prof              => i_prof,
                                                       i_flg_clin_purpose  => i_rec_comm_order_req.flg_clinical_purpose,
                                                       i_clin_purpose_desc => i_rec_comm_order_req.clinical_purpose_desc);
        
            l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                     i_prof              => i_prof,
                                                     i_id_comm_order_req => i_rec_comm_order_req.id_comm_order_req,
                                                     i_field             => g_field_clin_purpose,
                                                     i_id_section        => io_id_section,
                                                     i_header_1          => l_header_1,
                                                     i_signature         => l_signature,
                                                     i_field_value       => l_field_value,
                                                     i_field_style       => i_field_style,
                                                     i_rank              => i_rank,
                                                     i_dt_detail         => l_dt_detail);
        
            g_error := 'io_data.extend ';
            io_data.extend;
            io_data(io_data.last) := l_rec_comm_order_req_det;
        END IF;
    
        -- Instructions
        -- Priority
        IF i_rec_comm_order_req.flg_priority IS NOT NULL
        THEN
            g_error                  := 'Priority ';
            l_field_value            := pk_sysdomain.get_domain(i_code_dom => g_code_priority,
                                                                i_val      => i_rec_comm_order_req.flg_priority,
                                                                i_lang     => i_lang);
            l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                     i_prof              => i_prof,
                                                     i_id_comm_order_req => i_rec_comm_order_req.id_comm_order_req,
                                                     i_field             => g_field_priority,
                                                     i_id_section        => io_id_section,
                                                     i_header_1          => l_header_1,
                                                     i_signature         => l_signature,
                                                     i_field_value       => l_field_value,
                                                     i_field_style       => i_field_style,
                                                     i_rank              => i_rank,
                                                     i_dt_detail         => l_dt_detail);
            g_error                  := 'io_data.extend ';
            io_data.extend;
            io_data(io_data.last) := l_rec_comm_order_req_det;
        END IF;
    
        -- PRN
        IF i_rec_comm_order_req.flg_prn IS NOT NULL
        THEN
            g_error                  := 'PRN ';
            l_field_value            := pk_sysdomain.get_domain(i_code_dom => g_code_prn,
                                                                i_val      => i_rec_comm_order_req.flg_prn,
                                                                i_lang     => i_lang);
            l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                     i_prof              => i_prof,
                                                     i_id_comm_order_req => i_rec_comm_order_req.id_comm_order_req,
                                                     i_field             => g_field_prn,
                                                     i_id_section        => io_id_section,
                                                     i_header_1          => l_header_1,
                                                     i_signature         => l_signature,
                                                     i_field_value       => l_field_value,
                                                     i_field_style       => i_field_style,
                                                     i_rank              => i_rank,
                                                     i_dt_detail         => l_dt_detail);
            g_error                  := 'io_data.extend ';
            io_data.extend;
            io_data(io_data.last) := l_rec_comm_order_req_det;
        END IF;
    
        -- PRN condition
        IF i_rec_comm_order_req.prn_condition IS NOT NULL
           AND length(i_rec_comm_order_req.prn_condition) > 0
        THEN
            g_error                  := 'PRN condition ';
            l_field_value            := i_rec_comm_order_req.prn_condition;
            l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                     i_prof              => i_prof,
                                                     i_id_comm_order_req => i_rec_comm_order_req.id_comm_order_req,
                                                     i_field             => g_field_prn_condition,
                                                     i_id_section        => io_id_section,
                                                     i_header_1          => l_header_1,
                                                     i_signature         => l_signature,
                                                     i_field_value       => l_field_value,
                                                     i_field_style       => i_field_style,
                                                     i_rank              => i_rank,
                                                     i_dt_detail         => l_dt_detail);
            g_error                  := 'io_data.extend ';
            io_data.extend;
            io_data(io_data.last) := l_rec_comm_order_req_det;
        END IF;
    
        -- Start date
        IF i_rec_comm_order_req.dt_begin IS NOT NULL
        THEN
            g_error                  := 'Start date ';
            l_field_value            := pk_date_utils.dt_chr_date_hour_tsz(i_lang,
                                                                           i_rec_comm_order_req.dt_begin,
                                                                           i_prof);
            l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                     i_prof              => i_prof,
                                                     i_id_comm_order_req => i_rec_comm_order_req.id_comm_order_req,
                                                     i_field             => g_field_dt_begin,
                                                     i_id_section        => io_id_section,
                                                     i_header_1          => l_header_1,
                                                     i_signature         => l_signature,
                                                     i_field_value       => l_field_value,
                                                     i_field_style       => i_field_style,
                                                     i_rank              => i_rank,
                                                     i_dt_detail         => l_dt_detail);
        
            g_error := 'io_data.extend ';
            io_data.extend;
            io_data(io_data.last) := l_rec_comm_order_req_det;
        END IF;
    
        --Frequency and task duration (Only for medical orders)
        IF i_rec_comm_order_req.id_task_type = pk_alert_constant.g_task_medical_orders
           OR
           pk_sysconfig.get_config(i_code_cf => g_comm_order_exec_workflow, i_prof => i_prof) = pk_alert_constant.g_yes
        THEN
            --Frequency
            g_error := 'Frequency ';
        
            IF i_rec_comm_order_req.id_order_recurr IS NULL
            THEN
                l_field_value := pk_translation.get_translation(i_lang,
                                                                'ORDER_RECURR_OPTION.CODE_ORDER_RECURR_OPTION.0');
            ELSE
                l_field_value := pk_order_recurrence_api_db.get_order_recurr_plan_desc(i_lang,
                                                                                       i_prof,
                                                                                       i_rec_comm_order_req.id_order_recurr);
            END IF;
        
            l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                     i_prof              => i_prof,
                                                     i_id_comm_order_req => i_rec_comm_order_req.id_comm_order_req,
                                                     i_field             => g_field_frequency,
                                                     i_id_section        => io_id_section,
                                                     i_header_1          => l_header_1,
                                                     i_signature         => l_signature,
                                                     i_field_value       => l_field_value,
                                                     i_field_style       => i_field_style,
                                                     i_rank              => i_rank,
                                                     i_dt_detail         => l_dt_detail);
        
            g_error := 'io_data.extend ';
            io_data.extend;
            io_data(io_data.last) := l_rec_comm_order_req_det;
            --time period of execution
            g_error := 'Task duration ';
        
            IF i_rec_comm_order_req.task_duration IS NOT NULL
            THEN
            
                l_field_value := i_rec_comm_order_req.task_duration || ' ' ||
                                 pk_unit_measure.get_unit_measure_description(i_lang         => i_lang,
                                                                              i_prof         => i_prof,
                                                                              i_unit_measure => 10374);
            
                l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                         i_prof              => i_prof,
                                                         i_id_comm_order_req => i_rec_comm_order_req.id_comm_order_req,
                                                         i_field             => g_field_task_duration,
                                                         i_id_section        => io_id_section,
                                                         i_header_1          => l_header_1,
                                                         i_signature         => l_signature,
                                                         i_field_value       => l_field_value,
                                                         i_field_style       => i_field_style,
                                                         i_rank              => i_rank,
                                                         i_dt_detail         => l_dt_detail);
            
                g_error := 'io_data.extend ';
                io_data.extend;
                io_data(io_data.last) := l_rec_comm_order_req_det;
            END IF;
        END IF;
    
        --Clinical questions    
        SELECT COUNT(1)
          INTO l_count_cq
          FROM comm_order_question_response coqr
         WHERE coqr.id_common_order_req = i_rec_comm_order_req.id_comm_order_req;
    
        IF l_count_cq > 0
        THEN
        
            SELECT MAX(coqr.dt_last_update_tstz)
              INTO l_dt_qc_current
              FROM comm_order_question_response coqr
             WHERE coqr.id_common_order_req = i_rec_comm_order_req.id_comm_order_req;
        
            BEGIN
                SELECT DISTINCT coqr.dt_last_update_tstz
                  INTO l_dt_qc_rec_comm_order
                  FROM comm_order_question_response coqr
                 WHERE coqr.id_common_order_req = i_rec_comm_order_req.id_comm_order_req
                   AND coqr.dt_last_update_tstz = i_rec_comm_order_req.dt_status;
            EXCEPTION
                WHEN OTHERS THEN
                    l_dt_qc_rec_comm_order := NULL;
            END;
        
            SELECT desc_clinical_question, desc_response
              BULK COLLECT
              INTO l_tbl_desc_clinical_question, l_tbl_desc_response
              FROM (SELECT DISTINCT coqr1.id_questionnaire,
                                    coqr1.flg_time,
                                    pk_mcdt.get_questionnaire_alias(i_lang,
                                                                    i_prof,
                                                                    'QUESTIONNAIRE.CODE_QUESTIONNAIRE.' ||
                                                                    coqr1.id_questionnaire) || ': ' desc_clinical_question,
                                    dbms_lob.substr(decode(dbms_lob.getlength(coqr.notes),
                                                           NULL,
                                                           to_clob(decode(coqr1.desc_response,
                                                                          NULL,
                                                                          '---',
                                                                          coqr1.desc_response)),
                                                           pk_procedures_utils.get_procedure_response(i_lang,
                                                                                                      i_prof,
                                                                                                      coqr.notes)),
                                                    3800) desc_response,
                                    get_comm_order_question_rank(i_lang,
                                                                 i_prof,
                                                                 cor.id_concept_term,
                                                                 coqr1.id_questionnaire,
                                                                 coqr1.flg_time) rank
                      FROM (SELECT coqr.id_common_order_req,
                                   coqr.id_questionnaire,
                                   coqr.flg_time,
                                   listagg(pk_mcdt.get_response_alias(i_lang,
                                                                      i_prof,
                                                                      'RESPONSE.CODE_RESPONSE.' || coqr.id_response),
                                           '; ') within GROUP(ORDER BY coqr.id_response) desc_response,
                                   coqr.dt_last_update_tstz,
                                   row_number() over(PARTITION BY coqr.id_questionnaire, coqr.flg_time ORDER BY coqr.dt_last_update_tstz DESC NULLS FIRST) rn
                              FROM comm_order_question_response coqr
                             WHERE coqr.id_common_order_req = i_rec_comm_order_req.id_comm_order_req
                               AND coqr.dt_last_update_tstz = nvl(l_dt_qc_rec_comm_order, l_dt_qc_current)
                             GROUP BY coqr.id_common_order_req,
                                      coqr.id_questionnaire,
                                      coqr.flg_time,
                                      coqr.dt_last_update_tstz) coqr1,
                           comm_order_question_response coqr,
                           comm_order_req cor
                     WHERE coqr1.rn = 1
                       AND coqr1.id_common_order_req = coqr.id_common_order_req
                       AND coqr1.id_questionnaire = coqr.id_questionnaire
                       AND coqr1.dt_last_update_tstz = coqr.dt_last_update_tstz
                       AND coqr1.flg_time = coqr.flg_time
                       AND coqr.id_common_order_req = cor.id_comm_order_req)
             ORDER BY flg_time, rank;
        
            g_error := 'Clinical questions';
            FOR i IN l_tbl_desc_clinical_question.first .. l_tbl_desc_clinical_question.last
            LOOP
            
                l_field_value := l_tbl_desc_response(i);
            
                l_rec_comm_order_req_det := format_field(i_lang                   => i_lang,
                                                         i_prof                   => i_prof,
                                                         i_id_comm_order_req      => i_rec_comm_order_req.id_comm_order_req,
                                                         i_field                  => g_field_clinical_question,
                                                         i_id_section             => io_id_section,
                                                         i_header_1               => l_header_1,
                                                         i_signature              => l_signature,
                                                         i_field_value            => l_field_value,
                                                         i_field_style            => i_field_style,
                                                         i_rank                   => i_rank,
                                                         i_dt_detail              => l_dt_detail,
                                                         i_clinical_question_desc => l_tbl_desc_clinical_question(i));
            
                g_error := 'io_data.extend ';
                io_data.extend;
                io_data(io_data.last) := l_rec_comm_order_req_det;
            END LOOP;
        END IF;
    
        -- cancel reason
        IF i_rec_comm_order_req.id_cancel_reason IS NOT NULL
        THEN
            g_error       := 'Cancel reason ';
            l_field_value := pk_translation.get_translation(i_lang      => i_lang,
                                                            i_code_mess => g_code_cancel_reason ||
                                                                           i_rec_comm_order_req.id_cancel_reason);
        
            -- check if this reason is a cancel reason or a discontinue reason
            g_error := 'ID_STATUS=' || i_rec_comm_order_req.id_status;
            IF i_rec_comm_order_req.id_status IN (g_id_sts_canceled, g_id_sts_discontinued)
            THEN
                l_field := g_field_cancel_reason;
            ELSIF i_rec_comm_order_req.id_status = g_id_sts_completed
            THEN
                l_field := g_field_discontinue_reason;
            END IF;
        
            g_error                  := 'Call format_field / l_field=' || l_field;
            l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                     i_prof              => i_prof,
                                                     i_id_comm_order_req => i_rec_comm_order_req.id_comm_order_req,
                                                     i_field             => l_field,
                                                     i_id_section        => io_id_section,
                                                     i_header_1          => l_header_1,
                                                     i_signature         => l_signature,
                                                     i_field_value       => l_field_value,
                                                     i_rank              => i_rank,
                                                     i_dt_detail         => l_dt_detail);
        
            g_error := 'io_data.extend ';
            io_data.extend;
            io_data(io_data.last) := l_rec_comm_order_req_det;
        END IF;
    
        -- cancel notes
        IF i_rec_comm_order_req.notes_cancel IS NOT NULL
           AND length(i_rec_comm_order_req.notes_cancel) > 0
        THEN
            g_error       := 'Cancel notes ';
            l_field_value := i_rec_comm_order_req.notes_cancel;
        
            -- check if this reason is a cancel reason or a discontinue reason
            g_error := 'ID_STATUS=' || i_rec_comm_order_req.id_status;
            IF i_rec_comm_order_req.id_status = g_id_sts_canceled
            THEN
                l_field := g_field_cancel_notes;
            ELSIF i_rec_comm_order_req.id_status = g_id_sts_completed
            THEN
                l_field := g_field_discontinue_notes;
            END IF;
        
            g_error                  := 'Call format_field / l_field=' || l_field;
            l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                     i_prof              => i_prof,
                                                     i_id_comm_order_req => i_rec_comm_order_req.id_comm_order_req,
                                                     i_field             => l_field,
                                                     i_id_section        => io_id_section,
                                                     i_header_1          => l_header_1,
                                                     i_signature         => l_signature,
                                                     i_field_value       => l_field_value,
                                                     i_rank              => i_rank,
                                                     i_dt_detail         => l_dt_detail);
        
            g_error := 'io_data.extend ';
            io_data.extend;
            io_data(io_data.last) := l_rec_comm_order_req_det;
        END IF;
    
        -- Co-sign data
        g_error  := 'Call format_data_co_sign ';
        g_retval := format_data_co_sign(i_lang               => i_lang,
                                        i_prof               => i_prof,
                                        i_rec_comm_order_req => i_rec_comm_order_req,
                                        i_header_1           => l_header_1,
                                        i_rank               => i_rank,
                                        i_signature          => l_signature,
                                        io_id_section        => io_id_section,
                                        io_data              => io_data,
                                        o_error              => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
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
                                              i_function => 'FORMAT_DATA_ORDER',
                                              o_error    => o_error);
            RETURN FALSE;
    END format_data_order;

    FUNCTION format_data_execution
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_rec_comm_order_req  IN t_rec_comm_order_req,
        i_tbl_comm_order_plan IN t_coll_comm_order_plan_info,
        i_rank                IN PLS_INTEGER,
        i_sig_code_message    IN sys_message.code_message%TYPE DEFAULT g_sm_comm_order_m005, -- 'Documented:' is default signature message,
        i_field_style         IN VARCHAR2 DEFAULT NULL,
        i_flg_show_status     IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        io_id_section         IN OUT PLS_INTEGER,
        io_data               IN OUT NOCOPY t_coll_comm_order_req_det,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rec_comm_order_req_det t_rec_comm_order_req_det;
        l_header_1               VARCHAR2(1000 CHAR);
        l_signature              VARCHAR2(1000 CHAR);
        l_field_value            CLOB;
    
        --Template execution/monitorization                
        l_cur_comm_doc_val pk_touch_option_out.t_cur_plain_text_entry;
        l_comm_doc_val_aux pk_touch_option_out.t_rec_plain_text_entry;
        l_template_text    CLOB;
    
        --Flowsheets
        l_id_po_param_reg    po_param_reg.id_po_param_reg%TYPE;
        l_tbl_po_param_desc  table_varchar;
        l_tbl_po_param_value table_varchar;
    
    BEGIN
    
        IF io_data IS NULL
        THEN
            io_data := t_coll_comm_order_req_det();
        END IF;
    
        FOR i IN i_tbl_comm_order_plan.first .. i_tbl_comm_order_plan.last
        LOOP
            IF i_tbl_comm_order_plan(i).action <> g_action_order
            THEN
            
                io_id_section := io_id_section + 1;
            
                --Headers
                IF i_tbl_comm_order_plan(i).action = g_action_executed
                THEN
                    l_header_1 := pk_message.get_message(i_lang, g_sm_comm_order_t070);
                ELSIF i_tbl_comm_order_plan(i).action = g_action_monitored
                THEN
                    l_header_1 := pk_message.get_message(i_lang, g_sm_comm_order_t071);
                ELSIF i_tbl_comm_order_plan(i).action = g_action_concluded
                THEN
                    l_header_1 := pk_message.get_message(i_lang, g_sm_comm_order_t072);
                ELSE
                    --canceled
                    l_header_1 := pk_message.get_message(i_lang, g_sm_comm_order_t073);
                END IF;
            
                l_signature := pk_message.get_message(i_lang, i_sig_code_message) || ' ' || i_tbl_comm_order_plan(i).registry;
            
                --Performed by:
                IF i_tbl_comm_order_plan(i).prof_performed IS NOT NULL
                THEN
                    g_error       := 'Performed by ';
                    l_field_value := i_tbl_comm_order_plan(i).prof_performed;
                
                    l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                             i_prof              => i_prof,
                                                             i_id_comm_order_req => i_rec_comm_order_req.id_comm_order_req,
                                                             i_field             => g_field_performed_by,
                                                             i_id_section        => io_id_section,
                                                             i_header_1          => l_header_1,
                                                             i_signature         => l_signature,
                                                             i_field_value       => l_field_value,
                                                             i_field_style       => i_field_style,
                                                             i_rank              => i_rank,
                                                             i_dt_detail         => i_tbl_comm_order_plan(i).dt_rec,
                                                             i_use_header_2      => pk_alert_constant.g_no);
                
                    g_error := 'io_data.extend ';
                    io_data.extend;
                    io_data(io_data.last) := l_rec_comm_order_req_det;
                END IF;
            
                -- Start date
                IF i_tbl_comm_order_plan(i).start_time IS NOT NULL
                THEN
                    g_error       := 'Start date ';
                    l_field_value := i_tbl_comm_order_plan(i).start_time;
                
                    l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                             i_prof              => i_prof,
                                                             i_id_comm_order_req => i_rec_comm_order_req.id_comm_order_req,
                                                             i_field             => g_field_start_time,
                                                             i_id_section        => io_id_section,
                                                             i_header_1          => l_header_1,
                                                             i_signature         => l_signature,
                                                             i_field_value       => l_field_value,
                                                             i_field_style       => i_field_style,
                                                             i_rank              => i_rank,
                                                             i_dt_detail         => i_tbl_comm_order_plan(i).dt_rec,
                                                             i_use_header_2      => pk_alert_constant.g_no);
                
                    g_error := 'io_data.extend ';
                    io_data.extend;
                    io_data(io_data.last) := l_rec_comm_order_req_det;
                END IF;
            
                --End date      
                IF i_tbl_comm_order_plan(i).end_time IS NOT NULL
                THEN
                    g_error       := 'End date ';
                    l_field_value := i_tbl_comm_order_plan(i).end_time;
                
                    l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                             i_prof              => i_prof,
                                                             i_id_comm_order_req => i_rec_comm_order_req.id_comm_order_req,
                                                             i_field             => g_field_end_time,
                                                             i_id_section        => io_id_section,
                                                             i_header_1          => l_header_1,
                                                             i_signature         => l_signature,
                                                             i_field_value       => l_field_value,
                                                             i_field_style       => i_field_style,
                                                             i_rank              => i_rank,
                                                             i_dt_detail         => i_tbl_comm_order_plan(i).dt_rec,
                                                             i_use_header_2      => pk_alert_constant.g_no);
                
                    g_error := 'io_data.extend ';
                    io_data.extend;
                    io_data(io_data.last) := l_rec_comm_order_req_det;
                END IF;
            
                --Execution notes/Template    
                IF i_tbl_comm_order_plan(i).id_epis_documentation IS NOT NULL
                THEN
                    --Template
                    g_error := 'Template ';
                
                    l_cur_comm_doc_val := NULL;
                    l_comm_doc_val_aux := NULL;
                    pk_touch_option_out.get_plain_text_entries(i_lang                    => i_lang,
                                                               i_prof                    => i_prof,
                                                               i_epis_documentation_list => table_number(i_tbl_comm_order_plan(i).id_epis_documentation),
                                                               i_use_html_format         => pk_procedures_constant.g_yes,
                                                               o_entries                 => l_cur_comm_doc_val);
                
                    FETCH l_cur_comm_doc_val
                        INTO l_comm_doc_val_aux;
                    CLOSE l_cur_comm_doc_val;
                
                    l_template_text := NULL;
                    l_template_text := REPLACE(l_comm_doc_val_aux.plain_text_entry, chr(10));
                    l_template_text := REPLACE(l_template_text, chr(10), chr(10) || chr(9));
                
                    l_field_value := l_template_text;
                
                    l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                             i_prof              => i_prof,
                                                             i_id_comm_order_req => i_rec_comm_order_req.id_comm_order_req,
                                                             i_field             => g_field_template_execution,
                                                             i_id_section        => io_id_section,
                                                             i_header_1          => l_header_1,
                                                             i_signature         => l_signature,
                                                             i_field_value       => l_field_value,
                                                             i_field_style       => i_field_style,
                                                             i_rank              => i_rank,
                                                             i_dt_detail         => i_tbl_comm_order_plan(i).dt_rec,
                                                             i_use_header_2      => pk_alert_constant.g_no);
                
                    g_error := 'io_data.extend ';
                    io_data.extend;
                    io_data(io_data.last) := l_rec_comm_order_req_det;
                
                ELSIF i_tbl_comm_order_plan(i).notes IS NOT NULL
                THEN
                    --Notes
                    g_error       := 'Notes ';
                    l_field_value := i_tbl_comm_order_plan(i).notes;
                
                    l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                             i_prof              => i_prof,
                                                             i_id_comm_order_req => i_rec_comm_order_req.id_comm_order_req,
                                                             i_field             => g_field_notes_execution,
                                                             i_id_section        => io_id_section,
                                                             i_header_1          => l_header_1,
                                                             i_signature         => l_signature,
                                                             i_field_value       => l_field_value,
                                                             i_field_style       => i_field_style,
                                                             i_rank              => i_rank,
                                                             i_dt_detail         => i_tbl_comm_order_plan(i).dt_rec,
                                                             i_use_header_2      => pk_alert_constant.g_no);
                
                    g_error := 'io_data.extend ';
                    io_data.extend;
                    io_data(io_data.last) := l_rec_comm_order_req_det;
                END IF;
            
                --Flowsheets
                g_error := 'Getting id_po_param_reg';
                BEGIN
                    SELECT id_po_param_reg
                      INTO l_id_po_param_reg
                      FROM (SELECT cop.id_po_param_reg
                              FROM comm_order_plan cop
                             WHERE cop.id_comm_order_plan = i_tbl_comm_order_plan(i).id_comm_order_plan
                               AND cop.flg_status <> 'C'
                               AND cop.dt_last_update_tstz = i_tbl_comm_order_plan(i).dt_rec
                            
                            UNION
                            
                            SELECT coph.id_po_param_reg
                              FROM comm_order_plan_hist coph
                             WHERE coph.id_comm_order_plan = i_tbl_comm_order_plan(i).id_comm_order_plan
                               AND coph.flg_status <> 'C'
                               AND coph.dt_last_update_tstz = i_tbl_comm_order_plan(i).dt_rec);
                EXCEPTION
                    WHEN OTHERS THEN
                        l_id_po_param_reg := NULL;
                END;
            
                IF l_id_po_param_reg IS NOT NULL
                THEN
                    IF NOT pk_periodic_observation.get_detail_comm_order(i_lang            => i_lang,
                                                                         i_prof            => i_prof,
                                                                         i_comm_order_req  => i_tbl_comm_order_plan(i).id_comm_order_req,
                                                                         i_po_param_reg    => l_id_po_param_reg,
                                                                         o_parameter_desc  => l_tbl_po_param_desc,
                                                                         o_parameter_value => l_tbl_po_param_value,
                                                                         o_error           => o_error)
                    
                    THEN
                        RAISE g_exception;
                    END IF;
                
                    IF l_tbl_po_param_desc IS NOT NULL
                    THEN
                        FOR j IN l_tbl_po_param_desc.first .. l_tbl_po_param_desc.last
                        LOOP
                        
                            l_field_value := l_tbl_po_param_desc(j) || '|' || l_tbl_po_param_value(j);
                            -- l_field_value := l_tbl_po_param_desc(j);
                            l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                                     i_prof              => i_prof,
                                                                     i_id_comm_order_req => i_rec_comm_order_req.id_comm_order_req,
                                                                     i_field             => g_field_parameter_desc,
                                                                     i_id_section        => io_id_section,
                                                                     i_header_1          => l_header_1,
                                                                     i_signature         => l_signature,
                                                                     i_field_value       => l_field_value,
                                                                     i_field_style       => i_field_style,
                                                                     i_rank              => i_rank,
                                                                     i_dt_detail         => i_tbl_comm_order_plan(i).dt_rec,
                                                                     i_use_header_2      => pk_alert_constant.g_yes);
                        
                            g_error := 'io_data.extend ';
                            io_data.extend;
                            io_data(io_data.last) := l_rec_comm_order_req_det;
                        END LOOP;
                    END IF;
                
                END IF;
            
                --Cancel reason
                IF i_tbl_comm_order_plan(i).cancel_reason IS NOT NULL
                THEN
                    g_error := 'Cancel reason ';
                
                    l_field_value := i_tbl_comm_order_plan(i).cancel_reason;
                
                    l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                             i_prof              => i_prof,
                                                             i_id_comm_order_req => i_rec_comm_order_req.id_comm_order_req,
                                                             i_field             => g_field_cancel_reason,
                                                             i_id_section        => io_id_section,
                                                             i_header_1          => l_header_1,
                                                             i_signature         => l_signature,
                                                             i_field_value       => l_field_value,
                                                             i_field_style       => i_field_style,
                                                             i_rank              => i_rank,
                                                             i_dt_detail         => i_tbl_comm_order_plan(i).dt_rec,
                                                             i_use_header_2      => pk_alert_constant.g_no);
                
                    g_error := 'io_data.extend ';
                    io_data.extend;
                    io_data(io_data.last) := l_rec_comm_order_req_det;
                END IF;
            
                --Cancel notes
                IF i_tbl_comm_order_plan(i).cancel_notes IS NOT NULL
                THEN
                    g_error := 'Cancel reason ';
                
                    l_field_value := i_tbl_comm_order_plan(i).cancel_notes;
                
                    l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                             i_prof              => i_prof,
                                                             i_id_comm_order_req => i_rec_comm_order_req.id_comm_order_req,
                                                             i_field             => g_field_cancel_notes,
                                                             i_id_section        => io_id_section,
                                                             i_header_1          => l_header_1,
                                                             i_signature         => l_signature,
                                                             i_field_value       => l_field_value,
                                                             i_field_style       => i_field_style,
                                                             i_rank              => i_rank,
                                                             i_dt_detail         => i_tbl_comm_order_plan(i).dt_rec,
                                                             i_use_header_2      => pk_alert_constant.g_no);
                
                    g_error := 'io_data.extend ';
                    io_data.extend;
                    io_data(io_data.last) := l_rec_comm_order_req_det;
                END IF;
            END IF;
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
                                              i_function => 'FORMAT_DATA_EXECUTION',
                                              o_error    => o_error);
            RETURN FALSE;
    END format_data_execution;

    FUNCTION format_data_ack
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_comm_order_req IN comm_order_req_ack.id_comm_order_req%TYPE,
        i_rank              IN PLS_INTEGER,
        io_id_section       IN OUT PLS_INTEGER,
        io_data             IN OUT NOCOPY t_coll_comm_order_req_det,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rec_comm_order_req_det t_rec_comm_order_req_det;
        l_header_1               VARCHAR2(1000 CHAR);
        l_signature              VARCHAR2(1000 CHAR);
        l_dt_detail              TIMESTAMP(6) WITH LOCAL TIME ZONE;
    
        CURSOR c_ack IS
            SELECT cora.id_prof_ack, cora.dt_ack
              FROM comm_order_req_ack cora
             WHERE cora.id_comm_order_req = i_id_comm_order_req;
    
        TYPE t_ack IS TABLE OF c_ack%ROWTYPE;
        l_ack_tab t_ack;
    
    BEGIN
    
        IF io_data IS NULL
        THEN
            io_data := t_coll_comm_order_req_det();
        END IF;
    
        -- getting common values
        g_error    := 'getting common values ';
        l_header_1 := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t027);
    
        OPEN c_ack;
        FETCH c_ack BULK COLLECT
            INTO l_ack_tab;
        CLOSE c_ack;
    
        g_error := 'FOR i IN 1 .. ' || l_ack_tab.count;
        FOR i IN 1 .. l_ack_tab.count
        LOOP
        
            g_error     := 'Call pk_prof_utils.get_name_signature / i_prof_id=' || l_ack_tab(i).id_prof_ack;
            l_dt_detail := l_ack_tab(i).dt_ack;
            g_error     := 'Call get_signature / ID_PROF=' || l_ack_tab(i).id_prof_ack;
            g_retval    := get_signature(i_lang         => i_lang,
                                         i_prof         => i_prof,
                                         i_code_message => g_sm_comm_order_m005, -- 'Documented:'
                                         i_id_prof_op   => l_ack_tab(i).id_prof_ack,
                                         i_dt_op        => l_dt_detail,
                                         o_text         => l_signature,
                                         o_error        => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            io_id_section            := io_id_section + 1;
            g_error                  := 'Call format_field / io_id_section=' || io_id_section;
            l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                     i_prof              => i_prof,
                                                     i_id_comm_order_req => i_id_comm_order_req,
                                                     i_field             => g_field_acknowledge,
                                                     i_id_section        => io_id_section,
                                                     i_header_1          => l_header_1,
                                                     i_signature         => l_signature,
                                                     i_field_value       => NULL,
                                                     i_rank              => i_rank,
                                                     i_dt_detail         => l_dt_detail);
            io_data.extend;
            io_data(io_data.last) := l_rec_comm_order_req_det;
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
                                              i_function => 'FORMAT_DATA_ACK',
                                              o_error    => o_error);
            RETURN FALSE;
    END format_data_ack;

    FUNCTION format_data_status
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_rec_comm_order_req IN t_rec_comm_order_req,
        i_rank               IN PLS_INTEGER,
        io_id_section        IN OUT PLS_INTEGER,
        io_data              IN OUT NOCOPY t_coll_comm_order_req_det,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rec_comm_order_req_det t_rec_comm_order_req_det;
        l_header_1               VARCHAR2(1000 CHAR);
        l_field_value            CLOB;
        l_signature              VARCHAR2(1000 CHAR);
        l_dt_detail              TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_field                  VARCHAR2(30 CHAR);
        l_count                  PLS_INTEGER;
    
    BEGIN
    
        l_count := io_data.count; -- number of records with comm_order_req details
    
        IF i_rec_comm_order_req.id_status NOT IN (g_id_sts_draft, g_id_sts_ongoing, g_id_sts_predf)
        THEN
        
            io_id_section := io_id_section + 1;
        
            IF io_data IS NULL
            THEN
                io_data := t_coll_comm_order_req_det();
            END IF;
        
            -- getting common values
            g_error    := 'getting common values ';
            l_header_1 := get_comm_order_req_sts_desc(i_lang              => i_lang,
                                                      i_prof              => i_prof,
                                                      i_id_status         => i_rec_comm_order_req.id_status,
                                                      i_dt_begin          => i_rec_comm_order_req.dt_begin,
                                                      i_id_comm_order_req => i_rec_comm_order_req.id_comm_order_req);
        
            l_dt_detail := i_rec_comm_order_req.dt_status;
        
            g_error  := 'Call get_signature / ID_PROF=' || i_rec_comm_order_req.id_professional;
            g_retval := get_signature(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_code_message => g_sm_comm_order_m005, -- 'Documented:'
                                      i_id_prof_op   => i_rec_comm_order_req.id_professional,
                                      i_dt_op        => l_dt_detail,
                                      o_text         => l_signature,
                                      o_error        => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            IF i_rec_comm_order_req.id_cancel_reason IS NOT NULL
            THEN
            
                g_error       := 'Cancel reason ';
                l_field_value := pk_translation.get_translation(i_lang      => i_lang,
                                                                i_code_mess => g_code_cancel_reason ||
                                                                               i_rec_comm_order_req.id_cancel_reason);
                -- check if this reason is a cancel reason or a discontinue reason
                g_error := 'ID_STATUS=' || i_rec_comm_order_req.id_status;
                IF i_rec_comm_order_req.id_status = g_id_sts_canceled
                THEN
                    l_field := g_field_cancel_reason;
                ELSIF i_rec_comm_order_req.id_status = g_id_sts_completed
                THEN
                    l_field := g_field_discontinue_reason;
                END IF;
            
                g_error                  := 'Call format_field / l_field=' || l_field;
                l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                         i_prof              => i_prof,
                                                         i_id_comm_order_req => i_rec_comm_order_req.id_comm_order_req,
                                                         i_field             => l_field,
                                                         i_id_section        => io_id_section,
                                                         i_header_1          => l_header_1,
                                                         i_signature         => l_signature,
                                                         i_field_value       => l_field_value,
                                                         i_rank              => i_rank,
                                                         i_dt_detail         => l_dt_detail);
            
                g_error := 'io_data.extend ';
                io_data.extend;
                io_data(io_data.last) := l_rec_comm_order_req_det;
            END IF;
        
            IF i_rec_comm_order_req.notes_cancel IS NOT NULL
               AND length(i_rec_comm_order_req.notes_cancel) > 0
            THEN
                g_error       := 'Cancel notes ';
                l_field_value := i_rec_comm_order_req.notes_cancel;
            
                -- check if this reason is a cancel reason or a discontinue reason
                g_error := 'ID_STATUS=' || i_rec_comm_order_req.id_status;
                IF i_rec_comm_order_req.id_status = g_id_sts_canceled
                THEN
                    l_field := g_field_cancel_notes;
                ELSIF i_rec_comm_order_req.id_status = g_id_sts_completed
                THEN
                    l_field := g_field_discontinue_notes;
                END IF;
            
                g_error                  := 'Call format_field / l_field=' || l_field;
                l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                         i_prof              => i_prof,
                                                         i_id_comm_order_req => i_rec_comm_order_req.id_comm_order_req,
                                                         i_field             => l_field,
                                                         i_id_section        => io_id_section,
                                                         i_header_1          => l_header_1,
                                                         i_signature         => l_signature,
                                                         i_field_value       => l_field_value,
                                                         i_rank              => i_rank,
                                                         i_dt_detail         => l_dt_detail);
            
                g_error := 'io_data.extend ';
                io_data.extend;
                io_data(io_data.last) := l_rec_comm_order_req_det;
            END IF;
        
            -- Co-sign data
            g_error  := 'Call format_data_co_sign ';
            g_retval := format_data_co_sign(i_lang               => i_lang,
                                            i_prof               => i_prof,
                                            i_rec_comm_order_req => i_rec_comm_order_req,
                                            i_header_1           => l_header_1,
                                            i_rank               => i_rank,
                                            i_signature          => l_signature,
                                            io_id_section        => io_id_section,
                                            io_data              => io_data,
                                            o_error              => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            g_error := 'l_count=' || l_count || ' io_data.count=' || io_data.count;
            IF l_count = io_data.count
            THEN
                -- this function (format_data_status) did not output any record (no co-sign, no notes, no reason). If so, output status record
                -- this validation must be done because old discontinuation records did not have co-sign/reason/notes, and status record must be outputed
                -- even with the "new" discontinuation records, reason could be not mandatory (as notes and co-sign)
            
                l_rec_comm_order_req_det                   := t_rec_comm_order_req_det();
                l_rec_comm_order_req_det.id_comm_order_req := i_rec_comm_order_req.id_comm_order_req;
                l_rec_comm_order_req_det.id_section        := io_id_section;
                l_rec_comm_order_req_det.header_1          := l_header_1;
                l_rec_comm_order_req_det.signature         := l_signature;
                l_rec_comm_order_req_det.rank              := i_rank;
                l_rec_comm_order_req_det.dt_detail         := l_dt_detail;
                l_rec_comm_order_req_det.field_value       := htf.escape_sc(NULL); -- escape html characters
                l_rec_comm_order_req_det.field_code        := g_field_status;
                l_rec_comm_order_req_det.field_rank        := g_field_sr_status;
            
                g_error := 'io_data.extend ';
                io_data.extend;
                io_data(io_data.last) := l_rec_comm_order_req_det;
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
                                              i_function => 'FORMAT_DATA_STATUS',
                                              o_error    => o_error);
            RETURN FALSE;
    END format_data_status;

    FUNCTION format_data_hist_co_signed
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_comm_order_req IN comm_order_req.id_comm_order_req%TYPE,
        i_rec_new           IN t_rec_co_sign,
        i_rec_old           IN t_rec_co_sign,
        i_header_1          IN VARCHAR2 DEFAULT NULL,
        i_rank              IN PLS_INTEGER,
        i_signature         IN VARCHAR2,
        i_flg_action        IN VARCHAR2,
        io_id_section       IN OUT PLS_INTEGER,
        io_data             IN OUT NOCOPY t_coll_comm_order_req_det,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rec_comm_order_req_det t_rec_comm_order_req_det;
        l_field_value            CLOB;
        l_dt_detail              TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_field                  VARCHAR2(30 CHAR);
    
    BEGIN
    
        IF io_data IS NULL
        THEN
            io_data := t_coll_comm_order_req_det();
        END IF;
    
        l_dt_detail := i_rec_new.dt_co_signed; -- printing old value in signature of the new record                
    
        -- Notes new value (there is no old value, only can co-sign once)
        IF i_rec_new.flg_has_notes = pk_alert_constant.g_yes
        THEN
        
            -- co-sign notes
            g_error := 'CASE i_flg_action / i_flg_action=' || i_flg_action;
            CASE
                WHEN i_flg_action IN (g_action_order, g_action_draft) THEN
                    l_field := g_field_o_notes;
                WHEN i_flg_action = g_action_edition THEN
                    l_field := g_field_e_notes;
                WHEN i_flg_action = g_action_canceled THEN
                    l_field := g_field_c_notes;
                WHEN i_flg_action = g_action_dicontinued THEN
                    l_field := g_field_d_notes;
                ELSE
                    l_field := NULL;
            END CASE;
        
            g_error       := 'Co-signed notes ';
            l_field_value := i_rec_new.co_sign_notes;
        
            g_error                  := 'Call format_field co-sign status ';
            l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                     i_prof              => i_prof,
                                                     i_id_comm_order_req => i_id_comm_order_req,
                                                     i_field             => l_field,
                                                     i_id_section        => io_id_section,
                                                     i_header_1          => i_header_1,
                                                     i_signature         => i_signature,
                                                     i_field_value       => l_field_value,
                                                     i_flg_new           => pk_alert_constant.g_yes, -- new value
                                                     i_rank              => i_rank,
                                                     i_dt_detail         => l_dt_detail);
        
            g_error := 'io_data.extend ';
            io_data.extend;
            io_data(io_data.last) := l_rec_comm_order_req_det;
        ELSE
            -- no notes specified, print only the title
            -- co-sign title
            g_error := 'CASE i_flg_action / i_flg_action=' || i_flg_action;
            CASE
                WHEN i_flg_action IN (g_action_order, g_action_draft) THEN
                    l_field := g_field_o_title;
                WHEN i_flg_action = g_action_edition THEN
                    l_field := g_field_e_title;
                WHEN i_flg_action = g_action_canceled THEN
                    l_field := g_field_c_title;
                WHEN i_flg_action = g_action_dicontinued THEN
                    l_field := g_field_d_title;
                ELSE
                    l_field := NULL;
            END CASE;
        
            g_error                  := 'Call format_field co-sign title ';
            l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                     i_prof              => i_prof,
                                                     i_id_comm_order_req => i_id_comm_order_req,
                                                     i_field             => l_field,
                                                     i_id_section        => io_id_section,
                                                     i_header_1          => i_header_1,
                                                     i_signature         => i_signature,
                                                     i_field_value       => NULL,
                                                     i_flg_new           => pk_alert_constant.g_no, -- old value
                                                     i_rank              => i_rank,
                                                     i_dt_detail         => l_dt_detail);
        
            g_error := 'io_data.extend ';
            io_data.extend;
            io_data(io_data.last) := l_rec_comm_order_req_det;
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
                                              i_function => 'FORMAT_DATA_HIST_CO_SIGNED',
                                              o_error    => o_error);
            RETURN FALSE;
    END format_data_hist_co_signed;

    FUNCTION format_data_hist_co_sign
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_rec_new     IN t_rec_comm_order_req,
        i_rec_old     IN t_rec_comm_order_req,
        i_header_1    IN VARCHAR2 DEFAULT NULL,
        i_rank        IN PLS_INTEGER,
        i_signature   IN VARCHAR2,
        io_id_section IN OUT PLS_INTEGER,
        io_data       IN OUT NOCOPY t_coll_comm_order_req_det,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rec_comm_order_req_det t_rec_comm_order_req_det;
        l_field_value            CLOB;
        l_dt_detail              TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_old_set                PLS_INTEGER;
        l_new_set                PLS_INTEGER;
        l_flg_action             comm_order_req_hist.flg_action%TYPE;
        l_field                  VARCHAR2(30 CHAR);
        l_rec_co_sign_new        t_rec_co_sign;
    BEGIN
    
        IF io_data IS NULL
        THEN
            io_data := t_coll_comm_order_req_det();
        END IF;
        l_flg_action := i_rec_new.flg_action;
    
        g_error := 'Call show_in_history_co_sign ';
        IF show_in_history_co_sign(i_lang    => i_lang,
                                   i_prof    => i_prof,
                                   i_rec_old => i_rec_old,
                                   i_rec_new => i_rec_new,
                                   o_old_set => l_old_set,
                                   o_new_set => l_new_set) = pk_alert_constant.g_yes
        THEN
            -- getting common values
            g_error     := 'getting common values ';
            l_dt_detail := i_rec_new.dt_status;
        
            IF i_rec_new.co_sign_data.exists(1)
            THEN
                l_rec_co_sign_new := i_rec_new.co_sign_data(1); -- there is only one co-sign related to this change
            ELSE
                l_rec_co_sign_new := t_rec_co_sign();
            END IF;
        
            -- Order type            
            g_error := 'CASE l_flg_action / l_flg_action=' || l_flg_action;
            CASE
                WHEN l_flg_action IN (g_action_order, g_action_draft) THEN
                    l_field := g_field_o_id_order_type;
                WHEN l_flg_action = g_action_edition THEN
                    l_field := g_field_e_id_order_type;
                WHEN l_flg_action = g_action_canceled THEN
                    l_field := g_field_c_id_order_type;
                WHEN l_flg_action = g_action_dicontinued THEN
                    l_field := g_field_d_id_order_type;
                ELSE
                    l_field := NULL;
            END CASE;
        
            g_error       := 'Order type / ' || l_field;
            l_field_value := pk_translation.get_translation(i_lang,
                                                            g_code_order_type || l_rec_co_sign_new.id_order_type);
        
            l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                     i_prof              => i_prof,
                                                     i_id_comm_order_req => i_rec_new.id_comm_order_req,
                                                     i_field             => l_field,
                                                     i_id_section        => io_id_section,
                                                     i_header_1          => i_header_1,
                                                     i_signature         => i_signature,
                                                     i_field_value       => l_field_value,
                                                     i_flg_new           => pk_alert_constant.g_yes,
                                                     i_rank              => i_rank,
                                                     i_dt_detail         => l_dt_detail);
        
            io_data.extend;
            io_data(io_data.last) := l_rec_comm_order_req_det;
        
            -- Ordered by
            g_error := 'CASE l_flg_action / l_flg_action=' || l_flg_action;
            CASE
                WHEN l_flg_action IN (g_action_order, g_action_draft) THEN
                    l_field := g_field_o_prof_order;
                WHEN l_flg_action = g_action_edition THEN
                    l_field := g_field_e_prof_order;
                WHEN l_flg_action = g_action_canceled THEN
                    l_field := g_field_c_prof_order;
                WHEN l_flg_action = g_action_dicontinued THEN
                    l_field := g_field_d_prof_order;
                ELSE
                    l_field := NULL;
            END CASE;
        
            g_error       := 'Ordered by / ' || l_field;
            l_field_value := l_rec_co_sign_new.desc_prof_ordered_by;
        
            l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                     i_prof              => i_prof,
                                                     i_id_comm_order_req => i_rec_new.id_comm_order_req,
                                                     i_field             => l_field,
                                                     i_id_section        => io_id_section,
                                                     i_header_1          => i_header_1,
                                                     i_signature         => i_signature,
                                                     i_field_value       => l_field_value,
                                                     i_flg_new           => pk_alert_constant.g_yes,
                                                     i_rank              => i_rank,
                                                     i_dt_detail         => l_dt_detail);
        
            io_data.extend;
            io_data(io_data.last) := l_rec_comm_order_req_det;
        
            -- Ordered at
            g_error := 'CASE l_flg_action / l_flg_action=' || l_flg_action;
            CASE
                WHEN l_flg_action IN (g_action_order, g_action_draft) THEN
                    l_field := g_field_o_dt_order;
                WHEN l_flg_action = g_action_edition THEN
                    l_field := g_field_e_dt_order;
                WHEN l_flg_action = g_action_canceled THEN
                    l_field := g_field_c_dt_order;
                WHEN l_flg_action = g_action_dicontinued THEN
                    l_field := g_field_d_dt_order;
                ELSE
                    l_field := NULL;
            END CASE;
        
            g_error       := 'Ordered at / ' || l_field;
            l_field_value := pk_date_utils.dt_chr_date_hour_tsz(i_lang, l_rec_co_sign_new.dt_ordered_by, i_prof);
        
            l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                     i_prof              => i_prof,
                                                     i_id_comm_order_req => i_rec_new.id_comm_order_req,
                                                     i_field             => l_field,
                                                     i_id_section        => io_id_section,
                                                     i_header_1          => i_header_1,
                                                     i_signature         => i_signature,
                                                     i_field_value       => l_field_value,
                                                     i_flg_new           => pk_alert_constant.g_yes,
                                                     i_rank              => i_rank,
                                                     i_dt_detail         => l_dt_detail);
            io_data.extend;
            io_data(io_data.last) := l_rec_comm_order_req_det;
        
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
                                              i_function => 'FORMAT_DATA_HIST_CO_SIGN',
                                              o_error    => o_error);
            RETURN FALSE;
    END format_data_hist_co_sign;

    FUNCTION format_data_hist
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_rec_new     IN t_rec_comm_order_req,
        i_rec_old     IN t_rec_comm_order_req,
        i_rank        IN PLS_INTEGER,
        io_id_section IN OUT PLS_INTEGER,
        io_data       IN OUT NOCOPY t_coll_comm_order_req_det,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rec_comm_order_req_det t_rec_comm_order_req_det;
        l_header_1               VARCHAR2(1000 CHAR);
        l_signature              VARCHAR2(1000 CHAR);
        l_field_value            CLOB;
        l_field_value_new        CLOB;
        l_information_deleted    sys_message.desc_message%TYPE;
        l_dt_detail              TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_old_set                PLS_INTEGER;
        l_new_set                PLS_INTEGER;
        l_tbl_desc_clin_quest    table_varchar := table_varchar();
        l_tbl_curr_desc_resp     table_varchar := table_varchar();
        l_tbl_prev_desc_resp     table_varchar := table_varchar();
        l_tbl_rank_cq            table_number := table_number();
    
    BEGIN
    
        l_information_deleted := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_m007);
        IF io_data IS NULL
        THEN
            io_data := t_coll_comm_order_req_det();
        END IF;
    
        -- getting common values
        g_error       := 'getting common values ';
        l_dt_detail   := i_rec_new.dt_status;
        io_id_section := io_id_section + 1;
    
        g_error  := 'Call get_signature / ID_PROF=' || i_rec_new.id_professional;
        g_retval := get_signature(i_lang         => i_lang,
                                  i_prof         => i_prof,
                                  i_code_message => g_sm_comm_order_m005, -- 'Documented:'
                                  i_id_prof_op   => i_rec_new.id_professional,
                                  i_dt_op        => l_dt_detail,
                                  o_text         => l_signature,
                                  o_error        => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- Status change
        g_error := 'Call show_in_history / g_field_status ';
        IF show_in_history(i_lang    => i_lang,
                           i_prof    => i_prof,
                           i_rec_old => i_rec_old,
                           i_rec_new => i_rec_new,
                           i_field   => g_field_status, -- check status change
                           o_old_set => l_old_set,
                           o_new_set => l_new_set) = pk_alert_constant.g_yes
           AND (i_rec_old.id_status <> g_id_sts_ongoing OR i_rec_new.id_status <> g_id_sts_completed)
        THEN
            -- if this is a status change, set header_1 to status name
            l_header_1 := pk_sysdomain.get_domain(i_code_dom => g_code_comm_order_action,
                                                  i_val      => i_rec_new.flg_action,
                                                  i_lang     => i_lang);
        
            -- output comm_order_req status
            IF l_old_set = 1
            THEN
                -- old value set
                g_error       := 'Call get_comm_order_req_sts_desc / status old ';
                l_field_value := get_comm_order_req_sts_desc(i_lang              => i_lang,
                                                             i_prof              => i_prof,
                                                             i_id_status         => i_rec_old.id_status,
                                                             i_dt_begin          => i_rec_old.dt_begin,
                                                             i_id_comm_order_req => i_rec_old.id_comm_order_req);
            
                g_error                  := 'Call format_field / status old ';
                l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                         i_prof              => i_prof,
                                                         i_id_comm_order_req => i_rec_new.id_comm_order_req,
                                                         i_field             => g_field_status,
                                                         i_id_section        => io_id_section,
                                                         i_header_1          => l_header_1,
                                                         i_signature         => l_signature,
                                                         i_field_value       => l_field_value,
                                                         i_flg_new           => pk_alert_constant.g_no,
                                                         i_rank              => i_rank,
                                                         i_dt_detail         => l_dt_detail);
                io_data.extend;
                io_data(io_data.last) := l_rec_comm_order_req_det;
            END IF;
        
            g_error := 'Status new ';
            IF l_new_set = 1
            THEN
                g_error       := 'Call get_comm_order_req_sts_desc / status new ';
                l_field_value := get_comm_order_req_sts_desc(i_lang              => i_lang,
                                                             i_prof              => i_prof,
                                                             i_id_status         => i_rec_new.id_status,
                                                             i_dt_begin          => i_rec_new.dt_begin,
                                                             i_id_comm_order_req => i_rec_new.id_comm_order_req);
            END IF;
        
            g_error                  := 'Call format_field / status new ';
            l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                     i_prof              => i_prof,
                                                     i_id_comm_order_req => i_rec_new.id_comm_order_req,
                                                     i_field             => g_field_status,
                                                     i_id_section        => io_id_section,
                                                     i_header_1          => l_header_1,
                                                     i_signature         => l_signature,
                                                     i_field_value       => l_field_value,
                                                     i_flg_new           => pk_alert_constant.g_yes,
                                                     i_rank              => i_rank,
                                                     i_dt_detail         => l_dt_detail);
            io_data.extend;
            io_data(io_data.last) := l_rec_comm_order_req_det;
        
        ELSE
            l_header_1 := pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t028);
        END IF;
    
        -- Notes    
        g_error := 'Notes ';
        IF show_in_history(i_lang    => i_lang,
                           i_prof    => i_prof,
                           i_rec_old => i_rec_old,
                           i_rec_new => i_rec_new,
                           i_field   => g_field_notes,
                           o_old_set => l_old_set,
                           o_new_set => l_new_set) = pk_alert_constant.g_yes
        THEN
            IF l_old_set = 1
            THEN
                -- old value set
                g_error                  := 'Notes old ';
                l_field_value            := i_rec_old.notes;
                l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                         i_prof              => i_prof,
                                                         i_id_comm_order_req => i_rec_new.id_comm_order_req,
                                                         i_field             => g_field_notes,
                                                         i_id_section        => io_id_section,
                                                         i_header_1          => l_header_1,
                                                         i_signature         => l_signature,
                                                         i_field_value       => l_field_value,
                                                         i_flg_new           => pk_alert_constant.g_no,
                                                         i_rank              => i_rank,
                                                         i_dt_detail         => l_dt_detail);
                io_data.extend;
                io_data(io_data.last) := l_rec_comm_order_req_det;
            END IF;
        
            g_error := 'Notes new ';
            IF l_new_set = 0
            THEN
                -- new value not set
                l_field_value := l_information_deleted;
            ELSE
                l_field_value := i_rec_new.notes;
            END IF;
        
            l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                     i_prof              => i_prof,
                                                     i_id_comm_order_req => i_rec_new.id_comm_order_req,
                                                     i_field             => g_field_notes,
                                                     i_id_section        => io_id_section,
                                                     i_header_1          => l_header_1,
                                                     i_signature         => l_signature,
                                                     i_field_value       => l_field_value,
                                                     i_flg_new           => pk_alert_constant.g_yes,
                                                     i_rank              => i_rank,
                                                     i_dt_detail         => l_dt_detail);
            io_data.extend;
            io_data(io_data.last) := l_rec_comm_order_req_det;
        END IF;
    
        -- Clinical Indication
        g_error := 'Clinical Indication ';
        IF show_in_history(i_lang    => i_lang,
                           i_prof    => i_prof,
                           i_rec_old => i_rec_old,
                           i_rec_new => i_rec_new,
                           i_field   => g_field_clin_indication,
                           o_old_set => l_old_set,
                           o_new_set => l_new_set) = pk_alert_constant.g_yes
        THEN
            IF l_old_set = 1
            THEN
                -- old value set            
                g_error  := 'Clinical Indication old ';
                g_retval := get_diagnoses_text(i_lang                => i_lang,
                                               i_prof                => i_prof,
                                               i_clinical_indication => i_rec_old.clinical_indication,
                                               o_text                => l_field_value,
                                               o_error               => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                IF l_field_value IS NOT NULL
                THEN
                
                    l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                             i_prof              => i_prof,
                                                             i_id_comm_order_req => i_rec_new.id_comm_order_req,
                                                             i_field             => g_field_clin_indication,
                                                             i_id_section        => io_id_section,
                                                             i_header_1          => l_header_1,
                                                             i_signature         => l_signature,
                                                             i_field_value       => l_field_value,
                                                             i_flg_new           => pk_alert_constant.g_no,
                                                             i_rank              => i_rank,
                                                             i_dt_detail         => l_dt_detail);
                    io_data.extend;
                    io_data(io_data.last) := l_rec_comm_order_req_det;
                
                END IF;
            END IF;
        
            g_error := 'Clinical Indication new ';
            IF l_new_set = 0
            THEN
                -- new value not set
                l_field_value := l_information_deleted;
            ELSE
            
                g_error  := 'Clinical Indication old ';
                g_retval := get_diagnoses_text(i_lang                => i_lang,
                                               i_prof                => i_prof,
                                               i_clinical_indication => i_rec_new.clinical_indication,
                                               o_text                => l_field_value,
                                               o_error               => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            END IF;
        
            IF l_field_value IS NOT NULL
            THEN
            
                l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                         i_prof              => i_prof,
                                                         i_id_comm_order_req => i_rec_new.id_comm_order_req,
                                                         i_field             => g_field_clin_indication,
                                                         i_id_section        => io_id_section,
                                                         i_header_1          => l_header_1,
                                                         i_signature         => l_signature,
                                                         i_field_value       => l_field_value,
                                                         i_flg_new           => pk_alert_constant.g_yes,
                                                         i_rank              => i_rank,
                                                         i_dt_detail         => l_dt_detail);
                io_data.extend;
                io_data(io_data.last) := l_rec_comm_order_req_det;
            
            END IF;
        END IF;
    
        -- Clinical Purpose
        g_error := 'Clinical Purpose ';
        IF show_in_history(i_lang    => i_lang,
                           i_prof    => i_prof,
                           i_rec_old => i_rec_old,
                           i_rec_new => i_rec_new,
                           i_field   => g_field_clin_purpose,
                           o_old_set => l_old_set,
                           o_new_set => l_new_set) = pk_alert_constant.g_yes
        THEN
            IF l_old_set = 1
            THEN
                -- old value set
                g_error       := 'Clinical Purpose old ';
                l_field_value := get_clinical_purpose_desc(i_lang              => i_lang,
                                                           i_prof              => i_prof,
                                                           i_flg_clin_purpose  => i_rec_old.flg_clinical_purpose,
                                                           i_clin_purpose_desc => i_rec_old.clinical_purpose_desc);
            
                l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                         i_prof              => i_prof,
                                                         i_id_comm_order_req => i_rec_new.id_comm_order_req,
                                                         i_field             => g_field_clin_purpose,
                                                         i_id_section        => io_id_section,
                                                         i_header_1          => l_header_1,
                                                         i_signature         => l_signature,
                                                         i_field_value       => l_field_value,
                                                         i_flg_new           => pk_alert_constant.g_no,
                                                         i_rank              => i_rank,
                                                         i_dt_detail         => l_dt_detail);
            
                io_data.extend;
                io_data(io_data.last) := l_rec_comm_order_req_det;
            END IF;
        
            g_error := 'Clinical Purpose new ';
            IF l_new_set = 0
            THEN
                -- new value not set
                l_field_value := l_information_deleted;
            ELSE
                l_field_value := get_clinical_purpose_desc(i_lang              => i_lang,
                                                           i_prof              => i_prof,
                                                           i_flg_clin_purpose  => i_rec_new.flg_clinical_purpose,
                                                           i_clin_purpose_desc => i_rec_new.clinical_purpose_desc);
            END IF;
            l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                     i_prof              => i_prof,
                                                     i_id_comm_order_req => i_rec_new.id_comm_order_req,
                                                     i_field             => g_field_clin_purpose,
                                                     i_id_section        => io_id_section,
                                                     i_header_1          => l_header_1,
                                                     i_signature         => l_signature,
                                                     i_field_value       => l_field_value,
                                                     i_flg_new           => pk_alert_constant.g_yes,
                                                     i_rank              => i_rank,
                                                     i_dt_detail         => l_dt_detail);
            io_data.extend;
            io_data(io_data.last) := l_rec_comm_order_req_det;
        END IF;
    
        -- Instructions
        -- Priority
        g_error := 'Priority ';
        IF show_in_history(i_lang    => i_lang,
                           i_prof    => i_prof,
                           i_rec_old => i_rec_old,
                           i_rec_new => i_rec_new,
                           i_field   => g_field_priority,
                           o_old_set => l_old_set,
                           o_new_set => l_new_set) = pk_alert_constant.g_yes
        THEN
            IF l_old_set = 1
            THEN
                -- old value set
                g_error                  := 'Priority old ';
                l_field_value            := pk_sysdomain.get_domain(i_code_dom => g_code_priority,
                                                                    i_val      => i_rec_old.flg_priority,
                                                                    i_lang     => i_lang);
                l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                         i_prof              => i_prof,
                                                         i_id_comm_order_req => i_rec_new.id_comm_order_req,
                                                         i_field             => g_field_priority,
                                                         i_id_section        => io_id_section,
                                                         i_header_1          => l_header_1,
                                                         i_signature         => l_signature,
                                                         i_field_value       => l_field_value,
                                                         i_flg_new           => pk_alert_constant.g_no,
                                                         i_rank              => i_rank,
                                                         i_dt_detail         => l_dt_detail);
                io_data.extend;
                io_data(io_data.last) := l_rec_comm_order_req_det;
            END IF;
        
            g_error := 'Priority new ';
            IF l_new_set = 0
            THEN
                -- new value not set
                l_field_value := l_information_deleted;
            ELSE
                l_field_value := pk_sysdomain.get_domain(i_code_dom => g_code_priority,
                                                         i_val      => i_rec_new.flg_priority,
                                                         i_lang     => i_lang);
            END IF;
            l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                     i_prof              => i_prof,
                                                     i_id_comm_order_req => i_rec_new.id_comm_order_req,
                                                     i_field             => g_field_priority,
                                                     i_id_section        => io_id_section,
                                                     i_header_1          => l_header_1,
                                                     i_signature         => l_signature,
                                                     i_field_value       => l_field_value,
                                                     i_flg_new           => pk_alert_constant.g_yes,
                                                     i_rank              => i_rank,
                                                     i_dt_detail         => l_dt_detail);
            io_data.extend;
            io_data(io_data.last) := l_rec_comm_order_req_det;
        END IF;
    
        -- PRN
        g_error := 'PRN ';
        IF show_in_history(i_lang    => i_lang,
                           i_prof    => i_prof,
                           i_rec_old => i_rec_old,
                           i_rec_new => i_rec_new,
                           i_field   => g_field_prn,
                           o_old_set => l_old_set,
                           o_new_set => l_new_set) = pk_alert_constant.g_yes
        THEN
            IF l_old_set = 1
            THEN
                -- old value set
                g_error                  := 'PRN old ';
                l_field_value            := pk_sysdomain.get_domain(i_code_dom => g_code_prn,
                                                                    i_val      => i_rec_old.flg_prn,
                                                                    i_lang     => i_lang);
                l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                         i_prof              => i_prof,
                                                         i_id_comm_order_req => i_rec_new.id_comm_order_req,
                                                         i_field             => g_field_prn,
                                                         i_id_section        => io_id_section,
                                                         i_header_1          => l_header_1,
                                                         i_signature         => l_signature,
                                                         i_field_value       => l_field_value,
                                                         i_flg_new           => pk_alert_constant.g_no,
                                                         i_rank              => i_rank,
                                                         i_dt_detail         => l_dt_detail);
                io_data.extend;
                io_data(io_data.last) := l_rec_comm_order_req_det;
            END IF;
        
            g_error := 'PRN new ';
            IF l_new_set = 0
            THEN
                -- new value not set
                l_field_value := l_information_deleted;
            ELSE
                l_field_value := pk_sysdomain.get_domain(i_code_dom => g_code_prn,
                                                         i_val      => i_rec_new.flg_prn,
                                                         i_lang     => i_lang);
            END IF;
            l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                     i_prof              => i_prof,
                                                     i_id_comm_order_req => i_rec_new.id_comm_order_req,
                                                     i_field             => g_field_prn,
                                                     i_id_section        => io_id_section,
                                                     i_header_1          => l_header_1,
                                                     i_signature         => l_signature,
                                                     i_field_value       => l_field_value,
                                                     i_flg_new           => pk_alert_constant.g_yes,
                                                     i_rank              => i_rank,
                                                     i_dt_detail         => l_dt_detail);
            io_data.extend;
            io_data(io_data.last) := l_rec_comm_order_req_det;
        END IF;
    
        -- PRN Condition
        g_error := 'PRN Condition ';
        IF show_in_history(i_lang    => i_lang,
                           i_prof    => i_prof,
                           i_rec_old => i_rec_old,
                           i_rec_new => i_rec_new,
                           i_field   => g_field_prn_condition,
                           o_old_set => l_old_set,
                           o_new_set => l_new_set) = pk_alert_constant.g_yes
        THEN
            IF l_old_set = 1
            THEN
                -- old value set
                g_error                  := 'PRN Condition old ';
                l_field_value            := i_rec_old.prn_condition;
                l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                         i_prof              => i_prof,
                                                         i_id_comm_order_req => i_rec_new.id_comm_order_req,
                                                         i_field             => g_field_prn_condition,
                                                         i_id_section        => io_id_section,
                                                         i_header_1          => l_header_1,
                                                         i_signature         => l_signature,
                                                         i_field_value       => l_field_value,
                                                         i_flg_new           => pk_alert_constant.g_no,
                                                         i_rank              => i_rank,
                                                         i_dt_detail         => l_dt_detail);
                io_data.extend;
                io_data(io_data.last) := l_rec_comm_order_req_det;
            END IF;
        
            g_error := 'PRN Condition new ';
            IF l_new_set = 0
            THEN
                -- new value not set
                l_field_value := l_information_deleted;
            ELSE
                l_field_value := i_rec_new.prn_condition;
            END IF;
            l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                     i_prof              => i_prof,
                                                     i_id_comm_order_req => i_rec_new.id_comm_order_req,
                                                     i_field             => g_field_prn_condition,
                                                     i_id_section        => io_id_section,
                                                     i_header_1          => l_header_1,
                                                     i_signature         => l_signature,
                                                     i_field_value       => l_field_value,
                                                     i_flg_new           => pk_alert_constant.g_yes,
                                                     i_rank              => i_rank,
                                                     i_dt_detail         => l_dt_detail);
            io_data.extend;
            io_data(io_data.last) := l_rec_comm_order_req_det;
        END IF;
    
        -- Start date
        g_error := 'Start date ';
        IF show_in_history(i_lang    => i_lang,
                           i_prof    => i_prof,
                           i_rec_old => i_rec_old,
                           i_rec_new => i_rec_new,
                           i_field   => g_field_dt_begin,
                           o_old_set => l_old_set,
                           o_new_set => l_new_set) = pk_alert_constant.g_yes
        THEN
            l_field_value     := pk_date_utils.dt_chr_date_hour_tsz(i_lang, i_rec_old.dt_begin, i_prof);
            l_field_value_new := pk_date_utils.dt_chr_date_hour_tsz(i_lang, i_rec_new.dt_begin, i_prof);
        
            IF l_old_set = 1
            THEN
                -- old value set                
                g_error                  := 'Start date old ';
                l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                         i_prof              => i_prof,
                                                         i_id_comm_order_req => i_rec_new.id_comm_order_req,
                                                         i_field             => g_field_dt_begin,
                                                         i_id_section        => io_id_section,
                                                         i_header_1          => l_header_1,
                                                         i_signature         => l_signature,
                                                         i_field_value       => l_field_value,
                                                         i_flg_new           => pk_alert_constant.g_no,
                                                         i_rank              => i_rank,
                                                         i_dt_detail         => l_dt_detail);
                io_data.extend;
                io_data(io_data.last) := l_rec_comm_order_req_det;
            END IF;
        
            g_error := 'Start date new ';
            IF l_new_set = 0
            THEN
                -- new value not set
                l_field_value_new := l_information_deleted;
            END IF;
            l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                     i_prof              => i_prof,
                                                     i_id_comm_order_req => i_rec_new.id_comm_order_req,
                                                     i_field             => g_field_dt_begin,
                                                     i_id_section        => io_id_section,
                                                     i_header_1          => l_header_1,
                                                     i_signature         => l_signature,
                                                     i_field_value       => l_field_value_new,
                                                     i_flg_new           => pk_alert_constant.g_yes,
                                                     i_rank              => i_rank,
                                                     i_dt_detail         => l_dt_detail);
            io_data.extend;
            io_data(io_data.last) := l_rec_comm_order_req_det;
        END IF;
    
        -- Frequency
        g_error := 'Frequency ';
        IF show_in_history(i_lang    => i_lang,
                           i_prof    => i_prof,
                           i_rec_old => i_rec_old,
                           i_rec_new => i_rec_new,
                           i_field   => g_field_frequency,
                           o_old_set => l_old_set,
                           o_new_set => l_new_set) = pk_alert_constant.g_yes
        THEN
        
            IF i_rec_old.id_order_recurr IS NULL
            THEN
                l_field_value := pk_translation.get_translation(i_lang,
                                                                'ORDER_RECURR_OPTION.CODE_ORDER_RECURR_OPTION.0');
            ELSE
                l_field_value := pk_order_recurrence_api_db.get_order_recurr_plan_desc(i_lang,
                                                                                       i_prof,
                                                                                       i_rec_old.id_order_recurr);
            END IF;
        
            IF i_rec_new.id_order_recurr IS NULL
            THEN
                l_field_value_new := pk_translation.get_translation(i_lang,
                                                                    'ORDER_RECURR_OPTION.CODE_ORDER_RECURR_OPTION.0');
            ELSE
                l_field_value_new := pk_order_recurrence_api_db.get_order_recurr_plan_desc(i_lang,
                                                                                           i_prof,
                                                                                           i_rec_new.id_order_recurr);
            END IF;
        
            -- old value set                
            g_error                  := 'Frequency old ';
            l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                     i_prof              => i_prof,
                                                     i_id_comm_order_req => i_rec_new.id_comm_order_req,
                                                     i_field             => g_field_frequency,
                                                     i_id_section        => io_id_section,
                                                     i_header_1          => l_header_1,
                                                     i_signature         => l_signature,
                                                     i_field_value       => l_field_value,
                                                     i_flg_new           => pk_alert_constant.g_no,
                                                     i_rank              => i_rank,
                                                     i_dt_detail         => l_dt_detail);
            io_data.extend;
            io_data(io_data.last) := l_rec_comm_order_req_det;
        
            g_error                  := 'Frequency new ';
            l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                     i_prof              => i_prof,
                                                     i_id_comm_order_req => i_rec_new.id_comm_order_req,
                                                     i_field             => g_field_frequency,
                                                     i_id_section        => io_id_section,
                                                     i_header_1          => l_header_1,
                                                     i_signature         => l_signature,
                                                     i_field_value       => l_field_value_new,
                                                     i_flg_new           => pk_alert_constant.g_yes,
                                                     i_rank              => i_rank,
                                                     i_dt_detail         => l_dt_detail);
            io_data.extend;
            io_data(io_data.last) := l_rec_comm_order_req_det;
        END IF;
    
        --Task duration
        g_error := 'Task duration ';
        IF show_in_history(i_lang    => i_lang,
                           i_prof    => i_prof,
                           i_rec_old => i_rec_old,
                           i_rec_new => i_rec_new,
                           i_field   => g_field_task_duration,
                           o_old_set => l_old_set,
                           o_new_set => l_new_set) = pk_alert_constant.g_yes
        THEN
        
            l_field_value := i_rec_old.task_duration || ' ' ||
                             pk_unit_measure.get_unit_measure_description(i_lang         => i_lang,
                                                                          i_prof         => i_prof,
                                                                          i_unit_measure => 10374);
        
            l_field_value_new := i_rec_new.task_duration || ' ' ||
                                 pk_unit_measure.get_unit_measure_description(i_lang         => i_lang,
                                                                              i_prof         => i_prof,
                                                                              i_unit_measure => 10374);
        
            IF l_old_set = 1
            THEN
                -- old value set                
                g_error                  := 'Task duration old ';
                l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                         i_prof              => i_prof,
                                                         i_id_comm_order_req => i_rec_new.id_comm_order_req,
                                                         i_field             => g_field_task_duration,
                                                         i_id_section        => io_id_section,
                                                         i_header_1          => l_header_1,
                                                         i_signature         => l_signature,
                                                         i_field_value       => l_field_value,
                                                         i_flg_new           => pk_alert_constant.g_no,
                                                         i_rank              => i_rank,
                                                         i_dt_detail         => l_dt_detail);
                io_data.extend;
                io_data(io_data.last) := l_rec_comm_order_req_det;
            END IF;
        
            g_error := 'Frequency new ';
            IF l_new_set = 0
            THEN
                -- new value not set
                l_field_value_new := l_information_deleted;
            END IF;
            l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                     i_prof              => i_prof,
                                                     i_id_comm_order_req => i_rec_new.id_comm_order_req,
                                                     i_field             => g_field_task_duration,
                                                     i_id_section        => io_id_section,
                                                     i_header_1          => l_header_1,
                                                     i_signature         => l_signature,
                                                     i_field_value       => l_field_value_new,
                                                     i_flg_new           => pk_alert_constant.g_yes,
                                                     i_rank              => i_rank,
                                                     i_dt_detail         => l_dt_detail);
            io_data.extend;
            io_data(io_data.last) := l_rec_comm_order_req_det;
        END IF;
    
        --Clinical Questions
        g_error := 'Clinical questions ';
        IF show_in_history(i_lang    => i_lang,
                           i_prof    => i_prof,
                           i_rec_old => i_rec_old,
                           i_rec_new => i_rec_new,
                           i_field   => g_field_clinical_question,
                           o_old_set => l_old_set,
                           o_new_set => l_new_set) = pk_alert_constant.g_yes
        THEN
        
            IF NOT get_comm_order_clin_quest(i_lang           => i_lang,
                                             i_prof           => i_prof,
                                             i_comm_order_req => i_rec_new.id_comm_order_req,
                                             i_dt_status_new  => i_rec_new.dt_status,
                                             i_dt_status_old  => i_rec_old.dt_status,
                                             o_tbl_clin_quest => l_tbl_desc_clin_quest,
                                             o_tbl_curr_resp  => l_tbl_curr_desc_resp,
                                             o_tbl_prev_resp  => l_tbl_prev_desc_resp,
                                             o_tbl_cq_rank    => l_tbl_rank_cq,
                                             o_error          => o_error)
            THEN
                RAISE g_exception_np;
            END IF;
        
            IF l_tbl_desc_clin_quest.exists(1)
            THEN
                FOR i IN l_tbl_desc_clin_quest.first .. l_tbl_desc_clin_quest.last
                LOOP
                
                    IF l_tbl_curr_desc_resp(i) = l_tbl_prev_desc_resp(i)
                    THEN
                        l_field_value            := l_tbl_curr_desc_resp(i);
                        g_error                  := 'Clinical question ';
                        l_rec_comm_order_req_det := format_field(i_lang                   => i_lang,
                                                                 i_prof                   => i_prof,
                                                                 i_id_comm_order_req      => i_rec_new.id_comm_order_req,
                                                                 i_field                  => g_field_clinical_question,
                                                                 i_id_section             => io_id_section,
                                                                 i_header_1               => l_header_1,
                                                                 i_signature              => l_signature,
                                                                 i_field_value            => l_field_value,
                                                                 i_flg_new                => pk_alert_constant.g_no,
                                                                 i_rank                   => i_rank,
                                                                 i_dt_detail              => l_dt_detail,
                                                                 i_clinical_question_desc => l_tbl_desc_clin_quest(i));
                        io_data.extend;
                        io_data(io_data.last) := l_rec_comm_order_req_det;
                        io_data(io_data.last).field_rank := io_data(io_data.last).field_rank + l_tbl_rank_cq(i);
                    
                    ELSE
                    
                        l_field_value            := l_tbl_prev_desc_resp(i);
                        g_error                  := 'Clinical question ';
                        l_rec_comm_order_req_det := format_field(i_lang                   => i_lang,
                                                                 i_prof                   => i_prof,
                                                                 i_id_comm_order_req      => i_rec_new.id_comm_order_req,
                                                                 i_field                  => g_field_clinical_question,
                                                                 i_id_section             => io_id_section,
                                                                 i_header_1               => l_header_1,
                                                                 i_signature              => l_signature,
                                                                 i_field_value            => l_field_value,
                                                                 i_flg_new                => pk_alert_constant.g_no,
                                                                 i_rank                   => i_rank,
                                                                 i_dt_detail              => l_dt_detail,
                                                                 i_clinical_question_desc => l_tbl_desc_clin_quest(i));
                        io_data.extend;
                        io_data(io_data.last) := l_rec_comm_order_req_det;
                        io_data(io_data.last).field_rank := io_data(io_data.last).field_rank + l_tbl_rank_cq(i);
                    
                        l_field_value_new        := l_tbl_curr_desc_resp(i);
                        l_rec_comm_order_req_det := format_field(i_lang                   => i_lang,
                                                                 i_prof                   => i_prof,
                                                                 i_id_comm_order_req      => i_rec_new.id_comm_order_req,
                                                                 i_field                  => g_field_clinical_question,
                                                                 i_id_section             => io_id_section,
                                                                 i_header_1               => l_header_1,
                                                                 i_signature              => l_signature,
                                                                 i_field_value            => l_field_value_new,
                                                                 i_flg_new                => pk_alert_constant.g_yes,
                                                                 i_rank                   => i_rank,
                                                                 i_dt_detail              => l_dt_detail,
                                                                 i_clinical_question_desc => l_tbl_desc_clin_quest(i));
                        io_data.extend;
                        io_data(io_data.last) := l_rec_comm_order_req_det;
                        io_data(io_data.last).field_rank := io_data(io_data.last).field_rank + l_tbl_rank_cq(i);
                    
                    END IF;
                
                END LOOP;
            END IF;
        END IF;
    
        -- Cancel reason 
        g_error := 'Cancel reason ';
        IF show_in_history(i_lang    => i_lang,
                           i_prof    => i_prof,
                           i_rec_old => i_rec_old,
                           i_rec_new => i_rec_new,
                           i_field   => g_field_cancel_reason,
                           o_old_set => l_old_set,
                           o_new_set => l_new_set) = pk_alert_constant.g_yes
           AND i_rec_new.flg_action = g_action_canceled -- to be sure that this record is related to a cancellation action
        THEN
            IF l_old_set = 1
            THEN
                -- old value set
                g_error       := 'Cancel reason old ';
                l_field_value := pk_translation.get_translation(i_lang      => i_lang,
                                                                i_code_mess => g_code_cancel_reason ||
                                                                               i_rec_old.id_cancel_reason);
            
                l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                         i_prof              => i_prof,
                                                         i_id_comm_order_req => i_rec_new.id_comm_order_req,
                                                         i_field             => g_field_cancel_reason,
                                                         i_id_section        => io_id_section,
                                                         i_header_1          => l_header_1,
                                                         i_signature         => l_signature,
                                                         i_field_value       => l_field_value,
                                                         i_flg_new           => pk_alert_constant.g_no,
                                                         i_rank              => i_rank,
                                                         i_dt_detail         => l_dt_detail);
                io_data.extend;
                io_data(io_data.last) := l_rec_comm_order_req_det;
            END IF;
        
            g_error := 'Cancel reason new ';
            IF l_new_set = 1
            THEN
                l_field_value := pk_translation.get_translation(i_lang      => i_lang,
                                                                i_code_mess => g_code_cancel_reason ||
                                                                               i_rec_new.id_cancel_reason);
            
                l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                         i_prof              => i_prof,
                                                         i_id_comm_order_req => i_rec_new.id_comm_order_req,
                                                         i_field             => g_field_cancel_reason,
                                                         i_id_section        => io_id_section,
                                                         i_header_1          => l_header_1,
                                                         i_signature         => l_signature,
                                                         i_field_value       => l_field_value,
                                                         i_flg_new           => pk_alert_constant.g_yes,
                                                         i_rank              => i_rank,
                                                         i_dt_detail         => l_dt_detail);
                io_data.extend;
                io_data(io_data.last) := l_rec_comm_order_req_det;
            END IF;
        END IF;
    
        -- Cancel notes
        g_error := 'Cancel notes ';
        IF show_in_history(i_lang    => i_lang,
                           i_prof    => i_prof,
                           i_rec_old => i_rec_old,
                           i_rec_new => i_rec_new,
                           i_field   => g_field_cancel_notes,
                           o_old_set => l_old_set,
                           o_new_set => l_new_set) = pk_alert_constant.g_yes
           AND i_rec_new.flg_action = g_action_canceled -- to be sure that this record is related to a cancellation action
        THEN
            IF l_old_set = 1
            THEN
                -- old value set
                g_error       := 'Cancel notes old ';
                l_field_value := i_rec_old.notes_cancel;
            
                l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                         i_prof              => i_prof,
                                                         i_id_comm_order_req => i_rec_new.id_comm_order_req,
                                                         i_field             => g_field_cancel_notes,
                                                         i_id_section        => io_id_section,
                                                         i_header_1          => l_header_1,
                                                         i_signature         => l_signature,
                                                         i_field_value       => l_field_value,
                                                         i_flg_new           => pk_alert_constant.g_no,
                                                         i_rank              => i_rank,
                                                         i_dt_detail         => l_dt_detail);
                io_data.extend;
                io_data(io_data.last) := l_rec_comm_order_req_det;
            END IF;
        
            g_error := 'Cancel notes new ';
            IF l_new_set = 1
            THEN
                l_field_value := i_rec_new.notes_cancel;
            
                l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                         i_prof              => i_prof,
                                                         i_id_comm_order_req => i_rec_new.id_comm_order_req,
                                                         i_field             => g_field_cancel_notes,
                                                         i_id_section        => io_id_section,
                                                         i_header_1          => l_header_1,
                                                         i_signature         => l_signature,
                                                         i_field_value       => l_field_value,
                                                         i_flg_new           => pk_alert_constant.g_yes,
                                                         i_rank              => i_rank,
                                                         i_dt_detail         => l_dt_detail);
                io_data.extend;
                io_data(io_data.last) := l_rec_comm_order_req_det;
            END IF;
        END IF;
    
        -- Discontinuation reason 
        g_error := 'Discontinuation reason ';
        IF show_in_history(i_lang    => i_lang,
                           i_prof    => i_prof,
                           i_rec_old => i_rec_old,
                           i_rec_new => i_rec_new,
                           i_field   => g_field_discontinue_reason,
                           o_old_set => l_old_set,
                           o_new_set => l_new_set) = pk_alert_constant.g_yes
           AND i_rec_new.flg_action = g_action_dicontinued -- to be sure that this record is related to a discontinuation action
        THEN
            IF l_old_set = 1
            THEN
                -- old value set
                g_error       := 'Discontinuation reason old ';
                l_field_value := pk_translation.get_translation(i_lang      => i_lang,
                                                                i_code_mess => g_code_cancel_reason ||
                                                                               i_rec_old.id_cancel_reason);
            
                l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                         i_prof              => i_prof,
                                                         i_id_comm_order_req => i_rec_new.id_comm_order_req,
                                                         i_field             => g_field_discontinue_reason,
                                                         i_id_section        => io_id_section,
                                                         i_header_1          => l_header_1,
                                                         i_signature         => l_signature,
                                                         i_field_value       => l_field_value,
                                                         i_flg_new           => pk_alert_constant.g_no,
                                                         i_rank              => i_rank,
                                                         i_dt_detail         => l_dt_detail);
                io_data.extend;
                io_data(io_data.last) := l_rec_comm_order_req_det;
            END IF;
        
            g_error := 'Discontinuation reason new ';
            IF l_new_set = 1
            THEN
                l_field_value := pk_translation.get_translation(i_lang      => i_lang,
                                                                i_code_mess => g_code_cancel_reason ||
                                                                               i_rec_new.id_cancel_reason);
            
                l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                         i_prof              => i_prof,
                                                         i_id_comm_order_req => i_rec_new.id_comm_order_req,
                                                         i_field             => g_field_discontinue_reason,
                                                         i_id_section        => io_id_section,
                                                         i_header_1          => l_header_1,
                                                         i_signature         => l_signature,
                                                         i_field_value       => l_field_value,
                                                         i_flg_new           => pk_alert_constant.g_yes,
                                                         i_rank              => i_rank,
                                                         i_dt_detail         => l_dt_detail);
                io_data.extend;
                io_data(io_data.last) := l_rec_comm_order_req_det;
            END IF;
        END IF;
    
        -- Discontinuation notes
        g_error := 'Discontinuation notes ';
        IF show_in_history(i_lang    => i_lang,
                           i_prof    => i_prof,
                           i_rec_old => i_rec_old,
                           i_rec_new => i_rec_new,
                           i_field   => g_field_discontinue_notes,
                           o_old_set => l_old_set,
                           o_new_set => l_new_set) = pk_alert_constant.g_yes
           AND i_rec_new.flg_action = g_action_dicontinued -- to be sure that this record is related to a discontinuation action
        THEN
            IF l_old_set = 1
            THEN
                -- old value set
                g_error       := 'Discontinuation notes old ';
                l_field_value := i_rec_old.notes_cancel;
            
                l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                         i_prof              => i_prof,
                                                         i_id_comm_order_req => i_rec_new.id_comm_order_req,
                                                         i_field             => g_field_discontinue_notes,
                                                         i_id_section        => io_id_section,
                                                         i_header_1          => l_header_1,
                                                         i_signature         => l_signature,
                                                         i_field_value       => l_field_value,
                                                         i_flg_new           => pk_alert_constant.g_no,
                                                         i_rank              => i_rank,
                                                         i_dt_detail         => l_dt_detail);
                io_data.extend;
                io_data(io_data.last) := l_rec_comm_order_req_det;
            END IF;
        
            g_error := 'Discontinuation notes new ';
            IF l_new_set = 1
            THEN
                l_field_value            := i_rec_new.notes_cancel;
                l_rec_comm_order_req_det := format_field(i_lang              => i_lang,
                                                         i_prof              => i_prof,
                                                         i_id_comm_order_req => i_rec_new.id_comm_order_req,
                                                         i_field             => g_field_discontinue_notes,
                                                         i_id_section        => io_id_section,
                                                         i_header_1          => l_header_1,
                                                         i_signature         => l_signature,
                                                         i_field_value       => l_field_value,
                                                         i_flg_new           => pk_alert_constant.g_yes,
                                                         i_rank              => i_rank,
                                                         i_dt_detail         => l_dt_detail);
                io_data.extend;
                io_data(io_data.last) := l_rec_comm_order_req_det;
            END IF;
        END IF;
    
        -- Co-sign
        g_error  := 'Call format_data_hist_co_sign ';
        g_retval := format_data_hist_co_sign(i_lang        => i_lang,
                                             i_prof        => i_prof,
                                             i_rec_new     => i_rec_new,
                                             i_rec_old     => i_rec_old,
                                             i_header_1    => l_header_1,
                                             i_rank        => i_rank,
                                             i_signature   => l_signature,
                                             io_id_section => io_id_section,
                                             io_data       => io_data,
                                             o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'FORMAT_DATA_HIST',
                                              o_error    => o_error);
            RETURN FALSE;
    END format_data_hist;

    FUNCTION get_comm_order_req
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_rank               IN NUMBER,
        io_id_section        IN OUT NUMBER,
        i_rec_comm_order_req IN t_rec_comm_order_req,
        i_show_status        IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        io_data              IN OUT t_coll_comm_order_req_det,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_sig_code_message sys_message.code_message%TYPE;
    
        CURSOR c_hist IS
            SELECT t_rec_comm_order_req(corh.id_comm_order_req,
                                        corh.id_workflow,
                                        corh.id_status,
                                        corh.id_patient,
                                        corh.id_episode,
                                        corh.id_concept_type,
                                        corh.id_concept_version,
                                        corh.id_cncpt_vrs_inst_owner,
                                        corh.id_concept_term,
                                        corh.id_cncpt_trm_inst_owner,
                                        corh.flg_free_text,
                                        corh.desc_concept_term,
                                        corh.id_prof_req,
                                        corh.id_inst_req,
                                        corh.dt_req,
                                        corh.notes,
                                        corh.clinical_indication,
                                        corh.flg_clinical_purpose,
                                        corh.clinical_purpose_desc,
                                        corh.flg_priority,
                                        corh.flg_prn,
                                        corh.prn_condition,
                                        corh.dt_begin,
                                        corh.id_professional,
                                        corh.id_institution,
                                        corh.dt_status,
                                        corh.notes_cancel,
                                        corh.id_cancel_reason,
                                        corh.flg_need_ack,
                                        corh.flg_action,
                                        corh.id_previous_status,
                                        corh.task_duration,
                                        corh.id_order_recurr,
                                        corh.id_task_type,
                                        t_table_co_sign())
              FROM comm_order_req_hist corh
             WHERE corh.id_comm_order_req = i_rec_comm_order_req.id_comm_order_req
               AND corh.dt_status <= i_rec_comm_order_req.dt_status
             ORDER BY corh.dt_status DESC;
    
        l_hist_tab  t_coll_comm_order_req;
        l_hist_prev t_rec_comm_order_req;
        l_old_set   PLS_INTEGER;
        l_new_set   PLS_INTEGER;
    
    BEGIN
    
        IF io_data IS NULL
        THEN
            io_data := t_coll_comm_order_req_det();
        END IF;
    
        -- getting signature label
        l_sig_code_message := g_sm_comm_order_m005; -- 'Documented:'
    
        g_error := 'OPEN c_hist ';
        OPEN c_hist;
        FETCH c_hist BULK COLLECT
            INTO l_hist_tab;
        CLOSE c_hist;
    
        g_error := '<<hist_loop>> ';
        <<hist_loop>>
        FOR i IN 1 .. l_hist_tab.count
        LOOP
            -- check if there was an update to the existing data
            IF l_hist_prev IS NOT NULL
               AND show_in_history(i_lang    => i_lang,
                                   i_prof    => i_prof,
                                   i_rec_old => l_hist_tab(i),
                                   i_rec_new => l_hist_prev, -- ordered desc, this record is most recent than l_hist_tab(i)
                                   i_field   => NULL, -- all possible fields
                                   o_old_set => l_old_set,
                                   o_new_set => l_new_set) = pk_alert_constant.g_yes
            THEN
                l_sig_code_message := g_sm_comm_order_m006; -- 'Updated:'
                EXIT hist_loop;
            END IF;
        
            l_hist_prev := l_hist_tab(i);
        END LOOP hist_loop;
        ----------------------
    
        -- format data of the request        
        g_error := 'Call format_data_order ';
    
        g_retval := format_data_order(i_lang               => i_lang,
                                      i_prof               => i_prof,
                                      i_rec_comm_order_req => i_rec_comm_order_req,
                                      i_rank               => i_rank,
                                      i_sig_code_message   => l_sig_code_message,
                                      i_flg_show_status    => i_show_status,
                                      io_id_section        => io_id_section,
                                      io_data              => io_data,
                                      o_error              => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_COMM_ORDER_REQ',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_comm_order_req;

    FUNCTION get_comm_order_exec
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_rank               IN NUMBER,
        io_id_section        IN OUT NUMBER,
        i_rec_comm_order_req IN t_rec_comm_order_req,
        io_data              IN OUT t_coll_comm_order_req_det,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_sig_code_message sys_message.code_message%TYPE;
    
        l_tbl_comm_order_plan t_coll_comm_order_plan_info;
    
    BEGIN
    
        IF io_data IS NULL
        THEN
            io_data := t_coll_comm_order_req_det();
        END IF;
    
        SELECT t_rec_comm_order_plan_info(decode(tt.flg_status,
                                                 g_flg_status_r,
                                                 g_action_order,
                                                 g_flg_status_a,
                                                 g_action_concluded,
                                                 g_flg_status_e,
                                                 decode(lag(tt.flg_status, 1) over(ORDER BY rownum),
                                                        g_flg_status_e,
                                                        g_action_monitored,
                                                        g_action_executed),
                                                 g_flg_status_c,
                                                 g_action_canceled,
                                                 'NA'),
                                          tt.flg_origin,
                                          tt.id_comm_order_plan,
                                          tt.id_comm_order_req,
                                          tt.flg_status,
                                          tt.id_epis_documentation,
                                          tt.exec_number,
                                          decode(tt.id_prof_performed,
                                                 NULL,
                                                 NULL,
                                                 pk_prof_utils.get_name_signature(i_lang, i_prof, tt.id_prof_performed)),
                                          pk_prof_utils.get_name_signature(i_lang,
                                                                           i_prof,
                                                                           nvl(tt.id_prof_take, tt.id_prof_cancel)) || '; ' ||
                                          pk_date_utils.date_char_tsz(i_lang,
                                                                      nvl(tt.dt_comm_order_plan, tt.dt_cancel_tstz),
                                                                      i_prof.institution,
                                                                      i_prof.software),
                                          decode(tt.start_time,
                                                 NULL,
                                                 NULL,
                                                 pk_date_utils.date_char_tsz(i_lang,
                                                                             tt.start_time,
                                                                             i_prof.institution,
                                                                             i_prof.software)),
                                          decode(tt.end_time,
                                                 NULL,
                                                 NULL,
                                                 pk_date_utils.date_char_tsz(i_lang,
                                                                             tt.end_time,
                                                                             i_prof.institution,
                                                                             i_prof.software)),
                                          decode(tt.id_cancel_reason,
                                                 NULL,
                                                 NULL,
                                                 pk_cancel_reason.get_cancel_reason_desc(i_lang,
                                                                                         i_prof,
                                                                                         tt.id_cancel_reason)),
                                          decode(tt.notes_cancel, NULL, NULL, tt.notes_cancel),
                                          tt.notes,
                                          nvl(tt.dt_comm_order_plan, tt.dt_cancel_tstz))
          BULK COLLECT
          INTO l_tbl_comm_order_plan
          FROM (SELECT t.*
                  FROM (SELECT 'P' flg_origin,
                               cop.id_comm_order_plan,
                               cop.id_comm_order_req,
                               cop.id_prof_take,
                               cop.notes,
                               cop.flg_status,
                               cop.id_prof_cancel,
                               cop.notes_cancel,
                               cop.id_wound_treat,
                               cop.id_episode_write,
                               cop.dt_plan_tstz,
                               cop.dt_take_tstz,
                               cop.dt_cancel_tstz,
                               cop.id_prof_performed,
                               cop.start_time,
                               cop.end_time,
                               nvl(cop.dt_last_update_tstz, cop.dt_take_tstz) dt_comm_order_plan,
                               cop.create_user,
                               cop.create_time,
                               cop.create_institution,
                               cop.update_user,
                               cop.update_time,
                               cop.update_institution,
                               cop.flg_supplies_reg,
                               cop.id_cancel_reason,
                               cop.id_cdr_event,
                               cop.id_epis_documentation,
                               cop.exec_number,
                               cop.id_prof_last_update,
                               cop.dt_last_update_tstz,
                               NULL dt_comm_order_plan_tstz,
                               cop.dt_comm_order_plan dt_order
                          FROM comm_order_plan cop
                         WHERE cop.id_comm_order_req = i_rec_comm_order_req.id_comm_order_req
                        UNION ALL
                        SELECT 'H' flg_origin,
                               coph.id_comm_order_plan,
                               coph.id_comm_order_req,
                               coph.id_prof_take,
                               coph.notes,
                               coph.flg_status,
                               coph.id_prof_cancel,
                               coph.notes_cancel,
                               coph.id_wound_treat,
                               coph.id_episode_write,
                               coph.dt_plan_tstz,
                               coph.dt_take_tstz,
                               coph.dt_cancel_tstz,
                               coph.id_prof_performed,
                               coph.start_time,
                               coph.end_time,
                               coph.dt_last_update_tstz dt_comm_order_plan,
                               coph.create_user,
                               coph.create_time,
                               coph.create_institution,
                               coph.update_user,
                               coph.update_time,
                               coph.update_institution,
                               coph.flg_supplies_reg,
                               coph.id_cancel_reason,
                               coph.id_cdr_event,
                               coph.id_epis_documentation,
                               coph.exec_number,
                               coph.id_prof_last_update,
                               coph.dt_last_update_tstz,
                               coph.dt_comm_order_plan_tstz,
                               coph.dt_comm_order_plan_hist_tstz dt_order
                          FROM comm_order_plan_hist coph
                         WHERE coph.id_comm_order_req = i_rec_comm_order_req.id_comm_order_req) t
                 WHERE t.flg_status IN
                       (g_flg_status_a, g_flg_status_e, g_flg_status_r, g_flg_status_c, g_comm_order_plan_discontinued)
                 ORDER BY t.exec_number ASC, t.id_comm_order_plan ASC, t.flg_origin ASC, t.dt_order ASC NULLS FIRST) tt;
    
        ----------------------
        -- getting signature label
        l_sig_code_message := g_sm_comm_order_m005; -- 'Documented:'
    
        -- format data of the request        
        g_error := 'Call format_data_order ';
    
        IF l_tbl_comm_order_plan.count > 0
        THEN
            g_retval := format_data_execution(i_lang                => i_lang,
                                              i_prof                => i_prof,
                                              i_rec_comm_order_req  => i_rec_comm_order_req,
                                              i_tbl_comm_order_plan => l_tbl_comm_order_plan,
                                              i_rank                => i_rank,
                                              i_sig_code_message    => l_sig_code_message,
                                              io_id_section         => io_id_section,
                                              io_data               => io_data,
                                              o_error               => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_COMM_ORDER_EXEC',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_comm_order_exec;

    FUNCTION get_comm_order_req_co_signed
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_rank               IN NUMBER,
        io_id_section        IN OUT NUMBER,
        i_rec_comm_order_req IN t_rec_comm_order_req,
        io_data              IN OUT t_coll_comm_order_req_det,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF io_data IS NULL
        THEN
            io_data := t_coll_comm_order_req_det();
        END IF;
    
        -- func  
        -- format data of the co-signed data
        g_error  := 'Call format_data_co_signed ';
        g_retval := format_data_co_signed(i_lang               => i_lang,
                                          i_prof               => i_prof,
                                          i_rec_comm_order_req => i_rec_comm_order_req,
                                          i_rank               => i_rank,
                                          io_id_section        => io_id_section,
                                          io_data              => io_data,
                                          o_error              => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_COMM_ORDER_REQ_CO_SIGNED',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_comm_order_req_co_signed;

    FUNCTION get_comm_order_req_hist
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_rec_comm_order_req IN t_rec_comm_order_req,
        i_flg_show_diff      IN VARCHAR2,
        i_rank               IN NUMBER,
        io_id_section        IN OUT NUMBER,
        io_data              IN OUT t_coll_comm_order_req_det,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_sts_exclude   table_number;
        l_req_hist         t_rec_comm_order_req := t_rec_comm_order_req();
        l_req_hist_prev    t_rec_comm_order_req;
        l_field_style      VARCHAR2(30 CHAR);
        l_old_set          PLS_INTEGER;
        l_new_set          PLS_INTEGER;
        l_sig_code_message sys_message.code_message%TYPE;
        l_flg_show_h       VARCHAR2(1 CHAR);
    
        l_hist_tab        t_coll_comm_order_req;
        l_id_cor_hist_tab table_number;
    
        l_co_sign_data t_table_co_sign;
    
        CURSOR c_hist
        (
            i_id_comm_order_req IN comm_order_req_hist.id_comm_order_req%TYPE,
            i_sts_exclude       IN table_number
        ) IS
            SELECT corh.id_comm_order_req_hist,
                   t_rec_comm_order_req(corh.id_comm_order_req,
                                        corh.id_workflow,
                                        corh.id_status,
                                        corh.id_patient,
                                        corh.id_episode,
                                        corh.id_concept_type,
                                        corh.id_concept_version,
                                        corh.id_cncpt_vrs_inst_owner,
                                        corh.id_concept_term,
                                        corh.id_cncpt_trm_inst_owner,
                                        corh.flg_free_text,
                                        corh.desc_concept_term,
                                        corh.id_prof_req,
                                        corh.id_inst_req,
                                        corh.dt_req,
                                        corh.notes,
                                        corh.clinical_indication,
                                        corh.flg_clinical_purpose,
                                        corh.clinical_purpose_desc,
                                        corh.flg_priority,
                                        corh.flg_prn,
                                        corh.prn_condition,
                                        corh.dt_begin,
                                        corh.id_professional,
                                        corh.id_institution,
                                        corh.dt_status,
                                        corh.notes_cancel,
                                        corh.id_cancel_reason,
                                        corh.flg_need_ack,
                                        corh.flg_action,
                                        corh.id_previous_status,
                                        corh.task_duration,
                                        corh.id_order_recurr,
                                        corh.id_task_type,
                                        t_table_co_sign())
              FROM comm_order_req_hist corh
             WHERE corh.id_comm_order_req = i_id_comm_order_req
               AND (i_sts_exclude IS NULL OR
                   corh.id_status NOT IN (SELECT /*+opt_estimate (table t rows=1)*/
                                            column_value
                                             FROM TABLE(i_sts_exclude) t))
             ORDER BY corh.dt_status ASC;
    
    BEGIN
    
        l_id_sts_exclude := table_number();
    
        IF io_data IS NULL
        THEN
            io_data := t_coll_comm_order_req_det();
        END IF;
    
        -- func
        IF i_rec_comm_order_req.id_status != g_id_sts_draft
        THEN
            l_id_sts_exclude.extend;
            l_id_sts_exclude(l_id_sts_exclude.last) := g_id_sts_draft; -- IF actual status is not draft, then do not show history of drafts
        END IF;
    
        IF i_rec_comm_order_req.id_status != g_id_sts_predf
        THEN
            l_id_sts_exclude.extend;
            l_id_sts_exclude(l_id_sts_exclude.last) := g_id_sts_predf; -- IF actual status is not predefined, then do not show history of predefined
        END IF;
    
        IF i_flg_show_diff = pk_alert_constant.g_yes
        THEN
            l_field_style := NULL; -- style defined inside the functions          
        ELSE
            l_field_style := g_field_style_hist; -- format data with this style
        END IF;
    
        -- get co-sign data that is valid to show in history: remove flg_status=CS and (FLG_STATUS=NA that were invalidated by other co-signs)
        g_error := 'SELECT t_rec_co_sign( ';
        SELECT t_rec_co_sign(id_co_sign           => cs.id_co_sign,
                             id_co_sign_hist      => cs.id_co_sign_hist,
                             id_episode           => cs.id_episode,
                             id_task              => cs.id_task,
                             id_task_group        => cs.id_task_group,
                             id_task_type         => cs.id_task_type,
                             desc_task_type       => cs.desc_task_type,
                             icon_task_type       => cs.icon_task_type,
                             id_action            => cs.id_action,
                             desc_action          => cs.desc_action,
                             id_task_type_action  => cs.id_task_type_action,
                             desc_order           => cs.desc_order,
                             desc_instructions    => cs.desc_instructions,
                             desc_task_action     => cs.desc_task_action,
                             id_order_type        => cs.id_order_type,
                             desc_order_type      => cs.desc_order_type,
                             id_prof_created      => cs.id_prof_created,
                             id_prof_ordered_by   => cs.id_prof_ordered_by,
                             desc_prof_ordered_by => cs.desc_prof_ordered_by,
                             id_prof_co_signed    => cs.id_prof_co_signed,
                             dt_req               => cs.dt_req,
                             dt_created           => cs.dt_created,
                             dt_ordered_by        => cs.dt_ordered_by,
                             dt_co_signed         => cs.dt_co_signed,
                             dt_exec_date_sort    => cs.dt_exec_date_sort,
                             flg_status           => cs.flg_status,
                             icon_status          => cs.icon_status,
                             desc_status          => cs.desc_status,
                             code_co_sign_notes   => cs.code_co_sign_notes,
                             co_sign_notes        => cs.co_sign_notes,
                             flg_has_notes        => cs.flg_has_notes,
                             flg_needs_cosign     => cs.flg_needs_cosign,
                             flg_has_cosign       => cs.flg_has_cosign,
                             flg_made_auth        => cs.flg_made_auth)
          BULK COLLECT
          INTO l_co_sign_data
          FROM (SELECT tt.*,
                        lag(tt.id_order_type, 1) over(ORDER BY dt_created ASC) AS prev_id_order_type,
                        lag(tt.id_prof_ordered_by, 1) over(ORDER BY dt_created ASC) AS prev_id_prof_ordered_by,
                        lag(tt.dt_ordered_by, 1) over(ORDER BY dt_created ASC) AS prev_dt_ordered_by,
                        lag(tt.id_prof_co_signed, 1) over(ORDER BY dt_created ASC) AS prev_id_prof_co_signed,
                        lag(tt.dt_co_signed, 1) over(ORDER BY dt_created ASC) AS prev_dt_co_signed
                   FROM (SELECT /*+opt_estimate (table tt rows=1)*/
                           row_number() over(PARTITION BY id_task_group ORDER BY dt_created ASC) rn, t.*
                            FROM TABLE(i_rec_comm_order_req.co_sign_data) t
                          -- co-signed co-signs are treated in function format_data_hist_co_signed
                          -- outdated co-signs were invalidated by another co-sign, we don't want to print this information
                         WHERE t.flg_status NOT IN
                               (pk_co_sign_api.g_cosign_flg_status_cs, pk_co_sign_api.g_cosign_flg_status_o)) tt) cs
         WHERE (cs.prev_id_order_type IS NULL AND cs.prev_id_prof_ordered_by IS NULL AND cs.prev_dt_ordered_by IS NULL)
            OR (cs.prev_id_order_type <> cs.id_order_type OR cs.prev_id_prof_ordered_by <> cs.id_prof_ordered_by OR
               cs.prev_dt_ordered_by <> cs.dt_ordered_by OR cs.prev_id_prof_co_signed <> cs.id_prof_co_signed OR
               cs.prev_dt_co_signed <> cs.dt_co_signed);
    
        -- get comm order req hist
        g_error := 'OPEN c_hist (i_id_comm_order_req => ' || i_rec_comm_order_req.id_comm_order_req ||
                   ', i_sts_exclude => ' || pk_utils.to_string(l_id_sts_exclude) || ') ';
        OPEN c_hist(i_id_comm_order_req => i_rec_comm_order_req.id_comm_order_req, i_sts_exclude => l_id_sts_exclude);
        FETCH c_hist BULK COLLECT
            INTO l_id_cor_hist_tab, l_hist_tab;
        CLOSE c_hist;
    
        g_error := 'FOR i IN 1 .. ' || l_hist_tab.count;
        FOR i IN 1 .. l_hist_tab.count
        LOOP
            l_req_hist := l_hist_tab(i);
        
            -- gets co-sign data related to this change
            g_error := 'Gets co-sign data related to this action / ID_COMM_ORDER_REQ_HIST=' || l_id_cor_hist_tab(i);
            FOR j IN 1 .. l_co_sign_data.count
            LOOP
                g_error := 'ID_TASK=' || l_co_sign_data(j).id_task || ' CS_FLG_STATUS=' || l_co_sign_data(j).flg_status;
                IF l_co_sign_data(j).id_task = l_id_cor_hist_tab(i)
                THEN
                    -- this is the ID_COMM_ORDER_REQ_HIST related to this change
                    l_req_hist.co_sign_data.extend;
                    l_req_hist.co_sign_data(l_req_hist.co_sign_data.last) := l_co_sign_data(j);
                END IF;
            END LOOP;
        
            g_error := 'IF l_req_hist_prev IS NULL ';
            IF l_req_hist_prev IS NULL
            THEN
                -- old record 
                l_sig_code_message := g_sm_comm_order_m005; -- 'Documented:'
            
                IF i_flg_show_diff = pk_alert_constant.g_yes
                THEN
                    -- print the old one
                    g_error  := 'Call format_data_order ';
                    g_retval := format_data_order(i_lang               => i_lang,
                                                  i_prof               => i_prof,
                                                  i_rec_comm_order_req => l_req_hist,
                                                  i_rank               => i_rank,
                                                  i_field_style        => l_field_style,
                                                  i_sig_code_message   => l_sig_code_message,
                                                  i_flg_show_status    => pk_alert_constant.g_yes,
                                                  io_id_section        => io_id_section,
                                                  io_data              => io_data,
                                                  o_error              => o_error);
                
                    IF NOT g_retval
                    THEN
                        RAISE g_exception_np;
                    END IF;
                END IF;
            
            ELSE
                -- remaining records
                l_flg_show_h := show_in_history(i_lang    => i_lang,
                                                i_prof    => i_prof,
                                                i_rec_old => l_req_hist_prev,
                                                i_rec_new => l_req_hist,
                                                i_field   => NULL, -- check all possible fields
                                                o_old_set => l_old_set,
                                                o_new_set => l_new_set);
            
                IF l_flg_show_h = pk_alert_constant.g_yes
                THEN
                
                    g_error := 'i_flg_show_diff=' || i_flg_show_diff;
                    -- show history                
                    IF i_flg_show_diff = pk_alert_constant.g_yes
                    THEN
                        -- get differences only and format
                        g_error  := 'Call format_data_hist ';
                        g_retval := format_data_hist(i_lang        => i_lang,
                                                     i_prof        => i_prof,
                                                     i_rec_new     => l_req_hist,
                                                     i_rec_old     => l_req_hist_prev,
                                                     i_rank        => i_rank,
                                                     io_id_section => io_id_section,
                                                     io_data       => io_data,
                                                     o_error       => o_error);
                    
                        IF NOT g_retval
                        THEN
                            RAISE g_exception_np;
                        END IF;
                    
                    ELSIF i_flg_show_diff = pk_alert_constant.g_no
                    THEN
                        -- gets the entire data (of the previous record)
                        g_error  := 'Call format_data_order ';
                        g_retval := format_data_order(i_lang               => i_lang,
                                                      i_prof               => i_prof,
                                                      i_rec_comm_order_req => l_req_hist_prev,
                                                      i_rank               => i_rank,
                                                      i_field_style        => l_field_style,
                                                      i_sig_code_message   => l_sig_code_message,
                                                      i_flg_show_status    => pk_alert_constant.g_yes,
                                                      io_id_section        => io_id_section,
                                                      io_data              => io_data,
                                                      o_error              => o_error);
                    
                        IF NOT g_retval
                        THEN
                            RAISE g_exception_np;
                        END IF;
                    
                        -- l_sig_code_message updated after format_data_order because l_req_hist_prev can refer to the oldest record (first iteration)
                        l_sig_code_message := g_sm_comm_order_m006; -- 'Updated:'
                    
                    END IF;
                END IF;
            END IF;
        
            g_error         := 'l_req_hist_prev := l_req_hist; ';
            l_req_hist_prev := l_req_hist;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_COMM_ORDER_REQ_HIST',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_comm_order_req_hist;

    FUNCTION get_comm_order_req_h_co_signed
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_rank               IN NUMBER,
        io_id_section        IN OUT NUMBER,
        i_rec_comm_order_req IN t_rec_comm_order_req,
        io_data              IN OUT t_coll_comm_order_req_det,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_req_hist      t_rec_co_sign;
        l_req_hist_prev t_rec_co_sign;
        l_co_sign_data  t_table_co_sign;
        l_header_1      VARCHAR2(1000 CHAR);
        l_code_header_1 sys_message.code_message%TYPE;
        l_flg_action    comm_order_req_hist.flg_action%TYPE;
        l_signature     VARCHAR2(1000 CHAR);
        l_dt_detail     TIMESTAMP(6) WITH LOCAL TIME ZONE;
    
        -- gets data to build the entire block
        PROCEDURE get_common_data IS
        BEGIN
            -- get flg_action related to this co-sign
            g_error      := 'Call get_co_sign_action ';
            l_flg_action := get_co_sign_action(i_id_task => l_req_hist.id_task);
        
            -- getting common values
            g_error := 'CASE l_flg_action / l_flg_action=' || l_flg_action;
            CASE
                WHEN l_flg_action IN (g_action_order, g_action_draft) THEN
                    l_code_header_1 := g_sm_comm_order_t043;
                WHEN l_flg_action = g_action_edition THEN
                    l_code_header_1 := g_sm_comm_order_t043;
                WHEN l_flg_action = g_action_canceled THEN
                    l_code_header_1 := g_sm_comm_order_t047;
                WHEN l_flg_action = g_action_dicontinued THEN
                    l_code_header_1 := g_sm_comm_order_t049;
                ELSE
                    l_code_header_1 := NULL;
            END CASE;
        
            l_header_1    := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_header_1);
            io_id_section := io_id_section + 1; -- new section
        
            l_dt_detail := l_req_hist.dt_co_signed; -- co_signed date
        
            g_error  := 'Call get_signature / ID_PROF=' || i_rec_comm_order_req.id_professional;
            g_retval := get_signature(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_code_message => g_sm_comm_order_m005, -- 'Documented:'
                                      i_id_prof_op   => l_req_hist.id_prof_co_signed,
                                      i_dt_op        => l_dt_detail,
                                      o_text         => l_signature,
                                      o_error        => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
        END get_common_data;
    
    BEGIN
    
        IF io_data IS NULL
        THEN
            io_data := t_coll_comm_order_req_det();
        END IF;
    
        -- gets all history co-signed co-signs
        g_error := 'SELECT t_rec_co_sign() co-signed ';
        SELECT /*+opt_estimate (table cs rows=1)*/
         t_rec_co_sign(id_co_sign           => cs.id_co_sign,
                       id_co_sign_hist      => cs.id_co_sign_hist,
                       id_episode           => cs.id_episode,
                       id_task              => cs.id_task,
                       id_task_group        => cs.id_task_group,
                       id_task_type         => cs.id_task_type,
                       desc_task_type       => cs.desc_task_type,
                       icon_task_type       => cs.icon_task_type,
                       id_action            => cs.id_action,
                       desc_action          => cs.desc_action,
                       id_task_type_action  => cs.id_task_type_action,
                       desc_order           => cs.desc_order,
                       desc_instructions    => cs.desc_instructions,
                       desc_task_action     => cs.desc_task_action,
                       id_order_type        => cs.id_order_type,
                       desc_order_type      => cs.desc_order_type,
                       id_prof_created      => cs.id_prof_created,
                       id_prof_ordered_by   => cs.id_prof_ordered_by,
                       desc_prof_ordered_by => cs.desc_prof_ordered_by,
                       id_prof_co_signed    => cs.id_prof_co_signed,
                       dt_req               => cs.dt_req,
                       dt_created           => cs.dt_created,
                       dt_ordered_by        => cs.dt_ordered_by,
                       dt_co_signed         => cs.dt_co_signed,
                       dt_exec_date_sort    => cs.dt_exec_date_sort,
                       flg_status           => cs.flg_status,
                       icon_status          => cs.icon_status,
                       desc_status          => cs.desc_status,
                       code_co_sign_notes   => cs.code_co_sign_notes,
                       co_sign_notes        => cs.co_sign_notes,
                       flg_has_notes        => cs.flg_has_notes,
                       flg_needs_cosign     => cs.flg_needs_cosign,
                       flg_has_cosign       => cs.flg_has_cosign,
                       flg_made_auth        => cs.flg_made_auth)
          BULK COLLECT
          INTO l_co_sign_data
          FROM TABLE(i_rec_comm_order_req.co_sign_data) cs
         WHERE EXISTS (SELECT /*+opt_estimate (table ti rows=1)*/
                 1 -- gets all history id_co_signs that has at least one co-signed record
                  FROM TABLE(i_rec_comm_order_req.co_sign_data) ti
                 WHERE ti.id_co_sign = cs.id_co_sign
                   AND ti.flg_status = pk_co_sign_api.g_cosign_flg_status_cs)
           AND cs.flg_status != pk_co_sign_api.g_cosign_flg_status_d -- remove draft records
         ORDER BY cs.id_co_sign, cs.dt_created DESC;
    
        g_error := 'FOR i IN 1 .. ' || l_co_sign_data.count;
        FOR i IN 1 .. l_co_sign_data.count
        LOOP
            l_req_hist := l_co_sign_data(i);
        
            IF l_req_hist_prev IS NULL
               OR l_req_hist.id_co_sign != l_req_hist_prev.id_co_sign
            THEN
                get_common_data(); -- gets flg_action, header_1, signature, dt_detail data
            ELSE
            
                g_error  := 'Call format_data_hist_co_signed / l_flg_action=' || l_flg_action;
                g_retval := format_data_hist_co_signed(i_lang              => i_lang,
                                                       i_prof              => i_prof,
                                                       i_id_comm_order_req => i_rec_comm_order_req.id_comm_order_req,
                                                       i_rec_new           => l_req_hist_prev,
                                                       i_rec_old           => l_req_hist,
                                                       i_header_1          => l_header_1,
                                                       i_rank              => i_rank,
                                                       i_signature         => l_signature,
                                                       i_flg_action        => l_flg_action,
                                                       io_id_section       => io_id_section,
                                                       io_data             => io_data,
                                                       o_error             => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            END IF;
        
            g_error         := 'l_req_hist_prev := l_req_hist; ';
            l_req_hist_prev := l_req_hist;
        
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_COMM_ORDER_REQ_H_CO_SIGNED',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_comm_order_req_h_co_signed;

    FUNCTION get_comm_order_req_ack
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_rec_comm_order_req IN t_rec_comm_order_req,
        i_rank               IN NUMBER,
        io_id_section        IN OUT NUMBER,
        io_data              IN OUT t_coll_comm_order_req_det,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF io_data IS NULL
        THEN
            io_data := t_coll_comm_order_req_det();
        END IF;
    
        -- func
        -- format data of the acknowledge
        g_error  := 'Call format_data_ack ';
        g_retval := format_data_ack(i_lang              => i_lang,
                                    i_prof              => i_prof,
                                    i_id_comm_order_req => i_rec_comm_order_req.id_comm_order_req,
                                    i_rank              => i_rank,
                                    io_id_section       => io_id_section,
                                    io_data             => io_data,
                                    o_error             => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_COMM_ORDER_REQ_ACK',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_comm_order_req_ack;

    FUNCTION get_comm_order_req_sts
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_rec_comm_order_req IN t_rec_comm_order_req,
        i_rank               IN NUMBER,
        io_id_section        IN OUT NUMBER,
        io_data              IN OUT t_coll_comm_order_req_det,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rec_comm_order_req t_rec_comm_order_req;
    
    BEGIN
    
        IF io_data IS NULL
        THEN
            io_data := t_coll_comm_order_req_det();
        END IF;
    
        -- func
        l_rec_comm_order_req := i_rec_comm_order_req;
    
        -- getting co-sign data related to this status change
        g_error := 'SELECT t_rec_co_sign() co-signed ';
        SELECT /*+opt_estimate (table cs rows=1)*/
         t_rec_co_sign(id_co_sign           => cs.id_co_sign,
                       id_co_sign_hist      => cs.id_co_sign_hist,
                       id_episode           => cs.id_episode,
                       id_task              => cs.id_task,
                       id_task_group        => cs.id_task_group,
                       id_task_type         => cs.id_task_type,
                       desc_task_type       => cs.desc_task_type,
                       icon_task_type       => cs.icon_task_type,
                       id_action            => cs.id_action,
                       desc_action          => cs.desc_action,
                       id_task_type_action  => cs.id_task_type_action,
                       desc_order           => cs.desc_order,
                       desc_instructions    => cs.desc_instructions,
                       desc_task_action     => cs.desc_task_action,
                       id_order_type        => cs.id_order_type,
                       desc_order_type      => cs.desc_order_type,
                       id_prof_created      => cs.id_prof_created,
                       id_prof_ordered_by   => cs.id_prof_ordered_by,
                       desc_prof_ordered_by => cs.desc_prof_ordered_by,
                       id_prof_co_signed    => cs.id_prof_co_signed,
                       dt_req               => cs.dt_req,
                       dt_created           => cs.dt_created,
                       dt_ordered_by        => cs.dt_ordered_by,
                       dt_co_signed         => cs.dt_co_signed,
                       dt_exec_date_sort    => cs.dt_exec_date_sort,
                       flg_status           => cs.flg_status,
                       icon_status          => cs.icon_status,
                       desc_status          => cs.desc_status,
                       code_co_sign_notes   => cs.code_co_sign_notes,
                       co_sign_notes        => cs.co_sign_notes,
                       flg_has_notes        => cs.flg_has_notes,
                       flg_needs_cosign     => cs.flg_needs_cosign,
                       flg_has_cosign       => cs.flg_has_cosign,
                       flg_made_auth        => cs.flg_made_auth)
          BULK COLLECT
          INTO l_rec_comm_order_req.co_sign_data -- is this variable that matters
          FROM TABLE(i_rec_comm_order_req.co_sign_data) cs
          JOIN comm_order_req_hist corh
            ON (corh.id_comm_order_req_hist = cs.id_task)
         WHERE corh.id_status IN (g_id_sts_completed, g_id_sts_canceled); -- only this status changes has co-sign
    
        g_error  := 'Call format_data_status / ID_STATUS=' || i_rec_comm_order_req.id_status || ' ID_PROFESSIONAL=' ||
                    i_rec_comm_order_req.id_professional;
        g_retval := format_data_status(i_lang               => i_lang,
                                       i_prof               => i_prof,
                                       i_rec_comm_order_req => l_rec_comm_order_req,
                                       i_rank               => i_rank,
                                       io_id_section        => io_id_section,
                                       io_data              => io_data,
                                       o_error              => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_COMM_ORDER_REQ_STS',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_comm_order_req_sts;

    FUNCTION get_comm_order_req_sts_desc
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_status         IN comm_order_req.id_status%TYPE,
        i_dt_begin          IN comm_order_req.dt_begin%TYPE,
        i_id_comm_order_req IN comm_order_req.id_comm_order_req%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
    
        l_result              sys_domain.desc_val%TYPE;
        l_check_date          VARCHAR2(1 CHAR);
        l_sysdate             TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_code_status         sys_domain.code_domain%TYPE;
        l_count_tasks         NUMBER := 0;
        l_id_task_type        task_type.id_task_type%TYPE;
        l_comm_order_workflow sys_config.value%TYPE;
    
    BEGIN
    
        l_sysdate := current_timestamp;
    
        l_comm_order_workflow := pk_sysconfig.get_config(g_comm_order_exec_workflow, i_prof);
    
        IF i_id_comm_order_req IS NOT NULL
        THEN
            SELECT COUNT(1)
              INTO l_count_tasks
              FROM comm_order_plan cop
             WHERE cop.id_comm_order_req = i_id_comm_order_req
               AND cop.flg_status NOT IN (g_comm_order_plan_cancel, g_comm_order_plan_req);
        END IF;
    
        SELECT cor.id_task_type
          INTO l_id_task_type
          FROM comm_order_req cor
         WHERE cor.id_comm_order_req = i_id_comm_order_req;
    
        IF i_id_status = g_id_sts_ongoing
        THEN
            g_error      := 'Call pk_date_utils.compare_dates_tsz ';
            l_check_date := pk_date_utils.compare_dates_tsz(i_prof  => i_prof,
                                                            i_date1 => i_dt_begin,
                                                            i_date2 => l_sysdate);
        
            IF l_check_date = pk_alert_constant.g_date_greater
               AND l_count_tasks = 0
            THEN
                -- order
                l_code_status := g_code_status_order;
            ELSE
                IF l_count_tasks > 0
                   OR (l_id_task_type = pk_alert_constant.g_task_comm_orders AND
                   l_comm_order_workflow = pk_alert_constant.g_no)
                THEN
                    -- ongoing
                    l_code_status := g_code_status;
                ELSE
                    -- order
                    l_code_status := g_code_status_order;
                END IF;
            END IF;
        
        ELSE
            l_code_status := g_code_status;
        END IF;
    
        g_error  := 'Call pk_sysdomain.get_domain / code_status=' || l_code_status;
        l_result := pk_sysdomain.get_domain(i_code_dom => l_code_status, i_val => i_id_status, i_lang => i_lang);
    
        RETURN l_result;
    
    END get_comm_order_req_sts_desc;

    FUNCTION get_comm_order_req_detail
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_comm_order_req IN comm_order_req.id_comm_order_req%TYPE,
        o_status            OUT VARCHAR2,
        o_title             OUT VARCHAR2,
        o_cur_current       OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_current_tab    t_coll_comm_order_req_det;
        l_comm_order_req t_rec_comm_order_req := t_rec_comm_order_req();
        l_rank           PLS_INTEGER;
        l_id_section     PLS_INTEGER := 0;
    
    BEGIN
    
        -- get comm order req data
        g_error  := 'Call get_commo_orders_req_row ';
        g_retval := get_comm_order_req_row(i_lang              => i_lang,
                                           i_prof              => i_prof,
                                           i_id_comm_order_req => i_id_comm_order_req,
                                           o_row               => l_comm_order_req,
                                           o_error             => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- gets actual co-sign data
        g_error                       := 'Call get_actual_cs_info ';
        l_comm_order_req.co_sign_data := get_actual_cs_info(i_lang              => i_lang,
                                                            i_prof              => i_prof,
                                                            i_id_episode        => l_comm_order_req.id_episode,
                                                            i_id_comm_order_req => l_comm_order_req.id_comm_order_req);
    
        -- get comm order request info
        l_rank   := 1;
        g_error  := 'Call get_comm_order_req ';
        g_retval := get_comm_order_req(i_lang               => i_lang,
                                       i_prof               => i_prof,
                                       i_rec_comm_order_req => l_comm_order_req,
                                       i_rank               => l_rank,
                                       io_id_section        => l_id_section,
                                       io_data              => l_current_tab,
                                       o_error              => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        l_rank   := 2;
        g_error  := 'Call get_comm_order_exec ';
        g_retval := get_comm_order_exec(i_lang               => i_lang,
                                        i_prof               => i_prof,
                                        i_rec_comm_order_req => l_comm_order_req,
                                        i_rank               => l_rank,
                                        io_id_section        => l_id_section,
                                        io_data              => l_current_tab,
                                        o_error              => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- get all acknowledgments if not cancelled
        IF l_comm_order_req.id_status != g_id_sts_canceled
        THEN
            -- l_rank   := 2; -- same rank as co-signs
            g_error  := 'Call get_comm_order_req_ack ';
            g_retval := get_comm_order_req_ack(i_lang               => i_lang,
                                               i_prof               => i_prof,
                                               i_rec_comm_order_req => l_comm_order_req,
                                               i_rank               => l_rank,
                                               io_id_section        => l_id_section,
                                               io_data              => l_current_tab,
                                               o_error              => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            -- get last status info - we have decided in issue ALERT-291069 that this block (only in detail screen)  will no longer be shown
        END IF;
    
        l_rank   := 3;
        g_error  := 'Call get_comm_order_req_co_signed ';
        g_retval := get_comm_order_req_co_signed(i_lang               => i_lang,
                                                 i_prof               => i_prof,
                                                 i_rank               => l_rank,
                                                 io_id_section        => l_id_section,
                                                 i_rec_comm_order_req => l_comm_order_req,
                                                 io_data              => l_current_tab,
                                                 o_error              => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- get status desc
        g_error  := 'Call get_comm_order_req_sts_desc / ID_STATUS=' || l_comm_order_req.id_status;
        o_status := get_comm_order_req_sts_desc(i_lang              => i_lang,
                                                i_prof              => i_prof,
                                                i_id_status         => l_comm_order_req.id_status,
                                                i_dt_begin          => l_comm_order_req.dt_begin,
                                                i_id_comm_order_req => l_comm_order_req.id_comm_order_req);
    
        -- get title desc
        g_error := 'Call get_comm_order_title ';
        o_title := get_comm_order_title(i_lang                     => i_lang,
                                        i_prof                     => i_prof,
                                        i_concept_type             => l_comm_order_req.id_concept_type,
                                        i_concept_term             => l_comm_order_req.id_concept_term,
                                        i_cncpt_trm_inst_owner     => l_comm_order_req.id_cncpt_trm_inst_owner,
                                        i_concept_version          => l_comm_order_req.id_concept_version,
                                        i_cncpt_vrs_inst_owner     => l_comm_order_req.id_cncpt_vrs_inst_owner,
                                        i_flg_free_text            => l_comm_order_req.flg_free_text,
                                        i_desc_concept_term        => l_comm_order_req.desc_concept_term,
                                        i_task_type                => l_comm_order_req.id_task_type,
                                        i_flg_show_comm_order_type => pk_alert_constant.g_yes,
                                        i_flg_trunc_clobs          => pk_alert_constant.g_no);
    
        -- open cursor with data
        g_error := 'OPEN o_cur_current FOR ';
        OPEN o_cur_current FOR
            SELECT /*+opt_estimate (table t rows=1)*/
             t.id_section, t.header_1, t.header_2, t.field_name, t.field_value, t.field_style, t.signature
              FROM TABLE(CAST(l_current_tab AS t_coll_comm_order_req_det)) t
             ORDER BY t.rank, t.dt_detail, t.field_rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_cur_current);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_COMM_ORDER_REQ_DETAIL',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_cur_current);
            RETURN FALSE;
    END get_comm_order_req_detail;

    FUNCTION get_comm_order_req_detail_h
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_comm_order_req IN comm_order_req.id_comm_order_req%TYPE,
        o_cur_hist          OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_hist_tab       t_coll_comm_order_req_det;
        l_comm_order_req t_rec_comm_order_req := t_rec_comm_order_req();
        l_rank           PLS_INTEGER;
        l_id_section     PLS_INTEGER := 0;
        l_id_task_type   task_type.id_task_type%TYPE;
    
    BEGIN
    
        -- get comm order req data
        g_error  := 'Call get_commo_orders_req_row ';
        g_retval := get_comm_order_req_row(i_lang              => i_lang,
                                           i_prof              => i_prof,
                                           i_id_comm_order_req => i_id_comm_order_req,
                                           o_row               => l_comm_order_req,
                                           o_error             => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- gets co-sign data to be shown in history detail screen
        g_error := 'Call pk_co_sign_api.tf_co_sign_task_hist_info ';
        SELECT cor.id_task_type
          INTO l_id_task_type
          FROM comm_order_req cor
         WHERE cor.id_comm_order_req = i_id_comm_order_req;
    
        l_comm_order_req.co_sign_data := pk_co_sign_api.tf_co_sign_task_hist_info(i_lang          => i_lang,
                                                                                  i_prof          => i_prof,
                                                                                  i_episode       => l_comm_order_req.id_episode,
                                                                                  i_task_type     => l_id_task_type,
                                                                                  i_id_task_group => l_comm_order_req.id_comm_order_req);
    
        -- get comm order request hist info
        l_rank   := 1;
        g_error  := 'Call get_comm_order_req_hist ';
        g_retval := get_comm_order_req_hist(i_lang               => i_lang,
                                            i_prof               => i_prof,
                                            i_rec_comm_order_req => l_comm_order_req,
                                            i_flg_show_diff      => pk_alert_constant.g_yes,
                                            i_rank               => l_rank,
                                            io_id_section        => l_id_section,
                                            io_data              => l_hist_tab,
                                            o_error              => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- l_rank := 1; -- same rank
        -- all co-signs
        g_error  := 'Call get_comm_order_req_h_co_signed ';
        g_retval := get_comm_order_req_h_co_signed(i_lang               => i_lang,
                                                   i_prof               => i_prof,
                                                   i_rank               => l_rank,
                                                   io_id_section        => l_id_section,
                                                   i_rec_comm_order_req => l_comm_order_req,
                                                   io_data              => l_hist_tab,
                                                   o_error              => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- get all acknowledgments
        g_error  := 'Call get_comm_order_req_ack ';
        g_retval := get_comm_order_req_ack(i_lang               => i_lang,
                                           i_prof               => i_prof,
                                           i_rec_comm_order_req => l_comm_order_req,
                                           i_rank               => l_rank,
                                           io_id_section        => l_id_section,
                                           io_data              => l_hist_tab,
                                           o_error              => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        --Executions
        g_error  := 'Call get_comm_order_exec ';
        g_retval := get_comm_order_exec(i_lang               => i_lang,
                                        i_prof               => i_prof,
                                        i_rec_comm_order_req => l_comm_order_req,
                                        i_rank               => l_rank,
                                        io_id_section        => l_id_section,
                                        io_data              => l_hist_tab,
                                        o_error              => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- open cursor with data
        g_error := 'OPEN o_cur_hist FOR ';
        OPEN o_cur_hist FOR
            SELECT /*+opt_estimate (table t rows=1)*/
             t.id_section, t.header_1, t.header_2, t.field_name, t.field_value, t.field_style, t.signature
              FROM TABLE(CAST(l_hist_tab AS t_coll_comm_order_req_det)) t
             ORDER BY t.rank DESC, t.dt_detail DESC, t.id_section, t.field_rank, t.style_rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_cur_hist);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_COMM_ORDER_REQ_DETAIL_H',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_cur_hist);
            RETURN FALSE;
    END get_comm_order_req_detail_h;

    FUNCTION get_comm_order_req_detail_rep
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN comm_order_req.id_episode%TYPE,
        i_flg_scope        IN VARCHAR2,
        i_flg_show_history IN VARCHAR2,
        i_flg_show_cancel  IN VARCHAR2,
        i_task_type        IN task_type.id_task_type%TYPE DEFAULT pk_alert_constant.g_task_medical_orders,
        o_title_info       OUT pk_types.cursor_type,
        o_detail_info      OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_patient          comm_order_req.id_patient%TYPE;
        l_id_visit            visit.id_visit%TYPE;
        l_id_episode          comm_order_req.id_episode%TYPE;
        l_info_tab            t_coll_comm_order_req_det := t_coll_comm_order_req_det();
        l_comm_order_req_tab  table_number;
        l_row_tab             t_coll_comm_order_req := t_coll_comm_order_req();
        l_comm_order_req      t_rec_comm_order_req := t_rec_comm_order_req();
        l_rank                PLS_INTEGER;
        l_id_section          PLS_INTEGER := 0;
        l_id_category         category.id_category%TYPE;
        l_id_profile_template profile_template.id_profile_template%TYPE;
    
    BEGIN
    
        l_id_category         := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
        l_id_profile_template := pk_tools.get_prof_profile_template(i_prof);
    
        g_error := 'CASE i_flg_scope ';
        CASE i_flg_scope
            WHEN pk_alert_constant.g_scope_type_patient THEN
                l_id_patient := pk_episode.get_id_patient(i_episode => i_id_episode);
            WHEN pk_alert_constant.g_scope_type_visit THEN
                l_id_visit := pk_episode.get_id_visit(i_episode => i_id_episode);
            WHEN pk_alert_constant.g_scope_type_episode THEN
                l_id_episode := i_id_episode;
            ELSE
                g_error := 'Invalid scope ';
                RAISE g_exception;
        END CASE;
    
        -- getting IDs to return info 
        g_error  := 'Call get_comm_order_req_ids ';
        g_retval := get_comm_order_req_ids(i_lang               => i_lang,
                                           i_prof               => i_prof,
                                           i_id_visit           => l_id_visit,
                                           i_id_patient         => l_id_patient,
                                           i_id_episode         => l_id_episode,
                                           i_id_status_exclude  => table_number(g_id_sts_predf), -- exclude predefined status
                                           i_tbl_task_type      => table_number(i_task_type),
                                           o_comm_order_req_tab => l_comm_order_req_tab,
                                           o_error              => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_comm_order_req_tab.count > 0
        THEN
        
            -- get comm order req data
            g_error  := 'Call get_commo_orders_req_rows ';
            g_retval := get_comm_order_req_rows(i_lang              => i_lang,
                                                i_prof              => i_prof,
                                                i_id_comm_order_req => l_comm_order_req_tab,
                                                o_row_tab           => l_row_tab,
                                                o_error             => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            g_error := 'FOR i IN 1 .. ' || l_row_tab.count;
            FOR i IN 1 .. l_row_tab.count
            LOOP
            
                l_comm_order_req := l_row_tab(i);
            
                -- get comm order request info            
                IF l_comm_order_req.id_status = g_id_sts_canceled
                   AND i_flg_show_cancel = pk_alert_constant.g_no
                THEN
                    NULL; -- do not show any information about this communication order req
                ELSE
                
                    -- gets actual co-sign data
                    g_error                       := 'Call get_actual_cs_info ';
                    l_comm_order_req.co_sign_data := get_actual_cs_info(i_lang              => i_lang,
                                                                        i_prof              => i_prof,
                                                                        i_id_episode        => l_comm_order_req.id_episode,
                                                                        i_id_comm_order_req => l_comm_order_req.id_comm_order_req);
                
                    l_rank := 1;
                    IF i_flg_show_history = pk_alert_constant.g_no
                    THEN
                        g_error  := 'Call get_comm_order_req ';
                        g_retval := get_comm_order_req(i_lang               => i_lang,
                                                       i_prof               => i_prof,
                                                       i_rec_comm_order_req => l_comm_order_req,
                                                       i_rank               => l_rank,
                                                       i_show_status        => i_flg_show_history, --When showing history it is necessary to show the status     
                                                       io_id_section        => l_id_section,
                                                       io_data              => l_info_tab,
                                                       o_error              => o_error);
                    
                        IF NOT g_retval
                        THEN
                            RAISE g_exception_np;
                        END IF;
                    
                    ELSE
                        -- get comm order request hist info
                        l_rank   := 2;
                        g_error  := 'Call get_comm_order_req_hist ';
                        g_retval := get_comm_order_req_hist(i_lang               => i_lang,
                                                            i_prof               => i_prof,
                                                            i_rec_comm_order_req => l_comm_order_req,
                                                            i_flg_show_diff      => pk_alert_constant.g_yes,
                                                            i_rank               => l_rank,
                                                            io_id_section        => l_id_section,
                                                            io_data              => l_info_tab,
                                                            o_error              => o_error);
                    
                        -- gets co-sign data to be shown in history report
                        g_error                       := 'Call pk_co_sign_api.tf_co_sign_task_hist_info ';
                        l_comm_order_req.co_sign_data := pk_co_sign_api.tf_co_sign_task_hist_info(i_lang          => i_lang,
                                                                                                  i_prof          => i_prof,
                                                                                                  i_episode       => l_comm_order_req.id_episode,
                                                                                                  i_task_type     => pk_alert_constant.g_task_comm_orders,
                                                                                                  i_id_task_group => l_comm_order_req.id_comm_order_req);
                    
                        IF NOT g_retval
                        THEN
                            RAISE g_exception_np;
                        END IF;
                    
                        IF NOT g_retval
                        THEN
                            RAISE g_exception_np;
                        END IF;
                    
                    END IF;
                
                    --get  comm order execution info
                    l_rank   := 2;
                    g_error  := 'Call get_comm_order_exec ';
                    g_retval := get_comm_order_exec(i_lang               => i_lang,
                                                    i_prof               => i_prof,
                                                    i_rec_comm_order_req => l_comm_order_req,
                                                    i_rank               => l_rank,
                                                    io_id_section        => l_id_section,
                                                    io_data              => l_info_tab,
                                                    o_error              => o_error);
                
                    IF NOT g_retval
                    THEN
                        RAISE g_exception_np;
                    END IF;
                
                    IF i_flg_show_history = pk_alert_constant.g_no
                    THEN
                        g_error  := 'Call get_comm_order_req_co_signed ';
                        g_retval := get_comm_order_req_co_signed(i_lang               => i_lang,
                                                                 i_prof               => i_prof,
                                                                 i_rank               => l_rank,
                                                                 io_id_section        => l_id_section,
                                                                 i_rec_comm_order_req => l_comm_order_req,
                                                                 io_data              => l_info_tab,
                                                                 o_error              => o_error);
                    
                        IF NOT g_retval
                        THEN
                            RAISE g_exception_np;
                        END IF;
                    END IF;
                
                    -- get last status info
                    IF l_comm_order_req.id_status != g_id_sts_canceled
                    THEN
                    
                        -- get all acknowledgments
                        l_rank   := 2;
                        g_error  := 'Call get_comm_order_req_ack ';
                        g_retval := get_comm_order_req_ack(i_lang               => i_lang,
                                                           i_prof               => i_prof,
                                                           i_rec_comm_order_req => l_comm_order_req,
                                                           i_rank               => l_rank,
                                                           io_id_section        => l_id_section,
                                                           io_data              => l_info_tab,
                                                           o_error              => o_error);
                    
                        IF NOT g_retval
                        THEN
                            RAISE g_exception_np;
                        END IF;
                    
                        l_rank   := 4;
                        g_error  := 'Call get_comm_order_req_sts ';
                        g_retval := get_comm_order_req_sts(i_lang               => i_lang,
                                                           i_prof               => i_prof,
                                                           i_rec_comm_order_req => l_comm_order_req,
                                                           i_rank               => l_rank,
                                                           io_id_section        => l_id_section,
                                                           io_data              => l_info_tab,
                                                           o_error              => o_error);
                    
                        IF NOT g_retval
                        THEN
                            RAISE g_exception_np;
                        END IF;
                    END IF;
                END IF;
            END LOOP;
        END IF;
    
        g_error := 'OPEN o_title_info FOR ';
        OPEN o_title_info FOR
            SELECT /*+opt_estimate (table t rows=1)*/
             t.id_comm_order_req,
             t.id_status,
             get_comm_order_req_sts_desc(i_lang              => i_lang,
                                         i_prof              => i_prof,
                                         i_id_status         => t.id_status,
                                         i_dt_begin          => t.dt_begin,
                                         i_id_comm_order_req => t.id_comm_order_req) status_desc,
             get_comm_order_title(i_lang                     => i_lang,
                                  i_prof                     => i_prof,
                                  i_concept_type             => t.id_concept_type,
                                  i_concept_term             => t.id_concept_term,
                                  i_cncpt_trm_inst_owner     => t.id_cncpt_trm_inst_owner,
                                  i_concept_version          => t.id_concept_version,
                                  i_cncpt_vrs_inst_owner     => t.id_cncpt_vrs_inst_owner,
                                  i_flg_free_text            => t.flg_free_text,
                                  i_desc_concept_term        => t.desc_concept_term,
                                  i_task_type                => t.id_task_type,
                                  i_flg_show_comm_order_type => pk_alert_constant.g_yes,
                                  i_flg_trunc_clobs          => pk_alert_constant.g_yes) title_desc
              FROM TABLE(CAST(l_row_tab AS t_coll_comm_order_req)) t
              JOIN comm_order_type cotype
                ON t.id_concept_type = cotype.id_comm_order_type
               AND t.id_task_type = cotype.id_task_type;
    
        IF i_flg_show_history = pk_alert_constant.g_no
        THEN
            -- open cursor with data
            g_error := 'OPEN o_detail_info FOR ';
            OPEN o_detail_info FOR
                SELECT /*+opt_estimate (table t rows=1)*/
                 t.id_comm_order_req,
                 t.id_section,
                 t.header_1,
                 t.header_2,
                 t.field_code,
                 t.field_name,
                 t.field_value,
                 t.field_style,
                 t.signature
                  FROM TABLE(CAST(l_info_tab AS t_coll_comm_order_req_det)) t
                  JOIN comm_order_req cor
                    ON (cor.id_comm_order_req = t.id_comm_order_req)
                  JOIN comm_order_type cotype
                    ON cor.id_concept_type = cotype.id_comm_order_type
                   AND cotype.id_task_type = cor.id_task_type
                 ORDER BY -- sorting communication order reqs
                          get_comm_order_req_rank(cotype.rank,
                                                  pk_workflow.get_status_rank(i_lang,
                                                                              i_prof,
                                                                              cor.id_workflow,
                                                                              cor.id_status,
                                                                              l_id_category,
                                                                              l_id_profile_template,
                                                                              NULL,
                                                                              table_varchar()),
                                                  pk_sysdomain.get_rank(i_lang, g_code_priority, cor.flg_priority)),
                          upper(get_comm_order_title(i_lang                     => i_lang,
                                                     i_prof                     => i_prof,
                                                     i_concept_type             => cor.id_concept_type,
                                                     i_concept_term             => cor.id_concept_term,
                                                     i_cncpt_trm_inst_owner     => cor.id_cncpt_trm_inst_owner,
                                                     i_concept_version          => cor.id_concept_version,
                                                     i_cncpt_vrs_inst_owner     => cor.id_cncpt_vrs_inst_owner,
                                                     i_flg_free_text            => cor.flg_free_text,
                                                     i_desc_concept_term        => pk_translation.get_translation_trs(cor.desc_concept_term),
                                                     i_task_type                => cor.id_task_type,
                                                     i_flg_show_comm_order_type => pk_alert_constant.g_yes,
                                                     i_flg_trunc_clobs          => pk_alert_constant.g_yes)),
                          -- sorting fields of the same comm_order_req
                          t.rank,
                          t.dt_detail,
                          t.field_rank;
        ELSE
            -- open cursor with data
            g_error := 'OPEN o_detail_info FOR ';
            OPEN o_detail_info FOR
                SELECT /*+opt_estimate (table t rows=1)*/
                 t.id_comm_order_req,
                 t.id_section,
                 t.header_1,
                 t.header_2,
                 t.field_code,
                 t.field_name,
                 t.field_value,
                 t.field_style,
                 t.signature
                  FROM TABLE(CAST(l_info_tab AS t_coll_comm_order_req_det)) t
                  JOIN comm_order_req cor
                    ON (cor.id_comm_order_req = t.id_comm_order_req)
                  JOIN comm_order_type cotype
                    ON cor.id_concept_type = cotype.id_comm_order_type
                   AND cotype.id_task_type = cor.id_task_type
                 ORDER BY -- sorting communication order reqs
                          get_comm_order_req_rank(cotype.rank,
                                                  pk_workflow.get_status_rank(i_lang,
                                                                              i_prof,
                                                                              cor.id_workflow,
                                                                              cor.id_status,
                                                                              l_id_category,
                                                                              l_id_profile_template,
                                                                              NULL,
                                                                              table_varchar()),
                                                  pk_sysdomain.get_rank(i_lang, g_code_priority, cor.flg_priority)),
                          upper(get_comm_order_title(i_lang                     => i_lang,
                                                     i_prof                     => i_prof,
                                                     i_concept_type             => cor.id_concept_type,
                                                     i_concept_term             => cor.id_concept_term,
                                                     i_cncpt_trm_inst_owner     => cor.id_cncpt_trm_inst_owner,
                                                     i_concept_version          => cor.id_concept_version,
                                                     i_cncpt_vrs_inst_owner     => cor.id_cncpt_vrs_inst_owner,
                                                     i_flg_free_text            => cor.flg_free_text,
                                                     i_desc_concept_term        => pk_translation.get_translation_trs(cor.desc_concept_term),
                                                     i_task_type                => cor.id_task_type,
                                                     i_flg_show_comm_order_type => pk_alert_constant.g_yes,
                                                     i_flg_trunc_clobs          => pk_alert_constant.g_yes)),
                          -- sorting fields of the same comm_order_req
                          t.rank       DESC,
                          t.dt_detail  DESC,
                          t.field_rank;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_title_info);
            pk_types.open_my_cursor(o_detail_info);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_COMM_ORDER_REQ_DETAIL_REP',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_title_info);
            pk_types.open_my_cursor(o_detail_info);
            RETURN FALSE;
    END get_comm_order_req_detail_rep;

    FUNCTION get_comm_order_req_type
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_comm_order_req IN table_number,
        o_list              OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'OPEN o_list ';
        OPEN o_list FOR
            SELECT /*+opt_estimate (table t rows=1)*/
             cor.id_comm_order_req,
             cor.id_concept_type id_comm_order_type,
             pk_translation.get_translation(i_lang, cotype.code_icon) icon_comm_order_type,
             get_comm_order_type_desc(i_lang => i_lang, i_prof => i_prof, i_concept_type => cor.id_concept_type) desc_comm_order_type,
             get_comm_order_id(i_lang                    => i_lang,
                               i_prof                    => i_prof,
                               i_id_concept_version      => cor.id_concept_version,
                               i_id_cncpt_vrs_inst_owner => cor.id_cncpt_vrs_inst_owner,
                               i_id_concept_term         => cor.id_concept_term,
                               i_id_cncpt_trm_inst_owner => cor.id_cncpt_trm_inst_owner) id_comm_order,
             get_comm_order_title(i_lang                 => i_lang,
                                  i_prof                 => i_prof,
                                  i_concept_type         => cor.id_concept_type,
                                  i_concept_term         => cor.id_concept_term,
                                  i_cncpt_trm_inst_owner => cor.id_cncpt_trm_inst_owner,
                                  i_concept_version      => cor.id_concept_version,
                                  i_cncpt_vrs_inst_owner => cor.id_cncpt_vrs_inst_owner,
                                  i_flg_free_text        => cor.flg_free_text,
                                  i_desc_concept_term    => pk_translation.get_translation_trs(cor.desc_concept_term),
                                  i_task_type            => cor.id_task_type,
                                  i_flg_trunc_clobs      => pk_alert_constant.g_no) desc_comm_order,
             cor.flg_free_text
              FROM comm_order_req cor
              JOIN comm_order_type cotype
                ON cor.id_concept_type = cotype.id_comm_order_type
               AND cor.id_task_type = cotype.id_task_type
              JOIN TABLE(CAST(i_id_comm_order_req AS table_number)) t
                ON (cor.id_comm_order_req = t.column_value);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_COMM_ORDER_REQ_TYPE',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_comm_order_req_type;

    FUNCTION set_flg_need_ack
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_flg_category  IN category.flg_type%TYPE,
        i_id_status     IN comm_order_req.id_status%TYPE,
        i_value         IN comm_order_req.flg_need_ack%TYPE,
        io_flg_need_ack IN OUT comm_order_req.flg_need_ack%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF i_id_status IN (g_id_sts_draft, g_id_sts_predf)
        THEN
            io_flg_need_ack := pk_alert_constant.g_no;
        ELSE
            g_error := 'Other status than draft ';
            IF i_value = pk_alert_constant.g_yes
            THEN
                -- someone has changed the comm order req... ack only needed if the professional is not the nurse
                IF i_flg_category = pk_alert_constant.g_cat_type_nurse
                THEN
                    io_flg_need_ack := pk_alert_constant.g_no;
                ELSE
                    -- io_flg_need_ack is null if comm order is being created
                    io_flg_need_ack := pk_alert_constant.g_yes;
                END IF;
            
            ELSIF i_value = pk_alert_constant.g_no
            THEN
                -- someone has acknowledge/copy the comm order req... reset flag only if the professional is a nurse
                IF i_flg_category = pk_alert_constant.g_cat_type_nurse
                THEN
                    io_flg_need_ack := pk_alert_constant.g_no;
                ELSE
                    -- io_flg_need_ack is null if comm order is being copied
                    io_flg_need_ack := nvl(io_flg_need_ack, pk_alert_constant.g_yes);
                END IF;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_FLG_NEED_ACK',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_flg_need_ack;

    FUNCTION set_last_cs_outdated
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_comm_order_req IN comm_order_req.id_comm_order_req%TYPE,
        i_id_episode        IN comm_order_req.id_episode%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_hist IS
            SELECT /*+opt_estimate (table t rows=1)*/
             a.id_comm_order_req_ack, t.id_co_sign
              FROM comm_order_req_hist h
              LEFT JOIN comm_order_req_ack a
                ON (a.id_comm_order_req_hist = h.id_comm_order_req_hist)
              LEFT JOIN TABLE(pk_co_sign_api.tf_co_sign_tasks_info(i_lang => i_lang, i_prof => i_prof, i_episode => i_id_episode, i_task_type => pk_alert_constant.g_task_comm_orders)) t
                ON (t.id_task = h.id_comm_order_req_hist AND
                   t.flg_status IN (pk_co_sign_api.g_cosign_flg_status_p,
                                     pk_co_sign_api.g_cosign_flg_status_na,
                                     pk_co_sign_api.g_cosign_flg_status_d)) -- only pending/NA and draft co-signs 
             WHERE h.id_comm_order_req = i_id_comm_order_req
             ORDER BY h.dt_status DESC;
    
        TYPE t_coll_hist IS TABLE OF c_hist%ROWTYPE;
        l_coll_hist t_coll_hist;
    
        l_id_co_sign_hist co_sign_hist.id_co_sign_hist%TYPE;
    
    BEGIN
    
        -- check if there were any acknowledges since last comm order req update/creation
        -- if the professional does not need co-sign, than all co-signs without ack are implicitly validated (must be outdated)
        -- if the professional need co-sign, outdated all co-signs that were not acknowledged
        g_error := 'OPEN c_hist ';
        OPEN c_hist;
        FETCH c_hist BULK COLLECT
            INTO l_coll_hist;
        CLOSE c_hist;
    
        -- the most recent history record relates to the current action
        -- must validate from the record inserted before this action to the last record that was acknowledged
        -- cancel co-signs that are pending, within this period
        g_error := 'FOR i IN 1 .. ' || l_coll_hist.count;
        <<loop_hist>>
        FOR i IN 1 .. l_coll_hist.count
        LOOP
        
            g_error := 'l_coll_hist(' || i || ').id_comm_order_req_ack=' || l_coll_hist(i).id_comm_order_req_ack;
            IF l_coll_hist(i).id_comm_order_req_ack IS NOT NULL
            THEN
                EXIT loop_hist;
            ELSE
                -- there were no acknowledges done to this action, outdate this co-sign (if exists)
                IF l_coll_hist(i).id_co_sign IS NOT NULL
                THEN
                
                    g_error  := 'Call pk_co_sign_api.set_task_outdated / ID_CO_SIGN=' || l_coll_hist(i).id_co_sign;
                    g_retval := pk_co_sign_api.set_task_outdated(i_lang            => i_lang,
                                                                 i_prof            => i_prof,
                                                                 i_episode         => i_id_episode,
                                                                 i_id_co_sign      => l_coll_hist(i).id_co_sign,
                                                                 o_id_co_sign_hist => l_id_co_sign_hist,
                                                                 o_error           => o_error);
                
                    IF NOT g_retval
                    THEN
                        RAISE g_exception_np;
                    END IF;
                END IF;
            
            END IF;
        
        END LOOP loop_hist;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_LAST_CS_OUTDATED',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_last_cs_outdated;

    FUNCTION create_comm_order_req
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_workflow             IN comm_order_req.id_workflow%TYPE,
        i_id_status               IN comm_order_req.id_status%TYPE,
        i_id_patient              IN comm_order_req.id_patient%TYPE,
        i_id_episode              IN comm_order_req.id_episode%TYPE,
        i_id_comm_order           IN table_number,
        i_id_comm_order_type      IN table_number,
        i_flg_free_text           IN table_varchar,
        i_desc_comm_order         IN table_clob,
        i_notes                   IN table_clob,
        i_clinical_indication     IN table_clob,
        i_flg_clinical_purpose    IN table_varchar,
        i_clinical_purpose_desc   IN table_varchar,
        i_flg_priority            IN table_varchar,
        i_flg_prn                 IN table_varchar,
        i_prn_condition           IN table_clob,
        i_dt_begin_str            IN table_varchar,
        i_dt_order_str            IN table_varchar,
        i_id_prof_order           IN table_number,
        i_id_order_type           IN table_number,
        i_task_duration           IN table_number,
        i_order_recurr            IN table_number,
        i_clinical_question       IN table_table_number, --30
        i_response                IN table_table_varchar,
        i_clinical_question_notes IN table_table_varchar,
        i_task_type               IN NUMBER DEFAULT NULL,
        o_id_comm_order_req       OUT table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_sysdate            TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_comm_order_req_row t_rec_comm_order_req := t_rec_comm_order_req();
        l_id_hist            comm_order_req_hist.id_comm_order_req_hist%TYPE;
        l_rowids             table_varchar;
        l_prof_cat           category.flg_type%TYPE;
        -- co_sign
        l_id_co_sign      co_sign.id_co_sign%TYPE;
        l_id_co_sign_hist co_sign_hist.id_co_sign_hist%TYPE;
    
        l_order_recurrence         order_recurr_plan.id_order_recurr_plan%TYPE;
        l_order_recurrence_option  order_recurr_plan.id_order_recurr_option%TYPE;
        l_order_recurr_final_array table_number := table_number();
    
        l_clinical_question       table_number := table_number();
        l_response                table_varchar := table_varchar();
        l_clinical_question_notes table_varchar := table_varchar();
    
        TYPE t_order_recurr_plan_map IS TABLE OF NUMBER INDEX BY VARCHAR2(200 CHAR);
        ibt_order_recurr_plan_map t_order_recurr_plan_map;
    
        l_aux table_varchar2;
    
        l_next_plan           interv_presc_plan.id_interv_presc_plan%TYPE;
        l_status_plan         interv_presc_plan.flg_status%TYPE;
        l_order_recurr_option order_recurr_option.id_order_recurr_option%TYPE;
        l_rows_out            table_varchar := table_varchar();
    
    BEGIN
    
        l_sysdate := current_timestamp;
    
        o_id_comm_order_req := table_number();
        o_id_comm_order_req.extend(i_id_comm_order.count);
    
        l_prof_cat := pk_prof_utils.get_category(i_lang, i_prof);
    
        -- val
        IF i_id_comm_order.count != i_flg_free_text.count
           AND i_id_comm_order.count != i_id_comm_order_type.count
           AND i_id_comm_order.count != i_desc_comm_order.count
           AND i_id_comm_order.count != i_notes.count
           AND i_id_comm_order.count != i_clinical_indication.count
           AND i_id_comm_order.count != i_flg_clinical_purpose.count
           AND i_id_comm_order.count != i_clinical_purpose_desc.count
           AND i_id_comm_order.count != i_flg_priority.count
           AND i_id_comm_order.count != i_flg_prn.count
           AND i_id_comm_order.count != i_prn_condition.count
           AND i_id_comm_order.count != i_dt_begin_str.count
           AND i_id_comm_order.count != i_dt_order_str.count
           AND i_id_comm_order.count != i_id_prof_order.count
           AND i_id_comm_order.count != i_id_order_type.count
           AND i_id_comm_order.count != i_task_duration.count
           AND i_id_comm_order.count != i_order_recurr.count
        THEN
            g_error := 'Invalid parameters ';
            RAISE g_exception;
        END IF;
    
        FOR i IN 1 .. i_id_comm_order.count
        LOOP
        
            IF i_order_recurr(i) IS NOT NULL
            THEN
                BEGIN
                    l_order_recurrence := ibt_order_recurr_plan_map(i_order_recurr(i));
                EXCEPTION
                    WHEN no_data_found THEN
                    
                        -- set order recurrence plan as finished or cancel plan (order_recurr_option - 0 OR -2 ---- order_recurr_area NOT IN (7,8,9)
                        g_error := 'CALL PK_ORDER_RECURRENCE_API_DB.SET_ORDER_RECURR_PLAN';
                        IF NOT pk_order_recurrence_api_db.set_order_recurr_plan(i_lang                    => i_lang,
                                                                                i_prof                    => i_prof,
                                                                                i_order_recurr_plan       => i_order_recurr(i),
                                                                                o_order_recurr_option     => l_order_recurrence_option,
                                                                                o_final_order_recurr_plan => l_order_recurrence,
                                                                                o_error                   => o_error)
                        THEN
                            RAISE g_exception;
                        END IF;
                    
                        -- add new order recurrence plan to map collection
                        ibt_order_recurr_plan_map(i_order_recurr(i)) := l_order_recurrence;
                    
                        IF l_order_recurrence IS NOT NULL
                        THEN
                            l_order_recurr_final_array.extend;
                            l_order_recurr_final_array(l_order_recurr_final_array.count) := l_order_recurrence;
                        END IF;
                END;
            END IF;
        
            l_clinical_question := table_number();
            IF i_clinical_question.count > 0
               AND i_clinical_question(i).count > 0
            THEN
                FOR j IN i_clinical_question(i).first .. i_clinical_question(i).last
                LOOP
                    l_clinical_question.extend;
                    l_clinical_question(j) := i_clinical_question(i) (j);
                END LOOP;
            END IF;
        
            l_response := table_varchar();
            IF i_response.count > 0
               AND i_response(i).count > 0
            THEN
                FOR j IN i_response(i).first .. i_response(i).last
                LOOP
                    l_response.extend;
                    l_response(j) := i_response(i) (j);
                END LOOP;
            END IF;
        
            l_clinical_question_notes := table_varchar();
            IF i_clinical_question_notes.count > 0
               AND i_clinical_question_notes(i).count > 0
            THEN
                FOR j IN i_clinical_question_notes(i).first .. i_clinical_question_notes(i).last
                LOOP
                    l_clinical_question_notes.extend;
                    l_clinical_question_notes(j) := i_clinical_question_notes(i) (j);
                END LOOP;
            END IF;
        
            l_comm_order_req_row := t_rec_comm_order_req();
        
            g_error := 'create ';
            -- mandatory parameters
            IF i_flg_free_text(i) IS NULL
               OR i_flg_priority(i) IS NULL
               OR i_flg_prn(i) IS NULL
            THEN
                g_error := 'Invalid parameters ';
                RAISE g_exception;
            END IF;
        
            IF i_flg_free_text(i) = pk_alert_constant.g_yes
               AND TRIM(i_desc_comm_order(i)) IS NULL
            THEN
                g_error := 'Description cannot be null ';
                RAISE g_exception;
            ELSIF i_flg_free_text(i) = pk_alert_constant.g_no
            THEN
                -- convert hash key
                g_error  := 'Call get_comm_order_key ';
                g_retval := get_comm_order_key(i_lang                    => i_lang,
                                               i_prof                    => i_prof,
                                               i_id_comm_order           => i_id_comm_order(i),
                                               o_id_concept_version      => l_comm_order_req_row.id_concept_version,
                                               o_id_cncpt_vrs_inst_owner => l_comm_order_req_row.id_cncpt_vrs_inst_owner,
                                               o_id_concept_term         => l_comm_order_req_row.id_concept_term,
                                               o_id_cncpt_trm_inst_owner => l_comm_order_req_row.id_cncpt_trm_inst_owner,
                                               o_error                   => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            END IF;
        
            IF i_flg_prn(i) = pk_alert_constant.g_no
               AND (i_prn_condition(i) IS NOT NULL AND length(i_prn_condition(i)) > 0)
            THEN
                g_error := 'PRN condition must be null / length=' || length(i_prn_condition(i));
                RAISE g_exception;
            END IF;
        
            -- set all values
            g_error                                 := 'Set vars ';
            l_comm_order_req_row.id_workflow        := i_id_workflow;
            l_comm_order_req_row.id_status := CASE
                                                  WHEN i_dt_begin_str(i) IS NULL THEN
                                                   pk_comm_orders.g_id_sts_predf
                                                  ELSE
                                                   i_id_status
                                              END;
            l_comm_order_req_row.id_previous_status := NULL;
            l_comm_order_req_row.id_patient         := i_id_patient;
            l_comm_order_req_row.id_episode         := i_id_episode;
            l_comm_order_req_row.id_concept_type    := i_id_comm_order_type(i);
            l_comm_order_req_row.flg_free_text      := i_flg_free_text(i);
        
            IF l_comm_order_req_row.flg_free_text = pk_alert_constant.g_yes
            THEN
                l_comm_order_req_row.desc_concept_term := i_desc_comm_order(i);
            END IF;
        
            l_comm_order_req_row.notes                := i_notes(i);
            l_comm_order_req_row.clinical_indication  := i_clinical_indication(i);
            l_comm_order_req_row.flg_clinical_purpose := nvl(i_flg_clinical_purpose(i), g_flg_clin_purpose_default);
        
            IF l_comm_order_req_row.flg_clinical_purpose = g_flg_clin_purpose_other
            THEN
                l_comm_order_req_row.clinical_purpose_desc := i_clinical_purpose_desc(i);
            END IF;
        
            l_comm_order_req_row.flg_priority    := i_flg_priority(i);
            l_comm_order_req_row.flg_prn         := i_flg_prn(i);
            l_comm_order_req_row.id_order_recurr := l_order_recurrence;
            l_comm_order_req_row.prn_condition   := i_prn_condition(i);
            l_comm_order_req_row.flg_action      := get_flg_action(i_lang             => i_lang,
                                                                   i_prof             => i_prof,
                                                                   i_id_status_actual => l_comm_order_req_row.id_status);
        
            g_error  := 'Call set_flg_need_ack ';
            g_retval := set_flg_need_ack(i_lang          => i_lang,
                                         i_prof          => i_prof,
                                         i_flg_category  => l_prof_cat,
                                         i_id_status     => l_comm_order_req_row.id_status,
                                         i_value         => pk_alert_constant.g_yes, -- needs to be acknowledge
                                         io_flg_need_ack => l_comm_order_req_row.flg_need_ack,
                                         o_error         => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            g_error                       := 'Convert to tstz ';
            l_comm_order_req_row.dt_begin := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_begin_str(i), NULL);
        
            g_error                                := 'Internal sets ';
            l_comm_order_req_row.id_prof_req       := i_prof.id;
            l_comm_order_req_row.id_inst_req       := i_prof.institution;
            l_comm_order_req_row.dt_req            := l_sysdate;
            l_comm_order_req_row.id_professional   := i_prof.id;
            l_comm_order_req_row.id_institution    := i_prof.institution;
            l_comm_order_req_row.dt_status         := l_sysdate;
            l_comm_order_req_row.id_comm_order_req := ts_comm_order_req.next_key();
            l_comm_order_req_row.task_duration     := i_task_duration(i);
            l_comm_order_req_row.id_task_type      := i_task_type;
        
            g_error := 'Call ts_comm_order_req.ins ';
            ts_comm_order_req.ins(id_comm_order_req_in       => l_comm_order_req_row.id_comm_order_req,
                                  id_workflow_in             => l_comm_order_req_row.id_workflow,
                                  id_status_in               => l_comm_order_req_row.id_status,
                                  id_patient_in              => l_comm_order_req_row.id_patient,
                                  id_episode_in              => l_comm_order_req_row.id_episode,
                                  id_concept_type_in         => l_comm_order_req_row.id_concept_type,
                                  id_concept_version_in      => l_comm_order_req_row.id_concept_version,
                                  id_cncpt_vrs_inst_owner_in => l_comm_order_req_row.id_cncpt_vrs_inst_owner,
                                  id_concept_term_in         => l_comm_order_req_row.id_concept_term,
                                  id_cncpt_trm_inst_owner_in => l_comm_order_req_row.id_cncpt_trm_inst_owner,
                                  flg_free_text_in           => l_comm_order_req_row.flg_free_text,
                                  id_prof_req_in             => l_comm_order_req_row.id_prof_req,
                                  id_inst_req_in             => l_comm_order_req_row.id_inst_req,
                                  dt_req_in                  => l_comm_order_req_row.dt_req,
                                  flg_clinical_purpose_in    => l_comm_order_req_row.flg_clinical_purpose,
                                  clinical_purpose_desc_in   => l_comm_order_req_row.clinical_purpose_desc,
                                  flg_priority_in            => l_comm_order_req_row.flg_priority,
                                  flg_prn_in                 => l_comm_order_req_row.flg_prn,
                                  dt_begin_in                => l_comm_order_req_row.dt_begin,
                                  id_professional_in         => l_comm_order_req_row.id_professional,
                                  id_institution_in          => l_comm_order_req_row.id_institution,
                                  dt_status_in               => l_comm_order_req_row.dt_status,
                                  id_cancel_reason_in        => l_comm_order_req_row.id_cancel_reason,
                                  flg_need_ack_in            => l_comm_order_req_row.flg_need_ack,
                                  flg_action_in              => l_comm_order_req_row.flg_action,
                                  id_previous_status_in      => l_comm_order_req_row.id_previous_status,
                                  id_order_recurr_in         => l_comm_order_req_row.id_order_recurr,
                                  task_duration_in           => l_comm_order_req_row.task_duration,
                                  id_task_type_in            => l_comm_order_req_row.id_task_type,
                                  rows_out                   => l_rowids);
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'COMM_ORDER_REQ',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            -- insert the remaining fields (translation_trs)            
            g_error := 'Call pk_translation.insert_translation_trs / ' || g_code_desc_concept_term ||
                       l_comm_order_req_row.id_comm_order_req;
            pk_translation.insert_translation_trs(i_lang   => i_lang,
                                                  i_code   => g_code_desc_concept_term ||
                                                              l_comm_order_req_row.id_comm_order_req,
                                                  i_desc   => l_comm_order_req_row.desc_concept_term,
                                                  i_module => 'COMM_ORDER_REQ');
        
            g_error := 'Call pk_translation.insert_translation_trs / ' || g_code_notes ||
                       l_comm_order_req_row.id_comm_order_req;
            pk_translation.insert_translation_trs(i_lang   => i_lang,
                                                  i_code   => g_code_notes || l_comm_order_req_row.id_comm_order_req,
                                                  i_desc   => l_comm_order_req_row.notes,
                                                  i_module => 'COMM_ORDER_REQ');
        
            g_error := 'Call pk_translation.insert_translation_trs / ' || g_code_clinical_indication ||
                       l_comm_order_req_row.id_comm_order_req;
            pk_translation.insert_translation_trs(i_lang   => i_lang,
                                                  i_code   => g_code_clinical_indication ||
                                                              l_comm_order_req_row.id_comm_order_req,
                                                  i_desc   => l_comm_order_req_row.clinical_indication,
                                                  i_module => 'COMM_ORDER_REQ');
        
            g_error := 'Call pk_translation.insert_translation_trs / ' || g_code_prn_condition ||
                       l_comm_order_req_row.id_comm_order_req;
            pk_translation.insert_translation_trs(i_lang   => i_lang,
                                                  i_code   => g_code_prn_condition ||
                                                              l_comm_order_req_row.id_comm_order_req,
                                                  i_desc   => l_comm_order_req_row.prn_condition,
                                                  i_module => 'COMM_ORDER_REQ');
        
            -- create hist data
            g_error  := 'Call set_comm_order_req_h ';
            g_retval := set_comm_order_req_h(i_lang               => i_lang,
                                             i_prof               => i_prof,
                                             i_comm_order_req_row => l_comm_order_req_row,
                                             o_id_hist            => l_id_hist,
                                             o_error              => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            g_error := 'i_id_order_type(i)=' || i_id_order_type(i);
            IF i_id_order_type(i) IS NOT NULL
            THEN
            
                -- create co-sign data
                IF l_comm_order_req_row.id_status = g_id_sts_draft
                THEN
                    -- create draft co-sign (add action)
                    g_error  := 'Call pk_co_sign_api.set_draft_co_sign_task ';
                    g_retval := pk_co_sign_api.set_draft_co_sign_task(i_lang               => i_lang,
                                                                      i_prof               => i_prof,
                                                                      i_episode            => l_comm_order_req_row.id_episode,
                                                                      i_id_task_type       => i_task_type,
                                                                      i_id_task            => l_id_hist,
                                                                      i_id_task_group      => l_comm_order_req_row.id_comm_order_req,
                                                                      i_id_order_type      => i_id_order_type(i),
                                                                      i_id_prof_created    => i_prof.id,
                                                                      i_id_prof_ordered_by => i_id_prof_order(i),
                                                                      i_dt_created         => l_comm_order_req_row.dt_status,
                                                                      i_dt_ordered_by      => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                            i_prof,
                                                                                                                            i_dt_order_str(i),
                                                                                                                            NULL),
                                                                      o_id_co_sign         => l_id_co_sign,
                                                                      o_id_co_sign_hist    => l_id_co_sign_hist,
                                                                      o_error              => o_error);
                
                    IF NOT g_retval
                    THEN
                        RAISE g_exception_np;
                    END IF;
                
                ELSE
                
                    -- create pending co-sign (add action)
                    g_error  := 'Call pk_co_sign_api.set_pending_co_sign_task ';
                    g_retval := pk_co_sign_api.set_pending_co_sign_task(i_lang               => i_lang,
                                                                        i_prof               => i_prof,
                                                                        i_episode            => l_comm_order_req_row.id_episode,
                                                                        i_id_task_type       => i_task_type,
                                                                        i_id_action          => g_cs_action_add,
                                                                        i_id_task            => l_id_hist,
                                                                        i_id_task_group      => l_comm_order_req_row.id_comm_order_req,
                                                                        i_id_order_type      => i_id_order_type(i),
                                                                        i_id_prof_created    => i_prof.id,
                                                                        i_id_prof_ordered_by => i_id_prof_order(i),
                                                                        i_dt_created         => l_comm_order_req_row.dt_status,
                                                                        i_dt_ordered_by      => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                              i_prof,
                                                                                                                              i_dt_order_str(i),
                                                                                                                              NULL),
                                                                        o_id_co_sign         => l_id_co_sign,
                                                                        o_id_co_sign_hist    => l_id_co_sign_hist,
                                                                        o_error              => o_error);
                
                    IF NOT g_retval
                    THEN
                        RAISE g_exception_np;
                    END IF;
                END IF;
            
            END IF;
        
            IF l_clinical_question.count != 0
            THEN
                FOR i IN 1 .. l_clinical_question.count
                LOOP
                    IF l_clinical_question(i) IS NOT NULL
                    THEN
                        IF l_response(i) IS NOT NULL
                        THEN
                            l_aux := pk_utils.str_split(l_response(i), '|');
                        
                            FOR j IN 1 .. l_aux.count
                            LOOP
                                g_error := 'INSERT INTO INTERV_QUESTION_RESPONSE';
                                INSERT INTO comm_order_question_response
                                    (id_comm_order_question_resp,
                                     id_episode,
                                     id_common_order_req,
                                     flg_time,
                                     id_questionnaire,
                                     id_response,
                                     notes,
                                     id_prof_last_update,
                                     dt_last_update_tstz)
                                VALUES
                                    (seq_comm_order_question_resp.nextval,
                                     i_id_episode,
                                     l_comm_order_req_row.id_comm_order_req,
                                     pk_procedures_constant.g_interv_cq_on_order,
                                     l_clinical_question(i),
                                     to_number(l_aux(j)),
                                     l_clinical_question_notes(i),
                                     i_prof.id,
                                     l_sysdate);
                            END LOOP;
                        ELSE
                            g_error := 'INSERT INTO INTERV_QUESTION_RESPONSE';
                            INSERT INTO comm_order_question_response
                                (id_comm_order_question_resp,
                                 id_episode,
                                 id_common_order_req,
                                 flg_time,
                                 id_questionnaire,
                                 id_response,
                                 notes,
                                 id_prof_last_update,
                                 dt_last_update_tstz)
                            VALUES
                                (seq_comm_order_question_resp.nextval,
                                 i_id_episode,
                                 l_comm_order_req_row.id_comm_order_req,
                                 pk_procedures_constant.g_interv_cq_on_order,
                                 l_clinical_question(i),
                                 NULL,
                                 l_clinical_question_notes(i),
                                 i_prof.id,
                                 l_sysdate);
                        END IF;
                    END IF;
                END LOOP;
            END IF;
        
            /*IF i_flg_prn(i) = pk_procedures_constant.g_no
               OR i_flg_prn(i) IS NULL
            THEN*/
            BEGIN
                l_order_recurr_option := pk_order_recurrence_api_db.get_recurr_order_option(i_lang              => i_lang,
                                                                                            i_prof              => i_prof,
                                                                                            i_order_recurr_plan => l_comm_order_req_row.id_order_recurr);
            EXCEPTION
                WHEN OTHERS THEN
                    l_order_recurr_option := NULL;
            END;
        
            g_error     := 'GET NEXT_KEY';
            l_next_plan := seq_comm_order_plan.nextval;
        
            l_status_plan := 'R';
        
            l_rows_out := NULL;
        
            g_error := 'INSERT INTERV_PRESC_PLAN';
            ts_comm_order_plan.ins(id_comm_order_plan_in => l_next_plan,
                                   id_comm_order_req_in  => l_comm_order_req_row.id_comm_order_req,
                                   flg_status_in         => l_status_plan,
                                   dt_plan_tstz_in       => CASE l_order_recurr_option
                                                                WHEN -2 THEN
                                                                 NULL
                                                                ELSE
                                                                 nvl(pk_date_utils.get_string_tstz(i_lang,
                                                                                                   i_prof,
                                                                                                   i_dt_begin_str(i),
                                                                                                   NULL),
                                                                     l_sysdate)
                                                            END,
                                   exec_number_in        => 1,
                                   rows_out              => l_rows_out);
        
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'COMM_ORDER_PLAN',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            --END IF;
        
            g_error := 'ID=' || l_comm_order_req_row.id_comm_order_req;
            o_id_comm_order_req(i) := l_comm_order_req_row.id_comm_order_req;
        
            IF i_id_status NOT IN (g_id_sts_predf, g_id_sts_draft)
               AND i_id_episode IS NOT NULL
            THEN
            
                g_error := 'Call t_ti_log.ins_log ';
                IF NOT t_ti_log.ins_log(i_lang       => i_lang,
                                        i_prof       => i_prof,
                                        i_id_episode => i_id_episode,
                                        i_flg_status => i_id_status,
                                        i_id_record  => l_comm_order_req_row.id_comm_order_req,
                                        i_flg_type   => pk_alert_constant.g_comm_order_req,
                                        o_error      => o_error)
                THEN
                    RAISE g_exception_np;
                END IF;
            
            END IF;
        
            IF l_order_recurr_final_array IS NOT NULL
               OR l_order_recurr_final_array.count > 0
            THEN
                g_error := 'CALL PK_ORDER_RECURRENCE_API_DB.PREPARE_ORDER_RECURR_PLAN';
                IF NOT pk_order_recurrence_api_db.prepare_order_recurr_plan(i_lang       => i_lang,
                                                                            i_prof       => i_prof,
                                                                            i_order_plan => l_order_recurr_final_array,
                                                                            o_error      => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            END IF;
        
        END LOOP;
    
        IF i_id_comm_order.count > 0
           AND i_id_status NOT IN (g_id_sts_predf, g_id_sts_draft)
        THEN
        
            g_error := 'Call pk_visit.set_first_obs ';
            IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                          i_id_episode          => i_id_episode,
                                          i_pat                 => i_id_patient,
                                          i_prof                => i_prof,
                                          i_prof_cat_type       => l_prof_cat,
                                          i_dt_last_interaction => l_sysdate,
                                          i_dt_first_obs        => l_sysdate,
                                          o_error               => o_error)
            THEN
                RAISE g_exception_np;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'CREATE_COMM_ORDER_REQ',
                                              o_error    => o_error);
            RETURN FALSE;
    END create_comm_order_req;

    FUNCTION create_comm_order_req_ong
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_patient              IN comm_order_req.id_patient%TYPE,
        i_id_episode              IN comm_order_req.id_episode%TYPE,
        i_id_comm_order           IN table_number,
        i_id_comm_order_type      IN table_number,
        i_flg_free_text           IN table_varchar,
        i_desc_comm_order         IN table_clob,
        i_notes                   IN table_clob,
        i_clinical_indication     IN table_clob,
        i_flg_clinical_purpose    IN table_varchar,
        i_clinical_purpose_desc   IN table_varchar,
        i_flg_priority            IN table_varchar,
        i_flg_prn                 IN table_varchar,
        i_prn_condition           IN table_clob,
        i_dt_begin_str            IN table_varchar,
        i_dt_order_str            IN table_varchar,
        i_id_prof_order           IN table_number,
        i_id_order_type           IN table_number,
        i_task_duration           IN table_number,
        i_order_recurr            IN table_number,
        i_clinical_question       IN table_table_number, --30
        i_response                IN table_table_varchar,
        i_clinical_question_notes IN table_table_varchar,
        i_task_type               IN NUMBER,
        o_id_comm_order_req       OUT table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_workflow comm_order_req.id_workflow%TYPE;
        l_id_status   comm_order_req.id_status%TYPE;
    
    BEGIN
    
        -- get status info
        l_id_workflow := g_id_workflow;
        l_id_status   := g_id_sts_ongoing;
    
        -- create 
        g_error  := 'Call create_comm_order_req ';
        g_retval := create_comm_order_req(i_lang                    => i_lang,
                                          i_prof                    => i_prof,
                                          i_id_workflow             => l_id_workflow,
                                          i_id_status               => l_id_status,
                                          i_id_patient              => i_id_patient,
                                          i_id_episode              => i_id_episode,
                                          i_id_comm_order           => i_id_comm_order,
                                          i_id_comm_order_type      => i_id_comm_order_type,
                                          i_flg_free_text           => i_flg_free_text,
                                          i_desc_comm_order         => i_desc_comm_order,
                                          i_notes                   => i_notes,
                                          i_clinical_indication     => i_clinical_indication,
                                          i_flg_clinical_purpose    => i_flg_clinical_purpose,
                                          i_clinical_purpose_desc   => i_clinical_purpose_desc,
                                          i_flg_priority            => i_flg_priority,
                                          i_flg_prn                 => i_flg_prn,
                                          i_prn_condition           => i_prn_condition,
                                          i_dt_begin_str            => i_dt_begin_str,
                                          i_dt_order_str            => i_dt_order_str,
                                          i_id_prof_order           => i_id_prof_order,
                                          i_id_order_type           => i_id_order_type,
                                          i_task_duration           => i_task_duration,
                                          i_order_recurr            => i_order_recurr,
                                          i_clinical_question       => i_clinical_question,
                                          i_response                => i_response,
                                          i_clinical_question_notes => i_clinical_question_notes,
                                          i_task_type               => i_task_type,
                                          o_id_comm_order_req       => o_id_comm_order_req,
                                          o_error                   => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := 'Synchronize with CPOE ';
        FOR i IN 1 .. o_id_comm_order_req.count
        LOOP
            IF i_id_episode IS NOT NULL
            THEN
                IF NOT pk_cpoe.sync_task(i_lang                 => i_lang,
                                         i_prof                 => i_prof,
                                         i_episode              => i_id_episode,
                                         i_task_type            => CASE
                                                                       WHEN i_task_type = pk_alert_constant.g_task_medical_orders THEN
                                                                        pk_alert_constant.g_task_type_med_order
                                                                       ELSE
                                                                        pk_alert_constant.g_task_type_com_order
                                                                   END,
                                         i_task_request         => o_id_comm_order_req(i),
                                         i_task_start_timestamp => pk_date_utils.get_string_tstz(i_lang,
                                                                                                 i_prof,
                                                                                                 i_dt_begin_str(i),
                                                                                                 NULL),
                                         o_error                => o_error)
                THEN
                    RAISE g_exception_np;
                END IF;
            END IF;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'CREATE_COMM_ORDER_REQ_ONG',
                                              o_error    => o_error);
            RETURN FALSE;
    END create_comm_order_req_ong;

    FUNCTION create_comm_order_req_draft
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_patient              IN comm_order_req.id_patient%TYPE,
        i_id_episode              IN comm_order_req.id_episode%TYPE,
        i_id_comm_order           IN table_number,
        i_id_comm_order_type      IN table_number,
        i_flg_free_text           IN table_varchar,
        i_desc_comm_order         IN table_clob,
        i_notes                   IN table_clob,
        i_clinical_indication     IN table_clob,
        i_flg_clinical_purpose    IN table_varchar,
        i_clinical_purpose_desc   IN table_varchar,
        i_flg_priority            IN table_varchar,
        i_flg_prn                 IN table_varchar,
        i_prn_condition           IN table_clob,
        i_dt_begin_str            IN table_varchar,
        i_dt_order_str            IN table_varchar,
        i_id_prof_order           IN table_number,
        i_id_order_type           IN table_number,
        i_task_duration           IN table_number,
        i_order_recurr            IN table_number,
        i_clinical_question       IN table_table_number,
        i_response                IN table_table_varchar,
        i_clinical_question_notes IN table_table_varchar,
        i_task_type               IN NUMBER,
        o_id_comm_order_req       OUT table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_workflow comm_order_req.id_workflow%TYPE;
        l_id_status   comm_order_req.id_status%TYPE;
    
        l_flg_profile     profile_template.flg_profile%TYPE;
        l_sys_alert_event sys_alert_event%ROWTYPE;
    
        l_dummy_n table_number := table_number();
    BEGIN
    
        l_dummy_n.extend(i_id_comm_order.count);
    
        l_flg_profile := nvl(pk_hand_off_core.get_flg_profile(i_lang, i_prof, NULL), '#');
    
        -- get status info
        l_id_workflow := g_id_workflow;
        l_id_status   := g_id_sts_draft;
    
        -- create 
        g_error  := 'Call create_comm_order_req ';
        g_retval := create_comm_order_req(i_lang                    => i_lang,
                                          i_prof                    => i_prof,
                                          i_id_workflow             => l_id_workflow,
                                          i_id_status               => l_id_status,
                                          i_id_patient              => i_id_patient,
                                          i_id_episode              => i_id_episode,
                                          i_id_comm_order           => i_id_comm_order,
                                          i_id_comm_order_type      => i_id_comm_order_type,
                                          i_flg_free_text           => i_flg_free_text,
                                          i_desc_comm_order         => i_desc_comm_order,
                                          i_notes                   => i_notes,
                                          i_clinical_indication     => i_clinical_indication,
                                          i_flg_clinical_purpose    => i_flg_clinical_purpose,
                                          i_clinical_purpose_desc   => i_clinical_purpose_desc,
                                          i_flg_priority            => i_flg_priority,
                                          i_flg_prn                 => i_flg_prn,
                                          i_prn_condition           => i_prn_condition,
                                          i_dt_begin_str            => i_dt_begin_str,
                                          i_dt_order_str            => i_dt_order_str,
                                          i_id_prof_order           => i_id_prof_order,
                                          i_id_order_type           => i_id_order_type,
                                          i_task_duration           => i_task_duration,
                                          i_order_recurr            => i_order_recurr,
                                          i_clinical_question       => i_clinical_question,
                                          i_response                => i_response,
                                          i_clinical_question_notes => i_clinical_question_notes,
                                          i_task_type               => i_task_type,
                                          o_id_comm_order_req       => o_id_comm_order_req,
                                          o_error                   => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_flg_profile = pk_prof_utils.g_flg_profile_template_student
        THEN
            l_sys_alert_event.id_sys_alert    := pk_alert_constant.g_alert_cpoe_draft;
            l_sys_alert_event.id_software     := i_prof.software;
            l_sys_alert_event.id_institution  := i_prof.institution;
            l_sys_alert_event.id_episode      := i_id_episode;
            l_sys_alert_event.id_patient      := i_id_patient;
            l_sys_alert_event.id_record       := i_id_episode;
            l_sys_alert_event.id_visit        := pk_visit.get_visit(i_episode => i_id_episode, o_error => o_error);
            l_sys_alert_event.dt_record       := current_timestamp;
            l_sys_alert_event.id_professional := pk_hand_off.get_episode_responsible(i_lang       => i_lang,
                                                                                     i_prof       => i_prof,
                                                                                     i_id_episode => i_id_episode,
                                                                                     o_error      => o_error);
        
            IF NOT pk_alerts.insert_sys_alert_event(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_sys_alert_event => l_sys_alert_event,
                                                    o_error           => o_error)
            THEN
                RAISE g_exception_np;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'CREATE_COMM_ORDER_REQ_DRAFT',
                                              o_error    => o_error);
            RETURN FALSE;
    END create_comm_order_req_draft;

    FUNCTION create_comm_order_req_predf
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_comm_order         IN table_number,
        i_id_comm_order_type    IN table_number,
        i_flg_free_text         IN table_varchar,
        i_desc_comm_order       IN table_clob,
        i_notes                 IN table_clob,
        i_clinical_indication   IN table_clob,
        i_flg_clinical_purpose  IN table_varchar,
        i_clinical_purpose_desc IN table_varchar,
        i_flg_priority          IN table_varchar,
        i_flg_prn               IN table_varchar,
        i_prn_condition         IN table_clob,
        o_id_comm_order_req     OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_workflow comm_order_req.id_workflow%TYPE;
        l_id_status   comm_order_req.id_status%TYPE;
        l_dummy_v     table_varchar := table_varchar();
        l_dummy_c     table_clob := table_clob();
        l_dummy_n     table_number := table_number();
    
    BEGIN
    
        -- init
        l_dummy_v.extend(i_id_comm_order.count);
        l_dummy_c.extend(i_id_comm_order.count);
        l_dummy_n.extend(i_id_comm_order.count);
    
        -- get status info
        l_id_workflow := g_id_workflow;
        l_id_status   := g_id_sts_predf;
    
        -- create 
        g_error  := 'Call create_comm_order_req ';
        g_retval := create_comm_order_req(i_lang                    => i_lang,
                                          i_prof                    => i_prof,
                                          i_id_workflow             => l_id_workflow,
                                          i_id_status               => l_id_status,
                                          i_id_patient              => NULL,
                                          i_id_episode              => NULL,
                                          i_id_comm_order           => i_id_comm_order,
                                          i_id_comm_order_type      => i_id_comm_order_type,
                                          i_flg_free_text           => i_flg_free_text,
                                          i_desc_comm_order         => i_desc_comm_order,
                                          i_notes                   => i_notes,
                                          i_clinical_indication     => i_clinical_indication,
                                          i_flg_clinical_purpose    => i_flg_clinical_purpose,
                                          i_clinical_purpose_desc   => i_clinical_purpose_desc,
                                          i_flg_priority            => i_flg_priority,
                                          i_flg_prn                 => i_flg_prn,
                                          i_prn_condition           => i_prn_condition,
                                          i_dt_begin_str            => l_dummy_v,
                                          i_dt_order_str            => l_dummy_v,
                                          i_id_prof_order           => l_dummy_n,
                                          i_id_order_type           => l_dummy_n,
                                          i_task_duration           => l_dummy_n,
                                          i_order_recurr            => l_dummy_n,
                                          i_clinical_question       => table_table_number(),
                                          i_response                => table_table_varchar(),
                                          i_clinical_question_notes => table_table_varchar(),
                                          o_id_comm_order_req       => o_id_comm_order_req,
                                          o_error                   => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'CREATE_COMM_ORDER_REQ_PREDF',
                                              o_error    => o_error);
            RETURN FALSE;
    END create_comm_order_req_predf;

    FUNCTION update_comm_order_req
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_episode                 IN episode.id_episode%TYPE DEFAULT NULL,
        i_id_comm_order_req       IN table_number,
        i_flg_free_text           IN table_varchar,
        i_desc_comm_order         IN table_clob,
        i_notes                   IN table_clob,
        i_clinical_indication     IN table_clob,
        i_flg_clinical_purpose    IN table_varchar,
        i_clinical_purpose_desc   IN table_varchar,
        i_flg_priority            IN table_varchar,
        i_flg_prn                 IN table_varchar,
        i_prn_condition           IN table_clob,
        i_dt_begin_str            IN table_varchar,
        i_dt_order_str            IN table_varchar,
        i_id_prof_order           IN table_number,
        i_id_order_type           IN table_number,
        i_task_duration           IN table_number,
        i_order_recurr            IN table_number,
        i_clinical_question       IN table_table_number,
        i_response                IN table_table_varchar,
        i_clinical_question_notes IN table_table_varchar,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'update_comm_order_req';
        l_params             VARCHAR2(1000 CHAR);
        l_params_int         VARCHAR2(1000 CHAR);
        l_sysdate            TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_row_tab            t_coll_comm_order_req;
        l_comm_order_req_row t_rec_comm_order_req;
        l_rowids             table_varchar;
        l_id_hist            comm_order_req_hist.id_comm_order_req_hist%TYPE;
        l_check_date         VARCHAR2(1 CHAR);
        l_dt_begin           comm_order_req.dt_begin%TYPE;
        l_prof_cat           category.flg_type%TYPE;
        -- co_sign
        l_id_co_sign      co_sign.id_co_sign%TYPE;
        l_id_co_sign_hist co_sign_hist.id_co_sign_hist%TYPE;
        --Clinical questions
        l_clinical_question       table_number := table_number();
        l_response                table_varchar := table_varchar();
        l_clinical_question_notes table_varchar := table_varchar();
        l_aux                     table_varchar2;
        l_comm_question_response  comm_order_question_response%ROWTYPE;
        l_count                   NUMBER := 0;
    
        l_order_recurrence        order_recurr_plan.id_order_recurr_plan%TYPE;
        l_order_recurrence_option order_recurr_plan.id_order_recurr_option%TYPE;
    
        l_id_task_type task_type.id_task_type%TYPE;
    
        l_id_comm_order_plan comm_order_plan.id_comm_order_plan%TYPE;
    
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof);
    
        -- init
        g_error := 'Init ' || l_func_name;
        IF g_debug
        THEN
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
        l_sysdate  := current_timestamp;
        l_prof_cat := pk_prof_utils.get_category(i_lang, i_prof);
    
        -- val
        IF i_id_comm_order_req.count != i_flg_free_text.count
           AND i_id_comm_order_req.count != i_desc_comm_order.count
           AND i_id_comm_order_req.count != i_notes.count
           AND i_id_comm_order_req.count != i_clinical_indication.count
           AND i_id_comm_order_req.count != i_flg_clinical_purpose.count
           AND i_id_comm_order_req.count != i_flg_priority.count
           AND i_id_comm_order_req.count != i_clinical_purpose_desc.count
           AND i_id_comm_order_req.count != i_flg_prn.count
           AND i_id_comm_order_req.count != i_prn_condition.count
           AND i_id_comm_order_req.count != i_dt_begin_str.count
           AND i_id_comm_order_req.count != i_dt_order_str.count
           AND i_id_comm_order_req.count != i_id_prof_order.count
           AND i_id_comm_order_req.count != i_id_order_type.count
        THEN
            g_error := 'Invalid parameters ';
            RAISE g_exception;
        END IF;
    
        -- getting existing values            
        g_error  := 'Call get_comm_order_req_rows ';
        g_retval := get_comm_order_req_rows(i_lang              => i_lang,
                                            i_prof              => i_prof,
                                            i_id_comm_order_req => i_id_comm_order_req,
                                            o_row_tab           => l_row_tab,
                                            o_error             => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- func    
        FOR i IN 1 .. l_row_tab.count
        LOOP
            l_params_int := 'i_id_comm_order_req=' || i_id_comm_order_req(i) || ' i_flg_free_text=' ||
                            i_flg_free_text(i) || ' i_flg_clinical_purpose=' || i_flg_clinical_purpose(i) ||
                            ' i_flg_priority=' || i_flg_priority(i) || ' i_flg_prn=' || i_flg_prn(i) ||
                            'i_dt_begin_str=' || i_dt_begin_str(i) || ' i_id_prof_order=' || i_id_prof_order(i) ||
                            ' i_id_order_type=' || i_id_order_type(i);
        
            l_comm_order_req_row := l_row_tab(i);
        
            g_error := 'create ';
            IF g_debug
            THEN
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            END IF;
        
            -- val
            IF i_flg_free_text(i) = pk_alert_constant.g_yes
               AND TRIM(i_desc_comm_order(i)) IS NULL
            THEN
                g_error := 'Description cannot be null ';
                RAISE g_exception;
            END IF;
        
            IF i_flg_prn(i) = pk_alert_constant.g_no
               AND (i_prn_condition(i) IS NOT NULL AND length(i_prn_condition(i)) > 0)
            THEN
                g_error := 'PRN condition must be null / length=' || length(i_prn_condition(i));
                RAISE g_exception;
            END IF;
        
            -- double check
            g_error := 'Double check communication orders request id / i_id_comm_order_req=' || i_id_comm_order_req(i) ||
                       ' / ' || ' i_flg_free_text(' || i || ')=' || i_flg_free_text(i) || ' FLG_FREE_TEXT=' ||
                       l_comm_order_req_row.flg_free_text;
            IF i_flg_free_text(i) != l_comm_order_req_row.flg_free_text
            THEN
                RAISE g_exception;
            END IF;
        
            g_error := 'Double check communication orders dt_begin / ID_STATUS=' || l_comm_order_req_row.id_status;
            IF l_comm_order_req_row.id_status NOT IN (g_id_sts_draft, g_id_sts_predf)
            THEN
            
                g_error      := 'Call pk_date_utils.compare_dates_tsz ';
                l_check_date := pk_date_utils.compare_dates_tsz(i_prof  => i_prof,
                                                                i_date1 => l_dt_begin,
                                                                i_date2 => l_comm_order_req_row.dt_begin);
            
                IF l_check_date != pk_alert_constant.g_date_equal
                THEN
                    g_error := 'Cannot update DT_BEGIN in state ' || l_comm_order_req_row.id_status || ' / ' ||
                               l_params;
                    RAISE g_exception;
                END IF;
            
            END IF;
        
            -- set all values
            g_error := 'Set vars ';
        
            IF l_comm_order_req_row.flg_free_text = pk_alert_constant.g_yes
            THEN
                l_comm_order_req_row.desc_concept_term := i_desc_comm_order(i);
            END IF;
        
            l_comm_order_req_row.notes                := i_notes(i);
            l_comm_order_req_row.clinical_indication  := i_clinical_indication(i);
            l_comm_order_req_row.flg_clinical_purpose := nvl(i_flg_clinical_purpose(i), g_flg_clin_purpose_default);
        
            IF l_comm_order_req_row.flg_clinical_purpose = g_flg_clin_purpose_other
            THEN
                l_comm_order_req_row.clinical_purpose_desc := i_clinical_purpose_desc(i);
            END IF;
        
            l_comm_order_req_row.flg_priority  := i_flg_priority(i);
            l_comm_order_req_row.flg_prn       := i_flg_prn(i);
            l_comm_order_req_row.prn_condition := i_prn_condition(i);
            l_comm_order_req_row.flg_action    := g_action_edition;
        
            g_error  := 'Call set_flg_need_ack ';
            g_retval := set_flg_need_ack(i_lang          => i_lang,
                                         i_prof          => i_prof,
                                         i_flg_category  => l_prof_cat,
                                         i_id_status     => l_comm_order_req_row.id_status,
                                         i_value         => pk_alert_constant.g_yes, -- needs to be acknowledge
                                         io_flg_need_ack => l_comm_order_req_row.flg_need_ack,
                                         o_error         => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            g_error                       := 'Convert to tstz ';
            l_dt_begin                    := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_begin_str(i), NULL);
            l_comm_order_req_row.dt_begin := l_dt_begin;
        
            g_error                              := 'Internal sets ';
            l_comm_order_req_row.id_professional := i_prof.id;
            l_comm_order_req_row.id_institution  := i_prof.institution;
            l_comm_order_req_row.dt_status       := l_sysdate;
            --  
            IF i_order_recurr.exists(i)
            THEN
                l_comm_order_req_row.id_order_recurr := i_order_recurr(i);
            ELSE
                l_comm_order_req_row.id_order_recurr := NULL;
            END IF;
            IF i_task_duration.exists(i)
            THEN
                l_comm_order_req_row.task_duration := i_task_duration(i);
            ELSE
                l_comm_order_req_row.task_duration := NULL;
            END IF;
            --
        
            IF l_comm_order_req_row.id_order_recurr IS NOT NULL
            THEN
                -- set order recurrence plan as finished or cancel plan (order_recurr_option - 0 OR -2 ---- order_recurr_area NOT IN (7,8,9)
                g_error := 'CALL PK_ORDER_RECURRENCE_API_DB.SET_ORDER_RECURR_PLAN';
                IF NOT pk_order_recurrence_api_db.set_order_recurr_plan(i_lang                    => i_lang,
                                                                        i_prof                    => i_prof,
                                                                        i_order_recurr_plan       => l_comm_order_req_row.id_order_recurr,
                                                                        o_order_recurr_option     => l_order_recurrence_option,
                                                                        o_final_order_recurr_plan => l_order_recurrence,
                                                                        o_error                   => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
                IF l_order_recurrence IS NOT NULL
                THEN
                    g_error := 'CALL PK_ORDER_RECURRENCE_API_DB.PREPARE_ORDER_RECURR_PLAN';
                    IF NOT pk_order_recurrence_api_db.prepare_order_recurr_plan(i_lang       => i_lang,
                                                                                i_prof       => i_prof,
                                                                                i_order_plan => table_number(l_order_recurrence),
                                                                                o_error      => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                END IF;
            END IF;
        
            -- update comm orders request
            g_error := 'Call ts_comm_order_req.upd ';
            ts_comm_order_req.upd(id_comm_order_req_in      => l_comm_order_req_row.id_comm_order_req,
                                  flg_clinical_purpose_in   => l_comm_order_req_row.flg_clinical_purpose,
                                  clinical_purpose_desc_in  => l_comm_order_req_row.clinical_purpose_desc,
                                  clinical_purpose_desc_nin => FALSE,
                                  flg_priority_in           => l_comm_order_req_row.flg_priority,
                                  flg_prn_in                => l_comm_order_req_row.flg_prn,
                                  dt_begin_in               => l_comm_order_req_row.dt_begin, -- do not update if null
                                  id_professional_in        => l_comm_order_req_row.id_professional,
                                  id_institution_in         => l_comm_order_req_row.id_institution,
                                  dt_status_in              => l_comm_order_req_row.dt_status,
                                  dt_last_update_tstz_in    => current_timestamp,
                                  flg_need_ack_in           => l_comm_order_req_row.flg_need_ack,
                                  flg_action_in             => l_comm_order_req_row.flg_action,
                                  id_order_recurr_in        => l_order_recurrence,
                                  id_order_recurr_nin       => FALSE,
                                  task_duration_in          => l_comm_order_req_row.task_duration,
                                  task_duration_nin         => FALSE,
                                  rows_out                  => l_rowids);
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'COMM_ORDER_REQ',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            -- update the remaining fields (translation_trs)
            g_error := 'Call pk_translation.insert_translation_trs / ' || g_code_desc_concept_term ||
                       l_comm_order_req_row.id_comm_order_req;
            pk_translation.insert_translation_trs(i_lang   => i_lang,
                                                  i_code   => g_code_desc_concept_term ||
                                                              l_comm_order_req_row.id_comm_order_req,
                                                  i_desc   => l_comm_order_req_row.desc_concept_term,
                                                  i_module => 'COMM_ORDER_REQ');
        
            g_error := 'Call pk_translation.insert_translation_trs / ' || g_code_notes ||
                       l_comm_order_req_row.id_comm_order_req;
            pk_translation.insert_translation_trs(i_lang   => i_lang,
                                                  i_code   => g_code_notes || l_comm_order_req_row.id_comm_order_req,
                                                  i_desc   => l_comm_order_req_row.notes,
                                                  i_module => 'COMM_ORDER_REQ');
        
            g_error := 'Call pk_translation.insert_translation_trs / ' || g_code_clinical_indication ||
                       l_comm_order_req_row.id_comm_order_req;
            pk_translation.insert_translation_trs(i_lang   => i_lang,
                                                  i_code   => g_code_clinical_indication ||
                                                              l_comm_order_req_row.id_comm_order_req,
                                                  i_desc   => l_comm_order_req_row.clinical_indication,
                                                  i_module => 'COMM_ORDER_REQ');
        
            g_error := 'Call pk_translation.insert_translation_trs / ' || g_code_prn_condition ||
                       l_comm_order_req_row.id_comm_order_req;
            pk_translation.insert_translation_trs(i_lang   => i_lang,
                                                  i_code   => g_code_prn_condition ||
                                                              l_comm_order_req_row.id_comm_order_req,
                                                  i_desc   => l_comm_order_req_row.prn_condition,
                                                  i_module => 'COMM_ORDER_REQ');
        
            -- must get comm orders req again
            g_error  := 'Call get_comm_order_req_row ';
            g_retval := get_comm_order_req_row(i_lang              => i_lang,
                                               i_prof              => i_prof,
                                               i_id_comm_order_req => l_comm_order_req_row.id_comm_order_req,
                                               o_row               => l_comm_order_req_row,
                                               o_error             => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            -- create hist data
            g_error  := 'Call set_comm_order_req_h ';
            g_retval := set_comm_order_req_h(i_lang               => i_lang,
                                             i_prof               => i_prof,
                                             i_comm_order_req_row => l_comm_order_req_row,
                                             o_id_hist            => l_id_hist,
                                             o_error              => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            -- co_sign data
            -- check if there were any acknowledges since last comm order req update/creation
            -- if the professional does not need co-sign, than all co-signs without ack are implicitly validated (must be outdated)
            -- if the professional need co-sign, outdated all co-signs that were not acknowledged
            g_error  := 'Call set_last_cs_outdated ';
            g_retval := set_last_cs_outdated(i_lang              => i_lang,
                                             i_prof              => i_prof,
                                             i_id_comm_order_req => l_comm_order_req_row.id_comm_order_req,
                                             i_id_episode        => l_comm_order_req_row.id_episode,
                                             o_error             => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            -- create co-sign if needed
            g_error := 'i_id_order_type(' || i || ')=' || i_id_order_type(i);
            IF i_id_order_type(i) IS NOT NULL
            THEN
            
                SELECT cor.id_task_type
                  INTO l_id_task_type
                  FROM comm_order_req cor
                 WHERE cor.id_comm_order_req = l_comm_order_req_row.id_comm_order_req;
            
                IF l_comm_order_req_row.id_status = g_id_sts_draft
                THEN
                    -- create draft co-sign (add action)
                    g_error  := 'Call pk_co_sign_api.set_draft_co_sign_task ';
                    g_retval := pk_co_sign_api.set_draft_co_sign_task(i_lang               => i_lang,
                                                                      i_prof               => i_prof,
                                                                      i_episode            => l_comm_order_req_row.id_episode,
                                                                      i_id_task_type       => l_id_task_type,
                                                                      i_id_task            => l_id_hist,
                                                                      i_id_task_group      => l_comm_order_req_row.id_comm_order_req,
                                                                      i_id_order_type      => i_id_order_type(i),
                                                                      i_id_prof_created    => i_prof.id,
                                                                      i_id_prof_ordered_by => i_id_prof_order(i),
                                                                      i_dt_created         => l_comm_order_req_row.dt_status,
                                                                      i_dt_ordered_by      => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                            i_prof,
                                                                                                                            i_dt_order_str(i),
                                                                                                                            NULL),
                                                                      o_id_co_sign         => l_id_co_sign,
                                                                      o_id_co_sign_hist    => l_id_co_sign_hist,
                                                                      o_error              => o_error);
                
                    IF NOT g_retval
                    THEN
                        RAISE g_exception_np;
                    END IF;
                
                ELSE
                
                    -- create pending co-sign (add action)                
                    g_error  := 'Call pk_co_sign_api.set_pending_co_sign_task ';
                    g_retval := pk_co_sign_api.set_pending_co_sign_task(i_lang               => i_lang,
                                                                        i_prof               => i_prof,
                                                                        i_episode            => l_comm_order_req_row.id_episode,
                                                                        i_id_task_type       => l_id_task_type,
                                                                        i_id_action          => g_cs_action_edit,
                                                                        i_id_task            => l_id_hist,
                                                                        i_id_task_group      => l_comm_order_req_row.id_comm_order_req,
                                                                        i_id_order_type      => i_id_order_type(i),
                                                                        i_id_prof_created    => i_prof.id,
                                                                        i_id_prof_ordered_by => i_id_prof_order(i),
                                                                        i_dt_created         => l_comm_order_req_row.dt_status,
                                                                        i_dt_ordered_by      => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                              i_prof,
                                                                                                                              i_dt_order_str(i),
                                                                                                                              NULL),
                                                                        o_id_co_sign         => l_id_co_sign,
                                                                        o_id_co_sign_hist    => l_id_co_sign_hist,
                                                                        o_error              => o_error);
                
                    IF NOT g_retval
                    THEN
                        RAISE g_exception_np;
                    END IF;
                END IF;
            END IF;
        
            -- check if set first obs function must be called
            IF l_comm_order_req_row.id_status NOT IN (g_id_sts_predf, g_id_sts_draft)
            THEN
            
                g_error := 'Call pk_visit.set_first_obs ';
                IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                              i_id_episode          => l_comm_order_req_row.id_episode,
                                              i_pat                 => l_comm_order_req_row.id_patient,
                                              i_prof                => i_prof,
                                              i_prof_cat_type       => l_prof_cat,
                                              i_dt_last_interaction => l_sysdate,
                                              i_dt_first_obs        => l_sysdate,
                                              o_error               => o_error)
                THEN
                    RAISE g_exception_np;
                END IF;
            
                g_error := 'Call t_ti_log.ins_log ';
                IF NOT t_ti_log.ins_log(i_lang       => i_lang,
                                        i_prof       => i_prof,
                                        i_id_episode => l_comm_order_req_row.id_episode,
                                        i_flg_status => l_comm_order_req_row.id_status,
                                        i_id_record  => l_comm_order_req_row.id_comm_order_req,
                                        i_flg_type   => pk_alert_constant.g_comm_order_req,
                                        o_error      => o_error)
                THEN
                    RAISE g_exception_np;
                END IF;
            
            END IF;
        
            BEGIN
                SELECT id_comm_order_plan
                  INTO l_id_comm_order_plan
                  FROM (SELECT cop.id_comm_order_plan
                          FROM comm_order_plan cop
                         WHERE cop.id_comm_order_req = l_comm_order_req_row.id_comm_order_req
                         ORDER BY cop.id_comm_order_plan DESC)
                 WHERE rownum = 1;
            EXCEPTION
                WHEN OTHERS THEN
                    l_id_comm_order_plan := NULL;
            END;
        
            IF l_id_comm_order_plan IS NOT NULL
            THEN
                ts_comm_order_plan.upd(id_comm_order_plan_in => l_id_comm_order_plan,
                                       dt_plan_tstz_in       => l_comm_order_req_row.dt_begin,
                                       rows_out              => l_rowids);
            
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'COMM_ORDER_PLAN',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            END IF;
        
            --Clinical questions
            g_error             := 'VALIDATE CLINICAL QUESTIONS';
            l_clinical_question := table_number();
            IF i_clinical_question(i).count > 0
                AND i_clinical_question(i) IS NOT NULL
            THEN
                FOR j IN i_clinical_question(i).first .. i_clinical_question(i).last
                LOOP
                    l_clinical_question.extend;
                    l_clinical_question(j) := i_clinical_question(i) (j);
                END LOOP;
            END IF;
        
            l_response := table_varchar();
            IF i_response(i).count > 0
                AND i_response(i) IS NOT NULL
            THEN
                FOR j IN i_response(i).first .. i_response(i).last
                LOOP
                    l_response.extend;
                    l_response(j) := i_response(i) (j);
                END LOOP;
            END IF;
        
            l_clinical_question_notes := table_varchar();
            IF i_clinical_question_notes(i).count > 0
                AND i_clinical_question_notes(i) IS NOT NULL
            THEN
                FOR j IN i_clinical_question_notes(i).first .. i_clinical_question_notes(i).last
                LOOP
                    l_clinical_question_notes.extend;
                    l_clinical_question_notes(j) := i_clinical_question_notes(i) (j);
                END LOOP;
            END IF;
        
            IF l_clinical_question.count != 0
            THEN
                FOR k IN 1 .. l_clinical_question.count
                LOOP
                    IF l_clinical_question(k) IS NOT NULL
                    THEN
                        IF l_response(k) IS NOT NULL
                        THEN
                            l_aux := pk_utils.str_split(l_response(k), '|');
                        
                            FOR j IN 1 .. l_aux.count
                            LOOP
                                SELECT COUNT(*)
                                  INTO l_count
                                  FROM (SELECT coqr.id_comm_order_question_resp,
                                               row_number() over(PARTITION BY coqr.id_questionnaire ORDER BY coqr.dt_last_update_tstz DESC NULLS FIRST) rn
                                          FROM comm_order_question_response coqr
                                         WHERE coqr.id_common_order_req = l_comm_order_req_row.id_comm_order_req
                                           AND coqr.id_questionnaire = l_clinical_question(k)
                                           AND (coqr.id_response = to_number(l_aux(j)) OR
                                               dbms_lob.substr(coqr.notes, 3800) = l_clinical_question_notes(k)))
                                 WHERE rn = 1;
                            
                                IF l_count = 0
                                THEN
                                    g_error := 'INSERT INTO COMM_ORDER_QUESTION_RESPONSE';
                                    INSERT INTO comm_order_question_response
                                        (id_comm_order_question_resp,
                                         id_common_order_req,
                                         id_questionnaire,
                                         id_response,
                                         notes,
                                         flg_time,
                                         id_episode,
                                         id_prof_last_update,
                                         dt_last_update_tstz)
                                    VALUES
                                        (seq_comm_order_question_resp.nextval,
                                         l_comm_order_req_row.id_comm_order_req,
                                         l_clinical_question(k),
                                         to_number(l_aux(j)),
                                         l_clinical_question_notes(k),
                                         pk_procedures_constant.g_interv_cq_on_order,
                                         i_episode,
                                         i_prof.id,
                                         l_sysdate);
                                ELSE
                                    SELECT id_comm_order_question_resp,
                                           id_common_order_req,
                                           id_questionnaire,
                                           id_response,
                                           notes,
                                           flg_time,
                                           id_episode,
                                           id_prof_last_update,
                                           dt_last_update_tstz,
                                           create_user,
                                           create_time,
                                           create_institution,
                                           update_user,
                                           update_time,
                                           update_institution
                                      INTO l_comm_question_response
                                      FROM (SELECT coqr.*,
                                                   row_number() over(PARTITION BY coqr.id_questionnaire ORDER BY coqr.dt_last_update_tstz DESC NULLS FIRST) rn
                                              FROM comm_order_question_response coqr
                                             WHERE coqr.id_common_order_req = l_comm_order_req_row.id_comm_order_req
                                               AND coqr.id_questionnaire = l_clinical_question(k)
                                               AND (coqr.id_response = to_number(l_aux(j)) OR
                                                   dbms_lob.substr(coqr.notes, 3800) = l_clinical_question_notes(k)))
                                     WHERE rn = 1;
                                
                                    g_error := 'INSERT INTO COMM_ORDER_QUESTION_RESPONSE_HIST';
                                    INSERT INTO comm_order_question_resp_hist
                                        (dt_comm_order_quest_resp_hist,
                                         id_comm_order_question_resp,
                                         id_episode,
                                         id_common_order_req,
                                         flg_time,
                                         id_questionnaire,
                                         id_response,
                                         notes,
                                         id_prof_last_update,
                                         dt_last_update_tstz)
                                    VALUES
                                        (l_sysdate,
                                         l_comm_question_response.id_comm_order_question_resp,
                                         l_comm_question_response.id_episode,
                                         l_comm_question_response.id_common_order_req,
                                         l_comm_question_response.flg_time,
                                         l_comm_question_response.id_questionnaire,
                                         l_comm_question_response.id_response,
                                         l_comm_question_response.notes,
                                         l_comm_question_response.id_prof_last_update,
                                         l_comm_question_response.dt_last_update_tstz);
                                
                                    g_error := 'INSERT INTO COMM_ORDER_QUESTION_RESPONSE';
                                    INSERT INTO comm_order_question_response
                                        (id_comm_order_question_resp,
                                         id_common_order_req,
                                         id_questionnaire,
                                         id_response,
                                         notes,
                                         flg_time,
                                         id_episode,
                                         id_prof_last_update,
                                         dt_last_update_tstz)
                                    VALUES
                                        (seq_comm_order_question_resp.nextval,
                                         l_comm_order_req_row.id_comm_order_req,
                                         l_clinical_question(k),
                                         to_number(l_aux(j)),
                                         l_clinical_question_notes(k),
                                         pk_procedures_constant.g_interv_cq_on_order,
                                         i_episode,
                                         i_prof.id,
                                         l_sysdate);
                                END IF;
                            END LOOP;
                        ELSE
                            SELECT COUNT(*)
                              INTO l_count
                              FROM (SELECT coqr.id_comm_order_question_resp,
                                           row_number() over(PARTITION BY coqr.id_questionnaire ORDER BY coqr.dt_last_update_tstz DESC NULLS FIRST) rn
                                      FROM comm_order_question_response coqr
                                     WHERE coqr.id_comm_order_question_resp = l_comm_order_req_row.id_comm_order_req
                                       AND coqr.id_questionnaire = l_clinical_question(k)
                                       AND (coqr.id_response IS NULL OR
                                           to_char(dbms_lob.substr(coqr.notes, 3800)) = l_clinical_question_notes(k)))
                             WHERE rn = 1;
                        
                            IF l_count = 0
                            THEN
                                g_error := 'INSERT INTO COMM_ORDER_QUESTION_RESPONSE';
                                INSERT INTO comm_order_question_response
                                    (id_comm_order_question_resp,
                                     id_common_order_req,
                                     id_questionnaire,
                                     id_response,
                                     notes,
                                     flg_time,
                                     id_episode,
                                     id_prof_last_update,
                                     dt_last_update_tstz)
                                VALUES
                                    (seq_comm_order_question_resp.nextval,
                                     l_comm_order_req_row.id_comm_order_req,
                                     l_clinical_question(k),
                                     NULL,
                                     l_clinical_question_notes(k),
                                     pk_procedures_constant.g_interv_cq_on_order,
                                     i_episode,
                                     i_prof.id,
                                     l_sysdate);
                            ELSE
                                SELECT id_comm_order_question_resp,
                                       id_common_order_req,
                                       id_questionnaire,
                                       id_response,
                                       notes,
                                       flg_time,
                                       id_episode,
                                       id_prof_last_update,
                                       dt_last_update_tstz,
                                       create_user,
                                       create_time,
                                       create_institution,
                                       update_user,
                                       update_time,
                                       update_institution
                                  INTO l_comm_question_response
                                  FROM (SELECT coqr.*,
                                               row_number() over(PARTITION BY coqr.id_questionnaire ORDER BY coqr.dt_last_update_tstz DESC NULLS FIRST) rn
                                          FROM comm_order_question_response coqr
                                         WHERE coqr.id_common_order_req = l_comm_order_req_row.id_comm_order_req
                                           AND coqr.id_questionnaire = l_clinical_question(k)
                                           AND (coqr.id_response IS NULL OR
                                               dbms_lob.substr(coqr.notes, 3800) = l_clinical_question_notes(k)))
                                 WHERE rn = 1;
                            
                                g_error := 'INSERT INTO COMM_ORDER_QUESTION_RESPONSE_HIST';
                                INSERT INTO comm_order_question_resp_hist
                                    (dt_comm_order_quest_resp_hist,
                                     id_comm_order_question_resp,
                                     id_episode,
                                     id_common_order_req,
                                     flg_time,
                                     id_questionnaire,
                                     id_response,
                                     notes,
                                     id_prof_last_update,
                                     dt_last_update_tstz)
                                VALUES
                                    (l_sysdate,
                                     l_comm_question_response.id_comm_order_question_resp,
                                     l_comm_question_response.id_episode,
                                     l_comm_question_response.id_common_order_req,
                                     l_comm_question_response.flg_time,
                                     l_comm_question_response.id_questionnaire,
                                     l_comm_question_response.id_response,
                                     l_comm_question_response.notes,
                                     l_comm_question_response.id_prof_last_update,
                                     l_comm_question_response.dt_last_update_tstz);
                            
                                g_error := 'INSERT INTO COMM_ORDER_QUESTION_RESPONSE';
                                INSERT INTO comm_order_question_response
                                    (id_comm_order_question_resp,
                                     id_common_order_req,
                                     id_questionnaire,
                                     id_response,
                                     notes,
                                     flg_time,
                                     id_episode,
                                     id_prof_last_update,
                                     dt_last_update_tstz)
                                VALUES
                                    (seq_comm_order_question_resp.nextval,
                                     l_comm_order_req_row.id_comm_order_req,
                                     l_clinical_question(k),
                                     NULL,
                                     l_clinical_question_notes(k),
                                     pk_procedures_constant.g_interv_cq_on_order,
                                     i_episode,
                                     i_prof.id,
                                     l_sysdate);
                            END IF;
                        END IF;
                    END IF;
                END LOOP;
            END IF;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'UPDATE_COMM_ORDER_REQ',
                                              o_error    => o_error);
            RETURN FALSE;
    END update_comm_order_req;

    FUNCTION update_comm_order_clin_ind
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_comm_order_req   IN table_number,
        i_clinical_indication IN pk_translation.t_lob_char,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_row_tab  t_coll_comm_order_req;
        l_rowids   table_varchar;
        l_id_hist  comm_order_req_hist.id_comm_order_req_hist%TYPE;
        l_sysdate  TIMESTAMP WITH LOCAL TIME ZONE;
        l_prof_cat category.flg_type%TYPE;
    
    BEGIN
    
        l_prof_cat := pk_prof_utils.get_category(i_lang, i_prof);
        l_sysdate  := current_timestamp;
    
        -- get comm order req data
        g_error  := 'Call get_commo_orders_req_rows ';
        g_retval := get_comm_order_req_rows(i_lang              => i_lang,
                                            i_prof              => i_prof,
                                            i_id_comm_order_req => i_id_comm_order_req,
                                            o_row_tab           => l_row_tab,
                                            o_error             => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := 'FOR i IN 1 .. ' || l_row_tab.count;
        FOR i IN 1 .. l_row_tab.count
        LOOP
        
            -- update comm order req data
            g_error := 'Set l_row_tab(i) / ID_COMM_ORDER_REQ=' || l_row_tab(i).id_comm_order_req;
            l_row_tab(i).clinical_indication := i_clinical_indication;
            l_row_tab(i).id_professional := i_prof.id;
            l_row_tab(i).id_institution := i_prof.institution;
            l_row_tab(i).dt_status := l_sysdate;
            l_row_tab(i).flg_action := g_action_edition;
        
            g_error  := 'Call set_flg_need_ack ';
            g_retval := set_flg_need_ack(i_lang          => i_lang,
                                         i_prof          => i_prof,
                                         i_flg_category  => l_prof_cat,
                                         i_id_status     => l_row_tab(i).id_status,
                                         i_value         => pk_alert_constant.g_yes, -- needs to be acknowledge
                                         io_flg_need_ack => l_row_tab(i).flg_need_ack,
                                         o_error         => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            -- update comm_order_req
            -- update to null if i_clinical_indication = NULL
            g_error := 'Call pk_translation.insert_translation_trs / ' || g_code_clinical_indication || l_row_tab(i).id_comm_order_req;
            pk_translation.insert_translation_trs(i_lang   => i_lang,
                                                  i_code   => g_code_clinical_indication || l_row_tab(i).id_comm_order_req,
                                                  i_desc   => l_row_tab(i).clinical_indication,
                                                  i_module => 'COMM_ORDER_REQ');
        
            ts_comm_order_req.upd(id_comm_order_req_in   => l_row_tab(i).id_comm_order_req,
                                  id_professional_in     => l_row_tab(i).id_professional,
                                  id_institution_in      => l_row_tab(i).id_institution,
                                  dt_status_in           => l_row_tab(i).dt_status,
                                  dt_last_update_tstz_in => current_timestamp,
                                  flg_need_ack_in        => l_row_tab(i).flg_need_ack,
                                  flg_action_in          => l_row_tab(i).flg_action,
                                  rows_out               => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'COMM_ORDER_REQ',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            -- create hist data
            g_error  := 'Call set_comm_order_req_h / ID_comm_order_REQ=' || l_row_tab(i).id_comm_order_req;
            g_retval := set_comm_order_req_h(i_lang               => i_lang,
                                             i_prof               => i_prof,
                                             i_comm_order_req_row => l_row_tab(i),
                                             o_id_hist            => l_id_hist,
                                             o_error              => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            -- check if set first obs function must be called
            IF l_row_tab(i).id_status NOT IN (g_id_sts_predf, g_id_sts_draft)
            THEN
            
                g_error := 'Call pk_visit.set_first_obs ';
                IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                              i_id_episode          => l_row_tab(i).id_episode,
                                              i_pat                 => l_row_tab(i).id_patient,
                                              i_prof                => i_prof,
                                              i_prof_cat_type       => l_prof_cat,
                                              i_dt_last_interaction => l_sysdate,
                                              i_dt_first_obs        => l_sysdate,
                                              o_error               => o_error)
                THEN
                    RAISE g_exception_np;
                END IF;
            
                g_error := 'Call t_ti_log.ins_log ';
                IF NOT t_ti_log.ins_log(i_lang       => i_lang,
                                        i_prof       => i_prof,
                                        i_id_episode => l_row_tab(i).id_episode,
                                        i_flg_status => l_row_tab(i).id_status,
                                        i_id_record  => l_row_tab(i).id_comm_order_req,
                                        i_flg_type   => pk_alert_constant.g_comm_order_req,
                                        o_error      => o_error)
                THEN
                    RAISE g_exception_np;
                END IF;
            END IF;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'UPDATE_COMM_ORDER_CLIN_IND',
                                              o_error    => o_error);
            RETURN FALSE;
    END update_comm_order_clin_ind;

    FUNCTION copy_comm_order_req
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_comm_order_req IN comm_order_req.id_comm_order_req%TYPE,
        i_id_status         IN comm_order_req.id_status%TYPE DEFAULT NULL,
        i_id_patient        IN comm_order_req.id_patient%TYPE DEFAULT NULL,
        i_id_episode        IN comm_order_req.id_episode%TYPE DEFAULT NULL,
        i_dt_begin          IN comm_order_req.dt_begin%TYPE DEFAULT NULL,
        i_task_type         IN comm_order_req.id_task_type%TYPE DEFAULT NULL,
        o_id_comm_order_req OUT comm_order_req.id_comm_order_req%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_comm_order_req_row t_rec_comm_order_req := t_rec_comm_order_req();
        l_sysdate            TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_id_hist            comm_order_req_hist.id_comm_order_req_hist%TYPE;
        l_rowids             table_varchar;
        l_prof_cat           category.flg_type%TYPE;
    
        l_order_recurr_desc   VARCHAR2(1000 CHAR);
        l_order_recurr_option order_recurr_plan.id_order_recurr_option%TYPE;
        l_start_date          order_recurr_plan.start_date%TYPE;
        l_occurrences         order_recurr_plan.occurrences%TYPE;
        l_duration            order_recurr_plan.duration%TYPE;
        l_unit_meas_duration  order_recurr_plan.id_unit_meas_duration%TYPE;
        l_duration_desc       VARCHAR2(1000 CHAR);
        l_end_date            order_recurr_plan.end_date%TYPE;
        l_flg_end_by_editable VARCHAR2(1 CHAR);
    
    BEGIN
    
        -- Note: do not copy the following information: 
        -- cancelling data (id_cancel_reason, notes_cancel)
    
        l_sysdate  := current_timestamp;
        l_prof_cat := pk_prof_utils.get_category(i_lang, i_prof);
    
        -- getting data to copy
        g_error  := 'Call get_comm_order_req_row ';
        g_retval := get_comm_order_req_row(i_lang              => i_lang,
                                           i_prof              => i_prof,
                                           i_id_comm_order_req => i_id_comm_order_req,
                                           o_row               => l_comm_order_req_row,
                                           o_error             => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_comm_order_req_row.id_order_recurr IS NOT NULL
        THEN
            -- copy order recurrence plan
            g_error := 'CALL PK_ORDER_RECURRENCE_API_DB.COPY_FROM_ORDER_RECURR_PLAN';
            IF NOT pk_order_recurrence_api_db.copy_from_order_recurr_plan(i_lang                   => i_lang,
                                                                          i_prof                   => i_prof,
                                                                          i_order_recurr_area      => NULL,
                                                                          i_order_recurr_plan_from => l_comm_order_req_row.id_order_recurr,
                                                                          i_flg_force_temp_plan    => pk_alert_constant.g_no,
                                                                          o_order_recurr_desc      => l_order_recurr_desc,
                                                                          o_order_recurr_option    => l_order_recurr_option,
                                                                          o_start_date             => l_start_date,
                                                                          o_occurrences            => l_occurrences,
                                                                          o_duration               => l_duration,
                                                                          o_unit_meas_duration     => l_unit_meas_duration,
                                                                          o_duration_desc          => l_duration_desc,
                                                                          o_end_date               => l_end_date,
                                                                          o_flg_end_by_editable    => l_flg_end_by_editable,
                                                                          o_order_recurr_plan      => l_comm_order_req_row.id_order_recurr,
                                                                          o_error                  => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        -- set vars to insert
        g_error                                 := 'set vars to insert ';
        l_comm_order_req_row.id_status          := nvl(i_id_status, l_comm_order_req_row.id_status);
        l_comm_order_req_row.id_previous_status := NULL;
        l_comm_order_req_row.id_patient         := nvl(i_id_patient, l_comm_order_req_row.id_patient);
        l_comm_order_req_row.id_episode         := nvl(i_id_episode, l_comm_order_req_row.id_episode);
        l_comm_order_req_row.dt_begin           := coalesce(i_dt_begin, l_start_date, current_timestamp);
        l_comm_order_req_row.id_prof_req        := i_prof.id;
        l_comm_order_req_row.id_inst_req        := i_prof.institution;
        l_comm_order_req_row.dt_req             := l_sysdate;
        l_comm_order_req_row.flg_action         := get_flg_action(i_lang             => i_lang,
                                                                  i_prof             => i_prof,
                                                                  i_id_status_actual => l_comm_order_req_row.id_status);
    
        -- acknowledge data must be reset
        g_error  := 'Call set_flg_need_ack ';
        g_retval := set_flg_need_ack(i_lang          => i_lang,
                                     i_prof          => i_prof,
                                     i_flg_category  => l_prof_cat,
                                     i_id_status     => l_comm_order_req_row.id_status,
                                     i_value         => pk_alert_constant.g_no, -- does not need to be acknowledge
                                     io_flg_need_ack => l_comm_order_req_row.flg_need_ack,
                                     o_error         => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- cancelling data
        g_error                               := 'cancelling data ';
        l_comm_order_req_row.id_cancel_reason := NULL;
        l_comm_order_req_row.notes_cancel     := NULL;
    
        g_error                              := 'Internal sets ';
        l_comm_order_req_row.id_professional := i_prof.id;
        l_comm_order_req_row.id_institution  := i_prof.institution;
        l_comm_order_req_row.dt_status       := l_sysdate;
    
        l_comm_order_req_row.id_comm_order_req := ts_comm_order_req.next_key();
    
        g_error := 'Call ts_comm_order_req.ins ';
        ts_comm_order_req.ins(id_comm_order_req_in       => l_comm_order_req_row.id_comm_order_req,
                              id_workflow_in             => l_comm_order_req_row.id_workflow,
                              id_status_in               => l_comm_order_req_row.id_status,
                              id_patient_in              => l_comm_order_req_row.id_patient,
                              id_episode_in              => l_comm_order_req_row.id_episode,
                              id_concept_type_in         => l_comm_order_req_row.id_concept_type,
                              id_concept_version_in      => l_comm_order_req_row.id_concept_version,
                              id_cncpt_vrs_inst_owner_in => l_comm_order_req_row.id_cncpt_vrs_inst_owner,
                              id_concept_term_in         => l_comm_order_req_row.id_concept_term,
                              id_cncpt_trm_inst_owner_in => l_comm_order_req_row.id_cncpt_trm_inst_owner,
                              flg_free_text_in           => l_comm_order_req_row.flg_free_text,
                              id_prof_req_in             => l_comm_order_req_row.id_prof_req,
                              id_inst_req_in             => l_comm_order_req_row.id_inst_req,
                              dt_req_in                  => l_comm_order_req_row.dt_req,
                              flg_clinical_purpose_in    => l_comm_order_req_row.flg_clinical_purpose,
                              clinical_purpose_desc_in   => l_comm_order_req_row.clinical_purpose_desc,
                              flg_priority_in            => l_comm_order_req_row.flg_priority,
                              flg_prn_in                 => l_comm_order_req_row.flg_prn,
                              dt_begin_in                => l_comm_order_req_row.dt_begin,
                              id_professional_in         => l_comm_order_req_row.id_professional,
                              id_institution_in          => l_comm_order_req_row.id_institution,
                              dt_status_in               => l_comm_order_req_row.dt_status,
                              flg_need_ack_in            => l_comm_order_req_row.flg_need_ack,
                              flg_action_in              => l_comm_order_req_row.flg_action,
                              id_previous_status_in      => l_comm_order_req_row.id_previous_status,
                              id_task_type_in            => l_comm_order_req_row.id_task_type,
                              rows_out                   => l_rowids);
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'COMM_ORDER_REQ',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        IF l_comm_order_req_row.flg_prn = pk_procedures_constant.g_no
        THEN
            BEGIN
                l_order_recurr_option := pk_order_recurrence_api_db.get_recurr_order_option(i_lang              => i_lang,
                                                                                            i_prof              => i_prof,
                                                                                            i_order_recurr_plan => l_comm_order_req_row.id_order_recurr);
            EXCEPTION
                WHEN OTHERS THEN
                    l_order_recurr_option := NULL;
            END;
        
            g_error := 'GET NEXT_KEY';
        
            l_rowids := NULL;
        
            g_error := 'INSERT INTERV_PRESC_PLAN';
            ts_comm_order_plan.ins(id_comm_order_plan_in => seq_comm_order_plan.nextval,
                                   id_comm_order_req_in  => l_comm_order_req_row.id_comm_order_req,
                                   flg_status_in         => 'R',
                                   dt_plan_tstz_in       => CASE l_order_recurr_option
                                                                WHEN -2 THEN
                                                                 NULL
                                                                ELSE
                                                                 nvl(pk_date_utils.get_string_tstz(i_lang,
                                                                                                   i_prof,
                                                                                                   l_comm_order_req_row.dt_begin,
                                                                                                   NULL),
                                                                     l_sysdate)
                                                            END,
                                   exec_number_in        => 1,
                                   rows_out              => l_rowids);
        
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'COMM_ORDER_PLAN',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
        END IF;
    
        -- insert the remaining fields (translation_trs)
        g_error := 'Call pk_translation.insert_translation_trs / ' || g_code_desc_concept_term ||
                   l_comm_order_req_row.id_comm_order_req;
        pk_translation.insert_translation_trs(i_lang   => i_lang,
                                              i_code   => g_code_desc_concept_term ||
                                                          l_comm_order_req_row.id_comm_order_req,
                                              i_desc   => l_comm_order_req_row.desc_concept_term,
                                              i_module => 'COMM_ORDER_REQ');
    
        g_error := 'Call pk_translation.insert_translation_trs / ' || g_code_notes ||
                   l_comm_order_req_row.id_comm_order_req;
        pk_translation.insert_translation_trs(i_lang   => i_lang,
                                              i_code   => g_code_notes || l_comm_order_req_row.id_comm_order_req,
                                              i_desc   => l_comm_order_req_row.notes,
                                              i_module => 'COMM_ORDER_REQ');
    
        g_error := 'Call pk_translation.insert_translation_trs / ' || g_code_clinical_indication ||
                   l_comm_order_req_row.id_comm_order_req;
        pk_translation.insert_translation_trs(i_lang   => i_lang,
                                              i_code   => g_code_clinical_indication ||
                                                          l_comm_order_req_row.id_comm_order_req,
                                              i_desc   => l_comm_order_req_row.clinical_indication,
                                              i_module => 'COMM_ORDER_REQ');
    
        g_error := 'Call pk_translation.insert_translation_trs / ' || g_code_prn_condition ||
                   l_comm_order_req_row.id_comm_order_req;
        pk_translation.insert_translation_trs(i_lang   => i_lang,
                                              i_code   => g_code_prn_condition || l_comm_order_req_row.id_comm_order_req,
                                              i_desc   => l_comm_order_req_row.prn_condition,
                                              i_module => 'COMM_ORDER_REQ');
    
        -- create hist data
        g_error  := 'Call set_comm_order_req_h ';
        g_retval := set_comm_order_req_h(i_lang               => i_lang,
                                         i_prof               => i_prof,
                                         i_comm_order_req_row => l_comm_order_req_row,
                                         o_id_hist            => l_id_hist,
                                         o_error              => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        o_id_comm_order_req := l_comm_order_req_row.id_comm_order_req;
    
        IF l_comm_order_req_row.id_status NOT IN (g_id_sts_predf, g_id_sts_draft)
        THEN
        
            g_error := 'Call pk_visit.set_first_obs ';
            IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                          i_id_episode          => l_comm_order_req_row.id_episode,
                                          i_pat                 => l_comm_order_req_row.id_patient,
                                          i_prof                => i_prof,
                                          i_prof_cat_type       => l_prof_cat,
                                          i_dt_last_interaction => l_sysdate,
                                          i_dt_first_obs        => l_sysdate,
                                          o_error               => o_error)
            THEN
                RAISE g_exception_np;
            END IF;
        
            g_error := 'Call t_ti_log.ins_log ';
            IF NOT t_ti_log.ins_log(i_lang       => i_lang,
                                    i_prof       => i_prof,
                                    i_id_episode => l_comm_order_req_row.id_episode,
                                    i_flg_status => l_comm_order_req_row.id_status,
                                    i_id_record  => l_comm_order_req_row.id_comm_order_req,
                                    i_flg_type   => pk_alert_constant.g_comm_order_req,
                                    o_error      => o_error)
            THEN
                RAISE g_exception_np;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'COPY_COMM_ORDER_REQ',
                                              o_error    => o_error);
            RETURN FALSE;
    END copy_comm_order_req;

    FUNCTION delete_comm_order_req
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_comm_order_req IN table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_count    PLS_INTEGER := 0;
        l_rowids   table_varchar;
        l_code_trs table_varchar;
        l_idx      PLS_INTEGER;
    
    BEGIN
    
        SELECT /*+opt_estimate (table t rows=1)*/
         COUNT(1)
          INTO l_count
          FROM comm_order_req cor
          JOIN TABLE(CAST(i_id_comm_order_req AS table_number)) t
            ON (t.column_value = cor.id_comm_order_req)
         WHERE cor.id_status NOT IN (g_id_sts_draft, g_id_sts_predf);
    
        -- double check
        g_error := 'IF l_count > 0 ';
        IF l_count > 0
        THEN
            g_error := 'Cannot delete this communication order in this status';
            RAISE g_exception;
        END IF;
    
        -- func
        -- delete co-sign data
        FOR i IN 1 .. i_id_comm_order_req.count
        LOOP
            g_error  := 'Call pk_co_sign_api.remove_draft_cosign / ID_COMM_ORDER_REQ=' || i_id_comm_order_req(i);
            g_retval := pk_co_sign_api.remove_draft_cosign(i_lang          => i_lang,
                                                           i_prof          => i_prof,
                                                           i_id_episode    => NULL,
                                                           i_id_task_group => i_id_comm_order_req(i),
                                                           i_id_task_type  => pk_alert_constant.g_task_comm_orders,
                                                           o_error         => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
        END LOOP;
    
        -- delete comm_order_req data
        g_error := 'DELETE FROM comm_order_req_ack corq ';
        DELETE FROM comm_order_req_ack corq
         WHERE corq.id_comm_order_req IN
               (SELECT /*+opt_estimate (table t rows=1)*/
                 column_value
                  FROM TABLE(CAST(i_id_comm_order_req AS table_number)) t);
    
        g_error := 'DELETE FROM comm_order_req_hist corh ';
        DELETE FROM comm_order_req_hist corh
         WHERE corh.id_comm_order_req IN
               (SELECT /*+opt_estimate (table t rows=1)*/
                 column_value
                  FROM TABLE(CAST(i_id_comm_order_req AS table_number)) t);
    
        -- delete from translation_trs
        l_code_trs := table_varchar();
        l_idx      := 0;
    
        g_error := 'FOR i IN 1 .. ' || i_id_comm_order_req.count;
        FOR i IN 1 .. i_id_comm_order_req.count
        LOOP
            l_code_trs.extend(6);
        
            l_idx := l_idx + 1;
            l_code_trs(l_idx) := g_code_notes || i_id_comm_order_req(i);
            l_idx := l_idx + 1;
            l_code_trs(l_idx) := g_code_clinical_indication || i_id_comm_order_req(i);
            l_idx := l_idx + 1;
            l_code_trs(l_idx) := g_code_prn_condition || i_id_comm_order_req(i);
            l_idx := l_idx + 1;
            l_code_trs(l_idx) := g_code_notes_cancel || i_id_comm_order_req(i);
            l_idx := l_idx + 1;
            l_code_trs(l_idx) := g_code_desc_concept_term || i_id_comm_order_req(i);
        END LOOP;
    
        pk_translation.delete_code_translation_trs(l_code_trs);
    
        g_error  := 'Call ts_comm_order_req.del_by ';
        l_rowids := table_varchar();
        ts_comm_order_req.del_by(where_clause_in => 'id_comm_order_req in (' ||
                                                    pk_utils.concat_table(i_tab => i_id_comm_order_req, i_delim => ',') || ')');
    
        t_data_gov_mnt.process_delete(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'COMM_ORDER_REQ',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'DELETE_COMM_ORDER_REQ',
                                              o_error    => o_error);
            RETURN FALSE;
    END delete_comm_order_req;

    FUNCTION set_comm_order_req_ack
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_comm_order_req IN table_number,
        o_id_ack_tab        OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_sysdate               TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_can_ack               VARCHAR2(1 CHAR);
        l_comm_req_row_tab      t_coll_comm_order_req;
        l_rowids                table_varchar;
        l_id_comm_order_req_ack comm_order_req_ack.id_comm_order_req_ack%TYPE;
        l_id_hist               comm_order_req_hist.id_comm_order_req_hist%TYPE;
        l_prof_cat              category.flg_type%TYPE;
    
    BEGIN
    
        l_sysdate    := current_timestamp;
        o_id_ack_tab := table_number();
        o_id_ack_tab.extend(i_id_comm_order_req.count);
        l_prof_cat := pk_prof_utils.get_category(i_lang, i_prof);
    
        -- func
        -- get comm order req data
        g_error  := 'Call get_comm_order_req_rows';
        g_retval := get_comm_order_req_rows(i_lang              => i_lang,
                                            i_prof              => i_prof,
                                            i_id_comm_order_req => i_id_comm_order_req,
                                            o_row_tab           => l_comm_req_row_tab,
                                            o_error             => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        l_rowids := table_varchar();
        g_error  := 'FOR i IN 1 .. ' || i_id_comm_order_req.count;
        FOR i IN 1 .. l_comm_req_row_tab.count
        LOOP
            -- check if acknowledge can be done
            l_can_ack := check_acknowledge(i_lang         => i_lang,
                                           i_prof         => i_prof,
                                           i_id_id_status => l_comm_req_row_tab(i).id_status,
                                           i_dt_begin     => l_comm_req_row_tab(i).dt_begin);
            IF l_can_ack = pk_alert_constant.g_no
            THEN
                g_error := 'Cannot acknowledge communication order request';
                RAISE g_exception;
            END IF;
        
            -- reset FLG_NEED_ACK on comm_order_req and set all values
            g_error := 'FLG_NEED_ACK / ID_COMM_ORDER_REQ=' || l_comm_req_row_tab(i).id_comm_order_req;
            l_comm_req_row_tab(i).id_professional := i_prof.id;
            l_comm_req_row_tab(i).id_institution := i_prof.institution;
            l_comm_req_row_tab(i).dt_status := l_sysdate;
        
            -- acknowledge data must be reset
            g_error  := 'Call set_flg_need_ack';
            g_retval := set_flg_need_ack(i_lang          => i_lang,
                                         i_prof          => i_prof,
                                         i_flg_category  => l_prof_cat,
                                         i_id_status     => l_comm_req_row_tab(i).id_status,
                                         i_value         => pk_alert_constant.g_no,
                                         io_flg_need_ack => l_comm_req_row_tab(i).flg_need_ack,
                                         o_error         => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            -- setting flg_action
            g_error := 'flg_action=' || g_action_ack;
            l_comm_req_row_tab(i).flg_action := g_action_ack;
        
            g_error := 'Call ts_comm_order_req.upd';
            ts_comm_order_req.upd(id_comm_order_req_in   => l_comm_req_row_tab(i).id_comm_order_req,
                                  id_professional_in     => l_comm_req_row_tab(i).id_professional,
                                  id_institution_in      => l_comm_req_row_tab(i).id_institution,
                                  dt_status_in           => l_comm_req_row_tab(i).dt_status,
                                  dt_last_update_tstz_in => current_timestamp,
                                  flg_need_ack_in        => l_comm_req_row_tab(i).flg_need_ack,
                                  flg_action_in          => l_comm_req_row_tab(i).flg_action,
                                  rows_out               => l_rowids);
        
            -- create hist data
            g_error  := 'Call set_comm_order_req_h / ID_COMM_ORDER_REQ=' || l_comm_req_row_tab(i).id_comm_order_req;
            g_retval := set_comm_order_req_h(i_lang               => i_lang,
                                             i_prof               => i_prof,
                                             i_comm_order_req_row => l_comm_req_row_tab(i),
                                             o_id_hist            => l_id_hist,
                                             o_error              => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            -- insert acknowledge in table comm_order_req_ack
            g_error := 'INSERT INTO comm_order_req_ack';
            INSERT INTO comm_order_req_ack
                (id_comm_order_req_ack, id_prof_ack, id_inst_ack, dt_ack, id_comm_order_req, id_comm_order_req_hist)
            VALUES
                (seq_comm_order_req_ack.nextval,
                 i_prof.id,
                 i_prof.institution,
                 l_sysdate,
                 l_comm_req_row_tab(i).id_comm_order_req,
                 l_id_hist)
            RETURNING id_comm_order_req_ack INTO l_id_comm_order_req_ack;
        
            g_error := 'l_id_comm_order_req_ack=' || l_id_comm_order_req_ack;
            o_id_ack_tab(i) := l_id_comm_order_req_ack;
        
        END LOOP;
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'COMM_ORDER_REQ',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_COMM_ORDER_REQ_ACK',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_comm_order_req_ack;

    FUNCTION set_comm_order_co_sign
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_comm_order_req      IN comm_order_req.id_comm_order_req%TYPE,
        i_id_episode             IN comm_order_req.id_episode%TYPE,
        i_id_status_begin        IN comm_order_req.id_status%TYPE,
        i_id_status_end          IN comm_order_req.id_status%TYPE,
        i_id_comm_order_req_hist IN comm_order_req_hist.id_comm_order_req_hist%TYPE,
        i_dt_comm_order_req_hist IN comm_order_req_hist.dt_status%TYPE,
        i_dt_order               IN co_sign.dt_ordered_by%TYPE,
        i_id_prof_order          IN co_sign.id_prof_ordered_by%TYPE,
        i_id_order_type          IN co_sign.id_order_type%TYPE,
        i_id_cs_action           IN co_sign.id_action%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -- co_sign
        l_id_co_sign           co_sign.id_co_sign%TYPE;
        l_id_co_sign_hist      co_sign_hist.id_co_sign_hist%TYPE;
        l_flg_prof_need_cosign VARCHAR2(1 CHAR);
        l_co_sign_data         t_table_co_sign;
        l_rec_co_sign          t_rec_co_sign;
    
    BEGIN
    
        -- co_sign data
        -- check if there were any acknowledges since last comm order req update/creation
        -- if the professional does not need co-sign, than all co-signs without ack are implicitly validated (must be outdated)
        -- if the professional need co-sign, outdated all co-signs that were not acknowledged
        g_error  := 'Call set_last_cs_outdated ';
        g_retval := set_last_cs_outdated(i_lang              => i_lang,
                                         i_prof              => i_prof,
                                         i_id_comm_order_req => i_id_comm_order_req,
                                         i_id_episode        => i_id_episode,
                                         o_error             => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- create co-sign if needed
        g_error := 'IF i_id_status_end ';
        IF i_id_status_end = g_id_sts_ongoing
           AND i_id_status_begin = g_id_sts_draft
           AND i_id_order_type IS NULL
        THEN
        
            -- get co-sign data of draft comm_order_req
            g_error        := 'Call pk_co_sign_api.tf_co_sign_tasks_info ';
            l_co_sign_data := pk_co_sign_api.tf_co_sign_tasks_info(i_lang          => i_lang,
                                                                   i_prof          => i_prof,
                                                                   i_episode       => i_id_episode,
                                                                   i_task_type     => pk_alert_constant.g_task_comm_orders,
                                                                   i_id_task_group => i_id_comm_order_req,
                                                                   i_tbl_status    => table_varchar(pk_co_sign_api.g_cosign_flg_status_d)); -- get draft co-sign
        
            IF l_co_sign_data.exists(1)
            THEN
            
                g_error       := 'Co-sign draft ';
                l_rec_co_sign := l_co_sign_data(1);
            
                -- no co-sign data was provided, check if comm_order_req keeps the same co-sign data (depends if professional needs co-sign or not)
                g_error  := 'Call pk_co_sign_api.check_prof_needs_cosign ';
                g_retval := pk_co_sign_api.check_prof_needs_cosign(i_lang                   => i_lang,
                                                                   i_prof                   => i_prof,
                                                                   i_episode                => i_id_episode,
                                                                   i_task_type              => pk_alert_constant.g_task_comm_orders,
                                                                   i_cosign_def_action_type => NULL,
                                                                   i_action                 => pk_comm_orders.g_cs_action_add,
                                                                   o_flg_prof_need_cosign   => l_flg_prof_need_cosign,
                                                                   o_error                  => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                g_error := 'l_flg_prof_need_cosign=' || l_flg_prof_need_cosign;
                IF l_flg_prof_need_cosign = pk_alert_constant.g_yes
                THEN
                
                    -- update draft co-sign to pending
                    g_error  := 'Call pk_co_sign_api.set_task_pending / ID_CO_SIGN=' || l_rec_co_sign.id_co_sign;
                    g_retval := pk_co_sign_api.set_task_pending(i_lang            => i_lang,
                                                                i_prof            => i_prof,
                                                                i_episode         => i_id_episode,
                                                                i_id_co_sign      => l_rec_co_sign.id_co_sign,
                                                                i_id_task_upd     => i_id_comm_order_req_hist,
                                                                i_dt_update       => i_dt_comm_order_req_hist,
                                                                o_id_co_sign_hist => l_id_co_sign_hist,
                                                                o_error           => o_error);
                
                    IF NOT g_retval
                    THEN
                        RAISE g_exception_np;
                    END IF;
                ELSE
                    -- outdate draft co-sign (professional does not need any co-sign)
                    g_error  := 'Call pk_co_sign_api.set_task_outdated / ID_CO_SIGN=' || l_rec_co_sign.id_co_sign;
                    g_retval := pk_co_sign_api.set_task_outdated(i_lang            => i_lang,
                                                                 i_prof            => i_prof,
                                                                 i_episode         => i_id_episode,
                                                                 i_id_co_sign      => l_rec_co_sign.id_co_sign,
                                                                 i_dt_update       => i_dt_comm_order_req_hist,
                                                                 o_id_co_sign_hist => l_id_co_sign_hist,
                                                                 o_error           => o_error);
                
                    IF NOT g_retval
                    THEN
                        RAISE g_exception_np;
                    END IF;
                
                END IF;
            END IF;
        
        ELSIF i_id_order_type IS NOT NULL
        THEN
        
            g_error  := 'Call pk_co_sign_api.set_pending_co_sign_task ';
            g_retval := pk_co_sign_api.set_pending_co_sign_task(i_lang               => i_lang,
                                                                i_prof               => i_prof,
                                                                i_episode            => i_id_episode,
                                                                i_id_task_type       => pk_alert_constant.g_task_comm_orders,
                                                                i_id_action          => i_id_cs_action,
                                                                i_id_task            => i_id_comm_order_req_hist,
                                                                i_id_task_group      => i_id_comm_order_req,
                                                                i_id_order_type      => i_id_order_type,
                                                                i_id_prof_created    => i_prof.id,
                                                                i_id_prof_ordered_by => i_id_prof_order,
                                                                i_dt_created         => i_dt_comm_order_req_hist,
                                                                i_dt_ordered_by      => i_dt_order,
                                                                o_id_co_sign         => l_id_co_sign,
                                                                o_id_co_sign_hist    => l_id_co_sign_hist,
                                                                o_error              => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_COMM_ORDER_CO_SIGN',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_comm_order_co_sign;

    FUNCTION set_comm_order_status
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_comm_order_req      IN table_number,
        i_id_status_end          IN comm_order_req.id_status%TYPE,
        i_id_workflow_action     IN wf_workflow_action.id_workflow_action%TYPE,
        i_id_cancel_reason       IN comm_order_req.id_cancel_reason%TYPE DEFAULT NULL,
        i_notes_cancel           IN pk_translation.t_lob_char DEFAULT NULL,
        i_dt_req                 IN comm_order_req.dt_req%TYPE DEFAULT NULL,
        i_id_episode             IN comm_order_req.id_episode%TYPE DEFAULT NULL,
        i_flg_ignore_trs_error   IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_auto_descontinued      IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_id_comm_order_req      OUT table_number,
        o_id_comm_order_req_hist OUT table_number,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_sysdate  TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_prof_cat category.flg_type%TYPE;
    
        l_comm_req_row_tab t_coll_comm_order_req;
        l_id_hist          comm_order_req_hist.id_comm_order_req_hist%TYPE;
        l_rowids           table_varchar := table_varchar();
        l_id_status_begin  comm_order_req.id_status%TYPE;
        -- wf
        l_id_category         category.id_category%TYPE;
        l_id_profile_template profile_template.id_profile_template%TYPE;
        l_flg_available       VARCHAR2(1 CHAR);
    
    BEGIN
    
        l_sysdate  := current_timestamp;
        l_prof_cat := pk_prof_utils.get_category(i_lang, i_prof);
    
        o_id_comm_order_req      := table_number();
        o_id_comm_order_req_hist := table_number();
    
        o_id_comm_order_req.extend(i_id_comm_order_req.count);
        o_id_comm_order_req_hist.extend(i_id_comm_order_req.count);
    
        l_id_category         := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
        l_id_profile_template := pk_tools.get_prof_profile_template(i_prof);
    
        -- get data
        g_error  := 'Call get_comm_order_req_rows ';
        g_retval := get_comm_order_req_rows(i_lang              => i_lang,
                                            i_prof              => i_prof,
                                            i_id_comm_order_req => i_id_comm_order_req,
                                            o_row_tab           => l_comm_req_row_tab,
                                            o_error             => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := 'FOR i IN 1 .. ' || l_comm_req_row_tab.count;
        FOR i IN 1 .. l_comm_req_row_tab.count
        LOOP
            l_id_status_begin := l_comm_req_row_tab(i).id_status;
        
            -- check workflow permission
            g_error := 'Call check_transition';
            IF i_auto_descontinued = pk_alert_constant.g_no
            THEN
                l_flg_available := check_transition(i_lang                => i_lang,
                                                    i_prof                => i_prof,
                                                    i_id_workflow         => l_comm_req_row_tab(i).id_workflow,
                                                    i_id_status_begin     => l_comm_req_row_tab(i).id_status,
                                                    i_id_status_end       => i_id_status_end,
                                                    i_id_workflow_action  => i_id_workflow_action,
                                                    i_id_category         => l_id_category,
                                                    i_id_profile_template => l_id_profile_template,
                                                    i_id_comm_order_req   => l_comm_req_row_tab(i).id_comm_order_req,
                                                    i_dt_begin            => l_comm_req_row_tab(i).dt_begin);
            ELSE
                l_flg_available := pk_ref_constant.g_yes;
            END IF;
        
            IF l_flg_available = pk_ref_constant.g_yes
            THEN
                -- change status
                g_error := 'Change status';
                l_comm_req_row_tab(i).id_previous_status := l_comm_req_row_tab(i).id_status;
                l_comm_req_row_tab(i).id_status := i_id_status_end;
            
                --------------
                -- used when cancelling the request
                g_error := 'cancel';
                IF i_id_cancel_reason IS NOT NULL
                THEN
                    l_comm_req_row_tab(i).id_cancel_reason := i_id_cancel_reason;
                END IF;
            
                IF i_notes_cancel IS NOT NULL
                   AND dbms_lob.getlength(i_notes_cancel) > 0
                THEN
                    l_comm_req_row_tab(i).notes_cancel := i_notes_cancel;
                END IF;
                --------------
            
                --------------                
                -- used when ordering the request
                g_error := 'order';
                IF i_dt_req IS NOT NULL
                THEN
                    l_comm_req_row_tab(i).dt_req := i_dt_req;
                END IF;
            
                IF i_id_episode IS NOT NULL
                THEN
                    l_comm_req_row_tab(i).id_episode := i_id_episode;
                END IF;
            
                -- set all values
                g_error := 'Internal sets';
                l_comm_req_row_tab(i).id_professional := i_prof.id;
                l_comm_req_row_tab(i).id_institution := i_prof.institution;
                l_comm_req_row_tab(i).dt_status := l_sysdate;
            
                g_error  := 'Call set_flg_need_ack';
                g_retval := set_flg_need_ack(i_lang          => i_lang,
                                             i_prof          => i_prof,
                                             i_flg_category  => l_prof_cat,
                                             i_id_status     => l_comm_req_row_tab(i).id_status,
                                             i_value         => pk_alert_constant.g_yes, -- needs to be acknowledge
                                             io_flg_need_ack => l_comm_req_row_tab(i).flg_need_ack,
                                             o_error         => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                g_error := 'Call get_flg_action';
                l_comm_req_row_tab(i).flg_action := get_flg_action(i_lang             => i_lang,
                                                                   i_prof             => i_prof,
                                                                   i_id_status_actual => l_comm_req_row_tab(i).id_status,
                                                                   i_task_type        => l_comm_req_row_tab(i).id_task_type);
            
                g_error := 'Call ts_comm_order_req.upd';
                ts_comm_order_req.upd(id_comm_order_req_in   => l_comm_req_row_tab(i).id_comm_order_req,
                                      id_status_in           => l_comm_req_row_tab(i).id_status,
                                      id_cancel_reason_in    => l_comm_req_row_tab(i).id_cancel_reason, -- do not update if null
                                      dt_req_in              => l_comm_req_row_tab(i).dt_req, -- do not update if null
                                      id_episode_in          => l_comm_req_row_tab(i).id_episode, -- do not update if null
                                      id_professional_in     => l_comm_req_row_tab(i).id_professional,
                                      id_institution_in      => l_comm_req_row_tab(i).id_institution,
                                      dt_status_in           => l_comm_req_row_tab(i).dt_status,
                                      dt_last_update_tstz_in => current_timestamp,
                                      flg_need_ack_in        => l_comm_req_row_tab(i).flg_need_ack,
                                      flg_action_in          => l_comm_req_row_tab(i).flg_action,
                                      id_previous_status_in  => l_comm_req_row_tab(i).id_previous_status,
                                      rows_out               => l_rowids);
            
                IF l_comm_req_row_tab(i).notes_cancel IS NOT NULL
                THEN
                    g_error := 'Call pk_translation.insert_translation_trs / ' || g_code_notes_cancel || l_comm_req_row_tab(i).id_comm_order_req;
                    pk_translation.insert_translation_trs(i_lang   => i_lang,
                                                          i_code   => g_code_notes_cancel || l_comm_req_row_tab(i).id_comm_order_req,
                                                          i_desc   => l_comm_req_row_tab(i).notes_cancel,
                                                          i_module => 'COMM_ORDER_REQ');
                END IF;
            
                -- create hist data
                g_error  := 'Call set_comm_order_req_h';
                g_retval := set_comm_order_req_h(i_lang               => i_lang,
                                                 i_prof               => i_prof,
                                                 i_comm_order_req_row => l_comm_req_row_tab(i),
                                                 o_id_hist            => l_id_hist,
                                                 o_error              => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                -- set output variables
                g_error := 'Output vars';
                o_id_comm_order_req(i) := l_comm_req_row_tab(i).id_comm_order_req;
                o_id_comm_order_req_hist(i) := l_id_hist;
            
                -- check if set first obs function must be called
                IF l_comm_req_row_tab(i).id_status NOT IN (g_id_sts_predf, g_id_sts_draft)
                THEN
                
                    g_error := 'Call pk_visit.set_first_obs';
                    IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                                  i_id_episode          => l_comm_req_row_tab(i).id_episode,
                                                  i_pat                 => l_comm_req_row_tab(i).id_patient,
                                                  i_prof                => i_prof,
                                                  i_prof_cat_type       => l_prof_cat,
                                                  i_dt_last_interaction => l_sysdate,
                                                  i_dt_first_obs        => l_sysdate,
                                                  o_error               => o_error)
                    THEN
                        RAISE g_exception_np;
                    END IF;
                
                    g_error := 'Call t_ti_log.ins_log';
                    IF NOT t_ti_log.ins_log(i_lang       => i_lang,
                                            i_prof       => i_prof,
                                            i_id_episode => l_comm_req_row_tab(i).id_episode,
                                            i_flg_status => l_comm_req_row_tab(i).id_status,
                                            i_id_record  => l_comm_req_row_tab(i).id_comm_order_req,
                                            i_flg_type   => pk_alert_constant.g_comm_order_req,
                                            o_error      => o_error)
                    THEN
                        RAISE g_exception_np;
                    END IF;
                END IF;
            ELSE
                -- ignores the error if i_flg_ignore_trs_error=Y
                IF i_flg_ignore_trs_error = pk_alert_constant.g_no
                THEN
                    g_error := 'Not a valid transition';
                    RAISE g_exception;
                END IF;
            END IF;
        END LOOP;
    
        IF l_rowids.count > 0
        THEN
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'COMM_ORDER_REQ',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_COMM_ORDER_STATUS',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_comm_order_status;

    FUNCTION set_action_order
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN comm_order_req.id_episode%TYPE DEFAULT NULL,
        i_id_comm_order_req IN table_number,
        i_dt_order          IN co_sign.dt_ordered_by%TYPE,
        i_id_prof_order     IN co_sign.id_prof_ordered_by%TYPE,
        i_id_order_type     IN co_sign.id_order_type%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_status_end          comm_order_req.id_status%TYPE;
        l_id_workflow_action     wf_workflow_action.id_workflow_action%TYPE;
        l_sysdate                TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_id_comm_order_req      table_number;
        l_id_comm_order_req_hist table_number;
        l_dt_begin_req           comm_order_req.dt_begin%TYPE;
        -- co_sign        
        l_id_co_sign           co_sign.id_co_sign%TYPE;
        l_id_co_sign_hist      co_sign_hist.id_co_sign_hist%TYPE;
        l_flg_prof_need_cosign VARCHAR2(1 CHAR);
        l_co_sign_data         t_table_co_sign;
        l_rec_co_sign          t_rec_co_sign;
        l_id_task_type         task_type.id_task_type%TYPE;
    
    BEGIN
    
        l_sysdate := current_timestamp;
    
        -- 1- change status of comm_order_req
        l_id_status_end      := g_id_sts_ongoing;
        l_id_workflow_action := g_id_action_order;
    
        g_error  := 'Call set_comm_order_status ';
        g_retval := set_comm_order_status(i_lang               => i_lang,
                                          i_prof               => i_prof,
                                          i_id_comm_order_req  => i_id_comm_order_req,
                                          i_id_status_end      => l_id_status_end,
                                          i_id_workflow_action => l_id_workflow_action,
                                          -- update this data also
                                          i_dt_req                 => l_sysdate,
                                          i_id_episode             => i_id_episode,
                                          o_id_comm_order_req      => l_id_comm_order_req,
                                          o_id_comm_order_req_hist => l_id_comm_order_req_hist,
                                          o_error                  => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- 2- updates co-sign data
    
        -- check if professional needs to set co-sign data
        g_error  := 'Call pk_co_sign_api.check_prof_needs_cosign ';
        g_retval := pk_co_sign_api.check_prof_needs_cosign(i_lang                   => i_lang,
                                                           i_prof                   => i_prof,
                                                           i_episode                => i_id_episode,
                                                           i_task_type              => pk_alert_constant.g_task_comm_orders,
                                                           i_cosign_def_action_type => NULL,
                                                           i_action                 => pk_comm_orders.g_cs_action_add,
                                                           o_flg_prof_need_cosign   => l_flg_prof_need_cosign,
                                                           o_error                  => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := 'FOR i IN 1 .. ' || l_id_comm_order_req.count;
        <<loop_cs>>
        FOR i IN 1 .. l_id_comm_order_req.count
        LOOP
            IF i_id_order_type IS NULL
            THEN
                -- no co-sign data was provided, check if comm_order_req keeps the same co-sign data (depends if professional needs co-sign or not)
                -- get all co-sign drafts (if any)
                g_error        := 'Call pk_co_sign_api.tf_co_sign_tasks_info';
                l_co_sign_data := pk_co_sign_api.tf_co_sign_tasks_info(i_lang          => i_lang,
                                                                       i_prof          => i_prof,
                                                                       i_episode       => i_id_episode,
                                                                       i_task_type     => pk_alert_constant.g_task_comm_orders,
                                                                       i_id_task_group => l_id_comm_order_req(i),
                                                                       i_tbl_status    => table_varchar(pk_co_sign_api.g_cosign_flg_status_d)); -- get draft co-sign
            
                IF l_co_sign_data.exists(1)
                THEN
                
                    g_error       := 'Co-sign draft';
                    l_rec_co_sign := l_co_sign_data(1);
                
                    g_error := 'l_flg_prof_need_cosign=' || l_flg_prof_need_cosign;
                    IF l_flg_prof_need_cosign = pk_alert_constant.g_yes
                    THEN
                        -- update draft co-sign to pending
                        g_error  := 'Call pk_co_sign_api.set_task_pending / ID_CO_SIGN=' || l_rec_co_sign.id_co_sign || '';
                        g_retval := pk_co_sign_api.set_task_pending(i_lang            => i_lang,
                                                                    i_prof            => i_prof,
                                                                    i_episode         => i_id_episode,
                                                                    i_id_co_sign      => l_rec_co_sign.id_co_sign,
                                                                    i_id_task_upd     => l_id_comm_order_req_hist(i),
                                                                    i_dt_update       => l_sysdate,
                                                                    o_id_co_sign_hist => l_id_co_sign_hist,
                                                                    o_error           => o_error);
                    
                        IF NOT g_retval
                        THEN
                            RAISE g_exception_np;
                        END IF;
                    ELSE
                        -- outdate draft co-sign (professional does not need any co-sign)
                        g_error  := 'Call pk_co_sign_api.set_task_outdated / ID_CO_SIGN=' || l_rec_co_sign.id_co_sign || '';
                        g_retval := pk_co_sign_api.set_task_outdated(i_lang            => i_lang,
                                                                     i_prof            => i_prof,
                                                                     i_episode         => i_id_episode,
                                                                     i_id_co_sign      => l_rec_co_sign.id_co_sign,
                                                                     i_dt_update       => l_sysdate,
                                                                     o_id_co_sign_hist => l_id_co_sign_hist,
                                                                     o_error           => o_error);
                    
                        IF NOT g_retval
                        THEN
                            RAISE g_exception_np;
                        END IF;
                    END IF;
                END IF;
            
            ELSIF i_id_order_type IS NOT NULL
            THEN
            
                -- outdate all co-signs that were not acknowledged
                g_error  := 'Call set_last_cs_outdated';
                g_retval := set_last_cs_outdated(i_lang              => i_lang,
                                                 i_prof              => i_prof,
                                                 i_id_comm_order_req => l_id_comm_order_req(i),
                                                 i_id_episode        => i_id_episode,
                                                 o_error             => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                g_error  := 'Call pk_co_sign_api.set_pending_co_sign_task ';
                g_retval := pk_co_sign_api.set_pending_co_sign_task(i_lang               => i_lang,
                                                                    i_prof               => i_prof,
                                                                    i_episode            => i_id_episode,
                                                                    i_id_task_type       => pk_alert_constant.g_task_comm_orders,
                                                                    i_id_action          => g_cs_action_add,
                                                                    i_id_task            => l_id_comm_order_req_hist(i),
                                                                    i_id_task_group      => l_id_comm_order_req(i),
                                                                    i_id_order_type      => i_id_order_type,
                                                                    i_id_prof_created    => i_prof.id,
                                                                    i_id_prof_ordered_by => i_id_prof_order,
                                                                    i_dt_created         => l_sysdate,
                                                                    i_dt_ordered_by      => i_dt_order,
                                                                    o_id_co_sign         => l_id_co_sign,
                                                                    o_id_co_sign_hist    => l_id_co_sign_hist,
                                                                    o_error              => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            END IF;
        END LOOP loop_cs;
    
        -- 3- Synchronize with CPOE
        g_error := 'Synchronize with CPOE ';
        FOR i IN 1 .. i_id_comm_order_req.count
        LOOP
        
            SELECT cor.dt_begin, cor.id_task_type
              INTO l_dt_begin_req, l_id_task_type
              FROM comm_order_req cor
             WHERE cor.id_comm_order_req = i_id_comm_order_req(i);
        
            IF NOT pk_cpoe.sync_task(i_lang                 => i_lang,
                                i_prof                 => i_prof,
                                i_episode              => i_id_episode,
                                i_task_type            => CASE
                                                              WHEN l_id_task_type = pk_alert_constant.g_task_medical_orders THEN
                                                               pk_alert_constant.g_task_type_med_order
                                                              ELSE
                                                               pk_alert_constant.g_task_type_com_order
                                                          END,
                                i_task_request         => i_id_comm_order_req(i),
                                i_task_start_timestamp => l_dt_begin_req,
                                o_error                => o_error)
            THEN
                RAISE g_exception_np;
            END IF;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_ACTION_ORDER',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_action_order;

    FUNCTION set_action_expire
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_comm_order_req    IN table_number,
        i_flg_ignore_trs_error IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_status_end          comm_order_req.id_status%TYPE;
        l_id_workflow_action     wf_workflow_action.id_workflow_action%TYPE;
        l_id_comm_order_req      table_number;
        l_id_comm_order_req_hist table_number;
    
    BEGIN
    
        l_id_status_end      := g_id_sts_expired;
        l_id_workflow_action := g_id_action_expire;
    
        g_error  := 'Call set_comm_order_status ';
        g_retval := set_comm_order_status(i_lang                   => i_lang,
                                          i_prof                   => i_prof,
                                          i_id_comm_order_req      => i_id_comm_order_req,
                                          i_id_status_end          => l_id_status_end,
                                          i_id_workflow_action     => l_id_workflow_action,
                                          i_flg_ignore_trs_error   => i_flg_ignore_trs_error,
                                          o_id_comm_order_req      => l_id_comm_order_req,
                                          o_id_comm_order_req_hist => l_id_comm_order_req_hist,
                                          o_error                  => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- co-sign data is maintained as it is
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_ACTION_EXPIRE',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_action_expire;

    FUNCTION set_action_cancel_discontinue
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_comm_order_req IN table_number,
        i_id_episode        IN comm_order_req.id_episode%TYPE,
        i_id_reason         IN comm_order_req.id_cancel_reason%TYPE,
        i_notes             IN pk_translation.t_lob_char,
        i_dt_order          IN co_sign.dt_ordered_by%TYPE,
        i_id_prof_order     IN co_sign.id_prof_ordered_by%TYPE,
        i_id_order_type     IN co_sign.id_order_type%TYPE,
        i_auto_descontinued IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_sysdate            TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_comm_req_row_tab   t_coll_comm_order_req;
        l_comm_orders_reqs   table_number;
        l_id_status_end      comm_order_req.id_status%TYPE;
        l_id_workflow_action wf_workflow_action.id_workflow_action%TYPE;
        -- wf
        l_id_category            category.id_category%TYPE;
        l_id_profile_template    profile_template.id_profile_template%TYPE;
        l_set                    PLS_INTEGER := 0;
        l_count                  PLS_INTEGER;
        l_id_comm_order_req      table_number;
        l_id_comm_order_req_hist table_number;
        -- co_sign
        l_id_co_sign      co_sign.id_co_sign%TYPE;
        l_id_co_sign_hist co_sign_hist.id_co_sign_hist%TYPE;
    
        l_comm_order_plan_hist comm_order_plan_hist.id_comm_order_plan_hist%TYPE;
    
        l_rows_out table_varchar;
    
        CURSOR c_comm_order_plan(i_comm_order_req comm_order_req.id_comm_order_req%TYPE) IS
            SELECT cop.id_comm_order_plan
              FROM comm_order_plan cop
             WHERE cop.id_comm_order_req = i_comm_order_req
               AND cop.flg_status NOT IN (g_comm_order_plan_executed,
                                          g_comm_order_plan_expired,
                                          g_comm_order_plan_cancel,
                                          g_comm_order_plan_discontinued);
    
        FUNCTION get_status_end(i_id_comm_order_req IN comm_order_req.id_comm_order_req%TYPE) RETURN NUMBER IS
            l_count_exec_tasks NUMBER := 0;
        BEGIN
            --Check if there are tasks that have alredy been concluded or initiated
            --In such case, the requisition should be discontinued and not canceled.
            SELECT COUNT(1)
              INTO l_count_exec_tasks
              FROM comm_order_plan cop
             WHERE cop.id_comm_order_req = i_id_comm_order_req
               AND cop.flg_status IN (g_comm_order_plan_ongoing,
                                      g_comm_order_plan_executed,
                                      g_comm_order_plan_monitorized,
                                      g_comm_order_plan_discontinued);
        
            IF l_count_exec_tasks > 0
            THEN
                RETURN g_id_sts_discontinued;
            ELSE
                RETURN g_id_sts_canceled;
            END IF;
        END get_status_end;
    
    BEGIN
    
        l_sysdate := current_timestamp;
        l_count   := 0;
    
        -- check for each comm_order_req if it will be cancelled or discontinued
    
        -- get data
        l_id_category         := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
        l_id_profile_template := pk_tools.get_prof_profile_template(i_prof);
    
        g_error  := 'Call get_comm_order_req_rows ';
        g_retval := get_comm_order_req_rows(i_lang              => i_lang,
                                            i_prof              => i_prof,
                                            i_id_comm_order_req => i_id_comm_order_req,
                                            o_row_tab           => l_comm_req_row_tab,
                                            o_error             => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        FOR j IN 1 .. 2
        LOOP
        
            IF j = 1
               AND i_auto_descontinued = pk_alert_constant.g_no
            THEN
                -- checks if comm_order_reqs can be cancelled
                g_error              := 'Check if comm_order reqs can be cancelled ';
                l_id_status_end      := g_id_sts_canceled;
                l_id_workflow_action := g_id_action_cancel;
            ELSE
                -- checks if comm_order_reqs can be discontinued
                g_error              := 'Check if comm_order reqs can be discontinued ';
                l_id_status_end      := g_id_sts_completed;
                l_id_workflow_action := g_id_action_complete;
            END IF;
        
            IF i_auto_descontinued = pk_alert_constant.g_no
            THEN
            
                SELECT /*+opt_estimate (table t rows=1)*/
                 t.id_comm_order_req
                  BULK COLLECT
                  INTO l_comm_orders_reqs
                  FROM TABLE(l_comm_req_row_tab) t
                  JOIN comm_order_req cor
                    ON cor.id_comm_order_req = t.id_comm_order_req
                 WHERE check_transition(i_lang                => i_lang,
                                        i_prof                => i_prof,
                                        i_id_workflow         => t.id_workflow,
                                        i_id_status_begin     => t.id_status,
                                        i_id_status_end       => l_id_status_end,
                                        i_id_workflow_action  => l_id_workflow_action,
                                        i_id_category         => l_id_category,
                                        i_id_profile_template => l_id_profile_template,
                                        i_id_comm_order_req   => t.id_comm_order_req,
                                        i_dt_begin            => t.dt_begin) = pk_alert_constant.g_yes
                   AND (j = 1 OR (j = 2 AND i_auto_descontinued = pk_alert_constant.g_yes));
            ELSE
                SELECT /*+opt_estimate (table t rows=1)*/
                 id_comm_order_req
                  BULK COLLECT
                  INTO l_comm_orders_reqs
                  FROM TABLE(l_comm_req_row_tab) t
                 WHERE j = 1;
            END IF;
        
            l_count := l_count + l_comm_orders_reqs.count;
        
            -- cancel/discontinue those comm_order_reqs
            IF l_comm_orders_reqs.count > 0
            THEN
                l_set   := 1;
                g_error := 'Call set_comm_order_status / STS_END=' || l_id_status_end || ' WF_ACTION=' ||
                           l_id_workflow_action;
                FOR i IN l_comm_orders_reqs.first .. l_comm_orders_reqs.last
                LOOP
                    g_retval := set_comm_order_status(i_lang                   => i_lang,
                                                      i_prof                   => i_prof,
                                                      i_id_comm_order_req      => table_number(l_comm_orders_reqs(i)),
                                                      i_id_status_end          => get_status_end(l_comm_orders_reqs(i)),
                                                      i_id_workflow_action     => l_id_workflow_action,
                                                      i_id_cancel_reason       => i_id_reason,
                                                      i_notes_cancel           => i_notes,
                                                      i_auto_descontinued      => i_auto_descontinued,
                                                      o_id_comm_order_req      => l_id_comm_order_req,
                                                      o_id_comm_order_req_hist => l_id_comm_order_req_hist,
                                                      o_error                  => o_error);
                
                    IF NOT g_retval
                    THEN
                        RAISE g_exception_np;
                    END IF;
                END LOOP;
            
                -- update co-sign data
                g_error := 'FOR i IN 1 .. ' || l_id_comm_order_req.count;
                <<loop_cs>>
                FOR i IN 1 .. l_id_comm_order_req.count
                LOOP
                    -- order/edit co-sign
                    --  - is outdated (if there are no acknowledgments)
                    --  - remains unchanged (if there are acknowledgments)
                    -- cancellation co-sign is created (if specified)
                
                    -- outdate all co-signs that were not acknowledged
                    g_error  := 'Call set_last_cs_outdated';
                    g_retval := set_last_cs_outdated(i_lang              => i_lang,
                                                     i_prof              => i_prof,
                                                     i_id_comm_order_req => l_id_comm_order_req(i),
                                                     i_id_episode        => i_id_episode,
                                                     o_error             => o_error);
                
                    IF NOT g_retval
                    THEN
                        RAISE g_exception_np;
                    END IF;
                
                    IF i_id_order_type IS NOT NULL
                    THEN
                    
                        g_error  := 'Call pk_co_sign_api.set_pending_co_sign_task ';
                        g_retval := pk_co_sign_api.set_pending_co_sign_task(i_lang               => i_lang,
                                                                            i_prof               => i_prof,
                                                                            i_episode            => i_id_episode,
                                                                            i_id_task_type       => pk_alert_constant.g_task_comm_orders,
                                                                            i_id_action          => g_cs_action_cancel_discontinue,
                                                                            i_id_task            => l_id_comm_order_req_hist(i),
                                                                            i_id_task_group      => l_id_comm_order_req(i),
                                                                            i_id_order_type      => i_id_order_type,
                                                                            i_id_prof_created    => i_prof.id,
                                                                            i_id_prof_ordered_by => i_id_prof_order,
                                                                            i_dt_created         => l_sysdate,
                                                                            i_dt_ordered_by      => i_dt_order,
                                                                            o_id_co_sign         => l_id_co_sign,
                                                                            o_id_co_sign_hist    => l_id_co_sign_hist,
                                                                            o_error              => o_error);
                    
                        IF NOT g_retval
                        THEN
                            RAISE g_exception_np;
                        END IF;
                    END IF;
                END LOOP loop_cs;
            
                /* Cancel Common Order Plan */
                FOR k IN 1 .. l_comm_orders_reqs.count
                LOOP
                    FOR rec IN c_comm_order_plan(l_comm_orders_reqs(k))
                    LOOP
                        g_error := 'CALL TO pk_comm_orders.SET_COMM_ORDER_EXECUTION_HIST';
                        IF NOT pk_comm_orders.set_comm_order_execution_hist(i_lang                 => i_lang,
                                                                            i_prof                 => i_prof,
                                                                            i_comm_order_plan      => rec.id_comm_order_plan,
                                                                            o_comm_order_plan_hist => l_comm_order_plan_hist,
                                                                            o_error                => o_error)
                        THEN
                            RAISE g_exception;
                        END IF;
                    
                        g_error := 'UPDATE COMM_ORDER_PLAN';
                        ts_comm_order_plan.upd(id_comm_order_plan_in  => rec.id_comm_order_plan,
                                               flg_status_in          => CASE get_status_end(l_comm_orders_reqs(k))
                                                                             WHEN g_id_sts_canceled THEN
                                                                              g_comm_order_plan_cancel
                                                                             ELSE
                                                                              g_comm_order_plan_discontinued
                                                                         END,
                                               id_prof_cancel_in      => i_prof.id,
                                               notes_cancel_in        => i_notes,
                                               dt_cancel_tstz_in      => l_sysdate,
                                               id_prof_performed_in   => NULL,
                                               id_prof_performed_nin  => FALSE,
                                               start_time_in          => NULL,
                                               start_time_nin         => FALSE,
                                               end_time_in            => NULL,
                                               end_time_nin           => FALSE,
                                               id_cancel_reason_in    => i_id_reason,
                                               id_prof_last_update_in => i_prof.id,
                                               dt_last_update_tstz_in => l_sysdate,
                                               rows_out               => l_rows_out);
                    
                        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'COMM_ORDER_PLAN',
                                                      i_rowids     => l_rows_out,
                                                      o_error      => o_error);
                    
                    END LOOP;
                END LOOP;
            END IF;
        END LOOP;
    
        IF l_count != i_id_comm_order_req.count -- not all comm_order_reqs were cancelled/discontinued
        THEN
            g_error := 'Not all comm_order_reqs were cancelled/discontinued ';
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_ACTION_CANCEL_DISCONTINUE',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_action_cancel_discontinue;

    FUNCTION set_action
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_action         IN action.id_action%TYPE,
        i_id_comm_order_req IN table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_ack_tab table_number;
    
    BEGIN
    
        CASE
            WHEN i_id_action IN (g_id_act_ack, g_id_act_ack_med_order) THEN
                g_error  := 'Call set_comm_order_req_ack ';
                g_retval := set_comm_order_req_ack(i_lang              => i_lang,
                                                   i_prof              => i_prof,
                                                   i_id_comm_order_req => i_id_comm_order_req,
                                                   o_id_ack_tab        => l_id_ack_tab,
                                                   o_error             => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
            ELSE
                g_error := 'Action ' || i_id_action || ' not found ';
                RAISE g_exception;
            
        END CASE;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_ACTION',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_action;

    FUNCTION get_actions
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_comm_order_req IN table_number,
        i_task_type         IN NUMBER,
        o_list              OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_actions     t_coll_action;
        l_code_action VARCHAR2(50 CHAR);
    
        l_sys_cfg_old_wf sys_config.value%TYPE := pk_sysconfig.get_config(i_prof    => i_prof,
                                                                          i_code_cf => 'COMMUNICATION_ORDERS_SCREEN_NEW');
    
    BEGIN
    
        l_code_action := CASE
                             WHEN i_task_type = pk_cpoe.g_task_type_com_order THEN
                              'COMM_ORDER_ACTION'
                             ELSE
                              'MED_ORDER_ACTION'
                         END;
    
        -- all actions are listed in table action under subject COMM_ORDER_ACTION
        -- Each action is checked with function check_action_active
        -- if more actions are needed, add the respective check code to function check_action_active
        g_error   := 'Call pk_action.tf_get_actions_permissions ';
        l_actions := pk_action.tf_get_actions_permissions(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                          i_subject    => l_code_action,
                                                          i_from_state => NULL);
    
        g_error := 'OPEN o_list FOR ';
        OPEN o_list FOR
            SELECT /*+opt_estimate (table t rows=1)*/
             t.id_action,
             t.id_parent,
             t.level_nr "level",
             t.from_state,
             t.to_state,
             t.desc_action,
             t.icon,
             t.flg_default,
             check_action_active(i_lang              => i_lang,
                                 i_prof              => i_prof,
                                 i_id_action         => t.id_action,
                                 i_internal_name     => t.action,
                                 i_id_comm_order_req => i_id_comm_order_req) flg_active,
             t.action
              FROM TABLE(CAST(l_actions AS t_coll_action)) t
             WHERE (t.action <> 'EXECUTE' OR
                   (i_task_type <> pk_cpoe.g_task_type_com_order OR l_sys_cfg_old_wf = pk_alert_constant.g_yes))
             ORDER BY t.desc_action;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_ACTIONS',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_actions;

    FUNCTION get_comm_order_status
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_comm_order_req IN table_number,
        o_task_status    OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        OPEN o_task_status FOR
            SELECT pk_alert_constant.g_task_type_com_order AS id_task_type,
                   cor.id_comm_order_req                   AS id_task_request,
                   cor.id_status                           AS flg_status
              FROM comm_order_req cor
             WHERE cor.id_comm_order_req IN (SELECT /*+opt_estimate (table t rows=1)*/
                                              column_value
                                               FROM TABLE(i_comm_order_req) t);
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_COMM_ORDER_STATUS',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_task_status);
            RETURN FALSE;
    END get_comm_order_status;

    FUNCTION get_comm_order_status_string
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_comm_order_req     IN comm_order_req.id_comm_order_req%TYPE,
        i_id_status             IN comm_order_req.id_status%TYPE,
        i_dt_begin              IN comm_order_req.dt_begin%TYPE,
        i_flg_need_ack          IN comm_order_req.flg_need_ack%TYPE,
        i_flg_ignore_ack        IN comm_order_req.flg_need_ack%TYPE DEFAULT pk_alert_constant.g_no,
        i_flg_new_wf_comm_order IN sys_config.value%TYPE DEFAULT pk_alert_constant.g_yes
    ) RETURN VARCHAR2 IS
    
        l_sysdate       TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_status_string VARCHAR2(1000 CHAR);
        l_back_color    VARCHAR2(10 CHAR);
        l_message_color VARCHAR2(10 CHAR);
    
        l_comm_order_plan comm_order_plan.id_comm_order_plan%TYPE;
        l_id_task_type    comm_order_req.id_task_type%TYPE;
        l_flg_prn         comm_order_req.flg_prn%TYPE;
    
    BEGIN
    
        l_sysdate := current_timestamp;
    
        BEGIN
            SELECT t.id_comm_order_plan, t.id_task_type
              INTO l_comm_order_plan, l_id_task_type
              FROM (SELECT cop.id_comm_order_plan, cop.exec_number, cor.id_task_type
                      FROM comm_order_req cor
                      LEFT JOIN comm_order_plan cop
                        ON cor.id_comm_order_req = cop.id_comm_order_req
                     WHERE cor.id_comm_order_req = i_id_comm_order_req
                     ORDER BY cop.exec_number DESC, cop.id_comm_order_plan DESC) t
             WHERE rownum = 1;
        EXCEPTION
            WHEN OTHERS THEN
                l_comm_order_plan := NULL;
        END;
    
        -- getting background color
        IF l_comm_order_plan IS NOT NULL
        THEN
            SELECT cor.flg_prn
              INTO l_flg_prn
              FROM comm_order_req cor
             WHERE cor.id_comm_order_req = i_id_comm_order_req;
        
            IF l_flg_prn = pk_alert_constant.g_no
            THEN
                SELECT pk_utils.get_status_string(i_lang,
                                                   i_prof,
                                                   pk_ea_logic_comm_orders.get_comm_order_plan_status_str(i_lang,
                                                                                                          i_prof,
                                                                                                          CASE
                                                                                                              WHEN cor.flg_prn = pk_alert_constant.g_no THEN
                                                                                                               CASE
                                                                                                                   WHEN (l_id_task_type = pk_alert_constant.g_task_comm_orders AND
                                                                                                                        i_flg_new_wf_comm_order = pk_alert_constant.g_no) THEN
                                                                                                                    decode(cop.flg_status, g_comm_order_plan_req, g_comm_order_plan_ongoing, cop.flg_status)
                                                                                                                   ELSE
                                                                                                                    cop.flg_status
                                                                                                               END
                                                                                                              ELSE
                                                                                                               decode(cop.flg_status, g_comm_order_plan_ongoing, cop.flg_status, NULL)
                                                                                                          END,
                                                                                                          CASE
                                                                                                              WHEN (l_id_task_type = pk_alert_constant.g_task_comm_orders AND
                                                                                                                   i_flg_new_wf_comm_order = pk_alert_constant.g_no) THEN
                                                                                                               NULL
                                                                                                              ELSE
                                                                                                               cop.dt_plan_tstz
                                                                                                          END,
                                                                                                          cop.dt_take_tstz,
                                                                                                          CASE
                                                                                                              WHEN (l_id_task_type = pk_alert_constant.g_task_comm_orders AND
                                                                                                                   i_flg_new_wf_comm_order = pk_alert_constant.g_no) THEN
                                                                                                               NULL
                                                                                                              ELSE
                                                                                                               cor.task_duration
                                                                                                          END,
                                                                                                          cor.id_status),
                                                   pk_ea_logic_comm_orders.get_comm_order_plan_status_msg(i_lang,
                                                                                                          i_prof,
                                                                                                          CASE
                                                                                                              WHEN cor.flg_prn = pk_alert_constant.g_no THEN
                                                                                                               CASE
                                                                                                                   WHEN (l_id_task_type = pk_alert_constant.g_task_comm_orders AND
                                                                                                                        i_flg_new_wf_comm_order = pk_alert_constant.g_no) THEN
                                                                                                                    decode(cop.flg_status, g_comm_order_plan_req, g_comm_order_plan_ongoing, cop.flg_status)
                                                                                                                   ELSE
                                                                                                                    cop.flg_status
                                                                                                               END
                                                                                                              ELSE
                                                                                                               decode(cop.flg_status, g_comm_order_plan_ongoing, cop.flg_status, NULL)
                                                                                                          END,
                                                                                                          CASE
                                                                                                              WHEN (l_id_task_type = pk_alert_constant.g_task_comm_orders AND
                                                                                                                   i_flg_new_wf_comm_order = pk_alert_constant.g_no) THEN
                                                                                                               NULL
                                                                                                              ELSE
                                                                                                               cop.dt_plan_tstz
                                                                                                          END,
                                                                                                          cop.dt_take_tstz,
                                                                                                          CASE
                                                                                                              WHEN (l_id_task_type = pk_alert_constant.g_task_comm_orders AND
                                                                                                                   i_flg_new_wf_comm_order = pk_alert_constant.g_no) THEN
                                                                                                               NULL
                                                                                                              ELSE
                                                                                                               cor.task_duration
                                                                                                          END,
                                                                                                          cor.id_status),
                                                   pk_ea_logic_comm_orders.get_comm_order_plan_stat_icon(i_lang,
                                                                                                         i_prof,
                                                                                                         CASE
                                                                                                             WHEN cor.flg_prn = pk_alert_constant.g_no THEN
                                                                                                              CASE
                                                                                                                  WHEN (l_id_task_type = pk_alert_constant.g_task_comm_orders AND
                                                                                                                       i_flg_new_wf_comm_order = pk_alert_constant.g_no) THEN
                                                                                                                   decode(cop.flg_status, g_comm_order_plan_req, g_comm_order_plan_ongoing, cop.flg_status)
                                                                                                                  ELSE
                                                                                                                   cop.flg_status
                                                                                                              END
                                                                                                             ELSE
                                                                                                              decode(cop.flg_status, g_comm_order_plan_ongoing, cop.flg_status, NULL)
                                                                                                         END,
                                                                                                         CASE
                                                                                                             WHEN (l_id_task_type = pk_alert_constant.g_task_comm_orders AND
                                                                                                                  i_flg_new_wf_comm_order = pk_alert_constant.g_no) THEN
                                                                                                              NULL
                                                                                                             ELSE
                                                                                                              cop.dt_plan_tstz
                                                                                                         END,
                                                                                                         cop.dt_take_tstz,
                                                                                                         CASE
                                                                                                             WHEN (l_id_task_type = pk_alert_constant.g_task_comm_orders AND
                                                                                                                  i_flg_new_wf_comm_order = pk_alert_constant.g_no) THEN
                                                                                                              NULL
                                                                                                             ELSE
                                                                                                              cor.task_duration
                                                                                                         END,
                                                                                                         cor.id_status),
                                                   pk_ea_logic_comm_orders.get_comm_order_plan_status_flg(i_lang,
                                                                                                          i_prof,
                                                                                                          CASE
                                                                                                              WHEN cor.flg_prn = pk_alert_constant.g_no THEN
                                                                                                               CASE
                                                                                                                   WHEN (l_id_task_type = pk_alert_constant.g_task_comm_orders AND
                                                                                                                        i_flg_new_wf_comm_order = pk_alert_constant.g_no) THEN
                                                                                                                    decode(cop.flg_status, g_comm_order_plan_req, g_comm_order_plan_ongoing, cop.flg_status)
                                                                                                                   ELSE
                                                                                                                    cop.flg_status
                                                                                                               END
                                                                                                              ELSE
                                                                                                               decode(cop.flg_status, g_comm_order_plan_ongoing, cop.flg_status, NULL)
                                                                                                          END,
                                                                                                          CASE
                                                                                                              WHEN (l_id_task_type = pk_alert_constant.g_task_comm_orders AND
                                                                                                                   i_flg_new_wf_comm_order = pk_alert_constant.g_no) THEN
                                                                                                               NULL
                                                                                                              ELSE
                                                                                                               cop.dt_plan_tstz
                                                                                                          END,
                                                                                                          cop.dt_take_tstz,
                                                                                                          CASE
                                                                                                              WHEN (l_id_task_type = pk_alert_constant.g_task_comm_orders AND
                                                                                                                   i_flg_new_wf_comm_order = pk_alert_constant.g_no) THEN
                                                                                                               NULL
                                                                                                              ELSE
                                                                                                               cor.task_duration
                                                                                                          END,
                                                                                                          cor.id_status))
                  INTO l_status_string
                  FROM comm_order_req cor
                 INNER JOIN comm_order_plan cop
                    ON cor.id_comm_order_req = cop.id_comm_order_req
                 WHERE cop.id_comm_order_plan = l_comm_order_plan;
            ELSE
                l_status_string := pk_utils.get_status_string_immediate(i_lang         => i_lang,
                                                                        i_prof         => i_prof,
                                                                        i_display_type => pk_alert_constant.g_display_type_icon,
                                                                        i_flg_state    => i_id_status,
                                                                        i_back_color   => l_back_color,
                                                                        i_value_icon   => g_code_status);
            END IF;
        
        ELSE
            -- if communication order is ongoing and start date is greater than current timestamp,
            -- show countdown icon with green background color
            g_error := 'Call pk_utils.get_status_string_immediate ';
            IF i_id_status = g_id_sts_ongoing
               AND i_dt_begin > l_sysdate
            THEN
            
                l_status_string := pk_utils.get_status_string_immediate(i_lang          => i_lang,
                                                                        i_prof          => i_prof,
                                                                        i_display_type  => pk_alert_constant.g_display_type_date,
                                                                        i_value_date    => pk_date_utils.to_char_insttimezone(i_prof,
                                                                                                                              i_dt_begin,
                                                                                                                              pk_alert_constant.g_dt_yyyymmddhh24miss_tzr),
                                                                        i_back_color    => l_back_color,
                                                                        i_message_color => l_message_color,
                                                                        i_dt_server     => l_sysdate);
            
            ELSE
                SELECT cor.flg_prn
                  INTO l_flg_prn
                  FROM comm_order_req cor
                 WHERE cor.id_comm_order_req = i_id_comm_order_req;
            
                IF l_flg_prn = pk_alert_constant.g_yes
                   AND i_id_status = g_id_sts_ongoing
                THEN
                    l_status_string := pk_utils.get_status_string_immediate(i_lang         => i_lang,
                                                                            i_prof         => i_prof,
                                                                            i_display_type => pk_alert_constant.g_display_type_icon,
                                                                            i_flg_state    => pk_alert_constant.g_yes,
                                                                            i_back_color   => pk_alert_constant.g_color_null,
                                                                            i_value_icon   => 'COMM_ORDER_REQ.FLG_PRN');
                ELSE
                
                    l_status_string := pk_utils.get_status_string_immediate(i_lang         => i_lang,
                                                                            i_prof         => i_prof,
                                                                            i_display_type => pk_alert_constant.g_display_type_icon,
                                                                            i_flg_state    => i_id_status,
                                                                            i_back_color   => l_back_color,
                                                                            i_value_icon   => g_code_status);
                END IF;
            END IF;
        END IF;
    
        RETURN l_status_string;
    END get_comm_order_status_string;

    FUNCTION get_comm_order_type_desc
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_concept_type IN comm_order_req.id_concept_type%TYPE
    ) RETURN VARCHAR2 IS
    
        l_comm_type_desc VARCHAR2(1000 CHAR);
    
    BEGIN
    
        -- get communication type description
        SELECT pk_translation.get_translation(i_lang, ct.code_concept_type_name)
          INTO l_comm_type_desc
          FROM concept_type ct
         WHERE ct.id_concept_type = i_concept_type;
    
        -- return communication order title
        RETURN l_comm_type_desc;
    
    END get_comm_order_type_desc;

    FUNCTION get_comm_order_path_bound_desc
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_concept_path IN comm_order_ea.concept_path%TYPE
    ) RETURN CLOB IS
    
        l_prof_cat_id category.id_category%TYPE := pk_prof_utils.get_id_category(i_lang, i_prof);
        l_market      market.id_market%TYPE := pk_utils.get_institution_market(i_lang, i_prof.institution);
    
        l_tbl_cpt_vrs_uids table_varchar;
        l_comm_order_path  CLOB;
    
        CURSOR c_path_descs IS
            SELECT /*+opt_estimate (table t rows=1)*/
             t.column_value AS cpt_vrs_uid,
             pk_translation.get_translation(i_lang, coea.code_concept_term) AS desc_comm_order
              FROM TABLE(CAST(l_tbl_cpt_vrs_uids AS table_varchar)) t
              JOIN comm_order_ea coea
                ON coea.cpt_vrs_uid = t.column_value
             WHERE coea.id_market IN (pk_alert_constant.g_id_market_all, l_market)
               AND coea.id_institution_term_vers IN (pk_alert_constant.g_inst_all, i_prof.institution)
               AND coea.id_institution_conc_term IN (pk_alert_constant.g_inst_all, i_prof.institution)
               AND coea.id_software_term_vers IN (pk_alert_constant.g_soft_all, i_prof.software)
               AND coea.id_software_conc_term IN (pk_alert_constant.g_soft_all, i_prof.software)
               AND coea.id_category_cncpt_vers IN (pk_ea_logic_comm_orders.k_category_minus_one, l_prof_cat_id)
               AND coea.id_category_cncpt_term IN (pk_ea_logic_comm_orders.k_category_minus_one, l_prof_cat_id);
    
        TYPE t_comm_order_path IS TABLE OF c_path_descs%ROWTYPE;
        l_comm_order_path_desc t_comm_order_path;
    
    BEGIN
    
        l_comm_order_path := to_clob(i_concept_path);
    
        -- get all concept version uids
        l_tbl_cpt_vrs_uids := pk_string_utils.str_split(i_concept_path, ' > ');
    
        -- get description of all concept version uids
        OPEN c_path_descs;
        FETCH c_path_descs BULK COLLECT
            INTO l_comm_order_path_desc;
        CLOSE c_path_descs;
    
        -- loop all concept version uids and replace them with description
        FOR i IN 1 .. l_comm_order_path_desc.count
        LOOP
            l_comm_order_path := REPLACE(l_comm_order_path,
                                         l_comm_order_path_desc(i).cpt_vrs_uid,
                                         l_comm_order_path_desc(i).desc_comm_order);
        END LOOP;
    
        -- return communication order path
        RETURN l_comm_order_path;
    
    END get_comm_order_path_bound_desc;

    FUNCTION get_comm_order_path
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_concept_type         IN comm_order_req.id_concept_type%TYPE,
        i_concept_term         IN comm_order_req.id_concept_term%TYPE,
        i_cncpt_trm_inst_owner IN comm_order_req.id_cncpt_trm_inst_owner%TYPE,
        i_concept_version      IN comm_order_req.id_concept_version%TYPE,
        i_cncpt_vrs_inst_owner IN comm_order_req.id_cncpt_vrs_inst_owner%TYPE,
        i_task_type            IN comm_order_req.id_task_type%TYPE
    ) RETURN VARCHAR2 IS
    
        l_prof_cat_id category.id_category%TYPE := pk_prof_utils.get_id_category(i_lang, i_prof);
        l_market      market.id_market%TYPE := pk_utils.get_institution_market(i_lang, i_prof.institution);
    
        l_comm_order_path comm_order_ea.concept_path%TYPE;
    
    BEGIN
    
        -- get comm order path
        BEGIN
            SELECT get_comm_order_path_bound_desc(i_lang, i_prof, coea.concept_path)
              INTO l_comm_order_path
              FROM comm_order_ea coea
             WHERE coea.id_concept_type = i_concept_type
               AND coea.id_concept_term = i_concept_term
               AND coea.id_cncpt_trm_inst_owner = i_cncpt_trm_inst_owner
               AND coea.id_market IN (pk_alert_constant.g_id_market_all, l_market)
               AND coea.id_institution_term_vers IN (pk_alert_constant.g_inst_all, i_prof.institution)
               AND coea.id_institution_conc_term IN (pk_alert_constant.g_inst_all, i_prof.institution)
               AND coea.id_software_term_vers IN (pk_alert_constant.g_soft_all, i_prof.software)
               AND coea.id_software_conc_term IN (pk_alert_constant.g_soft_all, i_prof.software)
               AND coea.id_category_cncpt_vers IN (pk_ea_logic_comm_orders.k_category_minus_one, l_prof_cat_id)
               AND coea.id_category_cncpt_term IN (pk_ea_logic_comm_orders.k_category_minus_one, l_prof_cat_id);
        EXCEPTION
            WHEN OTHERS THEN
            
                -- if the concept does not exists on COMM_ORDER_EA table available for this institution, 
                -- get concept path directly from terminology server
                l_comm_order_path := pk_ea_logic_comm_orders.get_concept_path_desc(i_lang               => i_lang,
                                                                                   i_id_concept_version => i_concept_version,
                                                                                   i_id_inst_owner      => i_cncpt_vrs_inst_owner,
                                                                                   i_id_concept_type    => i_concept_type,
                                                                                   i_id_task_type       => i_task_type);
            
        END;
    
        -- return communication order path
        RETURN l_comm_order_path;
    
    END get_comm_order_path;

    FUNCTION get_comm_order_title
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_concept_type             IN comm_order_req.id_concept_type%TYPE,
        i_concept_term             IN comm_order_req.id_concept_term%TYPE,
        i_cncpt_trm_inst_owner     IN comm_order_req.id_cncpt_trm_inst_owner%TYPE,
        i_concept_version          IN comm_order_req.id_concept_version%TYPE,
        i_cncpt_vrs_inst_owner     IN comm_order_req.id_cncpt_vrs_inst_owner%TYPE,
        i_flg_free_text            IN comm_order_req.flg_free_text%TYPE,
        i_desc_concept_term        IN pk_translation.t_lob_char,
        i_task_type                IN comm_order_req.id_task_type%TYPE,
        i_flg_bold_title           IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_show_comm_order_type IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_trunc_clobs          IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_escape_char          IN VARCHAR2 DEFAULT pk_alert_constant.g_yes
    ) RETURN VARCHAR2 IS
    
        l_format_bold_string VARCHAR2(10 CHAR) := (CASE i_flg_bold_title
                                                      WHEN pk_alert_constant.g_yes THEN
                                                       '<b>@</b>'
                                                      ELSE
                                                       '@'
                                                  END);
    
        l_comm_order_desc CLOB;
        l_comm_order_path VARCHAR2(1000 CHAR);
    
    BEGIN
    
        -- check if communication order description is free text or not
        IF i_flg_free_text = pk_alert_constant.g_no
        THEN
        
            -- get communication order path
            l_comm_order_path := get_comm_order_path(i_lang                 => i_lang,
                                                     i_prof                 => i_prof,
                                                     i_concept_type         => i_concept_type,
                                                     i_concept_term         => i_concept_term,
                                                     i_cncpt_trm_inst_owner => i_cncpt_trm_inst_owner,
                                                     i_concept_version      => i_concept_version,
                                                     i_cncpt_vrs_inst_owner => i_cncpt_vrs_inst_owner,
                                                     i_task_type            => i_task_type);
        
            -- truncate comm order path                                               
            IF l_comm_order_path IS NOT NULL
               AND i_flg_trunc_clobs = pk_alert_constant.g_yes
            THEN
                l_comm_order_path := trunc_clob_to_varchar2(l_comm_order_path, g_trunc_clob_max_size);
            END IF;
        
            -- get communication order title
            SELECT to_clob(pk_translation.get_translation(i_lang, cttt.code_concept_term)) AS task_desc
              INTO l_comm_order_desc
              FROM concept_term_task_type cttt
             WHERE cttt.id_concept_term = i_concept_term
               AND cttt.id_cncpt_trm_inst_owner = i_cncpt_trm_inst_owner
               AND cttt.id_task_type = i_task_type;
        
            -- truncate comm order description
            IF i_flg_trunc_clobs = pk_alert_constant.g_yes
            THEN
                l_comm_order_desc := trunc_clob_to_varchar2(l_comm_order_desc, g_trunc_clob_max_size);
            END IF;
        
            -- concat concept path to comm order description
            IF l_comm_order_path IS NOT NULL
            THEN
                l_comm_order_desc := l_comm_order_path || ' > ' || l_comm_order_desc;
            END IF;
        
        ELSE
            -- check if comm order (free text) description must be truncated
            IF i_flg_trunc_clobs = pk_alert_constant.g_yes
            THEN
                -- truncate comm order (free text) description
                l_comm_order_desc := trunc_clob_to_varchar2(i_desc_concept_term, g_trunc_clob_max_size);
            ELSE
                -- concat comm order (free text) description
                l_comm_order_desc := i_desc_concept_term;
            END IF;
        
        END IF;
    
        -- append communication order type if necessary
        IF i_flg_show_comm_order_type = pk_alert_constant.g_yes
        THEN
        
            l_comm_order_desc := get_comm_order_type_desc(i_lang         => i_lang,
                                                          i_prof         => i_prof,
                                                          i_concept_type => i_concept_type) || ' - ' ||
                                 l_comm_order_desc;
        END IF;
    
        IF i_flg_escape_char = pk_alert_constant.g_yes
        THEN
            l_comm_order_desc := htf.escape_sc(l_comm_order_desc);
        END IF;
    
        -- format description in bold if necessary
        l_comm_order_desc := REPLACE(l_format_bold_string, '@', l_comm_order_desc);
    
        -- return communication order title
        RETURN l_comm_order_desc;
    
    END get_comm_order_title;

    FUNCTION get_comm_order_notes
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_notes           IN pk_translation.t_lob_char,
        i_flg_trunc_clobs IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_flg_escape_char IN VARCHAR2 DEFAULT pk_alert_constant.g_yes
    ) RETURN CLOB IS
    
        l_result CLOB;
    
    BEGIN
    
        g_error := 'i_flg_trunc_clobs ';
        IF i_flg_trunc_clobs = pk_alert_constant.g_yes
        THEN
            l_result := trunc_clob_to_varchar2(i_notes, g_trunc_clob_max_size);
        ELSE
            l_result := i_notes;
        END IF;
    
        g_error := 'i_flg_escape_char ';
        IF i_flg_escape_char = pk_alert_constant.g_yes
        THEN
            l_result := htf.escape_sc(l_result);
        END IF;
    
        -- return communication order instructions
        RETURN l_result;
    
    END get_comm_order_notes;

    FUNCTION get_comm_order_instr
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_flg_priority    IN comm_order_req.flg_priority%TYPE,
        i_flg_prn         IN comm_order_req.flg_prn%TYPE,
        i_prn_condition   IN comm_order_req.prn_condition%TYPE,
        i_dt_begin        IN comm_order_req.dt_begin%TYPE,
        i_flg_trunc_clobs IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_escape_char IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_flg_report      IN VARCHAR2 DEFAULT 'N'
    ) RETURN CLOB IS
    
        l_comm_order_desc CLOB;
    
    BEGIN
    
        -- concat priority field value if not empty
        g_error := 'i_flg_priority ';
        IF i_flg_priority IS NOT NULL
        THEN
            l_comm_order_desc := pk_message.get_message(i_lang, 'COMM_ORDER_T011') || ' ' ||
                                 pk_sysdomain.get_domain(i_code_dom => g_code_priority,
                                                         i_val      => i_flg_priority,
                                                         i_lang     => i_lang) || g_str_separator;
        END IF;
    
        -- concat prn field value if not empty
        g_error := 'i_flg_prn ';
        IF i_flg_prn IS NOT NULL
        THEN
            l_comm_order_desc := l_comm_order_desc || pk_message.get_message(i_lang, 'COMM_ORDER_T012') || ' ' ||
                                 pk_sysdomain.get_domain(i_code_dom => g_code_prn, i_val => i_flg_prn, i_lang => i_lang) ||
                                 g_str_separator;
        END IF;
    
        -- concat prn condition field value if not empty
        g_error := 'i_prn_condition ';
        IF i_prn_condition IS NOT NULL
           AND length(i_prn_condition) > 0
        THEN
            l_comm_order_desc := l_comm_order_desc || pk_message.get_message(i_lang, 'COMM_ORDER_T013') || ' ' || (CASE
                                     WHEN i_flg_trunc_clobs = pk_alert_constant.g_yes THEN
                                      trunc_clob_to_varchar2(i_prn_condition, g_trunc_clob_max_size)
                                     ELSE
                                      i_prn_condition
                                 END) || g_str_separator;
        END IF;
    
        -- concat start date field value if not empty
        g_error := 'i_dt_begin ';
    
        IF i_dt_begin IS NOT NULL
           AND i_flg_report != pk_alert_constant.g_yes
        THEN
            l_comm_order_desc := l_comm_order_desc || pk_message.get_message(i_lang, 'COMM_ORDER_T014') || ' ' ||
                                 pk_date_utils.dt_chr_date_hour_tsz(i_lang, i_dt_begin, i_prof) || g_str_separator;
        END IF;
    
        -- remove last separator and escape html characters
        g_error           := 'regexp_replace ';
        l_comm_order_desc := regexp_replace(l_comm_order_desc, '(' || g_str_separator || ')*$', '');
    
        g_error := 'i_flg_escape_char ';
        IF i_flg_escape_char = pk_alert_constant.g_yes
        THEN
            l_comm_order_desc := htf.escape_sc(l_comm_order_desc);
        END IF;
    
        -- return communication order instructions
        RETURN l_comm_order_desc;
    
    END get_comm_order_instr;

    FUNCTION get_comm_order_desc
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_concept_type             IN comm_order_req.id_concept_type%TYPE,
        i_concept_term             IN comm_order_req.id_concept_term%TYPE,
        i_cncpt_trm_inst_owner     IN comm_order_req.id_cncpt_trm_inst_owner%TYPE,
        i_concept_version          IN comm_order_req.id_concept_version%TYPE,
        i_cncpt_vrs_inst_owner     IN comm_order_req.id_cncpt_vrs_inst_owner%TYPE,
        i_flg_free_text            IN comm_order_req.flg_free_text%TYPE,
        i_desc_concept_term        IN pk_translation.t_lob_char,
        i_notes                    IN pk_translation.t_lob_char,
        i_flg_priority             IN comm_order_req.flg_priority%TYPE,
        i_flg_prn                  IN comm_order_req.flg_prn%TYPE,
        i_prn_condition            IN pk_translation.t_lob_char,
        i_dt_begin                 IN comm_order_req.dt_begin%TYPE,
        i_task_type                IN comm_order_req.id_task_type%TYPE,
        i_flg_bold_title           IN VARCHAR2 DEFAULT 'N',
        i_flg_show_comm_order_type IN VARCHAR2 DEFAULT 'N',
        i_flg_trunc_clobs          IN VARCHAR2 DEFAULT 'N',
        i_flg_report               IN VARCHAR2 DEFAULT 'N'
    ) RETURN CLOB IS
    
        l_comm_order_desc CLOB;
    
    BEGIN
    
        -- get communication order title
        l_comm_order_desc := get_comm_order_title(i_lang                     => i_lang,
                                                  i_prof                     => i_prof,
                                                  i_concept_type             => i_concept_type,
                                                  i_concept_term             => i_concept_term,
                                                  i_cncpt_trm_inst_owner     => i_cncpt_trm_inst_owner,
                                                  i_concept_version          => i_concept_version,
                                                  i_cncpt_vrs_inst_owner     => i_cncpt_vrs_inst_owner,
                                                  i_flg_free_text            => i_flg_free_text,
                                                  i_desc_concept_term        => i_desc_concept_term,
                                                  i_task_type                => i_task_type,
                                                  i_flg_bold_title           => i_flg_bold_title,
                                                  i_flg_show_comm_order_type => i_flg_show_comm_order_type,
                                                  i_flg_trunc_clobs          => i_flg_trunc_clobs);
    
        -- concat notes field if not empty and escape html characters
        IF i_flg_report != pk_alert_constant.g_yes
        THEN
            IF i_notes IS NOT NULL
               AND length(i_notes) > 0
            THEN
                l_comm_order_desc := l_comm_order_desc || chr(10) ||
                                     get_comm_order_notes(i_lang            => i_lang,
                                                          i_prof            => i_prof,
                                                          i_notes           => i_notes,
                                                          i_flg_trunc_clobs => i_flg_trunc_clobs,
                                                          i_flg_escape_char => pk_alert_constant.g_yes);
            END IF;
        
            -- concat communication order instructions
        
            l_comm_order_desc := l_comm_order_desc || chr(10) ||
                                 get_comm_order_instr(i_lang            => i_lang,
                                                      i_prof            => i_prof,
                                                      i_flg_priority    => i_flg_priority,
                                                      i_flg_prn         => i_flg_prn,
                                                      i_prn_condition   => i_prn_condition,
                                                      i_dt_begin        => i_dt_begin,
                                                      i_flg_trunc_clobs => i_flg_trunc_clobs);
        END IF;
    
        -- return communication order title
        RETURN l_comm_order_desc;
    
    END get_comm_order_desc;

    FUNCTION check_mandatory_fields
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_comm_order_req IN comm_order_req.id_comm_order_req%TYPE,
        i_id_episode        IN comm_order_req.id_episode%TYPE
    ) RETURN VARCHAR2 IS
    
        l_error            t_error_out;
        l_result           VARCHAR2(1 CHAR);
        l_flg_prof_need_cs VARCHAR2(1 CHAR);
        l_co_sign_data     t_table_co_sign;
        l_count            PLS_INTEGER;
    
    BEGIN
    
        -- check if co-sign is required for this professional
        g_error  := 'Call pk_co_sign_api.check_prof_needs_cosign ';
        g_retval := pk_co_sign_api.check_prof_needs_cosign(i_lang                   => i_lang,
                                                           i_prof                   => i_prof,
                                                           i_episode                => i_id_episode,
                                                           i_task_type              => pk_alert_constant.g_task_comm_orders,
                                                           i_cosign_def_action_type => NULL,
                                                           i_action                 => g_cs_action_add, -- order co-sign
                                                           o_flg_prof_need_cosign   => l_flg_prof_need_cs,
                                                           o_error                  => l_error);
    
        IF l_flg_prof_need_cs = pk_alert_constant.g_yes
        THEN
        
            -- get co-sign data
            g_error        := 'Call pk_co_sign_api.tf_co_sign_tasks_info ';
            l_co_sign_data := pk_co_sign_api.tf_co_sign_tasks_info(i_lang          => i_lang,
                                                                   i_prof          => i_prof,
                                                                   i_episode       => i_id_episode,
                                                                   i_task_type     => pk_alert_constant.g_task_comm_orders,
                                                                   i_id_task_group => i_id_comm_order_req);
        
            -- check if has co-sign for add/edit actions
            g_error := 'SELECT COUNT(1) ';
            SELECT COUNT(1)
              INTO l_count
              FROM (SELECT /*+opt_estimate (table t rows=1)*/
                     row_number() over(ORDER BY dt_req DESC) rn, t.*
                      FROM TABLE(l_co_sign_data) t
                     WHERE t.id_action IN (g_cs_action_edit, g_cs_action_add)) cs
             WHERE cs.rn = 1;
        
            g_error := 'l_count=' || l_count;
            IF l_count > 0
            THEN
                l_result := pk_alert_constant.g_yes; -- all mandatory fields are filled
            ELSE
                l_result := pk_alert_constant.g_no;
            END IF;
        
        ELSE
            -- professional does not need co-sign, there are no mandatory fields
            l_result := pk_alert_constant.g_yes; -- all mandatory fields are filled
        END IF;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN pk_alert_constant.g_no;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'CHECK_MANDATORY_FIELDS',
                                              o_error    => l_error);
            RETURN pk_alert_constant.g_no;
    END check_mandatory_fields;

    FUNCTION get_instr_bg_color
    (
        i_flg_need_ack   IN comm_order_req.flg_need_ack%TYPE,
        i_comm_order_req comm_order_req.id_comm_order_req%TYPE
    ) RETURN VARCHAR2 IS
    
        l_result VARCHAR2(10 CHAR);
    
        l_count NUMBER(24) := 0;
    BEGIN
    
        IF i_flg_need_ack = pk_alert_constant.g_yes
        THEN
            SELECT COUNT(1)
              INTO l_count
              FROM comm_order_req cor
             WHERE cor.id_comm_order_req = i_comm_order_req
               AND cor.flg_action = pk_comm_orders.g_action_ack;
            IF l_count = 0
            THEN
                SELECT COUNT(1)
                  INTO l_count
                  FROM comm_order_req_hist corh
                 WHERE corh.id_comm_order_req = i_comm_order_req
                   AND corh.flg_action = pk_comm_orders.g_action_ack;
            END IF;
            IF l_count = 0
            THEN
                l_result := g_color_bg_acknowledged;
            END IF;
        END IF;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error('GET_INSTR_BG_COLOR / ' || SQLERRM);
            RETURN NULL;
    END get_instr_bg_color;

    FUNCTION get_instr_fg_color(i_flg_need_ack IN comm_order_req.flg_need_ack%TYPE) RETURN VARCHAR2 IS
    
        l_result VARCHAR2(10 CHAR);
    
    BEGIN
    
        IF i_flg_need_ack = pk_alert_constant.g_yes
        THEN
            l_result := g_color_fg_acknowledged;
        END IF;
    
        RETURN l_result;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error('GET_INSTR_FG_COLOR / ' || SQLERRM);
            RETURN NULL;
    END get_instr_fg_color;

    FUNCTION get_instr_bg_alpha(i_flg_need_ack IN comm_order_req.flg_need_ack%TYPE) RETURN VARCHAR2 IS
    
        l_result VARCHAR2(10 CHAR);
    
    BEGIN
    
        IF i_flg_need_ack = pk_alert_constant.g_yes
        THEN
            l_result := g_color_bg_alpha;
        END IF;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error('GET_INSTR_BG_ALPHA / ' || SQLERRM);
            RETURN NULL;
    END get_instr_bg_alpha;

    FUNCTION get_edit_icon
    (
        i_id_comm_order_req IN comm_order_req.id_comm_order_req%TYPE,
        i_flg_need_ack      IN comm_order_req.flg_need_ack%TYPE,
        i_flg_action        IN comm_order_req.flg_action%TYPE
    ) RETURN VARCHAR2 IS
    
        l_result     VARCHAR2(30 CHAR);
        l_flg_action comm_order_req.flg_action%TYPE;
    
    BEGIN
    
        IF i_flg_need_ack = pk_alert_constant.g_yes
        THEN
        
            g_error := 'i_flg_action ';
            IF i_flg_action = g_action_ack
            THEN
            
                -- getting the last action done in this comm order req (except the acknowledgement)             
                SELECT flg_action
                  INTO l_flg_action
                  FROM (SELECT row_number() over(ORDER BY dt_status DESC) AS rn, corh.flg_action
                          FROM comm_order_req_hist corh
                         WHERE corh.id_comm_order_req = i_id_comm_order_req
                           AND NOT EXISTS (SELECT 1
                                  FROM comm_order_req_ack cora
                                 WHERE cora.id_comm_order_req_hist = corh.id_comm_order_req_hist)) t
                 WHERE rn = 1; -- return the last action only
            
                IF l_flg_action = g_action_edition
                THEN
                    l_result := g_icon_edited_info;
                END IF;
            
            ELSIF i_flg_action = g_action_edition
            THEN
                l_result := g_icon_edited_info;
            END IF;
        END IF;
    
        RETURN l_result;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error('GET_EDIT_ICON / ' || g_error || ' / ' || SQLERRM);
            RETURN NULL;
    END get_edit_icon;

    FUNCTION get_comm_order_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_task_request   IN table_number,
        i_filter_tstz    IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_filter_status  IN table_varchar,
        i_flg_report     IN VARCHAR2 DEFAULT 'N',
        i_cpoe_task_type IN cpoe_task_type.id_task_type%TYPE DEFAULT NULL,
        i_dt_begin       IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_dt_end         IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_plan_list      OUT pk_types.cursor_type,
        o_task_list      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -- wf
        l_id_category         category.id_category%TYPE;
        l_id_profile_template profile_template.id_profile_template%TYPE;
    
        l_task_type task_type.id_task_type%TYPE;
    
        l_sys_cfg_old_wf sys_config.value%TYPE := pk_sysconfig.get_config(i_prof    => i_prof,
                                                                          i_code_cf => 'COMMUNICATION_ORDERS_SCREEN_NEW');
    
        l_cancelled_task_filter_interval sys_config.value%TYPE := pk_sysconfig.get_config('CPOE_CANCELLED_TASK_FILTER_INTERVAL',
                                                                                          i_prof);
        l_cancelled_task_filter_tstz     TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
    
        l_cancelled_task_filter_tstz := current_timestamp -
                                        numtodsinterval(to_number(l_cancelled_task_filter_interval), 'DAY');
    
        SELECT a.id_target_task_type
          INTO l_task_type
          FROM cpoe_task_type a
         WHERE a.id_task_type = i_cpoe_task_type;
    
        l_id_category         := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
        l_id_profile_template := pk_tools.get_prof_profile_template(i_prof);
    
        OPEN o_task_list FOR
            SELECT pk_alert_constant.g_task_type_com_order AS task_type,
                   to_char(get_comm_order_desc(i_lang                     => i_lang,
                                               i_prof                     => i_prof,
                                               i_concept_type             => cor.id_concept_type,
                                               i_concept_term             => cor.id_concept_term,
                                               i_cncpt_trm_inst_owner     => cor.id_cncpt_trm_inst_owner,
                                               i_concept_version          => cor.id_concept_version,
                                               i_cncpt_vrs_inst_owner     => cor.id_cncpt_vrs_inst_owner,
                                               i_flg_free_text            => cor.flg_free_text,
                                               i_desc_concept_term        => pk_translation.get_translation_trs(cor.desc_concept_term),
                                               i_notes                    => pk_translation.get_translation_trs(cor.notes),
                                               i_flg_priority             => cor.flg_priority,
                                               i_flg_prn                  => cor.flg_prn,
                                               i_prn_condition            => pk_translation.get_translation_trs(cor.prn_condition),
                                               i_dt_begin                 => cor.dt_begin,
                                               i_task_type                => cor.id_task_type,
                                               i_flg_bold_title           => CASE i_flg_report
                                                                                 WHEN pk_alert_constant.g_yes THEN
                                                                                  pk_alert_constant.g_no
                                                                                 ELSE
                                                                                  pk_alert_constant.g_yes
                                                                             END,
                                               i_flg_show_comm_order_type => pk_alert_constant.g_yes,
                                               i_flg_trunc_clobs          => pk_alert_constant.g_yes,
                                               i_flg_report               => i_flg_report)) AS task_description,
                   cor.id_professional AS id_professional, -- ALERT-283519
                   NULL AS icon_warning,
                   get_comm_order_status_string(i_lang                  => i_lang,
                                                i_prof                  => i_prof,
                                                i_id_comm_order_req     => cor.id_comm_order_req,
                                                i_id_status             => cor.id_status,
                                                i_dt_begin              => cor.dt_begin,
                                                i_flg_need_ack          => cor.flg_need_ack,
                                                i_flg_new_wf_comm_order => l_sys_cfg_old_wf) AS status_string,
                   cor.id_comm_order_req AS id_request,
                   cor.dt_begin AS start_date_tstz,
                   NULL AS end_date_tstz,
                   nvl(cor.dt_last_update_tstz, cor.dt_status) AS create_date_tstz, -- ALERT-283519
                   cor.id_status AS flg_status,
                   check_transition(i_lang                => i_lang,
                                    i_prof                => i_prof,
                                    i_id_workflow         => cor.id_workflow,
                                    i_id_status_begin     => cor.id_status,
                                    i_id_status_end       => g_id_sts_canceled,
                                    i_id_workflow_action  => g_id_action_cancel,
                                    i_id_category         => l_id_category,
                                    i_id_profile_template => l_id_profile_template,
                                    i_id_comm_order_req   => cor.id_comm_order_req,
                                    i_dt_begin            => cor.dt_begin) AS flg_cancel,
                   (CASE
                        WHEN (cor.id_status = g_id_sts_draft AND
                             check_mandatory_fields(i_lang              => i_lang,
                                                     i_prof              => i_prof,
                                                     i_id_comm_order_req => cor.id_comm_order_req,
                                                     i_id_episode        => cor.id_episode) = pk_alert_constant.g_no) THEN
                         pk_alert_constant.g_yes
                        ELSE
                         pk_alert_constant.g_no
                    END) AS flg_conflict,
                   cor.id_comm_order_req AS id_task,
                   get_comm_order_title(i_lang                     => i_lang,
                                        i_prof                     => i_prof,
                                        i_concept_type             => cor.id_concept_type,
                                        i_concept_term             => cor.id_concept_term,
                                        i_cncpt_trm_inst_owner     => cor.id_cncpt_trm_inst_owner,
                                        i_concept_version          => cor.id_concept_version,
                                        i_cncpt_vrs_inst_owner     => cor.id_cncpt_vrs_inst_owner,
                                        i_flg_free_text            => cor.flg_free_text,
                                        i_desc_concept_term        => pk_translation.get_translation_trs(cor.desc_concept_term),
                                        i_task_type                => cor.id_task_type,
                                        i_flg_show_comm_order_type => pk_alert_constant.g_yes,
                                        i_flg_trunc_clobs          => pk_alert_constant.g_yes) AS task_title,
                   decode(i_flg_report,
                          pk_alert_constant.g_yes,
                          to_char(get_comm_order_instr(i_lang            => i_lang,
                                                       i_prof            => i_prof,
                                                       i_flg_priority    => cor.flg_priority,
                                                       i_flg_prn         => cor.flg_prn,
                                                       i_prn_condition   => pk_translation.get_translation_trs(cor.prn_condition),
                                                       i_dt_begin        => cor.dt_begin,
                                                       i_flg_trunc_clobs => pk_alert_constant.g_yes,
                                                       i_flg_report      => i_flg_report))) AS task_instructions,
                   decode(i_flg_report, pk_alert_constant.g_yes, pk_translation.get_translation_trs(cor.notes)) AS task_notes,
                   NULL AS drug_dose,
                   NULL AS drug_route,
                   NULL AS drug_take_in_case,
                   decode(i_flg_report,
                          pk_alert_constant.g_yes,
                          get_comm_order_req_sts_desc(i_lang              => i_lang,
                                                      i_prof              => i_prof,
                                                      i_id_status         => cor.id_status,
                                                      i_dt_begin          => cor.dt_begin,
                                                      i_id_comm_order_req => cor.id_comm_order_req)) AS task_status,
                   get_instr_bg_color(cor.flg_need_ack, cor.id_comm_order_req) AS instr_bg_color,
                   get_instr_bg_alpha(cor.flg_need_ack) AS instr_bg_alpha,
                   pk_translation.get_translation(i_lang, cotype.code_icon) AS task_icon,
                   cor.flg_need_ack AS flg_need_ack,
                   get_edit_icon(i_id_comm_order_req => cor.id_comm_order_req,
                                 i_flg_need_ack      => cor.flg_need_ack,
                                 i_flg_action        => cor.flg_action) AS edit_icon,
                   '(' || pk_sysdomain.get_domain(i_code_dom => g_code_comm_order_action,
                                                  i_val      => cor.flg_action,
                                                  i_lang     => i_lang) || ')' AS action_desc,
                   cor.id_previous_status AS previous_status,
                   pk_alert_constant.g_task_comm_orders AS id_task_type_source,
                   NULL AS id_task_dependency,
                   decode(cor.id_status, g_id_sts_canceled, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_rep_cancel,
                   cor.flg_prn flg_prn_conditional
              FROM comm_order_req cor
              JOIN comm_order_type cotype
                ON cor.id_concept_type = cotype.id_comm_order_type
               AND cotype.id_task_type = cor.id_task_type
              LEFT JOIN comm_order_ea coea
                ON coea.id_concept_type = cor.id_concept_type
               AND coea.id_concept_term = cor.id_concept_term
               AND coea.id_concept_version = cor.id_concept_version
               AND coea.id_software_conc_term = i_prof.software
               AND coea.id_task_type_conc_term = l_task_type
               AND coea.id_institution_conc_term = i_prof.institution
             WHERE cor.id_patient = i_patient
               AND ((cor.flg_free_text = pk_alert_constant.g_no AND coea.id_comm_order IS NOT NULL) OR
                   (cor.flg_free_text = pk_alert_constant.g_yes))
               AND (cor.id_task_type = l_task_type OR cor.id_task_type IS NULL)
               AND cor.id_episode IN (SELECT epis.id_episode
                                        FROM episode epis
                                       WHERE epis.id_visit = pk_episode.get_id_visit(i_episode))
               AND (i_task_request IS NULL OR
                   (cor.id_comm_order_req IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                column_value
                                                 FROM TABLE(i_task_request) t)))
               AND cor.id_status != g_id_sts_predf
               AND (cor.id_status NOT IN (SELECT /*+opt_estimate (table t rows=1)*/
                                           to_number(column_value)
                                            FROM TABLE(i_filter_status) t) OR
                   (cor.id_status IN (g_id_sts_completed, g_id_sts_expired, g_id_sts_discontinued) AND -- closed tasks that need ack
                   cor.dt_status >= i_filter_tstz) OR (cor.id_status = g_id_sts_canceled AND -- closed tasks that need ack
                   cor.dt_status >= l_cancelled_task_filter_tstz))
             ORDER BY get_comm_order_req_rank(cotype.rank,
                                              pk_workflow.get_status_rank(i_lang,
                                                                          i_prof,
                                                                          cor.id_workflow,
                                                                          cor.id_status,
                                                                          l_id_category,
                                                                          l_id_profile_template,
                                                                          NULL,
                                                                          table_varchar()),
                                              pk_sysdomain.get_rank(i_lang, g_code_priority, cor.flg_priority)),
                      upper(task_description);
    
        IF i_flg_report = pk_alert_constant.g_yes
        THEN
        
            IF NOT get_order_plan_report(i_lang          => i_lang,
                                         i_prof          => i_prof,
                                         i_episode       => i_episode,
                                         i_task_request  => i_task_request,
                                         i_cpoe_dt_begin => i_dt_begin,
                                         i_cpoe_dt_end   => i_dt_end,
                                         i_task_type     => l_task_type,
                                         o_plan_rep      => o_plan_list,
                                         o_error         => o_error)
            THEN
                RAISE g_exception;
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
                                              i_function => 'GET_COMM_ORDER_LIST',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_task_list);
            RETURN FALSE;
    END get_comm_order_list;

    PROCEDURE set_visit_status_trigger
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
    
        l_error t_error_out;
    
        l_comm_orders            table_number;
        l_id_comm_order_req      table_number;
        l_id_comm_order_req_hist table_number;
    
    BEGIN
    
        -- Validate arguments
        g_error := 'VALIDATE ARGUEMTS';
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => 'VISIT',
                                                 i_expected_dg_table_name => 'COMM_ORDER_REQ',
                                                 i_list_columns           => i_list_columns,
                                                 i_expected_columns       => NULL)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        -- Check event type
        IF i_event_type = t_data_gov_mnt.g_event_update
        THEN
            IF i_rowids IS NOT NULL
               AND i_rowids.count > 0
            THEN
                SELECT /*+rule */
                 co.id_comm_order_req
                  BULK COLLECT
                  INTO l_comm_orders
                  FROM visit v
                  JOIN episode e
                    ON v.id_visit = e.id_visit
                  JOIN comm_order_req co
                    ON co.id_episode = e.id_episode
                  JOIN comm_order_type cotype
                    ON co.id_concept_type = cotype.id_comm_order_type
                   AND cotype.id_task_type = co.id_task_type
                 WHERE co.id_status = g_id_sts_ongoing
                   AND cotype.flg_scope = pk_alert_constant.g_scope_type_visit
                      -- AND e.flg_status = pk_alert_constant.g_epis_status_inactive
                   AND v.flg_status = pk_visit.g_visit_inactive
                   AND v.rowid IN (SELECT /*+opt_estimate (table t rows=1)*/
                                    column_value
                                     FROM TABLE(i_rowids) t);
            
                -- check if there are communication orders to complete
                IF l_comm_orders IS NOT NULL
                   AND l_comm_orders.count > 0
                THEN
                
                    -- discontinue comm_order_reqs
                    g_error  := 'Call set_comm_order_status / STS_END=' || g_id_sts_completed || ' WF_ACTION=' ||
                                g_id_action_complete;
                    g_retval := set_comm_order_status(i_lang                   => i_lang,
                                                      i_prof                   => i_prof,
                                                      i_id_comm_order_req      => l_comm_orders,
                                                      i_id_status_end          => g_id_sts_completed,
                                                      i_id_workflow_action     => g_id_action_complete,
                                                      o_id_comm_order_req      => l_id_comm_order_req,
                                                      o_id_comm_order_req_hist => l_id_comm_order_req_hist,
                                                      o_error                  => l_error);
                
                    IF NOT g_retval
                    THEN
                        RAISE g_exception_np;
                    END IF;
                END IF;
            END IF;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_VISIT_STATUS_TRIGGER',
                                              o_error    => l_error);
    END set_visit_status_trigger;

    PROCEDURE set_episode_status_trigger
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
    
        l_comm_orders            table_number;
        l_id_comm_order_req      table_number;
        l_id_comm_order_req_hist table_number;
    
        l_error t_error_out;
    
    BEGIN
    
        g_error := 'VALIDATE ARGUEMTS';
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => 'EPISODE',
                                                 i_expected_dg_table_name => 'COMM_ORDER_REQ',
                                                 i_list_columns           => i_list_columns,
                                                 i_expected_columns       => NULL)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        -- Check event type
        IF i_event_type = t_data_gov_mnt.g_event_update
        THEN
            IF i_rowids IS NOT NULL
               AND i_rowids.count > 0
            THEN
            
                SELECT /*+rule */
                 co.id_comm_order_req
                  BULK COLLECT
                  INTO l_comm_orders
                  FROM episode e
                  JOIN comm_order_req co
                    ON co.id_episode = e.id_episode
                  JOIN comm_order_type cotype
                    ON co.id_concept_type = cotype.id_comm_order_type
                   AND cotype.id_task_type = co.id_task_type
                 WHERE co.id_status = g_id_sts_ongoing
                   AND cotype.flg_scope = pk_alert_constant.g_scope_type_episode
                   AND e.flg_status = pk_alert_constant.g_epis_status_inactive
                   AND e.rowid IN (SELECT /*+opt_estimate (table t rows=1)*/
                                    column_value
                                     FROM TABLE(i_rowids) t);
            
                -- check if there are communication orders to complete
                IF l_comm_orders IS NOT NULL
                   AND l_comm_orders.count > 0
                THEN
                
                    g_error  := 'CALL SET_COMM_ORDER_STATUS';
                    g_retval := set_comm_order_status(i_lang                   => i_lang,
                                                      i_prof                   => i_prof,
                                                      i_id_comm_order_req      => l_comm_orders,
                                                      i_id_status_end          => g_id_sts_completed,
                                                      i_id_workflow_action     => g_id_action_complete,
                                                      o_id_comm_order_req      => l_id_comm_order_req,
                                                      o_id_comm_order_req_hist => l_id_comm_order_req_hist,
                                                      o_error                  => l_error);
                
                    IF NOT g_retval
                    THEN
                        RAISE g_exception_np;
                    END IF;
                END IF;
            END IF;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_EPISODE_STATUS_TRIGGER',
                                              o_error    => l_error);
    END set_episode_status_trigger;

    FUNCTION reset_comm_order_req
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_patients IN table_number,
        i_id_episodes IN table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rowids                 table_varchar := table_varchar();
        l_id_comm_order_req      table_number;
        l_code_trs               table_varchar;
        l_idx                    PLS_INTEGER;
        l_tbl_comm_order_req_del table_number;
    
    BEGIN
    
        -- comm_order_req        
        IF i_id_episodes IS NOT NULL
           AND i_id_episodes.count > 0
        THEN
        
            g_error := 'DELETE FROM comm_order_req_ack corq ';
            DELETE FROM comm_order_req_ack corq
             WHERE EXISTS (SELECT /*+opt_estimate (table t rows=1)*/
                     1
                      FROM comm_order_req cor
                      JOIN TABLE(CAST(i_id_episodes AS table_number)) t
                        ON (cor.id_episode = t.column_value)
                     WHERE corq.id_comm_order_req = cor.id_comm_order_req);
        
            SELECT cor.id_comm_order_req
              BULK COLLECT
              INTO l_tbl_comm_order_req_del
              FROM comm_order_req cor
             WHERE cor.id_episode IN (SELECT *
                                        FROM TABLE(i_id_episodes));
        
            IF l_tbl_comm_order_req_del IS NOT NULL
            THEN
                g_error := 'DELETE FROM comm_order_plan_hist coph ';
                DELETE FROM comm_order_plan_hist coph
                 WHERE coph.id_comm_order_req IN
                       (SELECT /*+opt_estimate (table t rows=1)*/
                         column_value
                          FROM TABLE(CAST(l_tbl_comm_order_req_del AS table_number)) t);
            
                g_error := 'DELETE FROM comm_order_plan cop ';
                DELETE FROM comm_order_plan cop
                 WHERE cop.id_comm_order_req IN
                       (SELECT /*+opt_estimate (table t rows=1)*/
                         column_value
                          FROM TABLE(CAST(l_tbl_comm_order_req_del AS table_number)) t);
            
                g_error := 'DELETE FROM comm_order_question_resp_hist coqrh ';
                DELETE FROM comm_order_question_resp_hist coqrh
                 WHERE coqrh.id_common_order_req IN
                       (SELECT /*+opt_estimate (table t rows=1)*/
                         column_value
                          FROM TABLE(CAST(l_tbl_comm_order_req_del AS table_number)) t);
            
                g_error := 'DELETE FROM comm_order_question_response coqr ';
                DELETE FROM comm_order_question_response coqr
                 WHERE coqr.id_common_order_req IN
                       (SELECT /*+opt_estimate (table t rows=1)*/
                         column_value
                          FROM TABLE(CAST(l_tbl_comm_order_req_del AS table_number)) t);
            END IF;
        
            g_error := 'DELETE FROM comm_order_req_hist corh ';
            DELETE FROM comm_order_req_hist corh
             WHERE corh.id_episode IN (SELECT /*+opt_estimate (table t rows=1)*/
                                        column_value
                                         FROM TABLE(CAST(i_id_episodes AS table_number)) t)
            RETURNING corh.id_comm_order_req BULK COLLECT INTO l_id_comm_order_req;
        
            g_error := 'DELETE FROM comm_order_req cor ';
            DELETE FROM comm_order_req cor
             WHERE cor.id_episode IN (SELECT /*+opt_estimate (table t rows=1)*/
                                       column_value
                                        FROM TABLE(CAST(i_id_episodes AS table_number)) t)
            RETURNING ROWID BULK COLLECT INTO l_rowids;
        
            t_data_gov_mnt.process_delete(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'COMM_ORDER_REQ',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
        ELSIF i_id_patients IS NOT NULL
              AND i_id_patients.count > 0
        THEN
        
            g_error := 'DELETE FROM comm_order_req_ack corq ';
            DELETE FROM comm_order_req_ack corq
             WHERE EXISTS (SELECT /*+opt_estimate (table t rows=1)*/
                     1
                      FROM comm_order_req cor
                      JOIN TABLE(CAST(i_id_patients AS table_number)) t
                        ON (cor.id_patient = t.column_value)
                     WHERE corq.id_comm_order_req = cor.id_comm_order_req);
        
            SELECT cor.id_comm_order_req
              BULK COLLECT
              INTO l_tbl_comm_order_req_del
              FROM comm_order_req cor
             WHERE cor.id_patient IN (SELECT *
                                        FROM TABLE(i_id_patients));
        
            IF l_tbl_comm_order_req_del IS NOT NULL
            THEN
                g_error := 'DELETE FROM comm_order_plan_hist coph ';
                DELETE FROM comm_order_plan_hist coph
                 WHERE coph.id_comm_order_req IN
                       (SELECT /*+opt_estimate (table t rows=1)*/
                         column_value
                          FROM TABLE(CAST(l_tbl_comm_order_req_del AS table_number)) t);
            
                g_error := 'DELETE FROM comm_order_plan cop ';
                DELETE FROM comm_order_plan cop
                 WHERE cop.id_comm_order_req IN
                       (SELECT /*+opt_estimate (table t rows=1)*/
                         column_value
                          FROM TABLE(CAST(l_tbl_comm_order_req_del AS table_number)) t);
            
                g_error := 'DELETE FROM comm_order_question_resp_hist coqrh ';
                DELETE FROM comm_order_question_resp_hist coqrh
                 WHERE coqrh.id_common_order_req IN
                       (SELECT /*+opt_estimate (table t rows=1)*/
                         column_value
                          FROM TABLE(CAST(l_tbl_comm_order_req_del AS table_number)) t);
            
                g_error := 'DELETE FROM comm_order_question_response coqr ';
                DELETE FROM comm_order_question_response coqr
                 WHERE coqr.id_common_order_req IN
                       (SELECT /*+opt_estimate (table t rows=1)*/
                         column_value
                          FROM TABLE(CAST(l_tbl_comm_order_req_del AS table_number)) t);
            END IF;
        
            g_error := 'DELETE FROM comm_order_req_hist corh ';
            DELETE FROM comm_order_req_hist corh
             WHERE corh.id_patient IN (SELECT /*+opt_estimate (table t rows=1)*/
                                        column_value
                                         FROM TABLE(CAST(i_id_patients AS table_number)) t)
            RETURNING corh.id_comm_order_req BULK COLLECT INTO l_id_comm_order_req;
        
            g_error := 'DELETE FROM comm_order_req cor ';
            DELETE FROM comm_order_req cor
             WHERE cor.id_patient IN (SELECT /*+opt_estimate (table t rows=1)*/
                                       column_value
                                        FROM TABLE(CAST(i_id_patients AS table_number)) t)
            RETURNING ROWID BULK COLLECT INTO l_rowids;
        
            t_data_gov_mnt.process_delete(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'COMM_ORDER_REQ',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        ELSE
            g_error := 'ID_PATIENT and ID_EPISODE cannot be null ';
            RAISE g_exception;
        END IF;
    
        -- delete from translation_trs
        l_code_trs := table_varchar();
        l_idx      := 0;
    
        FOR i IN 1 .. l_id_comm_order_req.count
        LOOP
            l_code_trs.extend(6);
        
            l_idx := l_idx + 1;
            l_code_trs(l_idx) := g_code_notes || l_id_comm_order_req(i);
            l_idx := l_idx + 1;
            l_code_trs(l_idx) := g_code_clinical_indication || l_id_comm_order_req(i);
            l_idx := l_idx + 1;
            l_code_trs(l_idx) := g_code_prn_condition || l_id_comm_order_req(i);
            l_idx := l_idx + 1;
            l_code_trs(l_idx) := g_code_notes_cancel || l_id_comm_order_req(i);
            l_idx := l_idx + 1;
            l_code_trs(l_idx) := g_code_desc_concept_term || l_id_comm_order_req(i);
        END LOOP;
    
        pk_translation.delete_code_translation_trs(l_code_trs);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'RESET_COMM_ORDER_REQ',
                                              o_error    => o_error);
            RETURN FALSE;
    END reset_comm_order_req;

    FUNCTION get_comm_order_req_rank
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_comm_order_type  IN comm_order_type.id_comm_order_type%TYPE,
        i_id_workflow         IN comm_order_req.id_workflow%TYPE,
        i_id_status           IN comm_order_req.id_status%TYPE,
        i_id_category         IN wf_status_config.id_category%TYPE DEFAULT 0,
        i_id_profile_template IN wf_status_config.id_profile_template%TYPE DEFAULT 0,
        i_flg_priority        IN comm_order_req.flg_priority%TYPE,
        i_id_task_type        IN task_type.id_task_type%TYPE
    ) RETURN NUMBER IS
    
        l_rank_comm_order_type comm_order_type.rank%TYPE;
        l_rank_status          wf_status_config.rank%TYPE;
        l_rank_priority        sys_domain.rank%TYPE;
    
    BEGIN
    
        g_error := 'Init';
        SELECT cotype.rank
          INTO l_rank_comm_order_type
          FROM comm_order_type cotype
         WHERE cotype.id_comm_order_type = i_id_comm_order_type
           AND cotype.id_task_type = i_id_task_type;
    
        g_error       := 'Call pk_workflow.get_status_rank ';
        l_rank_status := pk_workflow.get_status_rank(i_lang                => i_lang,
                                                     i_prof                => i_prof,
                                                     i_id_workflow         => i_id_workflow,
                                                     i_id_status           => i_id_status,
                                                     i_id_category         => i_id_category,
                                                     i_id_profile_template => i_id_profile_template,
                                                     i_id_functionality    => NULL,
                                                     i_param               => table_varchar());
    
        g_error         := 'FLG_PRIORITY_RANK ';
        l_rank_priority := pk_sysdomain.get_rank(i_lang, g_code_priority, i_flg_priority);
    
        g_error := 'Call get_comm_order_req_rank / i_rank_comm_order_type=' || l_rank_comm_order_type ||
                   ' i_rank_status=' || l_rank_status || ' i_rank_priority=' || l_rank_priority;
        RETURN get_comm_order_req_rank(i_rank_comm_order_type => l_rank_comm_order_type,
                                       i_rank_status          => l_rank_status,
                                       i_rank_priority        => l_rank_priority);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error('GET_COMM_ORDER_REQ_RANK / ' || g_error);
            RETURN NULL;
    END get_comm_order_req_rank;

    FUNCTION get_comm_order_req_rank
    (
        i_rank_comm_order_type IN NUMBER,
        i_rank_status          IN NUMBER,
        i_rank_priority        IN NUMBER
    ) RETURN NUMBER IS
    
        l_result NUMBER;
    
    BEGIN
    
        l_result := to_number(lpad(i_rank_comm_order_type, 8, '0') || lpad(i_rank_status, 8, '0') ||
                              lpad(i_rank_priority, 8, '0'));
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error('GET_COMM_ORDER_REQ_RANK / ' || g_error);
            RETURN NULL;
    END get_comm_order_req_rank;

    FUNCTION get_comm_order_viewer_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_viewer_area IN VARCHAR2,
        i_episode     IN episode.id_episode%TYPE,
        o_list        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_category         category.id_category%TYPE;
        l_id_profile_template profile_template.id_profile_template%TYPE;
    
        l_task_title sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'EHR_VIEWER_T325');
    
    BEGIN
    
        l_id_category         := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
        l_id_profile_template := pk_tools.get_prof_profile_template(i_prof);
    
        g_error := 'OPEN o_list FOR ';
        OPEN o_list FOR
            SELECT cor.id_comm_order_req AS id,
                   NULL code_description,
                   get_comm_order_title(i_lang                     => i_lang,
                                        i_prof                     => i_prof,
                                        i_concept_type             => cor.id_concept_type,
                                        i_concept_term             => cor.id_concept_term,
                                        i_cncpt_trm_inst_owner     => cor.id_cncpt_trm_inst_owner,
                                        i_concept_version          => cor.id_concept_version,
                                        i_cncpt_vrs_inst_owner     => cor.id_cncpt_vrs_inst_owner,
                                        i_flg_free_text            => cor.flg_free_text,
                                        i_desc_concept_term        => pk_translation.get_translation_trs(cor.desc_concept_term),
                                        i_task_type                => cor.id_task_type,
                                        i_flg_show_comm_order_type => pk_alert_constant.g_yes,
                                        i_flg_trunc_clobs          => pk_alert_constant.g_yes) AS description,
                   NULL AS title,
                   cor.dt_req dt_req_tstz,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, cor.dt_req, i_prof) dt_req,
                   to_char(cor.id_status) flg_status,
                   pk_alert_constant.g_viewer_filter_comm_orders flg_type,
                   get_comm_order_status_string(i_lang              => i_lang,
                                                i_prof              => i_prof,
                                                i_id_comm_order_req => cor.id_comm_order_req,
                                                i_id_status         => cor.id_status,
                                                i_dt_begin          => cor.dt_begin,
                                                i_flg_need_ack      => cor.flg_need_ack) AS desc_status,
                   get_comm_order_req_rank(cotype.rank,
                                           pk_workflow.get_status_rank(i_lang,
                                                                       i_prof,
                                                                       cor.id_workflow,
                                                                       cor.id_status,
                                                                       l_id_category,
                                                                       l_id_profile_template,
                                                                       NULL,
                                                                       table_varchar()),
                                           pk_sysdomain.get_rank(i_lang, g_code_priority, cor.flg_priority)) AS rank,
                   NULL rank_order,
                   get_instr_bg_color(cor.flg_need_ack, cor.id_comm_order_req) AS instr_bg_color,
                   get_instr_bg_alpha(cor.flg_need_ack) AS instr_bg_alpha,
                   get_edit_icon(i_id_comm_order_req => cor.id_comm_order_req,
                                 i_flg_need_ack      => cor.flg_need_ack,
                                 i_flg_action        => cor.flg_action) AS icon_skinning,
                   l_task_title task_title
              FROM comm_order_req cor
              JOIN comm_order_type cotype
                ON cor.id_concept_type = cotype.id_comm_order_type
               AND cotype.id_task_type = cor.id_task_type
             WHERE i_viewer_area = pk_hibernate_intf.g_ordered_list_wfl
               AND cor.id_patient = i_patient
               AND cor.id_episode IN (SELECT epis.id_episode
                                        FROM episode epis
                                       WHERE epis.id_visit = pk_episode.get_id_visit(i_episode))
               AND (cor.id_status = g_id_sts_ongoing OR (cor.id_status IN (g_id_sts_completed, g_id_sts_expired) AND
                   cor.flg_need_ack = pk_alert_constant.g_yes))
             ORDER BY rank,
                      upper(to_char(get_comm_order_desc(i_lang                     => i_lang,
                                                        i_prof                     => i_prof,
                                                        i_concept_type             => cor.id_concept_type,
                                                        i_concept_term             => cor.id_concept_term,
                                                        i_cncpt_trm_inst_owner     => cor.id_cncpt_trm_inst_owner,
                                                        i_concept_version          => cor.id_concept_version,
                                                        i_cncpt_vrs_inst_owner     => cor.id_cncpt_vrs_inst_owner,
                                                        i_flg_free_text            => cor.flg_free_text,
                                                        i_desc_concept_term        => pk_translation.get_translation_trs(cor.desc_concept_term),
                                                        i_notes                    => pk_translation.get_translation_trs(cor.notes),
                                                        i_flg_priority             => cor.flg_priority,
                                                        i_flg_prn                  => cor.flg_prn,
                                                        i_prn_condition            => pk_translation.get_translation_trs(cor.prn_condition),
                                                        i_dt_begin                 => cor.dt_begin,
                                                        i_task_type                => cor.id_task_type,
                                                        i_flg_bold_title           => pk_alert_constant.g_yes,
                                                        i_flg_show_comm_order_type => pk_alert_constant.g_yes,
                                                        i_flg_trunc_clobs          => pk_alert_constant.g_yes)));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_COMM_ORDER_VIEWER_LIST',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_comm_order_viewer_list;

    FUNCTION get_comm_order_viewer_detail
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_comm_order_req IN comm_order_req.id_comm_order_req%TYPE,
        o_detail         OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'OPEN o_detail FOR ';
        OPEN o_detail FOR
            SELECT cor.id_comm_order_req,
                   get_comm_order_req_sts_desc(i_lang              => i_lang,
                                               i_prof              => i_prof,
                                               i_id_status         => cor.id_status,
                                               i_dt_begin          => cor.dt_begin,
                                               i_id_comm_order_req => cor.id_comm_order_req) status_desc,
                   pk_prof_utils.get_name_signature(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_prof_id => cor.id_professional) prof_name,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, cor.dt_status, i_prof) dt_status_str,
                   NULL flg_nature_description
              FROM comm_order_req cor
             WHERE cor.id_comm_order_req = i_comm_order_req;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_COMM_ORDER_VIEWER_DETAIL',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_detail);
            RETURN FALSE;
    END get_comm_order_viewer_detail;

    FUNCTION get_comm_order_summ_grid
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_filter_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_filter_status IN table_number,
        o_comm_orders   OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_category         category.id_category%TYPE;
        l_id_profile_template profile_template.id_profile_template%TYPE;
    
    BEGIN
    
        l_id_category         := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
        l_id_profile_template := pk_tools.get_prof_profile_template(i_prof);
    
        g_error := 'OPEN o_comm_orders FOR ';
        OPEN o_comm_orders FOR
            SELECT get_comm_order_title(i_lang                     => i_lang,
                                        i_prof                     => i_prof,
                                        i_concept_type             => cor.id_concept_type,
                                        i_concept_term             => cor.id_concept_term,
                                        i_cncpt_trm_inst_owner     => cor.id_cncpt_trm_inst_owner,
                                        i_concept_version          => cor.id_concept_version,
                                        i_cncpt_vrs_inst_owner     => cor.id_cncpt_vrs_inst_owner,
                                        i_flg_free_text            => cor.flg_free_text,
                                        i_desc_concept_term        => pk_translation.get_translation_trs(cor.desc_concept_term),
                                        i_task_type                => cor.id_task_type,
                                        i_flg_show_comm_order_type => pk_alert_constant.g_yes,
                                        i_flg_trunc_clobs          => pk_alert_constant.g_yes) AS comm_order_title,
                   get_edit_icon(i_id_comm_order_req => cor.id_comm_order_req,
                                 i_flg_need_ack      => cor.flg_need_ack,
                                 i_flg_action        => cor.flg_action) AS edit_icon,
                   get_comm_order_status_string(i_lang              => i_lang,
                                                i_prof              => i_prof,
                                                i_id_comm_order_req => cor.id_comm_order_req,
                                                i_id_status         => cor.id_status,
                                                i_dt_begin          => cor.dt_begin,
                                                i_flg_need_ack      => cor.flg_need_ack) AS status_string,
                   get_comm_order_req_rank(cotype.rank,
                                           pk_workflow.get_status_rank(i_lang,
                                                                       i_prof,
                                                                       cor.id_workflow,
                                                                       cor.id_status,
                                                                       l_id_category,
                                                                       l_id_profile_template,
                                                                       NULL,
                                                                       table_varchar()),
                                           pk_sysdomain.get_rank(i_lang, g_code_priority, cor.flg_priority)) rank,
                   get_instr_bg_color(cor.flg_need_ack, cor.id_comm_order_req) AS instr_bg_color,
                   get_instr_bg_alpha(cor.flg_need_ack) AS instr_bg_alpha
              FROM comm_order_req cor
              JOIN comm_order_type cotype
                ON cor.id_concept_type = cotype.id_comm_order_type
               AND cotype.id_task_type = cor.id_task_type
             WHERE cor.id_episode = i_episode
               AND cor.id_status NOT IN (g_id_sts_predf, g_id_sts_draft) -- todo: confirmar se deve estar aqui
               AND (cor.id_status NOT IN (SELECT /*+opt_estimate (table t rows=1)*/
                                           to_number(column_value)
                                            FROM TABLE(i_filter_status) t) OR
                   (cor.id_status IN (g_id_sts_canceled, g_id_sts_completed, g_id_sts_expired) AND
                   cor.dt_status >= i_filter_tstz)) -- todo: confirmar where clause
             ORDER BY rank, upper(comm_order_title);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_COMM_ORDER_SUMM_GRID',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_comm_orders);
            RETURN FALSE;
    END get_comm_order_summ_grid;

    FUNCTION get_cs_action_desc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_flg_action IN comm_order_req_hist.flg_action%TYPE
    ) RETURN VARCHAR2 IS
    
        l_error       t_error_out;
        l_flg_action  comm_order_req_hist.flg_action%TYPE;
        l_action_desc sys_domain.desc_val%TYPE;
    
    BEGIN
    
        g_error := 'Init / i_flg_action=' || i_flg_action;
        CASE
            WHEN i_flg_action IN (g_action_canceled, g_action_dicontinued) THEN
                -- cancellation/discontinuation co-sign
                l_flg_action := i_flg_action;
            
            WHEN i_flg_action IN (g_action_draft, g_action_edition, g_action_order) THEN
                -- order co-sign
                l_flg_action := g_action_order;
            
            ELSE
                -- there is no co-sign of this type
                g_error := 'No co-sign of this type / i_flg_action=' || i_flg_action;
                RAISE g_exception;
        END CASE;
    
        g_error       := 'Call pk_sysdomain.get_domain / l_flg_action=' || l_flg_action;
        l_action_desc := pk_sysdomain.get_domain(i_code_dom => g_code_comm_order_action,
                                                 i_val      => l_flg_action,
                                                 i_lang     => i_lang);
    
        RETURN l_action_desc;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_CS_ACTION_DESC',
                                              o_error    => l_error);
            RETURN NULL;
    END get_cs_action_desc;

    FUNCTION inactivate_comm_order_tasks
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_inst        IN institution.id_institution%TYPE,
        i_ids_exclude IN OUT table_number,
        o_has_error   OUT BOOLEAN,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cancel_cfg sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf => 'INACTIVATE_CANCEL_REASON',
                                                                      i_prof    => i_prof);
    
        l_descontinued_cfg sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf => 'INACTIVATE_DISCONTINUED_REASON',
                                                                            i_prof    => i_prof);
    
        l_tbl_config t_tbl_config_table := pk_core_config.get_values_by_mkt_inst_sw(i_lang => NULL,
                                                                                    i_prof => profissional(0, i_inst, 0),
                                                                                    i_area => 'COMM_ORDER_INACTIVATE');
    
        l_cancel_id cancel_reason.id_cancel_reason%TYPE := pk_cancel_reason.get_id_by_content(i_lang,
                                                                                              i_prof,
                                                                                              l_cancel_cfg);
    
        l_descontinued_id cancel_reason.id_cancel_reason%TYPE := pk_cancel_reason.get_id_by_content(i_lang,
                                                                                                    i_prof,
                                                                                                    l_descontinued_cfg);
    
        l_max_rows sys_config.value%TYPE := pk_sysconfig.get_config(i_prof    => i_prof,
                                                                    i_code_cf => 'INACTIVATE_TASKS_MAX_NUMBER_ROWS');
    
        l_comm_order_req table_number;
        l_episodes_req   table_number;
        l_final_status   table_varchar;
    
        l_error t_error_out;
        g_other_exception EXCEPTION;
    
        l_tbl_error_ids table_number := table_number();
    
        --The cursor will not fetch the records for the ids (id_comm_order_req) sent in i_ids_exclude    
        CURSOR c_comm_order_req(ids_exclude IN table_number) IS
            SELECT cor.id_comm_order_req, cor.id_episode, cfg.field_04
              FROM comm_order_req cor
             INNER JOIN episode e
                ON e.id_episode = cor.id_episode
              LEFT JOIN episode prev_e
                ON prev_e.id_prev_episode = e.id_episode
               AND e.id_visit = prev_e.id_visit
             INNER JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                          *
                           FROM TABLE(l_tbl_config) t) cfg
                ON cfg.field_01 = cor.id_status
              LEFT JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                          t.column_value
                           FROM TABLE(i_ids_exclude) t) t_ids
                ON t_ids.column_value = cor.id_comm_order_req
             WHERE e.id_institution = i_inst
               AND e.dt_end_tstz IS NOT NULL
               AND (prev_e.id_episode IS NULL OR prev_e.flg_status = pk_alert_constant.g_inactive)
               AND pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                    i_timestamp => (pk_date_utils.add_to_ltstz(i_timestamp => e.dt_end_tstz,
                                                                                               i_amount    => cfg.field_02,
                                                                                               i_unit      => cfg.field_03))) <=
                   pk_date_utils.trunc_insttimezone(i_prof => i_prof, i_timestamp => current_timestamp)
               AND rownum <= l_max_rows
               AND t_ids.column_value IS NULL;
    
    BEGIN
    
        o_has_error := FALSE;
    
        OPEN c_comm_order_req(i_ids_exclude);
        FETCH c_comm_order_req BULK COLLECT
            INTO l_comm_order_req, l_episodes_req, l_final_status;
        CLOSE c_comm_order_req;
    
        IF l_comm_order_req.count > 0
        THEN
            FOR i IN 1 .. l_comm_order_req.count
            LOOP
                IF l_final_status(i) = g_id_sts_completed
                THEN
                    SAVEPOINT init_cancel;
                    IF NOT pk_comm_orders.set_action_cancel_discontinue(i_lang              => i_lang,
                                                                        i_prof              => i_prof,
                                                                        i_id_comm_order_req => table_number(l_comm_order_req(i)),
                                                                        i_id_episode        => l_episodes_req(i),
                                                                        i_id_reason         => l_descontinued_id,
                                                                        i_notes             => NULL,
                                                                        i_dt_order          => NULL,
                                                                        i_id_prof_order     => NULL,
                                                                        i_id_order_type     => NULL,
                                                                        i_auto_descontinued => pk_alert_constant.g_yes,
                                                                        o_error             => l_error)
                    THEN
                        ROLLBACK TO init_cancel;
                    
                        --If, for the given id_comm_order_req, an error is generated, o_has_error is set as TRUE,
                        --this way, the loop cicle may continue, but the system will know that at least one error has happened
                        o_has_error := TRUE;
                    
                        --A log for the id_comm_order_req that raised the error must be generated 
                        pk_alert_exceptions.reset_error_state;
                        g_error := 'ERROR CALLING  PK_COMM_ORDERS.SET_ACTION_CANCEL_DISCONTINUE FOR RECORD ' ||
                                   l_comm_order_req(i);
                        pk_alert_exceptions.process_error(i_lang,
                                                          SQLCODE,
                                                          SQLERRM,
                                                          g_error,
                                                          'ALERT',
                                                          g_package,
                                                          'INACTIVATE_COMM_ORDER_TASKS',
                                                          o_error);
                    
                        --The array for the ids (id_comm_order_req) that raised the error is incremented
                        l_tbl_error_ids.extend();
                        l_tbl_error_ids(l_tbl_error_ids.count) := l_comm_order_req(i);
                    
                        CONTINUE;
                    END IF;
                ELSIF l_final_status(i) = g_id_sts_canceled
                THEN
                    SAVEPOINT init_cancel;
                    IF NOT pk_comm_orders.set_action_cancel_discontinue(i_lang              => i_lang,
                                                                        i_prof              => i_prof,
                                                                        i_id_comm_order_req => table_number(l_comm_order_req(i)),
                                                                        i_id_episode        => l_episodes_req(i),
                                                                        i_id_reason         => l_cancel_id,
                                                                        i_notes             => NULL,
                                                                        i_dt_order          => NULL,
                                                                        i_id_prof_order     => NULL,
                                                                        i_id_order_type     => NULL,
                                                                        i_auto_descontinued => pk_alert_constant.g_no,
                                                                        o_error             => l_error)
                    THEN
                        ROLLBACK TO init_cancel;
                    
                        --If, for the given id_comm_order_req, an error is generated, o_has_error is set as TRUE,
                        --this way, the loop cicle may continue, but the system will know that at least one error has happened
                        o_has_error := TRUE;
                    
                        --A log for the id_comm_order_req that raised the error must be generated 
                        pk_alert_exceptions.reset_error_state;
                        g_error := 'ERROR CALLING  PK_COMM_ORDERS.SET_ACTION_CANCEL_DISCONTINUE FOR RECORD ' ||
                                   l_comm_order_req(i);
                        pk_alert_exceptions.process_error(i_lang,
                                                          SQLCODE,
                                                          SQLERRM,
                                                          g_error,
                                                          'ALERT',
                                                          g_package,
                                                          'INACTIVATE_COMM_ORDER_TASKS',
                                                          o_error);
                    
                        --The array for the ids (id_comm_order_req) that raised the error is incremented
                        l_tbl_error_ids.extend();
                        l_tbl_error_ids(l_tbl_error_ids.count) := l_comm_order_req(i);
                    
                        CONTINUE;
                    END IF;
                END IF;
            END LOOP;
        
            --When the number of error ids match the max number of rows that can be processed for each call,
            --it means that no id_comm_order_req has been inactivated.
            --The next time the Job would be executed, the cursor would fetch the same set fetched on the previous call,
            --and therefore, from this point on, no more records would be inactivated.
            IF l_tbl_error_ids.count = l_max_rows
            THEN
                FOR i IN l_tbl_error_ids.first .. l_tbl_error_ids.last
                LOOP
                    --i_ids_exclude is an IN OUT parameter, and is incremented with the ids (id_epis_diet_req) that could not
                    --be inactivated with the current call of the function
                    i_ids_exclude.extend();
                    i_ids_exclude(i_ids_exclude.count) := l_tbl_error_ids(i);
                END LOOP;
            
                --Since no inactivations were performed with the current call, a new call to this function is performed,
                --however, this time, the array i_ids_exclude will include a list of ids that cannot be fetched by the cursor
                --on the next call. The recursion will be perfomed until at least one record is inactivated, or the cursor
                --has no more records to fetch.
                --Note: i_ids_exclude is incremented and is an IN OUT parameter, therefore, 
                --it will hold all the ids that were not inactivated from ALL calls.            
                IF NOT pk_comm_orders.inactivate_comm_order_tasks(i_lang        => i_lang,
                                                                  i_prof        => i_prof,
                                                                  i_inst        => i_inst,
                                                                  i_ids_exclude => i_ids_exclude,
                                                                  o_has_error   => o_has_error,
                                                                  o_error       => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
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
                                              i_function => 'INACTIVATE_COMM_ORDER_TASKS',
                                              o_error    => o_error);
            RETURN FALSE;
    END inactivate_comm_order_tasks;

    FUNCTION get_comm_order_questionnaire
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_comm_order    IN comm_order_ea.id_comm_order%TYPE,
        i_flg_time      IN VARCHAR2,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        o_list          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_patient IS
            SELECT gender, trunc(months_between(SYSDATE, dt_birth) / 12) age
              FROM patient
             WHERE id_patient = i_patient;
    
        l_id_concept_term comm_order_ea.id_concept_term%TYPE;
    
        l_patient c_patient%ROWTYPE;
    
    BEGIN
    
        g_error := 'OPEN C_PATIENT';
        OPEN c_patient;
        FETCH c_patient
            INTO l_patient;
        CLOSE c_patient;
    
        g_error := 'GETTING ID_CONCEPT_TERM';
        SELECT coe.id_concept_term
          INTO l_id_concept_term
          FROM comm_order_ea coe
         WHERE coe.id_comm_order = i_comm_order
           AND coe.id_software_conc_term = i_prof.software
           AND coe.id_institution_conc_term = i_prof.institution
           AND rownum = 1;
    
        g_error := 'OPEN O_LIST BY ID_HEMO_TYPE';
        OPEN o_list FOR
            SELECT q.id_concept_term,
                   q.id_questionnaire,
                   q.id_questionnaire_parent,
                   q.id_response_parent,
                   pk_mcdt.get_questionnaire_alias(i_lang,
                                                   i_prof,
                                                   'QUESTIONNAIRE.CODE_QUESTIONNAIRE.' || q.id_questionnaire) desc_questionnaire,
                   q.flg_type,
                   q.flg_mandatory,
                   q.flg_copy flg_apply_to_all,
                   q.id_unit_measure,
                   pk_mcdt.get_questionnaire_response(i_lang,
                                                      i_prof,
                                                      i_patient,
                                                      q.id_questionnaire,
                                                      i_comm_order,
                                                      NULL,
                                                      i_flg_time,
                                                      'COMM_ORDER') desc_response,
                   decode(q.flg_validation,
                          pk_blood_products_constant.g_yes,
                          --if date then should return the serialized value stored in the field "notes"
                          decode(instr(q.flg_type, 'D'), 0, to_char(bpqr1.id_response), to_char(bpqr1.notes)),
                          NULL) episode_id_response,
                   decode(q.flg_validation,
                          pk_blood_products_constant.g_yes,
                          decode(dbms_lob.getlength(bpqr1.notes),
                                 NULL,
                                 to_clob(pk_mcdt.get_response_alias(i_lang,
                                                                    i_prof,
                                                                    'RESPONSE.CODE_RESPONSE.' || bpqr1.id_response)),
                                 pk_blood_products_utils.get_bp_response(i_lang, i_prof, bpqr1.notes)),
                          to_clob('')) episode_desc_response
              FROM (SELECT DISTINCT bpq.id_concept_term,
                                    bpq.id_questionnaire,
                                    qr.id_questionnaire_parent,
                                    qr.id_response_parent,
                                    bpq.flg_type,
                                    bpq.flg_mandatory,
                                    bpq.flg_copy,
                                    bpq.flg_validation,
                                    bpq.id_unit_measure,
                                    bpq.rank
                      FROM comm_order_questionnaire bpq, questionnaire_response qr
                     WHERE bpq.id_concept_term = l_id_concept_term
                       AND bpq.flg_time = i_flg_time
                       AND bpq.id_institution = i_prof.institution
                       AND bpq.flg_available = pk_blood_products_constant.g_available
                       AND bpq.id_questionnaire = qr.id_questionnaire
                       AND bpq.id_response = qr.id_response
                       AND qr.flg_available = pk_blood_products_constant.g_available
                       AND EXISTS
                     (SELECT 1
                              FROM questionnaire q
                             WHERE q.id_questionnaire = bpq.id_questionnaire
                               AND q.flg_available = pk_blood_products_constant.g_available
                               AND (((l_patient.gender IS NOT NULL AND
                                   coalesce(q.gender, 'I', 'U', 'N') IN ('I', 'U', 'N', l_patient.gender)) OR
                                   l_patient.gender IS NULL OR l_patient.gender IN ('I', 'U', 'N')) AND
                                   (nvl(l_patient.age, 0) BETWEEN nvl(q.age_min, 0) AND
                                   nvl(q.age_max, nvl(l_patient.age, 0)) OR nvl(l_patient.age, 0) = 0)))) q,
                   (SELECT id_questionnaire, id_response, notes
                      FROM (SELECT bpqr.id_questionnaire,
                                   pk_procedures_utils.get_procedure_episode_response(i_lang,
                                                                                      i_prof,
                                                                                      i_episode,
                                                                                      bpqr.id_questionnaire) id_response,
                                   bpqr.notes,
                                   row_number() over(PARTITION BY bpqr.id_questionnaire ORDER BY bpqr.dt_last_update_tstz DESC) rn
                              FROM comm_order_question_response bpqr
                             WHERE bpqr.id_episode = i_episode)
                     WHERE rn = 1) bpqr1
             WHERE q.id_questionnaire = bpqr1.id_questionnaire(+)
             ORDER BY q.rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_COMM_ORDER_QUESTIONNAIRE',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_comm_order_questionnaire;

    FUNCTION get_comm_order_response
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_questionnaire IN questionnaire_response.id_questionnaire%TYPE,
        i_comm_order    IN comm_order_ea.id_comm_order%TYPE,
        i_flg_time      IN VARCHAR2
    ) RETURN table_varchar IS
    
        CURSOR c_patient IS
            SELECT gender, trunc(months_between(SYSDATE, dt_birth) / 12) age
              FROM patient
             WHERE id_patient = i_patient;
    
        l_patient         c_patient%ROWTYPE;
        l_id_concept_term comm_order_ea.id_concept_term%TYPE;
        l_response        table_varchar;
    
    BEGIN
    
        g_error := 'OPEN C_PATIENT';
        OPEN c_patient;
        FETCH c_patient
            INTO l_patient;
        CLOSE c_patient;
    
        g_error := 'GETTING ID_CONCEPT_TERM';
        SELECT coe.id_concept_term
          INTO l_id_concept_term
          FROM comm_order_ea coe
         WHERE coe.id_comm_order = i_comm_order
           AND coe.id_software_conc_term = i_prof.software
           AND coe.id_institution_conc_term = i_prof.institution
           AND rownum = 1;
    
        g_error := 'SELECT QUESTIONNAIRE_RESPONSE';
        SELECT qr.id_response || '|' ||
               pk_mcdt.get_response_alias(i_lang, i_prof, 'RESPONSE.CODE_RESPONSE.' || qr.id_response) || '|' ||
               r.flg_free_text
          BULK COLLECT
          INTO l_response
          FROM questionnaire_response qr, response r
         WHERE qr.id_questionnaire = i_questionnaire
           AND qr.flg_available = pk_alert_constant.g_available
           AND qr.id_response = r.id_response
           AND r.flg_available = pk_alert_constant.g_available
           AND EXISTS (SELECT 1
                  FROM comm_order_questionnaire iq
                 WHERE iq.id_concept_term = l_id_concept_term
                   AND iq.flg_time = i_flg_time
                   AND iq.id_questionnaire = qr.id_questionnaire
                   AND iq.id_response = qr.id_response
                   AND iq.id_institution = i_prof.institution
                   AND iq.flg_available = pk_alert_constant.g_available)
           AND (((l_patient.gender IS NOT NULL AND
               coalesce(r.gender, 'I', 'U', 'N') IN ('I', 'U', 'N', l_patient.gender)) OR
               l_patient.gender IS NULL OR l_patient.gender IN ('I', 'U', 'N')) AND
               (nvl(l_patient.age, 0) BETWEEN nvl(r.age_min, 0) AND nvl(r.age_max, nvl(l_patient.age, 0)) OR
               nvl(l_patient.age, 0) = 0))
         ORDER BY qr.rank;
    
        RETURN l_response;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_comm_order_response;

    FUNCTION get_comm_order_response
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_notes IN comm_order_question_response.notes%TYPE
    ) RETURN comm_order_question_response.notes%TYPE IS
    
        l_ret comm_order_question_response.notes%TYPE;
    
    BEGIN
        -- Heuristic to minimize attempts to parse an invalid date
        IF dbms_lob.getlength(i_notes) = length('YYYYMMDDHHMMSS')
           AND pk_utils.is_number(char_in => i_notes) = pk_alert_constant.g_yes -- This is the size of a stored serialized date, not a mask (HH vs HH24).-- This is the size of a stored serialized date, not a mask (HH vs HH24).
        THEN
            -- We try to parse the note as a serialized date
            l_ret := pk_date_utils.dt_chr_str(i_lang     => i_lang,
                                              i_date     => i_notes,
                                              i_inst     => i_prof.institution,
                                              i_soft     => i_prof.software,
                                              i_timezone => NULL);
        ELSE
            l_ret := i_notes;
        END IF;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Ignore parse errors and return original content
            RETURN i_notes;
    END get_comm_order_response;

    FUNCTION get_comm_order_episode_resp
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_questionnaire IN comm_order_question_response.id_questionnaire%TYPE
    ) RETURN VARCHAR2 IS
    
        l_response VARCHAR2(1000 CHAR);
    
    BEGIN
    
        SELECT substr(concatenate(t.id_response || '|'), 1, length(concatenate(t.id_response || '|')) - 1)
          INTO l_response
          FROM (SELECT iqr.id_response,
                       dense_rank() over(PARTITION BY iqr.id_questionnaire ORDER BY iqr.dt_last_update_tstz DESC) rn
                  FROM comm_order_question_response iqr
                 WHERE iqr.id_episode = i_episode
                   AND iqr.id_questionnaire = i_questionnaire) t
         WHERE t.rn = 1;
    
        RETURN l_response;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_comm_order_episode_resp;

    FUNCTION get_comm_order_execution_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_comm_order_req  IN comm_order_req.id_comm_order_req%TYPE,
        o_comm_order_plan OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_comm_order_plan_last interv_presc_plan.id_interv_presc_plan%TYPE;
    
        l_msg_notes         sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'COMMON_M097');
        l_msg_not_aplicable sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'COMMON_M036');
    
    BEGIN
    
        -- Retorna a utima execução 
        BEGIN
            SELECT id_comm_order_plan
              INTO l_comm_order_plan_last
              FROM (SELECT cop.id_comm_order_plan,
                           row_number() over(PARTITION BY cop.id_comm_order_req ORDER BY cop.exec_number DESC, cop.dt_comm_order_plan DESC) rn
                      FROM comm_order_req cor, comm_order_plan cop
                     WHERE cor.id_comm_order_req = cop.id_comm_order_req
                       AND cor.id_comm_order_req = i_comm_order_req
                       AND cop.flg_status = pk_procedures_constant.g_interv_plan_executed
                       AND cop.id_prof_take = i_prof.id) -- Só pode cancelar o profissional que efectuou a execução)
             WHERE rn = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_comm_order_plan_last := NULL;
        END;
    
        g_error := 'OPEN O_COMM_ORDER_PLAN';
        OPEN o_comm_order_plan FOR
            SELECT cop.id_comm_order_plan,
                   cor.id_comm_order_req,
                   (SELECT ora_hash(lpad(cor.id_concept_term, 24, 0) || lpad(cor.id_cncpt_trm_inst_owner, 24, 0) ||
                                    lpad(cor.id_concept_version, 24, 0) || lpad(cor.id_cncpt_vrs_inst_owner, 24, 0))
                      FROM dual) id_comm_order_ea,
                   decode(cop.flg_status, NULL, g_comm_order_plan_req, cop.flg_status) flg_status,
                   get_comm_order_title(i_lang                     => i_lang,
                                        i_prof                     => i_prof,
                                        i_concept_type             => cor.id_concept_type,
                                        i_concept_term             => cor.id_concept_term,
                                        i_cncpt_trm_inst_owner     => cor.id_cncpt_trm_inst_owner,
                                        i_concept_version          => cor.id_concept_version,
                                        i_cncpt_vrs_inst_owner     => cor.id_cncpt_vrs_inst_owner,
                                        i_flg_free_text            => cor.flg_free_text,
                                        i_desc_concept_term        => pk_translation.get_translation_trs(cor.desc_concept_term),
                                        i_task_type                => cor.id_task_type,
                                        i_flg_bold_title           => pk_alert_constant.g_no,
                                        i_flg_show_comm_order_type => pk_alert_constant.g_yes,
                                        i_flg_trunc_clobs          => pk_alert_constant.g_no) desc_comm_order,
                   decode(cor.flg_prn,
                          pk_alert_constant.g_yes,
                          NULL,
                          nvl(pk_order_recurrence_api_db.get_order_recurr_plan_desc(i_lang, i_prof, cor.id_order_recurr),
                              pk_translation.get_translation(i_lang, 'ORDER_RECURR_OPTION.CODE_ORDER_RECURR_OPTION.0'))) to_be_perform,
                   decode(cor.flg_prn,
                          pk_procedures_constant.g_yes,
                          NULL,
                          decode(cop.dt_plan_tstz,
                                 NULL,
                                 NULL,
                                 pk_date_utils.dt_chr_tsz(i_lang, cop.dt_plan_tstz, i_prof.institution, i_prof.software))) dt_begin,
                   decode(cor.flg_prn,
                          pk_procedures_constant.g_yes,
                          decode(cop.id_comm_order_plan, NULL, NULL, l_msg_not_aplicable),
                          decode(cop.dt_plan_tstz,
                                 NULL,
                                 l_msg_not_aplicable,
                                 pk_date_utils.date_char_hour_tsz(i_lang,
                                                                  cop.dt_plan_tstz,
                                                                  i_prof.institution,
                                                                  i_prof.software))) hr_begin,
                   decode(cop.flg_status,
                          pk_procedures_constant.g_interv_plan_cancel,
                          pk_date_utils.dt_chr_tsz(i_lang, cop.dt_cancel_tstz, i_prof.institution, i_prof.software),
                          pk_date_utils.dt_chr_tsz(i_lang, cop.start_time, i_prof.institution, i_prof.software)) dt_perform,
                   decode(cop.flg_status,
                          pk_procedures_constant.g_interv_plan_cancel,
                          pk_date_utils.date_char_hour_tsz(i_lang,
                                                           cop.dt_cancel_tstz,
                                                           i_prof.institution,
                                                           i_prof.software),
                          pk_date_utils.date_char_hour_tsz(i_lang, cop.start_time, i_prof.institution, i_prof.software)) hr_perform,
                   decode(cop.flg_status,
                          pk_procedures_constant.g_interv_plan_cancel,
                          pk_prof_utils.get_name_signature(i_lang, i_prof, cop.id_prof_cancel),
                          pk_prof_utils.get_name_signature(i_lang, i_prof, cop.id_prof_performed)) prof_performed,
                   pk_utils.get_status_string(i_lang,
                                               i_prof,
                                               pk_ea_logic_comm_orders.get_comm_order_plan_status_str(i_lang,
                                                                                                      i_prof,
                                                                                                      CASE
                                                                                                          WHEN cor.flg_prn = pk_alert_constant.g_yes
                                                                                                               AND cop.flg_status = g_comm_order_plan_req THEN
                                                                                                           NULL
                                                                                                          ELSE
                                                                                                           cop.flg_status
                                                                                                      END,
                                                                                                      cop.dt_plan_tstz,
                                                                                                      cop.dt_take_tstz,
                                                                                                      cor.task_duration,
                                                                                                      cor.id_status),
                                               pk_ea_logic_comm_orders.get_comm_order_plan_status_msg(i_lang,
                                                                                                      i_prof,
                                                                                                      CASE
                                                                                                          WHEN cor.flg_prn = pk_alert_constant.g_yes
                                                                                                               AND cop.flg_status = g_comm_order_plan_req THEN
                                                                                                           NULL
                                                                                                          ELSE
                                                                                                           cop.flg_status
                                                                                                      END,
                                                                                                      cop.dt_plan_tstz,
                                                                                                      cop.dt_take_tstz,
                                                                                                      cor.task_duration,
                                                                                                      cor.id_status),
                                               pk_ea_logic_comm_orders.get_comm_order_plan_stat_icon(i_lang,
                                                                                                     i_prof,
                                                                                                     CASE
                                                                                                         WHEN cor.flg_prn = pk_alert_constant.g_yes
                                                                                                              AND cop.flg_status = g_comm_order_plan_req THEN
                                                                                                          NULL
                                                                                                         ELSE
                                                                                                          cop.flg_status
                                                                                                     END,
                                                                                                     cop.dt_plan_tstz,
                                                                                                     cop.dt_take_tstz,
                                                                                                     cor.task_duration,
                                                                                                     cor.id_status),
                                               pk_ea_logic_comm_orders.get_comm_order_plan_status_flg(i_lang,
                                                                                                      i_prof,
                                                                                                      CASE
                                                                                                          WHEN cor.flg_prn = pk_alert_constant.g_yes
                                                                                                               AND cop.flg_status = g_comm_order_plan_req THEN
                                                                                                           NULL
                                                                                                          ELSE
                                                                                                           cop.flg_status
                                                                                                      END,
                                                                                                      cop.dt_plan_tstz,
                                                                                                      cop.dt_take_tstz,
                                                                                                      cor.task_duration,
                                                                                                      cor.id_status)) status_string,
                   decode(cop.flg_status,
                          pk_procedures_constant.g_interv_plan_cancel,
                          decode(cop.notes_cancel, NULL, NULL, l_msg_notes),
                          decode(cop.id_epis_documentation,
                                 NULL,
                                 decode(cop.notes, NULL, NULL, l_msg_notes),
                                 l_msg_notes)) msg_notes,
                   decode(cop.notes_cancel,
                          NULL,
                          decode(cop.id_epis_documentation,
                                 NULL,
                                 to_clob(cop.notes),
                                 pk_touch_option_core.get_plain_text_entry(i_lang, i_prof, cop.id_epis_documentation)),
                          to_clob(cop.notes_cancel)) notes,
                   NULL avail_button_create,
                   NULL avail_button_ok,
                   NULL avail_button_cancel,
                   NULL doc_template_interv,
                   decode(cor.task_duration,
                          NULL,
                          NULL,
                          pk_message.get_message(i_lang => i_lang, i_code_mess => 'COMM_ORDER_T075') || ' ' ||
                          cor.task_duration || ' ' || (SELECT pk_unit_measure.get_unit_measure_description(i_lang         => i_lang,
                                                                                                           i_prof         => i_prof,
                                                                                                           i_unit_measure => 10374)
                                                         FROM dual)) time_execution,
                   cor.id_concept_term,
                   cor.id_task_type,
                   (SELECT check_parameters(i_lang            => i_lang,
                                            i_prof            => i_prof,
                                            i_id_task_type    => cor.id_task_type,
                                            i_id_concept_term => cor.id_concept_term)
                      FROM dual) flg_has_parameters,
                   row_number() over(ORDER BY pk_sysdomain.get_rank(i_lang, 'INTERV_PRESC_PLAN.FLG_STATUS', cop.flg_status), nvl(cop.exec_number, 1) DESC, nvl(cop.dt_plan_tstz, cop.start_time) DESC) rank
              FROM comm_order_req cor, comm_order_plan cop
             WHERE cor.id_comm_order_req = i_comm_order_req
               AND cor.id_comm_order_req = cop.id_comm_order_req(+)
             ORDER BY rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_COMM_ORDER_EXECUTION_LIST',
                                              o_error);
            RETURN FALSE;
    END get_comm_order_execution_list;

    FUNCTION get_execution_action_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_subject        IN action.subject%TYPE,
        i_from_state     IN action.from_state%TYPE,
        i_comm_order_req IN comm_order_req.id_comm_order_req%TYPE,
        o_actions        OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_prn comm_order_req.flg_prn %TYPE;
    
    BEGIN
    
        SELECT cor.flg_prn
          INTO l_flg_prn
          FROM comm_order_req cor
         WHERE cor.id_comm_order_req = i_comm_order_req;
    
        OPEN o_actions FOR
            SELECT a.id_action,
                   a.id_parent,
                   a.level_nr,
                   a.desc_action,
                   a.icon,
                   a.flg_default, --default action
                   CASE
                    --When PRN, task should not be cancelled unless when is 'ongoing'
                        WHEN a.action = 'CANCEL'
                             AND l_flg_prn = pk_alert_constant.g_yes
                             AND a.from_state <> g_comm_order_plan_ongoing THEN
                         pk_alert_constant.g_inactive
                        ELSE
                         a.flg_active
                    END flg_active, --action's state
                   a.action,
                   a.to_state
              FROM TABLE(pk_action.tf_get_actions_with_exceptions(i_lang, i_prof, i_subject, i_from_state)) a;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_EXECUTION_ACTION_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_actions);
        
    END get_execution_action_list;

    FUNCTION get_comm_order_for_execution
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_comm_order_req  IN comm_order_req.id_comm_order_req%TYPE,
        i_comm_order_plan IN comm_order_plan.id_comm_order_plan%TYPE,
        o_comm_order      OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_msg_not_applicable sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'COMMON_M018');
    
        l_comm_order_plan_last comm_order_plan.id_comm_order_plan%TYPE;
        l_comm_order_plan_next comm_order_plan.id_comm_order_plan%TYPE;
    
        l_count PLS_INTEGER := 0;
    
        l_plan_next_date order_recurr_plan.start_date%TYPE;
    
        l_finish_recurr VARCHAR2(1 CHAR);
    
        l_id_order_recurr     order_recurr_plan.id_order_recurr_plan%TYPE;
        l_flag_recurr_control order_recurr_control.flg_status%TYPE;
        l_sysdate_tstz        TIMESTAMP(6) WITH LOCAL TIME ZONE;
    
        l_comm_order_det_cancel comm_order_req.dt_status%TYPE;
    
    BEGIN
    
        l_sysdate_tstz := current_timestamp;
    
        SELECT COUNT(1)
          INTO l_count
          FROM comm_order_plan cop
         WHERE cop.id_comm_order_req = i_comm_order_req
           AND cop.flg_status != pk_procedures_constant.g_interv_cancel;
    
        -- Retorna a utima execução 
        BEGIN
            SELECT id_comm_order_plan
              INTO l_comm_order_plan_last
              FROM (SELECT cop.id_comm_order_plan,
                           row_number() over(PARTITION BY cop.id_comm_order_req ORDER BY cop.exec_number DESC, cop.dt_comm_order_plan DESC) rn
                      FROM comm_order_req cor
                     INNER JOIN comm_order_plan cop
                        ON cor.id_comm_order_req = cop.id_comm_order_req
                     WHERE cor.id_comm_order_req = i_comm_order_req
                       AND cop.flg_status = pk_procedures_constant.g_interv_plan_executed)
             WHERE rn = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_comm_order_plan_last := NULL;
        END;
    
        -- Retorna execução seguinte 
        BEGIN
            SELECT id_comm_order_plan
              INTO l_comm_order_plan_last
              FROM (SELECT cop.id_comm_order_plan,
                           row_number() over(PARTITION BY cop.id_comm_order_req ORDER BY cop.exec_number DESC, cop.dt_comm_order_plan DESC) rn
                      FROM comm_order_req cor
                     INNER JOIN comm_order_plan cop
                        ON cor.id_comm_order_req = cop.id_comm_order_req
                     WHERE cor.id_comm_order_req = i_comm_order_req
                       AND cop.flg_status IN
                           (pk_procedures_constant.g_interv_plan_pending, pk_procedures_constant.g_interv_plan_req))
             WHERE rn = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_comm_order_plan_last := NULL;
        END;
    
        -- When a prescription is expired DT_CANCEL_TSTZ represents the expiration timestamp 
        BEGIN
            SELECT cor.dt_status
              INTO l_comm_order_det_cancel
              FROM comm_order_req cor
             WHERE cor.id_comm_order_req = i_comm_order_req
               AND cor.id_status = pk_comm_orders.g_id_sts_expired;
        EXCEPTION
            WHEN no_data_found THEN
                l_comm_order_det_cancel := NULL;
        END;
    
        BEGIN
            SELECT cor.id_order_recurr
              INTO l_id_order_recurr
              FROM comm_order_req cor
             WHERE cor.id_comm_order_req = i_comm_order_req;
        EXCEPTION
            WHEN no_data_found THEN
                l_id_order_recurr := NULL;
        END;
    
        /*
        1 - Create and execute
        2 - Execute
        3 - Execution edition
        */
    
        IF l_id_order_recurr IS NOT NULL
        THEN
            g_error := 'CALL PK_ORDER_RECURRENCE_API_DB.GET_NEXT_EXECUTION';
            IF NOT pk_order_recurrence_api_db.get_next_execution(i_lang                => i_lang,
                                                                 i_prof                => i_prof,
                                                                 i_id_order_recurrence => l_id_order_recurr,
                                                                 i_dt_next             => NULL,
                                                                 o_flag_recurr_control => l_flag_recurr_control,
                                                                 o_finish_recurr       => l_finish_recurr,
                                                                 o_plan_start_date     => l_plan_next_date,
                                                                 o_error               => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        g_error := 'GET CURSOR';
        OPEN o_comm_order FOR
            SELECT NULL id_comm_order_ea,
                   NULL desc_comm_order,
                   i_prof.id id_prof_perform,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, i_prof.id) desc_prof_perform,
                   NULL dt_start,
                   NULL dt_start_min,
                   pk_date_utils.get_timestamp_str(i_lang, i_prof, l_sysdate_tstz, NULL) dt_start_max,
                   NULL dt_end,
                   l_msg_not_applicable dt_plan_show,
                   NULL dt_plan,
                   NULL id_modifiers,
                   NULL desc_modifiers,
                   NULL id_epis_documentation,
                   NULL id_doc_template,
                   NULL desc_notes,
                   NULL flg_supplies_mandatory,
                   NULL desc_supplies
              FROM dual
             WHERE i_comm_order_req IS NULL
               AND i_comm_order_plan IS NULL
            UNION ALL
            SELECT NULL id_comm_order_ea,
                   NULL desc_comm_order,
                   i_prof.id id_prof_perform,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, i_prof.id) desc_prof_perform,
                   NULL dt_start,
                   pk_date_utils.get_timestamp_str(i_lang,
                                                   i_prof,
                                                   coalesce(cor.dt_req, cor.dt_begin, l_sysdate_tstz),
                                                   NULL) dt_start_min,
                   pk_date_utils.get_timestamp_str(i_lang,
                                                   i_prof,
                                                   decode(cop.flg_status,
                                                          pk_procedures_constant.g_interv_expired,
                                                          l_comm_order_det_cancel,
                                                          l_sysdate_tstz),
                                                   NULL) dt_start_max,
                   NULL dt_end,
                   decode(l_plan_next_date,
                          NULL,
                          l_msg_not_applicable,
                          pk_date_utils.date_char_tsz(i_lang, l_plan_next_date, i_prof.institution, i_prof.software)) dt_plan_show,
                   pk_date_utils.to_char_insttimezone(i_prof, l_plan_next_date, pk_alert_constant.g_dt_yyyymmddhh24miss) dt_plan,
                   NULL id_modifiers,
                   NULL desc_modifiers,
                   NULL id_epis_documentation,
                   NULL id_doc_template,
                   NULL desc_notes,
                   NULL flg_supplies_mandatory,
                   NULL desc_supplies
              FROM comm_order_req cor
             INNER JOIN comm_order_plan cop
                ON cor.id_comm_order_req = cop.id_comm_order_plan
             WHERE cor.id_comm_order_req = i_comm_order_req
               AND cop.id_comm_order_plan = i_comm_order_plan
            UNION ALL
            SELECT NULL id_comm_order_ea,
                   NULL desc_comm_order,
                   i_prof.id id_prof_perform,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, i_prof.id) desc_prof_perform,
                   pk_date_utils.date_send_tsz(i_lang, cop.start_time, i_prof) dt_start,
                   nvl((SELECT pk_date_utils.to_char_insttimezone(i_prof, cop1.dt_plan_tstz, 'YYYYMMDDHH24MISS')
                         FROM comm_order_plan cop1
                        WHERE cop1.id_comm_order_plan = l_comm_order_plan_last),
                       pk_date_utils.to_char_insttimezone(i_prof, nvl(cor.dt_req, cor.dt_begin), 'YYYYMMDDHH24MISS')) dt_start_min,
                   decode(cop.id_comm_order_plan,
                          l_comm_order_plan_last,
                          NULL,
                          nvl((SELECT pk_date_utils.to_char_insttimezone(i_prof, cop1.start_time, 'YYYYMMDDHH24MISS')
                                FROM comm_order_plan cop1
                               WHERE cop1.id_comm_order_plan = l_comm_order_plan_next),
                              NULL)) dt_start_max,
                   pk_date_utils.date_send_tsz(i_lang, cop.end_time, i_prof) dt_end,
                   decode(cor.flg_prn,
                          pk_procedures_constant.g_yes,
                          l_msg_not_applicable,
                          nvl((SELECT pk_date_utils.date_char_tsz(i_lang,
                                                                 i.dt_plan_tstz,
                                                                 i_prof.institution,
                                                                 i_prof.software)
                                FROM comm_order_plan i
                               WHERE i.id_comm_order_req = cor.id_comm_order_req
                                 AND i.exec_number = cop.exec_number + 1),
                              l_msg_not_applicable)) dt_plan_show,
                   (SELECT pk_date_utils.to_char_insttimezone(i_prof,
                                                              i.dt_plan_tstz,
                                                              pk_alert_constant.g_dt_yyyymmddhh24miss)
                      FROM comm_order_plan i
                     WHERE i.id_comm_order_req = cor.id_comm_order_req
                       AND i.exec_number = cop.exec_number + 1) dt_plan,
                   NULL id_modifiers,
                   NULL desc_modifiers,
                   cop.id_epis_documentation,
                   pk_touch_option.get_doc_template_internal(i_lang,
                                                             i_prof,
                                                             NULL,
                                                             cor.id_episode,
                                                             CASE
                                                                 WHEN cor.id_task_type = pk_alert_constant.g_task_medical_orders THEN
                                                                  g_doc_area_medical_orders
                                                                 ELSE
                                                                  g_doc_area_communications
                                                             END,
                                                             cor.id_concept_term) id_doc_template,
                   NULL desc_notes,
                   NULL flg_supplies_mandatory,
                   NULL desc_supplies
              FROM comm_order_plan cop
             INNER JOIN comm_order_req cor
                ON cop.id_comm_order_req = cor.id_comm_order_req
             WHERE cop.id_comm_order_plan = i_comm_order_plan;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_COMM_ORDER_FOR_EXECUTION',
                                              o_error);
            pk_types.open_my_cursor(o_comm_order);
            RETURN FALSE;
    END get_comm_order_for_execution;

    FUNCTION get_comm_order_summary
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_episode                 IN episode.id_episode%TYPE,
        i_id_comm_order_req       IN comm_order_req.id_comm_order_req%TYPE,
        o_comm_order              OUT pk_types.cursor_type,
        o_comm_clinical_questions OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'OPEN O_COMM_ORDER';
        OPEN o_comm_order FOR
            SELECT t.id_comm_order_req,
                   t.dt_reg,
                   t.prof_reg,
                   t.prof_spec_reg,
                   decode(t.id_task_type,
                          pk_alert_constant.g_task_medical_orders,
                          '<b>' || pk_message.get_message(i_lang => i_lang, i_code_mess => 'MED_ORDER_T014') || '</b> ' ||
                          t.desc_comm_order,
                          '<b>' || pk_message.get_message(i_lang => i_lang, i_code_mess => 'COMM_ORDER_T024') || '</b> ' ||
                          t.desc_comm_order) desc_comm_order,
                   decode(t.desc_diagnosis,
                          NULL,
                          NULL,
                          '<b>' || pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t026) ||
                          '</b> ' || t.desc_diagnosis) desc_diagnosis,
                   decode(t.clinical_purpose,
                          NULL,
                          NULL,
                          '<b>' || pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t010) ||
                          '</b> ' || t.clinical_purpose) clinical_purpose,
                   decode(t.priority,
                          NULL,
                          NULL,
                          '<b>' || pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t011) ||
                          '</b> ' || t.priority) priority,
                   decode(t.desc_status,
                          NULL,
                          NULL,
                          '<b>' || pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t051) ||
                          '</b> ' || t.desc_status) desc_status,
                   decode(t.flg_prn,
                          NULL,
                          NULL,
                          '<b>' || pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t012) ||
                          '</b> ' || t.flg_prn) prn,
                   decode(to_char(t.prn_condition),
                          NULL,
                          NULL,
                          '<b>' || pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t013) ||
                          '</b> ' || t.prn_condition) prn_condition,
                   decode(t.start_date,
                          NULL,
                          NULL,
                          '<b>' || pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t014) ||
                          '</b> ' || t.start_date) start_date,
                   CASE
                        WHEN t.id_task_type = pk_alert_constant.g_task_medical_orders
                             OR pk_sysconfig.get_config(i_code_cf => g_comm_order_exec_workflow, i_prof => i_prof) =
                             pk_alert_constant.g_yes THEN
                         CASE
                             WHEN t.id_order_recurr IS NULL THEN
                              '<b>' || pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t061) ||
                              '</b> ' ||
                              pk_translation.get_translation(i_lang, 'ORDER_RECURR_OPTION.CODE_ORDER_RECURR_OPTION.0')
                             ELSE
                              '<b>' || pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t061) ||
                              '</b> ' ||
                              pk_order_recurrence_api_db.get_order_recurr_plan_desc(i_lang, i_prof, t.id_order_recurr)
                         END
                        ELSE
                         NULL
                    END order_recurrence,
                   decode(t.task_duration,
                          NULL,
                          NULL,
                          '<b>' || pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t075) ||
                          '</b> ' || t.task_duration || ' ' ||
                          pk_unit_measure.get_unit_measure_description(i_lang         => i_lang,
                                                                       i_prof         => i_prof,
                                                                       i_unit_measure => 10374)) task_duration,
                   decode(to_char(t.notes),
                          NULL,
                          NULL,
                          '<b>' || pk_message.get_message(i_lang => i_lang, i_code_mess => g_sm_comm_order_t008) ||
                          '</b> ' || t.notes) notes
              FROM (SELECT cor.id_comm_order_req,
                           cor.id_task_type,
                           pk_date_utils.date_char_tsz(i_lang, cor.dt_status, i_prof.institution, i_prof.software) dt_reg,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, cor.id_professional) prof_reg,
                           pk_prof_utils.get_spec_signature(i_lang,
                                                            i_prof,
                                                            cor.id_professional,
                                                            cor.dt_status,
                                                            cor.id_episode) prof_spec_reg,
                           get_comm_order_title(i_lang                     => i_lang,
                                                i_prof                     => i_prof,
                                                i_concept_type             => cor.id_concept_type,
                                                i_concept_term             => cor.id_concept_term,
                                                i_cncpt_trm_inst_owner     => cor.id_cncpt_trm_inst_owner,
                                                i_concept_version          => cor.id_concept_version,
                                                i_cncpt_vrs_inst_owner     => cor.id_cncpt_vrs_inst_owner,
                                                i_flg_free_text            => cor.flg_free_text,
                                                i_desc_concept_term        => pk_translation.get_translation_trs(cor.desc_concept_term),
                                                i_task_type                => cor.id_task_type,
                                                i_flg_show_comm_order_type => pk_alert_constant.g_yes,
                                                i_flg_trunc_clobs          => pk_alert_constant.g_no) desc_comm_order,
                           pk_utils.concat_table(get_desc_diagnoses(i_lang                => i_lang,
                                                                    i_prof                => i_prof,
                                                                    i_clinical_indication => pk_translation.get_translation_trs(cor.clinical_indication)),
                                                 g_str_sep_comma) desc_diagnosis,
                           get_clinical_purpose_desc(i_lang              => i_lang,
                                                     i_prof              => i_prof,
                                                     i_flg_clin_purpose  => cor.flg_clinical_purpose,
                                                     i_clin_purpose_desc => cor.clinical_purpose_desc) clinical_purpose,
                           pk_sysdomain.get_domain(i_code_dom => g_code_priority,
                                                   i_val      => cor.flg_priority,
                                                   i_lang     => i_lang) priority,
                           get_comm_order_req_sts_desc(i_lang              => i_lang,
                                                       i_prof              => i_prof,
                                                       i_id_status         => cor.id_status,
                                                       i_dt_begin          => cor.dt_begin,
                                                       i_id_comm_order_req => cor.id_comm_order_req) desc_status,
                           pk_sysdomain.get_domain(i_code_dom => g_code_prn, i_val => cor.flg_prn, i_lang => i_lang) flg_prn,
                           pk_translation.get_translation_trs(cor.prn_condition) prn_condition,
                           pk_date_utils.dt_chr_date_hour_tsz(i_lang, cor.dt_begin, i_prof) start_date,
                           cor.id_order_recurr,
                           cor.task_duration,
                           pk_translation.get_translation_trs(cor.notes) notes
                      FROM comm_order_req cor
                     WHERE cor.id_comm_order_req = i_id_comm_order_req) t;
    
        g_error := 'OPEN O_COMM_CLINICAL_QUESTIONS';
        OPEN o_comm_clinical_questions FOR
            SELECT id_common_order_req, desc_clinical_question, to_clob(desc_response) desc_response
              FROM (SELECT DISTINCT coqr1.id_common_order_req,
                                    coqr1.id_questionnaire,
                                    coqr1.flg_time,
                                    '<b>' || pk_mcdt.get_questionnaire_alias(i_lang,
                                                                             i_prof,
                                                                             'QUESTIONNAIRE.CODE_QUESTIONNAIRE.' ||
                                                                             coqr1.id_questionnaire) || ':</b>' desc_clinical_question,
                                    dbms_lob.substr(decode(dbms_lob.getlength(coqr.notes),
                                                           NULL,
                                                           to_clob(decode(coqr1.desc_response,
                                                                          NULL,
                                                                          '---',
                                                                          coqr1.desc_response)),
                                                           pk_procedures_utils.get_procedure_response(i_lang,
                                                                                                      i_prof,
                                                                                                      coqr.notes)),
                                                    3800) desc_response,
                                    get_comm_order_question_rank(i_lang,
                                                                 i_prof,
                                                                 cor.id_concept_term,
                                                                 coqr1.id_questionnaire,
                                                                 coqr1.flg_time) rank
                      FROM (SELECT coqr.id_common_order_req,
                                   coqr.id_questionnaire,
                                   coqr.flg_time,
                                   listagg(pk_mcdt.get_response_alias(i_lang,
                                                                      i_prof,
                                                                      'RESPONSE.CODE_RESPONSE.' || coqr.id_response),
                                           '; ') within GROUP(ORDER BY coqr.id_response) desc_response,
                                   coqr.dt_last_update_tstz,
                                   row_number() over(PARTITION BY coqr.id_questionnaire, coqr.flg_time ORDER BY coqr.dt_last_update_tstz DESC NULLS FIRST) rn
                              FROM comm_order_question_response coqr
                             WHERE coqr.id_common_order_req = i_id_comm_order_req
                               AND coqr.dt_last_update_tstz =
                                   (SELECT MAX(c.dt_last_update_tstz)
                                      FROM comm_order_question_response c
                                     WHERE c.id_common_order_req = i_id_comm_order_req)
                             GROUP BY coqr.id_common_order_req,
                                      coqr.id_questionnaire,
                                      coqr.flg_time,
                                      coqr.dt_last_update_tstz) coqr1,
                           comm_order_question_response coqr,
                           comm_order_req cor
                     WHERE coqr1.rn = 1
                       AND coqr1.id_common_order_req = coqr.id_common_order_req
                       AND coqr1.id_questionnaire = coqr.id_questionnaire
                       AND coqr1.dt_last_update_tstz = coqr.dt_last_update_tstz
                       AND coqr1.flg_time = coqr.flg_time
                       AND coqr.id_common_order_req = cor.id_comm_order_req)
             ORDER BY flg_time, rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_COMM_ORDER_SUMMARY',
                                              o_error);
            pk_types.open_my_cursor(o_comm_order);
            pk_types.open_my_cursor(o_comm_clinical_questions);
            RETURN FALSE;
    END get_comm_order_summary;

    FUNCTION set_comm_order_execution
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN episode.id_episode%TYPE,
        i_comm_order_req         IN comm_order_req.id_comm_order_req%TYPE,
        i_comm_order_plan        IN comm_order_plan.id_comm_order_plan%TYPE,
        i_flg_status             IN comm_order_plan.flg_status%TYPE,
        i_dt_next                IN VARCHAR2,
        i_prof_performed         IN comm_order_plan.id_prof_performed%TYPE,
        i_start_time             IN VARCHAR2,
        i_end_time               IN VARCHAR2,
        i_flg_supplies           IN VARCHAR2,
        i_notes                  IN comm_order_plan.notes%TYPE,
        i_epis_documentation     IN comm_order_plan.id_epis_documentation%TYPE DEFAULT NULL,
        i_doc_template           IN doc_template.id_doc_template%TYPE, --25
        i_flg_type               IN doc_template_context.flg_type%TYPE,
        i_id_documentation       IN table_number,
        i_id_doc_element         IN table_number,
        i_id_doc_element_crit    IN table_number,
        i_value                  IN table_varchar, --30
        i_id_doc_element_qualif  IN table_table_number,
        i_vs_element_list        IN table_number,
        i_vs_save_mode_list      IN table_varchar,
        i_vs_list                IN table_number,
        i_vs_value_list          IN table_number, --35
        i_vs_uom_list            IN table_number,
        i_vs_scales_list         IN table_number,
        i_vs_date_list           IN table_varchar,
        i_vs_read_list           IN table_number,
        i_clinical_decision_rule IN cdr_call.id_cdr_call%TYPE,
        i_id_po_param_reg        IN po_param_reg.id_po_param_reg%TYPE DEFAULT NULL,
        o_comm_order_plan        OUT comm_order_plan.id_comm_order_plan%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_comm_order_req IS
            SELECT cor.id_comm_order_req, cor.id_status, cor.flg_prn, cor.id_patient, cor.id_episode, cor.id_task_type
              FROM comm_order_req cor
             WHERE cor.id_comm_order_req = i_comm_order_req;
    
        CURSOR c_comm_order_plan IS
            SELECT cop.*
              FROM comm_order_plan cop
             WHERE cop.id_comm_order_plan = i_comm_order_plan;
    
        CURSOR c_comm_order_plan_count IS
            SELECT COUNT(*)
              FROM comm_order_plan
             WHERE id_comm_order_req = i_comm_order_req
               AND flg_status = pk_procedures_constant.g_interv_plan_executed;
    
        l_comm_order_req  c_comm_order_req%ROWTYPE;
        l_comm_order_plan c_comm_order_plan%ROWTYPE;
    
        l_comm_order_plan_hist comm_order_plan_hist.id_comm_order_plan_hist%TYPE;
    
        l_comm_order_plan_count NUMBER;
    
        l_next_comm_order_plan comm_order_plan.id_comm_order_plan%TYPE;
        l_start_time           comm_order_plan.start_time%TYPE;
        l_end_time             comm_order_plan.end_time%TYPE;
        l_dt_plan              comm_order_plan.dt_plan_tstz%TYPE;
        l_dt_take              comm_order_plan.dt_take_tstz%TYPE;
    
        l_exec_number NUMBER := 1;
    
        l_rows_out table_varchar := table_varchar();
    
        g_sysdate_tstz TIMESTAMP(6) WITH LOCAL TIME ZONE;
    
        l_comm_order_plan_flg_status comm_order_plan.flg_status%TYPE;
    
        l_id_epis_documentation epis_documentation.id_epis_documentation%TYPE;
        l_id_documentation      table_number := table_number();
    
        l_id_po_param_reg po_param_reg.id_po_param_reg%TYPE;
        l_count_po_param  NUMBER := 0;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        l_dt_plan    := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_next, NULL);
        l_start_time := pk_date_utils.get_string_tstz(i_lang, i_prof, i_start_time, NULL);
        l_end_time   := pk_date_utils.get_string_tstz(i_lang, i_prof, i_end_time, NULL);
    
        l_comm_order_plan_flg_status := pk_comm_orders.g_comm_order_plan_ongoing;
    
        g_error := 'OPEN C_INTERV';
        OPEN c_comm_order_req;
        FETCH c_comm_order_req
            INTO l_comm_order_req;
        CLOSE c_comm_order_req;
    
        l_dt_take := pk_date_utils.get_string_tstz(i_lang, i_prof, i_start_time, NULL);
    
        g_error := 'OPEN C_INTERV_PRESC_PLAN';
        OPEN c_comm_order_plan;
        FETCH c_comm_order_plan
            INTO l_comm_order_plan;
        CLOSE c_comm_order_plan;
    
        -- retorna numero máximo da execução
        SELECT MAX(cop.exec_number)
          INTO l_exec_number
          FROM comm_order_plan cop
         WHERE cop.id_comm_order_req = i_comm_order_req
           AND cop.flg_status = pk_procedures_constant.g_interv_plan_executed;
    
        IF l_exec_number IS NULL
        THEN
            l_exec_number := 1;
        ELSE
            l_exec_number := l_exec_number + 1;
        END IF;
    
        --Save template info
        l_id_documentation := nvl(i_id_documentation, table_number());
    
        IF i_doc_template IS NOT NULL
           AND i_epis_documentation IS NULL
        THEN
            IF nvl(l_id_documentation.count, 0) > 0
               OR (nvl(l_id_documentation.count, 0) = 0 AND i_notes IS NOT NULL AND dbms_lob.getlength(i_notes) > 0)
            THEN
                g_error := 'CALL PK_TOUCH_OPTION.SET_EPIS_DOCUMENTATION';
                IF NOT pk_touch_option.set_epis_document_internal(i_lang                  => i_lang,
                                                             i_prof                  => i_prof,
                                                             i_prof_cat_type         => pk_prof_utils.get_category(i_lang, i_prof),
                                                             i_epis                  => i_episode,
                                                             i_doc_area              => CASE
                                                                                            WHEN l_comm_order_req.id_task_type =
                                                                                                 pk_alert_constant.g_task_medical_orders THEN
                                                                                             g_doc_area_medical_orders
                                                                                            ELSE
                                                                                             g_doc_area_communications
                                                                                        END,
                                                             i_doc_template          => i_doc_template,
                                                             i_epis_documentation    => NULL,
                                                             i_flg_type              => i_flg_type,
                                                             i_id_documentation      => l_id_documentation,
                                                             i_id_doc_element        => i_id_doc_element,
                                                             i_id_doc_element_crit   => i_id_doc_element_crit,
                                                             i_value                 => i_value,
                                                             i_notes                 => i_notes,
                                                             i_id_epis_complaint     => NULL,
                                                             i_id_doc_element_qualif => i_id_doc_element_qualif,
                                                             i_epis_context          => nvl(l_comm_order_plan.id_comm_order_plan,
                                                                                            i_comm_order_req),
                                                             i_vs_element_list       => i_vs_element_list,
                                                             i_vs_save_mode_list     => i_vs_save_mode_list,
                                                             i_vs_list               => i_vs_list,
                                                             i_vs_value_list         => i_vs_value_list,
                                                             i_vs_uom_list           => i_vs_uom_list,
                                                             i_vs_scales_list        => i_vs_scales_list,
                                                             i_vs_date_list          => i_vs_date_list,
                                                             i_vs_read_list          => i_vs_read_list,
                                                             o_epis_documentation    => l_id_epis_documentation,
                                                             o_error                 => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            END IF;
        END IF;
    
        --If there's a Flowsheet configured for the current plan,
        --check if the user has inserted any value. If not, it is necessary
        -- to cancel the results column created by the flash layer
        IF i_id_po_param_reg IS NULL
        THEN
            l_id_po_param_reg := NULL;
        ELSE
            l_count_po_param := pk_periodic_observation.get_count_comm_order(i_lang           => i_lang,
                                                                             i_prof           => i_prof,
                                                                             i_comm_order_req => i_comm_order_req,
                                                                             i_po_param_reg   => i_id_po_param_reg,
                                                                             o_error          => o_error);
            IF l_count_po_param > 0
            THEN
                l_id_po_param_reg := i_id_po_param_reg;
                --Since the user has inserted data, it is necessary to configure the parameters
                -- for the patient's flowsheet
                IF NOT pk_periodic_observation.set_parameter_comm_order(i_lang               => i_lang,
                                                                        i_prof               => i_prof,
                                                                        i_episode            => i_episode,
                                                                        i_id_comm_order_plan => i_comm_order_plan,
                                                                        i_id_po_param_reg    => i_id_po_param_reg,
                                                                        o_error              => o_error)
                THEN
                
                    RAISE g_exception;
                END IF;
            ELSE
                l_id_po_param_reg := NULL;
                IF NOT pk_periodic_observation.cancel_column(i_lang            => i_lang,
                                                             i_prof            => i_prof,
                                                             i_id_po_param_reg => i_id_po_param_reg,
                                                             o_error           => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            END IF;
        END IF;
    
        IF l_comm_order_req.id_status = pk_comm_orders.g_id_sts_expired
        THEN
            -- This task was expired by CPOE.
            -- Should be possible to record the last execution made after the task expiration (not more than one excecution).
        
            IF l_comm_order_req.flg_prn = pk_alert_constant.g_yes
            THEN
                --Because SOS prescriptions do not have a prior entry in the planning table, a new entry is created
                g_error := 'Record an execution in a post-expired SOS task';
                IF l_start_time > l_end_time
                THEN
                    l_start_time := l_end_time;
                END IF;
            
                g_error                := 'INSERT INTO INTERV_PRESC_PLAN';
                l_next_comm_order_plan := seq_comm_order_plan.nextval;
                ts_comm_order_plan.ins(id_comm_order_plan_in    => l_next_comm_order_plan,
                                       id_comm_order_req_in     => l_comm_order_req.id_comm_order_req,
                                       dt_comm_order_plan_in    => g_sysdate_tstz,
                                       dt_plan_tstz_in          => g_sysdate_tstz,
                                       flg_status_in            => pk_comm_orders.g_comm_order_plan_executed,
                                       dt_take_tstz_in          => g_sysdate_tstz,
                                       id_prof_take_in          => i_prof.id,
                                       notes_in                 => i_notes,
                                       id_prof_performed_in     => CASE i_prof_performed
                                                                       WHEN -1 THEN
                                                                        NULL
                                                                       ELSE
                                                                        i_prof_performed
                                                                   END,
                                       start_time_in            => l_start_time,
                                       end_time_in              => l_end_time,
                                       flg_supplies_reg_in      => i_flg_supplies,
                                       id_epis_documentation_in => nvl(l_id_epis_documentation, i_epis_documentation),
                                       id_episode_write_in      => i_episode,
                                       exec_number_in           => l_exec_number,
                                       id_prof_last_update_in   => i_prof.id,
                                       dt_last_update_tstz_in   => g_sysdate_tstz,
                                       id_po_param_reg_in       => l_id_po_param_reg,
                                       rows_out                 => l_rows_out);
            
            ELSIF l_comm_order_plan.flg_status = pk_procedures_constant.g_interv_plan_expired
            THEN
                -- For safety, validate that we are updating an execution plan already expired         
                g_error := 'Record an execution in a post-expired task';
                ts_comm_order_plan.upd(id_comm_order_plan_in => i_comm_order_plan,
                                       flg_status_in         => l_comm_order_plan_flg_status,
                                       dt_take_tstz_in       => g_sysdate_tstz,
                                       id_prof_take_in       => i_prof.id,
                                       notes_in              => i_notes,
                                       notes_nin             => FALSE,
                                       id_prof_performed_in  => CASE i_prof_performed
                                                                    WHEN -1 THEN
                                                                     NULL
                                                                    ELSE
                                                                     i_prof_performed
                                                                END,
                                       start_time_in         => l_start_time,
                                       start_time_nin        => FALSE,
                                       end_time_in           => l_end_time,
                                       end_time_nin          => FALSE,
                                       flg_supplies_reg_in   => i_flg_supplies,
                                       -- Clear cancel information that was automatically filled by expire_task method
                                       id_prof_cancel_in         => NULL,
                                       id_prof_cancel_nin        => FALSE,
                                       notes_cancel_in           => NULL,
                                       notes_cancel_nin          => FALSE,
                                       dt_cancel_tstz_in         => NULL,
                                       dt_cancel_tstz_nin        => FALSE,
                                       id_epis_documentation_in  => nvl(l_id_epis_documentation, i_epis_documentation),
                                       id_epis_documentation_nin => FALSE,
                                       id_episode_write_in       => i_episode,
                                       id_prof_last_update_in    => i_prof.id,
                                       dt_last_update_tstz_in    => g_sysdate_tstz,
                                       id_po_param_reg_in        => l_id_po_param_reg,
                                       id_po_param_reg_nin       => FALSE,
                                       rows_out                  => l_rows_out);
            
            END IF;
        
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'COMM_ORDER_PLAN',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            -- End post-expired execution
        
        ELSIF l_comm_order_req.flg_prn = pk_alert_constant.g_yes
              OR l_comm_order_plan.flg_status IN
              (pk_comm_orders.g_comm_order_plan_req,
                  pk_comm_orders.g_comm_order_plan_pending,
                  pk_comm_orders.g_comm_order_plan_ongoing,
                  pk_comm_orders.g_comm_order_plan_monitorized)
        THEN
            IF l_comm_order_req.flg_prn IS NULL
               OR l_comm_order_req.flg_prn != pk_alert_constant.g_yes
            THEN
                g_error := 'CALL TO PK_PROCEDURES_CORE.SET_PROCEDURE_EXECUTION_HIST';
                IF NOT pk_comm_orders.set_comm_order_execution_hist(i_lang                 => i_lang,
                                                                    i_prof                 => i_prof,
                                                                    i_comm_order_plan      => i_comm_order_plan,
                                                                    o_comm_order_plan_hist => l_comm_order_plan_hist,
                                                                    o_error                => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
                IF l_comm_order_plan.flg_status = pk_comm_orders.g_comm_order_plan_req
                THEN
                
                    g_error := 'UPDATE INTERV_PRESC_PLAN';
                    ts_comm_order_plan.upd(id_comm_order_plan_in    => i_comm_order_plan,
                                           flg_status_in            => l_comm_order_plan_flg_status,
                                           dt_take_tstz_in          => l_dt_take,
                                           id_prof_take_in          => i_prof.id,
                                           notes_in                 => i_notes,
                                           notes_nin                => FALSE,
                                           id_prof_performed_in     => CASE i_prof_performed
                                                                           WHEN -1 THEN
                                                                            NULL
                                                                           ELSE
                                                                            i_prof_performed
                                                                       END,
                                           start_time_in            => l_start_time,
                                           start_time_nin           => FALSE,
                                           end_time_in              => l_end_time,
                                           end_time_nin             => FALSE,
                                           flg_supplies_reg_in      => i_flg_supplies,
                                           id_cdr_event_in          => i_clinical_decision_rule,
                                           id_epis_documentation_in => nvl(l_id_epis_documentation, i_epis_documentation),
                                           id_episode_write_in      => i_episode,
                                           id_prof_last_update_in   => i_prof.id,
                                           dt_last_update_tstz_in   => g_sysdate_tstz,
                                           id_po_param_reg_in       => l_id_po_param_reg,
                                           id_po_param_reg_nin      => FALSE,
                                           rows_out                 => l_rows_out);
                
                ELSE
                    g_error := 'UPDATE INTERV_PRESC_PLAN';
                    ts_comm_order_plan.upd(id_comm_order_plan_in    => i_comm_order_plan,
                                           flg_status_in            => l_comm_order_plan_flg_status,
                                           id_prof_take_in          => i_prof.id,
                                           notes_in                 => i_notes,
                                           notes_nin                => FALSE,
                                           id_prof_performed_in     => CASE i_prof_performed
                                                                           WHEN -1 THEN
                                                                            NULL
                                                                           ELSE
                                                                            i_prof_performed
                                                                       END,
                                           start_time_in            => l_start_time,
                                           start_time_nin           => FALSE,
                                           end_time_in              => l_end_time,
                                           end_time_nin             => FALSE,
                                           flg_supplies_reg_in      => i_flg_supplies,
                                           id_cdr_event_in          => i_clinical_decision_rule,
                                           id_epis_documentation_in => nvl(l_id_epis_documentation, i_epis_documentation),
                                           id_episode_write_in      => i_episode,
                                           id_prof_last_update_in   => i_prof.id,
                                           dt_last_update_tstz_in   => g_sysdate_tstz,
                                           id_po_param_reg_in       => l_id_po_param_reg,
                                           id_po_param_reg_nin      => FALSE,
                                           rows_out                 => l_rows_out);
                END IF;
            
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'COMM_ORDER_PLAN',
                                              i_rowids     => l_rows_out,
                                              o_error      => o_error);
            
            ELSIF l_comm_order_req.flg_prn = pk_procedures_constant.g_yes
            THEN
                IF l_start_time > l_end_time
                THEN
                    l_start_time := l_end_time;
                END IF;
            
                IF l_comm_order_plan.flg_status IS NOT NULL
                THEN
                    -- Editar a execução sos
                    g_error := 'CALL TO PK_COMM_ORDERS.SET_COMM_ORDER_EXECUTION_HIST';
                    IF NOT set_comm_order_execution_hist(i_lang                 => i_lang,
                                                         i_prof                 => i_prof,
                                                         i_comm_order_plan      => l_comm_order_plan.id_comm_order_plan,
                                                         o_comm_order_plan_hist => l_comm_order_plan_hist,
                                                         o_error                => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                
                    g_error := 'UPDATE COMM_ORDER_PRESC_PLAN';
                    ts_comm_order_plan.upd(id_comm_order_plan_in    => i_comm_order_plan,
                                           flg_status_in            => l_comm_order_plan_flg_status,
                                           id_prof_take_in          => i_prof.id,
                                           notes_in                 => i_notes,
                                           notes_nin                => FALSE,
                                           id_prof_performed_in     => CASE i_prof_performed
                                                                           WHEN -1 THEN
                                                                            NULL
                                                                           ELSE
                                                                            i_prof_performed
                                                                       END,
                                           start_time_in            => l_start_time,
                                           end_time_in              => l_end_time,
                                           flg_supplies_reg_in      => i_flg_supplies,
                                           id_cdr_event_in          => i_clinical_decision_rule,
                                           id_epis_documentation_in => nvl(l_id_epis_documentation, i_epis_documentation),
                                           id_episode_write_in      => i_episode,
                                           id_prof_last_update_in   => i_prof.id,
                                           dt_last_update_tstz_in   => g_sysdate_tstz,
                                           id_po_param_reg_in       => l_id_po_param_reg,
                                           id_po_param_reg_nin      => FALSE,
                                           rows_out                 => l_rows_out);
                
                ELSE
                    -- TAKE = sos
                    g_error                := 'INSERT INTERV_PRESC_PLAN (2)';
                    l_next_comm_order_plan := seq_comm_order_plan.nextval;
                    ts_comm_order_plan.ins(id_comm_order_plan_in    => l_next_comm_order_plan,
                                           id_comm_order_req_in     => l_comm_order_req.id_comm_order_req,
                                           dt_comm_order_plan_in    => g_sysdate_tstz,
                                           dt_plan_tstz_in          => g_sysdate_tstz,
                                           flg_status_in            => pk_comm_orders.g_comm_order_plan_ongoing,
                                           dt_take_tstz_in          => g_sysdate_tstz,
                                           id_prof_take_in          => i_prof.id,
                                           notes_in                 => i_notes,
                                           id_prof_performed_in     => CASE i_prof_performed
                                                                           WHEN -1 THEN
                                                                            NULL
                                                                           ELSE
                                                                            i_prof_performed
                                                                       END,
                                           start_time_in            => l_start_time,
                                           end_time_in              => l_end_time,
                                           flg_supplies_reg_in      => i_flg_supplies,
                                           id_epis_documentation_in => nvl(l_id_epis_documentation, i_epis_documentation),
                                           id_episode_write_in      => i_episode,
                                           exec_number_in           => l_exec_number,
                                           id_prof_last_update_in   => i_prof.id,
                                           dt_last_update_tstz_in   => g_sysdate_tstz,
                                           id_po_param_reg_in       => l_id_po_param_reg,
                                           rows_out                 => l_rows_out);
                
                END IF;
            
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'COMM_ORDER_PLAN',
                                              i_rowids     => l_rows_out,
                                              o_error      => o_error);
            END IF;
        
            g_error := 'OPEN C_INTERV_PRESC_PLAN_COUNT';
            OPEN c_comm_order_plan_count;
            FETCH c_comm_order_plan_count
                INTO l_comm_order_plan_count;
            CLOSE c_comm_order_plan_count;
        
            l_comm_order_req.id_status := pk_comm_orders.g_id_sts_ongoing;
            l_rows_out                 := NULL;
        
            g_error := 'UPDATE INTERV_PRESC_DET';
            ts_comm_order_req.upd(id_status_in           => l_comm_order_req.id_status,
                                  id_professional_in     => i_prof.id,
                                  dt_status_in           => g_sysdate_tstz,
                                  dt_last_update_tstz_in => g_sysdate_tstz,
                                  where_in               => ' id_status NOT IN ( ''' || l_comm_order_req.id_status ||
                                                            ''', ''' || pk_comm_orders.g_id_sts_expired ||
                                                            ''' ) AND id_comm_order_req = ' ||
                                                            l_comm_order_req.id_comm_order_req,
                                  rows_out               => l_rows_out);
        
        END IF;
    
        ts_comm_order_req.upd(id_comm_order_req_in   => l_comm_order_req.id_comm_order_req,
                              flg_action_in          => CASE
                                                            WHEN i_flg_status = g_flg_status_e THEN
                                                             g_action_executed
                                                            ELSE
                                                             g_action_monitored
                                                        END,
                              dt_last_update_tstz_in => g_sysdate_tstz,
                              rows_out               => l_rows_out);
    
        o_comm_order_plan := l_next_comm_order_plan;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'SET_COMM_ORDER_EXECUTION',
                                              o_error);
            RETURN FALSE;
    END set_comm_order_execution;

    FUNCTION set_comm_order_conclusion
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_comm_order_req  IN comm_order_req.id_comm_order_req%TYPE,
        i_comm_order_plan IN comm_order_plan.id_comm_order_plan%TYPE,
        o_comm_order_plan OUT comm_order_plan.id_comm_order_plan%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_comm_order_req IS
            SELECT cor.id_comm_order_req,
                   cor.id_status,
                   cor.flg_prn,
                   cor.id_patient,
                   cor.id_episode,
                   cor.id_order_recurr
              FROM comm_order_req cor
             INNER JOIN comm_order_plan cop
                ON cor.id_comm_order_req = cop.id_comm_order_req
             WHERE cor.id_comm_order_req = i_comm_order_req;
    
        CURSOR c_comm_order_plan IS
            SELECT cop.*
              FROM comm_order_plan cop
             WHERE cop.id_comm_order_plan = i_comm_order_plan;
    
        l_comm_order_req  c_comm_order_req%ROWTYPE;
        l_comm_order_plan c_comm_order_plan%ROWTYPE;
    
        l_comm_order_plan_hist comm_order_plan_hist.id_comm_order_plan_hist%TYPE;
    
        l_next_comm_order_plan comm_order_plan.id_comm_order_plan%TYPE;
        l_start_time           comm_order_plan.start_time%TYPE;
        l_end_time             comm_order_plan.end_time%TYPE;
        l_dt_take              comm_order_plan.dt_take_tstz%TYPE;
    
        l_exec_number NUMBER := 1;
    
        l_order_recurr_control order_recurr_control%ROWTYPE;
    
        l_rows_out table_varchar := table_varchar();
    
        g_sysdate_tstz TIMESTAMP(6) WITH LOCAL TIME ZONE;
    
        l_id_comm_order_req      table_number;
        l_id_comm_order_req_hist table_number;
    
        l_is_edit            NUMBER := 0;
        l_flg_recurr_control order_recurr_control.flg_status%TYPE;
        l_plan_start_date    order_recurr_plan.start_date%TYPE;
        l_finish_recurr      VARCHAR2(1 CHAR) := pk_procedures_constant.g_no;
    
        l_dt_next VARCHAR2(30 CHAR);
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'OPEN C_COMM_ORDER_REQ';
        OPEN c_comm_order_req;
        FETCH c_comm_order_req
            INTO l_comm_order_req;
        CLOSE c_comm_order_req;
    
        g_error := 'OPEN C_COMM_ORDER_PLAN';
        OPEN c_comm_order_plan;
        FETCH c_comm_order_plan
            INTO l_comm_order_plan;
        CLOSE c_comm_order_plan;
    
        -- retorna numero máximo da execução
        SELECT MAX(cop.exec_number)
          INTO l_exec_number
          FROM comm_order_plan cop
         WHERE cop.id_comm_order_req = i_comm_order_req
           AND cop.flg_status = g_comm_order_plan_executed;
    
        IF l_exec_number IS NULL
        THEN
            l_exec_number := 1;
        ELSE
            l_exec_number := l_exec_number + 1;
        END IF;
    
        SELECT id_order_recurr
          INTO l_order_recurr_control.id_order_recurr_plan
          FROM comm_order_req cor
         WHERE cor.id_comm_order_req = i_comm_order_req;
    
        g_error := 'CALL TO PK_PROCEDURES_CORE.SET_PROCEDURE_EXECUTION_HIST';
        IF NOT pk_comm_orders.set_comm_order_execution_hist(i_lang                 => i_lang,
                                                            i_prof                 => i_prof,
                                                            i_comm_order_plan      => i_comm_order_plan,
                                                            o_comm_order_plan_hist => l_comm_order_plan_hist,
                                                            o_error                => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        /*Plan history for control the status changes*/
        g_error := 'UPDATE INTERV_PRESC_PLAN';
        ts_comm_order_plan.upd(id_comm_order_plan_in     => i_comm_order_plan,
                               flg_status_in             => pk_comm_orders.g_comm_order_plan_executed,
                               dt_take_tstz_in           => l_dt_take,
                               id_prof_take_in           => i_prof.id,
                               notes_in                  => NULL,
                               notes_nin                 => FALSE,
                               id_prof_performed_in      => i_prof.id,
                               start_time_in             => l_start_time,
                               start_time_nin            => FALSE,
                               end_time_in               => l_end_time,
                               end_time_nin              => FALSE,
                               flg_supplies_reg_in       => NULL,
                               id_cdr_event_in           => NULL,
                               id_epis_documentation_in  => NULL,
                               id_epis_documentation_nin => FALSE,
                               id_episode_write_in       => i_episode,
                               id_prof_last_update_in    => i_prof.id,
                               dt_last_update_tstz_in    => g_sysdate_tstz,
                               id_po_param_reg_in        => NULL,
                               id_po_param_reg_nin       => FALSE,
                               rows_out                  => l_rows_out);
    
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'COMM_ORDER_PLAN',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
        IF l_comm_order_req.flg_prn = pk_alert_constant.g_no
        THEN
            g_error := 'CALL TO PK_ORDER_RECURRENCE_API_DB.GET_ORDER_RECURR_PLAN_STATUS';
            IF NOT pk_order_recurrence_api_db.get_order_recurr_plan_status(i_lang              => i_lang,
                                                                           i_prof              => i_prof,
                                                                           i_order_recurr_plan => l_order_recurr_control.id_order_recurr_plan,
                                                                           o_flg_status        => l_order_recurr_control.flg_status,
                                                                           o_last_exec_order   => l_order_recurr_control.last_exec_order,
                                                                           o_dt_last_exec      => l_order_recurr_control.dt_last_exec,
                                                                           o_error             => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            g_error := 'CALL PK_ORDER_RECURRENCE_API_DB.GET_NEXT_EXECUTION';
            IF NOT pk_order_recurrence_api_db.get_next_execution(i_lang                => i_lang,
                                                                 i_prof                => i_prof,
                                                                 i_is_edit             => l_is_edit,
                                                                 i_to_execute          => pk_alert_constant.g_yes,
                                                                 i_id_order_recurrence => l_comm_order_req.id_order_recurr,
                                                                 i_dt_next             => l_dt_next,
                                                                 i_flg_next_change     => pk_alert_constant.g_no,
                                                                 o_flag_recurr_control => l_flg_recurr_control,
                                                                 o_finish_recurr       => l_finish_recurr,
                                                                 o_plan_start_date     => l_plan_start_date,
                                                                 o_error               => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            IF l_flg_recurr_control = pk_order_recurrence_core.g_flg_status_control_active
               AND l_is_edit < 1
            THEN
                IF l_finish_recurr = pk_procedures_constant.g_yes
                THEN
                    IF NOT set_comm_order_status(i_lang                   => i_lang,
                                                 i_prof                   => i_prof,
                                                 i_id_comm_order_req      => table_number(l_comm_order_req.id_comm_order_req),
                                                 i_id_status_end          => g_id_sts_completed,
                                                 i_id_workflow_action     => g_id_action_complete,
                                                 o_id_comm_order_req      => l_id_comm_order_req,
                                                 o_id_comm_order_req_hist => l_id_comm_order_req_hist,
                                                 o_error                  => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                ELSE
                    -- retorna numero máximo da execução
                    SELECT MAX(cop.exec_number)
                      INTO l_exec_number
                      FROM comm_order_plan cop
                     WHERE cop.id_comm_order_req = i_comm_order_req
                       AND cop.flg_status = pk_comm_orders.g_comm_order_plan_executed;
                
                    IF l_exec_number IS NULL
                    THEN
                        l_exec_number := 1;
                    ELSE
                        l_exec_number := l_exec_number + 1;
                    END IF;
                
                    g_error := 'UPDATE INTERV_PRESC_PLAN';
                    ts_comm_order_plan.ins(id_comm_order_req_in  => i_comm_order_req,
                                           dt_comm_order_plan_in => g_sysdate_tstz,
                                           dt_plan_tstz_in       => l_plan_start_date,
                                           flg_status_in         => pk_comm_orders.g_comm_order_plan_req,
                                           exec_number_in        => l_exec_number,
                                           rows_out              => l_rows_out);
                
                    t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'COMM_ORDER_PLAN',
                                                  i_rowids     => l_rows_out,
                                                  o_error      => o_error);
                END IF;
            ELSIF l_finish_recurr IS NULL
            THEN
                IF NOT set_comm_order_status(i_lang                   => i_lang,
                                             i_prof                   => i_prof,
                                             i_id_comm_order_req      => table_number(l_comm_order_req.id_comm_order_req),
                                             i_id_status_end          => g_id_sts_completed,
                                             i_id_workflow_action     => g_id_action_complete,
                                             o_id_comm_order_req      => l_id_comm_order_req,
                                             o_id_comm_order_req_hist => l_id_comm_order_req_hist,
                                             o_error                  => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            END IF;
        ELSE
            SELECT MAX(cop.exec_number)
              INTO l_exec_number
              FROM comm_order_plan cop
             WHERE cop.id_comm_order_req = i_comm_order_req
               AND cop.flg_status = pk_comm_orders.g_comm_order_plan_executed;
        
            IF l_exec_number IS NULL
            THEN
                l_exec_number := 1;
            ELSE
                l_exec_number := l_exec_number + 1;
            END IF;
        
            g_error := 'UPDATE INTERV_PRESC_PLAN';
            ts_comm_order_plan.ins(id_comm_order_req_in  => i_comm_order_req,
                                   dt_comm_order_plan_in => g_sysdate_tstz,
                                   dt_plan_tstz_in       => l_plan_start_date,
                                   flg_status_in         => pk_comm_orders.g_comm_order_plan_req,
                                   exec_number_in        => l_exec_number,
                                   rows_out              => l_rows_out);
        
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'COMM_ORDER_PLAN',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
        END IF;
        o_comm_order_plan := l_next_comm_order_plan;
    
        ts_comm_order_req.upd(id_comm_order_req_in   => i_comm_order_req,
                              dt_last_update_tstz_in => current_timestamp,
                              rows_out               => l_rows_out);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'SET_COMM_ORDER_EXECUTION',
                                              o_error);
            RETURN FALSE;
    END set_comm_order_conclusion;

    FUNCTION cancel_comm_order_execution
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_comm_order_plan IN comm_order_plan.id_comm_order_plan%TYPE,
        i_dt_plan         IN VARCHAR2,
        i_cancel_reason   IN interv_presc_plan.id_cancel_reason%TYPE,
        i_cancel_notes    IN interv_presc_plan.notes_cancel%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_comm_order_req IS
            SELECT cor.id_comm_order_req,
                   cor.id_status,
                   cor.flg_prn,
                   cor.id_order_recurr,
                   cop.id_epis_documentation,
                   cop.flg_status,
                   cop.exec_number,
                   cor.id_episode id_episode
              FROM comm_order_plan cop
             INNER JOIN comm_order_req cor
                ON cop.id_comm_order_req = cor.id_comm_order_req
             WHERE cop.id_comm_order_plan = i_comm_order_plan;
    
        l_comm_order_req c_comm_order_req%ROWTYPE;
    
        l_comm_order_plan      comm_order_plan.id_comm_order_plan%TYPE;
        l_comm_order_plan_hist comm_order_plan_hist.id_comm_order_plan_hist%TYPE;
    
        l_flg_status_req comm_order_req.id_status%TYPE;
    
        l_count_co_plan_executed PLS_INTEGER := 0;
    
        l_decrement_order_control BOOLEAN := TRUE;
    
        l_rows_out table_varchar := table_varchar();
    
        l_flg_prn              comm_order_req.flg_prn%TYPE;
        l_next_comm_order_plan comm_order_plan.id_comm_order_plan%TYPE;
    
        l_from_state comm_order_plan.flg_status%TYPE;
    
        g_sysdate_tstz TIMESTAMP(6) WITH LOCAL TIME ZONE;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'OPEN C_INTERV_PRESCRIPTION';
        OPEN c_comm_order_req;
        FETCH c_comm_order_req
            INTO l_comm_order_req;
        CLOSE c_comm_order_req;
    
        -- retorna o numero de procedimentos executados da requisição
        SELECT COUNT(1)
          INTO l_count_co_plan_executed
          FROM comm_order_plan cop
         WHERE cop.id_comm_order_req = l_comm_order_req.id_comm_order_req
           AND cop.flg_status = pk_comm_orders.g_comm_order_plan_executed;
    
        IF l_comm_order_req.id_status != g_id_sts_canceled
        THEN
            g_error := 'CALL TO PK_PROCEDURES_CORE.SET_PROCEDURE_EXECUTION_HIST';
            IF NOT pk_comm_orders.set_comm_order_execution_hist(i_lang                 => i_lang,
                                                                i_prof                 => i_prof,
                                                                i_comm_order_plan      => i_comm_order_plan,
                                                                o_comm_order_plan_hist => l_comm_order_plan_hist,
                                                                o_error                => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            SELECT cop.flg_status
              INTO l_from_state
              FROM comm_order_plan cop
             WHERE cop.id_comm_order_plan = i_comm_order_plan;
        
            g_error := 'UPDATE INTERV_PRESC_PLAN';
            ts_comm_order_plan.upd(id_comm_order_plan_in     => i_comm_order_plan,
                                   flg_status_in             => CASE
                                                                    WHEN l_from_state = g_comm_order_plan_ongoing THEN
                                                                     g_comm_order_plan_discontinued
                                                                    ELSE
                                                                     g_comm_order_plan_cancel
                                                                END,
                                   id_prof_cancel_in         => i_prof.id,
                                   notes_in                  => NULL,
                                   notes_nin                 => FALSE,
                                   dt_cancel_tstz_in         => g_sysdate_tstz,
                                   notes_cancel_in           => i_cancel_notes,
                                   notes_cancel_nin          => FALSE,
                                   id_prof_performed_in      => NULL,
                                   id_prof_performed_nin     => FALSE,
                                   start_time_in             => NULL,
                                   start_time_nin            => FALSE,
                                   end_time_in               => NULL,
                                   end_time_nin              => FALSE,
                                   id_cancel_reason_in       => i_cancel_reason,
                                   id_epis_documentation_in  => NULL,
                                   id_epis_documentation_nin => FALSE,
                                   id_prof_last_update_in    => i_prof.id,
                                   dt_last_update_tstz_in    => g_sysdate_tstz,
                                   rows_out                  => l_rows_out);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'COMM_ORDER_PLAN',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            SELECT cor.flg_prn
              INTO l_flg_prn
              FROM comm_order_plan cop
              JOIN comm_order_req cor
                ON cor.id_comm_order_req = cop.id_comm_order_req
             WHERE cop.id_comm_order_plan = i_comm_order_plan;
        
            IF l_flg_prn = pk_alert_constant.g_no
            THEN
                BEGIN
                    SELECT cop.id_comm_order_plan
                      INTO l_comm_order_plan
                      FROM comm_order_plan cop
                     WHERE cop.id_comm_order_req = l_comm_order_req.id_comm_order_req
                       AND cop.flg_status = pk_comm_orders.g_comm_order_plan_pending;
                EXCEPTION
                    WHEN no_data_found THEN
                    
                        IF l_comm_order_req.flg_prn = pk_alert_constant.g_no
                        THEN
                            l_rows_out := NULL;
                        
                            BEGIN
                                SELECT cop.id_comm_order_plan
                                  INTO l_comm_order_plan
                                  FROM comm_order_plan cop
                                 WHERE cop.id_comm_order_req = l_comm_order_req.id_comm_order_req
                                   AND cop.flg_status = pk_comm_orders.g_comm_order_plan_req;
                            
                                IF i_dt_plan IS NOT NULL
                                THEN
                                    g_error := 'UPDATE INTERV_PRESC_PLAN';
                                    ts_comm_order_plan.upd(id_comm_order_plan_in  => l_comm_order_plan,
                                                           dt_plan_tstz_in        => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                   i_prof,
                                                                                                                   i_dt_plan,
                                                                                                                   NULL),
                                                           id_prof_last_update_in => i_prof.id,
                                                           dt_last_update_tstz_in => g_sysdate_tstz,
                                                           rows_out               => l_rows_out);
                                
                                    t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                                  i_prof       => i_prof,
                                                                  i_table_name => 'COMM_ORDER_PLAN',
                                                                  i_rowids     => l_rows_out,
                                                                  o_error      => o_error);
                                
                                    IF NOT
                                        pk_order_recurrence_api_db.update_order_control_last_exec(i_lang              => i_lang,
                                                                                                  i_prof              => i_prof,
                                                                                                  i_order_recurr_plan => l_comm_order_req.id_order_recurr,
                                                                                                  i_dt_last_processed => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                                       i_prof,
                                                                                                                                                       i_dt_plan,
                                                                                                                                                       NULL),
                                                                                                  o_error             => o_error)
                                    THEN
                                        RAISE g_exception;
                                    END IF;
                                END IF;
                            
                            EXCEPTION
                                WHEN no_data_found THEN
                                
                                    l_comm_order_plan := ts_comm_order_plan.next_key();
                                    g_error           := 'INSERT INTERV_PRESC_PLAN';
                                    ts_comm_order_plan.ins(id_comm_order_plan_out => l_comm_order_plan,
                                                           id_comm_order_req_in   => l_comm_order_req.id_comm_order_req,
                                                           dt_comm_order_plan_in  => g_sysdate_tstz,
                                                           dt_plan_tstz_in        => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                   i_prof,
                                                                                                                   i_dt_plan,
                                                                                                                   NULL),
                                                           flg_status_in          => g_comm_order_plan_req,
                                                           exec_number_in         => l_comm_order_req.exec_number,
                                                           rows_out               => l_rows_out);
                                
                                    t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                                  i_prof       => i_prof,
                                                                  i_table_name => 'COMM_ORDER_PLAN',
                                                                  i_rowids     => l_rows_out,
                                                                  o_error      => o_error);
                                
                                    l_decrement_order_control := FALSE;
                            END;
                        
                        ELSE
                            IF l_comm_order_req.flg_prn = pk_alert_constant.g_no
                            THEN
                                l_rows_out := NULL;
                            
                                -- Se interv_presc_plan pendente existe, então alterar a data do plano
                                g_error := 'UPDATE INTERV_PRESC_PLAN';
                                ts_comm_order_plan.upd(id_comm_order_plan_in  => l_comm_order_plan,
                                                       dt_plan_tstz_in        => pk_date_utils.get_string_tstz(i_lang,
                                                                                                               i_prof,
                                                                                                               i_dt_plan,
                                                                                                               NULL),
                                                       id_prof_last_update_in => i_prof.id,
                                                       dt_last_update_tstz_in => g_sysdate_tstz,
                                                       rows_out               => l_rows_out);
                            
                                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                              i_prof       => i_prof,
                                                              i_table_name => 'COMM_ORDER_PLAN',
                                                              i_rowids     => l_rows_out,
                                                              o_error      => o_error);
                            
                            END IF;
                        END IF;
                    
                END;
            ELSE
                g_error                := 'Inserting in COMM_ORDER_PLAN';
                l_next_comm_order_plan := seq_comm_order_plan.nextval;
                ts_comm_order_plan.ins(id_comm_order_plan_in  => l_next_comm_order_plan,
                                       id_comm_order_req_in   => l_comm_order_req.id_comm_order_req,
                                       dt_comm_order_plan_in  => g_sysdate_tstz,
                                       dt_plan_tstz_in        => g_sysdate_tstz,
                                       flg_status_in          => pk_comm_orders.g_comm_order_plan_req,
                                       dt_take_tstz_in        => g_sysdate_tstz,
                                       id_prof_take_in        => i_prof.id,
                                       id_episode_write_in    => l_comm_order_req.id_episode,
                                       exec_number_in         => l_comm_order_req.exec_number,
                                       id_prof_last_update_in => i_prof.id,
                                       dt_last_update_tstz_in => g_sysdate_tstz,
                                       id_po_param_reg_in     => NULL,
                                       rows_out               => l_rows_out);
            
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'COMM_ORDER_PLAN',
                                              i_rowids     => l_rows_out,
                                              o_error      => o_error);
            
            END IF;
        
            IF l_decrement_order_control
            THEN
                g_error := 'CALL PK_ORDER_RECURRENCE_API_DB.CANCEL_EXECUTION_ORDER';
                IF NOT pk_order_recurrence_api_db.cancel_execution_order(i_lang              => i_lang,
                                                                         i_prof              => i_prof,
                                                                         i_order_recurr_plan => l_comm_order_req.id_order_recurr,
                                                                         o_error             => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            END IF;
        
            l_rows_out := NULL;
        
            --AM actualiza a data de um procedimento agendado
            g_error := 'UPDATE INTERV_PRESCRIPTION';
            ts_comm_order_req.upd(dt_begin_in            => pk_date_utils.get_string_tstz(i_lang,
                                                                                          i_prof,
                                                                                          i_dt_plan,
                                                                                          NULL),
                                  id_professional_in     => i_prof.id,
                                  dt_status_in           => g_sysdate_tstz,
                                  dt_last_update_tstz_in => g_sysdate_tstz,
                                  where_in               => ' id_comm_order_req = ' ||
                                                            l_comm_order_req.id_comm_order_req ||
                                                            ' AND dt_begin IS NULL',
                                  rows_out               => l_rows_out);
        
            --Deve ser possível cancelar procedimentos e execuções de processos concluídos.
            IF l_comm_order_req.id_status = pk_comm_orders.g_id_sts_completed
            THEN
            
                -- Tipo: Única
                l_flg_status_req := pk_comm_orders.g_id_sts_canceled;
            
                IF l_flg_status_req IS NOT NULL
                   AND l_count_co_plan_executed > 0
                THEN
                    l_rows_out := NULL;
                
                    g_error := 'UPDATE INTERV_PRESC_DET';
                    ts_comm_order_req.upd(id_comm_order_req_in   => l_comm_order_req.id_comm_order_req,
                                          id_status_in           => l_flg_status_req,
                                          id_professional_in     => i_prof.id,
                                          dt_status_in           => g_sysdate_tstz,
                                          dt_last_update_tstz_in => g_sysdate_tstz,
                                          rows_out               => l_rows_out);
                
                END IF;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'CANCEL_COMM_ORDER_EXECUTION',
                                              o_error);
            RETURN FALSE;
    END cancel_comm_order_execution;

    FUNCTION cancel_comm_order_exec_values
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_comm_order_plan    IN comm_order_plan.id_comm_order_plan%TYPE,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_po_param_reg       IN po_param_reg.id_po_param_reg%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_comm_order_req comm_order_req.id_comm_order_req%TYPE;
    
        l_rows table_varchar;
    
    BEGIN
    
        IF i_epis_documentation IS NOT NULL
        THEN
        
            DELETE FROM epis_documentation_qualif edq
             WHERE edq.id_epis_documentation_det IN
                   (SELECT edd.id_epis_documentation_det
                      FROM epis_documentation_det edd
                     WHERE edd.id_epis_documentation = i_epis_documentation);
        
            DELETE FROM epis_documentation_det edd
             WHERE edd.id_epis_documentation = i_epis_documentation;
        
            ts_epis_documentation.del(id_epis_documentation_in => i_epis_documentation, rows_out => l_rows);
        END IF;
    
        IF i_po_param_reg IS NOT NULL
        THEN
            SELECT cop.id_comm_order_req
              INTO l_comm_order_req
              FROM comm_order_plan cop
             WHERE cop.id_comm_order_plan = i_comm_order_plan;
        
            IF NOT pk_periodic_observation.cancel_values_coll(i_lang           => i_lang,
                                                              i_prof           => i_prof,
                                                              i_comm_order_req => l_comm_order_req,
                                                              i_po_param_reg   => i_po_param_reg,
                                                              o_error          => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'CANCEL_COMM_ORDER_EXEC_VALUES',
                                              o_error);
            RETURN FALSE;
    END cancel_comm_order_exec_values;

    FUNCTION set_comm_order_execution_hist
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_comm_order_plan      IN comm_order_plan_hist.id_comm_order_plan%TYPE,
        o_comm_order_plan_hist OUT comm_order_plan_hist.id_comm_order_plan_hist%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_comm_order_plan comm_order_plan%ROWTYPE;
    
        l_comm_order_plan_hist comm_order_plan_hist%ROWTYPE;
        l_sysdate_tstz         TIMESTAMP(6) WITH LOCAL TIME ZONE;
    
    BEGIN
    
        l_sysdate_tstz := current_timestamp;
    
        g_error := 'GET INTERV_PRESC_PLAN';
        SELECT cop.*
          INTO l_comm_order_plan
          FROM comm_order_plan cop
         WHERE cop.id_comm_order_plan = i_comm_order_plan;
    
        l_comm_order_plan_hist.id_comm_order_plan_hist      := ts_comm_order_plan_hist.next_key();
        l_comm_order_plan_hist.dt_comm_order_plan_hist_tstz := l_sysdate_tstz;
        l_comm_order_plan_hist.id_comm_order_plan           := l_comm_order_plan.id_comm_order_plan;
        l_comm_order_plan_hist.id_comm_order_req            := l_comm_order_plan.id_comm_order_req;
        l_comm_order_plan_hist.id_prof_take                 := l_comm_order_plan.id_prof_take;
        l_comm_order_plan_hist.notes                        := l_comm_order_plan.notes;
        l_comm_order_plan_hist.flg_status                   := l_comm_order_plan.flg_status;
        l_comm_order_plan_hist.id_prof_cancel               := l_comm_order_plan.id_prof_cancel;
        l_comm_order_plan_hist.notes_cancel                 := l_comm_order_plan.notes_cancel;
        l_comm_order_plan_hist.id_wound_treat               := l_comm_order_plan.id_wound_treat;
        l_comm_order_plan_hist.id_episode_write             := l_comm_order_plan.id_episode_write;
        l_comm_order_plan_hist.dt_plan_tstz                 := l_comm_order_plan.dt_plan_tstz;
        l_comm_order_plan_hist.dt_take_tstz                 := l_comm_order_plan.dt_take_tstz;
        l_comm_order_plan_hist.dt_cancel_tstz               := l_comm_order_plan.dt_cancel_tstz;
        l_comm_order_plan_hist.id_prof_performed            := l_comm_order_plan.id_prof_performed;
        l_comm_order_plan_hist.start_time                   := l_comm_order_plan.start_time;
        l_comm_order_plan_hist.end_time                     := l_comm_order_plan.end_time;
        l_comm_order_plan_hist.dt_comm_order_plan_tstz      := l_comm_order_plan.dt_comm_order_plan;
        l_comm_order_plan_hist.flg_supplies_reg             := l_comm_order_plan.flg_supplies_reg;
        l_comm_order_plan_hist.id_cancel_reason             := l_comm_order_plan.id_cancel_reason;
        l_comm_order_plan_hist.id_epis_documentation        := l_comm_order_plan.id_epis_documentation;
        l_comm_order_plan_hist.id_cdr_event                 := l_comm_order_plan.id_cdr_event;
        l_comm_order_plan_hist.exec_number                  := l_comm_order_plan.exec_number;
        l_comm_order_plan_hist.id_prof_last_update          := l_comm_order_plan.id_prof_last_update;
        l_comm_order_plan_hist.dt_last_update_tstz          := l_comm_order_plan.dt_last_update_tstz;
        l_comm_order_plan_hist.id_po_param_reg              := l_comm_order_plan.id_po_param_reg;
    
        g_error := 'INSERT INTERV_PRESC_PLAN_HIST';
        ts_comm_order_plan_hist.ins(rec_in => l_comm_order_plan_hist);
    
        o_comm_order_plan_hist := l_comm_order_plan_hist.id_comm_order_plan_hist;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'SET_COMM_ORDER_EXECUTION_HIST',
                                              o_error);
            RETURN FALSE;
    END set_comm_order_execution_hist;

    FUNCTION get_order_plan_report
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_task_request  IN table_number,
        i_cpoe_dt_begin IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_cpoe_dt_end   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_task_type     IN cpoe_task_type.id_task_type%TYPE DEFAULT NULL,
        o_plan_rep      OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_order_plan_rep       t_tbl_order_recurr_plan;
        l_order_plan_rep_union t_tbl_order_recurr_plan := t_tbl_order_recurr_plan();
        l_tbl_interv_presc_det table_number;
        l_tbl_ipd_dt_begin     table_timestamp_tstz;
        l_last_reached         VARCHAR2(20 CHAR);
        l_order_recurrence     order_recurr_plan.id_order_recurr_plan%TYPE;
        l_t_order_recurr       table_number;
        l_cp_begin             TIMESTAMP WITH LOCAL TIME ZONE;
        l_cp_end               TIMESTAMP WITH LOCAL TIME ZONE;
        l_cp_begin_next        TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_interv_presc_plan_last interv_presc_plan.id_interv_presc_plan%TYPE;
        l_interv_presc_plan_next interv_presc_plan.id_interv_presc_plan%TYPE;
    
        l_order_plan_rep_max interv_presc_plan.exec_number%TYPE := NULL;
    
        l_flg_status_ipd comm_order_req.id_status%TYPE;
    
    BEGIN
    
        IF i_cpoe_dt_begin IS NULL
        THEN
            IF NOT pk_episode.get_epis_dt_begin_tstz(i_lang          => i_lang,
                                                     i_prof          => i_prof,
                                                     i_id_episode    => i_episode,
                                                     o_dt_begin_tstz => l_cp_begin,
                                                     o_error         => o_error)
            THEN
                l_cp_begin := current_timestamp;
            END IF;
        ELSE
            l_cp_begin := i_cpoe_dt_begin;
        END IF;
    
        IF i_cpoe_dt_end IS NULL
        THEN
            l_cp_end := pk_date_utils.add_days_to_tstz(i_timestamp => i_cpoe_dt_end, i_days => 1);
        ELSE
            --l_cp_end :=  pk_date_utils.add_days_to_tstz(i_timestamp => i_cpoe_dt_end, i_days => 1);
            l_cp_end := i_cpoe_dt_end;
        END IF;
    
        IF i_task_request IS NOT NULL
        THEN
            l_cp_end := i_cpoe_dt_end;
        
            FOR i IN 1 .. i_task_request.count
            LOOP
            
                BEGIN
                    SELECT a.id_order_recurr
                      INTO l_order_recurrence
                      FROM comm_order_req a
                     WHERE a.id_comm_order_req = i_task_request(i)
                       AND a.id_task_type = i_task_type
                       AND a.id_status NOT IN (pk_comm_orders.g_id_sts_draft, pk_comm_orders.g_id_sts_canceled);
                EXCEPTION
                    WHEN OTHERS THEN
                        l_order_recurrence := NULL;
                END;
            
                IF l_order_recurrence IS NOT NULL
                THEN
                    SELECT t_rec_order_recurr_plan(l_order_recurrence, ipp.exec_number, ipp.dt_plan_tstz)
                      BULK COLLECT
                      INTO l_order_plan_rep
                      FROM comm_order_plan ipp
                     WHERE ipp.id_comm_order_req = i_task_request(i)
                       AND ipp.flg_status NOT IN
                           (pk_procedures_constant.g_interv_cancel, pk_procedures_constant.g_inactive)
                     ORDER BY ipp.exec_number;
                
                    l_order_plan_rep_union := l_order_plan_rep MULTISET UNION l_order_plan_rep_union;
                
                    SELECT ipd.id_status
                      INTO l_flg_status_ipd
                      FROM comm_order_req ipd
                     WHERE ipd.id_order_recurr = l_t_order_recurr(i);
                
                    IF l_flg_status_ipd NOT IN
                       (pk_comm_orders.g_id_sts_discontinued, pk_comm_orders.g_id_sts_completed)
                    THEN
                    
                        IF l_order_plan_rep.count > 0
                        THEN
                            l_cp_begin_next := l_order_plan_rep(l_order_plan_rep.count).exec_timestamp;
                        END IF;
                    
                        IF NOT pk_order_recurrence_core.get_order_recurr_plan(i_lang                   => i_lang,
                                                                              i_prof                   => i_prof,
                                                                              i_order_plan             => l_order_recurrence,
                                                                              i_plan_start_date        => l_cp_begin,
                                                                              i_plan_end_date          => l_cp_end,
                                                                              i_proc_from_day          => l_cp_begin_next,
                                                                              i_proc_from_exec_nr      => NULL,
                                                                              i_flg_validate_proc_from => pk_alert_constant.g_yes,
                                                                              o_order_plan             => l_order_plan_rep,
                                                                              o_last_exec_reached      => l_last_reached,
                                                                              o_error                  => o_error)
                        THEN
                            RAISE g_exception;
                        END IF;
                    
                        l_order_plan_rep_union := l_order_plan_rep MULTISET UNION l_order_plan_rep_union;
                    END IF;
                ELSE
                    SELECT t_rec_order_recurr_plan(a.id_comm_order_req, NULL, a.dt_begin)
                      BULK COLLECT
                      INTO l_order_plan_rep
                      FROM comm_order_req a
                     WHERE a.id_comm_order_req = i_task_request(i)
                       AND a.id_task_type = i_task_type
                       AND a.id_status NOT IN (pk_comm_orders.g_id_sts_draft, pk_comm_orders.g_id_sts_canceled);
                
                    l_order_plan_rep_union := l_order_plan_rep MULTISET UNION l_order_plan_rep_union;
                END IF;
            END LOOP;
        
        ELSE
            SELECT nvl(pea.id_order_recurr, -1), pea.dt_begin, pea.id_comm_order_req
              BULK COLLECT
              INTO l_t_order_recurr, l_tbl_ipd_dt_begin, l_tbl_interv_presc_det
              FROM comm_order_req pea
              LEFT JOIN order_recurr_plan b
                ON pea.id_order_recurr = b.id_order_recurr_plan
             WHERE pea.id_episode = i_episode
               AND pea.id_task_type = i_task_type
               AND pea.id_status NOT IN (pk_comm_orders.g_id_sts_draft, pk_comm_orders.g_id_sts_canceled)
               AND (pea.dt_begin BETWEEN l_cp_begin AND l_cp_end OR (pea.dt_begin < l_cp_end AND b.flg_end_by = 'W'));
        
            FOR i IN 1 .. l_t_order_recurr.count
            LOOP
            
                IF l_t_order_recurr(i) != -1
                THEN
                    SELECT t_rec_order_recurr_plan(l_t_order_recurr(i), ipp.exec_number, ipp.dt_plan_tstz)
                      BULK COLLECT
                      INTO l_order_plan_rep
                      FROM comm_order_plan ipp
                     INNER JOIN comm_order_req ipd
                        ON ipp.id_comm_order_req = ipd.id_comm_order_req
                     WHERE ipd.id_order_recurr = l_t_order_recurr(i)
                       AND ipd.id_task_type = i_task_type
                       AND ipp.flg_status NOT IN
                           (pk_procedures_constant.g_interv_cancel, pk_procedures_constant.g_inactive)
                     ORDER BY ipp.exec_number;
                
                    l_order_plan_rep_union := l_order_plan_rep MULTISET UNION l_order_plan_rep_union;
                
                    SELECT ipd.id_status
                      INTO l_flg_status_ipd
                      FROM comm_order_req ipd
                     WHERE ipd.id_order_recurr = l_t_order_recurr(i);
                
                    IF l_flg_status_ipd NOT IN
                       (pk_comm_orders.g_id_sts_discontinued, pk_comm_orders.g_id_sts_completed)
                    THEN
                    
                        SELECT MAX(ipp.exec_number)
                          INTO l_order_plan_rep_max
                          FROM comm_order_plan ipp
                         INNER JOIN comm_order_req ipd
                            ON ipp.id_comm_order_req = ipd.id_comm_order_req
                         WHERE ipd.id_order_recurr = l_t_order_recurr(i)
                           AND ipd.id_task_type = i_task_type
                           AND ipp.flg_status != pk_procedures_constant.g_interv_cancel
                         ORDER BY ipp.exec_number;
                    
                        IF l_order_plan_rep.count > 0
                        THEN
                            l_cp_begin_next := l_order_plan_rep(l_order_plan_rep.count).exec_timestamp;
                        END IF;
                    
                        IF NOT pk_order_recurrence_core.get_order_recurr_plan(i_lang                   => i_lang,
                                                                         i_prof                   => i_prof,
                                                                         i_order_plan             => l_t_order_recurr(i),
                                                                         i_plan_start_date        => l_cp_begin,
                                                                         i_plan_end_date          => l_cp_end,
                                                                         i_proc_from_day          => CASE
                                                                                                         WHEN l_cp_begin_next < l_cp_begin THEN
                                                                                                          l_cp_begin
                                                                                                         ELSE
                                                                                                          l_cp_begin_next
                                                                                                     END,
                                                                         i_proc_from_exec_nr      => l_order_plan_rep_max,
                                                                         i_flg_validate_proc_from => pk_alert_constant.g_yes,
                                                                         o_order_plan             => l_order_plan_rep,
                                                                         o_last_exec_reached      => l_last_reached,
                                                                         o_error                  => o_error)
                        THEN
                            RAISE g_exception;
                        END IF;
                    END IF;
                
                    l_order_plan_rep_union := l_order_plan_rep MULTISET UNION l_order_plan_rep_union;
                ELSE
                    SELECT t_rec_order_recurr_plan(l_tbl_interv_presc_det(i), NULL, l_tbl_ipd_dt_begin(i))
                      BULK COLLECT
                      INTO l_order_plan_rep
                      FROM dual;
                
                    l_order_plan_rep_union := l_order_plan_rep MULTISET UNION l_order_plan_rep_union;
                END IF;
            END LOOP;
        END IF;
    
        OPEN o_plan_rep FOR
            SELECT DISTINCT ipd.id_comm_order_req AS id_presc,
                            pk_date_utils.date_send_tsz(i_lang => i_lang,
                                                        i_date => nvl(ipp.dt_plan_tstz, p.exec_timestamp),
                                                        i_prof => i_prof) AS dt_plan_send_format,
                            pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => ipp.start_time, i_prof => i_prof) AS dt_take_send_format,
                            ipp.notes,
                            'N' out_of_period
              FROM TABLE(l_order_plan_rep_union) p
             INNER JOIN comm_order_req ipd
                ON p.id_order_recurrence_plan = ipd.id_order_recurr
              LEFT JOIN comm_order_plan ipp
                ON ipp.id_comm_order_req = ipd.id_comm_order_req
               AND ipp.exec_number = p.exec_number
             WHERE p.exec_number IS NOT NULL
               AND p.exec_timestamp IS NOT NULL
               AND ipd.id_task_type = i_task_type
                  --AND p.exec_timestamp BETWEEN l_cp_begin AND l_cp_end
               AND ipd.id_status NOT IN (pk_comm_orders.g_id_sts_canceled, pk_comm_orders.g_id_sts_draft)
            UNION ALL
            SELECT p.id_order_recurrence_plan AS id_presc,
                   decode(b.flg_prn,
                          pk_alert_constant.g_yes,
                          NULL,
                          pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => c.dt_plan_tstz, i_prof => i_prof)) AS dt_plan_send_format,
                   pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => c.start_time, i_prof => i_prof) AS dt_take_send_format,
                   c.notes notes,
                   'N' out_of_period
              FROM TABLE(l_order_plan_rep_union) p
             INNER JOIN comm_order_req b
                ON p.id_order_recurrence_plan = b.id_comm_order_req
             INNER JOIN comm_order_plan c
                ON c.id_comm_order_req = b.id_comm_order_req
             WHERE p.exec_number IS NULL
               AND b.id_task_type = i_task_type
               AND b.id_status NOT IN (pk_comm_orders.g_id_sts_canceled, pk_comm_orders.g_id_sts_draft)
            UNION ALL
            SELECT DISTINCT ipd.id_comm_order_req id_presc,
                            NULL dt_plan_send_format,
                            get_last_order_plan_executed(i_lang, i_prof, i_episode, ipd.id_comm_order_req, l_cp_begin) dt_take_send_format,
                            NULL notes,
                            'Y' out_of_period
              FROM TABLE(l_order_plan_rep_union) p
             INNER JOIN comm_order_req ipd
                ON p.id_order_recurrence_plan = ipd.id_order_recurr
             INNER JOIN comm_order_plan ipp
                ON ipp.id_comm_order_req = ipd.id_comm_order_req
               AND ipp.exec_number = p.exec_number
             INNER JOIN order_recurr_plan orp
                ON orp.id_order_recurr_plan = ipd.id_order_recurr
             WHERE ipp.dt_take_tstz < l_cp_begin
               AND ipd.id_task_type = i_task_type
               AND ipp.dt_take_tstz IS NOT NULL
               AND (orp.flg_end_by IS NULL OR orp.flg_end_by != 'W')
               AND ipd.id_status NOT IN (pk_comm_orders.g_id_sts_canceled, pk_comm_orders.g_id_sts_draft)
             ORDER BY dt_plan_send_format;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              NULL,
                                              g_owner,
                                              g_package,
                                              'GET_ORDER_PLAN_REPORT',
                                              o_error);
            pk_types.open_my_cursor(o_plan_rep);
            RETURN FALSE;
        
    END get_order_plan_report;

    FUNCTION get_last_order_plan_executed
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE,
        i_id_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        i_cpoe_dt_end         IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2 IS
        l_ret VARCHAR2(30 CHAR);
    
    BEGIN
        SELECT pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => z.dt_take_tstz, i_prof => i_prof)
          INTO l_ret
          FROM (SELECT a.dt_take_tstz
                  FROM interv_presc_plan a
                 WHERE a.flg_status = pk_procedures_constant.g_interv_plan_executed
                   AND a.id_interv_presc_det = i_id_interv_presc_det
                   AND a.dt_take_tstz <= i_cpoe_dt_end
                 ORDER BY a.dt_take_tstz DESC) z
         WHERE rownum = 1;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_last_order_plan_executed;

BEGIN

    pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    pk_alertlog.log_init(object_name => g_package);
    g_debug := pk_alertlog.is_debug_enabled(i_object_name => g_package);

END pk_comm_orders;
/
