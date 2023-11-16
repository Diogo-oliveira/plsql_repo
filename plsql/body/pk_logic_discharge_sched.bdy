/*-- Last Change Revision: $Rev: 2027324 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:52 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_logic_discharge_sched IS

    FUNCTION is_number(i_value IN VARCHAR2) RETURN NUMBER IS
        l_num NUMBER;
    BEGIN
    
        l_num := i_value;
    
        RETURN l_num;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END is_number;

    /********************************************************************************************
    * GET_SCHED_DISCH_STATUS           Calculate the status of an schedule discharge registry
    *
    * @param    I_PROF                 Object (ID of professional, ID of institution, ID of software)
    * @param    I_DT_REQ               discharge request date
    * @param    I_DT_BEGIN             Request date for shedule discharge
    * @param    I_FLG_STATUS           Discharge date status flag
    * @param    O_STATUS_STR           Status string
    * @param    O_STATUS_MSG           Status message
    * @param    O_STATUS_ICON          Status icon
    * @param    O_STATUS_FLG           Status flag
    *
    * 
    * @return                         Return FALSE if an error occours, otherwise return TRUE
    * @raises                         PL/SQL generic erro "OTHERS"
    *
    * @author                         Luís Maia
    * @version                        2.5.0.3
    * @since                          2009/05/22
    ********************************************************************************************/
    PROCEDURE get_sched_disch_status
    (
        i_prof        IN profissional,
        i_dt_req      IN discharge_schedule.dt_req%TYPE,
        i_dt_begin    IN discharge_schedule.dt_discharge_schedule%TYPE,
        i_flg_status  IN discharge_schedule.flg_status%TYPE,
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
             'DISCHARGE_SCHEDULE.FLG_STATUS' desc_stat,
             
             -- l_display_type
             decode(i_flg_status,
                    pk_alert_constant.g_disch_sched_status_yes,
                    pk_alert_constant.g_display_type_icon, -- ICON
                    NULL) flg_text,
             
             -- l_back_color
             decode(i_flg_status,
                    pk_alert_constant.g_disch_sched_status_yes,
                    pk_alert_constant.g_color_gray, --
                    NULL) color_status,
             
             -- status_flg                      
             decode(i_flg_status,
                    pk_alert_constant.g_disch_sched_status_yes,
                    pk_alert_constant.g_disch_sched_status_yes,
                    pk_alert_constant.g_disch_sched_status_no,
                    pk_alert_constant.g_disch_sched_status_no,
                    NULL) status_flg
              FROM dual;
    
    BEGIN
    
        g_error := 'GET DISCHARGE SCHEDULE STATUS';
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
                                              'GET_SCHED_DISCH_STATUS',
                                              l_error_out);
    END get_sched_disch_status;

    /*******************************************************************************************************************************************
    * Name:                           SET_TASK_TIMELINE_DISCH
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
    * @version                        2.5.0.3
    * @since                          2009/05/22
    *******************************************************************************************************************************************/
    PROCEDURE set_task_timeline_disch
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
        l_func_proc_name   VARCHAR2(30) := 'SET_TASK_TIMELINE_DISCH';
        l_name_table_ea    VARCHAR2(30) := 'TASK_TIMELINE_EA';
        l_process_name     VARCHAR2(30);
        l_event_into_ea    VARCHAR2(1);
        l_update_reg       NUMBER(24);
        l_flg_not_outdated task_timeline_ea.flg_outdated%TYPE := 0;
        o_rowids           table_varchar;
        l_error_out        t_error_out;
        
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
            
                g_error := 'GET SCHEDULE DISCHARGE ROWIDS AND INFORMATION';
                pk_alertlog.log_debug(g_error);
                FOR r_cur IN (SELECT ds.id_episode,
                                     ds.id_discharge_schedule,
                                     ds.dt_req dt_req,
                                     ds.dt_discharge_schedule dt_begin,
                                     NULL dt_end,
                                     ds.flg_status,
                                     ds.id_prof_req id_prof_request,
                                     ds.id_patient,
                                     epi.id_visit,
                                     epi.id_institution,
                                     NULL universal_desc_clob,
                                     'TL_TASK.CODE_TL_TASK.12' code_task,
                                     pk_prog_notes_constants.g_task_ongoing_o flg_ongoing,
                                     pk_alert_constant.g_yes flg_normal,
                                     NULL id_prof_exec
                                FROM discharge_schedule ds
                               INNER JOIN episode epi
                                  ON (epi.id_episode = ds.id_episode)
                               WHERE ds.rowid IN (SELECT vc_1
                                                    FROM tbl_temp))
                
                LOOP
                
                    g_error := 'GET SCHEDULE DISCHARGE STATUS';
                    get_sched_disch_status(i_prof,
                                           r_cur.dt_req,
                                           r_cur.dt_begin,
                                           r_cur.flg_status,
                                           l_new_rec_row.status_str,
                                           l_new_rec_row.status_msg,
                                           l_new_rec_row.status_icon,
                                           l_new_rec_row.status_flg);
                
                    --
                    g_error := 'DEFINE NEW RECORD FOR TASK_TIMELINE_EA';
                    --
                    l_new_rec_row.id_tl_task        := pk_prog_notes_constants.g_task_prev_dischage_dt;
                    l_new_rec_row.table_name        := pk_alert_constant.g_tl_table_name_disch;
                    l_new_rec_row.flg_show_method   := pk_alert_constant.g_tl_oriented_episode;
                    l_new_rec_row.dt_dg_last_update := current_timestamp;
                    --
                    l_new_rec_row.id_task_refid  := r_cur.id_discharge_schedule;
                    l_new_rec_row.dt_req         := r_cur.dt_req;
                    l_new_rec_row.dt_begin       := r_cur.dt_begin;
                    l_new_rec_row.dt_end         := r_cur.dt_end;
                    l_new_rec_row.flg_status_req := r_cur.flg_status;
                    l_new_rec_row.id_prof_req    := is_number(r_cur.id_prof_request);
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
                    l_new_rec_row.dt_last_update      := r_cur.dt_begin;
                
                    --
                    pk_alertlog.log_debug('Processing ' || l_process_name || ' on ' || i_source_table_name || ' (' ||
                                          l_name_table_ea || '): ' || g_error,
                                          g_package_name,
                                          l_func_proc_name);
                
                    --
                    -- Events in TASK_TIMELINE_EA table is dependent of l_new_rec_row.flg_status_req variable
                    IF l_new_rec_row.flg_status_req = pk_alert_constant.g_disch_sched_status_yes -- Active Date ('Y')                  
                    THEN
                        -- Search for updated registrie
                        SELECT COUNT(0)
                          INTO l_update_reg
                          FROM task_timeline_ea tte
                         WHERE tte.id_task_refid = l_new_rec_row.id_task_refid
                           AND tte.table_name = pk_alert_constant.g_tl_table_name_disch
                           AND tte.id_tl_task = pk_prog_notes_constants.g_task_prev_dischage_dt;
                    
                        -- IF exists one registry, information should be UPDATED in TASK_TIMELINE_EA table for this registrie
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
                        --IF l_new_rec_row.flg_status_req = pk_alert_constant.g_disch_sched_status_yes -- Inactive Date ('N')
                        --
                        -- Information in states that are not relevant are DELETED
                        l_process_name  := 'DELETE';
                        l_event_into_ea := 'D';
                    END IF;
                
                    /*
                    * Operations to perform in TASK_TIMELINE_EA Easy Access table:
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
                    -- DELETE:
                    THEN
                        g_error := 'TS_TASK_TIMELINE_EA.DEL_BY';
                        ts_task_timeline_ea.del_by(where_clause_in => 'id_task_refid = ' || l_new_rec_row.id_task_refid ||
                                                                      ' AND id_tl_task = ' || l_new_rec_row.id_tl_task,
                                                   rows_out        => o_rowids);
                    
                    ELSIF l_event_into_ea = t_data_gov_mnt.g_event_update
                    -- UPDATE:
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
                                                flg_sos_in           => pk_alert_constant.g_no,
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
                                              'SET_TASK_TIMELINE_DISCH',
                                              l_error_out);
        
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
        
    END set_task_timeline_disch;

BEGIN
    -- Initialization
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_logic_discharge_sched;
/
