/*-- Last Change Revision: $Rev: 2027038 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:48 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_ea_logic_mtos IS

    -- Private type declarations

    -- Private constant declarations

    -- Private variable declarations

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;

    -- Function and procedure implementations

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
    ) IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_TASK_TIMELINE';
        l_ea_table  CONSTANT VARCHAR2(30 CHAR) := 'TASK_TIMELINE_EA';
        l_ea_row  task_timeline_ea%ROWTYPE;
        l_ea_rows ts_task_timeline_ea.task_timeline_ea_tc;
        l_rows    table_varchar := table_varchar();
        l_error   t_error_out;
    
        TYPE t_coll_mtos IS TABLE OF c_mtos%ROWTYPE;
        l_mtos_rows t_coll_mtos;
        l_idx       PLS_INTEGER;
    BEGIN
        g_sysdate_tstz := current_timestamp;
        l_idx          := 0;
        -- validate arguments
        g_error := 'CALL t_data_gov_mnt.validate_arguments';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_src_table,
                                                 i_dg_table_name          => i_dg_table,
                                                 i_expected_table_name    => g_src_table,
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
            g_error := 'processing insert or update event on ' || g_src_table || ' into ' || l_ea_table;
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        
            -- get data from rowids
            g_error := 'OPEN c_mtos';
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            OPEN c_mtos(i_rowids => i_rowids);
            FETCH c_mtos BULK COLLECT
                INTO l_mtos_rows;
            CLOSE c_mtos;
        
            -- copy data into rows collection
            IF l_mtos_rows IS NOT NULL
               AND l_mtos_rows.count > 0
            THEN
                -- set constant fields
                l_ea_row.id_tl_task        := pk_prog_notes_constants.g_task_mtos_score;
                l_ea_row.table_name        := g_src_table;
                l_ea_row.flg_show_method   := pk_alert_constant.g_tl_oriented_episode;
                l_ea_row.dt_dg_last_update := g_sysdate_tstz;
                l_ea_row.flg_sos           := pk_alert_constant.g_no;
                l_ea_row.flg_normal        := pk_alert_constant.g_yes;
                l_ea_row.flg_has_comments  := pk_alert_constant.g_no;
            
                -- set variable fields
                FOR i IN l_mtos_rows.first .. l_mtos_rows.last
                LOOP
                    l_ea_row.id_task_refid        := l_mtos_rows(i).id_epis_mtos_score;
                    l_ea_row.id_patient           := l_mtos_rows(i).id_patient;
                    l_ea_row.id_episode           := l_mtos_rows(i).id_episode;
                    l_ea_row.id_visit             := l_mtos_rows(i).id_visit;
                    l_ea_row.id_institution       := l_mtos_rows(i).id_institution;
                    l_ea_row.dt_req               := l_mtos_rows(i).dt_create;
                    l_ea_row.id_prof_req          := l_mtos_rows(i).id_prof_create;
                    l_ea_row.dt_begin             := l_mtos_rows(i).dt_create;
                    l_ea_row.flg_status_req       := pk_sev_scores_constant.g_flg_status_a;
                    l_ea_row.flg_outdated         := pk_ea_logic_tasktimeline.g_flg_not_outdated;
                    l_ea_row.flg_ongoing := CASE
                                                WHEN l_mtos_rows(i).id_mtos_score = pk_sev_scores_constant.g_id_score_isstw THEN
                                                 pk_prog_notes_constants.g_task_ongoing_o
                                                ELSE
                                                 pk_prog_notes_constants.g_task_finalized_f
                                            END;
                    l_ea_row.dt_last_update       := l_mtos_rows(i).dt_create;
                    l_ea_row.id_group_import      := mtos_score_has_parent(i_id_mtos_score => l_mtos_rows(i).id_mtos_score);
                    l_ea_row.id_parent_task_refid := l_mtos_rows(i).id_parent;
                
                    IF l_mtos_rows(i).flg_status_epis = pk_alert_constant.g_epis_status_cancel
                        OR l_mtos_rows(i).flg_status <> pk_sev_scores_constant.g_flg_status_a
                    THEN
                        g_error := 'CALL TS_TASK_TIMELINE_EA.DEL';
                        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                        ts_task_timeline_ea.del(id_task_refid_in => l_ea_row.id_task_refid,
                                                id_tl_task_in    => l_ea_row.id_tl_task);
                    ELSE
                        -- add row to rows collection
                        l_idx := l_idx + 1;
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
                    
                        IF l_rows.count = 0
                        THEN
                            g_error := 'CALL ts_task_timeline_ea.ins II';
                            pk_alertlog.log_info(text            => g_error,
                                                 object_name     => g_package,
                                                 sub_object_name => l_func_name);
                            ts_task_timeline_ea.ins(rows_in => l_ea_rows);
                        END IF;
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

    FUNCTION mtos_score_has_parent(i_id_mtos_score IN mtos_score.id_mtos_score%TYPE) RETURN mtos_score.id_mtos_score%TYPE IS
    
        l_return mtos_score.id_mtos_score%TYPE;
    BEGIN
    
        BEGIN
            SELECT mr.id_mtos_score
              INTO l_return
              FROM mtos_score_relation mr
             WHERE mr.id_mtos_score_rel = i_id_mtos_score;
        EXCEPTION
            WHEN OTHERS THEN
                l_return := i_id_mtos_score;
        END;
    
        RETURN l_return;
    
    END mtos_score_has_parent;

BEGIN
    -- Initialization

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_ea_logic_mtos;
/
