/*-- Last Change Revision: $Rev: 2054054 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2023-01-03 22:45:03 +0000 (ter, 03 jan 2023) $*/

CREATE OR REPLACE PACKAGE BODY pk_patient_education_cpoe IS
    -- Private constant declarations
    g_cpoe_adm_extra_take CONSTANT sys_config.id_sys_config%TYPE := 'CPOE_EXTRA_TAKE';

    -- Private variable declarations

    /* CAN'T TOUCH THIS */
    g_error         VARCHAR2(1000 CHAR);
    g_package_owner VARCHAR2(30 CHAR);
    g_package_name  VARCHAR2(30 CHAR);

    g_sysdate_tstz TIMESTAMP WITH TIME ZONE;
    g_exception EXCEPTION;

    PROCEDURE set_first_obs
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) IS
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'CALL TO PK_VISIT.SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => pk_prof_utils.get_category(i_lang, i_prof),
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    END set_first_obs;

    PROCEDURE set_ti_log
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_id_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE,
        o_error            OUT t_error_out
    ) IS
    BEGIN
        IF NOT t_ti_log.ins_log(i_lang       => i_lang,
                                i_prof       => i_prof,
                                i_id_episode => i_episode,
                                i_flg_status => pk_alert_constant.g_active,
                                i_id_record  => i_id_nurse_tea_req,
                                i_flg_type   => pk_edis_summary.g_ti_log_nurse_tea,
                                o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    END set_ti_log;

    FUNCTION get_id_compositions
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE
    ) RETURN table_number IS
        l_ret               table_number;
        l_nurse_tea_req_max nurse_tea_req.id_nurse_tea_req%TYPE;
    BEGIN
    
        SELECT MAX(ntrd.id_nurse_tea_req_hist)
          INTO l_nurse_tea_req_max
          FROM nurse_tea_req_diag_hist ntrd
         WHERE ntrd.id_nurse_tea_req = i_nurse_tea_req;
    
        SELECT id
          BULK COLLECT
          INTO l_ret
          FROM (SELECT ntrd.id_composition id
                  FROM nurse_tea_req_diag_hist ntrd
                 WHERE ntrd.id_nurse_tea_req = i_nurse_tea_req
                   AND ntrd.id_composition IS NOT NULL
                   AND ntrd.id_nurse_tea_req_hist = l_nurse_tea_req_max);
    
        RETURN l_ret;
    END get_id_compositions;

    FUNCTION copy_to_draft
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN episode.id_episode%TYPE,
        i_task_request         IN cpoe_process_task.id_task_request%TYPE,
        i_task_start_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_task_end_timestamp   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_draft                OUT cpoe_process_task.id_task_request%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_draft          table_number;
        l_ntr            nurse_tea_req%ROWTYPE;
        l_id_composition table_number := table_number();
    
        l_flg_profile     profile_template.flg_profile%TYPE;
        l_sys_alert_event sys_alert_event%ROWTYPE;
    
    BEGIN
    
        l_flg_profile := nvl(pk_hand_off_core.get_flg_profile(i_lang, i_prof, NULL), '#');
    
        SELECT ntr.*
          INTO l_ntr
          FROM nurse_tea_req ntr
         WHERE ntr.id_nurse_tea_req = i_task_request;
    
        l_id_composition := get_id_compositions(i_lang => i_lang, i_prof => i_prof, i_nurse_tea_req => i_task_request);
    
        IF i_task_start_timestamp IS NOT NULL
        THEN
            l_ntr.dt_begin_tstz := i_task_start_timestamp;
        END IF;
    
        g_error := 'pk_patient_education_api_db.create_req / i_id_episode ' || i_episode || ' , copy_to_draft';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_patient_education_api_db.create_req(i_lang                  => i_lang,
                                                      i_prof                  => i_prof,
                                                      i_id_episode            => i_episode,
                                                      i_topics                => table_number(l_ntr.id_nurse_tea_topic),
                                                      i_compositions          => table_table_number(l_id_composition),
                                                      i_diagnoses             => NULL,
                                                      i_to_be_performed       => table_varchar(l_ntr.flg_time),
                                                      i_start_date            => table_varchar(pk_date_utils.date_send_tsz(i_lang,
                                                                                                                           l_ntr.dt_begin_tstz,
                                                                                                                           i_prof)),
                                                      i_notes                 => table_varchar(l_ntr.notes_req),
                                                      i_description           => table_clob(l_ntr.description),
                                                      i_order_recurr          => table_number(NULL), --TO DO -- temporary 1º fase
                                                      i_draft                 => pk_alert_constant.g_yes,
                                                      i_id_nurse_tea_req_sugg => NULL,
                                                      i_desc_topic_aux        => table_varchar(l_ntr.desc_topic_aux),
                                                      i_not_order_reason      => NULL,
                                                      o_id_nurse_tea_req      => l_draft,
                                                      o_error                 => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF l_flg_profile = pk_prof_utils.g_flg_profile_template_student
        THEN
            l_sys_alert_event.id_sys_alert    := pk_alert_constant.g_alert_cpoe_draft;
            l_sys_alert_event.id_software     := i_prof.software;
            l_sys_alert_event.id_institution  := i_prof.institution;
            l_sys_alert_event.id_episode      := i_episode;
            l_sys_alert_event.id_patient      := pk_episode.get_epis_patient(i_lang    => i_lang,
                                                                             i_prof    => i_prof,
                                                                             i_episode => i_episode);
            l_sys_alert_event.id_record       := i_episode;
            l_sys_alert_event.id_visit        := pk_visit.get_visit(i_episode => i_episode, o_error => o_error);
            l_sys_alert_event.dt_record       := current_timestamp;
            l_sys_alert_event.id_professional := pk_hand_off.get_episode_responsible(i_lang       => i_lang,
                                                                                     i_prof       => i_prof,
                                                                                     i_id_episode => i_episode,
                                                                                     o_error      => o_error);
        
            IF NOT pk_alerts.insert_sys_alert_event(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_sys_alert_event => l_sys_alert_event,
                                                    o_error           => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
        END IF;
    
        o_draft := l_draft(1);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'copy_to_draft',
                                              o_error);
        
            RETURN FALSE;
    END copy_to_draft;
    --
    /*************************************************************************************************/
    FUNCTION create_draft
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN nurse_tea_req.id_episode%TYPE,
        i_topics          IN table_number,
        i_compositions    IN table_table_number,
        i_diagnoses       IN table_clob,
        i_to_be_performed IN table_varchar,
        i_start_date      IN table_varchar,
        i_notes           IN table_varchar,
        i_description     IN table_clob,
        i_order_recurr    IN table_number,
        i_desc_topic_aux  IN table_varchar,
        o_draft           OUT table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_draft              table_number;
        l_id_nurse_tea_topic table_number;
        l_title_topic        table_varchar;
        l_desc_diagnosis     table_varchar;
    
    BEGIN
    
        g_error := 'Call pk_patient_education_api_db.create_request / i_id_episode ' || i_id_episode ||
                   ' ,create_draft';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_patient_education_api_db.create_request(i_lang                  => i_lang,
                                                          i_prof                  => i_prof,
                                                          i_id_episode            => i_id_episode,
                                                          i_topics                => i_topics,
                                                          i_compositions          => i_compositions,
                                                          i_to_be_performed       => i_to_be_performed,
                                                          i_start_date            => i_start_date,
                                                          i_notes                 => i_notes,
                                                          i_description           => i_description,
                                                          i_order_recurr          => i_order_recurr,
                                                          i_draft                 => pk_alert_constant.g_yes,
                                                          i_id_nurse_tea_req_sugg => NULL,
                                                          i_desc_topic_aux        => i_desc_topic_aux,
                                                          i_diagnoses             => i_diagnoses,
                                                          i_not_order_reason      => NULL,
                                                          o_id_nurse_tea_req      => l_draft,
                                                          o_id_nurse_tea_topic    => l_id_nurse_tea_topic,
                                                          o_title_topic           => l_title_topic,
                                                          o_desc_diagnosis        => l_desc_diagnosis,
                                                          o_error                 => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        o_draft := l_draft;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_DRAFT',
                                              o_error);
            RETURN FALSE;
    END create_draft;
    --
    /******************************************************************************************** 
    * activate draft tasks (task goes from draft to active workflow) 
    * 
    * @param       i_lang                 language id 
    * @param       i_prof                 professional id structure 
    * @param       i_episode              episode id  
    * @param       i_draft                array of draft requests  
    * @param       i_flg_commit           transaction control
    * @param       o_created_tasks        array of created taksk requests    
    * @param       o_error                error message 
    * 
    * @value       i_flg_commit           {*} 'Y' commit/rollback the transaction 
    *                                     {*} 'N' transaction control is done outside  
    *
    * @return                             true on success, otherwise false
    **********************************************************************************************/
    FUNCTION activate_drafts
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_draft         IN table_number,
        i_flg_commit    IN VARCHAR2,
        o_created_tasks OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rows     table_varchar := table_varchar();
        l_rows_ntr table_varchar;
        l_dt_begin nurse_tea_req.dt_begin_tstz%TYPE;
    
        l_order_recurr_plan nurse_tea_req.id_order_recurr_plan%TYPE;
    
    BEGIN
        o_created_tasks := i_draft;
    
        FOR i IN 1 .. i_draft.count
        LOOP
            g_sysdate_tstz := current_timestamp;
        
            SELECT ntr.dt_begin_tstz, ntr.id_order_recurr_plan
              INTO l_dt_begin, l_order_recurr_plan
              FROM nurse_tea_req ntr
             WHERE ntr.id_nurse_tea_req = i_draft(i);
        
            ts_nurse_tea_req.upd(id_nurse_tea_req_in      => i_draft(i),
                                 flg_status_in            => pk_patient_education_cpoe.g_nurse_tea_req_pend,
                                 id_prof_req_in           => i_prof.id,
                                 dt_begin_tstz_in         => CASE
                                                                 WHEN nvl(l_dt_begin, g_sysdate_tstz) < g_sysdate_tstz THEN
                                                                  g_sysdate_tstz
                                                                 ELSE
                                                                  nvl(l_dt_begin, g_sysdate_tstz)
                                                             END,
                                 dt_nurse_tea_req_tstz_in => g_sysdate_tstz,
                                 rows_out                 => l_rows_ntr);
            l_rows := l_rows MULTISET UNION l_rows_ntr;
        
            IF NOT pk_patient_education_api_db.create_execution(i_lang                  => i_lang,
                                                                i_prof                  => i_prof,
                                                                i_id_nurse_tea_req      => i_draft(i),
                                                                i_dt_start              => nvl(l_dt_begin, g_sysdate_tstz),
                                                                i_dt_nurse_tea_det_tstz => g_sysdate_tstz,
                                                                i_flg_status            => pk_patient_education_cpoe.g_nurse_tea_req_pend,
                                                                i_num_order             => 1,
                                                                o_error                 => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            g_error := 'Add to history';
            pk_patient_education_api_db.insert_ntr_hist(i_lang             => i_lang,
                                                        i_prof             => i_prof,
                                                        i_id_nurse_tea_req => i_draft(i),
                                                        o_error            => o_error);
        
            set_ti_log(i_lang             => i_lang,
                       i_prof             => i_prof,
                       i_episode          => i_episode,
                       i_id_nurse_tea_req => i_draft(i),
                       o_error            => o_error);
        
            IF NOT pk_cpoe.sync_task(i_lang                 => i_lang,
                                     i_prof                 => i_prof,
                                     i_episode              => i_episode,
                                     i_task_type            => pk_alert_constant.g_task_type_nursing,
                                     i_task_request         => i_draft(i),
                                     i_task_start_timestamp => l_dt_begin,
                                     o_error                => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
        END LOOP;
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'NURSE_TEA_REQ',
                                      i_rowids     => l_rows,
                                      o_error      => o_error);
        set_first_obs(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode, o_error => o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'ACTIVATE_DRAFTS',
                                              o_error);
            RETURN FALSE;
    END activate_drafts;

    --
    FUNCTION cancel_draft
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_draft   IN table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_nurse_tea_det table_number;
    BEGIN
        -- for each draft
        FOR i IN 1 .. i_draft.count
        LOOP
            -- get all associated detail records
            SELECT id_nurse_tea_det
              BULK COLLECT
              INTO l_id_nurse_tea_det
              FROM nurse_tea_det
             WHERE id_nurse_tea_req = i_draft(i);
            -- for each detail record                 
            FOR j IN 1 .. l_id_nurse_tea_det.count
            LOOP
                -- delete associated executions
                ts_nurse_tea_det_opt.del_by_col(colname_in => 'ID_NURSE_TEA_DET', colvalue_in => l_id_nurse_tea_det(j));
                -- delete associated detail record
                ts_nurse_tea_det.del(id_nurse_tea_det_in => l_id_nurse_tea_det(j));
            END LOOP;
            -- delete associated diagnoses history records
            ts_nurse_tea_req_diag_hist.del_by_col(colname_in => 'ID_NURSE_TEA_REQ', colvalue_in => i_draft(i));
            -- delete associated diagnoses records
            ts_nurse_tea_req_diag.del_by_col(colname_in => 'ID_NURSE_TEA_REQ', colvalue_in => i_draft(i));
            -- delete main requisition history records
            ts_nurse_tea_req_hist.del_by_col(colname_in => 'ID_NURSE_TEA_REQ', colvalue_in => i_draft(i));
            -- delete main requisition record 
            ts_nurse_tea_req.del(id_nurse_tea_req_in => i_draft(i));
        END LOOP;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_DRAFT',
                                              o_error);
            RETURN FALSE;
    END cancel_draft;
    --
    /**********************************************************************************************
    * cancel all draft tasks
    *
    * @param          i_lang              language id    
    * @param          i_prof              professional type
    * @param          i_episode           episode id
    * @param          o_error             error message
    *
    * @return         boolean             true on success, otherwise false
    **********************************************************************************************/
    FUNCTION cancel_all_drafts
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_drafts table_number;
    BEGIN
        g_error := 'Get episode''s draft tasks';
        SELECT ntr.id_nurse_tea_req
          BULK COLLECT
          INTO l_drafts
          FROM nurse_tea_req ntr
         WHERE ntr.id_episode IN (SELECT id_episode
                                    FROM episode
                                   WHERE id_visit = pk_episode.get_id_visit(i_episode))
           AND ntr.flg_status = pk_patient_education_cpoe.g_nurse_tea_req_draft;
    
        IF l_drafts.count > 0
        THEN
            IF NOT cancel_draft(i_lang    => i_lang,
                                i_prof    => i_prof,
                                i_episode => i_episode,
                                i_draft   => l_drafts,
                                o_error   => o_error)
            THEN
                RAISE g_exception;
            END IF;
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
                                              'CANCEL_ALL_DRAFTS',
                                              o_error);
            RETURN FALSE;
    END cancel_all_drafts;
    --
    /******************************************************************************************** 
    * Check conflicts upon created drafts (verify if drafts can be requested or not) 
    * 
    * @param       i_lang                    preferred language id for this professional 
    * @param       i_prof                    professional id structure 
    * @param       i_episode                 episode id  
    * @param       i_draft                   draft id 
    * @param       o_flg_conflict            array of draft conflicts indicators
    * @param       o_msg_template            array of message/pop-up templates
    * @param       o_msg_title               array of message titles 
    * @param       o_msg_body                array of message bodies
    * @param       o_error                   error message 
    * 
    * @value       o_flg_conflict            {*} 'Y' the draft has conflicts  
    *                                        {*} 'N' no conflicts found 
    *    
    * @value       o_msg_template            {*} ' WARNING_READ' Warning Read
    *                                        {*} 'WARNING_CONFIRMATION' Warning Confirmation
    *                                        {*} 'WARNING_CANCEL' Warning Cancel
    *                                        {*} 'WARNING_HELP_SAVE' Warning Help Save
    *                                        {*} 'WARNING_SECURITY' Warning Security
    *                                        {*} 'CONFIRMATION' Confirmation
    *                                        {*} 'DETAIL' Detail
    *                                        {*} 'HELP' Help
    *                                        {*} 'WIZARD' Wizard
    *                                        {*} 'ADVANCED_INPUT' Advanced Input
    *         
    * @return                                True on success, false otherwise
    ********************************************************************************************/
    FUNCTION check_draft_conflicts
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_draft        IN table_number,
        o_flg_conflict OUT table_varchar,
        o_msg_title    OUT table_varchar,
        o_msg_body     OUT table_varchar,
        o_msg_template OUT table_varchar,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_nurse_tea_req nurse_tea_req.id_nurse_tea_req%TYPE;
        l_flg_conflict     table_varchar;
        l_empty_array      table_varchar;
    
    BEGIN
        l_flg_conflict := table_varchar();
        l_empty_array  := table_varchar();
    
        FOR i IN 1 .. i_draft.count
        LOOP
            SELECT ntr.id_nurse_tea_req
              INTO l_id_nurse_tea_req
              FROM nurse_tea_req ntr
             WHERE ntr.id_nurse_tea_req = i_draft(i);
        
            l_empty_array.extend;
            l_flg_conflict.extend;
            l_flg_conflict(i) := pk_alert_constant.g_no;
        END LOOP;
    
        o_flg_conflict := l_flg_conflict;
        o_msg_title    := l_empty_array;
        o_msg_body     := l_empty_array;
        o_msg_template := l_empty_array;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_DRAFT_CONFLICTS',
                                              o_error);
            RETURN FALSE;
    END check_draft_conflicts;
    --
    FUNCTION get_task_actions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN cpoe_process_task.id_task_request%TYPE,
        o_action       OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_status nurse_tea_req.flg_status%TYPE;
        l_dt_close   nurse_tea_req.dt_close_tstz%TYPE;
    
    BEGIN
        SELECT ntr.flg_status, ntr.dt_close_tstz
          INTO l_flg_status, l_dt_close
          FROM nurse_tea_req ntr
         WHERE ntr.id_nurse_tea_req = i_task_request;
    
        -- Check the possibility to enable execution after the task was expired
        IF l_flg_status = pk_patient_education_constant.g_nurse_tea_req_expired
        THEN
            IF check_extra_take(i_lang         => i_lang,
                                i_prof         => i_prof,
                                i_task_request => i_task_request,
                                i_status       => l_flg_status,
                                i_dt_expire    => l_dt_close) = pk_alert_constant.g_no
            THEN
                -- No conditions to allow execution, so actions are the same as for a cancelled task
                l_flg_status := pk_patient_education_constant.g_nurse_tea_req_canc;
            END IF;
        
        END IF;
    
        RETURN pk_action.get_actions(i_lang       => i_lang,
                                     i_prof       => i_prof,
                                     i_subject    => 'PATIENT_EDUCATION',
                                     i_from_state => l_flg_status,
                                     o_actions    => o_action,
                                     o_error      => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TASK_ACTIONS',
                                              o_error);
            RETURN FALSE;
    END get_task_actions;
    -- 
    FUNCTION get_task_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_task_request  IN table_number,
        i_filter_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_filter_status IN table_varchar,
        i_flg_report    IN VARCHAR2 DEFAULT 'N',
        i_dt_begin      IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_dt_end        IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_plan_list     OUT pk_types.cursor_type,
        o_task_list     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_episode table_number;
    
        l_epis_type    epis_type.id_epis_type%TYPE;
        l_i_id_hhc_req epis_hhc_req.id_epis_hhc_req%TYPE;
        l_flg_can_edit VARCHAR2(1) := pk_alert_constant.g_yes;
    
    BEGIN
    
        l_i_id_hhc_req := pk_hhc_core.get_id_req_by_epis_hhc(i_lang => i_lang, i_id_episode => i_episode);
    
        IF l_i_id_hhc_req IS NULL
        THEN
            SELECT id_episode
              BULK COLLECT
              INTO l_id_episode
              FROM episode
             WHERE id_visit = pk_episode.get_id_visit(i_episode);
        ELSE
        
            SELECT t.id_episode
              BULK COLLECT
              INTO l_id_episode
              FROM (SELECT e.id_episode
                      FROM episode e
                     WHERE e.id_visit = pk_episode.get_id_visit(i_episode)
                    UNION
                    SELECT e.id_episode
                      FROM episode e
                     WHERE e.id_prev_episode IN (SELECT ehr.id_epis_hhc
                                                   FROM alert.epis_hhc_req ehr
                                                  WHERE ehr.id_episode = i_episode
                                                     OR ehr.id_epis_hhc_req = l_i_id_hhc_req)
                    UNION
                    SELECT ehr.id_epis_hhc
                      FROM alert.epis_hhc_req ehr
                     WHERE ehr.id_episode = i_episode
                        OR ehr.id_epis_hhc_req = l_i_id_hhc_req) t;
        
            IF i_episode IS NOT NULL
            THEN
                IF NOT pk_episode.get_epis_type(i_lang      => i_lang,
                                                i_id_epis   => i_episode,
                                                o_epis_type => l_epis_type,
                                                o_error     => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            END IF;
        
            IF l_epis_type IN (pk_alert_constant.g_epis_type_home_health_care, 99)
               OR l_i_id_hhc_req IS NOT NULL
            THEN
                IF NOT pk_hhc_ux.get_prof_can_edit(i_lang         => i_lang,
                                                   i_prof         => i_prof,
                                                   i_id_hhc_req   => l_i_id_hhc_req,
                                                   o_flg_can_edit => l_flg_can_edit,
                                                   o_error        => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            END IF;
        
        END IF;
    
        OPEN o_task_list FOR
            SELECT task_type,
                   t_ti_log.get_desc_with_origin(i_lang,
                                                 i_prof,
                                                 task_description,
                                                 pk_episode.get_epis_type(i_lang, id_episode),
                                                 flg_status,
                                                 id_request,
                                                 pk_icnp_constant.g_ti_log_type_interv) task_description,
                   id_professional,
                   icon_warning,
                   status_string,
                   id_request,
                   start_date_tstz,
                   end_date_tstz,
                   create_date_tstz,
                   flg_status,
                   flg_cancel,
                   flg_conflict,
                   id_task,
                   task_title,
                   task_instructions,
                   task_notes,
                   drug_dose,
                   drug_route,
                   drug_take_in_case,
                   task_status,
                   NULL AS instr_bg_color,
                   NULL AS instr_bg_alpha,
                   NULL AS task_icon,
                   pk_alert_constant.g_no AS flg_need_ack,
                   NULL AS edit_icon,
                   NULL AS action_desc,
                   NULL AS previous_status,
                   pk_alert_constant.g_task_patient_edu id_task_type_source,
                   NULL AS id_task_dependency,
                   decode(flg_status,
                          pk_patient_education_constant.g_nurse_tea_req_canc,
                          pk_alert_constant.g_yes,
                          pk_alert_constant.g_no) flg_rep_cancel,
                   NULL flg_prn_conditional
              FROM (SELECT pk_alert_constant.g_task_type_nursing task_type,
                           decode(ntr.id_nurse_tea_topic,
                                  1, --other
                                  nvl(ntr.desc_topic_aux,
                                      pk_translation.get_translation(i_lang,
                                                                     (SELECT ntt.code_nurse_tea_topic
                                                                        FROM nurse_tea_topic ntt
                                                                       WHERE ntt.id_nurse_tea_topic = ntr.id_nurse_tea_topic))),
                                  pk_translation.get_translation(i_lang,
                                                                 (SELECT ntt.code_nurse_tea_topic
                                                                    FROM nurse_tea_topic ntt
                                                                   WHERE ntt.id_nurse_tea_topic = ntr.id_nurse_tea_topic))) task_description,
                           ntr.id_prof_req id_professional,
                           NULL icon_warning,
                           pk_utils.get_status_string(i_lang,
                                                      i_prof,
                                                      ntr.status_str,
                                                      ntr.status_msg,
                                                      ntr.status_icon,
                                                      ntr.status_flg) status_string,
                           ntr.id_nurse_tea_req id_request,
                           nvl(ntr.dt_begin_tstz, ntr.dt_nurse_tea_req_tstz) start_date_tstz,
                           ntr.dt_close_tstz end_date_tstz,
                           ntr.dt_nurse_tea_req_tstz create_date_tstz,
                           ntr.flg_status flg_status,
                           decode(ntr.flg_status,
                                  pk_patient_education_constant.g_nurse_tea_req_canc,
                                  pk_alert_constant.get_no,
                                  pk_patient_education_constant.g_nurse_tea_req_fin,
                                  pk_alert_constant.get_no,
                                  pk_patient_education_constant.g_nurse_tea_req_expired,
                                  pk_alert_constant.g_no,
                                  pk_alert_constant.get_yes) flg_cancel,
                           pk_alert_constant.get_no flg_conflict,
                           pk_translation.get_translation(i_lang,
                                                          (SELECT ntt.code_nurse_tea_topic
                                                             FROM nurse_tea_topic ntt
                                                            WHERE ntt.id_nurse_tea_topic = ntr.id_nurse_tea_topic)) task_title,
                           decode(i_flg_report,
                                  pk_alert_constant.get_yes,
                                  nvl(pk_order_recurrence_api_db.get_order_recurr_plan_desc(i_lang,
                                                                                            i_prof,
                                                                                            ntr.id_order_recurr_plan),
                                      pk_translation.get_translation(i_lang,
                                                                     'ORDER_RECURR_OPTION.CODE_ORDER_RECURR_OPTION.0'))) task_instructions,
                           decode(i_flg_report,
                                  pk_alert_constant.get_yes,
                                  decode(ntr.notes_close,
                                         NULL,
                                         decode(ntr.notes_req, NULL, NULL, ntr.notes_req),
                                         decode(ntr.flg_status, 'C', ntr.notes_close))) task_notes,
                           NULL drug_dose,
                           NULL drug_route,
                           NULL drug_take_in_case,
                           decode(i_flg_report,
                                  pk_alert_constant.get_yes,
                                  pk_sysdomain.get_domain('NURSE_TEA_REQ.FLG_STATUS', ntr.flg_status, i_lang)) task_status,
                           nvl(ntr.dt_begin_tstz, ntr.dt_nurse_tea_req_tstz) TIMESTAMP,
                           pk_sysdomain.get_rank(i_lang, 'NURSE_TEA_REQ.FLG_STATUS', ntr.flg_status) rank,
                           ntr.id_episode,
                           ntr.id_nurse_tea_topic id_task
                      FROM nurse_tea_req ntr
                     WHERE ntr.id_patient = i_patient
                       AND ntr.id_episode IN (SELECT *
                                                FROM (TABLE(l_id_episode) x))
                    /*AND (i_task_request IS NULL OR
                        ntr.id_nurse_tea_req IN (SELECT \*+opt_estimate(table,t,scale_rows=0.000001) *\
                                                   column_value
                                                    FROM TABLE(i_task_request) t))
                    AND ((ntr.flg_status NOT IN (SELECT \*+opt_estimate(table,t,scale_rows=0.000001) *\
                                                  column_value
                                                   FROM TABLE(i_filter_status) t) AND
                        ntr.flg_status NOT IN (g_nurse_tea_req_ign, g_nurse_tea_req_sug)) OR
                        ((ntr.flg_status != pk_patient_education_constant.g_nurse_tea_req_not_ord_reas AND
                        ntr.dt_close_tstz >= i_filter_tstz) OR
                        (ntr.flg_status = pk_patient_education_constant.g_nurse_tea_req_not_ord_reas AND
                        ntr.dt_nurse_tea_req_tstz >= i_filter_tstz)))*/
                    )
             ORDER BY rank, TIMESTAMP;
    
        IF i_flg_report = pk_alert_constant.g_yes
        THEN
        
            IF NOT get_order_plan_report(i_lang          => i_lang,
                                         i_prof          => i_prof,
                                         i_episode       => i_episode,
                                         i_task_request  => i_task_request,
                                         i_cpoe_dt_begin => i_dt_begin,
                                         i_cpoe_dt_end   => i_dt_end,
                                         o_plan_rep      => o_plan_list,
                                         o_error         => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
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
                                              'GET_TASK_LIST',
                                              o_error);
            RETURN FALSE;
    END get_task_list;
    --
    FUNCTION get_task_parameters
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_draft  IN cpoe_process_task.id_cpoe_process%TYPE,
        o_params OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        OPEN o_params FOR
            SELECT ntr.id_nurse_tea_req,
                   ntr.notes_req,
                   pk_date_utils.date_send_tsz(i_lang, ntr.dt_begin_tstz, i_prof) dt_begin_str,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, ntr.dt_begin_tstz, i_prof) dt_begin,
                   pk_not_order_reason_db.get_not_order_reason_id(i_lang                => i_lang,
                                                                  i_id_not_order_reason => ntr.id_not_order_reason) not_order_reason_id,
                   pk_not_order_reason_db.get_not_order_reason_desc(i_lang             => i_lang,
                                                                    i_not_order_reason => ntr.id_not_order_reason) not_order_reason_desc
              FROM nurse_tea_req ntr
             WHERE ntr.id_nurse_tea_req = i_draft;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TASK_PARAMETERS',
                                              o_error);
            RETURN FALSE;
    END get_task_parameters;
    --
    /********************************************************************************************
    * get tasks status based in their requests
    *
    * @param       i_lang                 language id    
    * @param       i_prof                 professional structure
    * @param       i_episode              episode id
    * @param       i_task_request         array of requests that identifies the tasks
    * @param       o_task_status          cursor with all requested task status
    * @param       o_error                error structure for exception handling
    *
    * @return      boolean                true on success, otherwise false    
    ********************************************************************************************/
    FUNCTION get_task_status
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN table_number,
        o_task_status  OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'Open cursor o_task_status';
        OPEN o_task_status FOR
            SELECT pk_alert_constant.g_task_type_nursing id_task_type,
                   ntr.id_nurse_tea_req                  id_task_request,
                   ntr.flg_status                        flg_status
              FROM nurse_tea_req ntr
             WHERE ntr.id_nurse_tea_req IN (SELECT /*+opt_estimate(table,t,scale_rows=0.000001) */
                                             column_value
                                              FROM TABLE(i_task_request) t);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TASK_STATUS',
                                              o_error);
            RETURN FALSE;
    END get_task_status;
    --
    FUNCTION set_action
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_action       IN action.id_action%TYPE,
        i_task_request IN cpoe_process_task.id_task_request%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'NOT IMPLEMENTED';
        RETURN FALSE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ACTION',
                                              o_error);
            RETURN FALSE;
    END set_action;
    --
    FUNCTION set_task_parameters
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN nurse_tea_req.id_episode%TYPE,
        i_draft           IN table_number, --i_id_nurse_tea_req
        i_topics          IN table_number,
        i_diagnoses       IN table_table_number,
        i_to_be_performed IN table_varchar,
        i_start_date      IN table_varchar, --i_dt_begin
        i_notes           IN table_varchar,
        i_description     IN table_clob,
        i_order_recurr    IN table_number,
        o_error           OUT t_error_out
        
    ) RETURN BOOLEAN IS
        l_category category.flg_type%TYPE;
    BEGIN
    
        l_category := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
        g_error    := 'Init update_request / i_id_episode=' || i_id_episode;
        pk_alertlog.log_debug(g_error);
        IF l_category = pk_alert_constant.g_cat_type_nurse
        THEN
            IF NOT pk_patient_education_api_db.update_request(i_lang             => i_lang,
                                                              i_prof             => i_prof,
                                                              i_id_episode       => i_id_episode,
                                                              i_id_nurse_tea_req => i_draft,
                                                              i_topics           => i_topics,
                                                              i_compositions     => i_diagnoses, --TO DO -- temporary 1º fase
                                                              i_to_be_performed  => i_to_be_performed,
                                                              i_start_date       => i_start_date,
                                                              i_notes            => i_notes,
                                                              i_description      => i_description,
                                                              i_order_recurr     => table_number(NULL), --TO DO -- temporary 1º fase
                                                              i_upd_flg_status   => pk_alert_constant.g_no,
                                                              i_diagnoses        => NULL,
                                                              i_not_order_reason => NULL,
                                                              o_error            => o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSE
            IF NOT pk_patient_education_api_db.update_request(i_lang             => i_lang,
                                                              i_prof             => i_prof,
                                                              i_id_episode       => i_id_episode,
                                                              i_id_nurse_tea_req => i_draft,
                                                              i_topics           => i_topics,
                                                              i_compositions     => table_table_number(NULL),
                                                              i_to_be_performed  => i_to_be_performed,
                                                              i_start_date       => i_start_date,
                                                              i_notes            => i_notes,
                                                              i_description      => i_description,
                                                              i_order_recurr     => table_number(NULL), --TO DO -- temporary 1º fase
                                                              i_upd_flg_status   => pk_alert_constant.g_no,
                                                              i_diagnoses        => NULL,
                                                              i_not_order_reason => NULL,
                                                              o_error            => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_TASK_PARAMETERS',
                                              o_error);
            RETURN FALSE;
    END set_task_parameters;

    /**
    * Expire tasks action (task will change its state to expired)
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id
    * @param       i_task_requests           array of task request ids to expire
    * @param       o_error                   error message structure
    *
    * @return                                true on success, false otherwise
    */
    FUNCTION expire_task
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_task_requests IN table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        co_function_name CONSTANT VARCHAR2(30 CHAR) := 'expire_task';
        l_nurse_tea_req_list table_number;
        l_prof_cat_type      category.flg_type%TYPE;
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        -- Sanity check
        IF i_task_requests IS NULL
           OR i_episode IS NULL
        THEN
            g_error := 'Invalid input arguments';
            pk_alertlog.log_warn(text => g_error, object_name => g_package_name, sub_object_name => co_function_name);
            RETURN TRUE;
        END IF;
    
        -- Filter NURSE_TEA_REQ that really meet the requirements for being able to expire 
        -- (ie. cannot expire a task that is completed, canceled, etc.)
    
        g_error := 'Select NURSE_TEA_REQ';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => co_function_name);
    
        SELECT ntr.id_nurse_tea_req
          BULK COLLECT
          INTO l_nurse_tea_req_list
          FROM nurse_tea_req ntr
         WHERE ntr.id_nurse_tea_req IN (SELECT /*+opt_estimate(table t rows=1) */
                                         column_value
                                          FROM TABLE(i_task_requests) t)
           AND ntr.flg_status IN
               (pk_patient_education_constant.g_nurse_tea_req_act, pk_patient_education_constant.g_nurse_tea_req_pend);
    
        -- So proceed if there are tasks able to expire
        IF l_nurse_tea_req_list.count > 0
        THEN
            g_error         := 'CALL pk_prof_utils.get_category';
            l_prof_cat_type := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
        
            g_error := 'CALL pk_patient_education_api_db.set_nurse_tea_req_status';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => co_function_name);
        
            IF NOT pk_patient_education_api_db.set_nurse_tea_req_status(i_lang               => i_lang,
                                                                        i_prof               => i_prof,
                                                                        i_prof_cat_type      => l_prof_cat_type,
                                                                        i_nurse_tea_req_list => l_nurse_tea_req_list,
                                                                        i_flg_status         => pk_patient_education_constant.g_nurse_tea_req_expired,
                                                                        i_flg_commit         => pk_alert_constant.g_no,
                                                                        i_flg_history        => pk_alert_constant.g_yes,
                                                                        o_error              => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => co_function_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END expire_task;

    /**
    * Check the possibility to be recorded in the system an execution after the task was expired.
    It was defined that it should be possible to record in the system the last execution made after the task expiration.
    It should not be possible to record more than one excecution after the task was expired. 
    *
    * @param   i_lang           Professional preferred language
    * @param   i_prof           Professional identification and its context (institution and software)
    * @param   i_task_request   Task request ID (ID_INTERV_PRESC_DET)
    * @param   i_status         Task request Status
    * @param   i_dt_expire      Task request expiration date
    *
    * @return  'Y' An execution is allowed. 'N' No execution is allowed (or the task has not expired).
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.1.5
    * @since   04-11-2011
    */
    FUNCTION check_extra_take
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN cpoe_process_task.id_task_request%TYPE,
        i_status       IN nurse_tea_req.flg_status%TYPE,
        i_dt_expire    IN nurse_tea_req.dt_close_tstz%TYPE
    ) RETURN VARCHAR IS
        co_function_name CONSTANT VARCHAR2(30 CHAR) := 'check_extra_take';
        l_error                   t_error_out;
        l_execution_allowed       VARCHAR2(1 CHAR);
        l_post_expired_executions NUMBER;
        l_cpoe_adm_extra_take     VARCHAR2(1);
    
    BEGIN
    
        -- Checks configuration to administer one more time after the task has expired
        g_error               := 'Get config';
        l_cpoe_adm_extra_take := pk_sysconfig.get_config(g_cpoe_adm_extra_take, i_prof);
    
        -- By default assumes the execution is not allowed
        l_execution_allowed := pk_alert_constant.get_no;
    
        -- -A procedure expired 
        -- -CPOE config allow execution after task was expired
        IF i_status = pk_patient_education_constant.g_nurse_tea_req_expired
           AND l_cpoe_adm_extra_take = pk_alert_constant.g_yes
        THEN
        
            -- Check if already exists one execution after the task was expired
            g_error := 'Counting post-expired executions';
            SELECT COUNT(*)
              INTO l_post_expired_executions
              FROM nurse_tea_det ntd
             WHERE ntd.id_nurse_tea_req = i_task_request
               AND ntd.flg_status = pk_patient_education_constant.g_nurse_tea_det_exec
               AND ntd.dt_nurse_tea_det_tstz >= i_dt_expire;
        
            -- If there is not one execution after the task has been expired, then execution is allowed
            IF l_post_expired_executions = 0
            THEN
                l_execution_allowed := pk_alert_constant.g_yes;
            END IF;
        
        END IF;
    
        RETURN l_execution_allowed;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => co_function_name,
                                              o_error    => l_error);
            RAISE;
    END check_extra_take;

    /**
    * Check the possibility to be recorded in the system an execution after the task was expired.
    It was defined that it should be possible to record in the system the last execution made after the task expiration.
    It should not be possible to record more than one excecution after the task was expired. 
    *
    * @param   i_lang           Professional preferred language
    * @param   i_prof           Professional identification and its context (institution and software)
    * @param   i_task_request   Task request ID (ID_INTERV_PRESC_DET)
    *
    * @return  'Y' An execution is allowed. 'N' No execution is allowed (or the task has not expired).
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.1.5
    * @since   04-11-2011
    */
    FUNCTION check_extra_take
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN cpoe_process_task.id_task_request%TYPE
    ) RETURN VARCHAR IS
        co_function_name CONSTANT VARCHAR2(30 CHAR) := 'check_extra_take';
        l_error             t_error_out;
        l_execution_allowed VARCHAR2(1 CHAR);
        l_status            nurse_tea_req.flg_status%TYPE;
        l_dt_expire         nurse_tea_req.dt_close_tstz%TYPE;
    BEGIN
        -- Check if the task has expired
        SELECT ntr.flg_status, ntr.dt_close_tstz
          INTO l_status, l_dt_expire
          FROM nurse_tea_req ntr
         WHERE ntr.id_nurse_tea_req = i_task_request;
    
        l_execution_allowed := check_extra_take(i_lang         => i_lang,
                                                i_prof         => i_prof,
                                                i_task_request => i_task_request,
                                                i_status       => l_status,
                                                i_dt_expire    => l_dt_expire);
    
        RETURN l_execution_allowed;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => co_function_name,
                                              o_error    => l_error);
            RAISE;
    END check_extra_take;

    FUNCTION get_order_plan_report
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_task_request  IN table_number,
        i_cpoe_dt_begin IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_cpoe_dt_end   IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_plan_rep      OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cp_begin     TIMESTAMP WITH LOCAL TIME ZONE;
        l_cp_end       TIMESTAMP WITH LOCAL TIME ZONE;
        l_tbl_pat_educ table_number;
    
        l_tbl_rec_exec_static t_tbl_cpoe_execution;
        l_tbl_rec_exec_final  t_tbl_cpoe_execution := t_tbl_cpoe_execution();
        l_last_date           monitorization_vs_plan.dt_plan_tstz%TYPE;
        l_interval            monitorization.interval%TYPE;
        l_calc_last_date      monitorization_vs_plan.dt_plan_tstz%TYPE;
    
        l_error t_error_out;
    BEGIN
    
        IF i_cpoe_dt_begin IS NULL
        THEN
            IF NOT pk_episode.get_epis_dt_begin_tstz(i_lang          => i_lang,
                                                     i_prof          => i_prof,
                                                     i_id_episode    => i_episode,
                                                     o_dt_begin_tstz => l_cp_begin,
                                                     o_error         => o_error)
            THEN
                l_cp_begin := current_timestamp;
            END IF;
        ELSE
            l_cp_begin := i_cpoe_dt_begin;
        END IF;
    
        IF i_cpoe_dt_end IS NULL
        THEN
            l_cp_end := nvl(pk_date_utils.add_days_to_tstz(i_timestamp => i_cpoe_dt_begin, i_days => 1),
                            current_timestamp);
        ELSE
            --l_cp_end :=  pk_date_utils.add_days_to_tstz(i_timestamp => i_cpoe_dt_end, i_days => 1);
            l_cp_end := i_cpoe_dt_end;
        END IF;
    
        SELECT a.id_nurse_tea_req
          BULK COLLECT
          INTO l_tbl_pat_educ
          FROM nurse_tea_req a
         WHERE a.id_episode = i_episode
           AND a.flg_status NOT IN ('Z', 'C');
    
        FOR i IN 1 .. l_tbl_pat_educ.count
        LOOP
        
            SELECT t_rec_cpoe_execution(id_task_type    => NULL,
                                        id_prescription => t.id_nurse_tea_req,
                                        planned_date    => pk_date_utils.date_send_tsz(i_lang => i_lang,
                                                                                       i_date => t.dt_plan,
                                                                                       i_prof => i_prof),
                                        exec_date       => CASE
                                                               WHEN t.dt_exec IS NULL THEN
                                                                NULL
                                                               ELSE
                                                                pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => t.dt_exec, i_prof => i_prof)
                                                           END,
                                        exec_notes      => NULL,
                                        out_of_period   => t.out_of_period)
              BULK COLLECT
              INTO l_tbl_rec_exec_static
              FROM (SELECT l_tbl_pat_educ(i) id_nurse_tea_req,
                           ntd.dt_planned dt_plan,
                           ntd.dt_end dt_exec,
                           'N' out_of_period
                      FROM nurse_tea_req ntr
                     INNER JOIN nurse_tea_det ntd
                        ON ntr.id_nurse_tea_req = ntd.id_nurse_tea_req
                     WHERE ntr.id_nurse_tea_req = l_tbl_pat_educ(i)
                       AND ntd.dt_start BETWEEN l_cp_begin AND l_cp_end
                       AND ntd.flg_status != 'I'
                    UNION ALL
                    SELECT z.id_nurse_tea_req, z.dt_plan, z.dt_exec, z.out_of_period
                      FROM (SELECT l_tbl_pat_educ(i) id_nurse_tea_req,
                                   ntd.dt_start dt_plan,
                                   ntd.dt_end dt_exec,
                                   'Y' out_of_period
                              FROM nurse_tea_req ntr
                             INNER JOIN nurse_tea_det ntd
                                ON ntr.id_nurse_tea_req = ntd.id_nurse_tea_req
                             WHERE ntr.id_nurse_tea_req = l_tbl_pat_educ(i)
                               AND ntd.dt_start < l_cp_begin
                             ORDER BY ntd.dt_start) z
                     WHERE rownum = 1) t;
        
            l_tbl_rec_exec_final := l_tbl_rec_exec_static MULTISET UNION l_tbl_rec_exec_final;
        
        END LOOP;
    
        OPEN o_plan_rep FOR
            SELECT t.id_prescription, t.planned_date, t.exec_date, t.exec_notes, t.out_of_period
              FROM TABLE(l_tbl_rec_exec_final) t
             ORDER BY t.planned_date;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_error.err_desc,
                                              g_package_owner,
                                              g_package_name,
                                              'INACTIVATE_MONITORZTN_TASKS',
                                              l_error);
            pk_types.open_my_cursor(o_plan_rep);
            RETURN FALSE;
        
    END get_order_plan_report;

BEGIN
    -- Initialization

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package_name);
END pk_patient_education_cpoe;
/
