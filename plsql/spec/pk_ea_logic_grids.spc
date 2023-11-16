/*-- Last Change Revision: $Rev: 2028636 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:02 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_ea_logic_grids IS

    -- Author  : FABIO.OLIVEIRA
    -- Created : 31-08-2009 14:29:37
    -- Purpose : Package for managing events for grids_ea table

    -- Public function and procedure declarations

    /**
    * Procedure that processes an update event on EPISODE
    *
    * @param   i_lang                Language ID
    * @param   i_prof                Professional context information
    * @value   i_event_type          Type of update event
    * @param   i_rowids              Table containing updated rowids
    * @param   i_source_table_name   Updated table name
    * @param   i_list_columns        Table containing updated table columns
    * @param   i_dg_table_name       Listening table ('GRIDS_EA')
    *
    * @author  Fábio Oliveira
    * @version 2.5.0.5
    * @since   03/09/2009
    */
    PROCEDURE set_episode
    (
        i_lang              IN LANGUAGE.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    /**
    * Procedure that processes an update event on EPIS_INFO
    *
    * @param   i_lang                Language ID
    * @param   i_prof                Professional context information
    * @value   i_event_type          Type of update event
    * @param   i_rowids              Table containing updated rowids
    * @param   i_source_table_name   Updated table name
    * @param   i_list_columns        Table containing updated table columns
    * @param   i_dg_table_name       Listening table ('GRIDS_EA')
    *
    * @author  Fábio Oliveira
    * @version 2.5.0.5
    * @since   03/09/2009
    */
    PROCEDURE set_epis_info
    (
        i_lang              IN LANGUAGE.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    /**
    * Procedure that processes an update event on ANNOUNCED_ARRIVAL
    *
    * @param   i_lang                Language ID
    * @param   i_prof                Professional context information
    * @value   i_event_type          Type of update event
    * @param   i_rowids              Table containing updated rowids
    * @param   i_source_table_name   Updated table name
    * @param   i_list_columns        Table containing updated table columns
    * @param   i_dg_table_name       Listening table ('GRIDS_EA')
    *
    * @author  Alexandre Santos
    * @version 2.5.0.7
    * @since   27/10/2009
    */
    PROCEDURE set_announced_arrival
    (
        i_lang              IN LANGUAGE.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    /**
    * Procedure that processes an update event on TRANSFER_INSTITUTION
    *
    * @param   i_lang                Language ID
    * @param   i_prof                Professional context information
    * @value   i_event_type          Type of update event
    * @param   i_rowids              Table containing updated rowids
    * @param   i_source_table_name   Updated table name
    * @param   i_list_columns        Table containing updated table columns
    * @param   i_dg_table_name       Listening table ('GRIDS_EA')
    *
    * @author  José Brito
    * @version 2.5.1
    * @since   16-May-2011
    */
    PROCEDURE set_transfer_institution
    (
        i_lang              IN LANGUAGE.id_language%TYPE,
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

    /* Error info */
    g_error VARCHAR2(400);

    e_update_error EXCEPTION;
    e_filter_error EXCEPTION;

END pk_ea_logic_grids;
/
