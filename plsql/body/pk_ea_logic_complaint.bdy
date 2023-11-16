/*-- Last Change Revision: $Rev: 1967126 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2020-10-16 17:52:47 +0100 (sex, 16 out 2020) $*/

CREATE OR REPLACE PACKAGE BODY pk_ea_logic_complaint IS

    -- This package provides Easy Access logic procedures to maintain the Complaint's EA table.

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
    
        IF i_table_name = 'EPIS_COMPLAINT'
        THEN
            o_rowids := i_rowids;
        ELSIF i_table_name = 'EPIS_ANAMNESIS'
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
    * Updates complaints information in the Task Timeline Easy Access table (task_timeline_ea)
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
    * @since                          14-Feb-2012
    */
    PROCEDURE set_task_timeline_complaint
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
        l_func_proc_name VARCHAR2(30) := 'SET_TASK_TIMELINE_COMPLAINT';
        l_name_table_ea  VARCHAR2(30) := 'TASK_TIMELINE_EA';
        l_process_name   VARCHAR2(30);
        l_rowids         table_varchar;
        l_event_into_ea  VARCHAR2(1);
        l_update_reg     NUMBER(24);
    
        l_complaint_act           CONSTANT VARCHAR2(1 CHAR) := pk_complaint.g_complaint_act;
        l_id_tl_task_complaint    CONSTANT PLS_INTEGER := pk_prog_notes_constants.g_task_chief_complaint;
        l_epis_status_cancel      CONSTANT VARCHAR2(1 CHAR) := pk_alert_constant.g_epis_status_cancel;
        l_tl_table_name_complaint CONSTANT VARCHAR2(1000 CHAR) := pk_alert_constant.g_tl_table_name_complaint;
        l_tl_oriented_visit       CONSTANT VARCHAR2(1 CHAR) := pk_alert_constant.g_tl_oriented_visit;
    
        l_flg_outdated CONSTANT task_timeline_ea.flg_outdated%TYPE := 1;
    
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
            
                g_error := 'GET COMPLAINT ROWIDS';
                get_data_rowid(i_lang, i_prof, i_source_table_name, i_rowids, l_rowids);
            
                DELETE FROM tbl_temp;
                insert_tbl_temp(i_vc_1 => l_rowids);
            
                FOR r_cur IN (SELECT ec.id_epis_complaint id_task_refid,
                                     epis.id_patient,
                                     epis.id_episode,
                                     epis.id_visit,
                                     epis.id_institution,
                                     ec.adw_last_update_tstz dt_req,
                                     ec.id_professional id_prof_req,
                                     decode(ec.id_complaint, NULL, NULL, 'COMPLAINT.CODE_COMPLAINT.' || ec.id_complaint) code_description,
                                     CASE
                                          WHEN ec.flg_status = l_complaint_act THEN
                                           pk_ea_logic_tasktimeline.g_flg_not_outdated
                                          ELSE
                                           l_flg_outdated
                                      END flg_outdated,
                                     ec.patient_complaint universal_description_clob,
                                     ec.flg_status flg_status_req,
                                     epis.flg_status flg_status_epis,
                                     ec.id_cancel_info_det,
                                     ec.id_epis_complaint_parent,
                                     ec.id_epis_complaint_root,
                                     CASE
                                          WHEN ec.id_epis_complaint_root IS NULL THEN
                                           'P'
                                          ELSE
                                           'S'
                                      END flg_type
                                FROM epis_complaint ec
                               INNER JOIN episode epis
                                  ON ec.id_episode = epis.id_episode
                               WHERE ec.rowid IN (SELECT vc_1
                                                    FROM tbl_temp))
                
                LOOP
                
                    g_error := 'DEFINE NEW RECORD FOR TASK_TIMELINE_EA';
                    --
                    l_new_rec_row.id_tl_task        := l_id_tl_task_complaint;
                    l_new_rec_row.table_name        := l_tl_table_name_complaint;
                    l_new_rec_row.flg_show_method   := l_tl_oriented_visit;
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
                    l_new_rec_row.code_description     := r_cur.code_description;
                    l_new_rec_row.flg_outdated         := r_cur.flg_outdated;
                    l_new_rec_row.universal_desc_clob  := r_cur.universal_description_clob;
                    l_new_rec_row.flg_sos              := pk_alert_constant.g_no;
                    l_new_rec_row.id_parent_task_refid := r_cur.id_epis_complaint_parent;
                    l_new_rec_row.flg_ongoing          := pk_prog_notes_constants.g_task_ongoing_o;
                    l_new_rec_row.flg_normal           := pk_alert_constant.g_yes;
                    l_new_rec_row.id_prof_exec         := r_cur.id_prof_req;
                    l_new_rec_row.flg_has_comments     := pk_alert_constant.g_no;
                    l_new_rec_row.dt_last_update       := r_cur.dt_req;
                
                    pk_alertlog.log_debug('Processing ' || l_process_name || ' on ' || i_source_table_name || ' (' ||
                                          l_name_table_ea || '): ' || g_error,
                                          g_package_name,
                                          l_func_proc_name);
                
                    -- Events in TASK_TIMELINE_EA table is dependent of l_new_rec_row.flg_status_req variable
                    IF l_new_rec_row.flg_status_req = l_complaint_act
                       AND r_cur.flg_status_epis <> l_epis_status_cancel
                       AND r_cur.id_cancel_info_det IS NULL
                    THEN
                        -- Search for updated registrie
                        SELECT COUNT(0)
                          INTO l_update_reg
                          FROM task_timeline_ea tte
                         WHERE tte.id_task_refid = l_new_rec_row.id_task_refid
                           AND tte.table_name = l_tl_table_name_complaint
                           AND tte.id_tl_task = l_id_tl_task_complaint;
                    
                        -- IF exists one registrie, information should be UPDATED in TASK_TIMELINE_EA table for this registrie
                        pk_alertlog.log_debug('l_update_reg : ' || l_update_reg);
                        IF l_update_reg > 0
                        THEN
                            l_process_name  := 'UPDATE';
                            l_event_into_ea := 'U';
                        ELSE
                            IF r_cur.id_epis_complaint_root IS NULL
                            THEN
                            -- IF information doesn't exist in TASK_TIMELINE_EA table, it is necessary insert that registrie
                            l_process_name  := 'INSERT';
                            l_event_into_ea := 'I';
                            ELSE
                                l_event_into_ea := 'X';
                            END IF;
                        END IF;
                    ELSE
                        IF l_new_rec_row.flg_status_req NOT IN (l_complaint_act) -- Not Active
                           OR r_cur.flg_status_epis = l_epis_status_cancel
                           OR (r_cur.id_cancel_info_det IS NOT NULL AND
                           l_new_rec_row.flg_status_req NOT IN (l_complaint_act))
                        THEN
                            pk_alertlog.log_debug('Deleting record. flg_status_req: ' || l_new_rec_row.flg_status_req);
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
                    -- DELETE: Apenas poderão ocorrer DELETE's na tabela EPIS_COMPLAINT
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
                    ELSIF l_event_into_ea = 'X'
                    THEN
                        -- not insert 
                        NULL;
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
                                              'SET_TASK_TIMELINE_COMPLAINT',
                                              l_error_out);
        
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
        
    END set_task_timeline_complaint;

    /**
    * Updates anamnesis information in the Task Timeline Easy Access table (task_timeline_ea)
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
    * @since                          16-Feb-2012
    */
    PROCEDURE set_task_timeline_anamnesis
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
        l_func_proc_name VARCHAR2(30) := 'SET_TASK_TIMELINE_ANAMNESIS';
        l_name_table_ea  VARCHAR2(30) := 'TASK_TIMELINE_EA';
        l_process_name   VARCHAR2(30);
        l_rowids         table_varchar;
        l_event_into_ea  VARCHAR2(1);
        l_update_reg     NUMBER(24);
    
        l_anamnesis_act           CONSTANT VARCHAR2(1 CHAR) := pk_clinical_info.g_epis_active;
        l_type_complaint          CONSTANT VARCHAR2(1 CHAR) := pk_clinical_info.g_complaint;
        l_id_tl_task_anamnesis    CONSTANT PLS_INTEGER := pk_prog_notes_constants.g_task_chief_complaint_anm;
        l_epis_status_cancel      CONSTANT VARCHAR2(1 CHAR) := pk_alert_constant.g_epis_status_cancel;
        l_tl_table_name_anamnesis CONSTANT VARCHAR2(1000 CHAR) := pk_alert_constant.g_tl_table_name_anamnesis;
        l_tl_oriented_visit       CONSTANT VARCHAR2(1 CHAR) := pk_alert_constant.g_tl_oriented_visit;
    
        l_flg_outdated CONSTANT task_timeline_ea.flg_outdated%TYPE := 1;
    
        o_rowids    table_varchar;
        l_error_out t_error_out;
        
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
        
            pk_alertlog.log_debug('Anamnesis Processing ' || l_process_name || ' on ' || i_source_table_name || ' (' ||
                                  l_name_table_ea || ')',
                                  g_package_name,
                                  l_func_proc_name);
        
            -- Loop through changed records
            g_error := 'LOOP PROCESS';
            pk_alertlog.log_debug(g_error);
            IF ((i_rowids IS NOT NULL) AND (i_rowids.count > 0))
            THEN
            
                g_error := 'GET COMPLAINT ROWIDS';
                pk_alertlog.log_debug(g_error);
                get_data_rowid(i_lang, i_prof, i_source_table_name, i_rowids, l_rowids);
            
                DELETE FROM tbl_temp;
                insert_tbl_temp(i_vc_1 => l_rowids);
            
                FOR r_cur IN (SELECT ea.id_epis_anamnesis id_task_refid,
                                     epis.id_patient,
                                     epis.id_episode,
                                     epis.id_visit,
                                     epis.id_institution,
                                     ea.dt_epis_anamnesis_tstz dt_req,
                                     ea.id_professional id_prof_req,
                                     NULL code_description,
                                     CASE
                                          WHEN ea.flg_status = l_anamnesis_act THEN
                                           pk_ea_logic_tasktimeline.g_flg_not_outdated
                                          ELSE
                                           l_flg_outdated
                                      END flg_outdated,
                                     ea.flg_status flg_status_req,
                                     l_id_tl_task_anamnesis id_tl_task,
                                     l_tl_table_name_anamnesis table_name,
                                     ea.desc_epis_anamnesis universal_description_clob,
                                     ea.flg_type,
                                     epis.flg_status flg_status_epis,
                                     ea.id_cancel_info_det,
                                     ea.id_epis_anamnesis_parent
                                FROM epis_anamnesis ea
                               INNER JOIN episode epis
                                  ON ea.id_episode = epis.id_episode
                               WHERE ea.rowid IN (SELECT vc_1
                                                    FROM tbl_temp))
                
                LOOP
                
                    g_error := 'DEFINE NEW RECORD FOR TASK_TIMELINE_EA';
                    pk_alertlog.log_debug(g_error);
                    --
                    l_new_rec_row.id_tl_task        := l_id_tl_task_anamnesis;
                    l_new_rec_row.table_name        := l_tl_table_name_anamnesis;
                    l_new_rec_row.flg_show_method   := l_tl_oriented_visit;
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
                    l_new_rec_row.id_parent_task_refid := r_cur.id_epis_anamnesis_parent;
                    l_new_rec_row.flg_ongoing          := pk_prog_notes_constants.g_task_ongoing_o;
                    l_new_rec_row.flg_normal           := pk_alert_constant.g_yes;
                    l_new_rec_row.id_prof_exec         := r_cur.id_prof_req;
                    l_new_rec_row.flg_has_comments     := pk_alert_constant.g_no;
                    l_new_rec_row.dt_last_update       := r_cur.dt_req;
                
                    pk_alertlog.log_debug('Processing ' || l_process_name || ' on ' || i_source_table_name || ' (' ||
                                          l_name_table_ea || '): ' || g_error,
                                          g_package_name,
                                          l_func_proc_name);
                
                    -- Events in TASK_TIMELINE_EA table is dependent of l_new_rec_row.flg_status_req variable
                    IF l_new_rec_row.flg_status_req = l_anamnesis_act
                       AND r_cur.flg_status_epis <> l_epis_status_cancel
                       AND r_cur.id_cancel_info_det IS NULL
                       AND r_cur.flg_type = l_type_complaint
                    THEN
                        -- Search for updated registrie
                        SELECT COUNT(0)
                          INTO l_update_reg
                          FROM task_timeline_ea tte
                         WHERE tte.id_task_refid = l_new_rec_row.id_task_refid
                           AND tte.table_name = l_tl_table_name_anamnesis
                           AND tte.id_tl_task = l_id_tl_task_anamnesis;
                    
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
                        IF l_new_rec_row.flg_status_req NOT IN (l_anamnesis_act) -- Not Active
                           OR r_cur.flg_status_epis = l_epis_status_cancel
                           OR
                           (r_cur.id_cancel_info_det IS NULL AND l_new_rec_row.flg_status_req NOT IN (l_anamnesis_act))
                           OR r_cur.flg_type <> l_type_complaint
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
                        pk_alertlog.log_debug(g_error);
                        ts_task_timeline_ea.ins(rec_in => l_new_rec_row, rows_out => o_rowids);
                    
                    ELSIF l_event_into_ea = t_data_gov_mnt.g_event_delete
                    -- DELETE: Apenas poderão ocorrer DELETE's na tabela EPIS_COMPLAINT
                    THEN
                        g_error := 'TS_TASK_TIMELINE_EA.DEL_BY';
                        pk_alertlog.log_debug(g_error);
                        ts_task_timeline_ea.del_by(where_clause_in => 'id_task_refid = ' || l_new_rec_row.id_task_refid ||
                                                                      ' AND id_tl_task = ' || l_new_rec_row.id_tl_task,
                                                   rows_out        => o_rowids);
                    
                    ELSIF l_event_into_ea = t_data_gov_mnt.g_event_update
                    -- UPDATE
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
                                              'SET_TASK_TIMELINE_ANAMNESIS',
                                              l_error_out);
        
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
        
    END set_task_timeline_anamnesis;
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
    PROCEDURE set_task_timeline_epis_reason
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
        l_func_proc_name VARCHAR2(30) := 'SET_TASK_TIMELINE_EPIS_REASON';
        l_name_table_ea  VARCHAR2(30) := 'TASK_TIMELINE_EA';
        l_update_reg     NUMBER(24);
        l_id_tl_task    CONSTANT PLS_INTEGER := pk_prog_notes_constants.g_task_chief_complaint_out;
        l_tl_table_name CONSTANT VARCHAR2(1000 CHAR) := 'PN_EPIS_REASON';
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
            
                FOR r_cur IN (SELECT per.id_pn_epis_reason id_task_refid,
                                     epis.id_patient,
                                     epis.id_episode,
                                     epis.id_visit,
                                     epis.id_institution,
                                     nvl(ec.adw_last_update_tstz, ea.dt_epis_anamnesis_tstz) dt_req,
                                     nvl(ec.id_professional, ea.id_professional) id_prof_req,
                                     CASE
                                          WHEN per.flg_status = pk_alert_constant.g_active THEN
                                           pk_ea_logic_tasktimeline.g_flg_not_outdated
                                          ELSE
                                           pk_ea_logic_tasktimeline.g_flg_outdated
                                      END flg_outdated,
                                     per.flg_status flg_status_req,
                                     epis.flg_status flg_status_epis,
                                     per.id_parent id_parent_task_refid
                                FROM pn_epis_reason per
                                JOIN episode epis
                                  ON per.id_episode = epis.id_episode
                                LEFT JOIN epis_complaint ec
                                  ON ec.id_epis_complaint = per.id_epis_complaint
                                LEFT JOIN epis_anamnesis ea
                                  ON ea.id_epis_anamnesis = per.id_epis_anamnesis
                               WHERE per.rowid IN (SELECT vc_1
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
                        l_new_rec_row.id_task_refid        := r_cur.id_task_refid;
                        l_new_rec_row.flg_status_req       := r_cur.flg_status_req;
                        l_new_rec_row.id_prof_req          := r_cur.id_prof_req;
                        l_new_rec_row.dt_req               := r_cur.dt_req;
                        l_new_rec_row.id_patient           := r_cur.id_patient;
                        l_new_rec_row.id_episode           := r_cur.id_episode;
                        l_new_rec_row.id_visit             := r_cur.id_visit;
                        l_new_rec_row.id_institution       := r_cur.id_institution;
                        l_new_rec_row.flg_outdated         := r_cur.flg_outdated;
                        l_new_rec_row.flg_sos              := pk_alert_constant.g_no;
                        l_new_rec_row.flg_ongoing          := pk_prog_notes_constants.g_task_ongoing_o;
                        l_new_rec_row.flg_normal           := pk_alert_constant.g_yes;
                        l_new_rec_row.id_prof_exec         := r_cur.id_prof_req;
                        l_new_rec_row.flg_has_comments     := pk_alert_constant.g_no;
                        l_new_rec_row.dt_last_update       := r_cur.dt_req;
                        l_new_rec_row.id_parent_task_refid := r_cur.id_parent_task_refid;
                    
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

    END set_task_timeline_epis_reason;
BEGIN
    -- Log initialization
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_ea_logic_complaint;
/
