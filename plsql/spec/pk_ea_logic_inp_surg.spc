/*-- Last Change Revision: $Rev: 2028637 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:02 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE pk_ea_logic_inp_surg IS

    /**
    * Process insert/update events on ADMIN_REQUEST into TASK_TIMELINE_EA.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_event_type   event type
    * @param i_rowids       changed records rowids list
    * @param i_src_table    source table name
    * @param i_list_columns changed column names list
    * @param i_dg_table     easy access table name
    *
    * @author               JORGE SILVA
    * @version               2.6.2
    * @since                2012/09/03
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
    
    /* Invalid event type */
    g_excp_invalid_event_type EXCEPTION;

END pk_ea_logic_inp_surg;
/
