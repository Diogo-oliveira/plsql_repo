/*-- Last Change Revision: $Rev: 1924408 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2019-11-14 16:05:45 +0000 (qui, 14 nov 2019) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_movement IS

    /** @headcom
    * Public Function. Criar movimento, no caso de requisição de transportes.   
    *
    * Note: Esta é a função chamada pelos Interfaces.
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
    * @author     ASM 
    * @version    0.1
    * @since      2007/07/26
    */

    FUNCTION intf_create_movement
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN movement.id_episode%TYPE,
        i_prof          IN profissional,
        i_room          IN movement.id_room_to%TYPE,
        i_necessity     IN movement.id_necessity%TYPE,
        i_dt_req        IN VARCHAR2,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_id_mov        OUT movement.id_movement%TYPE,
        o_flg_show      OUT VARCHAR2,
        o_msg           OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_button        OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'PK_MOVEMENT.CALL_CREATE_MOVEMENT';
        IF NOT pk_movement.call_create_movement(i_lang          => i_lang,
                                                i_episode       => i_episode,
                                                i_prof          => i_prof,
                                                i_room          => i_room,
                                                i_necessity     => i_necessity,
                                                i_dt_req_str    => i_dt_req,
                                                i_prof_cat_type => i_prof_cat_type,
                                                o_id_mov        => o_id_mov,
                                                o_flg_show      => o_flg_show,
                                                o_msg           => o_msg,
                                                o_msg_title     => o_msg_title,
                                                o_button        => o_button,
                                                o_error         => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_MOVEMENT',
                                              'INTF_CREATE_MOVEMENT',
                                              'S',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END intf_create_movement;
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
    ) RETURN NUMBER IS
    BEGIN
        RETURN pk_movement.get_time_in_room(i_episode => i_episode, i_room_type => i_room_type, i_room => i_room);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_time_in_room;
BEGIN
    -- Log initialization.
    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);

END pk_api_movement;
/
