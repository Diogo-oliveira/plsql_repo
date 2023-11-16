/*-- Last Change Revision: $Rev: 2027026 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:46 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_ea_logic_discharge IS

    g_error        VARCHAR2(1000 CHAR);
    g_owner        VARCHAR2(30 CHAR);
    g_package      VARCHAR2(30 CHAR);
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;

    /**
    * Process insert/update events on DISCHARGE_NOTES into TASK_TIMELINE_EA.
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
        l_src_table CONSTANT VARCHAR2(30 CHAR) := 'DISCHARGE_NOTES';
        l_ea_row   task_timeline_ea%ROWTYPE;
        l_ea_rows  ts_task_timeline_ea.task_timeline_ea_tc;
        l_rows     table_varchar := table_varchar();
        l_error    t_error_out;
        l_old_data table_number;
    
        CURSOR c_disch_notes IS
            SELECT dn.id_discharge_notes,
                   dn.id_patient,
                   dn.id_episode,
                   e.id_visit,
                   e.id_institution,
                   dn.dt_creation_tstz,
                   dn.id_professional,
                   dn.flg_status,
                   pk_ea_logic_tasktimeline.g_flg_not_outdated flg_outdated,
                   pk_prog_notes_constants.g_task_finalized_f  flg_ongoing,
                   e.flg_status                                flg_status_epis
              FROM discharge_notes dn
              JOIN episode e
                ON e.id_episode = dn.id_episode
             WHERE dn.rowid IN (SELECT /*+dynamic_sampling(t 2)*/
                                 t.column_value row_id
                                  FROM TABLE(i_rowids) t);
    
        TYPE t_coll_disch_notes IS TABLE OF c_disch_notes%ROWTYPE;
        l_disch_notes_rows t_coll_disch_notes;
    
        l_timestamp TIMESTAMP(6) WITH LOCAL TIME ZONE := current_timestamp;
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
    
        pk_alertlog.log_fatal(text => 'SS Zona 1');
    
        IF i_event_type IN (t_data_gov_mnt.g_event_insert, t_data_gov_mnt.g_event_update)
        THEN
            pk_alertlog.log_fatal(text => 'SS Zona 2');
            -- debug event
            g_error := 'processing insert or update event on ' || l_src_table || ' into ' || l_ea_table;
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        
            -- get discharge notes data from rowids
            g_error := 'OPEN c_disch_notes';
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            OPEN c_disch_notes;
            FETCH c_disch_notes BULK COLLECT
                INTO l_disch_notes_rows;
            CLOSE c_disch_notes;
        
            -- copy discharge notes data into rows collection
            IF l_disch_notes_rows IS NOT NULL
               AND l_disch_notes_rows.count > 0
            THEN
                -- set constant fields
                l_ea_row.table_name        := l_src_table;
                l_ea_row.id_tl_task        := pk_prog_notes_constants.g_task_disch_instructions;
                l_ea_row.flg_show_method   := pk_alert_constant.g_tl_oriented_episode;
                l_ea_row.dt_dg_last_update := g_sysdate_tstz;
                l_ea_row.flg_sos           := pk_alert_constant.g_no;
                l_ea_row.flg_normal        := pk_alert_constant.g_yes;
                l_ea_row.flg_has_comments  := pk_alert_constant.g_no;
            
                -- set variable fields
                FOR i IN l_disch_notes_rows.first .. l_disch_notes_rows.last
                LOOP
                    l_ea_row.id_task_refid     := l_disch_notes_rows(i).id_discharge_notes;
                    l_ea_row.id_patient        := l_disch_notes_rows(i).id_patient;
                    l_ea_row.id_episode        := l_disch_notes_rows(i).id_episode;
                    l_ea_row.id_visit          := l_disch_notes_rows(i).id_visit;
                    l_ea_row.id_institution    := l_disch_notes_rows(i).id_institution;
                    l_ea_row.dt_req            := l_disch_notes_rows(i).dt_creation_tstz;
                    l_ea_row.id_prof_req       := l_disch_notes_rows(i).id_professional;
                    l_ea_row.flg_status_req    := l_disch_notes_rows(i).flg_status;
                    l_ea_row.flg_outdated      := l_disch_notes_rows(i).flg_outdated;
                    l_ea_row.flg_ongoing       := l_disch_notes_rows(i).flg_ongoing;
                    l_ea_row.dt_last_execution := l_disch_notes_rows(i).dt_creation_tstz;
                    l_ea_row.dt_last_update    := l_disch_notes_rows(i).dt_creation_tstz;
                
                    --get old data if we are adding
                    IF i_event_type = t_data_gov_mnt.g_event_insert
                    THEN
                        SELECT t.id_task_refid BULK COLLECT
                          INTO l_old_data
                          FROM task_timeline_ea t
                         WHERE t.id_tl_task = pk_prog_notes_constants.g_task_disch_instructions
                           AND t.id_episode = l_disch_notes_rows(i).id_episode;
                    
                        --delete old data
                        FOR j IN 1 .. l_old_data.count
                        LOOP
                            g_error := 'TS_TASK_TIMELINE_EA.DEL REMOVING OLD DATA';
                            pk_alertlog.log_info(text            => g_error,
                                                 object_name     => g_package,
                                                 sub_object_name => l_func_name);
                            ts_task_timeline_ea.del(id_task_refid_in => l_old_data(j),
                                                    id_tl_task_in    => pk_prog_notes_constants.g_task_disch_instructions);
                        END LOOP;
                    END IF;
                
                    pk_alertlog.log_fatal(text => 'SS Zona 4');
                    IF l_disch_notes_rows(i)
                     .flg_status <> pk_discharge.g_disch_notes_c
                        AND l_disch_notes_rows(i).flg_status_epis <> pk_alert_constant.g_epis_status_cancel
                    THEN
                        pk_alertlog.log_fatal(text => 'SS Zona 5');
                        -- add row to rows collection
                        l_idx := l_idx + 1;
                        l_ea_rows(l_idx) := l_ea_row;
                    END IF;
                END LOOP;
            
                --if it was canceled there is nothing to insert or update
                IF l_ea_rows.count > 0
                THEN
                    pk_alertlog.log_fatal(text => 'SS Zona 6 - ' || i_event_type);
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
    --
    PROCEDURE ins_grid_task_discharge_pend
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_rowids IN table_varchar
    ) IS
        l_error_out t_error_out;
        l_prof      profissional := i_prof;
        l_exception EXCEPTION;
        l_dummy         grid_task.discharge_pend%TYPE;
        l_status_string grid_task.discharge_pend%TYPE;
        l_status_str    grid_task.discharge_pend%TYPE;
    BEGIN
    
        FOR r_cur IN (SELECT m.id_episode, m.id_professional, e.id_institution, ei.id_software, m.dt
                        FROM (SELECT aux.rowid, aux.id_episode, aux.id_professional, aux.dt
                                FROM (SELECT ROWID,
                                             row_number() over(PARTITION BY d.id_episode ORDER BY pk_date_utils.max_date(table_timestamp_tstz(d.dt_admin_tstz, d.dt_cancel_tstz, d.dt_med_tstz, d.dt_nurse, d.dt_nutritionist, d.dt_pend_active_tstz, d.dt_pend_tstz, d.dt_therapist)) DESC NULLS LAST) rn,
                                             pk_date_utils.max_date(table_timestamp_tstz(d.dt_admin_tstz,
                                                                                         d.dt_cancel_tstz,
                                                                                         d.dt_med_tstz,
                                                                                         d.dt_nurse,
                                                                                         d.dt_nutritionist,
                                                                                         d.dt_pend_active_tstz,
                                                                                         d.dt_pend_tstz,
                                                                                         d.dt_therapist)) dt,
                                             d.flg_status,
                                             d.id_episode,
                                             coalesce(d.id_prof_med,
                                                      d.id_prof_nurse,
                                                      d.id_prof_admin,
                                                      d.id_prof_nutritionist,
                                                      d.id_prof_therapist,
                                                      d.id_prof_pend_active,
                                                      d.id_prof_cancel) id_professional
                                        FROM discharge d) aux
                               WHERE aux.rn = 1
                                 AND aux.flg_status IN ('P')) m
                        JOIN episode e
                          ON e.id_episode = m.id_episode
                        JOIN epis_info ei
                          ON ei.id_episode = e.id_episode
                       WHERE m.rowid IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                           FROM TABLE(i_rowids))
                          OR i_rowids IS NULL)
        
        LOOP
        
            IF i_prof IS NULL
            THEN
                IF r_cur.id_professional IS NULL
                   OR r_cur.id_institution IS NULL
                   OR r_cur.id_software IS NULL
                THEN
                    continue;
                END IF;
                l_prof := profissional(r_cur.id_professional, r_cur.id_institution, r_cur.id_software);
            
            END IF;
        
            pk_utils.build_status_string(i_display_type => pk_alert_constant.g_display_type_date,
                                         i_value_date   => pk_date_utils.to_char_insttimezone(l_prof,
                                                                                              r_cur.dt,
                                                                                              pk_alert_constant.g_dt_yyyymmddhh24miss_tzr),
                                         i_shortcut     => pk_disposition.get_discharge_shortcut(i_lang => i_lang,
                                                                                                 i_prof => l_prof),
                                         o_status_str   => l_status_str,
                                         o_status_msg   => l_dummy,
                                         o_status_icon  => l_dummy,
                                         o_status_flg   => l_dummy);
        
            l_status_string := REPLACE(l_status_str,
                                       pk_alert_constant.g_status_rpl_chr_dt_server,
                                       pk_date_utils.to_char_insttimezone(l_prof,
                                                                          r_cur.dt,
                                                                          pk_alert_constant.g_dt_yyyymmddhh24miss_tzr)) || '|';
        
            g_error := 'CALL PK_GRID.UPDATE_GRID_TASK';
            --Actualiza estado da tarefa em GRID_TASK para o episódio correspondente
            IF NOT pk_grid.update_grid_task(i_lang             => i_lang,
                                            i_prof             => l_prof,
                                            i_episode          => r_cur.id_episode,
                                            discharge_pend_in  => l_status_string,
                                            discharge_pend_nin => FALSE,
                                            o_error            => l_error_out)
            THEN
                g_error := 'ERROR UPDATE_GRID_TASK';
                RAISE l_exception;
            END IF;
        END LOOP;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => g_error);
    END ins_grid_task_discharge_pend;
BEGIN
    -- log init
    pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    pk_alertlog.log_init(object_name => g_package);
END pk_ea_logic_discharge;
/
