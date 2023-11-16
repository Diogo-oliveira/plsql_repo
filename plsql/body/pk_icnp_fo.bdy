CREATE OR REPLACE PACKAGE BODY pk_icnp_fo IS

    --------------------------------------------------------------------------------
    -- TYPES
    --------------------------------------------------------------------------------

    -- Types used in the message cache mechanism
    SUBTYPE t_message_key IS VARCHAR2(207 CHAR);
    TYPE t_messages IS TABLE OF sys_message.desc_message%TYPE INDEX BY t_message_key;
    -- Type used to identify the frequency type, both from the tables icnp_epis_intervention
    -- and icnp_cplan_stand_compo
    SUBTYPE t_frequency_type IS VARCHAR2(1);
    -- Typed record with the information sent by the UX layer in the create_interv method
    TYPE data_ux_ci_rec IS RECORD(
        id_composition_interv icnp_epis_intervention.id_composition%TYPE,
        id_composition_diag   icnp_epis_intervention.id_composition%TYPE,
        flg_time              icnp_epis_intervention.flg_time%TYPE,
        dt_begin_tstz         icnp_epis_intervention.dt_begin_tstz%TYPE,
        id_order_recurr_plan  icnp_epis_intervention.id_order_recurr_plan%TYPE,
        flg_prn               icnp_epis_intervention.flg_prn%TYPE,
        prn_notes             icnp_epis_intervention.prn_notes%TYPE,
        notes                 icnp_epis_intervention.notes%TYPE,
        id_icnp_sug_interv    icnp_suggest_interv.id_icnp_sug_interv%TYPE);
    -- Typed record with the information sent by the UX layer in the create_or_update_icnp_cplan method
    TYPE data_ux_ccp_rec IS RECORD(
        id_composition_interv icnp_epis_intervention.id_composition%TYPE,
        id_composition_diag   icnp_epis_intervention.id_composition%TYPE,
        flg_time              icnp_epis_intervention.flg_time%TYPE,
        id_order_recurr_plan  icnp_epis_intervention.id_order_recurr_plan%TYPE,
        flg_prn               icnp_epis_intervention.flg_prn%TYPE,
        prn_notes             icnp_epis_intervention.prn_notes%TYPE);
    -- Types used to control which recurrences are already marked as definitive
    SUBTYPE t_order_recurr_key IS VARCHAR2(24 CHAR);
    TYPE t_order_recurr_rec IS RECORD(
        id_order_recurr_option order_recurr_plan.id_order_recurr_option%TYPE,
        id_order_recurr_plan   order_recurr_plan.id_order_recurr_plan%TYPE);
    TYPE t_order_recurr_coll IS TABLE OF t_order_recurr_rec INDEX BY t_order_recurr_key;

    TYPE t_processed_plan_rec IS RECORD(
        id_order_recurr_plan   NUMBER(24),
        id_order_recurr_option NUMBER(24));

    TYPE t_processed_plan IS TABLE OF t_processed_plan_rec INDEX BY VARCHAR2(24);

    --------------------------------------------------------------------------------
    -- CONSTANTS
    --------------------------------------------------------------------------------

    -- Special composition identifier used when there is no expected outcome
    g_compo_no_exp_result CONSTANT icnp_composition.id_composition%TYPE := -1;

    -- shortcut to follow to execute an intervention
    g_execution_shortcut CONSTANT sys_shortcut.id_sys_shortcut%TYPE := 668;

    -- internal types
    g_type_diag_interv CONSTANT VARCHAR2(2 CHAR) := 'DI';
    g_type_interv      CONSTANT VARCHAR2(2 CHAR) := 'I';
    g_type_diag        CONSTANT VARCHAR2(2 CHAR) := 'D';
    g_type_exec        CONSTANT VARCHAR2(2 CHAR) := 'E';

    g_interv_plan_req CONSTANT VARCHAR2(2 CHAR) := 'R';

    -- record timeline visibility
    g_show CONSTANT PLS_INTEGER := 1;
    g_hide CONSTANT PLS_INTEGER := 0;

    -- :TODO: REMOVE
    -- Keypad Date
    g_date_keypad               CONSTANT advanced_input_field.type%TYPE := 'DT';
    g_advanced_input_icnp_cplan CONSTANT advanced_input.id_advanced_input%TYPE := 83;
    -- domain
    g_domain_intv_presc_time CONSTANT sys_domain.code_domain%TYPE := 'INTERV_PRESCRIPTION.FLG_TIME'; -- Replace by pk_icnp_constant.g_domain_epis_interv_time
    g_domain_dept_urg        CONSTANT sys_domain.code_domain%TYPE := 'ANALYSIS_REQ_DET.FLG_URGENCY'; -- Replace by :TODO:
    g_domain_dept_coll       CONSTANT sys_domain.code_domain%TYPE := 'ANALYSIS_INSTIT_SOFT.FLG_COLLECTION_AUTHOR'; -- Replace by :TODO:
    --------------------------------------------------------------------------------
    -- GLOBAL VARIABLES
    --------------------------------------------------------------------------------

    -- Identifes the package in the log mechanism
    g_package_name         pk_icnp_type.t_package_name;
    g_prev_status_executed VARCHAR2(1 CHAR);

    --------------------------------------------------------------------------------
    -- PRIVATE VARIABLES
    --------------------------------------------------------------------------------

    -- Collection used to cache message descriptions
    l_messages_col t_messages;

    --------------------------------------------------------------------------------
    -- METHODS [DEBUG]
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
    -- METHODS [MESSAGE CACHE]
    --------------------------------------------------------------------------------

    /**
     * Gets the description of a given message code. The result is cached in a collection
     * to avoid unnecessary database round-trips. When the message doesn't exist in
     * the collection the message is retrieved through pk_message; otherwise the message
     * is retrieved from the collection.
     * 
     * This functions should be used when the programmer wants to store common frequently 
     * used messages.
     * 
     * If needed, the cache could be cleaned using the procedure clear_message_cache or
     * recompiling the package.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_messages_col The collection used to store the cached messages.
     * 
     * @return The message description for the given language.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 26/May/2011
    */
    FUNCTION get_message_and_cache
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_code_message IN sys_message.code_message%TYPE,
        i_messages_col IN OUT NOCOPY t_messages
    ) RETURN sys_message.desc_message%TYPE IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'get_message_and_cache';
        l_message_key  t_message_key;
        l_message_desc sys_message.desc_message%TYPE;
    
    BEGIN
        log_debug(c_func_name || '(i_lang:' || i_lang || ', i_prof:' || pk_utils.to_string(i_prof) ||
                  ', i_code_message:' || i_code_message || ')',
                  c_func_name);
    
        -- Get the message key, composed by the language and the code of the message
        l_message_key := i_lang || '|' || i_code_message;
    
        -- Check if the message could be retrieved from the cache
        IF i_messages_col.count > 0
           AND i_messages_col.exists(l_message_key)
        THEN
            -- Get the message from the cache
            l_message_desc := i_messages_col(l_message_key);
        ELSE
            -- Get the message from the database
            l_message_desc := pk_message.get_message(i_lang, i_code_message);
            i_messages_col(l_message_key) := l_message_desc;
        END IF;
    
        RETURN l_message_desc;
    END;

    /**
     * Clears the collection used to store (cache) messages.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 26/May/2011
    */
    PROCEDURE clear_message_cache IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'clear_message_cache';
        l_messages_empty t_messages;
    BEGIN
        log_debug(c_func_name || '()', c_func_name);
        l_messages_col := l_messages_empty;
    END;

    --------------------------------------------------------------------------------
    -- METHODS [RECURRENCE]
    --------------------------------------------------------------------------------

    /**
     * Set a temporary order recurrence plan as definitive (final status). Because
     * we can have the same recurrence for some interventions and because we can only 
     * mark the recurrence as definitive once, we must control which recurrences have
     * already been marked as definitive. The objective is achieved using an 
     * associative array with all the recurrences already processed.
     *
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_recurr_plan_id The recurrence identifier.
     * @param io_recurr_processed_coll Collection with all the recurrences that were 
     *                                 already processed (marked as definitive). 
     * @param io_recurr_definit_ids_coll Collection with all the definitive recurrence
     *                                   identifiers. It will be used in the
     *                                   prepare_order_recurr_plan method.
     * 
     * @return A record with information about the recurrence: the identifier and the
     *         option (once, no schedule, etc).
     *
     * @author Luis Oliveira
     * @version 1.0
     * @since 26/Jul/2011
    */
    FUNCTION set_order_recurr_plan
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_recurr_plan_id           IN icnp_epis_intervention.id_order_recurr_plan%TYPE,
        io_recurr_processed_coll   IN OUT NOCOPY t_order_recurr_coll,
        io_recurr_definit_ids_coll IN OUT NOCOPY table_number,
        io_precessed_plans         IN OUT t_processed_plan
    ) RETURN t_order_recurr_rec IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'set_order_recurr_plan';
        l_order_recurr_key       t_order_recurr_key;
        l_order_recurr_rec       t_order_recurr_rec;
        l_order_recurr_option_id order_recurr_plan.id_order_recurr_option%TYPE;
        l_order_recurr_final_id  order_recurr_plan.id_order_recurr_plan%TYPE;
        l_error                  t_error_out;
    
    BEGIN
        log_debug(c_func_name || '()', c_func_name);
    
        -- Converts the recurrence identifier to a varchar, to be used in the 
        -- associative collection
        l_order_recurr_key := to_char(i_recurr_plan_id);
    
        -- Check this order recurrence identifier was already processed
        IF io_recurr_processed_coll.count > 0
           AND io_recurr_processed_coll.exists(l_order_recurr_key)
        THEN
            -- This recurrence was already processed, retrieve it from the associative array
            l_order_recurr_rec := io_recurr_processed_coll(l_order_recurr_key);
        ELSE
            -- Set a temporary order recurrence plan as definitive (final status)
            log_debug('set_order_recurr_plan / i_recurr_plan_id: ' || i_recurr_plan_id, c_func_name);
            IF NOT io_precessed_plans.exists(i_recurr_plan_id)
            THEN
                IF NOT pk_order_recurrence_api_db.set_order_recurr_plan(i_lang                    => i_lang,
                                                                        i_prof                    => i_prof,
                                                                        i_order_recurr_plan       => i_recurr_plan_id,
                                                                        o_order_recurr_option     => l_order_recurr_option_id,
                                                                        o_final_order_recurr_plan => l_order_recurr_final_id,
                                                                        o_error                   => l_error)
                THEN
                    pk_icnp_util.raise_unexpected_error('pk_order_recurrence_api_db.set_order_recurr_plan', l_error);
                END IF;
                -- add plan values to processed array
                io_precessed_plans(i_recurr_plan_id).id_order_recurr_option := l_order_recurr_option_id;
                io_precessed_plans(i_recurr_plan_id).id_order_recurr_plan := l_order_recurr_final_id;
            ELSE
                l_order_recurr_option_id := io_precessed_plans(i_recurr_plan_id).id_order_recurr_option;
                l_order_recurr_final_id  := io_precessed_plans(i_recurr_plan_id).id_order_recurr_plan;
            END IF;
        
            -- Mark this recurrence identifier as processed (store it in the associative array)
            l_order_recurr_rec.id_order_recurr_plan := l_order_recurr_final_id;
            l_order_recurr_rec.id_order_recurr_option := l_order_recurr_option_id;
            io_recurr_processed_coll(l_order_recurr_key) := l_order_recurr_rec;
        
            -- Add the final order recurrence identifier for further processing
            -- When the id is null it means that there is no recurrence (once execution)
            log_debug('add l_order_recurr_final_id to io_recurr_definit_ids_coll / l_order_recurr_final_id: ' ||
                      l_order_recurr_final_id,
                      c_func_name);
            IF (l_order_recurr_final_id IS NOT NULL)
            THEN
                io_recurr_definit_ids_coll.extend;
                io_recurr_definit_ids_coll(io_recurr_definit_ids_coll.count) := l_order_recurr_final_id;
            END IF;
        END IF;
    
        RETURN l_order_recurr_rec;
    
    END set_order_recurr_plan;

    --------------------------------------------------------------------------------
    -- METHODS [CREATE INTERVS, DIAGS, ASSOCIATIONS]
    --------------------------------------------------------------------------------

    /**
     * Maps the a given frequency to its equivalent type. The frequency is expressed
     * through a recurrence option.
     * 
     * @param i_order_recurr_option The order recurrence option.
     * 
     * @return The intervention flag type equivalent to a given frequency.
     *
     * @author Luis Oliveira
     * @version 1.0
     * @since 28/Jun/2011
    */
    FUNCTION map_recurr_option_to_type(i_order_recurr_option order_recurr_plan.id_order_recurr_option%TYPE)
        RETURN t_frequency_type IS
    
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'map_recurr_option_to_type';
        l_flg_type icnp_cplan_stand_compo.flg_type%TYPE;
    
    BEGIN
        log_debug(c_func_name || '()', c_func_name);
    
        IF i_order_recurr_option = pk_alert_constant.g_order_recurr_option_once
        THEN
            l_flg_type := pk_icnp_constant.g_epis_interv_type_once;
        ELSIF i_order_recurr_option = pk_alert_constant.g_order_recurr_option_no_sched
        THEN
            l_flg_type := pk_icnp_constant.g_epis_interv_type_no_schedule;
        ELSE
            l_flg_type := pk_icnp_constant.g_epis_interv_type_recurrence;
        END IF;
    
        RETURN l_flg_type;
    
    END map_recurr_option_to_type;

    /**
     * Converts a raw data record sent by ux, with the data of one intervention and 
     * its associated diagnose (when invoking the method to create a new ICNP 
     * interventation), into a typed record.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_values Array with the values for one record. Each position corresponds
     *                 to a predefined type of information.
     * 
     * @return Typed record with the data of one intervention and its associated 
     *         diagnose.
     *
     * @author Luis Oliveira
     * @version 1.0
     * @since 02/Jun/2011
    */
    FUNCTION populate_create_interv_rec
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_values table_varchar
    ) RETURN data_ux_ci_rec IS
        -- Constants
        -- Function name
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'populate_create_interv_rec';
        -- Indexes of the fields stored in table_varchar
        c_idx_ci_compo_interv_id     CONSTANT PLS_INTEGER := 1;
        c_idx_ci_compo_diag_id       CONSTANT PLS_INTEGER := 2;
        c_idx_ci_flg_time            CONSTANT PLS_INTEGER := 3;
        c_idx_ci_dt_begin            CONSTANT PLS_INTEGER := 4;
        c_idx_ci_recurr_id           CONSTANT PLS_INTEGER := 5;
        c_idx_ci_flg_prn             CONSTANT PLS_INTEGER := 6;
        c_idx_ci_prn_notes           CONSTANT PLS_INTEGER := 7;
        c_idx_ci_notes               CONSTANT PLS_INTEGER := 8;
        c_idx_ci_suggested_interv_id CONSTANT PLS_INTEGER := 9;
        c_idx_ci_recurr_id_new       CONSTANT PLS_INTEGER := 10;
    
        l_data_ux_rec data_ux_ci_rec;
        -- Variables
        l_dt_begin_tstz icnp_epis_intervention.dt_begin_tstz%TYPE;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '()', c_func_name);
    
        -- Convert serialized date sent by ux to a timestamp with time zone
        l_dt_begin_tstz := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                         i_prof      => i_prof,
                                                         i_timestamp => i_values(c_idx_ci_dt_begin),
                                                         i_timezone  => NULL);
    
        -- Load the raw data sent by ux into a typed record
        l_data_ux_rec.id_composition_interv := to_number(i_values(c_idx_ci_compo_interv_id));
        l_data_ux_rec.id_composition_diag   := to_number(i_values(c_idx_ci_compo_diag_id));
        l_data_ux_rec.flg_time              := i_values(c_idx_ci_flg_time);
        l_data_ux_rec.dt_begin_tstz         := l_dt_begin_tstz;
        l_data_ux_rec.id_order_recurr_plan  := to_number(i_values(c_idx_ci_recurr_id));
        l_data_ux_rec.flg_prn               := i_values(c_idx_ci_flg_prn);
        l_data_ux_rec.prn_notes             := i_values(c_idx_ci_prn_notes);
        l_data_ux_rec.notes                 := i_values(c_idx_ci_notes);
    
        -- The identifier of the suggested intervention is optional
        IF to_number(i_values(c_idx_ci_suggested_interv_id)) IS NOT NULL
        THEN
            l_data_ux_rec.id_icnp_sug_interv := to_number(i_values(c_idx_ci_suggested_interv_id));
        END IF;
    
        RETURN l_data_ux_rec;
    
    END populate_create_interv_rec;

    /**
     * Associates a set of ICNP diagnosis with an episode.
     *
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_episode The episode identifier.
     * @param i_patient The patient identifier.
     * @param i_diag Collection with the identifiers of all the diagnosis to insert.
     * @param i_exp_res Collection with the identifiers of the expected results for all the diagnosis.
     * @param i_notes Collection with the notes for all the diagnosis.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * 
     * @return Collection with all the inserted icnp_epis_diagnosis rows.
     *
     * @author Luis Oliveira
     * @version 1.0
     * @since 02/Jun/2011
    */
    FUNCTION create_icnp_diags
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_patient      IN patient.id_patient%TYPE,
        i_diag         IN table_number,
        i_exp_res      IN table_number,
        i_notes        IN table_varchar,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN ts_icnp_epis_diagnosis.icnp_epis_diagnosis_tc IS
        -- Function name
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'create_icnp_diags';
        -- Info related with the given episode
        l_id_visit     icnp_epis_diagnosis.id_visit%TYPE;
        l_id_epis_type icnp_epis_diagnosis.id_epis_type%TYPE;
        -- Data structures related with icnp_epis_diagnosis
        l_epis_diag_row_coll ts_icnp_epis_diagnosis.icnp_epis_diagnosis_tc;
    
    BEGIN
        log_debug(c_func_name || '(i_lang:' || i_lang || ', i_prof:' || pk_icnp_util.to_string(i_prof) ||
                  ', i_episode:' || i_episode || ', i_patient:' || i_patient || ', i_diag:' ||
                  pk_utils.to_string(i_diag) || ', i_exp_res:' || pk_utils.to_string(i_exp_res) || ', i_notes:' ||
                  pk_utils.to_string(i_notes) || ')',
                  c_func_name);
    
        -- Check the input parameters
        IF pk_icnp_util.is_table_empty(i_diag)
           AND pk_icnp_util.is_table_empty(i_exp_res)
           AND pk_icnp_util.is_table_empty(i_notes)
        THEN
            -- There is nothing to do: return an empty collection
            log_debug('All the tables are empty: return', c_func_name);
            RETURN l_epis_diag_row_coll;
        END IF;
        IF i_diag.count <> i_exp_res.count
           OR i_diag.count <> i_notes.count
        THEN
            pk_alert_exceptions.raise_error(error_name_in => pk_icnp_constant.g_excep_inv_input_params,
                                            text_in       => 'The tables given as input parameter are not equally sized');
        END IF;
    
        -- Get info related with the given episode
        l_id_visit     := pk_episode.get_id_visit(i_episode => i_episode);
        l_id_epis_type := pk_episode.get_epis_type(i_lang => i_lang, i_id_epis => i_episode);
    
        -- Loop the diagnosis and add them to a collection
        FOR i IN i_diag.first .. i_diag.last
        LOOP
            log_debug('Processing i_diag(' || i || '): ' || i_diag(i), c_func_name);
        
            -- Check if it is a valid diagnose identifier
            IF i_diag(i) IS NULL
            THEN
                pk_alert_exceptions.raise_error(error_name_in => pk_icnp_constant.g_excep_null_identifier,
                                                text_in       => 'Tried to insert a diagnose with null identifier');
            END IF;
        
            -- Add icnp_epis_diagnosis row to collection (for further bulk processing)
            l_epis_diag_row_coll(i) := pk_icnp_diag.create_diag_row(i_lang         => i_lang,
                                                                    i_prof         => i_prof,
                                                                    i_episode      => i_episode,
                                                                    i_patient      => i_patient,
                                                                    i_visit        => l_id_visit,
                                                                    i_epis_type    => l_id_epis_type,
                                                                    i_diag         => i_diag(i),
                                                                    i_exp_res      => i_exp_res(i),
                                                                    i_notes        => i_notes(i),
                                                                    i_sysdate_tstz => i_sysdate_tstz);
        END LOOP;
    
        -- Create the diagnosis
        pk_icnp_diag.create_diags(i_lang         => i_lang,
                                  i_prof         => i_prof,
                                  i_diag_coll    => l_epis_diag_row_coll,
                                  i_sysdate_tstz => i_sysdate_tstz);
    
        RETURN l_epis_diag_row_coll;
    
    END create_icnp_diags;

    /**
     * Asssociates a set of interventions with a set of diagnosis.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_interv Array with the values for one record. Each position corresponds
     *                 to a predefined type of information.
     * @param i_diag_row_coll Collection with all the inserted icnp_epis_diagnosis rows.
     * @param i_cur_diag Diagnose identifier used when there is no records in i_diag_row_coll
     *                   collection.
     * @param i_assoc_interv Collection with all the identifiers of the inserted 
     *                       interventions.
     * @param i_moment_assoc Moment of creation of the association between intervention and diagnosis 'C' creation, 'A' association
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 26/Jul/2011
    */
    PROCEDURE create_assoc_interv_diag
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_interv         IN table_table_varchar,
        i_diag_row_coll  IN ts_icnp_epis_diagnosis.icnp_epis_diagnosis_tc,
        i_cur_diag       IN icnp_epis_diagnosis.id_icnp_epis_diag%TYPE,
        i_assoc_interv   IN table_number,
        i_moment_assoc   IN icnp_epis_diag_interv.flg_moment_assoc%TYPE DEFAULT 'C',
        i_flg_type_assoc IN icnp_epis_diag_interv.flg_type_assoc%TYPE DEFAULT 'D'
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'create_assoc_interv_diag';
    
        -- Typed i_interv record
        l_data_ux_rec data_ux_ci_rec;
        -- Data structures related with the associations between diagnosis and interventions
        l_edi_row        icnp_epis_diag_interv%ROWTYPE;
        l_iedih_row      icnp_epis_dg_int_hist%ROWTYPE;
        l_edi_row_coll   ts_icnp_epis_diag_interv.icnp_epis_diag_interv_tc;
        l_iedih_row_coll ts_icnp_epis_dg_int_hist.icnp_epis_dg_int_hist_tc;
        l_edi_id         table_number := table_number();
        l_iedih_id       table_number := table_number();
        l_rows_edi       table_varchar := table_varchar();
        -- Data structures related with error handling
        l_error t_error_out;
    
        l_next_key_iedi NUMBER(24);
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '()', c_func_name);
    
        -- Check the input parameters
        IF i_interv IS empty
        THEN
            RETURN;
        END IF;
    
        FOR i IN i_interv.first .. i_interv.last
        LOOP
            -- Converts the raw data record into a typed record
            l_data_ux_rec := populate_create_interv_rec(i_lang => i_lang, i_prof => i_prof, i_values => i_interv(i));
        
            l_next_key_iedi := ts_icnp_epis_diag_interv.next_key;
        
            l_edi_row.id_icnp_epis_diag_interv := l_next_key_iedi;
            l_edi_row.id_icnp_epis_interv      := i_assoc_interv(i);
            l_edi_row.flg_status               := pk_icnp_constant.g_interv_flg_status_a;
            l_edi_row.id_prof_assoc            := i_prof.id;
            l_edi_row.flg_moment_assoc         := i_moment_assoc;
            l_edi_row.flg_status_rel           := pk_icnp_constant.g_interv_rel_active;
            l_edi_row.flg_type_assoc           := i_flg_type_assoc;
        
            l_iedih_row.id_icnp_epis_dg_int_hist := ts_icnp_epis_dg_int_hist.next_key;
            l_iedih_row.id_icnp_epis_diag_interv := l_next_key_iedi;
            l_iedih_row.id_icnp_epis_interv      := i_assoc_interv(i);
            l_iedih_row.flg_status               := pk_icnp_constant.g_interv_flg_status_a;
            l_iedih_row.dt_hist                  := current_timestamp;
            l_iedih_row.flg_iud                  := pk_icnp_constant.g_iedih_flg_uid_i; --INSERT
            l_iedih_row.id_prof_assoc            := i_prof.id;
            l_iedih_row.flg_moment_assoc         := i_moment_assoc;
            l_iedih_row.flg_status_rel           := pk_icnp_constant.g_interv_rel_active;
            l_iedih_row.flg_type_assoc           := i_flg_type_assoc;
        
            IF i_diag_row_coll IS NULL
               OR i_diag_row_coll.count = 0
            THEN
                l_edi_row.id_icnp_epis_diag   := nvl(l_data_ux_rec.id_composition_diag, i_cur_diag);
                l_iedih_row.id_icnp_epis_diag := nvl(l_data_ux_rec.id_composition_diag, i_cur_diag);
            ELSE
                FOR j IN i_diag_row_coll.first .. i_diag_row_coll.last
                LOOP
                    IF i_diag_row_coll(j).id_composition = l_data_ux_rec.id_composition_diag
                    THEN
                        l_edi_row.id_icnp_epis_diag   := i_diag_row_coll(j).id_icnp_epis_diag;
                        l_iedih_row.id_icnp_epis_diag := i_diag_row_coll(j).id_icnp_epis_diag;
                    END IF;
                END LOOP;
            END IF;
        
            log_debug('insert associations / l_edi_row.id_icnp_epis_interv: ' || l_edi_row.id_icnp_epis_interv ||
                      ', l_edi_row.id_icnp_epis_diag: ' || l_edi_row.id_icnp_epis_diag,
                      c_func_name);
        
            IF l_edi_row.id_icnp_epis_diag IS NOT NULL
            THEN
                -- add row to collection
                l_edi_row_coll(i) := l_edi_row;
                l_iedih_row_coll(i) := l_iedih_row;
            END IF;
            -- add id to list of created ids
            l_edi_id.extend;
            l_edi_id(l_edi_id.last) := l_edi_row.id_icnp_epis_diag_interv;
            l_iedih_id.extend;
            l_iedih_id(l_iedih_id.last) := l_iedih_row.id_icnp_epis_dg_int_hist;
        END LOOP;
    
        -- Persist the associations into the database and brodcast the insert through the data 
        -- governace mechanism
        ts_icnp_epis_diag_interv.ins(rows_in => l_edi_row_coll, rows_out => l_rows_edi);
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'ICNP_EPIS_DIAG_INTERV',
                                      i_rowids     => l_rows_edi,
                                      o_error      => l_error);
        ts_icnp_epis_dg_int_hist.ins(rows_in => l_iedih_row_coll, rows_out => l_rows_edi);
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'ICNP_EPIS_DG_INT_HIST',
                                      i_rowids     => l_rows_edi,
                                      o_error      => l_error);
    END create_assoc_interv_diag;

    /**
     * Prepare the order plan executions by informing the recurrence mechanism that we are
     * ready to begin the executions. Doing it, adds the plan to the recurrene mechanism 
     * daily job that creates executions. This method also creates the initial set of 
     * executions.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_recurr_definit_ids_coll Collection with all the definitive recurrence
     *                                  identifiers.
     * @param i_interv_row_coll Collection with all the intervention rows that were
     *                          created or whose instructions were changed. We need
     *                          this collection to create the executions of the 
     *                          interventions with the frequency "once".
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 26/Jul/2011
    */
    PROCEDURE prepare_and_create_execs
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_recurr_definit_ids_coll IN table_number,
        i_interv_row_coll         IN ts_icnp_epis_intervention.icnp_epis_intervention_tc,
        i_sysdate_tstz            IN TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'prepare_and_create_execs';
        l_order_plan_exec t_tbl_order_recurr_plan;
        l_exec_to_process t_tbl_order_recurr_plan_sts;
        l_interv_row      icnp_epis_intervention%ROWTYPE;
        l_error           t_error_out;
    
    BEGIN
        -----
        -- Create the executions for all the requests that have a recurrence plan
        IF i_recurr_definit_ids_coll IS NOT empty
        THEN
            -- Prepare the order plan executions
            log_debug('calling pk_order_recurrence_api_db.prepare_order_recurr_plan function / i_recurr_definit_ids_coll: ' ||
                      pk_utils.to_string(i_recurr_definit_ids_coll),
                      c_func_name);
            IF NOT pk_order_recurrence_api_db.prepare_order_recurr_plan(i_lang            => i_lang,
                                                                        i_prof            => i_prof,
                                                                        i_order_plan      => i_recurr_definit_ids_coll,
                                                                        o_order_plan_exec => l_order_plan_exec,
                                                                        o_error           => l_error)
            THEN
                pk_icnp_util.raise_unexpected_error('pk_order_recurrence_api_db.prepare_order_recurr_plan', l_error);
            END IF;
        
            -- Create the first set of executions; the set is determined by the recurrence mechanism
            pk_icnp_exec.create_executions(i_lang            => i_lang,
                                           i_prof            => i_prof,
                                           i_exec_tab        => l_order_plan_exec,
                                           i_sysdate_tstz    => i_sysdate_tstz,
                                           o_exec_to_process => l_exec_to_process);
        END IF;
    
        -----
        -- When the frequency is "no schedule" or "once" the executions are not managed
        -- by the recurrence mechanism. Those type of execution doesn't have a recurrence 
        -- plan. When the frequency is "no schedule" the executions are not create 
        -- beforehand.
        FOR i IN 1 .. i_interv_row_coll.count
        LOOP
            l_interv_row := i_interv_row_coll(i);
        
            -- Create the executions for all requests that should be executed only once
            IF l_interv_row.flg_type = pk_icnp_constant.g_epis_interv_type_once
            THEN
                log_debug('create_execution / i_interv_row_coll(' || i || ') / id_order_recurr_plan=' ||
                          l_interv_row.id_order_recurr_plan || ', flg_time=' || l_interv_row.flg_time,
                          c_func_name);
                IF l_interv_row.flg_time IN
                   (pk_icnp_constant.g_epis_interv_time_curr_epis, pk_icnp_constant.g_epis_interv_time_before_epis)
                THEN
                    pk_icnp_exec.create_execution(i_lang              => i_lang,
                                                  i_prof              => i_prof,
                                                  i_epis_interv_id    => l_interv_row.id_icnp_epis_interv,
                                                  i_dt_plan_tstz      => l_interv_row.dt_begin_tstz,
                                                  i_exec_number       => NULL,
                                                  i_order_recurr_plan => l_interv_row.id_order_recurr_plan,
                                                  i_sysdate_tstz      => i_sysdate_tstz);
                END IF;
            END IF;
        END LOOP;
    
    END prepare_and_create_execs;

    /**
    * Update an ICNP intervention: given a set of interventions and it's instructions
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_interv       intervention identifiers and instructions list
    * @param i_sysdate_tstz Current timestamp that should be used across all the 
    *                       functions invoked from this one.
    * @param o_interv_id    created icnp_epis_intervention ids
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Nuno Neves
    * @version              2.5.1.8.2
    * @since                2011/10/10
    */
    PROCEDURE update_icnp_interv_int
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv           IN table_varchar,
        i_sysdate_tstz     IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_origin           IN VARCHAR2,
        o_interv_id        OUT table_number,
        io_precessed_plans IN OUT t_processed_plan
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'update_icnp_interv_int';
        -- Typed i_interv record
        l_rows table_varchar := table_varchar();
    
        l_recurr_definit_ids_coll table_number := table_number();
    
        -- Data structures related with error handling
        l_error t_error_out;
    
        -- Indexes of the fields stored in table_varchar
        c_idx_ci_compo_interv_id     CONSTANT PLS_INTEGER := 1;
        c_idx_ci_compo_diag_id       CONSTANT PLS_INTEGER := 2;
        c_idx_ci_flg_time            CONSTANT PLS_INTEGER := 3;
        c_idx_ci_dt_begin            CONSTANT PLS_INTEGER := 4;
        c_idx_ci_recurr_id_old       CONSTANT PLS_INTEGER := 5;
        c_idx_ci_flg_prn             CONSTANT PLS_INTEGER := 6;
        c_idx_ci_prn_notes           CONSTANT PLS_INTEGER := 7;
        c_idx_ci_notes               CONSTANT PLS_INTEGER := 8;
        c_idx_ci_suggested_interv_id CONSTANT PLS_INTEGER := 9;
        c_idx_ci_recurr_id_new       CONSTANT PLS_INTEGER := 10;
        c_idx_ci_act_intrv_sug       CONSTANT PLS_INTEGER := 11;
    
        l_order_recurr_option_id order_recurr_plan.id_order_recurr_option%TYPE;
        l_order_recurr_final_id  order_recurr_plan.id_order_recurr_plan%TYPE;
        l_count_r                NUMBER;
        l_exec_number            NUMBER;
    
        l_order_plan_exec       t_tbl_order_recurr_plan;
        l_flg_discard_old_plan  VARCHAR2(1);
        l_id_epis_documentation icnp_interv_plan.id_epis_documentation%TYPE := NULL;
        l_exec_rowids_coll      table_varchar;
        -- l_interv_id             table_number := table_number();
    
        l_interv_row_coll ts_icnp_epis_intervention.icnp_epis_intervention_tc;
        l_interv_hist     table_number;
        l_flg_type        icnp_epis_intervention.flg_type%TYPE;
    
        --o_error BOOLEAN;
        --Variables used for order_plan changes
        l_dt_next_sch       icnp_epis_intervention.dt_next_tstz%TYPE;
        l_check_date_change VARCHAR2(1);
        l_adit_exec         INTEGER := 0;
        l_date_aux          TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_flg_end_by        order_recurr_plan.flg_end_by%TYPE;
        l_tasks_to_exec     INTEGER := 0;
    BEGIN
    
        log_debug(c_func_name || '()', c_func_name);
    
        IF i_interv IS NOT NULL
        THEN
        
            --update order recurrence plan
            IF i_interv(c_idx_ci_recurr_id_new) IS NOT NULL
            THEN
            
                --Number of interventions using the same order recur plan
                SELECT COUNT(*)
                  INTO l_count_r
                  FROM icnp_epis_intervention iei
                 WHERE iei.id_order_recurr_plan = i_interv(c_idx_ci_recurr_id_old)
                   AND iei.flg_status IN (pk_icnp_constant.g_epis_interv_status_requested,
                                          pk_icnp_constant.g_epis_interv_status_ongoing,
                                          pk_icnp_constant.g_epis_interv_status_suspended);
            
                --Max of executions(previous)
                SELECT MAX(i.exec_number)
                  INTO l_exec_number
                  FROM icnp_interv_plan i
                 WHERE i.flg_status = pk_icnp_constant.g_interv_plan_status_executed
                   AND i.id_icnp_epis_interv = i_interv(c_idx_ci_compo_interv_id);
            
                --check if plan is used in 1 or more interventions
                IF l_count_r = 1
                THEN
                
                    --ending the old order recur plan
                    l_flg_discard_old_plan := pk_alert_constant.g_yes;
                ELSE
                
                    l_flg_discard_old_plan := pk_alert_constant.g_no;
                END IF;
            
                --set a temporary order recurrence plan as definitive (final status) and set as deprecated 
                log_debug('update_icnp_interv / i_recurr_plan_id: ' || i_interv(c_idx_ci_recurr_id_new), c_func_name);
            
                IF NOT io_precessed_plans.exists(i_interv(c_idx_ci_recurr_id_new))
                THEN
                    IF NOT
                        pk_order_recurrence_api_db.set_for_edit_order_recurr_plan(i_lang                    => i_lang,
                                                                                  i_prof                    => i_prof,
                                                                                  i_order_recurr_plan_old   => i_interv(c_idx_ci_recurr_id_old),
                                                                                  i_order_recurr_plan_new   => i_interv(c_idx_ci_recurr_id_new),
                                                                                  i_flg_discard_old_plan    => l_flg_discard_old_plan,
                                                                                  o_order_recurr_option     => l_order_recurr_option_id,
                                                                                  o_final_order_recurr_plan => l_order_recurr_final_id,
                                                                                  o_error                   => l_error)
                    THEN
                        pk_icnp_util.raise_unexpected_error('pk_order_recurrence_api_db.set_for_edit_order_recurr_plan',
                                                            l_error);
                    END IF;
                    -- add plan values to processed array
                    io_precessed_plans(i_interv(c_idx_ci_recurr_id_new)).id_order_recurr_option := l_order_recurr_option_id;
                    io_precessed_plans(i_interv(c_idx_ci_recurr_id_new)).id_order_recurr_plan := l_order_recurr_final_id;
                
                ELSE
                
                    l_order_recurr_option_id := io_precessed_plans(i_interv(c_idx_ci_recurr_id_new)).id_order_recurr_option;
                    l_order_recurr_final_id  := io_precessed_plans(i_interv(c_idx_ci_recurr_id_new)).id_order_recurr_plan;
                END IF;
            
                IF (l_order_recurr_final_id IS NOT NULL)
                THEN
                
                    l_recurr_definit_ids_coll.extend;
                    l_recurr_definit_ids_coll(l_recurr_definit_ids_coll.count) := l_order_recurr_final_id;
                
                    --prepare the order plan executions based in plan's area and interval configurations
                    IF NOT pk_order_recurrence_api_db.prepare_order_recurr_plan(i_lang            => i_lang,
                                                                                i_prof            => i_prof,
                                                                                i_order_plan      => l_recurr_definit_ids_coll,
                                                                                o_order_plan_exec => l_order_plan_exec,
                                                                                o_error           => l_error)
                    THEN
                        pk_icnp_util.raise_unexpected_error('pk_order_recurrence_api_db.prepare_order_recurr_plan',
                                                            l_error);
                    END IF;
                END IF;
            
                BEGIN
                    SELECT orp.flg_end_by
                      INTO l_flg_end_by
                      FROM order_recurr_plan orp
                     WHERE orp.id_order_recurr_plan = l_order_plan_exec(1).id_order_recurrence_plan;
                EXCEPTION
                    WHEN OTHERS THEN
                        l_flg_end_by := NULL;
                END;
            
                IF l_flg_end_by IN ('L', 'D')
                THEN
                    SELECT COUNT(*)
                      INTO l_tasks_to_exec
                      FROM icnp_interv_plan iip
                     WHERE iip.id_order_recurr_plan = i_interv(5)
                       AND iip.flg_status = 'R';
                END IF;
            
                --GET THE NEXT PLANNED EXECUTION DATE
                BEGIN
                    SELECT dt_exec
                      INTO l_dt_next_sch
                      FROM (SELECT i.id_icnp_interv_plan,
                                   i.id_icnp_epis_interv,
                                   i.flg_status,
                                   i.dt_plan_tstz AS dt_exec,
                                   i.exec_number,
                                   i.id_order_recurr_plan,
                                   row_number() over(PARTITION BY i.id_order_recurr_plan ORDER BY i.exec_number ASC, i.dt_plan_tstz ASC) AS rn
                              FROM icnp_interv_plan i
                             WHERE i.id_icnp_epis_interv = i_interv(c_idx_ci_compo_interv_id)
                               AND i.id_order_recurr_plan IS NOT NULL
                               AND i.flg_status = pk_icnp_constant.g_interv_plan_status_requested
                             ORDER BY i.exec_number ASC)
                     WHERE rn = 1;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_dt_next_sch := NULL;
                END;
            
                --CHECK IF THE 'NEW' NEXT EXECUTION DATE HAS BEEN CHANGED
                --E - REMAINS THE SAME
                --L - ANTICIPATED
                --G - POSTEPONED
                l_check_date_change := pk_date_utils.compare_dates_tsz(i_prof,
                                                                       pk_date_utils.get_string_tstz(i_lang,
                                                                                                     i_prof,
                                                                                                     i_interv(c_idx_ci_dt_begin),
                                                                                                     NULL),
                                                                       l_dt_next_sch);
            
                --cancel executions not executed ('M' - frequency changed)
                l_rows := table_varchar();
                ts_icnp_interv_plan.upd(flg_status_in    => pk_icnp_constant.g_interv_plan_status_freq_alt,
                                        dt_plan_tstz_in  => NULL,
                                        dt_plan_tstz_nin => FALSE,
                                        where_in         => 'flg_status=''' ||
                                                            pk_icnp_constant.g_interv_plan_status_requested ||
                                                            ''' AND id_icnp_epis_interv = ' ||
                                                            i_interv(c_idx_ci_compo_interv_id),
                                        rows_out         => l_rows);
            
                t_data_gov_mnt.process_update(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_table_name   => 'ICNP_INTERV_PLAN',
                                              i_rowids       => l_rows,
                                              o_error        => l_error,
                                              i_list_columns => table_varchar('FLG_STATUS'));
            
                --create new executions            
                IF l_exec_number IS NOT NULL
                THEN
                    SELECT iip.id_epis_documentation
                      INTO l_id_epis_documentation
                      FROM icnp_interv_plan iip
                     WHERE iip.id_icnp_epis_interv = i_interv(c_idx_ci_compo_interv_id)
                       AND iip.exec_number = l_exec_number
                       AND rownum = 1;
                END IF;
            
                IF l_order_recurr_option_id = 0 --- ONCE
                THEN
                    -- Persist the data into the database and brodcast the update through the data 
                    -- governace mechanism
                    IF l_exec_number IS NOT NULL
                    -- AND l_id_epis_documentation IS NOT NULL
                    THEN
                        ts_icnp_interv_plan.ins(id_icnp_interv_plan_in   => ts_icnp_interv_plan.next_key,
                                                id_icnp_epis_interv_in   => i_interv(c_idx_ci_compo_interv_id),
                                                flg_status_in            => pk_icnp_constant.g_interv_plan_status_requested,
                                                dt_plan_tstz_in          => pk_date_utils.get_string_tstz(i_lang,
                                                                                                          i_prof,
                                                                                                          i_interv(c_idx_ci_dt_begin),
                                                                                                          NULL),
                                                id_prof_created_in       => i_prof.id,
                                                dt_created_in            => i_sysdate_tstz,
                                                dt_last_update_in        => i_sysdate_tstz,
                                                id_epis_documentation_in => l_id_epis_documentation,
                                                exec_number_in           => l_exec_number + 1,
                                                rows_out                 => l_exec_rowids_coll);
                    
                        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'ICNP_INTERV_PLAN',
                                                      i_rowids     => l_exec_rowids_coll,
                                                      o_error      => l_error);
                    
                    ELSE
                        ts_icnp_interv_plan.ins(id_icnp_interv_plan_in   => ts_icnp_interv_plan.next_key,
                                                id_icnp_epis_interv_in   => i_interv(c_idx_ci_compo_interv_id),
                                                flg_status_in            => pk_icnp_constant.g_interv_plan_status_requested,
                                                dt_plan_tstz_in          => pk_date_utils.get_string_tstz(i_lang,
                                                                                                          i_prof,
                                                                                                          i_interv(c_idx_ci_dt_begin),
                                                                                                          NULL),
                                                id_prof_created_in       => i_prof.id,
                                                dt_created_in            => i_sysdate_tstz,
                                                dt_last_update_in        => i_sysdate_tstz,
                                                id_epis_documentation_in => l_id_epis_documentation,
                                                exec_number_in           => 1,
                                                rows_out                 => l_exec_rowids_coll);
                    
                        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'ICNP_INTERV_PLAN',
                                                      i_rowids     => l_exec_rowids_coll,
                                                      o_error      => l_error);
                    END IF;
                ELSIF l_order_recurr_option_id <> -2
                THEN
                    --WITH RECURRENCE
                    IF l_exec_number IS NOT NULL
                    --AND l_id_epis_documentation IS NOT NULL
                    THEN
                    
                        IF (l_flg_end_by NOT IN ('L', 'D'))
                           OR (l_flg_end_by <> 'L' AND i_origin <> 'E')
                           OR (l_flg_end_by <> 'D' AND i_origin <> 'E')
                        THEN
                            DECLARE
                                l_freq_pre_def  BOOLEAN := FALSE; --Variable to check if the next execution date falls on the pre-defined execution date (pre-defined frequencies)
                                l_sch_date_prev BOOLEAN := FALSE; --Variable to check if the next execution has been anticipated
                            BEGIN
                                <<req>>
                                FOR req_idx IN 1 .. l_order_plan_exec.count
                                LOOP
                                
                                    --CHECK IF THE 'NEW' NEXT EXECUTION DATE IS DIFFERENT FROM THE 'PRE-DEFINED' EXECUTION DATE     
                                    IF pk_date_utils.get_string_tstz(i_lang, i_prof, i_interv(c_idx_ci_dt_begin), NULL) <> l_order_plan_exec(req_idx).exec_timestamp
                                       AND req_idx = 1
                                    THEN
                                    
                                        l_freq_pre_def := TRUE;
                                    
                                        --CHECK IF THE CHANGE ON THE NEXT SCHEDULLED EXECUTION IS SET FOR A DATE BEFORE THE SCHEDULLED DATE
                                        IF l_check_date_change = 'L'
                                        THEN
                                            l_sch_date_prev := TRUE;
                                            ts_icnp_interv_plan.ins(id_icnp_interv_plan_in   => ts_icnp_interv_plan.next_key,
                                                                    id_icnp_epis_interv_in   => i_interv(c_idx_ci_compo_interv_id),
                                                                    flg_status_in            => pk_icnp_constant.g_interv_plan_status_requested,
                                                                    dt_plan_tstz_in          => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                              i_prof,
                                                                                                                              i_interv(c_idx_ci_dt_begin),
                                                                                                                              NULL),
                                                                    id_prof_created_in       => i_prof.id,
                                                                    dt_created_in            => i_sysdate_tstz,
                                                                    dt_last_update_in        => i_sysdate_tstz,
                                                                    id_epis_documentation_in => l_id_epis_documentation,
                                                                    exec_number_in           => l_exec_number + l_order_plan_exec(req_idx).exec_number,
                                                                    id_order_recurr_plan_in  => l_order_recurr_final_id,
                                                                    rows_out                 => l_exec_rowids_coll);
                                        
                                            IF pk_date_utils.compare_dates_tsz(i_prof,
                                                                               pk_date_utils.get_string_tstz(i_lang,
                                                                                                             i_prof,
                                                                                                             i_interv(c_idx_ci_dt_begin),
                                                                                                             NULL),
                                                                               l_order_plan_exec(req_idx).exec_timestamp) = 'L'
                                               AND i_origin = pk_icnp_constant.g_interv_plan_editing
                                            THEN
                                                l_sch_date_prev := FALSE; --TO PREVENT EXTRA EXECUTION (it has been anticipated regarding the next scheduled task but not regarding the next pre-defined hour)
                                                ts_icnp_interv_plan.ins(id_icnp_interv_plan_in   => ts_icnp_interv_plan.next_key,
                                                                        id_icnp_epis_interv_in   => i_interv(c_idx_ci_compo_interv_id),
                                                                        flg_status_in            => pk_icnp_constant.g_interv_plan_status_requested,
                                                                        dt_plan_tstz_in          => l_order_plan_exec(req_idx).exec_timestamp,
                                                                        id_prof_created_in       => i_prof.id,
                                                                        dt_created_in            => i_sysdate_tstz,
                                                                        dt_last_update_in        => i_sysdate_tstz,
                                                                        id_epis_documentation_in => l_id_epis_documentation,
                                                                        exec_number_in           => l_exec_number + l_order_plan_exec(req_idx).exec_number + 1,
                                                                        id_order_recurr_plan_in  => l_order_recurr_final_id,
                                                                        rows_out                 => l_exec_rowids_coll);
                                            END IF;
                                        
                                        ELSE
                                            --CHANGE ON THE NEXT SCHEDULLED EXECUTION IS SET FOR A DATE AFTER THE SCHEDULLED DATE
                                        
                                            BEGIN
                                                ts_icnp_interv_plan.ins(id_icnp_interv_plan_in   => ts_icnp_interv_plan.next_key,
                                                                        id_icnp_epis_interv_in   => i_interv(c_idx_ci_compo_interv_id),
                                                                        flg_status_in            => pk_icnp_constant.g_interv_plan_status_requested,
                                                                        dt_plan_tstz_in          => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                  i_prof,
                                                                                                                                  i_interv(c_idx_ci_dt_begin),
                                                                                                                                  NULL),
                                                                        id_prof_created_in       => i_prof.id,
                                                                        dt_created_in            => i_sysdate_tstz,
                                                                        dt_last_update_in        => i_sysdate_tstz,
                                                                        id_epis_documentation_in => l_id_epis_documentation,
                                                                        exec_number_in           => l_exec_number + l_order_plan_exec(req_idx).exec_number,
                                                                        id_order_recurr_plan_in  => l_order_recurr_final_id,
                                                                        rows_out                 => l_exec_rowids_coll);
                                            
                                                IF req_idx < l_order_plan_exec.count
                                                THEN
                                                    ts_icnp_interv_plan.ins(id_icnp_interv_plan_in   => ts_icnp_interv_plan.next_key,
                                                                            id_icnp_epis_interv_in   => i_interv(c_idx_ci_compo_interv_id),
                                                                            flg_status_in            => pk_icnp_constant.g_interv_plan_status_requested,
                                                                            dt_plan_tstz_in          => l_order_plan_exec(req_idx).exec_timestamp,
                                                                            id_prof_created_in       => i_prof.id,
                                                                            dt_created_in            => i_sysdate_tstz,
                                                                            dt_last_update_in        => i_sysdate_tstz,
                                                                            id_epis_documentation_in => l_id_epis_documentation,
                                                                            exec_number_in           => l_exec_number + l_order_plan_exec(req_idx).exec_number + 1,
                                                                            id_order_recurr_plan_in  => l_order_recurr_final_id,
                                                                            rows_out                 => l_exec_rowids_coll);
                                                END IF;
                                            END;
                                        END IF;
                                    
                                        --CHECK IF IS NOT THE NEXT EXECUTION AND IF THE NEXT EXECUTION WAS POSTPONED
                                    ELSIF req_idx < l_order_plan_exec.count
                                          AND l_freq_pre_def = TRUE
                                          AND l_sch_date_prev = FALSE
                                    THEN
                                        ts_icnp_interv_plan.ins(id_icnp_interv_plan_in   => ts_icnp_interv_plan.next_key,
                                                                id_icnp_epis_interv_in   => i_interv(c_idx_ci_compo_interv_id),
                                                                flg_status_in            => pk_icnp_constant.g_interv_plan_status_requested,
                                                                dt_plan_tstz_in          => l_order_plan_exec(req_idx).exec_timestamp,
                                                                id_prof_created_in       => i_prof.id,
                                                                dt_created_in            => i_sysdate_tstz,
                                                                dt_last_update_in        => i_sysdate_tstz,
                                                                id_epis_documentation_in => l_id_epis_documentation,
                                                                exec_number_in           => l_exec_number + l_order_plan_exec(req_idx).exec_number + 1,
                                                                id_order_recurr_plan_in  => l_order_recurr_final_id,
                                                                rows_out                 => l_exec_rowids_coll);
                                    
                                        --CHECK IF THE FREQUENCY HAS PRE-DEFINED HOURS, IF IS NOT THE NEXT EXECUTION AND IF THE NEXT EXECUTION WAS ANTICIPATED
                                    ELSIF req_idx < l_order_plan_exec.count
                                          AND l_freq_pre_def = TRUE
                                          AND l_sch_date_prev = TRUE
                                    THEN
                                        ts_icnp_interv_plan.ins(id_icnp_interv_plan_in   => ts_icnp_interv_plan.next_key,
                                                                id_icnp_epis_interv_in   => i_interv(c_idx_ci_compo_interv_id),
                                                                flg_status_in            => pk_icnp_constant.g_interv_plan_status_requested,
                                                                dt_plan_tstz_in          => l_order_plan_exec(req_idx).exec_timestamp,
                                                                id_prof_created_in       => i_prof.id,
                                                                dt_created_in            => i_sysdate_tstz,
                                                                dt_last_update_in        => i_sysdate_tstz,
                                                                id_epis_documentation_in => l_id_epis_documentation,
                                                                exec_number_in           => l_exec_number + l_order_plan_exec(req_idx).exec_number,
                                                                id_order_recurr_plan_in  => l_order_recurr_final_id,
                                                                rows_out                 => l_exec_rowids_coll);
                                    
                                    ELSIF l_freq_pre_def = FALSE
                                          OR l_sch_date_prev = TRUE
                                    THEN
                                        ts_icnp_interv_plan.ins(id_icnp_interv_plan_in   => ts_icnp_interv_plan.next_key,
                                                                id_icnp_epis_interv_in   => i_interv(c_idx_ci_compo_interv_id),
                                                                flg_status_in            => pk_icnp_constant.g_interv_plan_status_requested,
                                                                dt_plan_tstz_in          => l_order_plan_exec(req_idx).exec_timestamp,
                                                                id_prof_created_in       => i_prof.id,
                                                                dt_created_in            => i_sysdate_tstz,
                                                                dt_last_update_in        => i_sysdate_tstz,
                                                                id_epis_documentation_in => l_id_epis_documentation,
                                                                exec_number_in           => l_exec_number + l_order_plan_exec(req_idx).exec_number,
                                                                id_order_recurr_plan_in  => l_order_recurr_final_id,
                                                                rows_out                 => l_exec_rowids_coll);
                                    
                                        --CHECK IF THE PLAN IS SET AS 'END BY END DATE' AND ADDS THE LAST EXECUTION IF SO
                                    ELSIF req_idx = l_order_plan_exec.count
                                          AND l_flg_end_by IN ('L', 'D')
                                    THEN
                                        ts_icnp_interv_plan.ins(id_icnp_interv_plan_in   => ts_icnp_interv_plan.next_key,
                                                                id_icnp_epis_interv_in   => i_interv(c_idx_ci_compo_interv_id),
                                                                flg_status_in            => pk_icnp_constant.g_interv_plan_status_requested,
                                                                dt_plan_tstz_in          => l_order_plan_exec(req_idx).exec_timestamp,
                                                                id_prof_created_in       => i_prof.id,
                                                                dt_created_in            => i_sysdate_tstz,
                                                                dt_last_update_in        => i_sysdate_tstz,
                                                                id_epis_documentation_in => l_id_epis_documentation,
                                                                exec_number_in           => l_exec_number + l_order_plan_exec(req_idx).exec_number + 1,
                                                                id_order_recurr_plan_in  => l_order_recurr_final_id,
                                                                rows_out                 => l_exec_rowids_coll);
                                    
                                    END IF;
                                
                                    t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                                  i_prof       => i_prof,
                                                                  i_table_name => 'ICNP_INTERV_PLAN',
                                                                  i_rowids     => l_exec_rowids_coll,
                                                                  o_error      => l_error);
                                
                                END LOOP req;
                            END;
                        
                        ELSIF l_flg_end_by IN ('L', 'D')
                        THEN
                            DECLARE
                                l_check_not_pre_def BOOLEAN := FALSE;
                            BEGIN
                            
                                FOR req_idx IN 1 .. l_tasks_to_exec
                                LOOP
                                
                                    IF req_idx = 1
                                    THEN
                                        ts_icnp_interv_plan.ins(id_icnp_interv_plan_in   => ts_icnp_interv_plan.next_key,
                                                                id_icnp_epis_interv_in   => i_interv(c_idx_ci_compo_interv_id),
                                                                flg_status_in            => pk_icnp_constant.g_interv_plan_status_requested,
                                                                dt_plan_tstz_in          => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                          i_prof,
                                                                                                                          i_interv(c_idx_ci_dt_begin),
                                                                                                                          NULL),
                                                                id_prof_created_in       => i_prof.id,
                                                                dt_created_in            => i_sysdate_tstz,
                                                                dt_last_update_in        => i_sysdate_tstz,
                                                                id_epis_documentation_in => l_id_epis_documentation,
                                                                exec_number_in           => l_exec_number + l_order_plan_exec(req_idx).exec_number,
                                                                id_order_recurr_plan_in  => l_order_recurr_final_id,
                                                                rows_out                 => l_exec_rowids_coll);
                                    
                                        --CHECK IF THIS IS A FREQUENCY WITHOU PRE-DEFINED HOURS
                                        IF pk_date_utils.compare_dates_tsz(i_prof,
                                                                           pk_date_utils.get_string_tstz(i_lang,
                                                                                                         i_prof,
                                                                                                         i_interv(c_idx_ci_dt_begin),
                                                                                                         NULL),
                                                                           l_order_plan_exec(req_idx).exec_timestamp) = 'E'
                                        THEN
                                            l_check_not_pre_def := TRUE;
                                        END IF;
                                    
                                        --IF THE NEXT TASK HAS BEEN DELAYED, FREQUENCY IS END BY DATE AND HAS PRE-DEFINED HOURS
                                        IF l_check_date_change <> 'L'
                                           AND l_flg_end_by = 'D'
                                           AND req_idx <> l_tasks_to_exec
                                           AND l_check_not_pre_def = FALSE
                                        THEN
                                            ts_icnp_interv_plan.ins(id_icnp_interv_plan_in   => ts_icnp_interv_plan.next_key,
                                                                    id_icnp_epis_interv_in   => i_interv(c_idx_ci_compo_interv_id),
                                                                    flg_status_in            => pk_icnp_constant.g_interv_plan_status_requested,
                                                                    dt_plan_tstz_in          => l_order_plan_exec(req_idx).exec_timestamp,
                                                                    id_prof_created_in       => i_prof.id,
                                                                    dt_created_in            => i_sysdate_tstz,
                                                                    dt_last_update_in        => i_sysdate_tstz,
                                                                    id_epis_documentation_in => l_id_epis_documentation,
                                                                    exec_number_in           => l_exec_number + l_order_plan_exec(req_idx).exec_number + 1,
                                                                    id_order_recurr_plan_in  => l_order_recurr_final_id,
                                                                    rows_out                 => l_exec_rowids_coll);
                                        
                                        END IF;
                                    
                                        --NEXT TASK IS ANTICIPATED                                                           
                                    ELSIF l_check_date_change = 'L'
                                    THEN
                                        ts_icnp_interv_plan.ins(id_icnp_interv_plan_in   => ts_icnp_interv_plan.next_key,
                                                                id_icnp_epis_interv_in   => i_interv(c_idx_ci_compo_interv_id),
                                                                flg_status_in            => pk_icnp_constant.g_interv_plan_status_requested,
                                                                dt_plan_tstz_in          => l_order_plan_exec(req_idx).exec_timestamp,
                                                                id_prof_created_in       => i_prof.id,
                                                                dt_created_in            => i_sysdate_tstz,
                                                                dt_last_update_in        => i_sysdate_tstz,
                                                                id_epis_documentation_in => l_id_epis_documentation,
                                                                exec_number_in           => l_exec_number + l_order_plan_exec(req_idx).exec_number,
                                                                id_order_recurr_plan_in  => l_order_recurr_final_id,
                                                                rows_out                 => l_exec_rowids_coll);
                                    
                                        --NEXT TASK IS DELAYED, FREQUENCY WITHOUT PRE-DEFINED HOURS AND END BY DURATION
                                    ELSIF l_check_date_change <> 'L'
                                          AND l_check_not_pre_def = TRUE
                                          AND l_flg_end_by = 'L'
                                    THEN
                                        ts_icnp_interv_plan.ins(id_icnp_interv_plan_in   => ts_icnp_interv_plan.next_key,
                                                                id_icnp_epis_interv_in   => i_interv(c_idx_ci_compo_interv_id),
                                                                flg_status_in            => pk_icnp_constant.g_interv_plan_status_requested,
                                                                dt_plan_tstz_in          => l_order_plan_exec(req_idx).exec_timestamp,
                                                                id_prof_created_in       => i_prof.id,
                                                                dt_created_in            => i_sysdate_tstz,
                                                                dt_last_update_in        => i_sysdate_tstz,
                                                                id_epis_documentation_in => l_id_epis_documentation,
                                                                exec_number_in           => l_exec_number + l_order_plan_exec(req_idx).exec_number,
                                                                id_order_recurr_plan_in  => l_order_recurr_final_id,
                                                                rows_out                 => l_exec_rowids_coll);
                                    
                                        --NEXT TASK IS DELAYED, FREQUENCY WITHOUT PRE-DEFINED HOURS AND END BY DATE
                                    ELSIF l_check_date_change <> 'L'
                                          AND l_check_not_pre_def = TRUE
                                          AND l_flg_end_by = 'D'
                                    THEN
                                        IF req_idx < l_tasks_to_exec
                                        THEN
                                            ts_icnp_interv_plan.ins(id_icnp_interv_plan_in   => ts_icnp_interv_plan.next_key,
                                                                    id_icnp_epis_interv_in   => i_interv(c_idx_ci_compo_interv_id),
                                                                    flg_status_in            => pk_icnp_constant.g_interv_plan_status_requested,
                                                                    dt_plan_tstz_in          => l_order_plan_exec(req_idx).exec_timestamp,
                                                                    id_prof_created_in       => i_prof.id,
                                                                    dt_created_in            => i_sysdate_tstz,
                                                                    dt_last_update_in        => i_sysdate_tstz,
                                                                    id_epis_documentation_in => l_id_epis_documentation,
                                                                    exec_number_in           => l_exec_number + l_order_plan_exec(req_idx - 1).exec_number + 1,
                                                                    id_order_recurr_plan_in  => l_order_recurr_final_id,
                                                                    rows_out                 => l_exec_rowids_coll);
                                        END IF;
                                    
                                        --NEXT TASK DELAYED, FREQUENCY WITH PRE-DEFINED HOURS AND 'END BY DATE'
                                    ELSIF l_check_date_change <> 'L'
                                          AND l_flg_end_by = 'D'
                                          AND req_idx < l_tasks_to_exec
                                          AND l_check_not_pre_def = FALSE
                                    THEN
                                        ts_icnp_interv_plan.ins(id_icnp_interv_plan_in   => ts_icnp_interv_plan.next_key,
                                                                id_icnp_epis_interv_in   => i_interv(c_idx_ci_compo_interv_id),
                                                                flg_status_in            => pk_icnp_constant.g_interv_plan_status_requested,
                                                                dt_plan_tstz_in          => l_order_plan_exec(req_idx).exec_timestamp,
                                                                id_prof_created_in       => i_prof.id,
                                                                dt_created_in            => i_sysdate_tstz,
                                                                dt_last_update_in        => i_sysdate_tstz,
                                                                id_epis_documentation_in => l_id_epis_documentation,
                                                                exec_number_in           => l_exec_number + l_order_plan_exec(req_idx).exec_number + 1,
                                                                id_order_recurr_plan_in  => l_order_recurr_final_id,
                                                                rows_out                 => l_exec_rowids_coll);
                                    
                                        ----NEXT TASK DELAYED, FREQUENCY WITH PRE-DEFINED HOURS AND END BY DURATION
                                    ELSIF l_check_date_change <> 'L'
                                          AND l_flg_end_by = 'L'
                                          AND l_check_not_pre_def = FALSE
                                    THEN
                                        ts_icnp_interv_plan.ins(id_icnp_interv_plan_in   => ts_icnp_interv_plan.next_key,
                                                                id_icnp_epis_interv_in   => i_interv(c_idx_ci_compo_interv_id),
                                                                flg_status_in            => pk_icnp_constant.g_interv_plan_status_requested,
                                                                dt_plan_tstz_in          => l_order_plan_exec(req_idx - 1).exec_timestamp,
                                                                id_prof_created_in       => i_prof.id,
                                                                dt_created_in            => i_sysdate_tstz,
                                                                dt_last_update_in        => i_sysdate_tstz,
                                                                id_epis_documentation_in => l_id_epis_documentation,
                                                                exec_number_in           => l_exec_number + l_order_plan_exec(req_idx - 1).exec_number + 1,
                                                                id_order_recurr_plan_in  => l_order_recurr_final_id,
                                                                rows_out                 => l_exec_rowids_coll);
                                    END IF;
                                END LOOP;
                            END;
                        
                            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                          i_table_name => 'ICNP_INTERV_PLAN',
                                                          i_rowids     => l_exec_rowids_coll,
                                                          o_error      => l_error);
                        
                        END IF;
                    
                    ELSE
                        --EDITING PLAN WITHOUT PREVIOUS EXECUTIONS
                        <<req>>
                        FOR req_idx IN 1 .. l_order_plan_exec.count
                        LOOP
                        
                            SELECT pk_date_utils.get_string_tstz(i_lang, i_prof, i_interv(c_idx_ci_dt_begin), NULL)
                              INTO l_date_aux
                              FROM dual;
                        
                            IF req_idx = 1
                            THEN
                            
                                IF l_date_aux <> l_order_plan_exec(req_idx).exec_timestamp
                                THEN
                                
                                    ts_icnp_interv_plan.ins(id_icnp_interv_plan_in   => ts_icnp_interv_plan.next_key,
                                                            id_icnp_epis_interv_in   => i_interv(c_idx_ci_compo_interv_id),
                                                            flg_status_in            => pk_icnp_constant.g_interv_plan_status_requested,
                                                            dt_plan_tstz_in          => l_date_aux,
                                                            id_prof_created_in       => i_prof.id,
                                                            dt_created_in            => i_sysdate_tstz,
                                                            dt_last_update_in        => i_sysdate_tstz,
                                                            id_epis_documentation_in => l_id_epis_documentation,
                                                            exec_number_in           => l_order_plan_exec(req_idx).exec_number,
                                                            id_order_recurr_plan_in  => l_order_recurr_final_id,
                                                            rows_out                 => l_exec_rowids_coll);
                                
                                    l_adit_exec := l_adit_exec + 1;
                                
                                END IF;
                            
                                ts_icnp_interv_plan.ins(id_icnp_interv_plan_in   => ts_icnp_interv_plan.next_key,
                                                        id_icnp_epis_interv_in   => i_interv(c_idx_ci_compo_interv_id),
                                                        flg_status_in            => pk_icnp_constant.g_interv_plan_status_requested,
                                                        dt_plan_tstz_in          => l_order_plan_exec(req_idx).exec_timestamp,
                                                        id_prof_created_in       => i_prof.id,
                                                        dt_created_in            => i_sysdate_tstz,
                                                        dt_last_update_in        => i_sysdate_tstz,
                                                        id_epis_documentation_in => l_id_epis_documentation,
                                                        exec_number_in           => l_order_plan_exec(req_idx)
                                                                                    .exec_number + l_adit_exec,
                                                        id_order_recurr_plan_in  => l_order_recurr_final_id,
                                                        rows_out                 => l_exec_rowids_coll);
                            
                                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                              i_prof       => i_prof,
                                                              i_table_name => 'ICNP_INTERV_PLAN',
                                                              i_rowids     => l_exec_rowids_coll,
                                                              o_error      => l_error);
                            
                            ELSIF req_idx < l_order_plan_exec.count
                            THEN
                                -- Persist the data into the database and brodcast the update through the data 
                                -- governace mechanism
                                ts_icnp_interv_plan.ins(id_icnp_interv_plan_in   => ts_icnp_interv_plan.next_key,
                                                        id_icnp_epis_interv_in   => i_interv(c_idx_ci_compo_interv_id),
                                                        flg_status_in            => pk_icnp_constant.g_interv_plan_status_requested,
                                                        dt_plan_tstz_in          => l_order_plan_exec(req_idx).exec_timestamp,
                                                        id_prof_created_in       => i_prof.id,
                                                        dt_created_in            => i_sysdate_tstz,
                                                        dt_last_update_in        => i_sysdate_tstz,
                                                        id_epis_documentation_in => l_id_epis_documentation,
                                                        exec_number_in           => l_order_plan_exec(req_idx)
                                                                                    .exec_number + l_adit_exec,
                                                        id_order_recurr_plan_in  => l_order_recurr_final_id,
                                                        rows_out                 => l_exec_rowids_coll);
                            
                                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                              i_prof       => i_prof,
                                                              i_table_name => 'ICNP_INTERV_PLAN',
                                                              i_rowids     => l_exec_rowids_coll,
                                                              o_error      => l_error);
                            
                            ELSIF req_idx = l_order_plan_exec.count
                                  AND l_date_aux = l_order_plan_exec(1).exec_timestamp
                            THEN
                            
                                ts_icnp_interv_plan.ins(id_icnp_interv_plan_in   => ts_icnp_interv_plan.next_key,
                                                        id_icnp_epis_interv_in   => i_interv(c_idx_ci_compo_interv_id),
                                                        flg_status_in            => pk_icnp_constant.g_interv_plan_status_requested,
                                                        dt_plan_tstz_in          => l_order_plan_exec(req_idx).exec_timestamp,
                                                        id_prof_created_in       => i_prof.id,
                                                        dt_created_in            => i_sysdate_tstz,
                                                        dt_last_update_in        => i_sysdate_tstz,
                                                        id_epis_documentation_in => l_id_epis_documentation,
                                                        exec_number_in           => l_order_plan_exec(req_idx)
                                                                                    .exec_number + l_adit_exec,
                                                        id_order_recurr_plan_in  => l_order_recurr_final_id,
                                                        rows_out                 => l_exec_rowids_coll);
                            
                                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                              i_prof       => i_prof,
                                                              i_table_name => 'ICNP_INTERV_PLAN',
                                                              i_rowids     => l_exec_rowids_coll,
                                                              o_error      => l_error);
                            
                            ELSIF req_idx = l_order_plan_exec.count
                                  AND l_flg_end_by IN ('D', 'L')
                            THEN
                                ts_icnp_interv_plan.ins(id_icnp_interv_plan_in   => ts_icnp_interv_plan.next_key,
                                                        id_icnp_epis_interv_in   => i_interv(c_idx_ci_compo_interv_id),
                                                        flg_status_in            => pk_icnp_constant.g_interv_plan_status_requested,
                                                        dt_plan_tstz_in          => l_order_plan_exec(req_idx).exec_timestamp,
                                                        id_prof_created_in       => i_prof.id,
                                                        dt_created_in            => i_sysdate_tstz,
                                                        dt_last_update_in        => i_sysdate_tstz,
                                                        id_epis_documentation_in => l_id_epis_documentation,
                                                        exec_number_in           => l_order_plan_exec(req_idx)
                                                                                    .exec_number + l_adit_exec,
                                                        id_order_recurr_plan_in  => l_order_recurr_final_id,
                                                        rows_out                 => l_exec_rowids_coll);
                            
                                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                              i_prof       => i_prof,
                                                              i_table_name => 'ICNP_INTERV_PLAN',
                                                              i_rowids     => l_exec_rowids_coll,
                                                              o_error      => l_error);
                            END IF;
                        END LOOP req;
                    END IF;
                END IF;
            
                IF l_order_recurr_option_id = 0
                THEN
                    --ONCE
                    -- Gets the intervention row of the id
                    l_interv_row_coll := pk_icnp_interv.get_interv_rows(i_interv_ids => table_number(i_interv(c_idx_ci_compo_interv_id)));
                
                    -- Creates history records for all the interventions
                    pk_icnp_interv.create_interv_hist(i_lang         => i_lang,
                                                      i_prof         => i_prof,
                                                      i_interv_coll  => l_interv_row_coll,
                                                      i_sysdate_tstz => i_sysdate_tstz,
                                                      o_interv_hist  => l_interv_hist);
                
                    --Update id_order_recurr_plan 
                    l_rows := table_varchar();
                    ts_icnp_epis_intervention.upd(id_icnp_epis_interv_in   => i_interv(c_idx_ci_compo_interv_id),
                                                  id_order_recurr_plan_in  => NULL,
                                                  id_order_recurr_plan_nin => FALSE,
                                                  notes_in                 => i_interv(c_idx_ci_notes),
                                                  flg_time_in              => i_interv(c_idx_ci_flg_time),
                                                  dt_begin_tstz_in         => pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                                                            i_prof      => i_prof,
                                                                                                            i_timestamp => i_interv(c_idx_ci_dt_begin),
                                                                                                            i_timezone  => NULL),
                                                  dt_next_tstz_in          => pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                                                            i_prof      => i_prof,
                                                                                                            i_timestamp => i_interv(c_idx_ci_dt_begin),
                                                                                                            i_timezone  => NULL),
                                                  flg_prn_in               => i_interv(c_idx_ci_flg_prn),
                                                  dt_last_update_in        => i_sysdate_tstz,
                                                  prn_notes_in             => i_interv(c_idx_ci_prn_notes),
                                                  prn_notes_nin            => FALSE,
                                                  flg_type_in              => pk_icnp_constant.g_epis_interv_type_once,
                                                  id_prof_last_update_in   => i_prof.id,
                                                  rows_out                 => l_rows);
                
                    t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'ICNP_EPIS_INTERVENTION',
                                                  i_rowids     => l_rows,
                                                  o_error      => l_error);
                
                ELSIF l_order_recurr_option_id <> -2
                THEN
                
                    --WITH RECURRENCE
                
                    -- Gets the intervention row of the id
                    l_interv_row_coll := pk_icnp_interv.get_interv_rows(i_interv_ids => table_number(i_interv(c_idx_ci_compo_interv_id)));
                
                    -- Creates history records for all the interventions
                    pk_icnp_interv.create_interv_hist(i_lang         => i_lang,
                                                      i_prof         => i_prof,
                                                      i_interv_coll  => l_interv_row_coll,
                                                      i_sysdate_tstz => i_sysdate_tstz,
                                                      o_interv_hist  => l_interv_hist);
                
                    --Update id_order_recurr_plan 
                    l_rows := table_varchar();
                    BEGIN
                    
                        ts_icnp_epis_intervention.upd(id_icnp_epis_interv_in  => i_interv(c_idx_ci_compo_interv_id),
                                                      id_order_recurr_plan_in => l_order_plan_exec(1).id_order_recurrence_plan,
                                                      notes_in                => i_interv(c_idx_ci_notes),
                                                      flg_time_in             => i_interv(c_idx_ci_flg_time),
                                                      dt_begin_tstz_in        => pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                                                               i_prof      => i_prof,
                                                                                                               i_timestamp => i_interv(c_idx_ci_dt_begin),
                                                                                                               i_timezone  => NULL),
                                                      dt_next_tstz_in         => pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                                                               i_prof      => i_prof,
                                                                                                               i_timestamp => i_interv(c_idx_ci_dt_begin),
                                                                                                               i_timezone  => NULL),
                                                      flg_prn_in              => i_interv(c_idx_ci_flg_prn),
                                                      prn_notes_in            => i_interv(c_idx_ci_prn_notes),
                                                      prn_notes_nin           => FALSE,
                                                      dt_last_update_in       => i_sysdate_tstz,
                                                      flg_type_in             => pk_icnp_constant.g_epis_interv_type_recurrence,
                                                      id_prof_last_update_in  => i_prof.id,
                                                      rows_out                => l_rows);
                    EXCEPTION
                        WHEN OTHERS THEN
                            ts_icnp_epis_intervention.upd(id_icnp_epis_interv_in  => i_interv(c_idx_ci_compo_interv_id),
                                                          id_order_recurr_plan_in => l_order_plan_exec(1).id_order_recurrence_plan,
                                                          notes_in                => i_interv(c_idx_ci_notes),
                                                          flg_time_in             => i_interv(c_idx_ci_flg_time),
                                                          dt_begin_tstz_in        => pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                                                                   i_prof      => i_prof,
                                                                                                                   i_timestamp => i_interv(c_idx_ci_dt_begin),
                                                                                                                   i_timezone  => NULL),
                                                          dt_next_tstz_in         => pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                                                                   i_prof      => i_prof,
                                                                                                                   i_timestamp => i_interv(c_idx_ci_dt_begin),
                                                                                                                   i_timezone  => NULL),
                                                          flg_prn_in              => i_interv(c_idx_ci_flg_prn),
                                                          prn_notes_in            => i_interv(c_idx_ci_prn_notes),
                                                          prn_notes_nin           => FALSE,
                                                          dt_last_update_in       => i_sysdate_tstz,
                                                          flg_type_in             => pk_icnp_constant.g_epis_interv_type_recurrence,
                                                          id_prof_last_update_in  => i_prof.id,
                                                          rows_out                => l_rows);
                    END;
                
                    t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'ICNP_EPIS_INTERVENTION',
                                                  i_rowids     => l_rows,
                                                  o_error      => l_error);
                
                ELSE
                    -- NO SCHEDULE
                
                    -- Gets the intervention row of the id
                    l_interv_row_coll := pk_icnp_interv.get_interv_rows(i_interv_ids => table_number(i_interv(c_idx_ci_compo_interv_id)));
                
                    -- Creates history records for all the interventions
                    pk_icnp_interv.create_interv_hist(i_lang         => i_lang,
                                                      i_prof         => i_prof,
                                                      i_interv_coll  => l_interv_row_coll,
                                                      i_sysdate_tstz => i_sysdate_tstz,
                                                      o_interv_hist  => l_interv_hist);
                
                    --Update id_order_recurr_plan 
                    l_rows := table_varchar();
                    ts_icnp_epis_intervention.upd(id_icnp_epis_interv_in   => i_interv(c_idx_ci_compo_interv_id),
                                                  id_order_recurr_plan_in  => NULL,
                                                  id_order_recurr_plan_nin => FALSE,
                                                  notes_in                 => i_interv(c_idx_ci_notes),
                                                  flg_time_in              => i_interv(c_idx_ci_flg_time),
                                                  dt_begin_tstz_in         => pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                                                            i_prof      => i_prof,
                                                                                                            i_timestamp => i_interv(c_idx_ci_dt_begin),
                                                                                                            i_timezone  => NULL),
                                                  dt_next_tstz_in          => NULL,
                                                  dt_next_tstz_nin         => FALSE,
                                                  flg_prn_in               => i_interv(c_idx_ci_flg_prn),
                                                  prn_notes_in             => i_interv(c_idx_ci_prn_notes),
                                                  prn_notes_nin            => FALSE,
                                                  dt_last_update_in        => i_sysdate_tstz,
                                                  flg_type_in              => pk_icnp_constant.g_epis_interv_type_no_schedule,
                                                  id_prof_last_update_in   => i_prof.id,
                                                  rows_out                 => l_rows);
                    t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'ICNP_EPIS_INTERVENTION',
                                                  i_rowids     => l_rows,
                                                  o_error      => l_error);
                
                END IF;
            
            ELSE
            
                SELECT iei.flg_type
                  INTO l_flg_type
                  FROM icnp_epis_intervention iei
                 WHERE iei.id_icnp_epis_interv = i_interv(c_idx_ci_compo_interv_id);
            
                -- Gets the intervention row of the id
                l_interv_row_coll := pk_icnp_interv.get_interv_rows(i_interv_ids => table_number(i_interv(c_idx_ci_compo_interv_id)));
            
                -- Creates history records for all the interventions
                pk_icnp_interv.create_interv_hist(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  i_interv_coll  => l_interv_row_coll,
                                                  i_sysdate_tstz => i_sysdate_tstz,
                                                  o_interv_hist  => l_interv_hist);
            
                --Update id_order_recurr_plan 
                l_rows := table_varchar();
                ts_icnp_epis_intervention.upd(id_icnp_epis_interv_in => i_interv(c_idx_ci_compo_interv_id),
                                              notes_in               => i_interv(c_idx_ci_notes),
                                              notes_nin              => FALSE,
                                              flg_time_in            => i_interv(c_idx_ci_flg_time),
                                              dt_begin_tstz_in       => pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                                                      i_prof      => i_prof,
                                                                                                      i_timestamp => i_interv(c_idx_ci_dt_begin),
                                                                                                      i_timezone  => NULL),
                                              flg_prn_in             => i_interv(c_idx_ci_flg_prn),
                                              prn_notes_in           => i_interv(c_idx_ci_prn_notes),
                                              prn_notes_nin          => FALSE,
                                              dt_last_update_in      => i_sysdate_tstz,
                                              flg_type_in            => l_flg_type,
                                              id_prof_last_update_in => i_prof.id,
                                              rows_out               => l_rows);
            
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'ICNP_EPIS_INTERVENTION',
                                              i_rowids     => l_rows,
                                              o_error      => l_error);
            
            END IF;
        END IF;
        o_interv_id := table_number();
    END update_icnp_interv_int;

    --------------------------------------------------------------------------------
    -- PRIVATE METHODS
    --------------------------------------------------------------------------------

    /**
    * Creates intervention alerts.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/08/06
    */
    PROCEDURE create_alerts
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) IS
        -- requested interventions that have no executions
        CURSOR c_alert IS
            SELECT iei.id_icnp_epis_interv id_record,
                   nvl(iei.dt_begin_tstz, iei.dt_icnp_epis_interv_tstz) dt_record,
                   ic.code_icnp_composition replace1
              FROM icnp_epis_intervention iei
              JOIN icnp_composition ic
                ON iei.id_composition = ic.id_composition
             WHERE iei.id_episode = i_episode
               AND iei.id_episode_destination IS NULL
               AND iei.flg_status = pk_icnp_constant.g_epis_interv_status_requested
               AND NOT EXISTS (SELECT 1
                      FROM icnp_interv_plan iip
                     WHERE iip.id_icnp_epis_interv = iei.id_icnp_epis_interv
                       AND iip.flg_status = pk_icnp_constant.g_interv_plan_status_executed);
    
        TYPE t_coll_alert IS TABLE OF c_alert%ROWTYPE;
        l_alerts   t_coll_alert;
        l_replace2 sys_alert_event.replace2%TYPE;
        l_error    t_error_out;
    BEGIN
        -- check alert version
        IF NOT pk_alerts.is_event_version(i_id_sys_alert => pk_icnp_constant.g_icnp_alert)
        THEN
            RETURN;
        END IF;
    
        -- get records to create alerts to
        OPEN c_alert;
        FETCH c_alert BULK COLLECT
            INTO l_alerts;
        CLOSE c_alert;
        -- create alerts
        IF l_alerts IS NOT NULL
           AND l_alerts.count > 0
        THEN
            -- CALL pk_sysconfig.get_config
            l_replace2 := pk_sysconfig.get_config(i_code_cf => 'ALERT_ICNP_INTERV_TIMEOUT', i_prof => i_prof);
        
            -- LOOP CALL pk_alerts.insert_sys_alert_event
            FOR i IN l_alerts.first .. l_alerts.last
            LOOP
                IF NOT pk_alerts.insert_sys_alert_event(i_lang                => i_lang,
                                                        i_prof                => i_prof,
                                                        i_sys_alert           => pk_icnp_constant.g_icnp_alert,
                                                        i_id_episode          => i_episode,
                                                        i_id_record           => l_alerts(i).id_record,
                                                        i_dt_record           => l_alerts(i).dt_record,
                                                        i_id_professional     => i_prof.id,
                                                        i_id_room             => NULL,
                                                        i_id_clinical_service => NULL,
                                                        i_flg_type_dest       => 'C',
                                                        i_replace1            => l_alerts(i).replace1,
                                                        i_replace2            => l_replace2,
                                                        o_error               => l_error)
                THEN
                    pk_icnp_util.raise_unexpected_error('pk_alerts.insert_sys_alert_event', l_error);
                END IF;
            END LOOP;
        END IF;
    END create_alerts;

    /**
    * Filters a list of interventions in order to remove the groupable interventions
    * Interventions grouping diagram:
    *      A,E   I    F    C
    *  A,E  -    2   A,E  A,E
    *  I    2    -    2    I
    *  F   A,E   2    -    2 
    *  C   A,E   I    2    -
    *
    * @param i_interv_list  Interventions list
    *
    * @return               Filtered intervention list
    *
    * @author               Sérgio Santos
    * @version               2.5.1
    * @since                2010/08/02
    */
    FUNCTION filter_grouped_interv(i_interv_list IN t_coll_interv_icnp_ea) RETURN t_coll_interv_icnp_ea IS
        t_result t_coll_interv_icnp_ea := t_coll_interv_icnp_ea();
    
        l_base_interv t_rec_interv_icnp_ea;
    
        l_add_interv BOOLEAN;
    
        -- inserts the intervention if the tuple(id_composition_interv, flg_status) doesn't exist
        FUNCTION insert_if_not_exists
        (
            i_int          t_rec_interv_icnp_ea,
            i_res_int_list t_coll_interv_icnp_ea
        ) RETURN t_coll_interv_icnp_ea IS
            l_exist BOOLEAN := FALSE;
        
            l_result t_coll_interv_icnp_ea := t_coll_interv_icnp_ea();
        BEGIN
            l_result := i_res_int_list;
        
            FOR i IN 1 .. l_result.count
            LOOP
                IF l_result(i).id_composition_interv = i_int.id_composition_interv
                    AND l_result(i).flg_status = i_int.flg_status
                    AND l_result(i).instr_desc = i_int.instr_desc
                THEN
                    l_exist := TRUE;
                    IF l_result(i).id_icnp_epis_interv <> i_int.id_icnp_epis_interv
                    THEN
                        l_result(i).id_icnp_epis_interv_group := l_result(i).id_icnp_epis_interv_group || '|' ||
                                                                  i_int.id_icnp_epis_interv;
                    END IF;
                END IF;
            END LOOP;
        
            IF NOT l_exist
            THEN
                l_result.extend;
                l_result(l_result.count) := i_int;
                l_result(l_result.count).id_icnp_epis_interv_group := to_char(l_result(l_result.count).id_icnp_epis_interv);
            END IF;
        
            RETURN l_result;
        END;
    BEGIN
        FOR i IN 1 .. i_interv_list.count
        LOOP
            l_base_interv := i_interv_list(i);
        
            IF l_base_interv.flg_status IN
               (pk_icnp_constant.g_epis_interv_status_requested,
                pk_icnp_constant.g_epis_interv_status_ongoing,
                pk_icnp_constant.g_epis_interv_status_suspended)
            THEN
                -- interventions with the status 'A', 'E' and 'I' always apear (not repeated)
                t_result := insert_if_not_exists(l_base_interv, t_result);
            ELSE
                l_add_interv := TRUE;
            
                FOR j IN i + 1 .. i_interv_list.count
                LOOP
                    IF l_base_interv.id_composition_interv = i_interv_list(j).id_composition_interv
                    THEN
                        IF l_base_interv.flg_status = pk_icnp_constant.g_epis_interv_status_executed
                           AND i_interv_list(j).flg_status = pk_icnp_constant.g_epis_interv_status_requested
                        THEN
                            l_add_interv := FALSE;
                        END IF;
                    
                        IF l_base_interv.flg_status = pk_icnp_constant.g_epis_interv_status_cancelled
                           AND i_interv_list(j)
                          .flg_status IN (pk_icnp_constant.g_epis_interv_status_requested,
                                          pk_icnp_constant.g_epis_interv_status_suspended)
                        THEN
                            l_add_interv := FALSE;
                        END IF;
                    END IF;
                END LOOP;
            
                IF l_add_interv
                THEN
                    t_result := insert_if_not_exists(l_base_interv, t_result);
                END IF;
            END IF;
        END LOOP;
    
        RETURN t_result;
    END filter_grouped_interv;

    /*
    * Build status string. Internal use only.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_type           status string type
    * @param i_status         status flag
    * @param i_timestamp      status date
    * @param i_shortcut       shortcut identifier
    * @param i_flg_prn        Flag that indicates if the intervention should only be executed as 
    *                         the situation demands.
    * 
    * @return                 status string
    *
    * @author                 Pedro Carneiro
    * @version                 2.5.1
    * @since                  2010/07/30
    */
    FUNCTION get_status_str
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_type        IN VARCHAR2,
        i_status      IN interv_icnp_ea.flg_status%TYPE,
        i_timestamp1  IN interv_icnp_ea.dt_next%TYPE := NULL,
        i_timestamp2  IN interv_icnp_ea.dt_next%TYPE := NULL,
        i_exec_number IN icnp_interv_plan.exec_number%TYPE := NULL,
        i_shortcut    IN sys_shortcut.id_sys_shortcut%TYPE := NULL,
        i_flg_prn     IN interv_icnp_ea.flg_prn%TYPE
    ) RETURN sys_domain.desc_val%TYPE IS
        l_display_type VARCHAR2(2 CHAR);
        l_value_text   sys_domain.code_domain%TYPE;
        l_value_date   sys_domain.code_domain%TYPE;
        l_value_icon   sys_domain.code_domain%TYPE;
        l_back_color   VARCHAR2(8 CHAR) := pk_alert_constant.g_color_null;
        l_icon_color   VARCHAR2(8 CHAR) := pk_alert_constant.g_color_null;
        l_status       interv_icnp_ea.flg_status%TYPE;
    BEGIN
        l_status := i_status;
        IF l_status IS NULL
        THEN
            l_status     := NULL;
            l_value_text := NULL;
            l_value_date := NULL;
            l_value_icon := NULL;
            --i_shortcut:=null;
            l_back_color := NULL;
            l_icon_color := NULL;
        ELSE
            IF i_type = g_type_diag
            THEN
                -- diagnosis
                l_display_type := pk_alert_constant.g_display_type_icon;
                l_value_icon   := pk_icnp_constant.g_domain_epis_diag_status;
                l_icon_color   := pk_alert_constant.g_color_icon_medium_grey;
            ELSIF i_type = g_type_exec
            THEN
                -- executions
                IF l_status IN (pk_icnp_constant.g_interv_plan_status_executed,
                                pk_icnp_constant.g_interv_plan_status_cancelled,
                                pk_icnp_constant.g_interv_plan_status_suspended,
                                pk_icnp_constant.g_interv_plan_status_not_exec)
                THEN
                    l_display_type := pk_alert_constant.g_display_type_icon;
                    l_value_icon   := pk_icnp_constant.g_domain_interv_plan_status;
                    l_icon_color   := pk_alert_constant.g_color_icon_medium_grey;
                ELSIF i_flg_prn = pk_alert_constant.get_yes
                THEN
                    l_display_type := pk_alert_constant.g_display_type_text;
                    l_value_text   := pk_message.get_message(i_lang      => i_lang,
                                                             i_prof      => i_prof,
                                                             i_code_mess => 'CIPE_M007');
                    l_icon_color   := pk_alert_constant.g_color_icon_medium_grey;
                ELSIF l_status IN
                      (pk_icnp_constant.g_interv_plan_status_pending, pk_icnp_constant.g_interv_plan_status_requested)
                THEN
                    l_display_type := pk_alert_constant.g_display_type_date;
                    l_value_date   := pk_date_utils.to_char_insttimezone(i_prof      => i_prof,
                                                                         i_timestamp => i_timestamp2,
                                                                         i_mask      => pk_alert_constant.g_dt_yyyymmddhh24miss_tzr);
                    l_back_color   := pk_alert_constant.g_color_red;
                ELSIF l_status = pk_icnp_constant.g_interv_plan_status_not_exec
                THEN
                    l_display_type := pk_alert_constant.g_display_type_icon;
                    l_value_icon   := pk_icnp_constant.g_domain_interv_plan_status;
                    l_icon_color   := pk_alert_constant.g_color_icon_medium_grey;
                    l_status       := pk_icnp_constant.g_interv_plan_status_cancelled;
                END IF;
            END IF;
        END IF;
        -- generate status string
        RETURN pk_utils.get_status_string_immediate(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_display_type    => l_display_type,
                                                    i_flg_state       => l_status,
                                                    i_value_text      => l_value_text,
                                                    i_value_date      => l_value_date,
                                                    i_value_icon      => l_value_icon,
                                                    i_shortcut        => i_shortcut,
                                                    i_back_color      => l_back_color,
                                                    i_icon_color      => l_icon_color,
                                                    i_message_style   => NULL,
                                                    i_message_color   => NULL,
                                                    i_flg_text_domain => pk_alert_constant.g_no);
    END get_status_str;

    /********************************************************************************************
    * Returns the shortcut id using the its intern_name
    *
    * @param      i_prof                 Object (professional ID, institution ID, software ID)
    * @param      i_intern_name          Shortcut intern_name
    *
    * @return             Shortcut id
    *
    * @author                Sérgio Santos
    * @version               2.5.1
    * @since                 2010/08/02
    *********************************************************************************************/
    FUNCTION get_shortcut_by_intern_name
    (
        i_prof        IN profissional,
        i_intern_name IN sys_shortcut.intern_name%TYPE
    ) RETURN NUMBER IS
        l_result VARCHAR2(4000 CHAR);
    
        CURSOR c_shortcut(i_int_name IN sys_shortcut.intern_name%TYPE) IS
            SELECT ss.id_sys_shortcut
              FROM sys_shortcut ss
             WHERE ss.intern_name = i_int_name
               AND ss.id_software = i_prof.software
               AND ss.id_institution = i_prof.institution
            UNION ALL
            SELECT ss.id_sys_shortcut
              FROM sys_shortcut ss
             WHERE ss.intern_name = i_int_name
               AND ss.id_software = i_prof.software
               AND ss.id_institution = 0;
    BEGIN
        OPEN c_shortcut(i_int_name => i_intern_name);
        FETCH c_shortcut
            INTO l_result;
        CLOSE c_shortcut;
    
        IF l_result IS NULL
        THEN
            l_result := 0;
        END IF;
    
        RETURN l_result;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_shortcut_by_intern_name;

    /**
    * Update a standard care plan associations with specialties
    *
    * @param i_prof         logged professional structure
    * @param i_cplan_stand  standard care plan identifier
    * @param i_dcs          specialties identifiers list
    * @param i_soft         software identifiers list
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/06/29    
    */
    PROCEDURE update_icnp_cplan_dcs
    (
        i_prof        IN profissional,
        i_cplan_stand IN icnp_cplan_stand.id_cplan_stand%TYPE,
        i_dcs         IN table_number,
        i_soft        IN table_number
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'update_icnp_cplan_dcs';
        l_rows PLS_INTEGER;
    BEGIN
        DELETE FROM icnp_cplan_stand_dcs icds
         WHERE icds.id_cplan_stand = i_cplan_stand;
    
        l_rows := SQL%ROWCOUNT;
        log_debug('Deleted ' || l_rows || ' records.', c_func_name);
    
        -- todo this may be slow
        INSERT INTO icnp_cplan_stand_dcs
            (id_cplan_stand, id_software, id_dep_clin_serv)
            SELECT i_cplan_stand id_cplan_stand, sd.id_software, dcs.id_dep_clin_serv
              FROM dep_clin_serv dcs
              JOIN department s
                ON dcs.id_department = s.id_department
              JOIN software_dept sd
                ON s.id_dept = sd.id_dept
             WHERE dcs.id_dep_clin_serv IN (SELECT t.column_value id_software
                                              FROM TABLE(i_dcs) t)
               AND s.id_institution = i_prof.institution
               AND s.flg_available = pk_alert_constant.g_yes
               AND sd.id_software IN (SELECT t.column_value id_software
                                        FROM TABLE(i_soft) t);
        l_rows := SQL%ROWCOUNT;
        log_debug('Created ' || l_rows || ' records.', c_func_name);
    
    END update_icnp_cplan_dcs;

    /**
    * Given an ordered list of numbers, it returns
    * a list with the repeated numbers in that list.
    *
    * @param i_tbl_num      ordered list of numbers
    *
    * @return               list of repeated numbers
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/07/13
    */
    FUNCTION get_dups(i_tbl_num IN table_number) RETURN table_number IS
        l_dups     table_number := table_number();
        l_last_num NUMBER;
    BEGIN
        IF i_tbl_num IS NOT NULL
        THEN
            FOR i IN i_tbl_num.first .. i_tbl_num.last
            LOOP
                IF i = 1
                THEN
                    l_last_num := i_tbl_num(i);
                ELSE
                    IF l_last_num = i_tbl_num(i)
                    THEN
                        -- last number repeats
                        IF pk_utils.search_table_number(i_table => l_dups, i_search => l_last_num) < 0
                        THEN
                            l_dups.extend;
                            l_dups(l_dups.last) := l_last_num;
                        END IF;
                    ELSE
                        -- last number changes
                        l_last_num := i_tbl_num(i);
                    END IF;
                END IF;
            END LOOP;
        END IF;
    
        RETURN l_dups;
    END get_dups;

    /**
     * Gets the human readable text of the instructions of a given intervention request.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_flg_time Flag that indicates in which episode the task should be performed.
     * @param i_dt_begin_tstz Date that indicates when the task should be performed.
     * @param i_order_recurr_plan Identifier of the recurrence plan.
     * @param i_mask Mask that defines the order and which information appears.
     *               If not specified a default mask is used (pk_icnp_constant.g_inst_format_mask_default).
     *               If you want to use a non default mask please use 
     *               pk_icnp_constant.g_inst_format_opt_* constants.
     *
     * @return The human readable text of the instructions of a given intervention request.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 27/Jun/2011
    */
    FUNCTION get_instructions
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_flg_type          IN icnp_epis_intervention.flg_type%TYPE,
        i_flg_time          IN icnp_epis_intervention.flg_time%TYPE,
        i_dt_begin_tstz     IN icnp_epis_intervention.dt_begin_tstz%TYPE,
        i_order_recurr_plan IN icnp_epis_intervention.id_order_recurr_plan%TYPE,
        i_mask              IN pk_icnp_type.t_instruction_mask DEFAULT pk_icnp_constant.g_inst_format_mask_default
    ) RETURN pk_icnp_type.t_instruction_desc IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'get_instructions';
    
        -- Text that is going to be returned
        l_instruction_desc pk_icnp_type.t_instruction_desc;
    
        -- Appends a string to a given text
        -- :FIXME: Move this function to an utility package
        FUNCTION append
        (
            i_original IN pk_icnp_type.t_instruction_desc,
            i_add      IN pk_icnp_type.t_instruction_desc
        ) RETURN pk_icnp_type.t_instruction_desc IS
            l_instruction_desc pk_icnp_type.t_instruction_desc;
        BEGIN
            IF i_original IS NULL
            THEN
                l_instruction_desc := i_add;
            ELSE
                l_instruction_desc := i_original || pk_icnp_constant.g_word_sep || i_add;
            END IF;
        
            RETURN l_instruction_desc;
        END append;
    
        -- Gets the text that describes in which episode the task should be performed
        FUNCTION get_perform_desc RETURN pk_icnp_type.t_instruction_desc IS
            l_perform_desc pk_icnp_type.t_instruction_desc := '';
        BEGIN
            l_perform_desc := get_message_and_cache(i_lang, i_prof, pk_icnp_constant.mcodet_to_be_exec, l_messages_col) ||
                              pk_icnp_constant.g_word_space;
            IF i_flg_time IS NOT NULL
            THEN
                l_perform_desc := l_perform_desc || pk_sysdomain.get_domain(pk_icnp_constant.g_domain_epis_interv_time,
                                                                            i_flg_time,
                                                                            i_lang);
            ELSE
                l_perform_desc := l_perform_desc || pk_icnp_constant.g_word_no_record;
            END IF;
            RETURN l_perform_desc;
        END get_perform_desc;
    
        -- Gets the text with the frequency of the executions
        FUNCTION get_frequency_desc RETURN pk_icnp_type.t_instruction_desc IS
            l_frequency_desc pk_icnp_type.t_instruction_desc := '';
            l_message        sys_message.desc_message%TYPE;
        BEGIN
            l_message := get_message_and_cache(i_lang, i_prof, pk_icnp_constant.mcodet_frequency, l_messages_col);
            IF i_flg_type = pk_icnp_constant.g_epis_interv_type_once
            THEN
                l_frequency_desc := l_message || pk_icnp_constant.g_word_space ||
                                    pk_translation.get_translation(i_lang,
                                                                   'ORDER_RECURR_OPTION.CODE_ORDER_RECURR_OPTION.0');
            ELSIF i_flg_type = pk_icnp_constant.g_epis_interv_type_no_schedule
            THEN
                l_frequency_desc := l_message || pk_icnp_constant.g_word_space ||
                                    pk_translation.get_translation(i_lang,
                                                                   'ORDER_RECURR_OPTION.CODE_ORDER_RECURR_OPTION.-2');
            ELSIF i_flg_type = pk_icnp_constant.g_epis_interv_type_recurrence
            THEN
                l_frequency_desc := l_message || pk_icnp_constant.g_word_space ||
                                    pk_order_recurrence_api_db.get_order_recurr_plan_desc(i_lang              => i_lang,
                                                                                          i_prof              => i_prof,
                                                                                          i_order_recurr_plan => i_order_recurr_plan);
            END IF;
        
            RETURN l_frequency_desc;
        END get_frequency_desc;
    
        -- Gets the text that describes when the task should be performed
        FUNCTION get_start_date_desc RETURN pk_icnp_type.t_instruction_desc IS
            l_dt_begin_desc pk_icnp_type.t_instruction_desc := '';
        BEGIN
            l_dt_begin_desc := get_message_and_cache(i_lang, i_prof, pk_icnp_constant.mcodet_start_date, l_messages_col) ||
                               pk_icnp_constant.g_word_space;
        
            IF i_dt_begin_tstz IS NOT NULL
            THEN
                l_dt_begin_desc := l_dt_begin_desc || pk_date_utils.date_char_tsz(i_lang,
                                                                                  i_dt_begin_tstz,
                                                                                  i_prof.institution,
                                                                                  i_prof.software);
            ELSE
                l_dt_begin_desc := l_dt_begin_desc || pk_icnp_constant.g_word_no_record;
            END IF;
            RETURN l_dt_begin_desc;
        END get_start_date_desc;
    
    BEGIN
        log_debug(c_func_name || '(i_lang:' || i_lang || ', i_prof:' || pk_utils.to_string(i_prof) || ', i_flg_time:' ||
                  i_flg_time || ', i_dt_begin_tstz:' || i_dt_begin_tstz || ', i_order_recurr_plan:' ||
                  i_order_recurr_plan || ', i_mask:' || i_mask || ')',
                  c_func_name);
    
        -- Loop through the mask options and add them to the instructions string
        FOR i IN 1 .. length(i_mask)
        LOOP
            CASE substr(i_mask, i, 1)
                WHEN pk_icnp_constant.g_inst_format_opt_perform THEN
                    l_instruction_desc := append(l_instruction_desc, get_perform_desc());
                WHEN pk_icnp_constant.g_inst_format_opt_start_date THEN
                    l_instruction_desc := append(l_instruction_desc, get_start_date_desc());
                WHEN pk_icnp_constant.g_inst_format_opt_frequency THEN
                    l_instruction_desc := append(l_instruction_desc, get_frequency_desc());
                ELSE
                    NULL;
            END CASE;
        END LOOP;
    
        RETURN l_instruction_desc;
    END get_instructions;

    /**
    * Get list of available actions, from a given state. When specifying more than one state,
    * it groups the actions, according to their availability. This enables support
    * for "bulk" state changes.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_subject      action subject
    * @param i_from_state   list of selected states
    *
    * @return               action records collection
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/08/03
    */
    FUNCTION get_actions_perm_int
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_subject    IN action.subject%TYPE,
        i_from_state IN table_varchar,
        i_flg_time   IN icnp_epis_intervention.flg_time%TYPE
    ) RETURN t_coll_action_cipe IS
        l_actions   t_coll_action_cipe;
        l_profile   action_permission.id_profile_template%TYPE;
        l_category  action_permission.id_category%TYPE;
        l_states    table_varchar := table_varchar();
        l_rec_count PLS_INTEGER;
    BEGIN
        -- CALL pk_tools.get_prof_profile_template
        l_profile := pk_tools.get_prof_profile_template(i_prof => i_prof);
        -- CALL pk_prof_utils.get_id_category
        l_category := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
    
        IF i_from_state IS NOT NULL
           AND i_from_state.count > 0
        THEN
            l_states := i_from_state;
        END IF;
    
        l_rec_count := l_states.count;
    
        -- SELECT l_actions
        SELECT t_rec_action_cipe(MIN(a.id_action),
                                  a.desc_action,
                                  i_subject,
                                  a.to_state,
                                  a.icon,
                                  CASE
                                      WHEN l_rec_count > 1
                                           AND i_subject = pk_icnp_constant.g_action_subject_diag
                                           AND a.internal_name = pk_icnp_constant.g_action_diag_reeval THEN
                                       pk_alert_constant.g_inactive
                                      WHEN l_rec_count >= 1
                                           AND i_subject = pk_icnp_constant.g_action_subject_diag
                                           AND (a.internal_name = pk_icnp_constant.g_action_diag_pause OR
                                           a.internal_name = pk_icnp_constant.g_action_diag_resume) THEN
                                       pk_alert_constant.g_inactive
                                      WHEN l_rec_count > 1
                                           AND i_subject = pk_icnp_constant.g_action_subject_interv
                                           AND a.internal_name IN ( --pk_icnp_constant.g_action_interv_exec,
                                                                   pk_icnp_constant.g_action_interv_edit,
                                                                   pk_icnp_constant.g_action_interv_canc_exec) THEN
                                       pk_alert_constant.g_inactive
                                      WHEN i_flg_time = pk_icnp_constant.g_epis_interv_time_next_epis
                                           AND a.internal_name = pk_icnp_constant.g_action_interv_exec THEN
                                       pk_alert_constant.g_inactive
                                      WHEN i_flg_time = pk_icnp_constant.g_epis_interv_time_next_epis
                                           AND a.internal_name = pk_icnp_constant.g_action_interv_resolve THEN
                                       pk_alert_constant.g_inactive
                                      ELSE
                                       decode(instr(concatenate(a.flg_status), pk_alert_constant.g_inactive),
                                              0,
                                              pk_alert_constant.g_active,
                                              pk_alert_constant.g_inactive)
                                  END,
                                  a.rank,
                                  a.flg_default,
                                  a.id_parent,
                                  a.internal_name,
                                  a.action_level)
          BULK COLLECT
          INTO l_actions
          FROM (SELECT a.id_action,
                       a.id_parent,
                       LEVEL action_level,
                       a.from_state,
                       a.to_state,
                       pk_message.get_message(i_lang, i_prof, code_action) desc_action,
                       a.icon,
                       decode(a.flg_default, 'D', pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_default,
                       a.flg_status,
                       a.rank,
                       a.internal_name,
                       a.subject
                  FROM (SELECT a.id_action,
                               a.code_action,
                               a.subject,
                               a.from_state,
                               a.to_state,
                               a.icon,
                               a.flg_status,
                               a.rank,
                               a.flg_default,
                               a.id_parent,
                               a.internal_name
                          FROM action a
                         WHERE a.subject = i_subject) a
                 WHERE (a.from_state IS NULL OR
                       a.from_state IN ((SELECT /*+opt_estimate(table t rows=1)*/
                                          t.column_value from_state
                                           FROM TABLE(l_states) t)))
                   AND EXISTS (SELECT 1
                          FROM action_permission ap
                         WHERE ap.id_action = a.id_action
                           AND ap.id_category = l_category
                           AND ap.id_profile_template IN (0, l_profile)
                           AND ap.id_institution IN (0, i_prof.institution)
                           AND ap.id_software IN (0, i_prof.software)
                           AND ap.flg_available = pk_alert_constant.g_yes)
                CONNECT BY PRIOR a.id_action = a.id_parent) a
         GROUP BY a.id_parent,
                  a.action_level,
                  a.to_state,
                  a.desc_action,
                  a.icon,
                  a.flg_default,
                  a.internal_name,
                  a.rank;
    
        RETURN l_actions;
    END get_actions_perm_int;

    ------------------------------------
    FUNCTION get_actions_perm_int
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_subject    IN action.subject%TYPE,
        i_from_state IN table_varchar
    ) RETURN t_coll_action_cipe IS
    
    BEGIN
        RETURN get_actions_perm_int(i_lang       => i_lang,
                                    i_prof       => i_prof,
                                    i_subject    => i_subject,
                                    i_from_state => i_from_state,
                                    i_flg_time   => NULL);
    END get_actions_perm_int;

    /**
    * Get intervention instructions description.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_interv       intervention identifier
    *
    * @return               intervention instructions description
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/07/06
    */
    FUNCTION get_interv_instructions
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_interv IN icnp_epis_intervention.id_icnp_epis_interv%TYPE
    ) RETURN pk_icnp_type.t_instruction_desc IS
        CURSOR c_interv IS
            SELECT iei.flg_type, iei.flg_time, iei.dt_begin_tstz, iei.id_order_recurr_plan
              FROM icnp_epis_intervention iei
             WHERE iei.id_icnp_epis_interv = i_interv;
    
        l_found            BOOLEAN;
        r_interv           c_interv%ROWTYPE;
        l_instruction_desc pk_icnp_type.t_instruction_desc;
    BEGIN
        -- OPEN c_interv
        OPEN c_interv;
        FETCH c_interv
            INTO r_interv;
        l_found := c_interv%FOUND;
        CLOSE c_interv;
    
        IF l_found
        THEN
            -- CALL get_instructions
            l_instruction_desc := get_instructions(i_lang              => i_lang,
                                                   i_prof              => i_prof,
                                                   i_flg_type          => r_interv.flg_type,
                                                   i_flg_time          => r_interv.flg_time,
                                                   i_dt_begin_tstz     => r_interv.dt_begin_tstz,
                                                   i_order_recurr_plan => r_interv.id_order_recurr_plan);
        ELSE
            l_instruction_desc := NULL;
        END IF;
    
        RETURN l_instruction_desc;
    END get_interv_instructions;

    /**
    * Get intervention instructions description based on an history record.
    *
    * @param i_lang                 language identifier
    * @param i_prof                 logged professional structure
    * @param i_interv_hist          intervention history identifier
    *
    * @return               intervention instructions description
    *
    * @author               Sérgio Santos
    * @version               2.5.1
    * @since                2010/09/02
    */
    FUNCTION get_interv_hist_instructions
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_interv_hist IN icnp_epis_intervention_hist.id_icnp_epis_interv_hist%TYPE
    ) RETURN pk_icnp_type.t_instruction_desc IS
        CURSOR c_interv IS
            SELECT ieih.flg_type, ieih.flg_time, ieih.dt_begin_tstz, ieih.id_order_recurr_plan
              FROM icnp_epis_intervention_hist ieih
             WHERE ieih.id_icnp_epis_interv_hist = i_interv_hist;
    
        l_found            BOOLEAN;
        r_interv           c_interv%ROWTYPE;
        l_instruction_desc pk_icnp_type.t_instruction_desc;
    BEGIN
        -- OPEN c_interv
        OPEN c_interv;
        FETCH c_interv
            INTO r_interv;
        l_found := c_interv%FOUND;
        CLOSE c_interv;
    
        IF l_found
        THEN
            -- CALL get_instructions
            l_instruction_desc := get_instructions(i_lang              => i_lang,
                                                   i_prof              => i_prof,
                                                   i_flg_type          => r_interv.flg_type,
                                                   i_flg_time          => r_interv.flg_time,
                                                   i_dt_begin_tstz     => r_interv.dt_begin_tstz,
                                                   i_order_recurr_plan => r_interv.id_order_recurr_plan);
        ELSE
            l_instruction_desc := NULL;
        END IF;
    
        RETURN l_instruction_desc;
    END get_interv_hist_instructions;

    /**
    * Get intervention instructions description
    * (for Backoffice use only).
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_interv       intervention identifier
    * @param i_dt_begin     intervention start date
    *
    * @return               intervention instructions description
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/07/06
    */
    FUNCTION get_interv_instructions_bo
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_interv   IN icnp_cplan_stand_compo.id_cplan_stand_compo%TYPE,
        i_dt_begin IN interv_icnp_ea.dt_begin%TYPE := NULL
    ) RETURN pk_icnp_type.t_instruction_desc IS
        CURSOR c_compo IS
            SELECT icsc.flg_type, icsc.flg_time, icsc.id_order_recurr_plan
              FROM icnp_cplan_stand_compo icsc
             WHERE icsc.id_cplan_stand_compo = i_interv;
    
        l_found            BOOLEAN;
        r_compo            c_compo%ROWTYPE;
        l_instruction_desc pk_icnp_type.t_instruction_desc;
        l_instruction_mask pk_icnp_type.t_instruction_mask;
    BEGIN
        -- OPEN c_compo
        OPEN c_compo;
        FETCH c_compo
            INTO r_compo;
        l_found := c_compo%FOUND;
        CLOSE c_compo;
    
        IF l_found
        THEN
            -- Determines which information should be displayed in the instructions desc
            IF i_dt_begin IS NOT NULL
            THEN
                l_instruction_mask := pk_icnp_constant.g_inst_format_mask_default;
            ELSE
                l_instruction_mask := pk_icnp_constant.g_inst_format_opt_perform ||
                                      pk_icnp_constant.g_inst_format_opt_frequency;
            END IF;
        
            -- CALL get_instructions
            l_instruction_desc := get_instructions(i_lang              => i_lang,
                                                   i_prof              => i_prof,
                                                   i_flg_type          => r_compo.flg_type,
                                                   i_flg_time          => r_compo.flg_time,
                                                   i_dt_begin_tstz     => i_dt_begin,
                                                   i_order_recurr_plan => r_compo.id_order_recurr_plan,
                                                   i_mask              => l_instruction_mask);
        ELSE
            l_instruction_desc := NULL;
        END IF;
    
        RETURN l_instruction_desc;
    END get_interv_instructions_bo;

    /********************************************************************************************
    * Get ICNP care plan list (Configurations Area)
    *
    * @param      i_lang      Preferred language ID for this professional
    * @param      i_prof      Object (professional ID, institution ID, software ID)
    * @param      o_cplan     Cursor List of available Nursing Care Plans
    * @param      o_error     Error
    *
    * @return                 boolean type, "False" on error or "True" if success 
    * 
    * @author                  Sérgio Santos
    * @version                 2.5.1 
    * @since                   2010/05/05
    *                         
    *********************************************************************************************/
    PROCEDURE get_icnp_cplan_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_cplan OUT pk_types.cursor_type
    ) IS
        l_code_cs CONSTANT translation.code_translation%TYPE := 'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.';
    BEGIN
        -- OPEN O_CPLAN
        OPEN o_cplan FOR
            SELECT ics.id_cplan_stand,
                   ics.name,
                   ics.flg_status,
                   pk_sysdomain.get_domain('ICNP_CPLAN_STAND.FLG_STATUS', ics.flg_status, i_lang) desc_flg_status,
                   pk_sysdomain.get_rank(i_lang, 'ICNP_CPLAN_STAND.FLG_STATUS', ics.flg_status) rank,
                   (SELECT substr(concatenate_clob(desc_dep_clin_serv),
                                  1,
                                  length(concatenate_clob(desc_dep_clin_serv)) - length(pk_icnp_constant.g_word_sep))
                      FROM (SELECT icsd.id_cplan_stand,
                                   pk_translation.get_translation(i_lang, l_code_cs || dcs.id_clinical_service) ||
                                   pk_icnp_constant.g_word_sep desc_dep_clin_serv
                              FROM icnp_cplan_stand_dcs icsd
                              JOIN dep_clin_serv dcs
                                ON icsd.id_dep_clin_serv = dcs.id_dep_clin_serv
                             ORDER BY desc_dep_clin_serv) icsd
                     WHERE icsd.id_cplan_stand = ics.id_cplan_stand) desc_dep_clin_serv
              FROM icnp_cplan_stand ics
             WHERE ics.id_institution IN (0, i_prof.institution)
             ORDER BY rank, ics.name;
    
    END get_icnp_cplan_list;

    /**
    * Get time icnp terms that belongs to the axis "action" that already have some composition associated
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      Patient identifier
    * @param o_terms        The icnp terms that belongs to the axis "action"
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Sérgio Santos
    * @version              2.5.1
    * @since                2010/07/22
    */
    PROCEDURE get_action_terms
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient patient.id_patient%TYPE,
        o_actions OUT pk_types.cursor_type
    ) IS
        l_show_old_cipe sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf => 'USE_OLD_CIPE_TERMS',
                                                                         i_prof    => i_prof);
    BEGIN
        -- GET_ACTIONS
        OPEN o_actions FOR
            SELECT -1 id_term, pk_message.get_message(i_lang, i_prof, 'CPLAN_T113') desc_term, 1 rank
              FROM dual
             WHERE l_show_old_cipe = pk_alert_constant.g_yes
               AND i_patient IS NOT NULL
            UNION ALL
            SELECT it.id_term, pk_translation.get_translation(i_lang, it.code_term) desc_term, 2 rank
              FROM icnp_term it
              JOIN icnp_axis ia
                ON ia.id_axis = it.id_axis
             WHERE ia.flg_axis = pk_icnp.get_icnp_validation_flag(i_lang, i_prof, pk_icnp_constant.g_icnp_action)
               AND EXISTS (SELECT 1
                      FROM icnp_composition_term ict
                      JOIN icnp_composition ic
                        ON ic.id_composition = ict.id_composition
                     WHERE ict.id_term = it.id_term)
             ORDER BY rank, desc_term;
    
    END get_action_terms;

    /**
    * Gets a list of interventions that belongs to a specific icnp term in the axis "action"
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_term         icnp term identifier
    * @param i_patient      Patient identifier (optional)
    * @param o_intervs      list of interventions
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Sérgio Santos
    * @version               2.5.1
    * @since                2010/07/22
    */
    PROCEDURE get_interv_by_action_term
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_term IN icnp_term.id_term%TYPE,
        i_patient IN patient.id_patient%TYPE,
        o_intervs OUT pk_types.cursor_type
    ) IS
        l_gender patient.gender%TYPE;
    BEGIN
    
        -- get gender
        BEGIN
            SELECT gender
              INTO l_gender
              FROM patient
             WHERE id_patient = i_patient;
        EXCEPTION
            WHEN no_data_found THEN
                l_gender := NULL;
        END;
    
        IF i_id_term = -1
        THEN
            -- OPEN o_intervs (no term)
            OPEN o_intervs FOR
                SELECT *
                  FROM (SELECT id_composition,
                               id_composition id_composition_hist,
                               pk_translation.get_translation(i_lang, code_icnp_composition) desc_interv
                          FROM (SELECT DISTINCT ic.id_composition, ic.flg_repeat, ic.flg_solved, ic.code_icnp_composition
                                  FROM icnp_composition ic
                                  JOIN icnp_compo_dcs icd
                                    ON icd.id_composition = ic.id_composition
                                 WHERE rownum > 0
                                   AND ic.id_institution = i_prof.institution
                                   AND ic.flg_available = pk_alert_constant.g_yes
                                   AND ((i_patient IS NOT NULL AND
                                       ic.flg_gender IN (l_gender, pk_icnp_constant.g_composition_gender_both)) OR
                                       i_patient IS NULL)
                                   AND ic.flg_nurse_tea = nvl(NULL, ic.flg_nurse_tea)
                                   AND ic.flg_type = nvl('A', ic.flg_type)
                                   AND icd.id_dep_clin_serv IN
                                       (SELECT dcs.id_dep_clin_serv
                                          FROM dep_clin_serv dcs
                                          JOIN department d
                                            ON d.id_department = dcs.id_department
                                          JOIN dept dp
                                            ON dp.id_dept = d.id_dept
                                          JOIN software_dept sd
                                            ON sd.id_dept = dp.id_dept
                                         WHERE d.id_institution = i_prof.institution
                                           AND sd.id_software = i_prof.software)))
                 WHERE desc_interv IS NOT NULL
                 ORDER BY desc_interv;
        
        ELSE
            OPEN o_intervs FOR
                SELECT *
                  FROM (SELECT ich.id_composition,
                               ich.id_composition_hist,
                               pk_translation.get_translation(i_lang, ic.code_icnp_composition) desc_interv
                          FROM icnp_composition ic
                          JOIN icnp_composition_hist ich
                            ON ich.id_composition = ic.id_composition
                          JOIN icnp_composition_term ict
                            ON ict.id_composition = ic.id_composition
                          JOIN icnp_term it
                            ON it.id_term = ict.id_term
                          JOIN icnp_axis ia
                            ON ia.id_axis = it.id_axis
                         WHERE ich.flg_most_recent = pk_alert_constant.g_yes
                           AND ic.id_institution = i_prof.institution
                           AND ic.id_software = i_prof.software
                           AND ic.flg_type = pk_icnp_constant.g_composition_type_action
                           AND ia.flg_axis =
                               pk_icnp.get_icnp_validation_flag(i_lang, i_prof, pk_icnp_constant.g_icnp_action)
                           AND it.id_term = i_id_term
                           AND ich.flg_cancel <> pk_alert_constant.g_yes
                           AND ic.flg_available = pk_alert_constant.g_yes)
                 WHERE desc_interv IS NOT NULL
                 ORDER BY desc_interv;
        
        END IF;
    
    END get_interv_by_action_term;

    /**
    * Get available ICNP care plans list.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param o_cplan        icnp care plans cursor
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/07/07
    */
    PROCEDURE get_cplan_fo
    (
        i_prof  IN profissional,
        o_cplan OUT pk_types.cursor_type
    ) IS
    BEGIN
        -- OPEN o_cplan
        OPEN o_cplan FOR
            SELECT ics.id_cplan_stand id, ics.name
              FROM icnp_cplan_stand ics
             WHERE EXISTS (SELECT 1
                      FROM icnp_cplan_stand_dcs icsd
                      JOIN prof_dep_clin_serv pdcs
                        ON icsd.id_dep_clin_serv = pdcs.id_dep_clin_serv
                     WHERE icsd.id_cplan_stand = ics.id_cplan_stand
                       AND ics.id_institution IN (0, i_prof.institution)
                       AND ics.flg_status = pk_icnp_constant.g_icnp_cplan_status_active
                       AND icsd.id_software = i_prof.software
                       AND pdcs.id_professional = i_prof.id
                       AND pdcs.id_institution = i_prof.institution
                       AND pdcs.flg_status = pk_alert_constant.g_status_selected)
             ORDER BY ics.name;
    
    END get_cplan_fo;

    /**
    * Checks selected ICNP care plans for conflicts.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_cplan        icnp care plans identifiers list
    * @param o_exp_res      conflicted expected results cursor
    * @param o_interv       conflicted interventions cursor
    * @param o_sel_compo    unconflicted compositions list
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/07/13
    */
    PROCEDURE check_conflict
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_cplan     IN table_number,
        o_exp_res   OUT pk_types.cursor_type,
        o_interv    OUT pk_types.cursor_type,
        o_sel_compo OUT table_number
    ) IS
        CURSOR c_itv_instr IS
            SELECT MIN(itv.id_cplan_stand_compo) id_cplan_stand_compo, itv.id_composition, itv.desc_instr
              FROM (SELECT /*+opt_estimate(table t rows=1)*/
                     icsc.id_cplan_stand_compo,
                     icsc.id_composition,
                     get_interv_instructions_bo(i_lang, i_prof, icsc.id_cplan_stand_compo, NULL) desc_instr
                      FROM icnp_cplan_stand_compo icsc
                      JOIN (SELECT column_value id_cplan_stand
                             FROM TABLE(i_cplan)) t
                        ON icsc.id_cplan_stand = t.id_cplan_stand
                     WHERE icsc.flg_compo_type = pk_icnp_constant.g_cp_st_compo_type_interv
                       AND icsc.flg_status = pk_icnp_constant.g_cp_st_compo_status_active) itv
             GROUP BY itv.id_composition, itv.desc_instr
             ORDER BY itv.id_composition;
    
        CURSOR c_dx_exp_res IS
            SELECT /*+opt_estimate(table t rows=1)*/
             MIN(icsc.id_cplan_stand_compo) id_cplan_stand_compo, icsc.id_composition_parent, icsc.id_composition
              FROM icnp_cplan_stand_compo icsc
              JOIN (SELECT column_value id_cplan_stand
                      FROM TABLE(i_cplan)) t
                ON icsc.id_cplan_stand = t.id_cplan_stand
             WHERE icsc.flg_compo_type = pk_icnp_constant.g_cp_st_compo_type_res
               AND icsc.flg_status = pk_icnp_constant.g_cp_st_compo_status_active
             GROUP BY icsc.id_composition_parent, icsc.id_composition
             ORDER BY icsc.id_composition_parent;
    
        l_itv_compo_ids table_number := table_number();
        l_intervs       table_number := table_number();
        l_instrs        table_varchar := table_varchar();
        l_cfl_intervs   table_number := table_number();
        l_dx_compo_ids  table_number := table_number();
        l_dxs           table_number := table_number();
        l_exp_res       table_number := table_number();
        l_cfl_dxs       table_number := table_number();
        l_plan          sys_message.desc_message%TYPE;
    BEGIN
        IF i_cplan IS NULL
           OR i_cplan.count < 2
        THEN
            -- when only one plan is specified, or no plans are specified,
            -- there are no conflicts
            pk_types.open_my_cursor(o_exp_res);
            pk_types.open_my_cursor(o_interv);
        ELSE
            l_plan := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'CPLAN_T048') ||
                      pk_icnp_constant.g_word_space;
        
            -- retrieve distinct intervention-instructions pairs
            -- applicable in the selected plans
            OPEN c_itv_instr;
            FETCH c_itv_instr BULK COLLECT
                INTO l_itv_compo_ids, l_intervs, l_instrs;
            CLOSE c_itv_instr;
        
            IF l_itv_compo_ids IS NOT NULL
               AND l_itv_compo_ids.count > 0
            THEN
                -- for all distinct intervention-instructions pairs
                -- fill collection of the interventions that conflict
                l_cfl_intervs := get_dups(i_tbl_num => l_intervs);
            
                -- OPEN o_interv
                OPEN o_interv FOR
                    SELECT icsc.id_cplan_stand_compo,
                           icsc.id_composition id_interv,
                           pk_icnp.desc_composition(i_lang, icsc.id_composition) desc_interv,
                           t.desc_instr || (SELECT pk_icnp_constant.g_word_space || pk_icnp_constant.g_word_open_brac ||
                                                   l_plan || ics.name || pk_icnp_constant.g_word_close_brac
                                              FROM icnp_cplan_stand ics
                                             WHERE ics.id_cplan_stand = icsc.id_cplan_stand) desc_instr
                      FROM icnp_cplan_stand_compo icsc
                      JOIN (SELECT cp.id_cplan_stand_compo, ins.desc_instr
                              FROM (SELECT /*+opt_estimate(table t rows=1)*/
                                     column_value id_cplan_stand_compo, rownum rn
                                      FROM TABLE(l_itv_compo_ids) t) cp
                              JOIN (SELECT column_value id_composition, rownum rn
                                     FROM TABLE(l_intervs)) itv
                                ON cp.rn = itv.rn
                              JOIN (SELECT column_value desc_instr, rownum rn
                                     FROM TABLE(l_instrs)) ins
                                ON cp.rn = ins.rn
                              JOIN (SELECT column_value id_composition
                                     FROM TABLE(l_cfl_intervs)) cfl
                                ON itv.id_composition = cfl.id_composition) t
                        ON icsc.id_cplan_stand_compo = t.id_cplan_stand_compo;
            ELSE
                pk_types.open_my_cursor(o_interv);
            END IF;
        
            -- retrieve distinct diagnosis-expected results pairs
            -- applicable in the selected plans
            OPEN c_dx_exp_res;
            FETCH c_dx_exp_res BULK COLLECT
                INTO l_dx_compo_ids, l_dxs, l_exp_res;
            CLOSE c_dx_exp_res;
        
            IF l_dx_compo_ids IS NOT NULL
               AND l_dx_compo_ids.count > 0
            THEN
                -- for all distinct intervention-instructions pairs
                -- fill collection of the interventions that conflict
                l_cfl_dxs := get_dups(i_tbl_num => l_dxs);
            
                -- OPEN o_exp_res
                OPEN o_exp_res FOR
                    SELECT icsc.id_cplan_stand_compo,
                           icsc.id_composition_parent id_diagnosis,
                           pk_icnp.desc_composition(i_lang, icsc.id_composition_parent) desc_diagnosis,
                           pk_icnp.desc_composition(i_lang, icsc.id_composition) ||
                           (SELECT pk_icnp_constant.g_word_space || pk_icnp_constant.g_word_open_brac || l_plan ||
                                   ics.name || pk_icnp_constant.g_word_close_brac
                              FROM icnp_cplan_stand ics
                             WHERE ics.id_cplan_stand = icsc.id_cplan_stand) desc_exp_result
                      FROM icnp_cplan_stand_compo icsc
                      JOIN (SELECT cp.id_cplan_stand_compo
                              FROM (SELECT /*+opt_estimate(table t rows=1)*/
                                     column_value id_cplan_stand_compo, rownum rn
                                      FROM TABLE(l_dx_compo_ids) t) cp
                              JOIN (SELECT column_value id_composition_parent, rownum rn
                                     FROM TABLE(l_dxs)) dx
                                ON cp.rn = dx.rn
                              JOIN (SELECT column_value id_composition_parent
                                     FROM TABLE(l_cfl_dxs)) cfl
                                ON dx.id_composition_parent = cfl.id_composition_parent) t
                        ON icsc.id_cplan_stand_compo = t.id_cplan_stand_compo;
            ELSE
                pk_types.open_my_cursor(o_exp_res);
            END IF;
        END IF;
    
        -- SELECT o_sel_compo
        SELECT icsc.id_cplan_stand_compo
          BULK COLLECT
          INTO o_sel_compo
          FROM (SELECT MIN(icsc.id_cplan_stand_compo) id_cplan_stand_compo
                  FROM icnp_cplan_stand_compo icsc
                  JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                        column_value id_cplan_stand
                         FROM TABLE(i_cplan) t) cp
                    ON icsc.id_cplan_stand = cp.id_cplan_stand
                 WHERE icsc.flg_compo_type = pk_icnp_constant.g_cp_st_compo_type_interv
                   AND icsc.flg_status = pk_icnp_constant.g_cp_st_compo_status_active
                   AND icsc.id_composition NOT IN (SELECT t.column_value id_composition
                                                     FROM TABLE(l_cfl_intervs) t)
                 GROUP BY icsc.id_composition,
                          icsc.id_composition_parent,
                          get_interv_instructions_bo(i_lang, i_prof, icsc.id_cplan_stand_compo, NULL)
                UNION ALL
                SELECT MIN(icsc.id_cplan_stand_compo) id_cplan_stand_compo
                  FROM icnp_cplan_stand_compo icsc
                  JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                        column_value id_cplan_stand
                         FROM TABLE(i_cplan) t) cp
                    ON icsc.id_cplan_stand = cp.id_cplan_stand
                 WHERE icsc.flg_compo_type = pk_icnp_constant.g_cp_st_compo_type_res
                   AND icsc.flg_status = pk_icnp_constant.g_cp_st_compo_status_active
                   AND icsc.id_composition_parent NOT IN (SELECT t.column_value id_composition_parent
                                                            FROM TABLE(l_cfl_dxs) t)
                 GROUP BY icsc.id_composition_parent, icsc.id_composition) icsc;
    
    END check_conflict;

    /*
    * Returns the possible status.
    * TODO: pass actions as parameter, to avoid multiple collects
    *
    * @param     i_lang   
    * @param     i_prof   
    * @param     i_subject
    * @param     i_status 
    * @param     i_check        
    *
    * @return    TABLE_VARCHAR
    *
    * @author    Paulo Teixeira
    * @version   2.5.1
    * @since     2010/07/26
    */

    FUNCTION check_permissions
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_subject IN action.subject%TYPE,
        i_status  IN action.from_state%TYPE,
        i_check   IN action.internal_name%TYPE
    ) RETURN VARCHAR2 IS
        l_return  VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
        l_actions t_coll_action_cipe;
    BEGIN
        -- CALL get_actions_perm_int
        l_actions := get_actions_perm_int(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_subject    => i_subject,
                                          i_from_state => table_varchar(i_status));
    
        IF l_actions IS NOT NULL
           AND l_actions.count > 0
        THEN
            FOR i IN l_actions.first .. l_actions.last
            LOOP
                -- check if any given action (i_check) is active or not
                IF l_actions(i).internal_name = i_check
                    AND l_actions(i).flg_active = pk_alert_constant.g_active
                THEN
                    l_return := pk_alert_constant.g_yes;
                END IF;
            END LOOP;
        END IF;
    
        RETURN l_return;
    END check_permissions;

    /*
    * Returns the possible status 
    *    
    * @param     i_status   status            
    *
    * @return    TABLE_VARCHAR
    *
    * @author    Paulo Teixeira
    * @version   2.5.1
    * @since     2010/07/26
    */

    FUNCTION get_timeline_diagnosis_status(i_view_status IN VARCHAR2) RETURN table_varchar IS
        l_status table_varchar := table_varchar();
    BEGIN
        --build collection with possible states when a diagnosis is active or inactive, to be used in main query's
        IF i_view_status = pk_alert_constant.g_active
        THEN
            l_status := table_varchar(pk_icnp_constant.g_epis_diag_status_active,
                                      pk_icnp_constant.g_epis_diag_status_resolved,
                                      pk_icnp_constant.g_epis_diag_status_suspended);
        ELSIF i_view_status = pk_alert_constant.g_inactive
        THEN
            l_status := table_varchar(pk_icnp_constant.g_epis_diag_status_active,
                                      pk_icnp_constant.g_epis_diag_status_resolved,
                                      pk_icnp_constant.g_epis_diag_status_suspended,
                                      pk_icnp_constant.g_epis_diag_status_cancelled);
        END IF;
        RETURN l_status;
    END get_timeline_diagnosis_status;

    /**
    * Get interventions visible status.
    *
    * @param i_view_status  timeline view status
    *
    * @return               visible status list
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/08/02
    */
    FUNCTION get_timeline_interv_status(i_view_status IN VARCHAR2) RETURN table_varchar IS
        l_status table_varchar := table_varchar();
    BEGIN
        IF i_view_status = pk_alert_constant.g_active
        THEN
            l_status := table_varchar(pk_icnp_constant.g_epis_interv_status_ongoing,
                                      pk_icnp_constant.g_epis_interv_status_requested,
                                      pk_icnp_constant.g_epis_interv_status_executed,
                                      pk_icnp_constant.g_epis_interv_status_suspended);
        ELSIF i_view_status = pk_alert_constant.g_inactive
        THEN
            l_status := table_varchar(pk_icnp_constant.g_epis_interv_status_ongoing,
                                      pk_icnp_constant.g_epis_interv_status_requested,
                                      pk_icnp_constant.g_epis_interv_status_executed,
                                      pk_icnp_constant.g_epis_interv_status_suspended,
                                      pk_icnp_constant.g_epis_interv_status_cancelled);
        END IF;
        RETURN l_status;
    END get_timeline_interv_status;

    /**
    * Get a record's timeline view visibility.
    *
    * @param i_prof         logged professional structure
    * @param i_view_status  timeline view status
    * @param i_rec_status   record's status
    * @param i_episode      current episode identifier
    * @param i_rec_episode  record's episode identifier
    * @param i_timestamp    record's execution date
    * @param i_days_behind  days behind
    *
    * @return               record's timeline view visibility
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/07/30
    */
    FUNCTION check_visibility
    (
        i_prof        IN profissional,
        i_view_status IN VARCHAR2,
        i_rec_status  IN interv_icnp_ea.flg_status%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_rec_episode IN episode.id_episode%TYPE,
        i_dt_exec     IN interv_icnp_ea.dt_take_ea%TYPE,
        i_days_behind IN NUMBER
    ) RETURN PLS_INTEGER IS
        l_ret          PLS_INTEGER;
        l_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
        l_sysdate_aux  TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
        l_sysdate_tstz := current_timestamp;
        l_sysdate_aux  := current_timestamp - numtodsinterval(i_days_behind, 'DAY');
        IF i_view_status = pk_alert_constant.g_active
        THEN
            -- active records view
            IF i_rec_status IN (pk_icnp_constant.g_epis_diag_status_resolved,
                                pk_icnp_constant.g_epis_interv_status_executed,
                                pk_icnp_constant.g_epis_interv_status_cancelled,
                                pk_icnp_constant.g_epis_interv_status_discont)
            THEN
                -- inpatient environment
                IF i_prof.software = pk_alert_constant.g_soft_inpatient
                THEN
                    -- finished status
                    IF i_episode = i_rec_episode
                    THEN
                        -- finished on current episode
                        IF i_dt_exec > l_sysdate_aux
                        THEN
                            -- finished after 'days behind'
                            l_ret := g_show;
                        ELSE
                            -- finished before 'days behind'
                            l_ret := g_hide;
                        END IF;
                    ELSE
                        -- finished on other episodes
                        l_ret := g_hide;
                    END IF;
                ELSE
                    IF i_dt_exec > l_sysdate_aux
                    THEN
                        -- finished after 'days behind'
                        l_ret := g_show;
                    ELSE
                        -- finished before 'days behind'
                        l_ret := g_hide;
                    END IF;
                END IF;
            ELSE
                -- other status
                l_ret := g_show;
            END IF;
        ELSE
            -- inactive records view
            l_ret := g_show;
        END IF;
    
        RETURN l_ret;
    END check_visibility;

    /**
    * Get the number of days behind to show finished diagnoses and interventions
    * in the ICNP timeline view.
    *
    * @param i_prof         logged professional structure
    *
    * @return               days behind
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/08/05
    */
    FUNCTION get_days_behind(i_prof IN profissional) RETURN NUMBER IS
        l_config CONSTANT sys_config.id_sys_config%TYPE := 'ICNP_TIMELINE_DAYS_BEHIND';
        l_value sys_config.value%TYPE := NULL;
    BEGIN
    
        l_value := pk_sysconfig.get_config(i_code_cf => l_config, i_prof => i_prof);
    
        RETURN to_number(l_value);
    END get_days_behind;

    /*
    * Returns the tasks and views for the timeline documentation view
    *
    * @param     i_lang     Language id
    * @param     i_prof     Professional
    * @param     i_patient  Patient id
    * @param     i_episode  Episode id
    * @param     i_status   status    
    * @param     o_tasks    Tasks list
    * @param     o_view     Views list
    * @param     o_error    Error message
    
    * @return    true or false on success or error
    *
    * @author    Paulo Teixeira
    * @version   2.5.1
    * @since     2010/08/03
    */
    PROCEDURE get_icnp_doc_timeline
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN interv_icnp_ea.id_patient%TYPE,
        i_episode IN icnp_epis_diagnosis.id_episode%TYPE,
        i_status  IN icnp_epis_diagnosis.flg_status%TYPE,
        o_tasks   OUT pk_types.cursor_type,
        o_view    OUT pk_types.cursor_type
    ) IS
        l_label_no_spec sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'CPLAN_T056');
        l_diag_status   table_varchar := get_timeline_diagnosis_status(i_status);
        l_interv_status table_varchar := get_timeline_interv_status(i_status);
        l_days_behind   NUMBER;
        l_dt_server     sys_message.desc_message%TYPE;
        l_today         sys_message.desc_message%TYPE;
        l_sysdate_tstz  TIMESTAMP WITH LOCAL TIME ZONE;
        l_age           vital_sign_unit_measure.age_min%TYPE;
    BEGIN
        l_sysdate_tstz := current_timestamp;
        l_age          := pk_patient.get_pat_age(i_lang, NULL, NULL, NULL, 'MONTHS', i_patient);
        l_today        := pk_date_utils.get_month_day(i_lang => i_lang, i_prof => i_prof, i_timestamp => l_sysdate_tstz);
        l_dt_server    := pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => l_sysdate_tstz, i_prof => i_prof);
        l_days_behind  := get_days_behind(i_prof => i_prof);
    
        --build "documentação das intervenções" screen 
        --retrieve lines, query needs to have the same filters and joins of the get_icnp_doc_timeline_view but with the distinct option
        --the unique_id represents the line 
        OPEN o_tasks FOR
            SELECT DISTINCT iei.id_icnp_epis_interv || '_' || vs.id_vital_sign unique_id,
                            iei.id_icnp_epis_interv id_type,
                            pk_icnp.desc_composition(i_lang, iei.id_composition) name,
                            pk_sysdomain.get_domain(pk_icnp_constant.g_domain_epis_interv_status,
                                                    iei.flg_status,
                                                    i_lang) || ': ' ||
                            pk_date_utils.date_char_tsz(i_lang,
                                                        iei.dt_icnp_epis_interv_tstz,
                                                        i_prof.institution,
                                                        i_prof.software) || ' / ' ||
                            pk_prof_utils.get_name_signature(i_lang, i_prof, iei.id_prof) || ', ' ||
                            nvl(pk_prof_utils.get_spec_signature(i_lang,
                                                                 i_prof,
                                                                 iei.id_prof,
                                                                 iei.dt_icnp_epis_interv_tstz,
                                                                 NULL),
                                l_label_no_spec) detail
              FROM icnp_epis_intervention iei
              JOIN icnp_epis_diag_interv iedi
                ON iedi.id_icnp_epis_interv = iei.id_icnp_epis_interv
              JOIN icnp_epis_diagnosis ied
                ON ied.id_icnp_epis_diag = iedi.id_icnp_epis_diag
              JOIN icnp_interv_plan iip
                ON iip.id_icnp_epis_interv = iei.id_icnp_epis_interv
              JOIN icnp_epis_task iet
                ON iip.id_icnp_interv_plan = iet.id_icnp_interv_plan
              LEFT JOIN vital_sign_read vsr
                ON vsr.id_vital_sign_read = iet.id_task
              LEFT JOIN vital_sign vs
                ON vs.id_vital_sign = vsr.id_vital_sign
              LEFT JOIN vital_sign_desc vsd
                ON vsd.id_vital_sign_desc = vsr.id_vital_sign_desc
             WHERE iei.id_patient = i_patient
               AND iei.id_episode_destination IS NULL
               AND ied.flg_status IN (SELECT t.column_value flg_status
                                        FROM TABLE(l_diag_status) t)
               AND check_visibility(i_prof,
                                    i_status,
                                    ied.flg_status,
                                    i_episode,
                                    ied.id_episode,
                                    ied.dt_close_tstz,
                                    l_days_behind) = g_show
               AND iei.flg_status IN (SELECT t.column_value flg_status
                                        FROM TABLE(l_interv_status) t)
             ORDER BY name;
    
        -- OPEN o_view
        OPEN o_view FOR
            SELECT iei.id_icnp_epis_interv || '_' || vs.id_vital_sign unique_id,
                   iei.id_icnp_epis_interv id_type,
                   pk_icnp.desc_composition(i_lang, iei.id_composition) name,
                   vs.id_vital_sign id_task,
                   pk_translation.get_translation(i_lang, vs.code_vital_sign) desc_task,
                   l_today today,
                   pk_date_utils.get_month_day(i_lang, i_prof, vsr.dt_vital_sign_read_tstz) dt_begin,
                   pk_date_utils.get_year(i_lang, i_prof, vsr.dt_vital_sign_read_tstz) YEAR,
                   pk_utils.get_status_string_immediate(i_lang,
                                                         i_prof,
                                                         'T',
                                                         NULL,
                                                         CASE
                                                             WHEN vsd.id_vital_sign_desc IS NOT NULL THEN
                                                              pk_translation.get_translation(i_lang, vsd.code_vital_sign_desc)
                                                             ELSE
                                                              round(vsr.value, 3) || pk_icnp_constant.g_word_space ||
                                                              nvl(pk_unit_measure.get_unit_measure_description(i_lang, i_prof, vsr.id_unit_measure),
                                                                  pk_icnp_constant.g_word_open_brac || (SELECT pk_vital_sign_core.get_vsum_val_min(i_lang            => i_lang,
                                                                                                                                                   i_prof            => i_prof,
                                                                                                                                                   i_id_vital_sign   => vsr.id_vital_sign,
                                                                                                                                                   i_id_unit_measure => vsr.id_unit_measure,
                                                                                                                                                   i_id_institution  => i_prof.institution,
                                                                                                                                                   i_id_software     => i_prof.software,
                                                                                                                                                   i_age             => l_age)
                                                                                                          FROM dual) || '-' ||
                                                                  (SELECT pk_vital_sign_core.get_vsum_val_max(i_lang            => i_lang,
                                                                                                              i_prof            => i_prof,
                                                                                                              i_id_vital_sign   => vsr.id_vital_sign,
                                                                                                              i_id_unit_measure => vsr.id_unit_measure,
                                                                                                              i_id_institution  => i_prof.institution,
                                                                                                              i_id_software     => i_prof.software,
                                                                                                              i_age             => l_age)
                                                                     FROM dual) || pk_icnp_constant.g_word_close_brac)
                                                         END,
                                                         NULL,
                                                         NULL,
                                                         NULL,
                                                         NULL,
                                                         NULL,
                                                         NULL,
                                                         NULL,
                                                         NULL) status,
                   to_char(vsr.dt_vital_sign_read_tstz, pk_alert_constant.g_dt_yyyymmddhh24miss) dt_ord,
                   l_dt_server dt_server,
                   pk_date_utils.get_hour_short(i_lang, i_prof, vsr.dt_vital_sign_read_tstz) hour_str,
                   iip.id_icnp_interv_plan
              FROM icnp_epis_intervention iei
              JOIN icnp_epis_diag_interv iedi
                ON iedi.id_icnp_epis_interv = iei.id_icnp_epis_interv
              JOIN icnp_epis_diagnosis ied
                ON ied.id_icnp_epis_diag = iedi.id_icnp_epis_diag
              JOIN icnp_interv_plan iip
                ON iip.id_icnp_epis_interv = iei.id_icnp_epis_interv
              JOIN icnp_epis_task iet
                ON iip.id_icnp_interv_plan = iet.id_icnp_interv_plan
              LEFT JOIN vital_sign_read vsr
                ON vsr.id_vital_sign_read = iet.id_task
              LEFT JOIN vital_sign vs
                ON vs.id_vital_sign = vsr.id_vital_sign
              LEFT JOIN vital_sign_desc vsd
                ON vsd.id_vital_sign_desc = vsr.id_vital_sign_desc
             WHERE iei.id_patient = i_patient
               AND iei.id_episode_destination IS NULL
               AND ied.flg_status IN (SELECT t.column_value flg_status
                                        FROM TABLE(l_diag_status) t)
               AND check_visibility(i_prof,
                                    i_status,
                                    ied.flg_status,
                                    i_episode,
                                    ied.id_episode,
                                    ied.dt_close_tstz,
                                    l_days_behind) = g_show
               AND iei.flg_status IN (SELECT t.column_value flg_status
                                        FROM TABLE(l_interv_status) t)
             ORDER BY unique_id, dt_ord, name, desc_task;
    
    END get_icnp_doc_timeline;

    /*
    * Returns the tasks and views for the timeline view
    *
    * @param     i_lang     Language id
    * @param     i_prof     Professional
    * @param     i_patient  Patient id
    * @param     i_episode  Episode id
    * @param     i_status   status    
    * @param     o_tasks    Tasks list
    * @param     o_view     Views list
    * @param     o_error    Error message
    
    * @return    true or false on success or error
    *
    * @author    Paulo Teixeira
    * @version   2.5.1
    * @since     2010/08/03
    */
    PROCEDURE get_icnp_timeline
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN interv_icnp_ea.id_patient%TYPE,
        i_episode IN icnp_epis_diagnosis.id_episode%TYPE,
        i_status  IN icnp_epis_diagnosis.flg_status%TYPE,
        o_tasks   OUT pk_types.cursor_type,
        o_view    OUT pk_types.cursor_type
    ) IS
        c_id_diag         CONSTANT VARCHAR(1 CHAR) := '1';
        c_id_interv       CONSTANT VARCHAR(1 CHAR) := '2';
        c_id_interv_presc CONSTANT VARCHAR(1 CHAR) := '3';
    
        l_label_diagnosis    sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'CPLAN_T007');
        l_label_interv       sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'CPLAN_T021');
        l_label_interv_presc sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'CPLAN_T201');
        l_today              sys_message.desc_message%TYPE;
        l_dt_server          sys_message.desc_message%TYPE;
        l_days_behind        NUMBER;
        l_sysdate_tstz       TIMESTAMP WITH LOCAL TIME ZONE;
        l_view               t_tab_icnp_timeline;
    
        t_interv_list     t_coll_interv_icnp_ea;
        l_code_sys_config sys_config.id_sys_config%TYPE := 'ICNP_CARE_PLAN_SCOPE';
        l_care_plan_scope VARCHAR2(1);
        l_episodes        table_number;
        l_id_visit        episode.id_visit%TYPE;
    
    BEGIN
        l_sysdate_tstz := current_timestamp;
    
        l_today       := pk_date_utils.get_month_day(i_lang => i_lang, i_prof => i_prof, i_timestamp => l_sysdate_tstz);
        l_dt_server   := pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => l_sysdate_tstz, i_prof => i_prof);
        l_days_behind := get_days_behind(i_prof => i_prof);
        l_id_visit    := pk_episode.get_id_visit(i_episode => i_episode);
    
        --(P- Patient , E-Episode, V-VISIT)                                        
        l_care_plan_scope := pk_sysconfig.get_config(i_code_cf => l_code_sys_config, i_prof => i_prof);
    
        CASE l_care_plan_scope
            WHEN g_icnp_care_plan_e THEN
                l_episodes := NULL;
            WHEN g_icnp_care_plan_p THEN
                SELECT e.id_episode
                  BULK COLLECT
                  INTO l_episodes
                  FROM episode e
                 WHERE e.id_patient = i_patient
                   AND e.id_episode <> i_episode;
            WHEN g_icnp_care_plan_v THEN
                SELECT e.id_episode
                  BULK COLLECT
                  INTO l_episodes
                  FROM episode e
                 WHERE e.id_visit = l_id_visit
                   AND e.id_episode <> i_episode;
        END CASE;
    
        --get interventions
        SELECT t_rec_interv_icnp_ea(id_icnp_epis_interv,
                                    NULL,
                                    get_interv_instructions(i_lang, i_prof, id_icnp_epis_interv),
                                    id_composition_interv,
                                    id_icnp_epis_diag,
                                    id_composition_diag,
                                    flg_time,
                                    status_str,
                                    status_msg,
                                    status_icon,
                                    status_flg,
                                    flg_status,
                                    flg_type,
                                    dt_next,
                                    dt_plan,
                                    id_vs,
                                    id_prof_close,
                                    dt_close,
                                    dt_icnp_epis_interv,
                                    id_prof,
                                    id_episode_origin,
                                    id_episode,
                                    id_patient,
                                    flg_status_plan,
                                    id_prof_take,
                                    notes,
                                    notes_close,
                                    dt_begin,
                                    dt_take_ea,
                                    dt_dg_last_update)
          BULK COLLECT
          INTO t_interv_list
          FROM (SELECT *
                  FROM interv_icnp_ea iea
                 WHERE iea.id_episode = i_episode
                UNION ALL
                SELECT *
                  FROM interv_icnp_ea ea
                 WHERE ea.flg_status IN
                       (pk_icnp_constant.g_epis_diag_status_active, pk_icnp_constant.g_epis_diag_status_in_progress)
                   AND ea.id_episode IN (SELECT /*+opt_estimate(table t rows=1)*/
                                          column_value
                                           FROM TABLE(l_episodes) t));
    
        --
        SELECT t_rec_icnp_timeline(aux.unique_id, aux.id, aux.id_type, aux.name, aux.flg_status)
          BULK COLLECT
          INTO l_view
          FROM (SELECT DISTINCT c_id_interv || '_' || iei.id_icnp_epis_interv AS unique_id,
                                iei.id_icnp_epis_interv id,
                                c_id_interv id_type,
                                l_label_interv name,
                                iei.flg_status
                  FROM icnp_epis_intervention iei
                  JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                        t.*
                         FROM TABLE(t_interv_list) t) iea
                    ON iea.id_icnp_epis_interv = iei.id_icnp_epis_interv
                 WHERE iei.id_patient = i_patient
                   AND EXISTS
                 (SELECT 1
                          FROM icnp_epis_diag_interv iedi
                         WHERE iedi.id_icnp_epis_interv = iea.id_icnp_epis_interv
                           AND iedi.flg_status_rel IN
                               (pk_icnp_constant.g_interv_rel_active, pk_icnp_constant.g_interv_rel_reactivated))
                   AND check_visibility(i_prof,
                                        i_status,
                                        iei.flg_status,
                                        i_episode,
                                        iei.id_episode,
                                        coalesce(iei.dt_close_tstz, iei.dt_suspend, iei.dt_cancel, iei.dt_end_tstz),
                                        l_days_behind) = g_show
                
                UNION ALL
                --DIAG 
                SELECT c_id_diag || '_' || ied.id_icnp_epis_diag AS unique_id,
                       ied.id_icnp_epis_diag id,
                       c_id_diag id_type,
                       l_label_diagnosis name,
                       ied.flg_status
                  FROM (SELECT ied.*
                          FROM icnp_epis_diagnosis ied
                         WHERE ied.id_episode = i_episode
                        UNION
                        SELECT ied.*
                          FROM icnp_epis_diagnosis ied
                         WHERE ied.id_episode IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                   column_value
                                                    FROM TABLE(l_episodes) t)) ied
                UNION ALL
                --INTERV PRESC
                SELECT DISTINCT c_id_interv_presc || '_' || iei.id_icnp_epis_interv AS unique_id,
                                iei.id_icnp_epis_interv id,
                                c_id_interv_presc id_type,
                                l_label_interv_presc name,
                                iei.flg_status
                  FROM icnp_epis_intervention iei
                  JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                        t.*
                         FROM TABLE(t_interv_list) t) iea
                    ON iea.id_icnp_epis_interv = iei.id_icnp_epis_interv
                  JOIN icnp_suggest_interv isi
                    ON isi.id_icnp_epis_interv = iea.id_icnp_epis_interv
                 WHERE iei.id_patient = i_patient
                   AND NOT EXISTS
                 (SELECT 1
                          FROM icnp_epis_diag_interv iedi
                         WHERE iedi.id_icnp_epis_interv = iea.id_icnp_epis_interv
                           AND iedi.flg_status_rel IN
                               (pk_icnp_constant.g_interv_rel_active, pk_icnp_constant.g_interv_rel_reactivated))
                   AND check_visibility(i_prof,
                                        i_status,
                                        iei.flg_status,
                                        i_episode,
                                        iei.id_episode,
                                        iei.dt_close_tstz,
                                        l_days_behind) = g_show) aux;
    
        --the unique_id represents the line  
        OPEN o_tasks FOR
            SELECT task.unique_id,
                   task.id_type,
                   task.name,
                   pk_icnp.get_icnp_tooltip(i_lang     => i_lang,
                                            i_prof     => i_prof,
                                            i_id_task  => task.id,
                                            i_flg_type => task.id_type,
                                            i_screen   => 2) tooltip,
                   pk_alert_constant.g_yes task_avail_butt_action,
                   decode(task.id_type,
                          c_id_interv,
                          check_permissions(i_lang,
                                            i_prof,
                                            pk_icnp_constant.g_action_subject_interv,
                                            task.flg_status,
                                            pk_icnp_constant.g_action_interv_cancel),
                          c_id_diag,
                          check_permissions(i_lang,
                                            i_prof,
                                            pk_icnp_constant.g_action_subject_diag,
                                            task.flg_status,
                                            pk_icnp_constant.g_action_diag_cancel),
                          c_id_interv_presc,
                          check_permissions(i_lang,
                                            i_prof,
                                            pk_icnp_constant.g_action_subject_interv,
                                            task.flg_status,
                                            pk_icnp_constant.g_action_interv_cancel)) task_avail_butt_cancel
              FROM (TABLE(l_view)) task
             ORDER BY unique_id;
    
        --retrieve the values to populate the columns
        --the unique_id represents the line 
        OPEN o_view FOR
            SELECT v.*,
                   decode(v.id_icnp_epis_interv, NULL, NULL, get_interv_assoc_diag(v.id_icnp_epis_interv)) assoc_diag,
                   decode((SELECT COUNT(*)
                            FROM icnp_epis_intervention i
                           WHERE i.id_icnp_epis_interv_parent = v.id_icnp_epis_interv),
                          0,
                          pk_alert_constant.g_yes,
                          pk_alert_constant.g_no) flg_next_epis_active,
                   pk_icnp.get_icnp_exec_tooltip(i_lang         => i_lang,
                                                 i_prof         => i_prof,
                                                 i_id_task      => decode(v.id_type,
                                                                          1,
                                                                          v.id_icnp_epis_diag,
                                                                          v.id_icnp_epis_interv),
                                                 i_id_diag      => id_diagnosis,
                                                 i_id_interv    => id_icnp_epis_interv,
                                                 i_id_plan      => id_icnp_interv_plan,
                                                 i_id_diag_hist => id_icnp_epis_diag_hist,
                                                 i_flg_type     => v.id_type) tooltip
              FROM (SELECT c_id_interv || '_' || sel_distinct.id_icnp_epis_interv unique_id,
                           c_id_interv id_type,
                           l_label_interv name,
                           NULL id_icnp_epis_diag,
                           NULL id_diagnosis,
                           sel_distinct.id_icnp_epis_interv,
                           sel_distinct.id_icnp_interv_plan,
                           pk_icnp.desc_composition(i_lang, sel_distinct.id_composition) desc_task,
                           decode(nvl(substr(sel_distinct.id_vs, 1, 1), sel_distinct.area),
                                  'VS',
                                  'V',
                                  'BIO',
                                  'B',
                                  nvl(substr(sel_distinct.id_vs, 1, 1), sel_distinct.area)) flg_type_vs,
                           nvl(to_number(substr(sel_distinct.id_vs, 2, 7)),
                               decode(substr(sel_distinct.parameter_desc, 1, 27),
                                      'VITAL_SIGN.CODE_VITAL_SIGN.',
                                      to_number(substr(sel_distinct.parameter_desc,
                                                       28,
                                                       length(sel_distinct.parameter_desc))),
                                      NULL)) id_vs,
                           g_type_interv flg_type,
                           l_today today,
                           pk_date_utils.get_month_day(i_lang,
                                                       i_prof,
                                                       coalesce(sel_distinct.dt_take_tstz,
                                                                sel_distinct.dt_plan_tstz,
                                                                sel_distinct.dt_icnp_epis_interv_tstz)) dt_begin,
                           pk_date_utils.get_year(i_lang,
                                                  i_prof,
                                                  coalesce(sel_distinct.dt_take_tstz,
                                                           sel_distinct.dt_plan_tstz,
                                                           sel_distinct.dt_icnp_epis_interv_tstz)) YEAR,
                           sel_distinct.flg_status_iip flg_status,
                           get_status_str(i_lang,
                                          i_prof,
                                          g_type_exec,
                                          decode(sel_distinct.flg_status_iip,
                                                 NULL,
                                                 NULL,
                                                 pk_icnp_constant.g_interv_plan_status_not_exec,
                                                 pk_icnp_constant.g_interv_plan_status_cancelled,
                                                 pk_icnp_constant.g_interv_plan_status_requested,
                                                 decode(sel_distinct.id_order_recurr_option,
                                                        pk_order_recurrence_core.g_order_recurr_option_no_sched,
                                                        NULL,
                                                        sel_distinct.flg_status_iip),
                                                 sel_distinct.flg_status_iip),
                                          sel_distinct.dt_take_tstz,
                                          sel_distinct.dt_plan_tstz,
                                          sel_distinct.exec_number,
                                          NULL,
                                          sel_distinct.flg_prn) status,
                           decode(sel_distinct.flg_type,
                                  pk_icnp_constant.g_epis_interv_type_no_schedule,
                                  pk_alert_constant.g_no,
                                  pk_alert_constant.g_yes) avail_butt_action,
                           check_permissions(i_lang,
                                             i_prof,
                                             pk_icnp_constant.g_action_subject_interv_exec,
                                             sel_distinct.flg_status_iip,
                                             pk_icnp_constant.g_action_exec_cancel) avail_butt_cancel,
                           check_exec_permission(sel_distinct.id_icnp_interv_plan) avail_butt_execute,
                           to_char(coalesce(sel_distinct.dt_take_tstz,
                                            sel_distinct.dt_plan_tstz,
                                            sel_distinct.dt_icnp_epis_interv_tstz),
                                   pk_alert_constant.g_dt_yyyymmddhh24miss) dt_ord,
                           l_dt_server dt_server,
                           pk_date_utils.get_hour_short(i_lang,
                                                        i_prof,
                                                        coalesce(sel_distinct.dt_take_tstz,
                                                                 sel_distinct.dt_plan_tstz,
                                                                 sel_distinct.dt_icnp_epis_interv_tstz)) hour_str,
                           '1' query,
                           (SELECT pk_sysdomain.get_domain(pk_icnp_constant.g_domain_interv_plan_status,
                                                           sel_distinct.flg_status_iip,
                                                           i_lang)
                              FROM dual) desc_status,
                           sel_distinct.flg_status_iei flg_status1,
                           (SELECT pk_sysdomain.get_domain(pk_icnp_constant.g_domain_epis_interv_status,
                                                           sel_distinct.flg_status_iei,
                                                           i_lang)
                              FROM dual) desc_status1,
                           pk_utils.get_status_string(i_lang,
                                                      i_prof,
                                                      sel_distinct.status_str,
                                                      sel_distinct.status_msg,
                                                      sel_distinct.status_icon,
                                                      sel_distinct.status_flg_iea) TYPE,
                           pk_date_utils.date_send_tsz(i_lang, sel_distinct.dt_begin_tstz, i_prof) dt_begin_tstz,
                           sel_distinct.id_doc_template,
                           sel_distinct.dt_last_update,
                           NULL id_icnp_epis_diag_hist
                      FROM (SELECT DISTINCT iei.id_icnp_epis_interv,
                                            iip.dt_last_update,
                                            ic.id_doc_template,
                                            iei.dt_begin_tstz,
                                            iea.flg_status               status_flg_iea,
                                            iea.status_str,
                                            iea.status_msg,
                                            iea.status_icon,
                                            iei.flg_status               flg_status_iei,
                                            iip.flg_status               flg_status_iip,
                                            iip.dt_take_tstz,
                                            iip.dt_plan_tstz,
                                            iei.dt_icnp_epis_interv_tstz,
                                            iip.id_icnp_interv_plan,
                                            iei.flg_type,
                                            iei.flg_prn,
                                            iip.exec_number,
                                            iaa.parameter_desc,
                                            iea.id_vs,
                                            iaa.area,
                                            iei.id_composition,
                                            orp.id_order_recurr_option
                              FROM (SELECT ss.id
                                      FROM TABLE(l_view) ss
                                     WHERE ss.id_type = c_id_interv) s
                              JOIN icnp_epis_intervention iei
                                ON s.id = iei.id_icnp_epis_interv
                              JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                                    t.*
                                     FROM TABLE(t_interv_list) t) iea
                                ON iea.id_icnp_epis_interv = iei.id_icnp_epis_interv
                              LEFT JOIN (SELECT ii.*
                                          FROM icnp_interv_plan ii
                                         WHERE (ii.flg_status NOT IN
                                               (pk_icnp_constant.g_interv_plan_status_freq_alt,
                                                 pk_icnp_constant.g_interv_plan_status_not_exec) OR
                                               ii.flg_status IS NULL)) iip
                                ON iip.id_icnp_epis_interv = iei.id_icnp_epis_interv
                              LEFT JOIN order_recurr_plan orp
                                ON iip.id_order_recurr_plan = orp.id_order_recurr_plan
                              JOIN icnp_composition ic
                                ON ic.id_composition = iei.id_composition
                              LEFT JOIN icnp_application_area iaa
                                ON iaa.id_application_area = ic.id_application_area
                             WHERE iei.id_patient = i_patient
                               AND EXISTS (SELECT 1
                                      FROM icnp_epis_diag_interv iedi
                                     WHERE iedi.id_icnp_epis_interv = iea.id_icnp_epis_interv
                                       AND iedi.flg_status_rel IN
                                           (pk_icnp_constant.g_interv_rel_active,
                                            pk_icnp_constant.g_interv_rel_reactivated))) sel_distinct
                    
                    UNION ALL
                    SELECT c_id_diag || '_' || ied.id_icnp_epis_diag unique_id,
                           c_id_diag id_type,
                           l_label_diagnosis name,
                           ied.id_icnp_epis_diag,
                           ied.id_composition id_diagnosis,
                           NULL id_icnp_epis_interv,
                           NULL id_icnp_interv_plan,
                           pk_icnp.desc_composition(i_lang, ied.id_composition) desc_task,
                           NULL flg_type_vs,
                           NULL id_vs,
                           g_type_diag flg_type,
                           l_today today,
                           pk_date_utils.get_month_day(i_lang,
                                                       i_prof,
                                                       coalesce(ied.dt_last_update,
                                                                ied.dt_close_tstz,
                                                                ied.dt_icnp_epis_diag_tstz)) dt_begin,
                           pk_date_utils.get_year(i_lang,
                                                  i_prof,
                                                  coalesce(ied.dt_last_update,
                                                           ied.dt_close_tstz,
                                                           ied.dt_icnp_epis_diag_tstz)) YEAR,
                           ied.flg_status,
                           get_status_str(i_lang, i_prof, g_type_diag, ied.flg_status, NULL, NULL, NULL, NULL, NULL) status,
                           pk_alert_constant.g_yes avail_butt_action,
                           check_permissions(i_lang,
                                             i_prof,
                                             pk_icnp_constant.g_action_subject_diag,
                                             ied.flg_status,
                                             pk_icnp_constant.g_action_diag_cancel) avail_butt_cancel,
                           pk_alert_constant.g_no pavail_butt_execute,
                           to_char(coalesce(ied.dt_last_update, ied.dt_close_tstz, ied.dt_icnp_epis_diag_tstz),
                                   pk_alert_constant.g_dt_yyyymmddhh24miss) dt_ord,
                           l_dt_server dt_server,
                           pk_date_utils.get_hour_short(i_lang,
                                                        i_prof,
                                                        coalesce(ied.dt_last_update,
                                                                 ied.dt_close_tstz,
                                                                 ied.dt_icnp_epis_diag_tstz)) hour_str,
                           '2' query,
                           (SELECT pk_sysdomain.get_domain(pk_icnp_constant.g_domain_epis_diag_status,
                                                           ied.flg_status,
                                                           i_lang)
                              FROM dual) desc_status,
                           NULL flg_status1,
                           NULL desc_status1,
                           get_status_str(i_lang, i_prof, g_type_diag, ied.flg_status, NULL, NULL, NULL, NULL, NULL) TYPE,
                           NULL dt_begin_tstz,
                           NULL id_doc_template,
                           ied.dt_last_update,
                           NULL id_icnp_epis_diag_hist
                      FROM (SELECT ss.id
                              FROM TABLE(l_view) ss
                             WHERE ss.id_type = c_id_diag) s
                      JOIN icnp_epis_diagnosis ied
                        ON s.id = ied.id_icnp_epis_diag
                     WHERE ied.id_patient = i_patient
                    UNION ALL
                    SELECT c_id_diag || '_' || iedh.id_icnp_epis_diag unique_id,
                           c_id_diag id_type,
                           l_label_diagnosis name,
                           iedh.id_icnp_epis_diag,
                           iedh.id_composition id_diagnosis,
                           NULL id_icnp_epis_interv,
                           NULL id_icnp_interv_plan,
                           pk_icnp.desc_composition(i_lang, iedh.id_composition) desc_task,
                           NULL flg_type_vs,
                           NULL id_vs,
                           g_type_diag flg_type,
                           l_today today,
                           pk_date_utils.get_month_day(i_lang,
                                                       i_prof,
                                                       coalesce(iedh.dt_last_update,
                                                                iedh.dt_close,
                                                                iedh.dt_icnp_epis_diag)) dt_begin,
                           pk_date_utils.get_year(i_lang,
                                                  i_prof,
                                                  coalesce(iedh.dt_last_update, iedh.dt_close, iedh.dt_icnp_epis_diag)) YEAR,
                           iedh.flg_status,
                           get_status_str(i_lang, i_prof, g_type_diag, iedh.flg_status, NULL, NULL, NULL, NULL, NULL) status,
                           pk_alert_constant.g_yes avail_butt_action,
                           check_permissions(i_lang,
                                             i_prof,
                                             pk_icnp_constant.g_action_subject_diag,
                                             (SELECT ied.flg_status
                                                FROM icnp_epis_diagnosis ied
                                               WHERE ied.id_icnp_epis_diag = iedh.id_icnp_epis_diag),
                                             pk_icnp_constant.g_action_diag_cancel) avail_butt_cancel,
                           pk_alert_constant.g_no avail_butt_execute,
                           to_char(coalesce(iedh.dt_last_update, iedh.dt_close, iedh.dt_icnp_epis_diag),
                                   pk_alert_constant.g_dt_yyyymmddhh24miss) dt_ord,
                           l_dt_server dt_server,
                           pk_date_utils.get_hour_short(i_lang,
                                                        i_prof,
                                                        coalesce(iedh.dt_last_update,
                                                                 iedh.dt_close,
                                                                 iedh.dt_icnp_epis_diag)) hour_str,
                           '3' query,
                           (SELECT pk_sysdomain.get_domain(pk_icnp_constant.g_domain_epis_diag_status,
                                                           iedh.flg_status,
                                                           i_lang)
                              FROM dual) desc_status,
                           NULL flg_status1,
                           NULL desc_status1,
                           get_status_str(i_lang, i_prof, g_type_diag, iedh.flg_status, NULL, NULL, NULL, NULL, NULL) TYPE,
                           NULL dt_begin_tstz,
                           NULL id_doc_template,
                           iedh.dt_last_update,
                           iedh.id_icnp_epis_diag_hist id_icnp_epis_diag_hist
                      FROM (SELECT ss.id
                              FROM TABLE(l_view) ss
                             WHERE ss.id_type = c_id_diag) s
                      JOIN icnp_epis_diagnosis_hist iedh
                        ON s.id = iedh.id_icnp_epis_diag
                     WHERE iedh.id_patient = i_patient
                    UNION ALL
                    SELECT c_id_interv_presc || '_' || sel_distinct.id_icnp_epis_interv unique_id,
                           c_id_interv_presc id_type,
                           l_label_interv_presc name,
                           NULL id_icnp_epis_diag,
                           NULL id_diagnosis,
                           sel_distinct.id_icnp_epis_interv,
                           sel_distinct.id_icnp_interv_plan,
                           pk_icnp.desc_composition(i_lang, sel_distinct.id_composition) desc_task,
                           decode(nvl(substr(sel_distinct.id_vs, 1, 1), sel_distinct.area),
                                  'VS',
                                  'V',
                                  'BIO',
                                  'B',
                                  nvl(substr(sel_distinct.id_vs, 1, 1), sel_distinct.area)) flg_type_vs,
                           nvl(to_number(substr(sel_distinct.id_vs, 2, 7)),
                               decode(substr(sel_distinct.parameter_desc, 1, 27),
                                      'VITAL_SIGN.CODE_VITAL_SIGN.',
                                      to_number(substr(sel_distinct.parameter_desc,
                                                       28,
                                                       length(sel_distinct.parameter_desc))),
                                      NULL)) id_vs,
                           g_type_interv flg_type,
                           l_today today,
                           pk_date_utils.get_month_day(i_lang,
                                                       i_prof,
                                                       coalesce(sel_distinct.dt_take_tstz,
                                                                sel_distinct.dt_plan_tstz,
                                                                sel_distinct.dt_icnp_epis_interv_tstz)) dt_begin,
                           pk_date_utils.get_year(i_lang,
                                                  i_prof,
                                                  coalesce(sel_distinct.dt_take_tstz,
                                                           sel_distinct.dt_plan_tstz,
                                                           sel_distinct.dt_icnp_epis_interv_tstz)) YEAR,
                           sel_distinct.flg_status_iip flg_status,
                           get_status_str(i_lang,
                                          i_prof,
                                          g_type_exec,
                                          sel_distinct.flg_status_iip,
                                          sel_distinct.dt_take_tstz,
                                          sel_distinct.dt_plan_tstz,
                                          sel_distinct.exec_number,
                                          NULL,
                                          sel_distinct.flg_prn) status,
                           decode(sel_distinct.flg_type,
                                  pk_icnp_constant.g_epis_interv_type_no_schedule,
                                  pk_alert_constant.g_no,
                                  pk_alert_constant.g_yes) avail_butt_action,
                           check_permissions(i_lang,
                                             i_prof,
                                             pk_icnp_constant.g_action_subject_interv_exec,
                                             sel_distinct.flg_status_iip,
                                             pk_icnp_constant.g_action_exec_cancel) avail_butt_cancel,
                           check_exec_permission(sel_distinct.id_icnp_interv_plan) avail_butt_execute,
                           to_char(coalesce(sel_distinct.dt_take_tstz,
                                            sel_distinct.dt_plan_tstz,
                                            sel_distinct.dt_icnp_epis_interv_tstz),
                                   pk_alert_constant.g_dt_yyyymmddhh24miss) dt_ord,
                           l_dt_server dt_server,
                           pk_date_utils.get_hour_short(i_lang,
                                                        i_prof,
                                                        coalesce(sel_distinct.dt_take_tstz,
                                                                 sel_distinct.dt_plan_tstz,
                                                                 sel_distinct.dt_icnp_epis_interv_tstz)) hour_str,
                           '4' query,
                           (SELECT pk_sysdomain.get_domain(pk_icnp_constant.g_domain_interv_plan_status,
                                                           sel_distinct.flg_status_iip,
                                                           i_lang)
                              FROM dual) desc_status,
                           sel_distinct.flg_status_iei flg_status1,
                           (SELECT pk_sysdomain.get_domain(pk_icnp_constant.g_domain_epis_interv_status,
                                                           sel_distinct.flg_status_iei,
                                                           i_lang)
                              FROM dual) desc_status1,
                           pk_utils.get_status_string(i_lang,
                                                      i_prof,
                                                      sel_distinct.status_str,
                                                      sel_distinct.status_msg,
                                                      sel_distinct.status_icon,
                                                      sel_distinct.status_flg_iea) TYPE,
                           pk_date_utils.date_send_tsz(i_lang, sel_distinct.dt_begin_tstz, i_prof) dt_begin_tstz,
                           sel_distinct.id_doc_template id_doc_template,
                           sel_distinct.dt_last_update,
                           NULL id_icnp_epis_diag_hist
                      FROM (SELECT DISTINCT iei.id_icnp_epis_interv,
                                            iip.dt_last_update,
                                            ic.id_doc_template,
                                            iei.dt_begin_tstz,
                                            iea.flg_status               status_flg_iea,
                                            iea.status_str,
                                            iea.status_msg,
                                            iea.status_icon,
                                            iei.flg_status               flg_status_iei,
                                            iip.flg_status               flg_status_iip,
                                            iip.dt_take_tstz,
                                            iip.dt_plan_tstz,
                                            iei.dt_icnp_epis_interv_tstz,
                                            iip.id_icnp_interv_plan,
                                            iei.flg_type,
                                            iei.flg_prn,
                                            iip.exec_number,
                                            iaa.parameter_desc,
                                            iea.id_vs,
                                            iaa.area,
                                            iei.id_composition
                              FROM (SELECT ss.id
                                      FROM TABLE(l_view) ss
                                     WHERE ss.id_type = c_id_interv_presc) s
                              JOIN icnp_epis_intervention iei
                                ON s.id = iei.id_icnp_epis_interv
                              JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                                    t.*
                                     FROM TABLE(t_interv_list) t) iea
                                ON iea.id_icnp_epis_interv = iei.id_icnp_epis_interv
                              LEFT JOIN (SELECT *
                                          FROM icnp_interv_plan
                                         WHERE (flg_status NOT IN
                                               (pk_icnp_constant.g_interv_plan_status_freq_alt,
                                                 pk_icnp_constant.g_interv_plan_status_not_exec) OR flg_status IS NULL)) iip
                                ON iip.id_icnp_epis_interv = iei.id_icnp_epis_interv
                              JOIN icnp_composition ic
                                ON ic.id_composition = iei.id_composition
                              LEFT JOIN icnp_application_area iaa
                                ON iaa.id_application_area = ic.id_application_area
                              JOIN icnp_suggest_interv isi
                                ON isi.id_icnp_epis_interv = iei.id_icnp_epis_interv
                             WHERE iei.id_patient = i_patient
                               AND NOT EXISTS (SELECT 1
                                      FROM icnp_epis_diag_interv iedi
                                     WHERE iedi.id_icnp_epis_interv = iea.id_icnp_epis_interv
                                       AND iedi.flg_status_rel IN
                                           (pk_icnp_constant.g_interv_rel_active,
                                            pk_icnp_constant.g_interv_rel_reactivated))) sel_distinct
                     ORDER BY dt_ord, dt_last_update) v;
    
    END get_icnp_timeline;

    /********************************************************************************************
    * Returns the list of interventions descriptions (optionally intructions) associated to a diagnosis
    *
    * @param      i_lang                    Preferred language ID for this professional
    * @param      i_prof                    Object (professional ID, institution ID, software ID)
    * @param      i_icnp_epis_diag          Diagnosis ID
    * @param      i_show_instr              Show intervention instructions (Y - yes, N - No)
    * @param      i_sep                     Word separator character
    * @param      i_end                     Word end character
    * @param      i_dt_limit                Maximum date of the intervention (Used to get differences)
    *
    * @return             String with interventions description (optionally intructions)
    *
    * @author                Sérgio Santos
    * @version               2.5.1
    * @since                 2010/08/02
    *********************************************************************************************/
    FUNCTION get_diag_interventions_desc
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_icnp_epis_diag IN icnp_epis_diagnosis.id_icnp_epis_diag%TYPE,
        i_show_instr     IN VARCHAR2,
        i_sep            IN VARCHAR2,
        i_end            IN VARCHAR2,
        i_dt_limit       IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_flg_report     IN VARCHAR2 DEFAULT 'N'
    ) RETURN VARCHAR2 IS
        l_result     VARCHAR2(4000 CHAR);
        l_all_states table_varchar;
    BEGIN
        l_all_states := pk_string_utils.str_split(pk_sysconfig.get_config('REPORT_DISCHARGE_NURSE', i_prof), '|');
    
        SELECT substr(concatenate(desc_interv),
                      1,
                      length(concatenate(desc_interv)) - length(nvl(i_sep, pk_icnp_constant.g_word_sep))) ||
               decode(concatenate(desc_interv), NULL, NULL, nvl(i_end, pk_icnp_constant.g_word_end))
          INTO l_result
          FROM (SELECT DISTINCT pk_translation.get_translation(i_lang, ic.code_icnp_composition) ||
                                decode(i_show_instr,
                                       pk_alert_constant.g_no,
                                       decode(i_flg_report,
                                              pk_alert_constant.g_no,
                                              pk_icnp_constant.g_word_space || pk_icnp_constant.g_word_open_brac ||
                                              pk_sysdomain.get_domain('ICNP_EPIS_INTERVENTION.FLG_STATUS',
                                                                      iei.flg_status,
                                                                      i_lang) || pk_icnp_constant.g_word_close_brac)) ||
                                decode(i_show_instr,
                                       pk_alert_constant.g_yes,
                                       pk_icnp_constant.g_word_space || pk_icnp_constant.g_word_open_brac ||
                                       get_interv_instructions(i_lang, i_prof, iei.id_icnp_epis_interv) ||
                                       pk_icnp_constant.g_word_close_brac || nvl(i_sep, pk_icnp_constant.g_word_sep),
                                       nvl(i_sep, pk_icnp_constant.g_word_sep)) desc_interv
                  FROM icnp_epis_diagnosis ied
                  JOIN icnp_epis_diag_interv iedi
                    ON ied.id_icnp_epis_diag = iedi.id_icnp_epis_diag
                  JOIN icnp_epis_intervention iei
                    ON iedi.id_icnp_epis_interv = iei.id_icnp_epis_interv
                  JOIN icnp_composition ic
                    ON iei.id_composition = ic.id_composition
                 WHERE ied.id_icnp_epis_diag = i_icnp_epis_diag
                   AND iei.id_episode_destination IS NULL
                   AND (i_flg_report = pk_alert_constant.g_no OR
                       iei.flg_status NOT IN (SELECT column_value
                                                 FROM TABLE(l_all_states)))
                   AND iei.dt_icnp_epis_interv_tstz <= nvl(i_dt_limit, iei.dt_icnp_epis_interv_tstz)
                   AND iedi.flg_status_rel IN
                       (pk_icnp_constant.g_interv_rel_reactivated, pk_icnp_constant.g_interv_rel_active));
    
        RETURN l_result;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_diag_interventions_desc;

    /**
    * Get list of associated diagnoses.
    *
    * @param i_interv       interventions identifier
    *
    * @return               associated diagnosis identifiers list
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/08/19
    */
    FUNCTION get_interv_assoc_diag(i_interv IN icnp_epis_intervention.id_icnp_epis_interv%TYPE) RETURN table_number IS
        l_diag table_number := table_number();
    BEGIN
        -- SELECT l_diag
        SELECT iedi.id_icnp_epis_diag
          BULK COLLECT
          INTO l_diag
          FROM icnp_epis_diag_interv iedi
         WHERE iedi.id_icnp_epis_interv = i_interv
           AND iedi.flg_status_rel IN (pk_icnp_constant.g_interv_rel_active, pk_icnp_constant.g_interv_rel_reactivated);
    
        RETURN l_diag;
    END get_interv_assoc_diag;

    /**
    * Get list of diagnoses for association.
    *
    * @param i_lang         language identifier
    * @param i_patient      patient identifier
    * @param i_interv       interventions identifiers list
    * @param o_diag         diagnoses cursor
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/08/09
    */
    PROCEDURE get_assoc_diag
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_interv  IN table_number,
        o_diag    OUT pk_types.cursor_type
    ) IS
    BEGIN
        OPEN o_diag FOR
            SELECT ied.id_icnp_epis_diag id_diagnosis,
                   pk_icnp.desc_composition(i_lang, ied.id_composition) desc_diagnosis
              FROM icnp_epis_diagnosis ied
             WHERE ied.id_patient = i_patient
               AND ied.flg_status = pk_icnp_constant.g_epis_diag_status_active
               AND NOT EXISTS
             (SELECT 1
                      FROM icnp_epis_diag_interv iedi
                     WHERE iedi.id_icnp_epis_diag = ied.id_icnp_epis_diag
                       AND iedi.flg_status_rel IN
                           (pk_icnp_constant.g_interv_rel_active, pk_icnp_constant.g_interv_rel_reactivated)
                       AND iedi.id_icnp_epis_interv IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                         t.column_value id_icnp_epis_interv
                                                          FROM TABLE(i_interv) t));
    
    END get_assoc_diag;

    /**
    * Associate intervention.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_patient      patient identifier
    * @param i_diag         diagnosis identifier
    * @param i_interv       intervention identifiers and instructions list
    * @param i_sysdate_tstz Current timestamp that should be used across all the 
    *                       functions invoked from this one.
    * @param o_interv_id    created icnp_epis_intervention ids
    * @param o_edi_id       created icnp_epis_diag_interv ids
    * @param o_exec_id      created icnp_interv_plan ids
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/07/20
    */
    PROCEDURE set_assoc_interv
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_patient      IN patient.id_patient%TYPE,
        i_diag         IN icnp_epis_diagnosis.id_icnp_epis_diag%TYPE,
        i_interv       IN table_table_varchar,
        i_sysdate_tstz IN TIMESTAMP WITH TIME ZONE,
        o_interv_id    OUT table_number
    ) IS
    BEGIN
        create_icnp_interv(i_lang           => i_lang,
                           i_prof           => i_prof,
                           i_episode        => i_episode,
                           i_patient        => i_patient,
                           i_diag           => NULL,
                           i_exp_res        => NULL,
                           i_notes          => NULL,
                           i_interv         => i_interv,
                           i_cur_diag       => i_diag,
                           i_sysdate_tstz   => i_sysdate_tstz,
                           i_moment_assoc   => pk_icnp_constant.g_moment_assoc_a, --ASSOC
                           i_flg_type_assoc => pk_icnp_constant.g_flg_type_assoc_i,
                           o_interv_id      => o_interv_id);
    
    END set_assoc_interv;

    /**
    * Checks the permission to execute an intervention
    *
    * @param i_interv_plan  epis intervention plan identifier
    *
    * @return               Y - can execute, N - otherwise
    *
    * @author               Sérgio Santos
    * @version               2.5.1
    * @since                2010/08/09
    */
    FUNCTION check_exec_permission(i_interv_plan IN icnp_interv_plan.id_icnp_interv_plan%TYPE) RETURN VARCHAR2 IS
        l_dt_interv_plan icnp_interv_plan.dt_plan_tstz%TYPE;
        l_epis_interv    icnp_interv_plan.id_icnp_epis_interv%TYPE;
        l_exec           VARCHAR2(1 CHAR);
    BEGIN
        -- GET DT_PLAN_TSTZ AND ID_ICNP_EPIS_INTERV
        SELECT p.dt_plan_tstz, p.id_icnp_epis_interv
          INTO l_dt_interv_plan, l_epis_interv
          FROM icnp_interv_plan p
         WHERE p.id_icnp_interv_plan = i_interv_plan;
    
        --we can only execute the oldest plan that is not executed or cancelled.
        BEGIN
            SELECT pk_alert_constant.g_no
              INTO l_exec
              FROM icnp_interv_plan iip
             WHERE iip.id_icnp_epis_interv = l_epis_interv
               AND iip.dt_plan_tstz < l_dt_interv_plan
               AND iip.flg_status IN
                   (pk_icnp_constant.g_interv_plan_status_pending, pk_icnp_constant.g_interv_plan_status_requested)
               AND rownum <= 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_exec := pk_alert_constant.g_yes;
        END;
    
        RETURN l_exec;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_constant.g_no;
    END check_exec_permission;

    /********************************************************************************************
    * Returns all terms from focus axis that are already available throught diagnosis.
    *
    * @param      i_lang    Preferred language ID for this professional
    * @param      i_prof    Object (professional ID, institution ID, software ID)
    * @param      i_patient Patient identifier (optional)
    * @param      o_folder  Icnp's focuses list
    * @param      o_error   Error
    *
    * @return                boolean type, "False" on error or "True" if success
    *
    * @raises
    *
    * @author                Pedro Lopes
    * @author                Sérgio Santos (added old terms support)
    * @version               1
    * @since                 2009/02/16
    *********************************************************************************************/
    PROCEDURE get_icnp_existing_term
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_folder  OUT pk_types.cursor_type
    ) IS
    
        l_show_old_cipe sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf => 'USE_OLD_CIPE_TERMS',
                                                                         i_prof    => i_prof);
    
        l_msg_focus sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'CPLAN_T112');
    
        l_icnp_version sys_config.value%TYPE := pk_icnp.get_icnp_version(i_lang, i_prof);
        l_flg_axis     VARCHAR2(10 CHAR) := pk_icnp.get_icnp_validation_flag(i_lang,
                                                                             i_prof,
                                                                             pk_icnp_constant.g_icnp_focus);
    
    BEGIN
    
        OPEN o_folder FOR
            SELECT *
              FROM (SELECT -1 id_term, l_msg_focus desc_focus, NULL help_term, 1 rank
                      FROM dual
                     WHERE l_show_old_cipe = pk_alert_constant.g_yes
                       AND i_patient IS NOT NULL
                    UNION ALL
                    SELECT it1.id_term,
                           pk_translation.get_translation(i_lang, it1.code_term) desc_focus,
                           pk_translation.get_translation(i_lang, it1.code_help_term) help_term,
                           2 rank
                      FROM icnp_term it1
                     WHERE EXISTS (SELECT 1
                              FROM icnp_term             it,
                                   icnp_axis             ia,
                                   icnp_axis_dcs         iad,
                                   icnp_composition_term ict,
                                   icnp_composition_hist ich,
                                   icnp_composition      ic
                             WHERE it.id_axis = ia.id_axis
                               AND ia.flg_axis = l_flg_axis
                               AND ia.id_icnp_version = l_icnp_version
                               AND it.id_term = iad.id_term
                               AND iad.id_software = i_prof.software
                               AND iad.id_institution = i_prof.institution
                               AND EXISTS (SELECT 1
                                      FROM prof_dep_clin_serv pdcs
                                     WHERE pdcs.id_professional = i_prof.id
                                       AND pdcs.id_institution = i_prof.institution
                                       AND pdcs.flg_status = pk_alert_constant.g_status_selected
                                       AND iad.id_dep_clin_serv = pdcs.id_dep_clin_serv
                                       AND rownum > 0)
                               AND it.id_term = ict.id_term
                               AND ict.id_language = i_lang
                               AND ict.flg_main_focus = pk_alert_constant.g_yes
                               AND ict.id_composition = ich.id_composition
                               AND ich.flg_most_recent = pk_alert_constant.g_yes
                               AND ich.flg_cancel = pk_alert_constant.g_no
                               AND ic.id_composition = ich.id_composition
                               AND ic.id_institution = i_prof.institution
                               AND ic.flg_available = pk_alert_constant.g_yes
                               AND it.id_term = it1.id_term))
             WHERE desc_focus IS NOT NULL
             ORDER BY rank, desc_focus;
    
    END get_icnp_existing_term;

    /********************************************************************************************
    * Returns all composition terms from focus axis that are already available throught diagnosis.
    *
    * @param      i_lang      Preferred language ID for this professional
    * @param      i_prof      Object (professional ID, institution ID, software ID)
    * @param      i_term      Focus term ID
    * @param      i_flg_child flag (Y/N to calculate has child nodes)
    * @param      o_folder    Icnp's focuses list
    * @param      o_error     Error
    *
    * @return                boolean type, "False" on error or "True" if success
    *
    * @raises
    *
    * @author                Pedro Lopes
    * @author                Sérgio Santos (added old terms support)
    * @version               1
    * @since                 2009/02/16
    *********************************************************************************************/
    PROCEDURE get_icnp_composition_by_term
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_term      IN table_number,
        i_flg_child IN VARCHAR2,
        i_patient   IN patient.id_patient%TYPE,
        o_folder    OUT pk_types.cursor_type
    ) IS
        l_gender patient.gender%TYPE;
    BEGIN
    
        BEGIN
            SELECT gender
              INTO l_gender
              FROM patient
             WHERE id_patient = i_patient;
        EXCEPTION
            WHEN no_data_found THEN
                l_gender := NULL;
        END;
    
        DELETE tbl_temp;
    
        IF i_term.count = 1
        THEN
            IF i_term(1) = -1
            THEN
                OPEN o_folder FOR
                    SELECT *
                      FROM (SELECT id_composition,
                                   id_composition id_composition_hist,
                                   pk_translation.get_translation(i_lang, code_icnp_composition) short_desc,
                                   has_child
                              FROM (SELECT DISTINCT ic.id_composition,
                                                    ic.flg_repeat,
                                                    ic.flg_solved,
                                                    ic.code_icnp_composition,
                                                    (SELECT decode(COUNT(*),
                                                                   0,
                                                                   pk_alert_constant.g_no,
                                                                   pk_alert_constant.g_yes)
                                                       FROM icnp_predefined_action ipa, icnp_composition ic1
                                                      WHERE ipa.id_composition_parent = ic.id_composition
                                                        AND ipa.flg_available = pk_alert_constant.g_yes
                                                        AND nvl(ipa.id_institution, 0) IN (0, i_prof.institution)
                                                        AND ipa.id_software IN (0, i_prof.software)
                                                        AND ipa.id_composition = ic1.id_composition
                                                        AND ic1.id_software = i_prof.software
                                                        AND ic1.flg_type = pk_icnp_constant.g_axis_action
                                                        AND ic1.flg_available = pk_alert_constant.g_yes
                                                        AND ic1.id_institution = i_prof.institution) has_child
                                      FROM icnp_composition ic
                                     WHERE rownum > 0
                                       AND ic.id_institution = i_prof.institution
                                       AND ic.flg_available = pk_alert_constant.g_yes
                                       AND ((i_patient IS NOT NULL AND
                                           ic.flg_gender IN (l_gender, pk_icnp_constant.g_composition_gender_both)) OR
                                           i_patient IS NULL)
                                       AND ic.flg_type = 'D'
                                       AND EXISTS (SELECT 1
                                              FROM dep_clin_serv  dcs,
                                                   department     d,
                                                   dept           dp,
                                                   software_dept  sd,
                                                   icnp_compo_dcs icd
                                             WHERE d.id_department = dcs.id_department
                                               AND icd.id_dep_clin_serv = dcs.id_dep_clin_serv
                                               AND icd.id_composition = ic.id_composition
                                               AND d.id_institution = i_prof.institution
                                               AND dp.id_dept = d.id_dept
                                               AND sd.id_dept = dp.id_dept
                                               AND sd.id_software = i_prof.software))
                             ORDER BY short_desc)
                     WHERE short_desc IS NOT NULL;
            
                RETURN;
            END IF;
        END IF;
    
        IF (i_term IS NULL OR i_term.count = 0)
        THEN
            IF i_flg_child = pk_alert_constant.g_no
            THEN
                OPEN o_folder FOR
                    SELECT DISTINCT ic.id_composition,
                                    ich.id_composition_hist,
                                    pk_translation.get_translation(i_lang, ic.code_icnp_composition) AS short_desc,
                                    'X' AS has_child
                      FROM icnp_composition ic, icnp_composition_hist ich, icnp_composition_term ict --, translation t
                     WHERE ic.id_composition = ich.id_composition
                       AND ic.flg_type = pk_icnp_constant.g_cp_st_compo_type_diag
                       AND ic.flg_available = pk_alert_constant.g_yes
                       AND ich.flg_most_recent = pk_alert_constant.g_yes
                       AND ic.id_composition = ict.id_composition
                       AND ich.flg_cancel = pk_alert_constant.g_no
                       AND ic.id_software = i_prof.software
                       AND ict.flg_main_focus = pk_alert_constant.g_yes
                       AND ic.id_institution = i_prof.institution
                     ORDER BY 3;
            
                RETURN;
            ELSE
                --get diagnosis
                INSERT INTO tbl_temp
                    (num_1, num_2, vc_1)
                    (SELECT DISTINCT ic.id_composition,
                                     ich.id_composition_hist,
                                     pk_translation.get_translation(i_lang, ic.code_icnp_composition) AS short_desc
                       FROM icnp_composition ic, icnp_composition_hist ich, icnp_composition_term ict --, translation t
                      WHERE ic.id_composition = ich.id_composition
                        AND ic.flg_available = pk_alert_constant.g_yes
                        AND ic.flg_type = pk_icnp_constant.g_cp_st_compo_type_diag
                        AND ich.flg_most_recent = pk_alert_constant.g_yes
                        AND ic.id_composition = ict.id_composition
                        AND ic.id_software = i_prof.software
                        AND ich.flg_cancel = pk_alert_constant.g_no
                        AND ic.id_institution = i_prof.institution
                        AND ict.flg_main_focus = pk_alert_constant.g_yes);
            END IF;
        ELSE
            --get diagnosis
            FORALL k IN i_term.first .. i_term.last
                INSERT INTO tbl_temp
                    (num_1, num_2, vc_1, vc_2, vc_3, num_4, vc_4)
                    (SELECT DISTINCT (ic.id_composition),
                                     ich.id_composition_hist,
                                     pk_translation.get_translation(i_lang, ic.code_icnp_composition) AS short_desc,
                                     ich.flg_cancel,
                                     pk_sysdomain.get_domain('ICNP_COMPOSITION.FLG_TYPE', ic.flg_type, i_lang) desc_type,
                                     (SELECT MAX(it.rank)
                                        FROM icnp_term it, icnp_composition_term ict
                                       WHERE it.id_term = ict.id_term
                                         AND ict.id_composition = ic.id_composition
                                         AND it.rank IS NOT NULL) rank,
                                     pk_icnp.get_compo_desc_aux(i_lang, ic.id_composition) AS compo_desc
                       FROM icnp_composition_term ict2, icnp_composition ic, icnp_composition_hist ich
                      WHERE ich.id_composition = ic.id_composition
                        AND ict2.id_composition = ic.id_composition
                        AND ict2.id_term = i_term(k)
                        AND ic.id_institution = i_prof.institution
                        AND ic.id_software = i_prof.software
                        AND ic.flg_available = pk_alert_constant.g_yes
                        AND ict2.flg_main_focus = pk_alert_constant.g_yes
                        AND ich.flg_most_recent = pk_alert_constant.g_yes
                        AND ic.flg_type = pk_icnp_constant.g_cp_st_compo_type_diag
                           --------------------------
                        AND ic.id_software IN (0, i_prof.software)
                           --------------------------
                        AND ich.flg_cancel = pk_alert_constant.g_no);
        
        END IF;
    
        -- UPDATE INTERVENTION FLG_CHILD
        UPDATE tbl_temp tt
           SET tt.num_3 =
               (SELECT /*+ use_nl(ipa ic ipah)*/
                 COUNT(*)
                  FROM icnp_predefined_action_hist ipah, icnp_predefined_action ipa, icnp_composition ic
                 WHERE ipa.id_predefined_action = ipah.id_predefined_action
                   AND ipa.id_composition = ic.id_composition
                   AND ic.flg_type = pk_icnp_constant.g_axis_action
                   AND ic.flg_available = pk_alert_constant.g_yes
                   AND ipah.flg_most_recent = pk_alert_constant.g_yes
                   AND ipah.flg_cancel = pk_alert_constant.g_no
                   AND ic.id_institution = i_prof.institution
                   AND ic.id_software = i_prof.software
                   AND EXISTS (SELECT 1
                          FROM icnp_composition_hist
                         WHERE id_composition_hist = tt.num_2
                           AND id_composition = ipa.id_composition_parent
                           AND rownum > 0))
         WHERE tt.num_1 IS NOT NULL;
    
        --open temporary table for output
        OPEN o_folder FOR
            SELECT tt.num_1 AS id_composition,
                   tt.num_2 AS id_composition_hist,
                   tt.vc_1 AS short_desc,
                   decode(nvl(tt.num_3, 0), 0, 'N', 'Y') AS has_child,
                   tt.vc_2 AS flg_cancel,
                   tt.vc_3 AS desc_type,
                   tt.num_4 rank,
                   tt.vc_4 compo_desc
              FROM tbl_temp tt
             WHERE tt.vc_1 IS NOT NULL
               AND tt.vc_2 <> pk_alert_constant.g_yes
             ORDER BY compo_desc, rank;
    
    END get_icnp_composition_by_term;

    /**
    * Returns the flg_status of the prior id_icnp_epis_intervention_hist provided.
    *
    * @param i_id_icnp_epis_interv   icnp intervention id
    * @param id_interv_hist          Base interv_hist
    *
    * @return               flg_status of icnp intervention previous that was provided
    *
    * @author               Sérgio Santos
    * @version               2.5.1
    * @since                2010/09/20
    */
    FUNCTION get_interv_prior_status
    (
        i_id_icnp_epis_interv icnp_epis_intervention.id_icnp_epis_interv%TYPE,
        i_id_interv_hist      icnp_epis_intervention_hist.id_icnp_epis_interv_hist%TYPE
    ) RETURN icnp_epis_intervention_hist.flg_status%TYPE IS
        l_previous_status icnp_epis_intervention_hist.flg_status%TYPE;
    
        l_hist_date icnp_epis_intervention_hist.dt_last_update%TYPE;
    BEGIN
        IF i_id_interv_hist IS NULL
        THEN
            l_hist_date := current_timestamp;
        ELSE
            SELECT i.dt_created_hist
              INTO l_hist_date
              FROM icnp_epis_intervention_hist i
             WHERE i.id_icnp_epis_interv_hist = i_id_interv_hist
               AND i.id_icnp_epis_interv = i_id_icnp_epis_interv;
        END IF;
    
        /*SELECT t.flg_status
         INTO l_previous_status
         FROM (SELECT i.flg_status, i.dt_last_update
                 FROM icnp_epis_intervention_hist i
                WHERE i.dt_last_update < l_hist_date
                  AND i.id_icnp_epis_interv = i_id_icnp_epis_interv
                ORDER BY i.dt_last_update DESC) t
        WHERE rownum <= 1;*/
    
        SELECT t.flg_status
          INTO l_previous_status
          FROM (SELECT i.flg_status, i.dt_created_hist
                  FROM icnp_epis_intervention_hist i
                 WHERE i.dt_created_hist < l_hist_date
                   AND i.id_icnp_epis_interv = i_id_icnp_epis_interv
                 ORDER BY i.dt_created_hist DESC) t
         WHERE rownum <= 1;
    
        RETURN l_previous_status;
    END;

    /********************************************************************************************
    * Returns ICNP's intervention value
    *
    * @param      i_patient       Patient ID
    * @param      i_dt_vital_sign_read
    *
    * @return                boolean type, "False" on error or "True" if success
    *
    * @author                Nuno Neves
    * @version               2.5.1.3
    * @since                 2010/09/01
    *********************************************************************************************/
    FUNCTION get_interv_hist_value
    (
        i_patient              IN icnp_epis_intervention.id_patient%TYPE,
        i_dt_vital_sign_read   IN vital_sign_read.dt_vital_sign_read_tstz%TYPE,
        i_id_vital_sign        IN vital_sign_read.id_vital_sign%TYPE,
        i_id_vital_sign_parent IN vital_sign_relation.id_vital_sign_parent%TYPE
    ) RETURN VARCHAR2 IS
        l_value   VARCHAR2(200);
        l_v_rank1 VARCHAR2(50);
        l_v_rank2 VARCHAR2(50);
    BEGIN
    
        SELECT vs2.value
          INTO l_v_rank1
          FROM vital_sign_read vs2, vital_sign_relation vsr2
         WHERE vs2.id_patient = i_patient
           AND vsr2.id_vital_sign_parent = i_id_vital_sign_parent
           AND vs2.dt_vital_sign_read_tstz = i_dt_vital_sign_read
           AND vs2.id_vital_sign = vsr2.id_vital_sign_detail
           AND vsr2.relation_domain != pk_alert_constant.g_vs_rel_percentile
           AND vs2.id_vital_sign = (SELECT id_vital_sign_detail
                                      FROM vital_sign_relation
                                     WHERE id_vital_sign_parent = vsr2.id_vital_sign_parent
                                       AND relation_domain != pk_alert_constant.g_vs_rel_percentile
                                       AND rank = 1);
    
        SELECT vs2.value
          INTO l_v_rank2
          FROM vital_sign_read vs2, vital_sign_relation vsr2
         WHERE vs2.id_patient = i_patient
           AND vsr2.id_vital_sign_parent = i_id_vital_sign_parent
           AND vs2.dt_vital_sign_read_tstz = i_dt_vital_sign_read
           AND vs2.id_vital_sign = vsr2.id_vital_sign_detail
           AND vsr2.relation_domain != pk_alert_constant.g_vs_rel_percentile
           AND vs2.id_vital_sign = (SELECT id_vital_sign_detail
                                      FROM vital_sign_relation
                                     WHERE id_vital_sign_parent = vsr2.id_vital_sign_parent
                                       AND relation_domain != pk_alert_constant.g_vs_rel_percentile
                                       AND rank = 2);
    
        l_value := CASE
                       WHEN i_id_vital_sign = 6 THEN
                        l_v_rank1
                       WHEN i_id_vital_sign = 7 THEN
                        l_v_rank2
                       ELSE
                        l_v_rank1 || '/' || l_v_rank2
                   END;
    
        RETURN l_value;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_constant.g_no;
            pk_alert_exceptions.reset_error_state;
        
    END get_interv_hist_value;

    /********************************************************************************************
    * Gets the associated diagnosis of a list of interventions
    *
    * @param      i_lang               Preferred language ID for this professional
    * @param      i_epis_interv        Intervention id
    * @param      o_error              Error object
    *
    * @return               varchar2 with associated diagnosis
    *
    * @raises
    *
    * @author                Sérgio Santos
    * @version               2.5.1
    * @since                 2010/08/31
    *********************************************************************************************/
    FUNCTION get_interv_assoc_diag_desc
    (
        i_lang        IN language.id_language%TYPE,
        i_epis_interv IN icnp_epis_intervention.id_icnp_epis_interv%TYPE
    ) RETURN VARCHAR2 IS
        l_diag VARCHAR2(32767);
    BEGIN
        --obter a descrição
        SELECT substr(concatenate(desc_diag), 1, length(concatenate(desc_diag)) - length(pk_icnp_constant.g_word_sep)) ||
               decode(concatenate(desc_diag), NULL, NULL, pk_icnp_constant.g_word_end)
          INTO l_diag
          FROM (SELECT DISTINCT pk_translation.get_translation(i_lang, ic2.code_icnp_composition) ||
                                pk_icnp_constant.g_word_sep desc_diag
                  FROM icnp_epis_diagnosis ied
                  JOIN icnp_epis_diag_interv iedi
                    ON iedi.id_icnp_epis_diag = ied.id_icnp_epis_diag
                  JOIN icnp_epis_intervention iei
                    ON iei.id_icnp_epis_interv = iedi.id_icnp_epis_interv
                  JOIN icnp_composition ic2
                    ON ic2.id_composition = ied.id_composition
                 WHERE iei.id_icnp_epis_interv = i_epis_interv
                 ORDER BY desc_diag);
    
        RETURN l_diag;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_interv_assoc_diag_desc;

    --------------------------------------------------------------------------------
    -- PUBLIC METHODS
    --------------------------------------------------------------------------------

    /**
    * Checks if diagnoses for association are available.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_interv       interventions identifiers list
    * @param o_flg_show     shows warning message: Y - yes, N - No
    * @param o_msg          message text
    * @param o_msg_title    message title
    * @param o_button       buttons to show: N-No, R-Read, C-Confirmed
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/08/18
    */
    PROCEDURE check_assoc_diag
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_interv    IN table_number,
        o_flg_show  OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_button    OUT VARCHAR2
    ) IS
        g_button_read CONSTANT VARCHAR2(1 CHAR) := 'R';
        l_count PLS_INTEGER;
    BEGIN
        SELECT COUNT(*)
          INTO l_count
          FROM icnp_epis_diagnosis ied
         WHERE ied.id_patient = i_patient
           AND ied.flg_status = pk_icnp_constant.g_epis_diag_status_active
           AND NOT EXISTS
         (SELECT 1
                  FROM icnp_epis_diag_interv iedi
                 WHERE iedi.id_icnp_epis_diag = ied.id_icnp_epis_diag
                   AND iedi.flg_status_rel IN
                       (pk_icnp_constant.g_interv_rel_active, pk_icnp_constant.g_interv_rel_reactivated) ---
                   AND iedi.id_icnp_epis_interv IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                     t.column_value id_icnp_epis_interv
                                                      FROM TABLE(i_interv) t));
    
        IF l_count = 0
        THEN
            o_flg_show  := pk_alert_constant.g_yes;
            o_msg_title := get_message_and_cache(i_lang, i_prof, pk_icnp_constant.mcodet_warning, l_messages_col);
            o_msg       := get_message_and_cache(i_lang,
                                                 i_prof,
                                                 pk_icnp_constant.mcodet_intervs_already_assoc,
                                                 l_messages_col);
            o_button    := g_button_read;
        END IF;
    
    END check_assoc_diag;

    /**
    * Checks selected ICNP diagnoses and interventions for conflicts. We can't
    * have request diagnosis that are still active or suspended and interventions
    * that are still ongoing, requested or suspended for the patient.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_diag         selected diagnosis list
    * @param i_interv       selected interventions list
    * @param o_warn         conflict warning
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/08/02
    */
    PROCEDURE check_epis_conflict
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_diag       IN table_number,
        i_interv     IN table_number,
        i_flg_sug    IN VARCHAR2,
        o_warn       OUT table_varchar,
        o_desc_instr OUT pk_types.cursor_type
        
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'check_epis_conflict';
        l_compo               table_number := table_number();
        l_status              table_varchar := table_varchar();
        l_title               sys_message.desc_message%TYPE;
        l_message             sys_message.desc_message%TYPE;
        l_buttons             sys_message.desc_message%TYPE;
        l_id_icnp_epis_interv table_number := table_number();
        l_exist_sug           NUMBER;
        l_code_sys_config     sys_config.id_sys_config%TYPE := 'ICNP_CARE_PLAN_SCOPE';
        l_care_plan_scope     VARCHAR2(1);
        l_episodes            table_number;
    
        -- Diagnosis still active or suspended for the patient
        CURSOR c_diag IS
            SELECT ied.id_composition, ied.flg_status
              FROM icnp_epis_diagnosis ied
             WHERE ied.id_episode = i_episode
               AND ied.flg_status IN
                   (pk_icnp_constant.g_epis_diag_status_active, pk_icnp_constant.g_epis_diag_status_suspended)
               AND ied.id_composition IN (SELECT /*+opt_estimate(table t rows=1)*/
                                           t.column_value id_composition
                                            FROM TABLE(i_diag) t)
            UNION ALL
            SELECT ied.id_composition, ied.flg_status
              FROM icnp_epis_diagnosis ied
             WHERE ied.id_episode IN (SELECT /*+opt_estimate(table t rows=1)*/
                                       t.column_value
                                        FROM TABLE(l_episodes) t)
               AND ied.flg_status IN
                   (pk_icnp_constant.g_epis_diag_status_active, pk_icnp_constant.g_epis_diag_status_suspended)
               AND ied.id_composition IN (SELECT /*+opt_estimate(table t rows=1)*/
                                           t.column_value id_composition
                                            FROM TABLE(i_diag) t);
    
        -- Interventions still ongoing, requested or suspended for the patient
        CURSOR c_interv IS
            SELECT iei.id_composition, iei.flg_status, iei.id_icnp_epis_interv
              FROM icnp_epis_intervention iei
             WHERE iei.id_episode = i_episode
               AND iei.id_episode_destination IS NULL
               AND iei.flg_status IN (pk_icnp_constant.g_epis_interv_status_ongoing,
                                      pk_icnp_constant.g_epis_interv_status_requested,
                                      pk_icnp_constant.g_epis_interv_status_suspended)
               AND iei.id_composition IN (SELECT /*+opt_estimate(table t rows=1)*/
                                           t.column_value id_composition
                                            FROM TABLE(i_interv) t)
            UNION ALL
            SELECT iei.id_composition, iei.flg_status, iei.id_icnp_epis_interv
              FROM icnp_epis_intervention iei
             WHERE iei.id_episode IN (SELECT /*+opt_estimate(table t rows=1)*/
                                       t.column_value
                                        FROM TABLE(l_episodes) t)
               AND iei.id_episode_destination IS NULL
               AND iei.flg_status IN (pk_icnp_constant.g_epis_interv_status_ongoing,
                                      pk_icnp_constant.g_epis_interv_status_requested,
                                      pk_icnp_constant.g_epis_interv_status_suspended)
               AND iei.id_composition IN (SELECT /*+opt_estimate(table t rows=1)*/
                                           t.column_value id_composition
                                            FROM TABLE(i_interv) t);
    BEGIN
        -- debug input
        log_debug('i_diag: ' || pk_utils.to_string(i_input => i_diag), c_func_name);
    
        --(P- Patient , E-Episode, V-VISIT)                                        
        l_care_plan_scope := pk_sysconfig.get_config(i_code_cf => l_code_sys_config, i_prof => i_prof);
    
        CASE l_care_plan_scope
            WHEN g_icnp_care_plan_e THEN
                l_episodes := NULL;
            WHEN g_icnp_care_plan_p THEN
                SELECT e.id_episode
                  BULK COLLECT
                  INTO l_episodes
                  FROM episode e
                 WHERE e.id_patient = i_patient
                   AND e.id_episode <> i_episode;
            WHEN g_icnp_care_plan_v THEN
                SELECT e.id_episode
                  BULK COLLECT
                  INTO l_episodes
                  FROM episode e
                 WHERE e.id_visit = pk_episode.get_id_visit(i_episode)
                   AND e.id_episode <> i_episode;
        END CASE;
    
        IF i_diag IS NOT NULL
           AND i_diag.count > 0
        THEN
            -- check if selected diagnosis are active for patient
            OPEN c_diag;
            FETCH c_diag BULK COLLECT
                INTO l_compo, l_status;
            CLOSE c_diag;
        
            IF l_compo IS NOT NULL
               AND l_compo.count > 0
            THEN
                -- build warning message
                l_title   := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'COMMON_T013');
                l_message := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'CPLAN_T089');
                l_buttons := 'R';
            
                -- LOOP warning message
                FOR i IN l_compo.first .. l_compo.last
                LOOP
                    l_message := l_message || chr(10) || '- ' ||
                                 pk_icnp.desc_composition(i_lang => i_lang, i_composition => l_compo(i)) ||
                                 pk_icnp_constant.g_word_space || pk_icnp_constant.g_word_open_brac ||
                                 pk_sysdomain.get_domain(i_code_dom => pk_icnp_constant.g_domain_epis_diag_status,
                                                         i_val      => l_status(i),
                                                         i_lang     => i_lang) || pk_icnp_constant.g_word_close_brac;
                END LOOP;
            
                o_warn := table_varchar(l_title, l_message, l_buttons);
                pk_types.open_my_cursor(o_desc_instr);
                RETURN;
            END IF;
        END IF;
    
        IF i_interv IS NOT NULL
           AND i_interv.count > 0
        THEN
            -- check if selected interventions are active for patient
            OPEN c_interv;
            FETCH c_interv BULK COLLECT
                INTO l_compo, l_status, l_id_icnp_epis_interv;
            CLOSE c_interv;
        
            IF l_compo IS NOT NULL
               AND l_compo.count > 0
            THEN
            
                IF i_flg_sug = pk_alert_constant.g_yes
                THEN
                
                    -- build warning message
                    l_title   := pk_message.get_message(i_lang      => i_lang,
                                                        i_prof      => i_prof,
                                                        i_code_mess => 'COMMON_T013');
                    l_message := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'CPLAN_T090');
                    l_buttons := 'NC';
                ELSE
                    BEGIN
                        SELECT 1
                          INTO l_exist_sug
                          FROM (SELECT 1
                                  FROM icnp_suggest_interv s
                                 WHERE s.id_composition IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                             t.column_value
                                                              FROM TABLE(i_interv) t)
                                   AND s.id_episode = i_episode
                                   AND s.flg_status = pk_icnp_constant.g_sug_interv_status_accepted
                                UNION ALL
                                SELECT 1
                                  FROM icnp_suggest_interv s
                                 WHERE s.id_composition IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                             t.column_value
                                                              FROM TABLE(i_interv) t)
                                   AND s.id_episode IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                         t.column_value
                                                          FROM TABLE(l_episodes) t)
                                   AND s.flg_status = pk_icnp_constant.g_sug_interv_status_accepted)
                         WHERE rownum = 1;
                    EXCEPTION
                        WHEN no_data_found THEN
                            l_exist_sug := 0;
                    END;
                
                    IF l_exist_sug = 1
                    THEN
                        -- build warning message
                        l_title   := pk_message.get_message(i_lang      => i_lang,
                                                            i_prof      => i_prof,
                                                            i_code_mess => 'COMMON_T013');
                        l_message := pk_message.get_message(i_lang      => i_lang,
                                                            i_prof      => i_prof,
                                                            i_code_mess => 'CPLAN_T090');
                        l_buttons := 'NC';
                    ELSE
                        -- build warning message
                        l_title   := pk_message.get_message(i_lang      => i_lang,
                                                            i_prof      => i_prof,
                                                            i_code_mess => 'COMMON_T013');
                        l_message := pk_message.get_message(i_lang      => i_lang,
                                                            i_prof      => i_prof,
                                                            i_code_mess => 'CPLAN_T090');
                        l_buttons := 'RNC';
                    END IF;
                END IF;
            
                -- LOOP warning message
                FOR i IN l_compo.first .. l_compo.last
                LOOP
                    l_message := l_message || chr(10) || '- ' ||
                                 pk_icnp.desc_composition(i_lang => i_lang, i_composition => l_compo(i)) ||
                                 pk_icnp_constant.g_word_space || pk_icnp_constant.g_word_open_brac ||
                                 pk_sysdomain.get_domain(i_code_dom => pk_icnp_constant.g_domain_epis_interv_status,
                                                         i_val      => l_status(i),
                                                         i_lang     => i_lang) || pk_icnp_constant.g_word_close_brac;
                END LOOP;
                IF i_flg_sug = pk_alert_constant.g_yes
                THEN
                    l_message := l_message || chr(10) || chr(10) ||
                                 pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'CPLAN_T108');
                ELSE
                    l_message := l_message || chr(10) || chr(10);
                END IF;
                o_warn := table_varchar(l_title, l_message, l_buttons);
            
                --build o_desc_instr
                OPEN o_desc_instr FOR
                    SELECT iei.id_icnp_epis_interv,
                           iei.id_composition,
                           pk_icnp.desc_composition(i_lang, iei.id_composition) desc_interv,
                           get_interv_instructions(i_lang, i_prof, iei.id_icnp_epis_interv) desc_instr
                      FROM icnp_epis_intervention iei
                     WHERE iei.id_icnp_epis_interv IN
                           (SELECT /*+opt_estimate(table t rows=1)*/
                             *
                              FROM TABLE(l_id_icnp_epis_interv) t);
            
                RETURN;
            ELSE
                pk_types.open_my_cursor(o_desc_instr);
            END IF;
        ELSE
            pk_types.open_my_cursor(o_desc_instr);
        END IF;
    
    END check_epis_conflict;

    /**
    * Checks the state of the therapeutic attitude 
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_icnp_sug_interv      nurse intervention 
    
    * @param o_flg_show    Indica se deve ou não mostrar mensagem de aviso ao criar nova avaliação
    * @param o_msg_result  Mensagem de aviso a ser mostrada
    * @param o_title       Título da mensagem de aviso
    * @param o_button      Botões a mostrar no aviso
    */
    PROCEDURE check_therapeutic_status
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_icnp_epis_interv IN table_number,
        o_flg_show            OUT VARCHAR2,
        o_msg_result          OUT VARCHAR2,
        o_title               OUT VARCHAR2,
        o_button              OUT VARCHAR2
    ) IS
        l_status VARCHAR2(10) := pk_alert_constant.g_yes;
        l_desc   VARCHAR2(1000 CHAR);
        CURSOR c_therapeutic IS
            SELECT isi.id_icnp_epis_interv, isi.id_req, isi.id_task_type
              FROM icnp_suggest_interv isi
             WHERE isi.id_icnp_epis_interv IN (SELECT column_value
                                                 FROM TABLE(i_id_icnp_epis_interv));
    BEGIN
        FOR elem IN c_therapeutic
        LOOP
            l_status := CASE pk_icnp_suggestion.get_sugg_task_status(i_lang         => i_lang,
                                                                 i_prof         => i_prof,
                                                                 i_request_id   => elem.id_req,
                                                                 i_task_type_id => elem.id_task_type)
                            WHEN pk_alert_constant.g_no THEN
                             pk_alert_constant.g_no
                            ELSE
                             l_status
                        END;
        
            SELECT l_desc || chr(10) || pk_icnp.get_compo_desc(i_lang, id_composition)
              INTO l_desc
              FROM icnp_epis_intervention
             WHERE id_icnp_epis_interv = elem.id_icnp_epis_interv;
        
        END LOOP;
    
        IF l_status = pk_alert_constant.g_no
        THEN
            o_flg_show   := pk_alert_constant.g_yes;
            o_title      := pk_message.get_message(i_lang, 'COMMON_T013');
            o_msg_result := pk_message.get_message(i_lang, 'CPLAN_M003');
            o_button     := 'NC';
        ELSE
            o_flg_show := 'N';
        END IF;
    
    END check_therapeutic_status;

    /**
     * Converts a raw data record sent by ux, with the data of one intervention and 
     * its associated diagnose (when invoking the method to create a new standard 
     * plan), into a typed record.
     * 
     * @param i_values Array with the values for one record. Each position corresponds
     *                 to a predfined type of information.
     * 
     * @return Typed record with the data of one intervention and its associated 
     *         diagnose.
     *
     * @author Luis Oliveira
     * @version 1.0
     * @since 28/Jun/2011
    */
    FUNCTION populate_create_cplan_rec(i_values table_varchar) RETURN data_ux_ccp_rec IS
        -----
        -- Constants
    
        -- Function name
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'populate_create_cplan_rec';
        -- Indexes of the fields stored in table_varchar
        c_idx_ccp_compo_interv_id CONSTANT PLS_INTEGER := 1;
        c_idx_ccp_compo_diag_id   CONSTANT PLS_INTEGER := 2;
        c_idx_ccp_flg_time        CONSTANT PLS_INTEGER := 3;
        c_idx_ccp_recurr_id       CONSTANT PLS_INTEGER := 4;
        c_idx_ccp_flg_prn         CONSTANT PLS_INTEGER := 5;
        c_idx_ccp_prn_notes       CONSTANT PLS_INTEGER := 6;
    
        -----
        -- Variables
        l_data_ux_rec data_ux_ccp_rec;
    
    BEGIN
        log_debug(c_func_name || '()', c_func_name);
    
        -- Load the raw data sent by ux into a typed record
        l_data_ux_rec.id_composition_interv := to_number(i_values(c_idx_ccp_compo_interv_id));
        l_data_ux_rec.id_composition_diag   := to_number(i_values(c_idx_ccp_compo_diag_id));
        l_data_ux_rec.flg_time              := i_values(c_idx_ccp_flg_time);
        l_data_ux_rec.id_order_recurr_plan  := to_number(i_values(c_idx_ccp_recurr_id));
        l_data_ux_rec.flg_prn               := i_values(c_idx_ccp_flg_prn);
        l_data_ux_rec.prn_notes             := i_values(c_idx_ccp_prn_notes);
    
        RETURN l_data_ux_rec;
    END;

    /********************************************************************************************
    * Creates or updates ICNP care plans (Configurations Area)
    *
    * @param i_lang            Preferred language ID for this professional
    * @param i_prof            Object (professional ID, institution ID, software ID)
    * @param i_cplan           Care plan ID (null value creates a cplan)
    * @param i_name            Care plan name
    * @param i_notes           Care plan notes
    * @param i_diags           Diagnosis
    * @param i_results         Diagnosis expected results
    * @param i_intervs         Interventions (intervention and instructions) Interventions (intervention and instructions) [[(1)ID_COMPOSITION, (2)ID_COMPOSITION_PARENT, (3)TAKE_TYPE, (4)NUM_TAKE, (5)INTERVAL, (6)INTERVAL_UNIT, (7)DURATION, (8)DURATION_UNIT],...]
    * @param i_dep_clin_serv   associated specialties list
    * @param i_soft            associated softwares list
    * @param i_sysdate_tstz    Current timestamp that should be used across all the 
    *                          functions invoked from this one.
    *
    * @return                  boolean type, "False" on error or "True" if success 
    *
    * @author                  Sérgio Santos
    * @version                 2.5.1 
    * @since                   2010/05/12
    *                         
    *********************************************************************************************/
    PROCEDURE create_or_update_icnp_cplan
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_cplan         IN icnp_cplan_stand.id_cplan_stand%TYPE,
        i_name          IN VARCHAR2,
        i_notes         IN VARCHAR2,
        i_diags         IN table_number,
        i_results       IN table_number,
        i_intervs       IN table_table_varchar,
        i_dep_clin_serv IN table_number,
        i_soft          IN table_number,
        i_sysdate_tstz  IN TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'create_or_update_icnp_cplan';
        -- Typed i_interv record
        l_data_ux_rec data_ux_ccp_rec;
        -- Associative array to control the recurrences that were already made definitive
        l_recurr_processed_coll   t_order_recurr_coll;
        l_order_recurr_rec        t_order_recurr_rec;
        l_recurr_definit_ids_coll table_number := table_number();
        -- Data structures related with icnp_cplan_stand
        l_cplan_key icnp_cplan_stand.id_cplan_stand%TYPE;
        l_rowids    table_varchar;
        -- Data structures related with icnp_cplan_stand_compo
        l_flg_type            icnp_cplan_stand_compo.flg_type%TYPE;
        l_next_cplan_compo_id icnp_cplan_stand_compo.id_cplan_stand_compo%TYPE;
        l_exp_res             icnp_cplan_stand_compo.id_composition%TYPE;
        -- Aux variables
        l_found VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
        -- Data structures related with error handling
        l_error t_error_out;
    
        l_processed_plan t_processed_plan;
    
    BEGIN
        l_cplan_key := nvl(i_cplan, ts_icnp_cplan_stand.next_key);
    
        IF i_cplan IS NULL
        THEN
            --inserir plano
            ts_icnp_cplan_stand.ins(id_cplan_stand_in     => l_cplan_key,
                                    name_in               => i_name,
                                    notes_in              => i_notes,
                                    flg_status_in         => pk_icnp_constant.g_icnp_cplan_status_active,
                                    dt_care_plan_stand_in => i_sysdate_tstz,
                                    id_professional_in    => i_prof.id,
                                    id_institution_in     => i_prof.institution,
                                    rows_out              => l_rowids);
        
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'ICNP_CPLAN_STAND',
                                          i_rowids     => l_rowids,
                                          o_error      => l_error);
        ELSE
            --actualizar plano
            ts_icnp_cplan_stand.upd(id_cplan_stand_in      => l_cplan_key,
                                    name_in                => i_name,
                                    name_nin               => FALSE,
                                    notes_in               => i_notes,
                                    notes_nin              => FALSE,
                                    flg_status_in          => pk_icnp_constant.g_icnp_cplan_status_active,
                                    flg_status_nin         => FALSE,
                                    dt_care_plan_stand_in  => i_sysdate_tstz,
                                    dt_care_plan_stand_nin => FALSE,
                                    id_professional_in     => i_prof.id,
                                    id_professional_nin    => FALSE,
                                    id_institution_in      => i_prof.institution,
                                    id_institution_nin     => FALSE,
                                    rows_out               => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'ICNP_CPLAN_STAND',
                                          i_rowids     => l_rowids,
                                          o_error      => l_error);
        END IF;
    
        IF i_cplan IS NOT NULL
        THEN
            --desactualizar todos os registos aplicáveis ao plano
            l_rowids := table_varchar();
            ts_icnp_cplan_stand_compo.upd(flg_status_in  => pk_icnp_constant.g_cp_st_compo_status_inactive,
                                          flg_status_nin => FALSE,
                                          where_in       => ' id_cplan_stand = ' || l_cplan_key,
                                          rows_out       => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'ICNP_CPLAN_STAND_COMPO',
                                          i_rowids     => l_rowids,
                                          o_error      => l_error);
        END IF;
    
        --actualizar diagnosticos e resultados esperados
        FOR i IN 1 .. i_results.count
        LOOP
            l_rowids  := table_varchar();
            l_exp_res := nvl(i_results(i), g_compo_no_exp_result);
        
            BEGIN
                SELECT pk_alert_constant.g_yes
                  INTO l_found
                  FROM icnp_cplan_stand_compo i
                 WHERE i.id_cplan_stand = l_cplan_key
                   AND i.id_composition = l_exp_res
                   AND i.id_composition_parent = i_diags(i)
                   AND i.flg_compo_type = pk_icnp_constant.g_cp_st_compo_type_res;
            EXCEPTION
                WHEN no_data_found THEN
                    l_found := pk_alert_constant.g_no;
            END;
        
            IF l_found = pk_alert_constant.g_yes
            THEN
                ts_icnp_cplan_stand_compo.upd(flg_status_in  => pk_icnp_constant.g_cp_st_compo_status_active,
                                              flg_status_nin => FALSE,
                                              where_in       => ' ID_CPLAN_STAND=' || l_cplan_key ||
                                                                ' AND ID_COMPOSITION=' || l_exp_res ||
                                                                ' AND ID_COMPOSITION_PARENT=' || i_diags(i),
                                              rows_out       => l_rowids);
            
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'ICNP_CPLAN_STAND_COMPO',
                                              i_rowids     => l_rowids,
                                              o_error      => l_error);
            ELSE
                ts_icnp_cplan_stand_compo.ins(id_cplan_stand_in        => l_cplan_key,
                                              id_composition_in        => l_exp_res,
                                              id_composition_parent_in => i_diags(i),
                                              flg_compo_type_in        => pk_icnp_constant.g_cp_st_compo_type_res,
                                              flg_status_in            => pk_icnp_constant.g_cp_st_compo_status_active,
                                              id_cplan_stand_compo_out => l_next_cplan_compo_id,
                                              rows_out                 => l_rowids);
            
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'ICNP_CPLAN_STAND_COMPO',
                                              i_rowids     => l_rowids,
                                              o_error      => l_error);
            
            END IF;
            l_found := pk_alert_constant.g_no;
        END LOOP;
    
        --actualizar intervenções
        FOR i IN 1 .. i_intervs.count
        LOOP
            -- Converts the raw data record into a typed record
            l_data_ux_rec := populate_create_cplan_rec(i_values => i_intervs(i));
        
            BEGIN
                SELECT pk_alert_constant.g_yes
                  INTO l_found
                  FROM icnp_cplan_stand_compo i
                 WHERE i.id_cplan_stand = l_cplan_key
                   AND i.id_composition = l_data_ux_rec.id_composition_interv
                   AND i.id_composition_parent = l_data_ux_rec.id_composition_diag
                   AND i.flg_compo_type = pk_icnp_constant.g_cp_st_compo_type_interv;
            EXCEPTION
                WHEN no_data_found THEN
                    l_found := pk_alert_constant.g_no;
            END;
        
            -- Set a temporary order recurrence plan as definitive (final status)
            log_debug('set_order_recurr_plan / l_data_ux_rec.id_order_recurr_plan: ' ||
                      l_data_ux_rec.id_order_recurr_plan,
                      c_func_name);
            l_order_recurr_rec := set_order_recurr_plan(i_lang                     => i_lang,
                                                        i_prof                     => i_prof,
                                                        i_recurr_plan_id           => l_data_ux_rec.id_order_recurr_plan,
                                                        io_recurr_processed_coll   => l_recurr_processed_coll,
                                                        io_recurr_definit_ids_coll => l_recurr_definit_ids_coll,
                                                        io_precessed_plans         => l_processed_plan);
        
            -- Maps the a given frequency to its equivalent type
            log_debug('map_recurr_option_to_type', c_func_name);
            l_flg_type := map_recurr_option_to_type(l_order_recurr_rec.id_order_recurr_option);
        
            IF l_found = pk_alert_constant.g_yes
            THEN
                ts_icnp_cplan_stand_compo.upd(flg_status_in            => pk_icnp_constant.g_cp_st_compo_status_active,
                                              flg_status_nin           => FALSE,
                                              flg_time_in              => l_data_ux_rec.flg_time,
                                              flg_time_nin             => FALSE,
                                              flg_type_in              => l_flg_type,
                                              flg_type_nin             => FALSE,
                                              id_order_recurr_plan_in  => l_order_recurr_rec.id_order_recurr_plan,
                                              id_order_recurr_plan_nin => FALSE,
                                              flg_prn_in               => l_data_ux_rec.flg_prn,
                                              flg_prn_nin              => FALSE,
                                              prn_notes_in             => l_data_ux_rec.prn_notes,
                                              prn_notes_nin            => FALSE,
                                              where_in                 => ' ID_CPLAN_STAND=' || l_cplan_key ||
                                                                          ' AND ID_COMPOSITION=' ||
                                                                          l_data_ux_rec.id_composition_interv ||
                                                                          ' AND ID_COMPOSITION_PARENT=' ||
                                                                          l_data_ux_rec.id_composition_diag,
                                              rows_out                 => l_rowids);
            
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'ICNP_CPLAN_STAND_COMPO',
                                              i_rowids     => l_rowids,
                                              o_error      => l_error);
            ELSE
                ts_icnp_cplan_stand_compo.ins(id_cplan_stand_in        => l_cplan_key,
                                              id_composition_in        => l_data_ux_rec.id_composition_interv,
                                              id_composition_parent_in => l_data_ux_rec.id_composition_diag,
                                              flg_compo_type_in        => pk_icnp_constant.g_cp_st_compo_type_interv,
                                              flg_status_in            => pk_icnp_constant.g_cp_st_compo_status_active,
                                              flg_time_in              => l_data_ux_rec.flg_time,
                                              flg_type_in              => l_flg_type,
                                              id_order_recurr_plan_in  => l_order_recurr_rec.id_order_recurr_plan,
                                              flg_prn_in               => l_data_ux_rec.flg_prn,
                                              prn_notes_in             => l_data_ux_rec.prn_notes,
                                              id_cplan_stand_compo_out => l_next_cplan_compo_id,
                                              rows_out                 => l_rowids);
            
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'ICNP_CPLAN_STAND_COMPO',
                                              i_rowids     => l_rowids,
                                              o_error      => l_error);
            
            END IF;
            l_found := pk_alert_constant.g_no;
        END LOOP;
    
        -- update associated specialties
        update_icnp_cplan_dcs(i_prof        => i_prof,
                              i_cplan_stand => l_cplan_key,
                              i_dcs         => i_dep_clin_serv,
                              i_soft        => i_soft);
    
    END create_or_update_icnp_cplan;

    /**
    * Get list of available actions, from a given state. When specifying more than one state,
    * it groups the actions, according to their availability. This enables support
    * for "bulk" state changes.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_subject      action subject
    * @param i_from_state   list of selected states
    * @param o_actions      actions cursor
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/07/20
    */
    PROCEDURE get_actions_permissions
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_subject                IN action.subject%TYPE,
        i_from_state             IN table_varchar,
        id_icnp_epis_interv_diag IN table_number,
        o_actions                OUT pk_types.cursor_type
    ) IS
        l_actions         t_coll_action_cipe;
        l_interv_flg_time icnp_epis_intervention.flg_time%TYPE;
    
        CURSOR c_icnp_epis_interv IS
            SELECT iei.flg_time
              FROM icnp_epis_intervention iei
             WHERE iei.id_icnp_epis_interv = id_icnp_epis_interv_diag(id_icnp_epis_interv_diag.first);
    
    BEGIN
        IF i_subject = 'ICNP_INTERV'
           AND id_icnp_epis_interv_diag.count = 1
        THEN
            OPEN c_icnp_epis_interv;
            FETCH c_icnp_epis_interv
                INTO l_interv_flg_time;
            CLOSE c_icnp_epis_interv;
        
            -- no need to verify if l_interv_flg_time is NULL
            l_actions := get_actions_perm_int(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_subject    => i_subject,
                                              i_from_state => i_from_state,
                                              i_flg_time   => l_interv_flg_time);
        ELSE
            l_actions := get_actions_perm_int(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_subject    => i_subject,
                                              i_from_state => i_from_state);
        END IF;
    
        OPEN o_actions FOR
            SELECT a.id_action,
                   a.id_parent,
                   a.action_level  "LEVEL",
                   a.to_state,
                   a.desc_action,
                   a.icon,
                   a.flg_default,
                   a.flg_active,
                   a.internal_name action
              FROM TABLE(l_actions) a;
    
    END get_actions_permissions;

    /********************************************************************************************
    *  Obter lista de opções para requisição
    *
    * @param      i_lang       Preferred language ID for this professional
    * @param      i_prof       Object (professional ID, institution ID, software ID)
    * @param      o_list       Clinical services
    * @param      o_error      Error
    *
    * @return                  boolean type, "False" on error or "True" if success 
    *
    * @author                  Sérgio Santos
    * @version                 2.5.1 
    * @since                   2010/05/17
    *********************************************************************************************/
    PROCEDURE get_create_list
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        o_list OUT pk_types.cursor_type
    ) IS
    BEGIN
        OPEN o_list FOR
            SELECT g_type_diag_interv AS action,
                   10 AS rank,
                   pk_message.get_message(i_lang, i_prof, 'CPLAN_T020') AS desc_action
              FROM dual
            UNION ALL
            SELECT g_type_interv AS action,
                   20 AS rank,
                   pk_message.get_message(i_lang, i_prof, 'CPLAN_T021') AS desc_action
              FROM dual
            UNION ALL
            SELECT g_type_diag AS action,
                   30 AS rank,
                   pk_message.get_message(i_lang, i_prof, 'CPLAN_T070') AS desc_action
              FROM dual;
    
    END get_create_list;

    /**
    * Get ICNP create button available actions.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param o_actions      actions cursor
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/08/05
    */
    PROCEDURE get_create_list_fo
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_actions OUT pk_types.cursor_type
    ) IS
        l_subject      CONSTANT action.subject%TYPE := 'ICNP_CREATE';
        l_action_cplan CONSTANT action.internal_name%TYPE := 'CPLAN_STAND';
        l_count      PLS_INTEGER := 0;
        l_flg_active VARCHAR2(1 CHAR) := pk_alert_constant.g_inactive;
    BEGIN
        -- count available plans for professional
        SELECT COUNT(*)
          INTO l_count
          FROM icnp_cplan_stand ics
         WHERE EXISTS (SELECT 1
                  FROM icnp_cplan_stand_dcs icsd
                  JOIN prof_dep_clin_serv pdcs
                    ON icsd.id_dep_clin_serv = pdcs.id_dep_clin_serv
                 WHERE icsd.id_cplan_stand = ics.id_cplan_stand
                   AND ics.id_institution IN (0, i_prof.institution)
                   AND ics.flg_status = pk_icnp_constant.g_icnp_cplan_status_active
                   AND icsd.id_software = i_prof.software
                   AND pdcs.id_professional = i_prof.id
                   AND pdcs.id_institution = i_prof.institution
                   AND pdcs.flg_status = pk_alert_constant.g_status_selected);
    
        -- have plans? toggle flag
        IF l_count > 0
        THEN
            l_flg_active := pk_alert_constant.g_active;
        END IF;
    
        OPEN o_actions FOR
            SELECT a.id_action,
                   a.id_parent,
                   1 "LEVEL",
                   a.from_state,
                   a.to_state,
                   pk_message.get_message(i_lang, i_prof, code_action) desc_action,
                   a.icon,
                   decode(a.flg_default, 'D', pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_default,
                   decode(a.internal_name, l_action_cplan, l_flg_active, a.flg_status) flg_active,
                   a.internal_name action
              FROM action a
             WHERE a.subject = l_subject
             ORDER BY a.rank, desc_action;
    
    END get_create_list_fo;

    /********************************************************************************************
    * Returns diagnosis summary view
    *
    * @param i_lang               Language identifier
    * @param i_prof               Logged professional structure
    * @param i_patient            Patient identifier
    * @param o_diag               Diagnoses cursor
    *
    * @return                boolean type, "False" on error or "True" if success
    *
    * @raises
    *
    * @author                Sérgio Santos
    * @version               2.5.1
    * @since                 2010/08/02
    *********************************************************************************************/
    PROCEDURE get_diag_summary
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_diag    OUT pk_types.cursor_type
    ) IS
        --Message "Associated interventions:"
        l_msg_assoc_interv sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                   i_prof      => i_prof,
                                                                                   i_code_mess => pk_icnp_constant.mcodet_assoc_interv);
        --Message "Diagnosis"
        l_msg_diagnosis sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                i_prof      => i_prof,
                                                                                i_code_mess => pk_icnp_constant.mcodet_diagnosis);
        --Message "Expected results:"
        l_msg_exp_results sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                  i_prof      => i_prof,
                                                                                  i_code_mess => pk_icnp_constant.mcodet_exp_results);
    BEGIN
        -- open diagnosis cursor
        OPEN o_diag FOR
            SELECT ied.id_icnp_epis_diag,
                   ied.id_composition id_diagnosis,
                   l_msg_diagnosis || pk_icnp_constant.g_word_space ||
                   pk_icnp.desc_composition(i_lang, ied.id_composition) desc_diagnosis,
                   ied.icnp_compo_reeval id_exp_result,
                   l_msg_exp_results msg_exp_results,
                   nvl(pk_icnp.desc_composition(i_lang, ied.icnp_compo_reeval),
                       pk_icnp_constant.g_word_space || pk_icnp_constant.g_word_no_record) desc_exp_result,
                   l_msg_assoc_interv msg_assoc_interv,
                   nvl(get_diag_interventions_desc(i_lang,
                                                   i_prof,
                                                   ied.id_icnp_epis_diag,
                                                   pk_alert_constant.g_no,
                                                   NULL,
                                                   NULL,
                                                   NULL),
                       pk_icnp_constant.g_word_space || pk_icnp_constant.g_word_no_record) desc_interv_list,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang,
                                                      coalesce(ied.dt_last_update,
                                                               ied.dt_close_tstz,
                                                               ied.dt_icnp_epis_diag_tstz),
                                                      i_prof.institution,
                                                      i_prof.software) dt_diag_desc,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ied.id_professional) AS prof_name_desc,
                   decode(pk_prof_utils.get_spec_signature(i_lang,
                                                           i_prof,
                                                           ied.id_professional,
                                                           ied.dt_icnp_epis_diag_tstz,
                                                           ied.id_episode),
                          NULL,
                          NULL,
                          pk_icnp_constant.g_word_open_brac ||
                          pk_prof_utils.get_spec_signature(i_lang,
                                                           i_prof,
                                                           ied.id_professional,
                                                           ied.dt_icnp_epis_diag_tstz,
                                                           ied.id_episode) || pk_icnp_constant.g_word_close_brac) prof_spec_desc,
                   ied.flg_status,
                   decode(ied.flg_status,
                          pk_icnp_constant.g_epis_diag_status_cancelled,
                          pk_alert_constant.g_inactive,
                          pk_icnp_constant.g_epis_diag_status_resolved,
                          pk_alert_constant.g_inactive,
                          pk_alert_constant.g_active) flg_cancel
              FROM icnp_epis_diagnosis ied
             WHERE ied.id_patient = i_patient
             ORDER BY (SELECT pk_sysdomain.get_rank(i_lang, pk_icnp_constant.g_domain_epis_diag_status, ied.flg_status)
                         FROM dual),
                      coalesce(ied.dt_last_update, ied.dt_close_tstz, ied.dt_icnp_epis_diag_tstz) DESC;
    
    END get_diag_summary;

    /**
    * Get diagnosis conclusion warning.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_action       chosen action
    * @param i_diag         selected diagnosis list
    * @param o_warn         warning
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/09/16
    */
    PROCEDURE get_diag_warn
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_action IN action.internal_name%TYPE,
        i_diag   IN table_number,
        o_warn   OUT table_varchar
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'get_diag_warn';
        l_count     PLS_INTEGER := 0;
        l_title     sys_message.desc_message%TYPE;
        l_msg       sys_message.desc_message%TYPE;
        l_sub_msg   sys_message.desc_message%TYPE;
        l_buttons   sys_message.desc_message%TYPE;
        l_diag_desc VARCHAR2(4000);
    
        CURSOR c_interv IS
            SELECT 1
              FROM icnp_epis_diag_interv iedi
              JOIN (SELECT iedi.id_icnp_epis_diag, iedi.id_icnp_epis_interv
                      FROM icnp_epis_diag_interv iedi
                     WHERE iedi.id_icnp_epis_diag IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                       t.column_value id_icnp_epis_diag
                                                        FROM TABLE(i_diag) t)) conn
                ON iedi.id_icnp_epis_interv = conn.id_icnp_epis_interv
             WHERE iedi.id_icnp_epis_diag != conn.id_icnp_epis_diag;
    
    BEGIN
        -- debug input
        log_debug('i_action: ' || i_action || ', i_diag: ' || pk_utils.to_string(i_input => i_diag), c_func_name);
    
        IF i_diag IS NULL
           OR i_diag.count < 1
        THEN
            o_warn := table_varchar();
        ELSIF i_action IN (pk_icnp_constant.g_action_diag_resolve, pk_icnp_constant.g_action_diag_cancel)
        THEN
        
            --get the diagnosis description
            SELECT substr(concatenate(pk_icnp.desc_composition(i_lang, ied.id_composition) ||
                                      pk_icnp_constant.g_word_sep),
                          1,
                          length(concatenate(pk_icnp.desc_composition(i_lang, ied.id_composition) ||
                                             pk_icnp_constant.g_word_sep)) - 2)
              INTO l_diag_desc
              FROM icnp_epis_diagnosis ied
             WHERE ied.id_icnp_epis_diag IN (SELECT column_value
                                               FROM TABLE(i_diag));
        
            -- check if associated interventions are linked to other diagnoses
            OPEN c_interv;
            FETCH c_interv
                INTO l_count;
            CLOSE c_interv;
        
            -- build warning message
            IF i_action = pk_icnp_constant.g_action_diag_resolve
            THEN
                l_title   := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'CPLAN_T049');
                l_msg     := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'CPLAN_T100');
                l_sub_msg := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'CPLAN_T051');
            
                l_msg := REPLACE(l_msg, '@1', l_diag_desc);
            
                --l_msg := l_diag_desc;
            ELSIF i_action = pk_icnp_constant.g_action_diag_cancel
            THEN
                l_title   := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'COMMON_T013');
                l_msg     := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'CPLAN_T079');
                l_sub_msg := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'CPLAN_T084');
            END IF;
        
            l_buttons := 'NC';
        
            IF l_count = 1
            THEN
                l_sub_msg := l_sub_msg || chr(10) || chr(10) ||
                             pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'CPLAN_T121');
            END IF;
        
            -- set out variable
            o_warn := table_varchar(l_title, l_msg, l_sub_msg, l_buttons);
        END IF;
    
    END get_diag_warn;

    /********************************************************************************************
    * Returns ICNP's diagnosis hist
    *
    * @param      i_lang    Preferred language ID for this professional
    * @param      i_prof    Object (professional ID, institution ID, software ID)
    * @param      i_diag    Diagnosis ID
    * @param      i_episode            Episode identifier
    * @param      o_diag    Diagnosis cursor
    * @param      o_r_diag  Most recent diagnosis
    * @param      o_error   Error
    *
    * @return                boolean type, "False" on error or "True" if success
    *
    * @raises
    *
    * @author                Sérgio Santos (based on pk_icnp.get_diag_hist)
    * @version               2.5.1
    * @since                 2010/08/03
    *********************************************************************************************/
    PROCEDURE get_diagnosis_hist
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_diag    IN icnp_epis_diagnosis.id_icnp_epis_diag%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_diag    OUT pk_types.cursor_type,
        o_r_diag  OUT pk_types.cursor_type
    ) IS
        l_msg_cipe_t078 sys_message.code_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                i_prof      => i_prof,
                                                                                i_code_mess => 'CIPE_T078');
        l_msg_cipe_t097 sys_message.code_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                i_prof      => i_prof,
                                                                                i_code_mess => 'CIPE_T097');
        l_msg_cipe_t111 sys_message.code_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                i_prof      => i_prof,
                                                                                i_code_mess => 'CIPE_T111');
        l_msg_cipe_t112 sys_message.code_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                i_prof      => i_prof,
                                                                                i_code_mess => 'CIPE_T112');
        l_msg_cipe_t113 sys_message.code_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                i_prof      => i_prof,
                                                                                i_code_mess => 'CIPE_T113');
    
        --Message "Expected results:"
        l_msg_exp_results sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                  i_prof      => i_prof,
                                                                                  i_code_mess => pk_icnp_constant.mcodet_exp_results);
        --Criado a:
        l_msg_created sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                              i_prof      => i_prof,
                                                                              i_code_mess => 'CPLAN_T091');
        --Reavalido a:
        l_msg_reav sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                           i_prof      => i_prof,
                                                                           i_code_mess => 'CPLAN_T092');
        --Editado a:
        l_msg_edited sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                             i_prof      => i_prof,
                                                                             i_code_mess => 'CPLAN_T093');
        --Cancelado a:
        l_msg_cancelled sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                i_prof      => i_prof,
                                                                                i_code_mess => 'CPLAN_T096');
        --Suspenso a:
        l_msg_suspended sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                i_prof      => i_prof,
                                                                                i_code_mess => 'CPLAN_T097');
        --Resolvido a:
        l_msg_solved sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                             i_prof      => i_prof,
                                                                             i_code_mess => 'CPLAN_T098');
        --Activado a:                                                                    
        l_msg_activated sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                i_prof      => i_prof,
                                                                                i_code_mess => 'ICNP_T182');
    
        --Message "Associated interventions:"
        l_msg_assoc_interv sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                   i_prof      => i_prof,
                                                                                   i_code_mess => pk_icnp_constant.mcodet_assoc_interv);
        --Motivo de cancelamento:
        l_msg_cancel_res sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                 i_prof      => i_prof,
                                                                                 i_code_mess => 'CPLAN_T094');
        --Notas de cancelamento:
        l_msg_cancel_notes sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                   i_prof      => i_prof,
                                                                                   i_code_mess => 'CPLAN_T095');
    
        msg_sup_res   sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'CPLAN_T200');
        msg_sup_notes sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'CPLAN_T076');
    
        c_epis_diag    pk_types.cursor_type;
        coll_epis_diag t_coll_icnp_epis_diag;
    
        coll_epis_diag_aux t_coll_icnp_epis_diag := t_coll_icnp_epis_diag();
    
        l_interv_1 VARCHAR2(4000 CHAR);
        l_interv_2 VARCHAR2(4000 CHAR);
    
        l_id_composition_1 icnp_epis_diagnosis.id_composition%TYPE;
        l_id_composition_2 icnp_epis_diagnosis.id_composition%TYPE;
    
        l_count NUMBER;
    
        CURSOR c_inst IS
            SELECT e.id_epis_type
              FROM episode e
             WHERE e.id_episode = i_episode;
    
        l_epis_type epis_type.id_epis_type%TYPE;
    
    BEGIN
    
        OPEN c_inst;
        FETCH c_inst
            INTO l_epis_type;
        CLOSE c_inst;
    
        OPEN c_epis_diag FOR
            SELECT rec
              FROM (SELECT t_rec_icnp_epis_diag(id_icnp_epis_diag,
                                                -1,
                                                id_composition,
                                                id_professional,
                                                flg_status,
                                                id_episode,
                                                notes,
                                                id_prof_close,
                                                notes_close,
                                                id_patient,
                                                dt_last_update,
                                                dt_close_tstz,
                                                id_visit,
                                                id_epis_type,
                                                flg_executions,
                                                icnp_compo_reeval,
                                                id_prof_last_update,
                                                dt_last_update,
                                                id_suspend_reason,
                                                id_suspend_prof,
                                                suspend_notes,
                                                dt_suspend,
                                                id_cancel_reason,
                                                id_cancel_prof,
                                                cancel_notes,
                                                dt_cancel,
                                                NULL,
                                                NULL) rec,
                           dt_last_update
                      FROM icnp_epis_diagnosis ied
                     WHERE ied.id_icnp_epis_diag = i_diag
                    UNION ALL
                    SELECT t_rec_icnp_epis_diag(id_icnp_epis_diag,
                                                id_icnp_epis_diag_hist,
                                                id_composition,
                                                id_professional,
                                                flg_status,
                                                id_episode,
                                                notes,
                                                id_prof_close,
                                                notes_close,
                                                id_patient,
                                                dt_last_update,
                                                dt_close,
                                                id_visit,
                                                id_epis_type,
                                                flg_executions,
                                                icnp_compo_reeval,
                                                id_prof_last_update,
                                                dt_last_update,
                                                id_suspend_reason,
                                                id_suspend_prof,
                                                suspend_notes,
                                                dt_suspend,
                                                id_cancel_reason,
                                                id_cancel_prof,
                                                cancel_notes,
                                                dt_cancel,
                                                NULL,
                                                NULL) rec,
                           dt_last_update dt_icnp_epis_diag_tstz
                      FROM icnp_epis_diagnosis_hist iedh
                     WHERE iedh.id_icnp_epis_diag = i_diag
                     ORDER BY dt_last_update DESC);
    
        FETCH c_epis_diag BULK COLLECT
            INTO coll_epis_diag;
        CLOSE c_epis_diag;
    
        l_count := 1;
    
        -- Most recent record
        OPEN o_r_diag FOR
            SELECT coll_epis_diag(l_count).id_icnp_epis_diag,
                   l_msg_cipe_t112 || pk_icnp_constant.g_word_space msg_diag,
                   concat(nvl(pk_icnp.desc_composition(i_lang, coll_epis_diag(l_count).id_composition),
                              pk_icnp_constant.g_word_space || pk_icnp_constant.g_word_no_record),
                          decode( /*o tipo do episodio*/l_epis_type,
                                 /*tipo de episodio do episodio da requisição*/
                                 pk_episode.get_epis_type(i_lang, coll_epis_diag(l_count).id_episode),
                                 '',
                                 ' - (' || pk_message.get_message(i_lang,
                                                                  profissional(i_prof.id,
                                                                               i_prof.institution,
                                                                               (SELECT pk_episode.get_soft_by_epis_type(e.id_epis_type,
                                                                                                                        e.id_institution)
                                                                                  FROM episode e
                                                                                 WHERE e.id_episode = coll_epis_diag(l_count).id_episode)),
                                                                  'IMAGE_T009') || pk_icnp_constant.g_word_close_brac)) desc_diag,
                   l_msg_exp_results msg_exp_results,
                   nvl(pk_icnp.desc_composition(i_lang, coll_epis_diag(l_count).icnp_compo_reeval),
                       pk_icnp_constant.g_word_space || pk_icnp_constant.g_word_no_record) desc_exp_result,
                   l_msg_cipe_t113 || pk_icnp_constant.g_word_space msg_interv,
                   l_msg_cipe_t078 || pk_icnp_constant.g_word_space msg_notes,
                   nvl(get_diag_interventions_desc(i_lang,
                                                   i_prof,
                                                   coll_epis_diag(l_count).id_icnp_epis_diag,
                                                   pk_alert_constant.g_no,
                                                   NULL,
                                                   NULL,
                                                   NULL),
                       pk_icnp_constant.g_word_no_record) desc_intervs,
                   nvl(get_diag_interventions_desc(i_lang,
                                                   i_prof,
                                                   coll_epis_diag(l_count).id_icnp_epis_diag,
                                                   pk_alert_constant.g_no,
                                                   NULL,
                                                   NULL,
                                                   NULL,
                                                   pk_alert_constant.g_yes),
                       pk_icnp_constant.g_word_no_record) desc_intervs_rep, --reports use     
                   nvl(get_diag_interventions_desc(i_lang,
                                                   i_prof,
                                                   coll_epis_diag(l_count).id_icnp_epis_diag,
                                                   pk_alert_constant.g_yes,
                                                   NULL,
                                                   NULL,
                                                   NULL),
                       pk_icnp_constant.g_word_no_record) desc_intervs_instruc,
                   nvl(coll_epis_diag(l_count).notes, pk_icnp_constant.g_word_no_record) notes
              FROM dual;
    
        --vamos construir uma nova colecção duplicando a linha no caso das intervenções
        --associadas a um diagnóstico alterarem. Esta validação é feita por data de registo.
        --vamos também verificar se existiu uma reavaliação
        FOR i IN 1 .. coll_epis_diag.count
        LOOP
            l_id_composition_1 := coll_epis_diag(i).id_composition;
        
            l_interv_1 := get_diag_interventions_desc(i_lang,
                                                      i_prof,
                                                      coll_epis_diag        (i).id_icnp_epis_diag,
                                                      pk_alert_constant.g_no,
                                                      NULL,
                                                      NULL,
                                                      coll_epis_diag        (i).dt_icnp_epis_diag_tstz);
        
            IF i < coll_epis_diag.count
            THEN
                l_id_composition_2 := coll_epis_diag(i + 1).id_composition;
            
                l_interv_2 := get_diag_interventions_desc(i_lang,
                                                          i_prof,
                                                          coll_epis_diag        (i).id_icnp_epis_diag,
                                                          pk_alert_constant.g_no,
                                                          NULL,
                                                          NULL,
                                                          coll_epis_diag        (i + 1).dt_icnp_epis_diag_tstz);
            ELSE
                l_interv_2 := l_interv_1;
            END IF;
        
            coll_epis_diag_aux.extend;
            coll_epis_diag_aux(coll_epis_diag_aux.count) := coll_epis_diag(i);
            coll_epis_diag_aux(coll_epis_diag_aux.count).desc_interv := l_interv_1;
        
            IF l_id_composition_1 <> l_id_composition_2
            THEN
                coll_epis_diag_aux(coll_epis_diag_aux.count).flg_reav := pk_alert_constant.g_yes;
            END IF;
        
        /*            IF l_interv_1 <> l_interv_2
                                                                                                                                                                                                                                                                                                                                                                                            THEN
                                                                                                                                                                                                                                                                                                                                                                                                coll_epis_diag_aux.extend;
                                                                                                                                                                                                                                                                                                                                                                                                coll_epis_diag_aux(coll_epis_diag_aux.count) := coll_epis_diag(i);
                                                                                                                                                                                                                                                                                                                                                                                                coll_epis_diag_aux(coll_epis_diag_aux.count).desc_interv := l_interv_2;
                                                                                                                                                                                                                                                                                                                                                                                            END IF;*/
        
        END LOOP;
    
        --construcção do cursor final
        OPEN o_diag FOR
            SELECT *
              FROM (SELECT DISTINCT -- genéricos
                                    ied.id_icnp_epis_diag,
                                    ied.flg_status,
                                    ied.dt_last_update,
                                    decode(ied.flg_status,
                                           pk_icnp_constant.g_epis_diag_status_active,
                                           decode(get_diag_prior_status(ied.id_icnp_epis_diag, NULL),
                                                  pk_icnp_constant.g_epis_diag_status_suspended,
                                                  l_msg_activated,
                                                  decode(flg_reav,
                                                         pk_alert_constant.g_yes,
                                                         l_msg_reav,
                                                         decode(dt_icnp_epis_diag_tstz,
                                                                coll_epis_diag_aux(coll_epis_diag_aux.count).dt_icnp_epis_diag_tstz,
                                                                l_msg_created,
                                                                l_msg_edited))),
                                           pk_icnp_constant.g_epis_diag_status_cancelled,
                                           l_msg_cancelled,
                                           pk_icnp_constant.g_epis_diag_status_resolved,
                                           l_msg_solved,
                                           pk_icnp_constant.g_epis_diag_status_suspended,
                                           l_msg_suspended) left_title,
                                    pk_date_utils.date_char_hour_tsz(i_lang,
                                                                     decode(ied.flg_status,
                                                                            pk_icnp_constant.g_epis_diag_status_cancelled,
                                                                            dt_cancel,
                                                                            pk_icnp_constant.g_epis_diag_status_suspended,
                                                                            dt_suspend,
                                                                            dt_icnp_epis_diag_tstz),
                                                                     i_prof.institution,
                                                                     i_prof.software) || pk_icnp_constant.g_word_space ||
                                    pk_date_utils.dt_chr_tsz(i_lang,
                                                             decode(ied.flg_status,
                                                                    pk_icnp_constant.g_epis_diag_status_cancelled,
                                                                    dt_cancel,
                                                                    pk_icnp_constant.g_epis_diag_status_suspended,
                                                                    dt_suspend,
                                                                    dt_icnp_epis_diag_tstz),
                                                             i_prof) dt_diag,
                                    pk_prof_utils.get_name_signature(i_lang,
                                                                     i_prof,
                                                                     decode(ied.flg_status,
                                                                            pk_icnp_constant.g_epis_diag_status_cancelled,
                                                                            id_cancel_prof,
                                                                            pk_icnp_constant.g_epis_diag_status_suspended,
                                                                            id_suspend_prof,
                                                                            
                                                                            id_prof_last_update)) AS prof,
                                    pk_prof_utils.get_spec_signature(i_lang,
                                                                     i_prof,
                                                                     decode(ied.flg_status,
                                                                            pk_icnp_constant.g_epis_diag_status_cancelled,
                                                                            id_cancel_prof,
                                                                            pk_icnp_constant.g_epis_diag_status_suspended,
                                                                            id_suspend_prof,
                                                                            id_professional),
                                                                     decode(ied.flg_status,
                                                                            pk_icnp_constant.g_epis_diag_status_cancelled,
                                                                            dt_cancel,
                                                                            pk_icnp_constant.g_epis_diag_status_suspended,
                                                                            dt_suspend,
                                                                            dt_icnp_epis_diag_tstz),
                                                                     ied.id_episode) spec_prof,
                                    decode(dt_icnp_epis_diag_tstz,
                                           coll_epis_diag_aux(coll_epis_diag_aux.count).dt_icnp_epis_diag_tstz,
                                           'CREA',
                                           'EDIT') flg_hist_action,
                                    -- activos e reavalidados
                                    decode(ied.flg_status,
                                           pk_icnp_constant.g_epis_diag_status_active,
                                           l_msg_cipe_t097,
                                           NULL) msg_begin,
                                    decode(ied.flg_status,
                                           pk_icnp_constant.g_epis_diag_status_active,
                                           pk_date_utils.dt_chr_tsz(i_lang,
                                                                    coll_epis_diag_aux(coll_epis_diag_aux.count).dt_icnp_epis_diag_tstz,
                                                                    i_prof),
                                           NULL) desc_begin,
                                    decode(ied.flg_status,
                                           pk_icnp_constant.g_epis_diag_status_active,
                                           l_msg_cipe_t112,
                                           NULL) msg_diag,
                                    decode(ied.flg_status,
                                           pk_icnp_constant.g_epis_diag_status_active,
                                           pk_icnp.desc_composition(i_lang, id_composition),
                                           NULL) desc_diag,
                                    decode(ied.flg_status,
                                           pk_icnp_constant.g_epis_diag_status_active,
                                           l_msg_exp_results,
                                           NULL) msg_exp_results,
                                    decode(ied.flg_status,
                                           pk_icnp_constant.g_epis_diag_status_active,
                                           nvl(pk_icnp.desc_composition(i_lang, ied.icnp_compo_reeval),
                                               pk_icnp_constant.g_word_space || pk_icnp_constant.g_word_no_record),
                                           NULL) desc_exp_results,
                                    decode(ied.flg_status,
                                           pk_icnp_constant.g_epis_diag_status_active,
                                           l_msg_assoc_interv,
                                           NULL) msg_interv,
                                    decode(ied.flg_status,
                                           pk_icnp_constant.g_epis_diag_status_active,
                                           nvl(get_diag_intervs_hist_desc(i_lang,
                                                                          i_prof,
                                                                          id_icnp_epis_diag,
                                                                          pk_alert_constant.g_yes,
                                                                          NULL,
                                                                          NULL,
                                                                          NULL, --dt_icnp_epis_diag_tstz,
                                                                          table_varchar(pk_icnp_constant.g_moment_assoc_c),
                                                                          pk_icnp_constant.g_flg_type_assoc_d),
                                               /*nvl(get_diag_intervs_hist_desc(i_lang,
                                               i_prof,
                                               id_icnp_epis_diag,
                                               pk_alert_constant.g_yes,
                                               NULL,
                                               NULL,
                                               NULL),*/
                                               pk_icnp_constant.g_word_space || pk_icnp_constant.g_word_no_record /*)*/),
                                           NULL) desc_interv,
                                    l_msg_cipe_t111 msg_status, --genérico
                                    pk_sysdomain.get_domain('ICNP_EPIS_DIAGNOSIS.FLG_STATUS', ied.flg_status, i_lang) desc_status, --genérico
                                    decode(ied.flg_status,
                                           pk_icnp_constant.g_epis_diag_status_active,
                                           decode(notes, NULL, NULL, l_msg_cipe_t078),
                                           NULL) msg_notes,
                                    decode(ied.flg_status, pk_icnp_constant.g_epis_diag_status_active, notes, NULL) desc_notes,
                                    -- cancelado
                                    decode(ied.flg_status,
                                           pk_icnp_constant.g_epis_diag_status_cancelled,
                                           decode(pk_cancel_reason.get_cancel_reason_desc(i_lang,
                                                                                          i_prof,
                                                                                          id_cancel_reason),
                                                  NULL,
                                                  NULL,
                                                  l_msg_cancel_res),
                                           NULL) msg_cancel_reason,
                                    decode(ied.flg_status,
                                           pk_icnp_constant.g_epis_diag_status_cancelled,
                                           pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, id_cancel_reason),
                                           NULL) desc_cancel_reason,
                                    decode(ied.flg_status,
                                           pk_icnp_constant.g_epis_diag_status_cancelled,
                                           decode(nvl(notes_close, cancel_notes), NULL, NULL, l_msg_cancel_notes),
                                           NULL) msg_cancel_notes,
                                    decode(ied.flg_status,
                                           pk_icnp_constant.g_epis_diag_status_cancelled,
                                           nvl(notes_close, cancel_notes),
                                           NULL) desc_cancel_notes,
                                    -- suspenso
                                    decode(ied.flg_status,
                                           pk_icnp_constant.g_epis_diag_status_suspended,
                                           decode(pk_cancel_reason.get_cancel_reason_desc(i_lang,
                                                                                          i_prof,
                                                                                          id_suspend_reason),
                                                  NULL,
                                                  NULL,
                                                  msg_sup_res),
                                           NULL) msg_susp_reason,
                                    decode(ied.flg_status,
                                           pk_icnp_constant.g_epis_diag_status_suspended,
                                           pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, id_suspend_reason),
                                           NULL) desc_susp_reason,
                                    decode(ied.flg_status,
                                           pk_icnp_constant.g_epis_diag_status_suspended,
                                           decode(nvl(notes_close, suspend_notes), NULL, NULL, msg_sup_notes),
                                           NULL) msg_susp_notes,
                                    decode(ied.flg_status,
                                           pk_icnp_constant.g_epis_diag_status_suspended,
                                           nvl(notes_close, suspend_notes),
                                           NULL) desc_susp_notes
                      FROM (SELECT *
                              FROM TABLE(coll_epis_diag_aux)) ied
                    /*JOIN icnp_epis_dg_int_hist iedih
                     ON iedih.id_icnp_epis_diag = ied.id_icnp_epis_diag
                    AND iedih.id_icnp_epis_diag_interv= ied.id_icnp_epis_diag_hist*/
                    UNION ALL
                    --INTERV ASSOC
                    SELECT iedih.id_icnp_epis_diag,
                           NULL flg_status,
                           iedih.dt_hist dt_last_update,
                           pk_message.get_message(i_lang, 'CIPE_T143') left_title,
                           pk_date_utils.date_char_hour_tsz(i_lang, iedih.dt_hist, i_prof.institution, i_prof.software) ||
                           pk_icnp_constant.g_word_space || pk_date_utils.dt_chr_tsz(i_lang, iedih.dt_hist, i_prof) dt_diag,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, iedih.id_prof_assoc) AS prof,
                           pk_prof_utils.get_spec_signature(i_lang,
                                                            i_prof,
                                                            iedih.id_prof_assoc,
                                                            iedih.dt_hist,
                                                            ied.id_episode) spec_prof,
                           NULL flg_hist_action,
                           -- activos e reavalidados
                           NULL msg_begin,
                           NULL desc_begin,
                           NULL msg_diag,
                           NULL desc_diag,
                           NULL msg_exp_results,
                           NULL desc_exp_results,
                           l_msg_cipe_t113 || pk_icnp_constant.g_word_space msg_interv,
                           /*nvl(get_diag_intervs_hist_desc(i_lang,
                                                      i_prof,
                                                      iedih.id_icnp_epis_diag,
                                                      pk_alert_constant.g_no,
                                                      NULL,
                                                      NULL,
                                                      iedih.dt_hist,
                                                      table_varchar(iedih.flg_moment_assoc),
                                                      iedih.flg_type_assoc),
                           pk_icnp_constant.g_word_no_record)*/
                           pk_translation.get_translation(i_lang, ic2.code_icnp_composition) desc_intervs,
                           NULL msg_status, --genérico
                           NULL desc_status, --genérico
                           NULL msg_notes,
                           NULL desc_notes,
                           -- cancelado
                           NULL msg_cancel_reason,
                           NULL desc_cancel_reason,
                           NULL msg_cancel_notes,
                           NULL desc_cancel_notes,
                           -- suspenso
                           NULL msg_susp_reason,
                           NULL desc_susp_reason,
                           NULL msg_susp_notes,
                           NULL desc_susp_notes
                      FROM icnp_epis_diagnosis ied
                      JOIN icnp_epis_dg_int_hist iedih
                        ON iedih.id_icnp_epis_diag = ied.id_icnp_epis_diag
                      JOIN icnp_epis_intervention iei
                        ON iei.id_icnp_epis_interv = iedih.id_icnp_epis_interv
                      JOIN icnp_composition ic2
                        ON ic2.id_composition = iei.id_composition
                     WHERE iedih.id_icnp_epis_diag = i_diag
                          --AND trunc_timestamp_to_minutes(i_lang, i_prof, iedih.dt_hist) > ied.dt_icnp_epis_diag_tstz
                       AND iedih.flg_iud = pk_icnp_constant.g_iedih_flg_uid_i --INSERT
                       AND (((iedih.flg_moment_assoc = pk_icnp_constant.g_moment_assoc_a) AND
                           (iedih.flg_type_assoc IN
                           (pk_icnp_constant.g_flg_type_assoc_i, pk_icnp_constant.g_flg_type_assoc_d))) OR
                           ((iedih.flg_moment_assoc = pk_icnp_constant.g_moment_assoc_c) AND
                           (iedih.flg_type_assoc = pk_icnp_constant.g_flg_type_assoc_i))) --ASSOC
                       AND iedih.flg_status = pk_icnp_constant.g_interv_flg_status_a
                       AND iedih.flg_status_rel = pk_icnp_constant.g_interv_rel_active
                    UNION ALL
                    --REL_DIAG
                    SELECT iedih.id_icnp_epis_diag,
                           NULL flg_status,
                           iedih.dt_hist dt_last_update,
                           decode(iedih.flg_status_rel,
                                  pk_icnp_constant.g_interv_rel_cancel,
                                  pk_message.get_message(i_lang, 'CIPE_M013'),
                                  pk_icnp_constant.g_interv_rel_hold,
                                  pk_message.get_message(i_lang, 'CIPE_M015'),
                                  pk_icnp_constant.g_interv_rel_reactivated,
                                  pk_message.get_message(i_lang, 'CIPE_M016'),
                                  pk_icnp_constant.g_interv_rel_discontinued,
                                  pk_message.get_message(i_lang, 'CIPE_M014')) left_title,
                           pk_date_utils.date_char_hour_tsz(i_lang, iedih.dt_hist, i_prof.institution, i_prof.software) ||
                           pk_icnp_constant.g_word_space || pk_date_utils.dt_chr_tsz(i_lang, iedih.dt_hist, i_prof) dt_diag,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, iedih.id_prof_assoc) AS prof,
                           pk_prof_utils.get_spec_signature(i_lang,
                                                            i_prof,
                                                            iedih.id_prof_assoc,
                                                            iedih.dt_hist,
                                                            ied.id_episode) spec_prof,
                           NULL flg_hist_action,
                           -- activos e reavalidados
                           NULL msg_begin,
                           NULL desc_begin,
                           NULL msg_diag,
                           NULL desc_diag,
                           NULL msg_exp_results,
                           NULL desc_exp_results,
                           pk_message.get_message(1, 'CIPE_M025') || ': ' msg_interv,
                           nvl(get_diag_intervs_rel_desc(i_lang,
                                                         i_prof,
                                                         iedih.id_icnp_epis_diag,
                                                         pk_alert_constant.g_no,
                                                         NULL,
                                                         NULL,
                                                         iedih.dt_hist,
                                                         table_varchar(iedih.flg_moment_assoc)),
                               pk_icnp_constant.g_word_no_record) desc_intervs,
                           NULL msg_status, --genérico
                           NULL desc_status, --genérico
                           NULL msg_notes,
                           NULL desc_notes,
                           -- cancelado
                           NULL msg_cancel_reason,
                           NULL desc_cancel_reason,
                           NULL msg_cancel_notes,
                           NULL desc_cancel_notes,
                           -- suspenso
                           NULL msg_susp_reason,
                           NULL desc_susp_reason,
                           NULL msg_susp_notes,
                           NULL desc_susp_notes
                      FROM icnp_epis_diagnosis ied
                      JOIN icnp_epis_dg_int_hist iedih
                        ON iedih.id_icnp_epis_diag = ied.id_icnp_epis_diag
                      JOIN icnp_epis_intervention iei
                        ON iei.id_icnp_epis_interv = iedih.id_icnp_epis_interv
                      JOIN icnp_composition ic2
                        ON ic2.id_composition = ied.id_composition
                     WHERE iedih.id_icnp_epis_diag = i_diag
                          --AND trunc_timestamp_to_minutes(i_lang, i_prof, iedih.dt_hist) > ied.dt_icnp_epis_diag_tstz
                          --AND iedih.flg_iud = 'I' --INSERT
                          --AND iedih.flg_moment_assoc = 'A' --ASSOC
                       AND iedih.flg_status_rel IN (pk_icnp_constant.g_interv_rel_cancel,
                                                    pk_icnp_constant.g_interv_rel_hold,
                                                    pk_icnp_constant.g_interv_rel_discontinued))
             ORDER BY dt_last_update DESC;
    
    END get_diagnosis_hist;

    /**
     * Returns the description of the type of a given composition identifier. The
     * type has an associated flag that has translations on the sys_domain table.
     * 
     * @param i_lang The professional preferred language.
     * @param i_composition Composition identifier.
     * 
     * @return The description of the type of the given composition.
     * 
     * @author Luis Oliveira
     * @version 2.6.1
     * @since 14-Jun-2011
    */
    FUNCTION get_compo_type_desc
    (
        i_lang        IN sys_domain.id_language%TYPE,
        i_composition IN sys_domain.val%TYPE
    ) RETURN sys_domain.desc_val%TYPE IS
        l_desc_val  sys_domain.desc_val%TYPE;
        l_type      icnp_composition.flg_type%TYPE;
        l_type_coll table_varchar;
    BEGIN
        -- Check the input parameters
        IF i_composition IS NULL
        THEN
            pk_alert_exceptions.raise_error(error_name_in => pk_icnp_constant.g_excep_inv_input_params,
                                            text_in       => 'The composition identifier is null');
        END IF;
    
        -- Gets the type of the given composition identifier
        SELECT ic.flg_type
          BULK COLLECT
          INTO l_type_coll
          FROM icnp_composition ic
         WHERE ic.id_composition = i_composition;
    
        -- When no record is found return null
        IF l_type_coll IS empty
        THEN
            RETURN NULL;
        END IF;
    
        -- Get the description of the flg_type
        l_type     := l_type_coll(1);
        l_desc_val := pk_sysdomain.get_domain(i_code_dom => pk_icnp_constant.g_domain_compo_type,
                                              i_val      => l_type,
                                              i_lang     => i_lang);
    
        RETURN l_desc_val;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
        
    END get_compo_type_desc;

    /**
     * The icnp_cplan_stand_compo contains the set of icnp templates that could
     * be activated in frontoffice in order to ease the user in the request process.
     * This method gets all the data needed in order to correctly request one or
     * several of those templates. This method doesn't start by "get" because it 
     * changes some data in the database.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_sel_compo A set of diagnosis and interventions whose details must be 
     *                    returned.
     * @param o_diags All the details of the selected diagnosis needed to populate
     *                the UX form.
     * @param o_interv All the details of the selected interventions needed to populate
     *                the UX form.
     * 
     * @author Luis Oliveira
     * @version 2.6.1
     * @since 14/Jun/2011
    */
    PROCEDURE load_standard_cplan_info
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_sel_compo IN table_number,
        o_diags     OUT pk_types.cursor_type,
        o_interv    OUT pk_types.cursor_type
    ) IS
        c_func_name pk_icnp_type.t_function_name := 'LOAD_STANDARD_CPLAN_INFO';
        -- Vars to store data related with the intervention templates
        l_sel_compo_row  icnp_cplan_stand_compo%ROWTYPE;
        l_sel_compo_coll ts_icnp_cplan_stand_compo.icnp_cplan_stand_compo_ntt;
        -- Vars to store data related with the recurrence
        l_start_date        order_recurr_plan.start_date%TYPE;
        l_order_recurr_plan order_recurr_plan.id_order_recurr_plan%TYPE;
        -- Vars to store data related with the recurrence (not used)
        l_order_recurr_desc   VARCHAR2(1000 CHAR);
        l_order_recurr_option order_recurr_plan.id_order_recurr_option%TYPE;
        l_occurrences         order_recurr_plan.occurrences%TYPE;
        l_duration            order_recurr_plan.duration%TYPE;
        l_unit_meas_duration  order_recurr_plan.id_unit_meas_duration%TYPE;
        l_duration_desc       VARCHAR2(1000 CHAR);
        l_end_date            order_recurr_plan.end_date%TYPE;
        l_flg_end_by_editable VARCHAR2(1 CHAR);
        -- Vars to store the data that will be returned to the user
        l_interv_rec  t_rec_icnp_interv_act_st_cplan;
        l_interv_coll t_tbl_icnp_interv_act_st_cplan := t_tbl_icnp_interv_act_st_cplan();
    
        tbl_orp_interv table_number := table_number();
        tbl_orp        table_number := table_number();
        exists_interv  VARCHAR2(1 CHAR);
        idx_interv     NUMBER(24);
        -- Data structures related with error handling
        l_error t_error_out;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '()', c_func_name);
    
        -- Check the input parameters
        IF i_sel_compo IS empty
        THEN
            pk_alert_exceptions.raise_error(error_name_in => pk_icnp_constant.g_excep_inv_input_params,
                                            text_in       => 'The table of compositions given as input parameter is empty');
        END IF;
    
        -- Gets all the data of the templates of the interventions given as input parameter
        SELECT icsc.*
          BULK COLLECT
          INTO l_sel_compo_coll
          FROM icnp_cplan_stand_compo icsc
          JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                 t.column_value id_cplan_stand_compo
                  FROM TABLE(i_sel_compo) t) cp
            ON icsc.id_cplan_stand_compo = cp.id_cplan_stand_compo
          JOIN icnp_composition ip
            ON ip.id_composition = icsc.id_composition_parent
          JOIN icnp_composition_term ict
            ON ict.id_composition = icsc.id_composition_parent
          JOIN icnp_term it
            ON ict.id_term = it.id_term
         WHERE icsc.flg_status = pk_icnp_constant.g_cp_st_compo_status_active
           AND icsc.flg_compo_type = pk_icnp_constant.g_cp_st_compo_type_interv
           AND ict.flg_main_focus = pk_alert_constant.g_yes
         ORDER BY pk_translation.get_translation(i_lang, it.code_term),
                  pk_icnp.desc_composition(i_lang, icsc.id_composition_parent);
    
        -- Create a collection of interventions based in the template
        IF l_sel_compo_coll IS NOT empty
        THEN
            FOR i IN l_sel_compo_coll.first .. l_sel_compo_coll.last
            LOOP
                pk_alertlog.log_debug('process l_sel_compo_coll / ' || i);
            
                -- Get the current row
                l_sel_compo_row := l_sel_compo_coll(i);
            
                exists_interv := pk_alert_constant.g_no;
            
                FOR i IN 1 .. tbl_orp_interv.count
                LOOP
                    IF tbl_orp_interv(i) = l_sel_compo_row.id_composition
                    THEN
                        exists_interv := pk_alert_constant.g_yes;
                        idx_interv    := i;
                    END IF;
                END LOOP;
            
                IF exists_interv = pk_alert_constant.g_no
                THEN
                    -- Create a recurrence plan based on a predefined template
                    IF NOT
                        pk_order_recurrence_api_db.copy_from_order_recurr_plan(i_lang                   => i_lang,
                                                                               i_prof                   => i_prof,
                                                                               i_order_recurr_area      => pk_icnp_constant.g_order_recurr_area,
                                                                               i_order_recurr_plan_from => l_sel_compo_row.id_order_recurr_plan,
                                                                               o_order_recurr_desc      => l_order_recurr_desc,
                                                                               o_order_recurr_option    => l_order_recurr_option,
                                                                               o_start_date             => l_start_date,
                                                                               o_occurrences            => l_occurrences,
                                                                               o_duration               => l_duration,
                                                                               o_unit_meas_duration     => l_unit_meas_duration,
                                                                               o_duration_desc          => l_duration_desc,
                                                                               o_end_date               => l_end_date,
                                                                               o_flg_end_by_editable    => l_flg_end_by_editable,
                                                                               o_order_recurr_plan      => l_order_recurr_plan,
                                                                               o_error                  => l_error)
                    THEN
                        pk_icnp_util.raise_unexpected_error('pk_order_recurrence_api_db.copy_from_order_recurr_plan',
                                                            l_error);
                    END IF;
                ELSE
                    l_order_recurr_plan := tbl_orp(idx_interv);
                END IF;
            
                tbl_orp_interv.extend;
                idx_interv := tbl_orp_interv.count;
                tbl_orp_interv(tbl_orp_interv.count) := l_sel_compo_row.id_composition;
                tbl_orp.extend;
                tbl_orp(tbl_orp.count) := l_order_recurr_plan;
            
                -- Populate the intervention record, of the collection, with the data that will be returned 
                l_interv_rec := t_rec_icnp_interv_act_st_cplan(id_interv            => l_sel_compo_row.id_composition,
                                                               desc_interv          => pk_icnp.desc_composition(i_lang,
                                                                                                                l_sel_compo_row.id_composition),
                                                               id_rel_diag          => l_sel_compo_row.id_composition_parent,
                                                               desc_instr           => get_interv_instructions_bo(i_lang,
                                                                                                                  i_prof,
                                                                                                                  l_sel_compo_row.id_cplan_stand_compo,
                                                                                                                  l_start_date),
                                                               execution            => l_sel_compo_row.flg_time,
                                                               desc_execution       => pk_sysdomain.get_domain(pk_icnp_constant.g_domain_epis_interv_time,
                                                                                                               l_sel_compo_row.flg_time,
                                                                                                               i_lang),
                                                               dt_begin             => pk_date_utils.date_send_tsz(i_lang => i_lang,
                                                                                                                   i_date => l_start_date,
                                                                                                                   i_prof => i_prof),
                                                               id_order_recurr_plan => l_order_recurr_plan,
                                                               flg_prn              => l_sel_compo_row.flg_prn,
                                                               desc_prn             => pk_sysdomain.get_domain(pk_icnp_constant.g_domain_epis_interv_prn,
                                                                                                               l_sel_compo_row.flg_prn,
                                                                                                               i_lang),
                                                               prn_notes            => l_sel_compo_row.prn_notes);
                -- Add the record to the collection
                l_interv_coll.extend;
                l_interv_coll(l_interv_coll.count) := l_interv_rec;
            
            END LOOP;
        END IF;
    
        OPEN o_diags FOR
            SELECT icsc.id_composition_parent id_diagnosis,
                   pk_icnp.desc_composition(i_lang, icsc.id_composition_parent) desc_diagnosis,
                   pk_translation.get_translation(i_lang, it.code_term) desc_focus,
                   icsc.id_composition id_exp_result,
                   pk_icnp.desc_composition(i_lang, icsc.id_composition) desc_exp_result
              FROM icnp_cplan_stand_compo icsc
              JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                     t.column_value id_cplan_stand_compo
                      FROM TABLE(i_sel_compo) t) cp
                ON icsc.id_cplan_stand_compo = cp.id_cplan_stand_compo
              JOIN icnp_composition_term ict
                ON ict.id_composition = icsc.id_composition_parent
              JOIN icnp_term it
                ON ict.id_term = it.id_term
             WHERE icsc.flg_status = pk_icnp_constant.g_cp_st_compo_status_active
               AND icsc.flg_compo_type = pk_icnp_constant.g_cp_st_compo_type_res
               AND ict.flg_main_focus = pk_alert_constant.g_yes
             ORDER BY pk_translation.get_translation(i_lang, it.code_term),
                      pk_icnp.desc_composition(i_lang, icsc.id_composition_parent);
    
        OPEN o_interv FOR
        
            SELECT id_interv,
                   desc_interv,
                   desc_instr,
                   execution,
                   desc_execution,
                   --dt_begin,
                   prn,
                   desc_prn,
                   recurrence_id,
                   --listagg(recurrence_id, '|') within GROUP(ORDER BY recurrence_id) "RECURRENCE_ID",
                   listagg(id_rel_diag, '|') within GROUP(ORDER BY id_rel_diag) "ID_REL_DIAGS"
              FROM (SELECT id_interv,
                           id_rel_diag,
                           desc_interv,
                           desc_instr,
                           execution,
                           desc_execution,
                           --dt_begin,
                           id_order_recurr_plan recurrence_id,
                           flg_prn              prn,
                           desc_prn,
                           prn_notes            prn_condition
                      FROM TABLE(l_interv_coll)) a
             GROUP BY id_interv,
                      desc_interv,
                      desc_instr,
                      execution,
                      desc_execution /*, dt_begin*/,
                      prn,
                      desc_prn,
                      recurrence_id;
    END load_standard_cplan_info;

    /**
     * Gets all the data related with a given standard plan. This method is invoked 
     * to populate the UX form when the user wants to edit a plan. This method doesn't 
     * start by "get" because it changes data.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_cplan_stand The standard plan identifier whose details we want to retrieve.
     * @param o_diags All the details of the diagnosis associated with the standard plan.
     * @param o_interv All the details of the interventions associated with the standard plan.
     * @param o_name The standard plan name.
     * @param o_notes Predefined request notes.
     * @param o_dcs The specialties list where the plan is valid.
     * @param o_soft The software list where the plan is valid.
     * 
     * @author Luis Oliveira
     * @version 2.6.1
     * @since 14/Jun/2011
    */
    PROCEDURE load_standard_cplan_info_bo
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_cplan_stand IN icnp_cplan_stand_compo.id_cplan_stand%TYPE,
        o_diags       OUT pk_types.cursor_type,
        o_interv      OUT pk_types.cursor_type,
        o_name        OUT VARCHAR2,
        o_notes       OUT VARCHAR2,
        o_dcs         OUT pk_types.cursor_type,
        o_soft        OUT pk_types.cursor_type
    ) IS
        c_func_name pk_icnp_type.t_function_name := 'LOAD_STANDARD_CPLAN_INFO';
        -- Vars to store data related with the intervention templates
        l_sel_compo table_number;
    BEGIN
        -- Debug message
        log_debug(c_func_name || '()', c_func_name);
    
        -- Gets all the data of the templates of the interventions given as input parameter
        SELECT icsc.id_cplan_stand_compo
          BULK COLLECT
          INTO l_sel_compo
          FROM icnp_cplan_stand_compo icsc
         WHERE icsc.flg_status = pk_icnp_constant.g_cp_st_compo_status_active
              --AND icsc.flg_compo_type = pk_icnp_constant.g_cp_st_compo_type_interv
           AND icsc.id_cplan_stand = i_cplan_stand;
    
        load_standard_cplan_info(i_lang, i_prof, l_sel_compo, o_diags, o_interv);
    
        -- Gets name and notes of care plan
        SELECT ics.name, ics.notes
          INTO o_name, o_notes
          FROM icnp_cplan_stand ics
         WHERE ics.id_cplan_stand = i_cplan_stand;
    
        -- Gets associated specialties list
        OPEN o_dcs FOR
            SELECT icsd.id_dep_clin_serv,
                   pk_translation.get_translation(i_lang, cs.code_clinical_service) desc_dep_clin_serv
              FROM icnp_cplan_stand_dcs icsd
              JOIN dep_clin_serv dcs
                ON icsd.id_dep_clin_serv = dcs.id_dep_clin_serv
              JOIN clinical_service cs
                ON dcs.id_clinical_service = cs.id_clinical_service
             WHERE icsd.id_cplan_stand = i_cplan_stand
             ORDER BY desc_dep_clin_serv;
    
        -- Gets associated software list
        OPEN o_soft FOR
            SELECT DISTINCT s.id_software, s.name
              FROM icnp_cplan_stand_dcs icsd
              JOIN software s
                ON icsd.id_software = s.id_software
             WHERE icsd.id_cplan_stand = i_cplan_stand
             ORDER BY name;
    
    END load_standard_cplan_info_bo;

    /********************************************************************************************
    * Get ICNP care plan intervention instructions (Configurations Area)
    *
    * @param      i_lang      Preferred language ID for this professional
    * @param      i_prof      Object (professional ID, institution ID, software ID)
    * @param      o_instr     Interventions instructions
    * @param      o_error     Error
    *
    * @return                 boolean type, "False" on error or "True" if success 
    * 
    * @raises                
    *
    * @author                  Sérgio Santos
    * @version                 2.5.1 
    * @since                   2010/05/12
    *                         
    *********************************************************************************************/
    PROCEDURE get_icnp_cplan_instr
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        o_fields     OUT pk_types.cursor_type,
        o_fields_det OUT pk_types.cursor_type
    ) IS
    BEGIN
        OPEN o_fields FOR
            SELECT ai.id_advanced_input,
                   aif.id_advanced_input_field,
                   aif.intern_name AS name,
                   pk_translation.get_translation(i_lang, aif.code_advanced_input_field) AS label,
                   aif.type,
                   aisi.flg_active,
                   (SELECT pk_message.get_message(i_lang, i_prof, aisi.error_message)
                      FROM dual) errormessage,
                   aisi.rank
              FROM advanced_input ai, advanced_input_field aif, advanced_input_soft_inst aisi
             WHERE ai.id_advanced_input = g_advanced_input_icnp_cplan
               AND aisi.id_advanced_input = ai.id_advanced_input
               AND aif.id_advanced_input_field = aisi.id_advanced_input_field
               AND aisi.id_institution IN (i_prof.institution, 0)
               AND aisi.id_software IN (i_prof.software, 0)
             ORDER BY aisi.rank;
    
        OPEN o_fields_det FOR
            SELECT ai.id_advanced_input,
                   aif.id_advanced_input_field,
                   aidet.id_advanced_input_field_det,
                   aidet.field_name,
                   NULL VALUE,
                   aif.type,
                   aidet.alignment,
                   aidet.separator,
                   aidet.style,
                   decode(aif.type, g_date_keypad, aidet.max_value, to_number(aidet.max_value)) maxvalue,
                   decode(aif.type, g_date_keypad, aidet.min_value, to_number(aidet.min_value)) minvalue,
                   (SELECT pk_message.get_message(i_lang, i_prof, aidet.format_message)
                      FROM dual) format,
                   (SELECT pk_translation.get_translation(i_lang, 'UNIT_MEASURE.CODE_UNIT_MEASURE.' || aidet.id_unit)
                      FROM dual) units
              FROM advanced_input ai
              JOIN advanced_input_soft_inst aisi
                ON ai.id_advanced_input = aisi.id_advanced_input
              JOIN advanced_input_field aif
                ON aisi.id_advanced_input_field = aif.id_advanced_input_field
              LEFT JOIN advanced_input_field_det aidet
                ON aif.id_advanced_input_field = aidet.id_advanced_input_field
             WHERE ai.id_advanced_input = g_advanced_input_icnp_cplan
               AND aisi.id_institution IN (i_prof.institution, 0)
               AND aisi.id_software IN (i_prof.software, 0)
             ORDER BY aidet.rank;
    
    END get_icnp_cplan_instr;

    /********************************************************************************************
    * Get ICNP care plan (Configurations Area)
    *
    * @param      i_lang      Preferred language ID for this professional
    * @param      i_prof      Object (professional ID, institution ID, software ID)
    * @param      i_plan      Care plan ID
    * @param      o_name      Care plan name
    * @param      o_notes     Care plan notes
    * @param      o_diags     Diagnosis
    * @param      o_results   Diagnosis expected results
    * @param      o_intervs   Interventions (intervention and instructions) 
    * @param      o_dcs       associated specialties list
    * @param      o_soft      associated softwares list
    * @param      o_error     Error
    *
    * @return                 boolean type, "False" on error or "True" if success 
    * 
    * @author                  Sérgio Santos
    * @version                 2.5.1 
    * @since                   2010/05/06
    *                         
    *********************************************************************************************/
    PROCEDURE get_icnp_cplan_view
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_plan   IN icnp_cplan_stand.id_cplan_stand%TYPE,
        o_name   OUT VARCHAR2,
        o_status OUT VARCHAR2,
        o_notes  OUT VARCHAR2,
        o_diags  OUT pk_types.cursor_type,
        o_interv OUT pk_types.cursor_type,
        o_dcs    OUT pk_types.cursor_type,
        o_soft   OUT pk_types.cursor_type
    ) IS
    BEGIN
    
        SELECT ics.name, ics.flg_status, ics.notes
          INTO o_name, o_status, o_notes
          FROM icnp_cplan_stand ics
         WHERE ics.id_cplan_stand = i_plan;
    
        OPEN o_diags FOR
            SELECT ich.id_composition_hist,
                   icsc.id_composition_parent id_diagnosis,
                   pk_icnp.desc_composition(i_lang, icsc.id_composition_parent) desc_diagnosis,
                   icsc.id_composition id_exp_result,
                   pk_icnp.desc_composition(i_lang, icsc.id_composition) desc_exp_result,
                   pk_sysdomain.get_domain(pk_icnp_constant.g_domain_compo_type,
                                           (SELECT i.flg_type
                                              FROM icnp_composition i
                                             WHERE i.id_composition = icsc.id_composition),
                                           i_lang) desc_type
              FROM icnp_cplan_stand ics
              JOIN icnp_cplan_stand_compo icsc
                ON ics.id_cplan_stand = icsc.id_cplan_stand
              JOIN icnp_composition_hist ich
                ON icsc.id_composition_parent = ich.id_composition
             WHERE icsc.flg_status = pk_icnp_constant.g_cp_st_compo_status_active
               AND icsc.flg_compo_type = pk_icnp_constant.g_cp_st_compo_type_res
               AND ics.id_cplan_stand = i_plan;
    
        OPEN o_interv FOR
            SELECT ich.id_composition_hist,
                   icsc.id_composition id_interv,
                   pk_icnp.desc_composition(i_lang, icsc.id_composition) desc_interv,
                   icsc.id_composition_parent id_rel_diag,
                   get_interv_instructions_bo(i_lang, i_prof, icsc.id_cplan_stand_compo, NULL) desc_instr,
                   icsc.flg_time execution,
                   pk_sysdomain.get_domain(pk_icnp_constant.g_domain_epis_interv_time, icsc.flg_time, i_lang) desc_execution,
                   icsc.id_order_recurr_plan recurrence_id,
                   icsc.flg_prn,
                   icsc.prn_notes
              FROM icnp_cplan_stand ics
              JOIN icnp_cplan_stand_compo icsc
                ON ics.id_cplan_stand = icsc.id_cplan_stand
              JOIN icnp_composition_hist ich
                ON icsc.id_composition = ich.id_composition
             WHERE icsc.flg_status = pk_icnp_constant.g_cp_st_compo_status_active
               AND icsc.flg_compo_type = pk_icnp_constant.g_cp_st_compo_type_interv
               AND ics.id_cplan_stand = i_plan;
    
        OPEN o_dcs FOR
            SELECT icsd.id_dep_clin_serv,
                   pk_translation.get_translation(i_lang, cs.code_clinical_service) desc_dep_clin_serv
              FROM icnp_cplan_stand_dcs icsd
              JOIN dep_clin_serv dcs
                ON icsd.id_dep_clin_serv = dcs.id_dep_clin_serv
              JOIN clinical_service cs
                ON dcs.id_clinical_service = cs.id_clinical_service
             WHERE icsd.id_cplan_stand = i_plan
             ORDER BY desc_dep_clin_serv;
    
        OPEN o_soft FOR
            SELECT DISTINCT s.id_software, s.name
              FROM icnp_cplan_stand_dcs icsd
              JOIN software s
                ON icsd.id_software = s.id_software
             WHERE icsd.id_cplan_stand = i_plan
             ORDER BY name;
    
    END get_icnp_cplan_view;

    /********************************************************************************************
    * Get ICNP care plan expected results (Configurations Area)
    * The results are diagnosis with the same focus than the i_diag provided
    *
    * @param      i_lang      Preferred language ID for this professional
    * @param      i_prof      logged professional structure
    * @param      i_diag      ICNP Diagnosis
    * @param      o_results   Diagnosis expected results
    * @param      o_error     Error
    *
    * @return                 boolean type, "False" on error or "True" if success 
    * 
    * @raises                
    *
    * @author                  Sérgio Santos
    * @version                 2.5.1 
    * @since                   2010/05/06
    *                         
    *********************************************************************************************/
    PROCEDURE get_icnp_cplan_results
    (
        i_lang    IN language.id_language%TYPE,
        i_diag    IN icnp_composition.id_composition%TYPE,
        i_prof    IN profissional,
        o_results OUT pk_types.cursor_type
    ) IS
    
        l_flg_axis VARCHAR2(20 CHAR);
    
        l_focus_term icnp_term.id_term%TYPE;
    
    BEGIN
    
        l_flg_axis := pk_icnp.get_icnp_validation_flag(i_lang, i_prof, pk_icnp_constant.g_icnp_focus);
    
        BEGIN
            SELECT it.id_term
              INTO l_focus_term
              FROM icnp_composition ic
              JOIN icnp_composition_hist ich
                ON ich.id_composition = ic.id_composition
              JOIN icnp_composition_term ict
                ON ict.id_composition = ic.id_composition
              JOIN icnp_term it
                ON it.id_term = ict.id_term
              JOIN icnp_axis ia
                ON ia.id_axis = it.id_axis
             WHERE ich.flg_most_recent = pk_alert_constant.g_yes
               AND ic.flg_type = pk_icnp_constant.g_composition_type_diagnosis
               AND ia.flg_axis = l_flg_axis
               AND ic.id_composition = i_diag
               AND ict.flg_main_focus = pk_alert_constant.g_yes;
        
        EXCEPTION
            WHEN no_data_found THEN
                OPEN o_results FOR
                    SELECT ic.id_composition id_exp_result,
                           pk_translation.get_translation(i_lang, ic.code_icnp_composition) AS desc_exp_result
                      FROM icnp_composition ic
                     WHERE ic.id_composition = g_compo_no_exp_result;
            
                RETURN;
        END;
    
        OPEN o_results FOR
            SELECT ic.id_composition id_exp_result,
                   pk_translation.get_translation(i_lang, ic.code_icnp_composition) AS desc_exp_result
              FROM icnp_composition ic
             WHERE ic.id_composition = g_compo_no_exp_result
            UNION ALL
            SELECT id_exp_result, desc_exp_result
              FROM (SELECT ic.id_composition id_exp_result,
                           pk_translation.get_translation(i_lang, ic.code_icnp_composition) AS desc_exp_result
                      FROM icnp_composition ic
                      JOIN icnp_composition_hist ich
                        ON ich.id_composition = ic.id_composition
                      JOIN icnp_composition_term ict
                        ON ict.id_composition = ic.id_composition
                     WHERE ich.flg_most_recent = pk_alert_constant.g_yes
                       AND ict.id_term = l_focus_term
                       AND ict.flg_main_focus = pk_alert_constant.g_yes
                       AND ich.flg_most_recent = pk_alert_constant.g_yes
                       AND ic.flg_type = pk_icnp_constant.g_composition_type_diagnosis
                       AND ic.id_software = i_prof.software
                       AND ic.id_institution = i_prof.institution
                       AND ic.flg_available = pk_alert_constant.g_yes
                       AND ich.flg_cancel = pk_alert_constant.g_no
                       AND ict.id_language = i_lang
                     ORDER BY desc_exp_result);
    
    END get_icnp_cplan_results;

    /**
    * Get data on diagnoses and interventions, for the grid view.
    * Based on PK_ICNP's GET_DIAG_SUMMARY and GET_INTERV_SUMMARY.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param o_diag         diagnoses cursor
    * @param o_interv       interventions cursor
    * @param o_interv_presc List of interventions that were suggested by a 
    *                       therapeutic attitude.
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/06/29
    */
    PROCEDURE get_icnp_grid
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        o_diag         OUT pk_types.cursor_type,
        o_interv       OUT pk_types.cursor_type,
        o_interv_presc OUT pk_types.cursor_type
    ) IS
        l_ss_diag         sys_shortcut.id_sys_shortcut%TYPE;
        t_interv_list     t_coll_interv_icnp_ea;
        l_code_sys_config sys_config.id_sys_config%TYPE := 'ICNP_CARE_PLAN_SCOPE';
        l_care_plan_scope VARCHAR2(1);
        l_episodes        table_number;
    
        l_has_notes sys_message.desc_message%TYPE;
    
    BEGIN
    
        l_has_notes := pk_message.get_message(i_lang, i_prof, 'COMMON_M097');
        -- retrieve diagnosis shortcut
        l_ss_diag := get_shortcut_by_intern_name(i_prof        => i_prof,
                                                 i_intern_name => pk_icnp_constant.g_ss_in_grid_icnp_diag);
        --(P- Patient , E-Episode, V-VISIT)                                        
        l_care_plan_scope := pk_sysconfig.get_config(i_code_cf => l_code_sys_config, i_prof => i_prof);
    
        CASE l_care_plan_scope
            WHEN g_icnp_care_plan_e THEN
                l_episodes := NULL;
            WHEN g_icnp_care_plan_p THEN
                SELECT e.id_episode
                  BULK COLLECT
                  INTO l_episodes
                  FROM episode e
                 WHERE e.id_patient = i_patient
                   AND e.id_episode <> i_episode;
            WHEN g_icnp_care_plan_v THEN
                SELECT e.id_episode
                  BULK COLLECT
                  INTO l_episodes
                  FROM episode e
                 WHERE e.id_visit = pk_episode.get_id_visit(i_episode)
                   AND e.id_episode <> i_episode;
        END CASE;
    
        --get interventions
        SELECT t_rec_interv_icnp_ea(id_icnp_epis_interv,
                                    NULL,
                                    get_interv_instructions(i_lang, i_prof, id_icnp_epis_interv),
                                    id_composition_interv,
                                    id_icnp_epis_diag,
                                    id_composition_diag,
                                    flg_time,
                                    status_str,
                                    status_msg,
                                    status_icon,
                                    status_flg,
                                    flg_status,
                                    flg_type,
                                    dt_next,
                                    dt_plan,
                                    id_vs,
                                    id_prof_close,
                                    dt_close,
                                    dt_icnp_epis_interv,
                                    id_prof,
                                    id_episode_origin,
                                    id_episode,
                                    id_patient,
                                    flg_status_plan,
                                    id_prof_take,
                                    notes,
                                    notes_close,
                                    dt_begin,
                                    dt_take_ea,
                                    dt_dg_last_update)
          BULK COLLECT
          INTO t_interv_list
          FROM (SELECT *
                  FROM interv_icnp_ea iea
                 WHERE iea.id_episode = i_episode
                UNION ALL
                SELECT *
                  FROM interv_icnp_ea ea
                 WHERE ea.flg_status IN
                       (pk_icnp_constant.g_epis_diag_status_active, pk_icnp_constant.g_epis_diag_status_in_progress)
                   AND ea.id_episode IN (SELECT /*+opt_estimate(table t rows=1)*/
                                          column_value
                                           FROM TABLE(l_episodes) t));
    
        --filter grouped interventions
        t_interv_list := filter_grouped_interv(t_interv_list);
    
        -- open diagnosis cursor
        OPEN o_diag FOR
            SELECT ied.id_icnp_epis_diag,
                   ied.id_composition id_diagnosis,
                   ied.icnp_compo_reeval id_exp_result,
                   ied.flg_status,
                   pk_icnp.desc_composition(i_lang, ied.id_composition) desc_diagnosis,
                   pk_icnp.desc_composition(i_lang, ied.icnp_compo_reeval) desc_exp_result,
                   get_status_str(i_lang, i_prof, g_type_diag, ied.flg_status, NULL, NULL, NULL, l_ss_diag, NULL) status_str,
                   check_permissions(i_lang,
                                     i_prof,
                                     pk_icnp_constant.g_action_subject_diag,
                                     ied.flg_status,
                                     pk_icnp_constant.g_action_diag_cancel) flg_cancel,
                   decode(ied.notes, NULL, NULL, l_has_notes) notes,
                   decode(ied.notes, NULL, NULL, ied.notes) notes_tooltip,
                   pk_icnp.get_icnp_tooltip(i_lang     => i_lang,
                                            i_prof     => i_prof,
                                            i_id_task  => ied.id_icnp_epis_diag,
                                            i_flg_type => '1',
                                            i_screen   => 1) tooltip
              FROM (SELECT *
                      FROM icnp_epis_diagnosis i
                     WHERE i.id_episode = i_episode
                    UNION
                    SELECT *
                      FROM icnp_epis_diagnosis i
                     WHERE i.id_episode IN (SELECT /*+opt_estimate(table t rows=1)*/
                                             column_value
                                              FROM TABLE(l_episodes) t)
                       AND i.flg_status = pk_alert_constant.g_active
                    UNION
                    SELECT i.*
                      FROM icnp_epis_diagnosis i
                      JOIN icnp_epis_diag_interv iedi
                        ON iedi.id_icnp_epis_diag = i.id_icnp_epis_diag
                      JOIN (SELECT /*+opt_estimate(table iea rows=1)*/
                            *
                             FROM TABLE(t_interv_list) iea) iea
                        ON iea.id_icnp_epis_interv = iedi.id_icnp_epis_interv
                     WHERE i.id_episode NOT IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                 column_value
                                                  FROM TABLE(l_episodes) t)
                       AND iedi.flg_status_rel = pk_alert_constant.g_active) ied
             ORDER BY (SELECT pk_sysdomain.get_rank(i_lang, pk_icnp_constant.g_domain_epis_diag_status, ied.flg_status)
                         FROM dual),
                      coalesce(ied.dt_last_update, ied.dt_close_tstz, ied.dt_icnp_epis_diag_tstz) DESC;
    
        -- open interventions cursor
        OPEN o_interv FOR
            SELECT /*+opt_estimate(table iea rows=1)*/
             iea.id_icnp_epis_interv,
             iea.id_icnp_epis_interv_group,
             get_interv_assoc_diag(iea.id_icnp_epis_interv) assoc_diag,
             iea.id_composition_diag id_diagnosis,
             pk_icnp.desc_composition(i_lang, iea.id_composition_diag) desc_diagnosis,
             iea.id_composition_interv id_interv,
             pk_icnp.desc_composition(i_lang, iea.id_composition_interv) desc_interv,
             iea.flg_time,
             iea.flg_status,
             g_execution_shortcut ||
             pk_utils.get_status_string(i_lang, i_prof, iea.status_str, iea.status_msg, iea.status_icon, iea.flg_status) status_str,
             get_interv_instructions(i_lang, i_prof, iea.id_icnp_epis_interv) desc_instr,
             decode(nvl(substr(iea.id_vs, 1, 1), iaa.area),
                    'VS',
                    'V',
                    'BIO',
                    'B',
                    nvl(substr(iea.id_vs, 1, 1), iaa.area)) flg_type_vs,
             nvl(substr(iea.id_vs, 3, 7),
                 decode(substr(iaa.parameter_desc, 1, 27),
                        'VITAL_SIGN.CODE_VITAL_SIGN.',
                        to_number(substr(iaa.parameter_desc, 28, length(iaa.parameter_desc))),
                        NULL)) id_vs,
             check_permissions(i_lang,
                               i_prof,
                               pk_icnp_constant.g_action_subject_interv,
                               iea.flg_status,
                               pk_icnp_constant.g_action_interv_cancel) flg_cancel,
             ic.id_doc_template,
             pk_date_utils.date_send_tsz(i_lang, iei.dt_begin_tstz, i_prof) dt_begin_tstz,
             decode((SELECT COUNT(*)
                      FROM icnp_epis_intervention i
                     WHERE i.id_icnp_epis_interv_parent = iei.id_icnp_epis_interv),
                    0,
                    pk_alert_constant.g_yes,
                    pk_alert_constant.g_no) flg_next_epis_active,
             decode(iea.notes, NULL, NULL, l_has_notes) notes,
             decode(iea.notes, NULL, NULL, iea.notes) notes_tooltip,
             pk_icnp.get_icnp_tooltip(i_lang     => i_lang,
                                      i_prof     => i_prof,
                                      i_id_task  => iea.id_icnp_epis_interv,
                                      i_flg_type => '2',
                                      i_screen   => 1) tooltip
              FROM TABLE(t_interv_list) iea
              JOIN icnp_epis_intervention iei
                ON iei.id_icnp_epis_interv = iea.id_icnp_epis_interv
              JOIN icnp_composition ic
                ON ic.id_composition = iea.id_composition_interv
              LEFT JOIN icnp_application_area iaa
                ON iaa.id_application_area = ic.id_application_area
             WHERE EXISTS
             (SELECT 1
                      FROM icnp_epis_diag_interv iedi
                     WHERE iedi.id_icnp_epis_interv = iea.id_icnp_epis_interv
                       AND iedi.flg_status_rel IN
                           (pk_icnp_constant.g_interv_rel_active, pk_icnp_constant.g_interv_rel_reactivated))
             ORDER BY (SELECT pk_sysdomain.get_rank(i_lang, pk_icnp_constant.g_domain_epis_interv_status, iea.flg_status)
                         FROM dual),
                      nvl(iea.dt_plan, iea.dt_begin),
                      iea.dt_close DESC,
                      desc_interv;
    
        -- open interventions presc cursor
        OPEN o_interv_presc FOR
            SELECT *
              FROM (SELECT /*+opt_estimate(table iea rows=1)*/
                     iea.id_icnp_epis_interv,
                     iea.id_icnp_epis_interv_group,
                     get_interv_assoc_diag(iea.id_icnp_epis_interv) assoc_diag,
                     iea.id_composition_diag id_diagnosis,
                     pk_icnp.desc_composition(i_lang, iea.id_composition_diag) desc_diagnosis,
                     iea.id_composition_interv id_interv,
                     pk_icnp.desc_composition(i_lang, iea.id_composition_interv) desc_interv,
                     iea.flg_time,
                     iea.flg_status,
                     g_execution_shortcut || pk_utils.get_status_string(i_lang,
                                                                        i_prof,
                                                                        iea.status_str,
                                                                        iea.status_msg,
                                                                        iea.status_icon,
                                                                        iea.flg_status) status_str,
                     get_interv_instructions(i_lang, i_prof, iea.id_icnp_epis_interv) desc_instr,
                     decode(nvl(substr(iea.id_vs, 1, 1), iaa.area),
                            'VS',
                            'V',
                            'BIO',
                            'B',
                            nvl(substr(iea.id_vs, 1, 1), iaa.area)) flg_type_vs,
                     nvl(to_number(substr(iea.id_vs, 2, 7)),
                         decode(substr(iaa.parameter_desc, 1, 27),
                                'VITAL_SIGN.CODE_VITAL_SIGN.',
                                to_number(substr(iaa.parameter_desc, 28, length(iaa.parameter_desc))),
                                NULL)) id_vs,
                     check_permissions(i_lang,
                                       i_prof,
                                       pk_icnp_constant.g_action_subject_interv,
                                       iea.flg_status,
                                       pk_icnp_constant.g_action_interv_cancel) flg_cancel,
                     iea.dt_next,
                     iea.dt_close,
                     ic.id_doc_template,
                     decode(iea.notes, NULL, NULL, l_has_notes) notes,
                     decode(iea.notes, NULL, NULL, iea.notes) notes_tooltip
                      FROM TABLE(t_interv_list) iea
                      JOIN icnp_composition ic
                        ON ic.id_composition = iea.id_composition_interv
                      LEFT JOIN icnp_application_area iaa
                        ON iaa.id_application_area = ic.id_application_area
                      JOIN icnp_epis_intervention iei
                        ON iei.id_icnp_epis_interv = iea.id_icnp_epis_interv
                      JOIN icnp_suggest_interv isi
                        ON isi.id_icnp_epis_interv = iea.id_icnp_epis_interv
                     WHERE NOT EXISTS
                     (SELECT 1
                              FROM icnp_epis_diag_interv iedi
                             WHERE iedi.id_icnp_epis_interv = iea.id_icnp_epis_interv
                               AND iedi.flg_status_rel IN
                                   (pk_icnp_constant.g_interv_rel_active, pk_icnp_constant.g_interv_rel_reactivated)))
             ORDER BY (SELECT pk_sysdomain.get_rank(i_lang, pk_icnp_constant.g_domain_epis_interv_status, flg_status)
                         FROM dual),
                      dt_next,
                      dt_close DESC,
                      desc_interv;
    
    END get_icnp_grid;

    /**
    * Get data for the nurse interventon suggested with prescription.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param o_task         task cursor
    * @param o_interv       interventions cursor
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Elisabete Bugalho
    * @version              2.5.1
    * @since                21-01-2011
    */
    PROCEDURE get_icnp_sug_interv
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_task    OUT pk_types.cursor_type,
        o_interv  OUT pk_types.cursor_type
    ) IS
        l_code_sys_config sys_config.id_sys_config%TYPE := 'ICNP_CARE_PLAN_SCOPE';
        l_care_plan_scope VARCHAR2(1);
        l_episodes        table_number;
    BEGIN
        --(P- Patient , E-Episode, V-Visit)                                        
        l_care_plan_scope := pk_sysconfig.get_config(i_code_cf => l_code_sys_config, i_prof => i_prof);
    
        CASE l_care_plan_scope
            WHEN g_icnp_care_plan_e THEN
                l_episodes := table_number(i_episode);
            WHEN g_icnp_care_plan_p THEN
                SELECT e.id_episode
                  BULK COLLECT
                  INTO l_episodes
                  FROM episode e
                 WHERE e.id_patient = i_patient;
            WHEN g_icnp_care_plan_v THEN
                SELECT e.id_episode
                  BULK COLLECT
                  INTO l_episodes
                  FROM episode e
                 WHERE e.id_visit = pk_episode.get_id_visit(i_episode);
        END CASE;
    
        OPEN o_task FOR
            SELECT DISTINCT isi.id_task_type || '_' || isi.id_req id_unique_requisition,
                            pk_icnp_suggestion.get_sugg_task_description(i_lang, i_prof, isi.id_req, isi.id_task_type) task_name,
                            pk_icnp_suggestion.get_sugg_task_instructions(i_lang, i_prof, isi.id_req, isi.id_task_type) task_description
              FROM icnp_suggest_interv isi
             WHERE isi.flg_status = pk_icnp_constant.g_sug_interv_status_suggested
               AND isi.id_episode IN (SELECT /*+opt_estimate(table t rows=1)*/
                                       column_value
                                        FROM TABLE(l_episodes) t);
        --AND id_patient = i_patient;
    
        OPEN o_interv FOR
            SELECT DISTINCT isi.id_task_type || '_' || isi.id_req id_unique_requisition,
                            isi.id_req id_interv_task,
                            isi.id_icnp_sug_interv,
                            ic.id_composition id_interv,
                            pk_icnp.desc_composition(i_lang, isi.id_composition) desc_interv,
                            ic.flg_type
              FROM icnp_suggest_interv isi
              JOIN icnp_composition ic
                ON isi.id_composition = ic.id_composition
             WHERE isi.flg_status = pk_icnp_constant.g_sug_interv_status_suggested
               AND isi.id_episode IN (SELECT /*+opt_estimate(table t rows=1)*/
                                       column_value
                                        FROM TABLE(l_episodes) t);
        --AND id_patient = i_patient;
    
    END get_icnp_sug_interv;

    /********************************************************************************************
    * Gets the associated diagnosis of a list of interventions
    *
    * @param      i_lang               Preferred language ID for this professional
    * @param      i_epis_interv        List of interventions
    * @param      o_diag               Diagnosis list description
    * @param      o_error              Error object
    *
    * @return                boolean type, "False" on error or "True" if success
    *
    * @raises
    *
    * @author                Sérgio Santos
    * @version               2.5.1
    * @since                 2010/08/06
    *********************************************************************************************/
    PROCEDURE get_interv_assoc_diag_desc
    (
        i_lang        IN language.id_language%TYPE,
        i_epis_interv IN table_number,
        o_diag        OUT VARCHAR2
    ) IS
        l_epis_interv_list table_number := table_number();
    BEGIN
        --distinct do array
        l_epis_interv_list := l_epis_interv_list MULTISET UNION DISTINCT i_epis_interv;
    
        --obter a descrição
        SELECT substr(concatenate(desc_diag), 1, length(concatenate(desc_diag)) - length(pk_icnp_constant.g_word_sep)) ||
               decode(concatenate(desc_diag), NULL, NULL, pk_icnp_constant.g_word_end)
          INTO o_diag
          FROM (SELECT DISTINCT pk_translation.get_translation(i_lang, ic2.code_icnp_composition) ||
                                pk_icnp_constant.g_word_sep desc_diag
                  FROM icnp_epis_diagnosis ied
                  JOIN icnp_epis_diag_interv iedi
                    ON iedi.id_icnp_epis_diag = ied.id_icnp_epis_diag
                  JOIN icnp_epis_intervention iei
                    ON iei.id_icnp_epis_interv = iedi.id_icnp_epis_interv
                  JOIN icnp_composition ic2
                    ON ic2.id_composition = ied.id_composition
                 WHERE iei.id_icnp_epis_interv IN (SELECT *
                                                     FROM TABLE(l_epis_interv_list))
                 ORDER BY desc_diag);
    
    END get_interv_assoc_diag_desc;

    /**
    * Get the intervention data used in the edition screen.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_interv       intervention identifier
    * @param o_detail       intervention cursor
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/08/03
    */
    PROCEDURE get_interv_edit
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_interv IN icnp_epis_intervention.id_icnp_epis_interv%TYPE,
        o_detail OUT pk_types.cursor_type
    ) IS
        l_transl_base_code_compo CONSTANT translation.code_translation%TYPE := 'ICNP_COMPOSITION.CODE_ICNP_COMPOSITION.';
    BEGIN
        OPEN o_detail FOR
            SELECT iei.id_icnp_epis_interv,
                   iei.id_composition,
                   pk_translation.get_translation(i_lang, l_transl_base_code_compo || iei.id_composition) interv_desc,
                   iei.flg_time to_be_performed,
                   pk_sysdomain.get_domain(pk_icnp_constant.g_domain_epis_interv_time, iei.flg_time, i_lang) to_be_performed_desc,
                   pk_date_utils.get_timestamp_str(i_lang, i_prof, iei.dt_begin_tstz, NULL) start_date,
                   pk_date_utils.date_char(i_lang, iei.dt_begin_tstz, i_prof.institution, i_prof.software) start_date_str,
                   iei.id_order_recurr_plan,
                   iei.flg_prn,
                   iei.prn_notes,
                   iei.notes,
                   get_instructions(i_lang,
                                    i_prof,
                                    iei.flg_type,
                                    iei.flg_time,
                                    iei.dt_begin_tstz,
                                    iei.id_order_recurr_plan) instructions
              FROM icnp_epis_intervention iei
             WHERE iei.id_icnp_epis_interv = i_interv;
    
    END get_interv_edit;

    /********************************************************************************************
    * Returns ICNP's intervention history
    *
    * @param      i_lang                      Preferred language ID for this professional
    * @param      i_prof                      Object (professional ID, institution ID, software ID)
    * @param      i_patient                   Patient ID
    * @param      i_interv                    Intervetion ID
    * @param      o_interv_curr               Intervention current state
    * @param      o_interv                    Intervention detail
    * @param      o_epis_doc_register         array with the detail info register
    * @param      o_epis_document_val         array with detail of documentation
    * @param      o_error                     Error
    *
    * @return                boolean type, "False" on error or "True" if success
    *
    * @author                Nuno Neves
    * @version               2.6.1
    * @since                 2011/03/23
    *********************************************************************************************/
    PROCEDURE get_interv_hist
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_patient           IN icnp_epis_intervention.id_patient%TYPE,
        i_interv            IN icnp_epis_intervention.id_icnp_epis_interv%TYPE,
        i_reports           IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_interv_curr       OUT pk_types.cursor_type,
        o_interv            OUT pk_types.cursor_type,
        o_epis_doc_register OUT pk_types.cursor_type,
        o_epis_document_val OUT pk_types.cursor_type
    ) IS
        msg_interv sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'CPLAN_T031');
        --msg_solved_at        sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'CPLAN_T205');
        --msg_created_at       sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'CPLAN_T091');
        --msg_activated_at     sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'ICNP_T182');
        --msg_cancelled_at     sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'CPLAN_T096');
        --msg_edited_at        sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'CPLAN_T093');
        --msg_suspended_at     sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'CPLAN_T097');
        --msg_executed_at      sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'ICNP_T181');
        --msg_onhold_at        sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'CPLAN_T107');
        msg_state        sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'CIPE_T041');
        msg_instr        sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'CPLAN_T032');
        msg_notes        sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'CPLAN_T058');
        msg_assoc_diag   sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'CPLAN_T107') || ' ';
        msg_cancel_res   sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'CPLAN_T094');
        msg_cancel_notes sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'CPLAN_T095');
        msg_sup_res      sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'CPLAN_T200');
        msg_sup_notes    sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'CPLAN_T076');
        --msg_execution_cancel sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'ICNP_T168');
        msg_execution_date sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'ICNP_T186');
        msg_interv_doc     sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'CIPE_T089');
        msg_therapeutic    sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'CPLAN_T204');
        msg_prn            sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'CIPE_T138') || ' ';
        msg_prn_condition  sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'CIPE_T139') || ' ';
        --msg_discontinued_at  sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'CARE_PLANS_T065');
    
        l_oldest_interv icnp_epis_intervention_hist.id_icnp_epis_interv_hist%TYPE;
    
        l_flg_task      icnp_composition.flg_task%TYPE;
        l_epis_document table_number;
        l_error         t_error_out;
    
        l_interv_hist t_tbl_interv_hist;
    
        l_tbl_icnp_epis_interv t_tbl_icnp_epis_interv;
    
        l_msg_not_applicable sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'COMMON_M018');
    
        l_tbl_interv_data tbl_interv_data := tbl_interv_data();
        l_tbl_warning     tbl_interv_data := tbl_interv_data();
        l_max_hist_rec    PLS_INTEGER := 30;
        l_count_hist_rec  PLS_INTEGER := 0;
        l_alert_prof      sys_config.value%TYPE := pk_sysconfig.get_config('ID_PROF_BACKGROUND', i_prof);
        l_warning_message sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'CPLAN_T207') || chr(10) ||
                                                           pk_message.get_message(i_lang, 'CPLAN_T208');
    
        CURSOR c_task_old IS
            SELECT ic.flg_task
              FROM icnp_composition ic, icnp_epis_intervention iei
             WHERE iei.id_icnp_epis_interv = i_interv
               AND iei.id_composition = ic.id_composition;
    
        CURSOR c_task_new IS
            SELECT decode(iaa.area, 'V1', 'VS', 'V3', 'B', 'BIO', 'B', iaa.area)
              FROM icnp_epis_intervention iei
              JOIN icnp_composition ic
                ON iei.id_composition = ic.id_composition
              JOIN icnp_application_area iaa
                ON iaa.id_application_area = ic.id_application_area
             WHERE iei.id_icnp_epis_interv = i_interv;
    BEGIN
        SELECT t_rec_icnp_epis_interv(id_icnp_epis_interv,
                                      id_patient,
                                      id_episode,
                                      id_composition,
                                      flg_status,
                                      freq,
                                      notes,
                                      id_prof,
                                      notes_close,
                                      id_prof_close,
                                      forward_interv,
                                      notes_iteraction,
                                      notes_close_iteraction,
                                      flg_time,
                                      flg_type,
                                      INTERVAL,
                                      num_take,
                                      dt_icnp_epis_interv_tstz,
                                      dt_begin_tstz,
                                      dt_end_tstz,
                                      dt_next_tstz,
                                      dt_close_tstz,
                                      flg_interval_unit,
                                      id_episode_origin,
                                      id_episode_destination,
                                      duration,
                                      flg_duration_unit,
                                      id_prof_last_update,
                                      dt_last_update,
                                      id_suspend_reason,
                                      id_suspend_prof,
                                      suspend_notes,
                                      dt_suspend,
                                      id_cancel_reason,
                                      id_cancel_prof,
                                      cancel_notes,
                                      dt_cancel,
                                      id_order_recurr_plan,
                                      flg_prn,
                                      prn_notes,
                                      id_icnp_epis_interv_parent,
                                      prev_flg_status)
          BULK COLLECT
          INTO l_tbl_icnp_epis_interv
          FROM (SELECT id_icnp_epis_interv,
                       id_patient,
                       id_episode,
                       id_composition,
                       flg_status,
                       freq,
                       notes,
                       id_prof,
                       notes_close,
                       id_prof_close,
                       forward_interv,
                       notes_iteraction,
                       notes_close_iteraction,
                       flg_time,
                       flg_type,
                       INTERVAL,
                       num_take,
                       dt_icnp_epis_interv_tstz,
                       dt_begin_tstz,
                       dt_end_tstz,
                       dt_next_tstz,
                       dt_close_tstz,
                       flg_interval_unit,
                       id_episode_origin,
                       id_episode_destination,
                       duration,
                       flg_duration_unit,
                       id_prof_last_update,
                       dt_last_update,
                       id_suspend_reason,
                       id_suspend_prof,
                       suspend_notes,
                       dt_suspend,
                       id_cancel_reason,
                       id_cancel_prof,
                       cancel_notes,
                       dt_cancel,
                       id_order_recurr_plan,
                       flg_prn,
                       prn_notes,
                       id_icnp_epis_interv_parent,
                       NULL prev_flg_status
                  FROM icnp_epis_intervention_hist ih
                 WHERE ih.id_icnp_epis_interv = i_interv
                   AND ih.flg_status NOT IN (pk_icnp_constant.g_epis_diag_status_in_progress)
                UNION ALL
                SELECT id_icnp_epis_interv,
                       id_patient,
                       id_episode,
                       id_composition,
                       flg_status,
                       freq,
                       notes,
                       id_prof,
                       notes_close,
                       id_prof_close,
                       forward_interv,
                       notes_iteraction,
                       notes_close_iteraction,
                       flg_time,
                       flg_type,
                       INTERVAL,
                       num_take,
                       dt_icnp_epis_interv_tstz,
                       dt_begin_tstz,
                       dt_end_tstz,
                       dt_next_tstz,
                       dt_close_tstz,
                       flg_interval_unit,
                       id_episode_origin,
                       id_episode_destination,
                       duration,
                       flg_duration_unit,
                       id_prof_last_update,
                       dt_last_update,
                       id_suspend_reason,
                       id_suspend_prof,
                       suspend_notes,
                       dt_suspend,
                       id_cancel_reason,
                       id_cancel_prof,
                       cancel_notes,
                       dt_cancel,
                       id_order_recurr_plan,
                       flg_prn,
                       prn_notes,
                       id_icnp_epis_interv_parent,
                       NULL prev_flg_status
                  FROM icnp_epis_intervention i
                 WHERE i.id_icnp_epis_interv = i_interv)
         ORDER BY dt_last_update ASC;
    
        OPEN c_task_old;
        FETCH c_task_old
            INTO l_flg_task;
        CLOSE c_task_old;
    
        IF l_flg_task IS NULL
        THEN
            OPEN c_task_new;
            FETCH c_task_new
                INTO l_flg_task;
            CLOSE c_task_new;
        END IF;
    
        IF l_flg_task = 'VS'
        THEN
            SELECT t_rec_interv_hist(VALUE, vs_desc, id_icnp_epis_interv, id_icnp_interv_plan, id_task)
              BULK COLLECT
              INTO l_interv_hist
              FROM (SELECT decode(vsr.id_unit_measure,
                                  vsi.id_unit_measure,
                                  to_char(vsr.value),
                                  nvl(to_char(pk_unit_measure.get_unit_mea_conversion(vsr.value,
                                                                                      vsr.id_unit_measure,
                                                                                      vsi.id_unit_measure)),
                                      to_char(vsr.value))) || pk_icnp_constant.g_word_space ||
                           pk_vital_sign.get_vital_sign_unit_measure(i_lang,
                                                                     vsr.id_unit_measure,
                                                                     vsr.id_vs_scales_element) VALUE,
                           pk_translation.get_translation(i_lang, 'VITAL_SIGN.CODE_VITAL_SIGN.' || vsr.id_vital_sign) || ': ' vs_desc,
                           task.id_icnp_epis_interv,
                           task.id_icnp_interv_plan,
                           vsr.id_vital_sign id_task
                      FROM vital_sign_read vsr,
                           vital_sign vs,
                           vs_soft_inst vsi,
                           (SELECT iei.id_icnp_epis_interv id_icnp_epis_interv,
                                   iet.id_icnp_interv_plan id_icnp_interv_plan,
                                   iet.id_task             id_task
                              FROM icnp_epis_intervention iei, icnp_composition ic, icnp_epis_task iet
                             WHERE ic.id_composition IN (SELECT iei.id_composition
                                                           FROM icnp_epis_intervention iei
                                                          WHERE iei.id_icnp_epis_interv = i_interv)
                               AND ic.id_composition = iei.id_composition
                               AND iei.id_patient = i_patient
                               AND iei.id_icnp_epis_interv = iet.id_icnp_epis_interv) task
                     WHERE vsr.id_vital_sign_read = task.id_task
                       AND vs.id_vital_sign = vsr.id_vital_sign
                       AND vs.id_vital_sign NOT IN (SELECT vr.id_vital_sign_detail
                                                      FROM vital_sign_relation vr
                                                     WHERE vr.relation_domain = 'S')
                       AND vsi.id_vital_sign = vs.id_vital_sign
                       AND vsi.id_software = i_prof.software
                       AND vsi.id_institution = i_prof.institution
                       AND vsi.flg_view = 'V2'
                       AND pk_delivery.check_vs_read_from_fetus(vsr.id_vital_sign_read) = 0
                    UNION ALL
                    SELECT DISTINCT (get_interv_hist_value(i_patient,
                                                           vsr.dt_vital_sign_read_tstz,
                                                           vsr.id_vital_sign,
                                                           vr.id_vital_sign_parent) || pk_icnp_constant.g_word_space ||
                                    pk_vital_sign.get_vital_sign_unit_measure(i_lang,
                                                                               vsr.id_unit_measure,
                                                                               vsr.id_vs_scales_element)) VALUE,
                                    pk_translation.get_translation(i_lang,
                                                                   'VITAL_SIGN.CODE_VITAL_SIGN.' || vsr.id_vital_sign) || ': ' vs_desc,
                                    task.id_icnp_epis_interv,
                                    task.id_icnp_interv_plan,
                                    vsr.id_vital_sign id_task
                      FROM vital_sign_relation vr,
                           vital_sign_read vsr,
                           (SELECT iei.id_icnp_epis_interv id_icnp_epis_interv,
                                   iet.id_icnp_interv_plan id_icnp_interv_plan,
                                   iet.id_task             id_task
                              FROM icnp_epis_intervention iei, icnp_composition ic, icnp_epis_task iet
                             WHERE ic.id_composition IN (SELECT iei.id_composition
                                                           FROM icnp_epis_intervention iei
                                                          WHERE iei.id_icnp_epis_interv = i_interv)
                               AND ic.id_composition = iei.id_composition
                               AND iei.id_patient = i_patient
                               AND iei.id_icnp_epis_interv = iet.id_icnp_epis_interv) task
                     WHERE vsr.id_vital_sign_read = task.id_task
                       AND vr.id_vital_sign_detail = vsr.id_vital_sign
                       AND vr.relation_domain = 'C'
                       AND pk_delivery.check_vs_read_from_fetus(vsr.id_vital_sign_read) = 0
                    UNION ALL
                    SELECT to_char(SUM(vsd.value)) val,
                           pk_translation.get_translation(i_lang,
                                                          'VITAL_SIGN.CODE_VITAL_SIGN.' || vr.id_vital_sign_parent) || ': ' vs_desc,
                           task.id_icnp_epis_interv,
                           task.id_icnp_interv_plan,
                           vsr.id_vital_sign id_task
                      FROM vital_sign_desc vsd,
                           vital_sign_relation vr,
                           vital_sign_read vsr,
                           (SELECT iei.id_icnp_epis_interv id_icnp_epis_interv,
                                   iet.id_icnp_interv_plan id_icnp_interv_plan,
                                   iet.id_task             id_task
                              FROM icnp_epis_intervention iei, icnp_composition ic, icnp_epis_task iet
                             WHERE ic.id_composition IN (SELECT iei.id_composition
                                                           FROM icnp_epis_intervention iei
                                                          WHERE iei.id_icnp_epis_interv = i_interv)
                               AND ic.id_composition = iei.id_composition
                               AND iei.id_patient = i_patient
                               AND iei.id_icnp_epis_interv = iet.id_icnp_epis_interv) task
                     WHERE vsr.id_vital_sign_read = task.id_task
                       AND vr.id_vital_sign_detail = vsr.id_vital_sign
                       AND vr.relation_domain = 'S'
                       AND vsd.id_vital_sign_desc = vsr.id_vital_sign_desc
                       AND pk_delivery.check_vs_read_from_fetus(vsr.id_vital_sign_read) = 0
                     GROUP BY vr.id_vital_sign_parent,
                              task.id_icnp_epis_interv,
                              task.id_icnp_interv_plan,
                              vsr.id_vital_sign);
        ELSIF l_flg_task = 'B'
        THEN
            SELECT t_rec_interv_hist(VALUE, vs_desc, id_icnp_epis_interv, id_icnp_interv_plan, id_task)
              BULK COLLECT
              INTO l_interv_hist
              FROM (SELECT DISTINCT vs.id_vital_sign id_task,
                                    decode(vsr.id_unit_measure,
                                           vsi.id_unit_measure,
                                           to_char(vsr.value),
                                           nvl(to_char(pk_unit_measure.get_unit_mea_conversion(vsr.value,
                                                                                               vsr.id_unit_measure,
                                                                                               vsi.id_unit_measure)),
                                               to_char(vsr.value))) || pk_icnp_constant.g_word_space ||
                                    pk_vital_sign.get_vital_sign_unit_measure(i_lang,
                                                                              vsr.id_unit_measure,
                                                                              vsr.id_vs_scales_element) VALUE,
                                    pk_translation.get_translation(i_lang,
                                                                   'VITAL_SIGN.CODE_VITAL_SIGN.' || vsr.id_vital_sign) || ': ' vs_desc,
                                    task.id_icnp_epis_interv,
                                    task.id_icnp_interv_plan
                      FROM vital_sign_read vsr,
                           vital_sign vs,
                           vs_soft_inst vsi,
                           (SELECT iei.id_icnp_epis_interv id_icnp_epis_interv,
                                   iet.id_icnp_interv_plan id_icnp_interv_plan,
                                   iet.id_task             id_task
                              FROM icnp_epis_intervention iei, icnp_composition ic, icnp_epis_task iet
                             WHERE ic.id_composition IN (SELECT iei.id_composition
                                                           FROM icnp_epis_intervention iei
                                                          WHERE iei.id_icnp_epis_interv = i_interv)
                               AND ic.id_composition = iei.id_composition
                               AND iei.id_patient = i_patient
                               AND iei.id_icnp_epis_interv = iet.id_icnp_epis_interv) task
                     WHERE vsr.id_vital_sign_read = task.id_task
                       AND vs.id_vital_sign = vsr.id_vital_sign
                       AND vs.id_vital_sign NOT IN (SELECT vr.id_vital_sign_detail
                                                      FROM vital_sign_relation vr
                                                     WHERE vr.relation_domain = 'S')
                       AND vsi.id_vital_sign = vs.id_vital_sign
                       AND vsi.id_software = i_prof.software
                       AND vsi.id_institution = i_prof.institution
                       AND vsi.flg_view = 'V2'
                       AND pk_delivery.check_vs_read_from_fetus(vsr.id_vital_sign_read) = 0);
        END IF;
    
        BEGIN
            SELECT id_icnp_epis_interv_hist
              INTO l_oldest_interv
              FROM (SELECT ieih.id_icnp_epis_interv_hist,
                           coalesce(ieih.dt_last_update, ieih.dt_icnp_epis_interv_tstz) dt_last_update
                      FROM icnp_epis_intervention_hist ieih
                     WHERE ieih.id_icnp_epis_interv = i_interv
                       AND ieih.flg_status IN (pk_icnp_constant.g_epis_interv_status_requested,
                                               pk_icnp_constant.g_epis_interv_status_ongoing,
                                               pk_icnp_constant.g_epis_interv_status_suspended)
                     ORDER BY dt_last_update)
             WHERE rownum <= 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_oldest_interv := NULL;
        END;
    
        OPEN o_interv_curr FOR
            SELECT *
              FROM (SELECT msg_interv || ': ' msg_interv, --msg intervenção
                           pk_translation.get_translation(i_lang, ic.code_icnp_composition) desc_interv, --desc intervencao
                           msg_state || ': ' msg_status, --msg estado
                           pk_sysdomain.get_domain(pk_icnp_constant.g_domain_epis_interv_status, i.flg_status, i_lang) desc_status, --desc estado
                           msg_instr || ': ' msg_instr, --msg instrucoes
                           get_interv_instructions(i_lang, i_prof, i.id_icnp_epis_interv) desc_instr, --desc instrucoes
                           msg_assoc_diag || pk_icnp_constant.g_word_space msg_assoc_diag, --msg diagnosticos associados
                           get_interv_rel_by_status(i_lang,
                                                    i.id_icnp_epis_interv,
                                                    table_varchar(pk_icnp_constant.g_interv_rel_active,
                                                                  pk_icnp_constant.g_interv_rel_reactivated)) desc_assoc_diag, --desc diagnosticos associados
                           decode(i.notes, NULL, NULL, msg_notes || ': ') msg_notes, --msg notas
                           i.notes desc_notes, --desc notas
                           decode(isi.id_icnp_sug_interv, NULL, NULL, msg_therapeutic || ': ') msg_therapeutic,
                           decode(isi.id_icnp_sug_interv,
                                  NULL,
                                  NULL,
                                  decode(isi.flg_status_rel,
                                         pk_icnp_constant.g_interv_rel_cancel,
                                         NULL,
                                         pk_icnp_constant.g_interv_rel_hold,
                                         NULL,
                                         pk_icnp_constant.g_interv_rel_discontinued,
                                         NULL,
                                         pk_icnp_suggestion.get_sugg_task_description(i_lang,
                                                                                      i_prof,
                                                                                      isi.id_req,
                                                                                      isi.id_task_type))) therapeutic,
                           decode(i.flg_prn, NULL, NULL, msg_prn) msg_prn, --msg_prn
                           pk_sysdomain.get_domain(pk_icnp_constant.g_domain_epis_interv_prn, i.flg_prn, i_lang) flg_prn, --flg_prn
                           CASE
                                WHEN i.prn_notes IS NULL THEN
                                 NULL
                                ELSE
                                 msg_prn_condition
                            END msg_prn_condition, --msg_prn_condition
                           i.prn_notes prn_condition, --prn_condition
                           decode(iip.dt_plan_tstz,
                                  NULL,
                                  l_msg_not_applicable,
                                  pk_date_utils.date_char_tsz(i_lang,
                                                              iip.dt_plan_tstz,
                                                              i_prof.institution,
                                                              i_prof.software)) dt_plan,
                           pk_message.get_message(i_lang => i_lang, i_code_mess => 'CIPE_T141') msg_dt_plan,
                           row_number() over(PARTITION BY iip.id_icnp_epis_interv ORDER BY iip.dt_plan_tstz) AS rn
                      FROM icnp_epis_intervention i
                      JOIN icnp_composition ic
                        ON i.id_composition = ic.id_composition
                      LEFT JOIN icnp_suggest_interv isi
                        ON isi.id_icnp_epis_interv = i.id_icnp_epis_interv
                      LEFT JOIN icnp_interv_plan iip
                        ON i.id_order_recurr_plan = iip.id_order_recurr_plan
                       AND iip.flg_status = g_interv_plan_req
                     WHERE i.id_icnp_epis_interv = i_interv) z
             WHERE z.rn = 1;
    
        FOR i IN 1 .. l_tbl_icnp_epis_interv.count
        LOOP
            IF i > 1
            THEN
                l_tbl_icnp_epis_interv(i).prev_flg_status := l_tbl_icnp_epis_interv(i - 1).flg_status;
            END IF;
        END LOOP;
    
        SELECT t_interv_data(det_type              => det_type,
                             flg_status            => flg_status,
                             dt_last_update        => dt_last_update,
                             icnp_epis_interv_hist => icnp_epis_interv_hist,
                             msg_prn               => msg_prn,
                             flg_prn               => flg_prn,
                             msg_prn_condition     => msg_prn_condition,
                             prn_condition         => prn_condition,
                             left_state            => left_state,
                             left_date             => left_date,
                             left_prof             => left_prof,
                             left_spec             => left_spec,
                             msg_interv            => msg_interv,
                             desc_interv           => desc_interv,
                             msg_status            => msg_status,
                             desc_status           => desc_status,
                             msg_instr             => msg_instr,
                             desc_instr            => desc_instr,
                             msg_assoc_diag        => msg_assoc_diag,
                             desc_assoc_diag       => desc_assoc_diag,
                             msg_notes             => msg_notes,
                             desc_notes            => desc_notes,
                             msg_therapeutic       => msg_therapeutic,
                             therapeutic           => therapeutic,
                             msg_cancel_res        => msg_cancel_res,
                             desc_cancel_res       => desc_cancel_res,
                             msg_cancel_notes      => msg_cancel_notes,
                             desc_cancel_notes     => desc_cancel_notes,
                             msg_susp_res          => msg_susp_res,
                             desc_susp_res         => desc_susp_res,
                             msg_susp_notes        => msg_susp_notes,
                             desc_susp_notes       => desc_susp_notes,
                             id_epis_documentation => id_epis_documentation,
                             prev_flg_status       => prev_flg_status)
          BULK COLLECT
          INTO l_tbl_interv_data
          FROM (SELECT *
                  FROM (SELECT 'INTERV' det_type,
                               --
                               --flg_status
                               i.flg_status flg_status,
                               --
                               --dt_last_update
                               decode(i.flg_status,
                                      pk_icnp_constant.g_epis_interv_status_suspended,
                                      coalesce(i.dt_suspend, i.dt_close_tstz, i.dt_last_update),
                                      pk_icnp_constant.g_epis_interv_status_discont,
                                      coalesce(i.dt_suspend, i.dt_close_tstz, i.dt_last_update),
                                      pk_icnp_constant.g_epis_interv_status_cancelled,
                                      coalesce(i.dt_cancel, i.dt_close_tstz, i.dt_last_update),
                                      coalesce(i.dt_last_update, i.dt_icnp_epis_interv_tstz)) dt_last_update,
                               ---
                               --icnp_epis_interv_hist
                               NULL icnp_epis_interv_hist,
                               ---
                               --msg_prn
                               decode(i.flg_prn, NULL, NULL, msg_prn) msg_prn,
                               --
                               --flg_prn
                               pk_sysdomain.get_domain(pk_icnp_constant.g_domain_epis_interv_prn, i.flg_prn, i_lang) flg_prn,
                               --
                               --msg_prn_condition
                               CASE
                                    WHEN i.prn_notes IS NULL THEN
                                     NULL
                                    ELSE
                                     msg_prn_condition
                                END msg_prn_condition,
                               --
                               --prn_condition
                               i.prn_notes prn_condition,
                               --
                               --left_state
                               get_left_state_interv(i_lang, i_prof, i.flg_status, i.prev_flg_status) left_state,
                               --
                               --left_date
                               pk_date_utils.date_char_hour_tsz(i_lang,
                                                                decode(i.flg_status,
                                                                       pk_icnp_constant.g_epis_interv_status_cancelled,
                                                                       coalesce(i.dt_cancel,
                                                                                i.dt_close_tstz,
                                                                                i.dt_last_update),
                                                                       pk_icnp_constant.g_epis_interv_status_suspended,
                                                                       coalesce(i.dt_suspend,
                                                                                i.dt_close_tstz,
                                                                                i.dt_last_update),
                                                                       pk_icnp_constant.g_epis_interv_status_discont,
                                                                       coalesce(i.dt_suspend,
                                                                                i.dt_close_tstz,
                                                                                i.dt_last_update),
                                                                       coalesce(i.dt_last_update,
                                                                                i.dt_icnp_epis_interv_tstz)),
                                                                i_prof.institution,
                                                                i_prof.software) || pk_icnp_constant.g_word_space ||
                               pk_date_utils.dt_chr_tsz(i_lang,
                                                        decode(i.flg_status,
                                                               pk_icnp_constant.g_epis_interv_status_cancelled,
                                                               coalesce(i.dt_cancel, i.dt_close_tstz, i.dt_last_update),
                                                               pk_icnp_constant.g_epis_interv_status_suspended,
                                                               coalesce(i.dt_suspend, i.dt_close_tstz, i.dt_last_update),
                                                               pk_icnp_constant.g_epis_interv_status_discont,
                                                               coalesce(i.dt_suspend, i.dt_close_tstz, i.dt_last_update),
                                                               coalesce(i.dt_last_update, i.dt_icnp_epis_interv_tstz)),
                                                        i_prof) left_date,
                               --
                               --left_prof
                               pk_prof_utils.get_name_signature(i_lang,
                                                                i_prof,
                                                                decode(i.flg_status,
                                                                       pk_icnp_constant.g_epis_interv_status_cancelled,
                                                                       coalesce(i.id_cancel_prof,
                                                                                i.id_prof_close,
                                                                                i.id_prof_last_update),
                                                                       pk_icnp_constant.g_epis_interv_status_suspended,
                                                                       coalesce(i.id_suspend_prof,
                                                                                i.id_prof_close,
                                                                                i.id_prof_last_update),
                                                                       pk_icnp_constant.g_epis_interv_status_discont,
                                                                       coalesce(i.id_suspend_prof,
                                                                                i.id_prof_close,
                                                                                i.id_prof_last_update),
                                                                       coalesce(i.id_prof_last_update, i.id_prof))) left_prof,
                               --
                               --left_spec
                               pk_prof_utils.get_spec_signature(i_lang,
                                                                i_prof,
                                                                decode(i.flg_status,
                                                                       pk_icnp_constant.g_epis_interv_status_cancelled,
                                                                       coalesce(i.id_cancel_prof,
                                                                                i.id_prof_close,
                                                                                i.id_prof_last_update),
                                                                       pk_icnp_constant.g_epis_interv_status_suspended,
                                                                       coalesce(i.id_suspend_prof,
                                                                                i.id_prof_close,
                                                                                i.id_prof_last_update),
                                                                       pk_icnp_constant.g_epis_interv_status_discont,
                                                                       coalesce(i.id_suspend_prof,
                                                                                i.id_prof_close,
                                                                                i.id_prof_last_update),
                                                                       coalesce(i.id_prof_last_update, i.id_prof)),
                                                                decode(i.flg_status,
                                                                       pk_icnp_constant.g_epis_interv_status_cancelled,
                                                                       coalesce(i.dt_cancel,
                                                                                i.dt_close_tstz,
                                                                                i.dt_last_update),
                                                                       pk_icnp_constant.g_epis_interv_status_suspended,
                                                                       coalesce(i.dt_suspend,
                                                                                i.dt_close_tstz,
                                                                                i.dt_last_update),
                                                                       pk_icnp_constant.g_epis_interv_status_discont,
                                                                       coalesce(i.dt_suspend,
                                                                                i.dt_close_tstz,
                                                                                i.dt_last_update),
                                                                       coalesce(i.dt_last_update,
                                                                                i.dt_icnp_epis_interv_tstz)),
                                                                i.id_episode) left_spec,
                               ---
                               --msg intervenção
                               decode(i.flg_status,
                                      pk_icnp_constant.g_epis_interv_status_cancelled,
                                      NULL,
                                      pk_icnp_constant.g_epis_interv_status_suspended,
                                      NULL,
                                      pk_icnp_constant.g_epis_interv_status_discont,
                                      NULL,
                                      msg_interv || ': ') msg_interv,
                               --
                               --desc intervencao
                               decode(i.flg_status,
                                      pk_icnp_constant.g_epis_interv_status_cancelled,
                                      NULL,
                                      pk_icnp_constant.g_epis_interv_status_suspended,
                                      NULL,
                                      pk_icnp_constant.g_epis_interv_status_discont,
                                      NULL,
                                      pk_translation.get_translation(i_lang, ic.code_icnp_composition)) desc_interv,
                               --
                               --msg estado
                               msg_state || ': ' msg_status,
                               --
                               --desc estado
                               pk_sysdomain.get_domain('ICNP_EPIS_INTERVENTION.FLG_STATUS', i.flg_status, i_lang) desc_status,
                               --
                               --msg instrucoes
                               decode(i.flg_status,
                                      pk_icnp_constant.g_epis_interv_status_cancelled,
                                      NULL,
                                      pk_icnp_constant.g_epis_interv_status_suspended,
                                      NULL,
                                      pk_icnp_constant.g_epis_interv_status_discont,
                                      NULL,
                                      msg_instr || ': ') msg_instr,
                               --
                               --desc instrucoes
                               decode(i.flg_status,
                                      pk_icnp_constant.g_epis_interv_status_cancelled,
                                      NULL,
                                      pk_icnp_constant.g_epis_interv_status_suspended,
                                      NULL,
                                      pk_icnp_constant.g_epis_interv_status_discont,
                                      NULL,
                                      get_instructions(i_lang,
                                                       i_prof,
                                                       i.flg_type,
                                                       i.flg_time,
                                                       i.dt_begin_tstz,
                                                       i.id_order_recurr_plan)) desc_instr,
                               --
                               --msg diagnosticos associados
                               decode(i.flg_status,
                                      pk_icnp_constant.g_epis_interv_status_cancelled,
                                      NULL,
                                      pk_icnp_constant.g_epis_interv_status_suspended,
                                      NULL,
                                      pk_icnp_constant.g_epis_interv_status_discont,
                                      NULL,
                                      msg_assoc_diag) msg_assoc_diag,
                               --     
                               --desc diagnosticos associados
                               decode(i.flg_status,
                                      pk_icnp_constant.g_epis_interv_status_cancelled,
                                      NULL,
                                      pk_icnp_constant.g_epis_interv_status_suspended,
                                      NULL,
                                      pk_icnp_constant.g_epis_interv_status_discont,
                                      NULL,
                                      get_interv_rel_by_date(i_lang,
                                                             i_prof,
                                                             i.id_icnp_epis_interv,
                                                             decode(i.flg_status,
                                                                    pk_icnp_constant.g_epis_interv_status_cancelled,
                                                                    coalesce(i.dt_cancel, i.dt_close_tstz, i.dt_last_update),
                                                                    pk_icnp_constant.g_epis_interv_status_suspended,
                                                                    coalesce(i.dt_suspend, i.dt_close_tstz, i.dt_last_update),
                                                                    coalesce(i.dt_last_update, i.dt_icnp_epis_interv_tstz)),
                                                             pk_icnp_constant.g_moment_assoc_c)) desc_assoc_diag,
                               --
                               --msg notas
                               decode(i.flg_status,
                                      pk_icnp_constant.g_epis_interv_status_cancelled,
                                      NULL,
                                      pk_icnp_constant.g_epis_interv_status_suspended,
                                      NULL,
                                      pk_icnp_constant.g_epis_interv_status_discont,
                                      NULL,
                                      decode(i.notes, NULL, NULL, msg_notes || ': ')) msg_notes,
                               --
                               --desc notas
                               decode(i.flg_status,
                                      pk_icnp_constant.g_epis_interv_status_cancelled,
                                      NULL,
                                      pk_icnp_constant.g_epis_interv_status_suspended,
                                      NULL,
                                      pk_icnp_constant.g_epis_interv_status_discont,
                                      NULL,
                                      i.notes) desc_notes,
                               --
                               --atitudes terapêuticas
                               decode(isi.id_icnp_sug_interv, NULL, NULL, msg_therapeutic || ': ') msg_therapeutic,
                               --
                               --therapeutic
                               decode(isi.id_icnp_sug_interv,
                                      NULL,
                                      NULL,
                                      pk_icnp_suggestion.get_sugg_task_description(i_lang,
                                                                                   i_prof,
                                                                                   isi.id_req,
                                                                                   isi.id_task_type)) therapeutic,
                               --
                               ---cancelados
                               decode(i.flg_status, pk_icnp_constant.g_epis_interv_status_cancelled, msg_cancel_res, NULL) msg_cancel_res,
                               --
                               --desc_cancel_res
                               decode(i.flg_status,
                                      pk_icnp_constant.g_epis_interv_status_cancelled,
                                      nvl(pk_translation.get_translation(i_lang, cr1.code_cancel_reason),
                                          pk_icnp_constant.g_word_no_record),
                                      NULL) desc_cancel_res,
                               --
                               --msg_cancel_notes
                               decode(i.flg_status,
                                      pk_icnp_constant.g_epis_interv_status_cancelled,
                                      msg_cancel_notes,
                                      NULL) msg_cancel_notes,
                               --
                               --desc_cancel_notes
                               decode(i.flg_status,
                                      pk_icnp_constant.g_epis_interv_status_cancelled,
                                      nvl(nvl(i.cancel_notes, i.notes_close), pk_icnp_constant.g_word_no_record),
                                      NULL) desc_cancel_notes,
                               --
                               ---suspensos
                               decode(i.flg_status,
                                      pk_icnp_constant.g_epis_interv_status_suspended,
                                      msg_sup_res,
                                      pk_icnp_constant.g_epis_interv_status_discont,
                                      msg_sup_res,
                                      NULL) msg_susp_res,
                               --
                               --desc_susp_res
                               decode(i.flg_status,
                                      pk_icnp_constant.g_epis_interv_status_suspended,
                                      nvl(pk_translation.get_translation(i_lang, cr2.code_cancel_reason),
                                          pk_icnp_constant.g_word_no_record),
                                      pk_icnp_constant.g_epis_interv_status_discont,
                                      nvl(pk_translation.get_translation(i_lang, cr2.code_cancel_reason),
                                          pk_icnp_constant.g_word_no_record),
                                      NULL) desc_susp_res,
                               --
                               --msg_susp_notes
                               decode(i.flg_status,
                                      pk_icnp_constant.g_epis_interv_status_suspended,
                                      msg_sup_notes,
                                      pk_icnp_constant.g_epis_interv_status_discont,
                                      msg_sup_notes,
                                      NULL) msg_susp_notes,
                               --
                               --desc_susp_notes
                               decode(i.flg_status,
                                      pk_icnp_constant.g_epis_interv_status_suspended,
                                      nvl(nvl(i.suspend_notes, i.notes_close), pk_icnp_constant.g_word_no_record),
                                      pk_icnp_constant.g_epis_interv_status_discont,
                                      nvl(nvl(i.suspend_notes, i.notes_close), pk_icnp_constant.g_word_no_record),
                                      NULL) desc_susp_notes,
                               --
                               --id_epis_documentation
                               NULL id_epis_documentation,
                               --
                               --prev_flg_status
                               i.prev_flg_status
                          FROM TABLE(l_tbl_icnp_epis_interv) i
                          JOIN icnp_composition ic
                            ON i.id_composition = ic.id_composition
                          LEFT JOIN cancel_reason cr1
                            ON cr1.id_cancel_reason = i.id_cancel_reason
                          LEFT JOIN cancel_reason cr2
                            ON cr2.id_cancel_reason = i.id_suspend_reason
                          LEFT JOIN icnp_suggest_interv isi
                            ON isi.id_icnp_epis_interv = i.id_icnp_epis_interv
                        UNION ALL
                        SELECT 'EXEC' det_type,
                               --
                               --flg_status
                               iip.flg_status flg_status,
                               --
                               --dt_last_update
                               decode(iip.flg_status,
                                      pk_icnp_constant.g_interv_plan_status_cancelled,
                                      iip.dt_cancel_tstz,
                                      nvl(iip.dt_last_update, iip.dt_take_tstz)) dt_last_update,
                               ---
                               --icnp_epis_interv_hist
                               NULL icnp_epis_interv_hist,
                               ---
                               --msg_prn
                               NULL msg_prn,
                               --
                               --flg_prn
                               NULL flg_prn,
                               --
                               --msg_prn_condition
                               NULL msg_prn_condition,
                               --
                               --prn_condition
                               NULL prn_condition,
                               ---
                               --left_state
                               get_left_state_exec(i_lang, i_prof, iip.flg_status, iip.id_icnp_interv_plan) left_state,
                               --
                               --left_date
                               pk_date_utils.date_char_hour_tsz(i_lang,
                                                                decode(iip.flg_status,
                                                                       pk_icnp_constant.g_interv_plan_status_cancelled,
                                                                       iip.dt_cancel_tstz,
                                                                       nvl(iip.dt_last_update, iip.dt_take_tstz)),
                                                                i_prof.institution,
                                                                i_prof.software) || pk_icnp_constant.g_word_space ||
                               pk_date_utils.dt_chr_tsz(i_lang,
                                                        decode(iip.flg_status,
                                                               pk_icnp_constant.g_interv_plan_status_cancelled,
                                                               iip.dt_cancel_tstz,
                                                               nvl(iip.dt_last_update, iip.dt_take_tstz)),
                                                        i_prof) left_date,
                               --
                               --left_prof
                               pk_prof_utils.get_name_signature(i_lang,
                                                                i_prof,
                                                                decode(iip.flg_status,
                                                                       pk_icnp_constant.g_interv_plan_status_cancelled,
                                                                       iip.id_prof_cancel,
                                                                       iip.id_prof_take)) left_prof,
                               --
                               --left_spec
                               pk_prof_utils.get_spec_signature(i_lang,
                                                                i_prof,
                                                                decode(iip.flg_status,
                                                                       pk_icnp_constant.g_interv_plan_status_cancelled,
                                                                       iip.id_prof_cancel,
                                                                       iip.id_prof_take),
                                                                decode(iip.flg_status,
                                                                       pk_icnp_constant.g_interv_plan_status_cancelled,
                                                                       iip.dt_cancel_tstz,
                                                                       iip.dt_take_tstz),
                                                                i.id_episode) left_spec,
                               ---
                               --msg intervenção/execução
                               decode(iip.flg_status,
                                      pk_icnp_constant.g_interv_plan_status_executed,
                                      msg_execution_date,
                                      NULL) msg_interv,
                               --
                               --desc intervencao/execução
                               decode(iip.flg_status,
                                      pk_icnp_constant.g_interv_plan_status_executed,
                                      pk_date_utils.date_char_hour_tsz(i_lang,
                                                                       iip.dt_take_tstz,
                                                                       i_prof.institution,
                                                                       i_prof.software) || pk_icnp_constant.g_word_space ||
                                      pk_date_utils.dt_chr_tsz(i_lang, iip.dt_take_tstz, i_prof),
                                      NULL) desc_interv,
                               --
                               --msg estado
                               msg_state || ': ' msg_status,
                               --
                               --desc estado
                               pk_sysdomain.get_domain('ICNP_EPIS_INTERVENTION.FLG_STATUS', iip.flg_status, i_lang) desc_status,
                               --
                               --msg instrucoes
                               decode((SELECT substr(concatenate(ttt.descr_h || ttt.value_h || pk_icnp_constant.g_word_sep),
                                                    1,
                                                    length(concatenate(ttt.descr_h || ttt.value_h ||
                                                                       pk_icnp_constant.g_word_sep)) - 2)
                                        FROM (SELECT *
                                                FROM TABLE(l_interv_hist) tt
                                               ORDER BY tt.id_vital_sign) ttt
                                       WHERE ttt.id_icnp_interv_plan = iip.id_icnp_interv_plan),
                                      NULL,
                                      NULL,
                                      msg_interv_doc || ': ') msg_instr,
                               --
                               --desc instrucoes
                               (SELECT substr(concatenate(ttt.descr_h || ttt.value_h || pk_icnp_constant.g_word_sep),
                                              1,
                                              length(concatenate(ttt.descr_h || ttt.value_h || pk_icnp_constant.g_word_sep)) - 2)
                                  FROM (SELECT *
                                          FROM TABLE(l_interv_hist) tt
                                         ORDER BY tt.id_vital_sign) ttt
                                 WHERE ttt.id_icnp_interv_plan = iip.id_icnp_interv_plan) desc_instr,
                               --
                               --msg diagnosticos associados
                               NULL msg_assoc_diag,
                               --
                               --desc diagnosticos associados
                               NULL desc_assoc_diag,
                               --
                               --msg notas
                               decode(iip.notes, NULL, NULL, msg_notes || ': ') msg_notes,
                               --
                               --desc notas
                               iip.notes desc_notes,
                               --
                               --msg_therapeutic
                               NULL msg_therapeutic,
                               --
                               --therapeutic
                               NULL therapeutic,
                               --
                               ---msg_cancel_res
                               decode(iip.flg_status,
                                      pk_icnp_constant.g_interv_plan_status_cancelled,
                                      msg_cancel_res,
                                      NULL) msg_cancel_res,
                               --
                               --desc_cancel_res
                               decode(iip.flg_status,
                                      pk_icnp_constant.g_interv_plan_status_cancelled,
                                      nvl(pk_translation.get_translation(i_lang, cr1.code_cancel_reason),
                                          pk_icnp_constant.g_word_no_record),
                                      NULL) desc_cancel_res,
                               --
                               --msg_cancel_notes
                               decode(iip.flg_status,
                                      pk_icnp_constant.g_interv_plan_status_cancelled,
                                      msg_cancel_notes,
                                      NULL) msg_cancel_notes,
                               --
                               --desc_cancel_notes
                               decode(iip.flg_status,
                                      pk_icnp_constant.g_interv_plan_status_cancelled,
                                      nvl(iip.notes_cancel, pk_icnp_constant.g_word_no_record),
                                      NULL) desc_cancel_notes,
                               --
                               --msg_susp_res
                               NULL msg_susp_res,
                               --
                               --desc_susp_res
                               NULL desc_susp_res,
                               --
                               --msg_susp_notes
                               NULL msg_susp_notes,
                               --
                               --desc_susp_notes
                               NULL desc_susp_notess,
                               --
                               --id_epis_documentation
                               iip.id_epis_documentation,
                               --
                               --prev_flg_staus
                               NULL prev_flg_staus
                          FROM icnp_interv_plan iip
                          JOIN icnp_epis_intervention i
                            ON i.id_icnp_epis_interv = iip.id_icnp_epis_interv
                          LEFT JOIN cancel_reason cr1
                            ON cr1.id_cancel_reason = iip.id_cancel_reason
                         WHERE iip.id_icnp_epis_interv = i_interv
                           AND iip.flg_status IN (pk_icnp_constant.g_interv_plan_status_executed,
                                                  pk_icnp_constant.g_interv_plan_status_cancelled)
                        UNION ALL
                        SELECT
                        --ASSOC DIAG
                         'ASSOC_DIAG' det_type,
                         --
                         --flg_status
                         NULL flg_status,
                         --
                         --dt_last_update
                         iedih.dt_hist dt_last_update,
                         ---
                         --icnp_epis_interv_hist
                         NULL icnp_epis_interv_hist,
                         ---
                         --msg_prn
                         NULL msg_prn,
                         --
                         --flg_prn
                         NULL flg_prn,
                         --
                         --msg_prn_condition
                         NULL msg_prn_condition,
                         --
                         --prn_condition
                         NULL prn_condition,
                         --
                         --left_state
                         pk_message.get_message(i_lang, 'CIPE_T142') left_state,
                         --
                         --left_date
                         pk_date_utils.date_char_hour_tsz(i_lang, iedih.dt_hist, i_prof.institution, i_prof.software) ||
                         pk_icnp_constant.g_word_space || pk_date_utils.dt_chr_tsz(i_lang, iedih.dt_hist, i_prof) left_date,
                         --
                         --left_prof
                         pk_prof_utils.get_name_signature(i_lang, i_prof, iedih.id_prof_assoc) left_prof,
                         --
                         --left_spec
                         pk_prof_utils.get_spec_signature(i_lang,
                                                          i_prof,
                                                          iedih.id_prof_assoc,
                                                          iedih.dt_hist,
                                                          iei.id_episode) left_spec,
                         ---
                         --msg intervenção
                         NULL msg_interv,
                         --
                         --desc intervencao
                         NULL desc_interv,
                         --
                         --msg estado
                         NULL msg_status,
                         --
                         --desc estado
                         NULL desc_status,
                         --
                         --msg instrucoes
                         NULL msg_instr,
                         --
                         --desc instrucoes
                         NULL desc_instr,
                         --
                         --msg diagnosticos associados
                         decode(iei.flg_status,
                                pk_icnp_constant.g_epis_interv_status_cancelled,
                                NULL,
                                pk_icnp_constant.g_epis_interv_status_suspended,
                                NULL,
                                msg_assoc_diag) msg_assoc_diag,
                         --     
                         --desc diagnosticos associados
                         decode(iei.flg_status,
                                pk_icnp_constant.g_epis_interv_status_cancelled,
                                NULL,
                                pk_icnp_constant.g_epis_interv_status_suspended,
                                NULL,
                                pk_translation.get_translation(i_lang, ic2.code_icnp_composition)
                                /*get_interv_rel_by_date(i_lang,
                                i_prof,
                                iedih.id_icnp_epis_interv,
                                iedih.dt_hist,
                                pk_icnp_constant.g_moment_assoc_a)*/) desc_assoc_diag,
                         --
                         --msg notas
                         NULL msg_notes,
                         --
                         --desc notas
                         NULL desc_notes,
                         --
                         --atitudes terapêuticas
                         NULL msg_therapeutic,
                         --
                         --therapeutic
                         NULL therapeutic,
                         --
                         ---cancelados
                         NULL msg_cancel_res,
                         --
                         --desc_cancel_res
                         NULL desc_cancel_res,
                         --
                         --msg_cancel_notes
                         NULL msg_cancel_notes,
                         --
                         --desc_cancel_notes
                         NULL desc_cancel_notes,
                         --
                         ---suspensos
                         NULL msg_susp_res,
                         --
                         --desc_susp_res
                         NULL desc_susp_res,
                         --
                         --msg_susp_notes
                         NULL msg_susp_notes,
                         --
                         --desc_susp_notes
                         NULL desc_susp_notes,
                         --
                         --id_epis_documentation
                         NULL id_epis_documentation,
                         --
                         --prev_flg_status
                         NULL flg_status
                          FROM icnp_epis_diagnosis ied
                          JOIN icnp_epis_dg_int_hist iedih
                            ON iedih.id_icnp_epis_diag = ied.id_icnp_epis_diag
                          JOIN icnp_epis_intervention iei
                            ON iei.id_icnp_epis_interv = iedih.id_icnp_epis_interv
                          JOIN icnp_composition ic2
                            ON ic2.id_composition = ied.id_composition
                         WHERE iei.id_icnp_epis_interv = i_interv
                              --AND pk_icnp_fo.trunc_timestamp_to_minutes(i_lang, i_prof, iedih.dt_hist) > iei.dt_begin_tstz
                           AND iedih.flg_iud = pk_icnp_constant.g_iedih_flg_uid_i --INSERT
                           AND iedih.flg_moment_assoc = pk_icnp_constant.g_moment_assoc_a --ASSOC
                           AND iedih.flg_status_rel = pk_icnp_constant.g_interv_rel_active
                        UNION ALL
                        SELECT
                        --relationship whith Diagnosis
                         'REL_DIAG' det_type,
                         --
                         --flg_status
                         NULL flg_status,
                         --
                         --dt_last_update
                         iedih.dt_hist dt_last_update,
                         ---
                         --icnp_epis_interv_hist
                         NULL icnp_epis_interv_hist,
                         ---
                         --msg_prn
                         NULL msg_prn,
                         --
                         --flg_prn
                         NULL flg_prn,
                         --
                         --msg_prn_condition
                         NULL msg_prn_condition,
                         --
                         --prn_condition
                         NULL prn_condition,
                         --
                         --left_state
                         decode(iedih.flg_status_rel,
                                pk_icnp_constant.g_interv_rel_cancel,
                                pk_message.get_message(i_lang, 'CIPE_M013'),
                                pk_icnp_constant.g_interv_rel_hold,
                                pk_message.get_message(i_lang, 'CIPE_M015'),
                                pk_icnp_constant.g_interv_rel_reactivated,
                                pk_message.get_message(i_lang, 'CIPE_M016'),
                                pk_icnp_constant.g_interv_rel_discontinued,
                                pk_message.get_message(i_lang, 'CIPE_M014')) left_state,
                         --
                         --left_date
                         pk_date_utils.date_char_hour_tsz(i_lang, iedih.dt_hist, i_prof.institution, i_prof.software) ||
                         pk_icnp_constant.g_word_space || pk_date_utils.dt_chr_tsz(i_lang, iedih.dt_hist, i_prof) left_date,
                         --
                         --left_prof
                         pk_prof_utils.get_name_signature(i_lang, i_prof, iedih.id_prof_assoc) left_prof,
                         --
                         --left_spec
                         pk_prof_utils.get_spec_signature(i_lang,
                                                          i_prof,
                                                          iedih.id_prof_assoc,
                                                          iedih.dt_hist,
                                                          iei.id_episode) left_spec,
                         ---
                         --msg intervenção
                         NULL msg_interv,
                         --
                         --desc intervencao
                         NULL desc_interv,
                         --
                         --msg estado
                         NULL msg_status,
                         --
                         --desc estado
                         NULL desc_status,
                         --
                         --msg instrucoes
                         NULL msg_instr,
                         --
                         --desc instrucoes
                         NULL desc_instr,
                         --
                         --msg diagnosticos associados
                         pk_message.get_message(i_lang, 'CIPE_M017') || ': ' msg_assoc_diag,
                         --     
                         --desc diagnosticos associados
                         get_interv_rel_by_status(i_lang,
                                                  iedih.id_icnp_epis_interv,
                                                  table_varchar(iedih.flg_status_rel),
                                                  iedih.id_icnp_epis_diag_interv) desc_assoc_diag,
                         --
                         --msg notas
                         NULL msg_notes,
                         --
                         --desc notas
                         NULL desc_notes,
                         --
                         --atitudes terapêuticas
                         NULL msg_therapeutic,
                         --
                         --therapeutic
                         NULL therapeutic,
                         --
                         ---cancelados
                         NULL msg_cancel_res,
                         --
                         --desc_cancel_res
                         NULL desc_cancel_res,
                         --
                         --msg_cancel_notes
                         NULL msg_cancel_notes,
                         --
                         --desc_cancel_notes
                         NULL desc_cancel_notes,
                         --
                         ---suspensos
                         NULL msg_susp_res,
                         --
                         --desc_susp_res
                         NULL desc_susp_res,
                         --
                         --msg_susp_notes
                         NULL msg_susp_notes,
                         --
                         --desc_susp_notes
                         NULL desc_susp_notes,
                         --
                         --id_epis_documentation
                         NULL id_epis_documentation,
                         --
                         --prev_flg_status
                         NULL flg_status
                          FROM icnp_epis_diagnosis ied
                          JOIN icnp_epis_dg_int_hist iedih
                            ON iedih.id_icnp_epis_diag = ied.id_icnp_epis_diag
                          JOIN icnp_epis_intervention iei
                            ON iei.id_icnp_epis_interv = iedih.id_icnp_epis_interv
                          JOIN icnp_composition ic2
                            ON ic2.id_composition = ied.id_composition
                         WHERE iei.id_icnp_epis_interv = i_interv
                           AND iedih.flg_status_rel IN
                               (pk_icnp_constant.g_interv_rel_cancel,
                                pk_icnp_constant.g_interv_rel_hold,
                                pk_icnp_constant.g_interv_rel_discontinued,
                                pk_icnp_constant.g_interv_rel_reactivated)
                        UNION ALL
                        SELECT
                        --relationship whith Therapeutic Attitudes
                         'REL_SUG' det_type,
                         --
                         --flg_status
                         NULL flg_status,
                         --
                         --dt_last_update
                         isi.dt_last_update,
                         ---
                         --icnp_epis_interv_hist
                         NULL icnp_epis_interv_hist,
                         ---
                         --msg_prn
                         NULL msg_prn,
                         --
                         --flg_prn
                         NULL flg_prn,
                         --
                         --msg_prn_condition
                         NULL msg_prn_condition,
                         --
                         --prn_condition
                         NULL prn_condition,
                         --
                         --left_state
                         decode(isi.flg_status_rel,
                                pk_icnp_constant.g_interv_rel_cancel,
                                pk_message.get_message(i_lang, 'CIPE_M013'),
                                pk_icnp_constant.g_interv_rel_hold,
                                pk_message.get_message(i_lang, 'CIPE_M015'),
                                pk_icnp_constant.g_interv_rel_reactivated,
                                pk_message.get_message(i_lang, 'CIPE_M016'),
                                pk_icnp_constant.g_interv_rel_discontinued,
                                pk_message.get_message(i_lang, 'CIPE_M014')) left_state,
                         --
                         --left_date
                         pk_date_utils.date_char_hour_tsz(i_lang, isi.dt_last_update, i_prof.institution, i_prof.software) ||
                         pk_icnp_constant.g_word_space || pk_date_utils.dt_chr_tsz(i_lang, isi.dt_last_update, i_prof) left_date,
                         --
                         --left_prof
                         pk_prof_utils.get_name_signature(i_lang, i_prof, isi.id_prof_last_update) left_prof,
                         --
                         --left_spec
                         pk_prof_utils.get_spec_signature(i_lang,
                                                          i_prof,
                                                          isi.id_prof_last_update,
                                                          isi.dt_last_update,
                                                          isi.id_episode) left_spec,
                         ---
                         --msg intervenção
                         NULL msg_interv,
                         --
                         --desc intervencao
                         NULL desc_interv,
                         --
                         --msg estado
                         NULL msg_status,
                         --
                         --desc estado
                         NULL desc_status,
                         --
                         --msg instrucoes
                         NULL msg_instr,
                         --
                         --desc instrucoes
                         NULL desc_instr,
                         --
                         --msg diagnosticos associados
                         pk_message.get_message(i_lang, 'CIPE_M018') || ': ' msg_assoc_diag,
                         --     
                         --desc diagnosticos associados
                         pk_icnp_suggestion.get_sugg_task_description(i_lang, i_prof, isi.id_req, isi.id_task_type) desc_assoc_diag,
                         --
                         --msg notas
                         NULL msg_notes,
                         --
                         --desc notas
                         NULL desc_notes,
                         --
                         --atitudes terapêuticas
                         NULL msg_therapeutic,
                         --
                         --therapeutic
                         NULL therapeutic,
                         --
                         ---cancelados
                         NULL msg_cancel_res,
                         --
                         --desc_cancel_res
                         NULL desc_cancel_res,
                         --
                         --msg_cancel_notes
                         NULL msg_cancel_notes,
                         --
                         --desc_cancel_notes
                         NULL desc_cancel_notes,
                         --
                         ---suspensos
                         NULL msg_susp_res,
                         --
                         --desc_susp_res
                         NULL desc_susp_res,
                         --
                         --msg_susp_notes
                         NULL msg_susp_notes,
                         --
                         --desc_susp_notes
                         NULL desc_susp_notes,
                         --
                         --id_epis_documentation
                         NULL id_epis_documentation,
                         --
                         --prev_flg_status
                         NULL flg_status
                          FROM icnp_suggest_interv_hist isi
                         WHERE isi.id_icnp_epis_interv = i_interv
                           AND isi.flg_status_rel IN (pk_icnp_constant.g_interv_rel_cancel,
                                                      pk_icnp_constant.g_interv_rel_hold,
                                                      pk_icnp_constant.g_interv_rel_discontinued,
                                                      pk_icnp_constant.g_interv_rel_reactivated))
                 WHERE left_state IS NOT NULL
                 ORDER BY dt_last_update DESC);
    
        --Due to flash limitations, we must limit the result set to 30 records
        --otherwise, the system may freeze  
        IF i_reports = pk_alert_constant.g_no
        THEN
            SELECT /*+ opt_estimate(table t rows=1) */
             COUNT(1)
              INTO l_count_hist_rec
              FROM TABLE(l_tbl_interv_data) t;
        
            --If the result set exceeds the limit, we must add a block that will present a warning message
            --this block must be shown at the bottom of the details
            IF l_count_hist_rec > l_max_hist_rec
            THEN
                l_tbl_warning.extend();
                l_tbl_warning(l_tbl_warning.count) := t_interv_data(det_type              => NULL,
                                                                    flg_status            => NULL,
                                                                    dt_last_update        => NULL,
                                                                    icnp_epis_interv_hist => NULL,
                                                                    msg_prn               => NULL,
                                                                    flg_prn               => NULL,
                                                                    msg_prn_condition     => NULL,
                                                                    prn_condition         => NULL,
                                                                    left_state            => pk_message.get_message(i_lang,
                                                                                                                    'COMMON_M080'),
                                                                    left_date             => NULL,
                                                                    left_prof             => pk_prof_utils.get_name_signature(i_lang,
                                                                                                                              i_prof,
                                                                                                                              l_alert_prof),
                                                                    left_spec             => NULL,
                                                                    msg_interv            => NULL,
                                                                    desc_interv           => NULL,
                                                                    msg_status            => NULL,
                                                                    desc_status           => NULL,
                                                                    msg_instr             => NULL,
                                                                    desc_instr            => NULL,
                                                                    msg_assoc_diag        => NULL,
                                                                    desc_assoc_diag       => NULL,
                                                                    msg_notes             => REPLACE(l_warning_message,
                                                                                                     '@1',
                                                                                                     l_max_hist_rec),
                                                                    desc_notes            => ' ',
                                                                    msg_therapeutic       => NULL,
                                                                    therapeutic           => NULL,
                                                                    msg_cancel_res        => NULL,
                                                                    desc_cancel_res       => NULL,
                                                                    msg_cancel_notes      => NULL,
                                                                    desc_cancel_notes     => NULL,
                                                                    msg_susp_res          => NULL,
                                                                    desc_susp_res         => NULL,
                                                                    msg_susp_notes        => NULL,
                                                                    desc_susp_notes       => NULL,
                                                                    id_epis_documentation => NULL,
                                                                    prev_flg_status       => NULL);
            END IF;
        END IF;
    
        OPEN o_interv FOR
            SELECT /*+ opt_estimate(table t rows=1) */
             t.*
              FROM TABLE(l_tbl_interv_data) t
             WHERE i_reports = pk_alert_constant.g_yes
                OR rownum <= l_max_hist_rec
            UNION ALL
            SELECT /*+ opt_estimate(table t rows=1) */
             t.*
              FROM TABLE(l_tbl_warning) t;
    
        SELECT iip.id_epis_documentation id_epis_documentation
          BULK COLLECT
          INTO l_epis_document
          FROM icnp_interv_plan iip
          JOIN icnp_epis_intervention i
            ON i.id_icnp_epis_interv = iip.id_icnp_epis_interv
          LEFT JOIN cancel_reason cr1
            ON cr1.id_cancel_reason = iip.id_cancel_reason
         WHERE iip.id_icnp_epis_interv = i_interv
           AND iip.id_epis_documentation IS NOT NULL
           AND iip.flg_status IN
               (pk_icnp_constant.g_interv_plan_status_executed, pk_icnp_constant.g_interv_plan_status_cancelled);
    
        IF l_epis_document IS NOT NULL
           AND l_epis_document.count > 0
        THEN
            FOR y IN l_epis_document.first .. l_epis_document.last
            LOOP
                IF NOT pk_touch_option.get_epis_documentation_det(i_lang,
                                                                  i_prof,
                                                                  l_epis_document,
                                                                  o_epis_doc_register,
                                                                  o_epis_document_val,
                                                                  l_error)
                
                THEN
                    pk_icnp_util.raise_unexpected_error('pk_touch_option.get_epis_documentation_det', l_error);
                END IF;
            END LOOP;
        ELSE
            pk_types.open_my_cursor(o_epis_doc_register);
            pk_types.open_my_cursor(o_epis_document_val);
        END IF;
    
    END get_interv_hist;

    /**
     * Gets the available PRN options.
     * 
     * @param i_lang The professional preferred language.
     * @param o_list The list of the available PRN options.
     * 
     * @return TRUE if sucess, FALSE otherwise.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 30/May/2011
    */
    PROCEDURE get_prn_list
    (
        i_lang IN language.id_language%TYPE,
        o_list OUT pk_types.cursor_type
    ) IS
    BEGIN
    
        OPEN o_list FOR
            SELECT s.val data,
                   s.rank,
                   s.desc_val label,
                   decode(s.val, pk_exam_constant.g_no, pk_exam_constant.g_yes, pk_exam_constant.g_no) flg_default
              FROM sys_domain s
             WHERE id_language = i_lang
               AND s.domain_owner = pk_sysdomain.k_default_schema
               AND code_domain = pk_icnp_constant.g_domain_epis_interv_prn
             ORDER BY rank;
    
    END get_prn_list;

    /**
    * Get time flag domain, for the specified softwares.
    * Based on PK_LIST.GET_EXAM_TIME.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_soft         softwares list
    * @param o_time         domains cursor
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/07/07
    */
    PROCEDURE get_time
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_soft IN table_number,
        o_time OUT pk_types.cursor_type
    ) IS
        l_flg_time      sys_config.value%TYPE;
        l_avail_domains t_coll_values_domain_mkt := t_coll_values_domain_mkt();
        l_tmp           t_coll_values_domain_mkt := t_coll_values_domain_mkt();
    BEGIN
        IF i_soft IS NOT NULL
           AND i_soft.count > 0
        THEN
            -- fill collection with default values
            SELECT t_rec_values_domain_mkt(sd.desc_val, sd.val, sd.img_name, sd.rank, sd.code_domain)
              BULK COLLECT
              INTO l_tmp
              FROM sys_domain sd
             WHERE sd.code_domain = g_domain_intv_presc_time
               AND sd.id_language = i_lang
               AND sd.domain_owner = pk_sysdomain.k_default_schema
               AND sd.flg_available = pk_alert_constant.g_yes;
        
            -- for each software, intersect options,
            -- to determine which ones are common to all softwares
            FOR i IN i_soft.first .. i_soft.last
            LOOP
                SELECT t_rec_values_domain_mkt(t.desc_val, t.val, t.img_name, t.rank, t.code_domain)
                  BULK COLLECT
                  INTO l_avail_domains
                  FROM (SELECT *
                          FROM TABLE(l_tmp)
                        INTERSECT
                        SELECT *
                          FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang,
                                                                              profissional(i_prof.id,
                                                                                           i_prof.institution,
                                                                                           i_soft(i)),
                                                                              g_domain_intv_presc_time,
                                                                              NULL))) t;
            
                l_tmp := l_avail_domains;
            END LOOP;
        END IF;
    
        l_flg_time := pk_sysconfig.get_config(i_code_cf => 'FLG_TIME_P', i_prof => i_prof);
    
        OPEN o_time FOR
            SELECT t.val data,
                   t.rank,
                   t.desc_val label,
                   decode(l_flg_time, t.val, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_default
              FROM TABLE(l_avail_domains) t;
    
    END get_time;

    /**
    * Associate diagnosis.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_diag         diagnoses identifiers list
    * @param i_interv       interventions identifiers list
    * @param o_edi_id       created icnp_epis_diag_interv ids
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/08/09
    */
    PROCEDURE set_assoc_diag
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_diag   IN table_number,
        i_interv IN table_number
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'set_assoc_diag';
        l_edi_row             icnp_epis_diag_interv%ROWTYPE;
        l_iedih_hist_row      icnp_epis_dg_int_hist%ROWTYPE;
        l_edi_row_coll        ts_icnp_epis_diag_interv.icnp_epis_diag_interv_tc;
        l_iedih_row_hist_coll ts_icnp_epis_dg_int_hist.icnp_epis_dg_int_hist_tc;
        l_edi_id              table_number := table_number();
        l_iedih_hist_id       table_number := table_number();
        l_rows                table_varchar := table_varchar();
        -- Data structures related with error handling
        l_error t_error_out;
    
        l_next_key_iedi NUMBER(24);
    
    BEGIN
        -- debug input
        log_debug('i_diag: ' || pk_utils.to_string(i_input => i_diag) || ', i_interv: ' ||
                  pk_utils.to_string(i_input => i_interv),
                  c_func_name);
    
        FOR i IN i_diag.first .. i_diag.last
        LOOP
            FOR j IN i_interv.first .. i_interv.last
            LOOP
                l_next_key_iedi := ts_icnp_epis_diag_interv.next_key;
                --ICNP_EPIS_DIAG_INTERV
                -- set values
                l_edi_row.id_icnp_epis_diag_interv := l_next_key_iedi;
                l_edi_row.id_icnp_epis_diag        := i_diag(i);
                l_edi_row.id_icnp_epis_interv      := i_interv(j);
                l_edi_row.flg_status               := pk_icnp_constant.g_iedi_st_active;
                l_edi_row.id_prof_assoc            := i_prof.id;
                l_edi_row.flg_moment_assoc         := pk_icnp_constant.g_moment_assoc_a;
                l_edi_row.flg_status_rel           := pk_icnp_constant.g_interv_rel_active;
                l_edi_row.flg_type_assoc           := pk_icnp_constant.g_flg_type_assoc_d;
                -- add id to list of created ids
                l_edi_id.extend;
                l_edi_id(l_edi_id.last) := l_edi_row.id_icnp_epis_diag_interv;
                -- add row to collection
                l_edi_row_coll(l_edi_id.last) := l_edi_row;
            
                --ICNP_EPIS_DG_INT_HIST
                -- set values
                l_iedih_hist_row.id_icnp_epis_dg_int_hist := ts_icnp_epis_dg_int_hist.next_key;
                l_iedih_hist_row.id_icnp_epis_diag_interv := l_next_key_iedi;
                l_iedih_hist_row.id_icnp_epis_diag        := i_diag(i);
                l_iedih_hist_row.id_icnp_epis_interv      := i_interv(j);
                l_iedih_hist_row.flg_status               := pk_icnp_constant.g_iedi_st_active;
                l_iedih_hist_row.dt_hist                  := current_timestamp;
                l_iedih_hist_row.flg_iud                  := pk_icnp_constant.g_iedih_flg_uid_i; --INSERT
                l_iedih_hist_row.id_prof_assoc            := i_prof.id;
                l_iedih_hist_row.flg_moment_assoc         := pk_icnp_constant.g_moment_assoc_a;
                l_iedih_hist_row.flg_status_rel           := pk_icnp_constant.g_interv_rel_active;
                l_iedih_hist_row.flg_type_assoc           := pk_icnp_constant.g_flg_type_assoc_d;
                -- add id to list of created ids
                l_iedih_hist_id.extend;
                l_iedih_hist_id(l_iedih_hist_id.last) := l_iedih_hist_row.id_icnp_epis_dg_int_hist;
                -- add row to collection
                l_iedih_row_hist_coll(l_iedih_hist_id.last) := l_iedih_hist_row;
            
            END LOOP;
        END LOOP;
    
        -- create records
        ts_icnp_epis_diag_interv.ins(rows_in => l_edi_row_coll, rows_out => l_rows);
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'ICNP_EPIS_DIAG_INTERV',
                                      i_rowids     => l_rows,
                                      o_error      => l_error);
    
        ts_icnp_epis_dg_int_hist.ins(rows_in => l_iedih_row_hist_coll, rows_out => l_rows);
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'ICNP_EPIS_DG_INT_HIST',
                                      i_rowids     => l_rows,
                                      o_error      => l_error);
    END set_assoc_diag;

    /********************************************************************************************
    * Changes the status of a ICNP care plan
    *
    * @param      i_lang      Preferred language ID for this professional
    * @param      i_prof      Object (professional ID, institution ID, software ID)
    * @param      o_error     Error
    *
    * @return                 boolean type, "False" on error or "True" if success 
    * 
    * @author                  Sérgio Santos
    * @version                 2.5.1 
    * @since                   2010/05/06
    *                         
    *********************************************************************************************/
    PROCEDURE set_icnp_cplan_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_cplan   IN icnp_cplan_stand.id_cplan_stand%TYPE,
        i_flg_status IN icnp_cplan_stand.flg_status%TYPE
    ) IS
        -- Data structures related with icnp_cplan_stand
        l_rowids table_varchar := table_varchar();
        -- Data structures related with error handling
        l_error t_error_out;
    
    BEGIN
        ts_icnp_cplan_stand.upd(id_cplan_stand_in => i_id_cplan,
                                flg_status_in     => i_flg_status,
                                flg_status_nin    => FALSE,
                                rows_out          => l_rowids);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'ICNP_CPLAN_STAND',
                                      i_rowids     => l_rowids,
                                      o_error      => l_error);
    
    END set_icnp_cplan_status;

    /**
    * Get list of available softwares.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param o_soft         softwares cursor
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/07/06
    */
    PROCEDURE get_software
    (
        i_prof IN profissional,
        o_soft OUT pk_types.cursor_type
    ) IS
    BEGIN
        OPEN o_soft FOR
            SELECT s.id_software data, s.name label, NULL icon, s.rank
              FROM software s
             WHERE s.flg_mni = pk_alert_constant.g_yes
               AND s.flg_viewer = pk_alert_constant.g_no
               AND EXISTS (SELECT 1 -- the software must be available in this institution
                      FROM software_institution si
                     WHERE si.id_software = s.id_software
                       AND si.id_institution = i_prof.institution)
               AND EXISTS (SELECT 1 -- the software must have at least one option in this domain
                      FROM sys_domain_instit_soft_dcs sdis
                     WHERE sdis.code_domain = g_domain_intv_presc_time
                       AND sdis.domain_owner = pk_sysdomain.k_default_schema
                       AND sdis.id_software = s.id_software
                       AND sdis.id_institution IN (0, i_prof.institution)
                       AND sdis.flg_action = pk_alert_constant.g_sdm_flag_add)
               AND EXISTS (SELECT 1 -- the software must have at least on specialty available
                      FROM dep_clin_serv dcs
                      JOIN department d
                        ON dcs.id_department = d.id_department
                      JOIN software_dept sd
                        ON d.id_dept = sd.id_dept
                     WHERE dcs.flg_available = pk_alert_constant.g_yes
                       AND d.id_institution = i_prof.institution
                       AND d.flg_available = pk_alert_constant.g_yes
                       AND sd.id_software = s.id_software);
    
    END get_software;

    /**
    * Get list of available departments,
    * associated with the specified softwares.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_soft         softwares list
    * @param i_search       user input for name search
    * @param o_dept         departments cursor
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/07/06
    */
    PROCEDURE get_dept
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_soft   IN table_number,
        i_search IN pk_translation.t_desc_translation,
        o_dept   OUT pk_types.cursor_type
    ) IS
        l_spec_chars   CONSTANT pk_translation.t_desc_translation := 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ';
        l_transl_chars CONSTANT pk_translation.t_desc_translation := 'AEIOUAEIOUAEIOUAOCAEIOUN';
        l_search pk_translation.t_desc_translation;
    BEGIN
        IF i_search IS NULL
        THEN
            OPEN o_dept FOR
                SELECT d.id_dept id,
                       pk_translation.get_translation(i_lang, d.code_dept) name,
                       d.abbreviation abrv,
                       pk_date_utils.date_hour_chr_extend_tsz(i_lang, d.adw_last_update, i_prof) upd_date,
                       d.flg_priority,
                       (SELECT pk_sysdomain.get_domain(g_domain_dept_urg, d.flg_priority, i_lang)
                          FROM dual) desc_priority,
                       d.flg_collection_by collection_by,
                       (SELECT pk_sysdomain.get_domain(g_domain_dept_coll, d.flg_collection_by, i_lang)
                          FROM dual) desc_collection_by
                  FROM dept d
                 WHERE d.id_institution = i_prof.institution
                   AND d.flg_available = pk_alert_constant.g_yes
                   AND EXISTS (SELECT 1
                          FROM software_dept sd
                         WHERE sd.id_dept = d.id_dept
                           AND sd.id_software IN (SELECT t.column_value id_software
                                                    FROM TABLE(i_soft) t))
                 ORDER BY name;
        
        ELSE
            l_search := '%' || translate(upper(i_search), l_spec_chars || ' ', l_transl_chars || '%') || '%';
        
            OPEN o_dept FOR
                SELECT d.id_dept id,
                       d.name,
                       d.abbreviation abrv,
                       pk_date_utils.date_hour_chr_extend_tsz(i_lang, d.adw_last_update, i_prof) upd_date,
                       d.flg_priority,
                       (SELECT pk_sysdomain.get_domain(g_domain_dept_urg, d.flg_priority, i_lang)
                          FROM dual) desc_priority,
                       d.flg_collection_by collection_by,
                       (SELECT pk_sysdomain.get_domain(g_domain_dept_coll, d.flg_collection_by, i_lang)
                          FROM dual) desc_collection_by
                  FROM (SELECT d.id_dept,
                               pk_translation.get_translation(i_lang, d.code_dept) name,
                               d.abbreviation,
                               d.adw_last_update,
                               d.flg_priority,
                               d.flg_collection_by
                          FROM dept d
                         WHERE d.id_institution = i_prof.institution
                           AND d.flg_available = pk_alert_constant.g_yes
                           AND EXISTS (SELECT 1
                                  FROM software_dept sd
                                 WHERE sd.id_dept = d.id_dept
                                   AND sd.id_software IN (SELECT t.column_value id_software
                                                            FROM TABLE(i_soft) t))) d
                 WHERE translate(upper(d.name), l_spec_chars, l_transl_chars) LIKE l_search
                 ORDER BY d.name;
        
        END IF;
    
    END get_dept;

    /**
    * Get list of diagnoses for reevaluation.
    *
    * @param i_lang         language identifier
    * @param i_prof         Professional identifier
    * @param i_patient      Patient identifier
    * @param i_diag         current diagnosis identifier
    * @param o_diags        diagnoses cursor
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/08/06
    */
    PROCEDURE get_reeval_diagnoses
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_diag      IN icnp_epis_diagnosis.id_composition%TYPE,
        i_epis_diag IN icnp_epis_diagnosis.id_icnp_epis_diag%TYPE,
        o_diags     OUT pk_types.cursor_type,
        o_interv    OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) IS
        l_compo_hist icnp_composition_hist.id_composition_hist%TYPE;
        l_gender     patient.gender%TYPE;
    
        t_interv_list t_coll_interv_icnp_ea;
        l_has_notes   sys_message.desc_message%TYPE;
    
    BEGIN
        BEGIN
            SELECT gender
              INTO l_gender
              FROM patient
             WHERE id_patient = i_patient;
        EXCEPTION
            WHEN no_data_found THEN
                l_gender := NULL;
        END;
    
        BEGIN
            SELECT ich.id_composition_hist
              INTO l_compo_hist
              FROM icnp_composition_hist ich
             WHERE ich.id_composition = i_diag;
        EXCEPTION
            WHEN no_data_found THEN
                l_compo_hist := NULL;
        END;
    
        IF l_compo_hist IS NULL
        THEN
            OPEN o_diags FOR
                SELECT *
                  FROM (SELECT id_composition id_diagnosis,
                               pk_translation.get_translation(i_lang, code_icnp_composition) desc_diagnosis,
                               get_interv_pred_by_diag(i_lang, i_prof, id_composition) interventions
                          FROM (SELECT DISTINCT ic.id_composition, ic.code_icnp_composition
                                  FROM icnp_composition ic, icnp_compo_dcs icd
                                 WHERE ic.flg_available = pk_alert_constant.g_yes
                                   AND ((i_patient IS NOT NULL AND
                                       ic.flg_gender IN (l_gender, pk_icnp_constant.g_composition_gender_both)) OR
                                       i_patient IS NULL)
                                   AND ic.flg_type = pk_icnp_constant.g_composition_type_diagnosis
                                   AND icd.id_composition = ic.id_composition
                                   AND ic.id_institution = i_prof.institution
                                   AND icd.id_dep_clin_serv IN
                                       (SELECT dcs.id_dep_clin_serv
                                          FROM dep_clin_serv dcs, department d, dept dp, software_dept sd
                                         WHERE d.id_department = dcs.id_department
                                           AND d.id_institution = i_prof.institution
                                           AND dp.id_dept = d.id_dept
                                           AND sd.id_dept = dp.id_dept
                                           AND sd.id_software = i_prof.software))
                         ORDER BY 1)
                 WHERE desc_diagnosis IS NOT NULL;
        ELSE
            OPEN o_diags FOR
                SELECT t.id_diagnosis,
                       t.desc_diagnosis,
                       pk_icnp_fo.get_interv_pred_by_diag(i_lang, i_prof, t.id_diagnosis) interventions
                  FROM (SELECT DISTINCT (SELECT id_composition
                                            FROM icnp_composition_hist ich2
                                           WHERE ich2.id_composition_hist = ich.id_composition_hist
                                             AND ich2.flg_most_recent = pk_alert_constant.g_yes) id_diagnosis,
                                         (SELECT pk_icnp.get_compo_desc_by_date(i_lang, ich.id_composition_hist, NULL)
                                            FROM dual) desc_diagnosis
                           FROM icnp_predefined_action ipa
                           JOIN icnp_predefined_action_hist ipah
                             ON ipa.id_predefined_action = ipah.id_predefined_action
                           JOIN icnp_composition ic
                             ON ipa.id_composition = ic.id_composition
                           JOIN icnp_composition_hist ich
                             ON ic.id_composition = ich.id_composition
                          WHERE ipa.id_composition_parent IN
                                (SELECT i.id_composition
                                   FROM icnp_composition_hist i
                                  WHERE i.id_composition_hist = l_compo_hist)
                            AND ipah.flg_most_recent = pk_alert_constant.g_yes
                            AND ipa.id_institution IN (pk_icnp_constant.g_institution_all, i_prof.institution)
                            AND ic.id_institution = i_prof.institution
                            AND ic.flg_type = pk_icnp_constant.g_composition_type_diagnosis
                               --It's not possible to select a diagnosis already available
                           AND ic.id_composition NOT IN (SELECT ied.id_composition
                                                           FROM icnp_epis_diagnosis ied
                                                          WHERE ied.id_composition = ic.id_composition
                                                            AND ied.id_patient = i_patient)) t
                 WHERE t.desc_diagnosis IS NOT NULL
                 ORDER BY t.desc_diagnosis;
        END IF;
    
        l_has_notes := pk_message.get_message(i_lang, i_prof, 'COMMON_M097');
    
        SELECT t_rec_interv_icnp_ea(id_icnp_epis_interv,
                                    NULL,
                                    get_interv_instructions(i_lang, i_prof, id_icnp_epis_interv),
                                    id_composition_interv,
                                    id_icnp_epis_diag,
                                    id_composition_diag,
                                    flg_time,
                                    status_str,
                                    status_msg,
                                    status_icon,
                                    status_flg,
                                    flg_status,
                                    flg_type,
                                    dt_next,
                                    dt_plan,
                                    id_vs,
                                    id_prof_close,
                                    dt_close,
                                    dt_icnp_epis_interv,
                                    id_prof,
                                    id_episode_origin,
                                    id_episode,
                                    id_patient,
                                    flg_status_plan,
                                    id_prof_take,
                                    notes,
                                    notes_close,
                                    dt_begin,
                                    dt_take_ea,
                                    dt_dg_last_update)
          BULK COLLECT
          INTO t_interv_list
          FROM (SELECT *
                  FROM interv_icnp_ea iea
                 WHERE iea.id_icnp_epis_diag = i_epis_diag
                   AND iea.flg_status IN
                       (pk_icnp_constant.g_epis_diag_status_active, pk_icnp_constant.g_epis_diag_status_in_progress));
    
        --filter grouped interventions
        t_interv_list := filter_grouped_interv(t_interv_list);
    
        OPEN o_interv FOR
            SELECT /*+opt_estimate(table iea rows=1)*/
             iea.id_icnp_epis_interv,
             iea.id_icnp_epis_interv_group,
             get_interv_assoc_diag(iea.id_icnp_epis_interv) assoc_diag,
             iea.id_composition_diag id_diagnosis,
             pk_icnp.desc_composition(i_lang, iea.id_composition_diag) desc_diagnosis,
             iea.id_composition_interv id_interv,
             pk_icnp.desc_composition(i_lang, iea.id_composition_interv) desc_interv,
             iea.flg_time,
             iea.flg_status,
             g_execution_shortcut ||
             pk_utils.get_status_string(i_lang, i_prof, iea.status_str, iea.status_msg, iea.status_icon, iea.flg_status) status_str,
             get_interv_instructions(i_lang, i_prof, iea.id_icnp_epis_interv) desc_instr,
             decode(nvl(substr(iea.id_vs, 1, 1), iaa.area),
                    'VS',
                    'V',
                    'BIO',
                    'B',
                    nvl(substr(iea.id_vs, 1, 1), iaa.area)) flg_type_vs,
             nvl(to_number(substr(iea.id_vs, 3, 7)),
                 decode(substr(iaa.parameter_desc, 1, 27),
                        'VITAL_SIGN.CODE_VITAL_SIGN.',
                        to_number(substr(iaa.parameter_desc, 28, length(iaa.parameter_desc))),
                        NULL)) id_vs,
             check_permissions(i_lang,
                               i_prof,
                               pk_icnp_constant.g_action_subject_interv,
                               iea.flg_status,
                               pk_icnp_constant.g_action_interv_cancel) flg_cancel,
             ic.id_doc_template,
             pk_date_utils.date_send_tsz(i_lang, iei.dt_begin_tstz, i_prof) dt_begin_tstz,
             decode((SELECT COUNT(*)
                      FROM icnp_epis_intervention i
                     WHERE i.id_icnp_epis_interv_parent = iei.id_icnp_epis_interv),
                    0,
                    pk_alert_constant.g_yes,
                    pk_alert_constant.g_no) flg_next_epis_active,
             decode(iea.notes, NULL, NULL, l_has_notes) notes,
             decode(iea.notes, NULL, NULL, iea.notes) notes_tooltip,
             pk_icnp.get_icnp_tooltip(i_lang     => i_lang,
                                      i_prof     => i_prof,
                                      i_id_task  => iea.id_icnp_epis_interv,
                                      i_flg_type => '2',
                                      i_screen   => 1) tooltip
              FROM TABLE(t_interv_list) iea
              JOIN icnp_epis_intervention iei
                ON iei.id_icnp_epis_interv = iea.id_icnp_epis_interv
              JOIN icnp_composition ic
                ON ic.id_composition = iea.id_composition_interv
              LEFT JOIN icnp_application_area iaa
                ON iaa.id_application_area = ic.id_application_area
             WHERE EXISTS
             (SELECT 1
                      FROM icnp_epis_diag_interv iedi
                     WHERE iedi.id_icnp_epis_interv = iea.id_icnp_epis_interv
                       AND iedi.flg_status_rel IN
                           (pk_icnp_constant.g_interv_rel_active, pk_icnp_constant.g_interv_rel_reactivated))
               AND ((SELECT COUNT(*)
                       FROM icnp_epis_diag_interv iedi
                      WHERE iedi.id_icnp_epis_interv = iei.id_icnp_epis_interv
                        AND iedi.flg_status_rel IN
                            (pk_icnp_constant.g_interv_rel_active, pk_icnp_constant.g_interv_rel_reactivated)) = 1)
            
             ORDER BY (SELECT pk_sysdomain.get_rank(i_lang, pk_icnp_constant.g_domain_epis_interv_status, iea.flg_status)
                         FROM dual),
                      nvl(iea.dt_plan, iea.dt_begin),
                      iea.dt_close DESC,
                      desc_interv;
    
    END get_reeval_diagnoses;

    /**
     * Creates a new temporary recurrence plan to be used in the create intervention 
     * method. This method is used when there is the need to create new interventions
     * that were requested in a past episode to be executed in the next episode.
     * The new plan data must be based in the original type / recurrence. Because
     * the frequency "once" and "no schedule" doesn't has a corresponding final 
     * recurrence, we need to create a new one from scratch.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_flg_type The original intervention type.
     * @param i_order_recurr_plan The original recurrence identifier.
     * 
     * @return The new temporary order recurrence plan identifier.
     *
     * @author Luis Oliveira
     * @version 1.0
     * @since 29/Ago/2011 (v2.6.1)
    */
    FUNCTION create_recurrence_plan_by_type
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_flg_type          IN icnp_epis_intervention.flg_type%TYPE,
        i_order_recurr_plan IN icnp_epis_intervention.id_order_recurr_plan%TYPE
    ) RETURN icnp_epis_intervention.id_order_recurr_plan%TYPE IS
        -- Constants
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'create_recurrence_plan_by_type';
        -- Used variables
        l_order_recurr_option order_recurr_plan.id_order_recurr_option%TYPE;
        l_order_recurr_plan   order_recurr_plan.id_order_recurr_plan%TYPE;
        l_error               t_error_out;
        -- Non used variables (output of the recurrence methods)
        l_order_recurr_desc   VARCHAR2(1000 CHAR);
        l_start_date          VARCHAR2(1000 CHAR);
        l_occurrences         order_recurr_plan.occurrences%TYPE;
        l_duration            order_recurr_plan.duration%TYPE;
        l_unit_meas_duration  order_recurr_plan.id_unit_meas_duration%TYPE;
        l_end_date            VARCHAR2(1000 CHAR);
        l_flg_end_by_editable VARCHAR2(1000 CHAR);
        l_duration_desc       VARCHAR2(1000 CHAR);
    BEGIN
        log_debug(c_func_name || '()', c_func_name);
    
        -- Check the input parameters
        IF i_flg_type NOT IN (pk_icnp_constant.g_epis_interv_type_once,
                              pk_icnp_constant.g_epis_interv_type_no_schedule,
                              pk_icnp_constant.g_epis_interv_type_recurrence)
        THEN
            pk_alert_exceptions.raise_error(error_name_in => pk_icnp_constant.g_excep_inv_input_params,
                                            text_in       => 'The intervention type (' || i_flg_type || ') is not valid');
        END IF;
    
        IF i_flg_type = pk_icnp_constant.g_epis_interv_type_once
           OR i_flg_type = pk_icnp_constant.g_epis_interv_type_no_schedule
        THEN
            -- Create a temporary recurrence plan
            IF NOT pk_order_recurrence_api_db.create_order_recurr_plan(i_lang                => i_lang,
                                                                       i_prof                => i_prof,
                                                                       i_order_recurr_area   => pk_icnp_constant.g_order_recurr_area,
                                                                       o_order_recurr_desc   => l_order_recurr_desc,
                                                                       o_order_recurr_option => l_order_recurr_option,
                                                                       o_start_date          => l_start_date,
                                                                       o_occurrences         => l_occurrences,
                                                                       o_duration            => l_duration,
                                                                       o_unit_meas_duration  => l_unit_meas_duration,
                                                                       o_end_date            => l_end_date,
                                                                       o_flg_end_by_editable => l_flg_end_by_editable,
                                                                       o_order_recurr_plan   => l_order_recurr_plan,
                                                                       o_error               => l_error)
            THEN
                pk_icnp_util.raise_unexpected_error('pk_order_recurrence_api_db.create_order_recurr_plan', l_error);
            END IF;
        
            -- Determine the recurrence option by the flag type
            IF i_flg_type = pk_icnp_constant.g_epis_interv_type_once
            THEN
                l_order_recurr_option := pk_alert_constant.g_order_recurr_option_once;
            ELSIF i_flg_type = pk_icnp_constant.g_epis_interv_type_no_schedule
            THEN
                l_order_recurr_option := pk_alert_constant.g_order_recurr_option_no_sched;
            END IF;
        
            -- Set the correct recurrence option
            IF NOT pk_order_recurrence_api_db.set_order_recurr_option(i_lang                => i_lang,
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
                                                                      o_error               => l_error)
            THEN
                pk_icnp_util.raise_unexpected_error('pk_order_recurrence_api_ux.set_order_recurr_option', l_error);
            END IF;
        
        ELSIF i_flg_type = pk_icnp_constant.g_epis_interv_type_recurrence
        THEN
            -- Create a new recurrence plan based in an existing one
            IF NOT pk_order_recurrence_api_db.copy_from_order_recurr_plan(i_lang                   => i_lang,
                                                                          i_prof                   => i_prof,
                                                                          i_order_recurr_area      => pk_icnp_constant.g_order_recurr_area,
                                                                          i_order_recurr_plan_from => i_order_recurr_plan,
                                                                          o_order_recurr_desc      => l_order_recurr_desc,
                                                                          o_order_recurr_option    => l_order_recurr_option,
                                                                          o_start_date             => l_start_date,
                                                                          o_occurrences            => l_occurrences,
                                                                          o_duration               => l_duration,
                                                                          o_unit_meas_duration     => l_unit_meas_duration,
                                                                          o_duration_desc          => l_duration_desc,
                                                                          o_end_date               => l_end_date,
                                                                          o_flg_end_by_editable    => l_flg_end_by_editable,
                                                                          o_order_recurr_plan      => l_order_recurr_plan,
                                                                          o_error                  => l_error)
            THEN
                pk_icnp_util.raise_unexpected_error('pk_order_recurrence_api_db.copy_from_order_recurr_plan', l_error);
            END IF;
        
        END IF;
    
        log_debug('l_order_recurr_plan: ' || l_order_recurr_plan, c_func_name);
        RETURN l_order_recurr_plan;
    
    END create_recurrence_plan_by_type;

    /**
    * Creates interventions for "this episode", given the interventions
    * for the "next episode", set on a previous visit.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_past_episode past episode identifier
    * @param i_next_episode next episode identifier (the one being registered)
    * @param i_sysdate_tstz Current timestamp that should be used across all the 
    *                       functions invoked from this one.
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/08/19
    */
    PROCEDURE create_interv_next_epis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_past_episode IN episode.id_episode%TYPE,
        i_next_episode IN episode.id_episode%TYPE,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        l_dt_begin             sys_config.value%TYPE;
        l_interv               table_table_varchar := table_table_varchar();
        l_interv_id            table_number := table_number();
        l_rows                 table_varchar := table_varchar();
        l_iei_upd              table_varchar := table_varchar();
        l_order_recurr_plan_id icnp_epis_intervention.id_order_recurr_plan%TYPE;
        l_error                t_error_out;
    
        CURSOR c_next IS
            SELECT iei.id_icnp_epis_interv,
                   iei.id_patient,
                   iei.id_composition,
                   iei.flg_type,
                   iei.notes,
                   iei.id_prof,
                   iei.id_order_recurr_plan,
                   iei.flg_prn,
                   iei.prn_notes,
                   (SELECT ea.id_icnp_epis_diag
                      FROM interv_icnp_ea ea
                     WHERE ea.id_icnp_epis_interv = iei.id_icnp_epis_interv) id_icnp_epis_diag
              FROM icnp_epis_intervention iei
             WHERE iei.id_episode = i_past_episode
               AND iei.id_episode_destination IS NULL
               AND iei.flg_time = pk_alert_constant.g_flg_time_n
               AND iei.flg_status IN
                   (pk_icnp_constant.g_epis_interv_status_requested, pk_icnp_constant.g_epis_interv_status_ongoing);
    
        TYPE t_coll_next IS TABLE OF c_next%ROWTYPE;
        l_next      c_next%ROWTYPE;
        l_coll_next t_coll_next;
    BEGIN
        -- Serialize the date
        l_dt_begin := pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => i_sysdate_tstz, i_prof => i_prof);
    
        -- retrieve applicable interventions data
        OPEN c_next;
        FETCH c_next BULK COLLECT
            INTO l_coll_next;
        CLOSE c_next;
    
        IF l_coll_next IS NULL
           OR l_coll_next.count < 1
        THEN
            RETURN;
        END IF;
    
        FOR i IN l_coll_next.first .. l_coll_next.last
        LOOP
            l_next := l_coll_next(i);
        
            -- Create a new temporary recurrence plan to be used in the create intervention method
            l_order_recurr_plan_id := create_recurrence_plan_by_type(i_lang              => i_lang,
                                                                     i_prof              => i_prof,
                                                                     i_flg_type          => l_next.flg_type,
                                                                     i_order_recurr_plan => l_next.id_order_recurr_plan);
        
            -- create "next episode" intervention
            l_interv := table_table_varchar(table_varchar(to_char(l_next.id_composition), -- c_idx_ci_compo_interv_id
                                                          NULL, -- c_idx_ci_compo_diag_id
                                                          pk_icnp_constant.g_epis_interv_time_curr_epis, -- c_idx_ci_flg_time
                                                          l_dt_begin, -- c_idx_ci_dt_begin
                                                          l_order_recurr_plan_id, -- c_idx_ci_recurr_id
                                                          l_next.flg_prn, -- c_idx_ci_flg_prn
                                                          l_next.prn_notes, -- c_idx_ci_prn_notes
                                                          l_next.notes -- c_idx_ci_notes
                                                          ));
        
            -- CALL create_icnp_interv_int
            create_icnp_interv(i_lang     => i_lang,
                               i_prof     => profissional(l_next.id_prof, i_prof.institution, i_prof.software),
                               i_episode  => i_next_episode,
                               i_patient  => l_next.id_patient,
                               i_diag     => NULL,
                               i_exp_res  => NULL,
                               i_notes    => NULL,
                               i_interv   => l_interv,
                               i_cur_diag => l_next.id_icnp_epis_diag,
                               -- :TODO:
                               --i_epis_origin => i_past_episode,
                               i_sysdate_tstz => i_sysdate_tstz,
                               o_interv_id    => l_interv_id);
            pk_alertlog.log_debug('l_interv_id: ' || pk_utils.to_string(i_input => l_interv_id));
        
            -- update guideline related processes
            UPDATE guideline_process_task gpt
               SET gpt.id_request = l_interv_id(1), gpt.dt_request = current_timestamp
             WHERE gpt.flg_status_last IN (pk_guidelines.g_process_scheduled, pk_guidelines.g_process_running)
               AND gpt.task_type = pk_guidelines.g_task_enfint
               AND gpt.id_request = l_next.id_icnp_epis_interv;
        
            -- update protocol related processes
            UPDATE protocol_process_element ppe
               SET ppe.id_request = l_interv_id(1), ppe.dt_request = current_timestamp
             WHERE ppe.flg_status IN (pk_protocol.g_process_scheduled, pk_protocol.g_process_running)
               AND ppe.element_type = pk_protocol.g_element_task
               AND ppe.id_protocol_task IN (SELECT pt.id_protocol_task
                                              FROM protocol_task pt
                                             WHERE pt.task_type = pk_protocol.g_task_enfint)
               AND ppe.id_request = l_next.id_icnp_epis_interv;
        
            -- update "past episode" intervention
            ts_icnp_epis_intervention.upd(id_icnp_epis_interv_in     => l_next.id_icnp_epis_interv,
                                          id_episode_destination_in  => i_next_episode,
                                          id_episode_destination_nin => FALSE,
                                          rows_out                   => l_rows);
            -- append rowids
            l_iei_upd := l_iei_upd MULTISET UNION ALL l_rows;
        END LOOP;
    
        -- Send the data gov events
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'ICNP_EPIS_INTERVENTION',
                                      i_rowids       => l_iei_upd,
                                      o_error        => l_error,
                                      i_list_columns => table_varchar('ID_EPISODE_DESTINATION'));
    
    END create_interv_next_epis;

    /**
    * Returns the flg_status of the prior id_icnp_epis_diagnosis_hist provided.
    *
    * @param i_id_icnp_epis_diagnosis   icnp diagnosis id
    * @param id_interv_hist             Base interv_hist
    *
    * @return               flg_status of icnp diagnosis previous that was provided
    *
    * @author               Nuno Neves
    * @version              2.5.1.7
    * @since                2011/09/09
    */
    FUNCTION get_diag_prior_status
    (
        i_id_icnp_epis_diag icnp_epis_diagnosis.id_icnp_epis_diag%TYPE,
        i_id_interv_hist    icnp_epis_diagnosis_hist.id_icnp_epis_diag_hist%TYPE
    ) RETURN icnp_epis_diagnosis_hist.flg_status%TYPE IS
        l_previous_status icnp_epis_diagnosis_hist.flg_status%TYPE;
    
        l_hist_date icnp_epis_diagnosis_hist.dt_last_update%TYPE;
    BEGIN
        IF i_id_interv_hist IS NULL
        THEN
            l_hist_date := current_timestamp;
        ELSE
            SELECT i.dt_last_update
              INTO l_hist_date
              FROM icnp_epis_diagnosis_hist i
             WHERE i.id_icnp_epis_diag_hist = i_id_interv_hist
               AND i.id_icnp_epis_diag = i_id_icnp_epis_diag;
        END IF;
    
        SELECT t.flg_status
          INTO l_previous_status
          FROM (SELECT i.flg_status, i.dt_last_update
                  FROM icnp_epis_diagnosis_hist i
                 WHERE i.dt_last_update < l_hist_date
                   AND i.id_icnp_epis_diag = i_id_icnp_epis_diag
                 ORDER BY i.dt_last_update DESC) t
         WHERE rownum <= 1;
    
        RETURN l_previous_status;
    END;

    FUNCTION get_perform_desc
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_flg_time             IN icnp_epis_intervention.flg_time%TYPE,
        i_id_order_recurr_plan IN icnp_epis_intervention.id_order_recurr_plan%TYPE
    ) RETURN pk_icnp_type.t_instruction_desc IS
        l_perform_desc pk_icnp_type.t_instruction_desc := '';
    BEGIN
        /*l_perform_desc := get_message_and_cache(i_lang, i_prof, pk_icnp_constant.mcodet_to_be_exec, l_messages_col) ||
        pk_icnp_constant.g_word_space;*/
        IF i_flg_time IS NOT NULL
        THEN
            l_perform_desc :=    --l_perform_desc ||
             pk_sysdomain.get_domain(pk_icnp_constant.g_domain_epis_interv_time, i_flg_time, i_lang);
        ELSE
            l_perform_desc := l_perform_desc || pk_icnp_constant.g_word_no_record;
        END IF;
        RETURN l_perform_desc;
    END get_perform_desc;

    -- Gets the text with the frequency of the executions
    FUNCTION get_frequency_desc
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_flg_type             IN icnp_epis_intervention.flg_type%TYPE,
        i_id_order_recurr_plan IN icnp_epis_intervention.id_order_recurr_plan%TYPE
    ) RETURN pk_icnp_type.t_instruction_desc IS
        l_frequency_desc pk_icnp_type.t_instruction_desc := '';
        l_message        sys_message.desc_message%TYPE;
    BEGIN
        --l_message := get_message_and_cache(i_lang, i_prof, pk_icnp_constant.mcodet_frequency, l_messages_col);
        IF i_flg_type = pk_icnp_constant.g_epis_interv_type_once
        THEN
            l_frequency_desc := l_message || pk_icnp_constant.g_word_space ||
                                pk_translation.get_translation(i_lang, 'ORDER_RECURR_OPTION.CODE_ORDER_RECURR_OPTION.0');
        ELSIF i_flg_type = pk_icnp_constant.g_epis_interv_type_no_schedule
        THEN
            l_frequency_desc := l_message || pk_icnp_constant.g_word_space ||
                                pk_translation.get_translation(i_lang,
                                                               'ORDER_RECURR_OPTION.CODE_ORDER_RECURR_OPTION.-2');
        ELSIF i_flg_type = pk_icnp_constant.g_epis_interv_type_recurrence
        THEN
            l_frequency_desc := l_message || pk_icnp_constant.g_word_space ||
                                pk_order_recurrence_api_db.get_order_recurr_plan_desc(i_lang              => i_lang,
                                                                                      i_prof              => i_prof,
                                                                                      i_order_recurr_plan => i_id_order_recurr_plan);
        END IF;
    
        RETURN l_frequency_desc;
    END get_frequency_desc;

    -- Gets the text that describes when the task should be performed
    FUNCTION get_start_date_desc
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_dt_begin IN icnp_epis_intervention.dt_begin_tstz%TYPE
    ) RETURN pk_icnp_type.t_instruction_desc IS
        l_dt_begin_desc pk_icnp_type.t_instruction_desc := '';
    BEGIN
        /* l_dt_begin_desc := get_message_and_cache(i_lang, i_prof, pk_icnp_constant.mcodet_start_date, l_messages_col) ||
                               pk_icnp_constant.g_word_space;
        */
        IF i_dt_begin IS NOT NULL
        THEN
            l_dt_begin_desc := l_dt_begin_desc ||
                               pk_date_utils.date_char_tsz(i_lang, i_dt_begin, i_prof.institution, i_prof.software);
        ELSE
            l_dt_begin_desc := l_dt_begin_desc || pk_icnp_constant.g_word_no_record;
        END IF;
        RETURN l_dt_begin_desc;
    END get_start_date_desc;

    /**
     * Load needed info about intervention and it's instructions
     * This method gets all the data needed to update de recurrence. interventions and it's instructions
     * 
     * @param i_lang                      The professional preferred language.
     * @param i_prof                      The professional context [id user, id institution, id software].
     * @param i_id_icnp_epis_interv       The icnp_epis_intervention identifier whose details we want to retrieve. 
     *
     * @param o_interv All the details of the selected interventions needed to populate
     *                the UX form.
     * 
     * @author Nuno Neves
     * @version 2.5.1.8.2
     * @since 10/10/2011
    */
    PROCEDURE load_icnp_info
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_icnp_epis_interv IN icnp_epis_intervention.id_icnp_epis_interv%TYPE,
        o_interv              OUT pk_types.cursor_type
    ) IS
        c_func_name pk_icnp_type.t_function_name := 'LOAD_EDIT_ICNP_INFO';
        -- Vars to store data related with the recurrence
        l_flg_time             icnp_epis_intervention.flg_time%TYPE;
        l_flg_type             icnp_epis_intervention.flg_type%TYPE;
        l_id_order_recurr_plan icnp_epis_intervention.id_order_recurr_plan%TYPE;
        l_dt_begin             icnp_epis_intervention.dt_begin_tstz%TYPE;
    
        l_r_plan t_recurr_plan_info_rec := t_recurr_plan_info_rec(NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
    
        l_count_flg_time INTEGER;
        l_dt_take        TIMESTAMP WITH LOCAL TIME ZONE;
    
        -- Data structures related with error handling
        l_error t_error_out;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '()', c_func_name);
    
        -- Check the input parameters
        IF i_id_icnp_epis_interv IS NULL
        THEN
            pk_alert_exceptions.raise_error(error_name_in => pk_icnp_constant.g_excep_inv_input_params,
                                            text_in       => 'The compositions given as input parameter is empty');
        END IF;
    
        SELECT iei.id_order_recurr_plan, iei.flg_time, iei.flg_type, iei.dt_begin_tstz
          INTO l_id_order_recurr_plan, l_flg_time, l_flg_type, l_dt_begin
          FROM icnp_epis_intervention iei
         WHERE iei.id_icnp_epis_interv = i_id_icnp_epis_interv;
    
        SELECT COUNT(*)
          INTO l_count_flg_time
          FROM icnp_interv_plan iip
         WHERE iip.id_icnp_epis_interv = i_id_icnp_epis_interv
           AND iip.flg_status IN
               (pk_icnp_constant.g_interv_plan_status_executed, pk_icnp_constant.g_interv_plan_status_cancelled);
    
        BEGIN
            SELECT iip.dt_take_tstz
              INTO l_dt_take
              FROM icnp_interv_plan iip
             WHERE iip.id_icnp_epis_interv = i_id_icnp_epis_interv
               AND iip.flg_status IN
                   (pk_icnp_constant.g_interv_plan_status_executed, pk_icnp_constant.g_interv_plan_status_cancelled)
               AND iip.exec_number =
                   (SELECT MAX(iip.exec_number)
                      FROM icnp_interv_plan iip
                     WHERE iip.id_icnp_epis_interv = i_id_icnp_epis_interv
                       AND iip.flg_status IN (pk_icnp_constant.g_interv_plan_status_executed,
                                              pk_icnp_constant.g_interv_plan_status_cancelled));
        EXCEPTION
            WHEN no_data_found THEN
                l_dt_take := NULL;
        END;
    
        IF l_id_order_recurr_plan IS NOT NULL
        THEN
            -- call pk_order_recurrence_api_db.get_order_recurr_instructions function
            IF NOT pk_order_recurrence_api_db.get_order_recurr_instructions(i_lang                => i_lang,
                                                                            i_prof                => i_prof,
                                                                            i_order_plan          => l_id_order_recurr_plan,
                                                                            o_order_recurr_desc   => l_r_plan.order_recurr_desc,
                                                                            o_order_recurr_option => l_r_plan.order_recurr_option,
                                                                            o_start_date          => l_r_plan.start_date,
                                                                            o_occurrences         => l_r_plan.occurrences,
                                                                            o_duration            => l_r_plan.duration,
                                                                            o_unit_meas_duration  => l_r_plan.unit_meas_duration,
                                                                            o_duration_desc       => l_r_plan.o_duration_desc,
                                                                            o_end_date            => l_r_plan.end_date,
                                                                            o_flg_end_by_editable => l_r_plan.flg_end_by_editable,
                                                                            o_error               => l_error)
            THEN
                pk_icnp_util.raise_unexpected_error('pk_order_recurrence_api_db.get_order_recurr_instructions',
                                                    l_error);
            END IF;
        
        END IF;
    
        OPEN o_interv FOR
            SELECT iei.id_icnp_epis_interv id_interv,
                   pk_icnp.desc_composition(i_lang, iea.id_composition_interv) desc_interv,
                   iea.id_composition_diag id_rel_diag,
                   get_start_date_desc(i_lang, i_prof, iei.dt_begin_tstz) start_date_desc,
                   iei.flg_time execution,
                   get_perform_desc(i_lang, i_prof, iei.flg_time, iei.id_order_recurr_plan) desc_execution,
                   iei.id_order_recurr_plan recurrence_id,
                   decode(iei.flg_type,
                          pk_icnp_constant.g_epis_interv_type_recurrence,
                          l_r_plan.order_recurr_desc,
                          get_frequency_desc(i_lang, i_prof, iei.flg_type, iei.id_order_recurr_plan)) desc_frequency,
                   decode(iei.flg_type,
                          pk_icnp_constant.g_epis_interv_type_once,
                          0,
                          pk_icnp_constant.g_epis_interv_type_no_schedule,
                          -2,
                          l_r_plan.order_recurr_option) val_frequency,
                   decode(iei.flg_type, pk_icnp_constant.g_epis_interv_type_once, 1, l_r_plan.occurrences) executions,
                   l_r_plan.o_duration_desc duration_desc,
                   l_r_plan.duration duration,
                   l_r_plan.unit_meas_duration duration_unit,
                   pk_date_utils.date_send_tsz(i_lang, l_r_plan.end_date, i_prof) dt_end_str,
                   iei.flg_prn prn,
                   pk_sysdomain.get_domain(pk_icnp_constant.g_domain_epis_interv_prn, iei.flg_prn, i_lang) desc_prn,
                   iei.prn_notes prn_condition,
                   iei.notes,
                   pk_date_utils.date_send_tsz(i_lang,
                                               (SELECT decode(l_dt_take, NULL, e.dt_begin_tstz, l_dt_take)
                                                  FROM icnp_epis_intervention iei
                                                  JOIN episode e
                                                    ON e.id_episode = iei.id_episode
                                                 WHERE iei.id_icnp_epis_interv = i_id_icnp_epis_interv),
                                               i_prof) dt_min,
                   pk_date_utils.date_send_tsz(i_lang, iei.dt_begin_tstz, i_prof) dt_begin_str,
                   decode(iei.flg_type,
                          pk_icnp_constant.g_epis_interv_type_recurrence,
                          l_r_plan.flg_end_by_editable,
                          pk_alert_constant.g_no) flg_editable,
                   /*decode(l_count_next_epis, 0, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_next_epis_active*/
                   decode((SELECT COUNT(*)
                            FROM icnp_interv_plan iip
                           WHERE iip.id_icnp_epis_interv = iei.id_icnp_epis_interv
                             AND iip.flg_status IN (pk_icnp_constant.g_interv_plan_status_executed,
                                                    pk_icnp_constant.g_interv_plan_status_suspended,
                                                    pk_icnp_constant.g_interv_plan_status_cancelled)),
                          0,
                          pk_alert_constant.g_yes,
                          pk_alert_constant.g_no) flg_ongoing
              FROM icnp_epis_intervention iei
              JOIN interv_icnp_ea iea
                ON iea.id_icnp_epis_interv = iei.id_icnp_epis_interv
             WHERE iei.id_icnp_epis_interv = i_id_icnp_epis_interv;
    END load_icnp_info;

    /**
    * Update an ICNP intervention: given a set of interventions and it's instructions
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_interv       intervention identifiers and instructions list
    * @param i_sysdate_tstz Current timestamp that should be used across all the 
    *                       functions invoked from this one.
    * @param o_interv_id    created icnp_epis_intervention ids
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Nuno Neves
    * @version              2.5.1.8.2
    * @since                2011/10/10
    */

    PROCEDURE update_icnp_intervention
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv           IN table_varchar,
        i_sysdate_tstz     IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_origin           IN VARCHAR2,
        o_interv_id        OUT table_number,
        io_precessed_plans IN OUT t_processed_plan
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'update_icnp_interv';
        -- Typed i_interv record
        l_rows table_varchar := table_varchar();
    
        -- l_recurr_definit_ids_coll table_number := table_number();
    
        -- Data structures related with error handling
        l_error t_error_out;
    
        -- Indexes of the fields stored in table_varchar
        c_idx_ci_compo_interv_id     CONSTANT PLS_INTEGER := 1;
        c_idx_ci_compo_diag_id       CONSTANT PLS_INTEGER := 2;
        c_idx_ci_flg_time            CONSTANT PLS_INTEGER := 3;
        c_idx_ci_dt_begin            CONSTANT PLS_INTEGER := 4;
        c_idx_ci_recurr_id_old       CONSTANT PLS_INTEGER := 5;
        c_idx_ci_flg_prn             CONSTANT PLS_INTEGER := 6;
        c_idx_ci_prn_notes           CONSTANT PLS_INTEGER := 7;
        c_idx_ci_notes               CONSTANT PLS_INTEGER := 8;
        c_idx_ci_suggested_interv_id CONSTANT PLS_INTEGER := 9;
        c_idx_ci_recurr_id_new       CONSTANT PLS_INTEGER := 10;
        c_idx_ci_act_intrv_sug       CONSTANT PLS_INTEGER := 11;
    
        l_order_plan_exec  t_tbl_order_recurr_plan;
        l_exec_rowids_coll table_varchar;
    
        l_interv_row_coll ts_icnp_epis_intervention.icnp_epis_intervention_tc;
        l_interv_hist     table_number;
    
        l_episode  icnp_epis_intervention.id_episode%TYPE;
        l_flg_time icnp_epis_intervention.flg_time%TYPE;
        l_flg_type icnp_epis_intervention.flg_type%TYPE;
    
        -- Non used variables (output of the recurrence methods)
        l_order_recurr_desc   VARCHAR2(1000 CHAR);
        l_start_date          VARCHAR2(1000 CHAR);
        l_occurrences         order_recurr_plan.occurrences%TYPE;
        l_duration            order_recurr_plan.duration%TYPE;
        l_unit_meas_duration  order_recurr_plan.id_unit_meas_duration%TYPE;
        l_end_date            VARCHAR2(1000 CHAR);
        l_flg_end_by_editable VARCHAR2(1000 CHAR);
        l_duration_desc       VARCHAR2(1000 CHAR);
        l_order_recurr_option order_recurr_plan.id_order_recurr_option%TYPE;
        l_order_recurr_plan   order_recurr_plan.id_order_recurr_plan%TYPE;
    
        l_flg_discard_old_plan   VARCHAR2(1);
        l_count_r                INTEGER;
        l_order_recurr_option_id order_recurr_plan.id_order_recurr_option%TYPE;
        l_order_recurr_final_id  order_recurr_plan.id_order_recurr_plan%TYPE;
    
    BEGIN
        log_debug(c_func_name || '()', c_func_name);
    
        IF i_interv IS NOT NULL
        THEN
            SELECT iei.id_episode, iei.flg_time, iei.flg_type
              INTO l_episode, l_flg_time, l_flg_type
              FROM icnp_epis_intervention iei
             WHERE iei.id_icnp_epis_interv = i_interv(c_idx_ci_compo_interv_id);
        
            IF l_flg_time <> i_interv(c_idx_ci_flg_time)
            THEN
            
                IF (l_flg_time = pk_icnp_constant.g_epis_interv_time_before_epis AND
                   i_interv(c_idx_ci_flg_time) = pk_icnp_constant.g_epis_interv_time_curr_epis)
                   OR (l_flg_time = pk_icnp_constant.g_epis_interv_time_curr_epis AND
                   i_interv(c_idx_ci_flg_time) = pk_icnp_constant.g_epis_interv_time_before_epis)
                THEN
                    update_icnp_interv_int(i_lang             => i_lang,
                                           i_prof             => i_prof,
                                           i_interv           => i_interv,
                                           i_sysdate_tstz     => i_sysdate_tstz,
                                           i_origin           => i_origin,
                                           o_interv_id        => o_interv_id,
                                           io_precessed_plans => io_precessed_plans);
                
                ELSIF (l_flg_time = pk_icnp_constant.g_epis_interv_time_next_epis AND
                      i_interv(c_idx_ci_flg_time) = pk_icnp_constant.g_epis_interv_time_before_epis)
                      OR (l_flg_time = pk_icnp_constant.g_epis_interv_time_next_epis AND
                      i_interv(c_idx_ci_flg_time) = pk_icnp_constant.g_epis_interv_time_curr_epis)
                THEN
                    update_icnp_interv_int(i_lang             => i_lang,
                                           i_prof             => i_prof,
                                           i_interv           => i_interv,
                                           i_sysdate_tstz     => i_sysdate_tstz,
                                           i_origin           => i_origin,
                                           o_interv_id        => o_interv_id,
                                           io_precessed_plans => io_precessed_plans);
                
                    -- Create a new recurrence plan based in an existing one
                    IF NOT
                        pk_order_recurrence_api_db.copy_from_order_recurr_plan(i_lang                   => i_lang,
                                                                               i_prof                   => i_prof,
                                                                               i_order_recurr_area      => pk_icnp_constant.g_order_recurr_area,
                                                                               i_order_recurr_plan_from => i_interv(c_idx_ci_recurr_id_old),
                                                                               o_order_recurr_desc      => l_order_recurr_desc,
                                                                               o_order_recurr_option    => l_order_recurr_option,
                                                                               o_start_date             => l_start_date,
                                                                               o_occurrences            => l_occurrences,
                                                                               o_duration               => l_duration,
                                                                               o_unit_meas_duration     => l_unit_meas_duration,
                                                                               o_duration_desc          => l_duration_desc,
                                                                               o_end_date               => l_end_date,
                                                                               o_flg_end_by_editable    => l_flg_end_by_editable,
                                                                               o_order_recurr_plan      => l_order_recurr_plan,
                                                                               o_error                  => l_error)
                    THEN
                        pk_icnp_util.raise_unexpected_error('pk_order_recurrence_api_db.copy_from_order_recurr_plan',
                                                            l_error);
                    END IF;
                
                    --Number of interventions using the same order recur plan
                    SELECT COUNT(*)
                      INTO l_count_r
                      FROM icnp_epis_intervention iei
                     WHERE iei.id_order_recurr_plan = i_interv(c_idx_ci_recurr_id_old)
                       AND iei.flg_status IN (pk_icnp_constant.g_epis_interv_status_requested,
                                              pk_icnp_constant.g_epis_interv_status_ongoing,
                                              pk_icnp_constant.g_epis_interv_status_suspended);
                
                    --check if plan is used in 1 or more interventions
                    IF l_count_r = 1
                    THEN
                        --ending the old order recur plan
                        l_flg_discard_old_plan := pk_alert_constant.g_yes;
                    ELSE
                        l_flg_discard_old_plan := pk_alert_constant.g_no;
                    END IF;
                
                    --set a temporary order recurrence plan as definitive (final status) and set as deprecated 
                    log_debug('update_icnp_interv / i_recurr_plan_id: ' || i_interv(c_idx_ci_recurr_id_new),
                              c_func_name);
                
                    IF NOT io_precessed_plans.exists(l_order_recurr_plan)
                    THEN
                        IF NOT
                            pk_order_recurrence_api_db.set_for_edit_order_recurr_plan(i_lang                    => i_lang,
                                                                                      i_prof                    => i_prof,
                                                                                      i_order_recurr_plan_old   => i_interv(c_idx_ci_recurr_id_old),
                                                                                      i_order_recurr_plan_new   => l_order_recurr_plan,
                                                                                      i_flg_discard_old_plan    => l_flg_discard_old_plan,
                                                                                      o_order_recurr_option     => l_order_recurr_option_id,
                                                                                      o_final_order_recurr_plan => l_order_recurr_final_id,
                                                                                      o_error                   => l_error)
                        THEN
                            pk_icnp_util.raise_unexpected_error('pk_order_recurrence_api_db.set_for_edit_order_recurr_plan',
                                                                l_error);
                        END IF;
                        -- add plan values to processed array
                        io_precessed_plans(i_interv(c_idx_ci_recurr_id_new)).id_order_recurr_option := l_order_recurr_option_id;
                        io_precessed_plans(i_interv(c_idx_ci_recurr_id_new)).id_order_recurr_plan := l_order_recurr_final_id;
                    
                    ELSE
                    
                        l_order_recurr_option_id := io_precessed_plans(i_interv(c_idx_ci_recurr_id_new)).id_order_recurr_option;
                        l_order_recurr_final_id  := io_precessed_plans(i_interv(c_idx_ci_recurr_id_new)).id_order_recurr_plan;
                    END IF;
                
                    IF i_interv(c_idx_ci_recurr_id_old) IS NOT NULL
                    THEN
                        --prepare the order plan executions based in plan's area and interval configurations
                        IF NOT pk_order_recurrence_api_db.prepare_order_recurr_plan(i_lang            => i_lang,
                                                                                    i_prof            => i_prof,
                                                                                    i_order_plan      => table_number(l_order_recurr_final_id),
                                                                                    o_order_plan_exec => l_order_plan_exec,
                                                                                    o_error           => l_error)
                        THEN
                            pk_icnp_util.raise_unexpected_error('pk_order_recurrence_api_db.prepare_order_recurr_plan',
                                                                l_error);
                        END IF;
                    
                        /*IF i_interv(c_idx_ci_flg_prn) != pk_alert_constant.g_yes
                        THEN */
                        <<req>>
                        FOR req_idx IN 1 .. l_order_plan_exec.count
                        LOOP
                            -- Persist the data into the database and brodcast the update through the data 
                            -- governace mechanism                                                    
                            ts_icnp_interv_plan.ins(id_icnp_interv_plan_in  => ts_icnp_interv_plan.next_key,
                                                    id_icnp_epis_interv_in  => i_interv(c_idx_ci_compo_interv_id),
                                                    flg_status_in           => pk_icnp_constant.g_interv_plan_status_requested,
                                                    dt_plan_tstz_in         => l_order_plan_exec(req_idx).exec_timestamp,
                                                    id_prof_created_in      => i_prof.id,
                                                    dt_created_in           => i_sysdate_tstz,
                                                    dt_last_update_in       => i_sysdate_tstz,
                                                    exec_number_in          => l_order_plan_exec(req_idx).exec_number,
                                                    id_order_recurr_plan_in => i_interv(c_idx_ci_recurr_id_old),
                                                    rows_out                => l_exec_rowids_coll);
                        
                            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                          i_table_name => 'ICNP_INTERV_PLAN',
                                                          i_rowids     => l_exec_rowids_coll,
                                                          o_error      => l_error);
                        END LOOP req;
                    
                    ELSIF l_flg_type = pk_icnp_constant.g_epis_interv_type_once
                    THEN
                        --
                        ts_icnp_interv_plan.ins(id_icnp_interv_plan_in => ts_icnp_interv_plan.next_key,
                                                id_icnp_epis_interv_in => i_interv(c_idx_ci_compo_interv_id),
                                                flg_status_in          => pk_icnp_constant.g_interv_plan_status_requested,
                                                dt_plan_tstz_in        => pk_date_utils.get_string_tstz(i_lang,
                                                                                                        i_prof,
                                                                                                        i_interv(c_idx_ci_dt_begin),
                                                                                                        NULL),
                                                id_prof_created_in     => i_prof.id,
                                                dt_created_in          => i_sysdate_tstz,
                                                dt_last_update_in      => i_sysdate_tstz,
                                                exec_number_in         => 1,
                                                rows_out               => l_exec_rowids_coll);
                    
                        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'ICNP_INTERV_PLAN',
                                                      i_rowids     => l_exec_rowids_coll,
                                                      o_error      => l_error);
                    
                    END IF;
                
                ELSIF (l_flg_time = pk_icnp_constant.g_epis_interv_time_before_epis AND
                      i_interv(c_idx_ci_flg_time) = pk_icnp_constant.g_epis_interv_time_next_epis)
                      OR (l_flg_time = pk_icnp_constant.g_epis_interv_time_curr_epis AND
                      i_interv(c_idx_ci_flg_time) = pk_icnp_constant.g_epis_interv_time_next_epis)
                THEN
                
                    IF i_interv(c_idx_ci_recurr_id_old) IS NOT NULL
                       AND i_interv(c_idx_ci_recurr_id_new) IS NOT NULL
                    THEN
                        --set a temporary order recurrence plan as definitive (final status) and set as deprecated 
                        log_debug('update_icnp_interv / i_recurr_plan_id: ' || i_interv(c_idx_ci_recurr_id_new),
                                  c_func_name);
                        IF NOT io_precessed_plans.exists(i_interv(c_idx_ci_recurr_id_new))
                        THEN
                            IF NOT
                                pk_order_recurrence_api_db.set_for_edit_order_recurr_plan(i_lang                    => i_lang,
                                                                                          i_prof                    => i_prof,
                                                                                          i_order_recurr_plan_old   => i_interv(c_idx_ci_recurr_id_old),
                                                                                          i_order_recurr_plan_new   => i_interv(c_idx_ci_recurr_id_new),
                                                                                          i_flg_discard_old_plan    => l_flg_discard_old_plan,
                                                                                          o_order_recurr_option     => l_order_recurr_option_id,
                                                                                          o_final_order_recurr_plan => l_order_recurr_final_id,
                                                                                          o_error                   => l_error)
                            THEN
                                pk_icnp_util.raise_unexpected_error('pk_order_recurrence_api_db.set_for_edit_order_recurr_plan',
                                                                    l_error);
                            END IF;
                            -- add plan values to processed array
                            io_precessed_plans(i_interv(c_idx_ci_recurr_id_new)).id_order_recurr_option := l_order_recurr_option_id;
                            io_precessed_plans(i_interv(c_idx_ci_recurr_id_new)).id_order_recurr_plan := l_order_recurr_final_id;
                        
                        ELSE
                        
                            l_order_recurr_option_id := io_precessed_plans(i_interv(c_idx_ci_recurr_id_new)).id_order_recurr_option;
                            l_order_recurr_final_id  := io_precessed_plans(i_interv(c_idx_ci_recurr_id_new)).id_order_recurr_plan;
                        END IF;
                    END IF;
                
                    --cancel executions not executed ('M' - frequency changed)
                    l_rows := table_varchar();
                    ts_icnp_interv_plan.upd(flg_status_in => pk_icnp_constant.g_interv_plan_status_freq_alt,
                                            where_in      => 'flg_status=''' ||
                                                             pk_icnp_constant.g_interv_plan_status_requested ||
                                                             ''' AND id_icnp_epis_interv = ' ||
                                                             i_interv(c_idx_ci_compo_interv_id),
                                            rows_out      => l_rows);
                
                    t_data_gov_mnt.process_update(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  i_table_name   => 'ICNP_INTERV_PLAN',
                                                  i_rowids       => l_rows,
                                                  o_error        => l_error,
                                                  i_list_columns => table_varchar('FLG_STATUS'));
                
                    -- Gets the intervention row of the id
                    l_interv_row_coll := pk_icnp_interv.get_interv_rows(i_interv_ids => table_number(i_interv(c_idx_ci_compo_interv_id)));
                
                    -- Creates history records for all the interventions
                    pk_icnp_interv.create_interv_hist(i_lang         => i_lang,
                                                      i_prof         => i_prof,
                                                      i_interv_coll  => l_interv_row_coll,
                                                      i_sysdate_tstz => i_sysdate_tstz,
                                                      o_interv_hist  => l_interv_hist);
                
                    --Update id_order_recurr_plan                                   
                    l_rows := table_varchar();
                    ts_icnp_epis_intervention.upd(id_icnp_epis_interv_in  => i_interv(c_idx_ci_compo_interv_id),
                                                  id_order_recurr_plan_in => l_order_recurr_final_id,
                                                  notes_in                => i_interv(c_idx_ci_notes),
                                                  flg_time_in             => i_interv(c_idx_ci_flg_time),
                                                  flg_prn_in              => i_interv(c_idx_ci_flg_prn),
                                                  prn_notes_in            => i_interv(c_idx_ci_prn_notes),
                                                  prn_notes_nin           => FALSE,
                                                  dt_last_update_in       => i_sysdate_tstz,
                                                  flg_type_in             => l_flg_type,
                                                  id_prof_last_update_in  => i_prof.id,
                                                  rows_out                => l_rows);
                
                    t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'ICNP_EPIS_INTERVENTION',
                                                  i_rowids     => l_rows,
                                                  o_error      => l_error);
                
                END IF;
            
            ELSE
            
                update_icnp_interv_int(i_lang             => i_lang,
                                       i_prof             => i_prof,
                                       i_interv           => i_interv,
                                       i_sysdate_tstz     => i_sysdate_tstz,
                                       i_origin           => i_origin,
                                       o_interv_id        => o_interv_id,
                                       io_precessed_plans => io_precessed_plans);
            END IF;
        END IF;
    
        o_interv_id := table_number();
    END update_icnp_intervention;

    /**
    * Update an ICNP intervention: given a set of interventions and it's instructions
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_interv       intervention identifiers and instructions list
    * @param i_sysdate_tstz Current timestamp that should be used across all the 
    *                       functions invoked from this one.
    * @param i_origin       parameter to identify if the plan is being executed (E)
    *                       or modified/created (M)     
    * @param o_interv_id    created icnp_epis_intervention ids
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Nuno Neves
    * @version              2.5.2.4
    * @since                2011/10/10
    */

    PROCEDURE update_icnp_interv
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_interv       IN table_varchar,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_origin       IN VARCHAR2,
        o_interv_id    OUT table_number
    ) IS
        l_processed_plan t_processed_plan;
    BEGIN
    
        update_icnp_intervention(i_lang             => i_lang,
                                 i_prof             => i_prof,
                                 i_interv           => i_interv,
                                 i_sysdate_tstz     => i_sysdate_tstz,
                                 i_origin           => i_origin,
                                 o_interv_id        => o_interv_id,
                                 io_precessed_plans => l_processed_plan);
    
        updt_icnp_plan(i_lang => i_lang, i_prof => i_prof, i_interv => i_interv);
    END;

    PROCEDURE updt_icnp_plan
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_interv IN table_varchar
    ) IS
        -- Indexes of the fields stored in table_varchar
        c_idx_ci_compo_interv_id     CONSTANT PLS_INTEGER := 1;
        c_idx_ci_compo_diag_id       CONSTANT PLS_INTEGER := 2;
        c_idx_ci_flg_time            CONSTANT PLS_INTEGER := 3;
        c_idx_ci_dt_begin            CONSTANT PLS_INTEGER := 4;
        c_idx_ci_recurr_id_old       CONSTANT PLS_INTEGER := 5;
        c_idx_ci_flg_prn             CONSTANT PLS_INTEGER := 6;
        c_idx_ci_prn_notes           CONSTANT PLS_INTEGER := 7;
        c_idx_ci_notes               CONSTANT PLS_INTEGER := 8;
        c_idx_ci_suggested_interv_id CONSTANT PLS_INTEGER := 9;
        c_idx_ci_recurr_id_new       CONSTANT PLS_INTEGER := 10;
        c_idx_ci_act_intrv_sug       CONSTANT PLS_INTEGER := 11;
    
        l_task_count             INTEGER;
        l_flg_end_by             order_recurr_plan.flg_end_by%TYPE;
        l_new_recurr_plan_exists INTEGER := 1;
    
        l_rows_out table_varchar := table_varchar();
    
        l_t_interv_plan table_number := table_number();
        l_error         t_error_out;
    
        CURSOR c_interv_plan IS
            SELECT iip.id_icnp_epis_interv,
                   iip.id_prof_take,
                   iip.notes,
                   iip.flg_status,
                   iip.id_prof_cancel,
                   iip.notes_cancel,
                   iip.id_episode_write,
                   iip.dt_plan_tstz,
                   iip.dt_take_tstz,
                   iip.dt_cancel_tstz,
                   iip.id_epis_documentation,
                   iip.id_prof_created,
                   iip.dt_created,
                   iip.id_cancel_reason,
                   iip.dt_last_update,
                   iip.exec_number
              FROM icnp_interv_plan iip
             WHERE (iip.id_order_recurr_plan <> i_interv(c_idx_ci_recurr_id_new) OR iip.id_order_recurr_plan IS NULL)
               AND iip.id_icnp_epis_interv = i_interv(c_idx_ci_compo_interv_id)
               AND iip.flg_status NOT IN
                   (pk_icnp_constant.g_interv_plan_status_freq_alt, pk_icnp_constant.g_interv_plan_status_requested);
    
        --FUNCTION TO CHECK IF A NEW RECURR_PLAN HAS BEEN CREATED
        FUNCTION check_recurr_plan(i_id_recurr_plan IN order_recurr_plan.id_order_recurr_plan%TYPE) RETURN BOOLEAN IS
            l_id_recurr_plan order_recurr_plan.id_order_recurr_plan%TYPE;
        
        BEGIN
        
            SELECT orp.id_order_recurr_plan
              INTO l_id_recurr_plan
              FROM order_recurr_plan orp
             WHERE orp.id_order_recurr_plan = i_id_recurr_plan;
        
            RETURN TRUE;
        
        EXCEPTION
            WHEN no_data_found THEN
                RETURN FALSE;
            
        END check_recurr_plan;
    
    BEGIN
        --CHECK IF NEW PLAN IS OF SINGLE EXECUTION
        IF NOT check_recurr_plan(i_interv(c_idx_ci_recurr_id_new))
        THEN
            l_new_recurr_plan_exists := 0;
        END IF;
    
        IF (i_interv(c_idx_ci_recurr_id_old) IS NULL AND l_new_recurr_plan_exists = 0)
        THEN
            --IF THE PREVIOUS PLAN IS OF SINGLE EXECUTION AND THE NEXT PLAN IS ALSO OF SINGLE EXECUTION
            --IT IS ONLY NECESSARY TO SET THE PREVIOUS TASKS AS 'M'     
            SELECT iip.id_icnp_interv_plan
              BULK COLLECT
              INTO l_t_interv_plan
              FROM icnp_interv_plan iip
             WHERE (iip.id_order_recurr_plan <> i_interv(c_idx_ci_recurr_id_new) AND
                   iip.id_icnp_epis_interv = i_interv(c_idx_ci_compo_interv_id))
                OR (iip.id_icnp_epis_interv = i_interv(c_idx_ci_compo_interv_id) AND iip.id_order_recurr_plan IS NULL AND
                   iip.flg_status IN (pk_icnp_constant.g_interv_plan_status_freq_alt) AND l_new_recurr_plan_exists = 0)
                OR (iip.id_icnp_epis_interv = i_interv(c_idx_ci_compo_interv_id) AND iip.id_order_recurr_plan IS NULL AND
                   l_new_recurr_plan_exists = 1);
        
            FOR i IN 1 .. l_t_interv_plan.count()
            LOOP
            
                ts_icnp_interv_plan.upd(id_icnp_interv_plan_in => l_t_interv_plan(i),
                                        flg_status_in          => pk_icnp_constant.g_interv_plan_status_freq_alt,
                                        exec_number_in         => NULL,
                                        exec_number_nin        => FALSE,
                                        rows_out               => l_rows_out);
            
                t_data_gov_mnt.process_update(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_table_name   => 'ICNP_INTERV_PLAN',
                                              i_rowids       => l_rows_out,
                                              o_error        => l_error,
                                              i_list_columns => table_varchar('FLG_STATUS', 'EXEC_NUMBER'));
            
            END LOOP;
        ELSE
            --GET ALL THE PREVIOUS EXECUTED/CANCELED TASKS AND ADD THEM TO THE NEW PLAN
            FOR n IN c_interv_plan
            LOOP
            
                ts_icnp_interv_plan.ins(id_icnp_interv_plan_in   => seq_icnp_interv_plan.nextval,
                                        id_icnp_epis_interv_in   => n.id_icnp_epis_interv,
                                        id_prof_take_in          => n.id_prof_take,
                                        notes_in                 => n.notes,
                                        flg_status_in            => n.flg_status,
                                        id_prof_cancel_in        => n.id_prof_cancel,
                                        notes_cancel_in          => n.notes_cancel,
                                        id_episode_write_in      => n.id_episode_write,
                                        dt_plan_tstz_in          => n.dt_plan_tstz,
                                        dt_take_tstz_in          => n.dt_take_tstz,
                                        dt_cancel_tstz_in        => n.dt_cancel_tstz,
                                        id_epis_documentation_in => n.id_epis_documentation,
                                        id_prof_created_in       => n.id_prof_created,
                                        dt_created_in            => n.dt_created,
                                        id_cancel_reason_in      => n.id_cancel_reason,
                                        dt_last_update_in        => n.dt_last_update,
                                        exec_number_in           => n.exec_number,
                                        id_order_recurr_plan_in  => CASE
                                                                        WHEN l_new_recurr_plan_exists = 1 THEN
                                                                         i_interv(c_idx_ci_recurr_id_new)
                                                                        ELSE
                                                                         NULL
                                                                    END,
                                        rows_out                 => l_rows_out);
            
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'ICNP_INTERV_PLAN',
                                              i_rowids     => l_rows_out,
                                              o_error      => l_error);
            
            END LOOP;
        
            --SET ALL TASKS FROM PREVIOUS PLANS AS 'M' AND CLEAR EXEC_NUMBER                              
            SELECT iip.id_icnp_interv_plan
              BULK COLLECT
              INTO l_t_interv_plan
              FROM icnp_interv_plan iip
             WHERE (iip.id_order_recurr_plan <> i_interv(c_idx_ci_recurr_id_new) AND
                   iip.id_icnp_epis_interv = i_interv(c_idx_ci_compo_interv_id))
                OR (iip.id_icnp_epis_interv = i_interv(c_idx_ci_compo_interv_id) AND iip.id_order_recurr_plan IS NULL AND
                   iip.flg_status IN (pk_icnp_constant.g_interv_plan_status_freq_alt) AND l_new_recurr_plan_exists = 0)
                OR (iip.id_icnp_epis_interv = i_interv(c_idx_ci_compo_interv_id) AND iip.id_order_recurr_plan IS NULL AND
                   l_new_recurr_plan_exists = 1);
        
            FOR i IN 1 .. l_t_interv_plan.count()
            LOOP
            
                ts_icnp_interv_plan.upd(id_icnp_interv_plan_in => l_t_interv_plan(i),
                                        flg_status_in          => pk_icnp_constant.g_interv_plan_status_freq_alt,
                                        exec_number_in         => NULL,
                                        exec_number_nin        => FALSE,
                                        rows_out               => l_rows_out);
            
                t_data_gov_mnt.process_update(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_table_name   => 'ICNP_INTERV_PLAN',
                                              i_rowids       => l_rows_out,
                                              o_error        => l_error,
                                              i_list_columns => table_varchar('FLG_STATUS', 'EXEC_NUMBER'));
            
            END LOOP;
        
            DECLARE
            
                l_t_icnp_canceled_task table_number := table_number();
            
            BEGIN
            
                --DELETE EXEC_NUMBER FROM CANCELED TASKS              
                SELECT iip.id_icnp_interv_plan
                  BULK COLLECT
                  INTO l_t_icnp_canceled_task
                  FROM icnp_interv_plan iip
                 WHERE iip.id_icnp_epis_interv = i_interv(c_idx_ci_compo_interv_id)
                   AND iip.flg_status = pk_icnp_constant.g_interv_plan_status_cancelled;
            
                FOR i IN 1 .. l_t_icnp_canceled_task.count()
                LOOP
                    ts_icnp_interv_plan.upd(id_icnp_interv_plan_in => l_t_icnp_canceled_task(i),
                                            exec_number_in         => NULL,
                                            exec_number_nin        => FALSE,
                                            rows_out               => l_rows_out);
                
                END LOOP;
            
            END;
        
            --UPDATE THE NEW PLAN WITH THE TOTAL NUMBER OF EXECUTIONS (NEW EXECUTIONS + PREVIOUS CONCLUDED/CANCELED EXECUTIONS)
            IF l_new_recurr_plan_exists = 1
            THEN
            
                SELECT orp.flg_end_by
                  INTO l_flg_end_by
                  FROM order_recurr_plan orp
                 WHERE orp.id_order_recurr_plan = i_interv(c_idx_ci_recurr_id_new);
            
                IF l_flg_end_by = pk_order_recurrence_core.g_flg_end_by_occurrences
                THEN
                
                    SELECT COUNT(*)
                      INTO l_task_count
                      FROM icnp_interv_plan iip
                     WHERE iip.id_order_recurr_plan = i_interv(c_idx_ci_recurr_id_new);
                
                    UPDATE order_recurr_plan orp
                       SET orp.occurrences = l_task_count
                     WHERE orp.id_order_recurr_plan = i_interv(c_idx_ci_recurr_id_new);
                
                    UPDATE order_recurr_control orc
                       SET orc.last_exec_order = l_task_count
                     WHERE orc.id_order_recurr_plan = i_interv(c_idx_ci_recurr_id_new);
                
                END IF;
            
                --IF THE NEW PLAN IS NOT OF SINGLE EXECUTION => UPDATE START DATE                
                updt_start_date(i_lang => i_lang, i_prof => i_prof, i_interv => i_interv);
            
            END IF;
        END IF;
    
    END updt_icnp_plan;

    PROCEDURE updt_start_date
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_interv IN table_varchar
    ) IS
    
        l_start_date interv_icnp_ea.dt_begin%TYPE;
        l_rows_out   table_varchar := table_varchar();
        l_error      t_error_out;
    
        -- Indexes of the fields stored in table_varchar
        c_idx_ci_compo_interv_id     CONSTANT PLS_INTEGER := 1;
        c_idx_ci_compo_diag_id       CONSTANT PLS_INTEGER := 2;
        c_idx_ci_flg_time            CONSTANT PLS_INTEGER := 3;
        c_idx_ci_dt_begin            CONSTANT PLS_INTEGER := 4;
        c_idx_ci_recurr_id_old       CONSTANT PLS_INTEGER := 5;
        c_idx_ci_flg_prn             CONSTANT PLS_INTEGER := 6;
        c_idx_ci_prn_notes           CONSTANT PLS_INTEGER := 7;
        c_idx_ci_notes               CONSTANT PLS_INTEGER := 8;
        c_idx_ci_suggested_interv_id CONSTANT PLS_INTEGER := 9;
        c_idx_ci_recurr_id_new       CONSTANT PLS_INTEGER := 10;
        c_idx_ci_act_intrv_sug       CONSTANT PLS_INTEGER := 11;
    
        --FUNCTION TO CHECK HOW MANY TASKS HAVE ALREADY BEEN EXECUTED/CANCELLED
        FUNCTION get_exec_tasks(i_id_icnp_interv_plan IN icnp_interv_plan.id_icnp_interv_plan%TYPE) RETURN INTEGER IS
        
            l_n_exec_tasks INTEGER;
        
        BEGIN
        
            SELECT COUNT(*)
              INTO l_n_exec_tasks
              FROM icnp_interv_plan iip
             WHERE iip.id_icnp_epis_interv = i_id_icnp_interv_plan
               AND iip.flg_status IN
                   (pk_icnp_constant.g_interv_plan_status_executed, pk_icnp_constant.g_interv_plan_status_cancelled);
        
            RETURN l_n_exec_tasks;
        
        END get_exec_tasks;
    
    BEGIN
        --UPDATE START DATE IF AT LEAST ONE TASK HAS BEEN EXECUTED/CANCELLED
        IF get_exec_tasks(i_interv(c_idx_ci_compo_interv_id)) > 0
        THEN
        
            BEGIN
            
                SELECT dt_plan_tstz
                  INTO l_start_date
                  FROM (SELECT *
                          FROM icnp_interv_plan iip
                         WHERE iip.flg_status NOT IN (pk_icnp_constant.g_interv_plan_status_freq_alt)
                           AND iip.id_icnp_epis_interv = i_interv(c_idx_ci_compo_interv_id)
                           AND iip.exec_number IS NOT NULL
                         ORDER BY iip.exec_number ASC)
                 WHERE rownum = 1;
            
            END;
        
            UPDATE order_recurr_plan orp
               SET orp.start_date = l_start_date
             WHERE orp.id_order_recurr_plan = i_interv(c_idx_ci_recurr_id_new);
        
            --UPDATE TS_ICNP_EPIS_INTERVENTION - START DATE                                              
            ts_icnp_epis_intervention.upd(id_icnp_epis_interv_in => i_interv(c_idx_ci_compo_interv_id),
                                          dt_begin_tstz_in       => l_start_date,
                                          rows_out               => l_rows_out);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'ICNP_EPIS_INTERVENTION',
                                          i_rowids     => l_rows_out,
                                          o_error      => l_error);
        
            ts_interv_icnp_ea.upd(id_icnp_epis_interv_in => i_interv(c_idx_ci_compo_interv_id),
                                  --dt_plan_in             => l_start_date,
                                  dt_begin_in => l_start_date,
                                  rows_out    => l_rows_out);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'INTERV_ICNP_EA',
                                          i_rowids     => l_rows_out,
                                          o_error      => l_error);
        END IF;
    
    END updt_start_date;

    /**
     * :TODO:
    */
    FUNCTION process_intervs
    (
        i_lang                         IN language.id_language%TYPE,
        i_prof                         IN profissional,
        i_episode                      IN episode.id_episode%TYPE,
        i_patient                      IN patient.id_patient%TYPE,
        i_data_ux_rec                  IN data_ux_ci_rec,
        i_order_recurr_rec             IN t_order_recurr_rec,
        i_sysdate_tstz                 IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_interv                       IN table_varchar,
        io_interv_rows_for_create_coll IN OUT NOCOPY ts_icnp_epis_intervention.icnp_epis_intervention_tc,
        io_interv_rows_for_update_coll IN OUT NOCOPY ts_icnp_epis_intervention.icnp_epis_intervention_tc,
        io_interv_rows_all_coll        IN OUT NOCOPY ts_icnp_epis_intervention.icnp_epis_intervention_tc,
        io_precessed_plans             IN OUT t_processed_plan
    ) RETURN icnp_epis_intervention%ROWTYPE IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'process_intervs';
        l_already_processed  BOOLEAN := FALSE;
        l_interv_row         icnp_epis_intervention%ROWTYPE;
        l_existent_interv_id icnp_epis_intervention.id_icnp_epis_interv%TYPE;
        l_flg_type           icnp_epis_intervention.flg_type%TYPE;
        l_interv_id          table_number;
        l_recurr             icnp_epis_intervention.id_order_recurr_plan%TYPE;
    
        -- Indexes of the fields stored in table_varchar
        c_idx_ci_compo_interv_id     CONSTANT PLS_INTEGER := 1;
        c_idx_ci_compo_diag_id       CONSTANT PLS_INTEGER := 2;
        c_idx_ci_flg_time            CONSTANT PLS_INTEGER := 3;
        c_idx_ci_dt_begin            CONSTANT PLS_INTEGER := 4;
        c_idx_ci_recurr_id_old       CONSTANT PLS_INTEGER := 5;
        c_idx_ci_flg_prn             CONSTANT PLS_INTEGER := 6;
        c_idx_ci_prn_notes           CONSTANT PLS_INTEGER := 7;
        c_idx_ci_notes               CONSTANT PLS_INTEGER := 8;
        c_idx_ci_suggested_interv_id CONSTANT PLS_INTEGER := 9;
        c_idx_ci_recurr_id_new       CONSTANT PLS_INTEGER := 10;
        c_idx_ci_act_intrv_sug       CONSTANT PLS_INTEGER := 11;
    
        l_error t_error_out;
    
        -- Functions
        PROCEDURE check_interv_row_from_coll IS
            l_interv_index PLS_INTEGER := -1;
        BEGIN
            -- Check the collection with the records to insert
            l_interv_index := pk_icnp_interv.get_elem_index_by_compo(i_composition_id  => i_data_ux_rec.id_composition_interv,
                                                                     i_interv_row_coll => io_interv_rows_for_create_coll);
            IF l_interv_index > 0
            THEN
                l_already_processed := TRUE;
                l_interv_row        := io_interv_rows_for_create_coll(l_interv_index);
                RETURN;
            END IF;
        
            -- Check the collection with the records to update
            l_interv_index := pk_icnp_interv.get_elem_index_by_compo(i_composition_id  => i_data_ux_rec.id_composition_interv,
                                                                     i_interv_row_coll => io_interv_rows_for_update_coll);
            IF l_interv_index > 0
            THEN
                l_already_processed := TRUE;
                l_interv_row        := io_interv_rows_for_update_coll(l_interv_index);
                RETURN;
            END IF;
        END;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '()', c_func_name);
    
        -- Check if the given intervention was already processed: either marked for 
        -- creation or for update
        check_interv_row_from_coll();
    
        -- The intervention needs to be processed
        IF NOT l_already_processed
        THEN
            -- Check if intervention is already associated to the patient; it
            -- needs to be active
            l_existent_interv_id := pk_icnp_interv.get_interv_existent_id(i_patient      => i_patient,
                                                                          i_interv_compo => i_data_ux_rec.id_composition_interv,
                                                                          i_episode      => i_episode);
        
            -- Maps the a given frequency to its equivalent type
            l_flg_type := map_recurr_option_to_type(i_order_recurr_rec.id_order_recurr_option);
        
            IF l_existent_interv_id IS NOT NULL
            THEN
                -- IF 'Y' update recurr_plan
                IF i_interv(c_idx_ci_act_intrv_sug) = pk_alert_constant.g_yes
                THEN
                    SELECT iei.id_order_recurr_plan
                      INTO l_recurr
                      FROM icnp_epis_intervention iei
                     WHERE iei.id_icnp_epis_interv = l_existent_interv_id;
                
                    update_icnp_intervention(i_lang => i_lang,
                                             
                                             i_prof             => i_prof,
                                             i_interv           => table_varchar(l_existent_interv_id,
                                                                                 i_interv(c_idx_ci_compo_diag_id),
                                                                                 i_interv(c_idx_ci_flg_time),
                                                                                 i_interv(c_idx_ci_dt_begin),
                                                                                 l_recurr,
                                                                                 i_interv(c_idx_ci_flg_prn),
                                                                                 i_interv(c_idx_ci_prn_notes),
                                                                                 i_interv(c_idx_ci_notes),
                                                                                 i_interv(c_idx_ci_suggested_interv_id),
                                                                                 i_interv(c_idx_ci_recurr_id_old)),
                                             i_sysdate_tstz     => i_sysdate_tstz,
                                             i_origin           => 'M',
                                             o_interv_id        => l_interv_id,
                                             io_precessed_plans => io_precessed_plans);
                END IF;
                l_interv_row := pk_icnp_interv.get_interv_row(i_epis_interv_id => l_existent_interv_id);
            
                -- :TODO:
                io_interv_rows_for_update_coll(io_interv_rows_for_update_coll.count + 1) := l_interv_row;
            
            ELSE
                -----
                -- When the intervention is not yet associated with the patient we
                -- create a new one with the specified request instructions
            
                -- The intervention is not active for patient: normal insertion
                l_interv_row := pk_icnp_interv.create_interv_row(i_prof              => i_prof,
                                                                 i_episode           => i_episode,
                                                                 i_patient           => i_patient,
                                                                 i_interv            => i_data_ux_rec.id_composition_interv,
                                                                 i_flg_type          => l_flg_type,
                                                                 i_flg_time          => i_data_ux_rec.flg_time,
                                                                 i_dt_begin_tstz     => i_data_ux_rec.dt_begin_tstz,
                                                                 i_notes             => i_data_ux_rec.notes,
                                                                 i_order_recurr_plan => i_order_recurr_rec.id_order_recurr_plan,
                                                                 i_flg_prn           => i_data_ux_rec.flg_prn,
                                                                 i_prn_notes         => i_data_ux_rec.prn_notes,
                                                                 i_sysdate_tstz      => i_sysdate_tstz);
            
                -- Add the intervention to the collection with the interventions to be inserted
                io_interv_rows_for_create_coll(io_interv_rows_for_create_coll.count + 1) := l_interv_row;
            END IF;
        
            -- Add the intervention to the collection with all the interventions (both,
            -- to be inserted or to be updated)
            io_interv_rows_all_coll(io_interv_rows_all_coll.count + 1) := l_interv_row;
        END IF;
    
        RETURN l_interv_row;
    
    END process_intervs;

    /**
    * Create an ICNP intervention: given a set of diagnosis,
    * interventions and it's instructions, set them to the specified
    * patient.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_patient      patient identifier
    * @param i_diag         diagnosis identifiers list
    * @param i_exp_res      expected results identifiers list
    * @param i_notes        diagnosis notes list
    * @param i_interv       intervention identifiers and instructions list
    * @param i_cur_diag     current diagnosis identifier
    * @param i_sysdate_tstz Current timestamp that should be used across all the 
    *                       functions invoked from this one.
    * @param i_moment_assoc Moment of creation of the association between intervention and diagnosis 'C' creation, 'A' association
    * @param o_interv_id    created icnp_epis_intervention ids
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/07/20
    */
    PROCEDURE create_icnp_interv
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_patient        IN patient.id_patient%TYPE,
        i_diag           IN table_number,
        i_exp_res        IN table_number,
        i_notes          IN table_varchar,
        i_interv         IN table_table_varchar,
        i_cur_diag       IN icnp_epis_diagnosis.id_icnp_epis_diag%TYPE,
        i_sysdate_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_moment_assoc   IN icnp_epis_diag_interv.flg_moment_assoc%TYPE DEFAULT 'C',
        i_flg_type_assoc IN icnp_epis_diag_interv.flg_type_assoc%TYPE DEFAULT 'D',
        o_interv_id      OUT table_number
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'create_icnp_interv';
        -- Typed i_interv record
        l_data_ux_rec data_ux_ci_rec;
        -- Data structures related with icnp_epis_intervention
        l_interv_rows_for_create_coll  ts_icnp_epis_intervention.icnp_epis_intervention_tc;
        l_interv_rows_for_create_coll2 ts_icnp_epis_intervention.icnp_epis_intervention_tc;
        l_interv_rows_for_update_coll  ts_icnp_epis_intervention.icnp_epis_intervention_tc;
        l_interv_rows_for_update_coll2 ts_icnp_epis_intervention.icnp_epis_intervention_tc;
        l_interv_rows_all_coll         ts_icnp_epis_intervention.icnp_epis_intervention_tc;
        l_interv_rows_all_coll2        ts_icnp_epis_intervention.icnp_epis_intervention_tc;
        l_interv_row                   icnp_epis_intervention%ROWTYPE;
        l_interv_row2                  icnp_epis_intervention%ROWTYPE;
        -- Associative array to control the recurrences that were already made definitive
        l_recurr_processed_coll    t_order_recurr_coll;
        l_recurr_processed_coll2   t_order_recurr_coll;
        l_order_recurr_rec         t_order_recurr_rec;
        l_order_recurr_rec2        t_order_recurr_rec;
        l_recurr_definit_ids_coll  table_number := table_number();
        l_recurr_definit_ids_coll2 table_number := table_number();
        -- 
        l_diag_row_coll         ts_icnp_epis_diagnosis.icnp_epis_diagnosis_tc;
        l_interv_id             table_number := table_number();
        l_assoc_interv          table_number := table_number();
        l_interv_suggested_coll pk_icnp_type.t_interv_suggested_coll := pk_icnp_type.t_interv_suggested_coll();
        l_interv_suggested_rec  pk_icnp_type.t_interv_suggested_rec;
        l_suggested_interv      BOOLEAN := FALSE;
        l_sysdate_tstz          TIMESTAMP WITH LOCAL TIME ZONE;
        l_existent_interv_id    icnp_epis_intervention.id_icnp_epis_interv%TYPE;
    
        l_exist_sug        NUMBER;
        l_exist            NUMBER;
        l_sugg_rowids_coll table_varchar;
        l_error            t_error_out;
    
        l_moment_assoc icnp_epis_diag_interv.flg_moment_assoc%TYPE;
        l_type_assoc   icnp_epis_diag_interv.flg_type_assoc%TYPE;
    
        l_processed_plan t_processed_plan;
    
    BEGIN
        log_debug(c_func_name || '()', c_func_name);
        l_sysdate_tstz := i_sysdate_tstz;
    
        l_moment_assoc := i_moment_assoc;
    
        IF i_interv IS NOT NULL
           AND i_interv.count > 0
        THEN
            -- insert interventions
            FOR i IN i_interv.first .. i_interv.last
            LOOP
                -- Converts the raw data record into a typed record
                l_data_ux_rec := populate_create_interv_rec(i_lang => i_lang, i_prof => i_prof, i_values => i_interv(i));
            
                /*IF l_data_ux_rec.dt_begin_tstz < l_sysdate_tstz
                THEN
                    l_sysdate_tstz := l_data_ux_rec.dt_begin_tstz;
                END IF;*/
            
                BEGIN
                    SELECT 1
                      INTO l_exist
                      FROM icnp_epis_intervention iei
                     WHERE iei.id_patient = i_patient
                       AND iei.id_episode = i_episode
                       AND iei.id_episode_destination IS NULL
                       AND iei.flg_status IN (pk_icnp_constant.g_epis_interv_status_ongoing,
                                              pk_icnp_constant.g_epis_interv_status_requested,
                                              pk_icnp_constant.g_epis_interv_status_suspended)
                       AND iei.id_composition = l_data_ux_rec.id_composition_interv;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_exist := 0;
                END;
            
                l_existent_interv_id := pk_icnp_interv.get_interv_existent_id(i_patient      => i_patient,
                                                                              i_interv_compo => l_data_ux_rec.id_composition_interv,
                                                                              i_episode      => i_episode);
            
                IF l_data_ux_rec.flg_time != pk_icnp_constant.g_epis_interv_time_next_epis
                THEN
                    IF (l_existent_interv_id IS NULL)
                    THEN
                        /* IF \*(l_existent_interv_id IS NULL AND l_exist <> 1)
                                               OR*\
                         (l_data_ux_rec.id_icnp_sug_interv IS NULL)
                         OR (l_data_ux_rec.id_icnp_sug_interv IS NOT NULL AND l_exist = 0)
                        THEN*/
                        -- Set a temporary order recurrence plan as definitive (final status)
                        l_order_recurr_rec := set_order_recurr_plan(i_lang                     => i_lang,
                                                                    i_prof                     => i_prof,
                                                                    i_recurr_plan_id           => l_data_ux_rec.id_order_recurr_plan,
                                                                    io_recurr_processed_coll   => l_recurr_processed_coll,
                                                                    io_recurr_definit_ids_coll => l_recurr_definit_ids_coll,
                                                                    io_precessed_plans         => l_processed_plan);
                        /*END IF;*/
                    END IF;
                
                    -- :TODO:
                    l_interv_row := process_intervs(i_lang => i_lang,
                                                    
                                                    i_prof                         => i_prof,
                                                    i_episode                      => i_episode,
                                                    i_patient                      => i_patient,
                                                    i_data_ux_rec                  => l_data_ux_rec,
                                                    i_order_recurr_rec             => l_order_recurr_rec,
                                                    i_sysdate_tstz                 => l_sysdate_tstz,
                                                    i_interv                       => i_interv(i),
                                                    io_interv_rows_for_create_coll => l_interv_rows_for_create_coll,
                                                    io_interv_rows_for_update_coll => l_interv_rows_for_update_coll,
                                                    io_interv_rows_all_coll        => l_interv_rows_all_coll,
                                                    io_precessed_plans             => l_processed_plan);
                    l_assoc_interv.extend;
                    l_assoc_interv(l_assoc_interv.last) := l_interv_row.id_icnp_epis_interv;
                
                    BEGIN
                        SELECT 1
                          INTO l_exist_sug
                          FROM icnp_suggest_interv isi
                         WHERE isi.id_composition = l_data_ux_rec.id_composition_interv
                           AND isi.id_patient = i_patient
                           AND isi.id_episode = i_episode
                           AND isi.id_icnp_epis_interv = l_interv_row.id_icnp_epis_interv
                           AND isi.flg_status = pk_icnp_constant.g_sug_interv_status_accepted;
                    EXCEPTION
                        WHEN no_data_found THEN
                            l_exist_sug := 0;
                    END;
                
                    -- When a suggestion is specified we must associate it to the created intervention
                    IF l_data_ux_rec.id_icnp_sug_interv IS NOT NULL
                       AND l_exist_sug <> 1
                    THEN
                        l_interv_suggested_rec.id_icnp_epis_interv := l_interv_row.id_icnp_epis_interv;
                        l_interv_suggested_rec.id_icnp_sug_interv  := l_data_ux_rec.id_icnp_sug_interv;
                        l_interv_suggested_coll.extend;
                        l_interv_suggested_coll(l_interv_suggested_coll.last) := l_interv_suggested_rec;
                        l_suggested_interv := TRUE;
                    ELSIF l_data_ux_rec.id_icnp_sug_interv IS NOT NULL
                    THEN
                    
                        -- Persist the data into the database
                        ts_icnp_suggest_interv.upd(id_icnp_sug_interv_in => l_data_ux_rec.id_icnp_sug_interv,
                                                   flg_status_in         => pk_icnp_constant.g_sug_interv_status_accepted);
                        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'ICNP_SUGGEST_INTERV',
                                                      i_rowids     => l_sugg_rowids_coll,
                                                      o_error      => l_error);
                    
                    END IF;
                ELSE
                    IF l_data_ux_rec.id_icnp_sug_interv IS NULL
                       OR (l_data_ux_rec.id_icnp_sug_interv IS NOT NULL AND l_exist = 0)
                    THEN
                    
                        -- Set a temporary order recurrence plan as definitive (final status)
                        IF l_data_ux_rec.id_order_recurr_plan IS NOT NULL
                        THEN
                            l_order_recurr_rec2 := set_order_recurr_plan(i_lang                     => i_lang,
                                                                         i_prof                     => i_prof,
                                                                         i_recurr_plan_id           => l_data_ux_rec.id_order_recurr_plan,
                                                                         io_recurr_processed_coll   => l_recurr_processed_coll2,
                                                                         io_recurr_definit_ids_coll => l_recurr_definit_ids_coll2,
                                                                         io_precessed_plans         => l_processed_plan);
                        END IF;
                    
                    END IF;
                
                    -- :TODO:
                    l_interv_row2 := process_intervs(i_lang                         => i_lang,
                                                     i_prof                         => i_prof,
                                                     i_episode                      => i_episode,
                                                     i_patient                      => i_patient,
                                                     i_data_ux_rec                  => l_data_ux_rec,
                                                     i_order_recurr_rec             => l_order_recurr_rec2,
                                                     i_sysdate_tstz                 => l_sysdate_tstz,
                                                     i_interv                       => i_interv(i),
                                                     io_interv_rows_for_create_coll => l_interv_rows_for_create_coll2,
                                                     io_interv_rows_for_update_coll => l_interv_rows_for_update_coll2,
                                                     io_interv_rows_all_coll        => l_interv_rows_all_coll2,
                                                     io_precessed_plans             => l_processed_plan);
                    l_assoc_interv.extend;
                    l_assoc_interv(l_assoc_interv.last) := l_interv_row2.id_icnp_epis_interv;
                
                    BEGIN
                        SELECT 1
                          INTO l_exist_sug
                          FROM icnp_suggest_interv isi
                         WHERE isi.id_composition = l_data_ux_rec.id_composition_interv
                           AND isi.id_patient = i_patient
                           AND isi.id_episode = i_episode
                           AND isi.id_icnp_epis_interv = l_interv_row2.id_icnp_epis_interv
                           AND isi.flg_status = pk_icnp_constant.g_sug_interv_status_accepted;
                    EXCEPTION
                        WHEN no_data_found THEN
                            l_exist_sug := 0;
                    END;
                
                    -- When a suggestion is specified we must associate it to the created intervention
                    IF l_data_ux_rec.id_icnp_sug_interv IS NOT NULL
                       AND l_exist_sug <> 1
                    THEN
                        l_interv_suggested_rec.id_icnp_epis_interv := l_interv_row2.id_icnp_epis_interv;
                        l_interv_suggested_rec.id_icnp_sug_interv  := l_data_ux_rec.id_icnp_sug_interv;
                        l_interv_suggested_coll.extend;
                        l_interv_suggested_coll(l_interv_suggested_coll.last) := l_interv_suggested_rec;
                        l_suggested_interv := TRUE;
                    ELSIF l_data_ux_rec.id_icnp_sug_interv IS NOT NULL
                    THEN
                    
                        -- Persist the data into the database
                        ts_icnp_suggest_interv.upd(id_icnp_sug_interv_in => l_data_ux_rec.id_icnp_sug_interv,
                                                   flg_status_in         => pk_icnp_constant.g_sug_interv_status_accepted);
                        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'ICNP_SUGGEST_INTERV',
                                                      i_rowids     => l_sugg_rowids_coll,
                                                      o_error      => l_error);
                    
                    END IF;
                
                END IF;
            END LOOP;
        
            -- Associates a set of ICNP diagnosis with an episode
            IF i_diag IS NOT NULL
               AND i_diag.count > 0
            THEN
                l_diag_row_coll := create_icnp_diags(i_lang         => i_lang,
                                                     i_prof         => i_prof,
                                                     i_episode      => i_episode,
                                                     i_patient      => i_patient,
                                                     i_diag         => i_diag,
                                                     i_exp_res      => i_exp_res,
                                                     i_notes        => i_notes,
                                                     i_sysdate_tstz => l_sysdate_tstz);
                l_type_assoc    := pk_icnp_constant.g_flg_type_assoc_d; --DIAGNOSIS
            ELSE
                l_type_assoc := pk_icnp_constant.g_flg_type_assoc_i; --INTERVENTION
            END IF;
        
            -- Creates the pre-processed set of intervention records
            IF l_interv_rows_for_create_coll IS NOT NULL
               AND l_interv_rows_for_create_coll.count > 0
            THEN
                pk_icnp_interv.create_intervs(i_lang            => i_lang,
                                              i_prof            => i_prof,
                                              i_interv_row_coll => l_interv_rows_for_create_coll,
                                              i_sysdate_tstz    => l_sysdate_tstz);
                --The association is created as "association" and  intervention does not exist, the moment should be "creation"
                IF l_moment_assoc = pk_icnp_constant.g_moment_assoc_a
                THEN
                    --Association                        
                    l_moment_assoc := pk_icnp_constant.g_moment_assoc_c; --Creation
                END IF;
            
            END IF;
            IF l_interv_rows_for_create_coll2 IS NOT NULL
               AND l_interv_rows_for_create_coll2.count > 0
            THEN
                pk_icnp_interv.create_intervs(i_lang            => i_lang,
                                              i_prof            => i_prof,
                                              i_interv_row_coll => l_interv_rows_for_create_coll2,
                                              i_sysdate_tstz    => l_sysdate_tstz);
                --The association is created as "association" and  intervention does not exist, the moment should be "creation"
                IF l_moment_assoc = pk_icnp_constant.g_moment_assoc_a
                THEN
                    --Association                        
                    l_moment_assoc := pk_icnp_constant.g_moment_assoc_c; --Creation
                END IF;
            END IF;
        
            -- :TODO:
            -- fazer update às intervs
        
            -- associate the suggested intervention to the prescription
            IF l_interv_suggested_coll IS NOT NULL
               AND l_interv_suggested_coll.count > 0
            THEN
                log_debug('l_interv_suggested_coll:' || l_interv_suggested_coll.count, c_func_name);
                pk_icnp_suggestion.set_suggs_status_accept(i_lang                  => i_lang,
                                                           i_prof                  => i_prof,
                                                           i_episode_id            => i_episode,
                                                           i_interv_suggested_coll => l_interv_suggested_coll,
                                                           i_sysdate_tstz          => l_sysdate_tstz);
            END IF;
        
            -- Asssociates a set of interventions with a set of diagnosis
            IF l_interv_suggested_coll IS empty
            THEN
                IF l_assoc_interv IS NOT NULL
                   AND l_assoc_interv.count > 0
                THEN
                    create_assoc_interv_diag(i_lang           => i_lang,
                                             i_prof           => i_prof,
                                             i_interv         => i_interv,
                                             i_diag_row_coll  => l_diag_row_coll,
                                             i_cur_diag       => i_cur_diag,
                                             i_assoc_interv   => l_assoc_interv,
                                             i_moment_assoc   => l_moment_assoc,
                                             i_flg_type_assoc => l_type_assoc);
                END IF;
            END IF;
        
            IF l_data_ux_rec.flg_time != pk_icnp_constant.g_epis_interv_time_next_epis
            THEN
                -- Prepare the order plan executions and creates the initial set of executions
                prepare_and_create_execs(i_lang                    => i_lang,
                                         i_prof                    => i_prof,
                                         i_recurr_definit_ids_coll => l_recurr_definit_ids_coll,
                                         i_interv_row_coll         => l_interv_rows_all_coll,
                                         i_sysdate_tstz            => l_sysdate_tstz);
            END IF;
        
            -- create intervention alerts
            create_alerts(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode);
        ELSE
            -- Associates a set of ICNP diagnosis with an episode
            IF i_diag IS NOT NULL
               AND i_diag.count > 0
            THEN
                l_diag_row_coll := create_icnp_diags(i_lang         => i_lang,
                                                     i_prof         => i_prof,
                                                     i_episode      => i_episode,
                                                     i_patient      => i_patient,
                                                     i_diag         => i_diag,
                                                     i_exp_res      => i_exp_res,
                                                     i_notes        => i_notes,
                                                     i_sysdate_tstz => l_sysdate_tstz);
            END IF;
        END IF;
    
        --CODE TO RESOLVE AN ISSUE REGARDING PRE-DEFINED FREQUENCIES WITH START DATE DIFFERENT FROM THE PRE-DEFINED HOUR        
        IF i_interv IS NOT NULL
           AND i_interv.count > 0
        THEN
            -- insert interventions
            FOR i IN i_interv.first .. i_interv.last
            LOOP
                -- Converts the raw data record into a typed record
                l_data_ux_rec := populate_create_interv_rec(i_lang => i_lang, i_prof => i_prof, i_values => i_interv(i));
            
                DECLARE
                
                    l_interv              table_varchar;
                    l_dt_plan             interv_icnp_ea.dt_plan%TYPE;
                    l_dt_next             interv_icnp_ea.dt_plan%TYPE;
                    l_order_recurr_option order_recurr_plan.id_order_recurr_option%TYPE;
                    l_occurences          order_recurr_plan.occurrences%TYPE;
                    l_duration            order_recurr_plan.duration%TYPE;
                    l_unit_meas_duration  order_recurr_plan.id_unit_meas_duration%TYPE;
                    l_end_date            order_recurr_plan.end_date%TYPE;
                
                    o_order_recurr_desc   VARCHAR2(100);
                    o_order_recurr_option order_recurr_plan.id_order_recurr_option%TYPE;
                    o_start_date          order_recurr_plan.start_date%TYPE;
                    o_occurrences         order_recurr_plan.occurrences%TYPE;
                    o_duration            order_recurr_plan.duration%TYPE;
                    o_unit_meas_duration  order_recurr_plan.id_unit_meas_duration%TYPE;
                    o_end_date            order_recurr_plan.end_date%TYPE;
                    o_flg_end_by_editable VARCHAR2(1);
                    l_processed_plan      t_processed_plan;
                    o_order_recurr_plan   order_recurr_plan.id_order_recurr_plan%TYPE;
                    o_error               t_error_out;
                
                BEGIN
                
                    l_interv := table_varchar();
                
                    l_interv.extend();
                
                    SELECT iei.id_icnp_epis_interv
                      INTO l_interv(1)
                      FROM icnp_epis_intervention iei
                     WHERE iei.id_order_recurr_plan = l_data_ux_rec.id_order_recurr_plan;
                
                    l_interv.extend();
                    l_interv(2) := l_data_ux_rec.id_composition_diag;
                    l_interv.extend();
                    l_interv(3) := l_data_ux_rec.flg_time;
                    l_interv.extend();
                    l_interv(4) := i_interv(i) (4);
                    l_interv.extend();
                    l_interv(5) := l_data_ux_rec.id_order_recurr_plan;
                    l_interv.extend();
                    l_interv(6) := l_data_ux_rec.flg_prn;
                    l_interv.extend();
                    l_interv(7) := l_data_ux_rec.prn_notes;
                    l_interv.extend();
                    l_interv(8) := l_data_ux_rec.notes;
                    l_interv.extend();
                    l_interv(9) := l_data_ux_rec.id_icnp_sug_interv;
                    l_interv.extend();
                    --l_interv(10)
                    l_interv.extend();
                    l_interv(11) := l_data_ux_rec.id_icnp_sug_interv;
                
                    SELECT iie.dt_next, iie.dt_plan
                      INTO l_dt_next, l_dt_plan
                      FROM interv_icnp_ea iie
                     WHERE iie.id_icnp_epis_interv = l_interv(1);
                
                    SELECT ocr.id_order_recurr_option,
                           ocr.occurrences,
                           ocr.duration,
                           ocr.id_unit_meas_duration,
                           ocr.end_date
                      INTO l_order_recurr_option, l_occurences, l_duration, l_unit_meas_duration, l_end_date
                      FROM order_recurr_plan ocr
                     WHERE ocr.id_order_recurr_plan = l_interv(5);
                
                    IF l_dt_next <> l_dt_plan
                    THEN
                    
                        IF NOT pk_order_recurrence_core.edit_order_recurr_plan(i_lang                   => i_lang,
                                                                               i_prof                   => i_prof,
                                                                               i_order_recurr_area      => 'ICNP',
                                                                               i_order_recurr_option    => l_order_recurr_option,
                                                                               i_start_date             => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                         i_prof,
                                                                                                                                         l_interv(4),
                                                                                                                                         NULL),
                                                                               i_occurrences            => l_occurences,
                                                                               i_duration               => l_duration,
                                                                               i_unit_meas_duration     => l_unit_meas_duration,
                                                                               i_end_date               => l_end_date,
                                                                               i_order_recurr_plan_from => NULL,
                                                                               o_order_recurr_desc      => o_order_recurr_desc,
                                                                               o_order_recurr_option    => o_order_recurr_option,
                                                                               o_start_date             => o_start_date,
                                                                               o_occurrences            => o_occurrences,
                                                                               o_duration               => o_duration,
                                                                               o_unit_meas_duration     => o_unit_meas_duration,
                                                                               o_end_date               => o_end_date,
                                                                               o_flg_end_by_editable    => o_flg_end_by_editable,
                                                                               o_order_recurr_plan      => o_order_recurr_plan,
                                                                               o_error                  => o_error)
                        THEN
                            pk_icnp_util.raise_unexpected_error('pk_order_recurrence_api_db.edit_order_recurr_plan',
                                                                o_error);
                        END IF;
                    
                        l_interv(10) := o_order_recurr_plan;
                    
                        IF NOT
                            pk_order_recurrence_core.set_order_recurr_instructions(i_lang                => i_lang,
                                                                                   i_prof                => i_prof,
                                                                                   i_order_recurr_plan   => l_interv(10),
                                                                                   i_start_date          => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                          i_prof,
                                                                                                                                          l_interv(4),
                                                                                                                                          NULL),
                                                                                   i_occurrences         => l_occurences,
                                                                                   i_duration            => l_duration,
                                                                                   i_unit_meas_duration  => l_unit_meas_duration,
                                                                                   i_end_date            => l_end_date,
                                                                                   o_order_recurr_desc   => o_order_recurr_desc,
                                                                                   o_order_recurr_option => o_order_recurr_option,
                                                                                   o_start_date          => o_start_date,
                                                                                   o_occurrences         => o_occurrences,
                                                                                   o_duration            => o_duration,
                                                                                   o_unit_meas_duration  => o_unit_meas_duration,
                                                                                   o_end_date            => o_end_date,
                                                                                   o_flg_end_by_editable => o_flg_end_by_editable,
                                                                                   o_error               => o_error)
                        THEN
                            pk_icnp_util.raise_unexpected_error('pk_order_recurrence_api_db.set_order_recurr_instructions',
                                                                o_error);
                        END IF;
                    
                        update_icnp_intervention(i_lang             => i_lang,
                                                 i_prof             => i_prof,
                                                 i_interv           => l_interv,
                                                 i_sysdate_tstz     => i_sysdate_tstz,
                                                 i_origin           => pk_icnp_constant.g_interv_plan_editing,
                                                 o_interv_id        => o_interv_id,
                                                 io_precessed_plans => l_processed_plan);
                    
                        updt_icnp_plan(i_lang => i_lang, i_prof => i_prof, i_interv => l_interv);
                    END IF;
                EXCEPTION
                    WHEN OTHERS THEN
                        CONTINUE;
                END;
            END LOOP;
        END IF;
    
        o_interv_id := l_interv_id;
    
    END create_icnp_interv;

    /********************************************************************************************
    * Returns ICNP's left_state of interv
    *
    * @param      i_lang                      Preferred language ID for this professional
    * @param      i_prof                      Object (professional ID, institution ID, software ID)
    * @param      i_flg_status                FLG_STAUS  status of icnp_epis_interv
    * @param      i_prev_flg_status           PREV_FLG_STAUS previous status of icnp_epis_interv
    *
    * @return                varchar left_state of interv
    *
    * @author                Nuno Neves
    * @version               2.5.1
    * @since                 2012/12/20
    *********************************************************************************************/
    FUNCTION get_left_state_interv
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_flg_status      IN icnp_epis_intervention.flg_status%TYPE,
        i_prev_flg_status IN icnp_epis_intervention.flg_status%TYPE
    ) RETURN VARCHAR2 IS
        msg_solved_at       sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'CPLAN_T205');
        msg_created_at      sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'CPLAN_T091');
        msg_activated_at    sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'ICNP_T182');
        msg_cancelled_at    sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'CPLAN_T096');
        msg_edited_at       sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'CPLAN_T093');
        msg_suspended_at    sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'CPLAN_T097');
        msg_discontinued_at sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'CPLAN_T206');
    BEGIN
    
        CASE
        --i_flg_status=A i_prev_flg_status=NULL
            WHEN i_flg_status = pk_icnp_constant.g_epis_interv_status_requested
                 AND i_prev_flg_status IS NULL THEN
                g_prev_status_executed := pk_alert_constant.g_no;
                RETURN msg_created_at;
                --i_flg_status=F i_prev_flg_status=A
            WHEN i_flg_status = pk_icnp_constant.g_epis_interv_status_executed
                 AND i_prev_flg_status = pk_icnp_constant.g_epis_interv_status_requested THEN
                g_prev_status_executed := pk_alert_constant.g_no;
                RETURN msg_solved_at;
                --i_flg_status=I i_prev_flg_status=A
            WHEN i_flg_status = pk_icnp_constant.g_epis_interv_status_suspended
                 AND i_prev_flg_status = pk_icnp_constant.g_epis_interv_status_requested THEN
                g_prev_status_executed := pk_alert_constant.g_no;
                RETURN msg_suspended_at;
                --i_flg_status=C i_prev_flg_status=A
            WHEN i_flg_status = pk_icnp_constant.g_epis_interv_status_cancelled
                 AND i_prev_flg_status = pk_icnp_constant.g_epis_interv_status_requested THEN
                g_prev_status_executed := pk_alert_constant.g_no;
                RETURN msg_cancelled_at;
                --i_flg_status=A i_prev_flg_status=I
            WHEN i_flg_status = pk_icnp_constant.g_epis_interv_status_requested
                 AND i_prev_flg_status = pk_icnp_constant.g_epis_interv_status_suspended THEN
                g_prev_status_executed := pk_alert_constant.g_no;
                RETURN msg_activated_at;
                --i_flg_status=C i_prev_flg_status=I
            WHEN i_flg_status = pk_icnp_constant.g_epis_interv_status_cancelled
                 AND i_prev_flg_status = pk_icnp_constant.g_epis_interv_status_suspended THEN
                g_prev_status_executed := pk_alert_constant.g_no;
                RETURN msg_cancelled_at;
                --i_flg_status=T i_prev_flg_status=I
            WHEN i_flg_status = pk_icnp_constant.g_epis_interv_status_discont
                 AND i_prev_flg_status = pk_icnp_constant.g_epis_interv_status_suspended THEN
                g_prev_status_executed := pk_alert_constant.g_no;
                RETURN msg_discontinued_at;
            WHEN i_flg_status = pk_icnp_constant.g_epis_interv_status_discont THEN
                RETURN msg_discontinued_at;
                --i_flg_status=E i_prev_flg_status=A
        --WHEN i_flg_status = pk_icnp_constant.g_epis_interv_status_ongoing
        --AND i_prev_flg_status = pk_icnp_constant.g_epis_interv_status_requested THEN
        --RETURN msg_executed_at;
        --i_flg_status=I i_prev_flg_status=E
            WHEN i_flg_status = pk_icnp_constant.g_epis_interv_status_suspended
                 AND i_prev_flg_status = pk_icnp_constant.g_epis_interv_status_ongoing THEN
                g_prev_status_executed := pk_alert_constant.g_no;
                RETURN msg_suspended_at;
                --i_flg_status=F i_prev_flg_status=E
            WHEN i_flg_status = pk_icnp_constant.g_epis_interv_status_executed
                 AND i_prev_flg_status = pk_icnp_constant.g_epis_interv_status_ongoing THEN
                g_prev_status_executed := pk_alert_constant.g_no;
                RETURN msg_solved_at;
                --i_flg_status=T i_prev_flg_status=E
            WHEN i_flg_status = pk_icnp_constant.g_epis_interv_status_discont
                 AND i_prev_flg_status = pk_icnp_constant.g_epis_interv_status_ongoing THEN
                g_prev_status_executed := pk_alert_constant.g_no;
                RETURN msg_discontinued_at;
                --i_flg_status=E i_prev_flg_status=I
            WHEN i_flg_status = pk_icnp_constant.g_epis_interv_status_ongoing
                 AND i_prev_flg_status = pk_icnp_constant.g_epis_interv_status_suspended THEN
                g_prev_status_executed := pk_alert_constant.g_no;
                RETURN msg_activated_at;
                --i_flg_status=A i_prev_flg_status=E
            WHEN i_flg_status = pk_icnp_constant.g_epis_interv_status_requested
                 AND i_prev_flg_status = pk_icnp_constant.g_epis_interv_status_ongoing THEN
                g_prev_status_executed := pk_alert_constant.g_no;
                RETURN msg_edited_at;
                --i_flg_status=i_prev_flg_status
            WHEN i_flg_status = i_prev_flg_status
                 AND g_prev_status_executed = pk_alert_constant.g_no THEN
                g_prev_status_executed := pk_alert_constant.g_no;
                RETURN msg_edited_at;
            ELSE
                RETURN NULL;
        END CASE;
    END get_left_state_interv;

    /********************************************************************************************
    * Returns ICNP's left_state of exec
    *
    * @param      i_lang                      Preferred language ID for this professional
    * @param      i_prof                      Object (professional ID, institution ID, software ID)
    * @param      i_flg_status                FLG_STAUS icnp_interv_plan
    * @param      i_id_icnp_interv_plan       id_icnp_interv_plan
    *
    * @return                varchar left_state of exec
    *
    * @author                Nuno Neves
    * @version               2.5.1
    * @since                 2012/12/20
    *********************************************************************************************/
    FUNCTION get_left_state_exec
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_flg_status          IN icnp_epis_intervention.flg_status%TYPE,
        i_id_icnp_interv_plan IN icnp_interv_plan.id_icnp_interv_plan%TYPE
        
    ) RETURN VARCHAR2 IS
        msg_executed_at      sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'ICNP_T181');
        msg_execution_cancel sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'ICNP_T168') || ':';
    
        l_id_icnp_epis_interv icnp_interv_plan.id_icnp_epis_interv%TYPE;
        l_dt_cancel_tstz      icnp_interv_plan.dt_cancel_tstz%TYPE;
        l_flg_status          icnp_epis_intervention.flg_status%TYPE;
        l_dt_cancel           icnp_epis_intervention.dt_cancel%TYPE;
    BEGIN
    
        CASE
            WHEN i_flg_status = pk_icnp_constant.g_interv_plan_status_executed THEN
                g_prev_status_executed := pk_alert_constant.g_yes;
                RETURN msg_executed_at;
            WHEN i_flg_status = pk_icnp_constant.g_interv_plan_status_cancelled THEN
            
                SELECT iip.id_icnp_epis_interv, iip.dt_cancel_tstz
                  INTO l_id_icnp_epis_interv, l_dt_cancel_tstz
                  FROM icnp_interv_plan iip
                 WHERE iip.id_icnp_interv_plan = i_id_icnp_interv_plan;
            
                SELECT iei.flg_status, coalesce(iei.dt_close_tstz, iei.dt_cancel)
                  INTO l_flg_status, l_dt_cancel
                  FROM icnp_epis_intervention iei
                 WHERE iei.id_icnp_epis_interv = l_id_icnp_epis_interv;
            
                IF l_flg_status IN
                   (pk_icnp_constant.g_epis_interv_status_cancelled, pk_icnp_constant.g_epis_interv_status_discont)
                   AND l_dt_cancel_tstz >= l_dt_cancel
                THEN
                    RETURN NULL;
                ELSE
                    RETURN msg_execution_cancel;
                END IF;
            ELSE
                RETURN NULL;
        END CASE;
    END get_left_state_exec;

    /********************************************************************************************
    * Gets the associated diagnosis of a list of interventions
    *
    * @param      i_lang               Preferred language ID for this professional
    * @param      i_prof               Professional structure
    * @param      i_epis_interv        Intervention id
    * @param      i_dt_assoc           Date of association 
    * @param      i_momment_assoc      Moment of association
    *
    * @return               varchar2 with associated diagnosis
    *
    * @raises
    *
    * @author                Nuno Neves
    * @version               
    * @since                 2012/02/27
    *********************************************************************************************/
    FUNCTION get_interv_rel_by_date
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis_interv  IN icnp_epis_intervention.id_icnp_epis_interv%TYPE,
        i_dt_assoc     IN icnp_epis_dg_int_hist.dt_hist%TYPE,
        i_moment_assoc IN icnp_epis_dg_int_hist.flg_moment_assoc%TYPE
    ) RETURN VARCHAR2 IS
        l_diag           VARCHAR2(32767);
        l_icnp_epis_diag icnp_epis_diag_interv.id_icnp_epis_diag%TYPE;
    BEGIN
        --obter a descrição
        IF i_moment_assoc = pk_icnp_constant.g_moment_assoc_a
        THEN
        
            SELECT substr(concatenate(desc_diag),
                          1,
                          length(concatenate(desc_diag)) - length(pk_icnp_constant.g_word_sep)) ||
                   decode(concatenate(desc_diag), NULL, NULL, pk_icnp_constant.g_word_end)
              INTO l_diag
              FROM (SELECT DISTINCT pk_translation.get_translation(i_lang, ic2.code_icnp_composition) ||
                                    pk_icnp_constant.g_word_sep desc_diag
                      FROM icnp_epis_diagnosis ied
                      JOIN icnp_epis_dg_int_hist iedih
                        ON iedih.id_icnp_epis_diag = ied.id_icnp_epis_diag
                      JOIN icnp_epis_intervention iei
                        ON iei.id_icnp_epis_interv = iedih.id_icnp_epis_interv
                      JOIN icnp_composition ic2
                        ON ic2.id_composition = ied.id_composition
                     WHERE iei.id_icnp_epis_interv = i_epis_interv
                       AND trunc_timestamp_to_minutes(i_lang, i_prof, iedih.dt_hist) < i_dt_assoc
                       AND iedih.flg_iud = pk_icnp_constant.g_iedih_flg_uid_i
                    --AND iedih.flg_moment_assoc = i_moment_assoc
                     ORDER BY desc_diag);
        ELSIF i_moment_assoc = pk_icnp_constant.g_moment_assoc_c
        THEN
            SELECT iedi.id_icnp_epis_diag
              INTO l_icnp_epis_diag
              FROM icnp_epis_diag_interv iedi
             WHERE iedi.id_icnp_epis_interv = i_epis_interv;
        
            SELECT substr(concatenate(desc_diag),
                          1,
                          length(concatenate(desc_diag)) - length(pk_icnp_constant.g_word_sep)) ||
                   decode(concatenate(desc_diag), NULL, NULL, pk_icnp_constant.g_word_end)
              INTO l_diag
              FROM (SELECT DISTINCT pk_translation.get_translation(i_lang, ic2.code_icnp_composition) ||
                                    pk_icnp_constant.g_word_sep desc_diag
                      FROM (SELECT *
                              FROM (SELECT *
                                      FROM (SELECT id_icnp_epis_diag, id_composition, NULL dt_created_hist
                                              FROM icnp_epis_diagnosis
                                             WHERE id_icnp_epis_diag = l_icnp_epis_diag
                                            UNION ALL
                                            SELECT id_icnp_epis_diag, id_composition, dt_created_hist
                                              FROM icnp_epis_diagnosis_hist i
                                             WHERE i.id_icnp_epis_diag = l_icnp_epis_diag) t
                                     ORDER BY t.dt_created_hist ASC) r
                             WHERE rownum = 1) ied
                      JOIN icnp_epis_dg_int_hist iedih
                        ON iedih.id_icnp_epis_diag = ied.id_icnp_epis_diag
                      JOIN icnp_epis_intervention iei
                        ON iei.id_icnp_epis_interv = iedih.id_icnp_epis_interv
                      JOIN icnp_composition ic2
                        ON ic2.id_composition = ied.id_composition
                     WHERE iei.id_icnp_epis_interv = i_epis_interv
                          --AND trunc_timestamp_to_minutes(i_lang, i_prof, iedih.dt_hist) < i_dt_assoc
                       AND iedih.flg_iud = pk_icnp_constant.g_iedih_flg_uid_i --INSERT
                       AND iedih.flg_moment_assoc = i_moment_assoc
                     ORDER BY desc_diag);
        END IF;
    
        RETURN l_diag;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_interv_rel_by_date;

    /********************************************************************************************
    * get timestamp truncated to minutes (seconds part will be zero)
    *
    * @param       i_lang                 preferred language id    
    * @param       i_prof                 professional structure
    * @param       i_timestamp            timestamp to truncate
    *
    * @return      tsltz                  timestamp truncated to minutes
    *
    * @author                             Nuno Neves
    * @since                              27-02-2012
    ********************************************************************************************/
    FUNCTION trunc_timestamp_to_minutes
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
    BEGIN
        RETURN pk_date_utils.get_string_tstz(i_lang,
                                             i_prof,
                                             to_char(pk_date_utils.get_timestamp_insttimezone(i_lang,
                                                                                              i_prof.institution,
                                                                                              i_timestamp),
                                                     'YYYYMMDDHH24MI') || '00',
                                             NULL);
    END trunc_timestamp_to_minutes;

    /********************************************************************************************
    * Returns the list of interventions descriptions (optionally intructions) associated to a diagnosis
    *
    * @param      i_lang                    Preferred language ID for this professional
    * @param      i_prof                    Object (professional ID, institution ID, software ID)
    * @param      i_icnp_epis_diag          Diagnosis ID
    * @param      i_show_instr              Show intervention instructions (Y - yes, N - No)
    * @param      i_sep                     Word separator character
    * @param      i_end                     Word end character
    * @param      i_dt_limit                Maximum date of the intervention (Used to get differences)
    * @param      i_moment_assoc            Moment of association
    * @param      i_type_assoc              Type of association
    *
    * @return             String with interventions description (optionally intructions)
    *
    * @author                Nuno Neves
    * @version               
    * @since                 2012/03/12
    *********************************************************************************************/
    FUNCTION get_diag_intervs_hist_desc
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_icnp_epis_diag IN icnp_epis_diagnosis.id_icnp_epis_diag%TYPE,
        i_show_instr     IN VARCHAR2,
        i_sep            IN VARCHAR2,
        i_end            IN VARCHAR2,
        i_dt_limit       IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_moment_assoc   IN table_varchar,
        i_type_assoc     IN icnp_epis_diag_interv.flg_type_assoc%TYPE
    ) RETURN VARCHAR2 IS
        l_result VARCHAR2(4000 CHAR);
    BEGIN
        SELECT substr(concatenate(desc_interv),
                      1,
                      length(concatenate(desc_interv)) - length(nvl(i_sep, pk_icnp_constant.g_word_sep))) ||
               decode(concatenate(desc_interv), NULL, NULL, nvl(i_end, pk_icnp_constant.g_word_end))
          INTO l_result
          FROM (SELECT DISTINCT pk_translation.get_translation(i_lang, ic.code_icnp_composition) ||
                                 decode(i_show_instr,
                                        pk_alert_constant.g_yes,
                                        pk_icnp_constant.g_word_space || pk_icnp_constant.g_word_open_brac ||
                                        get_interv_instructions(i_lang, i_prof, iei.id_icnp_epis_interv) ||
                                        nvl(i_sep,
                                            pk_icnp_constant.g_word_sep ||
                                            decode(iei.flg_prn,
                                                   NULL,
                                                   NULL,
                                                   pk_message.get_message(i_lang, i_prof, 'CIPE_T138') ||
                                                   pk_icnp_constant.g_word_space) ||
                                            decode(iei.flg_prn,
                                                   NULL,
                                                   NULL,
                                                   pk_sysdomain.get_domain(pk_icnp_constant.g_domain_epis_interv_prn,
                                                                           iei.flg_prn,
                                                                           i_lang) || pk_icnp_constant.g_word_sep) || CASE
                                                WHEN iei.prn_notes IS NULL THEN
                                                 NULL
                                                ELSE
                                                 pk_message.get_message(i_lang, i_prof, 'CIPE_T139') || pk_icnp_constant.g_word_space
                                            END || CASE
                                                WHEN iei.prn_notes IS NULL THEN
                                                 NULL
                                                ELSE
                                                 iei.prn_notes || pk_icnp_constant.g_word_sep
                                            END) || pk_icnp_constant.g_word_close_brac ||
                                        pk_icnp_constant.g_word_open_brac ||
                                        pk_sysdomain.get_domain('ICNP_EPIS_INTERVENTION.FLG_STATUS',
                                                                iei.flg_status,
                                                                i_lang) || pk_icnp_constant.g_word_close_brac ||
                                        nvl(i_sep, pk_icnp_constant.g_word_sep),
                                        nvl(i_sep, pk_icnp_constant.g_word_sep)) desc_interv
                  FROM icnp_epis_diagnosis ied
                  JOIN icnp_epis_dg_int_hist iedih
                    ON ied.id_icnp_epis_diag = iedih.id_icnp_epis_diag
                  JOIN icnp_epis_intervention iei
                    ON iedih.id_icnp_epis_interv = iei.id_icnp_epis_interv
                  JOIN icnp_composition ic
                    ON iei.id_composition = ic.id_composition
                 WHERE ied.id_icnp_epis_diag = i_icnp_epis_diag
                   AND iei.id_episode_destination IS NULL
                   AND iedih.flg_status = pk_icnp_constant.g_interv_flg_status_a
                   AND iedih.flg_iud = pk_icnp_constant.g_iedih_flg_uid_i
                   AND iedih.flg_moment_assoc IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                   column_value
                                                    FROM TABLE(i_moment_assoc) t) --ASSOC
                   AND iedih.flg_type_assoc = i_type_assoc
                      --AND iedih.flg_status_rel = pk_icnp_constant.g_interv_rel_active
                   AND pk_icnp_fo.trunc_timestamp_to_minutes(i_lang, i_prof, iedih.dt_hist) <=
                       nvl(i_dt_limit, iedih.dt_hist));
    
        RETURN l_result;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_diag_intervs_hist_desc;

    /**
    * Get all information related to nursing interventions (relationships)
    * 
    * @param i_lang                              language identifier
    * @param i_prof                              logged professional structure
    * @param i_id_icnp_epis_inter_array          array with interventions ids
    * @param o_interv                            Interventions cursor                                               
    * @param o_diag                              Diagnoses cursor
    * @param o_task                              MCDT's cursor
    *              
    *
    * @author               Nuno Neves
    * @version               2.6.1
    * @since                2012/03/05
    */
    PROCEDURE get_icnp_rel_info
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_icnp_epis_inter_array IN table_number,
        o_interv                   OUT pk_types.cursor_type,
        o_diag                     OUT pk_types.cursor_type,
        o_task                     OUT pk_types.cursor_type
    ) IS
    BEGIN
        --Interventions
        OPEN o_interv FOR
            SELECT iei.id_icnp_epis_interv,
                   pk_translation.get_translation(i_lang, ic.code_icnp_composition) desc_interv
              FROM icnp_epis_intervention iei
              JOIN icnp_composition ic
                ON ic.id_composition = iei.id_composition
             WHERE iei.id_icnp_epis_interv IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                column_value
                                                 FROM TABLE(i_id_icnp_epis_inter_array) t);
        --Diagnosis
        OPEN o_diag FOR
            SELECT ied.id_icnp_epis_diag,
                   pk_translation.get_translation(i_lang, ic.code_icnp_composition) desc_diag,
                   iedi.id_icnp_epis_interv
              FROM icnp_epis_diagnosis ied
              JOIN icnp_composition ic
                ON ic.id_composition = ied.id_composition
              JOIN icnp_epis_diag_interv iedi
                ON iedi.id_icnp_epis_diag = ied.id_icnp_epis_diag
               AND iedi.flg_status_rel IN
                   (pk_icnp_constant.g_interv_rel_reactivated, pk_icnp_constant.g_interv_rel_active)
             WHERE iedi.id_icnp_epis_interv IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                 column_value
                                                  FROM TABLE(i_id_icnp_epis_inter_array) t);
        --MCDT's
        OPEN o_task FOR
            SELECT DISTINCT isi.id_task_type,
                            isi.id_req id_unique_requisition,
                            pk_icnp_suggestion.get_sugg_task_description(i_lang, i_prof, isi.id_req, isi.id_task_type) desc_mcdt,
                            isi.id_icnp_epis_interv
            --pk_icnp_suggestion.get_sugg_task_instructions(i_lang, i_prof, isi.id_req, isi.id_task_type) task_description
              FROM icnp_suggest_interv isi
             WHERE isi.flg_status = pk_icnp_constant.g_sug_interv_status_accepted
               AND isi.flg_status_rel IN
                   (pk_icnp_constant.g_interv_rel_reactivated, pk_icnp_constant.g_interv_rel_active)
               AND isi.id_icnp_epis_interv IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                column_value
                                                 FROM TABLE(i_id_icnp_epis_inter_array) t);
    
    END get_icnp_rel_info;

    /**
    * Define the status of the relationship with nursing intervention
    * 
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_rel_array    array with information with actions for nursing interventions
    *              
    *
    * @author               Nuno Neves
    * @version               2.6.1
    * @since                2012/03/05
    */
    PROCEDURE set_status_rel_icnp
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_rel_array IN table_table_varchar
    ) IS
        l_table table_varchar;
        l_rows  table_varchar := table_varchar();
        -- Data structures related with error handling
        l_error t_error_out;
    
        l_icnp_suggest_interv      ts_icnp_suggest_interv.icnp_suggest_interv_tc;
        l_icnp_epis_diag_interv    ts_icnp_epis_diag_interv.icnp_epis_diag_interv_tc;
        l_id_icnp_epis_diag_interv icnp_epis_diag_interv.id_icnp_epis_diag_interv%TYPE;
        l_id_icnp_sug_interv       icnp_suggest_interv.id_icnp_sug_interv%TYPE;
        l_varchar                  icnp_suggest_interv.flg_status_rel%TYPE;
    BEGIN
    
        IF i_rel_array IS NOT NULL
           OR i_rel_array.count > 0
        THEN
        
            FOR i IN 1 .. i_rel_array.count
            LOOP
                l_table   := i_rel_array(i);
                l_varchar := l_table(4);
                --Diagnosis
                IF l_table(3) = pk_icnp_constant.g_diagnosis
                THEN
                
                    SELECT iedi.id_icnp_epis_diag_interv
                      INTO l_id_icnp_epis_diag_interv
                      FROM icnp_epis_diag_interv iedi
                     WHERE iedi.id_icnp_epis_interv = l_table(1)
                       AND iedi.id_icnp_epis_diag = l_table(2)
                       AND iedi.flg_status_rel IN
                           (pk_icnp_constant.g_interv_rel_active, pk_icnp_constant.g_interv_rel_reactivated);
                
                    ts_icnp_epis_diag_interv.upd(id_icnp_epis_diag_interv_in => l_id_icnp_epis_diag_interv,
                                                 flg_status_rel_in           => l_varchar,
                                                 rows_out                    => l_rows);
                    t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'ICNP_EPIS_DIAG_INTERV',
                                                  i_rowids     => l_rows,
                                                  o_error      => l_error);
                
                    SELECT iedi.*
                      BULK COLLECT
                      INTO l_icnp_epis_diag_interv
                      FROM icnp_epis_diag_interv iedi
                     WHERE iedi.id_icnp_epis_diag_interv = l_id_icnp_epis_diag_interv;
                
                    FOR x IN 1 .. l_icnp_epis_diag_interv.count
                    LOOP
                        ts_icnp_epis_dg_int_hist.ins(id_icnp_epis_dg_int_hist_in => ts_icnp_epis_dg_int_hist.next_key,
                                                     id_icnp_epis_diag_interv_in => l_icnp_epis_diag_interv(x).id_icnp_epis_diag_interv,
                                                     id_icnp_epis_diag_in        => l_icnp_epis_diag_interv(x).id_icnp_epis_diag,
                                                     id_icnp_epis_interv_in      => l_icnp_epis_diag_interv(x).id_icnp_epis_interv,
                                                     flg_status_in               => l_icnp_epis_diag_interv(x).flg_status,
                                                     dt_inactivation_in          => l_icnp_epis_diag_interv(x).dt_inactivation,
                                                     dt_hist_in                  => current_timestamp,
                                                     flg_iud_in                  => 'I',
                                                     id_prof_assoc_in            => l_icnp_epis_diag_interv(x).id_prof_assoc,
                                                     flg_moment_assoc_in         => l_icnp_epis_diag_interv(x).flg_moment_assoc,
                                                     flg_status_rel_in           => l_icnp_epis_diag_interv(x).flg_status_rel,
                                                     rows_out                    => l_rows);
                        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'ICNP_EPIS_DG_INT_HIST',
                                                      i_rowids     => l_rows,
                                                      o_error      => l_error);
                    END LOOP;
                
                    --Therapeutic attitude
                ELSIF l_table(3) = pk_icnp_constant.g_therapeutic_attitude
                THEN
                    SELECT isi.id_icnp_sug_interv
                      INTO l_id_icnp_sug_interv
                      FROM icnp_suggest_interv isi
                     WHERE isi.id_icnp_epis_interv = l_table(1)
                       AND isi.id_req = l_table(2)
                       AND isi.flg_status_rel IN
                           (pk_icnp_constant.g_interv_rel_active, pk_icnp_constant.g_interv_rel_reactivated);
                
                    ts_icnp_suggest_interv.upd(id_icnp_sug_interv_in  => l_id_icnp_sug_interv,
                                               flg_status_rel_in      => l_varchar,
                                               id_prof_last_update_in => i_prof.id,
                                               dt_last_update_in      => current_timestamp,
                                               rows_out               => l_rows);
                    t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'ICNP_SUGGEST_INTERV',
                                                  i_rowids     => l_rows,
                                                  o_error      => l_error);
                
                    SELECT isi.*
                      BULK COLLECT
                      INTO l_icnp_suggest_interv
                      FROM icnp_suggest_interv isi
                     WHERE isi.id_icnp_sug_interv = l_id_icnp_sug_interv;
                    --esta mal se for sug não deve inserir nesta tabela mas sim na de sugs
                    FOR x IN 1 .. l_icnp_suggest_interv.count
                    LOOP
                    
                        ts_icnp_suggest_interv_hist.ins(id_icnp_sug_interv_hist_in => ts_icnp_suggest_interv_hist.next_key,
                                                        id_icnp_sug_interv_in      => l_id_icnp_sug_interv,
                                                        id_req_in                  => l_icnp_suggest_interv(x).id_req,
                                                        id_task_in                 => l_icnp_suggest_interv(x).id_task,
                                                        id_task_type_in            => l_icnp_suggest_interv(x).id_task_type,
                                                        id_composition_in          => l_icnp_suggest_interv(x).id_composition,
                                                        id_patient_in              => l_icnp_suggest_interv(x).id_patient,
                                                        id_episode_in              => l_icnp_suggest_interv(x).id_episode,
                                                        flg_status_in              => l_icnp_suggest_interv(x).flg_status,
                                                        id_prof_last_update_in     => i_prof.id,
                                                        dt_last_update_in          => current_timestamp,
                                                        id_icnp_epis_interv_in     => l_icnp_suggest_interv(x).id_icnp_epis_interv,
                                                        flg_status_rel_in          => l_varchar,
                                                        rows_out                   => l_rows);
                        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'ICNP_SUGGEST_INTERV_HIST',
                                                      i_rowids     => l_rows,
                                                      o_error      => l_error);
                    END LOOP;
                END IF;
            END LOOP;
        END IF;
    END set_status_rel_icnp;

    /********************************************************************************************
    * Gets the associated diagnosis of a list of interventions
    *
    * @param      i_lang               Preferred language ID for this professional
    * @param      i_epis_interv        Intervention id
    * @param      i_status_rel         array with status info
    * @param      i_id_icnp_epis_diag_interv     icnp_epis_diag_interv id    
    *
    * @return               varchar2 with associated diagnosis
    *
    * @raises
    *
    * @author                Nuno Neves
    * @version               
    * @since                 2012/03/12
    *********************************************************************************************/
    FUNCTION get_interv_rel_by_status
    (
        i_lang                     IN language.id_language%TYPE,
        i_epis_interv              IN icnp_epis_intervention.id_icnp_epis_interv%TYPE,
        i_status_rel               IN table_varchar,
        i_id_icnp_epis_diag_interv IN icnp_epis_diag_interv.id_icnp_epis_diag_interv%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_diag VARCHAR2(32767);
    BEGIN
        --obter a descrição
        SELECT substr(concatenate(desc_diag), 1, length(concatenate(desc_diag)) - length(pk_icnp_constant.g_word_sep)) ||
               decode(concatenate(desc_diag), NULL, NULL, pk_icnp_constant.g_word_end)
          INTO l_diag
          FROM (SELECT DISTINCT pk_translation.get_translation(i_lang, ic2.code_icnp_composition) ||
                                pk_icnp_constant.g_word_sep desc_diag
                  FROM icnp_epis_diagnosis ied
                  JOIN icnp_epis_diag_interv iedi
                    ON iedi.id_icnp_epis_diag = ied.id_icnp_epis_diag
                  JOIN icnp_epis_intervention iei
                    ON iei.id_icnp_epis_interv = iedi.id_icnp_epis_interv
                  JOIN icnp_composition ic2
                    ON ic2.id_composition = ied.id_composition
                 WHERE iei.id_icnp_epis_interv = i_epis_interv
                   AND iedi.id_icnp_epis_diag_interv = nvl(i_id_icnp_epis_diag_interv, iedi.id_icnp_epis_diag_interv)
                   AND iedi.flg_status_rel IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                column_value
                                                 FROM TABLE(i_status_rel) t)
                 ORDER BY desc_diag);
    
        RETURN l_diag;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_interv_rel_by_status;

    /********************************************************************************************
    * Returns the list of interventions descriptions (optionally intructions) associated to a diagnosis
    *
    * @param      i_lang                    Preferred language ID for this professional
    * @param      i_prof                    Object (professional ID, institution ID, software ID)
    * @param      i_icnp_epis_diag          Diagnosis ID
    * @param      i_show_instr              Show intervention instructions (Y - yes, N - No)
    * @param      i_sep                     Word separator character
    * @param      i_end                     Word end character
    * @param      i_dt_limit                Maximum date of the intervention (Used to get differences)
    *
    * @return             String with interventions description (optionally intructions)
    *
    * @author                Nuno Neves
    * @version               
    * @since                 2012/03/12
    *********************************************************************************************/
    FUNCTION get_diag_intervs_rel_desc
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_icnp_epis_diag IN icnp_epis_diagnosis.id_icnp_epis_diag%TYPE,
        i_show_instr     IN VARCHAR2,
        i_sep            IN VARCHAR2,
        i_end            IN VARCHAR2,
        i_dt_limit       IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_moment_assoc   IN table_varchar
    ) RETURN VARCHAR2 IS
        l_result VARCHAR2(4000 CHAR);
    BEGIN
        SELECT substr(concatenate(desc_interv),
                      1,
                      length(concatenate(desc_interv)) - length(nvl(i_sep, pk_icnp_constant.g_word_sep))) ||
               decode(concatenate(desc_interv), NULL, NULL, nvl(i_end, pk_icnp_constant.g_word_end))
          INTO l_result
          FROM (SELECT DISTINCT pk_translation.get_translation(i_lang, ic.code_icnp_composition) ||
                                decode(i_show_instr,
                                       pk_alert_constant.g_yes,
                                       pk_icnp_constant.g_word_space || pk_icnp_constant.g_word_open_brac ||
                                       get_interv_instructions(i_lang, i_prof, iei.id_icnp_epis_interv) ||
                                       
                                       pk_icnp_constant.g_word_close_brac || nvl(i_sep, pk_icnp_constant.g_word_sep),
                                       nvl(i_sep, pk_icnp_constant.g_word_sep)) desc_interv
                  FROM icnp_epis_diagnosis ied
                  JOIN icnp_epis_dg_int_hist iedih
                    ON ied.id_icnp_epis_diag = iedih.id_icnp_epis_diag
                  JOIN icnp_epis_intervention iei
                    ON iedih.id_icnp_epis_interv = iei.id_icnp_epis_interv
                  JOIN icnp_composition ic
                    ON iei.id_composition = ic.id_composition
                 WHERE ied.id_icnp_epis_diag = i_icnp_epis_diag
                   AND iei.id_episode_destination IS NULL
                   AND iedih.flg_status = pk_icnp_constant.g_interv_flg_status_a
                   AND iedih.flg_iud = pk_icnp_constant.g_iedih_flg_uid_i
                   AND iedih.flg_moment_assoc IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                   column_value
                                                    FROM TABLE(i_moment_assoc) t) --ASSOC
                      ---AND iedih.flg_status_rel = pk_icnp_constant.g_interv_rel_active
                   AND iedih.dt_hist = nvl(i_dt_limit, iedih.dt_hist));
    
        RETURN l_result;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_diag_intervs_rel_desc;

    FUNCTION reeval_diagnosis
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_diag_ids       IN table_number,
        i_composition_id IN icnp_epis_diagnosis.id_composition%TYPE,
        i_interv_check   IN table_number,
        i_new_diag       IN table_number, ---- new id_diag
        i_new_interv     IN table_number,
        i_new_interv_ovr IN table_number,
        i_flg_sug        IN VARCHAR2,
        i_exp_res        IN table_number,
        i_notes          IN table_varchar,
        i_interv         IN table_table_varchar,
        o_interv_id      OUT table_number,
        o_warn           OUT table_varchar,
        o_desc_instr     OUT pk_types.cursor_type,
        o_error          OUT t_error_out
        
    ) RETURN BOOLEAN IS
        l_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
        l_exception EXCEPTION;
        c_func_name VARCHAR2(30 CHAR) := 'REEVAL_DIAGNOSIS';
    
        l_interv_status       icnp_epis_intervention.flg_status%TYPE;
        l_new_interv_filtered table_number;
        l_unmatch_interv      table_number;
    
        l_count_interv_assoc NUMBER;
    
    BEGIN
    
        l_sysdate_tstz := current_timestamp;
    
        BEGIN
            SELECT t.column_value
              BULK COLLECT
              INTO l_new_interv_filtered
              FROM TABLE(i_new_interv) t
             WHERE t.column_value NOT IN
                   (SELECT a.id_composition
                      FROM icnp_epis_intervention a
                     WHERE a.id_icnp_epis_interv IN (SELECT t.column_value
                                                       FROM TABLE(i_interv_check) t));
        EXCEPTION
            WHEN no_data_found THEN
                l_new_interv_filtered := i_new_interv;
        END;
    
        pk_icnp_fo.check_epis_conflict(i_lang       => i_lang,
                                       i_prof       => i_prof,
                                       i_patient    => i_patient,
                                       i_episode    => i_episode,
                                       i_diag       => i_new_diag,
                                       i_interv     => l_new_interv_filtered,
                                       i_flg_sug    => i_flg_sug,
                                       o_warn       => o_warn,
                                       o_desc_instr => o_desc_instr);
    
        IF o_warn IS NULL
        THEN
            pk_icnp_fo_api_db.set_diags_status_reeval(i_lang           => i_lang,
                                                      i_prof           => i_prof,
                                                      i_episode        => i_episode,
                                                      i_patient        => i_patient,
                                                      i_diag_ids       => i_diag_ids,
                                                      i_composition_id => i_composition_id,
                                                      i_sysdate_tstz   => l_sysdate_tstz,
                                                      i_notes          => i_notes);
        
            SELECT iic.column_value
              BULK COLLECT
              INTO l_unmatch_interv
              FROM (SELECT column_value
                      FROM TABLE(i_interv_check)) iic
              LEFT JOIN (SELECT column_value
                           FROM TABLE(i_new_interv_ovr)) inio
                ON iic.column_value = inio.column_value
             WHERE inio.column_value IS NULL;
        
            FOR i IN 1 .. l_unmatch_interv.count
            LOOP
            
                SELECT COUNT(*)
                  INTO l_count_interv_assoc
                  FROM icnp_epis_diag_interv iedi
                 WHERE iedi.id_icnp_epis_interv = l_unmatch_interv(i)
                   AND iedi.flg_status_rel IN
                       (pk_icnp_constant.g_interv_rel_active, pk_icnp_constant.g_interv_rel_reactivated);
            
                IF l_count_interv_assoc = 1
                THEN
                
                    SELECT iei.flg_status
                      INTO l_interv_status
                      FROM icnp_epis_intervention iei
                     WHERE iei.id_icnp_epis_interv = l_unmatch_interv(i);
                
                    IF l_interv_status NOT IN (pk_icnp_constant.g_epis_interv_status_cancelled,
                                               pk_icnp_constant.g_epis_interv_status_suspended)
                    THEN
                    
                        pk_icnp_fo_api_db.set_intervs_status_finish(i_lang         => i_lang,
                                                                    i_prof         => i_prof,
                                                                    i_episode      => i_episode,
                                                                    i_patient      => i_patient,
                                                                    i_interv_ids   => l_unmatch_interv,
                                                                    i_sysdate_tstz => l_sysdate_tstz);
                    
                    END IF;
                END IF;
                --ts_interv_icnp_ea.del(id_icnp_epis_interv_in => l_unmatch_interv(i));
            
            END LOOP;
        
            pk_icnp_fo_api_db.set_assoc_interv(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_episode      => i_episode,
                                               i_patient      => i_patient,
                                               i_diag         => i_diag_ids(1),
                                               i_interv       => i_interv,
                                               i_sysdate_tstz => l_sysdate_tstz,
                                               o_interv_id    => o_interv_id);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
        
    END reeval_diagnosis;

    FUNCTION get_interv_pred_by_diag
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_diag IN icnp_epis_diagnosis.id_icnp_epis_diag%TYPE
    ) RETURN table_varchar IS
    
        l_interv table_varchar := table_varchar();
    BEGIN
        -- SELECT l_interv
        SELECT pk_translation.get_translation(i_lang, ic.code_icnp_composition)
          BULK COLLECT
          INTO l_interv
          FROM icnp_predefined_action ipc
         INNER JOIN icnp_composition ic
            ON ipc.id_composition = ic.id_composition
         INNER JOIN icnp_composition_hist ich
            ON ich.id_composition = ic.id_composition
         INNER JOIN icnp_predefined_action_hist ipah
            ON ipah.id_predefined_action = ipc.id_predefined_action
         WHERE ipc.id_composition_parent = i_diag
           AND ipc.flg_available = pk_alert_constant.g_yes
           AND ic.flg_available = pk_alert_constant.g_yes
           AND ic.flg_type = pk_icnp_constant.g_composition_type_action
           AND ich.flg_most_recent = pk_alert_constant.g_yes
           AND ich.flg_cancel = pk_alert_constant.g_no
           AND ipah.flg_cancel = pk_alert_constant.g_no
           AND ipah.flg_most_recent = pk_alert_constant.g_yes;
    
        RETURN l_interv;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
        
    END get_interv_pred_by_diag;

    PROCEDURE get_icnp_actions_sp
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        id_icnp_epis_interv_diag IN NUMBER,
        o_actions                OUT pk_types.cursor_type
    ) IS
        l_actions         t_coll_action_cipe;
        l_interv_flg_time icnp_epis_intervention.flg_time%TYPE;
        l_flg_status      icnp_epis_intervention.flg_status%TYPE;
    
        CURSOR c_icnp_epis_interv IS
            SELECT iei.flg_time, flg_status
              FROM icnp_epis_intervention iei
             WHERE iei.id_icnp_epis_interv = id_icnp_epis_interv_diag;
    
    BEGIN
        OPEN c_icnp_epis_interv;
        FETCH c_icnp_epis_interv
            INTO l_interv_flg_time, l_flg_status;
        CLOSE c_icnp_epis_interv;
    
        -- no need to verify if l_interv_flg_time is NULL
        l_actions := get_actions_perm_int(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_subject    => 'ICNP_INTERV',
                                          i_from_state => table_varchar(l_flg_status),
                                          i_flg_time   => l_interv_flg_time);
    
        OPEN o_actions FOR
            SELECT a.id_action,
                   a.id_parent,
                   a.action_level  "LEVEL",
                   NULL            from_state,
                   a.to_state,
                   a.desc_action,
                   a.icon,
                   a.flg_default,
                   a.flg_active,
                   a.internal_name action
              FROM TABLE(l_actions) a
             WHERE a.internal_name NOT IN ('INTERV_ADD_DIAG', 'INTERV_CANCEL');
    
    END get_icnp_actions_sp;

    FUNCTION get_icnp_interv_info
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_icnp_epis_interv IN icnp_epis_intervention.id_icnp_epis_interv%TYPE,
        o_interv              OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        -- open interventions cursor
        OPEN o_interv FOR
            SELECT /*+opt_estimate(table iea rows=1)*/
             iea.id_icnp_epis_interv,
             NULL id_icnp_epis_interv_group,
             get_interv_assoc_diag(iea.id_icnp_epis_interv) assoc_diag,
             iea.id_composition_diag id_diagnosis,
             pk_icnp.desc_composition(i_lang, iea.id_composition_diag) desc_diagnosis,
             iea.id_composition_interv id_interv,
             pk_icnp.desc_composition(i_lang, iea.id_composition_interv) desc_interv,
             iea.flg_time,
             iea.flg_status,
             g_execution_shortcut ||
             pk_utils.get_status_string(i_lang, i_prof, iea.status_str, iea.status_msg, iea.status_icon, iea.flg_status) status_str,
             get_interv_instructions(i_lang, i_prof, iea.id_icnp_epis_interv) desc_instr,
             decode(nvl(substr(iea.id_vs, 1, 1), iaa.area),
                    'VS',
                    'V',
                    'BIO',
                    'B',
                    nvl(substr(iea.id_vs, 1, 1), iaa.area)) flg_type_vs,
             nvl(substr(iea.id_vs, 3, 7),
                 decode(substr(iaa.parameter_desc, 1, 27),
                        'VITAL_SIGN.CODE_VITAL_SIGN.',
                        to_number(substr(iaa.parameter_desc, 28, length(iaa.parameter_desc))),
                        NULL)) id_vs,
             check_permissions(i_lang,
                               i_prof,
                               pk_icnp_constant.g_action_subject_interv,
                               iei.flg_status,
                               pk_icnp_constant.g_action_interv_cancel) flg_cancel,
             ic.id_doc_template,
             pk_date_utils.date_send_tsz(i_lang, iei.dt_begin_tstz, i_prof) dt_begin_tstz,
             decode((SELECT COUNT(*)
                      FROM icnp_epis_intervention i
                     WHERE i.id_icnp_epis_interv_parent = iei.id_icnp_epis_interv),
                    0,
                    pk_alert_constant.g_yes,
                    pk_alert_constant.g_no) flg_next_epis_active,
             --decode(iea.notes, NULL, NULL, l_has_notes) notes,
             -- decode(iea.notes, NULL, NULL, iei.notes) notes_tooltip,
             pk_icnp.get_icnp_tooltip(i_lang     => i_lang,
                                      i_prof     => i_prof,
                                      i_id_task  => iei.id_icnp_epis_interv,
                                      i_flg_type => '2',
                                      i_screen   => 1) tooltip
              FROM icnp_epis_intervention iei
              JOIN interv_icnp_ea iea
                ON iei.id_icnp_epis_interv = iea.id_icnp_epis_interv
              JOIN icnp_composition ic
                ON ic.id_composition = iei.id_composition
              LEFT JOIN icnp_application_area iaa
                ON iaa.id_application_area = ic.id_application_area
             WHERE iei.id_icnp_epis_interv = i_id_icnp_epis_interv;
        RETURN TRUE;
    END get_icnp_interv_info;
BEGIN
    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);

END pk_icnp_fo;
/
