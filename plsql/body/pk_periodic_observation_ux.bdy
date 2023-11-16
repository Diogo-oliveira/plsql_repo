/*-- Last Change Revision: $Rev: 2027481 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:21 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE BODY pk_periodic_observation_ux IS

    g_error   VARCHAR2(1000 CHAR);
    g_package VARCHAR2(32 CHAR);
    g_owner   VARCHAR2(32 CHAR);
    g_exception EXCEPTION;

    FUNCTION get_periodic_param_type
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_param OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_PERIODIC_PARAM_TYPE';
    BEGIN
        g_error := 'call pk_periodic_observation.get_periodic_param_type';
        IF NOT pk_periodic_observation.get_periodic_param_type(i_lang  => i_lang,
                                                               i_prof  => i_prof,
                                                               o_param => o_param,
                                                               o_error => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_cursor_if_closed(i_cursor => o_param);
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
            pk_types.open_cursor_if_closed(i_cursor => o_param);
            RETURN FALSE;
    END get_periodic_param_type;

    FUNCTION get_periodic_param_type
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_owner         IN VARCHAR2,
        o_param         OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_PERIODIC_PARAM_TYPE';
    BEGIN
        g_error := 'call pk_periodic_observation.get_periodic_param_type';
        IF NOT pk_periodic_observation.get_periodic_param_type(i_lang          => i_lang,
                                                               i_prof          => i_prof,
                                                               i_pat_pregnancy => i_pat_pregnancy,
                                                               i_owner         => i_owner,
                                                               o_param         => o_param,
                                                               o_error         => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_cursor_if_closed(i_cursor => o_param);
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
            pk_types.open_cursor_if_closed(i_cursor => o_param);
            RETURN FALSE;
    END get_periodic_param_type;

    FUNCTION get_other_periodic_param
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_flg_periodic_param_type IN periodic_param_type.flg_periodic_param_type%TYPE,
        i_patient                 IN patient.id_patient%TYPE,
        i_episode                 IN episode.id_episode%TYPE,
        o_param                   OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_OTHER_PERIODIC_PARAM';
    BEGIN
        IF NOT pk_periodic_observation.get_other_periodic_param(i_lang                    => i_lang,
                                                                i_prof                    => i_prof,
                                                                i_flg_periodic_param_type => i_flg_periodic_param_type,
                                                                i_patient                 => i_patient,
                                                                i_episode                 => i_episode,
                                                                o_param                   => o_param,
                                                                o_error                   => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_cursor_if_closed(i_cursor => o_param);
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
            pk_types.open_cursor_if_closed(i_cursor => o_param);
            RETURN FALSE;
    END get_other_periodic_param;
    FUNCTION get_other_periodic_param
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_flg_periodic_param_type IN periodic_param_type.flg_periodic_param_type%TYPE,
        i_patient                 IN patient.id_patient%TYPE,
        i_episode                 IN episode.id_episode%TYPE,
        i_pat_pregnancy           IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_owner                   IN VARCHAR2,
        o_param                   OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_OTHER_PERIODIC_PARAM';
    BEGIN
        IF NOT pk_periodic_observation.get_other_periodic_param(i_lang                    => i_lang,
                                                                i_prof                    => i_prof,
                                                                i_flg_periodic_param_type => i_flg_periodic_param_type,
                                                                i_patient                 => i_patient,
                                                                i_episode                 => i_episode,
                                                                i_pat_pregnancy           => i_pat_pregnancy,
                                                                i_owner                   => i_owner,
                                                                o_param                   => o_param,
                                                                o_error                   => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_cursor_if_closed(i_cursor => o_param);
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
            pk_types.open_cursor_if_closed(i_cursor => o_param);
            RETURN FALSE;
    END get_other_periodic_param;

    FUNCTION get_periodic_observation_an
    (
        i_lang          IN language.id_language%TYPE,
        i_room          IN room.id_room%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_analysis      OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_PERIODIC_OBSERVATION_AN';
    BEGIN
        IF NOT pk_periodic_observation.get_periodic_observation_an(i_lang          => i_lang,
                                                                   i_room          => i_room,
                                                                   i_episode       => i_episode,
                                                                   i_patient       => i_patient,
                                                                   i_prof          => i_prof,
                                                                   i_prof_cat_type => i_prof_cat_type,
                                                                   o_analysis      => o_analysis,
                                                                   o_error         => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_cursor_if_closed(i_cursor => o_analysis);
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
            pk_types.open_cursor_if_closed(i_cursor => o_analysis);
            RETURN FALSE;
    END get_periodic_observation_an;

    FUNCTION get_periodic_observation_an
    (
        i_lang          IN language.id_language%TYPE,
        i_room          IN room.id_room%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_owner         IN VARCHAR2,
        o_analysis      OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_PERIODIC_OBSERVATION_AN';
    BEGIN
        IF NOT pk_periodic_observation.get_periodic_observation_an(i_lang          => i_lang,
                                                                   i_room          => i_room,
                                                                   i_episode       => i_episode,
                                                                   i_patient       => i_patient,
                                                                   i_prof          => i_prof,
                                                                   i_prof_cat_type => i_prof_cat_type,
                                                                   i_pat_pregnancy => i_pat_pregnancy,
                                                                   i_owner         => i_owner,
                                                                   o_analysis      => o_analysis,
                                                                   o_error         => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_cursor_if_closed(i_cursor => o_analysis);
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
            pk_types.open_cursor_if_closed(i_cursor => o_analysis);
            RETURN FALSE;
    END get_periodic_observation_an;

    FUNCTION cancel_parameter
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_params  IN table_number,
        i_owners  IN table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'CANCEL_PARAMETER';
    BEGIN
        pk_periodic_observation.cancel_parameter(i_lang          => i_lang,
                                                 i_prof          => i_prof,
                                                 i_patient       => i_patient,
                                                 i_params        => i_params,
                                                 i_owners        => i_owners,
                                                 i_pat_pregnancy => NULL,
                                                 i_owner         => NULL);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END cancel_parameter;
    FUNCTION cancel_parameter
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_params        IN table_number,
        i_owners        IN table_number,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_owner         IN VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'CANCEL_PARAMETER';
    BEGIN
        pk_periodic_observation.cancel_parameter(i_lang          => i_lang,
                                                 i_prof          => i_prof,
                                                 i_patient       => i_patient,
                                                 i_params        => i_params,
                                                 i_owners        => i_owners,
                                                 i_pat_pregnancy => i_pat_pregnancy,
                                                 i_owner         => i_owner);
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END cancel_parameter;

    FUNCTION cancel_value
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_prof_cat    IN category.flg_type%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_patient     IN patient.id_patient%TYPE,
        i_values      IN table_number,
        i_types       IN table_varchar,
        i_canc_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_canc_notes  IN VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'CANCEL_VALUE';
    BEGIN
        IF NOT pk_periodic_observation.cancel_value(i_lang        => i_lang,
                                                    i_prof        => i_prof,
                                                    i_prof_cat    => i_prof_cat,
                                                    i_episode     => i_episode,
                                                    i_patient     => i_patient,
                                                    i_values      => i_values,
                                                    i_types       => i_types,
                                                    i_canc_reason => i_canc_reason,
                                                    i_canc_notes  => i_canc_notes,
                                                    o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_utils.undo_changes;
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
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END cancel_value;
    FUNCTION cancel_value_ref
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_prof_cat    IN category.flg_type%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_patient     IN patient.id_patient%TYPE,
        i_values      IN table_number,
        i_types       IN table_varchar,
        i_canc_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_canc_notes  IN VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'cancel_value_ref';
    BEGIN
        IF NOT pk_periodic_observation.cancel_value(i_lang        => i_lang,
                                                    i_prof        => i_prof,
                                                    i_prof_cat    => i_prof_cat,
                                                    i_episode     => i_episode,
                                                    i_patient     => i_patient,
                                                    i_values      => i_values,
                                                    i_types       => i_types,
                                                    i_canc_reason => i_canc_reason,
                                                    i_canc_notes  => i_canc_notes,
                                                    i_ref_value   => pk_alert_constant.g_yes,
                                                    o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_utils.undo_changes;
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
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END cancel_value_ref;

    FUNCTION create_column
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_dt      IN VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'CREATE_COLUMN';
    BEGIN
        pk_periodic_observation.create_column(i_lang    => i_lang,
                                              i_prof    => i_prof,
                                              i_patient => i_patient,
                                              i_episode => i_episode,
                                              i_dt      => i_dt,
                                              o_error   => o_error);
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END create_column;

    FUNCTION create_column_comm_order
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_dt              IN VARCHAR2,
        o_id_po_param_reg OUT po_param_reg.id_po_param_reg%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'CREATE_COLUMN_COMM_ORDER';
    BEGIN
        pk_periodic_observation.create_column_comm_order(i_lang            => i_lang,
                                                         i_prof            => i_prof,
                                                         i_patient         => i_patient,
                                                         i_episode         => i_episode,
                                                         i_dt              => i_dt,
                                                         o_id_po_param_reg => o_id_po_param_reg,
                                                         o_error           => o_error);
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END create_column_comm_order;

    FUNCTION create_column
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_dt              IN VARCHAR2,
        i_pat_pregnancy   IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_show_warning    OUT VARCHAR2,
        o_title_warning   OUT VARCHAR2,
        o_message_warning OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'CREATE_COLUMN';
    BEGIN
        IF NOT pk_periodic_observation.create_column(i_lang            => i_lang,
                                                     i_prof            => i_prof,
                                                     i_patient         => i_patient,
                                                     i_episode         => i_episode,
                                                     i_dt              => i_dt,
                                                     i_pat_pregnancy   => i_pat_pregnancy,
                                                     o_show_warning    => o_show_warning,
                                                     o_title_warning   => o_title_warning,
                                                     o_message_warning => o_message_warning,
                                                     o_error           => o_error)
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
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END create_column;

    FUNCTION get_actions
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_actions OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_ACTIONS';
    BEGIN
        IF NOT pk_periodic_observation.get_actions(i_lang    => i_lang,
                                                   i_prof    => i_prof,
                                                   o_actions => o_actions,
                                                   o_error   => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_cursor_if_closed(i_cursor => o_actions);
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
            pk_types.open_cursor_if_closed(i_cursor => o_actions);
            RETURN FALSE;
    END get_actions;

    FUNCTION get_create
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        o_create OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_CREATE';
    BEGIN
        g_error := 'call pk_periodic_observation.get_create';
        IF NOT pk_periodic_observation.get_create(i_lang          => i_lang,
                                                  i_prof          => i_prof,
                                                  i_pat_pregnancy => NULL,
                                                  o_create        => o_create,
                                                  o_error         => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_cursor_if_closed(i_cursor => o_create);
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
            pk_types.open_cursor_if_closed(i_cursor => o_create);
            RETURN FALSE;
    END get_create;
    FUNCTION get_create
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_create        OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_CREATE';
    BEGIN
        g_error := 'call pk_periodic_observation.get_create';
        IF NOT pk_periodic_observation.get_create(i_lang          => i_lang,
                                                  i_prof          => i_prof,
                                                  i_pat_pregnancy => i_pat_pregnancy,
                                                  o_create        => o_create,
                                                  o_error         => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_cursor_if_closed(i_cursor => o_create);
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
            pk_types.open_cursor_if_closed(i_cursor => o_create);
            RETURN FALSE;
    END get_create;

    FUNCTION get_detail
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_episode   IN episode.id_episode%TYPE,
        i_date      IN VARCHAR2,
        i_task_type IN VARCHAR2,
        o_detail    OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_DETAIL';
    BEGIN
        IF NOT pk_periodic_observation.get_detail(i_lang      => i_lang,
                                                  i_prof      => i_prof,
                                                  i_patient   => i_patient,
                                                  i_episode   => i_episode,
                                                  i_date      => i_date,
                                                  i_task_type => i_task_type,
                                                  o_detail    => o_detail,
                                                  o_error     => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_cursor_if_closed(i_cursor => o_detail);
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
            pk_types.open_cursor_if_closed(i_cursor => o_detail);
            RETURN FALSE;
    END get_detail;
    --------------------------
    FUNCTION get_detail_by_wh
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_date          IN VARCHAR2,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_detail        OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_DETAIL';
    BEGIN
        IF NOT pk_periodic_observation.get_detail_by_wh(i_lang          => i_lang,
                                                        i_prof          => i_prof,
                                                        i_patient       => i_patient,
                                                        i_episode       => i_episode,
                                                        i_date          => i_date,
                                                        i_pat_pregnancy => i_pat_pregnancy,
                                                        o_detail        => o_detail,
                                                        o_error         => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_cursor_if_closed(i_cursor => o_detail);
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
            pk_types.open_cursor_if_closed(i_cursor => o_detail);
            RETURN FALSE;
    END get_detail_by_wh;

    FUNCTION get_grid_param
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_dt_begin IN VARCHAR2,
        i_dt_end   IN VARCHAR2,
        i_num_reg  IN NUMBER DEFAULT NULL,
        o_param    OUT pk_types.cursor_type,
        o_time     OUT pk_types.cursor_type,
        o_value    OUT pk_types.cursor_type,
        o_ref      OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_GRID_PARAM';
        o_values_wh t_coll_wh_values;
    BEGIN
        IF NOT pk_periodic_observation.get_grid_param(i_lang      => i_lang,
                                                      i_prof      => i_prof,
                                                      i_patient   => i_patient,
                                                      i_episode   => i_episode,
                                                      i_dt_begin  => i_dt_begin,
                                                      i_dt_end    => i_dt_end,
                                                      i_num_reg   => i_num_reg,
                                                      o_param     => o_param,
                                                      o_time      => o_time,
                                                      o_value     => o_value,
                                                      o_ref       => o_ref,
                                                      o_values_wh => o_values_wh,
                                                      o_error     => o_error)
        THEN
            RAISE g_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_cursor_if_closed(i_cursor => o_param);
            pk_types.open_cursor_if_closed(i_cursor => o_time);
            pk_types.open_cursor_if_closed(i_cursor => o_value);
            pk_types.open_cursor_if_closed(i_cursor => o_ref);
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
            pk_types.open_cursor_if_closed(i_cursor => o_param);
            pk_types.open_cursor_if_closed(i_cursor => o_time);
            pk_types.open_cursor_if_closed(i_cursor => o_value);
            pk_types.open_cursor_if_closed(i_cursor => o_ref);
            RETURN FALSE;
    END get_grid_param;

    FUNCTION get_grid_param
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_num_reg IN NUMBER DEFAULT NULL,
        o_param   OUT pk_types.cursor_type,
        o_time    OUT pk_types.cursor_type,
        o_value   OUT pk_types.cursor_type,
        o_ref     OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_GRID_PARAM';
        o_values_wh t_coll_wh_values;
    BEGIN
        IF NOT pk_periodic_observation.get_grid_param(i_lang      => i_lang,
                                                      i_prof      => i_prof,
                                                      i_patient   => i_patient,
                                                      i_episode   => i_episode,
                                                      i_num_reg   => i_num_reg,
                                                      o_param     => o_param,
                                                      o_time      => o_time,
                                                      o_value     => o_value,
                                                      o_ref       => o_ref,
                                                      o_values_wh => o_values_wh,
                                                      o_error     => o_error)
        THEN
            RAISE g_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_cursor_if_closed(i_cursor => o_param);
            pk_types.open_cursor_if_closed(i_cursor => o_time);
            pk_types.open_cursor_if_closed(i_cursor => o_value);
            pk_types.open_cursor_if_closed(i_cursor => o_ref);
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
            pk_types.open_cursor_if_closed(i_cursor => o_param);
            pk_types.open_cursor_if_closed(i_cursor => o_time);
            pk_types.open_cursor_if_closed(i_cursor => o_value);
            pk_types.open_cursor_if_closed(i_cursor => o_ref);
            RETURN FALSE;
    END get_grid_param;

    FUNCTION get_keypad
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_param  IN po_param.id_po_param%TYPE,
        i_owner  IN po_param.id_inst_owner%TYPE,
        o_keypad OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_KEYPAD';
    BEGIN
        pk_periodic_observation.get_keypad(i_lang   => i_lang,
                                           i_prof   => i_prof,
                                           i_param  => i_param,
                                           i_owner  => i_owner,
                                           o_keypad => o_keypad);
    
        RETURN TRUE;
    EXCEPTION
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
            pk_types.open_cursor_if_closed(i_cursor => o_keypad);
            RETURN FALSE;
    END get_keypad;

    FUNCTION get_multichoice
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_param   IN po_param.id_po_param%TYPE,
        i_owner   IN po_param.id_inst_owner%TYPE,
        o_mc      OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_MULTICHOICE';
    BEGIN
        IF NOT pk_periodic_observation.get_multichoice(i_lang    => i_lang,
                                                       i_prof    => i_prof,
                                                       i_patient => i_patient,
                                                       i_param   => i_param,
                                                       i_owner   => i_owner,
                                                       o_mc      => o_mc,
                                                       o_error   => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_cursor_if_closed(i_cursor => o_mc);
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
            pk_types.open_cursor_if_closed(i_cursor => o_mc);
            RETURN FALSE;
    END get_multichoice;

    FUNCTION get_values_cancel
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_param   IN po_param.id_po_param%TYPE,
        i_owner   IN po_param.id_inst_owner%TYPE,
        i_dt      IN VARCHAR2,
        o_values  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_VALUES_CANCEL';
    BEGIN
        IF NOT pk_periodic_observation.get_values_cancel(i_lang    => i_lang,
                                                         i_prof    => i_prof,
                                                         i_patient => i_patient,
                                                         i_episode => i_episode,
                                                         i_param   => i_param,
                                                         i_owner   => i_owner,
                                                         i_dt      => i_dt,
                                                         o_values  => o_values,
                                                         o_error   => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_cursor_if_closed(i_cursor => o_values);
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
            pk_types.open_cursor_if_closed(i_cursor => o_values);
            RETURN FALSE;
    END get_values_cancel;
    -----------------------------------
    FUNCTION get_values_cancel
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_param           IN po_param.id_po_param%TYPE,
        i_owner           IN po_param.id_inst_owner%TYPE,
        i_dt              IN VARCHAR2,
        i_woman_health_id IN VARCHAR2,
        o_values          OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_VALUES_CANCEL';
    BEGIN
        IF NOT pk_periodic_observation.get_values_cancel(i_lang            => i_lang,
                                                         i_prof            => i_prof,
                                                         i_patient         => i_patient,
                                                         i_episode         => i_episode,
                                                         i_param           => i_param,
                                                         i_owner           => i_owner,
                                                         i_dt              => i_dt,
                                                         i_woman_health_id => i_woman_health_id,
                                                         o_values          => o_values,
                                                         o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
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
            pk_types.open_cursor_if_closed(i_cursor => o_values);
            RETURN FALSE;
    END get_values_cancel;
    FUNCTION get_views
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_loader  IN application_file.file_name%TYPE,
        o_views   OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_VIEWS';
    BEGIN
        IF NOT pk_periodic_observation.get_views(i_lang    => i_lang,
                                                 i_prof    => i_prof,
                                                 i_patient => i_patient,
                                                 i_loader  => i_loader,
                                                 o_views   => o_views,
                                                 o_error   => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_cursor_if_closed(i_cursor => o_views);
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
            pk_types.open_cursor_if_closed(i_cursor => o_views);
            RETURN FALSE;
    END get_views;

    FUNCTION set_parameter
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_parameters  IN table_number,
        i_types       IN table_varchar,
        i_sample_type IN table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_PARAMETER';
    BEGIN
        IF NOT pk_periodic_observation.set_parameter(i_lang          => i_lang,
                                                     i_prof          => i_prof,
                                                     i_patient       => i_patient,
                                                     i_parameters    => i_parameters,
                                                     i_types         => i_types,
                                                     i_pat_pregnancy => NULL,
                                                     i_owner         => NULL,
                                                     i_sample_type   => i_sample_type,
                                                     o_error         => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_utils.undo_changes;
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
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_parameter;

    FUNCTION set_parameter
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_parameters    IN table_number,
        i_types         IN table_varchar,
        i_sample_type   IN table_number,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_owner         IN VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_PARAMETER';
    BEGIN
        IF NOT pk_periodic_observation.set_parameter(i_lang          => i_lang,
                                                     i_prof          => i_prof,
                                                     i_patient       => i_patient,
                                                     i_parameters    => i_parameters,
                                                     i_types         => i_types,
                                                     i_pat_pregnancy => i_pat_pregnancy,
                                                     i_owner         => i_owner,
                                                     i_sample_type   => i_sample_type,
                                                     o_error         => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_utils.undo_changes;
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
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_parameter;

    FUNCTION set_value_k
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_prof_cat IN category.flg_type%TYPE,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_params   IN table_number,
        i_owners   IN table_number,
        i_results  IN table_varchar,
        i_unit_mea IN table_number,
        i_date     IN VARCHAR2,
        o_value    OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_VALUE_K';
    BEGIN
        IF NOT pk_periodic_observation.set_value_k(i_lang            => i_lang,
                                                   i_prof            => i_prof,
                                                   i_prof_cat        => i_prof_cat,
                                                   i_patient         => i_patient,
                                                   i_episode         => i_episode,
                                                   i_params          => i_params,
                                                   i_owners          => i_owners,
                                                   i_results         => i_results,
                                                   i_unit_mea        => i_unit_mea,
                                                   i_date            => i_date,
                                                   i_woman_health_id => NULL,
                                                   o_value           => o_value,
                                                   o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_value);
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
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_value);
            RETURN FALSE;
    END set_value_k;
    FUNCTION set_value_k
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_prof_cat        IN category.flg_type%TYPE,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_params          IN table_number,
        i_owners          IN table_number,
        i_results         IN table_varchar,
        i_unit_mea        IN table_number,
        i_date            IN VARCHAR2,
        i_woman_health_id IN VARCHAR2,
        o_value           OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_VALUE_K';
    BEGIN
        IF NOT pk_periodic_observation.set_value_k(i_lang            => i_lang,
                                                   i_prof            => i_prof,
                                                   i_prof_cat        => i_prof_cat,
                                                   i_patient         => i_patient,
                                                   i_episode         => i_episode,
                                                   i_params          => i_params,
                                                   i_owners          => i_owners,
                                                   i_results         => i_results,
                                                   i_unit_mea        => i_unit_mea,
                                                   i_date            => i_date,
                                                   i_woman_health_id => i_woman_health_id,
                                                   o_value           => o_value,
                                                   o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_value);
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
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_value);
            RETURN FALSE;
    END set_value_k;
    FUNCTION set_value_m
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_prof_cat IN category.flg_type%TYPE,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_params   IN table_number,
        i_owners   IN table_number,
        i_options  IN table_table_number,
        i_date     IN VARCHAR2,
        o_value    OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_VALUE_M';
    BEGIN
        IF NOT pk_periodic_observation.set_value_m(i_lang            => i_lang,
                                                   i_prof            => i_prof,
                                                   i_prof_cat        => i_prof_cat,
                                                   i_patient         => i_patient,
                                                   i_episode         => i_episode,
                                                   i_params          => i_params,
                                                   i_owners          => i_owners,
                                                   i_options         => i_options,
                                                   i_date            => i_date,
                                                   i_woman_health_id => NULL,
                                                   o_value           => o_value,
                                                   o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_value);
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
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_value);
            RETURN FALSE;
    END set_value_m;
    -----------------------------------
    FUNCTION set_value_m
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_prof_cat        IN category.flg_type%TYPE,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_params          IN table_number,
        i_owners          IN table_number,
        i_options         IN table_table_number,
        i_date            IN VARCHAR2,
        i_woman_health_id IN VARCHAR2,
        o_value           OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_VALUE_M';
    BEGIN
        IF NOT pk_periodic_observation.set_value_m(i_lang            => i_lang,
                                                   i_prof            => i_prof,
                                                   i_prof_cat        => i_prof_cat,
                                                   i_patient         => i_patient,
                                                   i_episode         => i_episode,
                                                   i_params          => i_params,
                                                   i_owners          => i_owners,
                                                   i_options         => i_options,
                                                   i_date            => i_date,
                                                   i_woman_health_id => i_woman_health_id,
                                                   o_value           => o_value,
                                                   o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_value);
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
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_value);
            RETURN FALSE;
    END set_value_m;
    -----------------------------------
    FUNCTION set_value_t
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_prof_cat IN category.flg_type%TYPE,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_params   IN table_number,
        i_owners   IN table_number,
        i_results  IN table_clob,
        i_date     IN VARCHAR2,
        o_value    OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'set_value_t';
    BEGIN
        IF NOT pk_periodic_observation.set_value_t(i_lang            => i_lang,
                                                   i_prof            => i_prof,
                                                   i_prof_cat        => i_prof_cat,
                                                   i_patient         => i_patient,
                                                   i_episode         => i_episode,
                                                   i_params          => i_params,
                                                   i_owners          => i_owners,
                                                   i_results         => i_results,
                                                   i_date            => i_date,
                                                   i_woman_health_id => NULL,
                                                   o_value           => o_value,
                                                   o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_value);
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
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_value);
            RETURN FALSE;
    END set_value_t;
    FUNCTION set_value_t
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_prof_cat        IN category.flg_type%TYPE,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_params          IN table_number,
        i_owners          IN table_number,
        i_results         IN table_clob,
        i_date            IN VARCHAR2,
        i_woman_health_id IN VARCHAR2,
        o_value           OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'set_value_t';
    BEGIN
        IF NOT pk_periodic_observation.set_value_t(i_lang            => i_lang,
                                                   i_prof            => i_prof,
                                                   i_prof_cat        => i_prof_cat,
                                                   i_patient         => i_patient,
                                                   i_episode         => i_episode,
                                                   i_params          => i_params,
                                                   i_owners          => i_owners,
                                                   i_results         => i_results,
                                                   i_date            => i_date,
                                                   i_woman_health_id => i_woman_health_id,
                                                   o_value           => o_value,
                                                   o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_value);
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
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_value);
            RETURN FALSE;
    END set_value_t;
    ----------------------------------------------------
    FUNCTION set_value_d
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_prof_cat   IN category.flg_type%TYPE,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_params     IN table_number,
        i_owners     IN table_number,
        i_dates      IN table_varchar,
        i_dates_mask IN table_varchar,
        i_date       IN VARCHAR2,
        o_value      OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'set_value_d';
    BEGIN
        IF NOT pk_periodic_observation.set_value_d(i_lang            => i_lang,
                                                   i_prof            => i_prof,
                                                   i_prof_cat        => i_prof_cat,
                                                   i_patient         => i_patient,
                                                   i_episode         => i_episode,
                                                   i_params          => i_params,
                                                   i_owners          => i_owners,
                                                   i_dates           => i_dates,
                                                   i_dates_mask      => i_dates_mask,
                                                   i_date            => i_date,
                                                   i_woman_health_id => NULL,
                                                   o_value           => o_value,
                                                   o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_value);
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
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_value);
            RETURN FALSE;
    END set_value_d;
    FUNCTION set_value_d
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_prof_cat        IN category.flg_type%TYPE,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_params          IN table_number,
        i_owners          IN table_number,
        i_dates           IN table_varchar,
        i_dates_mask      IN table_varchar,
        i_date            IN VARCHAR2,
        i_woman_health_id IN VARCHAR2,
        o_value           OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'set_value_d';
    BEGIN
        IF NOT pk_periodic_observation.set_value_d(i_lang            => i_lang,
                                                   i_prof            => i_prof,
                                                   i_prof_cat        => i_prof_cat,
                                                   i_patient         => i_patient,
                                                   i_episode         => i_episode,
                                                   i_params          => i_params,
                                                   i_owners          => i_owners,
                                                   i_dates           => i_dates,
                                                   i_dates_mask      => i_dates_mask,
                                                   i_date            => i_date,
                                                   i_woman_health_id => i_woman_health_id,
                                                   o_value           => o_value,
                                                   o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_value);
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
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_value);
            RETURN FALSE;
    END set_value_d;
    -------------------------------------------
    /*
    * Creates an order with a result for a given exam
    *
    * @param     i_lang                Language id
    * @param     i_prof                Professional
    * @param     i_patient             Patient id
    * @param     i_episode             Episode id
    * @param     i_exam_req_det        Exam detail order id
    * @param     i_reg                 Periodic observation id
    * @param     i_exam                Exams' id
    * @param     i_test                Flag that indicates if the exam is really to be ordered
    * @param     i_prof_performed      Professional perform id
    * @param     i_start_time          Exams' start time
    * @param     i_end_time            Exams' end time
    * @param     i_flg_result_origin   Flag that indicates what is the result's origin
    * @param     i_notes               Result notes
    * @param     i_flg_import          Flag that indicates if there is a document to import
    * @param     i_id_doc              Closing document id
    * @param     i_doc_type            Document type id
    * @param     i_desc_doc_type       Document type description
    * @param     i_dt_doc              Original document date
    * @param     i_dest                Destination id
    * @param     i_desc_dest           Destination description
    * @param     i_ori_type            Document type id
    * @param     i_desc_ori_doc_type   Document type description
    * @param     i_original            Original document id
    * @param     i_desc_original       Original document description
    * @param     i_btn                 Context
    * @param     i_title               Document description
    * @param     i_desc_perf_by        Performed by description
    * @param     i_woman_health_id     Pregnancy ID
    * @param     o_flg_show            Flag that indicates if there is a message to be shown
    * @param     o_msg_title           Message title
    * @param     o_msg_req             Message to be shown
    * @param     o_button              Buttons to show
    * @param     o_exam_req            Exams' order id
    * @param     o_exam_req_det        Exams' order details id 
    * @param     o_value               Value object,
    * @param     o_error               Error message
    *
    * @author               Jorge Silva
    * @version               2.5
    * @since                2013/04/09
    */
    FUNCTION set_value_exams
    (
        i_lang                IN language.id_language%TYPE, --1
        i_prof                IN profissional,
        i_patient             IN patient.id_patient%TYPE,
        i_episode             IN exam_req.id_episode%TYPE,
        i_exam_req_det        IN exam_req_det.id_exam_req_det%TYPE, --5
        i_reg                 IN periodic_observation_reg.id_periodic_observation_reg%TYPE,
        i_exam                IN exam.id_exam%TYPE,
        i_prof_performed      IN exam_req_det.id_prof_performed%TYPE,
        i_start_time          IN VARCHAR2,
        i_end_time            IN VARCHAR2, --10
        i_result_status       IN result_status.id_result_status%TYPE,
        i_abnormality         IN exam_result.id_abnormality%TYPE,
        i_flg_result_origin   IN exam_result.flg_result_origin%TYPE,
        i_result_origin_notes IN exam_result.result_origin_notes%TYPE,
        i_notes               IN exam_result.notes%TYPE, --15
        i_flg_import          IN table_varchar,
        i_id_doc              IN table_number,
        i_doc_type            IN table_number,
        i_desc_doc_type       IN table_varchar,
        i_dt_doc              IN table_varchar, --20
        i_dest                IN table_number,
        i_desc_dest           IN table_varchar,
        i_ori_doc_type        IN table_number,
        i_desc_ori_doc_type   IN table_varchar,
        i_original            IN table_number, --25
        i_desc_original       IN table_varchar,
        i_title               IN table_varchar,
        i_desc_perf_by        IN table_varchar,
        i_po_param            IN table_number,
        i_woman_health_id     IN VARCHAR2, --30
        o_exam_req            OUT exam_req.id_exam_req%TYPE,
        o_exam_req_det        OUT exam_req_det.id_exam_req_det%TYPE,
        o_value               OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_VALUE_EXAMS';
    BEGIN
        IF NOT pk_periodic_observation.set_value_exams(i_lang                => i_lang,
                                                       i_prof                => i_prof,
                                                       i_patient             => i_patient,
                                                       i_episode             => i_episode,
                                                       i_exam_req_det        => i_exam_req_det,
                                                       i_reg                 => i_reg,
                                                       i_exam                => i_exam,
                                                       i_prof_performed      => i_prof_performed,
                                                       i_start_time          => i_start_time,
                                                       i_end_time            => i_end_time,
                                                       i_result_status       => i_result_status,
                                                       i_abnormality         => i_abnormality,
                                                       i_flg_result_origin   => i_flg_result_origin,
                                                       i_result_origin_notes => i_result_origin_notes,
                                                       i_notes               => i_notes,
                                                       i_flg_import          => i_flg_import,
                                                       i_id_doc              => i_id_doc,
                                                       i_doc_type            => i_doc_type,
                                                       i_desc_doc_type       => i_desc_doc_type,
                                                       i_dt_doc              => i_dt_doc,
                                                       i_dest                => i_dest,
                                                       i_desc_dest           => i_desc_dest,
                                                       i_ori_doc_type        => i_ori_doc_type,
                                                       i_desc_ori_doc_type   => i_desc_ori_doc_type,
                                                       i_original            => i_original,
                                                       i_desc_original       => i_desc_original,
                                                       i_title               => i_title,
                                                       i_desc_perf_by        => i_desc_perf_by,
                                                       i_po_param            => i_po_param,
                                                       i_woman_health_id     => i_woman_health_id,
                                                       o_exam_req            => o_exam_req,
                                                       o_exam_req_det        => o_exam_req_det,
                                                       o_value               => o_value,
                                                       o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_utils.undo_changes;
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
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_value_exams;

    /*
    * Creates an order with a result for a given exam
    *
    * @param     i_lang                Language id
    * @param     i_prof                Professional
    * @param     i_patient             Patient id
    * @param     i_episode             Episode id
    * @param     i_exam_req_det        Exam detail order id
    * @param     i_reg                 Periodic observation id
    * @param     i_exam                Exams' id
    * @param     i_test                Flag that indicates if the exam is really to be ordered
    * @param     i_prof_performed      Professional perform id
    * @param     i_start_time          Exams' start time
    * @param     i_end_time            Exams' end time
    * @param     i_flg_result_origin   Flag that indicates what is the result's origin
    * @param     i_notes               Result notes
    * @param     i_flg_import          Flag that indicates if there is a document to import
    * @param     i_id_doc              Closing document id
    * @param     i_doc_type            Document type id
    * @param     i_desc_doc_type       Document type description
    * @param     i_dt_doc              Original document date
    * @param     i_dest                Destination id
    * @param     i_desc_dest           Destination description
    * @param     i_ori_type            Document type id
    * @param     i_desc_ori_doc_type   Document type description
    * @param     i_original            Original document id
    * @param     i_desc_original       Original document description
    * @param     i_btn                 Context
    * @param     i_title               Document description
    * @param     i_desc_perf_by        Performed by description
    * @param     o_flg_show            Flag that indicates if there is a message to be shown
    * @param     o_msg_title           Message title
    * @param     o_msg_req             Message to be shown
    * @param     o_button              Buttons to show
    * @param     o_exam_req            Exams' order id
    * @param     o_exam_req_det        Exams' order details id 
    * @param     o_value               Value object,
    * @param     o_error               Error message
    *
    * @author               Jorge Silva
    * @version               2.5
    * @since                2013/04/09
    */
    FUNCTION set_value_exams
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_patient             IN patient.id_patient%TYPE,
        i_episode             IN exam_req.id_episode%TYPE,
        i_exam_req_det        IN exam_req_det.id_exam_req_det%TYPE,
        i_reg                 IN periodic_observation_reg.id_periodic_observation_reg%TYPE,
        i_exam                IN exam.id_exam%TYPE,
        i_prof_performed      IN exam_req_det.id_prof_performed%TYPE,
        i_start_time          IN VARCHAR2,
        i_end_time            IN VARCHAR2,
        i_result_status       IN result_status.id_result_status%TYPE,
        i_abnormality         IN exam_result.id_abnormality%TYPE,
        i_flg_result_origin   IN exam_result.flg_result_origin%TYPE,
        i_result_origin_notes IN exam_result.result_origin_notes%TYPE,
        i_notes               IN exam_result.notes%TYPE,
        i_flg_import          IN table_varchar,
        i_id_doc              IN table_number,
        i_doc_type            IN table_number,
        i_desc_doc_type       IN table_varchar,
        i_dt_doc              IN table_varchar,
        i_dest                IN table_number,
        i_desc_dest           IN table_varchar,
        i_ori_doc_type        IN table_number,
        i_desc_ori_doc_type   IN table_varchar,
        i_original            IN table_number,
        i_desc_original       IN table_varchar,
        i_title               IN table_varchar,
        i_desc_perf_by        IN table_varchar,
        i_po_param            IN table_number,
        o_exam_req            OUT exam_req.id_exam_req%TYPE,
        o_exam_req_det        OUT exam_req_det.id_exam_req_det%TYPE,
        o_value               OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_VALUE_EXAMS';
    BEGIN
        IF NOT pk_periodic_observation.set_value_exams(i_lang                => i_lang,
                                                       i_prof                => i_prof,
                                                       i_patient             => i_patient,
                                                       i_episode             => i_episode,
                                                       i_exam_req_det        => i_exam_req_det,
                                                       i_reg                 => i_reg,
                                                       i_exam                => i_exam,
                                                       i_prof_performed      => i_prof_performed,
                                                       i_start_time          => i_start_time,
                                                       i_end_time            => i_end_time,
                                                       i_result_status       => i_result_status,
                                                       i_abnormality         => i_abnormality,
                                                       i_flg_result_origin   => i_flg_result_origin,
                                                       i_result_origin_notes => i_result_origin_notes,
                                                       i_notes               => i_notes,
                                                       i_flg_import          => i_flg_import,
                                                       i_id_doc              => i_id_doc,
                                                       i_doc_type            => i_doc_type,
                                                       i_desc_doc_type       => i_desc_doc_type,
                                                       i_dt_doc              => i_dt_doc,
                                                       i_dest                => i_dest,
                                                       i_desc_dest           => i_desc_dest,
                                                       i_ori_doc_type        => i_ori_doc_type,
                                                       i_desc_ori_doc_type   => i_desc_ori_doc_type,
                                                       i_original            => i_original,
                                                       i_desc_original       => i_desc_original,
                                                       i_title               => i_title,
                                                       i_desc_perf_by        => i_desc_perf_by,
                                                       i_po_param            => i_po_param,
                                                       i_woman_health_id     => NULL,
                                                       o_exam_req            => o_exam_req,
                                                       o_exam_req_det        => o_exam_req_det,
                                                       o_value               => o_value,
                                                       o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_utils.undo_changes;
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
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_value_exams;

    /******************************************************************************
    *
    * Create analysis results with/without analysis req also updates de results values 
    * This development is for the complex analysis, inserting the results values partially
    *
    * @return true/false
    *
    * @AUTHOR Jorge Silva
    * @VERSION 2.5.2
    * @SINCE 22/4/2013
    *
    *******************************************************************************/
    FUNCTION set_value_analysis
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_patient                IN analysis_result.id_patient%TYPE,
        i_episode                IN analysis_result.id_episode%TYPE,
        i_analysis               IN analysis.id_analysis%TYPE,
        i_sample_type            IN sample_type.id_sample_type%TYPE,
        i_analysis_parameter     IN table_number,
        i_analysis_param         IN table_number,
        i_analysis_req_det       IN analysis_req_det.id_analysis_req_det%TYPE,
        i_analysis_req_par       IN table_number,
        i_analysis_result_par    IN table_number,
        i_flg_type               IN table_varchar,
        i_harvest                IN harvest.id_harvest%TYPE,
        i_dt_sample              IN VARCHAR2,
        i_prof_req               IN analysis_result.id_prof_req%TYPE,
        i_dt_analysis_result     IN VARCHAR2,
        i_flg_result_origin      IN analysis_result.flg_result_origin%TYPE,
        i_result_origin_notes    IN analysis_result.result_origin_notes%TYPE,
        i_result_notes           IN analysis_result.notes%TYPE,
        i_result                 IN table_varchar,
        i_analysis_desc          IN table_number,
        i_doc_external           IN table_table_number DEFAULT NULL,
        i_doc_type               IN table_table_number DEFAULT NULL,
        i_doc_ori_type           IN table_table_number DEFAULT NULL,
        i_title                  IN table_table_varchar DEFAULT NULL, --30
        i_unit_measure           IN table_number,
        i_result_status          IN table_number,
        i_ref_val_min            IN table_varchar,
        i_ref_val_max            IN table_varchar,
        i_parameter_notes        IN table_varchar,
        i_flg_orig_analysis      IN VARCHAR2,
        i_clinical_decision_rule IN NUMBER,
        i_po_param               IN table_number,
        o_value                  OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_VALUE_ANALYSIS';
    BEGIN
        IF NOT pk_periodic_observation.set_value_analysis(i_lang                   => i_lang,
                                                          i_prof                   => i_prof,
                                                          i_patient                => i_patient,
                                                          i_episode                => i_episode,
                                                          i_analysis               => i_analysis,
                                                          i_sample_type            => i_sample_type,
                                                          i_analysis_parameter     => i_analysis_parameter,
                                                          i_analysis_param         => i_analysis_param,
                                                          i_analysis_req_det       => i_analysis_req_det,
                                                          i_analysis_req_par       => i_analysis_req_par,
                                                          i_analysis_result_par    => i_analysis_result_par,
                                                          i_flg_type               => i_flg_type,
                                                          i_harvest                => i_harvest,
                                                          i_dt_sample              => i_dt_sample,
                                                          i_prof_req               => i_prof_req,
                                                          i_dt_analysis_result     => i_dt_analysis_result,
                                                          i_flg_result_origin      => i_flg_result_origin,
                                                          i_result_origin_notes    => i_result_origin_notes,
                                                          i_result_notes           => i_result_notes,
                                                          i_result                 => i_result,
                                                          i_analysis_desc          => i_analysis_desc,
                                                          i_unit_measure           => i_unit_measure,
                                                          i_result_status          => i_result_status,
                                                          i_ref_val_min            => i_ref_val_min,
                                                          i_ref_val_max            => i_ref_val_max,
                                                          i_parameter_notes        => i_parameter_notes,
                                                          i_flg_orig_analysis      => i_flg_orig_analysis,
                                                          i_clinical_decision_rule => i_clinical_decision_rule,
                                                          i_po_param               => i_po_param,
                                                          i_woman_health_id        => NULL,
                                                          o_value                  => o_value,
                                                          o_error                  => o_error)
        
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_utils.undo_changes;
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
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_value_analysis;

    /******************************************************************************
    *
    * Create analysis results with/without analysis req also updates de results values 
    * This development is for the complex analysis, inserting the results values partially
    *
    * @return true/false
    *
    * @AUTHOR Jorge Silva
    * @VERSION 2.5.2
    * @SINCE 22/4/2013
    *
    *******************************************************************************/
    FUNCTION set_value_analysis
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_patient                IN analysis_result.id_patient%TYPE,
        i_episode                IN analysis_result.id_episode%TYPE,
        i_analysis               IN analysis.id_analysis%TYPE,
        i_sample_type            IN sample_type.id_sample_type%TYPE,
        i_analysis_parameter     IN table_number,
        i_analysis_param         IN table_number,
        i_analysis_req_det       IN analysis_req_det.id_analysis_req_det%TYPE,
        i_analysis_req_par       IN table_number,
        i_analysis_result_par    IN table_number,
        i_flg_type               IN table_varchar,
        i_harvest                IN harvest.id_harvest%TYPE,
        i_dt_sample              IN VARCHAR2,
        i_prof_req               IN analysis_result.id_prof_req%TYPE,
        i_dt_analysis_result     IN VARCHAR2,
        i_flg_result_origin      IN analysis_result.flg_result_origin%TYPE,
        i_result_origin_notes    IN analysis_result.result_origin_notes%TYPE,
        i_result_notes           IN analysis_result.notes%TYPE,
        i_result                 IN table_varchar,
        i_analysis_desc          IN table_number,
        i_doc_external           IN table_table_number DEFAULT NULL,
        i_doc_type               IN table_table_number DEFAULT NULL,
        i_doc_ori_type           IN table_table_number DEFAULT NULL,
        i_title                  IN table_table_varchar DEFAULT NULL, --30
        i_unit_measure           IN table_number,
        i_result_status          IN table_number,
        i_ref_val_min            IN table_varchar,
        i_ref_val_max            IN table_varchar,
        i_parameter_notes        IN table_varchar,
        i_flg_orig_analysis      IN VARCHAR2,
        i_clinical_decision_rule IN NUMBER,
        i_po_param               IN table_number,
        i_woman_health_id        IN VARCHAR2,
        o_value                  OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_VALUE_ANALYSIS';
    BEGIN
        IF NOT pk_periodic_observation.set_value_analysis(i_lang                   => i_lang,
                                                          i_prof                   => i_prof,
                                                          i_patient                => i_patient,
                                                          i_episode                => i_episode,
                                                          i_analysis               => i_analysis,
                                                          i_sample_type            => i_sample_type,
                                                          i_analysis_parameter     => i_analysis_parameter,
                                                          i_analysis_param         => i_analysis_param,
                                                          i_analysis_req_det       => i_analysis_req_det,
                                                          i_analysis_req_par       => i_analysis_req_par,
                                                          i_analysis_result_par    => i_analysis_result_par,
                                                          i_flg_type               => i_flg_type,
                                                          i_harvest                => i_harvest,
                                                          i_dt_sample              => i_dt_sample,
                                                          i_prof_req               => i_prof_req,
                                                          i_dt_analysis_result     => i_dt_analysis_result,
                                                          i_flg_result_origin      => i_flg_result_origin,
                                                          i_result_origin_notes    => i_result_origin_notes,
                                                          i_result_notes           => i_result_notes,
                                                          i_result                 => i_result,
                                                          i_analysis_desc          => i_analysis_desc,
                                                          i_unit_measure           => i_unit_measure,
                                                          i_result_status          => i_result_status,
                                                          i_ref_val_min            => i_ref_val_min,
                                                          i_ref_val_max            => i_ref_val_max,
                                                          i_parameter_notes        => i_parameter_notes,
                                                          i_flg_orig_analysis      => i_flg_orig_analysis,
                                                          i_clinical_decision_rule => i_clinical_decision_rule,
                                                          i_po_param               => i_po_param,
                                                          i_woman_health_id        => i_woman_health_id,
                                                          o_value                  => o_value,
                                                          o_error                  => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_utils.undo_changes;
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
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_value_analysis;

    /**
    * Get woman health grid.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param o_wh           woman health 
    * @param o_param        parameters
    * @param o_wh_param     woman health parameters
    * @param o_time         times
    * @param o_value        values
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Paulo Teixeira
    * @version               2.5
    * @since                2013/02/18
    */
    FUNCTION get_grid_wh
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_wh            OUT pk_types.cursor_type,
        o_param         OUT pk_types.cursor_type,
        o_wh_param      OUT pk_types.cursor_type,
        o_time          OUT pk_types.cursor_type,
        o_value         OUT pk_types.cursor_type,
        o_ref           OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'get_grid_wh';
        o_values_wh t_coll_wh_values;
    BEGIN
        g_error := 'call pk_periodic_observation.get_grid_wh';
        IF NOT pk_periodic_observation.get_grid_wh(i_lang          => i_lang,
                                                   i_prof          => i_prof,
                                                   i_patient       => i_patient,
                                                   i_episode       => i_episode,
                                                   i_pat_pregnancy => i_pat_pregnancy,
                                                   o_wh            => o_wh,
                                                   o_param         => o_param,
                                                   o_wh_param      => o_wh_param,
                                                   o_time          => o_time,
                                                   o_value         => o_value,
                                                   o_values_wh     => o_values_wh,
                                                   o_ref           => o_ref,
                                                   o_error         => o_error)
        THEN
            RAISE g_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
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
            pk_types.open_my_cursor(i_cursor => o_wh);
            pk_types.open_my_cursor(i_cursor => o_param);
            pk_types.open_my_cursor(i_cursor => o_wh_param);
            pk_types.open_my_cursor(i_cursor => o_time);
            pk_types.open_my_cursor(i_cursor => o_value);
            pk_types.open_my_cursor(i_cursor => o_ref);
            RETURN FALSE;
    END get_grid_wh;

    /**
    * get_permissions
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_pat_pregnancy        pat_pregnancy identifier
    * @param o_read_only        read_only Y/N
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Paulo Teixeira
    * @version               2.5
    * @since                2013/02/18
    */
    FUNCTION get_permissions
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_read_only     OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'get_permissions';
    BEGIN
        g_error := 'call pk_periodic_observation.get_permissions';
        IF NOT pk_periodic_observation.get_permissions(i_lang          => i_lang,
                                                       i_prof          => i_prof,
                                                       i_pat_pregnancy => i_pat_pregnancy,
                                                       o_read_only     => o_read_only,
                                                       o_error         => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
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
    END get_permissions;
    -----------------------------------------
    FUNCTION set_vital_sign
    (
        i_lang               IN language.id_language%TYPE,
        i_episode            IN vital_sign_read.id_episode%TYPE,
        i_prof               IN profissional,
        i_pat                IN vital_sign_read.id_patient%TYPE,
        i_vs_id              IN table_number,
        i_vs_val             IN table_number,
        i_id_monit           IN monitorization_vs_plan.id_monitorization_vs_plan%TYPE,
        i_unit_meas          IN table_number,
        i_vs_scales_elements IN table_number,
        i_notes              IN vital_sign_notes.notes%TYPE,
        i_prof_cat_type      IN category.flg_type%TYPE,
        i_dt_vs_read         IN VARCHAR2,
        i_params             IN table_number,
        i_woman_health_id    IN VARCHAR2,
        o_vital_sign_read    OUT table_number,
        o_value              OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'set_vital_sign';
    BEGIN
        g_error := 'call pk_periodic_observation.set_vital_sign';
        IF NOT pk_periodic_observation.set_vital_sign(i_lang               => i_lang,
                                                      i_episode            => i_episode,
                                                      i_prof               => i_prof,
                                                      i_pat                => i_pat,
                                                      i_vs_id              => i_vs_id,
                                                      i_vs_val             => i_vs_val,
                                                      i_id_monit           => i_id_monit,
                                                      i_unit_meas          => i_unit_meas,
                                                      i_vs_scales_elements => i_vs_scales_elements,
                                                      i_notes              => i_notes,
                                                      i_prof_cat_type      => i_prof_cat_type,
                                                      i_dt_vs_read         => i_dt_vs_read,
                                                      i_params             => i_params,
                                                      i_woman_health_id    => i_woman_health_id,
                                                      o_vital_sign_read    => o_vital_sign_read,
                                                      o_value              => o_value,
                                                      o_error              => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_value);
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
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_value);
            RETURN FALSE;
    END set_vital_sign;
    ----------------------------------------------------
    FUNCTION set_vital_sign
    (
        i_lang               IN language.id_language%TYPE,
        i_episode            IN vital_sign_read.id_episode%TYPE,
        i_prof               IN profissional,
        i_pat                IN vital_sign_read.id_patient%TYPE,
        i_vs_id              IN table_number,
        i_vs_val             IN table_number,
        i_id_monit           IN monitorization_vs_plan.id_monitorization_vs_plan%TYPE,
        i_unit_meas          IN table_number,
        i_vs_scales_elements IN table_number,
        i_notes              IN vital_sign_notes.notes%TYPE,
        i_prof_cat_type      IN category.flg_type%TYPE,
        i_dt_vs_read         IN VARCHAR2,
        i_params             IN table_number,
        o_vital_sign_read    OUT table_number,
        o_value              OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'set_vital_sign';
    BEGIN
        g_error := 'call pk_periodic_observation.set_vital_sign';
        IF NOT pk_periodic_observation.set_vital_sign(i_lang               => i_lang,
                                                      i_episode            => i_episode,
                                                      i_prof               => i_prof,
                                                      i_pat                => i_pat,
                                                      i_vs_id              => i_vs_id,
                                                      i_vs_val             => i_vs_val,
                                                      i_id_monit           => i_id_monit,
                                                      i_unit_meas          => i_unit_meas,
                                                      i_vs_scales_elements => i_vs_scales_elements,
                                                      i_notes              => i_notes,
                                                      i_prof_cat_type      => i_prof_cat_type,
                                                      i_dt_vs_read         => i_dt_vs_read,
                                                      i_params             => i_params,
                                                      i_woman_health_id    => NULL,
                                                      o_vital_sign_read    => o_vital_sign_read,
                                                      o_value              => o_value,
                                                      o_error              => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_value);
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
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_value);
            RETURN FALSE;
    END set_vital_sign;

    FUNCTION cancel_pat_periodic_obs
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_por   IN periodic_observation_reg.id_periodic_observation_reg%TYPE,
        o_error OUT t_error_out
        
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'CANCEL_PAT_PERIODIC_OBS';
    BEGIN
        g_error := 'call pk_periodic_observation.CANCEL_PAT_PERIODIC_OBS';
    
        pk_periodic_observation.cancel_pat_periodic_obs(i_prof => i_prof, i_por => i_por);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END cancel_pat_periodic_obs;

    /*  
    * Create periodic observation column by mcdt.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_flg_type_param      parameter flg type
    * @param i_patient             patient identifier
    * @param i_episode      episode identifier
    * @param i_dt_begin_str           column date
    * @param i_prof_req               prof request
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Jorge Silva
    * @version               2.6
    * @since                2013/07/18
    */
    FUNCTION create_column_by_mcdt
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_flg_type_param IN periodic_observation_reg.flg_type_param%TYPE,
        i_patient        IN patient.id_patient%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_dt_begin_str   IN VARCHAR2,
        i_prof_req       IN periodic_observation_reg.id_prof_writes%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'CREATE_COLUMN_BY_ANALISYS';
    BEGIN
        g_error := 'call pk_periodic_observation.SET_PAT_PERIODIC_OBSERVATION';
    
        pk_periodic_observation.set_pat_periodic_observation(i_lang           => i_lang,
                                                             i_prof           => i_prof,
                                                             i_flg_type_param => i_flg_type_param,
                                                             i_patient        => i_patient,
                                                             i_episode        => i_episode,
                                                             i_dt_begin_str   => i_dt_begin_str,
                                                             i_prof_req       => i_prof_req);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END create_column_by_mcdt;

    /*  
    * delete periodic observation column by mcdt.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_por          reg of periodic observation
    * @param i_episode      episode identifier
    * @param i_dt           column date
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author              Jorge Silva
    * @version               2.6
    * @since                2013/07/18
    */
    FUNCTION delete_column_by_mcdt
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_por   IN periodic_observation_reg.id_periodic_observation_reg%TYPE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'DELETE_PAT_PERIODIC_OBS';
    BEGIN
        g_error := 'call pk_periodic_observation.DELETE_PAT_PERIODIC_OBS';
    
        pk_periodic_observation.delete_pat_periodic_obs(i_por => i_por);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END delete_column_by_mcdt;

    FUNCTION get_grid_sets
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_task_type  IN VARCHAR2,
        o_title      OUT VARCHAR2,
        o_sets       OUT pk_types.cursor_type,
        o_param      OUT pk_types.cursor_type,
        o_sets_param OUT pk_types.cursor_type,
        o_time       OUT pk_types.cursor_type,
        o_value      OUT pk_types.cursor_type,
        o_ref        OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_GRID_SETS';
        o_values_wh t_coll_wh_values;
    BEGIN
        IF NOT pk_periodic_observation.get_grid_sets(i_lang       => i_lang,
                                                     i_prof       => i_prof,
                                                     i_patient    => i_patient,
                                                     i_episode    => i_episode,
                                                     i_task_type  => i_task_type,
                                                     o_title      => o_title,
                                                     o_sets       => o_sets,
                                                     o_param      => o_param,
                                                     o_sets_param => o_sets_param,
                                                     o_time       => o_time,
                                                     o_value      => o_value,
                                                     o_values_wh  => o_values_wh,
                                                     o_ref        => o_ref,
                                                     o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_cursor_if_closed(i_cursor => o_sets);
            pk_types.open_cursor_if_closed(i_cursor => o_param);
            pk_types.open_cursor_if_closed(i_cursor => o_sets_param);
            pk_types.open_cursor_if_closed(i_cursor => o_time);
            pk_types.open_cursor_if_closed(i_cursor => o_value);
            pk_types.open_cursor_if_closed(i_cursor => o_ref);
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
            pk_types.open_cursor_if_closed(i_cursor => o_sets);
            pk_types.open_cursor_if_closed(i_cursor => o_param);
            pk_types.open_cursor_if_closed(i_cursor => o_sets_param);
            pk_types.open_cursor_if_closed(i_cursor => o_time);
            pk_types.open_cursor_if_closed(i_cursor => o_value);
            pk_types.open_cursor_if_closed(i_cursor => o_ref);
            RETURN FALSE;
    END get_grid_sets;

    FUNCTION get_grid_comm_order
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_id_comm_order_plan IN comm_order_plan.id_comm_order_plan%TYPE,
        i_id_po_param_reg    IN po_param_reg.id_po_param_reg%TYPE,
        i_id_comm_order_req  IN comm_order_req.id_comm_order_req%type,
        o_title              OUT VARCHAR2,
        o_sets               OUT pk_types.cursor_type,
        o_param              OUT pk_types.cursor_type,
        o_sets_param         OUT pk_types.cursor_type,
        o_time               OUT pk_types.cursor_type,
        o_value              OUT pk_types.cursor_type,
        o_ref                OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'get_grid_comm_order';
        o_values_cor t_coll_wh_values;
    BEGIN
        IF NOT pk_periodic_observation.get_grid_comm_order(i_lang               => i_lang,
                                                           i_prof               => i_prof,
                                                           i_patient            => i_patient,
                                                           i_episode            => i_episode,
                                                           i_id_comm_order_plan => i_id_comm_order_plan,
                                                           i_id_po_param_reg    => i_id_po_param_reg,
                                                           i_id_comm_order_req  => i_id_comm_order_req,
                                                           o_title              => o_title,
                                                           o_sets               => o_sets,
                                                           o_param              => o_param,
                                                           o_sets_param         => o_sets_param,
                                                           o_time               => o_time,
                                                           o_value              => o_value,
                                                           o_values_wh          => o_values_cor,
                                                           o_ref                => o_ref,
                                                           o_error              => o_error)
        THEN
            RAISE g_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
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
            pk_types.open_cursor_if_closed(i_cursor => o_sets);
            pk_types.open_cursor_if_closed(i_cursor => o_param);
            pk_types.open_cursor_if_closed(i_cursor => o_sets_param);
            pk_types.open_cursor_if_closed(i_cursor => o_time);
            pk_types.open_cursor_if_closed(i_cursor => o_value);
            pk_types.open_cursor_if_closed(i_cursor => o_ref);
            RETURN FALSE;
    END get_grid_comm_order;

    FUNCTION create_column_comm_order
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_dt              IN VARCHAR2,
        i_task_type       IN task_type.id_task_type%TYPE,
        i_id_concept      IN comm_order_ea.id_concept%TYPE,
        o_show_warning    OUT VARCHAR2,
        o_title_warning   OUT VARCHAR2,
        o_message_warning OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF NOT pk_periodic_observation.create_column_comm_order(i_lang            => i_lang,
                                                                i_prof            => i_prof,
                                                                i_patient         => i_patient,
                                                                i_episode         => i_episode,
                                                                i_dt              => i_dt,
                                                                i_task_type       => i_task_type,
                                                                i_id_concept      => i_id_concept,
                                                                o_show_warning    => o_show_warning,
                                                                o_title_warning   => o_title_warning,
                                                                o_message_warning => o_message_warning,
                                                                o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'create_column_comm_order',
                                              o_error    => o_error);
        
            RETURN FALSE;
    END create_column_comm_order;

BEGIN
    pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    pk_alertlog.log_init(object_name => g_package);
END pk_periodic_observation_ux;
/
