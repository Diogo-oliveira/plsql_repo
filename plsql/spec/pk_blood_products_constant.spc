/*-- Last Change Revision: $Rev: 2043880 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2022-08-04 10:37:31 +0100 (qui, 04 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_blood_products_constant IS

    g_yes CONSTANT VARCHAR2(1 CHAR) := 'Y';
    g_no  CONSTANT VARCHAR2(1 CHAR) := 'N';

    g_active   CONSTANT VARCHAR2(1 CHAR) := 'A';
    g_inactive CONSTANT VARCHAR2(1 CHAR) := 'I';

    g_selected CONSTANT VARCHAR2(1 CHAR) := 'S';

    g_available CONSTANT VARCHAR2(1 CHAR) := 'Y';

    g_flg_time_e CONSTANT VARCHAR2(1 CHAR) := 'E'; -- In this episode
    g_flg_time_b CONSTANT VARCHAR2(1 CHAR) := 'B'; -- Between episodes
    g_flg_time_n CONSTANT VARCHAR2(1 CHAR) := 'N'; -- Next episode

    g_flg_priority_urgent    CONSTANT VARCHAR2(1 CHAR) := 'U';
    g_flg_priority_emergency CONSTANT VARCHAR2(1 CHAR) := 'E';
    g_flg_priority_routine   CONSTANT VARCHAR2(1 CHAR) := 'N';

    g_status_req_r  CONSTANT VARCHAR2(1 CHAR) := 'R';
    g_status_req_p  CONSTANT VARCHAR2(1 CHAR) := 'P';
    g_status_req_c  CONSTANT VARCHAR2(1 CHAR) := 'C';
    g_status_req_df CONSTANT VARCHAR2(2 CHAR) := 'DF';
    g_status_req_pd CONSTANT VARCHAR2(2 CHAR) := 'PD';
    g_status_req_f  CONSTANT VARCHAR2(1 CHAR) := 'F';
    g_status_req_i  CONSTANT VARCHAR2(1 CHAR) := 'I';
    g_status_req_d  CONSTANT VARCHAR2(1 CHAR) := 'D';
    g_status_req_o  CONSTANT VARCHAR2(1 CHAR) := 'O';
    g_status_req_n  CONSTANT VARCHAR2(1 CHAR) := 'N';
    g_status_req_e  CONSTANT VARCHAR2(1 CHAR) := 'E';
    g_status_req_wr CONSTANT VARCHAR2(2 CHAR) := 'WR';

    g_status_det_r_sc CONSTANT VARCHAR2(2 CHAR) := 'RS'; -- Requisitado without collection
    g_status_det_r_cc CONSTANT VARCHAR2(2 CHAR) := 'RC'; -- Requisitado with collection
    g_status_det_r_w  CONSTANT VARCHAR2(2 CHAR) := 'RW'; -- Technician request waiting
    g_status_det_wt   CONSTANT VARCHAR2(2 CHAR) := 'WT'; -- Waiting transport
    g_status_det_ot   CONSTANT VARCHAR2(2 CHAR) := 'OT'; -- Waiting transport
    g_status_det_ct   CONSTANT VARCHAR2(2 CHAR) := 'CT'; -- Waiting transport
    g_status_det_ns   CONSTANT VARCHAR2(2 CHAR) := 'NS'; -- Prepare Not Send
    g_status_det_rt   CONSTANT VARCHAR2(2 CHAR) := 'RT'; -- Ready for transfusion
    g_status_det_o    CONSTANT VARCHAR2(2 CHAR) := 'O'; -- Ongoing transfusion
    g_status_det_h    CONSTANT VARCHAR2(2 CHAR) := 'H'; -- Hold transfusion
    g_status_det_d    CONSTANT VARCHAR2(2 CHAR) := 'D'; -- Discontinued
    g_status_det_c    CONSTANT VARCHAR2(2 CHAR) := 'C'; -- Canceled
    g_status_det_pd   CONSTANT VARCHAR2(2 CHAR) := 'PD';
    g_status_det_df   CONSTANT VARCHAR2(2 CHAR) := 'DF';
    g_status_det_n    CONSTANT VARCHAR2(1 CHAR) := 'N';
    g_status_det_br   CONSTANT VARCHAR2(2 CHAR) := 'BR'; -- Bag returned
    g_status_det_f    CONSTANT VARCHAR2(1 CHAR) := 'F'; -- Finish
    g_status_det_e    CONSTANT VARCHAR2(1 CHAR) := 'E'; -- Expired
    g_status_det_x    CONSTANT VARCHAR2(1 CHAR) := 'X'; -- No longer safe for administration
    g_status_det_wr   CONSTANT VARCHAR2(2 CHAR) := 'WR'; --Waiting for bag return
    g_status_det_or   CONSTANT VARCHAR2(2 CHAR) := 'OR'; --Ongoing bag return    
    g_status_det_cr   CONSTANT VARCHAR2(2 CHAR) := 'CR'; --Completed bag return   

    g_task_type_bp      CONSTANT NUMBER(24) := 131;
    g_task_type_cpoe_bp CONSTANT NUMBER(24) := 49;

    g_bp_cq_on_order       CONSTANT bp_questionnaire.flg_time%TYPE := 'O';
    g_bp_cq_before_execute CONSTANT bp_questionnaire.flg_time%TYPE := 'BE';
    g_bp_cq_after_execute  CONSTANT bp_questionnaire.flg_time%TYPE := 'AE';

    g_bp_unit_ml  CONSTANT blood_product_det.id_unit_mea_qty_exec%TYPE := 10554;
    g_bp_unit_bag CONSTANT blood_product_det.id_unit_mea_qty_exec%TYPE := 10610;

    g_bp_doc_area_pre      doc_area.id_doc_area%TYPE := 36058;
    g_bp_doc_area_obs      doc_area.id_doc_area%TYPE := 36059;
    g_bp_doc_area_post     doc_area.id_doc_area%TYPE := 36060;
    g_bp_doc_area_adv_reac doc_area.id_doc_area%TYPE := 36061;

    -- ti_log
    g_bp_type CONSTANT ti_log.flg_type%TYPE := 'BP';

    g_bp_action_order            VARCHAR(20 CHAR) := 'ORDER';
    g_bp_action_administer       VARCHAR(20 CHAR) := 'ADMIN';
    g_bp_action_hold             VARCHAR(20 CHAR) := 'HOLD';
    g_bp_action_resume           VARCHAR(20 CHAR) := 'RESUME';
    g_bp_action_report           VARCHAR(20 CHAR) := 'REPORT';
    g_bp_action_reevaluate       VARCHAR(20 CHAR) := 'REEVALUATE';
    g_bp_action_conclude         VARCHAR(20 CHAR) := 'CONCLUDE';
    g_bp_action_return           VARCHAR(20 CHAR) := 'RETURN';
    g_bp_action_cancel           VARCHAR(20 CHAR) := 'CANCEL';
    g_bp_action_begin_transp     VARCHAR(20 CHAR) := 'BEGIN_TRANSP';
    g_bp_action_end_transp       VARCHAR(20 CHAR) := 'END_TRANSP';
    g_bp_action_lab_service      VARCHAR(20 CHAR) := 'LAB_SERVICE';
    g_bp_action_lab_collected    VARCHAR(20 CHAR) := 'LAB_COLLECTED';
    g_bp_action_compability      VARCHAR(20 CHAR) := 'COMPATIBILITY';
    g_bp_action_condition        VARCHAR(20 CHAR) := 'CONDITION';
    g_bp_action_blood_group      VARCHAR(20 CHAR) := 'BLOOD_GROUP';
    g_bp_action_lab_mother       VARCHAR(20 CHAR) := 'LAB_MOTHER';
    g_bp_action_begin_return     VARCHAR(20 CHAR) := 'BEGIN_RETURN';
    g_bp_action_end_return       VARCHAR(20 CHAR) := 'END_RETURN';
    g_bp_action_discontinue      VARCHAR(20 CHAR) := 'DISCONTINUE';
    g_bp_action_lab_mother_id    VARCHAR(20 CHAR) := 'LAB_MOTHER_ID';
    g_bp_action_prepare_not_send VARCHAR(20 CHAR) := 'PREPARE_NOT_SEND';

    --BP compatibility warnings
    g_bp_warning_compatibility CONSTANT VARCHAR2(1) := 'I';
    g_bp_warning_time_limit    CONSTANT VARCHAR2(1) := 'T';
    g_bp_warning_both          CONSTANT VARCHAR2(1) := 'B';

    --BP blood group
    g_an_blood_no_result     CONSTANT PLS_INTEGER := 1;
    g_an_blood_no_confirmed  CONSTANT PLS_INTEGER := 2;
    g_an_blood_confirmed     CONSTANT PLS_INTEGER := 3;
    g_an_blood_no_coincident CONSTANT PLS_INTEGER := 4;

    --NEWBORN
    g_bp_newborn_age_limit CONSTANT PLS_INTEGER := 7;
    g_bp_fam_rel_mother    CONSTANT PLS_INTEGER := 2;

    --AREAS
    g_bp_special_type_area  CONSTANT VARCHAR2(50) := 'BP_SPECIAL_TYPE';
    g_bp_special_instr_area CONSTANT VARCHAR2(50) := 'BP_SPECIAL_INSTRUCTIONS';

    --Blood product condition
    g_bp_condition        CONSTANT VARCHAR2(1) := 'C';
    g_bp_condition_reason CONSTANT VARCHAR2(1) := 'R';
    g_bp_condition_notes  CONSTANT VARCHAR2(1) := 'N';
END pk_blood_products_constant;
/
