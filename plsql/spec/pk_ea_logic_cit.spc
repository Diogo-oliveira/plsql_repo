/*-- Last Change Revision: $Rev: 1489814 $*/
/*-- Last Change by: $Author: sofia.mendes $*/
/*-- Date of last change: $Date: 2013-07-17 11:16:54 +0100 (qua, 17 jul 2013) $*/

CREATE OR REPLACE PACKAGE pk_ea_logic_cit IS

    -- Author  : SOFIA.MENDES
    -- Created : 4/29/2013 3:58:20 PM
    -- Purpose : This package should contain the easy access functions related to cits functionality

    -- Public type declarations

    -- Public constant declarations
    g_cits_src_table CONSTANT VARCHAR2(11 CHAR) := 'PAT_CIT';
    g_desc_type_s    CONSTANT VARCHAR2(1 CHAR) := 'S';
    g_desc_type_l    CONSTANT VARCHAR2(1 CHAR) := 'L';

    -- Public variable declarations
    CURSOR c_cits
    (
        i_rowids          IN table_varchar,
        i_patient         IN NUMBER := NULL,
        i_episode         IN NUMBER := NULL,
        i_institution     IN NUMBER := NULL,
        i_start_dt        IN TIMESTAMP WITH LOCAL TIME ZONE := NULL,
        i_end_dt          IN TIMESTAMP WITH LOCAL TIME ZONE := NULL,
        i_excluded_status IN table_varchar DEFAULT NULL
    ) IS
        SELECT pc.id_pat_cit,
               e.id_patient,
               pc.id_episode,
               e.id_visit,
               e.id_institution,
               pc.dt_start_period_tstz dt_begin,
               pc.id_prof_writes id_professional,
               pc.dt_end_period_tstz dt_end,
               e.flg_status flg_status_epis,
               pc.dt_writes_tstz dt_last_update,
               decode(pc.flg_status,
                      pk_cit.g_flg_status_concluded,
                      pk_prog_notes_constants.g_task_finalized_f,
                      pk_prog_notes_constants.g_task_ongoing_o) flg_ongoing,
               pc.flg_status
          FROM pat_cit pc
          JOIN episode e
            ON pc.id_episode = e.id_episode
         WHERE (i_rowids IS NULL OR (pc.rowid IN (SELECT /*+opt_estimate(table,t,scale_rows=1)*/
                                                   t.column_value row_id
                                                    FROM TABLE(i_rowids) t)))
           AND (e.id_patient = i_patient OR i_patient IS NULL)
           AND (pc.id_episode = i_episode OR i_episode IS NULL)
           AND (e.id_institution = i_institution OR i_institution IS NULL)
           AND (pc.dt_writes_tstz >= i_start_dt OR i_start_dt IS NULL)
           AND (pc.dt_writes_tstz <= i_end_dt OR i_end_dt IS NULL)
           AND (i_excluded_status IS NULL OR
               (pc.flg_status NOT IN (SELECT /*+opt_estimate(table,t,scale_rows=1)*/
                                        st.column_value
                                         FROM TABLE(i_excluded_status) st)));

    TYPE t_coll_cits IS TABLE OF c_cits%ROWTYPE;

    -- Public function and procedure declarations
    /**
    * Process insert/update events on PAT_CIT into TASK_TIMELINE_EA.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_event_type   event type
    * @param i_rowids       changed records rowids list
    * @param i_src_table    source table name
    * @param i_list_columns changed column names list
    * @param i_dg_table     easy access table name
    *
    * @author               Sofia Mendes
    * @version               2.6.2
    * @since                10-Jul-2013
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

END pk_ea_logic_cit;
/
