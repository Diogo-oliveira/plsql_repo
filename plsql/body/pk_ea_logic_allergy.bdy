/*-- Last Change Revision: $Rev: 2027011 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:43 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_ea_logic_allergy IS

    -- Private type declarations
    -- Private constant declarations    
    -- Private variable declarations

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Function and procedure implementations

    /*******************************************************************************************************************************************
    * Name:                           set_tl_allergy
    * Description:                    Function that updates past history information in the Easy Access table (task_timeline_ea)
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
    * @author                         paulo teixeira
    * @version                        2.6.2.1.5
    * @since                          2012/09/05 
    *******************************************************************************************************************************************/
    PROCEDURE set_tl_allergy
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
        l_func_proc_name VARCHAR2(30) := 'SET_TL_ALLERGY';
        l_name_table_ea  VARCHAR2(30) := 'TASK_TIMELINE_EA';
        l_process_name   VARCHAR2(30);
        l_event_into_ea  VARCHAR2(1);
        l_update_reg     NUMBER(24);
        o_rowids         table_varchar;
        l_error_out      t_error_out;
    
        l_timestamp TIMESTAMP(6) WITH LOCAL TIME ZONE := current_timestamp;
    
        PROCEDURE inner_process_allergy(l_filter_type VARCHAR2 DEFAULT NULL) IS
        BEGIN
            g_error := 'GET SCHEDULE DISCHARGE ROWIDS AND INFORMATION';
            pk_alertlog.log_debug(g_error);
            FOR r_cur IN (SELECT pa.id_pat_allergy,
                                 pa.id_episode,
                                 pa.dt_pat_allergy_tstz dt_req,
                                 pa.flg_status,
                                 pa.id_prof_write id_prof_request,
                                 pa.id_patient,
                                 e.id_visit,
                                 e.id_institution,
                                 pa.year_begin,
                                 pa.month_begin,
                                 pa.day_begin,
                                 pa.year_end,
                                 pa.month_end,
                                 pa.day_end,
                                 CASE
                                      WHEN pa.flg_status IN (pk_allergy.g_pat_allergy_flg_active) THEN
                                       pk_prog_notes_constants.g_task_ongoing_o
                                      WHEN pa.flg_status IN (pk_allergy.g_pat_allergy_flg_resolved) THEN
                                       pk_prog_notes_constants.g_task_finalized_f
                                      WHEN pa.flg_status IN (pk_allergy.g_pat_allergy_flg_passive) THEN
                                       pk_prog_notes_constants.g_task_inactive_i
                                      ELSE
                                       pk_prog_notes_constants.g_task_ongoing_o
                                  END flg_ongoing,
                                 pk_alert_constant.g_yes flg_normal,
                                 NULL id_prof_exec,
                                 pa.flg_type
                            FROM pat_allergy pa
                            LEFT JOIN episode e
                              ON e.id_episode = pa.id_episode
                           WHERE pa.rowid IN (SELECT vc_1
                                                FROM tbl_temp)
                          
                          --
                          )
            
            LOOP
            
                g_error := 'DEFINE NEW RECORD FOR TASK_TIMELINE_EA';
                --
                IF l_filter_type IS NULL
                THEN
                    l_new_rec_row.id_tl_task := pk_prog_notes_constants.g_task_allergies;
                ELSE
                    l_new_rec_row.id_tl_task := CASE
                                                    WHEN r_cur.flg_type = pk_allergy.g_flg_type_allergy THEN
                                                     pk_prog_notes_constants.g_task_allergies_allergy
                                                    WHEN r_cur.flg_type = pk_allergy.g_flg_type_adv_react THEN
                                                     pk_prog_notes_constants.g_task_allergies_adverse
                                                    WHEN r_cur.flg_type = pk_allergy.g_flg_type_intolerance THEN
                                                     pk_prog_notes_constants.g_task_allergies_intolerance
                                                    WHEN r_cur.flg_type = pk_allergy.g_flg_type_propensity THEN
                                                     pk_prog_notes_constants.g_task_allergies_propensity
                                                    ELSE
                                                     pk_prog_notes_constants.g_task_allergies
                                                END;
                END IF;
                l_new_rec_row.table_name        := pk_prog_notes_constants.g_tl_table_name_pa;
                l_new_rec_row.flg_show_method   := pk_alert_constant.g_tl_oriented_patient;
                l_new_rec_row.dt_dg_last_update := current_timestamp;
                --
                l_new_rec_row.id_task_refid    := r_cur.id_pat_allergy;
                l_new_rec_row.dt_begin := CASE
                                              WHEN r_cur.year_begin IS NOT NULL
                                                   AND r_cur.month_begin IS NOT NULL
                                                   AND r_cur.day_begin IS NOT NULL THEN
                                               to_timestamp(r_cur.year_begin || lpad(r_cur.month_begin, 2, '0') ||
                                                            lpad(r_cur.day_begin, 2, '0'),
                                                            'YYYYMMDD')
                                              ELSE
                                               NULL
                                          END;
                l_new_rec_row.dt_end := CASE
                                            WHEN r_cur.year_end IS NOT NULL
                                                 AND r_cur.month_end IS NOT NULL
                                                 AND r_cur.day_end IS NOT NULL THEN
                                             to_timestamp(r_cur.year_end || lpad(r_cur.month_end, 2, '0') ||
                                                          lpad(r_cur.day_end, 2, '0'),
                                                          'YYYYMMDD')
                                            ELSE
                                             NULL
                                        END;
                l_new_rec_row.flg_status_req   := r_cur.flg_status;
                l_new_rec_row.id_prof_req      := r_cur.id_prof_request;
                l_new_rec_row.dt_req           := r_cur.dt_req;
                l_new_rec_row.id_patient       := r_cur.id_patient;
                l_new_rec_row.id_episode       := r_cur.id_episode;
                l_new_rec_row.id_visit         := r_cur.id_visit;
                l_new_rec_row.id_institution   := r_cur.id_institution;
                l_new_rec_row.flg_outdated     := pk_ea_logic_tasktimeline.g_flg_not_outdated;
                l_new_rec_row.flg_sos          := pk_alert_constant.g_no;
                l_new_rec_row.flg_ongoing      := r_cur.flg_ongoing;
                l_new_rec_row.flg_normal       := r_cur.flg_normal;
                l_new_rec_row.id_prof_exec     := r_cur.id_prof_exec;
                l_new_rec_row.flg_has_comments := pk_alert_constant.g_no;
                l_new_rec_row.dt_last_update   := r_cur.dt_req;
                --
            
                pk_alertlog.log_error('Processing ' || l_process_name || ' on ' || i_source_table_name || ' (' ||
                                      l_name_table_ea || '): ' || g_error,
                                      g_package,
                                      l_func_proc_name);
            
                --
                -- Events in task_timeline_ea table is dependent of l_new_rec_row.flg_status_req variable
                IF (r_cur.flg_status <> pk_allergy.g_pat_allergy_flg_cancelled OR r_cur.flg_status IS NULL) -- Active Data                       
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
                      -- 
                        -- IF information doesn't exist in task_timeline_ea table, it is necessary insert that registrie
                        l_process_name  := 'INSERT';
                        l_event_into_ea := 'I';
                    END IF;
                ELSIF r_cur.flg_status = pk_allergy.g_pat_allergy_flg_cancelled
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
                                            dt_end_in    => l_new_rec_row.dt_end,
                                            --
                                            flg_status_req_nin => FALSE,
                                            flg_status_req_in  => l_new_rec_row.flg_status_req,
                                            --
                                            table_name_nin      => FALSE,
                                            table_name_in       => l_new_rec_row.table_name,
                                            flg_show_method_nin => FALSE,
                                            flg_show_method_in  => l_new_rec_row.flg_show_method,
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
        END inner_process_allergy;
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
                l_event_into_ea := '';
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
                -- Insert i_rowids into table tbl_temp to increase performance
                DELETE FROM tbl_temp;
                insert_tbl_temp(i_vc_1 => i_rowids);
                inner_process_allergy();
                inner_process_allergy(pk_alert_constant.g_yes);
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
                                              'SET_TL_ALLERGY',
                                              l_error_out);
        
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
        
    END set_tl_allergy;
    /*******************************************************************************************************************************************
    * Name:                           set_tl_allergy_unaware
    * Description:                    Function that updates past history information in the Easy Access table (task_timeline_ea)
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
    * @author                         paulo teixeira
    * @version                        2.6.2.1.5
    * @since                          2012/09/05 
    *******************************************************************************************************************************************/
    PROCEDURE set_tl_allergy_unaware
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
        l_func_proc_name VARCHAR2(30) := 'SET_TL_ALLERGY_UNAWARE';
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
                l_event_into_ea := '';
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
                -- Insert i_rowids into table tbl_temp to increase performance
                DELETE FROM tbl_temp;
                insert_tbl_temp(i_vc_1 => i_rowids);
            
                g_error := 'GET SCHEDULE DISCHARGE ROWIDS AND INFORMATION';
                pk_alertlog.log_debug(g_error);
                FOR r_cur IN (SELECT pa.id_pat_allergy_unawareness,
                                     pa.id_episode,
                                     pa.dt_creation                           dt_req,
                                     pa.flg_status,
                                     pa.id_professional                       id_prof_request,
                                     pa.id_patient,
                                     e.id_visit,
                                     e.id_institution,
                                     pk_prog_notes_constants.g_task_ongoing_o flg_ongoing,
                                     pk_alert_constant.g_yes                  flg_normal,
                                     NULL                                     id_prof_exec
                                FROM pat_allergy_unawareness pa
                                LEFT JOIN episode e
                                  ON e.id_episode = pa.id_episode
                               WHERE pa.rowid IN (SELECT vc_1
                                                    FROM tbl_temp)
                              
                              --
                              )
                
                LOOP
                
                    g_error := 'DEFINE NEW RECORD FOR TASK_TIMELINE_EA';
                    --
                    l_new_rec_row.id_tl_task        := pk_prog_notes_constants.g_task_no_known_allergies;
                    l_new_rec_row.table_name        := pk_prog_notes_constants.g_tl_table_name_pa_unaware;
                    l_new_rec_row.flg_show_method   := pk_alert_constant.g_tl_oriented_patient;
                    l_new_rec_row.dt_dg_last_update := current_timestamp;
                    --
                    l_new_rec_row.id_task_refid    := r_cur.id_pat_allergy_unawareness;
                    l_new_rec_row.dt_begin         := NULL;
                    l_new_rec_row.dt_end           := NULL;
                    l_new_rec_row.flg_status_req   := r_cur.flg_status;
                    l_new_rec_row.id_prof_req      := r_cur.id_prof_request;
                    l_new_rec_row.dt_req           := r_cur.dt_req;
                    l_new_rec_row.id_patient       := r_cur.id_patient;
                    l_new_rec_row.id_episode       := r_cur.id_episode;
                    l_new_rec_row.id_visit         := r_cur.id_visit;
                    l_new_rec_row.id_institution   := r_cur.id_institution;
                    l_new_rec_row.flg_outdated     := pk_ea_logic_tasktimeline.g_flg_not_outdated;
                    l_new_rec_row.flg_sos          := pk_alert_constant.g_no;
                    l_new_rec_row.flg_ongoing      := r_cur.flg_ongoing;
                    l_new_rec_row.flg_normal       := r_cur.flg_normal;
                    l_new_rec_row.id_prof_exec     := r_cur.id_prof_exec;
                    l_new_rec_row.flg_has_comments := pk_alert_constant.g_no;
                    l_new_rec_row.dt_last_update   := r_cur.dt_req;
                    --
                
                    pk_alertlog.log_error('Processing ' || l_process_name || ' on ' || i_source_table_name || ' (' ||
                                          l_name_table_ea || '): ' || g_error,
                                          g_package,
                                          l_func_proc_name);
                
                    --
                    -- Events in task_timeline_ea table is dependent of l_new_rec_row.flg_status_req variable
                    IF (r_cur.flg_status NOT IN (pk_allergy.g_unawareness_outdated, pk_allergy.g_unawareness_cancelled) OR
                       r_cur.flg_status IS NULL) -- Active Data                       
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
                    ELSIF r_cur.flg_status IN (pk_allergy.g_unawareness_outdated, pk_allergy.g_unawareness_cancelled)
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
                                                dt_end_in    => l_new_rec_row.dt_end,
                                                --
                                                flg_status_req_nin => FALSE,
                                                flg_status_req_in  => l_new_rec_row.flg_status_req,
                                                --
                                                table_name_nin      => FALSE,
                                                table_name_in       => l_new_rec_row.table_name,
                                                flg_show_method_nin => FALSE,
                                                flg_show_method_in  => l_new_rec_row.flg_show_method,
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
                                              g_owner,
                                              g_package,
                                              'SET_TL_ALLERGY_UNAWARE',
                                              l_error_out);
        
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
        
    END set_tl_allergy_unaware;

BEGIN
    -- Initialization

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_ea_logic_allergy;
/
