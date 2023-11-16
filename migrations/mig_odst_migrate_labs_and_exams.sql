-- CHANGED BY: Tiago Silva
-- CHANGE DATE: 29/01/2013
-- CHANGE REASON: []
DECLARE

    -- cursor to get all order ses with labs, image and other exams
    CURSOR c_odst_with_labs_and_exams IS
        SELECT os.id_order_set, os.title, os.id_professional, os.id_institution, os.id_software, os.id_content
          FROM order_set os
         WHERE os.flg_status IN ('F', 'C') -- final version or cancelled
           AND EXISTS
         (SELECT 1
                  FROM order_set_task t
                 WHERE t.id_task_type IN (7, 8, 11) -- lab test, image and other exam type
                   AND t.id_order_set = os.id_order_set
                   AND EXISTS (SELECT 1
                          FROM order_set_task_link ostl
                         WHERE ostl.id_order_set_task = t.id_order_set_task
                           AND ostl.flg_task_link_type != pk_order_sets.g_task_link_predefined))
         ORDER BY os.id_order_set;

    l_prof_id           professional.id_professional%TYPE;
    l_prof              profissional;
    l_error             t_error_out;
    l_task_link         order_set_task_link.id_task_link%TYPE;
    l_order_set         order_set.id_order_set%TYPE;
    l_id_prev_order_set order_set.id_order_set%TYPE;
    l_sysdate           TIMESTAMP
        WITH LOCAL TIME ZONE := current_timestamp;

    FUNCTION migrate_lab_test_tasks
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_order_set IN order_set.id_order_set%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_nvalues table_number;
        l_vvalues table_varchar;
        l_dvalues table_varchar;
    
        l_analysis            table_number;
        l_analysis_group      table_table_number;
        l_flg_type            table_varchar; -- A - lab test; G - lab test group (panel)
        l_dt_req              table_varchar := table_varchar();
        l_flg_time            table_varchar := table_varchar();
        l_dt_begin            table_varchar := table_varchar();
        l_dt_begin_limit      table_varchar := table_varchar();
        l_episode_destination table_number := table_number();
        l_order_recurrence    table_number := table_number();
        l_priority            table_varchar := table_varchar();
        l_flg_prn             table_varchar := table_varchar();
        l_notes_prn           table_varchar := table_varchar();
        l_specimen            table_number := table_number();
        l_body_location       table_table_number := table_table_number();
        l_collection_room     table_number := table_number();
        l_notes               table_varchar := table_varchar();
        l_notes_tech          table_varchar := table_varchar();
        l_notes_patient       table_varchar := table_varchar();
        l_lab_req             table_number := table_number();
        l_exec_institution    table_number := table_number();
        l_clinical_purpose    table_varchar := table_varchar();
        l_flg_col_inst        table_varchar := table_varchar();
        l_flg_fasting         table_varchar := table_varchar();
        --l_diagnosis                table_clob := table_clob();
        l_codification             table_number := table_number();
        l_health_plan              table_number := table_number();
        l_prof_order               table_number := table_number();
        l_order_type               table_number := table_number();
        l_dt_order                 table_varchar := table_varchar();
        l_clinical_question        table_table_number := table_table_number();
        l_clinical_question_answer table_table_varchar := table_table_varchar();
        l_clinical_question_notes  table_table_varchar := table_table_varchar();
        l_clinical_decision_rule   table_number := table_number();
        l_task_dependency          table_number := table_number();
        l_flg_start_depending      table_varchar := table_varchar();
        l_episode_followup_app     table_number := table_number();
        l_schedule_followup_app    table_number := table_number();
        l_event_followup_app       table_number := table_number();
    
        l_flg_show                 VARCHAR2(200);
        l_msg_req                  VARCHAR2(200);
        l_msg_title                VARCHAR2(200);
        l_button                   VARCHAR2(200);
        l_req                      table_number;
        l_req_det                  table_number;
        l_req_param                table_number;
        l_order_set_tasks          t_tbl_odst_mig_link; -- table of t_rec_odst_mig_link
        l_order_set_task_links     t_tbl_odst_mig_link; -- table of t_rec_odst_mig_link
        l_lab_test_group           NUMBER(24);
        l_order_set_task_processed table_number := table_number();
        l_tasks_from_lab_group     table_number;
        l_lab_test_links_group     table_number;
        l_lab_test_link_type       order_set_task_link.flg_task_link_type%TYPE;
        l_lab                      NUMBER;
        l_spec                     NUMBER;
        l_count                    NUMBER;
    
        -- check if a item exists in collection
        FUNCTION item_exists
        (
            in_val IN NUMBER,
            in_tab IN table_number
        ) RETURN BOOLEAN IS
            l_val NUMBER(1);
        BEGIN
            SELECT 1
              INTO l_val
              FROM TABLE(in_tab)
             WHERE column_value = in_val;
            RETURN TRUE;
        EXCEPTION
            WHEN no_data_found THEN
                RETURN FALSE;
        END item_exists;
    
        -- get lab test group, if available
        FUNCTION get_lab_test_group
        (
            in_order_set_task IN order_set_task.id_order_set_task%TYPE,
            in_tab            IN t_tbl_odst_mig_link
        ) RETURN order_set_task_link.id_task_link%TYPE IS
            l_lab_test_group order_set_task_link.id_task_link%TYPE;
        BEGIN
            SELECT task_link
              INTO l_lab_test_group
              FROM TABLE(in_tab)
             WHERE task_link_type = pk_order_sets.g_task_link_group
               AND order_set_task = in_order_set_task;
            RETURN l_lab_test_group;
        
        EXCEPTION
            WHEN no_data_found THEN
                RETURN NULL;
        END get_lab_test_group;
    
        -- get all order set tasks from a lab test group or panel
        FUNCTION get_tasks_from_lab_group
        (
            in_lab_group IN order_set_task_link.id_task_link%TYPE,
            in_tab       IN t_tbl_odst_mig_link
        ) RETURN table_number IS
            l_order_set_tasks table_number;
        BEGIN
        
            SELECT order_set_task BULK COLLECT
              INTO l_order_set_tasks
              FROM TABLE(in_tab)
             WHERE task_link_type = pk_order_sets.g_task_link_group
               AND task_link = in_lab_group;
            RETURN l_order_set_tasks;
        
        END get_tasks_from_lab_group;
    
        -- get new lab test id and corresponding specimen/sample type
        PROCEDURE get_mig_lab_test
        (
            in_old_lab_test  IN analysis.id_analysis%TYPE,
            out_new_lab_test OUT analysis.id_analysis%TYPE,
            out_sample_type  OUT sample_type.id_sample_type%TYPE
        ) IS
        BEGIN
        
            BEGIN
            
                -- migrated lab tests
                SELECT id_analysis, id_sample_type
                  INTO out_new_lab_test, out_sample_type
                  FROM analysis_sample_type_mig
                 WHERE id_analysis_legacy = in_old_lab_test;
            
            EXCEPTION
                WHEN no_data_found THEN
                
                    -- not migrated lab tests
                    SELECT id_analysis, id_sample_type
                      INTO out_new_lab_test, out_sample_type
                      FROM analysis
                     WHERE id_analysis = in_old_lab_test;
            END;
        
        END get_mig_lab_test;
    
    BEGIN
    
        -- delete lab test tasks from new order set that are not configured for this environment  
        FOR rec IN (SELECT l.id_order_set_task, t.id_task_type, l.flg_task_link_type, l.id_task_link
                      FROM order_set_task t
                      JOIN order_set_task_link l
                        ON t.id_order_set_task = l.id_order_set_task
                     WHERE t.id_task_type = 11 -- lab test task type
                       AND l.flg_task_link_type =
                           pk_order_sets.get_odst_task_link_type(i_id_order_set_task => t.id_order_set_task)
                       AND l.flg_task_link_type != pk_order_sets.g_task_link_predefined
                       AND t.id_order_set = i_order_set)
        LOOP
        
            -- get new analysis id and spcimen id
            get_mig_lab_test(rec.id_task_link, l_lab, l_spec);
        
            -- check if lab test is configured
            SELECT COUNT(1)
              INTO l_count
              FROM analysis_instit_soft ais
             WHERE ais.id_analysis = l_lab
               AND ais.id_sample_type = l_spec
               AND ais.id_software = i_prof.software
               AND ais.id_institution = i_prof.institution
               AND ais.flg_available = pk_alert_constant.g_yes;
        
            -- if lab test is not configured, delete task from the new order set
            IF l_count = 0
            THEN
            
                DELETE order_set_task_detail
                 WHERE id_order_set_task = rec.id_order_set_task;
            
                DELETE order_set_task_dependency
                 WHERE id_order_set_task_from = rec.id_order_set_task
                    OR id_order_set_task_to = rec.id_order_set_task;
            
                DELETE FROM order_set_task_link
                 WHERE id_order_set_task = rec.id_order_set_task;
            
                DELETE FROM order_set_task
                 WHERE id_order_set_task = rec.id_order_set_task;
            
            END IF;
        
        END LOOP;
    
        -- get all lab test tasks from order set
        SELECT t_rec_odst_mig_link(l.id_order_set_task, t.id_task_type, l.flg_task_link_type, l.id_task_link) BULK COLLECT
          INTO l_order_set_tasks
          FROM order_set_task t
          JOIN order_set_task_link l
            ON t.id_order_set_task = l.id_order_set_task
         WHERE t.id_task_type = 11 -- lab test task type
           AND l.flg_task_link_type = pk_order_sets.get_odst_task_link_type(i_id_order_set_task => t.id_order_set_task)
           AND l.flg_task_link_type != pk_order_sets.g_task_link_predefined
           AND t.id_order_set = i_order_set;
    
        -- get all lab test task links from order set
        SELECT t_rec_odst_mig_link(l.id_order_set_task, t.id_task_type, l.flg_task_link_type, l.id_task_link) BULK COLLECT
          INTO l_order_set_task_links
          FROM order_set_task t
          JOIN order_set_task_link l
            ON t.id_order_set_task = l.id_order_set_task
         WHERE t.id_task_type = 11 -- lab test task type
           AND l.flg_task_link_type != pk_order_sets.g_task_link_predefined
           AND t.id_order_set = i_order_set;
    
        -- for each order set task
        FOR i IN 1 .. l_order_set_tasks.count
        LOOP
            -- check if this order_set_task was already processed
            IF NOT item_exists(l_order_set_tasks(i).order_set_task, l_order_set_task_processed)
            THEN
                -- check if lab test belongs to a group
                l_lab_test_group := get_lab_test_group(l_order_set_tasks(i).order_set_task, l_order_set_task_links);
            
                -- if lab test is isolated            
                IF l_lab_test_group IS NULL
                THEN
                    -- set type
                    l_flg_type := table_varchar('A'); -- lab test type
                
                    -- get lab test link
                    l_analysis := table_number(l_order_set_tasks(i).task_link);
                
                    -- get lab test group link (in this case is null)
                    l_analysis_group := table_table_number(table_number(NULL));
                
                    -- get specimen from analysis table
                    l_specimen.extend(1);
                    get_mig_lab_test(l_order_set_tasks(i).task_link, l_analysis(1), l_specimen(1));
                
                    -- add lab test to processed tasks array
                    l_order_set_task_processed.extend;
                    l_order_set_task_processed(l_order_set_task_processed.count) := l_order_set_tasks(i).order_set_task;
                ELSE
                    -- set type
                    l_flg_type := table_varchar('G'); -- lab test group type
                
                    -- get lab test link group
                    l_analysis := table_number(l_lab_test_group);
                
                    -- get all order set tasks from a lab group
                    l_tasks_from_lab_group := get_tasks_from_lab_group(l_lab_test_group, l_order_set_task_links);
                
                    -- get all lab test links associated with this group
                    SELECT task_link BULK COLLECT
                      INTO l_lab_test_links_group
                      FROM TABLE(l_order_set_tasks)
                     WHERE order_set_task IN (SELECT column_value
                                                FROM TABLE(l_tasks_from_lab_group));
                
                    -- set lab test group links             
                    l_analysis_group := table_table_number(l_lab_test_links_group);
                
                    -- get specimen from analysis table, for each lab test in group
                    l_specimen := table_number();
                    FOR j IN 1 .. l_lab_test_links_group.count
                    LOOP
                        -- get new analysis id and its specimen/sample type
                        l_specimen.extend;
                        get_mig_lab_test(l_lab_test_links_group(j), l_analysis_group(1) (j), l_specimen(j));
                    
                    END LOOP;
                
                    -- add lab (all in group) tests to processed tasks array
                    l_order_set_task_processed := l_order_set_task_processed MULTISET UNION l_tasks_from_lab_group;
                END IF;
            
                -- flg time
                l_flg_time := table_varchar(nvl(pk_order_sets.get_odst_task_det_val(i_lang                        => i_lang,
                                                                                    i_prof                        => i_prof,
                                                                                    i_id_order_set_task           => l_order_set_tasks(i)
                                                                                                                     .order_set_task,
                                                                                    i_flg_detail_type             => 'A',
                                                                                    i_id_advanced_input           => NULL,
                                                                                    i_id_advanced_input_field     => 95,
                                                                                    i_id_advanced_input_field_det => NULL),
                                                pk_alert_constant.g_flg_time_e));
            
                -- priority processing
                -- get urgency value
                l_priority := table_varchar(pk_order_sets.get_odst_task_det_val(i_lang                        => i_lang,
                                                                                i_prof                        => i_prof,
                                                                                i_id_order_set_task           => l_order_set_tasks(i)
                                                                                                                 .order_set_task,
                                                                                i_flg_detail_type             => 'A',
                                                                                i_id_advanced_input           => NULL,
                                                                                i_id_advanced_input_field     => 91,
                                                                                i_id_advanced_input_field_det => NULL));
                -- if the selected urgency value is "very urgent", then force value to "urgent"
                IF l_priority(1) = pk_alert_constant.g_task_priority_very_urgent
                THEN
                    l_priority(1) := pk_alert_constant.g_task_priority_urgent;
                END IF;
            
                -- notes
                l_notes := table_varchar(pk_order_sets.get_odst_task_det_val(i_lang                        => i_lang,
                                                                             i_prof                        => i_prof,
                                                                             i_id_order_set_task           => l_order_set_tasks(i)
                                                                                                              .order_set_task,
                                                                             i_flg_detail_type             => 'S',
                                                                             i_id_advanced_input           => NULL,
                                                                             i_id_advanced_input_field     => NULL,
                                                                             i_id_advanced_input_field_det => NULL));
                -- notes for technician
                l_notes_tech := table_varchar(pk_order_sets.get_odst_task_det_val(i_lang                        => i_lang,
                                                                                  i_prof                        => i_prof,
                                                                                  i_id_order_set_task           => l_order_set_tasks(i)
                                                                                                                   .order_set_task,
                                                                                  i_flg_detail_type             => 'T',
                                                                                  i_id_advanced_input           => NULL,
                                                                                  i_id_advanced_input_field     => NULL,
                                                                                  i_id_advanced_input_field_det => NULL));
                -- fasting
                l_flg_fasting := table_varchar(pk_order_sets.get_odst_task_det_val(i_lang                        => i_lang,
                                                                                   i_prof                        => i_prof,
                                                                                   i_id_order_set_task           => l_order_set_tasks(i)
                                                                                                                    .order_set_task,
                                                                                   i_flg_detail_type             => 'A',
                                                                                   i_id_advanced_input           => NULL,
                                                                                   i_id_advanced_input_field     => 92,
                                                                                   i_id_advanced_input_field_det => NULL));
            
                -- codification
                l_codification := table_number(NULL);
                BEGIN
                    -- get all lab test links associated with this group
                    SELECT task_link
                      INTO l_codification(1)
                      FROM TABLE(l_order_set_task_links)
                     WHERE order_set_task = l_order_set_tasks(i).order_set_task
                       AND task_link_type = pk_order_sets.g_task_link_codification;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_codification(1) := NULL;
                END;
            
                -- lab room and institution to be executed
                l_lab_req          := table_number(NULL);
                l_exec_institution := table_number(NULL);
            
                -- default or null valued arrays (not needed in migration) 
                --l_diagnosis                := table_clob(NULL);
                l_dt_req                   := table_varchar(NULL);
                l_dt_begin                 := table_varchar(NULL);
                l_dt_begin_limit           := table_varchar(NULL);
                l_episode_destination      := table_number(NULL);
                l_order_recurrence         := table_number(NULL);
                l_flg_prn                  := table_varchar(pk_alert_constant.g_no);
                l_notes_prn                := table_varchar(NULL);
                l_body_location            := table_table_number(table_number(NULL));
                l_collection_room          := table_number(NULL);
                l_notes_patient            := table_varchar(NULL);
                l_clinical_purpose         := table_varchar(NULL);
                l_flg_col_inst             := table_varchar(pk_order_sets.g_yes);
                l_health_plan              := table_number(NULL);
                l_prof_order               := table_number(NULL);
                l_order_type               := table_number(NULL);
                l_dt_order                 := table_varchar(NULL);
                l_clinical_question        := table_table_number(table_number(NULL));
                l_clinical_question_answer := table_table_varchar(table_varchar(NULL));
                l_clinical_question_notes  := table_table_varchar(table_varchar(NULL));
                l_clinical_decision_rule   := table_number(NULL);
                l_task_dependency          := table_number(NULL);
                l_flg_start_depending      := table_varchar(pk_alert_constant.g_no);
                l_episode_followup_app     := table_number(NULL);
                l_schedule_followup_app    := table_number(NULL);
                l_event_followup_app       := table_number(NULL);
            
                pk_alert_exceptions.reset_error_state;
            
                -- create predefined lab test task    
                IF NOT pk_lab_tests_api_db.create_lab_test_order(i_lang                    => i_lang,
                                                                 i_prof                    => i_prof,
                                                                 i_patient                 => NULL,
                                                                 i_episode                 => NULL,
                                                                 i_analysis_req            => NULL, -- 5
                                                                 i_analysis_req_det        => NULL,
                                                                 i_harvest                 => NULL,
                                                                 i_analysis                => l_analysis,
                                                                 i_analysis_group          => l_analysis_group,
                                                                 i_flg_type                => l_flg_type, -- 10
                                                                 i_dt_req                  => l_dt_req,
                                                                 i_flg_time                => l_flg_time,
                                                                 i_dt_begin                => l_dt_begin,
                                                                 i_dt_begin_limit          => l_dt_begin_limit,
                                                                 i_episode_destination     => l_episode_destination, -- 15
                                                                 i_order_recurrence        => l_order_recurrence,
                                                                 i_priority                => l_priority,
                                                                 i_flg_prn                 => l_flg_prn,
                                                                 i_notes_prn               => l_notes_prn,
                                                                 i_specimen                => l_specimen, -- 20
                                                                 i_body_location           => l_body_location,
                                                                 i_collection_room         => l_collection_room,
                                                                 i_notes                   => l_notes,
                                                                 i_notes_technician        => l_notes_tech,
                                                                 i_notes_patient           => l_notes_patient, -- 25
                                                                 i_diagnosis               => NULL, --l_diagnosis,
                                                                 i_exec_institution        => l_exec_institution,
                                                                 i_clinical_purpose        => l_clinical_purpose,
                                                                 i_flg_col_inst            => l_flg_col_inst,
                                                                 i_flg_fasting             => l_flg_fasting, -- 30
                                                                 i_lab_req                 => l_lab_req,
                                                                 i_codification            => l_codification,
                                                                 i_health_plan             => l_health_plan,
                                                                 i_prof_order              => l_prof_order,
                                                                 i_dt_order                => l_dt_order, -- 35
                                                                 i_order_type              => l_order_type,
                                                                 i_clinical_question       => l_clinical_question,
                                                                 i_response                => l_clinical_question_answer,
                                                                 i_clinical_question_notes => l_clinical_question_notes,
                                                                 i_clinical_decision_rule  => l_clinical_decision_rule, -- 40
                                                                 i_flg_origin_req          => pk_alert_constant.g_task_origin_order_set,
                                                                 i_task_dependency         => l_task_dependency,
                                                                 i_flg_task_depending      => l_flg_start_depending,
                                                                 i_episode_followup_app    => l_episode_followup_app,
                                                                 i_schedule_followup_app   => l_schedule_followup_app, -- 45
                                                                 i_event_followup_app      => l_event_followup_app,
                                                                 i_test                    => pk_alert_constant.g_no,
                                                                 o_flg_show                => l_flg_show,
                                                                 o_msg_title               => l_msg_title,
                                                                 o_msg_req                 => l_msg_req, -- 50
                                                                 o_button                  => l_button,
                                                                 o_analysis_req_array      => l_req,
                                                                 o_analysis_req_det_array  => l_req_det,
                                                                 o_analysis_req_par_array  => l_req_param,
                                                                 o_error                   => o_error) -- 55
                THEN
                    dbms_output.put_line('ERROR found while calling "pk_lab_tests_api_db.create_lab_test_order" for order set task [' || l_order_set_tasks(i)
                                         .order_set_task || ']: ' || chr(10) || o_error.ora_sqlcode || ' ' ||
                                         o_error.ora_sqlerrm || chr(10) || o_error.log_id);
                    RETURN FALSE; -- error! could not create predefined lab test task
                END IF;
            
                -- get lab test link type
                l_lab_test_link_type := pk_order_sets.get_odst_task_link_type(i_id_order_set_task => l_order_set_tasks(i)
                                                                                                     .order_set_task);
            
                -- if this is an isolated lab test
                IF l_lab_test_group IS NULL
                THEN
                    -- ## TASK LINKS ##
                    -- delete the links that will not be used from now on
                    DELETE order_set_task_link
                     WHERE id_order_set_task = l_order_set_tasks(i).order_set_task
                       AND flg_task_link_type != l_lab_test_link_type;
                
                    -- update order set task link with predefined lab request
                    UPDATE order_set_task_link
                       SET id_task_link = l_req(1), flg_task_link_type = pk_order_sets.g_task_link_predefined
                     WHERE id_order_set_task = l_order_set_tasks(i).order_set_task
                       AND flg_task_link_type = l_lab_test_link_type;
                
                    -- ## TASK DETAILS ##
                    -- delete all order set task details, except selected field
                    DELETE order_set_task_detail
                     WHERE id_order_set_task = l_order_set_tasks(i).order_set_task
                       AND id_advanced_input_field != pk_order_sets.g_adv_input_field_selected;
                
                    -- delete also all task dependencies in order_set_task_dependency
                    DELETE order_set_task_dependency
                     WHERE id_order_set_task_from = l_order_set_tasks(i).order_set_task
                        OR id_order_set_task_to = l_order_set_tasks(i).order_set_task;
                
                ELSE
                    -- ## TASK LINKS ##
                    -- delete the links that will not be used from now on
                    DELETE order_set_task_link
                     WHERE id_order_set_task = l_order_set_tasks(i).order_set_task
                       AND flg_task_link_type != l_lab_test_link_type;
                
                    -- delete all links from remain tasks that belongs to the same group
                    DELETE order_set_task_link
                     WHERE id_order_set_task IN
                           (SELECT /*+ opt_estimate(table tsk rows=1) */
                             column_value
                              FROM TABLE(l_tasks_from_lab_group) tsk
                             WHERE column_value != l_order_set_tasks(i).order_set_task);
                
                    -- update order set task link with predefined lab group request
                    UPDATE order_set_task_link
                       SET id_task_link = l_req(1), flg_task_link_type = pk_order_sets.g_task_link_predefined
                     WHERE id_order_set_task = l_order_set_tasks(i).order_set_task
                       AND flg_task_link_type = l_lab_test_link_type;
                
                    -- ## TASK DETAILS ##
                    -- delete all order set task details, except selected field for current lab test group task
                    DELETE order_set_task_detail
                     WHERE id_order_set_task IN
                           (SELECT /*+ opt_estimate(table tsk rows=1) */
                             column_value
                              FROM TABLE(l_tasks_from_lab_group) tsk
                             WHERE column_value != l_order_set_tasks(i).order_set_task)
                        OR (id_order_set_task = l_order_set_tasks(i).order_set_task AND
                           id_advanced_input_field != pk_order_sets.g_adv_input_field_selected);
                
                    -- delete also all task dependencies in order_set_task_dependency
                    DELETE order_set_task_dependency
                     WHERE id_order_set_task_from IN
                           (SELECT /*+ opt_estimate(table tsk rows=1) */
                             column_value
                              FROM TABLE(l_tasks_from_lab_group) tsk
                             WHERE column_value != l_order_set_tasks(i).order_set_task)
                        OR id_order_set_task_to IN
                           (SELECT /*+ opt_estimate(table tsk rows=1) */
                             column_value
                              FROM TABLE(l_tasks_from_lab_group) tsk
                             WHERE column_value != l_order_set_tasks(i).order_set_task);
                
                END IF;
            
            END IF;
        
            -- save logs with the migrated data
            INSERT INTO order_set_task_migration
                (id_order_set, id_order_set_task, id_task_type, task_link_type, id_task_link)
            VALUES
                (i_order_set,
                 l_order_set_tasks(i).order_set_task,
                 l_order_set_tasks(i).task_type,
                 l_order_set_tasks(i).task_link_type,
                 l_order_set_tasks(i).task_link);
        
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line('ERROR ' || SQLCODE || ' ' || SQLERRM);
            RETURN FALSE;
    END migrate_lab_test_tasks;

    FUNCTION migrate_exam_tasks
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_order_set IN order_set.id_order_set%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_nvalues table_number;
        l_vvalues table_varchar;
        l_dvalues table_varchar;
    
        l_exam                table_number;
        l_flg_type            table_varchar; -- A - exam; G - exam group (panel)
        l_dt_req              table_varchar := table_varchar();
        l_flg_time            table_varchar := table_varchar();
        l_dt_begin            table_varchar := table_varchar();
        l_dt_begin_limit      table_varchar := table_varchar();
        l_episode_destination table_number := table_number();
        l_order_recurrence    table_number := table_number();
        l_priority            table_varchar := table_varchar();
        l_flg_prn             table_varchar := table_varchar();
        l_notes_prn           table_varchar := table_varchar();
        l_notes               table_varchar := table_varchar();
        l_notes_tech          table_varchar := table_varchar();
        l_notes_patient       table_varchar := table_varchar();
        l_exec_room           table_number := table_number();
        l_exec_institution    table_number := table_number();
        l_clinical_purpose    table_varchar := table_varchar();
        l_flg_col_inst        table_varchar := table_varchar();
        l_flg_fasting         table_varchar := table_varchar();
        --l_diagnosis              table_clob := table_clob();
        l_codification             table_number := table_number();
        l_health_plan              table_number := table_number();
        l_prof_order               table_number := table_number();
        l_order_type               table_number := table_number();
        l_dt_order                 table_varchar := table_varchar();
        l_clinical_question        table_table_number := table_table_number();
        l_clinical_question_answer table_table_varchar := table_table_varchar();
        l_clinical_question_notes  table_table_varchar := table_table_varchar();
        l_clinical_decision_rule   table_number := table_number();
        l_task_dependency          table_number := table_number();
        l_flg_start_depending      table_varchar := table_varchar();
        l_episode_followup_app     table_number := table_number();
        l_schedule_followup_app    table_number := table_number();
        l_event_followup_app       table_number := table_number();
    
        l_flg_show        VARCHAR2(200);
        l_msg_req         VARCHAR2(200);
        l_msg_title       VARCHAR2(200);
        l_button          VARCHAR2(200);
        l_req             table_number;
        l_req_det         table_number;
        l_req_param       table_number;
        l_order_set_tasks t_tbl_odst_mig_link; -- table of t_rec_odst_mig_link
        l_exam_link_type  order_set_task_link.flg_task_link_type%TYPE;
    
    BEGIN
    
        -- get all exam tasks from order set
        SELECT t_rec_odst_mig_link(l.id_order_set_task, t.id_task_type, l.flg_task_link_type, l.id_task_link) BULK COLLECT
          INTO l_order_set_tasks
          FROM order_set_task t
          JOIN order_set_task_link l
            ON t.id_order_set_task = l.id_order_set_task
         WHERE t.id_task_type IN (7, 8) -- image and other exams task types
           AND l.flg_task_link_type = pk_order_sets.get_odst_task_link_type(i_id_order_set_task => t.id_order_set_task)
           AND l.flg_task_link_type != pk_order_sets.g_task_link_predefined
           AND t.id_order_set = i_order_set;
    
        -- for each order set task
        FOR i IN 1 .. l_order_set_tasks.count
        LOOP
            -- check if exam is a group or not    
            IF l_order_set_tasks(i).task_link_type != pk_order_sets.g_task_link_group
            THEN
            
                -- set type
                l_flg_type := table_varchar('E'); -- exam type
            
            ELSE
            
                -- set type
                l_flg_type := table_varchar('G'); -- exam group type
            
            END IF;
        
            -- get exam link
            l_exam := table_number(l_order_set_tasks(i).task_link);
        
            -- flg time
            l_flg_time := table_varchar(nvl(pk_order_sets.get_odst_task_det_val(i_lang                        => i_lang,
                                                                                i_prof                        => i_prof,
                                                                                i_id_order_set_task           => l_order_set_tasks(i)
                                                                                                                 .order_set_task,
                                                                                i_flg_detail_type             => 'A',
                                                                                i_id_advanced_input           => NULL,
                                                                                i_id_advanced_input_field     => 95,
                                                                                i_id_advanced_input_field_det => NULL),
                                            pk_alert_constant.g_flg_time_e));
        
            -- priority processing
            -- get urgency value
            l_priority := table_varchar(pk_order_sets.get_odst_task_det_val(i_lang                        => i_lang,
                                                                            i_prof                        => i_prof,
                                                                            i_id_order_set_task           => l_order_set_tasks(i)
                                                                                                             .order_set_task,
                                                                            i_flg_detail_type             => 'A',
                                                                            i_id_advanced_input           => NULL,
                                                                            i_id_advanced_input_field     => 91,
                                                                            i_id_advanced_input_field_det => NULL));
            -- if the selected urgency value is "very urgent", then force value to "urgent"
            IF l_priority(1) = pk_alert_constant.g_task_priority_very_urgent
            THEN
                l_priority(1) := pk_alert_constant.g_task_priority_urgent;
            END IF;
        
            -- notes
            l_notes := table_varchar(pk_order_sets.get_odst_task_det_val(i_lang                        => i_lang,
                                                                         i_prof                        => i_prof,
                                                                         i_id_order_set_task           => l_order_set_tasks(i)
                                                                                                          .order_set_task,
                                                                         i_flg_detail_type             => 'S',
                                                                         i_id_advanced_input           => NULL,
                                                                         i_id_advanced_input_field     => NULL,
                                                                         i_id_advanced_input_field_det => NULL));
            -- notes for technician
            l_notes_tech := table_varchar(pk_order_sets.get_odst_task_det_val(i_lang                        => i_lang,
                                                                              i_prof                        => i_prof,
                                                                              i_id_order_set_task           => l_order_set_tasks(i)
                                                                                                               .order_set_task,
                                                                              i_flg_detail_type             => 'T',
                                                                              i_id_advanced_input           => NULL,
                                                                              i_id_advanced_input_field     => NULL,
                                                                              i_id_advanced_input_field_det => NULL));
            -- fasting
            l_flg_fasting := table_varchar(pk_order_sets.get_odst_task_det_val(i_lang                        => i_lang,
                                                                               i_prof                        => i_prof,
                                                                               i_id_order_set_task           => l_order_set_tasks(i)
                                                                                                                .order_set_task,
                                                                               i_flg_detail_type             => 'A',
                                                                               i_id_advanced_input           => NULL,
                                                                               i_id_advanced_input_field     => 92,
                                                                               i_id_advanced_input_field_det => NULL));
            -- codification
            l_codification := table_number(NULL);
            BEGIN
                -- get all lab test links associated with this group
                SELECT task_link
                  INTO l_codification(1)
                  FROM TABLE(l_order_set_tasks)
                 WHERE order_set_task = l_order_set_tasks(i).order_set_task
                   AND task_link_type = pk_order_sets.g_task_link_codification;
            EXCEPTION
                WHEN no_data_found THEN
                    l_codification(1) := NULL;
            END;
        
            -- exam room and institution to be executed
            l_exec_room        := table_number(NULL);
            l_exec_institution := table_number(NULL);
        
            -- default or null valued arrays (not needed in migration) 
            --l_diagnosis                := table_clob(NULL);
            l_dt_req                   := table_varchar(NULL);
            l_dt_begin                 := table_varchar(NULL);
            l_dt_begin_limit           := table_varchar(NULL);
            l_episode_destination      := table_number(NULL);
            l_order_recurrence         := table_number(NULL);
            l_flg_prn                  := table_varchar(pk_alert_constant.g_no);
            l_notes_prn                := table_varchar(NULL);
            l_notes_patient            := table_varchar(NULL);
            l_clinical_purpose         := table_varchar(NULL);
            l_flg_col_inst             := table_varchar(pk_order_sets.g_yes);
            l_health_plan              := table_number(NULL);
            l_prof_order               := table_number(NULL);
            l_order_type               := table_number(NULL);
            l_dt_order                 := table_varchar(NULL);
            l_clinical_question        := table_table_number(table_number(NULL));
            l_clinical_question_answer := table_table_varchar(table_varchar(NULL));
            l_clinical_question_notes  := table_table_varchar(table_varchar(NULL));
            l_clinical_decision_rule   := table_number(NULL);
            l_task_dependency          := table_number(NULL);
            l_flg_start_depending      := table_varchar(pk_alert_constant.g_no);
            l_episode_followup_app     := table_number(NULL);
            l_schedule_followup_app    := table_number(NULL);
            l_event_followup_app       := table_number(NULL);
        
            pk_alert_exceptions.reset_error_state;
        
            -- create predefined exam task    
            IF NOT pk_exams_api_db.create_exam_order(i_lang                    => i_lang,
                                                     i_prof                    => i_prof,
                                                     i_patient                 => NULL,
                                                     i_episode                 => NULL,
                                                     i_exam_req                => NULL,
                                                     i_exam_req_det            => NULL,
                                                     i_exam                    => l_exam,
                                                     i_flg_type                => l_flg_type,
                                                     i_dt_req                  => l_dt_req,
                                                     i_flg_time                => l_flg_time,
                                                     i_dt_begin                => l_dt_begin,
                                                     i_dt_begin_limit          => l_dt_begin_limit,
                                                     i_episode_destination     => l_episode_destination,
                                                     i_order_recurrence        => l_order_recurrence,
                                                     i_priority                => l_priority,
                                                     i_flg_prn                 => l_flg_prn,
                                                     i_notes_prn               => l_notes_prn,
                                                     i_flg_fasting             => l_flg_fasting,
                                                     i_notes                   => l_notes,
                                                     i_notes_technician        => l_notes_tech,
                                                     i_notes_patient           => l_notes_patient,
                                                     i_diagnosis               => NULL, --l_diagnosis,
                                                     i_exec_room               => l_exec_room,
                                                     i_exec_institution        => l_exec_institution,
                                                     i_clinical_purpose        => l_clinical_purpose,
                                                     i_codification            => l_codification,
                                                     i_health_plan             => l_health_plan,
                                                     i_prof_order              => l_prof_order,
                                                     i_dt_order                => l_dt_order,
                                                     i_order_type              => l_order_type,
                                                     i_clinical_question       => l_clinical_question,
                                                     i_response                => l_clinical_question_answer,
                                                     i_clinical_question_notes => l_clinical_question_notes,
                                                     i_clinical_decision_rule  => l_clinical_decision_rule,
                                                     i_flg_origin_req          => pk_alert_constant.g_task_origin_order_set,
                                                     i_task_dependency         => l_task_dependency,
                                                     i_flg_task_depending      => l_flg_start_depending,
                                                     i_episode_followup_app    => l_episode_followup_app,
                                                     i_schedule_followup_app   => l_schedule_followup_app,
                                                     i_event_followup_app      => l_event_followup_app,
                                                     i_test                    => pk_alert_constant.g_no,
                                                     o_flg_show                => l_flg_show,
                                                     o_msg_title               => l_msg_title,
                                                     o_msg_req                 => l_msg_req,
                                                     o_button                  => l_button,
                                                     o_exam_req_array          => l_req,
                                                     o_exam_req_det_array      => l_req_det,
                                                     o_error                   => o_error)
            THEN
                dbms_output.put_line('ERROR found while calling "pk_exams_api_db.create_exam_order" for order set task [' || l_order_set_tasks(i)
                                     .order_set_task || ']: ' || chr(10) || o_error.ora_sqlcode || ' ' ||
                                     o_error.ora_sqlerrm || chr(10) || o_error.log_id);
                RETURN FALSE; -- error! could not create predefined exam task
            END IF;
        
            -- get exam link type
            l_exam_link_type := pk_order_sets.get_odst_task_link_type(i_id_order_set_task => l_order_set_tasks(i)
                                                                                             .order_set_task);
        
            -- ## TASK LINKS ##
            -- delete the links that will not be used from now on
            DELETE order_set_task_link
             WHERE id_order_set_task = l_order_set_tasks(i).order_set_task
               AND flg_task_link_type != l_exam_link_type;
        
            -- update order set task link with predefined lab request
            UPDATE order_set_task_link
               SET id_task_link = l_req(1), flg_task_link_type = pk_order_sets.g_task_link_predefined
             WHERE id_order_set_task = l_order_set_tasks(i).order_set_task
               AND flg_task_link_type = l_exam_link_type;
        
            -- ## TASK DETAILS ##
            -- delete all order set task details, except selected field
            DELETE order_set_task_detail
             WHERE id_order_set_task = l_order_set_tasks(i).order_set_task
               AND id_advanced_input_field != pk_order_sets.g_adv_input_field_selected;
        
            -- delete also all task dependencies in order_set_task_dependency
            DELETE order_set_task_dependency
             WHERE id_order_set_task_from = l_order_set_tasks(i).order_set_task
                OR id_order_set_task_to = l_order_set_tasks(i).order_set_task;
        
            -- save logs with the migrated data
            INSERT INTO order_set_task_migration
                (id_order_set, id_order_set_task, id_task_type, task_link_type, id_task_link)
            VALUES
                (i_order_set,
                 l_order_set_tasks(i).order_set_task,
                 l_order_set_tasks(i).task_type,
                 l_order_set_tasks(i).task_link_type,
                 l_order_set_tasks(i).task_link);
        
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line('ERROR ' || SQLCODE || ' ' || SQLERRM);
            RETURN FALSE;
    END migrate_exam_tasks;

    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN

    -- get all order sets with labs, image and other exams
    FOR os_rec IN c_odst_with_labs_and_exams
    LOOP
    
        dbms_output.put_line('Processing order set "' || os_rec.title || '" [id_content=' || os_rec.id_content ||
                             ', id_order_set=' || os_rec.id_order_set || '] for professional [prof=' ||
                             os_rec.id_professional || ', inst=' || os_rec.id_institution || ', soft=' ||
                             os_rec.id_software || ']...');
    
        -- check if we can user order set's professional                            
        IF os_rec.id_professional IS NULL
        THEN
            -- if not, then get system professional id
            l_prof_id := pk_sysconfig.get_config(i_code_cf   => 'ID_PROF_BACKGROUND',
                                                 i_prof_inst => os_rec.id_institution,
                                                 i_prof_soft => os_rec.id_software);
            dbms_output.put_line('id_professional retrieved from ID_PROF_BACKGROUND sys_config is ' || l_prof_id);
        ELSE
            l_prof_id := os_rec.id_professional;
        END IF;
        l_prof := profissional(l_prof_id, os_rec.id_institution, os_rec.id_software);
    
        -- create new version of order set
        pk_alert_exceptions.reset_error_state;
        IF NOT pk_order_sets.create_order_set(i_lang          => 2,
                                              i_prof          => l_prof,
                                              i_id_order_set  => os_rec.id_order_set,
                                              i_flg_duplicate => 'N',
                                              o_id_order_set  => l_order_set,
                                              o_error         => l_error)
        THEN
            dbms_output.put_line('ERROR found while editing order set [' || os_rec.id_order_set || ']: ' || chr(10) ||
                                 l_error.ora_sqlcode || ' ' || l_error.ora_sqlerrm || chr(10) || l_error.log_id);
            continue;
        ELSE
            dbms_output.put_line('Temporary order set [' || l_order_set || '] created from [' || os_rec.id_order_set || ']');
        
            -- call lab tests migration function    
            IF NOT migrate_lab_test_tasks(i_lang => 2, i_prof => l_prof, i_order_set => l_order_set, o_error => l_error)
            THEN
                dbms_output.put_line('ERROR found while migrating lab tests from order set [' || l_order_set || ']: ' ||
                                     chr(10) || l_error.ora_sqlcode || ' ' || l_error.ora_sqlerrm || chr(10) ||
                                     l_error.log_id);
            
                ROLLBACK;
            
                pk_alert_exceptions.reset_error_state;
                IF NOT pk_order_sets.cancel_order_set(2, l_prof, l_order_set, l_error)
                THEN
                    dbms_output.put_line('ERROR while calling pk_order_sets.cancel_order_set function [id_order_set = ' ||
                                         l_order_set || ']: ' || chr(10) || l_error.ora_sqlcode || ' ' ||
                                         l_error.ora_sqlerrm || chr(10) || l_error.log_id);
                END IF;
            
                continue;
            END IF;
        
            -- call exams migration function
            IF NOT migrate_exam_tasks(i_lang => 2, i_prof => l_prof, i_order_set => l_order_set, o_error => l_error)
            THEN
                dbms_output.put_line('ERROR found while migrating exams from order set [' || l_order_set || ']: ' ||
                                     chr(10) || l_error.ora_sqlcode || ' ' || l_error.ora_sqlerrm || chr(10) ||
                                     l_error.log_id);
            
                ROLLBACK;
            
                pk_alert_exceptions.reset_error_state;
                IF NOT pk_order_sets.cancel_order_set(2, l_prof, l_order_set, l_error)
                THEN
                    dbms_output.put_line('ERROR while calling pk_order_sets.cancel_order_set function [id_order_set = ' ||
                                         l_order_set || ']: ' || chr(10) || l_error.ora_sqlcode || ' ' ||
                                         l_error.ora_sqlerrm || chr(10) || l_error.log_id);
                END IF;
            
                continue;
            END IF;
        
            BEGIN
            
                -- set the order set with the same status of its previous version (finished or cancelled)
                UPDATE order_set odst
                   SET odst.flg_status       =
                       (SELECT flg_status
                          FROM order_set prev_odst
                         WHERE prev_odst.id_order_set = odst.id_order_set_previous_version),
                       odst.dt_order_set_tstz = l_sysdate
                 WHERE odst.id_order_set = l_order_set
                   AND odst.flg_status = pk_order_sets.g_order_set_temp
                RETURNING odst.id_order_set_previous_version INTO l_id_prev_order_set;
            
                -- update order set ID on order_set_frequent table
                UPDATE order_set_frequent
                   SET id_order_set = l_order_set
                 WHERE id_order_set = nvl(l_id_prev_order_set, -1);
            
                -- update status of the previous order set
                UPDATE order_set
                   SET flg_status     = pk_order_sets.g_order_set_deprecated,
                       id_prof_cancel = l_prof.id,
                       dt_cancel_tstz = l_sysdate
                 WHERE id_order_set = nvl(l_id_prev_order_set, -1)
                   AND flg_status IN (pk_order_sets.g_order_set_finished, pk_order_sets.g_order_set_deleted);
            
                COMMIT;
            
            EXCEPTION
                WHEN OTHERS THEN
                
                    dbms_output.put_line('ERROR while setting temporary order set [id_order_set=' || l_order_set ||
                                         '] to final state');
                    ROLLBACK;
            END;
        END IF;
    END LOOP;

END;
/
-- CHANGE END: Tiago Silva
