/*-- Last Change Revision: $Rev: 2028579 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:38 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_co_sign_api AS

    g_cosign_action_def_add    CONSTANT action.internal_name%TYPE := pk_co_sign.g_cosign_action_def_add;
    g_cosign_action_def_cancel CONSTANT action.internal_name%TYPE := pk_co_sign.g_cosign_action_def_cancel;

    --Pending state value
    g_cosign_flg_status_p CONSTANT sys_domain.val%TYPE := pk_co_sign.g_cosign_flg_status_p;
    --Co-signed state value
    g_cosign_flg_status_cs CONSTANT sys_domain.val%TYPE := pk_co_sign.g_cosign_flg_status_cs;
    --Not applicable state value
    g_cosign_flg_status_na CONSTANT sys_domain.val%TYPE := pk_co_sign.g_cosign_flg_status_na;
    --Draft state value
    g_cosign_flg_status_d CONSTANT sys_domain.val%TYPE := pk_co_sign.g_cosign_flg_status_d;
    --Outdated status value
    g_cosign_flg_status_o CONSTANT sys_domain.val%TYPE := pk_co_sign.g_cosign_flg_status_o;

    /********************************************************************************************
    * Gets co sign information by episode and/or by task identifier without task description
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                Episode identifier
    * @param i_id_co_sign             Co-sign task id
    
    *                        
    * @return                         Returns t_table_co_sign table function that contains co_sign 
    *                                 tasks information.
    * 
    * @author                         Gisela Couto
    * @version                        2.6.4
    * @since                          2014/12/03
    **********************************************************************************************/
    FUNCTION tf_co_sign_task_info
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_id_co_sign IN co_sign.id_co_sign%TYPE DEFAULT NULL
    ) RETURN t_table_co_sign;

    /********************************************************************************************
    * Gets co sign hist information by episode and/or by task identifier without task description
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                Episode identifier
    * @param i_id_co_sign             Co-sign task id
    *                        
    * @return                         Returns t_table_co_sign table function that contains co_sign 
    *                                 tasks information.
    * 
    * @author                         Gisela Couto
    * @version                        2.6.4
    * @since                          2014/12/03
    **********************************************************************************************/
    FUNCTION tf_co_sign_task_hist_info
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_id_co_sign      IN co_sign.id_co_sign%TYPE DEFAULT NULL,
        i_id_co_sign_hist IN co_sign_hist.id_co_sign_hist%TYPE DEFAULT NULL,
        i_task_type       IN task_type.id_task_type%TYPE DEFAULT NULL,
        i_id_task_group   IN co_sign.id_task_group%TYPE DEFAULT NULL,
        i_tbl_id_task     IN table_number DEFAULT NULL
    ) RETURN t_table_co_sign;

    /********************************************************************************************
    * Gets co sign information by episode and/or by task identifier
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                Episode identifier
    * @param i_task_type              Tsk type identifiera
    * @param i_tbl_id_co_sign         Co-sign tasks identifiers
    * @param i_prof_ord_by            Professional that was ordered the request - Ordered by
    *                        
    * @return                         Returns t_table_co_sign table function that contains co_sign 
    *                                 tasks information.
    * 
    * @author                         Gisela Couto
    * @version                        2.6.4
    * @since                          2014/12/03
    **********************************************************************************************/
    FUNCTION tf_co_sign_tasks_info
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_task_type     IN task_type.id_task_type%TYPE DEFAULT NULL,
        i_id_co_sign    IN table_number DEFAULT NULL,
        i_prof_ord_by   IN co_sign.id_prof_ordered_by%TYPE DEFAULT NULL,
        i_id_task_group IN co_sign.id_task_group%TYPE DEFAULT NULL,
        i_tbl_status    IN table_varchar DEFAULT table_varchar()
    ) RETURN t_table_co_sign;

    /********************************************************************************************
    * Gets information about pending co-sign tasks
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                Episode identifier
    * @param i_task_type              Tsk type identifiera
    * @param i_prof_ord_by            Professional that was ordered the request - Ordered by
    *                        
    * @return                         Returns t_table_co_sign table function that contains co_sign 
    *                                 tasks information.
    * 
    * @author                         Gisela Couto
    * @version                        2.6.4
    * @since                          2014/12/03
    **********************************************************************************************/
    FUNCTION tf_pending_co_sign_tasks
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        i_task_type   IN task_type.id_task_type%TYPE DEFAULT NULL,
        i_prof_ord_by IN co_sign.id_prof_ordered_by%TYPE DEFAULT NULL
    ) RETURN t_table_co_sign;

    /********************************************************************************************
    * Gets information about co-signed tasks
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                Episode identifier
    * @param i_task_type              Tsk type identifiera
    * @param i_prof_ord_by            Professional that was ordered the request - Ordered by
    *                        
    * @return                         Returns t_table_co_sign table function that contains co_sign 
    *                                 tasks information.
    * 
    * @author                         Gisela Couto
    * @version                        2.6.4
    * @since                          2014/12/03
    **********************************************************************************************/
    FUNCTION tf_co_signed_tasks
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        i_task_type   IN task_type.id_task_type%TYPE DEFAULT NULL,
        i_prof_ord_by IN co_sign.id_prof_ordered_by%TYPE DEFAULT NULL
    ) RETURN t_table_co_sign;

    /********************************************************************************************
    * Gets information about outdated co-sign tasks
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                Episode identifier
    * @param i_task_type              Tsk type identifiera
    * @param i_prof_ord_by            Professional that was ordered the request - Ordered by
    *                        
    * @return                         Returns t_table_co_sign table function that contains co_sign 
    *                                 tasks information.
    * 
    * @author                         Gisela Couto
    * @version                        2.6.4
    * @since                          2014/12/03
    **********************************************************************************************/
    FUNCTION tf_outdated_co_sign_tasks
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        i_task_type   IN task_type.id_task_type%TYPE DEFAULT NULL,
        i_prof_ord_by IN co_sign.id_prof_ordered_by%TYPE DEFAULT NULL
    ) RETURN t_table_co_sign;

    /********************************************************************************************
    * Creates the co-sign task in draft status
    *
    * @param i_lang                    The language ID
    * @param i_prof                    Object (professional ID, institution ID, software ID)
    * @param i_episode                 The episode ID
    * @param i_id_task_type            Task type identifier
    * @param i_id_task                 Task id
    * @param i_id_task_group           Task group id
    * @param i_id_order_type           Order type identifier
    * @param i_id_prof_created         Professional identifier that was created the order  
    * @param i_id_prof_ordered_by      Professional identifier that is the ordered by     
    * @param i_dt_created              Order creation date
    * @param i_dt_ordered_by           Date ordered by
    * @param o_id_co_sign              Co-sign record identifier created  
    * @param o_id_co_sign_hist         Co-sign history record id created 
    * @param o_error                   Error message          
    *                    
    * @return                         true or false on success or error
    * 
    * @author                         Gisela Couto
    * @since                          2014/12/03
    **********************************************************************************************/
    FUNCTION set_draft_co_sign_task
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_id_co_sign      IN co_sign.id_co_sign%TYPE DEFAULT NULL,
        i_id_co_sign_hist IN co_sign_hist.id_co_sign_hist%TYPE DEFAULT NULL,
        i_id_task_type    IN task_type.id_task_type%TYPE,
        i_id_task         IN co_sign.id_task%TYPE,
        i_id_task_group   IN co_sign.id_task_group%TYPE,
        i_id_order_type   IN co_sign.id_order_type%TYPE,
        --
        i_id_prof_created    IN co_sign.id_prof_created%TYPE,
        i_id_prof_ordered_by IN co_sign.id_prof_ordered_by%TYPE,
        --
        i_dt_created      IN co_sign.dt_created%TYPE,
        i_dt_ordered_by   IN co_sign.dt_ordered_by%TYPE,
        o_id_co_sign      OUT co_sign.id_co_sign%TYPE,
        o_id_co_sign_hist OUT co_sign_hist.id_co_sign_hist%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Creates the co-sign task in pending status
    *
    * @param i_lang                    The language ID
    * @param i_prof                    Object (professional ID, institution ID, software ID)
    * @param i_episode                 The episode ID
    * @param i_id_co_sign              Co-sign task identifier (to be updated)
    * @param i_id_co_sign_hist         Co-sign-hist task identifier (to be updated)
    * @param i_id_task_type            Task type identifier
    * @param i_id_action               Action identifier
    * @param i_cosign_def_action_type  Co-sign default action ('NEEDS_COSIGN_ORDER', 'NEEDS_COSIGN_CANCEL',
                                       'HAS_COSIGN')       
    * @param i_id_task                 Task id
    * @param i_id_task_group           Task group id
    * @param i_id_order_type           Order type identifier
    * @param i_id_prof_created         Professional identifier that was created the order  
    * @param i_id_prof_ordered_by      Professional identifier that is the ordered by     
    * @param i_dt_created              Order creation date
    * @param i_dt_ordered_by           Date ordered by
    * @param o_id_co_sign              Co-sign record identifier created  
    * @param o_id_co_sign_hist         Co-sign history record id created 
    * @param o_error                   Error message          
    *                    
    * @return                         true or false on success or error
    * 
    * @author                         Gisela Couto
    * @since                          2014/12/03
    **********************************************************************************************/
    FUNCTION set_pending_co_sign_task
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN episode.id_episode%TYPE,
        i_id_co_sign             IN co_sign.id_co_sign%TYPE DEFAULT NULL,
        i_id_co_sign_hist        IN co_sign_hist.id_co_sign_hist%TYPE DEFAULT NULL,
        i_id_task_type           IN task_type.id_task_type%TYPE,
        i_id_action              IN action.id_action%TYPE DEFAULT NULL,
        i_cosign_def_action_type IN action.internal_name%TYPE DEFAULT pk_co_sign.g_cosign_action_def_add,
        i_id_task                IN co_sign.id_task%TYPE,
        i_id_task_group          IN co_sign.id_task_group%TYPE,
        i_id_order_type          IN co_sign.id_order_type%TYPE DEFAULT NULL,
        --
        i_id_prof_created    IN co_sign.id_prof_created%TYPE DEFAULT NULL,
        i_id_prof_ordered_by IN co_sign.id_prof_ordered_by%TYPE DEFAULT NULL,
        --
        i_dt_created      IN co_sign.dt_created%TYPE DEFAULT NULL,
        i_dt_ordered_by   IN co_sign.dt_ordered_by%TYPE DEFAULT NULL,
        o_id_co_sign      OUT co_sign.id_co_sign%TYPE,
        o_id_co_sign_hist OUT co_sign_hist.id_co_sign_hist%TYPE,
        
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Change co-sign task status to "outdated" status.
    *
    * @param i_lang                    The language ID
    * @param i_prof                    Object (professional ID, institution ID, software ID)
    * @param i_episode                 The episode ID
    * @param i_id_co_sign              Co-sign record identifiers
    * @param i_id_co_sign_hist         Co_sign_hist record identifiers
    * @param i_dt_update               Date when record was updated
    * @param o_id_co_sign_hist         Co-sign history record id created 
    * @param o_error                   Error message          
    *                    
    * @return                         true or false on success or error
    * 
    * @author                         Gisela Couto
    * @since                          2014/12/03
    **********************************************************************************************/

    FUNCTION set_task_outdated
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_id_co_sign      IN co_sign.id_co_sign%TYPE,
        i_id_co_sign_hist IN co_sign_hist.id_co_sign_hist%TYPE DEFAULT NULL,
        i_dt_update       IN co_sign.dt_created%TYPE DEFAULT current_timestamp,
        o_id_co_sign_hist OUT co_sign_hist.id_co_sign_hist%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Change co-sign task status to "waiting fo co-sign" status.
    *
    * @param i_lang                    The language ID
    * @param i_prof                    Object (professional ID, institution ID, software ID)
    * @param i_episode                 The episode ID
    * @param i_id_co_sign              Co-sign record identifiers
    * @param i_id_co_sign_hist         Co_sign_hist record identifiers
    * @param i_id_task_upd             New task id to update from old one, null if not to be updated
    * @param i_dt_update               Date when record was updated
    * @param o_id_co_sign_hist         Co-sign history record id created 
    * @param o_error                   Error message          
    *                    
    * @return                         true or false on success or error
    * 
    * @author                         Gisela Couto
    * @since                          2014/12/03
    **********************************************************************************************/

    FUNCTION set_task_pending
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_id_co_sign      IN co_sign.id_co_sign%TYPE,
        i_id_co_sign_hist IN co_sign_hist.id_co_sign_hist%TYPE DEFAULT NULL,
        i_id_task_upd     IN co_sign.id_task%TYPE DEFAULT NULL,
        i_dt_update       IN co_sign.dt_created%TYPE DEFAULT current_timestamp,
        o_id_co_sign_hist OUT co_sign_hist.id_co_sign_hist%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets a set of professionals that can made the co-sign
    *
    * @param i_lang                    The language ID
    * @param i_prof                    Object (professional ID, institution ID, software ID)
    * @param i_id_episode              The episode ID
    * @param o_prof_list               Professional data
    * @param o_error                   Error message          
    *                    
    * @return                         true or false on success or error
    * 
    * @author                         Gisela Couto
    * @since                          2014/12/03
    **********************************************************************************************/
    FUNCTION get_prof_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_prof_list  OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets a set of professionals that can made the co-sign
    *
    * @param i_lang                    The language ID
    * @param i_prof                    Object (professional ID, institution ID, software ID)
    * @param i_id_episode              The episode ID
    * @param i_id_order_type              Order type identifier
    * @param o_prof_list               Professional data
    * @param o_error                   Error message          
    *                    
    * @return                         true or false on success or error
    * 
    * @author                         Gisela Couto
    * @since                          2014/12/03
    **********************************************************************************************/
    FUNCTION get_prof_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_id_order_type IN order_type.id_order_type%TYPE,
        o_prof_list     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * List all types of orders existing in co-sign 
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Professional identifier
    * @param o_order_type             Order list                                
    * @param o_error                  Error message
                        
    * @return                         true or false on success or error
    * 
    * @author                         Gisela Couto
    * @since                          2014/12/04
    **********************************************************************************************/
    FUNCTION get_order_type
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        o_order_type OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Checks if the current professional needs co-sign to complete the action
    *
    * @param i_lang                   Language identifier
    * @param i_prof                   The professional record
    * @param i_episode                Episode id
    * @param i_task_type              Task type id
    * @param i_cosign_def_action_type Co-sign default action (Only send this parameter or i_action)
    * @param i_action                 Action id (Only send this parameter or i_cosign_def_action_type)
    * @param o_flg_prof_need_cosign   Professional needs cosig? Y - Yes; N - Otherwise 
    * @param o_error                  Error message
    *
    * @value   i_cosign_def_action_type  ADD    - Add co-sign task
    *                                    CANCEL - Cancel co-sign task
    *
    * @return  true or false on success or error
    *
    * @author   Alexandre Santos
    * @version  2.6.4
    * @since    02-12-2014
    */
    FUNCTION check_prof_needs_cosign
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN episode.id_episode%TYPE,
        i_task_type              IN task_type.id_task_type%TYPE,
        i_cosign_def_action_type IN action.internal_name%TYPE,
        i_action                 IN action.id_action%TYPE DEFAULT NULL,
        o_flg_prof_need_cosign   OUT VARCHAR2,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Checks if the current professional needs co-sign to complete the action
    *
    * @param i_lang                   Language identifier
    * @param i_prof                   The professional record
    * @param i_episode                Episode id
    * @param i_task_type              Task type id
    * @param i_cosign_def_action_type Co-sign default action (Only send this parameter or i_action)
    * @param i_action                 Action id (Only send this parameter or i_cosign_def_action_type)
    * @param o_error                  Error message
    *
    * @value   i_cosign_def_action_type  ADD    - Add co-sign task
    *                                    CANCEL - Cancel co-sign task
    *
    * @return  Professional needs cosign: Y - Yes; N - Otherwise 
    *
    * @author   Alexandre Santos
    * @version  2.6.4
    * @since    02-12-2014
    */
    FUNCTION check_prof_needs_cosign
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN episode.id_episode%TYPE,
        i_task_type              IN task_type.id_task_type%TYPE,
        i_cosign_def_action_type IN action.internal_name%TYPE,
        i_action                 IN action.id_action%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    /**
    * Checks if the current professional needs co-sign to complete the action
    *
    * @param i_lang                   Language identifier
    * @param i_prof                   The professional record
    * @param i_episode                Episode id
    * @param i_tbl_task_type          Task type ids
    * @param i_cosign_def_action_type Co-sign default action (Only send this parameter or i_action)
    * @param i_action                 Action id (Only send this parameter or i_cosign_def_action_type)
    * @param o_flg_prof_need_cosign   Professional needs cosig? Y - Yes; N - Otherwise
    * @param o_error                  Error message
    *
    * @value   i_cosign_def_action_type  ADD    - Add co-sign task
    *                                    CANCEL - Cancel co-sign task
    *
    * @return  true or false on success or error
    *
    * @author   Nuno Alves
    * @version  2.6.5
    * @since    18-06-2015
    */
    FUNCTION check_prof_needs_cosign
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN episode.id_episode%TYPE,
        i_tbl_id_task_type       IN table_number,
        i_cosign_def_action_type IN action.internal_name%TYPE,
        i_action                 IN action.id_action%TYPE,
        o_flg_prof_need_cosign   OUT VARCHAR2,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Match co-sign task from id_episode to id_episode_new  
    *
    * @param i_lang                    The language ID
    * @param i_prof                    Object (professional ID, institution ID, software ID)
    * @param i_id_episode              Old episode identifier
    * @param i_id_episode_new          New episode identifier
    *
    * @param o_error                   Error message       
    *                    
    * @return                         true or false on success or error
    * 
    * @author                         Gisela Couto
    * @since                          2015/01/13
    **********************************************************************************************/

    FUNCTION match_co_sign_task
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_id_episode_new IN episode.id_episode%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns de id_action based on the default co-sign actions  
    *
    * @param i_cosign_def_action_type  The default co_sign action (order or cancel)
    *
    * @param o_error                   Error message       
    *                    
    * @return                         id_action
    * 
    * @author                         Nuno Alves
    * @since                          2015/04/10
    **********************************************************************************************/
    FUNCTION get_id_action(i_cosign_def_action_type IN action.internal_name%TYPE) RETURN action.id_action%TYPE;

    /*********************************************************************************************
    * This function deletes all data related to a co-sign request for patient (all episodes) 
    * or for a singular patient episode. 
    *
    * @param i_lang                    The language ID
    * @param i_prof                    Object (professional ID, institution ID, software ID)
    * @param i_id_patients             Array of patient identifiers
    * @param i_id_episodes             Array of episode identifiers
    *
    * @param o_error                   Error message       
    *                    
    * @return                         true or false on success or error
    * 
    * @author                         Renato Nunes
    * @since                          2015/04/10
    **********************************************************************************************/

    FUNCTION reset_cosign_reg
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_patients IN table_number,
        i_id_episodes IN table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /*********************************************************************************************
    * This function deletes all task_type data related to a co-sign request in a task_type_group
    *
    * @param i_lang                    The language ID
    * @param i_prof                    Object (professional ID, institution ID, software ID)
    * @param i_id_episode              Episode identifier
    * @param i_id_task_group           Task group identifiers
    * @param i_id_task_type            Task Type identifier
    *
    * @param o_error                   Error message       
    *                    
    * @return                          true or false on success or error
    * 
    * @author                          Renato Nunes
    * @since                           2015/04/13
    **********************************************************************************************/

    FUNCTION remove_draft_cosign
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_id_task_group IN task_group.id_task_group%TYPE,
        i_id_task_type  IN task_type.id_task_type%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets co sign  information by id_co_sign_hist without task description
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                Episode identifier
    * @param i_id_co_sign_hist        ID Co-sign task id
    *                        
    * @return                         Returns t_table_co_sign table function that contains co_sign 
    *                                 tasks information.
    * 
    * @author                         Elisabete Bugalho
    * @version                        2.6.5
    * @since                          2015/04/15
    **********************************************************************************************/
    FUNCTION tf_co_sign_task_info_by_hist
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_id_co_sign_hist IN co_sign_hist.id_co_sign_hist%TYPE,
        i_flg_with_desc   IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_tbl_status      IN table_varchar DEFAULT NULL
    ) RETURN t_table_co_sign;

    /********************************************************************************************
    * Check if order type generates co_sign workflow
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_order_type          Order type identifier 
    *                        
    * @return                         Returns 'Y' or 'N'
    * 
    * @author                         Nuno Alves
    * @version                        2.6.5
    * @since                          2015/04/22
    **********************************************************************************************/
    FUNCTION get_order_type_generates_wf
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_order_type IN order_type.id_order_type%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_id_co_sign_from_hist(i_id_co_sign_hist co_sign_hist.id_co_sign_hist%TYPE)
        RETURN co_sign_hist.id_co_sign%TYPE;

    /********************************************************************************************
    *  Get current state of cosign for viewer checlist 
    *             
    * @param    i_lang           Language ID
    * @param    i_prof           Logged professional structure
    * @param    i_scope_type     Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode     Episode ID
    * @param    i_id_patient     Patient ID
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                     
    * @version                    
    * @since                              
    **********************************************************************************************/
    FUNCTION get_co_sign_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    --
    g_pk_owner CONSTANT VARCHAR2(6) := 'ALERT';
    g_package_name VARCHAR2(32);

    g_error        VARCHAR2(4000);
    g_sysdate      DATE;
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_sysdate_char VARCHAR2(50);
    g_found        BOOLEAN;

END pk_co_sign_api;
/
