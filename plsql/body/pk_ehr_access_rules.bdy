/*-- Last Change Revision: $Rev: 2027108 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:03 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_ehr_access_rules AS
    /**
    * This package encloses all EHR access rules.
    *
    * @since 2008-05-13
    * @author rui.baeta
    */

    /**
    * Rule number 2: Checks weather there is any open episode for this professional, in his/her environment.
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    * @param i_flg_episode_reopen  flag that tells if an episode is to be reopened (used in EDIS) (Y - episode will be reopened
    *                                                                                              N - episode will NOT be reopened - default)
    * @return                      true if access is granted; false otherwise.
    *
    * @since 2008-05-13
    * @version v2.4.3
    * @author rui.baeta
    */
    FUNCTION ckeck_ongoing_episode
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_flg_episode_reopen IN VARCHAR2,
        i_id_episode         IN episode.id_episode%TYPE
    ) RETURN BOOLEAN AS
        l_has_ongoing_episode VARCHAR2(1) := g_no;
    
        l_grp_insts table_number;
    
        CURSOR c_ongoing(l_insts table_number) IS
            SELECT g_yes
              FROM episode e
             WHERE e.id_patient = i_id_patient
               AND (e.id_institution IN (SELECT *
                                           FROM TABLE(l_insts)) OR
                   pk_transfer_institution.check_transfer_access(e.id_episode, i_prof) = g_yes)
               AND e.flg_status = g_epis_active
               AND e.flg_ehr = g_flg_ehr_normal
               AND rownum <= 1;
    
    BEGIN
        g_error := 'GET INSTITUTIONS GROUP';
        SELECT column_value
          BULK COLLECT
          INTO l_grp_insts
          FROM TABLE(pk_list.tf_get_all_inst_group(i_prof.institution, pk_ehr_access.g_inst_grp_flg_rel_adt));
    
        g_error := 'OPEN c_ongoing';
        OPEN c_ongoing(l_grp_insts);
        FETCH c_ongoing
            INTO l_has_ongoing_episode;
        g_found := c_ongoing%FOUND;
        CLOSE c_ongoing;
    
        RETURN(l_has_ongoing_episode = g_yes);
    
    END ckeck_ongoing_episode;

    /**
    * Rule number 3: Checks weather there is any scheduled episode for this professional, in his/her environment.
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    * @param i_flg_episode_reopen  flag that tells if an episode is to be reopened (used in EDIS) (Y - episode will be reopened
    *                                                                                              N - episode will NOT be reopened - default)
    * @return                      true if access is granted; false otherwise.
    *
    * @since 2008-05-13
    * @version v2.4.3
    * @author rui.baeta
    */
    FUNCTION ckeck_scheduled_episode_me
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_flg_episode_reopen IN VARCHAR2,
        i_id_episode         IN episode.id_episode%TYPE
    ) RETURN BOOLEAN AS
        l_has_sch_episode VARCHAR2(1) := g_no;
    
        CURSOR c_sch IS
            SELECT g_yes
              FROM schedule s
              JOIN sch_group sg
                ON (s.id_schedule = sg.id_schedule)
              JOIN schedule_outp so
                ON (s.id_schedule = so.id_schedule)
              JOIN sch_prof_outp spo
                ON (spo.id_schedule_outp = so.id_schedule_outp)
             WHERE sg.id_patient = i_id_patient
               AND spo.id_professional = i_prof.id
               AND s.flg_status != pk_schedule.g_sched_status_cache -- agendamentos temporários (SCH 3.0)
               AND s.id_schedule NOT IN (SELECT ei.id_schedule
                                           FROM epis_info ei
                                           JOIN episode e
                                             ON (ei.id_episode = e.id_episode)
                                           JOIN visit v
                                             ON (e.id_visit = v.id_visit)
                                          WHERE v.id_patient = i_id_patient
                                            AND e.flg_ehr IN (g_flg_ehr_normal, g_flg_ehr_ehr)
                                            AND ei.id_schedule IS NOT NULL)
            
            UNION
            SELECT g_yes
              FROM episode e
              JOIN visit v
                ON (e.id_visit = v.id_visit)
              JOIN epis_info ei
                ON (ei.id_episode = e.id_episode)
             WHERE v.id_patient = i_id_patient
               AND v.id_institution = i_prof.institution
               AND ei.id_professional = i_prof.id
               AND e.flg_status IN (g_epis_active)
               AND e.flg_ehr = g_flg_ehr_scheduled;
    BEGIN
        g_error := 'OPEN c_sch';
        OPEN c_sch;
        FETCH c_sch
            INTO l_has_sch_episode;
        g_found := c_sch%FOUND;
        CLOSE c_sch;
    
        RETURN(l_has_sch_episode = g_yes);
    
    END ckeck_scheduled_episode_me;

    /**
    * Rule number 4: Checks weather there is any requested episode for this professional, in his/her environment.
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    * @param i_flg_episode_reopen  flag that tells if an episode is to be reopened (used in EDIS) (Y - episode will be reopened
    *                                                                                              N - episode will NOT be reopened - default)
    * @return                      true if access is granted; false otherwise.
    *
    * @since 2008-05-13
    * @version v2.4.3
    * @author rui.baeta
    */
    FUNCTION ckeck_requested_episode
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_flg_episode_reopen IN VARCHAR2,
        i_id_episode         IN episode.id_episode%TYPE
    ) RETURN BOOLEAN AS
        l_has_requests VARCHAR2(1) := g_no;
    
        CURSOR c_requests IS
            SELECT g_yes
              FROM consult_req cr
             INNER JOIN episode e
                ON cr.id_episode = e.id_episode
             WHERE cr.id_patient = i_id_patient
               AND cr.id_prof_req = i_prof.id
               AND cr.flg_status IN (pk_consult_req.g_consult_req_stat_req,
                                     pk_consult_req.g_consult_req_stat_read,
                                     pk_consult_req.g_consult_req_stat_reply,
                                     pk_consult_req.g_consult_req_stat_auth,
                                     pk_consult_req.g_consult_req_stat_apr,
                                     pk_consult_req.g_consult_req_stat_proc)
               AND e.flg_status NOT IN (g_epis_cancelled);
    BEGIN
    
        OPEN c_requests;
        FETCH c_requests
            INTO l_has_requests;
        g_found := c_requests%FOUND;
        CLOSE c_requests;
    
        RETURN(l_has_requests = g_yes);
    
    END ckeck_requested_episode;

    /**
    * Rule number 1 and 5: Checks weather there is authorization from the institution for this professional to access EHR through 'break the glass'.
    * This is a "constant function" as it always returns true. The idea is to customize institution authorization in tables
    * EHR_ACCESS_PROFILE_RULE and/or EHR_ACCESS_PROF_RULE, selecting the intended rule: ckeck_inst_authorization_true or  ckeck_inst_authorization_false.
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    * @param i_flg_episode_reopen  flag that tells if an episode is to be reopened (used in EDIS) (Y - episode will be reopened
    *                                                                                              N - episode will NOT be reopened - default)
    * @return                      always returns true.
    *
    * @since 2008-05-13
    * @version v2.4.3
    * @author rui.baeta
    */
    FUNCTION ckeck_inst_authorization_true
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_flg_episode_reopen IN VARCHAR2,
        i_id_episode         IN episode.id_episode%TYPE
    ) RETURN BOOLEAN AS
    BEGIN
        RETURN TRUE;
    END ckeck_inst_authorization_true;

    /**
    * Rule number 1 and 5: Checks weather there is authorization from the institution for this professional to access EHR through 'break the glass'.
    * This is a "constant function" as it always returns false. The idea is to customize institution authorization in tables
    * EHR_ACCESS_PROFILE_RULE and/or EHR_ACCESS_PROF_RULE, selecting the intended rule: ckeck_inst_authorization_true or  ckeck_inst_authorization_false.
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    * @param i_flg_episode_reopen  flag that tells if an episode is to be reopened (used in EDIS) (Y - episode will be reopened
    *                                                                                              N - episode will NOT be reopened - default)
    * @return                      always returns false.
    *
    * @since 2008-05-13
    * @version v2.4.3
    * @author rui.baeta
    */
    FUNCTION ckeck_inst_authorization_false
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_flg_episode_reopen IN VARCHAR2,
        i_id_episode         IN episode.id_episode%TYPE
    ) RETURN BOOLEAN AS
    BEGIN
        RETURN FALSE;
    END ckeck_inst_authorization_false;

    /**
    * Rule number 6: Checks weather there is any previous (inactive) episode for this professional.
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    * @param i_flg_episode_reopen  flag that tells if an episode is to be reopened (used in EDIS) (Y - episode will be reopened
    *                                                                                              N - episode will NOT be reopened - default)
    * @return                      true if access is granted; false otherwise.
    *
    * @since 2008-05-13
    * @version v2.4.3
    * @author rui.baeta
    */
    FUNCTION ckeck_previous_episode
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_flg_episode_reopen IN VARCHAR2,
        i_id_episode         IN episode.id_episode%TYPE
    ) RETURN BOOLEAN AS
        l_has_previous_episode VARCHAR2(1) := g_no;
    
        l_grp_insts table_number;
    
        CURSOR c_previous(l_insts table_number) IS
            SELECT DISTINCT g_yes
              FROM episode e
             WHERE e.id_patient = i_id_patient
               AND (e.id_institution IN (SELECT *
                                           FROM TABLE(l_insts)) OR
                   pk_transfer_institution.check_transfer_access(e.id_episode, i_prof) = g_yes)
               AND e.flg_status IN (g_epis_inactive, g_epis_pending)
               AND e.flg_ehr = g_flg_ehr_normal;
    BEGIN
        g_error := 'GET INSTITUTIONS GROUP';
        SELECT column_value
          BULK COLLECT
          INTO l_grp_insts
          FROM TABLE(pk_list.tf_get_all_inst_group(i_prof.institution, pk_ehr_access.g_inst_grp_flg_rel_adt));
    
        g_error := 'OPEN C_PREVIOUS';
        OPEN c_previous(l_grp_insts);
        FETCH c_previous
            INTO l_has_previous_episode;
        g_found := c_previous%FOUND;
        CLOSE c_previous;
    
        RETURN(l_has_previous_episode = g_yes);
    
    END ckeck_previous_episode;

    /**
    * Rule number 7: Checks weather there is any scheduled episode for this professional, in the institution environment.
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    * @param i_flg_episode_reopen  flag that tells if an episode is to be reopened (used in EDIS) (Y - episode will be reopened
    *                                                                                              N - episode will NOT be reopened - default)
    * @return                      true if access is granted; false otherwise.
    *
    * @since 2008-05-13
    * @version v2.4.3
    * @author rui.baeta
    */
    FUNCTION ckeck_scheduled_episode_inst
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_flg_episode_reopen IN VARCHAR2,
        i_id_episode         IN episode.id_episode%TYPE
    ) RETURN BOOLEAN AS
        l_has_sch_episode VARCHAR2(1) := g_no;
    
        CURSOR c_sch IS
            SELECT g_yes
              FROM schedule s
              JOIN sch_group sg
                ON (s.id_schedule = sg.id_schedule)
              JOIN schedule_outp so
                ON (s.id_schedule = so.id_schedule)
              JOIN sch_prof_outp spo
                ON (spo.id_schedule_outp = so.id_schedule_outp)
             WHERE sg.id_patient = i_id_patient
               AND s.id_instit_requested = i_prof.institution
               AND s.flg_status != pk_schedule.g_sched_status_cache -- agendamentos temporários (SCH 3.0)
               AND s.id_schedule NOT IN (SELECT ei.id_schedule
                                           FROM epis_info ei
                                           JOIN episode e
                                             ON (ei.id_episode = e.id_episode)
                                           JOIN visit v
                                             ON (e.id_visit = v.id_visit)
                                          WHERE v.id_patient = i_id_patient
                                            AND e.flg_ehr IN (g_flg_ehr_normal, g_flg_ehr_ehr)
                                            AND ei.id_schedule IS NOT NULL)
            
            UNION
            SELECT g_yes
              FROM episode e
              JOIN visit v
                ON (e.id_visit = v.id_visit)
              JOIN epis_info ei
                ON (ei.id_episode = e.id_episode)
             WHERE v.id_patient = i_id_patient
               AND v.id_institution = i_prof.institution
               AND e.flg_status IN (g_epis_active)
               AND e.flg_ehr = g_flg_ehr_scheduled;
    BEGIN
    
        g_error := 'OPEN c_sch';
        OPEN c_sch;
        FETCH c_sch
            INTO l_has_sch_episode;
        g_found := c_sch%FOUND;
        CLOSE c_sch;
    
        RETURN(l_has_sch_episode = g_yes);
    
    END ckeck_scheduled_episode_inst;

    /**
    * Rule number 8: Checks weather this professional is trying to (legally) reopen an episode.
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    * @param i_flg_episode_reopen  flag that tells if an episode is to be reopened (used in EDIS) (Y - episode will be reopened
    *                                                                                              N - episode will NOT be reopened - default)
    * @return                      true if access is granted; false otherwise.
    *
    * @since 2008-05-13
    * @version v2.4.3
    * @author rui.baeta
    */
    FUNCTION ckeck_reopen_episode
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_flg_episode_reopen IN VARCHAR2,
        i_id_episode         IN episode.id_episode%TYPE
    ) RETURN BOOLEAN AS
    BEGIN
        RETURN(i_flg_episode_reopen = g_yes);
    END ckeck_reopen_episode;

    /**
    * Rule number 9: Checks if this patient doesnt have clinical information or appointments (episode/schedule)
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    * @param i_flg_episode_reopen  flag that tells if an episode is to be reopened (used in EDIS) (Y - episode will be reopened
    *                                                                                              N - episode will NOT be reopened - default)
    * 
    * @param return  flag that tells if the patient doesnt has clinical info (Y - doesnt have
    *                                                                         N - the patient has clinical info)
    *
    * @since 2008-05-28
    * @version v2.4.3
    * @author Sérgio Santos
    */
    FUNCTION ckeck_pat_empty_clin_info
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_flg_episode_reopen IN VARCHAR2,
        i_id_episode         IN episode.id_episode%TYPE
    ) RETURN BOOLEAN AS
        l_has_clin_info VARCHAR2(1) := g_no;
    
        CURSOR c_clin_info IS
            SELECT g_yes
              FROM episode e
              JOIN visit v
                ON (v.id_visit = e.id_visit)
             WHERE v.id_patient = i_id_patient
               AND e.flg_ehr = g_flg_ehr_normal
               AND e.flg_status != g_epis_cancelled
            UNION
            SELECT g_yes
              FROM schedule s
              JOIN sch_group sg
                ON (sg.id_schedule = s.id_schedule)
             WHERE sg.id_patient = i_id_patient
               AND s.flg_status != pk_schedule.g_sched_status_cache; -- agendamentos temporários (SCH 3.0)
    
    BEGIN
        g_error := 'OPEN c_sch';
        OPEN c_clin_info;
        FETCH c_clin_info
            INTO l_has_clin_info;
        g_found := c_clin_info%FOUND;
        CLOSE c_clin_info;
    
        RETURN(l_has_clin_info <> g_yes);
    END ckeck_pat_empty_clin_info;

    /**
    * Rule number 10: Checks weather if an episode is active and not assigned to any professional instead of the current one
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    * @param i_flg_episode_reopen  flag that tells if an episode is to be reopened (used in EDIS) (Y - episode will be reopened
    *                                                                                              N - episode will NOT be reopened - default)
    * @param i_episode             episode id
    *
    * @return                      true if access is granted; false otherwise.
    *
    * @since 2009-02-06
    * @version v2.4.3
    * @author sergio.santos
    */
    FUNCTION ckeck_active_episode_with_me
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_flg_episode_reopen IN VARCHAR2,
        i_id_episode         IN episode.id_episode%TYPE
    ) RETURN BOOLEAN AS
    
        l_error     t_error_out;
        l_prof      epis_info.id_professional%TYPE;
        l_prof_name professional.nick_name%TYPE;
        l_flg_type  category.flg_type%TYPE;
    
        l_grp_insts table_number := table_number();
        --   
        CURSOR c_category IS
            SELECT cat.flg_type
              FROM prof_cat pc, category cat
             WHERE pc.id_professional = i_prof.id
               AND pc.id_institution = i_prof.institution
               AND cat.id_category = pc.id_category
               AND flg_available = pk_visit.g_category_avail
               AND flg_prof = pk_visit.g_cat_prof;
        --
        -- Determinar o profissional responsável pela paciente de acordo com a categoria profissional
        -- pretendida (médico e enfermeiro). Para as restantes categorias é retornado null
        CURSOR c_epis_info(l_flg_type IN category.flg_type%TYPE) IS
            SELECT decode(l_flg_type,
                          pk_visit.g_cat_type_doc,
                          ei.id_professional,
                          pk_visit.g_cat_type_nurse,
                          ei.id_first_nurse_resp,
                          NULL),
                   p.nick_name
              FROM epis_info ei, professional p
             WHERE ei.id_episode = i_id_episode
               AND decode(l_flg_type,
                          pk_visit.g_cat_type_doc,
                          ei.id_professional,
                          pk_visit.g_cat_type_nurse,
                          ei.id_first_nurse_resp,
                          NULL) = p.id_professional(+);
    
        l_is_ongoing_episode VARCHAR2(1) := g_no;
    
        l_hand_off_type VARCHAR2(1);
    
        CURSOR c_ongoing(l_insts table_number) IS
            SELECT g_yes
              FROM episode e
             WHERE e.id_patient = i_id_patient
               AND (e.id_institution IN (SELECT *
                                           FROM TABLE(l_insts)) OR
                   pk_transfer_institution.check_transfer_access(e.id_episode, i_prof) = g_yes)
               AND e.flg_status = g_epis_active
               AND e.flg_ehr = g_flg_ehr_normal
               AND e.id_episode = i_id_episode;
    
        l_ehr_access_consultation  sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf => 'EHR_ACCESS_CONSULTATION',
                                                                                    i_prof    => i_prof);
        l_has_consultation_request VARCHAR2(1 CHAR);
        l_ehr_access_followup      sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf => 'EHR_ACCESS_FOLLOW_UP',
                                                                                    i_prof    => i_prof);
        l_has_follow_up_request    VARCHAR2(1 CHAR);
    
    BEGIN
        g_error := 'GET INSTITUTIONS GROUP';
        --SELECT column_value
        --BULK COLLECT INTO l_grp_insts
        -- FROM TABLE(pk_list.tf_get_all_inst_group(i_prof.institution, pk_ehr_access.g_inst_grp_flg_rel_adt));
    
        l_grp_insts := pk_list.tf_get_all_inst_group(i_prof.institution, pk_ehr_access.g_inst_grp_flg_rel_adt);
    
        g_error := 'OPEN c_ongoing';
        OPEN c_ongoing(l_grp_insts);
        FETCH c_ongoing
            INTO l_is_ongoing_episode;
        g_found := c_ongoing%FOUND;
        CLOSE c_ongoing;
    
        IF i_id_episode IS NULL
		   --CMF
           --OR l_is_ongoing_episode = g_no
        THEN
            RETURN FALSE;
        ELSE
            IF l_ehr_access_consultation = pk_alert_constant.g_no -- not shown pop-up if exists a consultation 
            THEN
                -- a consultation exists
                IF pk_opinion.check_opinion_prof(i_lang => i_lang, i_prof => i_prof, i_id_episode => i_id_episode) =
                   pk_alert_constant.g_yes
                THEN
                    RETURN FALSE;
                END IF;
            END IF;
            IF l_ehr_access_followup = pk_alert_constant.g_no -- not shown pop-up if exists a FOLLOWUP REQUEST
            THEN
                -- a followup request exists
                IF pk_opinion.check_follow_up_prof(i_lang => i_lang, i_prof => i_prof, i_id_episode => i_id_episode) =
                   pk_alert_constant.g_yes
                THEN
                    RETURN FALSE;
                END IF;
            END IF;
            -- Get the type of hand off - (M)ultiple, (N)ormal
            g_error := 'PK_HAND_OFF_CORE.GET_HAND_OFF_TYPE';
            pk_hand_off_core.get_hand_off_type(i_lang => i_lang, i_prof => i_prof, io_hand_off_type => l_hand_off_type);
        
						IF pk_utils.search_table_number(pk_hand_off_core.get_responsibles_id(i_lang          => i_lang,
																																								 i_prof          => i_prof,
																																								 i_id_episode    => i_id_episode,
																																								 i_prof_cat      => pk_prof_utils.get_category(i_lang => i_lang,
																																																															 i_prof => i_prof),
																																								 i_hand_off_type => l_hand_off_type),
																						i_prof.id) != -1
						THEN
								RETURN FALSE;
            ELSE
                -- Categoria do profissional
                g_error := 'GET CURSOR C_CATEGORY';
                OPEN c_category;
                FETCH c_category
                    INTO l_flg_type;
                CLOSE c_category;
                --
                g_error := 'GET CURSOR C_EPIS_INFO';
                OPEN c_epis_info(l_flg_type);
                FETCH c_epis_info
                    INTO l_prof, l_prof_name;
                CLOSE c_epis_info;
            
				/*
                IF l_prof IS NULL
                THEN
                    RETURN FALSE; --não está ninguem responsável pelo episódio
                ELSE
                    RETURN TRUE; -- o episódio não é meu e está outro profissional responsável.
                END IF;
				*/
				return true;
            
            END IF;
        END IF;
    
        RETURN(FALSE);
    
    END;

    /**
    * Rule number 11: Checks weather if an episode is inactive and not assigned to any professional instead of the current one
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    * @param i_flg_episode_reopen  flag that tells if an episode is to be reopened (used in EDIS) (Y - episode will be reopened
    *                                                                                              N - episode will NOT be reopened - default)
    * @param i_episode             episode id
    *
    * @return                      true if access is granted; false otherwise.
    *
    * @since 2009-02-09
    * @version v2.4.3
    * @author sergio.santos
    */
    FUNCTION ckeck_inactive_episode_with_me
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_flg_episode_reopen IN VARCHAR2,
        i_id_episode         IN episode.id_episode%TYPE
    ) RETURN BOOLEAN AS
    
        l_garbage   VARCHAR2(2000);
        l_error     VARCHAR2(2000);
        l_prof      epis_info.id_professional%TYPE;
        l_prof_name professional.nick_name%TYPE;
        l_flg_type  category.flg_type%TYPE;
    
        l_grp_insts table_number;
    
        l_flg_show VARCHAR(1);
        --   
        CURSOR c_category IS
            SELECT cat.flg_type
              FROM prof_cat pc, category cat
             WHERE pc.id_professional = i_prof.id
               AND pc.id_institution = i_prof.institution
               AND cat.id_category = pc.id_category
               AND flg_available = pk_visit.g_category_avail
               AND flg_prof = pk_visit.g_cat_prof;
        --
        -- Determinar o profissional responsável pela paciente de acordo com a categoria profissional
        -- pretendida (médico e enfermeiro). Para as restantes categorias é retornado null
        CURSOR c_epis_info(l_flg_type IN category.flg_type%TYPE) IS
            SELECT decode(l_flg_type,
                          pk_visit.g_cat_type_doc,
                          ei.id_professional,
                          pk_visit.g_cat_type_nurse,
                          ei.id_first_nurse_resp,
                          NULL),
                   p.nick_name
              FROM epis_info ei, professional p
             WHERE ei.id_episode = i_id_episode
               AND decode(l_flg_type,
                          pk_visit.g_cat_type_doc,
                          ei.id_professional,
                          pk_visit.g_cat_type_nurse,
                          ei.id_first_nurse_resp,
                          NULL) = p.id_professional(+);
    
        l_is_inactive_episode VARCHAR2(1) := g_no;
    
        l_hand_off_type VARCHAR2(1);
    
        CURSOR c_previous(l_insts table_number) IS
            SELECT g_yes
              FROM episode e
             WHERE e.id_patient = i_id_patient
               AND (e.id_institution IN (SELECT *
                                           FROM TABLE(l_insts)) OR
                   pk_transfer_institution.check_transfer_access(e.id_episode, i_prof) = g_yes)
               AND e.flg_status IN (g_epis_inactive, g_epis_pending)
               AND e.flg_ehr = g_flg_ehr_normal
               AND e.id_episode = i_id_episode;
    
    BEGIN
        g_error := 'GET INSTITUTIONS GROUP';
        SELECT column_value
          BULK COLLECT
          INTO l_grp_insts
          FROM TABLE(pk_list.tf_get_all_inst_group(i_prof.institution, pk_ehr_access.g_inst_grp_flg_rel_adt));
    
        g_error := 'OPEN c_previous';
        OPEN c_previous(l_grp_insts);
        FETCH c_previous
            INTO l_is_inactive_episode;
        g_found := c_previous%FOUND;
        CLOSE c_previous;
    
        IF i_id_episode IS NULL
           OR l_is_inactive_episode = g_no
        THEN
            RETURN FALSE;
        ELSE
            -- Get the type of hand off - (M)ultiple, (N)ormal
            g_error := 'PK_HAND_OFF_CORE.GET_HAND_OFF_TYPE';
            pk_hand_off_core.get_hand_off_type(i_lang => i_lang, i_prof => i_prof, io_hand_off_type => l_hand_off_type);
        
						IF pk_utils.search_table_number(pk_hand_off_core.get_responsibles_id(i_lang          => i_lang,
																																								 i_prof          => i_prof,
																																								 i_id_episode    => i_id_episode,
																																								 i_prof_cat      => pk_prof_utils.get_category(i_lang => i_lang,
																																																															 i_prof => i_prof),
																																								 i_hand_off_type => l_hand_off_type),
																						i_prof.id) != -1
						THEN
								RETURN FALSE;
						END IF;
        
            -- Categoria do profissional
            g_error := 'GET CURSOR C_CATEGORY';
            OPEN c_category;
            FETCH c_category
                INTO l_flg_type;
            CLOSE c_category;
            --
            g_error := 'GET CURSOR C_EPIS_INFO';
            OPEN c_epis_info(l_flg_type);
            FETCH c_epis_info
                INTO l_prof, l_prof_name;
            CLOSE c_epis_info;
        
            IF l_prof IS NULL --não está ninguem responsável pelo episódio
            THEN
                RETURN TRUE;
            ELSIF l_prof != i_prof.id -- o episódio não é meu e está outro profissional responsável.
            THEN
                RETURN TRUE;
            ELSIF l_prof = i_prof.id -- o episódio foi da minha responsabilidade.
            THEN
                RETURN FALSE;
            END IF;
        END IF;
    
        RETURN(FALSE);
    
    END;

    /**
    * Rule number 13: Checks weather if an episode is signed-off
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    * @param i_flg_episode_reopen  flag that tells if an episode is to be reopened (used in EDIS) (Y - episode will be reopened
    *                                                                                              N - episode will NOT be reopened - default)
    * @param i_episode             episode id
    *
    * @return                      true if access is granted; false otherwise.
    *
    * @since 2010-10-25
    * @version v2.5.1.2
    * @author sergio.santos
    */
    FUNCTION ckeck_signed_off_episode
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_flg_episode_reopen IN VARCHAR2,
        i_id_episode         IN episode.id_episode%TYPE
    ) RETURN BOOLEAN AS
        l_epis_signed_off VARCHAR2(1 CHAR);
        l_error           t_error_out;
    BEGIN
        IF i_id_episode IS NULL
        THEN
            RETURN FALSE;
        ELSE
            g_error := 'PK_SIGN_OFF.GET_EPIS_SIGN_OFF_STATE';
            IF NOT pk_sign_off.get_epis_sign_off_state(i_lang     => i_lang,
                                                       i_prof     => i_prof,
                                                       i_episode  => i_id_episode,
                                                       o_sign_off => l_epis_signed_off,
                                                       o_error    => l_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
    
        RETURN(l_epis_signed_off = pk_alert_constant.g_yes);
    END;

    /**
    * Rule number 14: Meaningfull use - Check if the professional has Emergency access on active episodes
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    * @param i_flg_episode_reopen  flag that tells if an episode is to be reopened (used in EDIS) (Y - episode will be reopened
    * @param i_episode             episode id
    *
    * @return                      true if access is granted; false otherwise.
    *
    * @since 2011-05-07
    * @version v2.6.1.0.1
    * @author sergio.santos
    */
    FUNCTION ckeck_emerg_access
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_flg_episode_reopen IN VARCHAR2,
        i_id_episode         IN episode.id_episode%TYPE
    ) RETURN BOOLEAN AS
        l_is_assigned      VARCHAR2(1 CHAR);
        l_has_emerg_access VARCHAR2(1 CHAR);
    
        l_hand_off_type VARCHAR2(1);
    BEGIN
        --check if the professional is reponsible for the episode
        -- Get the type of hand off - (M)ultiple, (N)ormal
        g_error := 'PK_HAND_OFF_CORE.GET_HAND_OFF_TYPE';
        pk_hand_off_core.get_hand_off_type(i_lang => i_lang, i_prof => i_prof, io_hand_off_type => l_hand_off_type);
    
        IF pk_utils.search_table_number(pk_hand_off_core.get_responsibles_id(i_lang          => i_lang,
                                                                             i_prof          => i_prof,
                                                                             i_id_episode    => i_id_episode,
                                                                             i_prof_cat      => pk_prof_utils.get_category(i_lang => i_lang,
                                                                                                                           i_prof => i_prof),
                                                                             i_hand_off_type => l_hand_off_type,
                                                                             i_my_patients   => 'Y'),
                                        i_prof.id) != -1
        THEN
            RETURN FALSE;
        END IF;
    
        --check if the professional has emergency access permissions
        BEGIN
            SELECT DISTINCT pk_alert_constant.g_yes
              INTO l_has_emerg_access
              FROM prof_func pf, sys_functionality sf
             WHERE pf.id_professional = i_prof.id
               AND pf.id_institution = i_prof.institution
               AND sf.id_software IN (i_prof.software, 0)
               AND sf.id_functionality = pf.id_functionality
               AND sf.flg_available = pk_alert_constant.g_available
               AND sf.id_functionality IN (24, 25, 26); --emergency access
        EXCEPTION
            WHEN no_data_found THEN
                l_has_emerg_access := pk_alert_constant.g_no;
        END;
    
        --if doesnt has emergency access then the rule is true
        IF l_has_emerg_access = pk_alert_constant.g_no
        THEN
            RETURN TRUE;
        END IF;
    
        RETURN FALSE;
    END;

    /**
    * Rule number 15: Meaningfull use - Check if the professional has Emergency access on active episodes (BTG)
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    * @param i_flg_episode_reopen  flag that tells if an episode is to be reopened (used in EDIS) (Y - episode will be reopened
    * @param i_episode             episode id
    *
    * @return                      true if access is granted; false otherwise.
    *
    * @since 2011-05-07
    * @version v2.6.1.0.1
    * @author sergio.santos
    */
    FUNCTION ckeck_emerg_access_phase2
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_flg_episode_reopen IN VARCHAR2,
        i_id_episode         IN episode.id_episode%TYPE
    ) RETURN BOOLEAN AS
        l_is_assigned      VARCHAR2(1 CHAR);
        l_has_emerg_access VARCHAR2(1 CHAR);
    
        l_hand_off_type VARCHAR2(1);
    BEGIN
        --check if the professional is reponsible for the episode
        -- Get the type of hand off - (M)ultiple, (N)ormal
        g_error := 'PK_HAND_OFF_CORE.GET_HAND_OFF_TYPE';
        pk_hand_off_core.get_hand_off_type(i_lang => i_lang, i_prof => i_prof, io_hand_off_type => l_hand_off_type);
    
        IF pk_utils.search_table_number(pk_hand_off_core.get_responsibles_id(i_lang          => i_lang,
                                                                             i_prof          => i_prof,
                                                                             i_id_episode    => i_id_episode,
                                                                             i_prof_cat      => pk_prof_utils.get_category(i_lang => i_lang,
                                                                                                                           i_prof => i_prof),
                                                                             i_hand_off_type => l_hand_off_type,
                                                                             i_my_patients   => 'Y'),
                                        i_prof.id) != -1
        THEN
            RETURN FALSE;
        END IF;
    
        --check if the professional has emergency access permissions
        BEGIN
            SELECT DISTINCT pk_alert_constant.g_yes
              INTO l_has_emerg_access
              FROM prof_func pf, sys_functionality sf
             WHERE pf.id_professional = i_prof.id
               AND pf.id_institution = i_prof.institution
               AND sf.id_software IN (i_prof.software, 0)
               AND sf.id_functionality = pf.id_functionality
               AND sf.flg_available = pk_alert_constant.g_available
               AND sf.id_functionality IN (24, 25, 26); --emergency access
        EXCEPTION
            WHEN no_data_found THEN
                l_has_emerg_access := pk_alert_constant.g_no;
        END;
    
        --if doesnt has emergency access then the rule is true
        IF l_has_emerg_access = pk_alert_constant.g_yes
        THEN
            RETURN TRUE;
        END IF;
    
        RETURN FALSE;
    END;

    /**
    * Generic rule: always returns true. Input arguments are ignored.
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    * @param i_flg_episode_reopen  flag that tells if an episode is to be reopened (used in EDIS) (Y - episode will be reopened
    *                                                                                              N - episode will NOT be reopened - default)
    * @return                      true
    *
    * @since 2008-05-13
    * @version v2.4.3
    * @author rui.baeta
    */
    FUNCTION return_true
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_flg_episode_reopen IN VARCHAR2,
        i_id_episode         IN episode.id_episode%TYPE
    ) RETURN BOOLEAN AS
    BEGIN
        RETURN TRUE;
    END return_true;

    /**
    * Generic rule: always returns false. Input arguments are ignored.
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    * @param i_flg_episode_reopen  flag that tells if an episode is to be reopened (used in EDIS) (Y - episode will be reopened
    *                                                                                              N - episode will NOT be reopened - default)
    * @return                      false
    *
    * @since 2008-05-13
    * @version v2.4.3
    * @author rui.baeta
    */
    FUNCTION return_false
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_flg_episode_reopen IN VARCHAR2,
        i_id_episode         IN episode.id_episode%TYPE
    ) RETURN BOOLEAN AS
    BEGIN
        RETURN FALSE;
    END return_false;

END pk_ehr_access_rules;
/
