CREATE OR REPLACE PACKAGE pk_data_access_cdoc_aux IS

    FUNCTION get_cols_inp_base RETURN table_varchar;

    FUNCTION get_from_inp_base RETURN table_varchar;

    PROCEDURE print_cols_inp_base;
    PROCEDURE print_from_inp_base;
    PROCEDURE print_all_inp_base;

    FUNCTION get_cols_outp_base RETURN table_varchar;
    FUNCTION get_from_outp_base RETURN table_varchar;

    PROCEDURE print_cols_outp_base;
    PROCEDURE print_from_outp_base;
    PROCEDURE print_all_outp_base;

    FUNCTION get_cols_edis_base RETURN table_varchar;
    FUNCTION get_from_edis_base RETURN table_varchar;

    PROCEDURE print_cols_edis_base;
    PROCEDURE print_from_edis_base;
    PROCEDURE print_all_edis_base;

    FUNCTION get_cols_consult_base RETURN table_varchar;
    FUNCTION get_from_consult_base RETURN table_varchar;

    PROCEDURE print_cols_consult_base;
    PROCEDURE print_from_consult_base;
    PROCEDURE print_all_consult_base;

    FUNCTION get_cols_transfer_base RETURN table_varchar;
    FUNCTION get_from_transfer_base RETURN table_varchar;

    PROCEDURE print_cols_transfer_base;
    PROCEDURE print_from_transfer_base;
    PROCEDURE print_all_transfer_base;

END pk_data_access_cdoc_aux;
