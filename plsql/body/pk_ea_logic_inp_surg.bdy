/*-- Last Change Revision: $Rev: 1749034 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2016-07-27 10:27:42 +0100 (qua, 27 jul 2016) $*/
CREATE OR REPLACE PACKAGE BODY pk_ea_logic_inp_surg IS

    g_error        VARCHAR2(1000 CHAR);
    g_owner        VARCHAR2(30 CHAR);
    g_package      VARCHAR2(30 CHAR);
    g_sysdate_tstz TIMESTAMP
        WITH LOCAL TIME ZONE;

    -- Function and procedure implementations

    /********************************************************************************************************************************************
    * Name:                           set_task_timeline
    * Description:                    Function that updates inpatient and surgery episode information in the Easy Access table (task_timeline_ea)
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
    * @author                         Jorge Silva
    * @version                        2.6.2
    * @since                          04-Sep-2012
    *******************************************************************************************************************************************/

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
        l_src_table CONSTANT VARCHAR2(30 CHAR) := 'ADM_REQUEST';
        l_ea_row  task_timeline_ea%ROWTYPE;
        l_ea_rows ts_task_timeline_ea.task_timeline_ea_tc;
        l_rows    table_varchar := table_varchar();
        l_error   t_error_out;
    
        CURSOR c_admission IS
            SELECT ar.id_adm_request,
                   ar.id_upd_episode id_episode,
                   epi_o.id_patient,
                   decode(ar.flg_status,
                          pk_admission_request.g_wlt_status_c,
                          pk_admission_request.g_wlt_status_c,
                          pk_surgery_request.get_epis_done_state(i_lang,
                                                                 wl.id_waiting_list,
                                                                 pk_alert_constant.g_epis_type_inpatient),
                          pk_alert_constant.g_yes,
                          pk_alert_constant.g_adm_req_status_done,
                          decode(pk_surgery_request.get_epis_done_state(i_lang,
                                                                        wl.id_waiting_list,
                                                                        pk_alert_constant.g_epis_type_operating),
                                 pk_alert_constant.g_yes,
                                 pk_alert_constant.g_adm_req_status_done,
                                 wl.flg_status)) flg_status,
                   
                   ar.id_dest_prof,
                   ar.id_upd_prof,
                   pk_surgery_request.get_wl_status_date_dtz(i_lang,
                                                             i_prof,
                                                             ar.id_dest_episode,
                                                             wl.id_waiting_list,
                                                             pk_surgery_request.get_wl_status_flg(i_lang,
                                                                                                  i_prof,
                                                                                                  wl.id_waiting_list,
                                                                                                  decode(wl.flg_type,
                                                                                                         pk_alert_constant.g_wl_status_a,
                                                                                                         pk_alert_constant.g_yes,
                                                                                                         pk_alert_constant.g_no), --ssr.adm_needed,
                                                                                                  pos.id_sr_pos_status,
                                                                                                  pk_alert_constant.g_epis_type_inpatient,
                                                                                                  wl.flg_type)) dt_req,
                   ar.id_dest_inst,
                   epi_o.id_visit id_visit,
                   epi_o.flg_status flg_status_epis,
                   ar.dt_upd dt_last_update
              FROM adm_request ar
              JOIN wtl_epis we
                ON we.id_episode = ar.id_dest_episode
              JOIN episode epi_o
                ON epi_o.id_episode = ar.id_upd_episode
              JOIN waiting_list wl
                ON (wl.id_waiting_list = we.id_waiting_list)
              LEFT JOIN schedule_sr ssr
                ON (ssr.id_waiting_list = wl.id_waiting_list)
              LEFT JOIN sr_pos_schedule pos
                ON (pos.id_schedule_sr = ssr.id_schedule_sr)
             WHERE ar.rowid IN (SELECT /*+dynamic_sampling(t 2)*/
                                 t.column_value row_id
                                  FROM TABLE(i_rowids) t);
    
        TYPE t_coll_admission IS TABLE OF c_admission%ROWTYPE;
        l_admission_rows t_coll_admission;
    l_idx PLS_INTEGER;
    BEGIN
        g_sysdate_tstz := current_timestamp;
        l_idx := 0;
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
        
            -- get admission data from rowids
            g_error := 'OPEN c_admission';
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            OPEN c_admission;
            FETCH c_admission BULK COLLECT
                INTO l_admission_rows;
            CLOSE c_admission;
        
            -- copy admission data into rows collection
            IF l_admission_rows IS NOT NULL
               AND l_admission_rows.count > 0
            THEN
                -- set constant fields
                l_ea_row.table_name        := l_src_table;
                l_ea_row.id_tl_task        := pk_prog_notes_constants.g_task_inp_surg;
                l_ea_row.flg_show_method   := pk_alert_constant.g_tl_oriented_episode;
                l_ea_row.dt_dg_last_update := g_sysdate_tstz;
                l_ea_row.flg_sos           := pk_alert_constant.g_no;
                l_ea_row.flg_normal        := pk_alert_constant.g_yes;
                l_ea_row.flg_has_comments  := pk_alert_constant.g_no;
            
                -- set variable fields
                FOR i IN l_admission_rows.first .. l_admission_rows.last
                LOOP
                    l_ea_row.id_task_refid     := l_admission_rows(i).id_adm_request;
                    l_ea_row.id_patient        := l_admission_rows(i).id_patient;
                    l_ea_row.id_episode        := l_admission_rows(i).id_episode;
                    l_ea_row.id_visit          := l_admission_rows(i).id_visit;
                    l_ea_row.id_institution    := l_admission_rows(i).id_dest_inst;
                    l_ea_row.dt_req            := l_admission_rows(i).dt_req;
                    l_ea_row.id_prof_req       := l_admission_rows(i).id_upd_prof;
                    l_ea_row.flg_status_req    := l_admission_rows(i).flg_status;
                    l_ea_row.flg_outdated      := pk_ea_logic_tasktimeline.g_flg_not_outdated;
                    l_ea_row.flg_ongoing       := pk_prog_notes_constants.g_task_ongoing_o;
                    l_ea_row.dt_last_execution := l_admission_rows(i).dt_last_update;
                    l_ea_row.dt_last_update    := l_admission_rows(i).dt_last_update;
                
                    g_error := 'FOR LOOP id_task_refid: ' || l_ea_row.id_task_refid || ' flg_status: ' || l_admission_rows(i)
                              .flg_status;
                    pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                
                    IF l_admission_rows(i)
                     .flg_status_epis = pk_alert_constant.g_epis_status_cancel
                        OR l_admission_rows(i)
                       .flg_status IN (pk_alert_constant.g_adm_req_status_done, pk_admission_request.g_wlt_status_c)
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
    -- Initialization

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);

END pk_ea_logic_inp_surg;
/
