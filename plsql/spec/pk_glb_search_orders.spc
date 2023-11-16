/*-- Last Change Revision: $Rev: 1877368 $*/
/*-- Last Change by: $Author: adriano.ferreira $*/
/*-- Date of last change: $Date: 2018-11-12 15:39:19 +0000 (seg, 12 nov 2018) $*/

CREATE OR REPLACE PACKAGE pk_glb_search_orders IS

    -- Author  : PEDRO.MIRANDA
    -- Created : 12/10/2013 3:21:43 PM
    -- Purpose : 

    FUNCTION get_tbl_analysis_harvest
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN analysis_harvest%ROWTYPE
    ) RETURN t_trl_trs_result;

    PROCEDURE get_tbl_an_harvest_desc_codes
    (
        i_owner     IN VARCHAR2,
        i_table     IN VARCHAR2,
        i_lang      IN NUMBER,
        i_rowtype   IN analysis_harvest%ROWTYPE,
        o_code_list OUT table_varchar,
        o_desc_list OUT table_varchar
    );

    FUNCTION get_tbl_analysis_quest_resp
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN analysis_question_response%ROWTYPE
    ) RETURN t_trl_trs_result;

    FUNCTION get_tbl_analysis_req
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN analysis_req%ROWTYPE
    ) RETURN t_trl_trs_result;

    FUNCTION get_tbl_analysis_result
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN analysis_result%ROWTYPE
    ) RETURN t_trl_trs_result;

    FUNCTION get_tbl_analysis_result_par
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN analysis_result_par%ROWTYPE
    ) RETURN t_trl_trs_result;

    FUNCTION get_tbl_care_plan
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN care_plan%ROWTYPE
    ) RETURN t_trl_trs_result;

    FUNCTION get_tbl_care_plan_task
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN care_plan_task%ROWTYPE
    ) RETURN t_trl_trs_result;

    PROCEDURE get_tbl_cp_task_desc_codes
    (
        i_owner     IN VARCHAR2,
        i_table     IN VARCHAR2,
        i_lang      IN NUMBER,
        i_rowtype   IN care_plan_task%ROWTYPE,
        o_code_list OUT table_varchar,
        o_desc_list OUT table_varchar
    );

    FUNCTION get_tbl_care_plan_task_lk
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN care_plan_task_link%ROWTYPE
    ) RETURN t_trl_trs_result;

    PROCEDURE get_tbl_cp_task_lk_desc_codes
    (
        i_owner     IN VARCHAR2,
        i_table     IN VARCHAR2,
        i_lang      IN NUMBER,
        i_rowtype   IN care_plan_task_link%ROWTYPE,
        o_code_list OUT table_varchar,
        o_desc_list OUT table_varchar
    );

    FUNCTION get_tbl_exam_req
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN exam_req%ROWTYPE
    ) RETURN t_trl_trs_result;

    FUNCTION get_tbl_exam_req_det
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN exam_req_det%ROWTYPE
    ) RETURN t_trl_trs_result;

    PROCEDURE get_tbl_exam_req_dt_desc_codes
    (
        i_owner     IN VARCHAR2,
        i_table     IN VARCHAR2,
        i_lang      IN NUMBER,
        i_rowtype   IN exam_req_det%ROWTYPE,
        o_code_list OUT table_varchar,
        o_desc_list OUT table_varchar
    );

    FUNCTION get_tbl_exam_result
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN exam_result%ROWTYPE
    ) RETURN t_trl_trs_result;

    FUNCTION get_tbl_harvest
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN harvest%ROWTYPE
    ) RETURN t_trl_trs_result;

    PROCEDURE get_tbl_harvest_desc_codes
    (
        i_owner     IN VARCHAR2,
        i_table     IN VARCHAR2,
        i_lang      IN NUMBER,
        i_rowtype   IN harvest%ROWTYPE,
        o_code_list OUT table_varchar,
        o_desc_list OUT table_varchar
    );

    FUNCTION get_tbl_order_set_process
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN order_set_process%ROWTYPE
    ) RETURN t_trl_trs_result;

    FUNCTION get_tbl_order_set_proc_task
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN order_set_process_task_det%ROWTYPE
    ) RETURN t_trl_trs_result;

    FUNCTION get_tbl_protocol_process
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN protocol_process%ROWTYPE
    ) RETURN t_trl_trs_result;

    FUNCTION get_tbl_protocol_proc_element
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN protocol_process_element%ROWTYPE
    ) RETURN t_trl_trs_result;

    FUNCTION get_tbl_therapeutic_decision
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN therapeutic_decision%ROWTYPE
    ) RETURN t_trl_trs_result;

    PROCEDURE get_tbl_analysis_desc_codes
    (
        i_owner     IN VARCHAR2,
        i_table     IN VARCHAR2,
        i_lang      IN NUMBER,
        i_rowtype   IN analysis_req_det%ROWTYPE,
        o_code_list OUT table_varchar,
        o_desc_list OUT table_varchar
    );

    FUNCTION get_tbl_col_info_rec
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN analysis_req_det%ROWTYPE
    ) RETURN t_trl_trs_result;

END pk_glb_search_orders;
/
