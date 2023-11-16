/*-- Last Change Revision: $Rev: 1940429 $*/
/*-- Last Change by: $Author: adriana.salgueiro $*/
/*-- Date of last change: $Date: 2020-03-16 10:41:00 +0000 (seg, 16 mar 2020) $*/

CREATE OR REPLACE PACKAGE pk_habit_PRM is
    SUBTYPE t_clob IS CLOB;
    SUBTYPE t_big_char IS VARCHAR2(1000 CHAR);
    SUBTYPE t_med_char IS VARCHAR2(0200 CHAR);
    SUBTYPE t_low_char IS VARCHAR2(0030 CHAR);
    SUBTYPE t_flg_char IS VARCHAR2(0001 CHAR);

    /**
    * Insert new habit
    *
    * @param i_lang                     Prefered language ID
    * @param o_result_tbl             Number of records inserted
    * @param o_error                    Error
    *
    *
    * @return                       true or false on success or error
    */

    -- content loader method signature
    FUNCTION load_habit_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Insert new habit characterizations
    *
    * @param i_lang                     Prefered language ID
    * @param o_result_tbl             Number of records inserted
    * @param o_error                    Error
    *
    *
    * @return                       true or false on success or error
    */

    FUNCTION ld_habit_characterization_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
	
    /**
    * Configure habits per institution
    *
    * @param i_lang                        Prefered language ID
    * @param i_mkt                        Market ID
    * @param i_vers                        Content Version
    * @param i_id_software              Software ID
    * @param i_id_content               Habit ID Content
    * @param o_result_tbl                Number of records inserted
    * @param o_error                       Error
    *
    *
    * @return                       true or false on success or error
    */

    -- searcheable loader method signature

    FUNCTION set_habit_inst_search
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
    
    FUNCTION del_habit_inst_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Inserts habits characterization relation
    *
    * @param i_lang                        Prefered language ID
    * @param i_mkt                        Market ID
    * @param i_vers                        Content Version
    * @param i_id_software              Software ID
    * @param i_id_content               Habit ID Content
    * @param o_result_tbl                Number of records inserted
    * @param o_error                       Error
    *
    *
    * @return                       true or false on success or error
    */

    FUNCTION set_habit_charact_rel_search
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
    
    FUNCTION del_habit_charact_rel_search
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
END pk_habit_PRM;
/
