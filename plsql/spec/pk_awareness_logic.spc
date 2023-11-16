/*-- Last Change Revision: $Rev: 2028506 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:12 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_awareness_logic IS

    -- Author  : PEDRO.TEIXEIRA
    -- Created : 02/10/2008
    -- Purpose : Awareness logic processing

    -- Public type declarations

    /**
    * Get id_patient and id_episode based on rowid and table_name
    *
    * @param i_lang               Language
    * @param i_table_name         Table Name
    * @param i_rowids             ROWID of the i_table_name
    * @param o_patient            returned id_patien
    * @param o_episode            returned id_episode
    * @param o_error              Error message
    *
    * @author Pedro Teixeira
    * @version 2.4.3-Denormalized
    * @since 02/10/2008
    */

    FUNCTION get_patient_episode
    (
        i_lang        IN language.id_language%TYPE,
        i_table_name  IN VARCHAR2,
        i_rowid       IN VARCHAR2,
        o_patient     OUT table_number,
        o_episode     OUT table_number,
        o_visit       OUT table_number,
        o_column_name OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Verifies if the specified table belongs to the Awareness context
    *
    * @param i_table_name         Table Name
    *
    * @author Pedro Teixeira
    * @version 2.4.3-Denormalized
    * @since 03/10/2008
    */
    FUNCTION lookup_table(i_table_name IN VARCHAR2) RETURN BOOLEAN;

    /**
    * Process Awareness event logic / Package main entry function
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, etc)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author Rita Lopes
    * @version 2.4.3-Denormalized
    * @since 2008/09/26
    */
    PROCEDURE process_event_logic
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
    * Inserts or updates awareness record bases on id_patient, id_episode and table_name
    *
    * @param i_patient            id_patien
    * @param i_episode            id_episode
    * @param i_table_name         Table Name
    *
    * @author Pedro Teixeira
    * @version 2.4.3-Denormalized
    * @since 03/10/2008
    */
    PROCEDURE awareness_tbl_upd
    (
        i_patient    table_number,
        i_episode    table_number,
        i_visit      table_number,
        i_table_name IN VARCHAR2
    );

    ---------------------------------------- GLOBAL VALUES ----------------------------------------------

    /* Current timestamp */
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;

    /* Package name */
    g_package_name CONSTANT VARCHAR2(30) := pk_alertlog.who_am_i;

END pk_awareness_logic;
/
