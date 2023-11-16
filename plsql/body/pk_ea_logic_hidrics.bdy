/*-- Last Change Revision: $Rev: 1752847 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2016-09-06 16:19:59 +0100 (ter, 06 set 2016) $*/

CREATE OR REPLACE PACKAGE BODY pk_ea_logic_hidrics IS

    g_error        VARCHAR2(1000 CHAR);
    g_owner        VARCHAR2(30 CHAR);
    g_package      VARCHAR2(30 CHAR);
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;

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
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2012/04/20
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
        l_src_table CONSTANT VARCHAR2(30 CHAR) := 'EPIS_HIDRICS';
        l_ea_row  task_timeline_ea%ROWTYPE;
        l_ea_rows ts_task_timeline_ea.task_timeline_ea_tc;
        l_rows    table_varchar := table_varchar();
        l_error   t_error_out;
    
        CURSOR c_hidric IS
            SELECT eh.id_epis_hidrics,
                   eh.id_patient,
                   eh.id_episode,
                   e.id_visit,
                   e.id_institution,
                   eh.dt_creation_tstz,
                   eh.id_professional,
                   eh.dt_initial_tstz,
                   eh.dt_end_tstz,
                   eh.flg_status,
                   CASE
                        WHEN eh.flg_status IN
                             (pk_inp_hidrics_constant.g_epis_hidric_r, pk_inp_hidrics_constant.g_epis_hidric_e) THEN
                         pk_ea_logic_tasktimeline.g_flg_not_outdated
                        ELSE
                         pk_ea_logic_tasktimeline.g_flg_outdated
                    END flg_outdated,
                   eh.id_hidrics_type,
                   ht.code_hidrics_type,
                   CASE
                        WHEN eh.flg_status IN
                             (pk_inp_hidrics_constant.g_epis_hidric_f, pk_inp_hidrics_constant.g_epis_hidric_i) THEN
                         pk_prog_notes_constants.g_task_finalized_f
                        ELSE
                         pk_prog_notes_constants.g_task_ongoing_o
                    END flg_ongoing,
                   (SELECT MAX(ehd.dt_execution_tstz) --DT_EPIS_HIDRICS_DET
                      FROM epis_hidrics_det ehd
                     WHERE ehd.id_epis_hidrics = eh.id_epis_hidrics) dt_last_execution,
                   e.flg_status flg_status_epis,
                   coalesce(eh.dt_epis_hidrics, eh.dt_inter_tstz, eh.dt_creation_tstz) dt_last_update
              FROM epis_hidrics eh
              JOIN episode e
                ON eh.id_episode = e.id_episode
              JOIN hidrics_type ht
                ON eh.id_hidrics_type = ht.id_hidrics_type
             WHERE eh.rowid IN (SELECT /*+dynamic_sampling(t 2)*/
                                 t.column_value row_id
                                  FROM TABLE(i_rowids) t)
               AND eh.flg_status NOT IN
                   (pk_inp_hidrics_constant.g_epis_hidric_d, pk_inp_hidrics_constant.g_epis_hidric_l);
    
        TYPE t_coll_hidric IS TABLE OF c_hidric%ROWTYPE;
        l_hidric_rows t_coll_hidric;
        l_idx         PLS_INTEGER;
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
        
            -- get hidric data from rowids
            g_error := 'OPEN c_hidric';
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            OPEN c_hidric;
            FETCH c_hidric BULK COLLECT
                INTO l_hidric_rows;
            CLOSE c_hidric;
        
            -- copy hidric data into rows collection
            IF l_hidric_rows IS NOT NULL
               AND l_hidric_rows.count > 0
            THEN
                -- set constant fields
                l_ea_row.id_tl_task        := pk_prog_notes_constants.g_task_intake_output;
                l_ea_row.table_name        := l_src_table;
                l_ea_row.flg_show_method   := pk_alert_constant.g_tl_oriented_episode;
                l_ea_row.dt_dg_last_update := g_sysdate_tstz;
                l_ea_row.flg_sos           := pk_alert_constant.g_no;
                l_ea_row.flg_normal        := pk_alert_constant.g_yes;
                l_ea_row.flg_has_comments  := pk_alert_constant.g_no;
            
                -- set variable fields
                FOR i IN l_hidric_rows.first .. l_hidric_rows.last
                LOOP
                    l_ea_row.id_task_refid     := l_hidric_rows(i).id_epis_hidrics;
                    l_ea_row.id_patient        := l_hidric_rows(i).id_patient;
                    l_ea_row.id_episode        := l_hidric_rows(i).id_episode;
                    l_ea_row.id_visit          := l_hidric_rows(i).id_visit;
                    l_ea_row.id_institution    := l_hidric_rows(i).id_institution;
                    l_ea_row.dt_req            := l_hidric_rows(i).dt_creation_tstz;
                    l_ea_row.id_prof_req       := l_hidric_rows(i).id_professional;
                    l_ea_row.dt_begin          := l_hidric_rows(i).dt_initial_tstz;
                    l_ea_row.dt_end            := l_hidric_rows(i).dt_end_tstz;
                    l_ea_row.flg_status_req    := l_hidric_rows(i).flg_status;
                    l_ea_row.flg_outdated      := l_hidric_rows(i).flg_outdated;
                    l_ea_row.id_group_import   := l_hidric_rows(i).id_hidrics_type;
                    l_ea_row.code_desc_group   := l_hidric_rows(i).code_hidrics_type;
                    l_ea_row.flg_ongoing       := l_hidric_rows(i).flg_ongoing;
                    l_ea_row.dt_last_execution := l_hidric_rows(i).dt_last_execution;
                    l_ea_row.dt_last_update    := l_hidric_rows(i).dt_last_update;
                
                    IF l_hidric_rows(i)
                     .flg_status IN (pk_inp_hidrics_constant.g_epis_hidric_c, pk_inp_hidrics_constant.g_epis_hidric_o)
                        OR l_hidric_rows(i).flg_status_epis = pk_alert_constant.g_epis_status_cancel
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

    PROCEDURE set_grid_task_hidrics
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
        l_rowids    table_varchar;
        l_error_out t_error_out;
    BEGIN
    
        g_error := 'GET EXAMS ROWIDS';
        IF NOT get_data_rowid(i_lang, i_prof, i_source_table_name, 'GRID_TASK', i_rowids, l_rowids, l_error_out)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
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
                ins_grid_task_hidrics(i_lang => i_lang, i_prof => i_prof, i_rowids => l_rowids);
            END IF;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => g_error);
    END set_grid_task_hidrics;

    FUNCTION get_data_rowid
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_table_name IN VARCHAR,
        i_table_ea   IN VARCHAR,
        i_rowids     IN table_varchar,
        o_rowids     OUT table_varchar,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF i_table_name = 'EPIS_HIDRICS_BALANCE'
        THEN
            SELECT /*+rule*/
             eh.rowid BULK COLLECT
              INTO o_rowids
              FROM epis_hidrics eh
             WHERE eh.id_epis_hidrics IN (SELECT ehb.id_epis_hidrics
                                            FROM epis_hidrics_balance ehb
                                            JOIN TABLE(i_rowids) t
                                              ON (t.column_value = ehb.rowid));
            RETURN TRUE;
            --
        ELSIF i_table_name = 'EPIS_HIDRICS'
        THEN
            o_rowids := i_rowids;
            RETURN TRUE;
            --        
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_DATA_ROWID',
                                              o_error    => o_error);
        
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_data_rowid;

    PROCEDURE ins_grid_task_hidrics
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_rowids IN table_varchar
    ) IS
    BEGIN
        FOR r_cur IN (SELECT eh.id_episode
                        FROM epis_hidrics eh
                       WHERE eh.rowid IN (SELECT /*+opt_estimate (table t rows=1)*/
                                           *
                                            FROM TABLE(i_rowids) t)
                          OR i_rowids IS NULL)
        
        LOOP
			IF r_cur.id_episode is not null
			THEN
				ins_grid_task_hidrics_epis(i_lang => i_lang, i_prof => i_prof, i_id_episode => r_cur.id_episode);
			END IF;        END LOOP;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => g_error);
    END ins_grid_task_hidrics;
    ----
    PROCEDURE ins_grid_task_hidrics_epis
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN grid_task.id_episode%TYPE
    ) IS
        l_grid_task              grid_task%ROWTYPE;
        l_shortcut               sys_shortcut.id_sys_shortcut%TYPE;
        l_value_date             VARCHAR2(200);
        l_server_date            VARCHAR2(200);
        l_aux                    VARCHAR2(200);
        l_error_out              t_error_out;
        l_prof                   profissional := i_prof;
        l_icon_type              VARCHAR2(24 CHAR);
        l_oldest_id_epis_hidrics epis_hidrics.id_epis_hidrics%TYPE;
        l_code_flg_status        VARCHAR2(200 CHAR);
        l_icon                   VARCHAR2(200 CHAR);
        l_dt_next                epis_hidrics.dt_initial_tstz%TYPE;
    BEGIN
        l_grid_task              := NULL;
        l_oldest_id_epis_hidrics := pk_inp_hidrics.get_oldest_hid(i_id_episode);
    
        IF l_oldest_id_epis_hidrics IS NULL
        THEN
            g_error := 'CALL PK_GRID.UPDATE_GRID_TASK - id_episode';
            IF NOT pk_grid.update_grid_task(i_lang          => i_lang,
                                            i_prof          => l_prof,
                                            i_episode       => i_id_episode,
                                            hidrics_reg_in  => NULL,
                                            hidrics_reg_nin => FALSE,
                                            o_error         => l_error_out)
            THEN
                RAISE t_data_gov_mnt.g_excp_invalid_arguments;
            END IF;
        
            g_error := 'CALL PK_GRID.DELETE_EPIS_GRID_TASK - id_episode';
            IF NOT pk_grid.delete_epis_grid_task(i_lang => i_lang, i_episode => i_id_episode, o_error => l_error_out)
            THEN
                RAISE t_data_gov_mnt.g_excp_invalid_arguments;
            END IF;
        END IF;
    
        FOR r_cur IN (SELECT *
                        FROM (SELECT eh.id_epis_hidrics,
                                     epis.id_institution,
                                     ei.id_software,
                                     eh.flg_status l_hid_flg_status,
                                     eh.dt_initial_tstz l_dt_initial,
                                     eh.flg_status flg_status_eh,
                                     eh.id_professional id_professional,
                                     eh.id_hidrics_interval,
                                     decode(eh.flg_status,
                                            pk_inp_hidrics_constant.g_epis_hidric_o,
                                            eh.flg_status,
                                            ehb.flg_status) flg_status,
                                     row_number() over(ORDER BY ehb.dt_eh_balance DESC NULLS LAST) rn
                                FROM epis_hidrics eh
                                JOIN epis_hidrics_balance ehb
                                  ON eh.id_epis_hidrics = ehb.id_epis_hidrics
                                JOIN episode epis
                                  ON eh.id_episode = epis.id_episode
                                JOIN epis_info ei
                                  ON epis.id_episode = ei.id_episode
                               WHERE eh.id_epis_hidrics = l_oldest_id_epis_hidrics
                               ORDER BY ehb.dt_close_balance_tstz DESC NULLS FIRST, ehb.dt_open_tstz DESC) t
                       WHERE t.rn = 1)
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
        
            g_error := 'PK_ACCESS.GET_ID_SHORTCUT for hidrics_LIST';
            IF NOT pk_access.get_id_shortcut(i_lang        => i_lang,
                                             i_prof        => l_prof,
                                             i_intern_name => pk_alert_constant.g_shortcut_hidrics_inten,
                                             o_id_shortcut => l_shortcut,
                                             o_error       => l_error_out)
            THEN
                l_shortcut := NULL;
            END IF;
        
            l_dt_next := nvl(pk_inp_hidrics.get_dt_next_balance(i_lang, l_prof, r_cur.id_epis_hidrics),
                             r_cur.l_dt_initial);
        
            l_grid_task.id_episode := i_id_episode;
        
            IF (r_cur.flg_status_eh <> pk_inp_hidrics_constant.g_epis_hidric_d)
            THEN
            
                l_code_flg_status := CASE
                                         WHEN r_cur.l_hid_flg_status = pk_inp_hidrics_constant.g_epis_hidric_o THEN
                                          'EPIS_HIDRICS.FLG_STATUS'
                                         ELSE
                                          'EPIS_HIDRICS_BALANCE.FLG_STATUS'
                                     END;
                l_value_date      := NULL;
                l_icon            := NULL;
                IF r_cur.l_hid_flg_status NOT IN
                   (pk_inp_hidrics_constant.g_epis_hidric_r, pk_inp_hidrics_constant.g_epis_hidric_e)
                THEN
                    l_icon       := pk_sysdomain.get_img(i_lang, l_code_flg_status, r_cur.l_hid_flg_status);
                    l_value_date := NULL;
                ELSIF r_cur.l_dt_initial > current_timestamp
                THEN
                    l_icon       := pk_sysdomain.get_img(i_lang,
                                                         l_code_flg_status,
                                                         pk_inp_hidrics_constant.g_epis_hidric_r);
                    l_value_date := pk_date_utils.to_char_insttimezone(l_prof,
                                                                       r_cur.l_dt_initial,
                                                                       pk_alert_constant.g_dt_yyyymmddhh24miss_tzr);
                ELSIF r_cur.l_dt_initial <= current_timestamp
                THEN
                    l_icon       := pk_sysdomain.get_img(i_lang,
                                                         l_code_flg_status,
                                                         pk_inp_hidrics_constant.g_epis_hidric_e);
                    l_value_date := pk_date_utils.to_char_insttimezone(l_prof,
                                                                       l_dt_next,
                                                                       pk_alert_constant.g_dt_yyyymmddhh24miss_tzr);
                ELSE
                    l_icon       := NULL;
                    l_value_date := NULL;
                END IF;
            
                -- Construir status string
            
                l_server_date := pk_date_utils.to_char_insttimezone(l_prof,
                                                                    current_timestamp,
                                                                    pk_alert_constant.g_dt_yyyymmddhh24miss_tzr);
            
                g_error := 'GET FLG_STATUS';
                IF r_cur.flg_status IN (pk_inp_hidrics_constant.g_epis_hidric_c,
                                        pk_inp_hidrics_constant.g_epis_hidric_f,
                                        pk_inp_hidrics_constant.g_epis_hidric_d,
                                        pk_inp_hidrics_constant.g_epis_hidric_o,
                                        pk_inp_hidrics_constant.g_epis_hidric_i)
                THEN
                    l_icon_type := 'I';
                ELSIF r_cur.id_hidrics_interval = -1
                THEN
                    l_icon_type := 'I';
                ELSE
                    l_icon_type := 'DI';
                END IF;
            
                g_error := 'CALL PK_UTILS.GET_STATUS_STRING_IMMEDIATE';
                pk_utils.build_status_string(i_display_type => l_icon_type,
                                             i_value_date   => l_value_date,
                                             i_shortcut     => l_shortcut,
                                             i_value_icon   => l_icon,
                                             o_status_str   => l_grid_task.hidrics_reg,
                                             o_status_msg   => l_aux,
                                             o_status_icon  => l_aux,
                                             o_status_flg   => l_aux);
            
                l_grid_task.hidrics_reg := REPLACE(l_grid_task.hidrics_reg,
                                                   pk_alert_constant.g_status_rpl_chr_icon,
                                                   l_icon);
            
                l_grid_task.hidrics_reg := REPLACE(l_grid_task.hidrics_reg,
                                                   pk_alert_constant.g_status_rpl_chr_dt_server,
                                                   l_server_date) || '|';
                --
                g_error := 'CALL PK_GRID.UPDATE_GRID_TASK - id_episode';
                IF NOT pk_grid.update_grid_task(i_lang          => i_lang,
                                                i_prof          => l_prof,
                                                i_episode       => l_grid_task.id_episode,
                                                hidrics_reg_in  => l_grid_task.hidrics_reg,
                                                hidrics_reg_nin => FALSE,
                                                o_error         => l_error_out)
                THEN
                    RAISE t_data_gov_mnt.g_excp_invalid_arguments;
                END IF;
            
            ELSE
            
                g_error := 'CALL PK_GRID.UPDATE_GRID_TASK - id_episode';
                IF NOT pk_grid.update_grid_task(i_lang          => i_lang,
                                                i_prof          => l_prof,
                                                i_episode       => l_grid_task.id_episode,
                                                hidrics_reg_in  => NULL,
                                                hidrics_reg_nin => FALSE,
                                                o_error         => l_error_out)
                THEN
                    RAISE t_data_gov_mnt.g_excp_invalid_arguments;
                END IF;
            
                g_error := 'CALL PK_GRID.DELETE_EPIS_GRID_TASK - id_episode';
                IF NOT pk_grid.delete_epis_grid_task(i_lang    => i_lang,
                                                     i_episode => l_grid_task.id_episode,
                                                     o_error   => l_error_out)
                THEN
                    RAISE t_data_gov_mnt.g_excp_invalid_arguments;
                END IF;
            END IF;
        END LOOP;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => g_error);
    END ins_grid_task_hidrics_epis;

BEGIN
    -- log init
    pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    pk_alertlog.log_init(object_name => g_package);
END pk_ea_logic_hidrics;
/
