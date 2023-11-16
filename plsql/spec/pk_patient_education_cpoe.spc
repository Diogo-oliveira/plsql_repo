/*-- Last Change Revision: $Rev: 2028849 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:18 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_patient_education_cpoe IS

    -- Author  : NUNO.NEVES
    -- Created : 10-05-2011 18:19:09
    -- Purpose : 
    FUNCTION copy_to_draft
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN episode.id_episode%TYPE,
        i_task_request         IN cpoe_process_task.id_task_request%TYPE,
        i_task_start_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_task_end_timestamp   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_draft                OUT cpoe_process_task.id_task_request%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;
    --------------------------------------------------------------------
    FUNCTION create_draft
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN nurse_tea_req.id_episode%TYPE,
        i_topics          IN table_number,
        i_compositions    IN table_table_number,
        i_diagnoses       IN table_clob,
        i_to_be_performed IN table_varchar,
        i_start_date      IN table_varchar,
        i_notes           IN table_varchar,
        i_description     IN table_clob,
        i_order_recurr    IN table_number,
        i_desc_topic_aux  IN table_varchar,
        o_draft           OUT table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /******************************************************************************************** 
    * activate draft tasks (task goes from draft to active workflow) 
    * 
    * @param       i_lang                 language id 
    * @param       i_prof                 professional id structure 
    * @param       i_episode              episode id  
    * @param       i_draft                array of draft requests  
    * @param       i_flg_commit           transaction control
    * @param       o_created_tasks        array of created taksk requests    
    * @param       o_error                error message 
    * 
    * @value       i_flg_commit           {*} 'Y' commit/rollback the transaction 
    *                                     {*} 'N' transaction control is done outside  
    *
    * @return                             true on success, otherwise false
    **********************************************************************************************/
    FUNCTION activate_drafts
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_draft      IN table_number,
        i_flg_commit IN VARCHAR2,
        
        o_created_tasks OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    --
    FUNCTION cancel_draft
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_draft   IN table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * cancel all draft tasks
    *
    * @param          i_lang              language id    
    * @param          i_prof              professional type
    * @param          i_episode           episode id
    * @param          o_error             error message
    *
    * @return         boolean             true on success, otherwise false
    **********************************************************************************************/
    FUNCTION cancel_all_drafts
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /******************************************************************************************** 
    * Check conflicts upon created drafts (verify if drafts can be requested or not) 
    * 
    * @param       i_lang                    preferred language id for this professional 
    * @param       i_prof                    professional id structure 
    * @param       i_episode                 episode id  
    * @param       i_draft                   draft id 
    * @param       o_flg_conflict            array of draft conflicts indicators
    * @param       o_msg_template            array of message/pop-up templates
    * @param       o_msg_title               array of message titles 
    * @param       o_msg_body                array of message bodies
    * @param       o_error                   error message 
    * 
    * @value       o_flg_conflict            {*} 'Y' the draft has conflicts  
    *                                        {*} 'N' no conflicts found 
    *    
    * @value       o_msg_template            {*} ' WARNING_READ' Warning Read
    *                                        {*} 'WARNING_CONFIRMATION' Warning Confirmation
    *                                        {*} 'WARNING_CANCEL' Warning Cancel
    *                                        {*} 'WARNING_HELP_SAVE' Warning Help Save
    *                                        {*} 'WARNING_SECURITY' Warning Security
    *                                        {*} 'CONFIRMATION' Confirmation
    *                                        {*} 'DETAIL' Detail
    *                                        {*} 'HELP' Help
    *                                        {*} 'WIZARD' Wizard
    *                                        {*} 'ADVANCED_INPUT' Advanced Input
    *         
    * @return                                True on success, false otherwise
    ********************************************************************************************/
    FUNCTION check_draft_conflicts
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_draft        IN table_number,
        o_flg_conflict OUT table_varchar,
        o_msg_title    OUT table_varchar,
        o_msg_body     OUT table_varchar,
        o_msg_template OUT table_varchar,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    --
    FUNCTION get_task_actions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN cpoe_process_task.id_task_request%TYPE,
        o_action       OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    --
    FUNCTION get_task_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_task_request  IN table_number,
        i_filter_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_filter_status IN table_varchar,
        i_flg_report    IN VARCHAR2 DEFAULT 'N',
        i_dt_begin      IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_dt_end        IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_plan_list     OUT pk_types.cursor_type,
        o_task_list     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    --
    FUNCTION get_task_parameters
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_draft  IN cpoe_process_task.id_cpoe_process%TYPE,
        o_params OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * get tasks status based in their requests
    *
    * @param       i_lang                 language id    
    * @param       i_prof                 professional structure
    * @param       i_episode              episode id
    * @param       i_task_request         array of requests that identifies the tasks
    * @param       o_task_status          cursor with all requested task status
    * @param       o_error                error structure for exception handling
    *
    * @return      boolean                true on success, otherwise false    
    ********************************************************************************************/
    FUNCTION get_task_status
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN table_number,
        o_task_status  OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    --
    FUNCTION set_action
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_action       IN action.id_action%TYPE,
        i_task_request IN cpoe_process_task.id_task_request%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    --
    FUNCTION set_task_parameters
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN nurse_tea_req.id_episode%TYPE,
        i_draft           IN table_number, --i_id_nurse_tea_req
        i_topics          IN table_number,
        i_diagnoses       IN table_table_number,
        i_to_be_performed IN table_varchar,
        i_start_date      IN table_varchar, --i_dt_begin
        i_notes           IN table_varchar,
        i_description     IN table_clob,
        i_order_recurr    IN table_number,
        o_error           OUT t_error_out
        
    ) RETURN BOOLEAN;
    /**
    * Expire tasks action (task will change its state to expired)
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id
    * @param       i_task_requests           array of task request ids to expire
    * @param       o_error                   error message structure
    *
    * @return                                true on success, false otherwise
    */
    FUNCTION expire_task
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_task_requests IN table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Check the possibility to be recorded in the system an execution after the task was expired.
    It was defined that it should be possible to record in the system the last execution made after the task expiration.
    It should not be possible to record more than one excecution after the task was expired. 
    *
    * @param   i_lang           Professional preferred language
    * @param   i_prof           Professional identification and its context (institution and software)
    * @param   i_task_request   Task request ID (ID_INTERV_PRESC_DET)
    * @param   o_error          Error information
    *
    * @return  'Y' An execution is allowed. 'N' No execution is allowed (or the task has not expired).
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.1.5
    * @since   04-11-2011
    */
    FUNCTION check_extra_take
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN cpoe_process_task.id_task_request%TYPE
    ) RETURN VARCHAR;

    /**
    * Check the possibility to be recorded in the system an execution after the task was expired.
    It was defined that it should be possible to record in the system the last execution made after the task expiration.
    It should not be possible to record more than one excecution after the task was expired. 
    *
    * @param   i_lang           Professional preferred language
    * @param   i_prof           Professional identification and its context (institution and software)
    * @param   i_task_request   Task request ID (ID_INTERV_PRESC_DET)
    * @param   i_status         Task request Status
    * @param   i_dt_expire      Task request expiration date
    *
    * @return  'Y' An execution is allowed. 'N' No execution is allowed (or the task has not expired).
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.1.5
    * @since   04-11-2011
    */
    FUNCTION check_extra_take
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN cpoe_process_task.id_task_request%TYPE,
        i_status       IN nurse_tea_req.flg_status%TYPE,
        i_dt_expire    IN nurse_tea_req.dt_close_tstz%TYPE
    ) RETURN VARCHAR;

    FUNCTION get_order_plan_report
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_task_request  IN table_number,
        i_cpoe_dt_begin IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_cpoe_dt_end   IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_plan_rep      OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    g_nurse_tea_req_sug   CONSTANT nurse_tea_req.flg_status%TYPE := 'S';
    g_nurse_tea_req_pend  CONSTANT nurse_tea_req.flg_status%TYPE := 'D';
    g_nurse_tea_req_act   CONSTANT nurse_tea_req.flg_status%TYPE := 'A';
    g_nurse_tea_req_fin   CONSTANT nurse_tea_req.flg_status%TYPE := 'F';
    g_nurse_tea_req_canc  CONSTANT nurse_tea_req.flg_status%TYPE := 'C';
    g_nurse_tea_req_ign   CONSTANT nurse_tea_req.flg_status%TYPE := 'I';
    g_nurse_tea_req_draft CONSTANT nurse_tea_req.flg_status%TYPE := 'Z';

    g_active icnp_epis_diagnosis.flg_status%TYPE := 'A';

END pk_patient_education_cpoe;
/
