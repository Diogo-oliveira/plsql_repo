/*-- Last Change Revision: $Rev: 2028659 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:10 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_edis_global_search IS

    -- Author  : ALEXANDRE.SANTOS
    -- Created : 11/19/2013 10:28:07 PM
    -- Purpose : Global search API's

    -- Public constant declarations

    -- Public function and procedure declarations
    FUNCTION get_rec_result_epis_diagnosis
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN epis_diagnosis%ROWTYPE
    ) RETURN t_trl_trs_result;

    PROCEDURE get_codes_desc_epis_diagnosis
    (
        i_owner     IN VARCHAR2,
        i_table     IN VARCHAR2,
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_rowtype   IN epis_diagnosis%ROWTYPE,
        o_code_list OUT table_varchar,
        o_desc_list OUT table_varchar
    );

    FUNCTION get_rec_result_epis_diag_notes
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN epis_diagnosis_notes%ROWTYPE
    ) RETURN t_trl_trs_result;

    FUNCTION get_rec_result_pat_habit
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN pat_habit%ROWTYPE
    ) RETURN t_trl_trs_result;

    PROCEDURE get_codes_desc_pat_habit
    (
        i_owner     IN VARCHAR2,
        i_table     IN VARCHAR2,
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_rowtype   IN pat_habit%ROWTYPE,
        o_code_list OUT table_varchar,
        o_desc_list OUT table_varchar
    );

    PROCEDURE get_codes_desc_epis_diag_notes
    (
        i_owner     IN VARCHAR2,
        i_table     IN VARCHAR2,
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_rowtype   IN epis_diagnosis_notes%ROWTYPE,
        o_code_list OUT table_varchar,
        o_desc_list OUT table_varchar
    );

    FUNCTION get_rec_result_pat_allergy
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN pat_allergy%ROWTYPE
    ) RETURN t_trl_trs_result;

    PROCEDURE get_codes_desc_pat_allergy
    (
        i_owner     IN VARCHAR2,
        i_table     IN VARCHAR2,
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_rowtype   IN pat_allergy%ROWTYPE,
        o_code_list OUT table_varchar,
        o_desc_list OUT table_varchar
    );

    FUNCTION get_rec_result_pat_allergy_sym
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN pat_allergy_symptoms%ROWTYPE
    ) RETURN t_trl_trs_result;

    PROCEDURE get_codes_desc_pat_allergy_sym
    (
        i_owner     IN VARCHAR2,
        i_table     IN VARCHAR2,
        i_lang      IN NUMBER,
        i_rowtype   IN pat_allergy_symptoms%ROWTYPE,
        o_code_list OUT table_varchar,
        o_desc_list OUT table_varchar
    );

END pk_edis_global_search;
/
