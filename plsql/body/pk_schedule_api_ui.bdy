/*-- Last Change Revision: $Rev: 2027665 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:56 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE BODY pk_schedule_api_ui IS

    -- Private type declarations

    -- Private constant declarations

    -- Private variable declarations

    -- Function and procedure implementations

    /* To be used by UI in patient clinical area -> discharge screen -> schedule subsequent appointment 
    * and similar places. This functions returns the appointment id content needed by the scheduler 3 screen.
    * 
    * @param i_lang              Language ID
    * @param i_prof              Professional ID/Institution ID/Software ID
    * @param i_dep_type          sch. type. C=physician app, N=nurse app, etc.
    * @param i_flg_occurr        F= first appointment, S=subsequent,  O=both
    * @param i_id_dcs            dep clin serv id
    * @param i_flg_prof           Y = this is a consult req with a specific target prof.  N = no specific target prof (specialty appoint)
    * @param o_id_content        id content as needed by scheduler 3. comes from appointment table. Previously this came from column id_content, now gone
    * @param o_flg_proceed        Indicates if further action is to be performed by Flash.
    * @param o_flg_show           Set if a message is displayed or not
    * @param o_msg_title          Message title
    * @param o_msg                Message body to be displayed in flash
    * @param o_button             message popup buttons
    * @param o_error             error info
    *
    * @return                     true / false
    *
    * @author                     Telmo
    * @version                    2.6
    * @date                       11-03-2010
    * 
    * UPDATE 19-10-2010: column appointment.id_content no longer exists, replaced by id_appointment. I opted to leave the function name unchanged
    * so as to not disturb UI layer
    */
    FUNCTION get_id_content
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_dep_type    IN sch_event.dep_type%TYPE,
        i_flg_occurr  IN sch_event.flg_occurrence%TYPE,
        i_id_dcs      IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_flg_prof    IN VARCHAR2,
        o_id_content  OUT appointment.id_appointment%TYPE,
        o_flg_proceed OUT VARCHAR2,
        o_flg_show    OUT VARCHAR2,
        o_msg_title   OUT VARCHAR2,
        o_msg         OUT VARCHAR2,
        o_button      OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL PK_SCHEDULE_API_DOWNSTREAM.GET_ID_CONTENT';
        RETURN pk_schedule_api_downstream.get_id_content(i_lang        => i_lang,
                                                         i_prof        => i_prof,
                                                         i_dep_type    => i_dep_type,
                                                         i_flg_occurr  => i_flg_occurr,
                                                         i_id_dcs      => i_id_dcs,
                                                         i_flg_prof    => i_flg_prof,
                                                         o_id_content  => o_id_content,
                                                         o_flg_proceed => o_flg_proceed,
                                                         o_flg_show    => o_flg_show,
                                                         o_msg_title   => o_msg_title,
                                                         o_msg         => o_msg,
                                                         o_button      => o_button,
                                                         o_error       => o_error);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ID_CONTENT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_id_content;

    /* To be used by referral 
    * 
    * @param i_lang              Language ID
    * @param i_prof              Professional ID/Institution ID/Software ID
    * @param i_dep_type          sch. type. C=physician app, N=nurse app, U=nutrition apps, AS=social worker app
    * @param i_flg_occurr        F= first appointment, S=subsequent,  O=both
    * @param i_id_dcs            dep clin serv id
    * @param i_flg_prof          Y = this is a consult req with a specific target prof.  N = no specific target prof (specialty appoint)
    *
    * @return                     appointment.id_appointment%TYPE (varchar)
    *
    * @author                     Telmo
    * @version                    2.6.0.4  ALERT-14479
    * @date                       22-10-2010
    */
    FUNCTION get_id_content
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_dep_type   IN sch_event.dep_type%TYPE,
        i_flg_occurr IN sch_event.flg_occurrence%TYPE,
        i_id_dcs     IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_flg_prof   IN VARCHAR2
    ) RETURN appointment.id_appointment%TYPE IS
        l_retval      appointment.id_appointment%TYPE;
        l_b           BOOLEAN;
        o_flg_proceed VARCHAR2(1);
        o_flg_show    VARCHAR2(1);
        o_msg_title   VARCHAR2(200);
        o_msg         VARCHAR2(200);
        o_button      VARCHAR2(200);
        o_error       t_error_out;
    BEGIN
        g_error := 'CALL PK_SCHEDULE_API_DOWNSTREAM.GET_ID_CONTENT';
        l_b     := pk_schedule_api_downstream.get_id_content(i_lang        => i_lang,
                                                             i_prof        => i_prof,
                                                             i_dep_type    => i_dep_type,
                                                             i_flg_occurr  => i_flg_occurr,
                                                             i_id_dcs      => i_id_dcs,
                                                             i_flg_prof    => i_flg_prof,
                                                             o_id_content  => l_retval,
                                                             o_flg_proceed => o_flg_proceed,
                                                             o_flg_show    => o_flg_show,
                                                             o_msg_title   => o_msg_title,
                                                             o_msg         => o_msg,
                                                             o_button      => o_button,
                                                             o_error       => o_error);
        RETURN l_retval;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ID_CONTENT',
                                              o_error);
            RETURN NULL;
    END get_id_content;

    /* This function applies the id content provided by the function get_id_content to severam consult requisitions.
    * 
    * @param i_lang              Language ID
    * @param i_prof              Professional ID/Institution ID/Software ID
    * @param i_id_cr          List of consult request
    * @param o_id_content        list id content as needed by scheduler 3. comes from appointment table
    * @param o_flg_proceed        Indicates if further action is to be performed by Flash.
    * @param o_flg_show           Set if a message is displayed or not
    * @param o_msg_title          Message title
    * @param o_msg                Message body to be displayed in flash
    * @param o_button             message popup buttons
    * @param o_error             error info
    *
    * @return                     true / false
    *
    * @author                     SS
    * @version                    2.6.0.3
    * @date                       01-07-2010
    */
    FUNCTION get_cr_id_content
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_cr       IN NUMBER,
        o_id_content  OUT VARCHAR2,
        o_flg_proceed OUT VARCHAR2,
        o_flg_show    OUT VARCHAR2,
        o_msg_title   OUT VARCHAR2,
        o_msg         OUT VARCHAR2,
        o_button      OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_dep_type       sch_event.dep_type%TYPE;
        l_flg_occurr     sch_event.flg_occurrence%TYPE;
        l_id_dcs         dep_clin_serv.id_dep_clin_serv%TYPE;
        l_flg_prof       VARCHAR2(200);
        l_sch_event      sch_event.id_sch_event%TYPE;
        l_prof_requested professional.id_professional%TYPE;
    BEGIN
    
        BEGIN
            SELECT pk_alert_constant.g_yes
              INTO l_flg_prof
              FROM request_prof rp
             WHERE rp.id_consult_req = i_id_cr
               AND rp.flg_active = pk_alert_constant.g_yes;
        EXCEPTION
            WHEN no_data_found THEN
                l_flg_prof := pk_alert_constant.g_no;
        END;
    
        SELECT nvl(se.dep_type, 'C'),
               nvl(se.flg_occurrence, 'S'),
               cr.id_dep_clin_serv,
               decode(cr.id_prof_requested, NULL, l_flg_prof, pk_alert_constant.g_yes),
               cr.id_sch_event
          INTO l_dep_type, l_flg_occurr, l_id_dcs, l_flg_prof, l_sch_event
          FROM consult_req cr
          LEFT JOIN sch_event se
            ON cr.id_sch_event = se.id_sch_event
         WHERE cr.id_consult_req = i_id_cr;
    
        IF l_sch_event IS NOT NULL
        THEN
            g_error := 'CALL PK_SCHEDULE_API_DOWNSTREAM.GET_ID_CONTENT 1';
            IF NOT pk_schedule_api_downstream.get_id_content(i_lang         => i_lang,
                                                             i_prof         => i_prof,
                                                             i_id_sch_event => l_sch_event,
                                                             i_id_dcs       => l_id_dcs,
                                                             o_id_content   => o_id_content,
                                                             o_flg_proceed  => o_flg_proceed,
                                                             o_flg_show     => o_flg_show,
                                                             o_msg_title    => o_msg_title,
                                                             o_msg          => o_msg,
                                                             o_button       => o_button,
                                                             o_error        => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
        ELSE
            g_error := 'CALL PK_SCHEDULE_API_DOWNSTREAM.GET_ID_CONTENT 2';
            IF NOT pk_schedule_api_downstream.get_id_content(i_lang        => i_lang,
                                                             i_prof        => i_prof,
                                                             i_dep_type    => l_dep_type,
                                                             i_flg_occurr  => l_flg_occurr,
                                                             i_id_dcs      => l_id_dcs,
                                                             i_flg_prof    => l_flg_prof,
                                                             o_id_content  => o_id_content,
                                                             o_flg_proceed => o_flg_proceed,
                                                             o_flg_show    => o_flg_show,
                                                             o_msg_title   => o_msg_title,
                                                             o_msg         => o_msg,
                                                             o_button      => o_button,
                                                             o_error       => o_error)
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
                                              'GET_ID_CONTENT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_cr_id_content;

    /* This function applies the id content provided by the function get_id_content or get_ids to several consult requisitions.
    * 
    * @param i_lang              Language ID
    * @param i_prof              Professional ID/Institution ID/Software ID
    * @param i_id_list          List of consult_req ids or exam ids
    * @param i_flg_type_list    List of id type (C - Consult, E - Exam)
    * @param o_id_content        list id content as needed by scheduler 3. comes from appointment table
    * @param o_flg_proceed        Indicates if further action is to be performed by Flash.
    * @param o_flg_show           Set if a message is displayed or not
    * @param o_msg_title          Message title
    * @param o_msg                Message body to be displayed in flash
    * @param o_button             message popup buttons
    * @param o_error             error info
    *
    * @return                     true / false
    *
    * @author                     SS
    * @version                    2.6.0.3
    * @date                       01-07-2010
    */
    FUNCTION get_cr_exam_id_content_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_list       IN table_number,
        i_flg_type_list IN table_varchar,
        o_id_content    OUT table_varchar,
        o_flg_proceed   OUT VARCHAR2,
        o_flg_show      OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_msg           OUT VARCHAR2,
        o_button        OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_content  table_varchar := table_varchar();
        l_flg_proceed VARCHAR2(200);
        l_flg_show    VARCHAR2(200);
        l_msg_title   VARCHAR2(4000);
        l_msg         VARCHAR2(4000);
        l_button      VARCHAR2(200);
    
        l_dep_type   sch_event.dep_type%TYPE;
        l_flg_occurr sch_event.flg_occurrence%TYPE;
        l_id_dcs     dep_clin_serv.id_dep_clin_serv%TYPE;
        l_flg_prof   VARCHAR2(200);
    BEGIN
        FOR i IN 1 .. i_id_list.count
        LOOP
            l_id_content.extend;
        
            IF i_flg_type_list(i) = 'C'
            THEN
            
                g_error := 'CALL PK_SCHEDULE_API_DOWNSTREAM.GET_ID_CONTENT';
                IF NOT get_cr_id_content(i_lang        => i_lang,
                                         i_prof        => i_prof,
                                         i_id_cr       => i_id_list(i),
                                         o_id_content  => l_id_content(l_id_content.count),
                                         o_flg_proceed => l_flg_proceed,
                                         o_flg_show    => l_flg_show,
                                         o_msg_title   => l_msg_title,
                                         o_msg         => l_msg,
                                         o_button      => l_button,
                                         o_error       => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
                IF l_flg_show = pk_alert_constant.g_yes
                THEN
                    o_flg_proceed := l_flg_proceed;
                    o_flg_show    := l_flg_show;
                    o_msg_title   := l_msg_title;
                    o_msg         := l_msg;
                    o_button      := l_button;
                END IF;
            
            ELSIF i_flg_type_list(i) = 'E'
            THEN
                IF NOT get_id_content_exam(i_lang       => i_lang,
                                           i_prof       => i_prof,
                                           i_id_exam    => i_id_list(i),
                                           o_id_content => l_id_content(l_id_content.count),
                                           o_error      => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            ELSE
                RETURN FALSE;
            END IF;
        END LOOP;
    
        o_id_content := l_id_content;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ID_CONTENT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_cr_exam_id_content_list;

    FUNCTION check_patient_event
    (
        i_id_patient     IN patient.id_patient%TYPE,
        i_id_schedule    IN schedule.id_schedule%TYPE,
        o_schedule_event OUT schedule.id_sch_event%TYPE
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'SELECT SCHEDULE EVENT';
        SELECT s.id_sch_event
          INTO o_schedule_event
          FROM schedule s
          JOIN sch_group sg
            ON s.id_schedule = sg.id_schedule
         WHERE s.id_schedule = i_id_schedule
           AND sg.id_patient = i_id_patient;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
        
    END check_patient_event;

    /**********************************************************************************************
    * Fetch the screen information about procedures' schedule. Function used by reports
    */
    FUNCTION get_notifications
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_schedule_ext IN sch_api_map_ids.id_schedule_ext%TYPE,
        i_id_patient      IN sch_group.id_patient%TYPE,
        o_domain          OUT pk_types.cursor_type,
        o_actual_event    OUT pk_types.cursor_type,
        o_to_notify       OUT pk_types.cursor_type,
        o_notified        OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name        VARCHAR2(32) := 'GET_NOTIFICATIONS';
        l_schedule_event   schedule.id_sch_event%TYPE;
        l_tab_id_schedules table_number;
        l_continue         BOOLEAN := TRUE;
        c_map_sch          SYS_REFCURSOR;
    BEGIN
    
        g_error            := 'GET_NOTIFICATIONS - get pfh ids';
        l_tab_id_schedules := pk_schedule_api_downstream.get_pfh_ids(i_id_schedule_ext);
    
        FOR i IN 1 .. l_tab_id_schedules.count
        LOOP
            -- ACTUAL EVENT
            IF check_patient_event(i_id_patient, l_tab_id_schedules(i), l_schedule_event)
            THEN
            
                IF l_schedule_event = pk_schedule.g_event_mfr
                THEN
                    -- call mfr function
                    g_error := 'CALL GET_NOTIFICATIONS_MFR';
                    IF NOT pk_schedule.get_notifications_mfr(i_lang            => i_lang,
                                                             i_prof            => i_prof,
                                                             i_tab_id_schedule => table_number(l_tab_id_schedules(i)),
                                                             o_error           => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                ELSIF pk_schedule.is_series_appointment(i_id_schedule => l_tab_id_schedules(i)) =
                      pk_alert_constant.g_yes
                THEN
                    --call series function
                    g_error := 'CALL GET_NOTIFICATIONS_SERIES';
                    IF NOT pk_schedule.get_notifications_series(i_lang            => i_lang,
                                                                i_prof            => i_prof,
                                                                i_tab_id_schedule => table_number(l_tab_id_schedules(i)),
                                                                o_error           => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                ELSE
                    g_error := 'CALL get_notifications_general';
                    IF NOT pk_schedule.get_notifications_general(i_lang            => i_lang,
                                                                 i_prof            => i_prof,
                                                                 i_tab_id_schedule => table_number(l_tab_id_schedules(i)),
                                                                 o_error           => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                END IF;
            END IF;
        
        --end looping through pfh schedules
        END LOOP;
    
        g_error := 'OPEN cursor o_actual_event';
        OPEN o_actual_event FOR
            SELECT t.*
              FROM sch_tmptab_notifs t
             ORDER BY order_nr;
    
        g_error := 'GET_NOTIFICATIONS - empty temp table sch_tmptab_notifs';
        DELETE FROM sch_tmptab_notifs;
        FOR i IN 1 .. l_tab_id_schedules.count
        LOOP
        
            IF check_patient_event(i_id_patient, l_tab_id_schedules(i), l_schedule_event)
            THEN
                -- PENDING EVENTS
                g_error := 'CALL get_conf_pend_schs for pending schedules';
                IF NOT pk_schedule.get_conf_pend_schs2(i_lang                => i_lang,
                                                       i_prof                => i_prof,
                                                       i_id_patient          => i_id_patient,
                                                       i_id_flg_notification => pk_schedule.g_sched_flg_notif_pending,
                                                       i_id_schedule_actual  => l_tab_id_schedules(i),
                                                       o_error               => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            END IF;
        END LOOP;
    
        g_error := 'OPEN CURSOR o_to_notify';
        OPEN o_to_notify FOR
            SELECT t.*
              FROM sch_tmptab_notifs t
             ORDER BY order_nr;
    
        DELETE FROM sch_tmptab_notifs;
        FOR i IN 1 .. l_tab_id_schedules.count
        LOOP
        
            IF check_patient_event(i_id_patient, l_tab_id_schedules(i), l_schedule_event)
            THEN
                -- CONFIRMED EVENTS
                g_error := 'CALL get_conf_pend_schs for confirmed schedules';
                IF NOT pk_schedule.get_conf_pend_schs2(i_lang                => i_lang,
                                                       i_prof                => i_prof,
                                                       i_id_patient          => i_id_patient,
                                                       i_id_flg_notification => pk_schedule.g_sched_flg_notif_notified,
                                                       i_id_schedule_actual  => l_tab_id_schedules(i),
                                                       o_error               => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            END IF;
        END LOOP;
    
        g_error := 'OPEN CURSOR o_notified';
        OPEN o_notified FOR
            SELECT t.*
              FROM sch_tmptab_notifs t
             ORDER BY order_nr;
    
        -- Fetch the possible ways of notifying a patient
        g_error := 'OPEN CURSOR - NOTIFICATION VIA';
        OPEN o_domain FOR
            SELECT sd.img_name icon, sd.desc_val description, sd.rank rank, sd.val val
              FROM sys_domain sd
             WHERE sd.code_domain = pk_schedule.g_notification_via
               AND sd.domain_owner = pk_sysdomain.k_default_schema
               AND sd.id_language = i_lang
             ORDER BY sd.rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_domain);
            pk_types.open_my_cursor(o_actual_event);
            pk_types.open_my_cursor(o_to_notify);
            pk_types.open_my_cursor(o_notified);
        
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_notifications;

    /* return exam id_content. UI needed this
    *
    * @param i_lang              Language ID
    * @param i_prof              Professional ID/Institution ID/Software ID
    * @param i_id_exam            exam id on which to base the search
    * @param o_id_content         output
    * @param o_error             error info
    *
    * @return                     true / false
    *
    * @author                     Telmo
    * @version                    2.6
    * @since                      29-03-2010
    */
    FUNCTION get_id_content_exam
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_exam    IN exam.id_exam%TYPE,
        o_id_content OUT exam.id_content%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_ID_CONTENT_EXAM';
        l_id_content_inv EXCEPTION;
    BEGIN
        g_error := 'GET EXAM ID_CONTENT';
        SELECT id_content
          INTO o_id_content
          FROM exam e
         WHERE e.id_exam = i_id_exam
           AND e.flg_available = pk_alert_constant.g_yes
           AND rownum = 1;
    
        g_error := 'CHECK IF ID_CONTENT IS NULL';
        IF TRIM(o_id_content) IS NULL
        THEN
            RAISE l_id_content_inv;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_id_content_inv THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => -21300,
                                              i_sqlerrm  => 'exam ' || i_id_exam || ' has no id_content',
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        WHEN no_data_found THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => -21301,
                                              i_sqlerrm  => 'exam ' || i_id_exam || ' not found',
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_id_content_exam;

    /* return exams id_contents. UI needed this
    *
    * @param i_lang              Language ID
    * @param i_prof              Professional ID/Institution ID/Software ID
    * @param i_ids_exam          exam ids on which to base the search
    * @param o_ids_content       output list
    * @param o_error             error info
    *
    * @return                     true / false
    *
    * @author                     Telmo
    * @version                    2.6
    * @since                      29-03-2010
    */
    FUNCTION get_ids_content_exam
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_ids_exam    IN table_number,
        o_ids_content OUT table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        i PLS_INTEGER;
    BEGIN
        o_ids_content := table_varchar();
    
        IF i_ids_exam IS NOT NULL
           AND i_ids_exam.count > 0
        THEN
            o_ids_content.extend(i_ids_exam.count);
        
            i := i_ids_exam.first;
            WHILE i IS NOT NULL
            LOOP
                IF NOT get_id_content_exam(i_lang       => i_lang,
                                           i_prof       => i_prof,
                                           i_id_exam    => i_ids_exam(i),
                                           o_id_content => o_ids_content(i),
                                           o_error      => o_error)
                THEN
                    RETURN FALSE;
                END IF;
                i := i_ids_exam.next(i);
            END LOOP;
        END IF;
        RETURN TRUE;
    
    END get_ids_content_exam;

    FUNCTION confirm_pending_sched
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE,
        o_id_schedule OUT sch_api_map_ids.id_schedule_ext%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        --Scheduler 3.0 variables
        l_transaction_id VARCHAR2(4000);
    
    BEGIN
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(l_transaction_id, i_prof);
    
        IF NOT pk_schedule_api_upstream.confirm_pending_sched(i_lang           => i_lang,
                                                              i_prof           => i_prof,
                                                              i_id_schedule    => i_id_schedule,
                                                              i_transaction_id => l_transaction_id,
                                                              o_id_schedule    => o_id_schedule,
                                                              o_error          => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END confirm_pending_sched;

    /*
    * Removes a pending schedule.
    *
    * @param i_lang                        Language identifier
    * @param i_prof                        Professional data: id, institution and software
    * @param i_id_schedule                 Schedule identifier
    * @param i_transaction_id              Scheduler transaction identifier
    * @param o_error                       An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Sérgio Santos
    * @version 1.0
    * @since   22-12-2009      
    */
    FUNCTION remove_pending_sched
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        --Scheduler 3.0 variables
        l_transaction_id VARCHAR2(4000);
    
    BEGIN
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(l_transaction_id, i_prof);
    
        IF NOT pk_schedule_api_upstream.remove_pending_sched(i_lang           => i_lang,
                                                             i_prof           => i_prof,
                                                             i_id_schedule    => i_id_schedule,
                                                             i_transaction_id => l_transaction_id,
                                                             o_error          => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END remove_pending_sched;

    FUNCTION get_schedule_details
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        o_schedule_details OUT pk_types.cursor_type,
        o_patients         OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN pk_schedule.get_schedule_details(i_lang             => i_lang,
                                                i_prof             => i_prof,
                                                i_id_schedule      => i_id_schedule,
                                                o_schedule_details => o_schedule_details,
                                                o_patients         => o_patients,
                                                o_error            => o_error);
    
    END get_schedule_details;

    /*
    * notifies scheduler 3 about a scheduled patient no-show
    *
    * @param i_lang                        Language identifier
    * @param i_prof                        Professional data: id, institution and software
    * @param i_id_schedule                 PFH schedule id
    * @param i_id_patient                  patient id
    * @param i_id_cancel_reason            no-show reason id. Comes from table cancel_reason
    * @param i_notes                       optional notes
    * @param o_error                       error info
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Telmo
    * @version 2.6.0.3.4
    * @date    29-10-2010
    */
    FUNCTION set_patient_no_show
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_cancel_reason IN sch_group.id_cancel_reason%TYPE,
        i_notes            IN sch_group.no_show_notes%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_transaction_id VARCHAR2(4000);
        l_func_exception EXCEPTION;
        l_id_external_request p1_external_request.id_external_request%TYPE;
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(NULL, i_prof);
    
        g_error := 'CALL PK_REF_EXT_SYS.GET_REFERRAL_ID i_id_schedule=' || i_id_schedule;
        IF NOT pk_ref_ext_sys.get_referral_id(i_lang                => i_lang,
                                              i_prof                => i_prof,
                                              i_id_schedule         => i_id_schedule,
                                              o_id_external_request => l_id_external_request,
                                              o_error               => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        IF l_id_external_request IS NULL
        THEN
            g_error := 'CALL PK_SCHEDULE_API_UPSTREAM.SET_PATIENT_NO_SHOW';
            IF NOT pk_schedule_api_upstream.set_patient_no_show(i_lang             => i_lang,
                                                                i_prof             => i_prof,
                                                                i_transaction_id   => l_transaction_id,
                                                                i_id_schedule      => i_id_schedule,
                                                                i_id_patient       => i_id_patient,
                                                                i_id_cancel_reason => i_id_cancel_reason,
                                                                i_notes            => i_notes,
                                                                o_error            => o_error)
            
            THEN
                RAISE l_func_exception;
            END IF;
        ELSE
            g_error := 'CALL PK_REF_EXT_SYS.SET_REF_NO_SHOW I_ID_REF=' || l_id_external_request;
            IF NOT pk_ref_ext_sys.set_ref_no_show(i_lang           => i_lang,
                                                  i_prof           => i_prof,
                                                  i_id_ref         => l_id_external_request,
                                                  i_notes          => i_notes,
                                                  i_reason         => i_id_cancel_reason,
                                                  i_date           => NULL,
                                                  i_transaction_id => l_transaction_id,
                                                  o_error          => o_error)
            
            THEN
                RAISE l_func_exception;
            END IF;
        
        END IF;
    
        pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_patient_no_show;

    /*
    * Gets id_schedule external (first id)
    *
    * @param i_lang               Language identifier
    * @param i_id_schedule        Schedule identifier
    * @param o_id_schedule        Schedule identifier in new Scheduler
    * @param o_error              An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @version 1.0
    * @since   21-10-2009      
    */
    FUNCTION get_schedule_id_ext
    (
        i_lang        IN language.id_language%TYPE,
        i_id_schedule IN sch_api_map_ids.id_schedule_pfh%TYPE,
        o_id_schedule OUT sch_api_map_ids.id_schedule_ext%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN pk_schedule_api_downstream.get_schedule_id_ext(i_lang        => i_lang,
                                                              i_id_schedule => i_id_schedule,
                                                              o_id_schedule => o_id_schedule,
                                                              o_error       => o_error);
    END get_schedule_id_ext;

BEGIN
    -- Log initialization.
    pk_alertlog.log_init(object_name => g_package_name, owner => g_package_owner);
END pk_schedule_api_ui;
/
