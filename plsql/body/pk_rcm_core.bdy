/*-- Last Change Revision: $Rev: 1850754 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2018-07-05 15:20:59 +0100 (qui, 05 jul 2018) $*/

CREATE OR REPLACE PACKAGE BODY pk_rcm_core IS

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    g_retval BOOLEAN;
    g_exception_np EXCEPTION;
    g_exception    EXCEPTION;
    g_sysdate pk_rcm_constant.t_timestamp;

    /**
    * Gets tokens needed to send message to the patient
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identifier and its context (institution and software)
    * @param   i_id_patient         Patient identifier
    * @param   i_id_rcm             Recommendation identifier
    * @param   o_tokens             Tokens needed to the message
    * @param   o_error              Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   09-04-2012
    */
    FUNCTION get_msg_tokens
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_rcm     IN pat_rcm_det.id_rcm%TYPE,
        o_tokens     OUT pk_rcm_constant.t_ibt_desc_value,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT pk_rcm_constant.t_low_char := 'GET_MSG_TOKENS';
    
        CURSOR c_pat_data(x_id_patient IN patient.id_patient%TYPE) IS
            SELECT p.name, p.id_preferred_contact_method
              FROM v_patient p
             WHERE p.id_patient = x_id_patient;
    
        CURSOR c_inst_data(x_id_institution IN institution.id_institution%TYPE) IS
            SELECT pk_translation.get_translation(i_lang, i.code_institution), i.phone_number
              FROM institution i
             WHERE i.id_institution = x_id_institution;
    BEGIN
        ----------------------
        -- INIT
        ----------------------
        g_error := 'Init ' || l_func_name || ' / i_id_patient=' || i_id_patient || ' i_id_rcm=' || i_id_rcm;
    
        -- get language message
        o_tokens(pk_rcm_constant.g_tk_lang) := pk_utils.get_institution_language(i_institution => i_prof.institution,
                                                                                 i_software    => i_prof.software);
    
        -- get patient data
        g_error := l_func_name || ': Get patient data / ID_PATIENT=' || i_id_patient;
        o_tokens(pk_rcm_constant.g_tk_id_patient) := i_id_patient;
        OPEN c_pat_data(i_id_patient);
        FETCH c_pat_data
            INTO o_tokens(pk_rcm_constant.g_tk_pat_name), o_tokens(pk_rcm_constant.g_tk_pat_contact_method);
        CLOSE c_pat_data;
    
        IF o_tokens(pk_rcm_constant.g_tk_pat_contact_method) IN
           (pk_rcm_constant.g_contact_method_sms, pk_rcm_constant.g_contact_method_email)
        THEN
            g_error  := l_func_name || ': Call pk_adt.get_main_contact / ID_PAT=' || i_id_patient ||
                        ' i_id_contact_method=' || o_tokens(pk_rcm_constant.g_tk_pat_contact_method);
            g_retval := pk_adt.get_main_contact(i_lang              => i_lang,
                                                i_prof              => i_prof,
                                                i_id_patient        => i_id_patient,
                                                i_id_contact_method => o_tokens(pk_rcm_constant.g_tk_pat_contact_method),
                                                o_contact           => o_tokens(pk_rcm_constant.g_tk_pat_contact),
                                                o_error             => o_error);
        
            -- get institution data
            g_error := l_func_name || ': get institution data / ID_INSTITUTION=' || i_prof.institution;
            OPEN c_inst_data(i_prof.institution);
            FETCH c_inst_data
                INTO o_tokens(pk_rcm_constant.g_tk_inst_name), o_tokens(pk_rcm_constant.g_tk_inst_phone);
            CLOSE c_inst_data;
        
            -- get reminder data
            g_error  := l_func_name || ': Call pk_rcm_base.get_rcm_summ / ID_RCM=' || i_id_rcm;
            g_retval := pk_rcm_base.get_rcm_summ(i_lang     => i_lang,
                                                 i_prof     => i_prof,
                                                 i_id_rcm   => i_id_rcm,
                                                 o_rcm_summ => o_tokens(pk_rcm_constant.g_tk_rcm_summ),
                                                 o_error    => o_error);
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        ELSE
            o_tokens(pk_rcm_constant.g_tk_pat_contact) := NULL;
            o_tokens(pk_rcm_constant.g_tk_inst_name) := NULL;
            o_tokens(pk_rcm_constant.g_tk_inst_phone) := NULL;
            o_tokens(pk_rcm_constant.g_tk_rcm_summ) := NULL;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            IF c_inst_data%ISOPEN
            THEN
                CLOSE c_inst_data;
            END IF;
            IF c_pat_data%ISOPEN
            THEN
                CLOSE c_pat_data;
            END IF;
            RETURN FALSE;
    END get_msg_tokens;

    /**
    * Gets template and tokens message and notifies the patient
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identifier and its context (institution and software)
    * @param   i_id_patient         Patient identifier
    * @param   i_id_rcm             Recommendation identifier
    * @param   i_id_rcm_det         Recomendation detail identifier
    * @param   o_crm_key            Transaction identifier related to the message sent to the patient
    * @param   o_flg_show           Flag indicating if o_msg is shown
    * @param   o_msg_title          Message title to be shown to the professional
    * @param   o_msg                Message to be shown to the professional
    * @param   o_button             Type of button to show with message
    * @param   o_error              Error information
    *
    * @value   o_flg_show           {*} Y - o_msg is shown {*} N - otherwise
    *
    * @return  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   05-04-2012
    */
    FUNCTION notify_patient
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_rcm     IN pat_rcm_det.id_rcm%TYPE,
        o_crm_key    OUT pat_rcm_h.crm_key%TYPE,
        o_flg_show   OUT VARCHAR2,
        o_msg_title  OUT VARCHAR2,
        o_msg        OUT VARCHAR2,
        o_button     OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT pk_rcm_constant.t_low_char := 'NOTIFY_PATIENT';
        l_tokens      pk_rcm_constant.t_ibt_desc_value;
        l_templ_value rcm_templ_crm.templ_value%TYPE;
        l_ws_response CLOB;
    BEGIN
    
        g_error    := 'Init ' || l_func_name || ' / i_id_patient=' || i_id_patient || ' i_id_rcm=' || i_id_rcm;
        o_flg_show := pk_alert_constant.g_no;
    
        -- get tokens message
        g_retval := get_msg_tokens(i_lang       => i_lang,
                                   i_prof       => i_prof,
                                   i_id_patient => i_id_patient,
                                   i_id_rcm     => i_id_rcm,
                                   o_tokens     => l_tokens,
                                   o_error      => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := l_func_name || ' Patient contact / ID_PATIENT=' || i_id_patient;
        IF l_tokens(pk_rcm_constant.g_tk_pat_contact) IS NOT NULL
        THEN
            -- notification is to be sent
        
            -- get message template
            g_error  := l_func_name || ': Call pk_rcm_base.get_rcm_templ_crm / i_id_rcm=' || i_id_rcm;
            g_retval := pk_rcm_base.get_rcm_templ_crm(i_lang              => i_lang,
                                                      i_prof              => i_prof,
                                                      i_id_rcm            => i_id_rcm,
                                                      i_id_contact_method => l_tokens(pk_rcm_constant.g_tk_pat_contact_method),
                                                      o_templ_value       => l_templ_value,
                                                      o_error             => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            l_tokens(pk_rcm_constant.g_tk_templ_value) := l_templ_value;
        
            -- send message to crm (call CRM webservice)
            g_error  := l_func_name || ': Call  pk_api_rcm_out.send_message_to_crm / i_id_patient=' || i_id_patient ||
                        ' i_id_rcm=' || i_id_rcm || ' ws_name=' || pk_rcm_constant.g_ws_execution_request;
            g_retval := pk_api_rcm_out.send_message_to_crm(i_lang        => i_lang,
                                                           i_prof        => i_prof,
                                                           i_ws_name     => pk_rcm_constant.g_ws_execution_request,
                                                           i_msg_tokens  => l_tokens,
                                                           o_ws_response => l_ws_response,
                                                           o_error       => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            -- gets crm key, returned by the webservice
            g_error  := l_func_name || ': Call pk_api_rcm_out.get_crm_key';
            g_retval := pk_api_rcm_out.get_crm_key(i_lang        => i_lang,
                                                   i_prof        => i_prof,
                                                   i_ws_response => l_ws_response,
                                                   o_crm_key     => o_crm_key,
                                                   o_error       => o_error);
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
        ELSIF l_tokens(pk_rcm_constant.g_tk_pat_contact_method) IS NULL
        THEN
            -- do not send notification: the patient has no contact method defined
            o_flg_show  := pk_alert_constant.g_yes;
            o_msg_title := pk_message.get_message(i_lang => i_lang, i_code_mess => pk_rcm_constant.g_sm_notif_t004);
            o_msg       := pk_message.get_message(i_lang => i_lang, i_code_mess => pk_rcm_constant.g_sm_notif_t001);
            o_button    := pk_rcm_constant.g_button_read;
            RETURN FALSE;
        
        ELSIF l_tokens(pk_rcm_constant.g_tk_pat_contact_method) NOT IN
              (pk_rcm_constant.g_contact_method_sms, pk_rcm_constant.g_contact_method_email)
        THEN
            -- do not send notification: the patient contact is not sms nor email
            o_flg_show  := pk_alert_constant.g_yes;
            o_msg_title := pk_message.get_message(i_lang => i_lang, i_code_mess => pk_rcm_constant.g_sm_notif_t004);
            o_msg       := pk_message.get_message(i_lang => i_lang, i_code_mess => pk_rcm_constant.g_sm_notif_t002);
            o_button    := pk_rcm_constant.g_button_read;
            RETURN FALSE;
        ELSIF l_tokens(pk_rcm_constant.g_tk_pat_contact) IS NULL
        THEN
            -- do not send notification: the patient has no contact defined
            o_flg_show  := pk_alert_constant.g_yes;
            o_msg_title := pk_message.get_message(i_lang => i_lang, i_code_mess => pk_rcm_constant.g_sm_notif_t004);
            o_msg       := pk_message.get_message(i_lang => i_lang, i_code_mess => pk_rcm_constant.g_sm_notif_t003);
            o_button    := pk_rcm_constant.g_button_read;
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END notify_patient;

    /**
    * Removes and creates sys_alert events, according to rcm states
    *
    * @param   i_lang                     Professional preferred language
    * @param   i_prof                     Professional identifier and its context (institution and software)
    * @param   i_id_patient               Patient identifier
    * @param   i_id_episode               Episode identifier
    * @param   i_id_rcm                   Recomendation identifier
    * @param   i_id_workflow              Workflow identifier
    * @param   i_id_status_old            Old recommendation status
    * @param   i_id_status_new            New recommendation status
    * @param   i_dt_status                Status change date
    * @param   o_rem_sys_alert            Alerts events that were removed
    * @param   o_add_sys_alert            Alerts events that were added
    * @param   o_error                    Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   13-02-2012
    */
    FUNCTION set_sys_alert_events
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_patient    IN patient.id_patient%TYPE,
        i_id_episode    IN episode.id_episode%TYPE,
        i_id_rcm        IN rcm.id_rcm%TYPE,
        i_id_workflow   IN pat_rcm_h.id_workflow%TYPE,
        i_id_status_old IN pat_rcm_h.id_status%TYPE,
        i_id_status_new IN pat_rcm_h.id_status%TYPE,
        i_dt_status     IN pat_rcm_h.dt_status%TYPE,
        o_rem_sys_alert OUT table_number,
        o_add_sys_alert OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT pk_rcm_constant.t_low_char := 'SET_SYS_ALERT_EVENTS';
        l_sysdate   pk_rcm_constant.t_timestamp;
        l_alert_msg sys_message.desc_message%TYPE;
    
        CURSOR c_rcm_alerts
        (
            x_id_rcm    IN rcm.id_rcm%TYPE,
            x_id_wf     IN rcm_type_workflow.id_workflow%TYPE,
            x_id_status IN rcm_type_wf_alert.id_status%TYPE
        ) IS
            SELECT rtwa.id_sys_alert, rtwa.sys_alert_message
              FROM rcm r
              JOIN rcm_type rt
                ON (r.id_rcm_type = rt.id_rcm_type)
              JOIN rcm_type_workflow rtw
                ON (rtw.id_rcm_type = rt.id_rcm_type)
              LEFT JOIN rcm_type_wf_alert rtwa
                ON (rtwa.id_rcm_type = rtw.id_rcm_type AND rtwa.id_workflow = rtw.id_workflow)
             WHERE r.id_rcm = x_id_rcm
               AND rtw.id_workflow = x_id_wf
               AND rtwa.id_status = x_id_status;
    
        l_id_sysalert_tab  table_number;
        l_sysalert_msg_tab table_varchar;
    
    BEGIN
        g_error := 'Init ' || l_func_name || ' / i_id_patient=' || i_id_patient || ' i_id_episode=' || i_id_episode ||
                   ' i_id_workflow=' || i_id_workflow;
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_sysdate       := nvl(i_dt_status, current_timestamp);
        o_rem_sys_alert := table_number();
        o_add_sys_alert := table_number();
    
        -- remove sys_alert_events (related to the old state: l_rcm_data.id_status)
        g_error := l_func_name || ': Remove sys_alert events';
        OPEN c_rcm_alerts(i_id_rcm, i_id_workflow, i_id_status_old);
        FETCH c_rcm_alerts BULK COLLECT
            INTO l_id_sysalert_tab, l_sysalert_msg_tab;
        CLOSE c_rcm_alerts;
    
        FOR i IN 1 .. l_id_sysalert_tab.count
        LOOP
            g_error := l_func_name || ': Call pk_alerts.delete_sys_alert_event / i_id_episode=' || i_id_episode ||
                       ' i_id_patient=' || i_id_patient || ' i_sys_alert=' || l_id_sysalert_tab(i);
            IF NOT pk_alerts.delete_sys_alert_event(i_lang         => i_lang,
                                                    i_prof         => i_prof,
                                                    i_id_sys_alert => l_id_sysalert_tab(i),
                                                    i_id_record    => i_id_patient,
                                                    o_error        => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            o_rem_sys_alert.extend;
            o_rem_sys_alert(o_rem_sys_alert.last) := l_id_sysalert_tab(i);
        END LOOP;
    
        -- adding sys_alert events (related to the new state: l_pat_rcm_h_row.id_status)
        g_error := l_func_name || ': Add sys_alert events';
        OPEN c_rcm_alerts(i_id_rcm, i_id_workflow, i_id_status_new);
        FETCH c_rcm_alerts BULK COLLECT
            INTO l_id_sysalert_tab, l_sysalert_msg_tab;
        CLOSE c_rcm_alerts;
    
        FOR i IN 1 .. l_id_sysalert_tab.count
        LOOP
            g_error     := l_func_name || ': Call pk_message.get_message / i_code_mess=' || l_sysalert_msg_tab(i);
            l_alert_msg := pk_message.get_message(i_lang => i_lang, i_code_mess => l_sysalert_msg_tab(i));
        
            g_error  := l_func_name || ': Call pk_alerts.insert_sys_alert_event / i_id_episode=' || i_id_episode ||
                        ' i_id_patient=' || i_id_patient || ' i_sys_alert=' || l_id_sysalert_tab(i) ||
                        ' sys_alert_code_message=' || l_sysalert_msg_tab(i);
            g_retval := pk_alerts.insert_sys_alert_event(i_lang                => i_lang,
                                                         i_prof                => i_prof,
                                                         i_sys_alert           => l_id_sysalert_tab(i),
                                                         i_id_episode          => i_id_episode,
                                                         i_id_record           => i_id_patient,
                                                         i_dt_record           => l_sysdate,
                                                         i_id_professional     => NULL,
                                                         i_id_room             => NULL,
                                                         i_id_clinical_service => NULL,
                                                         i_flg_type_dest       => NULL,
                                                         i_replace1            => l_alert_msg,
                                                         i_replace2            => NULL,
                                                         o_error               => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception;
            END IF;
        
            o_add_sys_alert.extend;
            o_add_sys_alert(o_add_sys_alert.last) := l_id_sysalert_tab(i);
        
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END set_sys_alert_events;

    /**
    * Updates a patient recommendation instance
    *
    * @param   i_lang                     Professional preferred language
    * @param   i_prof                     Professional identifier and its context (institution and software)
    * @param   i_id_patient               Patient identifier
    * @param   i_id_episode               Episode identifier
    * @param   i_id_rcm                   Recommendation identifier
    * @param   i_id_rcm_det               Recomendation detail identifier
    * @param   i_id_workflow              Recomendation workflow identifier
    * @param   i_id_workflow_action       Workflow action
    * @param   i_id_status_begin          Status begin
    * @param   i_id_status_end            Status end
    * @param   i_rcm_notes                Notes related to the status change
    * @param   o_error                    Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   10-02-2012
    */
    FUNCTION set_pat_rcm_int
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_rcm             IN pat_rcm_det.id_rcm%TYPE,
        i_id_rcm_det         IN pat_rcm_det.id_rcm_det%TYPE,
        i_id_workflow        IN pat_rcm_h.id_workflow%TYPE,
        i_id_workflow_action IN wf_workflow_action.id_workflow_action%TYPE,
        i_id_status_begin    IN pat_rcm_h.id_status%TYPE,
        i_id_status_end      IN pat_rcm_h.id_status%TYPE,
        i_rcm_notes          IN pat_rcm_h.notes%TYPE,
        i_crm_key            IN pat_rcm_h.crm_key%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT pk_rcm_constant.t_low_char := 'SET_PAT_RCM_INT';
        l_pat_rcm_h_row pat_rcm_h%ROWTYPE;
        l_rem_sys_alert table_number;
        l_add_sys_alert table_number;
    BEGIN
        g_error := 'Init ' || l_func_name || ' / i_id_patient=' || i_id_patient || ' i_id_episode=' || i_id_episode ||
                   ' i_id_rcm=' || i_id_rcm || ' i_id_rcm_det=' || i_id_rcm_det || ' i_id_workflow=' || i_id_workflow ||
                   ' i_id_workflow_action=' || i_id_workflow_action || ' i_id_status_begin=' || i_id_status_begin ||
                   ' i_id_status_end=' || i_id_status_end;
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        g_sysdate := current_timestamp;
    
        -- inserting status change into recommendation detail history                 
        g_error                            := l_func_name || ': Fill l_pat_rcm_h_row';
        l_pat_rcm_h_row.id_patient         := i_id_patient;
        l_pat_rcm_h_row.id_institution     := i_prof.institution;
        l_pat_rcm_h_row.id_rcm             := i_id_rcm;
        l_pat_rcm_h_row.id_rcm_det         := i_id_rcm_det;
        l_pat_rcm_h_row.dt_status          := g_sysdate;
        l_pat_rcm_h_row.id_workflow        := i_id_workflow;
        l_pat_rcm_h_row.id_status          := i_id_status_end;
        l_pat_rcm_h_row.id_workflow_action := i_id_workflow_action;
        l_pat_rcm_h_row.id_prof_status     := i_prof.id;
        l_pat_rcm_h_row.notes              := i_rcm_notes;
        l_pat_rcm_h_row.id_epis_created    := i_id_episode;
        l_pat_rcm_h_row.crm_key            := i_crm_key;
    
        g_error := l_func_name || ': Call pk_rcm_base.ins_pat_rcm_h / id_patient=' || l_pat_rcm_h_row.id_patient ||
                   ' id_rcm=' || l_pat_rcm_h_row.id_rcm || ' id_rcm_det=' || l_pat_rcm_h_row.id_rcm_det ||
                   ' id_workflow=' || l_pat_rcm_h_row.id_workflow || ' id_status=' || l_pat_rcm_h_row.id_status ||
                   ' id_prof_status=' || l_pat_rcm_h_row.id_prof_status || ' i_id_episode=' ||
                   l_pat_rcm_h_row.id_epis_created || ' i_id_workflow_action=' || l_pat_rcm_h_row.id_workflow_action ||
                   ' id_institution=' || l_pat_rcm_h_row.id_institution || ' i_crm_key=' || l_pat_rcm_h_row.crm_key;
        pk_rcm_base.ins_pat_rcm_h(i_lang => i_lang, i_prof => i_prof, i_row => l_pat_rcm_h_row);
    
        -- remove sys_alert_events (related to the old state: l_rcm_data.id_status) and
        -- adding sys_alert events (related to the new state: l_pat_rcm_h_row.id_status)
        g_error  := l_func_name || ': Call set_sys_alert_events / i_id_patient=' || l_pat_rcm_h_row.id_patient ||
                    ' i_id_episode=' || l_pat_rcm_h_row.id_epis_created || ' i_id_rcm=' || l_pat_rcm_h_row.id_rcm ||
                    ' i_id_workflow=' || l_pat_rcm_h_row.id_workflow || ' i_id_status_new=' ||
                    l_pat_rcm_h_row.id_status;
        g_retval := set_sys_alert_events(i_lang          => i_lang,
                                         i_prof          => i_prof,
                                         i_id_patient    => l_pat_rcm_h_row.id_patient,
                                         i_id_episode    => l_pat_rcm_h_row.id_epis_created,
                                         i_id_rcm        => l_pat_rcm_h_row.id_rcm,
                                         i_id_workflow   => l_pat_rcm_h_row.id_workflow,
                                         i_id_status_old => i_id_status_begin, -- old status
                                         i_id_status_new => l_pat_rcm_h_row.id_status,
                                         i_dt_status     => l_pat_rcm_h_row.dt_status,
                                         o_rem_sys_alert => l_rem_sys_alert,
                                         o_add_sys_alert => l_add_sys_alert,
                                         o_error         => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END set_pat_rcm_int;

    /**
    * Process automatic transitions of this recommendation
    *
    * @param   i_lang                     Professional preferred language
    * @param   i_prof                     Professional identifier and its context (institution and software)
    * @param   i_id_patient               Patient identifier
    * @param   i_id_episode               Episode identifier
    * @param   i_id_rcm                   Recommendation identifier
    * @param   i_id_rcm_det               Recomendation detail identifier
    * @param   i_id_workflow              Recomendation workflow identifier
    * @param   i_id_status_begin          Status begin
    * @param   i_id_category              Professional category identifier
    * @param   i_id_profile_template      Professional profile template identifier
    * @param   i_id_functionality         Professional funcionality identifier
    * @param   i_param                    Array of parameters to be processed by workflows
    * @param   o_flg_show                 Flag indicating if o_msg is shown
    * @param   o_msg_title                Message title to be shown to the professional
    * @param   o_msg                      Message to be shown to the professional
    * @param   o_button                   Type of button to show with message
    * @param   o_error                    Error information
    *
    * @value   o_flg_show                 {*} Y - o_msg is shown {*} N - otherwise
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   20-02-2012
    */
    FUNCTION process_auto_transitions
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_patient          IN patient.id_patient%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_rcm              IN pat_rcm_det.id_rcm%TYPE,
        i_id_rcm_det          IN pat_rcm_det.id_rcm_det%TYPE,
        i_id_workflow         IN pat_rcm_h.id_workflow%TYPE,
        i_id_status_begin     IN pat_rcm_h.id_status%TYPE,
        i_id_category         IN category.id_category%TYPE,
        i_id_profile_template IN profile_template.id_profile_template%TYPE,
        i_id_functionality    IN sys_functionality.id_functionality%TYPE,
        i_param               IN table_varchar,
        o_flg_show            OUT VARCHAR2,
        o_msg_title           OUT VARCHAR2,
        o_msg                 OUT VARCHAR2,
        o_button              OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT pk_rcm_constant.t_low_char := 'PROCESS_AUTO_TRANSITIONS';
        l_id_status_begin    wf_status.id_status%TYPE;
        l_tab_transitions    t_coll_wf_transition;
        l_tab_transition_rec t_rec_wf_transition;
    BEGIN
        g_error := 'Init ' || l_func_name || ' / i_id_patient=' || i_id_patient || ' i_id_episode=' || i_id_episode ||
                   ' i_id_rcm=' || i_id_rcm || ' i_id_rcm_det=' || i_id_rcm_det || ' i_id_workflow=' || i_id_workflow ||
                   ' i_id_status_begin=' || i_id_status_begin;
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        g_sysdate := current_timestamp;
    
        l_id_status_begin := i_id_status_begin;
    
        <<rcm_transitions>>
        FOR i IN 1 .. 10
        LOOP
        
            -- getting available automatic transitions
            g_error  := 'Calling pk_workflow.get_transitions / i_id_workflow=' || i_id_workflow ||
                        ' l_id_status_begin=' || l_id_status_begin || ' i_id_category=' || i_id_category ||
                        ' i_id_profile_template=' || i_id_profile_template || ' i_id_functionality=' ||
                        i_id_functionality;
            g_retval := pk_workflow.get_transitions(i_lang                => i_lang,
                                                    i_prof                => i_prof,
                                                    i_id_workflow         => i_id_workflow,
                                                    i_id_status_begin     => l_id_status_begin,
                                                    i_id_category         => i_id_category,
                                                    i_id_profile_template => i_id_profile_template,
                                                    i_id_functionality    => i_id_functionality,
                                                    i_param               => i_param,
                                                    i_flg_auto_transition => pk_alert_constant.get_yes, -- automatic transitions only
                                                    o_transitions         => l_tab_transitions,
                                                    o_error               => o_error);
        
            IF NOT g_retval
            THEN
                g_error := 'ERROR: ' || g_error;
                RAISE g_exception_np;
            END IF;
        
            IF l_tab_transitions.count > 1
            THEN
                -- there can be only one automatic transition available
                g_error := 'There are ' || l_tab_transitions.count || ' automatic transitions available.' || g_error;
                RAISE g_exception;
            END IF;
        
            IF l_tab_transitions.count = 0
            THEN
                -- there are no automatic transitions available
                g_error := 'There are no automatic transitions available.' || g_error;
                EXIT rcm_transitions;
            END IF;
        
            l_tab_transition_rec := l_tab_transitions(1);
        
            g_error  := 'Call set_pat_rcm / i_id_patient=' || i_id_patient || ' i_id_episode=' || i_id_episode ||
                        ' i_id_rcm=' || i_id_rcm || ' i_id_rcm_det=' || i_id_rcm_det || ' i_id_workflow=' ||
                        l_tab_transition_rec.id_workflow || ' i_id_workflow_action=' ||
                        l_tab_transition_rec.id_workflow_action || ' i_id_status_begin=' ||
                        l_tab_transition_rec.id_status_begin || ' i_id_status_end=' ||
                        l_tab_transition_rec.id_status_end || ' i_id_category=' || i_id_category ||
                        ' i_id_profile_template=' || i_id_profile_template || ' i_id_functionality=' ||
                        i_id_functionality;
            g_retval := set_pat_rcm(i_lang                => i_lang,
                                    i_prof                => i_prof,
                                    i_id_patient          => i_id_patient,
                                    i_id_episode          => i_id_episode,
                                    i_id_rcm              => i_id_rcm,
                                    i_id_rcm_det          => i_id_rcm_det,
                                    i_id_workflow         => l_tab_transition_rec.id_workflow,
                                    i_id_workflow_action  => l_tab_transition_rec.id_workflow_action,
                                    i_id_status_begin     => l_tab_transition_rec.id_status_begin,
                                    i_id_status_end       => l_tab_transition_rec.id_status_end,
                                    i_rcm_notes           => NULL,
                                    i_id_category         => i_id_category,
                                    i_id_profile_template => i_id_profile_template,
                                    i_id_functionality    => i_id_functionality,
                                    i_param               => i_param,
                                    o_flg_show            => o_flg_show,
                                    o_msg_title           => o_msg_title,
                                    o_msg                 => o_msg,
                                    o_button              => o_button,
                                    o_error               => o_error);
        
            IF NOT g_retval
            THEN
                g_error := 'ERROR: ' || g_error;
                RAISE g_exception_np;
            END IF;
        
            l_id_status_begin := l_tab_transition_rec.id_status_end;
        
        END LOOP rcm_transitions;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END process_auto_transitions;

    /**
    * Inserts a new patient recommendation
    *
    * @param   i_lang                     Professional preferred language
    * @param   i_prof                     Professional identifier and its context (institution and software)
    * @param   i_id_patient_tab           Array of patient identifiers
    * @param   i_id_episode_tab           Array of episode identifiers
    * @param   i_id_rcm                   Recommendation identifier
    * @param   i_id_rcm_orig              Origin recomendation identifier
    * @param   i_id_rcm_orig_value        Origin recomendation value (cdr_instance when origin=CDS)
    * @param   i_rcm_text_tab             Array of recommendation texts
    * @param   i_rcm_notes_tab            Array of notes associated to each recommendation
    * @param   i_id_category              Professional category identifier
    * @param   i_id_profile_template      Professional profile template identifier
    * @param   i_id_functionality         Professional functionality identifier
    * @param   i_param                    Array of parameters to be processed by workflows
    * @param   o_id_rcm_det_tab           Array of recommendation details identifiers
    * @param   o_flg_show                 Flag indicating if o_msg is shown
    * @param   o_msg_title                Message title to be shown to the professional
    * @param   o_msg                      Message to be shown to the professional
    * @param   o_button                   Type of button to show with message
    * @param   o_error                    Error information
    *
    * @value   o_flg_show                 {*} Y - o_msg is shown {*} N - otherwise
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   08-02-2012
    */
    FUNCTION create_pat_rcm
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_patient_tab      IN table_number,
        i_id_episode_tab      IN table_number,
        i_id_rcm              IN pat_rcm_det.id_rcm%TYPE,
        i_id_rcm_orig         IN pat_rcm_det.id_rcm_orig%TYPE,
        i_id_rcm_orig_value   IN pat_rcm_det.id_rcm_orig_value%TYPE,
        i_rcm_text_tab        IN table_clob,
        i_rcm_notes_tab       IN table_varchar,
        i_id_category         IN category.id_category%TYPE DEFAULT NULL,
        i_id_profile_template IN profile_template.id_profile_template%TYPE DEFAULT NULL,
        i_id_functionality    IN sys_functionality.id_functionality%TYPE DEFAULT NULL,
        i_param               IN table_varchar DEFAULT table_varchar(),
        o_id_rcm_det_tab      OUT table_number,
        o_flg_show            OUT VARCHAR2,
        o_msg_title           OUT VARCHAR2,
        o_msg                 OUT VARCHAR2,
        o_button              OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT pk_rcm_constant.t_low_char := 'CREATE_PAT_RCM';
        l_pat_rcm_det_row     pat_rcm_det%ROWTYPE;
        l_pat_rcm_h_row       pat_rcm_h%ROWTYPE;
        l_rem_sys_alert       table_number;
        l_add_sys_alert       table_number;
        l_id_rcm_type         rcm_orig.id_rcm_orig%TYPE;
        l_id_category         category.id_category%TYPE;
        l_id_profile_template profile_template.id_profile_template%TYPE;
        l_id_functionality    sys_functionality.id_functionality%TYPE;
        l_param               table_varchar;
        l_rcm_notes           pat_rcm_h.notes%TYPE;
    BEGIN
        g_error := 'Init ' || l_func_name || ' / i_id_rcm=' || i_id_rcm || ' i_id_rcm_orig=' || i_id_rcm_orig ||
                   ' i_id_rcm_orig_value=' || i_id_rcm_orig_value;
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        g_sysdate        := current_timestamp;
        o_flg_show       := pk_alert_constant.g_no;
        o_id_rcm_det_tab := table_number();
        o_id_rcm_det_tab.extend(i_id_patient_tab.count);
    
        l_id_category         := nvl(i_id_category, pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof));
        l_id_profile_template := nvl(i_id_profile_template, pk_tools.get_prof_profile_template(i_prof));
        l_id_functionality    := i_id_functionality;
        l_param               := i_param;
    
        -- getting rcm type
        g_error  := l_func_name || ': Call pk_rcm_base.get_rcm_type';
        g_retval := pk_rcm_base.get_rcm_type(i_lang        => i_lang,
                                             i_prof        => i_prof,
                                             i_id_rcm      => i_id_rcm,
                                             o_id_rcm_type => l_id_rcm_type,
                                             o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- getting workflow 
        g_error  := l_func_name || ': Call pk_rcm_base.get_rcm_workflow / ID_RCM=' || i_id_rcm;
        g_retval := pk_rcm_base.get_rcm_workflow(i_lang        => i_lang,
                                                 i_prof        => i_prof,
                                                 i_id_rcm      => i_id_rcm,
                                                 o_id_workflow => l_pat_rcm_h_row.id_workflow,
                                                 o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- getting initial status
        g_error  := l_func_name || ': Call pk_rcm_base.get_rcm_workflow / ID_RCM=' || i_id_rcm;
        g_retval := pk_workflow.get_status_begin(i_lang         => i_lang,
                                                 i_prof         => i_prof,
                                                 i_id_workflow  => l_pat_rcm_h_row.id_workflow,
                                                 o_status_begin => l_pat_rcm_h_row.id_status,
                                                 o_error        => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := 'FOR i IN 1 .. ' || i_id_patient_tab.count || ' LOOP';
        FOR i IN 1 .. i_id_patient_tab.count
        LOOP
        
            -- set savepoint
            SAVEPOINT ins_pat_reminder;
        
            BEGIN
            
                -- inserting recommendation detail
                g_error                             := l_func_name || ': Fill l_pat_rcm_det_row';
                l_pat_rcm_det_row.id_patient        := i_id_patient_tab(i);
                l_pat_rcm_det_row.id_institution    := i_prof.institution;
                l_pat_rcm_det_row.id_rcm            := i_id_rcm;
                l_pat_rcm_det_row.dt_create         := g_sysdate;
                l_pat_rcm_det_row.id_rcm_orig       := i_id_rcm_orig;
                l_pat_rcm_det_row.id_rcm_orig_value := i_id_rcm_orig_value;
                l_pat_rcm_det_row.rcm_text          := i_rcm_text_tab(i);
            
                g_error := l_func_name || ': Call pk_rcm_base.ins_pat_rcm_det / id_patient=' ||
                           l_pat_rcm_det_row.id_patient || ' id_rcm=' || l_pat_rcm_det_row.id_rcm || ' id_rcm_orig=' ||
                           l_pat_rcm_det_row.id_rcm_orig || ' id_rcm_orig_value=' ||
                           l_pat_rcm_det_row.id_rcm_orig_value;
                pk_rcm_base.ins_pat_rcm_det(i_lang       => i_lang,
                                            i_prof       => i_prof,
                                            i_row        => l_pat_rcm_det_row,
                                            o_id_rcm_det => o_id_rcm_det_tab(i));
            
                -- inserting recommendation detail history
                IF i_rcm_notes_tab IS NOT NULL
                   AND i_rcm_notes_tab.exists(i)
                THEN
                    l_rcm_notes := i_rcm_notes_tab(i);
                ELSE
                    l_rcm_notes := NULL;
                END IF;
            
                g_error                         := l_func_name || ': Fill l_pat_rcm_h_row';
                l_pat_rcm_h_row.id_patient      := l_pat_rcm_det_row.id_patient;
                l_pat_rcm_h_row.id_institution  := i_prof.institution;
                l_pat_rcm_h_row.id_rcm          := l_pat_rcm_det_row.id_rcm;
                l_pat_rcm_h_row.id_rcm_det      := o_id_rcm_det_tab(i);
                l_pat_rcm_h_row.dt_status       := g_sysdate;
                l_pat_rcm_h_row.id_prof_status  := i_prof.id;
                l_pat_rcm_h_row.notes           := l_rcm_notes;
                l_pat_rcm_h_row.id_epis_created := i_id_episode_tab(i);
            
                g_error := l_func_name || ': Call pk_rcm_base.ins_pat_rcm_h / id_patient=' ||
                           l_pat_rcm_h_row.id_patient || ' id_rcm=' || l_pat_rcm_h_row.id_rcm || ' id_rcm_det=' ||
                           l_pat_rcm_h_row.id_rcm_det || ' id_workflow=' || l_pat_rcm_h_row.id_workflow ||
                           ' id_status=' || l_pat_rcm_h_row.id_status || ' id_prof_status=' ||
                           l_pat_rcm_h_row.id_prof_status || ' id_episode=' || l_pat_rcm_h_row.id_epis_created ||
                           ' id_institution=' || l_pat_rcm_h_row.id_institution;
                pk_rcm_base.ins_pat_rcm_h(i_lang => i_lang, i_prof => i_prof, i_row => l_pat_rcm_h_row);
            
                -- adding sys_alert events
                g_error  := l_func_name || ': Call set_sys_alert_events / i_id_patient=' || l_pat_rcm_h_row.id_patient ||
                            ' i_id_episode=' || l_pat_rcm_h_row.id_epis_created || ' i_id_rcm=' ||
                            l_pat_rcm_h_row.id_rcm || ' i_id_rcm=' || l_pat_rcm_h_row.id_rcm || ' i_id_workflow=' ||
                            l_pat_rcm_h_row.id_workflow || ' i_id_status_new=' || l_pat_rcm_h_row.id_status;
                g_retval := set_sys_alert_events(i_lang          => i_lang,
                                                 i_prof          => i_prof,
                                                 i_id_patient    => l_pat_rcm_h_row.id_patient,
                                                 i_id_episode    => l_pat_rcm_h_row.id_epis_created,
                                                 i_id_rcm        => l_pat_rcm_h_row.id_rcm,
                                                 i_id_workflow   => l_pat_rcm_h_row.id_workflow,
                                                 i_id_status_old => NULL, -- creating a new rcm
                                                 i_id_status_new => l_pat_rcm_h_row.id_status,
                                                 i_dt_status     => l_pat_rcm_h_row.dt_status,
                                                 o_rem_sys_alert => l_rem_sys_alert,
                                                 o_add_sys_alert => l_add_sys_alert,
                                                 o_error         => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                -- process automatic transitions
                g_error  := 'Call process_auto_transitions / i_id_patient=' || l_pat_rcm_det_row.id_patient ||
                            ' i_id_episode=' || l_pat_rcm_h_row.id_epis_created || ' i_id_rcm=' ||
                            l_pat_rcm_det_row.id_rcm || ' i_id_rcm_det=' || l_pat_rcm_h_row.id_rcm_det ||
                            ' i_id_workflow=' || l_pat_rcm_h_row.id_workflow || ' i_id_status_begin=' ||
                            l_pat_rcm_h_row.id_status;
                g_retval := process_auto_transitions(i_lang                => i_lang,
                                                     i_prof                => i_prof,
                                                     i_id_patient          => l_pat_rcm_det_row.id_patient,
                                                     i_id_episode          => l_pat_rcm_h_row.id_epis_created,
                                                     i_id_rcm              => l_pat_rcm_det_row.id_rcm,
                                                     i_id_rcm_det          => l_pat_rcm_h_row.id_rcm_det,
                                                     i_id_workflow         => l_pat_rcm_h_row.id_workflow,
                                                     i_id_status_begin     => l_pat_rcm_h_row.id_status, -- from this status begin
                                                     i_id_category         => l_id_category,
                                                     i_id_profile_template => l_id_profile_template,
                                                     i_id_functionality    => l_id_functionality,
                                                     i_param               => l_param,
                                                     o_flg_show            => o_flg_show,
                                                     o_msg_title           => o_msg_title,
                                                     o_msg                 => o_msg,
                                                     o_button              => o_button,
                                                     o_error               => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            EXCEPTION
                WHEN g_exception_np THEN
                    ROLLBACK TO ins_pat_reminder;
                    pk_alertlog.log_warn(g_error);
                WHEN OTHERS THEN
                    ROLLBACK TO ins_pat_reminder;
                    pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                      i_sqlcode  => SQLCODE,
                                                      i_sqlerrm  => SQLERRM,
                                                      i_message  => g_error,
                                                      i_owner    => g_owner,
                                                      i_package  => g_package,
                                                      i_function => l_func_name,
                                                      o_error    => o_error);
            END;
        
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END create_pat_rcm;

    /**
    * Process the current status change of this recommendation
    *
    * @param   i_lang                     Professional preferred language
    * @param   i_prof                     Professional identifier and its context (institution and software)
    * @param   i_id_patient               Patient identifier
    * @param   i_id_episode               Episode identifier
    * @param   i_id_rcm                   Recommendation identifier
    * @param   i_id_rcm_det               Recomendation detail identifier
    * @param   i_id_workflow              Workflow identifier
    * @param   i_id_workflow_action       Workflow action identifier
    * @param   i_id_status_begin          Reccomendation status begin
    * @param   i_id_status_end            Reccomendation status end
    * @param   i_rcm_notes                Notes associated to this recommendation
    * @param   i_id_category              Professional category identifier
    * @param   i_id_profile_template      Professional profile template identifier
    * @param   i_id_functionality         Professional functionality identifier
    * @param   i_param                    Array of parameters to be processed by workflows
    * @param   o_flg_show                 Flag indicating if o_msg is shown
    * @param   o_msg_title                Message title to be shown to the professional
    * @param   o_msg                      Message to be shown to the professional
    * @param   o_button                   Type of button to show with message
    * @param   o_error                    Error information
    *
    * @value   o_flg_show                 {*} Y - o_msg is shown {*} N - otherwise
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   05-04-2012
    */
    FUNCTION set_pat_rcm
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_patient          IN patient.id_patient%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_rcm              IN pat_rcm_det.id_rcm%TYPE,
        i_id_rcm_det          IN pat_rcm_det.id_rcm_det%TYPE,
        i_id_workflow         IN pat_rcm_h.id_workflow%TYPE,
        i_id_workflow_action  IN wf_workflow_action.id_workflow_action%TYPE,
        i_id_status_begin     IN pat_rcm_h.id_status%TYPE,
        i_id_status_end       IN pat_rcm_h.id_status%TYPE,
        i_rcm_notes           IN pat_rcm_h.notes%TYPE,
        i_id_category         IN category.id_category%TYPE DEFAULT NULL,
        i_id_profile_template IN profile_template.id_profile_template%TYPE DEFAULT NULL,
        i_id_functionality    IN sys_functionality.id_functionality%TYPE DEFAULT NULL,
        i_param               IN table_varchar DEFAULT table_varchar(),
        o_flg_show            OUT VARCHAR2,
        o_msg_title           OUT VARCHAR2,
        o_msg                 OUT VARCHAR2,
        o_button              OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT pk_rcm_constant.t_low_char := 'SET_PAT_RCM';
        l_id_category         category.id_category%TYPE;
        l_id_profile_template profile_template.id_profile_template%TYPE;
        l_id_functionality    sys_functionality.id_functionality%TYPE;
        l_param               table_varchar;
        l_crm_key             pat_rcm_h.crm_key%TYPE;
    BEGIN
        g_error := 'Init ' || l_func_name || ' / i_id_patient=' || i_id_patient || ' i_id_episode=' || i_id_episode ||
                   ' i_id_rcm=' || i_id_rcm || ' i_id_rcm_det=' || i_id_rcm_det || ' i_id_workflow=' || i_id_workflow ||
                   ' i_id_workflow_action=' || i_id_workflow_action || ' i_id_status_begin=' || i_id_status_begin ||
                   ' i_id_status_end=' || i_id_status_end || ' i_id_category=' || i_id_category ||
                   ' i_id_profile_template=' || i_id_profile_template || ' i_id_functionality=' || i_id_functionality;
        --pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        g_sysdate  := current_timestamp;
        o_flg_show := pk_alert_constant.g_no;
    
        l_id_category         := nvl(i_id_category, pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof));
        l_id_profile_template := nvl(i_id_profile_template, pk_tools.get_prof_profile_template(i_prof));
        l_id_functionality    := i_id_functionality;
        l_param               := i_param;
    
        g_error := l_func_name || ': i_id_workflow_action=' || i_id_workflow_action;
        CASE i_id_workflow_action
            WHEN pk_rcm_constant.g_wf_action_pend_notif THEN
                -- notify patient
                g_retval := notify_patient(i_lang       => i_lang,
                                           i_prof       => i_prof,
                                           i_id_patient => i_id_patient,
                                           i_id_rcm     => i_id_rcm,
                                           o_crm_key    => l_crm_key,
                                           o_flg_show   => o_flg_show,
                                           o_msg_title  => o_msg_title,
                                           o_msg        => o_msg,
                                           o_button     => o_button,
                                           o_error      => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
            ELSE
                -- changing status only
                NULL;
        END CASE;
    
        -- sets rcm status change
        g_error  := l_func_name || ': Call set_pat_rcm_int / i_id_patient=' || i_id_patient || ' i_id_episode=' ||
                    i_id_episode || ' i_id_rcm=' || i_id_rcm || ' i_id_rcm_det=' || i_id_rcm_det || ' i_id_workflow=' ||
                    i_id_workflow || ' i_id_workflow_action=' || i_id_workflow_action || ' i_id_status_begin=' ||
                    i_id_status_begin || ' i_id_status_end=' || i_id_status_end;
        g_retval := set_pat_rcm_int(i_lang               => i_lang,
                                    i_prof               => i_prof,
                                    i_id_patient         => i_id_patient,
                                    i_id_episode         => i_id_episode,
                                    i_id_rcm             => i_id_rcm,
                                    i_id_rcm_det         => i_id_rcm_det,
                                    i_id_workflow        => i_id_workflow,
                                    i_id_workflow_action => i_id_workflow_action,
                                    i_id_status_begin    => i_id_status_begin,
                                    i_id_status_end      => i_id_status_end,
                                    i_rcm_notes          => i_rcm_notes,
                                    i_crm_key            => l_crm_key,
                                    o_error              => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- process automatic transitions
        g_error  := 'Call process_auto_transitions / i_id_patient=' || i_id_patient || ' i_id_episode=' || i_id_episode ||
                    ' i_id_rcm=' || i_id_rcm || ' i_id_rcm_det=' || i_id_rcm_det || ' i_id_workflow=' || i_id_workflow ||
                    ' i_id_status_begin=' || i_id_status_end;
        g_retval := process_auto_transitions(i_lang                => i_lang,
                                             i_prof                => i_prof,
                                             i_id_patient          => i_id_patient,
                                             i_id_episode          => i_id_episode,
                                             i_id_rcm              => i_id_rcm,
                                             i_id_rcm_det          => i_id_rcm_det,
                                             i_id_workflow         => i_id_workflow,
                                             i_id_status_begin     => i_id_status_end, -- from this status begin
                                             i_id_category         => l_id_category,
                                             i_id_profile_template => l_id_profile_template,
                                             i_id_functionality    => l_id_functionality,
                                             i_param               => l_param,
                                             o_flg_show            => o_flg_show,
                                             o_msg_title           => o_msg_title,
                                             o_msg                 => o_msg,
                                             o_button              => o_button,
                                             o_error               => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END set_pat_rcm;

    /**
    * Gets actual and historic data of this recommendation detail
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_id_patient   Patient identifier
    * @param   i_id_rcm       Recommendation identifier
    * @param   i_id_rcm_det   Recommendation detail identifier
    * @param   o_rcm_data     Recommendation info
    * @param   o_error        Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   24-04-2012
    */
    FUNCTION get_pat_rcm_det
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN pat_rcm_det.id_patient%TYPE,
        i_id_rcm     IN pat_rcm_det.id_rcm%TYPE,
        i_id_rcm_det IN pat_rcm_det.id_rcm_det%TYPE,
        o_rcm_data   OUT pk_rcm_constant.t_cur_rcm_info,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT pk_rcm_constant.t_low_char := 'GET_PAT_RCM_DET';
        l_id_category         category.id_category%TYPE;
        l_id_profile_template profile_template.id_profile_template%TYPE;
        l_id_func             sys_functionality.id_functionality%TYPE;
        l_empty_tv            table_varchar := table_varchar();
    BEGIN
        g_error := 'Init ' || l_func_name || ' / i_id_patient=' || i_id_patient || ' i_id_rcm=' || i_id_rcm ||
                   ' i_id_rcm_det=' || i_id_rcm_det;
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        l_id_category         := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
        l_id_profile_template := pk_tools.get_prof_profile_template(i_prof);
    
        OPEN o_rcm_data FOR
            SELECT tab.id_rcm,
                   tab.id_rcm_det,
                   tab.id_rcm_det_h,
                   pk_translation.get_translation(i_lang, r.code_rcm_summ) rcm_summ,
                   pk_translation.get_translation(i_lang, r.code_rcm_desc) rcm_desc,
                   (SELECT pk_translation.get_translation(i_lang, rt.code_rcm_type)
                      FROM dual) rcm_type_desc,
                   tab.id_workflow,
                   tab.id_status,
                   pk_workflow.get_status_desc(i_lang,
                                               i_prof,
                                               tab.id_workflow,
                                               tab.id_status,
                                               l_id_category,
                                               l_id_profile_template,
                                               l_id_func,
                                               l_empty_tv) status_desc,
                   tab.dt_status dt_status_tstz,
                   pk_date_utils.date_send_tsz(i_lang, tab.dt_status, i_prof) dt_status, -- format YYYYMMDDHH24MISS
                   pk_date_utils.date_char_tsz(i_lang, tab.dt_status, i_prof.institution, i_prof.software) dt_status_str, -- format to show in the application
                   pk_prof_utils.get_name_signature(i_lang, i_prof, tab.id_prof_status) prof_name_status,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, tab.id_prof_status, tab.dt_status, NULL) prof_spec_status,
                   tab.notes rcm_notes,
                   tab.rcm_text
              FROM (SELECT prh.dt_status,
                           prh.id_status,
                           prh.id_prof_status,
                           prh.notes,
                           prh.id_workflow,
                           prd.rcm_text,
                           prd.id_rcm,
                           prd.id_rcm_det,
                           prh.id_rcm_det_h
                      FROM pat_rcm_det prd
                      JOIN pat_rcm_h prh
                        ON (prd.id_patient = prh.id_patient AND prd.id_rcm = prh.id_rcm AND
                           prd.id_rcm_det = prh.id_rcm_det AND prd.id_institution = prh.id_institution)
                     WHERE prd.id_patient = i_id_patient
                       AND prd.id_institution = i_prof.institution
                       AND prd.id_rcm = i_id_rcm
                       AND prd.id_rcm_det = i_id_rcm_det) tab
              JOIN rcm r
                ON (r.id_rcm = tab.id_rcm)
              JOIN rcm_type rt
                ON (rt.id_rcm_type = r.id_rcm_type)
             ORDER BY tab.dt_status DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_rcm_data);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_pat_rcm_det;

    /**
    * Get value of chr_val (Recommendations Property )
    *
    * @param  i_id_rcm          Recommendation identifier
    * @param  i_prop            Property identifier
    *
    * @return  Varchar
    * @author  Joana Barroso
    * @version 1.0
    * @since   09-04-2012
    */
    FUNCTION get_rcm_prop_val_chr
    (
        i_rcm  IN rcm_prop.id_rcm%TYPE,
        i_prop IN rcm_prop.id_prop%TYPE
    ) RETURN rcm_prop.chr_val%TYPE IS
    
        CURSOR c_rcm_prop_val
        (
            x_rcm  rcm_prop.id_rcm%TYPE,
            x_prop rcm_prop.id_prop%TYPE
        ) IS
            SELECT chr_val
              FROM rcm_prop
             WHERE id_rcm = x_rcm
               AND id_prop = x_prop;
        l_chr_val rcm_prop.chr_val%TYPE;
    BEGIN
    
        OPEN c_rcm_prop_val(i_rcm, i_prop);
        FETCH c_rcm_prop_val
            INTO l_chr_val;
        CLOSE c_rcm_prop_val;
    
        RETURN l_chr_val;
    
    END get_rcm_prop_val_chr;

    /**
    * Get value of num_val (Recommendations Property )
    *
    * @param  i_id_rcm          Recommendation identifier
    * @param  i_prop            Property identifier
    *
    * @return  Number
    * @author  Joana Barroso
    * @version 1.0
    * @since   09-04-2012
    */

    FUNCTION get_rcm_prop_val_num
    (
        i_rcm  IN rcm_prop.id_rcm%TYPE,
        i_prop IN rcm_prop.id_prop%TYPE
    ) RETURN rcm_prop.num_val%TYPE IS
    
        CURSOR c_rcm_prop_val
        (
            x_rcm  rcm_prop.id_rcm%TYPE,
            x_prop rcm_prop.id_prop%TYPE
        ) IS
            SELECT num_val
              FROM rcm_prop
             WHERE id_rcm = x_rcm
               AND id_prop = x_prop;
        l_num_val rcm_prop.num_val%TYPE;
    BEGIN
    
        OPEN c_rcm_prop_val(i_rcm, i_prop);
        FETCH c_rcm_prop_val
            INTO l_num_val;
        CLOSE c_rcm_prop_val;
    
        RETURN l_num_val;
    
    END get_rcm_prop_val_num;

    /**
    * Get value of dte_val (Recommendations Property )
    *
    * @param  i_id_rcm          Recommendation identifier
    * @param  i_prop            Property identifier
    *
    * @return  TIMESTAMP(6) WITH LOCAL TIME ZONE
    * @author  Joana Barroso
    * @version 1.0
    * @since   09-04-2012
    */

    FUNCTION get_rcm_prop_val_dte
    (
        i_rcm  IN rcm_prop.id_rcm%TYPE,
        i_prop IN rcm_prop.id_prop%TYPE
    ) RETURN rcm_prop.dte_val%TYPE IS
    
        CURSOR c_rcm_prop_val
        (
            x_rcm  rcm_prop.id_rcm%TYPE,
            x_prop rcm_prop.id_prop%TYPE
        ) IS
            SELECT dte_val
              FROM rcm_prop
             WHERE id_rcm = x_rcm
               AND id_prop = x_prop;
        l_dte_val rcm_prop.dte_val%TYPE;
    BEGIN
    
        OPEN c_rcm_prop_val(i_rcm, i_prop);
        FETCH c_rcm_prop_val
            INTO l_dte_val;
        CLOSE c_rcm_prop_val;
        RETURN l_dte_val;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_rcm_prop_val_dte;

    /**
    * Check if is the professional configured in SYS_CONFIG with code ID_PROF_BACKGROUND
    *
    * @param   i_lang               Language associated to the professional 
    * @param   i_prof               Professional, institution and software ids
    * @param   i_workflow           Workflow identifier
    * @param   i_status_begin       Initial transition status
    * @param   i_status_end         Final transition status
    * @param   i_workflow_action    Workflow action identifier
    * @param   i_category           Category identifier
    * @param   i_profile            Profile template identifier        
    * @param   i_func               Functionality identifier
    * @param   i_param              Referral information
    *
    * @value   i_param              i_param(1)=id_external_request, i_param(2)=id_patient, i_param(3)=id_inst_orig, 
    *                               i_param(4)=id_inst_dest, i_param(5)=id_dep_clin_serv, i_param(6)=id_speciality, 
    *                               i_param(7)=flg_type, i_param(8)=decision_urg_level, i_param(9)=id_prof_requested, 
    *                               i_param(10)=id_prof_redirected, i_param(11)=id_prof_status, i_param(12)=id_external_sys, 
    *                               i_param(13)=location, i_param(14)=flg_completed, i_param(15)=action_name
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   29-05-2012
    */
    FUNCTION check_prof_background
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_workflow        IN wf_transition_config.id_workflow%TYPE,
        i_status_begin    IN wf_transition_config.id_status_begin%TYPE,
        i_status_end      IN wf_transition_config.id_status_end%TYPE,
        i_workflow_action IN wf_transition_config.id_workflow_action%TYPE,
        i_category        IN wf_transition_config.id_category%TYPE,
        i_profile         IN wf_transition_config.id_profile_template%TYPE,
        i_func            IN wf_transition_config.id_functionality%TYPE,
        i_param           IN table_varchar
    ) RETURN VARCHAR2 IS
        l_error              t_error_out;
        l_id_prof_background professional.id_professional%TYPE;
    BEGIN
        ----------------------
        -- INIT
        ----------------------
        g_error := 'Init check_prof_background / WF=' || i_workflow || ' BEG=' || i_status_begin || ' END=' ||
                   i_status_end || ' ACTION=' || i_workflow_action || ' CAT=' || i_category || ' PRF=' || i_profile ||
                   ' FUNC=' || i_func || ' PARAM=' || pk_utils.to_string(i_param);
    
        l_id_prof_background := pk_sysconfig.get_config(i_code_cf => pk_rcm_constant.g_sc_id_prof_background,
                                                        i_prof    => i_prof);
    
        IF i_prof.id = l_id_prof_background
        THEN
            RETURN pk_ref_constant.g_transition_allow;
        END IF;
    
        RETURN pk_ref_constant.g_transition_deny;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'CHECK_PROF_BACKGROUND',
                                              o_error    => l_error);
            RETURN pk_ref_constant.g_transition_deny;
    END check_prof_background;

    FUNCTION get_pat_rcm_instruct_cda
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_type_scope    IN VARCHAR2,
        i_id_scope      IN NUMBER,
        o_pat_rcm_instr OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name pk_types.t_internal_name_byte := 'GET_PAT_RCM_INSTRUCT_CDA';
    
        l_id_patient patient.id_patient%TYPE;
        l_id_episode episode.id_episode%TYPE;
        l_id_visit   visit.id_visit%TYPE;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_prof.id = ' || coalesce(to_char(i_prof.id), '<null>');
        g_error := g_error || ' i_prof.institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error := g_error || ' i_prof.software = ' || coalesce(to_char(i_prof.software), '<null>');
        g_error := g_error || ' i_type_scope = ' || coalesce(to_char(i_type_scope), '<null>');
        g_error := g_error || ' i_id_scope = ' || coalesce(to_char(i_id_scope), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        IF i_id_scope IS NULL
           OR i_type_scope IS NULL
        THEN
            g_error := 'Scope id or type is null';
            RAISE g_exception;
        END IF;
    
        g_error := 'Call pk_touch_option.get_scope_vars';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_id_scope,
                                              i_scope_type => i_type_scope,
                                              o_patient    => l_id_patient,
                                              o_visit      => l_id_visit,
                                              o_episode    => l_id_episode,
                                              o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
        g_error := 'Return pk_touch_option.get_scope_vars: ';
        g_error := g_error || ' o_patient = ' || coalesce(to_char(l_id_patient), '<null>');
        g_error := g_error || ' o_visit = ' || coalesce(to_char(l_id_visit), '<null>');
        g_error := g_error || ' o_episode = ' || coalesce(to_char(l_id_episode), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        OPEN o_pat_rcm_instr FOR
            SELECT t.id, pk_translation.get_translation(i_lang, t.code_rcm_summ) description, id_content
              FROM (SELECT tab.id_rcm_det id, r.code_rcm_summ, tab.id_patient, tab.id_institution, r.id_content
                      FROM (SELECT prd.id_rcm,
                                   prd.id_rcm_det,
                                   prd.id_patient,
                                   prd.id_institution,
                                   row_number() over(PARTITION BY prd.id_rcm, prd.id_rcm_det ORDER BY prh.dt_status DESC) my_row
                              FROM pat_rcm_det prd
                              JOIN pat_rcm_h prh
                                ON (prd.id_patient = prh.id_patient AND prd.id_rcm = prh.id_rcm AND
                                   prd.id_rcm_det = prh.id_rcm_det AND prd.id_institution = prh.id_institution)
                             INNER JOIN (SELECT DISTINCT e.id_patient, e.id_institution
                                          FROM episode e
                                         WHERE e.id_episode = l_id_episode
                                           AND e.id_patient = l_id_patient
                                           AND i_type_scope = pk_alert_constant.g_scope_type_episode
                                        UNION ALL
                                        SELECT DISTINCT e.id_patient, e.id_institution
                                          FROM episode e
                                         WHERE e.id_patient = l_id_patient
                                           AND i_type_scope = pk_alert_constant.g_scope_type_patient
                                        UNION ALL
                                        SELECT DISTINCT e.id_patient, e.id_institution
                                          FROM episode e
                                         WHERE e.id_visit = l_id_visit
                                           AND e.id_patient = l_id_patient
                                           AND i_type_scope = pk_alert_constant.g_scope_type_visit) epi
                                ON epi.id_patient = prd.id_patient
                               AND epi.id_institution = prd.id_institution) tab
                      JOIN rcm r
                        ON (r.id_rcm = tab.id_rcm)
                      JOIN rcm_type rt
                        ON (rt.id_rcm_type = r.id_rcm_type)
                     WHERE my_row = 1
                       AND r.id_rcm_type IN
                           (pk_rcm_constant.g_type_rcm_reminder, pk_rcm_constant.g_type_rcm_reminder_auto)) t;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_pat_rcm_instr);
            RETURN FALSE;
    END get_pat_rcm_instruct_cda;
BEGIN
    -- Initialization

    /* CAN'T TOUCH THIS */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_rcm_core;
/
