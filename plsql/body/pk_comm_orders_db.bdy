/*-- Last Change Revision: $Rev: 2005972 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2022-01-20 16:59:36 +0000 (qui, 20 jan 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_comm_orders_db IS

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- debug mode enabled/disabled
    g_debug  BOOLEAN;
    g_retval BOOLEAN;

    g_exception_np EXCEPTION;
    g_exception    EXCEPTION;

    /**
    * Gets communication order requests description, used for the task timeline easy access
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)    
    * @param   i_id_comm_order_req          Communication order request identifier
    *
    * @return  clob                         Communication order request description
    *
    * @author  ana.monteiro
    * @since   06-03-2014
    */
    FUNCTION get_comm_order_req_desc
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_comm_order_req     IN comm_order_req.id_comm_order_req%TYPE,
        i_description_condition IN pn_dblock_ttp_mkt.description_condition%TYPE DEFAULT NULL,
        i_flg_desc_for_dblock   IN pk_types.t_flg_char DEFAULT NULL
    ) RETURN CLOB IS
    BEGIN
        RETURN pk_comm_orders.get_comm_order_req_desc(i_lang                  => i_lang,
                                                      i_prof                  => i_prof,
                                                      i_id_comm_order_req     => i_id_comm_order_req,
                                                      i_description_condition => i_description_condition,
                                                      i_flg_desc_for_dblock   => i_flg_desc_for_dblock);
    END get_comm_order_req_desc;

    /**
    * Gets communication order requests description.
    * Used by co-sign module
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)    
    * @param   i_id_task                    Co-sign task identifier
    * @param   i_id_co_sign_hist            Co-sign history identifier
    *
    * @return  clob                         Communication order request title
    *
    * @author  ana.monteiro
    * @since   30-03-2015
    */
    FUNCTION get_cs_comm_order_req_title
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_task         IN co_sign.id_task%TYPE,
        i_id_co_sign_hist IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN CLOB IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'get_cs_comm_order_req_title';
        l_comm_order_req_title CLOB;
        l_error                t_error_out;
    BEGIN
        g_error := 'Init ' || l_func_name || ' / i_id_task=' || i_id_task || ' i_id_co_sign_hist=' || i_id_co_sign_hist;
        SELECT pk_comm_orders.get_comm_order_title(i_lang                     => i_lang,
                                                   i_prof                     => i_prof,
                                                   i_concept_type             => corh.id_concept_type,
                                                   i_concept_term             => corh.id_concept_term,
                                                   i_cncpt_trm_inst_owner     => corh.id_cncpt_trm_inst_owner,
                                                   i_concept_version          => corh.id_concept_version,
                                                   i_cncpt_vrs_inst_owner     => corh.id_cncpt_vrs_inst_owner,
                                                   i_flg_free_text            => corh.flg_free_text,
                                                   i_desc_concept_term        => corh.desc_concept_term,
                                                   i_task_type                => corh.id_task_type,
                                                   i_flg_bold_title           => pk_alert_constant.g_no,
                                                   i_flg_show_comm_order_type => pk_alert_constant.g_yes,
                                                   i_flg_trunc_clobs          => pk_alert_constant.g_yes,
                                                   i_flg_escape_char          => pk_alert_constant.g_yes)
          INTO l_comm_order_req_title
          FROM comm_order_req_hist corh
         WHERE corh.id_comm_order_req_hist = i_id_task;
    
        RETURN l_comm_order_req_title;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => l_error);
            RETURN empty_clob();
    END get_cs_comm_order_req_title;

    /**
    * Gets communication order requests instructions.
    * Used by co-sign module
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)    
    * @param   i_id_task                    Co-sign task identifier
    * @param   i_id_co_sign_hist            Co-sign history identifier
    *
    * @return  clob                         Communication order request instructions
    *
    * @author  ana.monteiro
    * @since   30-03-2015
    */
    FUNCTION get_cs_comm_order_req_instr
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_task         IN co_sign.id_task%TYPE,
        i_id_co_sign_hist IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN CLOB IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'get_cs_comm_order_req_instr';
        l_comm_order_req_instr CLOB;
        l_error                t_error_out;
    BEGIN
        g_error := 'Init ' || l_func_name || ' / i_id_task=' || i_id_task || ' i_id_co_sign_hist=' || i_id_co_sign_hist;
        SELECT pk_comm_orders.get_comm_order_instr(i_lang            => i_lang,
                                                   i_prof            => i_prof,
                                                   i_flg_priority    => corh.flg_priority,
                                                   i_flg_prn         => corh.flg_prn,
                                                   i_prn_condition   => corh.prn_condition,
                                                   i_dt_begin        => corh.dt_begin,
                                                   i_flg_trunc_clobs => pk_alert_constant.g_yes,
                                                   i_flg_escape_char => pk_alert_constant.g_yes)
          INTO l_comm_order_req_instr
          FROM comm_order_req_hist corh
         WHERE corh.id_comm_order_req_hist = i_id_task;
    
        RETURN l_comm_order_req_instr;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => l_error);
            RETURN empty_clob();
    END get_cs_comm_order_req_instr;

    /**
    * Gets co-sign action description
    * Used by co-sign module
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)    
    * @param   i_id_task                    Co-sign task identifier
    * @param   i_id_action                  Co-sign action identifier
    * @param   i_id_co_sign_hist            Co-sign history identifier
    *
    * @return  VARCHAR2                     Co-sign action description
    *
    * @author  ana.monteiro
    * @since   30-03-2015
    */
    FUNCTION get_cs_action_desc
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_task         IN co_sign.id_task%TYPE,
        i_id_action       IN co_sign.id_action%TYPE,
        i_id_co_sign_hist IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'get_cs_action_desc';
        l_action_desc VARCHAR2(1000 CHAR);
        l_error       t_error_out;
    BEGIN
        g_error := 'Init ' || l_func_name || ' / i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof) ||
                   ' i_id_task=' || i_id_task || ' i_id_action=' || i_id_action || ' i_id_co_sign_hist=' ||
                   i_id_co_sign_hist;
    
        -- get flg_action related to this record and get co-sign action description
        SELECT pk_comm_orders.get_cs_action_desc(i_lang => i_lang, i_prof => i_prof, i_flg_action => corh.flg_action)
          INTO l_action_desc
          FROM comm_order_req_hist corh
         WHERE corh.id_comm_order_req_hist = i_id_task;
    
        RETURN l_action_desc;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => l_error);
            RETURN NULL;
    END get_cs_action_desc;

    FUNCTION get_cs_date_to_order
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_task      IN co_sign.id_task%TYPE,
        i_co_sign_hist IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
    
        l_date TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
    
        IF i_id_task IS NULL
        THEN
            RETURN NULL;
        END IF;
    
        SELECT nvl(corh.dt_begin, corh.dt_req)
          INTO l_date
          FROM comm_order_req_hist corh
         WHERE corh.id_comm_order_req_hist = i_id_task;
    
        RETURN l_date;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_cs_date_to_order;

    /**
    * Informs communication orders module that a visit changed its status
    *
    * @param   i_lang                Professional preferred language
    * @param   i_prof                Professional identification and its context (institution and software)
    * @param   i_event_type          Type of event (UPDATE, INSERT, etc)
    * @param   i_rowids              List of ROWIDs belonging to the changed records.
    * @param   i_list_columns        List of columns that were changed
    * @param   i_source_table_name   Name of the table that was changed.
    * @param   i_dg_table_name       Name of the Data Governance table.
    *
    * @author  tiago.silva
    * @version 1.0
    * @since   07-03-2014
    */
    PROCEDURE set_visit_status_trigger
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'set_visit_status_trigger';
    BEGIN
        g_error := 'Init ' || l_func_name || ' / i_prof=' || pk_utils.to_string(i_prof) || ' i_event_type=' ||
                   i_event_type;
        IF g_debug
        THEN
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        pk_comm_orders.set_visit_status_trigger(i_lang              => i_lang,
                                                i_prof              => i_prof,
                                                i_event_type        => i_event_type,
                                                i_rowids            => i_rowids,
                                                i_source_table_name => i_source_table_name,
                                                i_list_columns      => i_list_columns,
                                                i_dg_table_name     => i_dg_table_name);
    END set_visit_status_trigger;

    /**
    * Informs communication orders module that an episode changed its status
    *
    * @param   i_lang                Professional preferred language
    * @param   i_prof                Professional identification and its context (institution and software)
    * @param   i_event_type          Type of event (UPDATE, INSERT, etc)
    * @param   i_rowids              List of ROWIDs belonging to the changed records.
    * @param   i_list_columns        List of columns that were changed
    * @param   i_source_table_name   Name of the table that was changed.
    * @param   i_dg_table_name       Name of the Data Governance table.
    *
    * @author  tiago.silva
    * @version 1.0
    * @since   07-03-2014
    */
    PROCEDURE set_episode_status_trigger
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'set_episode_status_trigger';
    BEGIN
        g_error := 'Init ' || l_func_name || ' / i_prof=' || pk_utils.to_string(i_prof) || ' i_event_type=' ||
                   i_event_type;
        IF g_debug
        THEN
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        pk_comm_orders.set_episode_status_trigger(i_lang              => i_lang,
                                                  i_prof              => i_prof,
                                                  i_event_type        => i_event_type,
                                                  i_rowids            => i_rowids,
                                                  i_source_table_name => i_source_table_name,
                                                  i_list_columns      => i_list_columns,
                                                  i_dg_table_name     => i_dg_table_name);
    END set_episode_status_trigger;

    /**
    * This function deletes all data related to a communication order request episode
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_patients                Array of patient identifiers
    * @param   i_id_episodes                Array of episode identifiers
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   21-03-2014
    */
    FUNCTION reset_comm_order_req
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_patients IN table_number,
        i_id_episodes IN table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'reset_comm_order_req';
    BEGIN
        g_error := 'Init ' || l_func_name || ' / i_prof=' || pk_utils.to_string(i_prof) || ' i_id_episodes.count=' ||
                   i_id_episodes.count || ' i_id_patients.count=' || i_id_patients.count;
        IF g_debug
        THEN
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        g_retval := pk_comm_orders.reset_comm_order_req(i_lang        => i_lang,
                                                        i_prof        => i_prof,
                                                        i_id_patients => i_id_patients,
                                                        i_id_episodes => i_id_episodes,
                                                        o_error       => o_error);
    
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
    END reset_comm_order_req;

    /**
    * Returns communication orders list for the viewer
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_patient                    Patient identifier
    * @param   i_viewer_area                Viewer area
    * @param   i_episode                    Episode identifier
    * @param   o_list                       Cursor containing communication orders list
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @since   02-12-2014
    */
    FUNCTION get_comm_order_viewer_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_viewer_area IN VARCHAR2,
        i_episode     IN episode.id_episode%TYPE,
        o_list        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'get_comm_order_viewer_list';
    BEGIN
        g_error := 'Init ' || l_func_name || ' / i_prof=' || pk_utils.to_string(i_prof) || ' i_patient=' || i_patient ||
                   ' i_viewer_area=' || i_viewer_area || ' i_episode=' || i_episode;
        IF g_debug
        THEN
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        g_retval := pk_comm_orders.get_comm_order_viewer_list(i_lang        => i_lang,
                                                              i_prof        => i_prof,
                                                              i_patient     => i_patient,
                                                              i_viewer_area => i_viewer_area,
                                                              i_episode     => i_episode,
                                                              o_list        => o_list,
                                                              o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_list);
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
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_comm_order_viewer_list;

    /**
    * Returns communication orders for a given episode
    * Used by grid summary screen
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_episode                    Episode identifier
    * @param   i_filter_tstz                Date to filter only the records with "end dates" > i_filter_tstz
    * @param   i_filter_status              Array with task status to consider along with i_filter_tstz
    * @param   o_comm_orders                Cursor containing the communication order requests of this episode
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @since   03-12-2014
    */
    FUNCTION get_comm_order_summ_grid
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_filter_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_filter_status IN table_number,
        o_comm_orders   OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'get_comm_order_summ_grid';
    BEGIN
        g_error := 'Init ' || l_func_name || ' / i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof) ||
                   ' i_episode=' || i_episode || ' i_filter_status=' || pk_utils.to_string(i_filter_status) ||
                   ' i_filter_tstz=' ||
                   pk_date_utils.to_char_insttimezone(i_prof,
                                                      i_filter_tstz,
                                                      pk_alert_constant.g_dt_yyyymmddhh24miss_tzh);
        IF g_debug
        THEN
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        g_retval := pk_comm_orders.get_comm_order_summ_grid(i_lang          => i_lang,
                                                            i_prof          => i_prof,
                                                            i_episode       => i_episode,
                                                            i_filter_tstz   => i_filter_tstz,
                                                            i_filter_status => i_filter_status,
                                                            o_comm_orders   => o_comm_orders,
                                                            o_error         => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_comm_orders);
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
            pk_types.open_my_cursor(o_comm_orders);
            RETURN FALSE;
    END get_comm_order_summ_grid;

    FUNCTION inactivate_comm_order_tasks
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_inst      IN institution.id_institution%TYPE,
        o_has_error OUT BOOLEAN,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_tbl_ids table_number := table_number();
    
    BEGIN
    
        IF NOT pk_comm_orders.inactivate_comm_order_tasks(i_lang        => i_lang,
                                                          i_prof        => i_prof,
                                                          i_inst        => i_inst,
                                                          i_ids_exclude => l_tbl_ids,
                                                          o_has_error   => o_has_error,
                                                          o_error       => o_error)
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'INACTIVATE_COMM_ORDER_TASKS',
                                              o_error    => o_error);
            RETURN FALSE;
    END inactivate_comm_order_tasks;

BEGIN
    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_comm_orders_db;
/
