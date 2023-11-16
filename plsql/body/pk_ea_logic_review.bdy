/*-- Last Change Revision: $Rev: 1490544 $*/
/*-- Last Change by: $Author: sofia.mendes $*/
/*-- Date of last change: $Date: 2013-07-18 15:59:19 +0100 (qui, 18 jul 2013) $*/

CREATE OR REPLACE PACKAGE BODY pk_ea_logic_review IS

    g_error        VARCHAR2(1000 CHAR);
    g_owner        VARCHAR2(30 CHAR);
    g_package      VARCHAR2(30 CHAR);
    g_sysdate_tstz TIMESTAMP
        WITH LOCAL TIME ZONE;

    /**
    * Process insert/update events on EPIS_HIDRICS into TASK_TIMELINE_EA.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_event_type   event type
    * @param i_rowids       changed records rowids list
    * @param i_src_table    source table name
    * @param i_list_columns changed column names list
    * @param i_dg_table     easy access table name
    *
    * @author               Sofia Mendes
    * @version               2.6.2
    * @since                12-Nov-2012
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
        l_src_table CONSTANT VARCHAR2(30 CHAR) := 'REVIEW_DETAIL';
    
        l_rows  table_varchar := table_varchar();
        l_error t_error_out;
    
        CURSOR c_review IS
            SELECT rd.id_professional, rd.dt_review, rd.flg_context, rd.id_record_area
              FROM review_detail rd
             WHERE rd.rowid IN (SELECT /*+dynamic_sampling(t 2)*/
                                 t.column_value row_id
                                  FROM TABLE(i_rowids) t);
    
        TYPE t_coll_review IS TABLE OF c_review%ROWTYPE;
        l_review_rows t_coll_review;
    
        l_task_types table_number;
    
        l_task_types_str pk_translation.t_desc_translation;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        -- validate arguments
        g_error := 'CALL t_data_gov_mnt.validate_arguments';
        pk_alertlog.log_error(text => g_error, object_name => g_package, sub_object_name => l_func_name);
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
        
            -- get opinion data from rowids
            g_error := 'OPEN c_opinion';
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            OPEN c_review;
            FETCH c_review BULK COLLECT
                INTO l_review_rows;
            CLOSE c_review;
        
            -- copy opinion data into rows collection
            IF l_review_rows IS NOT NULL
               AND l_review_rows.count > 0
            THEN
                -- set variable fields
                FOR i IN l_review_rows.first .. l_review_rows.last
                LOOP
                    g_error := 'GET task types flg_context: ' || l_review_rows(i).flg_context;
                    pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                    SELECT t.id_tl_task BULK COLLECT
                      INTO l_task_types
                      FROM tl_task t
                     WHERE t.review_context = l_review_rows(i).flg_context;
                
                    FOR j IN 1 .. l_task_types.count
                    LOOP
                        IF (j <> 1)
                        THEN
                            l_task_types_str := l_task_types_str || ',';
                        END IF;
                    
                        l_task_types_str := l_task_types_str || l_task_types(j);
                    END LOOP;
                
                    IF (l_task_types_str IS NOT NULL)
                    THEN
                        g_error := 'CALL ts_task_timeline_ea.upd. l_task_types_str: ' || l_task_types_str ||
                                   ' id_task_refid = ' || l_review_rows(i).id_record_area;
                        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                        ts_task_timeline_ea.upd(where_in          => ' id_task_refid = ' || l_review_rows(i)
                                                                    .id_record_area || 'and id_tl_task in (' ||
                                                                     l_task_types_str || ') ',
                                                id_prof_review_in => l_review_rows(i).id_professional,
                                                dt_review_in      => l_review_rows(i).dt_review,
                                                rows_out          => l_rows);
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
    -- log init
    pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    pk_alertlog.log_init(object_name => g_package);
END pk_ea_logic_review;
/
