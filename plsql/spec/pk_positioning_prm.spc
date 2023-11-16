/*-- Last Change Revision: $Rev: 1941671 $*/
/*-- Last Change by: $Author: adriana.salgueiro $*/
/*-- Date of last change: $Date: 2020-03-20 10:26:16 +0000 (sex, 20 mar 2020) $*/

CREATE OR REPLACE PACKAGE pk_positioning_prm IS
    SUBTYPE t_clob IS CLOB;
    SUBTYPE t_big_char IS VARCHAR2(1000 CHAR);
    SUBTYPE t_med_char IS VARCHAR2(0200 CHAR);
    SUBTYPE t_low_char IS VARCHAR2(0030 CHAR);
    SUBTYPE t_flg_char IS VARCHAR2(0001 CHAR);

    /**
    * Load positioning 
    *
    * @param i_lang                        Prefered language ID
    * @param o_result_tbl                Number of records inserted
    * @param o_error                       Error
    *
    *
    * @return                                    true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.1
    * @since                       2013/03/28
    */
    -- content loader method signature
    FUNCTION load_positioning
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    -- searcheable loader method signature
    /**
    *Set Default Positionings
    *
    * @param i_lang                     Prefered language ID
    * @param i_institution             Institution ID
    * @param i_mkt                      Market ID
    * @param i_vers                     Content Version
    * @param i_id_software              Software ID
    * @param i_id_content               positioning id content
    * @param o_result_tbl               Number of records inserted
    * @param o_error                    Error
    *
    * @return                      true or false on success or error
    *
    * @author                      Adriana Salgueiro
    * @version                     2.8.1.0
    * @since                        2020/03/16
    */

    FUNCTION set_positioning_search
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
    *Delete Default Positionings
    *
    * @param i_lang                     Prefered language ID
    * @param i_institution             Intitution ID
    * @param i_id_software              Software ID
    * @param o_result_tbl               Number of records inserted
    *
    * @return                      true or false on success or error
    *
    * @author                      Adriana Salgueiro
    * @version                     2.8.1.0
    * @since                        2020/03/16
    */

    FUNCTION del_positioning_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *Load Positionings relation
    *
    * @param i_lang                        Prefered language ID
    * @param o_result_tbl                Number of records inserted
    * @param o_error                       Error
    *
    * @return                      true or false on success or error
    *
    * @author                      Adriana Salgueiro
    * @version                     2.8.1.0
    * @since                        2020/03/18
    */

    FUNCTION load_sr_posit_rel
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    -- global vars
    g_error         t_big_char;
    g_flg_available t_flg_char;
    g_active        t_flg_char;
    g_version       t_low_char;
    g_func_name     t_med_char;

    g_array_size  NUMBER;
    g_array_size1 NUMBER;
END pk_positioning_prm;
/
