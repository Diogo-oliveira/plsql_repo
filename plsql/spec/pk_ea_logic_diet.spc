/*-- Last Change Revision: $Rev: 1744286 $*/
/*-- Last Change by: $Author: vanessa.barsottelli $*/
/*-- Date of last change: $Date: 2016-06-29 14:33:41 +0100 (qua, 29 jun 2016) $*/

CREATE OR REPLACE PACKAGE pk_ea_logic_diet IS

    /**
    * Process insert/update events on EPIS_DIET_REQ into TASK_TIMELINE_EA.
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

    PROCEDURE call_diet_inter_alert
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_event_type   IN VARCHAR2,
        i_rowids       IN table_varchar,
        i_src_table    IN VARCHAR2,
        i_list_columns IN table_varchar,
        i_dg_table     IN VARCHAR2
    );

END pk_ea_logic_diet;
/
