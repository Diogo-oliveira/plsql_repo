CREATE OR REPLACE PACKAGE BODY pk_alerts_ux IS

    g_owner   VARCHAR2(0200 CHAR) := 'ALERT';
    g_package VARCHAR2(0200 CHAR) := 'PK_ALERTS_UX';

    FUNCTION set_alert_read
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional,
        i_sys_alert_det IN NUMBER,
        i_sys_alert     IN NUMBER,
        i_test          IN VARCHAR2,
        o_flg_show      OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_msg_text      OUT VARCHAR2,
        o_button        OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_alerts.set_alert_read(i_lang          => i_lang,
                                        i_prof          => i_prof,
                                        i_sys_alert_det => i_sys_alert_det,
                                        i_sys_alert     => i_sys_alert,
                                        i_test          => i_test,
                                        o_flg_show      => o_flg_show,
                                        o_msg_title     => o_msg_title,
                                        o_msg_text      => o_msg_text,
                                        o_button        => o_button,
                                        o_error         => o_error);
    
    END set_alert_read;

    FUNCTION set_selected_alert_read
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional,
        i_sys_alert_det IN table_number,
        i_sys_alert     IN table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_alerts.set_selected_alert_read(i_lang          => i_lang,
                                                 i_prof          => i_prof,
                                                 i_sys_alert_det => i_sys_alert_det,
                                                 i_sys_alert     => i_sys_alert,
                                                 o_error         => o_error);
    
    END set_selected_alert_read;

    FUNCTION set_all_alert_read
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_alerts.set_all_alert_read(i_lang, i_prof, o_error);
    
    END set_all_alert_read;

    FUNCTION get_alert_actions
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_alert   IN NUMBER,
        i_subject    IN varchar2,
        i_from_state IN varchar2,
        o_actions    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_alert NUMBER;
        k_nothing_selected CONSTANT NUMBER := -1;
    BEGIN
    
        l_id_alert := i_id_alert;
        IF l_id_alert = k_nothing_selected
        THEN
            l_id_alert := NULL;
        END IF;
    
        RETURN pk_alerts.get_alert_actions(i_lang       => i_lang,
                                           i_prof       => i_prof,
                                           i_id_alert   => l_id_alert,
                                           i_subject    => table_varchar(i_subject),
                                           i_from_state => table_varchar(i_from_state),
                                           o_actions    => o_actions,
                                           o_error      => o_error);
    
    END get_alert_actions;
    
        -- **********************************************
    FUNCTION set_alert_read_x_days
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN BOOLEAN is
    begin
      
        RETURN pk_alerts.set_alert_read_x_days(i_lang, i_prof, o_error);
    
    end set_alert_read_x_days;

    FUNCTION get_prof_alerts_count
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        o_num_alerts OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_alerts.get_prof_alerts_count(i_lang       => i_lang,
                                               i_prof       => i_prof,
                                               o_num_alerts => o_num_alerts,
                                               o_error      => o_error);
    
    END get_prof_alerts_count;

    PROCEDURE inicialize IS
    BEGIN
    pk_alertlog.who_am_i(g_owner, g_package);
    pk_alertlog.log_init(object_name => g_package, owner => g_owner);
    END inicialize;

BEGIN
    -- Log initialization.
    inicialize();
END pk_alerts_ux;
