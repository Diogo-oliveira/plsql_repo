CREATE OR REPLACE PACKAGE pk_sig_ux IS

    FUNCTION set_active_sig
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_id_prof IN NUMBER,
        i_id_sig  IN NUMBER,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    --***************************
    FUNCTION save_sig
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_epis_sig    IN NUMBER,
        i_tbl_mkt_rel IN table_number,
        i_value       IN table_table_varchar,
        i_image       IN BLOB,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    --********************
    FUNCTION cancel_signature
    (
        i_lang     IN NUMBER,
        i_prof     IN profissional,
        i_epis_sig IN table_number,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

END pk_sig_ux;
