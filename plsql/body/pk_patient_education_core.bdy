/*-- Last Change Revision: $Rev: 2055402 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2023-02-22 09:44:22 +0000 (qua, 22 fev 2023) $*/

CREATE OR REPLACE PACKAGE BODY pk_patient_education_core IS

    --
    PROCEDURE insert_ntr_hist
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE,
        o_error            OUT t_error_out
    ) IS
        l_rec  nurse_tea_req_hist%ROWTYPE;
        l_rows table_varchar;
    BEGIN
        g_error := 'Get NURSE_TEA_REQ data';
        SELECT ts_nurse_tea_req_hist.next_key,
               ntr.id_nurse_tea_req,
               ntr.id_prof_req,
               ntr.id_episode,
               ntr.req_header,
               ntr.flg_status,
               ntr.notes_req,
               ntr.id_prof_close,
               ntr.notes_close,
               ntr.id_prof_exec,
               ntr.id_prev_episode,
               ntr.dt_nurse_tea_req_tstz,
               ntr.dt_begin_tstz,
               ntr.dt_close_tstz,
               ntr.id_visit,
               ntr.id_patient,
               ntr.status_flg,
               ntr.status_icon,
               ntr.status_msg,
               ntr.status_str,
               ntr.create_user,
               ntr.create_time,
               ntr.create_institution,
               ntr.update_user,
               ntr.update_time,
               ntr.update_institution,
               ntr.id_cancel_reason,
               ntr.id_context,
               ntr.flg_context,
               ntr.id_nurse_tea_topic,
               ntr.id_order_recurr_plan,
               ntr.description,
               ntr.flg_time,
               current_timestamp,
               ntr.desc_topic_aux,
               ntr.id_not_order_reason
          INTO l_rec
          FROM nurse_tea_req ntr
         WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req;
    
        g_error := 'Insert into history table';
        ts_nurse_tea_req_hist.ins(rec_in => l_rec, rows_out => l_rows);
    
        g_error := 'Process insert on NURSE_TEA_REQ_HIST';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'NURSE_TEA_REQ_HIST',
                                      i_rowids     => l_rows,
                                      o_error      => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'INSERT_NTR_HIST',
                                              o_error);
    END insert_ntr_hist;

    --
    PROCEDURE update_ntr_status
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE,
        o_error            OUT t_error_out
    ) IS
        l_req_status nurse_tea_req.flg_status%TYPE;
        l_rows       table_varchar;
    BEGIN
        SELECT decode(COUNT(*),
                      0,
                      pk_patient_education_constant.g_nurse_tea_req_fin,
                      pk_patient_education_constant.g_nurse_tea_req_act)
          INTO l_req_status
          FROM nurse_tea_det
         WHERE id_nurse_tea_req = i_id_nurse_tea_req
           AND flg_status = pk_patient_education_constant.g_nurse_tea_req_pend;
    
        insert_ntr_hist(i_lang             => i_lang,
                        i_prof             => i_prof,
                        i_id_nurse_tea_req => i_id_nurse_tea_req,
                        o_error            => o_error);
    
        ts_nurse_tea_req.upd(id_nurse_tea_req_in => i_id_nurse_tea_req,
                             flg_status_in       => l_req_status,
                             rows_out            => l_rows);
    
        g_error := 'Process insert';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'NURSE_TEA_REQ',
                                      i_rowids     => l_rows,
                                      o_error      => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'UPDATE_NTR_STATUS',
                                              o_error);
    END update_ntr_status;
    --
    FUNCTION check_params
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_flg_time   IN VARCHAR2,
        i_start_date IN VARCHAR2,
        i_duration   IN VARCHAR2,
        i_end_date   IN VARCHAR2,
        o_params     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_na sys_message.desc_message%TYPE;
    
    BEGIN
        l_na := pk_message.get_message(i_lang, 'COMMON_M018');
    
        OPEN o_params FOR
            SELECT decode(i_flg_time,
                          pk_patient_education_constant.g_flg_time_next,
                          pk_alert_constant.g_no,
                          pk_alert_constant.g_yes) edit_start_date,
                   decode(i_flg_time,
                          pk_patient_education_constant.g_flg_time_next,
                          pk_alert_constant.g_no,
                          pk_alert_constant.g_yes) edit_duration,
                   decode(i_flg_time,
                          pk_patient_education_constant.g_flg_time_next,
                          pk_alert_constant.g_no,
                          pk_alert_constant.g_yes) edit_end_date,
                   decode(i_flg_time, pk_patient_education_constant.g_flg_time_next, l_na, i_start_date) param_start_date,
                   decode(i_flg_time,
                          pk_patient_education_constant.g_flg_time_next,
                          l_na,
                          pk_date_utils.get_timestamp_diff(trunc(pk_date_utils.get_string_tstz(i_lang,
                                                                                               i_prof,
                                                                                               i_end_date,
                                                                                               NULL),
                                                                 'mi'),
                                                           trunc(pk_date_utils.get_string_tstz(i_lang,
                                                                                               i_prof,
                                                                                               i_start_date,
                                                                                               NULL),
                                                                 'mi')) * 24 * 60) param_duration,
                   decode(i_flg_time, pk_patient_education_constant.g_flg_time_next, l_na, i_end_date) param_end_date
              FROM dual;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_cursor_if_closed(o_params);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_PARAMS',
                                              o_error);
    END check_params;

    --
    PROCEDURE create_suggestion
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_id_episode         IN nurse_tea_req.id_episode%TYPE,
        i_id_nurse_tea_topic IN table_number,
        i_trig_by            IN table_clob,
        i_id_context         IN nurse_tea_req.id_context%TYPE,
        o_id_nurse_tea_req   OUT table_number
    ) IS
        l_description        pk_translation.t_desc_translation;
        l_next               nurse_tea_req.id_nurse_tea_req%TYPE;
        l_rows_ntr           table_varchar := table_varchar();
        l_rows               table_varchar := table_varchar();
        l_id_nurse_tea_req   table_number := table_number();
        l_id_nurse_tea_topic table_number := table_number();
        l_error              t_error_out;
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        SELECT id_nurse_tea_topic
          BULK COLLECT
          INTO l_id_nurse_tea_topic
          FROM (SELECT column_value id_nurse_tea_topic
                  FROM TABLE(i_id_nurse_tea_topic)
                MINUS
                SELECT ntr.id_nurse_tea_topic
                  FROM nurse_tea_req ntr
                 WHERE ntr.id_episode = i_id_episode
                   AND ntr.flg_status = pk_patient_education_constant.g_nurse_tea_req_sug
                   AND EXISTS (SELECT column_value
                          FROM TABLE(i_id_nurse_tea_topic)
                         WHERE ntr.id_nurse_tea_topic = column_value));
    
        FOR i IN 1 .. l_id_nurse_tea_topic.count
        LOOP
            SELECT pk_translation.get_translation(i_lang, ntt.code_topic_description)
              INTO l_description
              FROM nurse_tea_topic ntt
             WHERE ntt.id_nurse_tea_topic = i_id_nurse_tea_topic(i);
        
            l_next := ts_nurse_tea_req.next_key;
        
            g_error := 'Insert suggestion';
            ts_nurse_tea_req.ins(id_nurse_tea_req_in      => l_next,
                                 id_prof_req_in           => i_prof.id,
                                 id_episode_in            => i_id_episode,
                                 flg_status_in            => pk_patient_education_constant.g_nurse_tea_req_sug,
                                 dt_nurse_tea_req_tstz_in => g_sysdate_tstz,
                                 id_visit_in              => pk_episode.get_id_visit(i_id_episode),
                                 id_patient_in            => pk_episode.get_id_patient(i_id_episode),
                                 id_context_in            => i_id_context,
                                 id_nurse_tea_topic_in    => l_id_nurse_tea_topic(i),
                                 description_in           => l_description,
                                 rows_out                 => l_rows_ntr);
        
            insert_ntr_hist(i_lang => i_lang, i_prof => i_prof, i_id_nurse_tea_req => l_next, o_error => l_error);
        
            l_rows := l_rows MULTISET UNION l_rows_ntr;
        
            l_id_nurse_tea_req.extend;
            l_id_nurse_tea_req(i) := l_next;
        
            g_error := 'INSERT LOG ON TI_LOG';
            IF NOT t_ti_log.ins_log(i_lang,
                                    i_prof,
                                    i_id_episode,
                                    pk_patient_education_constant.g_nurse_tea_req_sug,
                                    l_next,
                                    'NT',
                                    l_error)
            THEN
                RAISE g_exception;
            END IF;
        END LOOP;
    
        g_error := 'Process insert on NURSE_TEA_REQ';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'NURSE_TEA_REQ',
                                      i_rowids     => l_rows,
                                      o_error      => l_error);
    
        o_id_nurse_tea_req := l_id_nurse_tea_req;
    
    END create_suggestion;

    /** 
    * Sets a temporary order recurrence plan as definitive (final status) and returns an array of plan identifiers
    *     
    * @param   i_lang                    Language associated to the professional 
    * @param   i_prof                    Professional, institution and software ids
    * @param   i_order_recurr            Array of order recurrence plans in a temporary state
    * @param   o_order_recurr            Array of order recurrence plans in a final state
    * @param   o_error                   An error message, set when return=false    
    *    
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  ana.monteiro
    * @version 1.0
    * @since   16-01-2013
    */
    FUNCTION set_final_order_recurr_p
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_order_recurr IN table_number,
        o_order_recurr OUT table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_order_recurr_temp   table_number := table_number();
        l_order_recurr_option order_recurr_plan.id_order_recurr_option%TYPE;
    
        -- index by varchar2(30) because we cannot index by number
        TYPE t_ids_tab IS TABLE OF order_recurr_plan.id_order_recurr_plan%TYPE INDEX BY VARCHAR2(30);
        l_ids_tab t_ids_tab;
    
        /*
        TODO: owner="ariel.machado" created="12/18/2014"
        text="This method should be moved to pk_order_recurrence_api_db"
        */
        FUNCTION check_temporary(i_order_plan IN order_recurr_plan.id_order_recurr_plan%TYPE) RETURN pk_types.t_flg_char IS
            l_flg_temporary pk_types.t_flg_char;
            l_flg_status    order_recurr_plan.flg_status%TYPE;
        BEGIN
            SELECT orcpl.flg_status
              INTO l_flg_status
              FROM order_recurr_plan orcpl
             WHERE orcpl.id_order_recurr_plan = i_order_plan;
        
            CASE l_flg_status
                WHEN pk_order_recurrence_core.g_plan_status_temp THEN
                    l_flg_temporary := pk_alert_constant.g_yes;
                WHEN pk_order_recurrence_core.g_plan_status_predefined THEN
                    l_flg_temporary := pk_alert_constant.g_yes;
                ELSE
                    l_flg_temporary := pk_alert_constant.g_no;
            END CASE;
        
            RETURN l_flg_temporary;
        END check_temporary;
    
    BEGIN
        g_error := 'Init set_final_order_recurr_p / i_order_recurr.count=' || i_order_recurr.count;
    
        -- remove duplicates and nulls
        g_error := 'Removing duplicates and nulls';
        SELECT DISTINCT column_value
          BULK COLLECT
          INTO l_order_recurr_temp
          FROM TABLE(CAST(i_order_recurr AS table_number))
         WHERE column_value IS NOT NULL;
    
        -- getting final order plans into l_ids_tab(old_value) := new_value
        FOR i IN 1 .. l_order_recurr_temp.count
        LOOP
            -- Only try to set a temporary order recurrence plan as definitive if order plan is not final yet 
            -- (an patient education edition without changes in recurrence info the plan is already final)
            IF check_temporary(i_order_plan => l_order_recurr_temp(i)) = pk_alert_constant.g_yes
            THEN
            
                g_error := 'Call pk_order_recurrence_core.set_order_recurr_plan / i_order_recurr(' || i || ')=' ||
                           l_order_recurr_temp(i);
                IF NOT pk_order_recurrence_api_db.set_order_recurr_plan(i_lang                    => i_lang,
                                                                        i_prof                    => i_prof,
                                                                        i_order_recurr_plan       => l_order_recurr_temp(i),
                                                                        o_order_recurr_option     => l_order_recurr_option,
                                                                        o_final_order_recurr_plan => l_ids_tab(to_char(l_order_recurr_temp(i))),
                                                                        o_error                   => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            ELSE
                -- The order recurrence plan is already definitive (final status)
                l_ids_tab(to_char(l_order_recurr_temp(i))) := l_order_recurr_temp(i);
            END IF;
        
        END LOOP;
    
        g_error        := 'map plan IDs';
        o_order_recurr := table_number();
        o_order_recurr.extend(i_order_recurr.count);
    
        FOR i IN 1 .. i_order_recurr.count
        LOOP
            -- fill o_order_recurr with the new plan ID values
            g_error := 'map plan IDs / i_order_recurr(' || i || ')=' || i_order_recurr(i);
            IF i_order_recurr(i) IS NOT NULL
            THEN
                o_order_recurr(i) := l_ids_tab(to_char(i_order_recurr(i)));
            ELSE
                o_order_recurr(i) := NULL;
            END IF;
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
                                              'SET_FINAL_ORDER_RECURR_P',
                                              o_error);
        
            RETURN FALSE;
    END set_final_order_recurr_p;

    /** 
    * Creates executions of a nurse tea request
    *     
    * @param   i_lang                    Language associated to the professional 
    * @param   i_prof                    Professional, institution and software ids
    * @param   i_id_nurse_tea_req        Array of nurse tea requests identifiers
    * @param   i_order_recurr            Array of order recurrence plans in a final state
    * @param   i_start_date              Array of executions start date
    * @param   o_error                   An error message, set when return=false    
    *    
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  ana.monteiro
    * @version 1.0
    * @since   16-01-2013
    */
    FUNCTION create_ntr_executions
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_req IN table_number,
        i_order_recurr     IN table_number,
        i_start_date       IN table_varchar,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_order_recurr_final table_number := table_number();
        l_order_plan_exec    t_tbl_order_recurr_plan;
        l_exec_to_process    t_tbl_order_recurr_plan_sts;
        l_start_date         TIMESTAMP(6) WITH LOCAL TIME ZONE;
    BEGIN
        g_error        := 'Init create_ntr_executions / i_order_recurr.count=' || i_order_recurr.count;
        g_sysdate_tstz := current_timestamp;
    
        -- remove duplicates and nulls (if any)
        SELECT DISTINCT column_value
          BULK COLLECT
          INTO l_order_recurr_final
          FROM TABLE(CAST(i_order_recurr AS table_number))
         WHERE column_value IS NOT NULL;
    
        -- Create the executions for all the requests that have a recurrence plan
        IF l_order_recurr_final IS NOT NULL
           AND l_order_recurr_final.count > 0
        THEN
            g_error := 'Get execution plan';
            IF NOT pk_order_recurrence_api_db.prepare_order_recurr_plan(i_lang            => i_lang,
                                                                        i_prof            => i_prof,
                                                                        i_order_plan      => l_order_recurr_final,
                                                                        o_order_plan_exec => l_order_plan_exec,
                                                                        o_error           => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            g_error := 'Create executions';
            IF NOT create_executions(i_lang            => i_lang,
                                     i_prof            => i_prof,
                                     i_exec_tab        => l_order_plan_exec,
                                     o_exec_to_process => l_exec_to_process,
                                     o_error           => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        -- Create the executions for all requests that should be executed only once
        -- This type of execution doesn't have a recurrence plan
        FOR i IN 1 .. i_order_recurr.count
        LOOP
            -- When the id (i_order_recurr(i)) is null is to be executed only once
            IF i_order_recurr(i) IS NULL
            THEN
                g_error      := 'create_execution / i_order_recurr(' || i || ')=' || i_order_recurr(i);
                l_start_date := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                              i_prof      => i_prof,
                                                              i_timestamp => i_start_date(i),
                                                              i_timezone  => NULL);
            
                IF NOT create_execution(i_lang                  => i_lang,
                                        i_prof                  => i_prof,
                                        i_id_nurse_tea_req      => i_id_nurse_tea_req(i),
                                        i_dt_start              => l_start_date,
                                        i_dt_nurse_tea_det_tstz => g_sysdate_tstz,
                                        i_flg_status            => pk_patient_education_constant.g_nurse_tea_req_pend,
                                        i_num_order             => 1,
                                        o_error                 => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            END IF;
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
                                              'CREATE_NTR_EXECUTIONS',
                                              o_error);
        
            RETURN FALSE;
    END create_ntr_executions;

    FUNCTION get_diagnosis
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE
    ) RETURN VARCHAR2 IS
        l_ret VARCHAR2(4000);
    BEGIN
        SELECT pk_string_utils.chop(concatenate(description || '; '), 2)
          INTO l_ret
          FROM (SELECT pk_diagnosis.concat_diag(i_lang, NULL, NULL, NULL, i_prof, ntr.id_nurse_tea_req) description
                  FROM nurse_tea_req ntr
                 WHERE ntr.id_nurse_tea_req = i_nurse_tea_req
                UNION ALL
                SELECT pk_translation.get_translation(i_lang, ic.code_icnp_composition) description
                  FROM nurse_tea_req_diag ntrd
                  JOIN icnp_composition ic
                    ON ic.id_composition = ntrd.id_composition
                 WHERE ntrd.id_nurse_tea_req = i_nurse_tea_req
                   AND ntrd.id_composition IS NOT NULL);
    
        RETURN l_ret;
    END get_diagnosis;

    FUNCTION prv_new_nurse_tea_req
    (
        i_lang                 IN language.id_language%TYPE,
        i_id_nurse_tea_req     IN nurse_tea_req.id_nurse_tea_req%TYPE DEFAULT NULL,
        i_id_episode           IN nurse_tea_req.id_episode%TYPE,
        i_flg_status           IN nurse_tea_req.flg_status%TYPE,
        i_dt_nurse_tea_req_str IN VARCHAR2,
        i_id_prof_req          IN profissional,
        i_dt_begin_str         IN VARCHAR2 DEFAULT NULL,
        i_notes_req            IN nurse_tea_req.notes_req%TYPE,
        i_dt_close_str         IN VARCHAR2 DEFAULT NULL,
        i_id_prof_close        IN nurse_tea_req.id_prof_close%TYPE DEFAULT NULL,
        i_notes_close          IN nurse_tea_req.notes_close%TYPE DEFAULT NULL,
        i_req_header           IN nurse_tea_req.req_header%TYPE DEFAULT NULL,
        i_id_patient           IN nurse_tea_req.id_patient%TYPE,
        i_id_visit             IN nurse_tea_req.id_visit%TYPE,
        o_rowids               OUT table_varchar
    ) RETURN nurse_tea_req.id_nurse_tea_req%TYPE IS
        l_next_id_nurse_tea_req nurse_tea_req.id_nurse_tea_req%TYPE;
    BEGIN
        /* if primary key is passed as a parameter, use it
        else, take the next value from sequence */
        IF (i_id_nurse_tea_req IS NOT NULL)
        THEN
            l_next_id_nurse_tea_req := i_id_nurse_tea_req;
        ELSE
            l_next_id_nurse_tea_req := ts_nurse_tea_req.next_key();
        END IF;
    
        -- < DESNORM LMAIA - Sep 2008 >
        -- CHAMAR O INSERT DO PACKAGE TS_NURSE_TEA_REQ
        ts_nurse_tea_req.ins(id_nurse_tea_req_in      => l_next_id_nurse_tea_req,
                             id_prof_req_in           => i_id_prof_req.id,
                             id_episode_in            => i_id_episode,
                             req_header_in            => i_req_header,
                             flg_status_in            => i_flg_status,
                             notes_req_in             => i_notes_req,
                             id_prof_close_in         => i_id_prof_close,
                             dt_nurse_tea_req_tstz_in => pk_date_utils.get_string_tstz(i_lang,
                                                                                       i_id_prof_req,
                                                                                       i_dt_nurse_tea_req_str,
                                                                                       NULL),
                             dt_begin_tstz_in         => pk_date_utils.get_string_tstz(i_lang,
                                                                                       i_id_prof_req,
                                                                                       i_dt_begin_str,
                                                                                       NULL),
                             dt_close_tstz_in         => pk_date_utils.get_string_tstz(i_lang,
                                                                                       i_id_prof_req,
                                                                                       i_dt_close_str,
                                                                                       NULL),
                             notes_close_in           => i_notes_close,
                             id_patient_in            => i_id_patient,
                             id_visit_in              => i_id_visit,
                             rows_out                 => o_rowids);
        -- < END DESNORM >
    
        RETURN l_next_id_nurse_tea_req;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
        
    END prv_new_nurse_tea_req;

    --
    FUNCTION create_request
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN nurse_tea_req.id_episode%TYPE,
        i_topics                IN table_number,
        i_compositions          IN table_table_number,
        i_to_be_performed       IN table_varchar,
        i_start_date            IN table_varchar,
        i_notes                 IN table_varchar,
        i_description           IN table_clob,
        i_order_recurr          IN table_number,
        i_draft                 IN VARCHAR2 DEFAULT 'N',
        i_id_nurse_tea_req_sugg IN table_number,
        i_desc_topic_aux        IN table_varchar,
        i_diagnoses             IN table_clob DEFAULT NULL,
        i_not_order_reason      IN table_number,
        i_flg_origin_req        IN VARCHAR2 DEFAULT 'D',
        o_id_nurse_tea_req      OUT table_number,
        o_id_nurse_tea_topic    OUT table_number,
        o_title_topic           OUT table_varchar,
        o_desc_diagnosis        OUT table_varchar,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_nurse_tea_req table_number := table_number();
        l_order_recurr_f   table_number := table_number();
    
        l_title_topic    table_varchar := table_varchar();
        l_desc_diagnosis table_varchar := table_varchar();
    
        l_flg_profile     profile_template.flg_profile%TYPE;
        l_sys_alert_event sys_alert_event%ROWTYPE;
    
        l_epis_type epis_type.id_epis_type%TYPE;
    
    BEGIN
        g_error := 'Init create_request / i_id_episode=' || i_id_episode || ' i_draft=' || i_draft;
        pk_alertlog.log_debug(g_error);
    
        l_flg_profile := nvl(pk_hand_off_core.get_flg_profile(i_lang, i_prof, NULL), '#');
    
        g_sysdate_tstz := current_timestamp;
    
        -- getting final order recurr plans
        IF NOT set_final_order_recurr_p(i_lang         => i_lang,
                                        i_prof         => i_prof,
                                        i_order_recurr => i_order_recurr,
                                        o_order_recurr => l_order_recurr_f,
                                        o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        -- create nurse tea request
        g_error := 'Call pk_patient_education_ux.create_req / i_id_episode ' || i_id_episode;
        IF NOT create_req(i_lang                  => i_lang,
                          i_prof                  => i_prof,
                          i_id_episode            => i_id_episode,
                          i_topics                => i_topics,
                          i_compositions          => i_compositions,
                          i_diagnoses             => i_diagnoses,
                          i_to_be_performed       => i_to_be_performed,
                          i_start_date            => i_start_date,
                          i_notes                 => i_notes,
                          i_description           => i_description,
                          i_order_recurr          => l_order_recurr_f,
                          i_draft                 => i_draft,
                          i_id_nurse_tea_req_sugg => i_id_nurse_tea_req_sugg,
                          i_desc_topic_aux        => i_desc_topic_aux,
                          i_not_order_reason      => i_not_order_reason,
                          i_flg_origin_req        => i_flg_origin_req,
                          o_id_nurse_tea_req      => l_id_nurse_tea_req,
                          o_error                 => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF l_flg_profile = pk_prof_utils.g_flg_profile_template_student
           AND i_flg_origin_req != pk_alert_constant.g_task_origin_order_set
        THEN
            l_sys_alert_event.id_sys_alert    := pk_alert_constant.g_alert_cpoe_draft;
            l_sys_alert_event.id_software     := i_prof.software;
            l_sys_alert_event.id_institution  := i_prof.institution;
            l_sys_alert_event.id_episode      := i_id_episode;
            l_sys_alert_event.id_patient      := pk_episode.get_epis_patient(i_lang    => i_lang,
                                                                             i_prof    => i_prof,
                                                                             i_episode => i_id_episode);
            l_sys_alert_event.id_record       := i_id_episode;
            l_sys_alert_event.id_visit        := pk_visit.get_visit(i_episode => i_id_episode, o_error => o_error);
            l_sys_alert_event.dt_record       := current_timestamp;
            l_sys_alert_event.id_professional := pk_hand_off.get_episode_responsible(i_lang       => i_lang,
                                                                                     i_prof       => i_prof,
                                                                                     i_id_episode => i_id_episode,
                                                                                     o_error      => o_error);
        
            IF NOT pk_alerts.insert_sys_alert_event(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_sys_alert_event => l_sys_alert_event,
                                                    o_error           => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
        END IF;
    
        IF i_draft = pk_alert_constant.g_no
           AND i_flg_origin_req != pk_alert_constant.g_task_origin_order_set
        THEN
        
            -- create nurse tea executions (nurse_tea_det)
            g_error := 'Call create_ntr_executions / l_id_nurse_tea_req.count=' || l_id_nurse_tea_req.count;
            IF NOT create_ntr_executions(i_lang             => i_lang,
                                         i_prof             => i_prof,
                                         i_id_nurse_tea_req => l_id_nurse_tea_req,
                                         i_order_recurr     => l_order_recurr_f,
                                         i_start_date       => i_start_date,
                                         o_error            => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            g_error := 'Call to SET_FIRST_OBS';
            IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                          i_id_episode          => i_id_episode,
                                          i_pat                 => pk_episode.get_id_patient(i_id_episode),
                                          i_prof                => i_prof,
                                          i_prof_cat_type       => pk_prof_utils.get_category(i_lang, i_prof),
                                          i_dt_last_interaction => g_sysdate_tstz,
                                          i_dt_first_obs        => g_sysdate_tstz,
                                          o_error               => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            --ALERT-332436 - Create a CPOE process when there is not one available for the episode
            DECLARE
                l_task_list         pk_types.cursor_type;
                l_flg_warning_type  VARCHAR2(1000);
                l_msg_title         VARCHAR2(1000);
                l_msg_body          VARCHAR2(1000);
                l_proc_start        VARCHAR2(1000);
                l_proc_end          VARCHAR2(1000);
                l_proc_refresh      VARCHAR2(1000);
                l_proc_next_start   VARCHAR2(1000);
                l_proc_next_end     VARCHAR2(1000);
                l_proc_next_refresh VARCHAR2(1000);
                l_error             t_error_out;
                l_task_id           table_varchar := table_varchar();
                l_task_type         table_number := table_number();
                l_cpoe_process      cpoe_process.id_cpoe_process%TYPE;
                l_count             NUMBER(24);
            BEGIN
                g_error := 'Call to check_tasks_creation';
                FOR i IN 1 .. l_id_nurse_tea_req.count()
                LOOP
                    l_task_id.extend();
                    l_task_id(i) := l_id_nurse_tea_req(i);
                    l_task_type.extend();
                    l_task_type(i) := pk_alert_constant.g_task_type_nursing;
                END LOOP;
            
                IF NOT pk_cpoe.check_tasks_creation(i_lang              => i_lang,
                                                    i_prof              => i_prof,
                                                    i_episode           => i_id_episode,
                                                    i_task_type         => l_task_type,
                                                    i_dt_start          => i_start_date,
                                                    i_dt_end            => table_varchar(NULL),
                                                    i_task_id           => l_task_id,
                                                    i_tab_type          => NULL,
                                                    o_task_list         => l_task_list,
                                                    o_flg_warning_type  => l_flg_warning_type,
                                                    o_msg_title         => l_msg_title,
                                                    o_msg_body          => l_msg_body,
                                                    o_proc_start        => l_proc_start,
                                                    o_proc_end          => l_proc_end,
                                                    o_proc_refresh      => l_proc_refresh,
                                                    o_proc_next_start   => l_proc_next_start,
                                                    o_proc_next_end     => l_proc_next_end,
                                                    o_proc_next_refresh => l_proc_next_refresh,
                                                    o_error             => l_error)
                THEN
                    RAISE g_exception;
                END IF;
            
                SELECT COUNT(1)
                  INTO l_count
                  FROM cpoe_process cp
                 WHERE cp.id_episode = i_id_episode;
            
                IF l_count = 0
                THEN
                    g_error := 'Call to create_cpoe';
                    IF NOT pk_cpoe.create_cpoe(i_lang              => i_lang,
                                               i_prof              => i_prof,
                                               i_episode           => i_id_episode,
                                               i_proc_start        => l_proc_start,
                                               i_proc_end          => l_proc_end,
                                               i_proc_next_start   => l_proc_next_start,
                                               i_proc_next_end     => l_proc_next_start,
                                               i_proc_next_refresh => l_proc_next_refresh,
                                               i_proc_type         => 'P',
                                               i_proc_refresh      => l_proc_next_refresh,
                                               o_cpoe_process      => l_cpoe_process,
                                               o_error             => l_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                END IF;
            END;
            --\ALERT-332436
        
            FOR i IN 1 .. l_id_nurse_tea_req.count
            LOOP
                g_error := 'Call to SYNC_TASK';
                IF NOT pk_cpoe.sync_task(i_lang                 => i_lang,
                                         i_prof                 => i_prof,
                                         i_episode              => i_id_episode,
                                         i_task_type            => pk_alert_constant.g_task_type_nursing,
                                         i_task_request         => l_id_nurse_tea_req(i),
                                         i_task_start_timestamp => pk_date_utils.get_string_tstz(i_lang,
                                                                                                 i_prof,
                                                                                                 i_start_date(i),
                                                                                                 NULL),
                                         o_error                => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            END LOOP;
        
            l_title_topic.extend(i_topics.count);
            l_desc_diagnosis.extend(i_topics.count);
        
            FOR i IN 1 .. i_topics.count
            LOOP
                IF i_topics(i) = 1
                THEN
                    --other
                    SELECT ntr.desc_topic_aux
                      INTO l_title_topic(i)
                      FROM nurse_tea_topic ntt
                      JOIN nurse_tea_req ntr
                        ON ntr.id_nurse_tea_topic = ntt.id_nurse_tea_topic
                     WHERE ntt.id_nurse_tea_topic = i_topics(i)
                       AND ntr.id_nurse_tea_req = l_id_nurse_tea_req(i);
                ELSE
                    SELECT pk_translation.get_translation(i_lang, ntt.code_nurse_tea_topic)
                      INTO l_title_topic(i)
                      FROM nurse_tea_topic ntt
                     WHERE ntt.id_nurse_tea_topic = i_topics(i);
                END IF;
            
                l_desc_diagnosis(i) := get_diagnosis(i_lang          => i_lang,
                                                     i_prof          => i_prof,
                                                     i_nurse_tea_req => l_id_nurse_tea_req(i));
            END LOOP;
        
        END IF;
    
        IF i_flg_origin_req != pk_alert_constant.g_task_origin_order_set
        THEN
            IF NOT pk_episode.get_epis_type(i_lang      => i_lang,
                                            i_id_epis   => i_id_episode,
                                            o_epis_type => l_epis_type,
                                            o_error     => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            IF l_epis_type IN (pk_alert_constant.g_epis_type_home_health_care, 99)
            THEN
                IF NOT pk_hhc_core.set_req_status_ie(i_lang            => i_lang,
                                                     i_prof            => i_prof,
                                                     i_id_episode      => i_id_episode,
                                                     i_id_epis_hhc_req => NULL,
                                                     o_error           => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            END IF;
        END IF;
    
        o_id_nurse_tea_req   := l_id_nurse_tea_req;
        o_title_topic        := l_title_topic;
        o_id_nurse_tea_topic := i_topics;
        o_desc_diagnosis     := l_desc_diagnosis;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_REQUEST',
                                              o_error);
        
            RETURN FALSE;
    END create_request;

    FUNCTION create_request
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN nurse_tea_req.id_episode%TYPE,
        i_draft                IN VARCHAR2 DEFAULT 'N',
        i_topics               IN table_number,
        i_tbl_ds_internal_name IN table_varchar DEFAULT NULL,
        i_tbl_real_val         IN table_table_varchar DEFAULT NULL,
        i_tbl_val_clob         IN table_table_clob DEFAULT NULL,
        i_tbl_val_array        IN tt_table_varchar DEFAULT NULL,
        i_flg_edition          IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_tbl_nurse_tea_req    IN table_number DEFAULT NULL,
        i_flg_origin_req       IN VARCHAR2 DEFAULT 'D',
        o_id_nurse_tea_req     OUT table_number,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_prof_req       nurse_tea_req.id_prof_req%TYPE;
        l_prof_req_category category.flg_type%TYPE;
    
        l_tbl_compositions          table_table_number := table_table_number();
        l_tbl_diagnoses             table_clob := table_clob();
        l_tbl_to_be_performed       table_varchar := table_varchar();
        l_tbl_start_date            table_varchar := table_varchar();
        l_tbl_notes                 table_varchar := table_varchar();
        l_tbl_description           table_clob := table_clob();
        l_tbl_order_recurr          table_number := table_number();
        l_tbl_id_nurse_tea_req_sugg table_number := table_number();
        l_tbl_desc_topic_aux        table_varchar := table_varchar();
        l_tbl_not_order_reason      table_number := table_number();
    
        l_id_patient             patient.id_patient%TYPE;
        l_tbl_id_diagnosis       table_number := table_number();
        l_tbl_id_alert_diagnosis table_number := table_number();
    
        l_diag_type VARCHAR2(1) := NULL;
    
        l_topics table_number := table_number();
    
        --o_id_nurse_tea_req   table_number;
        o_id_nurse_tea_topic table_number;
        o_title_topic        table_varchar;
        o_desc_diagnosis     table_varchar;
    
    BEGIN
        g_error := 'Init create_request / i_id_episode=' || i_id_episode;
        pk_alertlog.log_debug(g_error);
    
        IF i_flg_origin_req != pk_alert_constant.g_task_origin_order_set
        THEN
            SELECT e.id_patient
              INTO l_id_patient
              FROM episode e
             WHERE e.id_episode = i_id_episode;
        
            l_topics := i_topics;
        ELSE
            IF i_flg_edition = pk_alert_constant.g_no
            THEN
                l_topics := i_topics;
            ELSE
                FOR i IN i_tbl_nurse_tea_req.first .. i_tbl_nurse_tea_req.last
                LOOP
                    l_topics.extend();
                
                    SELECT ntr.id_nurse_tea_topic
                      INTO l_topics(l_topics.count)
                      FROM nurse_tea_req ntr
                     WHERE ntr.id_nurse_tea_req = i_tbl_nurse_tea_req(i);
                END LOOP;
            END IF;
        END IF;
    
        FOR i IN i_tbl_ds_internal_name.first .. i_tbl_ds_internal_name.last
        LOOP
            IF i_tbl_ds_internal_name(i) NOT IN
               (pk_orders_constant.g_ds_clinical_indication_mw, pk_orders_constant.g_ds_clinical_indication_icnp_mw)
            THEN
                FOR j IN l_topics.first .. l_topics.last
                LOOP
                    IF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_to_be_executed
                    THEN
                        l_tbl_to_be_performed.extend();
                        l_tbl_to_be_performed(l_tbl_to_be_performed.count) := i_tbl_real_val(i) (j);
                    ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_start_date
                    THEN
                        l_tbl_start_date.extend();
                        l_tbl_start_date(l_tbl_start_date.count) := i_tbl_real_val(i) (j);
                    ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_notes_clob
                    THEN
                        l_tbl_notes.extend();
                        l_tbl_notes(l_tbl_notes.count) := to_char(i_tbl_val_clob(i) (j)); --pk_patient_education_core.create_request is expecting varchar
                    ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_description
                    THEN
                        l_tbl_description.extend();
                        l_tbl_description(l_tbl_description.count) := i_tbl_val_clob(i) (j);
                    ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_dummy_number
                    THEN
                        l_tbl_order_recurr.extend();
                        l_tbl_order_recurr(l_tbl_order_recurr.count) := to_number(i_tbl_real_val(i) (j));
                    END IF;
                END LOOP;
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_clinical_indication_mw
            THEN
                FOR j IN l_topics.first .. l_topics.last
                LOOP
                    IF i_flg_edition = 'N'
                       OR i_flg_origin_req = pk_alert_constant.g_task_origin_order_set
                    THEN
                        --If this is a new request, we can assure that the content of this field is indeed Diagnosis,
                        --because this field is not available for the Nurse profile
                        l_diag_type := 'D';
                    ELSE
                        --When editing, it is necessary to check if the original request has been made by a nurse or
                        --by a phisician. If it was by a nurse, the content of this field is ICNP and not diagnosis
                    
                        SELECT t.id_prof_req
                          INTO l_id_prof_req
                          FROM (SELECT ntrh.id_prof_req,
                                       row_number() over(PARTITION BY ntrh.id_nurse_tea_req ORDER BY ntrh.dt_nurse_tea_req_tstz) AS rn
                                  FROM nurse_tea_req_hist ntrh
                                 WHERE ntrh.id_nurse_tea_req = i_tbl_nurse_tea_req(j)
                                   AND ntrh.flg_status = 'D') t
                         WHERE t.rn = 1;
                    
                        l_prof_req_category := pk_prof_utils.get_category(i_lang,
                                                                          profissional(l_id_prof_req,
                                                                                       i_prof.institution,
                                                                                       i_prof.software));
                    
                        IF l_prof_req_category = 'N'
                        THEN
                            l_diag_type := 'C'; --ICNP (Composition)
                        ELSE
                            l_diag_type := 'D'; --DIAGNOSIS
                        END IF;
                    END IF;
                
                    IF l_diag_type = 'D' --We may only create the XML when deailing with diagnosis
                    THEN
                        l_tbl_id_diagnosis       := table_number();
                        l_tbl_id_alert_diagnosis := table_number();
                    
                        SELECT ad.id_diagnosis, ad.id_alert_diagnosis
                          BULK COLLECT
                          INTO l_tbl_id_diagnosis, l_tbl_id_alert_diagnosis
                          FROM alert_diagnosis ad
                         WHERE ad.id_alert_diagnosis IN (SELECT *
                                                           FROM TABLE(i_tbl_val_array(i) (j)));
                    
                        IF l_tbl_id_diagnosis.count > 0
                        THEN
                        
                            l_tbl_diagnoses.extend();
                            l_tbl_diagnoses(l_tbl_diagnoses.count) := '<EPIS_DIAGNOSES ID_PATIENT="' || l_id_patient ||
                                                                      '" ID_EPISODE="' || i_id_episode ||
                                                                      '" PROF_CAT_TYPE="D" FLG_TYPE="P" FLG_EDIT_MODE="" ID_CDR_CALL="">
                            <EPIS_DIAGNOSIS ID_EPIS_DIAGNOSIS="" ID_EPIS_DIAGNOSIS_HIST="" FLG_TRANSF_FINAL="">
                              <CANCEL_REASON ID_CANCEL_REASON="" FLG_CANCEL_DIFF_DIAG="" /> ';
                        
                            FOR k IN l_tbl_id_diagnosis.first .. l_tbl_id_diagnosis.last
                            LOOP
                                l_tbl_diagnoses(l_tbl_diagnoses.count) := l_tbl_diagnoses(l_tbl_diagnoses.count) ||
                                                                          ' <DIAGNOSIS ID_DIAGNOSIS="' ||
                                                                          l_tbl_id_diagnosis(k) || '" ID_ALERT_DIAG="' ||
                                                                          l_tbl_id_alert_diagnosis(k) || '">
                                <DESC_DIAGNOSIS>undefined</DESC_DIAGNOSIS>
                                <DIAGNOSIS_WARNING_REPORT>Diagnosis with no form fields.</DIAGNOSIS_WARNING_REPORT>
                              </DIAGNOSIS> ';
                            END LOOP;
                        
                            l_tbl_diagnoses(l_tbl_diagnoses.count) := l_tbl_diagnoses(l_tbl_diagnoses.count) ||
                                                                      ' </EPIS_DIAGNOSIS>
                            <GENERAL_NOTES ID="" ID_CANCEL_REASON="" />
                          </EPIS_DIAGNOSES>';
                        ELSE
                            l_tbl_diagnoses.extend();
                        END IF;
                    ELSE
                        IF i_tbl_val_array(i).count > 0
                        THEN
                            l_tbl_compositions.extend();
                            l_tbl_compositions(l_tbl_compositions.count) := table_number();
                            FOR k IN i_tbl_val_array(i)(j).first .. i_tbl_val_array(i)(j).last
                            LOOP
                                l_tbl_compositions(l_tbl_compositions.count).extend();
                                l_tbl_compositions(l_tbl_compositions.count)(k) := to_number(i_tbl_val_array(i) (j) (k));
                            END LOOP;
                        ELSE
                            l_tbl_compositions.extend();
                            l_tbl_compositions(l_tbl_compositions.count) := table_number();
                        END IF;
                    
                        l_tbl_diagnoses.extend(); --To maintain consistency in pk_patient_education_ux
                    END IF;
                END LOOP;
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_clinical_indication_icnp_mw
            THEN
                FOR j IN l_topics.first .. l_topics.last
                LOOP
                    IF i_flg_edition = 'N'
                    THEN
                        --If this is a new request, we can assure that the content of this field is indeed ICNP,
                        --because this field is not available for the Nurse profile
                        l_diag_type := 'C';
                    ELSE
                        --When editing, it is necessary to check if the original request has been made by a nurse or
                        --by a phisician. If it was by a nurse, the content of this field is ICNP and not diagnosis
                        SELECT t.id_prof_req
                          INTO l_id_prof_req
                          FROM (SELECT ntrh.id_prof_req,
                                       row_number() over(PARTITION BY ntrh.id_nurse_tea_req ORDER BY ntrh.dt_nurse_tea_req_tstz) AS rn
                                  FROM nurse_tea_req_hist ntrh
                                 WHERE ntrh.id_nurse_tea_req = i_tbl_nurse_tea_req(j)
                                   AND ntrh.flg_status = 'D') t
                         WHERE t.rn = 1;
                    
                        l_prof_req_category := pk_prof_utils.get_category(i_lang,
                                                                          profissional(l_id_prof_req,
                                                                                       i_prof.institution,
                                                                                       i_prof.software));
                    
                        IF l_prof_req_category = 'N'
                        THEN
                            l_diag_type := 'C'; --ICNP (Composition)
                        ELSE
                            l_diag_type := 'D'; --DIAGNOSIS
                        END IF;
                    END IF;
                
                    IF l_diag_type = 'C'
                    THEN
                        IF i_tbl_val_array(i).count > 0
                        THEN
                            l_tbl_compositions.extend();
                            l_tbl_compositions(l_tbl_compositions.count) := table_number();
                            FOR k IN i_tbl_val_array(i)(j).first .. i_tbl_val_array(i)(j).last
                            LOOP
                                l_tbl_compositions(l_tbl_compositions.count).extend();
                                l_tbl_compositions(l_tbl_compositions.count)(k) := to_number(i_tbl_val_array(i) (j) (k));
                            END LOOP;
                        ELSE
                            l_tbl_compositions.extend();
                            l_tbl_compositions(l_tbl_compositions.count) := table_number();
                        END IF;
                    
                        l_tbl_diagnoses.extend(); --To maintain consistency in pk_patient_education_ux
                    ELSE
                        l_tbl_compositions.extend();
                        l_tbl_compositions(l_tbl_compositions.count) := table_number();
                    
                        l_tbl_id_diagnosis       := table_number();
                        l_tbl_id_alert_diagnosis := table_number();
                    
                        SELECT ad.id_diagnosis, ad.id_alert_diagnosis
                          BULK COLLECT
                          INTO l_tbl_id_diagnosis, l_tbl_id_alert_diagnosis
                          FROM alert_diagnosis ad
                         WHERE ad.id_alert_diagnosis IN (SELECT *
                                                           FROM TABLE(i_tbl_val_array(i) (j)));
                    
                        IF l_tbl_id_diagnosis.count > 0
                        THEN
                        
                            l_tbl_diagnoses.extend();
                            l_tbl_diagnoses(l_tbl_diagnoses.count) := '<EPIS_DIAGNOSES ID_PATIENT="' || l_id_patient ||
                                                                      '" ID_EPISODE="' || i_id_episode ||
                                                                      '" PROF_CAT_TYPE="D" FLG_TYPE="P" FLG_EDIT_MODE="" ID_CDR_CALL="">
                            <EPIS_DIAGNOSIS ID_EPIS_DIAGNOSIS="" ID_EPIS_DIAGNOSIS_HIST="" FLG_TRANSF_FINAL="">
                              <CANCEL_REASON ID_CANCEL_REASON="" FLG_CANCEL_DIFF_DIAG="" /> ';
                        
                            FOR k IN l_tbl_id_diagnosis.first .. l_tbl_id_diagnosis.last
                            LOOP
                                l_tbl_diagnoses(l_tbl_diagnoses.count) := l_tbl_diagnoses(l_tbl_diagnoses.count) ||
                                                                          ' <DIAGNOSIS ID_DIAGNOSIS="' ||
                                                                          l_tbl_id_diagnosis(k) || '" ID_ALERT_DIAG="' ||
                                                                          l_tbl_id_alert_diagnosis(k) || '">
                                <DESC_DIAGNOSIS>undefined</DESC_DIAGNOSIS>
                                <DIAGNOSIS_WARNING_REPORT>Diagnosis with no form fields.</DIAGNOSIS_WARNING_REPORT>
                              </DIAGNOSIS> ';
                            END LOOP;
                        
                            l_tbl_diagnoses(l_tbl_diagnoses.count) := l_tbl_diagnoses(l_tbl_diagnoses.count) ||
                                                                      ' </EPIS_DIAGNOSIS>
                            <GENERAL_NOTES ID="" ID_CANCEL_REASON="" />
                          </EPIS_DIAGNOSES>';
                        ELSE
                            l_tbl_diagnoses.extend();
                        END IF;
                    END IF;
                END LOOP;
            END IF;
        
            l_tbl_id_nurse_tea_req_sugg.extend();
            l_tbl_desc_topic_aux.extend();
            l_tbl_not_order_reason.extend();
        END LOOP;
    
        IF i_flg_edition = pk_alert_constant.g_no
        THEN
            IF NOT pk_patient_education_core.create_request(i_lang                  => i_lang,
                                                            i_prof                  => i_prof,
                                                            i_id_episode            => i_id_episode,
                                                            i_topics                => l_topics,
                                                            i_compositions          => l_tbl_compositions,
                                                            i_to_be_performed       => l_tbl_to_be_performed,
                                                            i_start_date            => l_tbl_start_date,
                                                            i_notes                 => l_tbl_notes,
                                                            i_description           => l_tbl_description,
                                                            i_order_recurr          => l_tbl_order_recurr,
                                                            i_draft                 => i_draft,
                                                            i_id_nurse_tea_req_sugg => l_tbl_id_nurse_tea_req_sugg,
                                                            i_desc_topic_aux        => l_tbl_desc_topic_aux,
                                                            i_diagnoses             => l_tbl_diagnoses,
                                                            i_not_order_reason      => l_tbl_not_order_reason,
                                                            i_flg_origin_req        => i_flg_origin_req,
                                                            o_id_nurse_tea_req      => o_id_nurse_tea_req,
                                                            o_id_nurse_tea_topic    => o_id_nurse_tea_topic,
                                                            o_title_topic           => o_title_topic,
                                                            o_desc_diagnosis        => o_desc_diagnosis,
                                                            o_error                 => o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSE
            IF NOT pk_patient_education_core.update_request(i_lang             => i_lang,
                                                            i_prof             => i_prof,
                                                            i_id_episode       => i_id_episode,
                                                            i_id_nurse_tea_req => i_tbl_nurse_tea_req,
                                                            i_topics           => l_topics,
                                                            i_compositions     => l_tbl_compositions,
                                                            i_to_be_performed  => l_tbl_to_be_performed,
                                                            i_start_date       => l_tbl_start_date,
                                                            i_notes            => l_tbl_notes,
                                                            i_description      => l_tbl_description,
                                                            i_order_recurr     => l_tbl_order_recurr,
                                                            i_upd_flg_status   => pk_alert_constant.g_yes,
                                                            i_diagnoses        => l_tbl_diagnoses,
                                                            i_not_order_reason => l_tbl_not_order_reason,
                                                            i_flg_origin_req   => i_flg_origin_req,
                                                            o_error            => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
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
                                              'CREATE_REQUEST',
                                              o_error);
        
            RETURN FALSE;
    END create_request;

    FUNCTION cancel_nurse_tea_req_int
    (
        i_lang             IN language.id_language%TYPE,
        i_nurse_tea_req    IN nurse_tea_req.id_nurse_tea_req%TYPE,
        i_prof_close       IN profissional,
        i_notes_close      IN nurse_tea_req.notes_close%TYPE,
        i_id_cancel_reason IN nurse_tea_req.id_cancel_reason%TYPE,
        i_flg_commit       IN VARCHAR2,
        i_flg_descontinue  IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_epis IS
            SELECT id_episode
              FROM nurse_tea_req
             WHERE id_nurse_tea_req = i_nurse_tea_req;
    
        CURSOR c_cancel IS
            SELECT flg_status
              FROM nurse_tea_req
             WHERE id_nurse_tea_req = i_nurse_tea_req;
    
        l_epis       episode.id_episode%TYPE;
        l_stat       nurse_tea_req.flg_status%TYPE;
        l_ntr_rowids table_varchar;
    
        l_count PLS_INTEGER;
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
        g_error        := 'OPEN c_cancel';
    
        OPEN c_cancel;
        FETCH c_cancel
            INTO l_stat;
        CLOSE c_cancel;
    
        g_error := 'prv_alter_ntr_by_id';
        pk_patient_education_utils.prv_alter_ntr_by_id(i_lang             => i_lang,
                                                       i_id_nurse_tea_req => i_nurse_tea_req,
                                                       i_flg_status       => CASE
                                                                                 WHEN i_flg_descontinue =
                                                                                      pk_alert_constant.g_yes THEN
                                                                                  pk_patient_education_constant.g_nurse_tea_req_descontinued
                                                                                 ELSE
                                                                                  pk_icnp_constant.g_epis_diag_status_cancelled
                                                                             END,
                                                       -- Jos� Brito 28/03/2008 WO11229
                                                       -- Ao cancelar era alterado o ID_PROF_REQ para o ID do profissional que CANCELOU.
                                                       -- Tal n�o deve acontecer. Passando o i_prof.ID como NULO n�o altera os dados da requisi��o.
                                                       i_id_prof_req => profissional(NULL,
                                                                                     i_prof_close.institution,
                                                                                     i_prof_close.software),
                                                       --
                                                       i_dt_close_str     => pk_date_utils.get_timestamp_str(i_lang,
                                                                                                             i_prof_close,
                                                                                                             g_sysdate_tstz,
                                                                                                             NULL),
                                                       i_id_prof_close    => i_prof_close.id,
                                                       i_notes_close      => i_notes_close,
                                                       i_id_cancel_reason => i_id_cancel_reason,
                                                       o_rowids           => l_ntr_rowids);
    
        g_error := 'CALL TO T_DATA_GOV_MNT.PROCESS_UPDATE - NURSE_TEA_REQ';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof_close,
                                      i_table_name   => 'NURSE_TEA_REQ',
                                      i_list_columns => table_varchar('id_nurse_tea_req',
                                                                      'id_prof_req',
                                                                      'id_episode',
                                                                      'req_header',
                                                                      'flg_status',
                                                                      'notes_req',
                                                                      'id_prof_close',
                                                                      'notes_close',
                                                                      'dt_nurse_tea_req_tstz',
                                                                      'dt_begin_tstz',
                                                                      'dt_close_tstz',
                                                                      'id_visit',
                                                                      'id_patient',
                                                                      'id_cancel_reason'),
                                      i_rowids       => l_ntr_rowids,
                                      o_error        => o_error);
    
        g_error := 'OPEN c_epis';
        OPEN c_epis;
        FETCH c_epis
            INTO l_epis;
        CLOSE c_epis;
    
        SELECT COUNT(1)
          INTO l_count
          FROM nurse_tea_req ntr
         WHERE ntr.id_order_recurr_plan IN
               (SELECT ntr_i.id_order_recurr_plan
                  FROM nurse_tea_req ntr_i
                 WHERE ntr_i.id_nurse_tea_req = i_nurse_tea_req)
           AND ntr.flg_status NOT IN ('F', 'C', 'X')
           AND ntr.id_order_recurr_plan IS NOT NULL;
    
        IF l_count = 0
        THEN
            UPDATE order_recurr_control orc
               SET orc.flg_status = 'F'
             WHERE orc.id_order_recurr_plan IN
                   (SELECT ntr_i.id_order_recurr_plan
                      FROM nurse_tea_req ntr_i
                     WHERE ntr_i.id_nurse_tea_req = i_nurse_tea_req);
        END IF;
    
        IF NOT t_ti_log.ins_log(i_lang,
                                i_prof_close,
                                l_epis,
                                l_stat,
                                i_nurse_tea_req,
                                pk_edis_summary.g_ti_log_nurse_tea,
                                o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        IF i_flg_commit = pk_alert_constant.g_yes
        THEN
            COMMIT;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_ret       BOOLEAN;
                l_error_s   VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, l_error_s);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_PATIENT_EDUCATION_DB', 'CANCEL_NURSE_TEA_REQ_INT');
                o_error := l_error_out;
                IF i_flg_commit = pk_alert_constant.g_yes
                THEN
                    pk_utils.undo_changes;
                END IF;
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END cancel_nurse_tea_req_int;

    --
    FUNCTION cancel_patient_education
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_req IN table_number,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes     IN nurse_tea_req.notes_close%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'Cancel patient education';
        FOR i IN 1 .. i_id_nurse_tea_req.count
        LOOP
        
            IF NOT pk_patient_education_core.cancel_nurse_tea_req_int(i_lang             => i_lang,
                                                                      i_nurse_tea_req    => i_id_nurse_tea_req(i),
                                                                      i_prof_close       => i_prof,
                                                                      i_notes_close      => i_cancel_notes,
                                                                      i_id_cancel_reason => i_id_cancel_reason,
                                                                      i_flg_commit       => pk_alert_constant.g_yes,
                                                                      o_error            => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            g_error := 'Add to history';
            insert_ntr_hist(i_lang             => i_lang,
                            i_prof             => i_prof,
                            i_id_nurse_tea_req => i_id_nurse_tea_req(i),
                            o_error            => o_error);
        
        END LOOP;
    
        COMMIT;
    
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
                                              'CANCEL_PATIENT_EDUCATION',
                                              o_error);
        
            RETURN FALSE;
    END cancel_patient_education;

    --

    --
    --
    FUNCTION get_domain_flg_time
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        o_values OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_time        sys_config.value%TYPE;
        l_flg_time_no_lst table_varchar;
    BEGIN
        g_error           := 'Return domain values';
        l_flg_time        := pk_sysconfig.get_config('FLG_TIME_P', i_prof.institution, i_prof.software);
        l_flg_time_no_lst := pk_string_utils.str_split(pk_sysconfig.get_config('FLG_TIME_NO_LIST', i_prof), '|');
    
        OPEN o_values FOR
            SELECT desc_val label,
                   val data,
                   img_name,
                   rank,
                   decode(l_flg_time, val, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_default
              FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang,
                                                                  i_prof,
                                                                  pk_patient_education_constant.g_sys_domain_flg_time,
                                                                  NULL))
             WHERE val NOT IN (SELECT column_value
                                 FROM TABLE(l_flg_time_no_lst));
    
        RETURN TRUE;
    
    END get_domain_flg_time;

    FUNCTION get_domain_flg_time
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN t_tbl_core_domain IS
    
        l_flg_time        sys_config.value%TYPE;
        l_flg_time_no_lst table_varchar;
    
        l_ret t_tbl_core_domain := t_tbl_core_domain();
    BEGIN
        g_error           := 'Return domain values';
        l_flg_time        := pk_sysconfig.get_config('FLG_TIME_P', i_prof.institution, i_prof.software);
        l_flg_time_no_lst := pk_string_utils.str_split(pk_sysconfig.get_config('FLG_TIME_NO_LIST', i_prof), '|');
    
        SELECT t_row_core_domain(internal_name => NULL,
                                 desc_domain   => label,
                                 domain_value  => data,
                                 order_rank    => rank,
                                 img_name      => NULL)
          BULK COLLECT
          INTO l_ret
          FROM (SELECT desc_val label, val data, img_name, rank
                  FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang,
                                                                      i_prof,
                                                                      pk_patient_education_constant.g_sys_domain_flg_time,
                                                                      NULL))
                 WHERE val NOT IN (SELECT column_value
                                     FROM TABLE(l_flg_time_no_lst)));
    
        RETURN l_ret;
    
    END get_domain_flg_time;

    FUNCTION get_default_domain_time
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_val      OUT VARCHAR2,
        o_desc_val OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_desc_val    VARCHAR2(200);
        l_val         VARCHAR2(30);
        l_img_name    VARCHAR2(200);
        l_rank        NUMBER(6);
        l_flg_default VARCHAR2(200);
    
        l_values pk_types.cursor_type;
    BEGIN
    
        IF NOT get_domain_flg_time(i_lang => i_lang, i_prof => i_prof, o_values => l_values, o_error => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        LOOP
            FETCH l_values
                INTO l_desc_val, l_val, l_img_name, l_rank, l_flg_default;
            EXIT WHEN l_values%NOTFOUND;
        
            IF l_flg_default = pk_alert_constant.g_yes
            THEN
                EXIT;
            END IF;
        END LOOP;
    
        IF l_flg_default = pk_alert_constant.g_yes
        THEN
            o_val      := l_val;
            o_desc_val := l_desc_val;
        END IF;
    
        RETURN TRUE;
    
    END get_default_domain_time;

    --
    FUNCTION get_request_for_update
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_req IN table_number,
        o_detail           OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        OPEN o_detail FOR
            SELECT /*+opt_estimate(table t rows=1)*/
             ntr.id_nurse_tea_req,
             ntr.id_nurse_tea_topic id_topic,
             pk_patient_education_utils.get_desc_topic(i_lang,
                                                       i_prof,
                                                       ntr.id_nurse_tea_topic,
                                                       ntr.desc_topic_aux,
                                                       ntt.code_nurse_tea_topic) title_topic,
             pk_translation.get_translation(i_lang, nts.code_nurse_tea_subject) desc_subject,
             pk_patient_education_utils.get_diagnosis(i_lang, i_prof, ntr.id_nurse_tea_req) clinical_indication,
             pk_patient_education_utils.get_id_diagnosis(i_lang, i_prof, ntr.id_nurse_tea_req) clinical_indication_id,
             pk_patient_education_utils.get_desc_diagnosis(i_lang, i_prof, ntr.id_nurse_tea_req) clinical_indication_desc,
             ntr.flg_time to_be_performed,
             pk_sysdomain.get_domain(pk_patient_education_constant.g_sys_domain_flg_time, ntr.flg_time, i_lang) to_be_performed_desc,
             NULL executions,
             pk_date_utils.get_timestamp_str(i_lang, i_prof, ntr.dt_begin_tstz, NULL) start_date,
             pk_date_utils.date_char(i_lang, ntr.dt_begin_tstz, i_prof.institution, i_prof.software) start_date_str,
             NULL duration,
             NULL end_date,
             NULL end_date_str,
             ntr.notes_req notes,
             --pk_string_utils.clob_to_plsqlvarchar2(ntr.description) desc_topic,
             ntr.description desc_topic,
             pk_patient_education_utils.get_instructions(i_lang, i_prof, ntr.id_nurse_tea_req) instructions,
             ntr.id_order_recurr_plan req_plan_id,
             pk_diagnosis.concat_diag_id(i_lang, NULL, NULL, NULL, i_prof, 'S', ntr.id_nurse_tea_req) id_alert_diagnosis,
             pk_not_order_reason_db.get_not_order_reason_id(i_lang                => i_lang,
                                                            i_id_not_order_reason => ntr.id_not_order_reason) not_order_reason_id,
             pk_not_order_reason_db.get_not_order_reason_desc(i_lang             => i_lang,
                                                              i_not_order_reason => ntr.id_not_order_reason) not_order_reason_desc,
             ntr.flg_status
              FROM nurse_tea_req ntr
              JOIN nurse_tea_topic ntt
                ON ntt.id_nurse_tea_topic = ntr.id_nurse_tea_topic
              JOIN nurse_tea_subject nts
                ON nts.id_nurse_tea_subject = ntt.id_nurse_tea_subject
              JOIN TABLE(i_id_nurse_tea_req) t
                ON t.column_value = ntr.id_nurse_tea_req;
    
        RETURN TRUE;
    
    END get_request_for_update;

    FUNCTION get_request_for_update
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN NUMBER,
        i_action           IN NUMBER,
        i_id_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE,
        i_idx              IN NUMBER,
        i_tbl_mkt_rel      IN table_number,
        io_tbl_resul       IN OUT t_tbl_ds_get_value,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_tbl_id_diag            table_number;
        l_tbl_id_alert_diagnosis table_number;
        l_tbl_diag_desc          table_varchar;
        l_flg_to_be_performed    nurse_tea_req.flg_time%TYPE;
        l_to_be_performed_desc   VARCHAR2(1000);
        l_notes                  nurse_tea_req.notes_req%TYPE;
        l_description            CLOB;
    
        l_id_order_recurr_plan nurse_tea_req.id_order_recurr_plan%TYPE;
    
        l_order_recurr_desc       VARCHAR2(1000);
        l_order_recurr_desc_other VARCHAR2(1000);
        l_order_recurr_option     order_recurr_plan.id_order_recurr_option%TYPE;
        l_start_date_tstz         nurse_tea_req.dt_begin_tstz%TYPE;
        l_occurrences             order_recurr_plan.occurrences%TYPE;
        l_duration                order_recurr_plan.duration%TYPE;
        l_unit_meas_duration      order_recurr_plan.id_unit_meas_duration%TYPE;
        l_duration_desc           VARCHAR2(1000);
        l_end_date_tstz           nurse_tea_req.dt_close_tstz%TYPE;
        l_flg_end_by_editable     VARCHAR2(2);
    
        l_ds_internal_name ds_component.internal_name%TYPE;
        l_id_ds_component  ds_component.id_ds_component%TYPE;
    
        l_tbl_id_prof_req   table_number;
        l_prof_req_category category.flg_type%TYPE;
    
        l_prof_category category.flg_type%TYPE;
    
        l_flg_event_type VARCHAR2(1);
    
    BEGIN
    
        --Determining the category of the professional that is making the update
        l_prof_category := pk_prof_utils.get_category(i_lang, i_prof);
    
        --Obtain the data for the first element of the i_id_nurse_tea_req array    
        SELECT pk_patient_education_utils.get_id_diagnosis(i_lang, i_prof, ntr.id_nurse_tea_req),
               pk_patient_education_utils.get_desc_diagnosis(i_lang, i_prof, ntr.id_nurse_tea_req),
               ntr.flg_time,
               pk_sysdomain.get_domain(pk_patient_education_constant.g_sys_domain_flg_time, ntr.flg_time, i_lang),
               ntr.notes_req,
               ntr.description,
               ntr.id_order_recurr_plan,
               ntr.dt_begin_tstz
          INTO l_tbl_id_diag,
               l_tbl_diag_desc,
               l_flg_to_be_performed,
               l_to_be_performed_desc,
               l_notes,
               l_description,
               l_id_order_recurr_plan,
               l_start_date_tstz
          FROM nurse_tea_req ntr
         WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req;
    
        --Determining the list of professionals that made the original requests
        SELECT DISTINCT t.id_prof_req
          BULK COLLECT
          INTO l_tbl_id_prof_req
          FROM (SELECT ntrh.id_prof_req,
                       row_number() over(PARTITION BY ntrh.id_nurse_tea_req ORDER BY ntrh.dt_nurse_tea_req_tstz) AS rn
                  FROM nurse_tea_req_hist ntrh
                 WHERE ntrh.id_nurse_tea_req = i_id_nurse_tea_req
                   AND ntrh.flg_status IN ('D', pk_patient_education_core.g_status_predefined)) t
         WHERE t.rn = 1;
    
        --Determining the category of each professional from the previous list and comparing them to the current user
        --If there is one or more records requested by a category differtent from the current user, l_flg_event_type will assume
        --the value 'read only'. This will be used for pk_orders_constant.g_ds_clinical_indication_mw
        --and pk_orders_constant.g_ds_clinical_indication_icnp_mw fields
        FOR i IN l_tbl_id_prof_req.first .. l_tbl_id_prof_req.last
        LOOP
            l_prof_req_category := pk_prof_utils.get_category(i_lang,
                                                              profissional(l_tbl_id_prof_req(i),
                                                                           i_prof.institution,
                                                                           i_prof.software));
            IF l_prof_req_category <> l_prof_category
            THEN
                l_flg_event_type := pk_orders_constant.g_component_read_only;
            ELSE
                l_flg_event_type := pk_orders_constant.g_component_active;
            END IF;
        END LOOP;
    
        IF l_id_order_recurr_plan IS NOT NULL
        THEN
            IF NOT pk_order_recurrence_core.get_order_recurr_instructions(i_lang                => i_lang,
                                                                          i_prof                => i_prof,
                                                                          i_order_plan          => l_id_order_recurr_plan,
                                                                          o_order_recurr_desc   => l_order_recurr_desc,
                                                                          o_order_recurr_option => l_order_recurr_option,
                                                                          o_start_date          => l_start_date_tstz,
                                                                          o_occurrences         => l_occurrences,
                                                                          o_duration            => l_duration,
                                                                          o_unit_meas_duration  => l_unit_meas_duration,
                                                                          o_end_date            => l_end_date_tstz,
                                                                          o_flg_end_by_editable => l_flg_end_by_editable,
                                                                          o_error               => o_error)
            THEN
                g_error := 'error found while calling pk_order_recurrence_core.get_order_recurr_instructions function';
                RAISE g_exception;
            END IF;
        
            IF l_order_recurr_option = -1
            THEN
                SELECT pk_translation.get_translation(i_lang, orp.code_order_recurr_option)
                  INTO l_order_recurr_desc_other
                  FROM order_recurr_option orp
                 WHERE orp.id_order_recurr_option = l_order_recurr_option;
            END IF;
        ELSE
            --ONCE
            l_flg_end_by_editable := pk_alert_constant.g_no;
            l_order_recurr_option := 0;
            l_occurrences         := 1;
        
            SELECT pk_translation.get_translation(i_lang, orp.code_order_recurr_option)
              INTO l_order_recurr_desc
              FROM order_recurr_option orp
             WHERE orp.id_order_recurr_option = 0;
        END IF;
    
        FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
        LOOP
            l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
            l_id_ds_component  := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
        
            IF l_ds_internal_name IN
               (pk_orders_constant.g_ds_clinical_indication_mw, pk_orders_constant.g_ds_clinical_indication_icnp_mw)
               AND l_tbl_id_diag.count > 0
               AND i_id_nurse_tea_req IS NOT NULL
            THEN
                --Only phisician have access to the g_ds_clinical_indication_mw field
                --Only nurses have acces to the g_ds_clinical_indication_icnp_mw
                --If a nurse is editing a record requested by a physician, the field g_ds_clinical_indication_icnp_mw will automatically be 'read-onlu'
                --If a physician is editing a record requested by a nurse, the field g_ds_clinical_indication_mw will automatically be 'read-only'
            
                --This select will fetch the id_alert_diagnosis from the array l_tbl_id_diag
                --This array can also hold the values of ICNP, however, if this query return results,
                --it means that this array refers to diagnosis (thus made by a physician) and not ICNP
                SELECT ad.id_alert_diagnosis
                  BULK COLLECT
                  INTO l_tbl_id_alert_diagnosis
                  FROM epis_diagnosis ed
                  JOIN alert_diagnosis ad
                    ON ad.id_alert_diagnosis = ed.id_alert_diagnosis
                 WHERE ad.id_diagnosis IN (SELECT * /*+opt_estimate(table t rows=1)*/
                                             FROM TABLE(l_tbl_id_diag) t)
                   AND ed.id_episode = i_episode
                 ORDER BY ed.id_diagnosis;
            
                IF l_tbl_id_alert_diagnosis.count > 0
                THEN
                    --l_tbl_id_alert_diagnosis.count > 0 means that original request has been made by a physician, 
                    --and that the records to be shown on this field refer to diagnosis
                    FOR j IN l_tbl_id_alert_diagnosis.first .. l_tbl_id_alert_diagnosis.last
                    LOOP
                        io_tbl_resul.extend();
                        io_tbl_resul(io_tbl_resul.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => l_ds_internal_name,
                                                                               VALUE              => to_char(l_tbl_id_alert_diagnosis(j)),
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => l_tbl_diag_desc(j),
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_orders_constant.g_component_valid,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => l_flg_event_type,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                    END LOOP;
                ELSE
                    --l_tbl_id_alert_diagnosis.count = 0 means that original request has been made by a nurse, 
                    --and that the records to be shown on this field refer to ICNP
                    FOR j IN l_tbl_id_diag.first .. l_tbl_id_diag.last
                    LOOP
                        io_tbl_resul.extend();
                        io_tbl_resul(io_tbl_resul.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => l_ds_internal_name,
                                                                               VALUE              => to_char(l_tbl_id_diag(j)),
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => l_tbl_diag_desc(j),
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_orders_constant.g_component_valid,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => l_flg_event_type,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                    END LOOP;
                END IF;
            ELSIF l_ds_internal_name = pk_orders_constant.g_ds_clinical_indication_mw
            THEN
                io_tbl_resul.extend();
                io_tbl_resul(io_tbl_resul.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                       id_ds_component    => l_id_ds_component,
                                                                       internal_name      => l_ds_internal_name,
                                                                       VALUE              => NULL,
                                                                       value_clob         => NULL,
                                                                       min_value          => NULL,
                                                                       max_value          => NULL,
                                                                       desc_value         => NULL,
                                                                       desc_clob          => NULL,
                                                                       id_unit_measure    => NULL,
                                                                       desc_unit_measure  => NULL,
                                                                       flg_validation     => pk_orders_constant.g_component_valid,
                                                                       err_msg            => NULL,
                                                                       flg_event_type     => CASE i_action
                                                                                                 WHEN
                                                                                                  pk_order_sets.g_order_set_bo_edit_task THEN
                                                                                                  pk_orders_constant.g_component_inactive
                                                                                                 WHEN
                                                                                                  pk_order_sets.g_order_set_fo_request THEN
                                                                                                  pk_orders_constant.g_component_inactive
                                                                                                 ELSE
                                                                                                  l_flg_event_type
                                                                                             END,
                                                                       flg_multi_status   => NULL,
                                                                       idx                => i_idx);
            ELSIF l_ds_internal_name = pk_orders_constant.g_ds_clinical_indication_icnp_mw
            THEN
                io_tbl_resul.extend();
                io_tbl_resul(io_tbl_resul.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                       id_ds_component    => l_id_ds_component,
                                                                       internal_name      => l_ds_internal_name,
                                                                       VALUE              => NULL,
                                                                       value_clob         => NULL,
                                                                       min_value          => NULL,
                                                                       max_value          => NULL,
                                                                       desc_value         => NULL,
                                                                       desc_clob          => NULL,
                                                                       id_unit_measure    => NULL,
                                                                       desc_unit_measure  => NULL,
                                                                       flg_validation     => pk_orders_constant.g_component_valid,
                                                                       err_msg            => NULL,
                                                                       flg_event_type     => l_flg_event_type,
                                                                       flg_multi_status   => NULL,
                                                                       idx                => i_idx);
            ELSIF l_ds_internal_name = pk_orders_constant.g_ds_to_be_executed
            THEN
                io_tbl_resul.extend();
                io_tbl_resul(io_tbl_resul.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                       id_ds_component    => l_id_ds_component,
                                                                       internal_name      => l_ds_internal_name,
                                                                       VALUE              => l_flg_to_be_performed,
                                                                       value_clob         => NULL,
                                                                       min_value          => NULL,
                                                                       max_value          => NULL,
                                                                       desc_value         => l_to_be_performed_desc,
                                                                       desc_clob          => NULL,
                                                                       id_unit_measure    => NULL,
                                                                       desc_unit_measure  => NULL,
                                                                       flg_validation     => pk_orders_constant.g_component_valid,
                                                                       err_msg            => NULL,
                                                                       flg_event_type     => CASE i_action
                                                                                                 WHEN
                                                                                                  pk_order_sets.g_order_set_bo_edit_task THEN
                                                                                                  pk_orders_constant.g_component_read_only
                                                                                                 ELSE
                                                                                                  pk_orders_constant.g_component_active
                                                                                             END,
                                                                       flg_multi_status   => NULL,
                                                                       idx                => i_idx);
            ELSIF l_ds_internal_name = pk_orders_constant.g_ds_notes_clob
            THEN
                io_tbl_resul.extend();
                io_tbl_resul(io_tbl_resul.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                       id_ds_component    => l_id_ds_component,
                                                                       internal_name      => l_ds_internal_name,
                                                                       VALUE              => NULL,
                                                                       value_clob         => NULL,
                                                                       min_value          => NULL,
                                                                       max_value          => NULL,
                                                                       desc_value         => NULL,
                                                                       desc_clob          => l_notes,
                                                                       id_unit_measure    => NULL,
                                                                       desc_unit_measure  => NULL,
                                                                       flg_validation     => pk_orders_constant.g_component_valid,
                                                                       err_msg            => NULL,
                                                                       flg_event_type     => pk_orders_constant.g_component_active,
                                                                       flg_multi_status   => NULL,
                                                                       idx                => i_idx);
            ELSIF l_ds_internal_name = pk_orders_constant.g_ds_description
            THEN
                io_tbl_resul.extend();
                io_tbl_resul(io_tbl_resul.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                       id_ds_component    => l_id_ds_component,
                                                                       internal_name      => l_ds_internal_name,
                                                                       VALUE              => NULL,
                                                                       value_clob         => NULL,
                                                                       min_value          => NULL,
                                                                       max_value          => NULL,
                                                                       desc_value         => NULL,
                                                                       desc_clob          => l_description,
                                                                       id_unit_measure    => NULL,
                                                                       desc_unit_measure  => NULL,
                                                                       flg_validation     => pk_orders_constant.g_component_valid,
                                                                       err_msg            => NULL,
                                                                       flg_event_type     => pk_orders_constant.g_component_active,
                                                                       flg_multi_status   => NULL,
                                                                       idx                => i_idx);
            ELSIF l_ds_internal_name = pk_orders_constant.g_ds_start_date
            THEN
                io_tbl_resul.extend();
                io_tbl_resul(io_tbl_resul.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                       id_ds_component    => l_id_ds_component,
                                                                       internal_name      => l_ds_internal_name,
                                                                       VALUE              => pk_date_utils.date_send_tsz(i_lang => i_lang,
                                                                                                                         i_date => l_start_date_tstz,
                                                                                                                         i_prof => i_prof),
                                                                       value_clob         => NULL,
                                                                       min_value          => NULL,
                                                                       max_value          => NULL,
                                                                       desc_value         => NULL,
                                                                       desc_clob          => NULL,
                                                                       id_unit_measure    => NULL,
                                                                       desc_unit_measure  => NULL,
                                                                       flg_validation     => pk_orders_constant.g_component_valid,
                                                                       err_msg            => NULL,
                                                                       flg_event_type     => CASE i_action
                                                                                                 WHEN
                                                                                                  pk_order_sets.g_order_set_bo_edit_task THEN
                                                                                                  pk_orders_constant.g_component_inactive
                                                                                                 ELSE
                                                                                                  pk_orders_constant.g_component_mandatory
                                                                                             END,
                                                                       flg_multi_status   => NULL,
                                                                       idx                => i_idx);
            ELSIF l_ds_internal_name = pk_orders_constant.g_ds_frequency
            THEN
                io_tbl_resul.extend();
                io_tbl_resul(io_tbl_resul.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                       id_ds_component    => l_id_ds_component,
                                                                       internal_name      => l_ds_internal_name,
                                                                       VALUE              => l_order_recurr_option,
                                                                       value_clob         => NULL,
                                                                       min_value          => NULL,
                                                                       max_value          => NULL,
                                                                       desc_value         => CASE
                                                                                                 WHEN l_order_recurr_option = -1 THEN
                                                                                                  l_order_recurr_desc_other
                                                                                                 ELSE
                                                                                                  l_order_recurr_desc
                                                                                             END,
                                                                       desc_clob          => NULL,
                                                                       id_unit_measure    => NULL,
                                                                       desc_unit_measure  => NULL,
                                                                       flg_validation     => pk_orders_constant.g_component_valid,
                                                                       err_msg            => NULL,
                                                                       flg_event_type     => pk_orders_constant.g_component_mandatory,
                                                                       flg_multi_status   => NULL,
                                                                       idx                => i_idx);
            ELSIF l_ds_internal_name = pk_orders_constant.g_ds_other_frequency
                  AND l_order_recurr_option = -1
            THEN
                io_tbl_resul.extend();
                io_tbl_resul(io_tbl_resul.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                       id_ds_component    => l_id_ds_component,
                                                                       internal_name      => l_ds_internal_name,
                                                                       VALUE              => l_order_recurr_desc,
                                                                       value_clob         => NULL,
                                                                       min_value          => NULL,
                                                                       max_value          => NULL,
                                                                       desc_value         => l_order_recurr_desc,
                                                                       desc_clob          => NULL,
                                                                       id_unit_measure    => NULL,
                                                                       desc_unit_measure  => NULL,
                                                                       flg_validation     => pk_orders_constant.g_component_valid,
                                                                       err_msg            => NULL,
                                                                       flg_event_type     => pk_orders_constant.g_component_mandatory,
                                                                       flg_multi_status   => NULL,
                                                                       idx                => i_idx);
            ELSIF l_ds_internal_name = pk_orders_constant.g_ds_executions
            THEN
                io_tbl_resul.extend();
                io_tbl_resul(io_tbl_resul.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                       id_ds_component    => l_id_ds_component,
                                                                       internal_name      => l_ds_internal_name,
                                                                       VALUE              => l_occurrences,
                                                                       value_clob         => NULL,
                                                                       min_value          => NULL,
                                                                       max_value          => NULL,
                                                                       desc_value         => l_occurrences,
                                                                       desc_clob          => NULL,
                                                                       id_unit_measure    => NULL,
                                                                       desc_unit_measure  => NULL,
                                                                       flg_validation     => pk_orders_constant.g_component_valid,
                                                                       err_msg            => NULL,
                                                                       flg_event_type     => CASE l_flg_end_by_editable
                                                                                                 WHEN pk_alert_constant.g_yes THEN
                                                                                                  pk_orders_constant.g_component_active
                                                                                                 ELSE
                                                                                                  pk_orders_constant.g_component_read_only
                                                                                             END,
                                                                       flg_multi_status   => NULL,
                                                                       idx                => i_idx);
            ELSIF l_ds_internal_name = pk_orders_constant.g_ds_duration
            THEN
                io_tbl_resul.extend();
                io_tbl_resul(io_tbl_resul.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                       id_ds_component    => l_id_ds_component,
                                                                       internal_name      => l_ds_internal_name,
                                                                       VALUE              => l_duration,
                                                                       value_clob         => NULL,
                                                                       min_value          => NULL,
                                                                       max_value          => NULL,
                                                                       desc_value         => CASE
                                                                                                 WHEN l_duration IS NULL THEN
                                                                                                  NULL
                                                                                                 ELSE
                                                                                                  l_duration || ' ' ||
                                                                                                  pk_unit_measure.get_unit_measure_description(i_lang         => i_lang,
                                                                                                                                               i_prof         => i_prof,
                                                                                                                                               i_unit_measure => l_unit_meas_duration)
                                                                                             END,
                                                                       desc_clob          => NULL,
                                                                       id_unit_measure    => l_unit_meas_duration,
                                                                       desc_unit_measure  => pk_unit_measure.get_unit_measure_description(i_lang         => i_lang,
                                                                                                                                          i_prof         => i_prof,
                                                                                                                                          i_unit_measure => l_unit_meas_duration),
                                                                       flg_validation     => pk_orders_constant.g_component_valid,
                                                                       err_msg            => NULL,
                                                                       flg_event_type     => CASE l_flg_end_by_editable
                                                                                                 WHEN pk_alert_constant.g_yes THEN
                                                                                                  pk_orders_constant.g_component_active
                                                                                                 ELSE
                                                                                                  pk_orders_constant.g_component_inactive
                                                                                             END,
                                                                       flg_multi_status   => NULL,
                                                                       idx                => i_idx);
            ELSIF l_ds_internal_name = pk_orders_constant.g_ds_end_date
            THEN
                io_tbl_resul.extend();
                io_tbl_resul(io_tbl_resul.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                       id_ds_component    => l_id_ds_component,
                                                                       internal_name      => l_ds_internal_name,
                                                                       VALUE              => pk_date_utils.date_send_tsz(i_lang => i_lang,
                                                                                                                         i_date => l_end_date_tstz,
                                                                                                                         i_prof => i_prof),
                                                                       value_clob         => NULL,
                                                                       min_value          => NULL,
                                                                       max_value          => NULL,
                                                                       desc_value         => pk_date_utils.date_send_tsz(i_lang => i_lang,
                                                                                                                         i_date => l_end_date_tstz,
                                                                                                                         i_prof => i_prof),
                                                                       desc_clob          => NULL,
                                                                       id_unit_measure    => NULL,
                                                                       desc_unit_measure  => NULL,
                                                                       flg_validation     => pk_orders_constant.g_component_valid,
                                                                       err_msg            => NULL,
                                                                       flg_event_type     => CASE i_action
                                                                                                 WHEN
                                                                                                  pk_order_sets.g_order_set_bo_edit_task THEN
                                                                                                  pk_orders_constant.g_component_inactive
                                                                                                 ELSE
                                                                                                  CASE
                                                                                                   l_flg_end_by_editable
                                                                                                      WHEN
                                                                                                       pk_alert_constant.g_yes THEN
                                                                                                       pk_orders_constant.g_component_active
                                                                                                      ELSE
                                                                                                       pk_orders_constant.g_component_inactive
                                                                                                  END
                                                                                             END,
                                                                       flg_multi_status   => NULL,
                                                                       idx                => i_idx);
            ELSIF l_ds_internal_name = pk_orders_constant.g_ds_dummy_number
            THEN
                SELECT ntr.id_order_recurr_plan
                  INTO l_id_order_recurr_plan
                  FROM nurse_tea_req ntr
                 WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req;
            
                IF l_id_order_recurr_plan IS NULL
                THEN
                    IF NOT pk_order_recurrence_core.edit_order_recurr_plan(i_lang                   => i_lang,
                                                                           i_prof                   => i_prof,
                                                                           i_order_recurr_area      => 'PATIENT_EDUCATION',
                                                                           i_order_recurr_option    => NULL,
                                                                           i_start_date             => l_start_date_tstz,
                                                                           i_occurrences            => NULL,
                                                                           i_duration               => NULL,
                                                                           i_unit_meas_duration     => NULL,
                                                                           i_end_date               => NULL,
                                                                           i_order_recurr_plan_from => NULL,
                                                                           o_order_recurr_desc      => l_order_recurr_desc,
                                                                           o_order_recurr_option    => l_order_recurr_option,
                                                                           o_start_date             => l_start_date_tstz,
                                                                           o_occurrences            => l_occurrences,
                                                                           o_duration               => l_duration,
                                                                           o_unit_meas_duration     => l_unit_meas_duration,
                                                                           o_end_date               => l_end_date_tstz,
                                                                           o_flg_end_by_editable    => l_flg_end_by_editable,
                                                                           o_order_recurr_plan      => l_id_order_recurr_plan,
                                                                           o_error                  => o_error)
                    THEN
                        g_error := 'error found while calling pk_order_recurrence_core.edit_order_recurr_plan function';
                        RAISE g_exception;
                    END IF;
                ELSE
                    IF NOT pk_order_recurrence_core.copy_order_recurr_plan(i_lang                   => i_lang,
                                                                           i_prof                   => i_prof,
                                                                           i_order_recurr_plan_from => l_id_order_recurr_plan,
                                                                           o_order_recurr_desc      => l_order_recurr_desc,
                                                                           o_order_recurr_option    => l_order_recurr_option,
                                                                           o_start_date             => l_start_date_tstz,
                                                                           o_occurrences            => l_occurrences,
                                                                           o_duration               => l_duration,
                                                                           o_unit_meas_duration     => l_unit_meas_duration,
                                                                           o_end_date               => l_end_date_tstz,
                                                                           o_flg_end_by_editable    => l_flg_end_by_editable,
                                                                           o_order_recurr_plan      => l_id_order_recurr_plan,
                                                                           o_error                  => o_error)
                    THEN
                        g_error := 'error found while calling pk_order_recurrence_core.copy_order_recurr_plan function';
                        RAISE g_exception;
                    END IF;
                END IF;
            
                io_tbl_resul.extend();
                io_tbl_resul(io_tbl_resul.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                       id_ds_component    => l_id_ds_component,
                                                                       internal_name      => l_ds_internal_name,
                                                                       VALUE              => l_id_order_recurr_plan,
                                                                       value_clob         => NULL,
                                                                       min_value          => NULL,
                                                                       max_value          => NULL,
                                                                       desc_value         => NULL,
                                                                       desc_clob          => NULL,
                                                                       id_unit_measure    => NULL,
                                                                       desc_unit_measure  => NULL,
                                                                       flg_validation     => pk_orders_constant.g_component_valid,
                                                                       err_msg            => NULL,
                                                                       flg_event_type     => pk_orders_constant.g_component_active,
                                                                       flg_multi_status   => NULL,
                                                                       idx                => i_idx);
            END IF;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END get_request_for_update;
    --
    FUNCTION get_patient_education_det
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE,
        o_register         OUT pk_types.cursor_type,
        o_detail           OUT pk_types.cursor_type,
        o_main             OUT pk_types.cursor_type,
        o_data             OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_date_req VARCHAR2(4000);
    
        l_request_rank CONSTANT PLS_INTEGER := 0;
    
        l_patient_education_m026 sys_message.desc_message%TYPE;
        l_patient_education_m027 sys_message.desc_message%TYPE;
        l_patient_education_m029 sys_message.desc_message%TYPE;
        l_patient_education_m028 sys_message.desc_message%TYPE;
        l_patient_education_m030 sys_message.desc_message%TYPE;
        l_patient_education_m031 sys_message.desc_message%TYPE;
        l_patient_education_m041 sys_message.desc_message%TYPE;
        l_patient_education_m042 sys_message.desc_message%TYPE;
        l_patient_education_m045 sys_message.desc_message%TYPE;
        l_common_m130            sys_message.desc_message%TYPE;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        -- MENSAGENS
        l_patient_education_m026 := pk_message.get_message(i_lang      => i_lang,
                                                           i_prof      => i_prof,
                                                           i_code_mess => 'PATIENT_EDUCATION_M026');
        l_patient_education_m027 := pk_message.get_message(i_lang      => i_lang,
                                                           i_prof      => i_prof,
                                                           i_code_mess => 'PATIENT_EDUCATION_M027');
        l_patient_education_m028 := pk_message.get_message(i_lang      => i_lang,
                                                           i_prof      => i_prof,
                                                           i_code_mess => 'PATIENT_EDUCATION_M028');
        l_patient_education_m029 := pk_message.get_message(i_lang      => i_lang,
                                                           i_prof      => i_prof,
                                                           i_code_mess => 'PATIENT_EDUCATION_M029');
        l_patient_education_m030 := pk_message.get_message(i_lang      => i_lang,
                                                           i_prof      => i_prof,
                                                           i_code_mess => 'PATIENT_EDUCATION_M030');
        l_patient_education_m031 := pk_message.get_message(i_lang      => i_lang,
                                                           i_prof      => i_prof,
                                                           i_code_mess => 'PATIENT_EDUCATION_M031');
        l_patient_education_m041 := pk_message.get_message(i_lang      => i_lang,
                                                           i_prof      => i_prof,
                                                           i_code_mess => 'PATIENT_EDUCATION_M041');
        l_patient_education_m042 := pk_message.get_message(i_lang      => i_lang,
                                                           i_prof      => i_prof,
                                                           i_code_mess => 'PATIENT_EDUCATION_M042');
        l_patient_education_m045 := pk_message.get_message(i_lang      => i_lang,
                                                           i_prof      => i_prof,
                                                           i_code_mess => 'PATIENT_EDUCATION_M045');
        l_common_m130            := pk_message.get_message(i_lang      => i_lang,
                                                           i_prof      => i_prof,
                                                           i_code_mess => pk_not_order_reason_db.g_mcode_not_ordered_label);
        OPEN o_register FOR
        -- DRAFT  (w/o hist)
            SELECT 'DRAFT' flg_type,
                   ntr.id_nurse_tea_req id,
                   l_patient_education_m026 title,
                   l_request_rank num_order,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, ntr.dt_nurse_tea_req_tstz, i_prof) date_reg,
                   pk_date_utils.get_timestamp_str(i_lang, i_prof, ntr.dt_nurse_tea_req_tstz, NULL) TIMESTAMP,
                   ntr.id_prof_req id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ntr.id_prof_req) name_sig,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    ntr.id_prof_req,
                                                    ntr.dt_nurse_tea_req_tstz,
                                                    ntr.id_episode) spec_sig
              FROM nurse_tea_req ntr
             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntr.flg_status = pk_patient_education_constant.g_nurse_tea_req_draft
               AND NOT EXISTS
             (SELECT ntrh.id_nurse_tea_req_hist
                      FROM nurse_tea_req_hist ntrh
                     WHERE ntrh.id_nurse_tea_req = ntr.id_nurse_tea_req
                       AND ntrh.flg_status = pk_patient_education_constant.g_nurse_tea_req_draft)
            UNION ALL
            -- DRAFT (w/ hist)
            SELECT 'DRAFTH' flg_type,
                   ntr.id_nurse_tea_req id,
                   l_patient_education_m026 title,
                   l_request_rank num_order,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, ntr.dt_nurse_tea_req_tstz, i_prof) date_reg,
                   pk_date_utils.get_timestamp_str(i_lang, i_prof, ntr.dt_nurse_tea_req_tstz, NULL) TIMESTAMP,
                   ntr.id_prof_req id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ntr.id_prof_req) name_sig,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    ntr.id_prof_req,
                                                    ntr.dt_nurse_tea_req_tstz,
                                                    ntr.id_episode) spec_sig
              FROM nurse_tea_req_hist ntr
             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntr.id_nurse_tea_req_hist = (SELECT MIN(id_nurse_tea_req_hist)
                                                  FROM nurse_tea_req_hist
                                                 WHERE id_nurse_tea_req = ntr.id_nurse_tea_req
                                                   AND flg_status = ntr.flg_status)
               AND ntr.flg_status = pk_patient_education_constant.g_nurse_tea_req_draft
            UNION ALL
            -- request (w/o hist)
            SELECT 'REQ' flg_type,
                   ntr.id_nurse_tea_req id,
                   l_patient_education_m026 title,
                   l_request_rank num_order,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, ntr.dt_nurse_tea_req_tstz, i_prof) date_reg,
                   pk_date_utils.get_timestamp_str(i_lang, i_prof, ntr.dt_nurse_tea_req_tstz, NULL) TIMESTAMP,
                   ntr.id_prof_req id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ntr.id_prof_req) name_sig,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    ntr.id_prof_req,
                                                    ntr.dt_nurse_tea_req_tstz,
                                                    ntr.id_episode) spec_sig
              FROM nurse_tea_req ntr
             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntr.flg_status = pk_patient_education_constant.g_nurse_tea_req_pend
               AND NOT EXISTS (SELECT ntrh.id_nurse_tea_req_hist
                      FROM nurse_tea_req_hist ntrh
                     WHERE ntrh.id_nurse_tea_req = ntr.id_nurse_tea_req
                       AND ntrh.flg_status = pk_patient_education_constant.g_nurse_tea_req_pend)
            UNION ALL
            -- request (w/ hist)
            SELECT 'RQH' flg_type,
                   ntrh.id_nurse_tea_req id,
                   l_patient_education_m026 title,
                   l_request_rank num_order,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, ntrh.dt_nurse_tea_req_tstz, i_prof) date_reg,
                   pk_date_utils.get_timestamp_str(i_lang, i_prof, ntrh.dt_nurse_tea_req_tstz, NULL) TIMESTAMP,
                   ntrh.id_prof_req id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ntrh.id_prof_req) name_sig,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    ntrh.id_prof_req,
                                                    ntrh.dt_nurse_tea_req_tstz,
                                                    ntrh.id_episode) spec_sig
              FROM nurse_tea_req_hist ntrh
             WHERE ntrh.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntrh.id_nurse_tea_req_hist = (SELECT MIN(id_nurse_tea_req_hist)
                                                   FROM nurse_tea_req_hist
                                                  WHERE id_nurse_tea_req = ntrh.id_nurse_tea_req
                                                    AND flg_status = ntrh.flg_status)
               AND ntrh.flg_status = pk_patient_education_constant.g_nurse_tea_req_pend
            -- cancelation
            UNION ALL
            SELECT 'CAN' flg_type,
                   ntr.id_nurse_tea_req id,
                   l_patient_education_m027 title,
                   0 num_order,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, ntr.dt_close_tstz, i_prof) date_reg,
                   pk_date_utils.get_timestamp_str(i_lang, i_prof, ntr.dt_close_tstz, NULL) TIMESTAMP,
                   ntr.id_prof_req id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ntr.id_prof_close) name_sig,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    ntr.id_prof_close,
                                                    ntr.dt_close_tstz,
                                                    ntr.id_episode) spec_sig
              FROM nurse_tea_req ntr
             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntr.flg_status = pk_patient_education_constant.g_nurse_tea_req_canc
            UNION ALL
            SELECT 'DIS' flg_type,
                   ntr.id_nurse_tea_req id,
                   l_patient_education_m045 title,
                   0 num_order,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, ntr.dt_close_tstz, i_prof) date_reg,
                   pk_date_utils.get_timestamp_str(i_lang, i_prof, ntr.dt_close_tstz, NULL) TIMESTAMP,
                   ntr.id_prof_req id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ntr.id_prof_close) name_sig,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    ntr.id_prof_close,
                                                    ntr.dt_close_tstz,
                                                    ntr.id_episode) spec_sig
              FROM nurse_tea_req ntr
             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntr.flg_status = pk_patient_education_constant.g_nurse_tea_req_descontinued
            -- suggestion (w/o hist)
            UNION ALL
            SELECT 'SUG' flg_type,
                   ntr.id_nurse_tea_req id,
                   l_patient_education_m029 title,
                   0 num_order,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, ntr.dt_nurse_tea_req_tstz, i_prof) date_reg,
                   pk_date_utils.get_timestamp_str(i_lang, i_prof, ntr.dt_nurse_tea_req_tstz, NULL) TIMESTAMP,
                   ntr.id_prof_req id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ntr.id_prof_req) name_sig,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    ntr.id_prof_req,
                                                    ntr.dt_nurse_tea_req_tstz,
                                                    ntr.id_episode) spec_sig
              FROM nurse_tea_req ntr
             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntr.flg_status = pk_patient_education_constant.g_nurse_tea_req_sug
               AND NOT EXISTS (SELECT ntrh.id_nurse_tea_req_hist
                      FROM nurse_tea_req_hist ntrh
                     WHERE ntrh.id_nurse_tea_req = ntr.id_nurse_tea_req
                       AND ntrh.flg_status = pk_patient_education_constant.g_nurse_tea_req_sug)
            -- suggestion (w/ hist)
            UNION ALL
            SELECT 'SGH' flg_type,
                   ntrh.id_nurse_tea_req id,
                   l_patient_education_m029 title,
                   0 num_order,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, ntrh.dt_nurse_tea_req_tstz, i_prof) date_reg,
                   pk_date_utils.get_timestamp_str(i_lang, i_prof, ntrh.dt_nurse_tea_req_tstz, NULL) TIMESTAMP,
                   ntrh.id_prof_req id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ntrh.id_prof_req) name_sig,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    ntrh.id_prof_req,
                                                    ntrh.dt_nurse_tea_req_tstz,
                                                    ntrh.id_episode) spec_sig
              FROM nurse_tea_req_hist ntrh
             WHERE ntrh.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntrh.id_nurse_tea_req_hist = (SELECT MIN(id_nurse_tea_req_hist)
                                                   FROM nurse_tea_req_hist
                                                  WHERE id_nurse_tea_req = ntrh.id_nurse_tea_req
                                                    AND flg_status = ntrh.flg_status)
               AND ntrh.flg_status = pk_patient_education_constant.g_nurse_tea_req_sug
            -- ignored suggestion
            UNION ALL
            SELECT 'IGN' flg_type,
                   ntr.id_nurse_tea_req id,
                   l_patient_education_m030 title,
                   0 num_order,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, ntr.dt_nurse_tea_req_tstz, i_prof) date_reg,
                   pk_date_utils.get_timestamp_str(i_lang, i_prof, ntr.dt_nurse_tea_req_tstz, NULL) TIMESTAMP,
                   ntr.id_prof_close id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ntr.id_prof_close) name_sig,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    ntr.id_prof_close,
                                                    ntr.dt_nurse_tea_req_tstz,
                                                    ntr.id_episode) spec_sig
              FROM nurse_tea_req ntr
             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntr.flg_status = pk_patient_education_constant.g_nurse_tea_req_ign
            -- execution
            UNION ALL
            SELECT 'EXE' flg_type,
                   ntd.id_nurse_tea_det id,
                   l_patient_education_m028 title,
                   ntd.num_order,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, ntd.dt_nurse_tea_det_tstz, i_prof) date_reg,
                   pk_date_utils.get_timestamp_str(i_lang, i_prof, ntd.dt_nurse_tea_det_tstz, NULL) TIMESTAMP,
                   ntd.id_prof_provider id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ntd.id_prof_provider) name_sig,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    ntd.id_prof_provider,
                                                    ntd.dt_nurse_tea_det_tstz,
                                                    ntr.id_episode) spec_sig
              FROM nurse_tea_det ntd
              JOIN nurse_tea_req ntr
                ON ntr.id_nurse_tea_req = ntd.id_nurse_tea_req
             WHERE ntd.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntd.flg_status = pk_patient_education_constant.g_nurse_tea_det_exec
            -- cancelled execution
            UNION ALL
            SELECT 'CEX' flg_type,
                   ntd.id_nurse_tea_det id,
                   l_patient_education_m031 title,
                   ntd.num_order,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, ntd.dt_nurse_tea_det_tstz, i_prof) date_reg,
                   pk_date_utils.get_timestamp_str(i_lang, i_prof, ntd.dt_nurse_tea_det_tstz, NULL) TIMESTAMP,
                   ntd.id_prof_provider id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ntd.id_prof_provider) name_sig,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    ntd.id_prof_provider,
                                                    ntd.dt_nurse_tea_det_tstz,
                                                    ntr.id_episode) spec_sig
              FROM nurse_tea_det ntd
              JOIN nurse_tea_req ntr
                ON ntr.id_nurse_tea_req = ntd.id_nurse_tea_req
             WHERE ntd.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntd.flg_status = pk_patient_education_constant.g_nurse_tea_det_canc
            UNION ALL
            --edited
            SELECT 'EDTD' flg_type,
                   ntrh.id_nurse_tea_req_hist id,
                   l_patient_education_m041 title,
                   l_request_rank num_order,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, ntrh.dt_nurse_tea_req_hist_tstz, i_prof) date_reg,
                   pk_date_utils.get_timestamp_str(i_lang, i_prof, ntrh.dt_nurse_tea_req_hist_tstz, NULL) TIMESTAMP,
                   ntrh.id_prof_req id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ntrh.id_prof_req) name_sig,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    ntrh.id_prof_req,
                                                    ntrh.dt_nurse_tea_req_hist_tstz,
                                                    ntrh.id_episode) spec_sig
              FROM (SELECT id_nurse_tea_req_hist
                      FROM (SELECT ntr.id_nurse_tea_req_hist,
                                   lag(ntr.notes_req, 1) over(ORDER BY ntr.dt_nurse_tea_req_hist_tstz) AS prev_notes_req,
                                   ntr.notes_req,
                                   --lag(ntr.c_description, 1) over(ORDER BY ntr.dt_nurse_tea_req_hist_tstz) AS prev_description,
                                   --null prev_description,
                                   --ntr.c_description,
                                   lag(ntr.id_order_recurr_plan, 1) over(ORDER BY ntr.dt_nurse_tea_req_hist_tstz) AS prev_id_order_recurr_plan,
                                   ntr.id_order_recurr_plan,
                                   lag(ntr.flg_time, 1) over(ORDER BY ntr.dt_nurse_tea_req_hist_tstz) AS prev_flg_time,
                                   ntr.flg_time,
                                   lag(ntr.id_not_order_reason, 1) over(ORDER BY ntr.dt_nurse_tea_req_hist_tstz) AS prev_id_not_order_reason,
                                   ntr.id_not_order_reason,
                                   ntr.diagnosis AS current_diag,
                                   lag(ntr.diagnosis, 1) over(ORDER BY ntr.id_nurse_tea_req_hist ASC) AS prev_diag
                              FROM (SELECT ntr.id_nurse_tea_req_hist,
                                           ntr.notes_req,
                                           --to_char(ntr.description) c_description,
                                           -- ntr.description c_description,
                                           ntr.id_order_recurr_plan,
                                           ntr.flg_time,
                                           ntr.id_not_order_reason,
                                           ntr.dt_nurse_tea_req_hist_tstz,
                                           dh.dt_nurse_tea_req_diag_tstz,
                                           listagg(dh.id_diagnosis, '|') within GROUP(ORDER BY dh.id_diagnosis ASC) AS diagnosis
                                      FROM nurse_tea_req_hist ntr
                                      LEFT JOIN nurse_tea_req_diag_hist dh
                                        ON dh.id_nurse_tea_req_hist = ntr.id_nurse_tea_req_hist
                                     WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
                                     GROUP BY ntr.id_nurse_tea_req_hist,
                                              ntr.notes_req,
                                              --ntr.description,
                                              ntr.id_order_recurr_plan,
                                              ntr.flg_time,
                                              ntr.id_not_order_reason,
                                              dt_nurse_tea_req_hist_tstz,
                                              dh.dt_nurse_tea_req_diag_tstz) ntr)
                     WHERE (nvl(prev_notes_req, 'NULL') <> nvl(notes_req, 'NULL') OR
                           /* REPLACE(REPLACE(pk_string_utils.clob_to_plsqlvarchar2(prev_description), chr(13), ''),
                           chr(10),
                           '') <>
                           REPLACE(REPLACE(pk_string_utils.clob_to_plsqlvarchar2(c_description), chr(13), ''),
                           chr(10),
                           '') OR*/
                           nvl(id_order_recurr_plan, -1) <> nvl(prev_id_order_recurr_plan, -1) OR
                           nvl(flg_time, -1) <> nvl(prev_flg_time, -1) OR
                           (nvl(id_not_order_reason, -1) <> nvl(prev_id_not_order_reason, -1) AND
                           prev_id_not_order_reason IS NOT NULL) OR nvl(current_diag, -1) <> nvl(prev_diag, -1))
                       AND id_nurse_tea_req_hist <>
                           (SELECT MIN(ntr.id_nurse_tea_req_hist)
                              FROM nurse_tea_req_hist ntr
                             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req)
                    UNION
                    -- id_composition
                    SELECT z.id_nurse_tea_req_hist
                      FROM (SELECT ntdh.dt_nurse_tea_req_diag_tstz,
                                   ntdh.id_nurse_tea_req,
                                   ntdh.id_nurse_tea_req_hist,
                                   listagg(pk_patient_education_utils.get_composition_hist(i_lang          => i_lang,
                                                                                           i_prof          => i_prof,
                                                                                           i_nurse_tea_req => ntdh.id_nurse_tea_req_hist),
                                           '; ') within GROUP(ORDER BY ntdh.id_diagnosis) id_diagnosis1
                              FROM nurse_tea_req_diag_hist ntdh
                             WHERE ntdh.id_nurse_tea_req = i_id_nurse_tea_req
                             GROUP BY ntdh.dt_nurse_tea_req_diag_tstz, ntdh.id_nurse_tea_req, ntdh.id_nurse_tea_req_hist) x
                      JOIN (SELECT ntdh.dt_nurse_tea_req_diag_tstz,
                                  ntdh.id_nurse_tea_req,
                                  ntdh.id_nurse_tea_req_hist,
                                  listagg(pk_patient_education_utils.get_composition_hist(i_lang          => i_lang,
                                                                                          i_prof          => i_prof,
                                                                                          i_nurse_tea_req => ntdh.id_nurse_tea_req_hist),
                                          '; ') within GROUP(ORDER BY ntdh.id_diagnosis) id_diagnosis2
                             FROM nurse_tea_req_diag_hist ntdh
                            WHERE ntdh.id_nurse_tea_req = i_id_nurse_tea_req
                            GROUP BY ntdh.dt_nurse_tea_req_diag_tstz, ntdh.id_nurse_tea_req, ntdh.id_nurse_tea_req_hist) z
                        ON x.id_nurse_tea_req = z.id_nurse_tea_req
                       AND x.dt_nurse_tea_req_diag_tstz < z.dt_nurse_tea_req_diag_tstz
                     WHERE nvl(id_diagnosis1, 'NULL') != nvl(id_diagnosis2, 'NULL')) n
              JOIN nurse_tea_req_hist ntrh
                ON ntrh.id_nurse_tea_req_hist = n.id_nurse_tea_req_hist
            -- expired task
            UNION ALL
            SELECT 'EXP' flg_type,
                   ntr.id_nurse_tea_req id,
                   l_patient_education_m042 title,
                   l_request_rank num_order,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, ntr.dt_close_tstz, i_prof) date_reg,
                   pk_date_utils.get_timestamp_str(i_lang, i_prof, ntr.dt_close_tstz, NULL) TIMESTAMP,
                   ntr.id_prof_req id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ntr.id_prof_close) name_sig,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    ntr.id_prof_close,
                                                    ntr.dt_close_tstz,
                                                    ntr.id_episode) spec_sig
              FROM nurse_tea_req ntr
             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntr.flg_status = pk_patient_education_constant.g_nurse_tea_req_expired
            -- not order reason
            UNION ALL
            SELECT 'NOR' flg_type,
                   ntr.id_nurse_tea_req id,
                   l_common_m130 title,
                   0 num_order,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, ntr.dt_nurse_tea_req_tstz, i_prof) date_reg,
                   pk_date_utils.get_timestamp_str(i_lang, i_prof, ntr.dt_nurse_tea_req_tstz, NULL) TIMESTAMP,
                   ntr.id_prof_req id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ntr.id_prof_req) name_sig,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    ntr.id_prof_req,
                                                    ntr.dt_nurse_tea_req_tstz,
                                                    ntr.id_episode) spec_sig
              FROM nurse_tea_req ntr
             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntr.flg_status = pk_patient_education_constant.g_nurse_tea_req_not_ord_reas
               AND NOT EXISTS
             (SELECT ntrh.id_nurse_tea_req_hist
                      FROM nurse_tea_req_hist ntrh
                     WHERE ntrh.id_nurse_tea_req = ntr.id_nurse_tea_req
                       AND ntrh.flg_status = pk_patient_education_constant.g_nurse_tea_req_not_ord_reas)
            -- not order reason (hist)
            UNION ALL
            SELECT 'NRH' flg_type,
                   ntrh.id_nurse_tea_req id,
                   l_common_m130 title,
                   0 num_order,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, ntrh.dt_nurse_tea_req_tstz, i_prof) date_reg,
                   pk_date_utils.get_timestamp_str(i_lang, i_prof, ntrh.dt_nurse_tea_req_tstz, NULL) TIMESTAMP,
                   ntrh.id_prof_req id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ntrh.id_prof_req) name_sig,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    ntrh.id_prof_req,
                                                    ntrh.dt_nurse_tea_req_tstz,
                                                    ntrh.id_episode) spec_sig
              FROM nurse_tea_req_hist ntrh
             WHERE ntrh.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntrh.id_nurse_tea_req_hist = (SELECT MIN(id_nurse_tea_req_hist)
                                                   FROM nurse_tea_req_hist
                                                  WHERE id_nurse_tea_req = ntrh.id_nurse_tea_req
                                                    AND flg_status = ntrh.flg_status)
               AND ntrh.flg_status = pk_patient_education_constant.g_nurse_tea_req_not_ord_reas
             ORDER BY TIMESTAMP DESC;
        --
    
        OPEN o_detail FOR
        -- DRAFT (w/o hist)
            SELECT 'DRAFT' flg_type,
                   ntr.id_nurse_tea_req id,
                   table_varchar('SUBJECT',
                                 'TOPIC',
                                 'CLINICAL_INDICATION',
                                 'TO_BE_PERFORMED',
                                 'FREQUENCY',
                                 'START_DATE',
                                 'REQ_NOTES',
                                 'DESCRIPTION',
                                 'STATUS') code,
                   table_varchar(pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M013'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M025'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M008'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M009'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_T041'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M010'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M012'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M014'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M039')) label,
                   table_varchar(pk_translation.get_translation(i_lang, nts.code_nurse_tea_subject),
                                  pk_patient_education_utils.get_desc_topic(i_lang,
                                                                            i_prof,
                                                                            ntr.id_nurse_tea_topic,
                                                                            ntr.desc_topic_aux,
                                                                            ntt.code_nurse_tea_topic),
                                  pk_patient_education_utils.get_diagnosis(i_lang, i_prof, ntr.id_nurse_tea_req),
                                  pk_sysdomain.get_domain(pk_patient_education_constant.g_sys_domain_flg_time,
                                                          ntr.flg_time,
                                                          i_lang),
                                  nvl(pk_order_recurrence_api_db.get_order_recurr_plan_desc(i_lang,
                                                                                            i_prof,
                                                                                            ntr.id_order_recurr_plan),
                                      
                                      pk_translation.get_translation(i_lang,
                                                                     'ORDER_RECURR_OPTION.CODE_ORDER_RECURR_OPTION.0')),
                                  pk_date_utils.date_char_tsz(i_lang,
                                                              ntr.dt_begin_tstz,
                                                              i_prof.institution,
                                                              i_prof.software),
                                  ntr.notes_req,
                                  NULL,
                                  pk_message.get_message(i_lang,
                                                         CASE
                                                             WHEN ntr.flg_status = pk_patient_education_constant.g_nurse_tea_req_fin THEN
                                                              'PATIENT_EDUCATION_M038'
                                                             WHEN ntr.flg_status = pk_patient_education_constant.g_nurse_tea_req_pend THEN
                                                              CASE
                                                                  WHEN ntr.flg_time = pk_patient_education_constant.g_flg_time_next THEN
                                                                   'PATIENT_EDUCATION_M036'
                                                                  WHEN ntr.dt_begin_tstz > g_sysdate_tstz THEN
                                                                   'PATIENT_EDUCATION_M036'
                                                                  ELSE
                                                                   'PATIENT_EDUCATION_M043'
                                                              END
                                                             WHEN ntr.flg_status = pk_patient_education_constant.g_nurse_tea_req_act THEN
                                                              'PATIENT_EDUCATION_M037'
                                                         END)) data
              FROM nurse_tea_req ntr
              JOIN nurse_tea_topic ntt
                ON ntt.id_nurse_tea_topic = ntr.id_nurse_tea_topic
              JOIN nurse_tea_subject nts
                ON nts.id_nurse_tea_subject = ntt.id_nurse_tea_subject
             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntr.flg_status = pk_patient_education_constant.g_nurse_tea_req_draft
               AND NOT EXISTS
             (SELECT ntrh.id_nurse_tea_req_hist
                      FROM nurse_tea_req_hist ntrh
                     WHERE ntrh.id_nurse_tea_req = ntr.id_nurse_tea_req
                       AND ntrh.flg_status = pk_patient_education_constant.g_nurse_tea_req_draft)
            UNION ALL
            -- DRAFT (with hist)           
            SELECT 'DRAFTH' flg_type,
                   ntr.id_nurse_tea_req id,
                   table_varchar('SUBJECT',
                                 'TOPIC',
                                 'CLINICAL_INDICATION',
                                 'TO_BE_PERFORMED',
                                 'FREQUENCY',
                                 'START_DATE',
                                 'REQ_NOTES',
                                 'DESCRIPTION',
                                 'STATUS') code,
                   table_varchar(pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M013'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M025'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M008'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M009'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_T041'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M010'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M012'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M014'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M039')) label,
                   table_varchar(pk_translation.get_translation(i_lang, nts.code_nurse_tea_subject),
                                 pk_patient_education_utils.get_desc_topic(i_lang,
                                                                           i_prof,
                                                                           ntr.id_nurse_tea_topic,
                                                                           ntr.desc_topic_aux,
                                                                           ntt.code_nurse_tea_topic),
                                 pk_patient_education_utils.get_diagnosis(i_lang, i_prof, ntr.id_nurse_tea_req),
                                 pk_sysdomain.get_domain(pk_patient_education_constant.g_sys_domain_flg_time,
                                                         ntr.flg_time,
                                                         i_lang),
                                 nvl(pk_order_recurrence_api_db.get_order_recurr_plan_desc(i_lang,
                                                                                           i_prof,
                                                                                           ntr.id_order_recurr_plan),
                                     pk_translation.get_translation(i_lang,
                                                                    'ORDER_RECURR_OPTION.CODE_ORDER_RECURR_OPTION.0')),
                                 pk_date_utils.date_char_tsz(i_lang,
                                                             ntr.dt_begin_tstz,
                                                             i_prof.institution,
                                                             i_prof.software),
                                 ntr.notes_req,
                                 NULL,
                                 pk_message.get_message(i_lang,
                                                        CASE
                                                            WHEN ntr.flg_status = pk_patient_education_constant.g_nurse_tea_req_fin THEN
                                                             'PATIENT_EDUCATION_M038'
                                                            WHEN ntr.flg_status = pk_patient_education_constant.g_nurse_tea_req_pend THEN
                                                             CASE
                                                                 WHEN ntr.flg_time = pk_patient_education_constant.g_flg_time_next THEN
                                                                  'PATIENT_EDUCATION_M036'
                                                                 WHEN ntr.dt_begin_tstz > g_sysdate_tstz THEN
                                                                  'PATIENT_EDUCATION_M036'
                                                                 ELSE
                                                                  'PATIENT_EDUCATION_M043'
                                                             END
                                                            WHEN ntr.flg_status = pk_patient_education_constant.g_nurse_tea_req_act THEN
                                                             'PATIENT_EDUCATION_M037'
                                                        END)) data
              FROM nurse_tea_req_hist ntr
              JOIN nurse_tea_topic ntt
                ON ntt.id_nurse_tea_topic = ntr.id_nurse_tea_topic
              JOIN nurse_tea_subject nts
                ON nts.id_nurse_tea_subject = ntt.id_nurse_tea_subject
             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntr.id_nurse_tea_req_hist = (SELECT MIN(id_nurse_tea_req_hist)
                                                  FROM nurse_tea_req_hist
                                                 WHERE id_nurse_tea_req = ntr.id_nurse_tea_req
                                                   AND flg_status = ntr.flg_status)
               AND ntr.flg_status = pk_patient_education_constant.g_nurse_tea_req_draft
            UNION ALL
            -- request (w/o hist)
            SELECT 'REQ' flg_type,
                   ntr.id_nurse_tea_req id,
                   table_varchar('SUBJECT',
                                 'TOPIC',
                                 'CLINICAL_INDICATION',
                                 'TO_BE_PERFORMED',
                                 'FREQUENCY',
                                 'START_DATE',
                                 'REQ_NOTES',
                                 'DESCRIPTION',
                                 'STATUS') code,
                   table_varchar(pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M013'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M025'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M008'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M009'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_T041'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M010'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M012'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M014'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M039')) label,
                   table_varchar(pk_translation.get_translation(i_lang, nts.code_nurse_tea_subject),
                                 pk_patient_education_utils.get_desc_topic(i_lang,
                                                                           i_prof,
                                                                           ntr.id_nurse_tea_topic,
                                                                           ntr.desc_topic_aux,
                                                                           ntt.code_nurse_tea_topic),
                                 pk_patient_education_utils.get_diagnosis(i_lang, i_prof, ntr.id_nurse_tea_req),
                                 pk_sysdomain.get_domain(pk_patient_education_constant.g_sys_domain_flg_time,
                                                         ntr.flg_time,
                                                         i_lang),
                                 nvl(pk_order_recurrence_api_db.get_order_recurr_plan_desc(i_lang,
                                                                                           i_prof,
                                                                                           ntr.id_order_recurr_plan),
                                     pk_translation.get_translation(i_lang,
                                                                    'ORDER_RECURR_OPTION.CODE_ORDER_RECURR_OPTION.0')),
                                 pk_date_utils.date_char_tsz(i_lang,
                                                             ntr.dt_begin_tstz,
                                                             i_prof.institution,
                                                             i_prof.software),
                                 ntr.notes_req,
                                 NULL,
                                 pk_message.get_message(i_lang,
                                                        CASE
                                                            WHEN ntr.flg_status = pk_patient_education_constant.g_nurse_tea_req_fin THEN
                                                             'PATIENT_EDUCATION_M038'
                                                            WHEN ntr.flg_status = pk_patient_education_constant.g_nurse_tea_req_pend THEN
                                                             CASE
                                                                 WHEN ntr.flg_time = pk_patient_education_constant.g_flg_time_next THEN
                                                                  'PATIENT_EDUCATION_M036'
                                                                 WHEN ntr.dt_begin_tstz > g_sysdate_tstz THEN
                                                                  'PATIENT_EDUCATION_M036'
                                                                 ELSE
                                                                  'PATIENT_EDUCATION_M043'
                                                             END
                                                            WHEN ntr.flg_status = pk_patient_education_constant.g_nurse_tea_req_act THEN
                                                             'PATIENT_EDUCATION_M037'
                                                        END)) data
              FROM nurse_tea_req ntr
              JOIN nurse_tea_topic ntt
                ON ntt.id_nurse_tea_topic = ntr.id_nurse_tea_topic
              JOIN nurse_tea_subject nts
                ON nts.id_nurse_tea_subject = ntt.id_nurse_tea_subject
             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntr.flg_status IN (pk_patient_education_constant.g_nurse_tea_req_pend,
                                      pk_patient_education_constant.g_nurse_tea_req_act,
                                      pk_patient_education_constant.g_nurse_tea_req_fin)
               AND NOT EXISTS (SELECT ntrh.id_nurse_tea_req_hist
                      FROM nurse_tea_req_hist ntrh
                     WHERE ntrh.id_nurse_tea_req = ntr.id_nurse_tea_req
                       AND ntrh.flg_status = pk_patient_education_constant.g_nurse_tea_req_pend)
            UNION ALL
            -- request (w/ hist)
            SELECT 'RQH' flg_type,
                   ntr.id_nurse_tea_req id,
                   table_varchar('SUBJECT',
                                 'TOPIC',
                                 'CLINICAL_INDICATION',
                                 'TO_BE_PERFORMED',
                                 'FREQUENCY',
                                 'START_DATE',
                                 'REQ_NOTES',
                                 'DESCRIPTION',
                                 'STATUS') code,
                   table_varchar(pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M013'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M025'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M008'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M009'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_T041'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M010'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M012'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M014'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M039')) label,
                   table_varchar(pk_translation.get_translation(i_lang, nts.code_nurse_tea_subject),
                                 pk_patient_education_utils.get_desc_topic(i_lang,
                                                                           i_prof,
                                                                           ntr.id_nurse_tea_topic,
                                                                           ntr.desc_topic_aux,
                                                                           ntt.code_nurse_tea_topic),
                                 pk_patient_education_utils.get_diagnosis_hist(i_lang, i_prof, ntr.id_nurse_tea_req_hist),
                                 pk_sysdomain.get_domain(pk_patient_education_constant.g_sys_domain_flg_time,
                                                         ntr.flg_time,
                                                         i_lang),
                                 nvl(pk_order_recurrence_api_db.get_order_recurr_plan_desc(i_lang,
                                                                                           i_prof,
                                                                                           ntr.id_order_recurr_plan),
                                     pk_translation.get_translation(i_lang,
                                                                    'ORDER_RECURR_OPTION.CODE_ORDER_RECURR_OPTION.0')),
                                 pk_date_utils.date_char_tsz(i_lang,
                                                             ntr.dt_begin_tstz,
                                                             i_prof.institution,
                                                             i_prof.software),
                                 ntr.notes_req,
                                 NULL,
                                 pk_message.get_message(i_lang,
                                                        CASE ntr.flg_status
                                                            WHEN pk_patient_education_constant.g_nurse_tea_req_fin THEN
                                                             'PATIENT_EDUCATION_M038'
                                                            WHEN pk_patient_education_constant.g_nurse_tea_req_pend THEN
                                                             CASE
                                                                 WHEN ntr.flg_time = pk_patient_education_constant.g_flg_time_next THEN
                                                                  'PATIENT_EDUCATION_M036'
                                                                 WHEN ntr.dt_begin_tstz > g_sysdate_tstz THEN
                                                                  'PATIENT_EDUCATION_M036'
                                                                 ELSE
                                                                  'PATIENT_EDUCATION_M043'
                                                             END
                                                            WHEN pk_patient_education_constant.g_nurse_tea_req_act THEN
                                                             'PATIENT_EDUCATION_M037'
                                                            ELSE
                                                             NULL
                                                        END)) data
              FROM nurse_tea_req_hist ntr
              JOIN nurse_tea_topic ntt
                ON ntt.id_nurse_tea_topic = ntr.id_nurse_tea_topic
              JOIN nurse_tea_subject nts
                ON nts.id_nurse_tea_subject = ntt.id_nurse_tea_subject
             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntr.id_nurse_tea_req_hist = (SELECT MIN(id_nurse_tea_req_hist)
                                                  FROM nurse_tea_req_hist
                                                 WHERE id_nurse_tea_req = ntr.id_nurse_tea_req
                                                   AND flg_status = ntr.flg_status)
               AND ntr.flg_status = pk_patient_education_constant.g_nurse_tea_req_pend
            -- cancelation
            UNION ALL
            SELECT 'CAN' flg_type,
                   ntr.id_nurse_tea_req id,
                   table_varchar('CANCEL_REASON', 'CANCEL_NOTES') code,
                   table_varchar(pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M032'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M033')) label,
                   table_varchar(pk_translation.get_translation(i_lang, cr.code_cancel_reason), ntr.notes_close) data
              FROM nurse_tea_req ntr
              JOIN cancel_reason cr
                ON cr.id_cancel_reason = ntr.id_cancel_reason
             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntr.flg_status = pk_patient_education_constant.g_nurse_tea_req_canc
            UNION ALL
            SELECT 'DIS' flg_type,
                   ntr.id_nurse_tea_req id,
                   table_varchar('CANCEL_REASON', 'CANCEL_NOTES') code,
                   table_varchar(pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M046'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M033')) label,
                   table_varchar(pk_translation.get_translation(i_lang, cr.code_cancel_reason), ntr.notes_close) data
              FROM nurse_tea_req ntr
              JOIN cancel_reason cr
                ON cr.id_cancel_reason = ntr.id_cancel_reason
             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntr.flg_status = pk_patient_education_constant.g_nurse_tea_req_descontinued
            -- suggestion (w/o hist)
            UNION ALL
            SELECT 'SUG' flg_type,
                   ntr.id_nurse_tea_req id,
                   table_varchar('SUBJECT',
                                 'TOPIC',
                                 'CLINICAL_INDICATION',
                                 'TO_BE_PERFORMED',
                                 'FREQUENCY',
                                 'START_DATE',
                                 'REQ_NOTES',
                                 'DESCRIPTION') code,
                   table_varchar(pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M013'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M025'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M008'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M009'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_T041'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M010'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M012'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M014')) label,
                   table_varchar(pk_translation.get_translation(i_lang, nts.code_nurse_tea_subject),
                                 pk_patient_education_utils.get_desc_topic(i_lang,
                                                                           i_prof,
                                                                           ntr.id_nurse_tea_topic,
                                                                           ntr.desc_topic_aux,
                                                                           ntt.code_nurse_tea_topic),
                                 pk_patient_education_utils.get_diagnosis(i_lang, i_prof, ntr.id_nurse_tea_req),
                                 pk_sysdomain.get_domain(pk_patient_education_constant.g_sys_domain_flg_time,
                                                         ntr.flg_time,
                                                         i_lang),
                                 nvl(pk_order_recurrence_api_db.get_order_recurr_plan_desc(i_lang,
                                                                                           i_prof,
                                                                                           ntr.id_order_recurr_plan),
                                     pk_translation.get_translation(i_lang,
                                                                    'ORDER_RECURR_OPTION.CODE_ORDER_RECURR_OPTION.0')),
                                 pk_date_utils.date_char_tsz(i_lang,
                                                             ntr.dt_begin_tstz,
                                                             i_prof.institution,
                                                             i_prof.software),
                                 ntr.notes_req,
                                 NULL) data
              FROM nurse_tea_req ntr
              JOIN nurse_tea_topic ntt
                ON ntt.id_nurse_tea_topic = ntr.id_nurse_tea_topic
              JOIN nurse_tea_subject nts
                ON nts.id_nurse_tea_subject = ntt.id_nurse_tea_subject
             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntr.flg_status = pk_patient_education_constant.g_nurse_tea_req_sug
               AND NOT EXISTS (SELECT ntrh.id_nurse_tea_req_hist
                      FROM nurse_tea_req_hist ntrh
                     WHERE ntrh.id_nurse_tea_req = ntr.id_nurse_tea_req
                       AND ntrh.flg_status = pk_patient_education_constant.g_nurse_tea_req_sug)
            -- suggestion (w/ hist)
            UNION ALL
            SELECT 'SGH' flg_type,
                   ntr.id_nurse_tea_req id,
                   table_varchar('SUBJECT',
                                 'TOPIC',
                                 'CLINICAL_INDICATION',
                                 'TO_BE_PERFORMED',
                                 'FREQUENCY',
                                 'START_DATE',
                                 'REQ_NOTES',
                                 'DESCRIPTION') code,
                   table_varchar(pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M013'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M025'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M008'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M009'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_T041'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M010'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M012'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M014')) label,
                   table_varchar(pk_translation.get_translation(i_lang, nts.code_nurse_tea_subject),
                                 pk_patient_education_utils.get_desc_topic(i_lang,
                                                                           i_prof,
                                                                           ntr.id_nurse_tea_topic,
                                                                           ntr.desc_topic_aux,
                                                                           ntt.code_nurse_tea_topic),
                                 pk_patient_education_utils.get_diagnosis(i_lang, i_prof, ntr.id_nurse_tea_req),
                                 pk_sysdomain.get_domain(pk_patient_education_constant.g_sys_domain_flg_time,
                                                         ntr.flg_time,
                                                         i_lang),
                                 nvl(pk_order_recurrence_api_db.get_order_recurr_plan_desc(i_lang,
                                                                                           i_prof,
                                                                                           ntr.id_order_recurr_plan),
                                     pk_translation.get_translation(i_lang,
                                                                    'ORDER_RECURR_OPTION.CODE_ORDER_RECURR_OPTION.0')),
                                 pk_date_utils.date_char_tsz(i_lang,
                                                             ntr.dt_begin_tstz,
                                                             i_prof.institution,
                                                             i_prof.software),
                                 ntr.notes_req,
                                 NULL) data
              FROM nurse_tea_req_hist ntr
              JOIN nurse_tea_topic ntt
                ON ntt.id_nurse_tea_topic = ntr.id_nurse_tea_topic
              JOIN nurse_tea_subject nts
                ON nts.id_nurse_tea_subject = ntt.id_nurse_tea_subject
             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntr.id_nurse_tea_req_hist = (SELECT MAX(id_nurse_tea_req_hist)
                                                  FROM nurse_tea_req_hist
                                                 WHERE id_nurse_tea_req = ntr.id_nurse_tea_req
                                                   AND flg_status = ntr.flg_status)
               AND ntr.flg_status = pk_patient_education_constant.g_nurse_tea_req_sug
            -- execution
            UNION ALL
            SELECT 'EXE' flg_type,
                   ntd.id_nurse_tea_det id,
                   CASE
                       WHEN ntr.flg_status = 'F'
                            AND ntd.id_nurse_tea_det =
                            (SELECT ntdz.id_nurse_tea_det
                                   FROM nurse_tea_det ntdz
                                  WHERE ntdz.id_nurse_tea_req = ntr.id_nurse_tea_req
                                    AND ntdz.flg_status = ntd.flg_status
                                    AND ntdz.num_order =
                                        (SELECT MAX(ntdx.num_order)
                                           FROM nurse_tea_det ntdx
                                          WHERE ntdx.id_nurse_tea_req = ntr.id_nurse_tea_req))
                            OR ntr.flg_status = pk_patient_education_constant.g_nurse_tea_req_act THEN
                        table_varchar('CLINICAL_INDICATION',
                                      'GOALS',
                                      'METHOD',
                                      'GIVEN_TO',
                                      'DELIVERABLES',
                                      'UNDERSTANDING',
                                      'START_DATE',
                                      'DURATION',
                                      'END_DATE',
                                      'DESCRIPTION',
                                      'STATUS')
                       ELSE
                        table_varchar('CLINICAL_INDICATION',
                                      'GOALS',
                                      'METHOD',
                                      'GIVEN_TO',
                                      'DELIVERABLES',
                                      'UNDERSTANDING',
                                      'START_DATE',
                                      'DURATION',
                                      'END_DATE',
                                      'DESCRIPTION')
                   END code,
                   CASE
                       WHEN ntr.flg_status = 'F'
                            AND ntd.id_nurse_tea_det =
                            (SELECT ntdz.id_nurse_tea_det
                                   FROM nurse_tea_det ntdz
                                  WHERE ntdz.id_nurse_tea_req = ntr.id_nurse_tea_req
                                    AND ntdz.flg_status = ntd.flg_status
                                    AND ntdz.num_order =
                                        (SELECT MAX(ntdx.num_order)
                                           FROM nurse_tea_det ntdx
                                          WHERE ntdx.id_nurse_tea_req = ntr.id_nurse_tea_req))
                            OR ntr.flg_status = pk_patient_education_constant.g_nurse_tea_req_act THEN
                        table_varchar(pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M015'),
                                      pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M016'),
                                      pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M017'),
                                      pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M018'),
                                      pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M019'),
                                      pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M020'),
                                      pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M021'),
                                      pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M022'),
                                      pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M023'),
                                      pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M024'),
                                      pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M039'))
                       ELSE
                        table_varchar(pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M015'),
                                      pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M016'),
                                      pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M017'),
                                      pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M018'),
                                      pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M019'),
                                      pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M020'),
                                      pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M021'),
                                      pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M022'),
                                      pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M023'),
                                      pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M024'))
                   END label,
                   CASE
                       WHEN ntr.flg_status = 'F'
                            AND ntd.id_nurse_tea_det =
                            (SELECT ntdz.id_nurse_tea_det
                                   FROM nurse_tea_det ntdz
                                  WHERE ntdz.id_nurse_tea_req = ntr.id_nurse_tea_req
                                    AND ntdz.flg_status = ntd.flg_status
                                    AND ntdz.num_order =
                                        (SELECT MAX(ntdx.num_order)
                                           FROM nurse_tea_det ntdx
                                          WHERE ntdx.id_nurse_tea_req = ntr.id_nurse_tea_req))
                            OR ntr.flg_status = pk_patient_education_constant.g_nurse_tea_req_act THEN
                        table_varchar(pk_patient_education_utils.get_diagnosis(i_lang, i_prof, ntr.id_nurse_tea_req),
                                      (SELECT nvl(pk_translation.get_translation(i_lang, nto.code_nurse_tea_opt),
                                                  ntdo.notes)
                                         FROM nurse_tea_det_opt ntdo
                                         LEFT JOIN nurse_tea_opt nto
                                           ON nto.id_nurse_tea_opt = ntdo.id_nurse_tea_opt
                                        WHERE ntdo.id_nurse_tea_det = ntd.id_nurse_tea_det
                                          AND ntdo.subject = 'GOALS'),
                                      (SELECT nvl(pk_translation.get_translation(i_lang, nto.code_nurse_tea_opt),
                                                  ntdo.notes)
                                         FROM nurse_tea_det_opt ntdo
                                         LEFT JOIN nurse_tea_opt nto
                                           ON nto.id_nurse_tea_opt = ntdo.id_nurse_tea_opt
                                        WHERE ntdo.id_nurse_tea_det = ntd.id_nurse_tea_det
                                          AND ntdo.subject = 'METHOD'),
                                      (SELECT nvl(pk_translation.get_translation(i_lang, nto.code_nurse_tea_opt),
                                                  ntdo.notes)
                                         FROM nurse_tea_det_opt ntdo
                                         LEFT JOIN nurse_tea_opt nto
                                           ON nto.id_nurse_tea_opt = ntdo.id_nurse_tea_opt
                                        WHERE ntdo.id_nurse_tea_det = ntd.id_nurse_tea_det
                                          AND ntdo.subject = 'GIVEN_TO'),
                                      (SELECT nvl(pk_translation.get_translation(i_lang, nto.code_nurse_tea_opt),
                                                  ntdo.notes)
                                         FROM nurse_tea_det_opt ntdo
                                         LEFT JOIN nurse_tea_opt nto
                                           ON nto.id_nurse_tea_opt = ntdo.id_nurse_tea_opt
                                        WHERE ntdo.id_nurse_tea_det = ntd.id_nurse_tea_det
                                          AND ntdo.subject = 'DELIVERABLES'),
                                      (SELECT nvl(pk_translation.get_translation(i_lang, nto.code_nurse_tea_opt),
                                                  ntdo.notes)
                                         FROM nurse_tea_det_opt ntdo
                                         LEFT JOIN nurse_tea_opt nto
                                           ON nto.id_nurse_tea_opt = ntdo.id_nurse_tea_opt
                                        WHERE ntdo.id_nurse_tea_det = ntd.id_nurse_tea_det
                                          AND ntdo.subject = 'LEVEL_OF_UNDERSTANDING'),
                                      pk_date_utils.dt_chr_date_hour_tsz(i_lang, ntd.dt_start, i_prof),
                                      nvl2(ntd.duration,
                                           ntd.duration || ' ' ||
                                           pk_unit_measure.get_unit_measure_description(i_lang,
                                                                                        i_prof,
                                                                                        ntd.id_unit_meas_duration),
                                           NULL),
                                      pk_date_utils.dt_chr_date_hour_tsz(i_lang, ntd.dt_end, i_prof),
                                      
                                      NULL,
                                      pk_message.get_message(i_lang,
                                                             CASE ntr.flg_status
                                                                 WHEN pk_patient_education_constant.g_nurse_tea_req_fin THEN
                                                                  'PATIENT_EDUCATION_M038'
                                                                 WHEN pk_patient_education_constant.g_nurse_tea_req_pend THEN
                                                                  CASE
                                                                      WHEN ntr.flg_time = pk_patient_education_constant.g_flg_time_next THEN
                                                                       'PATIENT_EDUCATION_M036'
                                                                      WHEN ntr.dt_begin_tstz > g_sysdate_tstz THEN
                                                                       'PATIENT_EDUCATION_M036'
                                                                      ELSE
                                                                       'PATIENT_EDUCATION_M043'
                                                                  END
                                                                 WHEN pk_patient_education_constant.g_nurse_tea_req_act THEN
                                                                  'PATIENT_EDUCATION_M044'
                                                                 ELSE
                                                                  NULL
                                                             END))
                       ELSE
                        table_varchar(pk_patient_education_utils.get_diagnosis(i_lang, i_prof, ntr.id_nurse_tea_req),
                                      (SELECT nvl(pk_translation.get_translation(i_lang, nto.code_nurse_tea_opt),
                                                  ntdo.notes)
                                         FROM nurse_tea_det_opt ntdo
                                         LEFT JOIN nurse_tea_opt nto
                                           ON nto.id_nurse_tea_opt = ntdo.id_nurse_tea_opt
                                        WHERE ntdo.id_nurse_tea_det = ntd.id_nurse_tea_det
                                          AND ntdo.subject = 'GOALS'),
                                      (SELECT nvl(pk_translation.get_translation(i_lang, nto.code_nurse_tea_opt),
                                                  ntdo.notes)
                                         FROM nurse_tea_det_opt ntdo
                                         LEFT JOIN nurse_tea_opt nto
                                           ON nto.id_nurse_tea_opt = ntdo.id_nurse_tea_opt
                                        WHERE ntdo.id_nurse_tea_det = ntd.id_nurse_tea_det
                                          AND ntdo.subject = 'METHOD'),
                                      (SELECT nvl(pk_translation.get_translation(i_lang, nto.code_nurse_tea_opt),
                                                  ntdo.notes)
                                         FROM nurse_tea_det_opt ntdo
                                         LEFT JOIN nurse_tea_opt nto
                                           ON nto.id_nurse_tea_opt = ntdo.id_nurse_tea_opt
                                        WHERE ntdo.id_nurse_tea_det = ntd.id_nurse_tea_det
                                          AND ntdo.subject = 'GIVEN_TO'),
                                      (SELECT nvl(pk_translation.get_translation(i_lang, nto.code_nurse_tea_opt),
                                                  ntdo.notes)
                                         FROM nurse_tea_det_opt ntdo
                                         LEFT JOIN nurse_tea_opt nto
                                           ON nto.id_nurse_tea_opt = ntdo.id_nurse_tea_opt
                                        WHERE ntdo.id_nurse_tea_det = ntd.id_nurse_tea_det
                                          AND ntdo.subject = 'DELIVERABLES'),
                                      (SELECT nvl(pk_translation.get_translation(i_lang, nto.code_nurse_tea_opt),
                                                  ntdo.notes)
                                         FROM nurse_tea_det_opt ntdo
                                         LEFT JOIN nurse_tea_opt nto
                                           ON nto.id_nurse_tea_opt = ntdo.id_nurse_tea_opt
                                        WHERE ntdo.id_nurse_tea_det = ntd.id_nurse_tea_det
                                          AND ntdo.subject = 'LEVEL_OF_UNDERSTANDING'),
                                      pk_date_utils.dt_chr_date_hour_tsz(i_lang, ntd.dt_start, i_prof),
                                      nvl2(ntd.duration,
                                           ntd.duration || ' ' ||
                                           pk_unit_measure.get_unit_measure_description(i_lang,
                                                                                        i_prof,
                                                                                        ntd.id_unit_meas_duration),
                                           NULL),
                                      pk_date_utils.dt_chr_date_hour_tsz(i_lang, ntd.dt_end, i_prof),
                                      NULL)
                   END data
              FROM nurse_tea_det ntd
              JOIN nurse_tea_req ntr
                ON ntr.id_nurse_tea_req = ntd.id_nurse_tea_req
             WHERE ntd.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntd.flg_status = pk_patient_education_constant.g_nurse_tea_det_exec
            -- cancelled execution
            UNION ALL
            SELECT 'CEX' flg_type,
                   ntd.id_nurse_tea_det id,
                   table_varchar('START_DATE', 'END_DATE', 'PROVIDER') code,
                   table_varchar('Data de inic�o:', 'Data de fim:', 'Provider:') label,
                   table_varchar(pk_date_utils.dt_chr_date_hour_tsz(i_lang, ntd.dt_start, i_prof),
                                 pk_date_utils.dt_chr_date_hour_tsz(i_lang, ntd.dt_end, i_prof),
                                 pk_prof_utils.get_name_signature(i_lang, i_prof, ntd.id_prof_provider)) data
              FROM nurse_tea_det ntd
              JOIN nurse_tea_req ntr
                ON ntr.id_nurse_tea_req = ntd.id_nurse_tea_req
             WHERE ntd.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntd.flg_status = pk_patient_education_constant.g_nurse_tea_det_canc
            UNION ALL
            --edited
            SELECT 'EDTD' flg_type,
                   ntr.id_nurse_tea_req_hist id,
                   table_varchar('SUBJECT',
                                 'TOPIC',
                                 'CLINICAL_INDICATION',
                                 'TO_BE_PERFORMED',
                                 'FREQUENCY',
                                 'START_DATE',
                                 'REQ_NOTES',
                                 'DESCRIPTION',
                                 'STATUS',
                                 'NOT_ORDER_REASON') code,
                   table_varchar(pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M013'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M025'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M008'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M009'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_T041'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M010'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M012'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M014'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M039'),
                                 pk_message.get_message(i_lang, pk_not_order_reason_db.g_mcode_reas_not_order)) label,
                   table_varchar(pk_translation.get_translation(i_lang, nts.code_nurse_tea_subject),
                                 pk_patient_education_utils.get_desc_topic(i_lang,
                                                                           i_prof,
                                                                           ntr.id_nurse_tea_topic,
                                                                           ntr.desc_topic_aux,
                                                                           ntt.code_nurse_tea_topic),
                                 pk_patient_education_utils.get_diagnosis_hist(i_lang, i_prof, ntr.id_nurse_tea_req_hist),
                                 pk_sysdomain.get_domain('NURSE_TEA_REQ.FLG_TIME', ntr.flg_time, i_lang),
                                 nvl(pk_order_recurrence_api_db.get_order_recurr_plan_desc(i_lang,
                                                                                           i_prof,
                                                                                           ntr.id_order_recurr_plan),
                                     pk_translation.get_translation(i_lang,
                                                                    'ORDER_RECURR_OPTION.CODE_ORDER_RECURR_OPTION.0')),
                                 pk_date_utils.date_char_tsz(i_lang,
                                                             ntr.dt_begin_tstz,
                                                             i_prof.institution,
                                                             i_prof.software),
                                 ntr.notes_req,
                                 NULL,
                                 pk_message.get_message(i_lang,
                                                        CASE ntr.flg_status
                                                            WHEN pk_patient_education_constant.g_nurse_tea_req_fin THEN
                                                             'PATIENT_EDUCATION_M038'
                                                            WHEN pk_patient_education_constant.g_nurse_tea_req_pend THEN
                                                             CASE
                                                                 WHEN ntr.flg_time = pk_patient_education_constant.g_flg_time_next THEN
                                                                  'PATIENT_EDUCATION_M036'
                                                                 WHEN ntr.dt_begin_tstz > g_sysdate_tstz THEN
                                                                  'PATIENT_EDUCATION_M036'
                                                                 ELSE
                                                                  'PATIENT_EDUCATION_M043'
                                                             END
                                                            WHEN pk_patient_education_constant.g_nurse_tea_req_act THEN
                                                             'PATIENT_EDUCATION_M037'
                                                            WHEN pk_patient_education_constant.g_nurse_tea_req_not_ord_reas THEN
                                                             pk_not_order_reason_db.g_mcode_not_ordered_data
                                                            ELSE
                                                             NULL
                                                        END),
                                 decode(ntr.id_not_order_reason,
                                        NULL,
                                        NULL,
                                        pk_not_order_reason_db.get_not_order_reason_desc(i_lang             => i_lang,
                                                                                         i_not_order_reason => ntr.id_not_order_reason))) data
              FROM (SELECT id_nurse_tea_req_hist
                      FROM (SELECT ntr.id_nurse_tea_req_hist,
                                   lag(ntr.notes_req, 1) over(ORDER BY ntr.dt_nurse_tea_req_hist_tstz) AS prev_notes_req,
                                   ntr.notes_req,
                                   --lag(pk_string_utils.clob_to_plsqlvarchar2(ntr.description), 1) over(ORDER BY ntr.dt_nurse_tea_req_hist_tstz) AS prev_description,
                                   --null prev_description,
                                   --ntr.description,
                                   lag(ntr.id_order_recurr_plan, 1) over(ORDER BY ntr.dt_nurse_tea_req_hist_tstz) AS prev_id_order_recurr_plan,
                                   ntr.id_order_recurr_plan,
                                   lag(ntr.flg_time, 1) over(ORDER BY ntr.dt_nurse_tea_req_hist_tstz) AS prev_flg_time,
                                   ntr.flg_time,
                                   lag(ntr.id_not_order_reason, 1) over(ORDER BY ntr.dt_nurse_tea_req_hist_tstz) AS prev_id_not_order_reason,
                                   ntr.id_not_order_reason,
                                   ntr.diagnosis AS current_diag,
                                   lag(ntr.diagnosis, 1) over(ORDER BY ntr.id_nurse_tea_req_hist ASC) AS prev_diag
                              FROM (SELECT ntr.id_nurse_tea_req_hist,
                                           ntr.notes_req,
                                           --ntr.description description,
                                           ntr.id_order_recurr_plan,
                                           ntr.flg_time,
                                           ntr.id_not_order_reason,
                                           ntr.dt_nurse_tea_req_hist_tstz,
                                           dh.dt_nurse_tea_req_diag_tstz,
                                           listagg(dh.id_diagnosis, '|') within GROUP(ORDER BY dh.id_diagnosis ASC) AS diagnosis
                                      FROM nurse_tea_req_hist ntr
                                      LEFT JOIN nurse_tea_req_diag_hist dh
                                        ON dh.id_nurse_tea_req_hist = ntr.id_nurse_tea_req_hist --LEFT porque os registos antigos n�o t�m entrada
                                     WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
                                     GROUP BY ntr.id_nurse_tea_req_hist,
                                              ntr.notes_req,
                                              --ntr.description,
                                              ntr.id_order_recurr_plan,
                                              ntr.flg_time,
                                              ntr.id_not_order_reason,
                                              dt_nurse_tea_req_hist_tstz,
                                              dh.dt_nurse_tea_req_diag_tstz) ntr)
                     WHERE (nvl(prev_notes_req, 'NULL') <> nvl(notes_req, 'NULL') OR
                           /*                           REPLACE(REPLACE(pk_string_utils.clob_to_plsqlvarchar2(prev_description), chr(13), ''),
                           chr(10),
                           '') <>
                           REPLACE(REPLACE(pk_string_utils.clob_to_plsqlvarchar2(description), chr(13), ''),
                           chr(10),
                           '') OR*/
                           nvl(id_order_recurr_plan, -1) <> nvl(prev_id_order_recurr_plan, -1) OR
                           nvl(flg_time, -1) <> nvl(prev_flg_time, -1) OR
                           (nvl(id_not_order_reason, -1) <> nvl(prev_id_not_order_reason, -1) AND
                           prev_id_not_order_reason IS NOT NULL) OR nvl(current_diag, -1) <> nvl(prev_diag, -1))
                       AND id_nurse_tea_req_hist <>
                           (SELECT MIN(ntr.id_nurse_tea_req_hist)
                              FROM nurse_tea_req_hist ntr
                             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req)
                    UNION
                    -- id_composition
                    SELECT z.id_nurse_tea_req_hist
                      FROM (SELECT ntdh.dt_nurse_tea_req_diag_tstz,
                                   ntdh.id_nurse_tea_req,
                                   ntdh.id_nurse_tea_req_hist,
                                   listagg(pk_patient_education_utils.get_composition_hist(i_lang          => i_lang,
                                                                                           i_prof          => i_prof,
                                                                                           i_nurse_tea_req => ntdh.id_nurse_tea_req_hist),
                                           '; ') within GROUP(ORDER BY ntdh.id_diagnosis) id_diagnosis1
                              FROM nurse_tea_req_diag_hist ntdh
                             WHERE ntdh.id_nurse_tea_req = i_id_nurse_tea_req
                             GROUP BY ntdh.dt_nurse_tea_req_diag_tstz, ntdh.id_nurse_tea_req, ntdh.id_nurse_tea_req_hist) x
                      JOIN (SELECT ntdh.dt_nurse_tea_req_diag_tstz,
                                  ntdh.id_nurse_tea_req,
                                  ntdh.id_nurse_tea_req_hist,
                                  listagg(pk_patient_education_utils.get_composition_hist(i_lang          => i_lang,
                                                                                          i_prof          => i_prof,
                                                                                          i_nurse_tea_req => ntdh.id_nurse_tea_req_hist),
                                          '; ') within GROUP(ORDER BY ntdh.id_diagnosis) id_diagnosis2
                             FROM nurse_tea_req_diag_hist ntdh
                            WHERE ntdh.id_nurse_tea_req = i_id_nurse_tea_req
                            GROUP BY ntdh.dt_nurse_tea_req_diag_tstz, ntdh.id_nurse_tea_req, ntdh.id_nurse_tea_req_hist) z
                        ON x.id_nurse_tea_req = z.id_nurse_tea_req
                       AND x.dt_nurse_tea_req_diag_tstz < z.dt_nurse_tea_req_diag_tstz
                     WHERE nvl(id_diagnosis1, 'NULL') != nvl(id_diagnosis2, 'NULL')) n
              JOIN nurse_tea_req_hist ntr
                ON ntr.id_nurse_tea_req_hist = n.id_nurse_tea_req_hist
              JOIN nurse_tea_topic ntt
                ON ntt.id_nurse_tea_topic = ntr.id_nurse_tea_topic
              JOIN nurse_tea_subject nts
                ON nts.id_nurse_tea_subject = ntt.id_nurse_tea_subject
            UNION ALL
            --expired task
            SELECT 'EXP' flg_type,
                   ntr.id_nurse_tea_req id,
                   table_varchar('EXPIRE_NOTES') code,
                   table_varchar(' ') label,
                   table_varchar(pk_message.get_message(i_lang, 'CPOE_M014')) data
              FROM nurse_tea_req ntr
             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntr.flg_status = pk_patient_education_constant.g_nurse_tea_req_expired
            -- not order reason
            UNION ALL
            SELECT 'NOR' flg_type,
                   ntr.id_nurse_tea_req id,
                   table_varchar('SUBJECT',
                                 'TOPIC',
                                 'CLINICAL_INDICATION',
                                 'TO_BE_PERFORMED',
                                 'FREQUENCY',
                                 'START_DATE',
                                 'REQ_NOTES',
                                 'DESCRIPTION',
                                 'STATUS',
                                 'NOT_ORDER_REASON') code,
                   table_varchar(pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M013'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M025'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M008'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M009'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_T041'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M010'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M012'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M014'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M039'),
                                 pk_message.get_message(i_lang, pk_not_order_reason_db.g_mcode_reas_not_order)) label,
                   table_varchar(pk_translation.get_translation(i_lang, nts.code_nurse_tea_subject),
                                 pk_patient_education_utils.get_desc_topic(i_lang,
                                                                           i_prof,
                                                                           ntr.id_nurse_tea_topic,
                                                                           ntr.desc_topic_aux,
                                                                           ntt.code_nurse_tea_topic),
                                 pk_patient_education_utils.get_diagnosis(i_lang, i_prof, ntr.id_nurse_tea_req),
                                 pk_sysdomain.get_domain(pk_patient_education_constant.g_sys_domain_flg_time,
                                                         ntr.flg_time,
                                                         i_lang),
                                 nvl(pk_order_recurrence_api_db.get_order_recurr_plan_desc(i_lang,
                                                                                           i_prof,
                                                                                           ntr.id_order_recurr_plan),
                                     pk_translation.get_translation(i_lang,
                                                                    'ORDER_RECURR_OPTION.CODE_ORDER_RECURR_OPTION.0')),
                                 pk_date_utils.date_char_tsz(i_lang,
                                                             ntr.dt_begin_tstz,
                                                             i_prof.institution,
                                                             i_prof.software),
                                 ntr.notes_req,
                                 ntr.description,
                                 pk_message.get_message(i_lang      => i_lang,
                                                        i_code_mess => pk_not_order_reason_db.g_mcode_not_ordered_data),
                                 pk_not_order_reason_db.get_not_order_reason_desc(i_lang             => i_lang,
                                                                                  i_not_order_reason => ntr.id_not_order_reason)) data
              FROM nurse_tea_req ntr
              JOIN nurse_tea_topic ntt
                ON ntt.id_nurse_tea_topic = ntr.id_nurse_tea_topic
              JOIN nurse_tea_subject nts
                ON nts.id_nurse_tea_subject = ntt.id_nurse_tea_subject
             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntr.flg_status = pk_patient_education_constant.g_nurse_tea_req_not_ord_reas
               AND NOT EXISTS
             (SELECT ntrh.id_nurse_tea_req_hist
                      FROM nurse_tea_req_hist ntrh
                     WHERE ntrh.id_nurse_tea_req = ntr.id_nurse_tea_req
                       AND ntrh.flg_status = pk_patient_education_constant.g_nurse_tea_req_not_ord_reas)
            -- not order reason (hist)  
            UNION ALL
            SELECT 'NRH' flg_type,
                   ntr.id_nurse_tea_req id,
                   table_varchar('SUBJECT',
                                 'TOPIC',
                                 'CLINICAL_INDICATION',
                                 'TO_BE_PERFORMED',
                                 'FREQUENCY',
                                 'START_DATE',
                                 'REQ_NOTES',
                                 'DESCRIPTION',
                                 'STATUS',
                                 'NOT_ORDER_REASON') code,
                   table_varchar(pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M013'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M025'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M008'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M009'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_T041'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M010'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M012'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M014'),
                                 pk_message.get_message(i_lang, 'PATIENT_EDUCATION_M039'),
                                 pk_message.get_message(i_lang, pk_not_order_reason_db.g_mcode_reas_not_order)) label,
                   table_varchar(pk_translation.get_translation(i_lang, nts.code_nurse_tea_subject),
                                 pk_patient_education_utils.get_desc_topic(i_lang,
                                                                           i_prof,
                                                                           ntr.id_nurse_tea_topic,
                                                                           ntr.desc_topic_aux,
                                                                           ntt.code_nurse_tea_topic),
                                 pk_patient_education_utils.get_diagnosis(i_lang, i_prof, ntr.id_nurse_tea_req),
                                 pk_sysdomain.get_domain(pk_patient_education_constant.g_sys_domain_flg_time,
                                                         ntr.flg_time,
                                                         i_lang),
                                 nvl(pk_order_recurrence_api_db.get_order_recurr_plan_desc(i_lang,
                                                                                           i_prof,
                                                                                           ntr.id_order_recurr_plan),
                                     pk_translation.get_translation(i_lang,
                                                                    'ORDER_RECURR_OPTION.CODE_ORDER_RECURR_OPTION.0')),
                                 pk_date_utils.date_char_tsz(i_lang,
                                                             ntr.dt_begin_tstz,
                                                             i_prof.institution,
                                                             i_prof.software),
                                 ntr.notes_req,
                                 ntr.description,
                                 pk_message.get_message(i_lang      => i_lang,
                                                        i_code_mess => pk_not_order_reason_db.g_mcode_not_ordered_data),
                                 pk_not_order_reason_db.get_not_order_reason_desc(i_lang             => i_lang,
                                                                                  i_not_order_reason => ntr.id_not_order_reason)) data
              FROM nurse_tea_req_hist ntr
              JOIN nurse_tea_topic ntt
                ON ntt.id_nurse_tea_topic = ntr.id_nurse_tea_topic
              JOIN nurse_tea_subject nts
                ON nts.id_nurse_tea_subject = ntt.id_nurse_tea_subject
             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntr.id_nurse_tea_req_hist = (SELECT MAX(id_nurse_tea_req_hist)
                                                  FROM nurse_tea_req_hist
                                                 WHERE id_nurse_tea_req = ntr.id_nurse_tea_req
                                                   AND flg_status = ntr.flg_status)
               AND ntr.flg_status = pk_patient_education_constant.g_nurse_tea_req_not_ord_reas;
    
        OPEN o_data FOR
        -- DRAFT
            SELECT 'DRAFT' flg_type, ntr.id_nurse_tea_req id, ntr.description description
              FROM nurse_tea_req ntr
              JOIN nurse_tea_topic ntt
                ON ntt.id_nurse_tea_topic = ntr.id_nurse_tea_topic
              JOIN nurse_tea_subject nts
                ON nts.id_nurse_tea_subject = ntt.id_nurse_tea_subject
             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntr.flg_status = pk_patient_education_constant.g_nurse_tea_req_draft
            
            UNION ALL
            -- request (w/o hist)
            SELECT 'REQ' flg_type, ntr.id_nurse_tea_req id, ntr.description description
              FROM nurse_tea_req ntr
              JOIN nurse_tea_topic ntt
                ON ntt.id_nurse_tea_topic = ntr.id_nurse_tea_topic
              JOIN nurse_tea_subject nts
                ON nts.id_nurse_tea_subject = ntt.id_nurse_tea_subject
             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntr.flg_status IN (pk_patient_education_constant.g_nurse_tea_req_pend,
                                      pk_patient_education_constant.g_nurse_tea_req_act,
                                      pk_patient_education_constant.g_nurse_tea_req_fin)
               AND NOT EXISTS (SELECT ntrh.id_nurse_tea_req_hist
                      FROM nurse_tea_req_hist ntrh
                     WHERE ntrh.id_nurse_tea_req = ntr.id_nurse_tea_req
                       AND ntrh.flg_status = pk_patient_education_constant.g_nurse_tea_req_pend)
            UNION ALL
            -- request (w/ hist)
            SELECT 'RQH' flg_type, ntr.id_nurse_tea_req id, ntr.description description
              FROM nurse_tea_req_hist ntr
              JOIN nurse_tea_topic ntt
                ON ntt.id_nurse_tea_topic = ntr.id_nurse_tea_topic
              JOIN nurse_tea_subject nts
                ON nts.id_nurse_tea_subject = ntt.id_nurse_tea_subject
             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntr.id_nurse_tea_req_hist = (SELECT MIN(id_nurse_tea_req_hist)
                                                  FROM nurse_tea_req_hist
                                                 WHERE id_nurse_tea_req = ntr.id_nurse_tea_req
                                                   AND flg_status = ntr.flg_status)
               AND ntr.flg_status = pk_patient_education_constant.g_nurse_tea_req_pend
            -- suggestion (w/o hist)
            UNION ALL
            SELECT 'SUG' flg_type, ntr.id_nurse_tea_req id, ntr.description description
              FROM nurse_tea_req ntr
              JOIN nurse_tea_topic ntt
                ON ntt.id_nurse_tea_topic = ntr.id_nurse_tea_topic
              JOIN nurse_tea_subject nts
                ON nts.id_nurse_tea_subject = ntt.id_nurse_tea_subject
             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntr.flg_status = pk_patient_education_constant.g_nurse_tea_req_sug
               AND NOT EXISTS (SELECT ntrh.id_nurse_tea_req_hist
                      FROM nurse_tea_req_hist ntrh
                     WHERE ntrh.id_nurse_tea_req = ntr.id_nurse_tea_req)
            -- suggestion (w/ hist)
            UNION ALL
            SELECT 'SGH' flg_type, ntr.id_nurse_tea_req id, ntr.description description
              FROM nurse_tea_req_hist ntr
              JOIN nurse_tea_topic ntt
                ON ntt.id_nurse_tea_topic = ntr.id_nurse_tea_topic
              JOIN nurse_tea_subject nts
                ON nts.id_nurse_tea_subject = ntt.id_nurse_tea_subject
             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntr.flg_status = pk_patient_education_constant.g_nurse_tea_req_sug
            -- execution
            UNION ALL
            SELECT 'EXE' flg_type, ntd.id_nurse_tea_det id, ntd.description description
              FROM nurse_tea_det ntd
              JOIN nurse_tea_req ntr
                ON ntr.id_nurse_tea_req = ntd.id_nurse_tea_req
             WHERE ntd.id_nurse_tea_req = i_id_nurse_tea_req
               AND ntd.flg_status = pk_patient_education_constant.g_nurse_tea_det_exec
            UNION ALL
            --edited
            SELECT 'EDTD' flg_type, ntr.id_nurse_tea_req_hist id, ntr.description description
              FROM (SELECT id_nurse_tea_req_hist
                      FROM (SELECT ntr.id_nurse_tea_req_hist,
                                   lag(ntr.notes_req, 1) over(ORDER BY ntr.dt_nurse_tea_req_hist_tstz) AS prev_notes_req,
                                   ntr.notes_req,
                                   --lag(pk_string_utils.clob_to_plsqlvarchar2(ntr.description), 1) over(ORDER BY ntr.dt_nurse_tea_req_hist_tstz) AS prev_description,
                                   --ntr.description,
                                   lag(ntr.id_order_recurr_plan, 1) over(ORDER BY ntr.dt_nurse_tea_req_hist_tstz) AS prev_id_order_recurr_plan,
                                   ntr.id_order_recurr_plan,
                                   lag(ntr.flg_time, 1) over(ORDER BY ntr.dt_nurse_tea_req_hist_tstz) AS prev_flg_time,
                                   ntr.flg_time,
                                   ntr.diagnosis AS current_diag,
                                   lag(ntr.diagnosis, 1) over(ORDER BY ntr.id_nurse_tea_req_hist ASC) AS prev_diag
                              FROM (SELECT ntr.id_nurse_tea_req_hist,
                                           ntr.notes_req,
                                           --ntr.description description,
                                           ntr.id_order_recurr_plan,
                                           ntr.flg_time,
                                           ntr.dt_nurse_tea_req_hist_tstz,
                                           dh.dt_nurse_tea_req_diag_tstz,
                                           listagg(dh.id_diagnosis, '|') within GROUP(ORDER BY dh.id_diagnosis ASC) AS diagnosis
                                      FROM nurse_tea_req_hist ntr
                                      LEFT JOIN nurse_tea_req_diag_hist dh
                                        ON dh.id_nurse_tea_req_hist = ntr.id_nurse_tea_req_hist
                                     WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
                                     GROUP BY ntr.id_nurse_tea_req_hist,
                                              ntr.notes_req,
                                              --ntr.description,
                                              ntr.id_order_recurr_plan,
                                              ntr.flg_time,
                                              dt_nurse_tea_req_hist_tstz,
                                              dh.dt_nurse_tea_req_diag_tstz) ntr) ntr
                     WHERE (nvl(prev_notes_req, 'NULL') <> nvl(notes_req, 'NULL') OR
                           /*REPLACE(REPLACE(pk_string_utils.clob_to_plsqlvarchar2(prev_description), chr(13), ''),
                           chr(10),
                           '') <>
                           REPLACE(REPLACE(pk_string_utils.clob_to_plsqlvarchar2(description), chr(13), ''),
                           chr(10),
                           '') OR*/
                           nvl(id_order_recurr_plan, -1) <> nvl(prev_id_order_recurr_plan, -1) OR
                           nvl(flg_time, -1) <> nvl(prev_flg_time, -1) OR
                           nvl(ntr.current_diag, -1) <> nvl(ntr.prev_diag, -1))
                       AND id_nurse_tea_req_hist <>
                           (SELECT MIN(ntr.id_nurse_tea_req_hist)
                              FROM nurse_tea_req_hist ntr
                             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req)
                    UNION
                    -- id_composition
                    SELECT z.id_nurse_tea_req_hist
                      FROM (SELECT ntdh.dt_nurse_tea_req_diag_tstz,
                                   ntdh.id_nurse_tea_req,
                                   ntdh.id_nurse_tea_req_hist,
                                   listagg(pk_patient_education_utils.get_composition_hist(i_lang          => i_lang,
                                                                                           i_prof          => i_prof,
                                                                                           i_nurse_tea_req => ntdh.id_nurse_tea_req_hist),
                                           '; ') within GROUP(ORDER BY ntdh.id_diagnosis) id_diagnosis1
                              FROM nurse_tea_req_diag_hist ntdh
                             WHERE ntdh.id_nurse_tea_req = i_id_nurse_tea_req
                             GROUP BY ntdh.dt_nurse_tea_req_diag_tstz, ntdh.id_nurse_tea_req, ntdh.id_nurse_tea_req_hist) x
                      JOIN (SELECT ntdh.dt_nurse_tea_req_diag_tstz,
                                  ntdh.id_nurse_tea_req,
                                  ntdh.id_nurse_tea_req_hist,
                                  listagg(pk_patient_education_utils.get_composition_hist(i_lang          => i_lang,
                                                                                          i_prof          => i_prof,
                                                                                          i_nurse_tea_req => ntdh.id_nurse_tea_req_hist),
                                          '; ') within GROUP(ORDER BY ntdh.id_diagnosis) id_diagnosis2
                             FROM nurse_tea_req_diag_hist ntdh
                            WHERE ntdh.id_nurse_tea_req = i_id_nurse_tea_req
                            GROUP BY ntdh.dt_nurse_tea_req_diag_tstz, ntdh.id_nurse_tea_req, ntdh.id_nurse_tea_req_hist) z
                        ON x.id_nurse_tea_req = z.id_nurse_tea_req
                       AND x.dt_nurse_tea_req_diag_tstz < z.dt_nurse_tea_req_diag_tstz
                     WHERE nvl(id_diagnosis1, 'NULL') != nvl(id_diagnosis2, 'NULL')) n
              JOIN nurse_tea_req_hist ntr
                ON ntr.id_nurse_tea_req_hist = n.id_nurse_tea_req_hist
              JOIN nurse_tea_topic ntt
                ON ntt.id_nurse_tea_topic = ntr.id_nurse_tea_topic
              JOIN nurse_tea_subject nts
                ON nts.id_nurse_tea_subject = ntt.id_nurse_tea_subject;
    
        SELECT pk_date_utils.get_timestamp_str(i_lang, i_prof, MIN(dt_nurse_tea_req_tstz), NULL)
          INTO l_date_req
          FROM (SELECT ntr.dt_nurse_tea_req_tstz
                  FROM nurse_tea_req ntr
                 WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
                UNION ALL
                SELECT h.dt_nurse_tea_req_tstz
                  FROM nurse_tea_req_hist h
                 WHERE h.id_nurse_tea_req_hist =
                       (SELECT MIN(id_nurse_tea_req_hist)
                          FROM nurse_tea_req_hist
                         WHERE id_nurse_tea_req = i_id_nurse_tea_req));
    
        OPEN o_main FOR
            SELECT pk_translation.get_translation(i_lang, nts.code_nurse_tea_subject) title_subject,
                   pk_patient_education_utils.get_desc_topic(i_lang,
                                                             i_prof,
                                                             ntr.id_nurse_tea_topic,
                                                             ntr.desc_topic_aux,
                                                             ntt.code_nurse_tea_topic) title_topic,
                   ntr.flg_status flg_status,
                   pk_sysdomain.get_domain(pk_patient_education_constant.g_sys_domain_req_flg_status,
                                           ntr.flg_status,
                                           i_lang) desc_status,
                   l_date_req date_req
              FROM nurse_tea_req ntr
              JOIN nurse_tea_topic ntt
                ON ntt.id_nurse_tea_topic = ntr.id_nurse_tea_topic
              JOIN nurse_tea_subject nts
                ON nts.id_nurse_tea_subject = ntt.id_nurse_tea_subject
              LEFT JOIN nurse_tea_req_hist ntrh
                ON ntrh.id_nurse_tea_req = ntr.id_nurse_tea_req
             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_cursor_if_closed(o_register);
            pk_types.open_cursor_if_closed(o_detail);
            pk_types.open_cursor_if_closed(o_main);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PATIENT_EDUCATION_DET',
                                              o_error);
        
            RETURN FALSE;
    END get_patient_education_det;

    FUNCTION get_patient_education_det
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE,
        o_detail           OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_tbl_order_detail  t_tbl_health_education_order;
        l_tbl_exec_detail   t_tbl_health_education_exec;
        l_tbl_cancel_detail t_tbl_health_education_cancel;
    
        l_tab_dd_block_data_order  t_tab_dd_block_data := t_tab_dd_block_data();
        l_tab_dd_block_data_exec   t_tab_dd_block_data := t_tab_dd_block_data();
        l_tab_dd_block_data_cancel t_tab_dd_block_data := t_tab_dd_block_data();
    
        l_tab_dd_data      t_tab_dd_data := t_tab_dd_data();
        l_data_source_list table_varchar := table_varchar();
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        --1) Obtaining the data
        --ORDER
        l_tbl_order_detail := pk_patient_education_utils.tf_get_order_detail(i_lang             => i_lang,
                                                                             i_prof             => i_prof,
                                                                             i_id_nurse_tea_req => i_id_nurse_tea_req);
    
        --EXECUTION
        l_tbl_exec_detail := pk_patient_education_utils.tf_get_execution_detail(i_lang             => i_lang,
                                                                                i_prof             => i_prof,
                                                                                i_id_nurse_tea_req => i_id_nurse_tea_req);
    
        --CANCELLATION
        l_tbl_cancel_detail := pk_patient_education_utils.tf_get_cancel_detail(i_lang             => i_lang,
                                                                               i_prof             => i_prof,
                                                                               i_id_nurse_tea_req => i_id_nurse_tea_req);
    
        --2) Construct the dd_blocks
        --ORDER
        SELECT t_rec_dd_block_data(ddb.id_dd_block,
                                   ddb.rank * 100,
                                   NULL,
                                   NULL,
                                   ddb.condition_val,
                                   NULL,
                                   NULL,
                                   dd.data_source,
                                   dd.data_source_val,
                                   NULL)
          BULK COLLECT
          INTO l_tab_dd_block_data_order
          FROM (SELECT data_source, data_source_val
                  FROM (SELECT *
                          FROM (SELECT t.action,
                                       t.subject,
                                       t.topic,
                                       t.clinical_indication,
                                       t.to_execute,
                                       t.frequency,
                                       t.start_date,
                                       to_char(t.order_notes) order_notes,
                                       to_char(dbms_lob.substr(t.description, 3990)) description,
                                       status,
                                       registry,
                                       end_date,
                                       NULL white_line
                                  FROM TABLE(l_tbl_order_detail) t) unpivot include NULLS(data_source_val FOR data_source IN(action,
                                                                                                                             subject,
                                                                                                                             topic,
                                                                                                                             clinical_indication,
                                                                                                                             to_execute,
                                                                                                                             frequency,
                                                                                                                             start_date,
                                                                                                                             order_notes,
                                                                                                                             description,
                                                                                                                             status,
                                                                                                                             registry,
                                                                                                                             end_date,
                                                                                                                             white_line)))) dd
          JOIN dd_block ddb
            ON ddb.area = 'HEALTH_EDUCATION'
           AND ddb.internal_name = 'ORDER'
           AND ddb.flg_available = pk_alert_constant.g_yes;
    
        --EXECUTION
        SELECT t_rec_dd_block_data(ddb.id_dd_block,
                                   (ddb.rank * 100) + rn,
                                   NULL,
                                   NULL,
                                   ddb.condition_val,
                                   NULL,
                                   NULL,
                                   dd.data_source,
                                   dd.data_source_val,
                                   NULL)
          BULK COLLECT
          INTO l_tab_dd_block_data_exec
          FROM (SELECT data_source, data_source_val, row_number() over(PARTITION BY data_source ORDER BY rownum) AS rn
                  FROM (SELECT *
                          FROM (SELECT t.action,
                                       t.clinical_indication,
                                       t.goals,
                                       t.method,
                                       t.given_to,
                                       t.deliverables,
                                       t.understanding,
                                       t.start_date,
                                       t.duration,
                                       t.end_date,
                                       to_char(t.description) description,
                                       t.status,
                                       t.registry,
                                       t.white_line
                                  FROM TABLE(l_tbl_exec_detail) t) unpivot include NULLS(data_source_val FOR data_source IN(action,
                                                                                                                            clinical_indication,
                                                                                                                            goals,
                                                                                                                            method,
                                                                                                                            given_to,
                                                                                                                            deliverables,
                                                                                                                            understanding,
                                                                                                                            start_date,
                                                                                                                            duration,
                                                                                                                            end_date,
                                                                                                                            description,
                                                                                                                            status,
                                                                                                                            registry,
                                                                                                                            white_line)))) dd
          JOIN dd_block ddb
            ON ddb.area = 'HEALTH_EDUCATION'
           AND ddb.internal_name = 'EXECUTION'
           AND ddb.flg_available = pk_alert_constant.g_yes;
    
        --CANCELLATION
        SELECT t_rec_dd_block_data(ddb.id_dd_block,
                                   (ddb.rank * 100),
                                   NULL,
                                   NULL,
                                   ddb.condition_val,
                                   NULL,
                                   NULL,
                                   dd.data_source,
                                   dd.data_source_val,
                                   NULL)
          BULK COLLECT
          INTO l_tab_dd_block_data_cancel
          FROM (SELECT data_source, data_source_val
                  FROM (SELECT *
                          FROM (SELECT t.action, t.cancel_reason, t.cancel_notes, t.registry, t.white_line
                                  FROM TABLE(l_tbl_cancel_detail) t) unpivot include NULLS(data_source_val FOR data_source IN(action,
                                                                                                                              cancel_reason,
                                                                                                                              cancel_notes,
                                                                                                                              registry,
                                                                                                                              white_line)))) dd
          JOIN dd_block ddb
            ON ddb.area = 'HEALTH_EDUCATION'
           AND ddb.internal_name = 'CANCELLATION'
           AND ddb.flg_available = pk_alert_constant.g_yes;
    
        SELECT t_rec_dd_data(CASE
                                  WHEN data_code_message IS NOT NULL
                                       AND flg_type <> 'L3CQ' THEN
                                   pk_message.get_message(i_lang => i_lang, i_code_mess => data_code_message)
                                  WHEN flg_type = 'L3CQ' THEN
                                   data_code_message
                                  ELSE
                                   NULL
                              END, --DESCR
                              CASE
                                  WHEN flg_type = 'L1' THEN
                                   NULL
                                  ELSE
                                   data_source_val
                              END, --VAL
                              decode(flg_type, 'L3CQ', 'L3B', flg_type), --TYPE
                              flg_html,
                              NULL,
                              flg_clob),
               data_source
          BULK COLLECT
          INTO l_tab_dd_data, l_data_source_list
          FROM (SELECT ddc.data_code_message,
                       flg_type,
                       data_source_val,
                       ddc.data_source,
                       db.rnk,
                       ddc.rank,
                       db.id_dd_block,
                       0 AS rank_cq,
                       flg_html,
                       flg_clob
                  FROM TABLE(l_tab_dd_block_data_order) db
                  JOIN dd_content ddc
                    ON ddc.data_source = db.data_source
                   AND ddc.flg_available = pk_alert_constant.g_yes
                   AND ddc.area = 'HEALTH_EDUCATION'
                 WHERE ddc.id_dd_block = db.id_dd_block
                   AND (db.data_source_val IS NOT NULL OR flg_type IN ('L1', 'WL'))
                UNION ALL
                SELECT ddc.data_code_message,
                       flg_type,
                       data_source_val,
                       ddc.data_source,
                       db.rnk,
                       ddc.rank,
                       db.id_dd_block,
                       0 AS rank_cq,
                       flg_html,
                       flg_clob
                  FROM TABLE(l_tab_dd_block_data_exec) db
                  JOIN dd_content ddc
                    ON ddc.data_source = db.data_source
                   AND ddc.flg_available = pk_alert_constant.g_yes
                   AND ddc.area = 'HEALTH_EDUCATION'
                 WHERE ddc.id_dd_block = db.id_dd_block
                   AND (db.data_source_val IS NOT NULL OR flg_type IN ('L1', 'WL'))
                UNION ALL
                SELECT ddc.data_code_message,
                       flg_type,
                       data_source_val,
                       ddc.data_source,
                       db.rnk,
                       ddc.rank,
                       db.id_dd_block,
                       0 AS rank_cq,
                       flg_html,
                       flg_clob
                  FROM TABLE(l_tab_dd_block_data_cancel) db
                  JOIN dd_content ddc
                    ON ddc.data_source = db.data_source
                   AND ddc.flg_available = pk_alert_constant.g_yes
                   AND ddc.area = 'HEALTH_EDUCATION'
                 WHERE ddc.id_dd_block = db.id_dd_block
                   AND (db.data_source_val IS NOT NULL OR flg_type IN ('L1', 'WL')))
         ORDER BY rnk DESC, rank, rank_cq;
    
        OPEN o_detail FOR
            SELECT descr, val, flg_type, flg_html, val_clob, flg_clob
              FROM (SELECT CASE
                                WHEN d.val IS NULL THEN
                                 d.descr
                                WHEN d.descr IS NULL THEN
                                 NULL
                                ELSE
                                 d.descr || ' '
                            END descr,
                           d.val,
                           d.flg_type,
                           flg_html,
                           val_clob,
                           flg_clob,
                           d.rn
                      FROM (SELECT rownum rn, descr, val, flg_type, flg_html, val_clob, flg_clob
                              FROM TABLE(l_tab_dd_data)) d
                      JOIN (SELECT rownum rn, column_value data_source
                             FROM TABLE(l_data_source_list)) ds
                        ON ds.rn = d.rn);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_patient_education_det',
                                              o_error);
            pk_types.open_my_cursor(o_detail);
            RETURN FALSE;
    END get_patient_education_det;

    FUNCTION get_patient_education_det_hist
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE,
        o_detail           OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_tbl_order_detail  t_tbl_health_education_order_hist;
        l_tbl_exec_detail   t_tbl_health_education_exec;
        l_tbl_cancel_detail t_tbl_health_education_cancel;
    
        l_tab_dd_block_data_order  t_tab_dd_block_data := t_tab_dd_block_data();
        l_tab_dd_block_data_exec   t_tab_dd_block_data := t_tab_dd_block_data();
        l_tab_dd_block_data_cancel t_tab_dd_block_data := t_tab_dd_block_data();
    
        l_tab_dd_data      t_tab_dd_data := t_tab_dd_data();
        l_data_source_list table_varchar := table_varchar();
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        --1) Obtaining the data
        --ORDER
        l_tbl_order_detail := pk_patient_education_utils.tf_get_order_detail_hist(i_lang             => i_lang,
                                                                                  i_prof             => i_prof,
                                                                                  i_id_nurse_tea_req => i_id_nurse_tea_req);
    
        --EXECUTION
        l_tbl_exec_detail := pk_patient_education_utils.tf_get_execution_detail(i_lang             => i_lang,
                                                                                i_prof             => i_prof,
                                                                                i_id_nurse_tea_req => i_id_nurse_tea_req);
    
        --CANCELLATION
        l_tbl_cancel_detail := pk_patient_education_utils.tf_get_cancel_detail(i_lang             => i_lang,
                                                                               i_prof             => i_prof,
                                                                               i_id_nurse_tea_req => i_id_nurse_tea_req);
    
        --2) Construct the dd_blocks
        --ORDER
        SELECT t_rec_dd_block_data(ddb.id_dd_block,
                                   (ddb.rank * 100) + rn,
                                   NULL,
                                   NULL,
                                   ddb.condition_val,
                                   NULL,
                                   NULL,
                                   dd.data_source,
                                   dd.data_source_val,
                                   NULL)
          BULK COLLECT
          INTO l_tab_dd_block_data_order
          FROM (SELECT data_source, data_source_val, row_number() over(PARTITION BY data_source ORDER BY rownum) AS rn
                  FROM (SELECT *
                          FROM (SELECT t.action,
                                       t.subject,
                                       t.topic,
                                       t.clinical_indication,
                                       t.clinical_indication_new,
                                       t.to_execute,
                                       t.to_execute_new,
                                       t.frequency,
                                       t.frequency_new,
                                       t.start_date,
                                       t.start_date_new,
                                       to_char(t.order_notes) order_notes,
                                       to_char(t.order_notes_new) order_notes_new,
                                       to_char(t.description) description,
                                       to_char(t.description_new) description_new,
                                       t.status,
                                       t.status_new,
                                       t.registry,
                                       t.white_line,
                                       t.end_date,
                                       t.end_date_new
                                  FROM TABLE(l_tbl_order_detail) t) unpivot include NULLS(data_source_val FOR data_source IN(action,
                                                                                                                             subject,
                                                                                                                             topic,
                                                                                                                             clinical_indication,
                                                                                                                             clinical_indication_new,
                                                                                                                             to_execute,
                                                                                                                             to_execute_new,
                                                                                                                             frequency,
                                                                                                                             frequency_new,
                                                                                                                             start_date,
                                                                                                                             start_date_new,
                                                                                                                             order_notes,
                                                                                                                             order_notes_new,
                                                                                                                             description,
                                                                                                                             description_new,
                                                                                                                             status,
                                                                                                                             status_new,
                                                                                                                             registry,
                                                                                                                             white_line,
                                                                                                                             end_date,
                                                                                                                             end_date_new)))) dd
          JOIN dd_block ddb
            ON ddb.area = 'HEALTH_EDUCATION'
           AND ddb.internal_name = 'ORDER'
           AND ddb.flg_available = pk_alert_constant.g_yes;
    
        --EXECUTION
        SELECT t_rec_dd_block_data(ddb.id_dd_block,
                                   (ddb.rank * 100) + rn,
                                   NULL,
                                   NULL,
                                   ddb.condition_val,
                                   NULL,
                                   NULL,
                                   dd.data_source,
                                   dd.data_source_val,
                                   NULL)
          BULK COLLECT
          INTO l_tab_dd_block_data_exec
          FROM (SELECT data_source, data_source_val, row_number() over(PARTITION BY data_source ORDER BY rownum) AS rn
                  FROM (SELECT *
                          FROM (SELECT t.action,
                                       t.clinical_indication,
                                       t.goals,
                                       t.method,
                                       t.given_to,
                                       t.deliverables,
                                       t.understanding,
                                       t.start_date,
                                       t.duration,
                                       t.end_date,
                                       to_char(t.description) description,
                                       t.status,
                                       t.registry,
                                       t.white_line
                                  FROM TABLE(l_tbl_exec_detail) t) unpivot include NULLS(data_source_val FOR data_source IN(action,
                                                                                                                            clinical_indication,
                                                                                                                            goals,
                                                                                                                            method,
                                                                                                                            given_to,
                                                                                                                            deliverables,
                                                                                                                            understanding,
                                                                                                                            start_date,
                                                                                                                            duration,
                                                                                                                            end_date,
                                                                                                                            description,
                                                                                                                            status,
                                                                                                                            registry,
                                                                                                                            white_line)))) dd
          JOIN dd_block ddb
            ON ddb.area = 'HEALTH_EDUCATION'
           AND ddb.internal_name = 'EXECUTION'
           AND ddb.flg_available = pk_alert_constant.g_yes;
    
        --CANCELLATION
        SELECT t_rec_dd_block_data(ddb.id_dd_block,
                                   (ddb.rank * 100),
                                   NULL,
                                   NULL,
                                   ddb.condition_val,
                                   NULL,
                                   NULL,
                                   dd.data_source,
                                   dd.data_source_val,
                                   NULL)
          BULK COLLECT
          INTO l_tab_dd_block_data_cancel
          FROM (SELECT data_source, data_source_val
                  FROM (SELECT *
                          FROM (SELECT t.action, t.cancel_reason, t.cancel_notes, t.registry, t.white_line
                                  FROM TABLE(l_tbl_cancel_detail) t) unpivot include NULLS(data_source_val FOR data_source IN(action,
                                                                                                                              cancel_reason,
                                                                                                                              cancel_notes,
                                                                                                                              registry,
                                                                                                                              white_line)))) dd
          JOIN dd_block ddb
            ON ddb.area = 'HEALTH_EDUCATION'
           AND ddb.internal_name = 'CANCELLATION'
           AND ddb.flg_available = pk_alert_constant.g_yes;
    
        SELECT t_rec_dd_data(CASE
                                  WHEN data_code_message IS NOT NULL
                                       AND flg_type <> 'L3CQ' THEN
                                   pk_message.get_message(i_lang => i_lang, i_code_mess => data_code_message)
                                  WHEN flg_type = 'L3CQ' THEN
                                   data_code_message
                                  ELSE
                                   NULL
                              END, --DESCR
                              CASE
                                  WHEN flg_type = 'L1' THEN
                                   NULL
                                  ELSE
                                   data_source_val
                              END, --VAL
                              decode(flg_type, 'L3CQ', 'L3B', flg_type), -- TYPE
                              flg_html,
                              NULL,
                              flg_clob),
               data_source
          BULK COLLECT
          INTO l_tab_dd_data, l_data_source_list
          FROM (SELECT ddc.data_code_message,
                       flg_type,
                       data_source_val,
                       ddc.data_source,
                       db.rnk,
                       ddc.rank,
                       db.id_dd_block,
                       0 AS rank_cq,
                       flg_html,
                       flg_clob
                  FROM TABLE(l_tab_dd_block_data_order) db
                  JOIN dd_content ddc
                    ON ddc.data_source = db.data_source
                   AND ddc.flg_available = pk_alert_constant.g_yes
                   AND ddc.area = 'HEALTH_EDUCATION'
                 WHERE ddc.id_dd_block = db.id_dd_block
                   AND (db.data_source_val IS NOT NULL OR flg_type IN ('L1', 'WL'))
                UNION ALL
                SELECT ddc.data_code_message,
                       flg_type,
                       data_source_val,
                       ddc.data_source,
                       db.rnk,
                       ddc.rank,
                       db.id_dd_block,
                       0 AS rank_cq,
                       flg_html,
                       flg_clob
                  FROM TABLE(l_tab_dd_block_data_exec) db
                  JOIN dd_content ddc
                    ON ddc.data_source = db.data_source
                   AND ddc.flg_available = pk_alert_constant.g_yes
                   AND ddc.area = 'HEALTH_EDUCATION'
                 WHERE ddc.id_dd_block = db.id_dd_block
                   AND (db.data_source_val IS NOT NULL OR flg_type IN ('L1', 'WL'))
                UNION ALL
                SELECT ddc.data_code_message,
                       flg_type,
                       data_source_val,
                       ddc.data_source,
                       db.rnk,
                       ddc.rank,
                       db.id_dd_block,
                       0 AS rank_cq,
                       flg_html,
                       flg_clob
                  FROM TABLE(l_tab_dd_block_data_cancel) db
                  JOIN dd_content ddc
                    ON ddc.data_source = db.data_source
                   AND ddc.flg_available = pk_alert_constant.g_yes
                   AND ddc.area = 'HEALTH_EDUCATION'
                 WHERE ddc.id_dd_block = db.id_dd_block
                   AND (db.data_source_val IS NOT NULL OR flg_type IN ('L1', 'WL')))
         ORDER BY rnk, rank, rank_cq;
    
        OPEN o_detail FOR
            SELECT descr, val, flg_type, flg_html, val_clob, flg_clob
              FROM (SELECT CASE
                                WHEN d.val IS NULL THEN
                                 d.descr
                                WHEN d.descr IS NULL THEN
                                 NULL
                                ELSE
                                 d.descr || ' '
                            END descr,
                           d.val,
                           d.flg_type,
                           flg_html,
                           val_clob,
                           flg_clob,
                           d.rn
                      FROM (SELECT rownum rn, descr, val, flg_type, flg_html, val_clob, flg_clob
                              FROM TABLE(l_tab_dd_data)) d
                      JOIN (SELECT rownum rn, column_value data_source
                             FROM TABLE(l_data_source_list)) ds
                        ON ds.rn = d.rn);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_patient_education_det',
                                              o_error);
            pk_types.open_my_cursor(o_detail);
            RETURN FALSE;
    END get_patient_education_det_hist;
    --
    FUNCTION get_patient_education_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_list       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF NOT get_patient_education_list(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_id_episode => i_id_episode,
                                          i_id_hhc_req => NULL,
                                          o_list       => o_list,
                                          o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_cursor_if_closed(o_list);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PATIENT_EDUCATION_LIST',
                                              o_error);
        
            RETURN FALSE;
    END get_patient_education_list;

    FUNCTION get_patient_education_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE DEFAULT NULL,
        o_list       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_episode      table_number;
        l_has_notes       sys_message.desc_message%TYPE;
        l_begin           sys_message.desc_message%TYPE;
        l_label_notes_req sys_message.desc_message%TYPE;
        l_label_cacel_req sys_message.desc_message%TYPE;
    
        l_epis_type    epis_type.id_epis_type%TYPE;
        l_i_id_hhc_req epis_hhc_req.id_epis_hhc_req%TYPE;
        l_flg_can_edit VARCHAR2(1) := pk_alert_constant.g_yes;
    BEGIN
        -- MENSAGENS 
        l_has_notes := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'COMMON_M097');
    
        l_begin := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'PROCEDURES_T016') || ': ';
    
        l_label_notes_req := pk_message.get_message(i_lang      => i_lang,
                                                    i_prof      => i_prof,
                                                    i_code_mess => 'PATIENT_EDUCATION_M012');
    
        l_label_cacel_req := pk_message.get_message(i_lang      => i_lang,
                                                    i_prof      => i_prof,
                                                    i_code_mess => 'PATIENT_EDUCATION_M033');
    
        g_error := 'All episodes from this visit';
        SELECT t.id_episode
          BULK COLLECT
          INTO l_id_episode
          FROM (SELECT e.id_episode
                  FROM episode e
                 WHERE e.id_visit = pk_episode.get_id_visit(i_id_episode)
                UNION
                SELECT e.id_episode
                  FROM episode e
                 WHERE e.id_prev_episode IN (SELECT ehr.id_epis_hhc
                                               FROM alert.epis_hhc_req ehr
                                              WHERE ehr.id_episode = i_id_episode
                                                 OR ehr.id_epis_hhc_req = i_id_hhc_req)
                UNION
                SELECT ehr.id_epis_hhc
                  FROM alert.epis_hhc_req ehr
                 WHERE ehr.id_episode = i_id_episode
                    OR ehr.id_epis_hhc_req = i_id_hhc_req) t;
    
        IF i_id_episode IS NOT NULL
        THEN
            IF NOT pk_episode.get_epis_type(i_lang      => i_lang,
                                            i_id_epis   => i_id_episode,
                                            o_epis_type => l_epis_type,
                                            o_error     => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        IF l_epis_type IN (pk_alert_constant.g_epis_type_home_health_care, 99)
           OR i_id_hhc_req IS NOT NULL
        THEN
        
            l_i_id_hhc_req := nvl(i_id_hhc_req,
                                  pk_hhc_core.get_id_epis_hhc_req_by_pat(i_id_patient => pk_episode.get_id_patient(i_id_episode)));
        
            IF NOT pk_hhc_ux.get_prof_can_edit(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_id_hhc_req   => l_i_id_hhc_req,
                                               o_flg_can_edit => l_flg_can_edit,
                                               o_error        => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        g_error := 'List this visit?s patient education tasks';
        OPEN o_list FOR
            SELECT /*+opt_estimate(table t rows=1)*/
             ntr.id_nurse_tea_req,
             pk_patient_education_utils.get_desc_topic(i_lang,
                                                       i_prof,
                                                       ntr.id_nurse_tea_topic,
                                                       ntr.desc_topic_aux,
                                                       ntt.code_nurse_tea_topic) title_topic,
             pk_translation.get_translation(i_lang,
                                             CASE
                                                 WHEN nts.code_nurse_tea_subject IS NULL THEN
                                                  'NURSE_TEA_SUBJECT.CODE_NURSE_TEA_SUBJECT.1'
                                                 ELSE
                                                  nts.code_nurse_tea_subject
                                             END) title_subject,
             ntt.id_nurse_tea_topic,
             nts.id_nurse_tea_subject,
             CASE
                  WHEN ntr.notes_req IS NOT NULL THEN
                   l_has_notes
                  WHEN ntr.notes_close IS NOT NULL THEN
                   l_has_notes
                  ELSE
                   NULL
              END title_notes,
             decode(ntr.notes_req, NULL, NULL, ntr.notes_req) notes_req,
             l_label_notes_req label_notes_req,
             decode(ntr.flg_status, 'C', ntr.notes_close, NULL) notes_cancel,
             l_label_cacel_req label_notes_cancel,
             l_begin || pk_date_utils.dt_chr_date_hour_tsz(i_lang, ntr.dt_begin_tstz, i_prof) instructions,
             ntr.flg_status,
             pk_sysdomain.get_domain('NURSE_TEA_REQ.FLG_STATUS', ntr.flg_status, i_lang) desc_status,
             ntr.flg_time,
             pk_prof_utils.get_nickname(i_lang, ntr.id_prof_req) prof_order,
             pk_patient_education_utils.get_diagnosis(i_lang, i_prof, ntr.id_nurse_tea_req) desc_diagnosis,
             pk_utils.get_status_string(i_lang, i_prof, ntr.status_str, ntr.status_msg, ntr.status_icon, ntr.status_flg) status_string,
             ntr.id_context,
             pk_info_button.get_cds_show_info_button(i_lang, i_prof, ntr.id_context) info_button_url,
             l_flg_can_edit flg_can_edit
              FROM nurse_tea_req ntr
              LEFT JOIN nurse_tea_topic ntt
                ON ntt.id_nurse_tea_topic = ntr.id_nurse_tea_topic
              LEFT JOIN nurse_tea_subject nts
                ON nts.id_nurse_tea_subject = ntt.id_nurse_tea_subject
              JOIN professional p
                ON p.id_professional = ntr.id_prof_req
              JOIN TABLE(l_id_episode) t
                ON t.column_value = ntr.id_episode
             WHERE ntr.flg_status NOT IN (pk_patient_education_constant.g_nurse_tea_req_draft)
             ORDER BY pk_sysdomain.get_rank(i_lang     => i_lang,
                                            i_code_dom => 'NURSE_TEA_REQ.FLG_STATUS',
                                            i_val      => ntr.flg_status),
                      title_subject,
                      title_topic,
                      desc_diagnosis;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_cursor_if_closed(o_list);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PATIENT_EDUCATION_LIST',
                                              o_error);
        
            RETURN FALSE;
    END get_patient_education_list;

    FUNCTION get_topic_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_keyword         IN VARCHAR2 DEFAULT NULL,
        i_most_frequent   IN VARCHAR2 DEFAULT 'Y',
        i_id_subject      IN nurse_tea_subject.id_nurse_tea_subject%TYPE DEFAULT NULL,
        i_flg_show_others IN VARCHAR2 DEFAULT 'Y',
        o_topics          OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_market          market.id_market%TYPE;
        l_prof_dep_clin_serv table_number;
    BEGIN
        l_id_market := pk_utils.get_institution_market(i_lang => i_lang, i_id_institution => i_prof.institution);
    
        g_error := 'Get professional?s associated dep_clin_serv';
        BEGIN
            SELECT pdcs.id_dep_clin_serv
              BULK COLLECT
              INTO l_prof_dep_clin_serv
              FROM prof_dep_clin_serv pdcs
              JOIN dep_clin_serv dcs
                ON dcs.id_dep_clin_serv = pdcs.id_dep_clin_serv
              JOIN department d
                ON d.id_department = dcs.id_department
             WHERE pdcs.id_professional = i_prof.id
               AND d.id_institution = i_prof.institution
               AND pdcs.flg_status = pk_patient_education_constant.g_selected
            UNION ALL
            SELECT 0
              FROM dual;
        EXCEPTION
            WHEN no_data_found THEN
                l_prof_dep_clin_serv := table_number();
        END;
    
        IF i_most_frequent IS NULL
        THEN
            NULL;
        ELSIF i_most_frequent NOT IN (pk_alert_constant.g_no, pk_alert_constant.g_yes)
        THEN
            RAISE g_exception;
        END IF;
    
        -- Patient education topics with not-null description, sorted by subject
        OPEN o_topics FOR
            SELECT id_subject, desc_subject, id_topic, title_topic, desc_topic, desc_topic_context_help
              FROM (SELECT o_ntt.id_nurse_tea_topic id_topic,
                           o_ntt.id_nurse_tea_subject id_subject,
                           pk_translation.get_translation(i_lang, o_ntt.code_nurse_tea_topic) title_topic,
                           pk_translation_lob.get_translation(i_lang, o_ntt.code_topic_description) desc_topic,
                           pk_translation.get_translation(i_lang, nts.code_nurse_tea_subject) desc_subject,
                           pk_translation_lob.get_translation(i_lang, o_ntt.code_topic_context_help) desc_topic_context_help
                      FROM nurse_tea_topic o_ntt
                      JOIN nurse_tea_subject nts
                        ON nts.id_nurse_tea_subject = o_ntt.id_nurse_tea_subject
                     WHERE nts.flg_available = pk_alert_constant.g_yes
                       AND (i_flg_show_others = pk_alert_constant.g_no AND o_ntt.id_nurse_tea_topic <> 1)
                        OR (i_flg_show_others = pk_alert_constant.g_yes)
                       AND o_ntt.flg_available = pk_alert_constant.g_yes
                       AND (i_id_subject IS NULL OR
                           (i_id_subject IS NOT NULL AND i_id_subject = nts.id_nurse_tea_subject))
                       AND EXISTS (SELECT nttsi.id_nurse_tea_topic
                              FROM nurse_tea_top_soft_inst nttsi
                             WHERE rownum > 0
                               AND ((i_most_frequent = pk_alert_constant.g_no AND
                                   nttsi.flg_type = pk_patient_education_constant.g_searchable) OR
                                   (i_most_frequent = pk_alert_constant.g_yes AND
                                   nttsi.flg_type = pk_patient_education_constant.g_frequent AND
                                   nvl(nttsi.id_dep_clin_serv, 0) IN
                                   (SELECT column_value
                                        FROM TABLE(l_prof_dep_clin_serv))))
                               AND nttsi.id_nurse_tea_topic = o_ntt.id_nurse_tea_topic
                               AND nttsi.flg_available = pk_alert_constant.g_yes
                               AND nttsi.id_software IN (0, i_prof.software)
                               AND nttsi.id_institution IN (0, i_prof.institution)
                               AND nttsi.id_market IN (0, l_id_market)
                            MINUS
                            SELECT nttsi.id_nurse_tea_topic
                              FROM nurse_tea_top_soft_inst nttsi
                             WHERE rownum > 0
                               AND ((i_most_frequent = pk_alert_constant.g_no AND
                                   nttsi.flg_type = pk_patient_education_constant.g_searchable) OR
                                   (i_most_frequent = pk_alert_constant.g_yes AND
                                   nttsi.flg_type = pk_patient_education_constant.g_frequent AND
                                   nvl(nttsi.id_dep_clin_serv, 0) IN
                                   (SELECT column_value
                                        FROM TABLE(l_prof_dep_clin_serv))))
                               AND nttsi.id_nurse_tea_topic = o_ntt.id_nurse_tea_topic
                               AND nttsi.flg_available = pk_alert_constant.g_no
                               AND nttsi.id_software IN (0, i_prof.software)
                               AND nttsi.id_institution IN (0, i_prof.institution)
                               AND nttsi.id_market IN (0, l_id_market)))
             WHERE title_topic IS NOT NULL
               AND desc_subject IS NOT NULL
             ORDER BY desc_subject, title_topic;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_cursor_if_closed(o_topics);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TOPIC_LIST',
                                              o_error);
        
            RETURN FALSE;
    END get_topic_list;

    --
    FUNCTION get_topic_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_flg_show_others IN VARCHAR2 DEFAULT 'Y',
        o_topics          OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN get_topic_list(i_lang            => i_lang,
                              i_prof            => i_prof,
                              i_most_frequent   => pk_alert_constant.g_yes,
                              i_flg_show_others => i_flg_show_others,
                              o_topics          => o_topics,
                              o_error           => o_error);
    END get_topic_list;

    --
    FUNCTION get_topic_search
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_keyword         IN VARCHAR2,
        i_flg_show_others IN VARCHAR2 DEFAULT 'Y',
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_topics          OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_limit     sys_config.value%TYPE;
        l_count     PLS_INTEGER;
        l_id_market market.id_market%TYPE;
    BEGIN
    
        l_limit     := pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof);
        o_flg_show  := 'N';
        l_id_market := pk_prof_utils.get_prof_market(i_prof);
    
        SELECT COUNT(*)
          INTO l_count
          FROM (SELECT id_subject, desc_subject, id_topic, title_topic, desc_topic
                  FROM (SELECT /*+opt_estimate(table st rows=1)*/
                         nts.id_nurse_tea_subject id_subject,
                         pk_translation.get_translation(i_lang, nts.code_nurse_tea_subject) desc_subject,
                         ntt.id_nurse_tea_topic id_topic,
                         st.desc_translation title_topic,
                         pk_translation_lob.get_translation(i_lang, ntt.code_topic_description) desc_topic
                          FROM TABLE(pk_translation.get_search_translation(i_lang,
                                                                           i_keyword,
                                                                           'NURSE_TEA_TOPIC.CODE_NURSE_TEA_TOPIC')) st
                          JOIN nurse_tea_topic ntt
                            ON ntt.code_nurse_tea_topic = st.code_translation
                          JOIN nurse_tea_subject nts
                            ON nts.id_nurse_tea_subject = ntt.id_nurse_tea_subject
                         WHERE ((i_flg_show_others = pk_alert_constant.g_no AND ntt.id_nurse_tea_topic <> 1) OR
                               (i_flg_show_others = pk_alert_constant.g_yes))
                           AND ntt.flg_available = pk_alert_constant.g_yes
                           AND EXISTS (SELECT nttsi.id_nurse_tea_topic
                                  FROM nurse_tea_top_soft_inst nttsi
                                 WHERE rownum > 0
                                   AND nttsi.id_nurse_tea_topic = ntt.id_nurse_tea_topic
                                   AND nttsi.flg_available = pk_alert_constant.g_yes
                                   AND nttsi.id_software IN (0, i_prof.software)
                                   AND nttsi.id_institution IN (0, i_prof.institution)
                                   AND nttsi.id_market IN (0, l_id_market)
                                MINUS
                                SELECT nttsi.id_nurse_tea_topic
                                  FROM nurse_tea_top_soft_inst nttsi
                                 WHERE rownum > 0
                                   AND nttsi.id_nurse_tea_topic = ntt.id_nurse_tea_topic
                                   AND nttsi.flg_available = pk_alert_constant.g_no
                                   AND nttsi.id_software IN (0, i_prof.software)
                                   AND nttsi.id_institution IN (0, i_prof.institution)
                                   AND nttsi.id_market IN (0, l_id_market)))
                 WHERE title_topic IS NOT NULL
                   AND desc_subject IS NOT NULL);
    
        IF l_count > l_limit
        THEN
            o_flg_show  := 'Y';
            o_msg       := pk_search.get_overlimit_message(i_lang           => i_lang,
                                                           i_prof           => i_prof,
                                                           i_flg_has_action => pk_alert_constant.g_yes);
            o_msg_title := pk_message.get_message(i_lang, 'SEARCH_CRITERIA_T011');
            o_button    := 'R';
        ELSIF l_count = 0
        THEN
            o_flg_show  := 'Y';
            o_msg       := pk_message.get_message(i_lang, 'COMMON_M015');
            o_msg_title := pk_message.get_message(i_lang, 'SEARCH_CRITERIA_T011');
            o_button    := 'R';
        
            pk_types.open_cursor_if_closed(o_topics);
            RETURN TRUE;
        END IF;
    
        OPEN o_topics FOR
            SELECT id_subject, desc_subject, id_topic, title_topic, desc_topic, desc_topic_context_help
              FROM (SELECT /*+opt_estimate(table st rows=1)*/
                     nts.id_nurse_tea_subject id_subject,
                     pk_translation.get_translation(i_lang, nts.code_nurse_tea_subject) desc_subject,
                     ntt.id_nurse_tea_topic id_topic,
                     st.desc_translation title_topic,
                     pk_translation_lob.get_translation(i_lang, ntt.code_topic_description) desc_topic,
                     pk_translation_lob.get_translation(i_lang, ntt.code_topic_context_help) desc_topic_context_help
                      FROM TABLE(pk_translation.get_search_translation(i_lang,
                                                                       i_keyword,
                                                                       'NURSE_TEA_TOPIC.CODE_NURSE_TEA_TOPIC')) st
                      JOIN nurse_tea_topic ntt
                        ON ntt.code_nurse_tea_topic = st.code_translation
                      JOIN nurse_tea_subject nts
                        ON nts.id_nurse_tea_subject = ntt.id_nurse_tea_subject
                     WHERE ((i_flg_show_others = pk_alert_constant.g_no AND ntt.id_nurse_tea_topic <> 1) OR
                           (i_flg_show_others = pk_alert_constant.g_yes))
                       AND ntt.flg_available = pk_alert_constant.g_yes
                       AND (EXISTS (SELECT nttsi.id_nurse_tea_topic
                                      FROM nurse_tea_top_soft_inst nttsi
                                     WHERE rownum > 0
                                       AND nttsi.id_nurse_tea_topic = ntt.id_nurse_tea_topic
                                       AND nttsi.flg_available = pk_alert_constant.g_yes
                                       AND nttsi.id_software IN (0, i_prof.software)
                                       AND nttsi.id_institution IN (0, i_prof.institution)
                                       AND nttsi.id_market IN (0, l_id_market)
                                    MINUS
                                    SELECT nttsi.id_nurse_tea_topic
                                      FROM nurse_tea_top_soft_inst nttsi
                                     WHERE rownum > 0
                                       AND nttsi.id_nurse_tea_topic = ntt.id_nurse_tea_topic
                                       AND nttsi.flg_available = pk_alert_constant.g_no
                                       AND nttsi.id_software IN (0, i_prof.software)
                                       AND nttsi.id_institution IN (0, i_prof.institution)
                                       AND nttsi.id_market IN (0, l_id_market))))
             WHERE title_topic IS NOT NULL
               AND desc_subject IS NOT NULL
             ORDER BY desc_subject, title_topic;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_cursor_if_closed(o_topics);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TOPIC_SEARCH',
                                              o_error);
        
            RETURN FALSE;
    END get_topic_search;

    --
    FUNCTION get_subject_topic_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_subject      IN nurse_tea_subject.id_nurse_tea_subject%TYPE,
        i_flg_show_others IN VARCHAR2 DEFAULT 'Y',
        o_subjects        OUT pk_types.cursor_type,
        o_topics          OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_market market.id_market%TYPE;
    BEGIN
        l_id_market := pk_prof_utils.get_prof_market(i_prof);
    
        -- Patient education subjects with a not-null description and with child topics
        IF i_id_subject IS NOT NULL
        THEN
            pk_types.open_cursor_if_closed(o_subjects);
        
        ELSE
            OPEN o_subjects FOR
                SELECT id_nurse_tea_subject, desc_nurse_tea_subject
                  FROM (SELECT nts.id_nurse_tea_subject,
                               pk_translation.get_translation(i_lang, nts.code_nurse_tea_subject) desc_nurse_tea_subject
                          FROM nurse_tea_subject nts
                         WHERE rownum > 0
                           AND (i_flg_show_others = pk_alert_constant.g_no AND nts.id_nurse_tea_subject <> 1)
                            OR (i_flg_show_others = pk_alert_constant.g_yes)
                           AND (i_id_subject IS NULL OR
                               (i_id_subject IS NOT NULL AND i_id_subject = nts.id_nurse_tea_subject))
                           AND nts.flg_available = pk_alert_constant.g_yes
                           AND EXISTS (SELECT ntt.id_nurse_tea_topic
                                  FROM nurse_tea_topic ntt
                                  JOIN nurse_tea_top_soft_inst nttsi
                                    ON nttsi.id_nurse_tea_topic = ntt.id_nurse_tea_topic
                                 WHERE rownum > 0
                                   AND ntt.id_nurse_tea_subject = nts.id_nurse_tea_subject
                                   AND ntt.flg_available = pk_alert_constant.g_yes
                                   AND nttsi.flg_available = pk_alert_constant.g_yes
                                   AND nttsi.id_software IN (0, i_prof.software)
                                   AND nttsi.id_institution IN (0, i_prof.institution)
                                   AND nttsi.id_market IN (0, l_id_market)
                                   AND pk_translation.get_translation(i_lang, ntt.code_nurse_tea_topic) IS NOT NULL
                                MINUS
                                SELECT ntt.id_nurse_tea_topic
                                  FROM nurse_tea_topic ntt
                                  JOIN nurse_tea_top_soft_inst nttsi
                                    ON nttsi.id_nurse_tea_topic = ntt.id_nurse_tea_topic
                                 WHERE rownum > 0
                                   AND ntt.id_nurse_tea_subject = nts.id_nurse_tea_subject
                                   AND ntt.flg_available = pk_alert_constant.g_yes
                                   AND nttsi.flg_available = pk_alert_constant.g_no
                                   AND nttsi.id_software IN (0, i_prof.software)
                                   AND nttsi.id_institution IN (0, i_prof.institution)
                                   AND nttsi.id_market IN (0, l_id_market)))
                 WHERE desc_nurse_tea_subject IS NOT NULL
                 ORDER BY desc_nurse_tea_subject;
        END IF;
    
        -- Get topics
        IF i_id_subject IS NULL
        THEN
            pk_types.open_cursor_if_closed(o_topics);
        
        ELSE
            IF NOT get_topic_list(i_lang            => i_lang,
                                  i_prof            => i_prof,
                                  i_most_frequent   => pk_alert_constant.g_no,
                                  i_id_subject      => i_id_subject,
                                  i_flg_show_others => i_flg_show_others,
                                  o_topics          => o_topics,
                                  o_error           => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_cursor_if_closed(o_subjects);
            pk_types.open_cursor_if_closed(o_topics);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SUBJECT_TOPIC_LIST',
                                              o_error);
        
            RETURN FALSE;
    END get_subject_topic_list;

    --
    /******************************************************************************/

    PROCEDURE prv_alter_ntr_by_id
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_nurse_tea_req     IN nurse_tea_req.id_nurse_tea_req%TYPE DEFAULT NULL,
        i_id_episode           IN nurse_tea_req.id_episode%TYPE DEFAULT NULL,
        i_flg_status           IN nurse_tea_req.flg_status%TYPE DEFAULT NULL,
        i_dt_nurse_tea_req_str IN VARCHAR2 DEFAULT NULL,
        i_id_prof_req          IN profissional,
        i_dt_begin_str         IN VARCHAR2 DEFAULT NULL,
        i_notes_req            IN nurse_tea_req.notes_req%TYPE DEFAULT NULL,
        i_dt_close_str         IN VARCHAR2 DEFAULT NULL,
        i_id_prof_close        IN nurse_tea_req.id_prof_close%TYPE DEFAULT NULL,
        i_notes_close          IN nurse_tea_req.notes_close%TYPE DEFAULT NULL,
        i_req_header           IN nurse_tea_req.req_header%TYPE DEFAULT NULL,
        i_id_visit             IN nurse_tea_req.id_visit%TYPE DEFAULT NULL,
        i_id_patient           IN nurse_tea_req.id_patient%TYPE DEFAULT NULL,
        i_id_cancel_reason     IN nurse_tea_req.id_cancel_reason%TYPE DEFAULT NULL,
        o_rowids               OUT table_varchar
    );

    /******************************************************************************/
    PROCEDURE prv_alter_ntr_by_id
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_nurse_tea_req     IN nurse_tea_req.id_nurse_tea_req%TYPE DEFAULT NULL,
        i_id_episode           IN nurse_tea_req.id_episode%TYPE DEFAULT NULL,
        i_flg_status           IN nurse_tea_req.flg_status%TYPE DEFAULT NULL,
        i_dt_nurse_tea_req_str IN VARCHAR2 DEFAULT NULL,
        i_id_prof_req          IN profissional,
        i_dt_begin_str         IN VARCHAR2 DEFAULT NULL,
        i_notes_req            IN nurse_tea_req.notes_req%TYPE DEFAULT NULL,
        i_dt_close_str         IN VARCHAR2 DEFAULT NULL,
        i_id_prof_close        IN nurse_tea_req.id_prof_close%TYPE DEFAULT NULL,
        i_notes_close          IN nurse_tea_req.notes_close%TYPE DEFAULT NULL,
        i_req_header           IN nurse_tea_req.req_header%TYPE DEFAULT NULL,
        i_id_visit             IN nurse_tea_req.id_visit%TYPE DEFAULT NULL,
        i_id_patient           IN nurse_tea_req.id_patient%TYPE DEFAULT NULL,
        i_id_cancel_reason     IN nurse_tea_req.id_cancel_reason%TYPE DEFAULT NULL,
        o_rowids               OUT table_varchar
    ) IS
        -- Auxiliar Variables
        dt_aux_nurse_tea_req_tstz TIMESTAMP WITH TIME ZONE := NULL;
        dt_aux_begin_tstz         TIMESTAMP WITH TIME ZONE := NULL;
        dt_aux_close_tstz         TIMESTAMP WITH TIME ZONE := NULL;
        --
        l_ntr_row_old nurse_tea_req%ROWTYPE;
        l_ntr_row     nurse_tea_req%ROWTYPE;
        l_error       t_error_out;
    
    BEGIN
    
        IF i_dt_nurse_tea_req_str IS NOT NULL
        THEN
            dt_aux_nurse_tea_req_tstz := pk_date_utils.get_string_tstz(i_lang,
                                                                       i_id_prof_req,
                                                                       i_dt_nurse_tea_req_str,
                                                                       NULL);
        END IF;
    
        IF i_dt_begin_str IS NOT NULL
        THEN
            dt_aux_begin_tstz := pk_date_utils.get_string_tstz(i_lang, i_id_prof_req, i_dt_begin_str, NULL);
        END IF;
    
        IF i_dt_close_str IS NOT NULL
        THEN
            dt_aux_close_tstz := pk_date_utils.get_string_tstz(i_lang, i_id_prof_req, i_dt_close_str, NULL);
        END IF;
    
        -- < DESNORM Lu�s Maia - Sep 2008 >
        -- Apanha os resultados antes do UPDATE para que se os novos valores forem NULL, mantenha os antigos valores.
        SELECT *
          INTO l_ntr_row_old
          FROM nurse_tea_req ntr
         WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req;
    
        -- Carrega na estrutura os dados para posteriormente realizar o UPDATE
        l_ntr_row.id_nurse_tea_req      := i_id_nurse_tea_req;
        l_ntr_row.id_prof_req           := nvl(i_id_prof_req.id, l_ntr_row_old.id_prof_req);
        l_ntr_row.id_episode            := nvl(i_id_episode, l_ntr_row_old.id_episode);
        l_ntr_row.req_header            := nvl(i_req_header, l_ntr_row_old.req_header);
        l_ntr_row.flg_status            := nvl(i_flg_status, l_ntr_row_old.flg_status);
        l_ntr_row.notes_req             := nvl(i_notes_req, l_ntr_row_old.notes_req);
        l_ntr_row.id_prof_close         := nvl(i_id_prof_close, l_ntr_row_old.id_prof_close);
        l_ntr_row.notes_close           := nvl(i_notes_close, l_ntr_row_old.notes_close);
        l_ntr_row.dt_nurse_tea_req_tstz := nvl(dt_aux_nurse_tea_req_tstz, l_ntr_row_old.dt_nurse_tea_req_tstz);
        l_ntr_row.dt_begin_tstz         := nvl(dt_aux_begin_tstz, l_ntr_row_old.dt_begin_tstz);
        l_ntr_row.dt_close_tstz         := nvl(dt_aux_close_tstz, l_ntr_row_old.dt_close_tstz);
        l_ntr_row.id_visit              := nvl(i_id_visit, l_ntr_row_old.id_visit);
        l_ntr_row.id_patient            := nvl(i_id_patient, l_ntr_row_old.id_patient);
        l_ntr_row.id_cancel_reason      := nvl(i_id_cancel_reason, l_ntr_row_old.id_cancel_reason);
    
        -- Realiza o UPDATE linha da tabela NURSE_TEA_REQ
        g_error := 'NURSE_TEA_REQ';
        ts_nurse_tea_req.upd(rec_in => l_ntr_row, rows_out => o_rowids);
        -- < END DESNORM >
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --PLLopes 10/03/2009 - Inicialization of object for input
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_ret       BOOLEAN;
                l_error     VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001');
            BEGIN
                -- setting error content into input object
                l_error_in.set_errors(SQLCODE, SQLERRM, l_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_PATIENT_EDUCATION_UX', 'PRV_ALTER_NTR_BY_ID');
                -- execute error processing
                l_ret := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                -- undo changes quando se faz ROLLBACK
                pk_utils.undo_changes;
            
            END;
    END prv_alter_ntr_by_id;

    /******************************************************************************/

    FUNCTION set_nurse_tea_req_status
    (
        i_lang          IN language.id_language%TYPE,
        i_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_epis IS
            SELECT id_episode
              FROM nurse_tea_req
             WHERE id_nurse_tea_req = i_nurse_tea_req;
    
        l_epis episode.id_episode%TYPE;
        --l_error                   VARCHAR2(4000);
        l_error      t_error_out;
        l_ntr_rowids table_varchar;
        --err_id                     PLS_INTEGER;
        l_count_nurse_tea_det      NUMBER;
        l_count_nurse_tea_det_exec NUMBER;
    
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        SELECT COUNT(*)
          INTO l_count_nurse_tea_det_exec
          FROM nurse_tea_det ntd
         WHERE ntd.id_nurse_tea_req = i_nurse_tea_req
           AND ntd.flg_status IN
               (pk_patient_education_constant.g_nurse_tea_det_exec, pk_patient_education_constant.g_nurse_tea_det_canc);
    
        SELECT COUNT(*)
          INTO l_count_nurse_tea_det
          FROM nurse_tea_det ntd
         WHERE ntd.id_nurse_tea_req = i_nurse_tea_req
           AND ntd.flg_status <> pk_patient_education_constant.g_nurse_tea_det_ign;
    
        CASE
            WHEN l_count_nurse_tea_det_exec = 0 THEN
            
                g_error := 'prv_alter_ntr_by_id';
                prv_alter_ntr_by_id(i_lang             => i_lang,
                                    i_prof             => i_prof,
                                    i_id_nurse_tea_req => i_nurse_tea_req,
                                    i_flg_status       => pk_patient_education_constant.g_nurse_tea_req_act,
                                    i_id_prof_req      => profissional(NULL, i_prof.institution, i_prof.software),
                                    i_dt_close_str     => pk_date_utils.get_timestamp_str(i_lang,
                                                                                          i_prof,
                                                                                          g_sysdate_tstz,
                                                                                          NULL),
                                    i_id_prof_close    => i_prof.id,
                                    o_rowids           => l_ntr_rowids);
            
                g_error := 'CALL TO T_DATA_GOV_MNT.PROCESS_UPDATE NURSE_TEA_REQ - NURSE_TEA_REQ';
                t_data_gov_mnt.process_update(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_table_name   => 'NURSE_TEA_REQ',
                                              i_list_columns => table_varchar('id_nurse_tea_req',
                                                                              'id_prof_req',
                                                                              'id_episode',
                                                                              'req_header',
                                                                              'flg_status',
                                                                              'notes_req',
                                                                              'id_prof_close',
                                                                              'notes_close',
                                                                              'dt_nurse_tea_req_tstz',
                                                                              'dt_begin_tstz',
                                                                              'dt_close_tstz',
                                                                              'id_visit',
                                                                              'id_patient'),
                                              i_rowids       => l_ntr_rowids,
                                              o_error        => o_error);
            
                insert_ntr_hist(i_lang             => i_lang,
                                i_prof             => i_prof,
                                i_id_nurse_tea_req => i_nurse_tea_req,
                                o_error            => o_error);
            
            WHEN l_count_nurse_tea_det_exec = l_count_nurse_tea_det THEN
            
                g_error := 'prv_alter_ntr_by_id';
                prv_alter_ntr_by_id(i_lang             => i_lang,
                                    i_prof             => i_prof,
                                    i_id_nurse_tea_req => i_nurse_tea_req,
                                    i_flg_status       => pk_patient_education_constant.g_nurse_tea_req_fin,
                                    i_id_prof_req      => profissional(NULL, i_prof.institution, i_prof.software),
                                    i_dt_close_str     => pk_date_utils.get_timestamp_str(i_lang,
                                                                                          i_prof,
                                                                                          g_sysdate_tstz,
                                                                                          NULL),
                                    i_id_prof_close    => i_prof.id,
                                    o_rowids           => l_ntr_rowids);
            
                g_error := 'CALL TO T_DATA_GOV_MNT.PROCESS_UPDATE NURSE_TEA_REQ - NURSE_TEA_REQ';
                t_data_gov_mnt.process_update(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_table_name   => 'NURSE_TEA_REQ',
                                              i_list_columns => table_varchar('id_nurse_tea_req',
                                                                              'id_prof_req',
                                                                              'id_episode',
                                                                              'req_header',
                                                                              'flg_status',
                                                                              'notes_req',
                                                                              'id_prof_close',
                                                                              'notes_close',
                                                                              'dt_nurse_tea_req_tstz',
                                                                              'dt_begin_tstz',
                                                                              'dt_close_tstz',
                                                                              'id_visit',
                                                                              'id_patient'),
                                              i_rowids       => l_ntr_rowids,
                                              o_error        => o_error);
            
                insert_ntr_hist(i_lang             => i_lang,
                                i_prof             => i_prof,
                                i_id_nurse_tea_req => i_nurse_tea_req,
                                o_error            => o_error);
            ELSE
                NULL;
            
        END CASE;
    
        g_error := 'OPEN c_epis';
        OPEN c_epis;
        FETCH c_epis
            INTO l_epis;
        CLOSE c_epis;
    
        -- PLLopes 30/01/2008 - ALERT912
        -- insert log status
        IF NOT t_ti_log.ins_log(i_lang,
                                i_prof,
                                l_epis,
                                pk_patient_education_constant.g_nurse_tea_req_fin,
                                i_nurse_tea_req,
                                pk_edis_summary.g_ti_log_nurse_tea,
                                o_error)
        THEN
            RETURN FALSE;
        END IF;
        --  ALERT912
    
        COMMIT;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --PLLopes 10/03/2009 - Inicialization of object for input
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_ret       BOOLEAN;
                l_error_s   VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
            BEGIN
                -- setting error content into input object
                l_error_in.set_errors(SQLCODE, SQLERRM, l_error_s);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_PATIENT_EDUCATION_UX', 'SET_NURSE_TEA_REQ_STATUS');
                -- execute error processing
                l_ret   := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                o_error := l_error_out;
                -- undo changes quando se faz ROLLBACK
                pk_utils.undo_changes;
                --reset error state
                pk_alert_exceptions.reset_error_state();
                RETURN FALSE;
            END;
        
    END set_nurse_tea_req_status;
    /************************************************/
    FUNCTION get_documentation_det
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE,
        o_goals            OUT pk_types.cursor_type,
        o_methods          OUT pk_types.cursor_type,
        o_given_to         OUT pk_types.cursor_type,
        o_deliverables     OUT pk_types.cursor_type,
        o_understanding    OUT pk_types.cursor_type,
        o_info             OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_goals                    nurse_tea_opt.subject%TYPE := 'GOALS';
        l_method                   nurse_tea_opt.subject%TYPE := 'METHOD';
        l_level                    nurse_tea_opt.subject%TYPE := 'LEVEL_OF_UNDERSTANDING';
        l_given_to                 nurse_tea_opt.subject%TYPE := 'GIVEN_TO';
        l_deliverables             nurse_tea_opt.subject%TYPE := 'DELIVERABLES';
        l_free_text                sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                           i_prof,
                                                                                           'PATIENT_EDUCATION_M001');
        l_clinical_service         table_number;
        l_pat_education_id_add_res sys_config.value%TYPE := pk_sysconfig.get_config('DEFAULT_ID_PAT_EDUCATION_ADDITIONAL_RESOURCES',
                                                                                    i_prof.institution,
                                                                                    i_prof.software);
        l_nurse_tea_opt_desc       VARCHAR2(4000);
        l_nurse_tea_opt_id         nurse_tea_opt.id_nurse_tea_opt%TYPE;
    
        CURSOR c_nurse_tea_opt_desc IS
            SELECT DISTINCT pk_translation.get_translation(i_lang, nto.code_nurse_tea_opt),
                            nto.id_nurse_tea_opt id_nurse_tea_opt
              FROM nurse_tea_opt nto
             WHERE nto.id_nurse_tea_opt = l_pat_education_id_add_res;
    BEGIN
    
        OPEN c_nurse_tea_opt_desc;
        FETCH c_nurse_tea_opt_desc
            INTO l_nurse_tea_opt_desc, l_nurse_tea_opt_id;
        CLOSE c_nurse_tea_opt_desc;
    
        SELECT id_clinical_service
          BULK COLLECT
          INTO l_clinical_service
          FROM (SELECT d.id_clinical_service
                  FROM prof_dep_clin_serv p
                  JOIN dep_clin_serv d
                    ON d.id_dep_clin_serv = p.id_dep_clin_serv
                 WHERE p.id_professional = i_prof.id
                   AND p.id_institution = i_prof.institution
                   AND p.flg_status = pk_patient_education_constant.g_selected
                   AND d.flg_available = pk_alert_constant.g_yes
                UNION ALL
                SELECT 0
                  FROM dual);
    
        OPEN o_goals FOR
            SELECT subject, data, label
              FROM (SELECT nto.subject,
                           nto.id_nurse_tea_opt data,
                           pk_translation.get_translation(i_lang, nto.code_nurse_tea_opt) label,
                           nvl(ntoi.rank, 0) rank
                      FROM nurse_tea_opt nto
                      JOIN nurse_tea_opt_inst ntoi
                        ON ntoi.id_nurse_tea_opt = nto.id_nurse_tea_opt
                     WHERE nto.subject = l_goals
                       AND nvl(ntoi.id_institution, 0) IN (0, i_prof.institution)
                       AND nvl(ntoi.id_clinical_service, 0) IN
                           (SELECT column_value
                              FROM TABLE(l_clinical_service))
                    UNION ALL
                    SELECT l_goals, -1, l_free_text, NULL rank
                      FROM dual)
             ORDER BY rank NULLS LAST, subject, label;
    
        OPEN o_methods FOR
            SELECT subject, data, label
              FROM (SELECT nto.subject,
                           nto.id_nurse_tea_opt data,
                           pk_translation.get_translation(i_lang, nto.code_nurse_tea_opt) label,
                           nvl(ntoi.rank, 0) rank
                      FROM nurse_tea_opt nto
                      JOIN nurse_tea_opt_inst ntoi
                        ON ntoi.id_nurse_tea_opt = nto.id_nurse_tea_opt
                     WHERE nto.subject = l_method
                       AND nvl(ntoi.id_institution, 0) IN (0, i_prof.institution)
                       AND nvl(ntoi.id_clinical_service, 0) IN
                           (SELECT column_value
                              FROM TABLE(l_clinical_service))
                    UNION ALL
                    SELECT l_method, -1, l_free_text, NULL rank
                      FROM dual)
             ORDER BY rank NULLS LAST, subject, label;
    
        OPEN o_deliverables FOR
            SELECT subject, data, label, flg_print
              FROM (SELECT nto.subject,
                           nto.id_nurse_tea_opt data,
                           pk_translation.get_translation(i_lang, nto.code_nurse_tea_opt) label,
                           nto.flg_print flg_print,
                           nvl(ntoi.rank, 0) rank
                      FROM nurse_tea_opt nto
                      JOIN nurse_tea_opt_inst ntoi
                        ON ntoi.id_nurse_tea_opt = nto.id_nurse_tea_opt
                     WHERE nto.subject = l_deliverables
                       AND nvl(ntoi.id_institution, 0) IN (0, i_prof.institution)
                       AND nvl(ntoi.id_clinical_service, 0) IN
                           (SELECT column_value
                              FROM TABLE(l_clinical_service))
                    UNION ALL
                    SELECT l_deliverables, -1, l_free_text, pk_alert_constant.g_no flg_print, NULL rank
                      FROM dual)
             ORDER BY rank NULLS LAST, subject, label;
    
        OPEN o_given_to FOR
            SELECT subject, data, label
              FROM (SELECT nto.subject,
                           nto.id_nurse_tea_opt data,
                           pk_translation.get_translation(i_lang, nto.code_nurse_tea_opt) label,
                           nvl(ntoi.rank, 0) rank
                      FROM nurse_tea_opt nto
                      JOIN nurse_tea_opt_inst ntoi
                        ON ntoi.id_nurse_tea_opt = nto.id_nurse_tea_opt
                     WHERE nto.subject = l_given_to
                       AND nvl(ntoi.id_institution, 0) IN (0, i_prof.institution)
                       AND nvl(ntoi.id_clinical_service, 0) IN
                           (SELECT column_value
                              FROM TABLE(l_clinical_service))
                    UNION ALL
                    SELECT l_given_to, -1, l_free_text, NULL rank
                      FROM dual)
             ORDER BY rank NULLS LAST, subject, label;
    
        OPEN o_understanding FOR
            SELECT subject, data, label
              FROM (SELECT nto.subject,
                           nto.id_nurse_tea_opt data,
                           pk_translation.get_translation(i_lang, nto.code_nurse_tea_opt) label,
                           nvl(ntoi.rank, 0) rank
                      FROM nurse_tea_opt nto
                      JOIN nurse_tea_opt_inst ntoi
                        ON ntoi.id_nurse_tea_opt = nto.id_nurse_tea_opt
                     WHERE nto.subject = l_level
                       AND nvl(ntoi.id_institution, 0) IN (0, i_prof.institution)
                       AND nvl(ntoi.id_clinical_service, 0) IN
                           (SELECT column_value
                              FROM TABLE(l_clinical_service))
                    UNION ALL
                    SELECT l_level, -1, l_free_text, NULL rank
                      FROM dual)
             ORDER BY rank NULLS LAST, subject, label;
    
        OPEN o_info FOR
            SELECT ntr.description description,
                   pk_date_utils.get_timestamp_str(i_lang,
                                                   i_prof,
                                                   (SELECT ntd.dt_start
                                                      FROM nurse_tea_det ntd
                                                     WHERE ntd.flg_status =
                                                           pk_patient_education_constant.g_nurse_tea_det_pend
                                                       AND ntd.id_nurse_tea_req = ntr.id_nurse_tea_req
                                                       AND ntd.num_order =
                                                           (SELECT MIN(ntd.num_order)
                                                              FROM nurse_tea_det ntd
                                                             WHERE ntd.flg_status =
                                                                   pk_patient_education_constant.g_nurse_tea_det_pend
                                                               AND ntd.id_nurse_tea_req = ntr.id_nurse_tea_req)),
                                                   NULL) dt_begin,
                   pk_date_utils.get_timestamp_str(i_lang, i_prof, e.dt_creation, NULL) dt_creation_epis,
                   CASE
                        WHEN l_nurse_tea_opt_desc IS NOT NULL THEN
                         l_nurse_tea_opt_desc
                        ELSE
                         NULL
                    END add_resources,
                   CASE
                        WHEN l_nurse_tea_opt_id IS NOT NULL THEN
                         l_nurse_tea_opt_id
                        ELSE
                         NULL
                    END add_resources_id
              FROM nurse_tea_req ntr
              JOIN episode e
                ON e.id_episode = ntr.id_episode
             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_cursor_if_closed(o_goals);
            pk_types.open_cursor_if_closed(o_methods);
            pk_types.open_cursor_if_closed(o_given_to);
            pk_types.open_cursor_if_closed(o_deliverables);
            pk_types.open_cursor_if_closed(o_understanding);
            pk_types.open_cursor_if_closed(o_info);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DOCUMENTATION_DET',
                                              o_error);
        
            RETURN FALSE;
    END get_documentation_det;

    FUNCTION get_documentation_goals
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN t_tbl_core_domain IS
    
        l_goals            nurse_tea_opt.subject%TYPE := 'GOALS';
        l_clinical_service table_number;
        l_free_text        sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                   i_prof,
                                                                                   'PATIENT_EDUCATION_M001');
    
        l_ret t_tbl_core_domain;
    
    BEGIN
    
        SELECT id_clinical_service
          BULK COLLECT
          INTO l_clinical_service
          FROM (SELECT d.id_clinical_service
                  FROM prof_dep_clin_serv p
                  JOIN dep_clin_serv d
                    ON d.id_dep_clin_serv = p.id_dep_clin_serv
                 WHERE p.id_professional = i_prof.id
                   AND p.id_institution = i_prof.institution
                   AND p.flg_status = pk_patient_education_constant.g_selected
                   AND d.flg_available = pk_alert_constant.g_yes
                UNION ALL
                SELECT 0
                  FROM dual);
    
        g_error := 'OPEN L_RET';
        SELECT *
          BULK COLLECT
          INTO l_ret
          FROM (SELECT t_row_core_domain(internal_name => NULL,
                                         desc_domain   => label,
                                         domain_value  => data,
                                         order_rank    => rank,
                                         img_name      => NULL)
                  FROM (SELECT data, label, rank
                          FROM (SELECT nto.id_nurse_tea_opt data,
                                       pk_translation.get_translation(i_lang, nto.code_nurse_tea_opt) label,
                                       nvl(ntoi.rank, 0) rank,
                                       row_number() over(PARTITION BY nto.id_nurse_tea_opt ORDER BY ntoi.id_institution DESC) AS rn
                                  FROM nurse_tea_opt nto
                                  JOIN nurse_tea_opt_inst ntoi
                                    ON ntoi.id_nurse_tea_opt = nto.id_nurse_tea_opt
                                 WHERE nto.subject = l_goals
                                   AND nvl(ntoi.id_institution, 0) IN (0, i_prof.institution)
                                   AND nvl(ntoi.id_clinical_service, 0) IN
                                       (SELECT column_value
                                          FROM TABLE(l_clinical_service))
                                UNION ALL
                                SELECT -1, l_free_text, NULL rank, 1 rn
                                  FROM dual)
                         WHERE rn = 1
                         ORDER BY rank NULLS LAST, label));
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DOCUMENTATION_GOALS',
                                              o_error);
            RETURN t_tbl_core_domain();
    END get_documentation_goals;

    FUNCTION get_documentation_methods
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN t_tbl_core_domain IS
    
        l_method           nurse_tea_opt.subject%TYPE := 'METHOD';
        l_clinical_service table_number;
        l_free_text        sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                   i_prof,
                                                                                   'PATIENT_EDUCATION_M001');
    
        l_ret t_tbl_core_domain;
    
    BEGIN
    
        SELECT id_clinical_service
          BULK COLLECT
          INTO l_clinical_service
          FROM (SELECT d.id_clinical_service
                  FROM prof_dep_clin_serv p
                  JOIN dep_clin_serv d
                    ON d.id_dep_clin_serv = p.id_dep_clin_serv
                 WHERE p.id_professional = i_prof.id
                   AND p.id_institution = i_prof.institution
                   AND p.flg_status = pk_patient_education_constant.g_selected
                   AND d.flg_available = pk_alert_constant.g_yes
                UNION ALL
                SELECT 0
                  FROM dual);
    
        g_error := 'OPEN L_RET';
        SELECT *
          BULK COLLECT
          INTO l_ret
          FROM (SELECT t_row_core_domain(internal_name => NULL,
                                         desc_domain   => label,
                                         domain_value  => data,
                                         order_rank    => rank,
                                         img_name      => NULL)
                  FROM (SELECT nto.id_nurse_tea_opt data,
                               pk_translation.get_translation(i_lang, nto.code_nurse_tea_opt) label,
                               nvl(ntoi.rank, 0) rank,
                               row_number() over(PARTITION BY nto.id_nurse_tea_opt ORDER BY ntoi.id_institution DESC) AS rn
                          FROM nurse_tea_opt nto
                          JOIN nurse_tea_opt_inst ntoi
                            ON ntoi.id_nurse_tea_opt = nto.id_nurse_tea_opt
                         WHERE nto.subject = l_method
                           AND nvl(ntoi.id_institution, 0) IN (0, i_prof.institution)
                           AND nvl(ntoi.id_clinical_service, 0) IN
                               (SELECT column_value
                                  FROM TABLE(l_clinical_service))
                        UNION ALL
                        SELECT -1, l_free_text, NULL rank, 1 rn
                          FROM dual)
                 WHERE rn = 1
                 ORDER BY rank NULLS LAST, label);
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DOCUMENTATION_METHODS',
                                              o_error);
            RETURN t_tbl_core_domain();
    END get_documentation_methods;

    FUNCTION get_documentation_given_to
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN t_tbl_core_domain IS
    
        l_given_to         nurse_tea_opt.subject%TYPE := 'GIVEN_TO';
        l_clinical_service table_number;
        l_free_text        sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                   i_prof,
                                                                                   'PATIENT_EDUCATION_M001');
    
        l_ret t_tbl_core_domain;
    
    BEGIN
    
        SELECT id_clinical_service
          BULK COLLECT
          INTO l_clinical_service
          FROM (SELECT d.id_clinical_service
                  FROM prof_dep_clin_serv p
                  JOIN dep_clin_serv d
                    ON d.id_dep_clin_serv = p.id_dep_clin_serv
                 WHERE p.id_professional = i_prof.id
                   AND p.id_institution = i_prof.institution
                   AND p.flg_status = pk_patient_education_constant.g_selected
                   AND d.flg_available = pk_alert_constant.g_yes
                UNION ALL
                SELECT 0
                  FROM dual);
    
        g_error := 'OPEN L_RET';
        SELECT *
          BULK COLLECT
          INTO l_ret
          FROM (SELECT t_row_core_domain(internal_name => NULL,
                                         desc_domain   => label,
                                         domain_value  => data,
                                         order_rank    => rank,
                                         img_name      => NULL)
                  FROM (SELECT data, label, rank
                          FROM (SELECT nto.id_nurse_tea_opt data,
                                       pk_translation.get_translation(i_lang, nto.code_nurse_tea_opt) label,
                                       nvl(ntoi.rank, 0) rank,
                                       row_number() over(PARTITION BY nto.id_nurse_tea_opt ORDER BY ntoi.id_institution DESC) AS rn
                                  FROM nurse_tea_opt nto
                                  JOIN nurse_tea_opt_inst ntoi
                                    ON ntoi.id_nurse_tea_opt = nto.id_nurse_tea_opt
                                 WHERE nto.subject = l_given_to
                                   AND nvl(ntoi.id_institution, 0) IN (0, i_prof.institution)
                                   AND nvl(ntoi.id_clinical_service, 0) IN
                                       (SELECT column_value
                                          FROM TABLE(l_clinical_service))
                                UNION ALL
                                SELECT -1, l_free_text, NULL rank, 1 rn
                                  FROM dual)
                         WHERE rn = 1
                         ORDER BY rank NULLS LAST, label));
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DOCUMENTATION_GIVEN_TO',
                                              o_error);
            RETURN t_tbl_core_domain();
    END get_documentation_given_to;

    FUNCTION get_documentation_addit_res
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN t_tbl_core_domain IS
    
        l_deliverables     nurse_tea_opt.subject%TYPE := 'DELIVERABLES';
        l_clinical_service table_number;
        l_free_text        sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                   i_prof,
                                                                                   'PATIENT_EDUCATION_M001');
    
        l_ret t_tbl_core_domain;
    
    BEGIN
    
        SELECT id_clinical_service
          BULK COLLECT
          INTO l_clinical_service
          FROM (SELECT d.id_clinical_service
                  FROM prof_dep_clin_serv p
                  JOIN dep_clin_serv d
                    ON d.id_dep_clin_serv = p.id_dep_clin_serv
                 WHERE p.id_professional = i_prof.id
                   AND p.id_institution = i_prof.institution
                   AND p.flg_status = pk_patient_education_constant.g_selected
                   AND d.flg_available = pk_alert_constant.g_yes
                UNION ALL
                SELECT 0
                  FROM dual);
    
        g_error := 'OPEN L_RET';
        SELECT *
          BULK COLLECT
          INTO l_ret
          FROM (SELECT t_row_core_domain(internal_name => NULL,
                                         desc_domain   => label,
                                         domain_value  => data,
                                         order_rank    => rank,
                                         img_name      => NULL)
                  FROM (SELECT data, label, rank
                          FROM (SELECT nto.id_nurse_tea_opt data,
                                       pk_translation.get_translation(i_lang, nto.code_nurse_tea_opt) label,
                                       nvl(ntoi.rank, 0) rank,
                                       row_number() over(PARTITION BY nto.id_nurse_tea_opt ORDER BY ntoi.id_institution DESC) AS rn
                                  FROM nurse_tea_opt nto
                                  JOIN nurse_tea_opt_inst ntoi
                                    ON ntoi.id_nurse_tea_opt = nto.id_nurse_tea_opt
                                 WHERE nto.subject = l_deliverables
                                   AND nvl(ntoi.id_institution, 0) IN (0, i_prof.institution)
                                   AND nvl(ntoi.id_clinical_service, 0) IN
                                       (SELECT column_value
                                          FROM TABLE(l_clinical_service))
                                UNION ALL
                                SELECT -1, l_free_text, NULL rank, 1 rn
                                  FROM dual)
                         WHERE rn = 1
                         ORDER BY rank NULLS LAST, label));
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DOCUMENTATION_ADDIT_RES',
                                              o_error);
            RETURN t_tbl_core_domain();
    END get_documentation_addit_res;

    FUNCTION get_doc_level_understanding
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN t_tbl_core_domain IS
    
        l_level            nurse_tea_opt.subject%TYPE := 'LEVEL_OF_UNDERSTANDING';
        l_clinical_service table_number;
        l_free_text        sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                   i_prof,
                                                                                   'PATIENT_EDUCATION_M001');
    
        l_ret t_tbl_core_domain;
    
    BEGIN
    
        SELECT id_clinical_service
          BULK COLLECT
          INTO l_clinical_service
          FROM (SELECT d.id_clinical_service
                  FROM prof_dep_clin_serv p
                  JOIN dep_clin_serv d
                    ON d.id_dep_clin_serv = p.id_dep_clin_serv
                 WHERE p.id_professional = i_prof.id
                   AND p.id_institution = i_prof.institution
                   AND p.flg_status = pk_patient_education_constant.g_selected
                   AND d.flg_available = pk_alert_constant.g_yes
                UNION ALL
                SELECT 0
                  FROM dual);
    
        g_error := 'OPEN L_RET';
        SELECT *
          BULK COLLECT
          INTO l_ret
          FROM (SELECT t_row_core_domain(internal_name => NULL,
                                         desc_domain   => label,
                                         domain_value  => data,
                                         order_rank    => rank,
                                         img_name      => NULL)
                  FROM (SELECT data, label, rank
                          FROM (SELECT nto.id_nurse_tea_opt data,
                                       pk_translation.get_translation(i_lang, nto.code_nurse_tea_opt) label,
                                       nvl(ntoi.rank, 0) rank,
                                       row_number() over(PARTITION BY nto.id_nurse_tea_opt ORDER BY ntoi.id_institution DESC) AS rn
                                  FROM nurse_tea_opt nto
                                  JOIN nurse_tea_opt_inst ntoi
                                    ON ntoi.id_nurse_tea_opt = nto.id_nurse_tea_opt
                                 WHERE nto.subject = l_level
                                   AND nvl(ntoi.id_institution, 0) IN (0, i_prof.institution)
                                   AND nvl(ntoi.id_clinical_service, 0) IN
                                       (SELECT column_value
                                          FROM TABLE(l_clinical_service))
                                UNION ALL
                                SELECT -1, l_free_text, NULL rank, 1 rn
                                  FROM dual)
                         WHERE rn = 1
                         ORDER BY rank NULLS LAST, label));
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DOCUMENTATION_ADDIT_RES',
                                              o_error);
            RETURN t_tbl_core_domain();
    END get_doc_level_understanding;
    --
    FUNCTION set_documentation_exec
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_nurse_tea_req   IN nurse_tea_det.id_nurse_tea_req%TYPE,
        i_subject            IN table_varchar,
        i_id_nurse_tea_opt   IN table_number,
        i_free_text          IN table_clob,
        i_dt_start           IN VARCHAR2,
        i_dt_end             IN VARCHAR2,
        i_duration           IN NUMBER,
        i_unit_meas_duration IN NUMBER,
        i_description        IN VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_dt_start          TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_dt_end            TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_nurse_tea_det_opt nurse_tea_det_opt.id_nurse_tea_det_opt%TYPE;
        l_id_nurse_tea_det  nurse_tea_det.id_nurse_tea_det%TYPE;
        l_flg_status        nurse_tea_req.flg_status%TYPE;
        l_episode           nurse_tea_req.id_episode%TYPE;
        l_rows_ntdo         table_varchar := table_varchar();
        l_rows              table_varchar := table_varchar();
        l_exist             BOOLEAN := TRUE;
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        l_dt_start := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_start, NULL);
        l_dt_end   := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_end, NULL);
    
        BEGIN
            SELECT t.id_nurse_tea_det, t.ntr_flg_status, t.id_episode
              INTO l_id_nurse_tea_det, l_flg_status, l_episode
              FROM (SELECT ntd.id_nurse_tea_det,
                           ntr.flg_status ntr_flg_status,
                           ntd.dt_start,
                           ntd.dt_end,
                           ntr.id_episode,
                           rank() over(ORDER BY ntd.num_order) rn
                      FROM nurse_tea_req ntr
                     INNER JOIN nurse_tea_det ntd
                        ON ntr.id_nurse_tea_req = ntd.id_nurse_tea_req
                     WHERE ntd.id_nurse_tea_req = i_id_nurse_tea_req
                       AND ntd.flg_status = pk_patient_education_constant.g_nurse_tea_det_pend) t
             WHERE t.rn = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_exist := FALSE;
        END;
    
        -- Check if this is a execution of the task after it expires through CPOE.
        -- If it is, we can not change the status of the request, keeping as expired.
        IF l_flg_status != pk_patient_education_constant.g_nurse_tea_req_expired
        THEN
        
            IF NOT set_nurse_tea_req_status(i_lang          => i_lang,
                                            i_nurse_tea_req => i_id_nurse_tea_req,
                                            i_prof          => i_prof,
                                            i_prof_cat_type => pk_prof_utils.get_category(i_lang, i_prof),
                                            o_error         => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        IF l_exist
        THEN
            g_error := 'Update execution details';
            ts_nurse_tea_det.upd(id_nurse_tea_det_in      => l_id_nurse_tea_det,
                                 id_prof_provider_in      => i_prof.id,
                                 dt_start_in              => l_dt_start,
                                 dt_end_in                => CASE
                                                                 WHEN l_dt_end IS NOT NULL THEN
                                                                  l_dt_end
                                                                 ELSE
                                                                  current_timestamp
                                                             END,
                                 duration_in              => i_duration,
                                 id_unit_meas_duration_in => i_unit_meas_duration,
                                 dt_nurse_tea_det_tstz_in => g_sysdate_tstz,
                                 flg_status_in            => pk_patient_education_constant.g_nurse_tea_det_exec,
                                 description_in           => i_description,
                                 rows_out                 => l_rows);
        
            g_error := 'Process insert';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'NURSE_TEA_DET',
                                          i_rowids     => l_rows,
                                          o_error      => o_error);
        
            g_error := 'INSERT LOG ON TI_LOG';
            IF NOT t_ti_log.ins_log(i_lang,
                                    i_prof,
                                    l_episode,
                                    pk_patient_education_constant.g_nurse_tea_det_exec,
                                    l_id_nurse_tea_det,
                                    'NT',
                                    o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            IF i_id_nurse_tea_opt.count > 0
            THEN
                l_rows := table_varchar();
            
                g_error := 'Insert execution details options';
                FOR i IN 1 .. i_id_nurse_tea_opt.count
                LOOP
                    l_nurse_tea_det_opt := ts_nurse_tea_det_opt.next_key;
                
                    ts_nurse_tea_det_opt.ins(id_nurse_tea_det_opt_in => l_nurse_tea_det_opt,
                                             id_nurse_tea_det_in     => l_id_nurse_tea_det,
                                             id_nurse_tea_opt_in     => i_id_nurse_tea_opt(i),
                                             subject_in              => i_subject(i),
                                             notes_in                => i_free_text(i),
                                             dt_nurse_tea_det_opt_in => g_sysdate_tstz,
                                             rows_out                => l_rows_ntdo);
                
                    l_rows := l_rows MULTISET UNION l_rows_ntdo;
                END LOOP;
            
                g_error := 'Process insert';
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'NURSE_TEA_DET_OPT',
                                              i_rowids     => l_rows,
                                              o_error      => o_error);
            
            END IF;
        
            -- Check if this is a execution of the task after it expires through CPOE.
            -- If it is, we can not change the status of the request, keeping as expired.
            IF l_flg_status != pk_patient_education_constant.g_nurse_tea_req_expired
            THEN
                IF NOT set_nurse_tea_req_status(i_lang          => i_lang,
                                                i_nurse_tea_req => i_id_nurse_tea_req,
                                                i_prof          => i_prof,
                                                i_prof_cat_type => pk_prof_utils.get_category(i_lang, i_prof),
                                                o_error         => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            END IF;
        
        END IF;
    
        COMMIT;
    
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
                                              'SET_DOCUMENTATION_EXEC',
                                              o_error);
        
            RETURN FALSE;
    END set_documentation_exec;

    FUNCTION set_documentation_exec
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_nurse_tea_req     IN table_number,
        i_tbl_ds_internal_name IN table_varchar DEFAULT NULL,
        i_tbl_real_val         IN table_table_varchar DEFAULT NULL,
        i_tbl_val_clob         IN table_table_clob DEFAULT NULL,
        i_unit_meas_duration   IN table_number DEFAULT NULL,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_dt_start          TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_dt_end            TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_nurse_tea_det_opt nurse_tea_det_opt.id_nurse_tea_det_opt%TYPE;
        l_id_nurse_tea_det  nurse_tea_det.id_nurse_tea_det%TYPE;
        l_flg_status        nurse_tea_req.flg_status%TYPE;
        l_episode           nurse_tea_req.id_episode%TYPE;
        l_rows_ntdo         table_varchar := table_varchar();
        l_rows              table_varchar := table_varchar();
        l_exist             BOOLEAN := TRUE;
    
        l_subject          table_table_varchar := table_table_varchar();
        l_id_nurse_tea_opt table_table_number := table_table_number();
        l_free_text        table_table_clob := table_table_clob();
    
        l_tbl_dt_start table_varchar := table_varchar();
        l_tbl_dt_end   table_varchar := table_varchar();
        l_tbl_duration table_number := table_number();
    
        l_tbl_description table_clob := table_clob();
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        FOR i IN i_id_nurse_tea_req.first .. i_id_nurse_tea_req.last
        LOOP
            l_subject.extend();
            l_subject(i) := table_varchar();
        
            l_id_nurse_tea_opt.extend();
            l_id_nurse_tea_opt(i) := table_number();
        
            l_free_text.extend();
            l_free_text(i) := table_clob();
        
            FOR j IN i_tbl_ds_internal_name.first .. i_tbl_ds_internal_name.last
            LOOP
                IF i_tbl_ds_internal_name(j) = pk_orders_constant.g_ds_health_education_goals
                THEN
                    l_subject(i).extend();
                    l_subject(i)(l_subject(i).count) := 'GOALS';
                
                    l_id_nurse_tea_opt(i).extend();
                    l_id_nurse_tea_opt(i)(l_id_nurse_tea_opt(i).count) := i_tbl_real_val(j) (i);
                
                ELSIF i_tbl_ds_internal_name(j) = pk_orders_constant.g_ds_health_education_method
                THEN
                    l_subject(i).extend();
                    l_subject(i)(l_subject(i).count) := 'METHOD';
                
                    l_id_nurse_tea_opt(i).extend();
                    l_id_nurse_tea_opt(i)(l_id_nurse_tea_opt(i).count) := i_tbl_real_val(j) (i);
                
                ELSIF i_tbl_ds_internal_name(j) = pk_orders_constant.g_ds_health_educ_given_to
                THEN
                    l_subject(i).extend();
                    l_subject(i)(l_subject(i).count) := 'GIVEN_TO';
                
                    l_id_nurse_tea_opt(i).extend();
                    l_id_nurse_tea_opt(i)(l_id_nurse_tea_opt(i).count) := i_tbl_real_val(j) (i);
                
                ELSIF i_tbl_ds_internal_name(j) = pk_orders_constant.g_ds_health_educ_addit_res
                THEN
                    l_subject(i).extend();
                    l_subject(i)(l_subject(i).count) := 'DELIVERABLES';
                
                    l_id_nurse_tea_opt(i).extend();
                    l_id_nurse_tea_opt(i)(l_id_nurse_tea_opt(i).count) := i_tbl_real_val(j) (i);
                
                ELSIF i_tbl_ds_internal_name(j) = pk_orders_constant.g_ds_health_educ_level_und
                THEN
                    l_subject(i).extend();
                    l_subject(i)(l_subject(i).count) := 'LEVEL_OF_UNDERSTANDING';
                
                    l_id_nurse_tea_opt(i).extend();
                    l_id_nurse_tea_opt(i)(l_id_nurse_tea_opt(i).count) := i_tbl_real_val(j) (i);
                
                ELSIF i_tbl_ds_internal_name(j) IN
                      (pk_orders_constant.g_ds_health_education_goals_ft,
                       pk_orders_constant.g_ds_health_educ_method_ft,
                       pk_orders_constant.g_ds_health_educ_given_to_ft,
                       pk_orders_constant.g_ds_health_educ_addit_res_ft,
                       pk_orders_constant.g_ds_health_educ_level_und_ft)
                THEN
                    l_free_text(i).extend();
                    l_free_text(i)(l_free_text(i).count) := i_tbl_val_clob(j) (i);
                
                ELSIF i_tbl_ds_internal_name(j) = pk_orders_constant.g_ds_start_date
                THEN
                    l_tbl_dt_start.extend();
                    l_tbl_dt_start(l_tbl_dt_start.count) := i_tbl_real_val(j) (i);
                ELSIF i_tbl_ds_internal_name(j) = pk_orders_constant.g_ds_end_date
                THEN
                    l_tbl_dt_end.extend();
                    l_tbl_dt_end(l_tbl_dt_end.count) := i_tbl_real_val(j) (i);
                ELSIF i_tbl_ds_internal_name(j) = pk_orders_constant.g_ds_duration
                THEN
                    l_tbl_duration.extend();
                    l_tbl_duration(l_tbl_duration.count) := i_tbl_real_val(j) (i);
                ELSIF i_tbl_ds_internal_name(j) = pk_orders_constant.g_ds_description
                THEN
                    l_tbl_description.extend();
                    l_tbl_description(l_tbl_description.count) := i_tbl_val_clob(j) (i);
                END IF;
            END LOOP;
        END LOOP;
    
        FOR i IN i_id_nurse_tea_req.first .. i_id_nurse_tea_req.last
        LOOP
        
            l_dt_start := pk_date_utils.get_string_tstz(i_lang, i_prof, l_tbl_dt_start(i), NULL);
            l_dt_end   := pk_date_utils.get_string_tstz(i_lang, i_prof, l_tbl_dt_end(i), NULL);
        
            BEGIN
                SELECT t.id_nurse_tea_det, t.ntr_flg_status, t.id_episode
                  INTO l_id_nurse_tea_det, l_flg_status, l_episode
                  FROM (SELECT ntd.id_nurse_tea_det,
                               ntr.flg_status ntr_flg_status,
                               ntd.dt_start,
                               ntd.dt_end,
                               ntr.id_episode,
                               rank() over(ORDER BY ntd.num_order) rn
                          FROM nurse_tea_req ntr
                         INNER JOIN nurse_tea_det ntd
                            ON ntr.id_nurse_tea_req = ntd.id_nurse_tea_req
                         WHERE ntd.id_nurse_tea_req = i_id_nurse_tea_req(i)
                           AND ntd.flg_status = pk_patient_education_constant.g_nurse_tea_det_pend) t
                 WHERE t.rn = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    l_exist := FALSE;
            END;
        
            -- check if this is a execution of the task after it expires through cpoe.
            -- if it is, we can not change the status of the request, keeping as expired.
            IF l_flg_status != pk_patient_education_constant.g_nurse_tea_req_expired
            THEN
            
                IF NOT set_nurse_tea_req_status(i_lang          => i_lang,
                                                i_nurse_tea_req => i_id_nurse_tea_req(i),
                                                i_prof          => i_prof,
                                                i_prof_cat_type => pk_prof_utils.get_category(i_lang, i_prof),
                                                o_error         => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            END IF;
        
            IF l_exist
            THEN
                g_error := 'Update execution details';
                ts_nurse_tea_det.upd(id_nurse_tea_det_in      => l_id_nurse_tea_det,
                                     id_prof_provider_in      => i_prof.id,
                                     dt_start_in              => l_dt_start,
                                     dt_end_in                => CASE
                                                                     WHEN l_dt_end IS NOT NULL THEN
                                                                      l_dt_end
                                                                     ELSE
                                                                      current_timestamp
                                                                 END,
                                     duration_in              => l_tbl_duration(i),
                                     id_unit_meas_duration_in => i_unit_meas_duration(i),
                                     dt_nurse_tea_det_tstz_in => g_sysdate_tstz,
                                     flg_status_in            => pk_patient_education_constant.g_nurse_tea_det_exec,
                                     description_in           => l_tbl_description(i),
                                     rows_out                 => l_rows);
            
                g_error := 'Process insert';
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'NURSE_TEA_DET',
                                              i_rowids     => l_rows,
                                              o_error      => o_error);
            
                g_error := 'INSERT LOG ON TI_LOG';
                IF NOT t_ti_log.ins_log(i_lang,
                                        i_prof,
                                        l_episode,
                                        pk_patient_education_constant.g_nurse_tea_det_exec,
                                        l_id_nurse_tea_det,
                                        'NT',
                                        o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
                IF l_id_nurse_tea_opt(i).count > 0
                THEN
                    l_rows := table_varchar();
                
                    g_error := 'Insert execution details options';
                    FOR j IN l_id_nurse_tea_opt(i).first .. l_id_nurse_tea_opt(i).last
                    LOOP
                        l_nurse_tea_det_opt := ts_nurse_tea_det_opt.next_key;
                    
                        ts_nurse_tea_det_opt.ins(id_nurse_tea_det_opt_in => l_nurse_tea_det_opt,
                                                 id_nurse_tea_det_in     => l_id_nurse_tea_det,
                                                 id_nurse_tea_opt_in     => CASE
                                                                                WHEN l_id_nurse_tea_opt(i) (j) = '-1' THEN
                                                                                 NULL
                                                                                ELSE
                                                                                 l_id_nurse_tea_opt(i) (j)
                                                                            END,
                                                 subject_in              => l_subject(i) (j),
                                                 notes_in                => l_free_text(i) (j),
                                                 dt_nurse_tea_det_opt_in => g_sysdate_tstz,
                                                 rows_out                => l_rows_ntdo);
                    
                        l_rows := l_rows MULTISET UNION l_rows_ntdo;
                    END LOOP;
                
                    g_error := 'Process insert';
                    t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'NURSE_TEA_DET_OPT',
                                                  i_rowids     => l_rows,
                                                  o_error      => o_error);
                
                END IF;
            
                -- check if this is a execution of the task after it expires through cpoe.
                -- if it is, we can not change the status of the request, keeping as expired.
                IF l_flg_status != pk_patient_education_constant.g_nurse_tea_req_expired
                THEN
                    IF NOT set_nurse_tea_req_status(i_lang          => i_lang,
                                                    i_nurse_tea_req => i_id_nurse_tea_req(i),
                                                    i_prof          => i_prof,
                                                    i_prof_cat_type => pk_prof_utils.get_category(i_lang, i_prof),
                                                    o_error         => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                END IF;
            
            END IF;
        END LOOP;
    
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
                                              'SET_DOCUMENTATION_EXEC',
                                              o_error);
        
            RETURN FALSE;
    END set_documentation_exec;

    FUNCTION set_order_for_execution
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN episode.id_episode%TYPE,
        i_id_nurse_tea_topic   IN table_number,
        i_tbl_ds_internal_name IN table_varchar DEFAULT NULL,
        i_tbl_real_val         IN table_table_varchar DEFAULT NULL,
        i_tbl_val_clob         IN table_table_clob DEFAULT NULL,
        i_unit_meas_duration   IN table_number DEFAULT NULL,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_dt_start          TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_dt_end            TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_nurse_tea_det_opt nurse_tea_det_opt.id_nurse_tea_det_opt%TYPE;
        l_id_nurse_tea_det  nurse_tea_det.id_nurse_tea_det%TYPE;
        l_flg_status        nurse_tea_req.flg_status%TYPE;
        l_episode           nurse_tea_req.id_episode%TYPE;
        l_rows_ntdo         table_varchar := table_varchar();
        l_rows              table_varchar := table_varchar();
        l_exist             BOOLEAN := TRUE;
    
        l_subject          table_table_varchar := table_table_varchar();
        l_id_nurse_tea_opt table_table_number := table_table_number();
        l_free_text        table_table_clob := table_table_clob();
    
        l_tbl_dt_start table_varchar := table_varchar();
        l_tbl_dt_end   table_varchar := table_varchar();
        l_tbl_duration table_number := table_number();
    
        l_tbl_description table_clob := table_clob();
    
        l_tbl_id_nurse_teq_req table_number := table_number();
    
        l_tbl_compositions          table_table_number := table_table_number();
        l_tbl_id_nurse_tea_req_sugg table_number := table_number();
        l_tbl_desc_topic_aux        table_varchar := table_varchar();
        l_tbl_not_order_reason      table_number := table_number();
        l_tbl_diagnoses             table_clob := table_clob();
        l_tbl_notes                 table_varchar := table_varchar();
    
        l_value_to_be_executed      VARCHAR2(4000);
        l_value_to_be_executed_desc VARCHAR2(4000);
        l_tbl_values_to_be_executed table_varchar := table_varchar();
    
        --RECURRENCE
        l_order_recurr_desc          VARCHAR2(4000);
        l_order_recurr_option        order_recurr_plan.id_order_recurr_option%TYPE;
        l_start_date                 order_recurr_plan.start_date%TYPE;
        l_occurrences                order_recurr_plan.occurrences%TYPE;
        l_duration                   order_recurr_plan.duration%TYPE;
        l_unit_meas_duration         order_recurr_plan.id_unit_meas_duration%TYPE;
        l_end_date                   order_recurr_plan.end_date%TYPE;
        l_flg_end_by_editable        VARCHAR2(1);
        l_order_recurr_plan          order_recurr_plan.id_order_recurr_plan%TYPE;
        l_order_recurr_plan_original order_recurr_plan.id_order_recurr_plan%TYPE;
        l_tbl_order_recurr_plan      table_number := table_number();
    
        o_id_nurse_tea_topic table_number := table_number();
        o_title_topic        table_varchar := table_varchar();
        o_desc_diagnosis     table_varchar := table_varchar();
    BEGIN
    
        FOR i IN i_id_nurse_tea_topic.first .. i_id_nurse_tea_topic.last
        LOOP
            l_subject.extend();
            l_subject(i) := table_varchar();
        
            l_id_nurse_tea_opt.extend();
            l_id_nurse_tea_opt(i) := table_number();
        
            l_free_text.extend();
            l_free_text(i) := table_clob();
        
            FOR j IN i_tbl_ds_internal_name.first .. i_tbl_ds_internal_name.last
            LOOP
                IF i_tbl_ds_internal_name(j) = pk_orders_constant.g_ds_health_education_goals
                THEN
                    l_subject(i).extend();
                    l_subject(i)(l_subject(i).count) := 'GOALS';
                
                    l_id_nurse_tea_opt(i).extend();
                    l_id_nurse_tea_opt(i)(l_id_nurse_tea_opt(i).count) := i_tbl_real_val(j) (i);
                ELSIF i_tbl_ds_internal_name(j) = pk_orders_constant.g_ds_health_education_method
                THEN
                    l_subject(i).extend();
                    l_subject(i)(l_subject(i).count) := 'METHOD';
                
                    l_id_nurse_tea_opt(i).extend();
                    l_id_nurse_tea_opt(i)(l_id_nurse_tea_opt(i).count) := i_tbl_real_val(j) (i);
                ELSIF i_tbl_ds_internal_name(j) = pk_orders_constant.g_ds_health_educ_given_to
                THEN
                    l_subject(i).extend();
                    l_subject(i)(l_subject(i).count) := 'GIVEN_TO';
                
                    l_id_nurse_tea_opt(i).extend();
                    l_id_nurse_tea_opt(i)(l_id_nurse_tea_opt(i).count) := i_tbl_real_val(j) (i);
                
                ELSIF i_tbl_ds_internal_name(j) = pk_orders_constant.g_ds_health_educ_addit_res
                THEN
                    l_subject(i).extend();
                    l_subject(i)(l_subject(i).count) := 'DELIVERABLES';
                
                    l_id_nurse_tea_opt(i).extend();
                    l_id_nurse_tea_opt(i)(l_id_nurse_tea_opt(i).count) := i_tbl_real_val(j) (i);
                ELSIF i_tbl_ds_internal_name(j) = pk_orders_constant.g_ds_health_educ_level_und
                THEN
                    l_subject(i).extend();
                    l_subject(i)(l_subject(i).count) := 'LEVEL_OF_UNDERSTANDING';
                
                    l_id_nurse_tea_opt(i).extend();
                    l_id_nurse_tea_opt(i)(l_id_nurse_tea_opt(i).count) := i_tbl_real_val(j) (i);
                ELSIF i_tbl_ds_internal_name(j) IN
                      (pk_orders_constant.g_ds_health_education_goals_ft,
                       pk_orders_constant.g_ds_health_educ_method_ft,
                       pk_orders_constant.g_ds_health_educ_given_to_ft,
                       pk_orders_constant.g_ds_health_educ_addit_res_ft,
                       pk_orders_constant.g_ds_health_educ_level_und_ft)
                THEN
                    l_free_text(i).extend();
                    l_free_text(i)(l_free_text(i).count) := i_tbl_val_clob(j) (i);
                
                ELSIF i_tbl_ds_internal_name(j) = pk_orders_constant.g_ds_start_date
                THEN
                    l_tbl_dt_start.extend();
                    l_tbl_dt_start(l_tbl_dt_start.count) := i_tbl_real_val(j) (i);
                ELSIF i_tbl_ds_internal_name(j) = pk_orders_constant.g_ds_end_date
                THEN
                    l_tbl_dt_end.extend();
                    l_tbl_dt_end(l_tbl_dt_end.count) := i_tbl_real_val(j) (i);
                ELSIF i_tbl_ds_internal_name(j) = pk_orders_constant.g_ds_duration
                THEN
                    l_tbl_duration.extend();
                    l_tbl_duration(l_tbl_duration.count) := i_tbl_real_val(j) (i);
                ELSIF i_tbl_ds_internal_name(j) = pk_orders_constant.g_ds_description
                THEN
                    l_tbl_description.extend();
                    l_tbl_description(l_tbl_description.count) := i_tbl_val_clob(j) (i);
                END IF;
            END LOOP;
        END LOOP;
    
        IF NOT get_default_domain_time(i_lang     => i_lang,
                                       i_prof     => i_prof,
                                       o_val      => l_value_to_be_executed,
                                       o_desc_val => l_value_to_be_executed_desc,
                                       o_error    => o_error)
        THEN
            g_error := 'error found while calling get_default_domain_time function';
            RAISE g_exception;
        END IF;
    
        FOR i IN i_id_nurse_tea_topic.first .. i_id_nurse_tea_topic.last
        LOOP
            IF i = 1
            THEN
                IF NOT pk_order_recurrence_core.create_order_recurr_plan(i_lang                => i_lang,
                                                                         i_prof                => i_prof,
                                                                         i_order_recurr_area   => 'PATIENT_EDUCATION',
                                                                         o_order_recurr_desc   => l_order_recurr_desc,
                                                                         o_order_recurr_option => l_order_recurr_option,
                                                                         o_start_date          => l_start_date,
                                                                         o_occurrences         => l_occurrences,
                                                                         o_duration            => l_duration,
                                                                         o_unit_meas_duration  => l_unit_meas_duration,
                                                                         o_end_date            => l_end_date,
                                                                         o_flg_end_by_editable => l_flg_end_by_editable,
                                                                         o_order_recurr_plan   => l_order_recurr_plan,
                                                                         o_error               => o_error)
                THEN
                    g_error := 'error found while calling pk_order_recurrence_core.create_order_recurr_plan function';
                    RAISE g_exception;
                END IF;
            
                l_order_recurr_plan_original := l_order_recurr_plan;
            ELSE
                IF NOT pk_order_recurrence_core.copy_order_recurr_plan(i_lang                   => i_lang,
                                                                       i_prof                   => i_prof,
                                                                       i_order_recurr_plan_from => l_order_recurr_plan_original,
                                                                       o_order_recurr_desc      => l_order_recurr_desc,
                                                                       o_order_recurr_option    => l_order_recurr_option,
                                                                       o_start_date             => l_start_date,
                                                                       o_occurrences            => l_occurrences,
                                                                       o_duration               => l_duration,
                                                                       o_unit_meas_duration     => l_unit_meas_duration,
                                                                       o_end_date               => l_end_date,
                                                                       o_flg_end_by_editable    => l_flg_end_by_editable,
                                                                       o_order_recurr_plan      => l_order_recurr_plan,
                                                                       o_error                  => o_error)
                THEN
                    g_error := 'error found while calling pk_order_recurrence_core.copy_order_recurr_plan function';
                    RAISE g_exception;
                END IF;
            END IF;
        
            l_tbl_order_recurr_plan.extend();
            l_tbl_order_recurr_plan(l_tbl_order_recurr_plan.count) := l_order_recurr_plan;
            l_tbl_id_nurse_tea_req_sugg.extend();
            l_tbl_desc_topic_aux.extend();
            l_tbl_not_order_reason.extend();
            l_tbl_notes.extend();
        
            l_tbl_values_to_be_executed.extend();
            l_tbl_values_to_be_executed(l_tbl_values_to_be_executed.count) := l_value_to_be_executed;
        END LOOP;
    
        IF NOT pk_patient_education_core.create_request(i_lang                  => i_lang,
                                                        i_prof                  => i_prof,
                                                        i_id_episode            => i_episode,
                                                        i_topics                => i_id_nurse_tea_topic,
                                                        i_compositions          => l_tbl_compositions,
                                                        i_to_be_performed       => l_tbl_values_to_be_executed,
                                                        i_start_date            => l_tbl_dt_start,
                                                        i_notes                 => l_tbl_notes,
                                                        i_description           => l_tbl_description,
                                                        i_order_recurr          => l_tbl_order_recurr_plan,
                                                        i_draft                 => pk_alert_constant.g_no,
                                                        i_id_nurse_tea_req_sugg => l_tbl_id_nurse_tea_req_sugg,
                                                        i_desc_topic_aux        => l_tbl_desc_topic_aux,
                                                        i_diagnoses             => l_tbl_diagnoses,
                                                        i_not_order_reason      => l_tbl_not_order_reason,
                                                        o_id_nurse_tea_req      => l_tbl_id_nurse_teq_req,
                                                        o_id_nurse_tea_topic    => o_id_nurse_tea_topic,
                                                        o_title_topic           => o_title_topic,
                                                        o_desc_diagnosis        => o_desc_diagnosis,
                                                        o_error                 => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        FOR i IN l_tbl_id_nurse_teq_req.first .. l_tbl_id_nurse_teq_req.last
        LOOP
        
            l_dt_start := pk_date_utils.get_string_tstz(i_lang, i_prof, l_tbl_dt_start(i), NULL);
            l_dt_end   := pk_date_utils.get_string_tstz(i_lang, i_prof, l_tbl_dt_end(i), NULL);
        
            BEGIN
                SELECT t.id_nurse_tea_det, t.ntr_flg_status, t.id_episode
                  INTO l_id_nurse_tea_det, l_flg_status, l_episode
                  FROM (SELECT ntd.id_nurse_tea_det,
                               ntr.flg_status ntr_flg_status,
                               ntd.dt_start,
                               ntd.dt_end,
                               ntr.id_episode,
                               rank() over(ORDER BY ntd.num_order) rn
                          FROM nurse_tea_req ntr
                         INNER JOIN nurse_tea_det ntd
                            ON ntr.id_nurse_tea_req = ntd.id_nurse_tea_req
                         WHERE ntd.id_nurse_tea_req = l_tbl_id_nurse_teq_req(i)
                           AND ntd.flg_status = pk_patient_education_constant.g_nurse_tea_det_pend) t
                 WHERE t.rn = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    l_exist := FALSE;
            END;
        
            -- check if this is a execution of the task after it expires through cpoe.
            -- if it is, we can not change the status of the request, keeping as expired.
            IF l_flg_status != pk_patient_education_constant.g_nurse_tea_req_expired
            THEN
            
                IF NOT set_nurse_tea_req_status(i_lang          => i_lang,
                                                i_nurse_tea_req => l_tbl_id_nurse_teq_req(i),
                                                i_prof          => i_prof,
                                                i_prof_cat_type => pk_prof_utils.get_category(i_lang, i_prof),
                                                o_error         => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            END IF;
        
            IF l_exist
            THEN
                g_error := 'Update execution details';
                ts_nurse_tea_det.upd(id_nurse_tea_det_in      => l_id_nurse_tea_det,
                                     id_prof_provider_in      => i_prof.id,
                                     dt_start_in              => l_dt_start,
                                     dt_end_in                => CASE
                                                                     WHEN l_dt_end IS NOT NULL THEN
                                                                      l_dt_end
                                                                     ELSE
                                                                      current_timestamp
                                                                 END,
                                     duration_in              => l_tbl_duration(i),
                                     id_unit_meas_duration_in => i_unit_meas_duration(i),
                                     dt_nurse_tea_det_tstz_in => g_sysdate_tstz,
                                     flg_status_in            => pk_patient_education_constant.g_nurse_tea_det_exec,
                                     description_in           => l_tbl_description(i),
                                     rows_out                 => l_rows);
            
                g_error := 'Process insert';
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'NURSE_TEA_DET',
                                              i_rowids     => l_rows,
                                              o_error      => o_error);
            
                g_error := 'INSERT LOG ON TI_LOG';
                IF NOT t_ti_log.ins_log(i_lang,
                                        i_prof,
                                        l_episode,
                                        pk_patient_education_constant.g_nurse_tea_det_exec,
                                        l_id_nurse_tea_det,
                                        'NT',
                                        o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
                IF l_id_nurse_tea_opt(i).count > 0
                THEN
                    l_rows := table_varchar();
                
                    g_error := 'Insert execution details options';
                    FOR j IN l_id_nurse_tea_opt(i).first .. l_id_nurse_tea_opt(i).last
                    LOOP
                        l_nurse_tea_det_opt := ts_nurse_tea_det_opt.next_key;
                    
                        ts_nurse_tea_det_opt.ins(id_nurse_tea_det_opt_in => l_nurse_tea_det_opt,
                                                 id_nurse_tea_det_in     => l_id_nurse_tea_det,
                                                 id_nurse_tea_opt_in     => CASE
                                                                                WHEN l_id_nurse_tea_opt(i) (j) = -1 THEN
                                                                                 NULL
                                                                                ELSE
                                                                                 l_id_nurse_tea_opt(i) (j)
                                                                            END,
                                                 subject_in              => l_subject(i) (j),
                                                 notes_in                => l_free_text(i) (j),
                                                 dt_nurse_tea_det_opt_in => g_sysdate_tstz,
                                                 rows_out                => l_rows_ntdo);
                    
                        l_rows := l_rows MULTISET UNION l_rows_ntdo;
                    END LOOP;
                
                    g_error := 'Process insert';
                    t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'NURSE_TEA_DET_OPT',
                                                  i_rowids     => l_rows,
                                                  o_error      => o_error);
                
                END IF;
            
                -- check if this is a execution of the task after it expires through cpoe.
                -- if it is, we can not change the status of the request, keeping as expired.
                IF l_flg_status != pk_patient_education_constant.g_nurse_tea_req_expired
                THEN
                    IF NOT set_nurse_tea_req_status(i_lang          => i_lang,
                                                    i_nurse_tea_req => l_tbl_id_nurse_teq_req(i),
                                                    i_prof          => i_prof,
                                                    i_prof_cat_type => pk_prof_utils.get_category(i_lang, i_prof),
                                                    o_error         => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                END IF;
            
            END IF;
        END LOOP;
    
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
                                              'set_order_for_execution',
                                              o_error);
        
            RETURN FALSE;
    END set_order_for_execution;

    --
    FUNCTION set_ignore_suggestion
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_req IN table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rows_ntr table_varchar := table_varchar();
        l_rows     table_varchar := table_varchar();
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        FOR i IN 1 .. i_id_nurse_tea_req.count
        LOOP
            insert_ntr_hist(i_lang             => i_lang,
                            i_prof             => i_prof,
                            i_id_nurse_tea_req => i_id_nurse_tea_req(i),
                            o_error            => o_error);
        
            ts_nurse_tea_req.upd(id_nurse_tea_req_in      => i_id_nurse_tea_req(i),
                                 id_prof_close_in         => i_prof.id,
                                 flg_status_in            => pk_patient_education_constant.g_nurse_tea_req_ign,
                                 dt_nurse_tea_req_tstz_in => g_sysdate_tstz,
                                 rows_out                 => l_rows_ntr);
        
            l_rows := l_rows MULTISET UNION l_rows_ntr;
        END LOOP;
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'NURSE_TEA_REQ',
                                      i_rowids     => l_rows,
                                      o_error      => o_error);
    
        COMMIT;
    
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
                                              'SET_IGNORE_SUGGESTION',
                                              o_error);
        
            RETURN FALSE;
    END set_ignore_suggestion;

    --
    FUNCTION update_request
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN nurse_tea_req.id_episode%TYPE,
        i_id_nurse_tea_req IN table_number,
        i_topics           IN table_number,
        i_compositions     IN table_table_number,
        i_to_be_performed  IN table_varchar,
        i_start_date       IN table_varchar,
        i_notes            IN table_varchar,
        i_description      IN table_clob,
        i_order_recurr     IN table_number,
        i_upd_flg_status   IN VARCHAR2 DEFAULT 'Y',
        i_diagnoses        IN table_clob DEFAULT NULL,
        i_not_order_reason IN table_number,
        i_flg_origin_req   IN VARCHAR2 DEFAULT 'D',
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_nurse_tea_det IS
            SELECT ntd.id_nurse_tea_det
              FROM nurse_tea_req ntr
              JOIN nurse_tea_det ntd
                ON ntr.id_nurse_tea_req = ntd.id_nurse_tea_req
             WHERE ntr.id_nurse_tea_req IN (SELECT /*+opt_estimate(table t rows=1)*/
                                             *
                                              FROM TABLE(i_id_nurse_tea_req) t)
               AND ntd.flg_status = pk_patient_education_constant.g_nurse_tea_det_pend
             ORDER BY ntd.num_order;
    
        l_nurse_tea_det table_number;
    
        l_category   category.flg_type%TYPE;
        l_start_date TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_rows       table_varchar;
        l_rows_ntr   table_varchar := table_varchar();
        l_rows_ntd   table_varchar := table_varchar();
        l_rows_ntrd  table_varchar := table_varchar();
    
        l_id_nurse_tea_req_diag_in NUMBER;
        l_id_diag                  table_number;
        l_id_nurse_tea_req_hist    nurse_tea_req_hist.id_nurse_tea_req_hist%TYPE;
        l_order_recurr_f           table_number;
        l_count_drafts             PLS_INTEGER;
        l_count                    PLS_INTEGER := 0;
    
        -- Variables for diagnoses
        l_lst_diagnosis  pk_edis_types.table_in_epis_diagnosis;
        l_diagnosis      table_number := table_number();
        l_diagnosis_new  table_number := table_number();
        l_epis_diagnosis table_varchar := table_varchar();
    
        l_not_order_reason     not_order_reason.id_not_order_reason%TYPE;
        l_lst_not_order_reason table_number;
        l_ncp_class            sys_config.value%TYPE;
    
        l_dt_nurse_tea_req_h nurse_tea_req_hist.dt_nurse_tea_req_hist_tstz%TYPE;
        l_id_nurse_tea_req_h nurse_tea_req_hist.id_nurse_tea_req_hist%TYPE;
    
        l_epis_type epis_type.id_epis_type%TYPE;
    
        FUNCTION get_sub_diag_table
        (
            i_tbl_diagnosis IN pk_edis_types.rec_in_epis_diagnosis,
            i_sub_diag_list IN table_number
        ) RETURN pk_edis_types.rec_in_epis_diagnosis IS
            l_ret      pk_edis_types.rec_in_epis_diagnosis;
            l_tbl_diag pk_edis_types.table_in_diagnosis;
        BEGIN
            l_ret := i_tbl_diagnosis;
        
            IF i_sub_diag_list.exists(1)
            THEN
                l_tbl_diag          := l_ret.tbl_diagnosis;
                l_ret.tbl_diagnosis := pk_edis_types.table_in_diagnosis();
            
                IF l_tbl_diag.exists(1)
                THEN
                    FOR j IN i_sub_diag_list.first .. i_sub_diag_list.last
                    LOOP
                        FOR i IN l_tbl_diag.first .. l_tbl_diag.last
                        LOOP
                            IF l_tbl_diag(i).id_diagnosis = i_sub_diag_list(j)
                            THEN
                                l_ret.tbl_diagnosis.extend;
                                l_ret.tbl_diagnosis(l_ret.tbl_diagnosis.count) := l_tbl_diag(i);
                                EXIT;
                            END IF;
                        END LOOP;
                    END LOOP;
                END IF;
            END IF;
        
            RETURN l_ret;
        END get_sub_diag_table;
    BEGIN
        g_sysdate_tstz         := current_timestamp;
        l_category             := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
        l_lst_not_order_reason := coalesce(i_not_order_reason, table_number());
        -- Checks the current Nursing Care Plan approach in use (ICNP/NNN)
        l_ncp_class := coalesce(pk_sysconfig.get_config(pk_nnn_constant.g_config_classification, i_prof),
                                pk_nnn_constant.g_classification_icnp);
    
        IF i_flg_origin_req != pk_alert_constant.g_task_origin_order_set
        THEN
            OPEN c_nurse_tea_det;
            FETCH c_nurse_tea_det BULK COLLECT
                INTO l_nurse_tea_det;
            CLOSE c_nurse_tea_det;
        
            -- getting diagnoses for phisican      
            IF i_diagnoses IS NOT NULL
               AND i_diagnoses.count > 0
            THEN
                l_lst_diagnosis := pk_diagnosis.get_diag_rec(i_lang   => i_lang,
                                                             i_prof   => i_prof,
                                                             i_params => i_diagnoses);
            END IF;
        
            -- ignores previous pendent executions
            g_error := 'Call cancel_executions';
            FOR i IN 1 .. l_nurse_tea_det.count
            LOOP
                ts_nurse_tea_det.upd(id_nurse_tea_det_in => l_nurse_tea_det(i),
                                     flg_status_in       => pk_patient_education_constant.g_nurse_tea_det_ign,
                                     rows_out            => l_rows_ntd);
            END LOOP;
        
            g_error := 'Process insert on NURSE_TEA_DET';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'NURSE_TEA_DET',
                                          i_rowids     => l_rows_ntd,
                                          o_error      => o_error);
        END IF;
    
        -- getting final order recurr plans
        IF NOT set_final_order_recurr_p(i_lang         => i_lang,
                                        i_prof         => i_prof,
                                        i_order_recurr => i_order_recurr,
                                        o_order_recurr => l_order_recurr_f,
                                        o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        -- update nurse tea request
        g_error := 'Loop over topics';
        <<topics>>
        FOR i IN 1 .. i_topics.count
        LOOP
            IF i_flg_origin_req != pk_alert_constant.g_task_origin_order_set
               OR i_id_episode IS NOT NULL
            THEN
                l_start_date := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                              i_prof      => i_prof,
                                                              i_timestamp => i_start_date(i),
                                                              i_timezone  => NULL);
            END IF;
            -- getting not order reason id         
            IF l_lst_not_order_reason.count > 0
            THEN
                IF l_lst_not_order_reason(i) IS NOT NULL
                THEN
                    g_error := 'Call set_not_order_reason: ';
                    g_error := g_error || ' i_not_order_reason_ea = ' ||
                               coalesce(to_char(l_lst_not_order_reason(i)), '<null>');
                    pk_alertlog.log_debug(g_error);
                    IF NOT pk_not_order_reason_db.set_not_order_reason(i_lang                => i_lang,
                                                                       i_prof                => i_prof,
                                                                       i_not_order_reason_ea => l_lst_not_order_reason(i),
                                                                       o_id_not_order_reason => l_not_order_reason,
                                                                       o_error               => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                END IF;
            END IF;
        
            IF i_upd_flg_status = pk_alert_constant.g_yes
            THEN
                g_error := 'Update request';
                ts_nurse_tea_req.upd(id_nurse_tea_req_in      => i_id_nurse_tea_req(i),
                                     id_prof_req_in           => i_prof.id,
                                     id_episode_in            => i_id_episode,
                                     flg_status_in            => CASE
                                                                     WHEN i_flg_origin_req =
                                                                          pk_alert_constant.g_task_origin_order_set THEN
                                                                      pk_patient_education_core.g_status_predefined
                                                                     WHEN l_not_order_reason IS NOT NULL THEN
                                                                      pk_patient_education_constant.g_nurse_tea_req_not_ord_reas
                                                                     ELSE
                                                                      pk_patient_education_constant.g_nurse_tea_req_pend
                                                                 END,
                                     notes_req_in             => i_notes(i),
                                     notes_req_nin            => FALSE,
                                     dt_nurse_tea_req_tstz_in => g_sysdate_tstz,
                                     dt_begin_tstz_in         => l_start_date,
                                     id_visit_in              => CASE
                                                                     WHEN i_flg_origin_req !=
                                                                          pk_alert_constant.g_task_origin_order_set
                                                                          OR i_id_episode IS NOT NULL THEN
                                                                      pk_episode.get_id_visit(i_episode => i_id_episode)
                                                                 END,
                                     id_patient_in            => CASE
                                                                     WHEN i_flg_origin_req !=
                                                                          pk_alert_constant.g_task_origin_order_set
                                                                          OR i_id_episode IS NOT NULL THEN
                                                                      pk_episode.get_id_patient(i_episode => i_id_episode)
                                                                 END,
                                     id_nurse_tea_topic_in    => i_topics(i),
                                     id_order_recurr_plan_in  => l_order_recurr_f(i),
                                     id_order_recurr_plan_nin => FALSE,
                                     description_in           => i_description(i),
                                     description_nin          => FALSE,
                                     flg_time_in              => i_to_be_performed(i),
                                     id_not_order_reason_in   => l_not_order_reason,
                                     rows_out                 => l_rows);
            ELSE
                g_error := 'Update request';
                ts_nurse_tea_req.upd(id_nurse_tea_req_in      => i_id_nurse_tea_req(i),
                                     id_prof_req_in           => i_prof.id,
                                     id_episode_in            => i_id_episode,
                                     notes_req_in             => i_notes(i),
                                     notes_req_nin            => FALSE,
                                     dt_nurse_tea_req_tstz_in => g_sysdate_tstz,
                                     dt_begin_tstz_in         => l_start_date,
                                     id_visit_in              => CASE
                                                                     WHEN i_flg_origin_req !=
                                                                          pk_alert_constant.g_task_origin_order_set
                                                                          OR i_id_episode IS NOT NULL THEN
                                                                      pk_episode.get_id_visit(i_episode => i_id_episode)
                                                                 END,
                                     id_patient_in            => CASE
                                                                     WHEN i_flg_origin_req !=
                                                                          pk_alert_constant.g_task_origin_order_set
                                                                          OR i_id_episode IS NOT NULL THEN
                                                                      pk_episode.get_id_patient(i_episode => i_id_episode)
                                                                 END,
                                     id_nurse_tea_topic_in    => i_topics(i),
                                     id_order_recurr_plan_in  => l_order_recurr_f(i),
                                     id_order_recurr_plan_nin => FALSE,
                                     description_in           => i_description(i),
                                     description_nin          => FALSE,
                                     flg_time_in              => i_to_be_performed(i),
                                     id_not_order_reason_in   => l_not_order_reason,
                                     rows_out                 => l_rows);
            END IF;
        
            IF i_flg_origin_req != pk_alert_constant.g_task_origin_order_set
            THEN
                insert_ntr_hist(i_lang             => i_lang,
                                i_prof             => i_prof,
                                i_id_nurse_tea_req => i_id_nurse_tea_req(i),
                                o_error            => o_error);
            
                l_rows_ntr := l_rows_ntr MULTISET UNION l_rows;
            
                IF NOT pk_cpoe.sync_task(i_lang                 => i_lang,
                                         i_prof                 => i_prof,
                                         i_episode              => i_id_episode,
                                         i_task_type            => pk_alert_constant.g_task_type_nursing,
                                         i_task_request         => i_id_nurse_tea_req(i),
                                         i_task_start_timestamp => l_start_date,
                                         o_error                => o_error)
                THEN
                    g_error := 'PK_CPOE.SYNC_TASK';
                    RAISE g_exception;
                END IF;
            
                -- Associate compositions for nurse
                IF l_category = pk_alert_constant.g_cat_type_nurse
                THEN
                
                    SELECT MAX(ntrh.id_nurse_tea_req_hist)
                      INTO l_id_nurse_tea_req_hist
                      FROM nurse_tea_req_hist ntrh
                     WHERE ntrh.id_nurse_tea_req = i_id_nurse_tea_req(i);
                
                    g_error := 'Associate compositions to request';
                    IF i_compositions(i) IS NOT NULL
                       AND i_compositions(i).count != 0
                    THEN
                        -- Delete the association to previous nursing diagnoses 
                        ts_nurse_tea_req_diag.del_ntrd_ntr_fk(id_nurse_tea_req_in => i_id_nurse_tea_req(i));
                    
                        <<diagnoses>>
                        FOR j IN 1 .. i_compositions(i).count
                        LOOP
                        
                            l_id_nurse_tea_req_diag_in := ts_nurse_tea_req_diag.next_key;
                        
                            ts_nurse_tea_req_diag_hist.ins(id_nurse_tea_req_diag_hist_in => ts_nurse_tea_req_diag_hist.next_key,
                                                           id_nurse_tea_req_diag_in      => l_id_nurse_tea_req_diag_in,
                                                           id_nurse_tea_req_in           => i_id_nurse_tea_req(i),
                                                           id_diagnosis_in               => NULL,
                                                           id_composition_in             => CASE
                                                                                                WHEN l_category =
                                                                                                     pk_alert_constant.g_cat_type_nurse
                                                                                                     AND l_ncp_class =
                                                                                                     pk_nnn_constant.g_classification_icnp THEN
                                                                                                 i_compositions(i) (j)
                                                                                                ELSE
                                                                                                 NULL
                                                                                            END,
                                                           id_nan_diagnosis_in           => CASE
                                                                                                WHEN l_category =
                                                                                                     pk_alert_constant.g_cat_type_nurse
                                                                                                     AND
                                                                                                     l_ncp_class =
                                                                                                     pk_nnn_constant.g_classification_nanda_nic_noc THEN
                                                                                                 i_compositions(i) (j)
                                                                                                ELSE
                                                                                                 NULL
                                                                                            END,
                                                           
                                                           dt_nurse_tea_req_diag_tstz_in => g_sysdate_tstz,
                                                           id_nurse_tea_req_hist_in      => l_id_nurse_tea_req_hist,
                                                           rows_out                      => l_rows);
                        
                            ts_nurse_tea_req_diag.ins(id_nurse_tea_req_diag_in => l_id_nurse_tea_req_diag_in,
                                                      id_nurse_tea_req_in      => i_id_nurse_tea_req(i),
                                                      id_diagnosis_in          => NULL,
                                                      id_composition_in        => CASE
                                                                                      WHEN l_category = pk_alert_constant.g_cat_type_nurse
                                                                                           AND
                                                                                           l_ncp_class = pk_nnn_constant.g_classification_icnp THEN
                                                                                       i_compositions(i) (j)
                                                                                      ELSE
                                                                                       NULL
                                                                                  END,
                                                      id_nan_diagnosis_in      => CASE
                                                                                      WHEN l_category = pk_alert_constant.g_cat_type_nurse
                                                                                           AND l_ncp_class =
                                                                                           pk_nnn_constant.g_classification_nanda_nic_noc THEN
                                                                                       i_compositions(i) (j)
                                                                                      ELSE
                                                                                       NULL
                                                                                  END,
                                                      rows_out                 => l_rows);
                        
                            l_rows_ntrd := l_rows_ntrd MULTISET UNION l_rows;
                        END LOOP diagnoses;
                    ELSIF i_diagnoses IS NOT NULL
                          AND i_diagnoses.count > 0
                    THEN
                        g_error     := 'VALIDATE DIAGNOSIS';
                        l_diagnosis := table_number();
                    
                        IF l_lst_diagnosis(i).tbl_diagnosis IS NOT NULL
                        THEN
                            IF l_lst_diagnosis(i).tbl_diagnosis.count > 0
                            THEN
                                FOR j IN l_lst_diagnosis(i).tbl_diagnosis.first .. l_lst_diagnosis(i).tbl_diagnosis.last
                                LOOP
                                    IF l_lst_diagnosis(i).tbl_diagnosis(j).id_diagnosis IS NOT NULL
                                        OR l_lst_diagnosis(i).tbl_diagnosis(j).id_diagnosis != -1
                                    THEN
                                        l_diagnosis.extend;
                                        l_diagnosis(l_diagnosis.count) := l_lst_diagnosis(i).tbl_diagnosis(j).id_diagnosis;
                                    
                                        SELECT MAX(h.id_nurse_tea_req_hist)
                                          INTO l_id_nurse_tea_req_h
                                          FROM nurse_tea_req_hist h
                                         WHERE h.id_nurse_tea_req = i_id_nurse_tea_req(i);
                                    
                                        SELECT h.dt_nurse_tea_req_hist_tstz
                                          INTO l_dt_nurse_tea_req_h
                                          FROM nurse_tea_req_hist h
                                         WHERE h.id_nurse_tea_req_hist = l_id_nurse_tea_req_h;
                                    
                                        ts_nurse_tea_req_diag_hist.ins(id_nurse_tea_req_diag_hist_in => ts_nurse_tea_req_diag_hist.next_key,
                                                                       id_nurse_tea_req_diag_in      => NULL,
                                                                       id_nurse_tea_req_in           => i_id_nurse_tea_req(i),
                                                                       id_diagnosis_in               => l_lst_diagnosis(i).tbl_diagnosis(j).id_diagnosis,
                                                                       id_composition_in             => NULL,
                                                                       id_nan_diagnosis_in           => NULL,
                                                                       dt_nurse_tea_req_diag_tstz_in => l_dt_nurse_tea_req_h,
                                                                       id_nurse_tea_req_hist_in      => l_id_nurse_tea_req_h,
                                                                       rows_out                      => l_rows);
                                    
                                        g_error := 'PROCESS INSERT ON NURSE_TEA_REQ_DIAG';
                                        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                                      i_prof       => i_prof,
                                                                      i_table_name => 'NURSE_TEA_REQ_DIAG_HIST',
                                                                      i_rowids     => l_rows,
                                                                      o_error      => o_error);
                                    
                                    END IF;
                                END LOOP;
                            END IF;
                        
                        ELSE
                        
                            SELECT MAX(h.id_nurse_tea_req_hist)
                              INTO l_id_nurse_tea_req_h
                              FROM nurse_tea_req_hist h
                             WHERE h.id_nurse_tea_req = i_id_nurse_tea_req(i);
                        
                            SELECT h.dt_nurse_tea_req_hist_tstz
                              INTO l_dt_nurse_tea_req_h
                              FROM nurse_tea_req_hist h
                             WHERE h.id_nurse_tea_req_hist = l_id_nurse_tea_req_h;
                        
                            ts_nurse_tea_req_diag_hist.ins(id_nurse_tea_req_diag_hist_in => ts_nurse_tea_req_diag_hist.next_key,
                                                           id_nurse_tea_req_diag_in      => NULL,
                                                           id_nurse_tea_req_in           => i_id_nurse_tea_req(i),
                                                           id_diagnosis_in               => NULL,
                                                           id_composition_in             => NULL,
                                                           id_nan_diagnosis_in           => NULL,
                                                           dt_nurse_tea_req_diag_tstz_in => l_dt_nurse_tea_req_h,
                                                           id_nurse_tea_req_hist_in      => l_id_nurse_tea_req_h,
                                                           rows_out                      => l_rows);
                        
                            g_error := 'PROCESS INSERT ON NURSE_TEA_REQ_DIAG';
                            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                          i_table_name => 'NURSE_TEA_REQ_DIAG_HIST',
                                                          i_rowids     => l_rows,
                                                          o_error      => o_error);
                        
                        END IF;
                    
                        --Counts not null records
                        g_error := 'COUNT EPIS_DIAGNOSIS';
                        SELECT COUNT(*)
                          INTO l_count
                          FROM (SELECT /*+opt_estimate(table t rows=1)*/
                                 *
                                  FROM TABLE(l_diagnosis) t);
                    
                        --Cancels previously associated diagnosis that don't apply
                        g_error := 'CANCEL MCTD_REQ_DIAGNOSIS';
                        UPDATE mcdt_req_diagnosis mrd
                           SET mrd.flg_status     = pk_alert_constant.g_cancelled,
                               mrd.id_prof_cancel = i_prof.id,
                               mrd.dt_cancel_tstz = g_sysdate_tstz
                         WHERE mrd.id_nurse_tea_req = i_id_nurse_tea_req(i)
                           AND mrd.flg_status != pk_alert_constant.g_cancelled
                           AND ((mrd.id_diagnosis NOT IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                           *
                                                            FROM TABLE(l_diagnosis) t) AND l_count > 0) OR l_count = 0);
                    
                        g_error := 'I_DIAGNOSIS LOOP';
                        IF l_lst_diagnosis(i).tbl_diagnosis IS NOT NULL
                        THEN
                            IF l_lst_diagnosis(i).tbl_diagnosis.count > 0
                            THEN
                                g_error := 'CALL PK_DIAGNOSIS.CONCAT_DIAG_ID';
                                l_epis_diagnosis.extend;
                                l_epis_diagnosis := pk_diagnosis.concat_diag_id(i_lang             => i_lang,
                                                                                i_prof             => i_prof,
                                                                                i_exam_req_det     => NULL,
                                                                                i_analysis_req_det => NULL,
                                                                                i_interv_presc_det => NULL,
                                                                                i_nurse_tea_req    => i_id_nurse_tea_req(i),
                                                                                i_type             => 'E');
                            
                                l_count := 0;
                                IF l_epis_diagnosis IS NOT NULL
                                   AND l_epis_diagnosis.count > 0
                                THEN
                                    --Verifies if diagnosis exist
                                    g_error := 'SELECT COUNT(*)';
                                    SELECT COUNT(*)
                                      INTO l_count
                                      FROM mcdt_req_diagnosis mrd
                                     WHERE mrd.id_nurse_tea_req = i_id_nurse_tea_req(i)
                                       AND nvl(mrd.flg_status, '@') != pk_alert_constant.g_cancelled
                                       AND mrd.id_diagnosis IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                                 *
                                                                  FROM TABLE(l_diagnosis) t)
                                       AND mrd.id_epis_diagnosis IN
                                           (SELECT /*+opt_estimate (table t rows=1)*/
                                             *
                                              FROM TABLE(l_epis_diagnosis) t);
                                END IF;
                            
                                IF l_count = 0
                                THEN
                                    --Inserts new diagnosis code
                                    g_error := 'CALL TO PK_DIAGNOSIS.SET_MCDT_REQ_DIAGNOSIS';
                                    IF NOT pk_diagnosis.set_mcdt_req_diag_no_commit(i_lang             => i_lang,
                                                                                    i_prof             => i_prof,
                                                                                    i_epis             => i_id_episode,
                                                                                    i_diag             => l_lst_diagnosis(i),
                                                                                    i_exam_req         => NULL,
                                                                                    i_analysis_req     => NULL,
                                                                                    i_interv_presc     => NULL,
                                                                                    i_exam_req_det     => NULL,
                                                                                    i_analysis_req_det => NULL,
                                                                                    i_interv_presc_det => NULL,
                                                                                    i_nurse_tea_req    => i_id_nurse_tea_req(i),
                                                                                    o_error            => o_error)
                                    THEN
                                        RAISE g_exception;
                                    END IF;
                                ELSIF l_count > 0
                                      AND l_count < l_lst_diagnosis(i).tbl_diagnosis.count
                                THEN
                                    SELECT DISTINCT t.column_value
                                      BULK COLLECT
                                      INTO l_diagnosis_new
                                      FROM (SELECT /*+opt_estimate(table t rows=1)*/
                                             *
                                              FROM TABLE(l_diagnosis) t) t
                                     WHERE t.column_value NOT IN
                                           (SELECT mrd.id_diagnosis
                                              FROM mcdt_req_diagnosis mrd
                                             WHERE mrd.id_nurse_tea_req = i_id_nurse_tea_req(i)
                                               AND mrd.id_epis_diagnosis IN
                                                   (SELECT /*+opt_estimate (table t rows=1)*/
                                                     *
                                                      FROM TABLE(l_epis_diagnosis) t)
                                               AND nvl(mrd.flg_status, '@') != pk_alert_constant.g_cancelled);
                                
                                    --Inserts new diagnosis code
                                    g_error := 'CALL TO PK_DIAGNOSIS.SET_MCDT_REQ_DIAGNOSIS';
                                    IF NOT pk_diagnosis.set_mcdt_req_diag_no_commit(i_lang             => i_lang,
                                                                                    i_prof             => i_prof,
                                                                                    i_epis             => i_id_episode,
                                                                                    i_diag             => get_sub_diag_table(i_tbl_diagnosis => l_lst_diagnosis(i),
                                                                                                                             i_sub_diag_list => l_diagnosis_new),
                                                                                    i_exam_req         => NULL,
                                                                                    i_analysis_req     => NULL,
                                                                                    i_interv_presc     => NULL,
                                                                                    i_exam_req_det     => NULL,
                                                                                    i_analysis_req_det => NULL,
                                                                                    i_interv_presc_det => NULL,
                                                                                    i_nurse_tea_req    => i_id_nurse_tea_req(i),
                                                                                    o_error            => o_error)
                                    THEN
                                        RAISE g_exception;
                                    END IF;
                                END IF;
                            END IF;
                        END IF;
                    ELSE
                        ts_nurse_tea_req_diag_hist.ins(id_nurse_tea_req_diag_hist_in => ts_nurse_tea_req_diag_hist.next_key,
                                                       id_nurse_tea_req_diag_in      => NULL,
                                                       id_nurse_tea_req_in           => i_id_nurse_tea_req(i),
                                                       id_diagnosis_in               => NULL,
                                                       id_composition_in             => NULL,
                                                       id_nan_diagnosis_in           => NULL,
                                                       dt_nurse_tea_req_diag_tstz_in => g_sysdate_tstz,
                                                       id_nurse_tea_req_hist_in      => l_id_nurse_tea_req_hist,
                                                       rows_out                      => l_rows);
                    
                        ts_nurse_tea_req_diag.del_ntrd_ntr_fk(id_nurse_tea_req_in => i_id_nurse_tea_req(i));
                    
                    END IF;
                ELSE
                    -- Associate diagnoses for phisican
                    IF i_diagnoses IS NOT NULL
                       AND i_diagnoses.count > 0
                    THEN
                        g_error     := 'VALIDATE DIAGNOSIS';
                        l_diagnosis := table_number();
                    
                        IF l_lst_diagnosis(i).tbl_diagnosis IS NOT NULL
                        THEN
                            IF l_lst_diagnosis(i).tbl_diagnosis.count > 0
                            THEN
                                FOR j IN l_lst_diagnosis(i).tbl_diagnosis.first .. l_lst_diagnosis(i).tbl_diagnosis.last
                                LOOP
                                    IF l_lst_diagnosis(i).tbl_diagnosis(j).id_diagnosis IS NOT NULL
                                        OR l_lst_diagnosis(i).tbl_diagnosis(j).id_diagnosis != -1
                                    THEN
                                        l_diagnosis.extend;
                                        l_diagnosis(l_diagnosis.count) := l_lst_diagnosis(i).tbl_diagnosis(j).id_diagnosis;
                                    
                                        SELECT MAX(h.id_nurse_tea_req_hist)
                                          INTO l_id_nurse_tea_req_h
                                          FROM nurse_tea_req_hist h
                                         WHERE h.id_nurse_tea_req = i_id_nurse_tea_req(i);
                                    
                                        SELECT h.dt_nurse_tea_req_hist_tstz
                                          INTO l_dt_nurse_tea_req_h
                                          FROM nurse_tea_req_hist h
                                         WHERE h.id_nurse_tea_req_hist = l_id_nurse_tea_req_h;
                                    
                                        ts_nurse_tea_req_diag_hist.ins(id_nurse_tea_req_diag_hist_in => ts_nurse_tea_req_diag_hist.next_key,
                                                                       id_nurse_tea_req_diag_in      => NULL,
                                                                       id_nurse_tea_req_in           => i_id_nurse_tea_req(i),
                                                                       id_diagnosis_in               => l_lst_diagnosis(i).tbl_diagnosis(j).id_diagnosis,
                                                                       id_composition_in             => NULL,
                                                                       id_nan_diagnosis_in           => NULL,
                                                                       dt_nurse_tea_req_diag_tstz_in => l_dt_nurse_tea_req_h,
                                                                       id_nurse_tea_req_hist_in      => l_id_nurse_tea_req_h,
                                                                       rows_out                      => l_rows);
                                    
                                        g_error := 'PROCESS INSERT ON NURSE_TEA_REQ_DIAG';
                                        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                                      i_prof       => i_prof,
                                                                      i_table_name => 'NURSE_TEA_REQ_DIAG_HIST',
                                                                      i_rowids     => l_rows,
                                                                      o_error      => o_error);
                                    
                                    END IF;
                                END LOOP;
                            END IF;
                        
                        ELSE
                        
                            SELECT MAX(h.id_nurse_tea_req_hist)
                              INTO l_id_nurse_tea_req_h
                              FROM nurse_tea_req_hist h
                             WHERE h.id_nurse_tea_req = i_id_nurse_tea_req(i);
                        
                            SELECT h.dt_nurse_tea_req_hist_tstz
                              INTO l_dt_nurse_tea_req_h
                              FROM nurse_tea_req_hist h
                             WHERE h.id_nurse_tea_req_hist = l_id_nurse_tea_req_h;
                        
                            ts_nurse_tea_req_diag_hist.ins(id_nurse_tea_req_diag_hist_in => ts_nurse_tea_req_diag_hist.next_key,
                                                           id_nurse_tea_req_diag_in      => NULL,
                                                           id_nurse_tea_req_in           => i_id_nurse_tea_req(i),
                                                           id_diagnosis_in               => NULL,
                                                           id_composition_in             => NULL,
                                                           id_nan_diagnosis_in           => NULL,
                                                           dt_nurse_tea_req_diag_tstz_in => l_dt_nurse_tea_req_h,
                                                           id_nurse_tea_req_hist_in      => l_id_nurse_tea_req_h,
                                                           rows_out                      => l_rows);
                        
                            g_error := 'PROCESS INSERT ON NURSE_TEA_REQ_DIAG';
                            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                          i_table_name => 'NURSE_TEA_REQ_DIAG_HIST',
                                                          i_rowids     => l_rows,
                                                          o_error      => o_error);
                        
                        END IF;
                    
                        --Counts not null records
                        g_error := 'COUNT EPIS_DIAGNOSIS';
                        SELECT COUNT(*)
                          INTO l_count
                          FROM (SELECT /*+opt_estimate(table t rows=1)*/
                                 *
                                  FROM TABLE(l_diagnosis) t);
                    
                        --Cancels previously associated diagnosis that don't apply
                        g_error := 'CANCEL MCTD_REQ_DIAGNOSIS';
                        UPDATE mcdt_req_diagnosis mrd
                           SET mrd.flg_status     = pk_alert_constant.g_cancelled,
                               mrd.id_prof_cancel = i_prof.id,
                               mrd.dt_cancel_tstz = g_sysdate_tstz
                         WHERE mrd.id_nurse_tea_req = i_id_nurse_tea_req(i)
                           AND mrd.flg_status != pk_alert_constant.g_cancelled
                           AND ((mrd.id_diagnosis NOT IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                           *
                                                            FROM TABLE(l_diagnosis) t) AND l_count > 0) OR l_count = 0);
                    
                        g_error := 'I_DIAGNOSIS LOOP';
                        IF l_lst_diagnosis(i).tbl_diagnosis IS NOT NULL
                        THEN
                            IF l_lst_diagnosis(i).tbl_diagnosis.count > 0
                            THEN
                                g_error := 'CALL PK_DIAGNOSIS.CONCAT_DIAG_ID';
                                l_epis_diagnosis.extend;
                                l_epis_diagnosis := pk_diagnosis.concat_diag_id(i_lang             => i_lang,
                                                                                i_prof             => i_prof,
                                                                                i_exam_req_det     => NULL,
                                                                                i_analysis_req_det => NULL,
                                                                                i_interv_presc_det => NULL,
                                                                                i_nurse_tea_req    => i_id_nurse_tea_req(i),
                                                                                i_type             => 'E');
                            
                                l_count := 0;
                                IF l_epis_diagnosis IS NOT NULL
                                   AND l_epis_diagnosis.count > 0
                                THEN
                                    --Verifies if diagnosis exist
                                    g_error := 'SELECT COUNT(*)';
                                    SELECT COUNT(*)
                                      INTO l_count
                                      FROM mcdt_req_diagnosis mrd
                                     WHERE mrd.id_nurse_tea_req = i_id_nurse_tea_req(i)
                                       AND nvl(mrd.flg_status, '@') != pk_alert_constant.g_cancelled
                                       AND mrd.id_diagnosis IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                                 *
                                                                  FROM TABLE(l_diagnosis) t)
                                       AND mrd.id_epis_diagnosis IN
                                           (SELECT /*+opt_estimate (table t rows=1)*/
                                             *
                                              FROM TABLE(l_epis_diagnosis) t);
                                END IF;
                            
                                IF l_count = 0
                                THEN
                                    --Inserts new diagnosis code
                                    g_error := 'CALL TO PK_DIAGNOSIS.SET_MCDT_REQ_DIAGNOSIS';
                                    IF NOT pk_diagnosis.set_mcdt_req_diag_no_commit(i_lang             => i_lang,
                                                                                    i_prof             => i_prof,
                                                                                    i_epis             => i_id_episode,
                                                                                    i_diag             => l_lst_diagnosis(i),
                                                                                    i_exam_req         => NULL,
                                                                                    i_analysis_req     => NULL,
                                                                                    i_interv_presc     => NULL,
                                                                                    i_exam_req_det     => NULL,
                                                                                    i_analysis_req_det => NULL,
                                                                                    i_interv_presc_det => NULL,
                                                                                    i_nurse_tea_req    => i_id_nurse_tea_req(i),
                                                                                    o_error            => o_error)
                                    THEN
                                        RAISE g_exception;
                                    END IF;
                                ELSIF l_count > 0
                                      AND l_count < l_lst_diagnosis(i).tbl_diagnosis.count
                                THEN
                                    SELECT DISTINCT t.column_value
                                      BULK COLLECT
                                      INTO l_diagnosis_new
                                      FROM (SELECT /*+opt_estimate(table t rows=1)*/
                                             *
                                              FROM TABLE(l_diagnosis) t) t
                                     WHERE t.column_value NOT IN
                                           (SELECT mrd.id_diagnosis
                                              FROM mcdt_req_diagnosis mrd
                                             WHERE mrd.id_nurse_tea_req = i_id_nurse_tea_req(i)
                                               AND mrd.id_epis_diagnosis IN
                                                   (SELECT /*+opt_estimate (table t rows=1)*/
                                                     *
                                                      FROM TABLE(l_epis_diagnosis) t)
                                               AND nvl(mrd.flg_status, '@') != pk_alert_constant.g_cancelled);
                                
                                    --Inserts new diagnosis code
                                    g_error := 'CALL TO PK_DIAGNOSIS.SET_MCDT_REQ_DIAGNOSIS';
                                    IF NOT pk_diagnosis.set_mcdt_req_diag_no_commit(i_lang             => i_lang,
                                                                                    i_prof             => i_prof,
                                                                                    i_epis             => i_id_episode,
                                                                                    i_diag             => get_sub_diag_table(i_tbl_diagnosis => l_lst_diagnosis(i),
                                                                                                                             i_sub_diag_list => l_diagnosis_new),
                                                                                    i_exam_req         => NULL,
                                                                                    i_analysis_req     => NULL,
                                                                                    i_interv_presc     => NULL,
                                                                                    i_exam_req_det     => NULL,
                                                                                    i_analysis_req_det => NULL,
                                                                                    i_interv_presc_det => NULL,
                                                                                    i_nurse_tea_req    => i_id_nurse_tea_req(i),
                                                                                    o_error            => o_error)
                                    THEN
                                        RAISE g_exception;
                                    END IF;
                                END IF;
                            END IF;
                        END IF;
                    ELSIF i_compositions(i) IS NOT NULL
                          AND i_compositions(i).count != 0
                    THEN
                        SELECT MAX(ntrh.id_nurse_tea_req_hist)
                          INTO l_id_nurse_tea_req_hist
                          FROM nurse_tea_req_hist ntrh
                         WHERE ntrh.id_nurse_tea_req = i_id_nurse_tea_req(i);
                    
                        -- Delete the association to previous nursing diagnoses 
                        ts_nurse_tea_req_diag.del_ntrd_ntr_fk(id_nurse_tea_req_in => i_id_nurse_tea_req(i));
                    
                        <<diagnoses>>
                        FOR j IN 1 .. i_compositions(i).count
                        LOOP
                        
                            l_id_nurse_tea_req_diag_in := ts_nurse_tea_req_diag.next_key;
                        
                            ts_nurse_tea_req_diag_hist.ins(id_nurse_tea_req_diag_hist_in => ts_nurse_tea_req_diag_hist.next_key,
                                                           id_nurse_tea_req_diag_in      => l_id_nurse_tea_req_diag_in,
                                                           id_nurse_tea_req_in           => i_id_nurse_tea_req(i),
                                                           id_diagnosis_in               => NULL,
                                                           id_composition_in             => i_compositions(i) (j),
                                                           id_nan_diagnosis_in           => NULL,
                                                           dt_nurse_tea_req_diag_tstz_in => g_sysdate_tstz,
                                                           id_nurse_tea_req_hist_in      => l_id_nurse_tea_req_hist,
                                                           rows_out                      => l_rows);
                        
                            ts_nurse_tea_req_diag.ins(id_nurse_tea_req_diag_in => l_id_nurse_tea_req_diag_in,
                                                      id_nurse_tea_req_in      => i_id_nurse_tea_req(i),
                                                      id_diagnosis_in          => NULL,
                                                      id_composition_in        => i_compositions(i) (j),
                                                      id_nan_diagnosis_in      => NULL,
                                                      rows_out                 => l_rows);
                        
                            l_rows_ntrd := l_rows_ntrd MULTISET UNION l_rows;
                        END LOOP diagnoses;
                    END IF;
                END IF;
            END IF;
        END LOOP topics;
    
        IF i_flg_origin_req != pk_alert_constant.g_task_origin_order_set
        THEN
            g_error := 'Process insert on NURSE_TEA_REQ';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'NURSE_TEA_REQ',
                                          i_rowids     => l_rows_ntr,
                                          o_error      => o_error);
        
            g_error := 'Process insert on NURSE_TEA_DET';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'NURSE_TEA_DET',
                                          i_rowids     => l_rows_ntd,
                                          o_error      => o_error);
        
            g_error := 'Process insert on NURSE_TEA_REQ_DIAG';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'NURSE_TEA_REQ_DIAG',
                                          i_rowids     => l_rows_ntrd,
                                          o_error      => o_error);
        
            g_error := 'Process insert on NURSE_TEA_REQ_DIAG';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'NURSE_TEA_REQ_DIAG_HIST',
                                          i_rowids     => l_rows_ntrd,
                                          o_error      => o_error);
        
            SELECT COUNT(1)
              INTO l_count_drafts
              FROM nurse_tea_req ntr
              JOIN TABLE(CAST(i_id_nurse_tea_req AS table_number)) t
                ON t.column_value = ntr.id_nurse_tea_req
             WHERE ntr.flg_status = pk_patient_education_constant.g_nurse_tea_req_draft;
        
            IF l_count_drafts = 0
            THEN
                -- create new executions related to this nurse_tea_req
                g_error := 'Call create_ntr_executions / i_id_nurse_tea_req.count=' || i_id_nurse_tea_req.count ||
                           ' l_order_recurr_f.count=' || l_order_recurr_f.count;
                IF NOT create_ntr_executions(i_lang             => i_lang,
                                             i_prof             => i_prof,
                                             i_id_nurse_tea_req => i_id_nurse_tea_req,
                                             i_order_recurr     => l_order_recurr_f,
                                             i_start_date       => i_start_date,
                                             o_error            => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
            END IF;
        
            IF NOT pk_episode.get_epis_type(i_lang      => i_lang,
                                            i_id_epis   => i_id_episode,
                                            o_epis_type => l_epis_type,
                                            o_error     => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            IF l_epis_type IN (pk_alert_constant.g_epis_type_home_health_care, 99)
            THEN
                IF NOT pk_hhc_core.set_req_status_ie(i_lang            => i_lang,
                                                     i_prof            => i_prof,
                                                     i_id_episode      => i_id_episode,
                                                     i_id_epis_hhc_req => NULL,
                                                     o_error           => o_error)
                THEN
                    RAISE g_exception;
                END IF;
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
                                              'UPDATE_REQUEST',
                                              o_error);
        
            RETURN FALSE;
    END update_request;

    /******************************************************************************/
    FUNCTION create_nurse_tea_req
    (
        i_lang             IN language.id_language%TYPE,
        i_episode          IN nurse_tea_req.id_episode%TYPE,
        i_prof_req         IN profissional,
        i_dt_begin_str     IN VARCHAR2,
        i_notes_req        IN nurse_tea_req.notes_req%TYPE,
        i_prof_cat_type    IN category.flg_type%TYPE,
        i_flg_commit       IN VARCHAR2,
        o_id_nurse_tea_req OUT nurse_tea_req.id_nurse_tea_req%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_next_req   nurse_tea_req.id_nurse_tea_req%TYPE;
        l_ntr_rowids table_varchar;
        --l_error      VARCHAR2(4000);
        l_error      t_error_out;
        l_id_patient nurse_tea_req.id_patient%TYPE;
        l_id_visit   nurse_tea_req.id_visit%TYPE;
        l_icnp_exception EXCEPTION;
        l_datehour     VARCHAR2(50);
        l_dt_begin_str VARCHAR2(50);
    
        --
        CURSOR c_nurse_tea_req_info IS
            SELECT vis.id_visit, vis.id_patient
              FROM episode epi, visit vis
             WHERE epi.id_episode = i_episode
               AND epi.id_visit = vis.id_visit;
    
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'validate notes';
    
        IF (i_notes_req IS NULL)
        THEN
            RAISE l_icnp_exception; --ALERT-23158
            -- o_error.err_desc := pk_message.get_message(i_lang, 'NURSE_TEA_M001');
            -- RETURN FALSE;
        END IF;
    
        g_error := 'GET CURSOR';
        OPEN c_nurse_tea_req_info;
        FETCH c_nurse_tea_req_info
            INTO l_id_visit, l_id_patient;
        CLOSE c_nurse_tea_req_info;
    
        --ALERT-25142
        IF i_dt_begin_str IS NOT NULL
        THEN
            --get actual date
            IF i_dt_begin_str < l_datehour
            THEN
                l_dt_begin_str := NULL;
            ELSE
                l_dt_begin_str := i_dt_begin_str;
            END IF;
        ELSE
            l_dt_begin_str := NULL;
        END IF;
    
        g_error    := 'prv_new_nurse_tea_req';
        l_next_req := prv_new_nurse_tea_req(i_lang                 => i_lang,
                                            i_id_episode           => i_episode,
                                            i_flg_status           => pk_icnp_constant.g_epis_diag_status_active,
                                            i_dt_nurse_tea_req_str => pk_date_utils.get_timestamp_str(i_lang,
                                                                                                      i_prof_req,
                                                                                                      g_sysdate_tstz,
                                                                                                      NULL),
                                            i_id_prof_req          => i_prof_req,
                                            i_dt_begin_str         => nvl(l_dt_begin_str,
                                                                          pk_date_utils.get_timestamp_str(i_lang,
                                                                                                          i_prof_req,
                                                                                                          g_sysdate_tstz,
                                                                                                          NULL)),
                                            i_notes_req            => i_notes_req,
                                            /* name of the deep-nav where the doctor make the teaching request */
                                            i_req_header => pk_message.get_message(i_lang,
                                                                                   i_prof_req,
                                                                                   'SYS_BUTTON.CODE_BUTTON.191'),
                                            i_id_visit   => l_id_visit,
                                            i_id_patient => l_id_patient,
                                            o_rowids     => l_ntr_rowids);
    
        -- PLLopes 30/01/2008 - ALERT912
        -- insert log status
        IF NOT t_ti_log.ins_log(i_lang,
                                i_prof_req,
                                i_episode,
                                pk_icnp_constant.g_epis_diag_status_active,
                                l_next_req,
                                pk_edis_summary.g_ti_log_nurse_tea,
                                o_error)
        THEN
            RETURN FALSE;
        END IF;
        --  ALERT912
    
        -- CHAMAR A FUNCAO PROCESS_INSERT DO PACKAGE T_DATA_GOV_MNT
        --IF (NOT
        g_error := 'CALL TO T_DATA_GOV_MNT.PROCESS_INSERT - NURSE_TEA_REQ';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof_req,
                                      i_table_name => 'NURSE_TEA_REQ',
                                      i_rowids     => l_ntr_rowids,
                                      o_error      => o_error);
        /*THEN
            RETURN FALSE;
        END IF;*/
    
        -- return new nurse tea request id
        o_id_nurse_tea_req := l_next_req;
    
        /* just in case set_first_obs fails, we commit, CIPE transactions */
        COMMIT;
        g_error := 'CALL TO PK_VISIT.SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof_req,
                                      i_prof_cat_type       => i_prof_cat_type,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => l_error)
        THEN
            o_error := l_error;
        
            IF i_flg_commit = pk_alert_constant.g_yes
            THEN
                ROLLBACK;
            END IF;
        
            RETURN FALSE;
        END IF;
    
        IF NOT pk_cpoe.sync_task(i_lang                 => i_lang,
                                 i_prof                 => i_prof_req,
                                 i_episode              => i_episode,
                                 i_task_type            => pk_alert_constant.g_task_type_nursing,
                                 i_task_request         => l_next_req,
                                 i_task_start_timestamp => nvl(pk_date_utils.get_string_tstz(i_lang,
                                                                                             i_prof_req,
                                                                                             pk_date_utils.get_string_tstz(i_lang,
                                                                                                                           i_prof_req,
                                                                                                                           l_dt_begin_str,
                                                                                                                           NULL),
                                                                                             NULL),
                                                               g_sysdate_tstz),
                                 o_error                => o_error)
        THEN
            g_error := 'PK_CPOE.SYNC_TASK';
            RAISE g_exception;
        END IF;
    
        IF i_flg_commit = pk_alert_constant.g_yes
        THEN
            COMMIT;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_icnp_exception THEN
            DECLARE
                l_error t_error_in := t_error_in();
                l_ret   BOOLEAN;
            BEGIN
                l_error.set_all(i_lang,
                                'NURSE_TEA_M001',
                                pk_message.get_message(i_lang, 'NURSE_TEA_M001'),
                                NULL,
                                'ALERT',
                                g_package_name,
                                'CREATE_NURSE_TEA_REQ',
                                pk_message.get_message(i_lang, 'NURSE_TEA_M001'),
                                'D');
                l_ret := pk_alert_exceptions.process_error(l_error, o_error);
                RETURN FALSE;
            END;
        WHEN OTHERS THEN
            DECLARE
                --PLLopes 10/03/2009 - Inicialization of object for input
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_ret       BOOLEAN;
                l_error_s   VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
            BEGIN
                -- setting error content into input object
                l_error_in.set_errors(SQLCODE, SQLERRM, l_error_s);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_ICNP', 'CREATE_NURSE_TEA_REQ');
                -- execute error processing
                l_ret   := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                o_error := l_error_out;
                -- undo changes quando aplic�vel-> s� faz ROLLBACK
                IF i_flg_commit = pk_alert_constant.g_yes
                THEN
                    pk_utils.undo_changes;
                END IF;
                --reset error state
                pk_alert_exceptions.reset_error_state();
                RETURN FALSE;
            END;
    END create_nurse_tea_req;

    FUNCTION create_nurse_tea_req
    (
        i_lang             IN language.id_language%TYPE,
        i_episode          IN nurse_tea_req.id_episode%TYPE,
        i_prof_req         IN profissional,
        i_dt_begin_str     IN VARCHAR2,
        i_notes_req        IN nurse_tea_req.notes_req%TYPE,
        i_prof_cat_type    IN category.flg_type%TYPE,
        o_id_nurse_tea_req OUT nurse_tea_req.id_nurse_tea_req%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
    
        IF NOT create_nurse_tea_req(i_lang             => i_lang,
                                    i_episode          => i_episode,
                                    i_prof_req         => i_prof_req,
                                    i_dt_begin_str     => i_dt_begin_str,
                                    i_notes_req        => i_notes_req,
                                    i_prof_cat_type    => i_prof_cat_type,
                                    i_flg_commit       => pk_alert_constant.g_yes,
                                    o_id_nurse_tea_req => o_id_nurse_tea_req,
                                    o_error            => o_error)
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
                                              'CREATE_NURSE_TEA_REQ',
                                              o_error);
        
            RETURN FALSE;
    END create_nurse_tea_req;

    FUNCTION create_nurse_tea_req
    (
        i_lang             IN language.id_language%TYPE,
        i_episode          IN nurse_tea_req.id_episode%TYPE,
        i_prof_req         IN profissional,
        i_dt_begin_str     IN VARCHAR2,
        i_notes_req        IN nurse_tea_req.notes_req%TYPE,
        i_prof_cat_type    IN category.flg_type%TYPE,
        i_draft            IN VARCHAR2,
        o_id_nurse_tea_req OUT nurse_tea_req.id_nurse_tea_req%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_next_req     nurse_tea_req.id_nurse_tea_req%TYPE;
        l_ntr_rowids   table_varchar;
        l_error        t_error_out;
        l_id_patient   nurse_tea_req.id_patient%TYPE;
        l_id_visit     nurse_tea_req.id_visit%TYPE;
        l_datehour     VARCHAR2(50);
        l_dt_begin_str VARCHAR2(50);
    
        l_icnp_exception EXCEPTION;
    
        CURSOR c_nurse_tea_req_info IS
            SELECT vis.id_visit, vis.id_patient
              FROM episode epi, visit vis
             WHERE epi.id_episode = i_episode
               AND epi.id_visit = vis.id_visit;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'validate notes';
        IF (i_notes_req IS NULL)
        THEN
            RAISE l_icnp_exception;
        END IF;
    
        g_error := 'GET CURSOR';
        OPEN c_nurse_tea_req_info;
        FETCH c_nurse_tea_req_info
            INTO l_id_visit, l_id_patient;
        CLOSE c_nurse_tea_req_info;
    
        IF i_dt_begin_str IS NOT NULL
        THEN
            IF i_dt_begin_str < l_datehour
            THEN
                l_dt_begin_str := NULL;
            ELSE
                l_dt_begin_str := i_dt_begin_str;
            END IF;
        ELSE
            l_dt_begin_str := NULL;
        END IF;
    
        g_error    := 'prv_new_nurse_tea_req';
        l_next_req := prv_new_nurse_tea_req(i_lang                 => i_lang,
                                            i_id_episode           => i_episode,
                                            i_flg_status           => CASE i_draft
                                                                          WHEN pk_alert_constant.get_yes THEN
                                                                           pk_patient_education_constant.g_nurse_tea_req_draft
                                                                          ELSE
                                                                           pk_alert_constant.g_active
                                                                      END,
                                            i_dt_nurse_tea_req_str => pk_date_utils.get_timestamp_str(i_lang,
                                                                                                      i_prof_req,
                                                                                                      g_sysdate_tstz,
                                                                                                      NULL),
                                            i_id_prof_req          => i_prof_req,
                                            i_dt_begin_str         => nvl(l_dt_begin_str,
                                                                          pk_date_utils.get_timestamp_str(i_lang,
                                                                                                          i_prof_req,
                                                                                                          g_sysdate_tstz,
                                                                                                          NULL)),
                                            i_notes_req            => i_notes_req,
                                            i_req_header           => pk_message.get_message(i_lang,
                                                                                             i_prof_req,
                                                                                             'SYS_BUTTON.CODE_BUTTON.191'),
                                            i_id_visit             => l_id_visit,
                                            i_id_patient           => l_id_patient,
                                            o_rowids               => l_ntr_rowids);
    
        g_error := 'CALL TO T_DATA_GOV_MNT.PROCESS_INSERT - NURSE_TEA_REQ';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof_req,
                                      i_table_name => 'NURSE_TEA_REQ',
                                      i_rowids     => l_ntr_rowids,
                                      o_error      => o_error);
    
        o_id_nurse_tea_req := l_next_req;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_icnp_exception THEN
            DECLARE
                l_error t_error_in := t_error_in();
                l_ret   BOOLEAN;
            BEGIN
                l_error.set_all(i_lang,
                                'NURSE_TEA_M001',
                                pk_message.get_message(i_lang, 'NURSE_TEA_M001'),
                                NULL,
                                'ALERT',
                                g_package_name,
                                'CREATE_NURSE_TEA_REQ',
                                pk_message.get_message(i_lang, 'NURSE_TEA_M001'),
                                'D');
                l_ret := pk_alert_exceptions.process_error(l_error, o_error);
                RETURN FALSE;
            END;
        WHEN OTHERS THEN
            DECLARE
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_ret       BOOLEAN;
                l_error_s   VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, l_error_s);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_ICNP_CORE', 'CREATE_NURSE_TEA_REQ');
                l_ret   := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                o_error := l_error_out;
                pk_utils.undo_changes;
                pk_alert_exceptions.reset_error_state();
                RETURN FALSE;
            END;
    END create_nurse_tea_req;

    FUNCTION get_subject_by_id_topic
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_topic IN nurse_tea_topic.id_nurse_tea_topic%TYPE,
        o_subject  OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF i_id_topic IS NULL
        THEN
            RAISE g_exception;
        END IF;
    
        -- Patient education subject
        OPEN o_subject FOR
            SELECT nts.id_nurse_tea_subject,
                   pk_translation.get_translation(i_lang, nts.code_nurse_tea_subject) desc_subject,
                   ntt.id_nurse_tea_topic,
                   pk_translation_lob.get_translation(i_lang, ntt.code_topic_description) desc_topic
              FROM nurse_tea_topic ntt
              JOIN nurse_tea_subject nts
                ON nts.id_nurse_tea_subject = ntt.id_nurse_tea_subject
               AND ntt.id_nurse_tea_topic = i_id_topic;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_cursor_if_closed(o_subject);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SUBJECT_BY_ID_TOPIC',
                                              o_error);
        
            RETURN FALSE;
    END get_subject_by_id_topic;

    /**
    * Returns available actions according with patient education request's status
    *
    * @param   i_lang           Professional preferred language
    * @param   i_prof           Professional identification and its context (institution and software)
    * @param   i_nurse_tea_req  Patient education request IDs
    * @param   o_actions        Available actions
    * @param   o_error          Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.1.5
    * @since   07-11-2011
    */
    FUNCTION get_request_actions
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_nurse_tea_req IN table_number,
        i_id_episode    IN episode.id_episode%TYPE,
        i_id_hhc_req    IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_actions       OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        co_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_request_actions';
        e_function_call_error EXCEPTION;
        l_flg_status table_varchar;
    
        l_epis_type     epis_type.id_epis_type%TYPE;
        l_flg_can_edit  VARCHAR2(1) := pk_alert_constant.g_yes;
        l_i_id_hhc_req  epis_hhc_req.id_epis_hhc_req%TYPE;
        l_flg_time      table_varchar;
        l_flg_time_next VARCHAR(1 CHAR) := pk_alert_constant.g_no;
    BEGIN
    
        g_error := 'Checks within selected items if there are requests expired';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => co_function_name);
        SELECT (CASE ntr.flg_status
                   WHEN pk_patient_education_constant.g_nurse_tea_req_expired THEN
                   -- Check extra take
                    (CASE pk_patient_education_cpoe.check_extra_take(i_lang         => i_lang,
                                                                 i_prof         => i_prof,
                                                                 i_task_request => ntr.id_nurse_tea_req,
                                                                 i_status       => ntr.flg_status,
                                                                 i_dt_expire    => ntr.dt_close_tstz)
                        WHEN pk_alert_constant.g_yes THEN
                         pk_patient_education_constant.g_nurse_tea_req_expired
                        ELSE
                        -- No conditions to allow execution in expired task, so actions are the same as for a cancelled task
                         pk_patient_education_constant.g_nurse_tea_req_canc
                    END)
                   ELSE
                    ntr.flg_status
               END) flg_status,
               ntr.flg_time
          BULK COLLECT
          INTO l_flg_status, l_flg_time
          FROM nurse_tea_req ntr
         WHERE ntr.id_nurse_tea_req IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                         t.column_value
                                          FROM TABLE(i_nurse_tea_req) t);
    
        FOR i IN 1 .. l_flg_time.count
        LOOP
            IF l_flg_time(i) = 'N'
            THEN
                l_flg_time_next := pk_alert_constant.g_yes;
            END IF;
        END LOOP;
    
        IF i_id_episode IS NOT NULL
        THEN
            IF NOT pk_episode.get_epis_type(i_lang      => i_lang,
                                            i_id_epis   => i_id_episode,
                                            o_epis_type => l_epis_type,
                                            o_error     => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        IF l_epis_type IN (pk_alert_constant.g_epis_type_home_health_care, 99)
           OR i_id_hhc_req IS NOT NULL
        THEN
        
            l_i_id_hhc_req := nvl(i_id_hhc_req,
                                  pk_hhc_core.get_id_epis_hhc_req_by_pat(i_id_patient => pk_episode.get_id_patient(i_id_episode)));
        
            IF NOT pk_hhc_ux.get_prof_can_edit(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_id_hhc_req   => l_i_id_hhc_req,
                                               o_flg_can_edit => l_flg_can_edit,
                                               o_error        => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        --determinar se existe algum epis�dio de hhc?                                                          
    
        g_error := 'CALL pk_action.get_cross_actions';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => co_function_name);
    
        OPEN o_actions FOR
            SELECT MIN(id_action) id_action,
                   id_parent,
                   l AS "LEVEL",
                   to_state,
                   desc_action,
                   icon,
                   flg_default,
                   MAX(flg_active) flg_active,
                   action,
                   MIN(rank) rank
              FROM (SELECT id_action,
                           id_parent,
                           LEVEL AS l, --used to manage the shown' items by Flash
                            to_state, --destination state flag
                            pk_message.get_message(i_lang, i_prof, code_action) desc_action, --action's description
                           icon, --action's icon
                            decode(flg_default, 'D', 'Y', 'N') flg_default, --default action
                            CASE
                                 WHEN ((l_flg_can_edit = pk_alert_constant.g_no AND internal_name IN ('EDIT', 'CANCEL')) OR
                                      (l_flg_time_next = pk_alert_constant.g_yes AND internal_name = 'EXECUTE')) THEN
                                  pk_alert_constant.g_inactive
                                 ELSE
                                  nvl(pk_action.get_actions_exception(i_lang, i_prof, a.id_action), a.flg_status)
                             END AS flg_active, --action's state
                           internal_name action,
                           a.from_state,
                           rank
                      FROM action a
                     WHERE subject = 'PATIENT_EDUCATION'
                       AND from_state IN (SELECT *
                                            FROM TABLE(l_flg_status))
                    CONNECT BY PRIOR id_action = id_parent
                     START WITH id_parent IS NULL)
             GROUP BY id_parent, l, to_state, desc_action, icon, flg_default, action
            HAVING COUNT(from_state) = (SELECT COUNT(*)
                                          FROM TABLE(table_varchar() MULTISET UNION DISTINCT l_flg_status))
            UNION ALL
            SELECT -1 id_action,
                   NULL id_parent,
                   1 AS "LEVEL",
                   NULL to_state,
                   pk_message.get_message(i_lang, 'PATIENT_EDUCATION_T056') desc_action,
                   'CheckIcon' icon,
                   pk_alert_constant.g_no flg_default,
                   pk_alert_constant.g_active flg_active,
                   'REQ_AND_EXECUTE' action,
                   -1 rank
              FROM dual
             ORDER BY "LEVEL", rank, desc_action;
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_function_call_error THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => o_error.ora_sqlcode,
                                              i_sqlerrm  => o_error.ora_sqlerrm,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => co_function_name,
                                              o_error    => o_error);
        
            pk_types.open_my_cursor(o_actions);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => co_function_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_actions);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_request_actions;

    FUNCTION get_patient_education_all_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_list       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'List this visit?s patient education tasks';
        OPEN o_list FOR
            SELECT ntr.id_nurse_tea_req,
                   pk_patient_education_utils.get_desc_topic(i_lang,
                                                             i_prof,
                                                             ntr.id_nurse_tea_topic,
                                                             ntr.desc_topic_aux,
                                                             ntt.code_nurse_tea_topic) title_topic,
                   pk_translation.get_translation(i_lang,
                                                   CASE
                                                       WHEN nts.code_nurse_tea_subject IS NULL THEN
                                                        'NURSE_TEA_TOPIC.CODE_NURSE_TEA_TOPIC.1'
                                                       ELSE
                                                        nts.code_nurse_tea_subject
                                                   END) title_subject,
                   ntt.id_nurse_tea_topic,
                   nts.id_nurse_tea_subject,
                   pk_prof_utils.get_nickname(i_lang, ntr.id_prof_req) prof_order,
                   pk_ehr_common.get_visit_name_by_epis(i_lang,
                                                        i_prof,
                                                        pk_episode.get_epis_type(i_lang, ntr.id_episode)) desc_epis_type,
                   pk_ehr_common.get_visit_type_by_epis(i_lang,
                                                        i_prof,
                                                        ntr.id_episode,
                                                        pk_episode.get_epis_type(i_lang, ntr.id_episode),
                                                        '; ') desc_epis,
                   pk_date_utils.date_char_hour_tsz(i_lang, ntr.dt_begin_tstz, i_prof.institution, i_prof.software) hour_target,
                   pk_date_utils.dt_chr_tsz(i_lang, ntr.dt_begin_tstz, i_prof.institution, i_prof.software) date_target
              FROM nurse_tea_req ntr
              LEFT JOIN nurse_tea_topic ntt
                ON ntt.id_nurse_tea_topic = ntr.id_nurse_tea_topic
              LEFT JOIN nurse_tea_subject nts
                ON nts.id_nurse_tea_subject = ntt.id_nurse_tea_subject
              JOIN professional p
                ON p.id_professional = ntr.id_prof_req
              JOIN (SELECT DISTINCT (ntr.id_episode)
                      FROM nurse_tea_req ntr
                     WHERE ntr.id_patient = i_id_patient) t
                ON t.id_episode = ntr.id_episode
             WHERE ntr.flg_status NOT IN (pk_patient_education_constant.g_nurse_tea_req_draft)
               AND EXISTS (SELECT 1
                      FROM nurse_tea_det n
                     WHERE n.id_nurse_tea_req = ntr.id_nurse_tea_req
                       AND n.flg_status = pk_patient_education_constant.g_nurse_tea_det_exec);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_cursor_if_closed(o_list);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PATIENT_EDUCATION_ALL_LIST',
                                              o_error);
        
            RETURN FALSE;
    END get_patient_education_all_list;

    PROCEDURE init_params_grid
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_keys  IN table_varchar DEFAULT NULL,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        g_lang             CONSTANT NUMBER(24) := 1;
        g_prof_id          CONSTANT NUMBER(24) := 2;
        g_prof_institution CONSTANT NUMBER(24) := 3;
        g_prof_software    CONSTANT NUMBER(24) := 4;
        g_episode          CONSTANT NUMBER(24) := 5;
        l_lang             CONSTANT language.id_language%TYPE := i_context_ids(g_lang);
        l_prof             CONSTANT profissional := profissional(i_context_ids(g_prof_id),
                                                                 i_context_ids(g_prof_institution),
                                                                 i_context_ids(g_prof_software));
    
        l_episode episode.id_episode%TYPE := i_context_ids(g_episode);
    
        l_has_notes        sys_message.desc_message%TYPE;
        l_begin            sys_message.desc_message%TYPE;
        l_label_notes_req  sys_message.desc_message%TYPE;
        l_label_cancel_req sys_message.desc_message%TYPE;
    
        l_flg_can_edit   VARCHAR2(1 CHAR) := pk_alert_constant.g_yes;
        l_id_req_hhc     episode.id_episode%TYPE;
        l_tbl_id_episode table_number;
        l_epis_type      epis_type.id_epis_type%TYPE;
        l_i_id_hhc_req   epis_hhc_req.id_epis_hhc_req%TYPE;
        l_episode_split  VARCHAR2(1000 CHAR);
    
        --FILTER_BIND
        g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    
        o_error t_error_out;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        IF i_context_vals.count > 0
        THEN
            l_id_req_hhc := i_context_vals(1);
        END IF;
    
        -- MENSAGENS 
        l_has_notes := pk_message.get_message(i_lang => l_lang, i_prof => l_prof, i_code_mess => 'COMMON_M097');
    
        l_begin := pk_message.get_message(i_lang => l_lang, i_prof => l_prof, i_code_mess => 'PROCEDURES_T016') || ': ';
    
        l_label_notes_req := pk_message.get_message(i_lang      => l_lang,
                                                    i_prof      => l_prof,
                                                    i_code_mess => 'PATIENT_EDUCATION_M012');
    
        l_label_cancel_req := pk_message.get_message(i_lang      => l_lang,
                                                     i_prof      => l_prof,
                                                     i_code_mess => 'PATIENT_EDUCATION_M033');
    
        SELECT t.id_episode
          BULK COLLECT
          INTO l_tbl_id_episode
          FROM (SELECT e.id_episode
                  FROM episode e
                 WHERE e.id_visit = pk_episode.get_id_visit(l_episode)
                UNION
                SELECT e.id_episode
                  FROM episode e
                 WHERE e.id_prev_episode IN (SELECT ehr.id_epis_hhc
                                               FROM alert.epis_hhc_req ehr
                                              WHERE ehr.id_episode = l_episode
                                                 OR ehr.id_epis_hhc_req = l_id_req_hhc)
                UNION
                SELECT ehr.id_epis_hhc
                  FROM alert.epis_hhc_req ehr
                 WHERE ehr.id_episode = l_episode
                    OR ehr.id_epis_hhc_req = l_id_req_hhc) t;
    
        IF l_episode IS NOT NULL
        THEN
            IF NOT pk_episode.get_epis_type(i_lang      => l_lang,
                                            i_id_epis   => l_episode,
                                            o_epis_type => l_epis_type,
                                            o_error     => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        IF l_epis_type IN (pk_alert_constant.g_epis_type_home_health_care, 99)
           OR l_id_req_hhc IS NOT NULL
        THEN
        
            l_i_id_hhc_req := nvl(l_id_req_hhc,
                                  pk_hhc_core.get_id_epis_hhc_req_by_pat(i_id_patient => pk_episode.get_id_patient(l_episode)));
        
            IF NOT pk_hhc_ux.get_prof_can_edit(i_lang         => l_lang,
                                               i_prof         => l_prof,
                                               i_id_hhc_req   => l_i_id_hhc_req,
                                               o_flg_can_edit => l_flg_can_edit,
                                               o_error        => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        l_episode_split := pk_utils.to_string(l_tbl_id_episode);
    
        pk_context_api.set_parameter('i_lang', l_lang);
        pk_context_api.set_parameter('i_prof_id', l_prof.id);
        pk_context_api.set_parameter('i_prof_institution', l_prof.institution);
        pk_context_api.set_parameter('i_prof_software', l_prof.software);
        pk_context_api.set_parameter('l_episodes', l_episode_split);
    
        g_error := 'PK_TECH_IMAGE, parameter:' || i_name || ' not found';
        CASE i_name
            WHEN 'lang' THEN
                o_vc2 := to_char(l_lang);
            WHEN 'l_has_notes' THEN
                o_vc2 := l_has_notes;
            WHEN 'l_label_notes_req' THEN
                o_vc2 := l_label_notes_req;
            WHEN 'l_label_cacel_req' THEN
                o_vc2 := l_label_cancel_req;
            WHEN 'l_begin' THEN
                o_vc2 := l_begin;
            WHEN 'l_flg_can_edit' THEN
                o_vc2 := l_flg_can_edit;
                NULL;
        END CASE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => l_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_PATIENT_EDUCATION_UX',
                                              i_function => 'INIT_PARAMS_GRID',
                                              o_error    => o_error);
    END init_params_grid;

    PROCEDURE init_params_topic_list
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_keys  IN table_varchar DEFAULT NULL,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        g_lang             CONSTANT NUMBER(24) := 1;
        g_prof_id          CONSTANT NUMBER(24) := 2;
        g_prof_institution CONSTANT NUMBER(24) := 3;
        g_prof_software    CONSTANT NUMBER(24) := 4;
        g_episode          CONSTANT NUMBER(24) := 5;
        l_lang             CONSTANT language.id_language%TYPE := i_context_ids(g_lang);
        l_prof             CONSTANT profissional := profissional(i_context_ids(g_prof_id),
                                                                 i_context_ids(g_prof_institution),
                                                                 i_context_ids(g_prof_software));
    
        l_episode         episode.id_episode%TYPE := i_context_ids(g_episode);
        l_id_market       market.id_market%TYPE;
        l_flg_show_others VARCHAR2(1 CHAR) := 'Y';
        l_id_subject      NUMBER(24);
        l_most_frequent   VARCHAR2(1 CHAR) := 'Y';
    
        l_prof_dep_clin_serv table_number;
        l_dcs_split          VARCHAR2(1000 CHAR);
        --FILTER_BIND
        g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    
        o_error t_error_out;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        /*IF i_context_vals.count > 0
        THEN
            l_id_req_hhc := i_context_vals(1);
        END IF;*/
    
        l_id_market := pk_utils.get_institution_market(i_lang => l_lang, i_id_institution => l_prof.institution);
    
        pk_context_api.set_parameter('i_lang', l_lang);
        pk_context_api.set_parameter('i_prof_id', l_prof.id);
        pk_context_api.set_parameter('i_prof_institution', l_prof.institution);
        pk_context_api.set_parameter('i_prof_software', l_prof.software);
        pk_context_api.set_parameter('l_id_market', l_id_market);
        pk_context_api.set_parameter('i_flg_show_others', l_flg_show_others);
        pk_context_api.set_parameter('i_id_subject', l_id_subject);
        pk_context_api.set_parameter('i_most_frequent', l_most_frequent);
    
        g_error := 'PK_TECH_IMAGE, parameter:' || i_name || ' not found';
        CASE i_name
            WHEN 'lang' THEN
                o_vc2 := to_char(l_lang);
            ELSE
                NULL;
        END CASE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => l_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_PATIENT_EDUCATION_UX',
                                              i_function => 'INIT_PARAMS_TOPIC_LIST',
                                              o_error    => o_error);
    END init_params_topic_list;

    FUNCTION check_nurse_teach_conflict
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_nurse_tea_topic IN nurse_tea_topic.id_nurse_tea_topic%TYPE,
        o_flg_conflict    OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_count     PLS_INTEGER;
        l_id_market market.id_market%TYPE := pk_prof_utils.get_prof_market(i_prof);
    
    BEGIN
    
        SELECT COUNT(1)
          INTO l_count
          FROM nurse_tea_topic ntt
          JOIN nurse_tea_subject nts
            ON nts.id_nurse_tea_subject = ntt.id_nurse_tea_subject
         WHERE nts.flg_available = pk_alert_constant.g_yes
           AND ntt.flg_available = pk_alert_constant.g_yes
           AND ntt.id_nurse_tea_topic = i_nurse_tea_topic
           AND EXISTS (SELECT nttsi.id_nurse_tea_topic
                  FROM nurse_tea_top_soft_inst nttsi
                 WHERE rownum > 0
                   AND nttsi.flg_type = pk_patient_education_constant.g_nurse_tea_searchable
                   AND nttsi.id_nurse_tea_topic = ntt.id_nurse_tea_topic
                   AND nttsi.flg_available = pk_alert_constant.g_yes
                   AND nttsi.id_software IN (0, i_prof.software)
                   AND nttsi.id_institution IN (0, i_prof.institution)
                   AND nttsi.id_market IN (0, l_id_market)
                   AND pk_translation.get_translation(i_lang, ntt.code_nurse_tea_topic) IS NOT NULL
                MINUS
                SELECT nttsi.id_nurse_tea_topic
                  FROM nurse_tea_top_soft_inst nttsi
                 WHERE rownum > 0
                   AND nttsi.flg_type = pk_patient_education_constant.g_nurse_tea_searchable
                   AND nttsi.id_nurse_tea_topic = ntt.id_nurse_tea_topic
                   AND nttsi.flg_available = pk_alert_constant.g_no
                   AND nttsi.id_software IN (0, i_prof.software)
                   AND nttsi.id_institution IN (0, i_prof.institution)
                   AND nttsi.id_market IN (0, l_id_market));
    
        IF l_count > 0
        THEN
            o_flg_conflict := pk_alert_constant.g_no;
        ELSE
            o_flg_conflict := pk_alert_constant.g_yes;
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
                                              'CHECK_NURSE_TEACH_CONFLICT',
                                              o_error);
        
            RETURN FALSE;
    END check_nurse_teach_conflict;

    FUNCTION get_he_order_values
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER, -- edit, new, submit
        i_root_name      IN VARCHAR2, -- root of dynamic screen
        i_curr_component IN NUMBER,
        i_idx            IN NUMBER DEFAULT 1,
        i_tbl_id_pk      IN table_number, -- id necessary for identifying pk for editing
        i_tbl_mkt_rel    IN table_number, -- components needed for default/edit
        i_tbl_int_name   IN table_varchar,
        i_value          IN table_table_varchar,
        i_value_mea      IN table_table_varchar,
        i_value_desc     IN table_table_varchar,
        i_value_clob     IN table_clob,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value IS
        tbl_result t_tbl_ds_get_value := t_tbl_ds_get_value();
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_HE_ORDER_VALUES';
    
        l_value_to_be_executed      VARCHAR2(4000);
        l_value_to_be_executed_desc VARCHAR2(4000);
        l_description               CLOB;
    
        l_curr_comp_int_name ds_component.internal_name%TYPE;
    
        --RECURRENCE
        l_order_recurr_desc          VARCHAR2(4000);
        l_order_recurr_option        order_recurr_plan.id_order_recurr_option%TYPE;
        l_order_recurr_option_aux    order_recurr_plan.id_order_recurr_option%TYPE;
        l_start_date                 order_recurr_plan.start_date%TYPE;
        l_occurrences                order_recurr_plan.occurrences%TYPE;
        l_duration                   order_recurr_plan.duration%TYPE;
        l_unit_meas_duration         order_recurr_plan.id_unit_meas_duration%TYPE;
        l_duration_desc              VARCHAR2(4000);
        l_end_date                   order_recurr_plan.end_date%TYPE;
        l_flg_end_by_editable        VARCHAR2(1);
        l_order_recurr_plan          order_recurr_plan.id_order_recurr_plan%TYPE;
        l_order_recurr_plan_original order_recurr_plan.id_order_recurr_plan%TYPE;
        l_timestamp_start            VARCHAR2(4000);
        l_timestamp_end              VARCHAR2(4000);
    
        --Frequency selected on the form
        l_recurrence_form_value VARCHAR2(100);
    
        --RECURRENC OTHER        
        l_regular_interval    order_recurr_plan.regular_interval%TYPE;
        l_regulat_interval_um NUMBER(24);
        l_daily_executions    order_recurr_plan.daily_executions%TYPE;
    
        l_predef_time_sched_desc VARCHAR2(500);
        l_exec_time              VARCHAR2(500);
        l_exec_time_desc         VARCHAR2(500);
        l_exec_time_option       NUMBER(24);
        l_recurr_pattern_desc    VARCHAR2(500);
        l_repeat_every_desc      VARCHAR2(500);
        l_start_date_str         VARCHAR2(500);
        l_end_by_desc            VARCHAR2(500);
    
        l_start VARCHAR2(500);
        l_end   VARCHAR2(500);
    
        l_ds_internal_name   ds_component.internal_name%TYPE;
        l_id_ds_component    ds_component.id_ds_component%TYPE;
        l_id_ds_cmpt_mkt_rel ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE;
    
        l_flg_recurr_pattern     order_recurr_plan.flg_recurr_pattern%TYPE;
        l_repeat_every           order_recurr_plan.repeat_every%TYPE;
        l_unit_meas_repeat_every unit_measure.id_unit_measure%TYPE;
        l_flg_end_by             order_recurr_plan.flg_end_by%TYPE;
    
        --Clinical indication
        l_clinical_indication_mandatory sys_config.value%TYPE := pk_alert_constant.g_no;
        l_clinical_purpose_mandatory    sys_config.value%TYPE := pk_alert_constant.g_no;
    
        l_tbl_id_prof_req       table_number;
        l_tbl_prof_req_category table_varchar := table_varchar();
        l_prof_category         category.flg_type%TYPE;
        l_tbl_id_nurse_tea_req  table_number;
    
        l_tbl_id_diag            table_number;
        l_tbl_id_alert_diagnosis table_number;
        l_tbl_diag_desc          table_varchar;
    
        l_flg_event_type VARCHAR2(1);
    
        l_episode_dt_begin episode.dt_begin_tstz%TYPE;
        l_flg_dt_begin     VARCHAR2(1 CHAR);
    
        PROCEDURE process_ok_button_control
        (
            i_id_ds_cmpt_mkt_rel IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
            i_id_ds_component    IN ds_component.id_ds_component%TYPE,
            i_ds_internal_name   IN ds_component.internal_name%TYPE
        ) IS
            l_ok_status VARCHAR2(1) := pk_orders_constant.g_component_valid;
        BEGIN
            FOR j IN tbl_result.first .. tbl_result.last
            LOOP
                IF (tbl_result(j).flg_event_type = pk_orders_constant.g_component_mandatory AND tbl_result(j).value IS NULL)
                   OR tbl_result(j).flg_validation = pk_orders_constant.g_component_error
                THEN
                    l_ok_status := pk_orders_constant.g_component_error;
                END IF;
            END LOOP;
        
            tbl_result.extend();
            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_id_ds_cmpt_mkt_rel,
                                                               id_ds_component    => i_id_ds_component,
                                                               internal_name      => i_ds_internal_name,
                                                               VALUE              => NULL,
                                                               value_clob         => NULL,
                                                               min_value          => NULL,
                                                               max_value          => NULL,
                                                               desc_value         => NULL,
                                                               desc_clob          => NULL,
                                                               id_unit_measure    => NULL,
                                                               desc_unit_measure  => NULL,
                                                               flg_validation     => l_ok_status,
                                                               err_msg            => NULL,
                                                               flg_event_type     => pk_orders_constant.g_component_active,
                                                               flg_multi_status   => NULL,
                                                               idx                => i_idx);
        EXCEPTION
            WHEN OTHERS THEN
                pk_alertlog.log_error(SQLCODE || ' ' || SQLERRM || ' ' || g_error);
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  'PROCESS_OK_BUTTON_CONTROL',
                                                  o_error);
            
        END process_ok_button_control;
    
    BEGIN
        g_sysdate_tstz := nvl(g_sysdate_tstz, current_timestamp);
    
        IF i_action IS NULL
        THEN
            --NEW FORM (default values)
            IF NOT get_default_domain_time(i_lang     => i_lang,
                                           i_prof     => i_prof,
                                           o_val      => l_value_to_be_executed,
                                           o_desc_val => l_value_to_be_executed_desc,
                                           o_error    => o_error)
            THEN
                g_error := 'error found while calling pk_patient_education_constant.g_et_default_domain_time function';
                RAISE g_exception;
            END IF;
        
            IF i_idx = 1
            THEN
                --Obtaining the recurrence and the default values for the following fields:
                --FREQUENCY
                --START DATE
                --EXECUTIONS
                --DURATION
                --END DATE   
                IF NOT pk_order_recurrence_core.create_order_recurr_plan(i_lang                => i_lang,
                                                                         i_prof                => i_prof,
                                                                         i_order_recurr_area   => 'PATIENT_EDUCATION',
                                                                         o_order_recurr_desc   => l_order_recurr_desc,
                                                                         o_order_recurr_option => l_order_recurr_option,
                                                                         o_start_date          => l_start_date,
                                                                         o_occurrences         => l_occurrences,
                                                                         o_duration            => l_duration,
                                                                         o_unit_meas_duration  => l_unit_meas_duration,
                                                                         o_end_date            => l_end_date,
                                                                         o_flg_end_by_editable => l_flg_end_by_editable,
                                                                         o_order_recurr_plan   => l_order_recurr_plan,
                                                                         o_error               => o_error)
                THEN
                    g_error := 'error found while calling pk_order_recurrence_core.create_order_recurr_plan function';
                    RAISE g_exception;
                END IF;
            
                l_order_recurr_plan_original := l_order_recurr_plan;
            
                --A recorr�ncia � gerada apenas no 1� registo do carrinho, como tal,
                --� necess�rio guardar este valor numa vari�vel de contexto, para que
                --os registos seguintes consigam utilizar esse valor
                pk_context_api.set_parameter(p_name  => 'l_order_recurr_plan_original',
                                             p_value => l_order_recurr_plan_original);
            ELSE
                --Quando o i_idx>1, � necess�rio obter o id_order_recurrence gerado para o 1� registo
                SELECT to_number(alert_context('l_order_recurr_plan_original'))
                  INTO l_order_recurr_plan_original
                  FROM dual;
            
                IF l_order_recurr_plan_original IS NOT NULL
                THEN
                    IF NOT pk_order_recurrence_core.copy_order_recurr_plan(i_lang                   => i_lang,
                                                                           i_prof                   => i_prof,
                                                                           i_order_recurr_plan_from => l_order_recurr_plan_original,
                                                                           o_order_recurr_desc      => l_order_recurr_desc,
                                                                           o_order_recurr_option    => l_order_recurr_option,
                                                                           o_start_date             => l_start_date,
                                                                           o_occurrences            => l_occurrences,
                                                                           o_duration               => l_duration,
                                                                           o_unit_meas_duration     => l_unit_meas_duration,
                                                                           o_end_date               => l_end_date,
                                                                           o_flg_end_by_editable    => l_flg_end_by_editable,
                                                                           o_order_recurr_plan      => l_order_recurr_plan,
                                                                           o_error                  => o_error)
                    THEN
                        g_error := 'error found while calling pk_order_recurrence_core.copy_order_recurr_plan function';
                        RAISE g_exception;
                    END IF;
                END IF;
            END IF;
        
            --GETING THE VALUES THAT ARE COMMON TO ALL FORMS (FREQUENCY, START DATE, ETC.)
            SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => t.id_ds_cmpt_mkt_rel,
                                       id_ds_component    => t.id_ds_component_child,
                                       internal_name      => t.internal_name_child,
                                       VALUE              => CASE
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_to_be_executed THEN
                                                                  l_value_to_be_executed
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_start_date THEN
                                                                  CASE
                                                                      WHEN i_root_name IN ('DS_OTHER_FREQUENCIES', 'DS_TO_EXECUTE') THEN
                                                                       l_start
                                                                      ELSE
                                                                       pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => l_start_date, i_prof => i_prof)
                                                                  END
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_dummy_number THEN
                                                                  to_char(l_order_recurr_plan)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_frequency THEN
                                                                  to_char(l_order_recurr_option)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_executions THEN
                                                                  to_char(l_occurrences)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_duration THEN
                                                                  to_char(l_duration)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_end_date THEN
                                                                  pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => l_end_date, i_prof => i_prof)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_daily_executions THEN
                                                                  to_char(l_daily_executions)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_end_based THEN
                                                                  l_flg_end_by
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_end_after THEN
                                                                  l_end
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_end_after_n THEN
                                                                  to_char(coalesce(l_occurrences, l_duration))
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_recurrence_pattern THEN
                                                                  l_flg_recurr_pattern
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_repeat_every THEN
                                                                  to_char(l_repeat_every)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_regular_intervals THEN
                                                                  to_char(l_regular_interval)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_time_schedule THEN
                                                                  to_char(l_exec_time_option)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_exact_time THEN
                                                                  l_exec_time
                                                                 ELSE
                                                                  NULL
                                                             END,
                                       value_clob         => NULL,
                                       min_value          => NULL,
                                       max_value          => NULL,
                                       desc_value         => CASE
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_dummy_number THEN
                                                                  to_char(l_order_recurr_plan)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_to_be_executed THEN
                                                                  l_value_to_be_executed_desc
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_frequency THEN
                                                                  l_order_recurr_desc
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_executions THEN
                                                                  to_char(l_occurrences)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_duration THEN
                                                                  CASE
                                                                      WHEN l_duration IS NOT NULL THEN
                                                                       to_char(l_duration) || ' ' ||
                                                                       pk_unit_measure.get_unit_measure_description(i_lang         => i_lang,
                                                                                                                    i_prof         => i_prof,
                                                                                                                    i_unit_measure => l_unit_meas_duration)
                                                                  END
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_end_date THEN
                                                                  pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => l_end_date, i_prof => i_prof)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_daily_executions THEN
                                                                  to_char(l_daily_executions)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_end_based THEN
                                                                  l_end_by_desc
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_recurrence_pattern THEN
                                                                  l_recurr_pattern_desc
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_repeat_every THEN
                                                                  to_char(l_repeat_every) || ' ' ||
                                                                  pk_unit_measure.get_unit_measure_description(i_lang         => i_lang,
                                                                                                               i_prof         => i_prof,
                                                                                                               i_unit_measure => l_unit_meas_repeat_every)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_end_after_n THEN
                                                                  to_char(coalesce(l_occurrences, l_duration)) || ' ' ||
                                                                  pk_unit_measure.get_unit_measure_description(i_lang         => i_lang,
                                                                                                               i_prof         => i_prof,
                                                                                                               i_unit_measure => l_unit_meas_duration)
                                                             
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_regular_intervals THEN
                                                                  decode(l_regular_interval,
                                                                         NULL,
                                                                         NULL,
                                                                         to_char(l_regular_interval) || ' ' ||
                                                                         pk_unit_measure.get_unit_measure_description(i_lang         => i_lang,
                                                                                                                      i_prof         => i_prof,
                                                                                                                      i_unit_measure => l_regulat_interval_um))
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_time_schedule THEN
                                                                  l_predef_time_sched_desc
                                                                 ELSE
                                                                  NULL
                                                             END,
                                       desc_clob          => NULL,
                                       id_unit_measure    => t.id_unit_measure,
                                       desc_unit_measure  => CASE
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_duration THEN
                                                                  pk_unit_measure.get_unit_measure_description(i_lang         => i_lang,
                                                                                                               i_prof         => i_prof,
                                                                                                               i_unit_measure => l_unit_meas_duration)
                                                                 WHEN t.id_unit_measure IS NOT NULL THEN
                                                                  pk_unit_measure.get_unit_measure_description(i_lang         => i_lang,
                                                                                                               i_prof         => i_prof,
                                                                                                               i_unit_measure => t.id_unit_measure)
                                                                 ELSE
                                                                  NULL
                                                             END,
                                       flg_validation     => pk_orders_constant.g_component_valid,
                                       err_msg            => NULL,
                                       flg_event_type     => coalesce(def.flg_event_type,
                                                                      CASE
                                                                          WHEN t.internal_name_child IN
                                                                               (pk_orders_constant.g_ds_duration, pk_orders_constant.g_ds_end_date) THEN
                                                                          --If l_flg_end_by_editable = 'N', fields duration and end date must be inactive
                                                                           decode(l_flg_end_by_editable,
                                                                                  pk_alert_constant.g_yes,
                                                                                  pk_orders_constant.g_component_active,
                                                                                  'I')
                                                                          WHEN t.internal_name_child IN (pk_orders_constant.g_ds_executions) THEN
                                                                          --If l_flg_end_by_editable = 'N', field 'Exections' must be Read Only and present the value given by l_occurrences
                                                                           decode(l_flg_end_by_editable,
                                                                                  pk_alert_constant.g_yes,
                                                                                  pk_orders_constant.g_component_active,
                                                                                  pk_orders_constant.g_component_read_only)
                                                                          WHEN t.internal_name_child IN (pk_orders_constant.g_ds_clinical_indication_mw) THEN
                                                                           CASE l_clinical_indication_mandatory
                                                                               WHEN pk_alert_constant.g_yes THEN
                                                                                pk_orders_constant.g_component_mandatory
                                                                               ELSE
                                                                                pk_orders_constant.g_component_active
                                                                           END
                                                                          WHEN t.internal_name_child IN (pk_orders_constant.g_ds_clinical_purpose) THEN
                                                                           CASE l_clinical_purpose_mandatory
                                                                               WHEN pk_alert_constant.g_yes THEN
                                                                                pk_orders_constant.g_component_mandatory
                                                                               ELSE
                                                                                pk_orders_constant.g_component_active
                                                                           END
                                                                          WHEN t.internal_name_child = pk_orders_constant.g_ds_end_after THEN
                                                                           CASE
                                                                               WHEN l_flg_end_by = 'D' THEN
                                                                                pk_orders_constant.g_component_active
                                                                               ELSE
                                                                                pk_orders_constant.g_component_inactive
                                                                           END
                                                                          WHEN t.internal_name_child = pk_orders_constant.g_ds_end_after_n THEN
                                                                           CASE
                                                                               WHEN l_flg_end_by IN ('L', 'N') THEN
                                                                                pk_orders_constant.g_component_active
                                                                               ELSE
                                                                                pk_orders_constant.g_component_inactive
                                                                           END
                                                                          WHEN t.internal_name_child NOT IN (pk_orders_constant.g_ds_start_date) THEN
                                                                           pk_orders_constant.g_component_active
                                                                      END),
                                       flg_multi_status   => pk_alert_constant.g_no,
                                       idx                => i_idx)
              BULK COLLECT
              INTO tbl_result
              FROM (SELECT dc.id_ds_cmpt_mkt_rel,
                           dc.id_ds_component_child,
                           dc.internal_name_child,
                           dc.flg_event_type,
                           dc.rn,
                           dc.flg_component_type_child,
                           dc.id_unit_measure
                      FROM TABLE(pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                         i_prof           => i_prof,
                                                         i_patient        => NULL,
                                                         i_component_name => i_root_name,
                                                         i_action         => NULL)) dc) t
              JOIN ds_component d
                ON d.id_ds_component = t.id_ds_component_child
              LEFT JOIN ds_def_event def
                ON def.id_ds_cmpt_mkt_rel = t.id_ds_cmpt_mkt_rel
             WHERE d.internal_name IN (pk_orders_constant.g_ds_clinical_indication_mw,
                                       pk_orders_constant.g_ds_to_be_executed,
                                       pk_orders_constant.g_ds_frequency,
                                       pk_orders_constant.g_ds_start_date,
                                       pk_orders_constant.g_ds_executions,
                                       pk_orders_constant.g_ds_duration,
                                       pk_orders_constant.g_ds_end_date,
                                       pk_orders_constant.g_ds_dummy_number,
                                       pk_orders_constant.g_ds_ok_button_control)
             ORDER BY t.rn;
        
            SELECT dc.id_ds_component
              INTO l_id_ds_component
              FROM ds_component dc
             WHERE dc.internal_name = pk_orders_constant.g_ds_description;
        
            l_id_ds_cmpt_mkt_rel := pk_orders_utils.get_ds_cmpt_mkt_rel(pk_orders_constant.g_ds_description,
                                                                        i_tbl_mkt_rel);
        
            l_description := pk_patient_education_utils.get_subject(i_lang     => i_lang,
                                                                    i_prof     => i_prof,
                                                                    i_id_topic => i_tbl_id_pk(i_idx));
            IF l_description IS NOT NULL
            THEN
                tbl_result.extend();
                tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => l_id_ds_cmpt_mkt_rel,
                                                                   id_ds_component    => l_id_ds_component,
                                                                   internal_name      => pk_orders_constant.g_ds_description,
                                                                   VALUE              => NULL,
                                                                   value_clob         => l_description,
                                                                   min_value          => NULL,
                                                                   max_value          => NULL,
                                                                   desc_value         => NULL,
                                                                   desc_clob          => l_description,
                                                                   id_unit_measure    => NULL,
                                                                   desc_unit_measure  => NULL,
                                                                   flg_validation     => pk_orders_constant.g_component_valid,
                                                                   err_msg            => NULL,
                                                                   flg_event_type     => pk_orders_constant.g_component_active,
                                                                   flg_multi_status   => NULL,
                                                                   idx                => i_idx);
            END IF;
        ELSIF i_action = pk_dyn_form_constant.get_submit_action
        THEN
            --Action of submiting a value on any given element of the form
            --In order for this action to be executed, a submit action must be configured in ds_event for the given field.
            IF i_curr_component IS NOT NULL
            THEN
                --Check which element has been changed
                SELECT d.internal_name_child
                  INTO l_curr_comp_int_name
                  FROM ds_cmpt_mkt_rel d
                 WHERE d.id_ds_cmpt_mkt_rel = i_curr_component;
            
                IF l_curr_comp_int_name = pk_orders_constant.g_ds_frequency --Frequency field
                THEN
                    --Obtain the id order recurr plan which is stored in DS_DUMMY_NUMBER element
                    --DS_DUMMY_NUMBER is an hidden field of the form. The reccurence id is stored in this element
                    --when the form is initialized                
                    FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                    LOOP
                        l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
                    
                        IF l_ds_internal_name = pk_orders_constant.g_ds_frequency
                        THEN
                            --Obtain the id for the recurr_option (value selected from the frequency field)   
                            l_order_recurr_option := to_number(i_value(i) (1));
                        END IF;
                    END LOOP;
                
                    FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                    LOOP
                        l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
                    
                        IF l_ds_internal_name = pk_orders_constant.g_ds_dummy_number
                        THEN
                            l_order_recurr_plan := to_number(i_value(i) (1));
                        END IF;
                    END LOOP;
                
                    --Obtain the values for End_date/Duration/Execution according to the selected frequency
                    IF l_order_recurr_option <> -1 --When frequency is not set as 'Other frequency'
                    THEN
                        IF NOT pk_order_recurrence_core.set_order_recurr_option(i_lang                => i_lang,
                                                                                i_prof                => i_prof,
                                                                                i_order_recurr_plan   => l_order_recurr_plan,
                                                                                i_order_recurr_option => l_order_recurr_option,
                                                                                o_order_recurr_desc   => l_order_recurr_desc,
                                                                                o_start_date          => l_start_date,
                                                                                o_occurrences         => l_occurrences,
                                                                                o_duration            => l_duration,
                                                                                o_unit_meas_duration  => l_unit_meas_duration,
                                                                                o_end_date            => l_end_date,
                                                                                o_flg_end_by_editable => l_flg_end_by_editable,
                                                                                o_error               => o_error)
                        THEN
                            g_error := 'Error found while calling pk_order_recurrence_core.set_order_recurr_option function';
                            RAISE g_exception;
                        END IF;
                        l_order_recurr_option_aux := l_order_recurr_option;
                    ELSE
                        --Frequency set as 'Other frequency'
                        IF NOT
                            pk_order_recurrence_core.get_order_recurr_instructions(i_lang                => i_lang,
                                                                                   i_prof                => i_prof,
                                                                                   i_order_plan          => l_order_recurr_plan,
                                                                                   o_order_recurr_desc   => l_order_recurr_desc,
                                                                                   o_order_recurr_option => l_order_recurr_option,
                                                                                   o_start_date          => l_start_date,
                                                                                   o_occurrences         => l_occurrences,
                                                                                   o_duration            => l_duration,
                                                                                   o_unit_meas_duration  => l_unit_meas_duration,
                                                                                   o_end_date            => l_end_date,
                                                                                   o_flg_end_by_editable => l_flg_end_by_editable,
                                                                                   o_error               => o_error)
                        THEN
                            g_error := 'error while calling get_order_recurr_instructions function';
                            RAISE g_exception;
                        END IF;
                    
                        l_order_recurr_option_aux := l_order_recurr_option;
                    
                        FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                        LOOP
                            l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
                        
                            IF l_ds_internal_name = pk_orders_constant.g_ds_frequency
                            THEN
                                l_order_recurr_option := to_number(i_value(i) (1));
                                l_order_recurr_desc   := i_value_desc(i) (1);
                            END IF;
                        END LOOP;
                    END IF;
                ELSIF l_curr_comp_int_name = pk_orders_constant.g_ds_start_date
                THEN
                    FOR i IN i_tbl_int_name.first .. i_tbl_int_name.last
                    LOOP
                        IF i_tbl_int_name(i) = pk_orders_constant.g_ds_dummy_number
                        THEN
                            l_order_recurr_plan := to_number(i_value(i) (1));
                        ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_start_date
                        THEN
                            l_timestamp_start := i_value(i) (1);
                        ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_executions
                        THEN
                            l_occurrences := to_number(i_value(i) (1));
                        ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_duration
                        THEN
                            l_duration           := to_number(i_value(i) (1));
                            l_unit_meas_duration := to_number(i_value_mea(i) (1));
                        ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_end_date
                        THEN
                            l_timestamp_end := i_value(i) (1);
                        END IF;
                    END LOOP;
                
                    --If we set the number of executions then the field Duration must be null and vice-versa.
                    IF NOT pk_order_recurrence_core.set_order_recurr_instructions(i_lang                => i_lang,
                                                                                  i_prof                => i_prof,
                                                                                  i_order_recurr_plan   => l_order_recurr_plan,
                                                                                  i_start_date          => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                         i_prof,
                                                                                                                                         l_timestamp_start,
                                                                                                                                         NULL),
                                                                                  i_occurrences         => l_occurrences,
                                                                                  i_duration            => l_duration,
                                                                                  i_unit_meas_duration  => l_unit_meas_duration,
                                                                                  i_end_date            => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                         i_prof,
                                                                                                                                         l_timestamp_end,
                                                                                                                                         NULL),
                                                                                  o_order_recurr_desc   => l_order_recurr_desc,
                                                                                  o_start_date          => l_start_date,
                                                                                  o_order_recurr_option => l_order_recurr_option,
                                                                                  o_occurrences         => l_occurrences,
                                                                                  o_duration            => l_duration,
                                                                                  o_unit_meas_duration  => l_unit_meas_duration,
                                                                                  o_end_date            => l_end_date,
                                                                                  o_flg_end_by_editable => l_flg_end_by_editable,
                                                                                  o_error               => o_error)
                    THEN
                        g_error := 'Error found while calling pk_order_recurrence_core.set_order_recurr_instructions function';
                        RAISE g_exception;
                    END IF;
                
                    l_order_recurr_option_aux := l_order_recurr_option;
                
                ELSIF l_curr_comp_int_name IN (pk_orders_constant.g_ds_executions,
                                               pk_orders_constant.g_ds_duration,
                                               pk_orders_constant.g_ds_end_date)
                THEN
                    --If we set the number of executions then the field Duration must be null and vice-versa.                                              
                    FOR i IN i_tbl_int_name.first .. i_tbl_int_name.last
                    LOOP
                        IF i_tbl_int_name(i) = pk_orders_constant.g_ds_dummy_number
                        THEN
                            l_order_recurr_plan := to_number(i_value(i) (1));
                        ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_executions
                              AND l_curr_comp_int_name != pk_orders_constant.g_ds_duration
                        THEN
                            l_occurrences := to_number(i_value(i) (1));
                        ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_start_date
                        THEN
                            l_timestamp_start := i_value(i) (1);
                        ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_end_date
                        THEN
                            l_timestamp_end := i_value(i) (1);
                        ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_duration
                              AND l_curr_comp_int_name != pk_orders_constant.g_ds_executions
                        THEN
                            l_duration           := to_number(i_value(i) (1));
                            l_unit_meas_duration := to_number(i_value_mea(i) (1));
                        END IF;
                    END LOOP;
                
                    IF NOT pk_order_recurrence_core.set_order_recurr_instructions(i_lang                => i_lang,
                                                                                  i_prof                => i_prof,
                                                                                  i_order_recurr_plan   => l_order_recurr_plan,
                                                                                  i_start_date          => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                         i_prof,
                                                                                                                                         l_timestamp_start,
                                                                                                                                         NULL),
                                                                                  i_occurrences         => l_occurrences,
                                                                                  i_duration            => l_duration,
                                                                                  i_unit_meas_duration  => l_unit_meas_duration,
                                                                                  i_end_date            => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                         i_prof,
                                                                                                                                         l_timestamp_end,
                                                                                                                                         NULL),
                                                                                  o_order_recurr_desc   => l_order_recurr_desc,
                                                                                  o_start_date          => l_start_date,
                                                                                  o_order_recurr_option => l_order_recurr_option,
                                                                                  o_occurrences         => l_occurrences,
                                                                                  o_duration            => l_duration,
                                                                                  o_unit_meas_duration  => l_unit_meas_duration,
                                                                                  o_end_date            => l_end_date,
                                                                                  o_flg_end_by_editable => l_flg_end_by_editable,
                                                                                  o_error               => o_error)
                    THEN
                        g_error := 'Error found while calling pk_order_recurrence_core.set_order_recurr_instructions function';
                        RAISE g_exception;
                    END IF;
                
                    l_order_recurr_option_aux := l_order_recurr_option;
                
                    IF l_curr_comp_int_name IN (pk_orders_constant.g_ds_executions, pk_orders_constant.g_ds_duration)
                    THEN
                        IF l_duration IS NULL
                           AND l_occurrences IS NULL
                        THEN
                            l_end_date := NULL;
                        END IF;
                    END IF;
                ELSIF l_curr_comp_int_name IN (pk_orders_constant.g_ds_other_frequency)
                THEN
                    l_order_recurr_plan := to_number(pk_orders_utils.get_value(pk_orders_constant.g_ds_dummy_number,
                                                                               i_tbl_mkt_rel,
                                                                               i_value));
                    --If we set the number of executions then the field Duration must be null and vice-versa.
                    IF NOT pk_order_recurrence_core.get_order_recurr_instructions(i_lang                => i_lang,
                                                                                  i_prof                => i_prof,
                                                                                  i_order_plan          => l_order_recurr_plan,
                                                                                  o_order_recurr_desc   => l_order_recurr_desc,
                                                                                  o_order_recurr_option => l_order_recurr_option,
                                                                                  o_start_date          => l_start_date,
                                                                                  o_occurrences         => l_occurrences,
                                                                                  o_duration            => l_duration,
                                                                                  o_unit_meas_duration  => l_unit_meas_duration,
                                                                                  o_end_date            => l_end_date,
                                                                                  o_flg_end_by_editable => l_flg_end_by_editable,
                                                                                  o_error               => o_error)
                    THEN
                        g_error := 'error while calling get_order_recurr_instructions function';
                        RAISE g_exception;
                    END IF;
                
                    --This variable will hold the true recurr option of the form
                    --because the user may change to the option 'Other frequencies', and when calling the othr frequencies modal, 
                    --if the modal is cancelled, the form must return to the previous frequency
                    l_order_recurr_option_aux := l_order_recurr_option;
                
                    IF l_order_recurr_option_aux <> -1
                    THEN
                        FOR i IN i_tbl_int_name.first .. i_tbl_int_name.last
                        LOOP
                            IF i_tbl_int_name(i) = pk_orders_constant.g_ds_frequency
                            THEN
                                l_order_recurr_option := to_number(i_value(i) (1));
                                l_order_recurr_desc   := i_value_desc(i) (1);
                            END IF;
                        END LOOP;
                    END IF;
                END IF;
            
                FOR i IN i_tbl_int_name.first .. i_tbl_int_name.last
                LOOP
                    IF i_tbl_int_name(i) = pk_orders_constant.g_ds_frequency
                    THEN
                        l_recurrence_form_value := i_value(i) (1);
                        EXIT;
                    END IF;
                END LOOP;
            
                g_error := 'GETTING EPISODE DE BEGIN';
                IF NOT pk_episode.get_epis_dt_begin_tstz(i_lang          => i_lang,
                                                         i_prof          => i_prof,
                                                         i_id_episode    => i_episode,
                                                         o_dt_begin_tstz => l_episode_dt_begin,
                                                         o_error         => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
                IF l_episode_dt_begin IS NOT NULL
                   AND l_start_date IS NOT NULL
                THEN
                    -- @return 'G' if i_timestamp1 is more recent than i_timestamp2, 'E' if they are equal, 'L' otherwise 
                    l_flg_dt_begin := pk_date_utils.compare_dates_tsz(i_prof  => i_prof,
                                                                      i_date1 => l_episode_dt_begin,
                                                                      i_date2 => l_start_date);
                END IF;
            
                SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => t.id_ds_cmpt_mkt_rel,
                                           id_ds_component    => t.id_ds_component_child,
                                           internal_name      => t.internal_name_child,
                                           VALUE              => CASE
                                                                     WHEN t.internal_name_child = pk_orders_constant.g_ds_start_date THEN
                                                                      CASE
                                                                          WHEN t.internal_name_child = pk_orders_constant.g_ds_start_date
                                                                               AND l_flg_dt_begin = 'G' THEN
                                                                           NULL
                                                                          ELSE
                                                                           CASE
                                                                               WHEN l_start_date IS NOT NULL THEN
                                                                                pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => l_start_date, i_prof => i_prof)
                                                                               ELSE
                                                                                l_start_date_str
                                                                           END
                                                                      END
                                                                     WHEN t.internal_name_child = pk_orders_constant.g_ds_frequency
                                                                          AND l_order_recurr_option <> -1 THEN
                                                                      to_char(l_order_recurr_option)
                                                                     WHEN t.internal_name_child = pk_orders_constant.g_ds_executions THEN
                                                                      to_char(l_occurrences)
                                                                     WHEN t.internal_name_child = pk_orders_constant.g_ds_duration
                                                                          AND l_duration IS NOT NULL THEN
                                                                      to_char(l_duration)
                                                                     WHEN t.internal_name_child = pk_orders_constant.g_ds_end_date THEN
                                                                      pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => l_end_date, i_prof => i_prof)
                                                                     WHEN t.internal_name_child IN (pk_orders_constant.g_ds_exact_time)
                                                                          AND l_curr_comp_int_name = pk_orders_constant.g_ds_time_schedule THEN
                                                                      '00000101' || l_exec_time || '00'
                                                                     WHEN t.internal_name_child = pk_orders_constant.g_ds_end_based THEN
                                                                      l_flg_end_by
                                                                     WHEN t.internal_name_child = pk_orders_constant.g_ds_recurrence_pattern THEN
                                                                      l_flg_recurr_pattern
                                                                     WHEN t.internal_name_child = pk_orders_constant.g_ds_repeat_every THEN
                                                                      to_char(l_repeat_every)
                                                                     WHEN t.internal_name_child = pk_orders_constant.g_ds_other_frequency
                                                                          AND l_order_recurr_option_aux = -1 THEN
                                                                      to_char(l_order_recurr_option)
                                                                     ELSE
                                                                      NULL
                                                                 END,
                                           value_clob         => NULL,
                                           min_value          => NULL,
                                           max_value          => NULL,
                                           desc_value         => CASE
                                                                     WHEN t.internal_name_child = pk_orders_constant.g_ds_start_date THEN
                                                                      CASE
                                                                          WHEN l_start_date IS NOT NULL THEN
                                                                           pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => l_start_date, i_prof => i_prof)
                                                                          ELSE
                                                                           l_start_date_str
                                                                      END
                                                                     WHEN t.internal_name_child = pk_orders_constant.g_ds_frequency
                                                                          AND l_order_recurr_option <> -1 THEN
                                                                      l_order_recurr_desc
                                                                     WHEN t.internal_name_child = pk_orders_constant.g_ds_executions THEN
                                                                      to_char(l_occurrences)
                                                                     WHEN t.internal_name_child = pk_orders_constant.g_ds_duration
                                                                          AND l_duration IS NOT NULL THEN
                                                                      to_char(l_duration) || ' ' ||
                                                                      pk_unit_measure.get_unit_measure_description(i_lang         => i_lang,
                                                                                                                   i_prof         => i_prof,
                                                                                                                   i_unit_measure => l_unit_meas_duration)
                                                                     WHEN t.internal_name_child = pk_orders_constant.g_ds_end_date THEN
                                                                      pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => l_end_date, i_prof => i_prof)
                                                                     WHEN t.internal_name_child IN (pk_orders_constant.g_ds_exact_time)
                                                                          AND l_curr_comp_int_name = pk_orders_constant.g_ds_time_schedule THEN
                                                                      l_exec_time_desc
                                                                     WHEN t.internal_name_child = pk_orders_constant.g_ds_end_based THEN
                                                                      l_end_by_desc
                                                                     WHEN t.internal_name_child = pk_orders_constant.g_ds_recurrence_pattern THEN
                                                                      l_recurr_pattern_desc
                                                                     WHEN t.internal_name_child = pk_orders_constant.g_ds_repeat_every THEN
                                                                      l_repeat_every_desc
                                                                     WHEN t.internal_name_child = pk_orders_constant.g_ds_other_frequency
                                                                          AND l_order_recurr_option_aux = -1 THEN
                                                                      l_order_recurr_desc
                                                                     ELSE
                                                                      NULL
                                                                 END,
                                           desc_clob          => NULL,
                                           id_unit_measure    => CASE
                                                                     WHEN t.internal_name_child = pk_orders_constant.g_ds_repeat_every THEN
                                                                      l_unit_meas_repeat_every
                                                                     WHEN t.internal_name_child = pk_orders_constant.g_ds_duration THEN
                                                                      l_unit_meas_duration
                                                                     ELSE
                                                                      t.id_unit_measure
                                                                 END,
                                           desc_unit_measure  => NULL,
                                           flg_validation     => CASE
                                                                     WHEN t.internal_name_child = pk_orders_constant.g_ds_start_date
                                                                          AND l_flg_dt_begin = 'G' THEN
                                                                      pk_orders_constant.g_component_error
                                                                     ELSE
                                                                      pk_orders_constant.g_component_valid
                                                                 END,
                                           err_msg            => CASE
                                                                     WHEN t.internal_name_child = pk_orders_constant.g_ds_start_date
                                                                          AND l_flg_dt_begin = 'G' THEN
                                                                      pk_message.get_message(i_lang, 'POSITIONING_T024')
                                                                     ELSE
                                                                      NULL
                                                                 END,
                                           flg_event_type     => CASE
                                                                     WHEN t.internal_name_child IN
                                                                          (pk_orders_constant.g_ds_duration, pk_orders_constant.g_ds_end_date) THEN
                                                                      decode(l_flg_end_by_editable,
                                                                             pk_alert_constant.g_yes,
                                                                             pk_orders_constant.g_component_active,
                                                                             pk_orders_constant.g_component_inactive)
                                                                     WHEN t.internal_name_child IN (pk_orders_constant.g_ds_executions) THEN
                                                                      decode(l_flg_end_by_editable,
                                                                             pk_alert_constant.g_yes,
                                                                             pk_orders_constant.g_component_active,
                                                                             pk_orders_constant.g_component_read_only)
                                                                     WHEN t.internal_name_child = pk_orders_constant.g_ds_exact_time
                                                                          AND l_regular_interval IS NOT NULL THEN
                                                                      pk_orders_constant.g_component_inactive
                                                                     WHEN t.internal_name_child = pk_orders_constant.g_ds_exact_time
                                                                          AND l_regular_interval IS NULL THEN
                                                                      pk_orders_constant.g_component_active
                                                                     WHEN t.internal_name_child = pk_orders_constant.g_ds_other_frequency THEN
                                                                      CASE
                                                                          WHEN l_order_recurr_option = -1 THEN
                                                                           pk_orders_constant.g_component_mandatory
                                                                          ELSE
                                                                           pk_orders_constant.g_component_inactive
                                                                      END
                                                                     WHEN t.internal_name_child = pk_orders_constant.g_ds_start_date THEN
                                                                      pk_orders_constant.g_component_mandatory
                                                                     ELSE
                                                                      pk_orders_constant.g_component_active
                                                                 END,
                                           flg_multi_status   => NULL,
                                           idx                => i_idx)
                  BULK COLLECT
                  INTO tbl_result
                  FROM (SELECT dc.id_ds_cmpt_mkt_rel,
                               dc.id_ds_component_child,
                               dc.internal_name_child,
                               dc.flg_event_type,
                               dc.rn,
                               dc.flg_component_type_child,
                               dc.id_unit_measure
                          FROM TABLE(pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                             i_prof           => i_prof,
                                                             i_patient        => NULL,
                                                             i_component_name => i_root_name,
                                                             i_action         => NULL)) dc) t
                  JOIN ds_component d
                    ON d.id_ds_component = t.id_ds_component_child
                 WHERE --A pair of d.internal_name and l_curr_comp_int_name to assure that we are only setting values for the intended fields
                 (l_curr_comp_int_name IN (pk_orders_constant.g_ds_frequency,
                                           pk_orders_constant.g_ds_start_date,
                                           pk_orders_constant.g_ds_executions,
                                           pk_orders_constant.g_ds_duration,
                                           pk_orders_constant.g_ds_end_date) AND
                 d.internal_name IN (pk_orders_constant.g_ds_start_date,
                                      pk_orders_constant.g_ds_executions,
                                      pk_orders_constant.g_ds_duration,
                                      pk_orders_constant.g_ds_end_date,
                                      pk_orders_constant.g_ds_other_frequency))
                --'Outra frequ�ncia'                
                 OR (l_curr_comp_int_name = pk_orders_constant.g_ds_other_frequency AND
                 d.internal_name IN (pk_orders_constant.g_ds_other_frequency,
                                      pk_orders_constant.g_ds_start_date,
                                      pk_orders_constant.g_ds_executions,
                                      pk_orders_constant.g_ds_duration,
                                      pk_orders_constant.g_ds_end_date) AND l_order_recurr_option = -1);
            
                FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                LOOP
                    l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
                
                    IF l_ds_internal_name = pk_orders_constant.g_ds_ok_button_control
                    THEN
                        l_id_ds_component := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                        process_ok_button_control(i_id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                  i_id_ds_component    => l_id_ds_component,
                                                  i_ds_internal_name   => l_ds_internal_name);
                    END IF;
                END LOOP;
            ELSE
                --Selecting/Deselecting elements in the viewer
                --For this action we must check if the fields Duration, End date/time and Other frequencies should be active or inactive
                FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                LOOP
                    l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
                
                    IF l_ds_internal_name = pk_orders_constant.g_ds_dummy_number
                    THEN
                        l_order_recurr_plan := to_number(i_value(i) (1));
                    ELSIF l_ds_internal_name = pk_orders_constant.g_ds_frequency
                    THEN
                        l_order_recurr_option := to_number(i_value(i) (1));
                    END IF;
                END LOOP;
            
                IF NOT pk_order_recurrence_core.get_order_recurr_instructions(i_lang                => i_lang,
                                                                              i_prof                => i_prof,
                                                                              i_order_plan          => l_order_recurr_plan,
                                                                              o_order_recurr_desc   => l_order_recurr_desc,
                                                                              o_order_recurr_option => l_order_recurr_option,
                                                                              o_start_date          => l_start_date,
                                                                              o_occurrences         => l_occurrences,
                                                                              o_duration            => l_duration,
                                                                              o_unit_meas_duration  => l_unit_meas_duration,
                                                                              o_end_date            => l_end_date,
                                                                              o_flg_end_by_editable => l_flg_end_by_editable,
                                                                              o_error               => o_error)
                THEN
                    g_error := 'error while calling get_order_recurr_instructions function';
                    RAISE g_exception;
                END IF;
            
                SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => t.id_ds_cmpt_mkt_rel,
                                           id_ds_component    => t.id_ds_component_child,
                                           internal_name      => t.internal_name_child,
                                           VALUE              => CASE
                                                                     WHEN t.internal_name_child = pk_orders_constant.g_ds_duration
                                                                          AND l_duration IS NOT NULL THEN
                                                                      to_char(l_duration)
                                                                     WHEN t.internal_name_child = pk_orders_constant.g_ds_end_date THEN
                                                                      pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => l_end_date, i_prof => i_prof)
                                                                     WHEN t.internal_name_child = pk_orders_constant.g_ds_other_frequency
                                                                          AND l_order_recurr_option = -1 THEN
                                                                      l_order_recurr_desc
                                                                     WHEN t.internal_name_child = pk_orders_constant.g_ds_executions THEN
                                                                      to_char(l_occurrences)
                                                                     ELSE
                                                                      NULL
                                                                 END,
                                           value_clob         => NULL,
                                           min_value          => NULL,
                                           max_value          => NULL,
                                           desc_value         => CASE
                                                                     WHEN t.internal_name_child = pk_orders_constant.g_ds_duration
                                                                          AND l_duration IS NOT NULL THEN
                                                                      to_char(l_duration) || ' ' ||
                                                                      pk_unit_measure.get_unit_measure_description(i_lang         => i_lang,
                                                                                                                   i_prof         => i_prof,
                                                                                                                   i_unit_measure => l_unit_meas_duration)
                                                                     WHEN t.internal_name_child = pk_orders_constant.g_ds_end_date THEN
                                                                      pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => l_end_date, i_prof => i_prof)
                                                                     WHEN t.internal_name_child = pk_orders_constant.g_ds_other_frequency
                                                                          AND l_order_recurr_option = -1 THEN
                                                                      l_order_recurr_desc
                                                                     WHEN t.internal_name_child = pk_orders_constant.g_ds_executions THEN
                                                                      to_char(l_occurrences)
                                                                     ELSE
                                                                      NULL
                                                                 END,
                                           desc_clob          => NULL,
                                           id_unit_measure    => CASE
                                                                     WHEN t.internal_name_child IN (pk_orders_constant.g_ds_duration) THEN
                                                                      to_number(pk_orders_utils.get_value(i_internal_name_child => t.internal_name_child,
                                                                                                          i_tbl_mkt_rel         => i_tbl_mkt_rel,
                                                                                                          i_value               => i_value_mea))
                                                                     ELSE
                                                                      NULL
                                                                 END,
                                           desc_unit_measure  => NULL,
                                           flg_validation     => pk_alert_constant.g_yes,
                                           err_msg            => NULL,
                                           flg_event_type     => CASE
                                                                     WHEN t.internal_name_child IN
                                                                          (pk_orders_constant.g_ds_duration, pk_orders_constant.g_ds_end_date) THEN
                                                                     --If l_flg_end_by_editable = 'N', fields duration and end date must be inactive
                                                                      decode(l_flg_end_by_editable,
                                                                             pk_alert_constant.g_yes,
                                                                             pk_orders_constant.g_component_active,
                                                                             pk_orders_constant.g_component_inactive)
                                                                     WHEN t.internal_name_child IN (pk_orders_constant.g_ds_executions) THEN
                                                                     --If l_flg_end_by_editable = 'N', field 'Exections' must be Read Only and present the value given by l_occurrences
                                                                      decode(l_flg_end_by_editable,
                                                                             pk_alert_constant.g_yes,
                                                                             pk_orders_constant.g_component_active,
                                                                             pk_orders_constant.g_component_read_only)
                                                                     WHEN t.internal_name_child = pk_orders_constant.g_ds_other_frequency THEN
                                                                      decode(l_order_recurr_option,
                                                                             -1,
                                                                             pk_orders_constant.g_component_mandatory,
                                                                             pk_orders_constant.g_component_inactive)
                                                                 END,
                                           flg_multi_status   => NULL,
                                           idx                => i_idx)
                  BULK COLLECT
                  INTO tbl_result
                  FROM (SELECT dc.id_ds_cmpt_mkt_rel,
                               dc.id_ds_component_child,
                               dc.internal_name_child,
                               dc.flg_event_type,
                               dc.rn,
                               dc.flg_component_type_child,
                               dc.id_unit_measure
                          FROM TABLE(pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                             i_prof           => i_prof,
                                                             i_patient        => NULL,
                                                             i_component_name => i_root_name,
                                                             i_action         => NULL)) dc) t
                  JOIN ds_component d
                    ON d.id_ds_component = t.id_ds_component_child
                 WHERE d.internal_name IN (pk_orders_constant.g_ds_executions,
                                           pk_orders_constant.g_ds_duration,
                                           pk_orders_constant.g_ds_end_date,
                                           pk_orders_constant.g_ds_other_frequency)
                 ORDER BY t.rn;
            
                --RESTANTES ELEMENTOS
                FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                LOOP
                    l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
                    l_id_ds_component  := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                
                    IF l_ds_internal_name IN
                       (pk_orders_constant.g_ds_clinical_indication_mw,
                        pk_orders_constant.g_ds_clinical_indication_icnp_mw)
                    THEN
                        SELECT ntr.id_nurse_tea_req
                          BULK COLLECT
                          INTO l_tbl_id_nurse_tea_req
                          FROM nurse_tea_req ntr
                         WHERE ntr.id_nurse_tea_req = i_tbl_id_pk(i_idx)
                           AND ntr.id_episode = i_episode
                           AND ntr.id_patient = i_patient;
                    
                        IF l_tbl_id_nurse_tea_req.count > 0
                        THEN
                            --Determining the category of the professional that made the original request
                            SELECT DISTINCT t.id_prof_req
                              BULK COLLECT
                              INTO l_tbl_id_prof_req
                              FROM (SELECT ntrh.id_prof_req,
                                           row_number() over(PARTITION BY ntrh.id_nurse_tea_req ORDER BY ntrh.dt_nurse_tea_req_tstz) AS rn
                                      FROM nurse_tea_req_hist ntrh
                                     WHERE ntrh.id_nurse_tea_req = i_tbl_id_pk(i_idx)
                                       AND ntrh.flg_status = 'D') t
                             WHERE t.rn = 1;
                        
                            l_prof_category := pk_prof_utils.get_category(i_lang, i_prof);
                        
                            --Determining the category of the professional that made the original request       
                            FOR j IN l_tbl_id_prof_req.first .. l_tbl_id_prof_req.last
                            LOOP
                                l_tbl_prof_req_category.extend();
                                l_tbl_prof_req_category(l_tbl_prof_req_category.count) := pk_prof_utils.get_category(i_lang,
                                                                                                                     profissional(l_tbl_id_prof_req(j),
                                                                                                                                  i_prof.institution,
                                                                                                                                  
                                                                                                                                  i_prof.software));
                            
                                IF l_tbl_prof_req_category(j) <> l_prof_category
                                THEN
                                    --If there is at least one record made by a different category,
                                    --the property flg_event_type must be set as 'Read-only' for
                                    --the field Clinical indication
                                    l_flg_event_type := pk_orders_constant.g_component_read_only;
                                ELSE
                                    l_flg_event_type := pk_orders_constant.g_component_active;
                                END IF;
                            END LOOP;
                        
                            SELECT pk_patient_education_utils.get_id_diagnosis(i_lang, i_prof, ntr.id_nurse_tea_req),
                                   pk_patient_education_utils.get_desc_diagnosis(i_lang, i_prof, ntr.id_nurse_tea_req)
                              INTO l_tbl_id_diag, l_tbl_diag_desc
                              FROM nurse_tea_req ntr
                             WHERE ntr.id_nurse_tea_req = i_tbl_id_pk(i_idx)
                               AND ntr.id_episode = i_episode
                               AND ntr.id_patient = i_patient;
                        
                            --Note: The structure only needs to be sent if the field is 'Read-only',
                            --otherwise the HTML takes care of the behavior.
                            IF l_tbl_id_diag.count > 0
                            --AND l_flg_event_type = PK_orders_constant.g_component_read_only
                            THEN
                                --Only phisician have access to the g_ds_clinical_indication_mw field
                                --Only nurses have acces to the g_ds_clinical_indication_icnp_mw
                                SELECT ad.id_alert_diagnosis
                                  BULK COLLECT
                                  INTO l_tbl_id_alert_diagnosis
                                  FROM epis_diagnosis ed
                                  JOIN alert_diagnosis ad
                                    ON ad.id_alert_diagnosis = ed.id_alert_diagnosis
                                 WHERE ad.id_diagnosis IN (SELECT * /*+opt_estimate(table t rows=1)*/
                                                             FROM TABLE(l_tbl_id_diag) t)
                                   AND ed.id_episode = i_episode
                                 ORDER BY ed.id_diagnosis;
                            
                                IF l_tbl_id_alert_diagnosis.count > 0
                                THEN
                                    FOR j IN l_tbl_id_alert_diagnosis.first .. l_tbl_id_alert_diagnosis.last
                                    LOOP
                                        tbl_result.extend();
                                        tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                                           id_ds_component    => l_id_ds_component,
                                                                                           internal_name      => l_ds_internal_name,
                                                                                           VALUE              => to_char(l_tbl_id_alert_diagnosis(j)),
                                                                                           value_clob         => NULL,
                                                                                           min_value          => NULL,
                                                                                           max_value          => NULL,
                                                                                           desc_value         => l_tbl_diag_desc(j),
                                                                                           desc_clob          => NULL,
                                                                                           id_unit_measure    => NULL,
                                                                                           desc_unit_measure  => NULL,
                                                                                           flg_validation     => pk_alert_constant.g_yes,
                                                                                           err_msg            => NULL,
                                                                                           flg_event_type     => l_flg_event_type,
                                                                                           flg_multi_status   => NULL,
                                                                                           idx                => i_idx);
                                    END LOOP;
                                ELSE
                                    FOR j IN l_tbl_id_diag.first .. l_tbl_id_diag.last
                                    LOOP
                                        tbl_result.extend();
                                        tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                                           id_ds_component    => l_id_ds_component,
                                                                                           internal_name      => l_ds_internal_name,
                                                                                           VALUE              => to_char(l_tbl_id_diag(j)),
                                                                                           value_clob         => NULL,
                                                                                           min_value          => NULL,
                                                                                           max_value          => NULL,
                                                                                           desc_value         => l_tbl_diag_desc(j),
                                                                                           desc_clob          => NULL,
                                                                                           id_unit_measure    => NULL,
                                                                                           desc_unit_measure  => NULL,
                                                                                           flg_validation     => pk_alert_constant.g_yes,
                                                                                           err_msg            => NULL,
                                                                                           flg_event_type     => l_flg_event_type,
                                                                                           flg_multi_status   => NULL,
                                                                                           idx                => i_idx);
                                    END LOOP;
                                END IF;
                            ELSIF l_flg_event_type = pk_orders_constant.g_component_read_only
                            THEN
                                tbl_result.extend();
                                tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                                   id_ds_component    => l_id_ds_component,
                                                                                   internal_name      => l_ds_internal_name,
                                                                                   VALUE              => NULL,
                                                                                   min_value          => NULL,
                                                                                   max_value          => NULL,
                                                                                   value_clob         => NULL,
                                                                                   desc_value         => NULL,
                                                                                   desc_clob          => NULL,
                                                                                   id_unit_measure    => NULL,
                                                                                   desc_unit_measure  => NULL,
                                                                                   flg_validation     => pk_alert_constant.g_yes,
                                                                                   err_msg            => NULL,
                                                                                   flg_event_type     => l_flg_event_type,
                                                                                   flg_multi_status   => NULL,
                                                                                   idx                => i_idx);
                            END IF;
                        ELSE
                            --Ainda n�o h� nada gravado???
                            l_prof_category := pk_prof_utils.get_category(i_lang, i_prof);
                        
                            FOR j IN i_value(i).first .. i_value(i).last
                            LOOP
                                tbl_result.extend();
                                tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                                   id_ds_component    => l_id_ds_component,
                                                                                   internal_name      => l_ds_internal_name,
                                                                                   VALUE              => i_value(i) (j),
                                                                                   min_value          => NULL,
                                                                                   max_value          => NULL,
                                                                                   value_clob         => NULL,
                                                                                   desc_value         => i_value_desc(i) (j),
                                                                                   desc_clob          => NULL,
                                                                                   id_unit_measure    => NULL,
                                                                                   desc_unit_measure  => NULL,
                                                                                   flg_validation     => pk_alert_constant.g_yes,
                                                                                   err_msg            => NULL,
                                                                                   flg_event_type     => CASE
                                                                                                             WHEN l_ds_internal_name = pk_orders_constant.g_ds_clinical_indication_mw THEN
                                                                                                              CASE
                                                                                                                  WHEN l_prof_category = 'D' THEN
                                                                                                                   pk_orders_constant.g_component_active
                                                                                                                  ELSE
                                                                                                                   pk_orders_constant.g_component_read_only
                                                                                                              END
                                                                                                             WHEN l_ds_internal_name = pk_orders_constant.g_ds_clinical_indication_icnp_mw THEN
                                                                                                              CASE
                                                                                                                  WHEN l_prof_category = 'D' THEN
                                                                                                                   pk_orders_constant.g_component_read_only
                                                                                                                  ELSE
                                                                                                                   pk_orders_constant.g_component_active
                                                                                                              END
                                                                                                         END,
                                                                                   flg_multi_status   => NULL,
                                                                                   idx                => i_idx);
                            END LOOP;
                        
                        END IF;
                    ELSIF l_ds_internal_name IN
                          (pk_orders_constant.g_ds_to_be_executed, pk_orders_constant.g_ds_frequency)
                    THEN
                        tbl_result.extend();
                        tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                           id_ds_component    => l_id_ds_component,
                                                                           internal_name      => l_ds_internal_name,
                                                                           VALUE              => i_value(i) (1),
                                                                           min_value          => NULL,
                                                                           max_value          => NULL,
                                                                           value_clob         => NULL,
                                                                           desc_value         => i_value_desc(i) (1),
                                                                           desc_clob          => NULL,
                                                                           id_unit_measure    => NULL,
                                                                           desc_unit_measure  => NULL,
                                                                           flg_validation     => pk_alert_constant.g_yes,
                                                                           err_msg            => NULL,
                                                                           flg_event_type     => pk_orders_constant.g_component_mandatory,
                                                                           flg_multi_status   => NULL,
                                                                           idx                => i_idx);
                    ELSIF l_ds_internal_name IN (pk_orders_constant.g_ds_start_date)
                          AND i_value(i) (1) IS NOT NULL
                    THEN
                        tbl_result.extend();
                        tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                           id_ds_component    => l_id_ds_component,
                                                                           internal_name      => l_ds_internal_name,
                                                                           VALUE              => i_value(i) (1),
                                                                           min_value          => NULL,
                                                                           max_value          => NULL,
                                                                           value_clob         => NULL,
                                                                           desc_value         => NULL,
                                                                           desc_clob          => NULL,
                                                                           id_unit_measure    => NULL,
                                                                           desc_unit_measure  => NULL,
                                                                           flg_validation     => pk_alert_constant.g_yes,
                                                                           err_msg            => NULL,
                                                                           flg_event_type     => pk_orders_constant.g_component_mandatory,
                                                                           flg_multi_status   => NULL,
                                                                           idx                => i_idx);
                    ELSIF l_ds_internal_name IN
                          (pk_orders_constant.g_ds_notes_clob, pk_orders_constant.g_ds_description)
                    THEN
                        tbl_result.extend();
                        tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                           id_ds_component    => l_id_ds_component,
                                                                           internal_name      => l_ds_internal_name,
                                                                           VALUE              => NULL,
                                                                           min_value          => NULL,
                                                                           max_value          => NULL,
                                                                           value_clob         => NULL,
                                                                           desc_value         => NULL,
                                                                           desc_clob          => i_value_clob(i),
                                                                           id_unit_measure    => NULL,
                                                                           desc_unit_measure  => NULL,
                                                                           flg_validation     => pk_alert_constant.g_yes,
                                                                           err_msg            => NULL,
                                                                           flg_event_type     => pk_orders_constant.g_component_active,
                                                                           flg_multi_status   => NULL,
                                                                           idx                => i_idx);
                    ELSIF l_ds_internal_name = pk_orders_constant.g_ds_dummy_number
                    THEN
                        tbl_result.extend();
                        tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                           id_ds_component    => l_id_ds_component,
                                                                           internal_name      => l_ds_internal_name,
                                                                           VALUE              => l_order_recurr_plan,
                                                                           min_value          => NULL,
                                                                           max_value          => NULL,
                                                                           value_clob         => NULL,
                                                                           desc_value         => to_char(l_order_recurr_plan),
                                                                           desc_clob          => NULL,
                                                                           id_unit_measure    => NULL,
                                                                           desc_unit_measure  => NULL,
                                                                           flg_validation     => pk_alert_constant.g_yes,
                                                                           err_msg            => NULL,
                                                                           flg_event_type     => pk_orders_constant.g_component_active,
                                                                           flg_multi_status   => NULL,
                                                                           idx                => i_idx);
                    ELSIF l_ds_internal_name = pk_orders_constant.g_ds_ok_button_control
                    THEN
                    
                        l_id_ds_component := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                    
                        process_ok_button_control(i_id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                  i_id_ds_component    => l_id_ds_component,
                                                  i_ds_internal_name   => l_ds_internal_name);
                    END IF;
                END LOOP;
            END IF;
        ELSE
            --EDI��O
            IF NOT pk_patient_education_core.get_request_for_update(i_lang             => i_lang,
                                                                    i_prof             => i_prof,
                                                                    i_episode          => i_episode,
                                                                    i_action           => i_action,
                                                                    i_id_nurse_tea_req => i_tbl_id_pk(i_idx),
                                                                    i_idx              => i_idx,
                                                                    i_tbl_mkt_rel      => i_tbl_mkt_rel,
                                                                    io_tbl_resul       => tbl_result,
                                                                    o_error            => o_error)
            THEN
                g_error := 'Error found while calling pk_patient_education_constant.g_et_request_for_update function';
                RAISE g_exception;
            END IF;
        END IF;
    
        RETURN tbl_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_db_object_name,
                                              o_error);
            RETURN NULL;
    END get_he_order_values;

    FUNCTION get_os_he_order_values
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER, -- edit, new, submit
        i_root_name      IN VARCHAR2, -- root of dynamic screen
        i_curr_component IN NUMBER,
        i_idx            IN NUMBER DEFAULT 1,
        i_tbl_id_pk      IN table_number, -- id necessary for identifying pk for editing
        i_tbl_mkt_rel    IN table_number, -- components needed for default/edit
        i_tbl_int_name   IN table_varchar,
        i_value          IN table_table_varchar,
        i_value_mea      IN table_table_varchar,
        i_value_desc     IN table_table_varchar,
        i_value_clob     IN table_clob,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value IS
        tbl_result t_tbl_ds_get_value := t_tbl_ds_get_value();
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_OS_HE_ORDER_VALUES';
    
        l_value_to_be_executed      VARCHAR2(4000);
        l_value_to_be_executed_desc VARCHAR2(4000);
        l_description               CLOB;
    
        l_curr_comp_int_name ds_component.internal_name%TYPE;
    
        l_id_nurse_tea_req nurse_tea_req.id_nurse_tea_req%TYPE;
    
        --RECURRENCE
        l_order_recurr_desc          VARCHAR2(4000);
        l_order_recurr_option        order_recurr_plan.id_order_recurr_option%TYPE;
        l_order_recurr_option_aux    order_recurr_plan.id_order_recurr_option%TYPE;
        l_start_date                 order_recurr_plan.start_date%TYPE;
        l_occurrences                order_recurr_plan.occurrences%TYPE;
        l_duration                   order_recurr_plan.duration%TYPE;
        l_unit_meas_duration         order_recurr_plan.id_unit_meas_duration%TYPE;
        l_duration_desc              VARCHAR2(4000);
        l_end_date                   order_recurr_plan.end_date%TYPE;
        l_flg_end_by_editable        VARCHAR2(1);
        l_order_recurr_plan          order_recurr_plan.id_order_recurr_plan%TYPE;
        l_order_recurr_plan_original order_recurr_plan.id_order_recurr_plan%TYPE;
        l_timestamp_start            VARCHAR2(4000);
        l_timestamp_end              VARCHAR2(4000);
    
        --Frequency selected on the form
        l_recurrence_form_value VARCHAR2(100);
    
        --RECURRENC OTHER        
        l_regular_interval    order_recurr_plan.regular_interval%TYPE;
        l_regulat_interval_um NUMBER(24);
        l_daily_executions    order_recurr_plan.daily_executions%TYPE;
    
        l_predef_time_sched_desc VARCHAR2(500);
        l_exec_time              VARCHAR2(500);
        l_exec_time_desc         VARCHAR2(500);
        l_exec_time_option       NUMBER(24);
        l_recurr_pattern_desc    VARCHAR2(500);
        l_repeat_every_desc      VARCHAR2(500);
        l_start_date_str         VARCHAR2(500);
        l_end_by_desc            VARCHAR2(500);
    
        l_start VARCHAR2(500);
        l_end   VARCHAR2(500);
    
        l_ds_internal_name   ds_component.internal_name%TYPE;
        l_id_ds_component    ds_component.id_ds_component%TYPE;
        l_id_ds_cmpt_mkt_rel ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE;
    
        l_flg_recurr_pattern     order_recurr_plan.flg_recurr_pattern%TYPE;
        l_repeat_every           order_recurr_plan.repeat_every%TYPE;
        l_unit_meas_repeat_every unit_measure.id_unit_measure%TYPE;
        l_flg_end_by             order_recurr_plan.flg_end_by%TYPE;
    
        --Clinical indication
        l_clinical_indication_mandatory sys_config.value%TYPE := pk_alert_constant.g_no;
        l_clinical_purpose_mandatory    sys_config.value%TYPE := pk_alert_constant.g_no;
    
        l_tbl_id_prof_req       table_number;
        l_tbl_prof_req_category table_varchar := table_varchar();
        l_prof_category         category.flg_type%TYPE;
        l_tbl_id_nurse_tea_req  table_number;
    
        l_tbl_id_diag            table_number;
        l_tbl_id_alert_diagnosis table_number;
        l_tbl_diag_desc          table_varchar;
    
        l_flg_event_type VARCHAR2(1);
    
        l_episode_dt_begin episode.dt_begin_tstz%TYPE;
        l_flg_dt_begin     VARCHAR2(1 CHAR);
    
        l_aux_val         VARCHAR2(4000 CHAR);
        l_dt_epis_begin   episode.dt_begin_tstz%TYPE;
        l_date_comparison VARCHAR2(1 CHAR);
    
        PROCEDURE process_ok_button_control
        (
            i_id_ds_cmpt_mkt_rel IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
            i_id_ds_component    IN ds_component.id_ds_component%TYPE,
            i_ds_internal_name   IN ds_component.internal_name%TYPE
        ) IS
            l_ok_status VARCHAR2(1) := pk_orders_constant.g_component_valid;
        BEGIN
            FOR j IN tbl_result.first .. tbl_result.last
            LOOP
                IF (tbl_result(j).flg_event_type = pk_orders_constant.g_component_mandatory AND tbl_result(j).value IS NULL)
                   OR tbl_result(j).flg_validation = pk_orders_constant.g_component_error
                THEN
                    l_ok_status := pk_orders_constant.g_component_error;
                END IF;
            END LOOP;
        
            tbl_result.extend();
            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_id_ds_cmpt_mkt_rel,
                                                               id_ds_component    => i_id_ds_component,
                                                               internal_name      => i_ds_internal_name,
                                                               VALUE              => NULL,
                                                               value_clob         => NULL,
                                                               min_value          => NULL,
                                                               max_value          => NULL,
                                                               desc_value         => NULL,
                                                               desc_clob          => NULL,
                                                               id_unit_measure    => NULL,
                                                               desc_unit_measure  => NULL,
                                                               flg_validation     => l_ok_status,
                                                               err_msg            => NULL,
                                                               flg_event_type     => pk_orders_constant.g_component_active,
                                                               flg_multi_status   => NULL,
                                                               idx                => i_idx);
        EXCEPTION
            WHEN OTHERS THEN
                pk_alertlog.log_error(SQLCODE || ' ' || SQLERRM || ' ' || g_error);
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  'PROCESS_OK_BUTTON_CONTROL',
                                                  o_error);
            
        END process_ok_button_control;
    
    BEGIN
        g_sysdate_tstz := nvl(g_sysdate_tstz, current_timestamp);
    
        IF i_action IS NULL
        THEN
            --NEW FORM (default values)
            IF NOT pk_patient_education_core.get_default_domain_time(i_lang     => i_lang,
                                                                     i_prof     => i_prof,
                                                                     o_val      => l_value_to_be_executed,
                                                                     o_desc_val => l_value_to_be_executed_desc,
                                                                     o_error    => o_error)
            THEN
                g_error := 'error found while calling pk_patient_education_constant.get_default_domain_time function';
                RAISE g_exception;
            END IF;
        
            IF i_idx = 1
            THEN
                --Obtaining the recurrence and the default values for the following fields:
                --FREQUENCY
                --START DATE
                --EXECUTIONS
                --DURATION
                --END DATE   
                IF NOT pk_order_recurrence_core.create_order_recurr_plan(i_lang                => i_lang,
                                                                         i_prof                => i_prof,
                                                                         i_order_recurr_area   => 'PATIENT_EDUCATION',
                                                                         o_order_recurr_desc   => l_order_recurr_desc,
                                                                         o_order_recurr_option => l_order_recurr_option,
                                                                         o_start_date          => l_start_date,
                                                                         o_occurrences         => l_occurrences,
                                                                         o_duration            => l_duration,
                                                                         o_unit_meas_duration  => l_unit_meas_duration,
                                                                         o_end_date            => l_end_date,
                                                                         o_flg_end_by_editable => l_flg_end_by_editable,
                                                                         o_order_recurr_plan   => l_order_recurr_plan,
                                                                         o_error               => o_error)
                THEN
                    g_error := 'error found while calling pk_order_recurrence_core.create_order_recurr_plan function';
                    RAISE g_exception;
                END IF;
            
                l_order_recurr_plan_original := l_order_recurr_plan;
            
                --A recorr�ncia � gerada apenas no 1� registo do carrinho, como tal,
                --� necess�rio guardar este valor numa vari�vel de contexto, para que
                --os registos seguintes consigam utilizar esse valor
                pk_context_api.set_parameter(p_name  => 'l_order_recurr_plan_original',
                                             p_value => l_order_recurr_plan_original);
            ELSE
                --Quando o i_idx>1, � necess�rio obter o id_order_recurrence gerado para o 1� registo
                SELECT to_number(alert_context('l_order_recurr_plan_original'))
                  INTO l_order_recurr_plan_original
                  FROM dual;
            
                IF l_order_recurr_plan_original IS NOT NULL
                THEN
                    IF NOT pk_order_recurrence_core.copy_order_recurr_plan(i_lang                   => i_lang,
                                                                           i_prof                   => i_prof,
                                                                           i_order_recurr_plan_from => l_order_recurr_plan_original,
                                                                           o_order_recurr_desc      => l_order_recurr_desc,
                                                                           o_order_recurr_option    => l_order_recurr_option,
                                                                           o_start_date             => l_start_date,
                                                                           o_occurrences            => l_occurrences,
                                                                           o_duration               => l_duration,
                                                                           o_unit_meas_duration     => l_unit_meas_duration,
                                                                           o_end_date               => l_end_date,
                                                                           o_flg_end_by_editable    => l_flg_end_by_editable,
                                                                           o_order_recurr_plan      => l_order_recurr_plan,
                                                                           o_error                  => o_error)
                    THEN
                        g_error := 'error found while calling pk_order_recurrence_core.copy_order_recurr_plan function';
                        RAISE g_exception;
                    END IF;
                END IF;
            END IF;
        
            --GETING THE VALUES THAT ARE COMMON TO ALL FORMS (FREQUENCY, START DATE, ETC.)
            SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => t.id_ds_cmpt_mkt_rel,
                                       id_ds_component    => t.id_ds_component_child,
                                       internal_name      => t.internal_name_child,
                                       VALUE              => CASE
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_to_be_executed THEN
                                                                  l_value_to_be_executed
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_frequency THEN
                                                                  to_char(l_order_recurr_option)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_start_date THEN
                                                                  NULL
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_executions THEN
                                                                  to_char(l_occurrences)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_duration THEN
                                                                  to_char(l_duration)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_end_date THEN
                                                                  NULL
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_dummy_number THEN
                                                                  to_char(l_order_recurr_plan)
                                                                 ELSE
                                                                  NULL
                                                             END,
                                       value_clob         => NULL,
                                       min_value          => NULL,
                                       max_value          => NULL,
                                       desc_value         => CASE
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_to_be_executed THEN
                                                                  l_value_to_be_executed_desc
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_frequency THEN
                                                                  l_order_recurr_desc
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_executions THEN
                                                                  to_char(l_occurrences)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_duration THEN
                                                                  CASE
                                                                      WHEN l_duration IS NOT NULL THEN
                                                                       to_char(l_duration) || ' ' ||
                                                                       pk_unit_measure.get_unit_measure_description(i_lang         => i_lang,
                                                                                                                    i_prof         => i_prof,
                                                                                                                    i_unit_measure => l_unit_meas_duration)
                                                                  END
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_dummy_number THEN
                                                                  to_char(l_order_recurr_plan)
                                                                 ELSE
                                                                  NULL
                                                             END,
                                       desc_clob          => NULL,
                                       id_unit_measure    => t.id_unit_measure,
                                       desc_unit_measure  => CASE
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_duration THEN
                                                                  pk_unit_measure.get_unit_measure_description(i_lang         => i_lang,
                                                                                                               i_prof         => i_prof,
                                                                                                               i_unit_measure => l_unit_meas_duration)
                                                                 WHEN t.id_unit_measure IS NOT NULL THEN
                                                                  pk_unit_measure.get_unit_measure_description(i_lang         => i_lang,
                                                                                                               i_prof         => i_prof,
                                                                                                               i_unit_measure => t.id_unit_measure)
                                                                 ELSE
                                                                  NULL
                                                             END,
                                       flg_validation     => pk_orders_constant.g_component_valid,
                                       err_msg            => NULL,
                                       flg_event_type     => CASE
                                                                 WHEN t.internal_name_child IN (pk_orders_constant.g_ds_clinical_indication_mw) THEN
                                                                  pk_orders_constant.g_component_inactive
                                                                 WHEN t.internal_name_child IN (pk_orders_constant.g_ds_to_be_executed) THEN
                                                                  pk_orders_constant.g_component_read_only
                                                                 WHEN t.internal_name_child IN
                                                                      (pk_orders_constant.g_ds_start_date, pk_orders_constant.g_ds_end_date) THEN
                                                                  pk_orders_constant.g_component_inactive
                                                                 WHEN t.internal_name_child IN (pk_orders_constant.g_ds_duration) THEN
                                                                 --If l_flg_end_by_editable = 'N', fields duration and end date must be inactive
                                                                  decode(l_flg_end_by_editable,
                                                                         pk_alert_constant.g_yes,
                                                                         pk_orders_constant.g_component_active,
                                                                         'I')
                                                                 WHEN t.internal_name_child IN (pk_orders_constant.g_ds_executions) THEN
                                                                 --If l_flg_end_by_editable = 'N', field 'Exections' must be Read Only and present the value given by l_occurrences
                                                                  decode(l_flg_end_by_editable,
                                                                         pk_alert_constant.g_yes,
                                                                         pk_orders_constant.g_component_active,
                                                                         pk_orders_constant.g_component_read_only)
                                                                 WHEN t.internal_name_child IN (pk_orders_constant.g_ds_clinical_purpose) THEN -------??????
                                                                  CASE l_clinical_purpose_mandatory
                                                                      WHEN pk_alert_constant.g_yes THEN
                                                                       pk_orders_constant.g_component_mandatory
                                                                      ELSE
                                                                       pk_orders_constant.g_component_active
                                                                  END
                                                                 WHEN t.internal_name_child NOT IN (pk_orders_constant.g_ds_start_date) THEN
                                                                  pk_orders_constant.g_component_active
                                                             END,
                                       flg_multi_status   => pk_alert_constant.g_no,
                                       idx                => i_idx)
              BULK COLLECT
              INTO tbl_result
              FROM (SELECT dc.id_ds_cmpt_mkt_rel,
                           dc.id_ds_component_child,
                           dc.internal_name_child,
                           dc.flg_event_type,
                           dc.rn,
                           dc.flg_component_type_child,
                           dc.id_unit_measure
                      FROM TABLE(pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                         i_prof           => i_prof,
                                                         i_patient        => NULL,
                                                         i_component_name => i_root_name,
                                                         i_action         => NULL)) dc) t
              JOIN ds_component d
                ON d.id_ds_component = t.id_ds_component_child
              LEFT JOIN ds_def_event def
                ON def.id_ds_cmpt_mkt_rel = t.id_ds_cmpt_mkt_rel
             WHERE d.internal_name IN (pk_orders_constant.g_ds_clinical_indication_mw,
                                       pk_orders_constant.g_ds_to_be_executed,
                                       pk_orders_constant.g_ds_frequency,
                                       pk_orders_constant.g_ds_start_date,
                                       pk_orders_constant.g_ds_executions,
                                       pk_orders_constant.g_ds_duration,
                                       pk_orders_constant.g_ds_end_date,
                                       pk_orders_constant.g_ds_dummy_number,
                                       pk_orders_constant.g_ds_ok_button_control)
             ORDER BY t.rn;
        
            SELECT dc.id_ds_component
              INTO l_id_ds_component
              FROM ds_component dc
             WHERE dc.internal_name = pk_orders_constant.g_ds_description;
        
            l_id_ds_cmpt_mkt_rel := pk_orders_utils.get_ds_cmpt_mkt_rel(pk_orders_constant.g_ds_description,
                                                                        i_tbl_mkt_rel);
        
            l_description := pk_patient_education_utils.get_subject(i_lang     => i_lang,
                                                                    i_prof     => i_prof,
                                                                    i_id_topic => i_tbl_id_pk(i_idx));
            IF l_description IS NOT NULL
            THEN
                tbl_result.extend();
                tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => l_id_ds_cmpt_mkt_rel,
                                                                   id_ds_component    => l_id_ds_component,
                                                                   internal_name      => pk_orders_constant.g_ds_description,
                                                                   VALUE              => NULL,
                                                                   value_clob         => l_description,
                                                                   min_value          => NULL,
                                                                   max_value          => NULL,
                                                                   desc_value         => NULL,
                                                                   desc_clob          => l_description,
                                                                   id_unit_measure    => NULL,
                                                                   desc_unit_measure  => NULL,
                                                                   flg_validation     => pk_orders_constant.g_component_valid,
                                                                   err_msg            => NULL,
                                                                   flg_event_type     => pk_orders_constant.g_component_active,
                                                                   flg_multi_status   => pk_alert_constant.g_no,
                                                                   idx                => i_idx);
            END IF;
        ELSIF i_action = pk_dyn_form_constant.get_submit_action
        THEN
            --Action of submiting a value on any given element of the form
            --In order for this action to be executed, a submit action must be configured in ds_event for the given field.
            IF i_curr_component IS NOT NULL
            THEN
                --Check which element has been changed
                SELECT d.internal_name_child
                  INTO l_curr_comp_int_name
                  FROM ds_cmpt_mkt_rel d
                 WHERE d.id_ds_cmpt_mkt_rel = i_curr_component;
            
                IF l_curr_comp_int_name = pk_orders_constant.g_ds_frequency --Frequency field
                THEN
                    --Obtain the id order recurr plan which is stored in DS_DUMMY_NUMBER element
                    --DS_DUMMY_NUMBER is an hidden field of the form. The reccurence id is stored in this element
                    --when the form is initialized                
                    FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                    LOOP
                        l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
                    
                        IF l_ds_internal_name = pk_orders_constant.g_ds_frequency
                        THEN
                            --Obtain the id for the recurr_option (value selected from the frequency field)   
                            l_order_recurr_option := to_number(i_value(i) (1));
                        END IF;
                    END LOOP;
                
                    FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                    LOOP
                        l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
                    
                        IF l_ds_internal_name = pk_orders_constant.g_ds_dummy_number
                        THEN
                            l_order_recurr_plan := to_number(i_value(i) (1));
                        END IF;
                    END LOOP;
                
                    --Obtain the values for End_date/Duration/Execution according to the selected frequency
                    IF l_order_recurr_option <> -1 --When frequency is not set as 'Other frequency'
                    THEN
                        IF NOT pk_order_recurrence_core.set_order_recurr_option(i_lang                => i_lang,
                                                                                i_prof                => i_prof,
                                                                                i_order_recurr_plan   => l_order_recurr_plan,
                                                                                i_order_recurr_option => l_order_recurr_option,
                                                                                o_order_recurr_desc   => l_order_recurr_desc,
                                                                                o_start_date          => l_start_date,
                                                                                o_occurrences         => l_occurrences,
                                                                                o_duration            => l_duration,
                                                                                o_unit_meas_duration  => l_unit_meas_duration,
                                                                                o_end_date            => l_end_date,
                                                                                o_flg_end_by_editable => l_flg_end_by_editable,
                                                                                o_error               => o_error)
                        THEN
                            g_error := 'Error found while calling pk_order_recurrence_core.set_order_recurr_option function';
                            RAISE g_exception;
                        END IF;
                        l_order_recurr_option_aux := l_order_recurr_option;
                    ELSE
                        --Frequency set as 'Other frequency'
                        IF NOT
                            pk_order_recurrence_core.get_order_recurr_instructions(i_lang                => i_lang,
                                                                                   i_prof                => i_prof,
                                                                                   i_order_plan          => l_order_recurr_plan,
                                                                                   o_order_recurr_desc   => l_order_recurr_desc,
                                                                                   o_order_recurr_option => l_order_recurr_option,
                                                                                   o_start_date          => l_start_date,
                                                                                   o_occurrences         => l_occurrences,
                                                                                   o_duration            => l_duration,
                                                                                   o_unit_meas_duration  => l_unit_meas_duration,
                                                                                   o_end_date            => l_end_date,
                                                                                   o_flg_end_by_editable => l_flg_end_by_editable,
                                                                                   o_error               => o_error)
                        THEN
                            g_error := 'error while calling get_order_recurr_instructions function';
                            RAISE g_exception;
                        END IF;
                    
                        l_order_recurr_option_aux := l_order_recurr_option;
                    
                        FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                        LOOP
                            l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
                        
                            IF l_ds_internal_name = pk_orders_constant.g_ds_frequency
                            THEN
                                l_order_recurr_option := to_number(i_value(i) (1));
                                l_order_recurr_desc   := i_value_desc(i) (1);
                            END IF;
                        END LOOP;
                    END IF;
                ELSIF l_curr_comp_int_name = pk_orders_constant.g_ds_start_date
                THEN
                    --Check if it is a valid date
                    l_aux_val := pk_orders_utils.get_value(i_internal_name_child => l_curr_comp_int_name,
                                                           i_tbl_mkt_rel         => i_tbl_mkt_rel,
                                                           i_value               => i_value);
                
                    IF NOT pk_episode.get_epis_dt_begin_tstz(i_lang          => i_lang,
                                                             i_prof          => i_prof,
                                                             i_id_episode    => i_episode,
                                                             o_dt_begin_tstz => l_dt_epis_begin,
                                                             o_error         => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                
                    l_date_comparison := pk_date_utils.compare_dates_tsz(i_prof  => i_prof,
                                                                         i_date1 => pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                                                                                     i_timestamp => l_dt_epis_begin,
                                                                                                                     i_format    => 'MI'),
                                                                         i_date2 => pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                                                                                     i_timestamp => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                                                  i_prof,
                                                                                                                                                                  l_aux_val,
                                                                                                                                                                  NULL),
                                                                                                                     i_format    => 'MI'));
                
                    IF l_date_comparison = 'G'
                    THEN
                        tbl_result.extend();
                        SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => d.id_ds_cmpt_mkt_rel,
                                                  id_ds_component    => d.id_ds_component_child,
                                                  internal_name      => d.internal_name_child,
                                                  VALUE              => NULL,
                                                  value_clob         => NULL,
                                                  min_value          => NULL,
                                                  max_value          => NULL,
                                                  desc_value         => NULL,
                                                  desc_clob          => NULL,
                                                  id_unit_measure    => d.id_unit_measure,
                                                  desc_unit_measure  => pk_unit_measure.get_unit_measure_description(i_lang         => i_lang,
                                                                                                                     i_prof         => i_prof,
                                                                                                                     i_unit_measure => d.id_unit_measure),
                                                  flg_validation     => pk_orders_constant.g_component_error,
                                                  err_msg            => pk_message.get_message(i_lang, 'POSITIONING_T024'),
                                                  flg_event_type     => pk_orders_constant.g_component_mandatory,
                                                  flg_multi_status   => NULL,
                                                  idx                => i_idx)
                          INTO tbl_result(tbl_result.count)
                          FROM ds_cmpt_mkt_rel d
                         WHERE d.id_ds_cmpt_mkt_rel = i_curr_component;
                    ELSE
                        FOR i IN i_tbl_int_name.first .. i_tbl_int_name.last
                        LOOP
                            IF i_tbl_int_name(i) = pk_orders_constant.g_ds_dummy_number
                            THEN
                                l_order_recurr_plan := to_number(i_value(i) (1));
                            ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_start_date
                            THEN
                                l_timestamp_start := i_value(i) (1);
                            ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_executions
                            THEN
                                l_occurrences := to_number(i_value(i) (1));
                            ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_duration
                            THEN
                                l_duration           := to_number(i_value(i) (1));
                                l_unit_meas_duration := to_number(i_value_mea(i) (1));
                            ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_end_date
                            THEN
                                l_timestamp_end := i_value(i) (1);
                            END IF;
                        END LOOP;
                    
                        --If we set the number of executions then the field Duration must be null and vice-versa.
                        IF NOT
                            pk_order_recurrence_core.set_order_recurr_instructions(i_lang                => i_lang,
                                                                                   i_prof                => i_prof,
                                                                                   i_order_recurr_plan   => l_order_recurr_plan,
                                                                                   i_start_date          => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                          i_prof,
                                                                                                                                          l_timestamp_start,
                                                                                                                                          NULL),
                                                                                   i_occurrences         => l_occurrences,
                                                                                   i_duration            => l_duration,
                                                                                   i_unit_meas_duration  => l_unit_meas_duration,
                                                                                   i_end_date            => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                          i_prof,
                                                                                                                                          l_timestamp_end,
                                                                                                                                          NULL),
                                                                                   o_order_recurr_desc   => l_order_recurr_desc,
                                                                                   o_start_date          => l_start_date,
                                                                                   o_order_recurr_option => l_order_recurr_option,
                                                                                   o_occurrences         => l_occurrences,
                                                                                   o_duration            => l_duration,
                                                                                   o_unit_meas_duration  => l_unit_meas_duration,
                                                                                   o_end_date            => l_end_date,
                                                                                   o_flg_end_by_editable => l_flg_end_by_editable,
                                                                                   o_error               => o_error)
                        THEN
                            g_error := 'Error found while calling pk_order_recurrence_core.set_order_recurr_instructions function';
                            RAISE g_exception;
                        END IF;
                    
                        l_order_recurr_option_aux := l_order_recurr_option;
                    
                    END IF;
                ELSIF l_curr_comp_int_name IN (pk_orders_constant.g_ds_executions,
                                               pk_orders_constant.g_ds_duration,
                                               pk_orders_constant.g_ds_end_date)
                THEN
                    --If we set the number of executions then the field Duration must be null and vice-versa.                                              
                    FOR i IN i_tbl_int_name.first .. i_tbl_int_name.last
                    LOOP
                        IF i_tbl_int_name(i) = pk_orders_constant.g_ds_dummy_number
                        THEN
                            l_order_recurr_plan := to_number(i_value(i) (1));
                        ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_executions
                              AND l_curr_comp_int_name NOT IN
                              (pk_orders_constant.g_ds_duration, pk_orders_constant.g_ds_end_date)
                        THEN
                            l_occurrences := to_number(i_value(i) (1));
                        ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_start_date
                        THEN
                            l_timestamp_start := i_value(i) (1);
                        ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_end_date
                        THEN
                            l_timestamp_end := i_value(i) (1);
                        ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_duration
                              AND l_curr_comp_int_name NOT IN
                              (pk_orders_constant.g_ds_executions, pk_orders_constant.g_ds_end_date)
                        THEN
                            l_duration           := to_number(i_value(i) (1));
                            l_unit_meas_duration := to_number(i_value_mea(i) (1));
                        END IF;
                    END LOOP;
                
                    IF NOT pk_order_recurrence_core.set_order_recurr_instructions(i_lang                => i_lang,
                                                                                  i_prof                => i_prof,
                                                                                  i_order_recurr_plan   => l_order_recurr_plan,
                                                                                  i_start_date          => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                         i_prof,
                                                                                                                                         l_timestamp_start,
                                                                                                                                         NULL),
                                                                                  i_occurrences         => l_occurrences,
                                                                                  i_duration            => l_duration,
                                                                                  i_unit_meas_duration  => l_unit_meas_duration,
                                                                                  i_end_date            => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                         i_prof,
                                                                                                                                         l_timestamp_end,
                                                                                                                                         NULL),
                                                                                  o_order_recurr_desc   => l_order_recurr_desc,
                                                                                  o_start_date          => l_start_date,
                                                                                  o_order_recurr_option => l_order_recurr_option,
                                                                                  o_occurrences         => l_occurrences,
                                                                                  o_duration            => l_duration,
                                                                                  o_unit_meas_duration  => l_unit_meas_duration,
                                                                                  o_end_date            => l_end_date,
                                                                                  o_flg_end_by_editable => l_flg_end_by_editable,
                                                                                  o_error               => o_error)
                    THEN
                        g_error := 'Error found while calling pk_order_recurrence_core.set_order_recurr_instructions function';
                        RAISE g_exception;
                    END IF;
                
                    l_order_recurr_option_aux := l_order_recurr_option;
                
                    IF l_curr_comp_int_name IN (pk_orders_constant.g_ds_executions, pk_orders_constant.g_ds_duration)
                    THEN
                        IF l_duration IS NULL
                           AND l_occurrences IS NULL
                        THEN
                            l_end_date := NULL;
                        END IF;
                    END IF;
                ELSIF l_curr_comp_int_name IN (pk_orders_constant.g_ds_other_frequency)
                THEN
                    l_order_recurr_plan := to_number(pk_orders_utils.get_value(pk_orders_constant.g_ds_dummy_number,
                                                                               i_tbl_mkt_rel,
                                                                               i_value));
                    --If we set the number of executions then the field Duration must be null and vice-versa.
                    IF NOT pk_order_recurrence_core.get_order_recurr_instructions(i_lang                => i_lang,
                                                                                  i_prof                => i_prof,
                                                                                  i_order_plan          => l_order_recurr_plan,
                                                                                  o_order_recurr_desc   => l_order_recurr_desc,
                                                                                  o_order_recurr_option => l_order_recurr_option,
                                                                                  o_start_date          => l_start_date,
                                                                                  o_occurrences         => l_occurrences,
                                                                                  o_duration            => l_duration,
                                                                                  o_unit_meas_duration  => l_unit_meas_duration,
                                                                                  o_end_date            => l_end_date,
                                                                                  o_flg_end_by_editable => l_flg_end_by_editable,
                                                                                  o_error               => o_error)
                    THEN
                        g_error := 'error while calling get_order_recurr_instructions function';
                        RAISE g_exception;
                    END IF;
                
                    --This variable will hold the true recurr option of the form
                    --because the user may change to the option 'Other frequencies', and when calling the othr frequencies modal, 
                    --if the modal is cancelled, the form must return to the previous frequency
                    l_order_recurr_option_aux := l_order_recurr_option;
                
                    IF l_order_recurr_option_aux <> -1
                    THEN
                        FOR i IN i_tbl_int_name.first .. i_tbl_int_name.last
                        LOOP
                            IF i_tbl_int_name(i) = pk_orders_constant.g_ds_frequency
                            THEN
                                l_order_recurr_option := to_number(i_value(i) (1));
                                l_order_recurr_desc   := i_value_desc(i) (1);
                            END IF;
                        END LOOP;
                    END IF;
                END IF;
            
                FOR i IN i_tbl_int_name.first .. i_tbl_int_name.last
                LOOP
                    IF i_tbl_int_name(i) = pk_orders_constant.g_ds_frequency
                    THEN
                        l_recurrence_form_value := i_value(i) (1);
                        EXIT;
                    END IF;
                END LOOP;
            
                IF l_date_comparison IS NULL
                   OR l_date_comparison <> 'G'
                THEN
                    SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => t.id_ds_cmpt_mkt_rel,
                                               id_ds_component    => t.id_ds_component_child,
                                               internal_name      => t.internal_name_child,
                                               VALUE              => CASE
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_frequency
                                                                              AND l_order_recurr_option <> -1 THEN
                                                                          to_char(l_order_recurr_option)
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_other_frequency
                                                                              AND l_order_recurr_option_aux = -1 THEN
                                                                          to_char(l_order_recurr_option)
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_start_date THEN
                                                                          CASE
                                                                              WHEN l_start_date IS NOT NULL THEN
                                                                               pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => l_start_date, i_prof => i_prof)
                                                                              ELSE
                                                                               l_start_date_str
                                                                          END
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_executions THEN
                                                                          to_char(l_occurrences)
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_duration
                                                                              AND l_duration IS NOT NULL THEN
                                                                          to_char(l_duration)
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_end_date THEN
                                                                          pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => l_end_date, i_prof => i_prof)
                                                                         ELSE
                                                                          NULL
                                                                     END,
                                               value_clob         => NULL,
                                               min_value          => NULL,
                                               max_value          => NULL,
                                               desc_value         => CASE
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_frequency
                                                                              AND l_order_recurr_option <> -1 THEN
                                                                          l_order_recurr_desc
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_other_frequency
                                                                              AND l_order_recurr_option_aux = -1 THEN
                                                                          l_order_recurr_desc
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_executions THEN
                                                                          to_char(l_occurrences)
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_duration
                                                                              AND l_duration IS NOT NULL THEN
                                                                          to_char(l_duration) || ' ' ||
                                                                          pk_unit_measure.get_unit_measure_description(i_lang         => i_lang,
                                                                                                                       i_prof         => i_prof,
                                                                                                                       i_unit_measure => l_unit_meas_duration)
                                                                         ELSE
                                                                          NULL
                                                                     END,
                                               desc_clob          => NULL,
                                               id_unit_measure    => CASE
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_duration THEN
                                                                          l_unit_meas_duration
                                                                         ELSE
                                                                          t.id_unit_measure
                                                                     END,
                                               desc_unit_measure  => NULL,
                                               flg_validation     => pk_orders_constant.g_component_valid,
                                               err_msg            => NULL,
                                               flg_event_type     => CASE
                                                                         WHEN t.internal_name_child IN (pk_orders_constant.g_ds_start_date)
                                                                              AND i_episode IS NOT NULL THEN
                                                                          pk_orders_constant.g_component_mandatory
                                                                         WHEN t.internal_name_child IN (pk_orders_constant.g_ds_end_date)
                                                                              AND i_episode IS NOT NULL THEN
                                                                          decode(l_flg_end_by_editable,
                                                                                 pk_alert_constant.g_yes,
                                                                                 pk_orders_constant.g_component_active,
                                                                                 pk_orders_constant.g_component_inactive)
                                                                         WHEN t.internal_name_child IN
                                                                              (pk_orders_constant.g_ds_start_date, pk_orders_constant.g_ds_end_date)
                                                                              AND i_episode IS NULL THEN
                                                                          pk_orders_constant.g_component_inactive
                                                                         WHEN t.internal_name_child IN (pk_orders_constant.g_ds_executions) THEN
                                                                          decode(l_flg_end_by_editable,
                                                                                 pk_alert_constant.g_yes,
                                                                                 pk_orders_constant.g_component_active,
                                                                                 pk_orders_constant.g_component_read_only)
                                                                         WHEN t.internal_name_child IN (pk_orders_constant.g_ds_duration) THEN
                                                                          decode(l_flg_end_by_editable,
                                                                                 pk_alert_constant.g_yes,
                                                                                 pk_orders_constant.g_component_active,
                                                                                 pk_orders_constant.g_component_inactive)
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_other_frequency THEN
                                                                          CASE
                                                                              WHEN l_order_recurr_option = -1 THEN
                                                                               pk_orders_constant.g_component_mandatory
                                                                              ELSE
                                                                               pk_orders_constant.g_component_inactive
                                                                          END
                                                                         ELSE
                                                                          NULL
                                                                     END,
                                               flg_multi_status   => NULL,
                                               idx                => i_idx)
                      BULK COLLECT
                      INTO tbl_result
                      FROM (SELECT dc.id_ds_cmpt_mkt_rel,
                                   dc.id_ds_component_child,
                                   dc.internal_name_child,
                                   dc.flg_event_type,
                                   dc.rn,
                                   dc.flg_component_type_child,
                                   dc.id_unit_measure
                              FROM TABLE(pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                                 i_prof           => i_prof,
                                                                 i_patient        => NULL,
                                                                 i_component_name => i_root_name,
                                                                 i_action         => NULL)) dc) t
                      JOIN ds_component d
                        ON d.id_ds_component = t.id_ds_component_child
                     WHERE --A pair of d.internal_name and l_curr_comp_int_name to assure that we are only setting values for the intended fields
                     (l_curr_comp_int_name IN (pk_orders_constant.g_ds_frequency,
                                               pk_orders_constant.g_ds_start_date,
                                               pk_orders_constant.g_ds_executions,
                                               pk_orders_constant.g_ds_duration,
                                               pk_orders_constant.g_ds_end_date) AND
                     d.internal_name IN (pk_orders_constant.g_ds_start_date,
                                          pk_orders_constant.g_ds_executions,
                                          pk_orders_constant.g_ds_duration,
                                          pk_orders_constant.g_ds_end_date,
                                          pk_orders_constant.g_ds_other_frequency))
                    --'Outra frequ�ncia'                
                     OR (l_curr_comp_int_name = pk_orders_constant.g_ds_other_frequency AND
                     d.internal_name IN (pk_orders_constant.g_ds_other_frequency,
                                          pk_orders_constant.g_ds_start_date,
                                          pk_orders_constant.g_ds_executions,
                                          pk_orders_constant.g_ds_duration,
                                          pk_orders_constant.g_ds_end_date) AND l_order_recurr_option = -1);
                END IF;
            
                FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                LOOP
                    l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
                
                    IF l_ds_internal_name = pk_orders_constant.g_ds_ok_button_control
                    THEN
                        l_id_ds_component := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                        process_ok_button_control(i_id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                  i_id_ds_component    => l_id_ds_component,
                                                  i_ds_internal_name   => l_ds_internal_name);
                    END IF;
                END LOOP;
            ELSE
                --Selecting/Deselecting elements in the viewer
                --For this action we must check if the fields Duration, End date/time and Other frequencies should be active or inactive
                FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                LOOP
                    l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
                
                    IF l_ds_internal_name = pk_orders_constant.g_ds_dummy_number
                    THEN
                        l_order_recurr_plan := to_number(i_value(i) (1));
                    ELSIF l_ds_internal_name = pk_orders_constant.g_ds_frequency
                    THEN
                        l_order_recurr_option := to_number(i_value(i) (1));
                    END IF;
                END LOOP;
            
                IF NOT pk_order_recurrence_core.get_order_recurr_instructions(i_lang                => i_lang,
                                                                              i_prof                => i_prof,
                                                                              i_order_plan          => l_order_recurr_plan,
                                                                              o_order_recurr_desc   => l_order_recurr_desc,
                                                                              o_order_recurr_option => l_order_recurr_option,
                                                                              o_start_date          => l_start_date,
                                                                              o_occurrences         => l_occurrences,
                                                                              o_duration            => l_duration,
                                                                              o_unit_meas_duration  => l_unit_meas_duration,
                                                                              o_end_date            => l_end_date,
                                                                              o_flg_end_by_editable => l_flg_end_by_editable,
                                                                              o_error               => o_error)
                THEN
                    g_error := 'error while calling get_order_recurr_instructions function';
                    RAISE g_exception;
                END IF;
            
                SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => t.id_ds_cmpt_mkt_rel,
                                           id_ds_component    => t.id_ds_component_child,
                                           internal_name      => t.internal_name_child,
                                           VALUE              => CASE
                                                                     WHEN t.internal_name_child = pk_orders_constant.g_ds_other_frequency
                                                                          AND l_order_recurr_option = -1 THEN
                                                                      l_order_recurr_desc
                                                                     WHEN t.internal_name_child = pk_orders_constant.g_ds_executions THEN
                                                                      to_char(l_occurrences)
                                                                     WHEN t.internal_name_child = pk_orders_constant.g_ds_duration
                                                                          AND l_duration IS NOT NULL THEN
                                                                      to_char(l_duration)
                                                                     WHEN t.internal_name_child = pk_orders_constant.g_ds_end_date
                                                                          AND i_episode IS NOT NULL THEN
                                                                      pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => l_end_date, i_prof => i_prof)
                                                                     ELSE
                                                                      NULL
                                                                 END,
                                           value_clob         => NULL,
                                           min_value          => NULL,
                                           max_value          => NULL,
                                           desc_value         => CASE
                                                                     WHEN t.internal_name_child = pk_orders_constant.g_ds_other_frequency
                                                                          AND l_order_recurr_option = -1 THEN
                                                                      l_order_recurr_desc
                                                                     WHEN t.internal_name_child = pk_orders_constant.g_ds_executions THEN
                                                                      to_char(l_occurrences)
                                                                     WHEN t.internal_name_child = pk_orders_constant.g_ds_duration
                                                                          AND l_duration IS NOT NULL THEN
                                                                      to_char(l_duration) || ' ' ||
                                                                      pk_unit_measure.get_unit_measure_description(i_lang         => i_lang,
                                                                                                                   i_prof         => i_prof,
                                                                                                                   i_unit_measure => l_unit_meas_duration)
                                                                     ELSE
                                                                      NULL
                                                                 END,
                                           desc_clob          => NULL,
                                           id_unit_measure    => CASE
                                                                     WHEN t.internal_name_child IN (pk_orders_constant.g_ds_duration) THEN
                                                                      to_number(pk_orders_utils.get_value(i_internal_name_child => t.internal_name_child,
                                                                                                          i_tbl_mkt_rel         => i_tbl_mkt_rel,
                                                                                                          i_value               => i_value_mea))
                                                                     ELSE
                                                                      NULL
                                                                 END,
                                           desc_unit_measure  => NULL,
                                           flg_validation     => pk_alert_constant.g_yes,
                                           err_msg            => NULL,
                                           flg_event_type     => CASE
                                                                     WHEN t.internal_name_child IN (pk_orders_constant.g_ds_end_date)
                                                                          AND i_episode IS NULL THEN
                                                                      pk_orders_constant.g_component_inactive
                                                                     WHEN t.internal_name_child IN (pk_orders_constant.g_ds_end_date)
                                                                          AND i_episode IS NOT NULL THEN
                                                                      decode(l_flg_end_by_editable,
                                                                             pk_alert_constant.g_yes,
                                                                             pk_orders_constant.g_component_active,
                                                                             pk_orders_constant.g_component_inactive)
                                                                     WHEN t.internal_name_child = pk_orders_constant.g_ds_other_frequency THEN
                                                                      decode(l_order_recurr_option,
                                                                             -1,
                                                                             pk_orders_constant.g_component_mandatory,
                                                                             pk_orders_constant.g_component_inactive)
                                                                     WHEN t.internal_name_child IN (pk_orders_constant.g_ds_duration) THEN
                                                                     --If l_flg_end_by_editable = 'N', fields duration and end date must be inactive
                                                                      decode(l_flg_end_by_editable,
                                                                             pk_alert_constant.g_yes,
                                                                             pk_orders_constant.g_component_active,
                                                                             pk_orders_constant.g_component_inactive)
                                                                     WHEN t.internal_name_child IN (pk_orders_constant.g_ds_executions) THEN
                                                                     --If l_flg_end_by_editable = 'N', field 'Exections' must be Read Only and present the value given by l_occurrences
                                                                      decode(l_flg_end_by_editable,
                                                                             pk_alert_constant.g_yes,
                                                                             pk_orders_constant.g_component_active,
                                                                             pk_orders_constant.g_component_read_only)
                                                                 END,
                                           flg_multi_status   => NULL,
                                           idx                => i_idx)
                  BULK COLLECT
                  INTO tbl_result
                  FROM (SELECT dc.id_ds_cmpt_mkt_rel,
                               dc.id_ds_component_child,
                               dc.internal_name_child,
                               dc.flg_event_type,
                               dc.rn,
                               dc.flg_component_type_child,
                               dc.id_unit_measure
                          FROM TABLE(pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                             i_prof           => i_prof,
                                                             i_patient        => NULL,
                                                             i_component_name => i_root_name,
                                                             i_action         => NULL)) dc) t
                  JOIN ds_component d
                    ON d.id_ds_component = t.id_ds_component_child
                 WHERE d.internal_name IN (pk_orders_constant.g_ds_executions,
                                           pk_orders_constant.g_ds_duration,
                                           pk_orders_constant.g_ds_end_date,
                                           pk_orders_constant.g_ds_other_frequency)
                 ORDER BY t.rn;
            
                --RESTANTES ELEMENTOS
                FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                LOOP
                    --l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
                    l_id_ds_component := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                
                    IF i_tbl_int_name(i) IN (pk_orders_constant.g_ds_clinical_indication_mw,
                                             pk_orders_constant.g_ds_clinical_indication_icnp_mw)
                    THEN
                        tbl_result.extend();
                        tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                           id_ds_component    => l_id_ds_component,
                                                                           internal_name      => i_tbl_int_name(i),
                                                                           VALUE              => NULL,
                                                                           min_value          => NULL,
                                                                           max_value          => NULL,
                                                                           value_clob         => NULL,
                                                                           desc_value         => NULL,
                                                                           desc_clob          => NULL,
                                                                           id_unit_measure    => NULL,
                                                                           desc_unit_measure  => NULL,
                                                                           flg_validation     => pk_alert_constant.g_yes,
                                                                           err_msg            => NULL,
                                                                           flg_event_type     => pk_orders_constant.g_component_inactive,
                                                                           flg_multi_status   => NULL,
                                                                           idx                => i_idx);
                    ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_to_be_executed
                    THEN
                        tbl_result.extend();
                        tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                           id_ds_component    => l_id_ds_component,
                                                                           internal_name      => i_tbl_int_name(i),
                                                                           VALUE              => i_value(i) (1),
                                                                           min_value          => NULL,
                                                                           max_value          => NULL,
                                                                           value_clob         => NULL,
                                                                           desc_value         => i_value_desc(i) (1),
                                                                           desc_clob          => NULL,
                                                                           id_unit_measure    => NULL,
                                                                           desc_unit_measure  => NULL,
                                                                           flg_validation     => pk_alert_constant.g_yes,
                                                                           err_msg            => NULL,
                                                                           flg_event_type     => CASE
                                                                                                     WHEN i_episode IS NULL THEN
                                                                                                      pk_orders_constant.g_component_read_only
                                                                                                     ELSE
                                                                                                      pk_orders_constant.g_component_mandatory
                                                                                                 END,
                                                                           flg_multi_status   => NULL,
                                                                           idx                => i_idx);
                    ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_frequency
                    THEN
                        tbl_result.extend();
                        tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                           id_ds_component    => l_id_ds_component,
                                                                           internal_name      => i_tbl_int_name(i),
                                                                           VALUE              => i_value(i) (1),
                                                                           min_value          => NULL,
                                                                           max_value          => NULL,
                                                                           value_clob         => NULL,
                                                                           desc_value         => i_value_desc(i) (1),
                                                                           desc_clob          => NULL,
                                                                           id_unit_measure    => NULL,
                                                                           desc_unit_measure  => NULL,
                                                                           flg_validation     => pk_alert_constant.g_yes,
                                                                           err_msg            => NULL,
                                                                           flg_event_type     => pk_orders_constant.g_component_mandatory,
                                                                           flg_multi_status   => NULL,
                                                                           idx                => i_idx);
                    ELSIF i_tbl_int_name(i) IN (pk_orders_constant.g_ds_start_date)
                    THEN
                        tbl_result.extend();
                        tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                           id_ds_component    => l_id_ds_component,
                                                                           internal_name      => i_tbl_int_name(i),
                                                                           VALUE              => pk_date_utils.date_send_tsz(i_lang => i_lang,
                                                                                                                             i_date => l_start_date,
                                                                                                                             i_prof => i_prof),
                                                                           min_value          => NULL,
                                                                           max_value          => NULL,
                                                                           value_clob         => NULL,
                                                                           desc_value         => NULL,
                                                                           desc_clob          => NULL,
                                                                           id_unit_measure    => NULL,
                                                                           desc_unit_measure  => NULL,
                                                                           flg_validation     => pk_alert_constant.g_yes,
                                                                           err_msg            => NULL,
                                                                           flg_event_type     => CASE
                                                                                                     WHEN i_episode IS NULL THEN
                                                                                                      pk_orders_constant.g_component_inactive
                                                                                                     ELSE
                                                                                                      pk_orders_constant.g_component_mandatory
                                                                                                 END,
                                                                           flg_multi_status   => NULL,
                                                                           idx                => i_idx);
                    ELSIF i_tbl_int_name(i) IN
                          (pk_orders_constant.g_ds_notes_clob, pk_orders_constant.g_ds_description)
                    THEN
                        tbl_result.extend();
                        tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                           id_ds_component    => l_id_ds_component,
                                                                           internal_name      => i_tbl_int_name(i),
                                                                           VALUE              => NULL,
                                                                           min_value          => NULL,
                                                                           max_value          => NULL,
                                                                           value_clob         => NULL,
                                                                           desc_value         => NULL,
                                                                           desc_clob          => i_value_clob(i),
                                                                           id_unit_measure    => NULL,
                                                                           desc_unit_measure  => NULL,
                                                                           flg_validation     => pk_alert_constant.g_yes,
                                                                           err_msg            => NULL,
                                                                           flg_event_type     => pk_orders_constant.g_component_active,
                                                                           flg_multi_status   => NULL,
                                                                           idx                => i_idx);
                    ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_dummy_number
                    THEN
                        tbl_result.extend();
                        tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                           id_ds_component    => l_id_ds_component,
                                                                           internal_name      => i_tbl_int_name(i),
                                                                           VALUE              => l_order_recurr_plan,
                                                                           min_value          => NULL,
                                                                           max_value          => NULL,
                                                                           value_clob         => NULL,
                                                                           desc_value         => to_char(l_order_recurr_plan),
                                                                           desc_clob          => NULL,
                                                                           id_unit_measure    => NULL,
                                                                           desc_unit_measure  => NULL,
                                                                           flg_validation     => pk_alert_constant.g_yes,
                                                                           err_msg            => NULL,
                                                                           flg_event_type     => pk_orders_constant.g_component_active,
                                                                           flg_multi_status   => NULL,
                                                                           idx                => i_idx);
                    ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_ok_button_control
                    THEN
                    
                        l_id_ds_component := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                    
                        process_ok_button_control(i_id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                  i_id_ds_component    => l_id_ds_component,
                                                  i_ds_internal_name   => i_tbl_int_name(i));
                    END IF;
                END LOOP;
            END IF;
        ELSIF i_action IN (pk_order_sets.g_order_set_bo_edit_task, pk_order_sets.g_order_set_fo_request)
        THEN
            g_error := 'Error calling pk_patient_education_core.get_request_for_update';
            IF NOT pk_patient_education_core.get_request_for_update(i_lang             => i_lang,
                                                                    i_prof             => i_prof,
                                                                    i_episode          => i_episode,
                                                                    i_action           => i_action,
                                                                    i_id_nurse_tea_req => i_tbl_id_pk(i_idx),
                                                                    i_idx              => i_idx,
                                                                    i_tbl_mkt_rel      => i_tbl_mkt_rel,
                                                                    io_tbl_resul       => tbl_result,
                                                                    o_error            => o_error)
            THEN
                g_error := 'Error found while calling pk_patient_education_constant.g_et_request_for_update function';
                RAISE g_exception;
            END IF;
        END IF;
    
        RETURN tbl_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_db_object_name,
                                              o_error);
            RETURN NULL;
    END get_os_he_order_values;

    FUNCTION get_request_for_execution
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN NUMBER,
        i_action               IN NUMBER,
        i_tbl_id_nurse_tea_req IN table_number,
        i_curr_component       IN NUMBER,
        i_idx                  IN NUMBER,
        i_tbl_mkt_rel          IN table_number,
        i_value                IN table_table_varchar,
        i_value_mea            IN table_table_varchar,
        i_value_desc           IN table_table_varchar,
        i_value_clob           IN table_clob,
        o_error                OUT t_error_out
    ) RETURN t_tbl_ds_get_value IS
    
        l_tbl_id_diag     table_table_number;
        l_tbl_diag_desc   table_table_varchar;
        l_tbl_description table_clob;
        l_duration        NUMBER;
        l_id_unit_measure unit_measure.id_unit_measure%TYPE;
        l_start_date      VARCHAR2(200);
        l_start_date_tstz TIMESTAMP WITH LOCAL TIME ZONE;
        l_end_date        VARCHAR2(200);
        l_end_date_tstz   TIMESTAMP WITH LOCAL TIME ZONE;
        l_elapsed_time    NUMBER;
    
        l_index_current_component NUMBER;
    
        l_curr_component_int_name ds_component.internal_name%TYPE;
        l_ds_internal_name        ds_component.internal_name%TYPE;
        l_id_ds_component         ds_component.id_ds_component%TYPE;
        l_ds_internal_name_aux    ds_component.internal_name%TYPE;
    
        l_count_diagnoses NUMBER := 0;
    
        l_clinical_service    table_number;
        l_id_default_option   nurse_tea_opt_inst.id_nurse_tea_opt%TYPE;
        l_default_option_desc VARCHAR2(4000);
    
        l_multiple_start_date BOOLEAN := FALSE;
    
        l_flg_validation VARCHAR2(1) := pk_alert_constant.g_yes;
        l_err_msg        VARCHAR2(4000);
    
        l_flg_free_text_active VARCHAR2(1) := pk_orders_constant.g_component_inactive;
    
        l_tbl_result t_tbl_ds_get_value := t_tbl_ds_get_value();
    
        FUNCTION get_component_index(i_component IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE) RETURN NUMBER IS
        BEGIN
        
            FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
            LOOP
                IF i_tbl_mkt_rel(i) = i_component
                THEN
                    RETURN i;
                END IF;
            END LOOP;
        
            RETURN NULL;
        
        EXCEPTION
            WHEN OTHERS THEN
                RETURN NULL;
        END get_component_index;
    
        FUNCTION get_date_validation
        (
            i_date           IN nurse_tea_req.dt_begin_tstz%TYPE,
            o_flg_validation OUT VARCHAR2,
            o_err_message    OUT VARCHAR2
        ) RETURN BOOLEAN IS
            l_dt_start_date_min  TIMESTAMP WITH LOCAL TIME ZONE;
            l_flg_validation_aux VARCHAR2(1) := pk_alert_constant.g_yes;
            l_err_msg_aux        VARCHAR2(4000);
        BEGIN
        
            IF pk_date_utils.compare_dates_tsz(i_prof => i_prof, i_date1 => i_date, i_date2 => g_sysdate_tstz) = 'G'
            THEN
                l_flg_validation_aux := pk_orders_constant.g_component_error;
                l_err_msg_aux        := pk_message.get_message(i_lang, 'POSITIONING_M041');
            ELSE
            
                SELECT MAX(dt) dt
                  INTO l_dt_start_date_min
                  FROM (SELECT MAX(dt_end) AS dt
                          FROM nurse_tea_det ntd
                         WHERE ntd.id_nurse_tea_req = i_tbl_id_nurse_tea_req(i_idx)
                           AND ntd.flg_status = 'E'
                        UNION
                        SELECT MIN(ntd.dt_start) AS dt
                          FROM nurse_tea_det ntd
                         WHERE ntd.id_nurse_tea_req = i_tbl_id_nurse_tea_req(i_idx)
                           AND ntd.flg_status = 'D'
                           AND NOT EXISTS (SELECT 1
                                  FROM nurse_tea_det ntd_i
                                 WHERE ntd_i.flg_status = 'E'
                                   AND ntd_i.id_nurse_tea_req = ntd.id_nurse_tea_req));
            
                IF pk_date_utils.date_mon_hour_format_tsz(i_lang => i_lang,
                                                          i_date => l_dt_start_date_min,
                                                          i_prof => i_prof) <>
                   pk_date_utils.date_mon_hour_format_tsz(i_lang => i_lang, i_date => i_date, i_prof => i_prof)
                THEN
                    IF pk_date_utils.compare_dates_tsz(i_prof  => i_prof,
                                                       i_date1 => l_dt_start_date_min,
                                                       i_date2 => i_date) = 'G'
                    THEN
                        l_flg_validation_aux := pk_orders_constant.g_component_error;
                        l_err_msg_aux        := pk_message.get_message(i_lang, 'POSITIONING_M040');
                    END IF;
                END IF;
            END IF;
        
            o_flg_validation := l_flg_validation_aux;
            o_err_message    := l_err_msg_aux;
        
            RETURN TRUE;
        
        EXCEPTION
            WHEN OTHERS THEN
                RETURN FALSE;
        END get_date_validation;
    
        PROCEDURE process_ok_button_control
        (
            i_id_ds_cmpt_mkt_rel IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
            i_id_ds_component    IN ds_component.id_ds_component%TYPE,
            i_ds_internal_name   IN ds_component.internal_name%TYPE
        ) IS
            l_ok_status VARCHAR2(1) := pk_orders_constant.g_component_valid;
        BEGIN
            FOR j IN l_tbl_result.first .. l_tbl_result.last
            LOOP
                IF (l_tbl_result(j).flg_event_type = pk_orders_constant.g_component_mandatory AND l_tbl_result(j).value IS NULL AND
                    nvl(length(l_tbl_result(j).value_clob), 0) = 0)
                   OR l_tbl_result(j).flg_validation = pk_orders_constant.g_component_error
                THEN
                    l_ok_status := pk_orders_constant.g_component_error;
                END IF;
            END LOOP;
        
            l_tbl_result.extend();
            l_tbl_result(l_tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_id_ds_cmpt_mkt_rel,
                                                                   id_ds_component    => i_id_ds_component,
                                                                   internal_name      => i_ds_internal_name,
                                                                   VALUE              => NULL,
                                                                   value_clob         => NULL,
                                                                   min_value          => NULL,
                                                                   max_value          => NULL,
                                                                   desc_value         => NULL,
                                                                   desc_clob          => NULL,
                                                                   id_unit_measure    => NULL,
                                                                   desc_unit_measure  => NULL,
                                                                   flg_validation     => l_ok_status,
                                                                   err_msg            => NULL,
                                                                   flg_event_type     => pk_orders_constant.g_component_active,
                                                                   flg_multi_status   => NULL,
                                                                   idx                => i_idx);
        END process_ok_button_control;
    
    BEGIN
    
        g_sysdate_tstz := nvl(g_sysdate_tstz, current_timestamp);
    
        IF i_action IS NULL
           OR i_action = -1 --NEW FORM
        THEN
            SELECT pk_patient_education_utils.get_id_diagnosis(i_lang, i_prof, ntr.id_nurse_tea_req),
                   pk_patient_education_utils.get_desc_diagnosis(i_lang, i_prof, ntr.id_nurse_tea_req),
                   ntr.description
              BULK COLLECT
              INTO l_tbl_id_diag, l_tbl_diag_desc, l_tbl_description
              FROM nurse_tea_req ntr
             WHERE ntr.id_nurse_tea_req = i_tbl_id_nurse_tea_req(i_idx);
        
            SELECT id_clinical_service
              BULK COLLECT
              INTO l_clinical_service
              FROM (SELECT d.id_clinical_service
                      FROM prof_dep_clin_serv p
                      JOIN dep_clin_serv d
                        ON d.id_dep_clin_serv = p.id_dep_clin_serv
                     WHERE p.id_professional = i_prof.id
                       AND p.id_institution = i_prof.institution
                       AND p.flg_status = g_selected
                       AND d.flg_available = pk_alert_constant.g_yes
                    UNION ALL
                    SELECT 0
                      FROM dual);
        
            FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
            LOOP
                l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
                l_id_ds_component  := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
            
                IF l_ds_internal_name = pk_orders_constant.g_ds_clinical_indication_mw
                THEN
                    FOR j IN l_tbl_id_diag.first .. l_tbl_id_diag.last
                    LOOP
                        IF l_tbl_id_diag(j).count > 0
                        THEN
                            FOR k IN l_tbl_id_diag(j).first .. l_tbl_id_diag(j).last
                            LOOP
                                l_tbl_result.extend();
                                l_tbl_result(l_tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                                       id_ds_component    => l_id_ds_component,
                                                                                       internal_name      => l_ds_internal_name,
                                                                                       VALUE              => to_char(l_tbl_id_diag(j) (k)),
                                                                                       value_clob         => NULL,
                                                                                       min_value          => NULL,
                                                                                       max_value          => NULL,
                                                                                       desc_value         => l_tbl_diag_desc(j) (k),
                                                                                       desc_clob          => NULL,
                                                                                       id_unit_measure    => NULL,
                                                                                       desc_unit_measure  => NULL,
                                                                                       flg_validation     => pk_orders_constant.g_component_valid,
                                                                                       err_msg            => NULL,
                                                                                       flg_event_type     => pk_orders_constant.g_component_read_only,
                                                                                       flg_multi_status   => NULL,
                                                                                       idx                => i_idx);
                            END LOOP;
                        ELSE
                            l_tbl_result.extend();
                            l_tbl_result(l_tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                                   id_ds_component    => l_id_ds_component,
                                                                                   internal_name      => l_ds_internal_name,
                                                                                   VALUE              => NULL,
                                                                                   value_clob         => NULL,
                                                                                   min_value          => NULL,
                                                                                   max_value          => NULL,
                                                                                   desc_value         => NULL,
                                                                                   desc_clob          => NULL,
                                                                                   id_unit_measure    => NULL,
                                                                                   desc_unit_measure  => NULL,
                                                                                   flg_validation     => pk_orders_constant.g_component_valid,
                                                                                   err_msg            => NULL,
                                                                                   flg_event_type     => pk_orders_constant.g_component_read_only,
                                                                                   flg_multi_status   => NULL,
                                                                                   idx                => i_idx);
                        END IF;
                    
                        l_count_diagnoses := l_count_diagnoses + l_tbl_id_diag(j).count;
                    END LOOP;
                ELSIF l_ds_internal_name = pk_orders_constant.g_ds_description
                THEN
                    FOR j IN l_tbl_description.first .. l_tbl_description.last
                    LOOP
                        l_tbl_result.extend();
                        l_tbl_result(l_tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => l_ds_internal_name,
                                                                               VALUE              => NULL,
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => NULL,
                                                                               desc_clob          => l_tbl_description(j),
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_orders_constant.g_component_valid,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => pk_orders_constant.g_component_active,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                    END LOOP;
                ELSIF l_ds_internal_name = pk_orders_constant.g_ds_start_date
                THEN
                    BEGIN
                        SELECT DISTINCT t.dt_start
                          INTO l_start_date_tstz
                          FROM (SELECT trunc(nvl(ntr.dt_begin_tstz, ntd.dt_start), 'MI') dt_start,
                                       row_number() over(PARTITION BY ntd.id_nurse_tea_req ORDER BY ntd.dt_start) AS rn
                                  FROM nurse_tea_det ntd
                                  LEFT JOIN nurse_tea_req ntr
                                    ON ntr.id_nurse_tea_req = ntd.id_nurse_tea_req
                                   AND ntr.flg_status = 'D'
                                 WHERE ntd.id_nurse_tea_req = i_tbl_id_nurse_tea_req(i_idx)
                                   AND ntd.flg_status = 'D'
                                 ORDER BY ntd.dt_start) t
                         WHERE t.rn = 1;
                    
                        -- @return 'G' if i_timestamp1 is more recent than i_timestamp2, 'E' if they are equal, 'L' otherwise 
                        --If the start date is scheduled for a date after the current timestamp, then the start date of the execution form
                        --will assume the the value of the current_timestamp 
                        IF pk_date_utils.compare_dates_tsz(i_prof  => i_prof,
                                                           i_date1 => l_start_date_tstz,
                                                           i_date2 => g_sysdate_tstz) = 'G'
                        THEN
                            l_start_date_tstz := NULL;
                        END IF;
                    
                        l_multiple_start_date := FALSE;
                    EXCEPTION
                        WHEN OTHERS THEN
                            --When there's more than one record selected with different start dates, the system will assume the current_timestamp 
                            --as the start date of the execution form.                            
                            l_start_date_tstz := NULL;
                            --HTML layer is having problems dealing with different start datesm therefore l_multiple_start_date has been created
                            --to activate/deactivate the duration and end date fields. (When multiple start dates => duration and end date inactives)
                            l_multiple_start_date := TRUE;
                    END;
                
                    l_tbl_result.extend();
                    l_tbl_result(l_tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                           id_ds_component    => l_id_ds_component,
                                                                           internal_name      => l_ds_internal_name,
                                                                           VALUE              => pk_date_utils.date_send_tsz(i_lang => i_lang,
                                                                                                                             i_date => nvl(l_start_date_tstz,
                                                                                                                                           g_sysdate_tstz),
                                                                                                                             i_prof => i_prof),
                                                                           value_clob         => NULL,
                                                                           min_value          => NULL,
                                                                           max_value          => NULL,
                                                                           desc_value         => pk_date_utils.date_send_tsz(i_lang => i_lang,
                                                                                                                             i_date => nvl(l_start_date_tstz,
                                                                                                                                           g_sysdate_tstz),
                                                                                                                             i_prof => i_prof),
                                                                           desc_clob          => NULL,
                                                                           id_unit_measure    => NULL,
                                                                           desc_unit_measure  => NULL,
                                                                           flg_validation     => pk_orders_constant.g_component_valid,
                                                                           err_msg            => NULL,
                                                                           flg_event_type     => pk_orders_constant.g_component_active,
                                                                           flg_multi_status   => NULL,
                                                                           idx                => i_idx);
                ELSIF l_ds_internal_name = pk_orders_constant.g_ds_duration
                THEN
                    l_tbl_result.extend();
                    l_tbl_result(l_tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                           id_ds_component    => l_id_ds_component,
                                                                           internal_name      => l_ds_internal_name,
                                                                           VALUE              => NULL,
                                                                           value_clob         => NULL,
                                                                           min_value          => NULL,
                                                                           max_value          => NULL,
                                                                           desc_value         => NULL,
                                                                           desc_clob          => NULL,
                                                                           id_unit_measure    => 10374, --MINUTES - DEFAULT UNIT FOR EXECUTION
                                                                           desc_unit_measure  => NULL,
                                                                           flg_validation     => pk_orders_constant.g_component_valid,
                                                                           err_msg            => NULL,
                                                                           flg_event_type     => pk_orders_constant.g_component_active,
                                                                           flg_multi_status   => NULL,
                                                                           idx                => i_idx);
                ELSIF l_ds_internal_name IN (pk_orders_constant.g_ds_health_education_goals,
                                             pk_orders_constant.g_ds_health_education_method,
                                             pk_orders_constant.g_ds_health_educ_given_to,
                                             pk_orders_constant.g_ds_health_educ_addit_res,
                                             pk_orders_constant.g_ds_health_educ_level_und)
                THEN
                    BEGIN
                        SELECT id_nurse_tea_opt, label
                          INTO l_id_default_option, l_default_option_desc
                          FROM (SELECT *
                                  FROM (SELECT nto.id_nurse_tea_opt,
                                               pk_translation.get_translation(i_lang, nto.code_nurse_tea_opt) label,
                                               ntoi.flg_default,
                                               row_number() over(PARTITION BY nto.id_nurse_tea_opt ORDER BY ntoi.id_institution DESC) AS rn
                                          FROM nurse_tea_opt nto
                                          JOIN nurse_tea_opt_inst ntoi
                                            ON ntoi.id_nurse_tea_opt = nto.id_nurse_tea_opt
                                         WHERE nto.subject = CASE
                                                   WHEN l_ds_internal_name =
                                                        pk_orders_constant.g_ds_health_education_goals THEN
                                                    'GOALS'
                                                   WHEN l_ds_internal_name =
                                                        pk_orders_constant.g_ds_health_education_method THEN
                                                    'METHOD'
                                                   WHEN l_ds_internal_name = pk_orders_constant.g_ds_health_educ_given_to THEN
                                                    'GIVEN_TO'
                                                   WHEN l_ds_internal_name = pk_orders_constant.g_ds_health_educ_addit_res THEN
                                                    'DELIVERABLES'
                                                   WHEN l_ds_internal_name = pk_orders_constant.g_ds_health_educ_level_und THEN
                                                    'LEVEL_OF_UNDERSTANDING'
                                               END
                                           AND nvl(ntoi.id_institution, 0) IN (0, i_prof.institution)
                                           AND nvl(ntoi.id_clinical_service, 0) IN
                                               (SELECT column_value
                                                  FROM TABLE(l_clinical_service)))
                                 WHERE rn = 1
                                   AND flg_default = pk_alert_constant.g_yes)
                         WHERE rownum = 1;
                    EXCEPTION
                        WHEN OTHERS THEN
                            l_id_default_option   := NULL;
                            l_default_option_desc := NULL;
                    END;
                
                    IF l_id_default_option IS NOT NULL
                    THEN
                        l_tbl_result.extend();
                        l_tbl_result(l_tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => l_ds_internal_name,
                                                                               VALUE              => to_char(l_id_default_option),
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => l_default_option_desc,
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_orders_constant.g_component_valid,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => pk_orders_constant.g_component_active,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                    END IF;
                ELSIF l_ds_internal_name = pk_orders_constant.g_ds_end_date
                THEN
                    l_tbl_result.extend();
                    l_tbl_result(l_tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                           id_ds_component    => l_id_ds_component,
                                                                           internal_name      => l_ds_internal_name,
                                                                           VALUE              => NULL,
                                                                           value_clob         => NULL,
                                                                           min_value          => NULL,
                                                                           max_value          => NULL,
                                                                           desc_value         => NULL,
                                                                           desc_clob          => NULL,
                                                                           id_unit_measure    => NULL,
                                                                           desc_unit_measure  => NULL,
                                                                           flg_validation     => pk_orders_constant.g_component_valid,
                                                                           err_msg            => NULL,
                                                                           flg_event_type     => pk_orders_constant.g_component_active,
                                                                           flg_multi_status   => NULL,
                                                                           idx                => i_idx);
                ELSIF l_ds_internal_name = pk_orders_constant.g_ds_ok_button_control
                THEN
                    l_tbl_result.extend();
                    l_tbl_result(l_tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                           id_ds_component    => l_id_ds_component,
                                                                           internal_name      => l_ds_internal_name,
                                                                           VALUE              => NULL,
                                                                           value_clob         => NULL,
                                                                           min_value          => NULL,
                                                                           max_value          => NULL,
                                                                           desc_value         => NULL,
                                                                           desc_clob          => NULL,
                                                                           id_unit_measure    => NULL,
                                                                           desc_unit_measure  => NULL,
                                                                           flg_validation     => pk_orders_constant.g_component_valid,
                                                                           err_msg            => NULL,
                                                                           flg_event_type     => pk_orders_constant.g_component_active,
                                                                           flg_multi_status   => NULL,
                                                                           idx                => i_idx);
                END IF;
            END LOOP;
        ELSIF i_action = pk_dyn_form_constant.get_submit_action
              AND i_curr_component IS NOT NULL --CHANGING VALUES ON THE FORM
        THEN
            l_index_current_component := get_component_index(i_curr_component);
            l_ds_internal_name        := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(l_index_current_component));
        
            IF l_ds_internal_name = pk_orders_constant.g_ds_start_date
            THEN
                FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                LOOP
                    l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
                
                    IF l_ds_internal_name = pk_orders_constant.g_ds_start_date
                    THEN
                        l_start_date      := i_value(i) (1);
                        l_start_date_tstz := pk_date_utils.get_string_tstz(i_lang, i_prof, i_value(i) (1), NULL);
                    
                        g_error := 'Error calling pk_patient_education_constant.g_et_date_validation function';
                        IF NOT get_date_validation(i_date           => l_start_date_tstz,
                                                   o_flg_validation => l_flg_validation,
                                                   o_err_message    => l_err_msg)
                        THEN
                            RAISE g_exception;
                        END IF;
                    END IF;
                END LOOP;
            ELSIF l_ds_internal_name = pk_orders_constant.g_ds_duration
            THEN
                l_duration        := to_number(i_value(l_index_current_component) (1));
                l_id_unit_measure := to_number(i_value_mea(l_index_current_component) (1));
            
                FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                LOOP
                    l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
                
                    IF l_ds_internal_name = pk_orders_constant.g_ds_start_date
                    THEN
                        l_start_date := i_value(i) (1);
                    ELSIF l_ds_internal_name = pk_orders_constant.g_ds_end_date
                    THEN
                        l_start_date_tstz := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                           i_prof      => i_prof,
                                                                           i_timestamp => l_start_date,
                                                                           i_timezone  => NULL);
                    
                        l_end_date_tstz := pk_date_utils.add_to_ltstz(i_timestamp => l_start_date_tstz,
                                                                      i_amount    => l_duration,
                                                                      i_unit      => CASE l_id_unit_measure
                                                                                         WHEN 10374 THEN
                                                                                          'MINUTE'
                                                                                         WHEN 1041 THEN
                                                                                          'HOUR'
                                                                                     END);
                    
                        g_error := 'Error calling pk_patient_education_constant.g_et_date_validation function';
                        IF NOT get_date_validation(i_date           => l_end_date_tstz,
                                                   o_flg_validation => l_flg_validation,
                                                   o_err_message    => l_err_msg)
                        THEN
                            RAISE g_exception;
                        END IF;
                    
                        IF l_flg_validation = pk_alert_constant.g_yes
                        THEN
                            l_end_date := pk_date_utils.date_send_tsz(i_lang => i_lang,
                                                                      i_date => l_end_date_tstz,
                                                                      i_prof => i_prof);
                        ELSE
                            l_end_date_tstz := NULL;
                            l_end_date      := NULL;
                            l_err_msg       := pk_message.get_message(i_lang, 'POSITIONING_M043');
                        END IF;
                    END IF;
                END LOOP;
            ELSIF l_ds_internal_name = pk_orders_constant.g_ds_end_date
            THEN
                l_end_date := i_value(l_index_current_component) (1);
                --When changing the end date, the duration is always calculated in minutes
                l_id_unit_measure := 10374;
            
                FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                LOOP
                    l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
                    IF l_ds_internal_name = pk_orders_constant.g_ds_start_date
                    THEN
                        l_start_date := i_value(i) (1);
                    
                        l_start_date_tstz := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                           i_prof      => i_prof,
                                                                           i_timestamp => l_start_date,
                                                                           i_timezone  => NULL);
                    
                        l_end_date_tstz := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                         i_prof      => i_prof,
                                                                         i_timestamp => l_end_date,
                                                                         i_timezone  => NULL);
                    
                        IF pk_date_utils.date_mon_hour_format_tsz(i_lang => i_lang,
                                                                  i_date => l_start_date_tstz,
                                                                  i_prof => i_prof) <>
                           pk_date_utils.date_mon_hour_format_tsz(i_lang => i_lang,
                                                                  i_date => l_end_date_tstz,
                                                                  i_prof => i_prof)
                        THEN
                            IF pk_date_utils.compare_dates_tsz(i_prof  => i_prof,
                                                               i_date1 => l_start_date_tstz,
                                                               i_date2 => l_end_date_tstz) = 'G'
                            THEN
                                l_flg_validation := pk_orders_constant.g_component_error;
                                l_err_msg        := pk_message.get_message(i_lang, 'MONITOR_M010');
                            ELSE
                                g_error := 'Error calling pk_patient_education_constant.g_et_date_validation function';
                                IF NOT get_date_validation(i_date           => l_end_date_tstz,
                                                           o_flg_validation => l_flg_validation,
                                                           o_err_message    => l_err_msg)
                                THEN
                                    RAISE g_exception;
                                END IF;
                            END IF;
                        END IF;
                    
                        IF l_flg_validation = pk_alert_constant.g_yes
                        THEN
                            IF pk_date_utils.get_timestamp_diff(i_lang        => i_lang,
                                                                i_timestamp_1 => l_end_date_tstz,
                                                                i_timestamp_2 => l_start_date_tstz,
                                                                o_days_diff   => l_elapsed_time,
                                                                o_error       => o_error)
                            THEN
                                l_duration := round(abs(l_elapsed_time * 1440));
                            ELSE
                                l_duration := NULL;
                            END IF;
                        END IF;
                    END IF;
                END LOOP;
            END IF;
        
            l_curr_component_int_name := pk_orders_utils.get_ds_internal_name(i_curr_component);
        
            SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => t.id_ds_cmpt_mkt_rel,
                                       id_ds_component    => t.id_ds_component_child,
                                       internal_name      => t.internal_name_child,
                                       VALUE              => CASE
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_start_date THEN
                                                                  l_start_date
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_duration THEN
                                                                  to_char(l_duration)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_end_date THEN
                                                                  l_end_date
                                                                 ELSE
                                                                  NULL
                                                             END,
                                       value_clob         => NULL,
                                       min_value          => NULL,
                                       max_value          => NULL,
                                       desc_value         => CASE
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_start_date THEN
                                                                  l_start_date
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_duration THEN
                                                                  CASE
                                                                      WHEN l_duration IS NOT NULL THEN
                                                                       to_char(l_duration) || ' ' ||
                                                                       pk_unit_measure.get_unit_measure_description(i_lang         => i_lang,
                                                                                                                    i_prof         => i_prof,
                                                                                                                    i_unit_measure => l_id_unit_measure)
                                                                      ELSE
                                                                       NULL
                                                                  END
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_end_date THEN
                                                                  l_end_date
                                                                 ELSE
                                                                  NULL
                                                             END,
                                       desc_clob          => NULL,
                                       id_unit_measure    => CASE
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_duration THEN
                                                                  l_id_unit_measure
                                                                 ELSE
                                                                  NULL
                                                             END,
                                       desc_unit_measure  => NULL,
                                       flg_validation     => CASE
                                                                 WHEN t.id_ds_cmpt_mkt_rel = i_curr_component THEN
                                                                  l_flg_validation
                                                                 ELSE
                                                                  pk_orders_constant.g_component_valid
                                                             END,
                                       err_msg            => CASE
                                                                 WHEN t.id_ds_cmpt_mkt_rel = i_curr_component THEN
                                                                  l_err_msg
                                                                 ELSE
                                                                  NULL
                                                             END,
                                       flg_event_type     => CASE
                                                                 WHEN t.internal_name_child IN
                                                                      (pk_orders_constant.g_ds_duration, pk_orders_constant.g_ds_end_date)
                                                                      AND l_curr_component_int_name = pk_orders_constant.g_ds_start_date
                                                                      AND l_flg_validation = pk_orders_constant.g_component_error THEN
                                                                  pk_orders_constant.g_component_inactive
                                                                 ELSE
                                                                  pk_orders_constant.g_component_active
                                                             END,
                                       flg_multi_status   => NULL,
                                       idx                => i_idx)
              BULK COLLECT
              INTO l_tbl_result
              FROM (SELECT dc.id_ds_cmpt_mkt_rel,
                           dc.id_ds_component_child,
                           dc.internal_name_child,
                           dc.flg_event_type,
                           dc.rn,
                           dc.flg_component_type_child
                      FROM TABLE(pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                         i_prof           => i_prof,
                                                         i_patient        => NULL,
                                                         i_component_name => pk_orders_constant.g_ds_health_education_execution,
                                                         i_action         => NULL)) dc) t
              JOIN ds_component d
                ON d.id_ds_component = t.id_ds_component_child
             WHERE d.internal_name IN (pk_orders_constant.g_ds_start_date,
                                       pk_orders_constant.g_ds_duration,
                                       pk_orders_constant.g_ds_end_date)
             ORDER BY t.rn;
        
            FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
            LOOP
                l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
            
                IF l_ds_internal_name = pk_orders_constant.g_ds_ok_button_control
                THEN
                    l_id_ds_component := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                    process_ok_button_control(i_id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                              i_id_ds_component    => l_id_ds_component,
                                              i_ds_internal_name   => l_ds_internal_name);
                END IF;
            END LOOP;
        ELSIF i_action = pk_dyn_form_constant.get_submit_action
              AND i_curr_component IS NULL --SELECTING ITEMS IN THE VIEWER
        THEN
            FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
            LOOP
                l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
            
                IF l_ds_internal_name IN (pk_orders_constant.g_ds_health_education_goals,
                                          pk_orders_constant.g_ds_health_education_method,
                                          pk_orders_constant.g_ds_health_educ_given_to,
                                          pk_orders_constant.g_ds_health_educ_addit_res,
                                          pk_orders_constant.g_ds_health_educ_level_und)
                THEN
                    l_id_ds_component := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                
                    l_tbl_result.extend();
                    l_tbl_result(l_tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                           id_ds_component    => l_id_ds_component,
                                                                           internal_name      => l_ds_internal_name,
                                                                           VALUE              => i_value(i) (1),
                                                                           value_clob         => NULL,
                                                                           min_value          => NULL,
                                                                           max_value          => NULL,
                                                                           desc_value         => CASE
                                                                                                     WHEN l_ds_internal_name NOT IN (pk_orders_constant.g_ds_end_date) THEN
                                                                                                      i_value_desc(i) (1)
                                                                                                 END,
                                                                           desc_clob          => NULL,
                                                                           id_unit_measure    => NULL,
                                                                           desc_unit_measure  => NULL,
                                                                           flg_validation     => pk_orders_constant.g_component_valid,
                                                                           err_msg            => NULL,
                                                                           flg_event_type     => pk_orders_constant.g_component_active,
                                                                           flg_multi_status   => pk_alert_constant.g_no,
                                                                           idx                => i_idx);
                ELSIF l_ds_internal_name IN (pk_orders_constant.g_ds_clinical_indication_mw)
                THEN
                    IF i_value(i).count > 0
                    THEN
                        FOR j IN i_value(i).first .. i_value(i).last
                        LOOP
                            IF i_value(i).exists(j)
                            THEN
                                l_id_ds_component := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                            
                                l_tbl_result.extend();
                                l_tbl_result(l_tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                                       id_ds_component    => l_id_ds_component,
                                                                                       internal_name      => l_ds_internal_name,
                                                                                       VALUE              => to_char(i_value(i) (j)),
                                                                                       value_clob         => NULL,
                                                                                       min_value          => NULL,
                                                                                       max_value          => NULL,
                                                                                       desc_value         => i_value_desc(i) (j),
                                                                                       desc_clob          => NULL,
                                                                                       id_unit_measure    => NULL,
                                                                                       desc_unit_measure  => NULL,
                                                                                       flg_validation     => pk_orders_constant.g_component_valid,
                                                                                       err_msg            => NULL,
                                                                                       flg_event_type     => pk_orders_constant.g_component_read_only,
                                                                                       flg_multi_status   => pk_alert_constant.g_no,
                                                                                       idx                => i_idx);
                            END IF;
                        END LOOP;
                    END IF;
                ELSIF l_ds_internal_name IN (pk_orders_constant.g_ds_description)
                THEN
                    l_id_ds_component := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                
                    l_tbl_result.extend();
                    l_tbl_result(l_tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                           id_ds_component    => l_id_ds_component,
                                                                           internal_name      => l_ds_internal_name,
                                                                           VALUE              => NULL,
                                                                           value_clob         => i_value_clob(i),
                                                                           min_value          => NULL,
                                                                           max_value          => NULL,
                                                                           desc_value         => NULL,
                                                                           desc_clob          => NULL,
                                                                           id_unit_measure    => NULL,
                                                                           desc_unit_measure  => NULL,
                                                                           flg_validation     => pk_orders_constant.g_component_valid,
                                                                           err_msg            => NULL,
                                                                           flg_event_type     => pk_orders_constant.g_component_active,
                                                                           flg_multi_status   => pk_alert_constant.g_no,
                                                                           idx                => i_idx);
                ELSIF l_ds_internal_name IN (pk_orders_constant.g_ds_start_date)
                THEN
                
                    FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                    LOOP
                        l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
                    
                        IF l_ds_internal_name = pk_orders_constant.g_ds_start_date
                        THEN
                            l_start_date      := i_value(i) (1);
                            l_start_date_tstz := pk_date_utils.get_string_tstz(i_lang, i_prof, i_value(i) (1), NULL);
                        
                            g_error := 'Error calling pk_patient_education_constant.g_et_date_validation function';
                            IF NOT get_date_validation(i_date           => l_start_date_tstz,
                                                       o_flg_validation => l_flg_validation,
                                                       o_err_message    => l_err_msg)
                            THEN
                                RAISE g_exception;
                            END IF;
                        END IF;
                    END LOOP;
                
                    l_id_ds_component  := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                    l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
                
                    l_tbl_result.extend();
                    l_tbl_result(l_tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                           id_ds_component    => l_id_ds_component,
                                                                           internal_name      => l_ds_internal_name,
                                                                           VALUE              => l_start_date,
                                                                           value_clob         => NULL,
                                                                           min_value          => NULL,
                                                                           max_value          => NULL,
                                                                           desc_value         => NULL,
                                                                           desc_clob          => NULL,
                                                                           id_unit_measure    => NULL,
                                                                           desc_unit_measure  => NULL,
                                                                           flg_validation     => l_flg_validation,
                                                                           err_msg            => l_err_msg,
                                                                           flg_event_type     => pk_orders_constant.g_component_active,
                                                                           flg_multi_status   => pk_alert_constant.g_no,
                                                                           idx                => i_idx);
                
                ELSIF l_ds_internal_name IN (pk_orders_constant.g_ds_duration)
                THEN
                    l_duration        := to_number(i_value(i) (1));
                    l_id_unit_measure := to_number(i_value_mea(i) (1));
                
                    FOR j IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                    LOOP
                        l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(j));
                    
                        IF l_ds_internal_name = pk_orders_constant.g_ds_start_date
                        THEN
                            l_start_date := i_value(j) (1);
                        ELSIF l_ds_internal_name = pk_orders_constant.g_ds_end_date
                        THEN
                            l_start_date_tstz := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                               i_prof      => i_prof,
                                                                               i_timestamp => l_start_date,
                                                                               i_timezone  => NULL);
                        
                            l_end_date_tstz := pk_date_utils.add_to_ltstz(i_timestamp => l_start_date_tstz,
                                                                          i_amount    => l_duration,
                                                                          i_unit      => CASE l_id_unit_measure
                                                                                             WHEN 10374 THEN
                                                                                              'MINUTE'
                                                                                             WHEN 1041 THEN
                                                                                              'HOUR'
                                                                                         END);
                        
                            g_error := 'Error calling pk_patient_education_constant.g_et_date_validation function';
                            IF NOT get_date_validation(i_date           => l_end_date_tstz,
                                                       o_flg_validation => l_flg_validation,
                                                       o_err_message    => l_err_msg)
                            THEN
                                RAISE g_exception;
                            END IF;
                        
                            IF l_flg_validation = pk_alert_constant.g_yes
                            THEN
                                l_end_date := pk_date_utils.date_send_tsz(i_lang => i_lang,
                                                                          i_date => l_end_date_tstz,
                                                                          i_prof => i_prof);
                            ELSE
                                l_end_date_tstz := NULL;
                                l_end_date      := NULL;
                                l_err_msg       := pk_message.get_message(i_lang, 'POSITIONING_M043');
                            END IF;
                        END IF;
                    END LOOP;
                
                    l_id_ds_component  := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                    l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
                
                    l_tbl_result.extend();
                    l_tbl_result(l_tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                           id_ds_component    => l_id_ds_component,
                                                                           internal_name      => l_ds_internal_name,
                                                                           VALUE              => l_duration,
                                                                           value_clob         => NULL,
                                                                           min_value          => NULL,
                                                                           max_value          => NULL,
                                                                           desc_value         => i_value_desc(i) (1),
                                                                           desc_clob          => NULL,
                                                                           id_unit_measure    => l_id_unit_measure,
                                                                           desc_unit_measure  => pk_unit_measure.get_unit_measure_description(i_lang,
                                                                                                                                              i_prof,
                                                                                                                                              10374), --Minutes
                                                                           flg_validation     => l_flg_validation,
                                                                           err_msg            => l_err_msg,
                                                                           flg_event_type     => pk_orders_constant.g_component_active,
                                                                           flg_multi_status   => pk_alert_constant.g_no,
                                                                           idx                => i_idx);
                ELSIF l_ds_internal_name IN (pk_orders_constant.g_ds_end_date)
                THEN
                    l_end_date := i_value(i) (1);
                
                    FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                    LOOP
                        l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
                        IF l_ds_internal_name = pk_orders_constant.g_ds_start_date
                        THEN
                            l_start_date := i_value(i) (1);
                        
                            l_start_date_tstz := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                               i_prof      => i_prof,
                                                                               i_timestamp => l_start_date,
                                                                               i_timezone  => NULL);
                        
                            l_end_date_tstz := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                             i_prof      => i_prof,
                                                                             i_timestamp => l_end_date,
                                                                             i_timezone  => NULL);
                        
                            IF pk_date_utils.date_mon_hour_format_tsz(i_lang => i_lang,
                                                                      i_date => l_start_date_tstz,
                                                                      i_prof => i_prof) <>
                               pk_date_utils.date_mon_hour_format_tsz(i_lang => i_lang,
                                                                      i_date => l_end_date_tstz,
                                                                      i_prof => i_prof)
                            THEN
                                IF pk_date_utils.compare_dates_tsz(i_prof  => i_prof,
                                                                   i_date1 => l_start_date_tstz,
                                                                   i_date2 => l_end_date_tstz) = 'G'
                                THEN
                                    l_flg_validation := pk_orders_constant.g_component_error;
                                    l_err_msg        := pk_message.get_message(i_lang, 'MONITOR_M010');
                                ELSE
                                    g_error := 'Error calling pk_patient_education_constant.g_et_date_validation function';
                                    IF NOT get_date_validation(i_date           => l_end_date_tstz,
                                                               o_flg_validation => l_flg_validation,
                                                               o_err_message    => l_err_msg)
                                    THEN
                                        RAISE g_exception;
                                    END IF;
                                END IF;
                            END IF;
                        
                            IF l_flg_validation = pk_alert_constant.g_yes
                            THEN
                                IF pk_date_utils.get_timestamp_diff(i_lang        => i_lang,
                                                                    i_timestamp_1 => l_end_date_tstz,
                                                                    i_timestamp_2 => l_start_date_tstz,
                                                                    o_days_diff   => l_elapsed_time,
                                                                    o_error       => o_error)
                                THEN
                                    l_duration := round(abs(l_elapsed_time * 1440));
                                ELSE
                                    l_duration := NULL;
                                END IF;
                            END IF;
                        END IF;
                    END LOOP;
                
                    l_id_ds_component  := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                    l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
                
                    l_tbl_result.extend();
                    l_tbl_result(l_tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                           id_ds_component    => l_id_ds_component,
                                                                           internal_name      => l_ds_internal_name,
                                                                           VALUE              => l_end_date,
                                                                           value_clob         => NULL,
                                                                           min_value          => NULL,
                                                                           max_value          => NULL,
                                                                           desc_value         => NULL,
                                                                           desc_clob          => NULL,
                                                                           id_unit_measure    => NULL,
                                                                           desc_unit_measure  => NULL,
                                                                           flg_validation     => l_flg_validation,
                                                                           err_msg            => l_err_msg,
                                                                           flg_event_type     => pk_orders_constant.g_component_active,
                                                                           flg_multi_status   => pk_alert_constant.g_no,
                                                                           idx                => i_idx);
                ELSIF l_ds_internal_name IN (pk_orders_constant.g_ds_health_education_goals_ft,
                                             pk_orders_constant.g_ds_health_educ_method_ft,
                                             pk_orders_constant.g_ds_health_educ_given_to_ft,
                                             pk_orders_constant.g_ds_health_educ_addit_res_ft,
                                             pk_orders_constant.g_ds_health_educ_level_und_ft)
                THEN
                    l_id_ds_component := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                
                    l_flg_free_text_active := pk_orders_constant.g_component_inactive;
                
                    FOR j IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                    LOOP
                        l_ds_internal_name_aux := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(j));
                    
                        IF ((l_ds_internal_name = pk_orders_constant.g_ds_health_education_goals_ft AND
                           l_ds_internal_name_aux = pk_orders_constant.g_ds_health_education_goals) OR
                           (l_ds_internal_name = pk_orders_constant.g_ds_health_educ_method_ft AND
                           l_ds_internal_name_aux = pk_orders_constant.g_ds_health_education_method) OR
                           (l_ds_internal_name = pk_orders_constant.g_ds_health_educ_given_to_ft AND
                           l_ds_internal_name_aux = pk_orders_constant.g_ds_health_educ_given_to) OR
                           (l_ds_internal_name = pk_orders_constant.g_ds_health_educ_addit_res_ft AND
                           l_ds_internal_name_aux = pk_orders_constant.g_ds_health_educ_addit_res) OR
                           (l_ds_internal_name = pk_orders_constant.g_ds_health_educ_level_und_ft AND
                           l_ds_internal_name_aux = pk_orders_constant.g_ds_health_educ_level_und))
                           AND i_value(j) (1) = '-1'
                        THEN
                            l_flg_free_text_active := pk_orders_constant.g_component_mandatory;
                        END IF;
                    
                    END LOOP;
                
                    l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
                
                    l_tbl_result.extend();
                    l_tbl_result(l_tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                           id_ds_component    => l_id_ds_component,
                                                                           internal_name      => l_ds_internal_name,
                                                                           VALUE              => i_value(i) (1),
                                                                           value_clob         => i_value_clob(i),
                                                                           min_value          => NULL,
                                                                           max_value          => NULL,
                                                                           desc_value         => i_value_desc(i) (1),
                                                                           desc_clob          => i_value_clob(i),
                                                                           id_unit_measure    => NULL,
                                                                           desc_unit_measure  => NULL,
                                                                           flg_validation     => pk_orders_constant.g_component_valid,
                                                                           err_msg            => NULL,
                                                                           flg_event_type     => l_flg_free_text_active,
                                                                           flg_multi_status   => pk_alert_constant.g_no,
                                                                           idx                => i_idx);
                ELSIF l_ds_internal_name = pk_orders_constant.g_ds_ok_button_control
                THEN
                
                    l_id_ds_component := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                
                    process_ok_button_control(i_id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                              i_id_ds_component    => l_id_ds_component,
                                              i_ds_internal_name   => l_ds_internal_name);
                END IF;
            END LOOP;
        END IF;
    
        RETURN l_tbl_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_REQUEST_FOR_EXECUTION',
                                              o_error);
            RETURN t_tbl_ds_get_value();
    END get_request_for_execution;

    FUNCTION get_order_for_execution
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER, -- edit, new, submit
        i_root_name      IN VARCHAR2, -- root of dynamic screen
        i_curr_component IN NUMBER,
        i_idx            IN NUMBER,
        i_tbl_id_pk      IN table_number, -- id necessary for identifying pk for editing
        i_tbl_mkt_rel    IN table_number, -- components needed for default/edit
        i_value          IN table_table_varchar,
        i_value_mea      IN table_table_varchar,
        i_value_desc     IN table_table_varchar,
        i_value_clob     IN table_clob,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value IS
    
        tbl_result t_tbl_ds_get_value := t_tbl_ds_get_value();
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'get_order_for_execution';
    
        l_ds_internal_name        ds_component.internal_name%TYPE;
        l_ds_internal_name_aux    ds_component.internal_name%TYPE;
        l_id_ds_component         ds_component.id_ds_component%TYPE;
        l_index_current_component NUMBER;
        l_duration                NUMBER;
        l_id_unit_measure         unit_measure.id_unit_measure%TYPE;
        l_start_date              VARCHAR2(200);
        l_start_date_tstz         TIMESTAMP WITH LOCAL TIME ZONE;
        l_end_date                VARCHAR2(200);
        l_end_date_tstz           TIMESTAMP WITH LOCAL TIME ZONE;
        l_elapsed_time            NUMBER;
        l_id_default_option       nurse_tea_opt_inst.id_nurse_tea_opt%TYPE;
        l_default_option_desc     VARCHAR2(4000);
    
        l_flg_free_text_active VARCHAR2(1 CHAR) := pk_orders_constant.g_component_inactive;
    
        l_tbl_description  table_clob := table_clob();
        l_clinical_service table_number := table_number();
    
        FUNCTION get_component_index(i_component IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE) RETURN NUMBER IS
        BEGIN
        
            FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
            LOOP
                IF i_tbl_mkt_rel(i) = i_component
                THEN
                    RETURN i;
                END IF;
            END LOOP;
        
            RETURN NULL;
        
        EXCEPTION
            WHEN OTHERS THEN
                RETURN NULL;
        END get_component_index;
    
        PROCEDURE process_ok_button_control
        (
            i_id_ds_cmpt_mkt_rel IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
            i_id_ds_component    IN ds_component.id_ds_component%TYPE,
            i_ds_internal_name   IN ds_component.internal_name%TYPE
        ) IS
            l_ok_status VARCHAR2(1) := pk_orders_constant.g_component_valid;
        BEGIN
            FOR j IN tbl_result.first .. tbl_result.last
            LOOP
                IF (tbl_result(j).flg_event_type = pk_orders_constant.g_component_mandatory AND tbl_result(j).value IS NULL AND
                    nvl(length(tbl_result(j).value_clob), 0) = 0)
                   OR tbl_result(j).flg_validation = pk_orders_constant.g_component_error
                THEN
                    l_ok_status := pk_orders_constant.g_component_error;
                END IF;
            END LOOP;
        
            tbl_result.extend();
            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_id_ds_cmpt_mkt_rel,
                                                               id_ds_component    => i_id_ds_component,
                                                               internal_name      => i_ds_internal_name,
                                                               VALUE              => NULL,
                                                               value_clob         => NULL,
                                                               min_value          => NULL,
                                                               max_value          => NULL,
                                                               desc_value         => NULL,
                                                               desc_clob          => NULL,
                                                               id_unit_measure    => NULL,
                                                               desc_unit_measure  => NULL,
                                                               flg_validation     => l_ok_status,
                                                               err_msg            => NULL,
                                                               flg_event_type     => pk_orders_constant.g_component_active,
                                                               flg_multi_status   => NULL,
                                                               idx                => i_idx);
        END process_ok_button_control;
    
    BEGIN
        g_sysdate_tstz := nvl(g_sysdate_tstz, trunc(current_timestamp, 'MI'));
    
        IF i_action IS NULL
           OR i_action = -1
        THEN
            --NEW FORM
            SELECT id_clinical_service
              BULK COLLECT
              INTO l_clinical_service
              FROM (SELECT d.id_clinical_service
                      FROM prof_dep_clin_serv p
                      JOIN dep_clin_serv d
                        ON d.id_dep_clin_serv = p.id_dep_clin_serv
                     WHERE p.id_professional = i_prof.id
                       AND p.id_institution = i_prof.institution
                       AND p.flg_status = g_selected
                       AND d.flg_available = pk_alert_constant.g_yes
                    UNION ALL
                    SELECT 0
                      FROM dual);
        
            FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
            LOOP
                l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
            
                IF l_ds_internal_name = pk_orders_constant.g_ds_description
                THEN
                    l_id_ds_component := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                
                    FOR j IN i_tbl_id_pk.first .. i_tbl_id_pk.last
                    LOOP
                    
                        l_tbl_description.extend();
                        l_tbl_description(l_tbl_description.count) := pk_patient_education_utils.get_subject(i_lang     => i_lang,
                                                                                                             i_prof     => i_prof,
                                                                                                             i_id_topic => i_tbl_id_pk(j));
                    END LOOP;
                
                    FOR j IN l_tbl_description.first .. l_tbl_description.last
                    LOOP
                        tbl_result.extend();
                        tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                           id_ds_component    => l_id_ds_component,
                                                                           internal_name      => l_ds_internal_name,
                                                                           VALUE              => NULL,
                                                                           value_clob         => NULL,
                                                                           min_value          => NULL,
                                                                           max_value          => NULL,
                                                                           desc_value         => NULL,
                                                                           desc_clob          => l_tbl_description(j),
                                                                           id_unit_measure    => NULL,
                                                                           desc_unit_measure  => NULL,
                                                                           flg_validation     => pk_orders_constant.g_component_valid,
                                                                           err_msg            => NULL,
                                                                           flg_event_type     => pk_orders_constant.g_component_active,
                                                                           flg_multi_status   => NULL,
                                                                           idx                => i_idx);
                    END LOOP;
                ELSIF l_ds_internal_name = pk_orders_constant.g_ds_start_date
                THEN
                    l_id_ds_component := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                
                    tbl_result.extend();
                    tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                       id_ds_component    => l_id_ds_component,
                                                                       internal_name      => l_ds_internal_name,
                                                                       VALUE              => pk_date_utils.date_send_tsz(i_lang => i_lang,
                                                                                                                         i_date => g_sysdate_tstz,
                                                                                                                         i_prof => i_prof),
                                                                       value_clob         => NULL,
                                                                       min_value          => NULL,
                                                                       max_value          => NULL,
                                                                       desc_value         => pk_date_utils.date_send_tsz(i_lang => i_lang,
                                                                                                                         i_date => g_sysdate_tstz,
                                                                                                                         i_prof => i_prof),
                                                                       desc_clob          => NULL,
                                                                       id_unit_measure    => NULL,
                                                                       desc_unit_measure  => NULL,
                                                                       flg_validation     => pk_orders_constant.g_component_valid,
                                                                       err_msg            => NULL,
                                                                       flg_event_type     => pk_orders_constant.g_component_active,
                                                                       flg_multi_status   => NULL,
                                                                       idx                => i_idx);
                ELSIF l_ds_internal_name = pk_orders_constant.g_ds_clinical_indication_mw
                THEN
                    l_id_ds_component := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                
                    tbl_result.extend();
                    tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                       id_ds_component    => l_id_ds_component,
                                                                       internal_name      => l_ds_internal_name,
                                                                       VALUE              => NULL,
                                                                       value_clob         => NULL,
                                                                       min_value          => NULL,
                                                                       max_value          => NULL,
                                                                       desc_value         => NULL,
                                                                       desc_clob          => NULL,
                                                                       id_unit_measure    => NULL,
                                                                       desc_unit_measure  => NULL,
                                                                       flg_validation     => pk_orders_constant.g_component_valid,
                                                                       err_msg            => NULL,
                                                                       flg_event_type     => pk_orders_constant.g_component_inactive,
                                                                       flg_multi_status   => NULL,
                                                                       idx                => i_idx);
                ELSIF l_ds_internal_name IN (pk_orders_constant.g_ds_health_education_goals,
                                             pk_orders_constant.g_ds_health_education_method,
                                             pk_orders_constant.g_ds_health_educ_given_to,
                                             pk_orders_constant.g_ds_health_educ_addit_res,
                                             pk_orders_constant.g_ds_health_educ_level_und)
                THEN
                    l_id_ds_component := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                
                    BEGIN
                        SELECT id_nurse_tea_opt, label
                          INTO l_id_default_option, l_default_option_desc
                          FROM (SELECT *
                                  FROM (SELECT nto.id_nurse_tea_opt,
                                               pk_translation.get_translation(i_lang, nto.code_nurse_tea_opt) label,
                                               ntoi.flg_default,
                                               row_number() over(PARTITION BY nto.id_nurse_tea_opt ORDER BY ntoi.id_institution DESC) AS rn
                                          FROM nurse_tea_opt nto
                                          JOIN nurse_tea_opt_inst ntoi
                                            ON ntoi.id_nurse_tea_opt = nto.id_nurse_tea_opt
                                         WHERE nto.subject = CASE
                                                   WHEN l_ds_internal_name =
                                                        pk_orders_constant.g_ds_health_education_goals THEN
                                                    'GOALS'
                                                   WHEN l_ds_internal_name =
                                                        pk_orders_constant.g_ds_health_education_method THEN
                                                    'METHOD'
                                                   WHEN l_ds_internal_name = pk_orders_constant.g_ds_health_educ_given_to THEN
                                                    'GIVEN_TO'
                                                   WHEN l_ds_internal_name = pk_orders_constant.g_ds_health_educ_addit_res THEN
                                                    'DELIVERABLES'
                                                   WHEN l_ds_internal_name = pk_orders_constant.g_ds_health_educ_level_und THEN
                                                    'LEVEL_OF_UNDERSTANDING'
                                               END
                                           AND nvl(ntoi.id_institution, 0) IN (0, i_prof.institution)
                                           AND nvl(ntoi.id_clinical_service, 0) IN
                                               (SELECT column_value
                                                  FROM TABLE(l_clinical_service)))
                                 WHERE rn = 1
                                   AND flg_default = pk_alert_constant.g_yes)
                         WHERE rownum = 1;
                    EXCEPTION
                        WHEN OTHERS THEN
                            l_id_default_option   := NULL;
                            l_default_option_desc := NULL;
                    END;
                
                    IF l_id_default_option IS NOT NULL
                    THEN
                        tbl_result.extend();
                        tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                           id_ds_component    => l_id_ds_component,
                                                                           internal_name      => l_ds_internal_name,
                                                                           VALUE              => to_char(l_id_default_option),
                                                                           value_clob         => NULL,
                                                                           min_value          => NULL,
                                                                           max_value          => NULL,
                                                                           desc_value         => l_default_option_desc,
                                                                           desc_clob          => NULL,
                                                                           id_unit_measure    => NULL,
                                                                           desc_unit_measure  => NULL,
                                                                           flg_validation     => pk_orders_constant.g_component_valid,
                                                                           err_msg            => NULL,
                                                                           flg_event_type     => pk_orders_constant.g_component_active,
                                                                           flg_multi_status   => NULL,
                                                                           idx                => i_idx);
                    END IF;
                ELSIF l_ds_internal_name = pk_orders_constant.g_ds_duration
                THEN
                    l_id_ds_component := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                
                    tbl_result.extend();
                    tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                       id_ds_component    => l_id_ds_component,
                                                                       internal_name      => l_ds_internal_name,
                                                                       VALUE              => NULL,
                                                                       value_clob         => NULL,
                                                                       min_value          => NULL,
                                                                       max_value          => NULL,
                                                                       desc_value         => NULL,
                                                                       desc_clob          => NULL,
                                                                       id_unit_measure    => 10374, --Minutes as default unit
                                                                       desc_unit_measure  => pk_unit_measure.get_unit_measure_description(i_lang         => i_lang,
                                                                                                                                          i_prof         => i_prof,
                                                                                                                                          i_unit_measure => 10374),
                                                                       flg_validation     => pk_orders_constant.g_component_valid,
                                                                       err_msg            => NULL,
                                                                       flg_event_type     => pk_orders_constant.g_component_active,
                                                                       flg_multi_status   => NULL,
                                                                       idx                => i_idx);
                ELSIF l_ds_internal_name = pk_orders_constant.g_ds_ok_button_control
                THEN
                    l_id_ds_component := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                
                    tbl_result.extend();
                    tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                       id_ds_component    => l_id_ds_component,
                                                                       internal_name      => l_ds_internal_name,
                                                                       VALUE              => NULL,
                                                                       value_clob         => NULL,
                                                                       min_value          => NULL,
                                                                       max_value          => NULL,
                                                                       desc_value         => NULL,
                                                                       desc_clob          => NULL,
                                                                       id_unit_measure    => NULL,
                                                                       desc_unit_measure  => NULL,
                                                                       flg_validation     => pk_orders_constant.g_component_valid,
                                                                       err_msg            => NULL,
                                                                       flg_event_type     => pk_orders_constant.g_component_active,
                                                                       flg_multi_status   => NULL,
                                                                       idx                => i_idx);
                END IF;
            END LOOP;
        ELSIF i_action = pk_dyn_form_constant.get_submit_action
              AND i_curr_component IS NOT NULL --CHANGING A VALUE ON THE FORM
        THEN
            l_index_current_component := get_component_index(i_curr_component);
            l_ds_internal_name        := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(l_index_current_component));
        
            IF l_ds_internal_name = pk_orders_constant.g_ds_duration
            THEN
                l_duration        := to_number(i_value(l_index_current_component) (1));
                l_id_unit_measure := to_number(i_value_mea(l_index_current_component) (1));
            
                FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                LOOP
                    l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
                
                    IF l_ds_internal_name = pk_orders_constant.g_ds_start_date
                    THEN
                        l_start_date := i_value(i) (1);
                    ELSIF l_ds_internal_name = pk_orders_constant.g_ds_end_date
                    THEN
                    
                        l_start_date_tstz := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                           i_prof      => i_prof,
                                                                           i_timestamp => l_start_date,
                                                                           i_timezone  => NULL);
                    
                        l_end_date_tstz := pk_date_utils.add_to_ltstz(i_timestamp => l_start_date_tstz,
                                                                      i_amount    => l_duration,
                                                                      i_unit      => CASE l_id_unit_measure
                                                                                         WHEN 10374 THEN
                                                                                          'MINUTE'
                                                                                         WHEN 1041 THEN
                                                                                          'HOUR'
                                                                                     END);
                    
                        l_end_date := pk_date_utils.date_send_tsz(i_lang => i_lang,
                                                                  i_date => l_end_date_tstz,
                                                                  i_prof => i_prof);
                    END IF;
                END LOOP;
            ELSIF l_ds_internal_name = pk_orders_constant.g_ds_end_date
            THEN
                l_end_date := i_value(l_index_current_component) (1);
            
                FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                LOOP
                    l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
                    IF l_ds_internal_name = pk_orders_constant.g_ds_start_date
                    THEN
                        l_start_date := i_value(i) (1);
                    
                        l_start_date_tstz := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                           i_prof      => i_prof,
                                                                           i_timestamp => l_start_date,
                                                                           i_timezone  => NULL);
                    
                        l_end_date_tstz := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                         i_prof      => i_prof,
                                                                         i_timestamp => l_end_date,
                                                                         i_timezone  => NULL);
                    
                        IF pk_date_utils.get_timestamp_diff(i_lang        => i_lang,
                                                            i_timestamp_1 => l_end_date_tstz,
                                                            i_timestamp_2 => l_start_date_tstz,
                                                            o_days_diff   => l_elapsed_time,
                                                            o_error       => o_error)
                        THEN
                            l_duration := round(abs(l_elapsed_time * 1440));
                        ELSE
                            l_duration := NULL;
                        END IF;
                    
                        l_id_unit_measure := 10374; --MINUTES
                    END IF;
                END LOOP;
            END IF;
        
            SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => t.id_ds_cmpt_mkt_rel,
                                       id_ds_component    => t.id_ds_component_child,
                                       internal_name      => t.internal_name_child,
                                       VALUE              => CASE
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_duration THEN
                                                                  to_char(l_duration)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_end_date THEN
                                                                  l_end_date
                                                                 ELSE
                                                                  NULL
                                                             END,
                                       value_clob         => NULL,
                                       min_value          => NULL,
                                       max_value          => NULL,
                                       desc_value         => CASE
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_duration THEN
                                                                  CASE
                                                                      WHEN l_duration IS NOT NULL THEN
                                                                       to_char(l_duration) || ' ' ||
                                                                       pk_unit_measure.get_unit_measure_description(i_lang         => i_lang,
                                                                                                                    i_prof         => i_prof,
                                                                                                                    i_unit_measure => l_id_unit_measure)
                                                                      ELSE
                                                                       NULL
                                                                  END
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_end_date THEN
                                                                  l_end_date
                                                                 ELSE
                                                                  NULL
                                                             END,
                                       desc_clob          => NULL,
                                       id_unit_measure    => CASE
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_duration THEN
                                                                  l_id_unit_measure
                                                                 ELSE
                                                                  NULL
                                                             END,
                                       desc_unit_measure  => NULL,
                                       flg_validation     => pk_orders_constant.g_component_valid,
                                       err_msg            => NULL,
                                       flg_event_type     => pk_orders_constant.g_component_active,
                                       flg_multi_status   => NULL,
                                       idx                => i_idx)
              BULK COLLECT
              INTO tbl_result
              FROM (SELECT dc.id_ds_cmpt_mkt_rel,
                           dc.id_ds_component_child,
                           dc.internal_name_child,
                           dc.flg_event_type,
                           dc.rn,
                           dc.flg_component_type_child
                      FROM TABLE(pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                         i_prof           => i_prof,
                                                         i_patient        => NULL,
                                                         i_component_name => i_root_name,
                                                         i_action         => NULL)) dc) t
              JOIN ds_component d
                ON d.id_ds_component = t.id_ds_component_child
             WHERE d.internal_name IN (pk_orders_constant.g_ds_duration, pk_orders_constant.g_ds_end_date)
             ORDER BY t.rn;
        
            FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
            LOOP
                l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
            
                IF l_ds_internal_name = pk_orders_constant.g_ds_ok_button_control
                THEN
                    l_id_ds_component := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                
                    process_ok_button_control(i_id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                              i_id_ds_component    => l_id_ds_component,
                                              i_ds_internal_name   => l_ds_internal_name);
                END IF;
            END LOOP;
        
        ELSIF i_action = pk_dyn_form_constant.get_submit_action
              AND i_curr_component IS NULL --SELECTING ITEMS IN THE VIEWER
        THEN
            FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
            LOOP
                l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
            
                IF l_ds_internal_name IN (pk_orders_constant.g_ds_health_education_goals,
                                          pk_orders_constant.g_ds_health_education_method,
                                          pk_orders_constant.g_ds_health_educ_given_to,
                                          pk_orders_constant.g_ds_health_educ_addit_res,
                                          pk_orders_constant.g_ds_health_educ_level_und)
                THEN
                    l_id_ds_component := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                
                    tbl_result.extend();
                    tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                       id_ds_component    => l_id_ds_component,
                                                                       internal_name      => l_ds_internal_name,
                                                                       VALUE              => i_value(i) (1),
                                                                       value_clob         => NULL,
                                                                       min_value          => NULL,
                                                                       max_value          => NULL,
                                                                       desc_value         => CASE
                                                                                                 WHEN l_ds_internal_name NOT IN (pk_orders_constant.g_ds_end_date) THEN
                                                                                                  i_value_desc(i) (1)
                                                                                             END,
                                                                       desc_clob          => NULL,
                                                                       id_unit_measure    => NULL,
                                                                       desc_unit_measure  => NULL,
                                                                       flg_validation     => pk_orders_constant.g_component_valid,
                                                                       err_msg            => NULL,
                                                                       flg_event_type     => pk_orders_constant.g_component_active,
                                                                       flg_multi_status   => pk_alert_constant.g_no,
                                                                       idx                => i_idx);
                ELSIF l_ds_internal_name IN (pk_orders_constant.g_ds_clinical_indication_mw)
                THEN
                    IF i_value(i).count > 0
                    THEN
                        FOR j IN i_value(i).first .. i_value(i).last
                        LOOP
                            IF i_value(i).exists(j)
                            THEN
                                l_id_ds_component := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                            
                                tbl_result.extend();
                                tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                                   id_ds_component    => l_id_ds_component,
                                                                                   internal_name      => l_ds_internal_name,
                                                                                   VALUE              => to_char(i_value(i) (j)),
                                                                                   value_clob         => NULL,
                                                                                   min_value          => NULL,
                                                                                   max_value          => NULL,
                                                                                   desc_value         => i_value_desc(i) (j),
                                                                                   desc_clob          => NULL,
                                                                                   id_unit_measure    => NULL,
                                                                                   desc_unit_measure  => NULL,
                                                                                   flg_validation     => pk_orders_constant.g_component_valid,
                                                                                   err_msg            => NULL,
                                                                                   flg_event_type     => pk_orders_constant.g_component_read_only,
                                                                                   flg_multi_status   => pk_alert_constant.g_no,
                                                                                   idx                => i_idx);
                            END IF;
                        END LOOP;
                    END IF;
                ELSIF l_ds_internal_name IN (pk_orders_constant.g_ds_description)
                THEN
                    l_id_ds_component := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                
                    tbl_result.extend();
                    tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                       id_ds_component    => l_id_ds_component,
                                                                       internal_name      => l_ds_internal_name,
                                                                       VALUE              => NULL,
                                                                       value_clob         => i_value_clob(i),
                                                                       min_value          => NULL,
                                                                       max_value          => NULL,
                                                                       desc_value         => NULL,
                                                                       desc_clob          => NULL,
                                                                       id_unit_measure    => NULL,
                                                                       desc_unit_measure  => NULL,
                                                                       flg_validation     => pk_orders_constant.g_component_valid,
                                                                       err_msg            => NULL,
                                                                       flg_event_type     => pk_orders_constant.g_component_active,
                                                                       flg_multi_status   => pk_alert_constant.g_no,
                                                                       idx                => i_idx);
                ELSIF l_ds_internal_name IN (pk_orders_constant.g_ds_start_date)
                THEN
                
                    l_start_date := i_value(i) (1);
                
                    l_id_ds_component := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                
                    tbl_result.extend();
                    tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                       id_ds_component    => l_id_ds_component,
                                                                       internal_name      => l_ds_internal_name,
                                                                       VALUE              => l_start_date,
                                                                       value_clob         => NULL,
                                                                       min_value          => NULL,
                                                                       max_value          => NULL,
                                                                       desc_value         => NULL,
                                                                       desc_clob          => NULL,
                                                                       id_unit_measure    => NULL,
                                                                       desc_unit_measure  => NULL,
                                                                       flg_validation     => pk_orders_constant.g_component_valid,
                                                                       err_msg            => NULL,
                                                                       flg_event_type     => pk_orders_constant.g_component_active,
                                                                       flg_multi_status   => pk_alert_constant.g_no,
                                                                       idx                => i_idx);
                
                ELSIF l_ds_internal_name IN (pk_orders_constant.g_ds_duration)
                THEN
                    l_duration        := to_number(i_value(i) (1));
                    l_id_unit_measure := to_number(i_value_mea(i) (1));
                
                    l_id_ds_component := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                
                    tbl_result.extend();
                    tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                       id_ds_component    => l_id_ds_component,
                                                                       internal_name      => l_ds_internal_name,
                                                                       VALUE              => l_duration,
                                                                       value_clob         => NULL,
                                                                       min_value          => NULL,
                                                                       max_value          => NULL,
                                                                       desc_value         => i_value_desc(i) (1),
                                                                       desc_clob          => NULL,
                                                                       id_unit_measure    => l_id_unit_measure,
                                                                       desc_unit_measure  => pk_unit_measure.get_unit_measure_description(i_lang,
                                                                                                                                          i_prof,
                                                                                                                                          10374), --Minutes
                                                                       flg_validation     => pk_orders_constant.g_component_valid,
                                                                       err_msg            => NULL,
                                                                       flg_event_type     => pk_orders_constant.g_component_active,
                                                                       flg_multi_status   => pk_alert_constant.g_no,
                                                                       idx                => i_idx);
                ELSIF l_ds_internal_name IN (pk_orders_constant.g_ds_end_date)
                THEN
                    l_end_date := i_value(i) (1);
                
                    l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
                
                    tbl_result.extend();
                    tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                       id_ds_component    => l_id_ds_component,
                                                                       internal_name      => l_ds_internal_name,
                                                                       VALUE              => l_end_date,
                                                                       value_clob         => NULL,
                                                                       min_value          => NULL,
                                                                       max_value          => NULL,
                                                                       desc_value         => i_value_desc(i) (1),
                                                                       desc_clob          => NULL,
                                                                       id_unit_measure    => NULL,
                                                                       desc_unit_measure  => NULL,
                                                                       flg_validation     => pk_orders_constant.g_component_valid,
                                                                       err_msg            => NULL,
                                                                       flg_event_type     => pk_orders_constant.g_component_active,
                                                                       flg_multi_status   => pk_alert_constant.g_no,
                                                                       idx                => i_idx);
                ELSIF l_ds_internal_name IN (pk_orders_constant.g_ds_health_education_goals_ft,
                                             pk_orders_constant.g_ds_health_educ_method_ft,
                                             pk_orders_constant.g_ds_health_educ_given_to_ft,
                                             pk_orders_constant.g_ds_health_educ_addit_res_ft,
                                             pk_orders_constant.g_ds_health_educ_level_und_ft)
                THEN
                    l_id_ds_component := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                
                    l_flg_free_text_active := pk_orders_constant.g_component_inactive;
                
                    FOR j IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                    LOOP
                        l_ds_internal_name_aux := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(j));
                    
                        IF ((l_ds_internal_name = pk_orders_constant.g_ds_health_education_goals_ft AND
                           l_ds_internal_name_aux = pk_orders_constant.g_ds_health_education_goals) OR
                           (l_ds_internal_name = pk_orders_constant.g_ds_health_educ_method_ft AND
                           l_ds_internal_name_aux = pk_orders_constant.g_ds_health_education_method) OR
                           (l_ds_internal_name = pk_orders_constant.g_ds_health_educ_given_to_ft AND
                           l_ds_internal_name_aux = pk_orders_constant.g_ds_health_educ_given_to) OR
                           (l_ds_internal_name = pk_orders_constant.g_ds_health_educ_addit_res_ft AND
                           l_ds_internal_name_aux = pk_orders_constant.g_ds_health_educ_addit_res) OR
                           (l_ds_internal_name = pk_orders_constant.g_ds_health_educ_level_und_ft AND
                           l_ds_internal_name_aux = pk_orders_constant.g_ds_health_educ_level_und))
                           AND i_value(j) (1) = '-1'
                        THEN
                            l_flg_free_text_active := pk_orders_constant.g_component_mandatory;
                        END IF;
                    
                    END LOOP;
                
                    l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
                
                    tbl_result.extend();
                    tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                       id_ds_component    => l_id_ds_component,
                                                                       internal_name      => l_ds_internal_name,
                                                                       VALUE              => i_value(i) (1),
                                                                       value_clob         => i_value_clob(i),
                                                                       min_value          => NULL,
                                                                       max_value          => NULL,
                                                                       desc_value         => i_value_desc(i) (1),
                                                                       desc_clob          => i_value_clob(i),
                                                                       id_unit_measure    => NULL,
                                                                       desc_unit_measure  => NULL,
                                                                       flg_validation     => pk_orders_constant.g_component_valid,
                                                                       err_msg            => NULL,
                                                                       flg_event_type     => l_flg_free_text_active,
                                                                       flg_multi_status   => pk_alert_constant.g_no,
                                                                       idx                => i_idx);
                ELSIF l_ds_internal_name = pk_orders_constant.g_ds_ok_button_control
                THEN
                
                    l_id_ds_component := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                
                    process_ok_button_control(i_id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                              i_id_ds_component    => l_id_ds_component,
                                              i_ds_internal_name   => l_ds_internal_name);
                END IF;
            END LOOP;
        END IF;
    
        RETURN tbl_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_db_object_name,
                                              o_error);
            RETURN NULL;
    END get_order_for_execution;

    FUNCTION create_executions
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_exec_tab        IN t_tbl_order_recurr_plan,
        o_exec_to_process OUT t_tbl_order_recurr_plan_sts,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -- returns outdated plans
        CURSOR c_ntr_not(x_exec_tab IN t_tbl_order_recurr_plan) IS
            SELECT DISTINCT t.id_order_recurrence_plan
              FROM nurse_tea_req ntr
             RIGHT JOIN TABLE(CAST(x_exec_tab AS t_tbl_order_recurr_plan)) t
                ON (t.id_order_recurrence_plan = ntr.id_order_recurr_plan)
             WHERE ntr.flg_status NOT IN -- plans that are associated to NOT active and NOT pending nurse_tea_req (are outdated)
                   (pk_patient_education_constant.g_nurse_tea_req_pend,
                    pk_patient_education_constant.g_nurse_tea_req_act)
                OR ntr.id_nurse_tea_req IS NULL -- plans that are NOT associated to any nurse_tea_req (they were changed and are outdated)
            ;
    
        -- returns plans that has active or pending nurse_tea_req
        CURSOR c_ntr(x_exec_tab IN t_tbl_order_recurr_plan) IS
            SELECT ntr.id_nurse_tea_req, t.id_order_recurrence_plan, t.exec_number, t.exec_timestamp
              FROM nurse_tea_req ntr
              JOIN TABLE(CAST(x_exec_tab AS t_tbl_order_recurr_plan)) t
                ON (t.id_order_recurrence_plan = ntr.id_order_recurr_plan)
              JOIN episode e
                ON e.id_episode = ntr.id_episode
              JOIN visit v
                ON e.id_visit = v.id_visit
             WHERE ntr.flg_status IN (pk_patient_education_constant.g_nurse_tea_req_pend,
                                      pk_patient_education_constant.g_nurse_tea_req_act)
               AND v.flg_status = pk_visit.g_active;
    
        CURSOR c_state_visit(x_exec_tab IN t_tbl_order_recurr_plan) IS
            SELECT DISTINCT v.flg_status
              FROM nurse_tea_req ntr
              JOIN TABLE(CAST(x_exec_tab AS t_tbl_order_recurr_plan)) t
                ON (t.id_order_recurrence_plan = ntr.id_order_recurr_plan)
              JOIN episode e
                ON e.id_episode = ntr.id_episode
              JOIN visit v
                ON e.id_visit = v.id_visit
             WHERE ntr.flg_status IN (pk_patient_education_constant.g_nurse_tea_req_pend,
                                      pk_patient_education_constant.g_nurse_tea_req_act)
               AND v.flg_status = pk_visit.g_active;
    
        TYPE t_ntr IS TABLE OF c_ntr%ROWTYPE;
        l_ntr_tab t_ntr;
    
        l_plans_oudated   table_number := table_number();
        l_plans_processed table_number := table_number();
    
        l_status_visit visit.flg_status%TYPE;
    BEGIN
        g_error := 'Init create_executions / i_exec_tab.COUNT=' || i_exec_tab.count;
        pk_alertlog.log_init(g_error);
        g_sysdate := current_timestamp;
    
        OPEN c_state_visit(i_exec_tab);
        FETCH c_state_visit
            INTO l_status_visit;
        CLOSE c_state_visit;
    
        IF l_status_visit != pk_visit.g_active
        THEN
            RETURN TRUE;
        END IF;
    
        -------
        -- Getting outdated plans
        g_error := 'OPEN c_ntr_not';
        OPEN c_ntr_not(i_exec_tab);
        FETCH c_ntr_not BULK COLLECT
            INTO l_plans_oudated;
        CLOSE c_ntr_not;
    
        -------
        -- Getting all nurse_tea_reqs related to this order recurr plan
        g_error := 'OPEN c_ntr';
        OPEN c_ntr(i_exec_tab);
        FETCH c_ntr BULK COLLECT
            INTO l_ntr_tab;
        CLOSE c_ntr;
    
        <<req>>
        FOR req_idx IN 1 .. l_ntr_tab.count
        LOOP
        
            -- for each req and each execution
            -- create executions
            g_error  := 'Call create_execution / i_id_nurse_tea_req=' || l_ntr_tab(req_idx).id_nurse_tea_req ||
                        ' i_flg_status=' || pk_patient_education_constant.g_nurse_tea_det_pend || ' i_num_order=' || l_ntr_tab(req_idx).exec_number;
            g_retval := create_execution(i_lang                  => i_lang,
                                         i_prof                  => i_prof,
                                         i_id_nurse_tea_req      => l_ntr_tab(req_idx).id_nurse_tea_req,
                                         i_dt_start              => l_ntr_tab(req_idx).exec_timestamp,
                                         i_dt_nurse_tea_det_tstz => g_sysdate,
                                         i_flg_status            => pk_patient_education_constant.g_nurse_tea_det_pend,
                                         i_num_order             => l_ntr_tab(req_idx).exec_number,
                                         o_error                 => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            -- plans processed
            g_error := 'l_exec_to_process 2';
            l_plans_processed.extend;
            l_plans_processed(l_plans_processed.count) := l_ntr_tab(req_idx).id_order_recurrence_plan;
        
        END LOOP req;
    
        -- note:
        -- getting all plans processed and all plans outdated.
        -- if one plan is in both arrays, consider only plans processed and discard the outdated
    
        g_error := 'l_plans_oudated.COUNT=' || l_plans_oudated.count || ' l_plans_processed.COUNT=' ||
                   l_plans_processed.count;
        pk_alertlog.log_debug(g_error);
        SELECT t_rec_order_recurr_plan_sts(column_value, flg_status)
          BULK COLLECT
          INTO o_exec_to_process
          FROM (
                -- plans processed
                SELECT column_value, pk_alert_constant.get_yes flg_status
                  FROM TABLE(CAST(l_plans_processed AS table_number))
                UNION
                -- plans outdated minus (plans processed intersect plans outdated)
                SELECT t.*, pk_alert_constant.get_no flg_status
                  FROM (SELECT *
                           FROM TABLE(CAST(l_plans_oudated AS table_number))
                         MINUS (SELECT *
                                 FROM TABLE(CAST(l_plans_oudated AS table_number))
                               INTERSECT
                               SELECT *
                                 FROM TABLE(CAST(l_plans_processed AS table_number)))) t);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_EXECUTIONS',
                                              o_error);
        
            RETURN FALSE;
    END create_executions;

    FUNCTION create_execution
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_nurse_tea_req      IN nurse_tea_det.id_nurse_tea_req%TYPE,
        i_dt_start              IN nurse_tea_det.dt_start%TYPE,
        i_dt_nurse_tea_det_tstz IN nurse_tea_det.dt_nurse_tea_det_tstz%TYPE,
        i_flg_status            IN nurse_tea_det.flg_status%TYPE,
        i_num_order             IN nurse_tea_det.num_order%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rows table_varchar := table_varchar();
    BEGIN
        g_error := 'Init create_execution / i_id_nurse_tea_req=' || i_id_nurse_tea_req || ' i_flg_status=' ||
                   i_flg_status || ' i_num_order=' || i_num_order;
        pk_alertlog.log_init(g_error);
        g_sysdate := current_timestamp;
    
        ts_nurse_tea_det.ins(id_nurse_tea_det_in      => ts_nurse_tea_det.next_key,
                             id_nurse_tea_req_in      => i_id_nurse_tea_req,
                             dt_start_in              => i_dt_start,
                             dt_nurse_tea_det_tstz_in => i_dt_nurse_tea_det_tstz,
                             flg_status_in            => pk_patient_education_constant.g_nurse_tea_det_pend,
                             num_order_in             => i_num_order,
                             dt_planned_in            => i_dt_start,
                             rows_out                 => l_rows);
    
        g_error := 'Process insert on NURSE_TEA_DET';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'NURSE_TEA_DET',
                                      i_rowids     => l_rows,
                                      o_error      => o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_EXECUTION',
                                              o_error);
        
            RETURN FALSE;
    END create_execution;

    FUNCTION create_req_diagnosis
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_category      IN category.flg_type%TYPE,
        i_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE,
        i_diagnoses     IN table_number,
        o_rows          OUT table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_diagnosis_id     diagnosis.id_diagnosis%TYPE;
        l_composition_id   icnp_composition.id_composition%TYPE;
        l_nan_diagnosis_id nan_diagnosis.id_nan_diagnosis%TYPE;
        l_rows             table_varchar;
    
        l_id_nurse_tea_req_diag_in NUMBER;
        l_id_nurse_tea_req_hist    nurse_tea_req_hist.id_nurse_tea_req_hist%TYPE;
        l_ncp_class                sys_config.value%TYPE;
    BEGIN
        pk_alertlog.log_debug('create_req_diagnosis()');
    
        SELECT MAX(ntrh.id_nurse_tea_req_hist)
          INTO l_id_nurse_tea_req_hist
          FROM nurse_tea_req_hist ntrh
         WHERE ntrh.id_nurse_tea_req = i_nurse_tea_req;
    
        -- Loop through all the given diagnoses and insert and associate them with the patient
        -- education request
        g_error := 'Associates diagnoses to patient education request';
        pk_alertlog.log_debug(g_error);
        IF i_diagnoses IS NOT NULL
           AND i_diagnoses.count > 0
        THEN
            -- Checks the current Nursing Care Plan approach in use (ICNP/NNN)
            l_ncp_class := coalesce(pk_sysconfig.get_config(pk_nnn_constant.g_config_classification, i_prof),
                                    pk_nnn_constant.g_classification_icnp);
        
            FOR i IN 1 .. i_diagnoses.count
            LOOP
                g_error := 'Processing index ' || i || ' of i_diagnoses: ' || i_diagnoses(i);
                pk_alertlog.log_debug(g_error);
            
                -- ICD Medical Diagnosis
                l_diagnosis_id := CASE i_category
                                      WHEN pk_alert_constant.g_cat_type_nurse THEN
                                       NULL
                                      ELSE
                                       i_diagnoses(i)
                                  END;
            
                l_composition_id   := NULL;
                l_nan_diagnosis_id := NULL;
                IF l_ncp_class = pk_nnn_constant.g_classification_icnp
                THEN
                    -- ICNP Nursing Diagnosis                  
                    l_composition_id := CASE i_category
                                            WHEN pk_alert_constant.g_cat_type_nurse THEN
                                             i_diagnoses(i)
                                            ELSE
                                             NULL
                                        END;
                ELSIF l_ncp_class = pk_nnn_constant.g_classification_nanda_nic_noc
                THEN
                    -- NANDA Nursing Diagnosis                                    
                    l_nan_diagnosis_id := CASE i_category
                                              WHEN pk_alert_constant.g_cat_type_nurse THEN
                                               i_diagnoses(i)
                                              ELSE
                                               NULL
                                          END;
                END IF;
            
                l_id_nurse_tea_req_diag_in := ts_nurse_tea_req_diag.next_key;
            
                ts_nurse_tea_req_diag_hist.ins(id_nurse_tea_req_diag_hist_in => ts_nurse_tea_req_diag_hist.next_key,
                                               id_nurse_tea_req_diag_in      => l_id_nurse_tea_req_diag_in,
                                               id_nurse_tea_req_in           => i_nurse_tea_req,
                                               id_diagnosis_in               => l_diagnosis_id,
                                               id_composition_in             => l_composition_id,
                                               id_nan_diagnosis_in           => l_nan_diagnosis_id,
                                               dt_nurse_tea_req_diag_tstz_in => current_timestamp,
                                               id_nurse_tea_req_hist_in      => l_id_nurse_tea_req_hist,
                                               rows_out                      => l_rows);
            
                ts_nurse_tea_req_diag.ins(id_nurse_tea_req_diag_in => l_id_nurse_tea_req_diag_in,
                                          id_nurse_tea_req_in      => i_nurse_tea_req,
                                          id_diagnosis_in          => l_diagnosis_id,
                                          id_composition_in        => l_composition_id,
                                          id_nan_diagnosis_in      => l_nan_diagnosis_id,
                                          rows_out                 => l_rows);
            
            END LOOP;
        
        END IF;
    
        IF i_diagnoses.count = 0
        THEN
            ts_nurse_tea_req_diag_hist.ins(id_nurse_tea_req_diag_hist_in => ts_nurse_tea_req_diag_hist.next_key,
                                           id_nurse_tea_req_diag_in      => NULL,
                                           id_nurse_tea_req_in           => i_nurse_tea_req,
                                           id_diagnosis_in               => NULL,
                                           id_composition_in             => NULL,
                                           id_nan_diagnosis_in           => NULL,
                                           dt_nurse_tea_req_diag_tstz_in => current_timestamp,
                                           id_nurse_tea_req_hist_in      => l_id_nurse_tea_req_hist,
                                           rows_out                      => l_rows);
        END IF;
    
        -- Inserts completed successfully
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            pk_alertlog.log_error(SQLCODE || ' ' || SQLERRM || ' ' || g_error);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'create_req_diagnosis',
                                              o_error);
        
            RETURN FALSE;
    END create_req_diagnosis;

    FUNCTION create_req
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN nurse_tea_req.id_episode%TYPE,
        i_topics                IN table_number,
        i_compositions          IN table_table_number,
        i_diagnoses             IN table_clob DEFAULT NULL,
        i_to_be_performed       IN table_varchar,
        i_start_date            IN table_varchar,
        i_notes                 IN table_varchar,
        i_description           IN table_clob,
        i_order_recurr          IN table_number,
        i_draft                 IN VARCHAR2,
        i_id_nurse_tea_req_sugg IN table_number,
        i_desc_topic_aux        IN table_varchar,
        i_not_order_reason      IN table_number,
        i_flg_origin_req        IN VARCHAR2 DEFAULT 'D',
        o_id_nurse_tea_req      OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_category                category.flg_type%TYPE;
        l_id_nurse_tea_req        table_number := table_number();
        l_start_date              TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_rows                    table_varchar := table_varchar();
        l_rows_ntr_ins            table_varchar := table_varchar();
        l_rows_ntr_upd            table_varchar := table_varchar();
        l_rows_ntrd               table_varchar := table_varchar();
        l_final_order_recurr_plan NUMBER;
        l_order_recurr_option     order_recurr_plan.id_order_recurr_option%TYPE;
        l_lst_diagnosis           pk_edis_types.table_in_epis_diagnosis;
        l_rec_diagnosis           pk_edis_types.rec_in_epis_diagnosis;
        l_not_order_reason        not_order_reason.id_not_order_reason%TYPE;
        l_lst_not_order_reason    table_number;
    
        l_dt_nurse_tea_req_h nurse_tea_req_hist.dt_nurse_tea_req_hist_tstz%TYPE;
        l_id_nurse_tea_req_h nurse_tea_req_hist.id_nurse_tea_req_hist%TYPE;
    BEGIN
        g_sysdate_tstz         := current_timestamp;
        l_category             := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
        l_lst_not_order_reason := coalesce(i_not_order_reason, table_number());
    
        -- getting diagnoses for phisican
        IF i_diagnoses IS NOT NULL
           AND i_diagnoses.count > 0
        THEN
            l_lst_diagnosis := pk_diagnosis.get_diag_rec(i_lang => i_lang, i_prof => i_prof, i_params => i_diagnoses);
        END IF;
    
        IF i_topics IS NOT NULL
           AND i_topics.count > 0
        THEN
        
            g_error := 'Loop over topics';
            <<topics>>
            FOR i IN 1 .. i_topics.count
            LOOP
                IF i_flg_origin_req != pk_alert_constant.g_task_origin_order_set
                THEN
                    l_start_date := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                  i_prof      => i_prof,
                                                                  i_timestamp => i_start_date(i),
                                                                  i_timezone  => NULL);
                END IF;
                -- getting not order reason id                                              
                IF l_lst_not_order_reason.count > 0
                THEN
                    IF l_lst_not_order_reason(i) IS NOT NULL
                    THEN
                        g_error := 'Call set_not_order_reason: ';
                        g_error := g_error || ' i_not_order_reason_ea = ' ||
                                   coalesce(to_char(l_lst_not_order_reason(i)), '<null>');
                        pk_alertlog.log_debug(g_error);
                        IF NOT pk_not_order_reason_db.set_not_order_reason(i_lang                => i_lang,
                                                                           i_prof                => i_prof,
                                                                           i_not_order_reason_ea => l_lst_not_order_reason(i),
                                                                           o_id_not_order_reason => l_not_order_reason,
                                                                           o_error               => o_error)
                        THEN
                            RAISE g_exception;
                        END IF;
                    END IF;
                END IF;
            
                IF i_id_nurse_tea_req_sugg IS NULL
                   OR i_id_nurse_tea_req_sugg(i) IS NULL
                THEN
                    l_id_nurse_tea_req.extend;
                    l_id_nurse_tea_req(i) := ts_nurse_tea_req.next_key;
                
                    IF i_draft = pk_alert_constant.g_yes
                       AND i_order_recurr(i) IS NOT NULL
                    THEN
                        g_error := 'set_order_recurr_plan';
                        pk_alertlog.log_debug(g_error);
                        IF NOT pk_order_recurrence_api_db.set_order_recurr_plan(i_lang                    => i_lang,
                                                                                i_prof                    => i_prof,
                                                                                i_order_recurr_plan       => i_order_recurr(i),
                                                                                o_order_recurr_option     => l_order_recurr_option,
                                                                                o_final_order_recurr_plan => l_final_order_recurr_plan,
                                                                                o_error                   => o_error)
                        
                        THEN
                            RAISE g_exception;
                        END IF;
                    ELSE
                        l_final_order_recurr_plan := i_order_recurr(i);
                    END IF;
                
                    g_error := 'Insert request / l_id_order_plan=' || i_order_recurr(i);
                    ts_nurse_tea_req.ins(id_nurse_tea_req_in      => l_id_nurse_tea_req(i),
                                         id_prof_req_in           => i_prof.id,
                                         id_episode_in            => i_id_episode,
                                         flg_status_in            => CASE
                                                                         WHEN i_flg_origin_req =
                                                                              pk_alert_constant.g_task_origin_order_set THEN
                                                                          pk_patient_education_core.g_status_predefined
                                                                         WHEN l_not_order_reason IS NOT NULL THEN
                                                                          pk_patient_education_constant.g_nurse_tea_req_not_ord_reas
                                                                         WHEN i_draft = pk_alert_constant.g_no THEN
                                                                          pk_patient_education_constant.g_nurse_tea_req_pend
                                                                         WHEN i_draft = pk_alert_constant.g_yes THEN
                                                                          pk_patient_education_constant.g_nurse_tea_req_draft
                                                                     END,
                                         notes_req_in             => i_notes(i),
                                         dt_nurse_tea_req_tstz_in => g_sysdate_tstz,
                                         dt_begin_tstz_in         => l_start_date,
                                         id_visit_in              => CASE
                                                                         WHEN i_id_episode IS NULL THEN
                                                                          NULL
                                                                         ELSE
                                                                          pk_episode.get_id_visit(i_episode => i_id_episode)
                                                                     END,
                                         id_patient_in            => CASE
                                                                         WHEN i_id_episode IS NULL THEN
                                                                          NULL
                                                                         ELSE
                                                                          pk_episode.get_id_patient(i_episode => i_id_episode)
                                                                     END,
                                         id_nurse_tea_topic_in    => i_topics(i),
                                         id_order_recurr_plan_in  => CASE
                                                                         WHEN i_draft = pk_alert_constant.g_no THEN
                                                                          i_order_recurr(i)
                                                                         WHEN i_draft = pk_alert_constant.g_yes THEN
                                                                          l_final_order_recurr_plan
                                                                     END,
                                         description_in           => i_description(i),
                                         flg_time_in              => i_to_be_performed(i),
                                         desc_topic_aux_in        => i_desc_topic_aux(i),
                                         id_not_order_reason_in   => l_not_order_reason,
                                         rows_out                 => l_rows);
                
                    insert_ntr_hist(i_lang             => i_lang,
                                    i_prof             => i_prof,
                                    i_id_nurse_tea_req => l_id_nurse_tea_req(i),
                                    o_error            => o_error);
                
                    l_rows_ntr_ins := l_rows_ntr_ins MULTISET UNION l_rows;
                ELSE
                    l_id_nurse_tea_req.extend;
                    l_id_nurse_tea_req(i) := i_id_nurse_tea_req_sugg(i);
                
                    g_error := 'Update request / l_id_order_plan=' || i_order_recurr(i);
                    ts_nurse_tea_req.upd(id_nurse_tea_req_in      => l_id_nurse_tea_req(i),
                                         id_prof_req_in           => i_prof.id,
                                         id_episode_in            => i_id_episode,
                                         flg_status_in            => CASE
                                                                         WHEN l_not_order_reason IS NOT NULL THEN
                                                                          pk_patient_education_constant.g_nurse_tea_req_not_ord_reas
                                                                         WHEN i_draft = pk_alert_constant.g_no THEN
                                                                          pk_patient_education_constant.g_nurse_tea_req_pend
                                                                         WHEN i_draft = pk_alert_constant.g_yes THEN
                                                                          pk_patient_education_constant.g_nurse_tea_req_draft
                                                                     END,
                                         notes_req_in             => i_notes(i),
                                         dt_nurse_tea_req_tstz_in => g_sysdate_tstz,
                                         dt_begin_tstz_in         => l_start_date,
                                         id_visit_in              => pk_episode.get_id_visit(i_episode => i_id_episode),
                                         id_patient_in            => pk_episode.get_id_patient(i_episode => i_id_episode),
                                         id_nurse_tea_topic_in    => i_topics(i),
                                         id_order_recurr_plan_in  => i_order_recurr(i),
                                         description_in           => i_description(i),
                                         flg_time_in              => i_to_be_performed(i),
                                         desc_topic_aux_in        => i_desc_topic_aux(i),
                                         id_not_order_reason_in   => l_not_order_reason,
                                         rows_out                 => l_rows);
                
                    insert_ntr_hist(i_lang             => i_lang,
                                    i_prof             => i_prof,
                                    i_id_nurse_tea_req => i_id_nurse_tea_req_sugg(i),
                                    o_error            => o_error);
                
                    l_rows_ntr_upd := l_rows_ntr_upd MULTISET UNION l_rows;
                
                END IF;
            
                IF i_flg_origin_req != pk_alert_constant.g_task_origin_order_set
                THEN
                    g_error := 'INSERT LOG ON TI_LOG';
                    IF NOT t_ti_log.ins_log(i_lang,
                                            i_prof,
                                            i_id_episode,
                                            CASE WHEN i_draft = pk_alert_constant.g_no THEN
                                            pk_patient_education_constant.g_nurse_tea_req_pend WHEN
                                            i_draft = pk_alert_constant.g_yes THEN
                                            pk_patient_education_constant.g_nurse_tea_req_draft END,
                                            l_id_nurse_tea_req(i),
                                            'NT',
                                            o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                END IF;
            
                pk_alertlog.log_debug('Associate diagnoses to request');
                IF l_category = pk_alert_constant.g_cat_type_nurse
                THEN
                    IF i_compositions IS NOT NULL
                       AND i_compositions.count > 0
                    THEN
                        IF NOT create_req_diagnosis(i_lang          => i_lang,
                                                    i_prof          => i_prof,
                                                    i_category      => l_category,
                                                    i_nurse_tea_req => l_id_nurse_tea_req(i),
                                                    i_diagnoses     => i_compositions(i),
                                                    o_rows          => l_rows,
                                                    o_error         => o_error)
                        THEN
                            RAISE g_exception;
                        END IF;
                    
                        l_rows_ntrd := l_rows_ntrd MULTISET UNION l_rows;
                    
                        g_error := 'Process insert on NURSE_TEA_REQ_DIAG';
                        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'NURSE_TEA_REQ_DIAG',
                                                      i_rowids     => l_rows_ntrd,
                                                      o_error      => o_error);
                    END IF;
                ELSE
                    -- physican     
                    IF i_diagnoses IS NOT NULL
                       AND i_diagnoses.count > 0
                    THEN
                        IF l_lst_diagnosis.count > 0
                        THEN
                            l_rec_diagnosis := l_lst_diagnosis(i);
                        
                            IF l_rec_diagnosis.tbl_diagnosis IS NOT NULL
                            THEN
                                g_error := 'SET DIAGNOSIS';
                                IF NOT pk_diagnosis.set_mcdt_req_diag_no_commit(i_lang              => i_lang,
                                                                                i_prof              => i_prof,
                                                                                i_epis              => i_id_episode,
                                                                                i_diag              => l_rec_diagnosis,
                                                                                i_exam_req          => NULL,
                                                                                i_analysis_req      => NULL,
                                                                                i_interv_presc      => NULL,
                                                                                i_exam_req_det      => NULL,
                                                                                i_analysis_req_det  => NULL,
                                                                                i_interv_presc_det  => NULL,
                                                                                i_epis_complication => NULL,
                                                                                i_epis_comp_hist    => NULL,
                                                                                i_nurse_tea_req     => l_id_nurse_tea_req(i),
                                                                                o_error             => o_error)
                                THEN
                                    g_error := to_char('Call to PK_DIAGNOSIS.SET_MCDT_REQ_DIAG_NO_COMMIT');
                                    RAISE g_exception;
                                END IF;
                            
                                FOR j IN l_lst_diagnosis(i).tbl_diagnosis.first .. l_lst_diagnosis(i).tbl_diagnosis.last
                                LOOP
                                
                                    SELECT MAX(h.id_nurse_tea_req_hist)
                                      INTO l_id_nurse_tea_req_h
                                      FROM nurse_tea_req_hist h
                                     WHERE h.id_nurse_tea_req = l_id_nurse_tea_req(i);
                                
                                    SELECT h.dt_nurse_tea_req_hist_tstz
                                      INTO l_dt_nurse_tea_req_h
                                      FROM nurse_tea_req_hist h
                                     WHERE h.id_nurse_tea_req_hist = l_id_nurse_tea_req_h;
                                
                                    ts_nurse_tea_req_diag_hist.ins(id_nurse_tea_req_diag_hist_in => ts_nurse_tea_req_diag_hist.next_key,
                                                                   id_nurse_tea_req_diag_in      => NULL,
                                                                   id_nurse_tea_req_in           => l_id_nurse_tea_req(i),
                                                                   id_diagnosis_in               => l_lst_diagnosis(i).tbl_diagnosis(j).id_diagnosis,
                                                                   id_composition_in             => NULL,
                                                                   id_nan_diagnosis_in           => NULL,
                                                                   dt_nurse_tea_req_diag_tstz_in => l_dt_nurse_tea_req_h,
                                                                   id_nurse_tea_req_hist_in      => l_id_nurse_tea_req_h,
                                                                   rows_out                      => l_rows);
                                
                                    IF i_flg_origin_req != pk_alert_constant.g_task_origin_order_set
                                    THEN
                                        g_error := 'PROCESS INSERT ON NURSE_TEA_REQ_DIAG';
                                        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                                      i_prof       => i_prof,
                                                                      i_table_name => 'NURSE_TEA_REQ_DIAG_HIST',
                                                                      i_rowids     => l_rows,
                                                                      o_error      => o_error);
                                    END IF;
                                
                                END LOOP;
                            ELSE
                            
                                SELECT MAX(h.id_nurse_tea_req_hist)
                                  INTO l_id_nurse_tea_req_h
                                  FROM nurse_tea_req_hist h
                                 WHERE h.id_nurse_tea_req = l_id_nurse_tea_req(i);
                            
                                SELECT h.dt_nurse_tea_req_hist_tstz
                                  INTO l_dt_nurse_tea_req_h
                                  FROM nurse_tea_req_hist h
                                 WHERE h.id_nurse_tea_req_hist = l_id_nurse_tea_req_h;
                            
                                ts_nurse_tea_req_diag_hist.ins(id_nurse_tea_req_diag_hist_in => ts_nurse_tea_req_diag_hist.next_key,
                                                               id_nurse_tea_req_diag_in      => NULL,
                                                               id_nurse_tea_req_in           => l_id_nurse_tea_req(i),
                                                               id_diagnosis_in               => NULL,
                                                               id_composition_in             => NULL,
                                                               id_nan_diagnosis_in           => NULL,
                                                               dt_nurse_tea_req_diag_tstz_in => l_dt_nurse_tea_req_h,
                                                               id_nurse_tea_req_hist_in      => l_id_nurse_tea_req_h,
                                                               rows_out                      => l_rows);
                            
                                IF i_flg_origin_req != pk_alert_constant.g_task_origin_order_set
                                THEN
                                    g_error := 'PROCESS INSERT ON NURSE_TEA_REQ_DIAG';
                                    t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                                  i_prof       => i_prof,
                                                                  i_table_name => 'NURSE_TEA_REQ_DIAG_HIST',
                                                                  i_rowids     => l_rows,
                                                                  o_error      => o_error);
                                END IF;
                            END IF;
                        END IF;
                    END IF;
                END IF;
            
            END LOOP topics;
        
        END IF;
    
        IF i_flg_origin_req != pk_alert_constant.g_task_origin_order_set
        THEN
            g_error := 'Process insert on NURSE_TEA_REQ';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'NURSE_TEA_REQ',
                                          i_rowids     => l_rows_ntr_ins,
                                          o_error      => o_error);
        
            g_error := 'Process update on NURSE_TEA_REQ';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'NURSE_TEA_REQ',
                                          i_rowids     => l_rows_ntr_upd,
                                          o_error      => o_error);
        END IF;
    
        o_id_nurse_tea_req := l_id_nurse_tea_req;
    
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
                                              'CREATE_REQ',
                                              o_error);
        
            RETURN FALSE;
    END create_req;

    FUNCTION set_ntr_copy_task
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_task_request  IN nurse_tea_req.id_nurse_tea_req%TYPE,
        o_nurse_tea_req OUT nurse_tea_req.id_nurse_tea_req%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_start_date_tstz         nurse_tea_req.dt_begin_tstz%TYPE;
        l_category                category.flg_type%TYPE;
        l_id_not_order_reason     not_order_reason.id_not_order_reason%TYPE;
        l_final_order_recurr_plan NUMBER;
        l_order_recurr_desc       VARCHAR2(4000);
        l_order_recurr_option     order_recurr_plan.id_order_recurr_option%TYPE;
        l_start_date              order_recurr_plan.start_date%TYPE;
        l_occurrences             order_recurr_plan.occurrences%TYPE;
        l_duration                order_recurr_plan.duration%TYPE;
        l_unit_meas_duration      order_recurr_plan.id_unit_meas_duration%TYPE;
        l_end_date                order_recurr_plan.end_date%TYPE;
        l_flg_end_by_editable     VARCHAR2(1);
    
        l_id_nurse_tea_req_h nurse_tea_req_hist.id_nurse_tea_req_hist%TYPE;
        l_dt_nurse_tea_req_h nurse_tea_req_hist.dt_nurse_tea_req_tstz%TYPE;
    
        l_nurse_tea_req_row nurse_tea_req%ROWTYPE;
    
        l_lst_not_order_reason table_number := table_number();
        l_id_nurse_tea_req     table_number := table_number();
    
        l_tbl_diagnosis    table_number := table_number();
        l_tbl_compositions table_number := table_number();
    
        l_rows         table_varchar := table_varchar();
        l_rows_ntrd    table_varchar := table_varchar();
        l_rows_ntr_ins table_varchar := table_varchar();
        l_rows_out     table_varchar := table_varchar();
    BEGIN
    
        g_error := 'ERROR FETCHING NURSE_TEA_REQ ROW';
        SELECT *
          INTO l_nurse_tea_req_row
          FROM nurse_tea_req ntr
         WHERE ntr.id_nurse_tea_req = i_task_request;
    
        g_sysdate_tstz := current_timestamp;
        l_category     := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
    
        IF l_nurse_tea_req_row.id_not_order_reason IS NOT NULL
        THEN
            l_lst_not_order_reason := table_number(l_nurse_tea_req_row.id_not_order_reason);
        ELSE
            l_lst_not_order_reason := table_number();
        END IF;
    
        l_start_date_tstz := coalesce(l_nurse_tea_req_row.dt_begin_tstz,
                                      pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                    i_prof      => i_prof,
                                                                    i_timestamp => l_nurse_tea_req_row.dt_begin_tstz,
                                                                    i_timezone  => NULL));
    
        l_id_nurse_tea_req.extend;
        l_id_nurse_tea_req(l_id_nurse_tea_req.count) := ts_nurse_tea_req.next_key;
    
        IF l_nurse_tea_req_row.id_order_recurr_plan IS NOT NULL
        THEN
            g_error := 'copy_order_recurr_plan';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_order_recurrence_core.copy_order_recurr_plan(i_lang                   => i_lang,
                                                                   i_prof                   => i_prof,
                                                                   i_order_recurr_plan_from => l_nurse_tea_req_row.id_order_recurr_plan,
                                                                   o_order_recurr_desc      => l_order_recurr_desc,
                                                                   o_order_recurr_option    => l_order_recurr_option,
                                                                   o_start_date             => l_start_date,
                                                                   o_occurrences            => l_occurrences,
                                                                   o_duration               => l_duration,
                                                                   o_unit_meas_duration     => l_unit_meas_duration,
                                                                   o_end_date               => l_end_date,
                                                                   o_flg_end_by_editable    => l_flg_end_by_editable,
                                                                   o_order_recurr_plan      => l_final_order_recurr_plan,
                                                                   o_error                  => o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSE
            IF NOT pk_order_recurrence_core.create_order_recurr_plan(i_lang                => i_lang,
                                                                     i_prof                => i_prof,
                                                                     i_order_recurr_area   => 'PATIENT_EDUCATION',
                                                                     o_order_recurr_desc   => l_order_recurr_desc,
                                                                     o_order_recurr_option => l_order_recurr_option,
                                                                     o_start_date          => l_start_date,
                                                                     o_occurrences         => l_occurrences,
                                                                     o_duration            => l_duration,
                                                                     o_unit_meas_duration  => l_unit_meas_duration,
                                                                     o_end_date            => l_end_date,
                                                                     o_flg_end_by_editable => l_flg_end_by_editable,
                                                                     o_order_recurr_plan   => l_final_order_recurr_plan,
                                                                     o_error               => o_error)
            THEN
                g_error := 'error found while calling pk_order_recurrence_core.create_order_recurr_plan function';
                RAISE g_exception;
            END IF;
        END IF;
    
        --g_error := 'Insert request / l_id_order_plan=' || i_order_recurr(i);
        ts_nurse_tea_req.ins(id_nurse_tea_req_in      => l_id_nurse_tea_req(l_id_nurse_tea_req.count),
                             id_prof_req_in           => i_prof.id,
                             id_episode_in            => i_episode,
                             flg_status_in            => l_nurse_tea_req_row.flg_status,
                             notes_req_in             => l_nurse_tea_req_row.notes_req,
                             dt_nurse_tea_req_tstz_in => g_sysdate_tstz,
                             dt_begin_tstz_in         => l_start_date_tstz,
                             id_visit_in              => CASE
                                                             WHEN i_episode IS NULL THEN
                                                              NULL
                                                             ELSE
                                                              pk_episode.get_id_visit(i_episode => i_episode)
                                                         END,
                             id_patient_in            => CASE
                                                             WHEN i_episode IS NULL THEN
                                                              NULL
                                                             ELSE
                                                              pk_episode.get_id_patient(i_episode => i_episode)
                                                         END,
                             id_nurse_tea_topic_in    => l_nurse_tea_req_row.id_nurse_tea_topic,
                             id_order_recurr_plan_in  => l_final_order_recurr_plan,
                             description_in           => l_nurse_tea_req_row.description,
                             flg_time_in              => l_nurse_tea_req_row.flg_time,
                             desc_topic_aux_in        => l_nurse_tea_req_row.desc_topic_aux,
                             id_not_order_reason_in   => l_nurse_tea_req_row.id_not_order_reason,
                             rows_out                 => l_rows);
    
        insert_ntr_hist(i_lang             => i_lang,
                        i_prof             => i_prof,
                        i_id_nurse_tea_req => l_id_nurse_tea_req(l_id_nurse_tea_req.count),
                        o_error            => o_error);
    
        IF i_episode IS NOT NULL
        THEN
            g_error := 'INSERT LOG ON TI_LOG';
            IF NOT t_ti_log.ins_log(i_lang,
                                    i_prof,
                                    i_episode,
                                    CASE WHEN l_nurse_tea_req_row.flg_status != 'D' THEN
                                    pk_patient_education_constant.g_nurse_tea_req_pend ELSE
                                    pk_patient_education_constant.g_nurse_tea_req_draft END,
                                    l_id_nurse_tea_req(l_id_nurse_tea_req.count),
                                    'NT',
                                    o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        pk_alertlog.log_debug('Associate diagnoses to request');
        IF l_category = pk_alert_constant.g_cat_type_nurse
        THEN
        
            SELECT ntrd.id_composition
              BULK COLLECT
              INTO l_tbl_compositions
              FROM nurse_tea_req_diag ntrd
             WHERE ntrd.id_nurse_tea_req = i_task_request
               AND ntrd.id_composition IS NOT NULL;
        
            IF l_tbl_compositions.exists(1)
            THEN
                IF NOT create_req_diagnosis(i_lang          => i_lang,
                                            i_prof          => i_prof,
                                            i_category      => l_category,
                                            i_nurse_tea_req => l_id_nurse_tea_req(l_id_nurse_tea_req.count),
                                            i_diagnoses     => l_tbl_compositions,
                                            o_rows          => l_rows,
                                            o_error         => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
                l_rows_ntrd := l_rows_ntrd MULTISET UNION l_rows;
            
                g_error := 'Process insert on NURSE_TEA_REQ_DIAG';
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'NURSE_TEA_REQ_DIAG',
                                              i_rowids     => l_rows_ntrd,
                                              o_error      => o_error);
            END IF;
        ELSE
            -- physican 
            SELECT ntrd.id_diagnosis
              BULK COLLECT
              INTO l_tbl_diagnosis
              FROM nurse_tea_req_diag ntrd
             WHERE ntrd.id_nurse_tea_req = i_task_request
               AND ntrd.id_diagnosis IS NOT NULL;
        
            IF l_tbl_diagnosis IS NOT NULL
               AND l_tbl_diagnosis.count > 0
            THEN
                g_error := 'SET DIAGNOSIS';
                IF NOT pk_diagnosis.set_mcdt_req_diag_no_commit(i_lang              => i_lang,
                                                                i_prof              => i_prof,
                                                                i_epis              => i_episode,
                                                                i_diag              => l_tbl_diagnosis,
                                                                i_desc_diagnosis    => NULL,
                                                                i_exam_req          => NULL,
                                                                i_analysis_req      => NULL,
                                                                i_interv_presc      => NULL,
                                                                i_exam_req_det      => NULL,
                                                                i_analysis_req_det  => NULL,
                                                                i_interv_presc_det  => NULL,
                                                                i_epis_complication => NULL,
                                                                i_epis_comp_hist    => NULL,
                                                                i_nurse_tea_req     => l_id_nurse_tea_req(l_id_nurse_tea_req.count),
                                                                o_error             => o_error)
                THEN
                    g_error := to_char('Call to PK_DIAGNOSIS.SET_MCDT_REQ_DIAG_NO_COMMIT');
                    RAISE g_exception;
                END IF;
            
                FOR i IN l_tbl_diagnosis.first .. l_tbl_diagnosis.last
                LOOP
                
                    SELECT MAX(h.id_nurse_tea_req_hist)
                      INTO l_id_nurse_tea_req_h
                      FROM nurse_tea_req_hist h
                     WHERE h.id_nurse_tea_req = i_task_request;
                
                    SELECT h.dt_nurse_tea_req_hist_tstz
                      INTO l_dt_nurse_tea_req_h
                      FROM nurse_tea_req_hist h
                     WHERE h.id_nurse_tea_req_hist = i_task_request;
                
                    ts_nurse_tea_req_diag_hist.ins(id_nurse_tea_req_diag_hist_in => ts_nurse_tea_req_diag_hist.next_key,
                                                   id_nurse_tea_req_diag_in      => NULL,
                                                   id_nurse_tea_req_in           => l_id_nurse_tea_req(l_id_nurse_tea_req.count),
                                                   id_diagnosis_in               => l_tbl_diagnosis(i),
                                                   id_composition_in             => NULL,
                                                   id_nan_diagnosis_in           => NULL,
                                                   dt_nurse_tea_req_diag_tstz_in => l_dt_nurse_tea_req_h,
                                                   id_nurse_tea_req_hist_in      => l_id_nurse_tea_req_h,
                                                   rows_out                      => l_rows);
                
                    g_error := 'PROCESS INSERT ON NURSE_TEA_REQ_DIAG';
                    t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'NURSE_TEA_REQ_DIAG_HIST',
                                                  i_rowids     => l_rows,
                                                  o_error      => o_error);
                END LOOP;
            END IF;
        END IF;
    
        g_error := 'Process insert on NURSE_TEA_REQ';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'NURSE_TEA_REQ',
                                      i_rowids     => l_rows_ntr_ins,
                                      o_error      => o_error);
    
        o_nurse_tea_req := l_id_nurse_tea_req(l_id_nurse_tea_req.count);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_NTR_COPY_TASK',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_ntr_copy_task;

    FUNCTION set_ntr_delete_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        FOR i IN 1 .. i_task_request.count
        LOOP
            g_error := 'DELETE NURSE_TEA_REQ_DIAG_HIST';
            ts_nurse_tea_req_diag_hist.del_by(where_clause_in => 'id_nurse_tea_req = ' || i_task_request(i));
        
            g_error := 'DELETE NURSE_TEA_REQ_DIAG';
            ts_nurse_tea_req_diag.del_by(where_clause_in => 'id_nurse_tea_req = ' || i_task_request(i));
        
            g_error := 'DELETE NURSE_TEA_REQ_HIST';
            ts_nurse_tea_req_hist.del_by(where_clause_in => 'id_nurse_tea_req = ' || i_task_request(i));
        
            g_error := 'DELETE NURSE_TEA_REQ';
            ts_nurse_tea_req.del_by(where_clause_in => 'id_nurse_tea_req = ' || i_task_request(i));
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
                                              'SET_NTR_DELETE_TASK',
                                              o_error);
            RETURN FALSE;
    END set_ntr_delete_task;

    FUNCTION get_patient_education_date_limits
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN table_number,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'OPEN O_LIST';
        OPEN o_list FOR
            SELECT ntr.id_nurse_tea_req, ntr.dt_begin_tstz, ntr.dt_close_tstz dt_end
              FROM nurse_tea_req ntr
             WHERE ntr.id_nurse_tea_req IN (SELECT /*+opt_estimate(table t rows=1)*/
                                             *
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
                                              'GET_PATIENT_EDUCATION_DATE_LIMITS',
                                              o_error);
            RETURN FALSE;
    END get_patient_education_date_limits;

BEGIN
    NULL;

END pk_patient_education_core;
/
