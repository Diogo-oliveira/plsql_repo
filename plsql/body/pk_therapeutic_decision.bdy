/*-- Last Change Revision: $Rev: 1850754 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2018-07-05 15:20:59 +0100 (qui, 05 jul 2018) $*/

CREATE OR REPLACE PACKAGE BODY pk_therapeutic_decision IS

    /**********************************************************************************************
    * Gets the summary of therapeutic decisions for a patient
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_patient               ID Patient
    * @param i_episode               ID Episode
    *
    * @param o_thdecision            Cursor with the information of register and therapeutic decision
    * @param o_thdecision_prof       Cursor with the information of the professionals
    * @param o_flg_create            String thar indicates if button Create is active(A/I)
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/06/22
    **********************************************************************************************/

    FUNCTION get_th_dec_summary
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        o_thdecision      OUT pk_types.cursor_type,
        o_thdecision_prof OUT pk_types.cursor_type,
        o_flg_create      OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_decision_title    sys_message.desc_message%TYPE;
        l_th_decision_title sys_message.desc_message%TYPE;
        l_th_presence_title sys_message.desc_message%TYPE;
        l_num               NUMBER;
        l_sch_event         sch_event.id_sch_event%TYPE;
    BEGIN
    
        --*RV FALTA - EM VEZ DA ESPECIALIDADE DO MÉDICO DEVE SER O TIPO DE CONSULTA DO AGENDAMENTO
        l_th_decision_title := pk_message.get_message(i_lang => i_lang, i_code_mess => 'THERAPEUTIC_DECISION_T002');
        l_decision_title    := pk_message.get_message(i_lang => i_lang, i_code_mess => 'THERAPEUTIC_DECISION_T003');
        l_th_presence_title := pk_message.get_message(i_lang => i_lang, i_code_mess => 'THERAPEUTIC_DECISION_T004');
    
        g_error := 'COUNT THERAPEUTIC DECISION';
        -- Verify if for this episode there are any therapeutic decision
        SELECT COUNT(1)
          INTO l_num
          FROM therapeutic_decision thd, therapeutic_decision_det thdd
         WHERE thd.id_therapeutic_decision = thdd.id_therapeutic_decision
           AND thd.id_episode = i_episode
           AND thd.flg_status = g_flg_status_a;
    
        g_error := 'DETERMINE THE EVENT_TYPE';
        BEGIN
            SELECT s.id_sch_event
              INTO l_sch_event
              FROM epis_info e, schedule s
             WHERE e.id_episode = i_episode
               AND e.id_schedule = s.id_schedule;
        EXCEPTION
            WHEN OTHERS THEN
                l_sch_event := 0;
        END;
    
        -- se o tipo de evento do episódio for de consultas de grupo e ainda não tiver sido efectuado registo 
        -- de decisões terapeuticas e o profissional que esta ligado ser o responsável pela consulta
        IF g_id_sch_event = l_sch_event
           AND l_num = 0
           AND i_prof.id = get_prof_responsible(i_episode)
        THEN
            o_flg_create := g_flg_active;
        ELSE
            o_flg_create := g_flg_inactive;
        END IF;
    
        g_error := 'OPEN  o_thdecision';
        OPEN o_thdecision FOR
            SELECT id_therapeutic_decision,
                   dt_creation,
                   dt_register,
                   id_professional,
                   nick_name,
                   desc_speciality,
                   flg_current_episode,
                   l_th_decision_title th_decision_title,
                   l_decision_title decision_title,
                   therapeutic_decision,
                   id_prof_resp,
                   decode(id_prof_resp,
                          i_prof.id,
                          g_flg_active,
                          decode(get_prof_in_consult(i_prof.id, id_therapeutic_decision),
                                 g_yes,
                                 g_flg_validation,
                                 g_flg_inactive)) flg_status,
                   decode(id_prof_resp, i_prof.id, g_yes, g_no) flg_create,
                   l_th_presence_title presence_title
              FROM (SELECT id_therapeutic_decision,
                           pk_date_utils.dt_chr_date_hour_tsz(i_lang, thd.dt_creation, i_prof) dt_register,
                           thd.id_professional,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, thd.id_professional) nick_name,
                           (SELECT pk_schedule_common.get_translation_alias(i_lang,
                                                                            i_prof,
                                                                            se.id_sch_event,
                                                                            se.code_sch_event)
                              FROM epis_info ei, schedule s, sch_event se
                             WHERE ei.id_episode = e.id_episode
                               AND ei.id_schedule = s.id_schedule
                               AND s.id_sch_event = se.id_sch_event) desc_speciality,
                           decode(thd.id_episode, i_episode, g_yes, g_no) flg_current_episode,
                           thd.therapeutic_decision,
                           get_prof_responsible(thd.id_episode) id_prof_resp,
                           thd.dt_creation
                      FROM therapeutic_decision thd, episode e
                     WHERE thd.id_patient = i_patient
                       AND thd.flg_status = g_flg_status_a
                       AND thd.id_episode = e.id_episode)
             ORDER BY dt_creation DESC;
    
        g_error := 'OPEN  o_thdecision_prof';
        -- list of professional in the consult
        OPEN o_thdecision_prof FOR
            SELECT thdd.id_therapeutic_decision,
                   thdd.id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, thdd.id_professional) name_profissional,
                   pk_sysdomain.get_domain(g_flg_presence, thdd.flg_presence, i_lang) presence,
                   pk_sysdomain.get_domain(g_flg_opinion, thdd.flg_opinion, i_lang) opinion,
                   decode(thdd.flg_opinion, g_yes, g_no, decode(thdd.id_professional, i_prof.id, g_yes, g_no)) flg_red
              FROM therapeutic_decision thd, therapeutic_decision_det thdd
             WHERE thd.id_patient = i_patient
               AND thd.flg_status = g_flg_status_a
               AND thd.id_therapeutic_decision = thdd.id_therapeutic_decision
               AND thdd.flg_status = g_flg_status_a
             ORDER BY thd.dt_creation DESC, name_profissional;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'GET_TH_DEC_SUMMARY',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_thdecision);
            pk_types.open_my_cursor(o_thdecision_prof);
            RETURN FALSE;
        
    END get_th_dec_summary;

    /**********************************************************************************************
    * Gets the ID of professional that is the responsible for the consult
    *
    * @param i_episode               ID Episode
    *
    *
    * @return                        Returns the ID of the professional that is the responsible
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/06/23
    **********************************************************************************************/
    FUNCTION get_prof_responsible(i_episode IN episode.id_episode%TYPE) RETURN NUMBER IS
        l_prof_resp NUMBER;
        l_num       NUMBER;
    BEGIN
    
        SELECT COUNT(1) -- verificar se já existe registo de decisão terapêutica
          INTO l_num
          FROM therapeutic_decision
         WHERE id_episode = i_episode;
        IF l_num = 0 -- Não existe(ir buscar o profissional responsável registado no agendamento)
        THEN
            SELECT sr.id_professional
              INTO l_prof_resp
              FROM epis_info ei, schedule s, sch_resource sr
             WHERE ei.id_episode = i_episode
               AND ei.id_schedule = s.id_schedule
               AND s.id_schedule = sr.id_schedule
               AND sr.flg_leader = g_yes;
        ELSE
            SELECT DISTINCT thdd.id_professional
              INTO l_prof_resp
              FROM therapeutic_decision thd, therapeutic_decision_det thdd
             WHERE thd.id_episode = i_episode
               AND thd.flg_status = g_flg_status_a
               AND thd.id_therapeutic_decision = thdd.id_therapeutic_decision
               AND thdd.flg_status = g_flg_status_a
               AND thdd.flg_leader = g_yes;
        END IF;
        RETURN l_prof_resp;
    END get_prof_responsible;

    /**********************************************************************************************
    * Verify if a specific profissional is part of the consultation team 
    *
    * @param i_professional          ID Professional
    * @param i_id_th_decision        ID therapeutic Decision
    *
    * @return                        Returns a flag that indicates if is missing one validation 
    *                                and the professional is part of the team
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/06/23
    **********************************************************************************************/

    FUNCTION get_prof_in_consult
    (
        i_professional   IN professional.id_professional%TYPE,
        i_id_th_decision IN therapeutic_decision.id_therapeutic_decision%TYPE
    ) RETURN VARCHAR2 IS
        l_num     NUMBER;
        l_opinion therapeutic_decision_det.flg_opinion%TYPE;
    BEGIN
        g_error := 'COUNT DECISION VALIDATION';
        SELECT COUNT(1)
          INTO l_num
          FROM therapeutic_decision thd, therapeutic_decision_det thdd
         WHERE thd.id_therapeutic_decision = thdd.id_therapeutic_decision
           AND thd.id_therapeutic_decision = i_id_th_decision
           AND i_professional IN (SELECT id_professional
                                    FROM therapeutic_decision_det
                                   WHERE id_therapeutic_decision = i_id_th_decision)
           AND thdd.flg_status = g_flg_status_a
           AND nvl(thdd.flg_opinion, g_no) = g_no
           AND thdd.flg_presence = g_flg_presence_p;
    
        IF l_num > 0
        THEN
            -- determine if the professional already agree with the decision
            --  SELECT flg_opinion
            --    INTO l_opinion
            --    FROM therapeutic_decision thd, therapeutic_decision_det thdd
            --   WHERE thd.id_therapeutic_decision = thdd.id_therapeutic_decision
            --     AND thd.id_therapeutic_decision = i_id_th_decision
            --     AND thdd.id_professional = i_professional
            --     AND thdd.flg_status = g_flg_status_a
            --     AND thdd.flg_presence = g_flg_presence_r;
            --  IF nvl(l_opinion, g_no) = g_yes
            --  THEN
            RETURN g_yes;
            --  ELSE
            --      RETURN g_no;
            --  END IF;
        ELSE
            RETURN g_no;
        END IF;
    END get_prof_in_consult;

    /**********************************************************************************************
    * Gets the detail of a therapeutic decisions
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_patient               ID Patient   
    * @param i_episode               ID Episode
    * @param i_id_the_decision       ID therapeutic decision
    *
    * @param o_thdecision            Cursor with the information of register and therapeutic decision
    * @param o_thdecision_prof       Cursor with the information of the professionals
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/06/23
    **********************************************************************************************/

    FUNCTION get_th_dec_summary_det
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_id_the_decision IN therapeutic_decision.id_therapeutic_decision%TYPE,
        o_thdecision      OUT pk_types.cursor_type,
        o_thdecision_prof OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_th_decision_title sys_message.desc_message%TYPE;
        l_th_presence_title sys_message.desc_message%TYPE;
        l_created           sys_message.desc_message%TYPE;
        l_edited            sys_message.desc_message%TYPE;
    BEGIN
    
        --*RV FALTA - EM VEZ DA ESPECIALIDADE DO MÉDICO DEVE SER O TIPO DE CONSULTA DO AGENDAMENTO
    
        l_th_decision_title := pk_message.get_message(i_lang => i_lang, i_code_mess => 'THERAPEUTIC_DECISION_T002') || ':';
        l_th_presence_title := pk_message.get_message(i_lang => i_lang, i_code_mess => 'THERAPEUTIC_DECISION_T004');
        l_created           := pk_message.get_message(i_lang => i_lang, i_code_mess => 'THERAPEUTIC_DECISION_T011');
        l_edited            := pk_message.get_message(i_lang => i_lang, i_code_mess => 'THERAPEUTIC_DECISION_T012');
    
        g_error := 'OPEN  o_thdecision';
        OPEN o_thdecision FOR
            SELECT id_therapeutic_decision,
                   dt_creation,
                   dt_register,
                   id_professional,
                   nick_name,
                   desc_speciality,
                   flg_current_episode,
                   decode(id_parent, NULL, l_created, l_edited) th_decision_title,
                   l_th_decision_title decision_title,
                   therapeutic_decision,
                   id_prof_resp,
                   l_th_presence_title presence_title
              FROM (SELECT id_therapeutic_decision,
                           pk_date_utils.dt_chr_date_hour_tsz(i_lang, thd.dt_creation, i_prof) dt_register,
                           id_professional,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, thd.id_professional) nick_name,
                           (SELECT pk_schedule_common.get_translation_alias(i_lang,
                                                                            i_prof,
                                                                            se.id_sch_event,
                                                                            se.code_sch_event)
                              FROM epis_info ei, schedule s, sch_event se
                             WHERE ei.id_episode = thd.id_episode
                               AND ei.id_schedule = s.id_schedule
                               AND s.id_sch_event = se.id_sch_event) desc_speciality,
                           decode(thd.id_episode, i_episode, g_yes, g_no) flg_current_episode,
                           thd.therapeutic_decision,
                           get_prof_responsible(thd.id_episode) id_prof_resp,
                           thd.dt_creation,
                           thd.id_parent
                      FROM therapeutic_decision thd
                     WHERE thd.id_therapeutic_decision IN
                           (SELECT thd2.id_therapeutic_decision
                              FROM therapeutic_decision thd2
                             START WITH id_therapeutic_decision = i_id_the_decision
                            CONNECT BY PRIOR thd2.id_parent = thd2.id_therapeutic_decision))
             ORDER BY dt_creation DESC;
    
        g_error := 'OPEN  o_thdecision_prof';
        -- list of professional in the consult
        OPEN o_thdecision_prof FOR
            SELECT thdd.id_therapeutic_decision,
                   thdd.id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, thdd.id_professional) name_profissional,
                   pk_sysdomain.get_domain(g_flg_presence, thdd.flg_presence, i_lang) presence,
                   pk_sysdomain.get_domain(g_flg_opinion, thdd.flg_opinion, i_lang) opinion,
                   g_no flg_red
            --    decode(thdd.id_professional, i_prof.id, g_yes, g_no) flg_red
              FROM therapeutic_decision thd, therapeutic_decision_det thdd
             WHERE thd.id_therapeutic_decision IN
                   (SELECT thd2.id_therapeutic_decision
                      FROM therapeutic_decision thd2
                     START WITH id_therapeutic_decision = i_id_the_decision
                    CONNECT BY PRIOR thd2.id_parent = thd2.id_therapeutic_decision)
               AND thd.id_therapeutic_decision = thdd.id_therapeutic_decision
               AND thdd.flg_status = g_flg_status_a
             ORDER BY thd.dt_creation DESC, name_profissional;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'GET_TH_DEC_SUMMARY_DET',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_thdecision);
            pk_types.open_my_cursor(o_thdecision_prof);
            RETURN FALSE;
        
    END get_th_dec_summary_det;

    /**********************************************************************************************
    * Create / Edit a therapeutic decision
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_patient               ID Patient   
    * @param i_episode               ID Episode
    * @param i_id_the_decision       ID therapeutic decision (in case of edit)
    * @param i_therapeutic_decision  Therapeutic decision
    * @param i_prof_list             List of professionals
    * @param i_status_list           List of status of witch professional
    * @param i_validation_list       List of validation of witch professional
    *
    * @param o_id_the_decision       ID of therapeutic decision created/edited
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/06/23
    **********************************************************************************************/
    FUNCTION create_th_decision
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_patient              IN patient.id_patient%TYPE,
        i_episode              IN episode.id_episode%TYPE,
        i_id_the_decision      IN therapeutic_decision.id_therapeutic_decision%TYPE,
        i_therapeutic_decision IN therapeutic_decision.therapeutic_decision%TYPE,
        i_prof_list            IN table_number,
        i_status_list          IN table_varchar,
        i_validation_list      IN table_varchar,
        o_id_the_decision      OUT therapeutic_decision.id_therapeutic_decision%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rows table_varchar;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'CALL TS_THERAPEUTIC_DECISION.INS';
        ts_therapeutic_decision.ins(id_patient_in               => i_patient,
                                    id_episode_in               => i_episode,
                                    therapeutic_decision_in     => i_therapeutic_decision,
                                    dt_creation_in              => g_sysdate_tstz,
                                    flg_status_in               => g_flg_status_a,
                                    id_professional_in          => i_prof.id,
                                    id_parent_in                => i_id_the_decision,
                                    id_therapeutic_decision_out => o_id_the_decision,
                                    rows_out                    => l_rows);
    
        IF i_id_the_decision IS NOT NULL -- edit a therapeutic decision
        THEN
            g_error := 'CALL TS_THERAPEUTIC_DECISION.UPD';
            ts_therapeutic_decision.upd(id_therapeutic_decision_in => i_id_the_decision,
                                        flg_status_in              => g_flg_status_o,
                                        rows_out                   => l_rows);
        
        END IF;
    
        l_rows := table_varchar();
        IF i_prof_list.count > 0 -- register the professionals
        THEN
            FOR i IN i_prof_list.first .. i_prof_list.last
            LOOP
                g_error := 'CALL TS_THERAPEUTIC_DECISION_DET.INS';
                ts_therapeutic_decision_det.ins(id_therapeutic_decision_in => o_id_the_decision,
                                                id_professional_in         => i_prof_list(i),
                                                flg_status_in              => g_flg_status_a,
                                                dt_creation_in             => g_sysdate_tstz,
                                                flg_presence_in            => i_status_list(i),
                                                dt_presence_in             => g_sysdate_tstz,
                                                id_prof_presence_in        => i_prof.id,
                                                flg_leader_in              => CASE i_prof_list(i)
                                                                                  WHEN i_prof.id THEN
                                                                                   g_yes
                                                                                  ELSE
                                                                                   g_no
                                                                              END,
                                                flg_opinion_in             => CASE i_status_list(i)
                                                                                  WHEN g_flg_presence_p THEN
                                                                                   nvl(i_validation_list(i),
                                                                                       g_flg_opinion_n)
                                                                                  ELSE
                                                                                   NULL
                                                                              END,
                                                dt_opinion_in              => CASE i_validation_list(i)
                                                                                  WHEN NULL THEN
                                                                                   NULL
                                                                                  ELSE
                                                                                   g_sysdate_tstz
                                                                              END,
                                                rows_out                   => l_rows);
            END LOOP;
        
        END IF;
        g_error := 'CALL PK_VISIT.SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => i_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            RAISE g_exception;
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
                                              'CREATE_TH_DECISION',
                                              o_error);
            pk_utils.undo_changes;
        
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END create_th_decision;

    /**********************************************************************************************
    * Gets the list of professional scheduled for the consult
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_patient               ID Patient
    * @param i_episode               ID Episode
    *
    * @param o_list_professional     Cursor with the list of professionals for the consultation
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/06/25
    **********************************************************************************************/
    FUNCTION get_professional_list
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_patient           IN patient.id_patient%TYPE,
        i_episode           IN episode.id_episode%TYPE,
        o_list_professional OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        --*RV verificar se está correcto 
        g_error := 'OPEN o_list_professional ';
    
        OPEN o_list_professional FOR
            SELECT DISTINCT sr.id_professional,
                            sr.flg_leader,
                            pk_profphoto.get_prof_photo(profissional(sr.id_professional,
                                                                     i_prof.institution,
                                                                     i_prof.software)) prof_photo,
                            pk_prof_utils.get_name_signature(i_lang, i_prof, sr.id_professional) nick_name,
                            pk_prof_utils.get_spec_signature(i_lang,
                                                             i_prof,
                                                             sr.id_professional,
                                                             sr.dt_sch_resource_tstz,
                                                             NULL) desc_speciality,
                            u.login,
                            pi.num_mecan
              FROM epis_info ei, schedule s, sch_resource sr, ab_user_info u, prof_institution pi
             WHERE ei.id_episode = i_episode
               AND ei.id_patient = i_patient
               AND ei.id_schedule = s.id_schedule
               AND s.id_schedule = sr.id_schedule
               AND sr.id_professional = u.id_ab_user_info
               AND sr.id_professional = pi.id_professional
               AND pi.id_institution = i_prof.institution
               AND pi.flg_state = g_flg_active
             ORDER BY nick_name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'GET_PROFESSIONAL_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_list_professional);
            RETURN FALSE;
        
    END get_professional_list;

    /**********************************************************************************************
    * Gets the name of professional that is the responsible for the consult
    *
    * @param i_episode               ID Episode
    *
    *
    * @return                        Returns the name of the professional that is the responsible
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/06/25
    **********************************************************************************************/
    FUNCTION get_prof_name_resp
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR2 IS
        l_prof_resp VARCHAR2(200);
        l_num       NUMBER;
    BEGIN
    
        IF i_episode IS NOT NULL
        THEN
            SELECT COUNT(1) -- verificar se já existe registo de decisão terapêutica
              INTO l_num
              FROM therapeutic_decision
             WHERE id_episode = i_episode;
            IF l_num = 0 -- Não existe(ir buscar o profissional responsável registado no agendamento)
            THEN
                SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, sr.id_professional)
                  INTO l_prof_resp
                  FROM epis_info ei, schedule s, sch_resource sr
                 WHERE ei.id_episode = i_episode
                   AND ei.id_schedule = s.id_schedule
                   AND s.id_schedule = sr.id_schedule
                   AND sr.flg_leader = g_yes;
            ELSE
                SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, thdd.id_professional)
                  INTO l_prof_resp
                  FROM therapeutic_decision thd, therapeutic_decision_det thdd
                 WHERE thd.id_episode = i_episode
                   AND thd.flg_status = g_flg_status_a
                   AND thd.id_therapeutic_decision = thdd.id_therapeutic_decision
                   AND thdd.flg_status = g_flg_status_a
                   AND thdd.flg_leader = g_yes;
            END IF;
        ELSE
            SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, sr.id_professional)
              INTO l_prof_resp
              FROM schedule s, sch_resource sr
             WHERE s.id_schedule = i_schedule
               AND s.id_schedule = sr.id_schedule
               AND sr.flg_leader = g_yes;
        END IF;
        RETURN l_prof_resp;
    END get_prof_name_resp;

    /**********************************************************************************************
    * Gets the information of a therapeutic decisions
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_patient               ID Patient   
    * @param i_episode               ID Episode
    * @param i_id_the_decision       ID therapeutic decision
    *
    * @param o_thdecision            Cursor with the information of register and therapeutic decision
    * @param o_thdecision_prof       Cursor with the information of the professionals
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/06/26
    **********************************************************************************************/
    FUNCTION get_therapeutic_decision
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_id_the_decision IN therapeutic_decision.id_therapeutic_decision%TYPE,
        o_thdecision      OUT pk_types.cursor_type,
        o_thdecision_prof OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := ' OPEN  o_thdecision';
        OPEN o_thdecision FOR
            SELECT thd.id_therapeutic_decision, thd.therapeutic_decision
              FROM therapeutic_decision thd
             WHERE thd.id_therapeutic_decision = i_id_the_decision;
    
        g_error := ' OPEN  o_thdecision';
        OPEN o_thdecision_prof FOR
            SELECT DISTINCT thdd.id_professional,
                            pk_profphoto.get_prof_photo(profissional(thdd.id_professional,
                                                                     i_prof.institution,
                                                                     i_prof.software)) prof_photo,
                            pk_prof_utils.get_name_signature(i_lang, i_prof, thdd.id_professional) nick_name,
                            pk_prof_utils.get_spec_signature(i_lang,
                                                             i_prof,
                                                             thdd.id_professional,
                                                             thdd.dt_creation,
                                                             thd.id_episode) desc_speciality,
                            thdd.flg_presence,
                            pk_sysdomain.get_domain(g_flg_presence, thdd.flg_presence, i_lang) presence,
                            thdd.flg_opinion,
                            pk_sysdomain.get_domain(g_flg_opinion, thdd.flg_opinion, i_lang) opinion,
                            thdd.flg_leader,
                            u.login,
                            pi.num_mecan
              FROM therapeutic_decision thd, therapeutic_decision_det thdd, ab_user_info u, prof_institution pi
             WHERE thd.id_therapeutic_decision = thdd.id_therapeutic_decision
               AND thdd.flg_status = g_flg_status_a
               AND thd.id_therapeutic_decision = i_id_the_decision
               AND thdd.id_professional = u.id_ab_user_info
               AND thdd.id_professional = pi.id_professional
               AND pi.id_institution = i_prof.institution
               AND pi.flg_state = g_flg_active
             ORDER BY nick_name;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'GET_THERAPEUTIC_DECISION',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_thdecision);
            pk_types.open_my_cursor(o_thdecision_prof);
            RETURN FALSE;
        
    END get_therapeutic_decision;

    /**********************************************************************************************
    * updates the validation of professionals
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_patient               ID Patient   
    * @param i_episode               ID Episode
    * @param i_id_the_decision       ID therapeutic decision (in case of edit)
    * @param i_therapeutic_decision  Therapeutic decision
    * @param i_prof_list             List of professionals
    * @param i_status_list           List of status of witch professional
    * @param i_validation_list       List of validation of witch professional
    *
    * @param o_id_the_decision       ID of therapeutic decision created/edited
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/06/26
    **********************************************************************************************/
    FUNCTION update_prof_opinion
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_id_the_decision IN therapeutic_decision.id_therapeutic_decision%TYPE,
        i_prof_list       IN table_number,
        i_status_list     IN table_varchar,
        i_validation_list IN table_varchar,
        o_id_the_decision OUT therapeutic_decision.id_therapeutic_decision%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rows table_varchar;
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'CALL TS_THERAPEUTIC_DECISION.INS';
        IF i_prof_list.count > 0 -- register the professionals
        THEN
            FOR i IN i_prof_list.first .. i_prof_list.last
            LOOP
                g_error := 'CALL TS_THERAPEUTIC_DECISION_DET.INS';
                ts_therapeutic_decision_det.upd(flg_opinion_in  => nvl(i_validation_list(i), g_flg_opinion_n),
                                                dt_opinion_in   => g_sysdate_tstz,
                                                flg_presence_in => i_status_list(i),
                                                dt_presence_in  => g_sysdate_tstz,
                                                where_in        => ' id_therapeutic_decision = ' || i_id_the_decision ||
                                                                   ' and id_professional = ' || i_prof_list(i) ||
                                                                   ' and flg_status = ''' || g_flg_active || ''' ',
                                                rows_out        => l_rows);
            
            END LOOP;
        
        END IF;
        g_error := 'CALL PK_VISIT.SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => i_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
        RETURN TRUE;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'UPDATE_PROF_OPINION',
                                              o_error);
            pk_utils.undo_changes;
        
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END update_prof_opinion;

    /**********************************************************************************************
    * Gets the possible values for the sys_domain table
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    *
    * @param o_value_opinion         Cursor with the information of the values
    * @param o_value_presence        Cursor with the information of the values    
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Rita Lopes
    * @version                       2.5
    * @since                         2009/07/01
    **********************************************************************************************/
    FUNCTION get_domain_values
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_value_opinion  OUT pk_types.cursor_type,
        o_value_presence OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := ' OPEN  o_thdecision';
        OPEN o_value_opinion FOR
            SELECT sd.val, sd.desc_val, sd.code_domain
              FROM sys_domain sd
             WHERE sd.code_domain = g_flg_opinion
               AND sd.id_language = i_lang
               AND sd.domain_owner = pk_sysdomain.k_default_schema
             ORDER BY sd.rank;
    
        OPEN o_value_presence FOR
            SELECT sd.val, sd.desc_val, sd.code_domain
              FROM sys_domain sd
             WHERE sd.code_domain = g_flg_presence
               AND sd.id_language = i_lang
               AND sd.domain_owner = pk_sysdomain.k_default_schema
             ORDER BY sd.rank;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'GET_DOMAIN_VALUES',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_value_opinion);
            pk_types.open_my_cursor(o_value_presence);
            RETURN FALSE;
        
    END get_domain_values;

BEGIN
    -- Log initialization.
    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);

END pk_therapeutic_decision;
/
