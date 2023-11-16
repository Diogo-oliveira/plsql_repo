/*-- Last Change Revision: $Rev: 2027326 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:52 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_logic_episode IS

    /********************************************************************************************
    * GET_EPISODE_STATUS               Calculate the status of an episode registry
    *
    * @param    I_PROF                 Object (ID of professional, ID of institution, ID of software)
    * @param    I_DT_REQ               discharge request date
    * @param    I_DT_BEGIN             Request date for shedule discharge
    * @param    I_FLG_STATUS           Discharge date status flag
    * @param    I_ID_EPIS_TYPE         ID_EPIS_TYPE of current episode
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
    * @since                          2009/05/25
    ********************************************************************************************/
    PROCEDURE get_episode_status
    (
        i_prof         IN profissional,
        i_dt_req       IN discharge_schedule.create_time%TYPE,
        i_dt_begin     IN discharge_schedule.dt_discharge_schedule%TYPE,
        i_flg_status   IN episode.flg_status%TYPE,
        i_id_epis_type IN episode.id_epis_type%TYPE,
        o_status_str   OUT VARCHAR2,
        o_status_msg   OUT VARCHAR2,
        o_status_icon  OUT VARCHAR2,
        o_status_flg   OUT VARCHAR2
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
             NULL desc_stat,
             
             -- l_display_type
             decode(i_flg_status,
                    pk_alert_constant.g_epis_status_active,
                    pk_alert_constant.g_display_type_icon, -- ICON
                    NULL) flg_text,
             
             -- l_back_color
             decode(i_flg_status,
                    pk_alert_constant.g_epis_status_active,
                    pk_alert_constant.g_color_gray, --
                    NULL) color_status,
             
             -- status_flg                      
             decode(i_flg_status,
                    pk_alert_constant.g_epis_status_active,
                    pk_alert_constant.g_epis_status_active,
                    pk_alert_constant.g_epis_status_inactive,
                    pk_alert_constant.g_epis_status_inactive,
                    pk_alert_constant.g_epis_status_temp,
                    pk_alert_constant.g_epis_status_temp,
                    pk_alert_constant.g_epis_status_pendent,
                    pk_alert_constant.g_epis_status_pendent,
                    pk_alert_constant.g_epis_status_cancel,
                    pk_alert_constant.g_epis_status_cancel,
                    NULL) status_flg
              FROM dual;
    
    BEGIN
    
        g_error := 'GET EPISODE STATUS';
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
                                              'GET_EPISODE_STATUS',
                                              l_error_out);
    END get_episode_status;

    /**
    * GET DATA ROWID's
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_table_name         Name of the Data Governance table.
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param o_rowids             List of ROWIDs belonging to the changed records.
    *
    * @author Luís Maia
    * @version 2.5.0.7.6
    * @since 2009/12/23
    */
    FUNCTION get_data_rowid
    (
        rows_in      IN table_varchar,
        i_table_name IN VARCHAR
    ) RETURN table_varchar IS
        data table_varchar;
    BEGIN
        IF i_table_name = 'EPISODE'
        THEN
            SELECT /*+RULE*/
             epi.rowid BULK COLLECT
              INTO data
              FROM episode epi
             WHERE ROWID IN (SELECT *
                               FROM TABLE(rows_in));
            RETURN data;
        ELSIF i_table_name = 'SCHEDULE_SR'
        THEN
            SELECT /*+RULE*/
             epi.rowid BULK COLLECT
              INTO data
              FROM episode epi
             WHERE epi.id_episode IN (SELECT ss.id_episode
                                        FROM schedule_sr ss
                                       WHERE ss.rowid IN (SELECT *
                                                            FROM TABLE(rows_in)));
            RETURN data;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_name_in => 'get_data_rowid');
    END get_data_rowid;

    /*******************************************************************************************************************************************
    * Name:                           SET_INP_EPISODE
    * Description:                    Function that updates episode information in the Task Timeline Easy Access table (task_timeline_ea)
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
    * @since                          2009/05/25
    *******************************************************************************************************************************************/
    PROCEDURE set_inp_episode
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
        l_func_proc_name   VARCHAR2(30) := 'SET_INP_EPISODE';
        l_name_table_ea    VARCHAR2(30) := 'TASK_TIMELINE_EA';
        l_process_name     VARCHAR2(30);
        l_event_into_ea    VARCHAR2(1);
        l_update_reg       NUMBER(24);
        l_id_epis_type     episode.id_epis_type%TYPE;
        l_insert_into_ea   BOOLEAN := FALSE;
        l_tl_task_episode  tl_task.id_tl_task%TYPE;
        l_tl_table_name    VARCHAR2(4000);
        l_code_task        VARCHAR2(24);
        l_flg_not_outdated task_timeline_ea.flg_outdated%TYPE := 0;
        l_icon_task        tl_task.icon%TYPE;
        o_rowids           table_varchar;
        l_error_out        t_error_out;
    
        l_timestamp TIMESTAMP(6)
            WITH LOCAL TIME ZONE := current_timestamp;
    
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
    
        BEGIN
            SELECT tl.icon
              INTO l_icon_task
              FROM tl_task tl
             WHERE tl.id_tl_task = pk_prog_notes_constants.g_task_schedule_inp;
        EXCEPTION
            WHEN no_data_found THEN
                l_icon_task := pk_alert_constant.g_status_rpl_chr_icon;
        END;
    
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
            
                g_error := 'GET EPISODES ROWIDS AND INFORMATION';
                pk_alertlog.log_debug(g_error);
                FOR r_cur IN (SELECT epis.id_episode,
                                     epis.dt_creation dt_req,
                                     decode(epis.flg_ehr,
                                            pk_alert_constant.g_epis_ehr_normal,
                                            epis.dt_begin_tstz,
                                            nvl(pk_schedule_inp.get_sch_dt_begin(NULL, NULL, epis.id_episode),
                                                epis.dt_begin_tstz)) dt_begin,
                                     NULL dt_end,
                                     epis.flg_status,
                                     nvl(ei.id_prof_schedules, ei.id_professional) id_prof_request,
                                     epis.id_patient,
                                     epis.id_visit,
                                     epis.id_institution,
                                     epis.id_epis_type,
                                     NULL universal_desc_clob,
                                     NULL code_task,
                                     pk_prog_notes_constants.g_task_ongoing_o flg_ongoing,
                                     pk_alert_constant.g_yes flg_normal,
                                     NULL id_prof_exec
                                FROM episode epis
                               INNER JOIN epis_info ei
                                  ON (ei.id_episode = epis.id_episode)
                               WHERE epis.rowid IN (SELECT vc_1
                                                      FROM tbl_temp)
                                 AND epis.id_epis_type = pk_alert_constant.g_epis_type_inpatient
                                 AND epis.id_prev_episode IS NOT NULL -- Main episodes should not be visible in Task Timeline
                              )
                LOOP
                    -- Save epis_type information
                    l_id_epis_type := r_cur.id_epis_type;
                
                    IF l_id_epis_type = pk_alert_constant.g_epis_type_inpatient
                    THEN
                        l_insert_into_ea := TRUE;
                        --
                        l_code_task       := 'TL_TASK.CODE_TL_TASK.11';
                        l_tl_task_episode := pk_prog_notes_constants.g_task_schedule_inp;
                        l_tl_table_name   := pk_alert_constant.g_tl_table_name_sche_inp;
                        --
                    ELSE
                        l_insert_into_ea := FALSE;
                    END IF;
                
                    --
                    g_error := 'GET IF EPISODES INFORMATION SHOULD BE INSERTED INTO TASK TIMELINE EASY ACCESS';
                    IF l_insert_into_ea = TRUE
                    THEN
                        --
                        g_error := 'GET EPISODES STATUS';
                        get_episode_status(i_prof,
                                           r_cur.dt_req,
                                           r_cur.dt_begin,
                                           r_cur.flg_status,
                                           l_id_epis_type,
                                           l_new_rec_row.status_str,
                                           l_new_rec_row.status_msg,
                                           l_new_rec_row.status_icon,
                                           l_new_rec_row.status_flg);
                    
                        --
                        g_error := 'DEFINE NEW RECORD FOR TASK_TIMELINE_EA';
                        --
                        l_new_rec_row.id_tl_task        := l_tl_task_episode;
                        l_new_rec_row.table_name        := l_tl_table_name;
                        l_new_rec_row.flg_show_method   := pk_alert_constant.g_tl_oriented_patient;
                        l_new_rec_row.dt_dg_last_update := current_timestamp;
                        --
                        l_new_rec_row.id_task_refid  := r_cur.id_episode;
                        l_new_rec_row.dt_req         := r_cur.dt_req;
                        l_new_rec_row.dt_begin       := r_cur.dt_begin;
                        l_new_rec_row.dt_end         := r_cur.dt_end;
                        l_new_rec_row.flg_status_req := r_cur.flg_status;
                    
                        l_new_rec_row.id_prof_req := r_cur.id_prof_request;
                        pk_alertlog.log_debug('r_cur.id_prof_request ' || r_cur.id_prof_request);
                        --
                        l_new_rec_row.id_patient          := r_cur.id_patient;
                        l_new_rec_row.id_episode          := r_cur.id_episode;
                        l_new_rec_row.id_visit            := r_cur.id_visit;
                        l_new_rec_row.id_institution      := r_cur.id_institution;
                        l_new_rec_row.universal_desc_clob := r_cur.universal_desc_clob;
                        l_new_rec_row.code_description    := l_code_task;
                        l_new_rec_row.flg_outdated        := l_flg_not_outdated;
                        l_new_rec_row.flg_sos             := pk_alert_constant.g_no;
                        l_new_rec_row.status_str := CASE
                                                        WHEN l_tl_task_episode = pk_prog_notes_constants.g_task_schedule_inp THEN
                                                         regexp_replace(l_new_rec_row.status_str,
                                                                        pk_alert_constant.g_status_rpl_chr_icon,
                                                                        l_icon_task)
                                                    END;
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
                        IF l_new_rec_row.flg_status_req = pk_alert_constant.g_epis_status_active -- Active ('A')
                        THEN
                            -- Search for updated registrie
                            SELECT COUNT(0)
                              INTO l_update_reg
                              FROM task_timeline_ea tte
                             WHERE tte.id_task_refid = l_new_rec_row.id_task_refid
                               AND tte.table_name = l_tl_table_name
                               AND tte.id_tl_task = l_tl_task_episode;
                        
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
                            --IF l_new_rec_row.flg_status_req = pk_alert_constant.g_epis_status_inactive -- Inactive  ('I')
                            --IF l_new_rec_row.flg_status_req = pk_alert_constant.g_epis_status_temp     -- Temporary ('T')
                            --IF l_new_rec_row.flg_status_req = pk_alert_constant.g_epis_status_pendent  -- Pendent   ('P')
                            --IF l_new_rec_row.flg_status_req = pk_alert_constant.g_epis_status_cancel   -- Cancelled ('C')
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
                            ts_task_timeline_ea.del_by(where_clause_in => 'id_task_refid = ' ||
                                                                          l_new_rec_row.id_task_refid ||
                                                                          ' AND id_tl_task = ' ||
                                                                          l_new_rec_row.id_tl_task,
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
                                                    flg_sos_nin             => FALSE,
                                                    flg_sos_in              => l_new_rec_row.flg_sos,
                                                    --
                                                    flg_outdated_nin     => TRUE,
                                                    flg_outdated_in      => l_new_rec_row.flg_outdated,
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
                        --
                    END IF;
                    --
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
                                              'SET_INP_EPISODE',
                                              l_error_out);
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END set_inp_episode;

    /*******************************************************************************************************************************************
    * Name:                           SET_SURG_EPISODE
    * Description:                    Function that updates episode information in the Task Timeline Easy Access table (task_timeline_ea)
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
    * @since                          2009/05/25
    *******************************************************************************************************************************************/
    PROCEDURE set_surg_episode
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
    
        l_new_rec_row     task_timeline_ea%ROWTYPE;
        l_func_proc_name  VARCHAR2(30) := 'SET_SURG_EPISODE';
        l_name_table_ea   VARCHAR2(30) := 'TASK_TIMELINE_EA';
        l_process_name    VARCHAR2(30);
        l_event_into_ea   VARCHAR2(1);
        l_update_reg      NUMBER(24);
        l_id_epis_type    episode.id_epis_type%TYPE;
        l_insert_into_ea  BOOLEAN := FALSE;
        l_tl_task_episode tl_task.id_tl_task%TYPE;
        l_tl_table_name   VARCHAR2(4000);
        l_code_task       VARCHAR2(24);
        l_icon_task       tl_task.icon%TYPE;
        o_rowids          table_varchar;
        l_error_out       t_error_out;
        l_flg_not_outdated task_timeline_ea.flg_outdated%TYPE := 0;
    
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
    
        BEGIN
            SELECT tl.icon
              INTO l_icon_task
              FROM tl_task tl
             WHERE tl.id_tl_task = pk_prog_notes_constants.g_task_surgery;
        EXCEPTION
            WHEN no_data_found THEN
                l_icon_task := pk_alert_constant.g_status_rpl_chr_icon;
        END;
    
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
            
                g_error := 'GET EPISODES ROWIDS AND INFORMATION';
                pk_alertlog.log_debug(g_error);
                FOR r_cur IN (SELECT epi.id_episode,
                                     epi.dt_creation dt_req,
                                     ss.dt_target_tstz dt_begin,
                                     NULL dt_end,
                                     epi.flg_status,
                                     nvl(ei.id_prof_schedules, ei.id_professional) id_prof_request,
                                     epi.id_patient,
                                     epi.id_visit,
                                     epi.id_institution,
                                     epi.id_epis_type,
                                     NULL universal_desc_clob,
                                     NULL code_task,
                                     CASE
                                          WHEN epi.flg_status = pk_alert_constant.g_active
                                               AND epi.flg_ehr = pk_alert_constant.g_epis_ehr_normal THEN
                                           pk_prog_notes_constants.g_task_ongoing_o
                                          WHEN epi.flg_status = pk_alert_constant.g_inactive THEN
                                           pk_prog_notes_constants.g_task_finalized_f
                                          WHEN epi.flg_status = pk_alert_constant.g_active
                                               AND epi.flg_ehr <> pk_alert_constant.g_epis_ehr_normal THEN
                                           pk_prog_notes_constants.g_task_pending_d
                                          ELSE
                                           pk_prog_notes_constants.g_task_ongoing_o
                                      END flg_ongoing,
                                     pk_alert_constant.g_yes flg_normal,
                                     NULL id_prof_exec
                                FROM episode epi
                               INNER JOIN epis_info ei
                                  ON (ei.id_episode = epi.id_episode)
                               INNER JOIN schedule_sr ss
                                  ON (ss.id_episode = epi.id_episode)
                               WHERE epi.rowid IN (SELECT vc_1
                                                     FROM tbl_temp)
                                    --
                                 AND ss.flg_status = pk_alert_constant.g_active                                
                                 AND epi.id_epis_type = pk_alert_constant.g_epis_type_operating) -- Surgery episodes
                LOOP
                    -- Save epis_type information
                    l_id_epis_type := r_cur.id_epis_type;
                
                    IF l_id_epis_type = pk_alert_constant.g_epis_type_operating
                    THEN
                        l_insert_into_ea := TRUE;
                        --
                        l_code_task       := 'TL_TASK.CODE_TL_TASK.10';
                        l_tl_task_episode := pk_prog_notes_constants.g_task_surgery;
                        l_tl_table_name   := pk_alert_constant.g_tl_table_name_surg;
                        --
                    ELSE
                        l_insert_into_ea := FALSE;
                    END IF;
                
                    --
                    g_error := 'GET IF EPISODES INFORMATION SHOULD BE INSERTED INTO TASK TIMELINE EASY ACCESS';
                    IF l_insert_into_ea = TRUE
                    THEN
                        --
                        g_error := 'GET EPISODES STATUS';
                        get_episode_status(i_prof,
                                           r_cur.dt_req,
                                           r_cur.dt_begin,
                                           r_cur.flg_status,
                                           l_id_epis_type,
                                           l_new_rec_row.status_str,
                                           l_new_rec_row.status_msg,
                                           l_new_rec_row.status_icon,
                                           l_new_rec_row.status_flg);
                    
                        --
                        g_error := 'DEFINE NEW RECORD FOR TASK_TIMELINE_EA';
                        --
                        l_new_rec_row.id_tl_task        := l_tl_task_episode;
                        l_new_rec_row.table_name        := l_tl_table_name;
                        l_new_rec_row.flg_show_method   := pk_alert_constant.g_tl_oriented_patient;
                        l_new_rec_row.dt_dg_last_update := current_timestamp;
                        --
                        l_new_rec_row.id_task_refid  := r_cur.id_episode;
                        l_new_rec_row.dt_req         := r_cur.dt_req;
                        l_new_rec_row.dt_begin       := r_cur.dt_begin;
                        l_new_rec_row.dt_end         := r_cur.dt_end;
                        l_new_rec_row.flg_status_req := r_cur.flg_status;
                        l_new_rec_row.flg_outdated        := l_flg_not_outdated;
                    
                        l_new_rec_row.id_prof_req := r_cur.id_prof_request;
                        pk_alertlog.log_debug('r_cur.id_prof_request ' || r_cur.id_prof_request);
                        --
                        l_new_rec_row.id_patient          := r_cur.id_patient;
                        l_new_rec_row.id_episode          := r_cur.id_episode;
                        l_new_rec_row.id_visit            := r_cur.id_visit;
                        l_new_rec_row.id_institution      := r_cur.id_institution;
                        l_new_rec_row.universal_desc_clob := r_cur.universal_desc_clob;
                        l_new_rec_row.code_description    := l_code_task;
                        l_new_rec_row.flg_sos             := pk_alert_constant.g_no;
                        l_new_rec_row.status_str := CASE
                                                        WHEN l_tl_task_episode = pk_prog_notes_constants.g_task_surgery THEN
                                                         regexp_replace(l_new_rec_row.status_str,
                                                                        pk_alert_constant.g_status_rpl_chr_icon,
                                                                        l_icon_task)
                                                    END;
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
                        IF l_new_rec_row.flg_status_req in (pk_alert_constant.g_epis_status_active,pk_alert_constant.g_epis_status_inactive) -- Active ('A') Inactive  ('I')
                           AND r_cur.dt_begin IS NOT NULL
                        THEN
                            -- Search for updated registrie
                            SELECT COUNT(0)
                              INTO l_update_reg
                              FROM task_timeline_ea tte
                             WHERE tte.id_task_refid = l_new_rec_row.id_task_refid
                               AND tte.table_name = l_tl_table_name
                               AND tte.id_tl_task = l_tl_task_episode;
                        
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
                            --IF l_new_rec_row.flg_status_req = pk_alert_constant.g_epis_status_inactive -- Inactive  ('I')
                            --IF l_new_rec_row.flg_status_req = pk_alert_constant.g_epis_status_temp     -- Temporary ('T')
                            --IF l_new_rec_row.flg_status_req = pk_alert_constant.g_epis_status_pendent  -- Pendent   ('P')
                            --IF l_new_rec_row.flg_status_req = pk_alert_constant.g_epis_status_cancel   -- Cancelled ('C')
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
                            ts_task_timeline_ea.del_by(where_clause_in => 'id_task_refid = ' ||
                                                                          l_new_rec_row.id_task_refid ||
                                                                          ' AND id_tl_task = ' ||
                                                                          l_new_rec_row.id_tl_task,
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
                                                    flg_sos_nin             => FALSE,
                                                    flg_sos_in              => l_new_rec_row.flg_sos,
                                                    flg_ongoing_nin         => TRUE,
                                                    flg_ongoing_in          => l_new_rec_row.flg_ongoing,
                                                    flg_normal_nin          => TRUE,
                                                    flg_normal_in           => l_new_rec_row.flg_normal,
                                                    id_prof_exec_nin        => TRUE,
                                                    id_prof_exec_in         => l_new_rec_row.id_prof_exec,
                                                    flg_has_comments_nin    => TRUE,
                                                    flg_has_comments_in     => l_new_rec_row.flg_has_comments,
                                                    dt_last_update_in       => l_new_rec_row.dt_last_update,
                                                    rows_out                => o_rowids);
                        
                        ELSE
                            -- EXCEPTION: Unexpected event type
                            RAISE g_excp_invalid_event_type;
                        END IF;
                        --
                    END IF;
                    --
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
                                              'SET_SURGE_EPISODE',
                                              l_error_out);
        
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END set_surg_episode;

    /*******************************************************************************************************************************************
    * Name:                           SET_TASK_TIMELINE_EPISOD
    * Description:                    Function that updates episode information in the Task Timeline Easy Access table (task_timeline_ea)
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
    * @since                          2009/05/25
    *******************************************************************************************************************************************/
    PROCEDURE set_task_timeline_episod
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
        l_id_epis_type table_number;
        l_epis_rowid   table_varchar;
        l_rowids       table_varchar;
        l_error_out    t_error_out;
    BEGIN
    
        IF ((i_rowids IS NOT NULL) AND (i_rowids.count > 0))
        THEN
            g_error  := 'GET NURSE_ACTV_REQ_DET ROWIDS';
            l_rowids := get_data_rowid(rows_in => i_rowids, i_table_name => i_source_table_name);
        
            -- Insert i_rowids into table tbl_temp to increase performance
            DELETE FROM tbl_temp;
            insert_tbl_temp(i_vc_1 => l_rowids);
        END IF;
    
        --
        BEGIN
            SELECT epi.id_epis_type, epi.rowid BULK COLLECT
              INTO l_id_epis_type, l_epis_rowid
              FROM episode epi
             WHERE epi.id_epis_type IN
                   (pk_alert_constant.g_epis_type_operating, pk_alert_constant.g_epis_type_inpatient)
               AND epi.rowid IN (SELECT vc_1
                                   FROM tbl_temp);
        EXCEPTION
            WHEN no_data_found THEN
                l_id_epis_type := NULL;
                l_epis_rowid   := NULL;
        END;
    
        IF ((l_id_epis_type IS NOT NULL) AND (l_id_epis_type.count > 0))
        THEN
            FOR i IN 1 .. l_id_epis_type.count
            LOOP
                -- Call correspondent function
                IF l_id_epis_type(i) = pk_alert_constant.g_epis_type_inpatient
                THEN
                    --
                    set_inp_episode(i_lang              => i_lang,
                                    i_prof              => i_prof,
                                    i_event_type        => i_event_type,
                                    i_rowids            => table_varchar(l_epis_rowid(i)),
                                    i_source_table_name => i_source_table_name,
                                    i_list_columns      => i_list_columns,
                                    i_dg_table_name     => i_dg_table_name);
                    --
                ELSIF l_id_epis_type(i) = pk_alert_constant.g_epis_type_operating
                THEN
                    --
                    set_surg_episode(i_lang              => i_lang,
                                     i_prof              => i_prof,
                                     i_event_type        => i_event_type,
                                     i_rowids            => table_varchar(l_epis_rowid(i)),
                                     i_source_table_name => i_source_table_name,
                                     i_list_columns      => i_list_columns,
                                     i_dg_table_name     => i_dg_table_name);
                ELSE
                    NULL;
                END IF;
            END LOOP;
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
                                              'SET_TASK_TIMELINE_EPISOD',
                                              l_error_out);
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
        
    END set_task_timeline_episod;

    /*******************************************************************************************************************************************
    * Name:                           SET_EPIS_DEP_CLIN_SERV
    * Description:                    Function that updates episode responsable department, dept and clinical service in EPISODE table
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
    * @version                        2.5.0.6
    * @since                          2009/12/17
    *******************************************************************************************************************************************/
    PROCEDURE set_epis_dep_clin_serv
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
        l_episode_row    episode%ROWTYPE;
        l_func_proc_name VARCHAR2(30) := 'SET_EPIS_DEP_CLIN_SERV';
        l_name_table_ea  VARCHAR2(30) := i_dg_table_name;
        l_process_name   VARCHAR2(30);
        l_event_into_ea  VARCHAR2(1);
        l_epis_rowid     table_varchar;
        l_error_out      t_error_out;
    BEGIN
        -- Validate arguments
        g_error := 'VALIDATE ARGUMENTS';
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => i_source_table_name,
                                                 i_expected_dg_table_name => i_dg_table_name,
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
                l_process_name  := 'UPDATE';
                l_event_into_ea := 'U';
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
            IF ((i_rowids IS NOT NULL) AND (i_rowids.count > 0))
            THEN
                --
                DELETE FROM tbl_temp;
                insert_tbl_temp(i_vc_1 => i_rowids);
            
                FOR r_cur IN (SELECT ei.id_episode,
                                     ei.id_dep_clin_serv,
                                     dcs.id_department,
                                     dcs.id_clinical_service,
                                     dep.id_dept
                                FROM epis_info ei
                               INNER JOIN dep_clin_serv dcs
                                  ON (dcs.id_dep_clin_serv = ei.id_dep_clin_serv)
                               INNER JOIN department dep
                                  ON (dep.id_department = dcs.id_department)
                               WHERE ei.rowid IN (SELECT vc_1
                                                    FROM tbl_temp))
                LOOP
                
                    g_error := 'DEFINE NEW INFORMATION FOR EPISODE';
                    --
                    l_episode_row.id_episode := r_cur.id_episode;
                    --
                    l_episode_row.id_dept             := r_cur.id_dept;
                    l_episode_row.id_department       := r_cur.id_department;
                    l_episode_row.id_clinical_service := r_cur.id_clinical_service;
                
                    --
                    pk_alertlog.log_debug('Processing ' || l_process_name || ' on ' || i_source_table_name || ' (' ||
                                          l_name_table_ea || '): ' || g_error,
                                          g_package_name,
                                          l_func_proc_name);
                
                    /*
                    * Operações a executar sobre a tabela de Easy Access EPISODE: 
                    *  -> INSERT;
                    *  -> DELETE;
                    *  -> UPDATE.
                    */
                    IF l_event_into_ea = t_data_gov_mnt.g_event_insert
                    -- INSERT
                    THEN
                        g_error := 'TS_EPISODE.INS IS NOT DEFINED';
                    
                    ELSIF l_event_into_ea = t_data_gov_mnt.g_event_delete
                    -- DELETE: 
                    THEN
                        g_error := 'TS_EPISODE.DEL_BY IS NOT DEFINED';
                    
                    ELSIF l_event_into_ea = t_data_gov_mnt.g_event_update
                    -- UPDATE
                    THEN
                        g_error := 'TS_EPISODE.UPD';
                        ts_episode.upd(id_episode_in          => l_episode_row.id_episode,
                                       id_dept_in             => l_episode_row.id_dept,
                                       id_department_in       => l_episode_row.id_department,
                                       id_clinical_service_in => l_episode_row.id_clinical_service,
                                       rows_out               => l_epis_rowid);
                        --
                        t_data_gov_mnt.process_update(i_lang,
                                                      i_prof,
                                                      'EPISODE',
                                                      l_epis_rowid,
                                                      l_error_out,
                                                      table_varchar('ID_DEPARTMENT', 'ID_CLINICAL_SERVICE', 'ID_DEPT'));
                    ELSE
                        -- EXCEPTION: Unexpected event type
                        RAISE g_excp_invalid_event_type;
                    END IF;
                
                END LOOP;
            
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
                                              'SET_EPIS_DEP_CLIN_SERV',
                                              l_error_out);
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
        
    END set_epis_dep_clin_serv;
    /*******************************************************************************************************************************************
    * Name:                           SET_GRID_TASK_EPISOD
    * Description:                    Function that updates ORIS episode information in the grid_task for hemo and material requisitions.
    *                                 When the schedule date's (schedule_sr) changed and exists hemo and/or material requisitions for this episode
    *                                 is necessary update these columns 
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
    * @author                         Filipe Silva
    * @version                        2.5.0.7.7
    * @since                          2010/02/26
    *******************************************************************************************************************************************/
    PROCEDURE set_grid_task_episode
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
    
        l_episode_row    episode%ROWTYPE;
        l_func_proc_name VARCHAR2(30) := 'SET_GRID_TASK_EPISODE';
        l_name_table_ea  VARCHAR2(30) := i_dg_table_name;
        l_process_name   VARCHAR2(30);
        l_event_into_ea  VARCHAR2(1);
        l_error_out      t_error_out;
        excep EXCEPTION;
        l_limit NUMBER := 10000;
        TYPE sr_reserv_req_aat IS TABLE OF sr_reserv_req%ROWTYPE INDEX BY PLS_INTEGER;
        l_sr_reserv_req sr_reserv_req_aat;
    
        CURSOR c_get_recs IS
            SELECT rev.*
              FROM schedule_sr sr, sr_reserv_req rev
             WHERE rev.id_episode_context = sr.id_episode
               AND sr.rowid IN (SELECT vc_1
                                  FROM tbl_temp);
    
    BEGIN
        g_error := 'VALIDATE ARGUMENTS';
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => i_source_table_name,
                                                 i_expected_dg_table_name => i_dg_table_name,
                                                 i_list_columns           => i_list_columns,
                                                 i_expected_columns       => NULL)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        -- Process update event
        IF i_event_type IN (t_data_gov_mnt.g_event_update)
        THEN
            l_process_name  := 'UPDATE';
            l_event_into_ea := 'U';
        
            pk_alertlog.log_debug('Processing ' || l_process_name || ' on ' || i_source_table_name || ' (' ||
                                  l_name_table_ea || ')',
                                  g_package_name,
                                  l_func_proc_name);
        
            -- Loop through changed records
            g_error := 'LOOP PROCESS';
            IF ((i_rowids IS NOT NULL) AND (i_rowids.count > 0))
            THEN
                --
                DELETE FROM tbl_temp;
                insert_tbl_temp(i_vc_1 => i_rowids);
            
            END IF;
        
            OPEN c_get_recs;
            LOOP
                FETCH c_get_recs BULK COLLECT
                    INTO l_sr_reserv_req LIMIT l_limit;
                EXIT WHEN l_sr_reserv_req.count = 0;
                FOR idx IN 1 .. l_sr_reserv_req.count
                LOOP
                
                    IF NOT pk_sr_planning.update_reserve_grid_task(i_lang       => i_lang,
                                                                   i_reserv_req => l_sr_reserv_req(idx),
                                                                   i_prof       => i_prof,
                                                                   o_error      => l_error_out)
                    THEN
                        RAISE excep;
                    END IF;
                
                END LOOP;
            END LOOP;
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
                                              l_func_proc_name,
                                              l_error_out);
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
        
    END set_grid_task_episode;
    
BEGIN
    -- Initialization
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_logic_episode;
/
