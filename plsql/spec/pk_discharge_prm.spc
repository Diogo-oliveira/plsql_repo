/*-- Last Change Revision: $Rev: 1967175 $*/
/*-- Last Change by: $Author: adriana.salgueiro $*/
/*-- Date of last change: $Date: 2020-10-19 10:18:43 +0100 (seg, 19 out 2020) $*/

CREATE OR REPLACE PACKAGE pk_discharge_prm IS
    SUBTYPE t_clob IS CLOB;
    SUBTYPE t_big_char IS VARCHAR2(1000 CHAR);
    SUBTYPE t_med_char IS VARCHAR2(0200 CHAR);
    SUBTYPE t_low_char IS VARCHAR2(0030 CHAR);
    SUBTYPE t_flg_char IS VARCHAR2(0001 CHAR);

    -- content loader method signature
    FUNCTION ld_disch_instructions_grp_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION ld_disch_instructions_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION load_discharge_dest_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION load_discharge_reason_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    -- searcheable loader method signature
    FUNCTION set_disch_instr_rel_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION del_disch_instr_rel_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_disch_rea_te_inst_search
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

    FUNCTION del_disch_rea_te_inst_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_disch_reas_dest_search
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

    FUNCTION del_disch_reas_dest_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_profile_disch_rea_search
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

    FUNCTION del_profile_disch_rea_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    -- frequent loader method signature
    FUNCTION set_discharge_freq
    (
        i_lang              IN language.id_language%TYPE,
        i_institution       IN institution.id_institution%TYPE,
        i_mkt               IN table_number,
        i_vers              IN table_varchar,
        i_software          IN table_number,
        i_id_content        IN table_varchar DEFAULT table_varchar(),
        i_clin_serv_in      IN table_number,
        i_clin_serv_out     IN clinical_service.id_clinical_service%TYPE,
        i_dep_clin_serv_out IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_result_tbl        OUT NUMBER,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    -- global vars
    g_error         t_big_char;
    g_flg_available t_flg_char;
    g_active        t_flg_char;
    g_version       t_low_char;
    g_func_name     t_med_char;

    g_array_size  NUMBER;
    g_array_size1 NUMBER;
END pk_discharge_prm;
/
