/*-- Last Change Revision: $Rev: 2027028 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:46 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_ea_logic_epis_er_law IS

    /**
    * Updates epis_reason information in the Task Timeline Easy Access table (task_timeline_ea)
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
    * @author                         Paulo teixeira
    * @version                        2.6.4.2
    * @since                          2014/08/25
    */
    PROCEDURE set_tl_epis_er_law
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
        l_func_proc_name VARCHAR2(30) := 'SET_TL_EPIS_ER_LAW';
        l_name_table_ea  VARCHAR2(30) := 'TASK_TIMELINE_EA';
        l_update_reg     NUMBER(24);
        l_id_tl_task    CONSTANT PLS_INTEGER := pk_prog_notes_constants.g_task_emergency_law;
        l_tl_table_name CONSTANT VARCHAR2(1000 CHAR) := 'EPIS_ER_LAW';
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
        
            -- Loop through changed records
            g_error := 'LOOP PROCESS';
            IF ((i_rowids IS NOT NULL) AND (i_rowids.count > 0))
            THEN
            
                DELETE FROM tbl_temp;
                insert_tbl_temp(i_vc_1 => i_rowids);
            
                FOR r_cur IN (SELECT eel.id_epis_er_law id_task_refid,
                                     epis.id_patient,
                                     epis.id_episode,
                                     epis.id_visit,
                                     epis.id_institution,
                                     eel.dt_create dt_req,
                                     eel.id_prof_create id_prof_req,
                                     CASE
                                          WHEN eel.id_cancel_reason IS NULL THEN
                                           pk_ea_logic_tasktimeline.g_flg_not_outdated
                                          ELSE
                                           pk_ea_logic_tasktimeline.g_flg_outdated
                                      END flg_outdated,
                                     eel.flg_er_law_status flg_status_req,
                                     epis.flg_status flg_status_epis
                                FROM epis_er_law eel
                                JOIN episode epis
                                  ON eel.id_episode = epis.id_episode
                               WHERE eel.rowid IN (SELECT vc_1
                                                     FROM tbl_temp))
                
                LOOP
                
                    IF r_cur.flg_outdated = pk_ea_logic_tasktimeline.g_flg_outdated
                    THEN
                        g_error := 'TS_TASK_TIMELINE_EA.DEL_BY';
                        ts_task_timeline_ea.del_by(where_clause_in => 'id_task_refid = ' || r_cur.id_task_refid ||
                                                                      ' AND id_tl_task = ' || l_id_tl_task,
                                                   rows_out        => o_rowids);
                    ELSE
                    
                        g_error := 'DEFINE RECORD FOR TASK_TIMELINE_EA';
                        --
                        l_new_rec_row.id_tl_task        := l_id_tl_task;
                        l_new_rec_row.table_name        := l_tl_table_name;
                        l_new_rec_row.flg_show_method   := pk_alert_constant.g_tl_oriented_episode;
                        l_new_rec_row.dt_dg_last_update := current_timestamp;
                        --
                        l_new_rec_row.id_task_refid    := r_cur.id_task_refid;
                        l_new_rec_row.flg_status_req   := r_cur.flg_status_req;
                        l_new_rec_row.id_prof_req      := r_cur.id_prof_req;
                        l_new_rec_row.dt_req           := r_cur.dt_req;
                        l_new_rec_row.id_patient       := r_cur.id_patient;
                        l_new_rec_row.id_episode       := r_cur.id_episode;
                        l_new_rec_row.id_visit         := r_cur.id_visit;
                        l_new_rec_row.id_institution   := r_cur.id_institution;
                        l_new_rec_row.flg_outdated     := r_cur.flg_outdated;
                        l_new_rec_row.flg_sos          := pk_alert_constant.g_no;
                        l_new_rec_row.flg_ongoing      := pk_prog_notes_constants.g_task_ongoing_o;
                        l_new_rec_row.flg_normal       := pk_alert_constant.g_yes;
                        l_new_rec_row.id_prof_exec     := r_cur.id_prof_req;
                        l_new_rec_row.flg_has_comments := pk_alert_constant.g_no;
                        l_new_rec_row.dt_last_update   := r_cur.dt_req;
                    
                        SELECT COUNT(0)
                          INTO l_update_reg
                          FROM task_timeline_ea tte
                         WHERE tte.id_task_refid = l_new_rec_row.id_task_refid
                           AND tte.table_name = l_tl_table_name
                           AND tte.id_tl_task = l_id_tl_task;
                    
                        IF l_update_reg = 0
                        -- INSERT
                        THEN
                            g_error := 'TS_TASK_TIMELINE_EA.INS';
                            ts_task_timeline_ea.ins(rec_in => l_new_rec_row, rows_out => o_rowids);
                        
                        ELSE
                            -- UPDATE                    
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
                                                    code_description_nin    => FALSE,
                                                    code_description_in     => l_new_rec_row.code_description,
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
                        END IF;
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
        
    END set_tl_epis_er_law;
BEGIN
    -- Log initialization
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_ea_logic_epis_er_law;
/
