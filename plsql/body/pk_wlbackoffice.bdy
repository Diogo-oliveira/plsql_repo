/*-- Last Change Revision: $Rev: 2027881 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:35 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_wlbackoffice IS

    /****************************************************************************************
    FUNCTION: GET_ROOMS_WAIT_MED
    GOAL: DEVOLVER AS ASSOCIAÇÕES EXISTENTES ENTRE AS SALAS DE CONSULTA E AS SALAS DE ESPERA
    PARAM OUT: O_DATA_ROOMS CURSOR_TYPE: CURSOR COM OS DADOS DA ASSOCIACAO
    ****************************************************************************************/

    FUNCTION get_rooms_wait_med
    (
        i_lang       IN language.id_language%TYPE,
        o_error      OUT t_error_out,
        o_data_rooms OUT pk_types.cursor_type
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN CURSOR';
        OPEN o_data_rooms FOR
            SELECT cro.id_room,
                   wro.id_room,
                   dpt.id_department,
                   pk_translation.get_translation(i_lang, dpt.code_department),
                   nvl(cro.desc_room, pk_translation.get_translation(i_lang, cro.code_room)),
                   nvl(wro.desc_room, pk_translation.get_translation(i_lang, wro.code_room))
              FROM wl_waiting_room wr, department dpt, room cro, room wro
             WHERE cro.id_department = dpt.id_department
               AND wr.id_room_consult = cro.id_room
               AND wr.id_room_wait = wro.id_room;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(1,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ROOMS_WAIT_MED',
                                              o_error);
            pk_types.open_my_cursor(o_data_rooms);
        
    END get_rooms_wait_med;

    -- ##############################################################################

    /********************************************************************************
    FUNCTION : GET_CATEGORY
    GOAL     : RETURNS CATEGORIES
    PARAM OUT: O_CAT CURSOR_TYPE: CURSOR WITH CATEGORY OF PROFESSIONALS
    *********************************************************************************/
    FUNCTION get_category
    (
        o_cat   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN CURSOR';
        OPEN o_cat FOR
            SELECT id_category, flg_type, pk_translation.get_translation(g_language_num, code_category) desc_category
              FROM category
             WHERE flg_available = 'Y'
             ORDER BY desc_category;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(1,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CATEGORY',
                                              o_error);
            pk_types.open_my_cursor(o_cat);
        
    END get_category;
    -- ##############################################################################

    /********************************************************************************
    FUNCTION: GET_MACHINE_QUEUE
    GOAL: DEVOLVER AS ASSOCIAÇÕES EXISTENTES ENTRE AS QUEUES E AS MAQUINAS ASSOCIADAS
    PARAM OUT: O_DATA_MACH_QUEUE CURSOR_TYPE: CURSOR COM OS DADOS DA ASSOCIACAO
    *********************************************************************************/
    FUNCTION get_department
    (
        i_id_institution IN institution.id_institution%TYPE,
        o_dpt            OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        g_id_institution NUMBER;
    BEGIN
    
        OPEN o_dpt FOR
            SELECT dpt.id_department,
                   dpt.abbreviation,
                   pk_translation.get_translation(g_language_num, dpt.code_department) desc_department
              FROM department dpt
             WHERE dpt.id_institution = nvl(i_id_institution, g_id_institution)
               AND dpt.flg_available = g_flg_available
             ORDER BY desc_department;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(1,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DEPARTMENT',
                                              o_error);
            pk_types.open_my_cursor(o_dpt);
        
    END get_department;
    -- ##############################################################################

    /********************************************************************************
    FUNCTION : GET_CLINICAL_SERVICE
    GOAL     : RETURNS CLINICAL SERVICES OF TARGET DEPARTMENT
    PARAM_IN : I_ID_DEPARTMENT NUMBER : ID OF TARGET DEPARTMENT
    PARAM OUT: O_SRV CURSOR_TYPE: CURSOR OF CLINICAL SERVICES
    *********************************************************************************/
    FUNCTION get_clinical_service
    (
        i_id_department IN department.id_department%TYPE,
        o_srv           OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET_CLINICAL_SERVICE';
        OPEN o_srv FOR
            SELECT dcs.id_dep_clin_serv,
                   dcs.id_clinical_service,
                   cls.rank,
                   pk_translation.get_translation(g_language_num, cls.code_clinical_service) desc_service
              FROM dep_clin_serv dcs, clinical_service cls
             WHERE dcs.id_department = i_id_department
               AND cls.id_clinical_service = dcs.id_clinical_service
               AND dcs.flg_available = g_flg_available
               AND cls.flg_available = g_flg_available
             ORDER BY dcs.rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(1,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CLINICAL_SERVICES',
                                              o_error);
            pk_types.open_my_cursor(o_srv);
        
    END get_clinical_service;
    -- ##############################################################################

    /********************************************************************************
    FUNCTION: GET_MACHINE_QUEUE
    GOAL: DEVOLVER AS ASSOCIAÇÕES EXISTENTES ENTRE AS QUEUES E AS MAQUINAS ASSOCIADAS
    PARAM OUT: O_DATA_MACH_QUEUE CURSOR_TYPE: CURSOR COM OS DADOS DA ASSOCIACAO
    *********************************************************************************/
    FUNCTION get_machine_queue
    (
        i_id_department   IN department.id_department%TYPE,
        o_data_mach_queue OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET MACHINE QUEUE';
        OPEN o_data_mach_queue FOR
            SELECT wq.id_wl_queue, wq.code_name_queue, wm.machine_name, wm.flg_audio_active, wm.flg_video_active
              FROM wl_queue wq, wl_msg_queue wmq, wl_machine wm
             WHERE wq.flg_visible = 'Y'
               AND wq.flg_type_queue = g_flg_type_queue_registar
               AND wq.id_department = i_id_department
               AND wmq.id_wl_id_queue = wq.id_wl_queue
               AND wmq.id_wl_mach_dest = wm.id_wl_machine;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(1,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_MACHINE_QUEUE',
                                              o_error);
            pk_types.open_my_cursor(o_data_mach_queue);
        
    END get_machine_queue;
    -- ######################################################################################################

    /********************************************************************************
    FUNCTION: GET_MACHINE
    GOAL: DEVOLVER AS MAQUINAS
    PARAM OUT: I_ID_DEPARTMENT IN NUMBER, O_MAC CURSOR_TYPE: CURSOR COM OS DADOS DA ASSOCIACAO
    *********************************************************************************/
    FUNCTION get_user
    (
        o_user  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN CURSOR';
        OPEN o_user FOR
            SELECT prf.id_professional,
                   prf.name            name,
                   prf.nick_name       nick_name,
                   prf.dt_birth        dt_birth,
                   prf.gender          gender,
                   prf.num_order       num_order,
                   usr.login           prf_login,
                   pes.value           num_sonho,
                   dmn.desc_val        desc_category,
                   cat.id_category     id_category
              FROM professional prf, category cat, prof_cat pca, prof_ext_sys pes, ab_user_info usr, sys_domain dmn
             WHERE dmn.code_domain = pk_wl_category
               AND dmn.id_language = g_language_num
               AND dmn.domain_owner = pk_sysdomain.k_default_schema
               AND cat.flg_type = dmn.val
               AND cat.id_category = pca.id_category
               AND prf.id_professional = pca.id_professional
               AND prf.id_professional = pes.id_professional
               AND prf.id_professional = usr.id_ab_user_info
               AND pes.id_external_sys = g_id_sonho
             ORDER BY cat.flg_type, prf.name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(1,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_USER',
                                              o_error);
            pk_types.open_my_cursor(o_user);
    END get_user;
    -- ######################################################################################################

    /********************************************************************************
    FUNCTION: GET_MACHINE
    GOAL: DEVOLVER AS MAQUINAS
    PARAM OUT: I_ID_DEPARTMENT IN NUMBER, O_MAC CURSOR_TYPE: CURSOR COM OS DADOS DA ASSOCIACAO
    *********************************************************************************/
    FUNCTION get_machine
    (
        i_id_department IN department.id_department%TYPE,
        o_mac           OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN CURSOR';
        OPEN o_mac FOR
            SELECT mac.id_wl_machine,
                   mac.machine_name,
                   mac.flg_audio_active,
                   mac.flg_video_active,
                   mac.cod_desc_machine_visual,
                   mac.cod_desc_machine_audio,
                   mac.id_room,
                   pk_translation.get_translation(g_language_num, dpt.code_department) desc_department,
                   nvl(roo.desc_room, pk_translation.get_translation(g_language_num, roo.code_room)) desc_room
              FROM wl_machine mac, room roo, department dpt
             WHERE roo.id_room = mac.id_room
               AND roo.id_department = dpt.id_department
               AND roo.id_department = i_id_department
             ORDER BY desc_department, mac.machine_name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(1,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_MACHINE',
                                              o_error);
            pk_types.open_my_cursor(o_mac);
        
    END get_machine;
    -- ##########################################################################################

    --
    /********************************************************************************
    FUNCTION: GET_CONFIG
    GOAL: RETORNA PARAMETROS DE SYS_CONFIG
    PARAM OUT: O_CFG CURSOR_TYPE: CURSOR COM OS PARAMETROS DE SYS_CONFIG DO WL
    *********************************************************************************/
    FUNCTION get_config
    (
        o_cfg   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'OPEN CURSOR';
        OPEN o_cfg FOR
            SELECT id_sys_config, VALUE, desc_sys_config
              FROM sys_config
             WHERE id_sys_config IN (SELECT val
                                       FROM sys_domain
                                      WHERE code_domain = pk_wl_lst_cfg
                                        AND domain_owner = pk_sysdomain.k_default_schema)
             ORDER BY desc_sys_config;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(1,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CONFIG',
                                              o_error);
            pk_types.open_my_cursor(o_cfg);
        
    END get_config;
    -- ##########################################################################################

    FUNCTION set_move_machine
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_mach  IN wl_machine.id_wl_machine%TYPE,
        i_room  IN room.id_room%TYPE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'SET_MOVE_MACHINE';
        UPDATE wl_machine wm
           SET wm.id_room = i_room
         WHERE wm.id_wl_machine = i_mach;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(1,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_MOVE_MACHINE',
                                              o_error);
            RETURN FALSE;
    END set_move_machine;

    FUNCTION set_group_machine
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_mach     IN wl_machine.id_wl_machine%TYPE,
        i_wl_group IN wl_queue_group.id_wl_queue_group%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'SET_GROUP_MACHINE';
        UPDATE wl_machine wm
           SET wm.id_wl_queue_group = i_wl_group
         WHERE wm.id_wl_machine = i_mach;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(1,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_GROUP_MACHINE',
                                              o_error);
            RETURN FALSE;
    END set_group_machine;

    /********************************************************************************
    FUNCTION: INSERT_MACHINE
    GOAL: Inserir Máquinas e registo correspondente nos interfaces para Sonho
    PARAM OUT: O_DATA_MACH_QUEUE CURSOR_TYPE: CURSOR COM OS DADOS DA ASSOCIACAO
    *********************************************************************************/
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
    ) RETURN BOOLEAN IS
        xmac wl_machine%ROWTYPE;
    BEGIN
    
        xmac.id_wl_machine           := i_id_wl_machine;
        xmac.machine_name            := i_intern_name;
        xmac.flg_audio_active        := i_flg_audio;
        xmac.flg_video_active        := i_flg_video;
        xmac.id_room                 := i_id_room;
        xmac.cod_desc_machine_visual := i_desc_visual;
        xmac.cod_desc_machine_audio  := i_desc_audio;
    
        IF i_mode = 'INS'
        THEN
        
            SELECT seq_wl_machine.nextval
              INTO xmac.id_wl_machine
              FROM dual;
        
            INSERT INTO wl_machine
                (id_wl_machine,
                 machine_name,
                 flg_audio_active,
                 flg_video_active,
                 id_room,
                 cod_desc_machine_visual,
                 cod_desc_machine_audio)
            VALUES
                (xmac.id_wl_machine,
                 xmac.machine_name,
                 xmac.flg_audio_active,
                 xmac.flg_video_active,
                 xmac.id_room,
                 xmac.cod_desc_machine_visual,
                 xmac.cod_desc_machine_audio);
        
        ELSIF i_mode = 'UPD'
        THEN
        
            UPDATE wl_machine
               SET machine_name            = xmac.machine_name,
                   flg_audio_active        = xmac.flg_audio_active,
                   flg_video_active        = xmac.flg_video_active,
                   id_room                 = xmac.id_room,
                   cod_desc_machine_visual = xmac.cod_desc_machine_visual,
                   cod_desc_machine_audio  = xmac.cod_desc_machine_audio
             WHERE id_wl_machine = i_id_wl_machine;
        
        ELSIF i_mode = 'DEL'
        THEN
            NULL;
        
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(1,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_MACHINE',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_machine;
    -- ######################################################################################################

    /********************************************************************************
    FUNCTION: INSERT_QUEUE
    GOAL: Inserir Máquinas e registo correspondente nos interfaces para Sonho
    PARAM OUT: O_DATA_MACH_QUEUE CURSOR_TYPE: CURSOR COM OS DADOS DA ASSOCIACAO
    *********************************************************************************/
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
    ) RETURN BOOLEAN IS
        xque wl_queue%ROWTYPE;
        --        xtra translation%ROWTYPE;
    
        TYPE xtra_t IS RECORD(
            id_language      language.id_language%TYPE,
            code_translation translation.code_translation%TYPE,
            desc_translation pk_translation.t_desc_translation);
        xtra xtra_t;
        CURSOR c_lang IS
            SELECT id_language
              FROM LANGUAGE;
    
    BEGIN
    
        xque.id_wl_queue     := i_id_wl_queue;
        xque.code_name_queue := i_intern_name;
        xque.code_msg        := pk_queue_code_msg || ltrim(to_char(xque.id_wl_queue));
        xque.char_queue      := i_char_queue;
        xque.num_queue       := i_num_queue;
        xque.color           := i_color;
        xque.flg_priority    := i_flg_priority;
    
        xque.adw_last_update := SYSDATE;
        xque.flg_visible     := 'Y'; -- 'N';
        xque.flg_type_queue  := g_flg_type_queue_registar;
    
        xtra.id_language      := g_language_num;
        xtra.code_translation := pk_queue_code_msg || ltrim(to_char(xque.id_wl_queue));
        xtra.desc_translation := i_code_msg;
    
        IF i_mode = 'INS'
        THEN
        
            SELECT seq_wl_queue.nextval
              INTO xque.id_wl_queue
              FROM dual;
            --            SELECT seq_translation.NEXTVAL
            --              INTO xtra.id_translation
            --              FROM dual;
        
            xque.code_msg         := pk_queue_code_msg || ltrim(to_char(xque.id_wl_queue));
            xtra.code_translation := pk_queue_code_msg || ltrim(to_char(xque.id_wl_queue));
            xtra.desc_translation := i_code_msg;
        
            -- PREPARAR REGISTO PARA INSERCAO EM TRANSLATION
        
            -- INSERCAO EM WL_QUEUES
            INSERT INTO wl_queue
                (id_wl_queue,
                 code_name_queue,
                 code_msg,
                 char_queue,
                 color,
                 num_queue,
                 flg_visible,
                 flg_type_queue,
                 flg_priority,
                 adw_last_update)
            VALUES
                (xque.id_wl_queue,
                 xque.code_name_queue,
                 xtra.code_translation,
                 xque.char_queue,
                 xque.color,
                 xque.num_queue,
                 xque.flg_visible,
                 xque.flg_type_queue,
                 xque.flg_priority,
                 xque.adw_last_update);
        
            -- INSERCAO EM TRANSLATION
            --            INSERT INTO translation
            --                (id_translation, id_language, code_translation, desc_translation)
            --            VALUES
            --                (xtra.id_translation, xtra.id_language, xtra.code_translation, xtra.desc_translation);
        
            pk_translation.insert_into_translation(xtra.id_language, xtra.code_translation, xtra.desc_translation);
        
        ELSIF i_mode = 'UPD'
        THEN
        
            UPDATE wl_queue
               SET code_name_queue = xque.code_name_queue,
                   code_msg        = xque.code_msg,
                   char_queue      = xque.char_queue,
                   color           = xque.color,
                   num_queue       = xque.num_queue,
                   flg_visible     = xque.flg_visible,
                   flg_type_queue  = xque.flg_type_queue,
                   flg_priority    = xque.flg_priority,
                   adw_last_update = xque.adw_last_update
             WHERE id_wl_queue = xque.id_wl_queue;
        
            FOR i IN c_lang
            LOOP
                --            UPDATE translation
                --               SET desc_translation = xtra.desc_translation
                --             WHERE code_translation = xtra.code_translation;
                pk_translation.insert_into_translation(i.id_language, xtra.code_translation, xtra.desc_translation);
            END LOOP;
        
        ELSIF i_mode = 'DEL'
        THEN
            NULL;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(1,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_QUEUE',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_queue;
    -- ######################################################################################################

    /********************************************************************************
    FUNCTION: INSERT_MSG_QUEUE( I_ID_QUEUE IN TABLE_NUMBER, ID_MACH_DEST IN NUMBER )
    GOAL: Inserir Máquinas e registo correspondente nos interfaces para Sonho
    PARAM OUT: O_DATA_MACH_QUEUE CURSOR_TYPE: CURSOR COM OS DADOS DA ASSOCIACAO
    *********************************************************************************/
    FUNCTION set_msg_queue
    (
        i_mode         IN VARCHAR2,
        i_id_queue     IN table_number,
        i_id_mach_dest IN table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        xmsq wl_msg_queue%ROWTYPE;
    BEGIN
    
        IF i_mode = 'INS'
        THEN
        
            FOR i IN 1 .. i_id_queue.count
            LOOP
            
                xmsq.id_wl_id_queue  := i_id_queue(i);
                xmsq.id_wl_mach_dest := i_id_mach_dest(i);
            
                INSERT INTO wl_msg_queue
                    (id_wl_id_queue, id_wl_mach_dest)
                VALUES
                    (xmsq.id_wl_id_queue, xmsq.id_wl_mach_dest);
            
            END LOOP;
        
        ELSIF i_mode = 'UPD'
        THEN
            NULL;
        ELSIF i_mode = 'DEL'
        THEN
            NULL;
        
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(g_language_num,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_MSG_QUEUE',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_msg_queue;
    -- ########################################################################################################

    --********************************************************************************
    --********************************************************************************
    FUNCTION set_clin_service
    (
        i_mode            IN VARCHAR2,
        i_id_professional IN profissional,
        i_id_clin_serv    IN table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rowids table_varchar;
    
    BEGIN
    
        IF i_mode = 'INS'
        THEN
        
            FOR i IN 1 .. i_id_clin_serv.count
            LOOP
            
                ts_prof_dep_clin_serv.ins(id_prof_dep_clin_serv_in => ts_prof_dep_clin_serv.next_key,
                                          id_professional_in       => i_id_professional.id,
                                          id_dep_clin_serv_in      => i_id_clin_serv(i),
                                          flg_status_in            => 'D',
                                          flg_default_in           => 'N',
                                          id_institution_in        => i_id_professional.institution,
                                          dt_creation_in           => current_timestamp,
                                          rows_out                 => l_rowids);
            END LOOP;
        
        ELSIF i_mode = 'UPD'
        THEN
            NULL;
        
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(g_language_num,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_CLIN_SERVICE',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_clin_service;
    -- ###############################################################################

    --********************************************************************************
    --********************************************************************************
    FUNCTION set_waiting_room
    (
        i_mode            IN VARCHAR2,
        i_id_room_consult IN table_number,
        i_id_waiting_room IN table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        xcount NUMBER;
        xwai   wl_waiting_room%ROWTYPE;
    BEGIN
    
        IF i_mode = 'INS'
        THEN
        
            xcount  := i_id_room_consult.count;
            g_error := 'INSERT INTO WWR';
            FOR i IN 1 .. xcount
            LOOP
            
                xwai.id_room_consult := i_id_room_consult(i);
                xwai.id_room_wait    := i_id_waiting_room(i);
            
                INSERT INTO wl_waiting_room
                    (id_room_consult, id_room_wait)
                    SELECT xwai.id_room_consult, xwai.id_room_wait
                      FROM dual;
            
            END LOOP;
        ELSIF i_mode = 'DEL'
        THEN
            g_error := 'DELETE WWR';
            FOR i IN 1 .. xcount
            LOOP
            
                DELETE FROM wl_waiting_room wwr
                 WHERE wwr.id_room_consult = i_id_room_consult(i);
            END LOOP;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(g_language_num,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_WAITING_ROOM',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_waiting_room;
    -- ###############################################################################

/*****************************************************************************************/
/**********************************    CONSTRUCTOR        ********************************/
/*****************************************************************************************/

BEGIN

    xpl                  := '''';
    xsp                  := chr(32);
    g_flg_available      := 'Y';
    pk_wl_lang           := 'WL_LANG';
    pk_wl_color_queue    := 'WL_COLOR_QUEUE';
    pk_prf_active        := 'A';
    pk_wl_id_sonho       := 'WL_ID_SONHO';
    pk_wl_category       := 'WL_CATEGORY';
    pk_wl_id_institution := 'WL_ID_INSTITUTION';
    pk_wl_lst_cfg        := 'WL_LST_CFG';

    g_flg_type_queue_doctor   := 'D';
    g_flg_type_queue_nurse    := 'N';
    g_flg_type_queue_registar := 'A';
    g_flg_type_queue_nur_cons := 'C';

    pk_color_orange       := 'WL_COLOR_QUEUE_ORANGE';
    pk_color_dark_yellow  := 'WL_COLOR_QUEUE_DARK_YELLOW';
    pk_color_light_green  := 'WL_COLOR_QUEUE_LIGHT_GREEN';
    pk_color_green        := 'WL_COLOR_QUEUE_GREEN';
    pk_color_light_blue   := 'WL_COLOR_QUEUE_LIGHT_BLUE';
    pk_color_blue         := 'WL_COLOR_QUEUE_BLUE';
    pk_color_dark_blue    := 'WL_COLOR_QUEUE_DARK_BLUE';
    pk_color_light_violet := 'WL_COLOR_QUEUE_LIGHT_VIOLET';
    pk_color_violet       := 'WL_COLOR_QUEUE_VIOLET';
    pk_color_red          := 'WL_COLOR_QUEUE_RED';
    pk_queue_code_msg     := 'WL_QUEUE.CODE_MSG.';
    pk_wlcategory         := 'WL_CATEGORY';

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

--L_RET := PK_SYSCONFIG.GET_CONFIG(I_CODE_CF => PK_WL_LANG          , O_MSG_CF => G_LANGUAGE_NUM);
--L_RET := PK_SYSCONFIG.GET_CONFIG(I_CODE_CF => PK_WL_ID_SONHO      , O_MSG_CF => G_ID_SONHO );
--L_RET := PK_SYSCONFIG.GET_CONFIG(I_CODE_CF => PK_WL_ID_INSTITUTION, O_MSG_CF => G_ID_INSTITUTION);

END pk_wlbackoffice;
/
