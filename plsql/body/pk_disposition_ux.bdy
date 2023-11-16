/*-- Last Change Revision: $Rev: 2026981 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:38 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_disposition_ux IS
    /**********************************************************************************************
    * Returns death event characterization data
    *
    * @param i_lang                ID language
    * @param i_prof                ID of professional
    *
    * @param o_death_evet          Content cursor
    * @param o_error               Error message
    *
    * @return                      True on success, false otherwise
    *                        
    * @author                      Sergio Dias
    * @version                     2.6.3.15
    * @since                       Apr-3-2014
    **********************************************************************************************/
    FUNCTION get_death_event
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_death_event OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_DEATH_EVENT';
    BEGIN
    
        g_error := 'CALL PK_DISPOSITION.GET_DEATH_EVENT';
        pk_alertlog.log_debug(g_error);
        RETURN pk_disposition.get_death_event(i_lang        => i_lang,
                                              i_prof        => i_prof,
                                              o_death_event => o_death_event,
                                              o_error       => o_error);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_death_event);
            RETURN FALSE;
    END get_death_event;

    /**********************************************************************************************
    * Get discharge shortcut
    *
    * @param i_lang                ID language
    * @param i_prof                ID of professional
    * @param o_discharge_shortcut  Discharge shortcut
    *
    * @return                      True on success, false otherwise
    *                        
    * @author                      Alexandre Santos
    * @version                     2.6.4
    * @since                       Dec-15-2014
    **********************************************************************************************/
    FUNCTION get_discharge_shortcut
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        o_discharge_shortcut OUT sys_shortcut.id_sys_shortcut%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(32 CHAR) := 'GET_DISCHARGE_SHORTCUT';
    BEGIN
        o_discharge_shortcut := pk_disposition.get_discharge_shortcut(i_lang => i_lang, i_prof => i_prof);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_discharge_shortcut;

    /**********************************************************************************************
    * Returns 
    *
    * @param i_lang                ID language
    * @param i_prof                ID of professional
    * @param i_discharge           ID of discharge
    * @param i_episode             ID of episode
    * @param i_pat_pregnancy       ID of pat_pregnancy
    * @param i_flg_condition       Flag of newborn condition
    *
    * @param o_error               Error message
    *
    * @return                      True on success, false otherwise
    *                        
    * @author                      Vanessa Barsottelli
    * @version                     2.7.0
    * @since                       10-11-2016
    **********************************************************************************************/
    FUNCTION set_newborn_discharge
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_discharge     IN discharge.id_discharge%TYPE,
        i_episode       IN table_number,
        i_pat_pregnancy IN table_number,
        i_flg_condition IN table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_NEWBORN_DISCHARGE';
    BEGIN
        g_error := 'CALL PK_DISPOSITION.SET_NEWBORN_DISCHARGE';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_disposition.set_newborn_discharge(i_lang          => i_lang,
                                                    i_prof          => i_prof,
                                                    i_discharge     => i_discharge,
                                                    i_episode       => i_episode,
                                                    i_pat_pregnancy => i_pat_pregnancy,
                                                    i_flg_condition => i_flg_condition,
                                                    o_error         => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            ROLLBACK;
            RETURN FALSE;
    END set_newborn_discharge;

    FUNCTION cancel_disposition
    (
        i_lang              IN language.id_language%TYPE,
        i_id_discharge      IN discharge.id_discharge%TYPE,
        i_id_discharge_hist IN discharge_hist.id_discharge_hist%TYPE,
        i_prof              IN profissional,
        i_notes_cancel      IN discharge.notes_cancel%TYPE,
        i_id_cancel_reason  IN cancel_reason.id_cancel_reason%TYPE,
        o_flg_show          OUT VARCHAR2,
        o_msg               OUT VARCHAR2,
        o_msg_title         OUT VARCHAR2,
        o_button            OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
		l_bool boolean;
    BEGIN
    
        l_bool := pk_disposition.cancel_disposition_ux(i_lang              => i_lang,
                                                    i_id_discharge      => i_id_discharge,
                                                    i_id_discharge_hist => i_id_discharge_hist,
                                                    i_prof              => i_prof,
                                                    i_notes_cancel      => i_notes_cancel,
                                                    i_id_cancel_reason  => i_id_cancel_reason,
                                                    o_flg_show          => o_flg_show,
                                                    o_msg               => o_msg,
                                                    o_msg_title         => o_msg_title,
                                                    o_button            => o_button,
                                                    o_error             => o_error);
    
        IF l_bool
        THEN
        COMMIT;
		else
			rollback;
		end if;
    
        RETURN l_bool;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => g_package_name,
                                              i_function => 'CANCEL_DISPOSITION',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            ROLLBACK;
            RETURN FALSE;
    END cancel_disposition;

BEGIN

    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);

END pk_disposition_ux;
/
