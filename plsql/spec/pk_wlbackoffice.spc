/*-- Last Change Revision: $Rev: 2029052 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:30 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_wlbackoffice IS

    FUNCTION get_rooms_wait_med
    (
        i_lang       IN language.id_language%TYPE,
        o_error      OUT t_error_out,
        o_data_rooms OUT pk_types.cursor_type
        
    ) RETURN BOOLEAN;

    -- RETURNS DEPARTMENT OF TARGET INSTITUTION
    FUNCTION get_department
    (
        i_id_institution IN institution.id_institution%TYPE,
        o_dpt            OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    -- RETURNS CATEGORY OF PROFESSIONALS
    FUNCTION get_category
    (
        o_cat   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    -- RETURNS CLINICAL SERVICE
    FUNCTION get_clinical_service
    (
        i_id_department IN department.id_department%TYPE,
        o_srv           OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    -- RETORNA AS ASSOCIAÇÕES EXISTENTES ENTRE AS QUEUES E AS MAQUINAS ASSOCIADAS A UM DEPARTAMENTO
    FUNCTION get_machine_queue
    (
        i_id_department   IN department.id_department%TYPE,
        o_data_mach_queue OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    -- RETORNA UTILIZADORES + NºSONHO + LOGIN
    FUNCTION get_user
    (
        o_user  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    -- RETORNA MAQUINAS DE DETERMINADO DEPARTAMENTO
    FUNCTION get_machine
    (
        i_id_department IN department.id_department%TYPE,
        o_mac           OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    -- RETORNA PARAMETROS DE SYS_CONFIG
    FUNCTION get_config
    (
        o_cfg   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_machine
    (
        i_mode          IN VARCHAR2,
        i_id_wl_machine IN wl_machine.id_wl_machine%TYPE,
        i_intern_name   IN VARCHAR2,
        i_flg_audio     IN VARCHAR2,
        i_flg_video     IN VARCHAR2,
        i_id_room       IN room.id_room%TYPE,
        i_desc_visual   IN VARCHAR2,
        i_desc_audio    IN VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_queue
    (
        i_mode         IN VARCHAR2,
        i_id_wl_queue  IN NUMBER,
        i_intern_name  IN VARCHAR2,
        i_code_msg     IN VARCHAR2,
        i_char_queue   IN VARCHAR2,
        i_num_queue    IN NUMBER,
        i_color        IN VARCHAR2,
        i_flg_priority IN VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_msg_queue
    (
        i_mode         IN VARCHAR2,
        i_id_queue     IN table_number,
        i_id_mach_dest IN table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_clin_service
    (
        i_mode            IN VARCHAR2,
        i_id_professional IN profissional,
        i_id_clin_serv    IN table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_move_machine
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_mach  IN wl_machine.id_wl_machine%TYPE,
        i_room  IN room.id_room%TYPE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_group_machine
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_mach     IN wl_machine.id_wl_machine%TYPE,
        i_wl_group IN wl_queue_group.id_wl_queue_group%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_waiting_room
    (
        i_mode            IN VARCHAR2,
        i_id_room_consult IN table_number,
        i_id_waiting_room IN table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    pk_prf_active         VARCHAR2(1);
    g_error               VARCHAR2(4000);
    g_language_num        NUMBER;
    g_id_sonho            NUMBER;
    g_id_institution      NUMBER;
    g_flg_available       VARCHAR2(0050);
    g_ret                 BOOLEAN;
    xpl                   VARCHAR2(0050);
    xsp                   VARCHAR2(0050);
    pk_wl_lst_cfg         VARCHAR2(0050);
    pk_wl_id_institution  VARCHAR2(0050);
    pk_wl_category        VARCHAR2(0050);
    pk_wl_lang            VARCHAR2(0050);
    pk_wl_color_queue     VARCHAR2(0050);
    pk_wlcategory         VARCHAR2(0100);
    pk_color_orange       VARCHAR2(0050);
    pk_color_dark_yellow  VARCHAR2(0050);
    pk_color_light_green  VARCHAR2(0050);
    pk_color_green        VARCHAR2(0050);
    pk_color_light_blue   VARCHAR2(0050);
    pk_color_blue         VARCHAR2(0050);
    pk_color_dark_blue    VARCHAR2(0050);
    pk_color_light_violet VARCHAR2(0050);
    pk_color_violet       VARCHAR2(0050);
    pk_color_red          VARCHAR2(0050);
    pk_wl_id_sonho        VARCHAR2(0050);
    pk_queue_code_msg     VARCHAR2(0050);

    g_flg_type_queue_doctor   VARCHAR2(1);
    g_flg_type_queue_nurse    VARCHAR2(1);
    g_flg_type_queue_registar VARCHAR2(1);
    g_flg_type_queue_nur_cons VARCHAR2(1);

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

END pk_wlbackoffice;
/
