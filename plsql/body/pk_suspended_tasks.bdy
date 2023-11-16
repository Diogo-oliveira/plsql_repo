/*-- Last Change Revision: $Rev: 2027773 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:15 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_suspended_tasks IS

    -- ***************************************************************************  
    FUNCTION get_package_owner RETURN VARCHAR2 IS
    BEGIN
        RETURN g_package_owner;
    END get_package_owner;
    FUNCTION get_package_name RETURN VARCHAR2 IS
    BEGIN
        RETURN g_package_name;
    END get_package_name;
    PROCEDURE set_package_name IS
    BEGIN
        g_package_name := pk_alertlog.who_am_i;
    END set_package_name;
    -- ###########################################################################

    -- ***************************************************************************  
    FUNCTION get_function_name RETURN VARCHAR2 IS
    BEGIN
        RETURN g_function_name;
    END get_function_name;
    -- ###########################################################################
    PROCEDURE set_function_name(i_function_name IN VARCHAR2) IS
    BEGIN
        g_function_name := i_function_name;
    END set_function_name;
    -- ###########################################################################
    PROCEDURE my_rollback IS
    BEGIN
        ROLLBACK;
    END my_rollback;

    /*
    * Get all ongoing tasks from within exams, lab tests, schedules, etc.
    *
    * @param   I_LANG               language associated to the professional executing the request
    * @param   I_PROF               Professional type
    * @param   I_ID_PATIENT         Patient ID
    * @param   O_SYS_LIST           Cursor containing the areas that have to be shown on the UX (e.g. "Exams", "Lab tests", etc)
    * @param   O_TASKS_LIST         Cursor containing all ongoing tasks and the corresponding area (e.g. "Lab 01" for the area "Lab tests")
    * @param   O_ERROR              warning/error message
    *
    * @RETURN  TRUE if success, FALSE otherwise
    * @author  Rui de Sousa Neves
    * @version 2.6.0.3
    * @since   10-MAY-2010
    *
    */

    FUNCTION get_ongoing_tasks_all
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_sys_list   OUT pk_types.cursor_type,
        o_tasks_list OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name         CONSTANT VARCHAR2(30 CHAR) := 'get_ongoing_tasks_all';
        l_slg_internal_name CONSTANT sys_list_group.internal_name%TYPE := 'ALERT_AREAS';
    
    BEGIN
    
        -- get areas configured to be shown on the UX (on SYS_LIST with SYS_LIST_GROUP)
        g_error := 'O_SYS_LIST FILL';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        OPEN o_sys_list FOR
            SELECT sl.*
              FROM TABLE(pk_sys_list.tf_sys_list_values(i_lang, i_prof, l_slg_internal_name)) sl;
    
        -- get cursor for all ongoing tasks (exams, labs, etc).
        -- IDs must be used later, for the SUSPENSION function.
        -- an oracle type was created to check if each team is returning the right columns
        g_error := 'OPEN CURSOR WITH ONGOING TASKS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        OPEN o_tasks_list FOR
        -- #### lab exams
            SELECT a.*, g_flgcontext_labs flg_context
              FROM TABLE(pk_lab_tests_external_api_db.get_lab_test_ongoing_tasks(i_lang, i_prof, i_id_patient)) a
            UNION ALL
            -- #### imaging and other exams
            SELECT a.*, g_flgcontext_imaging flg_context
              FROM TABLE(pk_exams_external_api_db.get_exam_ongoing_tasks(i_lang, i_prof, i_id_patient)) a
            UNION ALL
            -- #### Procedures
            SELECT a.*, g_flgcontext_procedures flg_context
              FROM TABLE(pk_procedures_external_api_db.get_procedure_ongoing_tasks(i_lang, i_prof, i_id_patient)) a
            UNION ALL
            -- #### Schedules
            SELECT a.*, g_flgcontext_schedules flg_context
              FROM TABLE(pk_schedule.get_ongoing_tasks_scheduler(i_lang, i_prof, i_id_patient)) a
            UNION ALL
            -- #### Medication
            SELECT a.*, g_flgcontext_medication flg_context
              FROM TABLE(pk_api_pfh_in.get_list_ongoing_presc(i_lang, i_prof, i_id_patient)) a
            UNION ALL
            -- #### Intake and output
            SELECT a.*, g_flgcontext_io flg_context
              FROM TABLE(pk_inp_hidrics_pbl.get_ongoing_tasks_hidric(i_lang, i_prof, i_id_patient)) a
            UNION ALL
            -- #### Monitorizations
            SELECT a.*, g_flgcontext_monit flg_context
              FROM TABLE(pk_monitorization.get_ongoing_tasks_monit(i_lang, i_prof, i_id_patient)) a
            UNION ALL
            -- #### Transports
            SELECT a.*, g_flgcontext_transp flg_context
              FROM TABLE(pk_movement.get_ongoing_tasks_transp(i_lang, i_prof, i_id_patient)) a
            UNION ALL
            -- #### Positionings
            SELECT a.*, g_flgcontext_posit flg_context
              FROM TABLE(pk_pbl_inp_positioning.get_ongoing_tasks_posit(i_lang, i_prof, i_id_patient)) a
            UNION ALL
            -- #### Physic
            SELECT a.*, g_flgcontext_physio flg_context
              FROM TABLE(pk_rehab_pbl.get_ongoing_tasks_rehab(i_lang, i_prof, i_id_patient)) a
            UNION ALL
            -- #### Diets
            SELECT a.*, g_flgcontext_diets flg_context
              FROM TABLE(pk_diet.get_ongoing_tasks_diets(i_lang, i_prof, i_id_patient)) a
            -- <TODO> These functions are yet to be developed:
            --UNION ALL
            -- #### Guidelines
            --SELECT a.*, g_flgcontext_guidelines flg_context
            --  FROM TABLE(get_ongoing_tasks_guid(i_lang, i_prof, i_id_patient)) a
            --UNION ALL
            -- #### Protocols
            --SELECT a.*, g_flgcontext_protocols flg_context
            --  FROM TABLE(get_ongoing_tasks_prot(i_lang, i_prof, i_id_patient)) a
            --UNION ALL
            -- #### Care plans
            --SELECT a.*, g_flgcontext_careplans flg_context
            --  FROM TABLE(get_ongoing_tasks_carepl(i_lang, i_prof, i_id_patient)) a
            --UNION ALL
            -- #### CPOE
            --SELECT a.*, g_flgcontext_cpoe flg_context
            --  FROM TABLE(get_ongoing_tasks_cpoe(i_lang, i_prof, i_id_patient)) a
            ;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => g_error || '-' || SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => get_package_owner,
                                              i_package  => get_package_name,
                                              i_function => get_function_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END get_ongoing_tasks_all;

    /*
    * Get all reactivatable tasks from within exams, lab tests, schedules, etc.
    *
    * @param   I_LANG               language associated to the professional executing the request
    * @param   I_PROF               Professional type
    * @param   I_ID_SUSP_ACTION     SUSP_ACTION ID
    * @param   O_SYS_LIST           Cursor containing the areas that have to be shown on the UX (e.g. "Exams", "Lab tests", etc)
    * @param   O_TASKS_LIST         Cursor containing all ongoing tasks and the corresponding area (e.g. "Lab 01" for the area "Lab tests")
    * @param   O_ERROR              warning/error message
    *
    * @RETURN  TRUE if success, FALSE otherwise
    * @author  Rui de Sousa Neves
    * @version 2.6.0.3
    * @since   14-MAY-2010
    *
    */
    FUNCTION get_reactivatable_tasks_all
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_susp_action IN susp_action.id_susp_action%TYPE,
        o_sys_list       OUT pk_types.cursor_type,
        o_tasks_list     OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name         CONSTANT VARCHAR2(30 CHAR) := 'get_reactivable_tasks_all';
        l_slg_internal_name CONSTANT sys_list_group.internal_name%TYPE := 'ALERT_AREAS';
    
    BEGIN
    
        -- get areas configured to be shown on the UX (on SYS_LIST with SYS_LIST_GROUP)
        g_error := 'O_SYS_LIST FILL';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        OPEN o_sys_list FOR
            SELECT sl.*
              FROM TABLE(pk_sys_list.tf_sys_list_values(i_lang, i_prof, l_slg_internal_name)) sl;
    
        -- get cursor for all reactivatable tasks (exams, labs, etc).
        -- IDs must be used later, for the REACTIVATION function.
        -- an oracle type was created to check if each function is returning the right columns
        g_error := 'OPEN CURSOR WITH REACTIVATABLE TASKS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        OPEN o_tasks_list FOR
            SELECT wf.*
              FROM TABLE(get_wfstatus_tasks_all(i_lang, i_prof, i_id_susp_action, c_wfstatus_susp)) wf;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => g_error || '-' || SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => get_package_owner,
                                              i_package  => get_package_name,
                                              i_function => get_function_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END get_reactivatable_tasks_all;

    /*
    * Get all tasks associated to the ID_SUSP_ACTION from within exams, lab tests, schedules, etc.
    *
    * @param   I_LANG               language associated to the professional executing the request
    * @param   I_PROF               Professional type
    * @param   I_ID_SUSP_ACTION     SUSP_ACTION ID
    * @param   O_SYS_LIST           Cursor containing the areas that have to be shown on the UX (e.g. "Exams", "Lab tests", etc)
    * @param   O_SUSP_TASKS_LIST    Cursor containing all suspended tasks and the corresponding area (e.g. "Lab 01" for the area "Lab tests")
    * @param   O_NSUSP_TASKS_LIST   Cursor containing all non-suspended tasks and the corresponding area (e.g. "Lab 01" for the area "Lab tests")
    * @param   O_REAC_TASKS_LIST    Cursor containing all reactivated tasks and the corresponding area (e.g. "Lab 01" for the area "Lab tests")
    * @param   O_NREAC_TASKS_LIST   Cursor containing all non-reactivated tasks and the corresponding area (e.g. "Lab 01" for the area "Lab tests")
    * @param   O_ERROR              warning/error message
    *
    * @RETURN  TRUE if success, FALSE otherwise
    * @author  Rui de Sousa Neves
    * @version 2.6.0.3
    * @since   9-JUN-2010
    *
    */
    FUNCTION get_action_tasks_all
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_susp_action   IN susp_action.id_susp_action%TYPE,
        o_sys_list         OUT pk_types.cursor_type,
        o_susp_tasks_list  OUT pk_types.cursor_type,
        o_nsusp_tasks_list OUT pk_types.cursor_type,
        o_reac_tasks_list  OUT pk_types.cursor_type,
        o_nreac_tasks_list OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name         CONSTANT VARCHAR2(30 CHAR) := 'get_action_tasks_all';
        l_slg_internal_name CONSTANT sys_list_group.internal_name%TYPE := 'ALERT_AREAS';
    
    BEGIN
    
        -- get areas configured to be shown on the UX (on SYS_LIST with SYS_LIST_GROUP)
        g_error := 'O_SYS_LIST FILL';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        OPEN o_sys_list FOR
            SELECT sl.*
              FROM TABLE(pk_sys_list.tf_sys_list_values(i_lang, i_prof, l_slg_internal_name)) sl;
    
        -- get cursor for all suspended tasks
        g_error := 'OPEN CURSOR WITH SUSP TASKS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        OPEN o_susp_tasks_list FOR
            SELECT *
              FROM (
                    -- susp
                    SELECT wf.*
                      FROM TABLE(get_wfstatus_tasks_all(i_lang, i_prof, i_id_susp_action, c_wfstatus_susp)) wf
                    UNION ALL
                    -- reac (was previously suspended with this ID_SUSP_ACTION)
                    SELECT wf.*
                      FROM TABLE(get_wfstatus_tasks_all(i_lang, i_prof, i_id_susp_action, c_wfstatus_reac)) wf
                    UNION ALL
                    -- nreac (was previously suspended with this ID_SUSP_ACTION)
                    SELECT wf.*
                      FROM TABLE(get_wfstatus_tasks_all(i_lang, i_prof, i_id_susp_action, c_wfstatus_nreac)) wf)
             ORDER BY id_susp_task ASC;
    
        -- get cursor for all non-suspended tasks
        g_error := 'OPEN CURSOR WITH N-SUSP TASKS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        OPEN o_nsusp_tasks_list FOR
            SELECT wf.*
              FROM TABLE(get_wfstatus_tasks_all(i_lang, i_prof, i_id_susp_action, c_wfstatus_nsusp)) wf;
    
        -- get cursor for all reactivated tasks
        g_error := 'OPEN CURSOR WITH REACT TASKS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        OPEN o_reac_tasks_list FOR
            SELECT wf.*
              FROM TABLE(get_wfstatus_tasks_all(i_lang, i_prof, i_id_susp_action, c_wfstatus_reac)) wf;
    
        -- get cursor for all non-reactivated tasks
        g_error := 'OPEN CURSOR WITH N-REACT TASKS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        OPEN o_nreac_tasks_list FOR
            SELECT wf.*
              FROM TABLE(get_wfstatus_tasks_all(i_lang, i_prof, i_id_susp_action, c_wfstatus_nreac)) wf;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => g_error || '-' || SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => get_package_owner,
                                              i_package  => get_package_name,
                                              i_function => get_function_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END get_action_tasks_all;

    /*
    * Get all tasks from within exams, lab tests, schedules, etc. according to the i_wf_status
    * Functions for each ALERT area MUST raise exceptions.
    *
    * @param   I_LANG               language associated to the professional executing the request
    * @param   I_PROF               Professional type
    * @param   I_ID_SUSP_ACTION     SUSP_ACTION ID
    * @param   I_WFSTATUS           Pretended WF Status (from the SUSP_TASK table)
    * @param   O_ERROR              warning/error message
    *
    * @RETURN  tf_tasks_list (table of tr_tasks_list)
    * @author  Rui de Sousa Neves
    * @version 2.6.0.3
    * @since   9-JUN-2010
    *
    */
    FUNCTION get_wfstatus_tasks_all
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_susp_action IN susp_action.id_susp_action%TYPE,
        i_wfstatus       IN susp_task.flg_status%TYPE
    ) RETURN tf_tasks_wfstatus_list IS
    
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'get_wfstatus_tasks_all';
        t tf_tasks_wfstatus_list;
    
    BEGIN
    
        -- get cursor for all tasks (exams, labs, etc) according to parameter WFSTATUS
        g_error := 'OPEN CURSOR WITH TASKS ACCORDING TO THE WFSTATUS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        SELECT tr_tasks_wfstatus_list(id_task, id_susp_task, desc_task, epis_type, dt_task, flg_context)
          BULK COLLECT
          INTO t
          FROM (
                -- #### lab exams
                SELECT a.*, g_flgcontext_labs flg_context
                  FROM TABLE(get_wfstatus_tasks_labs(i_lang, i_prof, i_id_susp_action, i_wfstatus)) a
                UNION ALL
                -- #### imaging and other exams
                SELECT a.*, g_flgcontext_imaging flg_context
                  FROM TABLE(get_wfstatus_tasks_ioe(i_lang, i_prof, i_id_susp_action, i_wfstatus)) a
                UNION ALL
                -- #### Procedures
                SELECT a.*, g_flgcontext_procedures flg_context
                  FROM TABLE(get_wfstatus_tasks_proc(i_lang, i_prof, i_id_susp_action, i_wfstatus)) a
                UNION ALL
                -- #### Schedules
                SELECT a.*, g_flgcontext_schedules flg_context
                  FROM TABLE(get_wfstatus_tasks_sch(i_lang, i_prof, i_id_susp_action, i_wfstatus)) a
                UNION ALL
                -- #### Medication
                SELECT a.*, g_flgcontext_medication flg_context
                  FROM TABLE(get_wfstatus_tasks_med(i_lang, i_prof, i_id_susp_action, i_wfstatus)) a
                UNION ALL
                -- #### Intake and output
                SELECT a.*, g_flgcontext_io flg_context
                  FROM TABLE(get_wfstatus_tasks_hidr(i_lang, i_prof, i_id_susp_action, i_wfstatus)) a
                UNION ALL
                -- #### Monitorizations
                SELECT a.*, g_flgcontext_monit flg_context
                  FROM TABLE(pk_monitorization.get_wfstatus_tasks_monit(i_lang, i_prof, i_id_susp_action, i_wfstatus)) a
                UNION ALL
                -- #### Transports
                SELECT a.*, g_flgcontext_transp flg_context
                  FROM TABLE(pk_movement.get_wfstatus_tasks_transp(i_lang, i_prof, i_id_susp_action, i_wfstatus)) a
                UNION ALL
                -- #### Positionings
                SELECT a.*, g_flgcontext_posit flg_context
                  FROM TABLE(get_wfstatus_tasks_posit(i_lang, i_prof, i_id_susp_action, i_wfstatus)) a
                UNION ALL
                -- #### Physio
                SELECT a.*, g_flgcontext_physio flg_context
                  FROM TABLE(get_wfstatus_tasks_physio(i_lang, i_prof, i_id_susp_action, i_wfstatus)) a
                UNION ALL
                -- #### Diets
                SELECT a.*, g_flgcontext_diets flg_context
                  FROM TABLE(pk_diet.get_wfstatus_tasks_diets(i_lang, i_prof, i_id_susp_action, i_wfstatus)) a
                -- <TODO> These functions are yet to be developed:
                --UNION ALL
                -- #### Guidelines
                --SELECT a.*, g_flgcontext_guidelines flg_context
                --  FROM TABLE(get_reactivatable_tasks_guid(i_lang, i_prof, i_id_susp_action)) a
                --UNION ALL
                -- #### Protocols
                --SELECT a.*, g_flgcontext_protocols flg_context
                --  FROM TABLE(get_reactivatable_tasks_prot(i_lang, i_prof, i_id_susp_action)) a
                --UNION ALL
                -- #### Care plans
                --SELECT a.*, g_flgcontext_careplans flg_context
                --  FROM TABLE(get_reactivatable_tasks_carepl(i_lang, i_prof, i_id_susp_action)) a
                --UNION ALL
                -- #### CPOE
                --SELECT a.*, g_flgcontext_cpoe flg_context
                --  FROM TABLE(get_reactivatable_tasks_cpoe(i_lang, i_prof, i_id_susp_action)) a            
                );
    
        RETURN t;
    
    END get_wfstatus_tasks_all;

    /*
    * Suspend the ongoing tasks selected by the professional from within exams, lab tests, schedules, etc.
    *
    * @param   I_LANG               language associated to the professional executing the request
    * @param   I_PROF               Professional type
    * @param   I_TASK_LIST          Table of IDs from the corresponding task (e.g., for an imaging exam, it is the ID_EXAM_REQ_DET)
    * @param   I_AREA_LIST          Table of Areas from each one of the tasks in I_TASK_LIST
    * @param   I_FLG_REASON         Reason for the WF suspension: 'D' (Death)
    * @param   O_SUSP_ACTION        ID for the SUSPENSION_ACTION created. It is sent to the UX to update the DEATH_REGISTRY table
    * @param   O_MSG_ERROR          Message to send to the UX in case one of the functions has some kind of error
    * @param   O_ERROR              warning/error message
    *
    * @RETURN  TRUE if success, FALSE otherwise
    * @author  Rui de Sousa Neves
    * @version 2.6.0.3
    * @since   10-MAY-2010
    *
    */
    FUNCTION suspend_tasks_all
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_task_list   IN table_number,
        i_area_list   IN table_varchar,
        i_flg_reason  IN VARCHAR2,
        o_susp_action OUT susp_action.id_susp_action%TYPE,
        o_msg_error   OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'suspend_tasks_all';
    
        l_return          BOOLEAN;
        l_proceed         BOOLEAN;
        l_flg_status      susp_task.flg_status%TYPE;
        l_susp_action     susp_action.id_susp_action%TYPE;
        l_susp_task       susp_task.id_susp_task%TYPE;
        l_rows            table_varchar := table_varchar();
        l_msg_error_init  VARCHAR2(4000 CHAR);
        l_msg_error_total VARCHAR2(4000 CHAR);
        l_msg_error_func  VARCHAR2(4000 CHAR);
        l_transaction_id  VARCHAR2(4000 CHAR);
    
        --l_counter NUMBER; -- debug
    
    BEGIN
    
        --l_counter    := 0; -- debug
        g_line_break       := pk_message.get_message(i_lang => i_lang, i_code_mess => 'WORKFLOW_WARNING_M011');
        l_msg_error_init   := '<b>' || pk_message.get_message(i_lang => i_lang, i_code_mess => 'DEATH_REGISTRY_T012') ||
                              ':</b>';
        g_sysdate_tstz     := current_timestamp;
        g_error_suspension := FALSE;
    
        -- SUSP_ACTION table insert. Registers the action by the user. Each SUSP_ACTION has several SUSP_TASK.
        g_error := 'GET NEXT_KEY SUSP_ACTION';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        BEGIN
        
            l_susp_action := ts_susp_action.next_key();
        
            g_error := 'INS SUSP_ACTION';
            alertlog.pk_alertlog.log_info(text            => g_error,
                                          object_name     => g_package_name,
                                          sub_object_name => l_func_name);
            ts_susp_action.ins(id_susp_action_in => l_susp_action,
                               dt_suspension_in  => g_sysdate_tstz,
                               flg_status_in     => c_wfstatus_susp,
                               rows_out          => l_rows);
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'SUSP_ACTION',
                                          i_rowids     => l_rows,
                                          o_error      => o_error);
        
        EXCEPTION
            WHEN OTHERS THEN
                g_error     := pk_message.get_message(i_lang => i_lang, i_code_mess => 'WORKFLOW_WARNING_M020');
                o_msg_error := g_error;
                alertlog.pk_alertlog.log_error(text            => g_error,
                                               object_name     => g_package_name,
                                               sub_object_name => l_func_name);
            
                ROLLBACK;
                RETURN TRUE;
        END;
    
        -- The UX needs to know the ID_SUSP_ACTION to update external tables (like DEATH_REGISTRY)
        o_susp_action := l_susp_action;
    
        -- Commit is needed because it must record the user's intention, even though everything else is rollbacked
        COMMIT;
    
        -- This loop will register the SUSP_TASKs that are part of the SUSP_ACTION    
        FOR i IN 1 .. i_task_list.count
        LOOP
            -- Sets l_proceed to TRUE on each iteration
            l_proceed := TRUE;
        
            -- SUSP_TASK insertion, for each task. The column FLG_STATUS will only be saved after calling the external suspension function.
            g_error := 'GET NEXT_KEY SUSP_TASK';
            alertlog.pk_alertlog.log_info(text            => g_error,
                                          object_name     => g_package_name,
                                          sub_object_name => l_func_name);
            BEGIN
                l_susp_task := ts_susp_task.next_key();
            
                g_error := 'INS SUSP_TASK';
                alertlog.pk_alertlog.log_info(text            => g_error,
                                              object_name     => g_package_name,
                                              sub_object_name => l_func_name);
                ts_susp_task.ins(id_susp_task_in   => l_susp_task,
                                 id_susp_action_in => l_susp_action,
                                 rows_out          => l_rows);
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'SUSP_TASK',
                                              i_rowids     => l_rows,
                                              o_error      => o_error);
            EXCEPTION
                WHEN OTHERS THEN
                    g_error     := pk_message.get_message(i_lang => i_lang, i_code_mess => 'WORKFLOW_WARNING_M020');
                    o_msg_error := g_error;
                    alertlog.pk_alertlog.log_error(text            => g_error,
                                                   object_name     => g_package_name,
                                                   sub_object_name => l_func_name);
                    ROLLBACK;
                    RETURN TRUE;
            END;
        
            -- From now on, there is specific code per area: labs, exams, procedures, etc.
            CASE i_area_list(i)
            
                WHEN g_flgcontext_labs THEN
                
                    -- #########################################################
                    -- #### Lab tests  
                    -- #########################################################
                
                    -- SUSP_TASK_* insertion. Tests for integrity (otherwise an ID that doesn't exist could be inserted in the table)
                    g_error := 'INS SUSP_TASK_SP';
                    alertlog.pk_alertlog.log_info(text            => g_error,
                                                  object_name     => g_package_name,
                                                  sub_object_name => l_func_name);
                    BEGIN
                    
                        ts_susp_task_lab.ins(id_susp_task_in        => l_susp_task,
                                             id_analysis_req_det_in => i_task_list(i),
                                             rows_out               => l_rows);
                        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'SUSP_TASK_LAB',
                                                      i_rowids     => l_rows,
                                                      o_error      => o_error);
                    EXCEPTION
                        WHEN OTHERS THEN
                            l_proceed         := FALSE;
                            l_msg_error_total := l_msg_error_total || g_line_break ||
                                                 pk_message.get_message(i_lang      => i_lang,
                                                                        i_code_mess => 'WORKFLOW_WARNING_M021');
                            g_error           := 'ERROR INS SUSP_TASK_SP WITH L_MSG_ERROR_TOTAL: ' || l_msg_error_total;
                            alertlog.pk_alertlog.log_error(text            => g_error,
                                                           object_name     => g_package_name,
                                                           sub_object_name => l_func_name);
                            ROLLBACK;
                    END;
                
                    IF l_proceed
                    THEN
                    
                        COMMIT;
                    
                        -- calls function for the corresponding area
                        g_error := 'FUNCTION pk_lab_tests_external_api_db.suspend_task_lab_tests';
                    
                        alertlog.pk_alertlog.log_info(text            => g_error,
                                                      object_name     => g_package_name,
                                                      sub_object_name => l_func_name);
                        l_return := pk_lab_tests_external_api_db.suspend_lab_test_task(i_lang       => i_lang,
                                                                                       i_prof       => i_prof,
                                                                                       i_id_task    => i_task_list(i),
                                                                                       i_flg_reason => i_flg_reason,
                                                                                       o_msg_error  => l_msg_error_func,
                                                                                       o_error      => o_error);
                    END IF;
                
                WHEN g_flgcontext_imaging THEN
                
                    -- #########################################################
                    -- #### Imaging and other exams
                    -- #########################################################
                
                    -- SUSP_TASK_* insertion. Tests for integrity (otherwise an ID that doesn't exist could be inserted in the table)
                    g_error := 'INS SUSP_TASK_SP';
                    alertlog.pk_alertlog.log_info(text            => g_error,
                                                  object_name     => g_package_name,
                                                  sub_object_name => l_func_name);
                    BEGIN
                        ts_susp_task_image_o_exams.ins(id_susp_task_in    => l_susp_task,
                                                       id_exam_req_det_in => i_task_list(i),
                                                       rows_out           => l_rows);
                        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'SUSP_TASK_IMAGE_O_EXAMS',
                                                      i_rowids     => l_rows,
                                                      o_error      => o_error);
                    EXCEPTION
                        WHEN OTHERS THEN
                            l_proceed         := FALSE;
                            l_msg_error_total := l_msg_error_total || g_line_break ||
                                                 pk_message.get_message(i_lang      => i_lang,
                                                                        i_code_mess => 'WORKFLOW_WARNING_M021');
                            g_error           := 'ERROR INS SUSP_TASK_SP WITH L_MSG_ERROR_TOTAL: ' || l_msg_error_total;
                            alertlog.pk_alertlog.log_error(text            => g_error,
                                                           object_name     => g_package_name,
                                                           sub_object_name => l_func_name);
                            ROLLBACK;
                    END;
                
                    IF l_proceed
                    THEN
                    
                        COMMIT;
                    
                        -- calls function for the corresponding area
                        g_error := 'FUNCTION pk_exams_external_api_db.suspend_task_exams';
                    
                        alertlog.pk_alertlog.log_info(text            => g_error,
                                                      object_name     => g_package_name,
                                                      sub_object_name => l_func_name);
                        l_return := pk_exams_external_api_db.suspend_exam_task(i_lang       => i_lang,
                                                                               i_prof       => i_prof,
                                                                               i_id_task    => i_task_list(i),
                                                                               i_flg_reason => i_flg_reason,
                                                                               o_msg_error  => l_msg_error_func,
                                                                               o_error      => o_error);
                    
                    END IF;
                WHEN g_flgcontext_procedures THEN
                    -- #########################################################
                    -- #### Procedures
                    -- #########################################################
                
                    -- SUSP_TASK_* insertion. Tests for integrity (otherwise an ID that doesn't exist could be inserted in the table)
                    g_error := 'INS SUSP_TASK_SP';
                    alertlog.pk_alertlog.log_info(text            => g_error,
                                                  object_name     => g_package_name,
                                                  sub_object_name => l_func_name);
                    BEGIN
                        ts_susp_task_procedures.ins(id_susp_task_in        => l_susp_task,
                                                    id_interv_presc_det_in => i_task_list(i),
                                                    rows_out               => l_rows);
                        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'SUSP_TASK_PROCEDURES',
                                                      i_rowids     => l_rows,
                                                      o_error      => o_error);
                    EXCEPTION
                        WHEN OTHERS THEN
                            l_proceed         := FALSE;
                            l_msg_error_total := l_msg_error_total || g_line_break ||
                                                 pk_message.get_message(i_lang      => i_lang,
                                                                        i_code_mess => 'WORKFLOW_WARNING_M021');
                            g_error           := 'ERROR INS SUSP_TASK_SP WITH L_MSG_ERROR_TOTAL: ' || l_msg_error_total;
                            alertlog.pk_alertlog.log_error(text            => g_error,
                                                           object_name     => g_package_name,
                                                           sub_object_name => l_func_name);
                            ROLLBACK;
                    END;
                
                    IF l_proceed
                    THEN
                    
                        COMMIT;
                    
                        -- calls function for the corresponding area
                        g_error := 'FUNCTION pk_procedures_external_api_db.suspend_procedure_task';
                    
                        alertlog.pk_alertlog.log_info(text            => g_error,
                                                      object_name     => g_package_name,
                                                      sub_object_name => l_func_name);
                        l_return := pk_procedures_external_api_db.suspend_procedure_task(i_lang       => i_lang,
                                                                                         i_prof       => i_prof,
                                                                                         i_id_task    => i_task_list(i),
                                                                                         i_flg_reason => i_flg_reason,
                                                                                         o_msg_error  => l_msg_error_func,
                                                                                         o_error      => o_error);
                    END IF;
                
                WHEN g_flgcontext_schedules THEN
                
                    -- #########################################################
                    -- #### Schedule events
                    -- #########################################################
                
                    -- SUSP_TASK_* insertion. Tests for integrity (otherwise an ID that doesn't exist could be inserted in the table)
                    g_error := 'INS SUSP_TASK_SP';
                    alertlog.pk_alertlog.log_info(text            => g_error,
                                                  object_name     => g_package_name,
                                                  sub_object_name => l_func_name);
                    BEGIN
                        ts_susp_task_schedules.ins(id_susp_task_in => l_susp_task,
                                                   id_schedule_in  => i_task_list(i),
                                                   rows_out        => l_rows);
                        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'SUSP_TASK_SCHEDULES',
                                                      i_rowids     => l_rows,
                                                      o_error      => o_error);
                    EXCEPTION
                        WHEN OTHERS THEN
                            l_proceed         := FALSE;
                            l_msg_error_total := l_msg_error_total || g_line_break ||
                                                 pk_message.get_message(i_lang      => i_lang,
                                                                        i_code_mess => 'WORKFLOW_WARNING_M021');
                            g_error           := 'ERROR INS SUSP_TASK_SP WITH L_MSG_ERROR_TOTAL: ' || l_msg_error_total;
                            alertlog.pk_alertlog.log_error(text            => g_error,
                                                           object_name     => g_package_name,
                                                           sub_object_name => l_func_name);
                            ROLLBACK;
                    END;
                
                    IF l_proceed
                    THEN
                    
                        COMMIT;
                    
                        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
                        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(NULL, i_prof);
                    
                        -- calls function for the corresponding area
                        g_error := 'FUNCTION pk_schedule.suspend_task_scheduler';
                    
                        alertlog.pk_alertlog.log_info(text            => g_error,
                                                      object_name     => g_package_name,
                                                      sub_object_name => l_func_name);
                        l_return := pk_schedule.suspend_task_scheduler(i_lang           => i_lang,
                                                                       i_prof           => i_prof,
                                                                       i_id_task        => i_task_list(i),
                                                                       i_transaction_id => l_transaction_id,
                                                                       i_flg_reason     => i_flg_reason,
                                                                       o_msg_error      => l_msg_error_func,
                                                                       o_error          => o_error);
                    
                        -- In case scheduler fails, transaction must be rollbacked.
                        IF l_return = FALSE
                        THEN
                            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
                        ELSE
                            -- If there is an open transaction on the scheduler, it must commit it.
                            BEGIN
                                pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
                                --l_transaction_id := NULL;
                            EXCEPTION
                                WHEN OTHERS THEN
                                    l_return          := FALSE;
                                    l_msg_error_total := l_msg_error_total || g_line_break ||
                                                         pk_message.get_message(i_lang      => i_lang,
                                                                                i_code_mess => 'WORKFLOW_WARNING_M021');
                                    g_error           := 'ERROR INS SUSP_TASK_SP WITH L_MSG_ERROR_TOTAL: ' ||
                                                         l_msg_error_total;
                                    alertlog.pk_alertlog.log_error(text            => g_error,
                                                                   object_name     => g_package_name,
                                                                   sub_object_name => l_func_name);
                            END;
                        END IF;
                    
                    END IF;
                
                WHEN g_flgcontext_medication THEN
                    -- #########################################################
                    -- #### Medication
                    -- #########################################################
                
                    -- SUSP_TASK_* insertion. Tests for integrity (otherwise an ID that doesn't exist could be inserted in the table)
                    g_error := 'INS SUSP_TASK_SP';
                    alertlog.pk_alertlog.log_info(text            => g_error,
                                                  object_name     => g_package_name,
                                                  sub_object_name => l_func_name);
                    BEGIN
                    
                        ts_susp_task_medication.ins(id_susp_task_in      => l_susp_task,
                                                    id_drug_presc_det_in => i_task_list(i),
                                                    rows_out             => l_rows);
                        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'SUSP_TASK_MEDICATION',
                                                      i_rowids     => l_rows,
                                                      o_error      => o_error);
                    EXCEPTION
                        WHEN OTHERS THEN
                            l_proceed         := FALSE;
                            l_msg_error_total := l_msg_error_total || g_line_break ||
                                                 pk_message.get_message(i_lang      => i_lang,
                                                                        i_code_mess => 'WORKFLOW_WARNING_M021');
                            g_error           := 'ERROR INS SUSP_TASK_SP WITH L_MSG_ERROR_TOTAL: ' || l_msg_error_total;
                            alertlog.pk_alertlog.log_error(text            => g_error,
                                                           object_name     => g_package_name,
                                                           sub_object_name => l_func_name);
                            ROLLBACK;
                    END;
                
                    IF l_proceed
                    THEN
                    
                        COMMIT;
                    
                        -- calls function for the corresponding area
                        g_error := 'FUNCTION pk_api_drug.suspend_task_med_int';
                        alertlog.pk_alertlog.log_info(text            => g_error,
                                                      object_name     => g_package_name,
                                                      sub_object_name => l_func_name);
                        l_return := pk_api_pfh_in.set_cancel_presc(i_lang        => i_lang,
                                                                   i_prof        => i_prof,
                                                                   i_id_presc    => i_task_list(i),
                                                                   i_id_reason   => pk_cancel_reason.c_reason_patient_death,
                                                                   i_reason      => pk_translation.get_translation(i_lang,
                                                                                                                   'CANCEL_REASON.CODE_CANCEL_REASON.' ||
                                                                                                                   pk_cancel_reason.c_reason_patient_death),
                                                                   i_notes       => NULL,
                                                                   i_flg_confirm => pk_alert_constant.g_yes,
                                                                   o_error       => o_error);
                    
                        IF l_return = FALSE
                        THEN
                            l_msg_error_func := REPLACE(pk_message.get_message(i_lang, 'MEDICATION_DEATH_0001'),
                                                        '@1',
                                                        pk_api_pfh_in.get_prod_desc_by_presc(i_lang     => i_lang,
                                                                                             i_prof     => i_prof,
                                                                                             i_id_presc => i_task_list(i)));
                        END IF;
                    
                    END IF;
                
                WHEN g_flgcontext_io THEN
                    -- #########################################################
                    -- #### Intake and output
                    -- #########################################################
                
                    -- SUSP_TASK_* insertion. Tests for integrity (otherwise an ID that doesn't exist could be inserted in the table)
                    g_error := 'INS SUSP_TASK_SP';
                    alertlog.pk_alertlog.log_info(text            => g_error,
                                                  object_name     => g_package_name,
                                                  sub_object_name => l_func_name);
                    BEGIN
                        ts_susp_task_fluid_balance.ins(id_susp_task_in    => l_susp_task,
                                                       id_epis_hidrics_in => i_task_list(i),
                                                       rows_out           => l_rows);
                        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'SUSP_TASK_FLUID_BALANCE',
                                                      i_rowids     => l_rows,
                                                      o_error      => o_error);
                    EXCEPTION
                        WHEN OTHERS THEN
                            l_proceed         := FALSE;
                            l_msg_error_total := l_msg_error_total || g_line_break ||
                                                 pk_message.get_message(i_lang      => i_lang,
                                                                        i_code_mess => 'WORKFLOW_WARNING_M021');
                            g_error           := 'ERROR INS SUSP_TASK_SP WITH L_MSG_ERROR_TOTAL: ' || l_msg_error_total;
                            alertlog.pk_alertlog.log_error(text            => g_error,
                                                           object_name     => g_package_name,
                                                           sub_object_name => l_func_name);
                            ROLLBACK;
                    END;
                
                    IF l_proceed
                    THEN
                    
                        COMMIT;
                    
                        -- calls function for the corresponding area
                        g_error := 'FUNCTION pk_inp_hidrics_pbl.suspend_task_hidric';
                    
                        alertlog.pk_alertlog.log_info(text            => g_error,
                                                      object_name     => g_package_name,
                                                      sub_object_name => l_func_name);
                        l_return := pk_inp_hidrics_pbl.suspend_task_hidric(i_lang       => i_lang,
                                                                           i_prof       => i_prof,
                                                                           i_id_task    => i_task_list(i),
                                                                           i_flg_reason => i_flg_reason,
                                                                           o_msg_error  => l_msg_error_func,
                                                                           o_error      => o_error);
                    END IF;
                
                WHEN g_flgcontext_monit THEN
                
                    -- #########################################################
                    -- #### Monitorizations
                    -- #########################################################
                
                    -- SUSP_TASK_* insertion. Tests for integrity (otherwise an ID that doesn't exist could be inserted in the table)
                    g_error := 'INS SUSP_TASK_SP';
                    alertlog.pk_alertlog.log_info(text            => g_error,
                                                  object_name     => g_package_name,
                                                  sub_object_name => l_func_name);
                    BEGIN
                        ts_susp_task_monitoring.ins(id_susp_task_in      => l_susp_task,
                                                    id_monitorization_in => i_task_list(i),
                                                    rows_out             => l_rows);
                        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'SUSP_TASK_MONITORING',
                                                      i_rowids     => l_rows,
                                                      o_error      => o_error);
                    EXCEPTION
                        WHEN OTHERS THEN
                            l_proceed         := FALSE;
                            l_msg_error_total := l_msg_error_total || g_line_break ||
                                                 pk_message.get_message(i_lang      => i_lang,
                                                                        i_code_mess => 'WORKFLOW_WARNING_M021');
                            g_error           := 'ERROR INS SUSP_TASK_SP WITH L_MSG_ERROR_TOTAL: ' || l_msg_error_total;
                            alertlog.pk_alertlog.log_error(text            => g_error,
                                                           object_name     => g_package_name,
                                                           sub_object_name => l_func_name);
                            ROLLBACK;
                    END;
                
                    IF l_proceed
                    THEN
                    
                        COMMIT;
                    
                        -- calls function for the corresponding area
                        g_error := 'FUNCTION pk_monitorization.suspend_task_monit';
                    
                        alertlog.pk_alertlog.log_info(text            => g_error,
                                                      object_name     => g_package_name,
                                                      sub_object_name => l_func_name);
                        l_return := pk_monitorization.suspend_task_monit(i_lang       => i_lang,
                                                                         i_prof       => i_prof,
                                                                         i_task       => i_task_list(i),
                                                                         i_flg_reason => i_flg_reason,
                                                                         o_msg_error  => l_msg_error_func,
                                                                         o_error      => o_error);
                    END IF;
                
                WHEN g_flgcontext_transp THEN
                
                    -- #########################################################
                    -- #### Movements/Transports
                    -- #########################################################
                
                    -- SUSP_TASK_* insertion. Tests for integrity (otherwise an ID that doesn't exist could be inserted in the table)
                    g_error := 'INS SUSP_TASK_SP';
                    alertlog.pk_alertlog.log_info(text            => g_error,
                                                  object_name     => g_package_name,
                                                  sub_object_name => l_func_name);
                    BEGIN
                        ts_susp_task_movements.ins(id_susp_task_in => l_susp_task,
                                                   id_movement_in  => i_task_list(i),
                                                   rows_out        => l_rows);
                    
                        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'SUSP_TASK_MOVEMENTS',
                                                      i_rowids     => l_rows,
                                                      o_error      => o_error);
                    EXCEPTION
                        WHEN OTHERS THEN
                            l_proceed         := FALSE;
                            l_msg_error_total := l_msg_error_total || g_line_break ||
                                                 pk_message.get_message(i_lang      => i_lang,
                                                                        i_code_mess => 'WORKFLOW_WARNING_M021');
                            g_error           := 'ERROR INS SUSP_TASK_SP WITH L_MSG_ERROR_TOTAL: ' || l_msg_error_total;
                            alertlog.pk_alertlog.log_error(text            => g_error,
                                                           object_name     => g_package_name,
                                                           sub_object_name => l_func_name);
                            ROLLBACK;
                    END;
                
                    IF l_proceed
                    THEN
                    
                        COMMIT;
                    
                        -- calls function for the corresponding area
                        g_error := 'FUNCTION pk_movement.suspend_task_transp';
                    
                        alertlog.pk_alertlog.log_info(text            => g_error,
                                                      object_name     => g_package_name,
                                                      sub_object_name => l_func_name);
                        l_return := pk_movement.suspend_task_transp(i_lang       => i_lang,
                                                                    i_prof       => i_prof,
                                                                    i_task       => i_task_list(i),
                                                                    i_flg_reason => i_flg_reason,
                                                                    o_msg_error  => l_msg_error_func,
                                                                    o_error      => o_error);
                    END IF;
                
                WHEN g_flgcontext_posit THEN
                
                    -- #########################################################
                    -- #### Positionings
                    -- #########################################################
                
                    -- SUSP_TASK_* insertion. Tests for integrity (otherwise an ID that doesn't exist could be inserted in the table)
                    g_error := 'INS SUSP_TASK_SP';
                    alertlog.pk_alertlog.log_info(text            => g_error,
                                                  object_name     => g_package_name,
                                                  sub_object_name => l_func_name);
                    BEGIN
                        ts_susp_task_positioning.ins(id_susp_task_in        => l_susp_task,
                                                     id_epis_positioning_in => i_task_list(i),
                                                     rows_out               => l_rows);
                    
                        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'SUSP_TASK_POSITIONING',
                                                      i_rowids     => l_rows,
                                                      o_error      => o_error);
                    EXCEPTION
                        WHEN OTHERS THEN
                            l_proceed         := FALSE;
                            l_msg_error_total := l_msg_error_total || g_line_break ||
                                                 pk_message.get_message(i_lang      => i_lang,
                                                                        i_code_mess => 'WORKFLOW_WARNING_M021');
                            g_error           := 'ERROR INS SUSP_TASK_SP WITH L_MSG_ERROR_TOTAL: ' || l_msg_error_total;
                            alertlog.pk_alertlog.log_error(text            => g_error,
                                                           object_name     => g_package_name,
                                                           sub_object_name => l_func_name);
                            ROLLBACK;
                    END;
                
                    IF l_proceed
                    THEN
                    
                        COMMIT;
                    
                        -- calls function for the corresponding area
                        g_error := 'FUNCTION pk_pbl_inp_positioning.suspend_task_posit';
                    
                        alertlog.pk_alertlog.log_info(text            => g_error,
                                                      object_name     => g_package_name,
                                                      sub_object_name => l_func_name);
                        l_return := pk_pbl_inp_positioning.suspend_task_posit(i_lang       => i_lang,
                                                                              i_prof       => i_prof,
                                                                              i_id_task    => i_task_list(i),
                                                                              i_flg_reason => i_flg_reason,
                                                                              o_msg_error  => l_msg_error_func,
                                                                              o_error      => o_error);
                    END IF;
                
                WHEN g_flgcontext_physio THEN
                    -- #########################################################
                    -- #### Physical therapy
                    -- #########################################################
                    g_error := 'Physical therapy';
                
                    -- SUSP_TASK_* insertion. Tests for integrity (otherwise an ID that doesn't exist could be inserted in the table)
                    g_error := 'INS SUSP_TASK_SP';
                    alertlog.pk_alertlog.log_info(text            => g_error,
                                                  object_name     => g_package_name,
                                                  sub_object_name => l_func_name);
                    BEGIN
                        ts_susp_task_physiotherapy.ins(id_susp_task_in        => l_susp_task,
                                                       id_interv_presc_det_in => i_task_list(i),
                                                       rows_out               => l_rows);
                    
                        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'SUSP_TASK_PHYSIOTHERAPY',
                                                      i_rowids     => l_rows,
                                                      o_error      => o_error);
                    EXCEPTION
                        WHEN OTHERS THEN
                            l_proceed         := FALSE;
                            l_msg_error_total := l_msg_error_total || g_line_break ||
                                                 pk_message.get_message(i_lang      => i_lang,
                                                                        i_code_mess => 'WORKFLOW_WARNING_M021');
                            g_error           := 'ERROR INS SUSP_TASK_SP WITH L_MSG_ERROR_TOTAL: ' || l_msg_error_total;
                            alertlog.pk_alertlog.log_error(text            => g_error,
                                                           object_name     => g_package_name,
                                                           sub_object_name => l_func_name);
                            ROLLBACK;
                    END;
                
                    IF l_proceed
                    THEN
                    
                        COMMIT;
                    
                        -- calls function for the corresponding area
                        g_error := 'FUNCTION pk_rehab_pbl.suspend_task_rehab';
                    
                        alertlog.pk_alertlog.log_info(text            => g_error,
                                                      object_name     => g_package_name,
                                                      sub_object_name => l_func_name);
                        l_return := pk_rehab_pbl.suspend_task_rehab(i_lang           => i_lang,
                                                                    i_prof           => i_prof,
                                                                    i_id_rehab_presc => i_task_list(i),
                                                                    i_flg_reason     => i_flg_reason,
                                                                    o_msg_error      => l_msg_error_func,
                                                                    o_error          => o_error);
                    END IF;
                
                WHEN g_flgcontext_diets THEN
                    -- #########################################################
                    -- #### Diets
                    -- #########################################################
                    g_error := 'Diets';
                
                    -- SUSP_TASK_* insertion. Tests for integrity (otherwise an ID that doesn't exist could be inserted in the table)
                    g_error := 'INS SUSP_TASK_SP';
                    alertlog.pk_alertlog.log_info(text            => g_error,
                                                  object_name     => g_package_name,
                                                  sub_object_name => l_func_name);
                    BEGIN
                        ts_susp_task_diets.ins(id_susp_task_in     => l_susp_task,
                                               id_epis_diet_req_in => i_task_list(i),
                                               rows_out            => l_rows);
                    
                        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'SUSP_TASK_DIETS',
                                                      i_rowids     => l_rows,
                                                      o_error      => o_error);
                    EXCEPTION
                        WHEN OTHERS THEN
                            l_proceed         := FALSE;
                            l_msg_error_total := l_msg_error_total || g_line_break ||
                                                 pk_message.get_message(i_lang      => i_lang,
                                                                        i_code_mess => 'WORKFLOW_WARNING_M021');
                            g_error           := 'ERROR INS SUSP_TASK_SP WITH L_MSG_ERROR_TOTAL: ' || l_msg_error_total;
                            alertlog.pk_alertlog.log_error(text            => g_error,
                                                           object_name     => g_package_name,
                                                           sub_object_name => l_func_name);
                            ROLLBACK;
                    END;
                
                    IF l_proceed
                    THEN
                    
                        COMMIT;
                    
                        -- calls function for the corresponding area
                        g_error := 'FUNCTION pk_diet.suspend_task_diet';
                    
                        alertlog.pk_alertlog.log_info(text            => g_error,
                                                      object_name     => g_package_name,
                                                      sub_object_name => l_func_name);
                        l_return := pk_diet.suspend_task_diet(i_lang       => i_lang,
                                                              i_prof       => i_prof,
                                                              i_id_task    => i_task_list(i),
                                                              i_flg_reason => i_flg_reason,
                                                              o_msg_error  => l_msg_error_func,
                                                              o_error      => o_error);
                    END IF;
                
            --WHEN g_flgcontext_careplans THEN
            -- #########################################################
            -- #### Care Plans
            -- #########################################################
            --    g_error := 'Care Plans';
            
            END CASE;
        
            -- to rollback third party functions
            IF l_return = FALSE
            THEN
                g_error := 'ROLLBACK THIRD PARTY FUNCTIONS. RETURNED ERROR: ' || l_msg_error_func;
                alertlog.pk_alertlog.log_info(text            => g_error,
                                              object_name     => g_package_name,
                                              sub_object_name => l_func_name);
                ROLLBACK;
            END IF;
        
            IF l_proceed
            THEN
            
                --l_counter        := l_counter + 1;
                --l_msg_error_func := 'Erro' || l_counter;
                --IF MOD(l_counter, 2) <> 0
                --THEN
                --    l_return := FALSE;
                --ELSE
                --    l_return := TRUE;
                --END IF;
            
                -- Changes flg_status according to the value in l_return. Concatenates message to be shown to the user               
                g_error := 'FUNCTION suspension_status';
                alertlog.pk_alertlog.log_info(text            => g_error,
                                              object_name     => g_package_name,
                                              sub_object_name => l_func_name);
                IF NOT suspension_status(i_lang              => i_lang,
                                         i_return_suspension => l_return,
                                         i_msg_error         => l_msg_error_init,
                                         i_msg_error_func    => l_msg_error_func,
                                         o_msg_error         => l_msg_error_total,
                                         o_flg_status        => l_flg_status,
                                         o_error             => o_error)
                THEN
                    l_msg_error_total := l_msg_error_total || g_line_break ||
                                         pk_message.get_message(i_lang      => i_lang,
                                                                i_code_mess => 'WORKFLOW_WARNING_M021');
                    g_error           := 'ERROR FUNCTION suspension_status WITH L_MSG_ERROR_TOTAL: ' ||
                                         l_msg_error_total;
                    alertlog.pk_alertlog.log_error(text            => g_error,
                                                   object_name     => g_package_name,
                                                   sub_object_name => l_func_name);
                    l_flg_status := c_wfstatus_nsusp;
                    ROLLBACK;
                END IF;
            
                -- SUSP_TASK update of FLG_STATUS based on the outcome of the external suspension function called.
                g_error := 'UPD SUSP_TASK';
                alertlog.pk_alertlog.log_info(text            => g_error,
                                              object_name     => g_package_name,
                                              sub_object_name => l_func_name);
            
                BEGIN
                
                    ts_susp_task.upd(id_susp_task_in => l_susp_task, flg_status_in => l_flg_status, rows_out => l_rows);
                    t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'SUSP_TASK',
                                                  i_rowids     => l_rows,
                                                  o_error      => o_error);
                EXCEPTION
                    WHEN OTHERS THEN
                        l_msg_error_total := l_msg_error_total || g_line_break ||
                                             pk_message.get_message(i_lang      => i_lang,
                                                                    i_code_mess => 'WORKFLOW_WARNING_M021');
                        g_error           := 'ERROR UPD SUSP_TASK WITH L_MSG_ERROR_TOTAL: ' || l_msg_error_total;
                        alertlog.pk_alertlog.log_error(text            => g_error,
                                                       object_name     => g_package_name,
                                                       sub_object_name => l_func_name);
                        ROLLBACK;
                END;
            END IF;
        
            l_msg_error_init := l_msg_error_total;
        
            COMMIT;
        
        END LOOP;
    
        -- checks if there were errors. it there were no errors, it has to send NULL to the Flash so that the popup doesn't shows
        IF g_error_suspension = FALSE
        --AND l_proceed = TRUE
        THEN
            g_error     := 'HAS NO ERRORS. O_MSG_ERROR IS NULL.';
            o_msg_error := NULL;
        ELSE
            g_error     := 'HAS ERRORS. WILL RETURN O_MSG_ERROR.';
            o_msg_error := l_msg_error_total;
        END IF;
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => g_error || '-' || SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => get_package_owner,
                                              i_package  => get_package_name,
                                              i_function => get_function_name,
                                              o_error    => o_error);
            my_rollback;
            RETURN FALSE;
        
    END suspend_tasks_all;

    /*
    * Reactivate the suspended tasks selected by the professional from within exams, lab tests, schedules, etc.
    *
    * @param   I_LANG               language associated to the professional executing the request
    * @param   I_PROF               Professional type
    * @param   I_SUSP_TASK          Table of IDs from ID_SUSP_TASK
    * @param   I_TASK_LIST          Table of IDs from the corresponding task (e.g., for an imaging exam, it is the ID_EXAM_REQ_DET)
    * @param   I_AREA_LIST          Table of Areas from each one of the tasks in I_TASK_LIST
    * @param   O_MSG_ERROR          Message to send to the UX in case one of the functions has some kind of error
    * @param   O_ERROR              warning/error message
    *
    * @RETURN  TRUE if success, FALSE otherwise
    * @author  Rui de Sousa Neves
    * @version 2.6.0.3
    * @since   21-MAY-2010
    *
    */
    FUNCTION reactivate_tasks_all
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_susp_task IN table_number,
        i_task_list IN table_number,
        i_area_list IN table_varchar,
        o_msg_error OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'reactivate_tasks_all';
    
        l_return          BOOLEAN;
        l_susp_task       susp_task.id_susp_task%TYPE;
        l_flg_status      susp_task.flg_status%TYPE;
        l_rows            table_varchar := table_varchar();
        l_msg_error_init  VARCHAR2(4000 CHAR);
        l_msg_error_total VARCHAR2(4000 CHAR);
        l_msg_error_func  VARCHAR2(4000 CHAR);
        l_transaction_id  VARCHAR2(4000 CHAR);
    
        CURSOR c_susp_action(pid_susp_task susp_task.id_susp_task%TYPE) IS
            SELECT st.id_susp_action
              FROM susp_task st
             WHERE st.id_susp_task = pid_susp_task;
        l_susp_action susp_action.id_susp_action%TYPE;
    
    BEGIN
    
        IF i_susp_task.count = 0
           OR i_task_list.count = 0
           OR i_area_list.count = 0
        THEN
            RETURN TRUE;
        END IF;
    
        g_line_break := pk_message.get_message(i_lang => i_lang, i_code_mess => 'WORKFLOW_WARNING_M011');
    
        l_msg_error_init   := '<b>' || pk_message.get_message(i_lang => i_lang, i_code_mess => 'DEATH_REGISTRY_T013') ||
                              ':</b>';
        g_sysdate_tstz     := current_timestamp;
        g_error_suspension := FALSE;
    
        -- To get SUSP_ACTION, one of the SUSP_TASKs is enough
        g_error := 'GET SUSP_ACTION';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        l_susp_task := i_susp_task(1);
    
        g_error := 'OPEN c_susp_action';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        OPEN c_susp_action(l_susp_task);
        FETCH c_susp_action
            INTO l_susp_action;
        CLOSE c_susp_action;
    
        -- Update DT_REACTIVATION on SUSP_ACTION
        g_error := 'UPD SUSP_ACTION';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        BEGIN
            ts_susp_action.upd(id_susp_action_in  => l_susp_action,
                               dt_reactivation_in => g_sysdate_tstz,
                               flg_status_in      => c_wfstatus_reac,
                               rows_out           => l_rows);
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'SUSP_ACTION',
                                          i_rowids     => l_rows,
                                          o_error      => o_error);
        EXCEPTION
            WHEN OTHERS THEN
                g_error     := pk_message.get_message(i_lang => i_lang, i_code_mess => 'WORKFLOW_WARNING_M022');
                o_msg_error := g_error;
                alertlog.pk_alertlog.log_error(text            => g_error,
                                               object_name     => g_package_name,
                                               sub_object_name => l_func_name);
                ROLLBACK;
                RETURN TRUE;
        END;
    
        COMMIT;
    
        -- Cycle to run all tasks that the user wishes to reactive.
        FOR i IN 1 .. i_task_list.count
        LOOP
        
            -- Function to reactivate, specific for each area.
            CASE i_area_list(i)
                WHEN g_flgcontext_labs THEN
                    -- #########################################################
                    -- #### Lab tests
                    -- #########################################################                
                    g_error := 'FUNCTION pk_lab_tests_external_api_db.reactivate_task_lab_tests';
                    alertlog.pk_alertlog.log_info(text            => g_error,
                                                  object_name     => g_package_name,
                                                  sub_object_name => l_func_name);
                    l_return := pk_lab_tests_external_api_db.reactivate_lab_test_task(i_lang      => i_lang,
                                                                                      i_prof      => i_prof,
                                                                                      i_id_task   => i_task_list(i),
                                                                                      o_msg_error => l_msg_error_func,
                                                                                      o_error     => o_error);
                
                WHEN g_flgcontext_imaging THEN
                    -- #########################################################
                    -- #### Imaging and other exams
                    -- #########################################################                                
                    g_error := 'FUNCTION pk_exams_external_api_db.reactivate_task_exams';
                    alertlog.pk_alertlog.log_info(text            => g_error,
                                                  object_name     => g_package_name,
                                                  sub_object_name => l_func_name);
                    l_return := pk_exams_external_api_db.reactivate_exam_task(i_lang      => i_lang,
                                                                              i_prof      => i_prof,
                                                                              i_id_task   => i_task_list(i),
                                                                              o_msg_error => l_msg_error_func,
                                                                              o_error     => o_error);
                
                WHEN g_flgcontext_procedures THEN
                    -- #########################################################
                    -- #### Procedures
                    -- #########################################################                                
                    g_error := 'FUNCTION pk_procedures_external_api_db.reactivate_procedure_task';
                    alertlog.pk_alertlog.log_info(text            => g_error,
                                                  object_name     => g_package_name,
                                                  sub_object_name => l_func_name);
                    l_return := pk_procedures_external_api_db.reactivate_procedure_task(i_lang      => i_lang,
                                                                                        i_prof      => i_prof,
                                                                                        i_id_task   => i_task_list(i),
                                                                                        o_msg_error => l_msg_error_func,
                                                                                        o_error     => o_error);
                
                WHEN g_flgcontext_schedules THEN
                    -- #########################################################
                    -- #### Schedules
                    -- #########################################################                
                
                    g_error := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
                    alertlog.pk_alertlog.log_info(text            => g_error,
                                                  object_name     => g_package_name,
                                                  sub_object_name => l_func_name);
                    l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(NULL, i_prof);
                
                    g_error := 'FUNCTION pk_schedule.reactivate_task_scheduler';
                    alertlog.pk_alertlog.log_info(text            => g_error,
                                                  object_name     => g_package_name,
                                                  sub_object_name => l_func_name);
                    l_return := pk_schedule.reactivate_task_scheduler(i_lang           => i_lang,
                                                                      i_prof           => i_prof,
                                                                      i_id_task        => i_task_list(i),
                                                                      i_transaction_id => l_transaction_id,
                                                                      o_msg_error      => l_msg_error_func,
                                                                      o_error          => o_error);
                    -- In case scheduler fails, transaction must be rollbacked.
                    IF l_return = FALSE
                    THEN
                        g_error := 'ROLLBACK ON SCHEDULER';
                        alertlog.pk_alertlog.log_info(text            => g_error,
                                                      object_name     => g_package_name,
                                                      sub_object_name => l_func_name);
                        pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
                    ELSE
                        -- If there is an open transaction on the scheduler, it must commit it.
                        BEGIN
                            g_error := 'COMMIT ON SCHEDULER';
                            alertlog.pk_alertlog.log_info(text            => g_error,
                                                          object_name     => g_package_name,
                                                          sub_object_name => l_func_name);
                            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
                            --l_transaction_id := NULL;
                        EXCEPTION
                            WHEN OTHERS THEN
                                l_return          := FALSE;
                                l_msg_error_total := l_msg_error_total || g_line_break ||
                                                     pk_message.get_message(i_lang      => i_lang,
                                                                            i_code_mess => 'WORKFLOW_WARNING_M023');
                                g_error           := 'COULDN''T COMMIT SCHEDULER. L_MSG_ERROR_TOTAL: ' ||
                                                     l_msg_error_total;
                                alertlog.pk_alertlog.log_error(text            => g_error,
                                                               object_name     => g_package_name,
                                                               sub_object_name => l_func_name);
                        END;
                    END IF;
                
                WHEN g_flgcontext_medication THEN
                    -- #########################################################
                    -- #### Medication
                    -- #########################################################     
                
                    g_error := 'FUNCTION pk_api_drug.reactivate_task_med_int';
                    alertlog.pk_alertlog.log_info(text            => g_error,
                                                  object_name     => g_package_name,
                                                  sub_object_name => l_func_name);
                    l_return := pk_api_pfh_in.reactivate_presc(i_lang      => i_lang,
                                                               i_prof      => i_prof,
                                                               i_id_presc  => i_task_list(i),
                                                               o_msg_error => l_msg_error_func,
                                                               o_error     => o_error);
                
                WHEN g_flgcontext_io THEN
                    -- #########################################################
                    -- #### Intake and output
                    -- #########################################################                                
                    g_error := 'FUNCTION pk_inp_hidrics_pbl.reactivate_task_hidric';
                    alertlog.pk_alertlog.log_info(text            => g_error,
                                                  object_name     => g_package_name,
                                                  sub_object_name => l_func_name);
                    l_return := pk_inp_hidrics_pbl.reactivate_task_hidric(i_lang      => i_lang,
                                                                          i_prof      => i_prof,
                                                                          i_id_task   => i_task_list(i),
                                                                          o_msg_error => l_msg_error_func,
                                                                          o_error     => o_error);
                WHEN g_flgcontext_monit THEN
                    -- #########################################################
                    -- #### Monitorizations
                    -- #########################################################                                
                    g_error := 'FUNCTION pk_monitorization.reactivate_task_monit';
                    alertlog.pk_alertlog.log_info(text            => g_error,
                                                  object_name     => g_package_name,
                                                  sub_object_name => l_func_name);
                    l_return := pk_monitorization.reactivate_task_monit(i_lang      => i_lang,
                                                                        i_prof      => i_prof,
                                                                        i_task      => i_task_list(i),
                                                                        o_msg_error => l_msg_error_func,
                                                                        o_error     => o_error);
                WHEN g_flgcontext_transp THEN
                    -- #########################################################
                    -- #### Movements
                    -- #########################################################                                
                    g_error := 'FUNCTION pk_movement.reactivate_task_transp';
                    alertlog.pk_alertlog.log_info(text            => g_error,
                                                  object_name     => g_package_name,
                                                  sub_object_name => l_func_name);
                    l_return := pk_movement.reactivate_task_transp(i_lang      => i_lang,
                                                                   i_prof      => i_prof,
                                                                   i_task      => i_task_list(i),
                                                                   o_msg_error => l_msg_error_func,
                                                                   o_error     => o_error);
                
                WHEN g_flgcontext_posit THEN
                    -- #########################################################
                    -- #### Positionings
                    -- #########################################################                                
                
                    g_error := 'FUNCTION pk_pbl_inp_positioning.reactivate_task_posit';
                    alertlog.pk_alertlog.log_info(text            => g_error,
                                                  object_name     => g_package_name,
                                                  sub_object_name => l_func_name);
                    l_return := pk_pbl_inp_positioning.reactivate_task_posit(i_lang      => i_lang,
                                                                             i_prof      => i_prof,
                                                                             i_id_task   => i_task_list(i),
                                                                             o_msg_error => l_msg_error_func,
                                                                             o_error     => o_error);
                
                WHEN g_flgcontext_physio THEN
                    -- #########################################################
                    -- #### Physical therapy
                    -- #########################################################                                
                    g_error := 'FUNCTION pk_rehab_pbl.reactivate_task_rehab';
                
                    alertlog.pk_alertlog.log_info(text            => g_error,
                                                  object_name     => g_package_name,
                                                  sub_object_name => l_func_name);
                    l_return := pk_rehab_pbl.reactivate_task_rehab(i_lang           => i_lang,
                                                                   i_prof           => i_prof,
                                                                   i_id_rehab_presc => i_task_list(i),
                                                                   o_msg_error      => l_msg_error_func,
                                                                   o_error          => o_error);
                
                WHEN g_flgcontext_diets THEN
                    -- #########################################################
                    -- #### Diets
                    -- #########################################################                                
                    g_error := 'FUNCTION pk_diet.reactivate_task_diet';
                
                    alertlog.pk_alertlog.log_info(text            => g_error,
                                                  object_name     => g_package_name,
                                                  sub_object_name => l_func_name);
                    l_return := pk_diet.reactivate_task_diet(i_lang      => i_lang,
                                                             i_prof      => i_prof,
                                                             i_id_task   => i_task_list(i),
                                                             o_msg_error => l_msg_error_func,
                                                             o_error     => o_error);
                
            --WHEN g_flgcontext_careplans THEN
            -- #########################################################
            -- #### Care plans
            -- #########################################################                                
            --g_error := 'FUNCTION reactivate_task_sp';
            
            END CASE;
        
            --l_counter        := l_counter + 1;
            --l_msg_error_func := 'Erro' || l_counter;
            --IF MOD(l_counter, 2) <> 0
            --THEN
            --    l_return := FALSE;
            --ELSE
            --    l_return := TRUE;
            --END IF;
        
            -- to rollback functions
            IF l_return = FALSE
            THEN
                g_error := 'WILL ROLLBACK THIRD PARTY FUNCTIONS';
                alertlog.pk_alertlog.log_info(text            => g_error,
                                              object_name     => g_package_name,
                                              sub_object_name => l_func_name);
                ROLLBACK;
            END IF;
        
            -- Changes flg_status according to the value in l_return. Concatenates message to return to the UX.
            g_error := 'FUNCTION suspension_status';
            alertlog.pk_alertlog.log_info(text            => g_error,
                                          object_name     => g_package_name,
                                          sub_object_name => l_func_name);
            IF NOT suspension_status(i_lang                => i_lang,
                                     i_return_reactivation => l_return,
                                     i_msg_error           => l_msg_error_init,
                                     i_msg_error_func      => l_msg_error_func,
                                     o_msg_error           => l_msg_error_total,
                                     o_flg_status          => l_flg_status,
                                     o_error               => o_error)
            THEN
                l_msg_error_total := l_msg_error_total || g_line_break ||
                                     pk_message.get_message(i_lang => i_lang, i_code_mess => 'WORKFLOW_WARNING_M023');
                l_flg_status      := c_wfstatus_nreac;
                g_error           := 'ERROR ON FUNCTION suspension_status. L_MSG_ERROR_TOTAL: ' || l_msg_error_total;
                alertlog.pk_alertlog.log_error(text            => g_error,
                                               object_name     => g_package_name,
                                               sub_object_name => l_func_name);
                ROLLBACK;
            END IF;
        
            -- SUSP_TASK update on FLG_STATUS
            g_error := 'UPD SUSP_TASK';
            alertlog.pk_alertlog.log_info(text            => g_error,
                                          object_name     => g_package_name,
                                          sub_object_name => l_func_name);
            BEGIN
            
                ts_susp_task.upd(id_susp_task_in => i_susp_task(i), flg_status_in => l_flg_status, rows_out => l_rows);
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'SUSP_TASK',
                                              i_rowids     => l_rows,
                                              o_error      => o_error);
            EXCEPTION
                WHEN OTHERS THEN
                    l_msg_error_total := l_msg_error_total || g_line_break ||
                                         pk_message.get_message(i_lang      => i_lang,
                                                                i_code_mess => 'WORKFLOW_WARNING_M022');
                    g_error           := 'ERROR ON UPD SUSP_TASK. L_MSG_ERROR_TOTAL: ' || l_msg_error_total;
                    alertlog.pk_alertlog.log_error(text            => g_error,
                                                   object_name     => g_package_name,
                                                   sub_object_name => l_func_name);
                    ROLLBACK;
            END;
        
            l_msg_error_init := l_msg_error_total;
            COMMIT;
        
        END LOOP;
    
        -- checks if there were errors. it there were no errors, it has to send NULL to the Flash so that the popup doesn't shows
        IF g_error_suspension = FALSE
        THEN
            g_error     := 'HAS NO ERRORS.';
            o_msg_error := NULL;
        ELSE
            g_error     := 'HAS ERRORS.';
            o_msg_error := l_msg_error_total;
        END IF;
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => g_error || '-' || SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => get_package_owner,
                                              i_package  => get_package_name,
                                              i_function => get_function_name,
                                              o_error    => o_error);
            my_rollback;
            RETURN FALSE;
        
    END reactivate_tasks_all;

    /*
    * Updates the WF status according to what was returned on each area's specific function
    *
    * @param   I_LANG               language associated to the professional executing the request
    * @param   I_RETURN_SUSPENSION  Result of each area specific function: TRUE if success, FALSE otherwise
    * @param   I_RETURN_REACTIVATIONResult of each area specific function: TRUE if success, FALSE otherwise   
    * @param   I_MSG_ERROR          Original message
    * @param   I_MSG_ERROR_FUNC     Message returned by the specific funcion (from each area)
    * @param   O_MSG_ERROR          Result message (will only be different from I_MSG_ERROR if I_MSG_ERROR_FUNC is not NULL)
    * @param   O_FLG_STATUS         Return value for the FLG_STATUS
    * @param   O_ERROR              warning/error message
    *
    * @RETURN  TRUE if success, FALSE otherwise
    * @author  Rui de Sousa Neves
    * @version 2.6.0.3
    * @since   10-MAY-2010
    *
    */

    FUNCTION suspension_status
    (
        i_lang                IN language.id_language%TYPE,
        i_return_suspension   IN BOOLEAN DEFAULT NULL,
        i_return_reactivation IN BOOLEAN DEFAULT NULL,
        i_msg_error           IN VARCHAR2,
        i_msg_error_func      IN VARCHAR2,
        o_msg_error           OUT VARCHAR2,
        o_flg_status          OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name CONSTANT VARCHAR2(100 CHAR) := 'suspension_status';
    
    BEGIN
    
        g_line_break := pk_message.get_message(i_lang => i_lang, i_code_mess => 'WORKFLOW_WARNING_M011');
    
        IF i_return_suspension = FALSE
        THEN
        
            -- not suspended due to external errors
            g_error := 'STATUS NS';
            alertlog.pk_alertlog.log_info(text            => g_error,
                                          object_name     => g_package_name,
                                          sub_object_name => l_func_name);
        
            o_flg_status := c_wfstatus_nsusp;
        
            -- error message must be concatenated every in one single message to return to the UX
            g_error := 'STR CONCAT msg_error NS';
            alertlog.pk_alertlog.log_info(text            => g_error,
                                          object_name     => g_package_name,
                                          sub_object_name => l_func_name);
            o_msg_error := i_msg_error || g_line_break || i_msg_error_func;
        
            g_error_suspension := TRUE;
        
        ELSIF i_return_suspension = TRUE
        THEN
            -- suspended with success
            g_error := 'STATUS S';
            alertlog.pk_alertlog.log_info(text            => g_error,
                                          object_name     => g_package_name,
                                          sub_object_name => l_func_name);
            o_flg_status := c_wfstatus_susp;
        
            -- error message must be concatenated every in one single message to return to the UX
            g_error := 'STR CONCAT msg_error S';
            alertlog.pk_alertlog.log_info(text            => g_error,
                                          object_name     => g_package_name,
                                          sub_object_name => l_func_name);
            o_msg_error := i_msg_error;
        
        ELSIF i_return_reactivation = FALSE
        THEN
            -- not reactivated due to external errors
            g_error := 'STATUS NR';
            alertlog.pk_alertlog.log_info(text            => g_error,
                                          object_name     => g_package_name,
                                          sub_object_name => l_func_name);
        
            o_flg_status := c_wfstatus_nreac;
        
            -- error message must be concatenated every in one single message to return to the UX
            g_error := 'STR CONCAT msg_error NR';
            alertlog.pk_alertlog.log_info(text            => g_error,
                                          object_name     => g_package_name,
                                          sub_object_name => l_func_name);
            o_msg_error := i_msg_error || g_line_break || i_msg_error_func;
        
            g_error_suspension := TRUE;
        
        ELSIF i_return_reactivation = TRUE
        THEN
            -- reactivated with success
            g_error := 'STATUS R';
            alertlog.pk_alertlog.log_info(text            => g_error,
                                          object_name     => g_package_name,
                                          sub_object_name => l_func_name);
            o_flg_status := c_wfstatus_reac;
        
            -- error message must be concatenated every in one single message to return to the UX
            g_error := 'STR CONCAT msg_error R';
            alertlog.pk_alertlog.log_info(text            => g_error,
                                          object_name     => g_package_name,
                                          sub_object_name => l_func_name);
            o_msg_error := i_msg_error;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => g_error || '-' || SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => get_package_owner,
                                              i_package  => get_package_name,
                                              i_function => get_function_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END suspension_status;

    /*
    * Provide list of reactivatable LAB tasks for the patient death feature. All the labs must have been suspended due to death and must not have been marked as canceled or finalized.
    *
    * @param   I_LANG               language associated to the professional executing the request
    * @param   I_PROF               Professional type
    * @param   I_ID_SUSP_ACTION     Corresponding ID_SUSP_ACTION
    * @param   I_WFSTATUS           Pretended WF Status (from the SUSP_TASK table)
    *
    * @RETURN  tf_tasks_list (table of tr_tasks_list)
    * @author  Rui de Sousa Neves
    * @version 2.6.0.3
    * @since   18-MAY-2010
    *
    */
    FUNCTION get_wfstatus_tasks_labs
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_susp_action IN susp_task.id_susp_action%TYPE,
        i_wfstatus       IN susp_task.flg_status%TYPE
    ) RETURN tf_tasks_react_list IS
    
        l_func_name CONSTANT VARCHAR2(100 CHAR) := 'get_wfstatus_tasks_labs';
    
        t tf_tasks_react_list;
        l_code_epis_type CONSTANT VARCHAR2(30 CHAR) := 'EPIS_TYPE.CODE_EPIS_TYPE.';
    
    BEGIN
        g_error := 'SELECT';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        SELECT tr_tasks_react_list(id_task, id_susp_task, desc_task, epis_type, dt_task)
          BULK COLLECT
          INTO t
          FROM (SELECT stl.id_analysis_req_det id_task,
                       st.id_susp_task,
                       pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                 i_prof,
                                                                 'A',
                                                                 'ANALYSIS.CODE_ANALYSIS.' || ltea.id_analysis,
                                                                 NULL) desc_task,
                       pk_translation.get_translation(i_lang, l_code_epis_type || e.id_epis_type) epis_type,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, ltea.dt_req, i_prof) dt_task
                  FROM susp_task st
                 INNER JOIN susp_task_lab stl
                    ON stl.id_susp_task = st.id_susp_task
                 INNER JOIN lab_tests_ea ltea
                    ON ltea.id_analysis_req_det = stl.id_analysis_req_det
                 INNER JOIN episode e
                    ON e.id_episode = ltea.id_episode
                 WHERE st.id_susp_action = i_id_susp_action
                   AND st.flg_status = i_wfstatus
                 ORDER BY dt_task DESC);
    
        RETURN t;
    
    END get_wfstatus_tasks_labs;

    /*
    * Provide list of reactivatable I&OE tasks for the patient death feature. All the I&OExams must have been suspended due to death and must not have been marked as canceled or finalized.
    *
    * @param   I_LANG               language associated to the professional executing the request
    * @param   I_PROF               Professional type
    * @param   I_ID_SUSP_ACTION     Corresponding ID_SUSP_ACTION
    * @param   I_WFSTATUS           Pretended WF Status (from the SUSP_TASK table)
    *
    * @RETURN  tf_tasks_list (table of tr_tasks_list)
    * @author  Rui de Sousa Neves
    * @version 2.6.0.3
    * @since   18-MAY-2010
    *
    */
    FUNCTION get_wfstatus_tasks_ioe
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_susp_action IN susp_task.id_susp_action%TYPE,
        i_wfstatus       IN susp_task.flg_status%TYPE
    ) RETURN tf_tasks_react_list IS
    
        l_func_name CONSTANT VARCHAR2(100 CHAR) := 'get_wfstatus_tasks_ioe';
    
        t tf_tasks_react_list;
        l_code_epis_type CONSTANT VARCHAR2(30 CHAR) := 'EPIS_TYPE.CODE_EPIS_TYPE.';
    
    BEGIN
        g_error := 'SELECT';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        SELECT tr_tasks_react_list(id_task, id_susp_task, desc_task, epis_type, dt_task)
          BULK COLLECT
          INTO t
          FROM (SELECT sti.id_exam_req_det id_task,
                       st.id_susp_task,
                       pk_exams_api_db.get_alias_translation(i_lang, i_prof, 'EXAM.CODE_EXAM.' || eea.id_exam, NULL) desc_task,
                       pk_translation.get_translation(i_lang, l_code_epis_type || e.id_epis_type) epis_type,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, eea.dt_req, i_prof) dt_task
                  FROM susp_task st
                 INNER JOIN susp_task_image_o_exams sti
                    ON sti.id_susp_task = st.id_susp_task
                 INNER JOIN exams_ea eea
                    ON eea.id_exam_req_det = sti.id_exam_req_det
                 INNER JOIN episode e
                    ON e.id_episode = eea.id_episode
                 WHERE st.id_susp_action = i_id_susp_action
                   AND st.flg_status = i_wfstatus
                 ORDER BY dt_task DESC);
    
        RETURN t;
    
    END get_wfstatus_tasks_ioe;

    /*
    * Provide list of reactivatable PROCEDURES tasks for the patient death feature. All the procedures must have been suspended due to death and must not have been marked as canceled or finalized.
    *
    * @param   I_LANG               language associated to the professional executing the request
    * @param   I_PROF               Professional type
    * @param   I_ID_SUSP_ACTION     Corresponding ID_SUSP_ACTION
    * @param   I_WFSTATUS           Pretended WF Status (from the SUSP_TASK table)
    *
    * @RETURN  tf_tasks_list (table of tr_tasks_list)
    * @author  Rui de Sousa Neves
    * @version 2.6.0.3
    * @since   18-MAY-2010
    *
    */
    FUNCTION get_wfstatus_tasks_proc
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_susp_action IN susp_task.id_susp_action%TYPE,
        i_wfstatus       IN susp_task.flg_status%TYPE
    ) RETURN tf_tasks_react_list IS
        l_func_name CONSTANT VARCHAR2(100 CHAR) := 'get_wfstatus_tasks_proc';
    
        t tf_tasks_react_list;
        l_code_epis_type CONSTANT VARCHAR2(30 CHAR) := 'EPIS_TYPE.CODE_EPIS_TYPE.';
    
    BEGIN
        g_error := 'SELECT';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        SELECT tr_tasks_react_list(id_task, id_susp_task, desc_task, epis_type, dt_task)
          BULK COLLECT
          INTO t
          FROM (SELECT stp.id_interv_presc_det id_task,
                       st.id_susp_task,
                       pk_translation.get_translation(i_lang, i.code_intervention) desc_task,
                       pk_translation.get_translation(i_lang, l_code_epis_type || e.id_epis_type) epis_type,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, pea.dt_interv_prescription, i_prof) dt_task
                  FROM susp_task st
                 INNER JOIN susp_task_procedures stp
                    ON stp.id_susp_task = st.id_susp_task
                 INNER JOIN procedures_ea pea
                    ON pea.id_interv_presc_det = stp.id_interv_presc_det
                 INNER JOIN episode e
                    ON e.id_episode = nvl(pea.id_episode, pea.id_episode_origin)
                 INNER JOIN intervention i
                    ON i.id_intervention = pea.id_intervention
                 WHERE st.id_susp_action = i_id_susp_action
                   AND st.flg_status = i_wfstatus
                 ORDER BY dt_task DESC);
    
        RETURN t;
    
    END get_wfstatus_tasks_proc;

    /*
    * Provide list of reactivatable SCHEDULE tasks for the patient death feature. All the schedule events must have been suspended due to death and must not have been marked as canceled or finalized.
    *
    * @param   I_LANG               language associated to the professional executing the request
    * @param   I_PROF               Professional type
    * @param   I_ID_SUSP_ACTION     Corresponding ID_SUSP_ACTION
    * @param   I_WFSTATUS           Pretended WF Status (from the SUSP_TASK table)
    *
    * @RETURN  tf_tasks_list (table of tr_tasks_list)
    * @author  Rui de Sousa Neves
    * @version 2.6.0.3
    * @since   18-MAY-2010
    *
    */
    FUNCTION get_wfstatus_tasks_sch
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_susp_action IN susp_task.id_susp_action%TYPE,
        i_wfstatus       IN susp_task.flg_status%TYPE
    ) RETURN tf_tasks_react_list IS
        l_func_name CONSTANT VARCHAR2(100 CHAR) := 'get_wfstatus_tasks_sch';
    
        t tf_tasks_react_list;
        l_code_epis_type CONSTANT VARCHAR2(30 CHAR) := 'EPIS_TYPE.CODE_EPIS_TYPE.';
    
    BEGIN
        g_error := 'SELECT';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        SELECT tr_tasks_react_list(id_task, id_susp_task, desc_task, epis_type, dt_task)
          BULK COLLECT
          INTO t
          FROM (SELECT sts.id_schedule id_task,
                       st.id_susp_task,
                       pk_schedule_common.get_translation_alias(i_lang, i_prof, se.id_sch_event, se.code_sch_event) ||
                       ' - ' || (SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service)
                                   FROM dep_clin_serv dcs
                                  INNER JOIN clinical_service cs
                                     ON dcs.id_clinical_service = cs.id_clinical_service
                                  WHERE dcs.id_dep_clin_serv = sch.id_dcs_requested) desc_task,
                       pk_translation.get_translation(i_lang,
                                                      l_code_epis_type ||
                                                      nvl((SELECT e.id_epis_type
                                                            FROM episode e
                                                           WHERE e.id_episode = ei.id_episode),
                                                          (SELECT so.id_epis_type
                                                             FROM schedule_outp so
                                                            WHERE so.id_schedule = sch.id_schedule))) epis_type,
                       pk_date_utils.date_time_chr_tsz(i_lang, sch.dt_schedule_tstz, i_prof) dt_task
                  FROM susp_task st
                 INNER JOIN susp_task_schedules sts
                    ON sts.id_susp_task = st.id_susp_task
                 INNER JOIN schedule sch
                    ON sch.id_schedule = sts.id_schedule
                 INNER JOIN sch_event se
                    ON sch.id_sch_event = se.id_sch_event
                  LEFT JOIN epis_info ei
                    ON sch.id_schedule = ei.id_schedule
                 WHERE st.id_susp_action = i_id_susp_action
                   AND st.flg_status = i_wfstatus);
    
        RETURN t;
    
    END get_wfstatus_tasks_sch;

    /*
    * Provide list of reactivatable HIDRIC tasks for the patient death feature. All the hidrics must have been suspended due to death and must not have been marked as canceled or finalized.
    *
    * @param   I_LANG               language associated to the professional executing the request
    * @param   I_PROF               Professional type
    * @param   I_ID_SUSP_ACTION     Corresponding ID_SUSP_ACTION
    * @param   I_WFSTATUS           Pretended WF Status (from the SUSP_TASK table)
    *
    * @RETURN  tf_tasks_list (table of tr_tasks_list)
    * @author  Rui de Sousa Neves
    * @version 2.6.0.3
    * @since   18-MAY-2010
    *
    */
    FUNCTION get_wfstatus_tasks_hidr
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_susp_action IN susp_task.id_susp_action%TYPE,
        i_wfstatus       IN susp_task.flg_status%TYPE
    ) RETURN tf_tasks_react_list IS
        l_func_name CONSTANT VARCHAR2(100 CHAR) := 'get_wfstatus_tasks_hidr';
    
        t tf_tasks_react_list;
    
    BEGIN
        g_error := 'SELECT';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        SELECT tr_tasks_react_list(id_task, id_susp_task, desc_task, epis_type, dt_task)
          BULK COLLECT
          INTO t
          FROM (SELECT eh.id_epis_hidrics id_task,
                       st.id_susp_task,
                       pk_translation.get_translation(i_lang, ht.code_hidrics_type) desc_task,
                       pk_translation.get_translation(i_lang, et.code_epis_type) epis_type,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang,
                                                          eh.dt_creation_tstz,
                                                          i_prof.institution,
                                                          i_prof.software) dt_task
                  FROM epis_hidrics eh
                 INNER JOIN episode epi
                    ON (eh.id_episode = epi.id_episode)
                 INNER JOIN epis_type et
                    ON (et.id_epis_type = epi.id_epis_type)
                 INNER JOIN hidrics_type ht
                    ON (eh.id_hidrics_type = ht.id_hidrics_type)
                 INNER JOIN susp_task_fluid_balance stf
                    ON stf.id_epis_hidrics = eh.id_epis_hidrics
                 INNER JOIN susp_task st
                    ON st.id_susp_task = stf.id_susp_task
                --
                 WHERE st.id_susp_action = i_id_susp_action
                   AND st.flg_status = i_wfstatus
                 ORDER BY eh.dt_creation_tstz DESC);
    
        RETURN t;
    
    END get_wfstatus_tasks_hidr;

    /*
    * Provide list of reactivatable MEDICATION tasks for the patient death feature. All the meds must have been suspended due to death and must not have been marked as canceled or finalized.
    *
    * @param   I_LANG               language associated to the professional executing the request
    * @param   I_PROF               Professional type
    * @param   I_ID_SUSP_ACTION     Corresponding ID_SUSP_ACTION
    * @param   I_WFSTATUS           Pretended WF Status (from the SUSP_TASK table)
    *
    * @RETURN  tf_tasks_list (table of tr_tasks_list)
    * @author  Rui de Sousa Neves
    * @version 2.6.0.3
    * @since   18-MAY-2010
    *
    */
    FUNCTION get_wfstatus_tasks_med
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_susp_action IN susp_task.id_susp_action%TYPE,
        i_wfstatus       IN susp_task.flg_status%TYPE
    ) RETURN tf_tasks_react_list IS
        l_func_name CONSTANT VARCHAR2(100 CHAR) := 'get_wfstatus_tasks_med';
    
        t tf_tasks_react_list;
        l_code_epis_type CONSTANT VARCHAR2(30 CHAR) := 'EPIS_TYPE.CODE_EPIS_TYPE.';
    
    BEGIN
        g_error := 'SELECT';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        SELECT tr_tasks_react_list(id_task, id_susp_task, desc_task, epis_type, dt_task)
          BULK COLLECT
          INTO t
          FROM (SELECT /*+ opt_estimate(table med rows=1)*/
                 stm.id_drug_presc_det id_task,
                 st.id_susp_task,
                 med.desc_treat_manag desc_task,
                 pk_translation.get_translation(i_lang, l_code_epis_type || e.id_epis_type) epis_type,
                 pk_date_utils.dt_chr_date_hour_tsz(i_lang, med.last_dt, i_prof) dt_task
                  FROM susp_task st
                 INNER JOIN susp_task_medication stm
                    ON stm.id_susp_task = st.id_susp_task
                 INNER JOIN TABLE(pk_api_pfh_clindoc_in.get_drug_desc(i_lang, i_prof, stm.id_drug_presc_det)) med
                    ON stm.id_drug_presc_det = med.id_drug_presc_det
                 INNER JOIN episode e
                    ON e.id_episode = med.id_episode
                 WHERE st.id_susp_action = i_id_susp_action
                   AND st.flg_status = i_wfstatus
                 ORDER BY med.last_dt DESC);
    
        RETURN t;
    
    END get_wfstatus_tasks_med;

    /*
    * Provide list of reactivatable POSITIONINGS tasks for the patient death feature. All the positionings must have been suspended due to death and must not have been marked as canceled or finalized.
    *
    * @param   I_LANG               language associated to the professional executing the request
    * @param   I_PROF               Professional type
    * @param   I_ID_SUSP_ACTION     Corresponding ID_SUSP_ACTION
    * @param   I_WFSTATUS           Pretended WF Status (from the SUSP_TASK table)
    *
    * @RETURN  tf_tasks_list (table of tr_tasks_list)
    * @author  Rui de Sousa Neves
    * @version 2.6.0.3
    * @since   18-MAY-2010
    *
    */
    FUNCTION get_wfstatus_tasks_posit
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_susp_action IN susp_task.id_susp_action%TYPE,
        i_wfstatus       IN susp_task.flg_status%TYPE
    ) RETURN tf_tasks_react_list IS
        l_func_name CONSTANT VARCHAR2(100 CHAR) := 'get_wfstatus_tasks_posit';
    
        t tf_tasks_react_list;
    
    BEGIN
        g_error := 'SELECT';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        SELECT tr_tasks_react_list(id_task, id_susp_task, desc_task, epis_type, dt_task)
          BULK COLLECT
          INTO t
          FROM (SELECT ep.id_epis_positioning id_task,
                       st.id_susp_task,
                       pk_pbl_inp_positioning.get_all_posit_desc(i_lang, i_prof, ep.id_epis_positioning) desc_task,
                       pk_translation.get_translation(i_lang, et.code_epis_type) epis_type,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang,
                                                          ep.dt_creation_tstz,
                                                          i_prof.institution,
                                                          i_prof.software) dt_task
                  FROM episode epi
                 INNER JOIN epis_positioning ep
                    ON (ep.id_episode = epi.id_episode)
                 INNER JOIN epis_type et
                    ON (et.id_epis_type = epi.id_epis_type)
                 INNER JOIN susp_task_positioning stp
                    ON stp.id_epis_positioning = ep.id_epis_positioning
                 INNER JOIN susp_task st
                    ON stp.id_susp_task = st.id_susp_task
                 WHERE st.id_susp_action = i_id_susp_action
                   AND st.flg_status = i_wfstatus
                 ORDER BY ep.dt_creation_tstz DESC);
    
        RETURN t;
    
    END get_wfstatus_tasks_posit;

    /*
    * Provide list of reactivatable PHYSICAL THERAPY tasks for the patient death feature. All the positionings must have been suspended due to death and must not have been marked as canceled or finalized.
    *
    * @param   I_LANG               language associated to the professional executing the request
    * @param   I_PROF               Professional type
    * @param   I_ID_SUSP_ACTION     Corresponding ID_SUSP_ACTION
    * @param   I_WFSTATUS           Pretended WF Status (from the SUSP_TASK table)
    *
    * @RETURN  tf_tasks_list (table of tr_tasks_list)
    * @author  Rui de Sousa Neves
    * @version 2.6.0.3
    * @since   18-MAY-2010
    *
    */
    FUNCTION get_wfstatus_tasks_physio
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_susp_action IN susp_task.id_susp_action%TYPE,
        i_wfstatus       IN susp_task.flg_status%TYPE
    ) RETURN tf_tasks_react_list IS
        l_func_name CONSTANT VARCHAR2(100 CHAR) := 'get_wfstatus_tasks_physio';
    
        t tf_tasks_react_list;
    
    BEGIN
        g_error := 'SELECT';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        SELECT tr_tasks_react_list(id_task, id_susp_task, desc_task, epis_type, dt_task)
          BULK COLLECT
          INTO t
          FROM (SELECT stp.id_interv_presc_det id_task,
                       st.id_susp_task,
                       pk_translation.get_translation(i_lang, i.code_intervention) desc_task,
                       pk_episode.get_epis_type(i_lang, pea.id_episode) epis_type,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, pea.dt_interv_presc_det, i_prof) dt_task
                  FROM susp_task st
                 INNER JOIN susp_task_physiotherapy stp
                    ON stp.id_susp_task = st.id_susp_task
                 INNER JOIN procedures_ea pea
                    ON pea.id_interv_presc_det = stp.id_interv_presc_det
                 INNER JOIN intervention i
                    ON pea.id_intervention = i.id_intervention
                 INNER JOIN episode e
                    ON e.id_episode = pea.id_episode
                 WHERE st.id_susp_action = i_id_susp_action
                   AND st.flg_status = i_wfstatus
                 ORDER BY dt_task DESC);
    
        RETURN t;
    
    END get_wfstatus_tasks_physio;

END pk_suspended_tasks;
/
