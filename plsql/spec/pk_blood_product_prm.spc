/*-- Last Change Revision: $Rev: 1945383 $*/
/*-- Last Change by: $Author: adriana.salgueiro $*/
/*-- Date of last change: $Date: 2020-04-14 09:14:38 +0100 (ter, 14 abr 2020) $*/
CREATE OR REPLACE PACKAGE alert.pk_blood_product_prm IS
    SUBTYPE t_clob IS CLOB;
    SUBTYPE t_big_char IS VARCHAR2(1000 CHAR);
    SUBTYPE t_med_char IS VARCHAR2(0200 CHAR);
    SUBTYPE t_low_char IS VARCHAR2(0030 CHAR);
    SUBTYPE t_flg_char IS VARCHAR2(0001 CHAR);

    /**
    * Load hemo types from default table
    *
    * @param i_lang                Prefered language ID
    * @param o_result_tbl          Number of records inserted
    * @param o_error               Error
    *
    * @return                      true or false on success or error
    *
    * @author                Ana Moita
    * @version               v2.7.4.5
    * @since                 2018/10/24
    */

    FUNCTION load_hemo_type_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Set Default Hemo types for institution and software
    *
    * @param i_lang                Prefered language ID
    * @param i_id_institution      Institution ID
    * @param i_mkt                 Market ID
    * @param i_vers                Content Version
    * @param i_id_software         Software ID
    * @param o_result_tbl          Number of records inserted
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      Ana Moita
    * @version                     v2.7.4.5
    * @since                       2018/10/24
    */
    -- searcheable loader method signature
    FUNCTION set_hemo_type_instit_soft
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        i_id_content  IN table_varchar DEFAULT table_varchar(),
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION del_hemo_type_instit_soft
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Configure analysis requested by hemo type for institution
    *
    * @param i_lang                Prefered language ID
    * @param i_id_institution      Institution ID
    * @param i_mkt                 Market ID
    * @param i_vers                Content Version
    * @param i_id_software         Software ID
    * @param o_result_tbl          Number of records inserted
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      Ana Moita
    * @version                     v2.7.4.5
    * @since                       2018/10/24
    */

    FUNCTION set_hemo_type_analysis
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        i_id_content  IN table_varchar DEFAULT table_varchar(),
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION del_hemo_type_analysis
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Set Default Questionnaire of Hemo types by institution
    *
    * @param i_lang                Prefered language ID
    * @param i_id_institution      Institution ID
    * @param i_mkt                 Market ID
    * @param i_vers                Content Version
    * @param i_id_software         Software ID
    * @param o_result_tbl          Number of records inserted
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      Ana Moita
    * @version                     v2.7.4.5
    * @since                       2018/10/24
    */

    FUNCTION set_bp_questionnaire_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        i_id_content  IN table_varchar DEFAULT table_varchar(),
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    -- frequent loader method signature

    FUNCTION del_bp_questionnaire_search
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
END pk_blood_product_prm;
/