/*-- Last Change Revision: $Rev: 1791602 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2017-07-28 15:03:37 +0100 (sex, 28 jul 2017) $*/

CREATE OR REPLACE PACKAGE pk_ea_logic_triage IS

    -- Author  : SOFIA.MENDES
    -- Created : 4/29/2013 3:58:20 PM
    -- Purpose : This package should contain the easy access functions related to triage functionality

    -- Public type declarations

    -- Public constant declarations
    g_triage_src_table CONSTANT VARCHAR2(11 CHAR) := 'EPIS_TRIAGE';
    g_desc_type_s      CONSTANT VARCHAR2(1 CHAR) := 'S';
    g_desc_type_l      CONSTANT VARCHAR2(1 CHAR) := 'L';

    -- Public variable declarations
    CURSOR c_triage
    (
        i_rowids           IN table_varchar,
        i_patient          IN NUMBER := NULL,
        i_episode          IN NUMBER := NULL,
        i_institution      IN NUMBER := NULL,
        i_start_dt         IN TIMESTAMP WITH LOCAL TIME ZONE := NULL,
        i_end_dt           IN TIMESTAMP WITH LOCAL TIME ZONE := NULL
    ) IS
        SELECT /*+opt_estimate(table et rows=1)*/ 
               et.id_epis_triage, 
               e.id_patient, 
               et.id_episode, 
               e.id_visit, 
               e.id_institution, 
               et.dt_begin_tstz, 
               et.id_professional, 
               et.dt_end_tstz, 
               e.flg_status flg_status_epis, 
               et.dt_end_tstz dt_last_update 
          FROM epis_triage et 
          JOIN episode e 
            ON et.id_episode = e.id_episode 
         WHERE et.rowid IN (SELECT t.column_value row_id 
                              FROM TABLE(i_rowids) t);

    -- Public function and procedure declarations
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
    * @author               Sofia Mendes
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

END pk_ea_logic_triage;
/
