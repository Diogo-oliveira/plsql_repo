/*-- Last Change Revision: $Rev: 1469740 $*/
/*-- Last Change by: $Author: rui.gomes $*/
/*-- Date of last change: $Date: 2013-05-21 16:52:14 +0100 (ter, 21 mai 2013) $*/

CREATE OR REPLACE PACKAGE BODY pk_appointment_prm IS
    -- Package info
    g_package_owner t_low_char := 'alert';
    g_package_name  t_low_char := 'PK_appointment_prm';

    --g_table_name t_med_char;
    -- Private Methods

    -- content loader method
    FUNCTION load_appointment_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_code_translation translation.code_translation%TYPE := upper('appointment.code_appointment.');
    BEGIN
        g_func_name := upper('load_appointment_def');
        INSERT INTO appointment
            (id_appointment, id_sch_event, id_clinical_service, flg_available, code_appointment)
            SELECT 'APP.' || to_char(se.id_sch_event) || '.' || to_char(cs.id_clinical_service),
                   se.id_sch_event,
                   cs.id_clinical_service,
                   g_flg_available,
                   l_code_translation ||
                   to_char('APP.' || to_char(se.id_sch_event) || '.' || to_char(cs.id_clinical_service))
              FROM sch_event se
              JOIN sch_dep_type sdt
                ON se.dep_type = sdt.dep_type
             CROSS JOIN clinical_service cs
             WHERE sdt.dep_type_group = 'C'
               AND se.flg_available = g_flg_available
               AND sdt.flg_available = g_flg_available
               AND cs.flg_available = g_flg_available
               AND NOT EXISTS (SELECT 1
                      FROM appointment a
                     WHERE a.id_clinical_service = cs.id_clinical_service
                       AND a.id_sch_event = se.id_sch_event);
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
    END load_appointment_def;
    -- searcheable loader method

    -- frequent loader method

    --translation methods
    FUNCTION set_appointments_transl
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        o_result_tbl := 0;
        RETURN pk_default_content.set_appointments_transl(i_lang                => i_lang,
                                                          i_id_clinical_service => NULL,
                                                          o_error               => o_error);
    END set_appointments_transl;

-- global vars
BEGIN
    -- Initializes log context

    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_flg_available := pk_alert_constant.g_available;
    g_active        := pk_alert_constant.g_active;

    g_array_size  := 100;
    g_array_size1 := 10000;
END pk_appointment_prm;
/