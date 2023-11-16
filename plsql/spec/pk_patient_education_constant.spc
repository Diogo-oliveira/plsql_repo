/*-- Last Change Revision: $Rev: 2028847 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:18 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_patient_education_constant IS

    g_no_color VARCHAR2(1) := 'X';

    -- nurse teaching request status flag
    g_nurse_tea_req_sug          CONSTANT nurse_tea_req.flg_status%TYPE := 'S';
    g_nurse_tea_req_pend         CONSTANT nurse_tea_req.flg_status%TYPE := 'D';
    g_nurse_tea_req_act          CONSTANT nurse_tea_req.flg_status%TYPE := 'A';
    g_nurse_tea_req_fin          CONSTANT nurse_tea_req.flg_status%TYPE := 'F';
    g_nurse_tea_req_canc         CONSTANT nurse_tea_req.flg_status%TYPE := 'C';
    g_nurse_tea_req_ign          CONSTANT nurse_tea_req.flg_status%TYPE := 'I';
    g_nurse_tea_req_draft        CONSTANT nurse_tea_req.flg_status%TYPE := 'Z';
    g_nurse_tea_req_expired      CONSTANT nurse_tea_req.flg_status%TYPE := 'O';
    g_nurse_tea_req_not_ord_reas CONSTANT nurse_tea_req.flg_status%TYPE := 'N';
    g_nurse_tea_req_descontinued CONSTANT nurse_tea_req.flg_status%TYPE := 'X';

    -- nurse teaching configuration type flag
    g_nurse_tea_searchable CONSTANT nurse_tea_top_soft_inst.flg_type%TYPE := 'P';
    g_nurse_tea_frequent   CONSTANT nurse_tea_top_soft_inst.flg_type%TYPE := 'M';

    g_selected   CONSTANT prof_dep_clin_serv.flg_status%TYPE := 'S';
    g_searchable CONSTANT nurse_tea_top_soft_inst.flg_type%TYPE := 'P';
    g_frequent   CONSTANT nurse_tea_top_soft_inst.flg_type%TYPE := 'M';

    g_nurse_tea_det_pend CONSTANT nurse_tea_det.flg_status%TYPE := 'D';
    g_nurse_tea_det_exec CONSTANT nurse_tea_det.flg_status%TYPE := 'E';
    g_nurse_tea_det_canc CONSTANT nurse_tea_det.flg_status%TYPE := 'C';
    g_nurse_tea_det_ign  CONSTANT nurse_tea_det.flg_status%TYPE := 'I';

    g_flg_time_before  CONSTANT nurse_tea_req.flg_time%TYPE := 'B';
    g_flg_time_episode CONSTANT nurse_tea_req.flg_time%TYPE := 'E';
    g_flg_time_next    CONSTANT nurse_tea_req.flg_time%TYPE := 'N';

    g_sys_domain_req_flg_status   CONSTANT sys_domain.code_domain%TYPE := 'NURSE_TEA_REQ.FLG_STATUS';
    g_sys_domain_req_status_flg   CONSTANT sys_domain.code_domain%TYPE := 'NURSE_TEA_REQ.STATUS_FLG';
    g_sys_domain_det_flg_status   CONSTANT sys_domain.code_domain%TYPE := 'NURSE_TEA_DET.FLG_STATUS';
    g_sys_domain_flg_time         CONSTANT sys_domain.code_domain%TYPE := 'NURSE_TEA_REQ.FLG_TIME';
    g_sys_domain_flg_deliverables CONSTANT sys_domain.code_domain%TYPE := 'NURSE_TEA_DET.FLG_DELIVERABLES';

END pk_patient_education_constant;
/
