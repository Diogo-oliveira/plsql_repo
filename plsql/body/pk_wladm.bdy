/*-- Last Change Revision: $Rev: 2027879 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:34 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_wladm AS

    /**
    * Call next patient waiting after having a ticket.
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_ID_PROF  professional, institution and software ids
    * @param   I_ID_MACH The machine name id.
    * @param   i_flg_prior_too Flag indicating if the prioritary queues are to be taken into account. 
    * @param   O_DATA_WAIT The info about next call
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Luís Gaspar
    * @version 1.0
    * @since   15-11-2006
    */
    FUNCTION get_next_call
    (
        i_lang          IN language.id_language%TYPE,
        i_id_prof       IN profissional,
        i_id_mach       IN wl_machine.id_wl_machine%TYPE,
        i_flg_prior_too IN NUMBER,
        o_data_wait     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_get_prior IS
            SELECT id_wl_queue
              FROM wl_queue
             WHERE flg_priority = pk_alert_constant.g_yes
                  -- LG 2006-11-15: consider only departments where machine is located
               AND id_department = (SELECT d. id_department
                                      FROM department d
                                      JOIN room r
                                        ON r.id_department = d.id_department
                                      JOIN wl_machine m
                                        ON m.id_room = r.id_room
                                     WHERE m.id_wl_machine = i_id_mach)
               AND flg_type_queue = pk_alert_constant.g_wr_wq_type_a;
    
        CURSOR c_get_my_queue IS
            SELECT id_wl_queue
              FROM wl_mach_prof_queue wmpq
             WHERE id_professional = i_id_prof.id
               AND id_wl_machine = i_id_mach;
    
        l_queues                table_number := table_number();
        l_wl_waiting_line_row   wl_waiting_line%ROWTYPE;
        l_its_mine              PLS_INTEGER;
        l_its_not_mine_but_aloc PLS_INTEGER;
        l_i                     NUMBER := 1;
        l_posso_atender_prior   PLS_INTEGER := 0;
        l_flg_prior_too         PLS_INTEGER;
    
    BEGIN
    
        g_error := 'CALC AVAILABLE PRIORITY QUEUES';
        IF i_flg_prior_too IS NULL
        THEN
            l_flg_prior_too := 1;
        ELSE
            l_flg_prior_too := i_flg_prior_too;
        END IF;
    
        -- Counts only with the same group       
        IF l_flg_prior_too = 1
        THEN
            SELECT COUNT(*)
              INTO l_posso_atender_prior
              FROM wl_mach_prof_queue w, wl_queue wq
             WHERE w.id_professional = i_id_prof.id
               AND w.id_wl_machine = i_id_mach
               AND wq.flg_priority = pk_alert_constant.g_yes
               AND w.id_wl_queue = wq.id_wl_queue;
        ELSE
            l_posso_atender_prior := 0;
        END IF;
    
        -- se nalguma das minhas filas posso atender os priors
        IF l_posso_atender_prior >= 1
        THEN
            g_error := 'GET WAITING_LINE FROM PRIORITY QUEUES';
            -- filas prioritarias
            FOR tuplo_prior IN c_get_prior
            LOOP
            
                g_error := 'IS PRIORITY QUEUE ' || tuplo_prior.id_wl_queue || 'MINE?';
                SELECT COUNT(*)
                  INTO l_its_mine
                  FROM wl_mach_prof_queue
                 WHERE id_wl_queue = tuplo_prior.id_wl_queue
                   AND id_wl_machine = i_id_mach
                   AND id_professional = i_id_prof.id;
            
                -- a fila prioritaria está alocada a mim
                IF l_its_mine != 0
                THEN
                    l_queues.extend;
                    l_queues(l_i) := tuplo_prior.id_wl_queue;
                    l_i := l_i + 1;
                ELSE
                
                    g_error := 'PRIORITY QUEUE ' || tuplo_prior.id_wl_queue || ' IS NOT MINE.';
                    -- A FILA NAO ESTÁ ALOCADA A MIM MAS E A OUTROS?
                    SELECT COUNT(*)
                      INTO l_its_not_mine_but_aloc
                      FROM wl_mach_prof_queue
                     WHERE id_wl_queue = tuplo_prior.id_wl_queue
                       AND id_wl_machine != i_id_mach
                       AND id_professional != i_id_prof.id;
                
                    IF l_its_not_mine_but_aloc = 0
                    THEN
                        l_queues.extend;
                        l_queues(l_i) := tuplo_prior.id_wl_queue;
                        l_i := l_i + 1;
                    END IF;
                END IF;
            END LOOP;
        END IF;
    
        g_error := 'GET PRIORITY WL_WAITING_LINE';
        IF NOT pk_wlinternal.get_next_call_queue_internal(i_lang,
                                                          i_id_prof,
                                                          l_queues,
                                                          l_flg_prior_too,
                                                          l_wl_waiting_line_row,
                                                          o_error)
        THEN
            g_ret := pk_alert_exceptions.process_error(i_lang,
                                                       o_error.ora_sqlcode,
                                                       o_error.ora_sqlerrm,
                                                       o_error.err_desc,
                                                       g_package_owner,
                                                       g_package_name,
                                                       'GET_NEXT_CALL',
                                                       o_error);
            pk_types.open_my_cursor(o_data_wait);
            RETURN FALSE;
        END IF;
    
        l_i      := 1;
        l_queues := table_number();
    
        IF l_wl_waiting_line_row.id_wl_waiting_line IS NULL
        THEN
        
            g_error := 'GET WL_WAITING_LINE FROM MY QUEUES';
            FOR tuplo_myq IN c_get_my_queue
            LOOP
            
                l_queues.extend;
                l_queues(l_i) := tuplo_myq.id_wl_queue;
                l_i := l_i + 1;
            
            END LOOP;
        
            g_error := 'GET WL_WAITING_LINE';
            IF NOT pk_wlinternal.get_next_call_queue_internal(i_lang,
                                                              i_id_prof,
                                                              l_queues,
                                                              l_flg_prior_too,
                                                              l_wl_waiting_line_row,
                                                              o_error)
            THEN
                g_ret := pk_alert_exceptions.process_error(i_lang,
                                                           o_error.ora_sqlcode,
                                                           o_error.ora_sqlerrm,
                                                           o_error.err_desc,
                                                           g_package_owner,
                                                           g_package_name,
                                                           'GET_NEXT_CALL',
                                                           o_error);
                pk_types.open_my_cursor(o_data_wait);
                RETURN FALSE;
            END IF;
        
        END IF;
    
        IF l_wl_waiting_line_row.id_wl_waiting_line IS NOT NULL
        THEN
            g_error := 'CALC WL_WAITING_LINE INFO';
            OPEN o_data_wait FOR
                SELECT l_wl_waiting_line_row.char_queue char_queue,
                       l_wl_waiting_line_row.number_queue ticket_number,
                       pk_wlcore.get_queue_color(i_lang, i_id_prof, color) color_queue,
                       pk_translation.get_translation(i_lang, code_name_queue) name_queue,
                       l_wl_waiting_line_row.id_wl_waiting_line id_wait
                  FROM wl_queue
                 WHERE id_wl_queue = l_wl_waiting_line_row.id_wl_queue;
        
        ELSE
            g_error := 'CALC WL_WAITING_LINE DUMMY INFO';
            pk_types.open_my_cursor(o_data_wait);
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            g_ret := pk_alert_exceptions.process_error(i_lang,
                                                       SQLCODE,
                                                       SQLERRM,
                                                       g_error,
                                                       g_package_owner,
                                                       g_package_name,
                                                       'GET_NEXT_CALL',
                                                       o_error);
            ROLLBACK;
            pk_types.open_my_cursor(o_data_wait);
            RETURN FALSE;
    END get_next_call;

    /********************************************************************************************
     *   
     *  Returns the next ticket to be called, from the provided group of queues.  
     *
     * @param i_lang                    Language ID
     * @param i_id_queues               Table Number with the queues to verify
     * @param i_flg_prior_too           Param to check wether the priority queues should or not be taken into account.
     * @param o_id_waiting_line         ID of the ticket to be called next.
     * @param o_error     
     *
     * @return                         true or false 
     *
     * @author                          Ricardo Nuno Almeida
     * @version                         0.1
     * @since                           2009/02/05
    **********************************************************************************************/
    FUNCTION get_next_call_queue
    (
        i_lang            IN language.id_language%TYPE,
        i_id_queues       IN table_number,
        i_flg_prior_too   IN NUMBER,
        o_id_waiting_line OUT wl_waiting_line.id_wl_waiting_line%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rows table_varchar;
    
    BEGIN
    
        IF i_id_queues IS NOT NULL
        THEN
            g_error := 'GET TICKET';
            pk_alertlog.log_debug(g_error);
        
            BEGIN
            
                SELECT data.id_wl_waiting_line
                  INTO o_id_waiting_line
                  FROM (SELECT w.id_wl_waiting_line, decode(i_flg_prior_too, 1, wq.flg_priority, 0) priority
                          FROM wl_waiting_line w
                         INNER JOIN wl_queue wq
                            ON wq.id_wl_queue = w.id_wl_queue
                         WHERE w.id_wl_queue IN (SELECT *
                                                   FROM TABLE(i_id_queues))
                           AND w.flg_wl_status = pk_alert_constant.g_wr_wl_status_e
                           AND trunc(w.dt_begin_tstz) = trunc(current_timestamp)
                         ORDER BY priority DESC, w.dt_begin_tstz ASC) data
                 WHERE rownum = 1;
            
            EXCEPTION
                WHEN OTHERS THEN
                    o_id_waiting_line := NULL;
            END;
        
            IF o_id_waiting_line IS NOT NULL
            THEN
                ts_wl_waiting_line.upd(id_wl_waiting_line_in => o_id_waiting_line,
                                       flg_wl_status_in      => pk_alert_constant.g_wr_wl_status_x,
                                       flg_wl_status_nin     => FALSE,
                                       rows_out              => l_rows);
            
                t_data_gov_mnt.process_update(i_lang, profissional(-1, 0, 0), 'WL_WAITING_LINE', l_rows, o_error);
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
                                              'GET_NEXT_CALL_QUEUE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_next_call_queue;

    /**
    * Gets patients registered at sonho/sinus
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_ID_PROF  professional, institution and software ids
    * @param   I_ID_MACH The machine name id.
    * @param   i_episode ID EPISODE for demo insertion in WL_WAITING_LINE
    * @param   O_DADOS The patients info
    * @param   o_last_called_ticket Last called ticket be the i_id_prof.id professional info
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Luís Gaspar
    * @version 1.0
    * @since   21-11-2006
    *
    * @EDIT 08-03-2009 RNAlmeida:
    *  Function now incorporates DEMO features.
    *
    */
    FUNCTION get_sonho
    (
        i_lang               IN language.id_language%TYPE,
        i_id_prof            IN profissional,
        i_id_mach            IN NUMBER,
        i_episode            IN episode.id_episode%TYPE,
        o_dados              OUT pk_types.cursor_type,
        o_last_called_ticket OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        comfirmedlbl sys_message.desc_message%TYPE;
    
        l_num      PLS_INTEGER;
        l_dt_begin TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end   TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_hand_off_type   sys_config.value%TYPE;
        l_wl_waiting_line wl_waiting_line%ROWTYPE;
        l_internal_error  EXCEPTION;
        l_demo            BOOLEAN := FALSE;
    
    BEGIN
    
        g_error := 'CALL pk_hand_off_core.get_hand_off_type';
        pk_alertlog.log_debug(g_error);
        pk_hand_off_core.get_hand_off_type(i_lang => i_lang, i_prof => i_id_prof, io_hand_off_type => l_hand_off_type);
    
        g_error := 'GET WL_CONFIRMED_LBM SYS_MESSAGE';
        pk_alertlog.log_debug(g_error, g_package_name);
        comfirmedlbl := pk_message.get_message(i_lang, i_id_prof, 'WL_CONFIRMED_LBL');
    
        l_demo := pk_sysconfig.get_config(pk_wlcore.g_wl_demo_flg, i_id_prof.institution, i_id_prof.software) =
                  pk_alert_constant.get_yes;
    
        g_error := 'GET DEMO_MODE';
        IF l_demo
        THEN
            g_error    := 'GET DATES';
            l_dt_begin := pk_date_utils.trunc_insttimezone(i_id_prof,
                                                           nvl(pk_date_utils.get_string_tstz(i_lang,
                                                                                             i_id_prof,
                                                                                             NULL,
                                                                                             NULL),
                                                               current_timestamp));
            l_dt_end   := pk_date_utils.add_days_to_tstz(l_dt_begin, 1);
        
            g_error := 'CHECK TIMER';
            SELECT COUNT(w.patient_id)
              INTO l_num
              FROM (SELECT wps.patient_id,
                           (extract(SECOND FROM(current_timestamp - wps.dt_consult_tstz)) +
                           (extract(minute FROM(current_timestamp - wps.dt_consult_tstz)) * 60) +
                           (extract(hour FROM(current_timestamp - wps.dt_consult_tstz)) * 3600)) total
                      FROM wl_patient_sonho wps
                     WHERE wps.prof_id = i_id_prof.id) w
             WHERE w.total < 30;
        
            IF (l_num = 0)
            THEN
                -- There are no records in the interface table with less than 30 secs of wait. We can add one...
                -- ... provided there are uncalled tickets, of course. 
                g_error := 'CHECK TICKETS';
                SELECT COUNT(ticket.id_wl_waiting_line)
                  INTO l_num
                  FROM (SELECT wl.id_wl_waiting_line,
                               (extract(SECOND FROM(current_timestamp - wl.dt_begin_tstz)) +
                               (extract(minute FROM(current_timestamp - wl.dt_begin_tstz)) * 60) +
                               (extract(hour FROM(current_timestamp - wl.dt_begin_tstz)) * 3600)) total
                          FROM wl_waiting_line wl
                         INNER JOIN wl_queue wq
                            ON wq.id_wl_queue = wl.id_wl_queue
                         INNER JOIN wl_machine wm
                            ON wm.id_wl_machine = i_id_mach
                           AND wm.id_wl_queue_group = wq.id_wl_queue_group
                         INNER JOIN wl_mach_prof_queue wmpq
                            ON wmpq.id_wl_queue = wq.id_wl_queue
                           AND wmpq.id_professional = i_id_prof.id
                         WHERE wl.dt_end_tstz IS NULL
                           AND wl.id_episode IS NULL
                           AND wq.id_department = pk_wlcore.g_demo_department_0
                           AND wl.flg_wl_status IN (pk_alert_constant.g_wr_wl_status_x)
                           AND wq.flg_type_queue = pk_alert_constant.g_wr_wq_type_a
                           AND wl.dt_begin_tstz BETWEEN l_dt_begin AND l_dt_end) ticket
                 WHERE ticket.total > 30;
            
                IF l_num > 0
                THEN
                    -- Everything checked, we can ignite.                                   
                    g_error := 'CALL create_context_wps';
                    IF NOT pk_demo.create_context_wps(i_lang    => i_lang,
                                                      i_prof    => i_id_prof,
                                                      i_episode => i_episode,
                                                      o_error   => o_error)
                    THEN
                        pk_types.open_my_cursor(o_dados);
                        pk_types.open_my_cursor(o_last_called_ticket);
                        RETURN FALSE;
                    END IF;
                END IF;
            END IF;
        END IF;
    
        g_error := 'GET WL_PATIENT_SONHO';
        pk_alertlog.log_debug(g_error, g_package_name);
        IF l_demo
        THEN
            OPEN o_dados FOR
                SELECT DISTINCT pa.id_patient id_patient,
                                to_char(pa.id_patient) id_pat_str,
                                pk_patphoto.get_pat_photo(i_lang, i_id_prof, pa.id_patient, wps.id_episode, NULL) url_foto,
                                pk_date_utils.to_char_insttimezone(i_id_prof, wps.dt_consult_tstz, 'HH24:MI') dt_consult,
                                wps.patient_id id_patient,
                                pk_patient.get_pat_name(i_lang, i_id_prof, pa.id_patient, wps.id_episode) nome,
                                pk_adt.get_pat_non_disc_options(i_lang, i_id_prof, pa.id_patient) pat_ndo,
                                pk_adt.get_pat_non_disclosure_icon(i_lang, i_id_prof, pa.id_patient) pat_nd_icon,
                                pk_patient.get_pat_age(i_lang,
                                                       pa.dt_birth,
                                                       pa.dt_deceased,
                                                       pa.age,
                                                       i_id_prof.institution,
                                                       i_id_prof.software) idade,
                                pk_patient.get_gender(i_lang, pa.gender) sexo,
                                pk_prof_utils.get_nickname(i_lang, wps.clin_prof_id) nome_medico,
                                comfirmedlbl confirmed_label,
                                pk_translation.get_translation(i_lang, cs.code_clinical_service) consulta_tipo,
                                NULL idsala,
                                ' ' sala,
                                wps.id_episode
                  FROM wl_patient_sonho wps
                  JOIN patient pa
                    ON pa.id_patient = wps.patient_id
                  JOIN clinical_service cs
                    ON cs.id_clinical_service = wps.consult_id
                 WHERE wps.prof_id = i_id_prof.id
                   AND wps.id_institution = i_id_prof.institution;
        ELSE
            OPEN o_dados FOR
                SELECT DISTINCT pa.id_patient id_patient,
                                to_char(pa.id_patient) id_pat_str,
                                pk_patphoto.get_pat_photo(i_lang, i_id_prof, pa.id_patient, wps.id_episode, NULL) url_foto,
                                pk_date_utils.to_char_insttimezone(i_id_prof, wps.dt_consult_tstz, 'HH24:MI') dt_consult,
                                wps.patient_id id_patient,
                                pk_patient.get_pat_name(i_lang, i_id_prof, pa.id_patient, wps.id_episode) nome,
                                pk_adt.get_pat_non_disc_options(i_lang, i_id_prof, pa.id_patient) pat_ndo,
                                pk_adt.get_pat_non_disclosure_icon(i_lang, i_id_prof, pa.id_patient) pat_nd_icon,
                                pk_patient.get_pat_age(i_lang,
                                                       pa.dt_birth,
                                                       pa.dt_deceased,
                                                       pa.age,
                                                       i_id_prof.institution,
                                                       i_id_prof.software) idade,
                                pk_patient.get_gender(i_lang, pa.gender) sexo,
                                pk_prof_utils.get_nickname(i_lang, wps.clin_prof_id) nome_medico,
                                comfirmedlbl confirmed_label,
                                pk_translation.get_translation(i_lang, cs.code_clinical_service) consulta_tipo,
                                wwr.id_room_wait idsala,
                                decode(wwr.id_room_wait,
                                       NULL,
                                       ' ',
                                       nvl(rwait.desc_room, pk_translation.get_translation(i_lang, rwait.code_room))) sala,
                                wps.id_episode
                  FROM wl_patient_sonho wps
                  JOIN patient pa
                    ON pa.id_patient = wps.patient_id
                  JOIN clinical_service cs
                    ON cs.id_clinical_service = wps.consult_id
                  JOIN prof_room pr
                    ON pr.id_professional = wps.prof_id
                   AND pr.flg_pref = g_prof_room_flg_pref_y
                  JOIN room rpref
                    ON rpref.id_room = pr.id_room
                  JOIN department d
                    ON rpref.id_department = d.id_department
                   AND d.id_institution = i_id_prof.institution
                   AND d.id_software = i_id_prof.software
                  JOIN dep_clin_serv dcs
                    ON dcs.id_clinical_service = cs.id_clinical_service
                   AND dcs.id_department = d.id_department
                  JOIN prof_dep_clin_serv pdcs
                    ON pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
                   AND pdcs.id_professional = wps.prof_id
                  LEFT JOIN wl_waiting_room wwr
                    ON rpref.id_room = wwr.id_room_consult
                  LEFT JOIN room rwait
                    ON wwr.id_room_wait = rwait.id_room
                 WHERE wps.prof_id = i_id_prof.id
                   AND wps.id_institution = i_id_prof.institution;
        END IF;
    
        g_error := 'CALL get_last_called_ticket. id_prof:' || i_id_prof.id;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_wlinternal.get_last_called_ticket(i_lang            => i_lang,
                                                    i_prof            => i_id_prof,
                                                    o_wl_waiting_line => l_wl_waiting_line,
                                                    o_error           => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        IF l_wl_waiting_line.id_wl_waiting_line IS NOT NULL
        THEN
            OPEN o_last_called_ticket FOR
                SELECT pk_wlcore.get_queue_color(i_lang, i_id_prof, wq.color) color_queue,
                       l_wl_waiting_line.id_wl_waiting_line id_wait,
                       l_wl_waiting_line.char_queue char_queue,
                       l_wl_waiting_line.number_queue ticket_number,
                       l_wl_waiting_line.id_wl_queue id_wl_queue,
                       pk_translation.get_translation(i_lang, wq.code_name_queue) name_queue
                  FROM wl_queue wq
                 WHERE wq.id_wl_queue = l_wl_waiting_line.id_wl_queue;
        ELSE
            pk_types.open_my_cursor(o_last_called_ticket);
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
                                              'GET_SONHO',
                                              o_error);
        
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_dados);
            pk_types.open_my_cursor(o_last_called_ticket);
            RETURN FALSE;
    END get_sonho;

BEGIN

    xpl         := '''';
    xsp         := chr(32);
    pk_adm_mode := 1;
    pk_med_mode := 2;
    pk_nur_mode := 3;

    pk_wl_id_sonho   := 'WL_ID_SONHO';
    pk_wl_lang       := 'WL_LANG';
    pk_nur_flg_type  := 'N';
    pk_nurse_queue   := 'WL_ID_NURSE_QUEUE';
    pk_id_department := 'WL_ID_DEPARTMENT';
    pk_id_software   := pk_wlcore.get_id_software();

    g_error_msg_code       := 'COMMON_M001';
    g_prof_room_flg_pref_y := 'Y';

    g_pdcs_flg_status_s := 'S';

    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END;
/
