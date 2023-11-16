/*-- Last Change Revision: $Rev: 2028631 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:00 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE pk_ea_logic_body_diagram IS

    /**
    * Process insert/update events on SCHEDULE_SR into TASK_TIMELINE_EA.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_event_type   event type
    * @param i_rowids       changed records rowids list
    * @param i_src_table    source table name
    * @param i_list_columns changed column names list
    * @param i_dg_table     easy access table name
    *
    * @author               Vanessa Barsottelli
    * @version              2.6.5
    * @since                19/02/2016
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
    /********************************************************************************************
    * Get BODY DIAGRAM description
    *
    * @param i_lang                 Language
    * @param i_prof                 professional/institution/software
    * @param i_id_epis_diagram       BODY DIAGRAM identifier
    *
    * @return                       Returns the surgery request information
    *
    * @author    Paulo Teixeira
    * @version   2.6.5
    * @since     05/07/2016
    *********************************************************************************************/
    FUNCTION get_body_diagram_description
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_diagram IN epis_diagram.id_epis_diagram%TYPE
    ) RETURN CLOB;
    /* Invalid event type */
    g_excp_invalid_event_type EXCEPTION;

END pk_ea_logic_body_diagram;
/