/*-- Last Change Revision: $Rev: 2050365 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2022-11-16 12:04:36 +0000 (qua, 16 nov 2022) $*/
CREATE OR REPLACE PACKAGE BODY pk_match AS

    FUNCTION get_match_currepis
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        o_curr           OUT pk_types.cursor_type,
        o_icon           OUT VARCHAR2,
        o_prof_nick_name OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        /***************   ***************************************************************
           OBJECTIVO:  Esta função devolve um array com os dados do episódio actual (SE ESTE FOR TEMPORÁRIO)
                          que serão utilizados para a obtenção de episódios relacionados, de acordo com
                    critérios pré-definidos, de forma a permitir fazer o match entre os episódios.
        
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                        I_PROF - ID do médico cirurgião que está a aceder à grelha
                                I_EPISODE - ID do episódio
                       SAIDA:   O_CURR- Array de dados do episódio actual
                                O_PROF_NICK_NAME- Alcunha do profissional
                                O_ICON - Nome do icon de selecção
                                O_ERROR - erro
        
          CRIAÇÃO: RB 2007/01/15
          NOTAS: Se o episódio actual não for temporário, esta função não vai devolver qualquer registo, já
                   que para o match, o episódio actual terá que ser sempre o temporário
        *********************************************************************************/
        l_id_health_plan       health_plan.id_health_plan%TYPE;
        l_id_cnt_hp            health_plan.id_content%TYPE;
        l_msg_edis_common_t002 sys_message.desc_message%TYPE;
        l_msg_edis_common_t004 sys_message.desc_message%TYPE;
        l_config_curp          VARCHAR2(10 CHAR);
    BEGIN
    
        o_icon := g_hand_icon;
    
        -- Fábio Oliveira 16/05/08 obtém o id_health_plan
        l_id_cnt_hp            := pk_sysconfig.get_config('ADT_NATIONAL_HEALTH_PLAN_ID', i_prof);
        l_config_curp          := pk_sysconfig.get_config('MATCH_USE_CURP', i_prof);
        l_msg_edis_common_t002 := pk_message.get_message(i_lang, 'EDIS_COMMON_T002');
        l_msg_edis_common_t004 := pk_message.get_message(i_lang, 'EDIS_COMMON_T004');
    
        g_error := 'GET HEALTH_PLAN BY id_content';
        BEGIN
            SELECT hp.id_health_plan
              INTO l_id_health_plan
              FROM health_plan hp
             WHERE hp.id_content = l_id_cnt_hp
               AND hp.flg_available = 'Y';
        EXCEPTION
            WHEN no_data_found THEN
                l_id_health_plan := NULL;
        END;
    
        -- LMAIA 03-07-2009
        -- Get professional nick_name to insert it in match screen
        g_error          := 'OPEN O_PROF_NICK_NAME CURSOR';
        o_prof_nick_name := pk_prof_utils.get_name_signature(i_lang, i_prof, i_prof.id);
    
        g_error := 'OPEN O_CURR CURSOR';
        OPEN o_curr FOR
            SELECT ei.id_episode,
                   e.id_visit,
                   p.id_patient,
                   pk_patient.get_pat_name(i_lang, i_prof, e.id_patient, e.id_episode) name,
                   -- ALERT-102882 Patient name used for sorting
                   pk_patient.get_pat_name_to_sort(i_lang, i_prof, e.id_patient, e.id_episode, NULL) name_pat_sort,
                   pk_patient.get_julian_age(i_lang, p.dt_birth, p.age) pat_age_for_order_by,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, e.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, e.id_patient) pat_nd_icon,
                   pk_patient.get_gender(i_lang, p.gender) gender,
                   -- Fábio Oliveira 16/05/08 usar a cache e a nova função visto já termos o dt_birth
                   (SELECT pk_patient.get_pat_age(i_lang,
                                                  p.dt_birth,
                                                  p.dt_deceased,
                                                  p.age,
                                                  i_prof.institution,
                                                  i_prof.software)
                      FROM dual) pat_age,
                   decode(pk_patphoto.check_blob(p.id_patient),
                          'N',
                          '',
                          (SELECT pk_patphoto.get_pat_photo(i_lang, i_prof, e.id_patient, e.id_episode, ei.id_schedule)
                             FROM dual)) photo,
                   pk_date_utils.date_send(i_lang, p.dt_birth, i_prof) dt_birth,
                   pk_date_utils.date_chr_short_read(i_lang, p.dt_birth, i_prof) dt_birth_formatted,
                   -- Fábio Oliveira 16/05/08 Obter número do serviço de saúde (health plan) de forma coerente com a informação do paciente
                   CASE l_config_curp
                       WHEN pk_alert_constant.g_yes THEN
                        (SELECT pr.social_security_number
                           FROM person pr
                          WHERE id_person = p.id_person)
                       ELSE
                        (SELECT php.num_health_plan
                           FROM pat_health_plan php
                          WHERE php.id_health_plan = l_id_health_plan
                            AND php.id_patient = p.id_patient
                            AND php.id_institution = i_prof.institution)
                   END num_health_plan,
                   --ORIS
                   pk_sr_clinical_info.get_proposed_surgery(i_lang, ei.id_episode, i_prof, pk_alert_constant.g_no) desc_intervention,
                   pk_date_utils.date_send_tsz(i_lang, h.dt_target_tstz, i_prof) dt_surg,
                   --EDIS
                   ei.triage_acuity acuity,
                   ei.triage_color_text color_text,
                   decode(pk_ubu.get_episode_transportation(ei.id_episode, i_prof),
                          NULL,
                          decode(i_prof.software,
                                 pk_alert_constant.g_soft_edis,
                                 l_msg_edis_common_t002,
                                 l_msg_edis_common_t004),
                          l_msg_edis_common_t004) desc_origin, -- tco 21/06/2007
                   --INP
                   -- jose silva 16-03-2007 devolver tambem o id do serviço
                   cs.id_clinical_service,
                   dpt.id_department,
                   -- Fábio Oliveira 16/05/08 usar a cache e não calcular se code_clinical_service ou code_department for null
                   decode(cs.code_clinical_service,
                          NULL,
                          NULL,
                          (SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service)
                             FROM dual)) desc_specialty,
                   decode(dpt.code_department,
                          NULL,
                          NULL,
                          (SELECT pk_translation.get_translation(i_lang, dpt.code_department)
                             FROM dual)) desc_department,
                   --JOSE SILVA 14-03-2007 formato da data
                   pk_date_utils.date_send_tsz(i_lang, e.dt_begin_tstz, i_prof) dt_episode,
                   pk_date_utils.dt_chr_tsz(i_lang, e.dt_begin_tstz, i_prof) dt_episode_formatted,
                   --Alexandre Santos 13-10-2010 ALERT-726 Changing and cancelling appointmentsChanging to another physician with the same specialty as the responsible physician. However, the responsible physician remains the same.
                   (SELECT pk_hand_off_api.get_resp_icons(i_lang, i_prof, e.id_episode, NULL)
                      FROM dual) resp_icons
              FROM episode          e,
                   patient          p,
                   schedule_sr      h, --Tabelas específicas do ORIS
                   epis_triage      etr,
                   department       dpt,
                   epis_info        ei,
                   clinical_service cs --Tabelas específicas do INP
             WHERE ei.id_episode = i_episode
               AND ei.id_episode = e.id_episode
               AND ei.flg_unknown = decode(e.flg_status, g_cancel, ei.flg_unknown, g_flg_unknown_temp)
               AND p.id_patient = ei.id_patient
               AND h.id_episode(+) = e.id_episode
               AND etr.id_episode(+) = e.id_episode
               AND ((etr.dt_begin_tstz = (SELECT MAX(etr1.dt_begin_tstz)
                                            FROM epis_triage etr1
                                           WHERE etr1.id_episode(+) = e.id_episode) AND EXISTS
                    (SELECT 0
                        FROM epis_triage etr2
                       WHERE etr2.id_episode(+) = e.id_episode)) OR NOT EXISTS
                    (SELECT 0
                       FROM epis_triage etr3
                      WHERE etr3.id_episode(+) = e.id_episode))
               AND e.id_department = dpt.id_department
               AND cs.id_clinical_service = e.id_clinical_service;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MATCH',
                                              'GET_MATCH_CURREPIS',
                                              o_error);
            pk_types.open_my_cursor(o_curr);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    FUNCTION get_match_episodes
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        i_name        IN patient.name%TYPE,
        i_gender      IN patient.gender%TYPE,
        i_dt_birth    IN VARCHAR2,
        i_num_hplan   IN pat_health_plan.num_health_plan%TYPE,
        i_desc_interv IN VARCHAR2,
        i_dt_surg     IN VARCHAR2,
        o_epis        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:  Esta função devolve um array com os dados do episódio actual que serão utilizados para a
                        obtenção de episódios relacionados, de acordo com critérios pré-definidos, de forma a permitir fazer
                        o match entre os episódios.
        
                        Os critérios são os seguintes (por ordem de obtenção):
                            1. Igual número de cartão de utente
                            2. Iguais nome do paciente, procedimentos cirúrgicos e data da cirurgia (apenas no ORIS)
                            3. Iguais nome do paciente, sexo e data de nascimento
                            4. Iguais nome do paciente e data de nascimento.
                        Quando um dos critérios devolve episódios, já não são avaliados os restantes critérios
        
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                        I_PROF - ID do médico cirurgião que está a aceder à grelha
                                I_EPISODE - ID do episódio
                        I_NAME - Nome do doente
                        I_GENDER - Sexo do doente
                        I_DT_BIRTH - Data de nascimento do doente
                        I_NUM_HPLAN - Número de cartão de utente (número do SNS)
                        I_DESC_INTERV  - Descrição dos processos cirúrgicos
                        I_DT_SURG - Data da cirurgia
                       SAIDA:   O_EPIS - Array de dados de todos os episódios relacionados
                                O_ERROR - erro
        
          CRIAÇÃO: RB 2007/01/15
          NOTAS:
        *********************************************************************************/
    
        num_epis         NUMBER;
        l_dt_surg_tstz   TIMESTAMP WITH LOCAL TIME ZONE;
        l_id_health_plan sys_config.value%TYPE;
        l_id_cnt_hp      health_plan.id_content%TYPE;
        l_hand_off_type  sys_config.value%TYPE;
        --
        l_msg_edis_common_t002 sys_message.desc_message%TYPE;
        l_msg_edis_common_t004 sys_message.desc_message%TYPE;
        --
        l_dt_birth    patient.dt_birth%TYPE;
        l_config_curp VARCHAR2(10 CHAR);
    BEGIN
        l_msg_edis_common_t002 := pk_message.get_message(i_lang, 'EDIS_COMMON_T002');
        l_msg_edis_common_t004 := pk_message.get_message(i_lang, 'EDIS_COMMON_T004');
    
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
        num_epis       := 0;
        l_dt_surg_tstz := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_surg, NULL);
        l_id_cnt_hp    := pk_sysconfig.get_config('ADT_NATIONAL_HEALTH_PLAN_ID', i_prof);
    
        BEGIN
            SELECT hp.id_health_plan
              INTO l_id_health_plan
              FROM health_plan hp
             WHERE hp.id_content = l_id_cnt_hp
               AND hp.flg_available = 'Y';
        EXCEPTION
            WHEN no_data_found THEN
                l_id_health_plan := NULL;
        END;
    
        l_config_curp := pk_sysconfig.get_config('MATCH_USE_CURP', i_prof);
    
        l_dt_birth := to_date(i_dt_birth, pk_date_utils.g_dateformat);
    
        IF l_config_curp = pk_alert_constant.g_no
        THEN
            --Verifica se existem episódios para o mesmo número de SNS
            g_error := 'COUNT EPISODES-1';
            SELECT COUNT(*)
              INTO num_epis
              FROM pat_health_plan php, patient p, episode e, epis_triage etr, epis_info ei
             WHERE php.id_health_plan = l_id_health_plan
               AND nvl(php.num_health_plan, '@') = nvl(i_num_hplan, '@')
               AND p.id_patient = php.id_patient
               AND php.id_institution = i_prof.institution
               AND e.id_patient = p.id_patient
               AND e.id_episode != i_episode
               AND e.flg_status = g_active
               AND e.id_epis_type = pk_episode.get_epis_type(i_lang, i_episode)
               AND etr.id_episode(+) = e.id_episode
               AND ((etr.dt_begin_tstz = (SELECT MAX(etr1.dt_begin_tstz)
                                            FROM epis_triage etr1
                                           WHERE etr1.id_episode(+) = e.id_episode) AND EXISTS
                    (SELECT 0
                        FROM epis_triage etr2
                       WHERE etr2.id_episode(+) = e.id_episode)) OR NOT EXISTS
                    (SELECT 0
                       FROM epis_triage etr3
                      WHERE etr3.id_episode(+) = e.id_episode))
               AND ei.id_episode = e.id_episode
               AND nvl(ei.flg_unknown, g_flg_unknown_def) = g_flg_unknown_def;
        ELSE
            SELECT COUNT(*)
              INTO num_epis
              FROM patient p
              JOIN person pe
                ON p.id_person = pe.id_person
              JOIN episode e
                ON p.id_patient = e.id_episode
              LEFT JOIN epis_triage etr
                ON etr.id_episode = e.id_episode
              JOIN epis_info ei
                ON e.id_episode = ei.id_episode
             WHERE e.id_episode != i_episode
               AND e.flg_status = g_active
               AND nvl(pe.social_security_number, '@') = nvl(i_num_hplan, '@')
               AND e.id_epis_type = pk_episode.get_epis_type(i_lang, i_episode)
               AND ((etr.dt_begin_tstz = (SELECT MAX(etr1.dt_begin_tstz)
                                            FROM epis_triage etr1
                                           WHERE etr1.id_episode(+) = e.id_episode) AND EXISTS
                    (SELECT 0
                        FROM epis_triage etr2
                       WHERE etr2.id_episode(+) = e.id_episode)) OR NOT EXISTS
                    (SELECT 0
                       FROM epis_triage etr3
                      WHERE etr3.id_episode(+) = e.id_episode))
               AND nvl(ei.flg_unknown, g_flg_unknown_def) = g_flg_unknown_def;
        END IF;
        IF nvl(num_epis, 0) > 0
        THEN
            --carrega array de episódios
            g_error := 'OPEN O_EPIS-1';
            OPEN o_epis FOR
                SELECT *
                  FROM (SELECT e.id_episode,
                               e.id_visit,
                               p.id_patient,
                               pk_patient.get_pat_name(i_lang, i_prof, e.id_patient, e.id_episode) name,
                               pk_patient.get_pat_name_to_sort(i_lang, i_prof, e.id_patient, e.id_episode) name_pat_sort,
                               pk_patient.get_julian_age(i_lang, p.dt_birth, p.age) pat_age_for_order_by,
                               pk_adt.get_pat_non_disc_options(i_lang, i_prof, e.id_patient) pat_ndo,
                               pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, e.id_patient) pat_nd_icon,
                               pk_patient.get_gender(i_lang, p.gender) gender,
                               pk_patient.get_pat_age(i_lang,
                                                      p.dt_birth,
                                                      p.dt_deceased,
                                                      p.age,
                                                      i_prof.institution,
                                                      i_prof.software) pat_age,
                               decode(pk_patphoto.check_blob(p.id_patient),
                                      'N',
                                      '',
                                      (SELECT pk_patphoto.get_pat_photo(i_lang,
                                                                        i_prof,
                                                                        e.id_patient,
                                                                        e.id_episode,
                                                                        ei.id_schedule)
                                         FROM dual)) photo,
                               p.dt_birth,
                               pk_date_utils.date_chr_short_read(i_lang, p.dt_birth, i_prof) dt_birth_formatted,
                               CASE l_config_curp
                                   WHEN pk_alert_constant.g_yes THEN
                                    (SELECT pr.social_security_number
                                       FROM person pr
                                      WHERE id_person = p.id_person)
                                   ELSE
                                    php.num_health_plan
                               END num_health_plan,
                               --ORIS
                               pk_sr_clinical_info.get_proposed_surgery(i_lang,
                                                                        e.id_episode,
                                                                        i_prof,
                                                                        pk_alert_constant.g_no) desc_intervention,
                               pk_date_utils.date_send_tsz(i_lang, h.dt_target_tstz, i_prof) dt_surg,
                               --EDIS
                               ei.triage_acuity acuity,
                               ei.triage_color_text color_text,
                               decode(pk_ubu.get_episode_transportation(ei.id_episode, i_prof),
                                      NULL,
                                      decode(i_prof.software,
                                             pk_alert_constant.g_soft_edis,
                                             l_msg_edis_common_t002,
                                             l_msg_edis_common_t004),
                                      l_msg_edis_common_t004) desc_origin, -- tco 21/06/2007
                               pk_date_utils.date_send_tsz(i_lang, e.dt_begin_tstz, i_prof) dt_episode,
                               pk_hand_off_api.get_resp_icons(i_lang, i_prof, e.id_episode, l_hand_off_type) resp_icons
                          FROM pat_health_plan php,
                               patient         p,
                               episode         e,
                               schedule_sr     h, --Tabelas específicas do ORIS
                               epis_triage     etr,
                               epis_info       ei
                         WHERE php.id_health_plan = l_id_health_plan
                           AND php.num_health_plan = i_num_hplan
                           AND p.id_patient = php.id_patient
                           AND php.id_institution = i_prof.institution
                           AND e.id_patient = p.id_patient
                              --                   AND v.flg_status = g_active
                              --                   AND v.id_institution = i_prof.institution
                           AND e.id_episode != i_episode
                           AND e.flg_status = g_active
                              --                 AND ei.id_software = i_prof.software
                           AND e.id_epis_type = pk_episode.get_epis_type(i_lang, i_episode)
                           AND h.id_episode(+) = e.id_episode
                           AND etr.id_episode(+) = e.id_episode
                           AND ((etr.dt_begin_tstz = (SELECT MAX(etr1.dt_begin_tstz)
                                                        FROM epis_triage etr1
                                                       WHERE etr1.id_episode(+) = e.id_episode) AND EXISTS
                                (SELECT 0
                                    FROM epis_triage etr2
                                   WHERE etr2.id_episode(+) = e.id_episode)) OR NOT EXISTS
                                (SELECT 0
                                   FROM epis_triage etr3
                                  WHERE etr3.id_episode(+) = e.id_episode))
                           AND ei.id_episode = e.id_episode
                           AND nvl(ei.flg_unknown, g_flg_unknown_def) = g_flg_unknown_def)
                 ORDER BY name_pat_sort, dt_birth, dt_surg;
        
        ELSE
            --Verifica se existem episódios que obedeçam aos seguintes critérios:
            --  Nome do paciente, procedimentos cirúrgicos e data de cirurgia
            --  Este critério é específico do ORIS, pelo que os critérios dos outros produtos não se incluem
            g_error := 'COUNT EPISODES-2';
        
            SELECT COUNT(*)
              INTO num_epis
              FROM episode e, visit v, patient p, schedule_sr h, epis_info ei
             WHERE upper(p.name) = upper(i_name)
               AND upper(i_desc_interv) =
                   upper(pk_sr_clinical_info.get_proposed_surgery(i_lang, e.id_episode, i_prof, pk_alert_constant.g_no))
               AND v.id_patient = p.id_patient
               AND v.flg_status = g_active
               AND e.id_visit = v.id_visit
               AND e.flg_status = g_active
               AND e.id_epis_type = pk_episode.get_epis_type(i_lang, i_episode)
               AND e.id_episode != i_episode
               AND ei.id_episode = e.id_episode
               AND nvl(ei.flg_unknown, g_flg_unknown_def) = g_flg_unknown_def
               AND h.id_episode = e.id_episode
               AND pk_date_utils.trunc_insttimezone(i_prof, h.dt_target_tstz, NULL) =
                   pk_date_utils.trunc_insttimezone(i_prof, l_dt_surg_tstz, NULL);
        
            IF nvl(num_epis, 0) > 0
            THEN
                --carrega array de episódios
                g_error := 'OPEN O_EPIS-2';
                OPEN o_epis FOR
                    SELECT *
                      FROM (SELECT e.id_episode,
                                   e.id_visit,
                                   p.id_patient,
                                   pk_patient.get_pat_name(i_lang, i_prof, e.id_patient, e.id_episode) name,
                                   pk_patient.get_pat_name_to_sort(i_lang, i_prof, e.id_patient, e.id_episode) name_pat_sort,
                                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, e.id_patient) pat_ndo,
                                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, e.id_patient) pat_nd_icon,
                                   pk_patient.get_gender(i_lang, p.gender) gender,
                                   pk_patient.get_pat_age(i_lang,
                                                          p.dt_birth,
                                                          p.dt_deceased,
                                                          p.age,
                                                          i_prof.institution,
                                                          i_prof.software) pat_age,
                                   decode(pk_patphoto.check_blob(p.id_patient),
                                          'N',
                                          '',
                                          (SELECT pk_patphoto.get_pat_photo(i_lang,
                                                                            i_prof,
                                                                            e.id_patient,
                                                                            e.id_episode,
                                                                            ei.id_schedule)
                                             FROM dual)) photo,
                                   p.dt_birth,
                                   pk_date_utils.date_chr_short_read(i_lang, p.dt_birth, i_prof) dt_birth_formatted,
                                   CASE l_config_curp
                                       WHEN pk_alert_constant.g_yes THEN
                                        (SELECT pr.social_security_number
                                           FROM person pr
                                          WHERE id_person = p.id_person)
                                       ELSE
                                        (SELECT php.num_health_plan
                                           FROM pat_health_plan php
                                          WHERE php.id_health_plan = l_id_health_plan
                                            AND php.id_patient = p.id_patient
                                            AND php.id_institution = i_prof.institution)
                                   END num_health_plan,
                                   --ORIS
                                   pk_sr_clinical_info.get_proposed_surgery(i_lang,
                                                                            e.id_episode,
                                                                            i_prof,
                                                                            pk_alert_constant.g_no) desc_intervention,
                                   pk_date_utils.date_send_tsz(i_lang, h.dt_target_tstz, i_prof) dt_surg,
                                   --EDIS
                                   NULL acuity,
                                   NULL color_text,
                                   NULL desc_origin,
                                   pk_hand_off_api.get_resp_icons(i_lang, i_prof, e.id_episode, l_hand_off_type) resp_icons
                              FROM episode e, patient p, schedule_sr h, epis_info ei
                             WHERE upper(p.name) = upper(i_name)
                               AND upper(i_desc_interv) =
                                   upper(pk_sr_clinical_info.get_proposed_surgery(i_lang,
                                                                                  e.id_episode,
                                                                                  i_prof,
                                                                                  pk_alert_constant.g_no))
                               AND e.id_patient = p.id_patient
                                  ---                       AND v.id_institution = i_prof.institution
                               AND e.flg_status = g_active
                                  --                       AND ei.id_software = i_prof.software
                               AND e.id_epis_type = pk_episode.get_epis_type(i_lang, i_episode)
                               AND e.id_episode != i_episode
                               AND ei.id_episode = e.id_episode
                               AND nvl(ei.flg_unknown, g_flg_unknown_def) = g_flg_unknown_def
                               AND h.id_episode = e.id_episode
                               AND pk_date_utils.trunc_insttimezone(i_prof, h.dt_target_tstz, NULL) =
                                   pk_date_utils.trunc_insttimezone(i_prof, l_dt_surg_tstz, NULL))
                     ORDER BY name_pat_sort, dt_birth, dt_surg;
            
            ELSE
                --Verifica se existem episódios que obedeçam aos seguintes critérios:
                --  Nome do paciente, sexo e data de nascimento
                g_error := 'COUNT EPISODES-3';
                SELECT COUNT(*)
                  INTO num_epis
                  FROM episode     e,
                       visit       v,
                       patient     p,
                       schedule_sr h, --Tabelas específicas do ORIS
                       epis_triage etr,
                       epis_info   ei
                 WHERE upper(p.name) = upper(i_name)
                   AND p.gender = i_gender
                   AND trunc(p.dt_birth) = trunc(l_dt_birth)
                   AND v.id_patient = p.id_patient
                   AND v.flg_status = g_active
                   AND e.id_visit = v.id_visit
                   AND e.flg_status = g_active
                   AND e.id_epis_type = pk_episode.get_epis_type(i_lang, i_episode)
                   AND e.id_episode != i_episode
                   AND h.id_episode(+) = e.id_episode
                   AND etr.id_episode(+) = e.id_episode
                   AND ((etr.dt_begin_tstz = (SELECT MAX(etr1.dt_begin_tstz)
                                                FROM epis_triage etr1
                                               WHERE etr1.id_episode(+) = e.id_episode) AND EXISTS
                         (SELECT 0
                            FROM epis_triage etr2
                           WHERE etr2.id_episode(+) = e.id_episode)) OR NOT EXISTS
                        (SELECT 0
                           FROM epis_triage etr3
                          WHERE etr3.id_episode(+) = e.id_episode))
                   AND ei.id_episode = e.id_episode
                   AND nvl(ei.flg_unknown, g_flg_unknown_def) = g_flg_unknown_def;
            
                IF nvl(num_epis, 0) > 0
                THEN
                    --carrega array de episódios
                    g_error := 'OPEN O_EPIS-3';
                    OPEN o_epis FOR
                        SELECT *
                          FROM (SELECT e.id_episode,
                                       e.id_visit,
                                       p.id_patient,
                                       pk_patient.get_pat_name(i_lang, i_prof, e.id_patient, e.id_episode) name,
                                       pk_patient.get_pat_name_to_sort(i_lang, i_prof, e.id_patient, e.id_episode) name_pat_sort,
                                       pk_adt.get_pat_non_disc_options(i_lang, i_prof, e.id_patient) pat_ndo,
                                       pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, e.id_patient) pat_nd_icon,
                                       pk_patient.get_gender(i_lang, p.gender) gender,
                                       pk_patient.get_pat_age(i_lang,
                                                              p.dt_birth,
                                                              p.dt_deceased,
                                                              p.age,
                                                              i_prof.institution,
                                                              i_prof.software) pat_age,
                                       decode(pk_patphoto.check_blob(p.id_patient),
                                              'N',
                                              '',
                                              (SELECT pk_patphoto.get_pat_photo(i_lang,
                                                                                i_prof,
                                                                                e.id_patient,
                                                                                e.id_episode,
                                                                                ei.id_schedule)
                                                 FROM dual)) photo,
                                       p.dt_birth,
                                       pk_date_utils.date_chr_short_read(i_lang, p.dt_birth, i_prof) dt_birth_formatted,
                                       CASE l_config_curp
                                           WHEN pk_alert_constant.g_yes THEN
                                            (SELECT pr.social_security_number
                                               FROM person pr
                                              WHERE id_person = p.id_person)
                                           ELSE
                                            (SELECT php.num_health_plan
                                               FROM pat_health_plan php
                                              WHERE php.id_health_plan = l_id_health_plan
                                                AND php.id_patient = p.id_patient
                                                AND php.id_institution = i_prof.institution)
                                       END num_health_plan,
                                       --ORIS
                                       pk_sr_clinical_info.get_proposed_surgery(i_lang,
                                                                                e.id_episode,
                                                                                i_prof,
                                                                                pk_alert_constant.g_no) desc_intervention,
                                       pk_date_utils.date_send_tsz(i_lang, h.dt_target_tstz, i_prof) dt_surg,
                                       --EDIS
                                       ei.triage_acuity acuity,
                                       ei.triage_color_text color_text,
                                       decode(pk_ubu.get_episode_transportation(ei.id_episode, i_prof),
                                              NULL,
                                              decode(i_prof.software,
                                                     pk_alert_constant.g_soft_edis,
                                                     l_msg_edis_common_t002,
                                                     l_msg_edis_common_t004),
                                              l_msg_edis_common_t004) desc_origin, -- tco 21/06/2007
                                       pk_date_utils.date_send_tsz(i_lang, e.dt_begin_tstz, i_prof) dt_episode,
                                       pk_hand_off_api.get_resp_icons(i_lang, i_prof, e.id_episode, l_hand_off_type) resp_icons
                                  FROM episode     e,
                                       patient     p,
                                       schedule_sr h, --Tabelas específicas do ORIS
                                       epis_triage etr,
                                       epis_info   ei
                                 WHERE upper(p.name) = upper(i_name)
                                   AND p.gender = i_gender
                                   AND trunc(p.dt_birth) = trunc(l_dt_birth)
                                   AND e.id_patient = p.id_patient
                                   AND e.id_epis_type = pk_episode.get_epis_type(i_lang, i_episode)
                                   AND e.flg_status = g_active
                                   AND e.id_episode != i_episode
                                   AND h.id_episode(+) = e.id_episode
                                   AND etr.id_episode(+) = e.id_episode
                                   AND ((etr.dt_begin_tstz =
                                        (SELECT MAX(etr1.dt_begin_tstz)
                                            FROM epis_triage etr1
                                           WHERE etr1.id_episode(+) = e.id_episode) AND EXISTS
                                         (SELECT 0
                                            FROM epis_triage etr2
                                           WHERE etr2.id_episode(+) = e.id_episode)) OR NOT EXISTS
                                        (SELECT 0
                                           FROM epis_triage etr3
                                          WHERE etr3.id_episode(+) = e.id_episode))
                                   AND ei.id_episode = e.id_episode
                                   AND nvl(ei.flg_unknown, g_flg_unknown_def) = g_flg_unknown_def)
                         ORDER BY name_pat_sort, dt_birth, dt_surg;
                ELSE
                    --Verifica se existem episódios que obedeçam aos seguintes critérios:
                    --  Nome do paciente e data de nascimento
                    g_error := 'COUNT EPISODES-4';
                    SELECT COUNT(*)
                      INTO num_epis
                      FROM episode     e,
                           patient     p,
                           schedule_sr h, --Tabelas específicas do ORIS
                           epis_triage etr,
                           epis_info   ei
                     WHERE upper(p.name) = upper(i_name)
                       AND trunc(p.dt_birth) = trunc(l_dt_birth)
                       AND e.id_patient = p.id_patient
                       AND e.flg_status = g_active
                       AND e.id_epis_type = pk_episode.get_epis_type(i_lang, i_episode)
                       AND e.id_episode != i_episode
                       AND h.id_episode(+) = e.id_episode
                       AND etr.id_episode(+) = e.id_episode
                       AND ((etr.dt_begin_tstz = (SELECT MAX(etr1.dt_begin_tstz)
                                                    FROM epis_triage etr1
                                                   WHERE etr1.id_episode(+) = e.id_episode) AND EXISTS
                             (SELECT 0
                                FROM epis_triage etr2
                               WHERE etr2.id_episode(+) = e.id_episode)) OR NOT EXISTS
                            (SELECT 0
                               FROM epis_triage etr3
                              WHERE etr3.id_episode(+) = e.id_episode))
                       AND ei.id_episode = e.id_episode
                       AND nvl(ei.flg_unknown, g_flg_unknown_def) = g_flg_unknown_def;
                
                    IF nvl(num_epis, 0) > 0
                    THEN
                        --carrega array de episódios
                        g_error := 'OPEN O_EPIS-4';
                        OPEN o_epis FOR
                            SELECT *
                              FROM (SELECT e.id_episode,
                                           v.id_visit,
                                           p.id_patient,
                                           pk_patient.get_pat_name(i_lang, i_prof, e.id_patient, e.id_episode) name,
                                           pk_patient.get_pat_name_to_sort(i_lang, i_prof, e.id_patient, e.id_episode) name_pat_sort,
                                           pk_adt.get_pat_non_disc_options(i_lang, i_prof, e.id_patient) pat_ndo,
                                           pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, e.id_patient) pat_nd_icon,
                                           pk_patient.get_gender(i_lang, p.gender) gender,
                                           pk_patient.get_pat_age(i_lang,
                                                                  p.dt_birth,
                                                                  p.dt_deceased,
                                                                  p.age,
                                                                  i_prof.institution,
                                                                  i_prof.software) pat_age,
                                           decode(pk_patphoto.check_blob(p.id_patient),
                                                  'N',
                                                  '',
                                                  (SELECT pk_patphoto.get_pat_photo(i_lang,
                                                                                    i_prof,
                                                                                    e.id_patient,
                                                                                    e.id_episode,
                                                                                    ei.id_schedule)
                                                     FROM dual)) photo,
                                           p.dt_birth,
                                           pk_date_utils.date_chr_short_read(i_lang, p.dt_birth, i_prof) dt_birth_formatted,
                                           CASE l_config_curp
                                               WHEN pk_alert_constant.g_yes THEN
                                                (SELECT pr.social_security_number
                                                   FROM person pr
                                                  WHERE id_person = p.id_person)
                                               ELSE
                                                (SELECT php.num_health_plan
                                                   FROM pat_health_plan php
                                                  WHERE php.id_health_plan = l_id_health_plan
                                                    AND php.id_patient = p.id_patient
                                                    AND php.id_institution = i_prof.institution)
                                           END num_health_plan,
                                           --ORIS
                                           pk_sr_clinical_info.get_proposed_surgery(i_lang,
                                                                                    e.id_episode,
                                                                                    i_prof,
                                                                                    pk_alert_constant.g_no) desc_intervention,
                                           pk_date_utils.date_send_tsz(i_lang, h.dt_target_tstz, i_prof) dt_surg,
                                           --EDIS
                                           ei.triage_acuity     acuity,
                                           ei.triage_color_text color_text,
                                           --pk_message.get_message(i_lang, 'EDIS_COMMON_T002') desc_origin,
                                           decode(pk_ubu.get_episode_transportation(ei.id_episode, i_prof),
                                                  NULL,
                                                  decode(i_prof.software,
                                                         pk_alert_constant.g_soft_edis,
                                                         l_msg_edis_common_t002,
                                                         l_msg_edis_common_t004),
                                                  l_msg_edis_common_t004) desc_origin, -- tco 21/06/2007
                                           pk_date_utils.date_send_tsz(i_lang, e.dt_begin_tstz, i_prof) dt_episode,
                                           pk_hand_off_api.get_resp_icons(i_lang, i_prof, e.id_episode, l_hand_off_type) resp_icons
                                      FROM episode     e,
                                           visit       v,
                                           patient     p,
                                           schedule_sr h, --Tabelas específicas do ORIS
                                           epis_triage etr,
                                           epis_info   ei
                                     WHERE upper(p.name) = upper(i_name)
                                       AND trunc(p.dt_birth) = trunc(l_dt_birth)
                                       AND v.id_patient = p.id_patient
                                       AND v.flg_status = g_active
                                       AND e.id_visit = v.id_visit
                                       AND e.flg_status = g_active
                                       AND e.id_epis_type = pk_episode.get_epis_type(i_lang, i_episode)
                                       AND e.id_episode != i_episode
                                       AND h.id_episode(+) = e.id_episode
                                       AND etr.id_episode(+) = e.id_episode
                                       AND ((etr.dt_begin_tstz =
                                            (SELECT MAX(etr1.dt_begin_tstz)
                                                FROM epis_triage etr1
                                               WHERE etr1.id_episode(+) = e.id_episode) AND EXISTS
                                             (SELECT 0
                                                FROM epis_triage etr2
                                               WHERE etr2.id_episode(+) = e.id_episode)) OR NOT EXISTS
                                            (SELECT 0
                                               FROM epis_triage etr3
                                              WHERE etr3.id_episode(+) = e.id_episode))
                                       AND ei.id_episode = e.id_episode
                                       AND nvl(ei.flg_unknown, g_flg_unknown_def) = g_flg_unknown_def)
                             ORDER BY name_pat_sort, dt_birth, dt_surg;
                    ELSE
                        --Não foram encontrados episódios para os critérios defindos. Assim, o array irá vazio.
                        pk_types.open_my_cursor(o_epis);
                    END IF;
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
                                              'ALERT',
                                              'PK_MATCH',
                                              'GET_MATCH_EPISODES',
                                              o_error);
            pk_types.open_my_cursor(o_epis);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;
    --
    --
    --
    FUNCTION get_match_active_episodes
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_active  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:  Esta função devolve um array com os dados dos episódios activos para a instituição/tipo de episódio
                        que serão utilizados de forma a permitir fazer o match entre os episódios.
        
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                        I_PROF - ID do médico cirurgião que está a aceder à grelha
                                I_EPISODE - ID do episódio
                       SAIDA:   O_ACTIVE - Array de dados de todos os episódios activos
                                O_ERROR - erro
        
          CRIAÇÃO: RB 2007/01/15
          NOTAS:
        *********************************************************************************/
    
        l_id_health_plan sys_config.value%TYPE;
        l_id_cnt_hp      health_plan.id_content%TYPE;
        l_hand_off_type  sys_config.value%TYPE;
        --
        l_msg_edis_common_t002 sys_message.desc_message%TYPE;
        l_msg_edis_common_t004 sys_message.desc_message%TYPE;
        l_config_curp          VARCHAR2(10 CHAR);
    BEGIN
        l_msg_edis_common_t002 := pk_message.get_message(i_lang, 'EDIS_COMMON_T002');
        l_msg_edis_common_t004 := pk_message.get_message(i_lang, 'EDIS_COMMON_T004');
    
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
    
        l_config_curp := pk_sysconfig.get_config('MATCH_USE_CURP', i_prof);
        l_id_cnt_hp   := pk_sysconfig.get_config('ADT_NATIONAL_HEALTH_PLAN_ID', i_prof);
    
        BEGIN
            SELECT hp.id_health_plan
              INTO l_id_health_plan
              FROM health_plan hp
             WHERE hp.id_content = l_id_cnt_hp
               AND hp.flg_available = 'Y';
        EXCEPTION
            WHEN no_data_found THEN
                l_id_health_plan := NULL;
        END;
        --abre cursor com todos os episódios activos na instituição para o tipo de episódio relativo ao software em execução
        g_error := 'OPEN O_ACTIVE CURSOR';
        OPEN o_active FOR
            SELECT *
              FROM (SELECT e.id_episode,
                           e.id_visit,
                           p.id_patient,
                           pk_patient.get_pat_name(i_lang, i_prof, e.id_patient, e.id_episode) name,
                           pk_patient.get_pat_name_to_sort(i_lang, i_prof, e.id_patient, e.id_episode) name_pat_sort,
                           pk_patient.get_julian_age(i_lang, p.dt_birth, p.age) pat_age_for_order_by,
                           pk_adt.get_pat_non_disc_options(i_lang, i_prof, e.id_patient) pat_ndo,
                           pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, e.id_patient) pat_nd_icon,
                           pk_patient.get_gender(i_lang, p.gender) gender,
                           pk_patient.get_pat_age(i_lang,
                                                  p.dt_birth,
                                                  p.dt_deceased,
                                                  p.age,
                                                  i_prof.institution,
                                                  i_prof.software) pat_age,
                           decode(pk_patphoto.check_blob(p.id_patient),
                                  'N',
                                  '',
                                  pk_patphoto.get_pat_photo(i_lang, i_prof, e.id_patient, e.id_episode, ei.id_schedule)) photo,
                           p.dt_birth,
                           pk_date_utils.date_chr_short_read(i_lang, p.dt_birth, i_prof) dt_birth_formatted,
                           CASE l_config_curp
                               WHEN pk_alert_constant.g_yes THEN
                                (SELECT pr.social_security_number
                                   FROM person pr
                                  WHERE id_person = p.id_person)
                               ELSE
                                (SELECT php.num_health_plan
                                   FROM pat_health_plan php
                                  WHERE php.id_health_plan = l_id_health_plan
                                    AND php.id_patient = p.id_patient
                                    AND php.id_institution = i_prof.institution)
                           END num_health_plan,
                           --ORIS
                           pk_sr_clinical_info.get_proposed_surgery(i_lang, e.id_episode, i_prof, pk_alert_constant.g_no) desc_intervention,
                           pk_date_utils.date_send_tsz(i_lang, h.dt_target_tstz, i_prof) dt_surg,
                           --EDIS
                           ei.triage_acuity acuity,
                           ei.triage_color_text color_text,
                           decode(pk_ubu.get_episode_transportation(ei.id_episode, i_prof),
                                  NULL,
                                  decode(i_prof.software,
                                         pk_alert_constant.g_soft_edis,
                                         l_msg_edis_common_t002,
                                         l_msg_edis_common_t004),
                                  l_msg_edis_common_t004) desc_origin, -- tco 21/06/2007
                           --INP
                           cs.id_clinical_service,
                           dpt.id_department,
                           pk_translation.get_translation(i_lang, cs.code_clinical_service) desc_specialty,
                           pk_translation.get_translation(i_lang, dpt.code_department) desc_department,
                           pk_date_utils.date_send_tsz(i_lang, e.dt_begin_tstz, i_prof) dt_episode,
                           pk_date_utils.dt_chr_tsz(i_lang, e.dt_begin_tstz, i_prof) dt_episode_formatted,
                           pk_hand_off_api.get_resp_icons(i_lang, i_prof, e.id_episode, l_hand_off_type) resp_icons
                      FROM episode          e,
                           patient          p,
                           schedule_sr      h, --Tabelas específicas do ORIS
                           epis_triage      etr,
                           epis_info        ei,
                           clinical_service cs, --Tabelas específicas do INP
                           department       dpt
                     WHERE e.id_institution = i_prof.institution
                       AND e.flg_status = g_active
                       AND e.flg_ehr != pk_alert_constant.g_epis_ehr_ehr
                       AND e.id_epis_type = pk_episode.get_epis_type(i_lang, i_episode)
                          --               AND ei.id_software = i_prof.software
                       AND e.id_episode != nvl(i_episode, -1)
                       AND p.id_patient = e.id_patient
                       AND h.id_episode(+) = e.id_episode
                       AND etr.id_episode(+) = e.id_episode
                       AND ((etr.dt_begin_tstz = (SELECT MAX(etr1.dt_begin_tstz)
                                                    FROM epis_triage etr1
                                                   WHERE etr1.id_episode(+) = e.id_episode) AND EXISTS
                            (SELECT 0
                                FROM epis_triage etr2
                               WHERE etr2.id_episode(+) = e.id_episode)) OR NOT EXISTS
                            (SELECT 0
                               FROM epis_triage etr3
                              WHERE etr3.id_episode(+) = e.id_episode))
                       AND ei.id_episode = e.id_episode
                       AND nvl(ei.flg_unknown, g_flg_unknown_def) = g_flg_unknown_def
                       AND e.id_department = dpt.id_department
                       AND cs.id_clinical_service = e.id_clinical_service)
             ORDER BY name_pat_sort, dt_birth, dt_surg;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MATCH',
                                              'GET_MATCH_ACTIVE_EPISODES',
                                              o_error);
            pk_types.open_my_cursor(o_active);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    --jose silva 19-03-2007 nova funcao
    FUNCTION get_match_dpt_episodes
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_active  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:  Esta função devolve um array com os dados dos episódios activos e do mesmo serviço para a instituição/tipo de episódio
                        que serão utilizados de forma a permitir fazer o match entre os episódios.
        
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                                     I_PROF - ID do médico cirurgião que está a aceder à grelha
                                 I_EPISODE - ID do episódio
                        SAIDA:   O_ACTIVE - Array de dados de todos os episódios activos
                                 O_ERROR - erro
        *********************************************************************************/
    
        l_department     dep_clin_serv.id_department%TYPE;
        l_id_health_plan sys_config.value%TYPE;
        l_id_cnt_hp      health_plan.id_content%TYPE;
        l_config_curp    VARCHAR2(10 CHAR);
    
    BEGIN
    
        l_id_cnt_hp := pk_sysconfig.get_config('ADT_NATIONAL_HEALTH_PLAN_ID', i_prof);
        BEGIN
            SELECT hp.id_health_plan
              INTO l_id_health_plan
              FROM health_plan hp
             WHERE hp.id_content = l_id_cnt_hp
               AND hp.flg_available = 'Y';
        EXCEPTION
            WHEN no_data_found THEN
                l_id_health_plan := NULL;
        END;
    
        l_config_curp := pk_sysconfig.get_config('MATCH_USE_CURP', i_prof);
    
        --verificar qual o serviço alocado ao episódio
    
        SELECT e.id_department
          INTO l_department
          FROM episode e
         WHERE e.id_episode = i_episode;
    
        --abre cursor com todos os episódios activos na instituição para o tipo de episódio relativo ao software em execução
        g_error := 'OPEN O_ACTIVE CURSOR';
        OPEN o_active FOR
            SELECT *
              FROM (SELECT e.id_episode,
                           e.id_visit,
                           p.id_patient,
                           pk_patient.get_pat_name(i_lang, i_prof, p.id_patient, e.id_episode) name,
                           pk_patient.get_pat_name_to_sort(i_lang, i_prof, p.id_patient, e.id_episode) name_pat_sort,
                           pk_adt.get_pat_non_disc_options(i_lang, i_prof, p.id_patient) pat_ndo,
                           pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, p.id_patient) pat_nd_icon,
                           pk_patient.get_gender(i_lang, p.gender) gender,
                           pk_patient.get_pat_age(i_lang,
                                                  p.dt_birth,
                                                  p.dt_deceased,
                                                  p.age,
                                                  i_prof.institution,
                                                  i_prof.software) pat_age,
                           decode(pk_patphoto.check_blob(p.id_patient),
                                  'N',
                                  '',
                                  pk_patphoto.get_pat_photo(i_lang, i_prof, e.id_patient, e.id_episode, ei.id_schedule)) photo,
                           p.dt_birth,
                           pk_date_utils.date_chr_short_read(i_lang, p.dt_birth, i_prof) dt_birth_formatted,
                           CASE l_config_curp
                               WHEN pk_alert_constant.g_yes THEN
                                (SELECT pr.social_security_number
                                   FROM person pr
                                  WHERE id_person = p.id_person)
                               ELSE
                                (SELECT php.num_health_plan
                                   FROM pat_health_plan php
                                  WHERE php.id_health_plan = l_id_health_plan
                                    AND php.id_patient = p.id_patient
                                    AND php.id_institution = i_prof.institution)
                           END num_health_plan,
                           --INP
                           cs.id_clinical_service,
                           dpt.id_department,
                           pk_translation.get_translation(i_lang, cs.code_clinical_service) desc_specialty,
                           pk_translation.get_translation(i_lang, dpt.code_department) desc_department,
                           pk_date_utils.date_send_tsz(i_lang, e.dt_begin_tstz, i_prof) dt_episode,
                           pk_date_utils.dt_chr_tsz(i_lang, e.dt_begin_tstz, i_prof) dt_episode_formatted,
                           --Alexandre Santos 13-10-2010 ALERT-726 Changing and cancelling appointmentsChanging to another physician with the same specialty as the responsible physician. However, the responsible physician remains the same.
                           (SELECT pk_hand_off_api.get_resp_icons(i_lang, i_prof, e.id_episode, NULL)
                              FROM dual) resp_icons
                      FROM episode          e,
                           patient          p,
                           epis_info        ei,
                           clinical_service cs, --Tabelas específicas do INP
                           department       dpt
                     WHERE e.flg_status = g_active
                       AND e.id_epis_type = pk_episode.get_epis_type(i_lang, i_episode)
                       AND e.id_episode != i_episode
                       AND p.id_patient = e.id_patient
                       AND ei.id_episode = e.id_episode
                       AND nvl(ei.flg_unknown, g_flg_unknown_def) = g_flg_unknown_def
                       AND e.id_department = dpt.id_department
                       AND dpt.id_department = l_department
                       AND cs.id_clinical_service = e.id_clinical_service)
             ORDER BY name_pat_sort, dt_birth;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MATCH',
                                              'GET_MATCH_DPT_EPISODES',
                                              o_error);
            pk_types.open_my_cursor(o_active);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_match_dpt_episodes;

    FUNCTION get_match_search_epis
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        o_search          OUT pk_types.cursor_type,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_mess_no_result  OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:  Esta função devolve um array com os dados do episódios ACTIVOS obtidos através dos critérios
                        de pesquisa seleccionados (por instituição e tipo de episódio).
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                        I_PROF - ID do médico cirurgião que está a aceder à grelha
                                I_EPISODE - ID do episódio
                        I_ID_SYS_BTN_CRIT - Lista de ID'S de critérios de pesquisa.
                        I_CRIT_VAL - Lista de valores dos critérios de pesquisa
                       SAIDA:   O_SEARCH - Array de dados doos episódios obtidos
                          O_FLG_SHOW - Flag que indica se deve ser mostrada a mensagem
                        O_MSG - Descrição da mensagem
                        O_MSG_TITLE - Título da mensagem
                        O_BUTTON - Código dos botões a mostrar
                        O_MESS_NO_RESULT - Mensagem quando a pesquisa não devolver resultados
                                O_ERROR - erro
        
          CRIAÇÃO: RB 2007/01/16
          NOTAS:  Esta função foi feita de forma a não fazer distinções entre produtos na sua lógica.
                  No entanto, se algum produto tiver necessidades que aumentem a complexidade do query
                  de pesquisa temos que pensar se não será melhor cada produto ter o seu query...
        
        *********************************************************************************/
        l_limit      sys_config.value%TYPE;
        l_where      VARCHAR2(4000);
        v_where_cond VARCHAR2(4000);
        aux_sql      CLOB; --VARCHAR2(5000);
        l_count      PLS_INTEGER;
        id_doc       sys_config.value%TYPE;
        --
        xpl    VARCHAR2(0050) := '''';
        l_prof VARCHAR2(0500);
    
        l_id_health_plan sys_config.value%TYPE;
        l_id_cnt_hp      health_plan.id_content%TYPE;
        --
        l_commonm015_exception EXCEPTION;
        --
        l_msg_edis_common_t002 sys_message.desc_message%TYPE;
        l_msg_edis_common_t004 sys_message.desc_message%TYPE;
        --
        l_epis_type   episode.flg_type%TYPE;
        l_config_curp VARCHAR2(10 CHAR);
    BEGIN
        l_msg_edis_common_t002 := pk_message.get_message(i_lang, 'EDIS_COMMON_T002');
        l_msg_edis_common_t004 := pk_message.get_message(i_lang, 'EDIS_COMMON_T004');
    
        l_prof         := 'PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || ')';
        g_software_inp := pk_sysconfig.get_config('SOFTWARE_ID_INP', i_prof);
        l_id_cnt_hp    := pk_sysconfig.get_config('ADT_NATIONAL_HEALTH_PLAN_ID', i_prof);
    
        BEGIN
            SELECT hp.id_health_plan
              INTO l_id_health_plan
              FROM health_plan hp
             WHERE hp.id_content = l_id_cnt_hp
               AND hp.flg_available = 'Y';
        EXCEPTION
            WHEN no_data_found THEN
                l_id_health_plan := NULL;
        END;
        l_config_curp := pk_sysconfig.get_config('MATCH_USE_CURP', i_prof);
    
        l_epis_type := pk_episode.get_epis_type(i_lang, i_episode);
    
        IF i_prof.software = g_software_inp
           OR l_epis_type = pk_alert_constant.g_epis_type_inpatient
        THEN
            --Obtém dados de parametrização
            l_limit := pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof);
        
            --Lê critérios de pesquisa seleccionados
            g_error := 'GET SEARCH CRITERIA';
            FOR i IN 1 .. i_id_sys_btn_crit.count
            LOOP
                --lê critérios de pesquisa e preenche cláusula where
                g_error      := 'SET WHERE';
                v_where_cond := NULL;
            
                IF i_id_sys_btn_crit(i) IS NOT NULL
                THEN
                    IF NOT pk_search.get_criteria_condition(i_lang,
                                                            i_prof,
                                                            i_id_sys_btn_crit(i),
                                                            REPLACE(i_crit_val(i), '''', '%'),
                                                            v_where_cond,
                                                            o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                
                    l_where := l_where || v_where_cond;
                END IF;
            END LOOP;
        
            --js 27-03-2007
            id_doc := pk_sysconfig.get_config('DOC_TYPE_ID', i_prof.institution, i_prof.software);
        
            --Verifica se o número de registos obtidos através dos critérios de pesquisa é superior ao definido na SYS_CONFIG
            g_error := 'COUNT EPISODES';
            aux_sql := 'select count(epis.id_episode) ' || --
                       'from episode epis, visit v, patient pat, epis_info ei, epis_ext_sys ees, professional p, ' ||
                       '        ( select distinct id_patient, id_institution, num_clin_record from clin_record where id_institution = :1 ) cr, ' ||
                       '    pat_soc_attributes psa, pat_health_plan php ' || ', clinical_service cs, department dpt, ' ||
                      -- js 27-03-2007 tabelas de documentos - doc_external e pat_doc
                       '    DOC_EXTERNAL DE, PAT_DOC PD ' || --
                       ' where v.flg_status = :2 ' || --
                       'and epis.id_institution = :3 ' || --
                       ' and epis.id_visit = v.id_visit ' || --
                       'and epis.flg_status = :4 ' || --
                       ' and ei.id_software = :5 ' || --
                       ' and epis.id_episode != :6 ' || --
                       ' and ei.id_episode = epis.id_episode ' || --
                       ' and nvl(ei.flg_unknown, ''N'') = ''N'' ' || --
                       ' and ei.id_professional = p.id_professional(+)' || --
                       ' and pat.id_patient = v.id_patient ' || --
                       ' and ees.id_episode(+) = epis.id_episode ' || --
                       ' and ees.id_external_sys(+) = pk_sysconfig.get_config(''ID_EXTERNAL_SYS'', :7, :8) ' || --
                       ' and ees.id_institution(+) = ' || i_prof.institution || --
                       ' and cr.id_patient(+) = pat.id_patient ' || --
                       'and psa.id_patient (+) = pat.id_patient ' || --
                       'and psa.id_institution (+) = :9 ' || --
                       ' and php.id_health_plan(+) = :10 ' || --
                       'and php.id_institution(+) = :11 ' || --
                       ' and php.id_patient(+) = v.id_patient AND epis.id_epis_type= :l_epis_type_12 ' || --
                      -- js 27-03-2007 join com a tabela de documentos
                       ' AND DE.ID_PATIENT(+) = PAT.ID_PATIENT' || --
                       ' AND DE.ID_DOC_TYPE(+) = :13 ' || --
                       ' AND DE.FLG_STATUS(+) = ''' || g_active || '''' || --
                       ' AND PD.ID_PATIENT(+)  = PAT.ID_PATIENT  ' || --
                       ' AND PD.ID_DOC_TYPE(+) = ' || id_doc || --
                      --inp
                       ' and cs.id_clinical_service = epis.id_clinical_service ' || --
                       ' and dpt.id_department = epis.id_department ' || --
                       l_where || --
                       ' order by pat.name, pat.dt_birth ';
        
            g_error := 'GET EXECUTE IMMEDIATE 1';
            --jose silva 23-03-2007 menos parametros no execute immediate
            EXECUTE IMMEDIATE aux_sql
                INTO l_count
                USING i_prof.institution, g_active, i_prof.institution, g_active, i_prof.software, i_episode, i_prof.institution, i_prof.software, i_prof.institution, l_id_health_plan, i_prof.institution, l_epis_type, id_doc;
        
            IF l_count > l_limit
            THEN
                o_flg_show := 'Y';
                --obtem mensagem a mostrar quando a pesquisa não devolver dados
                o_mess_no_result := pk_message.get_message(i_lang, 'COMMON_M015');
                o_msg            := pk_search.get_overlimit_message(i_lang           => i_lang,
                                                                    i_prof           => i_prof,
                                                                    i_flg_has_action => pk_alert_constant.g_yes,
                                                                    i_limit          => l_limit);
                o_msg_title      := pk_message.get_message(i_lang, 'SEARCH_CRITERIA_T011');
                o_button         := 'R';
            END IF;
            --
            IF l_count = 0
            THEN
                RAISE l_commonm015_exception;
            END IF;
        
            --Abre array com os episódios obtidos
            g_error := 'OPEN O_SEARCH CURSOR';
            OPEN o_search FOR 'SELECT EPIS.ID_EPISODE, EPIS.ID_VISIT, PAT.ID_PATIENT, ' || --
             'pk_patient.get_pat_name(' || i_lang || ', profissional(' || i_prof.id || ',' || i_prof.institution || ', ' || i_prof.software || '), epis.id_patient, epis.id_episode) name, ' || --
             'pk_patient.get_pat_name_to_sort(' || i_lang || ', profissional(' || i_prof.id || ',' || i_prof.institution || ', ' || i_prof.software || '), epis.id_patient, epis.id_episode) name_pat_sort, ' || --
             'pk_patient.get_julian_age(' || i_lang || ', pat.dt_birth , pat.age) pat_age_for_order_by, ' || --
             'pk_adt.get_pat_non_disc_options(' || i_lang || ', profissional(' || i_prof.id || ',' || i_prof.institution || ', ' || i_prof.software || '), epis.id_patient) pat_ndo, ' || --
             'pk_adt.get_pat_non_disclosure_icon(' || i_lang || ', profissional(' || i_prof.id || ',' || i_prof.institution || ', ' || i_prof.software || '), epis.id_patient) pat_nd_icon, ' || --
             'pk_patient.get_gender(' || i_lang || ', pat.gender) GENDER, ' || -- 
             'PK_PATIENT.GET_PAT_AGE(' || i_lang || ', PAT.dt_birth, pat.dt_deceased, pat.age, ' || i_prof.institution || ', ' || i_prof.software || ') PAT_AGE, ' || --
             'DECODE(PK_PATPHOTO.CHECK_BLOB(PAT.ID_PATIENT),' || xpl || 'N' || xpl || ',' || xpl || xpl || --
             ', pk_patphoto.get_pat_photo(' || i_lang || ', profissional(' || i_prof.id || ',' || i_prof.institution || ', ' || i_prof.software || '),  PAT.ID_PATIENT, EPIS.ID_EPISODE, EI.ID_SCHEDULE)) PHOTO, ' || --
             'PAT.DT_BIRTH, ' || --
             'PK_DATE_UTILS.date_chr_short_read(' || i_lang || ', PAT.DT_BIRTH, ' || l_prof || ' ) DT_BIRTH_FORMATTED, ' || --
             ' decode(''' || l_config_curp || ''',''Y'', 
                            (SELECT pr.social_security_number
                               FROM person pr
                              WHERE id_person = pat.id_person),
                           PHP.NUM_HEALTH_PLAN) NUM_HEALTH_PLAN , ' || --
             'CS.ID_CLINICAL_SERVICE, DPT.ID_DEPARTMENT, PK_TRANSLATION.GET_TRANSLATION(' || i_lang || ', CS.CODE_CLINICAL_SERVICE) DESC_SPECIALTY, ' || --
             'PK_TRANSLATION.GET_TRANSLATION(' || i_lang || ', DPT.CODE_DEPARTMENT) DESC_DEPARTMENT, ' || --
             'pk_date_utils.date_send_tsz(' || i_lang || ', EPIS.DT_BEGIN_TSTZ, profissional(' || i_prof.id || ',' || i_prof.institution || ', ' || i_prof.software || ') ) DT_EPISODE, ' || --
             'PK_DATE_UTILS.DT_CHR_TSZ(' || i_lang || ', EPIS.DT_BEGIN_TSTZ, ' || l_prof || ' ) DT_EPISODE_FORMATTED, ' || --
            --Alexandre Santos 13-10-2010 ALERT-726 Changing and cancelling appointmentsChanging to another physician with the same specialty as the responsible physician. However, the responsible physician remains the same.
             '(SELECT pk_hand_off_api.get_resp_icons(' || i_lang || ', profissional(' || i_prof.id || ',' || i_prof.institution || ', ' || i_prof.software || '), epis.id_episode, NULL) FROM dual) resp_icons ' || --
             'FROM EPISODE EPIS, PATIENT PAT, EPIS_INFO EI,  EPIS_EXT_SYS EES, ' || --
             '        ( SELECT DISTINCT ID_PATIENT, ID_INSTITUTION, NUM_CLIN_RECORD FROM CLIN_RECORD WHERE ID_INSTITUTION = ' || i_prof.institution || ') CR, ' || --
             '    PAT_SOC_ATTRIBUTES PSA, PAT_HEALTH_PLAN PHP ' || --
             ', PROFESSIONAL P, CLINICAL_SERVICE CS, DEPARTMENT DPT ' || --
            -- js 27-03-2007 tabelas de documentos - doc_external e pat_doc
             ', DOC_EXTERNAL DE, PAT_DOC PD ' || --
             'WHERE EPIS.ID_INSTITUTION = ' || i_prof.institution || ' ' || --
             'AND EPIS.FLG_STATUS = ''' || g_active || ''' ' || --
             'AND EPIS.ID_EPIS_TYPE = ' || l_epis_type || ' ' || --
             'AND EPIS.ID_EPISODE != ' || i_episode || ' ' || --
             'AND EI.ID_EPISODE = EPIS.ID_EPISODE ' || --
             ' and nvl(ei.flg_unknown, ''N'') = ''N'' ' || --
             ' AND PAT.ID_PATIENT = EPIS.ID_PATIENT ' || --
             'AND EES.ID_EPISODE(+) = EPIS.ID_EPISODE ' || --
             ' and ees.id_institution(+) = ' || i_prof.institution || --
             ' AND EES.ID_EXTERNAL_SYS(+) = PK_SYSCONFIG.GET_CONFIG(''ID_EXTERNAL_SYS'', ' || i_prof.institution || ', ' || i_prof.software || ') ' || --
             'AND CR.ID_PATIENT(+) = PAT.ID_PATIENT ' || --
             'AND PSA.ID_PATIENT (+) = PAT.ID_PATIENT ' || --
             ' AND PSA.ID_INSTITUTION (+) = ' || i_prof.institution || ' ' || --
             ' AND PHP.ID_PATIENT(+) = EPIS.ID_PATIENT ' || --
             ' AND PHP.ID_INSTITUTION(+) = ' || i_prof.institution || ' ' || --
             ' AND PHP.ID_HEALTH_PLAN(+) = ' || l_id_health_plan || ' ' || --
            -- js 27-03-2007 join com a tabela de documentos
             ' AND DE.ID_PATIENT(+) = PAT.ID_PATIENT ' || --
             ' AND EI.ID_PROFESSIONAL = P.ID_PROFESSIONAL(+) AND DE.ID_DOC_TYPE(+) = ' || id_doc || --
             ' AND DE.FLG_STATUS(+) = ''' || g_active || '''' || --
             ' AND PD.ID_PATIENT(+) = PAT.ID_PATIENT ' || --
             ' AND PD.ID_DOC_TYPE(+)  = ' || id_doc || --
             'AND CS.ID_CLINICAL_SERVICE = EPIS.ID_CLINICAL_SERVICE ' || --
             'AND DPT.ID_DEPARTMENT = EPIS.ID_DEPARTMENT ' || --
             ' AND ROWNUM < ' || l_limit || --
            l_where || --
             ' ORDER BY name_pat_sort, PAT.DT_BIRTH '; --
        
        ELSIF i_prof.software IN (g_software_oris)
        THEN
            --Obtém dados de parametrização
            l_limit := pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof);
        
            --Lê critérios de pesquisa seleccionados
            g_error := 'GET SEARCH CRITERIA';
            FOR i IN 1 .. i_id_sys_btn_crit.count
            LOOP
                --lê critérios de pesquisa e preenche cláusula where
                g_error      := 'SET WHERE';
                v_where_cond := NULL;
            
                IF i_id_sys_btn_crit(i) IS NOT NULL
                THEN
                    IF NOT pk_search.get_criteria_condition(i_lang,
                                                            i_prof,
                                                            i_id_sys_btn_crit(i),
                                                            REPLACE(i_crit_val(i), '''', '%'),
                                                            v_where_cond,
                                                            o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                
                    l_where := l_where || v_where_cond;
                END IF;
            END LOOP;
        
            --Verifica se o número de registos obtidos através dos critérios de pesquisa é superior ao definido na SYS_CONFIG
            g_error := 'COUNT EPISODES';
            aux_sql := 'select count(epis.id_episode) ' || --
                       'from episode epis,  visit v, patient pat, schedule_sr sp, epis_info ei, sr_prof_team_det spt, professional p, epis_ext_sys ees, ' ||
                       '        ( select distinct id_patient, id_institution, num_clin_record from clin_record where id_institution = :1 ) cr, ' ||
                       '    pat_soc_attributes psa, pat_health_plan php ' || --
                       'where v.flg_status = :2 ' || --
                       'and epis.id_institution = :3 ' || --
                       'and epis.id_visit = v.id_visit ' || --
                       'and epis.flg_status = :4 ' || --
                       'and epis.id_epis_type = :5 ' || --
                       'and epis.id_episode != :6 ' || --
                       'and ei.id_episode = epis.id_episode ' || --
                       'and pat.id_patient = v.id_patient ' || --
                       'and sp.id_episode(+) = epis.id_episode ' || --
                       'and sp.id_institution(+) = ' || i_prof.institution || ' ' || --
                      --ORIS
                       'and spt.id_episode(+) = epis.id_episode ' || --
                       'and spt.flg_status(+) = :7 ' || --
                       ' and (spt.id_professional = spt.id_prof_team_leader ' ||
                       ' or not exists (select 1 from sr_prof_team_det spt1 where spt1.id_episode = epis.id_episode and flg_status=''' ||
                       g_active || ''')) ' || 'and p.id_professional(+) = spt.id_prof_team_leader ' ||
                       ' and ees.id_episode(+) = epis.id_episode ' || --
                       ' and ees.id_institution(+) = ' || i_prof.institution || --
                       ' and ees.id_external_sys(+) = pk_sysconfig.get_config(''ID_EXTERNAL_SYS'', :8, :9) ' || --
                       ' and cr.id_patient(+) = pat.id_patient ' || --
                       'and psa.id_patient (+) = pat.id_patient ' || --
                       'and psa.id_institution (+) = :10 ' || --
                       'and php.id_health_plan(+) = :11 ' || --
                       'and php.id_institution(+) = :12 ' || --
                       'and php.id_patient(+) = v.id_patient ' || --
                       l_where || --
                       ' order by pat.name ';
        
            g_error := 'GET EXECUTE IMMEDIATE 2';
            EXECUTE IMMEDIATE aux_sql
                INTO l_count
                USING i_prof.institution, g_active, i_prof.institution, g_active, l_epis_type, i_episode, g_active, i_prof.institution, i_prof.software, i_prof.institution, l_id_health_plan, i_prof.institution;
        
            IF l_count > l_limit
            THEN
                o_flg_show := 'Y';
                --obtem mensagem a mostrar quando a pesquisa não devolver dados
                o_mess_no_result := pk_message.get_message(i_lang, 'COMMON_M015');
                o_msg            := pk_search.get_overlimit_message(i_lang           => i_lang,
                                                                    i_prof           => i_prof,
                                                                    i_flg_has_action => pk_alert_constant.g_yes,
                                                                    i_limit          => l_limit);
                o_msg_title      := pk_message.get_message(i_lang, 'SEARCH_CRITERIA_T011');
                o_button         := 'R';
            END IF;
            --
            IF l_count = 0
            THEN
                RAISE l_commonm015_exception;
            END IF;
        
            --Abre array com os episódios obtidos
            g_error := 'OPEN O_SEARCH CURSOR';
            OPEN o_search FOR 'select * from (select epis.id_episode, v.id_visit, pat.id_patient, ' || --
             'pk_patient.get_pat_name(' || i_lang || ', profissional(' || i_prof.id || ',' || i_prof.institution || ', ' || i_prof.software || '), epis.id_patient, epis.id_episode) name, ' || --
             'pk_patient.get_pat_name_to_sort(' || i_lang || ', profissional(' || i_prof.id || ',' || i_prof.institution || ', ' || i_prof.software || '), epis.id_patient, epis.id_episode) name_pat_sort, ' || --
             'pk_patient.get_julian_age(' || i_lang || ', pat.dt_birth, pat.age) pat_age_for_order_by, ' || --
             'pk_adt.get_pat_non_disc_options(' || i_lang || ', profissional(' || i_prof.id || ',' || i_prof.institution || ', ' || i_prof.software || '), epis.id_patient) pat_ndo, ' || --
             'pk_adt.get_pat_non_disclosure_icon(' || i_lang || ', profissional(' || i_prof.id || ',' || i_prof.institution || ', ' || i_prof.software || '), epis.id_patient) pat_nd_icon, ' || --
             'pk_patient.get_gender(' || i_lang || ', pat.gender) gender, ' || --
             '   Pk_Patient.get_pat_age(' || i_lang || ', pat.dt_birth, pat.dt_deceased, pat.age, ' || i_prof.institution || ', ' || i_prof.software || ') pat_age, ' || --
             '   decode(Pk_Patphoto.check_blob(pat.id_patient), ''N'', '''', Pk_Patphoto.get_pat_photo(' || i_lang || ', profissional(' || i_prof.id || ',' || i_prof.institution || ', ' || i_prof.software || '), pat.id_patient, epis.id_episode, ei.id_schedule)) photo, ' || --
             '   pat.dt_birth, ' || --
             ' decode(''' || l_config_curp || ''',''Y'', 
                            (SELECT pr.social_security_number
                               FROM person pr
                              WHERE id_person = pat.id_person),
                           PHP.NUM_HEALTH_PLAN) NUM_HEALTH_PLAN , ' || --
             '   pk_sr_clinical_info.get_proposed_surgery (' || i_lang || ', epis.id_episode, profissional(' || i_prof.id || ', ' || i_prof.institution || ', ' || i_prof.software || '),''' || pk_alert_constant.g_no || ''') desc_intervention, ' || --
             '   pk_date_utils.date_send_tsz(' || i_lang || ', sp.dt_target_tstz, profissional(' || i_prof.id || ', ' || i_prof.institution || ', ' || i_prof.software || '))   dt_surg, ' || --
            --Alexandre Santos 13-10-2010 ALERT-726 Changing and cancelling appointmentsChanging to another physician with the same specialty as the responsible physician. However, the responsible physician remains the same.
             '(SELECT pk_hand_off_api.get_resp_icons(' || i_lang || ', profissional(' || i_prof.id || ',' || i_prof.institution || ', ' || i_prof.software || '), epis.id_episode, NULL) FROM dual) resp_icons ' || --
             'from episode epis, visit v, patient pat, schedule_sr sp, epis_info ei, sr_prof_team_det spt, professional p, epis_ext_sys ees, ' || '        ( select distinct id_patient, id_institution, num_clin_record from clin_record where id_institution = ' || i_prof.institution || ') cr, ' || '    pat_soc_attributes psa, pat_health_plan php ' || --
             ' where epis.id_institution = ' || i_prof.institution || ' ' || --
             ' and epis.id_visit = v.id_visit ' || --
             ' and epis.flg_status = ''' || g_active || ''' ' || --
             ' and epis.id_epis_type = ' || l_epis_type || --
             ' and epis.id_episode != ' || i_episode || ' ' || --
             ' and ei.id_episode = epis.id_episode ' || --
             ' and pat.id_patient = v.id_patient ' || --
             ' and sp.id_episode(+) = epis.id_episode ' || --
             ' and sp.id_institution(+) = ' || i_prof.institution || ' ' || --
            --ORIS
             ' and spt.id_episode(+) = epis.id_episode ' || --
             ' and spt.flg_status(+) = ''' || g_active || '''' || ' ' || --
             ' and (spt.id_professional = spt.id_prof_team_leader ' || ' or not exists (select 1 from sr_prof_team_det spt1 where spt1.id_episode = epis.id_episode and flg_status=''' || g_active || ''')) ' || 'and p.id_professional(+) = spt.id_prof_team_leader ' || ' and ees.id_episode(+) = epis.id_episode ' || --
             ' and ees.id_institution(+) = ' || i_prof.institution || --
             ' and ees.id_external_sys(+) = pk_sysconfig.get_config(''ID_EXTERNAL_SYS'', ' || i_prof.institution || ', ' || i_prof.software || ') ' || --
             ' and cr.id_patient(+) = pat.id_patient ' || --
             ' and psa.id_patient (+) = pat.id_patient ' || --
             ' and psa.id_institution (+) = ' || i_prof.institution || ' ' || --
             ' and php.id_health_plan(+) = ' || l_id_health_plan || ' ' || --
             ' and php.id_institution(+) = ' || i_prof.institution || ' ' || --
             ' and php.id_patient(+) = v.id_patient ' || --
            l_where || --
             ') order by name_pat_sort, dt_birth, dt_surg';
        
        ELSIF i_prof.software = g_software_edis
              OR l_epis_type = pk_alert_constant.g_epis_type_emergency
        THEN
            g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
            --Obtém dados de parametrização
            l_limit := pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof);
            --
            --Lê critérios de pesquisa seleccionados
            g_error := 'GET SEARCH CRITERIA';
            FOR i IN 1 .. i_id_sys_btn_crit.count
            LOOP
                --lê critérios de pesquisa e preenche cláusula where
                g_error      := 'SET WHERE';
                v_where_cond := NULL;
            
                IF i_id_sys_btn_crit(i) IS NOT NULL
                THEN
                    IF NOT pk_search.get_criteria_condition(i_lang,
                                                            i_prof,
                                                            i_id_sys_btn_crit(i),
                                                            REPLACE(i_crit_val(i), '''', '%'),
                                                            v_where_cond,
                                                            o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                
                    l_where := l_where || v_where_cond;
                END IF;
            END LOOP;
            --
            --Verifica se o número de registos obtidos através dos critérios de pesquisa é superior ao definido na SYS_CONFIG
            id_doc := pk_sysconfig.get_config('DOC_TYPE_ID', i_prof.institution, i_prof.software);
            --
            g_error := 'GET COUNT';
            aux_sql := 'SELECT COUNT(EPIS.ID_EPISODE) ' || --
                       ' FROM EPISODE EPIS, EPIS_INFO EI, VISIT V, PATIENT PAT, ' ||
                       'DISCHARGE D, DISCH_REAS_DEST DRT, DISCHARGE_DEST DDN, DEPARTMENT DEP, ' ||
                       'PROFESSIONAL P, SPECIALITY SP, CLIN_RECORD CR, INSTITUTION INST,  CLINICAL_SERVICE CS,' ||
                       'DEP_CLIN_SERV DCS,  EPIS_EXT_SYS EES, PAT_SOC_ATTRIBUTES PSA , PAT_DOC PD ,ORIGIN ORI, PAT_HEALTH_PLAN PHP, ' ||
                       ' DOC_EXTERNAL DE ' || --
                       ' WHERE EPIS.ID_EPISODE = EI.ID_EPISODE(+) ' || --
                       ' AND EPIS.ID_EPISODE != :10 ' || --
                       ' AND EPIS.id_epis_type = :1 ' || --I_PROF.SOFTWARE
                       ' AND V.ID_VISIT=EPIS.ID_VISIT ' || --
                       ' AND EPIS.ID_INSTITUTION=:2 ' || --I_PROF.INSTITUTION
                       ' AND V.ID_PATIENT=PAT.ID_PATIENT  ' || --
                       ' AND D.ID_EPISODE(+) = EPIS.ID_EPISODE ' || --
                       ' AND DRT.ID_DISCH_REAS_DEST(+) = D.ID_DISCH_REAS_DEST ' || --
                       ' AND D.FLG_STATUS (+)<>''' || pk_discharge_core.g_disch_status_cancel || '''' ||
                       ' AND D.FLG_STATUS (+)<>''' || pk_discharge_core.g_disch_status_reopen || ''' ' ||
                       ' AND INST.ID_INSTITUTION(+) = DRT.ID_INSTITUTION  ' || --
                       ' AND P.ID_PROFESSIONAL(+) = EI.ID_PROFESSIONAL ' || --
                       ' AND NVL(EI.FLG_UNKNOWN, ''N'') = ''N''' || ' ' || --
                       ' AND EPIS.FLG_STATUS!= :3 ' || --G_EPIS_ACTIVE
                       ' AND SP.ID_SPECIALITY(+) = P.ID_SPECIALITY ' || --
                       ' AND PSA.ID_PATIENT (+) = PAT.ID_PATIENT ' || --
                       ' AND PSA.ID_INSTITUTION (+) = :4 ' || --
                       ' AND CR.ID_PATIENT(+) = PAT.ID_PATIENT ' || --
                       ' AND CR.ID_INSTITUTION(+) =:5 ' || --I_PROF.INSTITUTION
                       ' AND DEP.ID_DEPARTMENT(+) = DCS.ID_DEPARTMENT ' || --
                       ' AND DCS.ID_DEP_CLIN_SERV(+) = DRT.ID_DEP_CLIN_SERV ' || --
                       ' AND CS.ID_CLINICAL_SERVICE(+) = DCS.ID_CLINICAL_SERVICE ' || --
                       ' AND DDN.ID_DISCHARGE_DEST(+) = DRT.ID_DISCHARGE_DEST ' || --
                       ' AND EES.ID_EPISODE(+) = EPIS.ID_EPISODE ' || --
                       ' AND EES.ID_INSTITUTION (+) =' || i_prof.institution ||
                       ' AND EES.ID_EXTERNAL_SYS(+) = PK_SYSCONFIG.GET_CONFIG(''ID_EXTERNAL_SYS'', :6, :7) ' || --
                       ' AND PD.ID_PATIENT(+) = PAT.ID_PATIENT  ' || --
                       ' AND ORI.ID_ORIGIN(+)=V.ID_ORIGIN ' || --
                       ' AND PD.ID_DOC_TYPE(+) = :8 ' || --
                       ' AND PHP.ID_INSTITUTION(+) = :9 ' || --
                       ' AND PHP.ID_HEALTH_PLAN(+) = :10 ' || --
                       ' AND PHP.ID_PATIENT(+) = V.ID_PATIENT ' || --
                       ' AND DE.ID_PATIENT(+) = PAT.ID_PATIENT' || --
                       ' AND DE.ID_DOC_TYPE(+) = ' || id_doc || --
                       ' AND DE.FLG_STATUS(+) = ''' || g_active || '''' || ' ' || --
                       l_where;
            --
            g_error := 'GET EXECUTE IMMEDIATE 3';
            EXECUTE IMMEDIATE aux_sql
                INTO l_count
                USING i_episode, l_epis_type, i_prof.institution, g_epis_inactive, i_prof.institution, i_prof.institution, i_prof.institution, i_prof.software, id_doc, i_prof.institution, l_id_health_plan;
            --
            IF l_count > l_limit
            THEN
                o_flg_show  := 'Y';
                o_msg       := pk_search.get_overlimit_message(i_lang           => i_lang,
                                                               i_prof           => i_prof,
                                                               i_flg_has_action => pk_alert_constant.g_yes,
                                                               i_limit          => l_limit);
                o_msg_title := pk_message.get_message(i_lang, 'SEARCH_CRITERIA_T011');
                o_button    := 'R';
            END IF;
            --
            IF l_count = 0
            THEN
                RAISE l_commonm015_exception;
            END IF;
            --
            g_error := 'GET CURSOR O_SEARCH';
            aux_sql := 'SELECT EI.TRIAGE_ACUITY ACUITY, EI.TRIAGE_COLOR_TEXT COLOR_TEXT, 1 RANK_ACUITY,' || --
                       'CR.NUM_CLIN_RECORD,EPIS.ID_EPISODE,PAT.ID_PATIENT, ' || --
                       'pk_patient.get_pat_name(' || i_lang || ', profissional(' || i_prof.id || ',' ||
                       i_prof.institution || ', ' || i_prof.software || '), epis.id_patient, epis.id_episode) name, ' || --
                       'pk_patient.get_pat_name_to_sort(' || i_lang || ', profissional(' || i_prof.id || ',' || --
                       i_prof.institution || ', ' || i_prof.software || --
                       '), epis.id_patient, epis.id_episode) name_pat_sort, ' || --
                       'pk_patient.get_julian_age(' || i_lang || ', pat.dt_birth , pat.age) pat_age_for_order_by, ' || --
                       'pk_adt.get_pat_non_disc_options(' || i_lang || ', profissional(' || i_prof.id || ',' ||
                       i_prof.institution || ', ' || i_prof.software || '), epis.id_patient) pat_ndo, ' || --
                       'pk_adt.get_pat_non_disclosure_icon(' || i_lang || ', profissional(' || i_prof.id || ',' ||
                       i_prof.institution || ', ' || i_prof.software || '), epis.id_patient) pat_nd_icon, ' || --
                       'pk_patient.get_gender(' || i_lang || ', pat.gender) GENDER,  ' || --
                       'PK_PATIENT.GET_PAT_AGE(' || i_lang || ', pat.dt_birth, pat.dt_deceased, pat.age, ' ||
                       i_prof.institution || ', ' || i_prof.software || ') PAT_AGE, ' || --
                       'DECODE(PK_PATPHOTO.CHECK_BLOB(PAT.ID_PATIENT), ''N'','''', PK_PATPHOTO.GET_PAT_PHOTO(' ||
                       i_lang || ', profissional(' || i_prof.id || ',' || i_prof.institution || ', ' || i_prof.software ||
                       '), PAT.ID_PATIENT, ' || 'EPIS.ID_EPISODE, EI.ID_SCHEDULE)) PHOTO, ' || --
                       'PK_TRANSLATION.GET_TRANSLATION(' || i_lang || ', CS.CODE_CLINICAL_SERVICE) CONS_TYPE, ' || --
                       'P.NICK_NAME NAME_PROF,PN.NICK_NAME NAME_NURSE, ' || --
                       '''' || g_sysdate_char || ''' DT_SERVER, ' || --
                       'pk_date_utils.date_send_tsz(' || i_lang || ', EPIS.DT_BEGIN_TSTZ, ' || l_prof || ') DT_BEGIN, ' || --
                       'pk_date_utils.date_send_tsz(' || i_lang || ', EI.DT_FIRST_OBS_TSTZ, ' || l_prof ||
                       ') DT_FIRST_OBS, ' || --
                       'PK_DATE_UTILS.GET_ELAPSED_TSZ(' || i_lang ||
                       ',EPIS.DT_BEGIN_TSTZ, CURRENT_TIMESTAMP) DATE_SEND,' || --
                       'PK_DATE_UTILS.DATE_CHAR_HOUR_TSZ(' || i_lang || ', EPIS.DT_BEGIN_TSTZ, ' || i_prof.institution || ', ' ||
                       i_prof.software || ') DT_EFECTIV, ' || --
                       'PK_SAVE.CHECK_EXIST_REC_TEMP(' || i_lang || ', EPIS.ID_EPISODE,' || i_prof.id || ') FLG_TEMP,' || --
                       'DECODE(EPIS.FLG_STATUS, ''' || g_epis_active || ''', '''',DECODE(PK_SAVE.CHECK_EXIST_REC_TEMP(' ||
                       i_lang || ', EPIS.ID_EPISODE, ' || i_prof.id || '),''Y'', PK_MESSAGE.GET_MESSAGE(' || i_lang ||
                       ', ''COMMON_M012''), '''')) DESC_TEMP,' || --
                       'LPAD(TO_CHAR(SD.RANK), 6, ''0'')||SD.IMG_NAME  IMG_TRANSP,' || --
                       'DECODE( DRT.ID_DISCHARGE_DEST,' || ''''',' || 'DECODE( DRT.ID_DEP_CLIN_SERV,' || ''''',' ||
                       'DECODE( DRT.ID_INSTITUTION, '''', '''', PK_TRANSLATION.GET_TRANSLATION(' || i_lang ||
                       ', INST.CODE_INSTITUTION)),' || 'PK_TRANSLATION.GET_TRANSLATION(' || i_lang ||
                       ', DEP.CODE_DEPARTMENT)||'' - ''||' || 'PK_TRANSLATION.GET_TRANSLATION(' || i_lang ||
                       ', CS.CODE_CLINICAL_SERVICE)),' || 'PK_TRANSLATION.GET_TRANSLATION(' || i_lang ||
                       ', DDN.CODE_DISCHARGE_DEST)) DISCH_DEST, ' || --
                       'NVL(nvl(ro.desc_room_abbreviation, Pk_Translation.GET_TRANSLATION(' || i_lang ||
                       ', RO.CODE_ABBREVIATION)),nvl(ro.desc_room, Pk_Translation.GET_TRANSLATION(' || i_lang ||
                       ', RO.CODE_ROOM)))DESC_ROOM,' || --
                       'PAT.DT_BIRTH, ' || --
                       'PK_DATE_UTILS.date_chr_short_read(' || i_lang || ', PAT.DT_BIRTH, ' || l_prof ||
                       ' ) DT_BIRTH_FORMATTED, ' || --
                       ' decode(''' || l_config_curp ||
                       ''',''Y'', 
                            (SELECT pr.social_security_number
                               FROM person pr
                              WHERE id_person = pat.id_person),
                           PHP.NUM_HEALTH_PLAN) NUM_HEALTH_PLAN , ' || --
                       'decode(pk_ubu.get_episode_transportation(ei.id_episode, :i_prof), ' || --
                       '      NULL, ' || --
                       '      decode(:i_prof_software, ' || --
                       '             :pk_alert_constant_g_soft_edis, ' || --
                       '             :l_msg_edis_common_t002, ' || --
                       '             :l_msg_edis_common_t004), ' || --
                       '      :l_msg_edis_common_t004) DESC_ORIGIN, ' || -- tco 21/06/2007
                       'Pk_Edis_Grid.GET_COMPLAINT_GRID(' || i_lang || ',' || i_prof.institution || ',' ||
                       i_prof.software || ',EPIS.ID_EPISODE)DESC_EPIS_ANAMNESIS,' || --
                       'pk_prof_utils.get_spec_signature(' || i_lang || ', ' || l_prof ||
                       ', P.ID_PROFESSIONAL, NULL, NULL) DESC_SPEC_PROF, ' || --
                       'pk_prof_utils.get_spec_signature(' || i_lang || ', ' || l_prof ||
                       ', PN.ID_PROFESSIONAL, NULL, NULL) DESC_SPEC_NURSE, ' || --
                      --Alexandre Santos 13-10-2010 ALERT-726 Changing and cancelling appointmentsChanging to another physician with the same specialty as the responsible physician. However, the responsible physician remains the same.
                       '(SELECT pk_hand_off_api.get_resp_icons(' || i_lang || ', profissional(' || i_prof.id || ',' ||
                       i_prof.institution || ', ' || i_prof.software ||
                       '), epis.id_episode, NULL) FROM dual) resp_icons ' || --
                       ' FROM EPISODE EPIS,EPIS_INFO EI,VISIT V,PATIENT PAT,DISCHARGE D, ' ||
                       'DISCH_REAS_DEST DRT,DISCHARGE_DEST DDN,DEPARTMENT DEP,PROFESSIONAL P,SPECIALITY SP,' ||
                       'PROFESSIONAL PN,SPECIALITY SN,' ||
                       'CLIN_RECORD CR,INSTITUTION INST,CLINICAL_SERVICE CS,DEP_CLIN_SERV DCS,EPIS_EXT_SYS EES,PAT_HEALTH_PLAN PHP,ORIGIN ORI,' ||
                       'PAT_SOC_ATTRIBUTES PSA ,PAT_DOC PD,GRID_TASK GT,ROOM RO,SYS_DOMAIN SD,EPIS_TRIAGE ETR, ' ||
                       ' DOC_EXTERNAL DE ' || --
                       ' WHERE EPIS.ID_EPISODE = EI.ID_EPISODE (+)' || --
                       ' AND EPIS.ID_EPISODE != ' || i_episode || ' ' || --
                       ' AND EPIS.id_epis_type = ' || l_epis_type || --
                       ' AND V.ID_VISIT=EPIS.ID_VISIT' || --
                       ' AND RO.ID_ROOM(+)=EI.ID_ROOM' || --
                       ' AND EPIS.ID_INSTITUTION=' || i_prof.institution || --
                       ' AND V.ID_PATIENT=PAT.ID_PATIENT ' || --
                       ' AND D.ID_EPISODE(+) = EPIS.ID_EPISODE ' || --
                       ' AND DRT.ID_DISCH_REAS_DEST(+) = D.ID_DISCH_REAS_DEST' || --
                       ' AND D.FLG_STATUS (+)<>''' || pk_discharge_core.g_disch_status_cancel || '''' ||
                       ' AND D.FLG_STATUS (+)<>''' || pk_discharge_core.g_disch_status_reopen || ''' ' ||
                       ' AND INST.ID_INSTITUTION(+) = DRT.ID_INSTITUTION ' || --
                       ' AND P.ID_PROFESSIONAL(+) = EI.ID_PROFESSIONAL' || --
                       ' AND SP.ID_SPECIALITY(+) = P.ID_SPECIALITY' || --
                       ' AND PN.ID_PROFESSIONAL(+)=EI.ID_FIRST_NURSE_RESP ' || --
                       ' AND NVL(EI.FLG_UNKNOWN, ''N'') = ''N''' || ' ' || --
                       ' AND SN.ID_SPECIALITY(+) = PN.ID_SPECIALITY' || --
                       ' AND EPIS.FLG_STATUS!= ''' || g_epis_inactive || '''' || --
                       ' AND PSA.ID_PATIENT (+) = PAT.ID_PATIENT' || --
                       ' AND PSA.ID_INSTITUTION (+) = ' || i_prof.institution || --
                       ' AND CR.ID_PATIENT(+) = PAT.ID_PATIENT' || --
                       ' AND CR.ID_INSTITUTION(+) =' || i_prof.institution || --
                       ' AND SD.VAL(+)=EI.FLG_STATUS' || --
                       ' AND SD.CODE_DOMAIN(+)=''EPIS_INFO.FLG_STATUS''' || --
                       ' AND SD.ID_LANGUAGE(+) = ' || i_lang || --
                       ' AND DEP.ID_DEPARTMENT(+) = DCS.ID_DEPARTMENT ' || --
                       ' AND DCS.ID_DEP_CLIN_SERV(+) = DRT.ID_DEP_CLIN_SERV' || --
                       ' AND CS.ID_CLINICAL_SERVICE(+) = DCS.ID_CLINICAL_SERVICE' || --
                       ' AND DDN.ID_DISCHARGE_DEST(+) = DRT.ID_DISCHARGE_DEST' || --
                       ' AND EES.ID_EPISODE(+) = EPIS.ID_EPISODE ' || --
                       ' AND EES.ID_INSTITUTION (+) =' || i_prof.institution || --
                       ' AND GT.ID_EPISODE (+) = EPIS.ID_EPISODE ' || --
                       ' AND EES.ID_EXTERNAL_SYS(+) = PK_SYSCONFIG.GET_CONFIG(''ID_EXTERNAL_SYS'',' ||
                       i_prof.institution || ', ' || i_prof.software || ' ) ' || --
                       ' AND PD.ID_PATIENT(+) = PAT.ID_PATIENT ' || --
                       ' AND PD.ID_DOC_TYPE(+) = ' || id_doc || --
                       ' AND ORI.ID_ORIGIN(+)=V.ID_ORIGIN ' || --
                       ' AND PHP.ID_PATIENT(+) = V.ID_PATIENT ' || --
                       ' AND PHP.ID_INSTITUTION(+) = ' || i_prof.institution || ' ' || --
                       ' AND PHP.ID_HEALTH_PLAN(+) = ' || l_id_health_plan || ' ' || --
                       ' AND DE.ID_PATIENT(+) = PAT.ID_PATIENT' || --
                       ' AND DE.ID_DOC_TYPE(+) = ' || id_doc || --
                       ' AND DE.FLG_STATUS(+) = ''' || g_active || '''' || --
                       ' AND ETR.ID_EPISODE(+)=EPIS.ID_EPISODE ' || --
                       ' AND ((ETR.DT_BEGIN_TSTZ=(SELECT MAX(ETR1.DT_BEGIN_TSTZ) ' || ' FROM EPIS_TRIAGE ETR1  ' ||
                       ' WHERE ETR1.ID_EPISODE(+)=EPIS.ID_EPISODE) ' || ' AND EXISTS (SELECT 0 ' ||
                       ' FROM EPIS_TRIAGE ETR2 ' || ' WHERE ETR2.ID_EPISODE(+)=EPIS.ID_EPISODE)) ' ||
                       ' OR NOT EXISTS (SELECT 0 ' || ' FROM EPIS_TRIAGE ETR3  ' ||
                       ' WHERE ETR3.ID_EPISODE(+)=EPIS.ID_EPISODE)) ' || --
                       ' AND ROWNUM < ' || l_limit || --
                       l_where || --
                       ' order by EPIS.DT_BEGIN_TSTZ ';
            OPEN o_search FOR aux_sql
                USING --
            i_prof, --
            i_prof.software, --
            pk_alert_constant.g_soft_edis, --
            l_msg_edis_common_t002, --
            l_msg_edis_common_t004, --
            l_msg_edis_common_t002;
        ELSIF i_prof.software = g_software_ubu --om 13/07/2007
        THEN
            g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
            --Obtém dados de parametrização
            l_limit := pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof);
            --
            --Lê critérios de pesquisa seleccionados
            g_error := 'GET SEARCH CRITERIA';
            FOR i IN 1 .. i_id_sys_btn_crit.count
            LOOP
                --lê critérios de pesquisa e preenche cláusula where
                g_error      := 'SET WHERE';
                v_where_cond := NULL;
            
                IF i_id_sys_btn_crit(i) IS NOT NULL
                THEN
                    IF NOT pk_search.get_criteria_condition(i_lang,
                                                            i_prof,
                                                            i_id_sys_btn_crit(i),
                                                            REPLACE(i_crit_val(i), '''', '%'),
                                                            v_where_cond,
                                                            o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                
                    l_where := l_where || v_where_cond;
                END IF;
            END LOOP;
            --
            --Verifica se o número de registos obtidos através dos critérios de pesquisa é superior ao definido na SYS_CONFIG
            id_doc := pk_sysconfig.get_config('DOC_TYPE_ID', i_prof.institution, i_prof.software);
            --
            g_error := 'GET COUNT';
            aux_sql := 'SELECT COUNT(EPIS.ID_EPISODE) ' || --
                       ' FROM EPISODE EPIS, EPIS_INFO EI, VISIT V,PATIENT PAT, ' ||
                       'DISCHARGE D, DISCH_REAS_DEST DRT,DISCHARGE_DEST DDN,DEPARTMENT DEP,  ' ||
                       'PROFESSIONAL P,SPECIALITY SP,CLIN_RECORD CR, INSTITUTION INST,  CLINICAL_SERVICE CS,' ||
                       'DEP_CLIN_SERV DCS,  ' ||
                      --OM 13/06/2007                      EPIS_EXT_SYS EES,
                       'PAT_SOC_ATTRIBUTES PSA , PAT_DOC PD ,ORIGIN ORI, PAT_HEALTH_PLAN PHP, DOC_EXTERNAL DE ' || --
                       ' WHERE EPIS.ID_EPISODE = EI.ID_EPISODE(+) ' || --
                       ' AND EPIS.ID_EPISODE != :10 ' || --
                       ' AND EPIS.id_epis_type = :1 ' || --I_PROF.SOFTWARE
                       ' AND V.ID_VISIT=EPIS.ID_VISIT ' || --
                       ' AND V.ID_INSTITUTION=:2 ' || --I_PROF.INSTITUTION
                       ' AND V.ID_PATIENT=PAT.ID_PATIENT  ' || --
                       ' AND D.ID_EPISODE(+) = EPIS.ID_EPISODE ' || --
                       ' AND DRT.ID_DISCH_REAS_DEST(+) = D.ID_DISCH_REAS_DEST ' || --
                       ' AND D.FLG_STATUS (+)<>''' || pk_discharge_core.g_disch_status_cancel || '''' ||
                       ' AND D.FLG_STATUS (+)<>''' || pk_discharge_core.g_disch_status_reopen || ''' ' ||
                       ' AND INST.ID_INSTITUTION(+) = DRT.ID_INSTITUTION  ' || --
                       ' AND P.ID_PROFESSIONAL(+) = EI.ID_PROFESSIONAL ' || --
                       ' AND NVL(EI.FLG_UNKNOWN, ''N'') = ''N''' || ' ' || --
                      --OM 13/06/2007                                ' AND EPIS.FLG_STATUS!= :3 ' || --G_EPIS_ACTIVE
                       ' AND SP.ID_SPECIALITY(+) = P.ID_SPECIALITY ' || --
                       ' AND PSA.ID_PATIENT (+) = PAT.ID_PATIENT ' || --
                       ' AND PSA.ID_INSTITUTION(+) = :4 ' || --
                       ' AND CR.ID_PATIENT(+) = PAT.ID_PATIENT ' || --
                       ' AND CR.ID_INSTITUTION(+) = ' || i_prof.institution || --
                       ' AND DEP.ID_DEPARTMENT(+) = DCS.ID_DEPARTMENT ' || --
                       ' AND DCS.ID_DEP_CLIN_SERV(+) = DRT.ID_DEP_CLIN_SERV ' || --
                       ' AND CS.ID_CLINICAL_SERVICE(+) = DCS.ID_CLINICAL_SERVICE ' || --
                       ' AND DDN.ID_DISCHARGE_DEST(+) = DRT.ID_DISCHARGE_DEST ' || --
                      --OM 13/06/2007                       ' AND EES.ID_EPISODE(+) = EPIS.ID_EPISODE ' ||
                      --OM 13/06/2007                      ' AND EES.ID_INSTITUTION (+) =' || i_prof.institution ||
                      --OM 13/06/2007                      ' AND EES.ID_EXTERNAL_SYS(+) = PK_SYSCONFIG.GET_CONFIG(''ID_EXTERNAL_SYS'', :5, :6) ' ||
                       ' AND PD.ID_PATIENT(+) = PAT.ID_PATIENT  ' || --
                       ' AND ORI.ID_ORIGIN(+)=V.ID_ORIGIN ' || --
                       ' AND PD.ID_DOC_TYPE(+) = :7 ' || --
                       ' AND PHP.ID_INSTITUTION(+) = :8 ' || --
                       ' AND PHP.ID_HEALTH_PLAN(+) = :9 ' || --
                       ' AND PHP.ID_PATIENT(+) = V.ID_PATIENT ' || --
                       ' AND DE.ID_PATIENT(+) = PAT.ID_PATIENT' || --
                       ' AND DE.ID_DOC_TYPE(+) = ' || id_doc || --
                       ' AND DE.FLG_STATUS(+) = ''' || g_active || '''' || --
                       l_where;
            --
            g_error := 'GET EXECUTE IMMEDIATE 4';
            EXECUTE IMMEDIATE aux_sql
                INTO l_count
                USING i_episode, l_epis_type, i_prof.institution, i_prof.institution, id_doc, i_prof.institution, l_id_health_plan;
            --
            IF l_count > l_limit
            THEN
                o_flg_show  := 'Y';
                o_msg       := pk_search.get_overlimit_message(i_lang           => i_lang,
                                                               i_prof           => i_prof,
                                                               i_flg_has_action => pk_alert_constant.g_yes,
                                                               i_limit          => l_limit);
                o_msg_title := pk_message.get_message(i_lang, 'SEARCH_CRITERIA_T011');
                o_button    := 'R';
            END IF;
            --
            IF l_count = 0
            THEN
                RAISE l_commonm015_exception;
            END IF;
            --
            g_error := 'GET CURSOR O_SEARCH';
            aux_sql := 'SELECT EI.TRIAGE_ACUITY ACUITY, EI.TRIAGE_COLOR_TEXT COLOR_TEXT, 1 RANK_ACUITY,' || --
                       'CR.NUM_CLIN_RECORD,EPIS.ID_EPISODE,PAT.ID_PATIENT, ' || --
                       'pk_patient.get_pat_name(' || i_lang || ', profissional(' || i_prof.id || ',' ||
                       i_prof.institution || ', ' || i_prof.software || '), epis.id_patient, epis.id_episode) name, ' || --
                       'pk_patient.get_pat_name_to_sort(' || i_lang || ', profissional(' || i_prof.id || ',' ||
                       i_prof.institution || ', ' || i_prof.software ||
                       '), epis.id_patient, epis.id_episode) name_pat_sort, ' || --
                       'pk_patient.get_julian_age(' || i_lang || ', pat.dt_birth, pat.age) pat_age_for_order_by, ' || --
                       'pk_adt.get_pat_non_disc_options(' || i_lang || ', profissional(' || i_prof.id || ',' ||
                       i_prof.institution || ', ' || i_prof.software || '), epis.id_patient) pat_ndo, ' || --
                       'pk_adt.get_pat_non_disclosure_icon(' || i_lang || ', profissional(' || i_prof.id || ',' ||
                       i_prof.institution || ', ' || i_prof.software || '), epis.id_patient) pat_nd_icon, ' || --
                       'pk_patient.get_gender(' || i_lang || ', pat.gender) GENDER,  ' || --
                       'PK_PATIENT.GET_PAT_AGE(' || i_lang || ', pat.dt_birth, pat.dt_deceased, pat.age, ' ||
                       i_prof.institution || ', ' || i_prof.software || ') PAT_AGE, ' || --
                       'DECODE(PK_PATPHOTO.CHECK_BLOB(PAT.ID_PATIENT), ''N'','''', PK_PATPHOTO.GET_PAT_PHOTO(' ||
                       i_lang || --
                       ', profissional(' || i_prof.id || ',' || i_prof.institution || ', ' || i_prof.software || --
                       '), PAT.ID_PATIENT, EPIS.ID_EPISODE, EI.ID_SCHEDULE)) PHOTO, ' || --
                       'PK_TRANSLATION.GET_TRANSLATION(' || i_lang || ', CS.CODE_CLINICAL_SERVICE) CONS_TYPE, ' || --
                       'P.NICK_NAME NAME_PROF,PN.NICK_NAME NAME_NURSE, ' || '''' || g_sysdate_char || ''' DT_SERVER, ' || --
                       'pk_date_utils.date_send_tsz(' || i_lang || ', EPIS.DT_BEGIN_TSTZ, ' || l_prof || ') DT_BEGIN, ' || --
                       'pk_date_utils.date_send_tsz(' || i_lang || ', EI.DT_FIRST_OBS_TSTZ, ' || l_prof ||
                       ') DT_FIRST_OBS, ' || --
                       'PK_DATE_UTILS.GET_ELAPSED_TSZ(' || i_lang ||
                       ',EPIS.DT_BEGIN_TSTZ, CURRENT_TIMESTAMP) DATE_SEND,' || --
                       'PK_DATE_UTILS.DATE_CHAR_HOUR_TSZ(' || i_lang || ', EPIS.DT_BEGIN_TSTZ, ' || i_prof.institution || ', ' ||
                       i_prof.software || ') DT_EFECTIV, ' || --
                       'PK_SAVE.CHECK_EXIST_REC_TEMP(' || i_lang || ', EPIS.ID_EPISODE,' || i_prof.id || ') FLG_TEMP,' || --
                       'DECODE(EPIS.FLG_STATUS, ''' || g_epis_active || ''', '''',DECODE(PK_SAVE.CHECK_EXIST_REC_TEMP(' ||
                       i_lang || ', EPIS.ID_EPISODE, ' || i_prof.id || '),''Y'', PK_MESSAGE.GET_MESSAGE(' || i_lang ||
                       ', ''COMMON_M012''), '''')) DESC_TEMP,' || --
                       'LPAD(TO_CHAR(SD.RANK), 6, ''0'')||SD.IMG_NAME  IMG_TRANSP,' || --
                       'DECODE( DRT.ID_DISCHARGE_DEST,' || ''''',' || 'DECODE( DRT.ID_DEP_CLIN_SERV,' || ''''',' ||
                       'DECODE( DRT.ID_INSTITUTION, '''', '''', PK_TRANSLATION.GET_TRANSLATION(' || i_lang ||
                       ', INST.CODE_INSTITUTION)),' || 'PK_TRANSLATION.GET_TRANSLATION(' || i_lang ||
                       ', DEP.CODE_DEPARTMENT)||'' - ''||' || 'PK_TRANSLATION.GET_TRANSLATION(' || i_lang ||
                       ', CS.CODE_CLINICAL_SERVICE)),' || 'PK_TRANSLATION.GET_TRANSLATION(' || i_lang ||
                       ', DDN.CODE_DISCHARGE_DEST)) DISCH_DEST, ' || --
                       'NVL(nvl(ro.desc_room_abbreviation, Pk_Translation.GET_TRANSLATION(' || i_lang ||
                       ', RO.CODE_ABBREVIATION)),nvl(ro.desc_room, Pk_Translation.GET_TRANSLATION(' || i_lang ||
                       ', RO.CODE_ROOM))) DESC_ROOM, ' || --
                       'PAT.DT_BIRTH, ' || --
                       'PK_DATE_UTILS.date_chr_short_read(' || i_lang || ', PAT.DT_BIRTH, ' || l_prof ||
                       ' ) DT_BIRTH_FORMATTED, ' || --
                       ' decode(''' || l_config_curp ||
                       ''',''Y'', 
                            (SELECT pr.social_security_number
                               FROM person pr
                              WHERE id_person = pat.id_person),
                           PHP.NUM_HEALTH_PLAN) NUM_HEALTH_PLAN , ' || --
                       'decode(pk_ubu.get_episode_transportation(ei.id_episode, :i_prof), ' || --
                       '      NULL, ' || --
                       '      decode(:i_prof_software, ' || --
                       '             :pk_alert_constant_g_soft_edis, ' || --
                       '             :l_msg_edis_common_t002, ' || --
                       '             :l_msg_edis_common_t004), ' || --
                       '      :l_msg_edis_common_t004) DESC_ORIGIN, ' || -- tco 21/06/2007
                       'Pk_Edis_Grid.GET_COMPLAINT_GRID(' || i_lang || ',' || i_prof.institution || ',' ||
                       i_prof.software || ',EPIS.ID_EPISODE)DESC_EPIS_ANAMNESIS,' || --
                       'pk_prof_utils.get_spec_signature(' || i_lang || ', ' || l_prof ||
                       ', P.ID_PROFESSIONAL, NULL, NULL) DESC_SPEC_PROF, ' || --
                       'pk_prof_utils.get_spec_signature(' || i_lang || ', ' || l_prof ||
                       ', PN.ID_PROFESSIONAL, NULL, NULL) DESC_SPEC_NURSE, ' || --
                      --Alexandre Santos 13-10-2010 ALERT-726 Changing and cancelling appointmentsChanging to another physician with the same specialty as the responsible physician. However, the responsible physician remains the same.
                       '(SELECT pk_hand_off_api.get_resp_icons(' || i_lang || ', profissional(' || i_prof.id || ',' ||
                       i_prof.institution || ', ' || i_prof.software ||
                       '), epis.id_episode, NULL) FROM dual) resp_icons ' || --
                       ' FROM EPISODE EPIS,EPIS_INFO EI,  VISIT V,PATIENT PAT,DISCHARGE D, ' ||
                       'DISCH_REAS_DEST DRT,DISCHARGE_DEST DDN,DEPARTMENT DEP,PROFESSIONAL P,SPECIALITY SP,' ||
                       'PROFESSIONAL PN,SPECIALITY SN,' ||
                       'CLIN_RECORD CR,INSTITUTION INST,CLINICAL_SERVICE CS,DEP_CLIN_SERV DCS,EPIS_EXT_SYS EES,PAT_HEALTH_PLAN PHP,ORIGIN ORI,' ||
                       'PAT_SOC_ATTRIBUTES PSA ,PAT_DOC PD,GRID_TASK GT,ROOM RO,SYS_DOMAIN SD,EPIS_TRIAGE ETR, ' ||
                       ' DOC_EXTERNAL DE ' || --
                       ' WHERE EPIS.ID_EPISODE = EI.ID_EPISODE (+)' || --
                       ' AND EPIS.ID_EPISODE != ' || i_episode || ' ' || --
                       ' AND EPIS.ID_EPIS_TYPE = ' || l_epis_type || --
                       ' AND V.ID_VISIT=EPIS.ID_VISIT' || --
                       ' AND EPIS.ID_INSTITUTION =' || i_prof.institution || --
                       ' AND RO.ID_ROOM(+)=EI.ID_ROOM' || --
                       ' AND V.ID_INSTITUTION=' || i_prof.institution || --
                       ' AND V.ID_PATIENT=PAT.ID_PATIENT ' || --
                       ' AND D.ID_EPISODE(+) = EPIS.ID_EPISODE ' || --
                       ' AND DRT.ID_DISCH_REAS_DEST(+) = D.ID_DISCH_REAS_DEST' || --
                       ' AND D.FLG_STATUS (+)<>''' || pk_discharge_core.g_disch_status_cancel || '''' ||
                       ' AND D.FLG_STATUS (+)<>''' || pk_discharge_core.g_disch_status_reopen || ''' ' ||
                       ' AND INST.ID_INSTITUTION(+) = DRT.ID_INSTITUTION ' || --
                       ' AND P.ID_PROFESSIONAL(+) = EI.ID_PROFESSIONAL' || --
                       ' AND SP.ID_SPECIALITY(+) = P.ID_SPECIALITY' || --
                       ' AND PN.ID_PROFESSIONAL(+)=EI.ID_FIRST_NURSE_RESP ' || --
                       ' AND NVL(EI.FLG_UNKNOWN, ''N'') = ''N''' || ' ' || --
                       ' AND SN.ID_SPECIALITY(+) = PN.ID_SPECIALITY' || --
                       ' AND EPIS.FLG_STATUS!= ''' || g_epis_inactive || '''' || --
                       ' AND PSA.ID_PATIENT (+) = PAT.ID_PATIENT' || --
                       ' AND PSA.ID_INSTITUTION (+) = ' || i_prof.institution || --
                       ' AND CR.ID_PATIENT(+) = PAT.ID_PATIENT' || --
                       ' AND CR.ID_INSTITUTION(+) = ' || i_prof.institution || --
                       ' AND SD.VAL(+)=EI.FLG_STATUS' || --
                       ' AND SD.CODE_DOMAIN(+)=''EPIS_INFO.FLG_STATUS''' || --
                       ' AND SD.ID_LANGUAGE(+) = ' || i_lang || --
                       ' AND DEP.ID_DEPARTMENT(+) = DCS.ID_DEPARTMENT ' || --
                       ' AND DCS.ID_DEP_CLIN_SERV(+) = DRT.ID_DEP_CLIN_SERV' || --
                       ' AND CS.ID_CLINICAL_SERVICE(+) = DCS.ID_CLINICAL_SERVICE' || --
                       ' AND DDN.ID_DISCHARGE_DEST(+) = DRT.ID_DISCHARGE_DEST' || --
                       ' AND EES.ID_EPISODE(+) = EPIS.ID_EPISODE ' || --
                       ' AND EES.ID_INSTITUTION (+) =' || i_prof.institution || --
                       ' AND GT.ID_EPISODE (+) = EPIS.ID_EPISODE ' || --
                      --OM 13/06/2007 NAO COLOCADO' AND EES.ID_EXTERNAL_SYS(+) = PK_SYSCONFIG.GET_CONFIG(''ID_EXTERNAL_SYS'',' || i_prof.institution || ', ' || i_prof.software || ' ) ' ||
                       ' AND PD.ID_PATIENT(+) = PAT.ID_PATIENT ' || --
                       ' AND PD.ID_DOC_TYPE(+) = ' || id_doc || --
                       ' AND ORI.ID_ORIGIN(+)=V.ID_ORIGIN ' || --
                       ' AND PHP.ID_PATIENT(+) = V.ID_PATIENT ' || --
                       ' AND PHP.ID_INSTITUTION(+) = ' || i_prof.institution || ' ' || --
                       ' AND PHP.ID_HEALTH_PLAN(+) = ' || l_id_health_plan || ' ' || --
                       ' AND DE.ID_PATIENT(+) = PAT.ID_PATIENT' || --
                       ' AND DE.ID_DOC_TYPE(+) = ' || id_doc || --
                       ' AND DE.FLG_STATUS(+) = ''' || g_active || '''' || --
                       ' AND ETR.ID_EPISODE(+)=EPIS.ID_EPISODE ' || --
                       ' AND ((ETR.DT_BEGIN_TSTZ=(SELECT MAX(ETR1.DT_BEGIN_TSTZ) ' || ' FROM EPIS_TRIAGE ETR1  ' ||
                       ' WHERE ETR1.ID_EPISODE(+)=EPIS.ID_EPISODE) ' || ' AND EXISTS (SELECT 0 ' ||
                       ' FROM EPIS_TRIAGE ETR2 ' || ' WHERE ETR2.ID_EPISODE(+)=EPIS.ID_EPISODE)) ' ||
                       ' OR NOT EXISTS (SELECT 0 ' || ' FROM EPIS_TRIAGE ETR3  ' ||
                       ' WHERE ETR3.ID_EPISODE(+)=EPIS.ID_EPISODE)) ' || --
                       ' AND ROWNUM < ' || l_limit || --
                       l_where || --
                       ' ORDER BY EPIS.DT_BEGIN_TSTZ ';
        
            OPEN o_search FOR aux_sql
                USING --
            i_prof, --
            i_prof.software, --
            pk_alert_constant.g_soft_edis, --
            l_msg_edis_common_t002, --
            l_msg_edis_common_t004, --
            l_msg_edis_common_t002;
        
        ELSE
            pk_types.open_my_cursor(o_search);
        END IF;
        --
        RETURN TRUE;
        --
    EXCEPTION
        WHEN l_commonm015_exception THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang,
                                   'T_COMMON_ERROR',
                                   pk_message.get_message(i_lang, 'COMMON_M015'),
                                   g_error,
                                   'ALERT',
                                   'PK_MATCH',
                                   'GET_MATCH_SEARCH_EPIS',
                                   NULL,
                                   'U');
            
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_types.open_my_cursor(o_search);
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MATCH',
                                              'GET_MATCH_SEARCH_EPIS',
                                              o_error);
            pk_types.open_my_cursor(o_search);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    --
    FUNCTION set_match_interv
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode_temp IN episode.id_episode%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_patient      IN patient.id_patient%TYPE,
        i_patient_temp IN patient.id_patient%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rowids table_varchar;
    BEGIN
    
        -- INTERV_EVALUATION
        l_rowids := table_varchar();
        g_error  := 'Call ts_interv_evaluation.upd UPDATE id_episode';
        ts_interv_evaluation.upd(id_episode_in  => i_episode,
                                 id_episode_nin => FALSE,
                                 where_in       => 'id_episode = ' || i_episode_temp,
                                 rows_out       => l_rowids);
    
        g_error := 'Call ts_interv_evaluation.upd UPDATE id_patient';
        ts_interv_evaluation.upd(id_patient_in  => i_patient,
                                 id_patient_nin => FALSE,
                                 where_in       => 'id_patient = ' || i_patient_temp,
                                 rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update table INTERV_EVALUATION';
        t_data_gov_mnt.process_update(i_lang,
                                      i_prof,
                                      'INTERV_EVALUATION',
                                      l_rowids,
                                      o_error,
                                      table_varchar('ID_EPISODE', 'ID_PATIENT'));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MATCH',
                                              'SET_MATCH_INTERV',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_match_interv;

    FUNCTION set_match_icnp_epis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode_temp IN episode.id_episode%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rowids    table_varchar;
        l_visit     visit.id_visit%TYPE;
        l_epis_type epis_type.id_epis_type%TYPE;
    
        CURSOR c_cur(x_epis episode.id_episode%TYPE) IS
            SELECT e.id_visit, e.id_epis_type
              FROM episode e
             WHERE e.id_episode = x_epis;
    
    BEGIN
        g_error := 'OPEN CURSOR c_cur';
        OPEN c_cur(i_episode);
        FETCH c_cur
            INTO l_visit, l_epis_type;
        CLOSE c_cur;
    
        --ICNP_EPIS_DIAGNOSIS
        l_rowids := table_varchar();
    
        g_error := 'Call ts_icnp_epis_diagnosis.upd id_visit/id_epis_type/id_episode';
        ts_icnp_epis_diagnosis.upd(id_visit_in      => l_visit,
                                   id_visit_nin     => FALSE,
                                   id_epis_type_in  => l_epis_type,
                                   id_epis_type_nin => FALSE,
                                   id_episode_in    => i_episode,
                                   id_episode_nin   => FALSE,
                                   where_in         => 'id_episode = ' || i_episode_temp,
                                   rows_out         => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update  ICNP_EPIS_DIAGNOSIS';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'ICNP_EPIS_DIAGNOSIS',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_VISIT',
                                                                      'ID_EPIS_TYPE',
                                                                      'ID_EPISODE',
                                                                      'ID_PATIENT'));
    
        -- ICNP_EPIS_DIAGNOSIS_HIST
        l_rowids := table_varchar();
    
        g_error := 'Call ts_icnp_epis_diagnosis_hist.upd id_visit/id_epis_type/id_episode';
        ts_icnp_epis_diagnosis_hist.upd(id_episode_in    => i_episode,
                                        id_episode_nin   => FALSE,
                                        id_epis_type_in  => l_epis_type,
                                        id_epis_type_nin => FALSE,
                                        id_visit_in      => l_visit,
                                        id_visit_nin     => FALSE,
                                        where_in         => 'id_episode = ' || i_episode_temp,
                                        rows_out         => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update  ICNP_EPIS_DIAGNOSIS_HIST';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'ICNP_EPIS_DIAGNOSIS_HIST',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_VISIT',
                                                                      'ID_EPIS_TYPE',
                                                                      'ID_EPISODE',
                                                                      'ID_PATIENT'));
    
        -- ICNP_EPIS_INTERVENTION
        l_rowids := table_varchar();
    
        g_error := 'Call ts_icnp_epis_intervention.upd id_episode';
        ts_icnp_epis_intervention.upd(id_episode_in  => i_episode,
                                      id_episode_nin => FALSE,
                                      where_in       => 'id_episode = ' || i_episode_temp,
                                      rows_out       => l_rowids);
    
        g_error := 'Call icnp_epis_intervention_hist.upd id_episode_origin';
        ts_icnp_epis_intervention.upd(id_episode_origin_in => i_episode,
                                      id_episode_nin       => FALSE,
                                      where_in             => 'id_episode_origin = ' || i_episode_temp,
                                      rows_out             => l_rowids);
    
        g_error := 'Call icnp_epis_intervention_hist.upd id_episode_destination';
        ts_icnp_epis_intervention.upd(id_episode_destination_in  => i_episode,
                                      id_episode_destination_nin => FALSE,
                                      where_in                   => 'id_episode_destination = ' || i_episode_temp,
                                      rows_out                   => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update table ICNP_EPIS_INTERVENTION';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'ICNP_EPIS_INTERVENTION',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE',
                                                                      'ID_EPISODE_ORIGIN',
                                                                      'ID_EPISODE_DESTINATION',
                                                                      'ID_PATIENT'));
    
        -- ICNP_EPIS_INTERVENTION_HIST
        l_rowids := table_varchar();
    
        g_error := 'Call icnp_epis_intervention_hist.upd id_episode';
        ts_icnp_epis_intervention_hist.upd(id_episode_in  => i_episode,
                                           id_episode_nin => FALSE,
                                           where_in       => 'id_episode = ' || i_episode_temp,
                                           rows_out       => l_rowids);
    
        g_error := 'Call icnp_epis_intervention_hist.upd id_episode_origin';
        ts_icnp_epis_intervention_hist.upd(id_episode_origin_in => i_episode,
                                           id_episode_nin       => FALSE,
                                           where_in             => 'id_episode_origin = ' || i_episode_temp,
                                           rows_out             => l_rowids);
    
        g_error := 'Call icnp_epis_intervention_hist.upd id_episode_destination';
        ts_icnp_epis_intervention_hist.upd(id_episode_destination_in  => i_episode,
                                           id_episode_destination_nin => FALSE,
                                           where_in                   => 'id_episode_destination = ' || i_episode_temp,
                                           rows_out                   => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update table ICNP_EPIS_INTERVENTION_HIST';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'ICNP_EPIS_INTERVENTION_HIST',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE',
                                                                      'ID_EPISODE_ORIGIN',
                                                                      'ID_EPISODE_DESTINATION',
                                                                      'ID_PATIENT'));
    
        -- ICNP_SUGGEST_INTERV
        l_rowids := table_varchar();
    
        g_error := 'Call ts_icnp_suggest_interv.upd id_episode';
        ts_icnp_suggest_interv.upd(id_episode_in  => i_episode,
                                   id_episode_nin => FALSE,
                                   where_in       => 'id_episode = ' || i_episode_temp,
                                   rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update table ICNP_SUGGEST_INTERV';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'ICNP_SUGGEST_INTERV',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE', 'ID_PATIENT'));
    
        -- ICNP_SUGGEST_INTERV_HIST
        l_rowids := table_varchar();
    
        g_error := 'Call ts_ICNP_SUGGEST_INTERV_HIST.upd id_episode';
        ts_icnp_suggest_interv_hist.upd(id_episode_in  => i_episode,
                                        id_episode_nin => FALSE,
                                        where_in       => 'id_episode = ' || i_episode_temp,
                                        rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update table ICNP_SUGGEST_INTERV_HIST';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'ICNP_SUGGEST_INTERV_HIST',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE', 'ID_PATIENT'));
    
        -- ICNP_INTERV_PLAN
        l_rowids := table_varchar();
    
        g_error := 'Call ts_icnp_interv_plan.upd id_episode_write';
        ts_icnp_interv_plan.upd(id_episode_write_in  => i_episode,
                                id_episode_write_nin => FALSE,
                                where_in             => 'id_episode_write = ' || i_episode_temp,
                                rows_out             => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update table ICNP_INTERV_PLAN';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'ICNP_INTERV_PLAN',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE_WRITE'));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MATCH',
                                              'SET_MATCH_ICNP_EPIS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_match_icnp_epis;

    FUNCTION set_match_nurse_epis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode_temp IN episode.id_episode%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rowids table_varchar;
        l_visit  visit.id_visit%TYPE;
    BEGIN
    
        l_rowids := table_varchar();
        --, id_episode_origin_in => ,id_episode_destination_in => , id_prev_episode_in => , id_patient_in => )
    
        -- NURSE_TEA_REQ
        l_rowids := table_varchar();
    
        g_error := 'Call pk_episode.get_id_visit ';
        l_visit := pk_episode.get_id_visit(i_episode => i_episode);
    
        g_error := 'Call ts_nurse_tea_req.upd id_episode id_visit';
        ts_nurse_tea_req.upd(id_episode_in  => i_episode,
                             id_episode_nin => FALSE,
                             id_visit_in    => l_visit,
                             id_visit_nin   => FALSE,
                             where_in       => 'id_episode = ' || i_episode_temp,
                             rows_out       => l_rowids);
    
        g_error := 'Call ts_nurse_tea_req.upd id_prev_episode';
        ts_nurse_tea_req.upd(id_prev_episode_in  => i_episode,
                             id_prev_episode_nin => FALSE,
                             where_in            => 'id_prev_episode = ' || i_episode_temp,
                             rows_out            => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update table NURSE_TEA_REQ';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NURSE_TEA_REQ',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE',
                                                                      'ID_VISIT',
                                                                      'ID_PREV_EPISODE',
                                                                      'ID_PATIENT'));
    
        -- NURSE_TEA_REQ_HIST
        l_rowids := table_varchar();
    
        g_error := 'Call ts_nurse_tea_req_hist.upd id_episode, id_vist';
        ts_nurse_tea_req_hist.upd(id_episode_in  => i_episode,
                                  id_episode_nin => FALSE,
                                  id_visit_in    => l_visit,
                                  id_visit_nin   => FALSE,
                                  where_in       => 'id_episode = ' || i_episode_temp,
                                  rows_out       => l_rowids);
    
        g_error := 'Call ts_nurse_tea_req_hist.upd id_prev_episode';
        ts_nurse_tea_req_hist.upd(id_prev_episode_in  => i_episode,
                                  id_prev_episode_nin => FALSE,
                                  where_in            => 'id_prev_episode = ' || i_episode_temp,
                                  rows_out            => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update table NURSE_TEA_REQ_HIST';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NURSE_TEA_REQ_HIST',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE',
                                                                      'ID_PREV_EPISODE',
                                                                      'ID_PATIENT',
                                                                      'ID_VISIT'));
    
        -- NURSE_DISCHARGE
        g_error := 'UPDATE nurse_discharge (id_episode)';
        UPDATE nurse_discharge
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MATCH',
                                              'SET_MATCH_NURSE_EPIS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_match_nurse_epis;

    FUNCTION set_match_nurse_pat
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_patient_temp IN patient.id_patient%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rowids table_varchar;
        l_visit  visit.id_visit%TYPE;
    BEGIN
    
        l_rowids := table_varchar();
        --, id_episode_origin_in => ,id_episode_destination_in => , id_prev_episode_in => , id_patient_in => )
    
        -- NURSE_TEA_REQ
        l_rowids := table_varchar();
    
        g_error := 'Call ts_nurse_tea_req.upd id_patient';
        ts_nurse_tea_req.upd(id_patient_in  => i_patient,
                             id_patient_nin => FALSE,
                             where_in       => 'id_patient = ' || i_patient_temp,
                             rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update table NURSE_TEA_REQ';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NURSE_TEA_REQ',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE',
                                                                      'ID_VISIT',
                                                                      'ID_PREV_EPISODE',
                                                                      'ID_PATIENT'));
    
        -- NURSE_TEA_REQ_HIST
        l_rowids := table_varchar();
    
        g_error := 'Call ts_nurse_tea_req_hist.upd id_patient';
        ts_nurse_tea_req_hist.upd(id_patient_in  => i_patient,
                                  id_patient_nin => FALSE,
                                  where_in       => 'id_patient = ' || i_patient_temp,
                                  rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update table NURSE_TEA_REQ_HIST';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NURSE_TEA_REQ_HIST',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE',
                                                                      'ID_PREV_EPISODE',
                                                                      'ID_PATIENT',
                                                                      'ID_VISIT'));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MATCH',
                                              'SET_MATCH_NURSE_PAT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_match_nurse_pat;

    FUNCTION set_match_icnp_pat
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_patient_temp IN patient.id_patient%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rowids table_varchar;
    
    BEGIN
    
        --ICNP_EPIS_DIAGNOSIS
        l_rowids := table_varchar();
    
        g_error := 'Call ts_icnp_epis_diagnosis.upd id_patient';
        ts_icnp_epis_diagnosis.upd(id_patient_in  => i_patient,
                                   id_patient_nin => FALSE,
                                   where_in       => 'id_patient = ' || i_patient_temp,
                                   rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update  ICNP_EPIS_DIAGNOSIS';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'ICNP_EPIS_DIAGNOSIS',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_VISIT',
                                                                      'ID_EPIS_TYPE',
                                                                      'ID_EPISODE',
                                                                      'ID_PATIENT'));
    
        -- ICNP_EPIS_DIAGNOSIS_HIST
        l_rowids := table_varchar();
    
        g_error := 'Call ts_icnp_epis_diagnosis_hist.upd id_patient';
        ts_icnp_epis_diagnosis_hist.upd(id_patient_in  => i_patient,
                                        id_patient_nin => FALSE,
                                        where_in       => 'id_patient = ' || i_patient_temp,
                                        rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update  ICNP_EPIS_DIAGNOSIS_HIST';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'ICNP_EPIS_DIAGNOSIS_HIST',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_VISIT',
                                                                      'ID_EPIS_TYPE',
                                                                      'ID_EPISODE',
                                                                      'ID_PATIENT'));
    
        -- ICNP_EPIS_INTERVENTION
        l_rowids := table_varchar();
    
        g_error := 'Call icnp_epis_intervention_hist.upd i_patient';
        ts_icnp_epis_intervention.upd(id_patient_in  => i_patient,
                                      id_patient_nin => FALSE,
                                      where_in       => 'id_patient = ' || i_patient_temp,
                                      rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update table ICNP_EPIS_INTERVENTION';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'ICNP_EPIS_INTERVENTION',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE',
                                                                      'ID_EPISODE_ORIGIN',
                                                                      'ID_EPISODE_DESTINATION',
                                                                      'ID_PATIENT'));
    
        -- ICNP_EPIS_INTERVENTION_HIST
        l_rowids := table_varchar();
    
        g_error := 'Call icnp_epis_intervention_hist.upd id_patient';
        ts_icnp_epis_intervention_hist.upd(id_patient_in              => i_patient,
                                           id_episode_destination_nin => FALSE,
                                           where_in                   => 'id_patient = ' || i_patient_temp,
                                           rows_out                   => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update table ICNP_EPIS_INTERVENTION_HIST';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'ICNP_EPIS_INTERVENTION_HIST',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE',
                                                                      'ID_EPISODE_ORIGIN',
                                                                      'ID_EPISODE_DESTINATION',
                                                                      'ID_PATIENT'));
    
        -- ICNP_SUGGEST_INTERV
        l_rowids := table_varchar();
    
        g_error := 'Call ts_icnp_suggest_interv.upd i_patient';
        ts_icnp_suggest_interv.upd(id_patient_in  => i_patient,
                                   id_patient_nin => FALSE,
                                   where_in       => 'id_patient = ' || i_patient_temp,
                                   rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update table ICNP_SUGGEST_INTERV';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'ICNP_SUGGEST_INTERV',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE', 'ID_PATIENT'));
    
        -- ICNP_SUGGEST_INTERV_HIST
        l_rowids := table_varchar();
    
        g_error := 'Call ts_ICNP_SUGGEST_INTERV_HIST.upd id_episode';
        ts_icnp_suggest_interv_hist.upd(id_patient_in  => i_patient,
                                        id_patient_nin => FALSE,
                                        where_in       => 'id_patient = ' || i_patient_temp,
                                        rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update table ICNP_SUGGEST_INTERV_HIST';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'ICNP_SUGGEST_INTERV_HIST',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE', 'ID_PATIENT'));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MATCH',
                                              'SET_MATCH_ICNP_PAT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_match_icnp_pat;

    FUNCTION set_match_rehab
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode_temp IN episode.id_episode%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_patient      IN patient.id_patient%TYPE,
        i_patient_temp IN patient.id_patient%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rowids         table_varchar;
        rehab_plan_row   rehab_plan%ROWTYPE;
        rehab_plan_row_t rehab_plan%ROWTYPE;
    
        CURSOR c_rehab_plan_temp(x_epis episode.id_episode%TYPE) IS
            SELECT *
              FROM rehab_plan
             WHERE id_episode_origin = x_epis;
    
        CURSOR c_rehab_plan(x_epis episode.id_episode%TYPE) IS
            SELECT *
              FROM rehab_plan
             WHERE id_episode_origin = x_epis;
    
    BEGIN
    
        -- REHAB_DIAGNOSIS
        l_rowids := table_varchar();
    
        g_error := 'Call ts_rehab_diagnosis.upd id_episode';
        ts_rehab_diagnosis.upd(id_episode_in  => i_episode,
                               id_episode_nin => FALSE,
                               where_in       => 'id_episode = ' || i_episode_temp,
                               rows_out       => l_rowids);
    
        g_error := 'Call ts_rehab_diagnosis.upd id_episode_origin';
        ts_rehab_diagnosis.upd(id_episode_origin_in  => i_episode,
                               id_episode_origin_nin => FALSE,
                               where_in              => 'id_episode_origin = ' || i_episode_temp,
                               rows_out              => l_rowids);
    
        g_error := 'Call ts_rehab_diagnosis.upd id_patient';
        ts_rehab_diagnosis.upd(id_patient_in  => i_patient,
                               id_patient_nin => FALSE,
                               where_in       => 'id_patient = ' || i_patient_temp,
                               rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update table REHAB_DIAGNOSIS';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'REHAB_DIAGNOSIS',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE', 'ID_EPISODE_ORIGIN', 'ID_PATIENT'));
    
        -- REHAB_DIAGNOSIS_HIST
        l_rowids := table_varchar();
    
        g_error := 'Call ts_rehab_diagnosis_hist.upd id_episode_origin';
        ts_rehab_diagnosis_hist.upd(id_episode_origin_in  => i_episode,
                                    id_episode_origin_nin => FALSE,
                                    where_in              => 'id_episode_origin = ' || i_episode_temp,
                                    rows_out              => l_rowids);
    
        g_error := 'Call ts_rehab_diagnosis_hist.upd id_episode';
        ts_rehab_diagnosis_hist.upd(id_episode_in  => i_episode,
                                    id_episode_nin => FALSE,
                                    where_in       => 'id_episode = ' || i_episode_temp,
                                    rows_out       => l_rowids);
    
        g_error := 'Call ts_rehab_diagnosis_hist.upd id_patient';
        ts_rehab_diagnosis_hist.upd(id_patient_in  => i_patient,
                                    id_patient_nin => FALSE,
                                    where_in       => 'id_patient = ' || i_patient_temp,
                                    rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update table REHAB_DIAGNOSIS_HIST';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'REHAB_DIAGNOSIS_HIST',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE', 'ID_EPISODE_ORIGIN', 'ID_PATIENT'));
    
        -- REHAB_EPIS_PLAN
        l_rowids := table_varchar();
    
        g_error := 'Call ts_rehab_epis_plan.upd i_episode';
        ts_rehab_epis_plan.upd(id_episode_in  => i_episode,
                               id_episode_nin => FALSE,
                               where_in       => 'id_episode = ' || i_episode_temp,
                               rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update table REHAB_EPIS_PLAN';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'REHAB_EPIS_PLAN',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
    
        -- REHAB_EPIS_PLAN_HIST
        l_rowids := table_varchar();
    
        g_error := 'Call ts_rehab_epis_plan_hist.upd i_episode';
        ts_rehab_epis_plan_hist.upd(id_episode_in  => i_episode,
                                    id_episode_nin => FALSE,
                                    where_in       => 'id_episode = ' || i_episode_temp,
                                    rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update table REHAB_EPIS_PLAN_HIST';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'REHAB_EPIS_PLAN_HIST',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
    
        -- REHAB_PLAN
        l_rowids := table_varchar();
    
        g_error := 'OPEN c_rehab_plan_temp for id_episode_origin=' || i_episode_temp;
        OPEN c_rehab_plan_temp(i_episode_temp);
        g_error := 'FETCH c_rehab_plan_temp';
        FETCH c_rehab_plan_temp
            INTO rehab_plan_row_t;
    
        g_error := 'OPEN c_rehab_plan for id_episode_origin=' || i_episode;
        OPEN c_rehab_plan(i_episode);
        g_error := 'FETCH c_rehab_plan';
        FETCH c_rehab_plan
            INTO rehab_plan_row;
    
        IF c_rehab_plan_temp%FOUND
        THEN
            IF NOT c_rehab_plan%FOUND
            THEN
                g_error                            := 't.id_episode_origin := i_episode';
                rehab_plan_row_t.id_episode_origin := i_episode;
            
                g_error := 'Call ts_rehab_plan.ins rehab_plan_row_t';
                ts_rehab_plan.ins(rec_in => rehab_plan_row_t, rows_out => l_rowids);
            
                g_error := 'Call t_data_gov_mnt.process_insert table REHAB_PLAN';
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'REHAB_PLAN',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            END IF;
        END IF;
    
        -- REHAB_NOTES
        l_rowids := table_varchar();
    
        g_error := 'Call ts_rehab_notes.upd i_episode';
        ts_rehab_notes.upd(id_episode_in  => i_episode,
                           id_episode_nin => FALSE,
                           where_in       => 'id_episode = ' || i_episode_temp,
                           rows_out       => l_rowids);
    
        g_error := 'Call ts_rehab_notes.upd id_episode_origin';
        ts_rehab_notes.upd(id_episode_origin_in  => i_episode,
                           id_episode_origin_nin => FALSE,
                           where_in              => 'id_episode_origin = ' || i_episode_temp,
                           rows_out              => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update table REHAB_NOTES';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'REHAB_NOTES',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE', 'ID_EPISODE_ORIGIN'));
    
        -- REHAB_SCH_NEED
        l_rowids := table_varchar();
    
        g_error := 'Call ts_rehab_notes.upd id_episode_origin';
        ts_rehab_sch_need.upd(id_episode_origin_in  => i_episode,
                              id_episode_origin_nin => FALSE,
                              where_in              => 'id_episode_origin = ' || i_episode_temp,
                              rows_out              => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update table REHAB_SCH_NEED';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'REHAB_SCH_NEED',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE_ORIGIN'));
    
        -- REHAB_SESSION
        l_rowids := table_varchar();
    
        g_error := 'Call ts_rehab_session.upd i_episode';
        ts_rehab_session.upd(id_episode_in  => i_episode,
                             id_episode_nin => FALSE,
                             where_in       => 'id_episode = ' || i_episode_temp,
                             rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update table REHAB_SESSION';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'REHAB_SESSION',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
    
        -- REHAB_SESSION_HIST
        l_rowids := table_varchar();
    
        g_error := 'Call ts_rehab_session_hist.upd i_episode';
        ts_rehab_session_hist.upd(id_episode_in  => i_episode,
                                  id_episode_nin => FALSE,
                                  where_in       => 'id_episode = ' || i_episode_temp,
                                  rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update table REHAB_SESSION_HIST';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'REHAB_SESSION_HIST',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
    
        -- REHAB_EPIS_ENCOUNTER
        l_rowids := table_varchar();
    
        g_error := 'Call ts_rehab_epis_encounter.upd id_episode_origin';
        ts_rehab_epis_encounter.upd(id_episode_origin_in  => i_episode,
                                    id_episode_origin_nin => FALSE,
                                    where_in              => 'id_episode_origin = ' || i_episode_temp,
                                    rows_out              => l_rowids);
    
        g_error := 'Call ts_rehab_epis_encounter.upd id_episode_rehab';
        ts_rehab_epis_encounter.upd(id_episode_rehab_in  => i_episode,
                                    id_episode_rehab_nin => FALSE,
                                    where_in             => 'id_episode_rehab = ' || i_episode_temp,
                                    rows_out             => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update table REHAB_EPIS_ENCOUNTER';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'REHAB_EPIS_ENCOUNTER',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE_ORIGIN', 'ID_EPISODE_REHAB'));
    
        -- EHAB_EPIS_ENC_HIST
        l_rowids := table_varchar();
    
        g_error := 'Call ts_rehab_epis_enc_hist.upd id_episode_origin';
        ts_rehab_epis_enc_hist.upd(id_episode_origin_in  => i_episode,
                                   id_episode_origin_nin => FALSE,
                                   where_in              => 'id_episode_origin = ' || i_episode_temp,
                                   rows_out              => l_rowids);
    
        g_error := 'Call ts_rehab_epis_enc_hist.upd id_episode_rehab';
        ts_rehab_epis_enc_hist.upd(id_episode_rehab_in  => i_episode,
                                   id_episode_rehab_nin => FALSE,
                                   where_in             => 'id_episode_origin = ' || i_episode_temp,
                                   rows_out             => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update table REHAB_EPIS_ENC_HIST';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EHAB_EPIS_ENC_HIST',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE_ORIGIN', 'ID_EPISODE_REHAB'));
    
        --DELETE  REHAB_PLAN
    
        l_rowids := table_varchar();
    
        g_error := 'Call ts_rehab_plan.ins rehab_plan_row_t';
        ts_rehab_plan.del(id_episode_origin_in => i_episode_temp, rows_out => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_delete table REHAB_PLAN';
        t_data_gov_mnt.process_delete(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'REHAB_PLAN',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        CLOSE c_rehab_plan;
    
        l_rowids := table_varchar();
    
        g_error := 'Call ts_rehab_plan.upd id_patient_in';
        ts_rehab_plan.upd(id_patient_in  => i_patient,
                          id_patient_nin => FALSE,
                          where_in       => 'id_patient = ' || i_patient_temp,
                          rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update table REHAB_PLAN';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'REHAB_PLAN',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MATCH',
                                              'SET_MATCH_REHAB',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_match_rehab;

    /**
    * This function marges all the information of the two patients into i_patient.
    * It ONLY updates tables that reference PATIENT.ID_PATIENT
    *
    * @param i_lang language id
    * @param i_prof user's object
    * @param i_patient new patient id
    * @param i_patient_temp temporary patient which data will be merged out, and then deleted
    * @param o_error error message, if error occurs
    *
    * @return true on success, false on error
    */
    FUNCTION set_match_all_pat_internal
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_patient_temp IN patient.id_patient%TYPE,
        i_flg_unknown  IN epis_info.flg_unknown%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -- denormalization variables
        l_rowids     table_varchar;
        rows_vsr_out table_varchar;
    
        e_process_event EXCEPTION;
    
        l_rowids_php      table_varchar := table_varchar();
        l_dt_health_plan  table_date;
        l_id_patient      table_number;
        l_id_health_plan  table_number;
        l_num_health_plan table_varchar;
        l_flg_status      table_varchar;
        l_barcode         table_varchar;
        l_flg_default     table_varchar;
        l_id_institution  table_number;
        l_id_episode      table_number;
        l_id_php          table_number;
        l_rows            table_varchar := table_varchar();
    
        l_p1_match       ts_p1_match.p1_match_tc;
        l_id_clin_record clin_record.id_clin_record%TYPE;
    
        l_id_seq NUMBER(24);
    
        TYPE t_php IS TABLE OF pat_health_plan%ROWTYPE INDEX BY BINARY_INTEGER;
        l_php t_php;
    
        CURSOR c_health_plan IS
            SELECT dt_health_plan,
                   i_patient id_patient,
                   id_health_plan,
                   num_health_plan,
                   flg_status,
                   barcode,
                   flg_default,
                   id_institution,
                   id_episode,
                   php1.id_pat_health_plan
              FROM pat_health_plan php1
             WHERE id_patient = i_patient_temp
               AND NOT EXISTS (SELECT 0
                      FROM pat_health_plan php2
                     WHERE php2.id_health_plan = php1.id_health_plan
                          -- José Brito 06/11/2008 ALERT-8280 Acrescentados NVL para prevêr casos onde ID_INSTITUTION é nulo
                       AND nvl(php2.id_institution, 0) = nvl(php1.id_institution, 0)
                       AND php2.id_patient = i_patient);
    
        --START ADT-680 Match for new ADT tables 27-Apr-2009
        v_pat_id NUMBER;
        --END ADT-680 Match for new ADT tables
    
        -- all institutions of i_patient on pat_ext_sys
        l_pes_insts table_number;
    
        --variables for merge of pat_soc_attribtues
        l_id_pat_soc_attributes      table_number := table_number();
        l_id_pat_soc_attributes_temp table_number := table_number();
        l_adt_insts                  table_number := table_number();
        l_temp_psa                   pat_soc_attributes%ROWTYPE;
    
    BEGIN
        IF i_patient = i_patient_temp
        THEN
            RETURN TRUE;
        ELSIF nvl(i_patient, i_patient_temp) IS NULL
        THEN
            g_error := 'INVALID INPUT';
            RAISE g_exception;
        END IF;
    
        --ALERT-214426 - This code was moved to the begin of the function in order to try to prevent the error
        --and to be able to monitorize it
        g_error  := 'UPDATE EPISODE i_patient: ' || i_patient;
        l_rowids := table_varchar();
        ts_episode.upd(id_patient_in  => i_patient,
                       id_patient_nin => FALSE,
                       where_in       => 'id_patient = ' || i_patient_temp,
                       rows_out       => l_rowids);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EPISODE',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        /*
        Please, keep this alphabetically ordered
        */
        g_error := 'UPDATE ANALYSIS_REQ i_patient: ' || i_patient;
        /* <DENORM Fábio> */
        l_rowids := table_varchar();
        ts_analysis_req.upd(id_patient_in  => i_patient,
                            id_patient_nin => FALSE,
                            where_in       => 'id_patient = ' || i_patient_temp,
                            rows_out       => l_rowids);
    
        t_data_gov_mnt.process_update(i_lang, i_prof, 'ANALYSIS_REQ', l_rowids, o_error, table_varchar('ID_PATIENT'));
    
        g_error := 'UPDATE ANALYSIS_REQ_HIST i_patient: ' || i_patient;
        UPDATE analysis_req_hist
           SET id_patient = i_patient
         WHERE id_patient = i_patient_temp;
    
        g_error := 'UPDATE ANALYSIS_RESULT i_patient: ' || i_patient;
        /* <DENORM Fábio> */
        l_rowids := table_varchar();
        ts_analysis_result.upd(id_patient_in  => i_patient,
                               id_patient_nin => FALSE,
                               where_in       => 'id_patient = ' || i_patient_temp,
                               rows_out       => l_rowids);
    
        t_data_gov_mnt.process_update(i_lang,
                                      i_prof,
                                      'ANALYSIS_RESULT',
                                      l_rowids,
                                      o_error,
                                      table_varchar('ID_PATIENT'));
    
        g_error  := 'UPDATE ANALYSIS_RESULT_HIST i_patient: ' || i_patient;
        l_rowids := table_varchar();
        ts_analysis_result_hist.upd(id_patient_in  => i_patient,
                                    id_patient_nin => FALSE,
                                    where_in       => 'id_patient = ' || i_patient_temp,
                                    rows_out       => l_rowids);
    
        t_data_gov_mnt.process_update(i_lang,
                                      i_prof,
                                      'ANALYSIS_RESULT_HIST',
                                      l_rowids,
                                      o_error,
                                      table_varchar('ID_PATIENT'));
    
        -- José Brito 12/11/2008 ALERT-8280
        g_error := 'LOOP CLIN_RECORD';
        /*MERGE INTO clin_record c
        USING (SELECT cr.id_clin_record,
                      cr.flg_status,
                      cr.id_institution,
                      cr.id_pat_family,
                      cr.num_clin_record,
                      cr.id_instit_enroled
                 FROM clin_record cr
                WHERE id_patient = i_patient_temp) t
        ON (c.id_patient = i_patient AND c.id_institution = t.id_institution)
        WHEN MATCHED THEN
            UPDATE
               SET c.flg_status        = nvl2(c.num_clin_record, c.flg_status, t.flg_status),
                   c.id_pat_family     = nvl2(c.num_clin_record, c.id_pat_family, t.id_pat_family),
                   c.num_clin_record   = nvl(c.num_clin_record, t.num_clin_record),
                   c.id_instit_enroled = nvl2(c.num_clin_record, c.id_instit_enroled, t.id_instit_enroled)
        WHEN NOT MATCHED THEN
            INSERT
                (id_clin_record,
                 flg_status,
                 id_patient,
                 id_institution,
                 id_pat_family,
                 num_clin_record,
                 id_instit_enroled)
            VALUES
                (seq_clin_record.nextval,
                 t.flg_status,
                 i_patient,
                 t.id_institution,
                 t.id_pat_family,
                 t.num_clin_record,
                 t.id_instit_enroled);*/
    
        --ADT-5921
        --Merge cannot be used because there is no unique constraint id_patient, id_inst
        --Update clinical processes that exists to definitive patient with the same id_inst
        FOR i IN (SELECT ctemp.flg_status,
                         ctemp.id_pat_family,
                         ctemp.num_clin_record,
                         ctemp.id_instit_enroled,
                         ctemp.id_institution
                    FROM clin_record ctemp
                   WHERE ctemp.id_patient = i_patient_temp)
        LOOP
            g_error := 'UPDATE CLIN_RECORD';
            UPDATE clin_record c
               SET c.flg_status        = nvl2(c.num_clin_record, c.flg_status, i.flg_status),
                   c.id_pat_family     = nvl2(c.num_clin_record, c.id_pat_family, i.id_pat_family),
                   c.num_clin_record   = nvl(c.num_clin_record, i.num_clin_record),
                   c.id_instit_enroled = nvl2(c.num_clin_record, c.id_instit_enroled, i.id_instit_enroled)
             WHERE c.id_patient = i_patient
               AND c.id_institution = i.id_institution;
        
        END LOOP;
    
        --create clinical processes that exists in temporary patient
        --but do not exists for definitive patient in those id_institutions
        g_error := 'INSERT CLIN_RECORD';
        INSERT INTO clin_record
            (id_clin_record, flg_status, id_patient, id_institution, id_pat_family, num_clin_record, id_instit_enroled)
            SELECT seq_clin_record.nextval,
                   c1.flg_status,
                   i_patient,
                   c1.id_institution,
                   c1.id_pat_family,
                   c1.num_clin_record,
                   c1.id_instit_enroled
              FROM clin_record c1
             WHERE c1.id_patient = i_patient_temp
               AND NOT EXISTS (SELECT 1
                      FROM clin_record c2
                     WHERE c2.id_patient = i_patient
                       AND c2.id_institution = c1.id_institution);
    
        g_error := 'P1_MATCH BULK_COLLECT';
        SELECT p.*
          BULK COLLECT
          INTO l_p1_match
          FROM p1_match p
         WHERE EXISTS (SELECT 0
                  FROM clin_record c
                 WHERE c.id_clin_record = p.id_clin_record
                   AND c.id_patient = i_patient_temp)
           FOR UPDATE;
    
        l_rowids := table_varchar();
    
        IF l_p1_match.exists(1)
        THEN
        
            g_error := 'P1_MATCH LOOP';
            FOR i IN l_p1_match.first .. l_p1_match.last
            LOOP
                BEGIN
                    g_error := 'GET ID_CLIN_RECORD (' || i || ')';
                    SELECT d.id_clin_record
                      INTO l_id_clin_record
                      FROM clin_record c, clin_record d
                     WHERE c.id_clin_record = l_p1_match(i).id_clin_record
                       AND c.id_patient = i_patient_temp
                       AND d.id_institution = c.id_institution
                       AND d.id_patient = i_patient
                       FOR UPDATE;
                
                    g_error := 'UPDATE P1_MATCH (' || i || ')';
                    ts_p1_match.upd(id_patient_in     => i_patient,
                                    id_clin_record_in => l_id_clin_record,
                                    where_in          => 'ID_CLIN_RECORD = ' || l_p1_match(i).id_clin_record ||
                                                         ' AND ID_PATIENT = ' || i_patient_temp,
                                    rows_out          => l_rowids);
                EXCEPTION
                    WHEN no_data_found THEN
                        g_found := FALSE;
                END;
            END LOOP;
        
            g_error := 'Error: call process_update P1_MATCH';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'P1_MATCH',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
        END IF;
        -- END ALERT-8280
    
        --START ADT-680 Match for new ADT tables 27-Apr-2009
        BEGIN
            --Obtain most recent pat_identifier from the professional institution or institution = 0
            g_error := 'get PAT_IDENTIFIER';
            SELECT id_pat_identifier
              INTO v_pat_id
              FROM (SELECT id_pat_identifier
                      FROM pat_identifier
                     WHERE id_patient = i_patient
                       AND (id_institution = i_prof.institution OR id_institution = 0)
                     ORDER BY create_time DESC NULLS LAST)
             WHERE rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                --Obtain most recent pat_identifier from any institution
                g_error := 'get PAT_IDENTIFIER NO_DATA_FOUND';
                SELECT id_pat_identifier
                  INTO v_pat_id
                  FROM (SELECT id_pat_identifier
                          FROM pat_identifier
                         WHERE id_patient = i_patient
                         ORDER BY create_time DESC NULLS LAST)
                 WHERE rownum = 1;
        END;
    
        --put all adt visits referring temporary patient instead
        g_error := ' UPDATE visit_adt';
        UPDATE visit_adt
           SET id_pat_identifier = v_pat_id
         WHERE id_pat_identifier IN (SELECT id_pat_identifier
                                       FROM pat_identifier
                                      WHERE id_patient = i_patient_temp);
    
        g_error := ' UPDATE admission_adt';
        UPDATE admission_adt
           SET id_pat_health_plan =
               (SELECT id_pat_health_plan
                  FROM pat_health_plan
                 WHERE id_patient = i_patient
                   AND rownum = 1)
         WHERE id_pat_health_plan IN (SELECT id_pat_health_plan
                                        FROM pat_health_plan
                                       WHERE id_patient = i_patient_temp);
    
        --due to the dependency from clin_record and legacy issues, we have to delete the records from pat_identifier
        g_error := ' DELETE pat_identifier';
        DELETE FROM pat_identifier
         WHERE id_patient = i_patient_temp;
    
        --END ADT-680 Match for new ADT tables
    
        g_error := 'DELETE CLIN_RECORD';
        DELETE FROM clin_record
         WHERE id_patient = i_patient_temp;
    
        -- MATCH COMPLETE HISTORY
        g_error := 'COMPLETE_HISTORY: CALL PK_HISTORY.SET_MATCH_COMPLETE_HISTORY';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_history.set_match_complete_history(i_lang           => i_lang,
                                                     i_prof           => i_prof,
                                                     i_id_episode_new => NULL,
                                                     i_id_episode_old => NULL,
                                                     i_id_patient_new => i_patient,
                                                     i_id_patient_old => i_patient_temp,
                                                     o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- MATCH scales_scores
        g_error := 'COMPLETE_HISTORY: CALL PK_HISTORY.SET_MATCH_COMPLETE_HISTORY';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_scales_core.set_match_scales_pat(i_lang            => i_lang,
                                                   i_prof            => i_prof,
                                                   i_id_patient_temp => i_patient_temp,
                                                   i_id_patient      => i_patient,
                                                   o_error           => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CONSULT_REQ P';
        l_rows  := table_varchar();
        ts_consult_req.upd(id_patient_in => i_patient, where_in => 'id_patient=' || i_patient_temp, rows_out => l_rows);
    
        g_error := 't_data_gov_mnt.process_update ts_consult_req';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'CONSULT_REQ',
                                      i_rowids       => l_rows,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
    
        g_error := 'PAT_ADVANCE_DIRECTIVE';
        l_rows  := table_varchar();
        ts_pat_advance_directive.upd(id_patient_in => i_patient,
                                     where_in      => 'id_patient=' || i_patient_temp,
                                     rows_out      => l_rows);
    
        g_error := 'DOC_EXTERNAL P';
        --UPDATE doc_external
        --   SET id_patient = i_patient
        -- WHERE id_patient = i_patient_temp;
    
        l_rows  := table_varchar();
        g_error := 'Call ts_doc_external.upd / ID_PATIENT=' || i_patient || ', I_PATIENT_TEMP=' || i_patient_temp;
        ts_doc_external.upd(id_patient_in => i_patient,
                            where_in      => 'id_patient=' || i_patient_temp,
                            rows_out      => l_rows);
    
        g_error := 'Call t_data_gov_mnt.process_update';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'DOC_EXTERNAL',
                                      i_rowids     => l_rows,
                                      o_error      => o_error);
    
        g_error := 'EPIS_ANAMNESIS P';
        l_rows  := table_varchar();
        ts_epis_anamnesis.upd(id_patient_in => i_patient,
                              where_in      => 'id_patient = ' || i_patient_temp,
                              rows_out      => l_rows);
    
        g_error := 't_data_gov_mnt.process_update ts_epis_anamnesis';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPIS_ANAMNESIS',
                                      i_rowids       => l_rows,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
    
        g_error := 'EPIS_PROF_REC';
        UPDATE epis_prof_rec
           SET id_patient = i_patient
         WHERE id_patient = i_patient_temp;
    
        g_error := 'EPIS_PROF_REC';
        UPDATE epis_prof_rec
           SET id_patient = i_patient
         WHERE id_patient = i_patient_temp;
    
        -- José Brito 01/09/2008 Actualizar tabela EVENT_MOST_FREQ
        g_error := 'EVENT_MOST_FREQ';
        UPDATE event_most_freq
           SET id_patient = i_patient
         WHERE id_patient = i_patient_temp;
        --
        g_error := 'UPDATE CRISIS_EPIS';
        UPDATE crisis_epis
           SET id_patient = i_patient
         WHERE id_patient = i_patient_temp;
        --
    
        g_error  := 'MONITORIZATION';
        l_rowids := table_varchar();
        ts_monitorization.upd(id_patient_in  => i_patient,
                              id_patient_nin => FALSE,
                              where_in       => 'id_patient = ' || i_patient_temp,
                              rows_out       => l_rowids);
    
        g_error := 'CALL PROCESS_UPDATE';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'MONITORIZATION',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        DELETE FROM monitorizations_ea a
         WHERE a.id_patient = i_patient_temp;
    
        g_error  := 'EXAM_RESULT';
        l_rowids := table_varchar();
        ts_exam_result.upd(id_patient_in  => i_patient,
                           id_patient_nin => FALSE,
                           where_in       => 'id_patient = ' || i_patient_temp,
                           rows_out       => l_rowids);
    
        g_error := 'CALL PROCESS_UPDATE';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EXAM_RESULT',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        g_error  := 'EXAM_RESULT_HIST';
        l_rowids := table_varchar();
        ts_exam_result_hist.upd(id_patient_in  => i_patient,
                                id_patient_nin => FALSE,
                                where_in       => 'id_patient = ' || i_patient_temp,
                                rows_out       => l_rowids);
    
        g_error := 'CALL PROCESS_UPDATE';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EXAM_RESULT_HIST',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        g_error := 'GRID_TASK_LAB';
        UPDATE grid_task_lab
           SET id_patient = i_patient
         WHERE id_patient = i_patient_temp;
    
        g_error := 'GRID_TASK_IMG';
        UPDATE grid_task_img
           SET id_patient = i_patient
         WHERE id_patient = i_patient_temp;
    
        g_error := 'GRID_TASK_OTH_EXM';
        UPDATE grid_task_oth_exm
           SET id_patient = i_patient
         WHERE id_patient = i_patient_temp;
    
        g_error := 'GUIDELINE_PROCESS';
        UPDATE guideline_process
           SET id_patient = i_patient
         WHERE id_patient = i_patient_temp;
    
        -- cancel duplicated guideline processes
        -- that result from the merge/match process
        g_error := ' LOOP GUIDELINE_PROCESS';
        FOR rec IN (SELECT MIN(id_guideline_process) AS id_guideline_process
                      FROM guideline_process gp
                     WHERE gp.id_patient = i_patient
                       AND gp.flg_status = pk_guidelines.g_process_recommended
                       AND NOT EXISTS (SELECT 1
                              FROM guideline_process_task gpt
                             WHERE gpt.flg_status_last != pk_guidelines.g_process_recommended
                               AND gpt.id_guideline_process = gp.id_guideline_process)
                     GROUP BY id_guideline
                    HAVING COUNT(id_guideline_process) > 1)
        LOOP
            -- cancel duplicated guideline processes
            g_error := ' UPDATE GUIDELINE_PROCESS';
            UPDATE guideline_process gp
               SET gp.flg_status = pk_guidelines.g_process_canceled
             WHERE gp.id_guideline_process = rec.id_guideline_process;
        
            -- cancel all its guideline process tasks
            g_error := ' UPDATE guideline_process_task';
            UPDATE guideline_process_task gpt
               SET gpt.flg_status_last = pk_guidelines.g_process_canceled
             WHERE gpt.id_guideline_process = rec.id_guideline_process;
        END LOOP;
    
        g_error := 'UPDATE COMM_ORDER_REQ';
        l_rows  := table_varchar();
        ts_comm_order_req.upd(id_patient_in => i_patient,
                              where_in      => 'id_patient = ' || i_patient_temp,
                              rows_out      => l_rows);
    
        g_error := 't_data_gov_mnt.process_update comm_order_req';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'COMM_ORDER_REQ',
                                      i_rowids       => l_rows,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
    
        g_error := 'UPDATE COMM_ORDER_REQ_HIST';
        UPDATE comm_order_req_hist
           SET id_patient = i_patient
         WHERE id_patient = i_patient_temp;
    
        -- print list
        g_error := 'UPDATE PRINT_LIST_JOB';
        l_rows  := table_varchar();
        ts_print_list_job.upd(id_patient_in => i_patient,
                              where_in      => 'id_patient = ' || i_patient_temp,
                              rows_out      => l_rows);
    
        g_error := 't_data_gov_mnt.process_update print_list_job';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'PRINT_LIST_JOB',
                                      i_rowids       => l_rows,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
    
        g_error := 'UPDATE PRINT_LIST_JOB_HIST';
        l_rows  := table_varchar();
        ts_print_list_job_hist.upd(id_patient_in => i_patient,
                                   where_in      => 'id_patient = ' || i_patient_temp,
                                   rows_out      => l_rows);
    
        g_error := 't_data_gov_mnt.process_update print_list_job_hist';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'PRINT_LIST_JOB_HIST',
                                      i_rowids       => l_rows,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
    
        g_error := 'HARVEST';
        /* <DENORM Fábio> */
        l_rowids := table_varchar();
        ts_harvest.upd(id_patient_in  => i_patient,
                       id_patient_nin => FALSE,
                       where_in       => 'id_patient = ' || i_patient_temp,
                       rows_out       => l_rowids);
        g_error := 'process update HARVEST';
        t_data_gov_mnt.process_update(i_lang, i_prof, 'HARVEST', l_rowids, o_error, table_varchar('ID_PATIENT'));
    
        g_error := 'Call set_match_icnp i_episode_temp=NULL,i_episode= NULL, i_patient=' || i_patient ||
                   ', i_patient_temp=' || i_patient_temp;
        pk_alertlog.log_debug(g_error);
        IF NOT set_match_icnp_pat(i_lang         => i_lang,
                                  i_prof         => i_prof,
                                  i_patient      => i_patient,
                                  i_patient_temp => i_patient_temp,
                                  o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        -- Nursing Care Plan: NANDA, NIC NOC (by patient)
        g_error := 'Call pk_nnn_core.set_match_patient i_patient=' || i_patient || ', i_patient_temp=' ||
                   i_patient_temp;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_nnn_core.set_match_patient(i_lang         => i_lang,
                                             i_prof         => i_prof,
                                             i_patient_temp => i_patient_temp,
                                             i_patient      => i_patient,
                                             o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'Call pk_aih.match_patient_aih i_patient=' || i_patient || ', i_patient_temp=' || i_patient_temp;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_aih.match_patient_aih(i_lang            => i_lang,
                                        i_prof            => i_prof,
                                        i_id_patient_temp => i_patient_temp,
                                        i_id_patient      => i_patient,
                                        o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        -- <DENORM_JOSE_BRITO>
    
        g_error := 'IDENTIFICATION_NOTES P';
        UPDATE identification_notes
           SET id_patient = i_patient
         WHERE id_patient = i_patient_temp;
    
        g_error  := 'INTERV_PRESCRIPTION';
        l_rowids := table_varchar();
        ts_interv_prescription.upd(id_patient_in  => i_patient,
                                   id_patient_nin => FALSE,
                                   where_in       => 'id_patient = ' || i_patient_temp,
                                   rows_out       => l_rowids);
    
        g_error := 'process update INTERV_PRESCRIPTION';
        t_data_gov_mnt.process_update(i_lang,
                                      i_prof,
                                      'INTERV_PRESCRIPTION',
                                      l_rowids,
                                      o_error,
                                      table_varchar('ID_PATIENT'));
    
        g_error := 'ISSUE';
        UPDATE issue
           SET id_patient = i_patient
         WHERE id_patient = i_patient_temp;
    
        g_error := 'MATCH_EPIS';
        UPDATE match_epis
           SET id_patient = i_patient
         WHERE id_patient = i_patient_temp;
    
        g_error := 'ORDER_SET_PROCESS';
        UPDATE order_set_process
           SET id_patient = i_patient
         WHERE id_patient = i_patient_temp;
    
        g_error := 'PROTOCOL_PROCESS';
        UPDATE protocol_process
           SET id_patient = i_patient
         WHERE id_patient = i_patient_temp;
    
        -- cancel duplicated protocol processes
        -- that result from the merge/match process
        g_error := 'LOOP PROTOCOL_PROCESS';
        FOR rec IN (SELECT MIN(id_protocol_process) AS id_protocol_process
                      FROM protocol_process pp
                     WHERE pp.id_patient = i_patient
                       AND pp.flg_status = pk_protocol.g_process_recommended
                       AND NOT EXISTS (SELECT 1
                              FROM protocol_process_element ppe
                             WHERE ppe.flg_status != pk_protocol.g_process_recommended
                               AND ppe.id_protocol_process = pp.id_protocol_process)
                     GROUP BY id_protocol
                    HAVING COUNT(id_protocol_process) > 1)
        LOOP
            -- cancel duplicated protocol processes
            g_error := 'UPDATE PROTOCOL_PROCESS';
            UPDATE protocol_process pp
               SET pp.flg_status = pk_protocol.g_process_canceled
             WHERE pp.id_protocol_process = rec.id_protocol_process;
        
            -- cancel all its protocol process elements
            g_error := 'UPDATE PROTOCOL_PROCESS_ELEMENT';
            UPDATE protocol_process_element ppe
               SET ppe.flg_status = pk_protocol.g_process_canceled
             WHERE ppe.id_protocol_process = rec.id_protocol_process;
        END LOOP;
    
        g_error  := 'PAT_ALLERGY P';
        l_rowids := table_varchar();
        ts_pat_allergy.upd(id_patient_in => i_patient,
                           where_in      => 'id_patient = ' || i_patient_temp,
                           rows_out      => l_rowids);
        g_error := 'PROCESS UPDATE PAT_ALLERGY';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PAT_ALLERGY',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        g_error := 'PAT_ALLERGY_HIST P';
        UPDATE pat_allergy_hist
           SET id_patient = i_patient
         WHERE id_patient = i_patient_temp;
    
        g_error := 'PAT_BLOOD_GROUP PATIENT';
        UPDATE pat_blood_group
           SET id_patient = i_patient
         WHERE id_patient = i_patient_temp;
        --Actualiza o estado dos registos de Grupo sanguíneo de forma a só o último ficar activo
        g_error := 'UPDATE PAT_BLOOD_GROUP FLG_STATUS';
        UPDATE pat_blood_group p
           SET flg_status = g_inactive
         WHERE p.id_patient = i_patient
           AND p.flg_status = g_active
           AND p.dt_pat_blood_group_tstz < (SELECT MAX(p1.dt_pat_blood_group_tstz)
                                              FROM pat_blood_group p1
                                             WHERE p1.id_patient = p.id_patient
                                               AND p1.flg_status = g_active);
    
        g_error := 'PAT_CHILD_CLIN_REC';
        UPDATE pat_child_clin_rec
           SET id_patient = i_patient
         WHERE id_patient = i_patient_temp;
    
        g_error := 'PAT_CHILD_FEED_DEV';
        UPDATE pat_child_feed_dev
           SET id_patient = i_patient
         WHERE id_patient = i_patient_temp;
    
        g_error := 'PAT_CHILD_FEED_DEV_HIST';
        UPDATE pat_child_feed_dev_hist
           SET id_patient = i_patient
         WHERE id_patient = i_patient_temp;
    
        g_error := 'PAT_CLI_ATTRIBUTES';
        UPDATE pat_cli_attributes
           SET id_patient = i_patient
         WHERE id_patient = i_patient_temp;
    
        g_error := 'PAT_CNTRCEPTIV';
        UPDATE pat_cntrceptiv
           SET id_patient = i_patient
         WHERE id_patient = i_patient_temp;
    
        g_error := 'PAT_DELIVERY';
        UPDATE pat_delivery
           SET id_patient = i_patient
         WHERE id_patient = i_patient_temp;
    
        g_error := 'DELETE PAT_DMGR_HIST ';
        DELETE FROM pat_dmgr_hist
         WHERE id_patient = i_patient_temp;
    
        g_error := 'PAT_DOC';
        UPDATE pat_doc
           SET id_patient = i_patient
         WHERE id_patient = i_patient_temp;
    
        g_error := 'PAT_EXT_SYS';
        --ALERT-41096
        SELECT pes.id_institution
          BULK COLLECT
          INTO l_pes_insts
          FROM pat_ext_sys pes
         WHERE pes.id_patient = i_patient;
    
        g_error := 'DELETE PAT_EXT_SYS';
        DELETE FROM pat_ext_sys pes
         WHERE pes.id_patient = i_patient_temp
           AND pes.id_institution IN (SELECT *
                                        FROM TABLE(l_pes_insts));
    
        g_error := 'UPDATE PAT_EXT_SYS';
        UPDATE pat_ext_sys pes
           SET pes.id_patient = i_patient
         WHERE pes.id_patient = i_patient_temp;
    
        g_error := 'PAT_FAMILY_MEMBER';
        UPDATE pat_family_member
           SET id_patient = i_patient
         WHERE id_patient = i_patient_temp;
    
        g_error := 'PAT_FAM_SOC_HIST P';
        UPDATE pat_fam_soc_hist
           SET id_patient = i_patient
         WHERE id_patient = i_patient_temp;
    
        g_error := 'PAT_FAMILY_PROF';
        UPDATE pat_family_prof
           SET id_patient = i_patient
         WHERE id_patient = i_patient_temp;
    
        g_error := 'PAT_GINEC';
        UPDATE pat_ginec
           SET id_patient = i_patient
         WHERE id_patient = i_patient_temp;
    
        g_error := 'PAT_GINEC_OBSTET';
        UPDATE pat_ginec_obstet
           SET id_patient = i_patient
         WHERE id_patient = i_patient_temp;
    
        g_error := 'PAT_GRAFFAR_CRIT';
        UPDATE pat_graffar_crit
           SET id_patient = i_patient
         WHERE id_patient = i_patient_temp;
    
        g_error := 'PAT_HABIT P';
        pk_alertlog.log_debug(g_error);
        l_rowids := table_varchar();
        ts_pat_habit.upd(id_patient_in => i_patient,
                         where_in      => 'id_patient = ' || i_patient_temp,
                         rows_out      => l_rowids);
        g_error := 'PROCESS UPDATE PAT_HABIT P';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PAT_HABIT',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        --passar TODOS os planos de saúde do paciente temp para o definitivo
        --no set_match_core apenas os do episódio temporário foram passados
        g_error := ' INSERT INTO PAT_HEALTH_PLAN (2) ';
        -- desnormalização   9-10-08 Susana Silva
        -- LMAIA 30-10-2008
        -- Necessário IF para não realizar INSERT quando o SELECT anterior não retorna nada.
        g_error := 'GET c_health_plan';
        OPEN c_health_plan;
        FETCH c_health_plan BULK COLLECT
            INTO l_dt_health_plan,
                 l_id_patient,
                 l_id_health_plan,
                 l_num_health_plan,
                 l_flg_status,
                 l_barcode,
                 l_flg_default,
                 l_id_institution,
                 l_id_episode,
                 l_id_php;
        CLOSE c_health_plan;
    
        l_rowids := table_varchar();
    
        IF l_id_health_plan IS NOT NULL
           AND l_id_health_plan.count > 0
        THEN
            g_error := 'LOOP c_health_plan';
            FOR i IN 1 .. l_id_health_plan.count
            LOOP
                g_error  := 'INSERT pat_health_plan id_health_plan=' || l_id_health_plan(i);
                l_id_seq := ts_pat_health_plan.next_key;
                ts_pat_health_plan.ins(id_pat_health_plan_in => l_id_seq,
                                       dt_health_plan_in     => l_dt_health_plan(i),
                                       id_patient_in         => l_id_patient(i),
                                       id_health_plan_in     => l_id_health_plan(i),
                                       num_health_plan_in    => l_num_health_plan(i),
                                       flg_status_in         => l_flg_status(i),
                                       barcode_in            => l_barcode(i),
                                       flg_default_in        => l_flg_default(i),
                                       id_institution_in     => l_id_institution(i),
                                       id_episode_in         => l_id_episode(i),
                                       rows_out              => l_rowids_php);
            
                -- José Brito 02/01/2009 This allows to call PROCESS_INSERT just once
                l_rowids     := l_rowids MULTISET UNION l_rowids_php;
                l_rowids_php := table_varchar();
            
                UPDATE analysis_req_det a
                   SET a.id_pat_health_plan = l_id_seq
                 WHERE a.id_pat_health_plan = l_id_php(i);
            
                UPDATE exam_req_det a
                   SET a.id_pat_health_plan = l_id_seq
                 WHERE a.id_pat_health_plan = l_id_php(i);
            
                UPDATE interv_presc_det a
                   SET a.id_pat_health_plan = l_id_seq
                 WHERE a.id_pat_health_plan = l_id_php(i);
            
            END LOOP;
        END IF;
        -- fim da desnormalização 9-10-08 Susana Silva
    
        -- José Brito 02/01/2009 ALERT-10727
        -- Copy all health plans that don't exist on the CURRENT INSTITUTION.
        g_error := 'PAT_HEALTH_PLAN BULK_COLLECT';
        SELECT p.*
          BULK COLLECT
          INTO l_php
          FROM pat_health_plan p
         WHERE p.id_patient = i_patient
           AND p.id_institution <> i_prof.institution
           AND p.id_health_plan NOT IN (SELECT id_health_plan
                                          FROM pat_health_plan p2
                                         WHERE p2.id_patient = i_patient
                                           AND p2.id_institution = i_prof.institution);
        IF l_php.exists(1)
        THEN
            FOR i IN l_php.first .. l_php.last
            LOOP
                g_error := 'INSERT - PAT_HEALTH_PLAN id_health_plan' || l_php(i).id_health_plan;
                ts_pat_health_plan.ins(id_pat_health_plan_in => ts_pat_health_plan.next_key,
                                       dt_health_plan_in     => l_php(i).dt_health_plan,
                                       id_patient_in         => l_php(i).id_patient,
                                       id_health_plan_in     => l_php(i).id_health_plan,
                                       num_health_plan_in    => l_php(i).num_health_plan,
                                       flg_status_in         => l_php(i).flg_status,
                                       barcode_in            => l_php(i).barcode,
                                       flg_default_in        => 'N', -- Use 'N' for FLG_DEFAULT
                                       id_institution_in     => i_prof.institution,
                                       id_episode_in         => -1, -- Do not associate with any episode
                                       rows_out              => l_rowids_php);
            
                l_rowids     := l_rowids MULTISET UNION l_rowids_php;
                l_rowids_php := table_varchar();
            
            END LOOP;
        
            g_error := 'T_DATA_GOV_MNT.PROCESS_INSERT PAT_HEALTH_PLAN';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PAT_HEALTH_PLAN',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
            --
        
        END IF;
    
        g_error := 'UPDATE EPIS_HEALTH_PLAN (2) ';
        UPDATE epis_health_plan e
           SET id_pat_health_plan =
               (SELECT p.id_pat_health_plan
                  FROM pat_health_plan p, visit v, episode e2
                 WHERE p.id_patient = i_patient
                   AND p.id_health_plan = (SELECT p2.id_health_plan
                                             FROM pat_health_plan p2
                                            WHERE e.id_pat_health_plan = p2.id_pat_health_plan)
                   AND p.id_institution = v.id_institution
                   AND p.id_patient = v.id_patient
                   AND v.id_visit = e2.id_visit
                   AND e2.id_episode = e.id_episode)
         WHERE EXISTS (SELECT 0
                  FROM pat_health_plan p, visit v, episode e2
                 WHERE e.id_pat_health_plan = p.id_pat_health_plan
                   AND p.id_patient = i_patient_temp
                   AND p.id_institution = v.id_institution
                   AND p.id_patient = v.id_patient
                   AND v.id_visit = e2.id_visit
                   AND e2.id_episode = e.id_episode)
           AND EXISTS
         (SELECT 0
                  FROM pat_health_plan p, visit v, episode e2
                 WHERE p.id_patient = i_patient
                   AND p.id_health_plan = (SELECT p2.id_health_plan
                                             FROM pat_health_plan p2
                                            WHERE e.id_pat_health_plan = p2.id_pat_health_plan)
                   AND p.id_institution = v.id_institution
                   AND p.id_patient = v.id_patient
                   AND v.id_visit = e2.id_visit
                   AND e2.id_episode = e.id_episode);
    
        g_error := 'DELETE EPIS_HEALTH_PLAN';
        DELETE FROM epis_health_plan eh
         WHERE eh.id_pat_health_plan IN (SELECT php.id_pat_health_plan
                                           FROM pat_health_plan php
                                          WHERE php.id_patient = i_patient_temp);
    
        g_error := 'DELETE PAT_HEALTH_PLAN (2) ';
        DELETE FROM pat_health_plan php
         WHERE php.id_patient = i_patient_temp;
    
        g_error := 'PAT_HISTORY';
        UPDATE pat_history
           SET id_patient = i_patient
         WHERE id_patient = i_patient_temp;
    
        g_error := 'PAT_JOB';
        UPDATE pat_job
           SET id_patient = i_patient
         WHERE id_patient = i_patient_temp;
    
        g_error := 'PAT_MED_DECL';
        UPDATE pat_med_decl
           SET id_patient = i_patient
         WHERE id_patient = i_patient_temp;
    
        g_error := 'CALL PK_API_PFH_CLINDOC_IN.MATCH_EPISODE';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_api_pfh_clindoc_in.match_episode(i_lang           => i_lang,
                                                   i_prof           => i_prof,
                                                   i_old_id_patient => nvl(i_patient_temp, i_patient),
                                                   i_new_id_patient => i_patient,
                                                   i_old_id_episode => NULL,
                                                   i_new_id_episode => NULL,
                                                   o_error          => o_error)
        THEN
            g_error := 'ERROR ON CALL PK_API_PFH_CLINDOC_IN.MATCH_EPISODE';
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        END IF;
    
        g_error := 'PAT_NECESSITY';
        UPDATE pat_necessity
           SET id_patient = i_patient
         WHERE id_patient = i_patient_temp;
    
        g_error := 'PAT_NECESSITY_HIST';
        UPDATE pat_necessity_hist
           SET id_patient = i_patient
         WHERE id_patient = i_patient_temp;
    
        g_error := 'PAT_NOTES P';
        UPDATE pat_notes
           SET id_patient = i_patient
         WHERE id_patient = i_patient_temp;
    
        g_error := 'PAT_PERMISSION';
        UPDATE pat_permission
           SET id_patient = i_patient
         WHERE id_patient = i_patient_temp;
    
        g_error := 'PAT_PHOTO (1)';
        DELETE FROM pat_photo
         WHERE id_patient = i_patient
           AND EXISTS (SELECT 1
                  FROM pat_photo
                 WHERE id_patient = i_patient_temp);
    
        g_error := 'PAT_PHOTO (2)';
        UPDATE pat_photo
           SET id_patient = i_patient
         WHERE id_patient = i_patient_temp;
    
        g_error := 'CALL pk_pregnancy.set_match_pat_pregnancy';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_pregnancy.set_match_pat_pregnancy(i_lang, i_prof, i_patient, i_patient_temp, o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'PAT_PREGNANCY_RISK';
        UPDATE pat_pregnancy_risk
           SET id_patient = i_patient
         WHERE id_patient = i_patient_temp;
    
        g_error  := 'PAT_PROBLEM P';
        l_rowids := table_varchar();
        ts_pat_problem.upd(id_patient_in => i_patient,
                           where_in      => 'id_patient = ' || i_patient_temp,
                           rows_out      => l_rowids);
        g_error := 'PROCESS UPDATE PAT_PROBLEM P';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PAT_PROBLEM',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        g_error := 'PAT_PROBLEM_HIST P';
        UPDATE pat_problem_hist
           SET id_patient = i_patient
         WHERE id_patient = i_patient_temp;
    
        g_error := 'PAT_VACC_ADM';
        UPDATE pat_vacc_adm
           SET id_patient = i_patient
         WHERE id_patient = i_patient_temp;
    
        g_error := 'PAT_VACC';
        UPDATE pat_vacc
           SET id_patient = i_patient
         WHERE id_patient = i_patient_temp;
    
        g_error := 'PAT_SICK_LEAVE';
        UPDATE pat_sick_leave
           SET id_patient = i_patient
         WHERE id_patient = i_patient_temp;
    
        -- Leave only one record in pat_soc_attributes
        -- MERGE PAT_SOC_ATTRIBUTES
        -- get list of institution from the same ADT group
        g_error := 'PAT_SOC_ATTRIBUTES';
        SELECT a.id_institution
          BULK COLLECT
          INTO l_adt_insts
          FROM institution_group a
         WHERE a.flg_relation = 'ADT'
           AND a.id_group IN (SELECT instg.id_group
                                FROM institution_group instg
                               WHERE instg.flg_relation = 'ADT'
                                 AND instg.id_institution = i_prof.institution);
        -- DEFINITIVE patient
        -- get the latest modified or created record for definitive patient from pat_soc_attributes_hist
        SELECT id_pat_soc_attributes
          BULK COLLECT
          INTO l_id_pat_soc_attributes
          FROM (SELECT psah2.*
                  FROM pat_soc_attributes_hist psah2
                 WHERE psah2.id_patient = i_patient
                   AND psah2.id_institution IN (SELECT *
                                                  FROM TABLE(l_adt_insts))
                 ORDER BY psah2.operation_time DESC NULLS LAST)
         WHERE rownum = 1;
    
        -- if no record exist in pat_soc_attirbutes_hist (that should not happen), retrieve the last one from pat_soc_attributes
        IF l_id_pat_soc_attributes.count = 0
        THEN
            SELECT id_pat_soc_attributes
              BULK COLLECT
              INTO l_id_pat_soc_attributes
              FROM (SELECT psa2.*
                      FROM pat_soc_attributes psa2
                     WHERE psa2.id_patient = i_patient
                       AND psa2.id_institution IN (SELECT *
                                                     FROM TABLE(l_adt_insts))
                     ORDER BY psa2.id_pat_soc_attributes DESC NULLS LAST)
             WHERE rownum = 1;
        END IF;
        --TEMPORARY patient
        -- get the latest modfified or created record for temporary patient from pat_soc_attributes_hist
        SELECT id_pat_soc_attributes
          BULK COLLECT
          INTO l_id_pat_soc_attributes_temp
          FROM (SELECT psah2.*
                  FROM pat_soc_attributes_hist psah2
                 WHERE psah2.id_patient = i_patient_temp
                   AND psah2.id_institution IN (SELECT *
                                                  FROM TABLE(l_adt_insts))
                 ORDER BY psah2.operation_time DESC NULLS LAST)
         WHERE rownum = 1;
    
        -- if no record exist in pat_soc_attirbutes_hist (that should not happen), retrieve the last one from pat_soc_attributes for temporary patient
        IF l_id_pat_soc_attributes_temp.count = 0
        THEN
            SELECT id_pat_soc_attributes
              BULK COLLECT
              INTO l_id_pat_soc_attributes_temp
              FROM (SELECT psa2.*
                      FROM pat_soc_attributes psa2
                     WHERE psa2.id_patient = i_patient_temp
                       AND psa2.id_institution IN (SELECT *
                                                     FROM TABLE(l_adt_insts))
                     ORDER BY psa2.id_pat_soc_attributes DESC NULLS LAST)
             WHERE rownum = 1;
        END IF;
    
        -- if we have pat_soc_attirbute record for definitve patient and pat_soc_attribute record for temporary patient
        -- merge both to definitive patient.
        IF (l_id_pat_soc_attributes.count > 0 AND l_id_pat_soc_attributes_temp.count > 0)
        THEN
            -- execute merge of temporary to definitive - giving priority to information in definitive patient
            BEGIN
                SELECT psa.*
                  INTO l_temp_psa
                  FROM pat_soc_attributes psa
                 WHERE psa.id_pat_soc_attributes = l_id_pat_soc_attributes_temp(1);
            
                UPDATE pat_soc_attributes psa
                   SET psa.marital_status                = nvl(psa.marital_status, l_temp_psa.marital_status),
                       psa.address                       = nvl(psa.address, l_temp_psa.address),
                       psa.location                      = nvl(psa.location, l_temp_psa.location),
                       psa.district                      = nvl(psa.district, l_temp_psa.district),
                       psa.zip_code                      = nvl(psa.zip_code, l_temp_psa.zip_code),
                       psa.num_main_contact              = nvl(psa.num_main_contact, l_temp_psa.num_main_contact),
                       psa.num_contact                   = nvl(psa.num_contact, l_temp_psa.num_contact),
                       psa.flg_job_status                = nvl(psa.flg_job_status, l_temp_psa.flg_job_status),
                       psa.id_country_nation             = nvl(psa.id_country_nation, l_temp_psa.id_country_nation),
                       psa.id_country_address            = nvl(psa.id_country_address, l_temp_psa.id_country_address),
                       psa.id_scholarship                = nvl(psa.id_scholarship, l_temp_psa.id_scholarship),
                       psa.id_religion                   = nvl(psa.id_religion, l_temp_psa.id_religion),
                       psa.mother_name                   = nvl(psa.mother_name, l_temp_psa.mother_name),
                       psa.father_name                   = nvl(psa.father_name, l_temp_psa.father_name),
                       psa.id_isencao                    = nvl(psa.id_isencao, l_temp_psa.id_isencao),
                       psa.dt_isencao                    = nvl(psa.dt_isencao, l_temp_psa.dt_isencao),
                       psa.ine_location                  = nvl(psa.ine_location, l_temp_psa.ine_location),
                       psa.id_language                   = nvl(psa.id_language, l_temp_psa.id_language),
                       psa.notes                         = nvl(psa.notes, l_temp_psa.notes),
                       psa.contact_number_3              = nvl(psa.contact_number_3, l_temp_psa.contact_number_3),
                       psa.contact_number_4              = nvl(psa.contact_number_4, l_temp_psa.contact_number_4),
                       psa.birth_place                   = nvl(psa.birth_place, l_temp_psa.birth_place),
                       psa.pension                       = nvl(psa.pension, l_temp_psa.pension),
                       psa.net_wage                      = nvl(psa.net_wage, l_temp_psa.net_wage),
                       psa.unemployment_subsidy          = nvl(psa.unemployment_subsidy, l_temp_psa.unemployment_subsidy),
                       psa.id_geo_state                  = nvl(psa.id_geo_state, l_temp_psa.id_geo_state),
                       psa.num_contrib                   = nvl(psa.num_contrib, l_temp_psa.num_contrib),
                       psa.id_currency_pension           = nvl(psa.id_currency_pension, l_temp_psa.id_currency_pension),
                       psa.id_currency_net_wage          = nvl(psa.id_currency_net_wage, l_temp_psa.id_currency_net_wage),
                       psa.id_currency_unemp_sub         = nvl(psa.id_currency_unemp_sub,
                                                               l_temp_psa.id_currency_unemp_sub),
                       psa.flg_migrator                  = nvl(psa.flg_migrator, l_temp_psa.flg_migrator),
                       psa.desc_geo_state                = nvl(psa.desc_geo_state, l_temp_psa.desc_geo_state),
                       psa.id_doc_type                   = nvl(psa.id_doc_type, l_temp_psa.id_doc_type),
                       psa.national_health_number        = nvl(psa.national_health_number,
                                                               l_temp_psa.national_health_number),
                       psa.document_identifier_number    = nvl(psa.document_identifier_number,
                                                               l_temp_psa.document_identifier_number),
                       psa.doc_ident_validation_date     = nvl(psa.doc_ident_validation_date,
                                                               l_temp_psa.doc_ident_validation_date),
                       psa.doc_ident_identification_date = nvl(psa.doc_ident_identification_date,
                                                               l_temp_psa.doc_ident_identification_date),
                       psa.flg_sns_unknown_reason        = nvl(psa.flg_sns_unknown_reason,
                                                               l_temp_psa.flg_sns_unknown_reason),
                       psa.legal_guardian                = nvl(psa.legal_guardian, l_temp_psa.legal_guardian),
                       psa.flg_nhn_status                = nvl(psa.flg_nhn_status, l_temp_psa.flg_nhn_status),
                       psa.usual_occupation              = nvl(psa.usual_occupation, l_temp_psa.usual_occupation),
                       psa.flg_hajj_patient              = nvl(psa.flg_hajj_patient, l_temp_psa.flg_hajj_patient),
                       psa.flg_umrah_patient             = nvl(psa.flg_umrah_patient, l_temp_psa.flg_umrah_patient)
                 WHERE psa.id_pat_soc_attributes = l_id_pat_soc_attributes(1);
            
            EXCEPTION
                WHEN no_data_found THEN
                    NULL;
            END;
            -- if we do not have pat_soc_attirbute record for definitve patient and we have pat_soc_attribute record for temporary patient
            -- then assign the one from temporary patient to definitve patient
        ELSIF (l_id_pat_soc_attributes_temp.count > 0 AND l_id_pat_soc_attributes.count = 0)
        THEN
            -- execute update of temporary to definitive
            UPDATE pat_soc_attributes psa
               SET psa.id_patient = i_patient
             WHERE psa.id_pat_soc_attributes = l_id_pat_soc_attributes_temp(1);
            -- and also update hist table
            UPDATE pat_soc_attributes_hist psa
               SET psa.id_patient = i_patient
             WHERE psa.id_pat_soc_attributes = l_id_pat_soc_attributes_temp(1);
        END IF;
    
        -- if we do not have anything for temporary patient just leave it as it is
        -- delete all uncessesary rows for definitive and all row for temporary patient
        IF l_id_pat_soc_attributes.count > 0
        THEN
            UPDATE pat_soc_attributes_hist
               SET id_pat_soc_attributes = l_id_pat_soc_attributes(1)
             WHERE id_patient = i_patient
               AND id_pat_soc_attributes <> l_id_pat_soc_attributes(1)
               AND id_institution IN (SELECT *
                                        FROM TABLE(l_adt_insts));
            DELETE pat_soc_attributes p
             WHERE p.id_patient = i_patient
               AND p.id_pat_soc_attributes <> l_id_pat_soc_attributes(1) -- delete all that are older
               AND p.id_institution IN (SELECT *
                                          FROM TABLE(l_adt_insts)); --only from instutions that are from the group
        
        END IF;
    
        --delete all temporary patients
        IF l_id_pat_soc_attributes_temp.count > 0
        THEN
        
            IF i_flg_unknown <> 'N'
            THEN
                UPDATE pat_soc_attributes_hist psh
                   SET id_patient = i_patient, psh.id_pat_soc_attributes = l_id_pat_soc_attributes(1)
                 WHERE id_patient = i_patient_temp;
            ELSE
                UPDATE pat_soc_attributes_hist psh
                   SET id_patient = i_patient, psh.id_pat_soc_attributes = l_id_pat_soc_attributes(1)
                 WHERE id_patient = i_patient_temp
                   AND psh.id_institution IN (SELECT *
                                                FROM TABLE(l_adt_insts));
            END IF;
            DELETE pat_soc_attributes p
             WHERE p.id_patient = i_patient_temp
               AND p.id_institution IN (SELECT *
                                          FROM TABLE(l_adt_insts)); --only from instutions that are from the group
        END IF;
        --Patient Care Inst update
        BEGIN
            g_error := 'UPDATE patient_care_inst';
            UPDATE patient_care_inst
               SET id_patient = i_patient
             WHERE id_patient = i_patient_temp;
        
            g_error := 'UPDATE patient_care_inst_history';
            UPDATE patient_care_inst_history
               SET id_patient = i_patient
             WHERE id_patient = i_patient_temp;
        
        EXCEPTION
            WHEN dup_val_on_index THEN
                g_error := 'DELETE patient_care_inst';
                DELETE FROM patient_care_inst
                 WHERE id_patient = i_patient_temp;
            
                g_error := 'DELETE patient_care_inst_history';
                DELETE FROM patient_care_inst_history
                 WHERE id_patient = i_patient_temp;
        END;
    
        --START ADT-680 Match for new ADT tables 27-Apr-2009
        --updating all new ADT tables
        g_error := 'CALL  pk_adt.set_match_patient';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_adt.set_match_patient(i_lang         => i_lang,
                                        i_prof         => i_prof,
                                        i_patient      => i_patient,
                                        i_patient_temp => i_patient_temp,
                                        i_flg_unknown  => i_flg_unknown,
                                        o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
        --END ADT-680 Match for new ADT tables
    
        -- We delete the temporary patient info because we used it to do the MERGE.
        -- The definitive patient has more complete information: the info it had before
        -- the match, plus all the data from the temporary patient.
        g_error := 'DELETE  pat_soc_attributes';
        DELETE FROM pat_soc_attributes p
         WHERE p.id_patient = i_patient_temp;
        --
    
        g_error := 'PAT_VACCINE';
        UPDATE pat_vaccine
           SET id_patient = i_patient
         WHERE id_patient = i_patient_temp;
    
        g_error := 'PERIODIC_OBSERVATION_REG';
        UPDATE periodic_observation_reg
           SET id_patient = i_patient
         WHERE id_patient = i_patient_temp;
    
        g_error := 'PAT_PO_PARAM';
        UPDATE pat_po_param patpop
           SET patpop.id_patient = i_patient
         WHERE patpop.id_patient = i_patient_temp;
    
        l_rowids := table_varchar();
        g_error  := 'CALL ts_po_param_reg.upd';
        ts_po_param_reg.upd(id_patient_in  => i_patient,
                            id_patient_nin => FALSE,
                            where_in       => 'id_patient = ' || i_patient_temp,
                            rows_out       => l_rowids);
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'PO_PARAM_REG',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
    
        g_error  := 'P1_EXTERNAL_REQUEST';
        l_rowids := table_varchar();
        ts_p1_external_request.upd(id_patient_in => i_patient,
                                   where_in      => 'ID_PATIENT = ' || i_patient_temp,
                                   rows_out      => l_rowids);
    
        g_error := 'Error: call process_update P1_EXTERNAL_REQUEST';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'P1_EXTERNAL_REQUEST',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        g_error := 'SCH_GROUP';
        UPDATE sch_group
           SET id_patient = i_patient
         WHERE id_patient = i_patient_temp;
    
        g_error  := 'UPDATE SCHEDULE_SR';
        l_rowids := table_varchar();
        ts_schedule_sr.upd(id_patient_in  => i_patient,
                           id_patient_nin => FALSE,
                           where_in       => 'id_patient = ' || i_patient_temp,
                           rows_out       => l_rowids);
    
        g_error := 'PROCESS UPDATE SCHEDULE_SR';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'SCHEDULE_SR',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
    
        g_error := 'SCHOOL';
        UPDATE school
           SET id_patient = i_patient
         WHERE id_patient = i_patient_temp;
    
        g_error := 'SOCIAL_EPISODE P';
        UPDATE social_episode
           SET id_patient = i_patient
         WHERE id_patient = i_patient_temp;
    
        g_error := 'SR_SURGERY_RECORD';
        UPDATE sr_surgery_record
           SET id_patient = i_patient
         WHERE id_patient = i_patient_temp;
    
        g_error := 'SYS_ALERT_EVENT';
        UPDATE sys_alert_event
           SET id_patient = i_patient
         WHERE id_patient = i_patient_temp;
    
        g_error := 'TRANSP_REQ';
        UPDATE transp_req
           SET id_patient = i_patient
         WHERE id_patient = i_patient_temp;
    
        g_error := 'UNIDOSE_CAR_PATIENT';
        UPDATE unidose_car_patient
           SET id_patient = i_patient
         WHERE id_patient = i_patient_temp;
    
        g_error := 'VACCINE_DET';
        UPDATE vaccine_det
           SET id_patient = i_patient
         WHERE id_patient = i_patient_temp;
    
        g_error := 'VISIT';
        UPDATE visit
           SET id_patient = i_patient
         WHERE id_patient = i_patient_temp;
    
        g_error := 'PK_EA_VITAL_SIGNS.merge_vs_episode i_patient=' || i_patient || ', i_patient_temp=' ||
                   i_patient_temp;
        pk_alertlog.log_debug(g_error);
        pk_ea_vital_signs.merge_vs_patient(i_lang            => i_lang,
                                           i_prof            => i_prof,
                                           i_tmp_patient_id  => i_patient_temp,
                                           i_real_patient_id => i_patient,
                                           o_rows_out        => rows_vsr_out);
    
        /*        g_error := 'ts_vital_sign_read.upd';
        ts_vital_sign_read.upd(id_patient_in => i_patient,
                               where_in      => 'id_patient = ' || i_patient_temp,
                               rows_out      => rows_vsr_out);
        
        g_error := 'process_update vital_sign_read';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'VITAL_SIGN_READ',
                                      i_rowids     => rows_vsr_out,
                                      o_error      => o_error);*/
    
        g_error := 'WL_WAITING_LINE P';
        UPDATE wl_waiting_line
           SET id_patient = i_patient
         WHERE id_patient = i_patient_temp;
    
        g_error := 'PAT_VACC';
        UPDATE pat_vacc
           SET id_patient = i_patient
         WHERE id_patient = i_patient_temp;
    
        g_error  := 'DISCHARGE_NOTES';
        l_rowids := table_varchar();
        ts_discharge_notes.upd(id_patient_in => i_patient,
                               where_in      => 'id_patient = ' || i_patient_temp,
                               rows_out      => l_rowids);
    
        g_error := 'PROCESS_UPDATE DISCHARGE_NOTES';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'DISCHARGE_NOTES',
                                      i_list_columns => table_varchar('id_patient'),
                                      i_rowids       => l_rowids,
                                      o_error        => o_error);
    
        g_error  := 'EPIS_DIAGNOSIS';
        l_rowids := table_varchar();
        ts_epis_diagnosis.upd(id_patient_in => i_patient,
                              where_in      => 'id_patient = ' || i_patient_temp,
                              rows_out      => l_rowids);
    
        g_error := 'PROCESS_UPDATE EPIS_DIAGNOSIS';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPIS_DIAGNOSIS',
                                      i_list_columns => table_varchar('id_patient'),
                                      i_rowids       => l_rowids,
                                      o_error        => o_error);
    
        g_error  := 'EPIS_DIAGRAM';
        l_rowids := table_varchar();
        ts_epis_diagram.upd(id_patient_in => i_patient,
                            where_in      => 'id_patient = ' || i_patient_temp,
                            rows_out      => l_rowids);
    
        g_error := 'PROCESS_UPDATE EPIS_DIAGRAM';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPIS_DIAGRAM',
                                      i_list_columns => table_varchar('id_patient'),
                                      i_rowids       => l_rowids,
                                      o_error        => o_error);
    
        g_error  := 'EPIS_RECOMEND';
        l_rowids := table_varchar();
        ts_epis_recomend.upd(id_patient_in => i_patient,
                             where_in      => 'id_patient = ' || i_patient_temp,
                             rows_out      => l_rowids);
    
        g_error := 'PROCESS_UPDATE EPIS_RECOMEND';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPIS_RECOMEND',
                                      i_list_columns => table_varchar('id_patient'),
                                      i_rowids       => l_rowids,
                                      o_error        => o_error);
    
        g_error := 'Call set_match_nurse i_episode_temp=NULL, i_episode=NULL, i_patient=' || i_patient ||
                   ', i_patient_temp=' || i_patient_temp;
        pk_alertlog.log_debug(g_error);
        IF NOT set_match_nurse_pat(i_lang         => i_lang,
                                   i_prof         => i_prof,
                                   i_patient      => i_patient,
                                   i_patient_temp => i_patient_temp,
                                   o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        -- Alexandre Santos 02-04-2009 ALERT-8544
        -- LMAIA 22-05-2009 USE FRAMEWORK SYSTEM
        g_error  := 'UPDATE DISCHARGE_SCHEDULE';
        l_rowids := table_varchar();
        ts_discharge_schedule.upd(id_patient_in => i_patient,
                                  where_in      => 'id_patient = ' || i_patient_temp,
                                  rows_out      => l_rowids);
        --
        g_error := 'PROCESS_UPDATE DISCHARGE_SCHEDULE';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'DISCHARGE_SCHEDULE',
                                      i_list_columns => table_varchar('id_patient'),
                                      i_rowids       => l_rowids,
                                      o_error        => o_error);
    
        g_error  := 'UPDATE ID_PATIENT IN LENS_PRESC';
        l_rowids := table_varchar();
        ts_lens_presc.upd(id_patient_in  => i_patient,
                          id_patient_nin => TRUE,
                          where_in       => 'id_patient = ' || i_patient_temp,
                          rows_out       => l_rowids);
    
        g_error := 'PROCESS_UPDATE LENS_PRESC';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'LENS_PRESC',
                                      i_list_columns => table_varchar('id_patient'),
                                      i_rowids       => l_rowids,
                                      o_error        => o_error);
    
        g_error  := 'UPDATE ID_PATIENT IN LENS_PRESC_HIST';
        l_rowids := table_varchar();
        ts_lens_presc_hist.upd(id_patient_in  => i_patient,
                               id_patient_nin => TRUE,
                               where_in       => 'id_patient = ' || i_patient_temp,
                               rows_out       => l_rowids);
    
        g_error := 'PROCESS_UPDATE LENS_PRESC_HIST';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'LENS_PRESC_HIST',
                                      i_list_columns => table_varchar('id_patient'),
                                      i_rowids       => l_rowids,
                                      o_error        => o_error);
    
        -- DIETAS
        g_error  := 'UPDATE DIET';
        l_rowids := table_varchar();
        ts_epis_diet_req.upd(id_patient_in  => i_patient,
                             id_patient_nin => FALSE,
                             where_in       => 'id_patient = ' || i_patient_temp,
                             rows_out       => l_rowids);
    
        -- THERAPEUTIC DECISION
        g_error  := 'UPDATE THERAPEUTIC_DECISION';
        l_rowids := table_varchar();
        ts_therapeutic_decision.upd(id_patient_in  => i_patient,
                                    id_patient_nin => FALSE,
                                    where_in       => 'id_patient = ' || i_patient_temp,
                                    rows_out       => l_rowids);
    
        -- BED MANAGEMENT
        g_error  := 'ALLOCATION BED';
        l_rowids := table_varchar();
        ts_bmng_allocation_bed.upd(id_patient_in  => i_patient,
                                   id_patient_nin => FALSE,
                                   where_in       => 'id_patient = ' || i_patient_temp,
                                   rows_out       => l_rowids);
    
        g_error := 'PROCESS_UPDATE BMNG_ALLOCATION_BED';
        t_data_gov_mnt.process_update(i_lang,
                                      i_prof,
                                      'BMNG_ALLOCATION_BED',
                                      l_rowids,
                                      o_error,
                                      table_varchar('ID_PATIENT'));
    
        -- END BED MANAGEMENT
    
        g_error  := 'OPINION';
        l_rowids := table_varchar();
        ts_opinion.upd(id_patient_in  => i_patient,
                       id_patient_nin => FALSE,
                       where_in       => ' ID_PATIENT = ' || i_patient_temp,
                       rows_out       => l_rowids);
    
        g_error := 'PROCESS_UPDATE OPINION';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'OPINION',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
    
        g_error  := 'EPIS_ENCOUNTER';
        l_rowids := table_varchar();
    
        ts_epis_encounter.upd(id_patient_in  => i_patient,
                              id_patient_nin => FALSE,
                              where_in       => ' ID_PATIENT = ' || i_patient_temp,
                              rows_out       => l_rowids);
    
        g_error := 'PROCESS_UPDATE EPIS_ENCOUNTER';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPIS_ENCOUNTER',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
    
        g_error  := 'PAT_HEALTH_PROGRAM';
        l_rowids := table_varchar();
        ts_pat_health_program.upd(id_patient_in  => i_patient,
                                  id_patient_nin => FALSE,
                                  where_in       => ' ID_PATIENT = ' || i_patient_temp,
                                  rows_out       => l_rowids);
    
        g_error := 'PROCESS_UPDATE PAT_HEALTH_PROGRAM';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'PAT_HEALTH_PROGRAM',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
    
        g_error := 'PAT_HEALTH_PROGRAM_HIST';
        UPDATE pat_health_program_hist phph
           SET phph.id_patient = i_patient
         WHERE phph.id_patient = i_patient_temp;
    
        g_error  := 'PAT_ALLERGY_UNAWARENESS';
        l_rowids := table_varchar();
        ts_pat_allergy_unawareness.upd(id_patient_in => i_patient,
                                       where_in      => ' ID_PATIENT = ' || i_patient_temp,
                                       rows_out      => l_rowids);
    
        g_error := 'PROCESS_UPDATE PAT_ALLERGY_UNAWARENESS';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PAT_ALLERGY_UNAWARENESS',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        g_error := 'UPDATE pat_checklist';
        UPDATE pat_checklist pchk
           SET pchk.id_patient = i_patient
         WHERE pchk.id_patient = i_patient_temp;
    
        -- MATCH INTAKE AND OUTPUT
        g_error := 'CALL TO PK_INP_HIDRICS_PBL.SET_MATCH_PAT_HIDRICS';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_inp_hidrics_pbl.set_match_pat_hidrics(i_lang         => i_lang,
                                                        i_prof         => i_prof,
                                                        i_patient      => i_patient,
                                                        i_patient_temp => i_patient_temp,
                                                        o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL pk_organ_donor.change_donor_patient_id';
        pk_alertlog.log_info(text            => g_error,
                             object_name     => 'PK_MATCH',
                             sub_object_name => 'SET_MATCH_ALL_PAT_INTERNAL');
        IF NOT pk_organ_donor.change_donor_patient_id(i_lang        => i_lang,
                                                      i_new_patient => i_patient,
                                                      i_old_patient => i_patient_temp,
                                                      o_error       => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL pk_past_history.set_match_patient';
        pk_alertlog.log_info(text            => g_error,
                             object_name     => 'PK_MATCH',
                             sub_object_name => 'SET_MATCH_ALL_PAT_INTERNAL');
        IF NOT pk_past_history.set_match_patient(i_lang         => i_lang,
                                                 i_prof         => i_prof,
                                                 i_patient      => i_patient,
                                                 i_patient_temp => i_patient_temp,
                                                 o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- trials
        g_error := 'CALL pk_trials.set_match_pat_trial';
        pk_alertlog.log_info(text            => g_error,
                             object_name     => 'PK_MATCH',
                             sub_object_name => 'SET_MATCH_ALL_PAT_INTERNAL');
        IF NOT pk_trials.set_match_pat_trial(i_lang            => i_lang,
                                             i_prof            => i_prof,
                                             i_id_patient      => i_patient,
                                             i_id_patient_temp => i_patient_temp,
                                             o_error           => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- pharmacy
        g_error := 'CALL pk_api_pfh_in.match_patient_pharmacy';
        pk_alertlog.log_info(text            => g_error,
                             object_name     => 'PK_MATCH',
                             sub_object_name => 'SET_MATCH_ALL_PAT_INTERNAL');
        IF NOT pk_api_pfh_in.match_patient_pharmacy(i_lang         => i_lang,
                                                    i_prof         => i_prof,
                                                    i_patient_temp => i_patient_temp,
                                                    i_patient      => i_patient,
                                                    o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        --            
        g_error := 'UPDATE pat_rcm_H';
        UPDATE pat_rcm_h a
           SET a.id_patient = i_patient
         WHERE a.id_patient = i_patient_temp;
    
        g_error := 'UPDATE PAT_RCM_DET';
        UPDATE pat_rcm_det a
           SET a.id_patient = i_patient
         WHERE a.id_patient = i_patient_temp;
    
        g_error := 'CALL pk_translation.upd_translation_trs_pat';
        pk_translation.upd_translation_trs_pat(i_old_pat => i_patient_temp, i_new_pat => i_patient);
    
        /*        -- EA's
        DELETE FROM vs_patient_ea a
         WHERE a.id_patient = i_patient_temp;
        
        DELETE FROM vs_visit_ea a
         WHERE a.id_visit IN (SELECT e.id_visit
                                FROM episode e
                               WHERE e.id_patient = i_patient_temp);*/
    
        DELETE FROM monitorizations_ea a
         WHERE a.id_visit IN (SELECT e.id_visit
                                FROM episode e
                               WHERE e.id_patient = i_patient_temp);
    
        DELETE FROM monitorizations_ea a
         WHERE a.id_visit IN (SELECT e.id_visit
                                FROM episode e
                               WHERE e.id_patient = i_patient_temp);
    
        DELETE FROM task_timeline_ea a
         WHERE a.id_visit IN (SELECT e.id_visit
                                FROM episode e
                               WHERE e.id_patient = i_patient_temp);
    
        DELETE FROM task_timeline_ea a
         WHERE a.id_patient = i_patient_temp;
        --
    
        DELETE FROM pat_health_center a
         WHERE a.id_patient = i_patient_temp;
    
        g_error := 'UPDATE REMAINING TABLES';
        --antes de apagar o paciente, faz-se uma
        --query sobre o dicionáros de dados para
        --garantir que passam todos os registos
        FOR all_tbs IN (SELECT DISTINCT 'update ' || m1.table_name || ' set ' || mc1.column_name ||
                                        ' = :i_patient where ' || mc1.column_name || ' = :i_patient_temp' query
                          FROM all_constraints m1, all_cons_columns mc1, all_cons_columns rc1
                         WHERE rc1.constraint_name = m1.r_constraint_name
                           AND rc1.table_name = 'PATIENT'
                           AND m1.table_name <> 'VIEWER_EHR_EA'
                           AND m1.table_name <> 'VS_PATIENT_EA'
                              ---------------------------------------
                              -- actualizações schema medicação são feitas por API (pk_api_pfh_clindoc_in.match_episode)
                              -- caso contrário poderão dar problemas de permissão de acesso às tabelas
                              -- por isso os schemas de medicação são retirados da actualização
                           AND m1.owner != 'ALERT_PRODUCT_TR'
                           AND m1.owner != 'ALERT_PRODUCT_MT'
                           AND m1.owner != 'ALERT_PHARMACY_DATA'
                           AND m1.owner != 'ALERT_PHARMACY_FUNC'
                           AND m1.owner != 'ALERT_CODING_TR'
                              ---------------------------------------
                              --the table has select privileges to ALERT but cannot be updated
                           AND m1.table_name != 'TRANSLATION_TRS'
                           AND m1.constraint_name = mc1.constraint_name
                           AND m1.table_name = mc1.table_name)
        LOOP
            g_error := 'EXEC ' || all_tbs.query;
        
            EXECUTE IMMEDIATE all_tbs.query
                USING i_patient, i_patient_temp;
        END LOOP;
    
        --antes de apagar o patient, junta-se a informação disponível
        g_error := 'MERGE PATIENT';
        UPDATE patient p
           SET (p.name,
                p.gender,
                p.dt_birth,
                p.nick_name,
                p.flg_status,
                p.dt_deceased,
                p.adw_last_update,
                p.id_pat_family,
                p.last_name,
                p.middle_name,
                p.age) =
               (SELECT nvl(p.name, p2.name),
                       decode(p.gender, 'F', 'F', 'M', 'M', decode(p2.gender, 'F', 'F', 'M', 'M', p.gender)),
                       nvl(p.dt_birth, p2.dt_birth),
                       decode(p.name, NULL, p2.nick_name, p.nick_name),
                       decode(p.flg_status, 'A', 'A', p2.flg_status),
                       nvl(p.dt_deceased, p2.dt_deceased),
                       g_sysdate,
                       nvl(p.id_pat_family, p2.id_pat_family),
                       decode(p.name, NULL, p2.last_name, p.last_name),
                       decode(p.name, NULL, p2.middle_name, p.middle_name),
                       decode(nvl(p.dt_birth, p2.dt_birth), NULL, nvl(p.age, p2.age))
                  FROM patient p2
                 WHERE p2.id_patient = i_patient_temp)
         WHERE p.id_patient = i_patient;
    
        /* Not supported by LUCENE indexes
        ADT-3280*/
    
        /*MERGE INTO patient p
        USING (SELECT p2.id_patient,
                      p2.id_person,
                      p2.id_general_pratictioner,
                      p2.id_pat_family,
                      p2.name,
                      p2.gender,
                      p2.dt_birth,
                      p2.nick_name,
                      p2.flg_status,
                      p2.dt_deceased,
                      p2.adw_last_update,
                      p2.last_name,
                      p2.middle_name,
                      p2.age,
                      p2.flg_migration,
                      p2.total_fam_members,
                      p2.national_health_number,
                      p2.institution_key,
                      p2.create_user,
                      p2.create_time,
                      p2.update_user,
                      p2.update_time,
                      p2.patient_number,
                      p2.deceased_motive,
                      p2.deceased_place,
                      p2.birth_place
                 FROM patient p2
                WHERE p2.id_patient = i_patient_temp) p2
        ON (p.id_patient = i_patient)
        WHEN MATCHED THEN
            UPDATE
               SET p.name            = nvl(p.name, p2.name),
                   p.gender          = decode(p.gender,
                                              'F',
                                              'F',
                                              'M',
                                              'M',
                                              decode(p2.gender, 'F', 'F', 'M', 'M', p.gender)),
                   p.dt_birth        = nvl(p.dt_birth, p2.dt_birth),
                   p.nick_name       = decode(p.name, NULL, p2.nick_name, p.nick_name),
                   p.flg_status      = decode(p.flg_status, 'A', 'A', p2.flg_status),
                   p.dt_deceased     = nvl(p.dt_deceased, p2.dt_deceased),
                   p.adw_last_update = g_sysdate,
                   p.id_pat_family   = nvl(p.id_pat_family, p2.id_pat_family),
                   p.last_name       = decode(p.name, NULL, p2.last_name, p.last_name),
                   p.middle_name     = decode(p.name, NULL, p2.middle_name, p.middle_name),
                   p.age             = decode(nvl(p.dt_birth, p2.dt_birth), NULL, nvl(p.age, p2.age));*/
    
        --[ALERT-198666] Necessary from VS_PATIENT_EA table
        /*        g_error := 'DELETE VS_PATIENT_EA INFO';
        ts_vs_patient_ea.del_id_patient(id_patient_in => i_patient_temp);*/
    
        -- José Brito 29/08/2008 MatchCancelados: se o episódio cancelado fôr definitivo, não se elimina o registo na tabela PATIENT
        IF i_flg_unknown <> 'N'
        THEN
            g_error := 'DELETE VIEWER_EHR_EA ';
        
            --START ADT-680 Match for new ADT tables 27-Apr-2009
            ts_viewer_ehr_ea.del(i_patient_temp);
        
            --END ADT-680 Match for new ADT tables
            g_error := 'DELETE PATIENT ID_PATIENT:' || i_patient_temp;
            ts_patient.del_id_patient(id_patient_in => i_patient_temp, rows_out => l_rows);
            g_error := 'PROCESS DELETE PATIENT';
            t_data_gov_mnt.process_delete(i_lang, i_prof, 'PATIENT', l_rows, o_error);
        END IF;
    
        --ALERT-294355 - In some EA tables the id_patient isn't updated, it was not possible to reproduce the error.
        --               I'm adding this block of code to prevent the wrong data
        DECLARE
            l_count_track_board PLS_INTEGER;
        BEGIN
            SELECT COUNT(1)
              INTO l_count_track_board
              FROM tracking_board_ea t
             WHERE t.id_patient = i_patient_temp;
        
            IF l_count_track_board > 0
            THEN
                raise_application_error(-20001, 'TRACKING_BOARD_EA HAS RECORDS WITH ID_PATIENT_TEMP');
            END IF;
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MATCH',
                                              'SET_MATCH_ALL_PAT_INTERNAL',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            -- José Brito 10/07/2009 ALERT-34678  Match integration between ALERT clinical/non-clinical
            --pk_utils.undo_changes;
            RETURN FALSE;
    END;

    /**
    * This function marges all the information of the two patients into i_patient.
    * It ONLY updates tables that reference PATIENT.ID_PATIENT
    *
    * @param i_lang language id
    * @param i_prof user's object
    * @param i_patient new patient id
    * @param i_patient_temp temporary patient which data will be merged out, and then deleted
    * @param o_error error message, if error occurs
    *
    * @return true on success, false on error
    */
    FUNCTION set_match_all_pat
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_patient_temp IN patient.id_patient%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_match_epis match_epis.id_match_epis%TYPE;
    
    BEGIN
    
        g_error := 'CALL SET_MATCH_ALL_PAT_INTERNAL';
        IF NOT set_match_all_pat_internal(i_lang, i_prof, i_patient, i_patient_temp, pk_alert_constant.g_yes, o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        l_id_match_epis := seq_match_epis.nextval;
    
        g_error := 'INSERT MATCH_EPIS';
        INSERT INTO match_epis
            (id_match_epis, id_episode, id_episode_temp, id_patient, id_patient_temp, id_professional, dt_match_tstz)
        VALUES
            (l_id_match_epis, NULL, NULL, i_patient, i_patient_temp, i_prof.id, current_timestamp);
    
        g_error := 'CALL PK_IA_EVENT_COMMON.MERGE_PATIENT_EPISODES';
        pk_ia_event_common.merge_patient_episodes(i_id_institution => i_prof.institution,
                                                  i_id_match_epis  => l_id_match_epis);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MATCH',
                                              'SET_MATCH_ALL_PAT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            -- José Brito 10/07/2009 ALERT-34678  Match integration between ALERT clinical/non-clinical
            --pk_utils.undo_changes;
            RETURN FALSE;
    END;

    /******************************************************************************
    * This function contains all the logic required to update all the
    * dates related to the episode: begin date, first observation date and discharge date.
    *
    * @param i_lang             language id
    * @param i_prof             user's object
    * @param i_episode_temp     temporary episode which data will be merged out, and then deleted
    * @param i_episode          definitive episode id
    * @param i_visit_temp       temporary visit
    * @param i_visit            definitive visit
    * @param o_error            error message, if error occurs
    *
    * @return                  TRUE if succeeded, FALSE otherwise
    *
    * @author                  José Brito
    * @version                 0.1
    * @since                   2008-Nov-14
    *
    ******************************************************************************/
    FUNCTION set_episode_dates
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_episode_temp IN episode.id_episode%TYPE,
        i_visit        IN visit.id_visit%TYPE,
        i_visit_temp   IN visit.id_visit%TYPE,
        i_flg_unknown  IN epis_info.flg_unknown%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dt_begin_tstz   episode.dt_begin_tstz%TYPE;
        l_id_prev_episode episode.id_prev_episode%TYPE;
    
        l_dt_admin_end_tstz discharge.dt_admin_tstz%TYPE;
        l_dt_med_end_tstz   discharge.dt_med_tstz%TYPE;
    
        l_dt_first_obs_tstz epis_info.dt_first_obs_tstz%TYPE;
    
        l_count NUMBER(6);
    
        l_rowids table_varchar;
    
        l_dep_clin_serv          epis_info.id_dep_clin_serv%TYPE;
        l_clinical_service       clinical_service.id_clinical_service%TYPE;
        l_department             department.id_department%TYPE;
        l_dept                   dept.id_dept%TYPE;
        l_first_dep_clin_serv    dep_clin_serv.id_dep_clin_serv%TYPE;
        l_room                   room.id_room%TYPE;
        l_dt_first_obs_def       epis_info.dt_first_obs_tstz%TYPE;
        l_dt_first_nurse_obs_def epis_info.dt_first_nurse_obs_tstz%TYPE;
        l_dt_first_inst_obs_tstz epis_info.dt_first_inst_obs_tstz%TYPE;
        l_epis_bed               epis_info.id_bed%TYPE;
    
        l_ei epis_info%ROWTYPE;
    
        l_sys_cfg_epi_loc sys_config.id_sys_config%TYPE := 'MATCH_EPI_LOC_TEMP';
    BEGIN
    
        g_error := 'GET ID_FIRST_DEP_CLIN_SERV';
        BEGIN
            SELECT ei.id_dep_clin_serv,
                   e.id_clinical_service,
                   e.id_department,
                   e.id_dept,
                   ei.id_first_dep_clin_serv,
                   ei.id_room,
                   ei.dt_first_obs_tstz,
                   ei.dt_first_nurse_obs_tstz,
                   e.dt_begin_tstz,
                   ei.dt_first_inst_obs_tstz,
                   ei.id_bed
              INTO l_dep_clin_serv,
                   l_clinical_service,
                   l_department,
                   l_dept,
                   l_first_dep_clin_serv,
                   l_room,
                   l_dt_first_obs_def,
                   l_dt_first_nurse_obs_def,
                   l_dt_begin_tstz,
                   l_dt_first_inst_obs_tstz,
                   l_epis_bed
              FROM episode e, epis_info ei
             WHERE e.id_episode = ei.id_episode
               AND e.id_episode = i_episode;
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        g_error := 'GET ID_PREV_EPISODE';
        SELECT (SELECT e2.id_episode
                  FROM episode e2
                 WHERE e.id_prev_episode = e2.id_episode
                   AND e2.id_institution <> e.id_institution) id_prev_episode
          INTO l_id_prev_episode
          FROM episode e
         WHERE e.id_episode = i_episode_temp;
    
        g_error := 'DELETE EPIS_INFO - i_episode';
        ts_epis_info.del(id_episode_in => i_episode, rows_out => l_rowids);
    
        t_data_gov_mnt.process_delete(i_lang, i_prof, 'EPIS_INFO', l_rowids, o_error);
    
        g_error := 'UPDATE EPIS_INFO - i_episode';
        SELECT ei.id_bed,
               ei.id_room,
               ei.id_professional,
               ei.id_episode,
               ei.norton,
               ei.flg_hydric,
               ei.flg_wound,
               ei.companion,
               ei.flg_unknown,
               ei.desc_info,
               ei.id_schedule,
               ei.id_first_nurse_resp,
               ei.flg_status,
               ei.id_dep_clin_serv,
               ei.id_first_dep_clin_serv,
               ei.id_institution_usf,
               ei.id_prof_team,
               ei.id_triage,
               ei.id_triage_white_reason,
               ei.id_first_triage,
               ei.id_first_triage_wr,
               ei.dt_harvest_tstz,
               ei.dt_last_interaction_tstz,
               ei.dt_movement_tstz,
               ei.dt_next_drug_tstz,
               ei.dt_first_obs_tstz,
               ei.dt_next_intervention_tstz,
               ei.dt_next_vital_sign_tstz,
               ei.dt_next_position_tstz,
               ei.dt_entrance_room_tstz,
               ei.dt_harvest_mov_tstz,
               ei.dt_first_nurse_obs_tstz,
               ei.dt_first_analysis_exe_tstz,
               ei.dt_first_analysis_req_tstz,
               ei.dt_first_image_exec_tstz,
               ei.dt_first_image_req_tstz,
               ei.dt_first_drug_prsc_tstz,
               ei.dt_first_drug_take_tstz,
               ei.dt_first_interv_prsc_tstz,
               ei.dt_first_interv_take_tstz,
               ei.dt_first_inst_obs_tstz,
               ei.dt_init,
               ei.id_prof_first_obs,
               ei.id_prof_first_nurse_obs,
               ei.dt_first_sch,
               ei.dt_first_nurse_sch,
               ei.id_prof_first_sch,
               ei.id_prof_first_nurse_sch,
               ei.id_patient,
               ei.flg_dsch_status,
               ei.id_disch_reas_dest,
               ei.dt_med_tstz,
               ei.dt_pend_active_tstz,
               ei.id_dcs_requested,
               ei.id_instit_requested,
               ei.id_prof_schedules,
               ei.flg_sch_status,
               ei.id_complaint,
               ei.flg_urgency,
               ei.sch_group_id_patient,
               ei.id_schedule_outp,
               ei.sch_prof_outp_id_prof,
               ei.id_schedule_sr,
               ei.triage_acuity,
               ei.triage_color_text,
               ei.triage_rank_acuity,
               ei.triage_flg_letter,
               ei.fast_track_icon,
               ei.fast_track_desc,
               ei.fast_track_color,
               ei.id_room_scheduled,
               ei.room_sch_flg_status,
               ei.flg_pat_status,
               ei.dt_room_entry_tstz,
               ei.dt_surgery_time_det_tstz,
               ei.desc_diet,
               ei.dt_admin_tstz,
               ei.id_triage_color,
               ei.id_software,
               ei.create_user,
               ei.create_time,
               ei.create_institution,
               ei.update_user,
               ei.update_time,
               ei.update_institution
          INTO l_ei.id_bed,
               l_ei.id_room,
               l_ei.id_professional,
               l_ei.id_episode,
               l_ei.norton,
               l_ei.flg_hydric,
               l_ei.flg_wound,
               l_ei.companion,
               l_ei.flg_unknown,
               l_ei.desc_info,
               l_ei.id_schedule,
               l_ei.id_first_nurse_resp,
               l_ei.flg_status,
               l_ei.id_dep_clin_serv,
               l_ei.id_first_dep_clin_serv,
               l_ei.id_institution_usf,
               l_ei.id_prof_team,
               l_ei.id_triage,
               l_ei.id_triage_white_reason,
               l_ei.id_first_triage,
               l_ei.id_first_triage_wr,
               l_ei.dt_harvest_tstz,
               l_ei.dt_last_interaction_tstz,
               l_ei.dt_movement_tstz,
               l_ei.dt_next_drug_tstz,
               l_ei.dt_first_obs_tstz,
               l_ei.dt_next_intervention_tstz,
               l_ei.dt_next_vital_sign_tstz,
               l_ei.dt_next_position_tstz,
               l_ei.dt_entrance_room_tstz,
               l_ei.dt_harvest_mov_tstz,
               l_ei.dt_first_nurse_obs_tstz,
               l_ei.dt_first_analysis_exe_tstz,
               l_ei.dt_first_analysis_req_tstz,
               l_ei.dt_first_image_exec_tstz,
               l_ei.dt_first_image_req_tstz,
               l_ei.dt_first_drug_prsc_tstz,
               l_ei.dt_first_drug_take_tstz,
               l_ei.dt_first_interv_prsc_tstz,
               l_ei.dt_first_interv_take_tstz,
               l_ei.dt_first_inst_obs_tstz,
               l_ei.dt_init,
               l_ei.id_prof_first_obs,
               l_ei.id_prof_first_nurse_obs,
               l_ei.dt_first_sch,
               l_ei.dt_first_nurse_sch,
               l_ei.id_prof_first_sch,
               l_ei.id_prof_first_nurse_sch,
               l_ei.id_patient,
               l_ei.flg_dsch_status,
               l_ei.id_disch_reas_dest,
               l_ei.dt_med_tstz,
               l_ei.dt_pend_active_tstz,
               l_ei.id_dcs_requested,
               l_ei.id_instit_requested,
               l_ei.id_prof_schedules,
               l_ei.flg_sch_status,
               l_ei.id_complaint,
               l_ei.flg_urgency,
               l_ei.sch_group_id_patient,
               l_ei.id_schedule_outp,
               l_ei.sch_prof_outp_id_prof,
               l_ei.id_schedule_sr,
               l_ei.triage_acuity,
               l_ei.triage_color_text,
               l_ei.triage_rank_acuity,
               l_ei.triage_flg_letter,
               l_ei.fast_track_icon,
               l_ei.fast_track_desc,
               l_ei.fast_track_color,
               l_ei.id_room_scheduled,
               l_ei.room_sch_flg_status,
               l_ei.flg_pat_status,
               l_ei.dt_room_entry_tstz,
               l_ei.dt_surgery_time_det_tstz,
               l_ei.desc_diet,
               l_ei.dt_admin_tstz,
               l_ei.id_triage_color,
               l_ei.id_software,
               l_ei.create_user,
               l_ei.create_time,
               l_ei.create_institution,
               l_ei.update_user,
               l_ei.update_time,
               l_ei.update_institution
          FROM epis_info ei
         WHERE id_episode = i_episode_temp
           FOR UPDATE;
    
        -- apaga o registo da epis_info para este episódio apenas se não se tratar de um episódio definitivo
        -- usa a mesma lógica do delete a este episódio de forma a manter esta informação
        IF i_flg_unknown <> 'N'
        THEN
            /* <DENORM Fábio> */
            ts_epis_info.del(id_episode_in => i_episode_temp, rows_out => l_rowids);
        
            t_data_gov_mnt.process_delete(i_lang, i_prof, 'EPIS_INFO', l_rowids, o_error);
        END IF;
    
        l_ei.id_episode             := i_episode;
        l_ei.flg_unknown            := g_flg_unknown_def;
        l_ei.id_dep_clin_serv       := l_dep_clin_serv;
        l_ei.id_first_dep_clin_serv := l_first_dep_clin_serv;
        -- Alexandre Santos 30-09-2009 ALERT-44209
        IF (nvl(pk_sysconfig.get_config(l_sys_cfg_epi_loc, i_prof), 'Y') = 'Y')
        THEN
            l_ei.id_room := nvl(l_ei.id_room, l_room);
        ELSE
            l_ei.id_room := nvl(l_room, l_ei.id_room);
        END IF;
        -- José Brito 17/11/2008 ALERT-8235
        l_ei.dt_first_obs_tstz       := least(nvl(l_ei.dt_first_obs_tstz, l_dt_first_obs_def),
                                              nvl(l_dt_first_obs_def, l_ei.dt_first_obs_tstz));
        l_ei.dt_first_nurse_obs_tstz := least(nvl(l_ei.dt_first_nurse_obs_tstz, l_dt_first_nurse_obs_def),
                                              nvl(l_dt_first_nurse_obs_def, l_ei.dt_first_nurse_obs_tstz));
        -- ASantos 15-06-2009 ALERT-32105
        l_ei.dt_first_inst_obs_tstz := least(nvl(l_ei.dt_first_inst_obs_tstz, l_dt_first_inst_obs_tstz),
                                             nvl(l_dt_first_inst_obs_tstz, l_ei.dt_first_inst_obs_tstz));
    
        --BMNG - IF permanent episode has an active bed allocation, it should remain over one in the temporary episode.
        IF l_epis_bed IS NOT NULL
        THEN
            l_ei.id_bed := l_epis_bed;
        END IF;
    
        g_error := 'GET DISCHARGE FOR EPIS_INFO';
        BEGIN
            SELECT d.flg_status, d.id_disch_reas_dest, d.dt_med_tstz, d.dt_pend_active_tstz, dt_admin_tstz
              INTO l_ei.flg_dsch_status,
                   l_ei.id_disch_reas_dest,
                   l_ei.dt_med_tstz,
                   l_ei.dt_pend_active_tstz,
                   l_ei.dt_admin_tstz
              FROM discharge d
             WHERE id_episode = i_episode
               AND coalesce(d.dt_admin_tstz, d.dt_med_tstz, d.dt_pend_tstz) =
                   (SELECT MAX(coalesce(d2.dt_admin_tstz, d2.dt_med_tstz, d2.dt_pend_tstz))
                      FROM discharge d2
                     WHERE d2.id_episode = d.id_episode
                       AND d2.flg_status NOT IN
                           (pk_discharge.g_disch_flg_status_reopen, pk_discharge.g_disch_flg_status_cancel))
               AND flg_status NOT IN (pk_discharge.g_disch_flg_status_reopen, pk_discharge.g_disch_flg_status_cancel);
        EXCEPTION
            WHEN no_data_found THEN
                l_ei.flg_dsch_status    := NULL;
                l_ei.id_disch_reas_dest := NULL;
        END;
    
        /* <DENORM Fábio> */
        ts_epis_info.ins(rec_in => l_ei, rows_out => l_rowids);
    
        t_data_gov_mnt.process_insert(i_lang, i_prof, 'EPIS_INFO', l_rowids, o_error);
    
        g_error  := 'UPDATE EPISODE';
        l_rowids := table_varchar();
        ts_episode.upd(id_clinical_service_in  => nvl(l_clinical_service, -1),
                       id_clinical_service_nin => FALSE,
                       id_department_in        => nvl(l_department, -1),
                       id_department_nin       => FALSE,
                       id_dept_in              => nvl(l_dept, -1),
                       id_dept_nin             => FALSE,
                       id_episode_in           => i_episode,
                       rows_out                => l_rowids);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EPISODE',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        -- alta administrativa/médica
        -- primeiro verifica se tem alta administrativa; caso contrário verifica se tem alta médica [rui.baeta 2008/02/01]
        g_error := 'GET DATE DISCHARGE';
        BEGIN
            SELECT MAX(pk_discharge_core.get_dt_admin(i_lang, i_prof, id_discharge)), MAX(dt_med_tstz)
              INTO l_dt_admin_end_tstz, l_dt_med_end_tstz
              FROM discharge
             WHERE id_episode IN (i_episode_temp, i_episode)
               AND flg_status NOT IN (pk_discharge.g_disch_flg_status_reopen, pk_discharge.g_disch_flg_status_cancel);
        
            SELECT least(nvl(ei.dt_first_obs_tstz, ei.dt_first_nurse_obs_tstz),
                         nvl(ei.dt_first_nurse_obs_tstz, ei.dt_first_obs_tstz))
              INTO l_dt_first_obs_tstz
              FROM epis_info ei
             WHERE ei.id_episode = i_episode;
        
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        g_error := 'UPDATE EPISODE.DT_BEGIN';
        --Se o episódio temporário tem data de início anterior ao do episódio definitivo, actualiza-a
        -- jsilva 17-04-2008 validations to guarantee the discharge integrity
        IF (l_dt_begin_tstz > nvl(l_dt_med_end_tstz, current_timestamp) OR
           l_dt_begin_tstz > nvl(l_dt_first_obs_tstz, current_timestamp)) -- José Brito 14/11/2008 ALERT-8235
           AND nvl(l_dt_first_obs_tstz, current_timestamp) < nvl(l_dt_med_end_tstz, current_timestamp)
           AND l_id_prev_episode IS NOT NULL
        THEN
            g_error := 'UPDATE EPISODE.DT_BEGIN_TSTZ 1';
            /* <DENORM Fábio> */
            l_rowids := table_varchar();
            ts_episode.upd(id_episode_in     => i_episode,
                           dt_begin_tstz_in  => l_dt_first_obs_tstz,
                           dt_begin_tstz_nin => FALSE,
                           rows_out          => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang, i_prof, 'EPISODE', l_rowids, o_error, table_varchar('DT_BEGIN_TSTZ'));
        
            g_error := 'UPDATE VISIT.DT_BEGIN_TSTZ 1';
            UPDATE visit
               SET -- José Brito 11/11/2008 ALERT-9260
                   dt_end_tstz = NULL
             WHERE id_visit = i_visit;
        ELSIF l_id_prev_episode IS NULL
              OR l_dt_begin_tstz > nvl(l_dt_med_end_tstz, current_timestamp)
             -- José Brito 14/11/2008 ALERT-8235
              OR nvl(l_dt_first_obs_tstz, current_timestamp) < l_dt_begin_tstz
        THEN
            g_error := 'UPDATE EPISODE.DT_BEGIN_TSTZ 2';
            SELECT dt_begin_tstz
              INTO l_dt_begin_tstz
              FROM episode
             WHERE id_episode = i_episode_temp
               FOR UPDATE;
        
            l_rowids := table_varchar();
            ts_episode.upd(dt_begin_tstz_in  => l_dt_begin_tstz,
                           dt_begin_tstz_nin => FALSE,
                           where_in          => 'id_episode = ' || i_episode || ' AND dt_begin_tstz > ' ||
                                                '(SELECT epis.dt_begin_tstz FROM episode epis WHERE epis.id_episode = ' ||
                                                i_episode_temp || ')',
                           rows_out          => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang, i_prof, 'EPISODE', l_rowids, o_error, table_varchar('DT_BEGIN_TSTZ'));
        
            g_error := 'UPDATE VISIT.DT_BEGIN 2';
            --RB 2007/07/04
            --Se a visita temporária tem data de início anterior ao da visita definitiva, actualiza-a
            UPDATE visit
               SET -- José Brito 11/11/2008 ALERT-9260
                   dt_end_tstz = NULL
             WHERE id_visit = i_visit
               AND dt_begin_tstz > (SELECT dt_begin_tstz
                                      FROM visit
                                     WHERE id_visit = i_visit_temp);
        END IF;
    
        --Se o episódio temporário tem alta administrativa efectuada, fecha o episódio definitivo e respectiva visita
        IF l_dt_admin_end_tstz IS NOT NULL
        THEN
            g_error := 'UPDATE EPISODE.FLG_STATUS (ADMIN)';
            /* <DENORM Fábio> */
            l_rowids := table_varchar();
            ts_episode.upd(flg_status_in   => g_epis_inactive,
                           dt_end_tstz_in  => l_dt_admin_end_tstz,
                           dt_end_tstz_nin => FALSE,
                           where_in        => 'id_episode = ' || i_episode || '
               AND flg_status != ''' || g_epis_inactive || '''
               AND dt_end_tstz IS NULL',
                           rows_out        => l_rowids);
            g_error := 'PROCESS UPDATE (ADMIN)';
            t_data_gov_mnt.process_update(i_lang,
                                          i_prof,
                                          'EPISODE',
                                          l_rowids,
                                          o_error,
                                          table_varchar('FLG_STATUS', 'DT_END_TSTZ'));
            l_rowids := table_varchar();
            ts_epis_info.upd(id_episode_in     => i_episode,
                             dt_admin_tstz_in  => l_dt_admin_end_tstz,
                             dt_admin_tstz_nin => FALSE,
                             rows_out          => l_rowids);
            t_data_gov_mnt.process_update(i_lang,
                                          i_prof,
                                          'EPIS_INFO',
                                          l_rowids,
                                          o_error,
                                          table_varchar('DT_ADMIN_TSTZ'));
        
            g_error := 'SELECT COUNT (ADMIN)';
            SELECT COUNT(*)
              INTO l_count
              FROM episode
             WHERE id_visit = i_visit
               AND flg_status NOT IN (g_epis_inactive, g_cancel);
        
            IF l_count = 0
            THEN
            
                g_error  := 'UPDATE VISIT.FLG_STATUS (ADMIN)';
                l_rowids := table_varchar();
                ts_visit.upd(flg_status_in   => g_epis_inactive,
                             flg_status_nin  => FALSE,
                             dt_end_tstz_in  => l_dt_admin_end_tstz,
                             dt_end_tstz_nin => FALSE,
                             where_in        => 'id_visit = ' || i_visit || ' AND flg_status != ''' || g_epis_inactive ||
                                                ''' AND dt_end_tstz IS NULL',
                             rows_out        => l_rowids);
            
                t_data_gov_mnt.process_update(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_table_name   => 'VISIT',
                                              i_rowids       => l_rowids,
                                              o_error        => o_error,
                                              i_list_columns => table_varchar('FLG_STATUS', 'DT_END_TSTZ'));
            
                --g_error := 'UPDATE VISIT.FLG_STATUS (ADMIN)';
                --UPDATE visit
                --   SET flg_status = g_epis_inactive, dt_end_tstz = l_dt_admin_end_tstz
                -- WHERE id_visit = i_visit
                --   AND flg_status != g_epis_inactive
                --   AND dt_end_tstz IS NULL;
            END IF;
        ELSE
            -- Se o episódio temporário tem alta médica efectuada, passa o episódio para estado pendente
            -- porque, qd se faz o match de um episódio pendente (q tenha alta médica) com um episódio activo, o episodio final tem q ficar pendente,
            -- senão deixa de aparecer tarefa na coluna 'alta admin' na grelha do administrativo.
            -- Para já, isto apenas se aplica a software UBU (29) e EDIS (8)  [rui.baeta 2008/02/01]
            IF i_prof.software IN (8, 29) -- UBU (29) e EDIS (8)
               AND l_dt_med_end_tstz IS NOT NULL
            THEN
                g_error := 'UPDATE EPISODE.FLG_STATUS (MED)';
                /* <DENORM Fábio> */
                l_rowids := table_varchar();
                ts_episode.upd(flg_status_in => g_epis_pending,
                               where_in      => 'id_episode = ' || i_episode || '
                   AND flg_status != ''' || g_epis_active || '''',
                               rows_out      => l_rowids);
            
                t_data_gov_mnt.process_update(i_lang,
                                              i_prof,
                                              'EPISODE',
                                              l_rowids,
                                              o_error,
                                              table_varchar('FLG_STATUS'));
            END IF;
        END IF;
    
        g_error := 'UPDATE VISIT.DT_BEGIN_TSTZ';
        UPDATE visit v
           SET v.dt_begin_tstz =
               (SELECT MIN(e.dt_begin_tstz)
                  FROM episode e
                 WHERE e.id_visit = i_visit)
         WHERE v.id_visit = i_visit;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MATCH',
                                              'SET_EPISODE_DATES',
                                              o_error);
            -- José Brito 10/07/2009 ALERT-34678  Match integration between ALERT clinical/non-clinical
            --pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_episode_dates;

    /**********************************************************************************************
    * SET_MATCH_EPISODES_INTERNAL            TEsta função faz o "match" entre dois episódios relacionados.
    *
    *      NOTAS: A função do Alert-ER tem casos especiais, por exemplo, na alta quando o episódio
    *             de urgência dá origem a um episódio de OBS. Nos casos em que hajam esses casos
    *             especiais, cada produto devem implementar os seus...
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_episode_temp                  Temporary episode
    * @param i_episode                       Episode identifier
    * @param i_transaction_id                remote transaction identifier
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Rui Batista
    * @version                               0.1
    * @since                                 2007/01/16
    **********************************************************************************************/
    FUNCTION set_match_episodes_internal
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode_temp   IN episode.id_episode%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_transaction_id IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_patient       patient.id_patient%TYPE;
        l_patient_temp  patient.id_patient%TYPE;
        l_visit         visit.id_visit%TYPE;
        l_visit_def     visit.id_visit%TYPE;
        l_num_episodes  PLS_INTEGER;
        l_id_match_epis match_epis.id_match_epis%TYPE;
    
        --jsilva 03-04-2007 novas variaveis locais e cursor
        l_id_professional_perm epis_info.id_professional%TYPE;
        l_id_first_nurse_perm  epis_info.id_first_nurse_resp%TYPE;
    
        --
        TYPE t_all_exm IS TABLE OF exam_req_det%ROWTYPE INDEX BY BINARY_INTEGER;
        TYPE t_lab_exm IS TABLE OF analysis_req_det%ROWTYPE INDEX BY BINARY_INTEGER;
    
        l_all_exm t_all_exm;
        l_lab_exm t_lab_exm;
    
        l_flg_status  episode.flg_status%TYPE;
        l_flg_unknown epis_info.flg_unknown%TYPE;
        --
        l_rowids table_varchar;
        --
        CURSOR c_epis_prof IS
            SELECT id_professional, id_first_nurse_resp
              FROM epis_info
             WHERE id_episode = i_episode;
    
        l_id_professional     epis_info.id_professional%TYPE;
        l_id_first_nurse_resp epis_info.id_first_nurse_resp%TYPE;
        l_id_episode          epis_info.id_episode%TYPE;
    
        l_flg_type_cat category.flg_type%TYPE;
    
        l_id_prev_episode   episode.id_prev_episode%TYPE;
        l_id_prev_epis_temp episode.id_prev_episode%TYPE;
        l_id_prev_epis_type episode.id_epis_type%TYPE;
    
        l_oth_episode episode.id_episode%TYPE;
        --MATCH_EPISODE_M002 Exception
        l_matchepisode_exception EXCEPTION;
    
        --bmng
        l_epis_bed       epis_info.id_bed%TYPE;
        l_epis_tmp_bed   epis_info.id_bed%TYPE;
        l_count          NUMBER;
        l_id_visit       visit.id_visit%TYPE;
        l_id_patient     patient.id_patient%TYPE;
        l_transaction_id VARCHAR2(4000);
    BEGIN
        g_error := '[V$SESSION] <-> SID: ' || sys_context('USERENV', 'SID') || ';';
        pk_alertlog.log_debug(text            => g_error,
                              object_name     => 'PK_MATCH',
                              sub_object_name => 'SET_MATCH_EPISODES_INTERNAL');
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        g_sysdate := SYSDATE;
        --Determina o paciente do episódio final, já que o paciente temporário irá ser
        --  eliminado posteriormente
        g_error := 'GET PATIENT ID';
        BEGIN
            -- jsilva 17-04-2008 check for previous episodes (discharge to another institution)
            SELECT e.id_patient, e.id_prev_episode, ei.id_bed
              INTO l_patient, l_id_prev_episode, l_epis_bed
              FROM episode e
             INNER JOIN epis_info ei
                ON ei.id_episode = e.id_episode
             WHERE e.id_episode = i_episode;
        EXCEPTION
            WHEN no_data_found THEN
                RAISE g_exception;
        END;
    
        --Determina o paciente do episódio temporário. Este paciente temporário irá ser
        --  eliminado posteriormente
        g_error := 'GET TEMP PATIENT ID';
        BEGIN
            /*SELECT e.id_patient, e2.id_episode, e2.id_epis_type
             INTO l_patient_temp, l_id_prev_epis_temp, l_id_prev_epis_type
             FROM episode e, episode e2
            WHERE e.id_episode = i_episode_temp
              AND e2.id_episode = e.id_prev_episode;*/
            SELECT e.id_patient, e2.id_episode, e2.id_epis_type
              INTO l_patient_temp, l_id_prev_epis_temp, l_id_prev_epis_type
              FROM episode e
              LEFT JOIN episode e2
                ON e2.id_episode = e.id_prev_episode
             WHERE e.id_episode = i_episode_temp;
        EXCEPTION
            WHEN no_data_found THEN
                g_error := 'NO_DATA_FOUND  TEMP i_episode_temp:' || i_episode_temp;
                --avisar que o paciente não existe
                --é o problema de haver lag entre o match comcluir e o ecrã saltar
                RAISE l_matchepisode_exception;
        END;
    
        g_error := 'SELECT TEMP VISIT';
        pk_alertlog.log_debug(text            => g_error,
                              object_name     => 'PK_MATCH',
                              sub_object_name => 'SET_MATCH_EPISODES_INTERNAL');
        SELECT id_visit
          INTO l_visit
          FROM episode
         WHERE id_episode = i_episode_temp;
    
        g_error := 'SELECT DEF VISIT';
        pk_alertlog.log_debug(text            => g_error,
                              object_name     => 'PK_MATCH',
                              sub_object_name => 'SET_MATCH_EPISODES_INTERNAL');
        SELECT id_visit
          INTO l_visit_def
          FROM episode
         WHERE id_episode = i_episode;
    
        -- José Brito 29/08/2008 Obter estado e tipo do episódio I_EPISODE_TEMP
        g_error := 'CALL TO PK_EPISODE.GET_FLG_STATUS';
        IF NOT pk_episode.get_flg_status(i_lang       => i_lang,
                                         i_prof       => i_prof,
                                         i_id_episode => i_episode_temp,
                                         o_flg_status => l_flg_status,
                                         o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        -- José Brito 29/08/2008 Obter o tipo de episódio: definitivo ou temporário.
        -- Só no match de cancelados é que poderá surgir um episódio definitivo.
        g_error := 'CALL TO PK_EPISODE.GET_FLG_UNKNOWN';
        IF NOT pk_episode.get_flg_unknown(i_lang        => i_lang,
                                          i_prof        => i_prof,
                                          i_id_episode  => i_episode_temp,
                                          o_flg_unknown => l_flg_unknown,
                                          o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
        --
    
        --Activity Therapist: It must be before the other match funtions, because
        --it is necessary to match the Activity Therapy episodes before matching the inp episodes
        g_error := 'CALL pk_activity_therapist.set_match_act_therapy';
        pk_alertlog.log_debug(text            => g_error,
                              object_name     => 'PK_MATCH',
                              sub_object_name => 'SET_MATCH_EPISODES_INTERNAL');
    
        IF NOT pk_activity_therapist.set_match_act_therapy(i_lang         => i_lang,
                                                           i_prof         => i_prof,
                                                           i_episode_temp => i_episode_temp,
                                                           i_episode      => i_episode,
                                                           o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        --global search
        g_error := 'CALL pk_translation.upd_translation_trs_epis';
        pk_translation.upd_translation_trs_epis(i_old_epis => i_episode_temp, i_new_epis => i_episode);
    
        --Actualiza as tabelas específicas do ORIS
        g_error := 'CALL TO SET_MATCH_ORIS';
        pk_alertlog.log_debug(text            => g_error,
                              object_name     => 'PK_MATCH',
                              sub_object_name => 'SET_MATCH_EPISODES_INTERNAL');
        IF NOT pk_match.set_match_oris(i_lang, i_prof, i_episode_temp, i_episode, l_patient, l_patient_temp, o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        --Actualiza as tabelas específicas do EDIS
        g_error := 'CALL TO SET_MATCH_EDIS';
        pk_alertlog.log_debug(text            => g_error,
                              object_name     => 'PK_MATCH',
                              sub_object_name => 'SET_MATCH_EPISODES_INTERNAL');
        IF NOT pk_match.set_match_edis(i_lang, i_prof, i_episode_temp, i_episode, l_patient, l_patient_temp, o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        -- Update tables and functionalities under INPATIENT responsability
        -- NOTE: This function must always be run before function SET_MATCH_CORE
        g_error := 'CALL TO SET_MATCH_INP';
        pk_alertlog.log_debug(text            => g_error,
                              object_name     => 'PK_MATCH',
                              sub_object_name => 'SET_MATCH_EPISODES_INTERNAL');
        IF NOT pk_match.set_match_inp(i_lang           => i_lang,
                                      i_prof           => i_prof,
                                      i_episode_temp   => i_episode_temp,
                                      i_episode        => i_episode,
                                      i_patient        => l_patient,
                                      i_patient_temp   => l_patient_temp,
                                      i_transaction_id => l_transaction_id,
                                      o_error          => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL pk_past_history.set_match_episode';
        pk_alertlog.log_info(text => g_error, object_name => 'PK_PAST_HISTORY', sub_object_name => 'SET_MATCH_EPISODE');
        IF NOT pk_past_history.set_match_episode(i_lang         => i_lang,
                                                 i_prof         => i_prof,
                                                 i_episode      => i_episode,
                                                 i_episode_temp => i_episode_temp,
                                                 o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        --pharmacy
        g_error := 'CALL pk_api_pfh_in.match_episode_pharmacy';
        pk_alertlog.log_info(text            => g_error,
                             object_name     => 'PK_MATCH',
                             sub_object_name => 'SET_MATCH_EPISODES_INTERNAL');
        IF NOT pk_api_pfh_in.match_episode_pharmacy(i_lang         => i_lang,
                                                    i_prof         => i_prof,
                                                    i_episode      => i_episode,
                                                    i_episode_temp => i_episode_temp,
                                                    o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- José Brito 03/06/2008 Para os episódios cancelados devem ser repostas as tarefas nas tabelas GRID_TASK
        IF l_flg_status = g_cancel
        THEN
            -- Exames de Imagem e Outros Exames
            g_error := 'GET  exam_req';
            SELECT erd.*
              BULK COLLECT
              INTO l_all_exm
              FROM exam_req_det erd, exam_req er
             WHERE (er.id_episode = i_episode_temp OR er.id_episode_origin = i_episode_temp)
               AND er.id_exam_req = erd.id_exam_req;
        
            IF l_all_exm.count > 0
            THEN
                l_rowids := NULL;
                FOR i IN 1 .. l_all_exm.count
                LOOP
                    g_error := 'UPDATE exam_req (ID_EPISODE) id_exam_req = ' || l_all_exm(i).id_exam_req;
                    ts_exam_req.upd(id_episode_in => i_episode,
                                    id_patient_in => l_patient,
                                    id_visit_in   => l_visit_def,
                                    where_in      => 'id_exam_req = ' || l_all_exm(i).id_exam_req ||
                                                     ' AND id_episode IS NOT NULL',
                                    rows_out      => l_rowids);
                
                    g_error := 'UPDATE exam_req (ID_EPISODE_ORIGIN ) id_exam_req = ' || l_all_exm(i).id_exam_req;
                    ts_exam_req.upd(id_episode_origin_in => i_episode,
                                    id_patient_in        => l_patient,
                                    where_in             => 'id_exam_req = ' || l_all_exm(i).id_exam_req ||
                                                            ' AND id_episode_origin IS NOT NULL',
                                    rows_out             => l_rowids);
                    g_error := 'UPDATE exam_req (ID_EPISODE_DESTINATION) id_exam_req = ' || l_all_exm(i).id_exam_req;
                    ts_exam_req.upd(id_episode_destination_in => i_episode,
                                    id_patient_in             => l_patient,
                                    where_in                  => 'id_exam_req = ' || l_all_exm(i).id_exam_req ||
                                                                 ' AND id_episode_destination IS NOT NULL',
                                    rows_out                  => l_rowids);
                
                    g_error := 'CALL PROCESS_UPDATE EXAM_REQ';
                    t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'EXAM_REQ',
                                                  i_rowids     => l_rowids,
                                                  o_error      => o_error);
                
                    /*grid_task_img, grid_task_oth_exm*/
                    g_error := 'CALL pk_exams_api_db.set_exam_grid_task';
                    pk_alertlog.log_debug(text            => g_error,
                                          object_name     => 'PK_MATCH',
                                          sub_object_name => 'SET_MATCH_EPISODES_INTERNAL');
                    IF NOT pk_exams_api_db.set_exam_grid_task(i_lang         => i_lang,
                                                              i_prof         => i_prof,
                                                              i_patient      => l_patient,
                                                              i_episode      => i_episode,
                                                              i_exam_req     => l_all_exm(i).id_exam_req,
                                                              i_exam_req_det => l_all_exm(i).id_exam_req_det,
                                                              o_error        => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                END LOOP;
            END IF;
        
            -- Análises
            g_error := 'GET analysis_req';
            SELECT ard.*
              BULK COLLECT
              INTO l_lab_exm
              FROM analysis_req_det ard, analysis_req ar
             WHERE (ar.id_episode = i_episode_temp OR ard.id_episode_origin = i_episode_temp)
               AND ard.id_analysis_req = ar.id_analysis_req;
        
            IF l_lab_exm.count > 0
            THEN
                g_error := 'LOOP l_lab_exm';
                FOR i IN 1 .. l_lab_exm.count
                LOOP
                    l_rowids := NULL;
                    g_error  := 'UPDATE analysis_req (I_EPISODE) id_analysis_req = ' || l_lab_exm(i).id_analysis_req;
                    ts_analysis_req.upd(id_episode_in => i_episode,
                                        id_patient_in => l_patient,
                                        id_visit_in   => l_visit_def,
                                        where_in      => 'id_analysis_req = ' || l_lab_exm(i).id_analysis_req ||
                                                         ' AND id_episode IS NOT NULL',
                                        rows_out      => l_rowids);
                
                    g_error := 'UPDATE analysis_req (I_EPISODE_ORIGIN) id_analysis_req = ' || l_lab_exm(i).id_analysis_req;
                    ts_analysis_req.upd(id_episode_origin_in => i_episode,
                                        id_patient_in        => l_patient,
                                        where_in             => 'id_analysis_req = ' || l_lab_exm(i).id_analysis_req ||
                                                                ' AND id_episode_origin IS NOT NULL',
                                        rows_out             => l_rowids);
                
                    g_error := 'UPDATE analysis_req (I_EPISODE_DESTINATION) id_analysis_req = ' || l_lab_exm(i).id_analysis_req;
                    ts_analysis_req.upd(id_episode_destination_in => i_episode,
                                        id_patient_in             => l_patient,
                                        where_in                  => 'id_analysis_req = ' || l_lab_exm(i).id_analysis_req ||
                                                                     ' AND id_episode_destination IS NOT NULL',
                                        rows_out                  => l_rowids);
                
                    g_error := 'CALL PROCESS_UPDATE ANALYSIS_REQ (2)';
                    t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'ANALYSIS_REQ',
                                                  i_rowids     => l_rowids,
                                                  o_error      => o_error);
                
                    l_rowids := NULL;
                    ts_analysis_req_det.upd(id_episode_origin_in => i_episode,
                                            where_in             => 'id_analysis_req_det = ' || l_lab_exm(i).id_analysis_req_det ||
                                                                    ' AND id_episode_origin IS NOT NULL',
                                            rows_out             => l_rowids);
                
                    g_error := 'UPDATE analysis_req (I_EPISODE_ORIGIN) id_analysis_req_det = ' || l_lab_exm(i).id_analysis_req_det;
                    ts_analysis_req_det.upd(id_episode_destination_in => i_episode,
                                            where_in                  => 'id_analysis_req_det = ' || l_lab_exm(i).id_analysis_req_det ||
                                                                         ' AND id_episode_destination IS NOT NULL',
                                            rows_out                  => l_rowids);
                
                    g_error := 'CALL PROCESS_UPDATE ANALYSIS_REQ_DET(2)';
                    t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'ANALYSIS_REQ_DET',
                                                  i_rowids     => l_rowids,
                                                  o_error      => o_error);
                
                    /*gird_task_lab_req*/
                    g_error := 'CALL pk_lab_tests_api_db.set_lab_test_grid_task';
                    pk_alertlog.log_debug(text            => g_error,
                                          object_name     => 'PK_MATCH',
                                          sub_object_name => 'SET_MATCH_EPISODES_INTERNAL');
                    IF NOT pk_lab_tests_api_db.set_lab_test_grid_task(i_lang             => i_lang,
                                                                      i_prof             => i_prof,
                                                                      i_patient          => l_patient,
                                                                      i_episode          => i_episode,
                                                                      i_analysis_req     => l_lab_exm(i).id_analysis_req,
                                                                      i_analysis_req_det => l_lab_exm(i).id_analysis_req_det,
                                                                      o_error            => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                END LOOP;
            END IF;
        
        END IF;
        --
    
        --Actualiza a tabela GRID_TASK
        g_error := 'CALL pk_match.set_match_grid_task';
        pk_alertlog.log_debug(text            => g_error,
                              object_name     => 'PK_MATCH',
                              sub_object_name => 'SET_MATCH_EPISODES_INTERNAL');
        IF NOT pk_match.set_match_grid_task(i_lang, i_prof, i_episode, o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        --Actualiza as tabelas específicas do CORE
        --THIS CALL MUST BE DONE AFTER pk_match.set_match_grid_task (BECAUSE DELETE TO GRID_TASK IS INSIDE THIS FUNCTION)!
        g_error := 'CALL TO SET_MATCH_CORE';
        pk_alertlog.log_debug(text            => g_error,
                              object_name     => 'PK_MATCH',
                              sub_object_name => 'SET_MATCH_EPISODES_INTERNAL');
        IF NOT pk_match.set_match_core(i_lang,
                                       i_prof,
                                       i_episode_temp,
                                       i_episode,
                                       l_patient,
                                       l_patient_temp,
                                       l_flg_unknown,
                                       o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        --Preenche a tabela que relaciona os episódios
        g_error := 'INSERT MATCH_EPIS';
        pk_alertlog.log_debug(text            => g_error,
                              object_name     => 'PK_MATCH',
                              sub_object_name => 'SET_MATCH_EPISODES_INTERNAL');
        INSERT INTO match_epis
            (id_match_epis, id_episode, id_episode_temp, id_patient, id_patient_temp, id_professional, dt_match_tstz)
        VALUES
            (seq_match_epis.nextval,
             i_episode,
             i_episode_temp,
             l_patient,
             l_patient_temp,
             i_prof.id,
             current_timestamp)
        
        RETURNING id_match_epis INTO l_id_match_epis;
    
        --No Fim
        --Actualiza o paciente e o episódio
        --O agendamento do episódio temporário tem que ser eliminado
    
        --jsilva 03-04-2007 caso o episodio temporario não tenha medico nem enfermeiro responsavel fica com os do episodio permanente
    
        l_id_first_nurse_perm  := NULL;
        l_id_professional_perm := NULL;
    
        g_error := 'GET EPIS PROF INFO';
        pk_alertlog.log_debug(text            => g_error,
                              object_name     => 'PK_MATCH',
                              sub_object_name => 'SET_MATCH_EPISODES_INTERNAL');
        OPEN c_epis_prof;
        FETCH c_epis_prof
            INTO l_id_professional_perm, l_id_first_nurse_perm;
        CLOSE c_epis_prof;
    
        -- José Brito 21/11/2008 ALERT-10341
        -- Obter a categoria do profissional responsável. Isto é necessário, pois foi detectado
        -- um problema nalguns pacientes em que existiam administrativos responsáveis pelos respectivos episódios.
        -- Como o match não previa essa possibilidade, o erro foi-se propagando.
        g_error := 'GET PROFESSIONAL CATEGORY';
        pk_alertlog.log_debug(text            => g_error,
                              object_name     => 'PK_MATCH',
                              sub_object_name => 'SET_MATCH_EPISODES_INTERNAL');
        IF l_id_professional_perm IS NOT NULL
        THEN
            g_error        := 'CALL pk_prof_utils.get_category';
            l_flg_type_cat := pk_prof_utils.get_category(i_lang,
                                                         profissional(l_id_professional_perm,
                                                                      i_prof.institution,
                                                                      i_prof.software));
        END IF;
    
        g_error := 'UPDATE EPIS PROF INFO';
        pk_alertlog.log_debug(text            => g_error,
                              object_name     => 'PK_MATCH',
                              sub_object_name => 'SET_MATCH_EPISODES_INTERNAL');
        SELECT id_professional, id_first_nurse_resp, id_episode, id_bed
          INTO l_id_professional, l_id_first_nurse_resp, l_id_episode, l_epis_tmp_bed
          FROM epis_info
         WHERE id_episode = i_episode_temp
           FOR UPDATE;
    
        l_rowids := NULL;
    
        IF (l_id_professional IS NULL OR l_id_first_nurse_resp IS NULL)
        THEN
        
            -- José Brito 21/11/2008 ALERT-10341
            l_id_professional_perm := CASE l_flg_type_cat
                                          WHEN 'A' THEN
                                           NULL
                                          ELSE
                                           l_id_professional_perm
                                      END;
        
            /* <DENORM Fábio> */
            g_error := 'UPDATE EPIS_INFO';
            ts_epis_info.upd(id_episode_in           => i_episode_temp,
                             id_professional_in      => nvl(l_id_professional, l_id_professional_perm),
                             id_first_nurse_resp_in  => nvl(l_id_first_nurse_resp, l_id_first_nurse_perm),
                             id_professional_nin     => FALSE,
                             id_first_nurse_resp_nin => FALSE,
                             rows_out                => l_rowids);
            g_error := 'PROCESS UPDATE EPIS_INFO';
            t_data_gov_mnt.process_update(i_lang,
                                          i_prof,
                                          'EPIS_INFO',
                                          l_rowids,
                                          o_error,
                                          table_varchar('ID_PROFESSIONAL', 'ID_FIRST_NURSE_RESP'));
        END IF;
    
        ---------------------------------------------------------------------------------------------------
        -- José Brito 14/11/2008 ALERT-8235
        g_error := 'CALL TO SET_EPISODE_DATES';
        pk_alertlog.log_debug(text            => g_error,
                              object_name     => 'PK_MATCH',
                              sub_object_name => 'SET_MATCH_EPISODES_INTERNAL');
        IF NOT set_episode_dates(i_lang         => i_lang,
                                 i_prof         => i_prof,
                                 i_episode      => i_episode,
                                 i_episode_temp => i_episode_temp,
                                 i_visit        => l_visit_def,
                                 i_visit_temp   => l_visit,
                                 i_flg_unknown  => l_flg_unknown,
                                 o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL pk_edis_triage.set_alert_triage';
        pk_alertlog.log_debug(text            => g_error,
                              object_name     => 'PK_MATCH',
                              sub_object_name => 'SET_MATCH_EPISODES_INTERNAL');
        IF NOT pk_edis_triage.set_alert_triage(i_lang       => i_lang,
                                               i_prof       => i_prof,
                                               i_id_episode => i_episode,
                                               i_dt_req_det => NULL,
                                               i_alert_type => NULL,
                                               i_type       => pk_edis_triage.g_type_match,
                                               o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        --        
        g_error := 'PAT_PROB_VISIT';
        pk_alertlog.log_debug(text            => g_error,
                              object_name     => 'PK_MATCH',
                              sub_object_name => 'SET_MATCH_EPISODES_INTERNAL');
        UPDATE pat_prob_visit
           SET id_visit =
               (SELECT id_visit
                  FROM episode
                 WHERE id_episode = i_episode)
         WHERE id_visit = l_visit;
    
        --RS 20080213 faz o update da coluna da visita nas análises (ANALYSIS_REQ, ANALYSIS_RESULT e HARVEST)
        /* <DENORM Fábio> */
        l_rowids := table_varchar();
        g_error  := 'UPDATE analysis_req ';
        ts_analysis_req.upd(id_visit_in  => l_visit_def,
                            id_visit_nin => FALSE,
                            where_in     => 'id_visit = ' || l_visit,
                            rows_out     => l_rowids);
        g_error := 'PROCESS UPDATE analysis_req ';
        t_data_gov_mnt.process_update(i_lang, i_prof, 'ANALYSIS_REQ', l_rowids, o_error, table_varchar('ID_VISIT'));
    
        g_error := 'UPDATE analysis_req_hist ';
        UPDATE analysis_req_hist
           SET id_visit = l_visit_def
         WHERE id_visit = l_visit;
    
        /* <DENORM Fábio> */
        l_rowids := table_varchar();
        g_error  := 'UPDATE analysis_result ';
        ts_analysis_result.upd(id_visit_in  => l_visit_def,
                               id_visit_nin => FALSE,
                               where_in     => 'id_visit = ' || l_visit,
                               rows_out     => l_rowids);
        g_error := 'PROCESS UPDATE analysis_result ';
        t_data_gov_mnt.process_update(i_lang, i_prof, 'ANALYSIS_RESULT', l_rowids, o_error, table_varchar('ID_VISIT'));
    
        l_rowids := table_varchar();
        g_error  := 'UPDATE analysis_result_hist ';
        ts_analysis_result_hist.upd(id_visit_in  => l_visit_def,
                                    id_visit_nin => FALSE,
                                    where_in     => 'id_visit = ' || l_visit,
                                    rows_out     => l_rowids);
        g_error := 'PROCESS UPDATE analysis_result_hist ';
        t_data_gov_mnt.process_update(i_lang,
                                      i_prof,
                                      'ANALYSIS_RESULT_HIST',
                                      l_rowids,
                                      o_error,
                                      table_varchar('ID_VISIT'));
    
        /* <DENORM Fábio> */
        l_rowids := table_varchar();
        g_error  := 'UPDATE HARVEST ';
        ts_harvest.upd(id_visit_in  => l_visit_def,
                       id_visit_nin => FALSE,
                       where_in     => 'id_visit = ' || l_visit,
                       rows_out     => l_rowids);
    
        g_error := 'PROCESS UPDATE HARVEST ';
        t_data_gov_mnt.process_update(i_lang, i_prof, 'HARVEST', l_rowids, o_error, table_varchar('ID_VISIT'));
    
        --        
        g_error := 'UPDATE PAT_RCM_H';
        UPDATE pat_rcm_h a
           SET a.id_epis_created = i_episode
         WHERE a.id_epis_created = i_episode_temp;
        --
    
        g_error := 'UPDATE HARVEST_HIST ';
        UPDATE harvest_hist
           SET id_visit = l_visit_def
         WHERE id_visit = l_visit;
    
        g_error := 'CALL pk_prog_notes_core.set_match_single_page.';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_core.set_match_single_page(i_lang         => i_lang,
                                                        i_prof         => i_prof,
                                                        i_episode_temp => i_episode_temp,
                                                        i_episode      => i_episode,
                                                        o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL pk_aih.match_episode_aih.';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_aih.match_episode_aih(i_lang         => i_lang,
                                        i_prof         => i_prof,
                                        i_episode_temp => i_episode_temp,
                                        i_episode      => i_episode,
                                        o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        --EA's
        DELETE FROM monitorizations_ea a
         WHERE a.id_episode = i_episode_temp;
    
        DELETE FROM monitorizations_ea a
         WHERE a.id_visit IN (SELECT e.id_visit
                                FROM episode e
                               WHERE e.id_episode = i_episode_temp);
    
        DELETE FROM task_timeline_ea a
         WHERE a.id_visit IN (SELECT e.id_visit
                                FROM episode e
                               WHERE e.id_episode = i_episode_temp);
    
        DELETE FROM task_timeline_ea a
         WHERE a.id_episode = i_episode_temp;
    
        DELETE FROM vs_visit_ea a
         WHERE a.id_visit IN (SELECT e.id_visit
                                FROM episode e
                               WHERE e.id_episode = i_episode_temp);
    
        DELETE FROM lab_tests_ea a
         WHERE a.id_visit IN (SELECT e.id_visit
                                FROM episode e
                               WHERE e.id_episode = i_episode_temp);
    
        -- MATCH TASK TIMELINE
        g_error := 'CALL pk_ea_logic_tasktimeline.set_episode';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_ea_logic_tasktimeline.set_episode(i_lang         => i_lang,
                                                    i_prof         => i_prof,
                                                    i_episode_temp => i_episode_temp,
                                                    i_episode      => i_episode,
                                                    o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        ---------------------------------------------------------------------------------------------------
        -- José Brito 05/02/2009 ALERT-9546
        -- Check if exists an active episode with the same previous episode has the cancelled episode.
        -- ONLY for match of cancelled episodes --
        IF l_flg_status = g_cancel
        THEN
            g_error := 'EPISODE CANCELED';
            BEGIN
                SELECT e.id_episode
                  INTO l_oth_episode
                  FROM episode e
                 WHERE e.id_prev_episode = l_id_prev_epis_temp
                   AND e.id_episode <> i_episode_temp
                   AND e.id_episode <> i_episode
                   AND e.flg_status IN ('A', 'P');
            EXCEPTION
                WHEN no_data_found THEN
                    l_oth_episode := NULL;
            END;
        
            IF l_oth_episode IS NOT NULL
            THEN
                -- Remove association with the previous episode,
                -- to avoid having two active episodes with the same previous episode.
                -- This could happen with the recent developments for 2.4.4, that allow
                -- cancellation of episodes during cancellation of medical discharge.
                l_id_prev_epis_temp := NULL;
            END IF;
        
        END IF;
        ---------------------------------------------------------------------------------------------------
    
        g_error := 'UPDATE EPISODE';
        pk_alertlog.log_debug(text            => g_error,
                              object_name     => 'PK_MATCH',
                              sub_object_name => 'SET_MATCH_EPISODES_INTERNAL');
        l_rowids := table_varchar();
        ts_episode.upd(id_prev_episode_in  => i_episode,
                       id_prev_episode_nin => FALSE,
                       where_in            => 'id_prev_episode = ' || i_episode_temp,
                       rows_out            => l_rowids);
        g_error := 'PROCESS UPDATE EPISODE';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EPISODE',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        g_error := 'UPDATE PREV EPISODE';
        pk_alertlog.log_debug(text            => g_error,
                              object_name     => 'PK_MATCH',
                              sub_object_name => 'SET_MATCH_EPISODES_INTERNAL');
        IF l_id_prev_episode IS NULL
        THEN
        
            l_rowids := table_varchar();
            g_error  := 'UPDATE EPISODE WITH PREV_EPISODE';
            ts_episode.upd(id_prev_episode_in    => l_id_prev_epis_temp,
                           id_prev_episode_nin   => FALSE,
                           id_prev_epis_type_in  => l_id_prev_epis_type,
                           id_prev_epis_type_nin => FALSE,
                           id_episode_in         => i_episode,
                           rows_out              => l_rowids);
            g_error := 'PROCESS UPDATE EPISODE WITH PREV_EPISODE';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'EPISODE',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
        END IF;
    
        SELECT COUNT(1)
          INTO l_count
          FROM episode e
         WHERE e.id_visit IN (SELECT e1.id_visit
                                FROM episode e1
                               WHERE e1.id_episode = i_episode_temp);
    
        IF l_count > 0
        THEN
        
            -- José Brito 22/02/2010 ALERT-75265
            g_error := 'GET VISIT ID (MORE THEN ONE EPISODE)';
            SELECT id_visit, id_patient
              INTO l_id_visit, l_id_patient
              FROM episode
             WHERE id_episode = i_episode;
        
            -- Update ID_VISIT in all episodes of the same visit as the temporary episode
            g_error := 'UPDATE EPISODE (1)';
            ts_episode.upd(id_visit_in    => l_id_visit,
                           id_visit_nin   => FALSE,
                           id_patient_in  => l_id_patient,
                           id_patient_nin => FALSE,
                           where_in       => 'id_visit IN (SELECT e1.id_visit
                                                             FROM episode e1
                                                            WHERE e1.id_episode = ' ||
                                             i_episode_temp || ')',
                           rows_out       => l_rowids);
        END IF;
    
        --verifica se se pode eliminar a visita
        g_error := 'COUNT EPISODES';
        pk_alertlog.log_debug(text            => g_error,
                              object_name     => 'PK_MATCH',
                              sub_object_name => 'SET_MATCH_EPISODES_INTERNAL');
        SELECT COUNT(*)
          INTO l_num_episodes
          FROM episode
         WHERE id_visit = l_visit;
    
        g_error := 'DELETE FROM episode; i_episode_temp=' || i_episode_temp || '; i_episode=' || i_episode;
        pk_alertlog.log_debug(text            => g_error,
                              object_name     => 'PK_MATCH',
                              sub_object_name => 'SET_MATCH_EPISODES_INTERNAL');
        -- José Brito 29/08/2008 MatchCancelados: se o episódio cancelado fôr definitivo, não se elimina o registo na tabela EPISODE
        IF l_flg_unknown <> 'N'
        THEN
        
            --ADT Apagar dados da admissao ADT
            g_error := 'CALL TO PK_ADT.DELETE_ADT_EPISODE';
            pk_alertlog.log_debug(text            => g_error,
                                  object_name     => 'PK_MATCH',
                                  sub_object_name => 'SET_MATCH_EPISODES_INTERNAL');
            IF NOT pk_adt.delete_adt_episode(i_lang         => i_lang,
                                             i_prof         => i_prof,
                                             i_episode_temp => i_episode_temp,
                                             i_episode      => i_episode,
                                             o_error        => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            --Migrate sys_alert_notification
            g_error := 'UPDATE SYS_ALERT_NOTIFICATION';
            UPDATE sys_alert_notification san
               SET san.id_episode = i_episode
             WHERE san.id_episode = i_episode_temp;
        
            --Migrate prof_follow_episode
            g_error := 'UPDATE PROF_FOLLOW_EPISODE';
            UPDATE prof_follow_episode pfe
               SET pfe.id_episode = i_episode
             WHERE pfe.id_episode = i_episode_temp;
        
            -- Só no match de cancelados é que poderão surgir episódios com FLG_UNKNOWN = 'N' pelo que basta comparar o valor dessa variável
            /* <DENORM Fábio> */
            g_error := 'DELETE FROM episode; i_episode_temp=' || i_episode_temp || '; i_episode=' || i_episode;
            pk_alertlog.log_debug(text            => g_error,
                                  object_name     => 'PK_MATCH',
                                  sub_object_name => 'SET_MATCH_EPISODES_INTERNAL');
            l_rowids := table_varchar();
            ts_episode.del(id_episode_in => i_episode_temp, handle_error_in => FALSE, rows_out => l_rowids);
        
            g_error := 'PROCESS DELETE EPISODE';
            pk_alertlog.log_debug(text            => g_error,
                                  object_name     => 'PK_MATCH',
                                  sub_object_name => 'SET_MATCH_EPISODES_INTERNAL');
            t_data_gov_mnt.process_delete(i_lang, i_prof, 'EPISODE', l_rowids, o_error);
        END IF;
    
        -- José Brito 29/08/2008 MatchCancelados: se o episódio cancelado fôr definitivo, não se elimina o registo na tabela VISIT
        IF l_num_episodes <= 1
           AND l_flg_unknown <> 'N'
        THEN
        
            --ADT Apagar dados da admissao ADT
            g_error := 'CALL TO PK_ADT.DELETE_ADT_VISIT';
            pk_alertlog.log_debug(text            => g_error,
                                  object_name     => 'PK_MATCH',
                                  sub_object_name => 'SET_MATCH_EPISODES_INTERNAL');
            IF NOT pk_adt.delete_adt_visit(i_lang       => i_lang,
                                           i_prof       => i_prof,
                                           i_visit_temp => l_visit,
                                           i_visit      => l_visit_def,
                                           o_error      => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            g_error := 'DELETE FROM VISIT:' || l_visit;
            pk_alertlog.log_debug(text            => g_error,
                                  object_name     => 'PK_MATCH',
                                  sub_object_name => 'SET_MATCH_EPISODES_INTERNAL');
            DELETE FROM visit
             WHERE id_visit = l_visit;
        END IF;
    
        --Garante que o tipo de episódio fica como normal, já que não poderá existir match entre
        -- dois episódios de planeamento.
        g_error := 'UPDATE EPISODE.FLG_EHR';
        pk_alertlog.log_debug(text            => g_error,
                              object_name     => 'PK_MATCH',
                              sub_object_name => 'SET_MATCH_EPISODES_INTERNAL');
        /* <DENORM Fábio> */
        l_rowids := table_varchar();
        ts_episode.upd(flg_ehr_in  => g_episode_flg_ehr_n,
                       flg_ehr_nin => FALSE,
                       where_in    => 'id_episode = ' || i_episode || '
           AND flg_ehr != ''' || g_episode_flg_ehr_n || '''',
                       rows_out    => l_rowids);
    
        g_error := 'PROCESS UPDATE EPISODE FLG_EHR';
        t_data_gov_mnt.process_update(i_lang, i_prof, 'EPISODE', l_rowids, o_error, table_varchar('FLG_EHR'));
    
        --Se há match de episódios é porque o episódio não é de planemaneot, por isso
        --altera também o tipo de episódio para o episódio de ORIS associado.
        g_error := 'UPDATE ORIS EPISODE.FLG_EHR';
        pk_alertlog.log_debug(text            => g_error,
                              object_name     => 'PK_MATCH',
                              sub_object_name => 'SET_MATCH_EPISODES_INTERNAL');
        /* <DENORM Fábio> */
        l_rowids := table_varchar();
        ts_episode.upd(flg_ehr_in  => g_episode_flg_ehr_n,
                       flg_ehr_nin => FALSE,
                       where_in    => 'id_epis_type = ' || g_epis_type_oris || '
           AND id_prev_episode = ' || i_episode || '
           AND flg_ehr != ''' || g_episode_flg_ehr_n || '''
           AND EXISTS (SELECT 1
                  FROM episode epis
                 WHERE epis.id_episode = ' || i_episode || '
                   AND epis.flg_ehr = ''' || g_episode_flg_ehr_n || ''')',
                       rows_out    => l_rowids);
    
        g_error := 'PROCESS UPDATE PREV_EPISODE FLG_EHR(2) ';
        t_data_gov_mnt.process_update(i_lang, i_prof, 'EPISODE', l_rowids, o_error, table_varchar('FLG_EHR'));
    
        --Se o paciente do epis¢dio tempor rio for o mesmo do epis¢dio final, nÆo elimina o paciente
        IF nvl(l_patient, 0) != nvl(l_patient_temp, 0)
        THEN
        
            g_error := 'UPDATE VISIT';
            pk_alertlog.log_debug(text            => g_error,
                                  object_name     => 'PK_MATCH',
                                  sub_object_name => 'SET_MATCH_EPISODES_INTERNAL');
            UPDATE visit
               SET id_patient = l_patient
             WHERE id_patient = l_patient_temp;
        
            g_error := 'UPDATE EPISODE ID_PATIENT';
            pk_alertlog.log_debug(text            => g_error,
                                  object_name     => 'PK_MATCH',
                                  sub_object_name => 'SET_MATCH_EPISODES_INTERNAL');
            l_rowids := table_varchar();
            ts_episode.upd(id_patient_in  => l_patient,
                           id_patient_nin => FALSE,
                           where_in       => 'id_patient = ' || l_patient_temp,
                           rows_out       => l_rowids);
            g_error := 'PROCESS UPDATE EPISODE ID_PATIENT';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'EPISODE',
                                          i_rowids       => l_rowids,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('ID_PATIENT'));
        
            -- José Brito 10/07/2009 ALERT-34678  Match integration between ALERT clinical/non-clinical
            --IF NOT set_match_all_pat_internal(i_lang, i_prof, l_patient, l_patient_temp, l_flg_unknown, o_error)
            --THEN
            --    RAISE g_exception;
            --END IF;
        
        END IF;
        --
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN pk_diagnosis.e_primary_diag_exception THEN
            RAISE pk_diagnosis.e_primary_diag_exception;
        WHEN l_matchepisode_exception THEN
            --o_error := pk_message.get_message(i_lang, 'MATCH_EPISODE_M002');
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang,
                                   'T_COMMON_ERROR',
                                   pk_message.get_message(i_lang, 'MATCH_EPISODE_M002'),
                                   g_error,
                                   'ALERT',
                                   'PK_MATCH',
                                   'SET_MATCH_EPISODES_INTERNAL',
                                   NULL,
                                   'U');
            
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- José Brito 10/07/2009 ALERT-34678  Match integration between ALERT clinical/non-clinical
                --pk_utils.undo_changes;
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MATCH',
                                              'SET_MATCH_EPISODES_INTERNAL',
                                              o_error);
            -- José Brito 10/07/2009 ALERT-34678  Match integration between ALERT clinical/non-clinical
            --pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_match_episodes_internal;

    /**********************************************************************************************
    * SET_MATCH_EPISODES_INTERNAL            Match function
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_episode_temp                  Temporary episode
    * @param i_episode                       Episode identifier
    * @param i_transaction_id                remote transaction identifier
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                ??
    * @version                               ??
    * @since                                 ??
    **********************************************************************************************/
    FUNCTION set_match_episodes
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode_temp IN episode.id_episode%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_err_msg_diag   sys_message.desc_message%TYPE;
        l_transaction_id VARCHAR2(4000);
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(NULL, i_prof);
    
        l_err_msg_diag := pk_message.get_message(i_lang, 'MATCH_EPISODE_M003');
    
        g_error := 'CALL SET_MATCH_EPISODES_INTERNAL';
        IF NOT set_match_episodes_internal(i_lang           => i_lang,
                                           i_prof           => i_prof,
                                           i_episode_temp   => i_episode_temp,
                                           i_episode        => i_episode,
                                           i_transaction_id => l_transaction_id,
                                           o_error          => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        -- José Brito 10/07/2009 ALERT-34678  Match integration between ALERT clinical/non-clinical
        --COMMIT;
        --pk_episode.update_mv_episodes();
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN pk_diagnosis.e_primary_diag_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              'MATCH_EPISODE_M003',
                                              l_err_msg_diag,
                                              '',
                                              'ALERT',
                                              'PK_MATCH',
                                              'SET_MATCH_CORE',
                                              'D',
                                              o_error);
            pk_utils.undo_changes; --JAVA is making a commit when the DB returns false, so to prevent data lost we need to make a rollback
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MATCH',
                                              'SET_MATCH_EPISODES',
                                              o_error);
            pk_utils.undo_changes; --JAVA is making a commit when the DB returns false, so to prevent data lost we need to make a rollback
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_match_episodes;

    FUNCTION test_match_episodes
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode_temp IN episode.id_episode%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_transaction_id VARCHAR2(4000);
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(NULL, i_prof);
    
        g_error := 'CALL SET_MATCH_EPISODES_INTERNAL';
        IF NOT set_match_episodes_internal(i_lang           => i_lang,
                                           i_prof           => i_prof,
                                           i_episode_temp   => i_episode_temp,
                                           i_episode        => i_episode,
                                           i_transaction_id => l_transaction_id,
                                           o_error          => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'MATCH OK';
        pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
        ROLLBACK;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MATCH',
                                              'TEST_MATCH_EPISODES',
                                              o_error);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END test_match_episodes;

    FUNCTION set_match_oris
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode_temp IN episode.id_episode%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_patient      IN patient.id_patient%TYPE,
        i_patient_temp IN patient.id_patient%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:  Esta função faz o "match" entre dois episódios relacionados para as
                          tabelas específicas do ORIS.
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                        I_PROF - ID do médico cirurgião que está a aceder à grelha
                                I_EPISODE_TEMP - ID do episódio actual (temporário)
                        I_EPISODE - ID do episódio relacionado (final)
                        I_PATIENT - ID do paciente "final"
                        I_PATIENT_TEMP - ID do paciente temporário
                        SAIDA:  O_ERROR - erro
        
          CRIAÇÃO: RB 2007/01/16
        
        *********************************************************************************/
    
        CURSOR c_surg_rec IS
            SELECT ssr.id_schedule_sr,
                   ssr.id_prof_team,
                   ssr.id_patient,
                   ssr.flg_pat_status,
                   ssr.flg_state,
                   ssr.flg_surg_nat,
                   ssr.flg_surg_type,
                   ssr.flg_urgency,
                   ssr.id_anesthesia_type,
                   ssr.id_clinical_service,
                   ssr.notes,
                   ssr.id_prof_cancel,
                   ssr.dt_cancel_tstz,
                   ssr.notes_cancel,
                   ssr.id_institution,
                   ssr.flg_priority,
                   ssr.flg_sr_proc,
                   ssr.dt_flg_sr_proc
              FROM sr_surgery_record ssr
             WHERE ssr.id_episode = i_episode_temp;
    
        CURSOR c_sched IS
            SELECT id_sched_sr_parent,
                   id_schedule,
                   dt_target_tstz,
                   dt_interv_preview_tstz,
                   id_patient,
                   duration,
                   id_diagnosis,
                   id_speciality,
                   flg_status,
                   flg_sched,
                   id_dept_dest,
                   prev_recovery_time,
                   id_sr_cancel_reason,
                   dt_cancel_tstz,
                   id_prof_cancel,
                   notes_cancel,
                   id_prof_reg,
                   id_institution,
                   id_waiting_list,
                   flg_temporary,
                   icu,
                   notes,
                   adm_needed
              FROM schedule_sr
             WHERE id_episode = i_episode_temp;
    
        CURSOR c_prof IS
            SELECT id_sr_prof_team_det
              FROM sr_prof_team_det d
             WHERE id_episode = i_episode_temp
               AND NOT EXISTS (SELECT 1
                      FROM sr_prof_team_det d1
                     WHERE d1.id_episode = i_episode
                       AND d1.id_professional = d.id_professional);
    
        CURSOR c_prof_context IS
            SELECT id_sr_prof_team_det
              FROM sr_prof_team_det d
             WHERE id_episode_context = i_episode_temp
               AND NOT EXISTS (SELECT 1
                      FROM sr_prof_team_det d1
                     WHERE d1.id_episode_context = i_episode
                       AND d1.id_professional = d.id_professional);
    
        CURSOR c_prof_hist IS
            SELECT id_sr_prof_team_det_hist
              FROM sr_prof_team_det_hist d
             WHERE id_episode = i_episode_temp
               AND NOT EXISTS (SELECT 1
                      FROM sr_prof_team_det_hist d1
                     WHERE d1.id_episode = i_episode
                       AND d1.id_professional = d.id_professional);
    
        CURSOR c_prof_context_hist IS
            SELECT id_sr_prof_team_det_hist
              FROM sr_prof_team_det_hist d
             WHERE id_episode_context = i_episode_temp
               AND NOT EXISTS (SELECT 1
                      FROM sr_prof_team_det_hist d1
                     WHERE d1.id_episode_context = i_episode
                       AND d1.id_professional = d.id_professional);
    
        l_num PLS_INTEGER;
    
        l_rows_upd_ssr   table_varchar;
        l_rows_upd_ei    table_varchar;
        l_id_schedule_sr schedule_sr.id_schedule_sr%TYPE;
        /*        l_rows_upd_ssr3 table_varchar;
        l_rows_upd_ssr4 table_varchar;*/
        l_rowids_ssr  table_varchar := table_varchar();
        l_rowids      table_varchar;
        l_num_consent PLS_INTEGER;
    
        l_schedule_sr_epis      schedule_sr.id_schedule_sr%TYPE;
        l_schedule_sr_epis_temp schedule_sr.id_schedule_sr%TYPE;
    
    BEGIN
    
        --Actualiza o episódio das intervenções cirúrgicas que não estejam duplicadas
        g_error := 'UPDATE SR_EPIS_INTERV_HIST';
        UPDATE sr_epis_interv_hist seih
           SET seih.id_episode = i_episode
         WHERE seih.id_episode = i_episode_temp
           AND NOT EXISTS (SELECT 1
                  FROM sr_epis_interv_hist seih2
                 WHERE seih2.id_episode = i_episode
                   AND seih2.id_sr_intervention = seih.id_sr_intervention);
    
        g_error := 'UPDATE SR_EPIS_INTERV_HIST (id_episode_context)';
        UPDATE sr_epis_interv_hist seih
           SET seih.id_episode_context = i_episode
         WHERE seih.id_episode_context = i_episode_temp
           AND NOT EXISTS (SELECT 1
                  FROM sr_epis_interv_hist seih2
                 WHERE seih2.id_episode_context = i_episode
                   AND seih2.id_sr_intervention = seih.id_sr_intervention);
    
        --
        g_error := 'DELETE SR_EPIS_INTERV_HIST';
        DELETE FROM sr_epis_interv_hist
         WHERE id_episode = i_episode_temp;
    
        g_error := 'DELETE SR_EPIS_INTERV_HIST (id_episode_context)';
        DELETE FROM sr_epis_interv_hist
         WHERE id_episode_context = i_episode_temp;
    
        --Actualiza o episódio das intervenções cirúrgicas que não estejam duplicadas
        g_error := 'UPDATE SR_EPIS_INTERV';
        UPDATE sr_epis_interv ei
           SET ei.id_episode = i_episode
         WHERE ei.id_episode = i_episode_temp
           AND NOT EXISTS (SELECT 1
                  FROM sr_epis_interv ei2
                 WHERE ei2.id_episode = i_episode
                   AND ei2.id_sr_intervention = ei.id_sr_intervention);
        g_error := 'UPDATE SR_EPIS_INTERV (id_episode_context)';
        UPDATE sr_epis_interv ei
           SET ei.id_episode_context = i_episode
         WHERE ei.id_episode_context = i_episode_temp
           AND NOT EXISTS (SELECT 1
                  FROM sr_epis_interv ei2
                 WHERE ei2.id_episode_context = i_episode
                   AND ei2.id_sr_intervention = ei.id_sr_intervention);
    
        --As internveções cirúrgicas ainda existentes no episódio temporário é porque estão duplicadas,
        --  por isso elimina-as.
        g_error := 'DELETE SR_EPIS_INTERV';
        DELETE FROM sr_epis_interv
         WHERE id_episode = i_episode_temp;
    
        g_error := 'DELETE SR_EPIS_INTERV (id_episode_context)';
        DELETE FROM sr_epis_interv
         WHERE id_episode_context = i_episode_temp;
    
        --Actualiza o episódio das descrições das intervenções cirúrgicas que não estejam duplicadas
        g_error := 'SR_EPIS_INTERV_DESC';
        UPDATE sr_epis_interv_desc ei
           SET ei.id_episode = i_episode
         WHERE ei.id_episode = i_episode_temp
           AND NOT EXISTS (SELECT 1
                  FROM sr_epis_interv_desc ei2
                 WHERE ei2.id_episode = i_episode
                   AND ei2.id_sr_intervention = ei.id_sr_intervention);
    
        UPDATE sr_epis_interv_desc ei
           SET ei.id_episode_context = i_episode
         WHERE ei.id_episode_context = i_episode_temp
           AND NOT EXISTS (SELECT 1
                  FROM sr_epis_interv_desc ei2
                 WHERE ei2.id_episode_context = i_episode
                   AND ei2.id_sr_intervention = ei.id_sr_intervention);
    
        --As descrições das internveções cirúrgicas ainda existentes no episódio temporário é porque estão duplicadas,
        --  por isso elimina-as.
        g_error := 'DELETE SR_EPIS_INTERV_DESC ';
        DELETE FROM sr_epis_interv_desc
         WHERE id_episode = i_episode_temp;
    
        g_error := 'DELETE SR_EPIS_INTERV_DESC (id_episode_context)';
        DELETE FROM sr_epis_interv_desc
         WHERE id_episode_context = i_episode_temp;
    
        -- MATCH Surgery Episode Status
        g_error := 'CALL TO pk_sr_visit.set_match_epis_status';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_sr_visit.set_match_epis_status(i_lang           => i_lang,
                                                 i_prof           => i_prof,
                                                 i_id_episode_old => i_episode_temp,
                                                 i_id_episode_new => i_episode,
                                                 o_error          => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'UPDATE SR_POSIT_REQ';
        UPDATE sr_posit_req
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        g_error := 'UPDATE SR_POSIT_REQ (id_episode_context)';
        UPDATE sr_posit_req
           SET id_episode_context = i_episode
         WHERE id_episode_context = i_episode_temp;
    
        g_error := 'LOOP SR_PROF_TEAM_DET';
        --Para não duplicar profissionais, que já estejam registados no episódio final, apenas passamos do
        --  episódio temporário para o final os profissionais que ainda não existam
        FOR i IN c_prof
        LOOP
            g_error := 'UPDATE SR_PROF_TEAM_DET';
            UPDATE sr_prof_team_det
               SET id_episode = i_episode
             WHERE id_sr_prof_team_det = i.id_sr_prof_team_det;
        
        END LOOP;
        g_error := 'LOOP SR_PROF_TEAM_DET_CONTEXT';
        FOR j IN c_prof_context
        LOOP
            g_error := 'UPDATE SR_PROF_TEAM_DET (id_episode_context) ';
            UPDATE sr_prof_team_det
               SET id_episode_context = i_episode
             WHERE id_sr_prof_team_det = j.id_sr_prof_team_det;
        END LOOP;
        --hist
        FOR i IN c_prof_hist
        LOOP
            g_error := 'UPDATE SR_PROF_TEAM_DET_hist';
            UPDATE sr_prof_team_det_hist
               SET id_episode = i_episode
             WHERE id_sr_prof_team_det_hist = i.id_sr_prof_team_det_hist;
        
        END LOOP;
        g_error := 'LOOP SR_PROF_TEAM_DET_CONTEXT_hist';
        FOR j IN c_prof_context_hist
        LOOP
            g_error := 'UPDATE SR_PROF_TEAM_DET (id_episode_context) ';
            UPDATE sr_prof_team_det_hist
               SET id_episode_context = i_episode
             WHERE id_sr_prof_team_det_hist = j.id_sr_prof_team_det_hist;
        END LOOP;
        --
    
        g_error := 'DELETE SR_PROF_TEAM_DET';
        DELETE FROM sr_prof_team_det
         WHERE id_episode = i_episode_temp;
    
        g_error := 'DELETE SR_PROF_TEAM_DET (id_episode_context) ';
        DELETE FROM sr_prof_team_det
         WHERE id_episode_context = i_episode_temp;
        --hist
        g_error := 'DELETE SR_PROF_TEAM_DET_hist';
        DELETE FROM sr_prof_team_det_hist
         WHERE id_episode = i_episode_temp;
    
        g_error := 'DELETE SR_PROF_TEAM_DET_hist (id_episode_context) ';
        DELETE FROM sr_prof_team_det_hist
         WHERE id_episode_context = i_episode_temp;
        --
        g_error := 'UPDATE SR_RECEIVE';
        UPDATE sr_receive
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        g_error := 'UPDATE SR_RESERV_REQ';
        UPDATE sr_reserv_req
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        g_error := 'UPDATE SR_RESERV_REQ (id_episode_context) ';
        UPDATE sr_reserv_req
           SET id_episode_context = i_episode
         WHERE id_episode_context = i_episode_temp;
    
        g_error := 'UPDATE SR_ROOM_STATUS';
        UPDATE sr_room_status
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        g_error := 'UPDATE SR_SURGERY_TIME_DET';
        UPDATE sr_surgery_time_det
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        g_error := 'Fetch id_schedule_sr from episode:' || i_episode;
        BEGIN
            SELECT sr.id_schedule_sr
              INTO l_schedule_sr_epis
              FROM schedule_sr sr
             WHERE sr.id_episode = i_episode;
        EXCEPTION
            WHEN no_data_found THEN
                l_schedule_sr_epis := NULL;
        END;
    
        g_error := 'Fetch id_schedule_sr from episode_temp:' || i_episode_temp;
        BEGIN
            SELECT sr.id_schedule_sr
              INTO l_schedule_sr_epis_temp
              FROM schedule_sr sr
             WHERE sr.id_episode = i_episode_temp;
        EXCEPTION
            WHEN no_data_found THEN
                l_schedule_sr_epis_temp := NULL;
        END;
    
        g_error := 'SELECT SR_CONSENT';
        --match the sr_consent.
        --if there's an active consent record in the temporary episode, the consent records of the episode should be
        --updated for outdated status
        SELECT COUNT(*)
          INTO l_num_consent
          FROM sr_consent sc
         WHERE sc.id_schedule_sr = l_schedule_sr_epis_temp
           AND sc.flg_status = pk_alert_constant.g_active;
    
        -- we've in maximum one record with active status for each episode
        IF l_num_consent > 0
        THEN
            g_error := 'UPDATE SR_CONSENT';
            UPDATE sr_consent sc
               SET sc.flg_status = pk_alert_constant.g_outdated
             WHERE sc.id_schedule_sr = l_schedule_sr_epis;
        END IF;
        g_error := 'UPDATE  SR_CONSENT (id_schedule_sr) ';
        UPDATE sr_consent sc
           SET sc.id_schedule_sr = l_schedule_sr_epis
         WHERE sc.id_schedule_sr = l_schedule_sr_epis_temp;
    
        IF l_schedule_sr_epis_temp IS NOT NULL
        THEN
            g_error  := 'UPDATE sr_pos_schedule';
            l_rowids := table_varchar();
            ts_sr_pos_schedule.upd(id_schedule_sr_in => l_schedule_sr_epis,
                                   where_in          => 'id_schedule_sr = ' || l_schedule_sr_epis_temp,
                                   rows_out          => l_rowids);
        
            IF l_rowids.count > 0
            THEN
                g_error := 'PROCESS UPDATE sr_pos_schedule';
                t_data_gov_mnt.process_update(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_table_name   => 'SR_POS_SCHEDULE',
                                              i_rowids       => l_rowids,
                                              o_error        => o_error,
                                              i_list_columns => table_varchar('ID_SCHEDULE_SR'));
            END IF;
        
            g_error  := 'UPDATE sr_pos_schedule_hist';
            l_rowids := table_varchar();
            ts_sr_pos_schedule_hist.upd(id_schedule_sr_in => l_schedule_sr_epis,
                                        where_in          => 'id_schedule_sr = ' || l_schedule_sr_epis_temp,
                                        rows_out          => l_rowids);
        
            IF l_rowids.count > 0
            THEN
                g_error := 'PROCESS UPDATE sr_pos_schedule_hist';
                t_data_gov_mnt.process_update(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_table_name   => 'SR_POS_SCHEDULE_HIST',
                                              i_rowids       => l_rowids,
                                              o_error        => o_error,
                                              i_list_columns => table_varchar('ID_SCHEDULE_SR'));
            END IF;
        END IF;
        --Tabelas que não podem ter registos repetidos para o episódio
        g_error := 'SR_CHKLIST_DET';
        --Na tabela SR_CHKLIST_DET, só pode haver um registo com o mesmo id_episode e id_sr_chklist.
        -- Assim, vamos actualizar no episódio final, os dados do episódio temporário.
    
        g_error := 'SR_SURGERY_RECORD';
        --Só pode haver um registo na tabela SR_SURGERY_RECORD para cada episódio. Assim, se o registo já existir
        -- vai ser actualizado
        SELECT COUNT(*)
          INTO l_num
          FROM sr_surgery_record
         WHERE id_episode = i_episode;
    
        IF l_num > 0
        THEN
            FOR i IN c_surg_rec
            LOOP
                g_error := 'DELETE SR_SURGERY_RECORD';
                /* DELETE FROM sr_surgery_record
                WHERE id_schedule_sr = (SELECT id_schedule_sr
                                          FROM schedule_sr
                                         WHERE id_episode = i_episode_temp);*/
                ts_sr_surgery_record.del_by(where_clause_in => 'id_episode = ' || i_episode_temp);
            
                g_error := 'UPDATE SR_SURGERY_RECORD - 1';
                /*  UPDATE sr_surgery_record
                               SET id_prof_team        = i.id_prof_team,
                                   flg_pat_status      = i.flg_pat_status,
                                   flg_state           = i.flg_state,
                                   flg_surg_nat        = i.flg_surg_nat,
                                   flg_surg_type       = i.flg_surg_type,
                                   flg_urgency         = i.flg_urgency,
                                   id_anesthesia_type  = i.id_anesthesia_type,
                                   id_clinical_service = i.id_clinical_service,
                                   notes               = i.notes,
                                   id_prof_cancel      = i.id_prof_cancel,
                                   dt_cancel_tstz = i.dt_cancel_tstz,
                                   notes_cancel   = i.notes_cancel,
                                   id_institution = i.id_institution
                             WHERE id_schedule_sr = (SELECT id_schedule_sr
                                                       FROM schedule_sr
                                                      WHERE id_episode = i_episode);
                
                */
                /*  ts_sr_surgery_record.upd(id_prof_team_in        => i.id_prof_team,
                flg_pat_status_in      => i.flg_pat_status,
                flg_state_in           => i.flg_state,
                flg_surg_nat_in        => i.flg_surg_nat,
                flg_surg_type_in       => i.flg_surg_type,
                flg_urgency_in         => i.flg_urgency,
                id_anesthesia_type_in  => i.id_anesthesia_type,
                id_clinical_service_in => i.id_clinical_service,
                notes_in               => i.notes,
                id_prof_cancel_in      => i.id_prof_cancel,
                dt_cancel_tstz_in      => i.dt_cancel_tstz,
                notes_cancel_in        => i.notes_cancel,
                id_institution_in      => i.id_institution,
                id_episode_in          => i_episode,
                
                where_in => 'id_schedule_sr = (SELECT id_schedule_sr
                  FROM schedule_sr
                 WHERE id_episode = ' ||
                            i_episode || ')',
                rows_out => l_rows_upd_ssr);*/
            
                ts_sr_surgery_record.upd(id_prof_team_in        => i.id_prof_team,
                                         flg_pat_status_in      => i.flg_pat_status,
                                         flg_state_in           => i.flg_state,
                                         flg_surg_nat_in        => i.flg_surg_nat,
                                         flg_surg_type_in       => i.flg_surg_type,
                                         flg_urgency_in         => i.flg_urgency,
                                         id_anesthesia_type_in  => i.id_anesthesia_type,
                                         id_clinical_service_in => i.id_clinical_service,
                                         notes_in               => i.notes,
                                         id_prof_cancel_in      => i.id_prof_cancel,
                                         dt_cancel_tstz_in      => i.dt_cancel_tstz,
                                         notes_cancel_in        => i.notes_cancel,
                                         id_institution_in      => i.id_institution,
                                         id_episode_in          => i_episode,
                                         flg_priority_in        => i.flg_priority,
                                         flg_sr_proc_in         => i.flg_sr_proc,
                                         dt_flg_sr_proc_in      => i.dt_flg_sr_proc,
                                         where_in               => 'id_episode = ' || i_episode,
                                         rows_out               => l_rows_upd_ssr);
                g_error := 'UPDATE EPIS_INFO SR_SURGERY_RECORD - 1';
                ts_epis_info.upd(id_episode_in      => i_episode,
                                 flg_pat_status_in  => i.flg_pat_status,
                                 flg_pat_status_nin => FALSE,
                                 rows_out           => l_rows_upd_ei);
            
            END LOOP;
        ELSE
        
            /*         UPDATE sr_surgery_record
              SET id_schedule_sr = (SELECT id_schedule_sr
                                      FROM schedule_sr
                                     WHERE id_episode = i_episode)
            WHERE id_schedule_sr = (SELECT id_schedule_sr
                                      FROM schedule_sr
                                     WHERE id_episode = i_episode_temp);*/
            /*
                UPDATE sr_surgery_record
                   SET id_patient = i_patient
                 WHERE id_patient = i_patient_temp;
            */
        
            g_error := 'UPDATE SR_SURGERY_RECORD - 2';
            BEGIN
                SELECT id_schedule_sr
                  INTO l_id_schedule_sr
                  FROM schedule_sr
                 WHERE id_episode = i_episode;
                g_error := 'UPDATE  SR_SURGERY_RECORD -EPISODE';
                ts_sr_surgery_record.upd(id_episode_in => i_episode,
                                         where_in      => 'id_episode = ' || i_episode_temp,
                                         rows_out      => l_rows_upd_ssr);
            
                g_error := 'UPDATE  SR_SURGERY_RECORD -PATIENT';
                ts_sr_surgery_record.upd(id_patient_in => i_patient,
                                         where_in      => 'id_patient = ' || i_patient_temp,
                                         rows_out      => l_rows_upd_ssr);
            
            EXCEPTION
                WHEN no_data_found THEN
                    RETURN TRUE;
            END;
        
        END IF;
    
        g_error := 't_data_gov_mnt.process_update ts_sr_surgery_record';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'SR_SURGERY_RECORD',
                                      i_rowids     => l_rows_upd_ssr,
                                      o_error      => o_error);
    
        --O registo na tabela SCHEDULE_SR existe de certeza e, como só pode haver um para cada episódio, temos
        --  que actualizar o final pelo provisório
        FOR i IN c_sched
        LOOP
            g_error := 'UPDATE EPIS_INFO SR_SURGERY_RECORD - episode';
            ts_epis_info.upd(id_episode_in      => i_episode_temp,
                             id_schedule_sr_in  => NULL,
                             id_schedule_sr_nin => FALSE,
                             rows_out           => l_rows_upd_ei);
        
            SELECT id_schedule_sr
              INTO l_id_schedule_sr
              FROM schedule_sr
             WHERE id_episode = i_episode_temp;
        
            g_error := 'DELETE sr_consent';
            DELETE FROM sr_consent sc
             WHERE sc.id_schedule_sr = l_id_schedule_sr;
        
            --Só pode haver um registo da schedule_sr, por isso, elimina o do episódio temporário
            g_error  := 'DELETE SCHEDULE_SR';
            l_rowids := table_varchar();
            ts_schedule_sr.del_sr_sched_epis_fk(id_episode_in => i_episode_temp, rows_out => l_rowids);
        
            IF l_rowids.count > 0
            THEN
                g_error := 'PROCESS DELETE SCHEDULE_SR';
                t_data_gov_mnt.process_delete(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'SCHEDULE_SR',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            END IF;
        
            g_error  := 'UPDATE SCHEDULE_SR';
            l_rowids := table_varchar();
            ts_schedule_sr.upd(id_sched_sr_parent_in      => i.id_sched_sr_parent,
                               id_sched_sr_parent_nin     => FALSE,
                               id_schedule_in             => i.id_schedule,
                               id_schedule_nin            => FALSE,
                               id_patient_in              => i_patient,
                               id_patient_nin             => FALSE,
                               duration_in                => i.duration,
                               duration_nin               => FALSE,
                               id_diagnosis_in            => i.id_diagnosis,
                               id_diagnosis_nin           => FALSE,
                               id_speciality_in           => i.id_speciality,
                               id_speciality_nin          => FALSE,
                               flg_status_in              => i.flg_status,
                               flg_status_nin             => FALSE,
                               flg_sched_in               => i.flg_sched,
                               flg_sched_nin              => FALSE,
                               id_dept_dest_in            => i.id_dept_dest,
                               id_dept_dest_nin           => FALSE,
                               prev_recovery_time_in      => i.prev_recovery_time,
                               prev_recovery_time_nin     => FALSE,
                               id_sr_cancel_reason_in     => i.id_sr_cancel_reason,
                               id_sr_cancel_reason_nin    => FALSE,
                               id_prof_cancel_in          => i.id_prof_cancel,
                               id_prof_cancel_nin         => FALSE,
                               notes_cancel_in            => i.notes_cancel,
                               notes_cancel_nin           => FALSE,
                               id_prof_reg_in             => i.id_prof_reg,
                               id_prof_reg_nin            => FALSE,
                               id_institution_in          => i.id_institution,
                               id_institution_nin         => FALSE,
                               dt_target_tstz_in          => i.dt_target_tstz,
                               dt_target_tstz_nin         => FALSE,
                               dt_interv_preview_tstz_in  => i.dt_interv_preview_tstz,
                               dt_interv_preview_tstz_nin => FALSE,
                               dt_cancel_tstz_in          => i.dt_cancel_tstz,
                               dt_cancel_tstz_nin         => FALSE,
                               id_waiting_list_in         => i.id_waiting_list,
                               id_waiting_list_nin        => FALSE,
                               flg_temporary_in           => i.flg_temporary,
                               flg_temporary_nin          => FALSE,
                               icu_in                     => i.icu,
                               icu_nin                    => FALSE,
                               notes_in                   => i.notes,
                               notes_nin                  => FALSE,
                               adm_needed_in              => i.adm_needed,
                               adm_needed_nin             => FALSE,
                               where_in                   => 'id_episode = ' || i_episode,
                               rows_out                   => l_rowids);
        
            l_rowids_ssr := l_rowids_ssr MULTISET UNION l_rowids;
        
        END LOOP;
    
        IF l_rowids_ssr.count > 0
        THEN
            g_error := 'PROCESS UPDATE schedule_sr EPISODE';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'SCHEDULE_SR',
                                          i_rowids     => l_rowids_ssr,
                                          o_error      => o_error);
        END IF;
    
        --Actualiza todos os agendamentos de forma a substituir o paciente temporário pelo definitivo
        g_error  := 'UPDATE schedule_sr PATIENT';
        l_rowids := table_varchar();
        ts_schedule_sr.upd(id_patient_in => i_patient,
                           where_in      => 'id_patient = ' || i_patient_temp,
                           rows_out      => l_rowids);
    
        --Actualiza todos os agendamentos de forma a substituir o episode temporário pelo definitivo
        g_error  := 'UPDATE schedule_sr id_episode';
        l_rowids := table_varchar();
        ts_schedule_sr.upd(id_episode_in => i_episode,
                           where_in      => 'id_episode = ' || i_episode_temp,
                           rows_out      => l_rowids);
    
        IF l_rowids_ssr.count > 0
        THEN
            g_error := 'PROCESS UPDATE schedule_sr PATIENT';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'SCHEDULE_SR',
                                          i_rowids       => l_rowids_ssr,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('ID_PATIENT'));
        END IF;
    
        -- call approval_match to maintain episodes integrity after match
        g_error := 'CALL pk_sr_approval.approval_match';
        pk_alertlog.log_debug(text => g_error, object_name => 'PK_MATCH', sub_object_name => 'SET_MATCH_ORIS');
        IF NOT pk_sr_approval.approval_match(i_lang         => i_lang,
                                             i_prof         => i_prof,
                                             i_episode_temp => i_episode_temp,
                                             i_episode      => i_episode,
                                             o_error        => o_error)
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
                                              'PK_MATCH',
                                              'SET_MATCH_ORIS',
                                              o_error);
            -- José Brito 10/07/2009 ALERT-34678  Match integration between ALERT clinical/non-clinical
            --pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    FUNCTION set_match_edis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode_temp IN episode.id_episode%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_patient      IN patient.id_patient%TYPE,
        i_patient_temp IN patient.id_patient%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:  Esta função faz o "match" entre dois episódios relacionados para as
                          tabelas específicas do EDIS.
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                        I_PROF - ID do médico cirurgião que está a aceder à grelha
                                I_EPISODE_TEMP - ID do episódio actual (temporário)
                        I_EPISODE - ID do episódio relacionado (final)
                        I_PATIENT - ID do paciente "final"
                        I_PATIENT_TEMP - ID do paciente temporário
                        SAIDA:  O_ERROR - erro
        
          CRIAÇÃO: RB 2007/01/16
        
        *********************************************************************************/
    
        l_count             NUMBER;
        l_id_epis_ext_sys   epis_ext_sys.id_epis_ext_sys%TYPE;
        l_edis_value        epis_ext_sys.value%TYPE;
        l_cod_epis_type_ext epis_ext_sys.cod_epis_type_ext%TYPE;
        l_id_external_sys   NUMBER;
        l_upd_value         VARCHAR2(1); -- 'Y' - is to updt definitive epi with the value from temp epi, otherwise 'N'
        l_id_visit          visit.id_visit%TYPE;
        l_id_patient        patient.id_patient%TYPE;
        l_id_prev_epis_type episode.id_epis_type%TYPE;
    
        l_rowids    table_varchar;
        l_rowids_ei table_varchar;
    BEGIN
        -- GET ID OF EXTERNAL SYSTEM
        l_id_external_sys := pk_sysconfig.get_config('ID_EXTERNAL_SYS', i_prof);
        l_upd_value       := nvl(pk_sysconfig.get_config('TEMP_EPIS_EXT_VALUE', i_prof), 'N');
    
        g_error := 'EPIS_TRIAGE';
        ts_epis_triage.upd(id_episode_in => i_episode,
                           where_in      => 'ID_EPISODE = ' || i_episode_temp,
                           rows_out      => l_rowids);
        g_error := 'PROCESS UPDATE EPIS_TRIAGE';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EPIS_TRIAGE',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        l_rowids := table_varchar();
    
        IF l_upd_value = 'Y'
        THEN
            BEGIN
                SELECT e.value
                  INTO l_edis_value
                  FROM epis_ext_sys e
                 WHERE e.id_episode = i_episode_temp
                   AND e.id_institution = i_prof.institution;
            
                UPDATE epis_ext_sys e
                   SET e.value = l_edis_value
                 WHERE e.id_episode = i_episode;
            EXCEPTION
                WHEN no_data_found THEN
                    NULL;
            END;
        
            l_edis_value := NULL;
        END IF;
    
        -- José Brito 22/02/2010 ALERT-75265
        g_error := 'GET VISIT ID i_episode:' || i_episode;
        SELECT id_visit, id_patient, id_epis_type
          INTO l_id_visit, l_id_patient, l_id_prev_epis_type
          FROM episode
         WHERE id_episode = i_episode;
    
        g_error := 'GET PREV EPISODE i_episode_temp:' || i_episode_temp;
        FOR r IN (SELECT id_episode, id_epis_type
                    FROM episode
                   WHERE id_prev_episode = i_episode_temp)
        LOOP
            g_error := 'UPDATE EPISODE (2) - ' || r.id_episode;
            ts_episode.upd(id_prev_episode_in    => i_episode,
                           id_prev_episode_nin   => FALSE,
                           id_prev_epis_type_in  => l_id_prev_epis_type,
                           id_prev_epis_type_nin => FALSE,
                           id_episode_in         => r.id_episode,
                           rows_out              => l_rowids);
        
            g_error := 'UPDATE EPIS_INFO PREV EPISODE- ' || r.id_episode;
            ts_epis_info.upd(id_episode_in   => r.id_episode,
                             flg_unknown_in  => 'N',
                             flg_unknown_nin => FALSE,
                             rows_out        => l_rowids_ei);
        
            SELECT COUNT(*)
              INTO l_count
              FROM epis_ext_sys
             WHERE id_episode = r.id_episode
               AND id_institution = i_prof.institution;
        
            IF l_count = 0
            THEN
                BEGIN
                    -- get external value from EDIS
                    g_error := 'GET epis_ext_sys i_episode:' || i_episode;
                    SELECT VALUE
                      INTO l_edis_value
                      FROM epis_ext_sys
                     WHERE id_episode = i_episode
                       AND id_institution = i_prof.institution;
                
                    -- generate id
                    SELECT seq_epis_ext_sys.nextval
                      INTO l_id_epis_ext_sys
                      FROM dual;
                
                    -- detect how it must be billed -> normally as URG if originated from EDIS
                    l_cod_epis_type_ext := CASE r.id_epis_type
                                               WHEN 1 THEN
                                                'CON'
                                               WHEN 2 THEN
                                                'URG'
                                               WHEN 5 THEN
                                                CASE nvl(i_episode, -1)
                                                    WHEN -1 THEN
                                                     'INT'
                                                    ELSE
                                                     'URG'
                                                END
                                               WHEN 6 THEN
                                                'INT'
                                               WHEN 4 THEN
                                                'INT'
                                               ELSE
                                                'XXX'
                                           END;
                
                    -- insert mapping of OBS
                    g_error := 'INSERT EPIS_EXT_SYS cod_epis_type_ext:' || l_cod_epis_type_ext;
                    INSERT INTO epis_ext_sys
                        (id_epis_ext_sys,
                         id_external_sys,
                         id_episode,
                         VALUE,
                         id_institution,
                         id_epis_type,
                         cod_epis_type_ext)
                    VALUES
                        (l_id_epis_ext_sys,
                         l_id_external_sys,
                         r.id_episode,
                         l_edis_value,
                         i_prof.institution,
                         r.id_epis_type,
                         l_cod_epis_type_ext);
                EXCEPTION
                    WHEN no_data_found THEN
                        NULL;
                END;
            
            ELSE
                -- José Brito 28/08/2008 Ao dar alta para INP, já é criado um registo na EPIS_EXT_SYS, assim deve ser feito o UPDATE
                -- desse registo.
                BEGIN
                    g_error := 'GET epis_ext_sys i_episode(1):' || i_episode;
                    SELECT VALUE
                      INTO l_edis_value
                      FROM epis_ext_sys
                     WHERE id_episode = i_episode
                       AND id_institution = i_prof.institution;
                
                    l_cod_epis_type_ext := CASE r.id_epis_type
                                               WHEN 1 THEN
                                                'CON'
                                               WHEN 2 THEN
                                                'URG'
                                               WHEN 5 THEN
                                                CASE nvl(i_episode, -1)
                                                    WHEN -1 THEN
                                                     'INT'
                                                    ELSE
                                                     'URG'
                                                END
                                               WHEN 6 THEN
                                                'INT'
                                               WHEN 4 THEN
                                                'INT'
                                               ELSE
                                                'XXX'
                                           END;
                    g_error             := 'UPDATE epis_ext_sys';
                    UPDATE epis_ext_sys ees
                       SET ees.id_external_sys   = l_id_external_sys,
                           ees.value             = nvl(ees.value, l_edis_value),
                           ees.id_institution    = i_prof.institution,
                           ees.id_epis_type      = r.id_epis_type,
                           ees.cod_epis_type_ext = l_cod_epis_type_ext
                     WHERE ees.id_episode = r.id_episode;
                EXCEPTION
                    WHEN no_data_found THEN
                        NULL;
                END;
            END IF;
        END LOOP;
        g_error := 'PROCESS UPDATE EPIS_INFO FLG_UNKNOWN';
        t_data_gov_mnt.process_update(i_lang, i_prof, 'EPIS_INFO', l_rowids_ei, o_error, table_varchar('FLG_UNKNOWN'));
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EPISODE',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        g_error := 'CALL  pk_announced_arrival.match_announced_arrival';
        pk_alertlog.log_debug(text => g_error, object_name => 'PK_MATCH', sub_object_name => 'SET_MATCH_EDIS');
        IF NOT pk_announced_arrival.match_announced_arrival(i_lang, i_prof, i_episode, i_episode_temp, o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL  pk_patient_tracking.match_care_stage';
        pk_alertlog.log_debug(text => g_error, object_name => 'PK_MATCH', sub_object_name => 'SET_MATCH_EDIS');
        IF NOT pk_patient_tracking.match_care_stage(i_lang, i_prof, i_episode, i_episode_temp, o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL pk_complication_core.match_complications';
        pk_alertlog.log_debug(text => g_error, object_name => 'PK_MATCH', sub_object_name => 'SET_MATCH_EDIS');
        IF NOT pk_complication_core.match_complications(i_lang, i_prof, i_episode, i_episode_temp, o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL pk_hand_off_core.set_resp_match';
        pk_alertlog.log_debug(text => g_error, object_name => 'PK_MATCH', sub_object_name => 'SET_MATCH_EDIS');
        IF NOT pk_hand_off_core.set_resp_match(i_lang, i_prof, i_episode, i_episode_temp, o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL pk_episode.set_intake_match';
        pk_alertlog.log_debug(text => g_error, object_name => 'PK_MATCH', sub_object_name => 'SET_MATCH_EDIS');
        IF NOT pk_episode.set_intake_match(i_lang, i_prof, i_episode, i_episode_temp, o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL pk_epis_er_law_api.match_er_ges';
        pk_alertlog.log_debug(text => g_error, object_name => 'PK_MATCH', sub_object_name => 'SET_MATCH_EDIS');
        IF NOT pk_epis_er_law_api.match_er_ges(i_lang, i_prof, i_episode, i_episode_temp, o_error)
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
                                              'PK_MATCH',
                                              'SET_MATCH_EDIS',
                                              o_error);
            -- José Brito 10/07/2009 ALERT-34678  Match integration between ALERT clinical/non-clinical
            --pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    /**********************************************************************************************
    * SET_MATCH_INP                          This function make "match" between related episodes in
    *                                        INPATIENT specific tables
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_episode_temp                  Temporary episode
    * @param i_episode                       Episode identifier
    * @param i_patient_temp                  Temporary patient
    * @param i_patient                       Patient identifier
    * @param i_transaction_id                remote transaction identifier
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Rui Batista
    * @version                               0.1
    * @since                                 2007/01/16
    *
    * @author                                Emilia Taborda
    * @version                               0.2
    * @since                                 2007/02/03
    **********************************************************************************************/
    FUNCTION set_match_inp
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode_temp   IN episode.id_episode%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_patient        IN patient.id_patient%TYPE,
        i_patient_temp   IN patient.id_patient%TYPE,
        i_transaction_id IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rowids         table_varchar := table_varchar();
        l_transaction_id VARCHAR2(4000);
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        -- MATCH INTAKE AND OUTPUT
        g_error := 'CALL TO PK_INP_HIDRICS_PBL.SET_MATCH_HIDRICS';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_inp_hidrics_pbl.set_match_hidrics(i_lang         => i_lang,
                                                    i_prof         => i_prof,
                                                    i_episode_temp => i_episode_temp,
                                                    i_episode      => i_episode,
                                                    i_patient      => i_patient,
                                                    i_patient_temp => i_patient_temp,
                                                    o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        -- MATCH POSITIONING
        g_error := 'CALL TO pk_pbl_inp_positioning.set_new_match_epis';
        pk_alertlog.log_debug(text => g_error, object_name => 'PK_MATCH', sub_object_name => 'SET_MATCH_INP');
        IF NOT pk_pbl_inp_positioning.set_new_match_epis(i_lang         => i_lang,
                                                         i_prof         => i_prof,
                                                         i_episode_temp => i_episode_temp,
                                                         i_episode      => i_episode,
                                                         o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        -- MATCH DISCHARGE SCHEDULE
        g_error := 'CALL TO pk_discharge.set_new_match_epis_ds';
        pk_alertlog.log_debug(text => g_error, object_name => 'PK_MATCH', sub_object_name => 'SET_MATCH_INP');
        IF NOT pk_discharge.set_new_match_epis_ds(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  i_episode_temp => i_episode_temp,
                                                  i_episode      => i_episode,
                                                  o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        -- MATCH BED MANAGEMENT
        g_error := 'CALL PK_BMNG_PBL.SET_MATCH_BMNG';
        pk_alertlog.log_debug(text => g_error, object_name => 'PK_MATCH', sub_object_name => 'SET_MATCH_INP');
        IF NOT pk_bmng_pbl.set_match_bmng(i_lang           => i_lang,
                                          i_prof           => i_prof,
                                          i_episode_temp   => i_episode_temp,
                                          i_episode        => i_episode,
                                          i_patient        => i_patient,
                                          i_patient_temp   => i_patient_temp,
                                          i_transaction_id => l_transaction_id,
                                          o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- MATCH SCHEDULE INPATIENT EPISODES
        g_error := 'CALL pk_inp_episode.SET_MATCH_SCHEDULE_INP';
        pk_alertlog.log_debug(text => g_error, object_name => 'PK_MATCH', sub_object_name => 'SET_MATCH_INP');
        IF NOT pk_inp_episode.set_match_schedule_inp(i_lang         => i_lang,
                                                     i_prof         => i_prof,
                                                     i_episode_temp => i_episode_temp,
                                                     i_episode      => i_episode,
                                                     o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- MATCH TASK TIMELINE
        g_error := 'CALL pk_ea_logic_tasktimeline.SET_EPISODE';
        pk_alertlog.log_debug(text => g_error, object_name => 'PK_MATCH', sub_object_name => 'SET_MATCH_INP');
        IF NOT pk_ea_logic_tasktimeline.set_episode(i_lang         => i_lang,
                                                    i_prof         => i_prof,
                                                    i_episode_temp => i_episode_temp,
                                                    i_episode      => i_episode,
                                                    o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- MATCH Progress notes
        g_error := 'CALL pk_prog_notes_core.set_match_prog_notes';
        pk_alertlog.log_debug(text => g_error, object_name => 'PK_MATCH', sub_object_name => 'SET_MATCH_INP');
        IF NOT pk_prog_notes_core.set_match_prog_notes(i_lang         => i_lang,
                                                       i_prof         => i_prof,
                                                       i_episode_temp => i_episode_temp,
                                                       i_episode      => i_episode,
                                                       o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        -- MATCH scales scores
        g_error := 'CALL TO PK_SCALES_CORE.SET_MATCH_SCALES_EPIS';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_scales_core.set_match_scales_epis(i_lang         => i_lang,
                                                    i_prof         => i_prof,
                                                    i_episode_temp => i_episode_temp,
                                                    i_episode      => i_episode,
                                                    o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        -- Match of EPISODES/PATIENTS in functionality WAITING LIST (ADMISSION and SURGERY REQUEST)
        --
        -- SURGERY REQUEST
        --
        -- NOTE: This is an direct update because framework can't update primary Keys.
        -- This option was validated with Technical architecture team at 08-07-2009
        g_error := 'WTL_EPIS';
        UPDATE wtl_epis we
           SET we.id_episode = i_episode
         WHERE we.id_episode = i_episode_temp;
        --
        g_error  := 'UPDATE WTL_DEP_CLIN_SERV';
        l_rowids := table_varchar();
        ts_wtl_dep_clin_serv.upd(id_episode_in  => i_episode,
                                 id_episode_nin => FALSE,
                                 where_in       => 'id_episode = ' || i_episode_temp,
                                 rows_out       => l_rowids);
    
        g_error := 'PROCESS UPDATE WTL_DEP_CLIN_SERV';
        t_data_gov_mnt.process_update(i_lang,
                                      i_prof,
                                      'WTL_DEP_CLIN_SERV',
                                      l_rowids,
                                      o_error,
                                      table_varchar('ID_EPISODE'));
        --
        g_error  := 'UPDATE WTL_PROF';
        l_rowids := table_varchar();
        ts_wtl_prof.upd(id_episode_in  => i_episode,
                        id_episode_nin => FALSE,
                        where_in       => 'id_episode = ' || i_episode_temp,
                        rows_out       => l_rowids);
    
        g_error := 'PROCESS UPDATE WTL_PROF';
        t_data_gov_mnt.process_update(i_lang, i_prof, 'WTL_PROF', l_rowids, o_error, table_varchar('ID_EPISODE'));
        --
        g_error  := 'UPDATE SR_DANGER_CONT';
        l_rowids := table_varchar();
        ts_sr_danger_cont.upd(id_episode_in  => i_episode,
                              id_episode_nin => FALSE,
                              id_patient_in  => i_patient,
                              id_patient_nin => FALSE,
                              where_in       => 'id_episode = ' || i_episode_temp,
                              rows_out       => l_rowids);
    
        g_error := 'PROCESS UPDATE SR_DANGER_CONT';
        t_data_gov_mnt.process_update(i_lang, i_prof, 'SR_DANGER_CONT', l_rowids, o_error, table_varchar('ID_EPISODE'));
    
        --
        -- MATCH ADMISSION REQUEST
        -- ADM_REQUEST
        g_error  := 'UPDATE ADM_REQUEST (id_dest_episode)';
        l_rowids := table_varchar();
        ts_adm_request.upd(id_dest_episode_in  => i_episode,
                           id_dest_episode_nin => FALSE,
                           where_in            => 'id_dest_episode = ' || i_episode_temp,
                           rows_out            => l_rowids);
        --
        g_error := 'UPDATE ADM_REQUEST (id_upd_episode) ';
        ts_adm_request.upd(id_upd_episode_in  => i_episode,
                           id_upd_episode_nin => FALSE,
                           where_in           => 'id_upd_episode = ' || i_episode_temp,
                           rows_out           => l_rowids);
    
        g_error := 'PROCESS UPDATE ADM_REQUEST';
        t_data_gov_mnt.process_update(i_lang,
                                      i_prof,
                                      'ADM_REQUEST',
                                      l_rowids,
                                      o_error,
                                      table_varchar('ID_UPD_EPISODE', 'ID_DEST_EPISODE'));
        --
        -- ADM_REQUEST_HIST
        g_error  := 'UPDATE ADM_REQUEST_HIST (id_dest_episode) ';
        l_rowids := table_varchar();
        ts_adm_request_hist.upd(id_dest_episode_in  => i_episode,
                                id_dest_episode_nin => FALSE,
                                where_in            => 'id_dest_episode = ' || i_episode_temp,
                                rows_out            => l_rowids);
        --
        g_error := 'UPDATE ADM_REQUEST_HIST (id_upd_episode)';
        ts_adm_request_hist.upd(id_upd_episode_in  => i_episode,
                                id_upd_episode_nin => FALSE,
                                where_in           => 'id_upd_episode = ' || i_episode_temp,
                                rows_out           => l_rowids);
    
        g_error := 'PROCESS UPDATE ADM_REQUEST_HIST';
        t_data_gov_mnt.process_update(i_lang,
                                      i_prof,
                                      'ADM_REQUEST_HIST',
                                      l_rowids,
                                      o_error,
                                      table_varchar('ID_UPD_EPISODE', 'ID_DEST_EPISODE'));
    
        --
        -- MATCH WAITING LIST
        g_error  := 'UPDATE WAITING_LIST';
        l_rowids := table_varchar();
        ts_waiting_list.upd(id_patient_in  => i_patient,
                            id_patient_nin => FALSE,
                            where_in       => 'id_patient = ' || i_patient_temp,
                            rows_out       => l_rowids);
    
        g_error := 'PROCESS UPDATE WAITING_LIST';
        t_data_gov_mnt.process_update(i_lang, i_prof, 'WAITING_LIST', l_rowids, o_error, table_varchar('ID_PATIENT'));
        --
        g_error  := 'UPDATE WAITING_LIST_HIST';
        l_rowids := table_varchar();
        ts_waiting_list_hist.upd(id_patient_in  => i_patient,
                                 id_patient_nin => FALSE,
                                 where_in       => 'id_patient = ' || i_patient_temp,
                                 rows_out       => l_rowids);
    
        g_error := 'PROCESS UPDATE WAITING_LIST_HIST';
        t_data_gov_mnt.process_update(i_lang,
                                      i_prof,
                                      'WAITING_LIST_HIST',
                                      l_rowids,
                                      o_error,
                                      table_varchar('ID_PATIENT'));
        -- END WAITING LIST (ADMISSION and SURGERY REQUEST)
    
        -- Luís Maia 14/04/2008
        ----- EPISÓDIOS DOC_TEMPLATE
        -- Nos episódios é necessário actualizar os registos inseridos na tabela EPIS_DOC_TEMPLATE, de forma a associar ao paciente definitivo os registos efectuados
        -- pelos profissionais ao paciente quando este ainda se tratava de um paciente temporário.
    
        g_error := 'UPDATE EPIS_DOC_TEMPLATE';
        UPDATE epis_doc_template
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MATCH',
                                              'SET_MATCH_INP',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    FUNCTION set_match_core
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode_temp IN episode.id_episode%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_patient      IN patient.id_patient%TYPE,
        i_patient_temp IN patient.id_patient%TYPE,
        i_flg_unknown  IN epis_info.flg_unknown%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:  Esta função faz o "match" entre dois episódios relacionados para as
                          tabelas específicas do CORE.
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                        I_PROF - ID do médico cirurgião que está a aceder à grelha
                                I_EPISODE_TEMP - ID do episódio actual (temporário)
                        I_EPISODE - ID do episódio relacionado (final)
                        I_PATIENT - ID do paciente "final"
                        I_PATIENT_TEMP - ID do paciente temporário
                        SAIDA:  O_ERROR - erro
        
          CRIAÇÃO: RB 2007/01/16
        
        *********************************************************************************/
    
        l_num PLS_INTEGER;
    
        l_rowids_aux     table_varchar;
        l_rowids_m_u     table_varchar := table_varchar();
        l_ied_rowids_upd table_varchar;
        l_iei_rowids_upd table_varchar;
        l_rowids_ip      table_varchar;
    
        l_rowids_upd1   table_varchar := table_varchar();
        l_rowids_upd1_5 table_varchar := table_varchar();
        l_rowids_upd2   table_varchar := table_varchar();
        l_rowids_upd3   table_varchar := table_varchar();
        l_rowids_upd4   table_varchar := table_varchar();
        l_rowids_upd5   table_varchar := table_varchar();
        l_rowids_upd6   table_varchar := table_varchar();
        l_rowids_upd7   table_varchar := table_varchar();
        l_rowids_upd8   table_varchar := table_varchar();
        l_rowids_upd9   table_varchar := table_varchar();
        l_rowids_upd10  table_varchar := table_varchar();
        l_rowids_upd11  table_varchar := table_varchar();
        l_rowids_upd12  table_varchar := table_varchar();
        l_rowids_upd13  table_varchar := table_varchar();
        l_rowids_upd14  table_varchar := table_varchar();
        l_rowids_upd15  table_varchar := table_varchar();
        l_rowids_upd16  table_varchar := table_varchar();
    
        l_rowids_phpl     table_varchar;
        l_dt_health_plan  pat_health_plan.dt_health_plan%TYPE;
        l_id_patient      pat_health_plan.id_patient%TYPE;
        l_id_health_plan  pat_health_plan.id_health_plan%TYPE;
        l_num_health_plan pat_health_plan.num_health_plan%TYPE;
        l_flg_status      pat_health_plan.flg_status%TYPE;
        l_barcode         pat_health_plan.barcode%TYPE;
        l_flg_default     pat_health_plan.flg_default%TYPE;
        l_id_institution  pat_health_plan.id_institution%TYPE;
        l_id_episode      pat_health_plan.id_episode%TYPE;
        l_rows            table_varchar := table_varchar();
        l_id              PLS_INTEGER;
    
        -- USED FOR PRES_WARN_READ_NOTES
        --These variables were not used so they will be populated with the values from episode table to avoid multiple queries to the table
        l_episode episode.id_episode%TYPE := i_episode;
        l_patient patient.id_patient%TYPE;
        l_visit   visit.id_visit%TYPE;
    
        l_invalid_vars EXCEPTION;
    
        CURSOR c_episode IS
            SELECT e.id_patient, e.id_visit
              FROM episode e
             WHERE e.id_episode = i_episode;
    
        CURSOR c_hcn IS
            SELECT he.rowid linha, he.id_epis_documentation
              FROM hcn_eval he
             WHERE id_episode = i_episode
               AND pk_date_utils.trunc_insttimezone(i_prof, dt_eval_tstz, NULL) =
                   pk_date_utils.trunc_insttimezone(i_prof, current_timestamp, NULL)
               AND flg_status = 'A'
               AND dt_eval_tstz < (SELECT MAX(dt_eval_tstz)
                                     FROM hcn_eval he2
                                    WHERE he2.id_episode = he.id_episode
                                      AND pk_date_utils.trunc_insttimezone(i_prof, he2.dt_eval_tstz, NULL) =
                                          pk_date_utils.trunc_insttimezone(i_prof, current_timestamp, NULL)
                                      AND he2.flg_status = 'A');
    
        -- denormalization variables
        rows_vsr_out table_varchar;
        e_process_event EXCEPTION;
        l_rowid_tab table_varchar := table_varchar();
    
        l_rowids    table_varchar;
        l_rowidspar table_varchar;
    
        l_num_epis_inst PLS_INTEGER;
    
    BEGIN
    
        g_error := 'OPEN c_episode get episode, visit and patiente vars';
        OPEN c_episode;
        FETCH c_episode
            INTO l_patient, l_visit;
        CLOSE c_episode;
    
        IF l_patient IS NULL
           OR l_visit IS NULL
           OR l_episode IS NULL
        THEN
            RAISE l_invalid_vars;
        END IF;
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL_API_DB.SET_LAB_TEST_MATCH';
        IF NOT pk_lab_tests_external_api_db.set_lab_test_match(i_lang         => i_lang,
                                                               i_prof         => i_prof,
                                                               i_patient      => NULL,
                                                               i_episode      => i_episode,
                                                               i_episode_temp => i_episode_temp,
                                                               o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL PK_EXAMS_EXTERNAL_API_DB.SET_EXAM_MATCH';
        IF NOT pk_exams_external_api_db.set_exam_match(i_lang         => i_lang,
                                                       i_prof         => i_prof,
                                                       i_patient      => NULL,
                                                       i_episode      => i_episode,
                                                       i_episode_temp => i_episode_temp,
                                                       o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL_API_DB.SET_PROCEDURE_MATCH';
        IF NOT pk_procedures_external_api_db.set_procedure_match(i_lang         => i_lang,
                                                                 i_prof         => i_prof,
                                                                 i_patient      => NULL,
                                                                 i_episode      => i_episode,
                                                                 i_episode_temp => i_episode_temp,
                                                                 o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL PK_BP_EXTERNAL_API_DB.SET_BP_MATCH';
        IF NOT pk_bp_external_api_db.set_bp_match(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  i_patient      => NULL,
                                                  i_episode      => i_episode,
                                                  i_episode_temp => i_episode_temp,
                                                  o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'UPDATE CLI_REC_REQ';
        UPDATE cli_rec_req
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        g_error := 'UPDATE CLI_REC_REQ (id_episode_origin) ';
        UPDATE cli_rec_req
           SET id_episode_origin = i_episode
         WHERE id_episode_origin = i_episode_temp;
    
        g_error := 'UPDATE CLI_REC_REQ (id_episode_destination) ';
        UPDATE cli_rec_req
           SET id_episode_destination = i_episode
         WHERE id_episode_destination = i_episode_temp;
    
        g_error := 'UPDATE PHY_DISCHARGE_NOTES';
        UPDATE phy_discharge_notes pdn
           SET pdn.id_episode = i_episode
         WHERE pdn.id_episode = i_episode_temp;
    
        g_error := 'UPDATE PENDING_ISSUES';
        UPDATE pending_issue pi
           SET pi.id_episode = i_episode
         WHERE pi.id_episode = i_episode_temp;
    
        g_error := 'CONSULT_REQ';
    
        l_rowids := NULL;
        ts_consult_req.upd(id_episode_in => i_episode,
                           id_patient_in => i_patient,
                           where_in      => 'id_episode=' || i_episode_temp,
                           rows_out      => l_rowids);
    
        g_error := 't_data_gov_mnt.process_update ts_consult_req';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'CONSULT_REQ',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE', 'ID_PATIENT'));
    
        -- José Brito 29/05/2008
        g_error := 'UPDATE CO_SIGN AND CO_SIGN_HIST';
        pk_alertlog.log_debug(text => g_error, object_name => 'PK_MATCH', sub_object_name => g_error);
        IF NOT pk_co_sign_api.match_co_sign_task(i_lang           => i_lang,
                                                 i_prof           => i_prof,
                                                 i_id_episode     => i_episode_temp,
                                                 i_id_episode_new => i_episode,
                                                 o_error          => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'UPDATE CRITICAL_CARE_READ';
        UPDATE critical_care_read
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        g_error := ' PK_DISCHARGE.SET_MATCH_EPISODE_DISCHARGE';
        pk_alertlog.log_debug(text => g_error, object_name => 'PK_MATCH', sub_object_name => g_error);
        IF NOT pk_discharge.set_match_episode_discharge(i_lang         => i_lang,
                                                        i_prof         => i_prof,
                                                        i_episode_temp => i_episode_temp,
                                                        i_episode      => i_episode,
                                                        o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'UPDATE DISCHARGE_REP_NOTES';
        UPDATE discharge_rep_notes
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        g_error := 'UPDATE EPIS SUPLLIES';
        UPDATE epis_supplies
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        g_error := 'CALL pk_transfer_institution.set_match_transfer_inst';
        pk_alertlog.log_debug(text => g_error, object_name => 'PK_MATCH', sub_object_name => 'SET_MATCH_CORE');
        IF NOT pk_transfer_institution.set_match_transfer_inst(i_lang, i_prof, i_episode, i_episode_temp, o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'UPDATE EPIS_PROF_DCS';
        UPDATE epis_prof_dcs eps
           SET eps.id_episode = i_episode
         WHERE eps.id_episode = i_episode_temp;
    
        g_error := 'UPDATE DISCHARGE_NOTES';
        UPDATE discharge_notes
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        g_error := 'CALL PK_API_PFH_CLINDOC_IN.MATCH_EPISODE';
        pk_alertlog.log_debug(text => g_error, object_name => 'PK_MATCH', sub_object_name => 'SET_MATCH_CORE');
        IF NOT pk_api_pfh_clindoc_in.match_episode(i_lang           => i_lang,
                                                   i_prof           => i_prof,
                                                   i_old_id_patient => nvl(i_patient_temp, i_patient),
                                                   i_new_id_patient => i_patient,
                                                   i_old_id_episode => nvl(i_episode_temp, i_episode),
                                                   i_new_id_episode => i_episode,
                                                   o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error  := 'UPDATE EPIS_ANAMNESIS';
        l_rowids := table_varchar();
        ts_epis_anamnesis.upd(id_episode_in => i_episode,
                              where_in      => 'id_episode = ' || i_episode_temp,
                              rows_out      => l_rowids);
    
        g_error := 't_data_gov_mnt.process_update ts_epis_anamnesis';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPIS_ANAMNESIS',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
    
        g_error := 'UPDATE EPIS_ATTENDING_NOTES';
        UPDATE epis_attending_notes
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        g_error := 'UPDATE EPIS_BODY_PAINTING';
        UPDATE epis_body_painting
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        g_error := 'CALL pk_diagnosis.set_match_diagnosis';
        pk_alertlog.log_debug(text => g_error, object_name => 'PK_MATCH', sub_object_name => 'SET_MATCH_CORE');
        IF NOT pk_diagnosis.set_match_diagnosis(i_lang     => i_lang,
                                                i_prof     => i_prof,
                                                i_new_epis => i_episode,
                                                i_old_epis => i_episode_temp,
                                                o_error    => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'UPDATE EPIS_DIAGRAM';
        UPDATE epis_diagram ed
           SET ed.id_episode = i_episode
         WHERE ed.id_episode = i_episode_temp;
    
        g_error := 'UPDATE EPIS_DOCUMENTATION';
        l_rows  := table_varchar();
        ts_epis_documentation.upd(id_episode_in => i_episode,
                                  where_in      => ' id_episode = ' || i_episode_temp,
                                  rows_out      => l_rows);
    
        g_error := 'UPDATE EPIS_DOCUMENTATION id_episode_context';
        ts_epis_documentation.upd(id_episode_context_in => i_episode,
                                  where_in              => ' id_episode_context = ' || i_episode_temp,
                                  rows_out              => l_rows);
    
        g_error := 'PROCESS UPDATE EPIS_DOCUMENTATION';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPIS_DOCUMENTATION',
                                      i_rowids       => l_rows,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE', 'ID_EPISODE_CONTEXT'));
    
        --After searching in dba_source there are no other references to this table other than this one
        --so this table migh no longer be used but it can still have the update for coherence
        g_error := 'UPDATE EPIS_DRUG_USAGE';
        UPDATE epis_drug_usage
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        g_error := 'UPDATE CRISIS_EPIS';
        UPDATE crisis_epis
           SET id_patient = i_patient
         WHERE id_patient = i_patient_temp;
    
        UPDATE crisis_epis
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        -- José Brito 29/08/2008 MatchCancelados: se o episódio cancelado fôr definitivo, não se elimina o registo na tabela EPISODE
        IF i_flg_unknown <> 'N'
        THEN
            g_error := 'DELETE EPIS_EXT_SYS';
            DELETE FROM epis_ext_sys
             WHERE id_episode = i_episode_temp;
        END IF;
        --  update EPIS_EXT_SYS set id_episode = I_EPISODE where id_episode = I_EPISODE_TEMP;
    
        g_error := 'EPIS_HEALTH_PLAN-PAT_HEALTH_PLAN';
        g_error := 'EPIS_HEALTH_PLAN COUNT';
        SELECT COUNT(*)
          INTO l_num
          FROM epis_health_plan
         WHERE id_episode = i_episode;
    
        -- se episodio definitivo tiver health_plan, ficamos s¢ com os do definitivo
        -- senÆo ficamos com os do temporario
        IF l_num > 0
        THEN
            --apagar plano do epis¢dio
            g_error := 'DELETE EPIS_HEALTH_PLAN ';
            DELETE FROM epis_health_plan
             WHERE id_episode = i_episode_temp;
        ELSE
            --passar APENAS os planos de saúde do episódio temp para o definitivo
            g_error := 'UPDATE EPIS_HEALTH_PLAN (1) ';
            UPDATE epis_health_plan e
               SET id_episode = i_episode
             WHERE id_episode = i_episode_temp;
        END IF;
    
        g_error := 'SELECT EPIS_INSTITUTION';
        BEGIN
            SELECT COUNT(ei.id_epis_institution)
              INTO l_num_epis_inst
              FROM epis_institution ei
             WHERE ei.id_episode = i_episode;
        EXCEPTION
            WHEN no_data_found THEN
                g_error := 'UPDATE EPIS_INSTITUTION';
                UPDATE epis_institution
                   SET id_episode = i_episode
                 WHERE id_episode = i_episode_temp;
        END;
        g_error := 'DELETE EPIS_INSTITUTION';
        DELETE FROM epis_institution
         WHERE id_episode = i_episode_temp;
    
        g_error := 'UPDATE EPIS_OBSERVATION';
        UPDATE epis_observation
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        g_error := 'UPDATE EPIS_OBS_EXAM';
        UPDATE epis_obs_exam
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        g_error := 'UPDATE EPIS_OBS_PHOTO';
        UPDATE epis_obs_photo
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        g_error := 'UPDATE EPIS_PROBLEM';
        UPDATE epis_problem
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        g_error := 'DELETE EPIS_PROF_REC';
        DELETE FROM epis_prof_rec epc
         WHERE epc.id_episode = i_episode_temp
           AND EXISTS (SELECT 0
                  FROM epis_prof_rec epc2
                 WHERE epc2.id_episode = i_episode
                   AND epc2.id_professional = epc.id_professional);
    
        g_error := 'UPDATE  EPIS_PROF_REC';
        UPDATE epis_prof_rec
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        g_error := 'UPDATE EPIS_PROF_RESP';
        UPDATE epis_prof_resp
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        -- ALERT-39320
        l_rowids := table_varchar();
        g_error  := 'UPDATE EPIS_MULTI_PROF_RESP';
        ts_epis_multi_prof_resp.upd(id_episode_in  => i_episode,
                                    id_episode_nin => FALSE,
                                    where_in       => 'id_episode = ' || i_episode_temp,
                                    rows_out       => l_rowids);
    
        g_error := 'PROCESS UPDATE EPIS_MULTI_PROF_RESP';
        t_data_gov_mnt.process_update(i_lang, i_prof, 'EPIS_MULTI_PROF_RESP', l_rowids, o_error);
        l_rowids := table_varchar();
    
        g_error := 'UPDATE EPIS_MULTI_PROFRESP_HIST';
        ts_epis_multi_profresp_hist.upd(id_episode_in  => i_episode,
                                        id_episode_nin => FALSE,
                                        where_in       => 'id_episode = ' || i_episode_temp,
                                        rows_out       => l_rowids);
    
        g_error := 'PROCESS UPDATE EPIS_MULTI_PROFRESP_HIST';
        t_data_gov_mnt.process_update(i_lang, i_prof, 'EPIS_MULTI_PROFRESP_HIST', l_rowids, o_error);
        l_rowids := table_varchar();
    
        g_error := 'UPDATE EPIS_PROTOCOLS';
        UPDATE epis_protocols
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        --Só pode existir um registo por profissional/episódio. Por isso, elimino todos os
        -- registos que não sejam o último de cada profissional.
        g_error := 'DELETE EPIS_PROF_REC';
        DELETE FROM epis_prof_rec a
         WHERE a.id_episode IN (i_episode, i_episode_temp)
           AND EXISTS (SELECT 1
                  FROM epis_prof_rec b
                 WHERE b.id_episode IN (i_episode, i_episode_temp)
                   AND b.id_professional = a.id_professional
                   AND b.dt_last_rec_tstz > a.dt_last_rec_tstz);
    
        g_error := 'UPDATE EPIS_PROF_REC';
        UPDATE epis_prof_rec
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        g_error := 'UPDATE EPIS_READMISSION';
        UPDATE epis_readmission
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        --EPIS_RECOMEND
        l_rows  := table_varchar();
        g_error := 'UPDATE ts_epis_recomend.upd';
        ts_epis_recomend.upd(id_episode_in => i_episode,
                             where_in      => ' id_episode = ' || i_episode_temp,
                             rows_out      => l_rows);
    
        g_error := 'CALL t_data_gov_mnt.process_update';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPIS_RECOMEND',
                                      i_rowids       => l_rows,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
    
        g_error := 'UPDATE EPIS_REVIEW_SYSTEMS';
        UPDATE epis_review_systems
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        g_error  := 'UPDATE MONITORIZATION';
        l_rowids := table_varchar();
        ts_monitorization.upd(id_patient_in  => i_patient,
                              id_patient_nin => FALSE,
                              where_in       => 'id_patient = ' || i_patient_temp,
                              rows_out       => l_rowids);
    
        g_error := 'CALL PROCESS_UPDATE MONITORIZATION';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'MONITORIZATION',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        g_error := 'UPDATE HARVEST';
        /* <DENORM Fábio> */
        l_rowids := table_varchar();
        ts_harvest.upd(id_episode_in  => i_episode,
                       id_episode_nin => FALSE,
                       id_visit_in    => l_visit,
                       id_visit_nin   => FALSE,
                       where_in       => 'id_episode = ' || i_episode_temp,
                       rows_out       => l_rowids);
    
        /* <DENORM Fábio> */
        g_error := 'UPDATE HARVEST (id_episode_write)';
        ts_harvest.upd(id_episode_write_in => i_episode,
                       id_episode_nin      => FALSE,
                       where_in            => 'id_episode_write = ' || i_episode_temp,
                       rows_out            => l_rowids);
    
        g_error := 'PROCESS UPDATE HARVEST';
        t_data_gov_mnt.process_update(i_lang,
                                      i_prof,
                                      'HARVEST',
                                      l_rowids,
                                      o_error,
                                      table_varchar('ID_EPISODE', 'ID_VISIT', 'ID_EPISODE_WRITE'));
    
        g_error := 'UPDATE HARVEST_HIST';
        UPDATE harvest_hist
           SET id_episode = i_episode, id_visit = l_visit
         WHERE id_episode = i_episode_temp;
    
        g_error := 'UPDATE HARVEST_HIST (id_episode_write)';
        UPDATE harvest_hist
           SET id_episode_write = i_episode
         WHERE id_episode_write = i_episode_temp;
    
        g_error := 'UPDATE HEMO_REQ';
        UPDATE hemo_req
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        g_error := 'UPDATE HCN_EVAL';
        UPDATE hcn_eval
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        --Como só a última avaliação HCN por dia, pode estar activa, inactiva as anteriores do dia.
        -- As de dias anteriores não são alteradas pois podem ter sido alocadas a enfermeiros e executadas
        l_rows := NULL;
        FOR i IN c_hcn
        LOOP
            g_error := 'UPDATE HCN_EVAL';
            UPDATE hcn_eval
               SET flg_status = g_inactive, dt_cancel_tstz = g_sysdate_tstz, id_prof_cancel = i_prof.id
             WHERE ROWID = i.linha;
        
            g_error := 'UPDATING EPIS_DOCUMENTATION (HCN)';
            ts_epis_documentation.upd(id_epis_documentation_in => i.id_epis_documentation,
                                      flg_status_in            => g_inactive,
                                      dt_cancel_tstz_in        => g_sysdate_tstz,
                                      id_prof_cancel_in        => i_prof.id,
                                      rows_out                 => l_rows);
        END LOOP;
        g_error := 'CALL t_data_gov_mnt.process_update (HCN)';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPIS_DOCUMENTATION',
                                      i_rowids       => l_rows,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('FLG_STATUS', 'DT_CANCEL_TSTZ', 'ID_PROF_CANCEL'));
    
        g_error := 'UPDATE HCN_PAT_DET';
        UPDATE hcn_pat_det
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        --Apenas o último registo de cada dia pode ficar activo
        g_error := 'UPDATE HCN_PAT_DET FLG_STATUS';
        UPDATE hcn_pat_det a
           SET flg_status = g_inactive
         WHERE a.id_episode = i_episode
           AND a.flg_status = g_active
           AND a.dt_status_tstz <
               (SELECT MAX(b.dt_status_tstz)
                  FROM hcn_pat_det b
                 WHERE b.id_episode = i_episode
                   AND b.flg_status = g_active
                   AND pk_date_utils.trunc_insttimezone(i_prof, b.dt_status_tstz, NULL) =
                       pk_date_utils.trunc_insttimezone(i_prof, a.dt_status_tstz, NULL));
    
        g_error := 'Call set_match_icnp i_episode_temp=' || i_episode_temp || ', i_episode=' || i_episode ||
                   ' , i_patient=' || i_patient || ', i_patient_temp=' || i_patient_temp;
        pk_alertlog.log_debug(text => g_error, object_name => 'PK_MATCH', sub_object_name => 'SET_MATCH_CORE');
        IF NOT set_match_icnp_epis(i_lang         => i_lang,
                                   i_prof         => i_prof,
                                   i_episode_temp => i_episode_temp,
                                   i_episode      => i_episode,
                                   o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
        g_error := 'Call set_match_icnp_pat  i_patient=' || i_patient || ', i_patient_temp=' || i_patient_temp;
        pk_alertlog.log_debug(text => g_error, object_name => 'PK_MATCH', sub_object_name => 'SET_MATCH_CORE');
        IF NOT set_match_icnp_pat(i_lang         => i_lang,
                                  i_prof         => i_prof,
                                  i_patient      => i_patient,
                                  i_patient_temp => i_patient_temp,
                                  o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        -- Nursing Care Plan: NANDA, NIC NOC (by episode)
        g_error := 'Call pk_nnn_core.set_match_episode i_episode=' || i_episode || ', i_episode_temp=' ||
                   i_episode_temp;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_nnn_core.set_match_episode(i_lang         => i_lang,
                                             i_prof         => i_prof,
                                             i_episode_temp => i_episode_temp,
                                             i_episode      => i_episode,
                                             o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        -- Nursing Care Plan: NANDA, NIC NOC (by patient)
        g_error := 'Call pk_nnn_core.set_match_patient i_patient=' || i_patient || ', i_patient_temp=' ||
                   i_patient_temp;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_nnn_core.set_match_patient(i_lang         => i_lang,
                                             i_prof         => i_prof,
                                             i_patient_temp => i_patient_temp,
                                             i_patient      => i_patient,
                                             o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'UPDATE IDENTIFICATION_NOTES';
        UPDATE identification_notes
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        -- INTERV_EVALUATION
        g_error := 'CALL set_match_interv';
        pk_alertlog.log_debug(text => g_error, object_name => 'PK_MATCH', sub_object_name => 'SET_MATCH_CORE');
        IF NOT set_match_interv(i_lang, i_prof, i_episode_temp, i_episode, i_patient, i_patient_temp, o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL set_match_rehab';
        pk_alertlog.log_debug(text => g_error, object_name => 'PK_MATCH', sub_object_name => 'SET_MATCH_CORE');
        IF NOT set_match_rehab(i_lang, i_prof, i_episode_temp, i_episode, i_patient, i_patient_temp, o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        -- Init RowIds Collection
        l_rowids_m_u := table_varchar();
    
        g_error := 'update MONITORIZATION - id_episode';
        ts_monitorization.upd(id_episode_in => i_episode,
                              where_in      => 'id_episode = ' || i_episode_temp,
                              rows_out      => l_rowids_m_u);
    
        g_error := 'update MONITORIZATION - id_episode_origin';
        ts_monitorization.upd(id_episode_origin_in => i_episode,
                              where_in             => 'id_episode_origin = ' || i_episode_temp,
                              rows_out             => l_rowids_m_u);
    
        g_error := 'update MONITORIZATION - id_episode_destination';
        ts_monitorization.upd(id_episode_destination_in => i_episode,
                              where_in                  => 'id_episode_destination = ' || i_episode_temp,
                              rows_out                  => l_rowids_m_u);
    
        g_error := 'update MONITORIZATION - id_prev_episode';
        ts_monitorization.upd(id_prev_episode_in => i_episode,
                              where_in           => 'id_prev_episode = ' || i_episode_temp,
                              rows_out           => l_rowids_m_u);
    
        g_error := 'CALL t_data_gov_mnt.process_update';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'MONITORIZATION',
                                      i_rowids       => l_rowids_m_u,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE',
                                                                      'ID_EPISODE_ORIGIN',
                                                                      'ID_EPISODE_DESTINATION',
                                                                      'ID_PREV_EPISODE'));
    
        g_error := 'UPDATE MOVEMENT';
        /* <DENORM Fábio> */
        l_rowids := table_varchar();
        ts_movement.upd(id_episode_in => i_episode,
                        where_in      => 'id_episode = ' || i_episode_temp,
                        rows_out      => l_rowids);
    
        g_error := 'UPDATE MOVEMENT (id_episode_write)';
        ts_movement.upd(id_episode_write_in => i_episode,
                        where_in            => 'id_episode_write = ' || i_episode_temp,
                        rows_out            => l_rowids);
    
        g_error := 'PROCESS UPDATE MOVEMENT';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'MOVEMENT',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE', 'ID_EPISODE_WRITE'));
    
        g_error := 'Call set_match_nurse i_episode_temp=' || i_episode_temp || ', i_episode=' || i_episode ||
                   ', i_patient=' || i_patient || ', i_patient_temp=' || i_patient_temp;
        pk_alertlog.log_debug(text => g_error, object_name => 'PK_MATCH', sub_object_name => 'SET_MATCH_CORE');
        IF NOT set_match_nurse_epis(i_lang         => i_lang,
                                    i_prof         => i_prof,
                                    i_episode_temp => i_episode_temp,
                                    i_episode      => i_episode,
                                    o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'Call set_match_nurse_pat i_episode_temp=' || i_episode_temp || ', i_episode=' || i_episode ||
                   ', i_patient=' || i_patient || ', i_patient_temp=' || i_patient_temp;
    
        pk_alertlog.log_debug(text => g_error, object_name => 'PK_MATCH', sub_object_name => 'SET_MATCH_CORE');
        IF NOT set_match_nurse_pat(i_lang => i_lang,
                                   
                                   i_prof         => i_prof,
                                   i_patient      => i_patient,
                                   i_patient_temp => i_patient_temp,
                                   o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'UPDATE OPINION';
        ts_opinion.upd(id_episode_in => i_episode, where_in => 'id_episode =' || i_episode_temp, rows_out => l_rows);
    
        g_error := 't_data_gov_mnt.process_update ts_opinion';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'OPINION',
                                      i_rowids       => l_rows,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
    
        g_error  := 'UPDATE OPINION (id_episode_answer) ';
        l_rowids := table_varchar();
        ts_opinion.upd(id_episode_answer_in => i_episode,
                       where_in             => 'id_episode_answer = ' || i_episode_temp,
                       rows_out             => l_rowids);
    
        g_error := 'PROCESS UPDATE OPINION_ANSWER (id_episode_answer)';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'OPINION',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE_ANSWER'));
    
        g_error  := 'UPDATE OPINION (id_episode_approval) ';
        l_rowids := table_varchar();
        ts_opinion.upd(id_episode_approval_in => i_episode,
                       where_in               => 'id_episode_approval = ' || i_episode_temp,
                       rows_out               => l_rowids);
    
        g_error := 'PROCESS UPDATE OPINION (id_episode_approval) ';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'OPINION',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE_APPROVAL'));
    
        g_error  := 'UPDATE PAT_ALLERGY';
        l_rowids := table_varchar();
        ts_pat_allergy.upd(id_episode_in => i_episode,
                           where_in      => 'id_episode =' || i_episode_temp,
                           rows_out      => l_rowids);
    
        g_error := 'PROCESS UPDATE PAT_ALLERGY';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PAT_ALLERGY',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        g_error  := 'UPDATE PAT_ALLERGY_UNAWARENESS';
        l_rowids := table_varchar();
        ts_pat_allergy_unawareness.upd(id_episode_in => i_episode,
                                       where_in      => 'id_episode =' || i_episode_temp,
                                       rows_out      => l_rowids);
    
        g_error := 'PROCESS UPDATE PAT_ALLERGY_UNAWARENESS';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PAT_ALLERGY_UNAWARENESS',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        g_error := 'UPDATE PAT_ALLERGY_HIST';
        UPDATE pat_allergy_hist
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        g_error := 'UPDATE PAT_BLOOD_GROUP';
        UPDATE pat_blood_group
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        g_error := 'UPDATE PAT_FAM_SOC_HIST';
        UPDATE pat_fam_soc_hist
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        g_error := 'UPDATE PAT_HABIT P';
        pk_alertlog.log_debug(g_error);
        l_rowids := table_varchar();
        ts_pat_habit.upd(id_episode_in => i_episode,
                         where_in      => 'id_episode = ' || i_episode_temp,
                         rows_out      => l_rowids);
    
        g_error := 'PROCESS UPDATE PAT_HABIT P';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PAT_HABIT',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        g_error := 'UPDATE PAT_NOTES';
        UPDATE pat_notes
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        g_error := 'UPDATE PAT_PROBLEM';
        UPDATE pat_problem
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        g_error := 'UPDATE PAT_PROBLEM_HIST';
        UPDATE pat_problem_hist
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
        l_rowids := table_varchar();
        -- ALERT-260695 - Match da tabela (PAT_PROB_UNAWARE e PAT_PROB_UNAWARE_HIST)
        g_error := 'UPDATE PAT_PROB_UNAWARE EPISODE';
        ts_pat_prob_unaware.upd(id_episode_in => i_episode,
                                where_in      => 'id_episode =' || i_episode_temp,
                                rows_out      => l_rowids);
    
        g_error := 'PROCESS UPDATE PAT_PROB_UNAWARE EPISODE';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PAT_PROB_UNAWARE',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        l_rowids := table_varchar();
        g_error  := 'UPDATE PROB_UNAWARE_HIST EPISODE';
        ts_pat_prob_unaware_hist.upd(id_episode_in => i_episode,
                                     where_in      => 'id_episode =' || i_episode_temp,
                                     rows_out      => l_rowids);
    
        g_error := 'PROCESS UPDATE PROB_UNAWARE_HIST EPISODE';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PAT_PROB_UNAWARE_HIST',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
        l_rowids := table_varchar();
        g_error  := 'UPDATE PAT_PROB_UNAWARE PATIENT';
        ts_pat_prob_unaware.upd(id_patient_in  => i_patient,
                                id_patient_nin => FALSE,
                                where_in       => 'id_patient = ' || i_patient_temp,
                                rows_out       => l_rowids);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PAT_PROB_UNAWARE',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        l_rowids := table_varchar();
        g_error  := 'PAT_PROB_UNAWARE_HIST PATIENT';
        ts_pat_prob_unaware_hist.upd(id_patient_in  => i_patient,
                                     id_patient_nin => FALSE,
                                     where_in       => 'id_patient = ' || i_patient_temp,
                                     rows_out       => l_rowids);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PAT_PROB_UNAWARE_HIST',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
        -- ALERT-260695
    
        g_error  := 'UPDATE SYS_ALERT_DET';
        l_rowids := table_varchar();
        ts_sys_alert_det.upd(id_episode_in  => i_episode,
                             id_episode_nin => FALSE,
                             where_in       => 'id_episode = ' || i_episode_temp,
                             rows_out       => l_rowids);
        g_error := 'PROCESS UPDATE SYS_ALERT_DET';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'SYS_ALERT_DET',
                                      i_rowids       => l_rowids,
                                      i_list_columns => table_varchar('ID_EPISODE'),
                                      o_error        => o_error);
    
        g_error := 'UPDATE SYS_ALERT_EVENT - episode/patient/visit';
        --The 3 updates that existed were merged into one in order to always have correct values at the same time
        UPDATE sys_alert_event
           SET id_episode = l_episode, id_patient = l_patient, id_visit = l_visit
         WHERE id_patient = i_patient_temp;
    
        g_error := 'UPDATE TRANSPORTATION';
        UPDATE transportation
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        g_error := 'UPDATE VACCINE_PRESCRIPTION';
        UPDATE vaccine_prescription
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        g_error := 'UPDATE VACCINE_PRESCRIPTION (vaccine_prescription)';
        UPDATE vaccine_prescription
           SET id_episode_origin = i_episode
         WHERE id_episode_origin = i_episode_temp;
        UPDATE vaccine_prescription
           SET id_episode_destination = i_episode
         WHERE id_episode_destination = i_episode_temp;
    
        g_error := 'UPDATE VITAL_SIGN_NOTES';
        UPDATE vital_sign_notes
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        g_error := 'UPDATE ts_vital_sign_read.upd';
    
        /*        ts_vital_sign_read.upd(id_episode_in => i_episode,
        id_patient_in => i_patient,
        where_in      => 'id_episode = ' || i_episode_temp,
        rows_out      => rows_vsr_out);*/
        g_error := 'PK_EA_VITAL_SIGNS.merge_vs_episode i_patient=' || i_patient || ', i_patient_temp=' ||
                   i_patient_temp || ' i_episode_temp=' || i_episode_temp || ', i_episode=' || i_episode;
        pk_alertlog.log_debug(g_error);
        pk_ea_vital_signs.merge_vs_episode(i_lang            => i_lang,
                                           i_prof            => i_prof,
                                           i_real_episode_id => i_episode,
                                           i_real_patient_id => i_patient,
                                           i_tmp_episode_id  => i_episode_temp,
                                           i_tmp_patient_id  => i_patient_temp,
                                           o_rows_vsr_out    => rows_vsr_out);
    
        l_rowids := table_varchar();
        g_error  := 'UPDATE EPIS_ABCDE_METH';
        ts_epis_abcde_meth.upd(id_episode_in => i_episode,
                               where_in      => 'id_episode = ' || i_episode_temp,
                               rows_out      => l_rowids);
    
        g_error := 'PROCESS UPDATE EPIS_ABCDE_METH';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EPIS_ABCDE_METH',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        l_rowids := table_varchar();
    
        g_error := 'UPDATE EPIS_MTOS_SCORE';
        ts_epis_mtos_score.upd(id_episode_in => i_episode,
                               where_in      => 'id_episode = ' || i_episode_temp,
                               rows_out      => l_rowids);
    
        g_error := 'PROCESS UPDATE EPIS_MTOS_SCORE';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EPIS_MTOS_SCORE',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        l_rowids := table_varchar();
    
        g_error := 'DOC_EXTERNAL';
        -- UPDATE doc_external
        --   SET id_episode = i_episode
        --  WHERE id_episode = i_episode_temp;
        l_rows  := table_varchar();
        g_error := 'Call ts_doc_external.upd / ID_EPISODE=' || i_episode || ', I_PATIENT_TEMP=' || i_episode_temp;
        ts_doc_external.upd(id_episode_in => i_episode,
                            where_in      => 'id_episode=' || i_episode_temp,
                            rows_out      => l_rows);
    
        g_error := 'Call t_data_gov_mnt.process_update';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'DOC_EXTERNAL',
                                      i_rowids     => l_rows,
                                      o_error      => o_error);
    
        g_error := 'UPDATE EPIS_BARTCHART';
        UPDATE epis_bartchart
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        g_error := 'UPDATE EPIS_COMPLAINT';
        l_rows  := table_varchar();
        ts_epis_complaint.upd(id_episode_in => i_episode,
                              where_in      => 'id_episode = ' || i_episode_temp,
                              rows_out      => l_rows);
    
        g_error := 't_data_gov_mnt.process_update ts_epis_complaint';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPIS_COMPLAINT',
                                      i_rowids       => l_rows,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
    
        g_error := 'UPDATE ESTATE';
        UPDATE estate
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        g_error := 'UPDATE ESTATE PREV';
        UPDATE estate
           SET id_prev_episode = i_episode
         WHERE id_prev_episode = i_episode_temp;
    
        g_error := 'UPDATE MDM_PROF_CODING';
        UPDATE mdm_prof_coding
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        g_error := 'UPDATE RECORDS_REVIEW_READ';
        UPDATE records_review_read
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        g_error := 'UPDATE SOCIAL_EPISODE';
        UPDATE social_episode
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        g_error := 'UPDATE WL_WAITING_LINE';
        UPDATE wl_waiting_line
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        g_error := 'UPDATE CARE_PLAN';
        UPDATE care_plan
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        g_error := 'UPDATE CARE_PLAN_HIST';
        UPDATE care_plan_hist
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        g_error := 'UPDATE GUIDELINE_PROCESS';
        UPDATE guideline_process
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        g_error := 'UPDATE PROTOCOL_PROCESS';
        UPDATE protocol_process
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        g_error := 'UPDATE ORDER_SET_PROCESS';
        UPDATE order_set_process
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        g_error := 'UPDATE CPOE_PROCESS';
        UPDATE cpoe_process
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        g_error := 'UPDATE CPOE_PROCESS_HIST';
        UPDATE cpoe_process_hist
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        g_error := 'UPDATE CPOE_PROCESS_TASK';
        UPDATE cpoe_process_task
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        g_error := 'UPDATE COMM_ORDER_REQ';
        l_rows  := table_varchar();
        ts_comm_order_req.upd(id_episode_in => i_episode,
                              where_in      => 'id_episode = ' || i_episode_temp,
                              rows_out      => l_rows);
    
        g_error := 't_data_gov_mnt.process_update comm_order_req';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'COMM_ORDER_REQ',
                                      i_rowids       => l_rows,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
    
        g_error := 'UPDATE COMM_ORDER_REQ_HIST';
        UPDATE comm_order_req_hist
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        -- print list
        g_error := 'UPDATE PRINT_LIST_JOB';
        l_rows  := table_varchar();
        ts_print_list_job.upd(id_episode_in => i_episode,
                              where_in      => 'id_episode = ' || i_episode_temp,
                              rows_out      => l_rows);
    
        g_error := 't_data_gov_mnt.process_update print_list_job';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'PRINT_LIST_JOB',
                                      i_rowids       => l_rows,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
    
        g_error := 'UPDATE PRINT_LIST_JOB_HIST';
        l_rows  := table_varchar();
        ts_print_list_job_hist.upd(id_episode_in => i_episode,
                                   where_in      => 'id_episode = ' || i_episode_temp,
                                   rows_out      => l_rows);
    
        g_error := 't_data_gov_mnt.process_update print_list_job_hist';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'PRINT_LIST_JOB_HIST',
                                      i_rowids       => l_rows,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
    
        g_error := 'UPDATE PAT_PREGNANCY';
        UPDATE pat_pregnancy
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        g_error := 'UPDATE PAT_PREGNANCY 2 (id_episode_rh)';
        UPDATE pat_pregnancy
           SET id_episode_rh = i_episode
         WHERE id_episode_rh = i_episode_temp;
    
        g_error := 'UPDATE PAT_PREGNANCY_HIST';
        UPDATE pat_pregnancy_hist
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        g_error := 'UPDATE PAT_PREGNANCY_HIST (id_episode_rh) ';
        UPDATE pat_pregnancy_rh_hist
           SET id_episode_rh = i_episode
         WHERE id_episode_rh = i_episode_temp;
    
        g_error := 'SELECT GRID_TASK';
        --Verifica se há registo na grid_task para o episódio temporário. Se não houver, cria-o
        SELECT COUNT(*)
          INTO l_num
          FROM grid_task
         WHERE id_episode = i_episode_temp;
    
        IF l_num = 0
        THEN
            g_error := 'INSERT GRID_TASK';
            INSERT INTO grid_task
                (id_grid_task, id_episode)
            VALUES
                (seq_grid_task.nextval, i_episode_temp);
        END IF;
    
        --Trata os hemoderivados e os materiais
        g_error := 'INSERT GRID_TASK (material_req)';
        UPDATE grid_task
           SET material_req =
               (SELECT material_req
                  FROM grid_task
                 WHERE id_episode = i_episode)
         WHERE id_episode = i_episode_temp
           AND material_req IS NULL;
    
        g_error := 'UPDATE GRID_TASK (hemo_req)';
        UPDATE grid_task
           SET hemo_req =
               (SELECT hemo_req
                  FROM grid_task
                 WHERE id_episode = i_episode)
         WHERE id_episode = i_episode_temp
           AND hemo_req IS NULL;
    
        g_error := 'DELETE GRID_TASK (1) i_episode:' || i_episode;
        DELETE FROM grid_task
         WHERE id_episode = i_episode;
    
        g_error := 'UPDATE GRID_TASK (2)';
        UPDATE grid_task
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        g_error := 'DELETE GRID_TASK_BETWEEN (1)';
        DELETE FROM grid_task_between
         WHERE id_episode = i_episode;
    
        g_error := 'UPDATE GRID_TASK_BETWEEN (2)';
        UPDATE grid_task_between
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        g_error := 'UPDATE EPIS_REPORT';
        UPDATE epis_report
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        g_error := 'UPDATE REP_EDIT_REPORT';
        UPDATE rep_edit_report
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        -- Past Medical and Surgical History
        g_error  := 'UPDATE PAT_HISTORY_DIAGNOSIS';
        l_rowids := table_varchar();
        ts_pat_history_diagnosis.upd(id_episode_in => i_episode,
                                     where_in      => 'id_episode = ' || i_episode_temp,
                                     rows_out      => l_rowids);
    
        g_error := 'PROCESS UPDATE PAT_HISTORY_DIAGNOSIS';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PAT_HISTORY_DIAGNOSIS',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        g_error  := 'UPDATE PAT_PAST_HIST_FREE_TEXT';
        l_rowids := table_varchar();
        ts_pat_past_hist_free_text.upd(where_in      => 'id_episode = ' || i_episode_temp,
                                       id_episode_in => i_episode,
                                       id_visit_in   => l_visit,
                                       rows_out      => l_rowids);
    
        g_error := 'PROCESS UPDATE PAT_PAST_HIST_FREE_TEXT';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PAT_PAST_HIST_FREE_TEXT',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        g_error  := 'UPDATE PAT_PAST_HIST_FT_HIST';
        l_rowids := table_varchar();
        ts_pat_past_hist_ft_hist.upd(where_in      => 'id_episode = ' || i_episode_temp,
                                     id_episode_in => i_episode,
                                     id_visit_in   => l_visit,
                                     rows_out      => l_rowids);
    
        g_error := 'UPDATE PAT_PAST_HIST_FT_HIST';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PAT_PAST_HIST_FT_HIST',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        -- Periodic Observation
        g_error := 'UPDATE PERIODIC_OBSERVATION_REG';
        UPDATE periodic_observation_reg
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        l_rowids := table_varchar();
        g_error  := 'CALL ts_po_param_reg.upd';
        ts_po_param_reg.upd(id_episode_in => i_episode,
                            where_in      => 'id_episode = ' || i_episode_temp,
                            rows_out      => l_rowids);
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'PO_PARAM_REG',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
    
        -- information transfer log
        g_error := 'UPDATE TI_LOG';
        /* <DENORM Fábio> */
        l_rowids := table_varchar();
        ts_ti_log.upd(id_episode_in  => i_episode,
                      id_episode_nin => FALSE,
                      where_in       => 'id_episode = ' || i_episode_temp,
                      rows_out       => l_rowids);
    
        g_error := 'PROCESS UPDATE TI_LOG';
        t_data_gov_mnt.process_update(i_lang, i_prof, 'TI_LOG', l_rowids, o_error, table_varchar('ID_EPISODE'));
    
        -- labor and delivery
        g_error := 'UPDATE EPIS_DOC_DELIVERY';
        UPDATE epis_doc_delivery edd
           SET edd.id_child_episode = i_episode
         WHERE edd.id_child_episode = i_episode_temp;
    
        -- schedule
        g_error := 'UPDATE SCHEDULE';
        UPDATE schedule
           SET id_episode = i_episode
         WHERE id_episode = i_episode_temp;
    
        -- INPATIENT LMAIA 21-08-2008
        -- [WO17660 - Actualiza o id_episode da tabela EHR_ACCESS_LOG]
        g_error := 'UPDATE EHR_ACCESS_LOG (i_episode)';
        UPDATE ehr_access_log eal
           SET eal.id_episode = i_episode
         WHERE eal.id_episode = i_episode_temp;
    
        g_error := 'UPDATE EHR_ACCESS_LOG (i_patient)';
        UPDATE ehr_access_log eal
           SET eal.id_patient = i_patient
         WHERE eal.id_patient = i_patient_temp;
    
        -- VACCINATION/IMMUNIZATION
        g_error := 'UPDATE PAT_VACC_ADM';
        UPDATE pat_vacc_adm pva
           SET pva.id_episode = i_episode
         WHERE pva.id_episode = i_episode_temp;
    
        g_error := 'UPDATE PAT_VACC';
        UPDATE pat_vacc
           SET id_patient = i_patient
         WHERE id_patient = i_patient_temp;
    
        g_error := 'UPDATE PAT_VACC_ADM_DET';
        UPDATE pat_vacc_adm_det pvad
           SET pvad.id_episode = i_episode
         WHERE pvad.id_episode = i_episode_temp;
    
        -- José Brito 25/08/2008 WO18079 - Actualizar ID_EPISODE da EPIS_RISK_FACTOR
        g_error := 'UPDATE EPIS_RISK_FACTOR';
        UPDATE epis_risk_factor erf
           SET erf.id_episode = i_episode
         WHERE erf.id_episode = i_episode_temp;
    
        --- Desnormalização Susana Silva
        g_error := 'UPDATE PAT_CHILD_FEED_DEV';
        ts_pat_child_feed_dev.upd(id_episode_in => i_episode,
                                  where_in      => 'id_episode = ' || i_episode_temp,
                                  rows_out      => l_rowids_upd1);
    
        g_error := 't_data_gov_mnt.process_update PAT_CHILD_FEED_DEV';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'PAT_CHILD_FEED_DEV',
                                      i_rowids       => l_rowids_upd1,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
    
        g_error := 'UPDATE PAT_CHILD_FEED_DEV (id_patient) ';
        ts_pat_child_feed_dev.upd(id_patient_in => i_patient,
                                  where_in      => 'id_patient = ' || i_patient_temp,
                                  rows_out      => l_rowids_upd1);
    
        g_error := 't_data_gov_mnt.process_update PAT_CHILD_FEED_DEV';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'PAT_CHILD_FEED_DEV',
                                      i_rowids       => l_rowids_upd1,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
    
        g_error := 'UPDATE PAT_CHILD_FEED_DEV_HIST';
        ts_pat_child_feed_dev_hist.upd(id_episode_in => i_episode,
                                       where_in      => 'id_episode = ' || i_episode_temp,
                                       rows_out      => l_rowids_upd1_5);
    
        g_error := 't_data_gov_mnt.process_update PAT_CHILD_FEED_DEV_HIST';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'PAT_CHILD_FEED_DEV_HIST',
                                      i_rowids       => l_rowids_upd1_5,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
    
        g_error := 'UPDATE PAT_CHILD_FEED_DEV_HIST (id_patient)';
        ts_pat_child_feed_dev_hist.upd(id_patient_in => i_patient,
                                       where_in      => 'id_patient = ' || i_patient_temp,
                                       rows_out      => l_rowids_upd1_5);
    
        g_error := 't_data_gov_mnt.process_update PAT_CHILD_FEED_DEV_HIST';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'PAT_CHILD_FEED_DEV_HIST',
                                      i_rowids       => l_rowids_upd1_5,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
    
        g_error := 'UPDATE CLIN_RECORD';
        ts_clin_record.upd(id_episode_in => i_episode,
                           where_in      => 'id_episode = ' || i_episode_temp,
                           rows_out      => l_rowids_upd2);
    
        g_error := 't_data_gov_mnt.process_update CLIN_RECORD';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'CLIN_RECORD',
                                      i_rowids       => l_rowids_upd2,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
    
        g_error := 'UPDATE P1_EXTERNAL_REQUEST';
        ts_p1_external_request.upd(id_episode_in => i_episode,
                                   where_in      => 'id_episode = ' || i_episode_temp,
                                   rows_out      => l_rowids_upd3);
    
        g_error := 't_data_gov_mnt.process_update P1_EXTERNAL_REQUEST';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'P1_EXTERNAL_REQUEST',
                                      i_rowids       => l_rowids_upd3,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
    
        g_error := 'UPDATE PAT_CLI_ATTRIBUTES';
        ts_pat_cli_attributes.upd(id_episode_in => i_episode,
                                  where_in      => 'id_episode = ' || i_episode_temp,
                                  rows_out      => l_rowids_upd4);
    
        g_error := 't_data_gov_mnt.process_update PAT_CLI_ATTRIBUTES';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'PAT_CLI_ATTRIBUTES',
                                      i_rowids       => l_rowids_upd4,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
    
        g_error := 'UPDATE PAT_FAMILY_MEMBER';
        ts_pat_family_member.upd(id_episode_in => i_episode,
                                 where_in      => 'id_episode = ' || i_episode_temp,
                                 rows_out      => l_rowids_upd5);
    
        g_error := 't_data_gov_mnt.process_update PAT_FAMILY_MEMBER';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'PAT_FAMILY_MEMBER',
                                      i_rowids       => l_rowids_upd5,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
    
        g_error := 'UPDATE PAT_FAMILY_PROF';
        ts_pat_family_prof.upd(id_episode_in => i_episode,
                               where_in      => 'id_episode = ' || i_episode_temp,
                               rows_out      => l_rowids_upd6);
    
        g_error := 't_data_gov_mnt.process_update PAT_FAMILY_PROF';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'PAT_FAMILY_PROF',
                                      i_rowids       => l_rowids_upd6,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
    
        g_error := 'UPDATE PAT_GRAFFAR_CRIT';
        ts_pat_graffar_crit.upd(id_episode_in => i_episode,
                                where_in      => 'id_episode = ' || i_episode_temp,
                                rows_out      => l_rowids_upd7);
    
        g_error := 't_data_gov_mnt.process_update PAT_GRAFFAR_CRIT';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'PAT_GRAFFAR_CRIT',
                                      i_rowids       => l_rowids_upd7,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
    
        g_error := 'UPDATE PAT_HISTORY';
        ts_pat_history.upd(id_episode_in => i_episode,
                           where_in      => 'id_episode = ' || i_episode_temp,
                           rows_out      => l_rowids_upd8);
    
        g_error := 't_data_gov_mnt.process_update PAT_HISTORY';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'PAT_HISTORY',
                                      i_rowids       => l_rowids_upd8,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
    
        g_error := 'UPDATE PAT_JOB';
        ts_pat_job.upd(id_episode_in => i_episode,
                       where_in      => 'id_episode = ' || i_episode_temp,
                       rows_out      => l_rowids_upd9);
    
        g_error := 't_data_gov_mnt.process_update PAT_JOB';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'PAT_JOB',
                                      i_rowids       => l_rowids_upd9,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
    
        g_error := 'UPDATE PAT_NECESSITY';
        ts_pat_necessity.upd(id_episode_in => i_episode,
                             where_in      => 'id_episode = ' || i_episode_temp,
                             rows_out      => l_rowids_upd10);
    
        g_error := 't_data_gov_mnt.process_update PAT_NECESSITY';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'PAT_NECESSITY',
                                      i_rowids       => l_rowids_upd10,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
    
        g_error := 'UPDATE PAT_SOC_ATTRIBUTES';
        ts_pat_soc_attributes.upd(id_episode_in => i_episode,
                                  where_in      => 'id_episode = ' || i_episode_temp,
                                  rows_out      => l_rowids_upd11);
    
        g_error := 't_data_gov_mnt.process_update PAT_SOC_ATTRIBUTES';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'PAT_SOC_ATTRIBUTES',
                                      i_rowids       => l_rowids_upd11,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
    
        g_error := 'UPDATE PAT_VACC';
        ts_pat_vacc.upd(id_episode_in => i_episode,
                        where_in      => 'id_episode = ' || i_episode_temp,
                        rows_out      => l_rowids_upd12);
    
        g_error := 't_data_gov_mnt.process_update PAT_VACC';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'PAT_VACC',
                                      i_rowids       => l_rowids_upd12,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
    
        g_error := 'UPDATE PAT_VACCINE';
        ts_pat_vaccine.upd(id_episode_in => i_episode,
                           where_in      => 'id_episode = ' || i_episode_temp,
                           rows_out      => l_rowids_upd13);
    
        g_error := 't_data_gov_mnt.process_update PAT_VACCINE';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'PAT_VACCINE',
                                      i_rowids       => l_rowids_upd13,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
    
        g_error := 'UPDATE SR_SURGERY_RECORD';
        ts_sr_surgery_record.upd(id_episode_in => i_episode,
                                 where_in      => 'id_episode = ' || i_episode_temp,
                                 rows_out      => l_rowids_upd14);
    
        g_error := 't_data_gov_mnt.process_update SR_SURGERY_RECORD';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'SR_SURGERY_RECORD',
                                      i_rowids       => l_rowids_upd14,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
    
        g_error := 'UPDATE UNIDOSE_CAR_PATIENT';
        ts_unidose_car_patient.upd(id_episode_in => i_episode,
                                   where_in      => 'id_episode = ' || i_episode_temp,
                                   rows_out      => l_rowids_upd15);
    
        g_error := 't_data_gov_mnt.process_update UNIDOSE_CAR_PATIENT';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'UNIDOSE_CAR_PATIENT',
                                      i_rowids       => l_rowids_upd15,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
    
        g_error := 'UPDATE VACCINE_DET';
        ts_vaccine_det.upd(id_episode_in => i_episode,
                           where_in      => 'id_episode = ' || i_episode_temp,
                           rows_out      => l_rowids_upd16);
    
        g_error := 't_data_gov_mnt.process_update VACCINE_DET';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'VACCINE_DET',
                                      i_rowids       => l_rowids_upd16,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
    
        --- fim da desnormalização -- Susana Silva
    
        g_error := 'UPDATE EPIS_DIET';
        /* <DENORM Fábio> */
        l_rowids := table_varchar();
        ts_epis_diet_req.upd(id_episode_in  => i_episode,
                             id_episode_nin => FALSE,
                             id_patient_in  => i_patient,
                             id_patient_nin => FALSE,
                             where_in       => 'id_episode = ' || i_episode_temp,
                             rows_out       => l_rowids);
    
        g_error := 'PROCESS UPDATE EPIS_DIET';
        t_data_gov_mnt.process_update(i_lang,
                                      i_prof,
                                      'EPIS_DIET_REQ',
                                      l_rowids,
                                      o_error,
                                      table_varchar('ID_EPISODE', 'IP_PATIENT'));
    
        -- THERAPEUTIC DECISION
        g_error  := 'UPDATE THERAPEUTIC_DECISION';
        l_rowids := table_varchar();
        ts_therapeutic_decision.upd(id_patient_in  => i_patient,
                                    id_patient_nin => FALSE,
                                    id_episode_in  => i_episode,
                                    where_in       => ' ID_EPISODE=' || i_episode_temp,
                                    rows_out       => l_rowids);
        -- END THERAPEUTIC DECISION
    
        -- DIRECTOR APPROVAL REQUESTS
        g_error := 'CALL pk_approval.approval_match';
        pk_alertlog.log_debug(text => g_error, object_name => 'PK_MATCH', sub_object_name => 'SET_MATCH_CORE');
        IF NOT pk_approval.approval_match(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_episode_temp => i_episode_temp,
                                          i_episode      => i_episode,
                                          i_patient      => i_patient,
                                          i_patient_temp => i_patient_temp,
                                          o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
        -- END DIRECTOR APPROVAL REQUESTS
    
        g_error  := 'UPDATE EPIS_ENCOUNTER';
        l_rowids := table_varchar();
        ts_epis_encounter.upd(id_episode_in  => i_episode,
                              id_episode_nin => FALSE,
                              where_in       => ' ID_EPISODE = ' || i_episode_temp,
                              rows_out       => l_rowids);
        g_error := 'PROCESS UPDATE EPIS_ENCOUNTER';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPIS_ENCOUNTER',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
    
        g_error  := 'UPDATE MANAGEMENT_FOLLOW_UP';
        l_rowids := table_varchar();
        ts_management_follow_up.upd(id_episode_in  => i_episode,
                                    id_episode_nin => FALSE,
                                    where_in       => ' ID_EPISODE = ' || i_episode_temp,
                                    rows_out       => l_rowids);
        g_error := 'PROCESS UPDATE MANAGEMENT_FOLLOW_UP';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'MANAGEMENT_FOLLOW_UP',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
    
        g_error  := 'UPDATE  MANAGEMENT_PLAN';
        l_rowids := table_varchar();
        ts_management_plan.upd(id_episode_in  => i_episode,
                               id_episode_nin => FALSE,
                               where_in       => ' ID_EPISODE = ' || i_episode_temp,
                               rows_out       => l_rowids);
    
        g_error := 'PROCESS UPDATE  MANAGEMENT_PLAN';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'MANAGEMENT_PLAN',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
    
        g_error := 'UPDATE management_plan';
        UPDATE management_plan mp
           SET mp.flg_status = pk_case_management.g_mnp_flg_status_o
         WHERE mp.id_episode = i_episode
           AND mp.flg_status = pk_case_management.g_mnp_flg_status_a
           AND mp.dt_register < (SELECT MAX(mp.dt_register)
                                   FROM management_plan mp
                                  WHERE mp.id_episode = i_episode
                                    AND mp.flg_status = pk_case_management.g_mnp_flg_status_a);
    
        g_error := 'UPDATE LENS_PRESC_HIST';
        ts_lens_presc_hist.upd(id_episode_in  => i_episode,
                               id_episode_nin => FALSE,
                               where_in       => ' ID_EPISODE = ' || i_episode_temp,
                               rows_out       => l_rowids);
    
        g_error := 'PROCESS UPDATE LENS_PRESC_HIST';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'LENS_PRESC_HIST',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
        g_error  := 'UPDATE LENS PRESC';
        l_rowids := table_varchar();
        ts_lens_presc.upd(id_episode_in  => i_episode,
                          id_episode_nin => FALSE,
                          where_in       => ' ID_EPISODE = ' || i_episode_temp,
                          rows_out       => l_rowids);
    
        g_error := 'PROCESS UPDATE LENS PRESC';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'LENS_PRESC',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
    
        --paramed_report
        l_rowids := table_varchar();
        g_error  := 'CALL ts_paramed_report.upd';
        ts_paramed_report.upd(id_episode_in  => i_episode,
                              id_episode_nin => FALSE,
                              where_in       => 'ID_EPISODE = ' || i_episode_temp,
                              rows_out       => l_rowids);
        g_error := 'CALL t_data_gov_mnt.process_update PARAMED_REPORT';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'PARAMED_REPORT',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
        --paramed_report_hist
        l_rowids := table_varchar();
        g_error  := 'CALL ts_paramed_report_hist.upd';
        ts_paramed_report_hist.upd(id_episode_in  => i_episode,
                                   id_episode_nin => FALSE,
                                   where_in       => 'ID_EPISODE = ' || i_episode_temp,
                                   rows_out       => l_rowids);
        g_error := 'CALL t_data_gov_mnt.process_update PARAMED_REPORT_HIST';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'PARAMED_REPORT_HIST',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
    
        --epis_prog_notes
        l_rowids := table_varchar();
        g_error  := 'CALL ts_epis_prog_notes.upd';
        ts_epis_prog_notes.upd(id_episode_in  => i_episode,
                               id_episode_nin => FALSE,
                               where_in       => 'ID_EPISODE = ' || i_episode_temp,
                               rows_out       => l_rowids);
        g_error := 'CALL t_data_gov_mnt.process_update EPIS_PROG_NOTES';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPIS_PROG_NOTES',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
    
        --pn_epis_reason
        l_rowids := table_varchar();
        g_error  := 'CALL ts_pn_epis_reason.upd';
        ts_pn_epis_reason.upd(id_episode_in  => i_episode,
                              id_episode_nin => FALSE,
                              where_in       => 'ID_EPISODE = ' || i_episode_temp,
                              rows_out       => l_rowids);
        g_error := 'CALL t_data_gov_mnt.process_update PN_EPIS_REASON';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'PN_EPIS_REASON',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
    
        g_error := 'UPDATE social_episode II';
        UPDATE social_episode se
           SET se.id_episode_migrated = i_episode
         WHERE se.id_episode_migrated = i_episode_temp;
    
        --epis_interv_plan
        l_rowids := table_varchar();
        g_error  := 'CALL ts_epis_interv_plan.upd';
        ts_epis_interv_plan.upd(id_episode_in  => i_episode,
                                id_episode_nin => FALSE,
                                where_in       => 'ID_EPISODE = ' || i_episode_temp,
                                rows_out       => l_rowids);
        g_error := 'CALL t_data_gov_mnt.process_update EPIS_INTERV_PLAN';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPIS_INTERV_PLAN',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
    
        --epis_interv_plan_hist
        l_rowids := table_varchar();
        g_error  := 'CALL ts_epis_interv_plan_hist.upd';
        ts_epis_interv_plan_hist.upd(id_episode_in  => i_episode,
                                     id_episode_nin => FALSE,
                                     where_in       => 'ID_EPISODE = ' || i_episode_temp,
                                     rows_out       => l_rowids);
        g_error := 'CALL t_data_gov_mnt.process_update EPIS_INTERV_PLAN_HIST';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPIS_INTERV_PLAN_HIST',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
    
        -- SUPPLIES
        g_error := 'CALL t_data_gov_mnt.process_update SUPPLY_REQUEST';
        ts_supply_request.upd(id_episode_in  => i_episode,
                              id_episode_nin => FALSE,
                              where_in       => ' id_episode = ' || i_episode_temp,
                              rows_out       => l_rowids);
    
        g_error := 'PROCESS UPDATE SUPPLY_REQUEST';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'SUPPLY_REQUEST',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
        l_rowids := table_varchar();
        g_error  := 'CALL t_data_gov_mnt.process_update SUPPLY_REQUEST_HIST';
        ts_supply_request_hist.upd(id_episode_in  => i_episode,
                                   id_episode_nin => FALSE,
                                   where_in       => ' id_episode = ' || i_episode_temp,
                                   rows_out       => l_rowids);
    
        g_error := 'PROCESS UPDATE SUPPLY_REQUEST_HIST';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'SUPPLY_REQUEST_HIST',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
        l_rowids := table_varchar();
        g_error  := 'CALL t_data_gov_mnt.process_update SUPPLY_WORKFLOW';
        ts_supply_workflow.upd(id_episode_in  => i_episode,
                               id_episode_nin => FALSE,
                               where_in       => ' id_episode = ' || i_episode_temp,
                               rows_out       => l_rowids);
    
        g_error := 'PROCESS UPDATE SUPPLY_WORKFLOW';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'SUPPLY_WORKFLOW',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
        l_rowids := table_varchar();
        g_error  := 'CALL t_data_gov_mnt.process_update SUPPLY_WORKFLOW_HIST';
        ts_supply_workflow_hist.upd(id_episode_in  => i_episode,
                                    id_episode_nin => FALSE,
                                    where_in       => ' id_episode = ' || i_episode_temp,
                                    rows_out       => l_rowids);
    
        g_error := 'PROCESS UPDATE SUPPLY_WORKFLOW_HIST';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'SUPPLY_WORKFLOW_HIST',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
    
        -- Patient checklists
        g_error := 'UPDATE patient_checklist';
        UPDATE pat_checklist pchk
           SET pchk.id_episode_start = i_episode
         WHERE pchk.id_episode_start = i_episode_temp;
        UPDATE pat_checklist pchk
           SET pchk.id_episode_end = i_episode
         WHERE pchk.id_episode_end = i_episode_temp;
    
        -- Answers for patient checklists
        g_error := 'UPDATE patient_checklist_det';
        UPDATE pat_checklist_det pchkd
           SET pchkd.id_episode = i_episode
         WHERE pchkd.id_episode = i_episode_temp;
    
        g_error := 'CALL pk_death_registry.change_dr_episode_id';
        pk_alertlog.log_info(text => g_error, object_name => 'PK_MATCH', sub_object_name => 'SET_MATCH_CORE');
        IF NOT pk_death_registry.change_dr_episode_id(i_lang        => i_lang,
                                                      i_new_episode => i_episode,
                                                      i_old_episode => i_episode_temp,
                                                      o_error       => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL pk_organ_donor.change_donor_episode_id';
        pk_alertlog.log_info(text => g_error, object_name => 'PK_MATCH', sub_object_name => 'SET_MATCH_CORE');
        IF NOT pk_organ_donor.change_donor_episode_id(i_lang        => i_lang,
                                                      i_new_episode => i_episode,
                                                      i_old_episode => i_episode_temp,
                                                      o_error       => o_error)
        THEN
            RETURN FALSE;
        END IF;
        l_rowids := table_varchar();
        g_error  := 'UPDATE DICTATION_REPORT';
        ts_dictation_report.upd(id_episode_in => i_episode,
                                where_in      => ' id_episode = ' || i_episode_temp,
                                rows_out      => l_rowids);
    
        g_error := 'Process Update dictation report notes';
        pk_alertlog.log_debug(text => g_error, object_name => 'PK_MATCH', sub_object_name => 'SET_MATCH_CORE');
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'DICTATION_REPORT',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        l_rowids := table_varchar();
        g_error  := 'Update dictation report hist notes';
        pk_alertlog.log_debug(text => g_error, object_name => 'PK_MATCH', sub_object_name => 'SET_MATCH_CORE');
        ts_dictation_report_hist.upd(id_episode_in => i_episode,
                                     where_in      => ' id_episode = ' || i_episode_temp,
                                     rows_out      => l_rowids);
    
        g_error := 'Process Update dictation report hist notes';
        pk_alertlog.log_debug(text => g_error, object_name => 'PK_MATCH', sub_object_name => 'SET_MATCH_CORE');
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'DICTATION_REPORT_HIST',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        --PAT_TRIAL
        l_rowids := table_varchar();
        g_error  := 'CALL PAT_TRIAL.upd';
        ts_pat_trial.upd(id_episode_in  => i_episode,
                         id_episode_nin => FALSE,
                         where_in       => 'ID_EPISODE = ' || i_episode_temp,
                         rows_out       => l_rowids);
    
        g_error := 'CALL t_data_gov_mnt.process_update PAT_TRIAL';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'PAT_TRIAL',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
        --PAT_TRIAL_FOLLOW_UP
        l_rowids := table_varchar();
        g_error  := 'CALL PAT_TRIAL_FOLLOW_UP.upd';
        ts_pat_trial_follow_up.upd(id_episode_record_in  => i_episode,
                                   id_episode_record_nin => FALSE,
                                   where_in              => 'ID_EPISODE_RECORD = ' || i_episode_temp,
                                   rows_out              => l_rowids);
    
        g_error := 'CALL t_data_gov_mnt.process_update PAT_TRIAL_FOLLOW_UP';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'PAT_TRIAL_FOLLOW_UP',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE_RECORD'));
    
        --PAT_TRIAL_FOLLOW_UP_HIST
        l_rowids := table_varchar();
        g_error  := 'CALL PAT_TRIAL_FOLLOW_UP_HIST.upd';
        ts_pat_trial_follow_up_hist.upd(id_episode_record_in  => i_episode,
                                        id_episode_record_nin => FALSE,
                                        where_in              => 'ID_EPISODE_RECORD = ' || i_episode_temp,
                                        rows_out              => l_rowids);
    
        g_error := 'CALL t_data_gov_mnt.process_update PAT_TRIAL_FOLLOW_UP_HIST';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'PAT_TRIAL_FOLLOW_UP_HIST',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE_RECORD'));
    
        g_error := 'UPDATE REVIEW_DETAIL';
        ts_review_detail.upd(id_episode_in => i_episode,
                             where_in      => ' id_episode = ' || i_episode_temp,
                             rows_out      => l_rowids);
    
        g_error := 'PROCESS UPDATE REVIEW_DETAIL';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'REVIEW_DETAIL',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        l_rowids := table_varchar();
        g_error  := 'CALL ts_cdr_call.upd I';
        ts_cdr_call.upd(id_episode_in  => i_episode,
                        id_episode_nin => FALSE,
                        where_in       => 'ID_EPISODE = ' || i_episode_temp,
                        rows_out       => l_rowids);
        g_error := 'CALL t_data_gov_mnt.process_update CDR_CALL I';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'CDR_CALL',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
    
        l_rowids := table_varchar();
        g_error  := 'CALL ts_cdr_call.upd II';
        ts_cdr_call.upd(id_patient_in  => i_patient,
                        id_patient_nin => FALSE,
                        where_in       => 'ID_PATIENT = ' || i_patient_temp,
                        rows_out       => l_rowids);
        g_error := 'CALL t_data_gov_mnt.process_update CDR_CALL II';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'CDR_CALL',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN pk_diagnosis.e_primary_diag_exception THEN
            RAISE pk_diagnosis.e_primary_diag_exception;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MATCH',
                                              'SET_MATCH_CORE',
                                              o_error);
            -- José Brito 10/07/2009 ALERT-34678  Match integration between ALERT clinical/non-clinical
            --pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;
    --
    --
    --
    FUNCTION get_match_inp_episodes
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_name       IN patient.name%TYPE,
        i_gender     IN patient.gender%TYPE,
        i_dt_birth   IN VARCHAR2,
        i_num_hplan  IN pat_health_plan.num_health_plan%TYPE,
        i_department IN NUMBER,
        i_dt_begin   IN VARCHAR2,
        o_epis       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:  Usada no INPATIENT: Esta função devolve um array com os dados do episódio actual que serão utilizados para a
                        obtenção de episódios relacionados, de acordo com critérios pré-definidos, de forma a permitir fazer
                        o match entre os episódios.
        
                        Os critérios são os seguintes (por ordem de obtenção):
                            1. Igual número de cartão de utente
                            2. Iguais nome do paciente, serviço e data de admissao
                            3. Iguais nome do paciente, sexo e data de nascimento
                            4. Iguais nome do paciente e data de nascimento.
                        Quando um dos critérios devolve episódios, já não são avaliados os restantes critérios
        
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                                 I_PROF - ID do médico cirurgião que está a aceder à grelha
                                 I_EPISODE - ID do episódio
                                 I_NAME - Nome do doente
                                 I_GENDER - Sexo do doente
                                 I_DT_BIRTH - Data de nascimento do doente
                                 I_NUM_HPLAN - Número de cartão de utente (número do SNS)
                                 I_DEPARTMENT  - ID do serviço
                                 I_DT_BEGIN - Data de admissao
                       SAIDA:   O_EPIS - Array de dados de todos os episódios relacionados
                                O_ERROR - erro
        
          CRIAÇÃO: jose silva 2007/03/26
          NOTAS:
        *********************************************************************************/
    
        num_epis         NUMBER;
        l_dt_begin_tstz  TIMESTAMP WITH LOCAL TIME ZONE;
        l_id_health_plan sys_config.value%TYPE;
        l_id_cnt_hp      health_plan.id_content%TYPE;
    
        l_dt_birth    patient.dt_birth%TYPE;
        l_config_curp VARCHAR2(10 CHAR);
    BEGIN
    
        num_epis        := 0;
        l_dt_begin_tstz := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_begin, NULL);
        l_id_cnt_hp     := pk_sysconfig.get_config('ADT_NATIONAL_HEALTH_PLAN_ID', i_prof);
        BEGIN
            SELECT hp.id_health_plan
              INTO l_id_health_plan
              FROM health_plan hp
             WHERE hp.id_content = l_id_cnt_hp
               AND hp.flg_available = 'Y';
        EXCEPTION
            WHEN no_data_found THEN
                l_id_health_plan := NULL;
        END;
        l_config_curp := pk_sysconfig.get_config('MATCH_USE_CURP', i_prof);
        l_dt_birth    := to_date(i_dt_birth, pk_date_utils.g_dateformat);
    
        IF l_config_curp = pk_alert_constant.g_no
        THEN
            --Verifica se existem episódios para o mesmo número de SNS
            g_error := 'COUNT EPISODES-1';
            SELECT COUNT(*)
              INTO num_epis
              FROM pat_health_plan php, episode e, visit v, epis_info ei
             WHERE php.id_health_plan = l_id_health_plan
               AND nvl(php.num_health_plan, '@') = nvl(i_num_hplan, '@')
               AND v.id_patient = php.id_patient
               AND php.id_institution = i_prof.institution
               AND v.flg_status = g_active
               AND e.id_visit = v.id_visit
               AND e.id_episode != i_episode
               AND e.flg_status = g_active
               AND e.id_epis_type = pk_episode.get_epis_type(i_lang, i_episode)
               AND ei.id_episode = e.id_episode
               AND nvl(ei.flg_unknown, g_flg_unknown_def) = g_flg_unknown_def;
        ELSE
            SELECT COUNT(*)
              INTO num_epis
              FROM patient p
              JOIN person pe
                ON p.id_person = pe.id_person
              JOIN episode e
                ON p.id_patient = e.id_patient
              LEFT JOIN epis_triage etr
                ON etr.id_episode = e.id_episode
              JOIN epis_info ei
                ON e.id_episode = ei.id_episode
             WHERE e.id_episode != i_episode
               AND e.flg_status = g_active
               AND nvl(pe.social_security_number, '@') = nvl(i_num_hplan, '@')
               AND e.id_epis_type = pk_episode.get_epis_type(i_lang, i_episode)
               AND nvl(ei.flg_unknown, g_flg_unknown_def) = g_flg_unknown_def;
        END IF;
        IF nvl(num_epis, 0) > 0
        THEN
            --carrega array de episódios
            g_error := 'OPEN O_EPIS-1';
            OPEN o_epis FOR
                SELECT e.id_episode,
                       v.id_visit,
                       p.id_patient,
                       pk_patient.get_pat_name(i_lang, i_prof, e.id_patient, e.id_episode) name,
                       -- ALERT-102882 Patient name used for sorting
                       pk_patient.get_pat_name_to_sort(i_lang, i_prof, e.id_patient, e.id_episode, NULL) name_pat_sort,
                       pk_adt.get_pat_non_disc_options(i_lang, i_prof, e.id_patient) pat_ndo,
                       pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, e.id_patient) pat_nd_icon,
                       pk_patient.get_gender(i_lang, p.gender) gender,
                       pk_patient.get_pat_age(i_lang,
                                              p.dt_birth,
                                              p.dt_deceased,
                                              p.age,
                                              i_prof.institution,
                                              i_prof.software) pat_age,
                       decode(pk_patphoto.check_blob(p.id_patient),
                              'N',
                              '',
                              pk_patphoto.get_pat_photo(i_lang, i_prof, e.id_patient, e.id_episode, ei.id_schedule)) photo,
                       p.dt_birth,
                       pk_date_utils.date_chr_short_read(i_lang, p.dt_birth, i_prof) dt_birth_formatted,
                       CASE l_config_curp
                           WHEN pk_alert_constant.g_yes THEN
                            (SELECT pr.social_security_number
                               FROM person pr
                              WHERE id_person = p.id_person)
                           ELSE
                            php.num_health_plan
                       END num_health_plan,
                       cs.id_clinical_service,
                       dpt.id_department,
                       pk_translation.get_translation(i_lang, cs.code_clinical_service) desc_specialty,
                       pk_translation.get_translation(i_lang, dpt.code_department) desc_department,
                       pk_date_utils.trunc_insttimezone(i_prof, e.dt_begin_tstz, NULL) dt_episode,
                       pk_date_utils.dt_chr_tsz(i_lang, e.dt_begin_tstz, i_prof) dt_episode_formatted,
                       --Alexandre Santos 13-10-2010 ALERT-726 Changing and cancelling appointmentsChanging to another physician with the same specialty as the responsible physician. However, the responsible physician remains the same.
                       (SELECT pk_hand_off_api.get_resp_icons(i_lang, i_prof, e.id_episode, NULL)
                          FROM dual) resp_icons
                  FROM pat_health_plan  php,
                       patient          p,
                       episode          e,
                       visit            v,
                       department       dpt,
                       epis_info        ei,
                       clinical_service cs,
                       person           pe
                 WHERE ((php.id_health_plan = l_id_health_plan AND
                       nvl(php.num_health_plan, '@') = nvl(i_num_hplan, '@') AND
                       l_config_curp = pk_alert_constant.g_no) OR
                       (nvl(pe.social_security_number, '@') = nvl(i_num_hplan, '@') AND
                       l_config_curp = pk_alert_constant.g_yes))
                   AND php.id_patient(+) = p.id_patient
                   AND php.id_institution(+) = i_prof.institution
                   AND v.id_patient = p.id_patient
                   AND v.flg_status = g_active
                   AND e.id_visit = v.id_visit
                   AND e.id_episode != i_episode
                   AND e.flg_status = g_active
                   AND e.id_epis_type = pk_episode.get_epis_type(i_lang, i_episode)
                   AND ei.id_episode = e.id_episode
                   AND nvl(ei.flg_unknown, g_flg_unknown_def) = g_flg_unknown_def
                   AND e.id_department = dpt.id_department
                   AND cs.id_clinical_service = e.id_clinical_service
                   AND p.id_person = pe.id_person
                 ORDER BY p.name, p.dt_birth;
        
        ELSE
            --Verifica se existem episódios que obedeçam aos seguintes critérios:
            --  Nome do paciente, serviço e data de admissao
            g_error := 'COUNT EPISODES-2';
            SELECT COUNT(*)
              INTO num_epis
              FROM episode e, visit v, patient p, epis_info ei
             WHERE upper(p.name) = upper(i_name)
               AND v.id_patient = p.id_patient
               AND v.flg_status = g_active
               AND e.id_visit = v.id_visit
               AND e.flg_status = g_active
               AND e.id_epis_type = pk_episode.get_epis_type(i_lang, i_episode)
               AND e.id_episode != i_episode
               AND ei.id_episode = e.id_episode
               AND nvl(ei.flg_unknown, g_flg_unknown_def) = g_flg_unknown_def
               AND e.id_department = i_department
               AND e.dt_begin_tstz BETWEEN pk_date_utils.trunc_insttimezone(i_prof, l_dt_begin_tstz, NULL) AND
                   pk_date_utils.add_days_to_tstz(pk_date_utils.trunc_insttimezone(i_prof, l_dt_begin_tstz), .99999);
        
            IF nvl(num_epis, 0) > 0
            THEN
                --carrega array de episódios
                g_error := 'OPEN O_EPIS-2';
                OPEN o_epis FOR
                    SELECT e.id_episode,
                           v.id_visit,
                           p.id_patient,
                           pk_patient.get_pat_name(i_lang, i_prof, e.id_patient, e.id_episode) name,
                           -- ALERT-102882 Patient name used for sorting
                           pk_patient.get_pat_name_to_sort(i_lang, i_prof, e.id_patient, e.id_episode, NULL) name_pat_sort,
                           pk_adt.get_pat_non_disc_options(i_lang, i_prof, e.id_patient) pat_ndo,
                           pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, e.id_patient) pat_nd_icon,
                           pk_patient.get_gender(i_lang, p.gender) gender,
                           pk_patient.get_pat_age(i_lang,
                                                  p.dt_birth,
                                                  p.dt_deceased,
                                                  p.age,
                                                  i_prof.institution,
                                                  i_prof.software) pat_age,
                           decode(pk_patphoto.check_blob(p.id_patient),
                                  'N',
                                  '',
                                  pk_patphoto.get_pat_photo(i_lang, i_prof, e.id_patient, e.id_episode, ei.id_schedule)) photo,
                           p.dt_birth,
                           pk_date_utils.date_chr_short_read(i_lang, p.dt_birth, i_prof) dt_birth_formatted,
                           CASE l_config_curp
                               WHEN pk_alert_constant.g_yes THEN
                                (SELECT pr.social_security_number
                                   FROM person pr
                                  WHERE id_person = p.id_person)
                               ELSE
                                (SELECT php.num_health_plan
                                   FROM pat_health_plan php
                                  WHERE php.id_health_plan = l_id_health_plan
                                    AND php.id_patient = p.id_patient
                                    AND php.id_institution = i_prof.institution)
                           END num_health_plan,
                           cs.id_clinical_service,
                           dpt.id_department,
                           pk_translation.get_translation(i_lang, cs.code_clinical_service) desc_specialty,
                           pk_translation.get_translation(i_lang, dpt.code_department) desc_department,
                           pk_date_utils.trunc_insttimezone(i_prof, e.dt_begin_tstz, NULL) dt_episode,
                           pk_date_utils.dt_chr_tsz(i_lang, e.dt_begin_tstz, i_prof) dt_episode_formatted,
                           --Alexandre Santos 13-10-2010 ALERT-726 Changing and cancelling appointmentsChanging to another physician with the same specialty as the responsible physician. However, the responsible physician remains the same.
                           (SELECT pk_hand_off_api.get_resp_icons(i_lang, i_prof, e.id_episode, NULL)
                              FROM dual) resp_icons
                      FROM episode e, visit v, patient p, epis_info ei, department dpt, clinical_service cs
                     WHERE upper(p.name) = upper(i_name)
                       AND v.id_patient = p.id_patient
                       AND v.flg_status = g_active
                       AND e.id_epis_type = pk_episode.get_epis_type(i_lang, i_episode)
                       AND e.id_visit = v.id_visit
                       AND e.flg_status = g_active
                       AND e.id_episode != i_episode
                       AND ei.id_episode = e.id_episode
                       AND nvl(ei.flg_unknown, g_flg_unknown_def) = g_flg_unknown_def
                       AND e.id_department = i_department
                       AND e.id_department = dpt.id_department
                       AND e.id_clinical_service = cs.id_clinical_service
                       AND e.dt_begin_tstz BETWEEN pk_date_utils.trunc_insttimezone(i_prof, l_dt_begin_tstz, NULL) AND
                           pk_date_utils.add_days_to_tstz(pk_date_utils.trunc_insttimezone(i_prof, l_dt_begin_tstz),
                                                          .99999)
                     ORDER BY p.name, p.dt_birth;
            
            ELSE
                --Verifica se existem episódios que obedeçam aos seguintes critérios:
                --  Nome do paciente, sexo e data de nascimento
                g_error := 'COUNT EPISODES-3';
                SELECT COUNT(*)
                  INTO num_epis
                  FROM episode e, visit v, patient p, epis_info ei
                 WHERE upper(p.name) = upper(i_name)
                   AND p.gender = i_gender
                   AND trunc(p.dt_birth) = trunc(l_dt_birth)
                   AND v.id_patient = p.id_patient
                   AND v.flg_status = g_active
                   AND e.id_epis_type = pk_episode.get_epis_type(i_lang, i_episode)
                   AND e.id_visit = v.id_visit
                   AND e.flg_status = g_active
                   AND e.id_episode != i_episode
                   AND ei.id_episode = e.id_episode
                   AND nvl(ei.flg_unknown, g_flg_unknown_def) = g_flg_unknown_def;
            
                IF nvl(num_epis, 0) > 0
                THEN
                    --carrega array de episódios
                    g_error := 'OPEN O_EPIS-3';
                    OPEN o_epis FOR
                        SELECT e.id_episode,
                               v.id_visit,
                               p.id_patient,
                               pk_patient.get_pat_name(i_lang, i_prof, e.id_patient, e.id_episode) name,
                               -- ALERT-102882 Patient name used for sorting
                               pk_patient.get_pat_name_to_sort(i_lang, i_prof, e.id_patient, e.id_episode, NULL) name_pat_sort,
                               pk_adt.get_pat_non_disc_options(i_lang, i_prof, e.id_patient) pat_ndo,
                               pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, e.id_patient) pat_nd_icon,
                               pk_patient.get_gender(i_lang, p.gender) gender,
                               pk_patient.get_pat_age(i_lang,
                                                      p.dt_birth,
                                                      p.dt_deceased,
                                                      p.age,
                                                      i_prof.institution,
                                                      i_prof.software) pat_age,
                               decode(pk_patphoto.check_blob(p.id_patient),
                                      'N',
                                      '',
                                      pk_patphoto.get_pat_photo(i_lang,
                                                                i_prof,
                                                                e.id_patient,
                                                                e.id_episode,
                                                                ei.id_schedule)) photo,
                               p.dt_birth,
                               pk_date_utils.date_chr_short_read(i_lang, p.dt_birth, i_prof) dt_birth_formatted,
                               CASE l_config_curp
                                   WHEN pk_alert_constant.g_yes THEN
                                    (SELECT pr.social_security_number
                                       FROM person pr
                                      WHERE id_person = p.id_person)
                                   ELSE
                                    (SELECT php.num_health_plan
                                       FROM pat_health_plan php
                                      WHERE php.id_health_plan = l_id_health_plan
                                        AND php.id_patient = p.id_patient
                                        AND php.id_institution = i_prof.institution)
                               END num_health_plan,
                               cs.id_clinical_service,
                               dpt.id_department,
                               pk_translation.get_translation(i_lang, cs.code_clinical_service) desc_specialty,
                               pk_translation.get_translation(i_lang, dpt.code_department) desc_department,
                               pk_date_utils.trunc_insttimezone(i_prof, e.dt_begin_tstz, NULL) dt_episode,
                               pk_date_utils.dt_chr_tsz(i_lang, e.dt_begin_tstz, i_prof) dt_episode_formatted,
                               --Alexandre Santos 13-10-2010 ALERT-726 Changing and cancelling appointmentsChanging to another physician with the same specialty as the responsible physician. However, the responsible physician remains the same.
                               (SELECT pk_hand_off_api.get_resp_icons(i_lang, i_prof, e.id_episode, NULL)
                                  FROM dual) resp_icons
                          FROM episode e, visit v, patient p, department dpt, epis_info ei, clinical_service cs
                         WHERE upper(p.name) = upper(i_name)
                           AND p.gender = i_gender
                           AND trunc(p.dt_birth) = trunc(l_dt_birth)
                           AND v.id_patient = p.id_patient
                           AND v.flg_status = g_active
                           AND e.id_visit = v.id_visit
                           AND e.flg_status = g_active
                           AND e.id_epis_type = pk_episode.get_epis_type(i_lang, i_episode)
                           AND e.id_episode != i_episode
                           AND ei.id_episode = e.id_episode
                           AND nvl(ei.flg_unknown, g_flg_unknown_def) = g_flg_unknown_def
                           AND e.id_department = dpt.id_department
                           AND cs.id_clinical_service = e.id_clinical_service
                         ORDER BY p.name, p.dt_birth;
                ELSE
                    --Verifica se existem episódios que obedeçam aos seguintes critérios:
                    --  Nome do paciente e data de nascimento
                    g_error := 'COUNT EPISODES-4';
                    SELECT COUNT(*)
                      INTO num_epis
                      FROM episode e, visit v, patient p, epis_info ei
                     WHERE upper(p.name) = upper(i_name)
                       AND trunc(p.dt_birth) = trunc(l_dt_birth)
                       AND v.id_patient = p.id_patient
                       AND v.flg_status = g_active
                       AND e.id_epis_type = pk_episode.get_epis_type(i_lang, i_episode)
                       AND e.id_visit = v.id_visit
                       AND e.flg_status = g_active
                       AND e.id_episode != i_episode
                       AND ei.id_episode = e.id_episode
                       AND nvl(ei.flg_unknown, g_flg_unknown_def) = g_flg_unknown_def;
                
                    IF nvl(num_epis, 0) > 0
                    THEN
                        --carrega array de episódios
                        g_error := 'OPEN O_EPIS-4';
                        OPEN o_epis FOR
                            SELECT e.id_episode,
                                   v.id_visit,
                                   p.id_patient,
                                   pk_patient.get_pat_name(i_lang, i_prof, e.id_patient, e.id_episode) name,
                                   -- ALERT-102882 Patient name used for sorting
                                   pk_patient.get_pat_name_to_sort(i_lang, i_prof, e.id_patient, e.id_episode, NULL) name_pat_sort,
                                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, e.id_patient) pat_ndo,
                                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, e.id_patient) pat_nd_icon,
                                   pk_patient.get_gender(i_lang, p.gender) gender,
                                   pk_patient.get_pat_age(i_lang,
                                                          p.dt_birth,
                                                          p.dt_deceased,
                                                          p.age,
                                                          i_prof.institution,
                                                          i_prof.software) pat_age,
                                   decode(pk_patphoto.check_blob(p.id_patient),
                                          'N',
                                          '',
                                          pk_patphoto.get_pat_photo(i_lang,
                                                                    i_prof,
                                                                    e.id_patient,
                                                                    e.id_episode,
                                                                    ei.id_schedule)) photo,
                                   p.dt_birth,
                                   pk_date_utils.date_chr_short_read(i_lang, p.dt_birth, i_prof) dt_birth_formatted,
                                   CASE l_config_curp
                                       WHEN pk_alert_constant.g_yes THEN
                                        (SELECT pr.social_security_number
                                           FROM person pr
                                          WHERE id_person = p.id_person)
                                       ELSE
                                        (SELECT php.num_health_plan
                                           FROM pat_health_plan php
                                          WHERE php.id_health_plan = l_id_health_plan
                                            AND php.id_patient = p.id_patient
                                            AND php.id_institution = i_prof.institution)
                                   END num_health_plan,
                                   cs.id_clinical_service,
                                   dpt.id_department,
                                   pk_translation.get_translation(i_lang, cs.code_clinical_service) desc_specialty,
                                   pk_translation.get_translation(i_lang, dpt.code_department) desc_department,
                                   pk_date_utils.trunc_insttimezone(i_prof, e.dt_begin_tstz, NULL) dt_episode,
                                   pk_date_utils.dt_chr_tsz(i_lang, e.dt_begin_tstz, i_prof) dt_episode_formatted,
                                   --Alexandre Santos 13-10-2010 ALERT-726 Changing and cancelling appointmentsChanging to another physician with the same specialty as the responsible physician. However, the responsible physician remains the same.
                                   (SELECT pk_hand_off_api.get_resp_icons(i_lang, i_prof, e.id_episode, NULL)
                                      FROM dual) resp_icons
                              FROM episode e, visit v, patient p, epis_info ei, clinical_service cs, department dpt
                             WHERE upper(p.name) = upper(i_name)
                               AND trunc(p.dt_birth) = trunc(l_dt_birth)
                               AND v.id_patient = p.id_patient
                               AND v.flg_status = g_active
                               AND e.id_epis_type = pk_episode.get_epis_type(i_lang, i_episode)
                               AND e.id_visit = v.id_visit
                               AND e.flg_status = g_active
                               AND e.id_episode != i_episode
                               AND ei.id_episode = e.id_episode
                               AND nvl(ei.flg_unknown, g_flg_unknown_def) = g_flg_unknown_def
                               AND e.id_department = dpt.id_department
                               AND cs.id_clinical_service = e.id_clinical_service
                             ORDER BY p.name, p.dt_birth;
                    ELSE
                        --Não foram encontrados episódios para os critérios defindos. Assim, o array irá vazio.
                        pk_types.open_my_cursor(o_epis);
                    END IF;
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
                                              'ALERT',
                                              'PK_MATCH',
                                              'GET_MATCH_INP_EPISODES',
                                              o_error);
            pk_types.open_my_cursor(o_epis);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Esta função actualiza a tabela GRID_TASK depois de feito o match de dois episódios
    *
    * @param i_lang        ID do idioma
    * @param i_prof        Id do profissional, instituição e software
    * @param i_Episode     Id do episódio
    *
    * @return              TRUE/FALSE
    *
    * @author              Rui Batista
    * @version             1.0
    * @since               2007/05/22
       ********************************************************************************************/

    FUNCTION set_match_grid_task
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        pk_alertlog.log_debug(text            => 'i_episode:' || i_episode,
                              object_name     => 'PK_MATCH',
                              sub_object_name => 'SET_MATCH_GRID_TASK');
    
        --Coluna drug_presc
        g_error := 'CALL TO PK_API_PFH_IN.PROCESS_EPIS_GRID_TASK';
        pk_alertlog.log_debug(text => g_error, object_name => 'PK_MATCH', sub_object_name => 'SET_MATCH_GRID_TASK');
        pk_api_pfh_in.process_epis_grid_task(i_lang, i_prof, i_episode);
    
        --Coluna monitorization
        g_error := 'CALL TO PK_MONITORIZATION.INSERT_MONITORIZATION_TASK';
        pk_alertlog.log_debug(text => g_error, object_name => 'PK_MATCH', sub_object_name => 'SET_MATCH_GRID_TASK');
        pk_ea_logic_monitorizations.ins_grid_task_monit_epis(i_lang       => i_lang,
                                                             i_prof       => i_prof,
                                                             i_id_episode => i_episode);
    
        --Coluna movement
        g_error := 'CALL TO PK_MOVEMENT.INSERT_MOVEMENT_TASK';
        pk_alertlog.log_debug(text => g_error, object_name => 'PK_MATCH', sub_object_name => 'SET_MATCH_GRID_TASK');
    
        IF NOT pk_movement.insert_movement_task(i_lang, i_episode, i_prof, g_catg_prof_doctor, o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        --Coluna clin_rec_req
        g_error := 'CALL TO PK_CLINICAL_RECORD.INSERT_CLIN_REC_REQ_TASK';
        pk_alertlog.log_debug(text => g_error, object_name => 'PK_MATCH', sub_object_name => 'SET_MATCH_GRID_TASK');
    
        IF NOT pk_clinical_record.insert_clin_rec_req_task(i_lang, i_episode, i_prof, g_catg_prof_doctor, o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        --Coluna positioning
        g_error := 'CALL TO PK_INP_POSITIONING.UPDATE_POSITIONING_TASK';
        pk_alertlog.log_debug(text => g_error, object_name => 'PK_MATCH', sub_object_name => 'SET_MATCH_GRID_TASK');
        pk_ea_logic_positioning.ins_grid_task_positionings_epi(i_lang       => i_lang,
                                                               i_prof       => i_prof,
                                                               i_id_episode => i_episode);
    
        --Coluna hidrics_reg
        g_error := 'CALL TO PK_INP_HIDRICS_PBL.UPDATE_HIDRICS_TASK';
        pk_alertlog.log_debug(text => g_error, object_name => 'PK_MATCH', sub_object_name => 'SET_MATCH_GRID_TASK');
        pk_ea_logic_hidrics.ins_grid_task_hidrics_epis(i_lang => i_lang, i_prof => i_prof, i_id_episode => i_episode);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MATCH',
                                              'SET_MATCH_GRID_TASK',
                                              o_error);
            -- José Brito 10/07/2009 ALERT-34678  Match integration between ALERT clinical/non-clinical
            --pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Esta função traz da tabela CRITERIA o resultado do query CRIT_MCHOICE_SELECT
    *
    * @param id_criteria   id da tabela criteria
    * @param i_lang        ID do idioma
    *
    * @return              TRUE/FALSE
    * @o_crit_mchoice      cursor com os valores da criteria
    *
    * @author              Odete Monteiro
    * @version             1.0
    * @since               2007/06/18
       ********************************************************************************************/
    FUNCTION get_crit_mchoice_select
    (
        i_criteria     IN criteria.id_criteria%TYPE,
        i_lang         IN language.id_language%TYPE,
        o_crit_mchoice OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_crit_mchoice     criteria.crit_mchoice_select%TYPE;
        l_crit_mchoice_aux criteria.crit_mchoice_select%TYPE;
    
        CURSOR c_crit_mchoice_select(i_c_criteria IN criteria.id_criteria%TYPE) IS
            SELECT crit_mchoice_select
              FROM criteria
             WHERE id_criteria = i_c_criteria;
    
    BEGIN
        g_error := 'OPEN C_CRIT_MCHOICE_SELECT CURSOR';
        OPEN c_crit_mchoice_select(i_criteria);
        FETCH c_crit_mchoice_select
            INTO l_crit_mchoice_aux;
        CLOSE c_crit_mchoice_select;
    
        l_crit_mchoice := REPLACE(l_crit_mchoice_aux, '@i_lang', i_lang);
    
        g_error := 'OPEN O_CRIT_MCHOICE CURSOR';
        OPEN o_crit_mchoice FOR l_crit_mchoice;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MATCH',
                                              'GET_CRIT_MCHOICE_SELECT',
                                              o_error);
            --pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    FUNCTION get_match_search_pat_inst
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_patient         IN patient.id_patient%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        o_search          OUT pk_types.cursor_type,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_mess_no_result  OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:  Esta função devolve um array com os dados do episódios INACTIVOS obtidos através dos critérios
                        de pesquisa seleccionados (por instituição e tipo de episódio).
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                        I_PROF - ID do médico cirurgião que está a aceder à grelha
                                I_EPISODE - ID do episódio
                        I_ID_SYS_BTN_CRIT - Lista de ID'S de critérios de pesquisa.
                        I_CRIT_VAL - Lista de valores dos critérios de pesquisa
                       SAIDA:   O_SEARCH - Array de dados doos episódios obtidos
                          O_FLG_SHOW - Flag que indica se deve ser mostrada a mensagem
                        O_MSG - Descrição da mensagem
                        O_MSG_TITLE - Título da mensagem
                        O_BUTTON - Código dos botões a mostrar
                        O_MESS_NO_RESULT - Mensagem quando a pesquisa não devolver resultados
                                O_ERROR - erro
        
          CRIAÇÃO: TCO 2007/06/19
        
        *********************************************************************************/
        l_limit          sys_config.value%TYPE;
        l_where          VARCHAR2(4000);
        v_where_cond     VARCHAR2(4000);
        aux_sql          VARCHAR2(10000);
        l_count          PLS_INTEGER;
        xpl              VARCHAR2(0010) := '''';
        l_id_health_plan sys_config.value%TYPE;
        l_id_cnt_hp      health_plan.id_content%TYPE;
        l_prof           VARCHAR2(0500);
        --
        l_prof_cat category.flg_type%TYPE;
        --
        l_commonm015_exception EXCEPTION;
        --
        l_grp_insts table_number;
        l_inst_grp_flg_rel_ars CONSTANT institution_group.flg_relation%TYPE := 'ARS';
        l_config_curp VARCHAR2(10 CHAR);
    BEGIN
    
        l_prof         := 'PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || ')';
        g_software_inp := pk_sysconfig.get_config('SOFTWARE_ID_INP', i_prof);
    
        l_prof_cat    := pk_edis_list.get_prof_cat(i_prof);
        l_config_curp := pk_sysconfig.get_config('MATCH_USE_CURP', i_prof);
    
        g_error := 'GET INSTs GRP';
        SELECT column_value
          BULK COLLECT
          INTO l_grp_insts
          FROM TABLE(pk_list.tf_get_all_inst_group(i_prof.institution, l_inst_grp_flg_rel_ars));
    
        IF i_prof.software IN (g_software_edis, g_software_ubu, g_software_inp, g_software_oris)
        THEN
            g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
            --Obtém dados de parametrização
            l_limit := pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof);
            --
            --Lê critérios de pesquisa seleccionados
            g_error := 'GET SEARCH CRITERIA';
            FOR i IN 1 .. i_id_sys_btn_crit.count
            LOOP
                --lê critérios de pesquisa e preenche cláusula where
                g_error      := 'SET WHERE';
                v_where_cond := NULL;
            
                IF i_id_sys_btn_crit(i) IS NOT NULL
                THEN
                    IF NOT pk_search.get_criteria_condition(i_lang,
                                                            i_prof,
                                                            i_id_sys_btn_crit(i),
                                                            REPLACE(i_crit_val(i), '''', '%'),
                                                            v_where_cond,
                                                            o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                
                    l_where := l_where || v_where_cond;
                END IF;
            END LOOP;
            --
            --Verifica se o número de registos obtidos através dos critérios de pesquisa é superior ao definido na SYS_CONFIG
            l_id_cnt_hp := pk_sysconfig.get_config('ADT_NATIONAL_HEALTH_PLAN_ID', i_prof);
            BEGIN
                SELECT hp.id_health_plan
                  INTO l_id_health_plan
                  FROM health_plan hp
                 WHERE hp.id_content = l_id_cnt_hp
                   AND hp.flg_available = 'Y';
            EXCEPTION
                WHEN no_data_found THEN
                    l_id_health_plan := NULL;
            END;
            --
            g_error := 'GET COUNT';
            aux_sql := 'SELECT COUNT(pat.id_patient) ' || --
                       '  FROM patient pat ' || --
                       ' WHERE EXISTS (SELECT 0 ' || --
                       '          FROM episode v, discharge d, epis_info ei, clin_record cr, pat_health_plan php ' || --
                       '         WHERE v.id_patient = pat.id_patient ' || --
                       '           AND v.id_episode != :i_episode ' || --
                       '           AND d.id_episode(+) = v.id_episode ' || --
                       '           AND ei.id_episode(+) = v.id_episode ' || --
                       '           AND v.flg_status = :g_epis_inactive ' || --
                       '           AND D.FLG_STATUS (+)<>''' || pk_discharge_core.g_disch_status_cancel || '''' ||
                       ' AND D.FLG_STATUS (+)<>''' || pk_discharge_core.g_disch_status_reopen || ''' ' ||
                       '           AND nvl(ei.flg_unknown, ''N'') = ''N'' ' || --
                       '           AND php.id_patient(+) = v.id_patient ' || --
                       '           AND php.id_health_plan(+) = :l_id_health_plan ' || --
                       '           AND php.flg_status(+) = :g_active ' || --
                       '           AND (php.id_institution = v.id_institution OR php.id_institution IS NULL) ' || --
                       '           AND cr.id_patient(+) = v.id_patient ' || --
                       '           AND cr.id_institution(+) = v.id_institution ' || --
                       '           AND cr.flg_status(+) = :g_active ' || --
                       '           AND v.id_institution in (select * from table(:l_grp_insts)) ' || --
                       l_where || ' ) ' || --
                       '   AND pat.id_patient != :i_patient ';
            --
            g_error := 'GET EXECUTE IMMEDIATE';
            EXECUTE IMMEDIATE aux_sql
                INTO l_count
                USING --
            i_episode, --
            g_epis_inactive, --
            l_id_health_plan, --
            g_active, --
            g_active, --
            l_grp_insts, --
            i_patient;
            --
            IF l_count > l_limit
            THEN
                o_flg_show  := 'Y';
                o_msg       := pk_search.get_overlimit_message(i_lang           => i_lang,
                                                               i_prof           => i_prof,
                                                               i_flg_has_action => pk_alert_constant.g_yes,
                                                               i_limit          => l_limit);
                o_msg_title := pk_message.get_message(i_lang, 'SEARCH_CRITERIA_T011');
                o_button    := 'R';
            END IF;
            --
            IF l_count = 0
            THEN
                RAISE l_commonm015_exception;
            END IF;
            --
            g_error := 'GET CURSOR O_SEARCH';
            aux_sql := 'SELECT * FROM (SELECT pat.id_patient, ' || --
                       '       pk_patient.get_pat_name(:i_lang, :i_prof, pat.id_patient, :i_episode) name, ' || --
                       '       pk_patient.get_pat_name_to_sort(:i_lang, :i_prof, pat.id_patient, :i_episode) name_pat_sort, ' || --
                       '       pk_patient.get_julian_age(:i_lang, pat.dt_birth, pat.age) pat_age_for_order_by, ' || --
                       '       pk_adt.get_pat_non_disc_options(:i_lang, :i_prof, pat.id_patient) pat_ndo, ' || --
                       '       pk_adt.get_pat_non_disclosure_icon(:i_lang, :i_prof, pat.id_patient) pat_nd_icon, ' || --
                       '       pk_date_utils.date_chr_short_read(:i_lang, pat.dt_birth, :i_prof) dt_birth_formatted, ' || --
                       '       pat.dt_birth, ' || --
                       ' decode(''' || l_config_curp ||
                       ''',''Y'', 
                            (SELECT pr.social_security_number
                               FROM person pr
                              WHERE id_person = pat.id_person),
                           pat.num_health_plan) num_health_plan , ' || --
                       '       pk_patient.get_gender(:i_lang, pat.gender) gender, ' || --
                       '       pk_patient.get_pat_age(:i_lang, pat.dt_birth, pat.dt_deceased, pat.age, :i_prof_institution, :i_prof_software) pat_age, ' || --
                       '       decode(pk_patphoto.check_blob(pat.id_patient), ' || --
                       '              ''N'', ' || --
                       '              '''', ' || --
                       '              pk_patphoto.get_pat_photo(:i_lang, :i_prof, pat.id_patient, NULL, NULL)) photo, ' || --
                       ' pk_hand_off_api.get_resp_icons(:i_lang, :i_prof, :i_episode, NULL) resp_icons' || --
                       '  FROM (SELECT DISTINCT pat.id_person, pat.id_patient, pat.name, pat.dt_birth, php.num_health_plan, pat.gender, pat.age, pat.dt_deceased ' || --
                       '          FROM patient pat, pat_health_plan php ' || --
                       '         WHERE EXISTS (SELECT 0 ' || --
                       '                  FROM episode v, discharge d, epis_info ei, clin_record cr ' || --
                       '                 WHERE v.id_patient = pat.id_patient ' || --
                       '                   AND v.id_episode != :i_episode ' || --
                       '                   AND d.id_episode(+) = v.id_episode ' || --
                       '                   AND ei.id_episode(+) = v.id_episode ' || --
                       '                   AND v.flg_status = :g_epis_inactive ' || --
                       '                   AND D.FLG_STATUS (+)<>''' || pk_discharge_core.g_disch_status_cancel || '''' ||
                       ' AND D.FLG_STATUS (+)<>''' || pk_discharge_core.g_disch_status_reopen || ''' ' ||
                       '                   AND nvl(ei.flg_unknown, ''N'') = ''N'' ' || --
                       '                   AND (php.id_institution = v.id_institution OR php.id_institution IS NULL) ' || --
                       '                   AND cr.id_patient(+) = v.id_patient ' || --
                       '                   AND cr.id_institution(+) = v.id_institution ' || --
                       '                   AND cr.flg_status(+) = :g_active ' || --
                       '                   AND v.id_institution in (select * from table(:l_grp_insts)) ' || --
                       l_where || ' ) ' || --
                       '           AND pat.id_patient != :i_patient ' || --
                       '           AND php.id_patient(+) = pat.id_patient ' || --
                       '           AND php.id_health_plan(+) = :l_id_health_plan ' || --
                       '           AND php.flg_status(+) = :g_active) pat ' || --
                       ' WHERE rownum <= :l_limit )' || --
                       ' ORDER BY name_pat_sort ';
        
            OPEN o_search FOR aux_sql
                USING --
            i_lang, --
            i_prof, --
            i_episode, --
            i_lang, --
            i_prof, --
            i_episode, --
            i_lang, --
            i_lang, --
            i_prof, --
            i_lang, --
            i_prof, --
            i_lang, --
            i_prof, --
            i_lang, -- gender
            i_lang, --
            i_prof.institution, --
            i_prof.software, --
            i_lang, --
            i_prof, --
            i_lang, --
            i_prof, --
            i_episode, --
            i_episode, --
            g_epis_inactive, --
            g_active, --
            l_grp_insts, --
            i_patient, --
            l_id_health_plan, --
            g_active, --
            l_limit;
        
        ELSE
            pk_types.open_my_cursor(o_search);
        END IF;
        --
        RETURN TRUE;
        --
    EXCEPTION
        WHEN l_commonm015_exception THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang,
                                   'T_COMMON_ERROR',
                                   pk_message.get_message(i_lang, 'COMMON_M015'),
                                   g_error,
                                   'ALERT',
                                   'PK_MATCH',
                                   'GET_MATCH_SEARCH_PAT_INST',
                                   NULL,
                                   'U');
            
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_types.open_my_cursor(o_search);
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MATCH',
                                              'GET_MATCH_SEARCH_PAT_INST',
                                              o_error);
            pk_types.open_my_cursor(o_search);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    FUNCTION get_match_currepis_pat
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_curr    OUT pk_types.cursor_type,
        o_icon    OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        /***************   ***************************************************************
           OBJECTIVO:  Esta função devolve um array com os dados do episódio actual (verdadeiro ou temporario)
                          que serão utilizados para a obtenção de episódios relacionados, de acordo com
                    critérios pré-definidos, de forma a permitir fazer o match entre os episódios.
        
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                        I_PROF - ID do médico cirurgião que está a aceder à grelha
                                I_EPISODE - ID do episódio
                       SAIDA:   O_CURR- Array de dados do episódio actual
                                  O_ICON - Nome do icon de selecção
                                O_ERROR - erro
        
          CRIAÇÃO: TCO 2007/06/27
          NOTAS: Se o episódio actual não for temporário, esta função não vai devolver qualquer registo, já
                   que para o match, o episódio actual terá que ser sempre o temporário
        *********************************************************************************/
        l_id_health_plan       health_plan.id_health_plan%TYPE;
        l_id_cnt_hp            health_plan.id_content%TYPE;
        l_msg_edis_common_t002 sys_message.desc_message%TYPE;
        l_msg_edis_common_t004 sys_message.desc_message%TYPE;
        l_doc_type_id          doc_type.id_doc_type%TYPE;
        l_id_market            market.id_market%TYPE;
        l_config_curp          VARCHAR2(10 CHAR);
    BEGIN
    
        l_msg_edis_common_t002 := pk_message.get_message(i_lang, 'EDIS_COMMON_T002');
        l_msg_edis_common_t004 := pk_message.get_message(i_lang, 'EDIS_COMMON_T004');
        l_doc_type_id          := pk_sysconfig.get_config('DOC_TYPE_ID', i_prof);
        l_id_cnt_hp            := pk_sysconfig.get_config('ADT_NATIONAL_HEALTH_PLAN_ID', i_prof);
        l_config_curp          := pk_sysconfig.get_config('MATCH_USE_CURP', i_prof);
        o_icon                 := g_hand_icon;
    
        BEGIN
            SELECT hp.id_health_plan
              INTO l_id_health_plan
              FROM health_plan hp
             WHERE hp.id_content = l_id_cnt_hp
               AND hp.flg_available = 'Y';
        EXCEPTION
            WHEN no_data_found THEN
                l_id_health_plan := NULL;
        END;
    
        l_id_market := pk_utils.get_institution_market(i_lang => i_lang, i_id_institution => i_prof.institution);
    
        g_error := 'OPEN O_CURR CURSOR';
        OPEN o_curr FOR
            SELECT e.id_episode,
                   e.id_visit,
                   p.id_patient,
                   pk_patient.get_pat_name(i_lang, i_prof, e.id_patient, e.id_episode) name,
                   pk_patient.get_pat_name_to_sort(i_lang, i_prof, e.id_patient, e.id_episode) name_pat_sort,
                   pk_patient.get_julian_age(i_lang, p.dt_birth, p.age) pat_age_for_order_by,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, e.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, e.id_patient) pat_nd_icon,
                   pk_patient.get_gender(i_lang, p.gender) gender,
                   -- Fábio Oliveira 16/05/08 usar a cache e a nova função visto já termos o dt_birth
                   (SELECT pk_patient.get_pat_age(i_lang,
                                                  p.dt_birth,
                                                  p.dt_deceased,
                                                  p.age,
                                                  i_prof.institution,
                                                  i_prof.software)
                      FROM dual) pat_age,
                   pk_patphoto.get_pat_photo(i_lang, i_prof, e.id_patient, e.id_episode, ei.id_schedule) photo,
                   p.dt_birth,
                   -- Fábio Oliveira 16/05/08 usar a cache
                   (SELECT pk_date_utils.date_chr_short_read(i_lang, p.dt_birth, i_prof)
                      FROM dual) dt_birth_formatted,
                   -- Fábio Oliveira 16/05/08 Obter número do serviço de saúde (health plan) de forma coerente com a informação do paciente
                   CASE
                        WHEN l_id_market = 16 THEN
                         (SELECT php.affiliation_number
                            FROM epis_health_plan ehp
                            JOIN pat_health_plan php
                              ON ehp.id_pat_health_plan = php.id_pat_health_plan
                           WHERE ehp.id_episode = e.id_episode
                             AND php.institution_key = e.id_institution
                             AND php.flg_status = 'A'
                             AND rownum = 1)
                        ELSE
                         (SELECT php.num_health_plan
                            FROM pat_health_plan php
                           WHERE php.id_health_plan = l_id_health_plan
                             AND php.id_patient = p.id_patient
                             AND php.id_institution = i_prof.institution)
                    END num_health_plan,
                   --ORIS
                   pk_sr_clinical_info.get_proposed_surgery(i_lang, e.id_episode, i_prof, pk_alert_constant.g_no) desc_intervention,
                   h.dt_target_tstz dt_surg,
                   --EDIS
                   ei.triage_acuity acuity,
                   ei.triage_color_text color_text,
                   decode(pk_ubu.get_episode_transportation(ei.id_episode, i_prof),
                          NULL,
                          decode(i_prof.software,
                                 pk_alert_constant.g_soft_edis,
                                 l_msg_edis_common_t002,
                                 l_msg_edis_common_t004),
                          l_msg_edis_common_t004) desc_origin, -- tco 21/06/2007
                   --INP
                   -- jose silva 16-03-2007 devolver tambem o id do serviço
                   ds.id_clinical_service,
                   ds.id_department,
                   (SELECT pk_translation.get_translation(i_lang,
                                                          'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' ||
                                                          ds.id_clinical_service)
                      FROM dual) desc_specialty,
                   (SELECT pk_translation.get_translation(i_lang, 'DEPARTMENT.CODE_DEPARTMENT.' || ds.id_department)
                      FROM dual) desc_department,
                   --JOSE SILVA 14-03-2007 formato da data
                   -- Fábio Oliveira 16/05/08 usar a cache
                   (SELECT pk_date_utils.trunc_insttimezone(i_prof, e.dt_begin_tstz, NULL)
                      FROM dual) dt_episode,
                   (SELECT pk_date_utils.dt_chr_tsz(i_lang, e.dt_begin_tstz, i_prof)
                      FROM dual) dt_episode_formatted,
                   CASE
                        WHEN l_id_market = 16 THEN
                         (SELECT ca.location
                            FROM v_contact_address_mx ca
                           WHERE ca.id_contact_entity = p.id_person
                             AND ca.flg_main_address = 'Y'
                             AND rownum = 1)
                        ELSE
                         (SELECT location
                            FROM pat_soc_attributes psa
                           WHERE psa.id_institution = i_prof.institution
                             AND psa.id_patient = e.id_patient)
                    END location,
                   CASE
                        WHEN l_config_curp = pk_alert_constant.g_yes THEN
                         (SELECT social_security_number
                            FROM person pe
                           WHERE pe.id_person = p.id_person
                             AND rownum = 1)
                        ELSE
                         (SELECT t.num_doc
                            FROM (SELECT de.num_doc, de.id_patient
                                    FROM doc_external de
                                   WHERE de.id_doc_type = l_doc_type_id
                                     AND de.flg_status = 'A'
                                   ORDER BY decode(de.id_institution, i_prof.institution, 0, 1) ASC, de.dt_inserted DESC) t
                           WHERE t.id_patient = e.id_patient
                             AND rownum < 2)
                    END num_doc_id
              FROM episode       e,
                   patient       p,
                   schedule_sr   h, --Tabelas específicas do ORIS
                   epis_triage   etr, --Tabelas específicas do EDIS
                   epis_info     ei,
                   dep_clin_serv ds --Tabelas específicas do INP
             WHERE e.id_episode = i_episode
               AND ei.id_episode = e.id_episode
               AND p.id_patient = e.id_patient
               AND h.id_episode(+) = e.id_episode
               AND etr.id_episode(+) = e.id_episode
               AND (etr.dt_begin_tstz = (SELECT MAX(etr1.dt_begin_tstz)
                                           FROM epis_triage etr1
                                          WHERE etr1.id_episode(+) = e.id_episode) OR etr.dt_begin_tstz IS NULL)
               AND ds.id_dep_clin_serv(+) = ei.id_dep_clin_serv;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MATCH',
                                              'GET_MATCH_CURREPIS_PAT',
                                              o_error);
            pk_types.open_my_cursor(o_curr);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;
    --
    /**
    * This function changes the id_patient of the i_old_episode
    * and associated visit to the i_new_patient
    *
    * @param i_lang language id
    * @param i_prof user's object
    * @param i_new_patient new patient id
    * @param i_old_episode id of episode for which the associated patient will change
    * @param o_error error message, if error occurs
    *
    * @return true on success, false on error
    */
    FUNCTION set_episode_new_patient
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_new_patient IN patient.id_patient%TYPE,
        i_old_episode IN episode.id_episode%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_count PLS_INTEGER;
    
        l_old_patient     patient.id_patient%TYPE;
        l_old_epis_status episode.flg_status%TYPE;
        l_old_visit       visit.id_visit%TYPE;
        l_patient_name    patient.name%TYPE;
        l_epis_type_desc  table_varchar;
    
        l_visitm021_exception EXCEPTION;
        l_visitm022_exception EXCEPTION;
        l_visitm023_exception EXCEPTION;
    
        l_rows table_varchar;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
        g_error        := 'i_new_patient= ' || i_new_patient || ' i_old_episode:' || i_old_episode;
        pk_alertlog.log_debug(text => g_error, object_name => 'PK_MATCH', sub_object_name => 'SET_EPISODE_NEW_PATIENT');
    
        --ler estado e paciente do episódio
        BEGIN
            g_error := 'GET ID_VISIT, ID_PATIENT';
            SELECT e.id_patient, e.flg_status, e.id_visit
              INTO l_old_patient, l_old_epis_status, l_old_visit
              FROM episode e
             WHERE e.id_episode = i_old_episode;
        EXCEPTION
            WHEN no_data_found THEN
                RAISE g_exception;
        END;
    
        --mesmo paciente: isto não deveria acontecer, mas
        --garante-se que não acontece mesmo
        IF l_old_patient = i_new_patient
        THEN
            RAISE l_visitm023_exception;
        END IF;
    
        --validação se o paciente já tem episódios activos nesta instituitção
        IF l_old_epis_status IN (pk_alert_constant.g_active, pk_alert_constant.g_pending)
        THEN
            g_error := 'COUNT ACTIVE';
            SELECT MIN(name), CAST(COLLECT(epis_type_desc) AS table_varchar) eptypes
              INTO l_patient_name, l_epis_type_desc
              FROM (SELECT DISTINCT pn.name,
                                    lower(pk_translation.get_translation(i_lang,
                                                                         'EPIS_TYPE.CODE_EPIS_TYPE.' || en.id_epis_type)) epis_type_desc
                      FROM visit vo, episode eo, visit vn, episode en, patient pn
                     WHERE vo.id_visit = eo.id_visit
                       AND eo.id_episode = i_old_episode
                       AND eo.flg_ehr = pk_alert_constant.g_flg_ehr_n
                       AND eo.flg_status IN (pk_alert_constant.g_active, pk_alert_constant.g_pending)
                          --
                       AND vn.id_patient = i_new_patient
                       AND vn.id_visit = en.id_visit
                       AND en.flg_status IN (pk_alert_constant.g_active, pk_alert_constant.g_pending)
                       AND pn.id_patient = i_new_patient
                          --
                       AND vo.id_institution = i_prof.institution
                       AND vn.id_institution = i_prof.institution
                       AND eo.id_epis_type = en.id_epis_type
                     ORDER BY 2);
        
            IF l_epis_type_desc.count = 1
            THEN
                --um episódio activo nesta instituição
                RAISE l_visitm021_exception;
            ELSIF l_epis_type_desc.count > 1
            THEN
                --vários episódios activos nesta instituição
                RAISE l_visitm022_exception;
            END IF;
        END IF;
    
        g_error := 'COUNT VISIT';
        SELECT COUNT(0)
          INTO l_count
          FROM visit
         WHERE id_patient = l_old_patient;
    
        g_error := 'CALL PK_API_EDIS.SET_EPISODE_NEW_PATIENT';
        pk_alertlog.log_debug(text => g_error, object_name => 'PK_MATCH', sub_object_name => 'SET_EPISODE_NEW_PATIENT');
        IF NOT pk_api_edis.set_episode_new_patient(i_lang        => i_lang,
                                                   i_prof        => i_prof,
                                                   i_new_patient => i_new_patient,
                                                   i_old_episode => i_old_episode,
                                                   o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL pk_translation.upd_translation_trs_pat';
        pk_translation.upd_translation_trs_pat(i_old_pat => l_old_patient, i_new_pat => i_new_patient);
    
        --BM: It is necessary to update doc_externals created
        --by ADT with no id_episode
        g_error := 'TRYING TO UPDATE DOC_EXTERNAL';
    
        l_rows  := table_varchar();
        g_error := 'Call ts_doc_external.upd / ID_PATIENT=' || i_new_patient || ', I_PATIENT_TEMP=' || l_old_patient;
        ts_doc_external.upd(id_patient_in => i_new_patient,
                            where_in      => 'id_patient=' || l_old_patient || 'AND id_episode IS NULL',
                            rows_out      => l_rows);
    
        g_error := 'Call t_data_gov_mnt.process_update DOC_EXTERNAL';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'DOC_EXTERNAL',
                                      i_rowids     => l_rows,
                                      o_error      => o_error);
    
        g_error := 'CALL PK_ADT.SET_PATIENT_MATCH';
        pk_alertlog.log_debug(text => g_error, object_name => 'PK_MATCH', sub_object_name => 'SET_EPISODE_NEW_PATIENT');
        IF NOT pk_adt.set_patient_match(i_lang        => i_lang,
                                        i_prof        => i_prof,
                                        i_patient     => i_new_patient,
                                        i_old_episode => i_old_episode,
                                        i_old_visit   => l_old_visit,
                                        o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'COUNT VISIT';
        SELECT COUNT(0)
          INTO l_count
          FROM visit
         WHERE id_patient = l_old_patient;
        dbms_output.put_line(l_count);
    
        IF l_count = 0
        THEN
            --apagar paciente sem episódios e informação registada.
            --A seguinte secção de código apaga informação não clinica relativa ao paciente
            --e depois tenta-o apagar. Se ao fazer delete PATIENT lançar uma excepção é
            --porque o paciente ainda tem informação noutra tabelas.
            /*as tabelas a apagar são:
            MATCH_EPIS
            CLIN_RECORD
            PAT_DMGR_HIST
            PAT_DOC
            PAT_EXT_SYS
            PAT_FAMILY_MEMBER
            PAT_GRAFFAR_CRIT
            PAT_HEALTH_PLAN
            PAT_JOB
            PAT_MED_DECL
            PAT_NECESSITY
            PAT_PERMISSION
            PAT_PHOTO
            PAT_SOC_ATTRIBUTES
            PAT_CLI_ATTRIBUTES
            SCH_GROUP
            SCHOOL
            */
        
            --START ADT-806 Match for new ADT tables 11-May-2009
            g_error := 'CALL PK_ADT.DELETE_PATIENT';
            pk_alertlog.log_debug(text            => g_error,
                                  object_name     => 'PK_MATCH',
                                  sub_object_name => 'SET_EPISODE_NEW_PATIENT');
            IF NOT
                pk_adt.delete_patient(i_lang => i_lang, i_prof => i_prof, i_patient => l_old_patient, o_error => o_error)
            THEN
                RAISE g_exception;
            END IF;
            --END ADT-806 Match for new ADT tables  
        
            g_error := 'TRYING TO DELETE MATCH_EPIS';
            DELETE FROM match_epis
             WHERE id_patient = l_old_patient;
        
            g_error := 'TRYING TO DELETE CLIN_RECORD';
            DELETE FROM clin_record
             WHERE id_patient = l_old_patient;
        
            g_error := 'TRYING TO DELETE PAT_ADVANCE_DIRECTIVE';
            ts_pat_advance_directive.del_by(where_clause_in => 'id_patient = ' || l_old_patient);
        
            g_error := 'TRYING TO DELETE PAT_DMGR_HIST';
            DELETE FROM pat_dmgr_hist
             WHERE id_patient = l_old_patient;
        
            g_error := 'TRYING TO DELETE PAT_DOC';
            DELETE FROM pat_doc
             WHERE id_patient = l_old_patient;
        
            g_error := 'TRYING TO DELETE PAT_EXT_SYS';
            DELETE FROM pat_ext_sys
             WHERE id_patient = l_old_patient;
        
            g_error := 'TRYING TO DELETE PAT_FAMILY_MEMBER';
            DELETE FROM pat_family_member
             WHERE id_patient = l_old_patient;
        
            g_error := 'TRYING TO DELETE PAT_GRAFFAR_CRIT';
            DELETE FROM pat_graffar_crit
             WHERE id_patient = l_old_patient;
        
            g_error := 'TRYING TO DELETE PAT_HEALTH_PLAN';
            DELETE FROM pat_health_plan
             WHERE id_patient = l_old_patient;
        
            g_error := 'TRYING TO DELETE PAT_JOB';
            DELETE FROM pat_job
             WHERE id_patient = l_old_patient;
        
            g_error := 'TRYING TO DELETE PAT_MED_DECL';
            DELETE FROM pat_med_decl
             WHERE id_patient = l_old_patient;
        
            g_error := 'TRYING TO DELETE EPIS_TRIAGE_PAT_NECESSITY';
            DELETE FROM epis_triage_pat_necessity a
             WHERE a.id_pat_necessity IN (SELECT b.id_pat_necessity
                                            FROM pat_necessity b
                                           WHERE b.id_patient = l_old_patient);
        
            g_error := 'TRYING TO DELETE PAT_NECESSITY';
            DELETE FROM pat_necessity
             WHERE id_patient = l_old_patient;
        
            g_error := 'TRYING TO DELETE PAT_PERMISSION';
            DELETE FROM pat_permission
             WHERE id_patient = l_old_patient;
        
            g_error := 'TRYING TO DELETE PAT_PHOTO';
            DELETE FROM pat_photo
             WHERE id_patient = l_old_patient;
        
            g_error := 'TRYING TO DELETE PAT_CLI_ATTRIBUTES';
            DELETE FROM pat_cli_attributes
             WHERE id_patient = l_old_patient;
        
            g_error := 'TRYING TO DELETE PAT_SOC_ATTRIBUTES';
            DELETE FROM pat_soc_attributes
             WHERE id_patient = l_old_patient;
        
            g_error := 'TRYING TO DELETE SCH_GROUP';
            DELETE FROM sch_group
             WHERE id_patient = l_old_patient;
        
            g_error := 'TRYING TO DELETE SCHOOL';
            DELETE FROM school
             WHERE id_patient = l_old_patient;
        
            g_error := 'TRYING TO DELETE LENS_PRESC_DET FROM HISTORY';
            DELETE FROM lens_presc_det l
             WHERE l.id_lens_presc_hist IN (SELECT lph.id_lens_presc_hist
                                              FROM lens_presc_hist lph
                                             WHERE lph.id_patient = l_old_patient);
        
            g_error := 'TRYING TO DELETE LENS_PRESC_HIST';
            DELETE FROM lens_presc_hist
             WHERE id_patient = l_old_patient;
        
            g_error := 'TRYING TO DELETE LENS_PRESC_DET FROM CURRENT';
            DELETE FROM lens_presc_det l
             WHERE l.id_lens_presc IN (SELECT lp.id_lens_presc
                                         FROM lens_presc lp
                                        WHERE lp.id_patient = l_old_patient);
        
            g_error := 'TRYING TO DELETE LENS_PRESC';
            DELETE FROM lens_presc
             WHERE id_patient = l_old_patient;
        
            g_error := 'TRYING TO DELETE CRISIS_EPIS';
            DELETE FROM crisis_epis
             WHERE id_patient = l_old_patient;
        
            g_error := 'TRYING TO DELETE task_timeline_ea';
            DELETE FROM task_timeline_ea a
             WHERE a.id_patient = l_old_patient;
        
            g_error := 'TRYING TO DELETE vs_patient_ea';
            DELETE FROM vs_patient_ea a
             WHERE a.id_patient = l_old_patient;
        
            --as tabelas em cima não são envolvidas no bloco begin-exception-end
            --para se detectar quando os delete em cima causam inconsistências
        
            --se este delete suceder é porque o paciente não tem informação clínica associada nem visitas.
            --as tabelas em cima são apenas de atributos não clínico, dados pessoais etc.
            g_error := 'TRYING TO DELETE VIEWER_EHR_EA';
            ts_viewer_ehr_ea.del(l_old_patient);
        
            g_error := 'TRYING TO DELETE PATIENT';
            ts_patient.del_id_patient(id_patient_in => l_old_patient, rows_out => l_rows);
            g_error := 'PROCESS DELETE PATIENT';
            t_data_gov_mnt.process_delete(i_lang, i_prof, 'PATIENT', l_rows, o_error);
        END IF;
    
        g_error := 'CALL TO SET_FIRST_OBS';
        pk_alertlog.log_debug(text => g_error, object_name => 'PK_MATCH', sub_object_name => 'SET_EPISODE_NEW_PATIENT');
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_old_episode,
                                      i_pat                 => NULL,
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
        WHEN l_visitm021_exception THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang,
                                   'T_COMMON_ERROR',
                                   REPLACE(REPLACE(pk_message.get_message(i_lang, 'VISIT_M021'), '@1', l_patient_name),
                                           '@2',
                                           l_epis_type_desc(1)),
                                   g_error,
                                   'ALERT',
                                   'PK_MATCH',
                                   'SET_EPISODE_NEW_PATIENT',
                                   NULL,
                                   'U');
            
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        WHEN l_visitm023_exception THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang,
                                   'T_COMMON_ERROR',
                                   REPLACE(REPLACE(pk_message.get_message(i_lang, 'VISIT_M022'), '@1', l_patient_name),
                                           '@2',
                                           pk_utils.concat_table(l_epis_type_desc, ', ')),
                                   g_error,
                                   'ALERT',
                                   'PK_MATCH',
                                   'SET_EPISODE_NEW_PATIENT',
                                   NULL,
                                   'U');
            
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        WHEN l_visitm022_exception THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang,
                                   'T_COMMON_ERROR',
                                   pk_message.get_message(i_lang, 'VISIT_M023'),
                                   g_error,
                                   'ALERT',
                                   'PK_MATCH',
                                   'SET_EPISODE_NEW_PATIENT',
                                   NULL,
                                   'U');
            
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MATCH',
                                              'SET_EPISODE_NEW_PATIENT',
                                              o_error);
            --pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_episode_new_patient;

BEGIN

    g_epis_hidric_r := 'R';
    g_epis_hidric_e := 'E';
    g_epis_hidric_f := 'F';
    g_epis_hidric_c := 'C';
    g_epis_hidric_i := 'I';

    g_diet_status_r := 'R';
    g_diet_status_i := 'I';
    g_diet_status_c := 'C';

    g_epis_posit_r := 'R';
    g_epis_posit_e := 'E';
    g_epis_posit_f := 'F';
    g_epis_posit_c := 'C';
    g_epis_posit_i := 'I';

END pk_match;
/
