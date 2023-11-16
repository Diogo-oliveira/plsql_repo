/*-- Last Change Revision: $Rev: 690743 $*/
/*-- Last Change by: $Author: pedro.carneiro $*/
/*-- Date of last change: $Date: 2010-09-22 10:34:29 +0100 (qua, 22 set 2010) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_health_program IS

    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);
    g_exception EXCEPTION;

    /**
    * Retrieve available health programs,
    * signaling those which the patient can be subscribed to.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param o_avail        cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.1.1
    * @since                2010/09/22
    */
    FUNCTION get_available_hpgs
    (
        i_lang    IN LANGUAGE.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_avail   OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_AVAILABLE_HPGS';
    BEGIN
        g_error := 'CALL pk_health_program.get_available_hpgs';
        IF NOT pk_health_program.get_available_hpgs(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_patient => i_patient,
                                                    o_avail   => o_avail,
                                                    o_error   => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_avail);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_avail);
            RETURN FALSE;
    END get_available_hpgs;

    /**
    * Creates or edits a patient's health program inscription.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_health_program health program identifier
    * @param i_monitor_loc  monitor location flag
    * @param i_dt_begin     begin date
    * @param i_dt_end       end date
    * @param i_notes        record notes
    * @param i_action       action performed
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.1.1
    * @since                2010/09/22
    */
    FUNCTION set_pat_hpg
    (
        i_lang           IN LANGUAGE.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_health_program IN health_program.id_health_program%TYPE,
        i_monitor_loc    IN pat_health_program.flg_monitor_loc%TYPE,
        i_dt_begin       IN VARCHAR2,
        i_dt_end         IN VARCHAR2,
        i_notes          IN pat_health_program.notes%TYPE,
        i_action         IN action.internal_name%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_PAT_HPG';
    BEGIN
        g_error := 'CALL pk_health_program.set_pat_hpg';
        IF NOT pk_health_program.set_pat_hpg(i_lang           => i_lang,
                                             i_prof           => i_prof,
                                             i_patient        => i_patient,
                                             i_health_program => i_health_program,
                                             i_monitor_loc    => i_monitor_loc,
                                             i_dt_begin       => i_dt_begin,
                                             i_dt_end         => i_dt_end,
                                             i_notes          => i_notes,
                                             i_action         => i_action,
                                             o_error          => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_pat_hpg;

    /**
    * Cancels a patient's health program inscription.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_pat_hpg      pat health program identifier
    * @param i_motive       cancellation motive
    * @param i_notes        cancellation notes
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.1.1
    * @since                2010/09/22
    */
    FUNCTION cancel_pat_hpg
    (
        i_lang    IN LANGUAGE.id_language%TYPE,
        i_prof    IN profissional,
        i_pat_hpg IN pat_health_program.id_pat_health_program%TYPE,
        i_motive  IN pat_health_program.id_cancel_reason%TYPE,
        i_notes   IN pat_health_program.cancel_notes%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'CANCEL_PAT_HPG';
    BEGIN
        g_error := 'CALL pk_health_program.cancel_pat_hpg';
        IF NOT pk_health_program.cancel_pat_hpg(i_lang    => i_lang,
                                                i_prof    => i_prof,
                                                i_pat_hpg => i_pat_hpg,
                                                i_motive  => i_motive,
                                                i_notes   => i_notes,
                                                o_error   => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END cancel_pat_hpg;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    pk_alertlog.log_init(object_name => g_package);
END pk_api_health_program;
/
