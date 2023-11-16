/*-- Last Change Revision: $Rev: 1924408 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2019-11-14 16:05:45 +0000 (qui, 14 nov 2019) $*/

CREATE OR REPLACE PACKAGE pk_api_movement IS

    -- Author  : Rui Spratley
    -- Created : 23-05-2008
    -- Purpose : API for INTER_ALERT

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
    ) RETURN BOOLEAN;

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
    /* Stores log error messages. */
    g_error VARCHAR2(32000);
    /* Stores the package name. */
    g_package_name VARCHAR2(32);
    /* Message code for an unexpected exception. */
    g_msg_common_m001 CONSTANT VARCHAR2(11) := 'COMMON_M001';

END pk_api_movement;
/
