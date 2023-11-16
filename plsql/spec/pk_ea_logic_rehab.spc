CREATE OR REPLACE PACKAGE pk_ea_logic_rehab IS
    /*
    * Sets the timeline table
    *
    * @param     i_lang                Language id
    * @param     i_prof                Professional
    * @param     i_event_type          Event type
    * @param     i_rowids              Row ids
    * @param     i_source_table_name   Source table name
    * @param     i_list_columns        List of columns
    * @param     i_dg_table_name       Target table name
    
    *
    * @author    Ana Moita
    * @version   2.8.4
    * @since     2021/11/16
    */

    PROCEDURE set_task_timeline_treat
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );
    PROCEDURE set_task_timeline_icf
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    ---------------------------------------- GLOBAL VALUES ----------------------------------------------

    /* Package name */
    g_package_name  VARCHAR2(32);
    g_package_owner VARCHAR2(32);

    /* Error tracking */
    g_error VARCHAR2(4000);

    /* Invalid event type */
    g_excp_invalid_event_type EXCEPTION;

END pk_ea_logic_rehab;
/
