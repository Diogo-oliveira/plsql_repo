/*-- Last Change Revision: $Rev: 2027024 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:45 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_ea_logic_consult_req IS

    -- Private type declarations
    -- Private constant declarations    
    -- Private variable declarations

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Function and procedure implementations

    /*******************************************************************************************************************************************
    * Name:                           set_tl_CONSULT_REQ
    * Description:                    Function that updates patient Future Events information in the Easy Access table (task_timeline_ea)
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
    * @author                         Sofia Mendes
    * @version                        2.6.1.2
    * @since                          26-Mar-2012
    *******************************************************************************************************************************************/
    PROCEDURE set_tl_consult_req
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
    
        l_new_rec_row    task_timeline_ea%ROWTYPE;
        l_func_proc_name VARCHAR2(30) := 'SET_TL_CONSULT_REQ';
        l_name_table_ea  VARCHAR2(30) := 'TASK_TIMELINE_EA';
        l_process_name   VARCHAR2(30);
        l_event_into_ea  VARCHAR2(1);
        l_update_reg     NUMBER(24);
        o_rowids         table_varchar;
        l_error_out      t_error_out;
    
    BEGIN
        -- Validate arguments
        g_error := 'VALIDATE ARGUMENTS';
        pk_alertlog.log_debug(g_error);
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
                l_event_into_ea := 'U';
            ELSIF i_event_type = t_data_gov_mnt.g_event_delete
            THEN
                l_process_name  := 'DELETE';
                l_event_into_ea := 'D';
            END IF;
        
            pk_alertlog.log_debug('Processing ' || l_process_name || ' on ' || i_source_table_name || ' (' ||
                                  l_name_table_ea || ')',
                                  g_package,
                                  l_func_proc_name);
        
            -- Loop through changed records
            g_error := 'LOOP PROCESS';
            pk_alertlog.log_debug(g_error);
            IF ((i_rowids IS NOT NULL) AND (i_rowids.count > 0))
            THEN
                DELETE FROM tbl_temp;
                insert_tbl_temp(i_vc_1 => i_rowids);
            
                g_error := 'GET ROWIDS AND INFORMATION';
                pk_alertlog.log_debug(g_error);
                FOR r_cur IN (SELECT id_consult_req,
                                     id_patient,
                                     id_episode,
                                     flg_status,
                                     id_prof_request,
                                     dt_req,
                                     id_institution,
                                     code_description,
                                     id_prof_exec,
                                     dt_prev_plan_tstz,
                                     id_visit,
                                     flg_outdated,
                                     flg_ongoing,
                                     status_str,
                                     status_msg,
                                     status_flg,
                                     status_icon,
                                     id_tl_task,
                                     flg_status_epis,
                                     flg_priority
                                FROM (SELECT cr.id_consult_req id_consult_req,
                                             cr.id_patient id_patient,
                                             cr.id_episode id_episode,
                                             cr.flg_status flg_status,
                                             cr.id_prof_req id_prof_request,
                                             nvl(cr.dt_last_update, cr.dt_consult_req_tstz) dt_req,
                                             cr.id_instit_requests id_institution,
                                             CASE
                                                  WHEN fet.action = 'APPOINTMENT_NURSING' THEN
                                                   'TL_TASK.CODE_TL_TASK.82'
                                                  WHEN fet.action = 'APPOINTMENT_NUTRITION' THEN
                                                   'TL_TASK.CODE_TL_TASK.83'
                                                  WHEN fet.action = 'APPOINTMENT_REHABILITATION' THEN
                                                   'TL_TASK.CODE_TL_TASK.84'
                                                  WHEN fet.action = 'APPOINTMENT_SOCIAL_WORKER' THEN
                                                   'TL_TASK.CODE_TL_TASK.85'
                                                  WHEN fet.action = 'APPOINTMENT_PSYCHOLOGY' THEN
                                                   'TL_TASK.CODE_TL_TASK.200'
                                                  WHEN fet.action = 'APPOINTMENT_ST' THEN
                                                   'TL_TASK.CODE_TL_TASK.213'
                                                  WHEN fet.action = 'APPOINTMENT_OT' THEN
                                                   'TL_TASK.CODE_TL_TASK.214'
                                                  ELSE
                                                   'TL_TASK.CODE_TL_TASK.81'
                                              END code_description,
                                             cr.id_prof_last_update id_prof_exec,
                                             cr.dt_begin_event dt_prev_plan_tstz,
                                             e.id_visit id_visit,
                                             CASE
                                                  WHEN cr.flg_status IN (pk_consult_req.g_consult_req_stat_proc) THEN
                                                   pk_ea_logic_tasktimeline.g_flg_outdated
                                                  ELSE
                                                   pk_ea_logic_tasktimeline.g_flg_not_outdated
                                              END flg_outdated,
                                             CASE
                                                  WHEN cr.flg_status IN (pk_consult_req.g_consult_req_stat_proc) THEN
                                                   pk_prog_notes_constants.g_task_finalized_f
                                                  ELSE
                                                   pk_prog_notes_constants.g_task_ongoing_o
                                              END flg_ongoing,
                                             status_str,
                                             status_msg,
                                             CASE
                                                  WHEN cr.flg_status = pk_consult_req.g_consult_req_stat_req
                                                       AND
                                                       i_prof.id NOT IN
                                                       (SELECT column_value
                                                          FROM TABLE(pk_events.get_fe_approval_prof_ids(cr.id_consult_req))) THEN
                                                   pk_utils.get_status_string_immediate(i_lang,
                                                                                        i_prof,
                                                                                        pk_alert_constant.g_display_type_icon,
                                                                                        'W',
                                                                                        NULL,
                                                                                        NULL,
                                                                                        'CONSULT_REQ.FLG_STATUS',
                                                                                        NULL,
                                                                                        NULL,
                                                                                        NULL,
                                                                                        NULL,
                                                                                        NULL,
                                                                                        NULL,
                                                                                        NULL)
                                                  WHEN cr.flg_status = pk_consult_req.g_consult_req_stat_reply THEN
                                                   pk_utils.get_status_string_immediate(i_lang,
                                                                                        i_prof,
                                                                                        pk_alert_constant.g_display_type_icon,
                                                                                        decode(nvl(cr.flg_recurrence,
                                                                                                   pk_events.g_flg_not_repeat),
                                                                                               pk_events.g_flg_not_repeat,
                                                                                               'PC',
                                                                                               'PCR'),
                                                                                        NULL,
                                                                                        NULL,
                                                                                        'CONSULT_REQ.FLG_STATUS',
                                                                                        NULL,
                                                                                        NULL,
                                                                                        NULL,
                                                                                        NULL,
                                                                                        NULL,
                                                                                        NULL,
                                                                                        NULL)
                                                  WHEN cr.flg_status = pk_consult_req.g_consult_req_hold_list THEN
                                                   pk_utils.get_status_string_immediate(i_lang,
                                                                                        i_prof,
                                                                                        pk_alert_constant.g_display_type_icon,
                                                                                        pk_consult_req.g_consult_req_hold_list,
                                                                                        NULL,
                                                                                        NULL,
                                                                                        'CONSULT_REQ.FLG_STATUS',
                                                                                        NULL,
                                                                                        NULL,
                                                                                        NULL,
                                                                                        NULL,
                                                                                        NULL,
                                                                                        NULL,
                                                                                        NULL)
                                                  ELSE
                                                   pk_utils.get_status_string(i_lang,
                                                                              i_prof,
                                                                              cr.status_str,
                                                                              cr.status_msg,
                                                                              cr.status_icon,
                                                                              cr.status_flg)
                                              END status_icon,
                                             status_flg,
                                             CASE
                                                  WHEN fet.action = 'APPOINTMENT_NURSING' THEN
                                                   pk_prog_notes_constants.g_task_nursing_appointment
                                                  WHEN fet.action = 'APPOINTMENT_NUTRITION' THEN
                                                   pk_prog_notes_constants.g_task_nutrition_appointment
                                                  WHEN fet.action = 'APPOINTMENT_REHABILITATION' THEN
                                                   pk_prog_notes_constants.g_task_rehabilitation
                                                  WHEN fet.action = 'APPOINTMENT_SOCIAL_WORKER' THEN
                                                   pk_prog_notes_constants.g_task_social_service
                                                  WHEN fet.action = 'APPOINTMENT_PSYCHOLOGY' THEN
                                                   pk_prog_notes_constants.g_task_psychology
                                                  WHEN fet.action = 'APPOINTMENT_ST' THEN
                                                   pk_prog_notes_constants.g_task_speech_therapy
                                                  WHEN fet.action = 'APPOINTMENT_OT' THEN
                                                   pk_prog_notes_constants.g_task_occupational_therapy
                                                  ELSE
                                                   pk_prog_notes_constants.g_task_medical_appointment
                                              END id_tl_task,
                                             e.flg_status flg_status_epis,
                                             cr.flg_priority flg_priority
                                        FROM consult_req cr
                                        JOIN future_event_type fet
                                          ON fet.id_epis_type =
                                             nvl(cr.id_epis_type, pk_events.get_epis_type_consult_req(cr.id_consult_req))
                                         AND fet.action IN ('APPOINTMENT_MEDICAL',
                                                            'APPOINTMENT_NURSING',
                                                            'APPOINTMENT_NUTRITION',
                                                            'APPOINTMENT_REHABILITATION',
                                                            'APPOINTMENT_SOCIAL_WORKER',
                                                            'APPOINTMENT_PSYCHOLOGY',
                                                            'APPOINTMENT_ST',
                                                            'APPOINTMENT_OT')
                                        LEFT JOIN episode e
                                          ON cr.id_episode = e.id_episode
                                       WHERE cr.rowid IN (SELECT vc_1
                                                            FROM tbl_temp)))
                
                LOOP
                
                    g_error := 'DEFINE NEW RECORD FOR TASK_TIMELINE_EA';
                    g_error := 'CALL set_tl_CONSULT_REQ - id_consult_req: ' || r_cur.id_consult_req || ' id_patient: ' ||
                               r_cur.id_patient;
                    pk_alertlog.log_debug(g_error);
                    --
                    l_new_rec_row.id_tl_task        := r_cur.id_tl_task;
                    l_new_rec_row.table_name        := pk_alert_constant.g_tl_table_name_consult;
                    l_new_rec_row.flg_show_method   := pk_alert_constant.g_tl_oriented_episode;
                    l_new_rec_row.dt_dg_last_update := current_timestamp;
                    l_new_rec_row.id_task_refid     := r_cur.id_consult_req;
                    l_new_rec_row.dt_begin          := r_cur.dt_prev_plan_tstz;
                    l_new_rec_row.flg_status_req    := r_cur.flg_status;
                    l_new_rec_row.id_prof_req       := r_cur.id_prof_request;
                    l_new_rec_row.dt_req            := r_cur.dt_req;
                    l_new_rec_row.id_patient        := r_cur.id_patient;
                    l_new_rec_row.id_episode        := r_cur.id_episode;
                    l_new_rec_row.id_visit          := r_cur.id_visit;
                    l_new_rec_row.id_institution    := r_cur.id_institution;
                    l_new_rec_row.code_description  := r_cur.code_description;
                    l_new_rec_row.id_prof_exec      := r_cur.id_prof_exec;
                    l_new_rec_row.flg_outdated      := r_cur.flg_outdated;
                    l_new_rec_row.flg_sos           := pk_alert_constant.g_no;
                    l_new_rec_row.flg_ongoing       := r_cur.flg_ongoing;
                    l_new_rec_row.flg_normal        := pk_alert_constant.g_yes;
                    l_new_rec_row.flg_has_comments  := pk_alert_constant.g_no;
                    l_new_rec_row.status_str        := r_cur.status_str;
                    l_new_rec_row.status_msg        := r_cur.status_msg;
                    l_new_rec_row.status_icon       := r_cur.status_icon;
                    l_new_rec_row.status_flg        := r_cur.status_flg;
                    l_new_rec_row.dt_last_update    := r_cur.dt_req;
                    l_new_rec_row.flg_stat          := r_cur.flg_priority;
                    --
                
                    pk_alertlog.log_error('Processing ' || l_process_name || ' on ' || i_source_table_name || ' (' ||
                                          l_name_table_ea || '): ' || g_error,
                                          g_package,
                                          l_func_proc_name);
                
                    --
                    -- Events in task_timeline_ea table is dependent of l_new_rec_row.flg_status_req variable
                    IF r_cur.flg_status <> pk_consult_req.g_consult_req_stat_cancel -- Active Data                 
                       AND r_cur.flg_status_epis <> pk_alert_constant.g_epis_status_cancel
                    THEN
                        -- Search for updated registrie
                        SELECT COUNT(0)
                          INTO l_update_reg
                          FROM task_timeline_ea ttea
                         WHERE ttea.id_task_refid = l_new_rec_row.id_task_refid
                           AND ttea.id_tl_task = l_new_rec_row.id_tl_task;
                    
                        -- IF exists one registry, information should be UPDATED in task_timeline_ea table for this registrie
                        IF l_update_reg > 0
                        THEN
                            l_process_name  := 'UPDATE';
                            l_event_into_ea := 'U';
                        ELSE
                            -- IF information doesn't exist in task_timeline_ea table, it is necessary insert that registrie
                            l_process_name  := 'INSERT';
                            l_event_into_ea := 'I';
                        END IF;
                    ELSIF r_cur.flg_status = pk_consult_req.g_consult_req_stat_cancel
                          OR r_cur.flg_status_epis = pk_alert_constant.g_epis_status_cancel
                    THEN
                        -- Cancelled data
                        --
                        -- Information in states that are not relevant are DELETED
                        l_process_name  := 'DELETE';
                        l_event_into_ea := 'D';
                    END IF;
                
                    /*
                    * Operations to perform in task_timeline_ea Easy Access table:
                    *  -> INSERT;
                    *  -> DELETE;
                    *  -> UPDATE.
                    */
                    IF l_event_into_ea = t_data_gov_mnt.g_event_insert
                    -- INSERT
                    THEN
                        g_error := 'TS_task_timeline_ea.INS';
                        pk_alertlog.log_debug(g_error);
                        ts_task_timeline_ea.ins(rec_in => l_new_rec_row, rows_out => o_rowids);
                    
                    ELSIF l_event_into_ea = t_data_gov_mnt.g_event_delete
                    -- DELETE:
                    THEN
                        g_error := 'TS_TASK_TIMELINE_EA.DEL_BY';
                        pk_alertlog.log_debug(g_error);
                        ts_task_timeline_ea.del_by(where_clause_in => 'id_task_refid = ' || l_new_rec_row.id_task_refid ||
                                                                      ' AND id_tl_task = ' || l_new_rec_row.id_tl_task,
                                                   rows_out        => o_rowids);
                    
                    ELSIF l_event_into_ea = t_data_gov_mnt.g_event_update
                    -- UPDATE:
                    THEN
                        g_error := 'TS_TASK_TIMELINE_EA.UPD';
                        pk_alertlog.log_debug(g_error);
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
                                                dt_end_in    => NULL,
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
                                                table_name_nin       => FALSE,
                                                table_name_in        => l_new_rec_row.table_name,
                                                flg_show_method_nin  => FALSE,
                                                flg_show_method_in   => l_new_rec_row.flg_show_method,
                                                code_description_nin => FALSE,
                                                code_description_in  => l_new_rec_row.code_description,
                                                --
                                                flg_outdated_nin         => TRUE,
                                                flg_outdated_in          => l_new_rec_row.flg_outdated,
                                                flg_sos_nin              => FALSE,
                                                flg_sos_in               => l_new_rec_row.flg_sos,
                                                id_parent_task_refid_nin => TRUE,
                                                id_parent_task_refid_in  => l_new_rec_row.id_parent_task_refid,
                                                flg_ongoing_nin          => TRUE,
                                                flg_ongoing_in           => l_new_rec_row.flg_ongoing,
                                                flg_normal_nin           => TRUE,
                                                flg_normal_in            => l_new_rec_row.flg_normal,
                                                id_prof_exec_nin         => TRUE,
                                                id_prof_exec_in          => l_new_rec_row.id_prof_exec,
                                                flg_has_comments_nin     => TRUE,
                                                flg_has_comments_in      => l_new_rec_row.flg_has_comments,
                                                dt_last_update_in        => l_new_rec_row.dt_last_update,
                                                flg_stat_in              => l_new_rec_row.flg_stat,
                                                flg_stat_nin             => TRUE,
                                                rows_out                 => o_rowids);
                    
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
                                              g_owner,
                                              g_package,
                                              'SET_TL_CONSULT_REQ',
                                              l_error_out);
        
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
        
    END set_tl_consult_req;

BEGIN
    -- Initialization

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_ea_logic_consult_req;
/
