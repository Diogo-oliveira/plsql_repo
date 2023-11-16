/*-- Last Change Revision: $Rev: 1689419 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2015-03-18 14:47:46 +0000 (qua, 18 mar 2015) $*/

CREATE OR REPLACE PACKAGE pk_ea_logic_tracking_board IS

    ---------------------------------------- GLOBAL VALUES ----------------------------------------------

    /**
    * Count the number of not null timestamps inside the given array.
    *
    * @param i_timestamp_list Array with timestamps
    *
    * @return The number of not null elements
    *
    * @author Eduardo Lourenco
    * @version 2.4.3-Denormalized
    * @since 2008/10/20
    */
    FUNCTION count_not_nulls(i_timestamp_list IN table_varchar) RETURN NUMBER;

    /**
    * Inserts or Updates Analysis related fields in the TRACKING BOARD EA table.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, DELETE)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author Eduardo Lourenco
    * @version 2.4.3-Denormalized
    * @since 2008/10/17
    */
    PROCEDURE set_exam
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    PROCEDURE set_episode
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    /**
    * Inserts or Updates Analysis related fields in the TRACKING BOARD EA table.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, DELETE)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author Eduardo Lourenco
    * @version 2.4.3-Denormalized
    * @since 2008/10/17
    */
    PROCEDURE set_analysis
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    /**
    * Inserts or Updates Transport related fields in the TRACKING BOARD EA table.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, DELETE)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author Eduardo Lourenco
    * @version 2.4.3-Denormalized
    * @since 2008/10/21
    */
    PROCEDURE set_transport
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    /**
    * Inserts or Updates Facility Transfer related fields in the TRACKING BOARD EA table.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, DELETE)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author José Brito
    * @version 2.5.1
    * @since 17-May-2011
    */
    PROCEDURE set_transfer_institution
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    PROCEDURE update_ea_logic_opinion
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode_list table_number
    );

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

    /* Current timestamp */
    g_sysdate_tstz TIMESTAMP WITH TIME ZONE;

    /* Package name */
    g_package_name VARCHAR2(30);

    /* Error tracking */
    g_error VARCHAR2(4000);
END pk_ea_logic_tracking_board;
/
