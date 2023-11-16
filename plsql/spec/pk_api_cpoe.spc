/*-- Last Change Revision: $Rev: 1738706 $*/
/*-- Last Change by: $Author: cristina.oliveira $*/
/*-- Date of last change: $Date: 2016-05-23 10:59:40 +0100 (seg, 23 mai 2016) $*/

CREATE OR REPLACE PACKAGE pk_api_cpoe IS

    -- Purpose : API for CPOE

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
    * get cpoe start date timestamp for a given task type/episode
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_task_type               cpoe task type id
    * @param       i_episode                 episode id 
    * @param       o_start_date              cpoe start date timestamp
    * @param       o_error                   error message
    *
    * @return      boolean                   true on success, otherwise false  
    * 
    * @author                                CRISTINA.OLIVEIRA
    * @since                                 20-05-2016
    ********************************************************************************************/
    FUNCTION get_cpoe_start_date_by_task
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_task_type  IN cpoe_task_type.id_task_type%TYPE,
        i_episode    IN cpoe_process_task.id_episode%TYPE,
        o_start_date OUT cpoe_process.dt_cpoe_proc_start%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************/
    /********************************************************************************************/
    /********************************************************************************************/

    -- general error descriptions
    g_error VARCHAR2(4000);

    -- log variables
    g_package_owner VARCHAR2(30);
    g_package_name  VARCHAR2(30);

END pk_api_cpoe;
/
