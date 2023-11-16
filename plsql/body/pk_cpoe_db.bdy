/*-- Last Change Revision: $Rev: 2026915 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:25 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_cpoe_db IS

    -- Purpose : Computerized Prescription Order Entry (CPOE) DB API database package

    -- logging variables
    g_package_owner VARCHAR2(30);
    g_package_name  VARCHAR2(30);
    g_error         VARCHAR2(4000);
		
		
		/********************************************************************************************
    * get table_timestamp_tstz array from table_varchar arrays with dates
    *
    * @param    i_lang                     preferred language id for this professional
    * @param    i_prof                     professional id structure
    * @param    i_tbl                      varchar table
    *
    * @return   table_timestamp_tstz       timestamp table collection
    *
    * @author   Carlos Loureiro
    * @since    18-NOV-2011
    ********************************************************************************************/
    FUNCTION get_table_varchar
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_tbl  IN table_timestamp_tstz
    ) RETURN table_varchar IS
        l_ret table_varchar := table_varchar();
    BEGIN
        FOR i IN 1 .. i_tbl.count
        LOOP
            l_ret.extend;
            l_ret(l_ret.count) := pk_date_utils.get_timestamp_str(i_lang, i_prof, i_tbl(i), NULL);
        END LOOP;
        RETURN l_ret;
    END get_table_varchar;
		

    /********************************************************************************************
    * checks within cpoe if the given tasks can be created or not (in tasks requests)
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id
    * @param       i_task_type               cpoe task type id
    * @param       i_dt_start                tasks start timestamps
    * @param       i_dt_end                  tasks end timestamps
    * @param       i_task_id                 task ids (can be used with drafts also)
    * @param       o_task_list               list of tasks, according to cpoe confirmation grid
    * @param       o_flg_warning_type        warning type flag
    * @param       o_msg_title               message title
    * @param       o_msg_body                message body, according to warning type flag
    * @param       o_proc_start              cpoe process start timestamp (for new cpoe process)
    * @param       o_proc_end                cpoe process end timestamp (for new cpoe process)
    * @param       o_proc_refresh            cpoe refresh to draft prescription timestamp (for new cpoe process)
    * @param       o_error                   error message
    *
    * @value       o_flg_warning_type        {*} 'O' timestamps out of bounds
    *                                        {*} 'C' confirm cpoe creation
    *                                        {*} NULL proceed task creation, without warnings
    *
    * @return      boolean                   true on success, otherwise false
    *
    * @author                                Carlos Loureiro
    * @since                                 17-NOV-2011
    ********************************************************************************************/

    FUNCTION check_tasks_creation
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_task_type         IN table_number,
        i_dt_start          IN table_timestamp_tstz,
        i_dt_end            IN table_timestamp_tstz,
        i_task_id           IN table_varchar,
        i_tab_type          IN VARCHAR2 DEFAULT NULL,
        o_task_list         OUT pk_types.cursor_type,
        o_flg_warning_type  OUT VARCHAR2,
        o_msg_title         OUT VARCHAR2,
        o_msg_body          OUT VARCHAR2,
        o_proc_start        OUT cpoe_process.dt_cpoe_proc_start%TYPE,
        o_proc_end          OUT cpoe_process.dt_cpoe_proc_end%TYPE,
        o_proc_refresh      OUT cpoe_process.dt_cpoe_proc_auto_refresh%TYPE,
        o_proc_next_start   OUT cpoe_process.dt_cpoe_proc_start%TYPE,
        o_proc_next_end     OUT cpoe_process.dt_cpoe_proc_end%TYPE,
        o_proc_next_refresh OUT cpoe_process.dt_cpoe_proc_auto_refresh%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
				
				
				l_ts_cpoe_start   VARCHAR2(20 CHAR);
        l_ts_cpoe_end     VARCHAR2(20 CHAR);
        l_ts_cpoe_refresh VARCHAR2(20 CHAR);
				l_proc_next_start   VARCHAR2(20 CHAR);
        l_proc_next_end     VARCHAR2(20 CHAR);
        l_proc_next_refresh VARCHAR2(20 CHAR);
				
    BEGIN
        -- call pk_cpoe.check_tasks_creation function
        IF NOT pk_cpoe.check_tasks_creation(i_lang              => i_lang,
                                            i_prof              => i_prof,
                                            i_episode           => i_episode,
                                            i_task_type         => i_task_type,
                                            i_dt_start          => get_table_varchar(i_lang => i_lang,
                                                                                           i_prof => i_prof,
                                                                                           i_tbl  => i_dt_start),
                                            i_dt_end            => get_table_varchar(i_lang => i_lang,
                                                                                           i_prof => i_prof,
                                                                                           i_tbl  => i_dt_end),
                                            i_task_id           => i_task_id,
                                            i_tab_type          => i_tab_type,
                                            o_task_list         => o_task_list,
                                            o_flg_warning_type  => o_flg_warning_type,
                                            o_msg_title         => o_msg_title,
                                            o_msg_body          => o_msg_body,
                                            o_proc_start        => l_ts_cpoe_start,
                                            o_proc_end          => l_ts_cpoe_end,
                                            o_proc_refresh      => l_ts_cpoe_refresh,
                                            o_proc_next_start   => l_proc_next_start,
                                            o_proc_next_end     => l_proc_next_end,
                                            o_proc_next_refresh => l_proc_next_refresh,
                                            o_error             => o_error)
        THEN
            g_error := 'error found while calling pk_cpoe.check_tasks_creation function';
            RAISE l_exception;
        END IF;
				
				
				o_proc_start   := pk_date_utils.get_string_tstz(i_lang,i_prof, l_ts_cpoe_start,  NULL);
        o_proc_end     := pk_date_utils.get_string_tstz(i_lang, i_prof,l_ts_cpoe_end, NULL);
        o_proc_refresh := pk_date_utils.get_string_tstz(i_lang,i_prof, l_ts_cpoe_refresh, NULL);
				o_proc_next_start   := pk_date_utils.get_string_tstz(i_lang,i_prof, l_proc_next_start, NULL);
        o_proc_next_end     := pk_date_utils.get_string_tstz(i_lang, i_prof,l_proc_next_end, NULL);
        o_proc_next_refresh := pk_date_utils.get_string_tstz(i_lang,i_prof, l_proc_next_refresh, NULL);
				
				
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_TASKS_CREATION',
                                              o_error);
            pk_types.open_my_cursor(o_task_list);
            RETURN FALSE;
    END check_tasks_creation;

    /********************************************************************************************
    * synchronize requested task with cpoe processes in task creation or draft activation
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id
    * @param       i_task_type               cpoe task type id
    * @param       i_task_request            task request id (also used for draft activation)
    * @param       o_error                   error message
    *
    * @return      boolean                   true on success, otherwise false
    *
    * @author                                Carlos Loureiro
    * @since                                 2009/11/23
    ********************************************************************************************/
    FUNCTION sync_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_type    IN cpoe_task_type.id_task_type%TYPE,
        i_task_request IN cpoe_process_task.id_task_request%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
        -- call pk_cpoe.sync_task function
        IF NOT pk_cpoe.sync_task(i_lang             => i_lang,
                                 i_prof             => i_prof,
                                 i_episode          => i_episode,
                                 i_task_type        => i_task_type,
                                 i_old_task_request => NULL,
                                 i_new_task_request => i_task_request,
                                 o_error            => o_error)
        THEN
            g_error := 'error found while calling pk_cpoe.sync_task (i_old_task_request=>NULL) function';
            RAISE l_exception;
        END IF;
        -- no transaction control in this function (is done in the calling function)
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SYNC_TASK',
                                              o_error);
            RETURN FALSE;
    END sync_task;

    /********************************************************************************************
    * synchronize requested task with cpoe processes in task creation or draft activation
    * this overload is used for tasks that creates a new request for each statua transition
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id
    * @param       i_task_type               cpoe task type id
    * @param       i_old_task_request        old task request id (also used for draft activation)
    * @param       i_new_task_request        new task request id (also used for draft activation)
    * @param       o_error                   error message
    *
    * @return      boolean                   true on success, otherwise false
    *
    * @author                                Carlos Loureiro
    * @since                                 2009/12/09
    ********************************************************************************************/
    FUNCTION sync_task
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_task_type        IN cpoe_task_type.id_task_type%TYPE,
        i_old_task_request IN cpoe_process_task.id_task_request%TYPE,
        i_new_task_request IN cpoe_process_task.id_task_request%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
        -- call pk_cpoe.sync_task function
        IF NOT pk_cpoe.sync_task(i_lang             => i_lang,
                                 i_prof             => i_prof,
                                 i_episode          => i_episode,
                                 i_task_type        => i_task_type,
                                 i_old_task_request => i_old_task_request,
                                 i_new_task_request => i_new_task_request,
                                 o_error            => o_error)
        THEN
            g_error := 'error found while calling pk_cpoe.sync_task function';
            RAISE l_exception;
        END IF;
        -- no transaction control in this function (is done in the calling function)
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SYNC_TASK',
                                              o_error);
            RETURN FALSE;
    END sync_task;

    /********************************************************************************************
    * get cpoe end date timestamp for a given task type/request
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_task_type               cpoe task type id
    * @param       i_task_request            task request id
    * @param       o_end_date                cpoe end date timestamp
    * @param       o_error                   error message
    *
    * @return      boolean                   true on success, otherwise false
    *
    * @author                                Carlos Loureiro
    * @since                                 10-NOV-2011
    ********************************************************************************************/
    FUNCTION get_cpoe_end_date_by_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_type    IN cpoe_task_type.id_task_type%TYPE,
        i_task_request IN cpoe_process_task.id_task_request%TYPE,
        o_end_date     OUT cpoe_process.dt_cpoe_proc_end%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
        -- call pk_cpoe.get_cpoe_end_date_by_task function
        IF NOT pk_cpoe.get_cpoe_end_date_by_task(i_lang         => i_lang,
                                                 i_prof         => i_prof,
                                                 i_task_type    => i_task_type,
                                                 i_task_request => i_task_request,
                                                 o_end_date     => o_end_date,
                                                 o_error        => o_error)
        THEN
            g_error := 'error found while calling pk_cpoe.get_cpoe_end_date_by_task function';
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
                                              'GET_CPOE_END_DATE_BY_TASK',
                                              o_error);
            RETURN FALSE;
    END get_cpoe_end_date_by_task;

    /********************************************************************************************
    * get the closed task filter timestamp (with local tiome zone) used by CPOE
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id
    * @param       o_closed_task_filter_tstz closed task filter timestamp (with local tiome zone)
    *                                        note: if null, no cpoe was created or cpoe is not
    *                                              working in advanced mode
    * @param       o_error                   error message
    *
    * @return      boolean                   true on success, otherwise false
    *
    * @author                                Carlos Loureiro
    * @since                                 25-Jan-2011
    ********************************************************************************************/
    FUNCTION get_closed_task_filter_tstz
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_episode                 IN episode.id_episode%TYPE,
        o_closed_task_filter_tstz OUT TIMESTAMP WITH LOCAL TIME ZONE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
        -- call pk_cpoe.get_closed_task_filter_tstz function
        IF NOT pk_cpoe.get_closed_task_filter_tstz(i_lang                    => i_lang,
                                                   i_prof                    => i_prof,
                                                   i_episode                 => i_episode,
                                                   o_closed_task_filter_tstz => o_closed_task_filter_tstz,
                                                   o_error                   => o_error)
        THEN
            g_error := 'error found while calling pk_cpoe.get_closed_task_filter_tstz function';
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
                                              'GET_CLOSED_TASK_FILTER_TSTZ',
                                              o_error);
            RETURN FALSE;
    END get_closed_task_filter_tstz;

    /********************************************************************************************
    * clear particular cpoe processes or clear all cpoe processes related with a list of patients
    *
    * @param       i_lang              preferred language id for this professional
    * @param       i_prof              professional id structure
    * @param       i_patients          patients array
    * @param       i_cpoe_processes    cpoe processes array
    * @param       o_error             error message
    *
    * @return      boolean             true on success, otherwise false
    *
    * @author                          Tiago Silva
    * @since                           2010/11/02
    ********************************************************************************************/
    FUNCTION clear_cpoe_processes
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patients       IN table_number DEFAULT NULL,
        i_cpoe_processes IN table_number DEFAULT NULL,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
        -- call pk_cpoe.clear_cpoe_processes function
        IF NOT pk_cpoe.clear_cpoe_processes(i_lang           => i_lang,
                                            i_prof           => i_prof,
                                            i_patients       => i_patients,
                                            i_cpoe_processes => i_cpoe_processes,
                                            o_error          => o_error)
        THEN
            g_error := 'error found while calling pk_cpoe.clear_cpoe_processes function';
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
                                              'CLEAR_CPOE_PROCESSES',
                                              o_error);
            RETURN FALSE;
    END clear_cpoe_processes;

    /********************************************************************************************
    * insert/update (merge) a cpoe_task_type_status_filter record for CPOE task filter handling
    *
    * @param       i_task_type                   task type id
    * @param       i_flg_status                  task type original status flag
    * @param       i_status_internal_code        task type internal status code/description
    * @param       i_flg_filter_tab              cpoe grid filter for associated task status flag
    * @param       i_flg_proc_refresh            refresh flag for associated task type/flag status
    *                                            pair
    * @param       i_flg_proc_new                copy to new prescription flag for associated task
    *                                            type/flag status pair
    * @param       i_flg_proc_report             include/exclude task type/status in CPOE report
    *
    * @author                                    Carlos Loureiro
    * @since                                     19-Nov-2010
    ********************************************************************************************/
    PROCEDURE set_task_status_filter
    (
        i_task_type            IN cpoe_task_type_status_filter.id_task_type%TYPE,
        i_flg_status           IN cpoe_task_type_status_filter.flg_status%TYPE,
        i_status_internal_code IN cpoe_task_type_status_filter.status_internal_code%TYPE DEFAULT NULL,
        i_flg_filter_tab       IN cpoe_task_type_status_filter.flg_filter_tab%TYPE DEFAULT NULL,
        i_flg_proc_refresh     IN cpoe_task_type_status_filter.flg_cpoe_proc_refresh%TYPE DEFAULT NULL,
        i_flg_proc_new         IN cpoe_task_type_status_filter.flg_cpoe_proc_new%TYPE DEFAULT NULL,
        i_flg_proc_report      IN cpoe_task_type_status_filter.flg_cpoe_proc_report%TYPE DEFAULT NULL
    ) IS
    BEGIN
        -- update record using table's primary key
        UPDATE cpoe_task_type_status_filter ttsf
           SET ttsf.status_internal_code  = nvl(i_status_internal_code, ttsf.status_internal_code),
               ttsf.flg_filter_tab        = nvl(i_flg_filter_tab, ttsf.flg_filter_tab),
               ttsf.flg_cpoe_proc_refresh = nvl(i_flg_proc_refresh, ttsf.flg_cpoe_proc_refresh),
               ttsf.flg_cpoe_proc_new     = nvl(i_flg_proc_new, ttsf.flg_cpoe_proc_new),
               ttsf.flg_cpoe_proc_report  = nvl(i_flg_proc_report, ttsf.flg_cpoe_proc_report)
         WHERE ttsf.id_task_type = i_task_type
           AND ttsf.flg_status = i_flg_status;
        -- if no record was found, then insert a new record
        IF (SQL%ROWCOUNT = 0)
        THEN
            INSERT INTO cpoe_task_type_status_filter
                (id_task_type,
                 flg_status,
                 status_internal_code,
                 flg_filter_tab,
                 flg_cpoe_proc_refresh,
                 flg_cpoe_proc_new,
                 flg_cpoe_proc_report)
            VALUES
                (i_task_type,
                 i_flg_status,
                 i_status_internal_code,
                 i_flg_filter_tab,
                 i_flg_proc_refresh,
                 i_flg_proc_new,
                 i_flg_proc_report);
        END IF;
    END set_task_status_filter;

    /********************************************************************************************
    * set intake and output (hidric) references in cpoe_task_type table (to be executed only by DEFAULT)
    *
    * @author                                Carlos Loureiro
    * @since                                 12-JUN-2012
    ********************************************************************************************/
    PROCEDURE set_cpoe_hidric_references IS
    BEGIN
        -- call set_cpoe_hidric_references procedure
        pk_cpoe.set_cpoe_hidric_references;
    END set_cpoe_hidric_references;

/********************************************************************************************/
/********************************************************************************************/
/********************************************************************************************/

BEGIN
    -- log initialization
    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(object_name => g_package_name);
END pk_cpoe_db;

/
