/*-- Last Change Revision: $Rev: 1980541 $*/
/*-- Last Change by: $Author: adriana.salgueiro $*/
/*-- Date of last change: $Date: 2021-02-23 09:14:57 +0000 (ter, 23 fev 2021) $*/

CREATE OR REPLACE PACKAGE pk_codification_prm IS
    SUBTYPE t_clob IS CLOB;
    SUBTYPE t_big_char IS VARCHAR2(1000 CHAR);
    SUBTYPE t_med_char IS VARCHAR2(0200 CHAR);
    SUBTYPE t_low_char IS VARCHAR2(0030 CHAR);
    SUBTYPE t_flg_char IS VARCHAR2(0001 CHAR);

    -- content loader method signature
    FUNCTION load_codification_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION load_analysis_codification_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION load_exam_codification_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION load_interv_codification_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Configuration of Diagnosis and codification relation
    *
    * @param i_lang                  Language id
    * @param o_result                Number of results configured
    * @param o_error                 error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2012/12/13
    * @version                       2.6.1.14
    ********************************************************************************************/
    FUNCTION load_diag_codif_def
    (
        i_lang   IN language.id_language%TYPE,
        o_result OUT NUMBER,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Configuration of Diagnosis and codification relation
    *
    * @param i_lang                  Language id
    * @param o_result                Number of results configured
    * @param o_error                 error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2012/12/13
    * @version                       2.6.1.14
    ********************************************************************************************/
    FUNCTION load_extcause_codif_def
    (
        i_lang   IN language.id_language%TYPE,
        o_result OUT NUMBER,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;
    -- searcheable loader method signature
    FUNCTION set_codification_is_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        i_id_content  IN table_varchar,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    -- frequent loader method signature

    FUNCTION del_codification_is_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    -- global vars
    g_error         t_big_char;
    g_flg_available t_flg_char;
    g_active        t_flg_char;
    g_version       t_low_char;
    g_func_name     t_med_char;

    g_array_size  NUMBER;
    g_array_size1 NUMBER;
END pk_codification_prm;
/
