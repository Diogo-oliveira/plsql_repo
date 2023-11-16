/*-- Last Change Revision: $Rev: 1945396 $*/
/*-- Last Change by: $Author: adriana.salgueiro $*/
/*-- Date of last change: $Date: 2020-04-14 10:57:55 +0100 (ter, 14 abr 2020) $*/

CREATE OR REPLACE PACKAGE pk_doc_area_prm IS
    SUBTYPE t_clob IS CLOB;
    SUBTYPE t_big_char IS VARCHAR2(1000 CHAR);
    SUBTYPE t_med_char IS VARCHAR2(0200 CHAR);
    SUBTYPE t_low_char IS VARCHAR2(0030 CHAR);
    SUBTYPE t_flg_char IS VARCHAR2(0001 CHAR);

    -- content loader method signature

    -- searcheable loader method signature
    FUNCTION set_doc_area_is_search
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

    FUNCTION del_doc_area_is_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set Default Dashboard areas configuration
    *
    * @param i_lang                Prefered language ID
    * @param o_result_tbl          Number of records inserted
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.1
    * @since                       2013/05/15
    ********************************************************************************************/
    FUNCTION set_dash_da_mkt_search
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
    /********************************************************************************************
    * Set Default Dashboard areas configuration
    *
    * @param i_lang                Prefered language ID
    * @param o_result_tbl          Number of records inserted
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.1
    * @since                       2013/05/15
    ********************************************************************************************/
    FUNCTION set_dash_da_inst_search
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

    FUNCTION del_dash_da_inst_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Load doc_category from default table
    *
    * @param i_lang                   Prefered language ID
    * @param o_result_tbl          Number of records inserted
    * @param o_error                 Error
    *
    *
    * @return                       true or false on success or error
    *
    * @author                      Adriana Salgueiro
    * @version                     v2.8.0.0
    * @since                        2019/07/08
    */

    FUNCTION load_doc_category_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Set Default Doc category for institution and software
    *
    * @param i_lang                    Prefered language ID
    * @param i_id_institution      Institution ID
    * @param i_mkt                    Market ID
    * @param i_vers                    Content Version
    * @param i_id_software         Software ID
    * @param o_result_tbl           Number of records inserted
    * @param o_error                  Error
    *
    *
    * @return                       true or false on success or error
    *
    * @author                      Adriana Salgueiro
    * @version                     v2.7.4.5
    * @since                        2019/07/05
    */

    FUNCTION set_doc_cat_inst_soft
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

    /**
    * Configure doc_areas requested associated to categories for institution
    *
    * @param i_lang                     Prefered language ID
    * @param i_id_institution       Institution ID
    * @param i_mkt                     Market ID
    * @param i_vers                     Content Version
    * @param i_id_software          Software ID
    * @param o_result_tbl            Number of records inserted
    * @param o_error                   Error
    *
    *
    * @return                       true or false on success or error
    *
    * @author                      Adriana Salgueiro
    * @version                     v2.8.0.0
    * @since                        2019/07/05
    */

    FUNCTION set_doc_cat_area_inst_soft
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

    /**
    * Delete Doc category per institution and software
    *
    * @param i_lang                     Prefered language ID
    * @param i_id_institution       Institution ID
    * @param i_id_software          Software ID
    * @param o_result_tbl            Number of records inserted
    * @param o_error                   Error
    *
    *
    * @return                       true or false on success or error
    *
    * @author                      Adriana Salgueiro
    * @version                     v2.8.0.0
    * @since                        2019/07/09
    */

    FUNCTION del_doc_cat_inst_soft
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Delete Doc category associated to areas per institution and software
    *
    * @param i_lang                     Prefered language ID
    * @param i_id_institution       Institution ID
    * @param i_id_software          Software ID
    * @param o_result_tbl            Number of records inserted
    * @param o_error                   Error
    *
    *
    * @return                       true or false on success or error
    *
    * @author                      Adriana Salgueiro
    * @version                     v2.8.0.0
    * @since                        2019/07/09
    */

    FUNCTION del_doc_cat_area_inst_soft
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
END pk_doc_area_prm;
/