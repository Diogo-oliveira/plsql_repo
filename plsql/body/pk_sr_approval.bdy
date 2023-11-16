/*-- Last Change Revision: $Rev: 1850754 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2018-07-05 15:20:59 +0100 (qui, 05 jul 2018) $*/

CREATE OR REPLACE PACKAGE BODY pk_sr_approval AS

    /**************************************************************************
    * Check if the approval request can be done                               *
    *                                                                         *
    * @param i_lang                       language id                         *
    * @param i_prof                       professional, software and          *
    *                                     institution ids                     *
    * @param i_episode                    episode id                          *
    *                                                                         *
    * @param o_error                      Error message                       *
    *                                                                         *
    * @return                         Returns boolean                         *
    *                                                                         *
    * @author                         Filipe Silva                            *
    * @version                        1.0                                     *
    * @since                          2009/10/13                              *
    **************************************************************************/
    FUNCTION check_status_for_approval
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_num                   NUMBER;
        l_epis_last_templates   pk_types.cursor_type;
        l_id_epis_documentation epis_documentation.id_epis_documentation%TYPE;
        l_id_doc_template       epis_documentation.id_doc_template%TYPE;
        l_title                 pk_translation.t_desc_translation;
        l_doc_area              table_number := table_number(g_id_doc_area);
        err_exception EXCEPTION;
        l_func_name      VARCHAR(32) := 'CHECK_SEND_FOR_APPROVAL';
        l_check_director sys_config.value%TYPE;
    
    BEGIN
    
        g_error := 'CHECK IF EXISTS DIRECTOR SOFTWARE';
        pk_alertlog.log_debug(g_error);
        l_check_director := pk_sysconfig.get_config('CHECK_ALERT_DIRECTOR', i_prof);
        g_error          := 'CHECK SURGICAL PROCEDURE';
        pk_alertlog.log_debug(g_error);
        --check if in surgery description template has or not informations
    
        SELECT COUNT(*)
          INTO l_num
          FROM sr_epis_interv sei
         WHERE sei.id_episode_context = i_episode
           AND sei.flg_status != g_sr_epis_interv_status_c
           AND rownum = 1;
    
        IF l_check_director = pk_alert_constant.g_yes
        THEN
            IF l_num > 0
            THEN
                --check if in surgical procedures template has or not exist informations
                pk_alertlog.log_info(text            => 'call pk_touch_option.get_epis_last_templates_doc for the i_episode ' ||
                                                        i_episode,
                                     object_name     => pk_sr_approval.g_package_name,
                                     sub_object_name => l_func_name);
            
                IF NOT pk_touch_option.get_epis_last_templates_doc(i_lang                => i_lang,
                                                                   i_prof                => i_prof,
                                                                   i_episode             => i_episode,
                                                                   i_doc_area            => l_doc_area,
                                                                   o_epis_last_templates => l_epis_last_templates,
                                                                   o_error               => o_error)
                THEN
                    RAISE err_exception;
                END IF;
            
                --if in surgical procedures and surgery description exists informations then update the status for the surgical procedures
                -- for pending to send approval request in sr_surgery_record table
                g_error := 'FETCH CURSOR L_EPIS_LAST_TEMPLATES';
                pk_alertlog.log_debug(g_error);
                FETCH l_epis_last_templates
                    INTO l_id_epis_documentation, l_id_doc_template, l_title;
                g_found := l_epis_last_templates%FOUND;
                CLOSE l_epis_last_templates;
            
                IF g_found
                THEN
                
                    g_error := 'call pk_sr_surg_record.set_surg_process_status for id_episode: ' || i_episode;
                    pk_alertlog.log_debug(g_error);
                    IF NOT pk_sr_surg_record.set_surg_process_status(i_lang    => i_lang,
                                                                     i_prof    => i_prof,
                                                                     i_episode => i_episode,
                                                                     i_status  => g_pending_send_request,
                                                                     o_error   => o_error)
                    
                    THEN
                        RAISE err_exception;
                    END IF;
                
                ELSE
                
                    g_error := 'call pk_sr_surg_record.set_surg_process_status for id_episode: ' || i_episode;
                    pk_alertlog.log_debug(g_error);
                    IF NOT pk_sr_surg_record.set_surg_process_status(i_lang    => i_lang,
                                                                     i_prof    => i_prof,
                                                                     i_episode => i_episode,
                                                                     i_status  => g_inc_request,
                                                                     o_error   => o_error)
                    
                    THEN
                        RAISE err_exception;
                    END IF;
                
                END IF;
            
            ELSE
                g_error := 'call pk_sr_surg_record.set_surg_process_status for id_episode: ' || i_episode;
                pk_alertlog.log_debug(g_error);
                IF NOT pk_sr_surg_record.set_surg_process_status(i_lang    => i_lang,
                                                                 i_prof    => i_prof,
                                                                 i_episode => i_episode,
                                                                 i_status  => g_inc_request,
                                                                 o_error   => o_error)
                
                THEN
                    RAISE err_exception;
                END IF;
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
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END check_status_for_approval;

    /**************************************************************************
    * Returns information for the approval/reject surgery pop-up              *
    *                                                                         *
    * @param i_lang                       language id                         *
    * @param i_prof                       professional, software and          *
    *                                     institution ids                     *
    * @param i_episode                    episode id                          *
    *                                                                         *
    * @param o_data                   message to be display in pop-up         *
    * @param o_label                   ids labels                             *
    * @param o_error                      Error message                       *
    *                                                                         *
    * @return                         Returns boolean                         *
    *                                                                         *
    * @author                         Filipe Silva                            *
    * @version                        1.0                                     *
    * @since                          2009/10/09                              *
    **************************************************************************/
    FUNCTION get_info_for_approval
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_data    OUT pk_types.cursor_type,
        o_label   OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'OPEN CURSOR O_label';
        pk_alertlog.log_debug(g_error);
        OPEN o_label FOR
            SELECT pk_message.get_message(i_lang, column_value) AS label
              FROM (SELECT column_value
                      FROM TABLE(table_varchar('SR_LABEL_M004',
                                               'SR_LABEL_M005',
                                               'SR_LABEL_M006',
                                               'SR_LABEL_M007',
                                               'SR_LABEL_M008')));
    
        g_error := 'OPEN CURSOR O_DATA';
        pk_alertlog.log_debug(g_error);
        OPEN o_data FOR
            SELECT pk_patient.get_pat_name(i_lang, i_prof, ei.id_patient, ei.id_episode, NULL) label1,
                   pk_hea_prv_aux.get_process(i_lang, i_prof, ei.id_patient, pi.id_pat_identifier) label2,
                   (CASE
                        WHEN pk_ehr_common.get_visit_type_by_epis(i_lang,
                                                                  i_prof,
                                                                  nvl(e.id_prev_episode, e.id_episode),
                                                                  nvl(e.id_prev_epis_type, e.id_epis_type),
                                                                  ', ') IS NOT NULL THEN
                         pk_ehr_common.get_visit_name_by_epis(i_lang, i_prof, nvl(e.id_prev_epis_type, e.id_epis_type)) || ' (' ||
                         pk_ehr_common.get_visit_type_by_epis(i_lang,
                                                              i_prof,
                                                              nvl(e.id_prev_episode, e.id_episode),
                                                              nvl(e.id_prev_epis_type, e.id_epis_type),
                                                              ', ') || ')'
                        ELSE
                         pk_ehr_common.get_visit_name_by_epis(i_lang, i_prof, nvl(e.id_prev_epis_type, e.id_epis_type))
                    END) label3,
                   pk_sr_clinical_info.get_proposed_surgery(i_lang, ei.id_episode, i_prof, pk_alert_constant.g_no) label4,
                   pk_date_utils.dt_chr_date_hour(i_lang, current_timestamp, i_prof) label5
              FROM epis_info ei, pat_identifier pi, episode e
             WHERE ei.id_patient = pi.id_patient
               AND ei.id_episode = e.id_episode
               AND pi.id_institution = i_prof.institution
               AND ei.id_episode = i_episode;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_INFO_FOR_APPROVAL',
                                              o_error);
            pk_types.open_my_cursor(o_label);
            pk_types.open_my_cursor(o_data);
            RETURN FALSE;
        
    END get_info_for_approval;

    /**************************************************************************
    * send the approval request for the director                              *
    *                                                                         *
    * @param i_lang                       language id                         *
    * @param i_prof                       professional, software and          *
    *                                     institution ids                     *
    * @param i_id_episode                 id episode ORIS                     *
    * @param i_patient                    id patient                          *
    * @param i_episode                    id episode                          *
    * @param i_notes                      notes                               *
    *                                                                         *
    * @param o_error                      Error message                       *
    *                                                                         *
    * @return                         Returns boolean                         *
    *                                                                         *
    * @author                         Filipe Silva                            *
    * @version                        1.0                                     *
    * @since                          2009/10/13                              *
    **************************************************************************/
    FUNCTION send_approval_req
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE,
        i_notes      IN approval_request.notes%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name VARCHAR2(32) := 'SEND_APPROVAL_REQ';
        err_exception EXCEPTION;
        l_flg_status   ti_log.flg_status%TYPE;
        l_prev_episode episode.id_prev_episode%TYPE;
        l_status       table_varchar := table_varchar(pk_sr_approval.g_rejected_approval,
                                                      pk_sr_approval.g_pending_approval);
    
    BEGIN
    
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_sr_approval.g_package_name,
                             sub_object_name => l_func_name);
    
        l_flg_status := get_last_status_surg_proc(i_lang, i_prof, i_id_episode, l_status);
    
        --get the previous episode for the grids director clinic 
        --to know what's the origin episode (id_prev_episode)
        BEGIN
            SELECT e.id_prev_episode
              INTO l_prev_episode
              FROM episode e
             WHERE e.id_episode = i_id_episode;
        EXCEPTION
            WHEN no_data_found THEN
                l_prev_episode := NULL;
        END;
    
        IF l_flg_status IS NULL
        THEN
            BEGIN
            
                pk_alertlog.log_info(text            => 'Begin execution of pk_approval.add_approval_request_nocommit :',
                                     object_name     => pk_sr_approval.g_package_name,
                                     sub_object_name => l_func_name);
            
                pk_approval.add_approval_request_nocommit(i_lang             => i_lang,
                                                          i_prof             => i_prof,
                                                          i_id_approval_type => g_appr_type_oris,
                                                          i_id_external      => i_id_episode,
                                                          i_id_patient       => i_patient,
                                                          i_id_episode       => nvl(l_prev_episode, i_id_episode),
                                                          i_property_names   => NULL,
                                                          i_property_values  => NULL,
                                                          i_notes            => i_notes,
                                                          o_error            => o_error);
            EXCEPTION
                WHEN OTHERS THEN
                    pk_alert_exceptions.process_error(i_lang,
                                                      SQLCODE,
                                                      SQLERRM,
                                                      g_error,
                                                      g_package_owner,
                                                      g_package_name,
                                                      'PK_APPROVAL.ADD_APPROVAL_REQUEST_NOCOMMIT',
                                                      o_error);
                    RETURN FALSE;
            END;
        END IF;
    
        IF l_flg_status IN (g_rejected_approval, g_pending_approval)
        THEN
            BEGIN
                pk_alertlog.log_info(text            => 'Begin execution of pk_approval.send_appr_req_nocommit :',
                                     object_name     => pk_sr_approval.g_package_name,
                                     sub_object_name => l_func_name);
            
                pk_approval.send_appr_req_nocommit(i_lang             => i_lang,
                                                   i_prof             => i_prof,
                                                   i_id_approval_type => g_appr_type_oris,
                                                   i_id_external      => i_id_episode,
                                                   i_property_names   => NULL,
                                                   i_property_values  => NULL,
                                                   i_notes            => i_notes,
                                                   o_error            => o_error);
            
            EXCEPTION
                WHEN OTHERS THEN
                    pk_alert_exceptions.process_error(i_lang,
                                                      SQLCODE,
                                                      SQLERRM,
                                                      g_error,
                                                      g_package_owner,
                                                      g_package_name,
                                                      'PK_APPROVAL.ADD_APPROVAL_REQUEST_NOCOMMIT',
                                                      o_error);
                    RETURN FALSE;
            END;
        
        END IF;
    
        pk_alertlog.log_info(text            => 'pk_sr_surg_record.set_surg_process_status :',
                             object_name     => pk_sr_approval.g_package_name,
                             sub_object_name => l_func_name);
        IF NOT pk_sr_surg_record.set_surg_process_status(i_lang    => i_lang,
                                                         i_prof    => i_prof,
                                                         i_episode => i_id_episode,
                                                         i_status  => g_pending_approval,
                                                         o_error   => o_error)
        
        THEN
            RAISE err_exception;
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
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END send_approval_req;

    /**************************************************************************
    * return string with the surgical procedures                              *
    *                                                                         *
    * @param i_lang                       language id                         *
    * @param i_prof                       professional, software and          *
    *                                     institution ids                     *
    * @param i_episode                    id episode                          *
    *                                                                         *   
    * @return                         Returns string                          *
    *                                                                         *
    * @author                         Filipe Silva                            *
    * @version                        1.0                                     *
    * @since                          2009/10/13                              *
    **************************************************************************/
    FUNCTION get_proposed_surgery
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
    
        l_func_name VARCHAR2(32) := 'GET_PROPOSED_SURGERY';
        l_ret       VARCHAR2(4000) := NULL;
    
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_sr_approval.g_package_name,
                             sub_object_name => l_func_name);
    
        l_ret := pk_sr_clinical_info.get_proposed_surgery(i_lang, i_episode, i_prof);
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_proposed_surgery;

    /**************************************************************************
    * director approve the approval request                                   *
    *                                                                         *
    * @param i_lang                       language id                         *
    * @param i_prof                       professional, software and          *
    *                                     institution ids                     *
    * @param i_episode                    id episode ORIS                     *
    *                                                                         *
    * @param o_error                      Error message                       *
    *                                                                         *
    * @return                         Returns boolean                         *
    *                                                                         *
    * @author                         Filipe Silva                            *
    * @version                        1.0                                     *
    * @since                          2009/10/19                              *
    **************************************************************************/
    FUNCTION approve_approval_req
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
    
        l_func_name VARCHAR2(32) := 'APPROVE_APPROVAL_REQ';
        err_exception EXCEPTION;
        o_error t_error_out;
    
    BEGIN
    
        g_error := 'call pk_sr_surg_record.set_surg_process_status for id_episode: ' || i_episode;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_sr_surg_record.set_surg_process_status(i_lang    => i_lang,
                                                         i_prof    => i_prof,
                                                         i_episode => i_episode,
                                                         i_status  => g_granted_approval,
                                                         o_error   => o_error)
        
        THEN
            RAISE err_exception;
        END IF;
    
        RETURN pk_alert_constant.g_yes;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN pk_alert_constant.g_no;
    END approve_approval_req;

    /**************************************************************************
    * director reject the approval request                                    *
    *                                                                         *
    * @param i_lang                       language id                         *
    * @param i_prof                       professional, software and          *
    *                                     institution ids                     *
    * @param i_episode                    id episode ORIS                     *
    *                                                                         *
    * @param o_error                      Error message                       *
    *                                                                         *
    * @return                         Returns boolean                         *
    *                                                                         *
    * @author                         Filipe Silva                            *
    * @version                        1.0                                     *
    * @since                          2009/10/19                              *
    **************************************************************************/
    FUNCTION reject_approval_req
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
    
        l_func_name VARCHAR2(32) := 'REJECT_APPROVAL_REQ';
        err_exception EXCEPTION;
        o_error t_error_out;
    
    BEGIN
    
        g_error := 'call pk_sr_surg_record.set_surg_process_status for id_episode: ' || i_episode;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_sr_surg_record.set_surg_process_status(i_lang    => i_lang,
                                                         i_prof    => i_prof,
                                                         i_episode => i_episode,
                                                         i_status  => g_rejected_approval,
                                                         o_error   => o_error)
        
        THEN
            RAISE err_exception;
        END IF;
    
        RETURN pk_alert_constant.g_yes;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN pk_alert_constant.g_no;
    END reject_approval_req;

    /********************************************************************************************
    * if the surgical process is edited then check if the consent is assign and show message to inform this.
    *
    * @param i_lang             Id language
    * @param i_prof             Professional, software and institution ids
    * @param i_episode          Identifier of the Episode
    * @param i_flg_status       Target flag status (E-Edit; C-Cancel)
    * @param o_show_msg         Flag that inform If the message is showed or not
    * @param o_msg              Messages cursor
    * @param o_error            Error Menssage
    *
    * @return                   TRUE/FALSE
    *     
    * @author                   Filipe Silva
    * @version                  1.0
    * @since                    2009/10/19
    *
    *********************************************************************************************/
    FUNCTION check_surg_process_edition
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_flg_status IN VARCHAR2,
        o_show_msg   OUT VARCHAR,
        o_msg        OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name      VARCHAR2(32) := 'CHECK_SURG_PROCESS_EDITION';
        l_flg_sr_proc    sr_surgery_record.flg_sr_proc%TYPE;
        l_flg_status     sr_consent.flg_status%TYPE;
        l_check_director sys_config.value%TYPE;
    
    BEGIN
    
        g_error := 'GET CHECK DIRECTOR';
        pk_alertlog.log_debug(g_error);
        l_check_director := pk_sysconfig.get_config('CHECK_ALERT_DIRECTOR', i_prof);
    
        BEGIN
            g_error := 'Get l_flg_status';
            pk_alertlog.log_debug(g_error);
            SELECT flg_status
              INTO l_flg_status
              FROM (SELECT sc.flg_status
                      FROM sr_consent sc, schedule_sr ss
                     WHERE sc.id_schedule_sr = ss.id_schedule_sr
                       AND ss.id_episode = i_episode
                     ORDER BY sc.dt_reg DESC)
             WHERE rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_flg_status := pk_sr_planning.g_sr_consent_status_o;
        END;
    
        g_error := 'Get l_flg_sr_proc';
        pk_alertlog.log_debug(g_error);
        BEGIN
            SELECT flg_sr_proc
              INTO l_flg_sr_proc
              FROM sr_surgery_record
             WHERE id_episode = i_episode;
        EXCEPTION
            WHEN no_data_found THEN
                l_flg_sr_proc := NULL;
        END;
    
        IF (l_flg_status = pk_sr_planning.g_sr_consent_status_a)
           OR (l_check_director = pk_alert_constant.g_yes AND l_flg_sr_proc = g_granted_approval)
        THEN
            o_show_msg := pk_alert_constant.g_yes;
            g_error    := 'Open o_msg';
            pk_alertlog.log_debug(g_error);
            OPEN o_msg FOR
                SELECT decode(i_flg_status,
                              g_flg_status_message_e,
                              pk_message.get_message(i_lang, g_msg_title_1_e),
                              g_flg_status_message_c,
                              pk_message.get_message(i_lang, g_msg_title_1_c)) title1,
                       pk_utils.to_bold(decode(i_flg_status,
                                               g_flg_status_message_e,
                                               pk_message.get_message(i_lang, g_msg_title_2_e),
                                               g_flg_status_message_c,
                                               pk_message.get_message(i_lang, g_msg_title_2_c))) title2,
                       CASE
                            WHEN (l_check_director = pk_alert_constant.g_yes AND l_flg_sr_proc = g_granted_approval) THEN
                             decode(i_flg_status,
                                    g_flg_status_message_e,
                                    pk_message.get_message(i_lang, g_msg_text_1_e),
                                    g_flg_status_message_c,
                                    pk_message.get_message(i_lang, g_msg_text_1_c))
                            ELSE
                             NULL
                        END text1,
                       CASE
                            WHEN (l_flg_status = pk_sr_planning.g_sr_consent_status_a) THEN
                             decode(i_flg_status,
                                    g_flg_status_message_e,
                                    pk_message.get_message(i_lang, g_msg_text_2_e),
                                    g_flg_status_message_c,
                                    pk_message.get_message(i_lang, g_msg_text_2_c))
                            ELSE
                             NULL
                        END text2
                  FROM dual;
        ELSE
            o_show_msg := pk_alert_constant.g_no;
            pk_types.open_my_cursor(o_msg);
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
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_msg);
            RETURN FALSE;
        
    END check_surg_process_edition;

    /**************************************************************************
       * check if the approve request can be approve or reject by the director   *
       *                                                                         *
       * @param i_lang                       language id                         *
       * @param i_prof                       professional, software and          *
       *                                     institution ids                     *
       * @param i_episode                    id_episode                          *
       * @param id_external                  id_external ( id_episode ORIS)      *
       *                                                                         *
       * @param i_dates                    table_varchar with id_doc_area and    * 
       *                                    last update date  (8|2009102110300)  *
       *                                                                         *
       * @param o_show_msg                  (Y) show message / (N) no show msg   *
       * @param o_msg                       cursor with information to show in   *
       *                                    popup                                *
       * @param o_error                      Error message                       *
       *                                                                         *
       * @return                         Returns boolean                         *
       *                                                                         *
       * @author                         Filipe Silva                            *
       * @version                        1.0                                     *
       * @since                          2009/10/21                              *
       *
    /*****************************************************************************/

    FUNCTION check_approval_to_change
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_external IN approval_request.id_external%TYPE,
        i_dates    IN table_varchar,
        o_show_msg OUT VARCHAR,
        o_msg      OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name VARCHAR2(32) := 'CHECK_APPROVAL_TO_CHANGE';
        err_exception EXCEPTION;
    
        l_id_doc_area               table_number := table_number();
        l_last_date                 VARCHAR2(30); -- epis_documentation.dt_last_update_tstz%TYPE;
        l_aux_table                 table_varchar2;
        l_last_update               pk_types.cursor_type;
        l_aux_doc_area              doc_area.id_doc_area%TYPE;
        l_interv                    pk_types.cursor_type;
        l_labels                    pk_types.cursor_type;
        l_interv_supplies           pk_types.cursor_type;
        l_interv_clinical_questions pk_types.cursor_type;
    
        l_aux_title                  sys_message.desc_message%TYPE;
        l_aux_last_update            VARCHAR2(4000);
        l_aux_nick_name              professional.name%TYPE;
        l_aux_spec                   VARCHAR2(200);
        l_aux_dt                     VARCHAR2(4000);
        l_aux_ht                     VARCHAR2(4000);
        l_aux_dt_ht                  VARCHAR2(4000);
        l_aux_epis_interv            sr_epis_interv.id_sr_epis_interv%TYPE;
        l_aux_id_sr_int              sr_epis_interv.id_sr_intervention%TYPE;
        l_aux_interv                 VARCHAR2(4000);
        l_aux_laterality             VARCHAR2(4000);
        l_aux_diagnosis              VARCHAR2(4000);
        l_aux_flg_status             VARCHAR2(2);
        l_aux_flg_request            sr_epis_interv.flg_surg_request%TYPE;
        l_aux_desc_interv            sr_epis_interv_desc.desc_interv%TYPE;
        l_aux_ordered                VARCHAR2(1);
        l_aux_ordered_date           sr_epis_interv_desc.dt_interv_desc_tstz%TYPE;
        l_aux_dt_req                 VARCHAR2(4000);
        l_id_professional            professional.id_professional%TYPE;
        l_aux_cancel_reason          sr_epis_interv.id_sr_cancel_reason%TYPE;
        l_aux_notes_cancel           sr_epis_interv.notes_cancel%TYPE;
        l_aux_supplies               VARCHAR2(4000);
        l_aux_id_diagnosis           diagnosis.id_diagnosis%TYPE;
        l_aux_notes                  sr_epis_interv.notes%TYPE;
        l_aux_epis_flg_status        episode.flg_status%TYPE;
        l_aux_code_icd               interv_codification.standard_code%TYPE;
        l_aux_flg_coding             sr_interv_codification.flg_coding%TYPE;
        l_aux_intervention           pk_translation.t_desc_translation;
        l_aux_interv_desc            pk_translation.t_desc_translation;
        l_aux_sr_epis_flg_status     sr_epis_interv.flg_status%TYPE;
        l_aux_dt_sr_start_date       episode.dt_begin_tstz%TYPE;
        l_aux_dt_sr_end_date         sr_surgery_time_det.dt_surgery_time_det_tstz%TYPE;
        l_aux_sr_epis_flg_status_str pk_translation.t_desc_translation;
        l_aux_flg_type_desc          pk_translation.t_desc_translation;
        l_aux_flg_type               sr_epis_interv.flg_type%TYPE;
        l_aux_team                   pk_translation.t_desc_translation;
        l_aux_desc_team              pk_translation.t_desc_translation;
        l_aux_sr_start_date          pk_translation.t_desc_translation;
        l_aux_sr_start_date_str      pk_translation.t_desc_translation;
        l_aux_sr_end_date            pk_translation.t_desc_translation;
        l_aux_sr_end_date_str        pk_translation.t_desc_translation;
    
        CURSOR c_get_recs IS
            SELECT *
              FROM TABLE(i_dates);
    
        PROCEDURE init_vars
        (
            i_aux_title         IN OUT sys_message.desc_message%TYPE,
            i_aux_last_update   IN OUT VARCHAR,
            i_aux_nick_name     IN OUT professional.name%TYPE,
            i_aux_spec          IN OUT VARCHAR,
            i_aux_dt            IN OUT VARCHAR,
            i_aux_ht            IN OUT VARCHAR,
            i_aux_epis_interv   IN OUT sr_epis_interv.id_sr_epis_interv%TYPE,
            i_aux_id_sr_int     IN OUT sr_epis_interv.id_sr_intervention%TYPE,
            i_aux_interv        IN OUT VARCHAR,
            i_aux_laterality    IN OUT VARCHAR,
            i_aux_diagnosis     IN OUT VARCHAR,
            i_aux_flg_status    IN OUT VARCHAR,
            i_aux_flg_request   IN OUT sr_epis_interv.flg_surg_request%TYPE,
            i_aux_desc_interv   IN OUT sr_epis_interv_desc.desc_interv%TYPE,
            i_aux_ordered       IN OUT VARCHAR,
            i_aux_ordered_date  IN OUT sr_epis_interv_desc.dt_interv_desc_tstz%TYPE,
            i_aux_doc_area      IN OUT doc_area.id_doc_area%TYPE,
            i_id_doc_area       IN OUT table_number,
            i_last_date         IN OUT VARCHAR,
            i_aux_dt_req        IN OUT VARCHAR2,
            i_aux_id_prof       IN OUT professional.id_professional%TYPE,
            i_aux_cancel_reason IN OUT sr_epis_interv.id_sr_cancel_reason%TYPE,
            i_aux_notes_cancel  IN OUT sr_epis_interv.notes_cancel%TYPE,
            i_aux_supplies      IN OUT VARCHAR
            
        ) IS
        BEGIN
        
            l_aux_title                  := NULL;
            l_aux_last_update            := NULL;
            l_aux_nick_name              := NULL;
            l_aux_spec                   := NULL;
            l_aux_dt                     := NULL;
            l_aux_ht                     := NULL;
            l_aux_epis_interv            := NULL;
            l_aux_id_sr_int              := NULL;
            l_aux_interv                 := NULL;
            l_aux_laterality             := NULL;
            l_aux_diagnosis              := NULL;
            l_aux_flg_status             := NULL;
            l_aux_flg_request            := NULL;
            l_aux_desc_interv            := NULL;
            l_aux_ordered                := NULL;
            l_aux_ordered_date           := NULL;
            l_aux_doc_area               := NULL;
            l_id_doc_area                := table_number();
            l_last_date                  := NULL;
            l_aux_dt_req                 := NULL;
            l_id_professional            := NULL;
            l_aux_cancel_reason          := NULL;
            l_aux_notes_cancel           := NULL;
            l_aux_supplies               := NULL;
            l_aux_id_diagnosis           := NULL;
            l_aux_notes                  := NULL;
            l_aux_epis_flg_status        := NULL;
            l_aux_code_icd               := NULL;
            l_aux_flg_coding             := NULL;
            l_aux_intervention           := NULL;
            l_aux_interv_desc            := NULL;
            l_aux_sr_epis_flg_status     := NULL;
            l_aux_dt_sr_start_date       := NULL;
            l_aux_dt_sr_end_date         := NULL;
            l_aux_sr_epis_flg_status_str := NULL;
            l_aux_flg_type_desc          := NULL;
            l_aux_flg_type               := NULL;
            l_aux_team                   := NULL;
            l_aux_desc_team              := NULL;
            l_aux_sr_start_date          := NULL;
            l_aux_sr_start_date_str      := NULL;
            l_aux_sr_end_date            := NULL;
            l_aux_sr_end_date_str        := NULL;
        END init_vars;
    
    BEGIN
    
        FOR c IN c_get_recs
        LOOP
        
            l_aux_table := pk_utils.str_split(c.column_value, '|');
            l_id_doc_area.extend;
            l_id_doc_area(l_id_doc_area.count) := to_number(l_aux_table(1));
            l_aux_doc_area := to_number(l_aux_table(1));
            --l_id_doc_area := to_number(l_aux_table(1));
            l_last_date := to_char(l_aux_table(2));
        
            IF l_aux_doc_area = g_id_doc_area
            THEN
            
                pk_alertlog.log_debug(text            => 'Call to pk_touch_option.get_epis_document_last_update for episode: ' ||
                                                         i_episode || 'and id_doc_area: ' ||
                                                         l_id_doc_area(l_id_doc_area.count),
                                      object_name     => 'PK_SR_APPROVAL',
                                      sub_object_name => 'CHECK_APPROVAL_TO_CHANGE');
            
                IF NOT pk_touch_option.get_epis_document_last_update(i_lang        => i_lang,
                                                                     i_prof        => i_prof,
                                                                     i_episode     => i_episode,
                                                                     i_doc_area    => l_id_doc_area,
                                                                     o_last_update => l_last_update,
                                                                     o_error       => o_error)
                THEN
                
                    RAISE err_exception;
                END IF;
            
                FETCH l_last_update
                    INTO l_aux_title, l_aux_last_update, l_aux_nick_name, l_aux_spec, l_aux_dt, l_aux_ht, l_aux_dt_ht;
            
                IF l_aux_last_update = l_last_date
                
                THEN
                    o_show_msg := pk_alert_constant.g_no;
                ELSE
                    o_show_msg := pk_alert_constant.g_yes;
                
                    OPEN o_msg FOR
                        SELECT pk_message.get_message(i_lang, 'SR_LABEL_M003') AS label
                          FROM dual;
                    RETURN TRUE;
                END IF;
            ELSE
            
                g_error := 'call pk_sr_planning.get_summ_interv for id_episode : ' || i_external;
                pk_alertlog.log_debug(g_error);
                IF NOT pk_sr_planning.get_summ_interv(i_lang                      => i_lang,
                                                      i_prof                      => i_prof,
                                                      i_episode                   => i_external,
                                                      o_interv                    => l_interv,
                                                      o_labels                    => l_labels,
                                                      o_interv_supplies           => l_interv_supplies,
                                                      o_interv_clinical_questions => l_interv_clinical_questions,
                                                      o_error                     => o_error)
                THEN
                    RAISE err_exception;
                END IF;
            
                g_error := 'FETCH l_interv';
                pk_alertlog.log_debug(g_error);
                FETCH l_interv
                    INTO l_aux_epis_interv,
                         l_aux_id_sr_int,
                         l_aux_interv,
                         l_aux_laterality,
                         l_aux_diagnosis,
                         l_aux_id_diagnosis,
                         l_aux_notes,
                         l_aux_flg_status,
                         l_aux_flg_request,
                         l_aux_dt,
                         l_aux_dt_req,
                         l_aux_nick_name,
                         l_aux_spec,
                         l_aux_desc_interv,
                         l_aux_ordered,
                         l_aux_ordered_date,
                         l_id_professional,
                         l_aux_cancel_reason,
                         l_aux_notes_cancel,
                         l_aux_supplies,
                         l_aux_epis_flg_status,
                         l_aux_code_icd,
                         l_aux_flg_coding,
                         l_aux_intervention,
                         l_aux_interv_desc,
                         l_aux_sr_epis_flg_status,
                         l_aux_dt_sr_start_date,
                         l_aux_dt_sr_end_date,
                         l_aux_sr_start_date,
                         l_aux_sr_start_date_str,
                         l_aux_sr_end_date,
                         l_aux_sr_end_date_str,
                         l_aux_sr_epis_flg_status_str,
                         l_aux_flg_type_desc,
                         l_aux_flg_type,
                         l_aux_team,
                         l_aux_desc_team;
                EXIT WHEN l_interv%ROWCOUNT > 1 OR l_interv%NOTFOUND;
            
                IF l_aux_dt_req = l_last_date
                
                THEN
                    o_show_msg := pk_alert_constant.g_no;
                ELSE
                    o_show_msg := pk_alert_constant.g_yes;
                
                    g_error := 'open o_msg cursor';
                    pk_alertlog.log_debug(g_error);
                    OPEN o_msg FOR
                        SELECT pk_message.get_message(i_lang, 'SR_LABEL_M003') AS label
                          FROM dual;
                
                    RETURN TRUE;
                END IF;
            
            END IF;
        
            init_vars(i_aux_title         => l_aux_title,
                      i_aux_last_update   => l_aux_last_update,
                      i_aux_nick_name     => l_aux_nick_name,
                      i_aux_spec          => l_aux_spec,
                      i_aux_dt            => l_aux_dt,
                      i_aux_ht            => l_aux_ht,
                      i_aux_epis_interv   => l_aux_epis_interv,
                      i_aux_id_sr_int     => l_aux_id_sr_int,
                      i_aux_interv        => l_aux_interv,
                      i_aux_laterality    => l_aux_laterality,
                      i_aux_diagnosis     => l_aux_diagnosis,
                      i_aux_flg_status    => l_aux_flg_status,
                      i_aux_flg_request   => l_aux_flg_request,
                      i_aux_desc_interv   => l_aux_desc_interv,
                      i_aux_ordered       => l_aux_ordered,
                      i_aux_ordered_date  => l_aux_ordered_date,
                      i_aux_doc_area      => l_aux_doc_area,
                      i_id_doc_area       => l_id_doc_area,
                      i_last_date         => l_last_date,
                      i_aux_dt_req        => l_aux_dt_req,
                      i_aux_id_prof       => l_id_professional,
                      i_aux_cancel_reason => l_aux_cancel_reason,
                      i_aux_notes_cancel  => l_aux_notes_cancel,
                      i_aux_supplies      => l_aux_supplies);
        
        END LOOP;
    
        pk_types.open_cursor_if_closed(o_msg);
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_msg);
            RETURN FALSE;
    END check_approval_to_change;

    FUNCTION get_approval_proc_pipelined
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis          IN episode.id_episode%TYPE,
        i_approval_type IN approval_request.id_approval_type%TYPE
    ) RETURN t_coll_approval_proc_resume
        PIPELINED IS
    
        rec_out t_rec_approval_proc_resume;
    
        CURSOR c_approval_resume IS
            SELECT rank() over(PARTITION BY flg_status ORDER BY dt_action) rank, t.*
              FROM (SELECT ar.flg_status,
                           ar.flg_action,
                           ar.id_prof_action,
                           ar.dt_action,
                           ar.notes,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, ar.id_prof_action) prof_name,
                           CASE
                                WHEN pk_prof_utils.get_spec_signature(i_lang, i_prof, ar.id_prof_action, NULL, NULL) IS NOT NULL THEN
                                 '(' || pk_prof_utils.get_spec_signature(i_lang, i_prof, ar.id_prof_action, NULL, NULL) || ')'
                                ELSE
                                 NULL
                            END speciality
                      FROM approval_request ar
                     WHERE ar.id_external = i_epis
                       AND ar.id_approval_type = i_approval_type
                       AND ar.flg_status IN (pk_approval.g_approval_request_approved,
                                             pk_approval.g_approval_request_pending,
                                             pk_approval.g_approval_request_rejected)
                       AND ar.flg_action IN (pk_approval.g_action_approve_approval,
                                             pk_approval.g_action_reject_approval,
                                             pk_approval.g_action_create_approval,
                                             pk_approval.g_action_update_request,
                                             pk_approval.g_action_send_request)
                    UNION ALL
                    SELECT arh.flg_status,
                           arh.flg_action,
                           arh.id_prof_action,
                           arh.dt_action,
                           arh.notes,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, arh.id_prof_action) prof_name,
                           CASE
                               WHEN pk_prof_utils.get_spec_signature(i_lang, i_prof, arh.id_prof_action, NULL, NULL) IS NOT NULL THEN
                                '(' || pk_prof_utils.get_spec_signature(i_lang, i_prof, arh.id_prof_action, NULL, NULL) || ')'
                               ELSE
                                NULL
                           END speciality
                      FROM approval_request_hist arh
                     WHERE arh.id_external = i_epis
                       AND arh.id_approval_type = i_approval_type
                       AND arh.flg_status IN (pk_approval.g_approval_request_approved,
                                              pk_approval.g_approval_request_pending,
                                              pk_approval.g_approval_request_rejected)
                       AND arh.flg_action IN (pk_approval.g_action_approve_approval,
                                              pk_approval.g_action_reject_approval,
                                              pk_approval.g_action_create_approval,
                                              pk_approval.g_action_update_request,
                                              pk_approval.g_action_send_request)) t
             ORDER BY dt_action DESC;
    
    BEGIN
        g_error := 'OPEN CURSOR c_approval_resume';
        FOR rec IN c_approval_resume
        LOOP
            rec_out := t_rec_approval_proc_resume(rec.rank,
                                                  rec.flg_status,
                                                  rec.flg_action,
                                                  rec.id_prof_action,
                                                  rec.dt_action,
                                                  rec.notes,
                                                  rec.prof_name,
                                                  rec.speciality);
            PIPE ROW(rec_out);
        END LOOP;
    
        RETURN;
    END get_approval_proc_pipelined;

    /**************************************************************************
    * Returns information to put in the Cirurgical process resume             *
    *                                                                         *
    * @param i_lang                       language id                         *
    * @param i_prof                       professional, software and          *
    *                                     institution ids                     *
    * @param i_epis                       Episode Id                          *
    * @param i_approval_type              aproval type                        *
    *                                                                         *
    * @param o_error                      Error message                       *
    * @param o_approval_resume            Cursor with process resume info     *
    *                                                                         *
    * @return                         Returns boolean                         *
    *                                                                         *
    * @author                         Gustavo Serrano                         *
    * @version                        1.0                                     *
    * @since                          2009/10/22                              *
    **************************************************************************/
    FUNCTION get_approval_process_resume
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_epis            IN episode.id_episode%TYPE,
        i_approval_type   IN approval_request.id_approval_type%TYPE,
        o_approval_resume OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        TYPE t_code_messages IS TABLE OF VARCHAR2(2000 CHAR) INDEX BY sys_message.code_message%TYPE;
    
        aa_code_messages t_code_messages;
        va_code_messages table_varchar2 := table_varchar2('SR_APPROVAL_M001',
                                                          'SR_APPROVAL_M002',
                                                          'SR_APPROVAL_M003',
                                                          'SR_APPROVAL_M004',
                                                          'SR_APPROVAL_M005');
    BEGIN
    
        -- get all messages
        g_error := 'GET MESSAGES';
        pk_alertlog.log_debug(g_error);
        FOR i IN va_code_messages.first .. va_code_messages.last
        LOOP
            aa_code_messages(va_code_messages(i)) := pk_message.get_message(i_lang, va_code_messages(i));
        END LOOP;
    
        g_error := 'OPEN o_aproval_resume';
        pk_alertlog.log_debug(g_error);
        OPEN o_approval_resume FOR
            SELECT table_varchar(pk_date_utils.dt_chr_date_hour(i_lang, t1.dt_action, i_prof),
                                 t1.prof_name,
                                 t1.speciality) left_column,
                   table_varchar(pk_utils.to_bold(decode(flg_status,
                                                         pk_approval.g_approval_request_pending,
                                                         aa_code_messages('SR_APPROVAL_M001'),
                                                         pk_approval.g_approval_request_approved,
                                                         aa_code_messages('SR_APPROVAL_M002'),
                                                         pk_approval.g_approval_request_rejected,
                                                         aa_code_messages('SR_APPROVAL_M003'))),
                                 pk_utils.to_bold(aa_code_messages('SR_APPROVAL_M005')) || ' ' || nvl(t1.notes, '---')) right_column,
                   t1.*
              FROM TABLE(get_approval_proc_pipelined(i_lang, i_prof, i_epis, i_approval_type)) t1;
    
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            pk_types.open_my_cursor(o_approval_resume);
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_APPROVAL_PROCESS_RESUME',
                                              o_error);
            pk_types.open_my_cursor(o_approval_resume);
            RETURN FALSE;
    END get_approval_process_resume;

    /**************************************************************************
    * Returns information for detail screen                                   *
    *                                                                         *
    * @param i_lang                       language id                         *
    * @param i_prof                       professional, software and          *
    *                                     institution ids                     *
    * @param i_epis                       Episode Id                          *
    * @param i_approval_type              aproval type                        *
    *                                                                         *
    * @param o_error                      Error message                       *
    * @param o_approval_resume            Cursor with process resume info     *
    *                                                                         *
    * @return                         Returns boolean                         *
    *                                                                         *
    * @author                         Gustavo Serrano                         *
    * @version                        1.0                                     *
    * @since                          2009/10/22                              *
    **************************************************************************/
    FUNCTION get_approval_proc_resume_det
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_epis            IN episode.id_episode%TYPE,
        i_approval_type   IN approval_request.id_approval_type%TYPE,
        o_approval_resume OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        TYPE t_code_messages IS TABLE OF VARCHAR2(2000 CHAR) INDEX BY sys_message.code_message%TYPE;
    
        aa_code_messages t_code_messages;
        va_code_messages table_varchar2 := table_varchar2('SR_APPROVAL_M001',
                                                          'SR_APPROVAL_M002',
                                                          'SR_APPROVAL_M003',
                                                          'SR_APPROVAL_M004',
                                                          'SR_APPROVAL_M005');
    BEGIN
    
        -- get all messages
        g_error := 'GET MESSAGES';
        pk_alertlog.log_debug(g_error);
        FOR i IN va_code_messages.first .. va_code_messages.last
        LOOP
            aa_code_messages(va_code_messages(i)) := pk_message.get_message(i_lang, va_code_messages(i));
        END LOOP;
    
        g_error := 'OPEN o_aproval_resume';
        pk_alertlog.log_debug(g_error);
        OPEN o_approval_resume FOR
            SELECT table_varchar(pk_utils.to_bold(decode(flg_status,
                                                         pk_approval.g_approval_request_pending,
                                                         aa_code_messages('SR_APPROVAL_M001'),
                                                         pk_approval.g_approval_request_approved,
                                                         aa_code_messages('SR_APPROVAL_M002'),
                                                         pk_approval.g_approval_request_rejected,
                                                         aa_code_messages('SR_APPROVAL_M003'))),
                                 pk_date_utils.date_char_tsz(i_lang, t1.dt_action, i_prof.institution, i_prof.software),
                                 t1.prof_name) left_column,
                   table_varchar(pk_utils.to_bold(aa_code_messages('SR_APPROVAL_M005')) || ' ' || nvl(t1.notes, '---')) right_column
              FROM TABLE(get_approval_proc_pipelined(i_lang, i_prof, i_epis, i_approval_type)) t1;
    
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            pk_types.open_my_cursor(o_approval_resume);
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_APPROVAL_PROC_RESUME_DET',
                                              o_error);
            pk_types.open_my_cursor(o_approval_resume);
            RETURN FALSE;
    END get_approval_proc_resume_det;

    /**************************************************************************
    * director dummy cancel the approval request                              *
    *                                                                         *
    * @param i_lang                       language id                         *
    * @param i_prof                       professional, software and          *
    *                                     institution ids                     *
    * @param i_episode                    id episode ORIS                     *
    *                                                                         *
    * @param o_error                      Error message                       *
    *                                                                         *
    * @return                         Returns boolean                         *
    *                                                                         *
    * @author                         Filipe Silva                            *
    * @version                        1.0                                     *
    * @since                          2009/10/19                              *
    **************************************************************************/
    FUNCTION cancel_approval_req
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
    
        l_func_name VARCHAR2(32) := 'CANCEL_APPROVAL_REQ';
        err_exception EXCEPTION;
        o_error t_error_out;
    
    BEGIN
    
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_sr_approval.g_package_name,
                             sub_object_name => l_func_name);
    
        RETURN pk_alert_constant.g_no;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN pk_alert_constant.g_no;
    END cancel_approval_req;

    /**************************************************************************
    * director dummy check cancel the approval request function               *
    *                                                                         *
    * @param i_lang                       language id                         *
    * @param i_prof                       professional, software and          *
    *                                     institution ids                     *
    * @param i_episode                    id episode ORIS                     *
    *                                                                         *
    * @param o_error                      Error message                       *
    *                                                                         *
    * @return                         Returns boolean                         *
    *                                                                         *
    * @author                         Filipe Silva                            *
    * @version                        1.0                                     *
    * @since                          2009/10/19                              *
    **************************************************************************/
    FUNCTION check_cancel_approval_req
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
    
        l_func_name VARCHAR2(32) := 'CHECK_CANCEL_APPROVAL_REQ';
        err_exception EXCEPTION;
        o_error t_error_out;
    
    BEGIN
    
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_sr_approval.g_package_name,
                             sub_object_name => l_func_name);
    
        RETURN pk_alert_constant.g_no;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN pk_alert_constant.g_no;
    END check_cancel_approval_req;

    /**************************************************************************
    *get the last status in ti_log                                            *
    *                                                                         *
    *                                                                         *
    * @param i_lang                       language id                         *
    * @param i_prof                       professional, software and          *
    *                                     institution ids                     *
    * @param i_episode                    id episode ORIS                     *
    * @param i_status                     list of status surgical process     *
    *                                                                         *
    * @return                         Returns the last status                 *
    *                                                                         *
    * @author                         Filipe Silva                            *
    * @version                        2.5.07                                  *
    * @since                          2009/10/27                              *
    **************************************************************************/
    FUNCTION get_last_status_surg_proc
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_status  IN table_varchar
    ) RETURN VARCHAR2 IS
    
        l_func_name  VARCHAR2(32) := 'GET_LAST_STATUS_SURG_PROC';
        l_flg_status ti_log.flg_status%TYPE;
    
    BEGIN
        pk_alertlog.log_info(text => 'Begin execution of:',
                             
                             object_name     => pk_sr_approval.g_package_name,
                             sub_object_name => l_func_name);
    
        BEGIN
            SELECT flg_status
              INTO l_flg_status
              FROM (SELECT ti.flg_status
                      FROM ti_log ti
                     WHERE ti.flg_type = pk_sr_surg_record.g_surgery_process_type
                       AND ti.flg_status IN (SELECT *
                                               FROM TABLE(i_status))
                       AND id_episode = i_episode
                    
                     ORDER BY dt_creation_tstz DESC)
             WHERE rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_flg_status := NULL;
        END;
    
        RETURN l_flg_status;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_last_status_surg_proc;
    /**************************************************************************
    *check status rank to check if is available to change or not the new      *
    *status                                                                   *
    *                                                                         *
    * @param i_lang                       language id                         *
    * @param i_prof                       professional, software and          *
    *                                     institution ids                     *
    * @param i_episode                    id episode ORIS                     *
    * @param i_old_status                 previous pacient status             *
    * @param i_new_status                 new pacient status                  *
    *                                                                         *
    * @param o_error                      Error message                       *
    *                                                                         *
    * @return                         Returns boolean                         *
    *                                                                         *
    * @author                         Filipe Silva                            *
    * @version                        2.5.07                                  *
    * @since                          2009/10/27                              *
    **************************************************************************/
    FUNCTION check_change_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_old_status IN sr_pat_status.flg_pat_status%TYPE,
        i_new_status IN sr_pat_status.flg_pat_status%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name  VARCHAR2(32) := 'CHECK_CHANGE_STATUS';
        l_value      VARCHAR(1);
        l_flg_status ti_log.flg_status%TYPE;
        err_exception EXCEPTION;
        l_status_proc table_varchar := table_varchar(g_inc_request,
                                                     g_pending_send_request,
                                                     g_pending_approval,
                                                     g_granted_approval,
                                                     g_rejected_approval,
                                                     g_pending);
    
    BEGIN
    
        g_error      := 'GET LAST STATUS';
        l_flg_status := get_last_status_surg_proc(i_lang, i_prof, i_episode, l_status_proc);
    
        -- change the patient status for 'Ausente' to another status.
        g_error := 'CHANGE THE PATIENT STATUS1 ';
        pk_alertlog.log_debug(g_error);
        IF i_old_status = pk_sr_grid.g_pat_status_a
        THEN
            IF i_new_status IN (pk_sr_grid.g_pat_status_w,
                                pk_sr_grid.g_pat_status_l,
                                pk_sr_grid.g_pat_status_t,
                                pk_sr_grid.g_pat_status_v,
                                pk_sr_grid.g_pat_status_p,
                                pk_sr_grid.g_pat_status_r,
                                pk_sr_grid.g_pat_status_s)
            
            THEN
                pk_alertlog.log_info(text            => 'pk_sr_surg_record.set_surg_process_status for episode: ' ||
                                                        i_episode || ' change status to: ' || g_in_surgery,
                                     object_name     => pk_sr_approval.g_package_name,
                                     sub_object_name => 'pk_sr_surg_record.set_surg_process_status');
                IF NOT pk_sr_surg_record.set_surg_process_status(i_lang    => i_lang,
                                                                 i_prof    => i_prof,
                                                                 i_episode => i_episode,
                                                                 i_status  => g_in_surgery,
                                                                 o_error   => o_error)
                
                THEN
                    RAISE err_exception;
                END IF;
            
            END IF;
        
            IF i_new_status IN (pk_sr_grid.g_pat_status_y,
                                pk_sr_grid.g_pat_status_d,
                                pk_sr_grid.g_pat_status_o,
                                pk_sr_grid.g_pat_status_f)
            THEN
                pk_alertlog.log_info(text            => 'pk_sr_surg_record.set_surg_process_status for episode: ' ||
                                                        i_episode || ' change status to: ' || g_completed_surgery,
                                     object_name     => pk_sr_approval.g_package_name,
                                     sub_object_name => 'pk_sr_surg_record.set_surg_process_status');
            
                IF NOT pk_sr_surg_record.set_surg_process_status(i_lang    => i_lang,
                                                                 i_prof    => i_prof,
                                                                 i_episode => i_episode,
                                                                 i_status  => g_completed_surgery,
                                                                 o_error   => o_error)
                
                THEN
                    RAISE err_exception;
                END IF;
            
            END IF;
        END IF;
    
        -- change the patient status for W- Em espera, L- Pedido de transporte para o bloco, T- Em transporte para o bloco, V- Acolhido no bloco, P- Em preparação,
        --  R- Preparado para a cirurgia to another status.
        g_error := 'CHANGE THE PATIENT STATUS2 ';
        pk_alertlog.log_debug(g_error);
        IF i_old_status IN (pk_sr_grid.g_pat_status_w,
                            pk_sr_grid.g_pat_status_l,
                            pk_sr_grid.g_pat_status_t,
                            pk_sr_grid.g_pat_status_v,
                            pk_sr_grid.g_pat_status_p,
                            pk_sr_grid.g_pat_status_r,
                            pk_sr_grid.g_pat_status_s)
        THEN
            IF i_new_status IN (pk_sr_grid.g_pat_status_a)
            THEN
            
                pk_alertlog.log_info(text            => 'pk_sr_surg_record.set_surg_process_status for episode: ' ||
                                                        i_episode || ' change status to: ' || l_flg_status,
                                     object_name     => pk_sr_approval.g_package_name,
                                     sub_object_name => 'pk_sr_surg_record.set_surg_process_status');
            
                IF l_flg_status IS NOT NULL
                THEN
                    IF NOT pk_sr_surg_record.set_surg_process_status(i_lang    => i_lang,
                                                                     i_prof    => i_prof,
                                                                     i_episode => i_episode,
                                                                     i_status  => l_flg_status,
                                                                     o_error   => o_error)
                    
                    THEN
                        RAISE err_exception;
                    END IF;
                
                END IF;
            END IF;
        
            IF i_new_status IN (pk_sr_grid.g_pat_status_y,
                                pk_sr_grid.g_pat_status_d,
                                pk_sr_grid.g_pat_status_o,
                                pk_sr_grid.g_pat_status_f)
            THEN
            
                pk_alertlog.log_info(text            => 'pk_sr_surg_record.set_surg_process_status for episode: ' ||
                                                        i_episode || ' change status to: ' || g_completed_surgery,
                                     object_name     => pk_sr_approval.g_package_name,
                                     sub_object_name => 'pk_sr_surg_record.set_surg_process_status');
                IF NOT pk_sr_surg_record.set_surg_process_status(i_lang    => i_lang,
                                                                 i_prof    => i_prof,
                                                                 i_episode => i_episode,
                                                                 i_status  => g_completed_surgery,
                                                                 o_error   => o_error)
                
                THEN
                    RAISE err_exception;
                END IF;
            
            END IF;
        
        END IF;
    
        -- change the patient status F- Terminou a cirurgia, Y- No recobro, D- Alta do Recobro, O- Em transporte para outro local no hospital ou noutra instituição to another status 
        g_error := 'CHANGE THE PATIENT STATUS3';
        pk_alertlog.log_debug(g_error);
        IF i_old_status IN
           (pk_sr_grid.g_pat_status_y, pk_sr_grid.g_pat_status_d, pk_sr_grid.g_pat_status_o, pk_sr_grid.g_pat_status_f)
        THEN
        
            IF i_new_status IN (pk_sr_grid.g_pat_status_a)
            THEN
            
                pk_alertlog.log_info(text            => 'pk_sr_surg_record.set_surg_process_status for episode: ' ||
                                                        i_episode || ' change status to: ' || l_flg_status,
                                     object_name     => pk_sr_approval.g_package_name,
                                     sub_object_name => 'pk_sr_surg_record.set_surg_process_status');
            
                IF l_flg_status IS NOT NULL
                THEN
                    IF NOT pk_sr_surg_record.set_surg_process_status(i_lang    => i_lang,
                                                                     i_prof    => i_prof,
                                                                     i_episode => i_episode,
                                                                     i_status  => l_flg_status,
                                                                     o_error   => o_error)
                    
                    THEN
                        RAISE err_exception;
                    END IF;
                
                END IF;
            END IF;
        
            IF i_new_status IN (pk_sr_grid.g_pat_status_w,
                                pk_sr_grid.g_pat_status_l,
                                pk_sr_grid.g_pat_status_t,
                                pk_sr_grid.g_pat_status_v,
                                pk_sr_grid.g_pat_status_p,
                                pk_sr_grid.g_pat_status_r,
                                pk_sr_grid.g_pat_status_s)
            THEN
                pk_alertlog.log_info(text            => 'pk_sr_surg_record.set_surg_process_status for episode: ' ||
                                                        i_episode || ' change status to: ' || g_in_surgery,
                                     object_name     => pk_sr_approval.g_package_name,
                                     sub_object_name => 'pk_sr_surg_record.set_surg_process_status');
                IF NOT pk_sr_surg_record.set_surg_process_status(i_lang    => i_lang,
                                                                 i_prof    => i_prof,
                                                                 i_episode => i_episode,
                                                                 i_status  => g_in_surgery,
                                                                 o_error   => o_error)
                
                THEN
                    RAISE err_exception;
                END IF;
            
            END IF;
        
        END IF;
    
        -- change the patient status 'C' - Cancelado to another status 
        g_error := 'CHANGE THE PATIENT STATUS3';
        pk_alertlog.log_debug(g_error);
        IF i_old_status IN (pk_sr_grid.g_pat_status_c)
        THEN
        
            IF i_new_status IN (pk_sr_grid.g_pat_status_a)
            THEN
            
                pk_alertlog.log_info(text            => 'pk_sr_surg_record.set_surg_process_status for episode: ' ||
                                                        i_episode || ' change status to: ' || l_flg_status,
                                     object_name     => pk_sr_approval.g_package_name,
                                     sub_object_name => 'pk_sr_surg_record.set_surg_process_status');
            
                IF l_flg_status IS NOT NULL
                THEN
                    IF NOT pk_sr_surg_record.set_surg_process_status(i_lang    => i_lang,
                                                                     i_prof    => i_prof,
                                                                     i_episode => i_episode,
                                                                     i_status  => l_flg_status,
                                                                     o_error   => o_error)
                    
                    THEN
                        RAISE err_exception;
                    END IF;
                
                END IF;
            END IF;
            IF i_new_status IN (pk_sr_grid.g_pat_status_w,
                                pk_sr_grid.g_pat_status_l,
                                pk_sr_grid.g_pat_status_t,
                                pk_sr_grid.g_pat_status_v,
                                pk_sr_grid.g_pat_status_p,
                                pk_sr_grid.g_pat_status_r,
                                pk_sr_grid.g_pat_status_s)
            THEN
                pk_alertlog.log_info(text            => 'pk_sr_surg_record.set_surg_process_status for episode: ' ||
                                                        i_episode || ' change status to: ' || g_in_surgery,
                                     object_name     => pk_sr_approval.g_package_name,
                                     sub_object_name => 'pk_sr_surg_record.set_surg_process_status');
                IF NOT pk_sr_surg_record.set_surg_process_status(i_lang    => i_lang,
                                                                 i_prof    => i_prof,
                                                                 i_episode => i_episode,
                                                                 i_status  => g_in_surgery,
                                                                 o_error   => o_error)
                
                THEN
                    RAISE err_exception;
                END IF;
            
            END IF;
        
            IF i_new_status IN (pk_sr_grid.g_pat_status_y,
                                pk_sr_grid.g_pat_status_d,
                                pk_sr_grid.g_pat_status_o,
                                pk_sr_grid.g_pat_status_f)
            THEN
            
                pk_alertlog.log_info(text            => 'pk_sr_surg_record.set_surg_process_status for episode: ' ||
                                                        i_episode || ' change status to: ' || g_completed_surgery,
                                     object_name     => pk_sr_approval.g_package_name,
                                     sub_object_name => 'pk_sr_surg_record.set_surg_process_status');
                IF NOT pk_sr_surg_record.set_surg_process_status(i_lang    => i_lang,
                                                                 i_prof    => i_prof,
                                                                 i_episode => i_episode,
                                                                 i_status  => g_completed_surgery,
                                                                 o_error   => o_error)
                
                THEN
                    RAISE err_exception;
                END IF;
            
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
                                              l_func_name,
                                              o_error);
        
            RETURN FALSE;
    END check_change_status;

    /**************************************************************************
    *get the surgery status                                                   *
    *                                                                         *
    *                                                                         *
    * @param i_lang                       language id                         *
    * @param i_prof                       professional, software and          *
    *                                     institution ids                     *
    * @param i_episode                    id episode ORIS                     *
    *                                                                         *
    * @return                         Returns the last status                 *
    *                                                                         *
    * @author                         Filipe Silva                            *
    * @version                        2.6                                     *
    * @since                          2010/03/12                              *
    **************************************************************************/
    FUNCTION get_status_surg_proc
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
    
        l_func_name   VARCHAR2(32) := 'GET_LAST_SURG_PROC';
        l_flg_sr_proc sr_surgery_record.flg_sr_proc%TYPE;
        l_flg_status  sr_surgery_record.flg_sr_proc%TYPE;
    
    BEGIN
        pk_alertlog.log_info(text => 'Begin execution of:',
                             
                             object_name     => pk_sr_approval.g_package_name,
                             sub_object_name => l_func_name);
    
        BEGIN
            SELECT ssr.flg_sr_proc
              INTO l_flg_sr_proc
              FROM sr_surgery_record ssr
             WHERE ssr.id_episode = i_episode;
        EXCEPTION
            WHEN no_data_found THEN
                l_flg_status := NULL;
        END;
    
        IF l_flg_sr_proc IN (g_pending,
                             g_inc_request,
                             g_pending_send_request,
                             g_pending_approval,
                             g_granted_approval,
                             g_rejected_approval)
        THEN
            l_flg_status := g_scheduled;
        
        ELSIF l_flg_sr_proc IN (g_in_surgery)
        THEN
            l_flg_status := g_undergoing;
        ELSIF l_flg_sr_proc IN (g_completed_surgery)
        THEN
            l_flg_status := g_done;
        ELSIF l_flg_sr_proc IN (g_cancel_surgery)
        THEN
            l_flg_status := g_cancelled;
        END IF;
    
        RETURN l_flg_status;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_status_surg_proc;

    /****************************************************************************
    * update approvals' episodes to mantain integrity during "match" operation  *
    *                                                                           *
    * @param i_lang             language id                                     *
    * @param i_prof             professional info                               *
    * @param i_episode          final episode id                                *
    * @param i_episode_temp     temporary episode id                            *
    * @param o_error            error control                                   *
    *                                                                           *
    * @return                         Returns boolean (true - succes)           *
    *                                                                           *
    * @author                         Sérgio Dias                               *
    * @version                        1.0                                       *
    * @since                          2010/07/6                                 *
    ****************************************************************************/
    FUNCTION approval_match
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_episode_temp IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name VARCHAR2(30) := 'approval_match';
    
        l_rowids_request      table_varchar;
        l_rowids_request_hist table_varchar;
    
        l_id_approval_type    approval_request.id_approval_type%TYPE;
        l_id_external         approval_request.id_external%TYPE;
        l_id_prof_req         approval_request.id_prof_req%TYPE;
        l_id_patient          approval_request.id_patient%TYPE;
        l_id_episode          approval_request.id_episode%TYPE;
        l_dt_request          approval_request.dt_request%TYPE;
        l_id_prof_resp        approval_request.id_prof_resp%TYPE;
        l_flg_status          approval_request.flg_status%TYPE;
        l_flg_action          approval_request.flg_action%TYPE;
        l_id_prof_action      approval_request.id_prof_action%TYPE;
        l_approval_properties approval_request.approval_properties%TYPE;
        l_dt_action           approval_request.dt_action%TYPE;
        l_notes               approval_request.notes%TYPE;
    
        CURSOR c_approval_request_old_row IS
            SELECT ap.id_approval_type,
                   ap.id_external,
                   ap.id_prof_req,
                   ap.id_patient,
                   ap.id_episode,
                   ap.dt_request,
                   ap.id_prof_resp,
                   ap.flg_status,
                   ap.flg_action,
                   ap.id_prof_action,
                   ap.approval_properties,
                   ap.dt_action,
                   ap.notes
              FROM approval_request ap
             WHERE ap.id_external = i_episode_temp
               AND ap.id_approval_type = g_appr_type_oris;
    
        i NUMBER;
    BEGIN
    
        -- get data from temporary episode
        g_error := 'GET c_approval_request_old_row';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
    
        OPEN c_approval_request_old_row;
        FETCH c_approval_request_old_row
            INTO l_id_approval_type,
                 l_id_external,
                 l_id_prof_req,
                 l_id_patient,
                 l_id_episode,
                 l_dt_request,
                 l_id_prof_resp,
                 l_flg_status,
                 l_flg_action,
                 l_id_prof_action,
                 l_approval_properties,
                 l_dt_action,
                 l_notes;
        CLOSE c_approval_request_old_row;
    
        l_rowids_request      := table_varchar();
        l_rowids_request_hist := table_varchar();
    
        IF l_id_external IS NOT NULL
        THEN
            -- check if final episode already has approvals
            SELECT COUNT(1)
              INTO i
              FROM approval_request ap
             WHERE ap.id_episode = i_episode;
        
            IF i > 0
            THEN
                -- if it has approvals, they must be replaced with the ones from the temporary episode
                -- delete final episode's approval history
                g_error := 'T_DATA_GOV_MNT.PROCESS_DELETE approval_request_hist by episode';
                pk_alertlog.log_debug(text            => g_error,
                                      object_name     => g_package_name,
                                      sub_object_name => l_function_name);
                ts_approval_request_hist.del_by(where_clause_in => ' id_approval_type = ' || g_appr_type_oris ||
                                                                   ' AND id_external = ' || i_episode);
            
                t_data_gov_mnt.process_delete(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'APPROVAL_REQUEST_HIST',
                                              i_rowids     => l_rowids_request,
                                              o_error      => o_error);
            
                -- delete final episode's approval
                g_error := 'T_DATA_GOV_MNT.PROCESS_DELETE approval_request by episode';
                pk_alertlog.log_debug(text            => g_error,
                                      object_name     => g_package_name,
                                      sub_object_name => l_function_name);
                ts_approval_request.del(id_approval_type_in => l_id_approval_type,
                                        id_external_in      => i_episode,
                                        rows_out            => l_rowids_request);
            
                t_data_gov_mnt.process_delete(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'APPROVAL_REQUEST',
                                              i_rowids     => l_rowids_request,
                                              o_error      => o_error);
            END IF;
            -- insert a new line with a reference to the final episode
            g_error := 'T_DATA_GOV_MNT.PROCESS_INSERT approval_request new line';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
            ts_approval_request.ins(id_approval_type_in    => l_id_approval_type,
                                    id_external_in         => i_episode, -- here is provided the final episode
                                    id_prof_req_in         => l_id_prof_req,
                                    id_patient_in          => l_id_patient,
                                    id_episode_in          => l_id_episode,
                                    dt_request_in          => l_dt_request,
                                    id_prof_resp_in        => l_id_prof_resp,
                                    flg_status_in          => l_flg_status,
                                    flg_action_in          => l_flg_action,
                                    id_prof_action_in      => l_id_prof_action,
                                    approval_properties_in => l_approval_properties,
                                    dt_action_in           => l_dt_action,
                                    notes_in               => l_notes,
                                    rows_out               => l_rowids_request);
        
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'APPROVAL_REQUEST',
                                          i_rowids     => l_rowids_request,
                                          o_error      => o_error);
        
            g_error := 'T_DATA_GOV_MNT.PROCESS_UPDATE approval_request_hist by i_episode_temp';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
            -- update history table to reference final episode
            ts_approval_request_hist.upd(id_external_in => i_episode,
                                         where_in       => ' id_approval_type = ' || g_appr_type_oris ||
                                                           ' AND id_external = ' || i_episode_temp,
                                         rows_out       => l_rowids_request_hist);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'APPROVAL_REQUEST_HIST',
                                          i_rowids     => l_rowids_request_hist,
                                          o_error      => o_error);
        
            -- delete temporary episode's approval
            g_error := 'T_DATA_GOV_MNT.PROCESS_DELETE approval_request';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
            ts_approval_request.del(id_approval_type_in => l_id_approval_type,
                                    id_external_in      => i_episode_temp,
                                    rows_out            => l_rowids_request);
        
            t_data_gov_mnt.process_delete(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'APPROVAL_REQUEST',
                                          i_rowids     => l_rowids_request,
                                          o_error      => o_error);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN TRUE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END approval_match;

BEGIN
    -- Log initialization.
    pk_alertlog.log_init(pk_alertlog.who_am_i);
END pk_sr_approval;
/
