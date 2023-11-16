/*-- Last Change Revision: $Rev: 2028783 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:54 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_logic_prog_notes IS

    -- Author  : VANESSA.BARSOTTELLI
    -- Created : 19/05/2016 09:50:50
    -- Purpose : Progress note logic

    -- Public function and procedure declarations
    PROCEDURE set_physician_note
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_event_type   IN VARCHAR2,
        i_rowids       IN table_varchar,
        i_src_table    IN VARCHAR2,
        i_list_columns IN table_varchar,
        i_dg_table     IN VARCHAR2
    );

    /* Package name */
    g_package_name  VARCHAR2(32);
    g_package_owner VARCHAR2(32);

    /* Error tracking */
    g_error VARCHAR2(4000);

END pk_logic_prog_notes;
/
