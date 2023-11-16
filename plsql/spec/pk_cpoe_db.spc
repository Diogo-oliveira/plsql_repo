/*-- Last Change Revision: $Rev: 2028582 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:39 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_cpoe_db IS

    -- Computerized Prescription Order Entry (CPOE) DB API database package

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    );

    /********************************************************************************************
    * set intake and output (hidric) references in cpoe_task_type table (to be executed only by DEFAULT)
    *
    * @author                                Carlos Loureiro
    * @since                                 12-JUN-2012
    ********************************************************************************************/
    PROCEDURE set_cpoe_hidric_references;

END pk_cpoe_db;

/
