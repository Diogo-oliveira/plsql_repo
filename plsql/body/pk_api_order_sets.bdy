/*-- Last Change Revision: $Rev: 2055402 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2023-02-22 09:44:22 +0000 (qua, 22 fev 2023) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_order_sets IS

    -- Author  : Carlos Loureiro
    -- Purpose : API for order sets

    /********************************************************************************************
    * Returns the order set title of an order set task
    *
    * @param    I_LANG            Preferred language ID
    * @param    I_PROF            Object (ID of professional, ID of institution, ID of software)
    * @param    I_ID_ORDER_SET    Order set ID
    *
    * @return   VARCHAR2          Order set title
    *
    * @author   Tiago Silva
    * @since    2010/06/30
    ********************************************************************************************/
    FUNCTION get_order_set_title
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN order_set_process_task.id_request%TYPE,
        i_task_type    IN order_set_process_task.id_task_type%TYPE
    ) RETURN VARCHAR2 IS
        l_title order_set.title%TYPE;
    BEGIN
    
        g_error := 'GET ORDER SET TITLE';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        SELECT odst.title
          INTO l_title
          FROM order_set odst
         INNER JOIN order_set_process odst_proc
            ON odst.id_order_set = odst_proc.id_order_set
         INNER JOIN order_set_process_task odst_proc_tsk
            ON odst_proc.id_order_set_process = odst_proc_tsk.id_order_set_process
         WHERE odst_proc_tsk.id_request = i_task_request
           AND odst_proc_tsk.id_task_type = i_task_type;
    
        RETURN l_title;
    
    END get_order_set_title;

    /********************************************************************************************
    * updates diet references in all order sets that were using a diet that is about to be updated
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional structure
    * @param       i_diet_old                diet that is about to be updated
    * @param       i_diet_new                final diet version
    * @param       o_error                   error message
    *
    * @return      boolean                   true or false on success or error
    *
    * @author                                Carlos Loureiro
    * @version                               1.0
    * @since                                 2009/07/16
    ********************************************************************************************/
    FUNCTION set_diet_references
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_diet_old IN order_set_task_link.id_task_link%TYPE,
        i_diet_new IN order_set_task_link.id_task_link%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'UPDATE DIET REFERENCES IN ORDER SETS';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- update id_task_link for i_diet_old in all orders sets that are finished or in edition (temporary) for all diet tasks
        UPDATE order_set_task_link
           SET id_task_link = i_diet_new
         WHERE id_task_link = i_diet_old
           AND id_order_set_task IN
               (SELECT ost.id_order_set_task
                  FROM order_set_task ost
                  JOIN order_set os
                    ON os.id_order_set = ost.id_order_set
                 WHERE ost.id_task_type = pk_order_sets.g_odst_task_predef_diet
                   AND os.flg_status IN (pk_order_sets.g_order_set_finished, pk_order_sets.g_order_set_temp));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_DIET_REFERENCES',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_diet_references;

    /********************************************************************************************
    * updates diet references for the order set process that is handling the diet
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional structure
    * @param       i_id_epis_diet_old        patient's diet that is about to be updated
    * @param       i_id_epis_diet_new        final diet version to be associated to the patient
    * @param       o_error                   error message
    *
    * @return      boolean                   true or false on success or error
    *
    * @author                                Carlos Loureiro
    * @version                               1.0
    * @since                                 2009/07/23
    ********************************************************************************************/
    FUNCTION set_diet_process_references
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_epis_diet_old IN order_set_process_task.id_request%TYPE,
        i_id_epis_diet_new IN order_set_process_task.id_request%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'UPDATE DIET REFERENCES IN ORDER SET PROCESS';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- update id_request for i_id_epis_diet_old to enable the new id_request
        UPDATE order_set_process_task
           SET id_request = i_id_epis_diet_new
         WHERE id_request = i_id_epis_diet_old
           AND id_task_type = pk_order_sets.g_odst_task_predef_diet;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_DIET_REFERENCES',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_diet_process_references;

    /********************************************************************************************
    * Copy or duplicate order set
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    object (id of professional, id of institution, id of software)
    * @param       i_target_id_institution   target institution id
    * @param       i_id_order set            source order set id
    * @param       o_order_set               new order set id
    * @param       o_error                   error message
    *
    * @return      boolean                   true or false on success or error
    *
    * @author                                Tiago Silva
    * @version                               1.0
    * @since                                 2009/07/17
    ********************************************************************************************/
    FUNCTION copy_order_set
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_target_id_institution IN institution.id_institution%TYPE,
        i_id_order_set          IN order_set.id_order_set%TYPE,
        o_order_set             OUT order_set.id_order_set%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_result  BOOLEAN;
        l_odst_sw order_set.id_software%TYPE;
    
        e_undefined_error EXCEPTION;
    
    BEGIN
    
        -- use order set software id as input for calling the next function
        SELECT odst.id_software
          INTO l_odst_sw
          FROM order_set odst
         WHERE odst.id_order_set = i_id_order_set;
    
        -- duplicating order set based on source order set id   
        g_error := 'COPYING ORDER SET';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        l_result := pk_order_sets.create_order_set(i_lang,
                                                   profissional(i_prof.id, i_target_id_institution, l_odst_sw),
                                                   i_id_order_set,
                                                   g_duplicate_flag,
                                                   o_order_set,
                                                   o_error);
    
        IF l_result = TRUE
        THEN
            -- setting target order_set id        
            g_error := 'SETTING ORDER SET';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            l_result := pk_order_sets.set_order_set(i_lang, i_prof, o_order_set, o_error);
        
            IF l_result = TRUE
            THEN
                RETURN TRUE;
            END IF;
        END IF;
    
        RAISE e_undefined_error;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'COPY_ORDER_SET',
                                              o_error);
            -- return failure of function
            RETURN FALSE;
        
    END copy_order_set;

    /********************************************************************************************
    * Cancel order set / mark as deleted
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    object (id of professional, id of institution, id of software)
    * @param       i_id_order_set            order set id to cancel
    * @param       o_error                   error message
    *
    * @return      boolean                   true or false on success or error
    *
    * @author                                Tiago Silva
    * @version                               1.0
    * @since                                 2009/07/17
    ********************************************************************************************/
    FUNCTION cancel_order_set
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_order_set IN order_set.id_order_set%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_result BOOLEAN;
        e_undefined_error EXCEPTION;
    
    BEGIN
        -- cancel order set by order set id   
        g_error := 'CANCEL PROTOCOL';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        l_result := pk_order_sets.cancel_order_set(i_lang, i_prof, i_id_order_set, NULL, NULL, o_error);
    
        IF l_result = FALSE
        THEN
            RAISE e_undefined_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_ORDER_SET',
                                              o_error);
            -- return failure of function
            RETURN FALSE;
        
    END cancel_order_set;

    /********************************************************************************************
    * clear particular order set processes or clear all order sets processes related with
    * a list of patients or order sets
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_patients                patients array
    * @param       i_order_sets              order sets array    
    * @param       i_order_set_processes     order set processes array         
    * @param       o_error                   error message
    *        
    * @return      boolean                   true on success, otherwise false    
    *   
    * @author                                Tiago Silva
    * @since                                 2010/11/02
    ********************************************************************************************/
    FUNCTION clear_order_set_processes
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_patients            IN table_number DEFAULT NULL,
        i_order_sets          IN table_number DEFAULT NULL,
        i_order_set_processes IN table_number DEFAULT NULL,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_odst IS
            SELECT osp.id_order_set_process
              FROM order_set_process osp
             WHERE osp.id_patient IN (SELECT /*+ OPT_ESTIMATE(table pat rows = 1)*/
                                       column_value AS VALUE
                                        FROM TABLE(i_patients) pat)
                OR osp.id_order_set IN (SELECT /*+ OPT_ESTIMATE(table odsts rows = 1)*/
                                         column_value AS VALUE
                                          FROM TABLE(i_order_sets) odsts)
                OR osp.id_order_set_process IN
                   (SELECT /*+ OPT_ESTIMATE(table odst_procs rows = 1)*/
                     column_value AS VALUE
                      FROM TABLE(i_order_set_processes) odst_procs);
    
        l_order_set_processes table_number;
    
    BEGIN
    
        g_error := 'CLEAR ORDER SET PROCESSES';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        g_error := 'GET ALL ORDER SET PROCESSES TO REMOVE';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        OPEN c_odst;
        FETCH c_odst BULK COLLECT
            INTO l_order_set_processes;
        CLOSE c_odst;
    
        g_error := 'DEL ORDER_SET_PROCESS_TASK_DET';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        FORALL i IN 1 .. l_order_set_processes.last
            DELETE order_set_process_task_det osptd
             WHERE osptd.id_order_set_process_task IN
                   (SELECT ospt.id_order_set_process_task
                      FROM order_set_process_task ospt
                     WHERE ospt.id_order_set_process = l_order_set_processes(i));
    
        g_error := 'DEL ORDER_SET_PROCESS_TASK_LINK';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        FORALL i IN 1 .. l_order_set_processes.last
            DELETE order_set_process_task_link osptl
             WHERE osptl.id_order_set_process_task IN
                   (SELECT ospt.id_order_set_process_task
                      FROM order_set_process_task ospt
                     WHERE ospt.id_order_set_process = l_order_set_processes(i));
    
        g_error := 'DEL ORDER_SET_PROCESS_TASK_DEPEND';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        FORALL i IN 1 .. l_order_set_processes.last
            DELETE order_set_process_task_depend osptd
             WHERE osptd.id_order_set_process = l_order_set_processes(i);
    
        g_error := 'DEL ORDER_SET_PROCESS_TASK';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        FORALL i IN 1 .. l_order_set_processes.last
            DELETE FROM order_set_process_task ospt
             WHERE ospt.id_order_set_process = l_order_set_processes(i);
    
        g_error := 'DEL ORDER_SET_PROCESS';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        FORALL i IN 1 .. l_order_set_processes.last
            DELETE FROM order_set_process gp
             WHERE gp.id_order_set_process = l_order_set_processes(i);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CLEAR_ORDER_SET_PROCESSES',
                                              o_error);
            RETURN FALSE;
    END clear_order_set_processes;

    /********************************************************************************************
    * delete a list of order sets and its processes
    *
    * @param       i_lang         preferred language id for this professional
    * @param       i_prof         professional id structure
    * @param       i_order_sets   order set IDs
    * @param       o_error        error message
    *        
    * @return      boolean        true on success, otherwise false    
    *   
    * @author                     Tiago Silva
    * @since                      2010/11/02
    ********************************************************************************************/
    FUNCTION delete_order_sets
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_order_sets IN table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
    
    BEGIN
    
        g_error := 'DELETE ORDER SETS';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- deprecate order sets (order sets shouldn't be deleted)
        UPDATE order_set
           SET flg_status = pk_order_sets.g_order_set_deprecated
         WHERE id_order_set IN (SELECT /*+ OPT_ESTIMATE(table odsts rows = 1)*/
                                 column_value AS VALUE
                                  FROM TABLE(i_order_sets) odsts);
    
        -- clear all order sets processes related with these order sets
        IF NOT clear_order_set_processes(i_lang       => i_lang,
                                         i_prof       => i_prof,
                                         i_order_sets => i_order_sets,
                                         o_error      => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DELETE_ORDER_SETS',
                                              o_error);
            RETURN FALSE;
    END delete_order_sets;

    /********************************************************************************************
    * update new task reference in all order sets that are using the old reference
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional structure
    * @param       i_task_type               task type id
    * @param       i_task_ref_old            old task reference (the one that should be updated)
    * @param       i_task_ref_new            new task reference
    * @param       o_error                   error message
    *
    * @return      boolean                   true or false on success or error
    *
    * @author                                Carlos Loureiro
    * @since                                 19-SEP-2011
    ********************************************************************************************/
    FUNCTION update_task_reference
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_type    IN task_type.id_task_type%TYPE,
        i_task_ref_old IN order_set_task_link.id_task_link%TYPE,
        i_task_ref_new IN order_set_task_link.id_task_link%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
        -- call pk_order_sets.update_task_proc_reference function
        IF NOT pk_order_sets.update_task_reference(i_lang         => i_lang,
                                                   i_prof         => i_prof,
                                                   i_task_type    => i_task_type,
                                                   i_task_ref_old => i_task_ref_old,
                                                   i_task_ref_new => i_task_ref_new,
                                                   o_error        => o_error)
        THEN
            g_error := 'error found while calling pk_order_sets.update_task_reference function';
            RAISE l_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'UPDATE_TASK_REFERENCE',
                                              o_error);
            RETURN FALSE;
    END update_task_reference;

    /********************************************************************************************
    * update new task process reference in all order set processes that are using the old reference
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional structure
    * @param       i_task_type               task type id
    * @param       i_task_ref_old            old task reference (the one that should be updated)
    * @param       i_task_ref_new            new task reference
    * @param       o_error                   error message
    *
    * @return      boolean                   true or false on success or error
    *
    * @author                                Carlos Loureiro
    * @since                                 19-SEP-2011
    ********************************************************************************************/
    FUNCTION update_task_proc_reference
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_type    IN task_type.id_task_type%TYPE,
        i_task_ref_old IN order_set_task_link.id_task_link%TYPE,
        i_task_ref_new IN order_set_task_link.id_task_link%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
        -- call pk_order_sets.update_task_proc_reference function
        IF NOT pk_order_sets.update_task_proc_reference(i_lang         => i_lang,
                                                        i_prof         => i_prof,
                                                        i_task_type    => i_task_type,
                                                        i_task_ref_old => i_task_ref_old,
                                                        i_task_ref_new => i_task_ref_new,
                                                        o_error        => o_error)
        THEN
            g_error := 'error found while calling pk_order_sets.update_task_proc_reference function';
            RAISE l_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'UPDATE_TASK_PROC_REFERENCE',
                                              o_error);
            RETURN FALSE;
    END update_task_proc_reference;

    /********************************************************************************************
    * migrate labs and exams tasks to modular workflow task architecture
    *
    * @param       i_instit   institution ID
    *
    * @author                 Tiago Silva
    * @since                  27-NOV-2013
    ********************************************************************************************/
    PROCEDURE migrate_labs_and_exams(i_instit IN institution.id_institution%TYPE) IS
    
        -- cursor to get all order ses with labs, image and other exams
        CURSOR c_odst_with_labs_and_exams IS
            SELECT os.id_order_set, os.title, os.id_professional, os.id_institution, os.id_software, os.id_content
              FROM order_set os
             WHERE os.flg_status IN ('F', 'C') -- final version or cancelled
               AND os.id_institution = i_instit
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
        l_sysdate           TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
    
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
        
            l_analysis               table_number;
            l_analysis_group         table_table_varchar;
            l_flg_type               table_varchar; -- A - lab test; G - lab test group (panel)
            l_dt_req                 table_varchar := table_varchar();
            l_flg_time               table_varchar := table_varchar();
            l_dt_begin               table_varchar := table_varchar();
            l_dt_begin_limit         table_varchar := table_varchar();
            l_episode_destination    table_number := table_number();
            l_order_recurrence       table_number := table_number();
            l_priority               table_varchar := table_varchar();
            l_flg_prn                table_varchar := table_varchar();
            l_notes_prn              table_varchar := table_varchar();
            l_specimen               table_number := table_number();
            l_body_location          table_table_number := table_table_number();
            l_laterality             table_table_varchar := table_table_varchar();
            l_collection_room        table_number := table_number();
            l_notes                  table_varchar := table_varchar();
            l_notes_scheduler        table_varchar := table_varchar();
            l_notes_tech             table_varchar := table_varchar();
            l_notes_patient          table_varchar := table_varchar();
            l_diagnosis_notes        table_varchar := table_varchar();
            l_lab_req                table_number := table_number();
            l_prof_cc                table_table_varchar := table_table_varchar();
            l_prof_bcc               table_table_varchar := table_table_varchar();
            l_exec_institution       table_number := table_number();
            l_clinical_purpose       table_number := table_number();
            l_clinical_purpose_notes table_varchar := table_varchar();
            l_flg_col_inst           table_varchar := table_varchar();
            l_flg_fasting            table_varchar := table_varchar();
            --l_diagnosis                table_clob := table_clob();
            l_codification             table_number := table_number();
            l_health_plan              table_number := table_number();
            l_exemption                table_number := table_number();
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
            l_lab_test_links_group     table_varchar;
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
            
                SELECT order_set_task
                  BULK COLLECT
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
            SELECT t_rec_odst_mig_link(l.id_order_set_task, t.id_task_type, l.flg_task_link_type, l.id_task_link)
              BULK COLLECT
              INTO l_order_set_tasks
              FROM order_set_task t
              JOIN order_set_task_link l
                ON t.id_order_set_task = l.id_order_set_task
             WHERE t.id_task_type = 11 -- lab test task type
               AND l.flg_task_link_type =
                   pk_order_sets.get_odst_task_link_type(i_id_order_set_task => t.id_order_set_task)
               AND l.flg_task_link_type != pk_order_sets.g_task_link_predefined
               AND t.id_order_set = i_order_set;
        
            -- get all lab test task links from order set
            SELECT t_rec_odst_mig_link(l.id_order_set_task, t.id_task_type, l.flg_task_link_type, l.id_task_link)
              BULK COLLECT
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
                        l_analysis_group := table_table_varchar(table_varchar(NULL));
                    
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
                        SELECT task_link
                          BULK COLLECT
                          INTO l_lab_test_links_group
                          FROM TABLE(l_order_set_tasks)
                         WHERE order_set_task IN (SELECT column_value
                                                    FROM TABLE(l_tasks_from_lab_group));
                    
                        -- set lab test group links             
                        l_analysis_group := table_table_varchar(l_lab_test_links_group);
                    
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
                                                                                        i_id_order_set_task           => l_order_set_tasks(i).order_set_task,
                                                                                        i_flg_detail_type             => 'A',
                                                                                        i_id_advanced_input           => NULL,
                                                                                        i_id_advanced_input_field     => 95,
                                                                                        i_id_advanced_input_field_det => NULL),
                                                    pk_alert_constant.g_flg_time_e));
                
                    -- priority processing
                    -- get urgency value
                    l_priority := table_varchar(pk_order_sets.get_odst_task_det_val(i_lang                        => i_lang,
                                                                                    i_prof                        => i_prof,
                                                                                    i_id_order_set_task           => l_order_set_tasks(i).order_set_task,
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
                                                                                 i_id_order_set_task           => l_order_set_tasks(i).order_set_task,
                                                                                 i_flg_detail_type             => 'S',
                                                                                 i_id_advanced_input           => NULL,
                                                                                 i_id_advanced_input_field     => NULL,
                                                                                 i_id_advanced_input_field_det => NULL));
                    -- l_notes_scheduler
                    l_notes_scheduler := table_varchar(pk_order_sets.get_odst_task_det_val(i_lang                        => i_lang,
                                                                                           i_prof                        => i_prof,
                                                                                           i_id_order_set_task           => l_order_set_tasks(i).order_set_task,
                                                                                           i_flg_detail_type             => 'S',
                                                                                           i_id_advanced_input           => NULL,
                                                                                           i_id_advanced_input_field     => NULL,
                                                                                           i_id_advanced_input_field_det => NULL));
                    -- notes for technician
                    l_notes_tech := table_varchar(pk_order_sets.get_odst_task_det_val(i_lang                        => i_lang,
                                                                                      i_prof                        => i_prof,
                                                                                      i_id_order_set_task           => l_order_set_tasks(i).order_set_task,
                                                                                      i_flg_detail_type             => 'T',
                                                                                      i_id_advanced_input           => NULL,
                                                                                      i_id_advanced_input_field     => NULL,
                                                                                      i_id_advanced_input_field_det => NULL));
                    -- fasting
                    l_flg_fasting := table_varchar(pk_order_sets.get_odst_task_det_val(i_lang                        => i_lang,
                                                                                       i_prof                        => i_prof,
                                                                                       i_id_order_set_task           => l_order_set_tasks(i).order_set_task,
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
                    l_diagnosis_notes          := table_varchar(NULL);
                    l_clinical_purpose         := table_number(NULL);
                    l_clinical_purpose_notes   := table_varchar(NULL);
                    l_flg_col_inst             := table_varchar(pk_order_sets.g_yes);
                    l_prof_cc                  := table_table_varchar(table_varchar(NULL));
                    l_prof_bcc                 := table_table_varchar(table_varchar(NULL));
                    l_health_plan              := table_number(NULL);
                    l_exemption                := table_number(NULL);
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
                                                                     i_analysis_req_det_parent => NULL,
                                                                     i_harvest                 => NULL,
                                                                     i_analysis                => l_analysis,
                                                                     i_analysis_group          => l_analysis_group, -- 10
                                                                     i_flg_type                => l_flg_type,
                                                                     i_dt_req                  => l_dt_req,
                                                                     i_flg_time                => l_flg_time,
                                                                     i_dt_begin                => l_dt_begin,
                                                                     i_dt_begin_limit          => l_dt_begin_limit, -- 15
                                                                     i_episode_destination     => l_episode_destination,
                                                                     i_order_recurrence        => l_order_recurrence,
                                                                     i_priority                => l_priority,
                                                                     i_flg_prn                 => l_flg_prn,
                                                                     i_notes_prn               => l_notes_prn, -- 20
                                                                     i_specimen                => l_specimen,
                                                                     i_body_location           => l_body_location,
                                                                     i_laterality              => l_laterality,
                                                                     i_collection_room         => l_collection_room,
                                                                     i_notes                   => l_notes, -- 25
                                                                     i_notes_scheduler         => l_notes_scheduler,
                                                                     i_notes_technician        => l_notes_tech,
                                                                     i_notes_patient           => l_notes_patient,
                                                                     i_diagnosis_notes         => l_diagnosis_notes,
                                                                     i_diagnosis               => NULL, --l_diagnosis,
                                                                     i_exec_institution        => l_exec_institution,
                                                                     i_clinical_purpose        => l_clinical_purpose, -- 30
                                                                     i_clinical_purpose_notes  => l_clinical_purpose_notes,
                                                                     i_flg_col_inst            => l_flg_col_inst,
                                                                     i_flg_fasting             => l_flg_fasting,
                                                                     i_lab_req                 => l_lab_req,
                                                                     i_prof_cc                 => l_prof_cc, -- 35
                                                                     i_prof_bcc                => l_prof_bcc,
                                                                     i_codification            => l_codification,
                                                                     i_health_plan             => l_health_plan,
                                                                     i_exemption               => l_exemption,
                                                                     i_prof_order              => l_prof_order, -- 40
                                                                     i_dt_order                => l_dt_order,
                                                                     i_order_type              => l_order_type,
                                                                     i_clinical_question       => l_clinical_question,
                                                                     i_response                => l_clinical_question_answer,
                                                                     i_clinical_question_notes => l_clinical_question_notes, -- 45
                                                                     i_clinical_decision_rule  => l_clinical_decision_rule,
                                                                     i_flg_origin_req          => pk_alert_constant.g_task_origin_order_set,
                                                                     i_task_dependency         => l_task_dependency,
                                                                     i_flg_task_depending      => l_flg_start_depending,
                                                                     i_episode_followup_app    => l_episode_followup_app, -- 50
                                                                     i_schedule_followup_app   => l_schedule_followup_app,
                                                                     i_event_followup_app      => l_event_followup_app,
                                                                     i_test                    => pk_alert_constant.g_no,
                                                                     o_flg_show                => l_flg_show,
                                                                     o_msg_title               => l_msg_title, -- 55
                                                                     o_msg_req                 => l_msg_req,
                                                                     o_button                  => l_button,
                                                                     o_analysis_req_array      => l_req,
                                                                     o_analysis_req_det_array  => l_req_det,
                                                                     o_analysis_req_par_array  => l_req_param, -- 60
                                                                     o_error                   => o_error)
                    THEN
                    
                        g_error := 'ERROR found while calling "pk_lab_tests_api_db.create_lab_test_order" for order set task [' || l_order_set_tasks(i).order_set_task ||
                                   ']: ' || chr(10) || o_error.ora_sqlcode || ' ' || o_error.ora_sqlerrm || chr(10) ||
                                   o_error.log_id;
                        pk_alertlog.log_error(g_error, g_package_name);
                        RETURN FALSE; -- error! could not create predefined lab test task
                    END IF;
                
                    -- get lab test link type
                    l_lab_test_link_type := pk_order_sets.get_odst_task_link_type(i_id_order_set_task => l_order_set_tasks(i).order_set_task);
                
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
                    
                        -- ## TASK LINKS ##
                        -- delete the links that will not be used from now on
                        DELETE order_set_task_link
                         WHERE id_order_set_task = l_order_set_tasks(i).order_set_task
                           AND flg_task_link_type != pk_order_sets.g_task_link_group;
                    
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
                           AND flg_task_link_type = pk_order_sets.g_task_link_group;
                    
                        DELETE order_set_task
                         WHERE id_order_set_task IN
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
                g_error := 'ERROR ' || SQLCODE || ' ' || SQLERRM;
                pk_alertlog.log_error(g_error, g_package_name);
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
        
            l_exam                   table_number;
            l_flg_type               table_varchar; -- A - exam; G - exam group (panel)
            l_dt_req                 table_varchar := table_varchar();
            l_flg_time               table_varchar := table_varchar();
            l_dt_begin               table_varchar := table_varchar();
            l_dt_begin_limit         table_varchar := table_varchar();
            l_episode_destination    table_number := table_number();
            l_order_recurrence       table_number := table_number();
            l_priority               table_varchar := table_varchar();
            l_flg_prn                table_varchar := table_varchar();
            l_notes_prn              table_varchar := table_varchar();
            l_notes                  table_varchar := table_varchar();
            l_notes_scheduler        table_varchar := table_varchar();
            l_notes_tech             table_varchar := table_varchar();
            l_notes_patient          table_varchar := table_varchar();
            l_diagnosis_notes        table_varchar := table_varchar();
            l_exec_room              table_number := table_number();
            l_exec_institution       table_number := table_number();
            l_clinical_purpose       table_number := table_number();
            l_clinical_purpose_notes table_varchar := table_varchar();
            l_flg_col_inst           table_varchar := table_varchar();
            l_flg_fasting            table_varchar := table_varchar();
            --l_diagnosis              table_clob := table_clob();            
            l_prof_cc                  table_table_varchar := table_table_varchar();
            l_prof_bcc                 table_table_varchar := table_table_varchar();
            l_codification             table_number := table_number();
            l_health_plan              table_number := table_number();
            l_exemption                table_number := table_number();
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
            SELECT t_rec_odst_mig_link(l.id_order_set_task, t.id_task_type, l.flg_task_link_type, l.id_task_link)
              BULK COLLECT
              INTO l_order_set_tasks
              FROM order_set_task t
              JOIN order_set_task_link l
                ON t.id_order_set_task = l.id_order_set_task
             WHERE t.id_task_type IN (7, 8) -- image and other exams task types
               AND l.flg_task_link_type =
                   pk_order_sets.get_odst_task_link_type(i_id_order_set_task => t.id_order_set_task)
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
                                                                                    i_id_order_set_task           => l_order_set_tasks(i).order_set_task,
                                                                                    i_flg_detail_type             => 'A',
                                                                                    i_id_advanced_input           => NULL,
                                                                                    i_id_advanced_input_field     => 95,
                                                                                    i_id_advanced_input_field_det => NULL),
                                                pk_alert_constant.g_flg_time_e));
            
                -- priority processing
                -- get urgency value
                l_priority := table_varchar(pk_order_sets.get_odst_task_det_val(i_lang                        => i_lang,
                                                                                i_prof                        => i_prof,
                                                                                i_id_order_set_task           => l_order_set_tasks(i).order_set_task,
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
                                                                             i_id_order_set_task           => l_order_set_tasks(i).order_set_task,
                                                                             i_flg_detail_type             => 'S',
                                                                             i_id_advanced_input           => NULL,
                                                                             i_id_advanced_input_field     => NULL,
                                                                             i_id_advanced_input_field_det => NULL));
                -- l_notes_scheduler
                l_notes_scheduler := table_varchar(pk_order_sets.get_odst_task_det_val(i_lang                        => i_lang,
                                                                                       i_prof                        => i_prof,
                                                                                       i_id_order_set_task           => l_order_set_tasks(i).order_set_task,
                                                                                       i_flg_detail_type             => 'S',
                                                                                       i_id_advanced_input           => NULL,
                                                                                       i_id_advanced_input_field     => NULL,
                                                                                       i_id_advanced_input_field_det => NULL));
                -- notes for technician
                l_notes_tech := table_varchar(pk_order_sets.get_odst_task_det_val(i_lang                        => i_lang,
                                                                                  i_prof                        => i_prof,
                                                                                  i_id_order_set_task           => l_order_set_tasks(i).order_set_task,
                                                                                  i_flg_detail_type             => 'T',
                                                                                  i_id_advanced_input           => NULL,
                                                                                  i_id_advanced_input_field     => NULL,
                                                                                  i_id_advanced_input_field_det => NULL));
                -- fasting
                l_flg_fasting := table_varchar(pk_order_sets.get_odst_task_det_val(i_lang                        => i_lang,
                                                                                   i_prof                        => i_prof,
                                                                                   i_id_order_set_task           => l_order_set_tasks(i).order_set_task,
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
                l_diagnosis_notes          := table_varchar(NULL);
                l_clinical_purpose         := table_number(NULL);
                l_clinical_purpose_notes   := table_varchar(NULL);
                l_flg_col_inst             := table_varchar(pk_order_sets.g_yes);
                l_prof_cc                  := table_table_varchar(table_varchar(NULL));
                l_prof_bcc                 := table_table_varchar(table_varchar(NULL));
                l_health_plan              := table_number(NULL);
                l_exemption                := table_number(NULL);
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
                                                         i_notes_scheduler         => l_notes_scheduler,
                                                         i_notes_technician        => l_notes_tech,
                                                         i_notes_patient           => l_notes_patient,
                                                         i_diagnosis_notes         => l_diagnosis_notes,
                                                         i_diagnosis               => NULL, --l_diagnosis,
                                                         i_exec_room               => l_exec_room,
                                                         i_exec_institution        => l_exec_institution,
                                                         i_clinical_purpose        => l_clinical_purpose,
                                                         i_clinical_purpose_notes  => l_clinical_purpose_notes,
                                                         i_codification            => l_codification,
                                                         i_health_plan             => l_health_plan,
                                                         i_exemption               => l_exemption,
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
                    g_error := 'ERROR found while calling "pk_exams_api_db.create_exam_order" for order set task [' || l_order_set_tasks(i).order_set_task ||
                               ']: ' || chr(10) || o_error.ora_sqlcode || ' ' || o_error.ora_sqlerrm || chr(10) ||
                               o_error.log_id;
                    pk_alertlog.log_error(g_error, g_package_name);
                    RETURN FALSE; -- error! could not create predefined exam task
                END IF;
            
                -- get exam link type
                l_exam_link_type := pk_order_sets.get_odst_task_link_type(i_id_order_set_task => l_order_set_tasks(i).order_set_task);
            
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
                g_error := 'ERROR ' || SQLCODE || ' ' || SQLERRM;
                pk_alertlog.log_error(g_error, g_package_name);
                RETURN FALSE;
        END migrate_exam_tasks;
    
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
    
        -- get all order sets with labs, image and other exams
        FOR os_rec IN c_odst_with_labs_and_exams
        LOOP
        
            g_error := 'Processing order set "' || os_rec.title || '" [id_content=' || os_rec.id_content ||
                       ', id_order_set=' || os_rec.id_order_set || '] for professional [prof=' ||
                       os_rec.id_professional || ', inst=' || os_rec.id_institution || ', soft=' || os_rec.id_software ||
                       ']...';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            -- check if we can user order set's professional                            
            IF os_rec.id_professional IS NULL
            THEN
                -- if not, then get system professional id
                l_prof_id := pk_sysconfig.get_config(i_code_cf   => 'ID_PROF_BACKGROUND',
                                                     i_prof_inst => os_rec.id_institution,
                                                     i_prof_soft => os_rec.id_software);
                g_error   := 'id_professional retrieved from ID_PROF_BACKGROUND sys_config is ' || l_prof_id;
                pk_alertlog.log_debug(g_error, g_package_name);
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
                g_error := 'ERROR found while editing order set [' || os_rec.id_order_set || ']: ' || chr(10) ||
                           l_error.ora_sqlcode || ' ' || l_error.ora_sqlerrm || chr(10) || l_error.log_id;
                pk_alertlog.log_error(g_error, g_package_name);
                CONTINUE;
            ELSE
                g_error := 'Temporary order set [' || l_order_set || '] created from [' || os_rec.id_order_set || ']';
                pk_alertlog.log_debug(g_error, g_package_name);
            
                -- call lab tests migration function    
                IF NOT
                    migrate_lab_test_tasks(i_lang => 2, i_prof => l_prof, i_order_set => l_order_set, o_error => l_error)
                THEN
                    g_error := 'ERROR found while migrating lab tests from order set [' || l_order_set || ']: ' ||
                               chr(10) || l_error.ora_sqlcode || ' ' || l_error.ora_sqlerrm || chr(10) ||
                               l_error.log_id;
                    pk_alertlog.log_error(g_error, g_package_name);
                    ROLLBACK;
                
                    pk_alert_exceptions.reset_error_state;
                    IF NOT pk_order_sets.cancel_order_set(2, l_prof, l_order_set, NULL, NULL, l_error)
                    THEN
                        g_error := 'ERROR while calling pk_order_sets.cancel_order_set function [id_order_set = ' ||
                                   l_order_set || ']: ' || chr(10) || l_error.ora_sqlcode || ' ' || l_error.ora_sqlerrm ||
                                   chr(10) || l_error.log_id;
                        pk_alertlog.log_error(g_error, g_package_name);
                    END IF;
                
                    CONTINUE;
                END IF;
            
                -- call exams migration function
                IF NOT migrate_exam_tasks(i_lang => 2, i_prof => l_prof, i_order_set => l_order_set, o_error => l_error)
                THEN
                    g_error := 'ERROR found while migrating exams from order set [' || l_order_set || ']: ' || chr(10) ||
                               l_error.ora_sqlcode || ' ' || l_error.ora_sqlerrm || chr(10) || l_error.log_id;
                    pk_alertlog.log_error(g_error, g_package_name);
                    ROLLBACK;
                
                    pk_alert_exceptions.reset_error_state;
                    IF NOT pk_order_sets.cancel_order_set(2, l_prof, l_order_set, NULL, NULL, l_error)
                    THEN
                        g_error := 'ERROR while calling pk_order_sets.cancel_order_set function [id_order_set = ' ||
                                   l_order_set || ']: ' || chr(10) || l_error.ora_sqlcode || ' ' || l_error.ora_sqlerrm ||
                                   chr(10) || l_error.log_id;
                        pk_alertlog.log_error(g_error, g_package_name);
                    END IF;
                
                    CONTINUE;
                END IF;
            
                BEGIN
                
                    -- set the order set with the same status of its previous version (finished or cancelled)
                    UPDATE order_set odst
                       SET odst.flg_status       =
                           (SELECT prev_odst.flg_status
                              FROM order_set prev_odst
                             WHERE prev_odst.id_order_set = odst.id_order_set_previous_version),
                           odst.id_professional  =
                           (SELECT prev_odst.id_professional
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
                    
                        g_error := 'ERROR while setting temporary order set [id_order_set=' || l_order_set ||
                                   '] to final state';
                        pk_alertlog.log_error(g_error, g_package_name);
                        ROLLBACK;
                END;
            END IF;
        END LOOP;
    
    END migrate_labs_and_exams;

BEGIN

    -- log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_api_order_sets;
/
