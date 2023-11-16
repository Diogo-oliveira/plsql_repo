CREATE OR REPLACE PACKAGE pk_wl_base AS

    --*********************************************************
    FUNCTION set_queues(i_lang IN language.id_language%TYPE,
                        --i_prof      IN profissional,
        i_id_mach   IN wl_machine.id_wl_machine%TYPE,
        i_id_queues IN table_number,
                        o_error     OUT t_error_out) RETURN BOOLEAN;

    --*********************************************************
    FUNCTION get_queues_admin
    (
        i_lang          IN language.id_language%TYPE,
        i_id_prof       IN profissional,
        i_id_wl_machine IN wl_machine.id_wl_machine%TYPE,
        o_queues        OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION generate_ticket
    (
        i_lang              IN NUMBER,
        i_prof              IN profissional,
        i_wl_machine_name   IN VARCHAR2,
        i_id_episode        IN NUMBER,
        i_char_queue        IN VARCHAR2,
        i_number_queue      IN NUMBER,
        o_ticket_number     OUT VARCHAR2,
        o_ticket_print      OUT VARCHAR2,
        o_codification_type OUT VARCHAR2,
        o_printer           OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    --****************************************************
    FUNCTION get_dept_room
    (
        i_lang   IN NUMBER,
        i_prof   IN profissional,
        o_result OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    --***********************************************
    FUNCTION get_id_machine
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_name_pc               IN VARCHAR2,
        o_id_pc                 OUT NUMBER,
        o_video                 OUT VARCHAR2,
        o_audio                 OUT VARCHAR2,
        o_id_department         OUT NUMBER,
        o_id_institution        OUT NUMBER,
        o_call_exec_mapping     OUT VARCHAR2,
        o_interface_update_time OUT NUMBER,
        o_software_id           OUT NUMBER,
        o_flg_mach_type         OUT VARCHAR2,
        o_max_ticket_shown      OUT NUMBER,
        o_kiosk_exists          OUT VARCHAR2,
        o_title                 OUT VARCHAR2,
        o_header                OUT VARCHAR2,
        o_footer                OUT VARCHAR2,
        o_logo                  OUT BLOB,
        o_dt_format             OUT VARCHAR2,
        o_hr_format             OUT VARCHAR2,
        o_header_bckg_color     OUT VARCHAR2,
        o_flg_type_queue        out varchar2,
        o_section_title_01      out varchar2,
        o_section_title_02      out varchar2,
        o_section_title_03      out varchar2,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    --******************************************************
    FUNCTION get_last_called_tickets
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_id_machine IN NUMBER,
        o_result     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_next_call
    (
        i_lang          IN NUMBER,
        i_id_prof       IN profissional,
        i_id_mach       IN NUMBER,
        i_flg_prior_too IN NUMBER,
        o_data_wait     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    --**********************************************************
    FUNCTION set_item_call_queue
    (
        i_lang          IN language.id_language%TYPE,
        i_id_wl         IN wl_waiting_line.id_wl_waiting_line%TYPE,
        i_id_mach_ped   IN wl_machine.id_wl_machine%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_id_room       IN NUMBER,
        o_message_audio OUT VARCHAR2,
        o_sound_file    OUT VARCHAR2,
        o_mac           OUT table_varchar,
        o_msg           OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    --********************************************************
    FUNCTION get_id_software RETURN NUMBER;

    --********************************************************
    FUNCTION get_kiosk_button
    (
        i_lang  IN NUMBER,
        i_prf   IN profissional,
        o_sql   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    --***********************************************
    FUNCTION get_message_with_stat
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional,
        i_id_wl_queue   IN NUMBER,
        --i_id_department IN NUMBER,
        o_message       OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    --******************************************************
    FUNCTION get_timestamp_anytimezone
    (
        i_lang          IN language.id_language%TYPE,
        i_inst          IN institution.id_institution%TYPE,
        o_timestamp     OUT TIMESTAMP WITH TIME ZONE,
        o_timestamp_str OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    --*************************************************
    FUNCTION get_ticket
    (
        i_lang          IN NUMBER,
        i_id_wl_queue   IN NUMBER,
        i_id_mach       IN NUMBER,
        i_id_episode    IN NUMBER,
        i_char_queue    IN VARCHAR2,
        i_number_queue  IN NUMBER,
        i_prof          IN profissional,
        o_ticket_number OUT VARCHAR2,
        o_msg_dept      OUT VARCHAR2,
        o_frase         OUT VARCHAR2,
        o_msg_inst      OUT VARCHAR2,
        o_estimated_time OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    --***********************************
    FUNCTION get_item_call_queue
    (
        i_lang               IN NUMBER,
        i_id_mach            IN NUMBER,
        o_current_call OUT pk_types.cursor_type,
        o_last_called  OUT pk_types.cursor_type,
        o_stats        OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    --**********************************************************************************************/
    FUNCTION get_ad
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_wl_machine IN wl_machine.id_wl_machine%TYPE,
        o_error         OUT t_error_out,
        o_ads           OUT pk_types.cursor_type
    ) RETURN BOOLEAN;

    FUNCTION wr_call
    (
        i_prof       IN profissional,
        i_id_episode IN NUMBER
    ) RETURN VARCHAR2;

    FUNCTION get_queues_kiosk
    (
        i_lang          IN language.id_language%TYPE,
        i_id_wl_machine IN wl_machine.id_wl_machine%TYPE,
        o_queues        OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    -- *********************************************************
    FUNCTION get_item_call_queue_adm
    (
        i_lang         IN NUMBER,
        i_id_mach      IN NUMBER,
        o_current_call OUT pk_types.cursor_type,
        o_last_called  OUT pk_types.cursor_type,
        o_stats        OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_call_cursor
    (
        i_lang  IN NUMBER,
        i_tbl   IN t_tbl_wl_plasma,
        o_sql   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    --***********************************************************
    FUNCTION get_last_calls_adm
    (
        i_lang       IN NUMBER,
        i_id_mach    IN NUMBER,
        o_last_calls OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    -- *********************************************************
    FUNCTION get_current_call_adm
    (
        i_lang         IN NUMBER,
        i_id_mach      IN NUMBER,
        o_current_call OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_stats_adm
    (
        i_lang    IN NUMBER,
        i_id_mach IN NUMBER,
        o_stats   OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    -- *********************************************************
    FUNCTION get_current_call_med
    (
        i_lang         IN NUMBER,
        i_id_mach      IN NUMBER,
        o_current_call OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    --***********************************************************
    FUNCTION get_last_calls_med
    (
        i_lang       IN NUMBER,
        i_id_mach    IN NUMBER,
        o_last_calls OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    --****************************************
    FUNCTION get_stats_med
    (
        i_lang    IN NUMBER,
        i_id_mach IN NUMBER,
        o_stats   OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    -- *********************************************************
    FUNCTION get_item_call_queue_med
    (
        i_lang    IN NUMBER,
        i_id_mach IN NUMBER,
        --i_id_queue     IN NUMBER,
        o_current_call OUT pk_types.cursor_type,
        o_last_called  OUT pk_types.cursor_type,
        o_stats        OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_popup_queues
    (
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_mach_name IN VARCHAR2,
        o_result    OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_next_ticket(i_lang IN NUMBER,
        --i_prof        IN profissional,
        i_id_wl_queue IN NUMBER,
        o_char        OUT VARCHAR2,
        o_number      OUT NUMBER,
                             o_error       OUT t_error_out) RETURN BOOLEAN;

END pk_wl_base;
/