/*-- Last Change Revision: $Rev: 2028806 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:03 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_movement IS

    SUBTYPE obj_name IS VARCHAR2(30);
    SUBTYPE debug_msg IS VARCHAR2(4000);

    /** @headcom
    * Public Function. Criar movimento, no caso de requisição de transportes.   
    *
    * @param    i_lang           língua registada como preferência do profissional.
    * @param    i_episode        ID do episódio
    * @param    i_prof           object (ID do profissional, ID da instituição, ID do software).
    * @param    i_room           sala de destino
    * @param    i_necessity      necessidade
    * @param    i_dt_req         Data de requisição; ñ precisa de ser preenchido
    * @param    i_prof_cat_type  Tipo de categoria do profissional, tal 
                                 como é retornada em PK_LOGIN.GET_PROF_PREF 
    * @param    o_id_mov         ID do movimento 
    * @param    o_flg_show       Y - existe msg para mostrar; N - ñ existe 
    * @param    o_msg            mensagem
    * @param    o_msg_title      Título da msg a mostrar ao utilizador, caso 
                                 O_FLG_SHOW = Y 
    * @param    o_button         Botões a mostrar: N - não, R - lido, C - confirmado 
                                 Tb pode mostrar combinações destes, qd é p/ mostrar 
                                 + do q 1 botão 
    * @param    o_error          erro
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     CRS 
    * @version    0.1
    * @since      2005/02/28
    */

    FUNCTION call_create_movement
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN movement.id_episode%TYPE,
        i_prof          IN profissional,
        i_room          IN movement.id_room_to%TYPE,
        i_necessity     IN movement.id_necessity%TYPE,
        i_dt_req_str    IN VARCHAR2,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_id_mov        OUT movement.id_movement%TYPE,
        o_flg_show      OUT VARCHAR2,
        o_msg           OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_button        OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_new_location
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN movement.id_episode%TYPE,
        i_prof          IN profissional,
        i_room          IN movement.id_room_to%TYPE,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_flg_show      OUT VARCHAR2,
        o_msg           OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_button        OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_new_location_no_commit
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN movement.id_episode%TYPE,
        i_prof          IN profissional,
        i_room          IN movement.id_room_to%TYPE,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_flg_show      OUT VARCHAR2,
        o_msg           OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_button        OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_movement
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN movement.id_episode%TYPE,
        i_prof          IN profissional,
        i_room          IN movement.id_room_to%TYPE,
        i_necessity     IN movement.id_necessity%TYPE,
        i_dt_req_str    IN VARCHAR2,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_id_mov        OUT movement.id_movement%TYPE,
        o_flg_show      OUT VARCHAR2,
        o_msg           OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_button        OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_movement_no_commit
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN movement.id_episode%TYPE,
        i_prof          IN profissional,
        i_room          IN movement.id_room_to%TYPE,
        i_necessity     IN movement.id_necessity%TYPE,
        i_dt_req_str    IN VARCHAR2,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_id_mov        OUT movement.id_movement%TYPE,
        o_flg_show      OUT VARCHAR2,
        o_msg           OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_button        OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_movement
    (
        i_lang          IN language.id_language%TYPE,
        i_movement      IN movement.id_movement%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_mov_request
    (
        i_lang      IN language.id_language%TYPE,
        i_movement  movement.id_movement%TYPE,
        o_flg_exist OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_mov_begin
    (
        i_lang     IN language.id_language%TYPE,
        i_movement IN movement.id_movement%TYPE,
        i_prof     IN profissional,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_mov_end
    (
        i_lang          IN language.id_language%TYPE,
        i_movement      IN movement.id_movement%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_mov
    (
        i_lang          IN language.id_language%TYPE,
        i_movement      IN movement.id_movement%TYPE,
        i_prof          IN profissional,
        i_notes         IN movement.notes_cancel%TYPE,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_mov_no_commit
    (
        i_lang          IN language.id_language%TYPE,
        i_movement      IN movement.id_movement%TYPE,
        i_prof          IN profissional,
        i_notes         IN movement.notes_cancel%TYPE,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_movement_request
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_movement IN movement.id_movement%TYPE,
        i_notes    IN movement.notes_cancel%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_mov
    (
        i_lang        IN language.id_language%TYPE,
        i_episode     IN movement.id_episode%TYPE,
        i_room        IN movement.id_room_to%TYPE,
        i_prof        IN profissional,
        o_id_movement OUT movement.id_movement%TYPE,
        o_flg_show    OUT VARCHAR2,
        o_msg_text    OUT VARCHAR2,
        o_msg_title   OUT VARCHAR2,
        o_button      OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_transp_mov
    (
        i_lang     IN language.id_language%TYPE,
        i_episode  IN movement.id_episode%TYPE,
        o_movement OUT movement.id_movement%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_mov_info
    (
        i_lang     IN language.id_language%TYPE,
        i_movement IN movement.id_movement%TYPE,
        i_prof     IN profissional,
        o_mov      OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_from_location
    (
        i_lang        IN language.id_language%TYPE,
        i_movement    IN movement.id_movement%TYPE,
        i_prof        IN profissional,
        o_movement    OUT movement.id_movement%TYPE,
        o_id_location OUT movement.id_room_to%TYPE,
        o_location    OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_from_location_desc
    (
        i_lang     IN language.id_language%TYPE,
        i_movement IN movement.id_movement%TYPE,
        i_prof     IN profissional
    ) RETURN VARCHAR2;

    FUNCTION get_mov_episode
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN movement.id_episode%TYPE,
        i_prof    IN profissional,
        o_mov     OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION insert_movement_task
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION update_movement_task
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_rooms_assig
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_room  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_status_room
    (
        i_room     IN room.id_room%TYPE,
        i_capacity IN room.capacity%TYPE
    ) RETURN VARCHAR2;

    --

    TYPE prev_local IS RECORD(
        
        id_dept       dept.id_dept%TYPE,
        id_department department.id_department%TYPE,
        id_room       room.id_room%TYPE);

    FUNCTION get_curr_local_type
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN movement.id_episode%TYPE
    ) RETURN department.flg_type%TYPE;

    FUNCTION get_next_dest_type
    (
        i_lang           IN language.id_language%TYPE,
        i_mov_dest_types IN sys_config.value%TYPE,
        i_pos            IN PLS_INTEGER
    ) RETURN department.flg_type%TYPE;

    FUNCTION get_prev_local
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN movement.id_episode%TYPE,
        i_type    IN department.flg_type%TYPE
    ) RETURN prev_local;

    FUNCTION get_default_destination
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN movement.id_episode%TYPE,
        o_dept       OUT dept.id_dept%TYPE,
        o_department OUT department.id_department%TYPE,
        o_room       OUT room.id_room%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_location_visit
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN movement.id_episode%TYPE,
        i_room    IN movement.id_room_to%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_necess_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_mov     IN necessity.flg_mov%TYPE,
        o_necess  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Provide list of ongoing Movements tasks for the patient death feature. All the transports in this list must be possible to cancel.
    *
    * @param   I_LANG               language associated to the professional executing the request
    * @param   I_PROF               Professional type
    * @param   I_ID_PATIENT         Patient ID
    *
    * @RETURN  tf_tasks_list (table of tr_tasks_list)
    * @author  Rui de Sousa Neves
    * @version 2.6.0.3
    * @since   11-MAY-2010
    *
    */
    FUNCTION get_ongoing_tasks_transp
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN tf_tasks_list;

    /*
    * Provide list of reactivatable Movements tasks for the patient death feature. 
    *
    * @param   I_LANG               language associated to the professional executing the request
    * @param   I_PROF               Professional type
    * @param   I_ID_SUSP_ACTION     Corresponding ID_SUSP_ACTION
    * @param   I_WFSTATUS           Pretended WF Status (from the SUSP_TASK table)
    *
    * @RETURN  tf_tasks_list (table of tr_tasks_list)
    * @author  Rui de Sousa Neves
    * @version 2.6.0.3
    * @since   18-MAY-2010
    *
    */
    FUNCTION get_wfstatus_tasks_transp
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_susp_action IN susp_task.id_susp_action%TYPE,
        i_wfstatus       IN susp_task.flg_status%TYPE
    ) RETURN tf_tasks_react_list;

    /*
    * Suspend the ongoing tasks - Movements
    *
    * @param   I_LANG               language associated to the professional executing the request
    * @param   I_PROF               Professional type
    * @param   I_TASK               ID from the corresponding task
    * @param   I_FLG_REASON         Reason for the WF suspension: 'D' (Death)
    * @param   O_MSG_ERROR          Message to send to the UX in case one of the functions has some kind of error
    * @param   O_ERROR              warning/error message
    *
    * @RETURN  TRUE if success, FALSE otherwise
    * @author  Rui de Sousa Neves
    * @version 2.6.0.3
    * @since   13-MAY-2010
    *
    */
    FUNCTION suspend_task_transp
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_task       IN NUMBER,
        i_flg_reason IN VARCHAR2,
        o_msg_error  OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Reactivate the ongoing tasks - Movements
    *
    * @param   I_LANG               language associated to the professional executing the request
    * @param   I_PROF               Professional type
    * @param   I_TASK               ID from the corresponding task
    * @param   O_MSG_ERROR          Message to send to the UX in case one of the functions has some kind of error
    * @param   O_ERROR              warning/error message
    *
    * @RETURN  TRUE if success, FALSE otherwise
    * @author  Rui de Sousa Neves
    * @version 2.6.0.3
    * @since   21-MAY-2010
    *
    */
    FUNCTION reactivate_task_transp
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_task      IN NUMBER,
        o_msg_error OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get episode moments (used by reports and contains specific information for report generation)
    *
    * @param   I_LANG               language associated to the professional executing the request
    * @param   I_PROF               Professional type
    * @param   I_EPISODE            Episode ID
    * @param   O_ERROR              warning/error message
    *
    * @RETURN  TRUE if success, FALSE otherwise
    * @author  Rui Duarte
    * @version 2.6.0.4
    * @since   30-AUG-2010
    *
    */
    FUNCTION get_mov_epis_rep
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN movement.id_episode%TYPE,
        i_prof    IN profissional,
        o_mov     OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the next movement dbegin date
    *
    * @param i_episode               Episode ID
    * @param i_movement              actual Movement ID 
    * @param i_dt                    Actulament movement end date
    *
    * @return                        Begin date of next movement or the episode end_date
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.7.1.0
    * @since                         03-05-2017
    **********************************************************************************************/
    FUNCTION get_next_mov_date
    
    (
        i_episode  IN episode.id_episode%TYPE,
        i_movement IN movement.id_movement%TYPE,
        i_dt       IN movement.dt_end_tstz%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;
    /**********************************************************************************************
    * Gets the time in hours a patient stay in a specific room or the total time in room of a specific id_room_type
    *
    * @param i_episode               Episode ID
    * @param i_room_type             ID Room Type ( if not null the id_room is ignored) 
    * @param i_room                    ID room 
    *
    * @return                        Total time in hours
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.7.1.0
    * @since                         03-05-2017
    **********************************************************************************************/
    FUNCTION get_time_in_room
    (
        i_episode   IN episode.id_episode%TYPE,
        i_room_type IN room_type.id_room_type%TYPE DEFAULT NULL,
        i_room      IN room.id_room%TYPE DEFAULT NULL
    ) RETURN NUMBER;

    -- Movement types (M - movement and D - Detour)
    g_mov_type_movement CONSTANT VARCHAR2(1) := 'M';
    g_mov_type_detour   CONSTANT VARCHAR2(1) := 'D';

    -- Global variables
    g_general_exception EXCEPTION;
    g_sysdate_tstz     TIMESTAMP WITH LOCAL TIME ZONE;
    g_error            VARCHAR2(4000 CHAR);
    g_function_name    VARCHAR2(0100 CHAR);
    g_line_break       sys_message.desc_message%TYPE;
    g_error_suspension BOOLEAN;
    g_package_owner CONSTANT obj_name := 'ALERT';
    g_package_name  CONSTANT obj_name := pk_alertlog.who_am_i();
END;
/
