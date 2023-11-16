/*-- Last Change Revision: $Rev: 1469740 $*/
/*-- Last Change by: $Author: rui.gomes $*/
/*-- Date of last change: $Date: 2013-05-21 16:52:14 +0100 (ter, 21 mai 2013) $*/

CREATE OR REPLACE PACKAGE BODY pk_speciality_prm IS
    -- Package info
    g_package_owner t_low_char := 'ALERT';
    g_package_name  t_low_char := 'PK_speciality_prm';

    -- Private Methods

    -- content loader method
    FUNCTION load_speciality_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_code_translation translation.code_translation%TYPE := upper('speciality.code_speciality.');
    BEGIN
        g_func_name := upper('load_speciality_def');
        INSERT INTO speciality
            (id_speciality, code_speciality, flg_available, adw_last_update, id_content)
            SELECT seq_speciality.nextval,
                   l_code_translation || seq_speciality.currval,
                   g_flg_available,
                   SYSDATE,
                   id_content
              FROM (SELECT s.id_speciality, s.id_content
                      FROM alert_default.speciality s
                     WHERE s.flg_available = g_flg_available
                       AND NOT EXISTS (SELECT 0
                              FROM speciality dest_tbl
                             WHERE dest_tbl.id_content = s.id_content
                               AND dest_tbl.flg_available = g_flg_available)) def_data;
        o_result_tbl := SQL%ROWCOUNT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
    END load_speciality_def;
    -- searcheable loader method

-- frequent loader method

-- global vars
BEGIN
    -- Initializes log context

    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_flg_available := pk_alert_constant.g_available;
    g_active        := pk_alert_constant.g_active;

    g_array_size  := 100;
    g_array_size1 := 10000;
END pk_speciality_prm;
/
