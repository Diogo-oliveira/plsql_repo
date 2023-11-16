/*-- Last Change Revision: $Rev: 2027063 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:53 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_ea_logic_supply IS

    PROCEDURE set_grid_task_supplies
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
    
        l_grid_task grid_task%ROWTYPE;
    
        l_short_supplies sys_shortcut.id_sys_shortcut%TYPE;
    
        l_category category.id_category%TYPE := pk_prof_utils.get_id_category(i_lang, i_prof);
    
        l_error_out t_error_out;
    
    BEGIN
    
        -- Validate arguments
        g_error := 'VALIDATE ARGUMENTS';
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => i_source_table_name,
                                                 i_expected_dg_table_name => 'GRID_TASK',
                                                 i_list_columns           => i_list_columns,
                                                 i_expected_columns       => NULL)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        -- Process update event
        IF i_event_type IN (t_data_gov_mnt.g_event_insert, t_data_gov_mnt.g_event_update)
        THEN
            -- Loop through changed records
            g_error := 'LOOP UPDATED';
            IF i_rowids IS NOT NULL
               AND i_rowids.count > 0
            THEN
                g_error := 'GET SHORTCUT';
                IF NOT pk_access.get_id_shortcut(i_lang        => i_lang,
                                                 i_prof        => profissional(i_prof.id,
                                                                               i_prof.institution,
                                                                               pk_alert_constant.g_soft_oris),
                                                 i_intern_name => 'SR_SURGICAL_SUPPLIES',
                                                 o_id_shortcut => l_short_supplies,
                                                 o_error       => l_error_out)
                THEN
                    l_short_supplies := 0;
                END IF;
            
                FOR r_cur IN (SELECT /*+ opt_estimate (table ard rows=1)*/
                               sw.id_episode
                                FROM supply_workflow sw
                               WHERE sw.rowid IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                   *
                                                    FROM TABLE(i_rowids) t))
                LOOP
                    SELECT MAX(status_string) status_string
                      INTO l_grid_task.material_req
                      FROM (SELECT sw.status_string,
                                   rank() over(ORDER BY sw.rank, sw.dt_supply_workflow) rank,
                                   row_number() over(ORDER BY sw.rank, sw.dt_supply_workflow) rn
                              FROM (SELECT sw.dt_supply_workflow,
                                           pk_supplies_core.get_supply_wf_status_string(i_lang,
                                                                                        i_prof,
                                                                                        sw.flg_status,
                                                                                        l_short_supplies,
                                                                                        pk_supplies_constant.g_id_workflow_sr,
                                                                                        sw.id_supply_area,
                                                                                        l_category,
                                                                                        sw.dt_returned,
                                                                                        sw.dt_request,
                                                                                        sw.dt_supply_workflow,
                                                                                        sw.id_episode,
                                                                                        sw.id_supply_workflow) status_string,
                                           pk_workflow.get_status_rank(i_lang,
                                                                       i_prof,
                                                                       pk_supplies_constant.g_id_workflow_sr,
                                                                       sws.id_status,
                                                                       l_category,
                                                                       NULL,
                                                                       NULL,
                                                                       table_varchar()) rank
                                      FROM supply_workflow sw
                                     INNER JOIN supplies_wf_status sws
                                        ON sws.flg_status = sw.flg_status
                                     WHERE sw.id_supply_area = pk_supplies_constant.g_area_surgical_supplies
                                       AND sws.id_category = l_category
                                       AND sw.id_episode = r_cur.id_episode
                                       AND sw.flg_status IN
                                           (pk_supplies_constant.g_sww_request_local,
                                            pk_supplies_constant.g_sww_request_central,
                                            pk_supplies_constant.g_sww_prepared_pharmacist,
                                            pk_supplies_constant.g_sww_in_transit,
                                            pk_supplies_constant.g_sww_transport_concluded,
                                            pk_supplies_constant.g_sww_prep_sup_for_surg)) sw) t
                     WHERE rank = 1
                       AND rn = 1;
                
                    l_grid_task.id_episode := r_cur.id_episode;
                
                    IF l_grid_task.id_episode IS NOT NULL
                    THEN
                        g_error := 'CALL PK_GRID.UPDATE_GRID_TASK - id_episode';
                        IF NOT pk_grid.update_grid_task(i_lang           => i_lang,
                                                        i_prof           => i_prof,
                                                        i_episode        => l_grid_task.id_episode,
                                                        material_req_in  => l_grid_task.material_req,
                                                        material_req_nin => FALSE,
                                                        o_error          => l_error_out)
                        THEN
                            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
                        END IF;
                    
                        IF l_grid_task.material_req IS NULL
                        THEN
                            g_error := 'CALL PK_GRID.DELETE_EPIS_GRID_TASK - id_episode';
                            IF NOT pk_grid.delete_epis_grid_task(i_lang    => i_lang,
                                                                 i_episode => l_grid_task.id_episode,
                                                                 o_error   => l_error_out)
                            THEN
                                RAISE t_data_gov_mnt.g_excp_invalid_arguments;
                            END IF;
                        END IF;
                    END IF;
                END LOOP;
            END IF;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => g_error);
    END set_grid_task_supplies;

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
        l_src_table CONSTANT VARCHAR2(30 CHAR) := 'SUPPLY_WORKFLOW';
        l_ea_row  task_timeline_ea%ROWTYPE;
        l_ea_rows ts_task_timeline_ea.task_timeline_ea_tc;
        l_rows    table_varchar := table_varchar();
        l_error   t_error_out;
        l_count   NUMBER := 0;
    
        CURSOR c_supply IS
            SELECT sw.id_supply_workflow,
                   e.id_patient,
                   sw.id_episode,
                   e.id_visit,
                   e.id_institution,
                   sw.dt_request,
                   sw.id_professional,
                   sw.flg_status,
                   s.code_supply,
                   sw.id_sup_workflow_parent,
                   sa.code_supply_area,
                   sa.id_supply_area,
                   sw.dt_supply_workflow,
                   CASE
                        WHEN sw.flg_status IN (pk_supplies_constant.g_sww_cancelled) THEN
                         pk_ea_logic_tasktimeline.g_flg_outdated -- supply cancelled
                        WHEN sw.dt_returned < g_sysdate_tstz THEN
                         pk_ea_logic_tasktimeline.g_flg_outdated -- 
                        WHEN sw.dt_expiration < g_sysdate_tstz THEN
                         pk_ea_logic_tasktimeline.g_flg_outdated
                        ELSE
                         pk_ea_logic_tasktimeline.g_flg_not_outdated -- 
                    END flg_outdated
              FROM supply_workflow sw
              JOIN episode e
                ON sw.id_episode = e.id_episode
              JOIN supply s
                ON sw.id_supply = s.id_supply
              JOIN supply_area sa
                ON sw.id_supply_area = sa.id_supply_area
             WHERE sw.rowid IN (SELECT t.column_value row_id
                                  FROM TABLE(i_rowids) t)
             ORDER BY sw.id_supply_workflow DESC;
    
        TYPE t_coll_supply IS TABLE OF c_supply%ROWTYPE;
        l_supply_rows t_coll_supply;
        l_update_reg  NUMBER(5) := NULL;
        l_event_type  VARCHAR2(2 CHAR) := NULL;
    BEGIN
    
        g_error := 'set_task_timeline' || ' i_event_type : ' || i_event_type || ', i_src_table: ' || i_src_table ||
                   ', i_dg_table: ' || i_dg_table || ', i_rowids.count: ' || i_rowids.count;
        pk_alertlog.log_debug(text            => g_error,
                              object_name     => g_package,
                              sub_object_name => l_func_name,
                              owner           => g_owner);
        g_sysdate_tstz := current_timestamp;
        l_event_type   := i_event_type;
        -- validate arguments
        g_error := 'CALL t_data_gov_mnt.validate_arguments';
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
    
        IF i_event_type IN
           (t_data_gov_mnt.g_event_insert, t_data_gov_mnt.g_event_update, t_data_gov_mnt.g_event_delete)
        THEN
            g_error := 'processing insert or update event on ' || l_src_table || ' into ' || l_ea_table;
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        
            g_error := 'OPEN c_supply';
            OPEN c_supply;
            FETCH c_supply BULK COLLECT
                INTO l_supply_rows;
            CLOSE c_supply;
        
            -- copy supply data into rows collection
            IF l_supply_rows IS NOT NULL
               AND l_supply_rows.count > 0
            THEN
            
                -- set constant fields
                l_ea_row.id_tl_task        := pk_prog_notes_constants.g_task_supply;
                l_ea_row.table_name        := l_src_table;
                l_ea_row.flg_show_method   := pk_alert_constant.g_tl_oriented_episode;
                l_ea_row.dt_dg_last_update := g_sysdate_tstz;
                l_ea_row.flg_sos           := pk_alert_constant.g_no;
                l_ea_row.flg_normal        := pk_alert_constant.g_yes;
                l_ea_row.flg_has_comments  := pk_alert_constant.g_no;
                l_ea_row.flg_ongoing       := pk_prog_notes_constants.g_task_ongoing_o;
            
                -- set variable fields
                FOR i IN l_supply_rows.first .. l_supply_rows.last
                LOOP
                
                    l_ea_row.dt_last_update       := g_sysdate_tstz;
                    l_ea_row.id_task_refid        := l_supply_rows(i).id_supply_workflow;
                    l_ea_row.id_patient           := l_supply_rows(i).id_patient;
                    l_ea_row.id_episode           := l_supply_rows(i).id_episode;
                    l_ea_row.id_visit             := l_supply_rows(i).id_visit;
                    l_ea_row.id_institution       := l_supply_rows(i).id_institution;
                    l_ea_row.dt_req               := l_supply_rows(i).dt_supply_workflow;
                    l_ea_row.dt_begin             := l_supply_rows(i).dt_supply_workflow;
                    l_ea_row.dt_end               := l_supply_rows(i).dt_supply_workflow;
                    l_ea_row.id_prof_req          := l_supply_rows(i).id_professional;
                    l_ea_row.flg_status_req       := l_supply_rows(i).flg_status;
                    l_ea_row.flg_outdated         := l_supply_rows(i).flg_outdated;
                    l_ea_row.code_description     := l_supply_rows(i).code_supply;
                    l_ea_row.id_parent_task_refid := l_supply_rows(i).id_sup_workflow_parent;
                    l_ea_row.id_group_import      := l_supply_rows(i).id_supply_area;
                    l_ea_row.code_desc_group      := l_supply_rows(i).code_supply_area;
                
                    g_error := 'FOR LOOP id_task_refid: ' || l_ea_row.id_task_refid || ' flg_status: ' || l_supply_rows(i).flg_status;
                    pk_alertlog.log_debug(text            => g_error,
                                          object_name     => g_package,
                                          sub_object_name => l_func_name,
                                          owner           => g_owner);
                
                    SELECT COUNT(0)
                      INTO l_update_reg
                      FROM task_timeline_ea tte
                     WHERE tte.id_task_refid = l_ea_row.id_task_refid
                       AND tte.table_name = l_src_table
                       AND tte.id_tl_task = pk_prog_notes_constants.g_task_supply;
                
                    IF (l_ea_row.flg_status_req = pk_supplies_constant.g_sww_cancelled)
                    THEN
                        g_error := 'CALL ts_task_timeline_ea.del_by';
                        pk_alertlog.log_debug(text            => g_error,
                                              object_name     => g_package,
                                              sub_object_name => l_func_name,
                                              owner           => g_owner);
                        ts_task_timeline_ea.del_by(where_clause_in => 'id_task_refid = ' || l_ea_row
                                                                     .id_task_refid || ' AND id_tl_task = ' || l_ea_row.id_tl_task,
                                                   rows_out        => l_rows);
                        l_event_type := t_data_gov_mnt.g_event_delete;
                    
                    END IF;
                
                    l_count := l_count + 1;
                    l_ea_rows(l_count) := l_ea_row;
                
                END LOOP;
            END IF;
        
            --if it was canceled there is nothing to insert or update
        
            IF l_ea_rows.count > 0
            THEN
                -- add rows collection to easy access
                IF l_event_type = t_data_gov_mnt.g_event_insert
                THEN
                    g_error := 'CALL ts_task_timeline_ea.ins I';
                    pk_alertlog.log_info(text            => g_error,
                                         object_name     => g_package,
                                         sub_object_name => l_func_name,
                                         owner           => g_owner);
                    ts_task_timeline_ea.ins(rows_in => l_ea_rows);
                ELSIF l_event_type = t_data_gov_mnt.g_event_update
                THEN
                    g_error := 'CALL ts_task_timeline_ea.upd';
                    pk_alertlog.log_info(text            => g_error,
                                         object_name     => g_package,
                                         sub_object_name => l_func_name,
                                         owner           => g_owner);
                    ts_task_timeline_ea.upd(col_in => l_ea_rows, ignore_if_null_in => FALSE, rows_out => l_rows);
                END IF;
            END IF;
        
        ELSE
            RAISE g_excp_invalid_event_type;
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
    -- Log initialization.
    pk_alertlog.who_am_i(g_owner, g_package);
    pk_alertlog.log_init(g_package);
END pk_ea_logic_supply;
/
