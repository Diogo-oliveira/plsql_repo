/*-- Last Change Revision: $Rev: 1965628 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2020-10-09 09:22:44 +0100 (sex, 09 out 2020) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_rcm_out IS

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    g_retval BOOLEAN;
    g_exception_np EXCEPTION;
    g_exception    EXCEPTION;
    g_ids_software sys_config.value%TYPE;

    /**
    * Inserts new patient recommendations (batch process)
    *
    * @param   i_lang                     Professional preferred language
    * @param   i_prof                     Professional identifier and its context (institution and software)
    * @param   i_id_patient_tab           Array of patient identifiers
    * @param   i_id_episode_tab           Array of episode identifiers
    * @param   i_id_rcm                   Recommendation identifier
    * @param   i_id_rcm_orig              Origin recommendation identifier
    * @param   i_id_rcm_orig_value        Origin recommendation value (cdr_instance when origin=CDS)
    * @param   i_rcm_text_tab             Array of Recommendation texts
    * @param   i_rcm_notes_tab            Array of recommendation notes
    * @param   o_id_pat_rcm_tab           Array of recommendation details identifier
    * @param   o_error                    Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   08-02-2012
    */
    FUNCTION create_pat_rcm
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_patient_tab    IN table_number,
        i_id_episode_tab    IN table_number,
        i_id_rcm            IN pat_rcm_det.id_rcm%TYPE,
        i_id_rcm_orig       IN pat_rcm_det.id_rcm_orig%TYPE,
        i_id_rcm_orig_value IN pat_rcm_det.id_rcm_orig_value%TYPE,
        i_rcm_notes_tab     IN table_varchar,
        i_rcm_text_tab      IN table_clob,
        o_id_rcm_det_tab    OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT pk_rcm_constant.t_low_char := 'CREATE_PAT_RCM';
        l_flg_show  VARCHAR2(1 CHAR);
        l_msg_title VARCHAR2(1000 CHAR);
        l_msg       VARCHAR2(1000 CHAR);
        l_button    VARCHAR2(10 CHAR);
    BEGIN
        g_error := 'Init ' || l_func_name || ' / i_id_rcm=' || i_id_rcm || ' i_id_rcm_orig=' || i_id_rcm_orig ||
                   ' i_id_rcm_orig_value=' || i_id_rcm_orig_value;
    
        -- create a patient recommendation
        g_error  := l_func_name || ' Call pk_rcm_core.create_pat_rcm / ID_RCM=' || i_id_rcm || ' ID_RCM_ORIG=' ||
                    i_id_rcm_orig || ' ID_RCM_ORIG_VALUE=' || i_id_rcm_orig_value;
        g_retval := pk_rcm_core.create_pat_rcm(i_lang              => i_lang,
                                               i_prof              => i_prof,
                                               i_id_patient_tab    => i_id_patient_tab,
                                               i_id_episode_tab    => i_id_episode_tab,
                                               i_id_rcm            => i_id_rcm,
                                               i_id_rcm_orig       => i_id_rcm_orig,
                                               i_id_rcm_orig_value => i_id_rcm_orig_value,
                                               i_rcm_text_tab      => i_rcm_text_tab,
                                               i_rcm_notes_tab     => i_rcm_notes_tab,
                                               o_id_rcm_det_tab    => o_id_rcm_det_tab,
                                               o_flg_show          => l_flg_show,
                                               o_msg_title         => l_msg_title,
                                               o_msg               => l_msg,
                                               o_button            => l_button,
                                               o_error             => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END create_pat_rcm;

    /**
    * Inserts new patient clinical recommendations (batch process)
    *
    * @param   i_lang                     Professional preferred language
    * @param   i_prof                     Professional identifier and its context (institution and software)
    * @param   i_id_patient               Patient identifier
    * @param   i_id_episode               Episode identifier
    * @param   i_id_rcm_tab               Array of recommendation identifiers
    * @param   i_rcm_text_tab             Array of text recommendation text   
    * @param   i_id_rcm_orig_value        Origin value to be stored in rcm module
    * @param   o_id_rcm_det_tab           Array of recommendation details identifier    
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   03-04-2012
    */
    PROCEDURE create_pat_clin_rcm_cdr
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_patient        IN pat_rcm_det.id_patient%TYPE,
        i_id_episode        IN pat_rcm_h.id_epis_created%TYPE,
        i_id_rcm_tab        IN table_number,
        i_rcm_text_tab      IN table_clob,
        i_id_rcm_orig_value IN pat_rcm_det.id_rcm_orig_value%TYPE,
        o_id_rcm_det_tab    OUT table_number
    ) IS
        l_func_name CONSTANT pk_rcm_constant.t_low_char := 'CREATE_PAT_CLIN_RCM_CDR';
        l_id_rcm_orig     rcm_orig.id_rcm_orig%TYPE;
        l_id_rcm_type_tab table_number;
        l_error           t_error_out;
    BEGIN
        g_error := 'Init ' || l_func_name || ' / i_id_patient=' || i_id_patient || ' i_id_episode=' || i_id_episode ||
                   ' i_id_rcm_orig_value=' || i_id_rcm_orig_value;
    
        -- orig identifier
        l_id_rcm_orig := pk_rcm_constant.g_orig_rcm_cdr;
    
        -- getting rcm type
        g_error  := l_func_name || ': Call pk_rcm_base.get_rcm_type';
        g_retval := pk_rcm_base.get_rcm_type(i_lang            => i_lang,
                                             i_prof            => i_prof,
                                             i_id_rcm_tab      => i_id_rcm_tab,
                                             o_id_rcm_type_tab => l_id_rcm_type_tab,
                                             o_error           => l_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        FOR i IN 1 .. l_id_rcm_type_tab.count
        LOOP
            IF l_id_rcm_type_tab(i) != pk_rcm_constant.g_type_rcm_clin_rcm
            THEN
                g_error := 'ID_RCM=' || l_id_rcm_type_tab(i) || ' is not of type ID_RCM_TYPE=' ||
                           pk_rcm_constant.g_type_rcm_clin_rcm;
                RAISE g_exception;
            END IF;
        END LOOP;
    
        g_error := l_func_name || ': FOR i IN 1 .. ' || i_id_rcm_tab.count || ' LOOP';
        FOR i IN 1 .. i_id_rcm_tab.count
        LOOP
        
            g_error  := l_func_name || ': Call create_pat_rcm / i_id_rcm=' || i_id_rcm_tab(i) || ' l_id_rcm_orig=' ||
                        l_id_rcm_orig || ' i_id_rcm_orig_value=' || i_id_rcm_orig_value;
            g_retval := create_pat_rcm(i_lang              => i_lang,
                                       i_prof              => i_prof,
                                       i_id_patient_tab    => table_number(i_id_patient),
                                       i_id_episode_tab    => table_number(i_id_episode),
                                       i_id_rcm            => i_id_rcm_tab(i),
                                       i_id_rcm_orig       => l_id_rcm_orig,
                                       i_id_rcm_orig_value => i_id_rcm_orig_value,
                                       i_rcm_notes_tab     => NULL,
                                       i_rcm_text_tab      => table_clob(i_rcm_text_tab(i)),
                                       o_id_rcm_det_tab    => o_id_rcm_det_tab,
                                       o_error             => l_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        END LOOP;
    
        -- do not catch exceptions
    END create_pat_clin_rcm_cdr;

    /**
    * Inserts new patient reminders (batch process)
    *
    * @param   i_lang                     Professional preferred language
    * @param   i_prof                     Professional identifier and its context (institution and software)
    * @param   i_id_patient_tab           Array of patient identifiers
    * @param   i_id_episode_tab           Array of episode identifiers
    * @param   i_id_rcm                   Recommendation identifier
    * @param   i_rcm_text_tab             Array of recommendation texts (could be different from patient to patient for the same id_rcm)
    * @param   o_error                    Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   12-04-2012
    */
    FUNCTION create_pat_reminders_rcm
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_patient_tab IN table_number,
        i_id_episode_tab IN table_number,
        i_id_rcm         IN pat_rcm_det.id_rcm%TYPE,
        i_rcm_text_tab   IN table_clob,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT pk_rcm_constant.t_low_char := 'CREATE_PAT_REMINDERS_RCM';
        l_id_rcm_det_tab table_number;
        l_id_rcm_orig    rcm_orig.id_rcm_orig%TYPE;
    BEGIN
        g_error := 'Init ' || l_func_name || ' / i_id_rcm=' || i_id_rcm;
    
        -- orig identifier
        l_id_rcm_orig := pk_rcm_constant.g_orig_rcm_rcm;
    
        -- create a patient recommendation
        g_error  := l_func_name || ': Call pk_rcm_core.create_pat_rcm / ID_RCM=' || i_id_rcm || ' ID_RCM_ORIG=' ||
                    l_id_rcm_orig;
        g_retval := create_pat_rcm(i_lang              => i_lang,
                                   i_prof              => i_prof,
                                   i_id_patient_tab    => i_id_patient_tab,
                                   i_id_episode_tab    => i_id_episode_tab,
                                   i_id_rcm            => i_id_rcm,
                                   i_id_rcm_orig       => l_id_rcm_orig,
                                   i_id_rcm_orig_value => pk_rcm_constant.g_orig_value_noval, -- no value to be stored
                                   i_rcm_notes_tab     => NULL,
                                   i_rcm_text_tab      => i_rcm_text_tab,
                                   o_id_rcm_det_tab    => l_id_rcm_det_tab,
                                   o_error             => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END create_pat_reminders_rcm;

    /**
    * Updates recommendation status
    *
    * @param   i_lang                     Professional preferred language
    * @param   i_prof                     Professional identifier and its context (institution and software)
    * @param   i_id_patient               Patient identifier
    * @param   i_id_episode               Episode identifier
    * @param   i_id_rcm                   Recommendation identifier
    * @param   i_id_rcm_det               Recommendation detail identifier
    * @param   i_id_workflow_action       Workflow action
    * @param   i_id_status_end            Status end
    * @param   i_rcm_notes                Notes related to the status change
    * @param   o_error                    Error information    
    *
    * @return  TRUE if sucess, FALSE otherwise
    *   
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   03-04-2012
    */
    FUNCTION set_pat_rcm_status
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_rcm             IN pat_rcm_det.id_rcm%TYPE,
        i_id_rcm_det         IN pat_rcm_det.id_rcm_det%TYPE,
        i_id_workflow_action IN wf_workflow_action.id_workflow_action%TYPE,
        i_id_status_end      IN pat_rcm_h.id_status%TYPE,
        i_rcm_notes          IN pat_rcm_h.notes%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT pk_rcm_constant.t_low_char := 'SET_PAT_RCM_STATUS';
        l_rcm_data  t_rec_rcm;
        l_flg_show  VARCHAR2(1 CHAR);
        l_msg_title VARCHAR2(1000 CHAR);
        l_msg       VARCHAR2(1000 CHAR);
        l_button    VARCHAR2(10 CHAR);
    BEGIN
        g_error := 'Init ' || l_func_name || ' / i_id_patient=' || i_id_patient || ' i_id_episode=' || i_id_episode;
    
        -- getting rcm most recent data
        g_error    := l_func_name || ': Call pk_rcm_base.get_pat_rcm_data';
        l_rcm_data := pk_rcm_base.get_pat_rcm_data(i_lang       => i_lang,
                                                   i_prof       => i_prof,
                                                   i_id_patient => i_id_patient,
                                                   i_id_rcm     => i_id_rcm,
                                                   i_id_rcm_det => i_id_rcm_det);
    
        -- updates rcm
        g_error  := l_func_name || ': Call pk_rcm_core.set_pat_rcm / i_id_patient=' || i_id_patient || ' i_id_episode=' ||
                    i_id_episode || ' i_id_rcm=' || i_id_rcm || ' i_id_rcm_det=' || i_id_rcm_det || ' i_id_workflow=' ||
                    l_rcm_data.id_workflow || ' i_id_workflow_action=' || i_id_workflow_action || ' i_id_status_begin=' ||
                    l_rcm_data.id_status || ' i_id_status_end=' || i_id_status_end;
        g_retval := pk_rcm_core.set_pat_rcm(i_lang               => i_lang,
                                            i_prof               => i_prof,
                                            i_id_patient         => i_id_patient,
                                            i_id_episode         => i_id_episode,
                                            i_id_rcm             => i_id_rcm,
                                            i_id_rcm_det         => i_id_rcm_det,
                                            i_id_workflow        => l_rcm_data.id_workflow,
                                            i_id_workflow_action => i_id_workflow_action,
                                            i_id_status_begin    => l_rcm_data.id_status,
                                            i_id_status_end      => i_id_status_end,
                                            i_rcm_notes          => i_rcm_notes,
                                            o_flg_show           => l_flg_show,
                                            o_msg_title          => l_msg_title,
                                            o_msg                => l_msg,
                                            o_button             => l_button,
                                            o_error              => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END set_pat_rcm_status;

    ----------------------------------------------------------------
    -- JOBs functions
    ----------------------------------------------------------------
    /**
    * Executes the query (related to the rule instance) and creates patient reminders 
    *
    * @param   i_lang                     Professional preferred language
    * @param   i_prof                     Professional identifier and its context (institution and software)
    * @param   i_id_rcm                   Recommendation identifier
    * @param   i_id_rcm_rule              Rule identifier
    * @param   i_id_rule_inst             Rule instance identifier
    * @param   i_rule_query               Rule query
    * @param   i_id_patient_tab           Array of patient identifiers
    * @param   o_error                    Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   08-02-2012
    */
    FUNCTION process_rule_instance
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_rcm         IN rcm_rule_inst_rcm.id_rcm%TYPE,
        i_id_rcm_rule    IN rcm_rule_inst_rcm.id_rcm_rule%TYPE,
        i_id_rule_inst   IN rcm_rule_inst_rcm.id_rule_inst%TYPE,
        i_rule_query     IN rcm_rule.rule_query%TYPE,
        i_id_patient_tab IN table_number DEFAULT NULL,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT pk_rcm_constant.t_low_char := 'PROCESS_RULE_INSTANCE';
        l_cur_query        pk_types.cursor_type;
        l_id_patient_tab   table_number;
        l_id_rcm_tab       table_number;
        l_id_rule_tab      table_number;
        l_id_rule_inst_tab table_number;
        l_pat_age_tab      table_varchar;
        l_pat_gender_tab   table_varchar;
        l_id_rcm           rcm.id_rcm%TYPE;
        l_rcm_text_tab     table_clob;
        l_id_pat_tab       table_number;
        l_id_epis_tab      table_number;
        l_ids_software     sys_config.value%TYPE;
    BEGIN
        g_error := 'Init ' || l_func_name || ' / i_id_rcm=' || i_id_rcm || ' i_id_rcm_rule=' || i_id_rcm_rule ||
                   ' i_id_rule_inst=' || i_id_rule_inst;
    
        l_ids_software := nvl(g_ids_software,
                              pk_sysconfig.get_config(i_code_cf => pk_rcm_constant.g_sc_id_software, i_prof => i_prof));
    
        -- initializing context vars
        g_error := l_func_name || ': Call pk_rcm_params.init_params';
        pk_rcm_params.init_params(i_lang         => i_lang,
                                  i_prof         => i_prof,
                                  i_context_keys => table_varchar('i_id_rcm',
                                                                  'i_id_rule',
                                                                  'i_id_rule_inst',
                                                                  'l_ids_software'),
                                  i_context_vals => table_varchar(i_id_rcm,
                                                                  i_id_rcm_rule,
                                                                  i_id_rule_inst,
                                                                  l_ids_software));
    
        g_error := l_func_name || ': OPEN l_cur_query FOR i_rule_query';
        OPEN l_cur_query FOR i_rule_query
            USING i_id_patient_tab, i_id_patient_tab;
    
        LOOP
            g_error := l_func_name || ': FETCH l_cur_filter_data BULK COLLECT INTO';
            FETCH l_cur_query BULK COLLECT
                INTO l_id_patient_tab,
                     l_id_rcm_tab,
                     l_id_rule_tab,
                     l_id_rule_inst_tab,
                     l_pat_age_tab,
                     l_pat_gender_tab LIMIT pk_rcm_constant.g_limit;
        
            --pk_alertlog.log_error(i_id_rcm || '|' || i_id_rule_inst || '[' || i_prof.institution || '][' ||
            --                      l_id_rule_tab.count || ']'); -- todo: retirar
        
            IF l_id_rule_tab.count > 0
            THEN
            
                -- cleans previous data
                g_error := l_func_name || ': DELETE FROM tbl_temp / VC_1=' || pk_rcm_constant.g_temp_type_pat;
                DELETE FROM tbl_temp
                 WHERE vc_1 = pk_rcm_constant.g_temp_type_pat;
            
                -- inserts results into temporary table
                g_error := l_func_name || ': INSERT INTO tbl_temp';
                INSERT INTO tbl_temp
                    (vc_1, vc_2, vc_3, num_1, num_2, num_3, num_4)
                    SELECT pk_rcm_constant.g_temp_type_pat,
                           pat_gender_tab.column_value,
                           age_tab.column_value, -- unit and description
                           id_rcm_tab.column_value,
                           id_rule_tab.column_value,
                           id_rule_inst_tab.column_value,
                           id_patient_tab.column_value
                      FROM (SELECT rownum rn, column_value
                              FROM TABLE(CAST(l_pat_age_tab AS table_varchar))) age_tab
                      JOIN (SELECT rownum rn, column_value
                              FROM TABLE(CAST(l_pat_gender_tab AS table_varchar))) pat_gender_tab
                        ON (age_tab.rn = pat_gender_tab.rn)
                      JOIN (SELECT rownum rn, column_value
                              FROM TABLE(CAST(l_id_patient_tab AS table_number))) id_patient_tab
                        ON (age_tab.rn = id_patient_tab.rn)
                      JOIN (SELECT rownum rn, column_value
                              FROM TABLE(CAST(l_id_rcm_tab AS table_number))) id_rcm_tab
                        ON (age_tab.rn = id_rcm_tab.rn)
                      JOIN (SELECT rownum rn, column_value
                              FROM TABLE(CAST(l_id_rule_tab AS table_number))) id_rule_tab
                        ON (age_tab.rn = id_rule_tab.rn)
                      JOIN (SELECT rownum rn, column_value
                              FROM TABLE(CAST(l_id_rule_inst_tab AS table_number))) id_rule_inst_tab
                        ON (age_tab.rn = id_rule_inst_tab.rn);
            
                -- can only have one value
                g_error := l_func_name || ': SELECT DISTINCT column_value';
                SELECT DISTINCT column_value
                  INTO l_id_rcm
                  FROM TABLE(CAST(l_id_rcm_tab AS table_number));
            
                l_id_pat_tab   := NULL;
                l_id_epis_tab  := NULL;
                l_rcm_text_tab := NULL;
            
                -- getting rcm text
                g_error := l_func_name || ': Getting rule text';
                SELECT num_4, -- id_patient
                       pk_rcm_constant.g_epis_epis_undef, -- id_episode undefined in this context
                       pk_rcm_params.get_rule_text(i_lang         => i_lang,
                                                   i_prof         => i_prof,
                                                   i_id_rcm_rule  => num_2,
                                                   i_id_rule_inst => num_3,
                                                   i_id_patient   => num_4) rcm_text
                  BULK COLLECT
                  INTO l_id_pat_tab, l_id_epis_tab, l_rcm_text_tab
                  FROM tbl_temp
                 WHERE vc_1 = pk_rcm_constant.g_temp_type_pat
                   AND num_1 = i_id_rcm
                   AND num_2 = i_id_rcm_rule
                   AND num_3 = i_id_rule_inst;
            
                -- creates the patient reminder
                SAVEPOINT process_rule;
            
                g_error  := l_func_name || ': Call create_pat_reminders_rcm / i_id_rcm=' || l_id_rcm;
                g_retval := create_pat_reminders_rcm(i_lang           => i_lang,
                                                     i_prof           => i_prof,
                                                     i_id_patient_tab => l_id_pat_tab,
                                                     i_id_episode_tab => l_id_epis_tab,
                                                     i_id_rcm         => l_id_rcm,
                                                     i_rcm_text_tab   => l_rcm_text_tab,
                                                     o_error          => o_error);
            
                IF NOT g_retval
                THEN
                    -- rollback and continues to the next iteration
                    ROLLBACK TO process_rule;
                    g_error := g_error || ' / NOK 1 l_id_rcm=' || l_id_rcm || ' i_id_rcm_rule=' || i_id_rcm_rule ||
                               ' i_id_rule_inst=' || i_id_rule_inst;
                    pk_alertlog.log_error(g_error);
                END IF;
            
                COMMIT;
            
            END IF;
        
            EXIT WHEN l_id_rule_tab.count < pk_rcm_constant.g_limit;
        
        END LOOP;
    
        CLOSE l_cur_query;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            g_error := g_error || ' / NOK 2 l_id_rcm=' || l_id_rcm || ' i_id_rcm_rule=' || i_id_rcm_rule ||
                       ' i_id_rule_inst=' || i_id_rule_inst;
            pk_alertlog.log_error(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            g_error := g_error || ' / NOK 3 l_id_rcm=' || l_id_rcm || ' i_id_rcm_rule=' || i_id_rcm_rule ||
                       ' i_id_rule_inst=' || i_id_rule_inst;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END process_rule_instance;

    /**
    * Function to generate reminders for patients in the institution (if specified)
    *   
    * @param   i_id_patient_tab           Array of patient identifiers
    * @param   i_id_institution           Institution identifier 
    *   
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   03-09-2012
    */
    PROCEDURE generate_reminders_pat_int
    (
        i_id_patient_tab IN table_number,
        i_id_institution IN institution.id_institution%TYPE
    ) IS
        l_func_name CONSTANT pk_rcm_constant.t_low_char := 'GENERATE_REMINDERS_PAT_INT';
        l_error t_error_out;
    
        CURSOR c_inst
        (
            x_id_market IN institution.id_market%TYPE,
            x_id_inst   IN institution.id_institution%TYPE
        ) IS
            SELECT id_institution
              FROM institution i
             WHERE i.flg_available = pk_alert_constant.g_yes
               AND i.id_market = x_id_market
               AND (i.id_institution = x_id_inst OR x_id_inst IS NULL);
    
        l_id_institution_tab table_number;
        l_lang               language.id_language%TYPE;
        l_prof               profissional := profissional(NULL, 0, 0);
        l_cur_rcm_rules      pk_rcm_constant.t_cur_rcm_rule;
        l_tab_rcm_rules      pk_rcm_constant.t_coll_rcm_rule;
        l_rule_query         rcm_rule.rule_query%TYPE;
        l_id_market          institution.id_market%TYPE;
    BEGIN
        g_error := 'Init ' || l_func_name;
        pk_alertlog.log_debug(g_error);
        l_id_market    := to_number(pk_sysconfig.get_config(i_code_cf => pk_rcm_constant.g_sc_id_market,
                                                            i_prof    => l_prof));
        g_ids_software := pk_sysconfig.get_config(i_code_cf => pk_rcm_constant.g_sc_id_software, i_prof => l_prof);
    
        -- gets rcm rules (this info does not depend on institution data, can be done before fetching institution data)                                       
        g_retval := pk_rcm_params.get_rcm_rules(i_lang      => l_lang,
                                                i_prof      => l_prof,
                                                o_rcm_rules => l_cur_rcm_rules,
                                                o_error     => l_error);
    
        FETCH l_cur_rcm_rules BULK COLLECT
            INTO l_tab_rcm_rules;
        CLOSE l_cur_rcm_rules;
    
        OPEN c_inst(l_id_market, i_id_institution);
        LOOP
            FETCH c_inst BULK COLLECT
                INTO l_id_institution_tab LIMIT pk_rcm_constant.g_limit;
        
            FOR i IN 1 .. l_id_institution_tab.count
            LOOP
            
                BEGIN
                    -- loads professional and id_language for this institution
                    g_error            := l_func_name || ': ID_INSTITUTION=' || l_id_institution_tab(i);
                    l_prof.institution := l_id_institution_tab(i);
                    l_lang             := pk_utils.get_institution_language(i_institution => l_id_institution_tab(i));
                
                    -- this is done only once (for this market)
                    IF l_prof.id IS NULL
                    THEN
                        l_prof.id := pk_sysconfig.get_config(i_code_cf => pk_rcm_constant.g_sc_id_prof_background,
                                                             i_prof    => l_prof);
                    END IF;
                
                    FOR rec_rule IN 1 .. l_tab_rcm_rules.count
                    LOOP
                    
                        -- get rule query
                        l_rule_query := l_tab_rcm_rules(rec_rule).rule_query;
                    
                        -- loads instance values into temporary table
                        g_error  := l_func_name || ': Call pk_rcm_params.load_instance_data / ID_INSTITUTION=' ||
                                    l_id_institution_tab(i) || ' ID_RCM_RULE=' || l_tab_rcm_rules(rec_rule).id_rcm_rule ||
                                    ' i_id_rule_inst=' || l_tab_rcm_rules(rec_rule).id_rule_inst;
                        g_retval := pk_rcm_params.load_instance_data(i_lang         => l_lang,
                                                                     i_prof         => l_prof,
                                                                     i_id_rcm_rule  => l_tab_rcm_rules(rec_rule).id_rcm_rule,
                                                                     i_id_rule_inst => l_tab_rcm_rules(rec_rule).id_rule_inst,
                                                                     o_error        => l_error);
                    
                        -- process rule and create patient reminders
                        g_error  := l_func_name || ': Call process_rule_instance / i_id_rcm=' || l_tab_rcm_rules(rec_rule).id_rcm ||
                                    ' i_id_rcm_rule=' || l_tab_rcm_rules(rec_rule).id_rcm_rule || ' i_id_rule_inst=' || l_tab_rcm_rules(rec_rule).id_rule_inst;
                        g_retval := process_rule_instance(i_lang           => l_lang,
                                                          i_prof           => l_prof,
                                                          i_id_rcm         => l_tab_rcm_rules(rec_rule).id_rcm,
                                                          i_id_rcm_rule    => l_tab_rcm_rules(rec_rule).id_rcm_rule,
                                                          i_id_rule_inst   => l_tab_rcm_rules(rec_rule).id_rule_inst,
                                                          i_rule_query     => l_rule_query,
                                                          i_id_patient_tab => i_id_patient_tab,
                                                          o_error          => l_error);
                    
                        IF NOT g_retval
                        THEN
                            g_error := g_error || ' / ID_RULE=' || l_tab_rcm_rules(rec_rule).id_rcm_rule || ' ID_RCM=' || l_tab_rcm_rules(rec_rule).id_rcm ||
                                       ' ID_RULE_INST=' || l_tab_rcm_rules(rec_rule).id_rule_inst || ' / ' ||
                                       l_error.ora_sqlcode || ' LOG=' || l_error.log_id;
                            pk_alertlog.log_error(g_error); -- continue to the next rule
                        END IF;
                    
                    END LOOP;
                
                EXCEPTION
                    WHEN OTHERS THEN
                        pk_alertlog.log_error(g_error || ' / ID_INSTITUTION=' || l_prof.institution || ' / ' ||
                                              SQLERRM); -- continue to the next institution
                END;
            
            END LOOP;
        
            EXIT WHEN l_id_institution_tab.count < pk_rcm_constant.g_limit;
        
        END LOOP;
    
        CLOSE c_inst;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => l_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => l_error);
    END generate_reminders_pat_int;

    /**
    * Search patients who are under the conditions of the reminder rules 
    * Function called by job j_rcm_generate_reminder. Enabled only by request (in pre-production or production environment)
    *   
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   11-04-2012
    */
    PROCEDURE generate_reminders IS
        l_func_name CONSTANT pk_rcm_constant.t_low_char := 'GENERATE_REMINDERS';
        l_error t_error_out;
        l_lang  language.id_language%TYPE;
    BEGIN
        g_error := 'Init ' || l_func_name;
        generate_reminders_pat_int(i_id_patient_tab => NULL, i_id_institution => NULL); -- all institutions and all patients    
        COMMIT;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_utils.undo_changes;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => l_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => l_error);
            pk_utils.undo_changes;
    END generate_reminders;

    /**
    * Function to be called from reset, to generate reminders for patients in the institution specified 
    * Commit or rollback done by reset module
    *
    * @param   i_id_patient_tab           Array of patient identifiers
    * @param   i_id_institution           Institution identifier
    * @param   o_error                    Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *   
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   03-09-2012
    */
    FUNCTION generate_reminders_pat
    (
        i_id_patient_tab IN table_number,
        i_id_institution IN institution.id_institution%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT pk_rcm_constant.t_low_char := 'GENERATE_REMINDERS_PAT';
        l_lang language.id_language%TYPE;
    BEGIN
        g_error := 'Init ' || l_func_name || ' i_id_institution=' || i_id_institution || ' i_id_patient_tab.count=' ||
                   i_id_patient_tab.count;
        pk_alertlog.log_debug(g_error);
    
        IF i_id_patient_tab IS NULL
           OR i_id_patient_tab.count = 0
           OR i_id_institution IS NULL
        THEN
            g_error := l_func_name || ': Invalid input parameters / i_id_institution=' || i_id_institution;
            pk_alertlog.log_error(g_error);
            RAISE g_exception;
        END IF;
    
        generate_reminders_pat_int(i_id_patient_tab => i_id_patient_tab, i_id_institution => i_id_institution);
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.process_error(i_lang     => l_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END generate_reminders_pat;

    /**
    * Get CRM notification status
    *
    * @param   i_lang                     Professional preferred language
    * @param   i_prof                     Professional identifier and its context (institution and software)
    * @param   i_crm_key                  CRM id 
    * @param   o_notif_status             {*} 'Y' - Notified
    *                                     {*} 'N' - Unnotified
    * @param   o_error                    Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Joana Barroso
    * @version 1.0
    * @since   19-04-2012
    */
    FUNCTION get_notification_status
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_crm_key      IN pat_rcm_h.crm_key%TYPE,
        o_notif_status OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT pk_rcm_constant.t_low_char := 'GET_NOTIFICATION_STATUS';
        l_msg_tokens  pk_rcm_constant.t_ibt_desc_value;
        l_ws_response CLOB;
    BEGIN
        g_error := 'Init ' || l_func_name || ' / I_CRM_KEY=' || i_crm_key;
        l_msg_tokens(pk_rcm_constant.g_tk_crm_key) := i_crm_key;
    
        -- call webservice
        g_retval := send_message_to_crm(i_lang        => i_lang,
                                        i_prof        => i_prof,
                                        i_ws_name     => pk_rcm_constant.g_ws_get_request_data,
                                        i_msg_tokens  => l_msg_tokens,
                                        o_ws_response => l_ws_response,
                                        o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- get notification status 
        g_error  := l_func_name || ': Call get_crm_key_status / I_CRM_KEY=' || i_crm_key;
        g_retval := get_crm_key_status(i_lang           => i_lang,
                                       i_prof           => i_prof,
                                       i_ws_response    => l_ws_response,
                                       o_crm_key_status => o_notif_status,
                                       o_error          => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_notification_status;

    /**
    * Set RCM status, based on CRM notification status
    * Function called by job . Enabled only by request (in pre-production or production environment)
    *
    * @author Joana Barroso
    * @since  19-Apr-2012
    **/
    PROCEDURE set_rcm_notif_status IS
        CURSOR c_rcm IS
            SELECT t.id_patient, t.id_rcm, t.id_rcm_det, t.id_workflow, t.id_status, t.crm_key, t.id_institution
              FROM (SELECT row_number() over(PARTITION BY prd.id_patient, prd.id_rcm, prd.id_rcm_det ORDER BY prh.dt_status DESC) my_row,
                           prd.id_rcm,
                           prd.id_rcm_det,
                           prh.dt_status,
                           prh.id_workflow,
                           prh.id_status,
                           prd.id_patient,
                           prh.crm_key,
                           prh.id_institution
                      FROM pat_rcm_det prd
                      JOIN pat_rcm_h prh
                        ON (prd.id_patient = prh.id_patient AND prd.id_rcm = prh.id_rcm AND
                           prd.id_rcm_det = prh.id_rcm_det)) t
             WHERE t.my_row = 1
               AND t.id_status = pk_rcm_constant.g_id_status_pend_notif;
    
        TYPE t_rcm IS TABLE OF c_rcm%ROWTYPE INDEX BY PLS_INTEGER;
        l_rcm_tab t_rcm;
        l_lang    language.id_language%TYPE := 0;
        l_prof    profissional := profissional(0, 0, 0);
        l_error   t_error_out;
        l_func_name CONSTANT pk_rcm_constant.t_low_char := 'SET_RCM_NOTIF_STATUS';
        l_notif_status VARCHAR2(1 CHAR);
        l_flg_show     VARCHAR2(1 CHAR);
        l_msg_title    VARCHAR2(1000 CHAR);
        l_msg          VARCHAR2(1000 CHAR);
        l_button       VARCHAR2(10 CHAR);
    BEGIN
        g_error   := 'Init set_rcm_notif_status';
        l_prof.id := pk_sysconfig.get_config(i_code_cf => pk_rcm_constant.g_sc_id_prof_background, i_prof => l_prof);
    
        g_error := 'OPEN c_rcm';
        OPEN c_rcm;
        LOOP
            FETCH c_rcm BULK COLLECT
                INTO l_rcm_tab LIMIT pk_rcm_constant.g_limit;
        
            FOR i IN 1 .. l_rcm_tab.count
            LOOP
                l_prof.institution := l_rcm_tab(i).id_institution;
                l_lang             := pk_utils.get_institution_language(i_institution => l_prof.institution); -- needed in CRM ws
            
                g_error  := g_package || '.' || l_func_name || ': Call get_notification_status / I_CRM_KEY=' || l_rcm_tab(i).crm_key;
                g_retval := get_notification_status(i_lang         => l_lang,
                                                    i_prof         => l_prof,
                                                    i_crm_key      => l_rcm_tab(i).crm_key,
                                                    o_notif_status => l_notif_status,
                                                    o_error        => l_error);
            
                IF NOT g_retval
                THEN
                    pk_alertlog.log_error(g_error || ' / ' || l_error.ora_sqlcode || ' LOG=' || l_error.log_id);
                
                ELSE
                
                    IF l_notif_status = pk_alert_constant.get_yes
                    THEN
                        g_error := g_package || '.' || l_func_name || ': Call pk_rcm_core.set_pat_rcm / I_ID_PATIENT=' || l_rcm_tab(i).id_patient ||
                                   ' I_ID_EPISODE=' || pk_rcm_constant.g_epis_epis_undef || ' I_ID_RCM=' || l_rcm_tab(i).id_rcm ||
                                   ' I_ID_RCM_DET=' || l_rcm_tab(i).id_rcm_det || ' i_id_workflow' || l_rcm_tab(i).id_workflow ||
                                   ' I_ID_WORKFLOW_ACTION=' || pk_rcm_constant.g_wf_action_notif ||
                                   ' I_ID_STATUS_BEGIN=' || l_rcm_tab(i).id_status || 'I_ID_STATUS_END' ||
                                   pk_rcm_constant.g_id_status_pat_notif;
                    
                        g_retval := pk_rcm_core.set_pat_rcm(i_lang               => l_lang,
                                                            i_prof               => l_prof,
                                                            i_id_patient         => l_rcm_tab(i).id_patient,
                                                            i_id_episode         => pk_rcm_constant.g_epis_epis_undef,
                                                            i_id_rcm             => l_rcm_tab(i).id_rcm,
                                                            i_id_rcm_det         => l_rcm_tab(i).id_rcm_det,
                                                            i_id_workflow        => l_rcm_tab(i).id_workflow,
                                                            i_id_workflow_action => pk_rcm_constant.g_wf_action_notif,
                                                            i_id_status_begin    => l_rcm_tab(i).id_status,
                                                            i_id_status_end      => pk_rcm_constant.g_id_status_pat_notif,
                                                            i_rcm_notes          => NULL,
                                                            o_flg_show           => l_flg_show,
                                                            o_msg_title          => l_msg_title,
                                                            o_msg                => l_msg,
                                                            o_button             => l_button,
                                                            o_error              => l_error);
                    
                        IF NOT g_retval
                        THEN
                            pk_alertlog.log_error(g_error || ' / ' || l_error.ora_sqlcode || ' LOG=' || l_error.log_id);
                        END IF;
                    ELSIF l_notif_status = pk_alert_constant.get_no
                    THEN
                    
                        g_error := g_package || '.' || l_func_name || ': Call pk_rcm_core.set_pat_rcm / I_ID_PATIENT=' || l_rcm_tab(i).id_patient ||
                                   ' I_ID_EPISODE=' || pk_rcm_constant.g_epis_epis_undef || ' I_ID_RCM=' || l_rcm_tab(i).id_rcm ||
                                   ' I_ID_RCM_DET=' || l_rcm_tab(i).id_rcm_det || ' i_id_workflow' || l_rcm_tab(i).id_workflow ||
                                   ' I_ID_WORKFLOW_ACTION=' || pk_rcm_constant.g_wf_action_not_notif ||
                                   ' I_ID_STATUS_BEGIN=' || l_rcm_tab(i).id_status || 'I_ID_STATUS_END' ||
                                   pk_rcm_constant.g_id_status_pat_not_notif;
                    
                        g_retval := pk_rcm_core.set_pat_rcm(i_lang               => l_lang,
                                                            i_prof               => l_prof,
                                                            i_id_patient         => l_rcm_tab(i).id_patient,
                                                            i_id_episode         => pk_rcm_constant.g_epis_epis_undef,
                                                            i_id_rcm             => l_rcm_tab(i).id_rcm,
                                                            i_id_rcm_det         => l_rcm_tab(i).id_rcm_det,
                                                            i_id_workflow        => l_rcm_tab(i).id_workflow,
                                                            i_id_workflow_action => pk_rcm_constant.g_wf_action_not_notif,
                                                            i_id_status_begin    => l_rcm_tab(i).id_status,
                                                            i_id_status_end      => pk_rcm_constant.g_id_status_pat_not_notif,
                                                            i_rcm_notes          => NULL,
                                                            o_flg_show           => l_flg_show,
                                                            o_msg_title          => l_msg_title,
                                                            o_msg                => l_msg,
                                                            o_button             => l_button,
                                                            o_error              => l_error);
                    
                        IF NOT g_retval
                        THEN
                            pk_alertlog.log_error(g_error || ' / ' || l_error.ora_sqlcode || ' LOG=' || l_error.log_id);
                        END IF;
                    
                    ELSIF l_notif_status IS NULL
                    THEN
                        NULL; -- does not change rcm status, try again later (notification is being processed)
                    END IF;
                END IF;
            END LOOP;
        
            EXIT WHEN l_rcm_tab.count < pk_rcm_constant.g_limit;
        
        END LOOP;
        CLOSE c_rcm;
    
        COMMIT;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            pk_alertlog.log_error(g_error || ' / ' || SQLERRM);
    END set_rcm_notif_status;

    ----------------------------------------------------------------
    -- web service functions
    ----------------------------------------------------------------

    /**
    * Builds input string to be sent to the CRM 
    *
    * @param   i_lang                     Professional preferred language
    * @param   i_prof                     Professional identifier and its context (institution and software)
    * @param   i_ws_int_name              Webservice name
    * @param   i_msg_tokens               Tokens needed to the message
    * @param   o_crm_key                  Transaction identifier related to the message sent to the patient   
    * @param   o_error                    Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   09-04-2012
    */
    FUNCTION get_ws_data
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_ws_int_name IN VARCHAR2,
        i_msg_tokens  IN pk_rcm_constant.t_ibt_desc_value,
        o_ws_data     OUT pk_webservices.table_ws_attr,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT pk_rcm_constant.t_low_char := 'GET_WS_DATA';
        l_string VARCHAR2(1000 CHAR);
    BEGIN
        g_error := 'Init ' || l_func_name || ' / i_ws_int_name=' || i_ws_int_name;
    
        -- builds data to be sent to the crm services
        CASE i_ws_int_name
            WHEN pk_rcm_constant.g_ws_execution_request THEN
            
                -- RemoteServiceContext 
                l_string := 'executionRequestSetObject.context';
                o_ws_data(l_string || '.language') := anydata.convertnumber(i_lang);
                o_ws_data(l_string || '.professional') := anydata.convertnumber(i_prof.id);
                o_ws_data(l_string || '.institution') := anydata.convertnumber(i_prof.institution);
                o_ws_data(l_string || '.software') := anydata.convertnumber(i_prof.software);
            
                -- RequestDetails
                l_string := 'executionRequestSetObject.requestDetails';
                o_ws_data(l_string || '.executionType') := anydata.convertvarchar2('AUTO'); -- send from template
                o_ws_data(l_string || '.messageDefinition') := anydata.convertvarchar2(i_msg_tokens(pk_rcm_constant.g_tk_templ_value));
            
                -- RequestContent - 1 position filled (send to a patient only)
                --     RequestRecipient
                l_string := 'executionRequestSetObject.requestContents[1].requestContent.requestRecipient';
                o_ws_data(l_string || '.code') := anydata.convertvarchar2(i_msg_tokens(pk_rcm_constant.g_tk_id_patient)); -- id_patient
                o_ws_data(l_string || '.value') := anydata.convertvarchar2(i_msg_tokens(pk_rcm_constant.g_tk_pat_contact)); -- patient contact
                o_ws_data(l_string || '.description') := anydata.convertvarchar2(i_msg_tokens(pk_rcm_constant.g_tk_pat_name)); -- patient name
            
                --     RequestContentAttribute
                -- reminder description
                l_string := 'executionRequestSetObject.requestContents[1].requestContent.requestContentAttributeList[1].requestContentAttribute';
                o_ws_data(l_string || '[1].id') := anydata.convertvarchar2(pk_rcm_constant.g_crm_att_reminder_desc);
                o_ws_data(l_string || '[1].value') := anydata.convertvarchar2(i_msg_tokens(pk_rcm_constant.g_tk_rcm_summ));
                o_ws_data(l_string || '[1].description') := anydata.convertvarchar2(pk_rcm_constant.g_crm_att_reminder_desc);
            
                -- Patient name
                o_ws_data(l_string || '[2].id') := anydata.convertvarchar2(pk_rcm_constant.g_crm_att_patient_name);
                o_ws_data(l_string || '[2].value') := anydata.convertvarchar2(i_msg_tokens(pk_rcm_constant.g_tk_pat_name));
                o_ws_data(l_string || '[2].description') := anydata.convertvarchar2(pk_rcm_constant.g_crm_att_patient_name);
            
                -- institution name
                o_ws_data(l_string || '[3].id') := anydata.convertvarchar2(pk_rcm_constant.g_crm_att_instit_name);
                o_ws_data(l_string || '[3].value') := anydata.convertvarchar2(i_msg_tokens(pk_rcm_constant.g_tk_inst_name));
                o_ws_data(l_string || '[3].description') := anydata.convertvarchar2(pk_rcm_constant.g_crm_att_instit_name);
            
                -- institution phone
                o_ws_data(l_string || '[4].id') := anydata.convertvarchar2(pk_rcm_constant.g_crm_att_instit_phone);
                o_ws_data(l_string || '[4].value') := anydata.convertvarchar2(i_msg_tokens(pk_rcm_constant.g_tk_inst_phone));
                o_ws_data(l_string || '[4].description') := anydata.convertvarchar2(pk_rcm_constant.g_crm_att_instit_phone);
            
            WHEN pk_rcm_constant.g_ws_get_request_data THEN
            
                -- RemoteServiceContext 
                l_string := 'messageArchiveGetObject';
                o_ws_data(l_string || '.language') := anydata.convertnumber(i_lang);
                o_ws_data(l_string || '.professional') := anydata.convertnumber(i_prof.id);
                o_ws_data(l_string || '.institution') := anydata.convertnumber(i_prof.institution);
                o_ws_data(l_string || '.software') := anydata.convertnumber(i_prof.software);
                o_ws_data(l_string || '.requestId') := anydata.convertvarchar2(i_msg_tokens(pk_rcm_constant.g_tk_crm_key));
            ELSE
                g_error := 'Webservice name not expected / ' || i_ws_int_name;
                RAISE g_exception;
        END CASE;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_ws_data;

    /**
    * Sends message to the crm
    *
    * @param   i_lang            Professional preferred language
    * @param   i_prof            Professional identifier and its context (institution and software)
    * @param   i_ws_name         Webservice name to be called
    * @param   i_msg_tokens      Tokens needed to the message
    * @param   o_ws_response     Web service response   
    * @param   o_error           Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   09-04-2012
    */
    FUNCTION send_message_to_crm
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_ws_name     IN VARCHAR2,
        i_msg_tokens  IN pk_rcm_constant.t_ibt_desc_value,
        o_ws_response OUT CLOB,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT pk_rcm_constant.t_low_char := 'SEND_MESSAGE_TO_CRM';
        l_ws_data pk_webservices.table_ws_attr;
    BEGIN
        g_error := 'Init ' || l_func_name || ' / i_ws_name=' || i_ws_name;
    
        -- builds webservice data
        g_retval := get_ws_data(i_lang        => i_lang,
                                i_prof        => i_prof,
                                i_ws_int_name => i_ws_name,
                                i_msg_tokens  => i_msg_tokens,
                                o_ws_data     => l_ws_data,
                                o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        --dbms_output.put_line(pk_webservices.to_json(l_ws_data));
    
        -- call CRM web service
        g_error       := l_func_name || ': Call pk_webservices.call_ws / i_ws_int_name=' || i_ws_name;
        o_ws_response := pk_webservices.call_ws(i_ws_int_name => i_ws_name, i_table_table_ws => l_ws_data);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END send_message_to_crm;

    /**
    * Interprets webservice response and gets the value of CRM key (same as execution request key)
    *
    * @param   i_lang            Professional preferred language
    * @param   i_prof            Professional identifier and its context (institution and software)
    * @param   i_msg_tokens      Tokens needed to the message
    * @param   o_ws_response     Web service response   
    * @param   o_error           Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   09-04-2012
    */
    FUNCTION get_crm_key
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_ws_response IN CLOB,
        o_crm_key     OUT pat_rcm_h.crm_key%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT pk_rcm_constant.t_low_char := 'GET_CRM_KEY';
    BEGIN
        g_error   := 'Init ' || l_func_name;
        o_crm_key := i_ws_response;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_crm_key;

    /**
    * Interprets webservice response and gets the status of CRM key (same as execution request key)
    *
    * @param   i_lang            Professional preferred language
    * @param   i_prof            Professional identifier and its context (institution and software)
    * @param   i_msg_tokens      Tokens needed to the message
    * @param   o_ws_response     Web service response   
    * @param   o_error           Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   09-04-2012
    */
    FUNCTION get_crm_key_status
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_ws_response    IN CLOB,
        o_crm_key_status OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT pk_rcm_constant.t_low_char := 'GET_CRM_KEY_STATUS';
        l_status_crm VARCHAR2(20 CHAR);
        l_json       json_object_t;
    BEGIN
        g_error := 'Init ' || l_func_name;
    
        -- getting string "status"
        l_json       := json_object_t(i_ws_response);
        l_status_crm := l_json.get_string('messageArchiveDetailsListObject.messageArchives.messageArchive.status');
    
        g_error := l_func_name || ': l_status_crm=' || l_status_crm;
        CASE l_status_crm
            WHEN pk_rcm_constant.g_crm_status_processed THEN
                o_crm_key_status := pk_alert_constant.g_yes;
            WHEN pk_rcm_constant.g_crm_status_error THEN
                o_crm_key_status := pk_alert_constant.g_no;
            ELSE
                NULL; -- try again later
        END CASE;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_crm_key_status;

    /**
    * This function deletes all data related to recommendations
    *
    * @param   i_lang                     Professional preferred language
    * @param   i_prof                     Professional identifier and its context (institution and software)
    * @param   i_id_patient_tab           Array of patient identifiers. Only used to clean patient reminders.
    * @param   i_id_institution           Institution identifier
    * @param   i_id_episode_tab           Array of episode identifiers. Only used to clean clinical recommendations.
    * @param   i_id_software              Software identifier
    * @param   o_error                    Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ANA.MONTEIRO
    * @since   28-08-2012
    */
    FUNCTION rcm_reset
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_patient_tab IN table_number,
        i_id_institution IN pat_rcm_det.id_institution%TYPE,
        i_id_episode_tab IN table_number,
        i_id_software    IN software.id_software%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT pk_rcm_constant.t_low_char := 'RCM_RESET';
        l_id_software_tab table_number;
        l_count           PLS_INTEGER;
    
        -- getting all clinical recommendations that were ***created*** in that episode
        CURSOR c_rcm IS
            SELECT t.id_patient, t.id_rcm, t.id_rcm_det
              FROM (SELECT row_number() over(PARTITION BY prh.id_patient, prh.id_rcm, prh.id_rcm_det ORDER BY prh.dt_status ASC) my_row,
                           prh.*
                      FROM pat_rcm_h prh
                     WHERE prh.id_institution = i_id_institution
                       AND prh.id_rcm IN (SELECT r.id_rcm
                                            FROM rcm r
                                           WHERE r.id_rcm_type = pk_rcm_constant.g_type_rcm_clin_rcm)) t
             WHERE t.my_row = 1
               AND t.id_epis_created IN (SELECT /*+opt_estimate(table t rows=1)*/
                                          column_value
                                           FROM TABLE(CAST(i_id_episode_tab AS table_number)) t);
    
        l_pat_tab     table_number := table_number();
        l_rcm_tab     table_number := table_number();
        l_rcm_det_tab table_number := table_number();
    BEGIN
        g_error := 'Init ' || l_func_name || ' / i_id_patient_tab.count=' || i_id_patient_tab.count ||
                   ' i_id_episode_tab.count=' || i_id_episode_tab.count || ' i_id_institution=' || i_id_institution ||
                   ' i_id_software=' || i_id_software;
        pk_alertlog.log_debug(g_error);
    
        IF i_id_episode_tab IS NULL
           OR i_id_patient_tab IS NULL
        THEN
            g_error := 'Invalid parameters / i_id_episode_tab or i_id_patient_tab cannot be null';
            RAISE g_exception;
        END IF;
    
        l_id_software_tab := pk_utils.str_split_n(pk_sysconfig.get_config(i_code_cf => pk_rcm_constant.g_sc_id_software,
                                                                          i_prof    => i_prof));
    
        -- clinical recommendations
        -- cleans clinical recommendations that were created in the episode specified
        IF i_id_episode_tab.count > 0
        THEN
            OPEN c_rcm;
            FETCH c_rcm BULK COLLECT
                INTO l_pat_tab, l_rcm_tab, l_rcm_det_tab;
            CLOSE c_rcm;
        
            g_error := l_func_name || ': FORALL j IN 1..l_pat_tab.count / pat_rcm_h / l_id_software_tab=' ||
                       pk_utils.to_string(l_id_software_tab);
            pk_alertlog.log_debug(g_error);
            FORALL j IN 1 .. l_pat_tab.count
                DELETE FROM pat_rcm_h
                 WHERE id_patient = l_pat_tab(j)
                   AND id_rcm = l_rcm_tab(j)
                   AND id_rcm_det = l_rcm_det_tab(j)
                   AND id_institution = i_id_institution;
        
            g_error := l_func_name || ': FORALL j IN 1..l_pat_tab.count / pat_rcm_det';
            pk_alertlog.log_debug(g_error);
            FORALL j IN 1 .. l_pat_tab.count
                DELETE FROM pat_rcm_det
                 WHERE id_patient = l_pat_tab(j)
                   AND id_rcm = l_rcm_tab(j)
                   AND id_rcm_det = l_rcm_det_tab(j)
                   AND id_institution = i_id_institution;
        END IF;
    
        IF i_id_patient_tab.count > 0
        THEN
            -- Patient Reminders
            -- cleans patient reminders that were originated in the software configured in l_id_software_tab
            g_error := l_func_name || ': SELECT COUNT(1) / l_id_software_tab=' || pk_utils.to_string(l_id_software_tab);
            SELECT COUNT(1)
              INTO l_count
              FROM TABLE(CAST(l_id_software_tab AS table_number))
             WHERE column_value = i_id_software;
        
            IF l_count > 0
            THEN
                g_error := l_func_name || ': DELETE FROM pat_rcm_h / ID_SOFTWARE=' || i_id_software ||
                           ' ID_INSTITUTION=' || i_id_institution;
                pk_alertlog.log_debug(g_error);
                DELETE FROM pat_rcm_h
                 WHERE id_patient IN (SELECT /*+opt_estimate(table t rows=1)*/
                                       column_value
                                        FROM TABLE(CAST(i_id_patient_tab AS table_number)) t)
                   AND id_institution = i_id_institution
                   AND id_rcm IN
                       (SELECT r.id_rcm
                          FROM rcm r
                         WHERE r.id_rcm_type IN
                               (pk_rcm_constant.g_type_rcm_reminder, pk_rcm_constant.g_type_rcm_reminder_auto));
            
                g_error := l_func_name || ': DELETE FROM pat_rcm_det / ID_SOFTWARE=' || i_id_software ||
                           ' ID_INSTITUTION=' || i_id_institution;
                pk_alertlog.log_debug(g_error);
                DELETE FROM pat_rcm_det
                 WHERE id_patient IN (SELECT /*+opt_estimate(table t rows=1)*/
                                       column_value
                                        FROM TABLE(CAST(i_id_patient_tab AS table_number)) t)
                   AND id_institution = i_id_institution
                   AND id_rcm IN
                       (SELECT r.id_rcm
                          FROM rcm r
                         WHERE r.id_rcm_type IN
                               (pk_rcm_constant.g_type_rcm_reminder, pk_rcm_constant.g_type_rcm_reminder_auto));
            
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END rcm_reset;

    FUNCTION get_pat_rcm_instruct_cda
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_type_scope    IN VARCHAR2,
        i_id_scope      IN NUMBER,
        o_pat_rcm_instr OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_rcm_core.get_pat_rcm_instruct_cda(i_lang          => i_lang,
                                                    i_prof          => i_prof,
                                                    i_type_scope    => i_type_scope,
                                                    i_id_scope      => i_id_scope,
                                                    o_pat_rcm_instr => o_pat_rcm_instr,
                                                    o_error         => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_PAT_RCM_INSTRUCT_CDA',
                                              o_error);
            RETURN FALSE;
    END get_pat_rcm_instruct_cda;

BEGIN
    -- Initialization

    /* CAN'T TOUCH THIS */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_api_rcm_out;
/
