CREATE OR REPLACE PACKAGE BODY pk_ea_logic_rehab IS

    --  g_error        VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);
    -- g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;

    /**
    * Process insert/update events on REHAB_PRESC into TASK_TIMELINE_EA.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_event_type   event type
    * @param i_rowids       changed records rowids list
    * @param i_src_table    source table name
    * @param i_list_columns changed column names list
    * @param i_dg_table     easy access table name
    *
    * @author               Ana Moita
    * @version              v2.8.4.0
    * @since                2021/11/09
    */
    PROCEDURE set_task_timeline_treat
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
        l_process_name     VARCHAR2(30);
        l_rowids           table_varchar;
        l_event_into_ea    VARCHAR2(1);
        l_flg_outdated     task_timeline_ea.flg_outdated%TYPE := 1;
        o_rowids           table_varchar;
        l_error_out        t_error_out;
        l_flg_has_comments VARCHAR2(1 CHAR);
        l_timestamp        TIMESTAMP(6) WITH LOCAL TIME ZONE := current_timestamp;
    
    BEGIN
        -- Validate arguments
        g_error := 'VALIDATE ARGUMENTS';
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => i_source_table_name,
                                                 i_expected_dg_table_name => 'TASK_TIMELINE_EA',
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
        
            pk_alertlog.log_debug('Processing ' || l_process_name || ' on ' || i_source_table_name || ' event type=' ||
                                  i_event_type || ' (' || 'REHAB_PRESC' || ')',
                                  g_package_name,
                                  'SET_TASK_TIMELINE');
        
            -- Loop through changed records
            g_error := 'LOOP PROCESS';
            IF ((i_rowids IS NOT NULL) AND (i_rowids.count > 0))
            THEN
            
                g_error := 'GET REHAB_PRESC ROWIDS';
                --get_data_rowid(i_lang, i_prof, i_source_table_name, i_rowids, l_rowids);
            
                DELETE FROM tbl_temp;
                insert_tbl_temp(i_vc_1 => i_rowids);
            
                /*       
                */
                FOR r_cur IN (
                              
                              SELECT rtt.id_rehab_presc,
                                      rtt.dt_req,
                                      --               rs.dt_begin as dt_begin,
                                      rtt.dt_last_execution,
                                      rtt.flg_status,
                                      rtt.id_prof_req,
                                      rtt.code_intervention,
                                      rtt.code_area,
                                      rtt.id_episode,
                                      rtt.id_visit,
                                      rtt.id_patient,
                                      rtt.id_institution,
                                      pk_alert_constant.g_yes flg_normal,
                                      pk_alert_constant.g_no flg_prn,
                                      rtt.id_rehab_area_interv,
                                      rtt.flg_priority,
                                      rtt.id_prof_exec,
                                      'REHAB_PRESC.FLG_STATUS' code_status,
                                      decode(rtt.flg_status,
                                             pk_rehab.g_rehab_presc_begin,
                                             pk_prog_notes_constants.g_task_ongoing_o,
                                             pk_rehab.g_rehab_presc_susp_prop,
                                             pk_prog_notes_constants.g_task_ongoing_o,
                                             pk_rehab.g_rehab_presc_edit_prop,
                                             pk_prog_notes_constants.g_task_ongoing_o,
                                             pk_rehab.g_rehab_presc_ongoing_prop,
                                             pk_prog_notes_constants.g_task_ongoing_o,
                                             pk_rehab.g_rehab_presc_ongoing,
                                             pk_prog_notes_constants.g_task_ongoing_o,
                                             pk_rehab.g_rehab_presc_suspend,
                                             pk_prog_notes_constants.g_task_ongoing_o,
                                             pk_rehab.g_rehab_presc_referral,
                                             pk_prog_notes_constants.g_task_ongoing_o,
                                             pk_rehab.g_rehab_presc_disc_prop,
                                             pk_prog_notes_constants.g_task_inactive_i,
                                             pk_rehab.g_rehab_presc_discontinued,
                                             pk_prog_notes_constants.g_task_inactive_i,
                                             pk_rehab.g_rehab_presc_cancel,
                                             pk_prog_notes_constants.g_task_inactive_i,
                                             pk_rehab.g_rehab_presc_finished,
                                             pk_prog_notes_constants.g_task_finalized_f) flg_ongoing
                                FROM (SELECT /*+opt_estimate(table rp rows=1)*/
                                        rp.id_rehab_presc,
                                        rsn.dt_begin AS dt_req,
                                        rs.dt_end dt_last_execution,
                                        rp.flg_status,
                                        rp.id_professional id_prof_req,
                                        i.code_intervention,
                                        ra.code_rehab_area code_area,
                                        e.id_episode,
                                        e.id_visit,
                                        e.id_patient,
                                        e.id_institution,
                                        rp.id_rehab_area_interv,
                                        rsn.flg_priority,
                                        rs.id_professional id_prof_exec,
                                        row_number() over(PARTITION BY rp.id_rehab_presc ORDER BY rs.id_rehab_session DESC) rn
                                         FROM rehab_presc rp
                                         JOIN rehab_sch_need rsn
                                           ON rsn.id_rehab_sch_need = rp.id_rehab_sch_need
                                         JOIN rehab_area_interv rai
                                           ON rai.id_rehab_area_interv = rp.id_rehab_area_interv
                                         JOIN rehab_area ra
                                           ON ra.id_rehab_area = rai.id_rehab_area
                                         JOIN episode e
                                           ON e.id_episode = rsn.id_episode_origin
                                         JOIN intervention i
                                           ON i.id_intervention = rai.id_intervention
                                         LEFT JOIN rehab_session rs
                                           ON rs.id_rehab_presc = rp.id_rehab_presc
                                        WHERE rp.rowid IN (SELECT t.column_value row_id
                                                             FROM TABLE(i_rowids) t)
                                          AND rp.flg_status NOT IN
                                              (pk_rehab.g_rehab_presc_cancel, pk_rehab.g_rehab_presc_not_order_reas)) rtt
                               WHERE rtt.rn = 1)
                
                LOOP
                    g_error := 'DEFINE NEW RECORD FOR TASK_TIMELINE_EA';
                    --esatdo 
                    --data inicial
                    -- dt last update na execuçao 
                
                    l_new_rec_row.id_tl_task        := pk_prog_notes_constants.g_task_rehab_treatments;
                    l_new_rec_row.table_name        := 'REHAB_PRESC';
                    l_new_rec_row.flg_show_method   := pk_alert_constant.g_tl_oriented_visit;
                    l_new_rec_row.dt_dg_last_update := l_timestamp;
                    l_new_rec_row.id_task_refid     := r_cur.id_rehab_presc; --id_rehab_presc
                    l_new_rec_row.dt_begin          := r_cur.dt_req;
                    --l_new_rec_row.dt_end            := r_cur.dt_end;
                    l_new_rec_row.flg_status_req   := r_cur.flg_status;
                    l_new_rec_row.id_prof_req      := r_cur.id_prof_req;
                    l_new_rec_row.dt_req           := r_cur.dt_req;
                    l_new_rec_row.id_patient       := r_cur.id_patient;
                    l_new_rec_row.id_episode       := r_cur.id_episode;
                    l_new_rec_row.id_visit         := r_cur.id_visit;
                    l_new_rec_row.id_institution   := r_cur.id_institution;
                    l_new_rec_row.code_description := r_cur.code_intervention;
                    l_new_rec_row.code_desc_group  := r_cur.code_area;
                    l_new_rec_row.flg_outdated     := l_flg_outdated;
                    --   l_new_rec_row.id_ref_group        := r_cur.id_interv_presc_det;
                    --                    l_new_rec_row.universal_desc_clob := r_cur.notes;
                    --  l_new_rec_row.id_task_notes       := r_cur.id_epis_documentation;
                    l_new_rec_row.code_status       := r_cur.code_status;
                    l_new_rec_row.flg_ongoing       := r_cur.flg_ongoing;
                    l_new_rec_row.flg_normal        := r_cur.flg_normal;
                    l_new_rec_row.id_prof_exec      := r_cur.id_prof_exec;
                    l_new_rec_row.dt_last_update    := l_timestamp;
                    l_new_rec_row.dt_last_execution := r_cur.dt_last_execution;
                
                    IF r_cur.flg_prn = pk_alert_constant.g_yes
                    THEN
                        l_new_rec_row.flg_sos := pk_alert_constant.g_yes;
                    ELSE
                        l_new_rec_row.flg_sos := pk_alert_constant.g_no;
                    END IF;
                    /*                
                        --check if it has comments
                        BEGIN
                            SELECT pk_alert_constant.g_yes
                              INTO l_flg_has_comments
                              FROM treatment_management tm
                             WHERE tm.id_treatment = r_cur.id_interv_presc_det
                               AND rownum = 1;
                        EXCEPTION
                            WHEN no_data_found THEN
                    
                        END;
                    
                        
                    
                    /*
                    * Executar sobre a tabela de Easy Access TASK_TIMELINE_EA: 
                    *  -> INSERT;
                    *  -> DELETE;
                    *  -> UPDATE.
                    */
                    l_new_rec_row.flg_has_comments := pk_alert_constant.g_no;
                    --    l_flg_has_comments := pk_alert_constant.g_no;
                    -- INSERT
                    IF l_event_into_ea = t_data_gov_mnt.g_event_insert
                    THEN
                        g_error := 'TS_TASK_TIMELINE_EA.INS';
                        ts_task_timeline_ea.ins(rec_in          => l_new_rec_row,
                                                handle_error_in => FALSE,
                                                rows_out        => o_rowids);
                    
                        -- DELETE: Apenas podem ocorrer DELETE's nas tabelas INTERV_PRESCRIPTION e INTERV_PRESC_DET
                    ELSIF l_event_into_ea = t_data_gov_mnt.g_event_delete
                    THEN
                        g_error := 'TS_TASK_TIMELINE_EA.DEL_BY';
                        ts_task_timeline_ea.del_by(where_clause_in => 'id_task_refid = ' || l_new_rec_row.id_task_refid ||
                                                                      ' AND id_tl_task = ' || l_new_rec_row.id_tl_task,
                                                   rows_out        => o_rowids);
                    
                        -- UPDATE
                    ELSIF l_event_into_ea = t_data_gov_mnt.g_event_update
                    THEN
                        IF l_new_rec_row.flg_status_req IN
                           (pk_rehab.g_rehab_presc_begin,
                            pk_rehab.g_rehab_presc_susp_prop,
                            pk_rehab.g_rehab_presc_edit_prop,
                            pk_rehab.g_rehab_presc_ongoing_prop,
                            pk_rehab.g_rehab_presc_ongoing,
                            pk_rehab.g_rehab_presc_suspend)
                        
                        THEN
                        
                            g_error := 'TS_TASK_TIMELINE_EA.UPD';
                            ts_task_timeline_ea.upd_ins(id_task_refid_in     => l_new_rec_row.id_task_refid,
                                                        id_tl_task_in        => l_new_rec_row.id_tl_task,
                                                        id_patient_in        => l_new_rec_row.id_patient,
                                                        id_episode_in        => l_new_rec_row.id_episode,
                                                        id_visit_in          => l_new_rec_row.id_visit,
                                                        id_institution_in    => l_new_rec_row.id_institution,
                                                        dt_dg_last_update_in => l_new_rec_row.dt_dg_last_update,
                                                        dt_req_in            => l_new_rec_row.dt_req,
                                                        id_prof_req_in       => l_new_rec_row.id_prof_req,
                                                        dt_begin_in          => l_new_rec_row.dt_begin,
                                                        flg_status_req_in    => l_new_rec_row.flg_status_req,
                                                        table_name_in        => l_new_rec_row.table_name,
                                                        flg_show_method_in   => l_new_rec_row.flg_show_method,
                                                        code_description_in  => l_new_rec_row.code_description,
                                                        flg_ongoing_in       => l_new_rec_row.flg_ongoing,
                                                        flg_normal_in        => l_new_rec_row.flg_normal,
                                                        id_prof_exec_in      => l_new_rec_row.id_prof_exec,
                                                        dt_last_update_in    => l_new_rec_row.dt_last_update,
                                                        flg_outdated_in      => l_new_rec_row.flg_outdated,
                                                        code_status_in       => l_new_rec_row.code_status,
                                                        flg_sos_in           => l_new_rec_row.flg_sos,
                                                        flg_has_comments_in  => l_new_rec_row.flg_has_comments,
                                                        code_desc_group_in   => l_new_rec_row.code_desc_group,
                                                        rows_out             => o_rowids);
                        ELSE
                            g_error := 'TS_TASK_TIMELINE_EA.DEL_BY';
                            ts_task_timeline_ea.del_by(where_clause_in => 'id_task_refid = ' ||
                                                                          l_new_rec_row.id_task_refid ||
                                                                          ' AND id_tl_task = ' ||
                                                                          l_new_rec_row.id_tl_task,
                                                       rows_out        => o_rowids);
                        END IF;
                    ELSE
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
                                              'SET_TASK_TIMELINE_TREATMENTS',
                                              l_error_out);
        
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END set_task_timeline_treat;

    /**
    * Process insert/update events on REHAB_PRESC into TASK_TIMELINE_EA.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_event_type   event type
    * @param i_rowids       changed records rowids list
    * @param i_src_table    source table name
    * @param i_list_columns changed column names list
    * @param i_dg_table     easy access table name
    *
    * @author               Ana Moita
    * @version              v2.8.4.0
    * @since                2021/11/09
    **/
    PROCEDURE set_task_timeline_icf
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
        l_process_name     VARCHAR2(30);
        l_rowids           table_varchar;
        l_event_into_ea    VARCHAR2(1);
        l_flg_outdated     task_timeline_ea.flg_outdated%TYPE := 1;
        o_rowids           table_varchar;
        l_error_out        t_error_out;
        l_flg_has_comments VARCHAR2(1 CHAR);
        l_timestamp        TIMESTAMP(6) WITH LOCAL TIME ZONE := current_timestamp;
    
    BEGIN
        -- Validate arguments
        g_error := 'VALIDATE ARGUMENTS';
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => i_source_table_name,
                                                 i_expected_dg_table_name => 'TASK_TIMELINE_EA',
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
        
            pk_alertlog.log_debug('Processing ' || l_process_name || ' on ' || i_source_table_name || ' event type=' ||
                                  i_event_type || ' (' || 'REHAB_DIAGNOSIS' || ')',
                                  g_package_name,
                                  'SET_TASK_TIMELINE');
        
            -- Loop through changed records
            g_error := 'LOOP PROCESS';
            IF ((i_rowids IS NOT NULL) AND (i_rowids.count > 0))
            THEN
            
                g_error := 'GET REHAB_DIAGNOSIS ROWIDS';
                --get_data_rowid(i_lang, i_prof, i_source_table_name, i_rowids, l_rowids);
            
                DELETE FROM tbl_temp;
                insert_tbl_temp(i_vc_1 => i_rowids);
            
                /*
                */
                FOR r_cur IN (
                              
                              SELECT rd.id_rehab_diagnosis,
                                      rd.dt_last_update,
                                      rd.id_episode,
                                      rd.flg_status,
                                      rd.id_prof_last_update id_prof_req,
                                      e.id_visit,
                                      e.id_patient,
                                      e.id_institution,
                                      'REHAB_DIAGNOSIS.FLG_STATUS' code_status,
                                      rd.notes,
                                      pk_alert_constant.g_yes flg_normal,
                                      pk_alert_constant.g_no flg_prn,
                                      decode(rd.flg_status,
                                             pk_rehab.g_rehab_diag_flg_status_e,
                                             pk_prog_notes_constants.g_task_ongoing_o,
                                             pk_rehab.g_rehab_diag_flg_status_t,
                                             pk_prog_notes_constants.g_task_ongoing_o,
                                             pk_rehab.g_rehab_diag_flg_status_c,
                                             pk_prog_notes_constants.g_task_inactive_i,
                                             pk_rehab.g_rehab_diag_flg_status_r,
                                             pk_prog_notes_constants.g_task_finalized_f) flg_ongoing
                                FROM rehab_diagnosis rd
                                JOIN episode e
                                  ON e.id_episode = rd.id_episode
                               WHERE rd.rowid IN (SELECT t.column_value row_id
                                                    FROM TABLE(i_rowids) t)
                                 AND rd.flg_status NOT IN ('C'))
                
                LOOP
                    g_error := 'DEFINE NEW RECORD FOR TASK_TIMELINE_EA';
                    --esatdo 
                    --data inicial
                    -- dt last update na execuçao 
                
                    l_new_rec_row.id_tl_task        := pk_prog_notes_constants.g_task_icf;
                    l_new_rec_row.table_name        := 'REHAB_DIAGNOSIS';
                    l_new_rec_row.flg_show_method   := pk_alert_constant.g_tl_oriented_visit;
                    l_new_rec_row.dt_dg_last_update := l_timestamp;
                    l_new_rec_row.id_task_refid     := r_cur.id_rehab_diagnosis; --id_rehab_diagnosis
                    --l_new_rec_row.dt_begin          := r_cur.dt_req;
                    --l_new_rec_row.dt_end            := r_cur.dt_end;
                    l_new_rec_row.flg_status_req := r_cur.flg_status;
                    l_new_rec_row.id_prof_req    := r_cur.id_prof_req;
                    l_new_rec_row.dt_req         := r_cur.dt_last_update;
                    l_new_rec_row.id_patient     := r_cur.id_patient;
                    l_new_rec_row.id_episode     := r_cur.id_episode;
                    l_new_rec_row.id_visit       := r_cur.id_visit;
                    l_new_rec_row.id_institution := r_cur.id_institution;
                    -- l_new_rec_row.code_description := r_cur.code_intervention;
                    -- l_new_rec_row.code_desc_group  := r_cur.code_area;
                    l_new_rec_row.flg_outdated := l_flg_outdated;
                    --   l_new_rec_row.id_ref_group        := r_cur.id_interv_presc_det;
                    l_new_rec_row.universal_desc_clob := r_cur.notes;
                    --  l_new_rec_row.id_task_notes       := r_cur.id_epis_documentation;
                    l_new_rec_row.code_status := r_cur.code_status;
                    l_new_rec_row.flg_ongoing := r_cur.flg_ongoing;
                    l_new_rec_row.flg_normal  := r_cur.flg_normal;
                    --                        l_new_rec_row.id_prof_exec      := r_cur.id_prof_exec;
                    l_new_rec_row.dt_last_update := r_cur.dt_last_update;
                    -- l_new_rec_row.dt_last_execution := r_cur.dt_last_execution;
                
                    IF r_cur.flg_prn = pk_alert_constant.g_yes
                    THEN
                        l_new_rec_row.flg_sos := pk_alert_constant.g_yes;
                    ELSE
                        l_new_rec_row.flg_sos := pk_alert_constant.g_no;
                    END IF;
                    /*
                    --check if it has comments
                    BEGIN
                        SELECT pk_alert_constant.g_yes
                          INTO l_flg_has_comments
                          FROM treatment_management tm
                         WHERE tm.id_treatment = r_cur.id_interv_presc_det
                           AND rownum = 1;
                    EXCEPTION
                        WHEN no_data_found THEN
                    
                    END;
                    
                    * * executar sobre a tabela de easy access task_timeline_ea :* - > INSERT;
                    * - > DELETE;
                    * - > update. */
                    l_new_rec_row.flg_has_comments := pk_alert_constant.g_no;
                    --    l_flg_has_comments := pk_alert_constant.g_no;
                    -- INSERT
                    IF l_event_into_ea = t_data_gov_mnt.g_event_insert
                    THEN
                        g_error := 'TS_TASK_TIMELINE_EA.INS';
                        ts_task_timeline_ea.ins(rec_in          => l_new_rec_row,
                                                handle_error_in => FALSE,
                                                rows_out        => o_rowids);
                    
                        -- DELETE: Apenas podem ocorrer DELETE's nas tabelas INTERV_PRESCRIPTION e INTERV_PRESC_DET
                    ELSIF l_event_into_ea = t_data_gov_mnt.g_event_delete
                    THEN
                        g_error := 'TS_TASK_TIMELINE_EA.DEL_BY';
                        ts_task_timeline_ea.del_by(where_clause_in => 'id_task_refid = ' || l_new_rec_row.id_task_refid ||
                                                                      ' AND id_tl_task = ' || l_new_rec_row.id_tl_task,
                                                   rows_out        => o_rowids);
                    
                        -- UPDATE
                    ELSIF l_event_into_ea = t_data_gov_mnt.g_event_update
                    THEN
                        IF l_new_rec_row.flg_status_req IN
                           (pk_rehab.g_rehab_diag_flg_status_e, pk_rehab.g_rehab_diag_flg_status_t)
                        
                        THEN
                        
                            g_error := 'TS_TASK_TIMELINE_EA.UPD';
                            ts_task_timeline_ea.upd_ins(id_task_refid_in     => l_new_rec_row.id_task_refid,
                                                        id_tl_task_in        => l_new_rec_row.id_tl_task,
                                                        id_patient_in        => l_new_rec_row.id_patient,
                                                        id_episode_in        => l_new_rec_row.id_episode,
                                                        id_visit_in          => l_new_rec_row.id_visit,
                                                        id_institution_in    => l_new_rec_row.id_institution,
                                                        dt_dg_last_update_in => l_new_rec_row.dt_dg_last_update,
                                                        dt_req_in            => l_new_rec_row.dt_req,
                                                        id_prof_req_in       => l_new_rec_row.id_prof_req,
                                                        dt_begin_in          => l_new_rec_row.dt_begin,
                                                        flg_status_req_in    => l_new_rec_row.flg_status_req,
                                                        table_name_in        => l_new_rec_row.table_name,
                                                        flg_show_method_in   => l_new_rec_row.flg_show_method,
                                                        code_description_in  => l_new_rec_row.code_description,
                                                        flg_ongoing_in       => l_new_rec_row.flg_ongoing,
                                                        flg_normal_in        => l_new_rec_row.flg_normal,
                                                        id_prof_exec_in      => l_new_rec_row.id_prof_exec,
                                                        dt_last_update_in    => l_new_rec_row.dt_last_update,
                                                        flg_outdated_in      => l_new_rec_row.flg_outdated,
                                                        code_status_in       => l_new_rec_row.code_status,
                                                        flg_sos_in           => l_new_rec_row.flg_sos,
                                                        flg_has_comments_in  => l_new_rec_row.flg_has_comments,
                                                        code_desc_group_in   => l_new_rec_row.code_desc_group,
                                                        rows_out             => o_rowids);
                        ELSE
                            g_error := 'TS_TASK_TIMELINE_EA.DEL_BY';
                            ts_task_timeline_ea.del_by(where_clause_in => 'id_task_refid = ' ||
                                                                          l_new_rec_row.id_task_refid ||
                                                                          ' AND id_tl_task = ' ||
                                                                          l_new_rec_row.id_tl_task,
                                                       rows_out        => o_rowids);
                        END IF;
                    ELSE
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
                                              'SET_TASK_TIMELINE_ICF',
                                              l_error_out);
        
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END set_task_timeline_icf;

BEGIN
    -- log init
    pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    pk_alertlog.log_init(object_name => g_package);

END pk_ea_logic_rehab;
/
