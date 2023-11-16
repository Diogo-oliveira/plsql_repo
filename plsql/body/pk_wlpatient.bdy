/*-- Last Change Revision: $Rev: 2027894 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:37 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_wlpatient AS

    k_marker_ticket_nr CONSTANT VARCHAR2(0010 CHAR) := '@01';
    k_marker_num_proc  CONSTANT VARCHAR2(0010 CHAR) := '@02';
    k_marker_date      CONSTANT VARCHAR2(0010 CHAR) := '@03';
    k_marker_time      CONSTANT VARCHAR2(0010 CHAR) := '@04';
    k_err_printer      CONSTANT VARCHAR2(0100 CHAR) := 'WL_PRINTER_ERROR';
    k_err_wrong_number CONSTANT VARCHAR2(0100 CHAR) := 'WL_WRONG_NUMBER';

    k_yes CONSTANT VARCHAR2(0001 CHAR) := 'Y';

    PROCEDURE get_next_ticket
    (
        i_id_wl_queue IN NUMBER,
        o_char        OUT VARCHAR2,
        o_number      OUT NUMBER
    );

    /********************************************************************************************
    * 
    * Get configuration about available queues to department and which ones the user is allocated in context of I_ID_MACHINE;
    * Also, returns the last queues that the professional allocated himself to.
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_ID_DEPARTMENT The department id
    * @param   I_ID_WL_MACHINE The machine beeing operated
    * @param   O_QUEUES The cursor with queues info
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ricardo Nuno Almeida
    * @version 1.0
    * @since   27-11-2008
     **************************************************************************************************/
    FUNCTION get_queues
    (
        i_lang          IN language.id_language%TYPE,
        i_id_prof       IN profissional,
        i_id_department IN department.id_department%TYPE,
        i_id_wl_machine IN wl_machine.id_wl_machine%TYPE,
        o_queues        OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_queues      table_number := table_number();
        l_prof        profissional;
        l_queue_types table_varchar;
    
    BEGIN
    
        IF i_id_prof IS NOT NULL
        THEN
            g_error := 'GET CURSOR c_last_queues ';
            --Distinct, para evitar casos em que o utilizador tenha estado autenticado em mais do que uma máquina. 
            SELECT DISTINCT wmpq.id_wl_queue
              BULK COLLECT
              INTO l_queues
              FROM wl_mach_prof_queue wmpq
             WHERE wmpq.id_professional = i_id_prof.id
               AND wmpq.id_wl_machine = i_id_wl_machine;
        
            -- Create         
            g_error := 'SET QUEUES';
            IF l_queues.count > 0
            THEN
            
                g_ret := pk_wlsession.set_queues(i_lang      => i_lang,
                                                 i_prof      => i_id_prof,
                                                 i_id_mach   => i_id_wl_machine,
                                                 i_id_queues => l_queues,
                                                 o_error     => o_error);
            END IF;
        
            l_prof        := i_id_prof;
            l_queue_types := table_varchar('A');
        ELSE
            l_prof        := profissional(0, 0, 0);
            l_queue_types := table_varchar('A', 'C');
        END IF;
    
        g_error := 'OPEN o_queues CURSOR';
        OPEN o_queues FOR
            SELECT q.id_wl_queue,
                   pk_translation.get_translation(i_lang, q.code_name_queue) inter_name_queue,
                   q.char_queue,
                   q.num_queue,
                   q.flg_visible,
                   q.flg_type_queue,
                   q.flg_priority,
                   q.adw_last_update,
                   pk_wlcore.get_queue_color(i_lang, l_prof, color) color,
                   pk_translation.get_translation(i_lang, q.code_msg) code_msg,
                   pk_wlpatient.get_people_ahead(q.id_wl_queue, l_prof) total_ahead,
                   decode(mpq.id_wl_queue, NULL, pk_alert_constant.g_no, pk_alert_constant.g_yes) flg_allocated
              FROM wl_queue q
             INNER JOIN wl_machine wlm
                ON wlm.id_wl_queue_group = q.id_wl_queue_group
              LEFT JOIN wl_mach_prof_queue mpq
                ON mpq.id_wl_queue = q.id_wl_queue
               AND mpq.id_professional = l_prof.id
               AND mpq.id_wl_machine = i_id_wl_machine
             WHERE id_department = i_id_department
               AND q.flg_visible = pk_alert_constant.g_yes
               AND q.flg_type_queue IN (SELECT *
                                          FROM TABLE(l_queue_types))
               AND wlm.id_wl_machine = i_id_wl_machine
             ORDER BY code_msg;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_QUEUES',
                                              o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_queues);
            RETURN FALSE;
    END get_queues;

    FUNCTION get_id_patient(i_id_episode IN NUMBER) RETURN NUMBER IS
    
        tbl_id   table_number;
        l_return NUMBER;
    
    BEGIN
    
        SELECT v.id_patient
          BULK COLLECT
          INTO tbl_id
          FROM episode e
          JOIN visit v
            ON e.id_visit = v.id_visit
         WHERE e.id_episode = i_id_episode;
    
        IF tbl_id.count > 0
        THEN
        
            l_return := tbl_id(1);
        
        END IF;
    
        RETURN l_return;
    
    END get_id_patient;

    FUNCTION get_id_machine_by_name(i_machine_name IN VARCHAR2) RETURN NUMBER IS
    
        tbl_id   table_number;
        l_return NUMBER;
    
    BEGIN
    
        SELECT a.id_wl_machine
          BULK COLLECT
          INTO tbl_id
          FROM wl_machine a
         WHERE a.machine_name = upper(i_machine_name);
    
        IF tbl_id.count > 0
        THEN
            l_return := tbl_id(1);
        END IF;
    
        RETURN l_return;
    
    END get_id_machine_by_name;

    FUNCTION get_id_queue_by_id_machine(i_id_machine IN NUMBER) RETURN NUMBER IS
    
        tbl_id   table_number;
        l_return NUMBER;
    
    BEGIN
    
        SELECT wmq.id_wl_id_queue
          BULK COLLECT
          INTO tbl_id
          FROM wl_msg_queue wmq
         WHERE wmq.id_wl_mach_dest = i_id_machine
           AND rownum = 1;
    
        IF tbl_id.count > 0
        THEN
            l_return := tbl_id(1);
        END IF;
    
        RETURN l_return;
    
    END get_id_queue_by_id_machine;

    FUNCTION get_wl_by_episode(i_episode IN NUMBER) RETURN wl_waiting_line%ROWTYPE IS
    
        xrow wl_waiting_line%ROWTYPE;
    
    BEGIN
    
        SELECT *
          INTO xrow
          FROM (SELECT *
                  FROM wl_waiting_line x
                 WHERE x.id_episode = i_episode
                 ORDER BY x.dt_begin_tstz DESC)
         WHERE rownum = 1;
    
        RETURN xrow;
    
    EXCEPTION
        WHEN no_data_found THEN
            xrow := NULL;
            RETURN xrow;
    END get_wl_by_episode;

    FUNCTION report_ticket
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_wl_machine_name IN wl_machine.machine_name%TYPE,
        i_id_episode      IN NUMBER
    ) RETURN VARCHAR2 IS
    
        l_bool              BOOLEAN;
        l_ticket_number     VARCHAR2(4000);
        l_ticket_print      VARCHAR2(4000);
        l_codification_type VARCHAR2(4000);
        l_printer           VARCHAR2(4000);
        l_error             t_error_out;
        xrow                wl_waiting_line%ROWTYPE;
    
    BEGIN
    
        xrow := get_wl_by_episode(i_id_episode);
    
        l_bool := generate_ticket(i_lang              => i_lang,
                                  i_prof              => i_prof,
                                  i_wl_machine_name   => i_wl_machine_name,
                                  i_id_episode        => i_id_episode,
                                  i_char_queue        => xrow.char_queue,
                                  i_number_queue      => xrow.number_queue,
                                  o_ticket_number     => l_ticket_number,
                                  o_ticket_print      => l_ticket_print,
                                  o_codification_type => l_codification_type,
                                  o_printer           => l_printer,
                                  o_error             => l_error);
    
        RETURN l_ticket_print;
    
    END report_ticket;

    /********************************************************************************************
     * 
     *  Returns the info to be printed in the ticket
     *
     * @param i_lang                   Language ID
     * @param i_id_wl_queue            ID of the Queue that the ticket 
     * @param i_id_mach                ID of the machine (kiosk)
     * @param i_prof                   ID of the professional (presumively UTENTE)
     * @param o_ticket_number          Ticket number (in the corresponding queue)
     * @param o_msg_dept               Description of the machine
     * @param o_frase                  Configured Message
     * @param o_msg_inst               Configured Message
     * @param o_error
     *
     * @return                         true or false 
     *
     * @author                          Ricardo Nuno Almeida
     * @version                         0.1
     * @since                           2009/02/05
    **********************************************************************************************/
    FUNCTION get_wl_waiting_line
    (
        i_char_num      IN VARCHAR2,
        i_ticket_number IN NUMBER
    ) RETURN NUMBER IS
    
        tbl_id   table_number;
        l_return NUMBER;
    
    BEGIN
    
        SELECT id_wl_waiting_line
          BULK COLLECT
          INTO tbl_id
          FROM wl_waiting_line x
         WHERE x.char_queue = i_char_num
           AND x.number_queue = i_ticket_number
         ORDER BY x.dt_begin_tstz DESC;
    
        IF tbl_id.count > 0
        THEN
            l_return := tbl_id(1);
        END IF;
    
        RETURN l_return;
    
    END get_wl_waiting_line;

    FUNCTION get_ticket
    (
        i_lang          IN language.id_language%TYPE,
        i_id_wl_queue   IN wl_queue.id_wl_queue%TYPE,
        i_id_mach       IN wl_machine.id_wl_machine%TYPE,
        i_id_episode    IN NUMBER,
        i_char_queue    IN VARCHAR2,
        i_number_queue  IN NUMBER,
        i_prof          IN profissional,
        o_ticket_number OUT VARCHAR2,
        o_msg_dept      OUT VARCHAR2,
        o_frase         OUT VARCHAR2,
        o_msg_inst      OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        next_number         wl_queue.num_queue%TYPE;
        char_queue          wl_queue.char_queue%TYPE;
        l_code_message_dept department.code_department%TYPE;
        l_id_inst           department.id_institution%TYPE;
        l_code_message_inst institution.code_institution%TYPE;
        l_rows              table_varchar;
    
        l_cfg_ticket_system sys_config.value%TYPE;
    
        tbl_waiting_line table_number;
        xwtl             wl_waiting_line%ROWTYPE;
        l_id_parent      NUMBER;
    
        FUNCTION get_waiting_line_rec(i_id_episode IN NUMBER) RETURN table_number IS
            tbl_id table_number;
        BEGIN
        
            SELECT id_wl_waiting_line
              BULK COLLECT
              INTO tbl_id
              FROM wl_waiting_line
             WHERE id_episode = i_id_episode
             ORDER BY dt_begin_tstz DESC;
        
            RETURN tbl_id;
        
        END get_waiting_line_rec;
    
    BEGIN
    
        g_error := 'GET CONFIG INFO';
        pk_alertlog.log_debug(g_error, g_package_name);
        o_frase             := pk_message.get_message(i_lang, 'WL_TICKET_MESSAGE_M001');
        l_cfg_ticket_system := pk_sysconfig.get_config(i_code_cf => 'ADT_ADMISSION_WL_TICKET_NUMBER', i_prof => i_prof);
    
        g_error := 'GET MACHINE, INSTITUTION AND DEPARTMENT INFO';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        IF pk_sysconfig.get_config(pk_wlcore.g_wl_demo_flg, i_prof.institution, i_prof.software) =
           pk_alert_constant.get_yes
        THEN
            SELECT d.code_department,
                   d.id_institution,
                   pk_translation.get_translation(i_lang, wm.cod_desc_machine_visual),
                   i.code_institution,
                   i.abbreviation
              INTO l_code_message_dept, l_id_inst, o_msg_dept, l_code_message_inst, o_msg_inst
              FROM wl_machine wm
             INNER JOIN department d
                ON d.id_department = pk_wlcore.g_demo_department_0
             INNER JOIN institution i
                ON d.id_institution = i.id_institution
             WHERE wm.id_wl_machine = i_id_mach;
        
        ELSE
            IF l_cfg_ticket_system = pk_alert_constant.g_no
            THEN
                SELECT d.code_department,
                       d.id_institution,
                       pk_translation.get_translation(i_lang, wm.cod_desc_machine_visual),
                       i.code_institution,
                       i.abbreviation
                  INTO l_code_message_dept, l_id_inst, o_msg_dept, l_code_message_inst, o_msg_inst
                  FROM wl_machine wm
                 INNER JOIN room r
                    ON wm.id_room = r.id_room
                 INNER JOIN department d
                    ON r.id_department = d.id_department
                 INNER JOIN institution i
                    ON d.id_institution = i.id_institution
                 WHERE wm.id_wl_machine = i_id_mach;
            END IF;
        END IF;
    
        tbl_waiting_line := get_waiting_line_rec(i_id_episode => i_id_episode);
    
        IF tbl_waiting_line.count = 0
        THEN
            get_next_ticket(i_id_wl_queue, o_ticket_number, next_number);
        
            g_error := 'INSERT RECORD TO BE CALLED';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            l_id_parent := get_wl_waiting_line(i_char_queue, i_number_queue);
        
            ts_wl_waiting_line.ins(id_wl_waiting_line_in        => ts_wl_waiting_line.next_key,
                                   char_queue_in                => o_ticket_number,
                                   number_queue_in              => next_number,
                                   id_wl_queue_in               => i_id_wl_queue,
                                   id_episode_in                => i_id_episode,
                                   id_wl_waiting_line_parent_in => l_id_parent,
                                   flg_wl_status_in             => pk_alert_constant.g_wr_wl_status_e,
                                   dt_begin_tstz_in             => current_timestamp,
                                   rows_out                     => l_rows);
            o_ticket_number := o_ticket_number || next_number;
        
            g_error := 'PROCESS INSERT WITH WL_WAITING_LINE ' || o_ticket_number;
            pk_alertlog.log_debug(g_error, g_package_name);
            t_data_gov_mnt.process_insert(i_lang, i_prof, 'WL_WAITING_LINE', l_rows, o_error);
        
        ELSE
        
            SELECT *
              INTO xwtl
              FROM wl_waiting_line x
             WHERE x.id_wl_waiting_line = tbl_waiting_line(1);
        
            o_ticket_number := xwtl.char_queue || xwtl.number_queue;
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
                                              'GET_TICKET',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_ticket;

    /********************************************************************************************
     *  Function for use with the kiosk, it returns the stats regarding the provided queue (number of people ahead and the average waiting time). 
     *
     * @param i_lang                Language in which to return the results
     * @param i_id_wl_queue         ID of the queue to check stats from
     * @param i_prof        
     * @param o_total_people_ahead       number of people ahead
     * @param o_tempo_medio_espera       average waiting time.
     * @param o_error 
     *
     * @return                         true or false 
     *
     * @author                          ?
     * @version                         0.1
     * @since                           ?
    **********************************************************************************************/
    FUNCTION get_queue_stat
    (
        i_lang               IN language.id_language%TYPE,
        i_id_wl_queue        IN wl_queue.id_wl_queue%TYPE,
        i_prof               IN profissional,
        o_total_people_ahead OUT NUMBER,
        o_tempo_medio_espera OUT NUMBER,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_sample        PLS_INTEGER;
        l_total_amostra PLS_INTEGER;
        l_date_format   VARCHAR2(2) := 'DD';
    
    BEGIN
    
        g_error := 'INICIALIZE VARIABLES';
        pk_alertlog.log_debug(g_error, g_package_name);
        l_total_amostra := 0;
        l_sample        := pk_sysconfig.get_config('WL_STAT_SAMPLE_SIZE', i_prof);
    
        g_error := 'GET INFO FROM CHOSEN QUEUE';
        pk_alertlog.log_debug(g_error, g_package_name);
        o_total_people_ahead := pk_wlpatient.get_people_ahead(i_id_wl_queue, i_prof);
        o_tempo_medio_espera := 0;
    
        g_error := 'GET TIME BETWEEN GETTING TICKET AND BEING CALLED BY ADMINISTRATIVE';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        BEGIN
            SELECT AVG(d)
              INTO o_tempo_medio_espera
              FROM (SELECT (pk_date_utils.get_elapsed_minutes_abs_tsz(data.dt_begin_tstz) -
                           pk_date_utils.get_elapsed_minutes_abs_tsz(data.dt_call_tstz)) d
                      FROM (SELECT wh.dt_begin_tstz, wh.dt_call_tstz
                              FROM (SELECT wwl2.*
                                      FROM (SELECT wwl.*
                                              FROM wl_waiting_line wwl
                                             WHERE wwl.id_wl_queue = i_id_wl_queue
                                             ORDER BY wwl.dt_begin_tstz DESC) wwl2
                                     WHERE rownum <= l_sample) wh
                             WHERE dt_call_tstz IS NOT NULL
                               AND pk_date_utils.trunc_insttimezone(i_prof, wh.dt_begin_tstz, l_date_format) =
                                   pk_date_utils.trunc_insttimezone(i_prof, current_timestamp, l_date_format)
                             ORDER BY wh.dt_call_tstz DESC) data);
        
            l_total_amostra := l_sample;
        EXCEPTION
            WHEN no_data_found THEN
                l_total_amostra := 0;
        END;
    
        g_error := 'IF NO ONE HAS BEEN CALLED, THEN GET TIME BETWEEN NOW AND GETTING TICKET';
        pk_alertlog.log_debug(g_error, g_package_name);
        IF l_total_amostra = 0
           OR o_tempo_medio_espera IS NULL
        THEN
            BEGIN
                SELECT AVG(d)
                  INTO o_tempo_medio_espera
                  FROM (SELECT (pk_date_utils.get_elapsed_minutes_abs_tsz(dt_begin_tstz) -
                               pk_date_utils.get_elapsed_minutes_abs_tsz(dt_call_tstz)) d
                          FROM (SELECT wh.dt_begin_tstz, current_timestamp dt_call_tstz
                                  FROM (SELECT wwl2.*
                                          FROM (SELECT wwl.*
                                                  FROM wl_waiting_line wwl
                                                 WHERE wwl.id_wl_queue = i_id_wl_queue
                                                 ORDER BY wwl.dt_begin_tstz DESC) wwl2
                                         WHERE rownum <= l_sample) wh
                                 WHERE pk_date_utils.trunc_insttimezone(i_prof, wh.dt_begin_tstz, l_date_format) =
                                       pk_date_utils.trunc_insttimezone(i_prof, current_timestamp, l_date_format)
                                 ORDER BY wh.dt_call_tstz DESC));
            EXCEPTION
                WHEN no_data_found THEN
                    o_tempo_medio_espera := 0;
            END;
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
                                              'GET_QUEUE_STAT',
                                              o_error);
        
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_queue_stat;

    /********************************************************************************************
     *  Function for use in the kiosk, it returns an informative text regarding the provided queue with the number of people ahead and the average waiting time. 
     *
     * @param i_lang                Language in which to return the results
     * @param i_id_wl_queue         ID of the queue to check stats from 
     * @param i_prof                
     * @param o_message 
     * @param o_error 
     *
     * @return                         true or false 
     *
     * @author                          ?
     * @version                         2.5.0.7
     * @since                           ?
    **********************************************************************************************/
    FUNCTION get_message_with_stat
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_wl_queue   IN wl_queue.id_wl_queue%TYPE,
        i_id_department IN department.id_department%TYPE,
        o_message       OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_msg                  sys_message.desc_message%TYPE;
        l_prof                 profissional := profissional(0, 0, 0);
        l_people_ahead         PLS_INTEGER;
        l_tempo_espera         PLS_INTEGER;
        l_tempo_espera_total   PLS_INTEGER;
        l_tempo_espera_total_v VARCHAR2(0200);
        xhours                 VARCHAR2(0050);
    
    BEGIN
    
        g_error := 'SET VARIABLES';
        IF i_prof.institution = 0
        THEN
            g_error := 'FREE ACCESS - GET INSTITUTION';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            SELECT d.id_institution
              INTO l_prof.institution
              FROM department d
             WHERE d.id_department = i_id_department;
        ELSE
            l_prof := i_prof;
        END IF;
    
        -- GET STATISTICS
        g_error := 'CALL GET_QUEUE_STAT';
        pk_alertlog.log_debug(g_error, g_package_name);
        IF NOT pk_wlpatient.get_queue_stat(i_lang               => i_lang,
                                           i_id_wl_queue        => i_id_wl_queue,
                                           i_prof               => l_prof,
                                           o_total_people_ahead => l_people_ahead,
                                           o_tempo_medio_espera => l_tempo_espera,
                                           o_error              => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- GET TEXTS
        g_error := 'GET MESSAGE 1';
        xhours  := pk_message.get_message(i_lang, pk_msg_hours_kiosk);
        g_error := 'GET MESSAGE 2';
        l_msg   := pk_message.get_message(i_lang, 'INFO_GET_TICKET');
    
        g_error := 'GET MESSAGE 3';
        -- REPLACE SPECIAL SPOTS WITH MEANINGFUL INFO
        l_msg := REPLACE(l_msg, '#01', to_char(l_people_ahead));
    
        IF l_people_ahead = 0
        THEN
            l_msg := REPLACE(l_msg, '#02', 0);
        ELSE
            l_tempo_espera_total := l_tempo_espera * l_people_ahead;
        
            IF l_tempo_espera_total > pk_tempo_espera_lim
            THEN
                l_tempo_espera_total_v := to_char(trunc(l_tempo_espera_total / 60)) || xsp || xhours;
                l_tempo_espera_total_v := l_tempo_espera_total_v || xsp || to_char(MOD(l_tempo_espera_total, 60), '00');
            ELSE
                l_tempo_espera_total_v := l_tempo_espera_total;
            END IF;
        
            l_msg := REPLACE(l_msg, '#02', l_tempo_espera_total_v);
            IF l_tempo_espera_total = 1
            THEN
                l_msg := REPLACE((l_msg),
                                 pk_translation.get_translation(i_lang, 'TIME_UNIT.CODE_TIME_UNIT.3'),
                                 pk_translation.get_translation(i_lang, 'TIME_UNIT.CODE_TIME_UNIT.1'));
            END IF;
        
        END IF;
    
        o_message := l_msg;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_MESSAGE_WITH_STAT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_message_with_stat;

    /*********************************************************************************************************
    * 
    * Returns NUMBER OF PEOPLE NOT ATTENDED BY ADMINISTRATIVE IN A PARTICULAR QUEUE
    *
    * @param   I_ID_WL_QUEUE  ID of the ticket
    * @param   I_ID_PROF      Information of the professional calling this function. 
    *
    * @RETURN  NUMBER the number of people ahead of provided ticket.
    * @author  ?
    * @version 1.0
    * @since   ?
    **********************************************************************************************************/
    FUNCTION get_people_ahead
    (
        i_id_wl_queue IN wl_queue.id_wl_queue%TYPE,
        i_prof        IN profissional
    ) RETURN NUMBER IS
    
        l_total_people_ahead PLS_INTEGER;
    
    BEGIN
    
        SELECT COUNT(*) total
          INTO l_total_people_ahead
          FROM (SELECT *
                  FROM wl_waiting_line wwl
                 WHERE wwl.dt_begin_tstz >= (current_timestamp - 1))
         WHERE id_wl_queue = i_id_wl_queue
           AND flg_wl_status = pk_alert_constant.g_wr_wl_status_e
           AND pk_date_utils.trunc_insttimezone(i_prof, dt_begin_tstz) =
               pk_date_utils.trunc_insttimezone(i_prof, current_timestamp);
    
        RETURN l_total_people_ahead;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN - 1;
    END get_people_ahead;

    /*********************************************************************************************************
    *  
    * Returns the path for a patient's photo, but accesses a more restricted repository
    *
    * @param   I_ID_PAT The patient id
    *
    * @RETURN  STRING WITH PATH FOR PHOTOGRAPH if sucess, NULL otherwise
    * @author  Ricardo Nuno Almeida
    * @version 1.0
    * @since   03-03-2009
    **********************************************************************************************************/
    FUNCTION get_pat_pub_foto
    (
        i_id_pat  IN patient.id_patient%TYPE,
        i_id_prof IN profissional
    ) RETURN VARCHAR2 IS
    
        l_id_pat             NUMBER := 0;
        l_path               VARCHAR2(1000);
        l_path_parte         VARCHAR2(1000);
        l_sql                VARCHAR2(200);
        l_is_in_waiting_line VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
        vpatalias            patient.alias%TYPE;
    
    BEGIN
    
        SELECT alias
          INTO vpatalias
          FROM patient
         WHERE id_patient = i_id_pat;
    
        IF pk_patphoto.check_blob(i_id_pat) = 'N' -- no photo
           OR (vpatalias IS NOT NULL) -- must be hidden
        THEN
            RETURN NULL;
        ELSE
            SELECT pk_alert_constant.get_yes
              INTO l_is_in_waiting_line
              FROM wl_waiting_line wl
             WHERE wl.id_patient = i_id_pat
               AND rownum = 1;
        
            IF l_is_in_waiting_line = pk_alert_constant.g_yes
            THEN
                l_sql := ' SELECT count(id_patient)
                      FROM pat_photo
                    WHERE id_patient = :1';
                EXECUTE IMMEDIATE l_sql
                    INTO l_id_pat
                    USING i_id_pat;
            
                -- GET PATH OF PHOTO
                l_path := NULL;
                IF l_id_pat > 0
                THEN
                    g_ret  := pk_sysconfig.get_config(i_code_cf => pk_wl_url_photo_pub_read,
                                                      i_prof    => i_id_prof,
                                                      o_msg_cf  => l_path_parte);
                    l_path := l_path_parte || i_id_pat;
                END IF;
            ELSE
                l_path := NULL;
            END IF;
        END IF;
    
        RETURN l_path;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_pat_pub_foto;

    /***********************************************************************************************************************
    * 
    * GET PHOTO FOR AN PATIENT
    *
    * @param   I_ID_PAT The patient id
    * @param   O_IMG    the blob containing the image
    *
    * @RETURN  TRUE if sucess, NULL otherwise
    * @author  Luís Maia
    * @version 1.0
    * @since   25-02-2009
    ***********************************************************************************************************************/
    FUNCTION get_blob
    (
        i_pat   IN pat_photo.id_patient%TYPE,
        o_img   OUT BLOB,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_lang NUMBER := 1; --TODO: For now error language is returned in portuguese
    
    BEGIN
    
        g_error := 'GET PHOTO';
        SELECT d.img_photo
          INTO o_img
          FROM (SELECT pp.img_photo
                  FROM pat_photo pp
                 INNER JOIN wl_waiting_line wwl
                    ON wwl.id_patient = pp.id_patient
                 WHERE pp.id_patient = i_pat
                 ORDER BY pp.dt_photo_tstz DESC) d
         WHERE rownum = 1;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(l_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BLOB',
                                              o_error);
            RETURN FALSE;
    END get_blob;

    FUNCTION get_popup_queues
    (
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_mach_name IN VARCHAR2,
        o_result    OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        k_queue_type_adm CONSTANT VARCHAR2(0010 CHAR) := 'A';
    
    BEGIN
    
        OPEN o_result FOR
            SELECT q.id_wl_queue,
                   q.char_queue,
                   q.num_queue,
                   q.flg_visible,
                   q.flg_type_queue,
                   q.flg_priority,
                   pk_wlcore.get_queue_color(i_lang, i_prof, q.color) color,
                   pk_translation.get_translation(i_lang, q.code_msg) code_msg
              FROM wl_queue q
              JOIN wl_machine m
                ON m.id_wl_queue_group = q.id_wl_queue_group
             WHERE m.machine_name = i_mach_name
               AND q.flg_type_queue = k_queue_type_adm
               AND q.flg_visible = k_yes
             ORDER BY q.char_queue;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_POPUP_QUEUES',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_result);
            RETURN FALSE;
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
    
        l_rows table_varchar := table_varchar();
    
    BEGIN
    
        get_next_ticket(i_id_wl_queue, o_char, o_number);
    
        ts_wl_waiting_line.ins(id_wl_waiting_line_in        => ts_wl_waiting_line.next_key,
                               char_queue_in                => o_char,
                               number_queue_in              => o_number,
                               id_wl_queue_in               => i_id_wl_queue,
                               id_episode_in                => NULL,
                               id_wl_waiting_line_parent_in => NULL,
                               flg_wl_status_in             => pk_alert_constant.g_wr_wl_status_x,
                               dt_begin_tstz_in             => current_timestamp,
                               rows_out                     => l_rows);
    
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
                                              'GET_NEXT_TICKET',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes();
            RETURN FALSE;
    END get_next_ticket;

    PROCEDURE get_next_ticket
    (
        i_id_wl_queue IN NUMBER,
        o_char        OUT VARCHAR2,
        o_number      OUT NUMBER
    ) IS
    
    BEGIN
    
        g_error := 'UPDATE RECORD WITH NEW NUMBER';
        pk_alertlog.log_debug(g_error, g_package_name);
        UPDATE wl_queue
           SET num_queue =
               (num_queue + 1)
         WHERE id_wl_queue = i_id_wl_queue
        RETURNING(num_queue + 1), char_queue INTO o_number, o_char;
    
    END get_next_ticket;

    FUNCTION generate_ticket_bck
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
    
        l_bool     BOOLEAN;
        l_proc_num VARCHAR2(0200 CHAR);
    
        l_id_machine wl_machine.id_wl_machine%TYPE;
    
        l_id_queue   wl_queue.id_wl_queue%TYPE;
        l_id_patient NUMBER;
    
        l_dummy VARCHAR2(300 CHAR);
        l_code  VARCHAR2(1000 CHAR);
    
        l_date      VARCHAR2(100 CHAR);
        l_time      VARCHAR2(100 CHAR);
        l_exception EXCEPTION;
    
        PROCEDURE get_ticket_info IS
        
        BEGIN
        
            g_error := 'GET PRINTER';
            SELECT t.cfg_type, t.cfg_printer, t.cfg_value
              INTO o_codification_type, o_printer, l_code
              FROM TABLE(pk_barcode.get_barcode_cfg_base(i_lang, i_prof, 'BARCODE_WL_TICKET_NUMBER')) t;
        
        END get_ticket_info;
    
        FUNCTION get_tbl_episode RETURN NUMBER IS
        
            tbl_id_episode table_number;
            l_return       NUMBER;
        
        BEGIN
        
            SELECT id_episode
              BULK COLLECT
              INTO tbl_id_episode
              FROM wl_waiting_line
             WHERE char_queue = i_char_queue
               AND number_queue = i_number_queue
             ORDER BY dt_begin_tstz DESC;
        
            IF tbl_id_episode.count > 0
            THEN
            
                IF tbl_id_episode(1) IS NOT NULL
                THEN
                    l_return := tbl_id_episode(1);
                ELSE
                    RAISE l_exception;
                END IF;
            ELSE
                RAISE l_exception;
            END IF;
        
            RETURN l_return;
        
        END get_tbl_episode;
    
        PROCEDURE update_adt
        (
            i_id_episode    IN NUMBER,
            i_ticket_number IN VARCHAR2
        ) IS
        
            tbl_id table_number;
        
        BEGIN
        
            SELECT id_admission_adt
              BULK COLLECT
              INTO tbl_id
              FROM admission_adt aa
              JOIN episode_adt ea
                ON aa.id_episode_adt = ea.id_episode_adt
             WHERE ea.id_episode = i_id_episode;
        
            IF tbl_id.count > 0
            THEN
                IF i_ticket_number IS NOT NULL
                THEN
                    UPDATE admission_adt
                       SET ticket_number = i_ticket_number
                     WHERE id_admission_adt = tbl_id(1);
                END IF;
            END IF;
        
        END update_adt;
    
    BEGIN
    
        IF i_id_episode IS NOT NULL
        THEN
            l_id_patient := get_id_patient(i_id_episode => i_id_episode);
        
            l_bool := pk_patient.get_clin_rec(i_lang       => i_lang,
                                              i_pat        => l_id_patient,
                                              i_instit     => i_prof.institution,
                                              i_pat_family => NULL,
                                              o_num        => l_proc_num,
                                              o_error      => o_error);
        
            IF NOT l_bool
            THEN
                l_proc_num := '';
            END IF;
        END IF;
    
        get_ticket_info();
    
        l_id_machine := get_id_machine_by_name(i_machine_name => i_wl_machine_name);
    
        l_id_queue := get_id_queue_by_id_machine(i_id_machine => l_id_machine);
    
        l_date := pk_date_utils.dt_chr_tsz(i_lang, current_timestamp, i_prof.institution, i_prof.software);
        l_time := pk_date_utils.dt_chr_hour_tsz(i_lang,
                                                current_timestamp,
                                                profissional(i_prof.id, i_prof.institution, i_prof.software));
    
        IF NOT pk_wlpatient.get_ticket(i_lang          => i_lang,
                                       i_id_wl_queue   => l_id_queue,
                                       i_id_mach       => l_id_machine,
                                       i_id_episode    => i_id_episode,
                                       i_char_queue    => i_char_queue,
                                       i_number_queue  => i_number_queue,
                                       i_prof          => i_prof,
                                       o_ticket_number => o_ticket_number,
                                       o_msg_dept      => l_dummy,
                                       o_frase         => l_dummy,
                                       o_msg_inst      => l_dummy,
                                       o_error         => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        get_ticket_info();
    
        update_adt(i_id_episode, o_ticket_number);
    
        l_code         := REPLACE(l_code, k_marker_ticket_nr, o_ticket_number);
        l_code         := REPLACE(l_code, k_marker_num_proc, l_proc_num);
        l_code         := REPLACE(l_code, k_marker_date, l_date);
        l_code         := REPLACE(l_code, k_marker_time, l_time);
        o_ticket_print := l_code;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            l_bool              := pk_alert_exceptions.process_error(i_lang        => i_lang,
                                                                     i_sqlcode     => '',
                                                                     i_sqlerrm     => NULL,
                                                                     i_message     => NULL,
                                                                     i_owner       => g_package_owner,
                                                                     i_package     => g_package_name,
                                                                     i_function    => 'GENERATE_TICKET',
                                                                     i_action_type => 'D',
                                                                     i_action_msg  => NULL,
                                                                     i_msg_title   => NULL,
                                                                     i_msg_type    => NULL,
                                                                     o_error       => o_error);
            o_error.ora_sqlerrm := pk_message.get_message(i_lang, k_err_printer);
            o_error.err_action  := NULL;
            pk_alert_exceptions.reset_error_state();
            pk_utils.undo_changes;
            RETURN FALSE;
    END generate_ticket_bck;

    PROCEDURE update_adt
    (
        i_id_episode    IN NUMBER,
        i_ticket_number IN VARCHAR2
    ) IS
    
        tbl_id table_number;
    
    BEGIN
    
        SELECT id_admission_adt
          BULK COLLECT
          INTO tbl_id
          FROM admission_adt aa
          JOIN episode_adt ea
            ON aa.id_episode_adt = ea.id_episode_adt
         WHERE ea.id_episode = i_id_episode;
    
        IF tbl_id.count > 0
        THEN
            IF i_ticket_number IS NOT NULL
            THEN
                UPDATE admission_adt
                   SET ticket_number = i_ticket_number
                 WHERE id_admission_adt = tbl_id(1);
            END IF;
        END IF;
    
    END update_adt;

    PROCEDURE get_ticket_info
    (
        i_lang              IN NUMBER,
        i_prof              IN profissional,
        o_codification_type OUT VARCHAR2,
        o_printer           OUT VARCHAR2,
        o_code              OUT VARCHAR2
    ) IS
    
        l_codification_type VARCHAR2(4000);
        l_printer           VARCHAR2(4000);
        l_code              VARCHAR2(4000);
    
        t_data t_tbl_barcode_type_cfg := t_tbl_barcode_type_cfg();
        k_code CONSTANT VARCHAR2(0200 CHAR) := 'BARCODE_WL_TICKET_NUMBER';
    
    BEGIN
    
        t_data := pk_barcode.get_barcode_cfg_base(i_lang, i_prof, k_code);
    
        IF t_data.count > 0
        THEN
            l_codification_type := t_data(1).cfg_type;
            l_printer           := t_data(1).cfg_printer;
            l_code              := t_data(1).cfg_value;
        END IF;
    
        o_codification_type := l_codification_type;
        o_printer           := l_printer;
        o_code              := l_code;
    
    END get_ticket_info;

    FUNCTION get_med_queue
    (
        i_prof      IN profissional,
        i_mach_name IN VARCHAR2
    ) RETURN NUMBER IS
    
        tbl_id   table_number;
        l_return NUMBER;
    
    BEGIN
    
        SELECT q.id_wl_queue
          BULK COLLECT
          INTO tbl_id
          FROM wl_queue q
          JOIN wl_machine m
            ON m.id_wl_queue_group = q.id_wl_queue_group
         WHERE m.machine_name = i_mach_name
           AND q.flg_type_queue = pk_alert_constant.g_wr_wq_type_d;
    
        IF tbl_id.count > 0
        THEN
            l_return := tbl_id(1);
        ELSE
            -- fallback sql: id fisrst is not successfull because of bad config
            -- do this one
            SELECT wq.id_wl_queue
              BULK COLLECT
              INTO tbl_id
              FROM software_dept sd
              JOIN dept d
                ON d.id_dept = sd.id_dept
              JOIN department dp
                ON dp.id_dept = d.id_dept
              JOIN room r
                ON r.id_department = dp.id_department
              JOIN prof_room pr
                ON pr.id_room = r.id_room
              JOIN wl_queue wq
                ON wq.id_department = dp.id_department
             WHERE sd.id_software = i_prof.software
               AND pr.id_professional = i_prof.id
               AND dp.flg_available = k_yes
               AND r.flg_available = k_yes
               AND r.flg_wl = k_yes
               AND pr.flg_pref = k_yes
               AND dp.id_institution = i_prof.institution
               AND wq.flg_type_queue = pk_alert_constant.g_wr_wq_type_d;
        
            IF tbl_id.count > 0
            THEN
                l_return := tbl_id(1);
            END IF;
        
        END IF;
    
        IF l_return IS NULL
        THEN
            RAISE no_data_found;
        END IF;
    
        RETURN l_return;
    
    END get_med_queue;

    PROCEDURE get_info_med_machine
    (
        i_id_prof        IN NUMBER,
        i_id_institution IN NUMBER,
        i_mach_name      IN VARCHAR2,
        o_id_wl_machine  OUT NUMBER,
        o_machine_name   OUT VARCHAR2,
        o_id_room        OUT NUMBER,
        o_id_department  OUT NUMBER
    ) IS
    
        l_id_wl_machine NUMBER;
        l_machine_name  VARCHAR2(4000);
        l_id_room       NUMBER;
        l_id_department NUMBER;
    
    BEGIN
    
        SELECT w.id_wl_machine, w.machine_name, w.id_room, d.id_department
          INTO l_id_wl_machine, l_machine_name, l_id_room, l_id_department
          FROM wl_machine w
          JOIN prof_room pr
            ON pr.id_room = w.id_room
          JOIN wl_waiting_room wr
            ON wr.id_room_consult = pr.id_room
          JOIN room rs
            ON rs.id_room = wr.id_room_wait
          JOIN department d
            ON d.id_department = rs.id_department
         WHERE pr.id_professional = i_id_prof
           AND d.id_institution = i_id_institution
           AND w.machine_name = i_mach_name;
    
        o_id_wl_machine := l_id_wl_machine;
        o_machine_name  := l_machine_name;
        o_id_room       := l_id_room;
        o_id_department := l_id_department;
    
    END get_info_med_machine;

    PROCEDURE set_doc_date
    (
        i_prof      IN profissional,
        i_mach_name IN VARCHAR2,
        o_med_queue OUT NUMBER
    ) IS
    
        l_id_wl_machine NUMBER;
        l_machine_name  VARCHAR2(4000);
        l_id_room       NUMBER;
        l_id_department NUMBER;
        l_id_wl         NUMBER;
        l_rows          table_varchar := table_varchar();
    
    BEGIN
    
        o_med_queue := get_med_queue(i_prof, i_mach_name);
    
    END set_doc_date;

    FUNCTION get_wl_row_by_ticket
    (
        i_char_queue   IN VARCHAR2,
        i_number_queue IN NUMBER
    ) RETURN NUMBER IS
    
        tbl_wl   table_number;
        l_return NUMBER;
    
    BEGIN
    
        SELECT id_wl_waiting_line
          BULK COLLECT
          INTO tbl_wl
          FROM wl_waiting_line
         WHERE char_queue = i_char_queue
           AND number_queue = i_number_queue
         ORDER BY dt_begin_tstz DESC;
    
        IF tbl_wl.count > 0
        THEN
            l_return := tbl_wl(1);
        END IF;
    
        RETURN l_return;
    
    END get_wl_row_by_ticket;

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
    
        l_bool        BOOLEAN;
        xinfo         epis_info%ROWTYPE;
        xepis         episode%ROWTYPE;
        xvis          visit%ROWTYPE;
        l_id_wl       NUMBER;
        l_id_queue    NUMBER;
        l_flg_status  VARCHAR2(0050 CHAR);
        l_code        VARCHAR2(4000);
        l_char_number VARCHAR2(0050 CHAR);
        l_proc_num    VARCHAR2(0050 CHAR);
        l_next_number NUMBER;
        l_rows        table_varchar := table_varchar();
        l_date        VARCHAR2(100 CHAR);
        l_time        VARCHAR2(100 CHAR);
    
        err_unknown_ticket EXCEPTION;
    
        PROCEDURE get_episode_info IS
        
        BEGIN
        
            SELECT *
              INTO xinfo
              FROM epis_info
             WHERE id_episode = i_id_episode;
        
            SELECT *
              INTO xepis
              FROM episode
             WHERE id_episode = i_id_episode;
        
            SELECT *
              INTO xvis
              FROM visit
             WHERE id_visit = xepis.id_visit;
        
        END get_episode_info;
    
        FUNCTION process_error(i_err_text IN VARCHAR2) RETURN BOOLEAN IS
        
            l_bool BOOLEAN;
        
        BEGIN
        
            l_bool              := pk_alert_exceptions.process_error(i_lang        => i_lang,
                                                                     i_sqlcode     => '',
                                                                     i_sqlerrm     => NULL,
                                                                     i_message     => NULL,
                                                                     i_owner       => g_package_owner,
                                                                     i_package     => g_package_name,
                                                                     i_function    => 'GENERATE_TICKET',
                                                                     i_action_type => 'D',
                                                                     i_action_msg  => NULL,
                                                                     i_msg_title   => NULL,
                                                                     i_msg_type    => NULL,
                                                                     o_error       => o_error);
            o_error.ora_sqlerrm := pk_message.get_message(i_lang, i_err_text);
            o_error.err_action  := NULL;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        
        END process_error;
    
    BEGIN
    
        -- medical    
        IF i_number_queue IS NOT NULL
        THEN
            l_id_wl := get_wl_row_by_ticket(i_char_queue, i_number_queue);
        
            IF l_id_wl IS NULL
            THEN
                RAISE err_unknown_ticket;
            END IF;
        
            l_char_number := i_char_queue;
            l_next_number := i_number_queue;
        END IF;
    
        get_episode_info();
    
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
    
        set_doc_date(i_prof => i_prof, i_mach_name => i_wl_machine_name, o_med_queue => l_id_queue);
    
        IF l_id_wl IS NULL
        THEN
            get_next_ticket(l_id_queue, l_char_number, l_next_number);
        END IF;
    
        l_flg_status := pk_alert_constant.g_wr_wl_status_a;
    
        ts_wl_waiting_line.ins(id_wl_waiting_line_in        => ts_wl_waiting_line.next_key,
                               char_queue_in                => l_char_number,
                               number_queue_in              => l_next_number,
                               id_wl_queue_in               => l_id_queue,
                               id_episode_in                => i_id_episode,
                               id_patient_in                => xvis.id_patient,
                               id_wl_waiting_line_parent_in => l_id_wl,
                               flg_wl_status_in             => l_flg_status,
                               dt_begin_tstz_in             => current_timestamp,
                               rows_out                     => l_rows);
    
        -- o_codification_type, o_printer, l_code
        get_ticket_info(i_lang              => i_lang,
                        i_prof              => i_prof,
                        o_codification_type => o_codification_type,
                        o_printer           => o_printer,
                        o_code              => l_code);
    
        l_date := pk_date_utils.dt_chr_tsz(i_lang, current_timestamp, i_prof.institution, i_prof.software);
        l_time := pk_date_utils.dt_chr_hour_tsz(i_lang, current_timestamp, i_prof);
    
        l_char_number := l_char_number || l_next_number;
    
        update_adt(i_id_episode, l_char_number);
    
        l_code          := REPLACE(l_code, k_marker_ticket_nr, l_char_number);
        l_code          := REPLACE(l_code, k_marker_num_proc, l_proc_num);
        l_code          := REPLACE(l_code, k_marker_date, l_date);
        l_code          := REPLACE(l_code, k_marker_time, l_time);
        o_ticket_number := l_char_number;
        o_ticket_print  := l_code;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN err_unknown_ticket THEN
            RETURN process_error(k_err_wrong_number);
        WHEN OTHERS THEN
            RETURN process_error(k_err_printer);
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
        SELECT DISTINCT dp.id_dept
          BULK COLLECT
          INTO tbl_dept
          FROM prof_room pr
          JOIN room r
            ON r.id_room = pr.id_room
          JOIN department d
            ON d.id_department = r.id_department
          JOIN dept dp
            ON dp.id_dept = d.id_dept
          JOIN software_dept sd
            ON sd.id_dept = dp.id_dept
         WHERE d.id_institution = i_prof.institution
           AND sd.id_software = i_prof.software
           AND pr.id_professional = i_prof.id
           AND r.flg_wl = 'Y';
    
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
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DEPT_ROOM',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_result);
            RETURN FALSE;
        
    END get_dept_room;

BEGIN

    xpl := '''';
    xsp := chr(32);

    pk_wait_status      := 'E';
    pk_tempo_espera_lim := 120;

    -- TODO, LG: REMOVE FROM SYS_CONFIG WHEN ALL REFERENCES HAVE GONE!
    pk_wl_lang := 'WL_LANG';

    pk_msg_hours_kiosk       := 'MSG_HOURS_KIOSK';
    pk_wl_url_photo_read     := 'WL_URL_PHOTO_READ';
    pk_wl_url_photo_pub_read := 'WL_URL_PHOTO_PUB_READ';

    g_error_msg_code := 'COMMON_M001';

    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_wlpatient;
/
