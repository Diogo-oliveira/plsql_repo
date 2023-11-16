/*-- Last Change Revision: $Rev: 2027290 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:46 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_interv_mfr IS

    FUNCTION get_concatenated_interventions
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_professional IN professional.id_professional%TYPE,
        i_id_patient      IN patient.id_patient%TYPE,
        i_schedule        IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR2 IS
        l_res VARCHAR2(4000);
    
        CURSOR c_info IS
            SELECT ipd.id_interv_presc_det, ipd.code_intervention_alias, i.code_intervention, s.flg_status
              FROM schedule_intervention si, schedule s, interv_presc_det ipd, interv_prescription ip, intervention i
             WHERE ipd.id_interv_presc_det = si.id_interv_presc_det
               AND ip.id_interv_prescription = ipd.id_interv_prescription
               AND i.id_intervention = ipd.id_intervention
               AND ip.id_patient = i_id_patient
               AND s.id_schedule = si.id_schedule
               AND s.id_schedule = i_schedule;
        r_info c_info%ROWTYPE;
    
    BEGIN
        FOR r_info IN c_info
        LOOP
            IF l_res IS NULL
            THEN
                l_res := pk_procedures_api_db.get_alias_translation(i_lang, i_prof, r_info.code_intervention, NULL) || ' (' ||
                         pk_schedule_mfr.get_count_and_rank(i_lang,
                                                            i_schedule,
                                                            (CASE r_info.flg_status
                                                                WHEN pk_schedule.g_status_scheduled THEN
                                                                 NULL
                                                                ELSE
                                                                 g_flg_y
                                                            END),
                                                            r_info.id_interv_presc_det) || ')';
            ELSE
                l_res := l_res || ', ' ||
                         pk_procedures_api_db.get_alias_translation(i_lang, i_prof, r_info.code_intervention, NULL) || ' (' ||
                         pk_schedule_mfr.get_count_and_rank(i_lang,
                                                            i_schedule,
                                                            (CASE r_info.flg_status
                                                                WHEN pk_schedule.g_status_scheduled THEN
                                                                 NULL
                                                                ELSE
                                                                 g_flg_y
                                                            END),
                                                            r_info.id_interv_presc_det) || ')';
            END IF;
        END LOOP;
    
        RETURN l_res;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_id PLS_INTEGER;
            BEGIN
                pk_alert_exceptions.register_error(error_name_in       => SQLERRM,
                                                   err_instance_id_out => l_id,
                                                   text_in             => g_error,
                                                   name1_in            => 'OWNER',
                                                   value1_in           => 'ALERT',
                                                   name2_in            => 'PACKAGE',
                                                   value2_in           => 'PK_INTERV_MFR',
                                                   name3_in            => 'FUNCTION',
                                                   value3_in           => 'GET_CONCATENATED_INTERVENTION');
            
            END;
        
    END get_concatenated_interventions;

    FUNCTION update_interv_status
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_statuses(i_det IN interv_presc_det.id_interv_presc_det%TYPE) IS
            SELECT DISTINCT ipd.flg_status
              FROM interv_presc_det ipd
             WHERE ipd.id_interv_presc_det = i_det;
    
        l_flg_status             interv_presc_det.flg_status%TYPE;
        l_current_status         interv_presc_det.flg_status%TYPE;
        l_presc_status           interv_prescription.flg_status%TYPE;
        l_last_status            interv_prescription.flg_status%TYPE;
        l_id_interv_prescription interv_prescription.id_interv_prescription%TYPE;
        l_num_take               interv_presc_det.num_take%TYPE;
        l_num_executed           PLS_INTEGER;
        l_num_scheduled          PLS_INTEGER;
        l_rowids_det             table_varchar;
        l_rowids_presc           table_varchar;
    
    BEGIN
        g_error := 'GET INITIAL DATA';
        SELECT ipd.num_take, ipd.flg_status, ipd.id_interv_prescription
          INTO l_num_take, l_current_status, l_id_interv_prescription
          FROM interv_presc_det ipd
         WHERE ipd.id_interv_presc_det = i_id_interv_presc_det;
    
        g_error := 'CHECK FOR POSSIBLE ACTION';
        IF l_current_status NOT IN (g_flg_status_c, g_flg_status_f, g_flg_status_ext)
        THEN
        
            g_error        := 'GET EXECUTIONS';
            l_num_executed := get_num_exec_mfr(i_lang, i_prof, i_id_interv_presc_det);
        
            g_error         := 'GET SCHEDULES';
            l_num_scheduled := get_num_sessions_schedule(i_lang, i_prof, i_id_interv_presc_det);
        
            g_error := 'FIND NEW STATUS';
            -- All requested sessions are scheduled..
            IF l_num_take = l_num_scheduled
            THEN
                -- ..and finished
                IF l_num_scheduled = l_num_executed
                THEN
                    -- ...set new status as finished.
                    l_flg_status := 'F';
                
                    -- ..and some are executed
                ELSIF l_num_executed > 0
                THEN
                    -- ...set new status as ongoing.
                    l_flg_status := 'E';
                
                    -- ..none are executed
                ELSE
                    -- ...set new status as scheduled.
                    l_flg_status := 'A';
                END IF;
            
                -- Some requested sessions are scheduled..
            ELSIF l_num_scheduled > 0
            THEN
                -- ..and some are executed
                IF l_num_executed > 0
                THEN
                    -- ...set new status as ongoing.
                    l_flg_status := 'E';
                
                    -- ..none are executed
                ELSE
                    -- ...set new status as partially scheduled.
                    l_flg_status := 'P';
                END IF;
            
                -- Nothing is scheduled..
            ELSE
                l_flg_status := 'D';
            END IF;
        
            g_error := 'UPDATE INTERV_PRESC_DET STATUS';
            IF l_current_status != g_flg_status_i
            THEN
                ts_interv_presc_det.upd(id_interv_presc_det_in => i_id_interv_presc_det,
                                        flg_status_in          => l_flg_status,
                                        flg_status_nin         => TRUE,
                                        rows_out               => l_rowids_det);
            
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'INTERV_PRESC_DET',
                                              i_rowids     => l_rowids_det,
                                              o_error      => o_error);
            END IF;
        
        END IF;
    
        g_error := 'GET PRESCRIPTION STATUSES';
        FOR elem IN c_statuses(i_id_interv_presc_det)
        LOOP
            IF elem.flg_status = 'E'
            THEN
                l_presc_status := 'E';
                EXIT;
            
            ELSIF elem.flg_status = 'F'
                  AND elem.flg_status = nvl(l_last_status, elem.flg_status)
            THEN
                l_presc_status := 'F';
            
            ELSIF elem.flg_status = 'C'
                  AND elem.flg_status = nvl(l_last_status, elem.flg_status)
            THEN
                l_presc_status := 'C';
            
            ELSIF elem.flg_status = 'D'
                  AND elem.flg_status = nvl(l_last_status, elem.flg_status)
            THEN
                l_presc_status := 'D';
            
            ELSE
                l_presc_status := 'P';
            END IF;
        
            l_last_status := elem.flg_status;
        END LOOP;
    
        g_error := 'UPDATE INTERV_PRESCRIPTION STATUS';
        ts_interv_prescription.upd(id_interv_prescription_in => l_id_interv_prescription,
                                   flg_status_in             => l_presc_status,
                                   flg_status_nin            => TRUE,
                                   id_prof_cancel_in         => CASE l_presc_status
                                                                    WHEN 'C' THEN
                                                                     i_prof.id
                                                                    ELSE
                                                                     NULL
                                                                END,
                                   dt_cancel_tstz_in         => CASE l_presc_status
                                                                    WHEN 'C' THEN
                                                                     g_sysdate_tstz
                                                                    ELSE
                                                                     NULL
                                                                END,
                                   rows_out                  => l_rowids_presc);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'INTERV_PRESCRIPTION',
                                      i_rowids     => l_rowids_presc,
                                      o_error      => o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_ret       BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_INTERV_MFR', 'UPDATE_INTERV_STATUS');
            
                l_ret := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                pk_utils.undo_changes;
            
                RETURN FALSE;
            END;
    END update_interv_status;

    FUNCTION get_icon_state_mfr
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR2 IS
    
        l_res sys_domain.img_name%TYPE;
        CURSOR c_state IS
            SELECT DISTINCT si.flg_state,
                            pk_sysdomain.get_img(i_lang, 'SCHEDULE_INTERVENTION.FLG_STATE', si.flg_state) icon
              FROM schedule_intervention si
             WHERE si.id_schedule = i_schedule;
    
        r_state c_state%ROWTYPE;
    BEGIN
        OPEN c_state;
        FETCH c_state
            INTO r_state;
        IF c_state%FOUND
        THEN
            l_res := r_state.icon;
        END IF;
        CLOSE c_state;
    
        RETURN l_res;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_id PLS_INTEGER;
            BEGIN
                pk_alert_exceptions.register_error(error_name_in       => SQLERRM,
                                                   err_instance_id_out => l_id,
                                                   text_in             => g_error,
                                                   name1_in            => 'OWNER',
                                                   value1_in           => 'ALERT',
                                                   name2_in            => 'PACKAGE',
                                                   value2_in           => 'PK_INTERV_MFR',
                                                   name3_in            => 'FUNCTION',
                                                   value3_in           => 'GET_ICON_STATE_MFR');
            
                RETURN NULL;
            END;
    END;

    FUNCTION get_state_mfr
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR2 IS
    
        l_res sys_domain.img_name%TYPE;
        CURSOR c_state IS
            SELECT DISTINCT si.flg_state,
                            pk_sysdomain.get_img(i_lang, 'SCHEDULE_INTERVENTION.FLG_STATE', si.flg_state) icon
              FROM schedule_intervention si
             WHERE si.id_schedule = i_schedule;
    
        r_state c_state%ROWTYPE;
    BEGIN
        OPEN c_state;
        FETCH c_state
            INTO r_state;
        IF c_state%FOUND
        THEN
            l_res := r_state.flg_state;
        END IF;
        CLOSE c_state;
    
        RETURN l_res;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_id PLS_INTEGER;
            BEGIN
                pk_alert_exceptions.register_error(error_name_in       => SQLERRM,
                                                   err_instance_id_out => l_id,
                                                   text_in             => g_error,
                                                   name1_in            => 'OWNER',
                                                   value1_in           => 'ALERT',
                                                   name2_in            => 'PACKAGE',
                                                   value2_in           => 'PK_INTERV_MFR',
                                                   name3_in            => 'FUNCTION',
                                                   value3_in           => 'GET_STATE_MFR');
            
                RETURN NULL;
            END;
    END;

    FUNCTION get_num_exec_mfr
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE
    ) RETURN NUMBER IS
    
        l_result NUMBER := 0;
    
    BEGIN
    
        SELECT COUNT(*)
          INTO l_result
          FROM interv_presc_plan ipp
         WHERE ipp.id_interv_presc_det = i_id_interv_presc_det
           AND ipp.flg_status IN (g_flg_status_finalizado, g_flg_status_plan_faltou /*g_flg_plan_cancelled*/);
    
        RETURN l_result;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_id PLS_INTEGER;
            BEGIN
                pk_alert_exceptions.register_error(error_name_in       => SQLERRM,
                                                   err_instance_id_out => l_id,
                                                   text_in             => g_error,
                                                   name1_in            => 'OWNER',
                                                   value1_in           => 'ALERT',
                                                   name2_in            => 'PACKAGE',
                                                   value2_in           => 'PK_INTERV_MFR',
                                                   name3_in            => 'FUNCTION',
                                                   value3_in           => 'GET_NUM_EXEC_MFR');
            
                RETURN NULL;
            END;
    END;

    FUNCTION get_num_sessions_schedule
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE
    ) RETURN NUMBER IS
        l_result PLS_INTEGER := 0;
    
    BEGIN
        SELECT COUNT(si.id_schedule_intervention)
          INTO l_result
          FROM schedule_intervention si, schedule s
         WHERE si.id_schedule = s.id_schedule
           AND si.id_interv_presc_det = i_id_interv_presc_det
           AND s.flg_status NOT IN (g_flg_status_sched_c, g_sched_temp)
           AND si.flg_state != g_flg_state_c;
    
        RETURN l_result;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_id PLS_INTEGER;
            BEGIN
                pk_alert_exceptions.register_error(error_name_in       => SQLERRM,
                                                   err_instance_id_out => l_id,
                                                   text_in             => g_error,
                                                   name1_in            => 'OWNER',
                                                   value1_in           => 'ALERT',
                                                   name2_in            => 'PACKAGE',
                                                   value2_in           => 'PK_INTERV_MFR',
                                                   name3_in            => 'FUNCTION',
                                                   value3_in           => 'GET_NUM_SESSIONS_SCHEDULE');
            
                RETURN NULL;
            END;
    END;

    FUNCTION get_icon_name
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE
    ) RETURN VARCHAR2 IS
    
        l_icon sys_domain.img_name%TYPE;
    BEGIN
        SELECT decode(ipd.flg_referral,
                      g_flg_referral_reserved,
                      pk_sysdomain.get_img(i_lang, 'INTERV_PRESC_DET.FLG_REFERRAL', ipd.flg_referral),
                      g_flg_referral_sent_s,
                      pk_sysdomain.get_img(i_lang, 'INTERV_PRESC_DET.FLG_REFERRAL', ipd.flg_referral),
                      g_flg_referral_sent_i,
                      pk_sysdomain.get_img(i_lang, 'INTERV_PRESC_DET.FLG_REFERRAL', ipd.flg_referral),
                      pk_sysdomain.get_img(i_lang,
                                           g_flg_status,
                                           decode(ipd.flg_status, g_flg_status_d, g_flg_status_p, ipd.flg_status)))
          INTO l_icon
          FROM interv_presc_det ipd
         WHERE ipd.id_interv_presc_det = i_id_interv_presc_det;
    
        RETURN l_icon;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_id PLS_INTEGER;
            BEGIN
                pk_alert_exceptions.register_error(error_name_in       => SQLERRM,
                                                   err_instance_id_out => l_id,
                                                   text_in             => g_error,
                                                   name1_in            => 'OWNER',
                                                   value1_in           => 'ALERT',
                                                   name2_in            => 'PACKAGE',
                                                   value2_in           => 'PK_INTERV_MFR',
                                                   name3_in            => 'FUNCTION',
                                                   value3_in           => 'GET_ICON_NAME');
            
                RETURN NULL;
            END;
        
    END;

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
                         O_COMPL_DIAG - 1ª consulta: justificação do P1 + tipo consulta
                                    subsequente: tipo consulta
                         O_PROF_NAME - nome do médico da consulta
                                 O_PROF_SPEC - especialidade do médico da consulta
                                 O_NKDA - indicação de "Não são conhecidas alergias a fármacos"
                                 O_EPISODE - nº episódio no sistema externo e título
                                 O_CLIN_REC - nº do processo clínico na instituição onde se está
                                  a aceder à aplicação (SYS_CONFIG) e título
                         O_LOCATION - localização e título
                         O_DT_SCHED - hora da consulta (HH:MM) e título
                         O_EFECTIV - hora da efectivação (HH:MM) e título
                         O_ATEND - hora de atendimento médico (HH:MM) e título
                         O_WAIT -  título
                         O_PAT_PHOTO - URL da directoria da foto do doente
                         O_ALLERGY - nº de alergias
                         O_PREV_EPIS - nº de episódios de consulta anteriores
                         O_RELEV_DISEASE - nº de doenças relevantes
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
          ALTERAÇÃO: CRS 2006/09/08 Indicação do centro de saúde em q está inscrito
                RdSN 2006/11/02 Acrescentados 6 parâmetros de saída correspondentes aos
                                shortcuts a serem chamados quando não existe episódio
                     ASM 2007/01/17 Acrescentado novo parâmetro de saída para indicar se o paciente
                                 não tem alergias a fármacos - "NO KNOWN DRUG ALLERGIES"
                     Luís Gaspar, 2007-Nov-19. Retorna a descrição do evento (sch_event) onde dantes retornava mensagens (HEADER_M001, HEADER_M001)
          NOTAS: Conforme o tipo de episódio, o cabeçalho da aplicação pode ser diferente
        
        *********************************************************************************/
        l_desc_event      pk_translation.t_desc_translation;
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
        l_dept            VARCHAR2(4000);
        l_pat_ndo         VARCHAR2(4000);
        l_pat_nd_icon     VARCHAR2(4000);
        err_weeks_pregnancy EXCEPTION;
    
        CURSOR c_name IS
            SELECT pk_patient.get_pat_name(i_lang, i_prof, pat.id_patient, NULL) name,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, pat.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, pat.id_patient) pat_nd_icon,
                   pk_translation.get_translation(i_lang, hpn.code_health_plan) desc_translation,
                   crn.num_clin_record,
                   pk_sysdomain.get_domain('PATIENT.GENDER.ABBR', pat.gender, i_lang) gender, -- Eduardo Lourenco - 2007/Dez/11
                   tab_age.months,
                   tab_age.days,
                   decode(pk_patphoto.check_blob(pat.id_patient),
                          'N',
                          '',
                          pk_patphoto.get_pat_photo(i_lang, i_prof, pat.id_patient, i_id_episode, i_id_sched)) patphoto,
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
                   -- RdSN 2006/11/24 Para os utilizadores que não têm registo de idade, é retornada uma idade aproximada tendo em conta a sua DT_BIRTH
                   (SELECT nvl(pat1.age, trunc(months_between(SYSDATE, pat1.dt_birth) / 12, 0)) age,
                           months_between(SYSDATE, pat1.dt_birth) months,
                           (SYSDATE - pat1.dt_birth) days,
                           pat1.id_patient
                      FROM patient pat1
                     WHERE pat1.id_patient = i_id_pat
                       AND pat1.flg_status = g_patient_active) tab_age
             WHERE pat.id_patient = i_id_pat
               AND php.id_patient(+) = pat.id_patient
               AND hpn.id_health_plan(+) = php.id_health_plan
               AND php.flg_status(+) = g_hplan_active
               AND php.flg_default(+) = g_default_hplan_y
               AND php.id_institution(+) = i_prof.institution
               AND crn.id_patient(+) = pat.id_patient
               AND crn.id_institution(+) = l_instit_sched
               AND tab_age.id_patient = pat.id_patient
               AND pca.id_patient(+) = pat.id_patient
               AND pbg.id_patient(+) = pat.id_patient
               AND pbg.flg_status(+) = g_pat_blood_active
               AND sd.id_language(+) = i_lang
               AND sd.code_domain(+) = 'PAT_BLOOD_GROUP.FLG_BLOOD_RHESUS'
               AND sd.val(+) = pbg.flg_blood_rhesus
               AND sd.domain_owner(+) = pk_sysdomain.k_default_schema
               AND sd.id_language(+) = i_lang
               AND i.id_institution(+) = crn.id_instit_enroled;
        --
        CURSOR c_epis IS
            SELECT epis.id_epis_type,
                   e.id_episode,
                   p.name,
                   p.id_professional,
                   nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) desc_room,
                   pk_translation.get_translation(i_lang, sp.code_speciality) desc_spec,
                   decode(i.abbreviation, NULL, NULL, '; ' || i.abbreviation) abbreviation,
                   nvl(pk_date_utils.to_char_insttimezone(i_prof, s.dt_begin_tstz, 'HH24:MI"h"'), '---') dt_target,
                   pk_translation.get_translation(i_lang, cs.code_clinical_service) clin_serv,
                   pk_schedule_common.get_translation_alias(i_lang, i_prof, se.id_sch_event, se.code_sch_event) desc_event,
                   s.id_instit_requested,
                   ehp.id_pat_health_plan
              FROM schedule              s,
                   schedule_intervention si,
                   epis_info             e,
                   episode               epis,
                   room                  r,
                   professional          p,
                   speciality            sp,
                   institution           i,
                   clinical_service      cs,
                   epis_health_plan      ehp,
                   sch_event             se
             WHERE s.id_schedule = i_id_sched
               AND s.flg_status != g_sched_cancel
               AND si.id_schedule = s.id_schedule
               AND e.id_schedule = s.id_schedule
               AND e.id_episode = epis.id_episode
               AND r.id_room = e.id_room
               AND p.id_professional(+) = e.id_professional
               AND sp.id_speciality(+) = p.id_speciality
               AND s.id_instit_requested = i.id_institution
               AND cs.id_clinical_service = epis.id_cs_requested
               AND ehp.id_episode(+) = e.id_episode
               AND se.id_sch_event(+) = s.id_sch_event;
    
        -- JM 28/08/08 Physiatry interventions are not related to table schedule_outp
        CURSOR c_sched IS
            SELECT pk_episode.get_epis_type(i_lang, ip.id_episode) epis_type,
                   pk_prof_utils.get_name(i_lang, si.id_prof_assigned) name,
                   si.id_prof_assigned id_professional,
                   pk_translation.get_translation(i_lang, sp.code_speciality) desc_spec,
                   decode(i.abbreviation, NULL, NULL, '; ' || i.abbreviation) abbreviation,
                   nvl(pk_date_utils.to_char_insttimezone(i_prof, ipp.dt_plan_tstz, 'HH24:MI"h"'), '---') dt_target,
                   pk_translation.get_translation(i_lang, cs.code_clinical_service) clin_serv,
                   pk_schedule_common.get_translation_alias(i_lang, i_prof, se.id_sch_event, se.code_sch_event) desc_event,
                   s.id_instit_requested
              FROM schedule              s,
                   schedule_intervention si,
                   interv_presc_plan     ipp,
                   interv_presc_det      ipd,
                   interv_prescription   ip,
                   speciality            sp,
                   institution           i,
                   clinical_service      cs,
                   dep_clin_serv         dcs,
                   sch_event             se,
                   professional          p
             WHERE s.id_schedule = i_id_sched
               AND s.flg_status != g_sched_cancel
               AND si.id_schedule = s.id_schedule
               AND si.id_schedule_intervention = ipp.id_schedule_intervention(+)
               AND i.id_institution = s.id_instit_requested
               AND dcs.id_dep_clin_serv = s.id_dcs_requested
               AND cs.id_clinical_service = dcs.id_clinical_service
               AND se.id_sch_event(+) = s.id_sch_event
               AND si.id_interv_presc_det = ipd.id_interv_presc_det
               AND ip.id_interv_prescription = ipd.id_interv_prescription
               AND p.id_professional = si.id_prof_assigned
               AND p.id_speciality = sp.id_speciality(+);
    
        CURSOR c_habit IS
            SELECT COUNT(*)
              FROM pat_habit
             WHERE id_patient = i_id_pat
               AND flg_status != g_pat_habit_cancel;
    
        -- <DENORM_EPISODE_JOSE_BRITO>
        CURSOR c_prev_epis_outp IS
            SELECT COUNT(*)
              FROM episode e --, visit v
             WHERE e.id_patient = i_id_pat --v.id_visit = e.id_visit
                  --AND v.id_patient = i_id_pat
               AND pk_date_utils.trunc_insttimezone(i_prof, e.dt_begin_tstz, 'DD') <=
                   pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz, 'DD')
               AND e.flg_status = g_epis_stat_inactive;
    
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
               AND flg_status != g_pat_notes_cancel;
    
        CURSOR c_fam_prof IS
            SELECT pfp.id_professional, p.nick_name
              FROM patient pat, pat_family_prof pfp, professional p
             WHERE pat.id_patient = i_id_pat
               AND pfp.id_pat_family = pat.id_pat_family
               AND p.id_professional = pfp.id_professional;
    
        r_fam_prof c_fam_prof%ROWTYPE;
    
        CURSOR c_pat_hplan IS
            SELECT pk_translation.get_translation(i_lang, hpn.code_health_plan) desc_translation, num_health_plan
              FROM pat_health_plan php, health_plan hpn
             WHERE id_pat_health_plan = l_pat_hplan
               AND hpn.id_health_plan = php.id_health_plan;
    
        CURSOR c_dept
        (
            i_lang       IN language.id_language%TYPE,
            i_id_episode IN episode.id_episode%TYPE
        ) IS
            SELECT pk_translation.get_translation(i_lang, d.code_department)
              FROM room r, department d
             WHERE d.id_department = r.id_department
               AND r.id_room IN (SELECT ei.id_room
                                   FROM epis_info ei
                                  WHERE id_episode = i_id_episode);
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
        g_error        := 'GET CONFIGURATIONS';
        g_epis_consult := pk_sysconfig.get_config('ID_EPIS_TYPE_CONSULT', i_prof);
        g_epis_cs      := pk_sysconfig.get_config('ID_EPIS_TYPE_CS', i_prof);
        g_months_sign  := pk_sysconfig.get_config('MONTHS_SIGN', i_prof);
        g_days_sign    := pk_sysconfig.get_config('DAYS_SIGN', i_prof);
    
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
        IF (i_id_sched IS NOT NULL)
        THEN
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
        END IF;
    
        IF (i_id_sched IS NOT NULL)
        THEN
            -- LG, 2006-OUT-17. in the clinics we may have searched patients with no schedule
            IF g_found
            THEN
                -- Agendamento ainda ñ tem episódio (ñ foi efectivado)
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
        l_ret   := pk_episode.get_nkda_label(i_lang, i_prof, i_id_pat, o_nkda, o_error);
    
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
        g_error   := 'OPEN C_ALLERGY';
        l_allergy := pk_allergy.get_count_allergy(i_lang, i_id_pat, o_error);
    
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
        
        ELSIF l_epis_type = g_epis_fis
        THEN
            -- Fisiatria
            o_application := NULL; --WO 17494: dada a inexistência de informação sobre o valor que a variável deva assumir, foi registado no código para que no futuro seja mais simples alterar.
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
        OPEN c_prev_epis_outp;
        FETCH c_prev_epis_outp
            INTO l_prev_epis_outp;
        CLOSE c_prev_epis_outp;
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
        -- Nome do utente, subsistema de saúde, nº processo clínico, sexo e idade
        g_error := 'GET CURSOR C_NAME ';
        OPEN c_name;
        FETCH c_name
            INTO o_name,
                 l_pat_ndo,
                 l_pat_nd_icon,
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
            RAISE g_exception;
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
                l_ret   := pk_woman_health.get_pregnancy_weeks(i_lang, i_prof, i_id_pat, l_preg_weeks, o_error);
                IF l_ret = FALSE
                THEN
                    RAISE err_weeks_pregnancy;
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
    
        IF l_epis_type = g_epis_inpt
        THEN
            OPEN c_dept(i_lang, i_id_episode);
            FETCH c_dept
                INTO l_dept;
        
            o_compl_diag := pk_translation.get_translation(i_lang, 'EPIS_TYPE.CODE_EPIS_TYPE.' || l_epis_type);
        
            IF o_compl_diag IS NOT NULL
               AND c_dept%FOUND
            THEN
                o_compl_diag := o_compl_diag || ' (' || l_dept || ')';
            END IF;
        
            CLOSE c_dept;
        ELSE
            o_compl_diag := nvl(l_desc_event, pk_message.get_message(i_lang, 'HEADER_M006')) || ': ' || l_clin_serv;
        END IF;
    
        IF (i_id_episode IS NOT NULL AND l_epis_flg_ehr != 'S')
        THEN
            -- LG, 2006-OUT-17. in the clinics we may have searched patients with no episode
            g_error := 'CALL TO GET_EPIS_EXT';
            IF NOT pk_episode.get_epis_ext(i_lang       => i_lang,
                                           i_id_episode => i_id_episode,
                                           i_prof       => i_prof,
                                           o_dt_efectiv => l_dt_efectiv,
                                           o_dt_atend   => l_dt_atend,
                                           o_episode    => l_episode,
                                           o_error      => o_error)
            THEN
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
        IF i_id_episode IS NULL
        THEN
            l_area := 'CLINPROC';
        ELSE
            l_area := 'SOAP';
        END IF;
    
        o_shcut_habits        := pk_sysconfig.get_config('SHORTCUT_' || l_area || '_HABITS', i_prof);
        o_shcut_allergies     := pk_sysconfig.get_config('SHORTCUT_' || l_area || '_ALLERGIES', i_prof);
        o_shcut_episodes      := pk_sysconfig.get_config('SHORTCUT_' || l_area || '_EPISODES', i_prof);
        o_shcut_bloodtype     := pk_sysconfig.get_config('SHORTCUT_' || l_area || '_BLOODTYPE', i_prof);
        o_shcut_relevdiseases := pk_sysconfig.get_config('SHORTCUT_' || l_area || '_RELEVDISEASES', i_prof);
        o_shcut_relevnotes    := pk_sysconfig.get_config('SHORTCUT_' || l_area || '_RELEVNOTES', i_prof);
        o_shcut_photo         := pk_sysconfig.get_config('SHORTCUT_PHOTO', i_prof);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_INTERV_MFR', 'CREATE_INTERV_PRESC');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_types.open_my_cursor(o_episode);
                pk_types.open_my_cursor(o_clin_rec);
                pk_types.open_my_cursor(o_location);
                pk_types.open_my_cursor(o_sched);
                pk_types.open_my_cursor(o_atend);
                pk_types.open_my_cursor(o_efectiv);
                pk_types.open_my_cursor(o_wait);
            
                RETURN FALSE;
            END;
    END get_epis_header;

    FUNCTION get_plan_status_schedule
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE
        
    ) RETURN VARCHAR2 IS
        CURSOR c_schi IS
            SELECT nvl(ipp.flg_status, 'F') flg_status
              FROM schedule_intervention si, interv_presc_plan ipp
             WHERE si.id_schedule = i_id_schedule
               AND si.id_schedule_intervention = ipp.id_schedule_intervention(+)
               AND ipp.flg_status(+) NOT IN (g_flg_plan_completed, g_flg_plan_cancelled);
    
        r_schi c_schi%ROWTYPE;
    
    BEGIN
        OPEN c_schi;
        FETCH c_schi
            INTO r_schi;
        IF r_schi.flg_status = 'F'
        THEN
            RETURN 'Y';
        ELSE
            RETURN 'N';
        END IF;
        CLOSE c_schi;
    
    END get_plan_status_schedule;

    FUNCTION get_prof_alloc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE
    ) RETURN VARCHAR2 IS
        l_prof_names VARCHAR2(4000);
    BEGIN
        SELECT substr(names, 0, length(names) - 2)
          INTO l_prof_names
          FROM (SELECT COUNT(*) num,
                       concatenate(pk_prof_utils.get_name_signature(i_lang, i_prof, ipa.id_professional) || '; ') names
                  FROM interv_prof_alloc ipa
                 WHERE ipa.flg_available = 'Y'
                   AND ipa.id_interv_presc_det = i_id_interv_presc_det);
    
        RETURN l_prof_names;
    END get_prof_alloc;

    FUNCTION get_prof_id_alloc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE
    ) RETURN VARCHAR2 IS
        l_prof_ids VARCHAR2(4000);
    BEGIN
        SELECT concatenate(ipa.id_professional || '|')
          INTO l_prof_ids
          FROM interv_prof_alloc ipa
         WHERE ipa.flg_available = 'Y'
           AND ipa.id_interv_presc_det = i_id_interv_presc_det;
    
        RETURN l_prof_ids;
    END get_prof_id_alloc;

    FUNCTION get_physiatry_area
    (
        i_lang            IN language.id_language%TYPE,
        i_id_intervention IN interv_presc_det.id_intervention%TYPE
    ) RETURN VARCHAR2 IS
        l_ret VARCHAR2(4000);
    BEGIN
        SELECT pk_translation.get_translation(i_lang, pa.code_physiatry_area)
          INTO l_ret
          FROM intervention i, physiatry_area pa, interv_physiatry_area ipa
         WHERE ipa.id_physiatry_area = pa.id_physiatry_area
           AND i.id_intervention = i_id_intervention;
    
        RETURN l_ret;
    END get_physiatry_area;

    FUNCTION get_interv_conditions
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        o_conditions OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        OPEN o_conditions FOR
            SELECT *
              FROM (SELECT id_interv_condition,
                           pk_translation.get_translation(i_lang, code_interv_condition) condition_name
                      FROM (SELECT DISTINCT icn.id_interv_condition, icn.code_interv_condition
                              FROM interv_condition icn, interv_condition_icf ici, icf_soft_inst isi, icf i
                             WHERE rownum > 0
                               AND icn.id_interv_condition = ici.id_interv_condition
                               AND icn.flg_available = g_flg_y
                               AND isi.flg_available = g_flg_y
                               AND isi.id_icf = ici.id_icf
                               AND i.id_icf = ici.id_icf
                               AND i.flg_type = 'T'
                               AND nvl(ici.id_institution, 0) IN (0, i_prof.institution)
                               AND nvl(ici.id_software, 0) IN (0, i_prof.software)
                               AND nvl(isi.id_institution, 0) IN (0, i_prof.institution)
                               AND nvl(isi.id_software, 0) IN (0, i_prof.software)
                               AND nvl(ici.id_professional, 0) IN (0, i_prof.id)))
             WHERE condition_name IS NOT NULL
             ORDER BY condition_name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_INTERV_MFR', 'GET_INTERV_CONDITIONS');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_types.open_my_cursor(o_conditions);
            
                RETURN FALSE;
            END;
    END get_interv_conditions;

    FUNCTION get_icf_by_conditions
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_idcondition IN interv_condition.id_interv_condition%TYPE,
        o_categories  OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        OPEN o_categories FOR
            SELECT i.id_icf,
                   REPLACE(sys_connect_by_path(coding, '/'), '/', '') coding,
                   pk_translation.get_translation(i_lang, i.code_icf) icf_name,
                   substr(sys_connect_by_path(i.id_icf, '|'), 2) parent_hierarchy
              FROM icf i
             WHERE i.id_icf IN (SELECT i.id_icf
                                  FROM interv_condition_icf i
                                  JOIN icf_soft_inst isi
                                    ON isi.id_icf = i.id_icf
                                 WHERE id_interv_condition = i_idcondition
                                   AND i.flg_available = g_flg_y
                                   AND nvl(i.id_institution, 0) IN (0, i_prof.institution)
                                   AND nvl(i.id_software, 0) IN (0, i_prof.software)
                                   AND nvl(id_professional, 0) IN (0, i_prof.id)
                                   AND nvl(isi.id_institution, 0) IN (0, i_prof.institution)
                                   AND nvl(isi.id_software, 0) IN (0, i_prof.software))
               AND i.flg_available = g_flg_y
            CONNECT BY PRIOR i.id_icf = id_icf_parent
             START WITH i.id_icf IN (SELECT t.id_icf
                                       FROM icf t
                                      WHERE t.flg_type = g_flg_icf_component);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_INTERV_MFR', 'GET_ICF_BY_CONDITIONS');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_types.open_my_cursor(o_categories);
            
                RETURN FALSE;
            END;
    END get_icf_by_conditions;

    FUNCTION get_icf_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_idicfparent    IN icf.id_icf_parent%TYPE,
        o_id_parent      OUT icf.id_icf%TYPE,
        o_id_grandparent OUT icf.id_icf%TYPE,
        o_icf            OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_type      icf.flg_type%TYPE;
        l_idgrandparent icf.id_icf%TYPE;
    BEGIN
        o_id_parent := i_idicfparent;
        IF i_idicfparent IS NULL -- components
        THEN
            OPEN o_icf FOR
                SELECT *
                  FROM (SELECT id_icf,
                               NULL coding,
                               pk_translation.get_translation(i_lang, code_icf) icf_name,
                               connect_by_isleaf folha,
                               LEVEL cif_level,
                               i_idicfparent id_parent,
                               l_idgrandparent id_grandparent,
                               NULL parent_hierarchy
                          FROM icf i
                         WHERE id_icf_parent IS NULL
                           AND flg_available = g_flg_y
                        CONNECT BY PRIOR id_icf = id_icf_parent
                         START WITH id_icf IN (SELECT t.id_icf
                                                 FROM icf t
                                                WHERE t.flg_type = g_flg_icf_component))
                 WHERE icf_name IS NOT NULL
                 ORDER BY coding;
        ELSE
            SELECT flg_type
              INTO l_flg_type
              FROM icf
             WHERE id_icf = i_idicfparent;
        
            SELECT id_icf_parent
              INTO l_idgrandparent
              FROM icf
             WHERE id_icf = i_idicfparent;
            o_id_grandparent := l_idgrandparent;
            IF l_flg_type = g_flg_icf_component -- componente
            THEN
                OPEN o_icf FOR
                    SELECT *
                      FROM (SELECT id_icf,
                                   decode(flg_type,
                                          g_flg_icf_component,
                                          NULL,
                                          g_flg_icf_chapter,
                                          coding,
                                          REPLACE(sys_connect_by_path(coding, '/'), '/', '')) coding,
                                   pk_translation.get_translation(i_lang, code_icf) icf_name,
                                   connect_by_isleaf folha,
                                   LEVEL cif_level,
                                   i_idicfparent id_parent,
                                   l_idgrandparent id_grandparent,
                                   NULL parent_hierarchy
                              FROM icf
                             WHERE id_icf_parent = i_idicfparent
                               AND flg_available = g_flg_y
                            CONNECT BY PRIOR id_icf = id_icf_parent
                             START WITH id_icf IN (SELECT t.id_icf
                                                     FROM icf t
                                                    WHERE t.flg_type = g_flg_icf_component))
                     WHERE icf_name IS NOT NULL
                     ORDER BY coding;
            
            ELSE
                -- category 
                OPEN o_icf FOR
                    SELECT *
                      FROM (SELECT cif.id_icf,
                                   cif.coding,
                                   cif.icf_name,
                                   cif.folha,
                                   cif_level,
                                   i_idicfparent    id_parent,
                                   l_idgrandparent  id_grandparent,
                                   parent_hierarchy
                              FROM (SELECT id_icf,
                                           decode(flg_type,
                                                  g_flg_icf_component,
                                                  NULL,
                                                  g_flg_icf_chapter,
                                                  coding,
                                                  REPLACE(sys_connect_by_path(coding, '/'), '/', '')) coding,
                                           pk_translation.get_translation(i_lang, code_icf) icf_name,
                                           connect_by_isleaf folha,
                                           LEVEL cif_level,
                                           substr(sys_connect_by_path(id_icf, '|'), 2) parent_hierarchy
                                      FROM icf
                                     WHERE id_icf_parent = i_idicfparent
                                       AND flg_available = g_flg_y
                                    CONNECT BY PRIOR id_icf = id_icf_parent
                                     START WITH id_icf IN (SELECT t.id_icf
                                                             FROM icf t
                                                            WHERE t.flg_type = g_flg_icf_component)) cif)
                     WHERE icf_name IS NOT NULL
                     ORDER BY coding;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_INTERV_MFR', 'GET_ICF_LIST');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_types.open_my_cursor(o_icf);
            
                RETURN FALSE;
            END;
    END get_icf_list;

    /**********************************************************************************************
    * Returns the details for the ICF Assessment section of the summary page
    * This functions can by filter by episode, patient, doc area, start and end date 
    *
    * @param i_lang                Language ID
    * @param i_prof                Professional's details
    * @param i_scope               'E' -> Episode | 'P' -> Patient
    * @param i_id_scope            Value
    * @param o_assessment          Assessment details
    * @param o_error               Error message
    *
    * @return                      True on success, false otherwise
    *                        
    * @author                      Pedro Henriques
    * @version                     2.7.1.5
    * @since                       2017/10/09
    **********************************************************************************************/
    FUNCTION get_evaluation_icf_cda
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope      IN VARCHAR2,
        i_id_scope   IN NUMBER,
        o_assessment OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_patient episode.id_patient%TYPE;
        l_id_episode episode.id_episode%TYPE;
    BEGIN
    
        CASE i_scope
            WHEN g_rehab_assessment_scope_p THEN
                l_id_patient := i_id_scope;
            WHEN g_rehab_assessment_scope_e THEN
                l_id_episode := i_id_scope;
            ELSE
                RETURN NULL;
        END CASE;
    
        OPEN o_assessment FOR
            SELECT pk_translation.get_translation(i_lang, i.code_icf) interv_name,
                   pk_interv_mfr.get_full_coding(i_lang, i_prof, ieicf.id_icf, ie.id_interv_evaluation) interv_code,
                   ieicf.notes
              FROM interv_evaluation ie
              JOIN episode e
                ON e.id_episode = ie.id_episode
              JOIN interv_evaluation_icf ieicf
                ON ie.id_interv_evaluation = ieicf.id_interv_evaluation
              JOIN icf i
                ON i.id_icf = ieicf.id_icf
             WHERE ie.flg_type = g_flg_typeevaluation_icf
               AND ie.flg_status != g_status_eval_canc
               AND ((l_id_episode IS NOT NULL AND e.id_episode = l_id_episode) OR
                   (l_id_patient IS NOT NULL AND l_id_patient = e.id_patient))
             ORDER BY ie.dt_interv_evaluation_tstz DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_INTERV_MFR', 'GET_EVALUATION_ICF_INT');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_types.open_my_cursor(o_assessment);
            
                RETURN FALSE;
            END;
    END get_evaluation_icf_cda;

    FUNCTION get_evaluation_icf_int
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN episode.id_episode%TYPE,
        i_id_patient        IN patient.id_patient%TYPE,
        i_doc_area          IN doc_area.id_doc_area%TYPE,
        i_start_date        IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_end_date          IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_doc_area_register OUT pk_types.cursor_type,
        o_doc_area_val      OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rehab_icf_scope sys_config.value%TYPE;
        l_id_patient      episode.id_patient%TYPE;
        l_id_episode      episode.id_episode%TYPE;
        l_id_epis_origin  episode.id_prev_episode%TYPE;
        l_id_visit        episode.id_visit%TYPE;
    BEGIN
    
        l_rehab_icf_scope := pk_sysconfig.get_config(i_code_cf => 'REHAB_ASSESSMENTS_SCOPE', i_prof => i_prof);
    
        CASE l_rehab_icf_scope
            WHEN g_rehab_assessment_scope_p THEN
                l_id_patient := i_id_patient;
            WHEN g_rehab_assessment_scope_e THEN
                l_id_episode := i_id_episode;
            WHEN g_rehab_assessment_scope_o THEN
                SELECT e.id_prev_episode
                  INTO l_id_epis_origin
                  FROM episode e
                 WHERE e.id_episode = i_id_episode;
            WHEN g_rehab_assessment_scope_v THEN
                SELECT e.id_visit
                  INTO l_id_visit
                  FROM episode e
                 WHERE e.id_episode = i_id_episode;
        END CASE;
    
        OPEN o_doc_area_register FOR
            SELECT ie.id_interv_evaluation id_epis_documentation, -- Misleading alias
                   NULL id_doc_template, --
                   pk_date_utils.get_timestamp_str(i_lang, i_prof, ie.dt_interv_evaluation_tstz, NULL) dt_creation,
                   pk_date_utils.dt_chr_hour_tsz(i_lang, ie.dt_interv_evaluation_tstz, i_prof) || ' / ' ||
                   pk_date_utils.dt_chr_tsz(i_lang, ie.dt_interv_evaluation_tstz, i_prof) dt_register,
                   ie.id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ie.id_professional) nick_name,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, ie.id_professional, NULL, NULL) desc_speciality,
                   i_doc_area id_doc_area,
                   ie.flg_status,
                   pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS', ie.flg_status, i_lang) desc_status, -- Shouldn't be this way
                   decode(ie.id_episode, i_id_episode, 'Y', 'N') flg_current_episode,
                   ie.notes notes,
                   pk_message.get_message(i_lang, i_prof, 'EVALUATION_MFR_T017') || ':' title_notes_cancel,
                   ie.notes_cancel notes_cancel,
                   pk_date_utils.get_timestamp_str(i_lang,
                                                   i_prof,
                                                   greatest(ie.dt_interv_evaluation_tstz,
                                                            nvl(ie.dt_cancel_tstz, ie.dt_interv_evaluation_tstz)),
                                                   NULL) dt_last_update,
                   'Y' flg_detail, -- ?
                   'N' flg_external -- ?
              FROM interv_evaluation ie
              JOIN episode e
                ON e.id_episode = ie.id_episode
             WHERE ((l_id_episode IS NOT NULL AND e.id_episode = l_id_episode) OR
                   (l_id_patient IS NOT NULL AND l_id_patient = e.id_patient) OR
                   (l_id_visit IS NOT NULL AND l_id_visit = e.id_visit) OR
                   (l_id_epis_origin IS NOT NULL AND l_id_epis_origin = e.id_prev_episode))
                  --AND ie.id_patient = e.id_patient
               AND ie.flg_type = g_flg_typeevaluation_icf
               AND ie.dt_interv_evaluation_tstz >= nvl(i_start_date, ie.dt_interv_evaluation_tstz)
               AND ie.dt_interv_evaluation_tstz <= nvl(i_end_date, ie.dt_interv_evaluation_tstz)
             ORDER BY ie.dt_interv_evaluation_tstz DESC;
    
        OPEN o_doc_area_val FOR
            SELECT ie.id_interv_evaluation id_epis_documentation, -- Misleading alias
                   NULL id_documentation,
                   NULL id_doc_component,
                   NULL id_doc_element_crit,
                   CAST(MULTISET
                        (SELECT pk_translation.get_translation(i_lang, connect_by_root code_icf) parent_name
                           FROM icf
                          WHERE id_icf IN (SELECT id_icf
                                             FROM interv_evaluation_icf iei1
                                            WHERE iei1.id_interv_evaluation = ie.id_interv_evaluation)
                         CONNECT BY PRIOR id_icf = id_icf_parent
                          START WITH id_icf IN (SELECT id_icf
                                                  FROM icf
                                                 WHERE flg_type = g_flg_icf_component)
                          ORDER BY connect_by_root id_icf, id_icf) AS table_varchar) componentes,
                   
                   CAST(MULTISET
                        (SELECT decode(connect_by_root coding, NULL, g_flg_y, g_flg_n)
                           FROM icf
                          WHERE id_icf IN (SELECT id_icf
                                             FROM interv_evaluation_icf iei1
                                            WHERE iei1.id_interv_evaluation = ie.id_interv_evaluation)
                         CONNECT BY PRIOR id_icf = id_icf_parent
                          START WITH id_icf IN (SELECT id_icf
                                                  FROM icf
                                                 WHERE flg_type = g_flg_icf_component)
                          ORDER BY connect_by_root id_icf, id_icf) AS table_varchar) flg_personal,
                   
                   CAST(MULTISET
                        (SELECT pk_translation.get_translation(i_lang, code_icf)
                           FROM icf
                          WHERE id_icf IN (SELECT id_icf
                                             FROM interv_evaluation_icf iei1
                                            WHERE iei1.id_interv_evaluation = ie.id_interv_evaluation)
                         CONNECT BY PRIOR id_icf = id_icf_parent
                          START WITH id_icf IN (SELECT id_icf
                                                  FROM icf
                                                 WHERE flg_type = g_flg_icf_component)
                          ORDER BY connect_by_root id_icf, id_icf) AS table_varchar) categories,
                   
                   CAST(MULTISET
                        (SELECT pk_interv_mfr.get_full_coding(i_lang, i_prof, iei1.id_icf, iei1.id_interv_evaluation)
                           FROM interv_evaluation_icf iei1,
                                (SELECT id_icf, connect_by_root id_icf id_parent
                                   FROM icf
                                 --WHERE id_icf IN (SELECT id_icf
                                 --                  FROM interv_evaluation_icf iei1
                                 --                WHERE iei1.id_interv_evaluation = ie.id_interv_evaluation)
                                 CONNECT BY PRIOR id_icf = id_icf_parent
                                  START WITH id_icf IN (SELECT id_icf
                                                          FROM icf
                                                         WHERE flg_type = g_flg_icf_component)) cif
                          WHERE iei1.id_interv_evaluation = ie.id_interv_evaluation
                            AND iei1.id_icf = cif.id_icf
                          ORDER BY cif.id_parent, iei1.id_icf) AS table_varchar) AS coding,
                   
                   CAST(MULTISET (SELECT notes
                           FROM interv_evaluation_icf iei1,
                                (SELECT id_icf, connect_by_root id_icf id_parent
                                   FROM icf
                                 -- WHERE id_icf IN (SELECT id_icf
                                 --                  FROM interv_evaluation_icf iei1
                                 --                WHERE iei1.id_interv_evaluation = ie.id_interv_evaluation)
                                 CONNECT BY PRIOR id_icf = id_icf_parent
                                  START WITH id_icf IN (SELECT id_icf
                                                          FROM icf
                                                         WHERE flg_type = g_flg_icf_component)) cif
                          WHERE iei1.id_interv_evaluation = ie.id_interv_evaluation
                            AND iei1.id_icf = cif.id_icf
                          ORDER BY cif.id_parent, iei1.id_icf) AS table_varchar) notes,
                   
                   CAST(MULTISET
                        (SELECT concatenate(decode(iq.id_icf_qualification,
                                                   NULL,
                                                   '',
                                                   decode((SELECT flg_view
                                                            FROM icf_qualification_rel iqr
                                                           WHERE iqr.id_icf(+) = cif.id_component
                                                             AND iqr.id_icf_qualification_scale(+) =
                                                                 iqs.id_icf_qualification_scale),
                                                          g_flg_y,
                                                          '(' ||
                                                          pk_translation.get_translation(i_lang,
                                                                                         iqs.code_icf_qualification_scale) ||
                                                          ' - ' ||
                                                          pk_translation.get_translation(i_lang, iq.code_icf_qualification) || ')' ||
                                                          '<BR>',
                                                          NULL)))
                           FROM interv_evaluation_icf iei1,
                                interv_eval_icf_qualif ieiq,
                                icf_qualif_scale_rel iqsr,
                                icf_qualification iq,
                                icf_qualification_scale iqs,
                                (SELECT connect_by_root id_icf id_component, id_icf
                                   FROM icf
                                 --         WHERE id_icf IN
                                 --              (SELECT id_icf
                                 --                 FROM interv_evaluation_icf iei1
                                 --                WHERE iei1.id_interv_evaluation = iei1.id_interv_evaluation)
                                 CONNECT BY PRIOR id_icf = id_icf_parent
                                  START WITH id_icf IN (SELECT id_icf
                                                          FROM icf
                                                         WHERE flg_type = g_flg_icf_component)
                                  ORDER BY id_icf) cif
                          WHERE iei1.id_interv_evaluation = ie.id_interv_evaluation
                            AND iei1.id_icf = ieiq.id_icf(+)
                            AND iei1.id_interv_evaluation = ieiq.id_interv_evaluation(+)
                            AND ieiq.id_icf_qualification_scale = iqsr.id_icf_qualification_scale(+)
                            AND ieiq.id_icf_qualification = iqsr.id_icf_qualification(+)
                            AND iqsr.id_icf_qualification = iq.id_icf_qualification(+)
                            AND iqsr.id_icf_qualification_scale = iqs.id_icf_qualification_scale(+)
                            AND cif.id_icf = iei1.id_icf
                          GROUP BY cif.id_component, iei1.id_icf, cif.id_component) AS table_varchar) qualif,
                   
                   pk_date_utils.get_timestamp_str(i_lang, i_prof, ie.dt_interv_evaluation_tstz, NULL) dt_reg,
                   NULL desc_doc_component,
                   NULL desc_element,
                   NULL VALUE,
                   i_doc_area id_doc_area,
                   decode(ie.id_episode, i_id_episode, g_flg_y, g_flg_n) flg_current_episode,
                   NULL id_epis_documentation_det,
                   NULL desc_qualification,
                   'N' flg_external -- ?
              FROM interv_evaluation ie
              JOIN episode e
                ON e.id_episode = ie.id_episode
             WHERE ((l_id_episode IS NOT NULL AND e.id_episode = l_id_episode) OR
                   (l_id_patient IS NOT NULL AND l_id_patient = e.id_patient) OR
                   (l_id_visit IS NOT NULL AND l_id_visit = e.id_visit) OR
                   (l_id_epis_origin IS NOT NULL AND l_id_epis_origin = e.id_prev_episode))
                  --AND ie.id_patient = e.id_patient
               AND ie.flg_type = g_flg_typeevaluation_icf
               AND ie.dt_interv_evaluation_tstz >= nvl(i_start_date, ie.dt_interv_evaluation_tstz)
               AND ie.dt_interv_evaluation_tstz <= nvl(i_end_date, ie.dt_interv_evaluation_tstz)
             ORDER BY ie.dt_interv_evaluation_tstz DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_INTERV_MFR', 'GET_EVALUATION_ICF_INT');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_types.open_my_cursor(o_doc_area_register);
                pk_types.open_my_cursor(o_doc_area_val);
            
                RETURN FALSE;
            END;
    END get_evaluation_icf_int;

    FUNCTION get_evaluation_icf
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN episode.id_episode%TYPE,
        i_id_patient        IN patient.id_patient%TYPE,
        i_doc_area          IN doc_area.id_doc_area%TYPE,
        i_start_date        IN VARCHAR2 DEFAULT NULL,
        i_end_date          IN VARCHAR2 DEFAULT NULL,
        o_doc_area_register OUT pk_types.cursor_type,
        o_doc_area_val      OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_start_date TIMESTAMP WITH TIME ZONE;
        l_end_date   TIMESTAMP WITH TIME ZONE;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_prof.id = ' || coalesce(to_char(i_prof.id), '<null>');
        g_error := g_error || ' i_prof.institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error := g_error || ' i_prof.software = ' || coalesce(to_char(i_prof.software), '<null>');
        g_error := g_error || ' i_id_episode = ' || coalesce(to_char(i_id_episode), '<null>');
        g_error := g_error || ' i_id_patient = ' || coalesce(to_char(i_id_patient), '<null>');
        g_error := g_error || ' i_doc_area = ' || coalesce(to_char(i_doc_area), '<null>');
        pk_alertlog.log_debug(g_error);
    
        -- Convert start date to timestamp
        g_error := g_error || chr(10) || 'CALL GET_STRING_TSTZ FOR i_start_date = ' ||
                   coalesce(to_char(i_start_date, 'DD-MON-YYYY HH24:MI'), '<null>');
        pk_alertlog.log_debug(g_error);
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_start_date,
                                             i_timezone  => NULL,
                                             o_timestamp => l_start_date,
                                             o_error     => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        -- Convert end date to timestamp
        g_error := g_error || chr(10) || 'CALL GET_STRING_TSTZ FOR i_end_date = ' ||
                   coalesce(to_char(i_end_date, 'DD-MON-YYYY HH24:MI'), '<null>');
        pk_alertlog.log_debug(g_error);
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_end_date,
                                             i_timezone  => NULL,
                                             o_timestamp => l_end_date,
                                             o_error     => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := g_error || chr(10) || 'CALL get_evaluation_icf_int';
        pk_alertlog.log_debug(g_error);
        IF NOT get_evaluation_icf_int(i_lang              => i_lang,
                                      i_prof              => i_prof,
                                      i_id_episode        => i_id_episode,
                                      i_id_patient        => i_id_patient,
                                      i_doc_area          => i_doc_area,
                                      i_start_date        => l_start_date,
                                      i_end_date          => l_end_date,
                                      o_doc_area_register => o_doc_area_register,
                                      o_doc_area_val      => o_doc_area_val,
                                      o_error             => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_INTERV_MFR', 'GET_EVALUATION_ICF');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_types.open_my_cursor(o_doc_area_register);
                pk_types.open_my_cursor(o_doc_area_val);
            
                RETURN FALSE;
            END;
    END get_evaluation_icf;

    FUNCTION get_evaluation_icf
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN episode.id_episode%TYPE,
        i_id_patient        IN patient.id_patient%TYPE,
        i_doc_area          IN doc_area.id_doc_area%TYPE,
        o_doc_area_register OUT pk_types.cursor_type,
        o_doc_area_val      OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_prof.id = ' || coalesce(to_char(i_prof.id), '<null>');
        g_error := g_error || ' i_prof.institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error := g_error || ' i_prof.software = ' || coalesce(to_char(i_prof.software), '<null>');
        g_error := g_error || ' i_id_episode = ' || coalesce(to_char(i_id_episode), '<null>');
        g_error := g_error || ' i_id_patient = ' || coalesce(to_char(i_id_patient), '<null>');
        g_error := g_error || ' i_doc_area = ' || coalesce(to_char(i_doc_area), '<null>');
    
        g_error := g_error || chr(10) || 'CALL get_evaluation_icf_int';
        pk_alertlog.log_debug(g_error);
        IF NOT get_evaluation_icf_int(i_lang              => i_lang,
                                      i_prof              => i_prof,
                                      i_id_episode        => i_id_episode,
                                      i_id_patient        => i_id_patient,
                                      i_doc_area          => i_doc_area,
                                      o_doc_area_register => o_doc_area_register,
                                      o_doc_area_val      => o_doc_area_val,
                                      o_error             => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_INTERV_MFR', 'GET_EVALUATION_ICF');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_types.open_my_cursor(o_doc_area_register);
                pk_types.open_my_cursor(o_doc_area_val);
            
                RETURN FALSE;
            END;
    END get_evaluation_icf;

    FUNCTION get_top_id_icf
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_icf IN icf.id_icf%TYPE
    ) RETURN icf.id_icf%TYPE IS
        l_id icf.code_icf%TYPE;
    
    BEGIN
        g_error := 'GET_TOP_ID_ICF';
        SELECT connect_by_root id_icf root
          INTO l_id
          FROM icf i
         WHERE i.id_icf = i_id_icf
        CONNECT BY PRIOR i.id_icf = i.id_icf_parent
         START WITH i.id_icf IN (SELECT id_icf
                                   FROM icf
                                  WHERE flg_type = g_flg_icf_component);
    
        RETURN l_id;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_id PLS_INTEGER;
            BEGIN
                pk_alert_exceptions.register_error(error_name_in       => SQLERRM,
                                                   err_instance_id_out => l_id,
                                                   text_in             => g_error,
                                                   name1_in            => 'OWNER',
                                                   value1_in           => 'ALERT',
                                                   name2_in            => 'PACKAGE',
                                                   value2_in           => 'PK_INTERV_MFR',
                                                   name3_in            => 'FUNCTION',
                                                   value3_in           => 'GET_TOP_ID_ICF');
                pk_alert_exceptions.reset_error_state;
            
                RETURN NULL;
            END;
    END get_top_id_icf;

    FUNCTION get_full_coding
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_icf               IN interv_eval_icf_qualif.id_icf%TYPE,
        i_id_interv_evaluation IN interv_eval_icf_qualif.id_interv_evaluation%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_ret VARCHAR2(4000);
        --
        FUNCTION get_recursive_coding
        (
            i_id_icf IN icf.id_icf%TYPE,
            i_coding IN VARCHAR2
        ) RETURN VARCHAR2 IS
            l_parent icf.id_icf_parent%TYPE;
            l_coding VARCHAR2(4000);
        
        BEGIN
            SELECT i.id_icf_parent, i.coding
              INTO l_parent, l_coding
              FROM icf i
             WHERE i.id_icf = i_id_icf;
        
            IF l_parent IS NULL
            THEN
                RETURN l_coding;
            ELSE
                RETURN get_recursive_coding(l_parent, l_coding) || l_coding;
            END IF;
        END get_recursive_coding;
    
    BEGIN
        SELECT concatenate(iqsr.flg_code || iqsr.value)
          INTO l_ret
          FROM interv_eval_icf_qualif ieiq, icf_qualif_scale_rel iqsr
         WHERE ieiq.id_icf = i_id_icf
           AND ieiq.id_icf_qualification = iqsr.id_icf_qualification
           AND ieiq.id_icf_qualification_scale = iqsr.id_icf_qualification_scale
           AND ieiq.id_interv_evaluation = i_id_interv_evaluation;
    
        RETURN get_recursive_coding(i_id_icf, NULL) || l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_id PLS_INTEGER;
            BEGIN
                pk_alert_exceptions.register_error(error_name_in       => SQLERRM,
                                                   err_instance_id_out => l_id,
                                                   text_in             => g_error,
                                                   name1_in            => 'OWNER',
                                                   value1_in           => 'ALERT',
                                                   name2_in            => 'PACKAGE',
                                                   value2_in           => 'PK_INTERV_MFR',
                                                   name3_in            => 'FUNCTION',
                                                   value3_in           => 'GET_FULL_CODING');
                pk_alert_exceptions.reset_error_state;
            
                RETURN NULL;
            END;
    END get_full_coding;

    FUNCTION get_icf_categories
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_code_name IN VARCHAR2,
        o_flg_show  OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        o_icf       OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_count PLS_INTEGER;
        l_limit sys_config.desc_sys_config%TYPE;
    
    BEGIN
        l_limit    := pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof);
        o_flg_show := 'N';
    
        DELETE FROM tbl_temp;
    
        --   OPEN o_icf FOR
        INSERT INTO tbl_temp
            (num_1, vc_1, vc_2, num_2, vc_3, vc_4)
            SELECT cif.id_icf, coding, icf_name, folha, parent_hierarchy, code_icf
              FROM (SELECT id_icf, coding, icf_name, folha, flg_type, parent_hierarchy, code_icf
                      FROM (SELECT id_icf,
                                   decode(flg_type,
                                          g_flg_icf_component,
                                          NULL,
                                          g_flg_icf_chapter,
                                          coding,
                                          REPLACE(sys_connect_by_path(coding, '/'), '/', '')) coding,
                                   pk_translation.get_translation(i_lang, code_icf) icf_name,
                                   connect_by_isleaf folha,
                                   flg_type,
                                   substr(sys_connect_by_path(id_icf, '|'), 2) parent_hierarchy,
                                   code_icf
                              FROM icf
                             WHERE flg_available = g_flg_y
                            CONNECT BY PRIOR id_icf = id_icf_parent
                             START WITH id_icf IN (SELECT id_icf
                                                     FROM icf
                                                    WHERE flg_type = g_flg_icf_component)) t,
                           TABLE(pk_translation.get_search_translation(i_lang, i_code_name, 'ICF.CODE_ICF')) st
                     WHERE st.code_translation = t.code_icf
                    UNION
                    SELECT id_icf, coding, icf_name, folha, flg_type, parent_hierarchy, code_icf
                      FROM (SELECT id_icf,
                                   decode(flg_type,
                                          g_flg_icf_component,
                                          NULL,
                                          g_flg_icf_chapter,
                                          coding,
                                          REPLACE(sys_connect_by_path(coding, '/'), '/', '')) coding,
                                   pk_translation.get_translation(i_lang, code_icf) icf_name,
                                   connect_by_isleaf folha,
                                   flg_type,
                                   substr(sys_connect_by_path(id_icf, '|'), 2) parent_hierarchy,
                                   code_icf
                              FROM icf
                             WHERE flg_available = g_flg_y
                            CONNECT BY PRIOR id_icf = id_icf_parent
                             START WITH id_icf IN (SELECT id_icf
                                                     FROM icf
                                                    WHERE flg_type = g_flg_icf_component)) t,
                           TABLE(pk_translation.get_search_translation(i_lang, i_code_name, 'ICF.CODE_ICF')) st
                     WHERE st.code_translation = t.code_icf) cif,
                   icf_soft_inst isi
             WHERE cif.id_icf = isi.id_icf
               AND nvl(id_institution, 0) IN (0, i_prof.institution)
               AND nvl(id_software, 0) IN (0, i_prof.software);
    
        g_error := 'GET COUNT';
        SELECT COUNT(0)
          INTO l_count
          FROM tbl_temp;
    
        IF l_count > l_limit
        THEN
            o_flg_show  := 'Y';
            o_msg       := pk_search.get_overlimit_message(i_lang => i_lang, i_prof => i_prof, i_flg_has_action => 'Y');
            o_msg_title := pk_message.get_message(i_lang, 'SEARCH_CRITERIA_T011');
            o_button    := '';
        ELSIF l_count = 0
        THEN
            o_flg_show  := 'Y';
            o_msg       := pk_message.get_message(i_lang, 'COMMON_M015');
            o_msg_title := pk_message.get_message(i_lang, 'SEARCH_CRITERIA_T011');
            o_button    := '';
        
            pk_types.open_my_cursor(o_icf);
            RETURN TRUE;
        END IF;
        g_error := 'OPEN O_ICF';
        OPEN o_icf FOR
            SELECT *
              FROM (SELECT num_1 id_icf, vc_1 coding, vc_2 icf_name, num_2 folha, vc_3 parent_hierarchy
                      FROM tbl_temp
                     WHERE vc_1 IS NOT NULL
                     ORDER BY coding)
             WHERE rownum <= l_limit;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_INTERV_MFR', 'CREATE_INTERV_PRESC');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_types.open_my_cursor(o_icf);
            
                RETURN FALSE;
            END;
    END get_icf_categories;

    FUNCTION get_icf_evaluation
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_idinterv IN interv_evaluation.id_interv_evaluation%TYPE,
        o_icf      OUT pk_types.cursor_type,
        o_icf_hier OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        OPEN o_icf FOR
            SELECT iei.id_icf,
                   pk_translation.get_translation(i_lang, cif.component) component,
                   cif.coding,
                   cif.icf_name,
                   iei.notes,
                   cif.id_parent,
                   lvl1.id_icf_qualification_scale id_scale_level1,
                   lvl1.id_icf_qualification id_icf_qualif_level1,
                   lvl1.cif_value cif_value1,
                   decode((SELECT COUNT(1)
                            FROM icf_qualification_rel
                           WHERE id_icf = cif.id_parent
                             AND flg_level = g_flg_level1),
                          0,
                          g_flg_n,
                          g_flg_y) flg_edit_level1, --decode(lvl1.id_icf_qualification_scale,null,'N','S') flg_edit_level1,
                   lvl2.id_icf_qualification_scale id_scale_level2,
                   lvl2.id_icf_qualification id_icf_qualif_level2,
                   lvl2.cif_value cif_value2,
                   decode((SELECT COUNT(1)
                            FROM icf_qualification_rel
                           WHERE id_icf = cif.id_parent
                             AND flg_level = g_flg_level2),
                          0,
                          g_flg_n,
                          g_flg_y) flg_edit_level2, --decode(lvl2.id_icf_qualification_scale,null,'N','S') flg_edit_level2,
                   lvl3.id_icf_qualification_scale id_scale_level3,
                   lvl3.id_icf_qualification id_icf_qualif_level3,
                   lvl3.cif_value cif_value3,
                   decode((SELECT COUNT(1)
                            FROM icf_qualification_rel
                           WHERE id_icf = cif.id_parent
                             AND flg_level = g_flg_level3),
                          0,
                          g_flg_n,
                          g_flg_y) flg_edit_level3 --decode(lvl3.id_icf_qualification_scale,null,'N','S') flg_edit_level3
              FROM interv_evaluation ie,
                   interv_evaluation_icf iei,
                   (SELECT id_icf,
                           decode(flg_type,
                                  g_flg_icf_component,
                                  NULL,
                                  g_flg_icf_chapter,
                                  coding,
                                  REPLACE(sys_connect_by_path(coding, '/'), '/', '')) coding,
                           pk_translation.get_translation(i_lang, code_icf) icf_name,
                           connect_by_root i.code_icf component,
                           connect_by_root i.id_icf id_parent
                      FROM icf i
                    CONNECT BY PRIOR id_icf = id_icf_parent
                     START WITH id_icf IN (SELECT id_icf
                                             FROM icf
                                            WHERE flg_type = g_flg_icf_component)) cif,
                   (SELECT ieiq.id_icf,
                           iqsr.id_icf_qualification_scale,
                           ieiq.flg_level,
                           iq.id_icf_qualification,
                           iqsr.flg_code || iqsr.value cif_value,
                           g_flg_y flg
                      FROM interv_eval_icf_qualif ieiq,
                           icf_qualif_scale_rel   iqsr,
                           icf_qualification      iq,
                           interv_evaluation_icf  iei1
                     WHERE ieiq.id_interv_evaluation = i_idinterv
                       AND ieiq.id_icf_qualification_scale = iqsr.id_icf_qualification_scale
                       AND ieiq.id_icf_qualification = iqsr.id_icf_qualification
                       AND iqsr.id_icf_qualification = iq.id_icf_qualification
                       AND ieiq.id_interv_evaluation = iei1.id_interv_evaluation
                       AND ieiq.id_icf = iei1.id_icf
                       AND ieiq.flg_level = g_flg_level1) lvl1,
                   (SELECT ieiq.id_icf,
                           iqsr.id_icf_qualification_scale,
                           ieiq.flg_level,
                           iq.id_icf_qualification,
                           iqsr.flg_code || iqsr.value cif_value,
                           g_flg_y flg
                      FROM interv_eval_icf_qualif ieiq,
                           icf_qualif_scale_rel   iqsr,
                           icf_qualification      iq,
                           interv_evaluation_icf  iei1
                     WHERE ieiq.id_interv_evaluation = i_idinterv
                       AND ieiq.id_icf_qualification_scale = iqsr.id_icf_qualification_scale
                       AND ieiq.id_icf_qualification = iqsr.id_icf_qualification
                       AND iqsr.id_icf_qualification = iq.id_icf_qualification
                       AND ieiq.id_interv_evaluation = iei1.id_interv_evaluation
                       AND ieiq.id_icf = iei1.id_icf
                       AND ieiq.flg_level = g_flg_level2) lvl2,
                   (SELECT ieiq.id_icf,
                           iqsr.id_icf_qualification_scale,
                           ieiq.flg_level,
                           iq.id_icf_qualification,
                           iqsr.flg_code || iqsr.value cif_value,
                           g_flg_y flg
                      FROM interv_eval_icf_qualif ieiq,
                           icf_qualif_scale_rel   iqsr,
                           icf_qualification      iq,
                           interv_evaluation_icf  iei1
                     WHERE ieiq.id_interv_evaluation = i_idinterv
                       AND ieiq.id_icf_qualification_scale = iqsr.id_icf_qualification_scale
                       AND ieiq.id_icf_qualification = iqsr.id_icf_qualification
                       AND ieiq.id_icf = iei1.id_icf
                       AND iqsr.id_icf_qualification = iq.id_icf_qualification
                       AND ieiq.id_interv_evaluation = iei1.id_interv_evaluation
                       AND ieiq.flg_level = g_flg_level3) lvl3
             WHERE ie.id_interv_evaluation = iei.id_interv_evaluation
               AND ie.id_interv_evaluation = i_idinterv
               AND iei.id_icf = cif.id_icf
               AND iei.id_icf = lvl1.id_icf(+)
               AND iei.id_icf = lvl2.id_icf(+)
               AND iei.id_icf = lvl3.id_icf(+)
             ORDER BY component, coding;
    
        OPEN o_icf_hier FOR
            SELECT id_icf,
                   decode(flg_type,
                          g_flg_icf_component,
                          NULL,
                          g_flg_icf_chapter,
                          coding,
                          REPLACE(sys_connect_by_path(coding, '/'), '/', '')) coding,
                   pk_translation.get_translation(i_lang, code_icf) icf_name,
                   connect_by_isleaf folha,
                   LEVEL cif_level,
                   id_icf_parent id_parent,
                   substr(sys_connect_by_path(id_icf, '|'), 2) parent_hierarchy
              FROM icf
             WHERE id_icf IN (SELECT id_icf
                                FROM interv_evaluation_icf
                               WHERE id_interv_evaluation = i_idinterv)
            CONNECT BY PRIOR id_icf = id_icf_parent
             START WITH id_icf IN (SELECT id_icf
                                     FROM icf
                                    WHERE flg_type = g_flg_icf_component)
             ORDER BY coding, icf_name;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_INTERV_MFR', 'CREATE_INTERV_PRESC');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_types.open_my_cursor(o_icf);
            
                RETURN FALSE;
            END;
    END get_icf_evaluation;

    FUNCTION cancel_icf_evaluation
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_interv_evaluation IN interv_evaluation.id_interv_evaluation%TYPE,
        i_notes                IN interv_evaluation.notes_cancel%TYPE DEFAULT NULL,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        -- nothing to declare
    BEGIN
        IF NOT cancel_icf_evaluation_nocommit(i_lang                 => i_lang,
                                              i_prof                 => i_prof,
                                              i_id_interv_evaluation => i_id_interv_evaluation,
                                              i_cancel_mode          => g_status_eval_canc,
                                              i_notes                => i_notes,
                                              o_error                => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_INTERV_MFR', 'CANCEL_ICF_EVALUATION');
            
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_utils.undo_changes;
            
                RETURN FALSE;
            END;
    END cancel_icf_evaluation;

    FUNCTION cancel_icf_evaluation_nocommit
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_interv_evaluation IN interv_evaluation.id_interv_evaluation%TYPE,
        i_cancel_mode          IN interv_evaluation.flg_status%TYPE DEFAULT 'C',
        i_notes                IN interv_evaluation.notes_cancel%TYPE DEFAULT NULL,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rows table_varchar;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'CANCEL EVALUATION / UPDATE';
        ts_interv_evaluation.upd(id_interv_evaluation_in => i_id_interv_evaluation,
                                 flg_status_in           => i_cancel_mode,
                                 flg_status_nin          => TRUE,
                                 dt_cancel_tstz_in       => g_sysdate_tstz,
                                 dt_cancel_tstz_nin      => TRUE,
                                 id_prof_cancel_in       => i_prof.id,
                                 id_prof_cancel_nin      => TRUE,
                                 notes_cancel_in         => i_notes,
                                 notes_cancel_nin        => FALSE,
                                 handle_error_in         => TRUE,
                                 rows_out                => l_rows);
    
        g_error := 'PROCESS UPDATE';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'INTERV_EVALUATION',
                                      i_rowids     => l_rows,
                                      o_error      => o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_INTERV_MFR', 'CANCEL_ICF_EVALUATION_NOCOMMIT');
            
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_utils.undo_changes;
            
                RETURN FALSE;
            END;
    END cancel_icf_evaluation_nocommit;

    FUNCTION get_icf_qualif
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_id_icf                     IN icf_qualification_rel.id_icf%TYPE,
        i_id_icf_qualification_scale IN icf_qualification_rel.id_icf_qualification_scale%TYPE,
        i_flg_level                  IN icf_qualification_rel.flg_level%TYPE,
        o_qualif                     OUT pk_types.cursor_type,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN IS
        -- nothing to declare
    BEGIN
        g_error := 'GET QUALIFICATION';
        OPEN o_qualif FOR
            SELECT pk_translation.get_translation(i_lang, iq.code_icf_qualification) desc_qualif,
                   iqsr.flg_code || iqsr.value coding,
                   iq.id_icf_qualification id_qualif
              FROM icf_qualification_rel   iqr,
                   icf_qualification_scale iqs,
                   icf_qualification       iq,
                   icf_qualif_scale_rel    iqsr
             WHERE iqr.id_icf = get_top_id_icf(i_lang, i_prof, i_id_icf)
               AND iqr.id_icf_qualification_scale = i_id_icf_qualification_scale
               AND iqsr.flg_available = 'Y'
               AND iqsr.id_icf_qualification = iq.id_icf_qualification
               AND iqsr.id_icf_qualification_scale = iqs.id_icf_qualification_scale
               AND iqr.id_icf_qualification_scale = iqs.id_icf_qualification_scale
               AND iqr.flg_level = i_flg_level
             ORDER BY iqsr.rank ASC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_INTERV_MFR', 'GET_ICF_QUALIF');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN FALSE;
            END;
    END get_icf_qualif;

    FUNCTION create_icf_evaluation_internal
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_patient          IN patient.id_patient%TYPE,
        i_idicf               IN table_number,
        i_notes               IN table_varchar,
        i_idqualscalelevel1   IN table_number,
        i_id_qualifilevel1    IN table_number,
        i_idqualscalelevel2   IN table_number,
        i_id_qualifilevel2    IN table_number,
        i_idqualscalelevel3   IN table_number,
        i_id_qualifilevel3    IN table_number,
        o_id_intervevaluation OUT interv_evaluation.id_interv_evaluation%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rows                table_varchar;
        l_rows_icf            table_varchar;
        l_idinterv_evaluation interv_evaluation.id_interv_evaluation%TYPE;
        l_id_rehab_diagnosis  table_number;
        l_flg_show            VARCHAR2(1);
        l_msg                 VARCHAR2(4000);
    BEGIN
        g_sysdate_tstz := current_timestamp;
        g_error        := 'INSERT EVALUATION';
        ts_interv_evaluation.ins(dt_interv_evaluation_tstz_in => g_sysdate_tstz,
                                 id_professional_in           => i_prof.id,
                                 flg_status_in                => g_flg_status_ia,
                                 id_episode_in                => i_id_episode,
                                 id_patient_in                => i_id_patient,
                                 flg_type_in                  => g_flg_typeevaluation_icf,
                                 handle_error_in              => TRUE,
                                 id_interv_evaluation_out     => l_idinterv_evaluation,
                                 rows_out                     => l_rows);
    
        g_error := 'PROCESS UPDATE';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'INTERV_EVALUATION',
                                      i_rowids     => l_rows,
                                      o_error      => o_error);
    
        l_rows                := table_varchar();
        o_id_intervevaluation := l_idinterv_evaluation;
        FOR i IN 1 .. i_idicf.count
        LOOP
            g_error := 'INSERT EVALUATION ICF';
            ts_interv_evaluation_icf.ins(id_icf_in               => i_idicf(i),
                                         id_interv_evaluation_in => l_idinterv_evaluation,
                                         notes_in                => i_notes(i),
                                         handle_error_in         => TRUE,
                                         rows_out                => l_rows_icf);
        
            IF i_idqualscalelevel1(i) IS NOT NULL
               AND i_id_qualifilevel1(i) IS NOT NULL
            THEN
                -- QUALIFICATION LEVEL 1
                ts_interv_eval_icf_qualif.ins(id_icf_qualification_in       => i_id_qualifilevel1(i),
                                              id_icf_qualification_scale_in => i_idqualscalelevel1(i),
                                              id_icf_in                     => i_idicf(i),
                                              id_interv_evaluation_in       => l_idinterv_evaluation,
                                              flg_level_in                  => 1,
                                              handle_error_in               => TRUE,
                                              rows_out                      => l_rows);
            END IF;
            IF i_idqualscalelevel2(i) IS NOT NULL
               AND i_id_qualifilevel2(i) IS NOT NULL
            THEN
                -- QUALIFICATION LEVEL 2
                ts_interv_eval_icf_qualif.ins(id_icf_qualification_in       => i_id_qualifilevel2(i),
                                              id_icf_qualification_scale_in => i_idqualscalelevel2(i),
                                              id_icf_in                     => i_idicf(i),
                                              id_interv_evaluation_in       => l_idinterv_evaluation,
                                              flg_level_in                  => 2,
                                              handle_error_in               => TRUE,
                                              rows_out                      => l_rows);
            END IF;
        
            IF i_idqualscalelevel3(i) IS NOT NULL
               AND i_id_qualifilevel3(i) IS NOT NULL
            THEN
                -- QUALIFICATION LEVEL 3
                ts_interv_eval_icf_qualif.ins(id_icf_qualification_in       => i_id_qualifilevel3(i),
                                              id_icf_qualification_scale_in => i_idqualscalelevel3(i),
                                              id_icf_in                     => i_idicf(i),
                                              id_interv_evaluation_in       => l_idinterv_evaluation,
                                              flg_level_in                  => 3,
                                              handle_error_in               => TRUE,
                                              rows_out                      => l_rows);
            END IF;
        
        END LOOP;
        g_error := 'PROCESS UPDATE EVALUATION ICF';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'INTERV_EVALUATION_ICF',
                                      i_rowids     => l_rows_icf,
                                      o_error      => o_error);
        IF l_rows.count > 0
        THEN
            g_error := 'PROCESS UPDATE QUALIFICATION';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'INTERV_EVAL_ICF_QUALIF',
                                          i_rowids     => l_rows,
                                          o_error      => o_error);
        
        END IF;
    
        IF NOT pk_rehab.create_rehab_diag(i_lang                   => i_lang,
                                          i_prof                   => i_prof,
                                          i_episode                => i_id_episode,
                                          i_patient                => i_id_patient,
                                          i_icf                    => i_idicf,
                                          i_iq_initial_incapacity  => i_id_qualifilevel1,
                                          i_iqs_initial_incapacity => i_idqualscalelevel1,
                                          i_iq_expected_result     => i_id_qualifilevel2,
                                          i_iqs_expected_result    => i_idqualscalelevel2,
                                          i_iq_active_incapacity   => i_id_qualifilevel3,
                                          i_iqs_active_incapacity  => i_idqualscalelevel3,
                                          i_notes                  => i_notes,
                                          o_id_rehab_diagnosis     => l_id_rehab_diagnosis,
                                          o_flg_show               => l_flg_show,
                                          o_msg                    => l_msg,
                                          o_error                  => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF l_flg_show = pk_alert_constant.g_yes
        THEN
            pk_utils.undo_changes;
            RETURN TRUE;
        END IF;
    
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_id_episode,
                                      i_pat                 => i_id_patient,
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
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_INTERV_MFR', 'CREATE_ICF_EVALUATION_INTERNAL');
            
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_utils.undo_changes;
            
                RETURN FALSE;
            END;
    END create_icf_evaluation_internal;

    FUNCTION create_icf_evaluation
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_patient          IN patient.id_patient%TYPE,
        i_idicf               IN table_number,
        i_notes               IN table_varchar,
        i_idqualscalelevel1   IN table_number,
        i_id_qualifilevel1    IN table_number,
        i_idqualscalelevel2   IN table_number,
        i_id_qualifilevel2    IN table_number,
        i_idqualscalelevel3   IN table_number,
        i_id_qualifilevel3    IN table_number,
        o_id_intervevaluation OUT interv_evaluation.id_interv_evaluation%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF NOT create_icf_evaluation_internal(i_lang                => i_lang,
                                              i_prof                => i_prof,
                                              i_id_episode          => i_id_episode,
                                              i_id_patient          => i_id_patient,
                                              i_idicf               => i_idicf,
                                              i_notes               => i_notes,
                                              i_idqualscalelevel1   => i_idqualscalelevel1,
                                              i_id_qualifilevel1    => i_id_qualifilevel1,
                                              i_idqualscalelevel2   => i_idqualscalelevel2,
                                              i_id_qualifilevel2    => i_id_qualifilevel2,
                                              i_idqualscalelevel3   => i_idqualscalelevel3,
                                              i_id_qualifilevel3    => i_id_qualifilevel3,
                                              o_id_intervevaluation => o_id_intervevaluation,
                                              o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_INTERV_MFR', 'CREATE_ICF_EVALUATION');
            
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_utils.undo_changes;
            
                RETURN FALSE;
            END;
    END create_icf_evaluation;

    FUNCTION update_icf_evaluation
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_idinterv            IN interv_evaluation.id_interv_evaluation%TYPE,
        i_idepisode           IN episode.id_episode%TYPE,
        i_idpatient           IN patient.id_patient%TYPE,
        i_idicf               IN table_number,
        i_notes               IN table_varchar,
        i_idqualscalelevel1   IN table_number,
        i_id_qualifilevel1    IN table_number,
        i_idqualscalelevel2   IN table_number,
        i_id_qualifilevel2    IN table_number,
        i_idqualscalelevel3   IN table_number,
        i_id_qualifilevel3    IN table_number,
        o_id_intervevaluation OUT interv_evaluation.id_interv_evaluation%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        -- verify if the evaluation is already canceled
        g_error := 'CANCEL_ICF_EVALUATION';
        IF NOT cancel_icf_evaluation_nocommit(i_lang                 => i_lang,
                                              i_prof                 => i_prof,
                                              i_id_interv_evaluation => i_idinterv,
                                              i_cancel_mode          => g_status_eval_outd,
                                              o_error                => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF NOT create_icf_evaluation_internal(i_lang                => i_lang,
                                              i_prof                => i_prof,
                                              i_id_episode          => i_idepisode,
                                              i_id_patient          => i_idpatient,
                                              i_idicf               => i_idicf,
                                              i_notes               => i_notes,
                                              i_idqualscalelevel1   => i_idqualscalelevel1,
                                              i_id_qualifilevel1    => i_id_qualifilevel1,
                                              i_idqualscalelevel2   => i_idqualscalelevel2,
                                              i_id_qualifilevel2    => i_id_qualifilevel2,
                                              i_idqualscalelevel3   => i_idqualscalelevel3,
                                              i_id_qualifilevel3    => i_id_qualifilevel3,
                                              o_id_intervevaluation => o_id_intervevaluation,
                                              o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_INTERV_MFR', 'UPDATE_ICF_EVALUATION');
            
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_utils.undo_changes;
            
                RETURN FALSE;
            END;
    END update_icf_evaluation;

    FUNCTION get_num_icf_qualif
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_icf IN table_number,
        o_qualif OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET NUMBER OF QUALIFIERS';
        OPEN o_qualif FOR
            SELECT id_icf,
                   componente,
                   coding,
                   icf_name,
                   id_parent,
                   id_scale_level1,
                   decode(id_scale_level1, NULL, g_flg_n, g_flg_y) flg_edit_level1,
                   id_scale_level2,
                   decode(id_scale_level2, NULL, g_flg_n, g_flg_y) flg_edit_level2,
                   id_scale_level3,
                   decode(id_scale_level3, NULL, g_flg_n, g_flg_y) flg_edit_level3
              FROM (SELECT cif.id_icf,
                           pk_translation.get_translation(i_lang, cif.component) componente,
                           cif.coding,
                           cif.icf_name,
                           cif.id_parent,
                           (SELECT iqr.id_icf_qualification_scale
                              FROM icf_qualification_rel iqr
                             WHERE id_icf = cif.id_parent
                               AND flg_level = g_flg_level1
                               AND iqr.flg_available = pk_alert_constant.g_yes
                               AND rownum = 1) id_scale_level1,
                           (SELECT iqr.id_icf_qualification_scale
                              FROM icf_qualification_rel iqr
                             WHERE id_icf = cif.id_parent
                               AND flg_level = g_flg_level2
                               AND iqr.flg_available = pk_alert_constant.g_yes
                               AND rownum = 1) id_scale_level2,
                           (SELECT iqr.id_icf_qualification_scale
                              FROM icf_qualification_rel iqr
                             WHERE id_icf = cif.id_parent
                               AND flg_level = g_flg_level3
                               AND iqr.flg_available = pk_alert_constant.g_yes
                               AND rownum = 1) id_scale_level3
                      FROM (SELECT id_icf,
                                   decode(flg_type,
                                          g_flg_icf_component,
                                          NULL,
                                          g_flg_icf_chapter,
                                          coding,
                                          REPLACE(sys_connect_by_path(coding, '/'), '/', '')) coding,
                                   pk_translation.get_translation(i_lang, code_icf) icf_name,
                                   connect_by_root i.code_icf component,
                                   connect_by_root i.id_icf id_parent
                              FROM icf i
                             WHERE i.id_icf IN ((SELECT column_value
                                                  FROM TABLE(CAST(i_id_icf AS table_number))))
                            CONNECT BY PRIOR id_icf = id_icf_parent
                             START WITH id_icf IN (SELECT id_icf
                                                     FROM icf
                                                    WHERE flg_type = g_flg_icf_component)) cif);
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_INTERV_MFR', 'GET_NUM_ICF_QUALIF');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN FALSE;
            END;
    END get_num_icf_qualif;

    FUNCTION get_menu_evaluation
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_subject IN action.subject%TYPE,
        i_state   IN action.from_state%TYPE,
        o_menu    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_pat IS
            SELECT gender, trunc(months_between(SYSDATE, dt_birth) / 12) age
              FROM patient
             WHERE id_patient = i_patient;
    
        l_pat c_pat%ROWTYPE;
    
        l_create_no_selection action.from_state%TYPE := 'A';
        l_create_other        action.from_state%TYPE := 'O';
        l_search_no_selection action.from_state%TYPE := 'S';
        l_search_other        action.from_state%TYPE := 'P';
        l_active              VARCHAR2(1) := 'A';
        l_inactive            VARCHAR2(1) := 'I';
    
        l_prof_templ table_number;
    
    BEGIN
        g_error := 'OPEN C_PAT';
        OPEN c_pat;
        FETCH c_pat
            INTO l_pat;
        CLOSE c_pat;
    
        g_error := 'GET PROFILE_TEMPLATE';
        SELECT ppt.id_profile_template
          BULK COLLECT
          INTO l_prof_templ
          FROM prof_profile_template ppt
         WHERE profissional(ppt.id_professional, ppt.id_institution, ppt.id_software) = i_prof;
    
        g_error := 'OPEN MENU';
        OPEN o_menu FOR
            SELECT id_action,
                   id_parent,
                   "LEVEL",
                   to_state,
                   desc_action,
                   icon,
                   flg_active,
                   action,
                   id_doc_area,
                   title_documentation
              FROM (SELECT a.id_action,
                           a.id_parent,
                           LEVEL,
                           a.to_state to_state,
                           pk_message.get_message(i_lang, i_prof, code_action) desc_action,
                           a.icon,
                           a.flg_status flg_active,
                           a.internal_name action,
                           NULL id_doc_area,
                           NULL title_documentation
                      FROM action a, action_permission ap, TABLE(l_prof_templ) t
                     WHERE a.id_action = ap.id_action
                       AND a.subject = i_subject
                       AND a.from_state = i_state
                       AND ap.id_profile_template = t.column_value
                       AND nvl(ap.id_institution, 0) IN (0, i_prof.institution)
                       AND nvl(ap.id_software, 0) IN (0, i_prof.software)
                       AND ap.flg_available = g_flg_y
                       AND i_state NOT IN (l_create_other, l_search_other)
                    CONNECT BY PRIOR a.id_action = a.id_parent
                     START WITH a.id_parent IS NULL
                    UNION
                    SELECT ra.id_rehab_area id_action,
                           decode(i_state, l_create_no_selection, 23790, l_search_no_selection, 23794, NULL) id_parent,
                           decode(i_state, l_create_other, 1, 2) "LEVEL",
                           NULL to_state,
                           pk_translation.get_translation(i_lang, ra.code_rehab_area) desc_action,
                           NULL icon,
                           nvl((SELECT decode(COUNT(dtc1.id_doc_template), 0, l_inactive, l_active)
                                 FROM rehab_area ra1
                                 LEFT JOIN doc_template_context dtc1
                                   ON dtc1.id_context = ra1.id_rehab_area
                                  AND dtc1.flg_type = 'R'
                                WHERE ra1.id_rehab_area = ra.id_rehab_area
                                  AND nvl(dtc1.id_software, 0) IN (0, i_prof.software)
                                  AND nvl(dtc1.id_institution, 0) IN (0, i_prof.institution)
                                GROUP BY ra1.id_rehab_area),
                               l_inactive) flg_active,
                           'PHYSIATRY_AREA' action,
                           NULL id_doc_area,
                           NULL title_documentation
                      FROM rehab_area ra
                      LEFT JOIN doc_template_context dtc
                        ON dtc.id_context = ra.id_rehab_area
                       AND dtc.flg_type = 'R'
                       AND i_state IN (l_create_no_selection, l_search_no_selection, l_create_other, l_search_other)
                    UNION
                    SELECT dtc.id_doc_template id_action,
                           ra.id_rehab_area id_parent,
                           decode(i_state, l_create_other, 2, 3) "LEVEL",
                           NULL to_state,
                           pk_translation.get_translation(i_lang, dt.code_doc_template) desc_action,
                           NULL icon,
                           l_active flg_active,
                           'DOC_TEMPLATE' action,
                           5096 id_doc_area,
                           pk_message.get_message(i_lang, i_prof, 'EVALUATION_MFR_T033') || ' - ' ||
                           pk_translation.get_translation(i_lang, ra.code_rehab_area) title_documentation
                      FROM doc_template dt
                      JOIN doc_template_context dtc
                        ON dtc.id_doc_template = dt.id_doc_template
                      JOIN rehab_area ra
                        ON ra.id_rehab_area = dtc.id_context
                       AND dtc.flg_type = 'R'
                     WHERE dt.flg_available = g_flg_available_y
                       AND pk_patient.validate_pat_gender(l_pat.gender, dt.flg_gender) = 1
                       AND (dt.age_min <= l_pat.age OR dt.age_min IS NULL OR l_pat.age IS NULL)
                       AND (dt.age_max >= l_pat.age OR dt.age_max IS NULL OR l_pat.age IS NULL)
                       AND nvl(dtc.id_software, 0) IN (0, i_prof.software)
                       AND nvl(dtc.id_institution, 0) IN (0, i_prof.institution)
                       AND i_state IN (l_create_no_selection, l_search_no_selection, l_create_other, l_search_other))
             WHERE desc_action IS NOT NULL;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_INTERV_MFR', 'GET_MENU_EVALUATION');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN FALSE;
            END;
    END get_menu_evaluation;

    FUNCTION get_summ_page_mfr_assessm_int
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        i_current_episode    IN episode.id_episode%TYPE,
        i_scope              IN NUMBER,
        i_scope_type         IN VARCHAR2,
        i_paging             IN VARCHAR2 DEFAULT 'N',
        i_start_record       IN NUMBER DEFAULT 1,
        i_num_records        IN NUMBER DEFAULT 2000,
        i_start_date         IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_end_date           IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_doc_area_register  OUT pk_types.cursor_type,
        o_doc_area_val       OUT pk_types.cursor_type,
        o_template_layouts   OUT pk_types.cursor_type,
        o_doc_area_component OUT pk_types.cursor_type,
        o_record_count       OUT NUMBER,
        o_physiatry_area     OUT pk_types.cursor_type,
        o_totals             OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_total sys_message.desc_message%TYPE;
    
        l_episode episode.id_episode%TYPE;
        l_visit   visit.id_visit%TYPE;
        l_patient patient.id_patient%TYPE;
    BEGIN
        l_total := pk_message.get_message(i_lang, 'REHAB_M076');
    
        g_error := 'GET SUMMARY_PAGE INFO';
        IF NOT pk_touch_option.get_doc_area_value(i_lang               => i_lang,
                                                  i_prof               => i_prof,
                                                  i_doc_area           => i_doc_area,
                                                  i_current_episode    => i_current_episode,
                                                  i_scope              => i_scope,
                                                  i_scope_type         => i_scope_type,
                                                  i_paging             => i_paging,
                                                  i_start_record       => i_start_record,
                                                  i_num_records        => i_num_records,
                                                  i_fltr_start_date    => i_start_date,
                                                  i_fltr_end_date      => i_end_date,
                                                  o_doc_area_register  => o_doc_area_register,
                                                  o_doc_area_val       => o_doc_area_val,
                                                  o_template_layouts   => o_template_layouts,
                                                  o_doc_area_component => o_doc_area_component,
                                                  o_record_count       => o_record_count,
                                                  o_error              => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'ANALYSING SCOPE TYPE';
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_scope,
                                              i_scope_type => i_scope_type,
                                              o_patient    => l_patient,
                                              o_visit      => l_visit,
                                              o_episode    => l_episode,
                                              o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        pk_types.open_cursor_if_closed(o_physiatry_area);
        pk_types.open_cursor_if_closed(o_totals);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_INTERV_MFR', 'GET_SUMM_PAGE_MFR_ASSESSM_INT');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN FALSE;
            END;
    END get_summ_page_mfr_assessm_int;

    FUNCTION get_summ_page_mfr_assessment
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        i_current_episode    IN episode.id_episode%TYPE,
        i_scope              IN NUMBER,
        i_scope_type         IN VARCHAR2,
        i_paging             IN VARCHAR2 DEFAULT 'N',
        i_start_record       IN NUMBER DEFAULT 1,
        i_num_records        IN NUMBER DEFAULT 2000,
        i_start_date         IN VARCHAR2 DEFAULT NULL,
        i_end_date           IN VARCHAR2 DEFAULT NULL,
        o_doc_area_register  OUT pk_types.cursor_type,
        o_doc_area_val       OUT pk_types.cursor_type,
        o_template_layouts   OUT pk_types.cursor_type,
        o_doc_area_component OUT pk_types.cursor_type,
        o_record_count       OUT NUMBER,
        o_physiatry_area     OUT pk_types.cursor_type,
        o_totals             OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_start_date TIMESTAMP WITH TIME ZONE;
        l_end_date   TIMESTAMP WITH TIME ZONE;
    BEGIN
        -- Convert start date to timestamp
        g_error := 'CALL GET_STRING_TSTZ FOR l_dt_begin';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_start_date,
                                             i_timezone  => NULL,
                                             o_timestamp => l_start_date,
                                             o_error     => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        -- Convert end date to timestamp
        g_error := 'CALL GET_STRING_TSTZ FOR l_dt_end';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_end_date,
                                             i_timezone  => NULL,
                                             o_timestamp => l_end_date,
                                             o_error     => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL get_summ_page_mfr_assessm_int';
        pk_alertlog.log_debug(g_error);
        IF NOT get_summ_page_mfr_assessm_int(i_lang            => i_lang,
                                             i_prof            => i_prof,
                                             i_doc_area        => i_doc_area,
                                             i_current_episode => i_current_episode,
                                             i_scope           => i_scope,
                                             i_scope_type      => i_scope_type,
                                             i_paging          => i_paging,
                                             i_start_record    => i_start_record,
                                             i_num_records     => i_num_records,
                                             i_start_date      => l_start_date,
                                             
                                             i_end_date           => l_end_date,
                                             o_doc_area_register  => o_doc_area_register,
                                             o_doc_area_val       => o_doc_area_val,
                                             o_template_layouts   => o_template_layouts,
                                             o_doc_area_component => o_doc_area_component,
                                             o_record_count       => o_record_count,
                                             o_physiatry_area     => o_physiatry_area,
                                             o_totals             => o_totals,
                                             o_error              => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_INTERV_MFR', 'GET_SUMM_PAGE_MFR_ASSESSMENT');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN FALSE;
            END;
    END get_summ_page_mfr_assessment;

    FUNCTION get_summ_page_mfr_assessment
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        i_current_episode    IN episode.id_episode%TYPE,
        i_scope              IN NUMBER,
        i_scope_type         IN VARCHAR2,
        i_paging             IN VARCHAR2 DEFAULT 'N',
        i_start_record       IN NUMBER DEFAULT 1,
        i_num_records        IN NUMBER DEFAULT 2000,
        o_doc_area_register  OUT pk_types.cursor_type,
        o_doc_area_val       OUT pk_types.cursor_type,
        o_template_layouts   OUT pk_types.cursor_type,
        o_doc_area_component OUT pk_types.cursor_type,
        o_record_count       OUT NUMBER,
        o_physiatry_area     OUT pk_types.cursor_type,
        o_totals             OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL get_summ_page_mfr_assessm_int';
        pk_alertlog.log_debug(g_error);
        IF NOT get_summ_page_mfr_assessm_int(i_lang               => i_lang,
                                             i_prof               => i_prof,
                                             i_doc_area           => i_doc_area,
                                             i_current_episode    => i_current_episode,
                                             i_scope              => i_scope,
                                             i_scope_type         => i_scope_type,
                                             i_paging             => i_paging,
                                             i_start_record       => i_start_record,
                                             i_num_records        => i_num_records,
                                             o_doc_area_register  => o_doc_area_register,
                                             o_doc_area_val       => o_doc_area_val,
                                             o_template_layouts   => o_template_layouts,
                                             o_doc_area_component => o_doc_area_component,
                                             o_record_count       => o_record_count,
                                             o_physiatry_area     => o_physiatry_area,
                                             o_totals             => o_totals,
                                             o_error              => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, g_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_INTERV_MFR', 'GET_SUMM_PAGE_MFR_ASSESSMENT');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN FALSE;
            END;
    END get_summ_page_mfr_assessment;

    FUNCTION get_instructions
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        i_format              IN VARCHAR2 DEFAULT 'PFSED'
    ) RETURN VARCHAR2 IS
        l_prty  VARCHAR2(4000);
        l_freq  VARCHAR2(4000);
        l_take  VARCHAR2(4000);
        l_start VARCHAR2(4000);
        l_ret   VARCHAR2(4000);
    
        PROCEDURE add_to_ret
        (
            i_add      IN VARCHAR2,
            i_original IN OUT VARCHAR2
        ) IS
        BEGIN
            IF i_original IS NULL
            THEN
                i_original := i_add;
            ELSIF i_add IS NOT NULL
            THEN
                i_original := i_original || ', ' || i_add;
            END IF;
        END add_to_ret;
    
    BEGIN
        g_error := 'GET DATA';
        SELECT pk_sysdomain.get_domain(g_priority_domain, ipd.flg_prty, i_lang) priority,
               ipd.num_freq || ' ' ||
               decode(ipd.num_freq,
                      i_lang,
                      pk_message.get_message(i_lang, i_prof, 'PROCEDURES_MFR_M060'),
                      pk_message.get_message(i_lang, i_prof, 'PROCEDURES_MFR_M061')) || ' ' ||
               pk_sysdomain.get_domain(g_flg_freq, ipd.flg_freq, i_lang) frequency,
               ipd.num_take || decode(ipd.num_take,
                                      1,
                                      pk_message.get_message(i_lang, i_prof, 'PROCEDURES_MFR_M015'),
                                      pk_message.get_message(i_lang, i_prof, 'PROCEDURES_MFR_M016')) num_take,
               decode(ipd.dt_begin_tstz,
                      NULL,
                      NULL,
                      pk_message.get_message(i_lang, i_prof, 'PROCEDURES_MFR_T059') || ' ' ||
                      pk_date_utils.dt_chr_tsz(i_lang, ipd.dt_begin_tstz, i_prof)) start_date
          INTO l_prty, l_freq, l_take, l_start
          FROM interv_presc_det ipd
         WHERE ipd.id_interv_presc_det = i_id_interv_presc_det;
    
        FOR i IN 1 .. length(i_format)
        LOOP
            CASE substr(i_format, i, 1)
                WHEN 'P' THEN
                    add_to_ret(l_prty, l_ret);
                WHEN 'F' THEN
                    add_to_ret(l_freq, l_ret);
                WHEN 'S' THEN
                    add_to_ret(l_take, l_ret);
                WHEN 'D' THEN
                    add_to_ret(l_start, l_ret);
                ELSE
                    NULL;
            END CASE;
        END LOOP;
    
        RETURN l_ret;
    END get_instructions;

BEGIN
    -- Log initialization.
    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);

END pk_interv_mfr;
/
