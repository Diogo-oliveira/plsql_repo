/*-- Last Change Revision: $Rev:$*/
/*-- Last Change by: $Author:$*/
/*-- Date of last change: $Date:$*/ 

CREATE OR REPLACE PACKAGE pk_allergy_prm IS
    SUBTYPE t_clob IS CLOB;
    SUBTYPE t_big_char IS VARCHAR2(1000 CHAR);
    SUBTYPE t_med_char IS VARCHAR2(0200 CHAR);
    SUBTYPE t_low_char IS VARCHAR2(0030 CHAR);
    SUBTYPE t_flg_char IS VARCHAR2(0001 CHAR);

    /**
    * Configure allergies per software and institution
    *
    * @param i_lang                   Prefered language ID
    * @param i_mkt                    Market ID
    * @param i_vers                   Content Version
    * @param i_id_software            Software ID
    * @param i_id_content             Product id content
    * @param o_result_tbl             Number of records inserted
    * @param o_error                  Error
    *
    *
    * @return                         true or false on success or error
    *
    * @author                         Adriana Salgueiro
    * @version                        v2.8.2.4
    * @since                          2020/04/15
    */

    /*    FUNCTION set_allergy_inst_soft
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        i_id_content  IN table_varchar DEFAULT table_varchar(),
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;*/

    /**
    * Delete association of allergies to software and institution - allergy_inst_soft
    *
    * @param i_lang                   Prefered language ID
    * @param i_id_institution         Institution ID
    * @param i_id_software            Software ID
    * @param o_result_tbl             Number of records inserted
    * @param o_error                  Error
    *
    *
    * @return                         true or false on success or error
    *
    * @author                         Adriana Salgueiro
    * @version                        v2.8.2.4
    * @since                          2020/04/15
    */

 /*   FUNCTION del_allergy_inst_soft
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;*/

    /**
    * Configure allergies per software, institution and market
    *
    * @param i_lang                   Prefered language ID
    * @param i_mkt                    Market ID
    * @param i_vers                   Content Version
    * @param i_id_software            Software ID
    * @param i_id_content             Product id content
    * @param o_result_tbl             Number of records inserted
    * @param o_error                  Error
    *
    *
    * @return                         true or false on success or error
    *
    * @author                         Adriana Salgueiro
    * @version                        v2.8.2.4
    * @since                          2020/04/15
    */

    FUNCTION set_allergy_inst_soft_market
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
    * Delete association of allergies to software, institution and market - allergy_inst_soft_market
    *
    * @param i_lang                   Prefered language ID
    * @param i_id_institution         Institution ID
    * @param i_id_software            Software ID
    * @param o_result_tbl             Number of records inserted
    * @param o_error                  Error
    *
    *
    * @return                         true or false on success or error
    *
    * @author                         Adriana Salgueiro
    * @version                        v2.8.2.4
    * @since                          2020/04/15
    */

    FUNCTION del_allergy_inst_soft_market
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

END pk_allergy_prm;
/