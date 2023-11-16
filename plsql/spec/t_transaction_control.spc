/*-- Last Change Revision: $Rev: 2029424 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:51:35 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE t_transaction_control IS
    -- This package centralizes transaction control, in order to remove explicit rollbacks and commits.
    -- @author Nuno Guerreiro
    -- @version 2.4.3-Denormalized

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
    );

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
    );

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
    FUNCTION is_transaction_ctl_enabled(i_context VARCHAR2 DEFAULT NULL) RETURN BOOLEAN;

    /**
    * This procedure commits work if transaction control is enabled.
    *
    * @param i_context           Name of the context to use. If no configuration is found for this context, the default configuration is used
    *
    * @author Nuno Guerreiro
    * @version 2.4.3-Denormalized
    * @since 2008/08/04
    */
    PROCEDURE COMMIT(i_context VARCHAR2 DEFAULT NULL);

    /**
    * This procedure rolls back work if transaction control is enabled.
    *
    * @param i_context           Name of the context to use. If no configuration is found for this context, the default configuration is used
    *
    * @author Nuno Guerreiro
    * @version 2.4.3-Denormalized
    * @since 2008/08/04
    */
    PROCEDURE ROLLBACK(i_context VARCHAR2 DEFAULT NULL);

    ---------------------------------------- GLOBAL VALUES ----------------------------------------------

    /* Associative array type for storing boolean values */
    TYPE t_assoc_boolean IS TABLE OF BOOLEAN INDEX BY VARCHAR2(200);

    /* Transaction control status */
    g_trx_ctl_status t_assoc_boolean;

    /* Default transaction control status */
    g_default_trx_ctl_status BOOLEAN;

    /* Error marker */
    g_error VARCHAR2(4000);

    /* Package name */
    g_package_name VARCHAR2(30);
END t_transaction_control;
/
