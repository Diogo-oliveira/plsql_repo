CREATE OR REPLACE PACKAGE pk_template_prm IS
    SUBTYPE t_clob IS CLOB;
    SUBTYPE t_big_char IS VARCHAR2(1000 CHAR);
    SUBTYPE t_med_char IS VARCHAR2(0200 CHAR);
    SUBTYPE t_low_char IS VARCHAR2(0030 CHAR);
    SUBTYPE t_flg_char IS VARCHAR2(0001 CHAR);
    FUNCTION get_context2_search
    (
        i_lang            NUMBER,
        flg_context       VARCHAR,
        i_id_context2_def IN doc_template_context.id_context%TYPE
    ) RETURN NUMBER;

    FUNCTION
    
     get_context_search
    (
        i_lang           NUMBER,
        flg_context      VARCHAR,
        i_id_context_def IN doc_template_context.id_context%TYPE
    ) RETURN NUMBER;
    -- content loader method signature
    /*
    Doc_Template_Soft_Inst is deprecated (Ana Moita:02/11/2018)
        -- searcheable loader method signature
        FUNCTION set_inst_doc_template_si
        (
            i_lang        IN language.id_language%TYPE,
            i_institution IN institution.id_institution%TYPE,
            i_mkt         IN table_number,
            i_vers        IN table_varchar,
            i_software    IN table_number,
            o_result_tbl  OUT NUMBER,
            o_error       OUT t_error_out
        ) RETURN BOOLEAN;*/

    FUNCTION set_doc_template_cont_search
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

    FUNCTION del_doc_template_cont_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    -- frequent loader method signature
    FUNCTION set_template_freq
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
END pk_template_prm;
/
