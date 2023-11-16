/*-- Last Change Revision: $Rev: 2028942 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:52 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_scales_constant IS

    -- Author  : SOFIA.MENDES
    -- Created : 7/6/2011 8:45:51 AM
    -- Purpose : This package will collect all the constant related to the SCALES functionality

    -- Public constant declarations
    --score type
    g_flg_score_total_t   CONSTANT VARCHAR2(1 CHAR) := 'T';
    g_flg_score_partial_p CONSTANT VARCHAR2(1 CHAR) := 'P';

    g_formula_sum               CONSTANT VARCHAR2(3 CHAR) := 'SUM';
    g_formula_mult              CONSTANT VARCHAR2(4 CHAR) := 'MULT';
    g_formula_nr_answers        CONSTANT VARCHAR2(10 CHAR) := 'NR_ANSWERS';
    g_formula_nr_answ_questions CONSTANT VARCHAR2(21 CHAR) := 'NR_ANSWERED_QUESTIONS';
    g_formula_max               CONSTANT VARCHAR2(3 CHAR) := 'MAX';

    --formula types
    g_formula_type_tm CONSTANT scales_formula.flg_formula_type%TYPE := 'TM'; --total main formula
    g_formula_type_pm CONSTANT scales_formula.flg_formula_type%TYPE := 'PM'; --partial main formula
    g_formula_type_c  CONSTANT scales_formula.flg_formula_type%TYPE := 'C'; --complementar formula

    --arithemetic operations
    g_operator_plus CONSTANT VARCHAR2(1 CHAR) := '+';
    g_operator_mult CONSTANT VARCHAR2(1 CHAR) := '*';

    g_replace_1         CONSTANT VARCHAR2(2 CHAR) := '@1';
    g_percentage        CONSTANT VARCHAR2(1 CHAR) := '%';
    g_open_parenthesis  CONSTANT VARCHAR2(1 CHAR) := '(';
    g_close_parenthesis CONSTANT VARCHAR2(1 CHAR) := ')';

    --epis_scales_score.flg_status
    g_scales_score_status_a CONSTANT epis_scales_score.flg_status%TYPE := 'A';
    g_scales_score_status_o CONSTANT epis_scales_score.flg_status%TYPE := 'O';

    --Score scopes
    g_score_scope_scale_s CONSTANT VARCHAR2(1char) := 'T';
    g_score_scope_comp_c  CONSTANT VARCHAR2(1char) := 'G';
    g_score_scope_group_g CONSTANT VARCHAR2(1char) := 'S';

    g_formula_alias_start CONSTANT VARCHAR2(1char) := '#';
    g_formula_alias_end   CONSTANT VARCHAR2(1char) := '|';

    g_total_msg CONSTANT VARCHAR2(17 CHAR) := 'RISK_FACTORS_T004';

    g_grids_doc_area_sc CONSTANT sys_config.id_sys_config%TYPE := 'RISK_DOC_AREA';

END pk_scales_constant;
/
