/*-- Last Change Revision: $Rev: 1938982 $*/
/*-- Last Change by: $Author: adriana.salgueiro $*/
/*-- Date of last change: $Date: 2020-03-09 14:51:37 +0000 (seg, 09 mar 2020) $*/

CREATE OR REPLACE PACKAGE pk_clinicalservice_prm IS
    SUBTYPE t_clob IS CLOB;
    SUBTYPE t_big_char IS VARCHAR2(1000 CHAR);
    SUBTYPE t_med_char IS VARCHAR2(0200 CHAR);
    SUBTYPE t_low_char IS VARCHAR2(0030 CHAR);
    SUBTYPE t_flg_char IS VARCHAR2(0001 CHAR);

    -- content loader method signature
    FUNCTION load_clinical_service_def
    (
        i_lang       IN language.id_language%TYPE,
        i_id_content IN table_varchar DEFAULT table_varchar(),
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    -- searcheable loader method signature

    -- frequent loader method signature

    -- global vars
    g_error         t_big_char;
    g_flg_available t_flg_char;
    g_active        t_flg_char;
    g_version       t_low_char;
    g_func_name     t_med_char;

    g_array_size  NUMBER;
    g_array_size1 NUMBER;
END pk_clinicalservice_prm;
/
