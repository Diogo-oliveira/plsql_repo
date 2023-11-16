/*-- Last Change Revision: $Rev: 2028641 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:04 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_ea_logic_mtos IS

    -- Author  : SOFIA.MENDES
    -- Created : 4/29/2013 3:58:20 PM
    -- Purpose : This package should contain the easy access functions related to mtos_score functionality

    -- Public type declarations

    -- Public constant declarations
    g_src_table   CONSTANT VARCHAR2(20 CHAR) := 'EPIS_MTOS_SCORE';
    g_desc_type_s CONSTANT VARCHAR2(1 CHAR) := 'S';
    g_desc_type_l CONSTANT VARCHAR2(1 CHAR) := 'L';

    -- Public variable declarations
    CURSOR c_mtos(i_rowids IN table_varchar) IS
        SELECT ems.id_epis_mtos_score        id_epis_mtos_score,
               e.id_patient                  id_patient,
               ems.id_episode                id_episode,
               e.id_visit                    id_visit,
               e.id_institution              id_institution,
               ems.dt_create                 dt_create,
               ems.id_prof_create            id_prof_create,
               ems.dt_cancel                 dt_cancel,
               ems.flg_status                flg_status,
               e.flg_status                  flg_status_epis,
               ems.id_mtos_score,
               ems.id_epis_mtos_score_parent id_parent
          FROM epis_mtos_score ems
          JOIN episode e
            ON ems.id_episode = e.id_episode
         WHERE (i_rowids IS NULL OR (ems.rowid IN (SELECT /*+opt_estimate(table,t,scale_rows=1)*/
                                                    t.column_value row_id
                                                     FROM TABLE(i_rowids) t)));

    -- Public function and procedure declarations
    /**
    * Process insert/update events into TASK_TIMELINE_EA.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_event_type   event type
    * @param i_rowids       changed records rowids list
    * @param i_src_table    source table name
    * @param i_list_columns changed column names list
    * @param i_dg_table     easy access table name
    *
    * @author               Paulo Teixeira
    * @version               2.6.2
    * @since                2013/04/29
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

    FUNCTION mtos_score_has_parent(i_id_mtos_score IN mtos_score.id_mtos_score%TYPE) RETURN mtos_score.id_mtos_score%TYPE;

END pk_ea_logic_mtos;
/
