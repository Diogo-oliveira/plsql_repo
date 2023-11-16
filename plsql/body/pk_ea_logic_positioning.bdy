/*-- Last Change Revision: $Rev: 2027047 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:49 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_ea_logic_positioning IS

    -- Private type declarations
    -- Private constant declarations    
    -- Private variable declarations

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Function and procedure implementations

    /*******************************************************************************************************************************************
    * Name:                           set_tl_positioning
    * Description:                    Function that updates patient positionings information in the Easy Access table (task_timeline_ea)
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
    PROCEDURE set_tl_positioning
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
        l_func_proc_name VARCHAR2(30) := 'SET_TL_POSITIONING';
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
                --DELETE FROM tbl_temp;
                --insert_tbl_temp(i_vc_1 => i_rowids);
            
                g_error := 'GET PAT positioning ROWIDS AND INFORMATION';
                pk_alertlog.log_debug(g_error);
                FOR r_cur IN (SELECT id_epis_positioning,
                                     id_patient,
                                     id_episode,
                                     flg_status,
                                     id_prof_request,
                                     dt_req,
                                     id_institution,
                                     dt_epis_positioning,
                                     id_visit,
                                     flg_outdated,
                                     flg_ongoing,
                                     flg_status_epis
                                FROM (SELECT ep.id_epis_positioning id_epis_positioning,
                                             epi.id_patient id_patient,
                                             ep.id_episode id_episode,
                                             ep.flg_status flg_status,
                                             ep.id_professional id_prof_request,
                                             ep.dt_creation_tstz dt_req,
                                             epi.id_institution id_institution,
                                             ep.dt_epis_positioning,
                                             epi.id_visit id_visit,
                                             CASE
                                                  WHEN ep.flg_status IN
                                                       (pk_timeline.g_epis_posit_flg_statu_e,
                                                        pk_timeline.g_epis_posit_flg_statu_r) THEN
                                                   pk_ea_logic_tasktimeline.g_flg_not_outdated
                                                  ELSE
                                                   pk_ea_logic_tasktimeline.g_flg_outdated
                                              END flg_outdated,
                                             CASE
                                                  WHEN ep.flg_status IN
                                                       (pk_timeline.g_epis_posit_flg_statu_i,
                                                        pk_inp_positioning.g_epis_posit_f) THEN
                                                   pk_prog_notes_constants.g_task_finalized_f
                                                  ELSE
                                                   pk_prog_notes_constants.g_task_ongoing_o
                                              END flg_ongoing,
                                             epi.flg_status flg_status_epis
                                        FROM epis_positioning ep
                                        JOIN episode epi
                                          ON epi.id_episode = ep.id_episode
                                       WHERE ep.flg_status IN (pk_timeline.g_epis_posit_flg_statu_e,
                                                               pk_timeline.g_epis_posit_flg_statu_r,
                                                               pk_timeline.g_epis_posit_flg_statu_i,
                                                               pk_inp_positioning.g_epis_posit_c,
                                                               pk_inp_positioning.g_epis_posit_o,
                                                               pk_inp_positioning.g_epis_posit_f)
                                         AND ep.rowid IN (SELECT /*+dynamic_sampling(t 2)*/
                                                           t.column_value row_id
                                                            FROM TABLE(i_rowids) t)))
                
                LOOP
                
                    g_error := 'DEFINE NEW RECORD FOR TASK_TIMELINE_EA';
                    g_error := 'CALL set_tl_positioning - id_epis_positioning: ' || r_cur.id_epis_positioning ||
                               ' id_patient: ' || r_cur.id_patient;
                    pk_alertlog.log_debug(g_error);
                    --
                    l_new_rec_row.id_tl_task        := pk_prog_notes_constants.g_task_positioning;
                    l_new_rec_row.table_name        := 'EPIS_POSITIONING';
                    l_new_rec_row.flg_show_method   := pk_alert_constant.g_tl_oriented_episode;
                    l_new_rec_row.dt_dg_last_update := current_timestamp;
                    l_new_rec_row.id_task_refid     := r_cur.id_epis_positioning;
                    l_new_rec_row.dt_begin          := r_cur.dt_req;
                    l_new_rec_row.flg_status_req    := r_cur.flg_status;
                    l_new_rec_row.id_prof_req       := r_cur.id_prof_request;
                    l_new_rec_row.dt_req            := r_cur.dt_req;
                    l_new_rec_row.id_patient        := r_cur.id_patient;
                    l_new_rec_row.id_episode        := r_cur.id_episode;
                    l_new_rec_row.id_visit          := r_cur.id_visit;
                    l_new_rec_row.id_institution    := r_cur.id_institution;
                    l_new_rec_row.flg_outdated      := r_cur.flg_outdated;
                    l_new_rec_row.flg_sos           := pk_alert_constant.g_no;
                    l_new_rec_row.flg_ongoing       := r_cur.flg_ongoing;
                    l_new_rec_row.flg_normal        := pk_alert_constant.g_yes;
                    l_new_rec_row.flg_has_comments  := pk_alert_constant.g_no;
                    l_new_rec_row.dt_last_update    := r_cur.dt_epis_positioning;
                    --
                
                    pk_alertlog.log_error('Processing ' || l_process_name || ' on ' || i_source_table_name || ' (' ||
                                          l_name_table_ea || '): ' || g_error,
                                          g_package,
                                          l_func_proc_name);
                    pk_alertlog.log_error('FLG_STATUS: ' || r_cur.flg_status);
                    --
                    -- Events in task_timeline_ea table is dependent of l_new_rec_row.flg_status_req variable
                    IF r_cur.flg_status <> pk_inp_positioning.g_epis_posit_c -- Active Data
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
                    ELSIF r_cur.flg_status IN (pk_inp_positioning.g_epis_posit_c, pk_inp_positioning.g_epis_posit_o)
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
                                                table_name_nin          => FALSE,
                                                table_name_in           => l_new_rec_row.table_name,
                                                flg_show_method_nin     => FALSE,
                                                flg_show_method_in      => l_new_rec_row.flg_show_method,
                                                code_description_nin    => FALSE,
                                                code_description_in     => l_new_rec_row.code_description,
                                                universal_desc_clob_nin => TRUE,
                                                universal_desc_clob_in  => l_new_rec_row.universal_desc_clob,
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
                                              'SET_TL_POSITIONING',
                                              l_error_out);
        
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
        
    END set_tl_positioning;

    /********************************************************************************************
    * Update grid_task status_string for positionings.
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
    * @author                         Nuno Alves
    * @version                        2.6.5.0.2
    * @since                          25-May-2015
    **********************************************************************************************/

    PROCEDURE set_grid_task_positionings
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
    
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
                ins_grid_task_positionings(i_lang => i_lang, i_prof => i_prof, i_rowids => i_rowids);
            END IF;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => g_error);
    END set_grid_task_positionings;

    PROCEDURE ins_grid_task_positionings
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_rowids IN table_varchar
    ) IS
    BEGIN
        FOR r_cur IN (SELECT ep.id_episode
                        FROM epis_positioning_plan epp
                        JOIN epis_positioning_det epd
                          ON epd.id_epis_positioning_det = epp.id_epis_positioning_det
                        JOIN epis_positioning ep
                          ON ep.id_epis_positioning = epd.id_epis_positioning
                       WHERE epp.rowid IN (SELECT /*+opt_estimate (table t rows=1)*/
                                            *
                                             FROM TABLE(i_rowids) t)
                          OR i_rowids IS NULL)
        LOOP
            ins_grid_task_positionings_epi(i_lang => i_lang, i_prof => i_prof, i_id_episode => r_cur.id_episode);
        END LOOP;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => g_error);
    END ins_grid_task_positionings;

    PROCEDURE ins_grid_task_positionings_epi
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN grid_task.id_episode%TYPE
    ) IS
        l_grid_task   grid_task%ROWTYPE := NULL;
        l_shortcut    sys_shortcut.id_sys_shortcut%TYPE;
        l_value_date  VARCHAR2(200);
        l_server_date VARCHAR2(200);
        l_aux         VARCHAR2(200);
        l_error_out   t_error_out;
        l_prof        profissional := i_prof;
    BEGIN
    
        --limpa o valor do posicionamento
        --foi adicionado por causa dos cancelamento do posicionamento
        g_error := 'CALL PK_GRID.UPDATE_GRID_TASK - id_episode';
        IF NOT pk_grid.update_grid_task(i_lang          => i_lang,
                                        i_prof          => i_prof,
                                        i_episode       => i_id_episode,
                                        positioning_in  => NULL,
                                        positioning_nin => FALSE,
                                        o_error         => l_error_out)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        FOR r_cur IN (SELECT epis.flg_status epis_status,
                             'E' flg_time,
                             epp.dt_prev_plan_tstz dt_begin,
                             epp.flg_status,
                             ep.dt_creation_tstz dt_req,
                             epis.dt_begin_tstz epis_dt_begin,
                             NULL img_name,
                             epp.dt_epis_positioning_plan dt_update,
                             epis.id_institution,
                             ei.id_software,
                             nvl(epp.id_prof_exec, ep.id_professional) id_professional
                        FROM episode epis
                       INNER JOIN epis_positioning ep
                          ON ep.id_episode = epis.id_episode
                         AND ep.flg_status IN (pk_inp_positioning.g_epis_posit_r, pk_inp_positioning.g_epis_posit_e)
                       INNER JOIN epis_positioning_det epd
                          ON ep.id_epis_positioning = epd.id_epis_positioning
                       INNER JOIN epis_positioning_plan epp
                          ON epd.id_epis_positioning_det = epp.id_epis_positioning_det
                         AND epp.flg_status = pk_inp_positioning.g_epis_posit_e -- ET 2007/03/29 -> Só deve actualizar na GRID_TASK, planos de posicionamentos em curso
                        JOIN episode epis
                          ON ep.id_episode = epis.id_episode
                        JOIN epis_info ei
                          ON epis.id_episode = ei.id_episode
                       WHERE ep.id_episode = i_id_episode
                       ORDER BY dt_req)
        LOOP
            l_grid_task := NULL;
        
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
        
            g_error := 'PK_ACCESS.GET_ID_SHORTCUT for POSITIONING_LIST';
            IF NOT pk_access.get_id_shortcut(i_lang        => i_lang,
                                             i_prof        => l_prof,
                                             i_intern_name => pk_alert_constant.g_shortcut_position_inten,
                                             o_id_shortcut => l_shortcut,
                                             o_error       => l_error_out)
            THEN
                l_shortcut := NULL;
            END IF;
        
            l_grid_task.id_episode := i_id_episode;
        
            -- Construir status string
            l_value_date := pk_date_utils.to_char_insttimezone(l_prof,
                                                               r_cur.dt_begin,
                                                               pk_alert_constant.g_dt_yyyymmddhh24miss_tzr);
        
            l_server_date := pk_date_utils.to_char_insttimezone(l_prof,
                                                                current_timestamp,
                                                                pk_alert_constant.g_dt_yyyymmddhh24miss_tzr);
        
            g_error := 'CALL PK_UTILS.GET_STATUS_STRING_IMMEDIATE';
            pk_utils.build_status_string(i_display_type => pk_inp_positioning.g_date,
                                         i_value_date   => l_value_date,
                                         i_shortcut     => l_shortcut,
                                         o_status_str   => l_grid_task.positioning,
                                         o_status_msg   => l_aux,
                                         o_status_icon  => l_aux,
                                         o_status_flg   => l_aux);
        
            l_grid_task.positioning := REPLACE(l_grid_task.positioning,
                                               pk_alert_constant.g_status_rpl_chr_dt_server,
                                               l_server_date) || '|';
            --
            g_error := 'CALL PK_GRID.UPDATE_GRID_TASK - id_episode';
            IF NOT pk_grid.update_grid_task(i_lang          => i_lang,
                                            i_prof          => l_prof,
                                            i_episode       => l_grid_task.id_episode,
                                            positioning_in  => l_grid_task.positioning,
                                            positioning_nin => FALSE,
                                            o_error         => l_error_out)
            THEN
                RAISE t_data_gov_mnt.g_excp_invalid_arguments;
            END IF;
        
            IF l_grid_task.positioning IS NULL
            THEN
            
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
    END ins_grid_task_positionings_epi;

BEGIN
    -- Initialization

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_ea_logic_positioning;
/
