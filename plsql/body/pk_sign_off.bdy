/*-- Last Change Revision: $Rev: 1947597 $*/
/*-- Last Change by: $Author: cristina.oliveira $*/
/*-- Date of last change: $Date: 2020-04-29 10:02:28 +0100 (qua, 29 abr 2020) $*/

CREATE OR REPLACE PACKAGE BODY pk_sign_off IS
    --generic exception
    g_generic_exception EXCEPTION;

    /** @headcom
    * Public Function. Get Sign off
    *
    * @param      I_LANG                     Identificação do Idioma
    * @param      I_PROF                     Profissional
    * @param      ID_EPISODE                 Identificação do episódio
    * @param      O_CUR                      Curosor com os dados de sign off para o respectivo episódio 
    * @param      O_ERROR                    Erro
    *
    * @return     boolean
    * @author     Eduardo Lourenco
    * @version    0.1
    * @since      2007/10/01
    */
    FUNCTION get_sign_off
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_cur        OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name         VARCHAR2(64) := 'GET_SIGN_OFF';
        l_state             epis_sign_off.flg_state%TYPE;
        l_counter_co_sign   NUMBER;
        l_sign_off_value    VARCHAR2(1);
        l_sign_off_allowed  VARCHAR2(1);
        l_co_sign_value     VARCHAR2(1);
        l_co_sign_allowed   VARCHAR2(1);
        l_co_sign_visible   VARCHAR2(1);
        l_submitted_co_sign VARCHAR2(1);
        l_title_msg         VARCHAR2(1024);
        l_id_professional   epis_sign_off.id_professional_event%TYPE;
        l_id_prof_owner     epis_sign_off.id_professional_event%TYPE;
        l_id_prof_dest      epis_sign_off.id_professional_dest%TYPE;
        l_notes             epis_sign_off.notes%TYPE;
        l_epis_type         epis_type.id_epis_type%TYPE;
    
        l_is_dicharged VARCHAR2(1) := pk_alert_constant.g_yes;
    
        l_prof_cat_type category.flg_type%TYPE;
    
        l_is_walk_in_patient VARCHAR(1 CHAR);
    BEGIN
        l_prof_cat_type := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
    
        --Check if this is a walk-in patient
        BEGIN
            SELECT decode(so.flg_sched, 'H', pk_alert_constant.g_yes, pk_alert_constant.g_no)
              INTO l_is_walk_in_patient
              FROM epis_info ei
              JOIN schedule_outp so
                ON ei.id_schedule = so.id_schedule
             WHERE ei.id_episode = i_id_episode;
        EXCEPTION
            WHEN no_data_found THEN
                l_is_walk_in_patient := pk_alert_constant.g_no;
        END;
    
        g_error := 'GET FLG_STATE';
        SELECT nvl((SELECT flg_state
                     FROM (SELECT flg_state
                             FROM epis_sign_off eso
                            WHERE eso.id_episode = i_id_episode
                            ORDER BY eso.dt_event DESC, eso.id_epis_sign_off DESC)
                    WHERE rownum <= 1),
                   g_eso_flg_state_cancel) flg_state
          INTO l_state
          FROM dual;
    
        SELECT (SELECT notes
                  FROM (SELECT eso.notes
                          FROM epis_sign_off eso
                         WHERE eso.id_episode = i_id_episode
                         ORDER BY eso.dt_event DESC, eso.id_epis_sign_off DESC)
                 WHERE rownum <= 1)
          INTO l_notes
          FROM dual;
    
        SELECT COUNT(*)
          INTO l_counter_co_sign
          FROM epis_co_signer ecs
         WHERE ecs.id_prof_owner = i_prof.id
           AND ecs.id_institution IN (i_prof.institution, 0)
           AND ecs.id_software IN (i_prof.software, 0);
    
        SELECT e.id_epis_type
          INTO l_epis_type
          FROM episode e
         WHERE e.id_episode = i_id_episode;
    
        BEGIN
            IF l_epis_type = '17'
            THEN
                --consultas de enfermagem PP
                SELECT ei.id_first_nurse_resp
                  INTO l_id_prof_owner
                  FROM epis_info ei
                 WHERE ei.id_episode = i_id_episode;
            ELSE
                IF l_is_walk_in_patient = pk_alert_constant.g_no
                THEN
                    SELECT decode(l_prof_cat_type, 'N', ei.id_first_nurse_resp, ei.id_professional)
                      INTO l_id_prof_owner
                      FROM epis_info ei
                     WHERE ei.id_episode = i_id_episode;
                ELSE
                    SELECT nvl(ei.id_professional, ei.id_first_nurse_resp)
                      INTO l_id_prof_owner
                      FROM epis_info ei
                     WHERE ei.id_episode = i_id_episode;
                END IF;
            END IF;
        EXCEPTION
            WHEN no_data_found THEN
                l_id_prof_owner := NULL;
        END;
    
        IF l_state = g_eso_flg_state_cancel
        THEN
            l_sign_off_value    := g_no;
            l_co_sign_value     := g_no;
            l_co_sign_allowed   := g_no;
            l_submitted_co_sign := g_no;
        
            IF l_id_prof_owner != i_prof.id
               OR (l_id_prof_owner IS NULL AND l_is_walk_in_patient = pk_alert_constant.g_no)
            THEN
                l_sign_off_allowed := g_no;
                l_title_msg        := pk_message.get_message(i_lang, 'SIGN_OFF_T010');
                l_id_professional  := l_id_prof_owner;
            ELSE
                l_sign_off_allowed := g_yes;
            
                IF l_counter_co_sign = 0
                THEN
                    l_co_sign_visible := g_no;
                    l_title_msg       := pk_message.get_message(i_lang, 'SIGN_OFF_T010');
                    l_id_professional := i_prof.id;
                
                ELSE
                    l_co_sign_visible := g_yes;
                    l_title_msg       := pk_message.get_message(i_lang, 'SIGN_OFF_T007');
                
                    SELECT id_prof_co_signer
                      INTO l_id_professional
                      FROM (SELECT ecs.id_prof_co_signer
                              FROM epis_co_signer ecs
                             WHERE ecs.id_prof_owner = i_prof.id
                               AND ecs.id_institution IN (i_prof.institution, 0)
                               AND ecs.id_software IN (i_prof.software, 0)
                             ORDER BY ecs.flg_default DESC)
                     WHERE rownum <= 1;
                
                END IF;
            END IF;
        
        ELSIF l_state = g_eso_flg_state_sub_cosign
        THEN
            l_sign_off_value    := g_yes;
            l_co_sign_value     := g_no;
            l_co_sign_visible   := g_yes;
            l_submitted_co_sign := g_yes;
            SELECT id_professional_dest
              INTO l_id_prof_dest
              FROM (SELECT eso.id_professional_dest
                      FROM epis_sign_off eso
                     WHERE id_episode = i_id_episode
                     ORDER BY dt_event DESC, eso.id_epis_sign_off DESC)
             WHERE rownum <= 1;
            IF i_prof.id = l_id_prof_dest
            THEN
                l_id_professional  := l_id_prof_owner;
                l_co_sign_allowed  := g_yes;
                l_sign_off_allowed := g_no;
                l_title_msg        := pk_message.get_message(i_lang, 'SIGN_OFF_T001');
            ELSIF i_prof.id = l_id_prof_owner
            THEN
                l_id_professional  := l_id_prof_dest;
                l_co_sign_allowed  := g_no;
                l_sign_off_allowed := g_yes;
                l_title_msg        := pk_message.get_message(i_lang, 'SIGN_OFF_T007');
            ELSE
                l_id_professional  := l_id_prof_dest;
                l_co_sign_allowed  := g_no;
                l_sign_off_allowed := g_no;
                l_title_msg        := pk_message.get_message(i_lang, 'SIGN_OFF_T007');
            END IF;
        
        ELSIF l_state = g_eso_flg_state_co_sign
        THEN
            SELECT id_professional_event, id_professional_dest
              INTO l_id_prof_owner, l_id_prof_dest
              FROM (SELECT eso.id_professional_event, eso.id_professional_dest
                      FROM epis_sign_off eso
                     WHERE id_episode = i_id_episode
                       AND eso.flg_state = g_eso_flg_state_sub_cosign
                     ORDER BY dt_event DESC, eso.id_epis_sign_off DESC)
             WHERE rownum <= 1;
            l_sign_off_value    := g_yes;
            l_sign_off_allowed  := g_no;
            l_co_sign_value     := g_yes;
            l_co_sign_visible   := g_yes;
            l_submitted_co_sign := g_yes;
            IF i_prof.id = l_id_prof_dest
            THEN
                l_co_sign_allowed := g_yes;
                l_id_professional := l_id_prof_owner;
                l_title_msg       := pk_message.get_message(i_lang, 'SIGN_OFF_T001');
            ELSE
                l_co_sign_allowed := g_no;
                l_id_professional := l_id_prof_dest;
                l_title_msg       := pk_message.get_message(i_lang, 'SIGN_OFF_T011');
            END IF;
        ELSIF l_state = g_eso_flg_state_sign_off
        THEN
            SELECT id_professional_event
              INTO l_id_professional
              FROM (SELECT eso.id_professional_event
                      FROM epis_sign_off eso
                     WHERE id_episode = i_id_episode
                     ORDER BY dt_event DESC, eso.id_epis_sign_off DESC)
             WHERE rownum <= 1;
            IF i_prof.id = l_id_professional
            THEN
                l_sign_off_allowed := g_yes;
            ELSE
                l_sign_off_allowed := g_no;
            END IF;
        
            l_sign_off_value    := g_yes;
            l_co_sign_value     := g_no;
            l_co_sign_allowed   := g_no;
            l_submitted_co_sign := g_no;
        
            IF l_counter_co_sign > 0
               AND l_sign_off_allowed = g_yes
            THEN
                l_co_sign_visible := g_yes;
                SELECT id_prof_co_signer
                  INTO l_id_professional
                  FROM (SELECT ecs.id_prof_co_signer
                          FROM epis_co_signer ecs
                         WHERE ecs.id_prof_owner = i_prof.id
                           AND ecs.id_institution IN (i_prof.institution, 0)
                           AND ecs.id_software IN (i_prof.software, 0)
                         ORDER BY ecs.flg_default DESC)
                 WHERE rownum <= 1;
                l_title_msg := pk_message.get_message(i_lang, 'SIGN_OFF_T011');
            ELSE
                l_co_sign_visible := g_no;
                l_title_msg       := pk_message.get_message(i_lang, 'SIGN_OFF_T010');
            END IF;
        
        END IF;
    
        --validate if the episode already have a valid discharge
        IF (i_prof.software = pk_alert_constant.g_soft_private_practice OR
           i_prof.software = pk_alert_constant.g_soft_inpatient)
        
        THEN
            IF NOT pk_discharge.get_epis_discharge_state(i_lang      => i_lang,
                                                         i_prof      => i_prof,
                                                         i_episode   => i_id_episode,
                                                         o_discharge => l_is_dicharged,
                                                         o_error     => o_error)
            THEN
                RAISE g_generic_exception;
            END IF;
        END IF;
    
        IF l_is_dicharged = pk_alert_constant.g_no
        THEN
            l_sign_off_allowed := pk_alert_constant.g_no;
        ELSIF i_prof.software <> pk_alert_constant.g_soft_private_practice
              AND i_prof.software <> pk_alert_constant.g_soft_inpatient
        THEN
            l_is_dicharged := pk_alert_constant.g_yes;
        
        END IF;
    
        g_error := 'GET_SIGN_OFF';
        OPEN o_cur FOR
            SELECT l_id_professional id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, l_id_professional) professional_name,
                   'CheckIcon' icon,
                   l_sign_off_value sign_off_value,
                   l_sign_off_allowed sign_off_allowed,
                   l_co_sign_value co_sign_value,
                   l_co_sign_allowed co_sign_allowed,
                   l_co_sign_visible co_sign_visible,
                   l_submitted_co_sign submitted_value,
                   l_notes notes,
                   l_title_msg title_msg,
                   nvl(l_is_dicharged, pk_alert_constant.g_no) is_discharged
              FROM dual;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_cur);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_sign_off;

    /** @headcom
    * Public Function. Get Sign off professionals
    *
    * @param      I_LANG                     Identificação do Idioma
    * @param      I_PROF                     Profissional
    * @param      ID_EPISODE                 Identificação do episódio
    * @param      O_CUR                      Curosor com os profissionais possíveis para escolha 
    * @param      O_ERROR                    Erro
    *
    * @return     boolean
    * @author     Eduardo Lourenco
    * @version    0.1
    * @since      2007/10/01
    */
    FUNCTION get_sign_off_professionals
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_cur        OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(64) := 'GET_SIGN_OFF_PROFESSIONALS';
    BEGIN
        g_error := 'GET_SIGN_OFF_PROFESSIONALS';
        OPEN o_cur FOR
            SELECT DISTINCT p.id_professional,
                            pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) professional_name
              FROM professional p, epis_co_signer ecs
             WHERE p.id_professional = ecs.id_prof_co_signer
               AND ecs.id_prof_owner = i_prof.id
               AND ecs.id_institution IN (i_prof.institution, 0)
               AND ecs.id_software IN (i_prof.software, 0)
               AND pk_prof_utils.is_internal_prof(i_lang, i_prof, p.id_professional, i_prof.institution) =
                   pk_alert_constant.g_yes
             ORDER BY professional_name;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_cur);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_sign_off_professionals;

    /** @headcom
    * Public Function. Get Sign off details
    *
    * @param      I_LANG                     Identificação do Idioma
    * @param      I_PROF                     Profissional
    * @param      ID_EPISODE                 Identificação do episódio
    * @param      O_CUR                      Curosor com os detalhes de sign off 
    * @param      O_ERROR                    Erro
    *
    * @return     boolean
    * @author     Eduardo Lourenco
    * @version    0.1
    * @since      2007/10/01
    */
    FUNCTION get_sign_off_details
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_cur        OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(64) := 'GET_SIGN_OFF_DETAILS';
    BEGIN
        g_error := 'GET_SIGN_OFF_DETAILS';
        OPEN o_cur FOR
            SELECT msg_title msg_title,
                   ' ' VALUE,
                   professional_name,
                   pk_date_utils.date_hour_chr_extend_tsz(i_lang, dt_event, i_prof) date_desc
              FROM (SELECT pk_sysdomain.get_domain('EPIS_SIGN_OFF.FLG_EVENT_TYPE', eso.flg_event_type, i_lang) ||
                           decode(eso.flg_event_type,
                                  g_eso_flg_event_sc,
                                  pk_prof_utils.get_name_signature(i_lang, i_prof, eso.id_professional_dest),
                                  '') msg_title,
                           pk_tools.get_prof_description(i_lang,
                                                         i_prof,
                                                         eso.id_professional_event,
                                                         eso.dt_event,
                                                         i_id_episode) professional_name,
                           eso.dt_event,
                           eso.id_epis_sign_off
                      FROM epis_sign_off eso
                     WHERE eso.id_episode = i_id_episode
                    UNION
                    SELECT pk_message.get_message(i_lang, 'SIGN_OFF_T009') || ' ' || eso.notes msg_title,
                           pk_tools.get_prof_description(i_lang,
                                                         i_prof,
                                                         eso.id_professional_event,
                                                         eso.dt_event,
                                                         i_id_episode) professional_name,
                           eso.dt_event,
                           eso.id_epis_sign_off
                      FROM epis_sign_off eso
                     WHERE eso.id_episode = i_id_episode
                       AND eso.notes IS NOT NULL)
             ORDER BY dt_event DESC, id_epis_sign_off DESC;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_cur);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_sign_off_details;

    /** @headcom
    * Public Function. Get Report details
    *
    * @param      I_LANG                     Identificação do Idioma
    * @param      I_PROF                     Profissional
    * @param      ID_EPISODE                 Identificação do episódio
    * @param      O_CUR                      Curosor com os detalhes de sign off 
    * @param      O_ERROR                    Erro
    *
    * @return     boolean
    * @author     Eduardo Lourenco
    * @version    0.1
    * @since      2008/02/25
    */
    FUNCTION get_report_details
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_cur        OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(64) := 'GET_REPORT_DETAILS';
    BEGIN
        g_error := 'GET_REPORT_DETAILS';
        OPEN o_cur FOR
            SELECT id_epis_sign_off,
                   title,
                   msg,
                   ' ' VALUE,
                   professional_name,
                   pk_date_utils.date_hour_chr_extend_tsz(i_lang, dt_event, i_prof) date_desc,
                   pk_date_utils.date_send_tsz(i_lang, dt_event, i_prof) dt_desc_report,
                   flg_cancelled
              FROM (SELECT pk_sysdomain.get_domain('EPIS_SIGN_OFF.FLG_EVENT_TYPE', eso.flg_event_type, i_lang) title,
                           decode(eso.flg_event_type,
                                  g_eso_flg_event_sc,
                                  pk_prof_utils.get_name_signature(i_lang, i_prof, eso.id_professional_dest),
                                  '') msg,
                           pk_tools.get_prof_description(i_lang,
                                                         i_prof,
                                                         eso.id_professional_event,
                                                         eso.dt_event,
                                                         i_id_episode) professional_name,
                           eso.dt_event,
                           eso.id_epis_sign_off,
                           decode(eso.flg_state, g_eso_flg_state_cancel, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_cancelled
                      FROM epis_sign_off eso
                     WHERE eso.id_episode = i_id_episode
                    UNION
                    SELECT pk_message.get_message(i_lang, 'SIGN_OFF_T009') title,
                           eso.notes msg,
                           pk_tools.get_prof_description(i_lang,
                                                         i_prof,
                                                         eso.id_professional_event,
                                                         eso.dt_event,
                                                         i_id_episode) professional_name,
                           eso.dt_event,
                           eso.id_epis_sign_off,
                           decode(eso.flg_state, g_eso_flg_state_cancel, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_cancelled
                      FROM epis_sign_off eso
                     WHERE eso.id_episode = i_id_episode
                       AND eso.notes IS NOT NULL)
             ORDER BY dt_event DESC, id_epis_sign_off DESC;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_cur);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_report_details;

    /** @headcom
    * Public Function. Set Sign off
    *
    * @param      I_LANG                     Identificação do Idioma
    * @param      I_PROF                     Profissional
    * @param      ID_EPISODE                 Identificação do episódio
    * @param      ID_PROF_CO_SIGN            Identificação do profissional responsável pelo sign-off
    * @param      I_FLG_VALUE                Flag com identificação de sign off dado pelo profissional
    * @param      I_NOTE                     Notas dadas pelo profissional
    * @param      I_FLG_CONF                 Flag de confirmação. 'Y' Continua com o processo. 'N' Verifica se existem tarefas pendentes.
    * @param      O_CUR                      Mensagem para confirmação
    * @param      O_ERROR                    Erro
    *
    * @return     boolean
    * @author     Eduardo Lourenco
    * @version    0.1
    * @since      2007/10/01
    */
    FUNCTION set_sign_off
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_prof_co_sign IN professional.id_professional%TYPE,
        i_flg_value       IN VARCHAR2,
        i_note            IN VARCHAR2,
        i_flg_conf        IN VARCHAR2,
        o_cur             OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(64) := 'SET_SIGN_OFF';
        l_flg_conf  VARCHAR2(1);
        l_counter   NUMBER;
    BEGIN
        l_flg_conf := i_flg_conf;
    
        IF l_flg_conf = g_no
           AND (i_flg_value = g_eso_flg_event_socs OR i_flg_value = g_eso_flg_event_so)
        THEN
            SELECT SUM(counter)
              INTO l_counter
              FROM (SELECT COUNT(*) counter
                      FROM analysis_req_det ard
                     WHERE ard.id_analysis_req IN (SELECT ar.id_analysis_req
                                                     FROM analysis_req ar
                                                    WHERE ar.id_episode = i_id_episode)
                       AND ard.flg_status NOT IN (g_ard_flg_status_f, g_ard_flg_status_c)
                       AND ard.flg_time_harvest = g_ard_flg_th_e
                    UNION ALL
                    SELECT COUNT(*) counter
                      FROM exam_req erd
                     WHERE erd.id_exam_req IN (SELECT er.id_exam_req
                                                 FROM exam_req er
                                                WHERE er.id_episode = i_id_episode
                                                  AND er.flg_time = g_er_flg_time_e)
                       AND erd.flg_status NOT IN (g_erd_flg_status_f, g_erd_flg_status_c));
            IF l_counter = 0
            THEN
                l_flg_conf := g_yes;
            END IF;
        ELSE
            l_flg_conf := g_yes;
        END IF;
    
        IF l_flg_conf = g_yes
        THEN
            IF (i_flg_value = g_eso_flg_event_socs)
            THEN
                RETURN set_sign_off(i_lang            => i_lang,
                                    i_prof            => i_prof,
                                    i_id_episode      => i_id_episode,
                                    i_id_prof_co_sign => i_id_prof_co_sign,
                                    i_flg_value       => g_eso_flg_event_so,
                                    i_note            => NULL,
                                    i_flg_conf        => l_flg_conf,
                                    o_cur             => o_cur,
                                    o_error           => o_error) AND set_sign_off(i_lang            => i_lang,
                                                                                   i_prof            => i_prof,
                                                                                   i_id_episode      => i_id_episode,
                                                                                   i_id_prof_co_sign => i_id_prof_co_sign,
                                                                                   i_flg_value       => g_eso_flg_event_sc,
                                                                                   i_note            => i_note,
                                                                                   i_flg_conf        => l_flg_conf,
                                                                                   o_cur             => o_cur,
                                                                                   o_error           => o_error);
            ELSIF (i_flg_value = g_eso_flg_event_csocs)
            THEN
                RETURN set_sign_off(i_lang            => i_lang,
                                    i_prof            => i_prof,
                                    i_id_episode      => i_id_episode,
                                    i_id_prof_co_sign => i_id_prof_co_sign,
                                    i_flg_value       => g_eso_flg_event_csc,
                                    i_note            => NULL,
                                    i_flg_conf        => l_flg_conf,
                                    o_cur             => o_cur,
                                    o_error           => o_error) AND set_sign_off(i_lang            => i_lang,
                                                                                   i_prof            => i_prof,
                                                                                   i_id_episode      => i_id_episode,
                                                                                   i_id_prof_co_sign => i_id_prof_co_sign,
                                                                                   i_flg_value       => g_eso_flg_event_cso,
                                                                                   i_note            => i_note,
                                                                                   i_flg_conf        => l_flg_conf,
                                                                                   o_cur             => o_cur,
                                                                                   o_error           => o_error);
            ELSE
                IF (i_flg_value IN
                   (g_eso_flg_event_csocs, g_eso_flg_event_csc, g_eso_flg_event_ccs, g_eso_flg_event_cso))
                THEN
                    UPDATE epis_sign_off eso
                       SET eso.flg_real = g_no
                     WHERE eso.id_epis_sign_off =
                           (SELECT MAX(id_epis_sign_off)
                              FROM epis_sign_off
                             WHERE id_episode = eso.id_episode
                               AND flg_event_type = decode(i_flg_value,
                                                           g_eso_flg_event_csc,
                                                           g_eso_flg_event_sc,
                                                           g_eso_flg_event_ccs,
                                                           g_eso_flg_event_cs,
                                                           g_eso_flg_event_cso,
                                                           g_eso_flg_event_so));
                
                ELSIF (i_flg_value IN (g_eso_flg_event_sc, g_eso_flg_event_cs, g_eso_flg_event_so))
                THEN
                    UPDATE epis_sign_off eso
                       SET eso.flg_real = g_no
                     WHERE eso.id_epis_sign_off = (SELECT MAX(id_epis_sign_off)
                                                     FROM epis_sign_off
                                                    WHERE id_episode = eso.id_episode
                                                      AND flg_event_type = i_flg_value);
                END IF;
                INSERT INTO epis_sign_off
                    (id_epis_sign_off,
                     id_episode,
                     id_professional_event,
                     id_professional_dest,
                     dt_event,
                     notes,
                     flg_event_type,
                     flg_state,
                     flg_real)
                VALUES
                    (seq_epis_sign_off.nextval,
                     i_id_episode,
                     i_prof.id,
                     decode(i_flg_value,
                            g_eso_flg_event_socs,
                            i_id_prof_co_sign,
                            g_eso_flg_event_ccs,
                            i_prof.id,
                            g_eso_flg_event_sc,
                            i_id_prof_co_sign,
                            NULL),
                     SYSDATE,
                     i_note,
                     i_flg_value,
                     decode(i_flg_value,
                            g_eso_flg_event_socs,
                            g_eso_flg_state_sub_cosign,
                            g_eso_flg_event_sc,
                            g_eso_flg_state_sub_cosign,
                            g_eso_flg_event_cs,
                            g_eso_flg_state_co_sign,
                            g_eso_flg_event_so,
                            g_eso_flg_state_sign_off,
                            g_eso_flg_event_csocs,
                            g_eso_flg_state_cancel,
                            g_eso_flg_event_csc,
                            g_eso_flg_state_sign_off,
                            g_eso_flg_event_ccs,
                            g_eso_flg_state_sub_cosign,
                            g_eso_flg_event_cso,
                            g_eso_flg_state_cancel),
                     decode(i_flg_value,
                            g_eso_flg_event_socs,
                            g_yes,
                            g_eso_flg_event_sc,
                            g_yes,
                            g_eso_flg_event_cs,
                            g_yes,
                            g_eso_flg_event_so,
                            g_yes,
                            g_eso_flg_event_csocs,
                            g_no,
                            g_eso_flg_event_csc,
                            g_no,
                            g_eso_flg_event_ccs,
                            g_no,
                            g_eso_flg_event_cso,
                            g_no));
                ---            
                g_error := 'UPDATE SCHEDULE_OUTP';
                IF i_flg_value IN (g_eso_flg_event_csocs, g_eso_flg_event_cso)
                THEN
                    --Sign Off cancelled
                    UPDATE schedule_outp so
                       SET so.flg_state =
                           (SELECT CASE
                                        WHEN d.id_prof_admin IS NOT NULL THEN
                                         pk_grid.g_sched_adm_disch
                                        WHEN d.id_prof_med IS NOT NULL THEN
                                         pk_grid.g_sched_med_disch
                                        ELSE
                                         so.flg_state
                                    END state
                              FROM discharge d
                             WHERE d.flg_status <> pk_alert_constant.g_flg_status_c
                               AND d.id_episode = i_id_episode
                               AND rownum < 2)
                     WHERE so.id_schedule = (SELECT id_schedule
                                               FROM epis_info
                                              WHERE id_episode = i_id_episode)
                       AND id_schedule <> -1;
                ELSE
                    --Sign Off created or updated
                    UPDATE schedule_outp
                       SET flg_state = g_sched_signoff_s
                     WHERE id_schedule = (SELECT id_schedule
                                            FROM epis_info
                                           WHERE id_episode = i_id_episode)
                       AND id_schedule <> -1;
                END IF;
            
                OPEN o_cur FOR
                    SELECT 1
                      FROM dual
                     WHERE 1 = 2;
            END IF;
        ELSE
            OPEN o_cur FOR
                SELECT pk_message.get_message(i_lang, 'SIGN_OFF_T012') title,
                       pk_message.get_message(i_lang, 'SIGN_OFF_M001') msg
                  FROM dual;
        END IF;
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_cur);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_sign_off;

    /** @headcom
    * Public Function. Get Submitted for Co-Sign
    *
    * @param      I_LANG                     Identificação do Idioma
    * @param      I_PROF                     Profissional
    * @param      O_CUR                      Cursor com os pacientes à espera de co-sign 
    * @param      O_ERROR                    Erro
    *
    * @return     boolean
    * @author     Eduardo Lourenco
    * @version    0.1
    * @since      2007/10/09
    */
    FUNCTION get_submitted_for_co_sign
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_cur   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name    VARCHAR2(64) := 'GET_SUBMITTED_FOR_CO_SIGN';
        l_prof_cat     category.flg_type%TYPE;
        l_handoff_type sys_config.value%TYPE;
    BEGIN
        g_error := 'GET PROF CAT';
        alertlog.pk_alertlog.log_info(text => g_error);
        l_prof_cat := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
    
        g_error := 'GET HANDOFF TYPE';
        alertlog.pk_alertlog.log_info(text => g_error);
        pk_hand_off_core.get_hand_off_type(i_lang => i_lang, i_prof => i_prof, io_hand_off_type => l_handoff_type);
    
        g_error := 'GET_SUBMITTED_FOR_CO_SIGN';
        OPEN o_cur FOR
            SELECT eso.id_episode,
                   v.id_patient,
                   decode(pk_patphoto.check_blob(p.id_patient), 'N', '', pk_patphoto.get_pat_foto(p.id_patient, i_prof)) photo,
                   pk_sysdomain.get_domain('PATIENT.GENDER.ABBR', p.gender, i_lang) gender,
                   pk_patient.get_pat_age(i_lang, p.id_patient, i_prof) pat_age,
                   p.name pat_name,
                   nvl(pk_translation.get_translation(i_lang, 'COMPLAINT.CODE_COMPLAINT.' || ei.id_complaint),
                       decode(ei.id_episode,
                              NULL,
                              '',
                              pk_utils.query_to_string('select pk_translation.get_translation(' || i_lang ||
                                                       ', ''COMPLAINT.CODE_COMPLAINT.'' || ec.id_complaint) from epis_complaint ec where ec.id_episode = ' ||
                                                       ei.id_episode || ' and ec.flg_status = ''A''',
                                                       '; '))) visit_reason,
                   pk_date_utils.date_send_tsz(i_lang, v.dt_begin_tstz, i_prof) dt_begin,
                   pk_date_utils.date_hour_chr_extend_tsz(i_lang, v.dt_begin_tstz, i_prof) visit_date,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, prof.id_professional) super_physician,
                   -- José Brito 02/12/2008 ALERT-10580 Show date instead of icon
                   decode(eso.flg_state,
                          g_eso_flg_state_sub_cosign,
                          '|' || pk_date_utils.date_send_tsz(i_lang, eso.dt_event, i_prof) || '|D|X|WaitingIcon',
                          '||I|X|CheckIcon') event_time,
                   pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof) dt_server
              FROM epis_sign_off eso, epis_info ei, episode e, visit v, patient p, professional prof
             WHERE prof.id_professional = nvl(eso.id_professional_dest, eso.id_professional_event)
               AND v.id_patient = p.id_patient
               AND pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                    i_prof,
                                                                                    ei.id_episode,
                                                                                    l_prof_cat,
                                                                                    l_handoff_type),
                                                i_prof.id) != -1
               AND ei.id_episode = e.id_episode
               AND e.id_visit = v.id_visit
               AND ei.id_episode = eso.id_episode
               AND eso.flg_real <> 'N'
               AND (eso.flg_state = g_eso_flg_state_sub_cosign OR
                   (eso.flg_state = g_eso_flg_state_co_sign AND
                   trunc(eso.dt_event, 'D') = trunc(current_timestamp, 'D')))
                  -- Only display the most recent action
               AND eso.dt_event = (SELECT dt_event
                                     FROM (SELECT dt_event,
                                                  id_episode,
                                                  row_number() over(PARTITION BY id_episode ORDER BY dt_event DESC) row_number
                                             FROM epis_sign_off e
                                            WHERE flg_real <> 'N')
                                    WHERE id_episode = eso.id_episode
                                      AND row_number = 1)
             ORDER BY p.name;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_cur);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_submitted_for_co_sign;

    /** @headcom
    * Public Function. Get Waiting for Co-Sign
    *
    * @param      I_LANG                     Identificação do Idioma
    * @param      I_PROF                     Profissional
    * @param      O_CUR                      Cursor com os pacientes à espera de co-sign 
    * @param      O_ERROR                    Erro
    *
    * @return     boolean
    * @author     Eduardo Lourenco
    * @version    0.1
    * @since      2007/10/09
    */
    FUNCTION get_waiting_for_co_sign
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_cur   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(64) := 'GET_WAITING_FOR_CO_SIGN';
    BEGIN
        g_error := 'GET_WAITING_FOR_CO_SIGN';
        OPEN o_cur FOR
        
            SELECT eso.id_episode,
                   v.id_patient,
                   decode(pk_patphoto.check_blob(p.id_patient), 'N', '', pk_patphoto.get_pat_foto(p.id_patient, i_prof)) photo,
                   pk_sysdomain.get_domain('PATIENT.GENDER.ABBR', p.gender, i_lang) gender,
                   pk_patient.get_pat_age(i_lang, p.id_patient, i_prof) pat_age,
                   p.name pat_name,
                   nvl(pk_translation.get_translation(i_lang, 'COMPLAINT.CODE_COMPLAINT.' || ei.id_complaint),
                       decode(ei.id_episode,
                              NULL,
                              '',
                              pk_utils.query_to_string('select pk_translation.get_translation(' || i_lang ||
                                                       ', ''COMPLAINT.CODE_COMPLAINT.'' || ec.id_complaint) from epis_complaint ec where ec.id_episode = ' ||
                                                       ei.id_episode || ' and ec.flg_status = ''A''',
                                                       '; '))) visit_reason,
                   pk_date_utils.date_send_tsz(i_lang, v.dt_begin_tstz, i_prof) dt_begin,
                   pk_date_utils.date_hour_chr_extend_tsz(i_lang, v.dt_begin_tstz, i_prof) visit_date,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, prof.id_professional) practitioner,
                   -- José Brito 02/12/2008 ALERT-10580 Show date instead of icon
                   decode(eso.flg_state,
                          g_eso_flg_state_sub_cosign,
                          '|' || pk_date_utils.date_send_tsz(i_lang, eso.dt_event, i_prof) || '|D|X|WaitingIcon',
                          '||I|X|CheckIcon') event_time,
                   pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof) dt_server
              FROM epis_sign_off eso, epis_info ei, episode e, visit v, patient p, professional prof
             WHERE prof.id_professional = ei.id_professional
               AND v.id_patient = p.id_patient
               AND ei.id_episode = e.id_episode
                  -- José Brito 22/05/2008 Return only ALERT® Private Practice episodes
               AND i_prof.software = pk_episode.get_soft_by_epis_type(e.id_epis_type, v.id_institution)
               AND e.id_visit = v.id_visit
               AND ei.id_episode = eso.id_episode
               AND eso.flg_real <> 'N'
               AND ((eso.id_professional_dest = i_prof.id AND eso.flg_state = g_eso_flg_state_sub_cosign) OR
                   (eso.id_professional_event = i_prof.id AND eso.flg_state = g_eso_flg_state_co_sign AND
                   trunc(eso.dt_event, 'D') = trunc(current_timestamp, 'D')))
                  -- Only display the most recent action
               AND eso.dt_event = (SELECT dt_event
                                     FROM (SELECT dt_event,
                                                  id_episode,
                                                  row_number() over(PARTITION BY id_episode ORDER BY dt_event DESC) row_number
                                             FROM epis_sign_off e
                                            WHERE flg_real <> 'N')
                                    WHERE id_episode = eso.id_episode
                                      AND row_number = 1)
             ORDER BY p.name;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_cur);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_waiting_for_co_sign;

    /** @headcom
    * Public Function. Get Pending Tasks
    *
    * @param      I_LANG                     Identificação do Idioma
    * @param      I_PROF                     Profissional
    * @param      O_CUR                      Cursor com os pacientes com tarefas pendentes 
    * @param      O_ERROR                    Erro
    *
    * @return     boolean
    * @author     Eduardo Lourenco
    * @version    0.1
    * @since      2007/10/10
    */
    FUNCTION get_pending_tasks
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_cur   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name    VARCHAR2(64) := 'GET_PENDING_TASKS';
        l_prof_cat     category.flg_type%TYPE;
        l_handoff_type sys_config.value%TYPE;
    BEGIN
        g_error := 'GET PROF CAT';
        alertlog.pk_alertlog.log_info(text => g_error);
        l_prof_cat := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
    
        g_error := 'GET HANDOFF TYPE';
        alertlog.pk_alertlog.log_info(text => g_error);
        pk_hand_off_core.get_hand_off_type(i_lang => i_lang, i_prof => i_prof, io_hand_off_type => l_handoff_type);
    
        g_error := 'GET_PENDING_TASKS';
        OPEN o_cur FOR
        
            SELECT a.id_patient,
                   a.photo,
                   a.gender,
                   a.pat_age,
                   a.name pat_name,
                   a.id_episode,
                   -- José Brito 06/11/2008 Reformulação To-do List
                   pk_date_utils.date_send_tsz(i_lang, a.dt_begin_tstz, i_prof) dt_begin,
                   ---
                   pk_date_utils.date_hour_chr_extend_tsz(i_lang, a.dt_begin_tstz, i_prof) encounter_date,
                   a.reason_notes visit_reason,
                   a.sign_off,
                   decode(b.pending_issue, NULL, decode(a.pending_issue, 0, NULL, a.pending_issue), b.pending_issue) pending_issues,
                   decode(a.pending_lab, 0, NULL, a.pending_lab) pending_lab,
                   decode(a.pending_image, 0, NULL, a.pending_image) pending_image,
                   pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof) dt_server,
                   dt_first_lab,
                   dt_first_image
              FROM (SELECT p.id_patient,
                           decode(pk_patphoto.check_blob(p.id_patient),
                                  'N',
                                  '',
                                  pk_patphoto.get_pat_foto(p.id_patient, i_prof)) photo,
                           pk_sysdomain.get_domain('PATIENT.GENDER.ABBR', p.gender, i_lang) gender,
                           pk_patient.get_pat_age(i_lang, p.id_patient, i_prof) pat_age,
                           p.name,
                           e.id_episode,
                           v.dt_begin_tstz,
                           nvl(pk_translation.get_translation(i_lang, 'COMPLAINT.CODE_COMPLAINT.' || ei.id_complaint),
                               decode(ei.id_episode,
                                      NULL,
                                      '',
                                      pk_utils.query_to_string('select pk_translation.get_translation(' || i_lang ||
                                                               ', ''COMPLAINT.CODE_COMPLAINT.'' || ec.id_complaint) from epis_complaint ec where ec.id_episode = ' ||
                                                               ei.id_episode || ' and ec.flg_status = ''A''',
                                                               '; '))) reason_notes,
                           decode((SELECT decode(COUNT(*), 0, 1, 0)
                                     FROM epis_sign_off eso
                                    WHERE eso.id_episode = e.id_episode) +
                                  (SELECT COUNT(*)
                                     FROM (SELECT id_episode,
                                                  MAX(dt_event) over(PARTITION BY id_episode) max_dt_event,
                                                  dt_event,
                                                  flg_state
                                             FROM epis_sign_off)
                                    WHERE dt_event = max_dt_event
                                      AND flg_state = g_eso_flg_state_cancel
                                      AND id_episode = e.id_episode),
                                  0,
                                  NULL,
                                  '|' || pk_date_utils.date_send_tsz(i_lang, v.dt_begin_tstz, i_prof) || '|D|R') sign_off,
                           (SELECT COUNT(*)
                              FROM lab_tests_ea ltae
                             WHERE ltae.id_episode = e.id_episode
                               AND ltae.id_institution = i_prof.institution
                               AND ltae.flg_status_req NOT IN (g_ard_flg_status_f, g_ard_flg_status_c)) pending_lab,
                           (SELECT COUNT(*)
                              FROM exams_ea eea, exam_req er
                             WHERE eea.id_episode = e.id_episode
                               AND eea.flg_status_req NOT IN (g_erd_flg_status_f, g_erd_flg_status_c)
                               AND eea.id_exam_req = er.id_exam_req
                               AND er.id_institution = i_prof.institution) pending_image,
                           (SELECT MIN(ltae.dt_order)
                              FROM lab_tests_ea ltae
                             WHERE ltae.id_episode = e.id_episode
                               AND ltae.id_institution = i_prof.institution
                               AND ltae.flg_status_req NOT IN (g_ard_flg_status_f, g_ard_flg_status_c)) dt_first_lab,
                           (SELECT MIN(cso.dt_ordered_by)
                              FROM exam_req_det erd,
                                   TABLE(pk_co_sign_api.tf_co_sign_task_hist_info(i_lang, i_prof, e.id_episode, NULL)) cso
                             WHERE erd.id_co_sign_order = cso.id_co_sign_hist(+)
                               AND erd.id_exam_req IN
                                   (SELECT er.id_exam_req
                                      FROM exam_req er
                                     WHERE er.id_episode = e.id_episode
                                       AND er.id_institution = i_prof.institution
                                       AND er.flg_status NOT IN (g_erd_flg_status_f, g_erd_flg_status_c))) dt_first_image,
                           (SELECT COUNT(*)
                              FROM pending_issue i
                             WHERE i.id_patient = p.id_patient
                               AND i.flg_status IN (g_pend_issue_open, g_pend_issue_g)) pending_issue
                      FROM episode e, epis_info ei, visit v, patient p
                     WHERE e.id_episode = ei.id_episode
                       AND pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                            i_prof,
                                                                                            ei.id_episode,
                                                                                            l_prof_cat,
                                                                                            l_handoff_type),
                                                        i_prof.id) != -1
                          -- José Brito 22/05/2008 Return only ALERT® Private Practice episodes
                       AND i_prof.software = pk_episode.get_soft_by_epis_type(e.id_epis_type, i_prof.institution)
                          --
                       AND v.id_visit = e.id_visit
                       AND p.id_patient = v.id_patient
                       AND e.flg_status IN (g_e_flg_status_a, g_e_flg_status_p)) a,
                   (SELECT DISTINCT p.id_patient, p.name, COUNT(*) over(PARTITION BY p.id_patient) pending_issue
                      FROM patient p, pending_issue pi, pending_issue_prof pip
                     WHERE p.id_patient = pi.id_patient
                       AND pi.id_pending_issue = pip.id_pending_issue
                       AND pip.id_professional = i_prof.id
                       AND pip.flg_status = g_assign_flg_active
                       AND pi.flg_status IN (g_pend_issue_open, g_pend_issue_g)) b
             WHERE (a.pending_lab > 0 OR a.pending_image > 0 OR a.pending_issue > 0 OR b.pending_issue > 0)
               AND a.id_patient = b.id_patient(+)
             ORDER BY dt_first_lab, dt_first_image;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_cur);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_pending_tasks;

    /** @headcom
    * Public Function. Get Pending Lab Tasks
    *
    * @param      I_LANG                     Identificação do Idioma
    * @param      I_PROF                     Profissional
    * @param      I_ID_EPISODE               Identificação do episódio
    * @param      O_CUR                      Cursor com as tarefas de análise pendentes para um determinado paciente 
    * @param      O_ERROR                    Erro
    *
    * @return     boolean
    * @author     Eduardo Lourenco
    * @version    0.1
    * @since      2007/10/10
    */
    FUNCTION get_pending_lab_tasks
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_cur        OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(64) := 'GET_PENDING_LAB_TASKS';
    BEGIN
        g_error := 'GET_PENDING_LAB_TASKS';
        OPEN o_cur FOR
        
            SELECT pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                             i_prof,
                                                             'A',
                                                             'ANALYSIS.CODE_ANALYSIS.' || ltea.id_analysis,
                                                             NULL) task_desc,
                   pk_date_utils.date_chr_extend_tsz(i_lang, ltea.dt_req, i_prof) task_date,
                   NULL visit_desc, -- TODO
                   '|' || pk_date_utils.date_send_tsz(i_lang, ltea.dt_req, i_prof) || '|I|X|WaitingIcon' event_time,
                   pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof) dt_server
              FROM lab_tests_ea ltea
             WHERE ltea.id_episode = i_id_episode
               AND ltea.id_institution = i_prof.institution
               AND ltea.flg_status_req NOT IN (g_ard_flg_status_f, g_ard_flg_status_c)
             ORDER BY ltea.dt_req;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_cur);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_pending_lab_tasks;

    /** @headcom
    * Public Function. Get Pending Exam Tasks
    *
    * @param      I_LANG                     Identificação do Idioma
    * @param      I_PROF                     Profissional
    * @param      I_ID_EPISODE               Identificação do episódio
    * @param      O_CUR                      Cursor com as tarefas de exames pendentes para um determinado paciente 
    * @param      O_ERROR                    Erro
    *
    * @return     boolean
    * @author     Eduardo Lourenco
    * @version    0.1
    * @since      2007/10/10
    */
    FUNCTION get_pending_exam_tasks
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_cur        OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(64) := 'GET_PENDING_EXAM_TASKS';
    BEGIN
        g_error := 'GET_PENDING_EXAM_TASKS';
        OPEN o_cur FOR
        --/<DENORMALIZATION> Sérgio Monteiro 09-10-08 /--
            SELECT pk_exams_api_db.get_alias_translation(i_lang, i_prof, 'EXAM.CODE_EXAM.' || eea.id_exam, NULL) task_desc,
                   pk_date_utils.date_chr_extend_tsz(i_lang, eea.dt_req, i_prof) task_date,
                   NULL visit_desc, -- TODO
                   '|' || pk_date_utils.date_send_tsz(i_lang, eea.dt_req, i_prof) || '|I|X|WaitingIcon' event_time,
                   pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof) dt_server
              FROM exams_ea eea, exam_req er
             WHERE eea.id_episode = i_id_episode
               AND er.id_exam_req = eea.id_exam_req
               AND er.id_institution = i_prof.institution
               AND eea.flg_status_req NOT IN (g_erd_flg_status_f, g_erd_flg_status_c)
             ORDER BY eea.dt_req;
        --/<DENORMALIZATION>/--
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_cur);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_pending_exam_tasks;

    /**********************************************************************************************
    * Get the Sign Off checklist information
    *
    * @param          i_lang              language id    
    * @param          i_prof              professional type
    * @param          i_episode           episode id
    * @param          o_checklist         Checklist data
    * @param          o_error             error message
    *
    * @return         boolean             true on success, otherwise false
    *
    * @author                             Orlando Antunes
    * @version                            2.5.1.2
    * @since                              2010/10/19       
    ********************************************************************************************/
    FUNCTION get_sign_off_checklist
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        o_checklist OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_count_epis_final_diag PLS_INTEGER;
    
        l_discharge_state VARCHAR2(1 CHAR);
        l_sign_off_state  VARCHAR2(1 CHAR);
    BEGIN
    
        SELECT COUNT(*)
          INTO l_count_epis_final_diag
          FROM epis_diagnosis ed
         WHERE ed.id_episode = i_episode
           AND ed.flg_type = 'D'
           AND ed.flg_status NOT IN ('C', 'D');
    
        IF NOT pk_discharge.get_epis_discharge_state(i_lang      => i_lang,
                                                     i_prof      => i_prof,
                                                     i_episode   => i_episode,
                                                     o_discharge => l_discharge_state,
                                                     o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        IF NOT get_epis_sign_off_state(i_lang     => i_lang,
                                       i_prof     => i_prof,
                                       i_episode  => i_episode,
                                       o_sign_off => l_sign_off_state,
                                       o_error    => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        OPEN o_checklist FOR
            SELECT pk_message.get_message(i_lang, 'EHR_VIEWER_T126') description,
                   CASE
                        WHEN l_count_epis_final_diag > 0 THEN
                         'Y'
                        ELSE
                         'N'
                    END VALUE
              FROM dual
            UNION ALL
            SELECT pk_message.get_message(i_lang, 'EHR_VIEWER_T113') description, l_discharge_state VALUE
              FROM dual
            UNION ALL
            SELECT pk_message.get_message(i_lang, 'SIGN_OFF_T002') description, l_sign_off_state VALUE
              FROM dual;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'GET_SIGN_OFF_CHECKLIST',
                                              o_error);
            RETURN FALSE;
    END get_sign_off_checklist;
    --

    /**********************************************************************************************
    * Get the state of the Episode in terms of Sign Off
    *
    * @param          i_lang              language id    
    * @param          i_prof              professional type
    * @param          i_episode           episode id
    * @param          o_sign_off          Sign Off state: 
    *                                     Y if the episode is already signed off and N otherwise
    *
    * @param          o_error             error message
    *
    * @return         boolean             true on success, otherwise false
    *
    * @author                             Orlando Antunes
    * @version                            2.5.1.2
    * @since                              2010/10/20       
    ********************************************************************************************/
    FUNCTION get_epis_sign_off_state
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        o_sign_off OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        o_sign_off := nvl(get_epis_sign_off_state(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode),
                          pk_alert_constant.g_no);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'GET_EPIS_SIGN_OFF_STATE',
                                              o_error);
            RETURN FALSE;
    END get_epis_sign_off_state;
    --

    /**********************************************************************************************
    * Get the state of the Episode in terms of Sign Off (to be used in SQL)
    *
    * @param          i_lang              language id    
    * @param          i_prof              professional type
    * @param          i_episode           episode id
    *
    * @param          epis_sign_off_state Sign Off state: 
    *                                     Y if the episode is already signed off and N otherwise
    *
    * @author                             Orlando Antunes
    * @version                            2.5.1.2
    * @since                              2010/10/2       
    ********************************************************************************************/
    FUNCTION get_epis_sign_off_state
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
    
        l_sign_off_value VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
        l_state          epis_sign_off.flg_state%TYPE;
    
        l_error t_error_out;
    BEGIN
    
        --in this phase, only PP will have this notion of the Sign-off area
        IF i_prof.software <> pk_alert_constant.g_soft_private_practice
        THEN
            RETURN pk_alert_constant.g_no;
        END IF;
    
        g_error := 'GET FLG_STATE';
        SELECT nvl((SELECT flg_state
                     FROM (SELECT flg_state
                             FROM epis_sign_off eso
                            WHERE eso.id_episode = i_episode
                            ORDER BY eso.dt_event DESC, eso.id_epis_sign_off DESC)
                    WHERE rownum <= 1),
                   g_eso_flg_state_cancel) flg_state
          INTO l_state
          FROM dual;
    
        IF l_state = g_eso_flg_state_cancel
        THEN
            l_sign_off_value := g_no;
        ELSIF l_state = g_eso_flg_state_sub_cosign
        THEN
            l_sign_off_value := g_yes;
        ELSIF l_state = g_eso_flg_state_co_sign
        THEN
            l_sign_off_value := g_yes;
        ELSIF l_state = g_eso_flg_state_sign_off
        THEN
            l_sign_off_value := g_yes;
        END IF;
    
        RETURN l_sign_off_value;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'GET_EPIS_SIGN_OFF_STATE',
                                              l_error);
            RETURN NULL;
    END get_epis_sign_off_state;
    --

    /**********************************************************************************************
    * Get the ID of the Episode Sign Off (epis_sign_off)
    *
    * @param          i_lang              language id    
    * @param          i_prof              professional type
    * @param          i_episode           episode id
    * @param          o_id_epis_sign_off  ID Episode Sign Off state
    * @param          o_error             error message
    *
    * @return         boolean             true on success, otherwise false
    *
    * @author                             Orlando Antunes
    * @version                            2.5.1.2
    * @since                              2010/10/25       
    ********************************************************************************************/
    FUNCTION get_epis_sign_off_id
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        o_id_epis_sign_off OUT epis_sign_off.id_epis_sign_off%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        o_id_epis_sign_off := NULL;
        --
        SELECT id_epis_sign_off
          INTO o_id_epis_sign_off
          FROM (SELECT eso.id_epis_sign_off
                  FROM epis_sign_off eso
                 WHERE eso.id_episode = i_episode
                 ORDER BY eso.dt_event DESC)
         WHERE rownum < 2;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'GET_EPIS_SIGN_OFF_ID',
                                              o_error);
            RETURN FALSE;
    END get_epis_sign_off_id;

    /**********************************************************************************************
    * Get the list of Addemdums for a given episode. This function includes also information
    * about the Sign off of the episode, and when exists, the Sign off for each addendums
    *
    * @param          i_lang              language id    
    * @param          i_prof              professional type
    * @param          i_episode           episode id
    * @param          o_sign_off          Sign off data
    * @param          o_addendums_list    Addendums list
    * @param          o_error             error message
    *
    * @return         boolean             true on success, otherwise false
    *
    * @author                             Orlando Antunes
    * @version                            2.5.1.2
    * @since                              2010/10/19       
    ********************************************************************************************/
    FUNCTION get_addendums_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        o_sign_off       OUT pk_types.cursor_type,
        o_addendums_list OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        pk_alertlog.log_debug('PK_SIGN_OFF.GET_ADDENDUMS_LIST: i_episode = ' || i_episode);
        g_error := 'GET_SIGN_OFF';
        IF NOT get_epis_sign_off(i_lang     => i_lang,
                                 i_prof     => i_prof,
                                 i_episode  => i_episode,
                                 o_sign_off => o_sign_off,
                                 o_error    => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'GET_ADDENDUMS_LIST';
        IF NOT get_epis_addendums(i_lang      => i_lang,
                                  i_prof      => i_prof,
                                  i_episode   => i_episode,
                                  o_addendums => o_addendums_list,
                                  o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'GET_ADDENDUMS_LIST',
                                              o_error);
            RETURN FALSE;
    END get_addendums_list;
    --

    /**********************************************************************************************
    * Get the list of Addemdums for a given episode.
    *
    * @param          i_lang              language id    
    * @param          i_prof              professional type
    * @param          i_episode           episode id
    * @param          o_addendums_list    Addendums list
    * @param          o_error             error message
    *
    * @return         boolean             true on success, otherwise false
    *
    * @author                             Orlando Antunes
    * @version                            2.5.1.2
    * @since                              2010/10/28       
    ********************************************************************************************/
    FUNCTION get_epis_addendums
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        o_addendums OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        pk_alertlog.log_debug('PK_SIGN_OFF.GET_ADDENDUMS: i_episode = ' || i_episode);
        g_error := 'GET_SIGN_OFF';
    
        g_error := 'GET_ADDENDUMS';
        OPEN o_addendums FOR
            SELECT ea.id_epis_addendum id,
                   eso.id_episode id_episode,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, ea.dt_event, i_prof) dt,
                   pk_tools.get_prof_description(i_lang, i_prof, ea.id_professional, ea.dt_event, NULL) prof_sign,
                   ea.id_professional id_prof,
                   ea.notes notes,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, ea.dt_sign_off, i_prof) sign_off_dt,
                   pk_tools.get_prof_description(i_lang, i_prof, ea.id_professional_sign_off, ea.dt_sign_off, NULL) sign_off_prof_sign,
                   decode(ea.id_professional_sign_off,
                          NULL,
                          NULL,
                          pk_date_utils.dt_chr_date_hour_tsz(i_lang, ea.dt_sign_off, i_prof) || ' / ' ||
                          pk_tools.get_prof_description(i_lang,
                                                        i_prof,
                                                        ea.id_professional_sign_off,
                                                        ea.dt_sign_off,
                                                        NULL)) addendum_sign_off_str,
                   ea.flg_status flg_status,
                   pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, ea.id_cancel_reason) cancel_reason_desc,
                   ea.notes_cancel cancel_notes,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, ea.dt_cancel, i_prof) cancel_dt,
                   pk_tools.get_prof_description(i_lang, i_prof, ea.id_prof_cancel, ea.dt_cancel, NULL) cancel_prof_sign,
                   decode(ea.id_prof_cancel,
                          NULL,
                          NULL,
                          pk_date_utils.dt_chr_date_hour_tsz(i_lang, ea.dt_cancel, i_prof) || ' / ' ||
                          pk_tools.get_prof_description(i_lang, i_prof, ea.id_prof_cancel, ea.dt_cancel, NULL)) addendum_cancel_str,
                   ea.dt_event,
                   decode(ea.id_prof_cancel, NULL, 1, 2) rank
              FROM epis_addendum ea
              JOIN epis_sign_off eso
                ON (ea.id_epis_sign_off = eso.id_epis_sign_off)
             WHERE eso.id_episode = i_episode
             ORDER BY rank, ea.dt_event DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'GET_EPIS_ADDENDUMS',
                                              o_error);
            RETURN FALSE;
    END get_epis_addendums;
    --

    /**********************************************************************************************
    * Get the Sign Off details for a given episode.
    *
    * @param          i_lang              language id    
    * @param          i_prof              professional type
    * @param          i_episode           episode id
    * @param          o_sign_off          Sign off data
    * @param          o_error             error message
    *
    * @return         boolean             true on success, otherwise false
    *
    * @author                             Orlando Antunes
    * @version                            2.5.1.2
    * @since                              2010/10/28       
    ********************************************************************************************/
    FUNCTION get_epis_sign_off
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        o_sign_off OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        pk_alertlog.log_debug('PK_SIGN_OFF.GET_EPIS_SIGN_OFF: i_episode = ' || i_episode);
        g_error := 'GET_SIGN_OFF';
        OPEN o_sign_off FOR
            SELECT *
              FROM (SELECT eso.id_epis_sign_off id,
                           pk_date_utils.dt_chr_date_hour_tsz(i_lang, eso.dt_event, i_prof) dt,
                           pk_tools.get_prof_description(i_lang, i_prof, eso.id_professional_event, eso.dt_event, NULL) prof_sign,
                           decode(eso.id_professional_event,
                                  NULL,
                                  NULL,
                                  pk_date_utils.dt_chr_date_hour_tsz(i_lang, eso.dt_event, i_prof) || ' / ' ||
                                  pk_tools.get_prof_description(i_lang,
                                                                i_prof,
                                                                eso.id_professional_event,
                                                                eso.dt_event,
                                                                NULL)) sign_off_str
                      FROM epis_sign_off eso
                     WHERE eso.id_episode = i_episode
                     ORDER BY eso.dt_event DESC)
             WHERE rownum < 2;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'GET_EPIS_SIGN_OFF',
                                              o_error);
            RETURN FALSE;
    END get_epis_sign_off;
    --

    /**********************************************************************************************
    * Set new Addendum or updade an existing Addendum to register the Sign Off
    *
    * @param          i_lang              language id    
    * @param          i_prof              professional type
    * @param          i_episode           episode id
    * @param          i_epis_addendum     Addendum ID (Null when creating a new Addendum)
    * @param          i_epis_sign_off     Sign Off ID
    * @param          i_prof_sign_off     Professional that registers the Addendum's Sign Off
    * @param          i_addendum          Addendum text
    * @param          o_epis_addendum     New addendum ID
    * @param          o_error             error message
    *
    * @return         boolean             true on success, otherwise false
    *
    * @author                             Orlando Antunes
    * @version                            2.5.1.2
    * @since                              2010/10/19       
    ********************************************************************************************/
    FUNCTION set_addendum
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_epis_addendum IN epis_addendum.id_epis_addendum%TYPE,
        i_epis_sign_off IN epis_sign_off.id_epis_sign_off%TYPE,
        i_prof_sign_off IN epis_addendum.id_professional_sign_off%TYPE,
        i_addendum      IN epis_addendum.notes%TYPE,
        o_epis_addendum OUT epis_addendum.id_epis_addendum%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_epis_addendum epis_addendum.id_epis_addendum%TYPE;
        l_rows             table_varchar;
        l_timestamp        TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
    BEGIN
    
        pk_alertlog.log_debug('GET_SIGN_OFF.SET_ADDENDUM: i_episode = ' || i_episode || ', i_epis_sign_off = ' ||
                              i_epis_sign_off);
        g_error := 'GET_SIGN_OFF.SET_ADDENDUM';
    
        IF i_epis_addendum IS NULL
        THEN
            g_error := 'CALL ts_epis_addendum.ins';
            ts_epis_addendum.ins(id_epis_sign_off_in         => i_epis_sign_off,
                                 id_professional_in          => i_prof.id,
                                 dt_event_in                 => l_timestamp,
                                 id_professional_sign_off_in => i_prof_sign_off,
                                 dt_sign_off_in              => CASE
                                                                    WHEN i_prof_sign_off IS NULL THEN
                                                                     NULL
                                                                    ELSE
                                                                     l_timestamp
                                                                END,
                                 flg_status_in               => CASE
                                                                    WHEN i_prof_sign_off IS NULL THEN
                                                                     g_ea_flg_status_a
                                                                    ELSE
                                                                     g_ea_flg_status_s
                                                                END,
                                 notes_in                    => i_addendum,
                                 rows_out                    => l_rows,
                                 id_epis_addendum_out        => l_id_epis_addendum);
        
            g_error := 'CALL t_data_gov_mnt.process_insert';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'EPIS_ADDENDUM',
                                          i_rowids     => l_rows,
                                          o_error      => o_error);
        
        ELSE
            g_error := 'CALL ts_epis_addendum.upd';
            ts_epis_addendum.upd(id_epis_addendum_in         => i_epis_addendum,
                                 id_professional_sign_off_in => i_prof_sign_off,
                                 dt_sign_off_in              => l_timestamp,
                                 flg_status_in               => g_ea_flg_status_s,
                                 rows_out                    => l_rows);
        
            g_error := 'CALL t_data_gov_mnt.process_update';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'EPIS_ADDENDUM',
                                          i_rowids       => l_rows,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('ID_PROFESSIONAL_SIGN_OFF',
                                                                          'DT_SIGN_OFF',
                                                                          'FLG_STATUS'));
        
        END IF;
        --There is no need to call the set_first_obs because is never the first operation to be done within an episode!
        o_epis_addendum := l_id_epis_addendum;
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'SET_ADDENDUM',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_addendum;
    --

    /********************************************************************************************
    * Cancel Addendums.
    *
    * @ param i_lang                    Preferred language ID for this professional
    * @ param i_prof                    Object (professional ID, institution ID, software ID)
    * @ param i_episode                 episode id
    * @ param i_epis_addendum           Addendum ID (Null when creating a new Addendum)
    * @ param i_notes                   Cancel notes
    * @ param i_cancel_reason           Cancel reason
    *
    * @ param o_error                   Error message
    *
    * @return                          true or false on success or error
    *
    * @author                           Orlando Antunes
    * @version                          0.1
    * @since                            2010/02/26
    **********************************************************************************************/
    FUNCTION set_cancel_addendum
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_epis_addendum IN epis_addendum.id_epis_addendum%TYPE,
        i_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_notes         IN epis_addendum.notes_cancel%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rows      table_varchar;
        l_timestamp TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
    BEGIN
    
        pk_alertlog.log_debug('PK_SIGN_OFF.SET_CANCEL_ADDENDUM: i_epis_addendum = ' || i_epis_addendum);
    
        IF i_epis_addendum IS NULL
        THEN
            g_error := 'Invalid Input parameters';
            RAISE g_generic_exception;
        ELSE
            g_error := 'CALL ts_epis_addendum.upd';
            ts_epis_addendum.upd(id_epis_addendum_in => i_epis_addendum,
                                 id_prof_cancel_in   => i_prof.id,
                                 dt_cancel_in        => l_timestamp,
                                 notes_cancel_in     => i_notes,
                                 id_cancel_reason_in => i_cancel_reason,
                                 flg_status_in       => g_ea_flg_status_c,
                                 rows_out            => l_rows);
        
            g_error := 'CALL t_data_gov_mnt.process_update';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'EPIS_ADDENDUM',
                                          i_rowids       => l_rows,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('ID_PROF_CANCEL',
                                                                          'DT_CANCEL',
                                                                          'NOTES_CANCEL',
                                                                          'ID_CANCEL_REASON',
                                                                          'FLG_STATUS'));
        
        END IF;
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'SET_CANCEL_ADDENDUM',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_cancel_addendum;
    --
    /**********************************************************************************************
    * get_GLOBAL_SHORTCUT_FILTER
    *
    * @param          i_lang              language id    
    * @param          i_prof              professional type
    * @param          i_episode           episode id
    *
    * @author                             Paulo Teixeira
    * @version                            2.6.5
    * @since                              2015/07/16      
    ********************************************************************************************/
    FUNCTION get_global_shortcut_filter
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_sign_off VARCHAR2(1 CHAR);
        l_return   VARCHAR2(100 CHAR) := 'NORMAL';
    BEGIN
        l_sign_off := nvl(get_epis_sign_off_state(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode),
                          pk_alert_constant.g_no);
    
        IF l_sign_off = pk_alert_constant.g_yes
        THEN
            l_return := 'ADDENDUM';
        END IF;
    
        RETURN l_return;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN l_return;
    END;
BEGIN

    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);
    g_yes := 'Y';
    g_no  := 'N';

    g_eso_flg_state_cancel     := 'C';
    g_eso_flg_state_sub_cosign := 'SC';
    g_eso_flg_state_co_sign    := 'CS';
    g_eso_flg_state_sign_off   := 'SO';

    g_eso_flg_event_socs  := 'SOCS';
    g_eso_flg_event_sc    := 'SC';
    g_eso_flg_event_cs    := 'CS';
    g_eso_flg_event_so    := 'SO';
    g_eso_flg_event_csocs := 'CSOCS';
    g_eso_flg_event_csc   := 'CSC';
    g_eso_flg_event_ccs   := 'CCS';
    g_eso_flg_event_cso   := 'CSO';

    g_i_flg_status_unresolved := 'U';
    g_im_flg_status_active    := 'A';
    g_im_flg_status_cancel    := 'C';

    g_ard_flg_status_f := 'F';
    g_ard_flg_status_c := 'C';
    g_ard_flg_th_e     := 'E';

    g_erd_flg_status_f := 'F';
    g_erd_flg_status_c := 'C';
    g_er_flg_time_e    := 'E';

    g_e_flg_status_a := 'A';
    g_e_flg_status_p := 'P';

    g_assign_flg_active := 'A';

END;
/
