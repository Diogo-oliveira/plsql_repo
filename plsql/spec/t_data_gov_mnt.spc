/*-- Last Change Revision: $Rev: 2029420 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:51:34 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE t_data_gov_mnt IS
    -- This package supports the creation and maintenance of Data Governance tables.
    -- It provides a generic event signalling and processing framework that enables code decoupling
    -- between business logic and EA tables maintenance.
    -- @author Nuno Guerreiro
    -- @version 2.4.3-Denormalized

    /*
    * Validates the arguments passed on to an event procedure
    *
    * @param i_rowids                   List of ROWIDs belonging to the changed records.
    * @param i_source_table_name        Name of the table that was changed.
    * @param i_dg_table_name            Name of the Data Governance table to be changed.
    * @param i_expected_table_name      Name of the table that the procedure is expecting to receive.
    * @param i_expected_dg_table_name   Name of the Data Governance table that the procedure is expecting to update
    * @param i_list_columns             List of columns that were changed.
    * @param i_expected_columns         List of columns that the procedure is expecting to be modified.
    *
    * @return TRUE if all arguments match what the procedure was expecting, FALSE otherwise
    *
    * @author Nuno Guerreiro
    * @version 2.4.3-Denormalized
    * @since 2008/08/01
    */
    FUNCTION validate_arguments
    (
        i_rowids                 IN table_varchar,
        i_source_table_name      IN VARCHAR2,
        i_dg_table_name          IN VARCHAR2,
        i_expected_table_name    IN VARCHAR2,
        i_expected_dg_table_name IN VARCHAR2,
        i_list_columns           IN table_varchar DEFAULT NULL,
        i_expected_columns       IN table_varchar DEFAULT NULL
    ) RETURN BOOLEAN;

    /*
    * Searches the rowid's values for the given table filtering the result
    * by the given columns/values lists.
    *
    * @param i_table_name         Name of the table that was changed.
    * @param i_list_columns       List of PK column names.
    * @param i_list_values        List of PK column values.
    * @param o_rowids             List with the rowids
    * @param o_error              Error message (if an error occurred).
    *
    * @return TRUE if no error occurred, FALSE otherwise
    *
    * @author Alexandre Santos
    * @version 2.5
    * @since 2009/04/03
    */
    FUNCTION get_rowids
    (
        i_table_name   IN VARCHAR2,
        i_list_columns IN table_varchar,
        i_list_values  IN table_varchar,
        o_rowids       OUT table_varchar
    ) RETURN BOOLEAN;

    /**
    * This function returns true or false whether procedure process_update executes correctly or don't.
    * This allows for better error control.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_table_name         Name of the table that was changed.
    * @param i_rowids             Changed records' ROWIDs
    * @param o_error              Error message (if an error occurred).
    * @param i_list_columns       (Optional) Names of the columns that were affected.
    * @param i_flg_nzd            Flag to sinalize if it is the NZD process that is running
    *
    * @author Fábio Oliveira
    * @version 2.5.0.6
    * @since 2009/10/07
    */
    FUNCTION process_update
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_table_name   IN VARCHAR2,
        i_rowids       IN table_varchar,
        o_error        OUT t_error_out,
        i_list_columns IN table_varchar DEFAULT NULL,
        i_flg_nzd      IN VARCHAR2 DEFAULT 'N'
    ) RETURN BOOLEAN;

    /**
    * This procedure processes an update event, by calling all the procedures
    * associated with a change on table i_table_name and optionally on columns present
    * on i_list_columns.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_table_name         Name of the table that was changed.
    * @param i_rowids             Changed records' ROWIDs
    * @param o_error              Error message (if an error occurred).
    * @param i_list_columns       (Optional) Names of the columns that were affected.
    * @param i_flg_nzd            Flag to sinalize if it is the NZD process that is running
    *
    * @author Nuno Guerreiro
    * @version 2.4.3-Denormalized
    * @since 2008/10/02
    */
    PROCEDURE process_update
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_table_name   IN VARCHAR2,
        i_rowids       IN table_varchar,
        o_error        OUT t_error_out,
        i_list_columns IN table_varchar DEFAULT NULL,
        i_flg_nzd      IN VARCHAR2 DEFAULT 'N'
    );

    /**
    * This procedure processes an update event, by calling all the procedures
    * associated with a change on table i_table_name and optionally on columns present
    * on i_list_columns.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_table_name         Name of the table that was changed.
    * @param i_pk_list_columns    List of PK column names.
    * @param i_pk_list_values     List of PK column values.
    * @param o_error              Error message (if an error occurred).
    * @param i_list_columns       (Optional) Names of the columns that were affected.
    * @param i_flg_nzd            Flag to sinalize if it is the NZD process that is running
    *
    * @author Alexandre Santos
    * @version 2.5
    * @since 2009/04/03
    */
    PROCEDURE process_update
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_table_name      IN VARCHAR2,
        i_pk_list_columns IN table_varchar,
        i_pk_list_values  IN table_varchar,
        o_error           OUT t_error_out,
        i_list_columns    IN table_varchar DEFAULT NULL,
        i_flg_nzd         IN VARCHAR2 DEFAULT 'N'
    );

    /**
    * This function returns true or false whether procedure process_delete executes correctly or don't.
    * This allows for better error control.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_table_name         Name of the table that was changed.
    * @param i_rowids             Changed records' ROWIDs
    * @param o_error              Error message (if an error occurred).
    * @param i_list_columns       (Optional) Names of the columns that were affected.
    * @param i_flg_nzd            Flag to sinalize if it is the NZD process that is running
    *
    * @author Fábio Oliveira
    * @version 2.5.0.6
    * @since 2009/10/07
    */
    FUNCTION process_delete
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_table_name   IN VARCHAR2,
        i_rowids       IN table_varchar,
        o_error        OUT t_error_out,
        i_list_columns IN table_varchar DEFAULT NULL,
        i_flg_nzd      IN VARCHAR2 DEFAULT 'N'
    ) RETURN BOOLEAN;

    /**
    * This procedure processes a delete event, by calling all the procedures
    * associated with a change on table i_table_name and optionally on columns present
    * on i_list_columns.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_table_name         Name of the table that was changed.
    * @param i_rowids             Changed records' ROWIDs
    * @param o_error              Error message (if an error occurred).
    * @param i_list_columns       (Optional) Names of the columns that were affected.
    * @param i_flg_nzd            Flag to sinalize if it is the NZD process that is running
    *
    * @author Nuno Guerreiro
    * @version 2.4.3-Denormalized
    * @since 2008/10/02
    */
    PROCEDURE process_delete
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_table_name   IN VARCHAR2,
        i_rowids       IN table_varchar,
        o_error        OUT t_error_out,
        i_list_columns IN table_varchar DEFAULT NULL,
        i_flg_nzd      IN VARCHAR2 DEFAULT 'N'
    );

    /**
    * This procedure processes a delete event, by calling all the procedures
    * associated with a change on table i_table_name and optionally on columns present
    * on i_list_columns.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_table_name         Name of the table that was changed.
    * @param i_pk_list_columns    List of PK column names.
    * @param i_pk_list_values     List of PK column values.
    * @param o_error              Error message (if an error occurred).
    * @param i_list_columns       (Optional) Names of the columns that were affected.
    * @param i_flg_nzd            Flag to sinalize if it is the NZD process that is running
    *
    * @author Alexandre Santos
    * @version 2.4.3-Denormalized
    * @since 2009/04/03
    */
    PROCEDURE process_delete
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_table_name      IN VARCHAR2,
        i_pk_list_columns IN table_varchar,
        i_pk_list_values  IN table_varchar,
        o_error           OUT t_error_out,
        i_list_columns    IN table_varchar DEFAULT NULL,
        i_flg_nzd         IN VARCHAR2 DEFAULT 'N'
    );

    /**
    * This function returns true or false whether procedure process_insert executes correctly or don't.
    * This allows for better error control.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_table_name         Name of the table that was changed.
    * @param i_rowids             Changed records' ROWIDs
    * @param o_error              Error message (if an error occurred).
    * @param i_list_columns       (Optional) Names of the columns that were affected.
    * @param i_flg_nzd            Flag to sinalize if it is the NZD process that is running
    *
    * @author Fábio Oliveira
    * @version 2.5.0.6
    * @since 2009/10/07
    */
    FUNCTION process_insert
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_table_name   IN VARCHAR2,
        i_rowids       IN table_varchar,
        o_error        OUT t_error_out,
        i_list_columns IN table_varchar DEFAULT NULL,
        i_flg_nzd      IN VARCHAR2 DEFAULT 'N'
    ) RETURN BOOLEAN;

    /**
    * This procedure processes an insert event, by calling all the procedures
    * associated with a change on table i_table_name and optionally on columns present
    * on i_list_columns.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_table_name         Name of the table that was changed.
    * @param i_rowids             Changed records' ROWIDs
    * @param o_error              Error message (if an error occurred).
    * @param i_list_columns       (Optional) Names of the columns that were affected.
    * @param i_flg_nzd            Flag to sinalize if it is the NZD process that is running
    *
    * @author Nuno Guerreiro
    * @version 2.4.3-Denormalized
    * @since 2008/10/02
    */
    PROCEDURE process_insert
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_table_name   IN VARCHAR2,
        i_rowids       IN table_varchar,
        o_error        OUT t_error_out,
        i_list_columns IN table_varchar DEFAULT NULL,
        i_flg_nzd      IN VARCHAR2 DEFAULT 'N'
    );

    /**
    * This procedure processes an insert event, by calling all the procedures
    * associated with a change on table i_table_name and optionally on columns present
    * on i_list_columns.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_table_name         Name of the table that was changed.
    * @param i_pk_list_columns    List of PK column names.
    * @param i_pk_list_values     List of PK column values.
    * @param o_error              Error message (if an error occurred).
    * @param i_list_columns       (Optional) Names of the columns that were affected.
    * @param i_flg_nzd            Flag to sinalize if it is the NZD process that is running
    *
    * @author Alexandre Santos
    * @version 2.5
    * @since 2009/04/03
    */
    PROCEDURE process_insert
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_table_name      IN VARCHAR2,
        i_pk_list_columns IN table_varchar,
        i_pk_list_values  IN table_varchar,
        o_error           OUT t_error_out,
        i_list_columns    IN table_varchar DEFAULT NULL,
        i_flg_nzd         IN VARCHAR2 DEFAULT 'N'
    );

    PROCEDURE chck_consistency
    (
        i_prof              IN profissional,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2
    );

    /**
    * This procedure inserts/updates records in data_gov_event table
    *
    * @param i_source_owner          Source table owner
    * @param i_source_table_name     Source table name
    * @param i_source_column_name    Source column name
    * @param i_dg_owner              Destination table owner
    * @param i_dg_table_name         Destination table name
    * @param i_flg_enabled           Flag enabled
    * @param i_flg_background        Flag background
    * @param i_flg_iud               Flag IUD (has default value)
    * @param i_exec_procedure        Exec procedure
    * @param i_exec_order            Execution order
    * @param i_id_software           Software identifier
    *
    * @author Rui Spratley
    * @version 2.6.4.3
    * @since 2014/11/11
    */
    PROCEDURE upd_ins_data_gov_event
    (
        i_source_owner       IN VARCHAR2 DEFAULT NULL,
        i_source_table_name  IN VARCHAR2 DEFAULT NULL,
        i_source_column_name IN VARCHAR2 DEFAULT NULL,
        i_dg_owner           IN VARCHAR2 DEFAULT NULL,
        i_dg_table_name      IN VARCHAR2 DEFAULT NULL,
        i_flg_enabled        IN VARCHAR2,
        i_flg_background     IN VARCHAR2,
        i_flg_iud            IN VARCHAR2 DEFAULT 'IUD',
        i_exec_procedure     IN VARCHAR2,
        i_exec_order         IN VARCHAR2,
        i_id_software        IN NUMBER
    );

    ---------------------------------------- GLOBAL VALUES ----------------------------------------------

    /* Disclamer: constant values were not moved to PK_ALERT_CONSTANT, as they are not related with business rules */

    /* Event type: UPDATE */
    g_event_update CONSTANT VARCHAR2(1) := 'U';
    /* Event type: INSERT */
    g_event_insert CONSTANT VARCHAR2(1) := 'I';
    /* Event type: DELETE */
    g_event_delete CONSTANT VARCHAR2(1) := 'D';
    /* Event type: MERGE */
    g_event_merge CONSTANT VARCHAR2(1) := 'M';
    /* Event type: CANCEL */
    g_event_cancel CONSTANT VARCHAR2(1) := 'C';

    /* 'Yes' flag */
    g_yes CONSTANT VARCHAR2(1) := 'Y';

    /* 'No' flag */
    g_no CONSTANT VARCHAR2(1) := 'N';

    /* Current timestamp */
    g_sysdate_tstz TIMESTAMP WITH TIME ZONE;

    /* Error marker */
    g_error VARCHAR2(4000);

    /* Prefix for creating DBMS_SCHEDULER programs */
    g_data_gov_program_prefix VARCHAR2(32) := 'DATA_GOV_MNT_P';

    /* Prefix for creating DBMS_SCHEDULER jobs */
    g_data_gov_job_prefix VARCHAR2(32) := 'DATA_GOV_MNT_J';

    /* Invalid arguments */
    g_excp_invalid_arguments EXCEPTION;

    /* Package name */
    g_package_name  VARCHAR2(30 CHAR);
    g_package_owner VARCHAR2(30 CHAR);
END t_data_gov_mnt;
/
