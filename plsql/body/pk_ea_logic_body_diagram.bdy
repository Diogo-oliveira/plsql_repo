/*-- Last Change Revision: $Rev: 2027020 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:45 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE BODY pk_ea_logic_body_diagram IS

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
    * @version              2.6.5
    * @since                19/02/2016
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
        l_src_table CONSTANT VARCHAR2(30 CHAR) := 'EPIS_DIAGRAM';
        l_ea_row task_timeline_ea%ROWTYPE;
        l_count  NUMBER(12);
        l_error  t_error_out;
    
        CURSOR c_epis_diagram IS
            SELECT edl.id_epis_diagram id_epis_diagram,
                   ed.id_episode id_episode,
                   ed.id_patient id_patient,
                   edl.flg_status flg_status,
                   edl.id_professional id_prof_create,
                   nvl(ed.dt_last_update_tstz, edl.dt_creation_tstz) dt_req,
                   epi.id_institution id_institution,
                   epi.id_visit id_visit,
                   epi.flg_status flg_status_epis,
                   dl.flg_type
              FROM epis_diagram_layout edl
              JOIN epis_diagram ed
                ON edl.id_epis_diagram = ed.id_epis_diagram
              JOIN episode epi
                ON epi.id_episode = ed.id_episode
              JOIN diagram_layout dl
                ON edl.id_diagram_layout = dl.id_diagram_layout
             WHERE edl.rowid IN (SELECT vc_1
                                   FROM tbl_temp);
    
        TYPE t_coll_epis_diagram IS TABLE OF c_epis_diagram%ROWTYPE;
        l_epis_diagram_rows t_coll_epis_diagram;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        -- validate arguments
        g_error := 'CALL t_data_gov_mnt.validate_arguments';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_src_table,
                                                 i_dg_table_name          => i_dg_table,
                                                 i_expected_table_name    => 'EPIS_DIAGRAM_LAYOUT',
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
            g_error := 'OPEN c_epis_diagram';
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            DELETE FROM tbl_temp;
            insert_tbl_temp(i_vc_1 => i_rowids);
        
            OPEN c_epis_diagram;
            FETCH c_epis_diagram BULK COLLECT
                INTO l_epis_diagram_rows;
            CLOSE c_epis_diagram;
        
            -- copy surgery data into rows collection
            IF l_epis_diagram_rows IS NOT NULL
               AND l_epis_diagram_rows.count > 0
            THEN
                -- set constant fields
                l_ea_row.table_name        := l_src_table;
                l_ea_row.id_tl_task        := pk_prog_notes_constants.g_task_body_diagram;
                l_ea_row.flg_show_method   := pk_alert_constant.g_tl_oriented_episode;
                l_ea_row.dt_dg_last_update := g_sysdate_tstz;
                l_ea_row.flg_sos           := pk_alert_constant.g_no;
                l_ea_row.flg_normal        := pk_alert_constant.g_yes;
                l_ea_row.flg_has_comments  := pk_alert_constant.g_no;
            
                -- set variable fields
                FOR i IN l_epis_diagram_rows.first .. l_epis_diagram_rows.last
                LOOP
                    l_ea_row.id_task_refid  := l_epis_diagram_rows(i).id_epis_diagram;
                    l_ea_row.id_patient     := l_epis_diagram_rows(i).id_patient;
                    l_ea_row.id_episode     := l_epis_diagram_rows(i).id_episode;
                    l_ea_row.id_visit       := l_epis_diagram_rows(i).id_visit;
                    l_ea_row.id_institution := l_epis_diagram_rows(i).id_institution;
                    l_ea_row.dt_req         := l_epis_diagram_rows(i).dt_req;
                    l_ea_row.id_prof_req    := l_epis_diagram_rows(i).id_prof_create;
                    l_ea_row.flg_status_req := l_epis_diagram_rows(i).flg_status;
                    l_ea_row.flg_outdated   := pk_ea_logic_tasktimeline.g_flg_not_outdated;
                    l_ea_row.flg_ongoing    := pk_prog_notes_constants.g_task_ongoing_o;
                    l_ea_row.flg_type       := l_epis_diagram_rows(i).flg_type;
                
                    l_ea_row.dt_last_execution := nvl(l_epis_diagram_rows(i).dt_req, g_sysdate_tstz);
                    l_ea_row.dt_last_update    := nvl(l_epis_diagram_rows(i).dt_req, g_sysdate_tstz);
                
                    -- check if it already exists
                    SELECT COUNT(1)
                      INTO l_count
                      FROM task_timeline_ea a
                     WHERE a.id_task_refid = l_ea_row.id_task_refid
                       AND a.id_tl_task = l_ea_row.id_tl_task;
                
                    -- insert or update EA
                    IF l_count = 0
                    THEN
                        g_error := 'CALL ts_task_timeline_ea.ins';
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
    /********************************************************************************************
    * Get BODY DIAGRAM description
    *
    * @param i_lang                 Language
    * @param i_prof                 professional/institution/software
    * @param i_id_epis_diagram       BODY DIAGRAM identifier
    *
    * @return                       Returns the surgery request information
    *
    * @author    Paulo Teixeira
    * @version   2.6.5
    * @since     05/07/2016
    *********************************************************************************************/
    FUNCTION get_body_diagram_description
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_diagram IN epis_diagram.id_epis_diagram%TYPE
    ) RETURN CLOB IS
        l_description CLOB;
    BEGIN
    
        SELECT pk_message.get_message(i_lang, 'DIAGRAM_T001') || ' ' || ed.diagram_order || chr(10) || chr(9) ||
               pk_utils.concat_table(CAST(MULTISET (SELECT pk_translation.get_translation(i_lang, dl.code_diagram_layout)
                                             FROM epis_diagram_layout edl
                                             JOIN diagram_layout dl
                                               ON dl.id_diagram_layout = edl.id_diagram_layout
                                            WHERE edl.id_epis_diagram = ed.id_epis_diagram
                                              AND edl.flg_status NOT IN
                                                  (pk_diagram_new.g_diag_lay_removed,
                                                   pk_diagram_new.g_diag_lay_cancelled)
                                            ORDER BY edl.layout_order) AS table_varchar),
                                     chr(10) || chr(9))
          INTO l_description
          FROM epis_diagram ed
         WHERE ed.id_epis_diagram = i_id_epis_diagram;
    
        RETURN l_description;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_body_diagram_description;

BEGIN
    -- Initialization

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);

END pk_ea_logic_body_diagram;
/
