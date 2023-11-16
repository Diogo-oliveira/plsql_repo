CREATE OR REPLACE PACKAGE pk_sample_text_ux IS

    FUNCTION set_sample_text_prof
    (
        i_lang             IN NUMBER,
        i_id_sample_text   IN NUMBER,
        i_sample_text_type IN NUMBER,
        i_prof             IN profissional,
        i_title            IN VARCHAR2,
        i_text             IN VARCHAR2,
        i_rank             IN NUMBER,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_sample_text_prof
    (
        i_lang        IN NUMBER,
        i_sample_text IN NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_sample_text_type_list
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION save_dyn_sample_text
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_sample_text_prof     IN sample_text_prof.id_sample_text_prof%TYPE,
        i_tbl_ds_internal_name IN table_varchar,
        i_real_val             IN table_table_varchar,
        i_value                IN table_table_varchar,
        i_value_clob           IN table_table_clob,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

END pk_sample_text_ux;
