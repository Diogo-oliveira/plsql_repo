/*-- Last Change Revision: $Rev: 2027896 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:37 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_wlservices IS

    FUNCTION get_wl_by_episode(i_id_episode IN NUMBER) RETURN NUMBER IS
    
        tbl_id   table_number;
        l_return NUMBER;
    
    BEGIN
    
        SELECT wl.id_wl_waiting_line
          BULK COLLECT
          INTO tbl_id
          FROM wl_waiting_line wl
         WHERE wl.id_episode = i_id_episode
        -- can have only one row if workflow starts on adm
        ---AND wl.id_wl_waiting_line_parent IS NOT NULL
         ORDER BY wl.dt_begin_tstz DESC;
    
        IF tbl_id.count > 0
        THEN
            l_return := tbl_id(1);
        END IF;
    
        RETURN l_return;
    
    END get_wl_by_episode;

    FUNCTION get_mach_by_id_wl
    (
        i_prof  IN profissional,
        i_id_wl IN NUMBER
    ) RETURN NUMBER IS
    
        tbl_id   table_number;
        l_return NUMBER;
    
    BEGIN
    
        SELECT wm.id_wl_machine
          BULK COLLECT
          INTO tbl_id
          FROM prof_room pr
         INNER JOIN wl_machine wm
            ON wm.id_room = pr.id_room
         INNER JOIN room r
            ON r.id_room = wm.id_room
         INNER JOIN wl_queue wq
            ON wq.id_department = r.id_department
           AND wq.id_wl_queue_group = wm.id_wl_queue_group
        
         INNER JOIN wl_waiting_line wwl
            ON wwl.id_wl_queue = wq.id_wl_queue
         WHERE pr.id_professional = i_prof.id
           AND pr.flg_pref = pk_alert_constant.get_yes
           AND wwl.id_wl_waiting_line = i_id_wl;
    
        IF tbl_id.count > 0
        THEN
            l_return := tbl_id(1);
        END IF;
    
        RETURN l_return;
    
    END get_mach_by_id_wl;

    FUNCTION get_ticket_from_wl(i_id_wl IN NUMBER) RETURN VARCHAR2 IS
    
        tbl_nome table_varchar;
        l_return VARCHAR2(4000);
    
    BEGIN
    
        SELECT x.char_queue || x.number_queue
          BULK COLLECT
          INTO tbl_nome
          FROM wl_waiting_line x
         WHERE x.id_wl_waiting_line = i_id_wl;
    
        IF tbl_nome.count > 0
        THEN
            l_return := tbl_nome(1);
        END IF;
    
        RETURN l_return;
    
    END get_ticket_from_wl;

    /********************************************************************************************
     *
     *  Creates a new entry to be called by the Screen application.
     *
     * @param i_lang                  Language ID
     * @param i_id_wl                 ID of the ticket to be called
     * @param i_id_mach_ped           ID of the machine issuing the call. If null, assumed by i_prof vs prof_room
     * @param i_prof                  Professional issuing the call.
     * @param i_id_mach_ped           ID of the destination machine (where the patient should go). If null, assumed by i_prof vs prof_room
     * @param o_message_audio         Message to be converted into an audio file.
     * @param o_sound_file            Name of the audio file to be created.
     * @param o_mac                   IDs of the machines where the message will be displayed
     * @param o_msg                   Messages to appear on the screen
     * @param o_error
     *
     * @return                         true or false
     *
     * @author                          Ricardo Nuno Almeida
     * @version                         0.1
     * @since                           10/02/2009
    **********************************************************************************************/
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
    
        l_ticket_par_number wl_waiting_line.number_queue%TYPE;
        l_ticket_par_char   pk_wlcore.g_wl_queue_char;
        l_message           wl_call_queue.message%TYPE;
        l_sound_file        wl_call_queue.sound_file%TYPE;
        l_sound_beep        wl_call_queue.sound_file%TYPE;
        l_id_pat            wl_waiting_line.id_wl_waiting_line%TYPE;
    
        l_id_queue      wl_queue.id_wl_queue%TYPE;
        l_nome_pat      patient.name%TYPE;
        l_sexo_pat      patient.gender%TYPE;
        l_id_call_queue wl_call_queue.id_call_queue%TYPE;
        l_titulo_mens   NUMBER;
        l_flg_status    wl_waiting_line.flg_wl_status%TYPE;
        l_lang          language.id_language%TYPE;
    
        l_rows table_varchar;
    
        l_opcao         NUMBER := 0;
        l_ticket_number VARCHAR2(0050);
        xtmp            VARCHAR2(0100);
        i               NUMBER := 0;
        xflg_type       VARCHAR2(0050);
        l_queue_dep     department.id_department%TYPE;
        l_id_mach_ped   wl_machine.id_wl_machine%TYPE;
        l_type_queue    wl_queue.flg_type_queue%TYPE;
    
        l_cfg_ticket_type sys_config.id_sys_config%TYPE;
    
        l_mach_dest NUMBER;
        l_id_wl     NUMBER;
    
        CURSOR c_mach_dest
        (
            x_id_queue NUMBER,
            x_opcao    NUMBER
        ) IS
            SELECT wmq.id_wl_mach_dest id_wl_machine, --máquina que deve ler o pedido; corresponde à máquina especificada em wmq
                   wm.flg_audio_active,
                   pk_translation.get_translation(l_lang, wmo.cod_desc_machine_audio) cod_desc_machine_audio,
                   wm.machine_name,
                   l_id_mach_ped id_wl_machine_dest --máquina à qual se deve dirigir; corresponde à maquina do prof que fez o pedido.
              FROM wl_msg_queue wmq
             INNER JOIN wl_machine wm
                ON wmq.id_wl_mach_dest = wm.id_wl_machine
             INNER JOIN wl_machine wmo
                ON wm.id_wl_queue_group = wmo.id_wl_queue_group
               AND wmo.id_wl_machine = l_id_mach_ped
             INNER JOIN wl_queue wq
                ON wq.id_wl_queue = wmq.id_wl_id_queue
               AND wq.id_wl_queue_group = wm.id_wl_queue_group
             WHERE 0 = x_opcao
               AND wmq.id_wl_id_queue = x_id_queue
               AND wm.flg_video_active = pk_alert_constant.get_yes
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
    
        l_demo BOOLEAN := FALSE;
    
        FUNCTION get_mach_by_room(i_id_room IN NUMBER) RETURN NUMBER IS
        
            tbl_id   table_number;
            l_return NUMBER;
        
        BEGIN
        
            IF i_id_room IS NOT NULL
            THEN
                SELECT m.id_wl_machine
                  BULK COLLECT
                  INTO tbl_id
                  FROM wl_machine m
                 WHERE m.id_room = i_id_room
                   AND m.flg_mach_type = 'P';
            
                IF tbl_id.count > 0
                THEN
                    l_return := tbl_id(1);
                END IF;
            
            END IF;
        
            RETURN l_return;
        
        END get_mach_by_room;
    
    BEGIN
    
        l_cfg_ticket_type := pk_sysconfig.get_config('WL_CALL_BY_NAME_OR_NUMBER', i_prof.institution, i_prof.software);
        IF i_id_episode IS NOT NULL
        THEN
            l_id_wl := get_wl_by_episode(i_id_episode);
        ELSE
            l_id_wl := i_id_wl;
        END IF;
    
        l_lang := i_lang;
        o_mac  := table_varchar(50);
        o_msg  := table_number(50);
    
        g_error := 'CHECK ORIGIN MACHINE';
        pk_alertlog.log_debug(g_error);
        IF i_id_episode IS NOT NULL
        THEN
            -- ADM nao manda episode nem sala
            IF i_id_room IS NULL
            THEN
                l_id_mach_ped := get_mach_by_id_wl(i_prof, l_id_wl);
            ELSE
                l_id_mach_ped := get_mach_by_room(i_id_room);
            END IF;
        ELSE
            l_id_mach_ped := i_id_mach_ped;
        END IF;
    
        -- get needed info from waiting line queue
        -- Determinar Departmento da fila
        g_error := 'GET QUEUE DEP';
        pk_alertlog.log_debug(g_error);
        SELECT wl.char_queue, wl.number_queue, wl.id_wl_queue, wlq.id_department, wlq.flg_type_queue, wl.id_patient
          INTO l_ticket_par_char, l_ticket_par_number, l_id_queue, l_queue_dep, l_type_queue, l_id_pat
          FROM wl_waiting_line wl
         INNER JOIN wl_queue wlq
            ON wlq.id_wl_queue = wl.id_wl_queue
         INNER JOIN wl_machine wlm
            ON wlq.id_wl_queue_group = wlm.id_wl_queue_group
         WHERE id_wl_waiting_line = l_id_wl
           AND wlm.id_wl_machine = l_id_mach_ped;
    
        -- CONSTRUÇÃO DA MENSAGEM
        -- SE A QUEUE NAO É QUEUE DE SISTEMA, SENAO MENSAGEM DIFERENTE
        IF (l_type_queue = pk_alert_constant.g_wr_wq_type_a)
           OR (l_type_queue = pk_alert_constant.g_wr_wq_type_c AND
           nvl(pk_sysconfig.get_config('WL_NUR_CONS_TYPE', i_prof.institution, i_prof.software), 1) = 2 AND
           l_id_pat IS NULL)
        THEN
            g_error := 'GET WL_QUEUE.CHAR_QUEUE';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_wlcore.get_wl_queue_char_queue(i_lang   => i_lang,
                                                     i_prof   => i_prof,
                                                     i_char   => l_ticket_par_char,
                                                     o_result => l_ticket_par_char,
                                                     o_error  => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            -- build ticket number
            g_error := 'BUILD TICKET NUMBER';
            pk_alertlog.log_debug(g_error);
            l_ticket_number := l_ticket_par_char || to_char(l_ticket_par_number, '000');
            l_message       := l_ticket_number || '.' || xsp;
        
            l_opcao   := 0;
            xflg_type := 'A';
        
        ELSE
            l_opcao   := 1;
            xflg_type := 'M';
        
            IF l_cfg_ticket_type = 'NAME'
            THEN
            
                g_error := 'get basic info of patient';
                pk_alertlog.log_debug(g_error);
                SELECT pk_adt.get_patient_name_to_sort(i_lang, i_prof, pa.id_patient, pk_adt.g_false),
                       pk_patient.get_gender(i_lang, pa.gender),
                       nvl(wl.flg_wl_status, pk_alert_constant.g_wr_wl_status_e)
                  INTO l_nome_pat, l_sexo_pat, l_flg_status
                  FROM wl_waiting_line wl
                  JOIN episode e
                    ON e.id_episode = wl.id_episode
                  JOIN visit v
                    ON v.id_visit = e.id_visit
                  JOIN patient pa
                    ON pa.id_patient = v.id_patient
                 WHERE wl.id_wl_waiting_line = l_id_wl;
            
                -- build sentence for doctor's waiting room
                l_message := pk_message.get_message(i_lang => l_lang, i_code_mess => pk_med_msg_01);
            
                g_ret := pk_sysconfig.get_config(i_code_cf => pk_wl_titulo, i_prof => i_prof, o_msg_cf => l_titulo_mens);
            
                IF l_titulo_mens = 1
                THEN
                    SELECT decode(l_sexo_pat, 'M', pk_med_msg_tit_01, pk_med_msg_tit_02)
                      INTO xtmp
                      FROM dual;
                
                    l_message := l_message || pk_message.get_message(i_lang => l_lang, i_code_mess => xtmp);
                END IF;
            ELSE
                l_nome_pat := get_ticket_from_wl(l_id_wl);
            END IF;
        
            l_message := l_message || l_nome_pat || '.';
            l_message := l_message || xsp || pk_message.get_message(i_lang => l_lang, i_code_mess => pk_med_msg_02);
            l_message := l_message || chr(32);
            l_opcao   := 1;
        
            --Also, do not forget to update the ticket status
            IF l_flg_status = pk_alert_constant.g_wr_wl_status_e
            THEN
                g_error := 'UPDATE TICKET STATUS';
                pk_alertlog.log_debug(g_error);
                ts_wl_waiting_line.upd(id_wl_waiting_line_in => l_id_wl,
                                       dt_call_tstz_in       => current_timestamp,
                                       dt_call_tstz_nin      => FALSE,
                                       flg_wl_status_in      => pk_alert_constant.g_wr_wl_status_x,
                                       flg_wl_status_nin     => FALSE,
                                       rows_out              => l_rows);
            
                g_error := 'PROCESS UPDATE WITH WL_WAITING_LINE = ' || l_id_wl;
                pk_alertlog.log_debug(g_error, g_package_name);
                t_data_gov_mnt.process_update(i_lang, i_prof, 'WL_WAITING_LINE', l_rows, o_error);
            END IF;
        END IF;
    
        g_error := 'GET BEEP CONFIG';
        pk_alertlog.log_debug(g_error);
        g_ret := pk_sysconfig.get_config(i_code_cf => pk_wl_wav_bip_name, i_prof => i_prof, o_msg_cf => l_sound_beep);
    
        -- INSERCAO DAS MENSAGENS A CHAMAR POR CADA MAQUINA QUE FALA
        -- FOR TUPLO IN C_MACH_DEST(I_ID_MACHINE,I_ID_PROF.ID,L_OPCAO) LOOP
    
        g_error := 'GET MACHINES';
        pk_alertlog.log_debug(g_error);
        FOR tuplo IN c_mach_dest(l_id_queue, l_opcao)
        LOOP
        
            INSERT INTO wl_call_queue
                (id_call_queue,
                 message,
                 id_wl_machine,
                 id_wl_machine_dest,
                 id_wl_waiting_line,
                 flg_status,
                 sound_file,
                 id_professional,
                 
                 dt_gen_sound_file_tstz,
                 flg_type)
            VALUES
                (seq_wl_call_queue.nextval,
                 l_message || tuplo.cod_desc_machine_audio,
                 tuplo.id_wl_machine,
                 tuplo.id_wl_machine_dest,
                 l_id_wl,
                 pk_pendente,
                 decode(tuplo.flg_audio_active,
                        pk_voice,
                        nvl(l_sound_file, pk_wavfile_prefix || seq_wl_call_queue.currval || pk_wavfile_sufix),
                        pk_bip,
                        l_sound_beep,
                        NULL),
                 
                 i_prof.id,
                 
                 decode(tuplo.flg_audio_active, pk_bip, current_timestamp, pk_none, current_timestamp, NULL),
                 xflg_type)
            RETURNING id_call_queue, sound_file INTO l_id_call_queue, l_sound_file;
        
            i := i + 1; -- COMEÇA SEMPRE EM 1
        
            IF i > 1
            THEN
                o_mac.extend;
                o_msg.extend;
            ELSE
                o_message_audio := l_message || tuplo.cod_desc_machine_audio;
                o_sound_file    := NULL;
            END IF;
        
            g_error := 'CHECK SOUND FILE';
            pk_alertlog.log_debug(g_error);
            IF ((o_sound_file IS NULL) AND (tuplo.flg_audio_active = pk_voice))
            THEN
                o_sound_file := l_sound_file;
            END IF;
        
            o_mac(i) := tuplo.machine_name;
            o_msg(i) := l_id_call_queue;
        
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ITEM_CALL_QUEUE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_item_call_queue;

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
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ricardo Nuno Almeida
    * @version 0.1
    * @since   26-01-2009
    */
    FUNCTION set_item_call_epis
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
    
        l_id_wl_mach     wl_machine.id_wl_machine%TYPE;
        l_screen_machine table_number;
        l_id_wl          wl_waiting_line.id_wl_waiting_line%TYPE;
        l_wl_queue       wl_queue.id_wl_queue%TYPE;
        l_id_pat         patient.id_patient%TYPE;
        l_wroom          room.id_room%TYPE;
        l_clin_serv      clinical_service.id_clinical_service%TYPE;
        l_dep            department.id_department%TYPE := NULL;
        l_rows           table_varchar;
        l_demo           BOOLEAN := FALSE;
    
    BEGIN
    
        -- INIT
        l_demo := pk_sysconfig.get_config(pk_wlcore.g_wl_demo_flg, i_prof.institution, i_prof.software) =
                  pk_alert_constant.get_yes;
    
        g_error := 'GET WL_MACHINE';
        pk_alertlog.log_debug(g_error, g_package_name);
        IF NOT pk_wlcore.get_prof_wl_mach(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          io_dep       => l_dep,
                                          o_id_wl_mach => l_id_wl_mach,
                                          o_id_wl_room => l_wroom,
                                          o_error      => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- set chosen room if list of room displyed
        IF i_id_room IS NOT NULL
        THEN
            l_id_wl_mach := pk_wlcore.get_mach_of_room(i_id_room);
            l_wroom      := i_id_room;
        END IF;
    
        g_error := 'GET EXISTING TICKET';
        pk_alertlog.log_debug(g_error, g_package_name);
        BEGIN
            SELECT DISTINCT wl.id_wl_waiting_line
              INTO l_id_wl
              FROM wl_waiting_line wl
             INNER JOIN wl_call_queue wcq
                ON wcq.id_wl_waiting_line = wl.id_wl_waiting_line
             WHERE wl.id_episode = i_id_episode
               AND wl.id_professional = i_prof.id;
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        IF l_id_wl IS NULL
        THEN
            g_error := 'GET EPIS INFO';
            pk_alertlog.log_debug(g_error, g_package_name);
            SELECT ep.id_patient, ep.id_clinical_service
              INTO l_id_pat, l_clin_serv
              FROM episode ep
             WHERE ep.id_episode = i_id_episode;
        
            g_error := 'GET QUEUE INFO';
            pk_alertlog.log_debug(g_error, g_package_name);
            IF l_demo
            THEN
                SELECT wq.id_wl_queue
                  INTO l_wl_queue
                  FROM wl_queue wq
                 INNER JOIN wl_machine wm
                    ON wm.id_wl_queue_group = wq.id_wl_queue_group
                   AND wq.flg_type_queue = pk_alert_constant.g_wr_wq_type_d
                   AND wm.id_wl_machine = l_id_wl_mach
                   AND wm.flg_demo = pk_alert_constant.g_yes;
            ELSE
                SELECT wq.id_wl_queue
                  INTO l_wl_queue
                  FROM wl_queue wq
                 INNER JOIN room r
                    ON r.id_department = wq.id_department
                   AND r.id_room = l_wroom
                 INNER JOIN wl_machine wm
                    ON wm.id_room = r.id_room
                   AND wm.id_wl_queue_group = wq.id_wl_queue_group
                   AND wq.flg_type_queue = pk_alert_constant.g_wr_wq_type_d
                   AND wm.id_wl_machine = l_id_wl_mach;
            END IF;
        
            g_error := 'INSERT TICKET';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            l_id_wl := ts_wl_waiting_line.next_key;
            ts_wl_waiting_line.ins(id_wl_waiting_line_in  => l_id_wl,
                                   id_clinical_service_in => l_clin_serv,
                                   id_professional_in     => i_prof.id,
                                   id_wl_queue_in         => l_wl_queue,
                                   id_patient_in          => l_id_pat,
                                   id_room_in             => l_wroom,
                                   id_episode_in          => i_id_episode,
                                   dt_begin_tstz_in       => current_timestamp,
                                   dt_consult_tstz_in     => current_timestamp,
                                   flg_wl_status_in       => pk_alert_constant.g_wr_wl_status_a,
                                   rows_out               => l_rows);
        
            g_error := 'PROCESS INSERT WITH WL_WAITING_LINE = ' || l_id_wl;
            pk_alertlog.log_debug(g_error, g_package_name);
            t_data_gov_mnt.process_insert(i_lang, i_prof, 'WL_WAITING_LINE', l_rows, o_error);
        END IF;
    
        g_error := 'GET SCREEN MACHINES';
        pk_alertlog.log_debug(g_error, g_package_name);
        IF NOT pk_wlcore.get_screen_mach(i_lang          => i_lang,
                                         i_prof          => i_prof,
                                         i_id_wl_mach    => l_id_wl_mach,
                                         o_id_wl_screens => l_screen_machine,
                                         o_error         => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'PROCESS SCREEN MACHINES';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        FOR i IN l_screen_machine.first .. l_screen_machine.last
        LOOP
            g_error := 'CALL SET_ITEM_CALL_QUEUE WITH  ID_WL_WAITING_LINE=' || l_id_wl || ' AND ID_MACH=' ||
                       l_screen_machine(i);
            pk_alertlog.log_debug(g_error, g_package_name);
            IF NOT set_item_call_queue(i_lang          => i_lang,
                                       i_id_wl         => l_id_wl,
                                       i_id_mach_ped   => l_screen_machine(i),
                                       i_prof          => i_prof,
                                       i_id_mach_dest  => l_id_wl_mach,
                                       i_id_episode    => i_id_episode,
                                       i_id_room       => i_id_room,
                                       o_message_audio => o_message_audio,
                                       o_sound_file    => o_sound_file,
                                       o_mac           => o_mac,
                                       o_msg           => o_msg,
                                       o_error         => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END LOOP;
    
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
                                              'SET_ITEM_CALL_EPIS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_item_call_epis;

    /**
    * Generates a call to patient. Unlike the set_item_call_queue family of functions, it does not depend on
    * ticket or episodes, thus allowing the Screen application to call patients without them being efectivated
    * or taking a ticket. Also, this function assumes that the machine of the professional calling the patient is on the
    * same clinical service than the screen.
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_ID_PAT  The patient id
    * @param   O_MESSAGE_AUDIO The audio message in text
    * @param   O_SOUND_FILE The sound file created
    * @param   O_MAC Machines to issue the call
    * @param   O_MSG Id of WL_CALL_QUEUE
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ricardo Nuno Almeida
    * @version 0.1
    * @since   26-01-2009
    */
    FUNCTION set_item_call
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_pat        IN patient.id_patient%TYPE,
        o_message_audio OUT VARCHAR2,
        o_sound_file    OUT VARCHAR2,
        o_mac           OUT table_varchar,
        o_msg           OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_clin_machine              wl_machine.id_wl_machine%TYPE;
        l_screen_machine            table_number; --wl_machine.id_wl_machine%TYPE;
        l_id_wl                     wl_waiting_line.id_wl_waiting_line%TYPE;
        l_dep                       department.id_department%TYPE := NULL;
        l_dt_begin                  TIMESTAMP WITH LOCAL TIME ZONE := pk_date_utils.trunc_insttimezone(i_prof, nvl(pk_date_utils.get_string_tstz(i_lang, i_prof, '', NULL), current_timestamp));
        l_dt_end                    TIMESTAMP WITH LOCAL TIME ZONE := pk_date_utils.add_days_to_tstz(l_dt_begin, 1);
        l_dt_cons                   TIMESTAMP WITH LOCAL TIME ZONE;
        l_prof_cat                  category.flg_clinical%TYPE;
        l_id_prof                   professional.id_professional%TYPE;
        l_clin_serv                 clinical_service.id_clinical_service%TYPE;
        l_wl_queue                  wl_queue.id_wl_queue%TYPE;
        l_wroom                     room.id_room%TYPE;
        l_rows                      table_varchar;
        l_demo                      BOOLEAN := FALSE;
        l_waiting_room_sys_external sys_config.value%TYPE;
    
    BEGIN
        --Validate if external admission system is available 
        l_waiting_room_sys_external := pk_sysconfig.get_config('WAITING_ROOM_EXTERNAL_SYSTEM', i_prof);
    
        IF l_waiting_room_sys_external = pk_alert_constant.get_yes
        THEN
            g_error := 'pk_wlservices.set_item_call_external';
            IF NOT pk_wlservices.set_item_call_external(i_lang, i_prof, i_id_pat, o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSE
            l_demo := pk_sysconfig.get_config(pk_wlcore.g_wl_demo_flg, i_prof.institution, i_prof.software) =
                      pk_alert_constant.get_yes;
        
            -- 2009-03-17
            -- As of today, registars may now invoke this function and perform their own calls. 
            -- Hence, a new circuit must be implemented; also it is now necessary to find out the category of the 
            -- professional in order to opt between the circuits
            g_error := 'GET PROF CAT';
            pk_alertlog.log_debug(g_error);
            SELECT c.flg_clinical
              INTO l_prof_cat
              FROM prof_cat pc
             INNER JOIN category c
                ON pc.id_category = c.id_category
             WHERE pc.id_professional = i_prof.id
               AND pc.id_institution = i_prof.institution;
        
            g_error := 'FIND EXISTANT TICKET';
            pk_alertlog.log_debug(g_error);
            IF l_demo
            THEN
                SELECT COUNT(wwl.id_wl_waiting_line)
                  INTO l_id_wl
                  FROM wl_waiting_line wwl
                 INNER JOIN wl_queue wq
                    ON wq.id_wl_queue = wwl.id_wl_queue
                 WHERE wwl.id_patient = i_id_pat
                   AND wq.flg_type_queue IN (pk_alert_constant.g_wr_wq_type_d,
                                             pk_alert_constant.g_wr_wq_type_n,
                                             pk_alert_constant.g_wr_wq_type_c)
                   AND wwl.dt_consult_tstz BETWEEN l_dt_begin AND l_dt_end;
            ELSE
                SELECT COUNT(wwl.id_wl_waiting_line)
                  INTO l_id_wl
                  FROM wl_waiting_line wwl
                 INNER JOIN wl_queue wq
                    ON wq.id_wl_queue = wwl.id_wl_queue
                 INNER JOIN department d
                    ON d.id_department = wq.id_department
                 WHERE wwl.id_patient = i_id_pat
                   AND d.id_institution = i_prof.institution
                   AND wq.flg_type_queue IN (pk_alert_constant.g_wr_wq_type_d,
                                             pk_alert_constant.g_wr_wq_type_n,
                                             pk_alert_constant.g_wr_wq_type_c)
                   AND wwl.dt_consult_tstz BETWEEN l_dt_begin AND l_dt_end;
            END IF;
        
            IF l_prof_cat = pk_alert_constant.get_yes
               AND l_id_wl > 0
            THEN
                --Finds both the professional's and the screens' machines.
                -- If the params are not correctly consistent, there will be a problem.
                -- IF i_dep IS NULL, room validation is ignored (old model)
                g_error := 'FIND CLIN PROF MACHINE';
                pk_alertlog.log_debug(g_error, g_package_name);
                IF NOT pk_wlcore.get_prof_wl_mach(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  io_dep       => l_dep,
                                                  o_id_wl_mach => l_clin_machine,
                                                  o_id_wl_room => l_wroom,
                                                  o_error      => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
                g_error := 'FIND CLIN SCREEN MACHINES';
                pk_alertlog.log_debug(g_error, g_package_name);
                IF NOT pk_wlcore.get_screen_mach(i_lang          => i_lang,
                                                 i_prof          => i_prof,
                                                 i_id_wl_mach    => l_clin_machine,
                                                 o_id_wl_screens => l_screen_machine,
                                                 o_error         => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
            ELSE
                IF l_id_wl = 0
                THEN
                    IF l_demo
                    THEN
                        g_error := 'GET DATA';
                        pk_alertlog.log_debug(g_error);
                        SELECT data.id_department,
                               data.id_clinical_service,
                               data.id_professional,
                               data.id_wl_machine,
                               data.id_wl_queue,
                               data.id_room_wait
                          INTO l_dep, l_clin_serv, l_id_prof, l_clin_machine, l_wl_queue, l_wroom
                          FROM (SELECT wq.id_department,
                                       dcs.id_clinical_service,
                                       spo.id_professional,
                                       wm.id_wl_machine,
                                       wq.id_wl_queue,
                                       NULL                    id_room_wait,
                                       so.dt_target_tstz,
                                       1                       rank
                                  FROM sch_group sg
                                 INNER JOIN schedule_outp so
                                    ON so.id_schedule = sg.id_schedule
                                 INNER JOIN schedule s
                                    ON so.id_schedule = s.id_schedule
                                 INNER JOIN sch_prof_outp spo
                                    ON spo.id_schedule_outp = so.id_schedule_outp
                                 INNER JOIN dep_clin_serv dcs
                                    ON dcs.id_dep_clin_serv = s.id_dcs_requested
                                 INNER JOIN wl_queue wq
                                    ON wq.id_department = pk_wlcore.g_demo_department_0
                                   AND wq.flg_type_queue NOT IN (pk_alert_constant.g_wr_wq_type_a)
                                 INNER JOIN wl_machine wm
                                    ON wm.flg_demo = pk_alert_constant.get_yes
                                   AND wq.id_wl_queue_group = wm.id_wl_queue_group
                                 WHERE sg.id_patient = i_id_pat
                                   AND so.id_software = i_prof.software
                                   AND s.id_instit_requested = i_prof.institution
                                   AND so.dt_target_tstz BETWEEN l_dt_begin AND l_dt_end) data
                         WHERE rownum = 1;
                    ELSE
                        g_error := 'GET DATA';
                        pk_alertlog.log_debug(g_error);
                        SELECT data.id_department,
                               data.id_clinical_service,
                               data.id_professional,
                               data.id_wl_machine,
                               data.id_wl_queue,
                               data.id_room_wait
                          INTO l_dep, l_clin_serv, l_id_prof, l_clin_machine, l_wl_queue, l_wroom
                          FROM (SELECT dcs.id_department,
                                       dcs.id_clinical_service,
                                       spo.id_professional,
                                       wm.id_wl_machine,
                                       wq.id_wl_queue,
                                       wwr.id_room_wait,
                                       so.dt_target_tstz,
                                       1 rank
                                  FROM sch_group sg
                                 INNER JOIN schedule_outp so
                                    ON so.id_schedule = sg.id_schedule
                                 INNER JOIN schedule s
                                    ON so.id_schedule = s.id_schedule
                                 INNER JOIN sch_prof_outp spo
                                    ON spo.id_schedule_outp = so.id_schedule_outp
                                 INNER JOIN dep_clin_serv dcs
                                    ON dcs.id_dep_clin_serv = s.id_dcs_requested
                                 INNER JOIN wl_queue wq
                                    ON wq.id_department = dcs.id_department
                                   AND wq.flg_type_queue NOT IN (pk_alert_constant.g_wr_wq_type_a)
                                 INNER JOIN prof_room pr
                                    ON pr.id_professional = spo.id_professional
                                   AND pr.flg_pref = pk_alert_constant.get_yes
                                 INNER JOIN wl_machine wm
                                    ON wm.id_room = pr.id_room
                                   AND wq.id_wl_queue_group = wm.id_wl_queue_group
                                 INNER JOIN wl_waiting_room wwr
                                    ON wwr.id_room_consult = wm.id_room
                                 WHERE sg.id_patient = i_id_pat
                                   AND so.id_software = i_prof.software
                                   AND s.id_instit_requested = i_prof.institution
                                   AND so.dt_target_tstz BETWEEN l_dt_begin AND l_dt_end
                                UNION ALL
                                SELECT dcs.id_department,
                                       dcs.id_clinical_service,
                                       i_prof.id,
                                       wm.id_wl_machine,
                                       wq.id_wl_queue,
                                       wwr.id_room_wait,
                                       so.dt_target_tstz,
                                       2 rank
                                  FROM sch_group sg
                                 INNER JOIN schedule_outp so
                                    ON so.id_schedule = sg.id_schedule
                                 INNER JOIN schedule s
                                    ON so.id_schedule = s.id_schedule
                                 INNER JOIN dep_clin_serv dcs
                                    ON dcs.id_dep_clin_serv = s.id_dcs_requested
                                 INNER JOIN wl_queue wq
                                    ON wq.id_department = dcs.id_department
                                   AND wq.flg_type_queue NOT IN (pk_alert_constant.g_wr_wq_type_a)
                                 INNER JOIN prof_room pr
                                    ON pr.id_professional = i_prof.id
                                   AND pr.flg_pref = pk_alert_constant.g_yes
                                 INNER JOIN wl_machine wm
                                    ON wm.id_room = pr.id_room
                                   AND wq.id_wl_queue_group = wm.id_wl_queue_group
                                 INNER JOIN wl_waiting_room wwr
                                    ON wwr.id_room_consult = wm.id_room
                                 WHERE sg.id_patient = i_id_pat
                                   AND so.id_software = i_prof.software
                                   AND s.id_instit_requested = i_prof.institution
                                 ORDER BY rank ASC, dt_target_tstz) data
                         WHERE rownum = 1;
                    END IF;
                
                    g_error := 'INSERT INTO WL_WAITING_LINE';
                    pk_alertlog.log_debug(g_error, g_package_name);
                    ts_wl_waiting_line.ins(id_wl_waiting_line_in  => ts_wl_waiting_line.next_key,
                                           id_clinical_service_in => l_clin_serv,
                                           id_professional_in     => l_id_prof,
                                           id_wl_queue_in         => l_wl_queue,
                                           id_patient_in          => i_id_pat,
                                           id_room_in             => l_wroom,
                                           dt_begin_tstz_in       => current_timestamp,
                                           dt_consult_tstz_in     => l_dt_cons,
                                           flg_wl_status_in       => pk_alert_constant.g_wr_wl_status_a,
                                           rows_out               => l_rows);
                
                    g_error := 'PROCESS INSERT WITH WL_WAITING_LINE ';
                    pk_alertlog.log_debug(g_error, g_package_name);
                    t_data_gov_mnt.process_insert(i_lang, i_prof, 'WL_WAITING_LINE', l_rows, o_error);
                
                ELSE
                    g_error := 'GET WL';
                    SELECT wwl.id_wl_waiting_line
                      INTO l_id_wl
                      FROM wl_waiting_line wwl
                     INNER JOIN wl_queue wq
                        ON wq.id_wl_queue = wwl.id_wl_queue
                     INNER JOIN department d
                        ON wq.id_department = wq.id_department
                     WHERE wwl.id_patient = i_id_pat
                       AND d.id_institution = i_prof.institution
                       AND wq.flg_type_queue IN (pk_alert_constant.g_wr_wq_type_d,
                                                 pk_alert_constant.g_wr_wq_type_n,
                                                 pk_alert_constant.g_wr_wq_type_c)
                       AND wwl.dt_consult_tstz BETWEEN l_dt_begin AND l_dt_end
                       AND rownum = 1;
                
                    g_error := 'GET EXISTANT DATA';
                    SELECT wq.id_department, wm.id_wl_machine
                      INTO l_dep, l_clin_machine
                      FROM wl_waiting_line wwl
                     INNER JOIN wl_queue wq
                        ON wq.id_wl_queue = wwl.id_wl_queue
                     INNER JOIN wl_waiting_room wwr
                        ON wwr.id_room_wait = wwl.id_room
                     INNER JOIN wl_machine wm
                        ON wm.id_room = wwr.id_room_consult
                       AND wm.id_wl_queue_group = wq.id_wl_queue_group
                     WHERE wwl.id_wl_waiting_line = l_id_wl;
                END IF;
            
                g_error := 'FIND SCREEN PROF MACHINE';
                IF l_demo
                THEN
                    SELECT wm.id_wl_machine
                      BULK COLLECT
                      INTO l_screen_machine
                      FROM wl_machine wm
                     WHERE wm.id_wl_machine = l_clin_machine
                       AND wm.flg_video_active = pk_alert_constant.g_yes
                     ORDER BY wm.flg_audio_active DESC;
                ELSE
                    SELECT wm_s.id_wl_machine
                      BULK COLLECT
                      INTO l_screen_machine
                      FROM wl_waiting_room wwr
                     INNER JOIN wl_machine wm_s
                        ON wwr.id_room_wait = wm_s.id_room
                     INNER JOIN wl_machine wm_c
                        ON wwr.id_room_consult = wm_c.id_room
                       AND wm_c.id_wl_queue_group = wm_s.id_wl_queue_group
                     WHERE wm_c.id_wl_machine = l_clin_machine
                       AND wm_s.flg_video_active = pk_alert_constant.g_yes
                     ORDER BY wm_s.flg_audio_active DESC;
                END IF;
            
            END IF;
        
            g_error := 'FINDS IF SW IS VALID';
            pk_alertlog.log_debug(g_error);
            IF i_prof.software IN (1, 3, 12)
            THEN
                -- tickets
                -- Must not filter by professional, because schedule might be for a doctor and 
                -- there's the pre-medical nurse consult, where the nurse will issue a call for the patient too.
                BEGIN
                    SELECT wwl.id_wl_waiting_line
                      INTO l_id_wl
                      FROM wl_waiting_line wwl
                     INNER JOIN wl_queue wq
                        ON wq.id_wl_queue = wwl.id_wl_queue
                     INNER JOIN wl_machine wm
                        ON wm.id_wl_queue_group = wq.id_wl_queue_group
                     WHERE wq.id_department = l_dep
                       AND wwl.id_patient = i_id_pat
                       AND wm.id_wl_machine = l_clin_machine
                       AND wwl.dt_begin_tstz BETWEEN l_dt_begin AND l_dt_end
                       AND rownum = 1;
                
                EXCEPTION
                    WHEN no_data_found THEN
                        pk_alertlog.log_error('l_dep: ' || l_dep);
                        pk_alertlog.log_error('l_clin_machine: ' || l_clin_machine);
                        pk_alertlog.log_error('i_id_pat: ' || i_id_pat);
                        pk_alertlog.log_error('l_dt_begin: ' || l_dt_begin);
                        pk_alertlog.log_error('l_dt_end: ' || l_dt_end);
                        RAISE;
                END;
            
                FOR i IN l_screen_machine.first .. l_screen_machine.last
                LOOP
                    g_error := 'CALL SET_ITEM_CALL_QUEUE';
                    IF NOT set_item_call_queue(i_lang          => i_lang,
                                               i_id_wl         => l_id_wl,
                                               i_id_mach_ped   => l_screen_machine(i),
                                               i_prof          => i_prof,
                                               i_id_mach_dest  => l_clin_machine,
                                               i_id_room       => NULL,
                                               o_message_audio => o_message_audio,
                                               o_sound_file    => o_sound_file,
                                               o_mac           => o_mac,
                                               o_msg           => o_msg,
                                               o_error         => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                
                END LOOP;
            ELSE
                -- No tickets
                -- TO-DO: 100% free call.
                NULL;
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
                                              'SET_ITEM_CALL',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_item_call;

    /********************************************************************************************
    *
    * Shortcut to the function @ PK_WLCORE. This happens because even though  set_item_call_queue_sound_gen does not have 
    * any associated java logic, it is nevertheless called by the middleware and therefore needs to be instanciated 
    * in this package, to avoid instanciating two diferent packages instead of one.
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_SOUND_FILE The sound file name.
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ricardo Nuno Almeida
    * @version 1.0
    * @since   04-03-2009
    **********************************************************************************************/
    FUNCTION set_item_call_queue_sound_gen
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_sound_file IN VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL SET_ITEM_CALL_QUEUE_SOUND_GEN';
        RETURN pk_wlcore.set_item_call_queue_sound_gen(i_lang       => i_lang,
                                                       i_prof       => i_prof,
                                                       i_sound_file => i_sound_file,
                                                       o_error      => o_error);
    
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
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_item_call_queue_sound_gen;

    /********************************************************************************************
    *
    * Shortcut to the function @ PK_WLSESSION. This happens because even though  UNSET_QUEUES does not have 
    * any associated java logic, it is nevertheless called by the middleware and therefore needs to be instanciated 
    * in this package, to avoid instanciating two diferent packages instead of one.
    *    
    * @param   I_PROF  professional, institution and software ids
    * @param   I_ID_MACH   ID of the machine.
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ricardo Nuno Almeida
    * @version 1.0
    * @since   26-03-2009
    **********************************************************************************************/
    FUNCTION unset_queues
    (
        i_prof    IN profissional,
        i_id_mach IN wl_machine.id_wl_machine%TYPE
    ) RETURN BOOLEAN IS
    
        l_lang language.id_language%TYPE;
        l_err  t_error_out;
    
    BEGIN
        g_error := 'GET LANG';
        l_lang  := pk_sysconfig.get_config(i_code_cf => 'WL_LANG', i_prof => i_prof);
    
        g_error := 'CALL UNSET_QUEUES';
        RETURN pk_wlsession.unset_queues(i_lang => l_lang, i_prof => i_prof, i_id_mach => i_id_mach, o_error => l_err);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(l_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'UNSET_QUEUES',
                                              l_err);
            pk_utils.undo_changes;
            RETURN FALSE;
    END unset_queues;
    /**
    * Notify the patient call to external admission software
    *
    * Notify the patient call to external admission software
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param  i_id_episode epsisode
    */

    FUNCTION set_item_call_external
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_episode     episode.id_episode%TYPE;
        l_institution NUMBER;
    
    BEGIN
    
        pk_ia_event_common.episode_call(i_prof.id, i_prof.institution, i_id_episode);
    
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
    END set_item_call_external;

    PROCEDURE inicialize IS
    
    BEGIN
    
        xsp                := chr(32);
        pk_med_msg_01      := 'MED_MSG_01';
        pk_med_msg_02      := 'MED_MSG_02';
        pk_wl_titulo       := 'WL_TITULO';
        pk_med_msg_tit_01  := 'MED_MSG_TIT_01';
        pk_med_msg_tit_02  := 'MED_MSG_TIT_02';
        pk_med_msg_tit_03  := 'MED_MSG_TIT_03';
        pk_voice           := 'V';
        pk_bip             := 'B';
        pk_none            := 'N';
        pk_wavfile_prefix  := 'CALL_';
        pk_wavfile_sufix   := '000.WAV';
        pk_wl_wav_bip_name := 'WL_WAV_BIP_NAME';
        pk_wl_id_sonho     := 'WL_ID_SONHO';
        pk_pendente        := 'P';
    
    END inicialize;

BEGIN

    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

    inicialize();

END pk_wlservices;
/
