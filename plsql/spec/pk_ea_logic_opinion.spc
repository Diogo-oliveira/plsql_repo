/*-- Last Change Revision: $Rev: 2028642 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:04 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_ea_logic_opinion IS

    /**
    * Translates an id_opinion_type into a task_type.
    *
    * @param i_id_opinion_type  opinion_type identifier
    *
    * @return               The traslated id_task_type
    *
    * @author               Sérgio Santos
    * @version               2.6.2
    * @since                2012/08/08
    */
    FUNCTION get_id_tt_from_id_op_type(i_id_opinion_type opinion_type.id_opinion_type%TYPE)
        RETURN task_type.id_task_type%TYPE;

    /**
    * Translates an task_type into a id_opinion_type.
    *
    * @param id_task_type  tak_type identifier
    *
    * @return               The traslated id_opinion_type
    *
    * @author               Sérgio Santos
    * @version               2.6.2
    * @since                2012/08/08
    */
    FUNCTION get_id_op_type_from_id_tt(id_task_type task_type.id_task_type%TYPE) RETURN opinion_type.id_opinion_type%TYPE;

    /**
    * Process insert/update events on OPINION into TASK_TIMELINE_EA.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_event_type   event type
    * @param i_rowids       changed records rowids list
    * @param i_src_table    source table name
    * @param i_list_columns changed column names list
    * @param i_dg_table     easy access table name
    *
    * @author               Sérgio Santos
    * @version               2.6.2
    * @since                2012/08/08
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

END pk_ea_logic_opinion;
/
