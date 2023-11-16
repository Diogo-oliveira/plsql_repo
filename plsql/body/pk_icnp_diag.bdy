/*-- Last Change Revision: $Rev: 2027216 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:32 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_icnp_diag IS

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
     * @since 03/Jun/2011
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
    -- METHODS [GET DIAG ROW]
    --------------------------------------------------------------------------------

    /**
     * Gets the diagnosis data (icnp_epis_diagnosis rows) of all the diagnosis
     * identifiers given as input parameter.
     *
     * @param i_diag_ids Collection with the diagnosis identifiers.
     * 
     * @return Collection with the diagnosis data (icnp_epis_diagnosis rows).
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 5/Jun/2011 (v2.6.1)
    */
    FUNCTION get_diag_rows(i_diag_ids IN table_number) RETURN ts_icnp_epis_diagnosis.icnp_epis_diagnosis_tc IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'get_diag_rows';
        l_diag_row_coll ts_icnp_epis_diagnosis.icnp_epis_diagnosis_tc;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        SELECT ied.*
          BULK COLLECT
          INTO l_diag_row_coll
          FROM icnp_epis_diagnosis ied
         WHERE ied.id_icnp_epis_diag IN (SELECT /*+opt_estimate(table t rows=1)*/
                                          t.column_value id_icnp_epis_diag
                                           FROM TABLE(i_diag_ids) t);
    
        RETURN l_diag_row_coll;
    
    END get_diag_rows;

    /**
     * Gets the diagnose data (icnp_epis_diagnosis row) of a given diagnose
     * identifier given as input parameter.
     *
     * @param i_epis_diag_id The diagnose identifier.
     * 
     * @return The diagnose data (icnp_epis_diagnosis row).
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 5/Jun/2011 (v2.6.1)
    */
    FUNCTION get_diag_row(i_epis_diag_id IN icnp_epis_diagnosis.id_icnp_epis_diag%TYPE) RETURN icnp_epis_diagnosis%ROWTYPE IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'get_diag_row';
        l_diag_row icnp_epis_diagnosis%ROWTYPE;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        SELECT ied.*
          INTO l_diag_row
          FROM icnp_epis_diagnosis ied
         WHERE ied.id_icnp_epis_diag = i_epis_diag_id;
    
        RETURN l_diag_row;
    
    END get_diag_row;

    --------------------------------------------------------------------------------
    -- METHODS [CREATE]
    --------------------------------------------------------------------------------

    /**
     * Creates an icnp_epis_diagnosis record based in the input parameters and in some
     * default values that should be set when a new record is created.
     *
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_episode The episode identifier.
     * @param i_patient The patient identifier.
     * @param i_visit The visit identifier.
     * @param i_epis_type The identifier of the type of episode.
     * @param i_diag Identifier of the diagnose to insert.
     * @param i_exp_res Identifier of the expected results for the diagnose.
     * @param i_notes Notes for the diagnose.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * 
     * @return A icnp_epis_diagnosis record prepared to be inserted.
     *
     * @author Luis Oliveira
     * @version 1.0
     * @since 3/Jun/2011
    */
    FUNCTION create_diag_row
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN icnp_epis_diagnosis.id_episode%TYPE,
        i_patient      IN icnp_epis_diagnosis.id_patient%TYPE,
        i_visit        IN icnp_epis_diagnosis.id_visit%TYPE,
        i_epis_type    IN icnp_epis_diagnosis.id_epis_type%TYPE,
        i_diag         IN icnp_epis_diagnosis.id_icnp_epis_diag%TYPE,
        i_exp_res      IN icnp_epis_diagnosis.icnp_compo_reeval%TYPE,
        i_notes        IN icnp_epis_diagnosis.notes%TYPE,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN icnp_epis_diagnosis%ROWTYPE IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'create_diag_row';
        l_diag_row icnp_epis_diagnosis%ROWTYPE;
    
    BEGIN
        log_debug(c_func_name || '(i_lang:' || i_lang || ', i_prof:' || pk_icnp_util.to_string(i_prof) ||
                  ', i_episode:' || i_episode || ', i_patient:' || i_patient || ', i_visit:' || i_visit ||
                  ', i_epis_type:' || i_epis_type || ', i_diag:' || i_diag || ', i_exp_res:' || i_exp_res ||
                  ', i_notes:' || i_notes || ')',
                  c_func_name);
    
        l_diag_row.id_icnp_epis_diag := ts_icnp_epis_intervention.next_key;
        l_diag_row.id_episode        := i_episode;
        l_diag_row.id_visit          := i_visit;
        l_diag_row.id_epis_type      := i_epis_type;
        l_diag_row.id_patient        := i_patient;
        l_diag_row.id_composition    := i_diag;
        IF i_notes IS NULL
        THEN
            l_diag_row.notes := NULL;
        ELSE
            l_diag_row.notes := i_notes;
        END IF;
        IF i_exp_res IS NULL
        THEN
            l_diag_row.icnp_compo_reeval := NULL;
        ELSE
            l_diag_row.icnp_compo_reeval := i_exp_res;
        END IF;
        l_diag_row.id_professional        := i_prof.id;
        l_diag_row.flg_status             := pk_icnp_constant.g_epis_diag_status_active;
        l_diag_row.dt_icnp_epis_diag_tstz := i_sysdate_tstz;
        l_diag_row.flg_executions         := pk_alert_constant.g_no;
        l_diag_row.id_prof_last_update    := i_prof.id;
        l_diag_row.dt_last_update         := i_sysdate_tstz;
    
        RETURN l_diag_row;
    
    END create_diag_row;

    /**
     * Creates an ti_log record based in the input parameters and in some
     * default values that should be set when a new record is created.
     *
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_episode The episode identifier.
     * @param i_diag Identifier of the diagnose that was inserted.
     * @param i_sysdate_tstz Timestamp used when the record icnp_epis_diagnosis was created.
     * 
     * @return A ti_log record prepared to be inserted.
     *
     * @author Luis Oliveira
     * @version 1.0
     * @since 3/Jun/2011
    */
    FUNCTION create_ti_diag_row
    (
        i_prof         IN profissional,
        i_episode      IN ti_log.id_episode%TYPE,
        i_diag         IN ti_log.id_record%TYPE,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN ti_log%ROWTYPE IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'create_ti_diag_row';
        l_ti_log_row ti_log%ROWTYPE;
    
    BEGIN
        log_debug('create_ti_diag_row(i_prof:' || pk_icnp_util.to_string(i_prof) || ', i_episode:' || i_episode ||
                  ', i_diag:' || i_diag || ')',
                  c_func_name);
    
        l_ti_log_row.id_ti_log        := ts_ti_log.next_key;
        l_ti_log_row.id_professional  := i_prof.id;
        l_ti_log_row.id_episode       := i_episode;
        l_ti_log_row.flg_status       := pk_alert_constant.g_active;
        l_ti_log_row.id_record        := i_diag;
        l_ti_log_row.flg_type         := pk_icnp_constant.g_ti_log_type_diag;
        l_ti_log_row.dt_creation_tstz := i_sysdate_tstz;
    
        RETURN l_ti_log_row;
    
    END create_ti_diag_row;

    /**
     * Creates history records for all the diagnosis given as input parameter.
     * It is important to guarantee that before each update on any diagnose record,
     * a copy of the record is persisted. This is the mechanism we have to present 
     * to the user all the changes made in the record through time.
     *
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_diag_coll Diagnosis records whose history will be created.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * @param o_diag_hist  Identifiers list of the created history records.
     *
     * @author Pedro Carneiro
     * @version 2.5.1
     * @since 2010/07/22
    */
    PROCEDURE create_diag_hist
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_diag_coll    IN ts_icnp_epis_diagnosis.icnp_epis_diagnosis_tc,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_diag_hist    OUT table_number
    ) IS
        -- Data structures related with icnp_epis_diagnosis
        l_diag_row icnp_epis_diagnosis%ROWTYPE;
        -- Data structures related with icnp_epis_intervention_hist
        l_diag_hist_row_coll ts_icnp_epis_diagnosis_hist.icnp_epis_diagnosis_hist_tc;
        l_diag_hist_row      icnp_epis_diagnosis_hist%ROWTYPE;
        l_diag_hist_ids      table_number := table_number();
        l_diag_hist_rowids   table_varchar;
        -- Data structures related with error management
        l_error t_error_out;
    
    BEGIN
        -- check input
        IF pk_icnp_util.is_table_empty(i_diag_coll)
        THEN
            o_diag_hist := table_number();
            RETURN;
        END IF;
    
        -- set author and date
        l_diag_hist_row.id_prof_created_hist := i_prof.id;
        l_diag_hist_row.dt_created_hist      := i_sysdate_tstz;
        -- for each retrieved record...
        FOR i IN i_diag_coll.first .. i_diag_coll.last
        LOOP
            -- current record
            l_diag_row := i_diag_coll(i);
            -- build history record
            l_diag_hist_row.id_icnp_epis_diag_hist := ts_icnp_epis_diagnosis_hist.next_key;
            l_diag_hist_row.id_icnp_epis_diag      := l_diag_row.id_icnp_epis_diag;
            l_diag_hist_row.id_composition         := l_diag_row.id_composition;
            l_diag_hist_row.id_professional        := l_diag_row.id_professional;
            l_diag_hist_row.flg_status             := l_diag_row.flg_status;
            l_diag_hist_row.id_episode             := l_diag_row.id_episode;
            l_diag_hist_row.notes                  := l_diag_row.notes;
            l_diag_hist_row.id_prof_close          := l_diag_row.id_prof_close;
            l_diag_hist_row.notes_close            := l_diag_row.notes_close;
            l_diag_hist_row.id_patient             := l_diag_row.id_patient;
            l_diag_hist_row.dt_icnp_epis_diag      := l_diag_row.dt_icnp_epis_diag_tstz;
            l_diag_hist_row.dt_close               := l_diag_row.dt_close_tstz;
            l_diag_hist_row.id_visit               := l_diag_row.id_visit;
            l_diag_hist_row.id_epis_type           := l_diag_row.id_epis_type;
            l_diag_hist_row.flg_executions         := l_diag_row.flg_executions;
            l_diag_hist_row.icnp_compo_reeval      := l_diag_row.icnp_compo_reeval;
            l_diag_hist_row.id_prof_last_update    := l_diag_row.id_prof_last_update;
            l_diag_hist_row.dt_last_update         := l_diag_row.dt_last_update;
            l_diag_hist_row.id_suspend_reason      := l_diag_row.id_suspend_reason;
            l_diag_hist_row.id_suspend_prof        := l_diag_row.id_suspend_prof;
            l_diag_hist_row.suspend_notes          := l_diag_row.suspend_notes;
            l_diag_hist_row.dt_suspend             := l_diag_row.dt_suspend;
            l_diag_hist_row.id_cancel_reason       := l_diag_row.id_cancel_reason;
            l_diag_hist_row.id_cancel_prof         := l_diag_row.id_cancel_prof;
            l_diag_hist_row.cancel_notes           := l_diag_row.cancel_notes;
            l_diag_hist_row.dt_cancel              := l_diag_row.dt_cancel;
            -- add history record to collection
            l_diag_hist_row_coll(i) := l_diag_hist_row;
            -- add history record id to list
            l_diag_hist_ids.extend;
            l_diag_hist_ids(l_diag_hist_ids.last) := l_diag_hist_row.id_icnp_epis_diag_hist;
        END LOOP;
        -- set history
        ts_icnp_epis_diagnosis_hist.ins(rows_in => l_diag_hist_row_coll, rows_out => l_diag_hist_rowids);
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'ICNP_EPIS_DIAGNOSIS_HIST',
                                      i_rowids     => l_diag_hist_rowids,
                                      o_error      => l_error);
        o_diag_hist := l_diag_hist_ids;
    
    END create_diag_hist;

    /**
     * Creates a set of diagnosis records (icnp_epis_diagnosis rows). Each 
     * record of the collection is a icnp_epis_diagnosis row already with the data
     * that should be persisted in the database.
     *
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_diag_coll Collection of icnp_epis_diagnosis rows already with the
     *                    data that should be persisted in the database.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     *
     * @author Luis Oliveira
     * @version 1.1
     * @since 27/Jul/2011 (v2.6.1)
    */
    PROCEDURE create_diags
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_diag_coll    IN ts_icnp_epis_diagnosis.icnp_epis_diagnosis_tc,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        -- Constants
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'change_diag_row_resolve_cols';
        -- Data structures related with ti_log
        l_ti_row_coll ts_ti_log.ti_log_tc;
        l_ti_rowids   table_varchar;
        -- Data structures related with icnp_epis_diagnosis
        l_epis_diag_row    icnp_epis_diagnosis%ROWTYPE;
        l_epis_diag_rowids table_varchar;
        -- Data structures related with error management
        l_error t_error_out;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Check the input parameters
        IF pk_icnp_util.is_table_empty(i_diag_coll)
        THEN
            RETURN;
        END IF;
    
        -- Loop the diagnosis to create a collection of ti records (for further bulk processing)
        FOR i IN i_diag_coll.first .. i_diag_coll.last
        LOOP
            l_epis_diag_row := i_diag_coll(i);
            l_ti_row_coll(i) := create_ti_diag_row(i_prof         => i_prof,
                                                   i_episode      => l_epis_diag_row.id_episode,
                                                   i_diag         => l_epis_diag_row.id_icnp_epis_diag,
                                                   i_sysdate_tstz => i_sysdate_tstz);
        END LOOP;
    
        -- Persist the diagnosis into the database and brodcast the update through the data 
        -- governace mechanism
        ts_icnp_epis_diagnosis.ins(rows_in => i_diag_coll, rows_out => l_epis_diag_rowids);
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'ICNP_EPIS_DIAGNOSIS',
                                      i_rowids     => l_epis_diag_rowids,
                                      o_error      => l_error);
    
        -- Persist the ti_log (diagnosis) into the database and brodcast the update through 
        -- the data governace mechanism
        ts_ti_log.ins(rows_in => l_ti_row_coll, rows_out => l_ti_rowids);
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'TI_LOG',
                                      i_rowids     => l_ti_rowids,
                                      o_error      => l_error);
    
    END create_diags;

    --------------------------------------------------------------------------------
    -- METHODS [UPDATE DIAG ROW]
    --------------------------------------------------------------------------------

    /**
     * Updates a set of diagnosis records (icnp_epis_diagnosis rows). Each record
     * of the collection is a icnp_epis_diagnosis row already with the data that
     * should be persisted in the database. The ALERT data governance mechanism
     * demands that whenever an update is executed an event with the rows and columns 
     * updated is broadcasted. For that purpose, a set of column names (i_cols) should
     * always be defined.
     *
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_diag_row_coll Collection of icnp_epis_diagnosis rows already with 
     *                        the data that should be persisted in the database.
     * @param i_cols Set of column names that were updated.
     * @param o_diag_rowids_coll Collection with the updated icnp_epis_diagnosis 
     *                           rowids.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 5/Jun/2011 (v2.6.1)
    */
    PROCEDURE update_diag_rows
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_diag_row_coll    IN ts_icnp_epis_diagnosis.icnp_epis_diagnosis_tc,
        i_cols             IN table_varchar,
        o_diag_rowids_coll OUT table_varchar
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'update_diag_rows';
        l_diag_rowids_coll table_varchar;
        l_error            t_error_out;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Check the input parameters
        IF pk_icnp_util.is_table_empty(i_diag_row_coll)
        THEN
            pk_alert_exceptions.raise_error(error_name_in => pk_icnp_constant.g_excep_inv_input_params,
                                            text_in       => 'The table with the diagnosis rows (i_diag_row_coll) given as input parameter is empty');
        END IF;
        IF pk_icnp_util.is_table_empty(i_cols)
        THEN
            pk_alert_exceptions.raise_error(error_name_in => pk_icnp_constant.g_excep_inv_input_params,
                                            text_in       => 'The table with the column names (i_cols) given as input parameter is empty');
        END IF;
    
        -- Persist the data into the database and brodcast the update through the data 
        -- governace mechanism
        ts_icnp_epis_diagnosis.upd(col_in            => i_diag_row_coll,
                                   ignore_if_null_in => FALSE,
                                   rows_out          => l_diag_rowids_coll);
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'ICNP_EPIS_DIAGNOSIS',
                                      i_rowids       => l_diag_rowids_coll,
                                      o_error        => l_error,
                                      i_list_columns => i_cols);
    
        -- Set the output parameters
        o_diag_rowids_coll := l_diag_rowids_coll;
    
    END update_diag_rows;

    /**
     * Updates a diagnose record (icnp_epis_diagnosis row). The icnp_epis_diagnosis 
     * row must already have the data that should be persisted in the database. The 
     * ALERT data governance mechanism demands that whenever an update is executed an 
     * event with the rows and columns updated is broadcasted. For that purpose, a set 
     * of column names (i_cols) should always be defined.
     *
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_diag_row The icnp_epis_diagnosis row already with the data that
     *                     should be persisted in the database.
     * @param i_cols Set of column names that were updated.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 5/Jun/2011 (v2.6.1)
    */
    PROCEDURE update_diag_row
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_diag_row IN icnp_epis_diagnosis%ROWTYPE,
        i_cols     IN table_varchar
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'update_diag_row';
        l_diag_row_coll    ts_icnp_epis_diagnosis.icnp_epis_diagnosis_tc;
        l_diag_rowids_coll table_varchar;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Persist the data into the database
        l_diag_row_coll(1) := i_diag_row;
        update_diag_rows(i_lang             => i_lang,
                         i_prof             => i_prof,
                         i_diag_row_coll    => l_diag_row_coll,
                         i_cols             => i_cols,
                         o_diag_rowids_coll => l_diag_rowids_coll);
    
    END update_diag_row;

    --------------------------------------------------------------------------------
    -- METHODS [CHANGE ROW COLUMNS FOR UPDATE STATUS]
    --------------------------------------------------------------------------------

    /**
     * Updates all the necessary columns of a diagnose record (icnp_epis_diagnosis row)
     * when the user reevals a diagnose. A set with the column names that were updated
     * is returned to be used in the ALERT data governance mechanism.
     * 
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_composition_id The new diagnose that was determined in the reeval 
     *                         process.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * @param io_diag_row The icnp_epis_diagnosis row whose columns will be updated.
     *                      This is an input/output argument because the diagnose
     *                      record can be updated too in other methods.
     * 
     * @return Set with the column names that were updated.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 5/Jun/2011 (v2.6.1)
    */
    FUNCTION change_diag_row_reeval_cols
    (
        i_prof           IN profissional,
        i_composition_id IN icnp_epis_diagnosis.id_composition%TYPE,
        i_sysdate_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE,
        io_diag_row      IN OUT NOCOPY icnp_epis_diagnosis%ROWTYPE,
        i_notes          IN table_varchar
    ) RETURN table_varchar IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'change_diag_row_reeval_cols';
        l_cols table_varchar;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Update the columns of the diagnose record
        io_diag_row.id_composition      := i_composition_id;
        io_diag_row.id_prof_last_update := i_prof.id;
        io_diag_row.dt_last_update      := i_sysdate_tstz;
        IF i_notes IS NOT NULL
        THEN
            io_diag_row.notes := i_notes(1);
        END IF;
    
        -- Populate the collection with the column names that were updated
        l_cols := table_varchar('ID_COMPOSITION', 'ID_PROF_LAST_UPDATE', 'DT_LAST_UPDATE');
    
        RETURN l_cols;
    
    END change_diag_row_reeval_cols;

    /**
     * Updates all the necessary columns of a diagnose record (icnp_epis_diagnosis row)
     * when the user resolves a diagnose. A set with the column names that were updated
     * is returned to be used in the ALERT data governance mechanism.
     * 
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * @param io_diag_row The icnp_epis_diagnosis row whose columns will be updated.
     *                      This is an input/output argument because the diagnose
     *                      record can be updated too in other methods.
     * 
     * @return Set with the column names that were updated.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 5/Jun/2011 (v2.6.1)
    */
    FUNCTION change_diag_row_resolve_cols
    (
        i_prof         IN profissional,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE,
        io_diag_row    IN OUT NOCOPY icnp_epis_diagnosis%ROWTYPE
    ) RETURN table_varchar IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'change_diag_row_resolve_cols';
        l_cols table_varchar;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Update the columns of the diagnose record
        io_diag_row.flg_status          := pk_icnp_constant.g_epis_diag_status_resolved;
        io_diag_row.id_prof_last_update := i_prof.id;
        io_diag_row.dt_last_update      := i_sysdate_tstz;
    
        -- Populate the collection with the column names that were updated
        l_cols := table_varchar('FLG_STATUS', 'ID_PROF_LAST_UPDATE', 'DT_LAST_UPDATE');
    
        RETURN l_cols;
    
    END change_diag_row_resolve_cols;

    /**
     * Updates all the necessary columns of a diagnose record (icnp_epis_diagnosis row)
     * when the user suspends a diagnose. A set with the column names that were updated
     * is returned to be used in the ALERT data governance mechanism.
     * 
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_suspend_reason Suspension reason identifier.
     * @param i_suspend_notes Notes describing the reason of the suspension.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * @param io_diag_row The icnp_epis_diagnosis row whose columns will be updated.
     *                      This is an input/output argument because the diagnose
     *                      record can be updated too in other methods.
     * 
     * @return Set with the column names that were updated.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 5/Jun/2011 (v2.6.1)
    */
    FUNCTION change_diag_row_pause_cols
    (
        i_prof           IN profissional,
        i_suspend_reason IN icnp_epis_diagnosis.id_suspend_reason%TYPE,
        i_suspend_notes  IN icnp_epis_diagnosis.suspend_notes%TYPE,
        i_sysdate_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE,
        io_diag_row      IN OUT NOCOPY icnp_epis_diagnosis%ROWTYPE,
        i_force_status   IN VARCHAR2 DEFAULT 'N'
    ) RETURN table_varchar IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'change_diag_row_pause_cols';
        l_cols table_varchar;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Update the columns of the diagnose record
        io_diag_row.flg_status := CASE
                                      WHEN i_force_status = pk_alert_constant.g_no THEN
                                       pk_icnp_constant.g_epis_diag_status_suspended
                                      ELSE
                                       pk_icnp_constant.g_epis_diag_status_discontinue
                                  END;
        io_diag_row.id_suspend_prof     := i_prof.id;
        io_diag_row.id_suspend_reason   := i_suspend_reason;
        io_diag_row.suspend_notes       := i_suspend_notes;
        io_diag_row.dt_suspend          := i_sysdate_tstz;
        io_diag_row.id_prof_last_update := i_prof.id;
        io_diag_row.dt_last_update      := i_sysdate_tstz;
    
        -- Populate the collection with the column names that were updated
        l_cols := table_varchar('FLG_STATUS',
                                'ID_SUSPEND_PROF',
                                'ID_SUSPEND_REASON',
                                'SUSPEND_NOTES',
                                'DT_SUSPEND',
                                'ID_PROF_LAST_UPDATE',
                                'DT_LAST_UPDATE');
    
        RETURN l_cols;
    
    END change_diag_row_pause_cols;

    /**
     * Updates all the necessary columns of a diagnose record (icnp_epis_diagnosis row)
     * when the user resumes a diagnose. A set with the column names that were updated
     * is returned to be used in the ALERT data governance mechanism.
     * 
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * @param io_diag_row The icnp_epis_diagnosis row whose columns will be updated.
     *                      This is an input/output argument because the diagnose
     *                      record can be updated too in other methods.
     * 
     * @return Set with the column names that were updated.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 5/Jun/2011 (v2.6.1)
    */
    FUNCTION change_diag_row_resume_cols
    (
        i_prof         IN profissional,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE,
        io_diag_row    IN OUT NOCOPY icnp_epis_diagnosis%ROWTYPE
    ) RETURN table_varchar IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'change_diag_row_resume_cols';
        l_cols table_varchar;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Update the columns of the diagnose record
        io_diag_row.flg_status          := pk_icnp_constant.g_epis_diag_status_active;
        io_diag_row.id_prof_last_update := i_prof.id;
        io_diag_row.dt_last_update      := i_sysdate_tstz;
    
        -- Populate the collection with the column names that were updated
        l_cols := table_varchar('FLG_STATUS', 'ID_PROF_LAST_UPDATE', 'DT_LAST_UPDATE');
    
        RETURN l_cols;
    
    END change_diag_row_resume_cols;

    /**
     * Updates all the necessary columns of a diagnose record (icnp_epis_diagnosis row)
     * when the user cancels a diagnose. A set with the column names that were updated
     * is returned to be used in the ALERT data governance mechanism.
     * 
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_cancel_reason Cancellation reason identifier.
     * @param i_cancel_notes Notes describing the reason of the cancellation.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * @param io_diag_row The icnp_epis_diagnosis row whose columns will be updated.
     *                      This is an input/output argument because the diagnose
     *                      record can be updated too in other methods.
     * 
     * @return Set with the column names that were updated.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 5/Jun/2011 (v2.6.1)
    */
    FUNCTION change_diag_row_cancel_cols
    (
        i_prof          IN profissional,
        i_cancel_reason IN icnp_epis_diagnosis.id_cancel_reason%TYPE,
        i_cancel_notes  IN icnp_epis_diagnosis.cancel_notes%TYPE,
        i_sysdate_tstz  IN TIMESTAMP WITH LOCAL TIME ZONE,
        io_diag_row     IN OUT NOCOPY icnp_epis_diagnosis%ROWTYPE
    ) RETURN table_varchar IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'change_diag_row_cancel_cols';
        l_cols table_varchar;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Update the columns of the diagnose record
        io_diag_row.flg_status          := pk_icnp_constant.g_epis_diag_status_cancelled;
        io_diag_row.id_cancel_prof      := i_prof.id;
        io_diag_row.id_cancel_reason    := i_cancel_reason;
        io_diag_row.cancel_notes        := i_cancel_notes;
        io_diag_row.dt_cancel           := i_sysdate_tstz;
        io_diag_row.id_prof_last_update := i_prof.id;
        io_diag_row.dt_last_update      := i_sysdate_tstz;
    
        -- Populate the collection with the column names that were updated
        l_cols := table_varchar('FLG_STATUS',
                                'ID_CANCEL_PROF',
                                'ID_CANCEL_REASON',
                                'CANCEL_NOTES',
                                'DT_CANCEL',
                                'ID_PROF_LAST_UPDATE',
                                'DT_LAST_UPDATE');
    
        RETURN l_cols;
    
    END change_diag_row_cancel_cols;

    --------------------------------------------------------------------------------
    -- METHODS [UPDATE DIAG STATUS UTIL]
    --------------------------------------------------------------------------------

    /**
     * Checks if, when updating a set of diagnosis, the number of updated records
     * matches the number of historical records created.
     * 
     * @param i_diag_rows_updated Number of updated diagnosis records.
     * @param i_diag_hist_rows_created Number of historical records created.
     * 
     * @see create_diag_hist
     * @see set_diags_status_*
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 5/Jun/2011 (v2.6.1)
    */
    PROCEDURE check_diag_and_hist_count
    (
        i_diag_rows_updated      IN NUMBER,
        i_diag_hist_rows_created IN NUMBER
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'check_diag_and_hist_count';
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        IF i_diag_rows_updated != i_diag_hist_rows_created
        THEN
            pk_alert_exceptions.raise_error(error_name_in => pk_icnp_constant.g_excep_count_mismatch,
                                            text_in       => 'Count mismatch: updated ' || i_diag_rows_updated ||
                                                             ' diagnosis record(s), created ' ||
                                                             i_diag_hist_rows_created || ' history record(s)');
        END IF;
    
    END check_diag_and_hist_count;

    --------------------------------------------------------------------------------
    -- METHODS [UPDATE DIAG STATUS]
    --------------------------------------------------------------------------------

    /**
     * Makes the necessary updates to a set of diagnosis records (icnp_epis_diagnosis rows)
     * when the user reevaluates the diagnosis. When a diagose is reevaluated, the 
     * old diagnose is replaced by a new one. Functionally it means that the patient 
     * condition changed.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_diag_ids The set of diagnosis identifiers that we want to reeval.
     * @param i_composition_id The new diagnose that was determined in the reevaluation
     *                         process.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    PROCEDURE set_diags_status_reeval
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_diag_ids       IN table_number,
        i_composition_id IN icnp_epis_diagnosis.id_composition%TYPE,
        i_sysdate_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_notes          IN table_varchar
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'set_diags_status_reeval';
        l_diag_row         icnp_epis_diagnosis%ROWTYPE;
        l_diag_row_coll    ts_icnp_epis_diagnosis.icnp_epis_diagnosis_tc;
        l_diag_hist        table_number;
        l_cols             table_varchar;
        l_diag_rowids_coll table_varchar;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        /* The input parameter i_diag_ids is already being checked in pk_icnp_fo_api_db. 
         * When invoked from this package there is no need to raise an exception.
        */
        IF pk_icnp_util.is_table_empty(i_diag_ids)
        THEN
            RETURN;
        END IF;
    
        -- Gets the diagnosis rows of all the ids
        l_diag_row_coll := get_diag_rows(i_diag_ids => i_diag_ids);
    
        -- Creates history records for all the diagnosis
        create_diag_hist(i_lang         => i_lang,
                         i_prof         => i_prof,
                         i_diag_coll    => l_diag_row_coll,
                         i_sysdate_tstz => i_sysdate_tstz,
                         o_diag_hist    => l_diag_hist);
    
        -- Make the necessary changes to each diagnose record in the collection
        FOR i IN l_diag_row_coll.first .. l_diag_row_coll.last
        LOOP
            l_diag_row := l_diag_row_coll(i);
        
            /* :FIXME: there is no need to update l_cols on every iteration. A possible solution 
             * is to have a new method, invoked outside the loop, that only returns the changed 
             * columns. This could be, although, more error prone because the developer could 
             * easily forget to update both methods.
            */
            l_cols := change_diag_row_reeval_cols(i_prof           => i_prof,
                                                  i_composition_id => i_composition_id,
                                                  i_sysdate_tstz   => i_sysdate_tstz,
                                                  io_diag_row      => l_diag_row,
                                                  i_notes          => i_notes);
        
            l_diag_row_coll(i) := l_diag_row;
        END LOOP;
    
        -- Persist the data into the database
        update_diag_rows(i_lang             => i_lang,
                         i_prof             => i_prof,
                         i_diag_row_coll    => l_diag_row_coll,
                         i_cols             => l_cols,
                         o_diag_rowids_coll => l_diag_rowids_coll);
    
        -- Checks if the number of updated records matches the number of historical
        -- records created
        check_diag_and_hist_count(i_diag_rows_updated      => l_diag_rowids_coll.count,
                                  i_diag_hist_rows_created => l_diag_hist.count);
    
    END set_diags_status_reeval;

    /**
     * Makes the necessary updates to a set of diagnosis records (icnp_epis_diagnosis rows)
     * when the user resolves the diagnosis. Resolved is a final status, no more changes 
     * to the record can be made.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_diag_ids The set of diagnosis identifiers that we want to resolve.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    PROCEDURE set_diags_status_resolve
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_diag_ids     IN table_number,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'set_diags_status_resolve';
        l_diag_row         icnp_epis_diagnosis%ROWTYPE;
        l_diag_row_coll    ts_icnp_epis_diagnosis.icnp_epis_diagnosis_tc;
        l_diag_hist        table_number;
        l_cols             table_varchar;
        l_diag_rowids_coll table_varchar;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        /* The input parameter i_diag_ids is already being checked in pk_icnp_fo_api_db. 
         * When invoked from this package there is no need to raise an exception.
        */
        IF pk_icnp_util.is_table_empty(i_diag_ids)
        THEN
            RETURN;
        END IF;
    
        -- Gets the diagnosis rows of all the ids
        l_diag_row_coll := get_diag_rows(i_diag_ids => i_diag_ids);
    
        -- Creates history records for all the diagnosis
        create_diag_hist(i_lang         => i_lang,
                         i_prof         => i_prof,
                         i_diag_coll    => l_diag_row_coll,
                         i_sysdate_tstz => i_sysdate_tstz,
                         o_diag_hist    => l_diag_hist);
    
        -- Make the necessary changes to each diagnose record in the collection
        FOR i IN l_diag_row_coll.first .. l_diag_row_coll.last
        LOOP
            l_diag_row := l_diag_row_coll(i);
        
            /* :FIXME: there is no need to update l_cols on every iteration. A possible solution 
             * is to have a new method, invoked outside the loop, that only returns the changed 
             * columns. This could be, although, more error prone because the developer could 
             * easily forget to update both methods.
            */
            l_cols := change_diag_row_resolve_cols(i_prof         => i_prof,
                                                   i_sysdate_tstz => i_sysdate_tstz,
                                                   io_diag_row    => l_diag_row);
        
            l_diag_row_coll(i) := l_diag_row;
        END LOOP;
    
        -- Persist the data into the database
        update_diag_rows(i_lang             => i_lang,
                         i_prof             => i_prof,
                         i_diag_row_coll    => l_diag_row_coll,
                         i_cols             => l_cols,
                         o_diag_rowids_coll => l_diag_rowids_coll);
    
        -- Checks if the number of updated records matches the number of historical
        -- records created
        check_diag_and_hist_count(i_diag_rows_updated      => l_diag_rowids_coll.count,
                                  i_diag_hist_rows_created => l_diag_hist.count);
    
    END set_diags_status_resolve;

    /**
     * Makes the necessary updates to a set of diagnosis records (icnp_epis_diagnosis rows)
     * when the user suspends the diagnosis. When a diagnose is suspended, no actions
     * (excluding the resume) could be performed.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_diag_ids The set of diagnosis identifiers that we want to resolve.
     * @param i_suspend_reason Suspension reason identifier.
     * @param i_suspend_notes Notes describing the reason of the suspension.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    PROCEDURE set_diags_status_pause
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_diag_ids       IN table_number,
        i_suspend_reason IN icnp_epis_diagnosis.id_suspend_reason%TYPE,
        i_suspend_notes  IN icnp_epis_diagnosis.suspend_notes%TYPE,
        i_sysdate_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_force_status   IN VARCHAR2 DEFAULT 'N'
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'set_diags_status_pause';
        l_diag_row         icnp_epis_diagnosis%ROWTYPE;
        l_diag_row_coll    ts_icnp_epis_diagnosis.icnp_epis_diagnosis_tc;
        l_diag_hist        table_number;
        l_cols             table_varchar;
        l_diag_rowids_coll table_varchar;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        /* The input parameter i_diag_ids is already being checked in pk_icnp_fo_api_db. 
         * When invoked from this package there is no need to raise an exception.
        */
        IF pk_icnp_util.is_table_empty(i_diag_ids)
        THEN
            RETURN;
        END IF;
    
        -- Gets the diagnosis rows of all the ids
        l_diag_row_coll := get_diag_rows(i_diag_ids => i_diag_ids);
    
        -- Creates history records for all the diagnosis
        create_diag_hist(i_lang         => i_lang,
                         i_prof         => i_prof,
                         i_diag_coll    => l_diag_row_coll,
                         i_sysdate_tstz => i_sysdate_tstz,
                         o_diag_hist    => l_diag_hist);
    
        -- Make the necessary changes to each diagnose record in the collection
        FOR i IN l_diag_row_coll.first .. l_diag_row_coll.last
        LOOP
            l_diag_row := l_diag_row_coll(i);
        
            /* :FIXME: there is no need to update l_cols on every iteration. A possible solution 
             * is to have a new method, invoked outside the loop, that only returns the changed 
             * columns. This could be, although, more error prone because the developer could 
             * easily forget to update both methods.
            */
            l_cols := change_diag_row_pause_cols(i_prof           => i_prof,
                                                 i_suspend_reason => i_suspend_reason,
                                                 i_suspend_notes  => i_suspend_notes,
                                                 i_sysdate_tstz   => i_sysdate_tstz,
                                                 io_diag_row      => l_diag_row,
                                                 i_force_status   => i_force_status);
        
            l_diag_row_coll(i) := l_diag_row;
        END LOOP;
    
        -- Persist the data into the database
        update_diag_rows(i_lang             => i_lang,
                         i_prof             => i_prof,
                         i_diag_row_coll    => l_diag_row_coll,
                         i_cols             => l_cols,
                         o_diag_rowids_coll => l_diag_rowids_coll);
    
        -- Checks if the number of updated records matches the number of historical
        -- records created
        check_diag_and_hist_count(i_diag_rows_updated      => l_diag_rowids_coll.count,
                                  i_diag_hist_rows_created => l_diag_hist.count);
    
    END set_diags_status_pause;

    /**
     * Makes the necessary updates to a set of diagnosis records (icnp_epis_diagnosis rows)
     * when the user resumes the diagnosis. When the diagnose is resumed its status is
     * updated to active again, allowing the user to execute again action on the diagnosis,
     * like for example, reevaluate, resolve or cancel. 
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_diag_ids The set of diagnosis identifiers that we want to resolve.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    PROCEDURE set_diags_status_resume
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_diag_ids     IN table_number,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'set_diags_status_resume';
        l_diag_row         icnp_epis_diagnosis%ROWTYPE;
        l_diag_row_coll    ts_icnp_epis_diagnosis.icnp_epis_diagnosis_tc;
        l_diag_hist        table_number;
        l_cols             table_varchar;
        l_diag_rowids_coll table_varchar;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        /* The input parameter i_diag_ids is already being checked in pk_icnp_fo_api_db. 
         * When invoked from this package there is no need to raise an exception.
        */
        IF pk_icnp_util.is_table_empty(i_diag_ids)
        THEN
            RETURN;
        END IF;
    
        -- Gets the diagnosis rows of all the ids
        l_diag_row_coll := get_diag_rows(i_diag_ids => i_diag_ids);
    
        -- Creates history records for all the diagnosis
        create_diag_hist(i_lang         => i_lang,
                         i_prof         => i_prof,
                         i_diag_coll    => l_diag_row_coll,
                         i_sysdate_tstz => i_sysdate_tstz,
                         o_diag_hist    => l_diag_hist);
    
        -- Make the necessary changes to each diagnose record in the collection
        FOR i IN l_diag_row_coll.first .. l_diag_row_coll.last
        LOOP
            l_diag_row := l_diag_row_coll(i);
        
            /* :FIXME: there is no need to update l_cols on every iteration. A possible solution 
             * is to have a new method, invoked outside the loop, that only returns the changed 
             * columns. This could be, although, more error prone because the developer could 
             * easily forget to update both methods.
            */
            l_cols := change_diag_row_resume_cols(i_prof         => i_prof,
                                                  i_sysdate_tstz => i_sysdate_tstz,
                                                  io_diag_row    => l_diag_row);
        
            l_diag_row_coll(i) := l_diag_row;
        END LOOP;
    
        -- Persist the data into the database
        update_diag_rows(i_lang             => i_lang,
                         i_prof             => i_prof,
                         i_diag_row_coll    => l_diag_row_coll,
                         i_cols             => l_cols,
                         o_diag_rowids_coll => l_diag_rowids_coll);
    
        -- Checks if the number of updated records matches the number of historical
        -- records created
        check_diag_and_hist_count(i_diag_rows_updated      => l_diag_rowids_coll.count,
                                  i_diag_hist_rows_created => l_diag_hist.count);
    
    END set_diags_status_resume;

    /**
     * Makes the necessary updates to a set of diagnosis records (icnp_epis_diagnosis rows)
     * when the user cancels the diagnosis. When the diagnose is cancelled the user can't 
     * make any more changes.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_diag_ids The set of diagnosis identifiers that we want to resolve.
     * @param i_cancel_reason Cancellation reason identifier.
     * @param i_cancel_notes Notes describing the reason of the cancellation.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    PROCEDURE set_diags_status_cancel
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_diag_ids      IN table_number,
        i_cancel_reason IN icnp_epis_diagnosis.id_cancel_reason%TYPE,
        i_cancel_notes  IN icnp_epis_diagnosis.cancel_notes%TYPE,
        i_sysdate_tstz  IN TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'set_diags_status_cancel';
        l_diag_row         icnp_epis_diagnosis%ROWTYPE;
        l_diag_row_coll    ts_icnp_epis_diagnosis.icnp_epis_diagnosis_tc;
        l_diag_hist        table_number;
        l_cols             table_varchar;
        l_diag_rowids_coll table_varchar;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        /* The input parameter i_diag_ids is already being checked in pk_icnp_fo_api_db. 
         * When invoked from this package there is no need to raise an exception.
        */
        IF pk_icnp_util.is_table_empty(i_diag_ids)
        THEN
            RETURN;
        END IF;
    
        -- Gets the diagnosis rows of all the ids
        l_diag_row_coll := get_diag_rows(i_diag_ids => i_diag_ids);
    
        -- Creates history records for all the diagnosis
        create_diag_hist(i_lang => i_lang,
                         
                         i_prof         => i_prof,
                         i_diag_coll    => l_diag_row_coll,
                         i_sysdate_tstz => i_sysdate_tstz,
                         o_diag_hist    => l_diag_hist);
    
        -- Make the necessary changes to each diagnose record in the collection
        FOR i IN l_diag_row_coll.first .. l_diag_row_coll.last
        LOOP
            l_diag_row := l_diag_row_coll(i);
        
            /* :FIXME: there is no need to update l_cols on every iteration. A possible solution 
             * is to have a new method, invoked outside the loop, that only returns the changed 
             * columns. This could be, although, more error prone because the developer could 
             * easily forget to update both methods.
            */
            l_cols := change_diag_row_cancel_cols(i_prof          => i_prof,
                                                  i_cancel_reason => i_cancel_reason,
                                                  i_cancel_notes  => i_cancel_notes,
                                                  i_sysdate_tstz  => i_sysdate_tstz,
                                                  io_diag_row     => l_diag_row);
        
            l_diag_row_coll(i) := l_diag_row;
        END LOOP;
    
        -- Persist the data into the database
        update_diag_rows(i_lang             => i_lang,
                         i_prof             => i_prof,
                         i_diag_row_coll    => l_diag_row_coll,
                         i_cols             => l_cols,
                         o_diag_rowids_coll => l_diag_rowids_coll);
    
        -- Checks if the number of updated records matches the number of historical
        -- records created
        check_diag_and_hist_count(i_diag_rows_updated      => l_diag_rowids_coll.count,
                                  i_diag_hist_rows_created => l_diag_hist.count);
    
    END set_diags_status_cancel;

    FUNCTION get_icnp_diagnosis_desc
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN episode.id_episode%TYPE,
        i_id_icnp_epis_diag     IN icnp_epis_diagnosis.id_icnp_epis_diag%TYPE,
        i_flg_description       IN pn_dblock_ttp_mkt.flg_description%TYPE,
        i_description_condition IN pn_dblock_ttp_mkt.description_condition%TYPE
    ) RETURN CLOB IS
    
        l_description         CLOB;
        l_desc_icnp_diagnosis CLOB;
        l_desc_exp_result     CLOB;
        l_notes               CLOB;
        l_notes_msg           VARCHAR2(1000 CHAR) := pk_message.get_message(i_lang      => i_lang,
                                                                            i_prof      => i_prof,
                                                                            i_code_mess => 'PN_M030');
    
    BEGIN
    
        SELECT pk_icnp.desc_composition(i_lang, ied.id_composition) desc_diagnosis,
               pk_icnp.desc_composition(i_lang, ied.icnp_compo_reeval) desc_exp_result,
               notes
          INTO l_desc_icnp_diagnosis, l_desc_exp_result, l_notes
          FROM icnp_epis_diagnosis ied
         WHERE ied.id_icnp_epis_diag = i_id_icnp_epis_diag;
    
        IF (i_description_condition IS NOT NULL)
        THEN
            --l_tbl_desc_condition := pk_string_utils.str_split(i_list => i_description_condition, i_delim => '|');
            --   FOR i IN 1 .. l_tbl_desc_condition.last
            --  LOOP
            --null;
            --    END LOOP;
            NULL;
        ELSE
            IF l_desc_icnp_diagnosis IS NOT NULL
            THEN
                l_description := l_desc_icnp_diagnosis;
                IF l_desc_exp_result IS NOT NULL
                THEN
                    l_description := l_description || pk_prog_notes_constants.g_flg_sep;
                END IF;
                IF l_notes IS NOT NULL
                THEN
                    l_description := l_description || l_notes_msg || pk_prog_notes_constants.g_space || l_notes;
                
                END IF;
                l_description := l_description || pk_prog_notes_constants.g_period;
            ELSE
                l_description := NULL;
            END IF;
        END IF;
    
        RETURN l_description;
        --EXCEPTION WHEN OTHERS THEN RETURN NULL;
    END get_icnp_diagnosis_desc;

BEGIN
    -- Executes all the instructions needed to correctly initialize the package
    initialize();

END pk_icnp_diag;
/
