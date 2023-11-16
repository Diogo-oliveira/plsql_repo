/*-- Last Change Revision: $Rev: 1714789 $*/
/*-- Last Change by: $Author: paulo.teixeira $*/
/*-- Date of last change: $Date: 2015-11-06 09:28:10 +0000 (sex, 06 nov 2015) $*/

CREATE OR REPLACE PACKAGE pk_ea_logic_hidrics IS

    /**
    * Process insert/update events on EPIS_HIDRICS into TASK_TIMELINE_EA.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_event_type   event type
    * @param i_rowids       changed records rowids list
    * @param i_src_table    source table name
    * @param i_list_columns changed column names list
    * @param i_dg_table     easy access table name
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2012/04/20
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
    PROCEDURE set_grid_task_hidrics
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );
    FUNCTION get_data_rowid
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_table_name IN VARCHAR,
        i_table_ea   IN VARCHAR,
        i_rowids     IN table_varchar,
        o_rowids     OUT table_varchar,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    PROCEDURE ins_grid_task_hidrics
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_rowids IN table_varchar
    );
    PROCEDURE ins_grid_task_hidrics_epis
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN grid_task.id_episode%TYPE
    );
END pk_ea_logic_hidrics;
/
