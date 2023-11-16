/*-- Last Change Revision: $Rev: 2027885 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:35 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_wlcore AS

    k_yes CONSTANT VARCHAR2(0010 CHAR) := 'Y';
    k_no  CONSTANT VARCHAR2(0010 CHAR) := 'N';

    /***************************************************************************************************************
    *
    * Gets the language for the provided professional. If no language is set, it assumes the general language configured for WR
    *
    * @param      i_id_prof               ID of the professional
    *
    * @RETURN  The ID of the language.
    * @author  Ricardo Nuno Almeida
    * @version 1.0
    * @since   03-03-2009
    *
    ****************************************************************************************************/
    FUNCTION get_prof_default_language(i_id_prof IN profissional) RETURN language.id_language%TYPE IS
    
        l_prof_language language.id_language%TYPE;
    
        l_error t_error_out;
    
    BEGIN
    
        IF get_prof_default_language(i_id_prof => i_id_prof, o_id_lang => l_prof_language, o_error => l_error)
        THEN
            RETURN l_prof_language;
        END IF;
    
        RETURN 0;
    
    END get_prof_default_language;

    /**
    * Gets the language for the provided professional. If no language is set, it assumes the general language configured for WR
    *
    * @param      i_id_prof               ID of the professional
    * @param      o_id_lang               language
    *
    * @RETURN  true or false
    * @author  Ricardo Nuno Almeida
    * @version 1.0
    * @since   03-03-2009
    */
    FUNCTION get_prof_default_language
    (
        i_id_prof IN profissional,
        o_id_lang OUT language.id_language%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET PROF PREFERENCES';
        pk_alertlog.log_debug(g_error, g_package_name);
        BEGIN
            SELECT pp.id_language
              INTO o_id_lang
              FROM prof_preferences pp
             WHERE pp.id_professional = i_id_prof.id
               AND pp.id_institution = i_id_prof.institution
               AND rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
            
                o_id_lang := pk_sysconfig.get_config('WL_LANG', i_id_prof);
            
        END;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(o_id_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROF_DEFAULT_LANGUAGE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_prof_default_language;

    /**
    * Get configuration about the machine executing a waiting line module.
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_NAME_PC the machine name.
    * @param   O_ID_PC The wl_machine to which I_NAME_PC is associated.
    * @param   O_VIDEO 'Y' if machine trasmits video, 'N' otherwise
    * @param   O_AUDIO 'B' if machine trasmits bip, 'V' for voice, 'B' for both
    * @param   O_ID_DEPARTMENT The department id where the machine is located
    * @param   O_ID_INSTITUTION The institution id associated with the department
    * @param   o_call_exec_mapping 'Y' call execute_mapping service, 'N' otherwise
    * @param   O_INTERFACE_UPDATE_TIME The interval time in ms to get patients from the interface
    * @param   O_ID_SOFTWARE The Waiting Room software id
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Luís Gaspar
    * @version 1.0
    * @since   14-11-2006 wl_machine
    */
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
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_params       table_varchar;
        l_demo         BOOLEAN := FALSE;
        l_kiosk_exists NUMBER;
    
    BEGIN
        -- get machine info
        g_error := 'GET MACHINE INFO';
        pk_alertlog.log_debug(g_error, g_package_name);
        l_demo := pk_sysconfig.get_config(g_wl_demo_flg, i_prof.institution, i_prof.software) = pk_alert_constant.g_yes;
    
        IF l_demo
        THEN
            SELECT m.id_wl_machine,
                   m.flg_audio_active,
                   m.flg_video_active,
                   g_demo_department_0,
                   i_prof.institution,
                   m.flg_mach_type,
                   m.max_ticket_shown
              INTO o_id_pc, o_audio, o_video, o_id_department, o_id_institution, o_flg_mach_type, o_max_ticket_shown
              FROM wl_machine m
             WHERE m.flg_demo = pk_alert_constant.g_yes;
        ELSE
            SELECT m.id_wl_machine,
                   m.flg_audio_active,
                   m.flg_video_active,
                   d.id_department,
                   d.id_institution,
                   m.flg_mach_type,
                   m.max_ticket_shown
              INTO o_id_pc, o_audio, o_video, o_id_department, o_id_institution, o_flg_mach_type, o_max_ticket_shown
              FROM wl_machine m
              JOIN room r
                ON m.id_room = r.id_room
              JOIN department d
                ON r.id_department = d.id_department
             WHERE upper(machine_name) = upper(i_name_pc);
        END IF;
    
        g_error := 'GET SOFTWARE_ID';
        pk_alertlog.log_debug(g_error, g_package_name);
        IF NOT get_id_software(i_lang, i_prof, o_software_id, o_error)
        THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              o_error.err_desc,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ID_MACHINE',
                                              o_error);
        
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
    
        g_error := 'GET CALL EXECUTE MAPPING';
        pk_alertlog.log_debug(g_error, g_package_name);
        o_call_exec_mapping := pk_sysconfig.get_config('WR_CALL_EXECUTE_MAPPING', i_prof);
    
        g_error := 'GET INTERFACE INTERVAL TIME';
        pk_alertlog.log_debug(g_error, g_package_name);
        o_interface_update_time := pk_sysconfig.get_config('WL_INTERFACE_INTERVAL_TIME', i_prof);
    
        l_kiosk_exists := count_kiosk_department(i_prof => i_prof, i_machine_name => i_name_pc);
    
        o_kiosk_exists := k_no;
        IF l_kiosk_exists > 0
        THEN
            o_kiosk_exists := k_yes;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            g_error := 'NO CONFIGURATION FOR MACHINE ' || i_name_pc;
            DECLARE
                --Inicialization of object for input
                l_error_in      t_error_in := t_error_in();
                l_error_message VARCHAR2(4000) := pk_message.get_message(i_lang, 'WL_MESSAGE_M001');
            
            BEGIN
            
                l_params := table_varchar(i_name_pc);
                g_ret    := pk_message.format(i_lang, l_error_message, l_params, l_error_message, o_error);
            
                l_error_in.set_all(i_lang,
                                   'WL_MESSAGE_M001',
                                   l_error_message,
                                   l_error_message,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_ID_MACHINE');
            
                -- execute error processing
                g_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
        
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ID_MACHINE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_id_machine;

    /********************************************************************************************
    *
    * Send the ID of the machine and it will return its name
    *
    * @param      i_id_pc        ID of the WL_MACHINE
    * @param      o_name_pc      Name of the machine
    *
    * @RETURN  True or False
    * @author  ?
    * @version 1.0
    * @since   ?
    **********************************************************************************************/
    FUNCTION get_name_machine
    (
        i_id_pc   IN NUMBER,
        o_name_pc OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET MACHINE_NAME';
        SELECT machine_name
          INTO o_name_pc
          FROM wl_machine
         WHERE id_wl_machine = i_id_pc;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(1,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_NAME_MACHINE',
                                              o_error);
        
            RETURN FALSE;
    END get_name_machine;

    /**
    * Gets the defined value for a sys_config.
    *
    * @param      i_code_cf               Configs required
    * @param      i_prof_inst             Institution ID
    * @param      i_prof_soft              Software ID
    * @param      o_msg_cf                 Cursor with all configurations requested
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ricardo Nuno Almeida
    * @version 1.0
    * @since   17-02-2009
    */
    FUNCTION get_config
    (
        i_code_cf   IN table_varchar,
        i_prof_inst IN institution.id_institution%TYPE,
        i_prof_soft IN software.id_software%TYPE,
        o_msg_cf    OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN pk_sysconfig.get_config(i_code_cf   => i_code_cf,
                                       i_prof_inst => i_prof_inst,
                                       i_prof_soft => i_prof_soft,
                                       o_msg_cf    => o_msg_cf);
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(1,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CONFIG',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_msg_cf);
            RETURN FALSE;
    END get_config;

    /**
    * Get configuration about the machine executing a waiting line module.
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_SOUND_FILE The sound file name.
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Luís Gaspar
    * @version 1.0
    * @since   21-11-2006
    */
    FUNCTION set_item_call_queue_sound_gen
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_sound_file IN VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'UPDATE WL_CALL_QUEUE';
        --lg test DT_GEN_SOUND is not needed because in this situation dt_gen_sounf_file is filled in set_item_call_queue
        UPDATE wl_call_queue
           SET dt_gen_sound_file_tstz = current_timestamp
         WHERE sound_file = i_sound_file;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ITEM_CALL_QUEUE_SOUND_GEN',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_item_call_queue_sound_gen;

    FUNCTION get_flg_audio(i_id_mach IN NUMBER) RETURN VARCHAR2 IS
        tbl_flg  table_varchar;
        l_return VARCHAR2(0100 CHAR);
    BEGIN
    
        SELECT flg_audio_active
          BULK COLLECT
          INTO tbl_flg
          FROM wl_machine
         WHERE id_wl_machine = i_id_mach;
    
        IF tbl_flg.count > 0
        THEN
            l_return := tbl_flg(1);
        END IF;
    
        RETURN l_return;
    
    END get_flg_audio;

    FUNCTION get_waiting_line_row(i_id_wl IN NUMBER) RETURN wl_waiting_line%ROWTYPE IS
    
        xrow wl_waiting_line%ROWTYPE;
    
    BEGIN
    
        SELECT w.*
          INTO xrow
          FROM wl_waiting_line w
         WHERE id_wl_waiting_line = i_id_wl;
    
        RETURN xrow;
    
    END get_waiting_line_row;

    FUNCTION get_desc_room
    (
        i_lang    IN NUMBER,
        i_id_room IN NUMBER
    ) RETURN VARCHAR2 IS
    
        tbl_desc table_varchar;
        tbl_aux  table_varchar;
    
        l_return VARCHAR2(4000);
    
    BEGIN
    
        SELECT pk_translation.get_translation(i_lang, roo.code_room), desc_room
          BULK COLLECT
          INTO tbl_desc, tbl_aux
          FROM room roo
         WHERE roo.id_room = i_id_room;
    
        IF tbl_desc.count > 0
        THEN
            l_return := tbl_desc(1);
            IF l_return IS NULL
            THEN
                l_return := tbl_aux(1);
            END IF;
        END IF;
    
        RETURN l_return;
    
    END get_desc_room;

    FUNCTION get_message_desc_machine
    (
        i_lang       IN NUMBER,
        i_demo       IN BOOLEAN,
        i_id_machine IN NUMBER
    ) RETURN VARCHAR2 IS
    
        l_return  VARCHAR2(4000);
        l_code    VARCHAR2(4000);
        l_id_room NUMBER;
    
    BEGIN
    
        SELECT mac.cod_desc_machine_visual, mac.id_room
          INTO l_code, l_id_room
          FROM wl_machine mac
         WHERE id_wl_machine = i_id_machine;
    
        l_return := pk_translation.get_translation(i_lang, l_code);
    
        IF NOT i_demo
        THEN
        
            IF l_return IS NULL
            THEN
                l_return := get_desc_room(i_lang, l_id_room);
            END IF;
        
        END IF;
    
        RETURN l_return;
    
    END get_message_desc_machine;

    FUNCTION get_url_photo
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_id_patient IN NUMBER
    ) RETURN VARCHAR2 IS
    
        l_return VARCHAR2(4000);
    
    BEGIN
    
        IF i_prof.id != 0
        THEN
            l_return := pk_patphoto.get_pat_photo(i_lang, i_prof, i_id_patient, NULL, NULL);
        ELSE
            l_return := pk_wlpatient.get_pat_pub_foto(i_id_patient, i_prof);
        END IF;
    
        RETURN l_return;
    
    END get_url_photo;

    FUNCTION get_pat_gender(i_id_patient IN NUMBER) RETURN VARCHAR2 IS
    
        tbl_gender table_varchar;
    
        l_return VARCHAR2(4000);
    
    BEGIN
    
        SELECT gender
          BULK COLLECT
          INTO tbl_gender
          FROM patient
         WHERE id_patient = i_id_patient;
    
        IF tbl_gender.count > 0
        THEN
            l_return := tbl_gender(1);
        END IF;
    
        RETURN l_return;
    
    END get_pat_gender;

    FUNCTION get_tit_pat_visual
    (
        i_lang       IN NUMBER,
        i_tit_mens   IN NUMBER,
        i_id_patient IN NUMBER
    ) RETURN VARCHAR2 IS
    
        l_return VARCHAR2(4000);
        l_gender VARCHAR2(0100 CHAR);
        l_code   VARCHAR2(0200 CHAR);
    
    BEGIN
    
        IF i_tit_mens = 1
        THEN
            l_gender := get_pat_gender(i_id_patient);
        
            g_error := 'GET PATIENT DATA';
            pk_alertlog.log_debug(g_error, g_package_name);
            IF l_gender = 'M'
            THEN
                l_code := 'MED_MSG_TIT_01';
            ELSE
                l_code := 'MED_MSG_TIT_02';
            END IF;
        
            l_return := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code);
        
        END IF;
    
        RETURN l_return;
    
    END get_tit_pat_visual;

    /********************************************************************************************
    *
    * Gets the next ticket to be called of the specified queue, or of all available queues if i_id_queue is null.
    *
    * @param      i_lang                language    ID;
    * @param      i_id_mach             ID of the Screen machine searching for the next ticket;
    * @param      i_id_queue            ID of the queue where to look for more tickets;
    * @param      i_flg_type            Type of the call: A - Admin (only displays the ticket number and the destination) or M - Clinical (displays the patient's name, photo and service where to head to);
    * @param      i_prf                 ID of the professional;
    * @param      o_message_audio       Message to be converted into an audio file.
    * @param      o_message_sound_file     ID of the professional;
    * @param      o_message_video       Messagf
    * @param      o_error               ID of the professional;
    *
    * @RETURN  The ID of the language.
    * @author  Ricardo Nuno Almeida
    * @version 2.5.0.7
    * @since   03-03-2009
    **********************************************************************************************/
    FUNCTION get_item_call_queue
    (
        i_lang               IN NUMBER,
        i_id_mach            IN NUMBER,
        i_id_queue           IN NUMBER,
        i_prf                IN profissional,
        o_message_audio      OUT VARCHAR2,
        o_message_sound_file OUT VARCHAR2,
        o_message_video      OUT pk_types.cursor_type,
        o_flg_type           OUT VARCHAR2,
        o_item_call_queue    OUT NUMBER,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_time_unit VARCHAR2(10) := 'MINUTE';
        l_time_val  NUMBER := -5;
        l_demo      BOOLEAN := FALSE;
    
        CURSOR c_get_item(id_mach IN NUMBER) IS
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
                       AND w.flg_status = pk_pendente
                       AND w.dt_gen_sound_file_tstz IS NOT NULL
                       AND w.dt_gen_sound_file_tstz >=
                           pk_date_utils.add_to_ltstz(current_timestamp, l_time_val, l_time_unit)
                    
                     ORDER BY w.dt_gen_sound_file_tstz ASC)
             WHERE rownum = 1
               AND i_id_queue < 0
            UNION ALL
            SELECT w.id_call_queue,
                   w.message,
                   w.sound_file,
                   w.id_wl_waiting_line,
                   w.id_wl_machine_dest,
                   w.dt_gen_sound_file_tstz,
                   w.flg_type
              FROM wl_call_queue w
             WHERE w.id_wl_machine = id_mach
               AND w.flg_status = pk_pendente
               AND w.dt_gen_sound_file_tstz IS NOT NULL
               AND w.dt_gen_sound_file_tstz >= pk_date_utils.add_to_ltstz(current_timestamp, l_time_val, l_time_unit)
               AND w.id_call_queue = i_id_queue
               AND i_id_queue > -1;
    
        TYPE c_get_item_type IS TABLE OF c_get_item%ROWTYPE;
        tuplo c_get_item_type;
    
        l_message_desc_machine pk_translation.t_desc_translation;
        l_audio_active         wl_machine.flg_audio_active%TYPE;
        l_ok                   PLS_INTEGER;
        l_rows                 table_varchar;
    
        l_titulo_mens       sys_config.value%TYPE;
        l_wav_bip           sys_config.value%TYPE;
        l_tit_pat_visual    sys_message.desc_message%TYPE;
        l_url_photo         VARCHAR2(4000);
        l_label_name        sys_message.desc_message%TYPE;
        l_label_room        sys_message.desc_message%TYPE;
        l_triage_color      epis_info.triage_acuity%TYPE;
        l_triage_color_text epis_info.triage_acuity%TYPE;
    
        xtmp            sys_message.code_message%TYPE;
        l_ret           BOOLEAN;
        xwle            wl_waiting_line%ROWTYPE;
        l_hand_off_type sys_config.value%TYPE;
    
        l_id_institution     NUMBER;
        l_prof               profissional;
        l_flg_name_or_number VARCHAR2(0200 CHAR);
    
        PROCEDURE set_profissional_type IS
        BEGIN
        
            l_id_institution := get_inst_from_mach(i_id_machine => i_id_mach);
        
            l_prof := profissional(i_prf.id, l_id_institution, i_prf.software);
        
        END set_profissional_type;
    
        PROCEDURE set_sys_configs IS
        BEGIN
        
            l_wav_bip            := pk_sysconfig.get_config(i_code_cf => pk_wl_wav_bip_name, i_prof => l_prof);
            l_demo               := pk_sysconfig.get_config(g_wl_demo_flg, l_prof) = k_yes;
            l_titulo_mens        := pk_sysconfig.get_config(i_code_cf => pk_wl_titulo, i_prof => l_prof);
            l_flg_name_or_number := pk_sysconfig.get_config(i_code_cf => 'WL_CALL_BY_NAME_OR_NUMBER', i_prof => l_prof);
        
        END set_sys_configs;
    
        PROCEDURE get_color_triage(i_id_episode IN NUMBER) IS
            tbl_color table_varchar;
            tbl_text  table_varchar;
        BEGIN
        
            l_triage_color      := NULL;
            l_triage_color_text := NULL;
        
            IF xwle.id_episode IS NOT NULL
            THEN
            
                SELECT ei.triage_acuity, ei.triage_color_text
                  BULK COLLECT
                  INTO tbl_color, tbl_text
                  FROM epis_info ei
                 WHERE ei.id_episode = i_id_episode;
            
                IF tbl_color.count > 0
                THEN
                    l_triage_color      := tbl_color(1);
                    l_triage_color_text := tbl_text(1);
                END IF;
            
            END IF;
        
        END get_color_triage;
    
        PROCEDURE get_message_video
        (
            i_mode          IN NUMBER,
            i_id_queue      IN NUMBER,
            i_id_episode    IN NUMBER,
            i_id_patient    IN NUMBER,
            i_char_queue    IN VARCHAR2,
            i_num_queue     IN NUMBER,
            o_message_video OUT pk_types.cursor_type
        ) IS
        
            l_color VARCHAR2(0100 CHAR);
        
            FUNCTION get_color RETURN VARCHAR2 IS
                tbl_color table_varchar;
                l_return  VARCHAR2(0100 CHAR);
            BEGIN
            
                SELECT q.color
                  BULK COLLECT
                  INTO tbl_color
                  FROM wl_queue q
                  JOIN wl_queue_group qg
                    ON qg.id_wl_queue_group = q.id_wl_queue_group
                  JOIN wl_queue qq
                    ON qq.id_wl_queue_group = qg.id_wl_queue_group
                 WHERE q.char_queue = i_char_queue
                   AND qq.id_wl_queue = i_id_queue;
            
                IF tbl_color.count > 0
                THEN
                    l_return := tbl_color(1);
                END IF;
            
                RETURN l_return;
            
            END get_color;
        
        BEGIN
        
            IF i_mode = 1
            THEN
            
                OPEN o_message_video FOR
                    SELECT pk_wlcore.get_queue_color(i_lang, l_prof, color) color,
                           xwle.char_queue char_queue,
                           xwle.number_queue number_queue,
                           l_message_desc_machine desc_machine,
                           pk_alert_constant.g_color_icon_light_grey triage_color,
                           pk_alert_constant.g_color_black triage_color_text,
                           NULL titulo,
                           NULL label_name,
                           NULL label_room,
                           NULL nome,
                           NULL url_photo
                      FROM wl_queue
                     WHERE id_wl_queue = i_id_queue;
            
            ELSE
            
                l_color := pk_wlcore.get_queue_color(i_lang, l_prof, get_color());
            
                OPEN o_message_video FOR
                    SELECT l_tit_pat_visual titulo,
                           l_label_name label_name,
                           l_label_room label_room,
                           decode(l_flg_name_or_number,
                                  'NUMBER',
                                  pk_adt.get_ticket_number(i_lang, l_prof, i_id_episode),
                                  pk_adt.get_patient_name_to_sort(i_lang, l_prof, i_id_patient, pk_adt.g_false)) nome,
                           l_message_desc_machine desc_machine,
                           decode(l_flg_name_or_number, 'NUMBER', NULL, l_url_photo) url_photo,
                           l_triage_color triage_color,
                           nvl(l_triage_color_text, pk_alert_constant.g_color_black) triage_color_text,
                           l_color color,
                           i_char_queue char_queue,
                           i_num_queue number_queue
                      FROM dual;
            END IF;
        
        END get_message_video;
    
        PROCEDURE update_table
        (
            i_flg_status IN VARCHAR2,
            i_wl         IN NUMBER
        ) IS
        
        BEGIN
        
            IF i_flg_status IN (pk_alert_constant.g_wr_wl_status_h, pk_alert_constant.g_wr_wl_status_n)
            THEN
                ts_wl_waiting_line.upd(id_wl_waiting_line_in => i_wl,
                                       dt_call_tstz_in       => current_timestamp,
                                       dt_call_tstz_nin      => FALSE,
                                       rows_out              => l_rows);
            
            ELSE
                ts_wl_waiting_line.upd(id_wl_waiting_line_in => i_wl,
                                       dt_call_tstz_in       => current_timestamp,
                                       dt_call_tstz_nin      => FALSE,
                                       flg_wl_status_in      => pk_alert_constant.g_wr_wl_status_x,
                                       flg_wl_status_nin     => FALSE,
                                       rows_out              => l_rows);
            END IF;
        
        END update_table;
    
        FUNCTION get_pat_by_episode(i_id_episode IN NUMBER) RETURN NUMBER IS
        
            tbl_id   table_number;
            l_return NUMBER;
        
        BEGIN
        
            SELECT v.id_patient
              BULK COLLECT
              INTO tbl_id
              FROM episode e
              JOIN visit v
                ON v.id_visit = e.id_visit
             WHERE e.id_episode = i_id_episode;
        
            IF tbl_id.count > 0
            THEN
                l_return := tbl_id(1);
            END IF;
        
            RETURN l_return;
        
        END get_pat_by_episode;
    
        FUNCTION get_desc_room
        (
            i_lang    IN NUMBER,
            i_machine IN VARCHAR2
        ) RETURN VARCHAR2 IS
            tbl_name table_varchar;
            l_name   VARCHAR2(4000);
        BEGIN
        
            SELECT coalesce(pk_translation.get_translation(i_lang, r.code_room), r.desc_room) desc_room
              BULK COLLECT
              INTO tbl_name
              FROM wl_machine m
              JOIN room r
                ON r.id_room = m.id_room
             WHERE m.id_wl_machine = i_machine;
        
            IF tbl_name.count > 0
            THEN
                l_name := tbl_name(1);
            END IF;
        
            RETURN l_name;
        
        END get_desc_room;
    
    BEGIN
    
        g_error := 'CALL pk_hand_off_core.get_hand_off_type';
        pk_alertlog.log_debug(g_error);
    
        set_profissional_type();
    
        pk_hand_off_core.get_hand_off_type(i_lang => i_lang, i_prof => l_prof, io_hand_off_type => l_hand_off_type);
    
        set_sys_configs();
    
        g_error := 'GET AUDIO CONFIG FOR CURRENT MACHINE';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        l_audio_active := get_flg_audio(i_id_mach);
    
        -- Importante por causa do Flash
        o_message_audio      := 'null';
        o_message_sound_file := 'null';
        o_flg_type           := NULL;
    
        g_error := 'OPEN CURSOR OF SCREEN MACHINES';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        OPEN c_get_item(i_id_mach);
        FETCH c_get_item BULK COLLECT
            INTO tuplo;
        CLOSE c_get_item;
    
        <<lup_thru_call_queue>>
        FOR i IN 1 .. tuplo.count
        LOOP
        
            -- ADM
            o_message_audio      := tuplo(i).message;
            o_message_sound_file := NULL;
        
            xwle := get_waiting_line_row(tuplo(i).id_wl_waiting_line);
            IF xwle.id_episode IS NOT NULL
            THEN
                xwle.id_patient := get_pat_by_episode(xwle.id_episode);
            END IF;
            IF l_audio_active IN (pk_voice, pk_bip)
            THEN
                -- a maquina fala ou emite bip
                o_message_sound_file := tuplo(i).sound_file;
            END IF;
        
            get_color_triage(xwle.id_episode);
        
            g_error := 'GET MACHINE DATA';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            l_message_desc_machine := get_message_desc_machine(i_lang, l_demo, tuplo(i).id_wl_machine_dest);
        
            o_flg_type := tuplo(i).flg_type;
        
            IF tuplo(i).flg_type = 'A'
            THEN
            
                l_message_desc_machine := get_message_desc_machine(i_lang, l_demo, tuplo(i).id_wl_machine_dest);
            
                get_message_video(i_mode          => 1,
                                  i_id_queue      => xwle.id_wl_queue,
                                  i_id_episode    => NULL,
                                  i_id_patient    => NULL,
                                  i_char_queue    => NULL,
                                  i_num_queue     => NULL,
                                  o_message_video => o_message_video);
            
            ELSE
            
                IF l_flg_name_or_number = 'NAME'
                THEN
                    l_url_photo      := get_url_photo(i_lang, l_prof, xwle.id_patient);
                    l_tit_pat_visual := get_tit_pat_visual(i_lang, l_titulo_mens, xwle.id_patient);
                ELSE
                    l_url_photo      := NULL;
                    l_tit_pat_visual := NULL;
                END IF;
            
                l_label_room           := pk_message.get_message(i_lang => i_lang, i_code_mess => pk_med_msg_02);
                l_message_desc_machine := get_desc_room(i_lang, tuplo(i).id_wl_machine_dest);
            
                get_message_video(i_mode          => 2,
                                  i_id_queue      => xwle.id_wl_queue,
                                  i_id_episode    => xwle.id_episode,
                                  i_id_patient    => xwle.id_patient,
                                  i_char_queue    => xwle.char_queue,
                                  i_num_queue     => xwle.number_queue,
                                  o_message_video => o_message_video);
            
            END IF;
        
            UPDATE wl_call_queue
               SET flg_status = pk_t_status
             WHERE id_call_queue = tuplo(i).id_call_queue;
        
            o_item_call_queue := tuplo(i).id_call_queue;
        
            pk_alertlog.log_debug(g_error);
            update_table(i_flg_status => xwle.flg_wl_status, i_wl => tuplo(i).id_wl_waiting_line);
        
        END LOOP lup_thru_call_queue;
    
        g_error := 'PROCESS UPDATE';
        pk_alertlog.log_debug(g_error);
        t_data_gov_mnt.process_update(i_lang, l_prof, 'WL_WAITING_LINE', l_rows, o_error);
    
        IF tuplo.count = 0
        THEN
            pk_types.open_my_cursor(o_message_video);
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ITEM_CALL_QUEUE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_message_video);
            RETURN FALSE;
    END get_item_call_queue;

    /********************************************************************************
    FUNCTION: SEARCH_TABLE_NUMBER
    GOAL    : DEVOLVE O INDICE NA TABLE DO I_SEARCH
    PARAM IN: I_TABLE TABLE_NUMBER: TABLE DE NUMBER
              I_SEARCH NUMBER     : NUMBER A PROCURAR
    RETURN NUMBER: INDICE RESULTANTE
    *********************************************************************************/
    FUNCTION search_table_number
    (
        i_table  IN table_number,
        i_search IN NUMBER
    ) RETURN NUMBER IS
    
        l_indice NUMBER;
    
    BEGIN
    
        l_indice := -1;
    
        FOR i IN 1 .. i_table.count
        LOOP
        
            IF i_table(i) = i_search
            THEN
                l_indice := i;
                EXIT;
            END IF;
        
        END LOOP;
    
        RETURN l_indice;
    
    END search_table_number;

    /********************************************************************************************
     *
     *  Function called by Jobs to reset the provided queue.
     *
     * @param x_id_queue              ID of the Queue to clean.
     * @param x_num_queue             Initial value of the queue number.
     *
     * @return                         true or false
     *
     * @author                          ?
     * @version                         0.1
     * @since                           ?
    **********************************************************************************************/
    PROCEDURE clean_queues
    (
        x_id_queue  IN NUMBER,
        x_num_queue IN NUMBER,
        o_error     OUT t_error_out
    ) IS
    
        l_dt_reset TIMESTAMP(6) WITH LOCAL TIME ZONE;
    
        CURSOR queue_c(i_id_queue IN NUMBER) IS
            SELECT *
              FROM wl_queue
             WHERE id_wl_queue = i_id_queue
               AND i_id_queue IS NOT NULL
            UNION ALL
            SELECT *
              FROM wl_queue
             WHERE i_id_queue IS NULL;
    
    BEGIN
    
        -- ***********************************************************
        -- PARA EXECUTAR NO PROPRIO DIA ANTES DE COMEÇAR AS CONSULTAS
        -- **********************************************************
    
        DELETE wl_call_queue;
    
        DELETE wl_patient_sonho;
    
        FOR xcur IN queue_c(i_id_queue => x_num_queue)
        LOOP
        
            l_dt_reset := xcur.dt_last_reset + numtodsinterval(xcur.days_for_reset, 'DAY');
        
            IF l_dt_reset < current_timestamp
            THEN
            
                UPDATE wl_queue
                   SET num_queue = nvl(init_num_queue, 0), dt_last_reset = current_timestamp
                 WHERE id_wl_queue = xcur.id_wl_queue;
            
            END IF;
        
        END LOOP;
    
        IF trunc(current_timestamp) >= last_day(trunc(current_timestamp))
        THEN
        
            DELETE sys_error;
        
            DELETE sys_request;
        
            DELETE sys_session;
        
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(1,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CLEAN_QUEUES',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN;
    END clean_queues;

    PROCEDURE clean_queues
    (
        x_id_queue  IN NUMBER,
        x_num_queue IN NUMBER
    ) IS
    
        l_err t_error_out;
    
    BEGIN
    
        clean_queues(x_id_queue => x_id_queue, x_num_queue => x_num_queue, o_error => l_err);
    
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line('CLEAN_QUEUES: ' || l_err.ora_sqlcode || '-' || l_err.ora_sqlerrm);
    END clean_queues;

    /********************************************************************************************
    *
    *  Get_timestamp_anytimezone criteria
    *
    * @param      I_LANG                       Prefered language ID for this professional
    * @param      I_TIMEZONE                   Timezone to which we want to convert the date
    * @param      O_TIMESTAMP                  Timestamp variable output
    * @param      O_TIMESTAMP_STR              Timestamp variable ouput as string
    * @param      O_ERROR                      error
    *
    * @return     true or false
    * @author     Ricardo Nuno Almeida
    * @version    2.5.0.7
    * @since      2010/01/04
    */
    FUNCTION get_timestamp_anytimezone
    (
        i_lang          IN language.id_language%TYPE,
        i_inst          IN institution.id_institution%TYPE,
        o_timestamp     OUT TIMESTAMP WITH TIME ZONE,
        o_timestamp_str OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error     := 'CALL GET_TIME_STAMP_ANYTIMEZONE';
        o_timestamp := pk_date_utils.get_timestamp_insttimezone(i_lang => i_lang, i_inst => i_inst);
    
        o_timestamp_str := pk_date_utils.date_send_tsz(i_lang => i_lang,
                                                       i_date => o_timestamp,
                                                       i_prof => profissional(0, i_inst, 0));
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(g_language_num,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TIMESTAMP_ANYTIMEZONE',
                                              o_error);
            RETURN FALSE;
    END get_timestamp_anytimezone;

    /********************************************************************************************
     *
     *  Returns the Ads to be displayed on a Screen, for the provided department and machine.
     *
     * @param i_lang                  i_lang
     * @param i_prof                  ID of the professional asking
     * @param i_id_wl_machine         ID of machine
     * @param o_error
     * @param o_ads                   Cursor with the advertisement files.
     *
     * @return                         true or false
     *
     * @author                          Ricardo Nuno Almeida
     * @version                         0.1
     * @since                           10-02-2009
    **********************************************************************************************/
    FUNCTION get_ad
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_wl_machine IN wl_machine.id_wl_machine%TYPE,
        o_error         OUT t_error_out,
        o_ads           OUT pk_types.cursor_type
    ) RETURN BOOLEAN IS
    
        l_lang language.id_language%TYPE;
        l_demo BOOLEAN := FALSE;
    
    BEGIN
    
        l_demo := pk_sysconfig.get_config(g_wl_demo_flg, i_prof.institution, i_prof.software) = pk_alert_constant.g_yes;
    
        g_error := 'GET LANGUAGE';
        IF i_lang IS NULL
        THEN
            l_lang := pk_sysconfig.get_config(pk_wl_lang, i_prof);
        ELSE
            l_lang := i_lang;
        END IF;
    
        g_error := 'OPEN CURSOR o_ads';
        IF l_demo
        THEN
            -- for demo porpose, any ad it is fine
            OPEN o_ads FOR
                SELECT wt.file_name
                  FROM wl_machine wm
                 INNER JOIN wl_topics wt
                    ON wt.id_department = (SELECT MAX(id_department)
                                             FROM wl_topics wt)
                   AND wm.id_wl_queue_group = wm.id_wl_queue_group
                 WHERE wt.flg_active = pk_alert_constant.g_yes
                   AND wm.id_wl_machine = i_id_wl_machine
                   AND wt.id_language = l_lang
                 ORDER BY wt.rank;
        ELSE
            OPEN o_ads FOR
                SELECT wt.file_name
                  FROM wl_machine wm
                 INNER JOIN room r
                    ON r.id_room = wm.id_room
                 INNER JOIN wl_topics wt
                    ON wt.id_department = r.id_department
                   AND wm.id_wl_queue_group = wm.id_wl_queue_group
                 WHERE wt.flg_active = pk_alert_constant.g_yes
                   AND wm.id_wl_machine = i_id_wl_machine
                   AND wt.id_language = l_lang
                 ORDER BY wt.rank;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(g_language_num,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_AD',
                                              o_error);
        
            RETURN FALSE;
    END get_ad;

    /********************************************************************************************
     *
     *  Returns the ID from the WR software
     *
     *
     * @return                         NUMBER representing the ID of the WR software
     *
     * @author                          Ricardo Nuno Almeida
     * @version                         1.0
     * @since                           03-03-2009
    **********************************************************************************************/
    FUNCTION get_id_software RETURN NUMBER IS
    
        xid_software software.id_software%TYPE;
    
    BEGIN
    
        SELECT id_software
          INTO xid_software
          FROM software
         WHERE intern_name = 'WL';
    
        RETURN xid_software;
    
    END get_id_software;

    /********************************************************************************************
     *
     *  Returns the ID from the WR software
     *
     *
     * @param o_id_software            ID of the software.
     *
     * @return                         true or false
     *
     * @author                          Ricardo Nuno Almeida
     * @version                         1.0
     * @since                           03-03-2009
    **********************************************************************************************/
    FUNCTION get_id_software
    (
        o_id_software OUT software.id_software%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        o_id_software := get_id_software();
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(1,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ID_SOFTWARE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_id_software;

    /********************************************************************************************
    *
    * Gets Waiting Room software id.
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   O_ID_SOFTWARE The software id associated with the Waiting Room
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Luís Gaspar
    * @version 1.0
    * @since   14-11-2006
    */
    FUNCTION get_id_software
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_id_software OUT software.id_software%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_wr_soft_config VARCHAR2(24);
    
    BEGIN
    
        g_error          := 'GET SYS_CONFIG SOFTWARE_ID_WR';
        l_wr_soft_config := pk_sysconfig.get_config('SOFTWARE_ID_WR', i_prof);
    
        g_error := 'CHECK SOFTWARE ID';
        SELECT id_software
          INTO o_id_software
          FROM software
         WHERE id_software = l_wr_soft_config;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ID_SOFTWARE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_id_software;

    /********************************************************************************************
     *
     *  Returns a description of the institutions available
     *
     * @param i_prf                   The ALERT professional to be logged
     * @param o_dpt                   ID of the Institution
     *
     * @return                         true or false
     *
     * @author                          ?
     * @version                         0.1
     * @since                           ?
    **********************************************************************************************/
    FUNCTION get_institution
    (
        i_prf   IN profissional,
        o_ist   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_ret := pk_sysconfig.get_config(i_code_cf => 'WL_LANG', i_prof => i_prf, o_msg_cf => g_language_num);
    
        OPEN o_ist FOR
            SELECT id_institution,
                   nvl(pk_translation.get_translation(1, code_institution), abbreviation) desc_institution,
                   abbreviation
              FROM institution
             WHERE flg_available = pk_alert_constant.g_yes
             ORDER BY rank, desc_institution;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_ret := pk_alert_exceptions.process_error(g_language_num,
                                                       SQLCODE,
                                                       SQLERRM,
                                                       g_error,
                                                       g_package_owner,
                                                       g_package_name,
                                                       'GET_INSTITUTION',
                                                       o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_ist);
            RETURN FALSE;
    END get_institution;

    /********************************************************************************************
     *
     *  Returns a description of all departments available for WR.
     *
     * @param i_prf                   The ALERT professional to be logged
     * @param o_dpt                ID of the Department
     *
     * @return                         true or false
     *
     * @author                          ?
     * @version                         0.1
     * @since                           ?
    **********************************************************************************************/
    FUNCTION get_department
    (
        i_prf   IN profissional,
        o_dpt   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_ret := pk_sysconfig.get_config(i_code_cf => 'WL_LANG', i_prof => i_prf, o_msg_cf => g_language_num);
    
        OPEN o_dpt FOR
            SELECT d.id_department,
                   pk_translation.get_translation(1, d.code_department) desc_department,
                   d.abbreviation
              FROM department d
             WHERE d.id_institution = i_prf.institution
               AND d.flg_available = g_flg_available
               AND instr(d.flg_type, 'W') > 0
             ORDER BY d.rank, desc_department;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(g_language_num,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DEPARTMENT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_dpt);
            RETURN FALSE;
    END get_department;

    /********************************************************************************************
     *
     *  Logging function; registers the login of the professional in table prof_soft_inst
     *
     * @param i_prf                   The ALERT professional to be logged
     * @param i_id_dpt                ID of the Department
     * @param o_error
     *
     * @return                         true or false
     *
     * @author                          ?
     * @version                         0.1
     * @since                           2009/02/05
    **********************************************************************************************/
    FUNCTION set_default
    (
        i_prf    IN profissional,
        i_id_dpt IN department.id_department%TYPE,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        DELETE prof_soft_inst
         WHERE id_software = i_prf.software
           AND id_professional = i_prf.id;
    
        INSERT INTO prof_soft_inst
            (id_prof_soft_inst, id_professional, id_software, id_institution, flg_log, dt_log_tstz, id_department)
            SELECT seq_prof_soft_inst.nextval, i_prf.id, i_prf.software, i_prf.institution, 'N', NULL, i_id_dpt
              FROM dual;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(1,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_DEFAULT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_default;

    /********************************************************************************************
     *
     *  Returns the messages that should appear on the kiosk.
     *  Note that the language provided may not be the same of the messages returned. Those will be translated to the language defined in SYS_CONFIG
     *
     * @param i_lang                   Language ID
     * @param i_prf                   The ALERT professional calling this function
     * @param o_sql                    Cursor containing the messages
     * @param o_error
     *
     * @return                         true or false
     *
     * @author                          Ricardo Nuno Almeida
     * @version                         0.1
     * @since                           2009/02/05
    **********************************************************************************************/
    FUNCTION get_kiosk_button
    (
        i_lang  IN language.id_language%TYPE,
        i_prf   IN profissional,
        o_sql   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_lang language.id_language%TYPE;
    
    BEGIN
    
        IF i_lang IS NOT NULL
           OR i_lang <> 0
        THEN
            l_lang := i_lang;
        ELSE
            l_lang := pk_wlcore.get_prof_default_language(i_prf);
        END IF;
    
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
            g_ret := pk_alert_exceptions.process_error(i_lang,
                                                       SQLCODE,
                                                       SQLERRM,
                                                       g_error,
                                                       g_package_owner,
                                                       g_package_name,
                                                       'GET_KIOSK_BUTTON',
                                                       o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_sql);
            RETURN FALSE;
    END get_kiosk_button;

    /********************************************************************************************
     *
     *  Returns the messages that should appear on the applet buttons.
     *
     * @param i_lang                   Language ID
     * @param i_prof                   The ALERT professional calling this function
     * @param o_error
     * @param o_sql                    Cursor containing the messages
     *
     * @return                         true or false
     *
     * @author                          Ricardo Nuno Almeida
     * @version                         0.1
     * @since                           2009/02/05
    **********************************************************************************************/
    FUNCTION get_applet_button
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out,
        o_sql   OUT pk_types.cursor_type
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET APPLET BUTTON';
        OPEN o_sql FOR
            SELECT pk_message.get_message(i_lang, i_prof, 'WL_APPLET_NEXT_BT_LBL') next_bt_lbl,
                   pk_message.get_message(i_lang, i_prof, 'WL_APPLET_CALL_BT_LBL') call_bt_lbl,
                   pk_message.get_message(i_lang, i_prof, 'WL_APPLET_BACK_BT_LBL') back_bt_lbl
              FROM dual;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            g_ret := pk_alert_exceptions.process_error(i_lang,
                                                       SQLCODE,
                                                       SQLERRM,
                                                       g_error,
                                                       g_package_owner,
                                                       g_package_name,
                                                       'GET_APPLET_BUTTON',
                                                       o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_sql);
            RETURN FALSE;
    END get_applet_button;

    /********************************************************************************************
     *
     *  Function used for WR-INT integration with the ambulatory. Should be invoked when a scheduled patient is admitted.
     *  NOTE: this function doesn't have a rollback, because even if it fails it should never compromise the execution on the main process. 
     *
     * @param i_lang                   Language ID
     * @param i_prof                   The ALERT professional calling this function
     * @param i_c_prof                 And "extra" professional, when necessary for the admission process.
     * @param i_pat                    The patient going through admission process
     * @param i_clin_serv                   Clinical service ID
     * @param i_epis                  The episode to be associated with the WR ticket.
     * @param i_dt_cons                 Date of the consult.
     * @param o_error                  Structure instanciated whenever there's an exception.
     *
     * @return                         true or false
     *
     * @author                          Ricardo Nuno Almeida
     * @version                         0.1
     * @since                           2009/03/12
    **********************************************************************************************/
    FUNCTION set_pat_admission
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_c_prof    IN professional.id_professional%TYPE,
        i_pat       IN patient.id_patient%TYPE,
        i_clin_serv IN clinical_service.id_clinical_service%TYPE,
        i_inst      IN institution.id_institution%TYPE,
        i_epis      IN episode.id_episode%TYPE,
        i_dt_cons   IN wl_waiting_line.dt_consult_tstz%TYPE,
        o_id_wl     OUT wl_waiting_line.id_wl_waiting_line%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_prof_cat category.flg_type%TYPE;
        l_id_dep   department.id_department%TYPE;
        l_id_wq    wl_queue.id_wl_queue%TYPE;
        l_id_mach  wl_machine.id_wl_machine%TYPE;
        l_wr       room.id_room%TYPE;
        l_et       episode.id_epis_type%TYPE;
    
        l_rows table_varchar := table_varchar();
    
    BEGIN
        g_error := 'GET PROF CAT';
        pk_alertlog.log_debug(g_error, g_package_name);
        SELECT c.flg_type
          INTO l_prof_cat
          FROM prof_cat pc
         INNER JOIN category c
            ON pc.id_category = c.id_category
         WHERE pc.id_professional = i_c_prof
           AND pc.id_institution = i_inst;
    
        IF l_prof_cat IN ('A', 'O')
        THEN
            g_error := 'GET EPIS TYPE';
            SELECT e.id_epis_type
              INTO l_et
              FROM episode e
             WHERE e.id_episode = i_epis;
        
            IF l_et IN (g_flg_epis_type_nurse_care, g_flg_epis_type_nurse_outp, g_flg_epis_type_nurse_pp)
            THEN
                g_error := 'ADMIT NURSE CONSULT';
                pk_alertlog.log_debug(g_error, g_package_name);
                SELECT DISTINCT wq.id_wl_queue, dcs.id_department, wwr.id_room_wait
                  INTO l_id_wq, l_id_dep, l_wr
                  FROM wl_queue wq
                 INNER JOIN dep_clin_serv dcs
                    ON wq.id_department = dcs.id_department
                   AND dcs.id_clinical_service = i_clin_serv
                 INNER JOIN department d
                    ON d.id_department = dcs.id_department
                 INNER JOIN room r
                    ON r.id_department = dcs.id_department
                 INNER JOIN wl_machine wm
                    ON wm.id_wl_queue_group = wq.id_wl_queue_group
                   AND r.id_room = wm.id_room
                 INNER JOIN prof_room pr
                    ON pr.id_room = r.id_room
                   AND pr.id_professional = i_c_prof
                 INNER JOIN wl_waiting_room wwr
                    ON wwr.id_room_consult = pr.id_room
                 WHERE wq.flg_type_queue = pk_alert_constant.g_wr_wq_type_n
                   AND d.id_institution = i_prof.institution;
            
                g_error := 'INSERT TICKET';
                pk_alertlog.log_debug(g_error, g_package_name);
                o_id_wl := ts_wl_waiting_line.next_key;
                ts_wl_waiting_line.ins(id_wl_waiting_line_in  => o_id_wl,
                                       id_clinical_service_in => i_clin_serv,
                                       id_professional_in     => i_c_prof,
                                       id_wl_queue_in         => l_id_wq,
                                       id_patient_in          => i_pat,
                                       id_room_in             => l_wr,
                                       id_episode_in          => i_epis,
                                       dt_begin_tstz_in       => current_timestamp,
                                       dt_consult_tstz_in     => i_dt_cons,
                                       flg_wl_status_in       => pk_alert_constant.g_wr_wl_status_a,
                                       rows_out               => l_rows);
            
            ELSE
                --Admission by registar: must only fill interface table; WR-INT will make the rest.
                g_error := 'INSERT INTO SONHO';
                pk_alertlog.log_debug(g_error, g_package_name);
                INSERT INTO wl_patient_sonho
                    (patient_id, clin_prof_id, consult_id, prof_id, id_institution, id_episode, dt_consult_tstz)
                VALUES
                    (i_pat, i_c_prof, i_clin_serv, i_prof.id, i_inst, i_epis, i_dt_cons);
            END IF;
        
        ELSIF l_prof_cat = 'D'
        THEN
        
            g_error := 'GET DOCTOR QUEUE, DEPARTMENT AND WR';
            pk_alertlog.log_debug(g_error, g_package_name);
            --Admission by a doctor. As it is very unlikely that WR-INT will be available, 
            --it is necessary to create the WR ticket before applying the corresponding admission. 
            SELECT ep.id_department
              INTO l_id_dep
              FROM episode ep
             WHERE ep.id_episode = i_epis;
        
            g_error := 'GET WL_MACHINE';
            pk_alertlog.log_debug(g_error, g_package_name);
            IF NOT pk_wlcore.get_prof_wl_mach(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              io_dep       => l_id_dep,
                                              o_id_wl_mach => l_id_mach,
                                              o_id_wl_room => l_wr,
                                              o_error      => o_error)
            THEN
                RAISE no_data_found;
            END IF;
        
            g_error := 'GET WL_QUEUE FOR WL_MACH ' || l_id_mach;
            pk_alertlog.log_debug(g_error, g_package_name);
            SELECT wq.id_wl_queue
              INTO l_id_wq
              FROM wl_queue wq
             INNER JOIN wl_machine wm
                ON wm.id_wl_queue_group = wq.id_wl_queue_group
             WHERE wq.id_department = l_id_dep
               AND wm.id_wl_machine = l_id_mach
               AND wq.flg_type_queue = pk_alert_constant.g_wr_wq_type_d;
        
            g_error := 'INSERT TICKET';
            pk_alertlog.log_debug(g_error, g_package_name);
            o_id_wl := ts_wl_waiting_line.next_key;
            ts_wl_waiting_line.ins(id_wl_waiting_line_in  => o_id_wl,
                                   id_clinical_service_in => i_clin_serv,
                                   id_professional_in     => i_c_prof,
                                   id_wl_queue_in         => l_id_wq,
                                   id_patient_in          => i_pat,
                                   id_room_in             => l_wr,
                                   id_episode_in          => i_epis,
                                   dt_begin_tstz_in       => current_timestamp,
                                   dt_consult_tstz_in     => i_dt_cons,
                                   flg_wl_status_in       => pk_alert_constant.g_wr_wl_status_a,
                                   rows_out               => l_rows);
        
        ELSIF l_prof_cat = 'N'
        THEN
            g_error := 'GET EPIS TYPE';
            pk_alertlog.log_debug(g_error, g_package_name);
            SELECT e.id_epis_type
              INTO l_et
              FROM episode e
             WHERE e.id_episode = i_epis;
        
            IF l_et IN (g_flg_epis_type_nurse_care, g_flg_epis_type_nurse_outp, g_flg_epis_type_nurse_pp)
            THEN
                g_error := 'GET NURSE QUEUE, DEPARTMENT AND WR';
                pk_alertlog.log_debug(g_error, g_package_name);
                SELECT DISTINCT wq.id_wl_queue, dcs.id_department, wwr.id_room_wait
                  INTO l_id_wq, l_id_dep, l_wr
                  FROM wl_queue wq
                 INNER JOIN dep_clin_serv dcs
                    ON wq.id_department = dcs.id_department
                   AND dcs.id_clinical_service = i_clin_serv
                 INNER JOIN department d
                    ON d.id_department = dcs.id_department
                 INNER JOIN room r
                    ON r.id_department = dcs.id_department
                 INNER JOIN wl_machine wm
                    ON wm.id_wl_queue_group = wq.id_wl_queue_group
                   AND r.id_room = wm.id_room
                 INNER JOIN prof_room pr
                    ON pr.id_room = r.id_room
                   AND pr.id_professional = i_c_prof
                 INNER JOIN wl_waiting_room wwr
                    ON wwr.id_room_consult = pr.id_room
                 WHERE wq.flg_type_queue = pk_alert_constant.g_wr_wq_type_c
                   AND d.id_institution = i_prof.institution
                   AND pr.flg_pref = pk_alert_constant.g_yes;
            
            ELSE
                g_error := 'GET NURSE QUEUE, DEPARTMENT AND WR';
                pk_alertlog.log_debug(g_error, g_package_name);
                SELECT DISTINCT wq.id_wl_queue, dcs.id_department, wwr.id_room_wait
                  INTO l_id_wq, l_id_dep, l_wr
                  FROM wl_queue wq
                 INNER JOIN dep_clin_serv dcs
                    ON wq.id_department = dcs.id_department
                   AND dcs.id_clinical_service = i_clin_serv
                 INNER JOIN department d
                    ON d.id_department = dcs.id_department
                 INNER JOIN room r
                    ON r.id_department = dcs.id_department
                 INNER JOIN wl_machine wm
                    ON wm.id_wl_queue_group = wq.id_wl_queue_group
                   AND r.id_room = wm.id_room
                 INNER JOIN prof_room pr
                    ON pr.id_room = r.id_room
                   AND pr.id_professional = i_c_prof
                 INNER JOIN wl_waiting_room wwr
                    ON wwr.id_room_consult = pr.id_room
                 WHERE wq.flg_type_queue = pk_alert_constant.g_wr_wq_type_n
                   AND d.id_institution = i_prof.institution
                   AND pr.flg_pref = pk_alert_constant.g_yes;
            END IF;
        
            g_error := 'INSERT TICKET';
            o_id_wl := ts_wl_waiting_line.next_key;
            pk_alertlog.log_debug(g_error, g_package_name);
        
            ts_wl_waiting_line.ins(id_wl_waiting_line_in  => o_id_wl,
                                   id_clinical_service_in => i_clin_serv,
                                   id_professional_in     => i_c_prof,
                                   id_wl_queue_in         => l_id_wq,
                                   id_patient_in          => i_pat,
                                   id_room_in             => l_wr,
                                   id_episode_in          => i_epis,
                                   dt_begin_tstz_in       => current_timestamp,
                                   dt_consult_tstz_in     => i_dt_cons,
                                   flg_wl_status_in       => pk_alert_constant.g_wr_wl_status_a,
                                   rows_out               => l_rows);
        
        ELSE
            --unknown PROF_CAT. 
            g_error := 'UNKNOWN PROF_CAT';
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PAT_ADMISSION',
                                              o_error);
            RETURN FALSE;
        END IF;
    
        IF l_rows.count > 0
        THEN
            g_error := 'PROCESS INSERT WITH WL_WAITING_LINE ' || o_id_wl;
            pk_alertlog.log_debug(g_error, g_package_name);
            t_data_gov_mnt.process_insert(i_lang, i_prof, 'WL_WAITING_LINE', l_rows, o_error);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        --User is not correctly configured, but may not even use WR.
        --NEVER rollback. 
        WHEN no_data_found THEN
            o_id_wl := 0;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PAT_ADMISSION',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_pat_admission;

    /********************************************************************************************
     *  Mainly for usage in WR-INT, on the nurse's and physician's patient grids. Checks if a given episode 
     * is available to be called.
     *
     * @param flg_state 
     * @param flg_ehr 
     *
     * @return                         flg_state 
     *
     * @author                          marcio.dias
     * @version                         0.1
     * @since                           2012/02/08
    **********************************************************************************************/
    FUNCTION get_available_for_call
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_flg_state  IN schedule_outp.flg_state%TYPE,
        i_flg_ehr    IN episode.flg_ehr%TYPE
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        IF (pk_grid.get_schedule_real_state(i_flg_state, i_flg_ehr) = pk_visit.g_sched_scheduled OR
           i_flg_state = pk_grid.g_flg_no_show)
        THEN
            RETURN pk_alert_constant.g_no;
        ELSE
            RETURN pk_wlcore.get_available_for_call(i_lang, i_prof, i_id_episode);
        END IF;
    
    END get_available_for_call;

    /********************************************************************************************
     *  Mainly for usage in WR-INT, on the nurse's and physician's patient grids. Checks if a given episode 
     * is available to be called.
     *
     * @param i_lang 
     * @param i_prof 
     * @param i_id_episode 
     * @param i_flg_nurse_pre 
     *
     * @return                         true or false 
     *
     * @author                          Ricardo Nuno Almeida
     * @version                         0.1
     * @since                           2009/02/05
    **********************************************************************************************/
    FUNCTION get_available_for_call
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out,
        o_result     OUT VARCHAR2
    ) RETURN BOOLEAN IS
    
        l_ignore_wl  sys_config.value%TYPE := pk_sysconfig.get_config('IGNORE_WAITING_LINE_WORKFLOW', i_prof);
        l_cat        category.code_category%TYPE;
        l_acc        PLS_INTEGER := 0;
        l_dt_begin   TIMESTAMP WITH LOCAL TIME ZONE := pk_date_utils.trunc_insttimezone(i_prof, nvl(pk_date_utils.get_string_tstz(i_lang, i_prof, '', NULL), current_timestamp));
        l_dt_end     TIMESTAMP WITH LOCAL TIME ZONE := pk_date_utils.add_days_to_tstz(l_dt_begin, 1);
        l_wl_machine wl_machine.id_wl_machine%TYPE;
        l_room       room.id_room%TYPE;
        l_dep        department.id_department%TYPE;
    
    BEGIN
    
        g_error := 'CHECK EPISODE';
        pk_alertlog.log_debug(g_error, g_package_name);
        IF i_id_episode IS NULL
        THEN
            o_result := pk_alert_constant.g_no;
            RETURN TRUE;
        ELSE
            BEGIN
                SELECT epi.id_department
                  INTO l_dep
                  FROM episode epi
                 WHERE epi.id_episode = i_id_episode
                   AND epi.flg_status = pk_alert_constant.g_epis_status_active;
            EXCEPTION
                WHEN no_data_found THEN
                    o_result := pk_alert_constant.g_no;
                    RETURN TRUE;
            END;
        END IF;
    
        g_error := 'GET PROFESSIONAL CATEGORY';
        pk_alertlog.log_debug(g_error, g_package_name);
        l_cat := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
    
        IF l_cat IN ('A', 'O')
           OR l_ignore_wl = pk_alert_constant.g_yes
        THEN
            o_result := pk_alert_constant.g_yes;
            RETURN TRUE;
        END IF;
    
        g_error := 'CALL TO GET_PROF_WL_MACH';
        pk_alertlog.log_debug(g_error, g_package_name);
        IF NOT get_prof_wl_mach(i_lang       => i_lang,
                                i_prof       => i_prof,
                                io_dep       => l_dep,
                                o_id_wl_mach => l_wl_machine,
                                o_id_wl_room => l_room,
                                o_error      => o_error)
        THEN
            o_result := pk_alert_constant.g_no;
            RETURN TRUE;
        END IF;
    
        g_error := 'GET EXECUTE IMMEDIATE';
        pk_alertlog.log_debug(g_error, g_package_name);
        SELECT COUNT(wwl.id_wl_waiting_line)
          INTO l_acc
          FROM wl_waiting_line wwl
          JOIN wl_queue wq
            ON wwl.id_wl_queue = wq.id_wl_queue
          JOIN wl_machine wm
            ON wm.id_wl_queue_group = wq.id_wl_queue_group
           AND wm.id_wl_machine = l_wl_machine
          JOIN episode epis
            ON epis.id_episode = wwl.id_episode
         WHERE wwl.id_episode = i_id_episode
           AND wwl.dt_begin_tstz BETWEEN l_dt_begin AND l_dt_end
           AND (((wq.flg_type_queue = pk_alert_constant.g_wr_wq_type_c) AND (epis.id_epis_type IN (14, 16, 17))) OR
               (wq.flg_type_queue IN (pk_alert_constant.g_wr_wq_type_d, pk_alert_constant.g_wr_wq_type_n)));
    
        -- If there is one ticket in the DB that is associated to the given episode, it should be called.
        IF l_acc > 0
        THEN
            o_result := pk_alert_constant.g_yes;
        ELSE
            o_result := pk_alert_constant.g_no;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_AVAILABLE_FOR_CALL',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_available_for_call;

    FUNCTION get_available_for_call
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
    
        l_rez   VARCHAR2(1) := 'N';
        l_error t_error_out;
    
    BEGIN
    
        g_error := 'CALL MAIN FUNCTION';
        pk_alertlog.log_debug(g_error, g_package_name);
        IF NOT pk_wlcore.get_available_for_call(i_lang       => i_lang,
                                                i_prof       => i_prof,
                                                i_id_episode => i_id_episode,
                                                o_error      => l_error,
                                                o_result     => l_rez)
        
        THEN
            l_rez := 'N';
        END IF;
    
        RETURN l_rez;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_AVAILABLE_FOR_CALL',
                                              l_error);
        
            RETURN 'N';
    END get_available_for_call;

    /********************************************************************************************
     * Internal function to check if the value for wl_queue.char_queue needs to be altered in order to be
     * correctly read by Loquendo. Example: for the Portuguese language, the letter 'A' should be read like 'À'
     * 
     *
     * @param i_lang                   Language of the call
     * @param i_prof                   ALERT Professional  
     * @param i_char                   Char_Queue to be 
     * @param o_result                 The value for the char to be correctly read by Loquendo
     * @param o_error                  Error structure
     *
     * @return                         true or false for success
     *
     * @author                          Ricardo Nuno Almeida
     * @version                         2.5.0.6
     * @since                           2009/09/22
    **********************************************************************************************/
    FUNCTION get_wl_queue_char_queue
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_char   IN wl_queue.char_queue%TYPE,
        o_result OUT g_wl_queue_char,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CHECK CHAR_QUEUE';
        pk_alertlog.log_debug(g_error, g_error);
    
        IF i_lang = 1
        THEN
            --Portuguese             
            IF i_char = 'A'
            THEN
                o_result := 'Á';
            ELSIF i_char = 'E'
            THEN
                o_result := 'É';
            ELSIF i_char = 'I'
            THEN
                o_result := 'Í';
            ELSIF i_char = 'O'
            THEN
                o_result := 'Ó';
            ELSIF i_char = 'U'
            THEN
                o_result := 'Ú';
            ELSE
                o_result := i_char;
            END IF;
        
        ELSIF i_lang = 11
        THEN
            --Portuguese-BR            
            IF i_char = 'A'
            THEN
                o_result := 'Á';
            ELSIF i_char = 'E'
            THEN
                o_result := 'É';
            ELSIF i_char = 'I'
            THEN
                o_result := 'Í';
            ELSIF i_char = 'O'
            THEN
                o_result := 'Ó';
            ELSIF i_char = 'U'
            THEN
                o_result := 'Ú';
            ELSE
                o_result := i_char;
            END IF;
        ELSE
            --No rules to apply
            o_result := i_char;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_WL_QUEUE_CHAR_QUEUE',
                                              o_error);
        
            RETURN FALSE;
    END get_wl_queue_char_queue;

    /**
    * Ends admin ticket attending and creates support to nurse or doctor call .
    * Patients with "efectivação" are treated.
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_ID_PROF  professional, institution and software ids
    * @param   I_ID_MACH The machine name id.
    * @param   I_ID_PAT The patient  id.
    * @param   I_ID_ROOM The room id
    * @param   i_id_wl_queue ID of the ticket queue. To be used to get the department when this function is 
    *                        called by interface and it is not possible to have the registrar machine name 
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Luís Gaspar
    * @version 1.0
    * @since   15-11-2006
    */
    FUNCTION set_end_line_internal
    (
        i_lang        IN language.id_language%TYPE,
        i_id_prof     IN profissional,
        i_id_mach     IN wl_machine.id_wl_machine%TYPE,
        i_id_wait     IN wl_waiting_line.id_wl_waiting_line%TYPE,
        i_id_pat      IN table_number,
        i_id_room     IN table_number,
        i_id_wl_queue IN wl_queue.id_wl_queue%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_char_queue            pk_wlcore.g_wl_queue_char;
        c_get_sonhos            pk_types.cursor_type;
        l_id_episode            NUMBER;
        l_pat_sonho             NUMBER;
        l_id_queue              NUMBER;
        l_med_sonho             NUMBER;
        l_serv_sonho            NUMBER;
        l_id_wait_parent        NUMBER;
        l_indice_pat_room       NUMBER;
        l_id_room               NUMBER;
        l_id_nurse_queue        wl_queue.id_wl_queue%TYPE;
        l_dt_consult_sonho_tstz TIMESTAMP WITH LOCAL TIME ZONE;
        l_rows                  table_varchar;
        l_id_department         department.id_department%TYPE;
        l_id_queue_group        wl_queue.id_wl_queue_group%TYPE;
        internal_exception      EXCEPTION;
        l_invalid_arguments     EXCEPTION;
    
        l_demo BOOLEAN := FALSE;
    
    BEGIN
    
        l_demo := pk_sysconfig.get_config(g_wl_demo_flg, i_id_prof.institution, i_id_prof.software) =
                  pk_alert_constant.g_yes;
    
        IF i_id_wait IS NOT NULL
           AND i_id_wait != -1
        THEN
            -- lets consider attended the ticket (WL_WAITING_LINE)
        
            g_error := 'UPDATE WL_WAITING_LINE';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            ts_wl_waiting_line.upd(id_wl_waiting_line_in => i_id_wait,
                                   id_professional_in    => i_id_prof.id,
                                   id_professional_nin   => FALSE,
                                   dt_end_tstz_in        => current_timestamp,
                                   dt_end_tstz_nin       => FALSE,
                                   flg_wl_status_in      => pk_alert_constant.g_wr_wl_status_a,
                                   flg_wl_status_nin     => FALSE,
                                   rows_out              => l_rows);
        
            g_error := 'PROCESS UPDATE WITH WL_WAITING_LINE ' || i_id_wait;
            pk_alertlog.log_debug(g_error, g_package_name);
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_id_prof,
                                          i_table_name => 'WL_WAITING_LINE',
                                          i_rowids     => l_rows,
                                          o_error      => o_error);
            l_rows := table_varchar();
        END IF;
    
        IF i_id_mach IS NOT NULL
        THEN
            g_error := 'GET ID_DEPARTMENT';
            pk_alertlog.log_debug(g_error, g_package_name);
            IF l_demo
            THEN
                l_id_department := g_demo_department_0;
            ELSE
                SELECT d.id_department
                  INTO l_id_department
                  FROM department d
                  JOIN room r
                    ON r.id_department = d.id_department
                  JOIN wl_machine m
                    ON m.id_room = r.id_room
                 WHERE m.id_wl_machine = i_id_mach;
            END IF;
        
        ELSIF i_id_wl_queue IS NOT NULL
        THEN
            g_error := 'GET ID_DEPARTMENT';
            pk_alertlog.log_debug(g_error, g_package_name);
            SELECT wq.id_department, wq.id_wl_queue_group
              INTO l_id_department, l_id_queue_group
              FROM wl_queue wq
             WHERE wq.id_wl_queue = i_id_wl_queue;
        
        ELSE
            RAISE l_invalid_arguments;
        END IF;
    
        IF i_id_pat IS NOT NULL
           AND i_id_pat.count > 0
        THEN
            -- build tickets (WL_WAITING_LINE) for nurse or doctor calling to the patients "efectivados"
        
            g_error := 'SELECT WL_PATIENT_SONHO';
            pk_alertlog.log_debug(g_error, g_package_name);
            OPEN c_get_sonhos FOR
                SELECT patient_id, clin_prof_id, id_episode, consult_id, dt_consult_tstz
                  FROM wl_patient_sonho
                 WHERE prof_id = i_id_prof.id
                   AND id_institution = i_id_prof.institution
                   AND patient_id IN (SELECT *
                                        FROM TABLE(i_id_pat))
                 ORDER BY dt_consult_tstz;
        
            LOOP
                g_error := 'FETCH WL_PATIENT_SONHO';
                pk_alertlog.log_debug(g_error, g_package_name);
                FETCH c_get_sonhos
                    INTO l_pat_sonho, l_med_sonho, l_id_episode, l_serv_sonho, l_dt_consult_sonho_tstz;
                EXIT WHEN c_get_sonhos%NOTFOUND;
            
                g_error := 'CALC NURSE QUEUE L_SERV_SONHO = ' || l_serv_sonho;
                pk_alertlog.log_debug(g_error, g_package_name);
                -- VERIFICAR SE É NECESSÁRIO CRIAR REGISTO PARA EMFERMAGEM
            
                IF i_id_mach IS NOT NULL
                THEN
                    BEGIN
                        SELECT DISTINCT wlq.id_wl_queue
                          INTO l_id_nurse_queue
                          FROM wl_queue wlq
                         INNER JOIN wl_machine wlm
                            ON wlm.id_wl_queue_group = wlq.id_wl_queue_group
                         INNER JOIN dep_clin_serv dcs
                            ON dcs.id_department = wlq.id_department
                         WHERE wlm.id_wl_machine = i_id_mach
                           AND dcs.flg_available = pk_alert_constant.g_yes
                           AND wlq.id_department = l_id_department
                           AND dcs.id_clinical_service = l_serv_sonho
                           AND dcs.flg_nurse_pre = pk_alert_constant.g_yes
                           AND wlq.flg_type_queue = pk_alert_constant.g_wr_wq_type_n;
                    
                    EXCEPTION
                        WHEN no_data_found THEN
                            l_id_nurse_queue := NULL;
                    END;
                
                    IF l_id_nurse_queue IS NOT NULL
                    THEN
                        g_error := 'SELECT NURSE QUEUE INFO';
                        pk_alertlog.log_debug(g_error, g_package_name);
                        SELECT wlq.id_wl_queue, wlq.char_queue
                          INTO l_id_queue, l_char_queue
                          FROM wl_queue wlq, wl_machine wlm
                         WHERE wlm.id_wl_machine = i_id_mach
                           AND wlm.id_wl_queue_group = wlq.id_wl_queue_group
                           AND wlq.id_wl_queue = l_id_nurse_queue;
                    ELSE
                        g_error := 'SELECT DOCTOR QUEUE INFO';
                        pk_alertlog.log_debug(g_error, g_package_name);
                        SELECT wlq.id_wl_queue, wlq.char_queue
                          INTO l_id_queue, l_char_queue
                          FROM wl_queue wlq, wl_machine wlm
                         WHERE wlm.id_wl_machine = i_id_mach
                           AND wlm.id_wl_queue_group = wlq.id_wl_queue_group
                           AND wlq.flg_type_queue = pk_alert_constant.g_wr_wq_type_d
                           AND wlq.id_department = l_id_department;
                    END IF;
                ELSIF i_id_wl_queue IS NOT NULL
                THEN
                    BEGIN
                        SELECT DISTINCT wlq.id_wl_queue
                          INTO l_id_nurse_queue
                          FROM wl_queue wlq
                         INNER JOIN dep_clin_serv dcs
                            ON dcs.id_department = wlq.id_department
                         WHERE wlq.id_wl_queue_group = l_id_queue_group
                           AND dcs.flg_available = pk_alert_constant.g_yes
                           AND wlq.id_department = l_id_department
                           AND dcs.id_clinical_service = l_serv_sonho
                           AND dcs.flg_nurse_pre = pk_alert_constant.g_yes
                           AND wlq.flg_type_queue = pk_alert_constant.g_wr_wq_type_n;
                    EXCEPTION
                        WHEN no_data_found THEN
                            l_id_nurse_queue := NULL;
                    END;
                
                    IF l_id_nurse_queue IS NOT NULL
                    THEN
                        g_error := 'SELECT NURSE QUEUE INFO';
                        pk_alertlog.log_debug(g_error, g_package_name);
                        SELECT wlq.id_wl_queue, wlq.char_queue
                          INTO l_id_queue, l_char_queue
                          FROM wl_queue wlq
                         WHERE wlq.id_wl_queue_group = l_id_queue_group
                           AND wlq.id_wl_queue = l_id_nurse_queue;
                    ELSE
                        g_error := 'SELECT DOCTOR QUEUE INFO';
                        pk_alertlog.log_debug(g_error, g_package_name);
                        SELECT wlq.id_wl_queue, wlq.char_queue
                          INTO l_id_queue, l_char_queue
                          FROM wl_queue wlq
                         WHERE wlq.id_wl_queue_group = l_id_queue_group
                           AND wlq.flg_type_queue = pk_alert_constant.g_wr_wq_type_d
                           AND wlq.id_department = l_id_department;
                    END IF;
                ELSE
                    RAISE l_invalid_arguments;
                END IF;
            
                g_error := 'CALC WL_WAITING_LINE PARENT';
                pk_alertlog.log_debug(g_error, g_package_name);
                -- O PARENT TEM DE SER NULO PARA OS OUTROS Q ELE NÃO ASSOCIA A NENHUMA FILA (RPE:11-02-2005)
                l_id_wait_parent := i_id_wait;
                IF i_id_wait = -1
                THEN
                    l_id_wait_parent := NULL;
                END IF;
            
                g_error := 'CALC WL_WAITING_LINE ROOM';
                pk_alertlog.log_debug(g_error, g_package_name);
                l_indice_pat_room := pk_utils.search_table_number(i_table => i_id_pat, i_search => l_pat_sonho);
            
                l_id_room := NULL;
                IF l_indice_pat_room != -1
                THEN
                    l_id_room := i_id_room(l_indice_pat_room);
                END IF;
            
                IF l_id_room = -1
                THEN
                    l_id_room := NULL;
                END IF;
            
                g_error := 'INSERT INTO WL_WAITING_LINE';
                pk_alertlog.log_debug(g_error, g_package_name);
                ts_wl_waiting_line.ins(id_wl_waiting_line_in        => ts_wl_waiting_line.next_key,
                                       id_clinical_service_in       => l_serv_sonho,
                                       id_professional_in           => l_med_sonho,
                                       id_episode_in                => l_id_episode,
                                       id_wl_queue_in               => l_id_queue,
                                       id_patient_in                => l_pat_sonho,
                                       id_room_in                   => l_id_room,
                                       id_wl_waiting_line_parent_in => l_id_wait_parent,
                                       dt_begin_tstz_in             => current_timestamp,
                                       dt_consult_tstz_in           => l_dt_consult_sonho_tstz,
                                       flg_wl_status_in             => pk_alert_constant.g_wr_wl_status_e,
                                       rows_out                     => l_rows);
            
                g_error := 'PROCESS INSERT WITH WL_WAITING_LINE ';
                pk_alertlog.log_debug(g_error, g_package_name);
                t_data_gov_mnt.process_insert(i_lang, i_id_prof, 'WL_WAITING_LINE', l_rows, o_error);
            
                g_error := 'INSERT INTO WL_PATIENT_SONHO_TRANSFERED';
                pk_alertlog.log_debug(g_error, g_package_name);
                INSERT INTO wl_patient_sonho_transfered
                    (id_wl_patient_sonho_transfered,
                     patient_id,
                     patient_name,
                     patient_dt_birth,
                     patient_gender,
                     num_proc,
                     clin_prof_id,
                     clin_prof_name,
                     consult_id,
                     consult_name,
                     prof_id,
                     machine_name,
                     id_institution,
                     id_episode,
                     dt_consult_tstz)
                    SELECT seq_wl_pat_sonho_transfered.nextval,
                           patient_id,
                           patient_name,
                           patient_dt_birth,
                           patient_gender,
                           num_proc,
                           clin_prof_id,
                           clin_prof_name,
                           consult_id,
                           consult_name,
                           prof_id,
                           machine_name,
                           id_institution,
                           id_episode,
                           dt_consult_tstz
                      FROM wl_patient_sonho
                     WHERE patient_id = l_pat_sonho;
            
                g_error := 'DELETE FROM WL_PATIENT_SONHO';
                pk_alertlog.log_debug(g_error, g_package_name);
                DELETE FROM wl_patient_sonho wps
                 WHERE wps.patient_id = l_pat_sonho
                   AND wps.prof_id = i_id_prof.id;
            
            END LOOP;
        
            CLOSE c_get_sonhos;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_END_LINE_INTERNAL',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_end_line_internal;

    /**
    * Ends admin ticket attending and creates support to nurse or doctor call .
    * Patients with "efectivação" are treated.
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_ID_PROF  professional, institution and software ids
    * @param   I_ID_MACH The machine name id.
    * @param   I_ID_PAT The patient  id.
    * @param   I_ID_ROOM The room id
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Sofia Mendes
    * @version 2.5.1.3
    * @since   25-Nov-2010
    */
    FUNCTION set_end_line
    (
        i_lang    IN language.id_language%TYPE,
        i_id_prof IN profissional,
        i_id_mach IN wl_machine.id_wl_machine%TYPE,
        i_id_wait IN wl_waiting_line.id_wl_waiting_line%TYPE,
        i_id_pat  IN table_number,
        i_id_room IN table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_internal_error EXCEPTION;
    
    BEGIN
    
        g_error := 'CALL set_end_line_internal';
        pk_alertlog.log_debug(g_error);
        IF NOT set_end_line_internal(i_lang        => i_lang,
                                     i_id_prof     => i_id_prof,
                                     i_id_mach     => i_id_mach,
                                     i_id_wait     => i_id_wait,
                                     i_id_pat      => i_id_pat,
                                     i_id_room     => i_id_room,
                                     i_id_wl_queue => NULL,
                                     o_error       => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_END_LINE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_end_line;

    /**
    * Ends admin ticket attending and creates support to nurse or doctor call .
    * Patients with "efectivação" are treated. Function to be use by interface.
    *
    * @param   I_LANG             language associated to the professional executing the request
    * @param   I_PROF             professional, institution and software ids    
    * @param   I_ID_PATIENT       Patient id.
    *
    * @param   O_ERROR            error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Sofia Mendes
    * @version 2.5.1.3
    * @since   24-Nov-2010
    *
    * dependencies: Interfaces Team
    */
    FUNCTION set_end_line_intf
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_internal_error   EXCEPTION;
        l_assoc_pat_ticket sys_config.value%TYPE;
        l_wl_waiting_line  wl_waiting_line%ROWTYPE;
        l_id_room          room.id_room%TYPE;
    
    BEGIN
        --call sys_config
        g_error := 'GET sys_config: ' || g_associate_pat_ticket;
        pk_alertlog.log_debug(g_error);
        l_assoc_pat_ticket := pk_sysconfig.get_config(i_code_cf => g_associate_pat_ticket, i_prof => i_prof);
    
        IF l_assoc_pat_ticket = pk_alert_constant.g_yes
        THEN
            BEGIN
                g_error := 'GET ID_ROOM; id_prof: ' || i_prof.id;
                pk_alertlog.log_debug(g_error);
                SELECT wwr.id_room_wait
                  INTO l_id_room
                  FROM prof_room pr
                  LEFT JOIN wl_waiting_room wwr
                    ON pr.id_room = wwr.id_room_consult
                 WHERE pr.flg_pref = g_prof_room_flg_pref_y
                   AND pr.id_professional = i_prof.id;
            EXCEPTION
                WHEN no_data_found THEN
                    l_id_room := NULL;
            END;
        
            g_error := 'CALL pk_wladm.get_last_called_ticket. id_prof:' || i_prof.id;
            pk_alertlog.log_debug(g_error);
            IF NOT pk_wlinternal.get_last_called_ticket(i_lang            => i_lang,
                                                        i_prof            => i_prof,
                                                        o_wl_waiting_line => l_wl_waiting_line,
                                                        o_error           => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        
            --if yes
            --get ticket  
            g_error := 'CALL set_end_line. i_id_wait: ' || l_wl_waiting_line.id_wl_waiting_line;
            pk_alertlog.log_debug(g_error);
            IF NOT set_end_line_internal(i_lang        => i_lang,
                                         i_id_prof     => i_prof,
                                         i_id_mach     => NULL,
                                         i_id_wait     => l_wl_waiting_line.id_wl_waiting_line,
                                         i_id_pat      => table_number(i_id_patient),
                                         i_id_room     => table_number(l_id_room),
                                         i_id_wl_queue => l_wl_waiting_line.id_wl_queue,
                                         o_error       => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_END_LINE_INTF',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_end_line_intf;

    /**
    * Gets the machine currently associated with the professional (for calls of type M).
    *
    * @param      i_lang                  Language ID
    * @param      i_prof                  ALERT Professional    
    * @param      io_dep                  department identifier
    * @param      o_id_wl_mach            ID_WL_MACHINE of the professional's machine
    * @param      o_id_wl_room            ID_WL_ROOM of the professional's machine
    * @param      O_ERROR an error message, set when return=false    
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Luís Maia
    * @version 2.5.0.7.7.3
    * @since   22-10-2009
    */
    FUNCTION get_prof_wl_mach
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        io_dep       IN OUT department.id_department%TYPE,
        o_id_wl_mach OUT wl_machine.id_wl_machine%TYPE,
        o_id_wl_room OUT room.id_room%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_wr_no_machine EXCEPTION;
        l_serv_name     pk_translation.t_desc_translation;
        l_if_prof_room  prof_room.id_prof_room%TYPE;
        l_demo          BOOLEAN := FALSE;
    
    BEGIN
    
        l_demo := pk_sysconfig.get_config(g_wl_demo_flg, i_prof.institution, i_prof.software) = pk_alert_constant.g_yes;
    
        IF io_dep IS NOT NULL
        THEN
            IF l_demo
            THEN
                SELECT wm.id_wl_machine, wm.id_room
                  INTO o_id_wl_mach, o_id_wl_room
                  FROM wl_machine wm
                 WHERE wm.flg_demo = pk_alert_constant.g_yes;
            ELSE
                g_error := 'GET PROF_ROOM';
                pk_alertlog.log_debug(g_error, g_package_name);
                SELECT id_prof_room
                  INTO l_if_prof_room
                  FROM (SELECT pr.id_prof_room
                          FROM prof_room pr
                         INNER JOIN room r
                            ON pr.id_room = r.id_room
                         WHERE pr.id_professional = i_prof.id
                           AND pr.flg_pref = pk_alert_constant.g_yes
                           AND r.id_department = io_dep
                        UNION
                        SELECT pr.id_prof_room
                          FROM prof_room pr
                         INNER JOIN room r
                            ON pr.id_room = r.id_room
                         INNER JOIN department d
                            ON r.id_department = d.id_department
                         INNER JOIN dept dp
                            ON dp.id_dept = d.id_dept
                         INNER JOIN software_dept sd
                            ON sd.id_dept = dp.id_dept
                           AND sd.id_software = i_prof.software
                         INNER JOIN professional prof
                            ON prof.id_professional = pr.id_professional
                         WHERE pr.id_professional = i_prof.id
                           AND pr.flg_pref = pk_alert_constant.g_yes
                           AND d.id_institution = i_prof.institution
                           AND io_dep IS NULL) data
                 WHERE rownum = 1;
            END IF;
        
            g_error := 'GET WL_MACHINE';
            --As of today there must exist a single machine per room. 
            --This logic should be changed but would imply developments on the UX side as well.
            pk_alertlog.log_debug(g_error, g_package_name);
            IF l_demo
            THEN
                SELECT wm.id_wl_machine, wm.id_room
                  INTO o_id_wl_mach, o_id_wl_room
                  FROM wl_machine wm
                 INNER JOIN wl_queue wq
                    ON wq.id_wl_queue_group = wm.id_wl_queue_group
                 WHERE wm.flg_demo = pk_alert_constant.g_yes
                   AND rownum = 1;
            ELSE
                SELECT wm.id_wl_machine, wm.id_room
                  INTO o_id_wl_mach, o_id_wl_room
                  FROM prof_room pr
                 INNER JOIN room r
                    ON r.id_room = pr.id_room
                 INNER JOIN wl_queue wq
                    ON wq.id_department = r.id_department
                 INNER JOIN wl_machine wm
                    ON wm.id_room = pr.id_room
                   AND wq.id_wl_queue_group = wm.id_wl_queue_group
                 INNER JOIN wl_waiting_room wwr
                    ON wwr.id_room_consult = wm.id_room
                 WHERE pr.id_prof_room = l_if_prof_room
                   AND rownum = 1;
            END IF;
        
            IF o_id_wl_mach IS NULL
               AND NOT l_demo
            THEN
                RAISE l_wr_no_machine;
            END IF;
        
        ELSE
            g_error := 'GET PROF_ROOM';
            pk_alertlog.log_debug(g_error, g_package_name);
            IF l_demo
            THEN
                SELECT wm.id_wl_machine, wm.id_room, g_demo_department_0
                  INTO o_id_wl_mach, o_id_wl_room, io_dep
                  FROM wl_machine wm
                 INNER JOIN wl_queue wq
                    ON wq.id_wl_queue_group = wm.id_wl_queue_group
                 WHERE wm.flg_demo = pk_alert_constant.g_yes
                   AND rownum = 1;
            ELSE
                SELECT wm_p.id_wl_machine, wm_p.id_room, r_s.id_department
                  INTO o_id_wl_mach, o_id_wl_room, io_dep
                  FROM wl_machine wm_p
                 INNER JOIN prof_room pr
                    ON pr.id_room = wm_p.id_room
                   AND pr.id_professional = i_prof.id
                 INNER JOIN wl_waiting_room wwr
                    ON wwr.id_room_consult = pr.id_room
                 INNER JOIN room r_s
                    ON r_s.id_room = wwr.id_room_wait
                 INNER JOIN department d
                    ON r_s.id_department = d.id_department
                 INNER JOIN dept dp
                    ON dp.id_dept = d.id_dept
                 INNER JOIN software_dept sd
                    ON sd.id_dept = dp.id_dept
                   AND sd.id_software = i_prof.software
                 WHERE pr.flg_pref = pk_alert_constant.g_yes
                   AND d.id_institution = i_prof.institution
                   AND rownum = 1;
            END IF;
        
            IF o_id_wl_mach IS NULL
            THEN
                RAISE l_wr_no_machine;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            DECLARE
                --Inicialization of object for input
                l_error_in      t_error_in := t_error_in();
                l_error_message sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'WL_MESSAGE_M006');
                l_params        table_varchar := table_varchar(pk_prof_utils.get_nickname(i_lang, i_prof.id),
                                                               l_serv_name);
            BEGIN
                g_ret := pk_message.format(i_lang, l_error_message, l_params, l_error_message, o_error);
            
                l_error_in.set_all(i_lang,
                                   'WL_MESSAGE_M006',
                                   l_error_message,
                                   l_error_message,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_PROF_WL_MACH',
                                   '',
                                   'U');
                -- execute error processing
                g_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
        
            RETURN FALSE;
        
        WHEN l_wr_no_machine THEN
        
            DECLARE
                --Inicialization of object for input
                l_error_in      t_error_in := t_error_in();
                l_error_message sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'WL_MESSAGE_M008');
            
            BEGIN
                l_error_in.set_all(i_lang,
                                   'WL_MESSAGE_M007',
                                   pk_message.get_message(i_lang, 'WL_MESSAGE_M007'),
                                   pk_message.get_message(i_lang, 'WL_MESSAGE_M007'),
                                   g_package_owner,
                                   g_package_name,
                                   'GET_PROF_WL_MACH',
                                   l_error_message,
                                   'U');
            
                -- execute error processing
                g_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
        
            RETURN FALSE;
        
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROF_WL_MACH',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_prof_wl_mach;

    /**
    * Gets the screen machines that correspond to the provided clinical machine.
    *
    * @param      i_lang                  Language ID
    * @param      i_prof                  ALERT Professional    
    * @param      o_id_wl_mach            ID_WL_MACHINE of the professional's machine
    * @param      O_ERROR an error message, set when return=false    
    *
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ricardo Nuno Almeida
    * @version 2.5.0.7
    * @since   23-10-2009
    */
    FUNCTION get_screen_mach
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_wl_mach    IN wl_machine.id_wl_machine%TYPE,
        o_id_wl_screens OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_demo BOOLEAN := FALSE;
    
    BEGIN
    
        l_demo := pk_sysconfig.get_config(pk_wlcore.g_wl_demo_flg, i_prof.institution, i_prof.software) =
                  pk_alert_constant.g_yes;
    
        g_error := 'GET SCREEN MACHINES FOR ' || i_id_wl_mach;
        pk_alertlog.log_debug(g_error, g_package_name);
        IF l_demo
        THEN
            SELECT wm.id_wl_machine
              BULK COLLECT
              INTO o_id_wl_screens
              FROM wl_machine wm
             WHERE wm.id_wl_machine = i_id_wl_mach
               AND wm.flg_video_active = pk_alert_constant.g_yes;
        ELSE
            SELECT wm_s.id_wl_machine
              BULK COLLECT
              INTO o_id_wl_screens
              FROM wl_waiting_room wwr
             INNER JOIN wl_machine wm_s
                ON wwr.id_room_wait = wm_s.id_room
             INNER JOIN wl_machine wm_c
                ON wwr.id_room_consult = wm_c.id_room
               AND wm_c.id_wl_queue_group = wm_s.id_wl_queue_group
             WHERE wm_c.id_wl_machine = i_id_wl_mach
               AND wm_s.flg_video_active = pk_alert_constant.g_yes;
        END IF;
    
        IF o_id_wl_screens.count = 0
        THEN
            RAISE no_data_found;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            DECLARE
                --Inicialization of object for input
                l_error_in      t_error_in := t_error_in();
                l_error_message sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'WL_MESSAGE_M008');
            BEGIN
                l_error_in.set_all(i_lang,
                                   'WL_MESSAGE_M007',
                                   pk_message.get_message(i_lang, 'WL_MESSAGE_M007'),
                                   pk_message.get_message(i_lang, 'WL_MESSAGE_M007'),
                                   g_package_owner,
                                   g_package_name,
                                   'GET_PROF_WL_MACH',
                                   l_error_message,
                                   'U');
            
                -- execute error processing
                g_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
            END;
        
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SCREEN_MACH',
                                              o_error);
        
            RETURN FALSE;
    END get_screen_mach;

    /********************************************************************************************
    *
    * Makes the correspondence between the WR code of a color and its hexadecimal value. If no correspondance is possible,
    * the same value entered is returned. 
    *
    * @param      i_lang        ID of the language
    * @param      i_prof       professional
    * @param      i_color       Code of the color. 
    *
    * @RETURN  VARCHAR2 the hexa value of the color.
    * @author  RicardoNunoAlmeida
    * @version 2.5.0.7
    * @since   14/01/2010
    **********************************************************************************************/
    FUNCTION get_queue_color
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_color IN wl_queue.color%TYPE
    ) RETURN wl_queue.color%TYPE IS
    
        l_err    t_error_out;
        l_return VARCHAR2(4000);
    
    BEGIN
    
        CASE i_color
            WHEN 'WL_COLOR_QUEUE_BLUE' THEN
                l_return := pk_alert_constant.g_wr_col_blue;
            WHEN 'WL_COLOR_QUEUE_DARK_BLUE' THEN
                l_return := pk_alert_constant.g_wr_col_drk_blue;
            WHEN 'WL_COLOR_QUEUE_DARK_YELLOW' THEN
                l_return := pk_alert_constant.g_wr_col_drk_yell;
            WHEN 'WL_COLOR_QUEUE_GREEN' THEN
                l_return := pk_alert_constant.g_wr_col_gren;
            WHEN 'WL_COLOR_QUEUE_LIGHT_BLUE' THEN
                l_return := pk_alert_constant.g_wr_col_lgh_blue;
            WHEN 'WL_COLOR_QUEUE_LIGHT_GREEN' THEN
                l_return := pk_alert_constant.g_wr_col_lgh_gren;
            WHEN 'WL_COLOR_QUEUE_LIGHT_VIOLET' THEN
                l_return := pk_alert_constant.g_wr_col_lgh_vlt;
            WHEN 'WL_COLOR_QUEUE_ORANGE' THEN
                l_return := pk_alert_constant.g_wr_col_orange;
            WHEN 'WL_COLOR_QUEUE_RED' THEN
                l_return := pk_alert_constant.g_wr_col_red;
            WHEN 'WL_COLOR_QUEUE_VIOLET' THEN
                l_return := pk_alert_constant.g_wr_col_violet;
            ELSE
                l_return := i_color;
        END CASE;
    
        RETURN l_return;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_QUEUE_COLOR',
                                              l_err);
        
            RETURN NULL;
    END get_queue_color;

    /********************************************************************************************
    *
    * Call next patient waiting after having a ticket, for the specified type of queue.
    *
    * @param   I_LANG language id
    * @param   I_PROF  professional, institution and software ids
    * @param   I_TYPE_QUEUE Queue type to be considered on the next call.
    * @param   O_DATA_WAIT The info about next call
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ricardo Nuno Almeida
    * @version 1.0
    * @since   20-03-2009
    **********************************************************************************************/
    FUNCTION get_next_call_ni
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_type_queue IN wl_queue.flg_type_queue%TYPE,
        o_data_wait  OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_queues     table_number;
        l_wl_rec     wl_waiting_line%ROWTYPE;
        l_type_queue wl_queue.flg_type_queue%TYPE;
        l_demo       BOOLEAN := FALSE;
    
    BEGIN
    
        l_demo  := pk_sysconfig.get_config(g_wl_demo_flg, i_prof.institution, i_prof.software) =
                   pk_alert_constant.g_yes;
        g_error := 'SET MODE';
        IF i_type_queue IS NULL
        THEN
            l_type_queue := pk_alert_constant.g_wr_wq_type_c;
        ELSE
            l_type_queue := i_type_queue;
        END IF;
    
        g_error := 'GET WL_QUEUES';
        IF l_demo
        THEN
            SELECT wq.id_wl_queue
              BULK COLLECT
              INTO l_queues
              FROM wl_queue wq
             WHERE wq.flg_demo = pk_alert_constant.g_yes
               AND wq.flg_type_queue = l_type_queue;
        ELSE
            SELECT wq.id_wl_queue
              BULK COLLECT
              INTO l_queues
              FROM prof_room pr
             INNER JOIN room r
                ON pr.id_room = r.id_room
             INNER JOIN wl_queue wq
                ON wq.id_department = r.id_department
             INNER JOIN wl_machine wm
                ON wm.id_room = r.id_room
               AND wm.id_wl_queue_group = wq.id_wl_queue_group
             WHERE pr.id_professional = i_prof.id
               AND pr.flg_pref = pk_alert_constant.g_yes
               AND wq.flg_type_queue = l_type_queue;
        END IF;
    
        g_ret := pk_wlinternal.get_next_call_queue_internal(i_lang            => i_lang,
                                                            i_id_prof         => i_prof,
                                                            i_id_queues       => l_queues,
                                                            i_flg_prior_too   => NULL,
                                                            o_wl_waiting_line => l_wl_rec,
                                                            o_error           => o_error);
        IF l_wl_rec.id_wl_waiting_line IS NOT NULL
        THEN
        
            g_error := 'CALC WL_WAITING_LINE  INFO';
        
            OPEN o_data_wait FOR
                SELECT wq.char_queue         char_queue,
                       l_wl_rec.number_queue ticket_number,
                       
                       pk_wlcore.get_queue_color(i_lang, i_prof, wq.color) color_queue,
                       pk_translation.get_translation(i_lang, wq.code_name_queue) name_queue,
                       l_wl_rec.id_wl_waiting_line id_wait
                  FROM wl_queue wq
                 WHERE id_wl_queue = l_wl_rec.id_wl_queue;
        
        ELSE
            g_error := 'NO WL_WAITING_LINE  INFO';
        
            pk_types.open_my_cursor(o_data_wait);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_NEXT_CALL_NI',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_data_wait);
            RETURN FALSE;
    END get_next_call_ni;

    /**
    * Generates a waiting_line to patient from the nurse or doctor
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_ID_EPISODE  The episode id
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Luís Gaspar
    * @version 1.0
    * @since   26-11-2006
    */
    FUNCTION set_discharge_internal
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_quiosque_id_wwl        wl_waiting_line.id_wl_waiting_line%TYPE;
        l_nurse_id_wwl           wl_waiting_line.id_wl_waiting_line%TYPE;
        l_doctor_id_wwl          wl_waiting_line.id_wl_waiting_line%TYPE;
        l_wl_waiting_line_row    wl_waiting_line%ROWTYPE;
        l_waiting_room_available VARCHAR2(10);
        l_rows                   table_varchar;
    
    BEGIN
    
        g_error                  := 'IS WAITING ROOM AVAILABLE';
        l_waiting_room_available := pk_sysconfig.get_config(g_sys_config_wr, i_prof);
        IF l_waiting_room_available = pk_alert_constant.g_yes
        THEN
            g_error := 'GET QUIOSQUE AND TICKET NUMBER';
            BEGIN
                SELECT wl.id_wl_waiting_line, wl_nurse.id_wl_waiting_line, wl_doctor.id_wl_waiting_line
                  INTO l_quiosque_id_wwl, l_nurse_id_wwl, l_doctor_id_wwl
                  FROM wl_waiting_line wl
                  JOIN wl_queue wq
                    ON wl.id_wl_queue = wq.id_wl_queue
                  JOIN department d
                    ON wq.id_department = d.id_department
                  JOIN clinical_service cs
                    ON cs.id_clinical_service = wl.id_clinical_service
                  JOIN dep_clin_serv dcs
                    ON dcs.id_department = d.id_department
                   AND dcs.id_clinical_service = cs.id_clinical_service
                  LEFT JOIN wl_waiting_line wl_nurse
                    ON wl_nurse.id_wl_waiting_line_parent = wl.id_wl_waiting_line -- CHECK IF NURSE WL_WAITING_LINE ALREADY EXISTS
                  LEFT JOIN wl_waiting_line wl_doctor
                    ON wl_doctor.id_wl_waiting_line_parent = wl_nurse.id_wl_waiting_line
                 WHERE wl.id_episode = i_id_episode
                   AND wl.id_wl_waiting_line_parent IS NULL -- QUISOSQUE TICKET
                   AND dcs.flg_nurse_pre = pk_alert_constant.g_yes
                   AND rownum = 1;
            
                IF l_doctor_id_wwl IS NULL
                THEN
                    g_error := 'GET NURSE WL_WAITING_ROOM';
                    pk_alertlog.log_debug(g_error, g_package_name);
                    SELECT *
                      INTO l_wl_waiting_line_row
                      FROM wl_waiting_line
                     WHERE id_wl_waiting_line = l_nurse_id_wwl;
                
                    g_error := 'GET ID_WL_WAITING_ROOM';
                    pk_alertlog.log_debug(g_error, g_package_name);
                    SELECT wq_d.id_wl_queue
                      INTO l_wl_waiting_line_row.id_wl_queue
                      FROM wl_queue wq_a
                     INNER JOIN wl_queue wq_d
                        ON wq_d.id_department = wq_a.id_department
                       AND wq_d.id_wl_queue_group = wq_a.id_wl_queue_group
                       AND wq_d.flg_type_queue = g_flg_type_queue_doctor
                     WHERE wq_a.id_wl_queue = l_wl_waiting_line_row.id_wl_queue;
                
                    l_wl_waiting_line_row.id_wl_waiting_line_parent := l_nurse_id_wwl;
                    l_wl_waiting_line_row.id_wl_waiting_line        := ts_wl_waiting_line.next_key;
                
                    g_error := 'CREATE DOCTOR WL_WAITING_ROOM';
                    pk_alertlog.log_debug(g_error, g_package_name);
                    ts_wl_waiting_line.ins(id_wl_waiting_line_in        => l_wl_waiting_line_row.id_wl_waiting_line,
                                           char_queue_in                => l_wl_waiting_line_row.char_queue,
                                           number_queue_in              => l_wl_waiting_line_row.number_queue,
                                           id_clinical_service_in       => l_wl_waiting_line_row.id_clinical_service,
                                           id_professional_in           => l_wl_waiting_line_row.id_professional,
                                           id_wl_queue_in               => l_wl_waiting_line_row.id_wl_queue,
                                           id_patient_in                => l_wl_waiting_line_row.id_patient,
                                           id_room_in                   => l_wl_waiting_line_row.id_room,
                                           id_wl_waiting_line_parent_in => l_wl_waiting_line_row.id_wl_waiting_line_parent,
                                           id_episode_in                => l_wl_waiting_line_row.id_episode,
                                           dt_begin_tstz_in             => l_wl_waiting_line_row.dt_begin_tstz,
                                           dt_call_tstz_in              => l_wl_waiting_line_row.dt_call_tstz,
                                           dt_consult_tstz_in           => l_wl_waiting_line_row.dt_consult_tstz,
                                           dt_end_tstz_in               => l_wl_waiting_line_row.dt_end_tstz,
                                           flg_wl_status_in             => l_wl_waiting_line_row.flg_wl_status,
                                           rows_out                     => l_rows);
                
                    g_error := 'PROCESS INSERT WITH WL_WAITING_LINE ';
                    pk_alertlog.log_debug(g_error, g_package_name);
                    t_data_gov_mnt.process_insert(i_lang, i_prof, 'WL_WAITING_LINE', l_rows, o_error);
                
                    g_error := 'UPDATE NURSE WL_WAITING_ROOM';
                    pk_alertlog.log_debug(g_error, g_package_name);
                    ts_wl_waiting_line.upd(id_wl_waiting_line_in => l_nurse_id_wwl,
                                           flg_wl_status_in      => pk_alert_constant.g_wr_wl_status_n,
                                           flg_wl_status_nin     => FALSE,
                                           rows_out              => l_rows);
                
                    g_error := 'PROCESS UPDATE WITH WL_WAITING_LINE ' || l_nurse_id_wwl;
                    pk_alertlog.log_debug(g_error, g_package_name);
                    t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'WL_WAITING_LINE',
                                                  i_rowids     => l_rows,
                                                  o_error      => o_error);
                
                END IF;
            EXCEPTION
                WHEN no_data_found THEN
                    -- THIS PATIENT DOES NOT NEET TO GO TO THE NURSE BEFORE GOING TO THE DOCTOR
                    NULL;
            END;
        END IF;
    
        -- commit is not done here, but in the calling function
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_DISCHARGE_INTERNAL',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_discharge_internal;
    /********************************************************************************************
    *
    *  Creates a new entry to be called by the Screen application.
    *
    * @param i_lang                  Language ID
    * @param i_id_wl                 ID of the ticket to be called
    * @param i_id_mach_ped           ID of the machine issuing the call.
    * @param i_prof                  Professional issuing the call.
    * @param i_id_mach_ped           ID of the destination machine
    * @param i_id_episode            episode id
    * @param o_message_audio         Message to be converted into an audio file.
    * @param o_sound_file            Name of the audio file to be created.
    * @param o_mac                   IDs of the machines where the message will be displayed
    * @param o_msg                   Messages to appear on the screen
    * @param o_error
    */
    FUNCTION item_call_system_queue
    (
        i_lang          IN language.id_language%TYPE,
        i_id_wl         IN wl_waiting_line.id_wl_waiting_line%TYPE,
        i_id_mach_ped   IN wl_machine.id_wl_machine%TYPE,
        i_prof          IN profissional,
        i_id_mach_dest  IN wl_machine.id_wl_machine%TYPE,
        i_id_episode    IN episode.id_episode%TYPE,
        o_message_audio OUT VARCHAR2,
        o_sound_file    OUT VARCHAR2,
        o_mac           OUT table_varchar,
        o_msg           OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_waiting_room_sys_external sys_config.value%TYPE;
    
    BEGIN
    
        l_waiting_room_sys_external := pk_sysconfig.get_config('WAITING_ROOM_EXTERNAL_SYSTEM', i_prof);
    
        IF l_waiting_room_sys_external = pk_alert_constant.get_yes
        THEN
            IF NOT pk_wlservices.set_item_call_external(i_lang, i_prof, i_id_episode, o_error => o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSE
            IF NOT pk_wlservices.set_item_call_queue(i_lang          => i_lang,
                                                     i_id_wl         => i_id_wl,
                                                     i_id_mach_ped   => i_id_mach_ped,
                                                     i_prof          => i_prof,
                                                     i_id_mach_dest  => i_id_mach_dest,
                                                     i_id_room       => NULL,
                                                     o_message_audio => o_message_audio,
                                                     o_sound_file    => o_sound_file,
                                                     o_mac           => o_mac,
                                                     o_msg           => o_msg,
                                                     o_error         => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'ITEM_CALL_SYSTEM_QUEUE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END item_call_system_queue;
    /**
    * Generates a call to patient. Unlike the set_item_call_queue family of functions, it does not depend on
    * ticket or episodes, thus allowing the Screen application to call patients without them being efectivated
    * or taking a ticket. Also, this function assumes that the machine of the professional calling the patient is on the
    * same clinical service than the screen. (at least, currently)
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_ID_EPISODE  The episode ID
    * @param   O_MESSAGE_AUDIO The audio message in text
    * @param   O_SOUND_FILE The sound file created
    * @param   O_MAC Internal name of machine
    * @param   O_MSG Id of WL_CALL_QUEUE
    * @param   O_ERROR an error message, set when return=false
    */
    FUNCTION item_call_system_epis
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_id_room       IN NUMBER,
        o_message_audio OUT VARCHAR2,
        o_sound_file    OUT VARCHAR2,
        o_mac           OUT table_varchar,
        o_msg           OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_waiting_room_sys_external sys_config.value%TYPE;
    
    BEGIN
    
        l_waiting_room_sys_external := pk_sysconfig.get_config('WAITING_ROOM_EXTERNAL_SYSTEM', i_prof);
    
        IF l_waiting_room_sys_external = pk_alert_constant.get_yes
        THEN
            IF NOT pk_wlservices.set_item_call_external(i_lang, i_prof, i_id_episode, o_error => o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSE
            IF NOT pk_wlservices.set_item_call_epis(i_lang          => i_lang,
                                                    i_prof          => i_prof,
                                                    i_id_episode    => i_id_episode,
                                                    i_id_room       => i_id_room,
                                                    o_message_audio => o_message_audio,
                                                    o_sound_file    => o_sound_file,
                                                    o_mac           => o_mac,
                                                    o_msg           => o_msg,
                                                    o_error         => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            RETURN pk_alert_exceptions.process_error(i_lang        => i_lang,
                                                     i_sqlcode     => NULL,
                                                     i_sqlerrm     => NULL,
                                                     i_message     => NULL,
                                                     i_owner       => g_package_owner,
                                                     i_package     => g_package_name,
                                                     i_function    => 'ITEM_CALL_SYSTEM_EPIS',
                                                     i_action_type => 'U',
                                                     i_action_msg  => o_error.ora_sqlerrm,
                                                     i_msg_title   => pk_message.get_message(i_lang, 'COMMON_T006'),
                                                     i_msg_type    => NULL,
                                                     o_error       => o_error);
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'ITEM_CALL_SYSTEM_EPIS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END item_call_system_epis;
    /**
    * Notify the patient call to external admission software
     * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_ID_PAT  The patient id
    * @param  i_id_episode The episode id
    */
    FUNCTION item_call_system
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_pat        IN patient.id_patient%TYPE,
        i_id_episode    IN episode.id_episode%TYPE,
        o_message_audio OUT VARCHAR2,
        o_sound_file    OUT VARCHAR2,
        o_mac           OUT table_varchar,
        o_msg           OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_waiting_room_sys_external sys_config.value%TYPE;
    
    BEGIN
    
        l_waiting_room_sys_external := pk_sysconfig.get_config('WAITING_ROOM_EXTERNAL_SYSTEM', i_prof);
    
        IF l_waiting_room_sys_external = pk_alert_constant.get_yes
        THEN
            IF NOT pk_wlservices.set_item_call_external(i_lang, i_prof, i_id_episode, o_error => o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSE
        
            IF NOT pk_wlservices.set_item_call(i_lang          => i_lang,
                                               i_prof          => i_prof,
                                               i_id_pat        => i_id_pat,
                                               o_message_audio => o_message_audio,
                                               o_sound_file    => o_sound_file,
                                               o_mac           => o_mac,
                                               o_msg           => o_msg,
                                               o_error         => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ITEM_CALL_EXTERNAL',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END item_call_system;

    /**
     * @param i_lang 
     * @param i_prof 
    */
    FUNCTION get_episode_efective
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_flg_status IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_status VARCHAR2(1 CHAR);
    
    BEGIN
        --status available for call patient trough Waiting Room
        IF i_id_episode IS NULL
        THEN
            l_status := pk_alert_constant.g_no;
        ELSE
            IF i_flg_status IN ('E', 'C', 'W', 'P', 'G', 'F')
            THEN
                l_status := pk_alert_constant.g_yes;
            ELSE
                l_status := pk_alert_constant.g_no;
            END IF;
        END IF;
    
        RETURN l_status;
    
    END get_episode_efective;

    FUNCTION count_kiosk_department
    (
        i_prof         IN profissional,
        i_machine_name IN VARCHAR2
    ) RETURN NUMBER IS
    
        l_count NUMBER;
        k_mach_type_kiosk CONSTANT VARCHAR2(0001 CHAR) := 'K';
    
    BEGIN
    
        SELECT COUNT(*)
          INTO l_count
          FROM wl_machine m
          JOIN room r
            ON r.id_room = m.id_room
          JOIN department d
            ON d.id_department = r.id_department
          JOIN room r2
            ON r2.id_department = r.id_department
          JOIN wl_machine m2
            ON m2.id_room = r2.id_room
         WHERE m.machine_name = upper(i_machine_name)
           AND m2.flg_mach_type = k_mach_type_kiosk
           AND d.id_institution = i_prof.institution;
    
        RETURN l_count;
    
    END count_kiosk_department;

    PROCEDURE inicialize IS
    
    BEGIN
    
        g_flg_epis_type_nurse_care := 14;
        g_flg_epis_type_nurse_outp := 16;
        g_flg_epis_type_nurse_pp   := 17;
    
        xsp                 := chr(32);
        xpl                 := '''';
        pk_med_msg_01       := 'MED_MSG_01';
        pk_med_msg_02       := 'MED_MSG_02';
        pk_wl_titulo        := 'WL_TITULO';
        pk_med_msg_tit_01   := 'MED_MSG_TIT_01';
        pk_med_msg_tit_02   := 'MED_MSG_TIT_02';
        pk_med_msg_tit_03   := 'MED_MSG_TIT_03';
        pk_voice            := 'V';
        pk_bip              := 'B';
        pk_wavfile_prefix   := 'CALL_';
        pk_wavfile_sufix    := '000.WAV';
        pk_wl_wav_bip_name  := 'WL_WAV_BIP_NAME';
        pk_pendente         := 'P';
        pk_wl_path_wav_read := 'WL_PATH_WAV_READ';
        pk_wl_wav_bip_name  := 'WL_WAV_BIP_NAME';
        pk_h_status         := 'H';
        pk_a_status         := 'A';
        pk_t_status         := 'T';
        pk_n_status         := 'N';
        pk_nurse_queue      := 'WL_ID_NURSE_QUEUE';
        pk_wl_titulo        := 'WL_TITULO';
        pk_wl_lang          := 'WL_LANG';
    
        g_sys_config_wr         := 'WL_WAITING_ROOM_AVAILABLE';
        g_flg_type_queue_doctor := 'D';
    
        g_error_msg_code       := 'COMMON_M001';
        g_prof_room_flg_pref_y := 'Y';
        g_flg_available        := 'Y';
    
    END inicialize;

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
                SELECT *
                  INTO xepis
                  FROM episode x
                 WHERE x.id_episode = i_id_episode;
            
                l_bool := xepis.flg_status = 'A' AND xepis.flg_ehr = 'N';
            
                IF l_bool
                THEN
                
                    l_return := k_yes;
                
                END IF;
            END IF;
        END IF;
    
        RETURN l_return;
    
    END wr_call;

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
    
        l_num_stack := get_max_tickets_shown(i_prof => i_prof, i_id_machine => i_id_machine);
    
        OPEN o_result FOR
            SELECT t.*
              FROM (SELECT rownum rn, x01.*
                      FROM (SELECT wl.char_queue,
                                   wl.number_queue,
                                   wl.id_wl_waiting_line,
                                   pk_wlcore.get_queue_color(i_lang, i_prof, q.color) color
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
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_LAST_CALLED_TICKET',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_result);
            RETURN FALSE;
    END get_last_called_tickets;

    FUNCTION get_max_tickets_shown
    (
        i_prof       IN profissional,
        i_id_machine IN NUMBER
    ) RETURN NUMBER IS
    
        l_return NUMBER := 3;
        tbl_num  table_number;
    
    BEGIN
    
        SELECT max_ticket_shown
          BULK COLLECT
          INTO tbl_num
          FROM wl_machine
         WHERE id_wl_machine = i_id_machine;
    
        IF tbl_num.count > 0
        THEN
            l_return := coalesce(tbl_num(1), l_return);
        END IF;
    
        RETURN l_return;
    
    END get_max_tickets_shown;

    FUNCTION get_institution(i_id_department IN NUMBER) RETURN NUMBER IS
    
        tbl_id   table_number;
        l_return NUMBER;
    
    BEGIN
    
        SELECT d.id_institution
          BULK COLLECT
          INTO tbl_id
          FROM department d
         WHERE d.id_department = i_id_department;
    
        IF tbl_id.count > 0
        THEN
            l_return := tbl_id(1);
        END IF;
    
        RETURN l_return;
    
    END get_institution;

    FUNCTION get_department(i_id_room IN NUMBER) RETURN NUMBER IS
    
        tbl_id   table_number;
        l_return NUMBER;
    
    BEGIN
    
        SELECT r.id_department
          BULK COLLECT
          INTO tbl_id
          FROM room r
         WHERE r.id_room = i_id_room;
    
        IF tbl_id.count > 0
        THEN
            l_return := tbl_id(1);
        END IF;
    
        RETURN l_return;
    
    END get_department;

    FUNCTION get_room_of_mach(i_id_machine IN NUMBER) RETURN NUMBER IS
    
        tbl_id   table_number;
        l_return NUMBER;
    
    BEGIN
    
        SELECT id_room
          BULK COLLECT
          INTO tbl_id
          FROM wl_machine
         WHERE id_wl_machine = i_id_machine;
    
        IF tbl_id.count > 0
        THEN
            l_return := tbl_id(1);
        END IF;
    
        RETURN l_return;
    
    END get_room_of_mach;

    FUNCTION get_mach_of_room(i_id_room IN NUMBER) RETURN NUMBER IS
    
        tbl_id   table_number;
        l_return NUMBER;
    
    BEGIN
    
        SELECT id_wl_machine
          BULK COLLECT
          INTO tbl_id
          FROM wl_machine
         WHERE id_room = i_id_room;
    
        IF tbl_id.count > 0
        THEN
            l_return := tbl_id(1);
        END IF;
    
        RETURN l_return;
    
    END get_mach_of_room;

    FUNCTION get_inst_from_mach(i_id_machine IN NUMBER) RETURN NUMBER IS
    
        l_return        NUMBER := 0;
        l_id_room       NUMBER;
        l_id_department NUMBER;
    
    BEGIN
    
        IF i_id_machine IS NOT NULL
        THEN
        
            l_id_room := get_room_of_mach(i_id_machine);
        
            IF l_id_room IS NOT NULL
            THEN
            
                l_id_department := get_department(l_id_room);
                l_return        := get_institution(l_id_department);
            
            END IF;
        
        END IF;
    
        RETURN l_return;
    
    END get_inst_from_mach;

BEGIN

    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

    inicialize();

END pk_wlcore;
/
