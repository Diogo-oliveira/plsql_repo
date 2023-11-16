CREATE OR REPLACE PACKAGE BODY pk_wl_ux AS

    k_package_owner VARCHAR2(0050 CHAR);
    k_package_name  VARCHAR2(0050 CHAR);

    FUNCTION generate_ticket
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_wl_machine_name   IN wl_machine.machine_name%TYPE,
        i_id_episode        IN NUMBER,
        i_char_queue        IN VARCHAR2,
        i_number_queue      IN NUMBER,
        o_ticket_number     OUT VARCHAR2,
        o_ticket_print      OUT VARCHAR2,
        o_codification_type OUT VARCHAR2,
        o_printer           OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_bool BOOLEAN;
    
    BEGIN
    
        l_bool := pk_wl_base.generate_ticket(i_lang              => i_lang,
                                               i_prof              => i_prof,
                                               i_wl_machine_name   => i_wl_machine_name,
                                               i_id_episode        => i_id_episode,
                                               i_char_queue        => i_char_queue,
                                               i_number_queue      => i_number_queue,
                                               o_ticket_number     => o_ticket_number,
                                               o_ticket_print      => o_ticket_print,
                                               o_codification_type => o_codification_type,
                                               o_printer           => o_printer,
                                               o_error             => o_error);
    
        IF l_bool
        THEN
            COMMIT;
		else
		    pk_utils.undo_changes;
        END IF;
    
        RETURN l_bool;
    
    END generate_ticket;

    FUNCTION set_item_call_queue
    (
        i_lang          IN language.id_language%TYPE,
        i_id_wl         IN wl_waiting_line.id_wl_waiting_line%TYPE,
        i_id_mach_ped   IN wl_machine.id_wl_machine%TYPE,
        i_prof          IN profissional,
        i_id_mach_dest  IN wl_machine.id_wl_machine%TYPE,
        i_id_episode    IN episode.id_episode%TYPE,
        i_id_room       IN NUMBER,
        o_message_audio OUT VARCHAR2,
        o_sound_file    OUT VARCHAR2,
        o_mac           OUT table_varchar,
        o_msg           OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_bool BOOLEAN;
    
    BEGIN
    
        l_bool := pk_wl_base.set_item_call_queue(i_lang          => i_lang,
                                                    i_id_wl         => i_id_wl,
                                                    i_id_mach_ped   => i_id_mach_ped,
                                                    i_prof          => i_prof,
                                                   -- i_id_mach_dest  => i_id_mach_dest,
                                                    i_id_episode    => i_id_episode,
                                                    i_id_room       => i_id_room,
                                                    o_message_audio => o_message_audio,
                                                    o_sound_file    => o_sound_file,
                                                    o_mac           => o_mac,
                                                    o_msg           => o_msg,
                                                    o_error         => o_error);
    
        IF l_bool
        THEN
            COMMIT;
        END IF;
    
        RETURN l_bool;
    
    END set_item_call_queue;

    FUNCTION set_queues
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_machine IN wl_machine.id_wl_machine%TYPE,
        i_queues  IN table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_bool BOOLEAN;
    
    BEGIN
    
        l_bool := pk_wl_base.set_queues(i_lang      => i_lang,
                                        --i_prof      => i_prof,
                                          i_id_mach   => i_machine,
                                          i_id_queues => i_queues,
                                          o_error     => o_error);
    
        IF l_bool
        THEN
            COMMIT;
        END IF;
    
        RETURN l_bool;
    
    END set_queues;

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
        o_flg_type_queue        OUT VARCHAR2,
        o_section_title_01      OUT VARCHAR2,
        o_section_title_02      OUT VARCHAR2,
        o_section_title_03      OUT VARCHAR2,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN pk_wl_base.get_id_machine(i_lang                  => i_lang,
                                        i_prof                  => i_prof,
                                        i_name_pc               => i_name_pc,
                                        o_id_pc                 => o_id_pc,
                                        o_video                 => o_video,
                                        o_audio                 => o_audio,
                                        o_id_department         => o_id_department,
                                        o_id_institution        => o_id_institution,
                                        o_call_exec_mapping     => o_call_exec_mapping,
                                        o_interface_update_time => o_interface_update_time,
                                        o_software_id           => o_software_id,
                                        o_flg_mach_type         => o_flg_mach_type,
                                        o_max_ticket_shown      => o_max_ticket_shown,
                                        o_kiosk_exists          => o_kiosk_exists,
                                         o_title                 => o_title,
                                         o_header                => o_header,
                                         o_footer                => o_footer,
                                         o_logo                  => o_logo,
                                         o_dt_format             => o_dt_format,
                                         o_hr_format             => o_hr_format,
                                         o_header_bckg_color     => o_header_bckg_color,
                                         o_flg_type_queue        => o_flg_type_queue,
                                         o_section_title_01      => o_section_title_01,
                                         o_section_title_02      => o_section_title_02,
                                         o_section_title_03      => o_section_title_03,
                                        o_error                 => o_error);
    
    END get_id_machine;

    FUNCTION get_next_call
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_machine   IN wl_machine.id_wl_machine%TYPE,
        i_priority  IN NUMBER,
        o_data_wait OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN pk_wl_base.get_next_call(i_lang          => i_lang,
                                      i_id_prof       => i_prof,
                                      i_id_mach       => i_machine,
                                      i_flg_prior_too => i_priority,
                                      o_data_wait     => o_data_wait,
                                      o_error         => o_error);
    
    END get_next_call;

    FUNCTION get_last_called_tickets
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_machine IN NUMBER,
        o_result     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN pk_wl_base.get_last_called_tickets(i_lang       => i_lang,
                                                 i_prof       => i_prof,
                                                 i_id_machine => i_id_machine,
                                                 o_result     => o_result,
                                                 o_error      => o_error);
    
    END get_last_called_tickets;

    FUNCTION get_queues
    (
        i_lang          IN language.id_language%TYPE,
        i_id_prof       IN profissional,
        i_id_department IN department.id_department%TYPE,
        i_id_wl_machine IN wl_machine.id_wl_machine%TYPE,
        o_queues        OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN pk_wl_base.get_queues_admin(i_lang    => i_lang,
                                       i_id_prof       => i_id_prof,
                                           --i_id_department => i_id_department,
                                       i_id_wl_machine => i_id_wl_machine,
                                       o_queues        => o_queues,
                                       o_error         => o_error);
    
    END get_queues;

    FUNCTION get_dept_room
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        o_result OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN pk_wl_base.get_dept_room(i_lang => i_lang, i_prof => i_prof, o_result => o_result, o_error => o_error);
    
    END get_dept_room;

    FUNCTION get_popup_queues
    (
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_mach_name IN VARCHAR2,
        o_result    OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_wl_base.get_popup_queues(i_lang      => i_lang,
                                           i_prof      => i_prof,
                                           i_mach_name => i_mach_name,
                                           o_result    => o_result,
                                           o_error     => o_error);
    
    END get_popup_queues;

    FUNCTION get_next_ticket
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_id_wl_queue IN NUMBER,
        o_char        OUT VARCHAR2,
        o_number      OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_bool BOOLEAN;
    BEGIN
    
        l_bool := pk_wl_base.get_next_ticket(i_lang        => i_lang,
                                             --i_prof        => i_prof,
                                             i_id_wl_queue => i_id_wl_queue,
                                             o_char        => o_char,
                                             o_number      => o_number,
                                             o_error       => o_error);
    
        IF NOT l_bool
        THEN
            COMMIT;
        END IF;
    
        RETURN l_bool;
    
    END get_next_ticket;

    PROCEDURE inicialize IS
    BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(k_package_owner, k_package_name);
    pk_alertlog.log_init(k_package_name);
    END inicialize;

BEGIN
    inicialize();
END pk_wl_ux;
/
