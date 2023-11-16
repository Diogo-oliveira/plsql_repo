/*-- Last Change Revision: $Rev: 2044961 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2022-09-08 12:19:30 +0100 (qui, 08 set 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_ea_logic_opinion IS

    g_error        VARCHAR2(1000 CHAR);
    g_owner        VARCHAR2(30 CHAR);
    g_package      VARCHAR2(30 CHAR);
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;

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
        RETURN task_type.id_task_type%TYPE IS
        l_id_tt task_type.id_task_type%TYPE;
    BEGIN
        l_id_tt := CASE nvl(i_id_opinion_type, 0)
                       WHEN 0 THEN
                        pk_prog_notes_constants.g_task_opinion
                       WHEN pk_opinion.g_ot_dietitian THEN
                        pk_prog_notes_constants.g_task_opinion_die
                       WHEN pk_opinion.g_ot_case_manager THEN
                        pk_prog_notes_constants.g_task_opinion_cm
                       WHEN pk_opinion.g_ot_social_worker THEN
                        pk_prog_notes_constants.g_task_opinion_sw
                       WHEN pk_opinion.g_ot_activity_therapist THEN
                        pk_prog_notes_constants.g_task_opinion_at
                       WHEN pk_opinion.g_ot_psychology THEN
                        pk_prog_notes_constants.g_task_opinion_psy
                       WHEN pk_opinion.g_ot_speech_therapy THEN
                        pk_prog_notes_constants.g_task_opinion_speech
                       WHEN pk_opinion.g_ot_occupational_therapy THEN
                        pk_prog_notes_constants.g_task_opinion_occupational
                       WHEN pk_opinion.g_ot_physical_therapy THEN
                        pk_prog_notes_constants.g_task_opinion_physical
                       WHEN pk_opinion.g_ot_cdc THEN
                        pk_prog_notes_constants.g_task_opinion_cdc
                       WHEN pk_opinion.g_ot_mental THEN
                        pk_prog_notes_constants.g_task_opinion_mental
                       WHEN pk_opinion.g_ot_religious THEN
                        pk_prog_notes_constants.g_task_opinion_religious
                        when pk_opinion.g_ot_rehabilitation then
                          pk_prog_notes_constants.g_task_opinion_rehabilitation
                       ELSE
                        pk_prog_notes_constants.g_task_opinion
                   END;
        RETURN l_id_tt;
    END;

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
    FUNCTION get_id_op_type_from_id_tt(id_task_type task_type.id_task_type%TYPE) RETURN opinion_type.id_opinion_type%TYPE IS
        l_id_op opinion_type.id_opinion_type%TYPE;
    BEGIN
        l_id_op := CASE nvl(id_task_type, 0)
                       WHEN pk_prog_notes_constants.g_task_opinion THEN
                        NULL
                       WHEN pk_prog_notes_constants.g_task_opinion_die THEN
                        pk_opinion.g_ot_dietitian
                       WHEN pk_prog_notes_constants.g_task_opinion_cm THEN
                        pk_opinion.g_ot_case_manager
                       WHEN pk_prog_notes_constants.g_task_opinion_sw THEN
                        pk_opinion.g_ot_social_worker
                       WHEN pk_prog_notes_constants.g_task_opinion_at THEN
                        pk_opinion.g_ot_activity_therapist
                       WHEN pk_prog_notes_constants.g_task_opinion_psy THEN
                        pk_opinion.g_ot_psychology
                       WHEN pk_prog_notes_constants.g_task_opinion_speech THEN
                        pk_opinion.g_ot_speech_therapy
                       WHEN pk_prog_notes_constants.g_task_opinion_occupational THEN
                        pk_opinion.g_ot_occupational_therapy
                       WHEN pk_prog_notes_constants.g_task_opinion_physical THEN
                        pk_opinion.g_ot_physical_therapy                   
                       WHEN pk_prog_notes_constants.g_task_opinion_cdc THEN
                        pk_opinion.g_ot_cdc
                       WHEN pk_prog_notes_constants.g_task_opinion_mental THEN
                        pk_opinion.g_ot_mental
                       WHEN pk_prog_notes_constants.g_task_opinion_religious THEN
                        pk_opinion.g_ot_religious
                   when pk_prog_notes_constants.g_task_opinion_rehabilitation then
                     pk_opinion.g_ot_rehabilitation
                   END;
        RETURN l_id_op;
    END;

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
    ) IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_TASK_TIMELINE';
        l_ea_table  CONSTANT VARCHAR2(30 CHAR) := 'TASK_TIMELINE_EA';
        l_src_table CONSTANT VARCHAR2(30 CHAR) := 'OPINION';
        l_ea_row  task_timeline_ea%ROWTYPE;
        l_ea_rows ts_task_timeline_ea.task_timeline_ea_tc;
        l_rows    table_varchar := table_varchar();
        l_error   t_error_out;
    
        CURSOR c_opinion IS
            SELECT o.id_opinion,
                   o.id_opinion_type,
                   o.id_patient,
                   o.id_episode,
                   e.id_visit,
                   e.id_institution,
                   o.dt_problem_tstz,
                   o.id_prof_questions,
                   o.flg_state,
                   pk_ea_logic_tasktimeline.g_flg_not_outdated flg_outdated,
                   CASE
                        WHEN o.flg_state = pk_opinion.g_opinion_reply_read
                             OR o.flg_state = pk_opinion.g_opinion_over THEN
                         pk_prog_notes_constants.g_task_finalized_f
                        ELSE
                         pk_prog_notes_constants.g_task_ongoing_o
                    END flg_ongoing,
                   nvl(o.dt_last_update,
                       (SELECT MAX(op.dt_opinion_prof_tstz)
                          FROM opinion_prof op
                         WHERE op.id_opinion = o.id_opinion)) dt_last_update,
                   e.flg_status flg_status_epis,
                   (SELECT MAX(op.dt_opinion_prof_tstz)
                      FROM opinion_prof op
                     WHERE op.id_opinion = o.id_opinion) dt_reply_date
              FROM opinion o
              JOIN episode e
                ON e.id_episode = o.id_episode
             WHERE o.rowid IN (SELECT /*+dynamic_sampling(t 2)*/
                                t.column_value row_id
                                 FROM TABLE(i_rowids) t);
    
        TYPE t_coll_opinion IS TABLE OF c_opinion%ROWTYPE;
        l_opinion_rows t_coll_opinion;
        l_idx          PLS_INTEGER;
    BEGIN
        g_sysdate_tstz := current_timestamp;
        l_idx          := 0;
    
        -- validate arguments
        g_error := 'CALL t_data_gov_mnt.validate_arguments';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_src_table,
                                                 i_dg_table_name          => i_dg_table,
                                                 i_expected_table_name    => l_src_table,
                                                 i_expected_dg_table_name => l_ea_table,
                                                 i_list_columns           => i_list_columns)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        -- exit when no rowids are specified
        IF i_rowids IS NULL
           OR i_rowids.count < 1
        THEN
            RETURN;
        END IF;
    
        IF i_event_type IN (t_data_gov_mnt.g_event_insert, t_data_gov_mnt.g_event_update)
        THEN
            -- debug event
            g_error := 'processing insert or update event on ' || l_src_table || ' into ' || l_ea_table;
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        
            -- get opinion data from rowids
            g_error := 'OPEN c_opinion';
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            OPEN c_opinion;
            FETCH c_opinion BULK COLLECT
                INTO l_opinion_rows;
            CLOSE c_opinion;
        
            -- copy opinion data into rows collection
            IF l_opinion_rows IS NOT NULL
               AND l_opinion_rows.count > 0
            THEN
                -- set constant fields
                l_ea_row.table_name        := l_src_table;
                l_ea_row.flg_show_method   := pk_alert_constant.g_tl_oriented_episode;
                l_ea_row.dt_dg_last_update := g_sysdate_tstz;
                l_ea_row.flg_sos           := pk_alert_constant.g_no;
                l_ea_row.flg_normal        := pk_alert_constant.g_yes;
                l_ea_row.flg_has_comments  := pk_alert_constant.g_no;
            
                -- set variable fields
                FOR i IN l_opinion_rows.first .. l_opinion_rows.last
                LOOP
                    l_ea_row.id_task_refid     := l_opinion_rows(i).id_opinion;
                    l_ea_row.id_tl_task        := get_id_tt_from_id_op_type(l_opinion_rows(i).id_opinion_type);
                    l_ea_row.id_patient        := l_opinion_rows(i).id_patient;
                    l_ea_row.id_episode        := l_opinion_rows(i).id_episode;
                    l_ea_row.id_visit          := l_opinion_rows(i).id_visit;
                    l_ea_row.id_institution    := l_opinion_rows(i).id_institution;
                    l_ea_row.dt_req            := l_opinion_rows(i).dt_problem_tstz;
                    l_ea_row.id_prof_req       := l_opinion_rows(i).id_prof_questions;
                    l_ea_row.flg_status_req    := l_opinion_rows(i).flg_state;
                    l_ea_row.flg_outdated      := l_opinion_rows(i).flg_outdated;
                    l_ea_row.flg_ongoing       := l_opinion_rows(i).flg_ongoing;
                    l_ea_row.dt_last_execution := l_opinion_rows(i).dt_last_update;
                    l_ea_row.dt_last_update    := l_opinion_rows(i).dt_last_update;
                    l_ea_row.id_task_related   := l_opinion_rows(i).id_opinion;
                    l_ea_row.dt_begin          := l_opinion_rows(i).dt_problem_tstz;
                    l_ea_row.dt_result         := l_opinion_rows(i).dt_reply_date;
                    l_ea_row.flg_type          := CASE l_opinion_rows(i).flg_state
                                                      WHEN pk_prog_notes_constants.g_flg_value_p THEN
                                                       pk_prog_notes_constants.g_replied_opinion
                                                      ELSE
                                                       NULL
                                                  END;
                
                    IF l_opinion_rows(i).flg_state = pk_opinion.g_status_cancel
                        OR l_opinion_rows(i).flg_status_epis = pk_alert_constant.g_epis_status_cancel
                    THEN
                        g_error := 'CALL TS_TASK_TIMELINE_EA.DEL';
                        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                        ts_task_timeline_ea.del(id_task_refid_in => l_ea_row.id_task_refid,
                                                id_tl_task_in    => l_ea_row.id_tl_task);
                    ELSE
                        -- add row to rows collection
                    
                        l_idx := l_idx + 1; -- this idx is used because an INDEX BY TABLE can be sparse. ts_task_timeline_ea.upd cannot handle sparse collections
                        l_ea_rows(l_idx) := l_ea_row;
                    
                    END IF;
                END LOOP;
            
                --if it was canceled there is nothing to insert or update
                IF l_ea_rows.count > 0
                THEN
                    -- add rows collection to easy access
                    IF i_event_type = t_data_gov_mnt.g_event_insert
                    THEN
                        g_error := 'CALL ts_task_timeline_ea.ins I';
                        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                        ts_task_timeline_ea.ins(rows_in => l_ea_rows);
                    ELSIF i_event_type = t_data_gov_mnt.g_event_update
                    THEN
                        g_error := 'CALL ts_task_timeline_ea.upd';
                        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                        ts_task_timeline_ea.upd(col_in => l_ea_rows, ignore_if_null_in => FALSE, rows_out => l_rows);
                    END IF;
                END IF;
            END IF;
        END IF;
    EXCEPTION
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => l_error);
            RAISE;
    END set_task_timeline;

BEGIN
    -- log init
    pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    pk_alertlog.log_init(object_name => g_package);
END pk_ea_logic_opinion;
/
