/*-- Last Change Revision: $Rev: 2028652 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:07 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_ea_logic_supply IS

    /*
    * Updates the grid task for supplies columns
    *
    * @param     i_lang                Language id
    * @param     i_prof                Professional
    * @param     i_event_type          Type of event (UPDATE, INSERT, etc)
    * @param     i_rowids              List of ROWIDs belonging to the changed records.
    * @param     i_list_columns        List of columns that were changed
    * @param     i_source_table_name   Name of the table that was changed.
    * @param     i_dg_table_name       Name of the Data Governance table.
    *
    * @author    Filipe Silva
    * @version   2.6.0.4
    * @since     2010/10/29
    */

    PROCEDURE set_grid_task_supplies
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    /*
    * Process insert/update events on SUPPLY_WORKFLOW into TASK_TIMELINE_EA.
    *
    * @param     i_lang           Language id
    * @param     i_prof           Professional
    * @param     i_event_type     Event type
    * @param     i_rowids         Changed records rowids list
    * @param     i_src_table      Source table name
    * @param     i_list_columns   Changed column names list
    * @param     i_dg_table       Easy access table name
    *
    * @author    Kelsey Lai
    * @version   2.7.2
    * @since     2017/12/28
    */

    PROCEDURE set_task_timeline
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_event_type   IN VARCHAR2,
        i_rowids       IN table_varchar,
        i_src_table    IN VARCHAR2,
        i_list_columns IN table_varchar,
        i_dg_table     IN VARCHAR2
    );

    g_owner        VARCHAR2(10 CHAR) := 'ALERT';
    g_package      VARCHAR(20 CHAR) := 'PK_EA_LOGIC_SUPPLY';
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_error        VARCHAR2(1000 CHAR);
    g_excp_invalid_event_type EXCEPTION;
END pk_ea_logic_supply;
/
