/*-- Last Change Revision: $Rev: 1670919 $*/
/*-- Last Change by: $Author: mario.mineiro $*/
/*-- Date of last change: $Date: 2014-12-12 15:53:36 +0000 (sex, 12 dez 2014) $*/

CREATE OR REPLACE PACKAGE BODY pk_ea_logic_plan IS

    -- This package provides Easy Access logic procedures to maintain the Plan's EA table.

    PROCEDURE get_data_rowid
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_table_name IN VARCHAR,
        i_rowids     IN table_varchar,
        o_rowids     OUT table_varchar
    ) IS
        l_error_out t_error_out;
    BEGIN
    
        IF i_table_name = 'EPIS_RECOMEND'
        THEN
            o_rowids := i_rowids;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DATA_ROWID',
                                              l_error_out);
        
            o_rowids := table_varchar();
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END get_data_rowid;

    /**
    * Updates plan information in the Task Timeline Easy Access table (task_timeline_ea)
    * 
    * @param i_lang                   Language
    * @param i_prof                   Professional
    * @param i_event_type             Type of event (UPDATE, INSERT, etc)
    * @param i_rowids                 List of ROWIDs belonging to the changed records.
    * @param i_source_table_name      Name of the table that was changed.
    * @param i_list_columns           List of columns that were changed
    * @param i_dg_table_name          Name of the Data Governance table.
    * 
    * @value i_lang                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * @value i_event_type             {*} t_data_gov_mnt.g_event_insert {*} t_data_gov_mnt.g_event_update {*} t_data_gov_mnt.g_event_delete
    * 
    * @return                         Return FALSE if an error occours, otherwise return TRUE
    *
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         António Neto
    * @version                        2.6.2
    * @since                          21-Mar-2012
    */
    PROCEDURE set_task_timeline_plan
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
        l_func_proc_name VARCHAR2(30) := 'SET_TASK_TIMELINE_PLAN';
        l_name_table_ea  VARCHAR2(30) := 'TASK_TIMELINE_EA';
        l_process_name   VARCHAR2(30);
        l_rowids         table_varchar;
        l_event_into_ea  VARCHAR2(1);
        l_update_reg     NUMBER(24);
    
        l_recomend_act           CONSTANT VARCHAR2(1 CHAR) := pk_alert_constant.g_active;
        l_tl_table_name_recomend CONSTANT VARCHAR2(1000 CHAR) := pk_alert_constant.g_tl_table_name_recomend;
        l_tl_oriented_episode    CONSTANT VARCHAR2(1 CHAR) := pk_alert_constant.g_tl_oriented_episode;
        l_flg_temp_def           CONSTANT VARCHAR2(1 CHAR) := pk_discharge.g_flg_def;
        l_flg_not_outdated       CONSTANT task_timeline_ea.flg_outdated%TYPE := pk_ea_logic_tasktimeline.g_flg_not_outdated;
        l_flg_outdated           CONSTANT task_timeline_ea.flg_outdated%TYPE := pk_ea_logic_tasktimeline.g_flg_outdated;
        l_epis_status_cancel     CONSTANT VARCHAR2(1 CHAR) := pk_alert_constant.g_epis_status_cancel;
    
        o_rowids    table_varchar;
        l_error_out t_error_out;    
    
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
            IF ((i_rowids IS NOT NULL) AND (i_rowids.count > 0))
            THEN
            
                g_error := 'GET PLAN ROWIDS';
                get_data_rowid(i_lang, i_prof, i_source_table_name, i_rowids, l_rowids);
            
                DELETE FROM tbl_temp;
                insert_tbl_temp(i_vc_1 => l_rowids);
            
                FOR r_cur IN (SELECT er.id_epis_recomend id_task_refid,
                                     epis.id_patient,
                                     epis.id_episode,
                                     epis.id_visit,
                                     epis.id_institution,
                                     er.dt_epis_recomend_tstz dt_req,
                                     er.id_professional id_prof_req,
                                     NULL code_description,
                                     CASE
                                          WHEN er.flg_status = l_recomend_act THEN
                                           l_flg_not_outdated
                                          ELSE
                                           l_flg_outdated
                                      END flg_outdated,
                                     nvl(er.flg_status, l_recomend_act) flg_status_req,
                                     er.desc_epis_recomend_clob universal_description_clob,
                                     er.flg_type,
                                     epis.flg_status flg_status_epis,
                                     er.id_cancel_info_det,
                                     er.id_epis_recomend_parent,
                                     pk_prog_notes_constants.g_task_ongoing_o flg_ongoing,
                                     pk_alert_constant.g_yes flg_normal,
                                     NULL id_prof_exec,
                                     CASE
                                          WHEN er.flg_type = pk_progress_notes.g_type_plan THEN
                                           pk_prog_notes_constants.g_task_plan_notes
                                          WHEN er.flg_type = pk_progress_notes.g_type_subjective THEN
                                           pk_prog_notes_constants.g_task_subjective
                                          WHEN er.flg_type = pk_progress_notes.g_type_objective THEN
                                           pk_prog_notes_constants.g_task_objective
                                          WHEN er.flg_type = pk_progress_notes.g_type_assessment THEN
                                           pk_prog_notes_constants.g_task_assessment
                                          ELSE
                                           NULL
                                      END id_tl_task
                                FROM epis_recomend er
                               INNER JOIN episode epis
                                  ON er.id_episode = epis.id_episode
                               WHERE er.rowid IN (SELECT vc_1
                                                    FROM tbl_temp)
                                 AND er.flg_type IN (pk_progress_notes.g_type_plan,
                                                     pk_progress_notes.g_type_subjective,
                                                     pk_progress_notes.g_type_objective,
                                                     pk_progress_notes.g_type_assessment)
                                 AND er.flg_temp = l_flg_temp_def)
                
                LOOP
                
                    g_error := 'DEFINE NEW RECORD FOR TASK_TIMELINE_EA';
                    --
                    l_new_rec_row.id_tl_task        := r_cur.id_tl_task;
                    l_new_rec_row.table_name        := l_tl_table_name_recomend;
                    l_new_rec_row.flg_show_method   := l_tl_oriented_episode;
                    l_new_rec_row.dt_dg_last_update := current_timestamp;
                    --
                    l_new_rec_row.id_task_refid        := r_cur.id_task_refid;
                    l_new_rec_row.flg_status_req       := r_cur.flg_status_req;
                    l_new_rec_row.id_prof_req          := r_cur.id_prof_req;
                    l_new_rec_row.dt_req               := r_cur.dt_req;
                    l_new_rec_row.id_patient           := r_cur.id_patient;
                    l_new_rec_row.id_episode           := r_cur.id_episode;
                    l_new_rec_row.id_visit             := r_cur.id_visit;
                    l_new_rec_row.id_institution       := r_cur.id_institution;
                    l_new_rec_row.flg_outdated         := r_cur.flg_outdated;
                    l_new_rec_row.universal_desc_clob  := r_cur.universal_description_clob;
                    l_new_rec_row.flg_sos              := pk_alert_constant.g_no;
                    l_new_rec_row.id_parent_task_refid := r_cur.id_epis_recomend_parent;
                    l_new_rec_row.flg_ongoing          := r_cur.flg_ongoing;
                    l_new_rec_row.flg_normal           := r_cur.flg_normal;
                    l_new_rec_row.id_prof_exec         := r_cur.id_prof_exec;
                    l_new_rec_row.flg_has_comments     := pk_alert_constant.g_no;
                    l_new_rec_row.dt_last_update       := r_cur.dt_req;
                
                    pk_alertlog.log_debug('Processing ' || l_process_name || ' on ' || i_source_table_name || ' (' ||
                                          l_name_table_ea || '): ' || g_error,
                                          g_package_name,
                                          l_func_proc_name);
                
                    -- Events in TASK_TIMELINE_EA table is dependent of l_new_rec_row.flg_status_req variable
                    IF l_new_rec_row.flg_status_req = l_recomend_act
                       AND r_cur.flg_status_epis <> l_epis_status_cancel
                       AND r_cur.id_cancel_info_det IS NULL
                    THEN
                        -- Search for updated registrie
                        SELECT COUNT(0)
                          INTO l_update_reg
                          FROM task_timeline_ea tte
                         WHERE tte.id_task_refid = l_new_rec_row.id_task_refid
                           AND tte.table_name = l_tl_table_name_recomend
                           AND tte.id_tl_task = r_cur.id_tl_task;
                    
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
                        IF l_new_rec_row.flg_status_req <> l_recomend_act -- Not Active
                           OR r_cur.flg_status_epis = l_epis_status_cancel
                           OR r_cur.id_cancel_info_det IS NOT NULL
                        THEN
                            -- Information in states that are not relevant are DELETED
                            l_process_name  := 'DELETE';
                            l_event_into_ea := 'D';
                        ELSE
                            l_process_name  := 'UPDATE';
                            l_event_into_ea := 'U';
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
                    -- DELETE: Apenas poderão ocorrer DELETE's na tabela EPIS_RECOMEND
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
                                                flg_status_req_nin => FALSE,
                                                flg_status_req_in  => l_new_rec_row.flg_status_req,
                                                --
                                                table_name_nin          => FALSE,
                                                table_name_in           => l_new_rec_row.table_name,
                                                flg_show_method_nin     => FALSE,
                                                flg_show_method_in      => l_new_rec_row.flg_show_method,
                                                universal_desc_clob_nin => TRUE,
                                                universal_desc_clob_in  => l_new_rec_row.universal_desc_clob,
                                                --
                                                flg_outdated_nin         => TRUE,
                                                flg_outdated_in          => l_new_rec_row.flg_outdated,
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
                                              l_func_proc_name,
                                              l_error_out);
        
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
        
    END set_task_timeline_plan;

BEGIN
    -- Log initialization
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_ea_logic_plan;
/
