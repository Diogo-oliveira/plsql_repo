/*-- Last Change Revision: $Rev: 2027054 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:51 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_ea_logic_prognosis IS

    g_error        VARCHAR2(1000 CHAR);
    g_owner        VARCHAR2(30 CHAR);
    g_package      VARCHAR2(30 CHAR);
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;

    /**
    * Process insert/update events on SCHEDULE_SR into TASK_TIMELINE_EA.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_event_type   event type
    * @param i_rowids       changed records rowids list
    * @param i_src_table    source table name
    * @param i_list_columns changed column names list
    * @param i_dg_table     easy access table name
    *
    * @author               Vanessa Barsottelli
    * @version              2.7.0
    * @since                29/11/2016
    */

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
        l_src_table CONSTANT VARCHAR2(30 CHAR) := 'EPIS_PROGNOSIS';
    
        l_flg_not_outdated CONSTANT task_timeline_ea.flg_outdated%TYPE := pk_ea_logic_tasktimeline.g_flg_not_outdated;
        l_flg_outdated     CONSTANT task_timeline_ea.flg_outdated%TYPE := pk_ea_logic_tasktimeline.g_flg_outdated;
    
        l_ea_row task_timeline_ea%ROWTYPE;
        l_count  NUMBER(12);
        l_error  t_error_out;
    
        CURSOR c_prognosis IS
            SELECT ep.id_epis_prognosis,
                   ep.id_episode,
                   epi.id_visit,
                   epi.id_institution,
                   epi.id_patient,
                   ep.flg_status,
                   CASE
                        WHEN ep.flg_status = pk_alert_constant.g_active THEN
                         nvl(ep.id_prof_last_update, ep.id_prof_create)
                        ELSE
                         ep.id_prof_cancel
                    END id_prof_reg,
                   CASE
                        WHEN ep.flg_status = pk_alert_constant.g_active THEN
                         nvl(ep.dt_last_update, ep.dt_create)
                        ELSE
                         ep.dt_cancel
                    END dt_req,
                   decode(ep.flg_status, pk_alert_constant.g_active, l_flg_not_outdated, l_flg_outdated) flg_outdated,
                   epi.flg_status flg_status_epis,
                   ep.prognosis_notes universal_description_clob
              FROM epis_prognosis ep
              JOIN episode epi
                ON epi.id_episode = ep.id_episode
             WHERE ep.rowid IN (SELECT vc_1
                                  FROM tbl_temp);
    
        TYPE t_coll_prognosis IS TABLE OF c_prognosis%ROWTYPE;
        l_prognosis_rows t_coll_prognosis;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
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
        
            -- get surgery data from rowids
            g_error := 'OPEN c_prognosis';
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            DELETE FROM tbl_temp;
            insert_tbl_temp(i_vc_1 => i_rowids);
        
            OPEN c_prognosis;
            FETCH c_prognosis BULK COLLECT
                INTO l_prognosis_rows;
            CLOSE c_prognosis;
        
            -- copy surgery data into rows collection
            IF l_prognosis_rows IS NOT NULL
               AND l_prognosis_rows.count > 0
            THEN
                -- set constant fields
                l_ea_row.table_name        := l_src_table;
                l_ea_row.id_tl_task        := pk_prog_notes_constants.g_task_prognosis;
                l_ea_row.flg_show_method   := pk_alert_constant.g_tl_oriented_episode;
                l_ea_row.dt_dg_last_update := g_sysdate_tstz;
                l_ea_row.flg_sos           := pk_alert_constant.g_no;
                l_ea_row.flg_normal        := pk_alert_constant.g_yes;
                l_ea_row.flg_has_comments  := pk_alert_constant.g_no;
            
                -- set variable fields
                FOR i IN l_prognosis_rows.first .. l_prognosis_rows.last
                LOOP
                    l_ea_row.id_task_refid       := l_prognosis_rows(i).id_epis_prognosis;
                    l_ea_row.id_patient          := l_prognosis_rows(i).id_patient;
                    l_ea_row.id_episode          := l_prognosis_rows(i).id_episode;
                    l_ea_row.id_visit            := l_prognosis_rows(i).id_visit;
                    l_ea_row.id_institution      := l_prognosis_rows(i).id_institution;
                    l_ea_row.dt_req              := l_prognosis_rows(i).dt_req;
                    l_ea_row.id_prof_req         := l_prognosis_rows(i).id_prof_reg;
                    l_ea_row.flg_status_req      := l_prognosis_rows(i).flg_status;
                    l_ea_row.flg_outdated        := l_prognosis_rows(i).flg_outdated;
                    l_ea_row.flg_ongoing         := pk_prog_notes_constants.g_task_ongoing_o;
                    l_ea_row.universal_desc_clob := l_prognosis_rows(i).universal_description_clob;
                    l_ea_row.dt_last_execution   := nvl(l_prognosis_rows(i).dt_req, g_sysdate_tstz);
                    l_ea_row.dt_last_update      := nvl(l_prognosis_rows(i).dt_req, g_sysdate_tstz);
                
                    g_error := 'FOR LOOP id_task_refid: ' || l_ea_row.id_task_refid || ' flg_status: ' || l_prognosis_rows(i)
                              .flg_status;
                    pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                
                    --if it was canceled there is nothing to insert or update
                    -- if it is part od an admission do not consider it, and delete it, just in case
                    -- it should appear in the admission section
                    IF l_prognosis_rows(i).flg_status_epis = pk_alert_constant.g_epis_status_cancel
                        OR l_prognosis_rows(i).flg_status = pk_alert_constant.g_cancelled
                    THEN
                        g_error := 'CALL TS_TASK_TIMELINE_EA.DEL';
                        pk_alertlog.log_debug(text            => g_error,
                                              object_name     => g_package,
                                              sub_object_name => l_func_name);
                        ts_task_timeline_ea.del(id_task_refid_in => l_ea_row.id_task_refid,
                                                id_tl_task_in    => l_ea_row.id_tl_task);
                    ELSE
                        -- check if it already exists
                        SELECT COUNT(1)
                          INTO l_count
                          FROM task_timeline_ea a
                         WHERE a.id_task_refid = l_ea_row.id_task_refid
                           AND a.id_tl_task = l_ea_row.id_tl_task;
                    
                        -- insert or update EA
                        IF l_count = 0
                        THEN
                            g_error := 'CALL ts_task_timeline_ea.ins I';
                            pk_alertlog.log_debug(text            => g_error,
                                                  object_name     => g_package,
                                                  sub_object_name => l_func_name);
                            ts_task_timeline_ea.ins(rec_in => l_ea_row);
                        ELSE
                            g_error := 'CALL ts_task_timeline_ea.upd';
                            pk_alertlog.log_debug(text            => g_error,
                                                  object_name     => g_package,
                                                  sub_object_name => l_func_name);
                            ts_task_timeline_ea.upd(rec_in => l_ea_row);
                        END IF;
                    
                    END IF;
                END LOOP;
            
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
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_ea_logic_prognosis;
/
