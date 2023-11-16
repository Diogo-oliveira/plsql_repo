/*-- Last Change Revision: $Rev: 2028430 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:45:43 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY t_transaction_control IS
    -- This package centralizes transaction control, in order to remove explicit rollbacks and commits.
    -- @author Nuno Guerreiro
    -- @version 2.4.3-Denormalized

    ----------------------------------------------- PUBLIC ------------------------------------------------

    /**
    * This procedure enables/disables transaction control.
    * Transaction control can be enabled/disabled for the default context
    * or for specific contexts.
    *
    * @param i_enable            If true transaction control is enabled, otherwise transaction control is disabled.
    * @param i_context           Name of the context to enable/disable transaction control for.
    *
    *
    * @author Nuno Guerreiro
    * @version 2.4.3-Denormalized
    * @since 2008/08/04
    */
    PROCEDURE set_transaction_ctl_enabled
    (
        i_enable  BOOLEAN,
        i_context VARCHAR2 DEFAULT NULL
    ) IS
        l_func_proc_name VARCHAR2(30);
    BEGIN
        g_error          := 'CALL SET_TRANSACTION_CTL_ENABLED';
        l_func_proc_name := 'SET_TRANSACTION_CTL_ENABLED(B)';
    
        -- Set transaction control
        set_transaction_ctl_enabled(sys.diutil.bool_to_int(i_enable), i_context);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.error_handling(i_func_proc_name => l_func_proc_name,
                                               i_package_name   => g_package_name,
                                               i_package_error  => g_error,
                                               i_sql_error      => SQLERRM);
            RAISE;
    END set_transaction_ctl_enabled;

    /**
    * This procedure enables/disables transaction control.
    * Transaction control can be enabled/disabled for the default context
    * or for specific contexts.
    *
    * @param i_enable            If 1 is passed as argument transaction control is enabled. If 0 is passed as argument, transaction control is disabled.
    * @param i_context           Name of the context to enable/disable transaction control for.
    *
    *
    * @author Nuno Guerreiro
    * @version 2.4.3-Denormalized
    * @since 2008/08/04
    */
    PROCEDURE set_transaction_ctl_enabled
    (
        i_enable  NUMBER,
        i_context VARCHAR2 DEFAULT NULL
    ) IS
        l_func_proc_name VARCHAR2(30);
    BEGIN
        g_error          := 'START';
        l_func_proc_name := 'SET_TRANSACTION_CTL_ENABLED(N)';
    
        IF i_context IS NULL
        THEN
            -- If no context is given, use the default context
            g_error := 'SET DEFAULT';
            pk_alertlog.log_debug('Setting default transaction control: value = ' || i_enable || ';',
                                  g_package_name,
                                  l_func_proc_name);
            g_default_trx_ctl_status := sys.diutil.int_to_bool(i_enable);
        ELSE
            -- Set transaction control for a specific context
            g_error := 'SET CONTEXT: ' || i_context;
            pk_alertlog.log_debug('Setting transaction control: value: ' || i_enable || '; context = ' || i_context || ';',
                                  g_package_name,
                                  l_func_proc_name);
            g_trx_ctl_status(i_context) := sys.diutil.int_to_bool(i_enable);
        END IF;
    EXCEPTION
        WHEN value_error THEN
            pk_alert_exceptions.error_handling(i_func_proc_name => l_func_proc_name,
                                               i_package_name   => g_package_name,
                                               i_package_error  => 'Use 1 or 0 as i_enable parameter only - ' || g_error,
                                               i_sql_error      => SQLERRM);
            RAISE;
        WHEN OTHERS THEN
            pk_alert_exceptions.error_handling(i_func_proc_name => l_func_proc_name,
                                               i_package_name   => g_package_name,
                                               i_package_error  => g_error,
                                               i_sql_error      => SQLERRM);
            RAISE;
    END set_transaction_ctl_enabled;

    /**
    * Checks if transaction control is enabled for a given context or for the default context.
    *
    * @param i_context           Context name. If null, the default context is used instead
    *
    * @return                    True if transaction control is enabled, false otherwise
    *
    * @author Nuno Guerreiro
    * @version 2.4.3-Denormalized
    * @since 2008/08/04
    */
    FUNCTION is_transaction_ctl_enabled(i_context VARCHAR2 DEFAULT NULL) RETURN BOOLEAN IS
        l_ret BOOLEAN;
    BEGIN
        l_ret := g_default_trx_ctl_status;
        -- If the given context is configured use its value, otherwise just use the default.
        IF i_context IS NOT NULL
        THEN
            BEGIN
                l_ret := g_trx_ctl_status(i_context);
            EXCEPTION
                WHEN no_data_found THEN
                    NULL;
            END;
        END IF;
    
        RETURN l_ret;
    END is_transaction_ctl_enabled;

    /**
    * This procedure commits work if transaction control is enabled.
    *
    * @param i_context           Name of the context to use. If no configuration is found for this context, the default configuration is used
    *
    * @author Nuno Guerreiro
    * @version 2.4.3-Denormalized
    * @since 2008/08/04
    */
    PROCEDURE COMMIT(i_context VARCHAR2 DEFAULT NULL) IS
        l_func_proc_name VARCHAR2(30);
    BEGIN
        g_error          := 'START';
        l_func_proc_name := 'COMMIT';
    
        -- Commit work if transaction control is enabled
        IF is_transaction_ctl_enabled(i_context)
        THEN
            g_error := 'COMMIT';
            COMMIT;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.error_handling(i_func_proc_name => l_func_proc_name,
                                               i_package_name   => g_package_name,
                                               i_package_error  => g_error,
                                               i_sql_error      => SQLERRM);
            RAISE;
    END;

    /**
    * This procedure rolls back work if transaction control is enabled.
    *
    * @param i_context           Name of the context to use. If no configuration is found for this context, the default configuration is used
    *
    * @author Nuno Guerreiro
    * @version 2.4.3-Denormalized
    * @since 2008/08/04
    */
    PROCEDURE ROLLBACK(i_context VARCHAR2 DEFAULT NULL) IS
        l_func_proc_name VARCHAR2(30);
    BEGIN
        g_error          := 'START';
        l_func_proc_name := 'ROLLBACK';
    
        -- Rollback work if transaction control is enabled
        IF is_transaction_ctl_enabled(i_context)
        THEN
            g_error := 'ROLLBACK';
            ROLLBACK;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.error_handling(i_func_proc_name => l_func_proc_name,
                                               i_package_name   => g_package_name,
                                               i_package_error  => g_error,
                                               i_sql_error      => SQLERRM);
            RAISE;
    END;

BEGIN
    -- Enable default transaction control for now.
    -- This can be latter changed, for instance, to read a SYS_CONFIG value.
    g_default_trx_ctl_status := TRUE;

    -- Log initialization.
    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);
END t_transaction_control;
/
