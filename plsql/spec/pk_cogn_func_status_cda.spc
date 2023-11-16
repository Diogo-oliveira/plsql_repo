/*-- Last Change Revision: $Rev: 2028567 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:34 +0100 (ter, 02 ago 2022) $*/


CREATE OR REPLACE PACKAGE pk_cogn_func_status_cda IS

    TYPE pat_cogn_func_rec IS RECORD(
        id                      NUMBER(24),
        id_problem              NUMBER(24),
        TYPE                    VARCHAR2(2),
        dt_problem2             VARCHAR2(200),
        dt_problem              VARCHAR2(50),
        dt_problem_to_print     VARCHAR2(50),
        desc_probl              VARCHAR2(4000),
        title                   VARCHAR2(4000),
        flg_source              VARCHAR2(2),
        dt_order                VARCHAR2(14),
        flg_status              VARCHAR2(2),
        rank_type               NUMBER(6),
        flg_cancel              VARCHAR2(2),
        desc_status             VARCHAR2(200),
        desc_nature             VARCHAR2(200),
        rank_status             NUMBER(6),
        rank_nature             NUMBER(6),
        flg_nature              VARCHAR2(2),
        title_notes             VARCHAR2(4000),
        prob_notes              VARCHAR2(4000),
        title_canceled          VARCHAR2(4000),
        id_prob                 NUMBER(24),
        viewer_category         VARCHAR2(4000),
        viewer_category_desc    VARCHAR2(4000),
        viewer_id_prof          NUMBER(24),
        viewer_id_epis          NUMBER(24),
        viewer_date             VARCHAR2(14),
        registered_by_me        VARCHAR2(1),
        origin_specialty        VARCHAR2(200),
        id_origin_specialty     NUMBER(24),
        precaution_measures_str table_varchar,
        id_precaution_measures  table_number,
        header_warning          VARCHAR2(1),
        header_warning_str      VARCHAR2(200),
        resolution_date_str     VARCHAR2(200),
        resolution_date         VARCHAR2(200),
        warning_icon            VARCHAR2(4000),
        review_info             table_varchar,
        id_pat_habit            NUMBER(24),
        flg_area                VARCHAR2(1),
        id_content              VARCHAR2(200 CHAR),
        is_cognitive            NUMBER(1),
        is_functional           NUMBER(1),
        id_terminology_version  NUMBER(24),
        code_icd                VARCHAR2(200 CHAR),
        dt_problem_serial       VARCHAR2(50));
    TYPE pat_cogn_func_table IS TABLE OF pat_cogn_func_rec;

    -- Author  : JOEL.LOPES
    -- Created : 12/26/2013 10:50:50 AM
    -- Purpose : Package that should contain all functions/procedures for CDA

    /*/**********************************************************************************************
    * List all diagnosis registered in an episode
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_episode                Episode id
    * @param i_flg_type               Diagnosis type: P - differential, D - final
    * @param i_criteria               search criteria
    * @param i_format_text            
    *
    * @return                         Diagnoses list
    *
    * @author                               Joel Lopes
    * @version                              2.6.3
    * @since                                27-12-2013
    **********************************************************************************************/

    FUNCTION get_cog_and_func_cda
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_pat       IN pat_history_diagnosis.id_patient%TYPE,
        i_status    IN table_varchar,
        i_type      IN VARCHAR2,
        i_problem   IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE DEFAULT NULL,
        i_scopeid   IN pat_problem.id_episode%TYPE,
        i_flg_scope IN VARCHAR2,
        i_dt_ini    IN pat_history_diagnosis.dt_pat_history_diagnosis_tstz%TYPE,
        i_dt_end    IN pat_history_diagnosis.dt_pat_history_diagnosis_tstz%TYPE
    ) RETURN pat_cogn_func_table
        PIPELINED;

    FUNCTION get_is_cog_and_func
    (
        i_internal_name IN concept_type.internal_name%TYPE,
        i_id_concept    IN NUMBER
    ) RETURN NUMBER;
    ---
    g_flg_type_med    CONSTANT pat_history_diagnosis.flg_type%TYPE := 'M';
    g_flg_status_none CONSTANT pat_history_diagnosis.flg_status%TYPE := 'N';
    g_flg_status_unk  CONSTANT pat_history_diagnosis.flg_status%TYPE := 'U';
    g_flg_cancel      CONSTANT VARCHAR2(2) := 'C';

    g_code_domain          CONSTANT VARCHAR2(200) := 'PATIENT_PROBLEM.FLG_SOURCE';
    g_problem_type_allergy CONSTANT VARCHAR2(2) := 'A';
    g_problem_type_diag    CONSTANT VARCHAR2(2) := 'D';
    g_problem_type_habit   CONSTANT VARCHAR2(2) := 'H';
    g_problem_type_problem CONSTANT VARCHAR2(2) := 'PP';
    g_problem_type_pmh     CONSTANT VARCHAR2(2) := 'PH';

    g_epis_diag_passive epis_diagnosis.flg_type%TYPE;

    g_no                 CONSTANT VARCHAR2(1) := 'N';
    g_yes                CONSTANT VARCHAR2(1) := 'Y';
    g_semicolon          CONSTANT VARCHAR2(2 CHAR) := '; ';
    g_type_p             CONSTANT VARCHAR2(1 CHAR) := 'P';
    g_type_a             CONSTANT VARCHAR2(1 CHAR) := 'A';
    g_type_d             CONSTANT VARCHAR2(1 CHAR) := 'D';
    g_unknown            CONSTANT VARCHAR2(1 CHAR) := 'U';
    g_year_unknown       CONSTANT VARCHAR2(2 CHAR) := '-1';
    g_zero               CONSTANT NUMBER := 0;
    g_um                 CONSTANT NUMBER := 1;
    g_problem_cognitive  CONSTANT VARCHAR2(200 CHAR) := 'PROBLEM_COGNITIVE';
    g_problem_functional CONSTANT VARCHAR2(200 CHAR) := 'PROBLEM_FUNCTIONAL';

    g_main_concept_type_n CONSTANT VARCHAR2(1) := 'N';

    g_report_p CONSTANT VARCHAR2(1) := 'P';
    g_report_v CONSTANT VARCHAR2(1) := 'V';
    g_report_e CONSTANT VARCHAR2(1) := 'E';

    g_pat_probl_active   pat_problem.flg_status%TYPE;
    g_pat_probl_passive  pat_problem.flg_status%TYPE;
    g_pat_probl_cancel   pat_problem.flg_status%TYPE;
    g_pat_probl_resolved pat_problem.flg_status%TYPE;
    g_pat_probl_invest   pat_problem.flg_status%TYPE;

    g_scope_patient CONSTANT VARCHAR2(1) := 'P';
    g_scope_visit   CONSTANT VARCHAR2(1) := 'V';
    g_scope_episode CONSTANT VARCHAR2(1) := 'E';

    g_problem_cognitive_status  CONSTANT VARCHAR2(200 CHAR) := 'COGNITIVE_STATUS';
    g_problem_functional_status CONSTANT VARCHAR2(200 CHAR) := 'FUNCTIONAL_STATUS';

END pk_cogn_func_status_cda;
/
