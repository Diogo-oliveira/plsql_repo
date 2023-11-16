/*-- Last Change Revision: $Rev:$*/
/*-- Last Change by: $Author:$*/
/*-- Date of last change: $Date:$*/

CREATE OR REPLACE PACKAGE pk_reports_prm IS
    SUBTYPE t_clob IS CLOB;
    SUBTYPE t_big_char IS VARCHAR2(1000 CHAR);
    SUBTYPE t_med_char IS VARCHAR2(0200 CHAR);
    SUBTYPE t_low_char IS VARCHAR2(0030 CHAR);
    SUBTYPE t_flg_char IS VARCHAR2(0001 CHAR);

    /**
    * Configure reports per institution
    *
    * @param i_lang                              Prefered language ID
    * @param i_institution                     Institution ID
    * @param i_mkt                              Market ID (check content_market_version table)
    * @param i_vers                              Content Version (check content_market_version table)
    * @param i_software                        Software ID
    * @param o_result_tbl                     Number of records inserted
    * @param o_error                            Error
    *
    *
    * @return                       true or false on success or error
    *
    * @author                      Adriana Salgueiro
    * @version                     v2.8.0.0
    * @since                        2019/09/10
    */


    FUNCTION set_rep_section_cfg_inst_soft
    (
        i_lang IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt IN table_number,
        i_vers IN table_varchar,
        i_software IN table_number,
        o_result_tbl OUT NUMBER,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Delete reports per institution
    *
    * @param i_lang                              Prefered language ID
    * @param i_institution                     Institution ID
    * @param i_software                        Software ID
    * @param o_result_tbl                     Number of records inserted
    * @param o_error                            Error
    *
    *
    * @return                       true or false on success or error
    *
    * @author                      Adriana Salgueiro
    * @version                     v2.8.0.0
    * @since                        2019/09/10
    */

    FUNCTION del_rep_section_cfg_inst_soft
    (
        i_lang IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software IN table_number,
        o_result_tbl OUT NUMBER,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    -- global vars
    g_error         t_big_char;
    g_flg_available t_flg_char;
    g_active        t_flg_char;
    g_version       t_low_char;
    g_func_name     t_med_char;

    g_array_size  NUMBER;
    g_array_size1 NUMBER;

END pk_reports_prm;
/
