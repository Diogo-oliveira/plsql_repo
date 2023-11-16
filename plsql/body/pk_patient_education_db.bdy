/*-- Last Change Revision: $Rev: 2027460 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:17 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_patient_education_db IS

    -- Private variable declarations
    g_package_owner VARCHAR2(30 CHAR);
    g_package_name  VARCHAR2(30 CHAR);

    g_error   VARCHAR2(1000 CHAR);
    g_sysdate TIMESTAMP(6) WITH LOCAL TIME ZONE;
    g_retval  BOOLEAN;
    g_exception    EXCEPTION;
    g_exception_np EXCEPTION;
    g_date     VARCHAR2(1 CHAR) := 'D';
    g_no_color VARCHAR2(1) := 'X';

    -- Function and procedure implementations

    /**
     * Associates a set of diagnosis to a patient education request.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_nurse_tea_req Patient education request.
     * @param i_diagnoses Set of diagnoses to associate with a patient education request.
     * @param o_rows List of inserted ROWIDs.
     * @param o_error An error message, set when return=false.
     * 
     * @return TRUE if sucess, FALSE otherwise.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 23/May/2011
    */
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
            IF NOT pk_patient_education_db.create_executions(i_lang            => i_lang,
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
            
                IF NOT pk_patient_education_db.create_execution(i_lang                  => i_lang,
                                                                i_prof                  => i_prof,
                                                                i_id_nurse_tea_req      => i_id_nurse_tea_req(i),
                                                                i_dt_start              => l_start_date,
                                                                i_dt_nurse_tea_det_tstz => g_sysdate_tstz,
                                                                i_flg_status            => g_nurse_tea_req_pend,
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

    /**
    * Creates a patient education execution
    *
    * @param   i_lang                    Language associated to the professional 
    * @param   i_prof                    Professional, institution and software ids
    * @param   i_id_nurse_tea_req        Patient education request identifier
    * @param   i_dt_start                Start date for patient education
    * @param   i_dt_nurse_tea_det_tstz   Date of teaching execution insertion
    * @param   i_flg_status              Execution status
    * @param   i_num_order               Execution order number
    * @param   o_error                   An error message, set when return=false
    *
    * @value   i_flg_status              {*} 'D' Pending {*} 'E' Complete {*} 'C' Cancelled
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  ana.monteiro
    * @version 1.0
    * @since   02-05-2011 
    */
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
                             flg_status_in            => pk_patient_education_ux.g_nurse_tea_det_pend,
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

    /**
    * Cancels several patient education executions
    *
    * @param   i_lang                   Language associated to the professional 
    * @param   i_prof                   Professional, institution and software ids
    * @param   i_id_nurse_tea_det_tab   Array of Patient education execution identifiers
    * @param   o_error                  An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  ana.monteiro
    * @version 1.0
    * @since   16-01-2013 
    */
    FUNCTION cancel_executions
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_nurse_tea_det_tab IN table_number,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rows_t table_varchar := table_varchar();
        l_rows   table_varchar := table_varchar();
    BEGIN
        g_error := 'Init cancel_execution / i_id_nurse_tea_det_tab.count=' || i_id_nurse_tea_det_tab.count;
        pk_alertlog.log_init(g_error);
    
        FOR i IN 1 .. i_id_nurse_tea_det_tab.count
        LOOP
            ts_nurse_tea_det.upd(id_nurse_tea_det_in => i_id_nurse_tea_det_tab(i),
                                 flg_status_in       => pk_patient_education_ux.g_nurse_tea_det_canc,
                                 rows_out            => l_rows_t);
        
            l_rows := l_rows MULTISET UNION l_rows_t;
        END LOOP;
    
        g_error := 'Process insert on NURSE_TEA_DET';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
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
                                              'CANCEL_EXECUTIONS',
                                              o_error);
        
            RETURN FALSE;
    END cancel_executions;

    /**
    * Cancels several patient education executions
    *
    * @param   i_lang                   Language associated to the professional 
    * @param   i_prof                   Professional, institution and software ids
    * @param   i_id_nurse_tea_req_tab   Array of Patient education request identifier
    * @param   i_flg_status_det         Patient education detail status to be canceled
    * @param   o_error                  An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  ana.monteiro
    * @version 1.0
    * @since   16-01-2013 
    */
    FUNCTION cancel_executions
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_nurse_tea_req_tab IN table_number,
        i_flg_status_det       IN nurse_tea_det.flg_status%TYPE DEFAULT NULL,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_nurse_tea_det(x_id_nurse_tea_req_tab IN table_number) IS
            SELECT ntd.id_nurse_tea_det
              FROM nurse_tea_req ntr
              JOIN nurse_tea_det ntd
                ON ntr.id_nurse_tea_req = ntd.id_nurse_tea_req
              JOIN TABLE(CAST(x_id_nurse_tea_req_tab AS table_number)) t
                ON (t.column_value = ntr.id_nurse_tea_req)
             WHERE ntd.flg_status = nvl(i_flg_status_det, ntd.flg_status)
             ORDER BY ntd.num_order;
    
        l_ntr_det_tab table_number;
    BEGIN
        g_error := 'Init cancel_executions / i_id_nurse_tea_req_tab.count=' || i_id_nurse_tea_req_tab.count;
        pk_alertlog.log_init(g_error);
    
        OPEN c_nurse_tea_det(i_id_nurse_tea_req_tab);
        FETCH c_nurse_tea_det BULK COLLECT
            INTO l_ntr_det_tab;
        CLOSE c_nurse_tea_det;
    
        g_error := 'Call cancel_executions / i_id_nurse_tea_det=' || pk_utils.to_string(l_ntr_det_tab);
        IF NOT cancel_executions(i_lang                 => i_lang,
                                 i_prof                 => i_prof,
                                 i_id_nurse_tea_det_tab => l_ntr_det_tab,
                                 o_error                => o_error)
        THEN
            RAISE g_exception;
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
                                              'CANCEL_EXECUTIONS',
                                              o_error);
        
            RETURN FALSE;
    END cancel_executions;

    /**
    * Cancels a patient education execution
    *
    * @param   i_lang             Language associated to the professional 
    * @param   i_prof             Professional, institution and software ids
    * @param   i_id_nurse_tea_det Details about a patient education execution identifier
    * @param   o_error            An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  ana.monteiro
    * @version 1.0
    * @since   02-05-2011 
    */
    FUNCTION cancel_execution
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_det IN nurse_tea_det.id_nurse_tea_det%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'Init cancel_execution / i_id_nurse_tea_det=' || i_id_nurse_tea_det;
        pk_alertlog.log_init(g_error);
    
        IF NOT cancel_executions(i_lang                 => i_lang,
                                 i_prof                 => i_prof,
                                 i_id_nurse_tea_det_tab => table_number(i_id_nurse_tea_det),
                                 o_error                => o_error)
        THEN
            RAISE g_exception;
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
                                              'CANCEL_EXECUTION',
                                              o_error);
        
            RETURN FALSE;
    END cancel_execution;

    /**
    * Creates a patient education execution
    *
    * @param   i_lang                    Language associated to the professional 
    * @param   i_prof                    Professional, institution and software ids
    * @param   i_exec_tab                Order recurrence plan info
    * @param   o_exec_to_process         For each plan, indicates if there are more executions to be processed
    * @param   o_error                   An error message, set when return=false    
    *
    * @value   o_exec_to_process         {*} 'Y' there are more executions to be processed {*} 'N' there are no more executions to be processed
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  ana.monteiro
    * @version 1.0
    * @since   06-05-2011 
    */
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
                   (pk_patient_education_ux.g_nurse_tea_req_pend, pk_patient_education_ux.g_nurse_tea_req_act)
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
             WHERE ntr.flg_status IN
                   (pk_patient_education_ux.g_nurse_tea_req_pend, pk_patient_education_ux.g_nurse_tea_req_act)
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
             WHERE ntr.flg_status IN
                   (pk_patient_education_ux.g_nurse_tea_req_pend, pk_patient_education_ux.g_nurse_tea_req_act)
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
                        ' i_flg_status=' || pk_patient_education_ux.g_nurse_tea_det_pend || ' i_num_order=' || l_ntr_tab(req_idx).exec_number;
            g_retval := create_execution(i_lang                  => i_lang,
                                         i_prof                  => i_prof,
                                         i_id_nurse_tea_req      => l_ntr_tab(req_idx).id_nurse_tea_req,
                                         i_dt_start              => l_ntr_tab(req_idx).exec_timestamp,
                                         i_dt_nurse_tea_det_tstz => g_sysdate,
                                         i_flg_status            => pk_patient_education_ux.g_nurse_tea_det_pend,
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

    /******************************************************************************/
    PROCEDURE prv_alter_ntr_by_id
    (
        i_lang                 IN language.id_language%TYPE,
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
        o_rowids               IN OUT table_varchar
    ) IS
        -- Auxiliar Variables
        dt_aux_nurse_tea_req_tstz TIMESTAMP WITH TIME ZONE := NULL;
        dt_aux_begin_tstz         TIMESTAMP WITH TIME ZONE := NULL;
        dt_aux_close_tstz         TIMESTAMP WITH TIME ZONE := NULL;
        --
        l_ntr_row_old nurse_tea_req%ROWTYPE;
        l_ntr_row     nurse_tea_req%ROWTYPE;
    
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
    
        -- < DESNORM Luís Maia - Sep 2008 >
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
        l_ntr_row.dt_nurse_tea_req_tstz := current_timestamp;
    
        -- Realiza o UPDATE à linha da tabela NURSE_TEA_REQ
        g_error := 'NURSE_TEA_REQ';
        ts_nurse_tea_req.upd(rec_in => l_ntr_row, rows_out => o_rowids);
        -- < END DESNORM >
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
        
    END prv_alter_ntr_by_id;

    /******************************************************************************/
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
               ntr.id_cancel_reason,
               ntr.id_context,
               ntr.flg_context,
               ntr.id_nurse_tea_topic,
               ntr.id_order_recurr_plan,
               ntr.description,
               ntr.flg_time,
               ntr.desc_topic_aux,
               current_timestamp,
               ntr.id_not_order_reason
          INTO l_rec.id_nurse_tea_req_hist,
               l_rec.id_nurse_tea_req,
               l_rec.id_prof_req,
               l_rec.id_episode,
               l_rec.req_header,
               l_rec.flg_status,
               l_rec.notes_req,
               l_rec.id_prof_close,
               l_rec.notes_close,
               l_rec.id_prof_exec,
               l_rec.id_prev_episode,
               l_rec.dt_nurse_tea_req_tstz,
               l_rec.dt_begin_tstz,
               l_rec.dt_close_tstz,
               l_rec.id_visit,
               l_rec.id_patient,
               l_rec.status_flg,
               l_rec.status_icon,
               l_rec.status_msg,
               l_rec.status_str,
               l_rec.id_cancel_reason,
               l_rec.id_context,
               l_rec.flg_context,
               l_rec.id_nurse_tea_topic,
               l_rec.id_order_recurr_plan,
               l_rec.description,
               l_rec.flg_time,
               l_rec.desc_topic_aux,
               l_rec.dt_nurse_tea_req_hist_tstz,
               l_rec.id_not_order_reason
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
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'INSERT_NTR_HIST',
                                              o_error);
    END insert_ntr_hist;

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
    
        --l_error      VARCHAR2(4000);
        l_error      t_error_out;
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
        prv_alter_ntr_by_id(i_lang             => i_lang,
                            i_id_nurse_tea_req => i_nurse_tea_req,
                            i_flg_status       => CASE
                                                      WHEN i_flg_descontinue = pk_alert_constant.g_yes THEN
                                                       pk_patient_education_db.g_nurse_tea_req_descontinued
                                                      ELSE
                                                       pk_icnp_constant.g_epis_diag_status_cancelled
                                                  END,
                            -- José Brito 28/03/2008 WO11229
                            -- Ao cancelar era alterado o ID_PROF_REQ para o ID do profissional que CANCELOU.
                            -- Tal não deve acontecer. Passando o i_prof.ID como NULO não altera os dados da requisição.
                            i_id_prof_req => profissional(NULL, i_prof_close.institution, i_prof_close.software),
                            --
                            i_dt_close_str     => pk_date_utils.get_timestamp_str(i_lang, i_prof_close, g_sysdate_tstz, NULL),
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
                l_ret   := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                o_error := l_error_out;
                IF i_flg_commit = pk_alert_constant.g_yes
                THEN
                    pk_utils.undo_changes;
                END IF;
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END cancel_nurse_tea_req_int;

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
            g_error := 'Add to history';
            insert_ntr_hist(i_lang             => i_lang,
                            i_prof             => i_prof,
                            i_id_nurse_tea_req => i_id_nurse_tea_req(i),
                            o_error            => o_error);
        
            IF NOT cancel_nurse_tea_req_int(i_lang             => i_lang,
                                            i_nurse_tea_req    => i_id_nurse_tea_req(i),
                                            i_prof_close       => i_prof,
                                            i_notes_close      => i_cancel_notes,
                                            i_id_cancel_reason => i_id_cancel_reason,
                                            i_flg_commit       => pk_alert_constant.g_no,
                                            o_error            => o_error)
            THEN
                RAISE g_exception;
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
                                              'CANCEL_PATIENT_EDUCATION',
                                              o_error);
        
            RETURN FALSE;
    END cancel_patient_education;

    FUNCTION descontinue_patient_education
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_req IN table_number,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes     IN nurse_tea_req.notes_close%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'Descontinue patient education';
        FOR i IN 1 .. i_id_nurse_tea_req.count
        LOOP
            g_error := 'Add to history';
            insert_ntr_hist(i_lang             => i_lang,
                            i_prof             => i_prof,
                            i_id_nurse_tea_req => i_id_nurse_tea_req(i),
                            o_error            => o_error);
        
            IF NOT cancel_nurse_tea_req_int(i_lang             => i_lang,
                                            i_nurse_tea_req    => i_id_nurse_tea_req(i),
                                            i_prof_close       => i_prof,
                                            i_notes_close      => i_cancel_notes,
                                            i_id_cancel_reason => i_id_cancel_reason,
                                            i_flg_commit       => pk_alert_constant.g_no,
                                            i_flg_descontinue  => pk_alert_constant.g_yes,
                                            o_error            => o_error)
            THEN
                RAISE g_exception;
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
                                              'DESCONTINUE_PATIENT_EDUCATION',
                                              o_error);
        
            RETURN FALSE;
    END descontinue_patient_education;

    /********************************************************************************************
    * get nurse teach topic title
    *
    * @param       i_lang                      preferred language id    
    * @param       i_prof                      professional structure
    * @param       i_nurse_tea_topic           nurse teach topic id
    *
    * @return      boolean                     true on success, otherwise false    
    *
    * @author                                  Tiago Silva
    * @since                                   13-MAY-2011
    ********************************************************************************************/
    FUNCTION get_nurse_teach_topic_title
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_nurse_tea_topic IN nurse_tea_topic.id_nurse_tea_topic%TYPE
    ) RETURN VARCHAR2 IS
        l_nurse_teach_title VARCHAR2(1000 CHAR);
    BEGIN
    
        g_error := 'get nurse teach topic title';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        SELECT pk_translation.get_translation(i_lang, ntt.code_nurse_tea_topic) title_topic
          INTO l_nurse_teach_title
          FROM nurse_tea_topic ntt
         WHERE ntt.id_nurse_tea_topic = i_nurse_tea_topic;
    
        RETURN l_nurse_teach_title;
    
    END get_nurse_teach_topic_title;

    /********************************************************************************************
    * get nurse teach topic description
    *
    * @param       i_lang                      preferred language id    
    * @param       i_prof                      professional structure
    * @param       i_nurse_tea_topic           nurse teach topic id
    *
    * @return      boolean                     true on success, otherwise false    
    *
    * @author                                  Tiago Silva
    * @since                                   24-MAY-2011
    ********************************************************************************************/
    FUNCTION get_nurse_teach_topic_desc
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_nurse_tea_topic IN nurse_tea_topic.id_nurse_tea_topic%TYPE
    ) RETURN CLOB IS
        l_nurse_teach_desc CLOB;
    BEGIN
    
        g_error := 'get nurse teach topic description';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        SELECT pk_translation.get_translation(i_lang, ntt.code_topic_description) desc_topic
          INTO l_nurse_teach_desc
          FROM nurse_tea_topic ntt
         WHERE ntt.id_nurse_tea_topic = i_nurse_tea_topic;
    
        RETURN l_nurse_teach_desc;
    
    END get_nurse_teach_topic_desc;

    /********************************************************************************************
    * checks if a nurse teaching topic is available to be ordered or not
    *
    * @param       i_lang                      preferred language id    
    * @param       i_prof                      professional structure
    * @param       i_patient                   patient id
    * @param       i_episode                   episode id
    * @param       i_nurse_tea_topic           nurse teach topic id
    * @param       o_flg_conflict              flag that indicates if exists conflict or not
    * @param       o_error                     error structure for exception handling
    *
    * @return      boolean                     true on success, otherwise false    
    *
    * @author                                  Tiago Silva
    * @since                                   17-MAY-2011
    ********************************************************************************************/
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
                   AND nttsi.flg_type = g_nurse_tea_searchable
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
                   AND nttsi.flg_type = g_nurse_tea_searchable
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
        IF NOT pk_patient_education_db.create_req(i_lang                  => i_lang,
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
                                                  o_id_nurse_tea_req      => l_id_nurse_tea_req,
                                                  o_error                 => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF l_flg_profile = pk_prof_utils.g_flg_profile_template_student
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
                l_start_date := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                              i_prof      => i_prof,
                                                              i_timestamp => i_start_date(i),
                                                              i_timezone  => NULL);
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
                                                                         WHEN l_not_order_reason IS NOT NULL THEN
                                                                          g_nurse_tea_req_not_ord_reas
                                                                         WHEN i_draft = pk_alert_constant.g_no THEN
                                                                          g_nurse_tea_req_pend
                                                                         WHEN i_draft = pk_alert_constant.g_yes THEN
                                                                          g_nurse_tea_req_draft
                                                                     END,
                                         notes_req_in             => i_notes(i),
                                         dt_nurse_tea_req_tstz_in => g_sysdate_tstz,
                                         dt_begin_tstz_in         => l_start_date,
                                         id_visit_in              => pk_episode.get_id_visit(i_episode => i_id_episode),
                                         id_patient_in            => pk_episode.get_id_patient(i_episode => i_id_episode),
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
                                                                          g_nurse_tea_req_not_ord_reas
                                                                         WHEN i_draft = pk_alert_constant.g_no THEN
                                                                          g_nurse_tea_req_pend
                                                                         WHEN i_draft = pk_alert_constant.g_yes THEN
                                                                          g_nurse_tea_req_draft
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
            
                g_error := 'INSERT LOG ON TI_LOG';
                IF NOT t_ti_log.ins_log(i_lang,
                                        i_prof,
                                        i_id_episode,
                                        CASE WHEN i_draft = pk_alert_constant.g_no THEN g_nurse_tea_req_pend WHEN
                                        i_draft = pk_alert_constant.g_yes THEN g_nurse_tea_req_draft END,
                                        l_id_nurse_tea_req(i),
                                        'NT',
                                        o_error)
                THEN
                    RAISE g_exception;
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
                                
                                    g_error := 'PROCESS INSERT ON NURSE_TEA_REQ_DIAG';
                                    t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                                  i_prof       => i_prof,
                                                                  i_table_name => 'NURSE_TEA_REQ_DIAG_HIST',
                                                                  i_rowids     => l_rows,
                                                                  o_error      => o_error);
                                
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
            
            END LOOP topics;
        
        END IF;
    
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
               AND ntd.flg_status = pk_patient_education_ux.g_nurse_tea_det_pend
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
    
        OPEN c_nurse_tea_det;
        FETCH c_nurse_tea_det BULK COLLECT
            INTO l_nurse_tea_det;
        CLOSE c_nurse_tea_det;
    
        -- getting diagnoses for phisican      
        IF i_diagnoses IS NOT NULL
           AND i_diagnoses.count > 0
        THEN
            l_lst_diagnosis := pk_diagnosis.get_diag_rec(i_lang => i_lang, i_prof => i_prof, i_params => i_diagnoses);
        END IF;
    
        -- ignores previous pendent executions
        g_error := 'Call cancel_executions';
        FOR i IN 1 .. l_nurse_tea_det.count
        LOOP
            ts_nurse_tea_det.upd(id_nurse_tea_det_in => l_nurse_tea_det(i),
                                 flg_status_in       => pk_patient_education_ux.g_nurse_tea_det_ign,
                                 rows_out            => l_rows_ntd);
        END LOOP;
    
        g_error := 'Process insert on NURSE_TEA_DET';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'NURSE_TEA_DET',
                                      i_rowids     => l_rows_ntd,
                                      o_error      => o_error);
    
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
            l_start_date := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                          i_prof      => i_prof,
                                                          i_timestamp => i_start_date(i),
                                                          i_timezone  => NULL);
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
                                                                     WHEN l_not_order_reason IS NOT NULL THEN
                                                                      g_nurse_tea_req_not_ord_reas
                                                                     ELSE
                                                                      g_nurse_tea_req_pend
                                                                 END,
                                     notes_req_in             => i_notes(i),
                                     notes_req_nin            => FALSE,
                                     dt_nurse_tea_req_tstz_in => g_sysdate_tstz,
                                     dt_begin_tstz_in         => l_start_date,
                                     id_visit_in              => pk_episode.get_id_visit(i_episode => i_id_episode),
                                     id_patient_in            => pk_episode.get_id_patient(i_episode => i_id_episode),
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
                                     id_visit_in              => pk_episode.get_id_visit(i_episode => i_id_episode),
                                     id_patient_in            => pk_episode.get_id_patient(i_episode => i_id_episode),
                                     id_nurse_tea_topic_in    => i_topics(i),
                                     id_order_recurr_plan_in  => l_order_recurr_f(i),
                                     id_order_recurr_plan_nin => FALSE,
                                     description_in           => i_description(i),
                                     description_nin          => FALSE,
                                     flg_time_in              => i_to_be_performed(i),
                                     id_not_order_reason_in   => l_not_order_reason,
                                     rows_out                 => l_rows);
            END IF;
        
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
        
        END LOOP topics;
    
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
         WHERE ntr.flg_status = g_nurse_tea_req_draft;
    
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

    /********************************************************************************************
    * get status of a nurse teaching request
    *
    * @param       i_lang                  preferred language id    
    * @param       i_prof                  professional structure
    * @param       i_id_nurse_tea_req      request ID
    * @param       o_flg_status            request status
    * @param       o_status_string         status string to be parsed by the flash layer
    * @param       o_flg_finished          indicates if the request is finished
    * @param       o_flg_canceled          indicates if the request is canceled
    * @param       o_error                 error structure for exception handling
    *
    * @return      boolean                 true on success, otherwise false    
    *
    * @author                              Tiago Silva
    * @since                               24-MAY-2011
    ********************************************************************************************/
    FUNCTION get_nurse_teach_status
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE,
        o_flg_status       OUT nurse_tea_req.flg_status%TYPE,
        o_status_string    OUT VARCHAR2,
        o_flg_finished     OUT VARCHAR2,
        o_flg_canceled     OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'get nurse teach request status';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        SELECT ntr.flg_status,
               pk_utils.get_status_string(i_lang,
                                          i_prof,
                                          ntr.status_str,
                                          ntr.status_msg,
                                          ntr.status_icon,
                                          ntr.status_flg) status_str,
               decode(ntr.flg_status, g_nurse_tea_req_fin, pk_alert_constant.g_yes, pk_alert_constant.g_no) AS o_flg_finished,
               decode(ntr.flg_status, g_nurse_tea_req_canc, pk_alert_constant.g_yes, pk_alert_constant.g_no) AS flg_canceled
          INTO o_flg_status, o_status_string, o_flg_finished, o_flg_canceled
          FROM nurse_tea_req ntr
         WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_NURSE_TEACH_STATUS',
                                              o_error);
        
            RETURN FALSE;
    END get_nurse_teach_status;

    /**
    * Update the request's status for a patient education as finished
    * 
    * @param i_lang                 Professional preferred language
    * @param i_nurse_tea_req        Patient education request to update
    * @param i_prof                 Professional identification and its context (institution and software)
    * @param i_prof_cat_type        Professional category 
    * @param o_error                Error information
    *
    * @deprecated Replaced by {@link pk_patient_education_db.set_nurse_tea_req_status;2 set_nurse_tea_req_status}
    * @see pk_patient_education_db.set_nurse_tea_req_status;2
    */

    FUNCTION set_nurse_tea_req_status
    (
        i_lang          IN language.id_language%TYPE,
        i_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        co_function_name CONSTANT VARCHAR2(30 CHAR) := 'set_nurse_tea_req_status(1)';
    BEGIN
    
        g_error := 'CALL set_nurse_tea_req_status';
        RETURN set_nurse_tea_req_status(i_lang               => i_lang,
                                        i_prof               => i_prof,
                                        i_prof_cat_type      => i_prof_cat_type,
                                        i_nurse_tea_req_list => table_number(i_nurse_tea_req),
                                        i_flg_status         => g_nurse_tea_req_fin,
                                        o_error              => o_error);
    
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
    END set_nurse_tea_req_status;

    /**
    * Update the request's status for a list of patient education
    *
    * @param i_lang                 Professional preferred language
    * @param i_prof                 Professional identification and its context (institution and software)
    * @param i_prof_cat_type        Professional category
    * @param i_nurse_tea_req_list   List of patient education to update
    * @param i_flg_status           Request's status
    * @param i_notes_close          Notes
    * @param i_flg_commit           Perform transactional commit
    * @param i_flg_history          Saves previous status into history
    * @param o_error                Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.5.1.8
    * @since   13-09-2011
    */
    FUNCTION set_nurse_tea_req_status
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_prof_cat_type      IN category.flg_type%TYPE,
        i_nurse_tea_req_list IN table_number,
        i_flg_status         IN nurse_tea_req.flg_status%TYPE,
        i_notes_close        IN nurse_tea_req.notes_close%TYPE DEFAULT NULL,
        i_flg_commit         IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_flg_history        IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        co_function_name CONSTANT VARCHAR2(30 CHAR) := 'set_nurse_tea_req_status';
        l_idx          PLS_INTEGER;
        l_ntr_rowids   table_varchar;
        l_dt_close_str VARCHAR2(100 CHAR);
        l_prof_req     profissional;
        l_episode_list table_number := table_number();
        l_ntr_rows     ts_nurse_tea_req.nurse_tea_req_ntt;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
        l_dt_close_str := pk_date_utils.get_timestamp_str(i_lang, i_prof, g_sysdate_tstz, NULL);
        l_prof_req     := profissional(NULL, i_prof.institution, i_prof.software);
    
        l_idx := i_nurse_tea_req_list.first;
        WHILE l_idx IS NOT NULL
        LOOP
            IF i_flg_history = pk_alert_constant.g_yes
            THEN
                g_error := 'Add to history';
                insert_ntr_hist(i_lang             => i_lang,
                                i_prof             => i_prof,
                                i_id_nurse_tea_req => i_nurse_tea_req_list(l_idx),
                                o_error            => o_error);
            END IF;
        
            prv_alter_ntr_by_id(i_lang             => i_lang,
                                i_id_nurse_tea_req => i_nurse_tea_req_list(l_idx),
                                i_flg_status       => i_flg_status,
                                i_id_prof_req      => l_prof_req,
                                i_dt_close_str     => l_dt_close_str,
                                i_id_prof_close    => i_prof.id,
                                i_notes_close      => i_notes_close,
                                o_rowids           => l_ntr_rowids);
            l_idx := i_nurse_tea_req_list.next(l_idx);
        END LOOP;
    
        IF l_ntr_rowids IS NOT NULL
           AND l_ntr_rowids.count > 0
        THEN
            g_error := 'CALL t_data_gov_mnt.process_update';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => co_function_name);
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
        END IF;
    
        g_error := 'Select updated entries in NURSE_TEA_REQ';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => co_function_name);
        SELECT ntr.*
          BULK COLLECT
          INTO l_ntr_rows
          FROM nurse_tea_req ntr
         WHERE ntr.id_nurse_tea_req IN (SELECT /*+opt_estimate(table t rows=1) */
                                         column_value
                                          FROM TABLE(i_nurse_tea_req_list) t);
    
        g_error := 'Update TLOG';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => co_function_name);
        l_idx := l_ntr_rows.first;
        WHILE l_idx IS NOT NULL
        LOOP
            IF NOT t_ti_log.ins_log(i_lang       => i_lang,
                                    i_prof       => i_prof,
                                    i_id_episode => l_ntr_rows(l_idx).id_episode,
                                    i_flg_status => l_ntr_rows(l_idx).flg_status,
                                    i_id_record  => l_ntr_rows(l_idx).id_nurse_tea_req,
                                    i_flg_type   => pk_edis_summary.g_ti_log_nurse_tea,
                                    o_error      => o_error)
            THEN
                RAISE g_exception;
            END IF;
            l_episode_list.extend();
            l_episode_list(l_episode_list.last) := l_ntr_rows(l_idx).id_episode;
        
            l_idx := l_ntr_rows.next(l_idx);
        END LOOP;
    
        --A distinct set of episodes in order to suppress eventual overhead when two or more requests of same episode were updated
        l_episode_list := SET(l_episode_list);
    
        IF i_flg_commit = pk_alert_constant.g_yes
        THEN
            COMMIT;
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
            IF i_flg_commit = pk_alert_constant.g_yes
            THEN
                pk_utils.undo_changes;
            END IF;
            RETURN FALSE;
    END set_nurse_tea_req_status;

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
                -- undo changes quando aplicável-> só faz ROLLBACK
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
                                                                           pk_patient_education_db.g_nurse_tea_req_draft
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

    FUNCTION get_subject
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_topic IN nurse_tea_topic.id_nurse_tea_topic%TYPE
    ) RETURN CLOB IS
        l_ret CLOB;
    BEGIN
    
        IF i_id_topic IS NULL
        THEN
            RAISE g_exception;
        END IF;
    
        -- Patient education subject
        SELECT pk_translation_lob.get_translation(i_lang, ntt.code_topic_description)
          INTO l_ret
          FROM nurse_tea_topic ntt
          JOIN nurse_tea_subject nts
            ON nts.id_nurse_tea_subject = ntt.id_nurse_tea_subject
           AND ntt.id_nurse_tea_topic = i_id_topic;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_subject;

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
        i_id_episode    IN episode.id_episode%TYPE DEFAULT NULL,
        i_id_hhc_req    IN epis_hhc_req.id_epis_hhc_req%TYPE DEFAULT NULL,
        o_actions       OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        co_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_request_actions';
        e_function_call_error EXCEPTION;
        l_flg_status table_varchar;
    
        l_epis_type    epis_type.id_epis_type%TYPE;
        l_flg_can_edit VARCHAR2(1) := pk_alert_constant.g_yes;
        l_i_id_hhc_req epis_hhc_req.id_epis_hhc_req%TYPE;
    BEGIN
    
        g_error := 'Checks within selected items if there are requests expired';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => co_function_name);
        SELECT (CASE ntr.flg_status
                   WHEN pk_patient_education_db.g_nurse_tea_req_expired THEN
                   -- Check extra take
                    (CASE pk_patient_education_cpoe.check_extra_take(i_lang         => i_lang,
                                                                 i_prof         => i_prof,
                                                                 i_task_request => ntr.id_nurse_tea_req,
                                                                 i_status       => ntr.flg_status,
                                                                 i_dt_expire    => ntr.dt_close_tstz)
                        WHEN pk_alert_constant.g_yes THEN
                         pk_patient_education_db.g_nurse_tea_req_expired
                        ELSE
                        -- No conditions to allow execution in expired task, so actions are the same as for a cancelled task
                         pk_patient_education_db.g_nurse_tea_req_canc
                    END)
                   ELSE
                    ntr.flg_status
               END) flg_status
          BULK COLLECT
          INTO l_flg_status
          FROM nurse_tea_req ntr
         WHERE ntr.id_nurse_tea_req IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                         t.column_value
                                          FROM TABLE(i_nurse_tea_req) t);
    
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
    
        --determinar se existe algum episódio de hhc?                                                          
    
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
                                 WHEN l_flg_can_edit = pk_alert_constant.g_no
                                      AND internal_name IN ('EDIT', 'CANCEL') THEN
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
    END get_request_actions;

    FUNCTION get_pat_education_cda
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_type_scope  IN VARCHAR2,
        i_id_scope    IN NUMBER,
        o_pat_edu_cda OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name pk_types.t_internal_name_byte := 'GET_PAT_EDUCATION_CDA';
    
        l_id_patient patient.id_patient%TYPE;
        l_id_episode episode.id_episode%TYPE;
        l_id_visit   visit.id_visit%TYPE;
    
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_prof.id = ' || coalesce(to_char(i_prof.id), '<null>');
        g_error := g_error || ' i_prof.institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error := g_error || ' i_prof.software = ' || coalesce(to_char(i_prof.software), '<null>');
        g_error := g_error || ' i_type_scope = ' || coalesce(to_char(i_type_scope), '<null>');
        g_error := g_error || ' i_id_scope = ' || coalesce(to_char(i_id_scope), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        IF i_id_scope IS NULL
           OR i_type_scope IS NULL
        THEN
            g_error := 'Scope id or type is null';
            RAISE g_exception;
        END IF;
    
        g_error := 'Call pk_touch_option.get_scope_vars';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_id_scope,
                                              i_scope_type => i_type_scope,
                                              o_patient    => l_id_patient,
                                              o_visit      => l_id_visit,
                                              o_episode    => l_id_episode,
                                              o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
        g_error := 'Return pk_touch_option.get_scope_vars: ';
        g_error := g_error || ' o_patient = ' || coalesce(to_char(l_id_patient), '<null>');
        g_error := g_error || ' o_visit = ' || coalesce(to_char(l_id_visit), '<null>');
        g_error := g_error || ' o_episode = ' || coalesce(to_char(l_id_episode), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        OPEN o_pat_edu_cda FOR
            SELECT t.id,
                   t.id_content,
                   pk_patient_education_db.get_desc_topic(i_lang,
                                                          i_prof,
                                                          t.id_nurse_tea_topic,
                                                          t.desc_topic_aux,
                                                          t.code_nurse_tea_topic) topic,
                   t.description,
                   t.flg_status
              FROM (SELECT *
                      FROM (SELECT ntr.id_nurse_tea_req id,
                                   ntt.id_content,
                                   ntr.id_nurse_tea_topic,
                                   ntr.desc_topic_aux,
                                   ntt.code_nurse_tea_topic,
                                   ntr.description,
                                   ntr.flg_status,
                                   ntr.id_episode
                              FROM nurse_tea_req ntr
                             INNER JOIN nurse_tea_topic ntt
                                ON ntt.id_nurse_tea_topic = ntr.id_nurse_tea_topic
                             WHERE ntr.flg_status IN (pk_patient_education_ux.g_nurse_tea_req_pend,
                                                      pk_patient_education_ux.g_nurse_tea_req_act)) pat
                     INNER JOIN (SELECT e.id_episode
                                  FROM episode e
                                 WHERE e.id_episode = l_id_episode
                                   AND e.id_patient = l_id_patient
                                   AND i_type_scope = pk_alert_constant.g_scope_type_episode
                                UNION ALL
                                SELECT e.id_episode
                                  FROM episode e
                                 WHERE e.id_patient = l_id_patient
                                   AND i_type_scope = pk_alert_constant.g_scope_type_patient
                                UNION ALL
                                SELECT e.id_episode
                                  FROM episode e
                                 WHERE e.id_visit = l_id_visit
                                   AND e.id_patient = l_id_patient
                                   AND i_type_scope = pk_alert_constant.g_scope_type_visit) epi
                        ON epi.id_episode = pat.id_episode) t;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_pat_edu_cda);
            RETURN FALSE;
    END get_pat_education_cda;

    FUNCTION get_pat_educa_instruct_cda
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_type_scope    IN VARCHAR2,
        i_id_scope      IN NUMBER,
        o_pat_edu_instr OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name pk_types.t_internal_name_byte := 'GET_PAT_EDUCA_INSTRUCT_CDA';
    
        l_id_patient patient.id_patient%TYPE;
        l_id_episode episode.id_episode%TYPE;
        l_id_visit   visit.id_visit%TYPE;
    
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_prof.id = ' || coalesce(to_char(i_prof.id), '<null>');
        g_error := g_error || ' i_prof.institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error := g_error || ' i_prof.software = ' || coalesce(to_char(i_prof.software), '<null>');
        g_error := g_error || ' i_type_scope = ' || coalesce(to_char(i_type_scope), '<null>');
        g_error := g_error || ' i_id_scope = ' || coalesce(to_char(i_id_scope), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        IF i_id_scope IS NULL
           OR i_type_scope IS NULL
        THEN
            g_error := 'Scope id or type is null';
            RAISE g_exception;
        END IF;
    
        g_error := 'Call pk_touch_option.get_scope_vars';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_id_scope,
                                              i_scope_type => i_type_scope,
                                              o_patient    => l_id_patient,
                                              o_visit      => l_id_visit,
                                              o_episode    => l_id_episode,
                                              o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
        g_error := 'Return pk_touch_option.get_scope_vars: ';
        g_error := g_error || ' o_patient = ' || coalesce(to_char(l_id_patient), '<null>');
        g_error := g_error || ' o_visit = ' || coalesce(to_char(l_id_visit), '<null>');
        g_error := g_error || ' o_episode = ' || coalesce(to_char(l_id_episode), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        OPEN o_pat_edu_instr FOR
            SELECT t.id,
                   t.id_content,
                   pk_patient_education_db.get_desc_topic(i_lang,
                                                          i_prof,
                                                          t.id_nurse_tea_topic,
                                                          t.desc_topic_aux,
                                                          t.code_nurse_tea_topic) topic,
                   t.notes,
                   t.flg_status
              FROM (SELECT *
                      FROM (SELECT ntr.id_nurse_tea_req id,
                                   ntt.id_content,
                                   ntr.id_nurse_tea_topic,
                                   ntr.desc_topic_aux,
                                   ntt.code_nurse_tea_topic,
                                   ntdo.notes,
                                   ntr.flg_status,
                                   ntr.id_episode
                              FROM nurse_tea_req ntr
                             INNER JOIN nurse_tea_topic ntt
                                ON ntt.id_nurse_tea_topic = ntr.id_nurse_tea_topic
                             INNER JOIN nurse_tea_det ntd
                                ON ntd.id_nurse_tea_req = ntr.id_nurse_tea_req
                             INNER JOIN nurse_tea_det_opt ntdo
                                ON (ntdo.id_nurse_tea_det = ntd.id_nurse_tea_det AND ntdo.subject = 'DELIVERABLES')
                             WHERE ntd.flg_status = pk_patient_education_ux.g_nurse_tea_det_exec
                               AND ntdo.notes IS NOT NULL) pat
                     INNER JOIN (SELECT e.id_episode
                                  FROM episode e
                                 WHERE e.id_episode = l_id_episode
                                   AND e.id_patient = l_id_patient
                                   AND i_type_scope = pk_alert_constant.g_scope_type_episode
                                UNION ALL
                                SELECT e.id_episode
                                  FROM episode e
                                 WHERE e.id_patient = l_id_patient
                                   AND i_type_scope = pk_alert_constant.g_scope_type_patient
                                UNION ALL
                                SELECT e.id_episode
                                  FROM episode e
                                 WHERE e.id_visit = l_id_visit
                                   AND e.id_patient = l_id_patient
                                   AND i_type_scope = pk_alert_constant.g_scope_type_visit) epi
                        ON epi.id_episode = pat.id_episode) t;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_pat_edu_instr);
            RETURN FALSE;
    END get_pat_educa_instruct_cda;

    FUNCTION get_pat_edu_viewer_checklist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_scope_type IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_episode table_number;
    
        l_count NUMBER;
    
    BEGIN
    
        l_episode := pk_episode.get_scope(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_patient    => i_patient,
                                          i_episode    => i_episode,
                                          i_flg_filter => i_scope_type);
    
        SELECT COUNT(*)
          INTO l_count
          FROM nurse_tea_req ntr
         WHERE ntr.id_episode IN (SELECT /*+opt_estimate (table t rows=1)*/
                                   column_value
                                    FROM TABLE(l_episode) t)
           AND ntr.flg_time IN (pk_patient_education_ux.g_flg_time_episode, pk_patient_education_ux.g_flg_time_before)
           AND ntr.flg_status NOT IN (pk_patient_education_db.g_nurse_tea_req_draft,
                                      pk_patient_education_db.g_nurse_tea_req_canc,
                                      pk_patient_education_db.g_nurse_tea_req_expired);
    
        IF l_count > 0
        THEN
            SELECT COUNT(*)
              INTO l_count
              FROM nurse_tea_req ntr
             WHERE ntr.id_episode IN (SELECT /*+opt_estimate (table t rows=1)*/
                                       column_value
                                        FROM TABLE(l_episode) t)
               AND ntr.flg_time IN
                   (pk_patient_education_ux.g_flg_time_episode, pk_patient_education_ux.g_flg_time_before)
               AND ntr.flg_status NOT IN (pk_patient_education_db.g_nurse_tea_req_not_ord_reas,
                                          pk_patient_education_db.g_nurse_tea_req_fin,
                                          pk_patient_education_db.g_nurse_tea_req_draft,
                                          pk_patient_education_db.g_nurse_tea_req_canc,
                                          pk_patient_education_db.g_nurse_tea_req_expired);
        
            IF l_count > 0
            THEN
                RETURN pk_viewer_checklist.g_checklist_ongoing;
            ELSE
                RETURN pk_viewer_checklist.g_checklist_completed;
            END IF;
        ELSE
            RETURN pk_viewer_checklist.g_checklist_not_started;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_viewer_checklist.g_checklist_not_started;
    END get_pat_edu_viewer_checklist;

    FUNCTION get_pat_education_draft
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        o_has_draft OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_count NUMBER;
    
    BEGIN
        SELECT COUNT(*)
          INTO l_count
          FROM nurse_tea_req ntr
         WHERE ntr.id_episode = i_episode
           AND ntr.flg_status = pk_patient_education_db.g_nurse_tea_req_draft;
    
        IF l_count > 0
        THEN
            o_has_draft := pk_alert_constant.g_yes;
        ELSE
            o_has_draft := pk_alert_constant.g_no;
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
                                              'GET_PAT_EDUCATION_DRAFT',
                                              o_error);
            RETURN FALSE;
    END get_pat_education_draft;

    FUNCTION inactivate_pat_educ_tasks
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_inst  IN institution.id_institution%TYPE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cancel_cfg sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf => 'INACTIVATE_CANCEL_REASON',
                                                                      i_prof    => i_prof);
    
        l_descontinued_cfg sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf => 'INACTIVATE_DISCONTINUED_REASON',
                                                                            i_prof    => i_prof);
    
        l_tbl_config t_tbl_config_table := pk_core_config.get_values_by_mkt_inst_sw(i_lang => NULL,
                                                                                    i_prof => profissional(0, i_inst, 0),
                                                                                    i_area => 'PAT_EDUC_INACTIVATE');
    
        l_cancel_id cancel_reason.id_cancel_reason%TYPE := pk_cancel_reason.get_id_by_content(i_lang,
                                                                                              i_prof,
                                                                                              l_cancel_cfg);
    
        l_descontinued_id cancel_reason.id_cancel_reason%TYPE := pk_cancel_reason.get_id_by_content(i_lang,
                                                                                                    i_prof,
                                                                                                    l_descontinued_cfg);
    
        l_max_rows sys_config.value%TYPE := pk_sysconfig.get_config(i_prof    => i_prof,
                                                                    i_code_cf => 'INACTIVATE_TASKS_MAX_NUMBER_ROWS');
    
        l_pat_educ_req    table_number;
        l_pat_educ_status table_varchar;
    
        l_error t_error_out;
        g_other_exception EXCEPTION;
    
        CURSOR c_pat_educ_req IS
            SELECT id_nurse_tea_req, field_04
              FROM (SELECT ntr.id_nurse_tea_req,
                           cfg.field_04,
                           row_number() over(PARTITION BY ntr.id_nurse_tea_req ORDER BY ntr.id_nurse_tea_req) AS rn
                      FROM nurse_tea_req ntr
                     INNER JOIN nurse_tea_det ntd
                        ON ntr.id_nurse_tea_req = ntd.id_nurse_tea_req
                     INNER JOIN episode e
                        ON e.id_episode = ntr.id_episode
                      LEFT JOIN episode prev_e
                        ON prev_e.id_prev_episode = e.id_episode
                       AND e.id_visit = prev_e.id_visit
                     INNER JOIN (SELECT *
                                  FROM TABLE(l_tbl_config)) cfg
                        ON cfg.field_01 = ntr.flg_status
                     WHERE e.dt_end_tstz IS NOT NULL
                       AND (prev_e.id_episode IS NULL OR prev_e.flg_status = pk_alert_constant.g_inactive)
                       AND pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                            i_timestamp => (pk_date_utils.add_to_ltstz(i_timestamp => e.dt_end_tstz,
                                                                                                       i_amount    => cfg.field_02,
                                                                                                       i_unit      => cfg.field_03))) <=
                           pk_date_utils.trunc_insttimezone(i_prof => i_prof, i_timestamp => current_timestamp)) t
             WHERE rn = 1
               AND rownum < l_max_rows;
    
    BEGIN
    
        OPEN c_pat_educ_req;
        FETCH c_pat_educ_req BULK COLLECT
            INTO l_pat_educ_req, l_pat_educ_status;
        CLOSE c_pat_educ_req;
    
        IF l_pat_educ_req.count > 0
        THEN
            FOR i IN 1 .. l_pat_educ_req.count
            LOOP
                IF l_pat_educ_status(i) = pk_patient_education_db.g_nurse_tea_req_descontinued
                THEN
                    SAVEPOINT init_cancel;
                    IF NOT pk_patient_education_db.cancel_nurse_tea_req_int(i_lang             => i_lang,
                                                                            i_nurse_tea_req    => l_pat_educ_req(i),
                                                                            i_prof_close       => i_prof,
                                                                            i_notes_close      => NULL,
                                                                            i_id_cancel_reason => l_descontinued_id,
                                                                            i_flg_commit       => pk_alert_constant.g_no,
                                                                            i_flg_descontinue  => pk_alert_constant.g_yes,
                                                                            o_error            => l_error)
                    THEN
                        ROLLBACK TO init_cancel;
                    END IF;
                
                ELSIF l_pat_educ_status(i) = pk_patient_education_db.g_nurse_tea_req_canc
                THEN
                    SAVEPOINT init_cancel;
                    IF NOT pk_patient_education_db.cancel_nurse_tea_req_int(i_lang             => i_lang,
                                                                            i_nurse_tea_req    => l_pat_educ_req(i),
                                                                            i_prof_close       => i_prof,
                                                                            i_notes_close      => NULL,
                                                                            i_id_cancel_reason => l_cancel_id,
                                                                            i_flg_commit       => pk_alert_constant.g_no,
                                                                            o_error            => l_error)
                    THEN
                        ROLLBACK TO init_cancel;
                    END IF;
                END IF;
            END LOOP;
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
                                              'INACTIVATE_PAT_EDUC_TASKS',
                                              o_error);
            RETURN FALSE;
    END inactivate_pat_educ_tasks;

    FUNCTION get_pat_educ_add_resources
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE
    ) RETURN CLOB IS
    
        l_add_resources CLOB;
    
    BEGIN
        BEGIN
            SELECT nvl(pk_translation.get_translation(2, nto.code_nurse_tea_opt), ntdo.notes)
              INTO l_add_resources
              FROM nurse_tea_req ntr
              JOIN nurse_tea_det ntd
                ON ntr.id_nurse_tea_req = ntd.id_nurse_tea_req
              JOIN nurse_tea_det_opt ntdo
                ON ntd.id_nurse_tea_det = ntdo.id_nurse_tea_det
              LEFT JOIN nurse_tea_opt nto
                ON ntdo.id_nurse_tea_opt = nto.id_nurse_tea_opt
             WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req;
        EXCEPTION
            WHEN no_data_found THEN
                l_add_resources := NULL;
            WHEN too_many_rows THEN
                l_add_resources := NULL;
        END;
    
        RETURN l_add_resources;
    
    END get_pat_educ_add_resources;

    FUNCTION get_pat_education_info
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE,
        o_pat_edu_info  OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        OPEN o_pat_edu_info FOR
            SELECT ntr.id_nurse_tea_req,
                   ntr.flg_status,
                   pk_sysdomain.get_domain('NURSE_TEA_REQ.FLG_STATUS', ntr.flg_status, i_lang) desc_status,
                   pk_patient_education_db.get_desc_topic(i_lang,
                                                          i_prof,
                                                          ntr.id_nurse_tea_topic,
                                                          ntr.desc_topic_aux,
                                                          ntt.code_nurse_tea_topic) title_topic,
                   pk_patient_education_db.get_instructions(i_lang, i_prof, ntr.id_nurse_tea_req) instructions,
                   ntr.notes_req notes,
                   pk_date_utils.date_char_tsz(i_lang, ntr.dt_begin_tstz, i_prof.institution, i_prof.software) start_date,
                   pk_patient_education_db.get_pat_educ_add_resources(i_lang, i_prof, ntr.id_nurse_tea_req) add_resources
              FROM nurse_tea_req ntr
              JOIN nurse_tea_topic ntt
                ON ntt.id_nurse_tea_topic = ntr.id_nurse_tea_topic
             WHERE ntr.id_nurse_tea_req = i_nurse_tea_req;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAT_EDUCATION_INFO',
                                              o_error);
            RETURN FALSE;
    END get_pat_education_info;

    FUNCTION get_instructions
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE
    ) RETURN VARCHAR2 IS
        l_tbp    VARCHAR2(4000);
        l_start  VARCHAR2(4000);
        l_ret    VARCHAR2(4000);
        l_void   VARCHAR2(3) := '---';
        l_format VARCHAR2(5) := 'TSE';
        l_end    VARCHAR2(4000);
    
        -- Data structures related with error handling
        l_error t_error_out;
    
        PROCEDURE add_to_ret
        (
            i_add      IN VARCHAR2,
            i_original IN OUT VARCHAR2
        ) IS
        BEGIN
            IF i_original IS NULL
            THEN
                i_original := i_add;
            ELSE
                i_original := i_original || '; ' || nvl(i_add, l_void);
            END IF;
        END add_to_ret;
    
    BEGIN
    
        g_error := 'GET DATA';
        SELECT decode(ntr.flg_time,
                      NULL,
                      NULL,
                      pk_message.get_message(i_lang, 'PATIENT_EDUCATION_T040') || ' ' ||
                      pk_sysdomain.get_domain('NURSE_TEA_REQ.FLG_TIME', ntr.flg_time, i_lang)),
               decode(ntr.dt_begin_tstz,
                      NULL,
                      NULL,
                      pk_message.get_message(i_lang, 'PATIENT_EDUCATION_T042') || ' ' ||
                      pk_date_utils.date_char_tsz(i_lang, ntr.dt_begin_tstz, i_prof.institution, i_prof.software)),
               decode(ntr.id_order_recurr_plan,
                      NULL,
                      pk_translation.get_translation(i_lang, 'ORDER_RECURR_OPTION.CODE_ORDER_RECURR_OPTION.0'),
                      pk_order_recurrence_api_db.get_order_recurr_plan_desc(i_lang, i_prof, ntr.id_order_recurr_plan))
          INTO l_tbp, l_start, l_end
          FROM nurse_tea_req ntr
         WHERE ntr.id_nurse_tea_req = i_nurse_tea_req;
    
        FOR i IN 1 .. length(l_format)
        LOOP
            CASE substr(l_format, i, 1)
                WHEN 'T' THEN
                    add_to_ret(l_tbp, l_ret);
                WHEN 'S' THEN
                    add_to_ret(l_start, l_ret);
                WHEN 'E' THEN
                    add_to_ret(l_end, l_ret);
                ELSE
                    NULL;
            END CASE;
        END LOOP;
    
        RETURN l_ret;
    
    END get_instructions;

    FUNCTION get_desc_topic
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_nurse_tea_topic   IN nurse_tea_req.id_nurse_tea_topic%TYPE,
        i_desc_topic_aux       IN nurse_tea_req.desc_topic_aux%TYPE,
        i_code_nurse_tea_topic IN nurse_tea_topic.code_nurse_tea_topic%TYPE
        
    ) RETURN nurse_tea_req.desc_topic_aux%TYPE IS
    
        l_title_topic nurse_tea_req.desc_topic_aux%TYPE;
    
    BEGIN
        CASE
            WHEN i_id_nurse_tea_topic = 1
                 AND i_desc_topic_aux IS NOT NULL THEN
                l_title_topic := i_desc_topic_aux;
            ELSE
                l_title_topic := pk_translation.get_translation(i_lang, i_code_nurse_tea_topic);
        END CASE;
    
        RETURN l_title_topic;
    
    END get_desc_topic;

    FUNCTION get_last_execution
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE,
        i_flg_status    IN nurse_tea_req.flg_status%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
    
        l_dt_last_exec TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
    
        g_error := 'SELECT - EDUCATION';
        SELECT MAX(ntd.dt_end)
          INTO l_dt_last_exec
          FROM nurse_tea_det ntd
         INNER JOIN nurse_tea_req ntr
            ON ntr.id_nurse_tea_req = ntd.id_nurse_tea_req
         WHERE ntr.id_nurse_tea_req = i_nurse_tea_req
           AND ntr.flg_status = i_flg_status;
    
        RETURN l_dt_last_exec;
    
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END get_last_execution;

    FUNCTION get_pat_education_end_date
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_order_recurr_plan IN nurse_tea_req.id_order_recurr_plan%TYPE
    ) RETURN VARCHAR2 IS
    
        l_order_recurr_desc   VARCHAR2(1000);
        l_order_recurr_option order_recurr_plan.id_order_recurr_option%TYPE;
        l_start_date_tstz     order_recurr_plan.start_date%TYPE;
        l_occurrences         order_recurr_plan.occurrences%TYPE;
        l_duration            order_recurr_plan.duration%TYPE;
        l_unit_meas_duration  order_recurr_plan.id_unit_meas_duration%TYPE;
        l_end_date_tstz       order_recurr_plan.end_date%TYPE := NULL;
        l_flg_end_by_editable VARCHAR2(10);
    
        l_error t_error_out;
    BEGIN
    
        IF i_id_order_recurr_plan IS NOT NULL
        THEN
            IF NOT pk_order_recurrence_core.get_order_recurr_instructions(i_lang                => i_lang,
                                                                          i_prof                => i_prof,
                                                                          i_order_plan          => i_id_order_recurr_plan,
                                                                          o_order_recurr_desc   => l_order_recurr_desc,
                                                                          o_order_recurr_option => l_order_recurr_option,
                                                                          o_start_date          => l_start_date_tstz,
                                                                          o_occurrences         => l_occurrences,
                                                                          o_duration            => l_duration,
                                                                          o_unit_meas_duration  => l_unit_meas_duration,
                                                                          o_end_date            => l_end_date_tstz,
                                                                          o_flg_end_by_editable => l_flg_end_by_editable,
                                                                          o_error               => l_error)
            THEN
                g_error := 'error found while calling pk_order_recurrence_core.get_order_recurr_instructions function';
                RAISE g_exception;
            END IF;
        END IF;
    
        RETURN l_end_date_tstz;
    
    END get_pat_education_end_date;

    FUNCTION tf_get_order_detail
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE
    ) RETURN t_tbl_health_education_order IS
    
        l_ret t_tbl_health_education_order := t_tbl_health_education_order();
    BEGIN
    
        SELECT t_health_education_order(id_nurse_tea_req    => t.id_nurse_tea_req,
                                        action              => t.action,
                                        subject             => t.subject,
                                        topic               => t.topic,
                                        clinical_indication => t.clinical_indication,
                                        to_execute          => t.to_execute,
                                        frequency           => t.frequency,
                                        start_date          => t.start_date,
                                        order_notes         => t.order_notes,
                                        description         => t.description,
                                        status              => t.status,
                                        registry            => t.registry,
                                        end_date            => t.end_date)
          BULK COLLECT
          INTO l_ret
          FROM (SELECT ntr.id_nurse_tea_req,
                       'ORDER' action,
                       pk_translation.get_translation(i_lang, nts.code_nurse_tea_subject) subject,
                       pk_patient_education_db.get_desc_topic(i_lang,
                                                              i_prof,
                                                              ntr.id_nurse_tea_topic,
                                                              ntr.desc_topic_aux,
                                                              ntt.code_nurse_tea_topic) topic,
                       pk_patient_education_ux.get_diagnosis(i_lang, i_prof, ntr.id_nurse_tea_req) clinical_indication,
                       pk_sysdomain.get_domain(pk_patient_education_ux.g_sys_domain_flg_time, ntr.flg_time, i_lang) to_execute,
                       nvl(pk_order_recurrence_api_db.get_order_recurr_plan_desc(i_lang,
                                                                                 i_prof,
                                                                                 ntr.id_order_recurr_plan,
                                                                                 pk_alert_constant.g_no),
                           pk_translation.get_translation(i_lang, 'ORDER_RECURR_OPTION.CODE_ORDER_RECURR_OPTION.0')) frequency,
                       pk_date_utils.date_char_tsz(i_lang, ntr.dt_begin_tstz, i_prof.institution, i_prof.software) start_date,
                       pk_date_utils.date_char_tsz(i_lang,
                                                   (pk_patient_education_db.get_pat_education_end_date(i_lang,
                                                                                                       i_prof,
                                                                                                       ntr.id_order_recurr_plan)),
                                                   i_prof.institution,
                                                   i_prof.software) end_date,
                       ntr.notes_req order_notes,
                       ntr.description description,
                       pk_message.get_message(i_lang,
                                               CASE
                                                   WHEN ntr.flg_status = g_nurse_tea_req_fin THEN
                                                    'PATIENT_EDUCATION_M038'
                                                   WHEN ntr.flg_status = g_nurse_tea_req_pend THEN
                                                    CASE
                                                        WHEN ntr.flg_time = pk_patient_education_ux.g_flg_time_next THEN
                                                         'PATIENT_EDUCATION_M036'
                                                        WHEN ntr.dt_begin_tstz > g_sysdate_tstz THEN
                                                         'PATIENT_EDUCATION_M036'
                                                        ELSE
                                                         'PATIENT_EDUCATION_M043'
                                                    END
                                                   WHEN ntr.flg_status = g_nurse_tea_req_act THEN
                                                    'PATIENT_EDUCATION_M037'
                                                   WHEN ntr.flg_status = g_nurse_tea_req_canc THEN
                                                    'PATIENT_EDUCATION_M027'
                                               END) status,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, ntr.id_prof_req) ||
                       decode(pk_prof_utils.get_spec_signature(i_lang,
                                                               i_prof,
                                                               ntr.id_prof_req,
                                                               ntr.dt_nurse_tea_req_tstz,
                                                               ntr.id_episode),
                              NULL,
                              '; ',
                              ' (' || pk_prof_utils.get_spec_signature(i_lang,
                                                                       i_prof,
                                                                       ntr.id_prof_req,
                                                                       ntr.dt_nurse_tea_req_tstz,
                                                                       ntr.id_episode) || '); ') ||
                       pk_date_utils.date_char_tsz(i_lang,
                                                   ntr.dt_nurse_tea_req_tstz,
                                                   i_prof.institution,
                                                   i_prof.software) registry
                  FROM nurse_tea_req ntr
                  JOIN nurse_tea_topic ntt
                    ON ntt.id_nurse_tea_topic = ntr.id_nurse_tea_topic
                  JOIN nurse_tea_subject nts
                    ON nts.id_nurse_tea_subject = ntt.id_nurse_tea_subject
                 WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req) t;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN t_tbl_health_education_order();
    END tf_get_order_detail;

    FUNCTION tf_get_order_detail_hist
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE
    ) RETURN t_tbl_health_education_order_hist IS
    
        l_msg_del sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'COMMON_M106');
    
        l_ret t_tbl_health_education_order_hist := t_tbl_health_education_order_hist();
    BEGIN
    
        SELECT t_health_education_order_hist(id_nurse_tea_req_hist   => tt.id_nurse_tea_req_hist,
                                             action                  => tt.action,
                                             subject                 => decode(tt.cnt,
                                                                               tt.rn,
                                                                               decode(tt.subject, NULL, NULL, tt.subject),
                                                                               NULL),
                                             topic                   => decode(tt.cnt,
                                                                               tt.rn,
                                                                               decode(tt.topic, NULL, NULL, tt.topic),
                                                                               NULL),
                                             clinical_indication     => decode(tt.cnt,
                                                                               tt.rn,
                                                                               decode(tt.clinical_indication,
                                                                                      NULL,
                                                                                      NULL,
                                                                                      tt.clinical_indication),
                                                                               decode(tt.clinical_indication,
                                                                                      tt.clinical_indication_old,
                                                                                      NULL,
                                                                                      decode(tt.clinical_indication_old,
                                                                                             NULL,
                                                                                             NULL,
                                                                                             tt.clinical_indication_old))),
                                             clinical_indication_new => decode(tt.clinical_indication,
                                                                               tt.clinical_indication_old,
                                                                               NULL,
                                                                               NULL,
                                                                               l_msg_del,
                                                                               tt.clinical_indication),
                                             to_execute              => decode(tt.cnt,
                                                                               tt.rn,
                                                                               decode(tt.to_execute,
                                                                                      NULL,
                                                                                      NULL,
                                                                                      tt.to_execute),
                                                                               decode(tt.to_execute,
                                                                                      tt.to_execute_old,
                                                                                      NULL,
                                                                                      decode(tt.to_execute_old,
                                                                                             NULL,
                                                                                             NULL,
                                                                                             tt.to_execute_old))),
                                             to_execute_new          => decode(tt.to_execute,
                                                                               tt.to_execute_old,
                                                                               NULL,
                                                                               NULL,
                                                                               l_msg_del,
                                                                               tt.to_execute),
                                             frequency               => decode(tt.cnt,
                                                                               tt.rn,
                                                                               decode(tt.frequency,
                                                                                      NULL,
                                                                                      NULL,
                                                                                      tt.frequency),
                                                                               decode(tt.frequency,
                                                                                      tt.frequency_old,
                                                                                      NULL,
                                                                                      decode(tt.frequency_old,
                                                                                             NULL,
                                                                                             NULL,
                                                                                             tt.frequency_old))),
                                             frequency_new           => decode(tt.frequency,
                                                                               tt.frequency_old,
                                                                               NULL,
                                                                               NULL,
                                                                               l_msg_del,
                                                                               tt.frequency),
                                             start_date              => decode(tt.cnt,
                                                                               tt.rn,
                                                                               decode(tt.start_date,
                                                                                      NULL,
                                                                                      NULL,
                                                                                      tt.start_date),
                                                                               decode(tt.start_date,
                                                                                      tt.start_date_old,
                                                                                      NULL,
                                                                                      decode(tt.start_date_old,
                                                                                             NULL,
                                                                                             NULL,
                                                                                             tt.start_date_old))),
                                             start_date_new          => decode(tt.start_date,
                                                                               tt.start_date_old,
                                                                               NULL,
                                                                               NULL,
                                                                               l_msg_del,
                                                                               tt.start_date),
                                             order_notes             => decode(tt.cnt,
                                                                               tt.rn,
                                                                               decode(tt.order_notes,
                                                                                      NULL,
                                                                                      NULL,
                                                                                      tt.order_notes),
                                                                               decode(tt.order_notes,
                                                                                      tt.order_notes_old,
                                                                                      NULL,
                                                                                      decode(tt.order_notes_old,
                                                                                             NULL,
                                                                                             NULL,
                                                                                             tt.order_notes_old))),
                                             order_notes_new         => decode(tt.order_notes,
                                                                               tt.order_notes_old,
                                                                               NULL,
                                                                               NULL,
                                                                               l_msg_del,
                                                                               tt.order_notes),
                                             description             => decode(tt.cnt,
                                                                               tt.rn,
                                                                               decode(tt.description,
                                                                                      NULL,
                                                                                      NULL,
                                                                                      tt.description),
                                                                               decode(tt.description,
                                                                                      tt.description_old,
                                                                                      NULL,
                                                                                      decode(tt.description_old,
                                                                                             NULL,
                                                                                             NULL,
                                                                                             tt.description_old))),
                                             description_new         => decode(tt.description,
                                                                               tt.description_old,
                                                                               NULL,
                                                                               NULL,
                                                                               l_msg_del,
                                                                               tt.description),
                                             status                  => decode(tt.cnt,
                                                                               tt.rn,
                                                                               decode(tt.status, NULL, NULL, tt.status),
                                                                               decode(decode(tt.rn,
                                                                                             1,
                                                                                             tt.status_current,
                                                                                             tt.status),
                                                                                      tt.status_old,
                                                                                      NULL,
                                                                                      decode(tt.status_old,
                                                                                             NULL,
                                                                                             NULL,
                                                                                             tt.status_old))),
                                             status_new              => decode(decode(tt.rn,
                                                                                      1,
                                                                                      tt.status_current,
                                                                                      tt.status),
                                                                               tt.status_old,
                                                                               NULL,
                                                                               NULL,
                                                                               l_msg_del,
                                                                               decode(tt.rn,
                                                                                      1,
                                                                                      tt.status_current,
                                                                                      tt.status)),
                                             registry                => tt.registry,
                                             white_line              => NULL,
                                             end_date                => decode(tt.cnt,
                                                                               tt.rn,
                                                                               decode(tt.end_date, NULL, NULL, tt.end_date),
                                                                               decode(tt.end_date,
                                                                                      tt.end_date_old,
                                                                                      NULL,
                                                                                      decode(tt.end_date_old,
                                                                                             NULL,
                                                                                             NULL,
                                                                                             tt.end_date_old))),
                                             end_date_new            => decode(tt.end_date,
                                                                               tt.end_date_old,
                                                                               NULL,
                                                                               NULL,
                                                                               l_msg_del,
                                                                               tt.end_date))
          BULK COLLECT
          INTO l_ret
          FROM (SELECT row_number() over(ORDER BY t.dt_nurse_tea_req_hist_tstz DESC) rn,
                       MAX(rownum) over() cnt,
                       t.id_nurse_tea_req_hist,
                       t.action,
                       t.subject,
                       t.topic,
                       t.clinical_indication,
                       first_value(t.clinical_indication) over(ORDER BY t.dt_nurse_tea_req_hist_tstz rows BETWEEN 1 preceding AND CURRENT ROW) clinical_indication_old,
                       pk_sysdomain.get_domain(pk_patient_education_ux.g_sys_domain_flg_time, t.flg_time, i_lang) to_execute,
                       pk_sysdomain.get_domain(pk_patient_education_ux.g_sys_domain_flg_time, t.flg_time_old, i_lang) to_execute_old,
                       nvl(pk_order_recurrence_api_db.get_order_recurr_plan_desc(i_lang,
                                                                                 i_prof,
                                                                                 t.id_order_recurr_plan,
                                                                                 pk_alert_constant.g_no),
                           pk_translation.get_translation(i_lang, 'ORDER_RECURR_OPTION.CODE_ORDER_RECURR_OPTION.0')) frequency,
                       nvl(pk_order_recurrence_api_db.get_order_recurr_plan_desc(i_lang,
                                                                                 i_prof,
                                                                                 t.id_order_recurr_plan_old,
                                                                                 pk_alert_constant.g_no),
                           pk_translation.get_translation(i_lang, 'ORDER_RECURR_OPTION.CODE_ORDER_RECURR_OPTION.0')) frequency_old,
                       pk_date_utils.date_char_tsz(i_lang, t.dt_begin_tstz, i_prof.institution, i_prof.software) start_date,
                       pk_date_utils.date_char_tsz(i_lang, t.dt_begin_tstz_old, i_prof.institution, i_prof.software) start_date_old,
                       pk_date_utils.date_char_tsz(i_lang, t.dt_end_tstz, i_prof.institution, i_prof.software) end_date,
                       pk_date_utils.date_char_tsz(i_lang, t.dt_end_tstz_old, i_prof.institution, i_prof.software) end_date_old,
                       t.order_notes,
                       t.order_notes_old,
                       t.description,
                       t.description_old,
                       pk_message.get_message(i_lang,
                                               CASE
                                                   WHEN t.flg_status = g_nurse_tea_req_fin THEN
                                                    'PATIENT_EDUCATION_M038'
                                                   WHEN t.flg_status = g_nurse_tea_req_pend THEN
                                                    CASE
                                                        WHEN t.flg_time = pk_patient_education_ux.g_flg_time_next THEN
                                                         'PATIENT_EDUCATION_M036'
                                                        WHEN t.dt_begin_tstz > g_sysdate_tstz THEN
                                                         'PATIENT_EDUCATION_M036'
                                                        ELSE
                                                         'PATIENT_EDUCATION_M043'
                                                    END
                                                   WHEN t.flg_status = g_nurse_tea_req_act THEN
                                                    'PATIENT_EDUCATION_M037'
                                                   WHEN t.flg_status = g_nurse_tea_req_canc THEN
                                                    'DETAIL_COMMON_M003'
                                               END) status,
                       pk_message.get_message(i_lang,
                                               CASE
                                                   WHEN t.flg_status_old = g_nurse_tea_req_fin THEN
                                                    'PATIENT_EDUCATION_M038'
                                                   WHEN t.flg_status_old = g_nurse_tea_req_pend THEN
                                                    CASE
                                                        WHEN t.flg_status_old = pk_patient_education_ux.g_flg_time_next THEN
                                                         'PATIENT_EDUCATION_M036'
                                                        WHEN t.dt_begin_tstz_old > g_sysdate_tstz THEN
                                                         'PATIENT_EDUCATION_M036'
                                                        ELSE
                                                         'PATIENT_EDUCATION_M043'
                                                    END
                                                   WHEN t.flg_status_old = g_nurse_tea_req_act THEN
                                                    'PATIENT_EDUCATION_M037'
                                                   WHEN t.flg_status_old = g_nurse_tea_req_canc THEN
                                                    'DETAIL_COMMON_M003'
                                               END) status_old,
                       pk_message.get_message(i_lang,
                                               CASE
                                                   WHEN t.flg_status_current = g_nurse_tea_req_fin THEN
                                                    'PATIENT_EDUCATION_M038'
                                                   WHEN t.flg_status_current = g_nurse_tea_req_pend THEN
                                                    CASE
                                                        WHEN t.flg_status_current = pk_patient_education_ux.g_flg_time_next THEN
                                                         'PATIENT_EDUCATION_M036'
                                                        WHEN t.dt_begin_tstz_old > g_sysdate_tstz THEN
                                                         'PATIENT_EDUCATION_M036'
                                                        ELSE
                                                         'PATIENT_EDUCATION_M043'
                                                    END
                                                   WHEN t.flg_status_current = g_nurse_tea_req_act THEN
                                                    'PATIENT_EDUCATION_M037'
                                                   WHEN t.flg_status_current = g_nurse_tea_req_canc THEN
                                                    'DETAIL_COMMON_M003'
                                               END) status_current,
                       t.registry
                  FROM (SELECT ntrh.id_nurse_tea_req_hist,
                               'ORDER' action,
                               pk_translation.get_translation(i_lang, nts.code_nurse_tea_subject) subject,
                               pk_patient_education_db.get_desc_topic(i_lang,
                                                                      i_prof,
                                                                      ntr.id_nurse_tea_topic,
                                                                      ntr.desc_topic_aux,
                                                                      ntt.code_nurse_tea_topic) topic,
                               pk_patient_education_ux.get_diagnosis_hist(i_lang, i_prof, ntrh.id_nurse_tea_req_hist) clinical_indication,
                               ntrh.flg_time,
                               first_value(ntrh.flg_time) over(ORDER BY ntrh.dt_nurse_tea_req_hist_tstz rows BETWEEN 1 preceding AND CURRENT ROW) flg_time_old,
                               ntrh.id_order_recurr_plan,
                               first_value(ntrh.id_order_recurr_plan) over(ORDER BY ntrh.dt_nurse_tea_req_hist_tstz rows BETWEEN 1 preceding AND CURRENT ROW) id_order_recurr_plan_old,
                               ntrh.dt_begin_tstz,
                               first_value(ntrh.dt_begin_tstz) over(ORDER BY ntrh.dt_nurse_tea_req_hist_tstz rows BETWEEN 1 preceding AND CURRENT ROW) dt_begin_tstz_old,
                               pk_patient_education_db.get_pat_education_end_date(i_lang,
                                                                                  i_prof,
                                                                                  ntrh.id_order_recurr_plan) dt_end_tstz,
                               first_value(pk_patient_education_db.get_pat_education_end_date(i_lang,
                                                                                              i_prof,
                                                                                              ntrh.id_order_recurr_plan)) over(ORDER BY ntrh.dt_nurse_tea_req_hist_tstz rows BETWEEN 1 preceding AND CURRENT ROW) dt_end_tstz_old,
                               dbms_lob.substr(ntrh.notes_req, 3990) order_notes,
                               first_value(dbms_lob.substr(ntrh.notes_req, 3990)) over(ORDER BY ntrh.dt_nurse_tea_req_hist_tstz rows BETWEEN 1 preceding AND CURRENT ROW) order_notes_old,
                               dbms_lob.substr(ntrh.description, 3990) description,
                               first_value(dbms_lob.substr(ntrh.description, 3990)) over(ORDER BY ntrh.dt_nurse_tea_req_hist_tstz rows BETWEEN 1 preceding AND CURRENT ROW) description_old,
                               ntrh.flg_status,
                               first_value(ntrh.flg_status) over(ORDER BY ntrh.dt_nurse_tea_req_hist_tstz rows BETWEEN 1 preceding AND CURRENT ROW) flg_status_old,
                               ntr.flg_status flg_status_current,
                               ntrh.dt_nurse_tea_req_hist_tstz,
                               pk_prof_utils.get_name_signature(i_lang, i_prof, ntrh.id_prof_req) ||
                               decode(pk_prof_utils.get_spec_signature(i_lang,
                                                                       i_prof,
                                                                       ntrh.id_prof_req,
                                                                       ntrh.dt_nurse_tea_req_tstz,
                                                                       ntrh.id_episode),
                                      NULL,
                                      '; ',
                                      ' (' || pk_prof_utils.get_spec_signature(i_lang,
                                                                               i_prof,
                                                                               ntrh.id_prof_req,
                                                                               ntrh.dt_nurse_tea_req_tstz,
                                                                               ntrh.id_episode) || '); ') ||
                               pk_date_utils.date_char_tsz(i_lang,
                                                           ntrh.dt_nurse_tea_req_tstz,
                                                           i_prof.institution,
                                                           i_prof.software) registry
                          FROM nurse_tea_req_hist ntrh
                          JOIN nurse_tea_req ntr
                            ON ntr.id_nurse_tea_req = ntrh.id_nurse_tea_req
                          JOIN nurse_tea_topic ntt
                            ON ntt.id_nurse_tea_topic = ntrh.id_nurse_tea_topic
                          JOIN nurse_tea_subject nts
                            ON nts.id_nurse_tea_subject = ntt.id_nurse_tea_subject
                         WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
                           AND ntrh.flg_status IN (g_nurse_tea_req_pend, g_nurse_tea_req_canc, g_nurse_tea_req_act)) t) tt;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN t_tbl_health_education_order_hist();
    END tf_get_order_detail_hist;

    FUNCTION tf_get_execution_detail
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE
    ) RETURN t_tbl_health_education_exec IS
    
        l_ret t_tbl_health_education_exec := t_tbl_health_education_exec();
    BEGIN
        SELECT t_health_education_exec(id_nurse_tea_req    => t.id_nurse_tea_req,
                                       id_nurse_tea_det    => t.id_nurse_tea_det,
                                       action              => t.action,
                                       clinical_indication => t.clinical_indication,
                                       goals               => t.goals,
                                       method              => t.method,
                                       given_to            => t.given_to,
                                       deliverables        => t.deliverables,
                                       understanding       => t.understanding,
                                       start_date          => t.start_date,
                                       duration            => t.duration,
                                       end_date            => t.end_date,
                                       description         => t.description,
                                       status              => t.status,
                                       registry            => t.registry,
                                       white_line          => NULL)
          BULK COLLECT
          INTO l_ret
          FROM (SELECT ntr.id_nurse_tea_req,
                       ntd.id_nurse_tea_det,
                       'EXECUTION' action,
                       pk_patient_education_ux.get_diagnosis(i_lang, i_prof, ntr.id_nurse_tea_req) clinical_indication,
                       (SELECT nvl(pk_translation.get_translation(i_lang, nto.code_nurse_tea_opt), ntdo.notes)
                          FROM nurse_tea_det_opt ntdo
                          LEFT JOIN nurse_tea_opt nto
                            ON nto.id_nurse_tea_opt = ntdo.id_nurse_tea_opt
                         WHERE ntdo.id_nurse_tea_det = ntd.id_nurse_tea_det
                           AND ntdo.subject = 'GOALS') goals,
                       (SELECT nvl(pk_translation.get_translation(i_lang, nto.code_nurse_tea_opt), ntdo.notes)
                          FROM nurse_tea_det_opt ntdo
                          LEFT JOIN nurse_tea_opt nto
                            ON nto.id_nurse_tea_opt = ntdo.id_nurse_tea_opt
                         WHERE ntdo.id_nurse_tea_det = ntd.id_nurse_tea_det
                           AND ntdo.subject = 'METHOD') method,
                       (SELECT nvl(pk_translation.get_translation(i_lang, nto.code_nurse_tea_opt), ntdo.notes)
                          FROM nurse_tea_det_opt ntdo
                          LEFT JOIN nurse_tea_opt nto
                            ON nto.id_nurse_tea_opt = ntdo.id_nurse_tea_opt
                         WHERE ntdo.id_nurse_tea_det = ntd.id_nurse_tea_det
                           AND ntdo.subject = 'GIVEN_TO') given_to,
                       (SELECT nvl(pk_translation.get_translation(i_lang, nto.code_nurse_tea_opt), ntdo.notes)
                          FROM nurse_tea_det_opt ntdo
                          LEFT JOIN nurse_tea_opt nto
                            ON nto.id_nurse_tea_opt = ntdo.id_nurse_tea_opt
                         WHERE ntdo.id_nurse_tea_det = ntd.id_nurse_tea_det
                           AND ntdo.subject = 'DELIVERABLES') deliverables,
                       (SELECT nvl(pk_translation.get_translation(i_lang, nto.code_nurse_tea_opt), ntdo.notes)
                          FROM nurse_tea_det_opt ntdo
                          LEFT JOIN nurse_tea_opt nto
                            ON nto.id_nurse_tea_opt = ntdo.id_nurse_tea_opt
                         WHERE ntdo.id_nurse_tea_det = ntd.id_nurse_tea_det
                           AND ntdo.subject = 'LEVEL_OF_UNDERSTANDING') understanding,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, ntd.dt_start, i_prof) start_date,
                       nvl2(ntd.duration,
                            ntd.duration || ' ' ||
                            pk_unit_measure.get_unit_measure_description(i_lang, i_prof, ntd.id_unit_meas_duration),
                            NULL) duration,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, ntd.dt_end, i_prof) end_date,
                       ntd.description,
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
                                 OR ntr.flg_status = g_nurse_tea_req_act THEN
                             pk_message.get_message(i_lang,
                                                    CASE ntr.flg_status
                                                        WHEN pk_patient_education_ux.g_nurse_tea_req_fin THEN
                                                         'PATIENT_EDUCATION_M038'
                                                        WHEN g_nurse_tea_req_pend THEN
                                                         CASE
                                                             WHEN ntr.flg_time = pk_patient_education_ux.g_flg_time_next THEN
                                                              'PATIENT_EDUCATION_M036'
                                                             WHEN ntr.dt_begin_tstz > g_sysdate_tstz THEN
                                                              'PATIENT_EDUCATION_M036'
                                                             ELSE
                                                              'PATIENT_EDUCATION_M043'
                                                         END
                                                        WHEN g_nurse_tea_req_act THEN
                                                         'PATIENT_EDUCATION_M044'
                                                        ELSE
                                                         NULL
                                                    END)
                            ELSE
                             NULL
                        END status,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, ntd.id_prof_provider) ||
                       decode(pk_prof_utils.get_spec_signature(i_lang,
                                                               i_prof,
                                                               ntd.id_prof_provider,
                                                               ntd.dt_nurse_tea_det_tstz,
                                                               ntr.id_episode),
                              NULL,
                              '; ',
                              ' (' || pk_prof_utils.get_spec_signature(i_lang,
                                                                       i_prof,
                                                                       ntd.id_prof_provider,
                                                                       ntd.dt_nurse_tea_det_tstz,
                                                                       ntr.id_episode) || '); ') ||
                       pk_date_utils.date_char_tsz(i_lang,
                                                   ntd.dt_nurse_tea_det_tstz,
                                                   i_prof.institution,
                                                   i_prof.software) registry
                  FROM nurse_tea_det ntd
                  JOIN nurse_tea_req ntr
                    ON ntr.id_nurse_tea_req = ntd.id_nurse_tea_req
                 WHERE ntd.id_nurse_tea_req = i_id_nurse_tea_req
                   AND ntd.flg_status = pk_patient_education_ux.g_nurse_tea_det_exec
                 ORDER BY ntd.num_order DESC) t;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN t_tbl_health_education_exec();
    END tf_get_execution_detail;

    FUNCTION tf_get_cancel_detail
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE
    ) RETURN t_tbl_health_education_cancel IS
    
        l_ret t_tbl_health_education_cancel := t_tbl_health_education_cancel();
    BEGIN
    
        SELECT t_health_education_cancel(id_nurse_tea_req => t.id_nurse_tea_req,
                                         action           => t.action,
                                         cancel_reason    => t.cancel_reason,
                                         cancel_notes     => t.cancel_notes,
                                         registry         => t.registry,
                                         white_line       => NULL)
          BULK COLLECT
          INTO l_ret
          FROM (SELECT ntr.id_nurse_tea_req,
                       'CANCELLATION' action,
                       pk_translation.get_translation(i_lang, cr.code_cancel_reason) cancel_reason,
                       ntr.notes_close cancel_notes,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, ntr.id_prof_close) ||
                       decode(pk_prof_utils.get_spec_signature(i_lang,
                                                               i_prof,
                                                               ntr.id_prof_close,
                                                               ntr.dt_close_tstz,
                                                               ntr.id_episode),
                              NULL,
                              '; ',
                              ' (' || pk_prof_utils.get_spec_signature(i_lang,
                                                                       i_prof,
                                                                       ntr.id_prof_close,
                                                                       ntr.dt_close_tstz,
                                                                       ntr.id_episode) || '); ') ||
                       pk_date_utils.date_char_tsz(i_lang, ntr.dt_close_tstz, i_prof.institution, i_prof.software) registry
                  FROM nurse_tea_req ntr
                  JOIN cancel_reason cr
                    ON cr.id_cancel_reason = ntr.id_cancel_reason
                 WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req
                   AND ntr.flg_status = pk_patient_education_ux.g_nurse_tea_req_canc) t;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN t_tbl_health_education_cancel();
    END tf_get_cancel_detail;
BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_patient_education_db;
/
