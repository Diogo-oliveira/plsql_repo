/*-- Last Change Revision: $Rev: 2028904 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:39 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_ref_constant AS

    TYPE ibt_varchar_varchar IS TABLE OF VARCHAR2(1000 CHAR) INDEX BY VARCHAR2(1000 CHAR);

    -- Global variables
    g_package_name  VARCHAR2(50 CHAR);
    g_package_owner VARCHAR2(50 CHAR);

    g_active    CONSTANT VARCHAR2(1 CHAR) := 'A';
    g_inactive  CONSTANT VARCHAR2(1 CHAR) := 'I';
    g_cancelled CONSTANT VARCHAR2(1 CHAR) := 'C';
    g_outdated  CONSTANT VARCHAR2(1 CHAR) := 'O';

    g_available CONSTANT VARCHAR2(1 CHAR) := 'Y';
    g_r         CONSTANT VARCHAR2(1 CHAR) := 'R';
    g_ss        CONSTANT VARCHAR2(2 CHAR) := 'SS';

    g_yes     CONSTANT VARCHAR2(1 CHAR) := 'Y';
    g_no      CONSTANT VARCHAR2(1 CHAR) := 'N';
    g_na      CONSTANT VARCHAR2(1 CHAR) := 'A'; -- Not applicable    
    g_not_app CONSTANT VARCHAR2(2 CHAR) := 'NA'; -- Not applicable

    g_validate_changes CONSTANT VARCHAR2(1) := 'V';

    -- gender
    g_gender_f CONSTANT VARCHAR2(1 CHAR) := 'F';
    g_gender_m CONSTANT VARCHAR2(1 CHAR) := 'M';
    g_gender_i CONSTANT VARCHAR2(1 CHAR) := 'I';

    -- Referral status
    g_p1_status_n       CONSTANT p1_external_request.flg_status%TYPE := 'N'; -- New (Novo);
    g_p1_status_i       CONSTANT p1_external_request.flg_status%TYPE := 'I'; -- Issued (Emitido);
    g_p1_status_c       CONSTANT p1_external_request.flg_status%TYPE := 'C'; -- Canceled (Cancelado);
    g_p1_status_b       CONSTANT p1_external_request.flg_status%TYPE := 'B'; -- Bureaucratic Decline (Recusa administrativa);
    g_p1_status_t       CONSTANT p1_external_request.flg_status%TYPE := 'T'; -- Triage (Em triagem);
    g_p1_status_a       CONSTANT p1_external_request.flg_status%TYPE := 'A'; -- Accepted (Aceite, para agendar);
    g_p1_status_r       CONSTANT p1_external_request.flg_status%TYPE := 'R'; -- Redirected (Reencaminhado);
    g_p1_status_s       CONSTANT p1_external_request.flg_status%TYPE := 'S'; -- Scheduled (Agendado);
    g_p1_status_d       CONSTANT p1_external_request.flg_status%TYPE := 'D'; -- Declined (Recusado);
    g_p1_status_m       CONSTANT p1_external_request.flg_status%TYPE := 'M'; -- Mailed (Enviada notifica¨’o);
    g_p1_status_e       CONSTANT p1_external_request.flg_status%TYPE := 'E'; -- Executed (Consulta efectivada)
    g_p1_status_o       CONSTANT p1_external_request.flg_status%TYPE := 'O'; -- Under construction (Saved)
    g_p1_status_x       CONSTANT p1_external_request.flg_status%TYPE := 'X'; -- Refused  (Pedido recusado)
    g_p1_status_f       CONSTANT p1_external_request.flg_status%TYPE := 'F'; -- Failed  (Faltou a consulta)
    g_p1_status_w       CONSTANT p1_external_request.flg_status%TYPE := 'W'; -- Ans(we)red
    g_p1_status_k       CONSTANT p1_external_request.flg_status%TYPE := 'K'; -- Answer A(k)nowledge
    g_p1_status_p       CONSTANT p1_external_request.flg_status%TYPE := 'P'; -- Printed and delivered to (P)atient    
    g_p1_status_l       CONSTANT p1_external_request.flg_status%TYPE := 'L'; -- B(L)ocked
    g_p1_status_j       CONSTANT p1_external_request.flg_status%TYPE := 'J'; -- Em aprovacao
    g_p1_status_h       CONSTANT p1_external_request.flg_status%TYPE := 'H'; -- Nao aprovado
    g_p1_status_g       CONSTANT p1_external_request.flg_status%TYPE := 'G'; -- Em colheita
    g_p1_status_q       CONSTANT p1_external_request.flg_status%TYPE := 'Q'; -- Provisionally Accepted 
    g_p1_status_u       CONSTANT p1_external_request.flg_status%TYPE := 'U'; -- Awaiting Acceptance
    g_p1_status_v       CONSTANT p1_external_request.flg_status%TYPE := 'V'; -- For approval with informed consent
    g_p1_status_z       CONSTANT p1_external_request.flg_status%TYPE := 'Z'; -- Cancel Referral request
    g_p1_status_y       CONSTANT p1_external_request.flg_status%TYPE := 'Y'; -- Declined by clinical Director(Recusado)
    g_p1_status_initial CONSTANT wf_status.id_status%TYPE := 1;

    -- handoff
    g_tr_status_pend_app      CONSTANT wf_status.id_status%TYPE := 44; -- Pending approval
    g_tr_status_approved      CONSTANT wf_status.id_status%TYPE := 45; -- Approved
    g_tr_status_declined      CONSTANT wf_status.id_status%TYPE := 46; -- Declined
    g_tr_status_cancelled     CONSTANT wf_status.id_status%TYPE := 47; -- Cancelled
    g_tr_status_inst_app      CONSTANT wf_status.id_status%TYPE := 90; -- pending institution approval
    g_tr_status_declined_inst CONSTANT wf_status.id_status%TYPE := 91; -- declined by the dest professional in the new org institution

    g_p1_pseudo_status_i1 CONSTANT VARCHAR2(2 CHAR) := 'I1'; -- Pseudo-estado para diferenciar icon do estado emitido entre a institui¿Æo que envia e a que recebe.
    g_p1_pseudo_status_i2 CONSTANT VARCHAR2(2 CHAR) := 'I2'; -- Pseudo-estado para diferenciar icon do estado emitido entre a institui¿Æo que envia e a que recebe.
    g_p1_pseudo_status_a  CONSTANT VARCHAR2(2 CHAR) := 'A1'; -- Pseudo-estado para diferenciar icon de agendar com urgencia do icon de agendar normal;
    g_p1_pseudo_status_r1 CONSTANT VARCHAR2(2 CHAR) := 'R1'; -- Pseudo-estado para diferenciar icon de reencaminhado
    g_p1_pseudo_status_r2 CONSTANT VARCHAR2(2 CHAR) := 'R2'; -- Pseudo-estado para diferenciar icon de reencaminhado
    g_p1_pseudo_status_t1 CONSTANT VARCHAR2(2 CHAR) := 'T1'; -- Pseudo-estado para diferenciar cor do icon em triagem
    g_p1_pseudo_status_r  CONSTANT VARCHAR2(2 CHAR) := 'R1'; -- Pseudo-estado para diferenciar icon de reencaminhado
    g_p1_pseudo_status_p  CONSTANT VARCHAR2(2 CHAR) := 'P1'; -- Pseudo-estado para diferenciar icon de impressão (pedidos BDNP)
    g_p1_pseudo_status_c  CONSTANT VARCHAR2(2 CHAR) := 'C1'; -- Pseudo-estado para diferenciar icon de cancelado (pedidos BDNP)

    -- Referral detail types
    g_detail_type_jstf         CONSTANT p1_detail.flg_type%TYPE := 0; -- Reason
    g_detail_type_sntm         CONSTANT p1_detail.flg_type%TYPE := 1; -- Symptomatology 
    g_detail_type_evlt         CONSTANT p1_detail.flg_type%TYPE := 2; -- Progress
    g_detail_type_hstr         CONSTANT p1_detail.flg_type%TYPE := 3; -- History
    g_detail_type_hstf         CONSTANT p1_detail.flg_type%TYPE := 4; -- Family history
    g_detail_type_obje         CONSTANT p1_detail.flg_type%TYPE := 5; -- Objective exam
    g_detail_type_cmpe         CONSTANT p1_detail.flg_type%TYPE := 6; -- Diagnostic exams
    g_detail_type_nadm         CONSTANT p1_detail.flg_type%TYPE := 7; -- Notes to the registrar
    g_detail_type_ntri         CONSTANT p1_detail.flg_type%TYPE := 8; -- Notes to the triage physician
    g_detail_type_ndec         CONSTANT p1_detail.flg_type%TYPE := 9; -- Decision notes
    g_detail_type_ncan         CONSTANT p1_detail.flg_type%TYPE := 10; -- Cancellation notes
    g_detail_type_bdcl         CONSTANT p1_detail.flg_type%TYPE := 11; -- Administrative refusal notes
    g_detail_type_admi         CONSTANT p1_detail.flg_type%TYPE := 12; -- Notes from the sender Registrar    
    g_detail_type_a_obs        CONSTANT p1_detail.flg_type%TYPE := 13; -- Observation summary
    g_detail_type_a_ter        CONSTANT p1_detail.flg_type%TYPE := 14; -- Treatment proposal
    g_detail_type_a_exa        CONSTANT p1_detail.flg_type%TYPE := 15; -- New exams proposal   
    g_detail_type_a_con        CONSTANT p1_detail.flg_type%TYPE := 16; -- Conclusion 
    g_detail_type_note         CONSTANT p1_detail.flg_type%TYPE := 17; -- Analysis Notes 
    g_detail_type_nblc         CONSTANT p1_detail.flg_type%TYPE := 18; -- Referral blocking notes
    g_detail_type_item         CONSTANT p1_detail.flg_type%TYPE := 19; -- Referral Items (Circle UK)
    g_detail_type_ubrn         CONSTANT p1_detail.flg_type%TYPE := 20; -- Referral URN (Circle UK)
    g_detail_type_rrn          CONSTANT p1_detail.flg_type%TYPE := 21; -- Registrar request notes
    g_detail_type_med          CONSTANT p1_detail.flg_type%TYPE := 22; -- Medication (GP Portal)
    g_detail_type_begin_sch    CONSTANT p1_detail.flg_type%TYPE := 23; -- Begin Schedule (GP Portal)  
    g_detail_type_miss         CONSTANT p1_detail.flg_type%TYPE := 24; -- Missed appointment notes
    g_detail_type_transresp    CONSTANT p1_detail.flg_type%TYPE := 25; -- Transf. Resp        
    g_detail_type_req_can      CONSTANT p1_detail.flg_type%TYPE := 26; -- Request a referral cancel notes
    g_detail_type_req_can_answ CONSTANT p1_detail.flg_type%TYPE := 27; -- Answer a cancellation request notes
    g_detail_type_prof_sch     CONSTANT p1_detail.flg_type%TYPE := 28; -- Professional ID to schedule (GP Portal)
    g_detail_type_dcl_r        CONSTANT p1_detail.flg_type%TYPE := 29; -- notes declining to the registrar
    g_detail_type_auge         CONSTANT p1_detail.flg_type%TYPE := 30; -- AUGE
    g_detail_type_end_sch      CONSTANT p1_detail.flg_type%TYPE := 31; -- End Schedule (GP Portal)
    g_detail_type_ndec_cd      CONSTANT p1_detail.flg_type%TYPE := 32; -- Decision notes cin Dir
    g_detail_type_fpriority    CONSTANT p1_detail.flg_type%TYPE := 33; -- FLG_PRIORITY
    g_detail_type_fhome        CONSTANT p1_detail.flg_type%TYPE := 34; -- FLG_HOME
    g_detial_type_vist_dt_cc   CONSTANT p1_detail.flg_type%TYPE := 35; -- Visit date Cegonha Carioca -- BR
    g_detial_type_wd_cc        CONSTANT p1_detail.flg_type%TYPE := 36; -- Week day Cegonha Carioca -- BR
    g_detial_type_sector_cc    CONSTANT p1_detail.flg_type%TYPE := 37; -- Sector Cegonha Carioca -- BR
    g_detial_type_resp_cc      CONSTANT p1_detail.flg_type%TYPE := 38; -- Prof. Resp. Cegonha Carioca -- BR
    g_detial_type_notes_cc     CONSTANT p1_detail.flg_type%TYPE := 39; -- NOTES Cegonha Carioca -- BR
    g_detail_type_system       CONSTANT p1_detail.flg_type%TYPE := 40; -- System notes - used by support
    g_detail_type_vs           CONSTANT p1_detail.flg_type%TYPE := 43; -- Vital Signs -- MX 
    g_detail_type_answ_evol    CONSTANT p1_detail.flg_type%TYPE := 44; -- Referral answer2 Evolution -- MX
    g_detail_type_dt_come_back CONSTANT p1_detail.flg_type%TYPE := 45; -- Referral answer2 Date of comming back -- MX

    -- Referral tracking record type
    g_tracking_type_s CONSTANT p1_tracking.flg_type%TYPE := 'S'; -- Mudan¨a de estado
    g_tracking_type_p CONSTANT p1_tracking.flg_type%TYPE := 'P'; -- Encaminhamento para outro profissional
    g_tracking_type_c CONSTANT p1_tracking.flg_type%TYPE := 'C'; -- Encaminhamento para outro servi¨o clinico
    g_tracking_type_r CONSTANT p1_tracking.flg_type%TYPE := 'R'; -- Leitura do pedido
    g_tracking_type_u CONSTANT p1_tracking.flg_type%TYPE := 'U'; -- Update de dados (JS: 10-04-2007)    
    g_tracking_type_t CONSTANT p1_tracking.flg_type%TYPE := 'T'; -- Responsibility Transf.
    g_tracking_type_m CONSTANT p1_tracking.flg_type%TYPE := 'M'; -- Migration record

    g_tracking_subtype_r CONSTANT p1_tracking.flg_subtype%TYPE := 'R'; -- Re-schedule
    g_tracking_subtype_c CONSTANT p1_tracking.flg_subtype%TYPE := 'C'; -- Cancel schedule
    g_tracking_subtype_e CONSTANT p1_tracking.flg_subtype%TYPE := 'E'; -- External (refused by interface)

    -- Types of referrals
    g_p1_type_c      CONSTANT p1_external_request.flg_type%TYPE := 'C'; -- Consultation
    g_p1_type_a      CONSTANT p1_external_request.flg_type%TYPE := 'A'; -- Analysis
    g_p1_type_i      CONSTANT p1_external_request.flg_type%TYPE := 'I'; -- Image
    g_p1_type_e      CONSTANT p1_external_request.flg_type%TYPE := 'E'; -- Other exams
    g_p1_type_p      CONSTANT p1_external_request.flg_type%TYPE := 'P'; -- Intervention
    g_p1_type_f      CONSTANT p1_external_request.flg_type%TYPE := 'F'; -- Physiatrics    
    g_p1_type_s      CONSTANT p1_external_request.flg_type%TYPE := 'S'; -- Surgery
    g_p1_type_n      CONSTANT p1_external_request.flg_type%TYPE := 'N'; -- Inpatient requests    
    g_analysis_group CONSTANT VARCHAR2(1 CHAR) := 'G'; -- Analysis group

    -- Types of referral tasks
    g_p1_task_done_type_z CONSTANT p1_task_done.flg_type%TYPE := 'Z'; -- Complete (P)atient data
    g_p1_task_done_type_s CONSTANT p1_task_done.flg_type%TYPE := 'S'; -- To (S)chedule
    g_p1_task_done_type_c CONSTANT p1_task_done.flg_type%TYPE := 'C'; -- To (C)onsultation

    -- Referral diagnosis type
    g_exr_diag_type_p CONSTANT p1_exr_diagnosis.flg_type%TYPE := 'P'; -- Health problem
    g_exr_diag_type_d CONSTANT p1_exr_diagnosis.flg_type%TYPE := 'D'; -- Diagnosis (Sender)
    g_exr_diag_type_a CONSTANT p1_exr_diagnosis.flg_type%TYPE := 'A'; -- Diagnosis (Answer)
    g_exr_diag_type_r CONSTANT p1_exr_diagnosis.flg_type%TYPE := 'R'; -- Health problem (Answer)
    -- Referral diagnosis 'other'
    g_exr_diag_id_other CONSTANT p1_exr_diagnosis.id_diagnosis%TYPE := -1; -- other diagnosis (desc_description filled)
    -- Referral req type
    g_p1_req_type_m CONSTANT p1_external_request.req_type%TYPE := 'M'; -- M - Manual

    -- Referral decision urg level
    g_decision_urg_level_normal CONSTANT p1_external_request.decision_urg_level%TYPE := 3; -- Normal
    g_decision_urg_level_pri    CONSTANT p1_external_request.decision_urg_level%TYPE := 2; -- Priority
    g_decision_urg_level_v_pri  CONSTANT p1_external_request.decision_urg_level%TYPE := 1; -- Very priority

    -- Referral profiles
    --PT
    -- MK 1
    g_profile_med_cs    CONSTANT profile_template.id_profile_template%TYPE := 300;
    g_profile_adm_cs    CONSTANT profile_template.id_profile_template%TYPE := 310;
    g_profile_adm_cs_vo CONSTANT profile_template.id_profile_template%TYPE := 313;
    g_profile_adm_hs    CONSTANT profile_template.id_profile_template%TYPE := 320;
    g_profile_adm_hs_vo CONSTANT profile_template.id_profile_template%TYPE := 323;
    g_profile_med_hs    CONSTANT profile_template.id_profile_template%TYPE := 330;
    g_profile_intf      CONSTANT profile_template.id_profile_template%TYPE := 399;

    --BR
    -- MK 3
    g_profile_med_cs_br CONSTANT profile_template.id_profile_template%TYPE := 302;
    g_profile_adm_cs_br CONSTANT profile_template.id_profile_template%TYPE := 312;

    -- CL
    -- MK 12
    g_profile_med_cs_cl CONSTANT profile_template.id_profile_template%TYPE := 301;
    g_profile_adm_cs_cl CONSTANT profile_template.id_profile_template%TYPE := 311;
    g_profile_adm_hs_cl CONSTANT profile_template.id_profile_template%TYPE := 321;
    g_profile_med_hs_cl CONSTANT profile_template.id_profile_template%TYPE := 331;

    --UK
    -- MK 8   
    g_profile_planner CONSTANT profile_template.id_profile_template%TYPE := 325;

    -- NL
    -- MK 5
    g_profile_gp_med CONSTANT profile_template.id_profile_template%TYPE := 14960;
    g_profile_gp_adm CONSTANT profile_template.id_profile_template%TYPE := 15460;

    -- Referral completion options
    g_ref_compl_type_p CONSTANT ref_completion.flg_type%TYPE := 'P';
    g_ref_compl_type_e CONSTANT ref_completion.flg_type%TYPE := 'E';
    g_ref_compl_type_a CONSTANT ref_completion.flg_type%TYPE := 'A';
    g_ref_compl_type_s CONSTANT ref_completion.flg_type%TYPE := 'S';

    g_ref_compl_330_10    CONSTANT ref_completion.id_ref_completion%TYPE := 2; -- id_ref_completion form 330.10 PT
    g_ref_compl_print_req CONSTANT ref_completion.id_ref_completion%TYPE := 3; -- Imprimir requisição (ALL Markets)
    g_ref_compl_ap_cnes   CONSTANT ref_completion.id_ref_completion%TYPE := 5; -- Requisição de exames externos BR
    g_ref_compl_ge        CONSTANT ref_completion.id_ref_completion%TYPE := 6; -- guia de encaminhamento BR
    g_ref_compl_cc        CONSTANT ref_completion.id_ref_completion%TYPE := 7; -- Cegonha carioca BR
    g_ref_compl_ordon     CONSTANT ref_completion.id_ref_completion%TYPE := 9; -- Ordonnance
    g_ref_compl_save      CONSTANT ref_completion.id_ref_completion%TYPE := 10; -- save
    g_ref_compl_duplicata CONSTANT ref_completion.id_ref_completion%TYPE := 11; -- duplicata
    g_ref_compl_reprint   CONSTANT ref_completion.id_ref_completion%TYPE := 12; -- reprint

    -- MCDT codification
    g_codification_p CONSTANT codification.id_codification%TYPE := 1;
    g_codification_c CONSTANT codification.id_codification%TYPE := 2;

    -- Institutions type
    g_hospital         CONSTANT institution.flg_type%TYPE := pk_alert_constant.g_inst_type_hospital;
    g_private_practice CONSTANT institution.flg_type%TYPE := pk_alert_constant.g_inst_type_private_practice;
    g_primary_care     CONSTANT institution.flg_type%TYPE := pk_alert_constant.g_inst_type_primary_care;

    -- prof cat 
    -- flg_types
    g_doctor       CONSTANT category.flg_type%TYPE := pk_alert_constant.g_cat_type_doc;
    g_technician   CONSTANT category.flg_type%TYPE := pk_alert_constant.g_cat_type_technician;
    g_nutritionist CONSTANT category.flg_type%TYPE := pk_alert_constant.g_cat_type_nutritionist;
    g_nurse        CONSTANT category.flg_type%TYPE := pk_alert_constant.g_cat_type_nurse;
    g_registrar    CONSTANT category.flg_type%TYPE := pk_alert_constant.g_cat_type_registrar;
    g_psychologist CONSTANT category.flg_type%TYPE := pk_alert_constant.g_cat_type_psychologist;
    -- IDs
    --g_med_cat    CONSTANT category.id_category%TYPE := 1; -- Doctor
    g_cat_id_med CONSTANT category.id_category%TYPE := 1; -- Doctor
    g_cat_id_adm CONSTANT category.id_category%TYPE := 4;

    -- flg_type from the from the exam and intervention req
    g_exam_exec_w CONSTANT exam_dep_clin_serv.flg_type%TYPE := 'W';
    g_interv_exec_w interv_dep_clin_serv.flg_type%TYPE := 'W';

    -- FLG_REFERRAL
    g_flg_referral_a CONSTANT VARCHAR2(1 CHAR) := 'A'; -- Available
    g_flg_referral_r CONSTANT VARCHAR2(1 CHAR) := 'R'; -- Reserved
    g_flg_referral_s CONSTANT VARCHAR2(1 CHAR) := 'S'; -- Sent
    g_flg_referral_i CONSTANT VARCHAR2(1 CHAR) := 'I'; -- Issued (Sent electronic)

    g_status_selected CONSTANT prof_dep_clin_serv.flg_status%TYPE := pk_alert_constant.g_status_selected;

    -- Referral detail status
    g_detail_status_a CONSTANT p1_detail.flg_status%TYPE := 'A'; -- Active
    g_detail_status_c CONSTANT p1_detail.flg_status%TYPE := 'C'; -- Canceled
    g_detail_status_o CONSTANT p1_detail.flg_status%TYPE := 'O'; -- Outdated

    -- Referral match status
    g_match_status_a CONSTANT p1_match.flg_status%TYPE := 'A'; -- Active
    g_match_status_c CONSTANT p1_match.flg_status%TYPE := 'C'; -- Canceled

    -- Referrals tasks status
    g_p1_task_done_tdone_y CONSTANT p1_task_done.flg_task_done%TYPE := 'Y'; -- Completed
    g_p1_task_done_tdone_n CONSTANT p1_task_done.flg_task_done%TYPE := 'N'; -- Not completed

    -- Referrals tasks operators (flash)
    g_task_done_insert CONSTANT PLS_INTEGER := 1; -- insert task done
    g_task_done_delete CONSTANT PLS_INTEGER := 0; -- delete task done from db
    g_task_done_update CONSTANT PLS_INTEGER := 2; -- cancel task done

    g_zero CONSTANT PLS_INTEGER := 0; -- ZERO

    -- actions to process when changing referral status (INTERNAL_NAME)
    g_ref_action_c     CONSTANT wf_workflow_action.internal_name%TYPE := 'REF_CANCEL';
    g_ref_action_i     CONSTANT wf_workflow_action.internal_name%TYPE := 'REF_ISSUE';
    g_ref_action_n     CONSTANT wf_workflow_action.internal_name%TYPE := 'REF_NEW';
    g_ref_action_m     CONSTANT wf_workflow_action.internal_name%TYPE := 'REF_MAIL';
    g_ref_action_t     CONSTANT wf_workflow_action.internal_name%TYPE := 'REF_TRIAGE';
    g_ref_action_b     CONSTANT wf_workflow_action.internal_name%TYPE := 'REF_DECLINE_B';
    g_ref_action_a     CONSTANT wf_workflow_action.internal_name%TYPE := 'REF_ACCEPTED';
    g_ref_action_cs    CONSTANT wf_workflow_action.internal_name%TYPE := 'REF_CHANGE_CS';
    g_ref_action_d     CONSTANT wf_workflow_action.internal_name%TYPE := 'REF_DECLINE';
    g_ref_action_x     CONSTANT wf_workflow_action.internal_name%TYPE := 'REF_REFUSE';
    g_ref_action_r     CONSTANT wf_workflow_action.internal_name%TYPE := 'REF_FORWARD';
    g_ref_action_di    CONSTANT wf_workflow_action.internal_name%TYPE := 'REF_CHANGE_INST';
    g_ref_action_w     CONSTANT wf_workflow_action.internal_name%TYPE := 'REF_ANSWER';
    g_ref_action_f     CONSTANT wf_workflow_action.internal_name%TYPE := 'REF_MISSED';
    g_ref_action_s     CONSTANT wf_workflow_action.internal_name%TYPE := 'REF_SCHEDULE';
    g_ref_action_e     CONSTANT wf_workflow_action.internal_name%TYPE := 'REF_EFFECTIVE';
    g_ref_action_k     CONSTANT wf_workflow_action.internal_name%TYPE := 'REF_ANSWER_READ';
    g_ref_action_csh   CONSTANT wf_workflow_action.internal_name%TYPE := 'REF_CANCEL_SCH';
    g_ref_action_l     CONSTANT wf_workflow_action.internal_name%TYPE := 'REF_BLOCK';
    g_ref_action_unl   CONSTANT wf_workflow_action.internal_name%TYPE := 'REF_UNBLOCK';
    g_ref_action_j     CONSTANT wf_workflow_action.internal_name%TYPE := 'REF_FOR_APPROVAL';
    g_ref_action_h     CONSTANT wf_workflow_action.internal_name%TYPE := 'REF_NOT_APPROVED';
    g_ref_action_v     CONSTANT wf_workflow_action.internal_name%TYPE := 'REF_APPROVED';
    g_ref_action_z     CONSTANT wf_workflow_action.internal_name%TYPE := 'REF_CANCEL_REQ'; -- ACM, 2010-09-15: ALERT-75907 - Cancel referral request
    g_ref_action_zdn   CONSTANT wf_workflow_action.internal_name%TYPE := 'REF_CANCEL_REQ_DENY'; -- ACM, 2010-09-15: ALERT-75907 - Cancel referral request deny
    g_ref_action_dcl_r CONSTANT wf_workflow_action.internal_name%TYPE := 'REF_DECLINE_TO_REG'; -- ACM, 2010-10-08: ALERT-75390       
    g_ref_action_q     CONSTANT wf_workflow_action.internal_name%TYPE := 'REF_TEMP_APPROV';
    g_ref_action_u     CONSTANT wf_workflow_action.internal_name%TYPE := 'REF_PEND_APPROV';
    g_ref_action_y     CONSTANT wf_workflow_action.internal_name%TYPE := 'REF_DECLINE_CLINDIR'; -- JB 2011-03-24 ALERT-167730 
    g_ref_action_uts   CONSTANT wf_workflow_action.internal_name%TYPE := 'REF_UNDO_TO_SCHEDULE';
    g_ref_action_utm   CONSTANT wf_workflow_action.internal_name%TYPE := 'REF_UNDO_TO_MAIL';
    g_ref_action_ute   CONSTANT wf_workflow_action.internal_name%TYPE := 'REF_UNDO_TO_EFFECTIVE';

    -- hand off actions
    g_ref_tr_pend_app      CONSTANT wf_workflow_action.id_workflow_action%TYPE := 30; -- TR_PENDING_APPROVAL
    g_ref_tr_approved      CONSTANT wf_workflow_action.id_workflow_action%TYPE := 31; -- TR_APPROVED
    g_ref_tr_rejected      CONSTANT wf_workflow_action.id_workflow_action%TYPE := 32; -- TR_REJECTED
    g_ref_tr_cancelled     CONSTANT wf_workflow_action.id_workflow_action%TYPE := 33; -- TR_CANCELLED
    g_ref_tr_declined      CONSTANT wf_workflow_action.id_workflow_action%TYPE := 39; -- TR_DECLINED
    g_ref_tr_approved_inst CONSTANT wf_workflow_action.id_workflow_action%TYPE := 40; -- TR_APPROVED_INST

    -- workflow positions in table_varchar init array
    g_idx_id_ref             CONSTANT PLS_INTEGER := 1;
    g_idx_id_patient         CONSTANT PLS_INTEGER := 2;
    g_idx_id_inst_orig       CONSTANT PLS_INTEGER := 3;
    g_idx_id_inst_dest       CONSTANT PLS_INTEGER := 4;
    g_idx_id_dcs             CONSTANT PLS_INTEGER := 5;
    g_idx_id_speciality      CONSTANT PLS_INTEGER := 6;
    g_idx_flg_type           CONSTANT PLS_INTEGER := 7;
    g_idx_decision_urg_level CONSTANT PLS_INTEGER := 8;
    g_idx_id_prof_requested  CONSTANT PLS_INTEGER := 9;
    g_idx_id_prof_redirected CONSTANT PLS_INTEGER := 10;
    g_idx_id_prof_status     CONSTANT PLS_INTEGER := 11;
    g_idx_external_sys       CONSTANT PLS_INTEGER := 12;
    g_idx_location           CONSTANT PLS_INTEGER := 13; -- status
    g_idx_completed          CONSTANT PLS_INTEGER := 14; -- transition 
    g_idx_id_action          CONSTANT PLS_INTEGER := 15;
    g_idx_flg_status         CONSTANT PLS_INTEGER := 16;
    g_idx_n_auto_trans       CONSTANT PLS_INTEGER := 17; --  number of auto transitions done at once
    g_idx_flg_prof_dcs       CONSTANT PLS_INTEGER := 18; --  professional related to the dep_clin_serv
    g_idx_prof_clin_dir      CONSTANT PLS_INTEGER := 19; --  professional is clinical director in this institution

    -- hand off workflow positions in table_varchar init array
    g_idx_tr_id_tr         CONSTANT PLS_INTEGER := 1; -- hand off identifier
    g_idx_tr_id_ref        CONSTANT PLS_INTEGER := 2; -- referral identifier
    g_idx_tr_id_prof_owner CONSTANT PLS_INTEGER := 3; -- owner of the hand off
    g_idx_tr_id_prof_dest  CONSTANT PLS_INTEGER := 4; -- professional to which the referral is forward
    g_idx_tr_id_inst_orig  CONSTANT PLS_INTEGER := 5; -- hand off origin institution identifier
    g_idx_tr_id_inst_dest  CONSTANT PLS_INTEGER := 6; -- hand off dest institution identifier
    g_idx_tr_user_answ     CONSTANT PLS_INTEGER := 7; -- user answer

    g_max_auto_transitions CONSTANT PLS_INTEGER := 5; -- maximum number of allowed auto transitions at once

    -- referral software
    g_id_soft_referral CONSTANT software.id_software%TYPE := 4;

    -- referral modules
    g_sc_ref_module          CONSTANT sys_config.id_sys_config%TYPE := 'REF_MODULE';
    g_sc_ref_module_circle   CONSTANT sys_config.value%TYPE := 'CIRCLE'; -- circle module
    g_sc_ref_module_generic  CONSTANT sys_config.value%TYPE := 'GENERIC'; -- generic module
    g_sc_ref_module_gpportal CONSTANT sys_config.value%TYPE := 'GPPORTAL'; -- gp portal module
    g_sc_ref_module_acss     CONSTANT sys_config.value%TYPE := 'ACSS'; -- acss module

    -- workflow engine
    g_wf_pcc_hosp        CONSTANT wf_workflow.id_workflow%TYPE := 1; -- from Primary Care Center to Hospital
    g_wf_hosp_hosp       CONSTANT wf_workflow.id_workflow%TYPE := 2; -- from Hospital to Hospital
    g_wf_srv_srv         CONSTANT wf_workflow.id_workflow%TYPE := 3; -- from Service to Service (inside the Hospital)
    g_wf_x_hosp          CONSTANT wf_workflow.id_workflow%TYPE := 4; -- at Hospital Entrance    
    g_wf_circle_normal   CONSTANT wf_workflow.id_workflow%TYPE := 5; -- Circle Normal
    g_wf_circle_cb       CONSTANT wf_workflow.id_workflow%TYPE := 6; -- Circle Choose and Book
    g_wf_fertis          CONSTANT wf_workflow.id_workflow%TYPE := 8; -- FERTIS
    g_wf_transfresp      CONSTANT wf_workflow.id_workflow%TYPE := 10; -- Professional Hand off 
    g_wf_transfresp_inst CONSTANT wf_workflow.id_workflow%TYPE := 11; -- Institution Hand off
    g_wf_gp              CONSTANT wf_workflow.id_workflow%TYPE := 11; -- GPPortal
    g_wf_ref_but         CONSTANT wf_workflow.id_workflow%TYPE := 28; -- Referral button Care-> Referral MK BR
    g_wf_cc              CONSTANT wf_workflow.id_workflow%TYPE := 29; -- Referral button Care-> Referral Cegonha carioca MK BR

    -- referral functionality
    g_func_d               CONSTANT sys_functionality.id_functionality%TYPE := 4; -- Triage physician (speciality)
    g_func_t               CONSTANT sys_functionality.id_functionality%TYPE := 5; -- Triage physician
    g_func_c               CONSTANT sys_functionality.id_functionality%TYPE := 10; -- Consulting physician
    g_ref_func_cd          CONSTANT sys_functionality.id_functionality%TYPE := 15; -- Clinical director    
    g_func_ref_create      CONSTANT sys_functionality.id_functionality%TYPE := 1005; -- Create Referral
    g_pat_create           CONSTANT sys_functionality.id_functionality%TYPE := 1505; -- Create Patients
    g_func_ref_handoff_app CONSTANT sys_functionality.id_functionality%TYPE := 1007; -- Hand off approval

    -- referral reason codes
    g_reason_code_c CONSTANT p1_reason_code.flg_type%TYPE := 'C'; -- Cancellation
    g_reason_code_d CONSTANT p1_reason_code.flg_type%TYPE := 'D'; -- Triage physician decline
    g_reason_code_b CONSTANT p1_reason_code.flg_type%TYPE := 'B'; -- Sent back by registrar
    g_reason_code_x CONSTANT p1_reason_code.flg_type%TYPE := 'X'; -- Triage physician refusal
    g_reason_code_i CONSTANT p1_reason_code.flg_type%TYPE := 'I'; -- Triage physician declines referral to dest registrar
    g_reason_code_t CONSTANT p1_reason_code.flg_type%TYPE := 'T'; -- Responsibility Transf.
    g_reason_code_f CONSTANT p1_reason_code.flg_type%TYPE := 'F'; -- Failed appointment
    g_reason_code_y CONSTANT p1_reason_code.flg_type%TYPE := 'Y'; -- Sent back by clinical director
    g_reason_code_q CONSTANT p1_reason_code.flg_type%TYPE := 'Q'; -- Pending wf 28
    g_reason_code_a CONSTANT p1_reason_code.flg_type%TYPE := 'A'; -- Appointment cancelation
    g_reason_code_z CONSTANT p1_reason_code.flg_type%TYPE := 'Z'; -- Request cancellation

    -- sys_config
    g_sc_multi_institution     CONSTANT sys_config.id_sys_config%TYPE := 'MULTI_INSTITUTION';
    g_ref_external_inst        CONSTANT sys_config.id_sys_config%TYPE := 'REF_EXTERNAL_INST';
    g_ref_task_inf_consent     CONSTANT sys_config.id_sys_config%TYPE := 'REF_TASK_INFORMED_CONSENT';
    g_p1_auto_login_pass       CONSTANT sys_config.id_sys_config%TYPE := 'P1_AUTO_LOGIN_PASS';
    g_ident_health_plan        CONSTANT sys_config.id_sys_config%TYPE := 'ADT_NATIONAL_HEALTH_PLAN_ID'; --'IDENT_ID_HEALTH_PLAN';
    g_ext_sys_fertis           CONSTANT sys_config.id_sys_config%TYPE := 'REF_EXT_SYS_FERTIS';
    g_ref_inst_diag_list       CONSTANT sys_config.id_sys_config%TYPE := 'REF_INST_DIAG_LIST';
    g_ref_adt_available        CONSTANT sys_config.id_sys_config%TYPE := 'REF_ADT_AVAILABLE';
    g_ref_match_available      CONSTANT sys_config.id_sys_config%TYPE := 'REF_MATCH_AVAILABLE';
    g_ref_ext_session_hist     CONSTANT sys_config.id_sys_config%TYPE := 'REF_EXT_SESSION_HIST';
    g_ref_ext_session_timout   CONSTANT sys_config.id_sys_config%TYPE := 'REF_EXT_SESSION_TIMEOUT';
    g_ref_num_req_mask         CONSTANT sys_config.id_sys_config%TYPE := 'REF_NUM_REQ_MASK';
    g_ref_create_msg           CONSTANT sys_config.id_sys_config%TYPE := 'REF_CREATE_MESSAGE';
    g_ref_temp_msg             CONSTANT sys_config.id_sys_config%TYPE := 'REF_TEMP_MESSAGE';
    g_sc_cancel_req_answ       CONSTANT sys_config.id_sys_config%TYPE := 'REF_CANCEL_REQUEST_ANSWER';
    g_sc_num_record_search     CONSTANT sys_config.id_sys_config%TYPE := 'NUM_RECORD_SEARCH';
    g_sc_ref_days_bcancel      CONSTANT sys_config.id_sys_config%TYPE := 'REF_DAYS_BCANCEL';
    g_sc_ref_adw_column        CONSTANT sys_config.id_sys_config%TYPE := 'REF_ADW_COLUMN';
    g_ref_ignore_reason_c_i    CONSTANT sys_config.id_sys_config%TYPE := 'REF_IGNORE_REASON_C_INACTIVE';
    g_ref_prof_not_registered  CONSTANT sys_config.id_sys_config%TYPE := 'REF_PROF_NOT_REGISTERED';
    g_ref_network_available    CONSTANT sys_config.id_sys_config%TYPE := 'REF_NETWORK_AVAILABLE';
    g_ref_net_all_inst         CONSTANT sys_config.id_sys_config%TYPE := 'REF_NET_ALL_INST';
    g_ref_mcdt_bdnp            CONSTANT sys_config.id_sys_config%TYPE := 'REFERRAL_MCDT_BDNP';
    g_ref_mcdt_bdnp_form_type  CONSTANT sys_config.id_sys_config%TYPE := 'REFERRAL_MCDT_BDNP_FORM_TYPE';
    g_ref_via_bdnp             CONSTANT sys_config.id_sys_config%TYPE := 'REFERRAL_VIA_BDNP';
    g_accs_orig_soft_code      CONSTANT sys_config.id_sys_config%TYPE := 'ACCS_ORIG_SOFT_CODE';
    g_acss_db_instance         CONSTANT sys_config.id_sys_config%TYPE := 'ACSS_DB_INSTANCE';
    g_referral_button_wf       CONSTANT sys_config.id_sys_config%TYPE := 'REFERRAL_BUTTON_WF';
    g_referral_button_print    CONSTANT sys_config.id_sys_config%TYPE := 'REFERRAL_BUTTON_PRINT';
    g_referral_need_aproval    CONSTANT sys_config.id_sys_config%TYPE := 'REFERRAL_NEED_APROVAL';
    g_ref_visit_not_aprove     CONSTANT sys_config.id_sys_config%TYPE := 'REF_VISIT_NOT_APROVE';
    g_ref_analysis_not_aprove  CONSTANT sys_config.id_sys_config%TYPE := 'REF_ANALYSIS_NOT_APROVE';
    g_ref_exam_not_aprove      CONSTANT sys_config.id_sys_config%TYPE := 'REF_EXAM_NOT_APROVE';
    g_ref_interv_not_aprove    CONSTANT sys_config.id_sys_config%TYPE := 'REF_INTERV_NOT_APROVE';
    g_ref_waiting_time         CONSTANT sys_config.id_sys_config%TYPE := 'REF_WAITING_TIME';
    g_ap                       CONSTANT sys_config.id_sys_config%TYPE := 'AP';
    g_cnes                     CONSTANT sys_config.id_sys_config%TYPE := 'CNES';
    g_ref_priority_level       CONSTANT sys_config.id_sys_config%TYPE := 'REF_PRIORITY_LEVEL';
    g_sc_other_institution     CONSTANT sys_config.id_sys_config%TYPE := 'P1_OTHER_INSTITUTION';
    g_wait_time_avg_dd         CONSTANT sys_config.id_sys_config%TYPE := 'WAIT_TIME_AVG_DD';
    g_prof_patient_portal      CONSTANT sys_config.id_sys_config%TYPE := 'PROF_PATIENT_PORTAL';
    g_ref_vip_available        CONSTANT sys_config.id_sys_config%TYPE := 'REF_VIP_AVAILABLE';
    g_sc_sns_code_sonho        CONSTANT sys_config.id_sys_config%TYPE := 'P1_SNS_CODE_SONHO';
    g_sc_health_plan_other     CONSTANT sys_config.id_sys_config%TYPE := 'HEALTH_PLAN_OTHER';
    g_ref_issue_print_req_days CONSTANT sys_config.id_sys_config%TYPE := 'REF_ISSUE_PRINTED_REQUEST_DAYS';
    g_ref_reason_not_mandatory CONSTANT sys_config.id_sys_config%TYPE := 'REF_REASON_NOT_MANDATORY';
    g_ref_diag_mandatory       CONSTANT sys_config.id_sys_config%TYPE := 'REF_DIAG_MANDATORY';
    g_ref_internal_restriction CONSTANT sys_config.id_sys_config%TYPE := 'REF_INTERNAL_WF_RESTRICTION';
    g_ref_cancel_req_enabled   CONSTANT sys_config.id_sys_config%TYPE := 'REF_CANCEL_REQ_ENABLE';
    g_ref_registrar_can_cancel CONSTANT sys_config.id_sys_config%TYPE := 'REF_REGISTRAR_CAN_CANCEL';
    g_ref_decline_cd_enabled   CONSTANT sys_config.id_sys_config%TYPE := 'REF_DECLINE_CD_ENABLE';
    g_ref_upd_sts_a_enabled    CONSTANT sys_config.id_sys_config%TYPE := 'REF_UPD_STS_A_ENABLE';
    g_ref_decline_reg_enabled  CONSTANT sys_config.id_sys_config%TYPE := 'REF_DECLINE_REG_ENABLE';
    g_ref_medication_enabled   CONSTANT sys_config.id_sys_config%TYPE := 'REF_MEDICATION_ENABLE';
    g_ref_handoff_inst_enabled CONSTANT sys_config.id_sys_config%TYPE := 'REF_HANDOFF_INST_ENABLE';
    g_ref_inst_p_type_name     CONSTANT sys_config.id_sys_config%TYPE := 'REF_INST_PARENT_TYPE_NAME';
    g_ref_tr_inst_par_type     CONSTANT sys_config.id_sys_config%TYPE := 'REF_TR_INST_PARENT_TYPE';
    g_ref_reproc_intf_events   CONSTANT sys_config.id_sys_config%TYPE := 'REF_REPROCESS_INTF_EVENTS_SUPPORT';
    g_ref_clave_cause_enabled  CONSTANT sys_config.id_sys_config%TYPE := 'REF_CLAVE_CAUSE_ENABLE';
    g_ref_comments_available   CONSTANT sys_config.id_sys_config%TYPE := 'REF_COMMENTS_AVAILABLE';
    g_ref_vitalsigns_enabled   CONSTANT sys_config.id_sys_config%TYPE := 'REF_VITALSIGNS_ENABLE';

    -- sys_message
    g_sm_common_m001 CONSTANT sys_message.code_message%TYPE := 'COMMON_M001';
    g_sm_common_m20  CONSTANT sys_message.code_message%TYPE := 'COMMON_M020';
    g_sm_common_m15  CONSTANT sys_message.code_message%TYPE := 'COMMON_M015';
    g_sm_common_m19  CONSTANT sys_message.code_message%TYPE := 'COMMON_M019';
    g_sm_common_m21  CONSTANT sys_message.code_message%TYPE := 'REF_COMMON_M021';

    g_sm_common_t001 CONSTANT sys_message.code_message%TYPE := 'P1_COMMON_T001';
    g_sm_common_t002 CONSTANT sys_message.code_message%TYPE := 'P1_COMMON_T002';
    g_sm_common_t003 CONSTANT sys_message.code_message%TYPE := 'P1_COMMON_T003';
    g_sm_common_t005 CONSTANT sys_message.code_message%TYPE := 'P1_COMMON_T005';
    g_sm_common_t007 CONSTANT sys_message.code_message%TYPE := 'P1_COMMON_T007';
    g_sm_common_t008 CONSTANT sys_message.code_message%TYPE := 'P1_COMMON_T008';

    g_sm_ref_common_t001 CONSTANT sys_message.code_message%TYPE := 'REF_COMMON_T001';
    g_sm_ref_common_t002 CONSTANT sys_message.code_message%TYPE := 'REF_COMMON_T002';
    g_sm_ref_common_t003 CONSTANT sys_message.code_message%TYPE := 'REF_COMMON_T003';
    g_sm_ref_common_t004 CONSTANT sys_message.code_message%TYPE := 'REF_COMMON_T004';
    g_sm_ref_common_t005 CONSTANT sys_message.code_message%TYPE := 'REF_COMMON_T005';
    g_sm_ref_common_t006 CONSTANT sys_message.code_message%TYPE := 'REF_COMMON_T006';

    g_sm_doctor_req_t018 CONSTANT sys_message.code_message%TYPE := 'P1_DOCTOR_REQ_T018';
    g_sm_doctor_req_t019 CONSTANT sys_message.code_message%TYPE := 'P1_DOCTOR_REQ_T019';
    g_sm_doctor_req_t020 CONSTANT sys_message.code_message%TYPE := 'P1_DOCTOR_REQ_T020';
    g_sm_doctor_req_t021 CONSTANT sys_message.code_message%TYPE := 'P1_DOCTOR_REQ_T021';
    g_sm_doctor_req_t035 CONSTANT sys_message.code_message%TYPE := 'P1_DOCTOR_REQ_T035';
    g_sm_doctor_req_t038 CONSTANT sys_message.code_message%TYPE := 'P1_DOCTOR_REQ_T038';
    g_sm_doctor_req_t039 CONSTANT sys_message.code_message%TYPE := 'P1_DOCTOR_REQ_T039';
    g_sm_doctor_req_t040 CONSTANT sys_message.code_message%TYPE := 'P1_DOCTOR_REQ_T040';
    g_sm_doctor_req_t041 CONSTANT sys_message.code_message%TYPE := 'P1_DOCTOR_REQ_T041';
    g_sm_doctor_req_t042 CONSTANT sys_message.code_message%TYPE := 'P1_DOCTOR_REQ_T042';
    g_sm_doctor_req_t045 CONSTANT sys_message.code_message%TYPE := 'P1_DOCTOR_REQ_T045';
    g_sm_doctor_req_t046 CONSTANT sys_message.code_message%TYPE := 'P1_DOCTOR_REQ_T046';
    g_sm_doctor_req_t050 CONSTANT sys_message.code_message%TYPE := 'P1_DOCTOR_REQ_T050';
    g_sm_doctor_req_t055 CONSTANT sys_message.code_message%TYPE := 'P1_DOCTOR_REQ_T055';
    g_sm_doctor_req_t057 CONSTANT sys_message.code_message%TYPE := 'P1_DOCTOR_REQ_T057';
    g_sm_doctor_req_t058 CONSTANT sys_message.code_message%TYPE := 'P1_DOCTOR_REQ_T058';
    g_sm_doctor_req_t059 CONSTANT sys_message.code_message%TYPE := 'P1_DOCTOR_REQ_T059';
    g_sm_doctor_req_t061 CONSTANT sys_message.code_message%TYPE := 'P1_DOCTOR_REQ_T061';
    g_sm_doctor_req_t080 CONSTANT sys_message.code_message%TYPE := 'P1_DOCTOR_REQ_T080';
    g_sm_doctor_req_t081 CONSTANT sys_message.code_message%TYPE := 'P1_DOCTOR_REQ_T081';
    g_sm_doctor_req_t082 CONSTANT sys_message.code_message%TYPE := 'P1_DOCTOR_REQ_T082';
    g_sm_doctor_req_t083 CONSTANT sys_message.code_message%TYPE := 'P1_DOCTOR_REQ_T083';

    g_sm_doctor_cs_t030 CONSTANT sys_message.code_message%TYPE := 'P1_DOCTOR_CS_T030';
    g_sm_doctor_cs_t080 CONSTANT sys_message.code_message%TYPE := 'P1_DOCTOR_CS_T080';
    g_sm_doctor_cs_t081 CONSTANT sys_message.code_message%TYPE := 'P1_DOCTOR_CS_T081';
    g_sm_doctor_cs_t082 CONSTANT sys_message.code_message%TYPE := 'P1_DOCTOR_CS_T082';
    g_sm_doctor_cs_t073 CONSTANT sys_message.code_message%TYPE := 'P1_DOCTOR_CS_T073';
    g_sm_doctor_cs_t075 CONSTANT sys_message.code_message%TYPE := 'P1_DOCTOR_CS_T075';
    g_sm_doctor_cs_t076 CONSTANT sys_message.code_message%TYPE := 'P1_DOCTOR_CS_T076';
    g_sm_doctor_cs_t077 CONSTANT sys_message.code_message%TYPE := 'P1_DOCTOR_CS_T077';
    g_sm_doctor_cs_t078 CONSTANT sys_message.code_message%TYPE := 'P1_DOCTOR_CS_T078';
    g_sm_doctor_cs_t079 CONSTANT sys_message.code_message%TYPE := 'P1_DOCTOR_CS_T079';
    g_sm_doctor_cs_t117 CONSTANT sys_message.code_message%TYPE := 'P1_DOCTOR_CS_T117';
    g_sm_doctor_cs_t119 CONSTANT sys_message.code_message%TYPE := 'P1_DOCTOR_CS_T119';
    g_sm_doctor_hs_t023 CONSTANT sys_message.code_message%TYPE := 'P1_DOCTOR_HS_T023';
    g_sm_doctor_hs_t024 CONSTANT sys_message.code_message%TYPE := 'P1_DOCTOR_HS_T024';
    g_sm_doctor_hs_t026 CONSTANT sys_message.code_message%TYPE := 'P1_DOCTOR_HS_T026';

    g_sm_ref_detail_auge      CONSTANT sys_message.code_message%TYPE := 'REF_DETAIL_AUGE';
    g_sm_helpsave_w           CONSTANT sys_message.code_message%TYPE := 'HELP_SAVE_T002'; --Aviso  
    g_sm_ref_waitingtime_t012 CONSTANT sys_message.code_message%TYPE := 'REF_WAITINGTIME_T012';
    g_sm_ref_waitingtime_t013 CONSTANT sys_message.code_message%TYPE := 'REF_WAITINGTIME_T013';
    g_sm_ref_waitingtime_t014 CONSTANT sys_message.code_message%TYPE := 'REF_WAITINGTIME_T014';
    g_sm_ref_waitingtime_t015 CONSTANT sys_message.code_message%TYPE := 'REF_WAITINGTIME_T015';
    g_sm_ref_detail_ges       CONSTANT sys_message.code_message%TYPE := 'REF_DETAIL_GES';
    g_sm_ref_detail_no_ges    CONSTANT sys_message.code_message%TYPE := 'REF_DETAIL_NO_GES';

    -- Hand off
    g_sm_ref_transfresp_t002 CONSTANT sys_message.code_message%TYPE := 'REF_TRANSFRESP_T002';
    g_sm_ref_transfresp_t013 CONSTANT sys_message.code_message%TYPE := 'REF_TRANSFRESP_T013';
    g_sm_ref_transfresp_t016 CONSTANT sys_message.code_message%TYPE := 'REF_TRANSFRESP_T016';
    g_sm_ref_transfresp_t017 CONSTANT sys_message.code_message%TYPE := 'REF_TRANSFRESP_T017';
    g_sm_ref_transfresp_t021 CONSTANT sys_message.code_message%TYPE := 'REF_TRANSFRESP_T021';
    g_sm_ref_transfresp_t022 CONSTANT sys_message.code_message%TYPE := 'REF_TRANSFRESP_T022';
    g_sm_ref_transfresp_t023 CONSTANT sys_message.code_message%TYPE := 'REF_TRANSFRESP_T023';
    g_sm_ref_transfresp_t029 CONSTANT sys_message.code_message%TYPE := 'REF_TRANSFRESP_T029';
    g_sm_ref_transfresp_t042 CONSTANT sys_message.code_message%TYPE := 'REF_TRANSFRESP_T042';
    g_sm_ref_transfresp_t051 CONSTANT sys_message.code_message%TYPE := 'REF_TRANSFRESP_T051';
    g_sm_ref_transfresp_t054 CONSTANT sys_message.code_message%TYPE := 'REF_TRANSFRESP_T054';
    g_sm_ref_transfresp_t055 CONSTANT sys_message.code_message%TYPE := 'REF_TRANSFRESP_T055';
    g_sm_ref_transfresp_t058 CONSTANT sys_message.code_message%TYPE := 'REF_TRANSFRESP_T058';
    g_sm_ref_transfresp_t059 CONSTANT sys_message.code_message%TYPE := 'REF_TRANSFRESP_T059';
    g_sm_ref_transfresp_t063 CONSTANT sys_message.code_message%TYPE := 'REF_TRANSFRESP_T063';
    g_sm_ref_transfresp_t068 CONSTANT sys_message.code_message%TYPE := 'REF_TRANSFRESP_T068';
    g_sm_ref_transfresp_t069 CONSTANT sys_message.code_message%TYPE := 'REF_TRANSFRESP_T069';
    g_sm_ref_transfresp_t071 CONSTANT sys_message.code_message%TYPE := 'REF_TRANSFRESP_T071';
    g_sm_ref_transfresp_t072 CONSTANT sys_message.code_message%TYPE := 'REF_TRANSFRESP_T072';
    g_sm_ref_transfresp_t073 CONSTANT sys_message.code_message%TYPE := 'REF_TRANSFRESP_T073';
    g_sm_ref_transfresp_t075 CONSTANT sys_message.code_message%TYPE := 'REF_TRANSFRESP_T075';

    -- detail
    g_sm_p1_detail_t004 CONSTANT sys_message.code_message%TYPE := 'P1_DETAIL_T004';
    g_sm_p1_detail_t006 CONSTANT sys_message.code_message%TYPE := 'P1_DETAIL_T006';
    g_sm_p1_detail_t011 CONSTANT sys_message.code_message%TYPE := 'P1_DETAIL_T011';
    g_sm_p1_detail_t012 CONSTANT sys_message.code_message%TYPE := 'P1_DETAIL_T012';
    g_sm_p1_detail_t013 CONSTANT sys_message.code_message%TYPE := 'P1_DETAIL_T013';
    g_sm_p1_detail_t016 CONSTANT sys_message.code_message%TYPE := 'P1_DETAIL_T016';
    g_sm_p1_detail_t020 CONSTANT sys_message.code_message%TYPE := 'P1_DETAIL_T020';
    g_sm_p1_detail_t021 CONSTANT sys_message.code_message%TYPE := 'P1_DETAIL_T021';
    g_sm_p1_detail_t022 CONSTANT sys_message.code_message%TYPE := 'P1_DETAIL_T022';
    g_sm_p1_detail_t024 CONSTANT sys_message.code_message%TYPE := 'P1_DETAIL_T024';
    g_sm_p1_detail_t025 CONSTANT sys_message.code_message%TYPE := 'P1_DETAIL_T025';
    g_sm_p1_detail_t026 CONSTANT sys_message.code_message%TYPE := 'P1_DETAIL_T026';
    g_sm_p1_detail_t027 CONSTANT sys_message.code_message%TYPE := 'P1_DETAIL_T027';
    g_sm_p1_detail_t028 CONSTANT sys_message.code_message%TYPE := 'P1_DETAIL_T028';
    g_sm_p1_detail_t034 CONSTANT sys_message.code_message%TYPE := 'P1_DETAIL_T034';
    g_sm_p1_detail_t035 CONSTANT sys_message.code_message%TYPE := 'P1_DETAIL_T035';
    g_sm_p1_detail_t037 CONSTANT sys_message.code_message%TYPE := 'P1_DETAIL_T037';
    g_sm_p1_detail_t038 CONSTANT sys_message.code_message%TYPE := 'P1_DETAIL_T038';
    g_sm_p1_detail_t039 CONSTANT sys_message.code_message%TYPE := 'P1_DETAIL_T039';
    g_sm_p1_detail_t045 CONSTANT sys_message.code_message%TYPE := 'P1_DETAIL_T045';
    g_sm_p1_detail_t046 CONSTANT sys_message.code_message%TYPE := 'P1_DETAIL_T046';
    g_sm_p1_detail_t047 CONSTANT sys_message.code_message%TYPE := 'P1_DETAIL_T047';
    g_sm_p1_detail_t048 CONSTANT sys_message.code_message%TYPE := 'P1_DETAIL_T048';
    g_sm_p1_detail_t049 CONSTANT sys_message.code_message%TYPE := 'P1_DETAIL_T049';
    g_sm_p1_detail_t050 CONSTANT sys_message.code_message%TYPE := 'P1_DETAIL_T050';
    g_sm_p1_detail_t051 CONSTANT sys_message.code_message%TYPE := 'P1_DETAIL_T051';
    g_sm_p1_detail_t052 CONSTANT sys_message.code_message%TYPE := 'P1_DETAIL_T052';
    g_sm_p1_detail_t053 CONSTANT sys_message.code_message%TYPE := 'P1_DETAIL_T053';
    g_sm_p1_detail_t054 CONSTANT sys_message.code_message%TYPE := 'P1_DETAIL_T054';
    g_sm_p1_detail_t055 CONSTANT sys_message.code_message%TYPE := 'P1_DETAIL_T055';
    g_sm_p1_detail_t056 CONSTANT sys_message.code_message%TYPE := 'P1_DETAIL_T056';
    g_sm_p1_detail_t057 CONSTANT sys_message.code_message%TYPE := 'P1_DETAIL_T057';
    g_sm_p1_detail_t058 CONSTANT sys_message.code_message%TYPE := 'P1_DETAIL_T058';
    g_sm_p1_detail_t060 CONSTANT sys_message.code_message%TYPE := 'P1_DETAIL_T060';
    g_sm_p1_detail_t061 CONSTANT sys_message.code_message%TYPE := 'P1_DETAIL_T061';
    g_sm_p1_detail_t062 CONSTANT sys_message.code_message%TYPE := 'P1_DETAIL_T062';
    g_sm_p1_detail_t063 CONSTANT sys_message.code_message%TYPE := 'P1_DETAIL_T063';

    g_sm_ref_detail_t016 CONSTANT sys_message.code_message%TYPE := 'REF_DETAIL_T016';
    g_sm_ref_detail_t017 CONSTANT sys_message.code_message%TYPE := 'REF_DETAIL_T017';
    g_sm_ref_detail_t018 CONSTANT sys_message.code_message%TYPE := 'REF_DETAIL_T018';
    g_sm_ref_detail_t019 CONSTANT sys_message.code_message%TYPE := 'REF_DETAIL_T019';
    g_sm_ref_detail_t020 CONSTANT sys_message.code_message%TYPE := 'REF_DETAIL_T020';
    g_sm_ref_detail_t021 CONSTANT sys_message.code_message%TYPE := 'REF_DETAIL_T021';
    g_sm_ref_detail_t025 CONSTANT sys_message.code_message%TYPE := 'REF_DETAIL_T025';
    g_sm_ref_detail_t026 CONSTANT sys_message.code_message%TYPE := 'REF_DETAIL_T026';
    g_sm_ref_detail_t032 CONSTANT sys_message.code_message%TYPE := 'REF_DETAIL_T032';
    g_sm_ref_detail_t041 CONSTANT sys_message.code_message%TYPE := 'REF_DETAIL_T041';
    g_sm_ref_detail_t042 CONSTANT sys_message.code_message%TYPE := 'REF_DETAIL_T042';
    g_sm_ref_detail_t046 CONSTANT sys_message.code_message%TYPE := 'REF_DETAIL_T046';
    g_sm_ref_detail_t047 CONSTANT sys_message.code_message%TYPE := 'REF_DETAIL_T047';
    g_sm_ref_detail_t048 CONSTANT sys_message.code_message%TYPE := 'REF_DETAIL_T048';
    g_sm_ref_detail_t049 CONSTANT sys_message.code_message%TYPE := 'REF_DETAIL_T049';
    g_sm_ref_detail_t062 CONSTANT sys_message.code_message%TYPE := 'REF_DETAIL_T062';
    g_sm_ref_detail_t063 CONSTANT sys_message.code_message%TYPE := 'REF_DETAIL_T063';
    g_sm_ref_detail_t064 CONSTANT sys_message.code_message%TYPE := 'REF_DETAIL_T064';
    g_sm_ref_detail_t065 CONSTANT sys_message.code_message%TYPE := 'REF_DETAIL_T065';
    g_sm_ref_detail_t066 CONSTANT sys_message.code_message%TYPE := 'REF_DETAIL_T066';
    g_sm_ref_detail_t067 CONSTANT sys_message.code_message%TYPE := 'REF_DETAIL_T067';
    g_sm_ref_detail_t068 CONSTANT sys_message.code_message%TYPE := 'REF_DETAIL_T068';
    g_sm_ref_detail_t069 CONSTANT sys_message.code_message%TYPE := 'REF_DETAIL_T069';
    g_sm_ref_detail_t071 CONSTANT sys_message.code_message%TYPE := 'REF_DETAIL_T071';
    g_sm_ref_detail_t076 CONSTANT sys_message.code_message%TYPE := 'REF_DETAIL_T076';
    g_sm_ref_detail_t081 CONSTANT sys_message.code_message%TYPE := 'REF_DETAIL_T081'; -- patient missed
    g_sm_ref_detail_t082 CONSTANT sys_message.code_message%TYPE := 'REF_DETAIL_T082';
    g_sm_ref_detail_t083 CONSTANT sys_message.code_message%TYPE := 'REF_DETAIL_T083';
    g_sm_ref_detail_t087 CONSTANT sys_message.code_message%TYPE := 'REF_DETAIL_T087';

    g_sm_ref_detail_t088 CONSTANT sys_message.code_message%TYPE := 'REF_RESP_PAT_T01';
    g_sm_ref_detail_t089 CONSTANT sys_message.code_message%TYPE := 'ID_PATIENT_RELATIONSHIP';
    g_sm_ref_detail_t090 CONSTANT sys_message.code_message%TYPE := 'REF_RESP_PAT_T02';

    g_sm_p1_info_t001        CONSTANT sys_message.code_message%TYPE := 'P1_INFO_T001';
    g_sm_ref_detail_ubrn     CONSTANT sys_message.code_message%TYPE := 'REF_DETAIL_UBRN';
    g_sm_ref_detail_req_item CONSTANT sys_message.code_message%TYPE := 'REF_DEATIL_REQ_ITEM';

    g_sm_ref_h_entrance           CONSTANT sys_message.code_message%TYPE := 'REF_HOSPITAL_ENTRANCE';
    g_sm_ref_h_entrance_orig_inst CONSTANT sys_message.code_message%TYPE := 'REF_HOSPITAL_ENTRANCE_ORIG_INST';

    g_sm_ref_reg_hs_t001   CONSTANT sys_message.code_message%TYPE := 'REF_REG_HS_T001';
    g_sm_p1_doctor_cs_t040 CONSTANT sys_message.code_message%TYPE := 'P1_DOCTOR_CS_T040';

    g_sm_p1_answer_t001 CONSTANT sys_message.code_message%TYPE := 'P1_ANSWER_T001';
    g_sm_p1_answer_t003 CONSTANT sys_message.code_message%TYPE := 'P1_ANSWER_T003';
    g_sm_p1_answer_t004 CONSTANT sys_message.code_message%TYPE := 'P1_ANSWER_T004';
    g_sm_p1_answer_t005 CONSTANT sys_message.code_message%TYPE := 'P1_ANSWER_T005';
    g_sm_p1_answer_t006 CONSTANT sys_message.code_message%TYPE := 'P1_ANSWER_T006';
    g_sm_p1_answer_t007 CONSTANT sys_message.code_message%TYPE := 'P1_ANSWER_T007';
    g_sm_p1_answer_t008 CONSTANT sys_message.code_message%TYPE := 'P1_ANSWER_T008';
    g_sm_p1_answer_t009 CONSTANT sys_message.code_message%TYPE := 'P1_ANSWER_T009';
    g_sm_p1_answer_t010 CONSTANT sys_message.code_message%TYPE := 'P1_ANSWER_T010';
    g_sm_p1_answer_t011 CONSTANT sys_message.code_message%TYPE := 'P1_ANSWER_T011';
    g_sm_p1_answer_t012 CONSTANT sys_message.code_message%TYPE := 'P1_ANSWER_T012';

    g_sm_ref_grid_t009 CONSTANT sys_message.code_message%TYPE := 'REF_GRID_T009';
    g_sm_ref_grid_t012 CONSTANT sys_message.code_message%TYPE := 'REF_GRID_T012'; -- Status
    g_sm_ref_grid_t010 CONSTANT sys_message.code_message%TYPE := 'REF_GRID_T010';

    g_sm_ref_grid_t024 CONSTANT sys_message.code_message%TYPE := 'REF_GRID_T024';
    g_sm_ref_grid_t025 CONSTANT sys_message.code_message%TYPE := 'REF_GRID_T025';
    g_sm_ref_grid_t031 CONSTANT sys_message.code_message%TYPE := 'REF_GRID_T031'; -- Other (institution list)   
    g_sm_ref_grid_t032 CONSTANT sys_message.code_message%TYPE := 'REF_GRID_T032'; -- External institution (institution list)

    g_sm_adm_p1_t022 CONSTANT sys_message.code_message%TYPE := 'ADMINISTRATOR_P1_T022';

    g_sm_p1_import_notes CONSTANT sys_message.code_message%TYPE := 'P1_IMPORT_NOTES';

    g_ref_mark_req_t010 CONSTANT sys_message.code_message%TYPE := 'REF_MARK_REQ_T010';
    g_ref_mark_req_t011 CONSTANT sys_message.code_message%TYPE := 'REF_MARK_REQ_T011';
    g_ref_mark_req_t020 CONSTANT sys_message.code_message%TYPE := 'REF_MARK_REQ_T020';
    g_ref_mark_req_t028 CONSTANT sys_message.code_message%TYPE := 'REF_MARK_REQ_T028';
    g_ref_mark_req_t029 CONSTANT sys_message.code_message%TYPE := 'REF_MARK_REQ_T029';
    g_ref_mark_req_t030 CONSTANT sys_message.code_message%TYPE := 'REF_MARK_REQ_T030';
    g_ref_mark_req_t018 CONSTANT sys_message.code_message%TYPE := 'REF_MARK_REQ_T018';
    g_ref_mark_req_t017 CONSTANT sys_message.code_message%TYPE := 'REF_MARK_REQ_T017';
    g_ref_mark_req_t016 CONSTANT sys_message.code_message%TYPE := 'REF_MARK_REQ_T016';
    g_ref_mark_req_t027 CONSTANT sys_message.code_message%TYPE := 'REF_MARK_REQ_T027';

    -- Problems
    g_sm_problem_list_t003 CONSTANT sys_message.code_message%TYPE := 'PROBLEM_LIST_T003'; -- Status
    g_sm_problem_list_t004 CONSTANT sys_message.code_message%TYPE := 'PROBLEM_LIST_T004'; -- Chronicity
    g_sm_problem_list_t009 CONSTANT sys_message.code_message%TYPE := 'PROBLEM_LIST_T009'; -- Notes
    g_sm_problem_list_t031 CONSTANT sys_message.code_message%TYPE := 'PROBLEM_LIST_T031'; -- Precautions
    g_sm_problem_list_t033 CONSTANT sys_message.code_message%TYPE := 'PROBLEM_LIST_T033'; -- Resolution date
    g_sm_problem_list_t037 CONSTANT sys_message.code_message%TYPE := 'PROBLEM_LIST_T037'; -- Header warning
    g_sm_problem_list_t084 CONSTANT sys_message.code_message%TYPE := 'PROBLEM_LIST_T084'; -- Start date

    -- Diagnosis
    g_sm_diagnosis_final_t018 CONSTANT sys_message.code_message%TYPE := 'DIAGNOSIS_FINAL_T018'; -- Specific notes
    g_sm_diagnosis_final_t019 CONSTANT sys_message.code_message%TYPE := 'DIAGNOSIS_FINAL_T019'; -- General notes

    g_sm_ref_devstatus_notes  CONSTANT sys_message.code_message%TYPE := 'REF_DEVSTATUS_NOTES';
    g_sm_ref_devstatus_reason CONSTANT sys_message.code_message%TYPE := 'REF_DEVSTATUS_REASON';
    g_sm_ref_consent          CONSTANT sys_message.code_message%TYPE := 'P1_DOCTOR_REQ_T092';

    -- GP PORTAL
    g_sm_refgp_reqdest CONSTANT sys_message.code_message%TYPE := 'REFGPP_VISITFORM_T006';
    g_sm_refgp_schper  CONSTANT sys_message.code_message%TYPE := 'REFGPP_VISITFORM_T007';

    -- messagem de mcdts repetidos (Prescrição electronica de mcdts)
    g_ref_analysis_presc_m001 CONSTANT sys_message.code_message%TYPE := 'REF_ANALYSIS_PRESC_M001';
    g_ref_exam_presc_m001     CONSTANT sys_message.code_message%TYPE := 'REF_EXAM_PRESC_M001';
    g_ref_interv_presc_m001   CONSTANT sys_message.code_message%TYPE := 'REF_INTERV_PRESC_M001';
    g_ref_mcdt_presc_m001     CONSTANT sys_message.code_message%TYPE := 'REF_MCDT_PRESC_M001';
    g_ref_mcdt_presc_m002     CONSTANT sys_message.code_message%TYPE := 'REF_MCDT_PRESC_M002';

    -- p1_workflow_config
    g_adm_forward_dcs   CONSTANT p1_workflow_config.code_workflow_config%TYPE := 'ADM_FORWARD_DCS';
    g_adm_required      CONSTANT p1_workflow_config.code_workflow_config%TYPE := 'ADM_REQUIRED';
    g_inst_forward_type CONSTANT p1_workflow_config.code_workflow_config%TYPE := 'INST_FORWARD_TYPE';

    -- ADM_REQUIRED match value
    g_adm_required_match CONSTANT p1_workflow_config.value%TYPE := 'M';

    -- error constants
    g_err_flg_action_u CONSTANT VARCHAR2(1 CHAR) := 'U'; -- U=USER SPECIFIED ERROR
    g_err_flg_action_d CONSTANT VARCHAR2(1 CHAR) := 'D'; -- D=DEFAULT USER ERROR
    g_err_flg_action_s CONSTANT VARCHAR2(1 CHAR) := 'S'; -- S=ERROR SYSTEM        

    -- referral answer
    g_ref_answer_o       CONSTANT VARCHAR2(12 CHAR) := 'OBSERVATION';
    g_ref_answer_t       CONSTANT VARCHAR2(12 CHAR) := 'THERAPY';
    g_ref_answer_e       CONSTANT VARCHAR2(12 CHAR) := 'EXAM';
    g_ref_answer_c       CONSTANT VARCHAR2(12 CHAR) := 'CONCLUSION';
    g_ref_answer_ev      CONSTANT VARCHAR2(12 CHAR) := 'EVOLUTION'; --MX
    g_ref_answer_dt_cb   CONSTANT VARCHAR2(12 CHAR) := 'DTCOMEBACK'; --MX
    g_ref_answer_diag    CONSTANT VARCHAR2(12 CHAR) := 'DIAGNOSIS';
    g_exr_answer_hp      CONSTANT VARCHAR2(12 CHAR) := 'HEALTH_PROB'; -- Health problem (Answer) --MX
    g_exr_answer_diag_in CONSTANT VARCHAR2(12 CHAR) := 'DIAGNOSIS_IN'; -- Diagnosis --MX

    -----------------
    -- PIO constants

    -- Referral PIO status
    g_ref_pio_status_w CONSTANT ref_pio.flg_status_pio%TYPE := 'W'; -- (W)aiting for approval
    g_ref_pio_status_r CONSTANT ref_pio.flg_status_pio%TYPE := 'R'; -- (R)ead
    g_ref_pio_status_p CONSTANT ref_pio.flg_status_pio%TYPE := 'P'; -- (P)rocessing
    g_ref_pio_status_u CONSTANT ref_pio.flg_status_pio%TYPE := 'U'; -- (U)ntransferable
    g_ref_pio_status_s CONSTANT ref_pio.flg_status_pio%TYPE := 'S'; -- (S)tand by

    -- SIGLIC action
    g_ref_pio_action_n CONSTANT ref_pio_tracking.action%TYPE := 'N'; -- (N)o action
    g_ref_pio_action_c CONSTANT ref_pio_tracking.action%TYPE := 'C'; -- (C)ancel referral
    g_ref_pio_action_t CONSTANT ref_pio_tracking.action%TYPE := 'T'; -- (T)ransfer referral
    g_ref_pio_action_u CONSTANT ref_pio_tracking.action%TYPE := 'U'; -- (U)ntransferable

    -- SYS_CONFIG codes
    g_sc_pio_pat_transf      CONSTANT sys_config.id_sys_config%TYPE := 'REF_PIO_PAT_TRANSF';
    g_sc_pio_pat_refuse      CONSTANT sys_config.id_sys_config%TYPE := 'REF_PIO_PAT_REFUSE';
    g_sc_pio_ref_status      CONSTANT sys_config.id_sys_config%TYPE := 'REF_PIO_REF_STATUS';
    g_sc_pio_max_days        CONSTANT sys_config.id_sys_config%TYPE := 'REF_PIO_MAX_DAYS';
    g_sc_pio_specialities    CONSTANT sys_config.id_sys_config%TYPE := 'REF_PIO_SPECIALITIES';
    g_sc_intf_prof_id        CONSTANT sys_config.id_sys_config%TYPE := 'P1_INTERFACE_PROF_ID';
    g_sc_software_p1         CONSTANT sys_config.id_sys_config%TYPE := 'SOFTWARE_ID_P1';
    g_sc_auto_login_url      CONSTANT sys_config.id_sys_config%TYPE := 'P1_AUTO_LOGIN_URL';
    g_sc_sns_doc_type        CONSTANT sys_config.id_sys_config%TYPE := 'NATIONAL_HEALTH_NUMBER_DOC_TYPE_ID';
    g_sc_bi_doc_type         CONSTANT sys_config.id_sys_config%TYPE := 'DOC_TYPE_ID';
    g_ref_first_appoint_spec CONSTANT sys_config.id_sys_config%TYPE := 'REF_FIRST_APPOINT_SPEC';
    g_sc_cpf_doc_type        CONSTANT sys_config.id_sys_config%TYPE := 'ADT_CPF_DOC_TYPE_IDENTIFIER';

    -- SYS_MESSAGE codes
    g_sm_pio_notes   CONSTANT sys_message.code_message%TYPE := 'REF_PIO_NOTES';
    g_sm_block_notes CONSTANT sys_message.code_message%TYPE := 'REF_PIO_BLOCK_NOTES';

    -- Referral error codes
    g_ref_error_1000 CONSTANT ref_error.id_ref_error%TYPE := 1000;
    g_ref_error_1001 CONSTANT ref_error.id_ref_error%TYPE := 1001;
    g_ref_error_1002 CONSTANT ref_error.id_ref_error%TYPE := 1002;
    g_ref_error_1003 CONSTANT ref_error.id_ref_error%TYPE := 1003;
    g_ref_error_1004 CONSTANT ref_error.id_ref_error%TYPE := 1004;
    g_ref_error_1005 CONSTANT ref_error.id_ref_error%TYPE := 1005; -- invalid parameter
    g_ref_error_1006 CONSTANT ref_error.id_ref_error%TYPE := 1006; -- referral cannot be updated
    g_ref_error_1007 CONSTANT ref_error.id_ref_error%TYPE := 1007; -- invalid referral
    g_ref_error_1008 CONSTANT ref_error.id_ref_error%TYPE := 1008;
    g_ref_error_1009 CONSTANT ref_error.id_ref_error%TYPE := 1009;
    g_ref_error_1010 CONSTANT ref_error.id_ref_error%TYPE := 1010; -- patient mandatory data incomplete
    g_ref_error_1011 CONSTANT ref_error.id_ref_error%TYPE := 1011; -- invalid operation date

    -- institutions availability for referring
    g_flg_availability_i CONSTANT p1_spec_dep_clin_serv.flg_availability%TYPE := 'I';
    g_flg_availability_a CONSTANT p1_spec_dep_clin_serv.flg_availability%TYPE := 'A';
    g_flg_availability_e CONSTANT p1_spec_dep_clin_serv.flg_availability%TYPE := 'E';
    g_flg_availability_p CONSTANT p1_spec_dep_clin_serv.flg_availability%TYPE := 'P';

    -- Diagnosis types and subtypes
    g_icpc_subtype_s CONSTANT diagnosis.flg_subtype%TYPE := 'S'; -- S - Sinais/Sintomas
    g_icpc_subtype_i CONSTANT diagnosis.flg_subtype%TYPE := 'I'; -- I - Infeccoes
    g_icpc_subtype_n CONSTANT diagnosis.flg_subtype%TYPE := 'N'; -- N - Neoplasias
    g_icpc_subtype_t CONSTANT diagnosis.flg_subtype%TYPE := 'T'; -- T - Traumatismos
    g_icpc_subtype_a CONSTANT diagnosis.flg_subtype%TYPE := 'A'; -- A - Anomalias Congenitas
    g_icpc_subtype_o CONSTANT diagnosis.flg_subtype%TYPE := 'O'; -- O - Outros diagnosticos

    g_diag_type_icpc  CONSTANT diagnosis.flg_type%TYPE := 'P'; --ICPC2
    g_diag_type_icdcm CONSTANT diagnosis.flg_type%TYPE := 'C'; --ICD9CM

    -- Triggers events
    g_insert_event CONSTANT PLS_INTEGER := 1;
    g_update_event CONSTANT PLS_INTEGER := 2;
    g_delete_event CONSTANT PLS_INTEGER := 3;

    -- referral update event flg status
    g_ref_event_u CONSTANT VARCHAR(1 CHAR) := 'U';
    g_ref_event_c CONSTANT VARCHAR(1 CHAR) := 'C';

    -- referral icon
    -- colors
    g_icon_color_red  CONSTANT wf_status.color%TYPE := '0xC86464:0xEBEBC8:0xC86464:0xEBEBC8';
    g_icon_color_red2 CONSTANT wf_status.color%TYPE := ':0xC86464:0x919178:0xC86464';
    g_icon_color_def  CONSTANT wf_status.color%TYPE := ':0x919178::0xEBEBC8';
    -- backgound/foreground colors
    g_fg_color_white         CONSTANT wf_status.color%TYPE := '0xFFFFFF';
    g_bg_color_contessa      CONSTANT wf_status.color%TYPE := '0xC86464';
    g_fg_color_granite_green CONSTANT wf_status.color%TYPE := '0x919178';
    g_fg_color_yellow        CONSTANT wf_status.color%TYPE := '0x919178';

    -- images
    g_icon_sch_very_pri    CONSTANT wf_status.icon%TYPE := 'ScheduledVeryPriorityIcon';
    g_icon_sch_very_pri_b  CONSTANT wf_status.icon%TYPE := 'ScheduledVeryPriorityBeigeIcon';
    g_icon_sch_very_pri_w  CONSTANT wf_status.icon%TYPE := 'ScheduledVeryPriorityWhiteIcon';
    g_icon_sch_pri         CONSTANT wf_status.icon%TYPE := 'ScheduledPriorityIcon';
    g_icon_sch_pri_b       CONSTANT wf_status.icon%TYPE := 'ScheduledPriorityBeigeIcon';
    g_icon_sch_pri_w       CONSTANT wf_status.icon%TYPE := 'ScheduledPriorityWhiteIcon';
    g_icon_sch_new         CONSTANT wf_status.icon%TYPE := 'ScheduledNewDarkIcon';
    g_icon_sch_new_b       CONSTANT wf_status.icon%TYPE := 'ScheduledNewBeigeIcon';
    g_icon_sch_new_w       CONSTANT wf_status.icon%TYPE := 'ScheduledNewWhiteIcon';
    g_icon_triage_sent     CONSTANT wf_status.icon%TYPE := 'TriageSentIcon';
    g_icon_triage_received CONSTANT wf_status.icon%TYPE := 'TriageRecievedIcon';
    g_icon_sent            CONSTANT wf_status.icon%TYPE := 'SentIcon';
    g_icon_received        CONSTANT wf_status.icon%TYPE := 'ReceivedIcon';

    -- languages
    g_lang_pt CONSTANT language.id_language%TYPE := 1;

    g_max_text_field_size CONSTANT NUMBER := 4000;

    -- patient data
    g_pat_phone_type_main   CONSTANT NUMBER := 11; -- Main contact
    g_pat_phone_type_other  CONSTANT NUMBER := 12; -- other contact
    g_pat_email_type_main   CONSTANT NUMBER := 13; -- Main email
    g_pat_email_type_other  CONSTANT NUMBER := 14; -- other email    
    g_pat_preferred_contact CONSTANT v_contact_phone.id_contact_description%TYPE := 4; -- patient preferred contact

    -- dates
    g_date_greater  CONSTANT VARCHAR2(1 CHAR) := 'G';
    g_date_lower    CONSTANT VARCHAR2(1 CHAR) := 'L';
    g_date_equal    CONSTANT VARCHAR2(1 CHAR) := 'E';
    g_second        CONSTANT VARCHAR2(20 CHAR) := 'SECOND';
    g_minute        CONSTANT VARCHAR2(20 CHAR) := 'MINUTE';
    g_format_tstz   CONSTANT VARCHAR2(100 CHAR) := 'YYYY-MM-DD HH24:MI:SSXFF TZH:TZM';
    g_format_date   CONSTANT VARCHAR2(100 CHAR) := 'DD-MM-YYYY HH24:MI:SSXFF';
    g_format_date_2 CONSTANT VARCHAR2(50 CHAR) := 'YYYYMMDDHH24MISS';
    g_format_date_3 CONSTANT VARCHAR2(50 CHAR) := 'DD-MM-YYYY'; -- to use PK_DATE_UTILS.get_timestamp_insttimezone

    -- referral session constants
    g_provider_referral CONSTANT VARCHAR2(50 CHAR) := 'REFERRAL';
    g_provider_p1       CONSTANT VARCHAR2(50 CHAR) := 'P1';

    -- sys_config
    --MK 1
    g_sc_profile_med_cs CONSTANT sys_config.id_sys_config%TYPE := 'P1_PROFILE_MED_CS';
    g_sc_profile_adm_cs CONSTANT sys_config.id_sys_config%TYPE := 'P1_PROFILE_ADM_CS';
    g_sc_profile_adm_hs CONSTANT sys_config.id_sys_config%TYPE := 'P1_PROFILE_ADM_HS';
    g_sc_profile_med_hs CONSTANT sys_config.id_sys_config%TYPE := 'P1_PROFILE_MED_HS';

    --MK 12
    g_sc_profile_med_cs_cl CONSTANT sys_config.id_sys_config%TYPE := 'REF_PROFILE_MED_CS_CL';
    g_sc_profile_adm_cs_cl CONSTANT sys_config.id_sys_config%TYPE := 'REF_PROFILE_ADM_CS_CL';
    g_sc_profile_adm_hs_cl CONSTANT sys_config.id_sys_config%TYPE := 'REF_PROFILE_ADM_HS_CL';
    g_sc_profile_med_hs_cl CONSTANT sys_config.id_sys_config%TYPE := 'REF_PROFILE_MED_HS_CL';

    g_scheduler3_installed  CONSTANT sys_config.id_sys_config%TYPE := 'SCHEDULER3_INSTALLED';
    g_ref_schedule_type     CONSTANT sys_config.id_sys_config%TYPE := 'P1_SCHEDULE_TYPE';
    g_ref_efectivation_type CONSTANT sys_config.id_sys_config%TYPE := 'P1_EFECTIVATION_TYPE';

    -- criterias to search
    g_crit_clin_record           CONSTANT criteria.id_criteria%TYPE := 3; -- Search by clin record
    g_crit_pat_dt_birth          CONSTANT criteria.id_criteria%TYPE := 4; -- Search by date of birth
    g_crit_pat_dt_birth_format   CONSTANT VARCHAR2(50 CHAR) := 'DD-MM-YYYY'; -- date of birth format to search for        
    g_crit_flg_status            CONSTANT criteria.id_criteria%TYPE := 20; -- Search by referral status
    g_crit_id_ref                CONSTANT criteria.id_criteria%TYPE := 21; -- Search by referral number
    g_crit_pat_gender            CONSTANT criteria.id_criteria%TYPE := 29; -- Search by gender
    g_crit_id_spec               CONSTANT criteria.id_criteria%TYPE := 30; -- Search by referral speciality
    g_crit_dt_requested          CONSTANT criteria.id_criteria%TYPE := 123; -- Search by dt_requested
    g_crit_dt_requested_sup      CONSTANT criteria.id_criteria%TYPE := 124; -- Search by >=dt_requested (varchar) - used by flash
    g_crit_dt_requested_inf      CONSTANT criteria.id_criteria%TYPE := 125; -- Search by <=dt_requested (varchar) - used by flash
    g_crit_pat_sns               CONSTANT criteria.id_criteria%TYPE := 213; -- Search by health plan
    g_crit_pat_name              CONSTANT criteria.id_criteria%TYPE := 214; -- Search by name
    g_crit_id_inst               CONSTANT criteria.id_criteria%TYPE := 215; -- Search by referral origin or dest institution
    g_crit_ref_flg_type          CONSTANT criteria.id_criteria%TYPE := 216; -- Search by referral type
    g_crit_tr_id_status          CONSTANT criteria.id_criteria%TYPE := 217; -- Search by hand off status
    g_crit_tr_id_prof_d          CONSTANT criteria.id_criteria%TYPE := 218; -- Search by hand off dest professional
    g_crit_id_prof_req           CONSTANT criteria.id_criteria%TYPE := 219; -- Search by professional that is responsible for referrals
    g_crit_ref_orig_req          CONSTANT criteria.id_criteria%TYPE := 220; -- Search by professional that requested referrals
    g_crit_id_inst_orig          CONSTANT criteria.id_criteria%TYPE := 221; -- Search by referrals from this origin institution
    g_crit_id_inst_orig_dest     CONSTANT criteria.id_criteria%TYPE := 222; -- Search by referrals from this origin institution or this dest institution
    g_crit_id_inst_group         CONSTANT criteria.id_criteria%TYPE := 223; -- Origin or dest institution within the same institution group
    g_crit_id_inst_dest          CONSTANT criteria.id_criteria%TYPE := 224; -- Dest institution
    g_crit_dt_requested_tstz_sup CONSTANT criteria.id_criteria%TYPE := 225; -- Search by >=dt_requested (tstz) - used by interfaces
    g_crit_dt_requested_tstz_inf CONSTANT criteria.id_criteria%TYPE := 226; -- Search by <=dt_requested (tstz) - used by interfaces
    g_crit_pat_name_w            CONSTANT criteria.id_criteria%TYPE := 236; -- Search by name for flg_type W 

    -- Codigos 
    g_institution_code        CONSTANT institution.code_institution%TYPE := 'AB_INSTITUTION.CODE_INSTITUTION.';
    g_p1_speciality_code      CONSTANT p1_speciality.code_speciality%TYPE := 'P1_SPECIALITY.CODE_SPECIALITY.';
    g_health_plan_entity_code CONSTANT sys_domain.code_domain%TYPE := 'HEALTH_PLAN_ENTITY.CODE_HEALTH_PLAN_ENTITY.';
    g_codification_code       CONSTANT sys_domain.code_domain%TYPE := 'CODIFICATION.CODE_CODIFICATION.';
    g_department_code         CONSTANT sys_domain.code_domain%TYPE := 'DEPARTMENT.CODE_DEPARTMENT.';
    g_clinical_service_code   CONSTANT sys_domain.code_domain%TYPE := 'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.';
    g_domain_gender           CONSTANT sys_domain.code_domain%TYPE := 'PATIENT.GENDER';
    g_domain_yes_no           CONSTANT sys_domain.code_domain%TYPE := 'YES_NO';
    g_domain_inst_flg_type    CONSTANT sys_domain.code_domain%TYPE := 'AB_INSTITUTION.FLG_TYPE';
    g_p1_task_code            CONSTANT sys_domain.code_domain%TYPE := 'P1_TASK.CODE_TASK.';
    g_p1_reason_code          CONSTANT sys_domain.code_domain%TYPE := 'P1_REASON_CODE.CODE_REASON.';
    g_pat_soc_attr_br_code    CONSTANT sys_domain.code_domain%TYPE := 'PAT_SOC_ATTRIBUTES_BR.RACE';
    g_district_code           CONSTANT district.code_district%TYPE := 'DISTRICT.CODE_DISTRICT.';
    g_geo_state_code          CONSTANT geo_state.code_geo_state%TYPE := 'GEO_STATE.CODE_GEO_STATE.';
    g_workflow_action_code    CONSTANT wf_workflow_action.code_action%TYPE := 'WF_WORKFLOW_ACTION.CODE_ACTION.';
    g_workflow_status_code    CONSTANT wf_workflow_action.code_action%TYPE := 'WF_STATUS.CODE_STATUS.';
    g_ref_comments_code       CONSTANT sys_domain.code_domain%TYPE := 'REF_COMMENTS.CODE_REF_COMMENTS.';

    --Sys_domain
    g_p1_exr_flg_type         CONSTANT sys_domain.code_domain%TYPE := 'P1_EXTERNAL_REQUEST.FLG_TYPE';
    g_ref_prio                CONSTANT sys_domain.code_domain%TYPE := 'P1_EXTERNAL_REQUEST.FLG_PRIORITY';
    g_ref_home                CONSTANT sys_domain.code_domain%TYPE := 'P1_EXTERNAL_REQUEST.FLG_HOME';
    g_ref_prio_level_1        CONSTANT sys_domain.code_domain%TYPE := 'P1_EXTERNAL_REQUEST.FLG_PRIORITY.LEVEL_1';
    g_ref_prio_level_2        CONSTANT sys_domain.code_domain%TYPE := 'P1_EXTERNAL_REQUEST.FLG_PRIORITY.LEVEL_2';
    g_ref_prio_level_color_1  CONSTANT sys_domain.code_domain%TYPE := 'P1_EXTERNAL_REQUEST.FLG_PRIORITY.LEVEL_COLOR_1';
    g_ref_prio_level_color_2  CONSTANT sys_domain.code_domain%TYPE := 'P1_EXTERNAL_REQUEST.FLG_PRIORITY.LEVEL_COLOR_2';
    g_ref_decision_urg_level  CONSTANT sys_domain.code_domain%TYPE := 'P1_EXTERNAL_REQUEST.DECISION_URG_LEVEL.';
    g_ref_decision_urg_level3 CONSTANT sys_domain.code_domain%TYPE := 'P1_EXTERNAL_REQUEST.DECISION_URG_LEVEL.3';
    g_ref_decision_urg_level2 CONSTANT sys_domain.code_domain%TYPE := 'P1_EXTERNAL_REQUEST.DECISION_URG_LEVEL.2';
    g_ref_decision_urg_level1 CONSTANT sys_domain.code_domain%TYPE := 'P1_EXTERNAL_REQUEST.DECISION_URG_LEVEL.1';

    g_ref_detail_flg_type   CONSTANT sys_domain.code_domain%TYPE := 'P1_DETAIL.FLG_TYPE';
    g_interv_flg_laterality CONSTANT sys_domain.code_domain%TYPE := 'INTERV_PRESC_DET.FLG_LATERALITY';
    g_exam_flg_laterality   CONSTANT sys_domain.code_domain%TYPE := 'EXAM_REQ_DET.FLG_LATERALITY';

    g_p1_exr_flg_status     CONSTANT sys_domain.code_domain%TYPE := 'P1_EXTERNAL_REQUEST.FLG_STATUS';
    g_p1_exr_flg_home       CONSTANT sys_domain.code_domain%TYPE := 'P1_EXTERNAL_REQUEST.FLG_HOME';
    g_adm_hs_status_options CONSTANT sys_domain.code_domain%TYPE := 'P1_STATUS_OPTIONS.ADM_HS';
    g_p1_detail_type        CONSTANT sys_domain.code_domain%TYPE := 'P1_DETAIL.FLG_TYPE';
    g_ref_flg_ref_line      CONSTANT sys_domain.code_domain%TYPE := 'P1_DEST_INSTITUTION.FLG_REF_LINE';
    g_ref_flg_type_ins      CONSTANT sys_domain.code_domain%TYPE := 'P1_DEST_INSTITUTION.FLG_TYPE_INS';
    g_ref_inside_ref_area   CONSTANT sys_domain.code_domain%TYPE := 'REF_DEST_INSTITUTION_SPEC.FLG_INSIDE_REF_AREA';

    g_decision_urg_level   CONSTANT sys_domain.code_domain%TYPE := 'P1_EXTERNAL_REQUEST.DECISION_URG_LEVEL.';
    g_decision_urg_level_1 CONSTANT sys_domain.val%TYPE := '1';
    g_decision_urg_level_2 CONSTANT sys_domain.val%TYPE := '2';
    g_decision_urg_level_3 CONSTANT sys_domain.val%TYPE := '3';

    -- MARKET
    g_market_pt CONSTANT market.id_market%TYPE := 1;
    g_market_br CONSTANT market.id_market%TYPE := 3;
    g_market_fr CONSTANT market.id_market%TYPE := 9;
    g_market_cl CONSTANT market.id_market%TYPE := 12;
    g_market_mx CONSTANT market.id_market%TYPE := 16;
    g_market_ch CONSTANT market.id_market%TYPE := 17;

    -- EXT_SYS
    g_ext_sys_pas CONSTANT external_sys.id_external_sys%TYPE := '11';

    -- ALERT-75907
    g_accept CONSTANT VARCHAR2(1 CHAR) := 'A';
    g_reject CONSTANT VARCHAR2(1 CHAR) := 'R';

    -- PROFESSIONAL RELATIONS
    g_ref_prof_rel CONSTANT VARCHAR2(1 CHAR) := 'R'; -- CREATE REFERRAL

    -- OUT_PUT MESSAGE
    g_c_green_check_icon CONSTANT VARCHAR2(4000) := 'C829664CheckIcon';

    g_dcs_available_d     CONSTANT prof_dep_clin_serv.flg_status%TYPE := 'D';
    g_sch_event_1         CONSTANT schedule.id_schedule_ref%TYPE := 1; -- First Medical Consultation
    g_sched_status_a      CONSTANT schedule.flg_status%TYPE := 'A'; -- (A)ctive - scheduled
    g_sched_status_c      CONSTANT schedule.flg_status%TYPE := 'C'; -- (C)ancelled - scheduled
    g_sched_urg_n         CONSTANT schedule.flg_urgency%TYPE := 'N'; -- (N)ormal
    g_consult_type_first  CONSTANT schedule_outp.flg_type%TYPE := 'P'; -- Tipo de consula, P - primeira consulta
    g_sched_outp_sched_p  CONSTANT schedule_outp.flg_sched%TYPE := 'P'; -- (P)rimeira de especialidade
    g_sched_outp_status_a CONSTANT schedule_outp.flg_state%TYPE := 'A'; -- (A)gendado   

    -- p1_grid_config
    g_gc_filter_schpat_circle   p1_grid_config.filter%TYPE := 'TO_SCHEDULE_PAT_CIRCLE';
    g_gc_filter_schpat_gpportal p1_grid_config.filter%TYPE := 'TO_SCHEDULE_PAT_GPPORTAL';
    g_gc_filter_schpat_generic  p1_grid_config.filter%TYPE := 'TO_SCHEDULE_PAT';

    -- types to be used in mapping actions (internal name / id)
    TYPE t_ibt_action_name IS TABLE OF wf_workflow_action.internal_name%TYPE INDEX BY PLS_INTEGER;
    TYPE t_ibt_action_id IS TABLE OF wf_workflow_action.id_workflow_action%TYPE INDEX BY wf_workflow_action.internal_name%TYPE;

    g_tab_action_name t_ibt_action_name;
    g_tab_action_id   t_ibt_action_id;

    g_detail_flg_i CONSTANT VARCHAR2(1 CHAR) := 'I'; -- insert
    g_detail_flg_u CONSTANT VARCHAR2(1 CHAR) := 'U'; -- update
    g_detail_flg_c CONSTANT VARCHAR2(1 CHAR) := 'C'; -- cancel
    g_detail_flg_o CONSTANT VARCHAR2(1 CHAR) := 'O'; -- outdated
    g_detail_flg_d CONSTANT VARCHAR2(1 CHAR) := 'D'; -- delete   

    g_location_detail CONSTANT VARCHAR2(1 CHAR) := 'D'; -- detail
    g_location_grid   CONSTANT VARCHAR2(1 CHAR) := 'G'; -- grid

    g_button_read         CONSTANT VARCHAR2(1 CHAR) := 'R';
    g_selected            CONSTANT VARCHAR2(1 CHAR) := 'S';
    g_sched_outp_status_e CONSTANT schedule_outp.flg_state%TYPE := 'E'; -- (E)fectivado

    g_inst_forward_type_c CONSTANT VARCHAR2(1 CHAR) := 'C';
    g_inst_forward_type_i CONSTANT VARCHAR2(1 CHAR) := 'I';

    --data_export
    g_doc_area_complaint   CONSTANT doc_area.id_doc_area%TYPE := 20; --Complaint
    g_doc_area_hist_ill    CONSTANT doc_area.id_doc_area%TYPE := 21; --History present illness
    g_doc_area_rev_sys     CONSTANT doc_area.id_doc_area%TYPE := 22; --Review of system
    g_doc_area_phy_exam    CONSTANT doc_area.id_doc_area%TYPE := 28; --physical exam   
    g_doc_area_phy_assess  CONSTANT doc_area.id_doc_area%TYPE := 1045; --physical assessment
    g_doc_area_past_med    CONSTANT doc_area.id_doc_area%TYPE := 45; -- Past medical
    g_doc_area_past_surg   CONSTANT doc_area.id_doc_area%TYPE := 46; -- Past surgical
    g_doc_area_past_fam    CONSTANT doc_area.id_doc_area%TYPE := 47; -- Past family
    g_doc_area_past_soc    CONSTANT doc_area.id_doc_area%TYPE := 48; -- Past social
    g_doc_area_relev_notes CONSTANT doc_area.id_doc_area%TYPE := 49; -- Relevant notes
    g_doc_area_cong_anom   CONSTANT doc_area.id_doc_area%TYPE := 52; -- Congenital anomalies
    g_doc_area_food_hist   CONSTANT doc_area.id_doc_area%TYPE := 53; -- Food History
    g_doc_area_gyn_hist    CONSTANT doc_area.id_doc_area%TYPE := 54; -- Gynecology History
    g_doc_area_child_hist  CONSTANT doc_area.id_doc_area%TYPE := 55; -- Child History
    g_doc_area_obs_hist    CONSTANT doc_area.id_doc_area%TYPE := 1049; -- Obstetric History
    g_doc_area_natal_hist  CONSTANT doc_area.id_doc_area%TYPE := 57; -- Peri-natal and natal History
    g_doc_area_perm_incap  CONSTANT doc_area.id_doc_area%TYPE := 58; -- Permanent incapacities

    g_data_export_type_f CONSTANT p1_data_export_config.flg_type%TYPE := 'F'; -- Mostra resultados da função
    g_data_export_type_s CONSTANT p1_data_export_config.flg_type%TYPE := 'S';

    g_data_export_p1_type_req_pref CONSTANT VARCHAR2(1 CHAR) := 'R'; -- Prefixo do flg_type das requisições

    g_data_export_p1_type_p CONSTANT p1_data_export_config.flg_p1_data_type%TYPE := 'P'; -- Problema
    g_data_export_p1_type_d CONSTANT p1_data_export_config.flg_p1_data_type%TYPE := 'D'; -- Diagnóstico

    g_data_export_p1_type_ra CONSTANT p1_data_export_config.flg_p1_data_type%TYPE := 'RA'; -- Requisições de análises
    g_data_export_p1_type_ri CONSTANT p1_data_export_config.flg_p1_data_type%TYPE := 'RI'; -- Requisições de imagem
    g_data_export_p1_type_re CONSTANT p1_data_export_config.flg_p1_data_type%TYPE := 'RE'; -- Requisições de outros exames
    g_data_export_p1_type_rp CONSTANT p1_data_export_config.flg_p1_data_type%TYPE := 'RP'; -- Requisições de procedimentos
    g_data_export_p1_type_rf CONSTANT p1_data_export_config.flg_p1_data_type%TYPE := 'RF'; -- Requisições de MFR

    g_transition_allow CONSTANT wf_transition_config.flg_permission%TYPE := 'A'; -- (A)llow
    g_transition_deny  CONSTANT wf_transition_config.flg_permission%TYPE := 'D'; -- (D)eny

    g_simulation CONSTANT VARCHAR2(1 CHAR) := 'S';

    -- CANCEL_REASON
    g_reason_action_cancel CONSTANT VARCHAR2(1) := 'C';
    g_patient_no_show      CONSTANT cancel_rea_area.intern_name%TYPE := 'PATIENT_NO_SHOW';

    -- codification
    g_conv_codification CONSTANT codification.id_content%TYPE := 'TMP133.2';

    -- Prolems/Diagnosis/Details operations   
    g_op_insert  CONSTANT VARCHAR2(1 CHAR) := 'I'; -- insert
    g_op_update  CONSTANT VARCHAR2(1 CHAR) := 'U'; -- update
    g_op_cancel  CONSTANT VARCHAR2(1 CHAR) := 'C'; -- cancel
    g_op_outdate CONSTANT VARCHAR2(1 CHAR) := 'O'; -- outdated
    g_op_delete  CONSTANT VARCHAR2(1 CHAR) := 'D'; -- delete

    -- diagnosis
    g_diagnosis_type_p CONSTANT VARCHAR2(1 CHAR) := 'P'; -- 'P' - working diagnosis

    g_interv_code      CONSTANT translation.code_translation%TYPE := 'INTERVENTION.CODE_INTERVENTION.';
    g_exam_code        CONSTANT translation.code_translation%TYPE := 'EXAM.CODE_EXAM.';
    g_analysis_code    CONSTANT translation.code_translation%TYPE := 'ANALYSIS.CODE_ANALYSIS.';
    g_sample_type_code CONSTANT translation.code_translation%TYPE := 'SAMPLE_TYPE.CODE_SAMPLE_TYPE.';

    g_reports_code CONSTANT translation.code_translation%TYPE := 'REPORTS.CODE_REPORTS.';

    -- BDNP CONSTANT
    g_bdnp_ref_type CONSTANT bdnp_presc_detail.flg_presc_type%TYPE := 'R'; -- REFERRAL
    g_bdnp_med_type CONSTANT bdnp_presc_detail.flg_presc_type%TYPE := 'M'; -- Medication

    g_bdnp_event_type_i  CONSTANT bdnp_presc_tracking.flg_event_type%TYPE := 'I'; -- insert request into bdnp
    g_bdnp_event_type_c  CONSTANT bdnp_presc_tracking.flg_event_type%TYPE := 'C'; -- cancel request in bdnp
    g_bdnp_event_type_ri CONSTANT bdnp_presc_tracking.flg_event_type%TYPE := 'RI'; -- resent insert request into bdnp
    g_bdnp_event_type_rc CONSTANT bdnp_presc_tracking.flg_event_type%TYPE := 'RC'; -- resent cancel request into bdnp

    g_bdnp_msg_e CONSTANT bdnp_message.flg_type%TYPE := 'E'; -- ERROR
    g_bdnp_msg_w CONSTANT bdnp_message.flg_type%TYPE := 'W'; -- WARNING
    g_bdnp_msg_s CONSTANT bdnp_message.flg_type%TYPE := 'S'; -- SUCESS
    g_bdnp_mig_n CONSTANT p1_external_request.flg_migrated%TYPE := 'N'; -- not in bdnp
    g_bdnp_mig_x CONSTANT p1_external_request.flg_migrated%TYPE := 'X'; -- not applicable (not sent to bdnp)

    g_sm_bdnp_alert_m001   CONSTANT sys_message.code_message%TYPE := 'BDNP_ALERT_M001';
    g_sm_bdnp_alert_w_m001 CONSTANT sys_message.code_message%TYPE := 'BDNP_ALERT_W_M001';
    g_sm_bdnp_alert_e_m001 CONSTANT sys_message.code_message%TYPE := 'BDNP_ALERT_E_M001';

    -- alerts
    g_sm_alert_m0103 CONSTANT sys_message.code_message%TYPE := 'V_ALERT_M0103';
    g_sm_alert_m0104 CONSTANT sys_message.code_message%TYPE := 'V_ALERT_M0104';
    g_sm_alert_m0105 CONSTANT sys_message.code_message%TYPE := 'V_ALERT_M0105';
    g_sm_alert_m0106 CONSTANT sys_message.code_message%TYPE := 'V_ALERT_M0106';
    g_sm_alert_m0107 CONSTANT sys_message.code_message%TYPE := 'V_ALERT_M0107';
    g_sm_alert_m0108 CONSTANT sys_message.code_message%TYPE := 'V_ALERT_M0108';
    g_sm_alert_m0109 CONSTANT sys_message.code_message%TYPE := 'V_ALERT_M0109';

    -- ref_spec_market 
    g_ref CONSTANT ref_spec_market.standard_type%TYPE := 'REF'; -- especialidade apenas do botão REF (n pode ser enviado pelo P1)
    g_cth CONSTANT ref_spec_market.standard_type%TYPE := 'CTH'; -- Apenas refe ACSS (consulta a tempo e horas)
    g_all CONSTANT ref_spec_market.standard_type%TYPE := 'ALL'; -- Todas (REF + CTH)

    g_bdnp_msg_n CONSTANT p1_external_request.flg_migrated%TYPE := 'N'; -- not in bdnp

    -- report mode 
    g_rep_mode_pv CONSTANT VARCHAR2(2 CHAR) := 'PV';
    g_rep_mode_pf CONSTANT VARCHAR2(2 CHAR) := 'PF';
    g_rep_mode_a  CONSTANT VARCHAR2(2 CHAR) := 'A';

    -- migration
    g_mig_successful   CONSTANT VARCHAR2(1 CHAR) := 'S';
    g_mig_unsuccessful CONSTANT VARCHAR2(1 CHAR) := 'U';
    g_map_system_alert CONSTANT VARCHAR2(100 CHAR) := 'ALERT';
    g_map_dcs          CONSTANT VARCHAR2(100 CHAR) := 'REF_MIG_DCS';

    --ALD MESSAGES
    -- header
    g_ref_comp_alda_t001 CONSTANT sys_message.code_message%TYPE := 'REF_COMP_ALDA_T001';
    g_ref_comp_aldi_t001 CONSTANT sys_message.code_message%TYPE := 'REF_COMP_ALDI_T001';
    g_ref_comp_alde_t001 CONSTANT sys_message.code_message%TYPE := 'REF_COMP_ALDE_T001';
    g_ref_comp_aldp_t001 CONSTANT sys_message.code_message%TYPE := 'REF_COMP_ALDP_T001';
    g_ref_comp_aldf_t001 CONSTANT sys_message.code_message%TYPE := 'REF_COMP_ALDF_T001';
    -- text 
    g_ref_comp_alda_m001 CONSTANT sys_message.code_message%TYPE := 'REF_COMP_ALDA_M001';
    g_ref_comp_aldi_m001 CONSTANT sys_message.code_message%TYPE := 'REF_COMP_ALDI_M001';
    g_ref_comp_alde_m001 CONSTANT sys_message.code_message%TYPE := 'REF_COMP_ALDE_M001';
    g_ref_comp_aldp_m001 CONSTANT sys_message.code_message%TYPE := 'REF_COMP_ALDP_M001';
    g_ref_comp_aldf_m001 CONSTANT sys_message.code_message%TYPE := 'REF_COMP_ALDF_M001';

    -- title

    -- query columns
    g_col_dt_p1         CONSTANT VARCHAR2(50 CHAR) := 'DT_P1';
    g_col_pat_name      CONSTANT VARCHAR2(50 CHAR) := 'PAT_NAME';
    g_col_pat_ndo       CONSTANT VARCHAR2(50 CHAR) := 'PAT_NDO'; -- patient non disclosure options
    g_col_pat_nd_icon   CONSTANT VARCHAR2(50 CHAR) := 'PAT_ND_ICON'; --patient non disclosure icon
    g_col_pat_gender    CONSTANT VARCHAR2(50 CHAR) := 'PAT_GENDER';
    g_col_pat_age       CONSTANT VARCHAR2(50 CHAR) := 'PAT_AGE';
    g_col_pat_photo     CONSTANT VARCHAR2(50 CHAR) := 'PAT_PHOTO';
    g_col_id_prof_req   CONSTANT VARCHAR2(50 CHAR) := 'ID_PROF_REQUESTED';
    g_col_prof_req_name CONSTANT VARCHAR2(50 CHAR) := 'PROF_REQUESTED_NAME';
    --    g_col_priority_icon       CONSTANT VARCHAR2(50 CHAR) := 'PRIORITY_ICON';
    g_col_priority_info CONSTANT VARCHAR2(50 CHAR) := 'PRIORITY_INFO';
    g_col_priority_desc CONSTANT VARCHAR2(50 CHAR) := 'PRIORITY_DESC';
    g_col_priority_icon CONSTANT VARCHAR2(50 CHAR) := 'PRIORITY_ICON';
    g_col_priority_sort CONSTANT VARCHAR2(50 CHAR) := 'PRIORITY_TO_SORT';

    g_col_type_icon           CONSTANT VARCHAR2(50 CHAR) := 'TYPE_ICON';
    g_col_inst_orig_name      CONSTANT VARCHAR2(50 CHAR) := 'INST_ORIG_NAME';
    g_col_inst_dest_name      CONSTANT VARCHAR2(50 CHAR) := 'INST_DEST_NAME';
    g_col_p1_spec_name        CONSTANT VARCHAR2(50 CHAR) := 'P1_SPEC_NAME';
    g_col_clin_srv_name       CONSTANT VARCHAR2(50 CHAR) := 'CLIN_SRV_NAME';
    g_col_id_prof_schedule    CONSTANT VARCHAR2(50 CHAR) := 'ID_PROF_SCHEDULE';
    g_col_dt_schedule         CONSTANT VARCHAR2(50 CHAR) := 'DT_SCHEDULE';
    g_col_hour_schedule       CONSTANT VARCHAR2(50 CHAR) := 'HOUR_SCHEDULE';
    g_col_dt_sch_millis       CONSTANT VARCHAR2(50 CHAR) := 'DT_SCH_MILLIS';
    g_col_prof_triage_name    CONSTANT VARCHAR2(50 CHAR) := 'PROF_TRIAGE_NAME';
    g_col_flg_task_editable   CONSTANT VARCHAR2(50 CHAR) := 'FLG_TASK_EDITABLE';
    g_col_flg_attach          CONSTANT VARCHAR2(50 CHAR) := 'FLG_ATTACH';
    g_col_dt_last_interaction CONSTANT VARCHAR2(50 CHAR) := 'DT_LAST_INTERACTION';
    g_col_status_info         CONSTANT VARCHAR2(50 CHAR) := 'STATUS_INFO';
    g_col_tr_status_info      CONSTANT VARCHAR2(50 CHAR) := 'TR_STATUS_INFO';
    g_col_can_cancel          CONSTANT VARCHAR2(50 CHAR) := 'CAN_CANCEL';
    g_col_can_sent            CONSTANT VARCHAR2(50 CHAR) := 'CAN_SENT';
    g_col_can_approve         CONSTANT VARCHAR2(50 CHAR) := 'CAN_APPROVE';
    g_col_desc_dec_urg_level  CONSTANT VARCHAR2(50 CHAR) := 'DESC_DECISION_URG_LEVEL';
    g_col_id_schedule_ext     CONSTANT VARCHAR2(50 CHAR) := 'ID_SCHEDULE_EXT';
    g_col_tr_status_desc      CONSTANT VARCHAR2(50 CHAR) := 'TR_STATUS_DESC';
    g_col_observations        CONSTANT VARCHAR2(50 CHAR) := 'OBSERVATIONS';
    g_col_id_content          CONSTANT VARCHAR2(50 CHAR) := 'ID_CONTENT';
    g_col_reason_desc         CONSTANT VARCHAR2(50 CHAR) := 'REASON_DESC';
    g_col_is_task_complet     CONSTANT VARCHAR2(50 CHAR) := 'IS_TASK_COMPLET';
    g_col_flg_match_redirect  CONSTANT VARCHAR2(50 CHAR) := 'FLG_MATCH_REDIRECT';
    g_col_rc_count            CONSTANT VARCHAR2(50 CHAR) := 'RC_VAL';

    -- issue referral
    g_issue_mode_o VARCHAR2(1 CHAR) := 'O';
    g_issue_mode_s VARCHAR2(1 CHAR) := 'S';

    -- ALERTS
    -- id_sys_alert
    g_sa_refused_no_epis       CONSTANT sys_alert.id_sys_alert%TYPE := 303;
    g_sa_refused_epis          CONSTANT sys_alert.id_sys_alert%TYPE := 301;
    g_sa_sent_back_no_epis     CONSTANT sys_alert.id_sys_alert%TYPE := 302;
    g_sa_sent_back_epis        CONSTANT sys_alert.id_sys_alert%TYPE := 300;
    g_sa_sch_ref               CONSTANT sys_alert.id_sys_alert%TYPE := 305;
    g_sa_handoff_declined      CONSTANT sys_alert.id_sys_alert%TYPE := 304;
    g_sa_sent_back_bur_no_epis CONSTANT sys_alert.id_sys_alert%TYPE := 306;

    g_sa_code_replace     CONSTANT VARCHAR2(500 CHAR) := '<<code>>';
    g_sa_code_sysmessage  CONSTANT VARCHAR2(500 CHAR) := '@SM[' || g_sa_code_replace || ']';
    g_sa_code_translation CONSTANT VARCHAR2(500 CHAR) := '@TR[' || g_sa_code_replace || ']';
    g_sa_code_sysdomain   CONSTANT VARCHAR2(500 CHAR) := '@SD[' || g_sa_code_replace || ']';

    -- grid referral views 
    g_view_p1_grid    CONSTANT VARCHAR2(50 CHAR) := 'v_p1_grid'; -- default
    g_view_p1_grid_tr CONSTANT VARCHAR2(50 CHAR) := 'v_p1_grid_tr';

    -- sys_domain context
    g_context_desc CONSTANT VARCHAR2(100 CHAR) := 'DESC_VAL';
    g_context_rank CONSTANT VARCHAR2(100 CHAR) := 'RANK';
    g_context_img  CONSTANT VARCHAR2(100 CHAR) := 'IMG_NAME';

    -- comment types
    g_clinical_comment       CONSTANT VARCHAR2(1 CHAR) := 'C';
    g_administrative_comment CONSTANT VARCHAR2(1 CHAR) := 'A';

    -- comment status
    g_active_comment   CONSTANT VARCHAR2(1 CHAR) := 'A';
    g_canceled_comment CONSTANT VARCHAR2(1 CHAR) := 'C';
    g_outdated_comment CONSTANT VARCHAR2(1 CHAR) := 'O';

    g_ref_cmt_status_code CONSTANT sys_domain.code_domain%TYPE := 'REF_COMMENTS.FLG_STATUS';

    g_shortcut_detail   sys_shortcut.id_sys_shortcut%TYPE := 28;
    g_shortcut_clin_doc sys_shortcut.id_sys_shortcut%TYPE := 905308;

    -- index used by array i_mcdt (in accordance with flash)
    g_idx_id_mcdt           CONSTANT PLS_INTEGER := 1;
    g_idx_id_req_det        CONSTANT PLS_INTEGER := 2;
    g_idx_id_inst_dest_mcdt CONSTANT PLS_INTEGER := 3;
    g_idx_amount            CONSTANT PLS_INTEGER := 4;
    g_idx_id_sample_type    CONSTANT PLS_INTEGER := 5; -- lab tests only

    -- referral reports
    g_rep_type_duplicata CONSTANT ref_report.flg_type%TYPE := 'D';
    g_rep_type_reprint   CONSTANT ref_report.flg_type%TYPE := 'R';

    -- referral field names: sys_domain where code_domain = 'REFERRAL_FIELDS'
    g_field_orig_inst     CONSTANT VARCHAR2(50 CHAR) := 'ORIG_INST'; -- 'at hospital entrance' fields
    g_field_orig_phy_name CONSTANT VARCHAR2(50 CHAR) := 'ORIG_PHY_NAME'; -- 'at hospital entrance' fields
    g_field_orig_phy_no   CONSTANT VARCHAR2(50 CHAR) := 'ORIG_PHY_NO'; -- 'at hospital entrance' fields
    g_field_reason        CONSTANT VARCHAR2(50 CHAR) := 'REASON';
    g_field_notes         CONSTANT VARCHAR2(50 CHAR) := 'NOTES'; -- mcdt
    g_field_rrn           CONSTANT VARCHAR2(50 CHAR) := 'REGISTRAR_REQ_NOTES'; -- Registrar request notes
    g_field_diagnosis     CONSTANT VARCHAR2(50 CHAR) := 'DIAGNOSIS';
    g_field_problem       CONSTANT VARCHAR2(50 CHAR) := 'PROBLEM';
    g_field_dt_problem    CONSTANT VARCHAR2(50 CHAR) := 'DT_PROBLEM';
    g_field_symptoms      CONSTANT VARCHAR2(50 CHAR) := 'SYMPTOMS';
    g_field_progress      CONSTANT VARCHAR2(50 CHAR) := 'PROGRESS';
    g_field_med           CONSTANT VARCHAR2(50 CHAR) := 'MEDICATION';
    g_field_vital_signes  CONSTANT VARCHAR2(50 CHAR) := 'VITAL_SIGNES';
    g_field_auge          CONSTANT VARCHAR2(50 CHAR) := 'AUGE';
    g_field_hist          CONSTANT VARCHAR2(50 CHAR) := 'HISTORY';
    g_field_family_hist   CONSTANT VARCHAR2(50 CHAR) := 'FAMILY_HISTORY';
    g_field_exam_o        CONSTANT VARCHAR2(50 CHAR) := 'OBJECTIVE_EXAM';
    g_field_exam_c        CONSTANT VARCHAR2(50 CHAR) := 'DIAGNOSTIC_TESTS';
    --
    g_field_sent_to_reg     CONSTANT VARCHAR2(50 CHAR) := 'SENT_TO_REG'; -- Pedidos ao adm
    g_field_add_information CONSTANT VARCHAR2(50 CHAR) := 'ADD_INFORMATION'; -- Informacao complementar
    g_field_notes_reg       CONSTANT VARCHAR2(50 CHAR) := 'NOTES_REG'; -- Notas ao adm
    g_field_comments        CONSTANT VARCHAR2(50 CHAR) := 'COMMENTS'; -- Comments
    -- referral answer
    g_field_answ_obs_summ       CONSTANT VARCHAR2(50 CHAR) := 'ANSW_OBS_SUMM'; -- resumo da obs
    g_field_answ_concl          CONSTANT VARCHAR2(50 CHAR) := 'ANSW_CONCL'; -- conclusoes
    g_field_answ_probl          CONSTANT VARCHAR2(50 CHAR) := 'ANSW_PROBL'; -- problemas de resposta (MX)
    g_field_answ_progress       CONSTANT VARCHAR2(50 CHAR) := 'ANSW_PROGRESS'; -- evolucao resposta (MX)
    g_field_answ_exam_prop      CONSTANT VARCHAR2(50 CHAR) := 'ANSW_EXAM_PROP'; -- proposta de novos exames
    g_field_answ_diag_create    CONSTANT VARCHAR2(50 CHAR) := 'ANSW_DIAG_REF_CREATE'; -- diagnosticos inseridos na criacao do P1
    g_field_answ_diag           CONSTANT VARCHAR2(50 CHAR) := 'ANSW_DIAG'; -- diagnosticos
    g_field_answ_treat_prop     CONSTANT VARCHAR2(50 CHAR) := 'ANSW_TREAT_PROP'; -- proposta terapeutica
    g_field_answ_dt_comeback    CONSTANT VARCHAR2(50 CHAR) := 'ANSW_DT_COMEBACK'; -- fecha (MX)
    g_field_answ_label_comeback CONSTANT VARCHAR2(50 CHAR) := 'ANSW_LABEL_COMEBACK'; -- Debe regressar? (MX)

    g_referral_fields_code CONSTANT sys_domain.code_domain%TYPE := 'REFERRAL_FIELDS';

    g_task_type_referral CONSTANT task_type.id_task_type%TYPE := 58;

    g_slg_ref_compl_options   CONSTANT sys_list_group.internal_name%TYPE := 'REFERRAL_COMPLETION_OPTIONS';
    g_sc_show_concl_popup_ref CONSTANT sys_config.id_sys_config%TYPE := 'SHOW_CONCLUSION_POPUP_REFERRAL';

    /**
    * Maps action internal name into id
    *
    * @param   i_action        Action internal name to be mapped
    *
    * @RETURN  Action identifier
    * @author  Ana Monteiro
    * @version 1.0
    * @since   15-10-2010   
    */
    FUNCTION get_action_id(i_action IN wf_workflow_action.internal_name%TYPE)
        RETURN wf_workflow_action.id_workflow_action%TYPE;

    /**
    * Maps action id into internal name
    *
    * @param   i_status        Action id to be mapped
    *
    * @RETURN  Action name
    * @author  Ana Monteiro
    * @version 1.0
    * @since   15-10-2010   
    */
    FUNCTION get_action_name(i_action IN wf_workflow_action.id_workflow_action%TYPE)
        RETURN wf_workflow_action.internal_name%TYPE;

END pk_ref_constant;
/
