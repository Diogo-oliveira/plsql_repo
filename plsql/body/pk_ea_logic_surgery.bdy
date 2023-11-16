/*-- Last Change Revision: $Rev: 2046213 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2022-09-23 17:16:28 +0100 (sex, 23 set 2022) $*/
CREATE OR REPLACE PACKAGE BODY pk_ea_logic_surgery IS

    g_error        VARCHAR2(1000 CHAR);
    g_owner        VARCHAR2(30 CHAR);
    g_package      VARCHAR2(30 CHAR);
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;

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
    ) IS
        l_func_name         CONSTANT VARCHAR2(30 CHAR) := 'SET_TASK_TIMELINE';
        l_ea_table          CONSTANT VARCHAR2(30 CHAR) := 'TASK_TIMELINE_EA';
        l_src_table         CONSTANT VARCHAR2(30 CHAR) := 'SCHEDULE_SR';
        l_src_table_sr_epis CONSTANT VARCHAR2(30 CHAR) := 'SR_EPIS_INTERV';
        l_ea_row         task_timeline_ea%ROWTYPE;
        l_ea_row_sr_epis task_timeline_ea%ROWTYPE;
        l_count          NUMBER(12);
        l_error          t_error_out;
    
        CURSOR c_surgery IS
            SELECT sr.id_schedule_sr,
                   sr.id_episode,
                   sr.id_patient,
                   decode(sr.flg_status,
                          pk_alert_constant.g_cancelled,
                          pk_alert_constant.g_cancelled,
                          decode(pk_surgery_request.get_epis_done_state(i_lang,
                                                                        wl.id_waiting_list,
                                                                        pk_alert_constant.g_epis_type_operating),
                                 pk_alert_constant.g_yes,
                                 pk_alert_constant.g_surgery_record_status_f,
                                 wl.flg_status)) flg_status,
                   sr.id_prof_reg,
                   CASE
                        WHEN wl.id_waiting_list IS NOT NULL THEN
                         pk_surgery_request.get_wl_status_date_dtz(i_lang,
                                                                   i_prof,
                                                                   sr.id_episode,
                                                                   wl.id_waiting_list,
                                                                   pk_surgery_request.get_wl_status_flg(i_lang,
                                                                                                        i_prof,
                                                                                                        wl.id_waiting_list,
                                                                                                        decode(wl.flg_type,
                                                                                                               pk_alert_constant.g_wl_status_a,
                                                                                                               pk_alert_constant.g_yes,
                                                                                                               pk_alert_constant.g_no),
                                                                                                        pos.id_sr_pos_status,
                                                                                                        pk_alert_constant.g_epis_type_operating,
                                                                                                        wl.flg_type))
                        ELSE
                         NULL
                    END dt_req,
                   decode(sr.flg_sched,
                          pk_alert_constant.g_schedule_sr_sched_a,
                          sr.dt_target_tstz,
                          decode(wl.id_waiting_list, NULL, sr.dt_target_tstz, nvl(wl.dt_surgery, wl.dt_dpb))) dt_begin,
                   decode(sr.flg_sched,
                          pk_alert_constant.g_schedule_sr_sched_a,
                          s.dt_end_tstz,
                          decode(wl.id_waiting_list, NULL, NULL, wl.dt_dpa)) dt_end,
                   sr.id_institution,
                   epi.id_visit,
                   epi.flg_status flg_status_epis,
                   nvl(sr.adm_needed, pk_alert_constant.g_no) adm_needed,
                   (SELECT COUNT(1)
                      FROM sr_epis_interv sei
                     WHERE sei.id_episode_context = sr.id_episode
                       AND sei.flg_status NOT IN (pk_sr_planning.g_cancel)
                       AND rownum = 1) exists_sei,
                   sr.id_waiting_list
              FROM schedule_sr sr
              LEFT JOIN schedule s
                ON s.id_schedule = sr.id_schedule
              LEFT JOIN sr_pos_schedule pos
                ON pos.id_schedule_sr = sr.id_schedule_sr
              LEFT JOIN waiting_list wl
                ON wl.id_waiting_list = sr.id_waiting_list
              JOIN episode epi
                ON epi.id_episode = sr.id_episode
             WHERE sr.rowid IN (SELECT vc_1
                                  FROM tbl_temp);
    
        TYPE t_coll_surgery IS TABLE OF c_surgery%ROWTYPE;
        l_surgery_rows t_coll_surgery;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
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
        
            -- get surgery data from rowids
            g_error := 'OPEN c_surgery';
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            DELETE FROM tbl_temp;
            insert_tbl_temp(i_vc_1 => i_rowids);
        
            OPEN c_surgery;
            FETCH c_surgery BULK COLLECT
                INTO l_surgery_rows;
            CLOSE c_surgery;
        
            -- copy surgery data into rows collection
            IF l_surgery_rows IS NOT NULL
               AND l_surgery_rows.count > 0
            THEN
                -- set constant fields
                l_ea_row.table_name        := l_src_table;
                l_ea_row.id_tl_task        := pk_prog_notes_constants.g_task_surg;
                l_ea_row.flg_show_method   := pk_alert_constant.g_tl_oriented_patient;
                l_ea_row.dt_dg_last_update := g_sysdate_tstz;
                l_ea_row.flg_sos           := pk_alert_constant.g_no;
                l_ea_row.flg_normal        := pk_alert_constant.g_yes;
                l_ea_row.flg_has_comments  := pk_alert_constant.g_no;
            
                -- set variable fields
                FOR i IN l_surgery_rows.first .. l_surgery_rows.last
                LOOP
                    l_ea_row.id_task_refid  := l_surgery_rows(i).id_schedule_sr;
                    l_ea_row.id_patient     := l_surgery_rows(i).id_patient;
                    l_ea_row.id_episode     := l_surgery_rows(i).id_episode;
                    l_ea_row.id_visit       := l_surgery_rows(i).id_visit;
                    l_ea_row.id_institution := l_surgery_rows(i).id_institution;
                    l_ea_row.dt_req         := l_surgery_rows(i).dt_req;
                    l_ea_row.dt_begin       := l_surgery_rows(i).dt_begin;
                    l_ea_row.dt_end         := l_surgery_rows(i).dt_end;
                    l_ea_row.id_prof_req    := l_surgery_rows(i).id_prof_reg;
                    l_ea_row.flg_status_req := l_surgery_rows(i).flg_status;
                    l_ea_row.flg_outdated   := pk_ea_logic_tasktimeline.g_flg_not_outdated;
                
                    IF l_surgery_rows(i).id_waiting_list IS NULL
                    THEN
                        l_ea_row.flg_ongoing := pk_prog_notes_constants.g_task_finalized_f;
                    ELSE
                        l_ea_row.flg_ongoing := pk_prog_notes_constants.g_task_ongoing_o;
                    END IF;
                
                    l_ea_row.dt_last_execution := nvl(l_surgery_rows(i).dt_req, g_sysdate_tstz);
                    l_ea_row.dt_last_update    := nvl(l_surgery_rows(i).dt_req, g_sysdate_tstz);
                
                    g_error := 'FOR LOOP id_task_refid: ' || l_ea_row.id_task_refid || ' flg_status: ' || l_surgery_rows(i).flg_status;
                    pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                
                    --if it was canceled there is nothing to insert or update 
                    -- if it is part od an admission do not consider it, and delete it, just in case
                    -- it should appear in the admission section
                    IF l_surgery_rows(i)
                     .flg_status_epis = pk_alert_constant.g_epis_status_cancel
                        OR l_surgery_rows(i)
                       .flg_status IN (pk_alert_constant.g_surgery_record_status_f, pk_alert_constant.g_cancelled)
                        OR l_surgery_rows(i).adm_needed = pk_alert_constant.g_yes
                        OR l_surgery_rows(i).exists_sei = 0
                    THEN
                        g_error := 'CALL TS_TASK_TIMELINE_EA.DEL';
                        pk_alertlog.log_debug(text            => g_error,
                                              object_name     => g_package,
                                              sub_object_name => l_func_name);
                        ts_task_timeline_ea.del(id_task_refid_in => l_ea_row.id_task_refid,
                                                id_tl_task_in    => l_ea_row.id_tl_task);
                    ELSE
                        -- check if it already exists
                        SELECT COUNT(1)
                          INTO l_count
                          FROM task_timeline_ea a
                         WHERE a.id_task_refid = l_ea_row.id_task_refid
                           AND a.id_tl_task = l_ea_row.id_tl_task;
                    
                        -- insert or update EA
                        IF l_count = 0
                        THEN
                            g_error := 'CALL ts_task_timeline_ea.ins I';
                            pk_alertlog.log_debug(text            => g_error,
                                                  object_name     => g_package,
                                                  sub_object_name => l_func_name);
                            ts_task_timeline_ea.ins(rec_in => l_ea_row);
                        ELSE
                            g_error := 'CALL ts_task_timeline_ea.upd';
                            pk_alertlog.log_debug(text            => g_error,
                                                  object_name     => g_package,
                                                  sub_object_name => l_func_name);
                            ts_task_timeline_ea.upd(rec_in => l_ea_row);
                        END IF;
                    
                    END IF;
                END LOOP;
            
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

    PROCEDURE set_task_ea_sr_epis_interv
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_event_type   IN VARCHAR2,
        i_rowids       IN table_varchar,
        i_src_table    IN VARCHAR2,
        i_list_columns IN table_varchar,
        i_dg_table     IN VARCHAR2
    ) IS
    
        l_func_name         CONSTANT VARCHAR2(30 CHAR) := 'SET_TASK_TIMELINE';
        l_ea_table          CONSTANT VARCHAR2(30 CHAR) := 'TASK_TIMELINE_EA';
        l_src_table         CONSTANT VARCHAR2(30 CHAR) := 'SR_EPIS_INTERV';
        l_src_table_sr_epis CONSTANT VARCHAR2(30 CHAR) := 'SR_EPIS_INTERV';
        l_ea_row         task_timeline_ea%ROWTYPE;
        l_ea_row_sr_epis task_timeline_ea%ROWTYPE;
        l_count          NUMBER(12);
        l_error          t_error_out;
    
        CURSOR c_sr_epis_interv IS
            SELECT sei.id_sr_epis_interv,
                   sei.id_episode_context,
                   pk_episode.get_id_patient(sei.id_episode_context) id_patient,
                   sei.flg_status,
                   sei.id_prof_req,
                   sei.dt_req_tstz,
                   sei.dt_interv_start_tstz,
                   sei.dt_interv_end_tstz,
                   pk_episode.get_id_visit(sei.id_episode_context) id_visit,
                   e.flg_status flg_status_epis
            
              FROM sr_epis_interv sei
              JOIN episode e
                ON e.id_episode = sei.id_episode
             WHERE sei.rowid IN (SELECT vc_1
                                   FROM tbl_temp);
    
        TYPE t_coll_sr_epis_interv IS TABLE OF c_sr_epis_interv%ROWTYPE;
        l_sr_epis_interv_rows t_coll_sr_epis_interv;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
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
        
            -- get surgery data from rowids
            g_error := 'OPEN c_surgery';
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            DELETE FROM tbl_temp;
            insert_tbl_temp(i_vc_1 => i_rowids);
        
            OPEN c_sr_epis_interv;
            FETCH c_sr_epis_interv BULK COLLECT
                INTO l_sr_epis_interv_rows;
            CLOSE c_sr_epis_interv;
        
            -- copy surgery data into rows collection
            IF (l_sr_epis_interv_rows IS NOT NULL AND l_sr_epis_interv_rows.count > 0)
            THEN
            
                -- set constant fields
                l_ea_row_sr_epis.table_name        := l_src_table_sr_epis;
                l_ea_row_sr_epis.id_tl_task        := pk_prog_notes_constants.g_task_surg_procedures;
                l_ea_row_sr_epis.flg_show_method   := pk_alert_constant.g_tl_oriented_patient;
                l_ea_row_sr_epis.dt_dg_last_update := g_sysdate_tstz;
                l_ea_row_sr_epis.flg_sos           := pk_alert_constant.g_no;
                l_ea_row_sr_epis.flg_normal        := pk_alert_constant.g_yes;
                l_ea_row_sr_epis.flg_has_comments  := pk_alert_constant.g_no;
            
                -- set variable fields
                FOR i IN l_sr_epis_interv_rows.first .. l_sr_epis_interv_rows.last
                LOOP
                    l_ea_row_sr_epis.id_task_refid     := l_sr_epis_interv_rows(i).id_sr_epis_interv;
                    l_ea_row_sr_epis.id_patient        := l_sr_epis_interv_rows(i).id_patient;
                    l_ea_row_sr_epis.id_episode        := l_sr_epis_interv_rows(i).id_episode_context;
                    l_ea_row_sr_epis.id_visit          := l_sr_epis_interv_rows(i).id_visit;
                    l_ea_row_sr_epis.id_institution    := i_prof.institution;
                    l_ea_row_sr_epis.dt_req            := l_sr_epis_interv_rows(i).dt_req_tstz;
                    l_ea_row_sr_epis.dt_begin          := l_sr_epis_interv_rows(i).dt_interv_start_tstz;
                    l_ea_row_sr_epis.dt_end            := l_sr_epis_interv_rows(i).dt_interv_end_tstz;
                    l_ea_row_sr_epis.id_prof_req       := l_sr_epis_interv_rows(i).id_prof_req;
                    l_ea_row_sr_epis.flg_status_req    := l_sr_epis_interv_rows(i).flg_status;
                    l_ea_row_sr_epis.flg_outdated      := pk_ea_logic_tasktimeline.g_flg_not_outdated;
                    l_ea_row_sr_epis.flg_ongoing := CASE
                                                        WHEN l_sr_epis_interv_rows(i).flg_status = 'C' THEN
                                                         'I'
                                                        ELSE
                                                         l_sr_epis_interv_rows(i).flg_status
                                                    END;
                    l_ea_row_sr_epis.dt_last_execution := nvl(l_sr_epis_interv_rows(i).dt_req_tstz, g_sysdate_tstz);
                    l_ea_row_sr_epis.dt_last_update    := nvl(l_sr_epis_interv_rows(i).dt_req_tstz, g_sysdate_tstz);
                
                    g_error := 'FOR LOOP id_task_refid: ' || l_ea_row_sr_epis.id_task_refid || ' flg_status: ' || l_sr_epis_interv_rows(i).flg_status;
                    pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                
                    --if it was canceled there is nothing to insert or update 
                    -- if it is part od an admission do not consider it, and delete it, just in case
                    -- it should appear in the admission section
                    IF l_sr_epis_interv_rows(i).flg_status_epis = pk_alert_constant.g_epis_status_cancel
                    /*OR l_sr_epis_interv_rows(i)
                                                               .flg_status IN (pk_alert_constant.g_surgery_record_status_f, pk_alert_constant.g_cancelled)*/
                    THEN
                        g_error := 'CALL TS_TASK_TIMELINE_EA.DEL';
                        pk_alertlog.log_debug(text            => g_error,
                                              object_name     => g_package,
                                              sub_object_name => l_func_name);
                        ts_task_timeline_ea.del(id_task_refid_in => l_ea_row_sr_epis.id_task_refid,
                                                id_tl_task_in    => l_ea_row_sr_epis.id_tl_task);
                    ELSE
                        -- check if it already exists
                        SELECT COUNT(1)
                          INTO l_count
                          FROM task_timeline_ea a
                         WHERE a.id_task_refid = l_ea_row_sr_epis.id_task_refid
                           AND a.id_tl_task = l_ea_row_sr_epis.id_tl_task;
                    
                        -- insert or update EA
                        IF l_count = 0
                        THEN
                            g_error := 'CALL ts_task_timeline_ea.ins I';
                            pk_alertlog.log_debug(text            => g_error,
                                                  object_name     => g_package,
                                                  sub_object_name => l_func_name);
                            ts_task_timeline_ea.ins(rec_in => l_ea_row_sr_epis);
                        ELSE
                            g_error := 'CALL ts_task_timeline_ea.upd';
                            pk_alertlog.log_debug(text            => g_error,
                                                  object_name     => g_package,
                                                  sub_object_name => l_func_name);
                            ts_task_timeline_ea.upd(rec_in => l_ea_row_sr_epis);
                        END IF;
                    
                    END IF;
                END LOOP;
            
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
        
    END set_task_ea_sr_epis_interv;

BEGIN
    -- Initialization

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);

END pk_ea_logic_surgery;
/
