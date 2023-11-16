/*-- Last Change Revision: $Rev: 2027231 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:34 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_icnp_suggestion IS

    --------------------------------------------------------------------------------
    -- GLOBAL VARIABLES
    --------------------------------------------------------------------------------

    -- Identifes the owner in the log mechanism
    g_package_owner pk_icnp_type.t_package_owner;

    -- Identifes the package in the log mechanism
    g_package_name pk_icnp_type.t_package_name;

    --------------------------------------------------------------------------------
    -- PRIVATE METHODS [DEBUG]
    --------------------------------------------------------------------------------

    /*
     * Wrapper of the method from the alertlog mechanism that creates a debug log 
     * message.
     *
     * @param i_text Text to log.
     * @param i_func_name Function / procedure name.
     *
     * @author Luis Oliveira
     * @version 1.0
     * @since 25/Jul/2011
    */
    PROCEDURE log_debug
    (
        i_text      VARCHAR2,
        i_func_name VARCHAR2
    ) IS
    BEGIN
        pk_alertlog.log_debug(text => i_text, object_name => g_package_name, sub_object_name => i_func_name);
    END log_debug;

    --------------------------------------------------------------------------------
    -- METHODS [INIT]
    --------------------------------------------------------------------------------

    /**
     * Executes all the instructions needed to correctly initialize the package.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 20/Jul/2011 (v2.6.1)
    */
    PROCEDURE initialize IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'initialize';
    
    BEGIN
        -- Initializes the log mechanism
        g_package_owner := 'ALERT';
        g_package_name  := pk_alertlog.who_am_i;
        pk_alertlog.log_init(g_package_name);
    
        -- Log message
        log_debug(c_func_name || '()', c_func_name);
    END;

    --------------------------------------------------------------------------------
    -- METHODS [GETS EXTERNAL TASK]
    --------------------------------------------------------------------------------

    /**
     * Gets relevant information (namely a description, the instructions and the status) 
     * about a task that is associated with a therapeutic attitude.
     *
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_request_id The identifier of the external request.
     * @param i_task_type_id Identifier of the external task type.
     * @param o_description A text that identifies the external task.
     * @param o_instructions A text with the instructions of the external task.
     * @param o_flg_status The status of the external task.
     * 
     * @author Joao Martins
     * @version (?)
     * @since (?)
    */
    PROCEDURE get_sugg_task_info
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_request_id   IN NUMBER,
        i_task_type_id IN NUMBER,
        o_description  OUT VARCHAR2,
        o_instructions OUT VARCHAR2,
        o_flg_status   OUT VARCHAR2
    ) IS
        l_error t_error_out;
    
    BEGIN
        CASE
            WHEN i_task_type_id = pk_alert_constant.g_task_procedure THEN
                DECLARE
                    l_dump       VARCHAR2(4000);
                    l_flg_status VARCHAR2(4000);
                
                BEGIN
                    IF NOT
                        pk_procedures_external_api_db.get_procedure_task_description(i_lang             => i_lang,
                                                                                     i_prof             => i_prof,
                                                                                     i_task_request     => i_request_id,
                                                                                     o_task_desc        => o_description,
                                                                                     o_task_status_desc => l_dump,
                                                                                     o_error            => l_error)
                    THEN
                        pk_icnp_util.raise_unexpected_error('pk_procedures_external_api_db.get_procedure_order',
                                                            l_error);
                    END IF;
                
                    IF NOT pk_procedures_external_api_db.get_procedure_status(i_lang          => i_lang,
                                                                              i_prof          => i_prof,
                                                                              i_task_request  => i_request_id,
                                                                              o_flg_status    => l_flg_status,
                                                                              o_status_string => l_dump,
                                                                              o_error         => l_error)
                    THEN
                        pk_icnp_util.raise_unexpected_error('pk_procedures_external_api_db.get_procedure_order',
                                                            l_error);
                    END IF;
                
                    o_instructions := NULL;
                    o_flg_status   := CASE l_flg_status
                                          WHEN pk_alert_constant.g_interv_det_cancel THEN
                                           pk_alert_constant.g_no
                                          ELSE
                                           pk_alert_constant.g_yes
                                      END;
                END;
            
            WHEN i_task_type_id = pk_alert_constant.g_task_rehab THEN
                DECLARE
                    l_dump       VARCHAR2(4000);
                    l_flg_status VARCHAR2(4000);
                
                BEGIN
                    IF NOT
                        pk_procedures_external_api_db.get_procedure_task_description(i_lang             => i_lang,
                                                                                     i_prof             => i_prof,
                                                                                     i_task_request     => i_request_id,
                                                                                     o_task_desc        => o_description,
                                                                                     o_task_status_desc => l_dump,
                                                                                     o_error            => l_error)
                    THEN
                        pk_icnp_util.raise_unexpected_error('pk_procedures_external_api_db.get_procedure_order',
                                                            l_error);
                    END IF;
                
                    IF NOT pk_procedures_external_api_db.get_procedure_status(i_lang          => i_lang,
                                                                              i_prof          => i_prof,
                                                                              i_task_request  => i_request_id,
                                                                              o_flg_status    => l_flg_status,
                                                                              o_status_string => l_dump,
                                                                              o_error         => l_error)
                    THEN
                        pk_icnp_util.raise_unexpected_error('pk_procedures_external_api_db.get_procedure_order',
                                                            l_error);
                    END IF;
                
                    o_instructions := NULL;
                    o_flg_status   := CASE l_flg_status
                                          WHEN pk_alert_constant.g_interv_det_cancel THEN
                                           pk_alert_constant.g_no
                                          ELSE
                                           pk_alert_constant.g_yes
                                      END;
                END;
            
            WHEN i_task_type_id = pk_alert_constant.g_task_monitoring THEN
                pk_monitorization.get_therapeutic_status(i_lang         => i_lang,
                                                         i_prof         => i_prof,
                                                         i_id_request   => i_request_id,
                                                         o_description  => o_description,
                                                         o_instructions => o_instructions,
                                                         o_flg_status   => o_flg_status);
            
            WHEN i_task_type_id = pk_alert_constant.g_task_sr_procedures THEN
                pk_sr_planning.get_therapeutic_status(i_lang         => i_lang,
                                                      i_prof         => i_prof,
                                                      i_id_request   => i_request_id,
                                                      o_description  => o_description,
                                                      o_instructions => o_instructions,
                                                      o_flg_status   => o_flg_status);
            
            WHEN i_task_type_id = pk_alert_constant.g_task_inp_positioning THEN
                pk_pbl_inp_positioning.get_therapeutic_status(i_lang         => i_lang,
                                                              i_prof         => i_prof,
                                                              i_id_request   => i_request_id,
                                                              o_description  => o_description,
                                                              o_instructions => o_instructions,
                                                              o_flg_status   => o_flg_status);
            
            WHEN i_task_type_id = pk_alert_constant.g_task_inp_hidrics THEN
                pk_inp_hidrics_pbl.get_therapeutic_status(i_lang         => i_lang,
                                                          i_prof         => i_prof,
                                                          i_id_request   => i_request_id,
                                                          o_description  => o_description,
                                                          o_instructions => o_instructions,
                                                          o_flg_status   => o_flg_status);
            
            WHEN i_task_type_id IN (pk_alert_constant.g_task_med_local, pk_alert_constant.g_task_med_local_op) THEN
                pk_alert_exceptions.raise_error(error_name_in => pk_icnp_constant.g_excep_not_implemented,
                                                text_in       => 'There is no API to get the therapeutic status for the medication tasks');
            
            WHEN i_task_type_id IN (pk_alert_constant.g_task_imaging_exams, pk_alert_constant.g_task_other_exams) THEN
                pk_alert_exceptions.raise_error(error_name_in => pk_icnp_constant.g_excep_not_implemented,
                                                text_in       => 'There is no API to get the therapeutic status for the exam tasks');
            
            WHEN i_task_type_id = pk_alert_constant.g_task_lab_tests THEN
                DECLARE
                    l_dump       VARCHAR2(4000);
                    l_flg_status VARCHAR2(4000);
                
                BEGIN
                    IF NOT pk_lab_tests_external_api_db.get_lab_test_task_description(i_lang             => i_lang,
                                                                                      i_prof             => i_prof,
                                                                                      i_task_request     => i_request_id,
                                                                                      o_task_desc        => o_description,
                                                                                      o_task_status_desc => l_dump,
                                                                                      o_error            => l_error)
                    THEN
                        pk_icnp_util.raise_unexpected_error('pk_lab_tests_core.get_lab_test_order', l_error);
                    END IF;
                
                    IF NOT pk_lab_tests_external_api_db.get_lab_test_status(i_lang          => i_lang,
                                                                            i_prof          => i_prof,
                                                                            i_task_request  => i_request_id,
                                                                            o_flg_status    => l_flg_status,
                                                                            o_status_string => l_dump,
                                                                            o_error         => l_error)
                    THEN
                        pk_icnp_util.raise_unexpected_error('pk_lab_tests_core.get_lab_test_order', l_error);
                    END IF;
                
                    o_instructions := NULL;
                    o_flg_status   := CASE l_flg_status
                                          WHEN pk_alert_constant.g_analysis_det_canc THEN
                                           pk_alert_constant.g_no
                                          ELSE
                                           pk_alert_constant.g_yes
                                      END;
                END;
            
            ELSE
                pk_alert_exceptions.raise_error(error_name_in => pk_icnp_constant.g_excep_not_implemented,
                                                text_in       => 'There is no API to get the therapeutic status for the task ' ||
                                                                 i_task_type_id);
        END CASE;
    
    END get_sugg_task_info;

    /**
     * Gets the description of a task that is associated with a therapeutic attitude.
     *
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_request_id The identifier of the external request.
     * @param i_task_type_id Identifier of the external task type.
     *
     * @return The description of a task that is associated with a therapeutic 
     *         attitude.
     * 
     * @author Joao Martins
     * @version (?)
     * @since (?)
    */
    FUNCTION get_sugg_task_description
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_request_id   IN icnp_suggest_interv.id_req%TYPE,
        i_task_type_id IN icnp_suggest_interv.id_task_type%TYPE
    ) RETURN VARCHAR2 IS
        l_description VARCHAR2(4000);
        l_dump        VARCHAR2(4000);
    
    BEGIN
        get_sugg_task_info(i_lang         => i_lang,
                           i_prof         => i_prof,
                           i_request_id   => i_request_id,
                           i_task_type_id => i_task_type_id,
                           o_description  => l_description,
                           o_instructions => l_dump,
                           o_flg_status   => l_dump);
    
        RETURN l_description;
    
    END get_sugg_task_description;

    /**
     * Gets the instructions of a task that is associated with a therapeutic 
     * attitude.
     *
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_request_id The identifier of the external request.
     * @param i_task_type_id Identifier of the external task type.
     *
     * @return The instructions of a task that is associated with a therapeutic 
     *         attitude.
     * 
     * @author Joao Martins
     * @version (?)
     * @since (?)
    */
    FUNCTION get_sugg_task_instructions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_request_id   IN icnp_suggest_interv.id_req%TYPE,
        i_task_type_id IN icnp_suggest_interv.id_task_type%TYPE
    ) RETURN VARCHAR2 IS
        l_instructions VARCHAR2(4000);
        l_dump         VARCHAR2(4000);
    
    BEGIN
        get_sugg_task_info(i_lang         => i_lang,
                           i_prof         => i_prof,
                           i_request_id   => i_request_id,
                           i_task_type_id => i_task_type_id,
                           o_description  => l_dump,
                           o_instructions => l_instructions,
                           o_flg_status   => l_dump);
    
        RETURN l_instructions;
    
    END get_sugg_task_instructions;

    /**
     * Gets the status of a task that is associated with a therapeutic attitude.
     *
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_request_id The identifier of the external request.
     * @param i_task_type_id Identifier of the external task type.
     *
     * @return The status of a task that is associated with a therapeutic 
     *         attitude.
     * 
     * @author Joao Martins
     * @version (?)
     * @since (?)
    */
    FUNCTION get_sugg_task_status
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_request_id   IN icnp_suggest_interv.id_req%TYPE,
        i_task_type_id IN icnp_suggest_interv.id_task_type%TYPE
    ) RETURN VARCHAR2 IS
        l_status VARCHAR2(4000);
        l_dump   VARCHAR2(4000);
    
    BEGIN
        get_sugg_task_info(i_lang         => i_lang,
                           i_prof         => i_prof,
                           i_request_id   => i_request_id,
                           i_task_type_id => i_task_type_id,
                           o_description  => l_dump,
                           o_instructions => l_dump,
                           o_flg_status   => l_status);
    
        RETURN l_status;
    
    END get_sugg_task_status;

    --------------------------------------------------------------------------------
    -- METHODS [GET SUGGESTION ROW]
    --------------------------------------------------------------------------------

    /**
     * Gets the suggestion data (icnp_suggest_interv rows) of all the suggestion
     * identifiers given as input parameter.
     *
     * @param i_sugg_ids Collection with the suggestion identifiers.
     * 
     * @return Collection with the suggestion data (icnp_suggest_interv rows).
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 20/Jul/2011 (v2.6.1)
    */
    FUNCTION get_sugg_rows(i_sugg_ids IN table_number) RETURN ts_icnp_suggest_interv.icnp_suggest_interv_tc IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'get_sugg_rows';
        l_sugg_row_coll ts_icnp_suggest_interv.icnp_suggest_interv_tc;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        SELECT isi.* BULK COLLECT
          INTO l_sugg_row_coll
          FROM icnp_suggest_interv isi
         WHERE isi.id_icnp_sug_interv IN (SELECT /*+opt_estimate(table t rows=1)*/
                                           t.column_value id_icnp_sug_interv
                                            FROM TABLE(i_sugg_ids) t);
    
        RETURN l_sugg_row_coll;
    
    END get_sugg_rows;

    /**
     * Gets the suggestion data (icnp_suggest_interv rows) of all the suggestion
     * identifiers that are stored in the collection given as input parameter. The
     * collection has the suggestion and the intervention identifiers.
     *
     * @param i_interv_suggested_coll Collection with the suggestion and the 
     *                                intervention identifiers.
     * 
     * @return Collection with the suggestion data (icnp_suggest_interv rows).
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 20/Jul/2011 (v2.6.1)
    */
    FUNCTION get_sugg_rows(i_interv_suggested_coll IN pk_icnp_type.t_interv_suggested_coll)
        RETURN ts_icnp_suggest_interv.icnp_suggest_interv_tc IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'get_sugg_rows';
        l_sugg_row_coll        ts_icnp_suggest_interv.icnp_suggest_interv_tc;
        l_interv_suggested_rec pk_icnp_type.t_interv_suggested_rec;
        l_sugg_ids             table_number := table_number();
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Build a collection with the suggestion identifiers
        log_debug('i_interv_suggested_coll.count: ' || i_interv_suggested_coll.count, c_func_name);
        FOR i IN 1 .. i_interv_suggested_coll.count
        LOOP
            l_interv_suggested_rec := i_interv_suggested_coll(i);
            l_sugg_ids.extend;
            l_sugg_ids(l_sugg_ids.count) := l_interv_suggested_rec.id_icnp_sug_interv;
        END LOOP;
    
        -- Gets the suggestion rows of all the suggestion identifiers
        l_sugg_row_coll := get_sugg_rows(i_sugg_ids => l_sugg_ids);
    
        RETURN l_sugg_row_coll;
    
    END get_sugg_rows;

    /**
     * Gets the suggestion data (icnp_suggest_interv rows) of all the suggestions
     * of a given type and with a given request identifier. The request identifiers
     * are primary keys of other ALERT areas, like for example, medication, 
     * procedures, etc.
     *
     * @param i_request_ids Collection with the external request identifiers.
     * @param i_task_type_id Identifier of the external tasks type.
     * 
     * @return Collection with the suggestion data (icnp_suggest_interv rows).
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 20/Jul/2011 (v2.6.1)
    */
    FUNCTION get_sugg_rows
    (
        i_request_ids  IN table_number,
        i_task_type_id IN icnp_suggest_interv.id_task_type%TYPE
    ) RETURN ts_icnp_suggest_interv.icnp_suggest_interv_tc IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'get_sugg_rows';
        l_sugg_row_coll ts_icnp_suggest_interv.icnp_suggest_interv_tc;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        SELECT isi.* BULK COLLECT
          INTO l_sugg_row_coll
          FROM icnp_suggest_interv isi
         WHERE isi.id_req IN (SELECT /*+opt_estimate(table t rows=1)*/
                               t.column_value id_req
                                FROM TABLE(i_request_ids) t)
           AND isi.id_task_type = i_task_type_id;
    
        RETURN l_sugg_row_coll;
    
    END get_sugg_rows;

    /**
     * Gets the suggestion data (icnp_suggest_interv row) of a given suggestion
     * identifier. This method should be used only when we already have a collection 
     * with suggestion rows. This way we avoid quering again the database, improving
     * the performance.
     * 
     * @param l_sugg_row_coll Collection with the suggestion rows.
     * @param i_sug_interv_id Identifier of the suggestion that we want to retrive 
     *                        from the collection.
     * 
     * @return The suggestion data (icnp_suggest_interv row).
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 22/Jul/2011 (v2.6.1)
    */
    FUNCTION get_sugg_row
    (
        l_sugg_row_coll ts_icnp_suggest_interv.icnp_suggest_interv_tc,
        i_sug_interv_id IN icnp_suggest_interv.id_icnp_sug_interv%TYPE
    ) RETURN icnp_suggest_interv%ROWTYPE IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'get_sugg_row';
        l_sugg_row icnp_suggest_interv%ROWTYPE;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Traverse each collection element to find a suggestion with the given 
        -- identifier
        FOR i IN 1 .. l_sugg_row_coll.count
        LOOP
            l_sugg_row := l_sugg_row_coll(i);
        
            IF l_sugg_row.id_icnp_sug_interv = i_sug_interv_id
            THEN
                RETURN l_sugg_row;
            END IF;
        END LOOP;
    
        -- When no row is found raise an exception
        pk_alert_exceptions.raise_error(error_name_in => pk_icnp_constant.g_excep_count_mismatch,
                                        text_in       => 'No row with the identifier ' || i_sug_interv_id ||
                                                         ' was found in the collection');
    
    END get_sugg_row;

    --------------------------------------------------------------------------------
    -- METHODS [CREATE]
    --------------------------------------------------------------------------------

    /**
     * Creates history records for all the suggestions given as input parameter.
     * It is important to guarantee that before each update of a suggestion 
     * record, a copy of the original record is persisted. This is the mechanism we 
     * have to present to the user all the changes made in the record through time.
     *
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_sugg_coll Suggestion records whose history will be created.
     * 
     * @author Joao Martins
     * @version 1.0
     * @since 2011/01/21 (v2.5.1.3)
     * 
     * @author Luis Oliveira
     * @version 1.1
     * @since 20/Jul/2011 (v2.6.1)
    */
    PROCEDURE create_sugg_hist
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_sugg_coll IN ts_icnp_suggest_interv.icnp_suggest_interv_tc
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'create_sugg_hist';
        l_sugg_row         icnp_suggest_interv%ROWTYPE;
        l_hist_row_coll    ts_icnp_suggest_interv_hist.icnp_suggest_interv_hist_tc;
        l_hist_row         icnp_suggest_interv_hist%ROWTYPE;
        l_sugg_rowids_coll table_varchar;
        l_error            t_error_out;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- for each retrieved record...
        FOR i IN i_sugg_coll.first .. i_sugg_coll.last
        LOOP
            -- current record
            l_sugg_row := i_sugg_coll(i);
            -- build history record
            SELECT seq_icnp_suggest_interv_hist.nextval
              INTO l_hist_row.id_icnp_sug_interv_hist
              FROM dual;
            l_hist_row.id_icnp_sug_interv  := l_sugg_row.id_icnp_sug_interv;
            l_hist_row.id_req              := l_sugg_row.id_req;
            l_hist_row.id_task             := l_sugg_row.id_task;
            l_hist_row.id_task_type        := l_sugg_row.id_task_type;
            l_hist_row.id_composition      := l_sugg_row.id_composition;
            l_hist_row.id_patient          := l_sugg_row.id_patient;
            l_hist_row.id_episode          := l_sugg_row.id_episode;
            l_hist_row.flg_status          := l_sugg_row.flg_status;
            l_hist_row.id_prof_last_update := l_sugg_row.id_prof_last_update;
            l_hist_row.dt_last_update      := l_sugg_row.dt_last_update;
            l_hist_row.id_icnp_epis_interv := l_sugg_row.id_icnp_epis_interv;
            l_hist_row.create_user         := l_sugg_row.create_user;
            l_hist_row.create_time         := l_sugg_row.create_time;
            l_hist_row.create_institution  := l_sugg_row.create_institution;
            l_hist_row.update_user         := l_sugg_row.update_user;
            l_hist_row.update_time         := l_sugg_row.update_time;
            l_hist_row.update_institution  := l_sugg_row.update_institution;
            l_hist_row.flg_status_rel      := l_sugg_row.flg_status_rel;
            -- add history record to collection
            l_hist_row_coll(l_hist_row_coll.count) := l_hist_row;
        END LOOP;
    
        -- Persist the data into the database and brodcast the update through the data 
        -- governace mechanism
        ts_icnp_suggest_interv_hist.ins(rows_in => l_hist_row_coll, rows_out => l_sugg_rowids_coll);
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'ICNP_SUGGEST_INTERV_HIST',
                                      i_rowids     => l_sugg_rowids_coll,
                                      o_error      => l_error);
    
    END create_sugg_hist;

    /**
     * Creates therapeutic attitudes (icnp suggestions) for a given ALERT area and 
     * task identifiers. A configuration table stores the suggestions that should
     * be created for each task / ALERT module.
     *
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_episode_id The episode identifier.
     * @param i_request_ids Collection with the external request identifiers.
     * @param i_task_ids  Collection with the tasks identifiers, like for example,
     *                    the identifier of the lab test, exam, etc.
     * @param i_task_type_id Identifier of the external tasks type (ALERT modules), 
     *                       like for example, lab tests, exams, etc.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * @param o_id_icnp_sug_interv Collection with the identifiers of the created 
     *                             suggestions.
     *
     * @author Joao Martins
     * @version 1.0
     * @since 2011/01/19 (v2.5.1.3)
     * 
     * @author Luis Oliveira
     * @version 1.1
     * @since 20/Jul/2011 (v2.6.1)
    */
    PROCEDURE create_suggs
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode_id         IN episode.id_episode%TYPE,
        i_request_ids        IN table_number,
        i_task_ids           IN table_number,
        i_task_type_id       IN task_type.id_task_type%TYPE,
        i_sysdate_tstz       IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_id_icnp_sug_interv OUT table_number
    ) IS
        l_id_icnp_sug_interv table_number := table_number();
        l_patient_id         patient.id_patient%TYPE;
        l_rows               table_varchar;
        l_error              t_error_out;
    
        -- Gets the suggestions that are related with a given task
        CURSOR cur_data
        (
            i_task      icnp_suggest_interv.id_task%TYPE,
            i_task_type icnp_suggest_interv.id_task_type%TYPE
        ) IS
            SELECT itcsi.id_composition
              FROM icnp_task_comp_soft_inst itcsi
              JOIN icnp_task_composition itc
                ON itc.id_task = itcsi.id_task
              JOIN icnp_composition ic
                ON ic.id_composition = itc.id_composition
               AND itc.id_task_type = itcsi.id_task_type
               AND itc.id_composition = itcsi.id_composition
             WHERE itcsi.id_task = i_task
               AND itcsi.id_task_type = i_task_type
               AND nvl(itcsi.id_institution, 0) IN (0, i_prof.institution)
               AND nvl(itcsi.id_software, 0) IN (0, i_prof.software)
               AND itcsi.flg_available = pk_alert_constant.g_yes
               AND itc.flg_available = pk_alert_constant.g_yes
               AND ic.flg_available = pk_alert_constant.g_yes;
    
    BEGIN
        /* The input parameter i_diag_ids is already being checked in pk_icnp_fo_api_db. 
         * When invoked from this package there is no need to raise an exception.
        */
        IF pk_icnp_util.is_table_empty(i_request_ids)
           OR pk_icnp_util.is_table_empty(i_task_ids)
        THEN
            RETURN;
        END IF;
    
        -- Checks if the therapeutic attitudes should be created when are the nurses 
        -- making the request.
        -- Some categories can´t generate nursing intervention suggestions.
        IF pk_sysconfig.get_config(pk_icnp_constant.g_config_nurse_trigg_ther_att, i_prof.institution, i_prof.software) =
           pk_alert_constant.g_no
           AND pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof) = pk_alert_constant.g_cat_type_nurse
        THEN
            RETURN;
        END IF;
    
        -- Get the patient identifier
        l_patient_id := pk_episode.get_id_patient(i_episode_id);
    
        -- Loop over requests
        FOR i IN 1 .. i_request_ids.count
        LOOP
            -- Insert data
            FOR elem IN cur_data(i_task_ids(i), i_task_type_id)
            LOOP
                l_id_icnp_sug_interv.extend;
                l_id_icnp_sug_interv(l_id_icnp_sug_interv.count) := ts_icnp_suggest_interv.next_key;
            
                ts_icnp_suggest_interv.ins(id_icnp_sug_interv_in  => l_id_icnp_sug_interv(l_id_icnp_sug_interv.count),
                                           id_req_in              => i_request_ids(i),
                                           id_task_in             => i_task_ids(i),
                                           id_task_type_in        => i_task_type_id,
                                           id_composition_in      => elem.id_composition,
                                           id_patient_in          => l_patient_id,
                                           id_episode_in          => i_episode_id,
                                           flg_status_in          => pk_icnp_constant.g_sug_interv_status_suggested,
                                           id_prof_last_update_in => i_prof.id,
                                           dt_last_update_in      => i_sysdate_tstz,
                                           rows_out               => l_rows);
            
                -- Insert alert
                IF NOT pk_alerts.insert_sys_alert_event(i_lang                => i_lang,
                                                        i_prof                => i_prof,
                                                        i_sys_alert           => pk_icnp_constant.g_alert_therapeutic_attitudes,
                                                        i_id_episode          => i_episode_id,
                                                        i_id_record           => i_request_ids(i),
                                                        i_dt_record           => i_sysdate_tstz,
                                                        i_id_professional     => i_prof.id,
                                                        i_id_room             => NULL,
                                                        i_id_clinical_service => NULL,
                                                        i_flg_type_dest       => NULL,
                                                        i_replace1            => i_task_type_id,
                                                        o_error               => l_error)
                THEN
                    pk_icnp_util.raise_unexpected_error('pk_alerts.insert_sys_alert_event', l_error);
                END IF;
            END LOOP data;
        END LOOP requests;
    
        -- Brodcast the update through the data governace mechanism
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'ICNP_SUGGEST_INTERV',
                                      i_rowids     => l_rows,
                                      o_error      => l_error);
    
        -- Set the output parameters
        IF l_id_icnp_sug_interv.count > 0
        THEN
            o_id_icnp_sug_interv := l_id_icnp_sug_interv;
        END IF;
    
    END create_suggs;

    /**
     * Creates a therapeutic attitude (icnp suggestion) for a given ALERT area and 
     * task identifier. A configuration table stores the suggestions that should
     * be created for each task / ALERT module.
     *
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_episode_id The episode identifier.
     * @param i_request_id Identifier of the external request.
     * @param i_task_id Identifier of the task, like for example, the identifier of 
     *                  the lab test, exam, etc.
     * @param i_task_type_id Identifier of the external task type (ALERT modules), 
     *                       like for example, lab tests, exams, etc.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * @param o_id_icnp_sug_interv Collection with the identifiers of the created 
     *                             suggestions.
     *
     * @author Luis Oliveira
     * @version 1.1
     * @since 20/Jul/2011 (v2.6.1)
    */
    PROCEDURE create_sugg
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode_id         IN episode.id_episode%TYPE,
        i_request_id         IN icnp_suggest_interv.id_req%TYPE,
        i_task_id            IN icnp_suggest_interv.id_task%TYPE,
        i_task_type_id       IN icnp_suggest_interv.id_task_type%TYPE,
        i_sysdate_tstz       IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_id_icnp_sug_interv OUT table_number
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'create_sugg';
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Resolve the intervention
        create_suggs(i_lang               => i_lang,
                     i_prof               => i_prof,
                     i_episode_id         => i_episode_id,
                     i_request_ids        => table_number(i_request_id),
                     i_task_ids           => table_number(i_task_id),
                     i_task_type_id       => i_task_type_id,
                     i_sysdate_tstz       => i_sysdate_tstz,
                     o_id_icnp_sug_interv => o_id_icnp_sug_interv);
    
    END create_sugg;

    --------------------------------------------------------------------------------
    -- METHODS [ALERTS]
    --------------------------------------------------------------------------------

    /**
     * Deletes a therapeutic attitude alert that matches a given request identifier / 
     * ALERT module.
     *
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_request_id Identifier of the external request.
     * @param i_task_type_id Identifier of the external task type (ALERT modules), 
     *                       like for example, lab tests, exams, etc.
     * 
     * @author Luis Oliveira
     * @version 1.1
     * @since 20/Jul/2011 (v2.6.1)
    */
    PROCEDURE delete_alert
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_request_id   IN icnp_suggest_interv.id_req%TYPE,
        i_task_type_id IN icnp_suggest_interv.id_task_type%TYPE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'delete_alert';
        l_alerts sys_alert_event%ROWTYPE;
        l_error  t_error_out;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Find the alert that matches a given request identifier / ALERT module
        -- and delete it
        BEGIN
            SELECT *
              INTO l_alerts
              FROM sys_alert_event sae
             WHERE sae.id_sys_alert = pk_icnp_constant.g_alert_therapeutic_attitudes
               AND sae.id_record = i_request_id
               AND sae.replace1 = i_task_type_id;
        
            IF NOT pk_alerts.delete_sys_alert_event(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_sys_alert_event => l_alerts,
                                                    o_error           => l_error)
            THEN
                pk_icnp_util.raise_unexpected_error('pk_alerts.delete_sys_alert_event', l_error);
            END IF;
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
    END delete_alert;

    --------------------------------------------------------------------------------
    -- METHODS [UPDATE SUGGESTION ROW]
    --------------------------------------------------------------------------------

    /**
     * Updates a set of suggestion records (icnp_suggest_interv rows). Each record
     * of the collection is a icnp_suggest_interv row already with the data that 
     * should be persisted in the database. The ALERT data governance mechanism
     * demands that whenever an update is executed an event with the updated rows is 
     * broadcasted.
     *
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_sugg_row_coll Collection of icnp_suggest_interv rows already with 
     *                        the data that should be persisted in the database.
     * 
     * @param o_sugg_rowids_coll Collection with the updated icnp_epis_intervention 
     *                           rowids.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 20/Jul/2011 (v2.6.1)
    */
    PROCEDURE update_sugg_rows
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_sugg_row_coll    IN ts_icnp_suggest_interv.icnp_suggest_interv_tc,
        o_sugg_rowids_coll OUT table_varchar
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'update_sugg_rows';
        l_sugg_rowids_coll table_varchar;
        l_error            t_error_out;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Check the input parameters
        IF pk_icnp_util.is_table_empty(i_sugg_row_coll)
        THEN
            pk_alert_exceptions.raise_error(error_name_in => pk_icnp_constant.g_excep_inv_input_params,
                                            text_in       => 'The table with the suggestion rows (i_sugg_row_coll) given as input parameter is empty');
        END IF;
    
        -- Persist the data into the database and brodcast the update through the data 
        -- governace mechanism
        ts_icnp_suggest_interv.upd(col_in            => i_sugg_row_coll,
                                   ignore_if_null_in => FALSE,
                                   rows_out          => l_sugg_rowids_coll);
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'ICNP_SUGGEST_INTERV',
                                      i_rowids     => l_sugg_rowids_coll,
                                      o_error      => l_error);
    
        -- Set the output parameters
        o_sugg_rowids_coll := l_sugg_rowids_coll;
    
    END update_sugg_rows;

    --------------------------------------------------------------------------------
    -- METHODS [CHANGE ROW COLUMNS FOR UPDATE STATUS]
    --------------------------------------------------------------------------------

    /**
     * Updates all the necessary columns of an suggestion record (icnp_suggest_interv
     * row) when only the status needs to be updated.
     * 
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_flg_status The new suggestion status.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * @param io_sugg_row The icnp_suggest_interv row whose columns will be updated.
     *                    This is an input/output argument because the suggestion
     *                    record can be updated too in other methods.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 20/Jul/2011 (v2.6.1)
    */
    PROCEDURE change_sugg_row_status_cols
    (
        i_prof         IN profissional,
        i_flg_status   IN icnp_suggest_interv.flg_status%TYPE,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE,
        io_sugg_row    IN OUT NOCOPY icnp_suggest_interv%ROWTYPE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'change_sugg_row_status_cols';
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Update the columns of the suggestion record
        io_sugg_row.flg_status          := i_flg_status;
        io_sugg_row.id_prof_last_update := i_prof.id;
        io_sugg_row.dt_last_update      := i_sysdate_tstz;
    
    END change_sugg_row_status_cols;

    /**
     * Updates all the necessary columns of a suggestion record (icnp_suggest_interv
     * row) when the suggestion is accepted.
     * 
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_episode_id The episode identifier.
     * @param i_sug_interv_id The suggestion identifier.
     * @param i_epis_interv_id The icnp intervention that we want to associated with
     *                         the suggestion.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * @param io_sugg_row The icnp_suggest_interv row whose columns will be updated.
     *                    This is an input/output argument because the suggestion
     *                    record can be updated too in other methods.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 20/Jul/2011 (v2.6.1)
    */
    PROCEDURE change_sugg_row_accept_cols
    (
        i_prof           IN profissional,
        i_episode_id     IN icnp_suggest_interv.id_episode%TYPE,
        i_sug_interv_id  IN icnp_suggest_interv.id_icnp_sug_interv%TYPE,
        i_epis_interv_id IN icnp_suggest_interv.id_icnp_epis_interv%TYPE,
        i_sysdate_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE,
        io_sugg_row      IN OUT NOCOPY icnp_suggest_interv%ROWTYPE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'change_sugg_row_accept_cols';
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Update the columns of the suggestion record
        io_sugg_row.id_icnp_sug_interv  := i_sug_interv_id;
        io_sugg_row.id_icnp_epis_interv := i_epis_interv_id;
        io_sugg_row.id_episode          := i_episode_id;
        io_sugg_row.flg_status          := pk_icnp_constant.g_sug_interv_status_accepted;
        io_sugg_row.id_prof_last_update := i_prof.id;
        io_sugg_row.dt_last_update      := i_sysdate_tstz;
    
    END change_sugg_row_accept_cols;

    --------------------------------------------------------------------------------
    -- METHODS [UPDATE SUGGESTION STATUS]
    --------------------------------------------------------------------------------

    /**
     * Rejects all the suggestions with identifiers that are in the collection given 
     * as input parameter (i_sugg_ids). When the suggestion is rejected, the 
     * corresponding alert should be deleted.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_sugg_ids Collection with the suggestion identifiers.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     *
     * @author Luis Oliveira
     * @version 1.1
     * @since 27/Jul/2011 (v2.6.1)
    */
    PROCEDURE set_suggs_status_reject
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_sugg_ids     IN table_number,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'set_suggs_status_cancel';
        l_sugg_coll        ts_icnp_suggest_interv.icnp_suggest_interv_tc;
        l_sugg_row         icnp_suggest_interv%ROWTYPE;
        l_sugg_rowids_coll table_varchar;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        /* The input parameter i_request_ids is already being checked in pk_icnp_fo_api_db. 
         * When invoked from this package there is no need to raise an exception.
        */
        IF pk_icnp_util.is_table_empty(i_sugg_ids)
        THEN
            RETURN;
        END IF;
    
        -- Gets the suggestion rows of the request ids
        l_sugg_coll := get_sugg_rows(i_sugg_ids => i_sugg_ids);
    
        -- Creates history records for all the suggestions
        create_sugg_hist(i_lang => i_lang, i_prof => i_prof, i_sugg_coll => l_sugg_coll);
    
        -- Make the necessary changes to each suggestion record in the collection
        -- and delete the therapeutic attitude alert
        FOR i IN l_sugg_coll.first .. l_sugg_coll.last
        LOOP
            l_sugg_row := l_sugg_coll(i);
        
            change_sugg_row_status_cols(i_prof         => i_prof,
                                        i_flg_status   => pk_icnp_constant.g_sug_interv_status_rejected,
                                        i_sysdate_tstz => i_sysdate_tstz,
                                        io_sugg_row    => l_sugg_row);
        
            l_sugg_coll(i) := l_sugg_row;
        
            delete_alert(i_lang         => i_lang,
                         i_prof         => i_prof,
                         i_request_id   => l_sugg_row.id_req,
                         i_task_type_id => l_sugg_row.id_task_type);
        END LOOP;
    
        -- Persist the data into the database
        update_sugg_rows(i_lang             => i_lang,
                         i_prof             => i_prof,
                         i_sugg_row_coll    => l_sugg_coll,
                         o_sugg_rowids_coll => l_sugg_rowids_coll);
    
    END set_suggs_status_reject;

    /**
     * Accepts all the suggestions with identifiers that are in the collection given 
     * as input parameter (i_interv_suggested_coll). The collection is composed by
     * records with the identifier of the suggestion and the identifier of the 
     * intervention that we want to associated with the suggestion.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_episode_id The episode identifier.
     * @param i_interv_suggested_coll Collection with the suggestion and the intervention 
     *                                identifier.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     *
     * @author Joao Martins
     * @version 1.0
     * @since 2011/01/21 (v2.5.1.3)
     *
     * @author Luis Oliveira
     * @version 1.1
     * @since 20/Jul/2011 (v2.6.1)
    */
    PROCEDURE set_suggs_status_accept
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode_id            IN icnp_suggest_interv.id_episode%TYPE,
        i_interv_suggested_coll IN pk_icnp_type.t_interv_suggested_coll,
        i_sysdate_tstz          IN TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'set_suggs_status_accept';
        l_interv_suggested_rec pk_icnp_type.t_interv_suggested_rec;
        l_sugg_row_coll        ts_icnp_suggest_interv.icnp_suggest_interv_tc;
        l_sugg_row             icnp_suggest_interv%ROWTYPE;
        l_sugg_rowids_coll     table_varchar;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Gets the suggestion rows of the request ids
        l_sugg_row_coll := get_sugg_rows(i_interv_suggested_coll => i_interv_suggested_coll);
    
        -- Creates history records for all the suggestions
        create_sugg_hist(i_lang => i_lang, i_prof => i_prof, i_sugg_coll => l_sugg_row_coll);
    
        -- Make the necessary changes to each suggestion record in the collection
        FOR i IN 1 .. i_interv_suggested_coll.count
        LOOP
            l_interv_suggested_rec := i_interv_suggested_coll(i);
            l_sugg_row             := get_sugg_row(l_sugg_row_coll => l_sugg_row_coll,
                                                   i_sug_interv_id => l_interv_suggested_rec.id_icnp_sug_interv);
        
            change_sugg_row_accept_cols(i_prof           => i_prof,
                                        i_episode_id     => i_episode_id,
                                        i_sug_interv_id  => l_interv_suggested_rec.id_icnp_sug_interv,
                                        i_epis_interv_id => l_interv_suggested_rec.id_icnp_epis_interv,
                                        i_sysdate_tstz   => i_sysdate_tstz,
                                        io_sugg_row      => l_sugg_row);
        
            FOR a IN 1 .. l_sugg_row_coll.count
            LOOP
                IF l_sugg_row_coll(a).id_icnp_sug_interv = l_sugg_row.id_icnp_sug_interv
                THEN
                    l_sugg_row_coll(a) := l_sugg_row;
                    EXIT;
                END IF;
            END LOOP;
        
            delete_alert(i_lang         => i_lang,
                         i_prof         => i_prof,
                         i_request_id   => l_sugg_row.id_req,
                         i_task_type_id => l_sugg_row.id_task_type);
        END LOOP;
    
        -- Persist the data into the database
        update_sugg_rows(i_lang             => i_lang,
                         i_prof             => i_prof,
                         i_sugg_row_coll    => l_sugg_row_coll,
                         o_sugg_rowids_coll => l_sugg_rowids_coll);
    
    END set_suggs_status_accept;

    /**
     * Cancels all the suggestions that are in the collection given as input parameter.
     *
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_sugg_coll Collection with the suggestion records to cancel.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * 
     * @author Luis Oliveira
     * @version 1.1
     * @since 20/Jul/2011 (v2.6.1)
    */
    PROCEDURE set_suggs_status_cancel_int
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_sugg_coll    IN ts_icnp_suggest_interv.icnp_suggest_interv_tc,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'set_suggs_status_cancel_int';
        l_sugg_coll        ts_icnp_suggest_interv.icnp_suggest_interv_tc;
        l_sugg_row         icnp_suggest_interv%ROWTYPE;
        l_sugg_rowids_coll table_varchar;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- We need to update the collection, so a copy of the collection needs to be made
        l_sugg_coll := i_sugg_coll;
    
        -- Creates history records for all the suggestions
        create_sugg_hist(i_lang => i_lang, i_prof => i_prof, i_sugg_coll => l_sugg_coll);
    
        -- Make the necessary changes to each suggestion record in the collection
        -- and delete the therapeutic attitude alert
        FOR i IN l_sugg_coll.first .. l_sugg_coll.last
        LOOP
            l_sugg_row := l_sugg_coll(i);
        
            change_sugg_row_status_cols(i_prof         => i_prof,
                                        i_flg_status   => pk_icnp_constant.g_sug_interv_status_canceled,
                                        i_sysdate_tstz => i_sysdate_tstz,
                                        io_sugg_row    => l_sugg_row);
        
            l_sugg_coll(i) := l_sugg_row;
        
            delete_alert(i_lang         => i_lang,
                         i_prof         => i_prof,
                         i_request_id   => l_sugg_row.id_req,
                         i_task_type_id => l_sugg_row.id_task_type);
        END LOOP;
    
        -- Persist the data into the database
        update_sugg_rows(i_lang             => i_lang,
                         i_prof             => i_prof,
                         i_sugg_row_coll    => l_sugg_coll,
                         o_sugg_rowids_coll => l_sugg_rowids_coll);
    
    END set_suggs_status_cancel_int;

    /**
     * Cancels all the suggestions with identifiers that are in the collection given 
     * as input parameter.
     *
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_sugg_ids Collection with the suggestion identifiers.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * 
     * @author Luis Oliveira
     * @version 1.1
     * @since 20/Jul/2011 (v2.6.1)
    */
    PROCEDURE set_suggs_status_cancel
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_sugg_ids     IN table_number,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'set_suggs_status_cancel';
        l_sugg_row_coll ts_icnp_suggest_interv.icnp_suggest_interv_tc;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        /* The input parameter i_request_ids is already being checked in pk_icnp_fo_api_db. 
         * When invoked from this package there is no need to raise an exception.
        */
        IF pk_icnp_util.is_table_empty(i_sugg_ids)
        THEN
            RETURN;
        END IF;
    
        -- Gets the suggestion rows of the request ids
        l_sugg_row_coll := get_sugg_rows(i_sugg_ids => i_sugg_ids);
    
        -- Cancel the suggestions
        set_suggs_status_cancel_int(i_lang         => i_lang,
                                    i_prof         => i_prof,
                                    i_sugg_coll    => l_sugg_row_coll,
                                    i_sysdate_tstz => i_sysdate_tstz);
    
    END set_suggs_status_cancel;

    /**
     * Cancels all the suggestions by request identifier / ALERT module (like for example, 
     * lab tests, medication, procedures, etc).
     *
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_request_ids Collection with the external request identifiers.
     * @param i_task_type_id Identifier of the external tasks type.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     *
     * @author Joao Martins
     * @version 1.0
     * @since 2011/01/21 (v2.5.1.3)
     * 
     * @author Luis Oliveira
     * @version 1.1
     * @since 20/Jul/2011 (v2.6.1)
    */
    PROCEDURE set_suggs_status_cancel
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_request_ids  IN table_number,
        i_task_type_id IN icnp_suggest_interv.id_task_type%TYPE,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'set_suggs_status_cancel';
        l_sugg_row_coll ts_icnp_suggest_interv.icnp_suggest_interv_tc;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        /* The input parameter i_request_ids is already being checked in pk_icnp_fo_api_db. 
         * When invoked from this package there is no need to raise an exception.
        */
        IF pk_icnp_util.is_table_empty(i_request_ids)
        THEN
            RETURN;
        END IF;
    
        -- Gets the suggestion rows of the request ids
        l_sugg_row_coll := get_sugg_rows(i_request_ids => i_request_ids, i_task_type_id => i_task_type_id);
    
        -- Not all the requests have suggestion, so the collection could be empty
        IF pk_icnp_util.is_table_empty(l_sugg_row_coll)
        THEN
            RETURN;
        END IF;
    
        -- Cancel the suggestions
        set_suggs_status_cancel_int(i_lang         => i_lang,
                                    i_prof         => i_prof,
                                    i_sugg_coll    => l_sugg_row_coll,
                                    i_sysdate_tstz => i_sysdate_tstz);
    
    END set_suggs_status_cancel;

    /**
     * Cancels a single suggestion by request identifier / ALERT module (like for 
     * example, lab tests, medication, procedures, etc).
     *
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_request_id The identifier of the external request.
     * @param i_task_type_id Identifier of the external task type.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * 
     * @author Luis Oliveira
     * @version 1.1
     * @since 20/Jul/2011 (v2.6.1)
    */
    PROCEDURE set_sugg_status_cancel
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_request_id   IN icnp_suggest_interv.id_req%TYPE,
        i_task_type_id IN icnp_suggest_interv.id_task_type%TYPE,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'set_sugg_status_cancel';
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Cancel the suggestion
        set_suggs_status_cancel(i_lang         => i_lang,
                                i_prof         => i_prof,
                                i_request_ids  => table_number(i_request_id),
                                i_task_type_id => i_task_type_id,
                                i_sysdate_tstz => i_sysdate_tstz);
    
    END set_sugg_status_cancel;

BEGIN
    -- Executes all the instructions needed to correctly initialize the package
    initialize();

END pk_icnp_suggestion;
/
