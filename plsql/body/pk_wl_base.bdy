CREATE OR REPLACE PACKAGE BODY pk_wl_base AS

    --k_calc_total_patient    constant varchar2(0050 char):= pk_wl_aux.k_calc_total_patient;
    k_calc_avg_waiting_time CONSTANT VARCHAR2(0050 CHAR) := pk_wl_aux.k_calc_avg_waiting_time;

    k_mach_kiosk CONSTANT VARCHAR2(0020 CHAR) := pk_wl_aux.k_mach_kiosk;
    --k_mach_monitor  constant varchar2(0020 char) := pk_wl_aux.k_mach_monitor;
    --k_mach_user     constant varchar2(0020 char) := pk_wl_aux.k_mach_user;

    g_language_num NUMBER;

    k_package_owner VARCHAR2(0050 CHAR) := 'ALERT';
    k_package_name  VARCHAR2(0050 CHAR) := 'PK_WL_BASE';

    k_yes CONSTANT VARCHAR2(0010 CHAR) := 'Y';
    k_no  CONSTANT VARCHAR2(0010 CHAR) := 'N';

    k_wl_wav_bip_name CONSTANT VARCHAR2(0050 CHAR) := 'WL_WAV_BIP_NAME';
    k_med_msg_01      CONSTANT VARCHAR2(0050 CHAR) := 'MED_MSG_01';
    k_med_msg_02      CONSTANT VARCHAR2(0050 CHAR) := 'MED_MSG_02';
    k_med_msg_tit_01  CONSTANT VARCHAR2(0050 CHAR) := 'MED_MSG_TIT_01';
    k_med_msg_tit_02  CONSTANT VARCHAR2(0050 CHAR) := 'MED_MSG_TIT_02';
    k_sp              CONSTANT VARCHAR2(0010 CHAR) := chr(32);
    k_voice           CONSTANT VARCHAR2(0050 CHAR) := 'V';
    --k_bip             CONSTANT VARCHAR2(0050 CHAR) := 'B';
    --k_t_status        CONSTANT VARCHAR2(0050 CHAR) := 'T';
    --k_wl_titulo       CONSTANT VARCHAR2(0050 CHAR) := 'WL_TITULO';

    k_marker_ticket_nr CONSTANT VARCHAR2(0010 CHAR) := '@01';
    k_marker_num_proc  CONSTANT VARCHAR2(0010 CHAR) := '@02';
    k_marker_date      CONSTANT VARCHAR2(0010 CHAR) := '@03';
    k_marker_time      CONSTANT VARCHAR2(0010 CHAR) := '@04';
    k_err_printer      CONSTANT VARCHAR2(0100 CHAR) := 'WL_PRINTER_ERROR';
    k_err_wrong_number CONSTANT VARCHAR2(0100 CHAR) := 'WL_WRONG_NUMBER';

    --k_msg_hours_kiosk CONSTANT VARCHAR2(0100 CHAR) := 'MSG_HOURS_KIOSK';

    PROCEDURE process_error
    (
        i_lang  IN NUMBER,
        i_code  IN VARCHAR2,
        i_errm  IN VARCHAR2,
        i_msg   IN VARCHAR2,
        i_func  IN VARCHAR2,
        o_error OUT t_error_out
    ) IS
    
    BEGIN
    
        pk_alert_exceptions.process_error(i_lang,
                                          i_code,
                                          i_errm,
                                          i_msg,
                                          k_package_owner,
                                          k_package_name,
                                          i_func,
                                          o_error);
        ROLLBACK;
        pk_alert_exceptions.reset_error_state();
    
    END process_error;

    FUNCTION get_next_call_queue_internal
    (
        i_lang            IN NUMBER,
        i_id_prof         IN profissional,
        i_id_queues       IN table_number,
        i_flg_prior_too   IN NUMBER,
        o_wl_waiting_line OUT wl_waiting_line%ROWTYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    --***************************************
    FUNCTION set_queues(i_lang IN language.id_language%TYPE,
                        --i_prof      IN profissional,
        i_id_mach   IN wl_machine.id_wl_machine%TYPE,
        i_id_queues IN table_number,
                        o_error     OUT t_error_out) RETURN BOOLEAN IS
    
        err_queue_error EXCEPTION;
    
        l_error VARCHAR2(4000);
    
        --***********************************
        FUNCTION l_do_error RETURN BOOLEAN IS
        
        BEGIN
        
            process_error(i_lang  => i_lang,
                          i_code  => SQLCODE,
                          i_errm  => SQLERRM,
                          i_msg   => l_error,
                          i_func  => 'SET_QUEUES',
                          o_error => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
        END l_do_error;
    
    BEGIN
    
        l_error := 'UNSET_QUEUES';
        pk_wl_aux.del_wl_q_machine(i_id_mach);
    
        l_error := 'INS wl_mach_prof_queue';
        pk_wl_aux.ins_wl_q_machine(i_id_mach, i_id_queues);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN err_queue_error THEN
            RETURN l_do_error();
        
        WHEN OTHERS THEN
            RETURN l_do_error();
    END set_queues;

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
    ) RETURN BOOLEAN IS
    
        l_bool     BOOLEAN;
        xinfo      epis_info%ROWTYPE;
        xepis      episode%ROWTYPE;
        xvis       visit%ROWTYPE;
        l_id_wl    NUMBER;
        l_id_queue NUMBER;
    
        l_code        VARCHAR2(4000);
        l_char_number VARCHAR2(0050 CHAR);
        l_proc_num    VARCHAR2(0050 CHAR);
        l_next_number NUMBER;
    
        l_date VARCHAR2(100 CHAR);
        l_time VARCHAR2(100 CHAR);
    
        err_unknown_ticket EXCEPTION;
    
        PROCEDURE l_get_episode_info IS
        BEGIN
        
            xinfo := pk_wl_aux.get_row_epis_info(i_id_episode);
            xepis := pk_wl_aux.get_row_episode(i_id_episode);
            xvis  := pk_wl_aux.get_row_visit(xepis.id_visit);
        
        END l_get_episode_info;
    
        PROCEDURE l_process_date_and_time IS
        BEGIN
            l_date := pk_date_utils.dt_chr_tsz(i_lang, current_timestamp, i_prof.institution, i_prof.software);
            l_time := pk_date_utils.dt_chr_hour_tsz(i_lang, current_timestamp, i_prof);
        END l_process_date_and_time;
    
        PROCEDURE l_format_ticket IS
        BEGIN
        
            l_code          := REPLACE(l_code, k_marker_ticket_nr, l_char_number);
            l_code          := REPLACE(l_code, k_marker_num_proc, l_proc_num);
            l_code          := REPLACE(l_code, k_marker_date, l_date);
            l_code          := REPLACE(l_code, k_marker_time, l_time);
            o_ticket_number := l_char_number;
            o_ticket_print  := l_code;
        
        END l_format_ticket;
    
        FUNCTION l_process_error(i_err_text IN VARCHAR2) RETURN BOOLEAN IS
            l_bool BOOLEAN;
        BEGIN
        
            l_bool              := pk_alert_exceptions.process_error(i_lang        => i_lang,
                                                                     i_sqlcode     => '',
                                                                     i_sqlerrm     => NULL,
                                                                     i_message     => NULL,
                                                                     i_owner       => k_package_owner,
                                                                     i_package     => k_package_name,
                                                                     i_function    => 'GENERATE_TICKET',
                                                                     i_action_type => 'D',
                                                                     i_action_msg  => NULL,
                                                                     i_msg_title   => NULL,
                                                                     i_msg_type    => NULL,
                                                                     o_error       => o_error);
            o_error.ora_sqlerrm := pk_message.get_message(i_lang, i_err_text);
            o_error.err_action  := NULL;
            pk_alert_exceptions.reset_error_state();
            l_bool := l_bool AND FALSE;
        
            RETURN l_bool;
        END l_process_error;
    
    BEGIN
    
        -- medical
        IF i_number_queue IS NOT NULL
        THEN
            l_id_wl := pk_wl_aux.get_wl_row_by_ticket(i_char_queue, i_number_queue);
        
            IF l_id_wl IS NULL
            THEN
                RAISE err_unknown_ticket;
            END IF;
        
            l_char_number := i_char_queue;
            l_next_number := i_number_queue;
        END IF;
    
        l_get_episode_info();
    
        l_bool := pk_patient.get_clin_rec(i_lang       => i_lang,
                                          i_pat        => xvis.id_patient,
                                          i_instit     => i_prof.institution,
                                          i_pat_family => NULL,
                                          o_num        => l_proc_num,
                                          o_error      => o_error);
    
        IF NOT l_bool
        THEN
            l_proc_num := '';
        END IF;
    
        l_id_queue := pk_wl_aux.get_med_queue(i_prof, i_wl_machine_name);
    
        IF l_id_wl IS NULL
        THEN
            pk_wl_aux.get_next_ticket(l_id_queue, l_char_number, l_next_number);
        END IF;
    
        pk_wl_aux.ins_wl_waiting_line(i_lang              => i_lang,
                                      i_prof              => i_prof,
                                      i_char_queue        => l_char_number,
                                      i_number_queue      => l_next_number,
                                      i_id_wl_queue       => l_id_queue,
                                      i_id_episode        => i_id_episode,
                                      i_id_patient        => xvis.id_patient,
                                      i_id_wl_line_parent => l_id_wl);
    
        -- o_codification_type, o_printer, l_code
        pk_wl_aux.get_ticket_info(i_lang              => i_lang,
                                  i_prof              => i_prof,
                                  o_codification_type => o_codification_type,
                                  o_printer           => o_printer,
                                  o_code              => l_code);
    
        l_process_date_and_time();
    
        l_char_number := l_char_number || l_next_number;
    
        pk_wl_aux.update_adt(i_id_episode, l_char_number);
    
        l_format_ticket();
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN err_unknown_ticket THEN
            RETURN l_process_error(k_err_wrong_number);
        WHEN OTHERS THEN
            RETURN l_process_error(k_err_printer);
    END generate_ticket;

    FUNCTION get_dept_room
    (
        i_lang   IN NUMBER,
        i_prof   IN profissional,
        o_result OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        tbl_dept table_number;
    
    BEGIN
    
        -- get main dept
        tbl_dept := pk_wl_aux.get_dept_of_prof(i_prof);
    
        OPEN o_result FOR
            SELECT id_room,
                   id_dept,
                   desc_room || chr(32) || '( ' || desc_department || chr(32) || ')' desc_room,
                   flg_wl,
                   flg_wait,
                   flg_pref
              FROM (SELECT /*+ opt_estimate (table dd rows=1) */
                     d.id_dept,
                     r.id_room,
                     pk_translation.get_translation(i_lang, d.code_department) desc_department,
                     coalesce(pk_translation.get_translation(i_lang, r.code_room), r.desc_room) desc_room,
                     r.flg_wl,
                     r.flg_wait,
                     coalesce(pr.flg_pref, 'N') flg_pref
                      FROM department d
                      JOIN (SELECT column_value id_dept
                             FROM TABLE(tbl_dept)) dd
                        ON dd.id_dept = d.id_dept
                      JOIN room r
                        ON r.id_department = d.id_department
                      LEFT JOIN prof_room pr
                        ON pr.id_room = r.id_room
                       AND pr.id_professional = i_prof.id
                       AND pr.flg_pref = 'Y'
                     WHERE r.flg_wl = 'Y'
                       AND d.id_institution = i_prof.institution
                       AND r.flg_available = 'Y'
                       AND r.flg_wait = 'N') xsql
             ORDER BY desc_department, desc_room;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang  => i_lang,
                          i_code  => SQLCODE,
                          i_errm  => SQLERRM,
                          i_msg   => '',
                          i_func  => 'GET_DEPT_ROOM',
                          o_error => o_error);
            pk_types.open_my_cursor(o_result);
            RETURN FALSE;
    END get_dept_room;

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
    ) RETURN BOOLEAN IS
    
        --l_params table_varchar;
        k_cfg_dt CONSTANT VARCHAR2(0200 CHAR) := 'LOCALE_DATETIME_FORMATS_FULL_DATE';
        k_cfg_hr CONSTANT VARCHAR2(0200 CHAR) := 'LOCALE_DATETIME_FORMATS_SHORT_TIME';
    
        --l_format_dt VARCHAR2(1000 CHAR);
        --l_format_hr VARCHAR2(1000 CHAR);
    
        l_kiosk_exists NUMBER;
        l_error        VARCHAR2(4000);
        --l_bool         BOOLEAN;
    
        PROCEDURE l_get_id_machine_info IS
        BEGIN
        
            SELECT m.id_wl_machine,
                   m.flg_audio_active,
                   m.flg_video_active,
                   d.id_department,
                   d.id_institution,
                   m.flg_mach_type,
                   m.max_ticket_shown,
                   m.title_text,
                   m.header_text,
                   m.footer_text,
                   m.logo_img,
                   m.header_bckg_color,
                   m.flg_type_queue,
                   m.section_title_01,
                   m.section_title_02,
                   m.section_title_03
              INTO o_id_pc,
                   o_audio,
                   o_video,
                   o_id_department,
                   o_id_institution,
                   o_flg_mach_type,
                   o_max_ticket_shown,
                   o_title,
                   o_header,
                   o_footer,
                   o_logo,
                   o_header_bckg_color,
                   o_flg_type_queue,
                   o_section_title_01,
                   o_section_title_02,
                   o_section_title_03
              FROM wl_machine m
              JOIN room r
                ON m.id_room = r.id_room
              JOIN department d
                ON r.id_department = d.id_department
             WHERE upper(machine_name) = upper(i_name_pc);
        
        END l_get_id_machine_info;
    
        --***************************************
        PROCEDURE l_check_kiosk_exists IS
        BEGIN
        
            l_kiosk_exists := pk_wl_aux.count_kiosk_department(i_prof => i_prof, i_machine_name => i_name_pc);
        
            o_kiosk_exists := k_no;
        
            IF l_kiosk_exists > 0
            THEN
                o_kiosk_exists := k_yes;
            END IF;
        
        END l_check_kiosk_exists;
    
        --**********************************
        FUNCTION get_dt_format(i_cfg_table IN VARCHAR2) RETURN VARCHAR2 IS
            l_config t_config;
            l_return VARCHAR2(4000);
            --k_cfg_table CONSTANT VARCHAR2(0200 CHAR) := 'LOCALE_DATETIME_FORMATS_MEDIUM';
        
            tbl_format table_varchar;
        BEGIN
        
            l_config := pk_core_config.get_config(i_area             => i_cfg_table,
                                                  i_prof             => i_prof,
                                                  i_market           => NULL,
                                                  i_category         => NULL,
                                                  i_profile_template => NULL,
                                                  i_prof_dcs         => NULL,
                                                  i_episode_dcs      => NULL);
        
            SELECT field_02
              BULK COLLECT
              INTO tbl_format
              FROM v_config_table ct
             WHERE ct.config_table = i_cfg_table
               AND id_config = l_config.id_config
               AND id_inst_owner = l_config.id_inst_owner;
        
            IF tbl_format.count > 0
            THEN
                l_return := tbl_format(1);
            END IF;
        
            RETURN l_return;
        
        END get_dt_format;
    
    BEGIN
    
        -- get machine info
        l_error := 'GET MACHINE INFO';
        l_get_id_machine_info();
    
        o_software_id := pk_wl_aux.get_id_software();
    
        l_error             := 'GET CALL EXECUTE MAPPING';
        o_call_exec_mapping := pk_sysconfig.get_config('WR_CALL_EXECUTE_MAPPING', i_prof);
    
        l_error                 := 'GET INTERFACE INTERVAL TIME';
        o_interface_update_time := pk_sysconfig.get_config('WL_INTERFACE_INTERVAL_TIME', i_prof);
    
        l_check_kiosk_exists();
    
        o_dt_format := get_dt_format(k_cfg_dt);
        o_hr_format := get_dt_format(k_cfg_hr);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            o_id_pc                 := NULL;
            o_video                 := NULL;
            o_audio                 := NULL;
            o_id_department         := NULL;
            o_id_institution        := NULL;
            o_call_exec_mapping     := NULL;
            o_interface_update_time := NULL;
            o_software_id           := NULL;
            o_flg_mach_type         := NULL;
            o_max_ticket_shown      := NULL;
            o_kiosk_exists          := NULL;
            o_dt_format             := NULL;
            o_hr_format             := NULL;
        
            RETURN TRUE;
        WHEN OTHERS THEN
            process_error(i_lang  => i_lang,
                          i_code  => SQLCODE,
                          i_errm  => SQLERRM,
                          i_msg   => l_error,
                          i_func  => 'GET_ID_MACHINE',
                          o_error => o_error);
            RETURN FALSE;
    END get_id_machine;

    FUNCTION get_last_called_tickets
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_id_machine IN NUMBER,
        o_result     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_num_stack NUMBER;
    
    BEGIN
    
        l_num_stack := pk_wl_aux.get_max_tickets_shown(i_id_machine => i_id_machine);
    
        OPEN o_result FOR
            SELECT t.*
              FROM (SELECT rownum rn, x01.*
                      FROM (SELECT wl.char_queue, wl.number_queue, wl.id_wl_waiting_line, q.color
                              FROM wl_call_queue cq
                              JOIN wl_waiting_line wl
                                ON wl.id_wl_waiting_line = cq.id_wl_waiting_line
                              JOIN wl_queue q
                                ON q.id_wl_queue = wl.id_wl_queue
                             WHERE cq.id_professional = i_prof.id
                               AND cq.flg_status = 'T'
                             ORDER BY cq.dt_gen_sound_file_tstz DESC) x01) t
             WHERE rn <= l_num_stack;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang  => i_lang,
                          i_code  => SQLCODE,
                          i_errm  => SQLERRM,
                          i_msg   => '',
                          i_func  => 'GET_LAST_CALLED_TICKETS',
                          o_error => o_error);
            pk_types.open_my_cursor(o_result);
            RETURN FALSE;
    END get_last_called_tickets;

    FUNCTION get_next_call
    (
        i_lang          IN NUMBER,
        i_id_prof       IN profissional,
        i_id_mach       IN NUMBER,
        i_flg_prior_too IN NUMBER,
        o_data_wait     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_get_prior(i_id_department IN NUMBER) IS
            SELECT id_wl_queue
              FROM wl_queue
             WHERE flg_priority = k_yes
               AND id_department = i_id_department
               AND flg_type_queue = pk_alert_constant.g_wr_wq_type_a;
    
        l_queues              table_number := table_number();
        l_call_queues         table_number := table_number();
        l_wl_waiting_line_row wl_waiting_line%ROWTYPE;
    
        l_its_not_mine_but_aloc PLS_INTEGER;
        l_i                     NUMBER := 1;
        l_can_attend_priority   PLS_INTEGER := 0;
        l_flg_prior_too         PLS_INTEGER;
        l_id_department         NUMBER;
        l_error                 VARCHAR2(4000);
        l_bool                  BOOLEAN;
        err_next_call           EXCEPTION;
    
        --******************************************
        FUNCTION l_chck_others_4_priority_q(i_id_wl_queue IN NUMBER) RETURN NUMBER IS
            l_return NUMBER;
        BEGIN
        
            -- A FILA NAO EST�? ALOCADA A MIM MAS E A OUTROS?
            -- cmf
            SELECT COUNT(*)
              INTO l_return
            --FROM wl_mach_prof_queue
              FROM wl_q_machine qm
              JOIN wl_machine m
                ON qm.id_wl_machine = m.id_wl_machine
              JOIN wl_queue q
                ON q.id_wl_queue = qm.id_wl_queue
             WHERE qm.id_wl_queue = i_id_wl_queue
               AND m.flg_mach_type = 'P'
               AND q.flg_type_queue = 'A'
               AND qm.id_wl_machine != i_id_mach;
        
            RETURN l_return;
        
        END l_chck_others_4_priority_q;
    
        --*************************************
        PROCEDURE set_me_current_queue(i_id_wl_queue IN NUMBER) IS
        BEGIN
            l_call_queues.extend;
            l_call_queues(l_i) := i_id_wl_queue;
            l_i := l_i + 1;
        END set_me_current_queue;
    
        --***********************************
        PROCEDURE l_set_me_unassigned_queue(i_id_wl_queue IN NUMBER) IS
        BEGIN
        
            l_error                 := 'PRIORITY QUEUE ' || i_id_wl_queue || ' IS NOT MINE.';
            l_its_not_mine_but_aloc := l_chck_others_4_priority_q(i_id_wl_queue);
        
            IF l_its_not_mine_but_aloc = 0
            THEN
                set_me_current_queue(i_id_wl_queue);
            END IF;
        
        END l_set_me_unassigned_queue;
    
        --*******************************
        PROCEDURE l_get_next_call_q_internal IS
            l_bool BOOLEAN;
        BEGIN
        
            l_bool := get_next_call_queue_internal(i_lang,
                                                   i_id_prof,
                                                   l_call_queues,
                                                   l_flg_prior_too,
                                                   l_wl_waiting_line_row,
                                                   o_error);
        
            IF NOT l_bool
            THEN
                RAISE err_next_call;
            END IF;
        
        END l_get_next_call_q_internal;
    
    BEGIN
    
        l_error         := 'CALC AVAILABLE PRIORITY QUEUES';
        l_flg_prior_too := coalesce(i_flg_prior_too, 1);
    
        -- Counts only with the same group
        IF l_flg_prior_too = 1
        THEN
            l_queues              := pk_wl_aux.priority_q_allocated(i_id_mach);
            l_can_attend_priority := l_queues.count;
        END IF;
    
        -- se nalguma das minhas filas posso atender os priors
        IF l_can_attend_priority > 0
        THEN
        
            l_error         := 'GET WAITING_LINE FROM PRIORITY QUEUES';
            l_i             := 1;
            l_id_department := pk_wl_aux.get_dept_from_machine(i_id_mach);
        
            <<lup_thru_tuplo>>
            FOR tuplo_prior IN c_get_prior(l_id_department)
            LOOP
            
                l_error := 'IS PRIORITY QUEUE ' || tuplo_prior.id_wl_queue || 'MINE?';
                IF tuplo_prior.id_wl_queue MEMBER OF l_queues
                THEN
                    -- a fila prioritaria está alocada a mim
                    set_me_current_queue(tuplo_prior.id_wl_queue);
                ELSE
                    l_set_me_unassigned_queue(tuplo_prior.id_wl_queue);
                END IF;
            
            END LOOP lup_thru_tuplo;
        END IF;
    
        l_error := 'GET PRIORITY WL_WAITING_LINE';
        l_get_next_call_q_internal();
    
        IF l_wl_waiting_line_row.id_wl_waiting_line IS NULL
        THEN
        
            l_error       := 'GET WL_WAITING_LINE FROM MY QUEUES';
            l_call_queues := pk_wl_aux.get_allocated_queues(i_id_mach);
            --l_call_queues := pk_wl_aux.get_wl_queue(i_id_prof, i_id_mach);
        
            l_error := 'GET WL_WAITING_LINE';
            l_get_next_call_q_internal();
        
        END IF;
    
        IF l_wl_waiting_line_row.id_wl_waiting_line IS NOT NULL
        THEN
            l_error := 'CALC WL_WAITING_LINE INFO';
            OPEN o_data_wait FOR
                SELECT l_wl_waiting_line_row.char_queue char_queue,
                       l_wl_waiting_line_row.number_queue ticket_number,
                       color color_queue,
                       pk_translation.get_translation(i_lang, code_name_queue) name_queue,
                       l_wl_waiting_line_row.id_wl_waiting_line id_wait
                  FROM wl_queue
                 WHERE id_wl_queue = l_wl_waiting_line_row.id_wl_queue;
        ELSE
            pk_types.open_my_cursor(o_data_wait);
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN err_next_call THEN
            pk_types.open_my_cursor(o_data_wait);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            process_error(i_lang  => i_lang,
                          i_code  => SQLCODE,
                          i_errm  => SQLERRM,
                          i_msg   => '',
                          i_func  => 'GET_NEXT_CALL-GENERIC',
                          o_error => o_error);
        
            pk_utils.undo_changes();
            RETURN FALSE;
    END get_next_call;

    FUNCTION get_next_call_queue_internal
    (
        i_lang            IN NUMBER,
        i_id_prof         IN profissional,
        i_id_queues       IN table_number,
        i_flg_prior_too   IN NUMBER,
        o_wl_waiting_line OUT wl_waiting_line%ROWTYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_wl_waiting_line_row wl_waiting_line%ROWTYPE;
    
        l_bool BOOLEAN;
    
    BEGIN
    
        l_bool := (i_id_queues IS NOT NULL) AND (i_id_queues.count > 0);
        IF l_bool
        THEN
        
            l_wl_waiting_line_row := pk_wl_aux.get_wl_line_row(i_flg_prior_too, i_id_queues);
        
            IF l_wl_waiting_line_row.id_wl_waiting_line IS NOT NULL
            THEN
                pk_wl_aux.set_wl_line_executed(i_lang, i_id_prof, l_wl_waiting_line_row.id_wl_waiting_line);
            
                o_wl_waiting_line := l_wl_waiting_line_row;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang  => i_lang,
                          i_code  => SQLCODE,
                          i_errm  => SQLERRM,
                          i_msg   => '',
                          i_func  => 'GET_NEXT_CALL_QUEUE_INTERNAL',
                          o_error => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_next_call_queue_internal;

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
    ) RETURN BOOLEAN IS
    
        l_ticket_par_number wl_waiting_line.number_queue%TYPE;
        l_ticket_par_char   wl_queue.char_queue%TYPE;
        l_message           wl_call_queue.message%TYPE;
        l_sound_file        wl_call_queue.sound_file%TYPE;
        l_sound_beep        wl_call_queue.sound_file%TYPE;
        l_nome_pat          patient.name%TYPE;
        l_sexo_pat          patient.gender%TYPE;
        l_flg_status        wl_waiting_line.flg_wl_status%TYPE;
    
        l_id_pat        NUMBER;
        l_id_queue      NUMBER;
        l_id_call_queue NUMBER;
        l_lang          NUMBER;
        l_titulo_mens   NUMBER;
        l_opcao         NUMBER := 0;
        i               NUMBER := 0;
        l_flg_type      VARCHAR2(0010 CHAR);
    
        l_id_wl NUMBER;
    
        l_ticket_number VARCHAR2(0050);
        xtmp            VARCHAR2(0100);
    
        l_queue_dep       department.id_department%TYPE;
        l_id_mach_ped     wl_machine.id_wl_machine%TYPE;
        l_type_queue      wl_queue.flg_type_queue%TYPE;
        l_cfg_ticket_type sys_config.id_sys_config%TYPE;
    
        l_bool             BOOLEAN;
        l_wl_nur_cons_type VARCHAR2(4000);
    
        CURSOR c_mach_dest
        (
            x_id_queue NUMBER,
            x_opcao    NUMBER
        ) IS
            SELECT m_plasma.id_wl_machine id_wl_machine,
                   m_plasma.flg_audio_active,
                   pk_translation.get_translation(l_lang, m_plasma.cod_desc_machine_audio) cod_desc_machine_audio,
                   m_plasma.machine_name,
                   l_id_mach_ped id_wl_machine_dest
              FROM wl_q_machine qm
              JOIN wl_machine m_plasma
                ON m_plasma.id_wl_machine = qm.id_wl_machine
              JOIN wl_queue q
                ON q.id_wl_queue = qm.id_wl_queue
             WHERE qm.id_wl_queue = x_id_queue
               AND m_plasma.flg_mach_type = 'M'
               AND m_plasma.flg_video_active = pk_alert_constant.get_yes
               AND q.flg_type_queue IN ('A', 'C')
            UNION
            -- med
            SELECT mw.id_wl_machine,
                   mw.flg_audio_active,
                   pk_translation.get_translation(l_lang, rw.code_room) cod_desc_machine_audio,
                   mc.machine_name,
                   mc.id_wl_machine id_wl_machine_dest --máquina à qual se deve dirigir; corresponde à maquina do prof que fez o pedido.
              FROM wl_waiting_room wr
              JOIN wl_machine mc
                ON mc.id_room = wr.id_room_consult
              JOIN room rw
                ON rw.id_room = mc.id_room
              JOIN wl_machine mw
                ON mw.id_room = wr.id_room_wait
             WHERE mc.id_wl_machine = l_id_mach_ped
               AND 1 = x_opcao;
    
        PROCEDURE l_get_wl_info IS
        BEGIN
        
            SELECT wl.char_queue, wl.number_queue, wl.id_wl_queue, wlq.id_department, wlq.flg_type_queue, wl.id_patient
              INTO l_ticket_par_char, l_ticket_par_number, l_id_queue, l_queue_dep, l_type_queue, l_id_pat
              FROM wl_waiting_line wl
              JOIN wl_queue wlq
                ON wlq.id_wl_queue = wl.id_wl_queue
              JOIN wl_machine wlm
                ON wlq.id_wl_queue_group = wlm.id_wl_queue_group
              JOIN wl_queue_group qg
                ON qg.id_wl_queue_group = wlq.id_wl_queue_group
             WHERE id_wl_waiting_line = l_id_wl
               AND wlm.id_wl_machine = l_id_mach_ped
               AND qg.id_institution = i_prof.institution
            --AND wl.dt_begin_tstz >= current_timestamp - numtodsinterval(24, 'HOUR')
            ;
        
        END l_get_wl_info;
    
        PROCEDURE l_get_id_mach_ped IS
        BEGIN
        
            l_id_mach_ped := i_id_mach_ped;
        
            IF i_id_episode IS NOT NULL
            THEN
                l_id_wl := pk_wl_aux.get_wl_by_episode(i_id_episode);
            
                -- ADM doesnt send episode nor room
                IF i_id_room IS NULL
                THEN
                    l_id_mach_ped := pk_wl_aux.get_mach_by_id_wl(i_prof, l_id_wl);
                ELSE
                    l_id_mach_ped := pk_wl_aux.get_mach_by_room(i_id_room);
                END IF;
            END IF;
        
        END l_get_id_mach_ped;
    
    BEGIN
    
        l_cfg_ticket_type  := pk_sysconfig.get_config('WL_CALL_BY_NAME_OR_NUMBER', i_prof.institution, i_prof.software);
        l_wl_nur_cons_type := pk_sysconfig.get_config('WL_NUR_CONS_TYPE', i_prof.institution, i_prof.software);
    
        l_lang := i_lang;
        o_mac  := table_varchar(50);
        o_msg  := table_number(50);
    
        l_id_wl := i_id_wl;
    
        l_get_id_mach_ped();
    
        -- get needed info from waiting line queue
        l_get_wl_info();
    
        -- Building message
        -- Queue is not a system queue, if it was message would be diferente
        l_bool := l_id_pat IS NULL;
        l_bool := l_bool AND (coalesce(l_wl_nur_cons_type, 1) = 2);
        l_bool := l_bool AND (l_type_queue = pk_alert_constant.g_wr_wq_type_c);
        l_bool := l_bool OR (l_type_queue = pk_alert_constant.g_wr_wq_type_a);
    
        IF l_bool
        THEN
        
            -- build ticket number
            l_ticket_number := l_ticket_par_char || to_char(l_ticket_par_number, '000');
            l_message       := l_ticket_number || '.' || k_sp;
        
            l_opcao := 0;
            l_flg_type := 'A'; -- admin call
        ELSE
            l_flg_type := 'M'; -- med call
            IF l_cfg_ticket_type = 'NAME'
            THEN
            
                pk_wl_aux.get_pat_info(i_lang       => i_lang,
                                       i_prof       => i_prof,
                                       i_id_wl      => l_id_wl,
                                       o_nome_pat   => l_nome_pat,
                                       o_sexo_pat   => l_sexo_pat,
                                       o_flg_status => l_flg_status);
            
                -- build sentence for doctor's waiting room
                l_message := pk_message.get_message(i_lang => l_lang, i_code_mess => k_med_msg_01);
            
                l_titulo_mens := pk_sysconfig.get_config(i_code_cf => 'WL_ID_SONHO', i_prof => i_prof);
            
                IF l_titulo_mens = 1
                THEN
                
                    xtmp := k_med_msg_tit_02;
                    IF l_sexo_pat = 'M'
                    THEN
                        xtmp := k_med_msg_tit_01;
                    END IF;
                
                    l_message := l_message || pk_message.get_message(i_lang => l_lang, i_code_mess => xtmp);
                
                END IF;
            ELSE
                l_nome_pat := pk_wl_aux.get_ticket_from_wl(l_id_wl);
            END IF;
        
            l_message := l_message || l_nome_pat || '.';
            l_message := l_message || k_sp || pk_message.get_message(i_lang => l_lang, i_code_mess => k_med_msg_02);
            l_message := l_message || chr(32);
            l_opcao   := 1;
        
            --Also, do not forget to update the ticket status
            IF l_flg_status = pk_alert_constant.g_wr_wl_status_e
            THEN
                pk_wl_aux.upd_wl_waiting_line(l_id_wl);
            END IF;
        
        END IF;
    
        -- insercao das mensagens a chamar por cada maquina que fala
        -- for tuplo in c_mach_dest(i_id_machine, i_id_prof.id, l_opcao) loop
        l_sound_beep := pk_sysconfig.get_config(i_code_cf => k_wl_wav_bip_name, i_prof => i_prof);
    
        <<lup_thru_mach_dest>>
        FOR tuplo IN c_mach_dest(l_id_queue, l_opcao)
        LOOP
        
            pk_wl_aux.ins_wl_call_queue(i_prof          => i_prof,
                                        i_message       => l_message || tuplo.cod_desc_machine_audio,
                                        i_machine       => tuplo.id_wl_machine,
                                        i_machine_dest  => tuplo.id_wl_machine_dest,
                                        i_id_wl         => l_id_wl,
                                        i_flg_audio     => tuplo.flg_audio_active,
                                        i_beep          => l_sound_beep,
                                        i_flg_type      => l_flg_type,
                                        o_id_call_queue => l_id_call_queue,
                                        io_sound_file   => l_sound_file);
        
            i := i + 1; -- começa sempre em 1
        
            IF i > 1
            THEN
                o_mac.extend;
                o_msg.extend;
            ELSE
                o_message_audio := l_message || tuplo.cod_desc_machine_audio;
                o_sound_file    := NULL;
            END IF;
        
            IF ((o_sound_file IS NULL) AND (tuplo.flg_audio_active = k_voice))
            THEN
                o_sound_file := l_sound_file;
            END IF;
        
            o_mac(i) := tuplo.machine_name;
            o_msg(i) := l_id_call_queue;
        
        END LOOP lup_thru_mach_dest;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang  => i_lang,
                          i_code  => SQLCODE,
                          i_errm  => SQLERRM,
                          i_msg   => '',
                          i_func  => 'SET_ITEM_CALL_QUEUE',
                          o_error => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_item_call_queue;

    FUNCTION get_id_software RETURN NUMBER IS
    
    BEGIN
    
        RETURN pk_wl_aux.get_id_software();
    
    END get_id_software;

    FUNCTION get_kiosk_button
    (
        i_lang  IN NUMBER,
        i_prf   IN profissional,
        o_sql   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_lang NUMBER;
    
    BEGIN
    
        l_lang := pk_wl_aux.get_lang(i_lang, i_prf);
    
        g_language_num := l_lang;
    
        OPEN o_sql FOR
            SELECT code_message, desc_message, flg_type, img_name
              FROM sys_message
             WHERE code_message IN ('WL_KIOSK_BACK_BUTTON', 'WL_KIOSK_PRINT_BUTTON')
               AND id_software = i_prf.software
               AND id_language = g_language_num;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            process_error(i_lang  => i_lang,
                          i_code  => SQLCODE,
                          i_errm  => SQLERRM,
                          i_msg   => '',
                          i_func  => 'GET_KIOSK_BUTTON',
                          o_error => o_error);
            pk_types.open_my_cursor(o_sql);
            RETURN FALSE;
    END get_kiosk_button;

    FUNCTION get_item_call_queue
    (
        i_lang               IN NUMBER,
        i_id_mach            IN NUMBER,
        o_current_call OUT pk_types.cursor_type,
        o_last_called  OUT pk_types.cursor_type,
        o_stats        OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_queue VARCHAR2(0100 CHAR);
        k_q_type_adm CONSTANT VARCHAR2(0010 CHAR) := 'A';
        --k_q_type_med constant varchar2(0010 char) := 'M';
        
        BEGIN
        
        l_flg_queue := pk_wl_aux.get_mach_queue_type(i_id_mach);
        
        IF l_flg_queue = k_q_type_adm
            THEN
            RETURN pk_wl_base.get_item_call_queue_adm(i_lang         => i_lang,
                                                      i_id_mach      => i_id_mach,
                                                      o_current_call => o_current_call,
                                                      o_last_called  => o_last_called,
                                                      o_stats        => o_stats,
                                                      o_error        => o_error);
            ELSE
            
            RETURN pk_wl_base.get_item_call_queue_med(i_lang    => i_lang,
                                                      i_id_mach => i_id_mach,
                                                      --i_id_queue    => o_current_call,
                                                      o_current_call => o_current_call,
                                                      o_last_called  => o_last_called,
                                                      o_stats        => o_stats,
                                                      o_error        => o_error);
    
        END IF;
    
    END get_item_call_queue;

    FUNCTION get_message_with_stat
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional,
        i_id_wl_queue   IN NUMBER,
        --i_id_department IN NUMBER,
        o_message       OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_msg                  sys_message.desc_message%TYPE;
        l_prof                 profissional := profissional(0, 0, 0);
        l_people_ahead         PLS_INTEGER;
        l_tempo_espera         PLS_INTEGER;
        --l_tempo_espera_total   PLS_INTEGER;
        --l_tempo_espera_total_v VARCHAR2(0200);
        --xhours                 VARCHAR2(0050);
        l_error                VARCHAR2(4000);
        --k_tempo_espera_lim CONSTANT NUMBER := 120;
        l_institution NUMBER;
    
    BEGIN
    
        l_error := 'SET VARIABLES';
        l_prof  := i_prof;
    
        IF nvl(l_prof.institution, 0) = 0
        THEN
            l_institution := pk_wl_aux.get_inst_from_queue(i_id_wl_queue);
            l_prof        := profissional(i_prof.id, l_institution, i_prof.software);
        END IF;
    
        -- get statistics
        --l_people_ahead := pk_wl_aux.get_people_ahead(i_id_wl_queue, l_prof);
        l_people_ahead := pk_wl_aux.get_people_ahead(i_id_wl_queue => i_id_wl_queue, i_prof => l_prof);
        l_tempo_espera := pk_wl_aux.get_avg_waiting_time(k_calc_avg_waiting_time, l_prof, i_id_wl_queue);
    
        l_msg := pk_wl_aux.format_avg_waiting_time(i_lang, l_people_ahead, l_tempo_espera);
    
        o_message := l_msg;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang  => i_lang,
                          i_code  => SQLCODE,
                          i_errm  => SQLERRM,
                          i_msg   => l_error,
                          i_func  => 'GET_QUEUE_STAT',
                          o_error => o_error);
            RETURN FALSE;
    END get_message_with_stat;

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
    ) RETURN BOOLEAN IS
    
        next_number wl_queue.num_queue%TYPE;
        l_prof      profissional;
    
        l_code_message_dept department.code_department%TYPE;
        l_id_inst           department.id_institution%TYPE;
        l_code_message_inst institution.code_institution%TYPE;
    
        l_error      VARCHAR2(4000);
        l_id_patient NUMBER;
        l_people     NUMBER;
        l_time       NUMBER;
    
        --l_cfg_ticket_system sys_config.value%TYPE;
    
        tbl_waiting_line table_number;
        xwtl             wl_waiting_line%ROWTYPE;
        l_id_parent      NUMBER;
    
        FUNCTION l_get_waiting_line_rec(i_id_episode IN NUMBER) RETURN table_number IS
        
            tbl_id table_number;
        
        BEGIN
        
            SELECT id_wl_waiting_line
              BULK COLLECT
              INTO tbl_id
              FROM wl_waiting_line
             WHERE id_episode = i_id_episode
             ORDER BY dt_begin_tstz DESC;
        
            RETURN tbl_id;
        
        END l_get_waiting_line_rec;
    
    BEGIN
    
        l_error := 'GET CONFIG INFO';
        pk_alertlog.log_debug(l_error, k_package_name);
        o_frase             := pk_message.get_message(i_lang, 'WL_TICKET_MESSAGE_M001');
    
        IF nvl(i_prof.institution, 0) = 0
        THEN
            l_prof := profissional(0, pk_wl_aux.get_inst_from_mach(i_id_mach), i_prof.software);
        END IF;
    
        --l_cfg_ticket_system := pk_sysconfig.get_config(i_code_cf => 'ADT_ADMISSION_WL_TICKET_NUMBER', i_prof => l_prof);
    
        l_error := 'GET MACHINE, INSTITUTION AND DEPARTMENT INFO';
        pk_alertlog.log_debug(l_error, k_package_name);
    
        --        IF l_cfg_ticket_system = pk_alert_constant.g_no THEN
            SELECT d.code_department,
                   d.id_institution,
                   pk_translation.get_translation(i_lang, wm.cod_desc_machine_visual),
                   i.code_institution,
                   i.abbreviation
              INTO l_code_message_dept, l_id_inst, o_msg_dept, l_code_message_inst, o_msg_inst
              FROM wl_machine wm
              JOIN room r
                ON wm.id_room = r.id_room
              JOIN department d
                ON r.id_department = d.id_department
              JOIN institution i
                ON d.id_institution = i.id_institution
             WHERE wm.id_wl_machine = i_id_mach;
        --        END IF;
    
        tbl_waiting_line := l_get_waiting_line_rec(i_id_episode => i_id_episode);
    
        IF tbl_waiting_line.count = 0
        THEN
            pk_wl_aux.get_next_ticket(i_id_wl_queue, o_ticket_number, next_number);
        
            l_error := 'INSERT RECORD TO BE CALLED';
            pk_alertlog.log_debug(l_error, k_package_name);
            l_id_parent  := pk_wl_aux.get_wl_waiting_line(i_char_queue, i_number_queue);
            l_id_patient := pk_wl_aux.get_pat_by_episode(i_id_episode);
        
            pk_wl_aux.ins_wl_waiting_line(i_lang              => i_lang,
                                          i_prof              => i_prof,
                                          i_char_queue        => o_ticket_number,
                                          i_number_queue      => next_number,
                                          i_id_wl_queue       => i_id_wl_queue,
                                          i_id_episode        => i_id_episode,
                                          i_id_patient        => l_id_patient,
                                          i_id_wl_line_parent => l_id_parent);
        
            o_ticket_number := o_ticket_number || next_number;
        
        ELSE
            xwtl            := pk_wl_aux.get_waiting_line_row(tbl_waiting_line(1));
            o_ticket_number := xwtl.char_queue || xwtl.number_queue;
        END IF;
    
        l_people         := pk_wl_aux.get_people_ahead(i_id_wl_queue => i_id_wl_queue, i_prof => l_prof);
        l_time           := pk_wl_aux.get_avg_waiting_time(k_calc_avg_waiting_time, l_prof, i_id_wl_queue);
        o_estimated_time := pk_wl_aux.format_avg_waiting_time(i_lang   => i_lang,
                                                              i_people => l_people,
                                                              i_time   => l_time,
                                                              i_msg    => '#02');
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang  => i_lang,
                          i_code  => SQLCODE,
                          i_errm  => SQLERRM,
                          i_msg   => l_error,
                          i_func  => 'GET_TICKET',
                          o_error => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_ticket;

    FUNCTION get_timestamp_anytimezone
    (
        i_lang          IN language.id_language%TYPE,
        i_inst          IN institution.id_institution%TYPE,
        o_timestamp     OUT TIMESTAMP WITH TIME ZONE,
        o_timestamp_str OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        o_timestamp     := pk_date_utils.get_timestamp_insttimezone(i_lang => i_lang, i_inst => i_inst);
        o_timestamp_str := pk_date_utils.date_send_tsz(i_lang => i_lang,
                                                       i_date => o_timestamp,
                                                       i_prof => profissional(0, i_inst, 0));
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang  => i_lang,
                          i_code  => SQLCODE,
                          i_errm  => SQLERRM,
                          i_msg   => '',
                          i_func  => 'GET_TIMESTAMP_ANYTIMEZONE',
                          o_error => o_error);
            RETURN FALSE;
    END get_timestamp_anytimezone;

    FUNCTION get_ad
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_wl_machine IN wl_machine.id_wl_machine%TYPE,
        o_error         OUT t_error_out,
        o_ads           OUT pk_types.cursor_type
    ) RETURN BOOLEAN IS
    
        l_lang language.id_language%TYPE;
    BEGIN
    
        IF i_lang IS NULL
        THEN
            l_lang := pk_sysconfig.get_config('WL_LANG', i_prof);
        ELSE
            l_lang := i_lang;
        END IF;
    
        OPEN o_ads FOR
            SELECT wt.file_name
              FROM wl_machine wm
              JOIN room r
                ON r.id_room = wm.id_room
              JOIN wl_topics wt
                ON wt.id_department = r.id_department
               AND wm.id_wl_queue_group = wm.id_wl_queue_group
             WHERE wt.flg_active = pk_alert_constant.g_yes
               AND wm.id_wl_machine = i_id_wl_machine
               AND wt.id_language = l_lang
             ORDER BY wt.rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang  => i_lang,
                          i_code  => SQLCODE,
                          i_errm  => SQLERRM,
                          i_msg   => '',
                          i_func  => 'GET_AD',
                          o_error => o_error);
        
            RETURN FALSE;
    END get_ad;

    FUNCTION wr_call
    (
        i_prof       IN profissional,
        i_id_episode IN NUMBER
    ) RETURN VARCHAR2 IS
    
        l_return                 VARCHAR2(0050 CHAR) := k_no;
        l_bool                   BOOLEAN;
        xepis                    episode%ROWTYPE;
        l_waiting_room_available VARCHAR2(0010 CHAR);
    
    BEGIN
    
        l_waiting_room_available := pk_sysconfig.get_config('WL_WAITING_ROOM_AVAILABLE', i_prof);
    
        IF l_waiting_room_available = k_yes
        THEN
            IF i_id_episode IS NOT NULL
            THEN
                xepis := pk_wl_aux.get_row_episode(i_id_episode);
            
                l_bool := xepis.flg_status = 'A' AND xepis.flg_ehr = 'N';
            
                IF l_bool
                THEN
                
                    l_return := k_yes;
                
                END IF;
            END IF;
        END IF;
    
        RETURN l_return;
    
    END wr_call;

    FUNCTION get_queues_admin
    (
        i_lang          IN language.id_language%TYPE,
        i_id_prof       IN profissional,
        i_id_wl_machine IN wl_machine.id_wl_machine%TYPE,
        o_queues        OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        --l_prof profissional;
        --l_queues      table_number := table_number();
        --l_queue_types table_varchar := table_varchar();
        --l_bool        BOOLEAN;
    
        err_set_queues EXCEPTION;
        l_error VARCHAR2(4000);
    
        PROCEDURE l_process_error(i_func IN VARCHAR2) IS
        BEGIN
        
            process_error(i_lang  => i_lang,
                          i_code  => SQLCODE,
                          i_errm  => SQLERRM,
                          i_msg   => l_error,
                          i_func  => i_func,
                          o_error => o_error);
        
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_queues);
        
        END l_process_error;
    
    BEGIN
    
        --l_prof        := profissional(0, 0, 0);
        --l_queue_types := table_varchar('A', 'C');
    
        l_error := 'OPEN o_queues CURSOR';
        OPEN o_queues FOR
            SELECT t.id_wl_queue,
                   t.inter_name_queue,
                   t.char_queue,
                   t.num_queue,
                   t.flg_visible,
                   t.flg_type_queue,
                   t.flg_priority,
                   t.foreground_color,
                   t.color,
                   t.code_msg,
                   t.total_ahead,
                   t.flg_allocated
              FROM (pk_wl_aux.get_tbl_queue_admin(i_lang, i_id_prof, i_id_wl_machine)) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN err_set_queues THEN
            l_process_error(i_func => 'SET_QUEUES');
            RETURN FALSE;
        
        WHEN OTHERS THEN
            l_process_error(i_func => 'GET_QUEUES_ADMIN');
            RETURN FALSE;
    END get_queues_admin;

    FUNCTION get_queues_kiosk
    (
        i_lang          IN language.id_language%TYPE,
        i_id_wl_machine IN wl_machine.id_wl_machine%TYPE,
        o_queues        OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        --l_prof        profissional;
        l_queue_types table_varchar := table_varchar();
        l_error       VARCHAR2(4000);
    
        PROCEDURE l_process_error(i_func IN VARCHAR2) IS
        BEGIN
        
            process_error(i_lang  => i_lang,
                          i_code  => SQLCODE,
                          i_errm  => SQLERRM,
                          i_msg   => l_error,
                          i_func  => i_func,
                          o_error => o_error);
        
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_queues);
        
        END l_process_error;
    
    BEGIN
    
        --l_prof        := profissional(0, 0, 0);
        l_queue_types := table_varchar('A', 'C');
    
        l_error := 'OPEN o_queues CURSOR';
        OPEN o_queues FOR
            SELECT sys_connect_by_path(xtmp.id_wl_queue, '|') xpath,
                   xtmp.id_wl_queue,
                   xtmp.id_parent,
                   pk_translation.get_translation(i_lang, xtmp.code_name_queue) inter_name_queue,
                   xtmp.char_queue,
                   xtmp.num_queue,
                   xtmp.flg_visible,
                   xtmp.flg_type_queue,
                   xtmp.flg_priority,
                   xtmp.foreground_color,
                   xtmp.color,
                   pk_translation.get_translation(i_lang, xtmp.code_msg) code_msg
              FROM (SELECT q.id_wl_queue,
                           q.id_parent,
                           q.code_name_queue,
                           q.char_queue,
                           q.num_queue,
                           q.flg_visible,
                           q.flg_type_queue,
                           q.flg_priority,
                           q.foreground_color,
                           q.color,
                           q.code_msg,
                           qm.order_rank
                      FROM wl_queue q
                      JOIN wl_q_machine qm
                        ON qm.id_wl_queue = q.id_wl_queue
                      JOIN wl_machine m
                        ON m.id_wl_machine = qm.id_wl_machine
                     WHERE q.flg_visible = k_yes
                       AND m.flg_mach_type = k_mach_kiosk
                       AND m.id_wl_machine = i_id_wl_machine
                       AND q.flg_type_queue IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                 column_value
                                                  FROM TABLE(l_queue_types) t)) xtmp
            CONNECT BY PRIOR xtmp.id_wl_queue = xtmp.id_parent
             START WITH xtmp.id_parent IS NULL
             ORDER SIBLINGS BY xtmp.order_rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            l_process_error(i_func => 'GET_QUEUES');
            RETURN FALSE;
    END get_queues_kiosk;

    -- *********************************************************
    FUNCTION get_item_call_queue_adm
    (
        i_lang         IN NUMBER,
        i_id_mach      IN NUMBER,
        o_current_call OUT pk_types.cursor_type,
        o_last_called  OUT pk_types.cursor_type,
        o_stats        OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_bool BOOLEAN;
        err_processing EXCEPTION;
    
    BEGIN
    
        --************************************
        l_bool := get_last_calls_adm(i_lang       => i_lang,
                                     i_id_mach    => i_id_mach,
                                     o_last_calls => o_last_called,
                                     o_error      => o_error);
        IF NOT l_bool
        THEN
            RAISE err_processing;
        END IF;
    
        --***********************************
        l_bool := get_stats_adm(i_lang => i_lang, i_id_mach => i_id_mach, o_stats => o_stats, o_error => o_error);
        IF NOT l_bool
        THEN
            RAISE err_processing;
        END IF;
    
        --***********************************
        l_bool := get_current_call_adm(i_lang         => i_lang,
                                       i_id_mach      => i_id_mach,
                                       o_current_call => o_current_call,
                                       o_error        => o_error);
        IF NOT l_bool
        THEN
            RAISE err_processing;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN err_processing THEN
            pk_types.open_my_cursor(o_current_call);
            pk_types.open_my_cursor(o_last_called);
            pk_types.open_my_cursor(o_stats);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            process_error(i_lang  => i_lang,
                          i_code  => SQLCODE,
                          i_errm  => SQLERRM,
                          i_msg   => '',
                          i_func  => 'GET_ITEM_CALL_QUEUE_ADM',
                          o_error => o_error);
            pk_types.open_my_cursor(o_current_call);
            pk_types.open_my_cursor(o_last_called);
            RETURN FALSE;
    END get_item_call_queue_adm;

    FUNCTION get_call_cursor
    (
        i_lang  IN NUMBER,
        i_tbl   IN t_tbl_wl_plasma,
        o_sql   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF i_tbl.count > 0
        THEN
            OPEN o_sql FOR
                SELECT t.message_audio,
                       t.message_sound_file,
                       t.flg_type,
                       t.id_call_queue,
                       t.color,
                       t.char_queue,
                       t.number_queue,
                       t.desc_machine,
                       t.triage_color,
                       t.triage_color_text,
                       t.titulo,
                       t.label_name,
                       t.label_room,
                       t.nome,
                       t.url_photo
                  FROM TABLE(i_tbl) t;
        
        ELSE
            pk_types.open_my_cursor(o_sql);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang  => i_lang,
                          i_code  => SQLCODE,
                          i_errm  => SQLERRM,
                          i_msg   => '',
                          i_func  => 'GET_CALL_CURSOR',
                          o_error => o_error);
            pk_types.open_my_cursor(o_sql);
            RETURN FALSE;
    END get_call_cursor;

    --***********************************************************
    FUNCTION get_last_calls_adm
    (
        i_lang       IN NUMBER,
        i_id_mach    IN NUMBER,
        o_last_calls OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_max_tickets_shown NUMBER;
        tbl_return          t_tbl_wl_plasma := t_tbl_wl_plasma();
        l_idx               NUMBER;
        l_bool              BOOLEAN;
    
        k_grey  CONSTANT VARCHAR2(0100 CHAR) := pk_alert_constant.g_color_icon_light_grey;
        k_black CONSTANT VARCHAR2(0100 CHAR) := pk_alert_constant.g_color_black;
        l_label_room VARCHAR2(4000);
    
        CURSOR c_get_item
        (
            id_mach          IN NUMBER,
            i_num_max_ticket IN NUMBER
        ) IS
            SELECT id_call_queue,
                   message,
                   sound_file,
                   id_wl_waiting_line,
                   id_wl_machine_dest,
                   dt_gen_sound_file_tstz,
                   flg_type
              FROM (SELECT w.id_call_queue,
                           w.message,
                           w.sound_file,
                           w.id_wl_waiting_line,
                           w.id_wl_machine_dest,
                           w.dt_gen_sound_file_tstz,
                           w.flg_type
                      FROM wl_call_queue w
                     WHERE w.id_wl_machine = id_mach
                       AND w.flg_status = 'T'
                       AND w.flg_type = 'A'
                       AND w.dt_gen_sound_file_tstz IS NOT NULL
                     ORDER BY w.dt_gen_sound_file_tstz DESC, w.id_call_queue DESC)
             WHERE rownum <= i_num_max_ticket;
    
        TYPE type_get_item_c IS TABLE OF c_get_item%ROWTYPE;
        tbl_row type_get_item_c;
    
        --********************************************
        PROCEDURE l_load_cursor
        (
            i_id_mach           IN NUMBER,
            i_max_tickets_shown IN NUMBER
        ) IS
        BEGIN
        
            OPEN c_get_item(i_id_mach, i_max_tickets_shown);
            FETCH c_get_item BULK COLLECT
                INTO tbl_row;
            CLOSE c_get_item;
        
        END l_load_cursor;
    
        --***************************************
        PROCEDURE init_tbl_return IS
        BEGIN
            tbl_return(l_idx).triage_color := k_grey;
            tbl_return(l_idx).triage_color_text := k_black;
            tbl_return(l_idx).titulo := NULL;
            tbl_return(l_idx).label_name := NULL;
            tbl_return(l_idx).label_room := NULL;
            tbl_return(l_idx).nome := NULL;
            tbl_return(l_idx).url_photo := NULL;
        END init_tbl_return;
    
    BEGIN
    
        l_max_tickets_shown := pk_wl_aux.get_max_tickets_shown(i_id_mach);
        l_label_room        := pk_message.get_message(i_lang => i_lang, i_code_mess => k_med_msg_02);
    
        l_load_cursor(i_id_mach, l_max_tickets_shown);
    
        <<lup_thru_called_tickets>>
        FOR i IN 1 .. tbl_row.count
        LOOP
        
            tbl_return.extend();
            l_idx := tbl_return.count;
        
            tbl_return(l_idx) := pk_wl_aux.process_call(i_lang               => i_lang,
                                                        i_id_waiting_line    => tbl_row(i).id_wl_waiting_line,
                                                        i_id_call_queue      => tbl_row(i).id_call_queue,
                                                        i_id_mach            => i_id_mach,
                                                        i_label_room         => l_label_room,
                                                        i_message            => tbl_row(i).message,
                                                        i_sound_file         => tbl_row(i).sound_file,
                                                        i_flg_type           => tbl_row(i).flg_type,
                                                        i_id_wl_machine_dest => tbl_row(i).id_wl_machine_dest);
        
        END LOOP lup_thru_called_tickets;
    
        l_bool := get_call_cursor(i_lang => i_lang, i_tbl => tbl_return, o_sql => o_last_calls, o_error => o_error);
    
        RETURN l_bool;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang  => i_lang,
                          i_code  => SQLCODE,
                          i_errm  => SQLERRM,
                          i_msg   => '',
                          i_func  => 'GET_LAST_CALLS_ADM',
                          o_error => o_error);
            pk_types.open_my_cursor(o_last_calls);
            RETURN FALSE;
    END get_last_calls_adm;

    -- *********************************************************
    FUNCTION get_current_call_adm
    (
        i_lang         IN NUMBER,
        i_id_mach      IN NUMBER,
        o_current_call OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        tbl_return t_tbl_wl_plasma := t_tbl_wl_plasma();
        l_idx      NUMBER;
        l_bool     BOOLEAN;
    
        l_time_val   NUMBER := -5;
        l_time_unit  VARCHAR2(0010) := 'MINUTE';
        l_label_room VARCHAR2(4000);
    
        CURSOR c_get_item(i_id_mach IN NUMBER) IS
            SELECT id_call_queue,
                   message,
                   sound_file,
                   id_wl_waiting_line,
                   id_wl_machine_dest,
                   dt_gen_sound_file_tstz,
                   flg_type
              FROM (SELECT w.id_call_queue,
                           w.message,
                           w.sound_file,
                           w.id_wl_waiting_line,
                           w.id_wl_machine_dest,
                           w.dt_gen_sound_file_tstz,
                           w.flg_type
                      FROM wl_call_queue w
                     WHERE w.id_wl_machine = i_id_mach
                       AND w.flg_status = 'P'
                       AND w.flg_type = 'A'
                       AND w.dt_gen_sound_file_tstz IS NOT NULL
                       AND w.dt_gen_sound_file_tstz >= current_timestamp + numtodsinterval(l_time_val, l_time_unit)
                     ORDER BY w.dt_gen_sound_file_tstz ASC, w.id_call_queue ASC);
    
        TYPE type_get_item_c IS TABLE OF c_get_item%ROWTYPE;
        tbl_row type_get_item_c;
    
        --********************************************
        PROCEDURE l_load_cursor(i_id_mach IN NUMBER) IS
        BEGIN
        
            OPEN c_get_item(i_id_mach);
            FETCH c_get_item BULK COLLECT
                INTO tbl_row;
            CLOSE c_get_item;
        
        END l_load_cursor;
    
    BEGIN
    
        l_load_cursor(i_id_mach);
        l_label_room := pk_message.get_message(i_lang => i_lang, i_code_mess => k_med_msg_02);
    
        <<lup_once_queue>>
        FOR i IN 1 .. tbl_row.count
        LOOP
        
            tbl_return.extend();
            l_idx := tbl_return.count;
        
            tbl_return(l_idx) := pk_wl_aux.process_call(i_lang               => i_lang,
                                                        i_id_waiting_line    => tbl_row(i).id_wl_waiting_line,
                                                        i_id_call_queue      => tbl_row(i).id_call_queue,
                                                        i_id_mach            => i_id_mach,
                                                        i_label_room         => l_label_room,
                                                        i_message            => tbl_row(i).message,
                                                        i_sound_file         => tbl_row(i).sound_file,
                                                        i_flg_type           => tbl_row(i).flg_type,
                                                        i_id_wl_machine_dest => tbl_row(i).id_wl_machine_dest);
        
            EXIT lup_once_queue;
        
        END LOOP lup_once_queue;
    
        l_bool := get_call_cursor(i_lang => i_lang, i_tbl => tbl_return, o_sql => o_current_call, o_error => o_error);
    
        RETURN l_bool;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang  => i_lang,
                          i_code  => SQLCODE,
                          i_errm  => SQLERRM,
                          i_msg   => '',
                          i_func  => 'GET_CURRENT_CALL_ADM',
                          o_error => o_error);
            pk_types.open_my_cursor(o_current_call);
            RETURN FALSE;
    END get_current_call_adm;

    FUNCTION get_stats_adm
    (
        i_lang    IN NUMBER,
        i_id_mach IN NUMBER,
        o_stats   OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_audio_active VARCHAR2(4000);
        l_institution  NUMBER;
        k_grey  CONSTANT VARCHAR2(0100 CHAR) := pk_alert_constant.g_color_icon_light_grey;
        k_black CONSTANT VARCHAR2(0100 CHAR) := pk_alert_constant.g_color_black;
    BEGIN
    
        l_audio_active := pk_wl_aux.get_flg_audio(i_id_mach);
        l_institution  := pk_wl_aux.get_inst_from_mach(i_id_mach);
    
        OPEN o_stats FOR
            SELECT xsql.message_audio,
                   xsql.message_sound_file,
                   xsql.flg_type,
                   xsql.id_call_queue,
                   q1.color,
                   xsql.char_queue,
                   xsql.number_queue,
                   xsql.desc_machine,
                   xsql.triage_color,
                   xsql.triage_color_text,
                   xsql.titulo,
                   xsql.label_name,
                   xsql.label_room,
                   xsql.nome,
                   xsql.url_photo,
                   q1.id_wl_queue,
                   pk_translation.get_translation(i_lang => i_lang, i_code_mess => q1.code_msg) desc_queue,
                   xsql.dt_call
              FROM (SELECT *
                      FROM wl_q_machine xmain
                     WHERE id_wl_machine = i_id_mach) xmain
              JOIN wl_queue q1
                ON q1.id_wl_queue = xmain.id_wl_queue
              LEFT JOIN (SELECT 0 flg_order,
                                xall.message message_audio,
                                pk_wl_aux.set_audio(l_audio_active, xall.sound_file) message_sound_file,
                                xall.flg_type,
                                xall.id_call_queue,
                                xall.color,
                                xall.char_queue,
                                xall.number_queue,
                                pk_wl_aux.get_message_desc_machine(i_lang, xall.id_wl_machine_dest) desc_machine,
                                k_grey triage_color,
                                k_black triage_color_text,
                                NULL titulo,
                                NULL label_name,
                                NULL label_room,
                                NULL nome,
                                NULL url_photo,
                                xall.id_wl_queue,
                                xall.dt_gen_sound_file_tstz dt_call
                           FROM (SELECT cq.id_call_queue,
                                        q.code_msg,
                                        w.char_queue,
                                        w.number_queue,
                                        w.id_wl_queue,
                                        cq.message,
                                        cq.sound_file,
                                        cq.flg_type,
                                        q.color,
                                        cq.id_wl_machine_dest,
                                        cq.dt_gen_sound_file_tstz,
                                        row_number() over(PARTITION BY w.id_wl_queue ORDER BY cq.dt_gen_sound_file_tstz DESC) rn
                                   FROM wl_waiting_line w
                                   JOIN wl_queue q
                                     ON q.id_wl_queue = w.id_wl_queue
                                   JOIN wl_queue_group qg
                                     ON qg.id_wl_queue_group = q.id_wl_queue_group
                                   JOIN wl_q_machine qm
                                     ON qm.id_wl_queue = q.id_wl_queue
                                   JOIN wl_call_queue cq
                                     ON cq.id_wl_waiting_line = w.id_wl_waiting_line
                                    AND cq.flg_status = 'T'
                                  WHERE qg.id_institution = l_institution
                                    AND qm.id_wl_machine = i_id_mach) xall
                          WHERE xall.rn = 1) xsql
                ON xsql.id_wl_queue = xmain.id_wl_queue
            --AND xmain.id_wl_machine = i_id_mach
             ORDER BY nvl(xsql.flg_order, 1) ASC, xmain.order_rank ASC, desc_queue ASC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang  => i_lang,
                          i_code  => SQLCODE,
                          i_errm  => SQLERRM,
                          i_msg   => '',
                          i_func  => 'GET_STAT_ADM',
                          o_error => o_error);
            pk_types.open_my_cursor(o_stats);
            RETURN FALSE;
        
    END get_stats_adm;

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
    ) RETURN BOOLEAN IS
        l_bool BOOLEAN;
        err_processing EXCEPTION;
    
    BEGIN
    
        l_bool := get_last_calls_med(i_lang    => i_lang,
                                     i_id_mach => i_id_mach,
                                     --i_id_queue   => i_id_queue
                                     o_last_calls => o_last_called,
                                     o_error      => o_error);
        IF NOT l_bool
        THEN
            RAISE err_processing;
        END IF;
    
        l_bool := get_stats_med(i_lang => i_lang, i_id_mach => i_id_mach, o_stats => o_stats, o_error => o_error);
        IF NOT l_bool
        THEN
            RAISE err_processing;
        END IF;
    
        l_bool := get_current_call_med(i_lang    => i_lang,
                                       i_id_mach => i_id_mach,
                                       --i_id_queue     => i_id_queue
                                       o_current_call => o_current_call,
                                       o_error        => o_error);
        IF NOT l_bool
        THEN
            RAISE err_processing;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN err_processing THEN
            pk_types.open_my_cursor(o_current_call);
            pk_types.open_my_cursor(o_last_called);
            pk_types.open_my_cursor(o_stats);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            process_error(i_lang  => i_lang,
                          i_code  => SQLCODE,
                          i_errm  => SQLERRM,
                          i_msg   => '',
                          i_func  => 'GET_ITEM_CALL_QUEUE_MED',
                          o_error => o_error);
            pk_types.open_my_cursor(o_current_call);
            pk_types.open_my_cursor(o_last_called);
            RETURN FALSE;
    END get_item_call_queue_med;

    -- *********************************************************
    FUNCTION get_current_call_med
    (
        i_lang    IN NUMBER,
        i_id_mach IN NUMBER,
        --i_id_queue     in number,
        o_current_call OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        tbl_return t_tbl_wl_plasma := t_tbl_wl_plasma();
        l_idx      NUMBER;
        l_bool     BOOLEAN;
        -- l_prof     profissional;
    
        l_time_val   NUMBER := -5;
        l_time_unit  VARCHAR2(0010 CHAR) := 'MINUTE';
        l_label_room VARCHAR2(4000);
        --l_id_institution NUMBER;
    
        CURSOR c_get_item(i_id_mach IN NUMBER) IS
            SELECT w.id_call_queue,
                   w.message,
                   w.sound_file,
                   w.id_wl_waiting_line,
                   w.id_wl_machine_dest,
                   w.dt_gen_sound_file_tstz,
                   w.flg_type
              FROM wl_call_queue w
             WHERE w.id_wl_machine = i_id_mach
               AND w.flg_status = 'P'
               AND w.flg_type = 'M'
               AND w.dt_gen_sound_file_tstz IS NOT NULL
               AND w.dt_gen_sound_file_tstz >= pk_date_utils.add_to_ltstz(current_timestamp, l_time_val, l_time_unit)
            --AND w.id_call_queue = i_id_queue
            ;
    
        TYPE type_get_item_c IS TABLE OF c_get_item%ROWTYPE;
        tbl_row type_get_item_c;
    
        --********************************************
        PROCEDURE l_load_cursor(i_id_mach IN NUMBER) IS
        BEGIN
        
            OPEN c_get_item(i_id_mach);
            FETCH c_get_item BULK COLLECT
                INTO tbl_row;
            CLOSE c_get_item;
        
        END l_load_cursor;
    
    BEGIN
    
        l_load_cursor(i_id_mach);
        l_label_room := pk_message.get_message(i_lang => i_lang, i_code_mess => k_med_msg_02);
    
        <<lup_once_queue>>
        FOR i IN 1 .. tbl_row.count
        LOOP
        
            tbl_return.extend();
            l_idx := tbl_return.count;
        
            tbl_return(l_idx) := pk_wl_aux.process_call(i_lang               => i_lang,
                                                        i_id_waiting_line    => tbl_row(i).id_wl_waiting_line,
                                                        i_id_call_queue      => tbl_row(i).id_call_queue,
                                                        i_id_mach            => i_id_mach,
                                                        i_label_room         => l_label_room,
                                                        i_message            => tbl_row(i).message,
                                                        i_sound_file         => tbl_row(i).sound_file,
                                                        i_flg_type           => tbl_row(i).flg_type,
                                                        i_id_wl_machine_dest => tbl_row(i).id_wl_machine_dest);
        
            EXIT lup_once_queue;
        
        END LOOP lup_once_queue;
    
        l_bool := get_call_cursor(i_lang => i_lang, i_tbl => tbl_return, o_sql => o_current_call, o_error => o_error);
    
        RETURN l_bool;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang  => i_lang,
                          i_code  => SQLCODE,
                          i_errm  => SQLERRM,
                          i_msg   => '',
                          i_func  => 'GET_CURRENT_CALL_MED',
                          o_error => o_error);
            pk_types.open_my_cursor(o_current_call);
            RETURN FALSE;
    END get_current_call_med;

    --***********************************************************
    FUNCTION get_last_calls_med
    (
        i_lang       IN NUMBER,
        i_id_mach    IN NUMBER,
        o_last_calls OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_max_tickets_shown NUMBER;
        tbl_return          t_tbl_wl_plasma := t_tbl_wl_plasma();
        l_idx               NUMBER;
        l_bool              BOOLEAN;
    
        k_grey  CONSTANT VARCHAR2(0100 CHAR) := pk_alert_constant.g_color_icon_light_grey;
        k_black CONSTANT VARCHAR2(0100 CHAR) := pk_alert_constant.g_color_black;
        l_label_room VARCHAR2(4000);
    
        CURSOR c_get_item
        (
            id_mach          IN NUMBER,
            i_num_max_ticket IN NUMBER
        ) IS
            SELECT id_call_queue,
                   message,
                   sound_file,
                   id_wl_waiting_line,
                   id_wl_machine_dest,
                   dt_gen_sound_file_tstz,
                   flg_type
              FROM (SELECT w.id_call_queue,
                           w.message,
                           w.sound_file,
                           w.id_wl_waiting_line,
                           w.id_wl_machine_dest,
                           w.dt_gen_sound_file_tstz,
                           w.flg_type
                      FROM wl_call_queue w
                     WHERE w.id_wl_machine = id_mach
                       AND w.flg_status = 'T'
                       AND w.flg_type = 'M'
                       AND w.dt_gen_sound_file_tstz IS NOT NULL
                     ORDER BY w.dt_gen_sound_file_tstz DESC, w.id_call_queue DESC)
             WHERE rownum <= i_num_max_ticket;
    
        TYPE type_get_item_c IS TABLE OF c_get_item%ROWTYPE;
        tbl_row type_get_item_c;
    
        --********************************************
        PROCEDURE l_load_cursor
        (
            i_id_mach           IN NUMBER,
            i_max_tickets_shown IN NUMBER
        ) IS
        BEGIN
        
            OPEN c_get_item(i_id_mach, i_max_tickets_shown);
            FETCH c_get_item BULK COLLECT
                INTO tbl_row;
            CLOSE c_get_item;
        
        END l_load_cursor;
    
        --***************************************
        PROCEDURE init_tbl_return IS
        BEGIN
            tbl_return(l_idx).triage_color := k_grey;
            tbl_return(l_idx).triage_color_text := k_black;
            tbl_return(l_idx).titulo := NULL;
            tbl_return(l_idx).label_name := NULL;
            tbl_return(l_idx).label_room := NULL;
            tbl_return(l_idx).nome := NULL;
            tbl_return(l_idx).url_photo := NULL;
        END init_tbl_return;
    
    BEGIN
    
        l_max_tickets_shown := pk_wl_aux.get_max_tickets_shown(i_id_mach);
        l_label_room        := pk_message.get_message(i_lang => i_lang, i_code_mess => k_med_msg_02);
    
        l_load_cursor(i_id_mach, l_max_tickets_shown);
    
        <<lup_thru_called_tickets>>
        FOR i IN 1 .. tbl_row.count
        LOOP
        
            tbl_return.extend();
            l_idx := tbl_return.count;
        
            tbl_return(l_idx) := pk_wl_aux.process_call(i_lang               => i_lang,
                                                        i_id_waiting_line    => tbl_row(i).id_wl_waiting_line,
                                                        i_id_call_queue      => tbl_row(i).id_call_queue,
                                                        i_id_mach            => i_id_mach,
                                                        i_label_room         => l_label_room,
                                                        i_message            => tbl_row(i).message,
                                                        i_sound_file         => tbl_row(i).sound_file,
                                                        i_flg_type           => tbl_row(i).flg_type,
                                                        i_id_wl_machine_dest => tbl_row(i).id_wl_machine_dest);
        
        END LOOP lup_thru_called_tickets;
    
        l_bool := get_call_cursor(i_lang => i_lang, i_tbl => tbl_return, o_sql => o_last_calls, o_error => o_error);
    
        RETURN l_bool;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang  => i_lang,
                          i_code  => SQLCODE,
                          i_errm  => SQLERRM,
                          i_msg   => '',
                          i_func  => 'GET_LAST_CALLS_MED',
                          o_error => o_error);
            pk_types.open_my_cursor(o_last_calls);
            RETURN FALSE;
    END get_last_calls_med;

    --****************************************
    FUNCTION get_stats_med
    (
        i_lang    IN NUMBER,
        i_id_mach IN NUMBER,
        o_stats   OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        --l_audio_active VARCHAR2(4000);
        l_institution NUMBER;
        k_grey  CONSTANT VARCHAR2(0100 CHAR) := pk_alert_constant.g_color_icon_light_grey;
        k_black CONSTANT VARCHAR2(0100 CHAR) := pk_alert_constant.g_color_black;
        l_audio_active VARCHAR2(1000 CHAR);
        l_titulo_mens  VARCHAR2(1000 CHAR);
        l_med_queue_color VARCHAR2(1000 CHAR);
        l_prof         profissional;
    
        --*******************************************
        PROCEDURE set_l_prof IS
            k_wl_software CONSTANT NUMBER := 0;
        BEGIN
        
            IF nvl(l_prof.institution, 0) = 0
            THEN
                l_prof := profissional(0, l_institution, k_wl_software);
            END IF;
        
        END set_l_prof;
    
    BEGIN
    
        l_institution  := pk_wl_aux.get_inst_from_mach(i_id_mach);
        l_audio_active := pk_wl_aux.get_flg_audio(i_id_mach);
        set_l_prof();
    
        l_titulo_mens := pk_sysconfig.get_config(i_code_cf => 'WL_TITULO', i_prof => l_prof);
        l_med_queue_color := pk_wl_aux.get_med_queue_color(i_id_mach, l_institution);
    
        OPEN o_stats FOR
            SELECT xsql.message_audio,
                   xsql.message_sound_file,
                   xsql.flg_type,
                   xsql.id_call_queue,
                   --****
                   --pk_wl_aux.get_parent_color(xsql.id_wl_waiting_line_parent) color,
                   l_med_queue_color color,
                   -- xsql.color,
                   --*****
                   xsql.char_queue,
                   xsql.number_queue,
                   xsql.desc_machine,
                   xsql.triage_color,
                   xsql.triage_color_text,
                   ----
                   pk_wl_aux.get_tit_pat_visual(i_lang, l_titulo_mens, xsql.id_patient) titulo,
                   --xsql.titulo,
                   ---
                   xsql.label_name,
                   xsql.label_room,
                   --*********************************
                   pk_adt.get_patient_name_to_sort(i_lang, l_prof, xsql.id_patient, pk_adt.g_false) nome,
                   --xsql.nome,
                   ---*******************************
                   xsql.url_photo,
                   --xsql.id_wl_queue,
                   xmain.id_room_med id_wl_queue, --id_item
                   pk_translation.get_translation(i_lang => i_lang, i_code_mess => xmain.code_room) desc_queue, --desc_item,
                   xsql.dt_call
              FROM (SELECT wwr.id_room_consult id_room_med, r.code_room, wwr.order_rank room_rank, wwr.id_room_wait -- 2089, 2087
                      FROM wl_waiting_room wwr
                      JOIN room r
                        ON r.id_room = wwr.id_room_consult
                      JOIN wl_machine m
                        ON m.id_room = wwr.id_room_wait
                     WHERE id_wl_machine = i_id_mach) xmain
              LEFT JOIN (SELECT xall.message message_audio,
                                pk_wl_aux.set_audio(l_audio_active, xall.sound_file) message_sound_file,
                                xall.id_patient,
                                xall.flg_type,
                                xall.id_room,
                                xall.id_call_queue,
                                xall.color,
                                xall.char_queue,
                                xall.number_queue,
                                pk_wl_aux.get_message_desc_machine(i_lang, xall.id_wl_machine_dest) desc_machine,
                                xall.id_wl_waiting_line_parent,
                                k_grey triage_color,
                                k_black triage_color_text,
                                NULL titulo,
                                NULL label_name,
                                NULL label_room,
                                NULL nome,
                                NULL url_photo,
                                xall.id_wl_queue,
                                xall.id_room_consult,
                                xall.dt_gen_sound_file_tstz dt_call
                           FROM (SELECT cq.id_call_queue,
                                        w_calling.id_room,
                                        --pk_translation.get_translation(i_lang, r.code_room) desc_room,
                                        --q.code_msg,
                                        wl.char_queue,
                                        wl.number_queue,
                                        wl.id_wl_queue,
                                        wl.id_patient,
                                        cq.message,
                                        cq.sound_file,
                                        cq.flg_type,
                                        wl.id_wl_waiting_line_parent,
                                        q.color,
                                        cq.id_wl_machine_dest,
                                        cq.dt_gen_sound_file_tstz,
                                        w_consult.id_room id_room_consult,
                                        row_number() over(PARTITION BY w_consult.id_room ORDER BY cq.dt_gen_sound_file_tstz DESC) rn
                                   FROM wl_waiting_line wl
                                   JOIN wl_call_queue cq
                                     ON cq.id_wl_waiting_line = wl.id_wl_waiting_line
                                   JOIN wl_machine w_calling
                                     ON w_calling.id_wl_machine = cq.id_wl_machine
                                   JOIN wl_machine w_consult
                                     ON w_consult.id_wl_machine = cq.id_wl_machine_dest
                                   JOIN wl_queue q
                                     ON q.id_wl_queue = wl.id_wl_queue
                                   JOIN wl_queue_group qg
                                     ON qg.id_wl_queue_group = q.id_wl_queue_group
                                   JOIN room r
                                     ON r.id_room = w_calling.id_room
                                  WHERE cq.id_wl_machine = i_id_mach
                                    AND cq.flg_type = 'M'
                                    AND qg.id_institution = l_institution) xall
                          WHERE xall.rn = 1) xsql
                ON xsql.id_room = xmain.id_room_wait
               AND xsql.id_room_consult = xmain.id_room_med
             ORDER BY xmain.room_rank, desc_queue;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang  => i_lang,
                          i_code  => SQLCODE,
                          i_errm  => SQLERRM,
                          i_msg   => '',
                          i_func  => 'GET_STAT_MED',
                          o_error => o_error);
            pk_types.open_my_cursor(o_stats);
            RETURN FALSE;
        
    END get_stats_med;

    FUNCTION get_popup_queues
    (
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_mach_name IN VARCHAR2,
        o_result    OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        --k_queue_type_adm CONSTANT VARCHAR2(0010 CHAR) := 'A';
        l_id_machine NUMBER;
    BEGIN
    
        l_id_machine := pk_wl_aux.get_id_machine_by_name(i_mach_name);
    
        RETURN get_queues_admin(i_lang          => i_lang,
                                i_id_prof       => i_prof,
                                i_id_wl_machine => l_id_machine,
                                o_queues        => o_result,
                                o_error         => o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              '',
                                              'ALERT',
                                              'PK_WL_BASE',
                                              'GET_POPUP_QUEUES',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_result);
            RETURN FALSE;
    END get_popup_queues;

    FUNCTION get_next_ticket(i_lang IN NUMBER,
                             --i_prof        IN profissional,
                             i_id_wl_queue IN NUMBER,
                             o_char        OUT VARCHAR2,
                             o_number      OUT NUMBER,
                             o_error       OUT t_error_out) RETURN BOOLEAN IS
        l_rows table_varchar := table_varchar();
    BEGIN
        pk_wl_aux.get_next_ticket(i_id_wl_queue, o_char, o_number);
    
        ts_wl_waiting_line.ins(id_wl_waiting_line_in        => ts_wl_waiting_line.next_key,
                               char_queue_in                => o_char,
                               number_queue_in              => o_number,
                               id_wl_queue_in               => i_id_wl_queue,
                               id_episode_in                => NULL,
                               id_wl_waiting_line_parent_in => NULL,
                               flg_wl_status_in             => pk_alert_constant.g_wr_wl_status_x,
                               dt_begin_tstz_in             => current_timestamp,
                               rows_out                     => l_rows);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              '',
                                              k_package_owner,
                                              k_package_name,
                                              'GET_NEXT_TICKET',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes();
            RETURN FALSE;
    END get_next_ticket;

BEGIN

    -- Log initialization.
    pk_alertlog.who_am_i(k_package_owner, k_package_name);
    pk_alertlog.log_init(k_package_name);

END pk_wl_base;
/
