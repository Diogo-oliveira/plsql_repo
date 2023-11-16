/*-- Last Change Revision: $Rev: 1376969 $*/
/*-- Last Change by: $Author: nuno.neves $*/
/*-- Date of last change: $Date: 2012-09-17 12:28:39 +0100 (seg, 17 set 2012) $*/

CREATE OR REPLACE PACKAGE pk_ea_logic_nurse_tea IS

    /**
    * Process insert/update events on Patient education into TASK_TIMELINE_EA.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_event_type   event type
    * @param i_rowids       changed records rowids list
    * @param i_src_table    source table name
    * @param i_list_columns changed column names list
    * @param i_dg_table     easy access table name
    *
    * @author               Nuno Neves
    * @version              2.6.2
    * @since                2012/09/14
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

END pk_ea_logic_nurse_tea;
/