/*-- Last Change Revision: $Rev: 2028580 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:38 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_co_sign_ux AS

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
    * @author   Alexandre Santos
    * @version  2.6.4
    * @since    02-12-2014
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

    /**
    * Checks if the current professional needs co-sign to complete the action at the order 
    *
    * @param i_lang                   Language identifier
    * @param i_prof                   The professional record
    * @param i_episode                Episode id
    * @param i_task_type              Task type id
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
    FUNCTION check_prof_needs_cosign_order
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN episode.id_episode%TYPE,
        i_task_type            IN task_type.id_task_type%TYPE,
        o_flg_prof_need_cosign OUT VARCHAR2,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets all co-sing tasks, by professional identifier and patient episode
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                The episode ID
    * @param o_co_sign_list           Cursor containing the task list to co-sign 
                                          
    * @param o_error                  Error message
                        
    * @return                         true or false on success or error
    * 
    * @author                         Gisela Couto
    * @since                          2014/12/03
    **********************************************************************************************/

    FUNCTION get_co_sign_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        o_co_sign_list OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Changes the co-sign status to "co-signed" status.
    *
    * @param i_lang                    The language ID
    * @param i_prof                    Object (professional ID, institution ID, software ID)
    * @param i_episode                 The episode ID
    * @param i_tbl_id_co_sign          Co-sign record identifier
    * @param i_id_prof_cosigned        Professinonal that co-signs the order
    * @param i_cosign_notes            Co-sign notes
    * @param i_flg_made_auth           Flag that indicates if professional was made authentication: 
                                       (Y) - Yes, (N) - No
    * @param o_tbl_id_co_sign_hist     Co-sign history record id created 
    * @param o_error                   Error message          
    *                    
    * @return                         true or false on success or error
    * 
    * @author                         Gisela Couto
    * @since                          2014/12/03
    **********************************************************************************************/

    FUNCTION set_task_co_signed
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE,
        i_tbl_id_co_sign      IN table_number,
        i_id_prof_cosigned    IN co_sign.id_prof_co_signed%TYPE,
        i_cosign_notes        IN translation_trs.desc_translation%TYPE,
        i_flg_made_auth       IN co_sign.flg_made_auth%TYPE,
        o_tbl_id_co_sign_hist OUT table_number,
        o_error               OUT t_error_out
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

    /********************************************************************************************
    * Detailed current information about a co-sign task
    *
    * @param i_lang                    The language ID
    * @param i_prof                    Object (professional ID, institution ID, software ID)
    * @param i_id_co_sign              Co-sign task identifier
    * @param o_co_sign_info            Co-sign task info
    * @param o_error                   Error message          
    *                    
    * @return                         true or false on success or error
    * 
    * @author                         Gisela Couto
    * @since                          2014/12/11
    **********************************************************************************************/

    FUNCTION get_co_sign_current_det
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_co_sign   IN co_sign.id_co_sign%TYPE,
        o_co_sign_info OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Detailed history information about a co-sign task
    *
    * @param i_lang                    The language ID
    * @param i_prof                    Object (professional ID, institution ID, software ID)
    * @param i_id_co_sign              Co-sign task identifier
    * @param o_co_sign_info            Co-sign task info
    * @param o_error                   Error message          
    *                    
    * @return                         true or false on success or error
    * 
    * @author                         Gisela Couto
    * @since                          2014/12/11
    **********************************************************************************************/

    FUNCTION get_co_sign_history_det
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_co_sign   IN co_sign.id_co_sign%TYPE,
        o_co_sign_info OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Detailed current information about a co-sign task
    *
    * @param i_lang                    The language ID
    * @param i_prof                    Object (professional ID, institution ID, software ID)
    * @param i_id_co_sign              TABLE_NUMBER
    * @param o_co_sign_info            Co-sign task info
    * @param o_error                   Error message          
    *                    
    * @return                         true or false on success or error
    * 
    * @author                         Elisabete Bugalho
    * @since                          2017/03/15
    **********************************************************************************************/

    FUNCTION get_co_sign_current_det_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_co_sign   IN table_number,
        o_co_sign_info OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Detailed current information about a co-sign task
    *
    * @param i_lang                    The language ID
    * @param i_prof                    Object (professional ID, institution ID, software ID)
    * @param i_id_co_sign              TABLE_NUMBER
    * @param i_tbl_status              Co-sign task flag status list ('CS' - Cosigned)
    * @param o_co_sign_info            Co-sign task info
    * @param o_error                   Error message          
    *                    
    * @return                         true or false on success or error
    * 
    * @author                         Cristina oliveira
    * @since                          2020/11/13
    **********************************************************************************************/
    FUNCTION get_co_sign_current_det_by_status
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_co_sign   IN table_number,
        i_tbl_status   IN table_varchar DEFAULT NULL,
        o_co_sign_info OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    --
    g_owner CONSTANT VARCHAR2(6) := 'ALERT';
    g_package_name VARCHAR2(32);

    g_error        VARCHAR2(4000);
    g_sysdate      DATE;
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_sysdate_char VARCHAR2(50);
    g_found        BOOLEAN;

END pk_co_sign_ux;
/
