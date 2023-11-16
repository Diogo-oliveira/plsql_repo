CREATE OR REPLACE PACKAGE pk_sig IS

    FUNCTION get_address(i_professional IN NUMBER) RETURN VARCHAR2;

    --*******************************************************
    PROCEDURE get_prof_sigs_base
    (
        i_lang     IN NUMBER,
        i_prof     IN profissional,
        i_flg_type IN VARCHAR2,
        o_result   OUT pk_types.cursor_type
    );

    --*******************************************************
    PROCEDURE get_prof_sigs_digital
    (
        i_lang   IN NUMBER,
        i_prof   IN profissional,
        o_result OUT pk_types.cursor_type
    );

    --*******************************************************
    PROCEDURE get_prof_sigs_electronic
    (
        i_lang   IN NUMBER,
        i_prof   IN profissional,
        o_result OUT pk_types.cursor_type
    );

    --*******************************************************
    PROCEDURE get_prof_sigs_list
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        o_digital    OUT pk_types.cursor_type,
        o_electronic OUT pk_types.cursor_type
    );

    PROCEDURE upd_prof_sig_base
    (
        i_prof     IN profissional,
        i_flg_type IN VARCHAR2,
        i_id_prof  IN NUMBER,
        i_id_sig   IN NUMBER,
        i_name     IN VARCHAR2,
        i_image    IN BLOB
    );

    -- ****************************
    PROCEDURE upd_sig_electronic
    (
        i_prof    IN profissional,
        i_id_prof IN NUMBER,
        i_id_sig  IN NUMBER,
        i_name    IN VARCHAR2,
        i_image   IN BLOB
    );

    PROCEDURE upd_sig_digital
    (
        i_prof    IN profissional,
        i_id_prof IN NUMBER,
        i_id_sig  IN NUMBER,
        i_name    IN VARCHAR2,
        i_image   IN BLOB
    );

    PROCEDURE set_active_sig
    (
        i_prof    IN profissional,
        i_id_prof IN NUMBER,
        i_id_sig  IN NUMBER
    );

    FUNCTION check_if_active_exist(i_id_prof IN NUMBER) RETURN NUMBER;


    PROCEDURE init_par_sig
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_keys  IN table_varchar DEFAULT NULL,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    );

    --********************************************
    FUNCTION get_sig_info
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        --i_episode        IN episode.id_episode%TYPE,
        --i_patient        IN patient.id_patient%TYPE,
        i_action         IN NUMBER, -- edit, new, submit
        i_root_name      IN VARCHAR2, -- root of dynamic screen
        i_curr_component IN NUMBER,
        i_tbl_id_pk      IN table_number, -- id necessary for identifying pk for editing
        i_tbl_mkt_rel    IN table_number, -- components needed for default/edit
        i_value          IN table_table_varchar,
        i_value_clob     IN table_clob,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value;

    FUNCTION get_sig_add_values
    (
        i_lang IN NUMBER,
        i_prof IN profissional,
        --i_id_episode IN NUMBER,
        --i_id_patient IN NUMBER,
        i_root_name IN VARCHAR2
    ) RETURN t_tbl_ds_get_value;

    FUNCTION get_sig_edit_values
    (
        i_lang IN NUMBER,
        i_prof IN profissional,
        --i_id_episode IN NUMBER,
        --i_id_patient IN NUMBER,
        i_id_sig    IN NUMBER,
        i_root_name IN VARCHAR2
    ) RETURN t_tbl_ds_get_value;

    FUNCTION cancel_signature
    (
        i_lang     IN NUMBER,
        i_epis_sig IN table_number,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE save_sig_base
    (
        i_lang IN NUMBER,
        i_prof IN profissional,
        --i_id_episode    IN number,
        --i_id_patient    IN number,
        i_mode        IN VARCHAR2,
        i_epis_sig    IN NUMBER,
        i_tbl_mkt_rel IN table_number,
        i_value       IN table_table_varchar,
        i_image       IN BLOB
    );

    --***************************
    FUNCTION save_sig
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_id_episode  IN NUMBER,
        i_id_patient  IN NUMBER,
        i_epis_sig    IN NUMBER,
        i_tbl_mkt_rel IN table_number,
        i_value       IN table_table_varchar,
        i_image       IN BLOB,
        --o_result      OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

END pk_sig;
