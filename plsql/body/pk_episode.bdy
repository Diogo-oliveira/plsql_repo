/*-- Last Change Revision: $Rev: 2052347 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2022-12-06 16:24:02 +0000 (ter, 06 dez 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_episode IS

    g_code_dom_act_inact         CONSTANT sys_domain.code_domain%TYPE := 'ACTIVE_INACTIVE';
    g_code_msg_treat_begin       CONSTANT sys_message.code_message%TYPE := 'INTAKE_TIME_M001'; --Início do tratamento data/hora
    g_code_msg_reg               CONSTANT sys_message.code_message%TYPE := 'INTAKE_TIME_M002'; --Register date/time
    g_code_msg_treat_begin_colon CONSTANT sys_message.code_message%TYPE := 'INTAKE_TIME_M003'; --Início do tratamento data/hora:
    g_code_msg_reg_colon         CONSTANT sys_message.code_message%TYPE := 'INTAKE_TIME_M004'; --Register date/time:

    FUNCTION get_epis_header
    (
        i_lang                IN language.id_language%TYPE,
        i_id_pat              IN patient.id_patient%TYPE,
        i_id_sched            IN schedule.id_schedule%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        i_prof                IN profissional,
        o_name                OUT patient.name%TYPE,
        o_gender              OUT patient.gender%TYPE,
        o_age                 OUT VARCHAR2,
        o_health_plan         OUT VARCHAR2,
        o_compl_diag          OUT VARCHAR2,
        o_prof_name           OUT VARCHAR2,
        o_prof_spec           OUT VARCHAR2,
        o_nkda                OUT VARCHAR2,
        o_episode             OUT pk_types.cursor_type,
        o_clin_rec            OUT pk_types.cursor_type,
        o_location            OUT pk_types.cursor_type,
        o_sched               OUT pk_types.cursor_type,
        o_efectiv             OUT pk_types.cursor_type,
        o_atend               OUT pk_types.cursor_type,
        o_wait                OUT pk_types.cursor_type,
        o_pat_photo           OUT VARCHAR2,
        o_habit               OUT VARCHAR2,
        o_allergy             OUT VARCHAR2,
        o_prev_epis           OUT VARCHAR2,
        o_relev_disease       OUT VARCHAR2,
        o_blood_type          OUT VARCHAR2,
        o_relev_note          OUT VARCHAR2,
        o_application         OUT VARCHAR2,
        o_shcut_habits        OUT VARCHAR2,
        o_shcut_allergies     OUT VARCHAR2,
        o_shcut_episodes      OUT VARCHAR2,
        o_shcut_bloodtype     OUT VARCHAR2,
        o_shcut_relevdiseases OUT VARCHAR2,
        o_shcut_relevnotes    OUT VARCHAR2,
        o_shcut_photo         OUT VARCHAR2,
        o_info                OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        /******************************************************************************
           OBJECTIVO:   Retornar os dados para o cabeçalho da aplicação
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                            I_ID_PAT - ID do doente
                         I_ID_SCHED - ID do agendamento
                         I_ID_EPISODE - ID do epis.
                        Saida: O_NAME - nome completo
                         O_GENDER - sexo do doente
                         O_AGE - idade do doente
                                 O_HEALTH_PLAN - subsistema de saúde do utente. Se houver +
                                     do q 1, considera-se o q tiver FLG_DEFAULT = 'S'
                         O_COMPL_DIAG - 1?consulta: justificação do P1 + tipo consulta
                                    subsequente: tipo consulta
                         O_PROF_NAME - nome do médico da consulta
                                 O_PROF_SPEC - especialidade do médico da consulta
                                 O_NKDA - indicação de "Não são conhecidas alergias a fármacos"
                                 O_EPISODE - n?episódio no sistema externo e título
                                 O_CLIN_REC - n?do processo clínico na instituição onde se est?
                                  a aceder ?aplicação (SYS_CONFIG) e título
                         O_LOCATION - localização e título
                         O_DT_SCHED - hora da consulta (HH:MM) e título
                         O_EFECTIV - hora da efectivação (HH:MM) e título
                         O_ATEND - hora de atendimento médico (HH:MM) e título
                         O_WAIT -  título
                         O_PAT_PHOTO - URL da directoria da foto do doente
                         O_ALLERGY - n?de alergias
                         O_PREV_EPIS - n?de episódios de consulta anteriores
                         O_RELEV_DISEASE - n?de doenças relevantes
                         O_BLOOD_TYPE - tipo sanguíneo
                         O_RELEV_NOTE - notas relevantes
                         O_APPLICATION - área aplicacional
                                 O_SHCUT_HABITS - shortcut para os hábitos
                                 O_SHCUT_ALLERGIES - shortcut para as alergias
                                 O_SHCUT_EPISODES - shortcut para os episódios
                                 O_SHCUT_BLOODTYPE - shortcut para o tipo de sangue
                                 O_SHCUT_RELEVDISEASES - shortcut para as doenças relevantes
                                 O_SHCUT_RELEVNOTES - shortcut para as notas relavantes
                                 O_INFO -
                                 O_ERROR - erro
        
          CRIAÇÃO: CRS 2005/02/25
          ALTERAÇÃO: CRS 2006/09/08 Indicação do centro de saúde em q est?inscrito
                RdSN 2006/11/02 Acrescentados 6 parâmetros de saída correspondentes aos
                                shortcuts a serem chamados quando não existe episódio
                     ASM 2007/01/17 Acrescentado novo parâmetro de saída para indicar se o paciente
                                 não tem alergias a fármacos - "NO KNOWN DRUG ALLERGIES"
                     Luís Gaspar, 2007-Nov-19. Retorna a descrição do evento (sch_event) onde dantes retornava mensagens (HEADER_M001, HEADER_M001)
          NOTAS: Conforme o tipo de episódio, o cabeçalho da aplicação pode ser diferente
        
        *********************************************************************************/
        l_desc_event      pk_translation.t_desc_translation;
        l_error           t_error_out;
        l_inst_abbr       institution.abbreviation%TYPE;
        l_health_plan     VARCHAR2(200);
        l_epis_type       epis_type.id_epis_type%TYPE;
        l_id_episode      epis_info.id_episode%TYPE;
        l_dt_efectiv      VARCHAR2(200);
        l_dt_atend        VARCHAR2(200);
        l_dt_sched        VARCHAR2(200);
        l_clin_rec        clin_record.num_clin_record%TYPE;
        l_episode         epis_ext_sys.value%TYPE;
        l_location        VARCHAR2(200);
        l_months          NUMBER;
        l_days            NUMBER;
        l_prof_name       professional.name%TYPE;
        l_id_prof_name    professional.id_professional%TYPE;
        l_prof_spec       VARCHAR2(200);
        l_habit           NUMBER;
        l_allergy         NUMBER;
        l_prev_epis_er    NUMBER;
        l_prev_epis_outp  NUMBER;
        l_prev_epis       NUMBER;
        l_relev_disease   NUMBER;
        l_blood_group     pat_blood_group.flg_blood_group%TYPE;
        l_blood_rhesus    VARCHAR2(20);
        l_blood_other     VARCHAR2(200);
        l_notes           NUMBER;
        l_clin_serv       VARCHAR2(200);
        l_instit_sched    schedule.id_instit_requested%TYPE;
        l_num_health_plan pat_health_plan.num_health_plan%TYPE;
        l_pat_hplan       pat_health_plan.id_pat_health_plan%TYPE;
        l_pat_desc_hplan  VARCHAR2(200);
        l_exist_er        sys_config.value%TYPE;
        l_instit_enroled  VARCHAR2(200);
        l_pat             pat_ext_sys.value%TYPE;
        l_area            VARCHAR2(8);
        l_age             NUMBER; -- LG 2006-11-08 patient might have an estimated age without a DT_BIRTH
        l_ret             BOOLEAN;
        l_preg_weeks      VARCHAR2(200);
        l_epis_flg_ehr    VARCHAR2(1);
        err_weeks_pregnancy EXCEPTION;
        l_exception         EXCEPTION;
        -- Nome do utente, subsistema de saúde, n?processo clínico, tipo sanguíneo,
        -- CRS 2006/09/08: centro de saúde em q est?inscrito
        -- JS 2006/11/16: Outer join con CLIN_RECORD, paciente criado na aplicação pode não ter processo clinico
        CURSOR c_name IS
            SELECT pat.name,
                   pk_translation.get_translation(i_lang, hpn.code_health_plan) desc_translation,
                   crn.num_clin_record,
                   pk_sysdomain.get_domain('PATIENT.GENDER.ABBR', pat.gender, i_lang) gender, -- Eduardo Lourenco - 2007/Dez/11
                   tab_age.months,
                   tab_age.days,
                   decode(pk_patphoto.check_blob(pat.id_patient),
                          'N',
                          '',
                          pk_patphoto.get_pat_foto(pat.id_patient, i_prof)) patphoto,
                   pbg.flg_blood_group,
                   sd.desc_val flg_blood_rhesus,
                   decode(pbg.desc_other_system, '', '', pk_message.get_message(i_lang, 'HEADER_BLOOD')),
                   php.num_health_plan,
                   decode(pk_translation.get_translation(i_lang, i.code_institution),
                          NULL,
                          NULL,
                          decode(i.id_institution,
                                 i_prof.institution,
                                 '; ' || i.abbreviation,
                                 '; ' || pk_translation.get_translation(i_lang, i.code_institution))) instit_enroled,
                   tab_age.age
              FROM patient            pat,
                   pat_health_plan    php,
                   health_plan        hpn,
                   clin_record        crn,
                   institution        i,
                   pat_cli_attributes pca,
                   pat_blood_group    pbg,
                   sys_domain         sd,
                   -- RdSN 2006/11/24 Para os utilizadores que não têm registo de idade, ?retornada uma idade aproximada tendo em conta a sua DT_BIRTH
                   (SELECT nvl(pat1.age, trunc(months_between(SYSDATE, pat1.dt_birth) / 12, 0)) age,
                           months_between(SYSDATE, pat1.dt_birth) months,
                           (SYSDATE - pat1.dt_birth) days,
                           pat1.id_patient
                      FROM patient pat1
                     WHERE pat1.id_patient = i_id_pat) tab_age
             WHERE pat.id_patient = i_id_pat
               AND php.id_patient(+) = pat.id_patient
               AND hpn.id_health_plan(+) = php.id_health_plan
               AND php.flg_status(+) = pk_alert_constant.g_active
               AND php.flg_default(+) = pk_alert_constant.g_yes
               AND php.id_institution(+) = i_prof.institution
               AND crn.id_patient(+) = pat.id_patient
               AND crn.id_institution(+) = l_instit_sched
               AND tab_age.id_patient = pat.id_patient
               AND pca.id_patient(+) = pat.id_patient
               AND pbg.id_patient(+) = pat.id_patient
               AND pbg.flg_status(+) = pk_alert_constant.g_active
               AND sd.id_language(+) = i_lang
               AND sd.code_domain(+) = 'PAT_BLOOD_GROUP.FLG_BLOOD_RHESUS'
               AND sd.domain_owner(+) = pk_sysdomain.k_default_schema
               AND sd.val(+) = pbg.flg_blood_rhesus
               AND sd.id_language(+) = i_lang
               AND i.id_institution(+) = crn.id_instit_enroled;
        --
        CURSOR c_epis IS
            SELECT so.id_epis_type,
                   e.id_episode,
                   p.name,
                   p.id_professional,
                   nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) desc_room,
                   pk_translation.get_translation(i_lang, sp.code_speciality) desc_spec,
                   decode(i.abbreviation, NULL, NULL, '; ' || i.abbreviation) abbreviation,
                   nvl(pk_date_utils.to_char_insttimezone(i_prof, so.dt_target_tstz, 'HH24:MI"h"'), '---') dt_target,
                   pk_translation.get_translation(i_lang, cs.code_clinical_service) clin_serv,
                   pk_schedule_common.get_translation_alias(i_lang, i_prof, se.id_sch_event, se.code_sch_event) desc_event,
                   s.id_instit_requested,
                   ehp.id_pat_health_plan
              FROM schedule         s,
                   schedule_outp    so,
                   epis_info        e,
                   room             r,
                   professional     p,
                   speciality       sp,
                   institution      i,
                   clinical_service cs,
                   dep_clin_serv    dcs,
                   epis_health_plan ehp,
                   sch_event        se
             WHERE (s.id_schedule = i_id_sched OR e.id_episode = i_id_episode)
               AND s.flg_status != pk_schedule.g_sched_status_cancelled
               AND s.flg_status != pk_schedule.g_sched_status_cache -- agendamentos temporários (SCH 3.0)
               AND so.id_schedule = s.id_schedule
               AND e.id_schedule = s.id_schedule
               AND r.id_room = e.id_room
               AND p.id_professional(+) = e.id_professional
               AND sp.id_speciality(+) = p.id_speciality
               AND s.id_instit_requested = i.id_institution
               AND dcs.id_dep_clin_serv = s.id_dcs_requested
               AND cs.id_clinical_service = dcs.id_clinical_service
               AND ehp.id_episode(+) = e.id_episode
               AND se.id_sch_event(+) = s.id_sch_event;
    
        CURSOR c_sched IS
            SELECT so.id_epis_type,
                   p.name,
                   p.id_professional,
                   pk_translation.get_translation(i_lang, sp.code_speciality) desc_spec,
                   decode(i.abbreviation, NULL, NULL, '; ' || i.abbreviation) abbreviation,
                   nvl(pk_date_utils.to_char_insttimezone(i_prof, so.dt_target_tstz, 'HH24:MI"h"'), '---') dt_target,
                   pk_translation.get_translation(i_lang, cs.code_clinical_service) clin_serv,
                   pk_schedule_common.get_translation_alias(i_lang, i_prof, se.id_sch_event, se.code_sch_event) desc_event,
                   s.id_instit_requested
              FROM schedule         s,
                   schedule_outp    so,
                   sch_prof_outp    spo,
                   professional     p,
                   speciality       sp,
                   institution      i,
                   clinical_service cs,
                   dep_clin_serv    dcs,
                   sch_event        se
             WHERE s.id_schedule = i_id_sched
               AND s.flg_status != pk_schedule.g_sched_status_cancelled
               AND s.flg_status != pk_schedule.g_sched_status_cache -- agendamentos temporários (SCH 3.0)
               AND so.id_schedule = s.id_schedule
               AND spo.id_schedule_outp(+) = so.id_schedule_outp
               AND p.id_professional(+) = spo.id_professional
               AND sp.id_speciality(+) = p.id_speciality
               AND i.id_institution = s.id_instit_requested
               AND dcs.id_dep_clin_serv = s.id_dcs_requested
               AND cs.id_clinical_service = dcs.id_clinical_service
               AND se.id_sch_event(+) = s.id_sch_event;
    
        CURSOR c_habit IS
            SELECT COUNT(*)
              FROM pat_habit
             WHERE id_patient = i_id_pat
               AND flg_status != pk_alert_constant.g_cancelled;
    
        CURSOR c_pat_ext IS
            SELECT VALUE
              FROM pat_ext_sys pes
             WHERE pes.id_patient = i_id_pat
               AND pes.id_external_sys = pk_sysconfig.get_config('ID_EXTERNAL_SYS', i_prof);
    
        CURSOR c_disease IS
        -- RdSN 2007/09/22
        -- New model for the relevant diseases
            SELECT COUNT(*)
              FROM pat_history_diagnosis
             WHERE id_patient = i_id_pat
               AND id_alert_diagnosis IS NOT NULL
               AND id_pat_history_diagnosis =
                   pk_problems.get_pat_hist_diag_recent(i_lang,
                                                        id_alert_diagnosis,
                                                        desc_pat_history_diagnosis, --NULL,
                                                        i_id_pat,
                                                        i_prof,
                                                        g_pat_history_diagnosis_n);
    
        CURSOR c_notes IS
            SELECT COUNT(1)
              FROM v_pat_notes
             WHERE id_patient = i_id_pat
               AND flg_status != pk_alert_constant.g_cancelled;
    
        CURSOR c_fam_prof IS
            SELECT id_professional, nick_name
              FROM ((SELECT pfp.id_professional, p.nick_name, 1
                       FROM patient pat, pat_family_prof pfp, professional p
                      WHERE pat.id_patient = i_id_pat
                        AND pfp.id_patient = pat.id_patient
                        AND p.id_professional = pfp.id_professional
                     UNION ALL
                     SELECT pfp.id_professional, p.nick_name, 2
                       FROM patient pat, pat_family_prof pfp, professional p
                      WHERE pat.id_patient = i_id_pat
                        AND pfp.id_pat_family = pat.id_pat_family
                        AND p.id_professional = pfp.id_professional) ORDER BY 3)
             WHERE rownum = 1;
    
        r_fam_prof c_fam_prof%ROWTYPE;
    
        CURSOR c_pat_hplan IS
            SELECT pk_translation.get_translation(i_lang, hpn.code_health_plan) desc_translation, num_health_plan
              FROM pat_health_plan php, health_plan hpn
             WHERE id_pat_health_plan = l_pat_hplan
               AND hpn.id_health_plan = php.id_health_plan;
    
        -- JM 28/08/08
    
        --variavel que indica de nos devemos deslocar para a area antiga quando estamos em episódios não efectivados
        l_to_old_area VARCHAR2(1);
    
        l_flg_ehr episode.flg_ehr%TYPE;
    
        --variavel que ir?guardar o estado de agendamento (caso aplicável)
        l_sched_status VARCHAR(1);
    
        FUNCTION check_schedule_intervention(i_id_sched IN schedule_intervention.id_schedule%TYPE) RETURN BOOLEAN IS
            l_count NUMBER := 0;
        BEGIN
            SELECT COUNT(*)
              INTO l_count
              FROM schedule_intervention
             WHERE id_schedule = i_id_sched;
            RETURN l_count > 0;
        END;
    BEGIN
        g_sysdate_tstz := current_timestamp;
        g_error        := 'GET CONFIGURATIONS';
        g_epis_consult := pk_sysconfig.get_config('ID_EPIS_TYPE_CONSULT', i_prof);
        g_epis_cs      := pk_sysconfig.get_config('ID_EPIS_TYPE_CS', i_prof);
        g_months_sign  := pk_sysconfig.get_config('MONTHS_SIGN', i_prof);
        g_days_sign    := pk_sysconfig.get_config('DAYS_SIGN', i_prof);
    
        l_to_old_area := pk_sysconfig.get_config('EHR_ACCESS_SC_OLD_AREA', i_prof);
    
        BEGIN
            SELECT s.flg_status
              INTO l_sched_status
              FROM schedule s
             WHERE s.id_schedule = i_id_sched;
        EXCEPTION
            WHEN no_data_found THEN
                l_sched_status := NULL;
        END;
    
        IF (i_id_episode IS NOT NULL AND
           get_epis_type(i_lang, i_id_episode) = pk_sysconfig.get_config(g_epis_type_physiotherapy, i_prof))
           OR check_schedule_intervention(i_id_sched)
        THEN
            g_error := 'FUNCTION pk_interv_mfr.get_epis_header';
            RETURN pk_interv_mfr.get_epis_header(i_lang                => i_lang,
                                                 i_id_pat              => i_id_pat,
                                                 i_id_sched            => i_id_sched,
                                                 i_id_episode          => i_id_episode,
                                                 i_prof                => i_prof,
                                                 o_name                => o_name,
                                                 o_gender              => o_gender,
                                                 o_age                 => o_age,
                                                 o_health_plan         => o_health_plan,
                                                 o_compl_diag          => o_compl_diag,
                                                 o_prof_name           => o_prof_name,
                                                 o_prof_spec           => o_prof_spec,
                                                 o_nkda                => o_nkda,
                                                 o_episode             => o_episode,
                                                 o_clin_rec            => o_clin_rec,
                                                 o_location            => o_location,
                                                 o_sched               => o_sched,
                                                 o_efectiv             => o_efectiv,
                                                 o_atend               => o_atend,
                                                 o_wait                => o_wait,
                                                 o_pat_photo           => o_pat_photo,
                                                 o_habit               => o_habit,
                                                 o_allergy             => o_allergy,
                                                 o_prev_epis           => o_prev_epis,
                                                 o_relev_disease       => o_relev_disease,
                                                 o_blood_type          => o_blood_type,
                                                 o_relev_note          => o_relev_note,
                                                 o_application         => o_application,
                                                 o_shcut_habits        => o_shcut_habits,
                                                 o_shcut_allergies     => o_shcut_allergies,
                                                 o_shcut_episodes      => o_shcut_episodes,
                                                 o_shcut_bloodtype     => o_shcut_bloodtype,
                                                 o_shcut_relevdiseases => o_shcut_relevdiseases,
                                                 o_shcut_relevnotes    => o_shcut_relevnotes,
                                                 o_shcut_photo         => o_shcut_photo,
                                                 o_info                => o_info,
                                                 o_error               => o_error);
        END IF;
    
        --SPS - ler o tipo de episodio (agendamento, normal, ehr event)
        IF (i_id_episode IS NOT NULL)
        THEN
            SELECT e.flg_ehr
              INTO l_epis_flg_ehr
              FROM episode e
             WHERE e.id_episode = i_id_episode;
        END IF;
    
        -- LG 2006-OUT-17. by default consider institution the one executing the request, needed by clinics when the patient has no episodes
        l_instit_sched := i_prof.institution;
    
        -- Tipo de episódio (Urg, CE, BO, ...)
        --IF (i_id_sched IS NOT NULL)
        --THEN -- EduardoLourenco: If commented because we need information even if no id_schedule is given.
        -- LG, 2006-OUT-17. in the clinics we may have searched patients with no schedule
        g_error := 'GET CURSOR C_EPIS';
        OPEN c_epis;
        FETCH c_epis
            INTO l_epis_type,
                 l_id_episode,
                 l_prof_name,
                 l_id_prof_name,
                 l_location,
                 l_prof_spec,
                 l_inst_abbr,
                 l_dt_sched,
                 l_clin_serv,
                 l_desc_event,
                 l_instit_sched,
                 l_pat_hplan;
        g_found := c_epis%NOTFOUND;
        CLOSE c_epis;
        --END IF;
    
        IF (i_id_sched IS NOT NULL)
        THEN
            -- LG, 2006-OUT-17. in the clinics we may have searched patients with no schedule
            IF g_found
            THEN
                -- Agendamento ainda ?tem episódio (?foi efectivado)
                g_error := 'GET CURSOR C_SCHED';
                OPEN c_sched;
                FETCH c_sched
                    INTO l_epis_type,
                         l_prof_name,
                         l_id_prof_name,
                         l_prof_spec,
                         l_inst_abbr,
                         l_dt_sched,
                         l_clin_serv,
                         l_desc_event,
                         l_instit_sched;
                g_found := c_sched%NOTFOUND;
                CLOSE c_sched;
            END IF;
        END IF;
        --
        o_prof_name := l_prof_name;
        -- hora da consulta
        g_error := 'GET CURSOR O_SCHED';
        OPEN o_sched FOR
            SELECT desc_message title, l_dt_sched valor
              FROM sys_message
             WHERE id_language = i_lang
               AND code_message = 'ID_T003'
               AND flg_available = 'Y';
    
        -- localização
        --caso se trate um episodio com o tipo flg_ehr = 'S', significa que o paciente ainda não se encontra fisicamente na instituição
        IF l_epis_flg_ehr = 'S'
        THEN
            l_location := NULL;
        END IF;
        g_error := 'GET CURSOR O_LOCATION';
        OPEN o_location FOR
            SELECT desc_message title, l_location valor
              FROM sys_message
             WHERE id_language = i_lang
               AND code_message = 'ID_T006'
               AND flg_available = 'Y';
    
        g_error := 'GET NKDA TEXT';
        l_ret   := get_nkda_label(i_lang, i_prof, i_id_pat, o_nkda, l_error);
    
        g_error := 'CALL PK_ADT.GET_PAT_RECM';
        IF NOT pk_adt.get_pat_recm(i_lang   => i_lang,
                                   i_prof   => i_prof,
                                   i_id_pat => i_id_pat,
                                   o_nkda   => o_nkda,
                                   o_error  => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        -- Contagem de hábitos
        g_error := 'OPEN C_HABIT';
        OPEN c_habit;
        FETCH c_habit
            INTO l_habit;
        CLOSE c_habit;
        IF l_habit = 1
        THEN
            o_habit := l_habit || ' ' || pk_message.get_message(i_lang, 'ID_M009');
        ELSIF l_habit > 1
        THEN
            o_habit := l_habit || ' ' || pk_message.get_message(i_lang, 'ID_M010');
        END IF;
    
        -- Contagem de alergias
        g_error := 'GET ALLERGY';
        --l_allergy := pk_ea_logic_viewer.get_pat_num_allergies(i_lang, i_id_pat);
        l_allergy := pk_allergy.get_count_allergy(i_lang, i_id_pat, o_error);
    
        g_error := 'IF AFTER GET ALLERGY';
        IF l_allergy = 1
        THEN
            o_allergy := l_allergy || ' ' || pk_message.get_message(i_lang, 'EDIS_ID_M003');
        ELSIF l_allergy > 1
        THEN
            o_allergy := l_allergy || ' ' || pk_message.get_message(i_lang, 'EDIS_ID_M004');
        END IF;
    
        -- Contagem de doenças relevantes
        g_error := 'OPEN C_DISEASE';
        OPEN c_disease;
        FETCH c_disease
            INTO l_relev_disease;
        CLOSE c_disease;
        IF l_relev_disease = 1
        THEN
            o_relev_disease := l_relev_disease || ' ' || pk_message.get_message(i_lang, 'ID_M006');
        ELSIF l_relev_disease > 1
        THEN
            o_relev_disease := l_relev_disease || ' ' || pk_message.get_message(i_lang, 'ID_M003');
        END IF;
    
        -- Contagem de notas relevantes
        g_error := 'OPEN C_NOTES';
        OPEN c_notes;
        FETCH c_notes
            INTO l_notes;
        CLOSE c_notes;
        IF l_notes = 1
        THEN
            o_relev_note := l_notes || ' ' || pk_message.get_message(i_lang, 'ID_M007');
        ELSIF l_notes > 1
        THEN
            o_relev_note := l_notes || ' ' || pk_message.get_message(i_lang, 'ID_M004');
        END IF;
        --
        g_error := 'GET CONSULT TYPE';
        IF l_epis_type = g_epis_consult
        THEN
            -- Consulta externa
            o_application := pk_message.get_message(i_lang, 'HEADER_M003');
        ELSIF l_epis_type = g_epis_cs
        THEN
            -- Consulta
            o_application := pk_message.get_message(i_lang, 'HEADER_M004');
        END IF;
        --
        g_error    := 'CALL TO PK_SYSCONFIG.GET_CONFIG';
        l_exist_er := pk_sysconfig.get_config('ER_CLIENT_SERVER', i_prof);
        IF l_exist_er = 'Y'
        THEN
            g_error := 'OPEN C_PAT_EXT';
            OPEN c_pat_ext;
            FETCH c_pat_ext
                INTO l_pat;
            CLOSE c_pat_ext;
        
            -- Contagem de epis. anteriores
            g_error := 'OPEN C_PREV_EPIS_ER';
            EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM V_OUTP_EPISODES WHERE ID_PAT_EXT = :1'
                INTO l_prev_epis_er
                USING l_pat;
        END IF;
        --
        g_error := 'OPEN C_PREV_EPIS_OUTP';
        SELECT COUNT(*)
          INTO l_prev_epis_outp
          FROM episode e
         WHERE e.id_patient = i_id_pat
           AND pk_date_utils.trunc_insttimezone(i_prof, e.dt_begin_tstz, 'DD') <=
               pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz, 'DD')
           AND e.flg_status = pk_alert_constant.g_epis_status_inactive;
    
        --
        l_prev_epis := nvl(l_prev_epis_er, 0) + nvl(l_prev_epis_outp, 0);
        --
        IF l_prev_epis = 1
        THEN
            o_prev_epis := l_prev_epis || ' ' || pk_message.get_message(i_lang, i_prof, 'ID_M008');
        ELSIF l_prev_epis > 1
        THEN
            o_prev_epis := l_prev_epis || ' ' || pk_message.get_message(i_lang, i_prof, 'ID_M002');
        END IF;
        -- Nome do utente, subsistema de saúde, n?processo clínico, sexo e idade
        g_error := 'GET CURSOR C_NAME ';
        OPEN c_name;
        FETCH c_name
            INTO o_name,
                 l_health_plan,
                 l_clin_rec,
                 o_gender,
                 l_months,
                 l_days,
                 o_pat_photo,
                 l_blood_group,
                 l_blood_rhesus,
                 l_blood_other,
                 l_num_health_plan,
                 l_instit_enroled,
                 l_age;
        g_found := c_name%NOTFOUND;
        CLOSE c_name;
        --
        IF g_found
        THEN
            RAISE l_exception;
        ELSE
            g_error := 'GET BLOOD TYPE';
            IF l_blood_group IS NULL
            THEN
                o_blood_type := NULL;
            ELSE
                o_blood_type := l_blood_group || ' ' || l_blood_rhesus || ' ' || l_blood_other;
            END IF;
        
            g_error := 'GET HEALTH PLAN';
            IF l_pat_hplan IS NOT NULL
            THEN
                g_error := 'GET CURSOR C_PAT_HPLAN ';
                OPEN c_pat_hplan;
                FETCH c_pat_hplan
                    INTO l_pat_desc_hplan, l_num_health_plan;
                CLOSE c_pat_hplan;
                --o_health_plan := ' (' || l_pat_desc_hplan || ' - ' || l_num_health_plan || ')';
                o_health_plan := ' (' || l_num_health_plan || ' - ' || l_pat_desc_hplan || ')';
            
            ELSE
                IF l_health_plan IS NOT NULL
                THEN
                    --o_health_plan := ' (' || l_health_plan || ' - ' || l_num_health_plan || ')';
                    o_health_plan := ' (' || l_num_health_plan || ' - ' || l_health_plan || ')';
                ELSE
                    o_health_plan := '';
                END IF;
            END IF;
        
            g_error := 'GET AGE';
            --    IF(L_AGE IS NOT NULL) THEN
            IF nvl(l_age, 0) != 0
            THEN
                o_age := l_age;
            ELSIF l_months < 1
            THEN
                o_age := trunc(l_days) || g_days_sign;
            ELSIF l_months < 36
            THEN
                o_age := trunc(l_months) || g_months_sign;
            ELSE
                o_age := trunc(l_months / 12);
            END IF;
        
            -- cmf 2007/09/26
            -- Header must show the weeks of pregnancy, if the patient has as active one
            IF nvl(pk_sysconfig.get_config('WOMAN_HEALTH_HEADER', i_prof), 'N') = 'Y'
            THEN
                g_error := 'GET PREGNANCY WEEKS';
                l_ret   := pk_woman_health.get_pregnancy_weeks(i_lang, i_prof, i_id_pat, l_preg_weeks, l_error);
                IF l_ret = FALSE
                THEN
                    RAISE l_exception;
                ELSE
                    IF l_preg_weeks IS NOT NULL
                    THEN
                        o_age := o_age || ' / ' || l_preg_weeks;
                    END IF;
                END IF;
            END IF;
        
            --            o_age := o_age || l_preg_weeks;
        
        END IF;
    
        IF i_prof.software = pk_sysconfig.get_config('SOFTWARE_ID_CARE', i_prof)
        THEN
            g_error := 'GET C_FAM_PROF';
            OPEN c_fam_prof;
            FETCH c_fam_prof
                INTO r_fam_prof;
            g_found := c_fam_prof%FOUND;
            CLOSE c_fam_prof;
        
            IF g_found
            THEN
                g_error := 'GET PROF SPEC (CS)';
                IF nvl(l_id_prof_name, 0) != 0
                   AND l_id_prof_name = r_fam_prof.id_professional
                THEN
                    o_prof_spec := ' (' || pk_message.get_message(i_lang, 'HEADER_M005') || ')';
                ELSE
                    o_prof_spec := ' (' || pk_message.get_message(i_lang, 'HEADER_M005') || ': ' ||
                                   r_fam_prof.nick_name || l_instit_enroled || ')';
                END IF;
            END IF;
        
        ELSIF l_prof_spec IS NOT NULL
        THEN
            g_error     := 'GET PROF SPEC (H)';
            o_prof_spec := ' (' || l_prof_spec || l_inst_abbr || ')';
        END IF;
    
        -- processo clínico na instituição
        g_error := 'GET CURSOR O_CLIN_REC';
        OPEN o_clin_rec FOR
            SELECT pk_message.get_message(i_lang, 'ID_T002') title, l_clin_rec valor
              FROM dual;
    
        o_compl_diag := nvl(l_desc_event, pk_message.get_message(i_lang, 'HEADER_M006')) || ': ' || l_clin_serv;
    
        IF (i_id_episode IS NOT NULL AND l_epis_flg_ehr != 'S')
        THEN
            -- LG, 2006-OUT-17. in the clinics we may have searched patients with no episode
            g_error := 'CALL TO GET_EPIS_EXT';
            IF NOT get_epis_ext(i_lang       => i_lang,
                                i_id_episode => i_id_episode,
                                i_prof       => i_prof,
                                o_dt_efectiv => l_dt_efectiv,
                                o_dt_atend   => l_dt_atend,
                                o_episode    => l_episode,
                                o_error      => l_error)
            THEN
                --   o_error := l_error;
                RAISE g_exception;
            END IF;
        END IF;
    
        -- episódio no sistema externo
        g_error := 'GET CURSOR O_EPISODE';
        OPEN o_episode FOR
            SELECT pk_message.get_message(i_lang, i_prof, 'ID_T001') title, l_episode valor
              FROM dual;
    
        -- hora de atendimento médico
        g_error := 'GET CURSOR O_ATEND';
        OPEN o_atend FOR
            SELECT pk_message.get_message(i_lang, i_prof, 'ID_T005') title, l_dt_atend valor
              FROM dual;
    
        -- hora da efectivação
        g_error := 'GET CURSOR O_EFECTIV';
        OPEN o_efectiv FOR
            SELECT pk_message.get_message(i_lang, i_prof, 'ID_T004') title, l_dt_efectiv valor
              FROM dual;
    
        -- em espera
        g_error := 'GET CURSOR O_WAIT';
        OPEN o_wait FOR
            SELECT pk_message.get_message(i_lang, i_prof, 'ID_T007') title, NULL valor
              FROM dual;
    
        -- RdSN 2006/11/06
        BEGIN
            SELECT e.flg_ehr
              INTO l_flg_ehr
              FROM episode e
             WHERE e.id_episode = i_id_episode;
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;
    
        dbms_output.put_line(l_flg_ehr || '--' || l_to_old_area || '--' || pk_alert_constant.g_yes);
    
        IF i_id_episode IS NULL
        THEN
            SELECT decode(l_to_old_area, pk_alert_constant.g_yes, 'CLINPROC', 'SOAP')
              INTO l_area
              FROM dual;
        ELSE
            SELECT decode(l_flg_ehr,
                          pk_ehr_access.g_flg_ehr_normal,
                          'SOAP',
                          decode(l_to_old_area, pk_alert_constant.g_yes, 'CLINPROC', 'SOAP'))
              INTO l_area
              FROM dual;
        END IF;
    
        o_shcut_habits        := CASE l_sched_status
                                     WHEN pk_schedule.g_sched_status_cancelled THEN
                                      -1
                                     ELSE
                                      pk_sysconfig.get_config('SHORTCUT_' || l_area || '_HABITS', i_prof)
                                 END;
        o_shcut_allergies     := CASE l_sched_status
                                     WHEN pk_schedule.g_sched_status_cancelled THEN
                                      -1
                                     ELSE
                                      pk_sysconfig.get_config('SHORTCUT_' || l_area || '_ALLERGIES', i_prof)
                                 END;
        o_shcut_episodes      := CASE l_sched_status
                                     WHEN pk_schedule.g_sched_status_cancelled THEN
                                      -1
                                     ELSE
                                      pk_sysconfig.get_config('SHORTCUT_' || l_area || '_EPISODES', i_prof)
                                 END;
        o_shcut_bloodtype     := CASE l_sched_status
                                     WHEN pk_schedule.g_sched_status_cancelled THEN
                                      -1
                                     ELSE
                                      pk_sysconfig.get_config('SHORTCUT_' || l_area || '_BLOODTYPE', i_prof)
                                 END;
        o_shcut_relevdiseases := CASE l_sched_status
                                     WHEN pk_schedule.g_sched_status_cancelled THEN
                                      -1
                                     ELSE
                                      pk_sysconfig.get_config('SHORTCUT_' || l_area || '_RELEVDISEASES', i_prof)
                                 END;
        o_shcut_relevnotes    := CASE l_sched_status
                                     WHEN pk_schedule.g_sched_status_cancelled THEN
                                      -1
                                     ELSE
                                      pk_sysconfig.get_config('SHORTCUT_' || l_area || '_RELEVNOTES', i_prof)
                                 END;
        o_shcut_photo         := CASE l_sched_status
                                     WHEN pk_schedule.g_sched_status_cancelled THEN
                                      -1
                                     ELSE
                                      pk_sysconfig.get_config('SHORTCUT_PHOTO', i_prof)
                                 END;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            o_error := l_error;
            RETURN FALSE;
        WHEN l_exception THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_episode);
                pk_types.open_my_cursor(o_clin_rec);
                pk_types.open_my_cursor(o_location);
                pk_types.open_my_cursor(o_sched);
                pk_types.open_my_cursor(o_atend);
                pk_types.open_my_cursor(o_efectiv);
                pk_types.open_my_cursor(o_wait);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_owner_name, g_pck_name, 'GET_EPIS_HEADER');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN l_ret;
            END;
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_episode);
                pk_types.open_my_cursor(o_clin_rec);
                pk_types.open_my_cursor(o_location);
                pk_types.open_my_cursor(o_sched);
                pk_types.open_my_cursor(o_atend);
                pk_types.open_my_cursor(o_efectiv);
                pk_types.open_my_cursor(o_wait);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_owner_name, g_pck_name, 'GET_EPIS_HEADER');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN l_ret;
            END;
    END;
    --

    FUNCTION get_epis_header_reports
    (
        i_lang                IN language.id_language%TYPE,
        i_id_pat              IN patient.id_patient%TYPE,
        i_id_sched            IN schedule.id_schedule%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        i_prof_id             IN professional.id_professional%TYPE,
        i_prof_inst           IN institution.id_institution%TYPE,
        i_prof_sw             IN software.id_software%TYPE,
        o_name                OUT patient.name%TYPE,
        o_gender              OUT patient.gender%TYPE,
        o_age                 OUT VARCHAR2,
        o_health_plan         OUT VARCHAR2,
        o_compl_diag          OUT VARCHAR2,
        o_prof_name           OUT VARCHAR2,
        o_prof_spec           OUT VARCHAR2,
        o_nkda                OUT VARCHAR2,
        o_episode             OUT pk_types.cursor_type,
        o_clin_rec            OUT pk_types.cursor_type,
        o_location            OUT pk_types.cursor_type,
        o_sched               OUT pk_types.cursor_type,
        o_efectiv             OUT pk_types.cursor_type,
        o_atend               OUT pk_types.cursor_type,
        o_wait                OUT pk_types.cursor_type,
        o_pat_photo           OUT VARCHAR2,
        o_habit               OUT VARCHAR2,
        o_allergy             OUT VARCHAR2,
        o_prev_epis           OUT VARCHAR2,
        o_relev_disease       OUT VARCHAR2,
        o_blood_type          OUT VARCHAR2,
        o_relev_note          OUT VARCHAR2,
        o_application         OUT VARCHAR2,
        o_shcut_habits        OUT VARCHAR2,
        o_shcut_allergies     OUT VARCHAR2,
        o_shcut_episodes      OUT VARCHAR2,
        o_shcut_bloodtype     OUT VARCHAR2,
        o_shcut_relevdiseases OUT VARCHAR2,
        o_shcut_relevnotes    OUT VARCHAR2,
        o_shcut_photo         OUT VARCHAR2,
        o_info                OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        i_prof profissional := profissional(i_prof_id, i_prof_inst, i_prof_sw);
    
    BEGIN
        g_error := 'FUNCTION GET_EPIS_HEADER';
        RETURN get_epis_header(i_lang,
                               i_id_pat,
                               i_id_sched,
                               i_id_episode,
                               i_prof,
                               o_name,
                               o_gender,
                               o_age,
                               o_health_plan,
                               o_compl_diag,
                               o_prof_name,
                               o_prof_spec,
                               o_nkda,
                               o_episode,
                               o_clin_rec,
                               o_location,
                               o_sched,
                               o_efectiv,
                               o_atend,
                               o_wait,
                               o_pat_photo,
                               o_habit,
                               o_allergy,
                               o_prev_epis,
                               o_relev_disease,
                               o_blood_type,
                               o_relev_note,
                               o_application,
                               o_shcut_habits,
                               o_shcut_allergies,
                               o_shcut_episodes,
                               o_shcut_bloodtype,
                               o_shcut_relevdiseases,
                               o_shcut_relevnotes,
                               o_shcut_photo,
                               o_info,
                               o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_episode);
                pk_types.open_my_cursor(o_clin_rec);
                pk_types.open_my_cursor(o_location);
                pk_types.open_my_cursor(o_sched);
                pk_types.open_my_cursor(o_atend);
                pk_types.open_my_cursor(o_efectiv);
                pk_types.open_my_cursor(o_wait);
            
                -- setting language, setting error content into input object, setting package information 
            
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_owner_name,
                                   g_pck_name,
                                   'GET_EPIS_HEADER_REPORTS');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN l_ret;
            END;
    END;
    --
    FUNCTION get_epis_header_info
    (
        i_lang        IN language.id_language%TYPE,
        i_id_pat      IN patient.id_patient%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_prof        IN profissional,
        o_desc_info   OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Retornar info do doente q ?mostrada na cabeçalho da aplicação
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                                    I_ID_PAT - ID do doente
                                 I_ID_EPISODE - Tipo de episódio
                        Saida:   O_DESC_INFO - info do doente
                                 O_ERROR - erro
        
          CRIAÇÃO: CRS 2005/03/16
          NOTAS:
        *********************************************************************************/
        l_sched_type schedule_outp.flg_type%TYPE;
        l_error      t_error_out;
    
        CURSOR c_sched IS
            SELECT c.id_clinical_service,
                   so.id_epis_type,
                   pk_translation.get_translation(i_lang, c.code_clinical_service) clin_serv
              FROM schedule s, schedule_outp so, clinical_service c, dep_clin_serv d
             WHERE s.id_schedule = i_id_schedule
               AND s.flg_status != pk_schedule.g_sched_status_cancelled
               AND so.id_schedule = s.id_schedule
               AND d.id_dep_clin_serv = s.id_dcs_requested
               AND c.id_clinical_service = d.id_clinical_service;
        r_sched c_sched%ROWTYPE;
    BEGIN
        g_sysdate_tstz := current_timestamp;
        g_epis_consult := pk_sysconfig.get_config('ID_EPIS_TYPE_CONSULT', i_prof);
    
        -- Info do episódio e respectiva visita
        g_error := 'GET CURSOR C_EPIS';
        OPEN c_sched;
        FETCH c_sched
            INTO r_sched;
        CLOSE c_sched;
    
        IF r_sched.id_epis_type = g_epis_consult
        THEN
            -- Episódio ?de consulta
            -- Verificar se a consulta (deste episódio) ?1?ou subsequente, da especialidade
            g_error := 'CALL TO PK_SCHEDULE.GET_FIRST_SUBSEQUENT';
            IF NOT get_first_subsequent(i_lang         => i_lang,
                                        i_id_pat       => i_id_pat,
                                        i_id_clin_serv => r_sched.id_clinical_service,
                                        i_institution  => i_institution,
                                        i_epis_type    => r_sched.id_epis_type,
                                        o_flg          => l_sched_type,
                                        o_error        => l_error)
            THEN
                RAISE g_exception;
            END IF;
        
            IF l_sched_type = 'S'
            THEN
                -- Consulta subsequente
                o_desc_info := pk_message.get_message(i_lang, 'HEADER_M002') || r_sched.clin_serv;
            ELSIF l_sched_type = 'P'
            THEN
                -- 1?consulta
                -- mostra a justificação do P1, se houver
                o_desc_info := pk_message.get_message(i_lang, 'HEADER_M001') || r_sched.clin_serv;
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            o_error := l_error;
            RETURN FALSE;
        WHEN OTHERS THEN
        
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
            
                -- setting language, setting error content into input object, setting package information             
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_owner_name, g_pck_name, 'GET_EPIS_HEADER_INFO');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN l_ret;
            END;
    END;
    --
    --
    FUNCTION get_first_subsequent
    (
        i_lang         IN language.id_language%TYPE,
        i_id_pat       IN patient.id_patient%TYPE,
        i_id_clin_serv IN clinical_service.id_clinical_service%TYPE,
        i_institution  IN institution.id_institution%TYPE,
        i_epis_type    IN episode.id_epis_type%TYPE,
        o_flg          OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Retornar se se trata de uma 1?consulta ou subsequente da
                           especialidade indicada
           PARAMETROS:  Entrada: I_LANG - Língua
                                    I_ID_PAT - ID do utente
                                 I_ID_CLIN_SERV - ID do tipo de serviço clínico
                                 I_INSTITUTION - ID da instituição
                                 I_EPIS_TYPE - ID do tipo de episódio
                        Saida:   O_FLG - P - 1?consulta
                                             S - subsequente
                                 O_ERROR - erro
        
          CRIAÇÃO: CRS 2005/01/25
          NOTAS:
        *********************************************************************************/
        CURSOR c_episode IS
            SELECT 'S'
              FROM episode epis
             WHERE epis.id_patient = i_id_pat
               AND epis.id_institution = i_institution
               AND epis.id_epis_type = i_epis_type
               AND epis.id_clinical_service = i_id_clin_serv
               AND ((epis.flg_status = pk_alert_constant.g_epis_status_inactive AND
                   trunc(months_between(current_timestamp, epis.dt_end_tstz)) <=
                   pk_sysconfig.get_config('MONTHS_FIRST_CONSULT', i_institution, 1)) OR
                   epis.flg_status = pk_alert_constant.g_epis_status_active);
    
    BEGIN
        o_flg   := 'P';
        g_error := 'OPEN CURSOR';
        OPEN c_episode;
        FETCH c_episode
            INTO o_flg;
        CLOSE c_episode;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_owner_name, g_pck_name, 'GET_FIRST_SUBSEQUENT');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN l_ret;
            END;
    END;
    --
    --
    FUNCTION get_first_subseq
    (
        i_lang         IN language.id_language%TYPE,
        i_id_pat       IN patient.id_patient%TYPE,
        i_id_clin_serv IN clinical_service.id_clinical_service%TYPE,
        i_institution  IN institution.id_institution%TYPE,
        i_epis_type    IN episode.id_epis_type%TYPE
    ) RETURN VARCHAR2 IS
        /******************************************************************************
           OBJECTIVO:   Retornar se se trata de uma 1?consulta (P) ou subsequente (S) da
                           especialidade indicada. Retorna VARCHAR2, p/ poder ser usada
                        dentro de um SELECT
           PARAMETROS:  Entrada: I_LANG - Língua
                                    I_ID_PAT - ID do utente
                                 I_ID_CLIN_SERV - ID do tipo de serviço clínico
                        Saida:
        
          CRIAÇÃO: CRS 2005/04/05
          NOTAS: Usado em PK_SCHEDULE.GET_DAILY_SCHEDULE
        *********************************************************************************/
        l_flg   VARCHAR2(50);
        l_error t_error_out;
    BEGIN
        g_error := 'CALL TO PK_SCHEDULE.GET_FIRST_SUBSEQUENT';
        IF NOT get_first_subsequent(i_lang         => i_lang,
                                    i_id_pat       => i_id_pat,
                                    i_id_clin_serv => i_id_clin_serv,
                                    i_institution  => i_institution,
                                    i_epis_type    => i_epis_type,
                                    o_flg          => l_flg,
                                    o_error        => l_error)
        THEN
            RETURN NULL;
        END IF;
    
        RETURN l_flg;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;
    --
    /**********************************************************************************************
    * Get the external episode ID 
    *
    * @param i_lang                   The id language
    * @param i_prof                   Professional, software and institution id
    * @param i_ext_sys                External system ID
    * @param i_episode                Episode ID         
    * @param i_institution            Institution ID
    *
    * @return                         External episode ID
    *
    * @author  Jos?Silva
    * @date    29-12-2011
    * @version 2.5.1.11
    **********************************************************************************************/
    FUNCTION get_epis_ext_sys
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_ext_sys     IN external_sys.id_external_sys%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_institution IN institution.id_institution%TYPE
    ) RETURN epis_ext_sys.value%TYPE IS
    
        l_external_sys external_sys.id_external_sys%TYPE;
        l_ret_value    epis_ext_sys.value%TYPE;
        l_error        t_error_out;
    
        CURSOR c_epis_ext_sys IS
            SELECT ees.value
              FROM epis_ext_sys ees
             WHERE ees.id_episode = i_episode
               AND ees.id_external_sys = l_external_sys
             ORDER BY decode(ees.id_institution, i_institution, 1, 2), ees.id_epis_ext_sys DESC;
    BEGIN
    
        IF i_ext_sys IS NULL
        THEN
            l_external_sys := pk_sysconfig.get_config('ID_EXTERNAL_SYS', i_prof);
        ELSE
            l_external_sys := i_ext_sys;
        END IF;
    
        g_error := 'FETCH EXTERNAL PATIENT ID';
        OPEN c_epis_ext_sys;
        FETCH c_epis_ext_sys
            INTO l_ret_value;
        CLOSE c_epis_ext_sys;
    
        RETURN l_ret_value;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner_name,
                                              g_pck_name,
                                              'GET_EPIS_EXT_SYS',
                                              l_error);
            RAISE;
    END get_epis_ext_sys;
    --
    FUNCTION get_epis_ext
    (
        i_lang       IN language.id_language%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_prof       IN profissional,
        o_dt_efectiv OUT VARCHAR2,
        o_dt_atend   OUT VARCHAR2,
        o_episode    OUT epis_ext_sys.value%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Retornar n?do epis do Sonho, data de efectivação (= data início) e
                           data de atendimento
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                        Saida:   O_DT_EFECTIV - Tipo de episódio
                                 O_DESC_INFO - info do doente
                                 O_ERROR - erro
        
          CRIAÇÃO: CRS 2005/03/17
          ALTERAÇÃO: ASM 2007/04/06
        
          NOTAS:
        *********************************************************************************/
        CURSOR c_ext_sys(i_external_sys IN VARCHAR2) IS
            SELECT nvl(pk_date_utils.to_char_insttimezone(i_prof, e.dt_begin_tstz, 'HH24:MI"h"'), '---') dt_begin,
                   nvl(ee.value, '---') epis_ext,
                   decode(least(nvl(t.dt_first_obs_tstz, current_timestamp + numtodsinterval(100, 'DAY')),
                                nvl(t.dt_first_nurse_obs_tstz, current_timestamp + numtodsinterval(100, 'DAY'))),
                          current_timestamp + numtodsinterval(100, 'DAY'),
                          '---',
                          pk_date_utils.to_char_insttimezone(i_prof,
                                                             least(nvl(t.dt_first_obs_tstz,
                                                                       current_timestamp + numtodsinterval(100, 'DAY')),
                                                                   nvl(t.dt_first_nurse_obs_tstz,
                                                                       current_timestamp + numtodsinterval(100, 'DAY'))),
                                                             'HH24:MI"h"')) dt_first_obs
              FROM episode e
              JOIN epis_info t
                ON t.id_episode = e.id_episode
              LEFT JOIN epis_ext_sys ee
                ON ee.id_episode = e.id_episode
               AND ee.id_external_sys = to_number(i_external_sys)
             WHERE e.id_episode = i_id_episode;
        l_external_sys VARCHAR2(0200 CHAR);
    BEGIN
    
        l_external_sys := pk_sysconfig.get_config(i_code_cf => 'ID_EXTERNAL_SYS', i_prof => i_prof);
    
        -- N?do episódio do Sonho e hora de efectivação
        g_error := 'GET CURSOR EXT_SYS';
        OPEN c_ext_sys(i_external_sys => l_external_sys);
        FETCH c_ext_sys
            INTO o_dt_efectiv, o_episode, o_dt_atend;
        CLOSE c_ext_sys;
    
        o_dt_efectiv := nvl(o_dt_efectiv, '---');
        IF pk_sysconfig.get_config('EXTERNAL_SYSTEM_EXIST', i_prof) = 'N'
        THEN
            o_episode := to_char(i_id_episode);
        ELSE
            o_episode := nvl(o_episode, '---');
        END IF;
        o_dt_atend := nvl(o_dt_atend, '---');
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_owner_name, g_pck_name, 'GET_EPIS_EXT');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- return failure of function_dummy 
                RETURN l_ret;
            END;
        
    END;

    FUNCTION get_prev_episode
    (
        i_lang  IN language.id_language%TYPE,
        i_pat   IN patient.id_patient%TYPE,
        i_type  IN episode.id_epis_type%TYPE,
        i_prof  IN profissional,
        o_epis  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Retornar episódios fechados de um doente
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                                 I_PAT - ID do doente
                                 I_TYPE - tipo de episódio. Se ?estiver preenchido, retorna
                                           os epis. de qq tipo. Para a cons. externa ?1
                        Saida:   O_EPIS - episódios
                                 O_ERROR - erro
        
          CRIAÇÃO: CRS 2005/04/01
          NOTAS:
        *********************************************************************************/
        CURSOR c_pat IS
            SELECT VALUE
              FROM pat_ext_sys pes
             WHERE pes.id_patient = i_pat
               AND pes.id_external_sys = pk_sysconfig.get_config('ID_EXTERNAL_SYS', i_prof);
    
        CURSOR c_timezone(l_institution NUMBER) IS
            SELECT tr.timezone_region
              FROM institution i, timezone_region tr
             WHERE i.id_institution = l_institution
               AND i.id_timezone_region = tr.id_timezone_region;
    
        l_pat             pat_ext_sys.value%TYPE;
        l_mess1           VARCHAR2(200) := pk_message.get_message(i_lang, 'ER_M001');
        l_mess2           VARCHAR2(200) := pk_message.get_message(i_lang, 'ER_M002');
        l_mess3           VARCHAR2(200) := pk_message.get_message(i_lang, 'ER_M003');
        l_exist_er        sys_config.value%TYPE;
        l_num             NUMBER;
        l_timezone_region timezone_region.timezone_region%TYPE := NULL;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
        g_error        := 'OPEN C_PAT';
        OPEN c_pat;
        FETCH c_pat
            INTO l_pat;
        CLOSE c_pat;
    
        g_error := 'OPEN C_TIMEZONE';
        OPEN c_timezone(i_prof.institution);
        FETCH c_timezone
            INTO l_timezone_region;
        CLOSE c_timezone;
    
        g_error    := 'CALL TO PK_SYSCONFIG.GET_CONFIG';
        l_exist_er := pk_sysconfig.get_config('ER_CLIENT_SERVER', i_prof);
    
        g_error := 'GET CURSOR(2)';
        OPEN o_epis FOR
            SELECT e.id_episode,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ei.id_professional) spec_prof,
                   pk_date_utils.to_char_insttimezone(i_prof, e.dt_begin_tstz, 'YYYYMMDDHH24MISS') dt_begin,
                   pk_date_utils.dt_chr_tsz(i_lang, e.dt_begin_tstz, i_prof) date_target,
                   pk_date_utils.date_char_hour_tsz(i_lang, e.dt_begin_tstz, i_prof.institution, i_prof.software) hour_target,
                   decode(e.id_epis_type,
                          pk_alert_constant.g_epis_type_emergency,
                          pk_sysdomain.get_domain('DISCHARGE.FLG_STATUS', d.flg_status, i_lang),
                          pk_alert_constant.g_epis_type_inpatient,
                          pk_sysdomain.get_domain('DISCHARGE.FLG_STATUS', d.flg_status, i_lang),
                          pk_alert_constant.g_epis_type_urgent_care,
                          pk_sysdomain.get_domain('DISCHARGE.FLG_STATUS', d.flg_status, i_lang),
                          pk_alert_constant.g_epis_type_operating,
                          pk_sysdomain.get_domain('DISCHARGE.FLG_STATUS', d.flg_status, i_lang),
                          pk_sysdomain.get_domain('DISCHARGE.FLG_TYPE', d.flg_type, i_lang)) disch_type,
                   -- Diagnosis descriptions
                   pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                              i_prof                => i_prof,
                                              i_id_alert_diagnosis  => ad.id_alert_diagnosis,
                                              i_id_diagnosis        => dg.id_diagnosis,
                                              i_desc_epis_diagnosis => ediag.desc_epis_diagnosis,
                                              i_code                => dg.code_icd,
                                              i_flg_other           => dg.flg_other,
                                              i_flg_std_diag        => ad.flg_icd9,
                                              i_epis_diag           => ediag.id_epis_diagnosis) diag,
                   pk_translation.get_translation(i_lang, 'EPIS_TYPE.CODE_EPIS_TYPE.' || e.id_epis_type) || ': ' ||
                   pk_translation.get_translation(i_lang,
                                                  'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' || e.id_clinical_service) clin_serv,
                   pk_message.get_message(i_lang, 'BARCODE_EPIS_TYPE') flg_type,
                   pk_date_utils.to_char_insttimezone(i_prof, e.dt_begin_tstz, 'YYYYMMDDHH24MISS') dt_ord1,
                   pk_sysconfig.get_config(g_prev_epis_config, i_prof.institution, ei.id_software) id_report
              FROM episode e,
                   epis_info ei,
                   discharge d,
                   diagnosis dg,
                   epis_diagnosis ediag,
                   alert_diagnosis ad,
                   (SELECT MAX(ed1.id_epis_diagnosis) id_epis_diagnosis, id_episode
                      FROM epis_diagnosis ed1
                     WHERE ed1.id_episode IN (SELECT id_episode
                                                FROM episode
                                               WHERE flg_status = 'I'
                                                 AND id_patient = i_pat)
                     GROUP BY id_episode) ed
             WHERE e.id_patient = i_pat
               AND e.flg_status = pk_alert_constant.g_epis_status_inactive
               AND e.id_episode = ei.id_episode
               AND d.id_episode(+) = e.id_episode
               AND d.flg_status(+) != pk_discharge.g_disch_flg_cancel
               AND ed.id_episode(+) = e.id_episode
               AND ediag.id_epis_diagnosis(+) = ed.id_epis_diagnosis
               AND dg.id_diagnosis(+) = ediag.id_diagnosis
               AND ad.id_alert_diagnosis(+) = ediag.id_alert_diagnosis
             ORDER BY e.dt_begin_tstz DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_owner_name, g_pck_name, 'GET_PREV_EPISODE');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN l_ret;
            END;
    END get_prev_episode;

    /**
    * Gets the home medication and the current selected info on the previous medication screen select list.
    *
    * @param i_lang              language identifier
    * @param i_prof              logged professional structure
    * @param i_patient           patient identifier
    * @param i_epis              episode identifiers list
    * @param o_medication        home medication info
    * @param o_home_med_review   info of the current selected item on the previous medication screen (full medication history, partial, ...)
    * @param o_error             error
    *
    * @return                    TRUE or FALSE on success or error
    *
    * @author                    Nuno Alves
    * @version                   2.6.3.8.2
    * @since                     2015/05/12
    */
    FUNCTION get_previous_medication
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_pat             IN patient.id_patient%TYPE,
        i_epis            IN table_number,
        o_medication      OUT pk_types.cursor_type,
        o_home_med_review OUT pk_types.cursor_type,
        o_pat_take        OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'get_previous_medication';
    
        -- Medication get_last_review                                                                      
        l_id_review      NUMBER;
        l_code_review    NUMBER;
        l_review_desc    VARCHAR2(4000);
        l_dt_create      TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_update      TIMESTAMP WITH LOCAL TIME ZONE;
        l_id_prof_create NUMBER;
        l_info_source    CLOB;
        l_pat_not_take   CLOB;
        l_pat_take       CLOB;
        l_notes          VARCHAR2(4000);
    
        -- aux vars
        l_rec_info             info;
        l_table_info           table_info := table_info();
        l_review_signature     VARCHAR2(4000);
        l_pat_take_signature   VARCHAR2(4000);
        l_rec_desc_info_ranked t_rec_desc_info_ranked;
        l_tab_desc_info_ranked t_table_desc_info_ranked := t_table_desc_info_ranked();
    BEGIN
        -- get_last_review gets the current selected option by the professional on previous medication area (full medication history, partial, ...)
        FOR i IN 1 .. i_epis.count
        LOOP
            g_error := 'CALL pk_api_pfh_in.get_last_review';
            pk_alertlog.log_info(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
            IF NOT pk_api_pfh_in.get_last_review(i_lang           => i_lang,
                                                 i_prof           => i_prof,
                                                 i_id_episode     => i_epis(i),
                                                 i_id_patient     => i_pat,
                                                 o_id_review      => l_id_review,
                                                 o_code_review    => l_code_review,
                                                 o_review_desc    => l_review_desc,
                                                 o_dt_create      => l_dt_create,
                                                 o_dt_update      => l_dt_update,
                                                 o_id_prof_create => l_id_prof_create,
                                                 o_info_source    => l_info_source,
                                                 o_pat_not_take   => l_pat_not_take,
                                                 o_pat_take       => l_pat_take,
                                                 o_notes          => l_notes)
            THEN
                RAISE g_exception;
            END IF;
        
            IF l_review_desc IS NOT NULL
            THEN
                l_review_signature := pk_prof_utils.get_detail_signature(i_lang,
                                                                         i_prof,
                                                                         i_epis(i),
                                                                         l_dt_update,
                                                                         l_id_prof_create);
                l_rec_info         := info(id => i_epis(i), desc_info => l_review_desc, signature => l_review_signature);
                l_table_info.extend;
                l_table_info(l_table_info.count) := l_rec_info;
            END IF;
            IF l_pat_take IS NOT NULL
            THEN
                l_pat_take_signature   := pk_prof_utils.get_detail_signature(i_lang,
                                                                             i_prof,
                                                                             i_epis(i),
                                                                             l_dt_update,
                                                                             l_id_prof_create);
                l_rec_desc_info_ranked := t_rec_desc_info_ranked(id        => i_epis(i),
                                                                 desc_info => l_pat_take,
                                                                 num_rank  => NULL,
                                                                 tstz_rank => NULL,
                                                                 signature => l_pat_take_signature);
                l_tab_desc_info_ranked.extend;
                l_tab_desc_info_ranked(l_tab_desc_info_ranked.count) := l_rec_desc_info_ranked;
            END IF;
        END LOOP;
    
        OPEN o_home_med_review FOR
            SELECT t.id id_episode, t.desc_info desc_info, t.signature
              FROM TABLE(l_table_info) t;
        OPEN o_pat_take FOR
            SELECT t.id id_episode, t.desc_info desc_info, t.signature
              FROM TABLE(l_tab_desc_info_ranked) t;
    
        -- Get the home medication list
        g_error := 'CALL pk_api_pfh_clindoc_in.get_prev_med_summ_s';
        pk_alertlog.log_info(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        IF NOT pk_api_pfh_clindoc_in.get_prev_med_summ_s(i_lang       => i_lang,
                                                         i_prof       => i_prof,
                                                         i_patient    => i_pat,
                                                         i_epis       => i_epis,
                                                         o_medication => o_medication,
                                                         o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(o_medication);
            pk_types.open_my_cursor(o_home_med_review);
            pk_types.open_my_cursor(o_pat_take);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_medication);
            pk_types.open_my_cursor(o_home_med_review);
            pk_types.open_my_cursor(o_pat_take);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner_name,
                                              i_package  => g_pck_name,
                                              i_function => 'GET_PREVIOUS_MEDICATION',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_previous_medication;

    /********************************************************************************************
    * Gets the GP notes (notes for colleague) registered in given episode list
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                the episode ID
    * @param o_gp_notes               Cursor containing de note (free text) and the corresponding id_episode 
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Nuno Alves
    * @version                        2.6.3.8.2
    * @since                          2015/05/19
    *
    **********************************************************************************************/
    FUNCTION get_gp_notes
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_tbl_episode IN table_number,
        o_gp_notes    OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        c_id_summary_page summary_page.id_summary_page%TYPE := 40;
    
        l_patient            patient.id_patient%TYPE;
        l_sections           pk_summary_page.t_cur_section;
        l_sections_tab       pk_summary_page.t_coll_section;
        l_record_count       NUMBER;
        l_coll_epis_doc      table_number;
        l_tab_number_discard table_number;
    BEGIN
        IF i_tbl_episode.count = 0
           OR i_tbl_episode(1) IS NULL
        THEN
            RAISE g_exception;
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL pk_episode.get_epis_patient: i_id_episode: ' || i_tbl_episode(1);
        pk_alertlog.log_debug(g_error);
        -- Get patient from episode
        l_patient := pk_episode.get_epis_patient(i_lang => i_lang, i_prof => i_prof, i_episode => i_tbl_episode(1));
    
        g_error := 'CALL pk_summary_page.get_summary_page_sections: i_id_summary_page: ' || c_id_summary_page ||
                   ', i_pat: ' || l_patient;
        pk_alertlog.log_debug(g_error);
        -- Get summary page sections for the assessment scales summary page, but we only need the doc_area ids and the section title
        IF NOT pk_summary_page.get_summary_page_sections(i_lang            => i_lang,
                                                         i_prof            => i_prof,
                                                         i_id_summary_page => c_id_summary_page,
                                                         i_pat             => l_patient,
                                                         o_sections        => l_sections,
                                                         o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        FETCH l_sections BULK COLLECT
            INTO l_sections_tab;
    
        FOR i IN 1 .. l_sections_tab.count
        LOOP
            g_error := 'CALL pk_touch_option.get_doc_area_value_ids function';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_touch_option.get_doc_area_value_ids(i_lang               => i_lang,
                                                          i_prof               => i_prof,
                                                          i_doc_area           => table_number(l_sections_tab(i).id_doc_area),
                                                          i_scope              => i_tbl_episode,
                                                          i_scope_type         => pk_alert_constant.g_scope_type_episode,
                                                          i_fltr_status        => pk_alert_constant.g_active,
                                                          o_record_count       => l_record_count,
                                                          o_coll_epis_doc      => l_coll_epis_doc,
                                                          o_coll_epis_anamn    => l_tab_number_discard,
                                                          o_coll_epis_rev_sys  => l_tab_number_discard,
                                                          o_coll_epis_obs      => l_tab_number_discard,
                                                          o_coll_epis_past_fsh => l_tab_number_discard,
                                                          o_coll_epis_recomend => l_tab_number_discard,
                                                          o_error              => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            g_error := 'OPEN o_gp_notes FOR select from epis_documentation';
            pk_alertlog.log_debug(g_error);
            OPEN o_gp_notes FOR
                SELECT ed.notes desc_info,
                       ed.id_episode id_episode,
                       pk_prof_utils.get_detail_signature(i_lang,
                                                          i_prof,
                                                          ed.id_episode,
                                                          ed.dt_last_update_tstz,
                                                          ed.id_prof_last_update) signature
                  FROM epis_documentation ed
                 WHERE ed.id_epis_documentation IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                     t.column_value
                                                      FROM TABLE(l_coll_epis_doc) t)
                 ORDER BY ed.id_episode DESC, ed.dt_last_update_tstz DESC;
        END LOOP;
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(o_gp_notes);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_gp_notes);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner_name,
                                              i_package  => g_pck_name,
                                              i_function => 'GET_GP_NOTES',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_gp_notes;

    /********************************************************************************************
    * Página resumo
    *
    * @param i_lang              language id
    * @param i_pat               patient id
    * @param i_epis               episode id
    * @param i_prof              professional, software and institution ids
    * @param o_complaint      complaint
    * @param o_history      array with info history
    * @param o_fam_hist      array with info family history
    * @param o_soc_hist      array with info social history
    * @param o_allergy      array with info allergy
    * @param o_habit      array with info habits
    * @param o_relev_disease      array with info relev disease
    * @param o_relev_notes      array with info relevantes notes
    * @param o_medication      array with info medications
    * @param o_info10           array with info
    
    * @param o_error             Error message
    
    * @return                    true or false on success or error
    *
    * @author                    Susana Seixas
    * @since                     2006/02/27
    
    * @alter                    Emília Taborda
    * @since                     2006/06/21
    ********************************************************************************************/
    FUNCTION get_summary_internal
    (
        i_lang            IN NUMBER,
        i_pat             IN NUMBER,
        i_epis            IN table_number,
        i_prof            IN profissional,
        o_complaint       OUT pk_types.cursor_type,
        o_relev_disease   OUT pk_types.cursor_type,
        o_relev_notes     OUT pk_types.cursor_type,
        o_medication      OUT pk_types.cursor_type,
        o_home_med_review OUT pk_types.cursor_type,
        o_pat_take        OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(20 CHAR) := 'GET_SUMMARY_INTERNAL';
        l_error t_error_out;
    
        l_sys_config_show_diag sys_config.id_sys_config%TYPE := pk_sysconfig.get_config(pk_alert_constant.g_diag_area_sys_config,
                                                                                        i_prof);
        -- Medication get_last_review                                                                      
        l_id_review      NUMBER;
        l_code_review    NUMBER;
        l_review_desc    VARCHAR2(4000);
        l_dt_create      TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_update      TIMESTAMP WITH LOCAL TIME ZONE;
        l_id_prof_create NUMBER;
    
        -- aux vars
        l_rec_info   info;
        l_table_info table_info := table_info();
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
        --
        g_error         := 'GET configurations';
        g_documentation := pk_sysconfig.get_config('DOCUMENTATION_TEXT', i_prof);
        --
        --QUEIXA
        g_error := 'GET CURSOR O_COMPLAINT: ' || g_documentation;
        pk_alertlog.log_info(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        OPEN o_complaint FOR
            SELECT c.desc_info, c.signature
              FROM (SELECT ei.id_episode,
                           pk_string_utils.clob_to_varchar2(pk_clinical_info.get_epis_reason_for_visit(i_lang,
                                                                                                       i_prof,
                                                                                                       ei.id_episode,
                                                                                                       s.id_schedule),
                                                            4000) desc_info,
                           pk_prof_utils.get_detail_signature(i_lang,
                                                              i_prof,
                                                              ei.id_episode,
                                                              s.dt_schedule_tstz,
                                                              s.id_prof_schedules) signature
                      FROM epis_info ei
                      LEFT JOIN schedule s
                        ON ei.id_schedule = s.id_schedule
                     WHERE ei.id_episode IN (SELECT /*+opt_estimate(table t rows=1)*/
                                              t.column_value id_episode
                                               FROM TABLE(i_epis) t)) c
             WHERE c.desc_info IS NOT NULL
             ORDER BY c.id_episode;
    
        --DOENÇAS RELEVANTES
        IF g_documentation = g_document_d
        THEN
            g_error := 'GET CURSOR O_HISTORY: ' || g_documentation;
            pk_alertlog.log_info(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
            IF NOT pk_summary_page.get_summ_last_documentation(i_lang          => i_lang,
                                                               i_prof          => i_prof,
                                                               i_episode       => i_epis,
                                                               i_doc_area      => g_area_past_med_hist,
                                                               o_documentation => o_relev_disease,
                                                               o_error         => l_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSE
            g_error := 'OPEN o_relev_disease';
            pk_alertlog.log_info(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
            IF NOT pk_past_history.get_past_history_info(i_lang         => i_lang,
                                                         i_prof         => i_prof,
                                                         i_epis         => i_epis,
                                                         i_pat          => i_pat,
                                                         i_flg_type     => pk_past_history.g_alert_diag_type_med,
                                                         i_doc_area     => pk_past_history.g_doc_area_past_med,
                                                         o_past_history => o_relev_disease,
                                                         o_error        => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
        END IF;
        --
        --NOTAS RELEVANTES
        g_error := 'CURSOR O_RELEV_NOTES';
        pk_alertlog.log_info(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
    
        IF NOT pk_past_history.get_past_history_info(i_lang         => i_lang,
                                                     i_prof         => i_prof,
                                                     i_epis         => i_epis,
                                                     i_pat          => i_pat,
                                                     i_flg_type     => pk_past_history.g_alert_diag_type_med,
                                                     i_doc_area     => pk_past_history.g_doc_area_relev_notes,
                                                     o_past_history => o_relev_notes,
                                                     o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        --
        -- MEDICAÇÃO ANTERIOR (Home medication)
        IF NOT get_previous_medication(i_lang            => i_lang,
                                       i_prof            => i_prof,
                                       i_pat             => i_pat,
                                       i_epis            => i_epis,
                                       o_medication      => o_medication,
                                       o_home_med_review => o_home_med_review,
                                       o_pat_take        => o_pat_take,
                                       o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            o_error := l_error;
            pk_types.open_my_cursor(o_complaint);
            pk_types.open_my_cursor(o_relev_disease);
            pk_types.open_my_cursor(o_relev_notes);
            pk_types.open_my_cursor(o_medication);
            pk_types.open_my_cursor(o_home_med_review);
            pk_types.open_my_cursor(o_pat_take);
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_complaint);
                pk_types.open_my_cursor(o_relev_disease);
                pk_types.open_my_cursor(o_relev_notes);
                pk_types.open_my_cursor(o_medication);
                pk_types.open_my_cursor(o_home_med_review);
                pk_types.open_my_cursor(o_pat_take);
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_owner_name, g_pck_name, 'GET_SUMMARY_INTERNAL');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN l_ret;
            END;
    END get_summary_internal;

    --
    --
    /********************************************************************************************
    * Página resumo
    *
    * @param i_lang              language id
    * @param i_pat               patient id
    * @param i_epis               episode id
    * @param i_prof              professional, software and institution ids
    * @param o_complaint      complaint
    * @param o_history      array with info history
    * @param o_fam_hist      array with info family history
    * @param o_soc_hist      array with info social history
    * @param o_allergy      array with info allergy
    * @param o_habit      array with info habits
    * @param o_relev_disease      array with info relev disease
    * @param o_relev_notes      array with info relevantes notes
    * @param o_medication      array with info medications
    * @param o_info10           array with info
    
    * @param o_error             Error message
    
    * @return                    true or false on success or error
    *
    * @author                    Susana Seixas
    * @since                     2006/02/27
    
    * @alter                    Emília Taborda
    * @since                     2006/06/21
    ********************************************************************************************/
    FUNCTION get_summary_s
    (
        i_lang            IN NUMBER,
        i_pat             IN NUMBER,
        i_epis            IN table_number,
        i_prof            IN profissional,
        o_complaint       OUT pk_types.cursor_type,
        o_history_doc     OUT pk_types.cursor_type,
        o_history_ft      OUT pk_types.cursor_type,
        o_fam_hist        OUT pk_types.cursor_type,
        o_soc_hist        OUT pk_types.cursor_type,
        o_allergy         OUT pk_types.cursor_type,
        o_habit           OUT pk_types.cursor_type,
        o_relev_disease   OUT pk_types.cursor_type,
        o_relev_notes     OUT pk_types.cursor_type,
        o_medication      OUT pk_types.cursor_type,
        o_info10          OUT pk_types.cursor_type,
        o_home_med_review OUT pk_types.cursor_type,
        o_pat_take        OUT pk_types.cursor_type,
        o_surgical_hist   OUT pk_types.cursor_type,
        
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(13 CHAR) := 'GET_SUMMARY_S';
        l_error t_error_out;
    BEGIN
        g_sysdate_tstz := current_timestamp;
        --
        g_error         := 'GET configurations';
        g_documentation := pk_sysconfig.get_config('DOCUMENTATION_TEXT', i_prof);
    
        g_error := 'CALL get_summary_internal';
        pk_alertlog.log_info(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        IF NOT get_summary_internal(i_lang            => i_lang,
                                    i_pat             => i_pat,
                                    i_epis            => i_epis,
                                    i_prof            => i_prof,
                                    o_complaint       => o_complaint,
                                    o_relev_disease   => o_relev_disease,
                                    o_relev_notes     => o_relev_notes,
                                    o_medication      => o_medication,
                                    o_home_med_review => o_home_med_review,
                                    o_pat_take        => o_pat_take,
                                    o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        --
        --HISTÓRIA
        g_error := 'GET CURSOR O_HISTORY_DOC: ' || g_documentation;
        IF NOT pk_summary_page.get_summ_last_documentation(i_lang          => i_lang,
                                                           i_prof          => i_prof,
                                                           i_episode       => i_epis,
                                                           i_doc_area      => g_area_history,
                                                           o_documentation => o_history_doc,
                                                           o_error         => l_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'OPEN CURSOR o_history_ft';
        OPEN o_history_ft FOR
            SELECT pk_string_utils.clob_to_sqlvarchar2(e.desc_epis_anamnesis) desc_info,
                   pk_date_utils.date_send_tsz(i_lang, e.dt_epis_anamnesis_tstz, i_prof) dt_epis_anamnesis,
                   e.flg_temp,
                   decode(e.flg_temp, g_flg_def, NULL, e.id_epis_anamnesis) id,
                   e.id_episode
              FROM epis_anamnesis e
             WHERE e.id_episode IN (SELECT *
                                      FROM TABLE(CAST(i_epis AS table_number)))
               AND e.flg_temp IN (g_flg_temp, g_flg_def)
               AND e.flg_type = g_flg_anamnesis
               AND e.dt_epis_anamnesis_tstz = decode(e.flg_temp,
                                                     g_flg_temp,
                                                     ((SELECT MAX(e2.dt_epis_anamnesis_tstz)
                                                         FROM epis_anamnesis e2
                                                        WHERE e2.id_episode = e.id_episode
                                                          AND e2.id_professional = e.id_professional
                                                          AND e2.flg_type = g_flg_anamnesis)),
                                                     e.dt_epis_anamnesis_tstz)
             ORDER BY flg_temp, dt_epis_anamnesis;
    
        --HISTÓRIA FAMILIAR
        g_error := 'OPEN O_FAMILY_HIST';
        IF NOT pk_past_history.get_last_past_hist(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  i_patient      => i_pat,
                                                  i_episode      => i_epis(1),
                                                  i_doc_area     => pk_past_history.g_doc_area_past_fam,
                                                  o_past_history => o_fam_hist,
                                                  o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        --
        --HISTÓRIA SOCIAL
        g_error := 'OPEN O_SOC_HIST';
        IF NOT pk_past_history.get_last_past_hist(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  i_patient      => i_pat,
                                                  i_episode      => i_epis(1),
                                                  i_doc_area     => pk_past_history.g_doc_area_past_soc,
                                                  o_past_history => o_soc_hist,
                                                  o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
        --
        --ALERGIAS
    
        g_error := 'CALL get_allergies';
        pk_alertlog.log_info(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        IF NOT pk_allergy.get_allergies(i_lang    => i_lang,
                                        i_prof    => i_prof,
                                        i_episode => i_epis,
                                        i_patient => i_pat,
                                        o_allergy => o_allergy,
                                        o_error   => o_error)
        THEN
            RAISE g_exception;
        END IF;
        --
        --HÁBITOS
    
        g_error := 'CALL pk_patient.get_habits';
        pk_alertlog.log_info(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        IF NOT pk_patient.get_habits(i_lang  => i_lang,
                                     i_prof  => i_prof,
                                     i_epis  => i_epis,
                                     o_habit => o_habit,
                                     o_error => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        -- past surgical history
        IF NOT pk_past_history.get_past_history_info(i_lang         => i_lang,
                                                     i_prof         => i_prof,
                                                     i_epis         => i_epis,
                                                     i_pat          => i_pat,
                                                     i_flg_type     => pk_past_history.g_alert_diag_type_surg,
                                                     i_doc_area     => pk_past_history.g_doc_area_past_surg,
                                                     o_past_history => o_surgical_hist,
                                                     o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
        --
        pk_types.open_my_cursor(o_info10);
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            o_error := l_error;
            pk_types.open_my_cursor(o_complaint);
            pk_types.open_my_cursor(o_history_doc);
            pk_types.open_my_cursor(o_history_ft);
            pk_types.open_my_cursor(o_fam_hist);
            pk_types.open_my_cursor(o_soc_hist);
            pk_types.open_my_cursor(o_allergy);
            pk_types.open_my_cursor(o_habit);
            pk_types.open_my_cursor(o_relev_disease);
            pk_types.open_my_cursor(o_relev_notes);
            pk_types.open_my_cursor(o_medication);
            pk_types.open_my_cursor(o_home_med_review);
            pk_types.open_my_cursor(o_pat_take);
            pk_types.open_my_cursor(o_info10);
            pk_types.open_my_cursor(o_surgical_hist);
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_complaint);
                pk_types.open_my_cursor(o_history_doc);
                pk_types.open_my_cursor(o_history_ft);
                pk_types.open_my_cursor(o_fam_hist);
                pk_types.open_my_cursor(o_soc_hist);
                pk_types.open_my_cursor(o_allergy);
                pk_types.open_my_cursor(o_habit);
                pk_types.open_my_cursor(o_relev_disease);
                pk_types.open_my_cursor(o_relev_notes);
                pk_types.open_my_cursor(o_medication);
                pk_types.open_my_cursor(o_home_med_review);
                pk_types.open_my_cursor(o_pat_take);
                pk_types.open_my_cursor(o_info10);
                pk_types.open_my_cursor(o_surgical_hist);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_owner_name, g_pck_name, 'GET_SUMMARY_S');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN l_ret;
            END;
    END;

    --
    --
    /********************************************************************************************
    * Página resumo
    *
    * @param i_lang              language id
    * @param i_pat               patient id
    * @param i_epis               episode id
    * @param i_prof              professional, software and institution ids
    * @param i_review            indicates if the summary includes Review of system
    * @param o_complaint      complaint
    * @param o_history      array with info history
    * @param o_review      array with info of review of system
    * @param o_fam_hist      array with info family history
    * @param o_soc_hist      array with info social history
    * @param o_allergy      array with info allergy
    * @param o_habit      array with info habits
    * @param o_relev_disease      array with info relev disease
    * @param o_relev_notes      array with info relevantes notes
    * @param o_medication      array with info medications
    * @param o_info10           array with info
    
    * @param o_error             Error message
    
    * @return                    true or false on success or error
    *
    * @author                    Susana Seixas
    * @since                     2006/02/27
    
    * @alter                    Emília Taborda
    * @since                     2006/06/21
    * @alter                    Orlando Antunes
    * @since                     2007/10/01
    * NOTAS: Esta função deve ser completamente remodelada!
    * @alter                    Rita Lopes
    * @since                     2008/03/20
    * Alterar a flg da medicação anterior de C para D
    ********************************************************************************************/
    FUNCTION get_summary_s
    (
        i_lang            IN NUMBER,
        i_pat             IN NUMBER,
        i_epis            IN table_number,
        i_prof            IN profissional,
        i_review          IN BOOLEAN,
        o_complaint       OUT pk_types.cursor_type,
        o_history         OUT pk_types.cursor_type,
        o_review          OUT pk_types.cursor_type,
        o_fam_hist        OUT pk_types.cursor_type,
        o_soc_hist        OUT pk_types.cursor_type,
        o_allergy         OUT pk_types.cursor_type,
        o_habit           OUT pk_types.cursor_type,
        o_relev_disease   OUT pk_types.cursor_type,
        o_relev_notes     OUT pk_types.cursor_type,
        o_medication      OUT pk_types.cursor_type,
        o_home_med_review OUT pk_types.cursor_type,
        o_pat_take        OUT pk_types.cursor_type,
        o_info10          OUT pk_types.cursor_type,
        o_surgical_hist   OUT pk_types.cursor_type,
        
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_error  t_error_out;
        l_review BOOLEAN := i_review;
    
        CURSOR c_epis IS
            SELECT *
              FROM TABLE(i_epis);
    
        l_episode  episode.id_episode%TYPE;
        l_id_compl epis_anamnesis.id_epis_anamnesis%TYPE;
        l_id_anamn epis_anamnesis.id_epis_anamnesis%TYPE;
    
        --
        l_count NUMBER;
    
        l_sys_config_show_diag sys_config.id_sys_config%TYPE := pk_sysconfig.get_config(pk_alert_constant.g_diag_area_sys_config,
                                                                                        i_prof);
        l_func_name            VARCHAR2(200 CHAR) := 'GET_SUMMARY_S';
        l_notes                sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'PAST_HISTORY_M062');
    BEGIN
        g_sysdate_tstz := current_timestamp;
        --
        g_error         := 'GET configurations';
        g_documentation := pk_sysconfig.get_config('DOCUMENTATION_TEXT', i_prof);
    
        OPEN c_epis;
        FETCH c_epis
            INTO l_episode;
        CLOSE c_epis;
    
        --REVIEW OF SYSTEMS
        --Se não ?feito o set de um valor, considera-se false por defeito
        IF l_review IS NULL
        THEN
            l_review := FALSE;
        END IF;
    
        IF l_review
        THEN
            --Revisão de sistemas - esta função devolve o conteudo quer para documentation quer para texto livre
            g_error := 'GET CURSOR O_REVIEW: ' || g_documentation;
            IF NOT pk_clinical_info.get_summ_last_review_system(i_lang       => i_lang,
                                                                i_episode    => l_episode,
                                                                i_prof       => i_prof,
                                                                o_rev_system => o_review,
                                                                o_error      => l_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSE
            --abre o cursor...
            pk_types.open_my_cursor(o_review);
        END IF;
    
        ----------------------------Copy of the old function---------------------------
    
        --
        --HISTÓRIA
        g_error := 'CALL pk_clinical_info.get_summ_last_anamnesis - ' || g_flg_anamnesis;
        IF NOT pk_clinical_info.get_summ_last_anamnesis(i_lang      => i_lang,
                                                        i_episode   => l_episode,
                                                        i_prof      => i_prof,
                                                        i_flg_type  => g_flg_anamnesis,
                                                        o_anamnesis => o_history,
                                                        o_error     => l_error)
        THEN
            RAISE g_exception;
        END IF;
    
        --
        --HISTÓRIA FAMILIAR
        g_error := 'OPEN O_FAMILY_HIST';
        IF NOT pk_past_history.get_last_past_hist(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  i_patient      => i_pat,
                                                  i_episode      => l_episode,
                                                  i_doc_area     => pk_past_history.g_doc_area_past_fam,
                                                  o_past_history => o_fam_hist,
                                                  o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        --
        --HISTÓRIA SOCIAL
        g_error := 'OPEN O_SOC_HIST';
        IF NOT pk_past_history.get_last_past_hist(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  i_patient      => i_pat,
                                                  i_episode      => l_episode,
                                                  i_doc_area     => pk_past_history.g_doc_area_past_soc,
                                                  o_past_history => o_soc_hist,
                                                  o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        --
        --ALERGIAS
    
        g_error := 'CALL get_allergies';
        pk_alertlog.log_info(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        IF NOT pk_allergy.get_allergies(i_lang    => i_lang,
                                        i_prof    => i_prof,
                                        i_episode => i_epis,
                                        i_patient => i_pat,
                                        o_allergy => o_allergy,
                                        o_error   => o_error)
        THEN
            RAISE g_exception;
        END IF;
        --
        --HÁBITOS
        g_error := 'CALL pk_patient.get_habits';
        pk_alertlog.log_info(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        IF NOT pk_patient.get_habits(i_lang  => i_lang,
                                     i_prof  => i_prof,
                                     i_epis  => i_epis,
                                     o_habit => o_habit,
                                     o_error => o_error)
        THEN
            RAISE g_exception;
        END IF;
        --
        --NOTAS RELEVANTES
        g_error := 'CURSOR O_RELEV_NOTES';
    
        IF NOT pk_past_history.get_past_history_info(i_lang         => i_lang,
                                                     i_prof         => i_prof,
                                                     i_epis         => i_epis,
                                                     i_pat          => i_pat,
                                                     i_flg_type     => pk_past_history.g_alert_diag_type_med,
                                                     i_doc_area     => pk_past_history.g_doc_area_relev_notes,
                                                     o_past_history => o_relev_notes,
                                                     o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
        --
        --MEDICAÇÃO ANTERIOR
        g_error := 'CALL pk_api_pfh_clindoc_in.get_prev_med_summ_s';
        IF NOT get_previous_medication(i_lang            => i_lang,
                                       i_prof            => i_prof,
                                       i_pat             => i_pat,
                                       i_epis            => i_epis,
                                       o_medication      => o_medication,
                                       o_home_med_review => o_home_med_review,
                                       o_pat_take        => o_pat_take,
                                       o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        ----------------------------END of Copy of the old function-------------------------------------------------------
    
        --MOTIVO DE CONSULTA
        g_error := 'GET CURSOR O_COMPLAINT: ' || g_documentation;
        --procura o último registo de motivo de consulta
        IF NOT pk_clinical_info.get_last_id_epis_anamnesis(i_lang     => i_lang,
                                                           i_episode  => l_episode,
                                                           i_flg_type => g_flg_complaint,
                                                           o_id_compl => l_id_compl,
                                                           o_id_anamn => l_id_anamn,
                                                           o_error    => l_error)
        THEN
            RAISE g_exception;
        END IF;
        --Verifica se foi encontrado o último registo
        --Se não for encontrado retorna tudo o que existir?
    
        IF l_id_compl IS NOT NULL
        THEN
        
            SELECT COUNT(*)
              INTO l_count
              FROM (SELECT 1
                      FROM epis_anamnesis ea
                     WHERE ea.id_epis_anamnesis = l_id_compl
                    UNION ALL
                    SELECT 1
                      FROM epis_complaint ec
                     WHERE ec.id_episode = l_episode
                       AND ec.flg_status = pk_alert_constant.g_active
                    UNION ALL
                    SELECT 1
                      FROM epis_info ei
                      JOIN schedule s
                        ON s.id_schedule = ei.id_schedule
                     WHERE ei.id_episode = l_episode
                       AND (s.reason_notes IS NOT NULL OR decode(s.flg_reason_type, 'C', s.id_reason, NULL) IS NOT NULL));
        
            IF l_count > 0
            THEN
                OPEN o_complaint FOR
                    SELECT pk_utils.concatenate_list(CURSOR
                                                     (SELECT pk_string_utils.clob_to_sqlvarchar2(ea.desc_epis_anamnesis) desc_info2
                                                        FROM epis_anamnesis ea
                                                       WHERE ea.id_epis_anamnesis = l_id_compl
                                                      UNION ALL
                                                      SELECT decode(ec.id_complaint,
                                                                    NULL,
                                                                    ec.patient_complaint,
                                                                    pk_translation.get_translation(i_lang,
                                                                                                   'COMPLAINT.CODE_COMPLAINT.' ||
                                                                                                   ec.id_complaint)) desc_info2
                                                        FROM epis_complaint ec
                                                       WHERE ec.id_episode = l_episode
                                                         AND ec.flg_status = pk_alert_constant.g_active
                                                      
                                                      UNION ALL
                                                      SELECT TRIM(s.reason_notes || chr(10) ||
                                                                  decode(decode(s.flg_reason_type,
                                                                                'C',
                                                                                s.id_reason,
                                                                                NULL),
                                                                         NULL,
                                                                         NULL,
                                                                         pk_translation.get_translation(i_lang,
                                                                                                        'COMPLAINT.CODE_COMPLAINT.' ||
                                                                                                        s.id_reason))) reason
                                                        FROM epis_info ei
                                                        JOIN schedule s
                                                          ON s.id_schedule = ei.id_schedule
                                                       WHERE ei.id_episode = l_episode
                                                         AND (s.reason_notes IS NOT NULL OR
                                                             (s.id_reason IS NOT NULL AND s.flg_reason_type = 'C'))),
                                                     '; ') desc_info
                      FROM dual;
            ELSE
                pk_types.open_my_cursor(o_complaint);
            END IF;
        ELSE
        
            SELECT COUNT(*)
              INTO l_count
              FROM (SELECT 1
                      FROM epis_anamnesis ea
                     WHERE ea.id_episode = l_episode
                       AND ea.flg_type = g_flg_complaint
                    UNION ALL
                    SELECT 1
                      FROM epis_complaint ec
                     WHERE ec.id_episode = l_episode
                       AND ec.flg_status = pk_alert_constant.g_active
                    UNION ALL
                    SELECT 1
                      FROM epis_info ei
                      JOIN schedule s
                        ON s.id_schedule = ei.id_schedule
                     WHERE ei.id_episode = l_episode
                       AND (s.reason_notes IS NOT NULL OR decode(s.flg_reason_type, 'C', s.id_reason, NULL) IS NOT NULL));
        
            IF l_count > 0
            THEN
                OPEN o_complaint FOR
                    SELECT pk_utils.concatenate_list(CURSOR
                                                     (SELECT pk_string_utils.clob_to_sqlvarchar2(ea.desc_epis_anamnesis) desc_info2
                                                        FROM epis_anamnesis ea
                                                       WHERE ea.id_episode = l_episode
                                                         AND ea.flg_type = g_flg_complaint
                                                      UNION ALL
                                                      SELECT decode(ec.id_complaint,
                                                                    NULL,
                                                                    ec.patient_complaint,
                                                                    pk_translation.get_translation(i_lang,
                                                                                                   'COMPLAINT.CODE_COMPLAINT.' ||
                                                                                                   ec.id_complaint)) desc_info2
                                                        FROM epis_complaint ec
                                                       WHERE ec.id_episode = l_episode
                                                         AND ec.flg_status = pk_alert_constant.g_active
                                                      UNION ALL
                                                      SELECT TRIM(s.reason_notes || chr(10) ||
                                                                  decode(decode(s.flg_reason_type,
                                                                                'C',
                                                                                s.id_reason,
                                                                                NULL),
                                                                         NULL,
                                                                         NULL,
                                                                         pk_translation.get_translation(i_lang,
                                                                                                        'COMPLAINT.CODE_COMPLAINT.' ||
                                                                                                        s.id_reason))) reason
                                                        FROM epis_info ei
                                                        JOIN schedule s
                                                          ON s.id_schedule = ei.id_schedule
                                                       WHERE ei.id_episode = l_episode
                                                         AND (s.reason_notes IS NOT NULL OR
                                                             (s.id_reason IS NOT NULL AND s.flg_reason_type = 'C'))),
                                                     '; ') desc_info
                      FROM dual;
            ELSE
                pk_types.open_my_cursor(o_complaint);
            END IF;
        END IF;
    
        --DOENÇAS RELEVANTES
        g_error := 'pk_past_history.get_past_history_info: ' || g_documentation;
    
        -- past medical history
        IF NOT pk_past_history.get_past_history_info(i_lang         => i_lang,
                                                     i_prof         => i_prof,
                                                     i_epis         => i_epis,
                                                     i_pat          => i_pat,
                                                     i_flg_type     => pk_past_history.g_alert_diag_type_med,
                                                     i_doc_area     => pk_past_history.g_doc_area_past_med,
                                                     o_past_history => o_relev_disease,
                                                     o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- past surgical history
        IF NOT pk_past_history.get_past_history_info(i_lang         => i_lang,
                                                     i_prof         => i_prof,
                                                     i_epis         => i_epis,
                                                     i_pat          => i_pat,
                                                     i_flg_type     => pk_past_history.g_alert_diag_type_surg,
                                                     i_doc_area     => pk_past_history.g_doc_area_past_surg,
                                                     o_past_history => o_surgical_hist,
                                                     o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
        --
        --The cursor o_info10 is not being used in previous version and to solve the 
        --Issue ALERT-147545 it will be used to return the Objective free text information. 
        OPEN o_info10 FOR
            SELECT e.desc_epis_recomend_clob desc_info,
                   pk_date_utils.date_send_tsz(i_lang, e.dt_epis_recomend_tstz, i_prof.institution, i_prof.software) dt_epis_recomend,
                   e.flg_temp,
                   decode(e.flg_temp, g_flg_def, NULL, e.id_epis_recomend) id,
                   e.id_episode
              FROM epis_recomend e
             WHERE e.id_episode IN (SELECT *
                                      FROM TABLE(i_epis))
               AND e.flg_temp IN (g_flg_temp, g_flg_def)
               AND e.flg_type = g_flg_subj
             ORDER BY flg_temp, dt_epis_recomend;
        --
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(o_complaint);
            pk_types.open_my_cursor(o_history);
            pk_types.open_my_cursor(o_review);
            pk_types.open_my_cursor(o_fam_hist);
            pk_types.open_my_cursor(o_soc_hist);
            pk_types.open_my_cursor(o_allergy);
            pk_types.open_my_cursor(o_habit);
            pk_types.open_my_cursor(o_relev_disease);
            pk_types.open_my_cursor(o_relev_notes);
            pk_types.open_my_cursor(o_medication);
            pk_types.open_my_cursor(o_home_med_review);
            pk_types.open_my_cursor(o_pat_take);
            pk_types.open_my_cursor(o_info10);
        
            o_error := l_error;
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_complaint);
                pk_types.open_my_cursor(o_history);
                pk_types.open_my_cursor(o_review);
                pk_types.open_my_cursor(o_fam_hist);
                pk_types.open_my_cursor(o_soc_hist);
                pk_types.open_my_cursor(o_allergy);
                pk_types.open_my_cursor(o_habit);
                pk_types.open_my_cursor(o_relev_disease);
                pk_types.open_my_cursor(o_relev_notes);
                pk_types.open_my_cursor(o_medication);
                pk_types.open_my_cursor(o_home_med_review);
                pk_types.open_my_cursor(o_pat_take);
                pk_types.open_my_cursor(o_info10);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_owner_name, g_pck_name, 'GET_SUMMARY_S');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN l_ret;
            END;
        
    END get_summary_s; --with review of systems...
    --
    --

    FUNCTION get_summary_o_internal
    (
        i_lang        IN NUMBER,
        i_pat         IN NUMBER,
        i_epis        IN table_number,
        i_prof        IN profissional,
        o_vital_sign  OUT pk_types.cursor_type,
        o_biometric   OUT pk_types.cursor_type,
        o_blood_group OUT pk_types.cursor_type,
        o_info7       OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                         I_PAT - ID do paciente
                                 I_EPIS - ID do episódio
                                 I_PROF - profissional que acede
                        Saída: O_INFO - informação
                               O_ERROR - erro
        
          CRIAÇÃO: SS 2006/02/27
          ALTERADO: ET 2006/06/21
          NOTAS: RdSN 2007/02/18 Recebe um array de episódios em vez de um NUMBER (necessário p/ Saúde Materna)
          ALTERADO: Orlando Antunes 2006/10/03
          NOTAS: Esta função deve ser completamente remodelada!
        *********************************************************************************/
        l_msg_header_blood sys_message.desc_message%TYPE;
    
        l_decimal_symbol VARCHAR2(1);
        l_error          t_error_out;
    BEGIN
        l_decimal_symbol := pk_sysconfig.get_config(i_code_cf => 'DECIMAL_SYMBOL', i_prof => i_prof);
    
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'OPEN O_VITAL_SIGN';
        OPEN o_vital_sign FOR
            SELECT *
              FROM (SELECT pk_translation.get_translation(i_lang, vs.code_vital_sign) || ' ' ||
                           nvl(to_char(vs_ea.value),
                               pk_vital_sign.get_vs_alias(i_lang, vs_ea.id_patient, vsd.code_vital_sign_desc)) ||
                           nvl2(nvl(vs_ea.id_unit_measure, vs_ea.id_vs_scales_element), ' ', '') ||
                           pk_vital_sign.get_vital_sign_unit_measure(i_lang,
                                                                     vs_ea.id_unit_measure,
                                                                     vs_ea.id_vs_scales_element) ||
                           nvl2(vs_ea.id_vs_scales_element, ' ', '') ||
                           pk_vital_sign.get_vs_scale_shortdesc(i_lang, vs_ea.id_vs_scales_element) ||
                           decode(pk_vital_sign.check_vs_notes(vs_ea.id_vital_sign_read),
                                  pk_alert_constant.g_yes,
                                  ' ' || pk_message.get_message(i_lang, i_prof, 'COMMON_M101'),
                                  '') desc_info,
                           pk_date_utils.date_send_tsz(i_lang, vs_ea.dt_vital_sign_read, i_prof) dt_vs_read,
                           decode(vs_ea.relation_domain, pk_alert_constant.g_vs_rel_sum, 2, 1) rank,
                           vs_ea.id_episode,
                           pk_prof_utils.get_detail_signature(i_lang,
                                                              i_prof,
                                                              vs_ea.id_episode,
                                                              vs_ea.dt_vital_sign_read,
                                                              vs_ea.id_prof_read) signature
                      FROM vital_signs_ea vs_ea, vital_sign vs, vital_sign_desc vsd
                     WHERE EXISTS (SELECT /*+ cardinality (t 1)*/
                             1
                              FROM TABLE(i_epis) t
                             WHERE vs_ea.id_episode = t.column_value)
                       AND vs_ea.flg_state = pk_alert_constant.g_active
                       AND vsd.id_vital_sign_desc(+) = vs_ea.id_vital_sign_desc
                       AND vs.id_vital_sign = vs_ea.id_vital_sign
                       AND vs.flg_available = pk_alert_constant.g_yes
                       AND vs.flg_vs = pk_alert_constant.g_vs_flg_vs
                       AND vs.flg_show = pk_alert_constant.g_yes
                       AND pk_delivery.check_vs_read_from_fetus(vs_ea.id_vital_sign_read) = 0
                       AND NOT EXISTS (SELECT 1
                              FROM vital_sign_relation vsre
                             WHERE vsre.id_vital_sign_detail = vs_ea.id_vital_sign
                               AND vsre.relation_domain IN (pk_alert_constant.g_vs_rel_conc))
                    UNION ALL
                    -----------------------------------------------------------
                    SELECT DISTINCT pk_translation.get_translation(i_lang, vs.code_vital_sign) || ' ' ||
                                    decode((SELECT pk_vital_sign.get_bloodpressure_value(vsre.id_vital_sign_parent,
                                                                                        vs_ea.id_patient,
                                                                                        vs_ea.id_episode,
                                                                                        vs_ea.dt_vital_sign_read,
                                                                                        l_decimal_symbol)
                                             FROM dual),
                                           '/',
                                           NULL,
                                           (SELECT pk_vital_sign.get_bloodpressure_value(vsre.id_vital_sign_parent,
                                                                                         vs_ea.id_patient,
                                                                                         vs_ea.id_episode,
                                                                                         vs_ea.dt_vital_sign_read,
                                                                                         l_decimal_symbol)
                                              FROM dual)) || nvl2(vs_ea.id_unit_measure, ' ', '') ||
                                    pk_vital_sign.get_vital_sign_unit_measure(i_lang, vs_ea.id_unit_measure, NULL) ||
                                    decode(pk_vital_sign.check_vs_notes(vs_ea.id_vital_sign_read),
                                           pk_alert_constant.g_yes,
                                           ' ' || pk_message.get_message(i_lang, i_prof, 'COMMON_M101'),
                                           '') desc_info,
                                    pk_date_utils.date_send_tsz(i_lang, vs_ea.dt_vital_sign_read, i_prof) dt_vs_read,
                                    1 rank,
                                    vs_ea.id_episode,
                                    pk_prof_utils.get_detail_signature(i_lang,
                                                                       i_prof,
                                                                       vs_ea.id_episode,
                                                                       vs_ea.dt_vital_sign_read,
                                                                       vs_ea.id_prof_read) signature
                      FROM vital_signs_ea vs_ea, vital_sign vs, vital_sign_relation vsre
                     WHERE EXISTS (SELECT /*+ cardinality (t 1)*/
                             1
                              FROM TABLE(i_epis) t
                             WHERE vs_ea.id_episode = t.column_value)
                       AND vsre.id_vital_sign_parent = vs.id_vital_sign
                       AND vs_ea.flg_state = pk_alert_constant.g_active
                       AND vsre.id_vital_sign_detail = vs_ea.id_vital_sign(+)
                       AND vsre.relation_domain(+) = pk_alert_constant.g_vs_rel_conc
                       AND pk_delivery.check_vs_read_from_fetus(vs_ea.id_vital_sign_read) = 0
                    UNION ALL
                    SELECT DISTINCT pk_translation.get_translation(i_lang, vs.code_vital_sign) || ' ' ||
                                    decode((SELECT pk_vital_sign.get_bloodpressure_value(vsre.id_vital_sign_parent,
                                                                                        vs_ea.id_patient,
                                                                                        vs_ea.id_episode,
                                                                                        vs_ea.dt_vital_sign_read,
                                                                                        l_decimal_symbol)
                                             FROM dual),
                                           '/',
                                           NULL,
                                           (SELECT pk_vital_sign.get_bloodpressure_value(vsre.id_vital_sign_parent,
                                                                                         vs_ea.id_patient,
                                                                                         vs_ea.id_episode,
                                                                                         vs_ea.dt_vital_sign_read,
                                                                                         l_decimal_symbol)
                                              FROM dual)) || nvl2(vs_ea.id_unit_measure, ' ', '') ||
                                    pk_vital_sign.get_vital_sign_unit_measure(i_lang, vs_ea.id_unit_measure, NULL) ||
                                    decode(pk_vital_sign.check_vs_notes(vs_ea.id_vital_sign_read),
                                           pk_alert_constant.g_yes,
                                           ' ' || pk_message.get_message(i_lang, i_prof, 'COMMON_M101'),
                                           '') desc_info,
                                    pk_date_utils.date_send_tsz(i_lang, vs_ea.dt_vital_sign_read, i_prof) dt_vs_read,
                                    1 rank,
                                    vs_ea.id_episode,
                                    pk_prof_utils.get_detail_signature(i_lang,
                                                                       i_prof,
                                                                       vs_ea.id_episode,
                                                                       vs_ea.dt_vital_sign_read,
                                                                       vs_ea.id_prof_read) signature
                      FROM vital_signs_ea vs_ea, vital_sign vs, vital_sign_relation vsre
                     WHERE vs_ea.id_episode IS NULL
                       AND id_patient = i_pat
                       AND vsre.id_vital_sign_parent = vs.id_vital_sign
                       AND vs_ea.flg_state = pk_alert_constant.g_active
                       AND vsre.id_vital_sign_detail = vs_ea.id_vital_sign(+)
                       AND vsre.relation_domain(+) = pk_alert_constant.g_vs_rel_conc
                       AND pk_delivery.check_vs_read_from_fetus(vs_ea.id_vital_sign_read) = 0
                    -----------------------------------------------------------
                    UNION ALL
                    SELECT DISTINCT pk_translation.get_translation(i_lang, vs.code_vital_sign) || ': ' ||
                                    to_char(aux.val) desc_info,
                                    pk_date_utils.date_send_tsz(i_lang, aux.dt_vital_sign_read, i_prof) dt_vs_read,
                                    3 rank,
                                    aux.id_episode,
                                    pk_prof_utils.get_detail_signature(i_lang,
                                                                       i_prof,
                                                                       aux.id_episode,
                                                                       aux.dt_vital_sign_read,
                                                                       aux.id_prof_read) signature
                      FROM vital_sign vs,
                           vital_sign_relation vr_par,
                           (SELECT SUM(vsd.value) val,
                                   vr.id_vital_sign_parent,
                                   vs_ea.dt_vital_sign_read,
                                   vs_ea.id_episode,
                                   vs_ea.id_prof_read
                              FROM vital_sign_desc vsd, vital_sign_relation vr, vital_signs_ea vs_ea
                             WHERE EXISTS (SELECT /*+ cardinality (t 1)*/
                                     1
                                      FROM TABLE(i_epis) t
                                     WHERE vs_ea.id_episode = t.column_value)
                               AND vs_ea.flg_state = pk_alert_constant.g_active
                               AND vr.id_vital_sign_detail = vs_ea.id_vital_sign
                               AND vr.relation_domain = pk_alert_constant.g_vs_rel_sum -- 'S' : sum glasgow
                               AND vsd.id_vital_sign_desc = vs_ea.id_vital_sign_desc
                               AND pk_delivery.check_vs_read_from_fetus(vs_ea.id_vital_sign_read) = 0
                             GROUP BY vr.id_vital_sign_parent,
                                      vs_ea.dt_vital_sign_read,
                                      vs_ea.id_episode,
                                      vs_ea.id_prof_read) aux
                     WHERE vr_par.id_vital_sign_parent = vs.id_vital_sign
                       AND vr_par.relation_domain = pk_alert_constant.g_vs_rel_sum -- 'S' : sum glasgow
                       AND aux.id_vital_sign_parent = vs.id_vital_sign)
             ORDER BY dt_vs_read, rank;
    
        g_error := 'OPEN O_BIOMETRIC';
        OPEN o_biometric FOR
            SELECT pk_translation.get_translation(i_lang, vs.code_vital_sign) || ': ' ||
                   decode(instr(vs_ea.value, '.'),
                          0,
                          vs_ea.value,
                          decode(length(substr(vs_ea.value, instr(vs_ea.value, '.') + 1)),
                                 2,
                                 vs_ea.value,
                                 rpad(vs_ea.value, length(vs_ea.value) + 1, '0'))) ||
                   pk_translation.get_translation(i_lang, um.code_unit_measure) desc_info,
                   vs_ea.id_episode,
                   pk_prof_utils.get_detail_signature(i_lang,
                                                      i_prof,
                                                      vs_ea.id_episode,
                                                      vs_ea.dt_vital_sign_read,
                                                      vs_ea.id_prof_read) signature
              FROM vital_signs_ea vs_ea, vital_sign vs, unit_measure um
             WHERE vs.id_vital_sign = vs_ea.id_vital_sign
               AND um.id_unit_measure = vs_ea.id_unit_measure
               AND EXISTS (SELECT /*+ cardinality (t 1)*/
                     1
                      FROM TABLE(i_epis) t
                     WHERE vs_ea.id_episode = t.column_value)
               AND vs_ea.flg_state = pk_alert_constant.g_active
               AND vs.flg_available = pk_alert_constant.g_yes
               AND vs.flg_vs = pk_alert_constant.g_vs_flg_bio
               AND pk_delivery.check_vs_read_from_fetus(vs_ea.id_vital_sign_read) = 0
             ORDER BY vs_ea.dt_vital_sign_read;
    
        l_msg_header_blood := pk_message.get_message(i_lang, 'HEADER_BLOOD');
        --GRUPO SANGUÍNEO
        g_error := 'OPEN O_BLOOD_GROUP';
        OPEN o_blood_group FOR
            SELECT pbg.flg_blood_group || ' ' ||
                   pk_sysdomain.get_domain('PAT_BLOOD_GROUP.FLG_BLOOD_RHESUS', pbg.flg_blood_rhesus, i_lang) || ' ' ||
                   decode(pbg.desc_other_system, '', '', l_msg_header_blood) desc_info,
                   pbg.id_episode,
                   pk_prof_utils.get_detail_signature(i_lang,
                                                      i_prof,
                                                      pbg.id_episode,
                                                      pbg.dt_pat_blood_group_tstz,
                                                      pbg.id_professional) signature
              FROM pat_blood_group pbg
             WHERE pbg.id_episode IN (SELECT *
                                        FROM TABLE(i_epis))
               AND pbg.flg_status = pk_alert_constant.g_active
             ORDER BY pbg.dt_pat_blood_group_tstz;
    
        --The cursor o_info7 is not being used in previous versions and to solve the 
        --Issue ALERT-147545 it will be used to return the Objective free text information. 
        OPEN o_info7 FOR
            SELECT e.desc_epis_recomend_clob desc_info,
                   pk_date_utils.date_send_tsz(i_lang, e.dt_epis_recomend_tstz, i_prof.institution, i_prof.software) dt_epis_recomend,
                   e.flg_temp,
                   decode(e.flg_temp, g_flg_def, NULL, e.id_epis_recomend) id,
                   e.id_episode,
                   pk_prof_utils.get_detail_signature(i_lang,
                                                      i_prof,
                                                      e.id_episode,
                                                      e.dt_epis_recomend_tstz,
                                                      e.id_professional) signature
              FROM epis_recomend e
             WHERE e.id_episode IN (SELECT *
                                      FROM TABLE(i_epis))
               AND e.flg_temp IN (g_flg_temp, g_flg_def)
               AND e.flg_type = g_flg_obj
             ORDER BY dt_epis_recomend;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_cursor_if_closed(o_vital_sign);
            pk_types.open_cursor_if_closed(o_biometric);
            pk_types.open_cursor_if_closed(o_blood_group);
            pk_types.open_cursor_if_closed(o_info7);
            o_error := l_error;
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_vital_sign);
                pk_types.open_my_cursor(o_biometric);
                pk_types.open_my_cursor(o_blood_group);
                pk_types.open_my_cursor(o_info7);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_owner_name,
                                   g_pck_name,
                                   'GET_SUMMARY_O_INTERNAL');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN l_ret;
            END;
        
    END get_summary_o_internal;

    FUNCTION get_summary_o
    (
        i_lang           IN NUMBER,
        i_pat            IN NUMBER,
        i_epis           IN table_number,
        i_prof           IN profissional,
        o_vital_sign     OUT pk_types.cursor_type,
        o_biometric      OUT pk_types.cursor_type,
        o_phys_exam      OUT pk_types.cursor_type,
        o_monitorization OUT pk_types.cursor_type,
        o_problems       OUT pk_types.cursor_type,
        o_blood_group    OUT pk_types.cursor_type,
        o_info7          OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                         I_PAT - ID do paciente
                                 I_EPIS - ID do episódio
                                 I_PROF - profissional que acede
                        Saída: O_INFO - informação
                               O_ERROR - erro
        
          CRIAÇÃO: SS 2006/02/27
          ALTERADO: ET 2006/06/21
          NOTAS: RdSN 2007/02/18 Recebe um array de episódios em vez de um NUMBER (necessário p/ Saúde Materna)
          ALTERADO: Orlando Antunes 2006/10/03
          NOTAS: Esta função deve ser completamente remodelada!
        *********************************************************************************/
        l_func_name CONSTANT VARCHAR2(13 CHAR) := 'GET_SUMMARY_O';
    
        l_error t_error_out;
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'CALL get_summary_o_internal';
        pk_alertlog.log_info(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        IF NOT get_summary_o_internal(i_lang        => i_lang,
                                      i_pat         => i_pat,
                                      i_epis        => i_epis,
                                      i_prof        => i_prof,
                                      o_vital_sign  => o_vital_sign,
                                      o_biometric   => o_biometric,
                                      o_blood_group => o_blood_group,
                                      o_info7       => o_info7,
                                      o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        --EXAME FÍSICO
        g_error := 'CALL PK_CLINICAL_INFO.GET_SUMM_LAST_PHYSICAL_EXAM';
        IF NOT pk_clinical_info.get_summ_last_physical_exam(i_lang          => i_lang,
                                                            i_prof          => i_prof,
                                                            i_episode       => i_epis(1),
                                                            i_prof_cat_type => pk_alert_constant.g_cat_type_doc,
                                                            o_physical_exam => o_phys_exam,
                                                            o_error         => l_error)
        THEN
            RAISE g_exception;
        END IF;
    
        --
        pk_types.open_cursor_if_closed(o_monitorization);
        pk_types.open_cursor_if_closed(o_problems);
    
        --
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_cursor_if_closed(o_vital_sign);
            pk_types.open_cursor_if_closed(o_biometric);
            pk_types.open_cursor_if_closed(o_phys_exam);
            pk_types.open_cursor_if_closed(o_monitorization);
            pk_types.open_cursor_if_closed(o_problems);
            pk_types.open_cursor_if_closed(o_blood_group);
            pk_types.open_cursor_if_closed(o_info7);
            o_error := l_error;
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_vital_sign);
                pk_types.open_my_cursor(o_biometric);
                pk_types.open_my_cursor(o_phys_exam);
                pk_types.open_my_cursor(o_monitorization);
                pk_types.open_my_cursor(o_problems);
                pk_types.open_my_cursor(o_blood_group);
                pk_types.open_my_cursor(o_info7);
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_owner_name, g_pck_name, 'GET_SUMMARY_O');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN l_ret;
            END;
        
    END get_summary_o;

    FUNCTION get_summary_a
    (
        i_lang        IN NUMBER,
        i_pat         IN NUMBER,
        i_epis        IN table_number,
        i_prof        IN profissional,
        i_prev_visits IN sys_domain.val%TYPE DEFAULT pk_alert_constant.g_no,
        o_problems    OUT pk_types.cursor_type,
        o_ass_scales  OUT pk_types.cursor_type,
        o_body_diags  OUT pk_types.cursor_type,
        o_diag        OUT pk_types.cursor_type,
        o_impressions OUT pk_types.cursor_type,
        o_evaluation  OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                         I_PAT - ID do paciente
                                 I_EPIS - ID do episódio
                                 I_PROF - profissional que acede
                        Saída: O_INFO - informação
                               O_ERROR - erro
        
          CRIAÇÃO: SS 2006/02/27
          NOTAS: RdSN 2007/02/18 Recebe um array de episódios em vez de um NUMBER (necessário p/ Saúde Materna)
        *********************************************************************************/
        aux_epis       VARCHAR2(4000) := '0';
        l_aux_1        VARCHAR2(4000);
        l_aux_2        VARCHAR2(4000);
        l_notes        sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'PAST_HISTORY_M062');
        l_id_epis_type episode.id_epis_type%TYPE;
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
        FOR i IN 1 .. i_epis.count
        LOOP
            -- Loop sobre o array de IDs de episódios
            aux_epis := aux_epis || ', ' || i_epis(i);
        END LOOP;
    
        --get id epis type
        IF NOT pk_episode.get_epis_type(i_lang      => i_lang,
                                        i_id_epis   => i_epis(1),
                                        o_epis_type => l_id_epis_type,
                                        o_error     => o_error)
        THEN
            RAISE g_exception;
        END IF;
        ------------------------------------------- A -------------------------------------------------
    
        -- Assessment Scales
        -- flash is calling the function each time for episode, there is no need to use a table_number
        g_error := 'CALL pk_scales_api.get_epis_ass_scales_scores';
        IF NOT pk_scales_api.get_epis_ass_scales_scores(i_lang            => i_lang,
                                                        i_prof            => i_prof,
                                                        i_tbl_episode     => i_epis,
                                                        i_show_all_scores => i_prev_visits,
                                                        o_ass_scales      => o_ass_scales,
                                                        o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        -- Body diagrams - all the (distinct) figures registered for the episodes
        g_error := 'CALL pk_diagram_new.get_epis_diag_lay_desc';
        IF NOT pk_diagram_new.get_epis_diag_lay_desc(i_lang        => i_lang,
                                                     i_prof        => i_prof,
                                                     i_tbl_episode => i_epis,
                                                     o_diag_layout => o_body_diags,
                                                     o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
        --      IF l_id_epis_type = pk_alert_constant.g_hhc_epis_type
        --       THEN
    
        --           pk_types.open_my_cursor(o_impressions);
        --       ELSE
        --Diagnósticos - Diagnosis description (code) (Principal diagnosis (only if Yes), status, date of initial diagnosis), Specific notes
        g_error := 'CALL pk_diagnosis.get_epis_diag_with_notes';
        IF NOT pk_diagnosis.get_epis_diag_with_notes(i_lang        => i_lang,
                                                     i_prof        => i_prof,
                                                     i_tbl_episode => i_epis,
                                                     o_diag        => o_diag,
                                                     o_impressions => o_impressions,
                                                     o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF l_id_epis_type = pk_alert_constant.g_hhc_epis_type
        THEN
            pk_types.open_my_cursor(o_diag);
        END IF;
        --        END IF;
        -- PROBLEMAS
        g_error := 'GET CURSOR o_problems';
        OPEN o_problems FOR
            SELECT phd.desc_probl || ' (' || pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS', phd.flg_status, i_lang) || ')' ||
                   nvl2(phd.prob_notes, ' ' || l_notes || ' ' || phd.prob_notes, '') desc_info,
                   phd.viewer_id_epis id_episode,
                   pk_prof_utils.get_detail_signature(i_lang,
                                                      i_prof,
                                                      phd.viewer_id_epis,
                                                      phd.dt_updated,
                                                      phd.id_professional) signature
              FROM TABLE(pk_problems.get_pat_problem_tf_cda(i_lang        => i_lang,
                                                            i_prof        => i_prof,
                                                            i_pat         => i_pat,
                                                            i_status      => table_varchar('A', 'P', 'R'),
                                                            i_type        => NULL,
                                                            i_problem     => NULL,
                                                            i_scopeid     => i_epis(1),
                                                            i_flg_scope   => pk_alert_constant.g_scope_type_episode,
                                                            i_dt_ini      => NULL,
                                                            i_dt_end      => NULL,
                                                            i_show_ph     => pk_alert_constant.g_no,
                                                            i_show_review => pk_alert_constant.g_yes)) phd;
        -- AVALIAÇÃO
        g_error := 'GET CURSOR o_evaluation';
        OPEN o_evaluation FOR
            SELECT tmp.desc_info,
                   tmp.dt_epis_recomend,
                   tmp.flg_temp,
                   tmp.id,
                   tmp.id_episode,
                   pk_prof_utils.get_detail_signature(i_lang,
                                                      i_prof,
                                                      tmp.id_episode,
                                                      tmp.dt_epis_recomend_tstz,
                                                      tmp.id_professional) signature
              FROM (SELECT e.desc_epis_recomend_clob desc_info,
                           pk_date_utils.date_send_tsz(i_lang,
                                                       e.dt_epis_recomend_tstz,
                                                       i_prof.institution,
                                                       i_prof.software) dt_epis_recomend,
                           e.flg_temp,
                           decode(e.flg_temp, g_flg_def, NULL, e.id_epis_recomend) id,
                           e.id_episode,
                           e.id_professional,
                           e.dt_epis_recomend_tstz,
                           row_number() over(PARTITION BY e.id_episode ORDER BY e.dt_epis_recomend_tstz DESC) rn
                      FROM epis_recomend e
                     WHERE e.id_episode IN (SELECT /*+opt_estimate(table t rows=1)*/
                                             t.column_value id_episode
                                              FROM TABLE(i_epis) t)
                       AND e.flg_temp = g_flg_temp
                       AND e.flg_type = g_flg_aval
                       AND (e.flg_status = pk_alert_constant.g_active OR e.flg_status IS NULL)) tmp
             WHERE rn = 1
            UNION ALL
            SELECT e.desc_epis_recomend_clob desc_info,
                   pk_date_utils.date_send_tsz(i_lang, e.dt_epis_recomend_tstz, i_prof.institution, i_prof.software) dt_epis_recomend,
                   e.flg_temp,
                   decode(e.flg_temp, g_flg_def, NULL, e.id_epis_recomend) id,
                   e.id_episode,
                   pk_prof_utils.get_detail_signature(i_lang,
                                                      i_prof,
                                                      e.id_episode,
                                                      e.dt_epis_recomend_tstz,
                                                      e.id_professional) signature
              FROM epis_recomend e
             WHERE e.id_episode IN (SELECT /*+opt_estimate(table t rows=1)*/
                                     t.column_value id_episode
                                      FROM TABLE(i_epis) t)
               AND e.flg_temp = g_flg_def
               AND e.flg_type = g_flg_aval
               AND (e.flg_status = pk_alert_constant.g_active OR e.flg_status IS NULL)
             ORDER BY flg_temp, dt_epis_recomend;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_diag);
                pk_types.open_my_cursor(o_impressions);
                pk_types.open_my_cursor(o_ass_scales);
                pk_types.open_my_cursor(o_body_diags);
                pk_types.open_my_cursor(o_problems);
                pk_types.open_my_cursor(o_evaluation);
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_owner_name, g_pck_name, 'GET_SUMMARY_A');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN l_ret;
            END;
    END;

    FUNCTION get_summary_p
    (
        i_lang                 IN NUMBER,
        i_pat                  IN NUMBER,
        i_epis                 IN table_number,
        i_prof                 IN profissional,
        o_analysis             OUT pk_types.cursor_type,
        o_exam                 OUT pk_types.cursor_type,
        o_presc_ext            OUT pk_types.cursor_type,
        o_dietary_ext          OUT pk_types.cursor_type,
        o_manip_ext            OUT pk_types.cursor_type,
        o_presc                OUT pk_types.cursor_type,
        o_interv               OUT pk_types.cursor_type,
        o_monitorization       OUT pk_types.cursor_type,
        o_nurse_act            OUT pk_types.cursor_type,
        o_nurse_teach          OUT pk_types.cursor_type,
        o_plan                 OUT pk_types.cursor_type,
        o_therapeutic_decision OUT pk_types.cursor_type,
        o_referrals            OUT pk_types.cursor_type,
        o_gp_notes             OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                         I_PAT - ID do paciente
                                 I_EPIS - ID do episódio
                                 I_PROF - profissional que acede
                        Saída: O_INFO - informação
                               O_ERROR - erro
        
          CRIAÇÃO: SS 2006/02/27
          NOTAS: RdSN 2007/02/18 Recebe um array de episódios em vez de um NUMBER (necessário p/ Saúde Materna)
          CHANGE: Elisabete Bugalho 
                  ALERT-19202 : Separar os procedimento MFR dos restantes procedimentos         
        *********************************************************************************/
        aux_epis       VARCHAR2(4000) := '0';
        l_aux_1        VARCHAR2(4000);
        l_aux_2        VARCHAR2(4000);
        l_aux_5        VARCHAR2(4000);
        l_aux_8        VARCHAR2(4000);
        l_aux_11       VARCHAR2(4000);
        l_aux_12       VARCHAR2(4000);
        l_visit        visit.id_visit%TYPE;
        l_epis_type    epis_type.id_epis_type%TYPE;
        l_current_epis episode.id_episode%TYPE := i_epis(1);
    
        -- Referrals
        -- package table type
        l_coll_ref_info pk_ref_ext_sys.t_coll_ref_info;
        -- sys_messages
        l_sm_dest_facility sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                   i_code_mess => 'P1_DOCTOR_CS_T039');
        l_sm_reason        sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                   i_code_mess => 'P1_DOCTOR_CS_T010');
    
        -- aux typed vars
        l_rec_desc_info_ranked   t_rec_desc_info_ranked;
        l_table_desc_info_ranked t_table_desc_info_ranked := t_table_desc_info_ranked();
        l_patient                patient.id_patient%TYPE;
        l_desc_info              CLOB;
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        FOR i IN 1 .. i_epis.count
        LOOP
            -- Loop sobre o array de IDs de episódios
            aux_epis := aux_epis || ', ' || i_epis(i);
        END LOOP;
    
        g_error := 'GET current EPIS_TYPE';
    
        SELECT e.id_epis_type, e.id_visit, e.id_patient
          INTO l_epis_type, l_visit, l_patient
          FROM episode e
         WHERE e.id_episode = l_current_epis;
    
        ------------------------------------------- P -------------------------------------------------
    
        --ANÁLISES
        g_error := 'GET CURSOR o_analysis';
        -- < DESNORM LMAIA 16-10-2008 >
        l_aux_1 := 'SELECT pk_lab_tests_api_db.get_alias_translation(' || i_lang || ', profissional(' || i_prof.id || ', ' ||
                   i_prof.institution || ', ' || i_prof.software ||
                   '), ''A'', ''ANALYSIS.CODE_ANALYSIS.'' || lte.id_analysis, NULL) || decode(' || l_epis_type || ' , ' ||
                   'nvl(t_ti_log.get_epis_type(' || i_lang || ',' || 'profissional(' || i_prof.id || ', ' ||
                   i_prof.institution || ', ' || i_prof.software || '),' || 'epis.id_epis_type,' ||
                   'LTE.flg_status_det,' || 'LTE.id_analysis_req_det,''' || pk_alert_constant.g_analysis_type_req_det ||
                   '''),' || ' epis.id_epis_type), '''' ' || ', '' - (''||' || 'pk_message.get_message(' || i_lang || ',' ||
                   'profissional(' || i_prof.id || ',' || i_prof.institution || ',' || 't_ti_log.get_epis_type_soft(' ||
                   i_lang || ',' || 'profissional(' || i_prof.id || ', ' || i_prof.institution || ', ' ||
                   i_prof.software || '),' || 'epis.id_epis_type,' || 'LTE.flg_status_det,' ||
                   'LTE.id_analysis_req_det,''' || pk_alert_constant.g_analysis_type_req_det || ''')),' ||
                   '''IMAGE_T009'') || '')'') ' || ' DESC_INFO' || ', LTE.ID_EPISODE, ' ||
                   ' pk_prof_utils.get_detail_signature(' || i_lang || ', profissional(' || i_prof.id || ', ' ||
                   i_prof.institution || ',' || i_prof.software || '),' || 'lte.id_episode ,' ||
                   'ard.dt_last_update_tstz, ' || 'ard.id_prof_last_update)' || 'signature ' ||
                   '  FROM LAB_TESTS_EA LTE, EPISODE EPIS, ANALYSIS_REQ_DET ARD, ' ||
                   ' --Laboratory tests of infectious diseases
                     (SELECT DISTINCT gar.id_record id_analysis
                        FROM group_access ga
                       INNER JOIN group_access_prof gaf
                          ON gaf.id_group_access = ga.id_group_access
                       INNER JOIN group_access_record gar
                          ON gar.id_group_access = ga.id_group_access
                       WHERE ga.id_institution = ' || i_prof.institution || ' AND ga.id_software = ' ||
                   i_prof.software || ' AND ga.flg_type = ''' || pk_lab_tests_constant.g_infectious_diseases_orders || '''' ||
                   ' AND gar.flg_type = ''A'' ' || ' AND ga.flg_available = ''' || pk_alert_constant.g_available || '''' ||
                   ' AND gaf.flg_available = ''' || pk_alert_constant.g_available || '''' ||
                   ' AND gar.flg_available = ''' || pk_alert_constant.g_available || ''') a_infect ' ||
                   '  WHERE EPIS.ID_VISIT = ' || l_visit ||
                   '  AND (LTE.ID_EPISODE = EPIS.ID_EPISODE OR ARD.ID_EPISODE_ORIGIN = EPIS.ID_EPISODE) ' ||
                   ' AND LTE.id_analysis = a_infect.id_analysis(+)' ||
                   ' AND (a_infect.id_analysis IS NULL OR EXISTS
                            (SELECT 1
                                FROM group_access ga
                               INNER JOIN group_access_prof gaf
                                  ON gaf.id_group_access = ga.id_group_access
                               INNER JOIN group_access_record gar
                                  ON gar.id_group_access = ga.id_group_access
                               WHERE gaf.id_professional = ' || i_prof.id ||
                   '  AND ga.id_institution = ' || i_prof.institution || '  AND ga.id_software = ' || i_prof.software ||
                   '  AND ga.flg_type = ''' || pk_lab_tests_constant.g_infectious_diseases_orders || '''' ||
                   '  AND gar.flg_type = ''A'' ' || '  AND ga.flg_available = ''' || pk_alert_constant.g_available || '''' ||
                   '  AND gaf.flg_available = ''' || pk_alert_constant.g_available || '''' ||
                   '  AND gar.flg_available = ''' || pk_alert_constant.g_available || '''))' ||
                   '  AND LTE.ID_ANALYSIS_REQ_DET = ARD.ID_ANALYSIS_REQ_DET ' || '  AND LTE.FLG_STATUS_DET != ''' ||
                   pk_alert_constant.g_cancelled || '''' || ' ORDER BY LTE.DT_REQ';
        -- < END DESNORM >
        OPEN o_analysis FOR l_aux_1;
    
        --EXAMES
        /* <DENORM Sérgio Monteiro 2008-10-13> */
        g_error := 'GET CURSOR o_exam';
        l_aux_2 := 'SELECT pk_exams_api_db.get_alias_translation(' || i_lang || ', profissional(' || i_prof.id || ', ' ||
                   i_prof.institution || ', ' || i_prof.software ||
                   '), ''EXAM.CODE_EXAM.'' || eea.id_exam, NULL) || decode(' || l_epis_type || ',' ||
                   'nvl(t_ti_log.get_epis_type(' || i_lang || ', ' || 'profissional(' || i_prof.id || ', ' ||
                   i_prof.institution || ', ' || i_prof.software || '),' ||
                   'epi.id_epis_type, eea.flg_status_req, eea.id_exam_req,''' || pk_exam_constant.g_exam_type_req ||
                   '''), epi.id_epis_type),' || ''''', '' - ('' || pk_message.get_message(' || i_lang || ',' ||
                   'profissional(' || i_prof.id || ',' || i_prof.institution || ',' || 't_ti_log.get_epis_type_soft(' ||
                   i_lang || ',' || 'profissional(' || i_prof.id || ', ' || i_prof.institution || ', ' ||
                   i_prof.software || '),' || 'epi.id_epis_type, eea.flg_status_req, eea.id_exam_req,''' ||
                   pk_exam_constant.g_exam_type_req || ''')), ''IMAGE_T009'') || '')'') ' ||
                   ' DESC_INFO, EEA.ID_EPISODE , ' || ' pk_prof_utils.get_detail_signature(' || i_lang ||
                   ', profissional(' || i_prof.id || ', ' || i_prof.institution || ',' || i_prof.software || '),' ||
                   'EEA.id_episode,' || 'eea.dt_dg_last_update,' || 'eea.id_prof_req ' || ')' || 'signature ' ||
                   'FROM EPISODE EPI, EXAMS_EA EEA' || ' WHERE EPI.ID_VISIT = ' || l_visit ||
                   ' AND (EEA.ID_EPISODE = EPI.ID_EPISODE OR EEA.ID_EPISODE_ORIGIN = EPI.ID_EPISODE) ' ||
                   ' AND EEA.FLG_STATUS_DET != ''' || pk_alert_constant.g_cancelled || ''' ORDER BY EEA.DT_REQ';
        /* <DENORM Sérgio Monteiro 2008-10-13> */
        OPEN o_exam FOR l_aux_2;
    
        --MEDICAÇÃO PARA O EXTERIOR
        g_error := 'CALL pk_api_pfh_clindoc_in.get_ext_med_summ_p';
        IF NOT pk_api_pfh_clindoc_in.get_ext_med_summ_p(i_lang      => i_lang,
                                                        i_prof      => i_prof,
                                                        i_patient   => i_pat,
                                                        i_epis      => i_epis,
                                                        o_presc_ext => o_presc_ext,
                                                        o_error     => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        --MEDICAÇÃO NESTE LOCAL
        g_error := 'CALL pk_api_pfh_clindoc_in.get_local_med_summ_p';
        IF NOT pk_api_pfh_clindoc_in.get_local_med_summ_p(i_lang    => i_lang,
                                                          i_prof    => i_prof,
                                                          i_patient => i_pat,
                                                          i_epis    => i_epis,
                                                          o_presc   => o_presc,
                                                          o_error   => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        --PROCEDIMENTOS
        g_error := 'GET CURSOR o_interv';
        l_aux_5 := 'SELECT pk_procedures_api_db.get_alias_translation(' || i_lang || ', ' || --
                   '                                                  profissional(' || i_prof.id || ', ' ||
                   i_prof.institution || ', ' || i_prof.software || '), ' || --
                   '                                                  i.code_intervention, ' || --
                   '                                                  NULL) desc_info, ' || --
                   '       ip.id_episode ' || ', ' || ' pk_prof_utils.get_detail_signature(' || i_lang ||
                   ', profissional(' || i_prof.id || ', ' || i_prof.institution || ',' || i_prof.software || '),' ||
                   'ip.id_episode ' || ',' || 'ipd.dt_last_update_tstz' || ',' || 'ipd.id_prof_last_update ' || ')' ||
                   'signature' || '  FROM interv_prescription ip, interv_presc_det ipd, intervention i ' || --
                   ' WHERE (ip.id_episode = ' || l_current_epis || ' OR (ip.flg_time IN (''A'', ''H'') AND ' ||
                   ' ip.id_patient = ' || l_patient || ' AND (ipd.flg_status in (''R'', ''D'', ''S'', ''E'') OR ' ||
                   ' (EXISTS (SELECT 1 FROM interv_presc_plan a where a.id_interv_presc_det = ipd.id_interv_presc_det ' ||
                   ' and a.id_episode_write = ' || l_current_epis || ')))) ' || ' OR ip.id_episode_origin = ' ||
                   l_current_epis || ') ' || --
                   '   AND ipd.flg_status NOT IN (''' || pk_procedures_constant.g_interv_cancel || ''', ' || --
                   '                              ''' || pk_procedures_constant.g_interv_not_ordered || ''', ' || --
                   '                              ''' || pk_procedures_constant.g_interv_interrupted || ''', ' || --
                   '                              ''' || pk_procedures_constant.g_interv_expired || ''', ' || --
                   '                              ''' || pk_procedures_constant.g_interv_draft || ''') ' || --
                   '   AND ipd.id_interv_prescription = ip.id_interv_prescription ' || --
                   '   AND i.id_intervention = ipd.id_intervention ' || --
                   '   AND i.id_intervention IN (SELECT id_intervention ' || --
                   '                               FROM interv_dep_clin_serv idcs ' || --
                   '                              WHERE idcs.id_institution = ' || i_prof.institution || ') ' || --
                   ' ORDER BY ip.dt_interv_prescription_tstz ';
        OPEN o_interv FOR l_aux_5;
    
        -- MONITORIZATIONS
        g_error := 'GET CURSOR o_monitorization';
        OPEN o_monitorization FOR --
         'SELECT (SELECT pk_translation.get_translation(' || i_lang || ', vs.code_vital_sign) ' || --
         '          FROM vital_sign vs ' || --
         '         WHERE mvs.id_vital_sign = vs.id_vital_sign) desc_info, ' || --
         '       m.id_episode ' || --
         ', ' || ' pk_prof_utils.get_detail_signature(' || i_lang || ', profissional(' || i_prof.id || ', ' || i_prof.institution || ',' || i_prof.software || '),' || 'm.id_episode ' || ',' || 'm.dt_monitorization_tstz' || ',' || 'm.id_professional ' || ')' || 'signature' || --
         '  FROM monitorization m ' || --
         ' INNER JOIN monitorization_vs mvs ON m.id_monitorization = mvs.id_monitorization ' || --
         ' WHERE m.id_episode IN (' || aux_epis || ') ' || --
         '   AND m.flg_status NOT IN (''' || pk_alert_constant.g_monitor_vs_canc || ''', ''' || pk_alert_constant.g_monitor_vs_draft || ''') ' || --
         '   AND mvs.flg_status NOT IN (''' || pk_alert_constant.g_monitor_vs_canc || ''', ''' || pk_alert_constant.g_monitor_vs_draft || ''') ' || --
         ' ORDER BY m.dt_monitorization_tstz';
    
        --PENSOS
        pk_alertlog.log_warn(text => aux_epis);
        g_error := 'GET CURSOR o_nurse_act';
        pk_types.open_my_cursor(o_nurse_act);
    
        IF l_epis_type = pk_alert_constant.g_epis_type_home_health_care
        THEN
            pk_types.open_my_cursor(o_nurse_teach);
        ELSE
            --REQ ENSINOS
            g_error := 'GET CURSOR o_nurse_teach';
            l_aux_8 := ' SELECT decode(ntr.id_nurse_tea_topic,1,nvl(ntr.desc_topic_aux,pk_translation.get_translation(:1,
         (SELECT ntt.code_nurse_tea_topic
      FROM nurse_tea_topic ntt
          WHERE ntt.id_nurse_tea_topic = ntr.id_nurse_tea_topic))), pk_translation.get_translation(:2,
         (SELECT ntt.code_nurse_tea_topic
      FROM nurse_tea_topic ntt
          WHERE ntt.id_nurse_tea_topic = ntr.id_nurse_tea_topic))) DESC_INFO, ntr.ID_EPISODE, ' ||
                       ' pk_prof_utils.get_detail_signature(' || i_lang || ', profissional(' || i_prof.id || ', ' ||
                       i_prof.institution || ',' || i_prof.software || '),' || 'ntr.id_episode,' ||
                       'ntr.dt_nurse_tea_req_tstz,' || 'ntr.id_prof_req ' || ')' || 'signature ' ||
                       ' FROM NURSE_TEA_REQ ntr ' || ' WHERE ntr.ID_EPISODE IN (' || aux_epis || ') ' || -- ))
                       ' AND NTR.FLG_STATUS NOT IN (:3, :4, :5, :6) ' || 'ORDER BY NTR.DT_NURSE_TEA_REQ_TSTZ ';
        
            OPEN o_nurse_teach FOR l_aux_8
                USING i_lang, i_lang, pk_patient_education_api_db.g_nurse_tea_req_canc, pk_patient_education_api_db.g_nurse_tea_req_draft, pk_patient_education_api_db.g_nurse_tea_req_expired, pk_patient_education_api_db.g_nurse_tea_req_not_ord_reas;
        END IF;
        -- AVALIAÇÃO
        g_error := 'GET CURSOR o_plan: ' || pk_summary_page.g_doc_area_plan;
        IF NOT pk_summary_page.get_summ_last_documentation(i_lang          => i_lang,
                                                           i_prof          => i_prof,
                                                           i_episode       => i_epis,
                                                           i_doc_area      => pk_summary_page.g_doc_area_plan,
                                                           o_documentation => o_plan,
                                                           o_error         => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        -- THERAPEUTIC DECISION
        g_error  := 'GET CURSOR o_therapeutic_decision';
        l_aux_12 := 'SELECT TH.THERAPEUTIC_DECISION FROM THERAPEUTIC_DECISION TH ' || ' WHERE TH.ID_EPISODE IN (' ||
                    aux_epis || ') ' || ' AND TH.FLG_STATUS =''A'' ' ||
                    ' AND (SELECT COUNT (1) FROM THERAPEUTIC_DECISION_DET THD ' ||
                    ' WHERE THD.ID_THERAPEUTIC_DECISION = TH.ID_THERAPEUTIC_DECISION ' || ' AND THD.FLG_PRESENCE=''P''' ||
                    ' AND THD.FLG_OPINION=''Y'') = (SELECT COUNT(1)  FROM THERAPEUTIC_DECISION_DET THD1 ' ||
                    ' WHERE THD1.ID_THERAPEUTIC_DECISION = TH.ID_THERAPEUTIC_DECISION ' ||
                    ' AND THD1.FLG_PRESENCE=''P'' )';
        OPEN o_therapeutic_decision FOR l_aux_12;
    
        pk_types.open_my_cursor(o_dietary_ext);
        pk_types.open_my_cursor(o_manip_ext);
    
        /****** REFERRALS ******/
        g_error := 'GET Referrals info';
    
        -- Go through all the episodes
        FOR i IN 1 .. i_epis.count
        LOOP
            -- Call referrals API
            g_error := 'CALL pk_ref_ext_sys.get_referrals_by_epis';
            IF NOT pk_ref_ext_sys.get_referrals_by_epis(i_lang          => i_lang,
                                                        i_prof          => i_prof,
                                                        i_id_episode    => i_epis(i),
                                                        o_coll_ref_info => l_coll_ref_info,
                                                        o_error         => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            -- Populate table type
            g_error := 'FORALL INSERT into tbl_temp';
            FOR j IN 1 .. l_coll_ref_info.count
            LOOP
                l_desc_info := l_coll_ref_info(j)
                               .desc_ref_type || g_flg_sep_open_par || l_coll_ref_info(j).desc_items ||
                                g_flg_sep_close_par || g_flg_sep_semi_colon || l_sm_dest_facility || g_flg_sep_colon || l_coll_ref_info(j).desc_inst_dest ||
                                g_flg_sep_semi_colon || l_sm_reason || g_flg_sep_colon || l_coll_ref_info(j).reason;
            
                l_rec_desc_info_ranked := t_rec_desc_info_ranked(id        => i_epis(i),
                                                                 desc_info => l_desc_info,
                                                                 num_rank  => NULL,
                                                                 tstz_rank => l_coll_ref_info(j).dt_requested,
                                                                 signature => l_coll_ref_info(j).signature);
            
                l_table_desc_info_ranked.extend;
                l_table_desc_info_ranked(l_table_desc_info_ranked.count) := l_rec_desc_info_ranked;
            END LOOP;
        END LOOP;
    
        -- Open o_referrals cursor: Type of request (Specialty); Destination facility; Referral reason
        g_error := 'Open o_referrals for select from tbl_temp';
        OPEN o_referrals FOR
        
            SELECT desc_info AS desc_info, id AS id_episode, signature
              FROM TABLE(l_table_desc_info_ranked) t
             ORDER BY t.tstz_rank DESC;
    
        IF l_epis_type = pk_alert_constant.g_epis_type_home_health_care
        THEN
            pk_types.open_my_cursor(o_gp_notes);
        ELSE
            /***** GP NOTES ******/
            IF NOT get_gp_notes(i_lang        => i_lang,
                                i_prof        => i_prof,
                                i_tbl_episode => i_epis,
                                o_gp_notes    => o_gp_notes,
                                o_error       => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_analysis);
                --Pk_Types.OPEN_MY_CURSOR(O_IMAGE);
                pk_types.open_my_cursor(o_exam);
                pk_types.open_my_cursor(o_presc_ext);
                pk_types.open_my_cursor(o_dietary_ext);
                pk_types.open_my_cursor(o_manip_ext);
                pk_types.open_my_cursor(o_presc);
                pk_types.open_my_cursor(o_interv);
                pk_types.open_my_cursor(o_nurse_act);
                pk_types.open_my_cursor(o_nurse_teach);
                pk_types.open_my_cursor(o_monitorization);
                pk_types.open_my_cursor(o_plan);
                pk_types.open_my_cursor(o_therapeutic_decision);
                pk_types.open_my_cursor(o_referrals);
                pk_types.open_my_cursor(o_gp_notes);
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_owner_name, g_pck_name, 'GET_SUMMARY_P');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN l_ret;
            END;
    END get_summary_p;

    FUNCTION create_estate_epis
    (
        i_lang        IN language.id_language%TYPE,
        i_id_epis     IN estate.id_episode%TYPE,
        i_desc_estate IN estate.desc_estate%TYPE,
        i_prof        IN profissional,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:    Registar o espólio do paciente neste episódio
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                             I_ID_EPIS - ID do Episódio do profissional
                                 I_DESC_ESTATE- Descrição do espólio
                                 I_PROF - ID do profissional q regista
        
                        Saida: O_ERROR - erro
        
          CRIAÇÃO: SF 2006/06/16
          NOTAS:
        *********************************************************************************/
        l_next estate.id_estate %TYPE;
    
        l_id_episode      episode.id_episode%TYPE;
        l_id_prev_episode episode.id_episode%TYPE;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'GET NEXT EPISODE';
        BEGIN
            SELECT e.id_episode, e.id_prev_episode
              INTO l_id_episode, l_id_prev_episode
              FROM episode e
             WHERE e.id_prev_episode = i_id_epis
               AND rownum < 2;
        EXCEPTION
            WHEN no_data_found THEN
                l_id_episode      := i_id_epis;
                l_id_prev_episode := NULL;
        END;
    
        g_error := ' GET SEQ_ESTATE.NEXTVAL';
        SELECT seq_estate.nextval
          INTO l_next
          FROM dual;
    
        g_error := ' INSERT INTO ESTATE';
        INSERT INTO estate
            (id_estate, id_episode, dt_estate_tstz, id_professional, desc_estate, id_prev_episode)
        VALUES
            (l_next, l_id_episode, g_sysdate_tstz, i_prof.id, i_desc_estate, l_id_prev_episode);
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_owner_name, g_pck_name, 'CREATE_ESTATE_EPIS');
                -- undo changes quando aplicável
                pk_utils.undo_changes;
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN l_ret;
            END;
    END;

    FUNCTION get_epis_type_new
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_epis   IN episode.id_episode%TYPE,
        o_epis_type OUT episode.id_epis_type%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_epis IS
            SELECT id_epis_type
              FROM episode
             WHERE id_episode = i_id_epis;
    BEGIN
        -- "i_id_epis IS NOT NULL" validation to avoid full scan in episode table (i_id_epis is null in Tools area)
        IF i_id_epis IS NOT NULL
        THEN
            g_error := 'GET CURSOR ';
            OPEN c_epis;
            FETCH c_epis
                INTO o_epis_type;
            CLOSE c_epis;
        ELSE
            o_epis_type := NULL;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_owner_name, g_pck_name, 'GET_EPIS_TYPE_NEW');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN l_ret;
            END;
    END get_epis_type_new;

    FUNCTION get_epis_type
    (
        i_lang      IN language.id_language%TYPE,
        i_id_epis   IN social_episode.id_social_episode%TYPE,
        o_epis_type OUT episode.id_epis_type%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        /********************************************************************************************
        * Return EPIS_TYPE
        *
        * @param i_lang              language id
        * @param i_id_epis           episode id
        * @param o_epis_type         episode type
        
        * @param o_error             Error message
        
        * @return                    true or false on success or error
        *
        * @author                    Rui Spratley
        * @version                   2.4.2
        * @since                     2008/02/07
        
        * @notes                     This function should not be used by the flash layer
        ********************************************************************************************/
    
        CURSOR c_epis IS
            SELECT id_epis_type
              FROM episode
             WHERE id_episode = i_id_epis;
    BEGIN
        g_error := 'GET CURSOR ';
        OPEN c_epis;
        FETCH c_epis
            INTO o_epis_type;
        CLOSE c_epis;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_owner_name, g_pck_name, 'GET_EPIS_TYPE');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN l_ret;
            END;
            RETURN FALSE;
    END;

    FUNCTION get_epis_type
    (
        i_lang    IN language.id_language%TYPE,
        i_id_epis IN social_episode.id_social_episode%TYPE
    ) RETURN NUMBER IS
    
        /********************************************************************************************
        * Return EPIS_TYPE
        *
        * @param i_lang              language id
        * @param i_id_epis           episode id
        
        * @return                    epis_type
        *
        * @author                    Rui Spratley
        * @version                   2.4.2
        * @since                     2008/02/07
        ********************************************************************************************/
    
        CURSOR c_epis IS
            SELECT id_epis_type
              FROM episode
             WHERE id_episode = i_id_epis;
    
        l_epis_type episode.id_epis_type%TYPE;
    BEGIN
        g_error := 'GET CURSOR ';
        OPEN c_epis;
        FETCH c_epis
            INTO l_epis_type;
        CLOSE c_epis;
    
        RETURN l_epis_type;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    FUNCTION get_estate_epis
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_epis     IN social_episode.id_social_episode%TYPE,
        o_estate_epis OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Listar o espólio do paciente num episódio
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                                 I_PROF - ID do profissional
                                 I_ID_EPIS - ID  do Episódio
        
                        Saida:   O_S_EPIS - Retorna o espólio do paciente do episódio
                                 O_ERROR - erro
        
          CRIAÇÃO: SF 2006/06/16
          ALTERAÇÃO: ET 2007/04/10 Filtrar os exames também com ID_PREV_EPISODE=I_ID_EPIS
          NOTAS:
        *********************************************************************************/
        l_episode estate.id_episode%TYPE;
    BEGIN
        BEGIN
            SELECT id_episode
              INTO l_episode
              FROM estate
             WHERE (id_episode = i_id_epis OR id_prev_episode = i_id_epis) --ET 2007/05/12
               AND rownum = 1;
        
            g_error := 'GET CURSOR O_ESTATE_EPIS(1)';
            OPEN o_estate_epis FOR
                SELECT desc_estate, name, date_estate, speciali
                  FROM (SELECT es.desc_estate,
                               pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) name,
                               pk_prof_utils.get_spec_signature(i_lang,
                                                                i_prof,
                                                                p.id_professional,
                                                                es.dt_estate_tstz,
                                                                i_id_epis) speciali,
                               pk_date_utils.date_char_tsz(i_lang,
                                                           es.dt_estate_tstz,
                                                           i_prof.institution,
                                                           i_prof.software) date_estate
                          FROM professional p
                          LEFT JOIN speciality s
                            ON (p.id_speciality = s.id_speciality)
                          LEFT JOIN estate es
                            ON (p.id_professional = es.id_professional)
                         WHERE (es.id_episode = i_id_epis OR es.id_prev_episode = i_id_epis) --ET 2007/04/10
                         ORDER BY es.id_estate DESC);
            --
        EXCEPTION
            WHEN no_data_found THEN
                g_error := 'GET CURSOR O_ESTATE_EPIS(2)';
                OPEN o_estate_epis FOR
                    SELECT 'N' reg, pk_message.get_message(i_lang, 'COMMON_M007') desc_estate
                      FROM dual;
            
        END;
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_estate_epis);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_owner_name, g_pck_name, 'GET_ESTATE_EPIS');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN l_ret;
            END;
    END;

    FUNCTION get_nkda_label
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_pat IN patient.id_patient%TYPE,
        o_nkda   OUT VARCHAR2,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        /******************************************************************************
           OBJECTIVO:   Retornar o descritivo a dizer se o paciente tem ou não alergias a fármacos conhecidas
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                                 I_PROF - ID do profissional
                                 I_ID_PAT - ID do paciente
                     Saida:   O_NKDA - descritivo
                               O_ERROR - erro
          CRIAÇÃO: ASM 2007/01/30
          NOTAS:
        *********************************************************************************/
    
    BEGIN
    
        g_error := 'GET CURSOR C_NKDA';
    
        BEGIN
        
            SELECT pk_translation.get_translation(i_lang, au.code_allergy_unawareness) text
              INTO o_nkda
              FROM pat_allergy_unawareness pau, allergy_unawareness au
             WHERE pau.id_allergy_unawareness = au.id_allergy_unawareness
               AND pau.id_patient = i_id_pat
               AND pau.id_allergy_unawareness = g_id_allergy_unawareness
               AND pau.flg_status = pk_alert_constant.g_active;
        
        EXCEPTION
            WHEN OTHERS THEN
                o_nkda := '';
        END;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_owner_name, g_pck_name, 'GET_NKDA_LABEL');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN l_ret;
            END;
        
    END;

    --
    /********************************************************************************************
    * This function returns the software of one episode
    *
    * @param i_lang                language
    * @param i_prof                profissional
    * @param i_id_episode          episode id
    * @param o_id_software         episode software
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      Luis Gaspar
    * @version                     1.0
    * @since                       2007/02/23
    **********************************************************************************************/

    FUNCTION get_episode_software
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        o_id_software OUT software.id_software%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET SOFTWARE';
        SELECT pk_episode.get_soft_by_epis_type(e.id_epis_type, e.id_institution)
          INTO o_id_software
          FROM episode e
         WHERE e.id_episode = i_id_episode;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_owner_name, g_pck_name, 'GET_EPISODE_SOFTWARE');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN l_ret;
            END;
    END get_episode_software;

    /********************************************************************************************
    * This function returns the software of one episode
    *
    * @param i_lang                language
    * @param i_prof                profissional
    * @param i_id_episode          episode id
    * @param o_id_software         episode software
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      Sofia Mendes
    * @version                     2.6.2
    * @since                       13-Jul-2012
    **********************************************************************************************/

    FUNCTION get_episode_software
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN software.id_software%TYPE IS
        l_id_episode episode.id_episode%TYPE;
        l_func_name CONSTANT VARCHAR2(20 CHAR) := 'GET_EPISODE_SOFTWARE';
        l_error t_error_out;
    BEGIN
        g_error := 'CALL pk_episode.get_episode_software';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_episode.get_episode_software(i_lang        => i_lang,
                                               i_prof        => i_prof,
                                               i_id_episode  => i_id_episode,
                                               o_id_software => l_id_episode,
                                               o_error       => l_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN l_id_episode;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner_name,
                                              g_pck_name,
                                              l_func_name,
                                              l_error);
            RETURN NULL;
    END get_episode_software;

    --
    /**********************************************************************************************
    * Actualizar o episódio de origem do espólio bem como as respectivas tabelas de relação.
      Utilizada aquando a passagem de Urgência para Internamento ser?necessário actualizar o ID_EPISODE no espólio
      com o novo episódio (INP) e o ID_EPISODE_ORIGIN ficar?com o episódio de urgência (EDIS)
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_prof_cat_type          categoty professional
    * @param i_episode                episode id
    * @param i_new_episode            new episode id
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2007/04/10
    **********************************************************************************************/
    FUNCTION update_estate
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_new_episode   IN episode.id_episode%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'UPDATE ESTATE';
        UPDATE estate
           SET id_episode = i_new_episode, id_prev_episode = i_episode
         WHERE id_episode = i_episode;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_owner_name, g_pck_name, 'UPDATE_ESTATE');
                -- undo changes quando aplicável
                pk_utils.undo_changes;
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN l_ret;
            END;
    END;

    /**
    * Get the list of previous episodes.
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_patient                patient identifier
    * @param i_episode                episode identifier
    * @param I_FLG_TYPE          Tipo de filtro: C - Comigo, neste tipo de consulta
    *                                                 T - Neste tipo de consulta
    *                                                 E - Doutra especialidade
    *                                                 TE - Todas as especialidades
    * @param      I_SEARCH            parâmetro de pesquisa (p. ex. da especialidade escolhida)
    * @param i_id_clinical_service    clinical service identifier
    *
    * @return               notes
    *
    * @author               Sofia Mendes
    * @version               2.5
    * @since                20/03/2013
    */
    FUNCTION get_prev_episodes_list
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_patient             IN patient.id_patient%TYPE,
        i_episode             IN episode.id_episode%TYPE,
        i_flg_type            IN VARCHAR2,
        i_search              IN NUMBER,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_epis_type           IN epis_type.id_epis_type%TYPE,
        i_id_epis_hhc_req     IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_episodes            OUT NOCOPY table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof_cat         category.flg_type%TYPE;
        l_handoff_type     sys_config.value%TYPE;
        l_ehr_epis_summary sys_config.value%TYPE;
        l_all_epis_type_v  table_varchar := table_varchar();
        l_all_epis_type_n  table_number := table_number();
    
    BEGIN
        g_error := 'GET PROF CAT';
        alertlog.pk_alertlog.log_info(text => g_error);
        l_prof_cat := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
    
        g_error := 'GET HANDOFF TYPE';
        alertlog.pk_alertlog.log_info(text => g_error);
        pk_hand_off_core.get_hand_off_type(i_lang => i_lang, i_prof => i_prof, io_hand_off_type => l_handoff_type);
    
        g_error := 'GET previous Episodes list. i_patient: ' || i_patient || ' i_episode: ' || i_episode ||
                   ' i_flg_type: ' || i_flg_type || ' i_search: ' || i_search || ' i_id_clinical_service: ' ||
                   i_id_clinical_service;
        pk_alertlog.log_debug(g_error);
    
        --get what epis_type would be diaply
        l_ehr_epis_summary := pk_sysconfig.get_config(i_code_cf => 'EHR_EPIS_SUMMARY_CATEGORY', i_prof => i_prof);
        IF (l_ehr_epis_summary IS NOT NULL)
        THEN
            SELECT regexp_substr(l_ehr_epis_summary, '[^\|]+', 1, LEVEL)
              BULK COLLECT
              INTO l_all_epis_type_v
              FROM dual
            CONNECT BY regexp_substr(l_ehr_epis_summary, '[^\|]+', 1, LEVEL) IS NOT NULL;
        
            FOR i IN 1 .. l_all_epis_type_v.count
            LOOP
                l_all_epis_type_n.extend(1);
                l_all_epis_type_n(l_all_epis_type_n.count) := to_number(l_all_epis_type_v(i));
            END LOOP;
        
        END IF;
    
        IF (i_search IS NULL AND i_flg_type = g_prev_app_other_spec_e)
        THEN
        
            SELECT epis.id_episode
              BULK COLLECT
              INTO o_episodes
              FROM episode epis
              JOIN epis_info ei
                ON ei.id_episode = epis.id_episode
              LEFT JOIN schedule_outp so
                ON so.id_schedule_outp = ei.id_schedule_outp
              JOIN institution i
                ON i.id_institution = epis.id_institution
              LEFT JOIN professional p
                ON ei.id_professional = p.id_professional
             WHERE (epis.id_epis_type = i_epis_type AND i_epis_type IS NOT NULL OR
                   (epis.id_epis_type = epis.id_epis_type AND i_epis_type IS NULL))
               AND ei.id_patient = i_patient
               AND epis.flg_ehr = pk_ehr_access.g_flg_ehr_normal;
        
        ELSIF (l_ehr_epis_summary IS NOT NULL)
              AND i_id_epis_hhc_req IS NULL
        THEN
            SELECT id_episode
              BULK COLLECT
              INTO o_episodes
              FROM (SELECT epis.id_episode
                      FROM episode epis
                      JOIN epis_info ei
                        ON ei.id_episode = epis.id_episode
                      LEFT JOIN schedule_outp so
                        ON so.id_schedule_outp = ei.id_schedule_outp
                      JOIN institution i
                        ON i.id_institution = epis.id_institution
                      LEFT JOIN professional p
                        ON ei.id_professional = p.id_professional
                     WHERE ((pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang          => i_lang,
                                                                                              i_prof          => i_prof,
                                                                                              i_id_episode    => ei.id_episode,
                                                                                              i_prof_cat      => l_prof_cat,
                                                                                              i_hand_off_type => l_handoff_type,
                                                                                              i_my_patients   => pk_alert_constant.g_yes),
                                                          i_prof.id) != -1 AND i_flg_type = g_prev_app_with_me_c AND
                           epis.id_clinical_service = i_id_clinical_service) OR
                           (epis.id_clinical_service = i_id_clinical_service AND i_flg_type = g_prev_app_this_spec_t) OR
                           (epis.id_clinical_service = i_search AND i_flg_type = g_prev_app_other_spec_e) OR
                           (i_flg_type = g_prev_app_all_specs_te AND
                           epis.id_epis_type IN (SELECT column_value
                                                     FROM TABLE(l_all_epis_type_n))) AND
                           epis.id_epis_type != pk_alert_constant.g_hhc_epis_type_shadow)
                          
                       AND ei.id_patient = i_patient
                       AND epis.flg_ehr = pk_ehr_access.g_flg_ehr_normal);
        
        ELSIF i_id_epis_hhc_req IS NOT NULL
              AND i_flg_type IS NOT NULL
        THEN
        
            SELECT epis.id_episode
              BULK COLLECT
              INTO o_episodes
              FROM episode epis
              JOIN epis_info ei
                ON ei.id_episode = epis.id_episode
              LEFT JOIN schedule_outp so
                ON so.id_schedule_outp = ei.id_schedule_outp
              JOIN schedule s
                ON s.id_schedule = so.id_schedule
              JOIN sch_resource sr
                ON sr.id_schedule = s.id_schedule
              JOIN institution i
                ON i.id_institution = epis.id_institution
              LEFT JOIN professional p
                ON ei.id_professional = p.id_professional
             WHERE epis.id_prev_episode = i_episode
               AND ((sr.id_professional = i_prof.id AND epis.id_clinical_service = i_id_clinical_service AND
                   i_flg_type = g_prev_app_with_me_c) OR
                   (epis.id_clinical_service = i_id_clinical_service AND i_flg_type = g_prev_app_this_spec_t) OR
                   (epis.id_clinical_service = i_search AND i_flg_type = g_prev_app_other_spec_e) OR
                   i_flg_type = g_prev_app_all_specs_te)
               AND ei.id_patient = i_patient
               AND epis.id_epis_type = pk_alert_constant.g_hhc_epis_type
               AND epis.flg_ehr = pk_ehr_access.g_flg_ehr_normal;
        ELSE
            -- 
            SELECT epis.id_episode
              BULK COLLECT
              INTO o_episodes
              FROM episode epis
              JOIN epis_info ei
                ON ei.id_episode = epis.id_episode
              LEFT JOIN schedule_outp so
                ON so.id_schedule_outp = ei.id_schedule_outp
              JOIN institution i
                ON i.id_institution = epis.id_institution
              LEFT JOIN professional p
                ON ei.id_professional = p.id_professional
             WHERE ((pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang          => i_lang,
                                                                                      i_prof          => i_prof,
                                                                                      i_id_episode    => ei.id_episode,
                                                                                      i_prof_cat      => l_prof_cat,
                                                                                      i_hand_off_type => l_handoff_type,
                                                                                      i_my_patients   => pk_alert_constant.g_yes),
                                                  i_prof.id) != -1 AND i_flg_type = g_prev_app_with_me_c AND
                   epis.id_clinical_service = i_id_clinical_service) OR
                   (epis.id_clinical_service = i_id_clinical_service AND i_flg_type = g_prev_app_this_spec_t) OR
                   (epis.id_clinical_service = i_search AND i_flg_type = g_prev_app_other_spec_e) OR
                   i_flg_type = g_prev_app_all_specs_te)
               AND ei.id_patient = i_patient
               AND epis.id_epis_type NOT IN
                   ( /*pk_alert_constant.g_hhc_epis_type,*/ pk_alert_constant.g_hhc_epis_type_shadow)
               AND epis.flg_ehr = pk_ehr_access.g_flg_ehr_normal;
        END IF;
    
        RETURN TRUE;
        --
    EXCEPTION
    
        WHEN OTHERS THEN
            o_episodes := table_number();
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_EPISODE',
                                              'GET_PREV_EPISODES_LIST',
                                              o_error);
            RETURN FALSE;
    END get_prev_episodes_list;

    /**
    * Returns an episode clinical service.
    * a identificação do clinical_service, no internamento, não se encontra na tabela episode, mas sim na tabela dep_clin_serv.
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_episode                episode identifier
    *
    * @return               notes
    *
    * @author               Sofia Mendes
    * @version               2.5
    * @since                20/03/2013
    */
    FUNCTION get_epis_clin_serv
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        o_clin_serv OUT clinical_service.id_clinical_service%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF i_prof.software = pk_alert_constant.g_soft_inpatient
        THEN
            g_error := 'GET clinical service from INP episode: ' || i_episode;
            pk_alertlog.log_debug(g_error);
            SELECT cs.id_clinical_service
              INTO o_clin_serv
              FROM episode epi, epis_info ei, dep_clin_serv dcs, clinical_service cs
             WHERE epi.id_episode = i_episode
               AND ei.id_episode = epi.id_episode
               AND ei.id_dep_clin_serv = dcs.id_dep_clin_serv
               AND dcs.id_clinical_service = cs.id_clinical_service;
        ELSE
            g_error := 'GET clinical service from episode: ' || i_episode;
            pk_alertlog.log_debug(g_error);
            SELECT e.id_clinical_service
              INTO o_clin_serv
              FROM episode e
             WHERE e.id_episode = i_episode;
        
        END IF;
    
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_EPISODE',
                                              'GET_EPIS_CLIN_SERV',
                                              o_error);
            RETURN FALSE;
    END get_epis_clin_serv;

    FUNCTION get_plan
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN CLOB IS
        l_desc_info table_varchar := table_varchar();
        l_plan      pk_types.cursor_type;
        l_error     t_error_out;
        l_desc_plan CLOB;
    BEGIN
    
        -- AVALIAÇÃO
        g_error := 'GET CURSOR o_plan: ' || pk_summary_page.g_doc_area_plan;
        IF NOT pk_summary_page.get_summ_all_documentation(i_lang          => i_lang,
                                                          i_prof          => i_prof,
                                                          i_episode       => table_number(i_episode),
                                                          i_doc_area      => pk_summary_page.g_doc_area_plan,
                                                          o_documentation => l_plan,
                                                          o_error         => l_error)
        THEN
            RETURN NULL;
        END IF;
        FETCH l_plan BULK COLLECT
            INTO l_desc_info;
    
        IF l_desc_info IS NOT NULL
           AND l_desc_info.first IS NOT NULL
        THEN
            SELECT concatenate_clob(plan || chr(10))
              INTO l_desc_plan
              FROM (SELECT t.column_value plan
                      FROM TABLE(l_desc_info) t);
        
        END IF;
        RETURN l_desc_plan;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_plan;

    FUNCTION get_prev_epis_summary
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_patient              IN patient.id_patient%TYPE,
        i_episode              IN episode.id_episode%TYPE,
        i_flg_type             IN VARCHAR2,
        i_search               IN NUMBER,
        i_epis_type            IN epis_type.id_epis_type%TYPE,
        i_id_epis_hhc_req      IN epis_hhc_req.id_epis_hhc_req%TYPE DEFAULT NULL,
        o_info                 OUT pk_types.cursor_type,
        o_doc_area_register    OUT NOCOPY pk_touch_option.t_cur_doc_area_register,
        o_doc_area_val         OUT NOCOPY pk_touch_option.t_cur_doc_area_val,
        o_template_layouts     OUT NOCOPY pk_types.cursor_type,
        o_doc_area_component   OUT NOCOPY pk_types.cursor_type,
        o_brief_desc           OUT pk_types.cursor_type,
        o_desc_doc_area        OUT pk_types.cursor_type,
        o_desc_doc_area_detail OUT pk_types.cursor_type,
        o_supp_list            OUT pk_types.cursor_type,
        o_nurse_teach          OUT pk_types.cursor_type,
        o_diag                 OUT pk_types.cursor_type,
        --   o_impressions           OUT pk_types.cursor_type,
        o_warning_msg OUT pk_translation.t_desc_translation,
        --   o_ass_scales            OUT pk_types.cursor_type,
        --   o_doc_area_register_obs OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_internal_error EXCEPTION;
        l_error t_error_out;
        l_func_name CONSTANT VARCHAR2(21 CHAR) := 'GET_PREV_EPIS_SUMMARY';
        l_id_clinical_service clinical_service.id_clinical_service%TYPE;
        l_anamnesis_desc      pk_translation.t_desc_translation := pk_message.get_message(i_lang      => i_lang,
                                                                                          i_code_mess => 'PREV_EPISODE_M003');
        l_evaluation_desc     pk_translation.t_desc_translation := pk_message.get_message(i_lang      => i_lang,
                                                                                          i_code_mess => 'PREV_EPISODE_T772');
        l_plan_desc           pk_translation.t_desc_translation := pk_message.get_message(i_lang      => i_lang,
                                                                                          i_code_mess => 'PREV_EPISODE_T773');
        --
        l_episodes           table_number;
        l_coll_epis_doc      table_number;
        l_coll_epis_anamn    table_number;
        l_coll_epis_rev_sys  table_number;
        l_coll_epis_obs      table_number;
        l_coll_epis_past_fsh table_number;
        l_coll_epis_recomend table_number;
    
        l_record_count PLS_INTEGER := 0;
        l_id_patient   patient.id_patient%TYPE;
    
        l_ehr_epis_summary    sys_config.value%TYPE;
        l_epis_type_operating epis_type.id_epis_type%TYPE := NULL;
        l_all_epis_type_v     table_varchar := table_varchar();
        l_all_epis_type_n     table_number := table_number();
        l_surgery_record      pk_types.cursor_type;
        l_brief_desc          VARCHAR2(1000 CHAR);
        l_tbl_doc_area        table_number := table_number(g_area_history,
                                                           pk_summary_page.g_doc_area_phy_exam,
                                                           pk_summary_page.g_doc_area_plan,
                                                           pk_summary_page.g_doc_area_assessment);
        l_tbl_doc_area_hhc    table_number := table_number(pk_summary_page.g_doc_area_hist_ill,
                                                           pk_summary_page.g_doc_area_rev_sys,
                                                           pk_summary_page.g_doc_area_phy_exam,
                                                           pk_summary_page.g_doc_area_neur_exam,
                                                           pk_summary_page.g_doc_area_mental_st_exm,
                                                           pk_summary_page.g_doc_area_mini_ment_exm,
                                                           pk_summary_page.g_doc_area_assessment,
                                                           pk_summary_page.g_doc_area_nur_init_ass,
                                                           pk_summary_page.g_doc_area_nurse_assess,
                                                           pk_summary_page.g_doc_area_assessments,
                                                           pk_summary_page.g_doc_area_assessment,
                                                           pk_summary_page.g_doc_area_nutr_assess,
                                                           pk_summary_page.g_doc_area_nutritional_a,
                                                           pk_summary_page.g_doc_area_ini_res_the_a,
                                                           pk_summary_page.g_doc_area_prg_notes_tec,
                                                           pk_summary_page.g_doc_area_abuse_history,
                                                           pk_summary_page.g_doc_area_plan,
                                                           pk_summary_page.g_doc_area_treatments,
                                                           pk_summary_page.g_doc_area_orienta_notes,
                                                           pk_summary_page.g_doc_area_inten_hc,
                                                           pk_summary_page.g_doc_area_educ_assess);
    
        l_tbl_aux_doc_area table_number := table_number();
    
        l_tbl_doc_area_det table_number := table_number(g_area_history,
                                                        pk_clinical_info.g_doc_area_rev_sys,
                                                        pk_summary_page.g_doc_area_phy_exam,
                                                        pk_summary_page.g_doc_area_plan,
                                                        pk_summary_page.g_doc_area_assessment,
                                                        pk_summary_page.g_doc_area_past_fam,
                                                        pk_summary_page.g_doc_area_past_soc);
    
        l_tbl_doc_area_hhc_det table_number := table_number(pk_summary_page.g_doc_area_perm_incap,
                                                            pk_summary_page.g_doc_area_act_daily_s,
                                                            pk_summary_page.g_doc_area_eval_relat_fam,
                                                            pk_summary_page.g_doc_area_instructions,
                                                            pk_summary_page.g_doc_area_disch_notes,
                                                            pk_summary_page.g_doc_area_past_surg,
                                                            pk_summary_page.g_doc_area_past_fam,
                                                            pk_summary_page.g_doc_area_past_soc,
                                                            pk_summary_page.g_doc_area_mental_hist,
                                                            pk_summary_page.g_doc_area_past_psy_hist,
                                                            pk_summary_page.g_doc_area_personal_hist,
                                                            pk_summary_page.g_doc_area_occup_hist,
                                                            pk_summary_page.g_doc_area_foren_hist,
                                                            pk_summary_page.g_doc_area_gyn_hist,
                                                            pk_summary_page.g_doc_area_obs_hist,
                                                            pk_summary_page.g_doc_area_cong_anom,
                                                            pk_summary_page.g_doc_area_relev_notes,
                                                            pk_summary_page.g_doc_area_ped_nutrit,
                                                            pk_summary_page.g_doc_area_gener_ped_ass,
                                                            pk_summary_page.g_doc_area_develop_ass);
    
        l_tbl_aux_doc_area_det table_number := table_number();
        l_id_episode           episode.id_episode%TYPE;
        l_tbl_id_doc_area      table_number := table_number(21,
                                                            22,
                                                            28,
                                                            1045,
                                                            36076,
                                                            36077,
                                                            6592,
                                                            35,
                                                            5592,
                                                            5096,
                                                            6704,
                                                            280105,
                                                            36100,
                                                            36150,
                                                            6725,
                                                            36140,
                                                            36110,
                                                            6753,
                                                            36090,
                                                            36064,
                                                            6752);
        l_tbl_desc_doc_area    table_varchar := table_varchar();
        l_flg_type_supp        table_varchar := table_varchar('I', 'K', 'S', 'E', 'P');
        l_limit                sys_config.value%TYPE := pk_sysconfig.get_config('PREV_EPIS_SUMMARY_LIMIT', i_prof);
    
        l_impressions pk_types.cursor_type;
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        IF i_patient IS NULL
        THEN
            l_id_patient := pk_episode.get_id_patient(i_episode => i_episode);
        ELSE
            l_id_patient := i_patient;
        END IF;
    
        g_error := 'CALL get_epis_clin_serv';
        pk_alertlog.log_debug(g_error);
        IF NOT get_epis_clin_serv(i_lang      => i_lang,
                                  i_prof      => i_prof,
                                  i_episode   => i_episode,
                                  o_clin_serv => l_id_clinical_service,
                                  o_error     => o_error)
        THEN
            l_id_clinical_service := -1;
        END IF;
    
        IF i_id_epis_hhc_req IS NOT NULL
        THEN
            l_tbl_aux_doc_area     := l_tbl_doc_area_hhc;
            l_tbl_aux_doc_area_det := l_tbl_doc_area_hhc_det;
        
            --get id of episode (epis_hhc)
            l_id_episode := pk_hhc_core.get_id_epis_hhc_by_hhc_req(i_id_hhc_req => i_id_epis_hhc_req);
        
        ELSE
            l_tbl_aux_doc_area     := l_tbl_doc_area;
            l_tbl_aux_doc_area_det := l_tbl_doc_area_det;
            l_id_episode           := i_episode;
        END IF;
    
        --doc_area descriptions
        FOR r IN l_tbl_aux_doc_area.first() .. l_tbl_aux_doc_area.last()
        LOOP
            l_tbl_desc_doc_area.extend(1);
            SELECT pk_translation.get_translation(i_lang, da.code_doc_area)
              INTO l_tbl_desc_doc_area(l_tbl_desc_doc_area.count)
              FROM doc_area da
             WHERE da.id_doc_area = l_tbl_aux_doc_area(r);
        END LOOP;
    
        OPEN o_desc_doc_area FOR
            SELECT id_doc_area, doc_area_desc
              FROM (SELECT rownum rnum, column_value id_doc_area
                      FROM TABLE(l_tbl_aux_doc_area)) tid
              JOIN (SELECT rownum rnum, column_value doc_area_desc
                      FROM TABLE(l_tbl_desc_doc_area)) tdesc
                ON tid.rnum = tdesc.rnum;
    
        --doc_area descriptions
        l_tbl_desc_doc_area := table_varchar();
        FOR r IN l_tbl_aux_doc_area_det.first() .. l_tbl_aux_doc_area_det.last()
        LOOP
            l_tbl_desc_doc_area.extend(1);
            SELECT pk_translation.get_translation(i_lang, da.code_doc_area)
              INTO l_tbl_desc_doc_area(l_tbl_desc_doc_area.count)
              FROM doc_area da
             WHERE da.id_doc_area = l_tbl_aux_doc_area_det(r);
        END LOOP;
    
        OPEN o_desc_doc_area_detail FOR
            SELECT id_doc_area, doc_area_desc
              FROM (SELECT rownum rnum, column_value id_doc_area
                      FROM TABLE(l_tbl_aux_doc_area_det)) tid
              JOIN (SELECT rownum rnum, column_value doc_area_desc
                      FROM TABLE(l_tbl_desc_doc_area)) tdesc
                ON tid.rnum = tdesc.rnum;
    
        g_error := 'CALL get_prev_episodes_list';
        pk_alertlog.log_debug(g_error);
        IF NOT get_prev_episodes_list(i_lang                => i_lang,
                                      i_prof                => i_prof,
                                      i_patient             => l_id_patient,
                                      i_episode             => l_id_episode,
                                      i_flg_type            => i_flg_type,
                                      i_search              => i_search,
                                      i_id_clinical_service => l_id_clinical_service,
                                      i_epis_type           => i_epis_type,
                                      i_id_epis_hhc_req     => i_id_epis_hhc_req,
                                      o_episodes            => l_episodes,
                                      o_error               => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        g_error := 'COUNT o_info';
        SELECT COUNT(1)
          INTO l_record_count
          FROM (SELECT 1
                  FROM episode epis
                  JOIN epis_info ei
                    ON ei.id_episode = epis.id_episode
                  JOIN epis_type et
                    ON et.id_epis_type = epis.id_epis_type
                  LEFT JOIN schedule_outp so
                    ON so.id_schedule_outp = ei.id_schedule_outp
                  JOIN institution i
                    ON i.id_institution = epis.id_institution
                  LEFT JOIN professional p
                    ON ei.id_professional = p.id_professional
                 WHERE epis.id_episode IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                            t.column_value
                                             FROM TABLE(l_episodes) t)
                UNION ALL
                SELECT 1
                  FROM p1_external_request exr
                  JOIN patient pat
                    ON (exr.id_patient = pat.id_patient)
                  JOIN institution ist
                    ON (exr.id_inst_orig = ist.id_institution)
                  JOIN epis_type et
                    ON (et.id_epis_type = 1)
                  JOIN professional p
                    ON (exr.id_prof_requested = p.id_professional)
                  LEFT JOIN dep_clin_serv dcs
                    ON (exr.id_dep_clin_serv = dcs.id_dep_clin_serv)
                  LEFT JOIN clinical_service cs
                    ON (dcs.id_clinical_service = cs.id_clinical_service)
                  LEFT JOIN department d
                    ON (dcs.id_department = d.id_department)
                  LEFT JOIN schedule_outp so
                    ON (exr.id_schedule = so.id_schedule)
                  LEFT JOIN sch_prof_outp spo
                    ON (so.id_schedule_outp = spo.id_schedule_outp)
                  LEFT JOIN p1_speciality ps
                    ON (exr.id_speciality = ps.id_speciality)
                 WHERE pat.id_patient = l_id_patient
                   AND exr.flg_status IN (pk_alert_constant.g_p1_status_a,
                                          pk_alert_constant.g_p1_status_s,
                                          pk_alert_constant.g_p1_status_m,
                                          pk_alert_constant.g_p1_status_e,
                                          pk_alert_constant.g_p1_status_f)
                   AND exr.flg_type = pk_alert_constant.g_p1_type_c
                   AND d.id_institution = i_prof.institution
                   AND ((spo.id_professional = i_prof.id AND i_flg_type = 'C') OR
                       (cs.id_clinical_service = l_id_clinical_service AND i_flg_type = 'T') OR
                       (cs.id_clinical_service = i_search AND i_flg_type = 'E') OR i_flg_type = 'TE'));
    
        IF l_record_count > l_limit
        THEN
            o_warning_msg := REPLACE(pk_message.get_message(i_lang => i_lang, i_code_mess => 'PREV_EPISODE_M007'),
                                     '@1',
                                     l_limit);
        END IF;
    
        g_error := 'OPEN o_info';
        pk_alertlog.log_debug(g_error);
        OPEN o_info FOR
            SELECT *
              FROM (SELECT epis.id_episode,
                           NULL id_p1,
                           NULL id_external_request,
                           (SELECT pk_date_utils.date_send_tsz(i_lang, epis.dt_begin_tstz, i_prof)
                              FROM dual) dt,
                           (SELECT pk_date_utils.dt_chr_tsz(i_lang,
                                                            epis.dt_begin_tstz,
                                                            i_prof.institution,
                                                            i_prof.software)
                              FROM dual) dt_begin,
                           (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, ei.id_professional)
                              FROM dual) nick_name,
                           (SELECT pk_translation.get_translation(i_lang, et.code_epis_type)
                              FROM dual) desc_speciality,
                           nvl(i.abbreviation,
                               (SELECT pk_translation.get_translation(i_lang, i.code_institution)
                                  FROM dual)) instit,
                           CASE
                                WHEN epis.id_epis_type = pk_alert_constant.g_epis_type_rehab_appointment THEN
                                 (SELECT pk_translation.get_translation(i_lang, et.code_epis_type)
                                    FROM dual)
                                WHEN epis.id_epis_type = pk_alert_constant.g_epis_type_rehab_session THEN
                                 (SELECT pk_episode.get_desc_rehab_area(i_lang, i_prof, epis.id_episode)
                                    FROM dual)
                                ELSE
                                 (SELECT pk_translation.get_translation(i_lang,
                                                                        'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' ||
                                                                        epis.id_clinical_service)
                                    FROM dual)
                            END clin_serv,
                           (SELECT pk_sysdomain.get_domain('SCHEDULE_OUTP.FLG_TYPE', so.flg_type, i_lang)
                              FROM dual) cons,
                           -- MOTIVO DE CONSULTA --
                           l_anamnesis_desc anamnesis_desc,
                           pk_string_utils.clob_to_varchar2((SELECT pk_clinical_info.get_epis_reason_for_visit(i_lang,
                                                                                                              profissional(i_prof.id,
                                                                                                                           nvl(epis.id_institution,
                                                                                                                               i_prof.institution),
                                                                                                                           nvl(ei.id_software,
                                                                                                                               i_prof.software)),
                                                                                                              epis.id_episode,
                                                                                                              so.id_schedule)
                                                              FROM dual),
                                                            4000) anamnesis,
                           -- AVALICACAO --
                           l_evaluation_desc evaluation_desc,
                           --                           (SELECT get_epis_recommend_notes(i_lang,
                           --                                                          i_prof,
                           --                                                         epis.id_episode,
                           --                                                        g_flg_aval,
                           --                                                       i_order_desc => pk_alert_constant.g_yes)
                           --                        FROM dual) 
                           NULL evaluation,
                           -- PLANO --
                           l_plan_desc plan_desc,
                           (SELECT get_plan(i_lang, i_prof, epis.id_episode)
                              FROM dual) plan,
                           -- VIEWER AUXILIAR --
                           et.code_epis_type viewer_category,
                           (SELECT pk_translation.get_translation(i_lang, et.code_epis_type)
                              FROM dual) viewer_category_desc,
                           ei.id_professional viewer_id_prof,
                           (SELECT pk_date_utils.date_send_tsz(i_lang, epis.dt_begin_tstz, i_prof)
                              FROM dual) viewer_date,
                           CASE
                                WHEN i_id_epis_hhc_req IS NOT NULL THEN
                                 '(' ||
                                 (SELECT pk_prof_teams.get_hhc_prof_category(i_lang, p.id_professional, i_prof.institution)
                                    FROM dual) || ')'
                                ELSE
                                 NULL
                            END cat,
                           CASE
                                WHEN i_id_epis_hhc_req IS NOT NULL THEN
                                 (SELECT pk_hhc_core.get_list_prof_cat(i_lang,
                                                                       i_prof,
                                                                       ei.id_schedule,
                                                                       pk_alert_constant.g_flg_action_t)
                                    FROM dual)
                                ELSE
                                 NULL
                            END title_hhc,
                           CASE
                                WHEN i_id_epis_hhc_req IS NOT NULL THEN
                                 (SELECT pk_hhc_core.get_list_prof_cat(i_lang,
                                                                       i_prof,
                                                                       ei.id_schedule,
                                                                       pk_alert_constant.g_flg_action_d)
                                    FROM dual)
                                ELSE
                                 NULL
                            END descr_hhc
                    
                      FROM episode epis
                      JOIN epis_info ei
                        ON ei.id_episode = epis.id_episode
                      JOIN epis_type et
                        ON et.id_epis_type = epis.id_epis_type
                      LEFT JOIN schedule_outp so
                        ON so.id_schedule_outp = ei.id_schedule_outp
                      JOIN institution i
                        ON i.id_institution = epis.id_institution
                      LEFT JOIN professional p
                        ON ei.id_professional = p.id_professional
                     WHERE epis.id_episode IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                t.column_value
                                                 FROM TABLE(l_episodes) t)
                    
                    -- Incluir P1
                    UNION ALL
                    SELECT NULL id_episode,
                           exr.num_req id_p1,
                           exr.id_external_request id_external_request,
                           (SELECT pk_date_utils.date_send_tsz(i_lang, exr.dt_requested, i_prof)
                              FROM dual) dt,
                           pk_date_utils.dt_chr_tsz(i_lang, exr.dt_requested, i_prof.institution, i_prof.software) dt_begin,
                           (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional)
                              FROM dual) nick_name,
                           NULL desc_speciality,
                           nvl(ist.abbreviation,
                               (SELECT pk_translation.get_translation(i_lang, ist.code_institution)
                                  FROM dual)) instit,
                           (SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service)
                              FROM dual) clin_serv,
                           (SELECT pk_message.get_message(i_lang, 'EPIS_HISTORY_M001') || ' ' ||
                                   pk_translation.get_translation(i_lang, cs.code_clinical_service)
                              FROM dual) cons,
                           l_anamnesis_desc anamnesis_desc,
                           decode(exr.flg_type,
                                  pk_alert_constant.g_p1_type_c,
                                  pk_translation.get_translation(i_lang, ps.code_speciality),
                                  (SELECT pk_sysdomain.get_domain('P1_EXTERNAL_REQUEST.FLG_TYPE', exr.flg_type, i_lang)
                                     FROM dual)) anamnesis,
                           NULL evaluation_desc,
                           NULL evaluation,
                           NULL plan_desc,
                           NULL plan,
                           --Nelson Lima, 25-10-2007 - Needed for the new episodes screen on Viewer
                           et.code_epis_type viewer_category,
                           (SELECT pk_translation.get_translation(i_lang, et.code_epis_type)
                              FROM dual) viewer_category_desc,
                           spo.id_professional viewer_id_prof,
                           (SELECT pk_date_utils.date_send_tsz(i_lang, exr.dt_requested, i_prof)
                              FROM dual) viewer_date,
                           CASE
                               WHEN i_id_epis_hhc_req IS NOT NULL THEN
                                (SELECT pk_prof_teams.get_hhc_prof_category(i_lang, p.id_professional, i_prof.institution)
                                   FROM dual)
                               ELSE
                                NULL
                           END cat,
                           NULL title_hhc,
                           NULL descr_hhc
                      FROM p1_external_request exr
                      JOIN patient pat
                        ON (exr.id_patient = pat.id_patient)
                      JOIN institution ist
                        ON (exr.id_inst_orig = ist.id_institution)
                      JOIN epis_type et
                        ON (et.id_epis_type = 1)
                      JOIN professional p
                        ON (exr.id_prof_requested = p.id_professional)
                      LEFT JOIN dep_clin_serv dcs
                        ON (exr.id_dep_clin_serv = dcs.id_dep_clin_serv)
                      LEFT JOIN clinical_service cs
                        ON (dcs.id_clinical_service = cs.id_clinical_service)
                      LEFT JOIN department d
                        ON (dcs.id_department = d.id_department)
                      LEFT JOIN schedule_outp so
                        ON (exr.id_schedule = so.id_schedule)
                      LEFT JOIN sch_prof_outp spo
                        ON (so.id_schedule_outp = spo.id_schedule_outp)
                      LEFT JOIN p1_speciality ps
                        ON (exr.id_speciality = ps.id_speciality)
                     WHERE pat.id_patient = l_id_patient
                       AND exr.flg_status IN (pk_alert_constant.g_p1_status_a,
                                              pk_alert_constant.g_p1_status_s,
                                              pk_alert_constant.g_p1_status_m,
                                              pk_alert_constant.g_p1_status_e,
                                              pk_alert_constant.g_p1_status_f)
                       AND exr.flg_type = pk_alert_constant.g_p1_type_c
                       AND d.id_institution = i_prof.institution
                       AND ((spo.id_professional = i_prof.id AND i_flg_type = 'C') OR
                           (cs.id_clinical_service = l_id_clinical_service AND i_flg_type = 'T') OR
                           (cs.id_clinical_service = i_search AND i_flg_type = 'E') OR i_flg_type = 'TE')
                     ORDER BY dt DESC)
             WHERE rownum <= l_limit;
    
        --touch-option areas
        --HPI 
        g_error := 'CALL pk_touch_option.get_doc_area_value_ids function HPI.';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_touch_option.get_doc_area_value_ids(i_lang               => i_lang,
                                                      i_prof               => i_prof,
                                                      i_doc_area           => l_tbl_aux_doc_area,
                                                      i_scope              => l_episodes,
                                                      i_scope_type         => pk_alert_constant.g_scope_type_episode,
                                                      i_fltr_status        => pk_touch_option.g_active,
                                                      o_record_count       => l_record_count,
                                                      o_coll_epis_doc      => l_coll_epis_doc,
                                                      o_coll_epis_anamn    => l_coll_epis_anamn,
                                                      o_coll_epis_rev_sys  => l_coll_epis_rev_sys,
                                                      o_coll_epis_obs      => l_coll_epis_obs,
                                                      o_coll_epis_past_fsh => l_coll_epis_past_fsh,
                                                      o_coll_epis_recomend => l_coll_epis_recomend,
                                                      o_error              => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        g_error := 'CALL pk_touch_option.get_doc_area_value_internal';
        pk_alertlog.log_info(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        IF NOT pk_touch_option.get_doc_area_value_internal(i_lang               => i_lang,
                                                           i_prof               => i_prof,
                                                           i_id_episode         => i_episode,
                                                           i_id_patient         => l_id_patient,
                                                           i_doc_area           => NULL,
                                                           i_epis_doc           => l_coll_epis_doc,
                                                           i_epis_anamn         => l_coll_epis_anamn,
                                                           i_epis_rev_sys       => l_coll_epis_rev_sys,
                                                           i_epis_obs           => l_coll_epis_obs,
                                                           i_epis_past_fsh      => l_coll_epis_past_fsh,
                                                           i_epis_recomend      => l_coll_epis_recomend,
                                                           o_doc_area_register  => o_doc_area_register,
                                                           o_doc_area_val       => o_doc_area_val,
                                                           o_template_layouts   => o_template_layouts,
                                                           o_doc_area_component => o_doc_area_component,
                                                           o_error              => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        --Surgery record
        --check oris's episode that through interface display or not
        l_ehr_epis_summary := pk_sysconfig.get_config(i_code_cf => 'EHR_EPIS_SUMMARY_CATEGORY', i_prof => i_prof);
        IF (l_ehr_epis_summary IS NOT NULL)
        THEN
            SELECT regexp_substr(l_ehr_epis_summary, '[^\|]+', 1, LEVEL)
              BULK COLLECT
              INTO l_all_epis_type_v
              FROM dual
            CONNECT BY regexp_substr(l_ehr_epis_summary, '[^\|]+', 1, LEVEL) IS NOT NULL;
        
            FOR i IN 1 .. l_all_epis_type_v.count
            LOOP
                l_all_epis_type_n.extend(1);
                l_all_epis_type_n(l_all_epis_type_n.count) := to_number(l_all_epis_type_v(i));
            END LOOP;
        
            SELECT t.id_epis_type
              INTO l_epis_type_operating
              FROM (SELECT column_value id_epis_type
                      FROM TABLE(l_all_epis_type_n)) t
             WHERE t.id_epis_type = pk_alert_constant.g_epis_type_operating;
        END IF;
    
        IF (l_epis_type_operating IS NOT NULL)
        THEN
            g_error := 'CALL pk_sr_surg_record.get_sr_brief_det';
            pk_alertlog.log_info(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        
            IF NOT pk_sr_surg_record.get_sr_brief_det(i_lang                 => i_lang,
                                                      i_prof                 => i_prof,
                                                      i_epis                 => l_episodes,
                                                      i_patient              => l_id_patient,
                                                      o_brief_surgery_record => o_brief_desc,
                                                      o_error                => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
        END IF;
    
        IF i_id_epis_hhc_req IS NOT NULL
        THEN
            --SUPPLIES
            IF NOT pk_supplies_core.get_supply_listview(i_lang           => i_lang,
                                                        i_prof           => i_prof,
                                                        i_id_supply_area => NULL,
                                                        i_patient        => l_id_patient,
                                                        i_episode        => i_episode,
                                                        i_flg_type       => l_flg_type_supp,
                                                        i_id_hhc_req     => i_id_epis_hhc_req,
                                                        o_list           => o_supp_list,
                                                        o_error          => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            --patient education
            --REQ ENSINOS
            g_error := 'GET CURSOR o_nurse_teach';
            OPEN o_nurse_teach FOR
                SELECT decode(ntr.id_nurse_tea_topic,
                              1,
                              nvl(ntr.desc_topic_aux,
                                  pk_translation.get_translation(i_lang,
                                                                 (SELECT ntt.code_nurse_tea_topic
                                                                    FROM nurse_tea_topic ntt
                                                                   WHERE ntt.id_nurse_tea_topic = ntr.id_nurse_tea_topic))),
                              pk_translation.get_translation(i_lang,
                                                             (SELECT ntt.code_nurse_tea_topic
                                                                FROM nurse_tea_topic ntt
                                                               WHERE ntt.id_nurse_tea_topic = ntr.id_nurse_tea_topic))) desc_info,
                       ntr.id_episode,
                       pk_prof_utils.get_detail_signature(i_lang,
                                                          profissional(i_prof.id, i_prof.institution, i_prof.software),
                                                          ntr.id_episode,
                                                          ntr.dt_nurse_tea_req_tstz,
                                                          ntr.id_prof_req) signature
                  FROM nurse_tea_req ntr
                 WHERE ntr.id_episode IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                           t.column_value
                                            FROM TABLE(l_episodes) t)
                   AND ntr.flg_status NOT IN
                       (pk_patient_education_api_db.g_nurse_tea_req_canc,
                        pk_patient_education_api_db.g_nurse_tea_req_draft,
                        pk_patient_education_api_db.g_nurse_tea_req_expired,
                        pk_patient_education_api_db.g_nurse_tea_req_not_ord_reas)
                 ORDER BY ntr.dt_nurse_tea_req_tstz;
        
            g_error := 'CALL pk_diagnosis.get_epis_diag_with_notes';
            IF NOT pk_diagnosis.get_epis_diag_with_notes(i_lang        => i_lang,
                                                         i_prof        => i_prof,
                                                         i_tbl_episode => l_episodes,
                                                         o_diag        => o_diag,
                                                         o_impressions => l_impressions,
                                                         o_error       => l_error)
            THEN
                RAISE g_exception;
            END IF;
        
            /*      -- Assessment Scales
            g_error := 'CALL pk_scales_api.get_epis_ass_scales_scores';
            IF NOT pk_scales_api.get_epis_ass_scales_scores(i_lang            => i_lang,
                                                            i_prof            => i_prof,
                                                            i_tbl_episode     => l_episodes,
                                                            i_show_all_scores => pk_alert_constant.g_no,
                                                            o_ass_scales      => o_ass_scales,
                                                            o_error           => o_error)
            THEN
                RAISE g_exception;
            END IF;*/
        
            -- Obstetric history
            /*         g_error := 'CALL TO pk_pregnancy.get_summ_page_doc_area_pregn';
            IF NOT pk_pregnancy.get_summ_page_doc_area_pregn(i_lang              => i_lang,
                                                             i_prof              => i_prof,
                                                             i_episode           => i_episode,
                                                             i_pat               => l_id_patient,
                                                             i_doc_area          => pk_summary_page.g_doc_area_obs_hist,
                                                             o_doc_area_register => o_doc_area_register_obs,
                                                             o_doc_area_val      => l_doc_area_val_obs,
                                                             o_error             => o_error)
            THEN
                RAISE g_exception;
            END IF;*/
        
        END IF;
    
        pk_types.open_cursor_if_closed(o_info);
        pk_types.open_cursor_if_closed(o_doc_area_register);
        pk_types.open_cursor_if_closed(o_doc_area_val);
        pk_types.open_cursor_if_closed(o_template_layouts);
        pk_types.open_cursor_if_closed(o_doc_area_component);
        pk_types.open_cursor_if_closed(o_brief_desc);
        pk_types.open_cursor_if_closed(o_desc_doc_area);
        pk_types.open_cursor_if_closed(o_desc_doc_area_detail);
        pk_types.open_cursor_if_closed(o_supp_list);
        pk_types.open_cursor_if_closed(o_nurse_teach);
        pk_types.open_cursor_if_closed(o_diag);
        --    pk_types.open_cursor_if_closed(o_impressions);
    
        --       pk_types.open_cursor_if_closed(o_ass_scales);
        --       pk_types.open_cursor_if_closed(o_doc_area_register_obs);
        --       pk_types.open_cursor_if_closed(l_doc_area_val_obs);
    
        RETURN TRUE;
        --
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_cursor_if_closed(o_info);
            pk_types.open_cursor_if_closed(o_doc_area_register);
            pk_types.open_cursor_if_closed(o_doc_area_val);
            pk_types.open_cursor_if_closed(o_template_layouts);
            pk_types.open_cursor_if_closed(o_doc_area_component);
            pk_types.open_cursor_if_closed(o_brief_desc);
            pk_types.open_cursor_if_closed(o_desc_doc_area);
            pk_types.open_cursor_if_closed(o_desc_doc_area_detail);
            pk_types.open_cursor_if_closed(o_supp_list);
            pk_types.open_cursor_if_closed(o_nurse_teach);
            pk_types.open_cursor_if_closed(o_diag);
            --         pk_types.open_cursor_if_closed(o_impressions);
            --         pk_types.open_cursor_if_closed(o_ass_scales);
            --         pk_types.open_cursor_if_closed(o_doc_area_register_obs);
            --         pk_types.open_cursor_if_closed(l_doc_area_val_obs);
            o_error := l_error;
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                pk_types.open_cursor_if_closed(o_info);
                pk_types.open_cursor_if_closed(o_doc_area_register);
                pk_types.open_cursor_if_closed(o_doc_area_val);
                pk_types.open_cursor_if_closed(o_template_layouts);
                pk_types.open_cursor_if_closed(o_doc_area_component);
                pk_types.open_cursor_if_closed(o_brief_desc);
                pk_types.open_cursor_if_closed(o_desc_doc_area);
                pk_types.open_cursor_if_closed(o_desc_doc_area_detail);
                pk_types.open_cursor_if_closed(o_supp_list);
                pk_types.open_cursor_if_closed(o_nurse_teach);
                pk_types.open_cursor_if_closed(o_diag);
                --           pk_types.open_cursor_if_closed(o_impressions);
                --          pk_types.open_cursor_if_closed(o_ass_scales);
                --           pk_types.open_cursor_if_closed(o_doc_area_register_obs);
                --          pk_types.open_cursor_if_closed(l_doc_area_val_obs);
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_owner_name, g_pck_name, l_func_name);
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN l_ret;
            END;
        
            ROLLBACK;
            RETURN FALSE;
        
    END;

    FUNCTION get_prev_epis_det
    (
        i_lang            IN language.id_language%TYPE,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN table_number,
        i_prof            IN profissional,
        o_complaint       OUT pk_types.cursor_type,
        o_allergy         OUT pk_types.cursor_type,
        o_habit           OUT pk_types.cursor_type,
        o_relev_disease   OUT pk_types.cursor_type,
        o_relev_notes     OUT pk_types.cursor_type,
        o_medication      OUT pk_types.cursor_type,
        o_home_med_review OUT pk_types.cursor_type,
        o_pat_take        OUT pk_types.cursor_type,
        o_vital_sign      OUT pk_types.cursor_type,
        o_biometric       OUT pk_types.cursor_type,
        o_blood_group     OUT pk_types.cursor_type,
        o_info7           OUT pk_types.cursor_type,
        o_problems        OUT pk_types.cursor_type,
        o_ass_scales      OUT pk_types.cursor_type,
        o_body_diags      OUT pk_types.cursor_type,
        o_diag            OUT pk_types.cursor_type,
        o_impressions     OUT pk_types.cursor_type,
        o_evaluation      OUT pk_types.cursor_type,
        o_analysis        OUT pk_types.cursor_type,
        o_exam            OUT pk_types.cursor_type,
        o_presc_ext       OUT pk_types.cursor_type,
        o_dietary_ext     OUT pk_types.cursor_type,
        o_manip_ext       OUT pk_types.cursor_type,
        o_presc           OUT pk_types.cursor_type,
        o_interv          OUT pk_types.cursor_type,
        o_monitorization  OUT pk_types.cursor_type,
        o_nurse_act       OUT pk_types.cursor_type,
        o_nurse_teach     OUT pk_types.cursor_type,
        o_referrals       OUT pk_types.cursor_type,
        o_gp_notes        OUT pk_types.cursor_type,
        -- o_intervmfr              OUT pk_types.cursor_type,
        o_doc_area_register      OUT pk_touch_option.t_cur_doc_area_register,
        o_doc_area_val           OUT pk_touch_option.t_cur_doc_area_val,
        o_template_layouts       OUT pk_types.cursor_type,
        o_doc_area_component     OUT pk_types.cursor_type,
        o_cits                   OUT pk_types.cursor_type,
        o_discharge_instructions OUT pk_types.cursor_type,
        o_discharge              OUT pk_types.cursor_type,
        o_surgical_hist          OUT pk_types.cursor_type,
        o_past_hist_ft           OUT pk_types.cursor_type,
        o_surgery_record         OUT pk_types.cursor_type,
        o_risk_factors           OUT pk_types.cursor_type,
        o_obstetric_history      OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obtenção dos dados dos episódios anteriores
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                            I_PATIENT - ID do paciente
                            I_PROF - ID do profissional
                            ...
                        Saida: O_ERROR - Erro
        
          CRIAÇÃO: ASM 2007/05/23
          NOTAS: Dados de retorno semelhantes aos do GET_SUMMARY_S, GET_SUMMARY_O, etc
        *********************************************************************************/
        l_func_name CONSTANT VARCHAR2(17 CHAR) := 'GET_PREV_EPIS_DET';
    
        o_doc_areas   pk_types.cursor_type;
        l_therapeutic pk_types.cursor_type;
        l_plan        pk_types.cursor_type;
        l_error       t_error_out;
    
        l_coll_epis_doc      table_number;
        l_coll_epis_anamn    table_number;
        l_coll_epis_rev_sys  table_number;
        l_coll_epis_obs      table_number;
        l_coll_epis_past_fsh table_number;
        l_coll_epis_recomend table_number;
    
        l_coll_epis_doc_all      table_number := table_number();
        l_coll_epis_anamn_all    table_number := table_number();
        l_coll_epis_rev_sys_all  table_number := table_number();
        l_coll_epis_obs_all      table_number := table_number();
        l_coll_epis_past_fsh_all table_number := table_number();
        l_coll_epis_recomend_all table_number := table_number();
        l_record_count           PLS_INTEGER;
        l_doc_area_obs_exam      doc_area.id_doc_area%TYPE;
    
        l_cits_descs     table_varchar := table_varchar();
        l_cits_title     table_varchar := table_varchar();
        l_cits_signature table_varchar := table_varchar();
    
        l_sm_restrict_for_activity sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                           'DISCHARGE_NOTES_M023');
        l_sm_discharge_instruction sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                           'DISCHARGE_NOTES_T035');
        -- Discharge reason and destination
        l_disch_reason      translation.desc_lang_2%TYPE;
        l_disch_destination translation.desc_lang_2%TYPE;
    
        l_id_epis_software     software.id_software%TYPE;
        l_show_all_scores      VARCHAR2(1) := pk_alert_constant.g_yes;
        l_disch_signature      VARCHAR2(4000);
        l_ehr_epis_summary     sys_config.value%TYPE;
        l_epis_type_operating  epis_type.id_epis_type%TYPE := NULL;
        l_all_epis_type_v      table_varchar := table_varchar();
        l_all_epis_type_n      table_number := table_number();
        l_brief_surgery_record pk_types.cursor_type;
        l_tbl_doc_area         table_number := table_number(g_area_history,
                                                            pk_clinical_info.g_doc_area_rev_sys,
                                                            pk_summary_page.g_doc_area_phy_exam,
                                                            pk_summary_page.g_doc_area_assessment,
                                                            pk_summary_page.g_doc_area_past_fam,
                                                            pk_summary_page.g_doc_area_past_soc);
    
        l_tbl_doc_area_hhc table_number := table_number(pk_summary_page.g_doc_area_perm_incap,
                                                        pk_summary_page.g_doc_area_act_daily_s,
                                                        pk_summary_page.g_doc_area_eval_relat_fam,
                                                        pk_summary_page.g_doc_area_instructions,
                                                        pk_summary_page.g_doc_area_disch_notes,
                                                        pk_summary_page.g_doc_area_past_surg,
                                                        pk_summary_page.g_doc_area_mental_hist,
                                                        pk_summary_page.g_doc_area_ped_nutrit,
                                                        pk_summary_page.g_doc_area_past_psy_hist,
                                                        pk_summary_page.g_doc_area_personal_hist,
                                                        pk_summary_page.g_doc_area_occup_hist,
                                                        pk_summary_page.g_doc_area_foren_hist,
                                                        pk_summary_page.g_doc_area_gener_ped_ass,
                                                        pk_summary_page.g_doc_area_develop_ass,
                                                        pk_summary_page.g_doc_area_past_fam,
                                                        pk_summary_page.g_doc_area_past_soc,
                                                        pk_summary_page.g_doc_area_gyn_hist,
                                                        pk_summary_page.g_doc_area_obs_hist,
                                                        pk_summary_page.g_doc_area_cong_anom,
                                                        pk_summary_page.g_doc_area_relev_notes,
                                                        pk_summary_page.g_doc_area_ped_nutrit,
                                                        pk_summary_page.g_doc_area_gener_ped_ass,
                                                        pk_summary_page.g_doc_area_develop_ass);
        l_tbl_aux_doc_area table_number := table_number();
        l_id_epis_type     episode.id_epis_type%TYPE;
        l_doc_area_val_obs pk_types.cursor_type;
    BEGIN
    
        pk_types.open_my_cursor(o_complaint);
        pk_types.open_my_cursor(o_allergy);
        pk_types.open_my_cursor(o_habit);
        pk_types.open_my_cursor(o_relev_disease);
        pk_types.open_my_cursor(o_relev_notes);
        pk_types.open_my_cursor(o_medication);
        pk_types.open_my_cursor(o_home_med_review);
        pk_types.open_my_cursor(o_pat_take);
        pk_types.open_my_cursor(o_vital_sign);
        pk_types.open_my_cursor(o_biometric);
        pk_types.open_my_cursor(o_blood_group);
        pk_types.open_my_cursor(o_info7);
        pk_types.open_my_cursor(o_doc_areas);
        pk_types.open_my_cursor(o_problems);
        pk_types.open_my_cursor(o_ass_scales);
        pk_types.open_my_cursor(o_body_diags);
        pk_types.open_my_cursor(o_diag);
        pk_types.open_my_cursor(o_impressions);
        pk_types.open_my_cursor(o_evaluation);
        pk_types.open_my_cursor(o_analysis);
        pk_types.open_my_cursor(o_exam);
        pk_types.open_my_cursor(o_presc_ext);
        pk_types.open_my_cursor(o_dietary_ext);
        pk_types.open_my_cursor(o_manip_ext);
        pk_types.open_my_cursor(o_presc);
        pk_types.open_my_cursor(o_interv);
        pk_types.open_my_cursor(o_monitorization);
        pk_types.open_my_cursor(o_nurse_act);
        pk_types.open_my_cursor(o_nurse_teach);
        pk_types.open_my_cursor(o_referrals);
        pk_types.open_my_cursor(o_gp_notes);
        --pk_types.open_my_cursor(o_intervmfr);
        pk_types.open_my_cursor(o_cits);
        pk_types.open_my_cursor(o_discharge_instructions);
        pk_types.open_my_cursor(o_discharge);
        pk_types.open_my_cursor(o_surgical_hist);
        pk_types.open_my_cursor(o_past_hist_ft);
        pk_types.open_my_cursor(o_surgery_record);
        pk_types.open_my_cursor(o_risk_factors);
        --get epis type
        IF NOT pk_episode.get_epis_type(i_lang      => i_lang,
                                        i_id_epis   => i_episode(1),
                                        o_epis_type => l_id_epis_type,
                                        o_error     => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        -- get episode software
        g_error := 'CALL get_episode_software';
        pk_alertlog.log_info(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        IF NOT pk_episode.get_episode_software(i_lang        => i_lang,
                                               i_prof        => i_prof,
                                               i_id_episode  => i_episode(1),
                                               o_id_software => l_id_epis_software,
                                               o_error       => l_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF l_id_epis_software IN (pk_alert_constant.g_soft_inpatient, pk_alert_constant.g_soft_oris)
        THEN
            l_show_all_scores := pk_alert_constant.g_no;
        END IF;
    
        g_error := 'CALL get_summary_internal';
        pk_alertlog.log_info(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        IF NOT get_summary_internal(i_lang            => i_lang,
                                    i_pat             => i_patient,
                                    i_epis            => i_episode,
                                    i_prof            => i_prof,
                                    o_complaint       => o_complaint,
                                    o_relev_disease   => o_relev_disease,
                                    o_relev_notes     => o_relev_notes,
                                    o_medication      => o_medication,
                                    o_home_med_review => o_home_med_review,
                                    o_pat_take        => o_pat_take,
                                    o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL get_allergies';
        pk_alertlog.log_info(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        IF NOT pk_allergy.get_allergies(i_lang    => i_lang,
                                        i_prof    => i_prof,
                                        i_episode => i_episode,
                                        i_patient => i_patient,
                                        o_allergy => o_allergy,
                                        o_error   => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL pk_patient.get_habits';
        pk_alertlog.log_info(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        IF NOT pk_patient.get_habits(i_lang  => i_lang,
                                     i_prof  => i_prof,
                                     i_epis  => i_episode,
                                     o_habit => o_habit,
                                     o_error => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL get_summary_o_internal';
        pk_alertlog.log_info(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        IF NOT get_summary_o_internal(i_lang        => i_lang,
                                      i_pat         => i_patient,
                                      i_epis        => i_episode,
                                      i_prof        => i_prof,
                                      o_vital_sign  => o_vital_sign,
                                      o_biometric   => o_biometric,
                                      o_blood_group => o_blood_group,
                                      o_info7       => o_info7,
                                      o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL pk_episode.get_summary_a';
        pk_alertlog.log_info(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        IF NOT pk_episode.get_summary_a(i_lang        => i_lang,
                                        i_pat         => i_patient,
                                        i_epis        => i_episode,
                                        i_prof        => i_prof,
                                        i_prev_visits => l_show_all_scores,
                                        o_problems    => o_problems,
                                        o_ass_scales  => o_ass_scales,
                                        o_body_diags  => o_body_diags,
                                        o_diag        => o_diag,
                                        o_impressions => o_impressions,
                                        o_evaluation  => o_evaluation,
                                        o_error       => l_error)
        THEN
        
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL pk_episode.get_summary_p';
        pk_alertlog.log_info(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        IF NOT pk_episode.get_summary_p(i_lang           => i_lang,
                                        i_pat            => i_patient,
                                        i_epis           => i_episode,
                                        i_prof           => i_prof,
                                        o_analysis       => o_analysis,
                                        o_exam           => o_exam,
                                        o_presc_ext      => o_presc_ext,
                                        o_dietary_ext    => o_dietary_ext,
                                        o_manip_ext      => o_manip_ext,
                                        o_presc          => o_presc,
                                        o_interv         => o_interv,
                                        o_monitorization => o_monitorization,
                                        o_nurse_act      => o_nurse_act,
                                        o_nurse_teach    => o_nurse_teach,
                                        o_plan           => l_plan,
                                        --o_physiatry            => o_intervmfr,
                                        o_therapeutic_decision => l_therapeutic,
                                        o_referrals            => o_referrals,
                                        o_gp_notes             => o_gp_notes,
                                        o_error                => l_error)
        THEN
        
            RAISE g_exception;
        
        END IF;
    
        IF i_prof.software = pk_alert_constant.g_soft_home_care
        THEN
            l_tbl_aux_doc_area := l_tbl_doc_area_hhc;
        ELSE
            l_tbl_aux_doc_area := l_tbl_doc_area;
        END IF;
        --HPI 
        g_error := 'CALL pk_touch_option.get_doc_area_value_ids function HPI.';
        pk_alertlog.log_info(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        IF NOT pk_touch_option.get_doc_area_value_ids(i_lang               => i_lang,
                                                      i_prof               => i_prof,
                                                      i_doc_area           => l_tbl_aux_doc_area, -- table_number(g_area_history),
                                                      i_scope              => i_episode,
                                                      i_scope_type         => pk_alert_constant.g_scope_type_episode,
                                                      i_fltr_status        => pk_touch_option.g_active,
                                                      o_record_count       => l_record_count,
                                                      o_coll_epis_doc      => l_coll_epis_doc,
                                                      o_coll_epis_anamn    => l_coll_epis_anamn,
                                                      o_coll_epis_rev_sys  => l_coll_epis_rev_sys,
                                                      o_coll_epis_obs      => l_coll_epis_obs,
                                                      o_coll_epis_past_fsh => l_coll_epis_past_fsh,
                                                      o_coll_epis_recomend => l_coll_epis_recomend,
                                                      o_error              => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        l_coll_epis_doc_all      := l_coll_epis_doc;
        l_coll_epis_anamn_all    := l_coll_epis_anamn;
        l_coll_epis_rev_sys_all  := l_coll_epis_rev_sys;
        l_coll_epis_obs_all      := l_coll_epis_obs;
        l_coll_epis_past_fsh_all := l_coll_epis_past_fsh;
        l_coll_epis_recomend_all := l_coll_epis_recomend;
        /*
        --Revisão de sistemas
        g_error := 'CALL pk_touch_option.get_doc_area_value_ids function RoS.';
        pk_alertlog.log_info(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        IF NOT pk_touch_option.get_doc_area_value_ids(i_lang               => i_lang,
                                                      i_prof               => i_prof,
                                                          i_doc_area           => table_number(pk_clinical_info.g_doc_area_rev_sys),
                                                      i_scope              => i_episode,
                                                      i_scope_type         => pk_alert_constant.g_scope_type_episode,
                                                      i_fltr_status        => pk_touch_option.g_active,
                                                      o_record_count       => l_record_count,
                                                      o_coll_epis_doc      => l_coll_epis_doc,
                                                      o_coll_epis_anamn    => l_coll_epis_anamn,
                                                      o_coll_epis_rev_sys  => l_coll_epis_rev_sys,
                                                      o_coll_epis_obs      => l_coll_epis_obs,
                                                      o_coll_epis_past_fsh => l_coll_epis_past_fsh,
                                                      o_coll_epis_recomend => l_coll_epis_recomend,
                                                      o_error              => o_error)
        THEN
            RAISE g_exception;
        END IF;
        
        l_coll_epis_doc_all      := l_coll_epis_doc_all MULTISET UNION l_coll_epis_doc;
        l_coll_epis_anamn_all    := l_coll_epis_anamn_all MULTISET UNION l_coll_epis_anamn;
        l_coll_epis_rev_sys_all  := l_coll_epis_rev_sys_all MULTISET UNION l_coll_epis_rev_sys;
        l_coll_epis_obs_all      := l_coll_epis_obs_all MULTISET UNION l_coll_epis_obs;
        l_coll_epis_past_fsh_all := l_coll_epis_past_fsh_all MULTISET UNION l_coll_epis_past_fsh;
        l_coll_epis_recomend_all := l_coll_epis_recomend_all MULTISET UNION l_coll_epis_recomend;
        
        --Physical exam
        g_error := 'CALL pk_touch_option.get_doc_area_value_ids function Physical Exam.';
        pk_alertlog.log_info(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        IF NOT pk_touch_option.get_doc_area_value_ids(i_lang               => i_lang,
                                                      i_prof               => i_prof,
                                                          i_doc_area           => table_number(pk_summary_page.g_doc_area_phy_exam),
                                                      i_scope              => i_episode,
                                                      i_scope_type         => pk_alert_constant.g_scope_type_episode,
                                                      i_fltr_status        => pk_touch_option.g_active,
                                                      o_record_count       => l_record_count,
                                                      o_coll_epis_doc      => l_coll_epis_doc,
                                                      o_coll_epis_anamn    => l_coll_epis_anamn,
                                                      o_coll_epis_rev_sys  => l_coll_epis_rev_sys,
                                                      o_coll_epis_obs      => l_coll_epis_obs,
                                                      o_coll_epis_past_fsh => l_coll_epis_past_fsh,
                                                      o_coll_epis_recomend => l_coll_epis_recomend,
                                                      o_error              => o_error)
        THEN
            RAISE g_exception;
        END IF;
        
        l_coll_epis_doc_all      := l_coll_epis_doc_all MULTISET UNION l_coll_epis_doc;
        l_coll_epis_anamn_all    := l_coll_epis_anamn_all MULTISET UNION l_coll_epis_anamn;
        l_coll_epis_rev_sys_all  := l_coll_epis_rev_sys_all MULTISET UNION l_coll_epis_rev_sys;
        l_coll_epis_obs_all      := l_coll_epis_obs_all MULTISET UNION l_coll_epis_obs;
        l_coll_epis_past_fsh_all := l_coll_epis_past_fsh_all MULTISET UNION l_coll_epis_past_fsh;
        l_coll_epis_recomend_all := l_coll_epis_recomend_all MULTISET UNION l_coll_epis_recomend;
        
        --Family hx
        g_error := 'CALL pk_touch_option.get_doc_area_value_ids function Family hx.';
        pk_alertlog.log_info(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        IF NOT pk_touch_option.get_doc_area_value_ids(i_lang               => i_lang,
                                                      i_prof               => i_prof,
                                                          i_doc_area           => table_number(pk_summary_page.g_doc_area_past_fam),
                                                      i_scope              => i_episode,
                                                      i_scope_type         => pk_alert_constant.g_scope_type_episode,
                                                      i_fltr_status        => pk_touch_option.g_active,
                                                      o_record_count       => l_record_count,
                                                      o_coll_epis_doc      => l_coll_epis_doc,
                                                      o_coll_epis_anamn    => l_coll_epis_anamn,
                                                      o_coll_epis_rev_sys  => l_coll_epis_rev_sys,
                                                      o_coll_epis_obs      => l_coll_epis_obs,
                                                      o_coll_epis_past_fsh => l_coll_epis_past_fsh,
                                                      o_coll_epis_recomend => l_coll_epis_recomend,
                                                      o_error              => o_error)
        THEN
            RAISE g_exception;
        END IF;
        
        l_coll_epis_doc_all      := l_coll_epis_doc_all MULTISET UNION l_coll_epis_doc;
        l_coll_epis_anamn_all    := l_coll_epis_anamn_all MULTISET UNION l_coll_epis_anamn;
        l_coll_epis_rev_sys_all  := l_coll_epis_rev_sys_all MULTISET UNION l_coll_epis_rev_sys;
        l_coll_epis_obs_all      := l_coll_epis_obs_all MULTISET UNION l_coll_epis_obs;
        l_coll_epis_past_fsh_all := l_coll_epis_past_fsh_all MULTISET UNION l_coll_epis_past_fsh;
        l_coll_epis_recomend_all := l_coll_epis_recomend_all MULTISET UNION l_coll_epis_recomend;
        
        --Social hx
        g_error := 'CALL pk_touch_option.get_doc_area_value_ids function Social hx.';
        pk_alertlog.log_info(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        IF NOT pk_touch_option.get_doc_area_value_ids(i_lang               => i_lang,
                                                      i_prof               => i_prof,
                                                      i_doc_area           => table_number(pk_summary_page.g_doc_area_past_soc),
                                                      i_scope              => i_episode,
                                                      i_scope_type         => pk_alert_constant.g_scope_type_episode,
                                                      i_fltr_status        => pk_touch_option.g_active,
                                                      o_record_count       => l_record_count,
                                                      o_coll_epis_doc      => l_coll_epis_doc,
                                                      o_coll_epis_anamn    => l_coll_epis_anamn,
                                                      o_coll_epis_rev_sys  => l_coll_epis_rev_sys,
                                                      o_coll_epis_obs      => l_coll_epis_obs,
                                                      o_coll_epis_past_fsh => l_coll_epis_past_fsh,
                                                      o_coll_epis_recomend => l_coll_epis_recomend,
                                                      o_error              => o_error)
        THEN
            RAISE g_exception;
        END IF;
        
        l_coll_epis_doc_all      := l_coll_epis_doc_all MULTISET UNION l_coll_epis_doc;
        l_coll_epis_anamn_all    := l_coll_epis_anamn_all MULTISET UNION l_coll_epis_anamn;
        l_coll_epis_rev_sys_all  := l_coll_epis_rev_sys_all MULTISET UNION l_coll_epis_rev_sys;
        l_coll_epis_obs_all      := l_coll_epis_obs_all MULTISET UNION l_coll_epis_obs;
        l_coll_epis_past_fsh_all := l_coll_epis_past_fsh_all MULTISET UNION l_coll_epis_past_fsh;
        l_coll_epis_recomend_all := l_coll_epis_recomend_all MULTISET UNION l_coll_epis_recomend;
        */
        l_coll_epis_doc     := pk_past_history.get_past_hist_ids_review(i_lang        => i_lang,
                                                                        i_prof        => i_prof,
                                                                        i_episode     => i_episode,
                                                                        i_flg_context => pk_review.get_template_context,
                                                                        i_flg_area    => table_varchar(),
                                                                        i_doc_area    => pk_summary_page.g_doc_area_past_soc);
        l_coll_epis_doc_all := l_coll_epis_doc_all MULTISET UNION l_coll_epis_doc;
    
        l_coll_epis_doc     := pk_past_history.get_past_hist_ids_review(i_lang        => i_lang,
                                                                        i_prof        => i_prof,
                                                                        i_episode     => i_episode,
                                                                        i_flg_context => pk_review.get_template_context,
                                                                        i_flg_area    => table_varchar(),
                                                                        i_doc_area    => pk_summary_page.g_doc_area_past_fam);
        l_coll_epis_doc_all := l_coll_epis_doc_all MULTISET UNION l_coll_epis_doc;
    
        g_error := 'CALL pk_touch_option.get_doc_area_value_internal';
        pk_alertlog.log_info(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        IF NOT pk_touch_option.get_doc_area_value_internal(i_lang               => i_lang,
                                                           i_prof               => i_prof,
                                                           i_id_episode         => i_episode(1),
                                                           i_id_patient         => i_patient,
                                                           i_doc_area           => NULL,
                                                           i_epis_doc           => l_coll_epis_doc_all,
                                                           i_epis_anamn         => l_coll_epis_anamn_all,
                                                           i_epis_rev_sys       => l_coll_epis_rev_sys_all,
                                                           i_epis_obs           => l_coll_epis_obs_all,
                                                           i_epis_past_fsh      => l_coll_epis_past_fsh_all,
                                                           i_epis_recomend      => l_coll_epis_recomend_all,
                                                           o_doc_area_register  => o_doc_area_register,
                                                           o_doc_area_val       => o_doc_area_val,
                                                           o_template_layouts   => o_template_layouts,
                                                           o_doc_area_component => o_doc_area_component,
                                                           o_error              => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL pk_cit.get_cits_by_patient. i_patient: ' || i_patient;
        pk_alertlog.log_info(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        IF NOT pk_cit.get_cits_by_patient(i_lang            => i_lang,
                                          i_prof            => i_prof,
                                          i_id_patient      => i_patient,
                                          i_id_episode      => i_episode(1),
                                          i_excluded_status => table_varchar(pk_cit.g_flg_status_canceled,
                                                                             pk_cit.g_flg_status_concluded,
                                                                             pk_cit.g_flg_status_expired),
                                          o_cit_desc        => l_cits_descs,
                                          o_cit_title       => l_cits_title,
                                          o_signature       => l_cits_signature,
                                          o_error           => l_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'Open o_cits';
        pk_alertlog.log_info(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        OPEN o_cits FOR
            SELECT tdesc.column_value desc_info, ttitle.column_value desc_title, ttsignature.column_value signature
              FROM (SELECT rownum rnum, column_value
                      FROM TABLE(l_cits_descs)) tdesc
              JOIN (SELECT rownum rnum, column_value
                      FROM TABLE(l_cits_title)) ttitle
                ON tdesc.rnum = ttitle.rnum
              JOIN (SELECT rownum rnum, column_value
                      FROM TABLE(l_cits_signature)) ttsignature
                ON tdesc.rnum = ttsignature.rnum;
    
        -- Discharge info
        g_error := 'CALL pk_discharge.get_epis_disch_rea_dest_desc. i_episode: ' || i_episode(1);
        pk_alertlog.log_info(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        IF NOT pk_discharge.get_epis_disch_rea_dest_desc(i_lang        => i_lang,
                                                         i_prof        => i_prof,
                                                         i_episode     => i_episode(1),
                                                         o_reason      => l_disch_reason,
                                                         o_destination => l_disch_destination,
                                                         o_signature   => l_disch_signature,
                                                         o_error       => l_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF l_disch_reason IS NOT NULL
           OR l_disch_destination IS NOT NULL
        THEN
            g_error := 'Open o_discharge';
            pk_alertlog.log_info(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
            OPEN o_discharge FOR
                SELECT nvl2(l_disch_reason, l_disch_reason || ': ', '') || l_disch_destination AS desc_info,
                       pk_message.get_message(i_lang      => i_lang,
                                              i_prof      => profissional(NULL, i_prof.institution, l_id_epis_software),
                                              i_code_mess => 'SUMMARY_M041') AS desc_title,
                       l_disch_signature signature
                  FROM dual;
        END IF;
    
        g_error := 'Open o_discharge';
        pk_alertlog.log_info(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        OPEN o_discharge_instructions FOR
            SELECT CASE
                        WHEN t.notes_release IS NOT NULL
                             AND dbms_lob.compare(t.discharge_instructions, empty_clob()) <> 0 THEN
                         l_sm_restrict_for_activity || chr(10) || t.notes_release || chr(10) ||
                         l_sm_discharge_instruction || chr(10) || t.discharge_instructions
                        WHEN t.notes_release IS NULL
                             AND dbms_lob.compare(t.discharge_instructions, empty_clob()) <> 0 THEN
                         l_sm_discharge_instruction || chr(10) || t.discharge_instructions
                        WHEN t.notes_release IS NOT NULL
                             AND dbms_lob.compare(t.discharge_instructions, empty_clob()) = 0 THEN
                         to_clob(l_sm_restrict_for_activity || chr(10) || t.notes_release)
                    END desc_info,
                   t.id_episode,
                   t.signature
              FROM TABLE(pk_discharge.tf_discharge_notes(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode)) t
             WHERE t.notes_release IS NOT NULL
                OR dbms_lob.compare(t.discharge_instructions, empty_clob()) <> 0;
    
        -- past surgical history
        IF NOT pk_past_history.get_past_history_info(i_lang         => i_lang,
                                                     i_prof         => i_prof,
                                                     i_epis         => i_episode,
                                                     i_pat          => i_patient,
                                                     i_flg_type     => pk_past_history.g_alert_diag_type_surg,
                                                     i_doc_area     => pk_past_history.g_doc_area_past_surg,
                                                     o_past_history => o_surgical_hist,
                                                     o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        IF NOT pk_past_history.get_past_history_info(i_lang         => i_lang,
                                                     i_prof         => i_prof,
                                                     i_epis         => i_episode,
                                                     i_pat          => i_patient,
                                                     i_flg_type     => NULL,
                                                     i_doc_area     => NULL,
                                                     i_flg_ft       => 'FT',
                                                     o_past_history => o_past_hist_ft,
                                                     o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        IF NOT pk_sr_surg_record.get_surgery_record_det(i_lang           => i_lang,
                                                        i_prof           => i_prof,
                                                        i_epis           => i_episode(1),
                                                        i_patient        => i_patient,
                                                        o_surgery_record => o_surgery_record,
                                                        o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
        IF NOT pk_risk_factor.get_epis_risk_factors(i_lang         => i_lang,
                                                    i_prof         => i_prof,
                                                    i_episode      => i_episode(1),
                                                    o_risk_factors => o_risk_factors,
                                                    o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        -- Obstetric history
        g_error := 'CALL TO pk_pregnancy.get_summ_page_doc_area_pregn';
        IF NOT pk_pregnancy.get_summ_page_doc_area_pregn(i_lang              => i_lang,
                                                         i_prof              => i_prof,
                                                         i_episode           => i_episode(1),
                                                         i_pat               => i_patient,
                                                         i_doc_area          => pk_summary_page.g_doc_area_obs_hist,
                                                         o_doc_area_register => o_obstetric_history,
                                                         o_doc_area_val      => l_doc_area_val_obs,
                                                         o_error             => o_error)
        THEN
            RAISE g_exception;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(o_complaint);
            pk_types.open_my_cursor(o_allergy);
            pk_types.open_my_cursor(o_habit);
            pk_types.open_my_cursor(o_relev_disease);
            pk_types.open_my_cursor(o_relev_notes);
            pk_types.open_my_cursor(o_medication);
            pk_types.open_my_cursor(o_home_med_review);
            pk_types.open_my_cursor(o_pat_take);
            pk_types.open_my_cursor(o_vital_sign);
            pk_types.open_my_cursor(o_biometric);
            pk_types.open_my_cursor(o_blood_group);
            pk_types.open_my_cursor(o_info7);
            pk_types.open_my_cursor(o_problems);
            pk_types.open_my_cursor(o_ass_scales);
            pk_types.open_my_cursor(o_body_diags);
            pk_types.open_my_cursor(o_diag);
            pk_types.open_my_cursor(o_evaluation);
            pk_types.open_my_cursor(o_analysis);
            pk_types.open_my_cursor(o_exam);
            pk_types.open_my_cursor(o_presc_ext);
            pk_types.open_my_cursor(o_dietary_ext);
            pk_types.open_my_cursor(o_manip_ext);
            pk_types.open_my_cursor(o_presc);
            pk_types.open_my_cursor(o_interv);
            pk_types.open_my_cursor(o_monitorization);
            pk_types.open_my_cursor(o_nurse_act);
            pk_types.open_my_cursor(o_nurse_teach);
            -- pk_types.open_my_cursor(o_intervmfr);
            pk_types.open_my_cursor(o_referrals);
            pk_types.open_my_cursor(o_gp_notes);
            pk_touch_option.open_cur_doc_area_register(o_doc_area_register);
            pk_touch_option.open_cur_doc_area_val(o_doc_area_val);
            pk_types.open_my_cursor(o_template_layouts);
            pk_types.open_my_cursor(o_doc_area_component);
            pk_types.open_my_cursor(o_cits);
            pk_types.open_my_cursor(o_discharge_instructions);
            pk_types.open_my_cursor(o_discharge);
            pk_types.open_my_cursor(o_surgical_hist);
            pk_types.open_my_cursor(o_past_hist_ft);
            pk_types.open_my_cursor(o_surgery_record);
            pk_types.open_my_cursor(o_risk_factors);
        
            o_error := l_error;
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_complaint);
                pk_types.open_my_cursor(o_allergy);
                pk_types.open_my_cursor(o_habit);
                pk_types.open_my_cursor(o_relev_disease);
                pk_types.open_my_cursor(o_relev_notes);
                pk_types.open_my_cursor(o_medication);
                pk_types.open_my_cursor(o_home_med_review);
                pk_types.open_my_cursor(o_pat_take);
                pk_types.open_my_cursor(o_vital_sign);
                pk_types.open_my_cursor(o_biometric);
                pk_types.open_my_cursor(o_blood_group);
                pk_types.open_my_cursor(o_info7);
                pk_types.open_my_cursor(o_problems);
                pk_types.open_my_cursor(o_ass_scales);
                pk_types.open_my_cursor(o_body_diags);
                pk_types.open_my_cursor(o_diag);
                pk_types.open_my_cursor(o_evaluation);
                pk_types.open_my_cursor(o_analysis);
                pk_types.open_my_cursor(o_exam);
                pk_types.open_my_cursor(o_presc_ext);
                pk_types.open_my_cursor(o_dietary_ext);
                pk_types.open_my_cursor(o_manip_ext);
                pk_types.open_my_cursor(o_presc);
                pk_types.open_my_cursor(o_interv);
                pk_types.open_my_cursor(o_monitorization);
                pk_types.open_my_cursor(o_nurse_act);
                pk_types.open_my_cursor(o_nurse_teach);
                --pk_types.open_my_cursor(o_intervmfr);
                pk_types.open_my_cursor(o_referrals);
                pk_types.open_my_cursor(o_gp_notes);
                pk_touch_option.open_cur_doc_area_register(o_doc_area_register);
                pk_touch_option.open_cur_doc_area_val(o_doc_area_val);
                pk_types.open_my_cursor(o_template_layouts);
                pk_types.open_my_cursor(o_doc_area_component);
                pk_types.open_my_cursor(o_cits);
                pk_types.open_my_cursor(o_discharge_instructions);
                pk_types.open_my_cursor(o_discharge);
                pk_types.open_my_cursor(o_surgical_hist);
                pk_types.open_my_cursor(o_past_hist_ft);
                pk_types.open_my_cursor(o_surgery_record);
                pk_types.open_my_cursor(o_risk_factors);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_owner_name, g_pck_name, 'GET_PREV_EPIS_DET');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN l_ret;
            END;
        
    END;

    /******************************************************************************
    * Returns the status of an episode.
    *
    * @param i_lang            Professional preferred language
    * @param i_prof            Professional information
    * @param i_id_episode      Episode ID
    * @param o_flg_status      Status of the episode
    * @param o_error           Error message
    *
    * @return                  TRUE if succeeded, FALSE otherwise
    *
    * @author                  Jos?Brito
    * @version                 0.1
    * @since                   2008-Apr-17
    *
    ******************************************************************************/
    FUNCTION get_flg_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_flg_status OUT episode.flg_status%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET FLG_STATUS';
        SELECT e.flg_status
          INTO o_flg_status
          FROM episode e
         WHERE e.id_episode = i_id_episode;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_owner_name, g_pck_name, 'GET_FLG_STATUS');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN l_ret;
            END;
        
    END get_flg_status;
    --
    --
    /******************************************************************************
    * Checks if an episode is temporary or definitive.
    *
    * @param i_lang            Professional preferred language
    * @param i_prof            Professional information
    * @param i_id_episode      Episode ID
    * @param o_flg_unknown     Type of the episode
    * @param o_error           Error message
    *
    * @return                  TRUE if succeeded, FALSE otherwise
    *
    * @author                  Jos?Brito
    * @version                 0.1
    * @since                   2008-Apr-17
    *
    ******************************************************************************/
    FUNCTION get_flg_unknown
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        o_flg_unknown OUT episode.flg_status%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET FLG_UNKNOWN';
        SELECT ei.flg_unknown
          INTO o_flg_unknown
          FROM epis_info ei
         WHERE ei.id_episode = i_id_episode;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_owner_name, g_pck_name, 'GET_FLG_UNKNOWN');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN l_ret;
            END;
        
    END get_flg_unknown;

    /**
    * Procedimento para actualizar as mviews
    * mv_episode_act e mv_episode_act_pend
    *
    * @author João Eiras, 30-07-2007
    */

    PROCEDURE update_mv_episodes_create_job IS
    
    BEGIN
    
        NULL;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_alertlog.log_fatal('MV_EPISODE: Scheduling refresh of mv_episode* failed' || chr(10) || SQLERRM,
                                  'MV_EPISODE');
            NULL;
    END update_mv_episodes_create_job;

    /**
    * Procedimento para actualizar as mviews
    * mv_episode_act e mv_episode_act_pend por forma a poder utilizar os procedimentos update_mv_episodes
    * ou update_mv_episodes_no_timeout consoante o valor da sys_config REFRESH_MVIEWS_WITH_NO_TIMEOUT_PROCEDURE 
    * 
    * Solução temporária para resolver os problemas de efectivação dos softwares de ambulatório
    *
    * @author Sérgio Santos, 12-05-2009
    */

    PROCEDURE update_mv_episodes_temp
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) IS
    
    BEGIN
        g_error := 'GET TIMEOUT CONFIG';
    
        NULL;
    
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END update_mv_episodes_temp;

    /**
    * Procedimento para actualizar as mviews
    * mv_episode_act e mv_episode_act_pend
    *
    * @author João Eiras, 30-07-2007
    */

    PROCEDURE update_mv_episodes IS
    BEGIN
    
        g_error := 'GET JOB';
    
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END update_mv_episodes;

    /************************************************************************************************************
    * This function returns the visit id associated to a episode
    *
    * @param      i_episode         Episode Id
    *
    * @return     Visit Id
    *
    * @author     Paulo Fonseca
    * @version    2.5
    * @since      2009/10/13
    ************************************************************************************************************/
    FUNCTION get_id_visit(i_episode IN episode.id_episode%TYPE) RETURN episode.id_visit%TYPE IS
        l_id_visit episode.id_visit%TYPE;
    BEGIN
        SELECT id_visit
          INTO l_id_visit
          FROM episode
         WHERE id_episode = i_episode;
    
        RETURN l_id_visit;
    END;

    /**
    * Returns the visit ID associated to an episode.
    * This function can be invoked by Flash
    *
    * @param i_lang         Language ID
    * @param i_prof         Current profissional
    * @param i_episode      Episode ID
    *
    * @param o_error        Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.1
    * @since   07-Apr-10
    */
    FUNCTION get_id_visit
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_visit   OUT visit.id_visit%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        o_visit := get_id_visit(i_episode => i_episode);
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_owner_name, g_pck_name, 'get_id_visit');
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
    END get_id_visit;

    /********************************************************************************************
    * Returns id_patient associated to episode
    *                                                                                                                                          
    * @param i_episode                Episode ID                                                                                              
    * @return                         Patient ID                                                        
    *                                                                                                                          
    * @author                         Ariel Geraldo Machado                                                                                    
    * @version                         1.0 (2.4.4)                                                                                                     
    * @since                          2008/10/06                                                                                               
    ********************************************************************************************/
    FUNCTION get_id_patient(i_episode IN episode.id_episode%TYPE) RETURN patient.id_patient%TYPE IS
        l_ret patient.id_patient%TYPE;
    BEGIN
        SELECT v.id_patient
          INTO l_ret
          FROM visit v
         INNER JOIN episode e
            ON v.id_visit = e.id_visit
         WHERE e.id_episode = i_episode;
    
        RETURN l_ret;
    END;

    /********************************************************************************************
    * This function returns the id_software associated to a type of episode in an institution
    *                                                                                                                                          
    * @param i_epis_type              Type of episode
    * @param i_institution            Institution ID                                                                                              
    * @return                         Software ID                                                        
    *                                                                                                                          
    * @author                         Ariel Geraldo Machado                                                                                    
    * @version                         1.0 (2.4.4)                                                                                                     
    * @since                          2008/11/10                                                                                               
    ********************************************************************************************/
    FUNCTION get_soft_by_epis_type
    (
        i_epis_type   IN epis_type_soft_inst.id_epis_type%TYPE,
        i_institution IN epis_type_soft_inst.id_institution%TYPE
        
    ) RETURN epis_type_soft_inst.id_software%TYPE IS
    
        l_soft epis_type_soft_inst.id_software%TYPE;
    
        CURSOR c_epis_type_soft_inst IS
            SELECT etsi.id_software
              FROM epis_type_soft_inst etsi
             WHERE etsi.id_epis_type = i_epis_type
               AND etsi.id_institution IN (i_institution, 0)
             ORDER BY etsi.id_institution DESC, etsi.id_software DESC;
    BEGIN
    
        OPEN c_epis_type_soft_inst;
        FETCH c_epis_type_soft_inst
            INTO l_soft;
        CLOSE c_epis_type_soft_inst;
    
        RETURN l_soft;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.error_handling('GET_SOFT_BY_EPIS_TYPE', 'PK_EPISODE', g_error, SQLERRM);
            RETURN NULL;
    END;

    /*******************************************************************************************************************************************
    *GET_ORDERED_LIST Return a ordered episodes list                                                                                           *
    *                                                                                                                                          *
    * @param LANG                     Id language                                                                                              *
    * @param I_PROF                   Profissiona, institution and software identifiers                                                        *
    * @param I_EPISODE                Episode identifier                                                                                       *
    * @param O_COUNT                  Number of records                                                                                        *
    * @param O_FIRST                  First record description                                                                                 *    
    * @param O_CODE                   Code description                                                                                 *    
    * @param O_DATE                   First record date                                                                                        *    
    * @param O_FMT                    Format date indicator                                                                                    *    
    *                                                                                                                                          *
    *                                                                                                                                          *
    * @return                         Return false if any error ocurred and return true otherwise                                              *
    *                                                                                                                                          *
    * @raises                                                                                                                                  *
    *                                                                                                                                          *
    * @author                         Carlos Vieira                                                                                            *
    * @version                         1.0                                                                                                     *
    * @since                          2008/11/17                                                                                               *
    *******************************************************************************************************************************************/

    FUNCTION get_count_and_first
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_count   OUT NUMBER,
        o_first   OUT VARCHAR2,
        o_code    OUT VARCHAR2,
        o_date    OUT VARCHAR2,
        o_fmt     OUT VARCHAR2
        
    ) RETURN BOOLEAN IS
    
        l_fmt VARCHAR2(1) := 'Y';
    
    BEGIN
        BEGIN
            SELECT v.o_code, v.o_count, v.o_date
              INTO o_code, o_count, o_date
              FROM v_viewer_episode_list v
             WHERE v.id_patient = i_patient;
        
        EXCEPTION
            WHEN no_data_found THEN
                o_code  := '';
                o_count := NULL;
                o_date  := '';
        END;
    
        o_fmt   := l_fmt;
        o_first := '';
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(SQLERRM);
            RETURN FALSE;
    END get_count_and_first;

    PROCEDURE upd_viewer_ehr_ea IS
        l_patients table_number;
        l_error    t_error_out;
    
    BEGIN
    
        SELECT id_patient
          BULK COLLECT
          INTO l_patients
          FROM v_viewer_episode_list vee;
    
        IF NOT upd_viewer_ehr_ea_pat(i_lang              => pk_data_gov_admin.g_log_lang,
                                     i_table_id_patients => l_patients,
                                     o_error             => l_error)
        THEN
            RAISE g_exception;
        END IF;
    END upd_viewer_ehr_ea;

    /**********************************************************************************************
    *  This fuction will update the table viewer_ehr_ea for the specified patients.
    *
    * @param I_LANG                   The id language
    * @param I_TABLE_ID_PATIENTS      Table of id patients to be clean.
    * @param O_ERROR                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         ANA COELHO
    * @version                        1.0
    * @since                          27-APR-2011
    **********************************************************************************************/
    FUNCTION upd_viewer_ehr_ea_pat
    (
        i_lang              IN language.id_language%TYPE,
        i_table_id_patients IN table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        UPDATE viewer_ehr_ea vee
           SET (vee.desc_episode, vee.code_episode, vee.num_episode, vee.dt_episode) =
               (SELECT '', o_code, o_count, o_date
                  FROM v_viewer_episode_list epis1
                 WHERE epis1.id_patient IN (SELECT /*+ OPT_ESTIMATE(table pat rows = 1)*/
                                             column_value
                                              FROM TABLE(i_table_id_patients) pat)
                   AND epis1.id_patient = vee.id_patient)
        
         WHERE vee.id_patient IN (SELECT /*+ OPT_ESTIMATE(table pat rows = 1)*/
                                   column_value
                                    FROM TABLE(i_table_id_patients));
    
        -- update episodes + archives   
        IF NOT
            pk_data_gov_admin.update_viewer_epis_archive(i_table_id_patients => i_table_id_patients, o_error => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              'UPDATE VIEWER_EHR_EA',
                                              g_owner_name,
                                              g_pck_name,
                                              'UPD_VIEWER_EHR_EA_PAT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END upd_viewer_ehr_ea_pat;

    /**********************************************************************************************
    * Get episode' clinical service description.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_episode                episode identifier
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author                         Pedro Carneiro
    * @version                         2.5.0.6.2
    * @since                          2009/10/12
    **********************************************************************************************/
    FUNCTION get_cs_desc
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR IS
        l_ret              pk_translation.t_desc_translation;
        l_id_dep_clin_serv dep_clin_serv.id_dep_clin_serv%TYPE;
    BEGIN
        BEGIN
            SELECT nvl(ei.id_dep_clin_serv, s.id_dcs_requested)
              INTO l_id_dep_clin_serv
              FROM epis_info ei
              LEFT JOIN schedule s
                ON (ei.id_schedule = s.id_schedule)
             WHERE ei.id_episode = i_episode;
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        l_ret := pk_hea_prv_aux.get_clin_service(i_lang, i_prof, l_id_dep_clin_serv);
    
        RETURN l_ret;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_cs_desc;

    /**********************************************************************************************
    * Get episode' creation date.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_episode                episode identifier
    * @param o_dt_creation            Episode creation date
    * @param o_error                  Error message
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author                         Sofia Mendes
    * @version                        2.5.0.7
    * @since                          2009/10/23
    **********************************************************************************************/
    FUNCTION get_epis_dt_creation
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        o_dt_creation OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET DT_CREATION with id_episode: ' || i_id_episode;
        SELECT pk_date_utils.get_timestamp_str(i_lang, i_prof, e.dt_creation, NULL)
          INTO o_dt_creation
          FROM episode e
         WHERE id_episode = i_id_episode;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_owner_name, g_pck_name, 'GET_EPIS_DR_CREATION');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN l_ret;
            END;
            RETURN FALSE;
    END get_epis_dt_creation;

    /**********************************************************************************************
    * Check if episode is temporary for match purposes
    *
    * %param i_lang            language identifier
    * %param i_prof            logged professional structure
    * %param i_episode         episode identifier
    * %param o_is_temporary    varchar2 checking if episode is temporary for match matters
    * %param o_error           Error object
    *
    * @return                  false if errors occur, true otherwise
    *
    * @author                  Fábio Oliveira
    * @version                 2.6.0.0
    * @since                   18-Feb-2010
    **********************************************************************************************/
    FUNCTION check_temporary_for_match
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        o_is_temporary OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        e_call_exception EXCEPTION;
        l_flg_unknown epis_info.flg_unknown%TYPE;
    BEGIN
        g_error := 'CHECK FLG_UNKNOWN';
        IF NOT get_flg_unknown(i_lang        => i_lang,
                               i_prof        => i_prof,
                               i_id_episode  => i_episode,
                               o_flg_unknown => l_flg_unknown,
                               o_error       => o_error)
        THEN
            RAISE e_call_exception;
        ELSE
            o_is_temporary := l_flg_unknown;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner_name,
                                              g_pck_name,
                                              'CHECK_TEMPORARY_FOR_MATCH',
                                              o_error);
            RETURN FALSE;
    END check_temporary_for_match;

    /**********************************************************************************************
    * Get episode institution abbreviation.
    *
    * %param i_lang            language identifier
    * %param i_prof            logged professional structure
    * %param i_episode         episode identifier    
    *
    * @return                  Institution abbreviation
    *
    * @author                  Sofia Mendes
    * @version                 2.6.0.3
    * @since                   20-May-2010
    **********************************************************************************************/
    FUNCTION get_epis_institution
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN institution.abbreviation%TYPE IS
    
        l_inst_abbreviation institution.abbreviation%TYPE;
    BEGIN
        g_error := 'GET EPISODE INSTITUTION';
        SELECT ist.abbreviation
          INTO l_inst_abbreviation
          FROM episode epi
          JOIN institution ist
            ON epi.id_institution = ist.id_institution
         WHERE epi.id_episode = i_id_episode;
    
        IF l_inst_abbreviation IS NOT NULL
        THEN
            l_inst_abbreviation := ', ' || l_inst_abbreviation;
        END IF;
    
        RETURN l_inst_abbreviation;
    
    EXCEPTION
        -- if theres no records, no big deal, continue execution
        WHEN no_data_found THEN
            NULL;
    END get_epis_institution;

    FUNCTION get_epis_institution_id
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN institution.id_institution%TYPE IS
    
        l_inst_id institution.id_institution%TYPE;
    BEGIN
        g_error := 'GET EPISODE INSTITUTION ID';
        SELECT vis.id_institution
          INTO l_inst_id
          FROM episode epis, visit vis
         WHERE epis.id_episode = i_id_episode
           AND vis.id_visit = epis.id_visit;
    
        RETURN l_inst_id;
    
    EXCEPTION
        -- if theres an error return null
        WHEN OTHERS THEN
            RETURN NULL;
    END get_epis_institution_id;

    /********************************************************************************************
    * Returns id_patient associated to an episode
    *  
    * @param i_lang            language identifier
    * @param i_prof            logged professional structure                                                                                                                                        
    * @param i_episode                Episode ID                                                                                              
    * @return                         Patient ID                                                        
    *                                                                                                                          
    * @author                         Sofia Mendes                                                                                 
    * @version                         2.6.0.3                                                                                                     
    * @since                          02-Jun-2010                                                                                              
    ********************************************************************************************/
    FUNCTION get_epis_patient
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN patient.id_patient%TYPE IS
        l_ret patient.id_patient%TYPE;
    BEGIN
        SELECT e.id_patient
          INTO l_ret
          FROM episode e
         WHERE e.id_episode = i_episode;
    
        RETURN l_ret;
    END get_epis_patient;

    /******************************************************************************
    *  Returns id_task_dependency from an episode
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_id_episode        episode identifier
    *
    *  @return                     id_task_identifier
    *
    *  @author                     Luís Maia
    *  @version                    2.6.0.3
    *  @since                      02-07-2010
    *
    ******************************************************************************/
    FUNCTION get_task_dependency
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN episode.id_task_dependency%TYPE IS
        --
        l_func_name          VARCHAR2(30) := 'GET_TASK_DEPENDENCY';
        l_id_task_dependency episode.id_task_dependency%TYPE;
    BEGIN
        g_error := 'GET ID_TASK_DEPENDENCY IDENTIFIER';
        pk_alertlog.log_debug(g_error);
        BEGIN
            SELECT epi.id_task_dependency
              INTO l_id_task_dependency
              FROM episode epi
             WHERE epi.id_episode = i_id_episode;
        EXCEPTION
            WHEN no_data_found THEN
                g_error := 'GET ID_TASK_DEPENDENCY IDENTIFIER: NO_DATA_FOUND FOR ID_EPISODE=' || i_id_episode;
                pk_alertlog.log_debug(g_error);
                RETURN NULL;
        END;
        --
        RETURN l_id_task_dependency;
    END get_task_dependency;

    /**********************************************************************************************
    * Update id_task_dependency from an episode
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_episode                episode id
    * @param i_id_task_dependency     new id_task_dependency identifier
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    *  @author                        Luís Maia
    *  @version                       2.6.0.3
    *  @since                         02-07-2010
    **********************************************************************************************/
    FUNCTION set_task_dependency
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_task_dependency IN episode.id_episode%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rowids table_varchar := table_varchar();
    BEGIN
        g_error := 'UDPATE EPISODE.ID_TASK_DEPENDENCY';
        pk_alertlog.log_debug(g_error);
        ts_episode.upd(id_episode_in         => i_id_episode,
                       id_task_dependency_in => i_id_task_dependency,
                       rows_out              => l_rowids);
    
        t_data_gov_mnt.process_update(i_lang,
                                      i_prof,
                                      'EPISODE',
                                      l_rowids,
                                      o_error,
                                      table_varchar('ID_TASK_DEPENDENCY'));
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_owner_name, g_pck_name, 'SET_TASK_DEPENDENCY');
                -- undo changes quando aplicável
                pk_utils.undo_changes;
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN l_ret;
            END;
    END set_task_dependency;

    /**********************************************************************************************
    * Get episode's begin date.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   Professional
    * @param i_episode                episode identifier
    * @param o_dt_begin               Episode begin date
    * @param o_error                  Error message
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author                         João Martins
    * @version                        2.5.1.2
    * @since                          2010/10/27
    **********************************************************************************************/
    FUNCTION get_epis_dt_begin
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_dt_begin   OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        e_epis_dt_begin_tstz EXCEPTION;
        l_dt_begin_tstz episode.dt_begin_tstz%TYPE;
    BEGIN
        IF NOT get_epis_dt_begin_tstz(i_lang          => i_lang,
                                      i_prof          => i_prof,
                                      i_id_episode    => i_id_episode,
                                      o_dt_begin_tstz => l_dt_begin_tstz,
                                      o_error         => o_error)
        THEN
            RAISE e_epis_dt_begin_tstz;
        ELSE
            o_dt_begin := pk_date_utils.get_timestamp_str(i_lang      => i_lang,
                                                          i_prof      => i_prof,
                                                          i_timestamp => l_dt_begin_tstz,
                                                          i_timezone  => NULL);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner_name,
                                              i_package  => g_pck_name,
                                              i_function => 'GET_EPIS_DT_BEGIN',
                                              o_error    => o_error);
        
            RETURN FALSE;
    END get_epis_dt_begin;

    /**********************************************************************************************
    * Get episode's begin date in timestamp with local time zone
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_episode                episode identifier
    * @param o_dt_begin               Episode begin date
    * @param o_error                  Error message
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author                         João Martins
    * @version                        2.5.1.2
    * @since                          2010/10/27
    *
    * @author                         ANTONIO.NETO
    * @version                        2.6.2.1
    * @since                          30-Mar-2012
    **********************************************************************************************/
    FUNCTION get_epis_dt_begin_tstz
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        o_dt_begin_tstz OUT episode.dt_begin_tstz%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET DT_BEGIN with id_episode: ' || i_id_episode;
        SELECT e.dt_begin_tstz
          INTO o_dt_begin_tstz
          FROM episode e
         WHERE id_episode = i_id_episode;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_owner_name,
                                   g_pck_name,
                                   'GET_EPIS_DT_BEGIN_TSTZ');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN l_ret;
            END;
            RETURN FALSE;
    END get_epis_dt_begin_tstz;

    /**********************************************************************************************
    * Gets the last episode of a patient and checks if it can be reopened
    *
    * @param i_lang         Language ID
    * @param i_prof         Current profissional
    * @param i_patient      Patient ID
    *
    * @param o_last_episode Last episode ID
    * @param o_flg_reopen   Episode can be reopened: Y - yes, N - no
    * @param o_error        Error information
    *
    * @return  True or False on success or error
    *
    * @author  Jos?Silva
    * @version 2.6.0.3
    * @since   21-Dec-2010
    **********************************************************************************************/
    FUNCTION get_last_episode
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_flg_discharge IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_last_episode  OUT episode.id_episode%TYPE,
        o_flg_reopen    OUT VARCHAR2,
        o_epis_type     OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_last_episode IS
            SELECT e.id_episode,
                   decode(e.flg_status,
                          pk_alert_constant.g_epis_status_inactive,
                          pk_alert_constant.g_yes,
                          pk_alert_constant.g_epis_status_pendent,
                          pk_alert_constant.g_yes,
                          pk_alert_constant.g_epis_status_active,
                          decode(i_flg_discharge,
                                 pk_alert_constant.g_yes,
                                 decode(d.flg_status,
                                        pk_discharge.g_disch_flg_pend,
                                        pk_alert_constant.g_yes,
                                        pk_alert_constant.g_no),
                                 pk_alert_constant.g_no),
                          pk_alert_constant.g_no) can_reopen,
                   e.id_epis_type
              FROM episode e
              LEFT JOIN discharge d
                ON e.id_episode = d.id_episode
               AND d.flg_status NOT IN (pk_discharge.g_disch_flg_cancel, pk_discharge.g_disch_flg_reopen)
             WHERE e.id_patient = i_patient
               AND e.id_epis_type IN (pk_alert_constant.g_epis_type_emergency,
                                      pk_alert_constant.g_epis_type_inpatient,
                                      pk_alert_constant.g_epis_type_urgent_care,
                                      pk_alert_constant.g_epis_type_outpatient)
               AND e.flg_status <> pk_alert_constant.g_epis_status_cancel
               AND e.flg_ehr = pk_alert_constant.g_epis_ehr_normal
             ORDER BY e.dt_begin_tstz DESC;
    
    BEGIN
    
        g_error := 'C_LAST_EPISODE';
        OPEN c_last_episode;
        FETCH c_last_episode
            INTO o_last_episode, o_flg_reopen, o_epis_type;
        CLOSE c_last_episode;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_owner_name, g_pck_name, 'get_last_episode');
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
    END get_last_episode;

    /**
    * Sets intake time
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_episode      Episode id
    * @param   i_patient      Patient id
    * @param   i_intake_time  Intake time
    * @param   o_dt_register  Register date
    *
    * @param   o_error        Error information
    *
    * @return  Returns TRUE if success, otherwise returns FALSE
    *
    * @author  ALEXANDRE.SANTOS
    * @version 2.6.0.5
    * @since   25-01-2011
    */
    FUNCTION set_intake_time
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN epis_intake_time.id_episode%TYPE,
        i_patient     IN epis_intake_time.id_patient%TYPE,
        i_intake_time IN VARCHAR2,
        o_dt_register OUT epis_intake_time.dt_register%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'SET_INTAKE_TIME';
        --
        l_dt_intake_time epis_intake_time.dt_intake_time%TYPE;
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'CAST I_INTAKE_TIME TO TIMESTAMP';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        l_dt_intake_time := pk_date_utils.get_string_tstz(i_lang, i_prof, i_intake_time, NULL);
    
        g_error := 'INSERT EPIS_INTAKE_TIME';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        ts_epis_intake_time.ins(id_episode_in      => i_episode,
                                dt_register_in     => g_sysdate_tstz,
                                id_patient_in      => i_patient,
                                id_professional_in => i_prof.id,
                                dt_intake_time_in  => l_dt_intake_time);
    
        o_dt_register := g_sysdate_tstz;
    
        COMMIT;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner_name,
                                              i_package  => g_pck_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_intake_time;

    /**
    * Gets intake time info
    *
    * @param   i_lang                   Professional preferred language
    * @param   i_prof                   Professional identification and its context (institution and software)
    * @param   i_episode                Episode id
    * @param   i_all                    Is to show all records or only the current one?
    * @param   o_intake_time_register   Intake time registered info
    *
    * @param   o_error                  Error information
    *
    * @value   i_all {*} 'Y' All records
    *                {*} 'N' Only the current one
    *
    * @return  Returns TRUE if success, otherwise returns FALSE
    *
    * @author  ALEXANDRE.SANTOS
    * @version 2.6.0.5
    * @since   25-01-2011
    */
    FUNCTION get_intake_time_int
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN epis_intake_time.id_episode%TYPE,
        i_all                  IN VARCHAR2,
        o_intake_time_register OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_INTAKE_TIME_INT';
        --
        l_msg_register          sys_message.desc_message%TYPE;
        l_msg_treat_begin       sys_message.desc_message%TYPE;
        l_msg_register_title    sys_message.desc_message%TYPE;
        l_msg_treat_begin_title sys_message.desc_message%TYPE;
        --
        l_desc_active   sys_domain.desc_val%TYPE;
        l_desc_inactive sys_domain.desc_val%TYPE;
        --
        l_dt_admission   episode.dt_begin_tstz%TYPE;
        l_dt_curr_record epis_intake_time.dt_register%TYPE;
        --
        l_doc_area  CONSTANT doc_area.id_doc_area%TYPE := 6745;
        l_free_text CONSTANT VARCHAR2(1) := 'N';
    BEGIN
        g_error := 'GET REGISTER LABEL';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        l_msg_register := pk_message.get_message(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_code_mess => g_code_msg_reg_colon);
    
        g_error := 'GET TREATMENT BEGIN LABEL';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        l_msg_treat_begin := pk_message.get_message(i_lang      => i_lang,
                                                    i_prof      => i_prof,
                                                    i_code_mess => g_code_msg_treat_begin_colon);
    
        g_error := 'GET REGISTER TITLE';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        l_msg_register_title := pk_message.get_message(i_lang      => i_lang,
                                                       i_prof      => i_prof,
                                                       i_code_mess => g_code_msg_reg);
    
        g_error := 'GET TREATMENT BEGIN TITLE';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        l_msg_treat_begin_title := pk_message.get_message(i_lang      => i_lang,
                                                          i_prof      => i_prof,
                                                          i_code_mess => g_code_msg_treat_begin);
    
        g_error := 'GET ADMISSION DATE';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        SELECT epis.dt_begin_tstz
          INTO l_dt_admission
          FROM episode epis
         WHERE epis.id_episode = i_episode;
    
        g_error := 'GET CURR RECORD';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        BEGIN
            SELECT MAX(eit.dt_register)
              INTO l_dt_curr_record
              FROM epis_intake_time eit
             WHERE eit.id_episode = i_episode;
        EXCEPTION
            WHEN no_data_found THEN
                l_dt_curr_record := NULL;
        END;
    
        g_error := 'GET CURR RECORD';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        l_desc_active   := pk_sysdomain.get_domain(g_code_dom_act_inact, pk_alert_constant.g_active, i_lang);
        l_desc_inactive := pk_sysdomain.get_domain(g_code_dom_act_inact, pk_alert_constant.g_inactive, i_lang);
    
        g_error := 'OPEN CURSOR';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        --This cursor is used in a summary page so there are some fields that were added to fulfill the flash rules
        OPEN o_intake_time_register FOR
            SELECT -1 * (current_timestamp - eit.dt_register) order_by_default, --flash logic field
                   rownum id_epis_intake, --flash logic field
                   NULL id_parent, --flash logic field
                   l_msg_register_title title_admission,
                   l_msg_register label_admission,
                   pk_date_utils.date_char_tsz(i_lang, l_dt_admission, i_prof.institution, i_prof.software) dt_admission_chr,
                   pk_date_utils.date_send_tsz(i_lang, l_dt_admission, i_prof) dt_admission_arr,
                   pk_date_utils.date_char_tsz(i_lang, eit.dt_register, i_prof.institution, i_prof.software) dt_creation_chr,
                   pk_date_utils.date_send_tsz(i_lang, eit.dt_register, i_prof) dt_creation_arr,
                   eit.id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, eit.id_professional) reg_prof_name,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    eit.id_professional,
                                                    eit.dt_register,
                                                    eit.id_episode) reg_prof_spec,
                   l_msg_treat_begin_title title_intake_time,
                   l_msg_treat_begin label_intake_time,
                   pk_date_utils.date_char_tsz(i_lang, eit.dt_intake_time, i_prof.institution, i_prof.software) dt_intake_time_chr,
                   pk_date_utils.date_send_tsz(i_lang, eit.dt_intake_time, i_prof) dt_intake_time_arr,
                   l_doc_area id_doc_area,
                   decode(eit.dt_register, l_dt_curr_record, pk_alert_constant.g_active, pk_alert_constant.g_inactive) flg_status, --flash logic field
                   decode(eit.dt_register, l_dt_curr_record, '', l_desc_inactive) desc_status, --flash logic field
                   l_free_text flg_type_register, --flash logic field
                   eit.dt_register
              FROM epis_intake_time eit
             WHERE eit.id_episode = i_episode
               AND (eit.dt_register = l_dt_curr_record OR i_all = pk_alert_constant.g_yes)
            UNION ALL
            --This record is only to be shown when called by get_intake_time_det and where there isn't any data for the current episode
            SELECT NULL order_by_default, --flash logic field
                   rownum id_epis_intake, --flash logic field
                   NULL id_parent, --flash logic field
                   l_msg_register_title title_admission,
                   l_msg_register label_admission,
                   pk_date_utils.date_char_tsz(i_lang, l_dt_admission, i_prof.institution, i_prof.software) dt_admission_chr,
                   pk_date_utils.date_send_tsz(i_lang, l_dt_admission, i_prof) dt_admission_arr,
                   NULL dt_creation_chr,
                   NULL dt_creation_arr,
                   NULL id_professional,
                   NULL reg_prof_name,
                   NULL reg_prof_spec,
                   l_msg_treat_begin_title title_intake_time,
                   l_msg_treat_begin label_intake_time,
                   NULL dt_intake_time_chr,
                   NULL dt_intake_time_arr,
                   l_doc_area id_doc_area,
                   NULL flg_status, --flash logic field
                   NULL desc_status, --flash logic field
                   l_free_text flg_type_register, --flash logic field
                   NULL dt_register
              FROM dual
             WHERE NOT EXISTS (SELECT 1
                      FROM epis_intake_time eit
                     WHERE eit.id_episode = i_episode
                       AND (eit.dt_register = l_dt_curr_record))
               AND i_all = pk_alert_constant.g_no
             ORDER BY dt_register DESC;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner_name,
                                              i_package  => g_pck_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_intake_time_register);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_intake_time_int;

    /**
    * Gets intake time info
    *
    * @param   i_lang                   Professional preferred language
    * @param   i_prof                   Professional identification and its context (institution and software)
    * @param   i_episode                Episode id
    * @param   o_intake_time_register   Intake time registered info
    *
    * @param   o_error                  Error information
    *
    * @return  Returns TRUE if success, otherwise returns FALSE
    *
    * @author  ALEXANDRE.SANTOS
    * @version 2.6.0.5
    * @since   25-01-2011
    */
    FUNCTION get_intake_time
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN epis_intake_time.id_episode%TYPE,
        o_intake_time_register OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_INTAKE_TIME';
        --
        l_error EXCEPTION;
    BEGIN
        g_error := 'GET INTAKE_TIME';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        IF NOT get_intake_time_int(i_lang                 => i_lang,
                                   i_prof                 => i_prof,
                                   i_episode              => i_episode,
                                   i_all                  => pk_alert_constant.g_yes,
                                   o_intake_time_register => o_intake_time_register,
                                   o_error                => o_error)
        THEN
            RAISE l_error;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_error THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner_name,
                                              i_package  => g_pck_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_intake_time_register);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_intake_time;

    /**
    * Gets the current intake time info
    *
    * @param   i_lang                   Professional preferred language
    * @param   i_prof                   Professional identification and its context (institution and software)
    * @param   i_episode                Episode id
    * @param   o_intake_time_register   Intake time registered info
    *
    * @param   o_error                  Error information
    *
    * @return  Returns TRUE if success, otherwise returns FALSE
    *
    * @author  ALEXANDRE.SANTOS
    * @version 2.6.0.5
    * @since   25-01-2011
    */
    FUNCTION get_intake_time_det
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN epis_intake_time.id_episode%TYPE,
        o_intake_time_register OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_INTAKE_TIME_DET';
        --
        l_error EXCEPTION;
    BEGIN
        g_error := 'GET INTAKE_TIME';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        IF NOT get_intake_time_int(i_lang                 => i_lang,
                                   i_prof                 => i_prof,
                                   i_episode              => i_episode,
                                   i_all                  => pk_alert_constant.g_no,
                                   o_intake_time_register => o_intake_time_register,
                                   o_error                => o_error)
        THEN
            RAISE l_error;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_error THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner_name,
                                              i_package  => g_pck_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_intake_time_register);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_intake_time_det;

    /**
    * Gets intake time limits for a certain episode
    *
    * @param   i_lang                   Professional preferred language
    * @param   i_prof                   Professional identification and its context (institution and software)
    * @param   i_episode                Episode id
    * @param   o_intake_time_lim        Intake time limit cursor
    *
    * @param   o_error                  Error information
    *
    * @return  Returns TRUE if success, otherwise returns FALSE
    *
    * @author  ALEXANDRE.SANTOS
    * @version 2.6.0.5
    * @since   25-01-2011
    */
    FUNCTION get_intake_time_lim
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN epis_intake_time.id_episode%TYPE,
        o_intake_time_lim OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_INTAKE_TIME_LIM';
        --
        l_dt_min     epis_intake_time.dt_intake_time%TYPE;
        l_dt_max     epis_intake_time.dt_intake_time%TYPE;
        l_dt_cur     epis_intake_time.dt_intake_time%TYPE;
        l_dt_arrival epis_intake_time.dt_intake_time%TYPE;
        --
        l_dt_min_str VARCHAR2(30) := NULL;
        l_dt_max_str VARCHAR2(30) := NULL;
        --
    
        e_intake_time_lim EXCEPTION;
    BEGIN
        IF NOT get_intake_time_lim(i_lang       => i_lang,
                                   i_prof       => i_prof,
                                   i_episode    => i_episode,
                                   o_dt_cur     => l_dt_cur,
                                   o_dt_arrival => l_dt_arrival,
                                   o_dt_min     => l_dt_min,
                                   o_dt_max     => l_dt_max,
                                   o_error      => o_error)
        THEN
            RAISE e_intake_time_lim;
        END IF;
    
        g_error := 'PREPARE MIN DATE TO SEND TO FLASH';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        IF l_dt_min IS NOT NULL
        THEN
            --We must subtract one day to the admission day, this is done to extende the minimum date to prevent user mistakes
            l_dt_min_str := pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => l_dt_min, i_prof => i_prof);
        END IF;
    
        g_error := 'PREPARE MAX DATE TO SEND TO FLASH';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        l_dt_max_str := pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => l_dt_max, i_prof => i_prof);
    
        g_error := 'OPEN CURSOR';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        OPEN o_intake_time_lim FOR
            SELECT pk_date_utils.date_char_tsz(i_lang, l_dt_cur, i_prof.institution, i_prof.software) dt_admission_chr,
                   pk_date_utils.date_send_tsz(i_lang, l_dt_cur, i_prof) dt_admission_arr,
                   l_dt_min_str dt_min,
                   l_dt_max_str dt_max
              FROM dual;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner_name,
                                              i_package  => g_pck_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_intake_time_lim);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_intake_time_lim;

    /**
    * Gets intake time limits for a certain episode
    *
    * @param   i_lang                   Professional preferred language
    * @param   i_prof                   Professional identification and its context (institution and software)
    * @param   i_episode                Episode id
    * @param   o_dt_cur                 Current Date based on Begin Date
    * @param   o_dt_arrival             Last arrival date time
    * @param   o_dt_min                 Minimum Date
    * @param   o_dt_max                 Maximum Date
    * @param   o_error                  Error information
    *
    * @return                           Returns TRUE if success, otherwise returns FALSE
    *
    * @author                           António Neto
    * @version                          2.6.2
    * @since                            13-Feb-2012
    */
    FUNCTION get_intake_time_lim
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN epis_intake_time.id_episode%TYPE,
        o_dt_cur     OUT epis_intake_time.dt_intake_time%TYPE,
        o_dt_arrival OUT epis_intake_time.dt_intake_time%TYPE,
        o_dt_min     OUT epis_intake_time.dt_intake_time%TYPE,
        o_dt_max     OUT epis_intake_time.dt_intake_time%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_day CONSTANT PLS_INTEGER := 1;
    
    BEGIN
    
        g_error := 'GET ADMISSION DATE';
        pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => 'GET_INTAKE_TIME_LIM');
        SELECT epis.dt_begin_tstz
          INTO o_dt_cur
          FROM episode epis
         WHERE epis.id_episode = i_episode;
    
        g_error := 'GET LAST ARRIVAL DATE';
        pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => 'GET_INTAKE_TIME_LIM');
        BEGIN
            SELECT eit.dt_intake_time dt_intake_time_arr
              INTO o_dt_arrival
              FROM epis_intake_time eit
             WHERE eit.id_episode = i_episode
               AND eit.dt_register = (SELECT MAX(ei.dt_register)
                                        FROM epis_intake_time ei
                                       WHERE ei.id_episode = i_episode);
        EXCEPTION
            WHEN no_data_found THEN
                o_dt_arrival := NULL;
        END;
    
        g_error := 'PREPARE MIN DATE TO SEND TO FLASH';
        pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => 'GET_INTAKE_TIME_LIM');
        IF o_dt_cur IS NOT NULL
        THEN
            --We must subtract one day to the admission day, this is done to extende the minimum date to prevent user mistakes
            o_dt_min := o_dt_cur - l_day;
        END IF;
    
        g_error := 'GET DISCHARGE DATE';
        pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => 'GET_INTAKE_TIME_LIM');
        o_dt_max := pk_discharge.get_discharge_date(i_lang => i_lang, i_prof => i_prof, i_id_episode => i_episode);
    
        g_error := 'IF DISCH DATE = NULL THEN SET MAX DATE TO CURRENT DATE';
        pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => 'GET_INTAKE_TIME_LIM');
        IF o_dt_max IS NULL
        THEN
            o_dt_max := current_timestamp;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner_name,
                                              i_package  => g_pck_name,
                                              i_function => 'GET_INTAKE_TIME_LIM',
                                              o_error    => o_error);
        
            o_dt_cur := NULL;
            o_dt_min := NULL;
            o_dt_max := NULL;
        
            RETURN FALSE;
    END get_intake_time_lim;

    /********************************************************************************************
    * Function that matches two episodes with intake records
    *
    * @param i_lang          Language ID
    * @param i_prof          Professional
    * @param i_episode       Definitive episode ID
    * @param i_episode_temp  Temporary episode ID
    * @param o_error         Error ocurred
    *
    * @return                False if an error ocurred and True if not
    *
    * @author                Alexandre Santos
    * @version               2.6
    * @since                 26-01-2010
    ********************************************************************************************/
    FUNCTION set_intake_match
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_episode_temp IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'SET_INTAKE_MATCH';
        --
        l_count PLS_INTEGER;
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
    
        g_error := 'UPD EPIS AND PAT';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        UPDATE epis_intake_time eit
           SET eit.id_episode = i_episode,
               eit.id_patient =
               (SELECT epis.id_patient
                  FROM episode epis
                 WHERE epis.id_episode = i_episode)
         WHERE eit.id_episode = i_episode_temp;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner_name,
                                              i_package  => g_pck_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_intake_match;

    /************************************************************************************************************
    * This function returns episode dep_clin_serv
    *
    * @param i_lang          Language ID
    * @param i_prof          Professional   
    * @param i_episode       Episode Id
    *
    * @return     Dep_clin_serv Id
    *
    * @author     Sofia Mendes
    * @version    2.6.0.5
    * @since      18-Mai-2011
    ************************************************************************************************************/
    FUNCTION get_dep_clin_serv
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN epis_info.id_dep_clin_serv%TYPE IS
        l_id_dep_clin_serv epis_info.id_dep_clin_serv%TYPE;
        l_error            t_error_out;
    BEGIN
        g_error := 'GET episode dep_clin_serv. i_episode: ' || i_episode;
        pk_alertlog.log_debug(g_error);
        SELECT ei.id_dep_clin_serv
          INTO l_id_dep_clin_serv
          FROM epis_info ei
         WHERE ei.id_episode = i_episode;
    
        RETURN l_id_dep_clin_serv;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner_name,
                                              i_package  => g_pck_name,
                                              i_function => 'GET_DEP_CLIN_SERV',
                                              o_error    => l_error);
            RETURN NULL;
    END get_dep_clin_serv;

    /**
    * Returns the notes according to the given type (evaluation notes, plan notes,...)
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_episode                episode identifier
    * @param i_flg_type               Type of notes
    * @param i_order_desc             Sort records from most recent to oldest? 'Y' or 'N'
    *
    * @return               notes
    *
    * @author               Sofia Mendes
    * @version               2.5
    * @since                20/03/2013
    */
    FUNCTION get_epis_recommend_notes
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_flg_type   IN epis_recomend.flg_type%TYPE,
        i_order_desc IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN CLOB IS
    
        l_notes CLOB;
    
    BEGIN
        IF i_episode IS NULL
        THEN
            l_notes := NULL;
        ELSE
            g_error := 'GET NOTES i_episode: ' || i_episode;
            pk_alertlog.log_debug(g_error);
            SELECT concatenate_clob(dbms_xmlgen.convert(desc_epis_recomend_clob) || chr(10))
              INTO l_notes
              FROM (SELECT t.*
                      FROM (SELECT er.desc_epis_recomend_clob, er.id_episode, er.dt_epis_recomend_tstz dt_ord
                              FROM epis_recomend er
                             WHERE er.flg_type = i_flg_type
                               AND er.id_episode = i_episode
                               AND er.flg_temp != pk_clinical_info.g_flg_hist
                               AND er.flg_status = pk_alert_constant.g_active
                            UNION ALL
                            SELECT ed.notes desc_epis_recomend_clob, ed.id_episode, ed.dt_last_update_tstz dt_ord
                              FROM epis_documentation ed, episode e
                             WHERE ed.id_episode = i_episode
                               AND ed.id_episode = e.id_episode
                               AND e.id_epis_type IN (pk_alert_constant.g_epis_type_rehab_appointment,
                                                      pk_alert_constant.g_epis_type_rehab_session)
                               AND i_flg_type = g_flg_aval) t
                     ORDER BY CASE
                                   WHEN i_order_desc = pk_alert_constant.g_yes THEN
                                    t.dt_ord
                                   ELSE
                                    NULL
                               END DESC,
                              CASE
                                   WHEN i_order_desc = pk_alert_constant.g_no
                                        OR i_order_desc IS NULL THEN
                                    t.dt_ord
                                   ELSE
                                    NULL
                               END ASC) t_ord;
        
        END IF;
    
        RETURN l_notes;
    END get_epis_recommend_notes;

    /************************************************************************************************************
    * This function returns episode dep_clin_serv
    *
    * @param i_lang                 Language ID
    * @param i_prof                 Professional
    * @param i_episode              Episode Id
    * @param o_id_dep_clin_serv     Dep_clin_serv id
    * @param o_error                Error info
    *
    * @return     boolean
    *
    * @author     Sofia Mendes
    * @version    2.6.0.5
    * @since      18-Mai-2011
    ************************************************************************************************************/
    FUNCTION get_epis_dep_clin_serv
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        o_id_dep_clin_serv OUT epis_info.id_dep_clin_serv%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL get_dep_clin_serv. i_episode: ' || i_episode;
        pk_alertlog.log_debug(g_error);
        o_id_dep_clin_serv := get_dep_clin_serv(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode);
    
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner_name,
                                              i_package  => g_pck_name,
                                              i_function => 'GET_EPIS_DEP_CLIN_SERV',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_epis_dep_clin_serv;

    /**********************************************************************************************
    * Get episode's first observation date.
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_id_episode             Episode ID
    * @param i_dt_first_obs           First observation date
    * @param i_has_stripes            Has stripes? (N) No (Y) Yes. Found in GRIDS_EA or TRACKING_BOARD_EA.
    *
    * @return                         String with serialized date
    *
    * @author                         Jos?Brito
    * @version                        2.5.1
    * @since                          2011/05/12
    **********************************************************************************************/
    FUNCTION get_epis_dt_first_obs
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_dt_first_obs IN epis_info.dt_first_obs_tstz%TYPE,
        i_has_stripes  IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'GET_EPIS_DT_FIRST_OBS';
        l_error t_error_out;
        l_empty CONSTANT VARCHAR2(1 CHAR) := '';
    
        l_dt_first_obs      VARCHAR2(200 CHAR);
        l_dt_first_obs_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
    
        l_dt_first_obs_tstz := get_epis_dt_first_obs(i_id_episode   => i_id_episode,
                                                     i_dt_first_obs => i_dt_first_obs,
                                                     i_has_stripes  => i_has_stripes);
    
        IF l_dt_first_obs_tstz IS NULL
        THEN
            l_dt_first_obs := l_empty;
        ELSE
            l_dt_first_obs := pk_date_utils.date_send_tsz(i_lang, l_dt_first_obs_tstz, i_prof);
        END IF;
    
        RETURN l_dt_first_obs;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner_name,
                                              g_pck_name,
                                              l_func_name,
                                              l_error);
            RETURN l_empty;
    END get_epis_dt_first_obs;

    /**********************************************************************************************
    * Get episode's first observation date.
    *
    * @param i_id_episode             Episode ID
    * @param i_dt_first_obs           First observation date
    * @param i_has_stripes            Has stripes? (N) No (Y) Yes. Found in GRIDS_EA or TRACKING_BOARD_EA.
    * @param i_alert_query            Indicates if is called from an alert query: (Y) Yes (N) No - default.
    *
    * @return                         First observation date
    *
    * @author                         Jos?Brito
    * @version                        2.5.1
    * @since                          2011/05/12
    **********************************************************************************************/
    FUNCTION get_epis_dt_first_obs
    (
        i_id_episode   IN episode.id_episode%TYPE,
        i_dt_first_obs IN epis_info.dt_first_obs_tstz%TYPE,
        i_has_stripes  IN VARCHAR2 DEFAULT NULL,
        i_alert_query  IN VARCHAR2 DEFAULT 'N'
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
        l_dt_first_obs_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
    
        IF nvl(i_has_stripes, pk_alert_constant.g_no) = pk_alert_constant.g_yes
        THEN
            -- If easy access force patient not to have "stripes" in the triage column, then 
            -- send NULL as first observation date, regardless if is or isn't registered in the DB.
            l_dt_first_obs_tstz := NULL;
        
        ELSIF i_alert_query = pk_alert_constant.g_yes
        THEN
            -- Value of "has_stripes" only is available by accessing EA tables, which aren't consulted in
            -- alert queries.
            BEGIN
                SELECT decode(nvl(gea.flg_has_stripes, pk_alert_constant.g_no),
                              pk_alert_constant.g_yes,
                              NULL,
                              i_dt_first_obs)
                  INTO l_dt_first_obs_tstz
                  FROM grids_ea gea
                 WHERE gea.id_episode = i_id_episode;
            EXCEPTION
                WHEN no_data_found THEN
                    l_dt_first_obs_tstz := i_dt_first_obs;
            END;
        
        ELSE
            -- Otherwise send whichever date is registered in the DB.
            l_dt_first_obs_tstz := i_dt_first_obs;
        END IF;
    
        RETURN l_dt_first_obs_tstz;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_epis_dt_first_obs;
    --
    /**
     * This function returns the scope of episodes
     *
     * @param    IN  i_lang            Language ID
     * @param    IN  i_prof            Professional structure
     * @param    IN  i_patient         Patient ID
     * @param    IN  i_episode         Episode ID
     * @param    IN  i_flg_filter      Flag filter (P - Patient, V - Visit, E - Episode)
     *
     * @return   BOOLEAN
     *
     * @version  
     * @since    
     * @created  
    */

    FUNCTION get_scope
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_flg_filter IN VARCHAR2
    ) RETURN table_number IS
    
        l_epis     table_number := table_number();
        l_epis_all table_number := table_number();
    
    BEGIN
    
        -- get all episodes that belongs to the patient    
        SELECT a.id_episode
          BULK COLLECT
          INTO l_epis_all
          FROM episode a
         WHERE a.id_patient = i_patient
         ORDER BY a.dt_creation DESC;
    
        CASE
            WHEN i_flg_filter = pk_alert_constant.g_scope_type_episode THEN
                l_epis.extend(1);
                l_epis(l_epis.count) := nvl(i_episode, 1);
            
            WHEN i_flg_filter = pk_alert_constant.g_scope_type_visit THEN
                -- get all episodes that belongs to current visit
                SELECT a.id_episode
                  BULK COLLECT
                  INTO l_epis
                  FROM episode a
                 WHERE a.id_visit = (SELECT e.id_visit
                                       FROM episode e
                                      WHERE e.id_episode = i_episode)
                 ORDER BY a.dt_creation DESC;
            
            WHEN i_flg_filter = pk_alert_constant.g_scope_type_patient THEN
                l_epis := l_epis_all;
            
            ELSE
                l_epis := l_epis_all;
        END CASE;
    
        RETURN l_epis;
    
    END get_scope;

    /************************************************************************************************************
    * This function returns the department associated to the episode dep_clin_serv
    *
    * @param i_lang          Language ID
    * @param i_prof          Professional   
    * @param i_episode       Episode Id
    *
    * @return     Department Id
    *
    * @author     Sofia Mendes
    * @version    2.6.0.5
    * @since      29-Oct-2013
    ************************************************************************************************************/
    FUNCTION get_epis_department
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN dep_clin_serv.id_department%TYPE IS
        l_id_department department.id_department%TYPE;
        l_error         t_error_out;
    BEGIN
        g_error := 'GET episode department. i_episode: ' || i_episode;
        pk_alertlog.log_debug(g_error);
        SELECT d.id_department
          INTO l_id_department
          FROM epis_info ei
          JOIN dep_clin_serv d
            ON d.id_dep_clin_serv = ei.id_dep_clin_serv
         WHERE ei.id_episode = i_episode;
    
        RETURN l_id_department;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner_name,
                                              i_package  => g_pck_name,
                                              i_function => 'GET_EPIS_DEPARTMENT',
                                              o_error    => l_error);
            RETURN NULL;
    END get_epis_department;

    /************************************************************************************************************
    * This function returns episode information by episode, visit and patient identification
    *
    * @param i_lang          Language ID
    * @param i_prof          Professional   
    * @param i_id_patient    Patient Id
    * @param i_scope         Function scope type: P- patient, E- episode, V- visit
    * @param i_id_scope      Corresponding scope identifier
    *
    * @return     Table type - t_table_episode_cda
    *
    * @author     Gisela Couto
    * @version    2.6.3.15
    * @since      10-April-2014
    ************************************************************************************************************/
    FUNCTION get_episode_cda
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_scope      IN VARCHAR2,
        i_id_scope   IN NUMBER
    ) RETURN t_table_episode_cda IS
        l_episode table_number := table_number();
        l_error   t_error_out;
        o_result  t_table_episode_cda;
        --
        l_function_name CONSTANT VARCHAR2(200 CHAR) := 'GET_EPISODE_CDA';
    BEGIN
        g_error := 'VERIFY IF SCOPE IS NULL';
        IF (i_scope IS NULL)
        THEN
            g_error := 'i_scope IS NULL';
            RAISE g_exception;
        END IF;
    
        g_error := 'GET EPISODES BY SCOPE - ' || i_scope;
    
        IF i_scope = g_scope_episode
        THEN
            /*Episode Scope*/
            g_error   := 'CALL PK_PATIENT.GET_EPISODE_LIST';
            l_episode := pk_patient.get_episode_list(i_lang              => i_lang,
                                                     i_prof              => i_prof,
                                                     i_id_patient        => i_id_patient,
                                                     i_id_episode        => i_id_scope,
                                                     i_id_visit          => NULL,
                                                     i_flg_visit_or_epis => g_scope_episode);
        ELSIF i_scope = g_scope_visit
        THEN
            /*Visit Scope*/
            g_error   := 'CALL PK_PATIENT.GET_EPISODE_LIST';
            l_episode := pk_patient.get_episode_list(i_lang              => i_lang,
                                                     i_prof              => i_prof,
                                                     i_id_patient        => i_id_patient,
                                                     i_id_episode        => NULL,
                                                     i_id_visit          => i_id_scope,
                                                     i_flg_visit_or_epis => g_scope_visit);
        
        ELSIF i_scope = g_scope_patient
        THEN
            /*Patient scope*/
            g_error   := 'CALL PK_PATIENT.GET_EPISODE_LIST';
            l_episode := pk_patient.get_episode_list(i_lang              => i_lang,
                                                     i_prof              => i_prof,
                                                     i_id_patient        => i_id_patient,
                                                     i_id_episode        => NULL,
                                                     i_id_visit          => NULL,
                                                     i_flg_visit_or_epis => g_scope_patient);
        
        END IF;
    
        IF l_episode.exists(1)
        THEN
        
            SELECT t_rec_episode_cda(dt_begin_tstz        => ep.dt_begin_tstz,
                                     dt_begin_formatted   => pk_date_utils.date_char_tsz(i_lang => i_lang,
                                                                                         i_date => ep.dt_begin_tstz,
                                                                                         i_inst => i_prof.institution,
                                                                                         i_soft => i_prof.software),
                                     dt_begin_id_timezone => inst.id_timezone_region,
                                     dt_end_tstz          => ep.dt_end_tstz,
                                     dt_end_formatted     => pk_date_utils.date_char_tsz(i_lang => i_lang,
                                                                                         i_date => ep.dt_end_tstz,
                                                                                         i_inst => i_prof.institution,
                                                                                         i_soft => i_prof.software),
                                     dt_end_id_timezone   => inst.id_timezone_region,
                                     id_institution       => inst.id_institution,
                                     id_country           => c.id_country,
                                     institution_name     => pk_translation.get_translation(i_lang      => i_lang,
                                                                                            i_code_mess => inst.code_institution),
                                     address              => inst.address,
                                     zip_code             => inst.zip_code,
                                     phone_number         => inst.phone_number,
                                     district             => inst.district,
                                     country              => pk_translation.get_translation(i_lang      => i_lang,
                                                                                            i_code_mess => c.code_country),
                                     location             => inst.location,
                                     email                => insta.email)
              BULK COLLECT
              INTO o_result
              FROM episode ep
              JOIN institution inst
                ON inst.id_institution = ep.id_institution
              JOIN timezone_region tzr
                ON tzr.id_timezone_region = inst.id_timezone_region
              JOIN inst_attributes insta
                ON insta.id_institution = inst.id_institution
              JOIN country c
                ON insta.id_country = c.id_country
             WHERE ep.id_episode IN (SELECT *
                                       FROM TABLE(l_episode));
        
        ELSE
            o_result := t_table_episode_cda();
        END IF;
    
        RETURN o_result;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner_name,
                                              i_package  => g_pck_name,
                                              i_function => l_function_name,
                                              o_error    => l_error);
            RETURN NULL;
    END get_episode_cda;
    /**
    * count visit episodes oris and inp
    *
    * @param i_lang              language identifier
    * @param i_prof              logged professional structure
    * @param i_id_episode        episode  identifier
    *
    * @return               count visit episodes oris and inp
    *
    * @author              Paulo Teixeira
    * @version              2.6
    * @since                2014/10/02
    */
    FUNCTION count_oris_inp_visit_epis
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN NUMBER IS
        l_count NUMBER(12);
    BEGIN
    
        SELECT COUNT(1)
          INTO l_count
          FROM episode e
         WHERE e.id_visit IN (SELECT epis.id_visit
                                FROM episode epis
                               WHERE epis.id_episode = i_id_episode)
           AND e.id_epis_type IN (pk_alert_constant.g_epis_type_operating, pk_alert_constant.g_epis_type_inpatient);
    
        RETURN l_count;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END count_oris_inp_visit_epis;
    --
    /**********************************************************************************************
    * Gets the last episode of a patient by software
    *
    * @param i_lang         Language ID
    * @param i_prof         Current profissional
    * @param i_patient      Patient ID
    * @param i_software     Software ID
    *
    * @return  Last episode ID
    *
    * @author  Alexandre Santos
    * @version 2.6.4
    * @since   11-Nov-2014
    **********************************************************************************************/
    FUNCTION get_last_episode_by_soft
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_software IN software.id_software%TYPE DEFAULT NULL
    ) RETURN episode.id_episode%TYPE IS
        l_last_episode episode.id_episode%TYPE;
    BEGIN
        BEGIN
            SELECT t.id_episode
              INTO l_last_episode
              FROM (SELECT epis.id_episode,
                           row_number() over(ORDER BY epis.dt_end_tstz DESC NULLS FIRST, epis.dt_begin_tstz DESC) line_number
                      FROM episode epis
                      JOIN epis_info ei
                        ON ei.id_episode = epis.id_episode
                     WHERE ei.id_software = nvl(i_software, ei.id_software)
                       AND epis.id_patient = i_patient
                       AND epis.flg_ehr = 'N'
                       AND epis.flg_status IN ('A', 'I', 'P')) t
             WHERE t.line_number = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_last_episode := NULL;
        END;
    
        RETURN l_last_episode;
    END get_last_episode_by_soft;

    PROCEDURE set_outp_no_show IS
        /******************************************************************************
           OBJECTIVO:  Colocar NO-SHOW os episódios agendados ao final do dia.         
        *********************************************************************************/
        l_count          NUMBER;
        l_error          t_error_out;
        l_transaction_id VARCHAR2(4000);
        l_aux            VARCHAR2(2000);
        --
        CURSOR c_episode IS
            SELECT e.id_episode, ei.id_schedule, e.id_patient, ei.id_software, e.id_institution
              FROM episode e
              JOIN epis_info ei
                ON e.id_episode = ei.id_episode
              JOIN schedule_outp so
                ON so.id_schedule = ei.id_schedule
             WHERE so.dt_target_tstz < current_timestamp
               AND e.id_epis_type = pk_alert_constant.g_epis_type_outpatient
               AND e.flg_ehr = pk_visit.g_flg_ehr_s
               AND pk_grid.get_schedule_real_state(so.flg_state, e.flg_ehr) = pk_grid_amb.g_sched_scheduled
               AND e.dt_cancel_tstz IS NULL
                  -- exists
               AND EXISTS (SELECT 1
                      FROM sch_api_map_ids sami
                     WHERE sami.id_schedule_pfh = ei.id_schedule);
    
        l_rowids table_varchar;
        l_prof   profissional;
        l_lang   language.id_language%TYPE := 2;
        o_error  t_error_out;
        l_internal_error EXCEPTION;
        l_rowids2           table_varchar;
        l_sei_flg_status    table_varchar;
        l_id_sr_epis_interv table_number;
        l_id_cancel_reason  sys_config.value%TYPE;
    
    BEGIN
        FOR i IN c_episode
        LOOP
            l_prof := profissional(0, i.id_institution, i.id_software);
            l_lang := pk_sysconfig.get_config('LANGUAGE', l_prof);
        
            l_id_cancel_reason := pk_sysconfig.get_config(g_inactive_no_show_creason, l_prof);
        
            IF NOT pk_schedule_api_ui.set_patient_no_show(i_lang             => l_lang,
                                                          i_prof             => l_prof,
                                                          i_id_schedule      => i.id_schedule,
                                                          i_id_patient       => i.id_patient,
                                                          i_id_cancel_reason => l_id_cancel_reason,
                                                          i_notes            => NULL,
                                                          o_error            => o_error)
            THEN
                pk_alertlog.log_warn('ERROR ON JOB PK_EPISODE.SET_OUTP_NO_SHOW for patient: ' || i.id_patient ||
                                     ' with id_schedule ' || i.id_schedule);
            END IF;
            COMMIT;
        END LOOP;
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line('ERROR' || SQLERRM);
            dbms_output.put_line(g_error);
            pk_alert_exceptions.process_error(l_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_owner_name,
                                              g_pck_name,
                                              'SET_OUTP_NO_SHOW',
                                              o_error);
            pk_utils.undo_changes;
    END set_outp_no_show;

    FUNCTION get_episode_summary
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_pat                  IN patient.id_patient%TYPE,
        i_epis                 IN table_number,
        i_review               IN BOOLEAN,
        o_complaint            OUT pk_types.cursor_type,
        o_info10               OUT pk_types.cursor_type,
        o_history              OUT pk_types.cursor_type,
        o_history_doc          OUT pk_types.cursor_type,
        o_history_ft           OUT pk_types.cursor_type,
        o_review               OUT pk_types.cursor_type,
        o_problems             OUT pk_types.cursor_type,
        o_relev_disease        OUT pk_types.cursor_type,
        o_surgical_hist        OUT pk_types.cursor_type,
        o_allergy              OUT pk_types.cursor_type,
        o_medication           OUT pk_types.cursor_type,
        o_home_med_review      OUT pk_types.cursor_type,
        o_pat_take             OUT pk_types.cursor_type,
        o_fam_hist             OUT pk_types.cursor_type,
        o_soc_hist             OUT pk_types.cursor_type,
        o_relev_notes          OUT pk_types.cursor_type,
        o_habit                OUT pk_types.cursor_type,
        o_info7                OUT pk_types.cursor_type,
        o_vital_sign           OUT pk_types.cursor_type,
        o_biometric            OUT pk_types.cursor_type,
        o_phys_exam            OUT pk_types.cursor_type,
        o_body_diags           OUT pk_types.cursor_type,
        o_ass_scales           OUT pk_types.cursor_type,
        o_blood_group          OUT pk_types.cursor_type,
        o_evaluation           OUT pk_types.cursor_type,
        o_diag                 OUT pk_types.cursor_type,
        o_impressions          OUT pk_types.cursor_type,
        o_plan                 OUT pk_types.cursor_type,
        o_therapeutic_decision OUT pk_types.cursor_type,
        o_analysis             OUT pk_types.cursor_type,
        o_exam                 OUT pk_types.cursor_type,
        o_presc_ext            OUT pk_types.cursor_type,
        o_dietary_ext          OUT pk_types.cursor_type,
        o_manip_ext            OUT pk_types.cursor_type,
        o_presc                OUT pk_types.cursor_type,
        o_interv               OUT pk_types.cursor_type,
        o_monitorization       OUT pk_types.cursor_type,
        o_nurse_act            OUT pk_types.cursor_type,
        o_nurse_teach          OUT pk_types.cursor_type,
        o_gp_notes             OUT pk_types.cursor_type,
        o_referrals            OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(13 CHAR) := 'GET_SUMMARY_S';
        l_error t_error_out;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
        IF i_review
        THEN
            g_error := 'CALL GET_SUMMARY_S';
            IF NOT get_summary_s(i_lang            => i_lang,
                                 i_pat             => i_pat,
                                 i_epis            => i_epis,
                                 i_prof            => i_prof,
                                 i_review          => i_review,
                                 o_complaint       => o_complaint,
                                 o_history         => o_history,
                                 o_review          => o_review,
                                 o_fam_hist        => o_fam_hist,
                                 o_soc_hist        => o_soc_hist,
                                 o_allergy         => o_allergy,
                                 o_habit           => o_habit,
                                 o_relev_disease   => o_relev_disease,
                                 o_relev_notes     => o_relev_notes,
                                 o_medication      => o_medication,
                                 o_home_med_review => o_home_med_review,
                                 o_pat_take        => o_pat_take,
                                 o_info10          => o_info10,
                                 o_surgical_hist   => o_surgical_hist,
                                 o_error           => o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSE
            g_error := 'CALL GET_SUMMARY_S';
            IF NOT get_summary_s(i_lang            => i_lang,
                                 i_pat             => i_pat,
                                 i_epis            => i_epis,
                                 i_prof            => i_prof,
                                 o_complaint       => o_complaint,
                                 o_history_doc     => o_history_doc,
                                 o_history_ft      => o_history_ft,
                                 o_fam_hist        => o_fam_hist,
                                 o_soc_hist        => o_soc_hist,
                                 o_allergy         => o_allergy,
                                 o_habit           => o_habit,
                                 o_relev_disease   => o_relev_disease,
                                 o_relev_notes     => o_relev_notes,
                                 o_medication      => o_medication,
                                 o_info10          => o_info10,
                                 o_home_med_review => o_home_med_review,
                                 o_pat_take        => o_pat_take,
                                 o_surgical_hist   => o_surgical_hist,
                                 o_error           => o_error)
            THEN
                RAISE g_exception;
            
            END IF;
        END IF;
    
        g_error := 'CALL GET_SUMMARY_O';
        IF NOT get_summary_o(i_lang           => i_lang,
                             i_pat            => i_pat,
                             i_epis           => i_epis,
                             i_prof           => i_prof,
                             o_vital_sign     => o_vital_sign,
                             o_biometric      => o_biometric,
                             o_phys_exam      => o_phys_exam,
                             o_monitorization => o_monitorization,
                             o_problems       => o_problems,
                             o_blood_group    => o_blood_group,
                             o_info7          => o_info7,
                             o_error          => o_error)
        THEN
            RAISE g_exception;
        END IF;
        g_error := 'CALL GET_SUMMARY_A';
        IF NOT get_summary_a(i_lang        => i_lang,
                             i_pat         => i_pat,
                             i_epis        => i_epis,
                             i_prof        => i_prof,
                             o_problems    => o_problems,
                             o_ass_scales  => o_ass_scales,
                             o_body_diags  => o_body_diags,
                             o_diag        => o_diag,
                             o_impressions => o_impressions,
                             o_evaluation  => o_evaluation,
                             o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF NOT get_summary_p(i_lang                 => i_lang,
                             i_pat                  => i_pat,
                             i_epis                 => i_epis,
                             i_prof                 => i_prof,
                             o_analysis             => o_analysis,
                             o_exam                 => o_exam,
                             o_presc_ext            => o_presc_ext,
                             o_dietary_ext          => o_dietary_ext,
                             o_manip_ext            => o_manip_ext,
                             o_presc                => o_presc,
                             o_interv               => o_interv,
                             o_monitorization       => o_monitorization,
                             o_nurse_act            => o_nurse_act,
                             o_nurse_teach          => o_nurse_teach,
                             o_plan                 => o_plan,
                             o_therapeutic_decision => o_therapeutic_decision,
                             o_referrals            => o_referrals,
                             o_gp_notes             => o_gp_notes,
                             o_error                => o_error)
        THEN
            RAISE g_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner_name,
                                              i_package  => g_pck_name,
                                              i_function => 'GET_EPIS_DEPARTMENT',
                                              o_error    => l_error);
            RETURN FALSE;
    END get_episode_summary;

    /**********************************************************************************************
    * Get all episodes by visit and status
    *
    * @param i_id_visit     Visit ID
    * @param i_id_status    Flag Status
    *
    * @return  Episode ID List
    *
    * @author  Vitor Reis
    * @version 2.6.5.1
    * @since   06-Nov-2015
    **********************************************************************************************/
    FUNCTION get_epis_by_visit_and_status
    (
        i_id_visit  IN visit.id_visit%TYPE,
        i_id_status IN table_varchar2
    ) RETURN table_number IS
    
        l_episodes table_number;
    
    BEGIN
    
        SELECT epis.id_episode
          BULK COLLECT
          INTO l_episodes
          FROM episode epis
         WHERE epis.id_visit = i_id_visit
           AND epis.flg_status IN (SELECT /*+OPT_ESTIMATE(TABLE p ROWS=1)*/
                                    column_value
                                     FROM TABLE(i_id_status) p);
    
        RETURN l_episodes;
    
    END get_epis_by_visit_and_status;

    /**********************************************************************************************
    * Get all active episodes by visit
    *
    * @param i_id_visit     Visit ID
    *
    * @return  Episode ID List
    *
    * @author  Vitor Reis
    * @version 2.6.5.1
    * @since   06-Nov-2015
    **********************************************************************************************/
    FUNCTION get_active_epis_by_visit(i_id_visit IN visit.id_visit%TYPE) RETURN table_number IS
    
    BEGIN
    
        RETURN get_epis_by_visit_and_status(i_id_visit  => i_id_visit,
                                            i_id_status => table_varchar2(pk_alert_constant.g_epis_status_active));
    
    END get_active_epis_by_visit;

    FUNCTION get_epis_clinical_serv
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_id_dep_clin_serv dep_clin_serv.id_dep_clin_serv%TYPE;
        l_clinical_service VARCHAR2(2000 CHAR);
    BEGIN
        l_id_dep_clin_serv := get_dep_clin_serv(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode);
        l_clinical_service := pk_hea_prv_aux.get_clin_service(i_lang             => i_lang,
                                                              i_prof             => i_prof,
                                                              i_id_dep_clin_serv => l_id_dep_clin_serv);
        RETURN l_clinical_service;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_epis_clinical_serv;

    FUNCTION get_epis_room
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
    
        l_room pk_translation.t_desc_translation;
    
    BEGIN
    
        SELECT nvl(pk_translation.get_translation(i_lang, 'ROOM.CODE_ABBREVIATION.' || ei.id_room),
                   pk_translation.get_translation(i_lang, 'ROOM.CODE_ROOM.' || ei.id_room))
          INTO l_room
          FROM epis_info ei
         WHERE ei.id_episode = i_episode;
    
        RETURN l_room;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_epis_room;

    FUNCTION get_epis_id_room
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN epis_info.id_room%TYPE IS
        l_room epis_info.id_room%TYPE;
    BEGIN
    
        SELECT ei.id_room
          INTO l_room
          FROM epis_info ei
         WHERE ei.id_episode = i_episode;
    
        RETURN l_room;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_epis_id_room;

    /********************************************************************************************
    * Get CHIEF COMPLAINT/ REASON FOR VISIT viewer checklist 
    *             
    * @param i_lang       language idenfier
    * @param i_scope_type scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param i_id_patient patient idenfier
    * @param i_id_episode episode idenfier
    * @param o_flg_out    flag out 
    * @param o_error      t_error_out type error
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                         Elisabete Bugalho
    * @version                        2.6.5
    * @since                          2016-10-25
    **********************************************************************************************/

    FUNCTION get_complaint_viewer_checklist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_episodes table_number;
        l_count    NUMBER(12) := 0;
        l_status   VARCHAR2(1 CHAR) := pk_viewer_checklist.g_checklist_not_started;
    
    BEGIN
        SELECT *
          BULK COLLECT
          INTO l_episodes
          FROM TABLE(pk_episode.get_scope(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_patient    => i_id_patient,
                                          i_episode    => i_id_episode,
                                          i_flg_filter => i_scope_type));
    
        SELECT COUNT(1)
          INTO l_count
          FROM (SELECT ea.id_epis_anamnesis
                  FROM epis_anamnesis ea
                 WHERE ea.flg_status = pk_alert_constant.g_active
                   AND id_episode IN (SELECT /*+opt_estimate (table t rows=1)*/
                                       column_value
                                        FROM TABLE(l_episodes) t)
                UNION
                SELECT ec.id_epis_complaint
                  FROM epis_complaint ec
                 WHERE ec.flg_status = pk_alert_constant.g_active
                   AND id_episode IN (SELECT /*+opt_estimate (table t rows=1)*/
                                       column_value
                                        FROM TABLE(l_episodes) t));
        IF l_count > 0
        THEN
            l_status := pk_viewer_checklist.g_checklist_completed;
        END IF;
        RETURN l_status;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN l_status;
    END get_complaint_viewer_checklist;

    /********************************************************************************************
    * Get Admission information
    *             
    * @param i_lang       language idenfier
    * @param i_prof       profissional identifier
    * @param i_id_episode episode idenfier
    *
    * @return             Type with the admission information
    *
    * @author                         Elisabete Bugalho
    * @version                        2.7.2.3
    * @since                          2018-01-12
    **********************************************************************************************/

    FUNCTION tf_get_episode_admission
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN t_table_epis_transf IS
        l_admission          sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'PREV_EPISODE_T596');
        l_tbl_epis_admission t_table_epis_transf;
        l_function_name      VARCHAR2(030 CHAR) := 'TF_GET_EPISODE_ADMISSION';
        l_error              t_error_out;
        l_dt_begin           episode.dt_begin_tstz%TYPE;
        l_location           VARCHAR2(2000 CHAR);
        l_resp               VARCHAR2(2000 CHAR);
        l_id_type_admission CONSTANT NUMBER(24) := 1;
    BEGIN
    
        SELECT e.dt_begin_tstz
          INTO l_dt_begin
          FROM episode e
         WHERE e.id_episode = i_id_episode;
    
        l_location := pk_bmng.get_pat_location_by_date(i_lang,
                                                       i_prof,
                                                       i_id_episode,
                                                       l_dt_begin,
                                                       pk_alert_constant.g_yes);
    
        l_resp := pk_hand_off.get_prof_resp_list_by_date(i_lang,
                                                         i_prof,
                                                         i_id_episode,
                                                         l_dt_begin,
                                                         pk_alert_constant.g_yes);
    
        SELECT t_rec_epis_transf(i_id_episode,
                                 l_id_type_admission,
                                 l_dt_begin,
                                 l_admission,
                                 --                                 l_location || nvl2(l_resp, ', ' || l_resp, l_resp)
                                 NULL)
          BULK COLLECT
          INTO l_tbl_epis_admission
          FROM dual;
    
        RETURN l_tbl_epis_admission;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner_name,
                                              i_package  => g_pck_name,
                                              i_function => l_function_name,
                                              o_error    => l_error);
            RETURN l_tbl_epis_admission;
    END tf_get_episode_admission;

    FUNCTION get_episode_transfer_sp
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN CLOB IS
        l_ret           CLOB;
        l_sep           VARCHAR2(10 CHAR) := ': ';
        l_space         VARCHAR2(1 CHAR) := ' ';
        l_common        VARCHAR2(2 CHAR) := ', ';
        l_function_name VARCHAR2(030 CHAR) := 'GET_EPISODE_TRANSFER_SP';
        l_error         t_error_out;
        l_admission     sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'PREV_EPISODE_T596');
    
        l_id_type_admission  CONSTANT VARCHAR2(1 CHAR) := '1';
        l_id_type_location   CONSTANT VARCHAR2(1 CHAR) := '2';
        l_id_type_serv_trans CONSTANT VARCHAR2(1 CHAR) := '3';
        l_id_type_prof_resp  CONSTANT VARCHAR2(1 CHAR) := '4';
        l_id_type_discharge  CONSTANT VARCHAR2(1 CHAR) := '5';
    
    BEGIN
    
        SELECT pk_utils.concat_table_l(CAST(COLLECT(t.description) AS table_varchar), chr(10))
          INTO l_ret
          FROM (SELECT pk_date_utils.date_chr_space_tsz(i_lang, dt_record, i_prof) || l_space || CASE
                            WHEN instr(idtype, l_id_type_admission) > 0 THEN
                             l_admission || l_sep
                            ELSE
                             typedesc || l_sep
                        END || CASE
                            WHEN instr(idtype, l_id_type_admission) > 0
                                 OR instr(idtype, l_id_type_discharge) > 0
                                 OR (instr(idtype, l_id_type_location) > 0 AND instr(idtype, l_id_type_prof_resp) > 0) THEN
                             valuedesc
                            ELSE
                             CASE
                                 WHEN instr(idtype, l_id_type_location) = 0 THEN
                                  pk_bmng.get_pat_location_by_date(i_lang, i_prof, i_id_episode, dt_record)
                                 ELSE
                                  valuedesc
                             END || l_common || CASE
                                 WHEN instr(idtype, l_id_type_prof_resp) = 0 THEN
                                  pk_hand_off.get_prof_resp_list_by_date(i_lang, i_prof, i_id_episode, dt_record)
                                 ELSE
                                  valuedesc
                             END
                        
                        END description,
                       dt_record,
                       idtype
                  FROM (SELECT dt_record,
                               listagg(id_type, '/') within GROUP(ORDER BY rn) idtype,
                               listagg(type_desc, '/') within GROUP(ORDER BY rn) typedesc,
                               listagg(VALUE, l_common) within GROUP(ORDER BY rn) valuedesc
                          FROM (SELECT dt_record,
                                       id_record,
                                       VALUE,
                                       type_desc,
                                       id_type,
                                       row_number() over(PARTITION BY t.dt_record ORDER BY id_type, dt_record) rn
                                  FROM (SELECT a.id_record, a.dt_record, a.value, a. type_desc, a.id_type
                                          FROM TABLE(pk_episode.tf_get_episode_admission(i_lang, i_prof, i_id_episode)) a
                                        UNION ALL
                                        SELECT b.id_record, b.dt_record, b.value, b.type_desc, b.id_type
                                          FROM TABLE(pk_bmng.tf_get_patient_transf_bed(i_lang, i_prof, i_id_episode)) b
                                        UNION ALL
                                        SELECT r.id_record, r.dt_record, r.value, r.type_desc, r.id_type
                                          FROM TABLE(pk_hand_off.tf_get_responsability_transf(i_lang, i_prof, i_id_episode)) r
                                        UNION ALL
                                        SELECT d.id_record, d.dt_record, d.value, d.type_desc, d.id_type
                                          FROM TABLE(pk_discharge.tf_get_episode_discharge(i_lang, i_prof, i_id_episode)) d
                                          JOIN episode e
                                            ON d.id_record = e.id_episode
                                           AND e.flg_status = 'I'
                                         ORDER BY id_type) t)
                         GROUP BY dt_record)) t;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner_name,
                                              i_package  => g_pck_name,
                                              i_function => l_function_name,
                                              o_error    => l_error);
            RETURN NULL;
    END get_episode_transfer_sp;

    PROCEDURE inactivate_epis_tasks IS
    
        CURSOR c_inst IS
            SELECT i.id_institution
              FROM institution i
              JOIN timezone_region tr
                ON tr.id_timezone_region = i.id_timezone_region
             WHERE to_char(current_timestamp at TIME ZONE tr.timezone_region, 'HH24') = '00'
               AND i.flg_available = pk_alert_constant.g_yes;
    
        CURSOR c_lang
        (
            l_prof        NUMBER,
            l_institution NUMBER
        ) IS
            SELECT DISTINCT p.id_language
              FROM prof_preferences p
             WHERE p.id_professional = l_prof
               AND p.id_institution = l_institution;
    
        l_id_inst_tab table_number;
        l_prof        profissional;
        l_lang        language.id_language%TYPE;
    
        l_partial_commit sys_config.value%TYPE;
    
        l_error t_error_out;
        l_exception EXCEPTION;
    
        l_tbl_id_record table_number;
        l_tbl_active    table_varchar;
    
        l_id_config        t_config;
        l_step             NUMBER(24) := 0;
        l_area             VARCHAR2(100 CHAR) := NULL;
        l_step_has_error   BOOLEAN := FALSE;
        l_job_error        BOOLEAN := FALSE;
        l_list_error_steps VARCHAR2(4000 CHAR) := NULL;
    
        l_ids_exclude table_number := table_number();
    
    BEGIN
    
        OPEN c_inst;
        FETCH c_inst BULK COLLECT
            INTO l_id_inst_tab;
        CLOSE c_inst;
    
        --This variable will indicate pk_utils.undo_changes that a rollback should not be executed.
        --This is necessary because whenever there is an error in one of the several apis called by this procedure,
        --pk_utils.undo_changes is usually called, and a rollback would be performed. This rollback would conflict
        --with the SAVEPOINT strategy used in each area.
        pk_context_api.set_parameter('l_undo_on_error', 'N');
    
        FOR i IN l_id_inst_tab.first .. l_id_inst_tab.last
        LOOP
            pk_alertlog.log_info(text            => 'STARTING EXECUTION OF INACTIVATE_EPIS_TASKS FOR INSTITUTION ' ||
                                                    l_id_inst_tab(i),
                                 object_name     => g_pck_name,
                                 sub_object_name => 'INACTIVATE_EPIS_TASKS',
                                 owner           => g_owner_name);
        
            l_step := 10;
        
            l_prof      := profissional(pk_sysconfig.get_config('ID_PROF_BACKGROUND',
                                                                profissional(0, l_id_inst_tab(i), 0)),
                                        l_id_inst_tab(i),
                                        0);
            l_step      := 20;
            l_id_config := pk_core_config.get_config(i_area             => 'INACTIVATE_AREAS',
                                                     i_prof             => l_prof,
                                                     i_market           => pk_core.get_inst_mkt(i_id_institution => l_prof.institution),
                                                     i_category         => NULL,
                                                     i_profile_template => NULL,
                                                     i_prof_dcs         => NULL,
                                                     i_episode_dcs      => NULL);
        
            l_step := 30;
            SELECT a.id_record, a.active
              BULK COLLECT
              INTO l_tbl_id_record, l_tbl_active
              FROM v_inactivate_area_cfg a
             WHERE a.id_config = l_id_config.id_config
               AND a.id_inst_owner = l_id_config.id_inst_owner;
        
            l_step := 40;
            OPEN c_lang(l_prof.id, l_id_inst_tab(i));
            FETCH c_lang
                INTO l_lang;
            CLOSE c_lang;
        
            l_step           := 50;
            l_partial_commit := pk_sysconfig.get_config(i_prof    => l_prof,
                                                        i_code_cf => 'INACTIVATE_TASKS_PARTIAL_COMMIT');
        
            FOR j IN l_tbl_id_record.first .. l_tbl_id_record.last
            LOOP
                BEGIN
                
                    l_area := NULL;
                
                    IF l_tbl_active(j) = pk_alert_constant.g_yes
                    THEN
                    
                        l_ids_exclude := table_number();
                    
                        --Exams
                        CASE l_tbl_id_record(j)
                            WHEN k_exam THEN
                                l_step := 60;
                                l_area := 'EXAMS';
                                pk_alertlog.log_info(text            => 'STARTING EXECUTION FOR STEP ' || l_step || ' (' ||
                                                                        l_area || ').',
                                                     object_name     => g_pck_name,
                                                     sub_object_name => 'INACTIVATE_EPIS_TASKS',
                                                     owner           => g_owner_name);
                                IF NOT pk_exams_external_api_db.inactivate_exams_tasks(i_lang      => l_lang,
                                                                                       i_prof      => l_prof,
                                                                                       i_inst      => l_id_inst_tab(i),
                                                                                       i_flg_type  => NULL,
                                                                                       o_has_error => l_step_has_error,
                                                                                       o_error     => l_error)
                                THEN
                                    RAISE l_exception;
                                END IF;
                            
                        --Procedures
                            WHEN k_procedures THEN
                                l_step := 70;
                                l_area := 'PROCEDURES';
                                pk_alertlog.log_info(text            => 'STARTING EXECUTION FOR STEP ' || l_step || ' (' ||
                                                                        l_area || ').',
                                                     object_name     => g_pck_name,
                                                     sub_object_name => 'INACTIVATE_EPIS_TASKS',
                                                     owner           => g_owner_name);
                                IF NOT
                                    pk_procedures_external_api_db.inactivate_procedures_tasks(i_lang      => l_lang,
                                                                                              i_prof      => l_prof,
                                                                                              i_inst      => l_id_inst_tab(i),
                                                                                              o_has_error => l_step_has_error,
                                                                                              o_error     => l_error)
                                THEN
                                    RAISE l_exception;
                                END IF;
                            
                        --Lab Test
                            WHEN k_lab_test THEN
                                l_step := 80;
                                l_area := 'LAB TESTS';
                                pk_alertlog.log_info(text            => 'STARTING EXECUTION FOR STEP ' || l_step || ' (' ||
                                                                        l_area || ').',
                                                     object_name     => g_pck_name,
                                                     sub_object_name => 'INACTIVATE_EPIS_TASKS',
                                                     owner           => g_owner_name);
                                IF NOT
                                    pk_lab_tests_external_api_db.inactivate_lab_tests_tasks(i_lang      => l_lang,
                                                                                            i_prof      => l_prof,
                                                                                            i_inst      => l_id_inst_tab(i),
                                                                                            o_has_error => l_step_has_error,
                                                                                            o_error     => l_error)
                                THEN
                                    RAISE l_exception;
                                END IF;
                            
                        --Diet
                            WHEN k_diet THEN
                                l_step := 90;
                                l_area := 'DIET';
                                pk_alertlog.log_info(text            => 'STARTING EXECUTION FOR STEP ' || l_step || ' (' ||
                                                                        l_area || ').',
                                                     object_name     => g_pck_name,
                                                     sub_object_name => 'INACTIVATE_EPIS_TASKS',
                                                     owner           => g_owner_name);
                                IF NOT pk_diet_api_db.inactivate_diet_tasks(i_lang      => l_lang,
                                                                            i_prof      => l_prof,
                                                                            i_inst      => l_id_inst_tab(i),
                                                                            o_has_error => l_step_has_error,
                                                                            o_error     => l_error)
                                THEN
                                    RAISE l_exception;
                                END IF;
                            
                        --Patient Education
                            WHEN k_pat_educ THEN
                                l_step := 100;
                                l_area := 'PATIENT EDUCATION';
                                pk_alertlog.log_info(text            => 'STARTING EXECUTION FOR STEP ' || l_step || ' (' ||
                                                                        l_area || ').',
                                                     object_name     => g_pck_name,
                                                     sub_object_name => 'INACTIVATE_EPIS_TASKS',
                                                     owner           => g_owner_name);
                                IF NOT
                                    pk_patient_education_api_db.inactivate_pat_educ_tasks(i_lang        => l_lang,
                                                                                          i_prof        => l_prof,
                                                                                          i_inst        => l_id_inst_tab(i),
                                                                                          i_ids_exclude => l_ids_exclude,
                                                                                          o_has_error   => l_step_has_error,
                                                                                          o_error       => l_error)
                                THEN
                                    RAISE l_exception;
                                END IF;
                            
                        --Comm Orders
                            WHEN k_comm_orders THEN
                                l_step := 110;
                                l_area := 'COMMUNICATION ORDERS';
                                pk_alertlog.log_info(text            => 'STARTING EXECUTION FOR STEP ' || l_step || ' (' ||
                                                                        l_area || ').',
                                                     object_name     => g_pck_name,
                                                     sub_object_name => 'INACTIVATE_EPIS_TASKS',
                                                     owner           => g_owner_name);
                                IF NOT pk_comm_orders_db.inactivate_comm_order_tasks(i_lang      => l_lang,
                                                                                     i_prof      => l_prof,
                                                                                     i_inst      => l_id_inst_tab(i),
                                                                                     o_has_error => l_step_has_error,
                                                                                     o_error     => l_error)
                                THEN
                                    RAISE l_exception;
                                END IF;
                            
                        --Positionings
                            WHEN k_positioning THEN
                                l_step := 120;
                                l_area := 'POSITIONINGS';
                                pk_alertlog.log_info(text            => 'STARTING EXECUTION FOR STEP ' || l_step || ' (' ||
                                                                        l_area || ').',
                                                     object_name     => g_pck_name,
                                                     sub_object_name => 'INACTIVATE_EPIS_TASKS',
                                                     owner           => g_owner_name);
                                IF NOT pk_inp_positioning.inactivate_positioning_tasks(i_lang        => l_lang,
                                                                                       i_prof        => l_prof,
                                                                                       i_inst        => l_id_inst_tab(i),
                                                                                       i_ids_exclude => l_ids_exclude,
                                                                                       o_has_error   => l_step_has_error,
                                                                                       o_error       => l_error)
                                THEN
                                    RAISE l_exception;
                                END IF;
                            
                        --NNN
                            WHEN k_nnn THEN
                                l_step := 130;
                                l_area := 'NNN';
                                pk_alertlog.log_info(text            => 'STARTING EXECUTION FOR STEP ' || l_step || ' (' ||
                                                                        l_area || ').',
                                                     object_name     => g_pck_name,
                                                     sub_object_name => 'INACTIVATE_EPIS_TASKS',
                                                     owner           => g_owner_name);
                                IF NOT pk_nnn_api_db.inactivate_nnn_tasks(i_lang      => l_lang,
                                                                          i_prof      => l_prof,
                                                                          i_inst      => l_id_inst_tab(i),
                                                                          o_has_error => l_step_has_error,
                                                                          o_error     => l_error)
                                THEN
                                    RAISE l_exception;
                                END IF;
                            
                        --Monitorization
                            WHEN k_monit THEN
                                l_step := 140;
                                l_area := 'MONITORIZATIONS';
                                pk_alertlog.log_info(text            => 'STARTING EXECUTION FOR STEP ' || l_step || ' (' ||
                                                                        l_area || ').',
                                                     object_name     => g_pck_name,
                                                     sub_object_name => 'INACTIVATE_EPIS_TASKS',
                                                     owner           => g_owner_name);
                                IF NOT pk_monitorization.inactivate_monitorztn_tasks(i_lang        => l_lang,
                                                                                     i_prof        => l_prof,
                                                                                     i_inst        => l_id_inst_tab(i),
                                                                                     i_ids_exclude => l_ids_exclude,
                                                                                     o_has_error   => l_step_has_error,
                                                                                     o_error       => l_error)
                                THEN
                                    RAISE l_exception;
                                END IF;
                            
                        --Hidrics
                            WHEN k_hidrics THEN
                                l_step := 150;
                                l_area := 'HIDRICS';
                                pk_alertlog.log_info(text            => 'STARTING EXECUTION FOR STEP ' || l_step || ' (' ||
                                                                        l_area || ').',
                                                     object_name     => g_pck_name,
                                                     sub_object_name => 'INACTIVATE_EPIS_TASKS',
                                                     owner           => g_owner_name);
                                IF NOT pk_inp_hidrics_pbl.inactivate_hidrics_tasks(i_lang      => l_lang,
                                                                                   i_prof      => l_prof,
                                                                                   i_inst      => l_id_inst_tab(i),
                                                                                   o_has_error => l_step_has_error,
                                                                                   o_error     => l_error)
                                THEN
                                    RAISE l_exception;
                                END IF;
                            
                        --ICNP
                            WHEN k_icnp THEN
                                l_step := 160;
                                l_area := 'ICNP';
                                pk_alertlog.log_info(text            => 'STARTING EXECUTION FOR STEP ' || l_step || ' (' ||
                                                                        l_area || ').',
                                                     object_name     => g_pck_name,
                                                     sub_object_name => 'INACTIVATE_EPIS_TASKS',
                                                     owner           => g_owner_name);
                                IF NOT pk_icnp_fo_api_db.inactivate_icnp_tasks(i_lang        => l_lang,
                                                                               i_prof        => l_prof,
                                                                               i_inst        => l_id_inst_tab(i),
                                                                               i_ids_exclude => l_ids_exclude,
                                                                               o_has_error   => l_step_has_error,
                                                                               o_error       => l_error)
                                THEN
                                    RAISE l_exception;
                                END IF;
                            
                        --Medication
                            WHEN k_medication THEN
                                l_step := 170;
                                l_area := 'MEDICATION';
                                pk_alertlog.log_info(text            => 'STARTING EXECUTION FOR STEP ' || l_step || ' (' ||
                                                                        l_area || ').',
                                                     object_name     => g_pck_name,
                                                     sub_object_name => 'INACTIVATE_EPIS_TASKS',
                                                     owner           => g_owner_name);
                                IF NOT pk_api_pfh_in.inactivate_presc_tasks(i_lang      => l_lang,
                                                                            i_prof      => l_prof,
                                                                            i_inst      => l_id_inst_tab(i),
                                                                            o_has_error => l_step_has_error,
                                                                            o_error     => l_error)
                                THEN
                                    RAISE l_exception;
                                END IF;
                            
                        --Dispense Pharmacy
                            WHEN k_pharmacy THEN
                                l_step := 180;
                                l_area := 'PHARMACY';
                                pk_alertlog.log_info(text            => 'STARTING EXECUTION FOR STEP ' || l_step || ' (' ||
                                                                        l_area || ').',
                                                     object_name     => g_pck_name,
                                                     sub_object_name => 'INACTIVATE_EPIS_TASKS',
                                                     owner           => g_owner_name);
                                IF NOT pk_api_pfh_in.inactivate_pharm_dispense(i_lang      => l_lang,
                                                                               i_prof      => l_prof,
                                                                               i_inst      => l_id_inst_tab(i),
                                                                               o_has_error => l_step_has_error,
                                                                               o_error     => l_error)
                                THEN
                                    RAISE l_exception;
                                END IF;
                            
                        --Rehab
                            WHEN k_rehab THEN
                                l_step := 190;
                                l_area := 'REHABILITATION';
                                pk_alertlog.log_info(text            => 'STARTING EXECUTION FOR STEP ' || l_step || ' (' ||
                                                                        l_area || ').',
                                                     object_name     => g_pck_name,
                                                     sub_object_name => 'INACTIVATE_EPIS_TASKS',
                                                     owner           => g_owner_name);
                                IF NOT pk_rehab_external_api_db.inactivate_rehab_tasks(i_lang      => l_lang,
                                                                                       i_prof      => l_prof,
                                                                                       i_inst      => l_id_inst_tab(i),
                                                                                       o_has_error => l_step_has_error,
                                                                                       o_error     => l_error)
                                THEN
                                    RAISE l_exception;
                                END IF;
                            
                        --Consultas
                            WHEN k_appoitments THEN
                                l_step := 200;
                                l_area := 'APPOINTMENTS';
                                pk_alertlog.log_info(text            => 'STARTING EXECUTION FOR STEP ' || l_step || ' (' ||
                                                                        l_area || ').',
                                                     object_name     => g_pck_name,
                                                     sub_object_name => 'INACTIVATE_EPIS_TASKS',
                                                     owner           => g_owner_name);
                                IF NOT pk_consult_req.inactivate_consult_req(i_lang        => l_lang,
                                                                             i_prof        => l_prof,
                                                                             i_inst        => l_id_inst_tab(i),
                                                                             i_ids_exclude => l_ids_exclude,
                                                                             o_has_error   => l_step_has_error,
                                                                             o_error       => l_error)
                                
                                THEN
                                    RAISE l_exception;
                                END IF;
                            
                        --Oppinion (Follow-up requests)
                            WHEN k_opinion THEN
                                l_step := 210;
                                l_area := 'OPINION';
                                pk_alertlog.log_info(text            => 'STARTING EXECUTION FOR STEP ' || l_step || ' (' ||
                                                                        l_area || ').',
                                                     object_name     => g_pck_name,
                                                     sub_object_name => 'INACTIVATE_EPIS_TASKS',
                                                     owner           => g_owner_name);
                                IF NOT pk_opinion.inactivate_opinion(i_lang        => l_lang,
                                                                     i_prof        => l_prof,
                                                                     i_inst        => l_id_inst_tab(i),
                                                                     i_ids_exclude => l_ids_exclude,
                                                                     o_has_error   => l_step_has_error,
                                                                     o_error       => l_error)
                                
                                THEN
                                    RAISE l_exception;
                                END IF;
                            
                        --Inpatient admission
                            WHEN k_inpatient_admission THEN
                                l_step := 220;
                                l_area := 'INPATIENT ADMISSION';
                                pk_alertlog.log_info(text            => 'STARTING EXECUTION FOR STEP ' || l_step || ' (' ||
                                                                        l_area || ').',
                                                     object_name     => g_pck_name,
                                                     sub_object_name => 'INACTIVATE_EPIS_TASKS',
                                                     owner           => g_owner_name);
                                IF NOT pk_admission_request.inactivate_inpatient_admission(i_lang        => l_lang,
                                                                                           i_prof        => l_prof,
                                                                                           i_inst        => l_id_inst_tab(i),
                                                                                           i_ids_exclude => l_ids_exclude,
                                                                                           o_has_error   => l_step_has_error,
                                                                                           o_error       => l_error)
                                
                                THEN
                                    RAISE l_exception;
                                END IF;
                            
                        --Surgery admission
                            WHEN k_surgery_admission THEN
                                l_step := 230;
                                l_area := 'SURGERY ADMISSION';
                                pk_alertlog.log_info(text            => 'STARTING EXECUTION FOR STEP ' || l_step || ' (' ||
                                                                        l_area || ').',
                                                     object_name     => g_pck_name,
                                                     sub_object_name => 'INACTIVATE_EPIS_TASKS',
                                                     owner           => g_owner_name);
                                IF NOT pk_sr_grid.inactivate_surgery_admission(i_lang        => l_lang,
                                                                               i_prof        => l_prof,
                                                                               i_inst        => l_id_inst_tab(i),
                                                                               i_ids_exclude => l_ids_exclude,
                                                                               o_has_error   => l_step_has_error,
                                                                               o_error       => l_error)
                                
                                THEN
                                    RAISE l_exception;
                                END IF;
                                --Supplies
                            WHEN k_procedures THEN
                                l_step := 231;
                                l_area := 'SUPPLIES';
                                pk_alertlog.log_info(text            => 'STARTING EXECUTION FOR STEP ' || l_step || ' (' ||
                                                                        l_area || ').',
                                                     object_name     => g_pck_name,
                                                     sub_object_name => 'INACTIVATE_EPIS_TASKS',
                                                     owner           => g_owner_name);
                                IF NOT pk_supplies_external_api_db.inactivate_supplies_tasks(i_lang      => l_lang,
                                                                                             i_prof      => l_prof,
                                                                                             i_inst      => l_id_inst_tab(i),
                                                                                             o_has_error => l_step_has_error,
                                                                                             o_error     => l_error)
                                THEN
                                    RAISE l_exception;
                                END IF;
                            ELSE
                                NULL;
                        END CASE;
                    END IF;
                
                    --Each step indicates if there was an error
                    --If there's an error, the loop's exception must be raised in order to force the CONTINUE
                    --and l_step_has_error is reset for the next step
                    IF l_step_has_error = TRUE
                    THEN
                        l_job_error        := TRUE;
                        l_list_error_steps := l_list_error_steps || chr(10) || 'INSTITUTION: ' || l_id_inst_tab(i) ||
                                              ' - STEP: ' || l_step || ' - LCALL: ' || l_error.log_id;
                    
                        l_step_has_error := FALSE;
                    
                        RAISE l_exception;
                    ELSIF l_step_has_error = FALSE
                          AND l_area IS NOT NULL
                    THEN
                        --If no error has been detected while processing a step, a log message is generated.
                        --PK_EPISODE must be configured with level 50 in log_obj and/or log_group to see this log                    
                        pk_alertlog.log_info(text            => 'STEP ' || l_step || ' (' || l_area ||
                                                                ') EXECUTED SUCCESSFULLY.',
                                             object_name     => g_pck_name,
                                             sub_object_name => 'INACTIVATE_EPIS_TASKS',
                                             owner           => g_owner_name);
                    
                    END IF;
                
                    IF l_partial_commit = pk_alert_constant.g_yes
                    THEN
                        l_step := 240;
                        COMMIT;
                    END IF;
                
                EXCEPTION
                    WHEN OTHERS THEN
                        --When the exception is raised, a log is generated stating which step has raised the error
                        pk_alert_exceptions.reset_error_state;
                        g_error := 'ERROR (STEP-' || l_step || ' - ' || l_area || ') (ID_RECORD-' || l_tbl_id_record(j) ||
                                   ') (INST-' || l_id_inst_tab(i) || ')';
                        pk_alert_exceptions.process_error(l_lang,
                                                          SQLCODE,
                                                          SQLERRM,
                                                          g_error,
                                                          'ALERT',
                                                          'PK_EPISODE',
                                                          'INACTIVATE_EPIS_TASKS',
                                                          l_error);
                        pk_alert_exceptions.reset_error_state;
                    
                        --If an error was detected, it means that at least one record of the step WAS NOT inactivated, however,
                        --several other records may have been correctly inactivated, therefore, a commit should be performed.
                        --If a rollback would be performed instead of the commit, once an error would be detected for a specific step,
                        --no more records would ever be inactivated (even if the job is executed afterwards).
                        IF l_partial_commit = pk_alert_constant.g_yes
                        THEN
                            COMMIT;
                        END IF;
                    
                        --A continue must then be executed, otherwise, if an error would be detected for a step, the remaining steps 
                        --would never be executed (even if the job is executed afterwards).
                        CONTINUE;
                END;
            END LOOP;
            pk_alertlog.log_info(text            => 'EXECUTION OF INACTIVATE_EPIS_TASKS ENDED FOR INSTITUTION ' ||
                                                    l_id_inst_tab(i),
                                 object_name     => g_pck_name,
                                 sub_object_name => 'INACTIVATE_EPIS_TASKS',
                                 owner           => g_owner_name);
        END LOOP;
    
        IF l_partial_commit = pk_alert_constant.g_no
        THEN
            l_step := 250;
            COMMIT;
        END IF;
    
        --When the job ends its execution, if an error has been detected in any of the steps, an exception must be raised
        --in order to log the error in user_scheduler_job_run_details
        IF l_job_error = TRUE
        THEN
            RAISE l_exception;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001,
                                    'PROCEDURE INACTIVATE_EPIS_TASKS HAS FOUND ERRORS FOR THE FOLLOWING TASKS:' ||
                                    l_list_error_steps);
    END inactivate_epis_tasks;

    FUNCTION get_episode_summary_default_it
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_send_id_req IN BOOLEAN,
        o_default     OUT VARCHAR2,
        o_filter      OUT table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_epis_type episode.id_epis_type%TYPE;
        l_exception EXCEPTION;
        k_default_all_services CONSTANT VARCHAR2(2 CHAR) := 'TE';
    BEGIN
        -- in cases of a HHC record in a sw that is not the HHC
        IF (i_send_id_req)
        THEN
            o_default := k_default_all_services;
        ELSE
            g_error   := 'GET CONFIGURATIONS';
            o_default := pk_sysconfig.get_config('EPISODE_SUMMARY_DEFAULT_IT', i_prof);
        END IF;
    
        IF NOT pk_episode.get_epis_type(i_lang      => i_lang,
                                        i_id_epis   => i_id_episode,
                                        o_epis_type => l_epis_type,
                                        o_error     => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        IF l_epis_type = pk_hhc_constant.k_hhc_epis_type
        THEN
            o_filter := table_varchar(g_prev_app_all_specs_te);
        ELSE
            o_filter := table_varchar(g_prev_app_with_me_c,
                                      g_prev_app_this_spec_t,
                                      g_prev_app_other_spec_e,
                                      g_prev_app_all_specs_te);
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            RETURN FALSE;
    END get_episode_summary_default_it;

    FUNCTION get_language_by_epis(i_epis episode.id_episode%TYPE) RETURN NUMBER IS
        l_ret institution_language.id_language%TYPE;
    BEGIN
        SELECT DISTINCT il.id_language
          INTO l_ret
          FROM episode e
         INNER JOIN institution_language il
            ON e.id_institution = il.id_institution
         WHERE e.id_episode = i_epis
           AND rownum = 1;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_language_by_epis;

    FUNCTION get_institution_by_epis(i_epis episode.id_episode%TYPE) RETURN NUMBER IS
        l_ret episode.id_institution%TYPE;
    BEGIN
        SELECT e.id_institution
          INTO l_ret
          FROM episode e
         WHERE e.id_episode = i_epis;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_institution_by_epis;

    /************************************************************************************************************
    * This function returns episode professional
    *
    * @param i_lang          Language ID
    * @param i_prof          Professional   
    * @param i_episode       Episode Id
    *
    * @return     professional Id
    *
    * @author     Sofia Mendes
    * @version    2.6.7
    * @since      23-Mai-2018
    ************************************************************************************************************/
    FUNCTION get_epis_prof
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN epis_info.id_professional%TYPE IS
    
        l_id_prof       epis_info.id_professional%TYPE;
        l_responsibles  table_number := table_number();
        l_hand_off_type sys_config.value%TYPE;
    
    BEGIN
    
        g_error := 'GET episode id_professional. i_episode: ' || i_episode;
        SELECT ei.id_professional
          INTO l_id_prof
          FROM epis_info ei
         WHERE ei.id_episode = i_episode;
    
        IF l_id_prof IS NULL
        THEN
            g_error := 'GET TYPE OF HAND-OFF';
            pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
        
            -- Get all episode responsibles of the current category
            g_error        := 'GET LIST OF RESPONSIBLES ID';
            l_responsibles := pk_hand_off_core.get_responsibles_id(i_lang          => i_lang,
                                                                   i_prof          => i_prof,
                                                                   i_id_episode    => i_episode,
                                                                   i_prof_cat      => pk_alert_constant.g_cat_type_doc,
                                                                   i_hand_off_type => l_hand_off_type,
                                                                   i_my_patients   => pk_alert_constant.g_no);
            l_id_prof      := l_responsibles(1);
        END IF;
    
        RETURN l_id_prof;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_epis_prof;

    FUNCTION get_previous_visit
    (
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_epis_type IN episode.id_epis_type%TYPE
    ) RETURN episode.id_visit%TYPE IS
        l_id_patient    episode.id_patient%TYPE;
        l_id_visit_prev episode.id_visit%TYPE;
        l_id_visit      episode.id_visit%TYPE;
    BEGIN
        l_id_patient := get_id_patient(i_episode => i_id_episode);
        l_id_visit   := get_id_visit(i_episode => i_id_episode);
    
        SELECT t.id_visit_prev
          INTO l_id_visit_prev
          FROM (SELECT v.id_visit,
                       v.dt_begin_tstz,
                       lead(v.id_visit, 1, NULL) over(ORDER BY v.dt_begin_tstz DESC) id_visit_prev
                  FROM visit v
                 WHERE v.flg_status <> pk_alert_constant.g_cancelled
                   AND v.id_patient = l_id_patient
                   AND (EXISTS (SELECT 1
                                  FROM episode epis
                                 WHERE epis.id_visit = v.id_visit
                                   AND epis.flg_ehr = pk_alert_constant.g_flg_ehr_n
                                   AND epis.flg_status <> pk_alert_constant.g_cancelled
                                   AND epis.id_epis_type = i_id_epis_type))
                    OR v.id_visit = l_id_visit) t
         WHERE t.id_visit = l_id_visit;
    
        RETURN l_id_visit_prev;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
        WHEN OTHERS THEN
            RETURN NULL;
    END get_previous_visit;

    PROCEDURE get_etsi_cfg_vars
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        o_inst OUT institution.id_institution%TYPE
    ) IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_ETSI_CFG_VARS';
    BEGIN
    
        BEGIN
            g_error := 'GET EPIS_TYPS_SOFT_INST CFG_VARS';
            pk_alertlog.log_debug(g_error);
            SELECT id_institution
              INTO o_inst
              FROM (SELECT etsi.id_institution,
                           row_number() over(ORDER BY --
                           decode(etsi.id_institution, i_prof.institution, 1, 2)) line_number
                      FROM epis_type_soft_inst etsi
                     WHERE etsi.id_software IN (i_prof.software)
                       AND etsi.id_institution IN (pk_alert_constant.g_inst_all, i_prof.institution))
             WHERE line_number = 1;
        
        EXCEPTION
            WHEN no_data_found THEN
            
                o_inst := i_prof.institution;
            
        END;
    END get_etsi_cfg_vars;

    FUNCTION get_epis_type_access
    (
        i_prof        IN profissional,
        i_include_all IN VARCHAR2 DEFAULT pk_alert_constant.g_yes
    ) RETURN table_number IS
        l_et_access        table_number := table_number();
        l_profile_template profile_template.id_profile_template%TYPE;
    BEGIN
    
        l_profile_template := pk_prof_utils.get_prof_profile_template(i_prof);
    
        -- get local accesses to epis_types
        -- using all institutions in group
        g_error := 'SELECT l_et_access';
        SELECT DISTINCT id_epis_type
          BULK COLLECT
          INTO l_et_access
          FROM (SELECT eta.id_epis_type,
                       dense_rank() over(PARTITION BY id_epis_type ORDER BY id_institution ASC, id_profile_template, id_software) rn
                  FROM epis_type_access eta
                 WHERE eta.id_institution IN (i_prof.institution, pk_alert_constant.g_inst_all)
                   AND flg_add_remove = pk_alert_constant.g_flg_add
                   AND eta.id_profile_template IN (l_profile_template, pk_alert_constant.g_profile_template_all)
                   AND NOT EXISTS
                 (SELECT 1
                          FROM epis_type_access eta1
                         WHERE eta1.id_institution = i_prof.institution
                           AND eta1.flg_add_remove = pk_alert_constant.g_flg_rem
                           AND eta1.id_epis_type = eta.id_epis_type
                           AND eta1.id_profile_template IN (l_profile_template, pk_alert_constant.g_profile_template_all))
                   AND ((eta.id_epis_type <> 0 AND i_include_all = pk_alert_constant.g_no) OR
                       i_include_all = pk_alert_constant.g_yes)
                   AND id_software IN (i_prof.software, pk_alert_constant.g_soft_all));
    
        RETURN l_et_access;
    
    END get_epis_type_access;

    FUNCTION get_episode_info
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_schedule IN schedule.id_schedule%TYPE,
        o_info     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name           VARCHAR2(30 CHAR) := 'GET_EPISODE_INFO';
        l_schdl_outp_state_domain sys_domain.code_domain%TYPE := 'SCHEDULE_OUTP.FLG_STATE';
        l_hand_off_type           sys_config.value%TYPE;
        l_prof_cat                category.flg_type%TYPE;
    BEGIN
        l_prof_cat := pk_edis_list.get_prof_cat(i_prof);
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
    
        IF i_prof.software = pk_alert_constant.g_soft_edis
        THEN
            OPEN o_info FOR
                SELECT epis.id_episode,
                       decode(pk_prof_follow.get_follow_episode_by_me(i_prof, epis.id_episode, -1),
                              pk_alert_constant.g_no,
                              decode(pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                                      i_prof,
                                                                                                      epis.id_episode,
                                                                                                      l_prof_cat,
                                                                                                      l_hand_off_type,
                                                                                                      pk_alert_constant.g_yes),
                                                                  i_prof.id),
                                     -1,
                                     pk_alert_constant.g_yes,
                                     pk_alert_constant.g_no),
                              pk_alert_constant.g_no) prof_follow_add,
                       pk_prof_follow.get_follow_episode_by_me(i_prof, epis.id_episode, -1) prof_follow_remove --, 
                --  null name_pat
                  FROM episode epis
                 WHERE id_episode = i_episode;
        
        ELSIF i_prof.software = pk_alert_constant.g_soft_oris
        THEN
            OPEN o_info FOR
                SELECT s.id_schedule,
                       e.id_episode,
                       rec.flg_pat_status,
                       pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof) dt_server,
                       pk_sysdomain.get_img(i_lang,
                                            'SR_SURGERY_ROOM.FLG_PAT_STATUS',
                                            nvl(rec.flg_pat_status, pk_sr_visit.g_flg_pat_status_pend)) pat_status,
                       nvl(rec.flg_pat_status, pk_sr_visit.g_flg_pat_status_pend) pat_status_det,
                       pk_episode.get_epis_room(i_lang, i_prof, e.id_episode) desc_room,
                       decode(pk_prof_follow.get_follow_episode_by_me(i_prof, e.id_episode, s.id_schedule),
                              pk_alert_constant.g_no,
                              decode(pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                                      i_prof,
                                                                                                      e.id_episode,
                                                                                                      l_prof_cat,
                                                                                                      l_hand_off_type,
                                                                                                      pk_alert_constant.g_yes),
                                                                  i_prof.id),
                                     -1,
                                     pk_alert_constant.g_yes,
                                     pk_alert_constant.g_no),
                              pk_alert_constant.g_no) prof_follow_add,
                       pk_prof_follow.get_follow_episode_by_me(i_prof, e.id_episode, s.id_schedule) prof_follow_remove
                  FROM episode e
                  JOIN schedule_sr sr
                    ON sr.id_episode = e.id_episode
                  JOIN schedule s
                    ON sr.id_schedule = s.id_schedule
                  LEFT JOIN sr_surgery_record rec
                    ON sr.id_schedule_sr = rec.id_schedule_sr
                 WHERE e.id_episode = i_episode;
        ELSIF i_prof.software = pk_alert_constant.g_soft_home_care
        THEN
            OPEN o_info FOR
                SELECT s.id_schedule,
                       e.id_episode,
                       e.flg_ehr,
                       CASE
                            WHEN ei.id_episode IS NOT NULL THEN
                             CASE
                                 WHEN pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) = 'A' THEN
                                  ''
                                 ELSE
                                  pk_date_utils.date_char_hour_tsz(i_lang,
                                                                   e.dt_begin_tstz,
                                                                   i_prof.institution,
                                                                   i_prof.software)
                             END
                            ELSE
                            
                             ''
                        END dt_efectiv,
                       pk_sysdomain.get_img(i_lang,
                                            l_schdl_outp_state_domain,
                                            pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr)) img_state,
                       pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof) dt_server,
                       pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) flg_state,
                       pk_sysdomain.get_rank(i_lang,
                                             l_schdl_outp_state_domain,
                                             pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr)) img_state_rank,
                       pk_sysdomain.get_domain(i_code_dom => l_schdl_outp_state_domain,
                                               i_val      => pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                               i_lang     => i_lang) img_state_desc,
                       sg.flg_contact_type,
                       pk_sysdomain.get_img(i_lang, 'SCH_GROUP.FLG_CONTACT_TYPE', sg.flg_contact_type) icon_contact_type,
                       pk_sysdomain.get_domain('SCH_GROUP.FLG_CONTACT_TYPE', sg.flg_contact_type, i_lang) presence_desc,
                       decode(pk_prof_follow.get_follow_episode_by_me(i_prof, ei.id_episode, ei.id_schedule),
                              pk_alert_constant.g_no,
                              decode(pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                                      i_prof,
                                                                                                      ei.id_episode,
                                                                                                      l_prof_cat,
                                                                                                      l_hand_off_type,
                                                                                                      pk_alert_constant.g_yes),
                                                                  i_prof.id),
                                     -1,
                                     pk_alert_constant.g_yes,
                                     pk_alert_constant.g_no),
                              pk_alert_constant.g_no) prof_follow_add,
                       pk_prof_follow.get_follow_episode_by_me(i_prof, ei.id_episode, ei.id_schedule) prof_follow_remove
                  FROM schedule s
                  JOIN schedule_outp sp
                    ON s.id_schedule = sp.id_schedule
                  JOIN sch_group sg
                    ON s.id_schedule = sg.id_schedule
                  JOIN epis_info ei
                    ON s.id_schedule = ei.id_schedule
                  JOIN episode e
                    ON e.id_episode = ei.id_episode
                 WHERE (s.id_schedule = i_schedule OR e.id_episode = i_episode);
        
        ELSIF i_prof.software IN (pk_alert_constant.g_soft_social,
                                  pk_alert_constant.g_soft_nutritionist,
                                  pk_alert_constant.g_soft_resptherap,
                                  pk_alert_constant.g_soft_psychologist)
        THEN
        
            OPEN o_info FOR
                SELECT s.id_schedule,
                       e.id_episode,
                       e.flg_ehr,
                       CASE
                            WHEN pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) = 'A' THEN
                             ''
                            ELSE
                             pk_date_utils.date_char_hour_tsz(i_lang,
                                                              e.dt_begin_tstz,
                                                              i_prof.institution,
                                                              i_prof.software)
                        END dt_efectiv,
                       CASE
                            WHEN e.id_epis_type = 50
                                 AND sp.flg_state = 'M' THEN
                             pk_sysdomain.get_img(i_lang,
                                                  'SCHEDULE_OUTP.FLG_STATE',
                                                  pk_grid.get_schedule_real_state('X', e.flg_ehr))
                            ELSE
                             pk_sysdomain.get_img(i_lang,
                                                  'SCHEDULE_OUTP.FLG_STATE',
                                                  pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr))
                        END img_state,
                       pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof) dt_server,
                       decode(e.flg_status, 'C', 'C', pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr)) flg_state,
                       /*   pk_sysdomain.get_rank(i_lang,
                                             l_schdl_outp_state_domain,
                                             pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr)) img_state_rank,
                       pk_sysdomain.get_domain(i_code_dom => l_schdl_outp_state_domain,
                                               i_val      => pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                               i_lang     => i_lang) img_state_desc,*/
                       sg.flg_contact_type,
                       pk_sysdomain.get_img(i_lang, 'SCH_GROUP.FLG_CONTACT_TYPE', sg.flg_contact_type) icon_contact_type,
                       --     pk_sysdomain.get_domain('SCH_GROUP.FLG_CONTACT_TYPE', sg.flg_contact_type, i_lang) presence_desc,
                       decode(pk_prof_follow.get_follow_episode_by_me(i_prof, ei.id_episode, ei.id_schedule),
                              pk_alert_constant.g_no,
                              decode(pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                                      i_prof,
                                                                                                      ei.id_episode,
                                                                                                      l_prof_cat,
                                                                                                      l_hand_off_type,
                                                                                                      pk_alert_constant.g_yes),
                                                                  i_prof.id),
                                     -1,
                                     pk_alert_constant.g_yes,
                                     pk_alert_constant.g_no),
                              pk_alert_constant.g_no) prof_follow_add,
                       pk_prof_follow.get_follow_episode_by_me(i_prof, ei.id_episode, ei.id_schedule) prof_follow_remove
                  FROM schedule s
                  JOIN schedule_outp sp
                    ON s.id_schedule = sp.id_schedule
                  JOIN sch_group sg
                    ON s.id_schedule = sg.id_schedule
                  JOIN epis_info ei
                    ON s.id_schedule = ei.id_schedule
                  JOIN episode e
                    ON e.id_episode = ei.id_episode
                 WHERE (s.id_schedule = i_schedule OR e.id_episode = i_episode);
        ELSE
        
            OPEN o_info FOR
                SELECT s.id_schedule,
                       e.id_episode,
                       e.flg_ehr,
                       pk_sysdomain.get_img(i_lang,
                                            l_schdl_outp_state_domain,
                                            pk_grid.get_pre_nurse_appointment(i_lang,
                                                                              i_prof,
                                                                              ei.id_dep_clin_serv,
                                                                              e.flg_ehr,
                                                                              pk_grid.get_schedule_real_state(sp.flg_state,
                                                                                                              e.flg_ehr))) img_state,
                       CASE
                            WHEN e.flg_ehr = 'S' THEN
                             NULL
                            WHEN sg.flg_contact_type IN ('V', 'P') THEN
                             NULL
                            WHEN sg.flg_contact_type IN ('D') THEN
                             pk_grid_amb.get_room_desc(i_lang, ei.id_room)
                        END desc_room,
                       CASE
                            WHEN ei.id_episode IS NOT NULL THEN
                             CASE
                                 WHEN pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) = 'A' THEN
                                  ''
                                 ELSE
                                  pk_date_utils.date_char_hour_tsz(i_lang,
                                                                   e.dt_begin_tstz,
                                                                   i_prof.institution,
                                                                   i_prof.software)
                             END
                            ELSE
                            
                             ''
                        END dt_efectiv,
                       pk_date_utils.date_char_tsz(i_lang, sp.dt_target_tstz, i_prof.institution, i_prof.software) dt_schedule_begin,
                       pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof) dt_server,
                       pk_grid.get_pre_nurse_appointment(i_lang,
                                                         i_prof,
                                                         ei.id_dep_clin_serv,
                                                         e.flg_ehr,
                                                         pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr)) flg_state,
                       ei.id_room epis_id_room,
                       pk_date_utils.date_send_tsz(i_lang, e.dt_begin_tstz, i_prof.institution, i_prof.software) dt_begin,
                       e.flg_status epis_status,
                       pk_sysdomain.get_rank(i_lang,
                                             l_schdl_outp_state_domain,
                                             pk_grid.get_pre_nurse_appointment(i_lang,
                                                                               i_prof,
                                                                               ei.id_dep_clin_serv,
                                                                               e.flg_ehr,
                                                                               pk_grid.get_schedule_real_state(sp.flg_state,
                                                                                                               e.flg_ehr))) img_state_rank,
                       decode(pk_prof_follow.get_follow_episode_by_me(i_prof, ei.id_episode, ei.id_schedule),
                              pk_alert_constant.g_no,
                              decode(pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                                      i_prof,
                                                                                                      ei.id_episode,
                                                                                                      l_prof_cat,
                                                                                                      l_hand_off_type,
                                                                                                      pk_alert_constant.g_yes),
                                                                  i_prof.id),
                                     -1,
                                     pk_alert_constant.g_yes,
                                     pk_alert_constant.g_no),
                              pk_alert_constant.g_no) prof_follow_add,
                       pk_prof_follow.get_follow_episode_by_me(i_prof, ei.id_episode, ei.id_schedule) prof_follow_remove
                  FROM schedule s
                  JOIN schedule_outp sp
                    ON s.id_schedule = sp.id_schedule
                  JOIN sch_group sg
                    ON s.id_schedule = sg.id_schedule
                  JOIN epis_info ei
                    ON s.id_schedule = ei.id_schedule
                  JOIN episode e
                    ON e.id_episode = ei.id_episode
                 WHERE (s.id_schedule = i_schedule OR e.id_episode = i_episode);
        
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner_name,
                                              i_package  => g_pck_name,
                                              i_function => l_function_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_info);
            RETURN FALSE;
    END get_episode_info;

    FUNCTION get_epis_contact_type
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR2 IS
    
        l_flg_contact_type VARCHAR2(2);
    
    BEGIN
    
        SELECT sg.flg_contact_type
          INTO l_flg_contact_type
          FROM sch_group sg
         WHERE sg.id_schedule = i_schedule;
    
        RETURN l_flg_contact_type;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_epis_contact_type;

    FUNCTION get_epis_dep_cs_desc
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR IS
        l_ret              pk_translation.t_desc_translation;
        l_id_dep_clin_serv dep_clin_serv.id_dep_clin_serv%TYPE;
    BEGIN
    
        BEGIN
            SELECT nvl(ei.id_dep_clin_serv, s.id_dcs_requested)
              INTO l_id_dep_clin_serv
              FROM epis_info ei
              LEFT JOIN schedule s
                ON (ei.id_schedule = s.id_schedule)
             WHERE ei.id_episode = i_episode;
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
        SELECT pk_translation.get_translation(i_lang, d.code_department) || ' - ' ||
               pk_translation.get_translation(i_lang, cs.code_clinical_service)
          INTO l_ret
          FROM dep_clin_serv dcs
          JOIN clinical_service cs
            ON cs.id_clinical_service = dcs.id_clinical_service
          JOIN department d
            ON dcs.id_department = d.id_department
         WHERE dcs.id_dep_clin_serv = l_id_dep_clin_serv;
    
        RETURN l_ret;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_epis_dep_cs_desc;

    PROCEDURE get_date_bounds
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_dt     IN VARCHAR2,
        o_dt_min OUT schedule_outp.dt_target_tstz%TYPE,
        o_dt_max OUT schedule_outp.dt_target_tstz%TYPE
    ) IS
    BEGIN
        o_dt_min := pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                     i_timestamp => nvl(pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                                                      i_prof      => i_prof,
                                                                                                      i_timestamp => i_dt,
                                                                                                      i_timezone  => NULL),
                                                                        g_sysdate_tstz));
        -- the date max as to be 23:59:59 (that in seconds is 86399 seconds)                                                                        
        o_dt_max := pk_date_utils.add_to_ltstz(i_timestamp => o_dt_min,
                                               i_amount    => g_day_in_seconds,
                                               i_unit      => 'SECOND');
    
    END get_date_bounds;

    FUNCTION get_episodes_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_dt       IN VARCHAR2,
        o_episodes OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dt_min schedule_outp.dt_target_tstz%TYPE;
        l_dt_max schedule_outp.dt_target_tstz%TYPE;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        g_error        := 'GET G_SYSDATE';
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
    
        g_error := 'CALL get_date_bounds';
        get_date_bounds(i_lang => i_lang, i_prof => i_prof, i_dt => i_dt, o_dt_min => l_dt_min, o_dt_max => l_dt_max);
    
        OPEN o_episodes FOR
            SELECT s.id_schedule,
                   sg.id_patient,
                   (SELECT cr.num_clin_record
                      FROM clin_record cr
                     WHERE cr.id_patient = sg.id_patient
                       AND cr.id_institution = i_prof.institution
                       AND rownum < 2) num_clin_record,
                   ei.id_episode id_episode,
                   pk_patient.get_pat_name(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) name,
                   (SELECT pk_sysdomain.get_domain('PATIENT.GENDER.ABBR', pat.gender, i_lang) gender
                      FROM patient pat
                     WHERE sg.id_patient = pat.id_patient) gender,
                   pk_patient.get_pat_age(i_lang, sg.id_patient, i_prof) pat_age,
                   ei.id_dep_clin_serv,
                   pk_hea_prv_aux.get_clin_service(i_lang, i_prof, ei.id_dep_clin_serv) clinical_service,
                   pk_schedule_common.get_translation_alias(i_lang, i_prof, se.id_sch_event, se.code_sch_event) visit_type,
                   se.id_sch_event visit_type_id,
                   nvl((SELECT nvl(p.nick_name, p.name)
                         FROM professional p
                        WHERE p.id_professional = ei.id_professional),
                       (SELECT nvl(p.nick_name, p.name)
                          FROM sch_prof_outp ps, professional p
                         WHERE ps.id_schedule_outp = sp.id_schedule_outp
                           AND p.id_professional = ps.id_professional
                           AND rownum < 2)) professional_name,
                   nvl(ei.id_professional, spo.id_professional) id_professional,
                   pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_target,
                   pk_date_utils.date_char_hour_tsz(i_lang, sp.dt_target_tstz, i_prof.institution, i_prof.software) dt_target_hour,
                   sp.dt_target_tstz,
                   sp.flg_sched,
                   e.flg_status,
                   e.flg_ehr,
                   sg.flg_contact_type
              FROM schedule_outp sp
              JOIN schedule s
                ON s.id_schedule = sp.id_schedule
              JOIN sch_group sg
                ON sg.id_schedule = s.id_schedule
              JOIN sch_event se
                ON s.id_sch_event = se.id_sch_event
              JOIN epis_type et
                ON sp.id_epis_type = et.id_epis_type
              LEFT JOIN epis_info ei
                ON s.id_schedule = ei.id_schedule
               AND ei.id_patient = sg.id_patient
              LEFT JOIN episode e
                ON ei.id_episode = e.id_episode
               AND e.id_patient = ei.id_patient
               AND e.flg_ehr != pk_visit.g_flg_ehr_e
              LEFT JOIN sch_prof_outp spo
                ON spo.id_schedule_outp = sp.id_schedule_outp
             WHERE sp.dt_target_tstz BETWEEN l_dt_min AND l_dt_max
               AND sp.id_software = i_prof.software
               AND s.id_instit_requested = i_prof.institution
               AND s.flg_status NOT IN (pk_schedule.g_sched_status_cancelled, pk_schedule.g_sched_status_cache);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner_name,
                                              i_package  => g_pck_name,
                                              i_function => 'GET_EPISODES_LIST',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_episodes);
            RETURN FALSE;
    END get_episodes_list;

    FUNCTION get_desc_rehab_area
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_id_episode IN NUMBER
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(4000);
        tbl_area table_number;
        k_sep       CONSTANT VARCHAR2(0010 CHAR) := ';' || chr(32);
        k_code_area CONSTANT VARCHAR2(0200 CHAR) := 'REHAB_AREA.CODE_REHAB_AREA.';
    
        --****************************************
        FUNCTION l_get_rehab_area(i_id_episode IN NUMBER) RETURN table_number IS
            tbl_area table_number;
        BEGIN
        
            SELECT DISTINCT rai.id_rehab_area
              BULK COLLECT
              INTO tbl_area
              FROM rehab_epis_encounter ree
              JOIN rehab_presc rp
                ON ree.id_rehab_sch_need = rp.id_rehab_sch_need
              JOIN rehab_area_interv rai
                ON rp.id_rehab_area_interv = rai.id_rehab_area_interv
             WHERE ree.id_episode_rehab = i_id_episode;
        
            RETURN tbl_area;
        
        END l_get_rehab_area;
    
    BEGIN
    
        tbl_area := l_get_rehab_area(i_id_episode => i_id_episode);
    
        IF tbl_area.count > 0
        THEN
        
            <<lup_thru_area>>
            FOR i IN 1 .. tbl_area.count
            LOOP
            
                IF l_return IS NOT NULL
                THEN
                    l_return := l_return || k_sep;
                END IF;
            
                l_return := l_return || pk_translation.get_translation(i_lang, k_code_area || tbl_area(i));
            
            END LOOP lup_thru_area;
        
        END IF;
    
        RETURN l_return;
    
    END get_desc_rehab_area;

    FUNCTION get_appointment_type
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_ret              pk_translation.t_desc_translation;
        l_desc_event       pk_translation.t_desc_translation;
        l_id_dep_clin_serv dep_clin_serv.id_dep_clin_serv%TYPE;
        l_clinical_service pk_translation.t_desc_translation;
    BEGIN
        BEGIN
            SELECT pk_schedule_common.get_translation_alias(i_lang, i_prof, se.id_sch_event, se.code_sch_event),
                   s.id_dcs_requested
              INTO l_desc_event, l_id_dep_clin_serv
              FROM schedule s
              LEFT JOIN sch_event se
                ON s.id_sch_event = se.id_sch_event
              JOIN epis_info ei
                ON ei.id_schedule = s.id_schedule
             WHERE ei.id_episode = i_id_episode;
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        IF l_desc_event IS NOT NULL
        THEN
            l_desc_event := l_desc_event || ': ';
        END IF;
    
        SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service)
          INTO l_clinical_service
          FROM dep_clin_serv dcs
          JOIN clinical_service cs
            ON cs.id_clinical_service = dcs.id_clinical_service
         WHERE dcs.id_dep_clin_serv = l_id_dep_clin_serv;
    
        l_ret := l_desc_event || l_clinical_service;
    
        RETURN l_ret;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_appointment_type;

    FUNCTION get_epis_type_desc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
    
        CURSOR c_epis IS
            SELECT pk_translation.get_translation(i_lang, et.code_epis_type)
              FROM episode e
              JOIN epis_type et
                ON e.id_epis_type = et.id_epis_type
             WHERE id_episode = i_id_episode;
    
        l_desc_epis_type VARCHAR2(500 CHAR);
    BEGIN
        g_error := 'GET CURSOR ';
        OPEN c_epis;
        FETCH c_epis
            INTO l_desc_epis_type;
        CLOSE c_epis;
    
        RETURN l_desc_epis_type;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_epis_type_desc;

END pk_episode;
/
