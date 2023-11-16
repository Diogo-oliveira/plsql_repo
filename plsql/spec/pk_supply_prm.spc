/*-- Last Change Revision: $Rev: 1947312 $*/
/*-- Last Change by: $Author: adriana.salgueiro $*/
/*-- Date of last change: $Date: 2020-04-27 12:02:07 +0100 (seg, 27 abr 2020) $*/

CREATE OR REPLACE PACKAGE pk_supply_prm IS
    SUBTYPE t_clob IS CLOB;
    SUBTYPE t_big_char IS VARCHAR2(1000 CHAR);
    SUBTYPE t_med_char IS VARCHAR2(0200 CHAR);
    SUBTYPE t_low_char IS VARCHAR2(0030 CHAR);
    SUBTYPE t_flg_char IS VARCHAR2(0001 CHAR);

    -- support function

    /**
    * Get id context per flag context
    *
    * @param i_lang                      Prefered language ID
    * @param i_flg_context_def      Flag context alert default
    * @param i_id_context_def       ID context alert default
    * @param i_id_institution        Institution ID
    * @param i_id_software           Software ID
    *
    *
    * @return                       id_context
    *
    * @updateauthor            Adriana Salgueiro
    * @updateversion           v2.8.1.0
    * @updated                    2019/02/06
    */

    FUNCTION get_supply_context
    (
        i_lang            IN NUMBER,
        i_flg_context_def IN supply_context.flg_context%TYPE,
        i_id_context_def  IN supply_context.id_context%TYPE,
        i_id_institution  IN NUMBER,
        i_id_software     IN NUMBER 
	) RETURN VARCHAR;

    -- content loader method signature
    FUNCTION load_supplies_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION load_supply_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION load_supply_type_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Set association between supplies and interventions/medication/icnp/labtests/exams
    *
    * @param i_lang                     Prefered language ID
    * @param i_id_institution       Institution ID
    * @param i_mkt                     market id
    * @param i_vers                     version of content
    * @param i_id_software          Software ID
    * @param o_result_tbl            Number of records inserted
    * @param o_error                   Error
    *
    *
    * @return                       true or false on success or error
    *
    * @updateauthor            Adriana Salgueiro
    * @updateversion           v2.8.1.0
    * @updated                    2019/02/06
    */

    FUNCTION set_supply_context_search
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

    FUNCTION del_supply_context_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_supply_loc_default_search
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

    FUNCTION del_supply_loc_default_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_supply_reason_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_supply_relation_search
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

    FUNCTION set_supply_soft_inst_search
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

    FUNCTION del_supply_soft_inst_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_supply_sup_area_search
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

    FUNCTION del_supply_sup_area_search
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
END pk_supply_prm;
/