/*-- Last Change Revision: $Rev: 2027328 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:52 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_logic_movements IS

    /********************************************************************************************
    * Calculate the status of an movement request
    *
    * @param    I_PROF                 Object (ID of professional, ID of institution, ID of software)
    * @param    I_FLG_REFERRAL         Referral flag
    * @param    I_DT_REQ               Analysis request date
    * @param    I_DT_PEND_REQ          Pending request date
    * @param    I_DT_TARGET            Target date
    * @param    I_FLG_STATUS_DET       Detail status flag
    * @param    I_FLG_STATUS_HARVEST   Harvest status flag
    * @param    I_FLG_TIME_HARVEST     Execution type flag
    * @param    O_STATUS_STR           Status string
    * @param    O_STATUS_MSG           Status message
    * @param    O_STATUS_ICON          Status icon
    * @param    O_STATUS_FLG           Status flag
    *
    * 
    * @return                         Return FALSE if an error occours, otherwise return TRUE
    * @raises                         PL/SQL generic erro "OTHERS"
    *
    * @author   Luís Maia
    * @version  2.5.0.2
    * @since    2009/04/23
    ********************************************************************************************/
    PROCEDURE get_movement_status
    (
        i_prof        IN profissional,
        i_dt_req      IN movement.dt_req_tstz%TYPE,
        i_dt_begin    IN movement.dt_begin_tstz%TYPE,
        i_dt_end      IN movement.dt_end_tstz%TYPE,
        i_flg_status  IN movement.flg_status%TYPE,
        o_status_str  OUT VARCHAR2,
        o_status_msg  OUT VARCHAR2,
        o_status_icon OUT VARCHAR2,
        o_status_flg  OUT VARCHAR2
    ) IS
    
        l_display_type VARCHAR2(30) := '';
        l_back_color   VARCHAR2(30) := '';
        l_status_flg   VARCHAR2(30) := '';
        l_icon_color   VARCHAR2(30) := '';
        --
        l_aux        VARCHAR2(200);
        l_date_begin VARCHAR2(200);
        --
        i_lang      language.id_language%TYPE := NULL;
        l_error_out t_error_out;
    
        CURSOR c_info IS
            SELECT
            -- dt_begin
             pk_date_utils.to_char_insttimezone(i_prof,
                                                nvl(i_dt_begin, i_dt_req),
                                                pk_alert_constant.g_dt_yyyymmddhh24miss_tzr) date_begin,
             
             -- l_aux
             'MOVEMENT.FLG_STATUS' desc_stat,
             
             -- l_display_type
             decode(i_flg_status,
                    pk_alert_constant.g_mov_status_transp,
                    pk_alert_constant.g_display_type_icon, -- ICON
                    pk_alert_constant.g_mov_status_finish,
                    NULL,
                    pk_alert_constant.g_mov_status_pend,
                    pk_alert_constant.g_display_type_date, -- DATE
                    pk_alert_constant.g_mov_status_req,
                    pk_alert_constant.g_display_type_date, -- DATE
                    pk_alert_constant.g_mov_status_interr,
                    NULL,
                    pk_alert_constant.g_mov_status_cancel,
                    NULL,
                    NULL) flg_text,
             
             -- l_back_color
             decode(i_flg_status,
                    pk_alert_constant.g_mov_status_transp,
                    NULL,
                    pk_alert_constant.g_mov_status_finish,
                    NULL,
                    pk_alert_constant.g_mov_status_pend,
                    NULL,
                    pk_alert_constant.g_mov_status_req,
                    NULL,
                    pk_alert_constant.g_mov_status_interr,
                    NULL,
                    pk_alert_constant.g_mov_status_cancel,
                    NULL,
                    NULL) color_status,
             -- status_flg                      
             decode(i_flg_status,
                    pk_alert_constant.g_mov_status_transp,
                    pk_alert_constant.g_mov_status_transp,
                    pk_alert_constant.g_mov_status_finish,
                    pk_alert_constant.g_mov_status_finish,
                    pk_alert_constant.g_mov_status_pend,
                    pk_alert_constant.g_mov_status_pend,
                    pk_alert_constant.g_mov_status_req,
                    pk_alert_constant.g_mov_status_req,
                    pk_alert_constant.g_mov_status_interr,
                    pk_alert_constant.g_mov_status_interr,
                    pk_alert_constant.g_mov_status_cancel,
                    pk_alert_constant.g_mov_status_cancel,
                    NULL) status_flg
              FROM dual;
    
    BEGIN
    
        g_error := 'GET MOVEMENTS STATUS';
        OPEN c_info;
        FETCH c_info
            INTO l_date_begin, l_aux, l_display_type, l_back_color, l_status_flg;
        CLOSE c_info;
    
        pk_utils.build_status_string(i_display_type => l_display_type,
                                     i_flg_state    => l_status_flg,
                                     i_value_text   => l_aux,
                                     i_value_date   => l_date_begin,
                                     i_value_icon   => l_aux,
                                     i_back_color   => l_back_color,
                                     i_icon_color   => l_icon_color,
                                     o_status_str   => o_status_str,
                                     o_status_msg   => o_status_msg,
                                     o_status_icon  => o_status_icon,
                                     o_status_flg   => o_status_flg);
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_MOVEMENT_STATUS',
                                              l_error_out);
    END get_movement_status;

    /*******************************************************************************************************************************************
    * Name:                           SET_TASK_TIMELINE_TRANSP
    * Description:                    Function that updates movements information in the Task Timeline Easy Access table (task_timeline_ea)
    * 
    * @param I_LANG                   Language ID
    * @param I_PROF                   Professional information Vector: (professional ID, institution ID, software ID)
    * @param I_EVENT_TYPE             Type of event (UPDATE, INSERT, etc)
    * @param I_ROWIDS                 List of ROWIDs belonging to the changed records.
    * @param I_LIST_COLUMNS           List of columns that were changed
    * @param I_SOURCE_TABLE_NAME      Name of the table that was changed.
    * @param I_DG_TABLE_NAME          Name of the Data Governance table.
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * @value I_EVENT_TYPE             {*} t_data_gov_mnt.g_event_insert {*} t_data_gov_mnt.g_event_update {*} t_data_gov_mnt.g_event_delete
    * 
    * @return                         Return FALSE if an error occours, otherwise return TRUE
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Luís Maia
    * @version                        1.0
    * @since                          2009/04/22
    *******************************************************************************************************************************************/
    PROCEDURE set_task_timeline_transp
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
    
        l_new_rec_row      task_timeline_ea%ROWTYPE;
        l_func_proc_name   VARCHAR2(30) := 'SET_TASK_TIMELINE_TRANSP';
        l_name_table_ea    VARCHAR2(30) := 'TASK_TIMELINE_EA';
        l_process_name     VARCHAR2(30);
        l_event_into_ea    VARCHAR2(1);
        l_update_reg       NUMBER(24);
        o_rowids           table_varchar;
        l_error_out        t_error_out;
        l_flg_outdated     task_timeline_ea.flg_outdated%TYPE := 1;
        l_flg_not_outdated task_timeline_ea.flg_outdated%TYPE := 0;
    
        l_timestamp TIMESTAMP(6) WITH LOCAL TIME ZONE := current_timestamp;
    
    BEGIN
        -- Validate arguments
        g_error := 'VALIDATE ARGUMENTS';
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => i_source_table_name,
                                                 i_expected_dg_table_name => l_name_table_ea,
                                                 i_list_columns           => i_list_columns,
                                                 i_expected_columns       => NULL)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        -- Process insert and update event
        IF i_event_type IN
           (t_data_gov_mnt.g_event_insert, t_data_gov_mnt.g_event_update, t_data_gov_mnt.g_event_delete)
        THEN
        
            IF i_event_type = t_data_gov_mnt.g_event_insert
            THEN
                l_process_name  := 'INSERT';
                l_event_into_ea := 'I';
            ELSIF i_event_type = t_data_gov_mnt.g_event_update
            THEN
                l_process_name  := 'UNDEFINED';
                l_event_into_ea := '';
            ELSIF i_event_type = t_data_gov_mnt.g_event_delete
            THEN
                l_process_name  := 'DELETE';
                l_event_into_ea := 'D';
            END IF;
        
            pk_alertlog.log_debug('Processing ' || l_process_name || ' on ' || i_source_table_name || ' (' ||
                                  l_name_table_ea || ')',
                                  g_package_name,
                                  l_func_proc_name);
        
            -- Loop through changed records
            g_error := 'LOOP PROCESS';
            pk_alertlog.log_debug(g_error);
            IF ((i_rowids IS NOT NULL) AND (i_rowids.count > 0))
            THEN
            
                -- Insert i_rowids into table tbl_temp to increase performance
                DELETE FROM tbl_temp;
                insert_tbl_temp(i_vc_1 => i_rowids);
            
                g_error := 'GET MOVEMENT ROWIDS AND INFORMATION';
                pk_alertlog.log_debug(g_error);
                FOR r_cur IN (SELECT /*+ opt_estimate(table mov rows=1) */
                               mov.id_episode,
                               mov.id_movement,
                               mov.dt_req_tstz dt_req,
                               mov.dt_begin_tstz dt_begin,
                               mov.dt_end_tstz dt_end,
                               mov.flg_status,
                               mov.id_prof_request,
                               epi.id_patient,
                               epi.id_visit,
                               epi.id_institution,
                               NULL universal_desc_clob,
                               'TL_TASK.CODE_TL_TASK.9' code_task,
                               decode(mov.flg_status,
                                      pk_alert_constant.g_mov_status_finish,
                                      pk_prog_notes_constants.g_task_finalized_f,
                                      pk_prog_notes_constants.g_task_ongoing_o) flg_ongoing,
                               pk_alert_constant.g_yes flg_normal,
                               coalesce(mov.id_prof_receive, mov.id_prof_move, mov.id_prof_request) id_prof_exec,
                               epi.flg_status flg_status_epis
                                FROM movement mov
                               INNER JOIN episode epi
                                  ON (epi.id_episode = mov.id_episode)
                               INNER JOIN room ro
                                  ON (ro.id_room = mov.id_room_to)
                               INNER JOIN department dep
                                  ON (dep.id_department = ro.id_department)
                               WHERE mov.rowid IN (SELECT vc_1
                                                     FROM tbl_temp))
                
                LOOP
                
                    g_error := 'GET MOVEMENTS STATUS';
                    get_movement_status(i_prof,
                                        r_cur.dt_req,
                                        r_cur.dt_begin,
                                        r_cur.dt_end,
                                        r_cur.flg_status,
                                        l_new_rec_row.status_str,
                                        l_new_rec_row.status_msg,
                                        l_new_rec_row.status_icon,
                                        l_new_rec_row.status_flg);
                
                    --
                    g_error := 'DEFINE NEW RECORD FOR TASK_TIMELINE_EA';
                    --
                    l_new_rec_row.id_tl_task        := pk_prog_notes_constants.g_task_transports;
                    l_new_rec_row.table_name        := pk_alert_constant.g_tl_table_name_transp;
                    l_new_rec_row.flg_show_method   := pk_alert_constant.g_tl_oriented_episode;
                    l_new_rec_row.dt_dg_last_update := current_timestamp;
                    --
                    l_new_rec_row.id_task_refid  := r_cur.id_movement;
                    l_new_rec_row.dt_req         := r_cur.dt_req;
                    l_new_rec_row.dt_begin       := nvl(r_cur.dt_begin, r_cur.dt_req);
                    l_new_rec_row.dt_end         := r_cur.dt_end;
                    l_new_rec_row.flg_status_req := r_cur.flg_status;
                    l_new_rec_row.id_prof_req    := r_cur.id_prof_request;
                    --
                    l_new_rec_row.id_patient          := r_cur.id_patient;
                    l_new_rec_row.id_episode          := r_cur.id_episode;
                    l_new_rec_row.id_visit            := r_cur.id_visit;
                    l_new_rec_row.id_institution      := r_cur.id_institution;
                    l_new_rec_row.universal_desc_clob := r_cur.universal_desc_clob;
                    l_new_rec_row.code_description    := r_cur.code_task;
                    l_new_rec_row.flg_outdated        := l_flg_not_outdated;
                    l_new_rec_row.flg_sos             := pk_alert_constant.g_no;
                    l_new_rec_row.flg_ongoing         := r_cur.flg_ongoing;
                    l_new_rec_row.flg_normal          := r_cur.flg_normal;
                    l_new_rec_row.id_prof_exec        := r_cur.id_prof_exec;
                    l_new_rec_row.flg_has_comments    := pk_alert_constant.g_no;
                    l_new_rec_row.dt_last_update      := l_timestamp;
                
                    --
                    pk_alertlog.log_debug('Processing ' || l_process_name || ' on ' || i_source_table_name || ' (' ||
                                          l_name_table_ea || '): ' || g_error,
                                          g_package_name,
                                          l_func_proc_name);
                
                    --
                    -- Events in TASK_TIMELINE_EA table is dependent of l_new_rec_row.flg_status_req variable
                    IF (l_new_rec_row.flg_status_req = pk_alert_constant.g_mov_status_req -- Required ('R')
                       OR l_new_rec_row.flg_status_req = pk_alert_constant.g_mov_status_pend -- pendent ('P')
                       OR l_new_rec_row.flg_status_req = pk_alert_constant.g_mov_status_transp -- In Transport ('T')                    
                       )
                       AND r_cur.flg_status_epis <> pk_alert_constant.g_epis_status_cancel
                    THEN
                        -- Search for updated registrie
                        SELECT COUNT(0)
                          INTO l_update_reg
                          FROM task_timeline_ea tte
                         WHERE tte.id_task_refid = l_new_rec_row.id_task_refid
                           AND tte.table_name = pk_alert_constant.g_tl_table_name_transp
                           AND tte.id_tl_task = pk_prog_notes_constants.g_task_transports;
                    
                        -- IF exists one registrie, information should be UPDATED in TASK_TIMELINE_EA table for this registrie
                        IF l_update_reg > 0
                        THEN
                            l_process_name  := 'UPDATE';
                            l_event_into_ea := 'U';
                        ELSE
                            -- IF information doesn't exist in TASK_TIMELINE_EA table, it is necessary insert that registrie
                            l_process_name  := 'INSERT';
                            l_event_into_ea := 'I';
                        END IF;
                    ELSE
                        --IF l_new_rec_row.flg_status_req = pk_alert_constant.g_mov_status_cancel -- Cancelled ('C')
                        --OR l_new_rec_row.flg_status_req = pk_alert_constant.g_mov_status_finish -- Finished ('F')
                        --OR l_new_rec_row.flg_status_req = pk_alert_constant.g_mov_status_interr -- Interrupted ('I')
                        --
                        -- Information in states that are not relevant are DELETED
                        IF l_new_rec_row.flg_status_req = pk_alert_constant.g_mov_status_cancel
                           OR r_cur.flg_status_epis = pk_alert_constant.g_epis_status_cancel
                        THEN
                            -- Cancelled ('C')
                            l_process_name  := 'DELETE';
                            l_event_into_ea := 'D';
                        ELSE
                            l_process_name             := 'UPDATE';
                            l_event_into_ea            := 'U';
                            l_new_rec_row.flg_outdated := l_flg_outdated;
                        END IF;
                    END IF;
                
                    /*
                    * Operações a executar sobre a tabela de Easy Access TASK_TIMELINE_EA: 
                    *  -> INSERT;
                    *  -> DELETE;
                    *  -> UPDATE.
                    */
                    IF l_event_into_ea = t_data_gov_mnt.g_event_insert
                    -- INSERT
                    THEN
                        g_error := 'TS_TASK_TIMELINE_EA.INS';
                        ts_task_timeline_ea.ins(rec_in => l_new_rec_row, rows_out => o_rowids);
                    
                    ELSIF l_event_into_ea = t_data_gov_mnt.g_event_delete
                    -- DELETE: Apenas poderão ocorrer DELETE's nas tabelas ANALYSIS_REQ e ANALYSIS_REQ_DET
                    THEN
                        g_error := 'TS_TASK_TIMELINE_EA.DEL_BY';
                        ts_task_timeline_ea.del_by(where_clause_in => 'id_task_refid = ' || l_new_rec_row.id_task_refid ||
                                                                      ' AND id_tl_task = ' || l_new_rec_row.id_tl_task,
                                                   rows_out        => o_rowids);
                    
                    ELSIF l_event_into_ea = t_data_gov_mnt.g_event_update
                    -- UPDATE
                    THEN
                        g_error := 'TS_TASK_TIMELINE_EA.UPD';
                        ts_task_timeline_ea.upd(id_task_refid_in => l_new_rec_row.id_task_refid,
                                                id_tl_task_in    => l_new_rec_row.id_tl_task,
                                                --
                                                id_patient_nin     => FALSE,
                                                id_patient_in      => l_new_rec_row.id_patient,
                                                id_episode_nin     => FALSE,
                                                id_episode_in      => l_new_rec_row.id_episode,
                                                id_visit_nin       => FALSE,
                                                id_visit_in        => l_new_rec_row.id_visit,
                                                id_institution_nin => FALSE,
                                                id_institution_in  => l_new_rec_row.id_institution,
                                                --
                                                dt_req_nin      => TRUE,
                                                dt_req_in       => l_new_rec_row.dt_req,
                                                id_prof_req_nin => TRUE,
                                                id_prof_req_in  => l_new_rec_row.id_prof_req,
                                                --
                                                dt_begin_nin => TRUE,
                                                dt_begin_in  => l_new_rec_row.dt_begin,
                                                dt_end_nin   => TRUE,
                                                dt_end_in    => l_new_rec_row.dt_end,
                                                --
                                                flg_status_req_nin => FALSE,
                                                flg_status_req_in  => l_new_rec_row.flg_status_req,
                                                status_str_nin     => FALSE,
                                                status_str_in      => l_new_rec_row.status_str,
                                                status_msg_nin     => FALSE,
                                                status_msg_in      => l_new_rec_row.status_msg,
                                                status_icon_nin    => FALSE,
                                                status_icon_in     => l_new_rec_row.status_icon,
                                                status_flg_nin     => FALSE,
                                                status_flg_in      => l_new_rec_row.status_flg,
                                                --
                                                table_name_nin          => FALSE,
                                                table_name_in           => l_new_rec_row.table_name,
                                                flg_show_method_nin     => FALSE,
                                                flg_show_method_in      => l_new_rec_row.flg_show_method,
                                                code_description_nin    => FALSE,
                                                code_description_in     => l_new_rec_row.code_description,
                                                universal_desc_clob_nin => TRUE,
                                                universal_desc_clob_in  => l_new_rec_row.universal_desc_clob,
                                                --
                                                flg_outdated_nin     => TRUE,
                                                flg_outdated_in      => l_new_rec_row.flg_outdated,
                                                flg_sos_nin          => FALSE,
                                                flg_sos_in           => l_new_rec_row.flg_sos,
                                                flg_ongoing_nin      => TRUE,
                                                flg_ongoing_in       => l_new_rec_row.flg_ongoing,
                                                flg_normal_nin       => TRUE,
                                                flg_normal_in        => l_new_rec_row.flg_normal,
                                                id_prof_exec_nin     => TRUE,
                                                id_prof_exec_in      => l_new_rec_row.id_prof_exec,
                                                flg_has_comments_nin => TRUE,
                                                flg_has_comments_in  => l_new_rec_row.flg_has_comments,
                                                dt_last_update_in    => l_new_rec_row.dt_last_update,
                                                rows_out             => o_rowids);
                    
                    ELSE
                        -- EXCEPTION: Unexpected event type
                        RAISE g_excp_invalid_event_type;
                    END IF;
                
                END LOOP;
                pk_alertlog.log_debug('END LOOP');
            
            END IF;
        
        END IF;
    
    EXCEPTION
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
        WHEN g_excp_invalid_event_type THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_EVENT_TYPE');
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_TASK_TIMELINE_TRANSP',
                                              l_error_out);
        
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
        
    END set_task_timeline_transp;

    /*******************************************************************************************************************************************
    * Name:                           GET_MOVEMENT_STATUS_STR
    * Description:                    Function that calculates the status string for movements
    * 
    * @param I_LANG                   Language ID
    * @param I_PROF                   Professional information Vector: (professional ID, institution ID, software ID)
    * @param i_episode                Episode identifier
    * 
    * @return                         String with the status string
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Elisabete Bugalho
    * @version                        2.6.5
    * @since                          2015/05/27
    *******************************************************************************************************************************************/

    FUNCTION get_movement_status_str
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        CURSOR c_movement IS
            SELECT s.rank, mov.dt_req_tstz dt_req, mov.flg_status, nvl(mov.dt_begin_tstz, mov.dt_req_tstz) dt_begin
              FROM movement mov, sys_domain s
             WHERE mov.id_episode = i_episode
               AND mov.flg_status NOT IN (pk_alert_constant.g_mov_status_cancel,
                                          pk_alert_constant.g_mov_status_finish,
                                          pk_alert_constant.g_mov_status_interr)
               AND mov.flg_status = s.val
               AND s.code_domain = 'MOVEMENT.FLG_STATUS'
               AND s.domain_owner = pk_sysdomain.k_default_schema
               AND s.id_language = i_lang
             ORDER BY dt_begin, rank;
    
        CURSOR c_short_transp IS
            SELECT id_sys_shortcut
              FROM sys_shortcut
             WHERE intern_name = 'GRID_TRANSPORT'
               AND id_software = i_prof.software
               AND id_institution IN (0, i_prof.institution)
               AND id_parent IS NULL
             ORDER BY id_institution DESC;
        l_rank        sys_domain.rank%TYPE;
        l_dt_req_tstz movement.dt_req_tstz%TYPE;
        l_flg_status  movement.flg_status%TYPE;
        l_dt_begin    movement.dt_begin_tstz%TYPE;
        l_found       BOOLEAN;
    
        l_display_type   VARCHAR2(200);
        l_display_date   VARCHAR2(200);
        l_display_status VARCHAR2(200);
        l_display_icon   VARCHAR2(200);
    
        --l_short_transp sys_shortcut.id_sys_shortcut%TYPE;
        l_status_str grid_task.movement%TYPE;
        --l_status_s     VARCHAR2(200);
        l_status_msg  VARCHAR2(200);
        l_status_icon VARCHAR2(200);
        l_status_flg  VARCHAR2(200);
        l_shortcut    sys_shortcut.id_sys_shortcut%TYPE;
    BEGIN
        OPEN c_movement;
        FETCH c_movement
            INTO l_rank, l_dt_req_tstz, l_flg_status, l_dt_begin;
        l_found := c_movement%FOUND;
        CLOSE c_movement;
        IF l_found
        THEN
            OPEN c_short_transp;
            FETCH c_short_transp
                INTO l_shortcut;
            CLOSE c_short_transp;
        
            IF l_flg_status = pk_alert_constant.g_mov_status_transp
            THEN
                l_display_type   := pk_alert_constant.g_display_type_icon;
                l_display_icon   := pk_sysdomain.get_img(i_lang,
                                                         'MOVEMENT.FLG_STATUS',
                                                         pk_alert_constant.g_mov_status_transp);
                l_display_status := l_flg_status;
            
            ELSE
                l_display_type := pk_alert_constant.g_display_type_date;
                l_display_date := pk_date_utils.to_char_insttimezone(i_prof,
                                                                     l_dt_req_tstz,
                                                                     pk_alert_constant.g_dt_yyyymmddhh24miss_tzr);
                --  pk_date_utils.to_char_insttimezone(i_prof, l_dt_req_tstz, 'YYYYMMDDHH24MISS TZR');
                l_display_status := 'A';
            END IF;
        
            pk_utils.build_status_string(i_display_type    => l_display_type, -- icon only
                                         i_flg_state       => l_display_status,
                                         i_value_text      => NULL,
                                         i_value_date      => l_display_date,
                                         i_value_icon      => l_display_icon,
                                         i_shortcut        => l_shortcut, -- SHORTCUT 
                                         i_back_color      => NULL,
                                         i_icon_color      => NULL,
                                         i_message_style   => NULL,
                                         i_message_color   => NULL,
                                         i_flg_text_domain => NULL,
                                         o_status_str      => l_status_str,
                                         o_status_msg      => l_status_msg,
                                         o_status_icon     => l_status_icon,
                                         o_status_flg      => l_status_flg);
        
            l_status_str := REPLACE(l_status_str, pk_alert_constant.g_status_rpl_chr_icon, l_status_icon);
            l_status_str := REPLACE(l_status_str,
                                    pk_alert_constant.g_status_rpl_chr_dt_server,
                                    pk_date_utils.to_char_insttimezone(i_prof,
                                                                       l_dt_req_tstz,
                                                                       pk_alert_constant.g_dt_yyyymmddhh24miss_tzr)) || '|';
        
        END IF;
        RETURN l_status_str;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_movement_status_str;

    /*******************************************************************************************************************************************
    * Name:                           SET_GRID_TASK_MOVEMENT
    * Description:                    Function that updates movements information in the grid_task table 
    * 
    * @param I_LANG                   Language ID
    * @param I_PROF                   Professional information Vector: (professional ID, institution ID, software ID)
    * @param I_EVENT_TYPE             Type of event (UPDATE, INSERT, etc)
    * @param I_ROWIDS                 List of ROWIDs belonging to the changed records.
    * @param I_LIST_COLUMNS           List of columns that were changed
    * @param I_SOURCE_TABLE_NAME      Name of the table that was changed.
    * @param I_DG_TABLE_NAME          Name of the Data Governance table.
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * @value I_EVENT_TYPE             {*} t_data_gov_mnt.g_event_insert {*} t_data_gov_mnt.g_event_update {*} t_data_gov_mnt.g_event_delete
    * 
    * @return                         Return FALSE if an error occours, otherwise return TRUE
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Elisabete Bugalho
    * @version                        2.6.5
    * @since                          2015/05/27
    *******************************************************************************************************************************************/

    PROCEDURE set_grid_task_movement
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
        l_func_proc_name VARCHAR2(30);
        l_exception EXCEPTION;
    BEGIN
        l_func_proc_name := 'SET_GRID_TASK_MOVEMENT';
        pk_alertlog.log_info(text            => 'BEGIN: ' || i_rowids.count,
                             object_name     => g_package_name,
                             sub_object_name => l_func_proc_name);
    
        -- Validate arguments
        g_error := 'VALIDATE ARGUMENTS';
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => 'MOVEMENT',
                                                 i_expected_dg_table_name => 'GRID_TASK',
                                                 i_list_columns           => i_list_columns,
                                                 i_expected_columns       => NULL)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
        -- Process event
        pk_alertlog.log_debug('MOVEMENT: Getting list of id_episode', g_package_name, l_func_proc_name);
        IF i_event_type != t_data_gov_mnt.g_event_delete
        THEN
            IF i_rowids IS NOT NULL
               AND i_rowids.count > 0
            THEN
                ins_grid_task_movements(i_lang => i_lang, i_prof => i_prof, i_rowids => i_rowids);
            END IF;
        END IF;
    
    EXCEPTION
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
            pk_utils.undo_changes();
        WHEN OTHERS THEN
            -- Unexpected error.
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
            pk_utils.undo_changes();
    END set_grid_task_movement;

    PROCEDURE ins_grid_task_movements
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_rowids IN table_varchar
    ) IS
    
        l_prof       profissional := i_prof;
        l_status_str grid_task.movement%TYPE;
    
        l_exception EXCEPTION;
    
        l_error_out t_error_out;
    
    BEGIN
    
        FOR r_cur IN (SELECT /*+ opt_estimate (table m rows=1) */
                       m.id_episode,
                       nvl(m.id_prof_move, m.id_prof_request) id_professional,
                       e.id_institution,
                       ei.id_software
                        FROM movement m
                        JOIN episode e
                          ON e.id_episode = m.id_episode
                        JOIN epis_info ei
                          ON ei.id_episode = e.id_episode
                       WHERE m.rowid IN (SELECT /*+ opt_estimate (table t rows=1)  */
                                          *
                                           FROM TABLE(i_rowids) t)
                      UNION ALL
                      SELECT m.id_episode,
                             nvl(m.id_prof_move, m.id_prof_request) id_professional,
                             e.id_institution,
                             ei.id_software
                        FROM movement m
                        JOIN episode e
                          ON e.id_episode = m.id_episode
                        JOIN epis_info ei
                          ON ei.id_episode = e.id_episode
                       WHERE i_rowids IS NULL)
        LOOP
            IF i_prof IS NULL
            THEN
                IF r_cur.id_professional IS NULL
                   OR r_cur.id_institution IS NULL
                   OR r_cur.id_software IS NULL
                THEN
                    CONTINUE;
                END IF;
            
                l_prof := profissional(r_cur.id_professional, r_cur.id_institution, r_cur.id_software);
            END IF;
        
            l_status_str := get_movement_status_str(i_lang => i_lang, i_prof => l_prof, i_episode => r_cur.id_episode);
        
            g_error := 'CALL PK_GRID.UPDATE_GRID_TASK';
            --Actualiza estado da tarefa em GRID_TASK para o episódio correspondente
            IF NOT pk_grid.update_grid_task(i_lang       => i_lang,
                                            i_prof       => l_prof,
                                            i_episode    => r_cur.id_episode,
                                            movement_in  => l_status_str,
                                            movement_nin => FALSE,
                                            o_error      => l_error_out)
            THEN
                g_error := 'ERROR UPDATE_GRID_TASK';
                RAISE l_exception;
            END IF;
        END LOOP;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => g_error);
    END ins_grid_task_movements;

BEGIN
    -- Initialization
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_logic_movements;
/
