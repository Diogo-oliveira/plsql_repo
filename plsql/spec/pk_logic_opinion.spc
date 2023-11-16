/*-- Last Change Revision: $Rev: 1689419 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2015-03-18 14:47:46 +0000 (qua, 18 mar 2015) $*/

CREATE OR REPLACE PACKAGE pk_logic_opinion IS

    -- Author  : THIAGO.BRITO
    -- Created : 13-10-2008 14:25:33
    PROCEDURE get_opinion_status
    (
        i_prof        IN profissional,
        i_flg_state   IN opinion.flg_state%TYPE,
        o_status_str  OUT opinion.status_str%TYPE,
        o_status_msg  OUT opinion.status_msg%TYPE,
        o_status_icon OUT opinion.status_icon%TYPE,
        o_status_flg  OUT opinion.status_flg%TYPE
    );

    /**
    * Opinion Logic entry funtion
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, etc)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author Pedro Teixeira
    * @version 2.4.3.d
    * @since 2008-Oct-14
    */
    PROCEDURE set_opinion
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    PROCEDURE set_grid_task
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    /* Package name */
    g_package_name  VARCHAR2(32);
    g_package_owner VARCHAR2(32);

    /* Error tracking */
    g_error VARCHAR2(4000);

    /* Invalid event type */
    g_exception EXCEPTION;

END pk_logic_opinion;
/
